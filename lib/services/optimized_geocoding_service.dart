import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🚀 Serviciu de geocoding optimizat pentru performanță maximă
/// Implementează cache inteligent, debouncing și multiple surse de date
class OptimizedGeocodingService {
  static const String _userAgent = 'Nabour/1.0';
  static const int _maxCacheSize = 500;
  
  // Cache inteligent cu expirare
  final Map<String, CacheEntry> _cache = {};
  
  // Statistici de performanță
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _totalRequests = 0;
  int _totalResponseTime = 0;

  /// 📍 Caută adrese cu performanță optimizată
  Future<List<AddressSuggestion>> searchAddresses({
    required String query,
    required geolocator.Position userPosition,
    bool useCache = true,
    int maxResults = 8,
  }) async {
    if (query.trim().length < 2) {
      return [];
    }

    _totalRequests++;
    final stopwatch = Stopwatch()..start();

    try {
      final normalizedQuery = _normalizeQuery(query);
      
      // 1. Verifică cache-ul mai întâi — cache hit nu consumă tokeni
      if (useCache && _cache.containsKey(normalizedQuery)) {
        final cacheEntry = _cache[normalizedQuery]!;
        if (!cacheEntry.isExpired) {
          _cacheHits++;
          stopwatch.stop();
          _totalResponseTime += stopwatch.elapsedMilliseconds;

          Logger.debug(
            '[GEOCODING] Cache hit: ${stopwatch.elapsedMilliseconds}ms',
            tag: 'GEOCODING',
          );
          return cacheEntry.suggestions.take(maxResults).toList();
        } else {
          // Cache expirat, șterge-l
          _cache.remove(normalizedQuery);
        }
      }

      _cacheMisses++;

      // 2. Deducere tokeni pentru geocoding (request real, nu cache)
      await TokenService().spend(
        TokenTransactionType.geocoding,
        customDescription: 'Căutare adresă: $query',
      );

      // 3. Caută în multiple surse în paralel
      final results = await _searchMultipleSources(
        normalizedQuery,
        userPosition,
        maxResults,
      );

      // 4. Procesează și sortează rezultatele
      final processedResults = _processAndSortResults(results, query, userPosition);
      final limitedResults = processedResults.take(maxResults).toList();

      // 5. Salvează în cache
      if (useCache && limitedResults.isNotEmpty) {
        _cacheResult(normalizedQuery, limitedResults);
      }

      stopwatch.stop();
      _totalResponseTime += stopwatch.elapsedMilliseconds;
      
      Logger.debug(
        '[GEOCODING] Search completed: ${stopwatch.elapsedMilliseconds}ms — ${limitedResults.length} results',
        tag: 'GEOCODING',
      );
      
      return limitedResults;

    } catch (e) {
      stopwatch.stop();
      _totalResponseTime += stopwatch.elapsedMilliseconds;
      Logger.warning('[GEOCODING] Error: $e', tag: 'GEOCODING');
      return [];
    }
  }

  /// 🔍 Caută în multiple surse în paralel pentru performanță maximă
  Future<List<AddressSuggestion>> _searchMultipleSources(
    String query,
    geolocator.Position userPosition,
    int maxResults,
  ) async {
    final List<Future<List<AddressSuggestion>>> futures = [];

    // 1. Nominatim optimizat (prioritate maximă)
    futures.add(_searchNominatimOptimized(query, userPosition));
    
    // 2. Nominatim standard (fallback)
    futures.add(_searchNominatimStandard(query, userPosition));

    // 3. Cache local de adrese București (ultra-rapid)
    futures.add(_searchLocalBucharestCache(query, userPosition));

    try {
      // Așteaptă primul rezultat sau toate dacă sunt sub 500ms
      final results = await Future.wait(
        futures.map((f) => f.timeout(const Duration(milliseconds: 500), onTimeout: () => <AddressSuggestion>[])),
      );

      // Combină rezultatele și elimină duplicatele
      final allResults = <AddressSuggestion>[];
      for (final result in results) {
        allResults.addAll(result);
      }

      return _deduplicateResults(allResults);
    } catch (e) {
      Logger.warning('[GEOCODING] Multi-source search error: $e', tag: 'GEOCODING');
      return [];
    }
  }

  /// ⚡ Nominatim optimizat cu parametri pentru București
  Future<List<AddressSuggestion>> _searchNominatimOptimized(
    String query,
    geolocator.Position userPosition,
  ) async {
    try {
      final distanceToBucharest = geolocator.Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        44.4268,
        26.1025,
      );

      final bool nearBucharest = distanceToBucharest < 50000; // 50km
      final String contextualQuery = nearBucharest
          ? '$query, București, România'
          : '$query, România';

      final Map<String, String> params = {
        'q': contextualQuery,
        'format': 'json',
        'addressdetails': '1',
        'limit': '15',
        'countrycodes': 'ro',
        'dedupe': '1',
      };

      // Viewbox pentru București pentru rezultate mai relevante
      if (nearBucharest) {
        params['bounded'] = '1';
        params['viewbox'] = '25.9,44.7,26.4,44.2';
      }

      final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, deflate',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return _parseNominatimResults(data, query, userPosition);
      }

