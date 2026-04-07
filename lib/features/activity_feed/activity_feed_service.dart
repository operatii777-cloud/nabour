import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/utils/logger.dart';

/// Server-side activity feed, persisted in Firestore.
///
/// Collection: `activity_feed/{uid}/events/{auto-id}`
///
/// Each event has: `type`, `actorUid`, `actorName`, `text`, `ts`, optional `lat`/`lng`.
/// Client writes own events; friends query each other's feed (ACL via `allowedUids`).
class ActivityFeedService {
  ActivityFeedService._();
  static final ActivityFeedService instance = ActivityFeedService._();

  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Throttle: one event per type per 3 minutes.
  final Map<String, DateTime> _lastWrite = {};
  static const _throttle = Duration(minutes: 3);

  Future<void> postEvent({
    required String type,
    required String text,
    double? lat,
    double? lng,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final now = DateTime.now();
    final key = '$type:$uid';
    final last = _lastWrite[key];
    if (last != null && now.difference(last) < _throttle) return;
    _lastWrite[key] = now;

    try {
      final user = FirebaseAuth.instance.currentUser;
      await _db
          .collection('activity_feed')
          .doc(uid)
          .collection('events')
          .add({
        'type': type,
        'actorUid': uid,
        'actorName': user?.displayName ?? 'Vecin',
        'text': text,
        'ts': FieldValue.serverTimestamp(),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
    } catch (e) {
      Logger.warning('ActivityFeed postEvent failed: $e', tag: 'FEED');
    }
  }

  /// Stream of recent events for a friend.
  Stream<List<ActivityEvent>> friendEvents(String friendUid,
      {int limit = 30}) {
    return _db
        .collection('activity_feed')
        .doc(friendUid)
        .collection('events')
        .orderBy('ts', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ActivityEvent.fromDoc(d, feedOwnerUid: friendUid))
            .toList());
  }

  /// Merged stream of events from multiple friends.
  Stream<List<ActivityEvent>> mergedFriendEvents(List<String> friendUids,
      {int limit = 50}) {
    if (friendUids.isEmpty) return Stream.value([]);

    final streams = friendUids.map((uid) => friendEvents(uid, limit: 15));
    return _combineStreams(streams.toList()).map((lists) {
      final all = lists.expand((l) => l).toList();
      all.sort((a, b) => b.ts.compareTo(a.ts));
      if (all.length > limit) return all.sublist(0, limit);
      return all;
    });
  }

  /// Cleanup events older than 7 days (call occasionally).
  Future<void> pruneOldEvents() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final cutoff = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7)));
      final old = await _db
          .collection('activity_feed')
          .doc(uid)
          .collection('events')
          .where('ts', isLessThan: cutoff)
          .limit(50)
          .get();
      final batch = _db.batch();
      for (final doc in old.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      Logger.warning('ActivityFeed prune failed: $e', tag: 'FEED');
    }
  }

  static Stream<List<List<ActivityEvent>>> _combineStreams(
      List<Stream<List<ActivityEvent>>> streams) {
    final latest =
        List<List<ActivityEvent>>.filled(streams.length, const []);
    final controller =
        StreamController<List<List<ActivityEvent>>>.broadcast();
    final subs = <StreamSubscription>[];
    for (var i = 0; i < streams.length; i++) {
      final idx = i;
      subs.add(streams[idx].listen((data) {
        latest[idx] = data;
        controller.add(List.from(latest));
      }));
    }
    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
    return controller.stream;
  }
}

class ActivityEvent {
  final String id;
  /// UID-ul documentului părinte `activity_feed/{feedOwnerUid}` (unic per card în listă îmbinată).
  final String feedOwnerUid;
  final String type;
  final String actorUid;
  final String actorName;
  final String text;
  final DateTime ts;
  final double? lat;
  final double? lng;

  const ActivityEvent({
    required this.id,
    required this.feedOwnerUid,
    required this.type,
    required this.actorUid,
    required this.actorName,
    required this.text,
    required this.ts,
    this.lat,
    this.lng,
  });

  factory ActivityEvent.fromDoc(DocumentSnapshot doc,
      {required String feedOwnerUid}) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityEvent(
      id: doc.id,
      feedOwnerUid: feedOwnerUid,
      type: m['type'] as String? ?? '',
      actorUid: m['actorUid'] as String? ?? '',
      actorName: m['actorName'] as String? ?? 'Vecin',
      text: m['text'] as String? ?? '',
      ts: (m['ts'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
    );
  }
}
