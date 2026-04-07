import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/utils/deprecated_apis_fix.dart';

/// Un pas de navigare derivat din Mapbox Directions (segment start → end pe hartă).
class NavigationStep {
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String instruction;

  /// Din `maneuver.type` (ex.: turn, arrive, depart).
  final String? type;

  /// Din `maneuver.modifier` (ex.: left, right, slight left).
  final String? modifier;

  /// Lungimea pasului în metri (`distance` din API sau estimare pe segment).
  final double distance;

  NavigationStep({
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.instruction,
    this.type,
    this.modifier,
    this.distance = 0,
  });

  /// Construiește pași din `legs[0].steps`; dacă nu există pași, folosește un singur segment start→dest.
  static List<NavigationStep> fromMapboxSteps(
    List<Map<String, dynamic>> rawSteps, {
    required double fallbackStartLat,
    required double fallbackStartLng,
    required double fallbackEndLat,
    required double fallbackEndLng,
  }) {
    if (rawSteps.isEmpty) {
      return [
        NavigationStep(
          startLat: fallbackStartLat,
          startLng: fallbackStartLng,
          endLat: fallbackEndLat,
          endLng: fallbackEndLng,
          instruction: 'Navighează spre destinație.',
          distance: Geolocator.distanceBetween(
            fallbackStartLat,
            fallbackStartLng,
            fallbackEndLat,
            fallbackEndLng,
          ),
        ),
      ];
    }

    final out = <NavigationStep>[];
    ({double lat, double lng})? prevEnd;
    for (var i = 0; i < rawSteps.length; i++) {
      final s = rawSteps[i];
      var a = _segmentStart(s);
      var b = _segmentEnd(s);
      if (a == null && b != null) a = b;
      if (b == null && a != null) b = a;
      if (a == null || b == null) {
        final m = s['maneuver'];
        if (m is Map && m['location'] is List) {
          final loc = m['location'] as List;
          final p = (
            lat: (loc[1] as num).toDouble(),
            lng: (loc[0] as num).toDouble(),
          );
          a = p;
          b = p;
        }
      }
      if (a == null || b == null) {
        final fallback = prevEnd ??
            (
              lat: fallbackStartLat,
              lng: fallbackStartLng,
            );
        a = fallback;
        b = (
          lat: fallbackEndLat,
          lng: fallbackEndLng,
        );
      }
      if (a.lat == b.lat && a.lng == b.lng) {
        b = (
          lat: a.lat + 8e-6,
          lng: a.lng,
        );
      }
      final (mt, mm) = _maneuverTypeModifier(s);
      out.add(NavigationStep(
        startLat: a.lat,
        startLng: a.lng,
        endLat: b.lat,
        endLng: b.lng,
        instruction: _instructionTextForMapboxStep(s),
        type: mt,
        modifier: mm,
        distance: _stepDistanceMeters(s, a.lat, a.lng, b.lat, b.lng),
      ));
      prevEnd = (lat: b.lat, lng: b.lng);
    }

    if (out.isEmpty) {
      return [
        NavigationStep(
          startLat: fallbackStartLat,
          startLng: fallbackStartLng,
          endLat: fallbackEndLat,
          endLng: fallbackEndLng,
          instruction: 'Navighează spre destinație.',
          distance: Geolocator.distanceBetween(
            fallbackStartLat,
            fallbackStartLng,
            fallbackEndLat,
            fallbackEndLng,
          ),
        ),
      ];
    }
    return out;
  }

  static (String?, String?) _maneuverTypeModifier(Map<String, dynamic> step) {
    final m = step['maneuver'];
    if (m is! Map) return (null, null);
    final type = m['type']?.toString();
    final modifier = m['modifier']?.toString();
    final t = (type != null && type.isEmpty) ? null : type;
    final mod = (modifier != null && modifier.isEmpty) ? null : modifier;
    return (t, mod);
  }

