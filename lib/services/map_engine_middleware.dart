import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:nabour_app/providers/map_settings_provider.dart';
import 'package:nabour_app/utils/logger.dart';

/// Camera state that is engine-agnostic.
class MapCameraState {
  final double latitude;
  final double longitude;
  final double zoom;
  final double bearing;
  final double pitch;

  const MapCameraState({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    this.bearing = 0,
    this.pitch = 0,
  });

  static const MapCameraState defaultState = MapCameraState(
    latitude: 44.4268,
    longitude: 26.1025,
    zoom: 13,
  );

  @override
  String toString() =>
      'MapCameraState(lat=$latitude, lng=$longitude, zoom=$zoom, bearing=$bearing, pitch=$pitch)';
}

/// Which map-only features are available for the current engine.
class MapFeatureAvailability {
  final bool annotations;
  final bool layer3dBuildings;
  final bool trafficLayer;
  final bool mysteryBox;
  final bool radarAlerts;
  final bool neighborhoodRequests;
  final bool customStyles;
  final bool spaceIntroAnimation;

  const MapFeatureAvailability({
    required this.annotations,
    required this.layer3dBuildings,
    required this.trafficLayer,
    required this.mysteryBox,
    required this.radarAlerts,
    required this.neighborhoodRequests,
    required this.customStyles,
    required this.spaceIntroAnimation,
  });

  static const MapFeatureAvailability mapbox = MapFeatureAvailability(
    annotations: true,
    layer3dBuildings: true,
    trafficLayer: true,
    mysteryBox: true,
    radarAlerts: true,
    neighborhoodRequests: true,
    customStyles: true,
    spaceIntroAnimation: true,
  );

  static const MapFeatureAvailability osm = MapFeatureAvailability(
    annotations: false,
    layer3dBuildings: false,
    trafficLayer: false,
    mysteryBox: false,
    radarAlerts: false,
    neighborhoodRequests: false,
    customStyles: false,
    spaceIntroAnimation: false,
  );
}

/// Middleware that sits between the app logic and the active map engine.
///
/// Responsibilities:
/// - Preserves camera state across engine switches
/// - Exposes a unified flyTo / getCamera API regardless of active engine
/// - Tracks feature availability per engine
/// - Manages transition overlay visibility so UI can show a brief loading state
class MapEngineMiddleware extends ChangeNotifier {
  MapEngineMiddleware(this._settings) {
    _settings.addListener(_onProviderChanging);
  }

  final MapSettingsProvider _settings;

  mb.MapboxMap? _mapboxMap;
  fm.MapController? _osmController;

  MapCameraState _lastCamera = MapCameraState.defaultState;
  MapCameraState? _pendingRestore;

  bool _isTransitioning = false;

  // ── Public getters ──────────────────────────────────────────────────────────

  bool get isTransitioning => _isTransitioning;

  MapCameraState get lastKnownCamera => _lastCamera;

  MapFeatureAvailability get features =>
      _settings.isMapbox ? MapFeatureAvailability.mapbox : MapFeatureAvailability.osm;

  MapProviderType get activeProvider => _settings.selectedProvider;

  // ── Engine registration ─────────────────────────────────────────────────────

  /// Called from _onMapCreated (MapBox). Restores pending camera if a switch just happened.
  void registerMapbox(mb.MapboxMap map) {
    _mapboxMap = map;
    _osmController = null;
    _applyPendingRestore();
  }

  /// Called from _onOsmMapCreated. Restores pending camera if a switch just happened.
  void registerOsm(fm.MapController ctrl) {
    _osmController = ctrl;
    _mapboxMap = null;
    _applyPendingRestore();
  }

  /// Called when the active engine is being torn down (widget dispose / engine switch).
  void unregisterAll() {
    _mapboxMap = null;
    _osmController = null;
  }

  // ── Unified camera API ──────────────────────────────────────────────────────

  /// Move the active engine's camera to [lat]/[lng] at [zoom].
  /// Works on both MapBox and OSM — callers don't need to branch.
  Future<void> flyTo(
    double lat,
    double lng,
    double zoom, {
    int durationMs = 1200,
    double bearing = 0,
    double pitch = 0,
  }) async {
    _lastCamera = MapCameraState(
      latitude: lat,
      longitude: lng,
      zoom: zoom,
      bearing: bearing,
      pitch: pitch,
    );

    if (_settings.isMapbox && _mapboxMap != null) {
      await _mapboxMap!.flyTo(
        mb.CameraOptions(
          center: mb.Point(coordinates: mb.Position(lng, lat)),
          zoom: zoom,
          bearing: bearing,
          pitch: pitch,
        ),
        mb.MapAnimationOptions(duration: durationMs),
      );
    } else if (_settings.isOsm && _osmController != null) {
      _animatedMoveOsm(ll.LatLng(lat, lng), zoom, durationMs: durationMs);
    }
  }

