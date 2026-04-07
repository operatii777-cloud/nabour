import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/models/ride_preferences_model.dart';
import 'package:nabour_app/utils/logger.dart';

enum RideCategory { any, standard, family, energy, best, utility }

extension RideCategoryExtension on RideCategory {
  String get displayName {
    switch (this) {
      case RideCategory.any:
        return 'Orice categorie';
      case RideCategory.standard:
        return 'Standard';
      case RideCategory.family:
        return 'Familie';
      case RideCategory.energy:
        return 'Ecologic';
      case RideCategory.best:
        return 'Premium';
      case RideCategory.utility:
        return 'Utilitar';
    }
  }
}

class Ride {
  final String id;
  final String passengerId;  // ✅ MODIFICAT: userId → passengerId pentru claritate
  final String? driverId;
  final String startAddress;
  final String destinationAddress;
  final double distance;

  final double? startLatitude;
  final double? startLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;

  final double? durationInMinutes;
  final double baseFare;
  final double perKmRate;
  final double perMinRate;
  final double totalCost;

  final double appCommission;
  final double driverEarnings;
  final DateTime timestamp;
  final String status;

  final double? passengerRating;
  final String? passengerComment;
  final double? driverRating;
  final String? driverComment;

  final double? driverRatingForPassenger;
  final String? driverCharacterizationForPassenger;

  final double tip;
  final List<Map<String, dynamic>> stops;
  final bool wasCancelled;
  final String? cancelledBy;
  final double? cancellationFee;
  final List<String> declinedBy;
  final RideCategory category;
  final double? searchRadius;
  final DateTime? searchStartTime;
  final String? assignmentMethod;
  final double? driverDistance;
  final DateTime? assignedAt;
  final RidePreferences? ridePreferences;

  // Feature: Pickup code — 4-digit code shown to passenger for driver verification
  final String? pickupCode;

  // Feature: Wait time fee — tracks wait start and accumulated fee
  final DateTime? waitStartedAt;
  final double? waitTimeFee;

  /// PNG traseu înghețat (Firebase Storage download URL), setat la confirmarea pasagerului.
  final String? routePreviewUrl;

  /// Lista de UID-uri ale șoferilor care pot vedea și accepta cursa.
  /// Folosit pentru a limita cursa doar la contactele pasagerului.
  final List<String>? allowedDriverUids;

