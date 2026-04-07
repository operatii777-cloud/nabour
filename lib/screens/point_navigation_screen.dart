import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:latlong2/latlong.dart';
import 'package:nabour_app/services/location_cache_service.dart';
import 'package:nabour_app/services/navigation_service.dart';
import 'package:nabour_app/services/routing_service.dart';
import 'package:nabour_app/utils/deprecated_apis_fix.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Navigare în aplicație către un punct.
///
/// Model UX aliniat cu **Google Maps**: mai întâi **previzualizare rută** (hartă + ETA/distanță,
/// fără urmărire agresivă), apăsare **„Pornește navigarea”** → abia atunci flux tip Waze/Maps activ:
/// streaming GPS, cameră după curs, instrucțiuni + TTS, detecție sosire.
///
/// **Hartă:** `flutter_map` + tile-uri OpenStreetMap (același stivă ca în cursă activă).
/// **Rută:** Mapbox Directions (ca pe MapScreen) → OSRM dacă Mapbox pică → linie dreaptă dacă totul pică.
class PointNavigationScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationLabel;

  /// Ultima poziție cunoscută pe MapScreen (puck / GPS deja obținut acolo).
  /// Folosită ca origine imediată dacă Geolocator întârzie (main thread încărcat).
  final double? mapKnownOriginLat;
  final double? mapKnownOriginLng;

  const PointNavigationScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationLabel,
    this.mapKnownOriginLat,
    this.mapKnownOriginLng,
  });

  @override
  State<PointNavigationScreen> createState() => _PointNavigationScreenState();
}

class _PointNavigationScreenState extends State<PointNavigationScreen> {
  static const double _arrivalRadiusM = 38;
  final RoutingService _routingService = RoutingService();
  NavigationService? _navigationService;

  final MapController _mapController = MapController();
  bool _mapReady = false;
  List<LatLng> _routePolyline = [];
  bool _isManualPan = false;
  Timer? _autoRecenterTimer;
  LatLng? _liveUserLatLng;

  bool _routeLoading = true;
  String? _routeError;
  /// OSRM/Mapbox au eșuat; afișăm linie dreaptă dar permitem navigare minimă.
  bool _straightLineFallback = false;
  Map<String, dynamic>? _routeData;
  geolocator.Position? _originPosition;

  List<Map<String, dynamic>> _steps = [];
  int _activeStepIndex = 0;
  bool _hasArrived = false;
  int _lastSpokenStep = -1;

  StreamSubscription<geolocator.Position>? _posSub;
  StreamSubscription<NavigationUpdate>? _navUpdateSub;
  Timer? _followCameraDebounce;
  geolocator.Position? _pendingFollowCameraPosition;
  FlutterTts? _tts;
  double _remainToDestM = 0;

  /// `false` = doar preview rută (ca Google Maps înainte de „Start”); `true` = navigare activă.
  bool _driveModeActive = false;
  /// Durată estimată pe traseu (secunde din răspunsul rută).
  Duration? _routeDurationEstimate;
  /// Metri parcurs pe traseul selectat (nu euclidian).
  double? _routeDistanceMeters;

  /// Distanța față de capătul pasului curent (din [NavigationService]) — opțional UI.
  double? _distanceToStepEndM;

  /// Utilizatorul e prea departe de segmentul pasului curent (metri, logică în serviciu).
  bool _offRouteHint = false;

