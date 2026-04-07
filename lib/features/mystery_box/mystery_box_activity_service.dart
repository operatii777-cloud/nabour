import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final int rewardTokens;
  final DateTime? createdAt;

  const CommunityBoxPlacerNotification({
    required this.id,
    required this.boxId,
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

class MysteryBoxActivityService {
  MysteryBoxActivityService._();
  static final MysteryBoxActivityService instance = MysteryBoxActivityService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Cutii comunitare plasate de utilizator; sortate cele mai noi primele.
  Stream<List<UserPlacedCommunityBox>> placedCommunityBoxesStream() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value([]);
    }
    return _db
        .collection('community_mystery_boxes')
        .where('placerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(UserPlacedCommunityBox.fromDoc).toList();
      int t(UserPlacedCommunityBox b) =>
          (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).millisecondsSinceEpoch;
      list.sort((a, b) => t(b).compareTo(t(a)));
      return list;
    });
  }

  /// Cutii comunitare deschise de utilizatorul curent.
  Stream<List<UserCommunityBoxClaim>> myCommunityClaimsStream() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value([]);
    }
    return _db
        .collection('community_mystery_boxes')
        .where('claimedByUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(UserCommunityBoxClaim.fromDoc).toList();
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
}
