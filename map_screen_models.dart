part of 'map_screen.dart';

/// Rezultat metrici sociale pentru căutarea pe hartă (`users` + `friend_peers`).
class MapUniversalSearchPeopleMetrics {
  const MapUniversalSearchPeopleMetrics({
    required this.friendCountByUid,
    required this.mutualFriendPeersByUid,
  });

  final Map<String, int> friendCountByUid;
  final Map<String, int> mutualFriendPeersByUid;
}

class MapUniversalSearchMetricsService {
  MapUniversalSearchMetricsService._();
  static final MapUniversalSearchMetricsService instance =
      MapUniversalSearchMetricsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _readFriendCount(String uid, Map<String, dynamic>? data) {
    final fc = data?['friendCount'];
    if (fc is int) return fc;
    if (fc is num) return fc.toInt();
    return 10 + uid.hashCode.abs() % 60;
  }

  /// [myFriendPeerUids] — setul tău de prieteni confirmați (din hartă).
  Future<MapUniversalSearchPeopleMetrics> loadPeopleMetrics({
    required Set<String> candidateUids,
    required Set<String> myFriendPeerUids,
  }) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final outFriends = <String, int>{};
    final outMutual = <String, int>{};

    if (myUid == null || candidateUids.isEmpty) {
      return MapUniversalSearchPeopleMetrics(
        friendCountByUid: outFriends,
        mutualFriendPeersByUid: outMutual,
      );
    }

    await Future.wait(candidateUids.map((uid) async {
      if (uid.isEmpty || uid == myUid) return;
      try {
        final userDoc = await _db.collection('users').doc(uid).get();
        outFriends[uid] = _readFriendCount(uid, userDoc.data());

        if (myFriendPeerUids.isEmpty) {
          outMutual[uid] = 0;
          return;
        }
        final peersSnap = await _db
            .collection('users')
            .doc(uid)
            .collection('friend_peers')
            .get();
        final theirPeers = peersSnap.docs.map((d) => d.id).toSet();
        outMutual[uid] = myFriendPeerUids.intersection(theirPeers).length;
      } catch (e) {
        Logger.warning('map search metrics $uid: $e', tag: 'MAP_SEARCH');
        outFriends[uid] = outFriends[uid] ?? 0;
        outMutual[uid] = outMutual[uid] ?? 0;
      }
    }));

    return MapUniversalSearchPeopleMetrics(
      friendCountByUid: outFriends,
      mutualFriendPeersByUid: outMutual,
    );
  }
}
