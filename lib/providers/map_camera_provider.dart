import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../utils/mapbox_utils.dart';
import 'package:nabour_app/utils/logger.dart';

/// Provider pentru gestionarea controlului camerei hărții
/// Extrage logica de cameră din map_screen.dart
class MapCameraProvider extends ChangeNotifier {
  MapboxMap? _mapboxMap;
  geo.Position? _currentPosition;
  Timer? _cameraUpdateTimer;
  
  // Camera state
  bool _isFollowingUser = true;
  double _currentZoom = 14.0;
  double _currentBearing = 0.0;
  double _currentPitch = 0.0;
  
  // Debouncing
  static const Duration _debounceDelay = Duration(milliseconds: 200);

  // Getters
  bool get isFollowingUser => _isFollowingUser;
  double get currentZoom => _currentZoom;
  double get currentBearing => _currentBearing;
  double get currentPitch => _currentPitch;
  geo.Position? get currentPosition => _currentPosition;
  bool get hasMapInstance => _mapboxMap != null;

  /// Setează instanța MapboxMap
  void setMapInstance(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    Logger.debug('MapboxMap instance set in MapCameraProvider');
    notifyListeners();
  }

  /// Actualizează poziția curentă
  void updateCurrentPosition(geo.Position position) {
    _currentPosition = position;
    
    if (_isFollowingUser) {
      _scheduleCameraUpdate();
    }
    
    notifyListeners();
  }

  /// Schedulează actualizarea camerei cu debouncing
  void _scheduleCameraUpdate() {
    _cameraUpdateTimer?.cancel();
    _cameraUpdateTimer = Timer(_debounceDelay, () {
      if (_currentPosition != null && _mapboxMap != null) {
        _updateCameraToCurrentPosition();
      }
    });
  }

  /// Actualizează camera la poziția curentă
  Future<void> _updateCameraToCurrentPosition() async {
    if (_currentPosition == null || _mapboxMap == null) return;

    try {
      await _mapboxMap!.flyTo(
        CameraOptions(
                  center: MapboxUtils.createPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
          zoom: _currentZoom,
          bearing: _currentBearing,
          pitch: _currentPitch,
        ),
        MapAnimationOptions(duration: 1000),
      );
    } catch (e) {
      Logger.error('Error updating camera: $e', error: e);
    }
  }

  /// Centrează camera pe poziția curentă
  Future<void> centerOnCurrentPosition({bool animated = true}) async {
    if (_currentPosition == null || _mapboxMap == null) {
      Logger.warning('Cannot center camera - missing position or map instance');
      return;
    }

    Logger.info('Centering camera on current position');

    try {
      final cameraOptions = CameraOptions(
        center: MapboxUtils.createPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        zoom: 15.0,
      );

      if (animated) {
        await _mapboxMap!.flyTo(
          cameraOptions,
          MapAnimationOptions(duration: 1500),
        );
      } else {
        await _mapboxMap!.setCamera(cameraOptions);
      }

      _isFollowingUser = true;
      _currentZoom = 15.0;
      notifyListeners();
    } catch (e) {
      Logger.error('Error centering camera: $e', error: e);
    }
  }

  /// Setează zoom level
  Future<void> setZoom(double zoom, {bool animated = true}) async {
    if (_mapboxMap == null) return;

    _currentZoom = zoom.clamp(1.0, 22.0);
    
    try {
      final cameraOptions = CameraOptions(zoom: _currentZoom);
      
      if (animated) {
        await _mapboxMap!.flyTo(
          cameraOptions,
          MapAnimationOptions(duration: 500),
        );
      } else {
        await _mapboxMap!.setCamera(cameraOptions);
      }
      
      notifyListeners();
    } catch (e) {
      Logger.error('Error setting zoom: $e', error: e);
    }
  }

  /// Setează bearing (rotația hărții)
  Future<void> setBearing(double bearing, {bool animated = true}) async {
    if (_mapboxMap == null) return;

    _currentBearing = bearing % 360;
    
    try {
      final cameraOptions = CameraOptions(bearing: _currentBearing);
      
      if (animated) {
        await _mapboxMap!.flyTo(
          cameraOptions,
          MapAnimationOptions(duration: 500),
        );
      } else {
        await _mapboxMap!.setCamera(cameraOptions);
      }
      
      notifyListeners();
    } catch (e) {
      Logger.error('Error setting bearing: $e', error: e);
    }
  }

