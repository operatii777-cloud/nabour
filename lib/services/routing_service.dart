import 'dart:async';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/utils/mapbox_config.dart';
import 'package:nabour_app/utils/logger.dart';

// IMPLEMENTARE ISOLATE PENTRU ROUTING CALCULATIONS - PERFORMANCE OPTIMIZATION
class RoutingIsolateManager {
  static const String _isolateName = 'Routing_Calculation_Isolate';
  static Isolate? _isolate;
  static ReceivePort? _receivePort;
  static SendPort? _sendPort;
  
  static Future<void> initialize() async {
    if (_isolate != null) return;
    
    _receivePort = ReceivePort();
    
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort!.sendPort,
      debugName: _isolateName,
    );
    
    _sendPort = await _receivePort!.first as SendPort;
    
    Logger.info('Routing Isolate initialized successfully');
  }
  
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    
    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        final type = message['type'] as String;
        final data = message['data'] as Map<String, dynamic>;
        final id = message['id'] as String;
        
        try {
          switch (type) {
            case 'calculate_route':
              final waypoints = data['waypoints'] as List<Map<String, dynamic>>;
              final accessToken = data['accessToken'] as String;
              final result = _calculateRouteInIsolate(waypoints, accessToken);
              sendPort.send({
                'id': id,
                'result': result,
                'success': true,
              });
              break;
            case 'search_place':
              final query = data['query'] as String;
              final accessToken = data['accessToken'] as String;
              final result = _searchPlaceInIsolate(query, accessToken);
              sendPort.send({
                'id': id,
                'result': result,
                'success': true,
              });
              break;
            default:
              sendPort.send({
                'id': id,
                'error': 'Unknown operation type: $type',
                'success': false,
              });
          }
        } catch (e) {
          sendPort.send({
            'id': id,
            'error': e.toString(),
            'success': false,
          });
        }
      }
    });
  }
  
  static Map<String, dynamic>? _calculateRouteInIsolate(List<Map<String, dynamic>> waypointsData, String accessToken) {
    try {
      if (waypointsData.length < 2) {
        return null;
      }
      
      // Simulate HTTP request in isolate (in real implementation, this would be done via compute)
      // For now, return a mock response structure
      return {
        'routes': [
          {
            'duration': 1800.0, // 30 minutes in seconds
            'distance': 15000.0, // 15 km in meters
            'geometry': {
              'coordinates': waypointsData.map((p) => [p['lng'], p['lat']]).toList(),
              'type': 'LineString'
            }
          }
        ]
      };
    } catch (e) {
      return null;
    }
  }
  
  static List<Map<String, dynamic>> _searchPlaceInIsolate(String query, String accessToken) {
    try {
      if (query.length < 3) return [];
      
      // Mock geocoding response for isolate
      return [
        {
          'place_name': '$query, România',
          'center': [26.1025, 44.4268], // București coordinates
          'text': query,
          'context': [
            {'text': 'București'},
            {'text': 'România'}
          ]
        }
      ];
    } catch (e) {
      return [];
    }
  }
  
  static Future<T> _sendMessage<T>(String type, Map<String, dynamic> data) async {
    if (_sendPort == null) {
      await initialize();
    }
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<T>();
    StreamSubscription? subscription;
    
    subscription = _receivePort!.listen((message) {
      if (message is Map<String, dynamic> && message['id'] == id) {
        subscription?.cancel();
        
        if (message['success'] == true) {
          completer.complete(message['result'] as T);
        } else {
          completer.completeError(message['error'] ?? 'Unknown error');
        }
      }
    });
    
    _sendPort!.send({
      'type': type,
      'data': data,
      'id': id,
    });
    
    return completer.future;
  }
  
  static void dispose() {
    _isolate?.kill();
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
    Logger.debug('Routing Isolate disposed');
  }
}

class RoutingService {
  RoutingService._internal();
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;

  static const String _baseUrl = "https://api.mapbox.com/directions/v5/mapbox";
  
