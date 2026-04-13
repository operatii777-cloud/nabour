import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/neighbor_location_model.dart';
import 'package:nabour_app/services/neighbor_telemetry_rtdb_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Serviciu pentru social map — opt-in vizibilitate vecini.
class NeighborLocationService {
  static final NeighborLocationService _instance =
      NeighborLocationService._();
  NeighborLocationService._();
  factory NeighborLocationService() => _instance;

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Limitează scrierile Firestore pentru harta socială (telemetria live e în RTDB).
  DateTime? _lastFirestoreVisibleWrite;

  /// Ultima valoare scrisă pentru [isDriver] — la schimbare forțăm scriere Firestore
  /// (altfel merge păstrează `photoURL` vechi cu `isDriver` întârziat → marker greșit).
  bool? _lastPublishedIsDriver;

  /// La schimbare avatar garaj — forțăm scriere Firestore ca vecinii să vadă noul marker.
  String? _lastPublishedCarAvatarId;

  // Firestore rămâne throttled; RTDB folosește throttling intern în [NeighborTelemetryRtdbService].
  static const Duration _firestoreVisibleMinGap = Duration(seconds: 60);

  static const Duration _staleThreshold = Duration(minutes: 5);

  /// Publică locația curentă în `user_visible_locations/{uid}`.
  /// [hiddenFromUids] — lista de UID-uri care NU pot vedea această locație.
  Future<void> publishLocation({
    required double lat,
    required double lng,
    required String avatar,
    required String displayName,
    bool isDriver = false,
    String? licensePlate,
    String? photoURL,
    bool isPulsing = false,
    double? heading,
    double? speed,
    int? battery,
    bool charging = false,
    String? placeKind,
    int? stationarySince,
    List<String> allowedUids = const [],
    bool forceNeighborTelemetry = false,
    String? carAvatarId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final now = DateTime.now();
      final allowFs = _lastFirestoreVisibleWrite == null ||
          now.difference(_lastFirestoreVisibleWrite!) >= _firestoreVisibleMinGap;
      final driverFlagChanged = _lastPublishedIsDriver != isDriver;
      final cid = (carAvatarId == null || carAvatarId.isEmpty)
          ? 'default_car'
          : carAvatarId;
      final carAvatarChanged = _lastPublishedCarAvatarId != cid;
      if (allowFs || driverFlagChanged || carAvatarChanged) {
        final payload = <String, dynamic>{
          'lat': lat,
          'lng': lng,
          'avatar': avatar,
          'displayName': displayName,
          'lastUpdate': FieldValue.serverTimestamp(),
          'isVisible': true,
          'isDriver': isDriver,
          'licensePlate': licensePlate ?? '',
          'allowedUids': allowedUids,
          'carAvatarId': cid,
          if (placeKind != null) 'placeKind': placeKind,
          if (stationarySince != null) 'stationarySince': stationarySince,
        };
        // Șofer disponibil: nu lăsăm `photoURL` vechi în document (merge îl păstra altfel).
        if (isDriver) {
          payload['photoURL'] = FieldValue.delete();
        } else if (photoURL != null && photoURL.isNotEmpty) {
          payload['photoURL'] = photoURL;
        } else {
          payload['photoURL'] = FieldValue.delete();
        }

        await _db
            .collection('user_visible_locations')
            .doc(uid)
            .set(payload, SetOptions(merge: true));
        _lastFirestoreVisibleWrite = now;
        _lastPublishedIsDriver = isDriver;
        _lastPublishedCarAvatarId = cid;
      }

      unawaited(
        NeighborTelemetryRtdbService.instance.publish(
          lat: lat,
          lng: lng,
          heading: heading,
          speed: speed,
          battery: battery,
          charging: charging,
          avatar: avatar,
          displayName: displayName,
          isDriver: isDriver,
          licensePlate: licensePlate,
          photoURL: isDriver ? null : photoURL,
          isPulsing: isPulsing,
          placeKind: placeKind,
          stationarySince: stationarySince,
          force: forceNeighborTelemetry,
          carAvatarId: cid,
        ),
      );
    } catch (e) {
      Logger.error('NeighborLocationService.publishLocation: $e', error: e);
    }
  }

  /// Marchează userul ca invizibil (oprire opt-in).
  Future<void> setInvisible() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _lastFirestoreVisibleWrite = null;
    _lastPublishedIsDriver = null;
    _lastPublishedCarAvatarId = null;
    try {
      await NeighborTelemetryRtdbService.instance.removeMyNode();
    } catch (_) {}
    try {
      await _db.collection('user_visible_locations').doc(uid).set(
          {'isVisible': false}, SetOptions(merge: true));
    } catch (e) {
      Logger.error('NeighborLocationService.setInvisible: $e', error: e);
    }
  }

  /// Stream de prieteni vizibili pe hartă (fără limită de distanță față de centru).
  /// [centerLat]/[centerLng] rămân în semnătură pentru compatibilitate; nu se mai filtrează pe hartă după distanță.
  /// Returnează doar useri activi în ultimele 5 minute (fără userul curent).
  Stream<List<NeighborLocation>> nearbyNeighbors({
    required double centerLat,
    required double centerLng,
  }) {
    final cutoff = Timestamp.fromDate(
        DateTime.now().subtract(_staleThreshold));
    final myUid = _auth.currentUser?.uid;

    return _db
        .collection('user_visible_locations')
        .where('isVisible', isEqualTo: true)
        .where('lastUpdate', isGreaterThan: cutoff)
        .where('allowedUids', arrayContains: myUid) // ✅ Server-side filter
        .snapshots()
        .map((snap) {
      final neighbors = <NeighborLocation>[];
      for (final doc in snap.docs) {
        if (doc.id == myUid) continue;
        final n = NeighborLocation.fromMap(doc.id, doc.data());
        neighbors.add(n);
      }
      return neighbors;
    });
  }
}
