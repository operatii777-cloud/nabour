import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/config/neighbor_telemetry_config.dart';
import 'package:nabour_app/services/nabour_functions.dart';
import 'package:nabour_app/models/neighbor_location_model.dart';
import 'package:nabour_app/utils/logger.dart';

/// Telemetrie efemeră pe Firebase Realtime Database, partiționată după celula H3
/// din claim-ul [nb_room] (aceeași ca la chat cartier / Faza 1).
///
/// - Publicare: `/telemetry/locations/{h3}/{uid}` — fără istoric, suprascriere.
/// - Citire: listener pe `/telemetry/locations/{h3}` doar dacă `auth.token.nb_room == h3`.
/// - [onDisconnect] șterge nodul la pierderea conexiunii.
///
/// **Throttling hibrid (timp + distanță)** înainte de orice `set` RTDB: valorile vin din
/// [NeighborTelemetryConfig] (Remote Config: `telemetry_throttle_time_sec`,
/// `telemetry_throttle_distance_m`; fallback 3s / 7m).
/// [publish] cu `force: true` ocolește poarta. [removeMyNode] resetează starea throttle.
/// [ensureNbRoomClaim] rulează doar dacă publicarea nu a fost respinsă de throttle.
///
/// Limitări (Faza 2): filtrul „doar contacte din agendă” rămâne pe client; toți
/// utilizatorii din același hexagon pot primi același snapshot RTDB (vezi regulile).
class NeighborTelemetryRtdbService {
  NeighborTelemetryRtdbService._();
  static final NeighborTelemetryRtdbService instance =
      NeighborTelemetryRtdbService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  DateTime? _lastRoomSync;
  double? _lastSyncLat;
  double? _lastSyncLng;
  String? _onDisconnectRegisteredKey;

  /// Ultima publicare reușită în `/telemetry/locations/...` (throttle hibrid).
  DateTime? _lastNeighborPublishTime;
  double? _lastNeighborPublishLat;
  double? _lastNeighborPublishLng;

  static const Duration _syncMinInterval = Duration(seconds: 45);
  static const double _syncMinMoveM = 400;

  bool _disabled = false;

  bool _shouldPublishNeighbor(double lat, double lng, {bool force = false}) {
    if (force) return true;
    if (_lastNeighborPublishTime == null) return true;
    final cfg = NeighborTelemetryConfig.instance;
    final elapsed = DateTime.now().difference(_lastNeighborPublishTime!);
    if (elapsed < cfg.publishMinInterval) return false;
    if (_lastNeighborPublishLat == null || _lastNeighborPublishLng == null) {
      return true;
    }
    final moved = Geolocator.distanceBetween(
      _lastNeighborPublishLat!,
      _lastNeighborPublishLng!,
      lat,
      lng,
    );
    return moved >= cfg.publishMinDistanceM;
  }