      return [];
    } catch (e) {
      Logger.warning('[GEOCODING] Nominatim optimized error: $e', tag: 'GEOCODING');
      return [];
    }
  }

  /// 🌍 Nominatim standard (fallback)
  Future<List<AddressSuggestion>> _searchNominatimStandard(
    String query,
    geolocator.Position userPosition,
  ) async {
    try {
      final params = {
        'q': '$query, România',
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
        'countrycodes': 'ro',
      };

      final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return _parseNominatimResults(data, query, userPosition);
      }

      return [];
    } catch (e) {
      Logger.warning('[GEOCODING] Nominatim standard error: $e', tag: 'GEOCODING');
      return [];
    }
  }

  /// 🏠 Cache local pentru adrese populare din București
  Future<List<AddressSuggestion>> _searchLocalBucharestCache(
    String query,
    geolocator.Position userPosition,
  ) async {
    final bucharestLocations = _getBucharestLocations();
    final queryLower = query.toLowerCase();
    
    final matches = bucharestLocations.entries
        .where((entry) => entry.key.toLowerCase().contains(queryLower) || 
                         queryLower.contains(entry.key.toLowerCase()))
        .map((entry) => AddressSuggestion(
          description: entry.value['description'],
          latitude: entry.value['lat'],
          longitude: entry.value['lng'],
          score: 100, // Scor maxim pentru cache local
          distanceMeters: geolocator.Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            entry.value['lat'],
            entry.value['lng'],
          ),
        ))
        .toList();

    return matches;
  }

  /// 📍 Cache local cu locații populare din București
  Map<String, Map<String, dynamic>> _getBucharestLocations() {
    return {
      'Piata Unirii': {
        'description': 'Piața Unirii, București',
        'lat': 44.4268,
        'lng': 26.1025,
      },
      'Gara de Nord': {
        'description': 'Gara de Nord, București',
        'lat': 44.4479,
        'lng': 26.0759,
      },
      'Aeroport': {
        'description': 'Aeroportul Henri Coandă, Otopeni',
        'lat': 44.5711,
        'lng': 26.0858,
      },
      'Mall Baneasa': {
        'description': 'Mall Băneasa, București',
        'lat': 44.5022,
        'lng': 26.0778,
      },
      'Universitate': {
        'description': 'Piața Universității, București',
        'lat': 44.4355,
        'lng': 26.1025,
      },
      'Piata Victoriei': {
        'description': 'Piața Victoriei, București',
        'lat': 44.4532,
        'lng': 26.0849,
      },
      'Herastrau': {
        'description': 'Parcul Herăstrău, București',
        'lat': 44.4734,
        'lng': 26.0778,
      },
      'Therme': {
        'description': 'Therme București, Voluntari',
        'lat': 44.5200,
        'lng': 26.1300,
      },
      'AFI Cotroceni': {
        'description': 'AFI Cotroceni, București',
        'lat': 44.4333,
        'lng': 26.0667,
      },
      'Promenada': {
        'description': 'Promenada Mall, București',
        'lat': 44.4500,
        'lng': 26.1000,
      },
      'Mega Mall': {
        'description': 'Mega Mall, București',
        'lat': 44.4167,
        'lng': 26.1167,
      },
      'Sun Plaza': {
        'description': 'Sun Plaza, București',
        'lat': 44.4833,
        'lng': 26.0833,
      },
    };
  }

  /// 🔄 Elimină rezultatele duplicate
  List<AddressSuggestion> _deduplicateResults(List<AddressSuggestion> results) {
    final Map<String, AddressSuggestion> uniqueResults = {};
    
    for (final result in results) {
      final key = '${result.latitude.toStringAsFixed(4)}_${result.longitude.toStringAsFixed(4)}';
      
      if (!uniqueResults.containsKey(key) || 
          (uniqueResults[key]?.score ?? 0) < result.score) {
        uniqueResults[key] = result;
      }
    }
    
    return uniqueResults.values.toList();
  }

  /// 🎯 Procesează și sortează rezultatele
  List<AddressSuggestion> _processAndSortResults(
    List<AddressSuggestion> results,
    String originalQuery,
    geolocator.Position userPosition,
  ) {
    // Adaugă scoruri și distanțe
    for (final result in results) {
      result.distanceMeters = geolocator.Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        result.latitude,
        result.longitude,
      );
      
      // Calculează scorul bazat pe relevanță
      result.score = _calculateRelevanceScore(result, originalQuery, userPosition);
    }

    // Sortează după scor și distanță
    results.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) return scoreComparison;
      
      return (a.distanceMeters ?? double.infinity)
          .compareTo(b.distanceMeters ?? double.infinity);
    });

    return results;
  }

  /// 📊 Calculează scorul de relevanță
  int _calculateRelevanceScore(
    AddressSuggestion suggestion,
    String query,
    geolocator.Position userPosition,
  ) {
    int score = 0;
    final queryLower = query.toLowerCase();
    final descLower = suggestion.description.toLowerCase();
    
    // Scor bazat pe potrivirea textului
    final queryWords = queryLower.split(' ').where((w) => w.isNotEmpty).toList();
    for (final word in queryWords) {
      if (descLower.contains(word)) {
        score += word.length > 3 ? 15 : 8;
      }
    }
    
    // Bonus pentru București
    if (descLower.contains('bucurești') || descLower.contains('bucharest')) {
      score += 25;
    }
    
    // Bonus pentru locații populare
    final popularLocations = _getBucharestLocations();
    for (final entry in popularLocations.entries) {
      if (descLower.contains(entry.key.toLowerCase()) ||
          queryLower.contains(entry.key.toLowerCase())) {
        score += 30;
        break;
      }
    }
    
    // Penalizare pentru distanță mare
    final distance = suggestion.distanceMeters ?? 0;
    if (distance > 50000) { // 50km
      score -= 20;
    } else if (distance > 20000) { // 20km
      score -= 10;
    }
    
    return score.clamp(0, 100);
  }

  /// 💾 Salvează rezultatul în cache
  void _cacheResult(String query, List<AddressSuggestion> suggestions) {
    // Limitează dimensiunea cache-ului
    if (_cache.length >= _maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    
    _cache[query] = CacheEntry(
      suggestions: suggestions,
      timestamp: DateTime.now(),
    );
  }

  /// 🔧 Normalizează interogarea
  String _normalizeQuery(String query) {
    String normalized = query.toLowerCase().trim();
    
    // Normalizează diacriticele
    normalized = normalized
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ș', 's')
        .replaceAll('ş', 's')
        .replaceAll('ț', 't')
        .replaceAll('ţ', 't');

    // Normalizează abrevierile
    final abbreviations = {
      r'\bsos\b': 'soseaua',
      r'\bstr\b': 'strada',
      r'\bstrada\b': 'strada',
      r'\bbd\b': 'bulevardul',
      r'\bbul\b': 'bulevardul',
      r'\bpiata\b': 'piata',
      r'\bpl\b': 'piata',
      r'\bcalea\b': 'calea',
      r'\bnr\b': 'numarul',
      r'\bbl\b': 'blocul',
    };

    abbreviations.forEach((pattern, replacement) {
      normalized = normalized.replaceAll(RegExp(pattern), replacement);
    });

    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// 📋 Parsează rezultatele Nominatim
  List<AddressSuggestion> _parseNominatimResults(
    List<dynamic> data,
    String originalQuery,
    geolocator.Position userPosition,
  ) {
    final List<AddressSuggestion> suggestions = [];

    for (final item in data) {
      final Map<String, dynamic> m = item as Map<String, dynamic>;
      final String displayName = (m['display_name'] as String?) ?? '';
      final double lat = double.tryParse((m['lat'] ?? '').toString()) ?? 0.0;
      final double lon = double.tryParse((m['lon'] ?? '').toString()) ?? 0.0;
      
      if (lat == 0.0 && lon == 0.0) continue;

      suggestions.add(AddressSuggestion(
        description: _formatAddressDisplay(displayName),
        latitude: lat,
        longitude: lon,
      ));
    }

    return suggestions;
  }

  /// 🎨 Formatează afișarea adresei
  String _formatAddressDisplay(String displayName) {
    final List<String> parts = displayName.split(', ');
    if (parts.length >= 2) {
      return '${parts[0]}, ${parts[1]}';
    }
    return displayName;
  }

  /// 📊 Obține statisticile de performanță
  Map<String, dynamic> getPerformanceStats() {
    final avgResponseTime = _totalRequests > 0 ? _totalResponseTime / _totalRequests : 0;
    final cacheHitRate = _totalRequests > 0 ? (_cacheHits / (_cacheHits + _cacheMisses)) * 100 : 0;
    
    return {
      'total_requests': _totalRequests,
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'cache_hit_rate': cacheHitRate.toStringAsFixed(1),
      'avg_response_time': avgResponseTime.toStringAsFixed(0),
      'cache_size': _cache.length,
    };
  }

  /// 🧹 Curăță cache-ul expirat
  void cleanExpiredCache() {
    _cache.removeWhere((key, entry) => entry.isExpired);
    Logger.debug('[GEOCODING] Cleaned expired cache entries', tag: 'GEOCODING');
  }

  /// 🗑️ Șterge tot cache-ul
  void clearCache() {
    _cache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    Logger.debug('[GEOCODING] Cache cleared', tag: 'GEOCODING');
  }
}

/// 📦 Intrare în cache cu expirare
class CacheEntry {
  final List<AddressSuggestion> suggestions;
  final DateTime timestamp;
  static const Duration _expiry = Duration(hours: 24);

  CacheEntry({
    required this.suggestions,
    required this.timestamp,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > _expiry;
}

/// 📍 Sugestie adresă cu coordonate și distanță
class AddressSuggestion {
  final String description;
  final double latitude;
  final double longitude;
  int score;
  double? distanceMeters;
  final String? mapboxId;

  AddressSuggestion({
    required this.description,
    required this.latitude,
    required this.longitude,
    this.score = 0,
    this.distanceMeters,
    this.mapboxId,
  });
}
