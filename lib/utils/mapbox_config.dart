import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nabour_app/config/environment.dart';

/// Configuration file for Mapbox services.
/// This file contains all Mapbox-related configuration including access tokens
/// and API endpoints.
class MapboxConfig {
  // IMPLEMENTARE SECURIZATĂ - Token din environment variables
  static String? _accessToken;
  
  // Mapbox API Base URLs
  static const String directionsApiUrl = 'https://api.mapbox.com/directions/v5';
  static const String geocodingApiUrl = 'https://api.mapbox.com/geocoding/v5';
  static const String placesApiUrl = 'https://api.mapbox.com/geocoding/v5';
  
  // IMPLEMENTARE SECURIZATĂ - Inițializare token
  static Future<void> initialize() async {
    // Lazy-loaded now via getAccessToken(); kept for backward compatibility
    _ensureToken();
  }
  
  // Mapbox Style URLs
  static const String lightStyleUrl = 'mapbox://styles/mapbox/light-v11';
  static const String darkStyleUrl = 'mapbox://styles/mapbox/dark-v11';
  static const String streetsStyleUrl = 'mapbox://styles/mapbox/streets-v12';
  static const String satelliteStyleUrl = 'mapbox://styles/mapbox/satellite-v9';
  
  // Default Map Settings
  static const double defaultZoom = 15.0;
  static const double minZoom = 10.0;
  static const double maxZoom = 20.0;
  
  // Routing Settings
  static const String defaultProfile = 'driving'; // driving, walking, cycling
  static const List<String> availableProfiles = ['driving', 'walking', 'cycling'];
  
  // POI Search Settings
  static const int maxPoiResults = 20;
  static const double defaultSearchRadius = 5000.0; // meters
  
  // Map Performance Settings
  static const bool enable3DBuildings = true;
  static const bool enableTraffic = true;
  static const bool enableIndoor = false;
  
  /// Returns the access token for Mapbox services
  static String getAccessToken() {
    _ensureToken();
    return _accessToken!;
  }

  static void _ensureToken() {
    if (_accessToken == null || _accessToken!.isEmpty) {
      // 1) Prefer .env (runtime) – suportă MAPBOX_ACCESS_TOKEN sau MAPBOX_PUBLIC_TOKEN
      if (dotenv.isInitialized) {
        final fromEnv = dotenv.maybeGet('MAPBOX_PUBLIC_TOKEN') ?? dotenv.maybeGet('MAPBOX_ACCESS_TOKEN');
        if (fromEnv != null && fromEnv.isNotEmpty && fromEnv.startsWith('pk.')) {
          _accessToken = fromEnv;
          return;
        }
      }
      // 2) Fallback: dart-define / Environment (compile-time)
      final token = Environment.mapboxPublicToken;
      if (token.isEmpty || !token.startsWith('pk.')) {
        throw Exception(
          'Mapbox token missing or invalid. Add MAPBOX_ACCESS_TOKEN or MAPBOX_PUBLIC_TOKEN in .env, '
          'or use --dart-define=MAPBOX_PUBLIC_TOKEN=pk.xxx'
        );
      }
      _accessToken = token;
    }
  }
  
  /// Quick setup helper - shows configuration status
  static void showConfigurationStatus() {
    // Keep quiet in release; only minimal logging in debug
    if (kDebugMode) {
      // ignore: avoid_print
      print('🗺️ Mapbox token configured: ${isValid()}');
    }
  }
  
  /// Returns the base URL for Mapbox Directions API
  static String getDirectionsApiUrl() => '$directionsApiUrl/${getAccessToken()}';
  
  /// Returns the base URL for Mapbox Geocoding API
  static String getGeocodingApiUrl() => '$geocodingApiUrl/${getAccessToken()}';
  
  /// Returns the base URL for Mapbox Places API
  static String getPlacesApiUrl() => '$placesApiUrl/${getAccessToken()}';
  
  /// Returns the appropriate style URL based on theme
  static String getStyleUrl({bool isDark = false}) {
    return isDark ? darkStyleUrl : lightStyleUrl;
  }
  
  /// Validates if the configuration is properly set up
  static bool isValid() {
    try {
      getAccessToken();
      return true;
    } catch (e) {
      return false;
    }
  }
}
