class PriceEstimateService {
  /// Calculează estimarea de preț pentru o cursă
  double estimatePrice({
    required double distanceKm,
    required int durationMin,
    double baseFare = 10.0,
    double perKm = 2.5,
    double perMin = 0.5,
    double surgeMultiplier = 1.0,
  }) {
    final price = baseFare + (distanceKm * perKm) + (durationMin * perMin);
    return price * surgeMultiplier;
  }
}