  const Ride({
    required this.id,
    required this.passengerId,  // ✅ MODIFICAT: userId → passengerId
    this.driverId,
    required this.startAddress,
    required this.destinationAddress,
    required this.distance,
    this.startLatitude,
    this.startLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.durationInMinutes,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinRate,
    required this.totalCost,
    required this.appCommission,
    required this.driverEarnings,
    required this.timestamp,
    required this.status,
    this.passengerRating,
    this.passengerComment,
    this.driverRating,
    this.driverComment,
    this.driverRatingForPassenger,
    this.driverCharacterizationForPassenger,
    this.tip = 0.0,
    this.stops = const [],
    this.wasCancelled = false,
    this.cancelledBy,
    this.cancellationFee,
    this.declinedBy = const [],
    this.category = RideCategory.standard,
    this.searchRadius,
    this.searchStartTime,
    this.assignmentMethod,
    this.driverDistance,
    this.assignedAt,
    this.ridePreferences,
    this.pickupCode,
    this.waitStartedAt,
    this.waitTimeFee,
    this.routePreviewUrl,
    this.allowedDriverUids,
  });

  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,  // ✅ MODIFICAT: userId → passengerId
      'driverId': driverId,
      'startAddress': startAddress,
      'destinationAddress': destinationAddress,
      'distance': distance,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'durationInMinutes': durationInMinutes,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'perMinRate': perMinRate,
      'totalCost': totalCost,
      'appCommission': appCommission,
      'driverEarnings': driverEarnings,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'passengerRating': passengerRating,
      'passengerComment': passengerComment,
      'driverRating': driverRating,
      'driverComment': driverComment,
      'driverRatingForPassenger': driverRatingForPassenger,
      'driverCharacterizationForPassenger': driverCharacterizationForPassenger,
      'tip': tip,
      'stops': stops,
      'wasCancelled': wasCancelled,
      'cancelledBy': cancelledBy,
      'cancellationFee': cancellationFee,
      'declinedBy': declinedBy,
      'category': category.name,
      'searchRadius': searchRadius,
      'searchStartTime': searchStartTime != null ? Timestamp.fromDate(searchStartTime!) : null,
      'assignmentMethod': assignmentMethod,
      'driverDistance': driverDistance,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'ridePreferences': ridePreferences?.toMap(),
      'pickupCode': pickupCode,
      'waitStartedAt': waitStartedAt != null ? Timestamp.fromDate(waitStartedAt!) : null,
      'waitTimeFee': waitTimeFee,
      if (routePreviewUrl != null) 'routePreviewUrl': routePreviewUrl,
      if (allowedDriverUids != null) 'allowedDriverUids': allowedDriverUids,
    };
  }
  
  /// Create Ride from map
  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'] ?? '',
      passengerId: map['passengerId'] ?? '',
      driverId: map['driverId'] ?? '',
      startAddress: map['startAddress'] ?? '',
      destinationAddress: map['destinationAddress'] ?? '',
      distance: (map['distance'] ?? 0.0).toDouble(),
      startLatitude: (map['startLatitude'] ?? 0.0).toDouble(),
      startLongitude: (map['startLongitude'] ?? 0.0).toDouble(),
      destinationLatitude: (map['destinationLatitude'] ?? 0.0).toDouble(),
      destinationLongitude: (map['destinationLongitude'] ?? 0.0).toDouble(),
      durationInMinutes: map['durationInMinutes'] ?? 0,
      baseFare: (map['baseFare'] ?? 0.0).toDouble(),
      perKmRate: (map['perKmRate'] ?? 0.0).toDouble(),
      perMinRate: (map['perMinRate'] ?? 0.0).toDouble(),
      totalCost: (map['totalCost'] ?? 0.0).toDouble(),
      appCommission: (map['appCommission'] ?? 0.0).toDouble(),
      driverEarnings: (map['driverEarnings'] ?? 0.0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      passengerRating: (map['passengerRating'] ?? 0.0).toDouble(),
      passengerComment: map['passengerComment'] ?? '',
      driverRating: (map['driverRating'] ?? 0.0).toDouble(),
      driverComment: map['driverComment'] ?? '',
      driverRatingForPassenger: (map['driverRatingForPassenger'] ?? 0.0).toDouble(),
      driverCharacterizationForPassenger: map['driverCharacterizationForPassenger'] ?? '',
      tip: (map['tip'] ?? 0.0).toDouble(),
      stops: List<Map<String, dynamic>>.from(map['stops'] ?? []),
      wasCancelled: map['wasCancelled'] ?? false,
      cancelledBy: map['cancelledBy'] ?? '',
      cancellationFee: (map['cancellationFee'] ?? 0.0).toDouble(),
      declinedBy: List<String>.from(map['declinedBy'] ?? []),
      category: RideCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => RideCategory.standard,
      ),
      searchRadius: (map['searchRadius'] ?? 5.0).toDouble(),
      searchStartTime: map['searchStartTime'] != null 
        ? (map['searchStartTime'] as Timestamp).toDate() 
        : null,
      assignmentMethod: map['assignmentMethod'] ?? 'automatic',
      driverDistance: (map['driverDistance'] ?? 0.0).toDouble(),
      assignedAt: map['assignedAt'] != null 
        ? (map['assignedAt'] as Timestamp).toDate() 
        : null,
      ridePreferences: map['ridePreferences'] != null
        ? RidePreferences.fromMap(Map<String, dynamic>.from(map['ridePreferences']))
        : null,
      pickupCode: map['pickupCode'],
      waitStartedAt: map['waitStartedAt'] != null
        ? (map['waitStartedAt'] as Timestamp).toDate()
        : null,
      waitTimeFee: (map['waitTimeFee'] as num?)?.toDouble(),
      routePreviewUrl: map['routePreviewUrl'] as String?,
      allowedDriverUids: map['allowedDriverUids'] != null 
          ? List<String>.from(map['allowedDriverUids']) 
          : null,
    );
  }

  factory Ride.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final status = data['status'] ?? 'unknown';
    final driverId = data['driverId'];
    
    // Debug pentru problemele cu driver_found
    if (status == 'driver_found' && driverId != null) {
      Logger.info('Driver found status detected - Driver ID: $driverId', tag: 'RIDE_MODEL');
    }
    
    return Ride(
      id: doc.id,
      passengerId: data['passengerId'] ?? data['userId'] ?? '',  // ✅ MODIFICAT: Suport pentru ambele câmpuri (backward compatibility)
      driverId: data['driverId'],
      startAddress: data['startAddress'] ?? '',
      destinationAddress: data['destinationAddress'] ?? '',
      distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
      startLatitude: (data['startLatitude'] as num?)?.toDouble(),
      startLongitude: (data['startLongitude'] as num?)?.toDouble(),
      destinationLatitude: (data['destinationLatitude'] as num?)?.toDouble(),
      destinationLongitude: (data['destinationLongitude'] as num?)?.toDouble(),
      durationInMinutes: (data['durationInMinutes'] as num?)?.toDouble(),
      baseFare: (data['baseFare'] as num?)?.toDouble() ?? 0.0,
      perKmRate: (data['perKmRate'] as num?)?.toDouble() ?? 0.0,
      perMinRate: (data['perMinRate'] as num?)?.toDouble() ?? 0.0,
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0.0,
      appCommission: (data['appCommission'] as num?)?.toDouble() ?? 0.0,
      driverEarnings: (data['driverEarnings'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: status,
      passengerRating: (data['passengerRating'] as num?)?.toDouble(),
      passengerComment: data['passengerComment'],
      driverRating: (data['driverRating'] as num?)?.toDouble(),
      driverComment: data['driverComment'],
      driverRatingForPassenger: (data['driverRatingForPassenger'] as num?)?.toDouble(),
      driverCharacterizationForPassenger: data['driverCharacterizationForPassenger'],
      tip: (data['tip'] as num?)?.toDouble() ?? 0.0,
      stops: List<Map<String, dynamic>>.from(data['stops'] ?? []),
      wasCancelled: data['wasCancelled'] ?? false,
      cancelledBy: data['cancelledBy'],
      cancellationFee: (data['cancellationFee'] as num?)?.toDouble(),
      declinedBy: List<String>.from(data['declinedBy'] ?? []),
      category: RideCategory.values.firstWhere(
        (e) => e.name == (data['category'] as String? ?? 'standard'),
        orElse: () => RideCategory.standard,
      ),
      searchRadius: (data['searchRadius'] as num?)?.toDouble(),
      searchStartTime: (data['searchStartTime'] as Timestamp?)?.toDate(),
      assignmentMethod: data['assignmentMethod'],
      driverDistance: (data['driverDistance'] as num?)?.toDouble(),
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      ridePreferences: data['ridePreferences'] != null
        ? RidePreferences.fromMap(Map<String, dynamic>.from(data['ridePreferences']))
        : null,
      pickupCode: data['pickupCode'],
      waitStartedAt: (data['waitStartedAt'] as Timestamp?)?.toDate(),
      waitTimeFee: (data['waitTimeFee'] as num?)?.toDouble(),
      routePreviewUrl: data['routePreviewUrl'] as String?,
      allowedDriverUids: data['allowedDriverUids'] != null 
          ? List<String>.from(data['allowedDriverUids']) 
          : null,
    );
  }
}