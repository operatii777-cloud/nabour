import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/utils/logger.dart';

/// Cerere din colecția `friend_requests`.
class FriendRequestEntry {
  final String id;
  final String fromUid;
  final String toUid;
  final String status;

  const FriendRequestEntry({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
  });

  factory FriendRequestEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return FriendRequestEntry(
      id: doc.id,
      fromUid: (m['fromUid'] as String?) ?? '',
      toUid: (m['toUid'] as String?) ?? '',
      status: (m['status'] as String?) ?? 'pending',
    );
  }
}

class FriendRequestService {
  FriendRequestService._();
  static final FriendRequestService instance = FriendRequestService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Cereri primite încă în așteptare (un singur where pentru index simplu).
  Stream<List<FriendRequestEntry>> incomingPendingStream() {
    final my = _uid;
    if (my == null) return const Stream.empty();
    return _db
        .collection('friend_requests')
        .where('toUid', isEqualTo: my)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FriendRequestEntry.fromDoc(d))
            .where((r) => r.status == 'pending' && r.fromUid.isNotEmpty)
            .toList());
  }

  /// UID-uri către care am deja cerere pending (evită duplicate la trimitere).
  Stream<Set<String>> outgoingPendingToUidsStream() {
    final my = _uid;
    if (my == null) return const Stream.empty();
    return _db
        .collection('friend_requests')
        .where('fromUid', isEqualTo: my)
        .snapshots()
        .map((snap) {
      final out = <String>{};
      for (final d in snap.docs) {
        final r = FriendRequestEntry.fromDoc(d);
        if (r.status == 'pending' && r.toUid.isNotEmpty) out.add(r.toUid);
      }
      return out;
    });
  }

  Future<bool> hasPendingRequestTo(String toUid) async {
    final my = _uid;
    if (my == null || toUid.isEmpty) return false;
    try {
      final snap = await _db
          .collection('friend_requests')
          .where('fromUid', isEqualTo: my)
          .get();
      for (final d in snap.docs) {
        final r = FriendRequestEntry.fromDoc(d);
        if (r.toUid == toUid && r.status == 'pending') return true;
      }
    } catch (e) {
      Logger.warning('hasPendingRequestTo: $e', tag: 'SOCIAL');
    }
    return false;
  }

  Future<void> acceptRequest(String requestId) async {
    final my = _uid;
    if (my == null) return;
    final ref = _db.collection('friend_requests').doc(requestId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final m = snap.data()!;
      if (m['toUid'] != my || m['status'] != 'pending') return;
      final fromUid = m['fromUid'] as String?;
      if (fromUid == null || fromUid.isEmpty || fromUid == my) return;

      tx.update(ref, {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      final peerRef =
          _db.collection('users').doc(my).collection('friend_peers').doc(fromUid);
      tx.set(
        peerRef,
        {
          'peerUid': fromUid,
          'since': FieldValue.serverTimestamp(),
          'requestId': requestId,
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Prieteni confirmați (doc-uri sub `users/me/friend_peers`).
  Future<Set<String>> loadFriendPeerUidSet() async {
    final my = _uid;
    if (my == null) return {};
    try {
      final snap =
          await _db.collection('users').doc(my).collection('friend_peers').get();
      return snap.docs.map((d) => d.id).toSet();
    } catch (e) {
      Logger.warning('loadFriendPeerUidSet: $e', tag: 'SOCIAL');
      return {};
    }
  }

  Stream<Set<String>> friendPeerUidsStream() {
    final my = _uid;
    if (my == null) return Stream.value({});
    return _db
        .collection('users')
        .doc(my)
        .collection('friend_peers')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  /// Dacă cineva ți-a acceptat cererea (ești `fromUid`), îți creăm și ție intrarea `friend_peers`.
  Future<void> ensureFriendPeersForAcceptedOutgoing() async {
    final my = _uid;
    if (my == null) return;
    try {
      final snap =
          await _db.collection('friend_requests').where('fromUid', isEqualTo: my).get();
      for (final d in snap.docs) {
        final m = d.data();
        if (m['status'] != 'accepted') continue;
        final to = m['toUid'] as String?;
        if (to == null || to.isEmpty || to == my) continue;
        await _db.collection('users').doc(my).collection('friend_peers').doc(to).set(
          {
            'peerUid': to,
            'since': FieldValue.serverTimestamp(),
            'requestId': d.id,
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      Logger.warning('ensureFriendPeersForAcceptedOutgoing: $e', tag: 'SOCIAL');
    }
  }

  Future<void> rejectRequest(String requestId) async {
    final my = _uid;
    if (my == null) return;
    final ref = _db.collection('friend_requests').doc(requestId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final m = snap.data()!;
      if (m['toUid'] != my || m['status'] != 'pending') return;
      tx.update(ref, {
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Șterge prietenul din lista ta (`friend_peers`). Celălalt user își păstrează intrarea până o șterge și el.
  Future<void> removeFriendPeer(String peerUid) async {
    final my = _uid;
    if (my == null || peerUid.isEmpty || peerUid == my) return;
    try {
      await _db
          .collection('users')
          .doc(my)
          .collection('friend_peers')
          .doc(peerUid)
          .delete();
    } catch (e) {
      Logger.error('removeFriendPeer: $e', error: e, tag: 'SOCIAL');
      rethrow;
    }
  }
}
