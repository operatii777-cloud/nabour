import 'package:nabour_app/models/token_wallet_model.dart';

/// Estimări lunare: câte acțiuni tipice încap în alocarea de tokeni (costuri din [TokenCost]).
class TokenEconomySummary {
  const TokenEconomySummary({
    required this.monthlyTokens,
    required this.aiQueries,
    required this.routeCalcs,
    required this.geocodings,
    required this.broadcastPosts,
    required this.businessOffers,
    required this.isUnlimited,
  });

  final int monthlyTokens;
  final int aiQueries;
  final int routeCalcs;
  final int geocodings;
  final int broadcastPosts;
  final int businessOffers;
  final bool isUnlimited;

  factory TokenEconomySummary.fromMonthlyAllowance(int allowance) {
    if (allowance >= 999999998) {
      return const TokenEconomySummary(
        monthlyTokens: 0,
        aiQueries: 0,
        routeCalcs: 0,
        geocodings: 0,
        broadcastPosts: 0,
        businessOffers: 0,
        isUnlimited: true,
      );
    }
    final ai = TokenCost.aiQuery > 0 ? allowance ~/ TokenCost.aiQuery : 0;
    final routes = TokenCost.routeCalc > 0 ? allowance ~/ TokenCost.routeCalc : 0;
    final geo = TokenCost.geocoding > 0 ? allowance ~/ TokenCost.geocoding : 0;
    final br = TokenCost.broadcastPost > 0 ? allowance ~/ TokenCost.broadcastPost : 0;
    final biz = TokenCost.businessOffer > 0 ? allowance ~/ TokenCost.businessOffer : 0;
    return TokenEconomySummary(
      monthlyTokens: allowance,
      aiQueries: ai,
      routeCalcs: routes,
      geocodings: geo,
      broadcastPosts: br,
      businessOffers: biz,
      isUnlimited: false,
    );
  }

  factory TokenEconomySummary.forPlan(TokenPlan plan) =>
      TokenEconomySummary.fromMonthlyAllowance(plan.monthlyAllowance);
}
