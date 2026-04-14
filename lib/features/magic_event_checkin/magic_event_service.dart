import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_geofence.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_geohash.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_model.dart';
import 'package:nabour_app/utils/logger.dart';

/// Citește evenimente candidat din Firestore și le filtrează cu [magicEventsUserIsInsideNow].
class MagicEventService {
  MagicEventService._();
  static final MagicEventService instance = MagicEventService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('magic_events');

  static const int _whereInLimit = 30;

  /// Events where the user is inside radius and within time window.
  ///
  /// [searchRadiusKm] widens geohash candidate query; strict filter is [MagicEvent.radiusMeters].
  Future<List<MagicEvent>> fetchEventsUserIsInsideNow({
    required double userLat,
    required double userLng,
    double searchRadiusKm = 8.0,
    DateTime? now,
  }) async {
    final candidates = await fetchActiveCandidatesInArea(
      userLat: userLat,
      userLng: userLng,
      searchRadiusKm: searchRadiusKm,
    );
    return magicEventsUserIsInsideNow(
      userLat: userLat,
      userLng: userLng,
      candidates: candidates,
      now: now,
    );
  }

  /// Active docs in nearby geohashes (no fine distance/time filter).
  Future<List<MagicEvent>> fetchActiveCandidatesInArea({
    required double userLat,
    required double userLng,
    double searchRadiusKm = 8.0,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return [];
    }
    final hashes = MagicEventGeohash.nearbyGeohashes(
      userLat,
      userLng,
      searchRadiusKm,
    );
    if (hashes.isEmpty) return [];

    final out = <MagicEvent>[];
    for (var i = 0; i < hashes.length; i += _whereInLimit) {
      final chunk = hashes.sublist(
        i,
        i + _whereInLimit > hashes.length ? hashes.length : i + _whereInLimit,
      );
      try {
        final snap = await _col
            .where('geohash', whereIn: chunk)
            .where('isActive', isEqualTo: true)
            .get();
        for (final doc in snap.docs) {
          out.add(MagicEvent.fromFirestore(doc));
        }
      } catch (e, st) {
        final msg = e.toString();
        if (msg.contains('permission-denied')) {
          Logger.warning(
            'MagicEventService.fetchActiveCandidatesInArea: Firestore permission-denied pe '
            '`magic_events`. Deploy `firestore.rules` din repo și verifică autentificarea.',
            tag: 'MAGIC_EVENT',
          );
        } else {
          Logger.error(
            'MagicEventService.fetchActiveCandidatesInArea: $e',
            error: e,
            stackTrace: st,
            tag: 'MAGIC_EVENT',
          );
        }
      }
    }
    return out;
  }

  /// Create event; geohash from center. Ownership enforced in Firestore rules.
  Future<String> createEvent(MagicEvent event) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Neautentificat');

    final gh = MagicEventGeohash.encode(event.latitude, event.longitude);
    final payload = event.toCreateMap();
    payload['geohash'] = gh;

    final doc = await _col.add(payload);
    Logger.info('Magic event created: ${doc.id}', tag: 'MAGIC_EVENT');
    return doc.id;
  }

  Stream<List<MagicEvent>> watchMyEvents(String businessId) {
    return _col
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(MagicEvent.fromFirestore).toList();
      list.sort((a, b) => b.startAt.compareTo(a.startAt));
      return list;
    });
  }

  Future<void> setEventActive(String eventId, bool active) async {
    await _col.doc(eventId).update({'isActive': active});
  }

  static const int _batchLimit = 450;

  /// Șterge documentele din `participants`, apoi evenimentul.
  Future<void> deleteEvent(String eventId) async {
    final eventRef = _col.doc(eventId);
    final partCol = eventRef.collection('participants');
    while (true) {
      final snap = await partCol.limit(500).get();
      if (snap.docs.isEmpty) break;
      var batch = _db.batch();
      var n = 0;
      for (final d in snap.docs) {
        batch.delete(d.reference);
        n++;
        if (n >= _batchLimit) {
          await batch.commit();
          batch = _db.batch();
          n = 0;
        }
      }
      if (n > 0) {
        await batch.commit();
      }
    }
    await eventRef.delete();
    Logger.info('Magic event deleted: $eventId', tag: 'MAGIC_EVENT');
  }

  /// Șterge toate evenimentele afacerii (cu subcolecții participants).
  Future<void> deleteAllEventsForBusiness(String businessId) async {
    final snap = await _col.where('businessId', isEqualTo: businessId).get();
    for (final doc in snap.docs) {
      await deleteEvent(doc.id);
    }
    Logger.info(
      'Magic events bulk deleted for business: $businessId (${snap.docs.length})',
      tag: 'MAGIC_EVENT',
    );
  }
}