  Future<String?> _nbRoomFromToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final r = await user.getIdTokenResult();
    final room = r.claims?['nb_room'];
    return room is String && room.isNotEmpty ? room : null;
  }

  /// Re-sincronizează claim-ul [nb_room] cu serverul (H3) când e necesar.
  Future<String?> ensureNbRoomClaim(double lat, double lng,
      {bool force = false}) async {
    if (_disabled) return _nbRoomFromToken();

    final now = DateTime.now();
    var needSync = force || _lastRoomSync == null;
    if (!needSync && _lastRoomSync != null) {
      if (now.difference(_lastRoomSync!) >= _syncMinInterval) {
        needSync = true;
      } else if (_lastSyncLat != null && _lastSyncLng != null) {
        final moved = Geolocator.distanceBetween(
          _lastSyncLat!, _lastSyncLng!, lat, lng,
        );
        if (moved >= _syncMinMoveM) needSync = true;
      }
    }

    if (needSync) {
      try {
        await NabourFunctions.instance
            .httpsCallable('nabourSyncNeighborhoodRoom')
            .call(<String, dynamic>{'lat': lat, 'lng': lng});
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
        _lastRoomSync = now;
        _lastSyncLat = lat;
        _lastSyncLng = lng;
      } on FirebaseFunctionsException catch (e) {
        Logger.warning(
          'NeighborTelemetryRtdb: sync room ${e.code} ${e.message}',
          tag: 'RTDB',
        );
      } catch (e) {
        Logger.warning('NeighborTelemetryRtdb: sync room $e', tag: 'RTDB');
      }
    }

    return _nbRoomFromToken();
  }

  /// Publică poziția curentă. Nu înlocuiește Firestore (acesta e throttled separat).
  /// [force] ocolește poarta timp + distanță (ex. prima activare sau test).
  Future<void> publish({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    int? battery,
    bool charging = false,
    required String avatar,
    required String displayName,
    bool isDriver = false,
    String? licensePlate,
    /// Doar când nu e șofer disponibil — altfel omis ca să nu rămână URL vechi în nod.
    String? photoURL,
    bool isPulsing = false,
    String? placeKind,
    int? stationarySince,
    bool force = false,
    String carAvatarId = 'default_car',
  }) async {
    if (_disabled) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (!_shouldPublishNeighbor(lat, lng, force: force)) {
      return;
    }

    final room = await ensureNbRoomClaim(lat, lng);
    if (room == null) {
      Logger.debug('NeighborTelemetryRtdb: skip publish — no nb_room claim',
          tag: 'RTDB');
      return;
    }

    try {
      final ref = _root.child('telemetry/locations/$room/$uid');
      final key = '$room/$uid';
      if (_onDisconnectRegisteredKey != null &&
          _onDisconnectRegisteredKey != key) {
        final old = _onDisconnectRegisteredKey!.split('/');
        if (old.length == 2) {
          await _root.child('telemetry/locations/${old[0]}/${old[1]}').remove();
        }
      }
      if (_onDisconnectRegisteredKey != key) {
        // Nu mai ștergem nodul la onDisconnect(). 
        // Lăsăm background publish (45s) să mențină locația, 
        // iar dacă aplicația e închisă, va expira prin stale-filter (5 min).
        _onDisconnectRegisteredKey = key;
      }

      await ref.set(<String, Object?>{
        'lat': lat,
        'lng': lng,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        if (battery != null) 'battery': battery,
        'charging': charging,
        'updatedAt': ServerValue.timestamp,
        'avatar': avatar,
        'displayName': displayName,
        'isDriver': isDriver,
        'licensePlate': licensePlate ?? '',
        'carAvatarId': carAvatarId,
        'isPulsing': isPulsing,
        if (!isDriver &&
            photoURL != null &&
            photoURL.isNotEmpty)
          'photoURL': photoURL,
        if (placeKind != null && placeKind.isNotEmpty) 'placeKind': placeKind,
        if (stationarySince != null) 'stationarySince': stationarySince,
      });
      _lastNeighborPublishTime = DateTime.now();
      _lastNeighborPublishLat = lat;
      _lastNeighborPublishLng = lng;
    } catch (e, st) {
      Logger.error('NeighborTelemetryRtdb.publish: $e',
          error: e, stackTrace: st, tag: 'RTDB');
      if (e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('permission_denied')) {
        _disabled = true;
      }
    }
  }

  /// Șterge explicit nodul (ex. vizibilitate oprită).
  Future<void> removeMyNode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final room = await _nbRoomFromToken();
    if (room == null) return;
    try {
      await _root.child('telemetry/locations/$room/$uid').remove();
    } catch (e) {
      Logger.warning('NeighborTelemetryRtdb.removeMyNode: $e', tag: 'RTDB');
    }
    _onDisconnectRegisteredKey = null;
    _lastNeighborPublishTime = null;
    _lastNeighborPublishLat = null;
    _lastNeighborPublishLng = null;
  }

  /// Stream de vecini din aceeași celulă H3 (excludem propriul uid).
  Stream<List<NeighborLocation>> listenLocationsInRoom(String roomId) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return _root.child('telemetry/locations/$roomId').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <NeighborLocation>[];
      final out = <NeighborLocation>[];
      for (final e in raw.entries) {
        final uid = e.key.toString();
        if (uid == myUid) continue;
        final v = e.value;
        if (v is! Map) continue;
        try {
          out.add(NeighborLocation.fromRtdb(uid, v));
        } catch (e) {
          Logger.debug('NeighborLocation.fromRtdb parse error for $uid: $e', tag: 'NBR_TELEM');
        }
      }
      return out;
    });
  }
}