  /// Returns a snapshot of the current camera position from whichever engine is active.
  Future<MapCameraState> captureCamera() async {
    if (_settings.isMapbox && _mapboxMap != null) {
      try {
        final cam = await _mapboxMap!.getCameraState();
        final center = cam.center;
        _lastCamera = MapCameraState(
          latitude: center.coordinates.lat.toDouble(),
          longitude: center.coordinates.lng.toDouble(),
          zoom: cam.zoom,
          bearing: cam.bearing,
          pitch: cam.pitch,
        );
      } catch (e) {
        Logger.warning('MapEngineMiddleware: captureCamera (mapbox) failed: $e');
      }
    } else if (_settings.isOsm && _osmController != null) {
      final cam = _osmController!.camera;
      _lastCamera = MapCameraState(
        latitude: cam.center.latitude,
        longitude: cam.center.longitude,
        zoom: cam.zoom,
      );
    }
    return _lastCamera;
  }

  /// Convenience: move camera to user's last known GPS position (stored externally).
  Future<void> flyToPosition(
    double lat,
    double lng, {
    double zoom = 15,
    int durationMs = 1200,
  }) =>
      flyTo(lat, lng, zoom, durationMs: durationMs);

  // ── Transition handling ─────────────────────────────────────────────────────

  /// Fired by [MapSettingsProvider] listener before the engine widget rebuilds.
  void _onProviderChanging() {
    // Capture current camera synchronously (best-effort — OSM gives sync access).
    // For MapBox we rely on the last cached value already updated via [captureCamera].
    if (_settings.isOsm && _osmController != null) {
      // We just switched TO osm → the previous engine was mapbox → _lastCamera is already set.
    }
    if (_settings.isMapbox && _mapboxMap == null) {
      // We just switched TO mapbox → previous engine was OSM.
      if (_osmController != null) {
        final cam = _osmController!.camera;
        _lastCamera = MapCameraState(
          latitude: cam.center.latitude,
          longitude: cam.center.longitude,
          zoom: cam.zoom,
        );
      }
    }

    _pendingRestore = _lastCamera;
    _isTransitioning = true;
    notifyListeners();
    Logger.info('MapEngineMiddleware: engine switching → saved camera $_lastCamera', tag: 'MAP');
  }

  void _applyPendingRestore() {
    final restore = _pendingRestore;
    if (restore == null) return;
    _pendingRestore = null;

    // Give the engine one frame to finish initialising before we move.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await flyTo(
        restore.latitude,
        restore.longitude,
        restore.zoom,
        bearing: restore.bearing,
        pitch: restore.pitch,
        durationMs: 600,
      );
      _isTransitioning = false;
      notifyListeners();
      Logger.info('MapEngineMiddleware: camera restored after engine switch', tag: 'MAP');
    });
  }

  // ── OSM animated move (mirrors map_osm_part but engine-agnostic) ────────────

  void _animatedMoveOsm(ll.LatLng dest, double destZoom, {int durationMs = 1200}) {
    final ctrl = _osmController;
    if (ctrl == null) return;

    final latTween = Tween<double>(begin: ctrl.camera.center.latitude, end: dest.latitude);
    final lngTween = Tween<double>(begin: ctrl.camera.center.longitude, end: dest.longitude);
    final zoomTween = Tween<double>(begin: ctrl.camera.zoom, end: destZoom);

    final ticker = _SingleTickerProvider();
    final controller = AnimationController(
      vsync: ticker,
      duration: Duration(milliseconds: durationMs),
    );
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      ctrl.move(
        ll.LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
        ticker.dispose();
      }
    });
    controller.forward();
  }

  @override
  void dispose() {
    _settings.removeListener(_onProviderChanging);
    super.dispose();
  }
}

/// Minimal TickerProvider for one-off animation controllers.
class _SingleTickerProvider extends TickerProvider {
  Ticker? _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _ticker = Ticker(onTick);
    return _ticker!;
  }

  void dispose() {
    _ticker?.dispose();
  }
}
