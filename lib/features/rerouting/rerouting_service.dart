import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show Point, Position;
import 'package:nabour_app/services/routing_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Monitorizează devierea șoferului de la rută și recalculează automat.
/// Activat când șoferul e în cursă activă (după preluare pasager).
class ReroutingService {
  static final ReroutingService _instance = ReroutingService._();
  factory ReroutingService() => _instance;
  ReroutingService._();

  static const String _tag = 'REROUTING';
  static const double _deviationThresholdMeters = 80.0;
  static const int _checkIntervalSeconds = 5;

  final RoutingService _routingService = RoutingService();

  /// Ruta curentă ca listă de coordonate [lng, lat]
  List<List<double>> _currentRouteCoords = [];

  /// Destinația finală
  double? _destLat;
  double? _destLng;

  Timer? _checkTimer;
  bool _isActive = false;

  /// Callback apelat cu noua rută (coordonate [lng, lat]) și instrucțiune text
  Function(List<List<double>> newCoords, String instruction)? onReroute;

  /// Pornește monitorizarea.
  /// [routeCoords] = lista de coordonate [[lng, lat], ...] a rutei curente.
  void start(List<List<double>> routeCoords) {
    if (routeCoords.isEmpty) return;
    _currentRouteCoords = routeCoords;
    final last = routeCoords.last;
    _destLng = last[0];
    _destLat = last[1];
    _isActive = true;
    Logger.info('Rerouting monitor started', tag: _tag);

    _checkTimer = Timer.periodic(
      const Duration(seconds: _checkIntervalSeconds),
      (_) => _checkDeviation(),
    );
  }

  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isActive = false;
    _currentRouteCoords = [];
    _destLat = null;
    _destLng = null;
    Logger.info('Rerouting monitor stopped', tag: _tag);
  }

  Future<void> _checkDeviation() async {
    if (!_isActive || _currentRouteCoords.isEmpty) return;

    try {
      final currentPos = await geo.Geolocator.getCurrentPosition(
        locationSettings:
            const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
      );

      final distanceToRoute = _minDistanceToRoute(currentPos);

      if (distanceToRoute > _deviationThresholdMeters) {
        Logger.warning(
          'Driver deviated ${distanceToRoute.toStringAsFixed(0)}m — rerouting',
          tag: _tag,
        );
        await _performReroute(currentPos);
      }
    } catch (e) {
      Logger.debug('Rerouting check failed: $e', tag: _tag);
    }
  }

  double _minDistanceToRoute(geo.Position currentPos) {
    double minDistance = double.infinity;
    for (final coord in _currentRouteCoords) {
      final dist = geo.Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        coord[1], // lat
        coord[0], // lng
      );
      if (dist < minDistance) minDistance = dist;
    }
    return minDistance;
  }

  Future<void> _performReroute(geo.Position fromPos) async {
    if (_destLat == null || _destLng == null) return;

    try {
      final waypoints = [
        Point(coordinates: Position(fromPos.longitude, fromPos.latitude)),
        Point(coordinates: Position(_destLng!, _destLat!)),
      ];

      final result = await _routingService.getRoute(waypoints);

      if (result == null) return;

      // Extrage coordonatele din geometria rutei
      final routes = result['routes'] as List?;
      if (routes == null || routes.isEmpty) return;

      final geometry = (routes.first as Map<String, dynamic>)['geometry']
          as Map<String, dynamic>?;
      if (geometry == null) return;

      final rawCoords = geometry['coordinates'] as List?;
      if (rawCoords == null || rawCoords.isEmpty) return;

      final newCoords = rawCoords
          .map((c) => [
                (c as List)[0].toDouble() as double, // lng
                (c)[1].toDouble() as double,          // lat
              ])
          .toList();

      _currentRouteCoords = newCoords;
      onReroute?.call(newCoords, 'Rută recalculată');
      Logger.info('Rerouting successful — ${newCoords.length} pts', tag: _tag);
    } catch (e) {
      Logger.error('Rerouting failed: $e', tag: _tag, error: e);
    }
  }
}
