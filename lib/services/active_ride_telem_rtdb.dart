import 'package:nabour_app/config/neighbor_telemetry_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/utils/logger.dart';

/// Telemetrie RTDB pentru cursa activă: un singur nod per cursă, fără H3.
///
/// - `telemetry/active_rides/{rideId}/_meta` — șofer + pasager (bootstrap Faza 2).
/// - `telemetry/active_rides/{rideId}/driver_location` — poziție șofer, throttled.
///
/// La deconectare, [onDisconnect] șterge `driver_location`. La final cursă,
/// [removeRideTelemetry] curăță tot sub `rideId`.
class ActiveRideDriverLocation {
  const ActiveRideDriverLocation({
    required this.lat,
    required this.lng,
    this.heading,
    this.speed,
    this.updatedAtMs,
  });

  final double lat;
  final double lng;
  final double? heading;
  final double? speed;
  final int? updatedAtMs;

  static ActiveRideDriverLocation? fromRtdbMap(Map<Object?, Object?> raw) {
    final lat = _asDouble(raw['lat']);
    final lng = _asDouble(raw['lng']);
    if (lat == null || lng == null) return null;
    return ActiveRideDriverLocation(
      lat: lat,
      lng: lng,
      heading: _asDouble(raw['heading']),
      speed: _asDouble(raw['speed']),
      updatedAtMs: _asInt(raw['updatedAt']),
    );
  }

  static double? _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    return null;
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }
}

class ActiveRideTelemetryRtdbService {
  ActiveRideTelemetryRtdbService._();
  static final ActiveRideTelemetryRtdbService instance =
      ActiveRideTelemetryRtdbService._();

  // URL explicit — necesar dacă google-services.json nu conține firebase_url
  static const String _dbUrl =
      'https://nabour-4b4e4-default-rtdb.firebaseio.com/';

  final DatabaseReference _root =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _dbUrl,
      ).ref();

  DateTime? _lastPublishTime;
  double? _lastPublishLat;
  double? _lastPublishLng;
  String? _onDisconnectRideId;
  bool _disabled = false;

  bool _shouldPublish(double lat, double lng, {bool force = false}) {
    if (force) return true;
    if (_lastPublishTime == null) return true;
    final cfg = NeighborTelemetryConfig.instance;
    if (DateTime.now().difference(_lastPublishTime!) < cfg.publishMinInterval) {
      return false;
    }
    if (_lastPublishLat == null || _lastPublishLng == null) return true;
    final moved = Geolocator.distanceBetween(
      _lastPublishLat!,
      _lastPublishLng!,
      lat,
      lng,
    );
    return moved >= cfg.publishMinDistanceM;
  }

  /// Apelat la acceptarea cursei de către șofer (sau înainte de primul publish).
  Future<void> ensureRideMeta({
    required String rideId,
    required String driverId,
    required String passengerId,
  }) async {
    if (_disabled) return;
    final ref = _root.child('telemetry/active_rides/$rideId/_meta');
    try {
      final snap = await ref.get();
      if (snap.exists) return;
      await ref.set(<String, Object?>{
        'driverId': driverId,
        'passengerId': passengerId,
        'createdAt': ServerValue.timestamp,
      });
    } catch (e, st) {
      Logger.error('ActiveRideTelemetry.ensureRideMeta: $e',
          error: e, stackTrace: st, tag: 'RTDB');
      _maybeDisableOnPermission(e);
    }
  }

  Future<void> publishDriverLocation({
    required String rideId,
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    bool force = false,
  }) async {
    if (_disabled) return;
    final uid = ActiveRideTelemetryRtdbService._currentUid();
    if (uid == null) return;
    if (!_shouldPublish(lat, lng, force: force)) return;

    final ref = _root.child('telemetry/active_rides/$rideId/driver_location');
    try {
      if (_onDisconnectRideId != null && _onDisconnectRideId != rideId) {
        await _root
            .child(
                'telemetry/active_rides/${_onDisconnectRideId!}/driver_location')
            .onDisconnect()
            .cancel();
        _onDisconnectRideId = null;
      }
      if (_onDisconnectRideId != rideId) {
        await ref.onDisconnect().remove();
        _onDisconnectRideId = rideId;
      }

      await ref.set(<String, Object?>{
        'lat': lat,
        'lng': lng,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        'updatedAt': ServerValue.timestamp,
      });
      _lastPublishTime = DateTime.now();
      _lastPublishLat = lat;
      _lastPublishLng = lng;
    } catch (e, st) {
      Logger.error('ActiveRideTelemetry.publishDriverLocation: $e',
          error: e, stackTrace: st, tag: 'RTDB');
      _maybeDisableOnPermission(e);
    }
  }

  Stream<ActiveRideDriverLocation?> listenDriverLocation(String rideId) {
    return _root
        .child('telemetry/active_rides/$rideId/driver_location')
        .onValue
        .map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return null;
      return ActiveRideDriverLocation.fromRtdbMap(
        Map<Object?, Object?>.from(raw),
      );
    });
  }

  /// Șterge telemetria cursei (finalizare / anulare).
  Future<void> removeRideTelemetry(String rideId) async {
    if (_onDisconnectRideId == rideId) {
      try {
        await _root
            .child('telemetry/active_rides/$rideId/driver_location')
            .onDisconnect()
            .cancel();
      } catch (_) {}
      _onDisconnectRideId = null;
    }

    _lastPublishTime = null;
    _lastPublishLat = null;
    _lastPublishLng = null;

    try {
      await _root.child('telemetry/active_rides/$rideId/driver_location').remove();
      await _root.child('telemetry/active_rides/$rideId/_meta').remove();
    } catch (e) {
      Logger.warning('ActiveRideTelemetry.removeRideTelemetry: $e', tag: 'RTDB');
    }
  }

  static String? _currentUid() => FirebaseAuth.instance.currentUser?.uid;

  void _maybeDisableOnPermission(Object e) {
    if (e.toString().contains('PERMISSION_DENIED') ||
        e.toString().contains('permission_denied')) {
      _disabled = true;
    }
  }
}
