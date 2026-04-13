import 'dart:async';
import 'dart:convert';
import 'dart:math' as math; // Pentru funcțiile trigonometrice
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:nabour_app/services/poi_geojson_worker.dart';
import 'package:nabour_app/models/poi_model.dart';
import 'package:nabour_app/utils/mapbox_config.dart';
import 'package:nabour_app/services/offline_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:nabour_app/utils/logger.dart';

class PoiService {
  static final PoiService _instance = PoiService._internal();
  factory PoiService() => _instance;
  PoiService._internal();

  // API constants
  static const String _baseUrl =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';

  String get _accessToken {
    try {
      return MapboxConfig.getAccessToken();
    } catch (e) {
      Logger.error('Mapbox configuration error in POI service: $e', error: e);
      throw Exception(
          'Mapbox not configured. Call MapboxConfig.initialize() first.');
    }
  }

  // Cache și performance
  final Map<String, List<PointOfInterest>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 15);
  static const int _maxCacheSize = 50;

  // Grid/TTL persistent cache (persist last N cells)
  // Cell key: grid around proximity by truncating coords to 3 decimals (~110m precision)
  final Map<String, List<PointOfInterest>> _gridCache = {};
  final Map<String, DateTime> _gridCacheTimestamps = {};
  static const Duration _gridTtl = Duration(minutes: 20);
  static const int _gridMaxEntries = 60; // persist last N cells

  // Coalescing pentru cereri dinamice (POI Search)
  final Map<String, Future<List<PointOfInterest>>> _inflightFetches = {};

  // POI-uri locale încărcate din assets (GeoJSON/GPX/KML)
  final List<PointOfInterest> _localPois = [];
  bool _geojsonLoaded = false;
  bool _gpxLoaded = false;
  bool _kmlLoaded = false;

  /// True când fișierele locale OSM (din `assets/poi/`) au fost încărcate.
  /// Folosit pentru a evita apeluri Mapbox Places înainte să avem datele locale.
  bool get isLocalAssetsLoaded => _geojsonLoaded || _gpxLoaded || _kmlLoaded;

  // Filtrare activă
  Set<PoiCategory> _activeCategories = {
    PoiCategory.gasStation,
    PoiCategory.restaurant,
    PoiCategory.parking,
    PoiCategory.hospital,
  };

  // Lista statică de puncte de interes (păstrată pentru compatibilitate)
  final List<PointOfInterest> _staticPois = [
    PointOfInterest(
      id: 'static_parlament',
      name: 'Palatul Parlamentului',
      description: 'A doua cea mai mare clădire administrativă din lume.',
      imageUrl:
          'https://placehold.co/600x400/9C27B0/FFFFFF?text=🏛️+Palatul+Parlamentului',
      location: Position(
          latitude: 44.4275,
          longitude: 26.0875,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0),
      category: PoiCategory.tourism,
      isStatic: true,
    ),
    PointOfInterest(
      id: 'static_ateneu',
      name: 'Ateneul Român',
      description:
          'O sală de concerte emblematică și un simbol al culturii române.',
      imageUrl:
          'https://placehold.co/600x400/9C27B0/FFFFFF?text=🏛️+Ateneul+Roman',
      location: Position(
          latitude: 44.4415,
          longitude: 26.0975,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0),
      category: PoiCategory.tourism,
      isStatic: true,
    ),
    PointOfInterest(
      id: 'static_mnar',
      name: 'Muzeul Național de Artă al României',
      description:
          'Găzduit în fostul Palat Regal, expune artă românească și europeană.',
      imageUrl: 'https://placehold.co/600x400/9C27B0/FFFFFF?text=🏛️+MNAR',
      location: Position(
          latitude: 44.4404,
          longitude: 26.0963,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0),
      category: PoiCategory.tourism,
      isStatic: true,
    ),
    PointOfInterest(
      id: 'static_botanica',
      name: 'Grădina Botanică "Dimitrie Brandza"',
      description: 'O oază de liniște și biodiversitate în mijlocul orașului.',
      imageUrl:
          'https://placehold.co/600x400/9C27B0/FFFFFF?text=🏛️+Gradina+Botanica',
      location: Position(
          latitude: 44.4367,
          longitude: 26.0625,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0),
      category: PoiCategory.tourism,
      isStatic: true,
    ),
    PointOfInterest(
      id: 'static_herastrau',
      name: 'Parcul Herăstrău',
      description:
          'Cel mai mare parc din București, ideal pentru relaxare și plimbări.',
      imageUrl:
          'https://placehold.co/600x400/9C27B0/FFFFFF?text=🏛️+Parcul+Herastrau',
      location: Position(
          latitude: 44.4715,
          longitude: 26.0825,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0),
      category: PoiCategory.tourism,
      isStatic: true,
    ),
  ];

  // (reserved) Caching/coalescing pentru Searchbox (neutilizat în prezent)

  // =================
  // PUBLIC API METHODS
  // =================

  /// Obține POI-uri pentru o zonă specifică (statice + dinamice)
  Future<List<PointOfInterest>> getPoisForArea({
    required double latitude,
    required double longitude,
    double radiusKm = 2.0,
    Set<PoiCategory>? categories,
  }) async {
    final List<PointOfInterest> allPois = [];

    // Adaugă POI-urile statice întotdeauna (obiective turistice)
    allPois.addAll(_staticPois);

    // Adaugă POI-urile locale din assets (filtrate spațial + după categorie)
    final activeCategories = categories ?? _activeCategories;
    for (final poi in _localPois) {
      if (activeCategories.contains(poi.category)) {
        final d = _distanceMeters(
            latitude, longitude, poi.location.latitude, poi.location.longitude);
        if (d <= radiusKm * 1000.0) {
          allPois.add(poi);
        }
      }
    }

    // Adaugă POI-urile dinamice dacă sunt în categoriile active
    for (final category in activeCategories) {
      if (category != PoiCategory.tourism) {
        // Turismul e static
        final dynamicPois = await _fetchDynamicPois(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          category: category,
        );
        allPois.addAll(dynamicPois);
      }
    }

    // Dedupe după coordonate (lat/lng la 6 zecimale) pentru a evita suprapuneri locale/dinamice
    final Set<String> seen = {};
    final List<PointOfInterest> deduped = [];
    for (final p in allPois) {
      final key =
          '${p.location.latitude.toStringAsFixed(6)}_${p.location.longitude.toStringAsFixed(6)}_${p.category.name}';
      if (!seen.contains(key)) {
        seen.add(key);
        deduped.add(p);
      }
    }

    return deduped;
  }

  /// Compatibilitate cu codul existent
  List<PointOfInterest> getPois() {
    return _staticPois;
  }

  /// POI-uri locale (din assets) pentru o categorie specifică
  List<PointOfInterest> getLocalPoisByCategory(PoiCategory category) {
    final List<PointOfInterest> result = [];
    for (final p in _localPois) {
      if (p.category == category) result.add(p);
    }
    // Include și staticele dacă se potrivesc
    for (final p in _staticPois) {
      if (p.category == category) result.add(p);
    }
    return result;
  }

  /// Toate POI-urile locale (din assets), indiferent de categorie
  List<PointOfInterest> getAllLocalPois() {
    return List<PointOfInterest>.from(_localPois)..addAll(_staticPois);
  }

  /// Setează categoriile active de POI-uri
  void setActiveCategories(Set<PoiCategory> categories) {
    _activeCategories = categories;
    _clearCache(); // Clear cache când se schimbă categoriile
  }

  /// Obține categoriile active
  Set<PoiCategory> getActiveCategories() {
    return Set.from(_activeCategories);
  }

  // (legacy helper removed; single implementation below)

  // =================
  // MAPBOX PLACES API INTEGRATION
  // =================

  /// Fetch POI-uri dinamice din Mapbox Places API
  Future<List<PointOfInterest>> _fetchDynamicPois({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required PoiCategory category,
  }) async {
    final cellLat = latitude.toStringAsFixed(3);
    final cellLng = longitude.toStringAsFixed(3);
    final cacheKey = '${cellLat}_${cellLng}_${radiusKm}_${category.mapboxType}';

    // Verifică cache-ul în memorie (rapid)
    if (_isCacheValid(cacheKey)) {
      Logger.debug('Cache hit for ${category.displayName}');
      return _cache[cacheKey] ?? [];
    }

    // Verifică grid/TTL cache persistent (în memorie, cu TTL separat)
    final gridKey = 'grid_${cellLat}_${cellLng}_${category.mapboxType}';
    if (_gridCache.containsKey(gridKey) &&
        _gridCacheTimestamps.containsKey(gridKey)) {
      final ts = _gridCacheTimestamps[gridKey]!;
      if (DateTime.now().difference(ts) < _gridTtl) {
        Logger.debug(
            'Grid TTL cache hit for ${category.displayName} @ $cellLat,$cellLng');
        return _gridCache[gridKey] ?? [];
      }
    }

    // Verifică cache persistent pe disc (OfflineManager)
    try {
      final diskKey = 'poi_$gridKey';
      final cachedJson = await OfflineManager().getSearchCacheCell(diskKey);
      if (cachedJson != null) {
        final List<dynamic> list = json.decode(cachedJson) as List<dynamic>;
        final pois = list
            .whereType<Map<String, dynamic>>()
            .map(_poiFromDiskJson)
            .toList();
        _saveToGridCache(gridKey, pois);
        Logger.debug(
            'Disk cache hit for ${category.displayName} @ $cellLat,$cellLng');
        return pois;
      }
    } catch (e) {
      Logger.error('Disk cache read failed: $e', error: e);
    }

    Logger.debug('Fetching ${category.displayName} from Mapbox API...');

    // Dacă există o cerere în desfășurare, coalesce
    final inflight = _inflightFetches[cacheKey];
    if (inflight != null) {
      Logger.debug('⏳ Coalescing in-flight fetch for ${category.displayName}');
      return await inflight;
    }

    final Future<List<PointOfInterest>> future = (() async {
      final url = Uri.parse('$_baseUrl/${category.mapboxType}.json').replace(
        queryParameters: {
          'access_token': _accessToken,
          'proximity': '$longitude,$latitude',
          'bbox': _calculateBbox(latitude, longitude, radiusKm),
          'limit': '25',
          'language': 'ro',
          'types': 'poi',
        },
      );

      final response = await _httpGetWithRetry(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>;

        final pois = features
            .map((feature) => PointOfInterest.fromMapboxFeature(
                feature as Map<String, dynamic>))
            .toList();

        // Salvează în cache (cheie fină) și în grid cache (cheie celulă)
        _saveToCache(cacheKey, pois);
        _saveToGridCache(gridKey, pois);
        // Persistă pe disc
        try {
          final diskKey = 'poi_$gridKey';
          final jsonList = pois.map(_poiToDiskJson).toList();
          await OfflineManager().saveSearchCacheCell(
            key: diskKey,
            jsonData: json.encode(jsonList),
          );
        } catch (e) {
          Logger.error('Disk cache write failed: $e', error: e);
        }

        Logger.info('Loaded ${pois.length} ${category.displayName}');
        return pois;
      } else {
        Logger.error(
            'Mapbox API error ${response.statusCode}: ${response.body}');
        return <PointOfInterest>[];
      }
    })();

    _inflightFetches[cacheKey] = future;
    try {
      return await future;
    } catch (e) {
      Logger.error('Error fetching ${category.displayName}: $e', error: e);
      return [];
    } finally {
      _inflightFetches.remove(cacheKey);
    }
  }

  // Retry helper pentru HTTP GET cu backoff și jitter
  Future<http.Response> _httpGetWithRetry(Uri url, {int maxRetries = 3}) async {
    int attempt = 0;
    while (true) {
      try {
        final resp = await http.get(url);
        return resp;
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        final backoff = 250 * attempt + math.Random().nextInt(200);
        await Future.delayed(Duration(milliseconds: backoff));
      }
    }
  }

  /// Calculează bounding box pentru o rază dată
  String _calculateBbox(double lat, double lng, double radiusKm) {
    const double earthRadius = 6371.0; // km
    final double latRad = lat * (math.pi / 180);

    final double deltaLat = radiusKm / earthRadius * (180 / math.pi);
    final double deltaLng =
        radiusKm / earthRadius * (180 / math.pi) / math.cos(latRad);

    final double minLat = lat - deltaLat;
    final double maxLat = lat + deltaLat;
    final double minLng = lng - deltaLng;
    final double maxLng = lng + deltaLng;

    return '$minLng,$minLat,$maxLng,$maxLat';
  }

  // =================
  // CACHE MANAGEMENT
  // =================

  /// Verifică dacă cache-ul este valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  /// Salvează în cache cu management de mărime
  void _saveToCache(String key, List<PointOfInterest> pois) {
    // Limitează mărimea cache-ului
    if (_cache.length >= _maxCacheSize) {
      _evictOldestCacheEntry();
    }

    _cache[key] = pois;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Salvează în grid cache cu TTL și limită de capacitate
  void _saveToGridCache(String gridKey, List<PointOfInterest> pois) {
    // Limitează mărimea grid cache-ului
    if (_gridCache.length >= _gridMaxEntries) {
      _evictOldestGridEntry();
    }
    _gridCache[gridKey] = pois;
    _gridCacheTimestamps[gridKey] = DateTime.now();
  }

  void _evictOldestGridEntry() {
    if (_gridCacheTimestamps.isEmpty) return;
    String? oldestKey;
    DateTime? oldestTime;
    for (final entry in _gridCacheTimestamps.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestKey = entry.key;
      }
    }
    if (oldestKey != null) {
      _gridCache.remove(oldestKey);
      _gridCacheTimestamps.remove(oldestKey);
    }
  }

  // ===== Serialization helpers for disk cache =====
  Map<String, dynamic> _poiToDiskJson(PointOfInterest p) {
    return {
      'id': p.id,
      'name': p.name,
      'description': p.description,
      'imageUrl': p.imageUrl,
      'lat': p.location.latitude,
      'lng': p.location.longitude,
      'category': p.category.name,
      'isStatic': p.isStatic,
      'additionalInfo': p.additionalInfo,
    };
  }

  PointOfInterest _poiFromDiskJson(Map<String, dynamic> m) {
    final catName = (m['category'] as String?) ?? 'other';
    final category = PoiCategory.values.firstWhere(
      (c) => c.name == catName,
      orElse: () => PoiCategory.other,
    );
    return PointOfInterest(
      id: (m['id'] ?? 'poi_${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      name: (m['name'] ?? 'POI').toString(),
      description: (m['description'] ?? '').toString(),
      imageUrl: (m['imageUrl'] ?? '').toString(),
      location: Position(
        latitude: (m['lat'] as num).toDouble(),
        longitude: (m['lng'] as num).toDouble(),
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
      category: category,
      isStatic: (m['isStatic'] as bool?) ?? false,
      additionalInfo: (m['additionalInfo'] as Map<String, dynamic>?),
    );
  }

  /// Elimină cea mai veche intrare din cache
  void _evictOldestCacheEntry() {
    if (_cacheTimestamps.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cacheTimestamps.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
  }

  /// Șterge întregul cache
  void _clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    Logger.debug('POI cache cleared');
  }

  /// Cleanup la dispose
  void dispose() {
    _clearCache();
  }

  // =================
  // LOCAL ASSETS LOADERS (GeoJSON / GPX / KML)
  // =================

  Future<void> loadLocalGeoJsonFromAsset(String assetPath) async {
    if (_geojsonLoaded) return;
    try {
      final content = await rootBundle.loadString(assetPath);
      // CPU-heavy: json + ~4k features — run on worker isolate to avoid janking the UI thread.
      final rows = await compute(parseLocalGeoJsonForWorker, content);
      final ts = DateTime.now();
      for (final row in rows) {
        final categoryName = row['categoryName'] as String;
        PoiCategory poiCategory;
        try {
          poiCategory = PoiCategory.values.byName(categoryName);
        } catch (_) {
          poiCategory = PoiCategory.other;
        }
        final name = row['name'] as String;
        final lat = (row['lat'] as num).toDouble();
        final lng = (row['lng'] as num).toDouble();
        final rawInfo = row['additionalInfo'];
        final additionalInfo = rawInfo is Map
            ? Map<String, dynamic>.from(rawInfo)
            : <String, dynamic>{};

        final poi = PointOfInterest(
          id: row['id'] as String,
          name: name,
          description: row['description'] as String,
          imageUrl: _generateImageUrl(poiCategory, name),
          location: Position(
            latitude: lat,
            longitude: lng,
            timestamp: ts,
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ),
          category: poiCategory,
          isStatic: true,
          additionalInfo: additionalInfo,
        );

        _localPois.add(poi);
      }

      _geojsonLoaded = true;
      Logger.info('Loaded local GeoJSON POIs: ${_localPois.length}');
    } catch (e) {
      Logger.error('Failed to load local GeoJSON ($assetPath): $e', error: e);
    }
  }

  Future<void> loadLocalGpxFromAsset(String assetPath) async {
    if (_gpxLoaded) return;
    try {
      final content = await rootBundle.loadString(assetPath);
      final wptExp = RegExp(
          r'<wpt[^>]*lat="([^"]+)"[^>]*lon="([^"]+)"[^>]*>([\s\S]*?)<\/wpt>',
          multiLine: true);
      final nameExp = RegExp(r'<name>([\s\S]*?)<\/name>');

      final matches = wptExp.allMatches(content);
      int i = 0;
      for (final m in matches) {
        i++;
        final latStr = m.group(1);
        final lonStr = m.group(2);
        final body = m.group(3) ?? '';
        if (latStr == null || lonStr == null) continue;
        final lat = double.tryParse(latStr);
        final lng = double.tryParse(lonStr);
        if (lat == null || lng == null) continue;

        final nameMatch = nameExp.firstMatch(body);
        final name = nameMatch?.group(1)?.trim() ?? 'POI';

        // Try to parse common key=value pairs from GPX <desc>
        final Map<String, String> kv = {};
        for (final line in body.split(RegExp(r'[\r\n]+'))) {
          final idx = line.indexOf('=');
          if (idx > 0) {
            final key = line.substring(0, idx).trim();
            final val = line.substring(idx + 1).trim();
            if (key.isNotEmpty && val.isNotEmpty) kv[key] = val;
          }
        }

        final poi = PointOfInterest(
          id: 'local_gpx_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: name.isEmpty ? 'POI' : name,
          description: kv['addr:street'] != null
              ? '${kv['addr:street']}${kv['addr:housenumber'] != null ? ' ${kv['addr:housenumber']}' : ''}${kv['addr:city'] != null ? ', ${kv['addr:city']}' : ''}'
              : 'Punct din GPX',
          imageUrl: _generateImageUrl(PoiCategory.tourism, name),
          location: Position(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ),
          category: PoiCategory.tourism,
          isStatic: true,
          additionalInfo: {
            if (kv.containsKey('amenity')) 'amenity': kv['amenity'],
            if (kv.containsKey('tourism')) 'tourism': kv['tourism'],
            if (kv.containsKey('shop')) 'shop': kv['shop'],
            if (kv.containsKey('addr:street')) 'addr:street': kv['addr:street'],
            if (kv.containsKey('addr:housenumber'))
              'addr:housenumber': kv['addr:housenumber'],
            if (kv.containsKey('addr:city')) 'addr:city': kv['addr:city'],
            if (kv.containsKey('brand')) 'brand': kv['brand'],
            if (kv.containsKey('operator')) 'operator': kv['operator'],
            if (kv.containsKey('phone')) 'phone': kv['phone'],
            if (kv.containsKey('website')) 'website': kv['website'],
            if (kv.containsKey('opening_hours'))
              'opening_hours': kv['opening_hours'],
          },
        );

        _localPois.add(poi);
      }

      _gpxLoaded = true;
      Logger.info('Loaded local GPX POIs: ${_localPois.length}');
    } catch (e) {
      Logger.error('Failed to load local GPX ($assetPath): $e', error: e);
    }
  }

  Future<void> loadLocalKmlFromAsset(String assetPath) async {
    if (_kmlLoaded) return;
    try {
      final content = await rootBundle.loadString(assetPath);
      // Very light-weight parsing of Placemark Points
      final placemarkExp = RegExp(
          r'<Placemark[\s\S]*?<name>([\s\S]*?)<\/name>[\s\S]*?<Point>[\s\S]*?<coordinates>([\s\S]*?)<\/coordinates>[\s\S]*?<\/Point>[\s\S]*?<\/Placemark>',
          multiLine: true);
      final matches = placemarkExp.allMatches(content);
      int i = 0;
      for (final m in matches) {
        i++;
        final name = (m.group(1) ?? 'POI').trim();
        final coords = (m.group(2) ?? '').trim();
        final placemarkXml = (m.group(0) ?? '');
        if (coords.isEmpty) continue;
        // coordinates: "lon,lat,alt" possibly multiple tuples separated by space/newline
        final firstTuple = coords
            .split(RegExp(r'\s+'))
            .firstWhere((e) => e.contains(','), orElse: () => '');
        if (firstTuple.isEmpty) continue;
        final parts = firstTuple.split(',');
        if (parts.length < 2) continue;
        final lng = double.tryParse(parts[0]);
        final lat = double.tryParse(parts[1]);
        if (lat == null || lng == null) continue;

        // Parse a few ExtendedData fields if present
        String? street;
        String? number;
        String? city;
        String? brand;
        String? operatorName;
        String? phone;
        String? website;
        String? openingHours;
        String? amenity;
        String? tourism;
        String? shop;

        String? extractField(String key) {
          final r = RegExp(
              '<Data name="${RegExp.escape(key)}"><value>([\\s\\S]*?)<\\/value><\\/Data>');
          final match = r.firstMatch(placemarkXml);
          return match?.group(1)?.trim();
        }

        street = extractField('addr:street');
        number = extractField('addr:housenumber');
        city = extractField('addr:city');
        brand = extractField('brand');
        operatorName = extractField('operator');
        phone = extractField('phone');
        website = extractField('website');
        openingHours = extractField('opening_hours');
        amenity = extractField('amenity');
        tourism = extractField('tourism');
        shop = extractField('shop');

        final poi = PointOfInterest(
          id: 'local_kml_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: name.isEmpty ? 'POI' : name,
          description: street != null
              ? '$street${number != null ? ' $number' : ''}${city != null ? ', $city' : ''}'
              : 'Punct din KML',
          imageUrl: _generateImageUrl(PoiCategory.tourism, name),
          location: Position(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ),
          category: PoiCategory.tourism,
          isStatic: true,
          additionalInfo: {
            if (amenity != null) 'amenity': amenity,
            if (tourism != null) 'tourism': tourism,
            if (shop != null) 'shop': shop,
            if (street != null) 'addr:street': street,
            if (number != null) 'addr:housenumber': number,
            if (city != null) 'addr:city': city,
            if (brand != null) 'brand': brand,
            if (operatorName != null) 'operator': operatorName,
            if (phone != null) 'phone': phone,
            if (website != null) 'website': website,
            if (openingHours != null) 'opening_hours': openingHours,
          },
        );

        _localPois.add(poi);
      }

      _kmlLoaded = true;
      Logger.info('Loaded local KML POIs: ${_localPois.length}');
    } catch (e) {
      Logger.error('Failed to load local KML ($assetPath): $e', error: e);
    }
  }

  // =================
  // HELPERS
  // =================

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000.0; // meters
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  String _generateImageUrl(PoiCategory category, String name) {
    final encodedName = Uri.encodeComponent(name.isEmpty ? 'POI' : name);
    // Neutral placeholder; card components may display this if needed
    return 'https://placehold.co/600x400/9E9E9E/FFFFFF?text=${category.emoji}+$encodedName';
  }

  // Removed duplicate implementation

  /// Fetch POIs from Mapbox Searchbox Category API in proximity of [center] within [radiusKm].
  Future<List<PointOfInterest>> fetchPoisFromApi(
    Map<String, double> center,
    PoiCategory category, {
    double radiusKm = 3.0,
  }) async {
    final String accessToken = MapboxConfig.getAccessToken();
    final String categoryKey = category.mapboxType;
    final double lat = center['latitude']!;
    final double lng = center['longitude']!;

    final uri = Uri.https(
      'api.mapbox.com',
      '/search/searchbox/v1/category/$categoryKey',
      <String, String>{
        'access_token': accessToken,
        'proximity': '$lng,$lat',
        'bbox': _calculateBbox(lat, lng, radiusKm),
        'limit': '25',
        'language': 'ro',
      },
    );

    return _fetchSearchWithRetry(uri);
  }
}

// =============================
// Isolate helpers for POI sorting
// =============================

// Compute-friendly function: sorts coordinates by distance to user and returns top N indices.
// args map must contain:
// - 'coords': List<List<double>> where each item is [lat, lng]
// - 'userLat': double
// - 'userLng': double
// - 'cap': int (optional)
List<int> poiSortByDistanceIndicesCompute(Map<String, dynamic> args) {
  final List<dynamic> rawCoords =
      (args['coords'] as List<dynamic>?) ?? const [];
  final double userLat = (args['userLat'] as num).toDouble();
  final double userLng = (args['userLng'] as num).toDouble();
  final int cap = args['cap'] is int ? (args['cap'] as int) : rawCoords.length;

  final int n = rawCoords.length;
  if (n == 0) return const [];

  const double earthRadius = 6371000.0; // meters
  double haversine(double lat1, double lon1, double lat2, double lon2) {
    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLon = (lon2 - lon1) * (math.pi / 180);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  final List<_IdxDist> distances = List<_IdxDist>.generate(n, (int index) {
    final List<dynamic> pair = (rawCoords[index] as List<dynamic>);
    final double lat = (pair[0] as num).toDouble();
    final double lng = (pair[1] as num).toDouble();
    final double d = haversine(userLat, userLng, lat, lng);
    return _IdxDist(index: index, distance: d);
  }, growable: false);

  distances.sort((a, b) => a.distance.compareTo(b.distance));

  final int take = cap < distances.length ? cap : distances.length;
  final List<int> result =
      List<int>.generate(take, (i) => distances[i].index, growable: false);
  return result;
}

class _IdxDist {
  final int index;
  final double distance;
  const _IdxDist({required this.index, required this.distance});
}

PointOfInterest? _poiFromSearchboxFeature(Map<String, dynamic> feature) {
  // Searchbox shape may differ from Places; handle robustly
  final geometry = feature['geometry'] as Map<String, dynamic>?;
  final properties = feature['properties'] as Map<String, dynamic>?;
  if (geometry == null) return null;
  final coords = (geometry['coordinates'] as List?) ?? const [];
  if (coords.length < 2) return null;

  final double lng = (coords[0] as num).toDouble();
  final double lat = (coords[1] as num).toDouble();
  final String address =
      (properties?['full_address'] ?? properties?['place_formatted'] ?? '')
          .toString();
  // Nu folosi adresa completă ca titlu: apare ca „poză” doar textul din placeholder și pare defect UI.
  final String rawTitle = (feature['name'] ?? properties?['name'] ?? '')
      .toString()
      .trim();
  final String name = rawTitle.isNotEmpty
      ? rawTitle
      : (address.isNotEmpty ? 'Loc din zonă' : 'POI');
  final String id = (feature['id'] ??
          properties?['mapbox_id'] ??
          'poi_${DateTime.now().millisecondsSinceEpoch}')
      .toString();

  // Category hint from properties if available; fallback to requested type
  final String cat =
      (properties?['category'] ?? categoryFromProperties(properties))
          .toString();
  final PoiCategory poiCategory =
      PoiCategoryExtension.mapboxTypeToCategory(cat);

  return PointOfInterest(
    id: id,
    name: name,
    description:
        address.isNotEmpty ? address : 'Locație din ${poiCategory.displayName}',
    imageUrl: PoiCategoryExtension.generateImageUrl(poiCategory, name),
    location: Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
    category: poiCategory,
    additionalInfo: {
      'place_formatted': properties?['place_formatted'],
      'maki': properties?['maki'],
      'distance': properties?['distance'],
      'metadata': feature['metadata'],
    },
  );
}

String categoryFromProperties(Map<String, dynamic>? properties) {
  if (properties == null) return '';
  final c = properties['category'];
  if (c is String && c.isNotEmpty) return c;
  final types = properties['types'];
  if (types is List && types.isNotEmpty) return types.first.toString();
  return '';
}

Future<List<PointOfInterest>> _fetchSearchWithRetry(Uri uri) async {
  const int maxRetries = 3;
  int attempt = 0;
  while (true) {
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> features =
            (data['features'] as List<dynamic>?) ?? const [];
        final List<PointOfInterest> pois = <PointOfInterest>[];
        for (final f in features) {
          if (f is! Map<String, dynamic>) continue;
          final poi = _poiFromSearchboxFeature(f);
          if (poi != null) pois.add(poi);
        }
        return pois;
      } else {
        Logger.error(
            'Search API error ${response.statusCode}: ${response.body}');
        throw Exception('Search API error ${response.statusCode}');
      }
    } catch (e) {
      attempt++;
      if (attempt >= maxRetries) rethrow;
      final backoffMs = 300 * attempt + (math.Random().nextInt(200));
      await Future.delayed(Duration(milliseconds: backoffMs));
    }
  }
}
