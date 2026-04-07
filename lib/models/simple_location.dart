import 'dart:math' as math;

/// Simple location model to replace Mapbox Point
class SimpleLocation {
  final double latitude;
  final double longitude;

  const SimpleLocation({
    required this.latitude,
    required this.longitude,
  });

  /// Create from lat/lng
  factory SimpleLocation.fromLatLng(double lat, double lng) {
    return SimpleLocation(latitude: lat, longitude: lng);
  }

  /// Create from coordinates map
  factory SimpleLocation.fromMap(Map<String, dynamic> map) {
    return SimpleLocation(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Calculate distance to another location
  double distanceTo(SimpleLocation other) {
    const double earthRadius = 6371000; // meters
    final lat1 = latitude * math.pi / 180;
    final lat2 = other.latitude * math.pi / 180;
    final deltaLat = (other.latitude - latitude) * math.pi / 180;
    final deltaLng = (other.longitude - longitude) * math.pi / 180;

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final c = 2 * math.atan(math.sqrt(a) / math.sqrt(1 - a));

    return earthRadius * c;
  }

  @override
  String toString() {
    return 'SimpleLocation(lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimpleLocation &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}
