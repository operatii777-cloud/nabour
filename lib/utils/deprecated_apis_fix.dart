// utils/deprecated_apis_fix.dart
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

/// Utility class pentru a gestiona API-urile deprecate
class DeprecatedAPIsFix {
  
  /// Înlocuiește Geolocator.getCurrentPosition cu parametri deprecated
  static Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.best,
    Duration? timeLimit,
  }) async {
    try {
      final future = Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
      
      if (timeLimit != null) {
        return await future.timeout(timeLimit);
      }
      
      return await future;
    } catch (e) {
      rethrow;
    }
  }

  /// Înlocuiește Geolocator.getLastKnownPosition cu LocationSettings
  static Future<Position?> getLastKnownPosition({
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      rethrow;
    }
  }

  /// Înlocuiește Share.share deprecated - API modern SharePlus v11.1.0
  static Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  /// Înlocuiește Share.shareFiles deprecated  
  static Future<void> shareFiles(
    List<String> paths, {
    String? text,
    String? subject,
  }) async {
    final files = paths.map((path) => XFile(path)).toList();
    await SharePlus.instance.share(ShareParams(
      files: files,
      text: text,
      subject: subject,
    ));
  }

  /// Create LocationSettings helper
  static LocationSettings createLocationSettings({
    LocationAccuracy accuracy = LocationAccuracy.best,
    Duration? timeLimit,
    int? distanceFilter,
  }) {
    return LocationSettings(
      accuracy: accuracy,
      timeLimit: timeLimit,
      distanceFilter: distanceFilter ?? 0,
    );
  }
}

/// Extension pentru Position pentru compatibilitate
extension PositionExtension on Position {
  /// Convertește Position la Map pentru compatibilitate
  Map<String, double> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}