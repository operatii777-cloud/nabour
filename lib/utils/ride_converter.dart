// Centralized converter for Ride and RideRequest models
// Eliminates inconsistencies and data loss during conversion

import 'dart:math' as math;
import '../models/ride_model.dart';
import '../models/voice_models.dart';

/// Converter for Ride and RideRequest models
/// Prevents data loss and inconsistencies during conversion
class RideConverter {
  /// Convert RideRequest to Ride
  /// Fills missing fields with defaults or calculated values
  static Ride rideRequestToRide(RideRequest rideRequest, {String? rideId}) {
    // Parse category
    RideCategory category;
    switch (rideRequest.category.toLowerCase()) {
      case 'standard':
        category = RideCategory.standard;
        break;
      case 'family':
        category = RideCategory.family;
        break;
      case 'energy':
        category = RideCategory.energy;
        break;
      case 'best':
        category = RideCategory.best;
        break;
      default:
        category = RideCategory.standard;
    }
    
    // Calculate distance if coordinates are available
    double distance = 0.0;
    if (rideRequest.pickupLatitude != null &&
        rideRequest.pickupLongitude != null &&
        rideRequest.destinationLatitude != null &&
        rideRequest.destinationLongitude != null) {
      distance = _calculateHaversineDistance(
        rideRequest.pickupLatitude!,
        rideRequest.pickupLongitude!,
        rideRequest.destinationLatitude!,
        rideRequest.destinationLongitude!,
      );
    }
    
    // Calculate pricing (simplified - should use PricingService in production)
    final baseFare = _getBaseFareForCategory(category);
    final perKmRate = _getPerKmRateForCategory(category);
    final perMinRate = _getPerMinRateForCategory(category);
    
    // Estimate duration (15 min default, or calculate from distance)
    final durationInMinutes = distance > 0 
        ? (distance / 50.0 * 60.0) // Assume average speed 50 km/h
        : 15.0;
    
    final totalCost = rideRequest.estimatedPrice;
    final appCommission = totalCost * 0.20; // 20% commission
    final driverEarnings = totalCost - appCommission;
    
    return Ride(
      id: rideId ?? rideRequest.id,
      passengerId: rideRequest.passengerId,
      startAddress: rideRequest.pickupLocation,
      destinationAddress: rideRequest.destination,
      distance: distance,
      startLatitude: rideRequest.pickupLatitude,
      startLongitude: rideRequest.pickupLongitude,
      destinationLatitude: rideRequest.destinationLatitude,
      destinationLongitude: rideRequest.destinationLongitude,
      durationInMinutes: durationInMinutes,
      baseFare: baseFare,
      perKmRate: perKmRate,
      perMinRate: perMinRate,
      totalCost: totalCost,
      appCommission: appCommission,
      driverEarnings: driverEarnings,
      timestamp: rideRequest.timestamp,
      status: rideRequest.status,
      category: category,
      searchRadius: 5.0,
      searchStartTime: rideRequest.timestamp,
      stops: [], // RideRequest doesn't have stops
      declinedBy: [],
    );
  }

  /// Convert Ride to RideRequest
  /// Extracts relevant fields for voice flow
  static RideRequest rideToRideRequest(Ride ride) {
    return RideRequest(
      id: ride.id,
      passengerId: ride.passengerId,
      pickupLocation: ride.startAddress,
      destination: ride.destinationAddress,
      estimatedPrice: ride.totalCost,
      category: ride.category.name,
      urgency: 'normal', // Default - Ride doesn't have urgency
      timestamp: ride.timestamp,
      status: ride.status,
      pickupLatitude: ride.startLatitude,
      pickupLongitude: ride.startLongitude,
      destinationLatitude: ride.destinationLatitude,
      destinationLongitude: ride.destinationLongitude,
      isVoiceRequest: false, // Ride from UI is not voice request
    );
  }

  /// Helper: Calculate Haversine distance
  static double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Helper: Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Helper: Get base fare for category
  static double _getBaseFareForCategory(RideCategory category) {
    switch (category) {
      case RideCategory.any:
      case RideCategory.standard:
        return 5.0;
      case RideCategory.family:
        return 6.0;
      case RideCategory.energy:
        return 7.0;
      case RideCategory.best:
        return 10.0;
      case RideCategory.utility:
        return 8.0;
    }
  }

  /// Helper: Get per km rate for category
  static double _getPerKmRateForCategory(RideCategory category) {
    switch (category) {
      case RideCategory.any:
      case RideCategory.standard:
        return 2.0;
      case RideCategory.family:
        return 2.5;
      case RideCategory.energy:
        return 2.2;
      case RideCategory.best:
        return 3.0;
      case RideCategory.utility:
        return 2.8;
    }
  }

  /// Helper: Get per min rate for category
  static double _getPerMinRateForCategory(RideCategory category) {
    switch (category) {
      case RideCategory.any:
      case RideCategory.standard:
        return 0.3;
      case RideCategory.family:
        return 0.35;
      case RideCategory.energy:
        return 0.32;
      case RideCategory.best:
        return 0.5;
      case RideCategory.utility:
        return 0.4;
    }
  }
}

// Extension methods for easier conversion
extension RideRequestExtension on RideRequest {
  /// Convert to Ride
  Ride toRide({String? rideId}) {
    return RideConverter.rideRequestToRide(this, rideId: rideId);
  }
}

extension RideExtension on Ride {
  /// Convert to RideRequest
  RideRequest toRideRequest() {
    return RideConverter.rideToRideRequest(this);
  }
}