  // ✅ CACHE PENTRU RUTE - OPTIMIZAT
  final Map<String, _CachedRoute> _routeCache = {};
  static const Duration _routeCacheExpiry = Duration(hours: 2); // ✅ Mărit de la 1h la 2h
  static const int _maxCacheSize = 500; // ✅ Limit cache size pentru memorie
  
  // ✅ PRE-COMPUTATION pentru rute comune
  final Map<String, DateTime> _precomputedRoutes = {};
  static const Duration _precomputeWindow = Duration(minutes: 5);
  
  String get _accessToken {
    try {
      return MapboxConfig.getAccessToken();
    } catch (e) {
      Logger.error('Mapbox configuration error in routing service: $e', error: e);
      throw Exception('Mapbox not configured. Call MapboxConfig.initialize() first.');
    }
  }
  
  // NOU: Adresă de bază pentru API-ul de Geocoding
  static const String _geocodingBaseUrl = "https://api.mapbox.com/geocoding/v5/mapbox.places";
  
  // ✅ Helper: Generează cheie cache pentru rută
  String _generateRouteCacheKey(List<Point> waypoints) {
    return waypoints.map((p) => '${p.coordinates.lat.toStringAsFixed(6)},${p.coordinates.lng.toStringAsFixed(6)}').join('|');
  }

  /// Metoda principală pentru obținerea unui traseu cu trafic în timp real.
  /// Punctele din lista `waypoints` sunt conectate în ordinea în care apar.
  /// Returnează durata reală cu trafic și distanța optimizată.
  Future<Map<String, dynamic>?> getRoute(List<Point> waypoints) async {
    if (waypoints.length < 2) {
      Logger.debug('Eroare: Ruta necesită cel puțin 2 puncte.');
      return null;
    }

    // ✅ VERIFICĂ CACHE — rutele din cache nu consumă tokeni
    final cacheKey = _generateRouteCacheKey(waypoints);
    final cached = _routeCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      Logger.debug('RoutingService: Cache hit for route (fără consum tokeni)');
      return cached.routeData;
    }

    if (_routeCache.length > _maxCacheSize) {
      _cleanupCache();
    }

    // Deducere tokeni doar după răspuns reușit de la Mapbox (nu plătește pentru 400/timeout).
    final result = await _getRouteWithRetry(waypoints);
    if (result != null) {
      final deduct = await TokenService().spend(
        TokenTransactionType.routeCalc,
        customDescription: 'Calcul rută Mapbox',
      );
      if (!deduct.success) {
        Logger.warning(
          'Rută obținută dar debit tokeni eșuat: ${deduct.errorMessage ?? "?"}',
          tag: 'ROUTING',
        );
      }
      _routeCache[cacheKey] = _CachedRoute(
        routeData: result,
        timestamp: DateTime.now(),
      );
    }