  static double _stepDistanceMeters(
    Map<String, dynamic> step,
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final d = step['distance'];
    if (d is num) return d.toDouble();
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  static ({double lat, double lng})? _segmentStart(Map<String, dynamic> step) {
    try {
      final g = step['geometry'];
      if (g is Map && g['coordinates'] is List) {
        final coords = g['coordinates'] as List;
        if (coords.isNotEmpty) {
          final first = coords.first as List;
          return (
            lat: (first[1] as num).toDouble(),
            lng: (first[0] as num).toDouble(),
          );
        }
      }
      final m = step['maneuver'];
      if (m is Map && m['location'] is List) {
        final loc = m['location'] as List;
        return (
          lat: (loc[1] as num).toDouble(),
          lng: (loc[0] as num).toDouble(),
        );
      }
    } catch (_) {}
    return null;
  }

  static ({double lat, double lng})? _segmentEnd(Map<String, dynamic> step) {
    try {
      final g = step['geometry'];
      if (g is Map && g['coordinates'] is List) {
        final coords = g['coordinates'] as List;
        if (coords.isNotEmpty) {
          final last = coords.last as List;
          return (
            lat: (last[1] as num).toDouble(),
            lng: (last[0] as num).toDouble(),
          );
        }
      }
      final m = step['maneuver'];
      if (m is Map && m['location'] is List) {
        final loc = m['location'] as List;
        return (
          lat: (loc[1] as num).toDouble(),
          lng: (loc[0] as num).toDouble(),
        );
      }
    } catch (_) {}
    return null;
  }

  static String _instructionTextForMapboxStep(Map<String, dynamic> step) {
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
}

/// Stare agregată pentru UI (pas curent, distanță până la capătul pasului, off-route).
class NavigationUpdate {
  final int stepIndex;
  final NavigationStep? currentStep;
  final double distanceToStepEndMeters;
  final bool offRoute;

  NavigationUpdate({
    required this.stepIndex,
    this.currentStep,
    required this.distanceToStepEndMeters,
    this.offRoute = false,
  });
}

/// Un singur flux GPS → poziție + logică de pas / off-route pe **segmentul** pasului curent.
class NavigationService {
  static const double _advanceRadiusM = 26;
  static const int _advanceCooldownMs = 2200;
  static const double _offRouteHighM = 88;
  static const double _offRouteLowM = 48;

  StreamSubscription<Position>? _positionSubscription;
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();
  final StreamController<NavigationUpdate> _navigationController =
      StreamController<NavigationUpdate>.broadcast();

  List<NavigationStep> _currentSteps = [];
  int _currentStepIndex = 0;
  DateTime? _lastStepAdvance;
  bool _offRouteLatch = false;
  NavigationUpdate? _lastNavigationUpdate;

  Stream<Position> get positionStream => _positionController.stream;
  Stream<NavigationUpdate> get navigationStream => _navigationController.stream;

  /// Număr de pași în ruta curentă (0 dacă nu e setată).
  int get routeStepCount => _currentSteps.length;

  /// Sumă `distance` pe pași (metri), din ruta curentă.
  double get routeTotalLengthMeters =>
      _currentSteps.fold(0.0, (sum, step) => sum + step.distance);

  /// Ultima stare emisă; util pentru UI înainte de primul eveniment GPS.
  NavigationUpdate? get lastNavigationUpdate => _lastNavigationUpdate;

  void setRoute(List<NavigationStep> steps) {
    _currentSteps = List<NavigationStep>.from(steps);
    _currentStepIndex = 0;
    _lastStepAdvance = null;
    _offRouteLatch = false;
    if (_currentSteps.isEmpty) {
      _emitNavigationUpdate(
        NavigationUpdate(
          stepIndex: 0,
          distanceToStepEndMeters: 0,
        ),
      );
    } else {
      final first = _currentSteps.first;
      _emitNavigationUpdate(
        NavigationUpdate(
          stepIndex: 0,
          currentStep: first,
          distanceToStepEndMeters: first.distance,
        ),
      );
    }
  }

  void _emitNavigationUpdate(NavigationUpdate update) {
    _lastNavigationUpdate = update;
    if (!_navigationController.isClosed) {
      _navigationController.add(update);
    }
  }

  Future<bool> checkPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Returnează `false` dacă permisiunea GPS lipsește sau serviciul de locație e oprit.
  Future<bool> startTracking() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return false;

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: DeprecatedAPIsFix.createLocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 4,
      ),
    ).listen(
      (position) {
        if (!_positionController.isClosed) {
          _positionController.add(position);
        }
        _processNavigation(position);
      },
      onError: (_) {},
    );
    return true;
  }

  void _processNavigation(Position position) {
    if (_navigationController.isClosed) return;

    if (_currentSteps.isEmpty) {
      _emitNavigationUpdate(NavigationUpdate(
        stepIndex: 0,
        distanceToStepEndMeters: 0,
      ));
      return;
    }

    if (_currentStepIndex >= _currentSteps.length) {
      _emitNavigationUpdate(NavigationUpdate(
        stepIndex: _currentSteps.length,
        distanceToStepEndMeters: 0,
      ));
      return;
    }

    final step = _currentSteps[_currentStepIndex];
    final distanceToEnd = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      step.endLat,
      step.endLng,
    );

    final distToSegment = _distanceToSegmentMeters(
      position.latitude,
      position.longitude,
      step.startLat,
      step.startLng,
      step.endLat,
      step.endLng,
    );

    if (distToSegment > _offRouteHighM) {
      _offRouteLatch = true;
    } else if (distToSegment < _offRouteLowM) {
      _offRouteLatch = false;
    }

    if (distanceToEnd < _advanceRadiusM &&
        _currentStepIndex < _currentSteps.length - 1) {
      final now = DateTime.now();
      if (_lastStepAdvance == null ||
          now.difference(_lastStepAdvance!).inMilliseconds >=
              _advanceCooldownMs) {
        _lastStepAdvance = now;
        _currentStepIndex++;
        _processNavigation(position);
        return;
      }
    }

    _emitNavigationUpdate(NavigationUpdate(
      stepIndex: _currentStepIndex,
      currentStep: step,
      distanceToStepEndMeters: distanceToEnd,
      offRoute: _offRouteLatch,
    ));
  }

  /// Distanța minimă (m) de la punctul P la segmentul AB — aproximare plană (OK pe distanțe scurte).
  double _distanceToSegmentMeters(
    double pLat,
    double pLng,
    double aLat,
    double aLng,
    double bLat,
    double bLng,
  ) {
    const metersPerDegLat = 111320.0;
    final metersPerDegLng = metersPerDegLat * math.cos(aLat * math.pi / 180);

    final px = (pLng - aLng) * metersPerDegLng;
    final py = (pLat - aLat) * metersPerDegLat;
    final bx = (bLng - aLng) * metersPerDegLng;
    final by = (bLat - aLat) * metersPerDegLat;

    final segLenSq = bx * bx + by * by;
    if (segLenSq == 0) {
      return math.sqrt(px * px + py * py);
    }

    final t = ((px * bx + py * by) / segLenSq).clamp(0.0, 1.0).toDouble();
    final closestX = bx * t;
    final closestY = by * t;
    final dx = px - closestX;
    final dy = py - closestY;
    return math.sqrt(dx * dx + dy * dy);
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopTracking();
    if (!_positionController.isClosed) {
      unawaited(_positionController.close());
    }
    if (!_navigationController.isClosed) {
      unawaited(_navigationController.close());
    }
  }

  static double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  static double bearingBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }
}
