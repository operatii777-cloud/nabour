import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/models/ride_model.dart';

/// Model pentru batch offers (multiple oferte simultan către șofer)
class BatchOffer {
  final String id;
  final String driverId;
  final List<BatchOfferRide> rides;
  final DateTime createdAt;
  final DateTime expiresAt;
  final BatchOfferStatus status;

  const BatchOffer({
    required this.id,
    required this.driverId,
    required this.rides,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'rides': rides.map((r) => r.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status.name,
    };
  }

  factory BatchOffer.fromMap(Map<String, dynamic> map) {
    return BatchOffer(
      id: map['id'] ?? '',
      driverId: map['driverId'] ?? '',
      rides: (map['rides'] as List<dynamic>?)
              ?.map((r) => BatchOfferRide.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: BatchOfferStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => BatchOfferStatus.pending,
      ),
    );
  }
}

class BatchOfferRide {
  final String rideId;
  final String passengerName;
  final String pickupAddress;
  final String destinationAddress;
  final double distanceKm;
  final double estimatedFare;
  final int estimatedDurationMinutes;
  final double driverDistanceKm;
  final double driverEtaMinutes;
  final RideCategory category;

  const BatchOfferRide({
    required this.rideId,
    required this.passengerName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.distanceKm,
    required this.estimatedFare,
    required this.estimatedDurationMinutes,
    required this.driverDistanceKm,
    required this.driverEtaMinutes,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'passengerName': passengerName,
      'pickupAddress': pickupAddress,
      'destinationAddress': destinationAddress,
      'distanceKm': distanceKm,
      'estimatedFare': estimatedFare,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'driverDistanceKm': driverDistanceKm,
      'driverEtaMinutes': driverEtaMinutes,
      'category': category.name,
    };
  }

  factory BatchOfferRide.fromMap(Map<String, dynamic> map) {
    return BatchOfferRide(
      rideId: map['rideId'] ?? '',
      passengerName: map['passengerName'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      destinationAddress: map['destinationAddress'] ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      estimatedFare: (map['estimatedFare'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMinutes: map['estimatedDurationMinutes'] ?? 0,
      driverDistanceKm: (map['driverDistanceKm'] as num?)?.toDouble() ?? 0.0,
      driverEtaMinutes: (map['driverEtaMinutes'] as num?)?.toDouble() ?? 0.0,
      category: RideCategory.values.firstWhere(
        (e) => e.name == (map['category'] ?? 'standard'),
        orElse: () => RideCategory.standard,
      ),
    );
  }
}

enum BatchOfferStatus {
  pending,    // Așteaptă răspuns de la șofer
  accepted,   // Șoferul a acceptat o ofertă
  declined,   // Șoferul a refuzat toate ofertele
  expired,    // Ofertele au expirat
}

