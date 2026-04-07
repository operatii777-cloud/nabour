import 'package:cloud_firestore/cloud_firestore.dart';

/// Model pentru sistem de referral (invită prieteni) - Uber-like
enum ReferralStatus {
  pending,      // Așteaptă înregistrare
  completed,     // Utilizatorul s-a înregistrat
  rewarded,      // Recompensa a fost acordată
  expired,       // Expirat
}

class Referral {
  final String id;
  final String referrerId; // ID-ul utilizatorului care invită
  final String? referredEmail; // Email-ul utilizatorului invitat
  final String? referredPhone; // Telefonul utilizatorului invitat
  final String referralCode; // Codul de referral unic
  final Timestamp createdAt;
  final Timestamp? completedAt;
  final Timestamp? rewardedAt;
  final Timestamp? expiresAt;
  final ReferralStatus status;
  final double? referrerReward; // Recompensa pentru cel care invită
  final double? referredReward; // Recompensa pentru cel invitat
  final bool referrerRewardClaimed;
  final bool referredRewardClaimed;

  const Referral({
    required this.id,
    required this.referrerId,
    this.referredEmail,
    this.referredPhone,
    required this.referralCode,
    required this.createdAt,
    this.completedAt,
    this.rewardedAt,
    this.expiresAt,
    required this.status,
    this.referrerReward,
    this.referredReward,
    this.referrerRewardClaimed = false,
    this.referredRewardClaimed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referrerId': referrerId,
      if (referredEmail != null) 'referredEmail': referredEmail,
      if (referredPhone != null) 'referredPhone': referredPhone,
      'referralCode': referralCode,
      'createdAt': createdAt,
      if (completedAt != null) 'completedAt': completedAt,
      if (rewardedAt != null) 'rewardedAt': rewardedAt,
      if (expiresAt != null) 'expiresAt': expiresAt,
      'status': status.name,
      if (referrerReward != null) 'referrerReward': referrerReward,
      if (referredReward != null) 'referredReward': referredReward,
      'referrerRewardClaimed': referrerRewardClaimed,
      'referredRewardClaimed': referredRewardClaimed,
    };
  }

  factory Referral.fromMap(Map<String, dynamic> map) {
    return Referral(
      id: map['id'] ?? '',
      referrerId: map['referrerId'] ?? '',
      referredEmail: map['referredEmail'],
      referredPhone: map['referredPhone'],
      referralCode: map['referralCode'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      completedAt: map['completedAt'],
      rewardedAt: map['rewardedAt'],
      expiresAt: map['expiresAt'],
      status: ReferralStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => ReferralStatus.pending,
      ),
      referrerReward: (map['referrerReward'] as num?)?.toDouble(),
      referredReward: (map['referredReward'] as num?)?.toDouble(),
      referrerRewardClaimed: map['referrerRewardClaimed'] ?? false,
      referredRewardClaimed: map['referredRewardClaimed'] ?? false,
    );
  }

  /// Verifică dacă referral-ul este valid
  bool get isValid {
    if (status == ReferralStatus.completed || status == ReferralStatus.rewarded) {
      return true;
    }
    if (expiresAt != null) {
      return DateTime.now().isBefore(expiresAt!.toDate());
    }
    return status == ReferralStatus.pending;
  }
}

/// Model pentru statistici de referral
class ReferralStats {
  final String userId;
  final int totalReferrals;
  final int completedReferrals;
  final int rewardedReferrals;
  final double totalRewardsEarned;
  final String referralCode;

  const ReferralStats({
    required this.userId,
    required this.totalReferrals,
    required this.completedReferrals,
    required this.rewardedReferrals,
    required this.totalRewardsEarned,
    required this.referralCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalReferrals': totalReferrals,
      'completedReferrals': completedReferrals,
      'rewardedReferrals': rewardedReferrals,
      'totalRewardsEarned': totalRewardsEarned,
      'referralCode': referralCode,
    };
  }

  factory ReferralStats.fromMap(Map<String, dynamic> map) {
    return ReferralStats(
      userId: map['userId'] ?? '',
      totalReferrals: map['totalReferrals'] ?? 0,
      completedReferrals: map['completedReferrals'] ?? 0,
      rewardedReferrals: map['rewardedReferrals'] ?? 0,
      totalRewardsEarned: (map['totalRewardsEarned'] as num?)?.toDouble() ?? 0.0,
      referralCode: map['referralCode'] ?? '',
    );
  }
}

