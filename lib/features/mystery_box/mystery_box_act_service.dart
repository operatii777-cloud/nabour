import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:nabour_app/features/mystery_box/comm_mystery_box_service.dart';
import 'package:nabour_app/features/mystery_box/comm_mystery_map_refresh.dart';

/// Inregistrare cutie comunitara plasata de utilizator (citire Firestore).
class UserPlacedCommunityBox {
  final String id;
  final String status;
  final String message;
  final double latitude;
  final double longitude;
  final int rewardTokens;
  final DateTime? createdAt;
  final DateTime? claimedAt;

  const UserPlacedCommunityBox({
    required this.id,
    required this.status,
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.rewardTokens,
    this.createdAt,
    this.claimedAt,
  });

  static UserPlacedCommunityBox fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? fromTs(dynamic x) => x is Timestamp ? x.toDate() : null;
    return UserPlacedCommunityBox(
      id: doc.id,
      status: d['status'] as String? ?? '',
      message: d['message'] as String? ?? '',
      latitude: (d['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (d['longitude'] as num?)?.toDouble() ?? 0,
      rewardTokens: (d['rewardTokens'] as num?)?.toInt() ?? 50,
      createdAt: fromTs(d['createdAt']),
      claimedAt: fromTs(d['claimedAt']),
    );
  }
}

/// Deschidere cutie comunitara de catre utilizatorul curent.
class UserCommunityBoxClaim {
  final String boxId;
  final String message;
  final int rewardTokens;
  final DateTime? claimedAt;

  const UserCommunityBoxClaim({
    required this.boxId,
    required this.message,
    required this.rewardTokens,
    this.claimedAt,
  });

