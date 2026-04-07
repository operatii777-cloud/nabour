import 'dart:math' as math;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart' as geolocator;

/// Advanced coordinate compatibility layer for AI system integration
/// Resolves conflicts between Point objects and Map types
class CoordinateHelpers {
  
  // ===== EXISTING FUNCTIONS (KEPT FOR BACKWARD COMPATIBILITY) =====
  
  /// Convert Point to Map format expected by some Mapbox APIs
  static Map<String?, Object?> pointToMap(Point point) {
    return {
      'coordinates': [point.coordinates.lng.toDouble(), point.coordinates.lat.toDouble()]
    };
  }
  
  /// Convert Map to Point format
  static Point mapToPoint(Map<String?, Object?> map) {
    if (map['coordinates'] is List) {
      final coords = map['coordinates'] as List;
      if (coords.length >= 2) {
        return Point(
          coordinates: Position(
            coords[0] as double, // longitude
            coords[1] as double, // latitude
          ),
        );
      }
    }
    
    // Fallback - try to extract lat/lng directly
    if (map['lng'] != null && map['lat'] != null) {
      return Point(
        coordinates: Position(
          map['lng'] as double,
          map['lat'] as double,
        ),
      );
    }
    
    // Default fallback to origin
    return Point(coordinates: Position(0.0, 0.0));
  }
  
  /// Create Point from latitude and longitude
  static Point createPoint(double latitude, double longitude) {
    return Point(
      coordinates: Position(longitude, latitude),
    );
  }
  
  /// Extract coordinates as [lng, lat] array from Point
  static List<double> pointToCoordinatesArray(Point point) {
    return [point.coordinates.lng.toDouble(), point.coordinates.lat.toDouble()];
  }
  
  /// Create Map with GeoJSON-style coordinates
  static Map<String, dynamic> pointToGeoJsonCoordinates(Point point) {
    return {
      'type': 'Point',
      'coordinates': [point.coordinates.lng, point.coordinates.lat]
    };
  }
  
  /// Convert GeoJSON coordinates to Point
  static Point geoJsonCoordinatesToPoint(Map<String, dynamic> geoJson) {
    if (geoJson['coordinates'] is List) {
      final coords = geoJson['coordinates'] as List;
      if (coords.length >= 2) {
        return Point(
          coordinates: Position(
            coords[0] as double, // longitude
            coords[1] as double, // latitude
          ),
        );
      }
    }
    return Point(coordinates: Position(0.0, 0.0));
  }
  
  /// Check if object is a valid Point
  static bool isValidPoint(dynamic obj) {
    return obj is Point && 
           obj.coordinates.lat.isFinite && 
           obj.coordinates.lng.isFinite;
  }
  
  /// Check if object is a valid coordinate map
  static bool isValidCoordinateMap(dynamic obj) {
    if (obj is! Map) return false;
    
    final map = obj;
    if (map['coordinates'] is List) {
      final coords = map['coordinates'] as List;
      return coords.length >= 2 && 
             coords[0] is num && 
             coords[1] is num;
    }
    
    return map['lng'] is num && map['lat'] is num;
  }

  // ===== NEW AI COMPATIBILITY FUNCTIONS =====
  
  /// AI System: Convert Point to CameraOptions.center format
  /// Used by AI services that need to set map camera position
  static Map<String?, Object?> pointToCameraCenter(Point point) {
    return {
      'center': {
        'lng': point.coordinates.lng.toDouble(),
        'lat': point.coordinates.lat.toDouble(),
      }
    };
  }
  
  /// AI System: Convert Point to PointAnnotationOptions.geometry format
  /// Used by AI services that need to place markers on map
  static Map<String?, Object?> pointToAnnotationGeometry(Point point) {
    return {
      'type': 'Point',
      'coordinates': [point.coordinates.lng.toDouble(), point.coordinates.lat.toDouble()]
    };
  }
  
  /// AI System: Convert Point to CircleAnnotationOptions.center format
  /// Used by AI services that need to draw circles on map
  static Map<String?, Object?> pointToCircleCenter(Point point) {
    return {
      'center': {
        'lng': point.coordinates.lng.toDouble(),
        'lat': point.coordinates.lat.toDouble(),
      }
    };
  }
  
  /// AI System: Convert Point to PolylineAnnotationOptions.geometry format
  /// Used by AI services that need to draw routes on map
  static Map<String?, Object?> pointsToPolylineGeometry(List<Point> points) {
    final coordinates = points.map((point) => [
      point.coordinates.lng.toDouble(),
      point.coordinates.lat.toDouble()
    ]).toList();
    
    return {
      'type': 'LineString',
      'coordinates': coordinates
    };
  }
  
  /// AI System: Convert Point to CameraBounds format
  /// Used by AI services that need to fit multiple points in view
  static Map<String?, Object?> pointsToCameraBounds(List<Point> points) {
    if (points.isEmpty) {
      return {
        'center': {'lng': 0.0, 'lat': 0.0},
        'zoom': 10.0
      };
    }
    
    double minLat = points.first.coordinates.lat.toDouble();
    double maxLat = points.first.coordinates.lat.toDouble();
    double minLng = points.first.coordinates.lng.toDouble();
    double maxLng = points.first.coordinates.lng.toDouble();
    
    for (final point in points) {
      final lat = point.coordinates.lat.toDouble();
      final lng = point.coordinates.lng.toDouble();
      
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }
    
    return {
      'bounds': {
        'northeast': {'lng': maxLng, 'lat': maxLat},
        'southwest': {'lng': minLng, 'lat': minLat}
      }
    };
  }
  
