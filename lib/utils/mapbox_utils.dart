// Adaugă aceste helper functions într-un fișier utils/mapbox_utils.dart

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:math' as math;

class MapboxUtils {
  // Convertește din Map la Point
  static Point mapToPoint(Map<String?, Object?> map) {
    final lng = ((map['lng'] ?? map['longitude']) as num).toDouble();
    final lat = ((map['lat'] ?? map['latitude']) as num).toDouble();
    return Point(coordinates: Position(lng, lat));
  }

  // Convertește din Point la Map
  static Map<String, double> pointToMap(Point point) {
    return {
      'lng': point.coordinates.lng.toDouble(),
      'lat': point.coordinates.lat.toDouble(),
    };
  }

  // Creează Point din coordonate
  static Point createPoint(double latitude, double longitude) {
    return Point(coordinates: Position(longitude, latitude));
  }

  // Convertește din Position (lat/lng) la Point
  static Point positionToPoint(double latitude, double longitude) {
    return Point(coordinates: Position(longitude, latitude));
  }

  // Convert to Point for compatibility
  static Point convertToPoint(dynamic input) {
    if (input is Point) return input;
    if (input is Map<String?, Object?>) return mapToPoint(input);
    throw ArgumentError('Cannot convert $input to Point');
  }

  // Context to Point helper
  static Point contextToPoint(MapContentGestureContext context) {
    return Point(coordinates: Position(context.point.coordinates.lng.toDouble(), context.point.coordinates.lat.toDouble()));
  }

  // Calculează distanța între două puncte (în metri)
  static double calculateDistance(Point point1, Point point2) {
    const double earthRadius = 6371000; // metri
    
    final lat1Rad = point1.coordinates.lat.toDouble() * (math.pi / 180);
    final lat2Rad = point2.coordinates.lat.toDouble() * (math.pi / 180);
    final deltaLatRad = (point2.coordinates.lat.toDouble() - point1.coordinates.lat.toDouble()) * (math.pi / 180);
    final deltaLngRad = (point2.coordinates.lng.toDouble() - point1.coordinates.lng.toDouble()) * (math.pi / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * 
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Obține coordonatele din Point
  static double getLng(Point point) => point.coordinates.lng.toDouble();
  static double getLat(Point point) => point.coordinates.lat.toDouble();

  // ✅ NOU: Creează LineString din List<Point>
  static LineString createLineString(List<Point> points) {
    return LineString(coordinates: points.map((p) => p.coordinates).toList());
  }
}