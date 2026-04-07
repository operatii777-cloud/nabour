import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/features/activity_feed/activity_feed_writer.dart';
import 'package:nabour_app/features/map_moments/map_moment_model.dart';
import 'package:nabour_app/utils/logger.dart';

/// CRUD for map moments (short TTL, pinned on the map).
class MapMomentService {
  MapMomentService._();
  static final MapMomentService instance = MapMomentService._();

  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('map_moments');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Post a new moment.
  Future<String?> post({
    required double lat,
    required double lng,
    required String caption,
    String? emoji,
    String? imageUrl,
    Duration ttl = const Duration(minutes: 30),
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final doc = await _col.add({
        'authorUid': user.uid,
        'authorName': user.displayName ?? 'Vecin',
        'authorAvatar': user.photoURL ?? '🙂',
        'lat': lat,
        'lng': lng,
        'caption': caption,
        if (emoji != null) 'emoji': emoji,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(ttl)),
        'reactions': <String>[],
      });
      unawaited(
        ActivityFeedWriter.postedMoment(caption, lat: lat, lng: lng),
      );
      return doc.id;
    } catch (e) {
      Logger.error('MapMomentService.post: $e', error: e, tag: 'MOMENTS');
      return null;
    }
  }

  /// Live stream of active (non-expired) moments in a bounding box.
  Stream<List<MapMoment>> nearbyMoments({
    required double centerLat,
    required double centerLng,
    double boxDeg = 0.054,
  }) {
    final now = Timestamp.fromDate(DateTime.now());
    return _col
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .snapshots()
        .map((snap) {
      final out = <MapMoment>[];
      for (final doc in snap.docs) {
        final m = MapMoment.fromDoc(doc);
        if ((m.lat - centerLat).abs() > boxDeg) continue;
        if ((m.lng - centerLng).abs() > boxDeg) continue;
        if (m.isExpired) continue;
        out.add(m);
      }
      return out;
    });
  }

  /// React to a moment with an emoji string.
  Future<void> react(String momentId, String emoji) async {
    try {
      await _col.doc(momentId).update({
        'reactions': FieldValue.arrayUnion([emoji]),
      });
    } catch (e) {
      Logger.warning('MapMomentService.react: $e', tag: 'MOMENTS');
    }
  }

  /// Delete own moment.
  Future<bool> delete(String momentId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final doc = await _col.doc(momentId).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (!doc.exists || data == null || data['authorUid'] != uid) {
        return false;
      }
      await _col.doc(momentId).delete();
      return true;
    } catch (e) {
      Logger.warning('MapMomentService.delete: $e', tag: 'MOMENTS');
      return false;
    }
  }
}