  /// Setează pitch (înclinarea hărții)
  Future<void> setPitch(double pitch, {bool animated = true}) async {
    if (_mapboxMap == null) return;

    _currentPitch = pitch.clamp(0.0, 60.0);
    
    try {
      final cameraOptions = CameraOptions(pitch: _currentPitch);
      
      if (animated) {
        await _mapboxMap!.flyTo(
          cameraOptions,
          MapAnimationOptions(duration: 500),
        );
      } else {
        await _mapboxMap!.setCamera(cameraOptions);
      }
      
      notifyListeners();
    } catch (e) {
      Logger.error('Error setting pitch: $e', error: e);
    }
  }

  /// Oprește urmărirea automată a utilizatorului
  void stopFollowingUser() {
    _isFollowingUser = false;
    Logger.debug('Stopped following user');
    notifyListeners();
  }

  /// Pornește urmărirea automată a utilizatorului
  void startFollowingUser() {
    _isFollowingUser = true;
    Logger.info('Started following user');
    
    if (_currentPosition != null) {
      _scheduleCameraUpdate();
    }
    
    notifyListeners();
  }

  /// Navighează la o locație specifică
  Future<void> navigateToLocation(
    double latitude,
    double longitude, {
    double? zoom,
    bool animated = true,
  }) async {
    if (_mapboxMap == null) return;

    Logger.debug('Navigating to: $latitude, $longitude');

    try {
      final cameraOptions = CameraOptions(
        center: MapboxUtils.createPoint(latitude, longitude),
        zoom: zoom ?? _currentZoom,
      );

      if (animated) {
        await _mapboxMap!.flyTo(
          cameraOptions,
          MapAnimationOptions(duration: 2000),
        );
      } else {
        await _mapboxMap!.setCamera(cameraOptions);
      }

      _isFollowingUser = false;
      if (zoom != null) _currentZoom = zoom;
      notifyListeners();
    } catch (e) {
      Logger.error('Error navigating to location: $e', error: e);
    }
  }

  /// Fit camera pentru a afișa toate punctele date
  Future<void> fitPoints(
    List<Point> points, {
    EdgeInsets padding = const EdgeInsets.all(50),
    bool animated = true,
  }) async {
    if (_mapboxMap == null || points.isEmpty) return;

    try {
      final coordinateBounds = CoordinateBounds(
        southwest: MapboxUtils.createPoint(
          points.map((p) => p.coordinates.lat).reduce((a, b) => a < b ? a : b).toDouble(),
          points.map((p) => p.coordinates.lng).reduce((a, b) => a < b ? a : b).toDouble(),
        ),
        northeast: MapboxUtils.createPoint(
          points.map((p) => p.coordinates.lat).reduce((a, b) => a > b ? a : b).toDouble(),
          points.map((p) => p.coordinates.lng).reduce((a, b) => a > b ? a : b).toDouble(),
        ),
        infiniteBounds: false,
      );

      final cameraOptions = await _mapboxMap!.cameraForCoordinateBounds(
        coordinateBounds,
        MbxEdgeInsets(
          top: padding.top,
          left: padding.left,
          bottom: padding.bottom,
          right: padding.right,
        ),
        null,
        null,
        null,
        null,
      );

      if (animated) {
        await _mapboxMap!.flyTo(
          cameraOptions,
          MapAnimationOptions(duration: 1500),
        );
      } else {
        await _mapboxMap!.setCamera(cameraOptions);
      }

      _isFollowingUser = false;
      notifyListeners();
    } catch (e) {
      Logger.error('Error fitting points: $e', error: e);
    }
  }

  /// Reset camera la starea inițială
  Future<void> resetCamera() async {
    _currentZoom = 14.0;
    _currentBearing = 0.0;
    _currentPitch = 0.0;
    _isFollowingUser = true;
    
    if (_currentPosition != null) {
      await centerOnCurrentPosition();
    }
    
    notifyListeners();
  }

  /// Cleanup la dispose
  @override
  void dispose() {
    Logger.debug('Disposing MapCameraProvider');
    _cameraUpdateTimer?.cancel();
    super.dispose();
  }
}
