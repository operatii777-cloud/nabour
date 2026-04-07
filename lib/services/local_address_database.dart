import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:nabour_app/services/geocoding_service.dart';

class LocalAddressDatabase {
  static final LocalAddressDatabase _instance = LocalAddressDatabase._();
  factory LocalAddressDatabase() => _instance;
  LocalAddressDatabase._();

  List<_LocalStreet> _streets = [];
  final List<_LocalAddress> _addresses = [];
  List<_LocalPoi> _poi = [];
  bool _loaded = false;

  static const _streetPrefixes = [
    'strada', 'str', 'intrarea', 'intr', 'bulevardul', 'bd', 'bdul',
    'aleea', 'calea', 'soseaua', 'sos', 'splaiul', 'piata', 'fundatura',
    'strada.', 'intr.', 'bd.', 'sos.',
  ];

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    // ── Bragadiru (format vechi cu chei named) ──────────────────────────────
    final bragRaw = await rootBundle.loadString('assets/data/bragadiru_streets.json');
    final bragData = json.decode(bragRaw) as Map<String, dynamic>;

    for (final e in bragData['streets'] as List<dynamic>) {
      _streets.add(_LocalStreet(
        name: e['name'] as String,
        lat: (e['lat'] as num).toDouble(),
        lon: (e['lon'] as num).toDouble(),
      ));
    }
    for (final e in bragData['addresses'] as List<dynamic>) {
      final nv = e['numericValue'];
      _addresses.add(_LocalAddress(
        street: e['street'] as String,
        numericValue: nv != null ? (nv as num).toInt() : null,
        lat: (e['lat'] as num).toDouble(),
        lon: (e['lon'] as num).toDouble(),
      ));
    }

    // ── București (format compact: arrays) ──────────────────────────────────
    // streets: [ [name, lat, lon], ... ]
    // addresses: [ [street, number, lat, lon], ... ]
    final bucRaw = await rootBundle.loadString('assets/data/bucharest_streets.json');
    final bucData = json.decode(bucRaw) as Map<String, dynamic>;

    for (final e in bucData['s'] as List<dynamic>) {
      _streets.add(_LocalStreet(
        name: e[0] as String,
        lat: (e[1] as num).toDouble(),
        lon: (e[2] as num).toDouble(),
      ));
    }
    for (final e in bucData['a'] as List<dynamic>) {
      _addresses.add(_LocalAddress(
        street: e[0] as String,
        numericValue: (e[1] as num).toInt(),
        lat: (e[2] as num).toDouble(),
        lon: (e[3] as num).toDouble(),
      ));
    }

    // ── POI ─────────────────────────────────────────────────────────────────
    final poiRaw = await rootBundle.loadString('assets/data/poi_bucharest.json');
    final poiData = json.decode(poiRaw) as List<dynamic>;
    _poi = poiData.map((e) => _LocalPoi(
          name: e['name'] as String,
          category: e['category'] as String,
          lat: (e['lat'] as num).toDouble(),
          lon: (e['lon'] as num).toDouble(),
        )).toList();

    // Deduplicare străzi cu același nume (păstrăm prima apariție)
    final seen = <String>{};
    _streets = _streets.where((s) => seen.add(s.name)).toList();