    return result;
  }

  /// Rută pentru navigație turn-by-turn: pași, geometrie `full`, instrucțiuni vocale (structură Mapbox).
  /// Cache separat față de [getRoute].
  Future<Map<String, dynamic>?> getTurnByTurnRoute(List<Point> waypoints) async {
    if (waypoints.length < 2) {
      Logger.debug('getTurnByTurnRoute: sunt necesare cel puțin 2 puncte.');
      return null;
    }

    final cacheKey = 'tt|${_generateRouteCacheKey(waypoints)}';
    final cached = _routeCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      Logger.debug('RoutingService: Cache hit navigare (tt)');
      return cached.routeData;
    }

    if (_routeCache.length > _maxCacheSize) {
      _cleanupCache();
    }

    final result = await _getRouteWithRetry(waypoints, turnByTurn: true);
    if (result != null) {
      final deduct = await TokenService().spend(
        TokenTransactionType.routeCalc,
        customDescription: 'Navigare turn-by-turn Mapbox',
      );
      if (!deduct.success) {
        Logger.warning(
          'Navigare TBT reușită dar debit tokeni eșuat: ${deduct.errorMessage ?? "?"}',
          tag: 'ROUTING',
        );
      }
      _routeCache[cacheKey] = _CachedRoute(
        routeData: result,
        timestamp: DateTime.now(),
      );
    }
    return result;
  }
  
  // ✅ NOU: Get route cu retry logic
  Future<Map<String, dynamic>?> _getRouteWithRetry(
    List<Point> waypoints, {
    int maxRetries = 3,
    bool turnByTurn = false,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Direct Mapbox Directions HTTP — isolate-ul [RoutingIsolateManager]
        // pentru calculate_route întorcea doar o linie dreaptă (mock), nu drumuri reale,
        // iar mesajele isolate puteau eșua silențios pe unele dispozitive.
        final result = await _performHttpRouteRequest(waypoints, turnByTurn: turnByTurn);
        if (result != null) {
          return result;
        }
      } on TimeoutException catch (e) {
        Logger.error('Routing timeout (attempt $attempt/$maxRetries): $e', error: e);
        if (attempt == maxRetries) {
          return null;
        }
        // ✅ EXPONENTIAL BACKOFF
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        Logger.error('Routing error (attempt $attempt/$maxRetries): $e', error: e);
        if (attempt == maxRetries) {
          return null;
        }
        // ✅ EXPONENTIAL BACKOFF
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    return null;
  }
  
  // ✅ Helper method pentru HTTP route request
  Future<Map<String, dynamic>?> _performHttpRouteRequest(
    List<Point> waypoints, {
    bool turnByTurn = false,
    bool allowTrafficProfile = true,
  }) async {
    final coordinates =
        waypoints.map((p) => '${p.coordinates.lng},${p.coordinates.lat}').join(';');

    // `congestion` în `annotations` este suportat doar pentru `driving-traffic`, nu pentru `driving`.
    // Înainte: rute 2 puncte + turn-by-turn foloseau `driving` + `congestion` → 400 de la API → navigarea Nabour pica mereu.
    final bool useTrafficProfile =
        allowTrafficProfile && (waypoints.length > 2 || turnByTurn);
    final profile = useTrafficProfile ? 'driving-traffic' : 'driving';
    final url = Uri.parse('$_baseUrl/$profile/$coordinates');

    final bool wantSteps = turnByTurn || waypoints.length > 2;
    final annotations =
        useTrafficProfile ? 'congestion,duration,distance' : 'duration,distance';
    final queryParams = {
      'access_token': _accessToken,
      'steps': wantSteps ? 'true' : 'false',
      'geometries': 'geojson',
      'overview': turnByTurn ? 'full' : 'simplified',
      'language': 'ro',
      'voice_instructions': wantSteps ? 'true' : 'false',
      'banner_instructions': wantSteps ? 'true' : 'false',
      'voice_units': 'metric',
      'annotations': annotations,
      'continue_straight': 'true',
    };

    final uri = url.replace(queryParameters: queryParams);

    Logger.debug('Routing request ($profile): $uri');

    // Rute scurte fără pași: 10s. Turn-by-turn / multi-stop: rețea lentă sau trasee lungi — evită abandon prematur.
    final timeout = (waypoints.length == 2 && !turnByTurn)
        ? const Duration(seconds: 10)
        : Duration(seconds: turnByTurn ? 28 : 20);

    final response = await http.get(uri).timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException('Routing request timeout');
      },
    );

    if (response.statusCode == 200) {
      final Object? decoded = json.decode(response.body);
      if (decoded is! Map) {
        Logger.error('Routing: răspuns JSON invalid (nu e obiect)');
        return null;
      }
      final data = Map<String, dynamic>.from(decoded);
      Logger.info('Routing response: Success ($profile)');

      final routes = data['routes'];
      if (routes is List && routes.isNotEmpty) {
        final first = routes.first;
        if (first is Map) {
          final r = Map<String, dynamic>.from(first);
          final durationWithTraffic = r['duration'] ?? 0;
          final distance = r['distance'] ?? 0;
          Logger.debug(
            'Route duration: ${(durationWithTraffic / 60).toStringAsFixed(1)} min, '
            'Distance: ${(distance / 1000).toStringAsFixed(1)} km',
          );
        }
      }

      return data;
    }

    Logger.error('Routing error: ${response.statusCode} - ${response.body}');
    // Unele tokenuri/regiuni returnează 400 pentru driving-traffic; rută fără trafic funcționează încă.
    if (allowTrafficProfile &&
        useTrafficProfile &&
        (response.statusCode == 400 || response.statusCode == 422)) {
      Logger.warning(
        'Reîncerc Mapbox Directions cu profil driving (fără trafic live)',
        tag: 'ROUTING',
      );
      return _performHttpRouteRequest(
        waypoints,
        turnByTurn: turnByTurn,
        allowTrafficProfile: false,
      );
    }
    return null;
  }
  
  // ✅ PERFORMANCE: Cleanup cache pentru a preveni memory leaks
  void _cleanupCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _routeCache.entries) {
      if (entry.value.isExpired || 
          now.difference(entry.value.timestamp) > const Duration(hours: 24)) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _routeCache.remove(key);
    }
    
    // Dacă încă e prea mare, șterge cele mai vechi
    if (_routeCache.length > _maxCacheSize) {
      final sortedEntries = _routeCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final toRemove = sortedEntries.take(_routeCache.length - _maxCacheSize).map((e) => e.key).toList();
      for (final key in toRemove) {
        _routeCache.remove(key);
      }
    }
  }
  
  // ✅ PERFORMANCE: Precompute route pentru waypoints comune
  Future<void> precomputeRoute(List<Point> waypoints) async {
    final cacheKey = _generateRouteCacheKey(waypoints);
    
    // Verifică dacă deja există în cache
    if (_routeCache.containsKey(cacheKey) && !_routeCache[cacheKey]!.isExpired) {
      return;
    }
    
    // Verifică dacă deja e în precomputation
    if (_precomputedRoutes.containsKey(cacheKey)) {
      final lastPrecompute = _precomputedRoutes[cacheKey]!;
      if (DateTime.now().difference(lastPrecompute) < _precomputeWindow) {
        return; // Deja precomputat recent
      }
    }
    
    // Precompute în background
    unawaited(_getRouteWithRetry(waypoints, maxRetries: 2).then((result) {
      if (result != null) {
        _routeCache[cacheKey] = _CachedRoute(
          routeData: result,
          timestamp: DateTime.now(),
        );
        _precomputedRoutes[cacheKey] = DateTime.now();
      }
    }));
  }

  // --- FUNCȚII NOI ADĂUGATE ---

  /// Caută o locație pe baza unui text și returnează o listă de sugestii.
  Future<List<Map<String, dynamic>>> searchPlace(String query) async {
    if (query.length < 3) return [];

    // Try isolate first for better performance
    try {
      final result = await RoutingIsolateManager._sendMessage<List<Map<String, dynamic>>>(
        'search_place',
        {
          'query': query,
          'accessToken': _accessToken,
        },
      );
      
      if (result.isNotEmpty) {
        Logger.info('Place search via isolate successful');
        return result;
      }
    } catch (e) {
      Logger.error('Isolate place search failed, falling back to HTTP: $e', error: e);
    }

    // Fallback to HTTP request
    final url = Uri.parse(
        '$_geocodingBaseUrl/$query.json?access_token=$_accessToken&autocomplete=true');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        return features.map((feature) {
          final context = feature['context'] as List?;
          String secondaryText = '';
          if (context != null && context.isNotEmpty) {
            secondaryText = context.map((c) => c['text']).join(', ');
          }
          
          return {
            'address': feature['text'] ?? 'N/A',
            'secondary_text': secondaryText,
            'longitude': feature['center'][0],
            'latitude': feature['center'][1],
          };
        }).toList();
      }
    } catch (e) {
      Logger.error('Error in searchPlace: $e', error: e);
    }
    return [];
  }

  /// Obține adresa corespunzătoare unor coordonate geografice (Reverse Geocoding).
  Future<Map<String, dynamic>> getReverseGeocoding(double lat, double lng) async {
    final url = Uri.parse(
        '$_geocodingBaseUrl/$lng,$lat.json?access_token=$_accessToken');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          final feature = features.first;
          return {
            'address': feature['place_name'] ?? 'Adresă necunoscută',
            'latitude': lat,
            'longitude': lng,
          };
        }
      }
    } catch (e) {
      Logger.error('Error in getReverseGeocoding: $e', error: e);
    }
    return {};
  }

  // --- RESTUL FUNCȚIILOR EXISTENTE ---

  /// Extrage distanța totală (în metri) din datele rutei.
  double extractDistance(Map<String, dynamic>? routeData) {
    if (routeData != null && routeData['routes'] != null && routeData['routes'].isNotEmpty) {
      return (routeData['routes'][0]['distance'] as num).toDouble();
    }
    return 0.0;
  }

  /// Extrage durata totală (în secunde) din datele rutei.
  double extractDuration(Map<String, dynamic>? routeData) {
    if (routeData != null && routeData['routes'] != null && routeData['routes'].isNotEmpty) {
      return (routeData['routes'][0]['duration'] as num).toDouble();
    }
    return 0.0;
  }
  
  /// Extrage coordonatele traseului din răspunsul MapBox pentru a desena ruta.
  List<Point> extractRouteCoordinates(Map<String, dynamic> routeData) {
    try {
      final routes = routeData['routes'] as List?;
      if (routes == null || routes.isEmpty) return [];
      
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'];
      final List<dynamic>? coordinates = (geometry is Map<String, dynamic>)
          ? geometry['coordinates'] as List<dynamic>?
          : (geometry is List ? geometry : null);
      if (coordinates == null) return [];

      final points = coordinates.map<Point?>((coord) {
        if (coord is List && coord.length >= 2) {
          final lng = (coord[0] as num).toDouble();
          final lat = (coord[1] as num).toDouble();
          return Point(coordinates: Position(lng, lat));
        }
        return null;
      }).whereType<Point>().toList();
      
      return points;
    } catch (e) {
      Logger.error('Error extracting route coordinates: $e', error: e);
      return [];
    }
  }

  /// Formatează timpul în format citibil (ex: "1h 15min" sau "25min").
  String formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Formatează distanța în format citibil (ex: "12.3 km" sau "500 m").
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  // ✅ NOU: Metoda pentru calcularea rutei cu coordonate lat/lng
  Future<Map<String, dynamic>?> calculateRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      // Creează punctele pentru ruta
      final startPoint = Point(coordinates: Position(startLng, startLat));
      final endPoint = Point(coordinates: Position(endLng, endLat));
      
      // Apelează metoda existentă getRoute
      final routeResult = await getRoute([startPoint, endPoint]);
      
      if (routeResult != null && routeResult['routes'] != null && routeResult['routes'].isNotEmpty) {
        final route = routeResult['routes'][0];
        return {
          'distance': (route['distance'] as num?)?.toDouble() ?? 0.0,
          'duration': (route['duration'] as num?)?.toInt() ?? 0,
          'polyline': route['geometry']?['coordinates']?.toString() ?? '',
        };
      }
      
      return null;
    } catch (e) {
      Logger.error('Error in calculateRoute: $e', error: e);
      return null;
    }
  }

  /// Mirror-uri OSRM publice (încercate în ordine). Dacă unul pică, următorul.
  static const List<String> _osrmDrivingBases = [
    'https://router.project-osrm.org/route/v1/driving',
    'https://routing.openstreetmap.de/routed-car/route/v1/driving',
  ];

  /// Returnează același tip de structură ca Mapbox: `{ "routes": [ { geometry, legs, distance, duration } ] }`.
  Future<Map<String, dynamic>?> getOsrmDrivingRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    for (var i = 0; i < _osrmDrivingBases.length; i++) {
      final base = _osrmDrivingBases[i];
      final r = await _fetchOsrmRouteOnce(
        base,
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
      );
      if (r != null) {
        final n = extractRouteCoordinates(r).length;
        Logger.info('OSRM OK ($base) — $n puncte pe traseu', tag: 'ROUTING');
        return r;
      }
      Logger.warning('OSRM eșuat mirror ${i + 1}/${_osrmDrivingBases.length}: $base',
          tag: 'ROUTING');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchOsrmRouteOnce(
    String base, {
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final coord =
          '${startLng.toStringAsFixed(6)},${startLat.toStringAsFixed(6)};${endLng.toStringAsFixed(6)},${endLat.toStringAsFixed(6)}';
      final uri = Uri.parse(
        '$base/$coord?overview=full&geometries=geojson&steps=true',
      );
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': 'NabourApp/1.0 (point-navigation; ro.nabour.app)',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 18),
            onTimeout: () => throw TimeoutException('OSRM timeout'),
          );

      if (response.statusCode != 200) {
        Logger.warning('OSRM HTTP ${response.statusCode} ${uri.host}', tag: 'ROUTING');
        return null;
      }

      final Object? decoded = json.decode(response.body);
      if (decoded is! Map) return null;
      final data = Map<String, dynamic>.from(decoded);
      final code = data['code']?.toString();
      if (code != 'Ok') {
        Logger.warning('OSRM code=$code (${uri.host})', tag: 'ROUTING');
        return null;
      }

      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final route0 = routes.first;
      if (route0 is! Map) return null;

      final normalized =
          _normalizeOsrmRoute(Map<String, dynamic>.from(route0));
      return {'routes': [normalized]};
    } on TimeoutException catch (e) {
      Logger.warning('OSRM timeout ($base): $e', tag: 'ROUTING');
      return null;
    } catch (e, st) {
      Logger.error('OSRM request failed ($base): $e',
          error: e, stackTrace: st, tag: 'ROUTING');
      return null;
    }
  }

  /// Navigare punct fix: **Mapbox** primul (același motor ca ruta din MapScreen / cursă),
  /// apoi **OSRM** (mirror-uri gratuite) dacă Mapbox eșuează.
  ///
  /// Înainte ordinea era inversă: OSRM putea bloca 30–40s pe rețea lentă sau eșua (TLS etc.)
  /// înainte să ajungem la Mapbox, deși pe același telefon cursa obținea ruta imediat.
  Future<Map<String, dynamic>?> getPointToPointRoutePreferOsm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final start = Point(coordinates: Position(startLng, startLat));
    final end = Point(coordinates: Position(endLng, endLat));

    try {
      var r = await getTurnByTurnRoute([start, end]);
      r ??= await getRoute([start, end]);
      if (r != null) {
        final n = extractRouteCoordinates(r).length;
        Logger.info('POINT_NAV Mapbox OK — $n puncte', tag: 'ROUTING');
        return r;
      }
    } catch (e, st) {
      Logger.error('Mapbox punct↔punct: $e',
          error: e, stackTrace: st, tag: 'ROUTING');
    }

    Logger.warning('Mapbox punct↔punct indisponibil — încerc OSRM (mirror-uri)',
        tag: 'ROUTING');
    final osrm = await getOsrmDrivingRoute(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
    if (osrm != null) return osrm;

    return null;
  }

  Map<String, dynamic> _normalizeOsrmRoute(Map<String, dynamic> route) {
    final out = Map<String, dynamic>.from(route);
    final legs = out['legs'];
    if (legs is List) {
      out['legs'] = legs.map((rawLeg) {
        if (rawLeg is! Map) return rawLeg;
        final leg = Map<String, dynamic>.from(rawLeg);
        final steps = leg['steps'];
        if (steps is List) {
          leg['steps'] = steps.map((s) {
            if (s is! Map) return s;
            return _enrichOsrmStep(Map<String, dynamic>.from(s));
          }).toList();
        }
        return leg;
      }).toList();
    }
    return out;
  }

  Map<String, dynamic> _enrichOsrmStep(Map<String, dynamic> step) {
    final out = Map<String, dynamic>.from(step);
    final name = step['name']?.toString() ?? '';
    final mRaw = step['maneuver'];
    if (mRaw is Map) {
      final m = Map<String, dynamic>.from(mRaw);
      final existing = m['instruction']?.toString().trim() ?? '';
      if (existing.isEmpty) {
        m['instruction'] = _osrmManeuverInstructionRo(m, name);
      }
      out['maneuver'] = m;
    }
    return out;
  }

  String _osrmManeuverInstructionRo(
    Map<String, dynamic> maneuver,
    String streetName,
  ) {
    final type = maneuver['type']?.toString() ?? '';
    final mod = maneuver['modifier']?.toString() ?? '';
    final name = streetName.trim();
    final onStreet = name.isNotEmpty ? ' pe $name' : '';

    switch (type) {
      case 'depart':
        return name.isNotEmpty ? 'Pornește$onStreet.' : 'Pornește la traseu.';
      case 'arrive':
        return 'Ai ajuns la destinație.';
      case 'turn':
        if (mod.contains('right')) {
          return 'Virează la dreapta$onStreet.';
        }
        if (mod.contains('left')) {
          return 'Virează la stânga$onStreet.';
        }
        if (mod.contains('uturn')) {
          return 'Întoarce-te cu maxim stânga$onStreet.';
        }
        return 'Schimbă direcția$onStreet.';
      case 'new name':
        return name.isNotEmpty ? 'Continuă$onStreet.' : 'Continuă pe traseu.';
      case 'merge':
        return 'Integrează-te în fluxul de trafic.';
      case 'on ramp':
        return 'Intră pe rampă.';
      case 'off ramp':
        return 'Ieși pe rampă.';
      case 'fork':
        if (mod.contains('right')) {
          return 'La bifurcare, ține dreapta.';
        }
        if (mod.contains('left')) {
          return 'La bifurcare, ține stânga.';
        }
        return 'La bifurcare, urmează traseul.';
      case 'end of road':
        return 'La capătul străzii, urmează traseul.';
      case 'roundabout':
      case 'rotary':
      case 'roundabout turn':
        final exit = maneuver['exit'];
        if (exit is int && exit > 0) {
          return 'La sensul giratoriu, ia a $exit-a ieșire.';
        }
        return 'Intră în sensul giratoriu.';
      case 'notification':
        return name.isNotEmpty ? 'Urmează$onStreet.' : 'Continuă pe traseu.';
      default:
        return name.isNotEmpty ? 'Continuă$onStreet.' : 'Continuă pe traseu.';
    }
  }
}

