import 'package:cloud_firestore/cloud_firestore.dart';

/// Driver model for UI optimization compatibility
class Driver {
  final String id;
  final String name;
  final String profileImageUrl;
  final String carModel;
  final String carColor;
  final String licensePlate;
  final double rating;
  final int completedRides;
  final DateTime estimatedArrival;
  final GeoPoint currentPosition;
  
  Driver({
    required this.id,
    required this.name,
    required this.profileImageUrl,
    required this.carModel,
    required this.carColor,
    required this.licensePlate,
    required this.rating,
    required this.completedRides,
    required this.estimatedArrival,
    required this.currentPosition,
  });
  
  /// UI OPTIMIZATION: Create copy with updated values
  Driver copyWith({
    String? id,
    String? name,
    String? profileImageUrl,
    String? carModel,
    String? carColor,
    String? licensePlate,
    double? rating,
    int? completedRides,
    DateTime? estimatedArrival,
    GeoPoint? currentPosition,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      carModel: carModel ?? this.carModel,
      carColor: carColor ?? this.carColor,
      licensePlate: licensePlate ?? this.licensePlate,
      rating: rating ?? this.rating,
      completedRides: completedRides ?? this.completedRides,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }
  
  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'carModel': carModel,
      'carColor': carColor,
      'licensePlate': licensePlate,
      'rating': rating,
      'completedRides': completedRides,
      'estimatedArrival': estimatedArrival.toIso8601String(),
      'currentPosition': {
        'latitude': currentPosition.latitude,
        'longitude': currentPosition.longitude,
      },
    };
  }
  
  /// Create from map for deserialization
  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      carModel: map['carModel'] ?? '',
      carColor: map['carColor'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      completedRides: map['completedRides'] ?? 0,
      estimatedArrival: DateTime.tryParse(map['estimatedArrival'] ?? '') ?? DateTime.now(),
      currentPosition: GeoPoint(
        map['currentPosition']?['latitude'] ?? 0.0,
        map['currentPosition']?['longitude'] ?? 0.0,
      ),
    );
  }
}
