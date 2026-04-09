import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Map style URIs shared by map UI and OfflineManager tile/style prefetch.
class NabourMapStyles {
  NabourMapStyles._();

  static const String streets = MapboxStyles.MAPBOX_STREETS;
  static const String dark = MapboxStyles.DARK;
  static const String light = MapboxStyles.LIGHT;

  static String uriForMainMap({
    required bool lowDataMode,
    required bool darkMode,
  }) {
    if (lowDataMode) return light;
    return darkMode ? dark : streets;
  }
}