import 'package:nabour_app/models/token_wallet_model.dart';

/// Document `subscription_plans/{planId}` în Firestore (planId = free | basic | pro | unlimited).
class SubscriptionPlanDoc {
  const SubscriptionPlanDoc({
    required this.planId,
    required this.monthlyAllowance,
    this.priceRonPerMonth,
    this.displayOrder = 0,
    this.subtitleRo,
    this.subtitleEn,
  });

  final String planId;
  final int monthlyAllowance;
  final double? priceRonPerMonth;
  final int displayOrder;
  final String? subtitleRo;
  final String? subtitleEn;

  TokenPlan? get tokenPlan {
    try {
      return TokenPlan.values.firstWhere((p) => p.name == planId);
    } catch (_) {
      return null;
    }
  }

  factory SubscriptionPlanDoc.fromFirestore(String id, Map<String, dynamic> m) {
    return SubscriptionPlanDoc(
      planId: m['planId'] as String? ?? id,
      monthlyAllowance: (m['monthlyAllowance'] as num?)?.toInt() ?? 1000,
      priceRonPerMonth: (m['priceRonPerMonth'] as num?)?.toDouble(),
      displayOrder: (m['displayOrder'] as num?)?.toInt() ?? 0,
      subtitleRo: m['subtitleRo'] as String?,
      subtitleEn: m['subtitleEn'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'planId': planId,
        'monthlyAllowance': monthlyAllowance,
        if (priceRonPerMonth != null) 'priceRonPerMonth': priceRonPerMonth,
        'displayOrder': displayOrder,
        if (subtitleRo != null) 'subtitleRo': subtitleRo,
        if (subtitleEn != null) 'subtitleEn': subtitleEn,
      };
}
