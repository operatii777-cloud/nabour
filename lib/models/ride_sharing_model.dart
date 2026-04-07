import 'package:cloud_firestore/cloud_firestore.dart';

/// Model pentru ride sharing (călătorie partajată) - Uber-like
class RideShare {
  final String id;
  final String rideId;
  final String passengerId;
  final String pickupAddress;
  final String destinationAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final Timestamp requestedAt;
  final String status; // pending, matched, in_progress, completed, cancelled
  final String? matchedRideId; // ID-ul cursei cu care s-a făcut match
  final double? sharedCost; // Costul partajat
  final double? originalCost; // Costul original (fără sharing)

  const RideShare({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.requestedAt,
    required this.status,
    this.matchedRideId,
    this.sharedCost,
    this.originalCost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rideId': rideId,
      'passengerId': passengerId,
      'pickupAddress': pickupAddress,
      'destinationAddress': destinationAddress,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'requestedAt': requestedAt,
      'status': status,
      if (matchedRideId != null) 'matchedRideId': matchedRideId,
      if (sharedCost != null) 'sharedCost': sharedCost,
      if (originalCost != null) 'originalCost': originalCost,
    };
  }

  factory RideShare.fromMap(Map<String, dynamic> map) {
    return RideShare(
      id: map['id'] ?? '',
      rideId: map['rideId'] ?? '',
      passengerId: map['passengerId'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      destinationAddress: map['destinationAddress'] ?? '',
      pickupLatitude: (map['pickupLatitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (map['pickupLongitude'] as num?)?.toDouble() ?? 0.0,
      destinationLatitude: (map['destinationLatitude'] as num?)?.toDouble() ?? 0.0,
      destinationLongitude: (map['destinationLongitude'] as num?)?.toDouble() ?? 0.0,
      requestedAt: map['requestedAt'] ?? Timestamp.now(),
      status: map['status'] ?? 'pending',
      matchedRideId: map['matchedRideId'],
      sharedCost: (map['sharedCost'] as num?)?.toDouble(),
      originalCost: (map['originalCost'] as num?)?.toDouble(),
    );
  }
}