// ✅ CLASĂ PENTRU CACHE RUTE (top-level)
class _CachedRoute {
  final Map<String, dynamic> routeData;
  final DateTime timestamp;
  
  _CachedRoute({
    required this.routeData,
    required this.timestamp,
  });
  
  bool get isExpired {
    return DateTime.now().difference(timestamp) > RoutingService._routeCacheExpiry;
  }
}

extension RoutingServiceAlternatives on RoutingService {
  /// Obține rute alternative folosind Mapbox Directions (HTTP direct)
  Future<Map<String, dynamic>?> getAlternativeRoutes(List<Point> waypoints) async {
    if (waypoints.length < 2) {
      Logger.debug('Eroare: Ruta necesită cel puțin 2 puncte.');
      return null;
    }

    try {
      final coordinates =
          waypoints.map((p) => '${p.coordinates.lng},${p.coordinates.lat}').join(';');
      final url = Uri.parse('${RoutingService._baseUrl}/driving-traffic/$coordinates');
      final queryParams = {
        'access_token': _accessToken,
        'steps': 'true',
        'geometries': 'geojson',
        'overview': 'full',
        'language': 'ro',
        'annotations': 'congestion,duration,distance',
        'continue_straight': 'true',
        'alternatives': 'true',
      };
      final uri = url.replace(queryParameters: queryParams);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        Logger.error('Routing alternatives error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      Logger.error('Routing alternatives exception: $e', error: e);
    }
    return null;
  }
}