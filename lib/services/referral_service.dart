import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/referral_model.dart';
import 'package:uuid/uuid.dart';
import 'package:nabour_app/utils/logger.dart';

/// Serviciu pentru sistemul de referral (invită prieteni) - Uber-like
class ReferralService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const double _referrerRewardAmount = 15.0; // RON
  static const double _referredRewardAmount = 10.0; // RON
  static const int _referralExpiryDays = 30;

  /// Generează și stochează un cod de referral unic pentru utilizator
  Future<String?> createReferralCode(String userId) async {
    try {
      final code = _generateCode(userId);
      await _db.collection('referral_codes').doc(userId).set({
        'userId': userId,
        'code': code,
        'createdAt': Timestamp.now(),
      }, SetOptions(merge: true));
      return code;
    } catch (e) {
      Logger.error('Error creating referral code: $e', tag: 'REFERRAL', error: e);
      return null;
    }
  }

  /// Obține codul de referral al utilizatorului (sau îl creează)
  Future<String?> getReferralCode(String userId) async {
    try {
      final doc = await _db.collection('referral_codes').doc(userId).get();
      if (doc.exists && doc.data()?['code'] != null) {
        return doc.data()!['code'] as String;
      }
      return await createReferralCode(userId);
    } catch (e) {
      Logger.error('Error getting referral code: $e', tag: 'REFERRAL', error: e);
      return null;
    }
  }

  /// Procesează utilizarea unui cod de referral de către un utilizator nou
  Future<bool> processReferralCode(String code, String newUserId) async {
    try {
      // Caută utilizatorul care deține codul
      final codeDoc = await _db
          .collection('referral_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (codeDoc.docs.isEmpty) {
        Logger.warning('Code not found: $code', tag: 'REFERRAL');
        return false;
      }

      final referrerId = codeDoc.docs.first.data()['userId'] as String;

      // Evită auto-referral
      if (referrerId == newUserId) {
        Logger.warning('Self-referral attempt: $newUserId', tag: 'REFERRAL');
        return false;
      }

      // Verifică dacă utilizatorul nou a mai folosit un cod
      final existingReferral = await _db
          .collection('referrals')
          .where('referredUserId', isEqualTo: newUserId)
          .limit(1)
          .get();

      if (existingReferral.docs.isNotEmpty) {
        Logger.warning('User already used a referral code: $newUserId', tag: 'REFERRAL');
        return false;
      }

      final referralId = const Uuid().v4();
      final expiresAt = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: _referralExpiryDays)),
      );

      final referral = Referral(
        id: referralId,
        referrerId: referrerId,
        referralCode: code.toUpperCase(),
        createdAt: Timestamp.now(),
        expiresAt: expiresAt,
        status: ReferralStatus.pending,
        referrerReward: _referrerRewardAmount,
        referredReward: _referredRewardAmount,
      );

      await _db.collection('referrals').doc(referralId).set(
            referral.toMap()..['referredUserId'] = newUserId,
          );

      Logger.info('Referral processed: $referralId (referrer: $referrerId, referred: $newUserId)', tag: 'REFERRAL');
      return true;
    } catch (e) {
      Logger.error('Error processing referral code: $e', tag: 'REFERRAL', error: e);
      return false;
    }
  }

  /// Obține lista de referral-uri pentru un utilizator
  Future<List<Referral>> getReferrals(String userId) async {
    try {
      final snapshot = await _db
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Referral.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Logger.error('Error getting referrals: $e', tag: 'REFERRAL', error: e);
      return [];
    }
  }

  /// Revendică recompensa pentru un referral
  Future<bool> claimReward(String referralId, String userId) async {
    try {
      final doc = await _db.collection('referrals').doc(referralId).get();
      if (!doc.exists) return false;

      final referral = Referral.fromMap(doc.data()!);
      final isReferrer = referral.referrerId == userId;
      final isReferred = (doc.data()!['referredUserId'] as String?) == userId;

      if (!isReferrer && !isReferred) return false;

      final updates = <String, dynamic>{
        'status': ReferralStatus.rewarded.name,
        'rewardedAt': Timestamp.now(),
      };

      if (isReferrer && !referral.referrerRewardClaimed) {
        updates['referrerRewardClaimed'] = true;
      }
      if (isReferred && !referral.referredRewardClaimed) {
        updates['referredRewardClaimed'] = true;
      }

      await _db.collection('referrals').doc(referralId).update(updates);
      Logger.info('Reward claimed: $referralId by $userId', tag: 'REFERRAL');
      return true;
    } catch (e) {
      Logger.error('Error claiming reward: $e', tag: 'REFERRAL', error: e);
      return false;
    }
  }

  /// Obține statisticile de referral pentru un utilizator
  Future<ReferralStats?> getReferralStats(String userId) async {
    try {
      final referralCode = await getReferralCode(userId);
      if (referralCode == null) return null;

      final snapshot = await _db
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .get();

      final int total = snapshot.docs.length;
      int completed = 0;
      int rewarded = 0;
      double totalRewards = 0.0;

      for (final doc in snapshot.docs) {
        final r = Referral.fromMap(doc.data());
        if (r.status == ReferralStatus.completed ||
            r.status == ReferralStatus.rewarded) {
          completed++;
        }
        if (r.status == ReferralStatus.rewarded && r.referrerRewardClaimed) {
          rewarded++;
          totalRewards += r.referrerReward ?? 0.0;
        }
      }

      return ReferralStats(
        userId: userId,
        totalReferrals: total,
        completedReferrals: completed,
        rewardedReferrals: rewarded,
        totalRewardsEarned: totalRewards,
        referralCode: referralCode,
      );
    } catch (e) {
      Logger.error('Error getting referral stats: $e', tag: 'REFERRAL', error: e);
      return null;
    }
  }

  /// Generează un cod unic folosind UUID pentru a preveni ghicirea codurilor
  String _generateCode(String userId) {
    const prefix = 'FR';
    final uuid = const Uuid()
        .v4()
        .replaceAll('-', '')
        .substring(0, 8)
        .toUpperCase();
    return '$prefix$uuid';
  }

  /// Obține utilizatorul curent autentificat
  User? get currentUser => _auth.currentUser;
}
