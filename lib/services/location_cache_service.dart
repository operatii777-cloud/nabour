import 'package:geolocator/geolocator.dart' as geolocator;

/// Ultima poziție cunoscută în aplicație (hartă, șofer, etc.) pentru a evita
/// așteptarea lungă la primul [getCurrentPosition] pe ecrane ca navigarea la punct.
class LocationCacheService {
  LocationCacheService._();
  static final LocationCacheService instance = LocationCacheService._();

  geolocator.Position? _last;

  void record(geolocator.Position p) {
    _last = p;
  }

  /// Returnează ultima poziție înregistrată dacă fixul GPS nu e mai vechi de [maxAge].
  geolocator.Position? peekRecent({
    Duration maxAge = const Duration(minutes: 4),
  }) {
    final p = _last;
    if (p == null) return null;
    final age = DateTime.now().difference(p.timestamp);
    if (age > maxAge) return null;
    return p;
  }

  static geolocator.Position? pickNewer(
    geolocator.Position? a,
    geolocator.Position? b,
  ) {
    if (a == null) return b;
    if (b == null) return a;
    return a.timestamp.isAfter(b.timestamp) ? a : b;
  }
}