  // ===== FIREBASE/FIRESTORE COMPATIBILITY =====
  
  /// AI System: Convert Point to Firestore GeoPoint
  /// Used by AI services that need to save coordinates to database
  static GeoPoint pointToGeoPoint(Point point) {
    return GeoPoint(
      point.coordinates.lat.toDouble(),
      point.coordinates.lng.toDouble(),
    );
  }
  
  /// AI System: Convert Firestore GeoPoint to Point
  /// Used by AI services that need to read coordinates from database
  static Point geoPointToPoint(GeoPoint geoPoint) {
    return Point(
      coordinates: Position(
        geoPoint.longitude,
        geoPoint.latitude,
      ),
    );
  }
  
  /// AI System: Convert Point to Firestore document data
  /// Used by AI services that need to save location data
  static Map<String, dynamic> pointToFirestoreData(Point point, {String? label}) {
    return {
      if (label != null) 'label': label,
      'coordinates': pointToGeoPoint(point),
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
  
  // ===== GEOLOCATOR COMPATIBILITY =====
  
  /// AI System: Convert Point to Geolocator Position
  /// Used by AI services that need to work with device location
  static geolocator.Position pointToGeolocatorPosition(Point point) {
    return geolocator.Position(
      latitude: point.coordinates.lat.toDouble(),
      longitude: point.coordinates.lng.toDouble(),
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }
  
  /// AI System: Convert Geolocator Position to Point
  /// Used by AI services that need to work with device location
  static Point geolocatorPositionToPoint(geolocator.Position position) {
    return Point(
      coordinates: Position(
        position.longitude,
        position.latitude,
      ),
    );
  }
  
  // ===== AI SYSTEM UTILITY FUNCTIONS =====
  
  /// AI System: Calculate distance between two points
  /// Used by AI services for proximity calculations
  static double calculateDistance(Point point1, Point point2) {
    const double earthRadius = 6371000; // meters
    
    final lat1 = point1.coordinates.lat.toDouble() * (math.pi / 180);
    final lat2 = point2.coordinates.lat.toDouble() * (math.pi / 180);
    final deltaLat = (point2.coordinates.lat.toDouble() - point1.coordinates.lat.toDouble()) * (math.pi / 180);
    final deltaLng = (point2.coordinates.lng.toDouble() - point1.coordinates.lng.toDouble()) * (math.pi / 180);
    
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
               math.cos(lat1) * math.cos(lat2) * math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// AI System: Check if point is within radius of another point
  /// Used by AI services for proximity-based suggestions
  static bool isWithinRadius(Point center, Point point, double radiusMeters) {
    return calculateDistance(center, point) <= radiusMeters;
  }
  
  /// AI System: Get midpoint between two points
  /// Used by AI services for route optimization
  static Point getMidpoint(Point point1, Point point2) {
    final midLat = (point1.coordinates.lat.toDouble() + point2.coordinates.lat.toDouble()) / 2;
    final midLng = (point1.coordinates.lng.toDouble() + point2.coordinates.lng.toDouble()) / 2;
    
    return Point(
      coordinates: Position(midLng, midLat),
    );
  }
  
  /// AI System: Validate coordinate bounds
  /// Used by AI services to ensure coordinates are valid
  static bool isValidCoordinateBounds(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
  
  /// AI System: Create Point with validation
  /// Used by AI services to ensure data integrity
  static Point? createValidPoint(double latitude, double longitude) {
    if (isValidCoordinateBounds(latitude, longitude)) {
      return Point(
        coordinates: Position(longitude, latitude),
      );
    }
    return null;
  }
  
  /// AI System: Convert multiple Points to coordinate array
  /// Used by AI services for batch coordinate processing
  static List<List<double>> pointsToCoordinateArrays(List<Point> points) {
    return points.map((point) => [
      point.coordinates.lng.toDouble(),
      point.coordinates.lat.toDouble()
    ]).toList();
  }
  
  /// AI System: Convert coordinate arrays to Points
  /// Used by AI services for batch coordinate processing
  static List<Point> coordinateArraysToPoints(List<List<double>> coordinates) {
    return coordinates.map((coord) => Point(
      coordinates: Position(coord[0], coord[1]),
    )).toList();
  }
  
  // ===== MAPBOX API COMPATIBILITY =====
  
  /// AI System: Convert Point to Mapbox API coordinate string
  /// Used by AI services that call Mapbox APIs
  static String pointToMapboxCoordinateString(Point point) {
    return '${point.coordinates.lng.toDouble()},${point.coordinates.lat.toDouble()}';
  }
  
  /// AI System: Convert multiple Points to Mapbox waypoints string
  /// Used by AI services that call Mapbox Directions API
  static String pointsToMapboxWaypoints(List<Point> points) {
    return points.map((point) => pointToMapboxCoordinateString(point)).join(';');
  }
  
  /// AI System: Parse Mapbox API response to Points
  /// Used by AI services that process Mapbox API responses
  static List<Point> parseMapboxCoordinates(Map<String, dynamic> response) {
    try {
      final routes = response['routes'] as List?;
      if (routes == null || routes.isEmpty) return [];
      
      final geometry = routes[0]['geometry'];
      final coordinates = geometry['coordinates'] as List?;
      if (coordinates == null) return [];
      
      return coordinates.map((coord) => Point(
        coordinates: Position(
          coord[0] as double,
          coord[1] as double,
        ),
      )).toList();
    } catch (e) {
      return [];
    }
  }
}