  geolocator.Position? _lastCameraPositionForBearing;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _initTts();
    await _loadNavigationRoute();
  }

  Future<void> _initTts() async {
    final t = FlutterTts();
    try {
      await t.setLanguage('ro-RO');
      await t.setSpeechRate(0.42);
      await t.awaitSpeakCompletion(true);
    } catch (_) {}
    if (mounted) _tts = t;
  }

  static geolocator.Position _syntheticPosition(double lat, double lng) {
    final now = DateTime.now();
    return geolocator.Position(
      latitude: lat,
      longitude: lng,
      timestamp: now,
      accuracy: 80,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  static bool _validLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    return lat.abs() <= 90 && lng.abs() <= 180;
  }

  Future<geolocator.Position?> _obtainStartPosition() async {
    try {
      var perm = await geolocator.Geolocator.checkPermission();
      var gpsAllowed = perm == geolocator.LocationPermission.always ||
          perm == geolocator.LocationPermission.whileInUse;
      if (perm == geolocator.LocationPermission.denied) {
        perm = await geolocator.Geolocator.requestPermission();
        gpsAllowed = perm == geolocator.LocationPermission.always ||
            perm == geolocator.LocationPermission.whileInUse;
      } else if (perm == geolocator.LocationPermission.deniedForever) {
        gpsAllowed = false;
      }

      // Seed rapid: poziție de pe hartă (MapScreen) + cache + lastKnown — înainte de HIGH.
      geolocator.Position? mapSeed;
      if (_validLatLng(
          widget.mapKnownOriginLat, widget.mapKnownOriginLng)) {
        mapSeed = _syntheticPosition(
          widget.mapKnownOriginLat!, widget.mapKnownOriginLng!);
        Logger.info(
          'POINT_NAV: seed de pe hartă (MapScreen) '
          '${widget.mapKnownOriginLat!.toStringAsFixed(5)},'
          '${widget.mapKnownOriginLng!.toStringAsFixed(5)}',
          tag: 'POINT_NAV',
        );
      }

      final cached = LocationCacheService.instance.peekRecent(
        
      );
      geolocator.Position? lastKnown;
      try {
        lastKnown = await geolocator.Geolocator.getLastKnownPosition()
            .timeout(const Duration(seconds: 2), onTimeout: () => null);
      } catch (_) {}
      final seed = LocationCacheService.pickNewer(
        mapSeed,
        LocationCacheService.pickNewer(cached, lastKnown),
      );
      if (seed != null && mapSeed == null) {
        Logger.info(
          'POINT_NAV: seed din cache/lastKnown (vârsta fix ${DateTime.now().difference(seed.timestamp).inSeconds}s)',
          tag: 'POINT_NAV',
        );
      }

      if (!gpsAllowed) {
        if (seed != null) {
          Logger.warning(
            'POINT_NAV: fără permisiune GPS activă — folosesc originea din hartă/cache',
            tag: 'POINT_NAV',
          );
          LocationCacheService.instance.record(seed);
          return seed;
        }
        if (mounted) {
          setState(() {
            _routeLoading = false;
            _routeError =
                'Permisiunea la locație lipsește și nu avem poziție de pe hartă. '
                'Activează locația sau deschide navigarea din nou din hartă.';
          });
        }
        return null;
      }

      geolocator.Position? pos;
      // Mai întâi precizie medie — fix mai rapid pe multe telefoane.
      try {
        pos = await geolocator.Geolocator.getCurrentPosition(
          locationSettings: DeprecatedAPIsFix.createLocationSettings(
            accuracy: geolocator.LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          ),
        ).timeout(const Duration(seconds: 12));
        LocationCacheService.instance.record(pos);
      } catch (e) {
        Logger.warning('PointNavigation: GPS medium: $e', tag: 'POINT_NAV');
      }

      if (pos == null) {
        try {
          pos = await geolocator.Geolocator.getCurrentPosition(
            locationSettings: DeprecatedAPIsFix.createLocationSettings(
              accuracy: geolocator.LocationAccuracy.high,
              timeLimit: const Duration(seconds: 18),
            ),
          ).timeout(const Duration(seconds: 20));
          LocationCacheService.instance.record(pos);
        } catch (e) {
          Logger.warning('PointNavigation: GPS high: $e', tag: 'POINT_NAV');
        }
      }

      pos ??= seed;
      if (pos != null) {
        LocationCacheService.instance.record(pos);
      }

      if (pos == null && mounted) {
        setState(() {
          _routeLoading = false;
          _routeError =
              'Nu am putut obține locația curentă. Verifică GPS-ul și permisiunile, apoi apasă închidere și încearcă din nou.';
        });
      }
      return pos;
    } catch (e, st) {
      Logger.error('PointNavigation obtain position: $e',
          error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _routeLoading = false;
          _routeError ??= 'Nu am putut citi locația. Încearcă din nou.';
        });
      }
      return null;
    }
  }

  /// Mapbox pune text util în `banner_instructions` / `voice_instructions`, nu doar în `maneuver.instruction`.
  String _instructionTextForStep(Map<String, dynamic> step) {
    final m = step['maneuver'];
    if (m is Map) {
      final s = m['instruction']?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    final banners =
        step['banner_instructions'] ?? step['bannerInstructions'];
    if (banners is List) {
      for (final b in banners) {
        if (b is! Map) continue;
        final pri = b['primary'];
        if (pri is Map) {
          final t = pri['text']?.toString().trim();
          if (t != null && t.isNotEmpty) return t;
          final comps = pri['components'] as List?;
          if (comps != null) {
            final parts = <String>[];
            for (final c in comps) {
              if (c is Map && c['text'] != null) {
                parts.add(c['text'].toString());
              }
            }
            if (parts.isNotEmpty) return parts.join();
          }
        }
      }
    }
    final vi = (step['voice_instructions'] ?? step['voiceInstructions']) as List?;
    if (vi != null && vi.isNotEmpty) {
      final x = vi.first;
      if (x is Map) {
        for (final key in ['announcement', 'ssmlAnnouncement']) {
          final a = x[key]?.toString().trim();
          if (a != null && a.isNotEmpty) return a;
        }
      }
    }
    return '';
  }

  /// Rută minimă (LineString 2 puncte) când serverele de rutare nu răspund — polilinie + ETA aproximativ.
  Map<String, dynamic> _straightLineRouteData(geolocator.Position pos) {
    final d = geolocator.Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      widget.destinationLat,
      widget.destinationLng,
    );
    final sec = (d / 13.89).round().clamp(1, 864000);
    return {
      'routes': [
        {
          'distance': d,
          'duration': sec,
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              [pos.longitude, pos.latitude],
              [widget.destinationLng, widget.destinationLat],
            ],
          },
          'legs': [
            {
              'steps': <Map<String, dynamic>>[],
              'distance': d,
              'duration': sec,
            },
          ],
        },
      ],
    };
  }

  Future<void> _fetchApplyRoute(
    geolocator.Position pos, {
    required bool resetToPreviewMode,
  }) async {
    Logger.info(
      'POINT_NAV: cerere rută ${pos.latitude.toStringAsFixed(5)},${pos.longitude.toStringAsFixed(5)} → '
      '${widget.destinationLat.toStringAsFixed(5)},${widget.destinationLng.toStringAsFixed(5)}',
      tag: 'POINT_NAV',
    );

    Map<String, dynamic>? route =
        await _routingService.getPointToPointRoutePreferOsm(
      startLat: pos.latitude,
      startLng: pos.longitude,
      endLat: widget.destinationLat,
      endLng: widget.destinationLng,
    );

    if (!mounted) return;

    var usedFallbackLine = false;
    if (route == null || (route['routes'] as List?)?.isEmpty != false) {
      route = _straightLineRouteData(pos);
      usedFallbackLine = true;
      Logger.warning(
        'POINT_NAV: OSRM+Mapbox indisponibile — folosesc linie dreaptă (distanță haversine)',
        tag: 'POINT_NAV',
      );
    }

    _steps = _parseSteps(route);
    _activeStepIndex = 0;
    _lastSpokenStep = -1;
    _offRouteHint = false;
    _distanceToStepEndM = null;
    _remainToDestM = geolocator.Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      widget.destinationLat,
      widget.destinationLng,
    );
    _applyRouteMetrics(route);

    final pts = _routingService.extractRouteCoordinates(route);
    var poly = pts
        .map(
          (p) => LatLng(p.coordinates.lat.toDouble(), p.coordinates.lng.toDouble()),
        )
        .toList();

    if (poly.length < 2) {
      poly = [
        LatLng(pos.latitude, pos.longitude),
        LatLng(widget.destinationLat, widget.destinationLng),
      ];
      Logger.warning(
        'POINT_NAV: geometrie rută goală sau invalidă — desenez linie dreaptă',
        tag: 'POINT_NAV',
      );
    }

    Logger.info(
      'POINT_NAV: rută aplicată — ${poly.length} vtx, fallbackLinie=$usedFallbackLine',
      tag: 'POINT_NAV',
    );

    setState(() {
      _originPosition = pos;
      _liveUserLatLng = LatLng(pos.latitude, pos.longitude);
      _routeData = route;
      _routePolyline = poly;
      _routeError = null;
      _straightLineFallback = usedFallbackLine;
      if (resetToPreviewMode) _driveModeActive = false;
    });

    if (usedFallbackLine && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Traseu aproximativ (linie dreaptă): serverele de rutare nu au răspuns. '
              'Verifică rețeaua și folosește Recalculează.',
            ),
            duration: Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    void scheduleFits() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitRouteInView();
      });
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _fitRouteInView();
      });
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _fitRouteInView();
      });
    }

    scheduleFits();
  }

  Future<void> _loadNavigationRoute() async {
    try {
      final pos = await _obtainStartPosition();
      if (pos == null) {
        if (mounted) setState(() => _routeLoading = false);
        return;
      }

      await _fetchApplyRoute(pos, resetToPreviewMode: true);

      if (!mounted) return;
      setState(() => _routeLoading = false);
    } catch (e, st) {
      Logger.error('PointNavigation route load failed: $e',
          error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _routeLoading = false;
          _routeError = 'Eroare la calculul rutei.';
        });
      }
    }
  }

  Future<void> _recalculateRoute() async {
    if (_hasArrived || _routeLoading) return;
    final wasDrive = _driveModeActive;
    await _disposeNavigationTracking();

    if (!mounted) return;
    setState(() {
      _routeLoading = true;
      _routeError = null;
      _offRouteHint = false;
    });

    try {
      geolocator.Position? pos = _originPosition;
      try {
        pos = await geolocator.Geolocator.getCurrentPosition(
          locationSettings: DeprecatedAPIsFix.createLocationSettings(
            accuracy: geolocator.LocationAccuracy.high,
            timeLimit: const Duration(seconds: 14),
          ),
        );
      } catch (_) {
        pos ??= await geolocator.Geolocator.getLastKnownPosition();
      }

      if (!mounted) return;
      if (pos == null) {
        setState(() {
          _routeLoading = false;
          _routeError = 'Nu am putut obține locația pentru recalculare.';
        });
        if (wasDrive) await _startLocationTracking();
        return;
      }

      await _fetchApplyRoute(pos, resetToPreviewMode: !wasDrive);

      if (!mounted) return;
      setState(() => _routeLoading = false);

      if (wasDrive) {
        setState(() => _driveModeActive = true);
        await _startLocationTracking();
        unawaited(_speakCurrentInstruction(force: true));
      }
    } catch (e, st) {
      Logger.error('PointNavigation recalc failed: $e',
          error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _routeLoading = false;
          _routeError = 'Recalcularea traseului a eșuat.';
        });
      }
      if (wasDrive && mounted) await _startLocationTracking();
    }
  }

  void _applyRouteMetrics(Map<String, dynamic> routeData) {
    _routeDurationEstimate = null;
    _routeDistanceMeters = null;
    try {
      final routes = routeData['routes'] as List?;
      if (routes == null || routes.isEmpty) return;
      final r = routes.first;
      if (r is! Map) return;
      final rm = Map<String, dynamic>.from(r);
      final dur = rm['duration'];
      final dist = rm['distance'];
      if (dur is num) {
        _routeDurationEstimate = Duration(seconds: dur.ceil());
      }
      if (dist is num) {
        _routeDistanceMeters = dist.toDouble();
      }
    } catch (_) {}
  }

  Future<void> _beginDriveMode() async {
    if (!mounted || _hasArrived || _routeData == null || _driveModeActive) return;
    await WakelockPlus.enable();
    setState(() => _driveModeActive = true);
    unawaited(_speakCurrentInstruction(force: true));
    await _startLocationTracking();
  }

  List<Map<String, dynamic>> _parseSteps(Map<String, dynamic> routeData) {
    try {
      final routes = routeData['routes'] as List?;
      if (routes == null || routes.isEmpty) return [];
      final legs = (routes.first as Map)['legs'] as List?;
      if (legs == null || legs.isEmpty) return [];
      final steps = (legs.first as Map)['steps'] as List?;
      if (steps == null) return [];
      return steps.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _disposeNavigationTracking() async {
    await _posSub?.cancel();
    await _navUpdateSub?.cancel();
    _posSub = null;
    _navUpdateSub = null;
    _navigationService?.dispose();
    _navigationService = null;
  }

  Future<void> _startLocationTracking() async {
    await _disposeNavigationTracking();
    final origin = _originPosition;
    if (!mounted || origin == null) return;

    _navigationService = NavigationService();
    final navSteps = NavigationStep.fromMapboxSteps(
      _steps,
      fallbackStartLat: origin.latitude,
      fallbackStartLng: origin.longitude,
      fallbackEndLat: widget.destinationLat,
      fallbackEndLng: widget.destinationLng,
    );

    // Abonări înainte de setRoute/startTracking ca să nu pierdem primul NavigationUpdate (broadcast).
    _posSub = _navigationService!.positionStream.listen(
      _onPositionTick,
      onError: (Object e) {
        Logger.warning('PointNavigation position stream: $e', tag: 'POINT_NAV');
      },
    );
    _navUpdateSub = _navigationService!.navigationStream.listen(
      _onNavigationUpdate,
      onError: (Object e) {
        Logger.warning('PointNavigation navigation stream: $e', tag: 'POINT_NAV');
      },
    );

    _navigationService!.setRoute(navSteps);
    final trackingOk = await _navigationService!.startTracking();
    if (!mounted) return;

    if (!trackingOk) {
      await _disposeNavigationTracking();
      await WakelockPlus.disable();
      if (!mounted) return;
      setState(() {
        _driveModeActive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Navigarea activă necesită locația activă și permisiuni. Activează GPS-ul și încearcă din nou.',
          ),
        ),
      );
    }
  }

  void _onNavigationUpdate(NavigationUpdate u) {
    if (!mounted || _hasArrived || !_driveModeActive) return;
    final maxIdx = _steps.isEmpty ? 0 : (_steps.length - 1);
    final idx = u.stepIndex.clamp(0, maxIdx);
    final prevDisplayed = _activeStepIndex;

    setState(() {
      _activeStepIndex = idx;
      _offRouteHint = u.offRoute;
      _distanceToStepEndM = u.distanceToStepEndMeters;
    });

    if (idx > prevDisplayed) {
      unawaited(_speakCurrentInstruction(force: false));
    }
  }

  void _onPositionTick(geolocator.Position pos) {
    if (!mounted || _hasArrived || !_driveModeActive) return;

    final destM = geolocator.Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      widget.destinationLat,
      widget.destinationLng,
    );

    setState(() {
      _remainToDestM = destM;
      _liveUserLatLng = LatLng(pos.latitude, pos.longitude);
    });

    if (destM <= _arrivalRadiusM) {
      unawaited(_completeArrival());
      return;
    }

    if (_mapReady && !_isManualPan) {
      _pendingFollowCameraPosition = pos;
      _followCameraDebounce?.cancel();
      _followCameraDebounce = Timer(const Duration(milliseconds: 72), () {
        _followCameraDebounce = null;
        final p = _pendingFollowCameraPosition;
        if (!mounted || p == null || !_mapReady || _isManualPan) return;
        unawaited(_followCamera(p));
      });
    }
  }

  LatLng? get _displayUserLatLng =>
      _liveUserLatLng ??
      (_originPosition != null
          ? LatLng(_originPosition!.latitude, _originPosition!.longitude)
          : null);

  void _fitRouteInView() {
    if (!_mapReady || !mounted) return;
    final pts = <LatLng>[
      if (_displayUserLatLng != null) _displayUserLatLng!,
      ..._routePolyline,
      LatLng(widget.destinationLat, widget.destinationLng),
    ];
    if (pts.length < 2) return;
    try {
      final bounds = LatLngBounds.fromPoints(pts);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: EdgeInsets.fromLTRB(
            36,
            160,
            36,
            _driveModeActive ? 200 : 280,
          ),
        ),
      );
    } catch (e) {
      Logger.debug('PointNavigation fitCamera: $e', tag: 'POINT_NAV');
    }
  }

  Future<void> _followCamera(geolocator.Position pos) async {
    if (!mounted || !_mapReady) return;
    try {
      double bearing = pos.heading;
      final speed = pos.speed;
      final headingBad = bearing < 0 || bearing > 360 || bearing.isNaN;
      if (headingBad || speed < 0.9) {
        final prev = _lastCameraPositionForBearing;
        if (prev != null) {
          bearing = geolocator.Geolocator.bearingBetween(
            prev.latitude,
            prev.longitude,
            pos.latitude,
            pos.longitude,
          );
        }
        if (bearing < 0 || bearing > 360 || bearing.isNaN) bearing = 0;
      }
      _lastCameraPositionForBearing = pos;

      _mapController.moveAndRotate(
        LatLng(pos.latitude, pos.longitude),
        17,
        -bearing,
      );
    } catch (e) {
      Logger.debug('followCamera: $e', tag: 'POINT_NAV');
    }
  }

  Future<void> _speakCurrentInstruction({required bool force}) async {
    if (_tts == null || !mounted) return;
    final text = _primaryInstruction();
    if (text.isEmpty) return;
    if (!force && _lastSpokenStep == _activeStepIndex) return;
    _lastSpokenStep = _activeStepIndex;
    try {
      await _tts!.stop();
      await _tts!.speak(text);
    } catch (_) {}
  }

  String _primaryInstruction() {
    if (_steps.isEmpty) {
      return 'Navighează spre destinație.';
    }
    final i = _activeStepIndex.clamp(0, _steps.length - 1);
    final text = _instructionTextForStep(_steps[i]);
    if (text.isNotEmpty) return text;
    return 'Continuă pe traseu.';
  }

  IconData _maneuverIcon() {
    if (_steps.isEmpty) return Icons.navigation_rounded;
    final i = _activeStepIndex.clamp(0, _steps.length - 1);
    final step = _steps[i];
    Map<dynamic, dynamic>? m = step['maneuver'] as Map<dynamic, dynamic>?;
    if (m == null || m.isEmpty) {
      final banners =
          (step['banner_instructions'] ?? step['bannerInstructions']) as List?;
      if (banners != null && banners.isNotEmpty) {
        final b = banners.first;
        if (b is Map && b['primary'] is Map) {
          m = b['primary'] as Map<dynamic, dynamic>?;
        }
      }
    }
    if (m == null || m.isEmpty) return Icons.arrow_upward_rounded;
    final type = m['type']?.toString() ?? '';
    final mod = m['modifier']?.toString() ?? '';
    if (type.contains('roundabout')) return Icons.rotate_right;
    if (mod == 'left' || type.contains('left')) return Icons.turn_left_rounded;
    if (mod == 'right' || type.contains('right')) return Icons.turn_right_rounded;
    if (type.contains('uturn')) return Icons.u_turn_left;
    if (type.contains('merge')) return Icons.merge_rounded;
    if (type.contains('fork')) return Icons.call_split_rounded;
    if (type == 'arrive') return Icons.flag_rounded;
    return Icons.arrow_upward_rounded;
  }

  Future<void> _completeArrival() async {
    if (_hasArrived) return;
    _hasArrived = true;
    await _disposeNavigationTracking();

    HapticFeedback.heavyImpact();
    try {
      await _tts?.stop();
      await _tts?.speak('Ai sosit la destinație.');
    } catch (_) {}

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          icon: Icon(Icons.place_rounded, size: 48, color: Theme.of(ctx).colorScheme.primary),
          title: const Text('Ai sosit!'),
          content: Text(
            widget.destinationLabel,
            style: Theme.of(ctx).textTheme.bodyLarge,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _recenterOnUser() async {
    if (!_mapReady) return;
    try {
      final pos = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _isManualPan = false;
        _liveUserLatLng = LatLng(pos.latitude, pos.longitude);
      });
      await _followCamera(pos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nu am putut centra pe locația ta: $e')),
        );
      }
    }
  }

  String _formatRemain(double m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)} km';
    return '${m.round()} m';
  }

  /// Rezumat: timp estimat pe traseu · distanță rută (din OSRM).
  String _routeSummaryLine() {
    final d = _routeDurationEstimate;
    final routeM = _routeDistanceMeters;
    if (d == null && routeM == null) {
      return 'Aprox. ${_formatRemain(_remainToDestM)} (distanță directă)';
    }
    final parts = <String>[];
    if (d != null) {
      final sec = d.inSeconds;
      if (sec < 60) {
        parts.add('< 1 min');
      } else {
        final totalMin = d.inMinutes;
        if (totalMin >= 60) {
          parts.add('${totalMin ~/ 60} h ${totalMin % 60} min');
        } else {
          parts.add('$totalMin min');
        }
      }
    }
    if (routeM != null) {
      parts.add(_formatRemain(routeM));
    }
    return parts.join(' · ');
  }

  @override
  void dispose() {
    _followCameraDebounce?.cancel();
    _autoRecenterTimer?.cancel();
    _mapController.dispose();
    unawaited(_disposeNavigationTracking());
    unawaited(WakelockPlus.disable());
    unawaited(_tts?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = LatLng(widget.destinationLat, widget.destinationLng);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.destinationLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_routeLoading && !_hasArrived)
            IconButton(
              tooltip: 'Recalculează traseul',
              onPressed: () => unawaited(_recalculateRoute()),
              icon: const Icon(Icons.refresh_rounded),
            ),
          IconButton(
            tooltip: 'Centrare pe mine',
            onPressed: _recenterOnUser,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14.5,
              onMapReady: () {
                if (!mounted) return;
                setState(() => _mapReady = true);
                _fitRouteInView();
              },
              onPositionChanged: (camera, hasGesture) {
                if (!hasGesture) return;
                if (!_isManualPan) setState(() => _isManualPan = true);
                _autoRecenterTimer?.cancel();
                _autoRecenterTimer = Timer(const Duration(seconds: 6), () {
                  if (mounted) setState(() => _isManualPan = false);
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ro.nabour.app',
              ),
              if (_routePolyline.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePolyline,
                      color: theme.colorScheme.primary,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_displayUserLatLng != null)
                    Marker(
                      point: _displayUserLatLng!,
                      child: Icon(
                        Icons.navigation_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                  Marker(
                    point: LatLng(widget.destinationLat, widget.destinationLng),
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.place_rounded,
                      color: theme.colorScheme.error,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_isManualPan && !_routeLoading && !_hasArrived)
            Positioned(
              top: 72,
              right: 12,
              child: FloatingActionButton.small(
                heroTag: 'point_nav_recenter',
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                onPressed: () {
                  setState(() => _isManualPan = false);
                  _fitRouteInView();
                },
                child: Icon(Icons.zoom_out_map_rounded,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),

          // Faza 2 — navigare activă (după „Pornește navigarea”): bandă instrucțiuni + voce.
          if (!_routeLoading && _routeError == null && !_hasArrived && _driveModeActive)
            Positioned(
              left: 12,
              right: 12,
              top: 8,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.97),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_maneuverIcon(), size: 30,
                            color: theme.colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _primaryInstruction(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Până la destinație: ${_formatRemain(_remainToDestM)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (_distanceToStepEndM != null &&
                                _steps.isNotEmpty &&
                                _distanceToStepEndM! > 8)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Până la capătul manevrei: ${_formatRemain(_distanceToStepEndM!)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_outlined),
                        tooltip: 'Repetă voce',
                        onPressed: () => unawaited(_speakCurrentInstruction(force: true)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!_routeLoading && _routeError == null && !_hasArrived && _driveModeActive && _offRouteHint)
            Positioned(
              left: 12,
              right: 12,
              top: 100,
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.96),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.alt_route_rounded, color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Te-ai îndepărtat de traseu. Recalculează din butonul de sus sau aici.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _routeLoading ? null : () => unawaited(_recalculateRoute()),
                        child: const Text('Recalculează'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Faza 1 — preview rută (model Google Maps: vezi traseul, apoi confirmi start).
          if (!_routeLoading && _routeError == null && !_hasArrived && !_driveModeActive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.98),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _routeSummaryLine(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.destinationLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _primaryInstruction(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          if (_straightLineFallback) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Traseu estimat pe linie dreaptă (nu urmează străzi). '
                              'Reîncearcă Recalculează când ai rețea stabilă.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: () => unawaited(_beginDriveMode()),
                            icon: const Icon(Icons.navigation_rounded),
                            label: const Text('Pornește navigarea'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Poți verifica traseul pe hartă înainte de a porni — ca în Google Maps.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_routeLoading)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),

          if (_routeError != null && !_routeLoading)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _routeError!,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