    _loaded = true;
  }

  Future<List<LocalPoi>> getPoisNearby(double lat, double lon, {double radiusKm = 2.0}) async {
    await _ensureLoaded();
    final results = <LocalPoi>[];
    for (final p in _poi) {
      final dist = geolocator.Geolocator.distanceBetween(lat, lon, p.lat, p.lon);
      if (dist <= radiusKm * 1000) results.add(p);
    }
    return results;
  }

  Future<List<AddressSuggestion>> search(
    String query,
    geolocator.Position currentPosition,
  ) async {
    await _ensureLoaded();

    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    // Nivel 0: POI
    final poiResults = _searchPoi(trimmed, currentPosition);
    if (poiResults.isNotEmpty) return poiResults;

    // Extrage numărul și partea de stradă
    final numberMatch = RegExp(r'\b(\d+)\b').firstMatch(trimmed);
    final int? requestedNumber = numberMatch != null ? int.tryParse(numberMatch.group(1)!) : null;
    final String streetPart = trimmed.replaceAll(RegExp(r'\b\d+\b'), '').trim();
    final String streetQuery = _normalize(streetPart.isNotEmpty ? streetPart : trimmed);

    if (requestedNumber != null && streetPart.isNotEmpty) {
      return _searchWithNumber(streetQuery, requestedNumber, currentPosition);
    } else {
      return _searchByStreetName(streetQuery, currentPosition);
    }
  }

  List<AddressSuggestion> _searchPoi(String query, geolocator.Position pos) {
    final normalized = _normalize(query);
    final results = <_ScoredPoi>[];
    for (final poi in _poi) {
      final score = _matchScore(_normalize(poi.name), normalized);
      if (score >= 40) {
        final dist = geolocator.Geolocator.distanceBetween(pos.latitude, pos.longitude, poi.lat, poi.lon);
        results.add(_ScoredPoi(poi: poi, score: score, distance: dist));
      }
    }
    results.sort((a, b) { final cs = b.score.compareTo(a.score); return cs != 0 ? cs : a.distance.compareTo(b.distance); });
    return results.take(5).map((r) => AddressSuggestion(
      description: '${r.poi.name}, ${_categoryLabel(r.poi.category)}',
      latitude: r.poi.lat, longitude: r.poi.lon,
      score: r.score, distanceMeters: r.distance,
    )).toList();
  }

  List<AddressSuggestion> _searchWithNumber(String streetQuery, int requestedNumber, geolocator.Position pos) {
    final matches = <_ScoredStreet>[];
    for (final street in _streets) {
      final score = _matchScore(_normalize(street.name), streetQuery);
      if (score >= 40) {
        final dist = geolocator.Geolocator.distanceBetween(pos.latitude, pos.longitude, street.lat, street.lon);
        matches.add(_ScoredStreet(street: street, score: score, distance: dist));
      }
    }
    if (matches.isEmpty) return [];
    matches.sort((a, b) { final cs = b.score.compareTo(a.score); return cs != 0 ? cs : a.distance.compareTo(b.distance); });

    final suggestions = <AddressSuggestion>[];
    for (final match in matches.take(5)) {
      final coreStreet = _extractCoreName(_normalize(match.street.name));
      final streetAddresses = _addresses
          .where((a) => a.numericValue != null && _extractCoreName(_normalize(a.street)).contains(coreStreet))
          .toList()
        ..sort((a, b) => a.numericValue!.compareTo(b.numericValue!));

      final coords = streetAddresses.isEmpty
          ? [match.street.lat, match.street.lon]
          : _interpolateCoordinates(streetAddresses, requestedNumber);

      final dist = geolocator.Geolocator.distanceBetween(pos.latitude, pos.longitude, coords[0], coords[1]);
      suggestions.add(AddressSuggestion(
        description: '${match.street.name} $requestedNumber',
        latitude: coords[0], longitude: coords[1],
        score: match.score, distanceMeters: dist,
      ));
    }
    return suggestions;
  }

  List<AddressSuggestion> _searchByStreetName(String streetQuery, geolocator.Position pos) {
    final results = <_ScoredStreet>[];
    for (final street in _streets) {
      final score = _matchScore(_normalize(street.name), streetQuery);
      if (score > 0) {
        final dist = geolocator.Geolocator.distanceBetween(pos.latitude, pos.longitude, street.lat, street.lon);
        results.add(_ScoredStreet(street: street, score: score, distance: dist));
      }
    }
    results.sort((a, b) { final cs = b.score.compareTo(a.score); return cs != 0 ? cs : a.distance.compareTo(b.distance); });
    return results.take(5).map((r) => AddressSuggestion(
      description: r.street.name,
      latitude: r.street.lat, longitude: r.street.lon,
      score: r.score, distanceMeters: r.distance,
    )).toList();
  }

  List<double> _interpolateCoordinates(List<_LocalAddress> sorted, int number) {
    for (final a in sorted) { if (a.numericValue == number) return [a.lat, a.lon]; }
    if (number <= sorted.first.numericValue!) return [sorted.first.lat, sorted.first.lon];
    if (number >= sorted.last.numericValue!) return [sorted.last.lat, sorted.last.lon];
    _LocalAddress? lower, upper;
    for (int i = 0; i < sorted.length - 1; i++) {
      if (sorted[i].numericValue! <= number && sorted[i + 1].numericValue! >= number) {
        lower = sorted[i]; upper = sorted[i + 1]; break;
      }
    }
    if (lower == null || upper == null) return [sorted.first.lat, sorted.first.lon];
    final t = (upper.numericValue! == lower.numericValue!) ? 0.0 : (number - lower.numericValue!) / (upper.numericValue! - lower.numericValue!);
    return [lower.lat + t * (upper.lat - lower.lat), lower.lon + t * (upper.lon - lower.lon)];
  }

  int _matchScore(String streetNorm, String queryNorm) {
    if (streetNorm == queryNorm) return 100;
    if (streetNorm.startsWith(queryNorm)) return 80;
    if (streetNorm.contains(queryNorm)) return 60;
    final sc = _extractCoreName(streetNorm);
    final qc = _extractCoreName(queryNorm);
    if (sc == qc) return 95;
    if (sc.startsWith(qc)) return 75;
    if (sc.contains(qc)) return 55;
    final words = qc.split(' ').where((w) => w.length > 2).toList();
    int score = 0;
    for (final w in words) { if (sc.contains(w)) score += 20; }
    return score;
  }

  String _extractCoreName(String normalized) {
    for (final prefix in _streetPrefixes) {
      if (normalized == prefix) return normalized;
      if (normalized.startsWith('$prefix ')) return normalized.substring(prefix.length).trim();
    }
    return normalized;
  }

  String _normalize(String input) {
    return input.toLowerCase().trim()
        .replaceAll('ă', 'a').replaceAll('â', 'a').replaceAll('î', 'i')
        .replaceAll('ș', 's').replaceAll('ş', 's').replaceAll('ț', 't').replaceAll('ţ', 't')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'restaurant': return 'Restaurant';
      case 'cafe': return 'Cafenea';
      case 'fast_food': return 'Fast Food';
      case 'pharmacy': return 'Farmacie';
      case 'bank': return 'Bancă';
      case 'supermarket': return 'Supermarket';
      default: return category;
    }
  }
}

class LocalPoi {
  final String name;
  final String category;
  final double lat;
  final double lon;
  const LocalPoi({required this.name, required this.category, required this.lat, required this.lon});
}

class _LocalPoi extends LocalPoi {
  const _LocalPoi({required super.name, required super.category, required super.lat, required super.lon});
}

class _LocalStreet {
  final String name;
  final double lat;
  final double lon;
  const _LocalStreet({required this.name, required this.lat, required this.lon});
}

class _LocalAddress {
  final String street;
  final int? numericValue;
  final double lat;
  final double lon;
  const _LocalAddress({required this.street, required this.numericValue, required this.lat, required this.lon});
}

class _ScoredStreet {
  final _LocalStreet street;
  final int score;
  final double distance;
  const _ScoredStreet({required this.street, required this.score, required this.distance});
}

class _ScoredPoi {
  final _LocalPoi poi;
  final int score;
  final double distance;
  const _ScoredPoi({required this.poi, required this.score, required this.distance});
}
