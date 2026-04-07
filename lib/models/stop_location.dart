// lib/models/stop_location.dart

class StopLocation {
  final String address;
  final double latitude;
  final double longitude;
  final String? notes;

  StopLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    };
  }

  factory StopLocation.fromMap(Map<String, dynamic> map) {
    return StopLocation(
      address: map['address'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
    );
  }

  @override
  String toString() {
    return 'StopLocation(address: $address, lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StopLocation &&
        other.address == address &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return address.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        notes.hashCode;
  }
}