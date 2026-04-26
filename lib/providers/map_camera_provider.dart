import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import '../utils/mapbox_utils.dart';
import 'package:nabour_app/utils/logger.dart';

/// Provider pentru gestionarea controlului camerei hărții
/// Extrage logica de cameră din map_screen.dart
class MapCameraProvider extends ChangeNotifier {
  // Master Camera State (The "Middleware" storage)
  double? _lastLat;
  double? _lastLng;
  double _currentZoom = 14.0;
  double _currentBearing = 0.0;
  double _currentPitch = 0.0;
  bool _isFollowingUser = true;

  // Controllers
  MapboxMap? _mapboxMap;
  fm.MapController? _osmMapController;

  // State
  geo.Position? _currentPosition;
  Timer? _cameraUpdateTimer;

  // Debouncing
  static const Duration _debounceDelay = Duration(milliseconds: 150);

  // Getters
  double? get lastLat => _lastLat;
  double? get lastLng => _lastLng;
  double get currentZoom => _currentZoom;
  double get currentBearing => _currentBearing;
  double get currentPitch => _currentPitch;
  geo.Position? get currentPosition => _currentPosition;
  bool get hasMapInstance => _mapboxMap != null || _osmMapController != null;
  bool get isFollowingUser => _isFollowingUser;

  /// Setează instanța MapboxMap (Middleware Sink)
  void setMapInstance(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _osmMapController = null; // Mapbox is now master
    
    // Dacă avem stare salvată, o aplicăm imediat
    if (_lastLat != null && _lastLng != null) {
      _mapboxMap?.setCamera(CameraOptions(
        center: MapboxUtils.createPoint(_lastLat!, _lastLng!),
        zoom: _currentZoom,
        bearing: _currentBearing,
        pitch: _currentPitch,
      ));
    }
    
    Logger.debug('MapboxMap instance synchronized in Middleware');
    notifyListeners();
  }

  /// Setează instanța OSM (Middleware Sink)
  void setOsmController(fm.MapController controller) {
    _osmMapController = controller;
    _mapboxMap = null; // OSM is now master

    // Dacă avem stare salvată, o aplicăm imediat
    if (_lastLat != null && _lastLng != null) {
      _osmMapController?.move(
        ll.LatLng(_lastLat!, _lastLng!),
        _currentZoom,
      );
    }

    Logger.debug('OSM Controller synchronized in Middleware');
    notifyListeners();
  }

  /// Sincronizează starea de la oricare motor către Middleware
  void syncFromNative({
    required double lat,
    required double lng,
    required double zoom,
    double? bearing,
    double? pitch,
    bool? following,
  }) {
    _lastLat = lat;
    _lastLng = lng;
    _currentZoom = zoom;
    if (bearing != null) _currentBearing = bearing;
    if (pitch != null) _currentPitch = pitch;
    if (following != null) _isFollowingUser = following;
    
    // Nu apelăm notifyListeners() aici pentru a evita bucle de rebuild în timpul scroll-ului,
    // deoarece acest provider este folosit mai mult ca un "store" de tranziție.
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
    if (_currentPosition == null) return;

    if (_mapboxMap != null) {
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
        Logger.error('Error updating Mapbox camera: $e', error: e);
      }
    } else if (_osmMapController != null) {
      _osmMapController!.move(
        ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        _currentZoom,
      );
    }
  }

  /// Centrează camera pe poziția curentă
  Future<void> centerOnCurrentPosition({bool animated = true}) async {
    if (_currentPosition == null) {
      Logger.warning('Cannot center camera - missing position');
      return;
    }

    if (_mapboxMap == null && _osmMapController == null) {
      Logger.warning('Cannot center camera - no map instance');
      return;
    }

    Logger.info('Centering camera on current position');

    try {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      const targetZoom = 15.0;

      if (_mapboxMap != null) {
        final cameraOptions = CameraOptions(
          center: MapboxUtils.createPoint(lat, lng),
          zoom: targetZoom,
        );
        if (animated) {
          await _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1500));
        } else {
          await _mapboxMap!.setCamera(cameraOptions);
        }
      } else if (_osmMapController != null) {
        _osmMapController!.move(ll.LatLng(lat, lng), targetZoom);
      }

      _isFollowingUser = true;
      _currentZoom = targetZoom;
      _lastLat = lat;
      _lastLng = lng;
      notifyListeners();
    } catch (e) {
      Logger.error('Error centering camera: $e', error: e);
    }
  }

  /// Setează zoom level
  Future<void> setZoom(double zoom, {bool animated = true}) async {
    _currentZoom = zoom.clamp(1.0, 22.0);
    
    try {
      if (_mapboxMap != null) {
        final cameraOptions = CameraOptions(zoom: _currentZoom);
        if (animated) {
          await _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 500));
        } else {
          await _mapboxMap!.setCamera(cameraOptions);
        }
      } else if (_osmMapController != null) {
        _osmMapController!.move(_osmMapController!.camera.center, _currentZoom);
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
    Logger.debug('Navigating to: $latitude, $longitude');

    try {
      final targetZoom = zoom ?? _currentZoom;
      
      if (_mapboxMap != null) {
        final cameraOptions = CameraOptions(
          center: MapboxUtils.createPoint(latitude, longitude),
          zoom: targetZoom,
        );
        if (animated) {
          await _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 2000));
        } else {
          await _mapboxMap!.setCamera(cameraOptions);
        }
      } else if (_osmMapController != null) {
        _osmMapController!.move(ll.LatLng(latitude, longitude), targetZoom);
      }

      _isFollowingUser = false;
      _currentZoom = targetZoom;
      _lastLat = latitude;
      _lastLng = longitude;
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