  static UserCommunityBoxClaim fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['claimedAt'];
    return UserCommunityBoxClaim(
      boxId: doc.id,
      message: d['message'] as String? ?? '',
      rewardTokens: (d['rewardTokens'] as num?)?.toInt() ?? 50,
      claimedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// Notificare pentru plasator: cineva a deschis o cutie.
class CommunityBoxPlacerNotification {
  final String id;
  final String boxId;
  final String openerUid;
  final String openerName;
  final int rewardTokens;
  final DateTime? createdAt;

  const CommunityBoxPlacerNotification({
    required this.id,
    required this.boxId,
    required this.openerUid,
    required this.openerName,
    required this.rewardTokens,
    this.createdAt,
  });

  static CommunityBoxPlacerNotification fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return CommunityBoxPlacerNotification(
      id: doc.id,
      boxId: d['boxId'] as String? ?? '',
      openerUid: d['openerUid'] as String? ?? '',
      openerName: d['openerName'] as String? ?? '',
      rewardTokens: (d['rewardTokens'] as num?)?.toInt() ?? 50,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// Cutie business deschisa (log scris de Cloud Function).
class UserOpenedBusinessMysteryBox {
  final String id;
  final String businessName;
  final String offerId;
  final String redemptionCode;
  final DateTime? openedAt;

  const UserOpenedBusinessMysteryBox({
    required this.id,
    required this.businessName,
    required this.offerId,
    required this.redemptionCode,
    this.openedAt,
  });

  static UserOpenedBusinessMysteryBox fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['openedAt'];
    return UserOpenedBusinessMysteryBox(
      id: doc.id,
      businessName: d['businessName'] as String? ?? '',
      offerId: d['offerId'] as String? ?? '',
      redemptionCode: d['redemptionCode'] as String? ?? '',
      openedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

Stream<T> _combineLatest2<X, Y, T>(
  Stream<X> streamA,
  Stream<Y> streamB,
  T Function(X a, Y b) combine,
) {
  final controller = StreamController<T>();
  X? lastA;
  Y? lastB;
  var hasA = false;
  var hasB = false;
  void emit() {
    if (hasA && hasB) {
      controller.add(combine(lastA as X, lastB as Y));
    }
  }

  final subA = streamA.listen(
    (v) {
      lastA = v;
      hasA = true;
      emit();
    },
    onError: controller.addError,
  );
  final subB = streamB.listen(
    (v) {
      lastB = v;
      hasB = true;
      emit();
    },
    onError: controller.addError,
  );
  controller.onCancel = () {
    subA.cancel();
    subB.cancel();
  };
  return controller.stream;
}

class MysteryBoxActivityService {
  MysteryBoxActivityService._();
  static final MysteryBoxActivityService instance = MysteryBoxActivityService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _hiddenPlacedCol(String uid) =>
      _db.collection('users').doc(uid).collection('hidden_community_placed_boxes');

  CollectionReference<Map<String, dynamic>> _hiddenClaimCol(String uid) =>
      _db.collection('users').doc(uid).collection('hidden_community_claim_boxes');

  /// Cutii comunitare plasate de utilizator; sortate cele mai noi primele.
  /// Fără rândurile ascunse din istoricul personal.
  Stream<List<UserPlacedCommunityBox>> placedCommunityBoxesStream() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value([]);
    }
    final placed = _db
        .collection('community_mystery_boxes')
        .where('placerUid', isEqualTo: uid)
        .snapshots();
    final hidden = _hiddenPlacedCol(uid).snapshots();
    return _combineLatest2(placed, hidden, (placedSnap, hiddenSnap) {
      final hiddenIds = hiddenSnap.docs.map((d) => d.id).toSet();
      final list = placedSnap.docs
          .where((d) => !hiddenIds.contains(d.id))
          .map(UserPlacedCommunityBox.fromDoc)
          .toList();
      int t(UserPlacedCommunityBox b) =>
          (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).millisecondsSinceEpoch;
      list.sort((a, b) => t(b).compareTo(t(a)));
      return list;
    });
  }

  /// Cutii comunitare deschise de utilizatorul curent (fără rânduri ascunse).
  Stream<List<UserCommunityBoxClaim>> myCommunityClaimsStream() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value([]);
    }
    final claims = _db
        .collection('community_mystery_boxes')
        .where('claimedByUid', isEqualTo: uid)
        .snapshots();
    final hidden = _hiddenClaimCol(uid).snapshots();
    return _combineLatest2(claims, hidden, (claimSnap, hiddenSnap) {
      final hiddenIds = hiddenSnap.docs.map((d) => d.id).toSet();
      final list = claimSnap.docs
          .where((d) => !hiddenIds.contains(d.id))
          .map(UserCommunityBoxClaim.fromDoc)
          .toList();
      int t(UserCommunityBoxClaim b) =>
          (b.claimedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).millisecondsSinceEpoch;
      list.sort((a, b) => t(b).compareTo(t(a)));
      return list;
    });
  }

  /// Notificari pentru plasator (deschideri ale cutiilor tale).
  Stream<List<CommunityBoxPlacerNotification>> placerNotificationsStream() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value([]);
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('community_mystery_notifications')
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map(
          (snap) => snap.docs.map(CommunityBoxPlacerNotification.fromDoc).toList(),
        );
  }

  /// Deschideri cutii business (o inregistrare per magazin/zi in practica).
  Stream<List<UserOpenedBusinessMysteryBox>> openedBusinessBoxesStream() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value([]);
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('opened_mystery_boxes')
        .orderBy('openedAt', descending: true)
        .limit(80)
        .snapshots()
        .map(
          (snap) => snap.docs.map(UserOpenedBusinessMysteryBox.fromDoc).toList(),
        );
  }

