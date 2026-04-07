import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/models/subscription_plan_doc.dart';
import 'package:nabour_app/models/token_wallet_model.dart';

/// Citește `subscription_plans/*` din Firestore; dacă lipsește, folosește valorile din [TokenPlan].
class SubscriptionCatalogService {
  SubscriptionCatalogService._();
  static final SubscriptionCatalogService instance = SubscriptionCatalogService._();

  final _db = FirebaseFirestore.instance;

  /// Override alocare lunară pentru un plan (din Firestore sau null = default enum).
  Future<int> monthlyAllowanceFor(TokenPlan plan) async {
    try {
      final snap = await _db.collection('subscription_plans').doc(plan.name).get();
      final m = snap.data();
      if (m == null) return plan.monthlyAllowance;
      final v = (m['monthlyAllowance'] as num?)?.toInt();
      return v ?? plan.monthlyAllowance;
    } catch (_) {
      return plan.monthlyAllowance;
    }
  }

  /// Lista de planuri pentru UI: documente Firestore + completare cu enum lipsă.
  Stream<List<SubscriptionPlanDoc>> get plansStream {
    return _db
        .collection('subscription_plans')
        .orderBy('displayOrder')
        .snapshots()
        .map((qs) {
      final fromFs = qs.docs
          .map((d) => SubscriptionPlanDoc.fromFirestore(d.id, d.data()))
          .toList();
      if (fromFs.isEmpty) return defaultPlanDocs();
      final ids = fromFs.map((e) => e.planId).toSet();
      final merged = List<SubscriptionPlanDoc>.from(fromFs);
      for (final p in TokenPlan.values) {
        if (!ids.contains(p.name)) {
          merged.add(docFromEnum(p));
        }
      }
      merged.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return merged;
    });
  }

  /// Folosit când Firestore e gol sau la erori de rețea în UI.
  List<SubscriptionPlanDoc> defaultPlanDocs() =>
      TokenPlan.values.map(docFromEnum).toList();

  SubscriptionPlanDoc docFromEnum(TokenPlan p) {
    final order = switch (p) {
      TokenPlan.free => 0,
      TokenPlan.basic => 1,
      TokenPlan.pro => 2,
      TokenPlan.unlimited => 3,
    };
    return SubscriptionPlanDoc(
      planId: p.name,
      monthlyAllowance: p.monthlyAllowance,
      displayOrder: order,
    );
  }
}
