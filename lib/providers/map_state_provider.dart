import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;

/// Placeholder for map state extraction.
/// Full state migration from _MapScreenState is planned incrementally.
class MapStateProvider extends ChangeNotifier {
  MapboxMap? _mapboxMap;
  geolocator.Position? _currentPosition;
  bool _isMapReady = false;
  String _scaleBarText = '';

  MapboxMap? get mapboxMap => _mapboxMap;
  geolocator.Position? get currentPosition => _currentPosition;
  bool get isMapReady => _isMapReady;
  String get scaleBarText => _scaleBarText;

  void setMapboxMap(MapboxMap? map) {
    _mapboxMap = map;
    notifyListeners();
  }

  void setCurrentPosition(geolocator.Position? position) {
    _currentPosition = position;
    notifyListeners();
  }

  void setMapReady(bool ready) {
    _isMapReady = ready;
    notifyListeners();
  }

  void setScaleBarText(String text) {
    _scaleBarText = text;
    notifyListeners();
  }
}