  /// Ascunde din lista „Plasate” o cutie deja inchisa/anulata (nu sterge cutia globala).
  Future<void> hidePlacedBoxFromActivity(String boxId) async {
    final uid = _uid;
    if (uid == null) return;
    await _hiddenPlacedCol(uid).doc(boxId).set({
      'hiddenAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ascunde din „Deschise de mine” o deschidere la cutie comunitara.
  Future<void> hideCommunityClaimFromActivity(String boxId) async {
    final uid = _uid;
    if (uid == null) return;
    await _hiddenClaimCol(uid).doc(boxId).set({
      'hiddenAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteOpenedBusinessRecord(String docId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('opened_mystery_boxes')
        .doc(docId)
        .delete();
  }

  Future<void> deletePlacerNotification(String docId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('community_mystery_notifications')
        .doc(docId)
        .delete();
  }

  static const int _batchLimit = 450;

  Future<void> _commitInBatches(List<void Function(WriteBatch)> ops) async {
    var batch = _db.batch();
    var n = 0;
    for (final op in ops) {
      op(batch);
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

  /// Sterge din Firestore notificarile si deschiderile business; ascunde toate cutiile
  /// comunitare vizibile in rezumat (plasate + deschise de tine). Nu modifica tokenii.
  Future<void> clearSummaryActivityHistory() async {
    final uid = _uid;
    if (uid == null) return;

    final notifSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('community_mystery_notifications')
        .limit(500)
        .get();
    final bizSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('opened_mystery_boxes')
        .limit(500)
        .get();

    final placedSnap = await _db
        .collection('community_mystery_boxes')
        .where('placerUid', isEqualTo: uid)
        .get();
    final claimSnap = await _db
        .collection('community_mystery_boxes')
        .where('claimedByUid', isEqualTo: uid)
        .get();

    final ops = <void Function(WriteBatch)>[];

    for (final d in notifSnap.docs) {
      final r = d.reference;
      ops.add((b) => b.delete(r));
    }
    for (final d in bizSnap.docs) {
      final r = d.reference;
      ops.add((b) => b.delete(r));
    }
    for (final d in placedSnap.docs) {
      final ref = _hiddenPlacedCol(uid).doc(d.id);
      ops.add((b) => b.set(ref, {'hiddenAt': FieldValue.serverTimestamp()}));
    }
    for (final d in claimSnap.docs) {
      final ref = _hiddenClaimCol(uid).doc(d.id);
      ops.add((b) => b.set(ref, {'hiddenAt': FieldValue.serverTimestamp()}));
    }

    await _commitInBatches(ops);
  }

  /// Fila „Plasate”: retrage toate cutiile active (Functions), apoi ascunde toate rândurile din listă.
  Future<void> clearEntirePlacedTabActivity() async {
    final uid = _uid;
    if (uid == null) return;

    await CommunityMysteryBoxService.instance.removeAllActiveBoxes();
    CommunityMysteryMapRefresh.instance.notify();

    final placedSnap = await _db
        .collection('community_mystery_boxes')
        .where('placerUid', isEqualTo: uid)
        .get();

    final ops = <void Function(WriteBatch)>[];
    for (final d in placedSnap.docs) {
      final ref = _hiddenPlacedCol(uid).doc(d.id);
      ops.add((b) => b.set(ref, {'hiddenAt': FieldValue.serverTimestamp()}));
    }
    await _commitInBatches(ops);
  }

  /// Fila „Deschise de mine”: ascunde toate deschiderile comunitare + șterge înregistrările business.
  Future<void> clearEntireMyOpensTabActivity() async {
    final uid = _uid;
    if (uid == null) return;

    final claimSnap = await _db
        .collection('community_mystery_boxes')
        .where('claimedByUid', isEqualTo: uid)
        .get();

    final ops = <void Function(WriteBatch)>[];
    for (final d in claimSnap.docs) {
      final ref = _hiddenClaimCol(uid).doc(d.id);
      ops.add((b) => b.set(ref, {'hiddenAt': FieldValue.serverTimestamp()}));
    }
    await _commitInBatches(ops);

    await _deleteAllUserSubcollectionDocs(
      uid,
      'opened_mystery_boxes',
    );
  }

  /// Fila „Deschideri la cutiile mele”: șterge toate notificările.
  Future<void> clearAllPlacerNotificationsActivity() async {
    final uid = _uid;
    if (uid == null) return;
    await _deleteAllUserSubcollectionDocs(
      uid,
      'community_mystery_notifications',
    );
  }

  Future<void> _deleteAllUserSubcollectionDocs(String uid, String subcollection) async {
    while (true) {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection(subcollection)
          .limit(500)
          .get();
      if (snap.docs.isEmpty) break;
      final ops = <void Function(WriteBatch)>[];
      for (final d in snap.docs) {
        final r = d.reference;
        ops.add((b) => b.delete(r));
      }
      await _commitInBatches(ops);
    }
  }
}
