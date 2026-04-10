
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/models/saved_address_model.dart';

// Sugestie adresă cu coordonate și distanță (pentru afișare rapidă și selectare fără geocodificare suplimentară)
class AddressSuggestion {
  final String description;
  final double latitude;
  final double longitude;
  final int score;
  double? distanceMeters;
  final String? mapboxId; // optional, retained for compatibility

  AddressSuggestion({
    required this.description,
    required this.latitude,
    required this.longitude,
    this.score = 0,
    this.distanceMeters,
    this.mapboxId,
  });
}

/// Normalizare text pentru potrivirea căutării cu adrese salvate (favorite).
String normalizeRomanianTextForSearch(String text) {
  final lower = text.toLowerCase();
  var s = lower
      .replaceAll(String.fromCharCode(0x0103), 'a')
      .replaceAll(String.fromCharCode(0x00e2), 'a')
      .replaceAll(String.fromCharCode(0x00ee), 'i')
      .replaceAll(String.fromCharCode(0x0219), 's')
      .replaceAll(String.fromCharCode(0x015f), 's')
      .replaceAll(String.fromCharCode(0x021b), 't')
      .replaceAll(String.fromCharCode(0x0163), 't');
  final tChar = String.fromCharCode(0x021b);
  s = s
      .replaceAll(RegExp(r'^\s*sos\b'), 'soseaua')
      .replaceAll(RegExp(r'\bstr\.?\b'), 'strada')
      .replaceAll(RegExp(r'\bbd\.?\b'), 'bulevardul')
      .replaceAll(RegExp(r'\bbl\.?\b'), 'blocul')
      .replaceAll(RegExp(r'\bnr\b'), 'numarul')
      .replaceAll(RegExp(r'\bet\b'), 'etajul')
      .replaceAll(RegExp(r'\bap\b'), 'apartamentul')
      .replaceAll(RegExp('p${tChar}a|piata'), 'piata');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

double searchMatchScoreNormalized(String queryNorm, String candidateNorm) {
  if (queryNorm.isEmpty) return 0;
  if (candidateNorm.contains(queryNorm)) return 3.0;
  final dist = _levenshteinForSavedSearch(candidateNorm, queryNorm);
  final maxLen = candidateNorm.length.clamp(queryNorm.length, 50);
  final ratio = 1.0 - (dist / maxLen);
  return ratio >= 0.7 ? ratio : 0.0;
}

double savedAddressMatchScoreNormalized(String queryNorm, SavedAddress addr) {
  final sl = searchMatchScoreNormalized(
    queryNorm,
    normalizeRomanianTextForSearch(addr.label),
  );
  final sa = searchMatchScoreNormalized(
    queryNorm,
    normalizeRomanianTextForSearch(addr.address),
  );
  return sl > sa ? sl : sa;
}

String savedAddressDisplayLine(SavedAddress addr) {
  final t = addr.label.trim();
  final cat = addr.category == SavedAddressCategory.other
      ? ''
      : '${addr.category.labelRo} · ';
  if (t.isEmpty) return '$cat${addr.address}'.trim();
  return '$cat$t · ${addr.address}';
}

int _levenshteinForSavedSearch(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;
  final v0 = List<int>.generate(t.length + 1, (i) => i);
  final v1 = List<int>.filled(t.length + 1, 0);
  for (int i = 0; i < s.length; i++) {
    v1[0] = i + 1;
    for (int j = 0; j < t.length; j++) {
      final cost = s[i] == t[j] ? 0 : 1;
      v1[j + 1] = [
        v1[j] + 1,
        v0[j + 1] + 1,
        v0[j] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
    for (int j = 0; j < v0.length; j++) {
      v0[j] = v1[j];
    }
  }
  return v1[t.length];
}

class GeocodingService {
  // ✅ CACHE PENTRU GEOCODING
  final Map<String, _CachedGeocodeResult> _geocodeCache = {};
  static const Duration _cacheExpiry = Duration(hours: 24);
  
  // Sugestii OSM Nominatim (autocomplete-like) cu normalizare română și scorare
  Future<List<AddressSuggestion>> fetchSuggestions(String query, geolocator.Position currentUserPosition) async {
    if (query.trim().length < 2) {
      return [];
    }

    // ✅ VERIFICĂ CACHE
    final cacheKey = query.toLowerCase().trim();
    final cached = _geocodeCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      Logger.debug('GeocodingService: Cache hit for: $query');
      return cached.suggestions;
    }

    // ✅ RETRY LOGIC cu exponential backoff
    return await _fetchSuggestionsWithRetry(query, currentUserPosition, cacheKey);
  }
  
  // ✅ NOU: Fetch cu retry logic
  Future<List<AddressSuggestion>> _fetchSuggestionsWithRetry(
    String query,
    geolocator.Position currentUserPosition,
    String cacheKey, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final parsed = await _performGeocodingRequest(query, currentUserPosition);
        
        // ✅ SALVEAZĂ ÎN CACHE
        if (parsed.isNotEmpty) {
          _geocodeCache[cacheKey] = _CachedGeocodeResult(
            suggestions: parsed,
            timestamp: DateTime.now(),
          );
        }
        
        return parsed;
      } on TimeoutException catch (e) {
        Logger.error('OSM geocoding timeout (attempt $attempt/$maxRetries): $e', error: e);
        if (attempt == maxRetries) {
          return [];
        }
        // ✅ EXPONENTIAL BACKOFF
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        Logger.error('OSM geocoding error (attempt $attempt/$maxRetries): $e', error: e);
        if (attempt == maxRetries) {
          return [];
        }
        // ✅ EXPONENTIAL BACKOFF
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    return [];
  }
  
  // ✅ Helper method pentru fetch (extras din try block)
  Future<List<AddressSuggestion>> _performGeocodingRequest(
    String query,
    geolocator.Position currentUserPosition,
  ) async {
    // Normalizează interogarea similar cu Google STT
    final String normalizedQuery = _normalizeRomanianAddress(query);

    // Context geografic: dacă ești aproape de București, adaugă bias și viewbox
    final double distanceToBucharest = geolocator.Geolocator.distanceBetween(
      currentUserPosition.latitude,
      currentUserPosition.longitude,
      44.4268,
      26.1025,
    );

    final bool nearBucharest = distanceToBucharest < 50000; // 50km
    final String contextualQuery = nearBucharest
        ? '$normalizedQuery, București, România'
        : '$normalizedQuery, România';

    final Map<String, String> params = <String, String>{
      'q': contextualQuery,
      'format': 'json',
      'addressdetails': '1',
      'limit': '10',
      'countrycodes': 'ro',
    };

    // Viewbox pentru București (lon,lat order: left, top, right, bottom)
    if (nearBucharest) {
      params['bounded'] = '1';
      params['viewbox'] = '25.9,44.7,26.4,44.2';
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    
    // ✅ TIMEOUT PENTRU GEOCODING (10 secunde)
    final response = await http.get(uri, headers: const {'User-Agent': 'Nabour/1.0'})
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Geocoding timeout pentru: $query');
        },
      );
    
    if (response.statusCode != 200) {
      return [];
    }

    final List<dynamic> data = json.decode(response.body) as List<dynamic>;
    return _parseOSMResults(
      data,
      normalizedQuery,
      currentUserPosition,
    );
  }

  // ✅ Photon (komoot) - geocoder rapid pentru input manual
  Future<List<AddressSuggestion>> fetchSuggestionsPhoton(
    String query,
    geolocator.Position currentUserPosition,
  ) async {
    if (query.trim().length < 2) return [];

    final cacheKey = 'photon_${query.toLowerCase().trim()}';
    final cached = _geocodeCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      Logger.debug('GeocodingService: Photon cache hit for: $query');
      return cached.suggestions;
    }

    try {
      final encoded = Uri.encodeComponent(query);
      final uri = Uri.parse(
        'https://photon.komoot.io/api/'
        '?q=$encoded'
        '&lang=ro'
        '&limit=8'
        '&lat=${currentUserPosition.latitude}'
        '&lon=${currentUserPosition.longitude}',
      );

      final response = await http
          .get(uri, headers: const {'User-Agent': 'Nabour/1.0'})
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Photon timeout for: $query'),
          );

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final features = (data['features'] as List<dynamic>?) ?? <dynamic>[];

      final suggestions = <AddressSuggestion>[];
      for (final dynamic feat in features) {
        final props = (feat['properties'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final geometry = (feat['geometry'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final coords = (geometry['coordinates'] as List<dynamic>?) ?? <dynamic>[];
        if (coords.length < 2) continue;

        final double lon = (coords[0] as num).toDouble();
        final double lat = (coords[1] as num).toDouble();

        // Filtrare doar România
        final String country = (props['country'] as String?) ?? '';
        if (!country.toLowerCase().contains('rom')) continue;

        final String name = (props['name'] as String?) ?? '';
        final String street = (props['street'] as String?) ?? '';
        final String housenumber = (props['housenumber'] as String?) ?? '';
        final String city = (props['city'] as String?)
            ?? (props['town'] as String?)
            ?? (props['village'] as String?)
            ?? '';

        String description = '';
        if (name.isNotEmpty && name != street) {
          description = name;
          if (street.isNotEmpty) description += ', $street';
          if (housenumber.isNotEmpty) description += ' $housenumber';
        } else if (street.isNotEmpty) {
          description = street;
          if (housenumber.isNotEmpty) description += ' $housenumber';
        }
        if (city.isNotEmpty) description += ', $city';
        if (description.isEmpty) continue;

        final double distance = geolocator.Geolocator.distanceBetween(
          currentUserPosition.latitude, currentUserPosition.longitude, lat, lon,
        );

        suggestions.add(AddressSuggestion(
          description: description,
          latitude: lat,
          longitude: lon,
          distanceMeters: distance,
        ));
      }

      if (suggestions.isNotEmpty) {
        _geocodeCache[cacheKey] = _CachedGeocodeResult(
          suggestions: suggestions,
          timestamp: DateTime.now(),
        );
      }

      return suggestions;
    } on TimeoutException catch (e) {
      Logger.error('Photon geocoding timeout: $e', error: e);
      return [];
    } catch (e) {
      Logger.error('Photon geocoding error: $e', error: e);
      return [];
    }
  }

  // ✅ NOU: Metoda pentru obținerea adresei din coordonate (cu retry)
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final request = 'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1';
        
        final response = await http.get(
          Uri.parse(request),
          headers: const {'User-Agent': 'Nabour/1.0'},
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Reverse geocoding timeout');
          },
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['display_name'] as String?;
        }
        
        if (attempt == 3) {
          return null;
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } on TimeoutException catch (e) {
        Logger.error('Reverse geocoding timeout (attempt $attempt/3): $e', error: e);
        if (attempt == 3) {
          return null;
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        Logger.error('Reverse geocoding error (attempt $attempt/3): $e', error: e);
        if (attempt == 3) {
          return null;
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    return null;
  }

  // --- Helpers ---
  String _normalizeRomanianAddress(String input) {
    String normalized = input.toLowerCase().trim();
    normalized = normalized
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ș', 's')
        .replaceAll('ş', 's')
        .replaceAll('ț', 't')
        .replaceAll('ţ', 't');

    final Map<String, String> abbreviations = <String, String>{
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
      r'\bsc\b': 'scara',
      r'\bet\b': 'etajul',
      r'\bap\b': 'apartamentul',
    };

    abbreviations.forEach((String pattern, String replacement) {
      normalized = normalized.replaceAll(RegExp(pattern), replacement);
    });

    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<AddressSuggestion> _parseOSMResults(
    List<dynamic> data,
    String originalQuery,
    geolocator.Position currentUserPosition,
  ) {
    final List<AddressSuggestion> suggestions = <AddressSuggestion>[];
    final List<String> queryWords = originalQuery.split(' ').where((w) => w.isNotEmpty).toList();

    for (final dynamic item in data) {
      final Map<String, dynamic> m = item as Map<String, dynamic>;
      final String displayName = (m['display_name'] as String?) ?? '';
      final double lat = double.tryParse((m['lat'] ?? '').toString()) ?? 0.0;
      final double lon = double.tryParse((m['lon'] ?? '').toString()) ?? 0.0;
      if (lat == 0.0 && lon == 0.0) continue;

      // Scor pe bază de potrivire a cuvintelor cheie
      int score = 0;
      final String lowerDisplay = displayName.toLowerCase();
      for (final String word in queryWords) {
        if (lowerDisplay.contains(word)) {
          score += word.length > 3 ? 10 : 5;
        }
      }
      if (lowerDisplay.contains('bucurești') || lowerDisplay.contains('bucharest')) {
        score += 20;
      }

      final double distance = geolocator.Geolocator.distanceBetween(
        currentUserPosition.latitude,
        currentUserPosition.longitude,
        lat,
        lon,
      );

      suggestions.add(AddressSuggestion(
        description: _formatAddressDisplay(displayName),
        latitude: lat,
        longitude: lon,
        score: score,
        distanceMeters: distance,
      ));
    }

    suggestions.sort((a, b) {
      final int cs = b.score.compareTo(a.score);
      if (cs != 0) return cs;
      return (a.distanceMeters ?? double.infinity).compareTo(b.distanceMeters ?? double.infinity);
    });

    return suggestions.take(8).toList();
  }

  String _formatAddressDisplay(String displayName) {
    final List<String> parts = displayName.split(', ');
    if (parts.length >= 2) {
      return '${parts[0]}, ${parts[1]}';
    }
    return displayName;
  }
}

// ✅ CLASĂ PENTRU CACHE (top-level)
class _CachedGeocodeResult {
  final List<AddressSuggestion> suggestions;
  final DateTime timestamp;
  
  _CachedGeocodeResult({
    required this.suggestions,
    required this.timestamp,
  });
  
  bool get isExpired {
    return DateTime.now().difference(timestamp) > GeocodingService._cacheExpiry;
  }
}
