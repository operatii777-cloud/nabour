import 'package:nabour_app/models/ride_model.dart';

/// Nabour — cursele sunt GRATUITE între vecini.
/// Această clasă calculează doar estimări de distanță și durată pentru afișare.
class PricingService {
  static const double _perKmRate = 0.0;
  static const double _perMinRate = 0.0;
  static const int freeWaitMinutes = 0;
  static const double waitFeePerMinute = 0.0;

  Map<String, double> calculateFare({
    required double distanceInKm,
    required double durationInMinutes,
    required RideCategory category,
  }) {
    return {
      'baseFare': 0.0,
      'perKmRate': _perKmRate,
      'perMinRate': _perMinRate,
      'totalCost': 0.0,
      'originalCost': 0.0,
      'discount': 0.0,
      'appCommission': 0.0,
      'driverEarnings': 0.0,
      'surgeMultiplier': 1.0,
      'categoryMultiplier': 1.0,
      'distanceKm': distanceInKm,
      'durationMin': durationInMinutes,
    };
  }

  Future<Map<String, double>> calculateFareWithSurge({
    required double distanceInKm,
    required double durationInMinutes,
    required RideCategory category,
    required double latitude,
    required double longitude,
  }) async {
    return calculateFare(
      distanceInKm: distanceInKm,
      durationInMinutes: durationInMinutes,
      category: category,
    );
  }

  static double calculateWaitTimeFee(DateTime waitStartedAt) => 0.0;

  Future<double> calculatePrice({
    required String pickup,
    required String destination,
    required RideCategory category,
  }) async => 0.0;
}
