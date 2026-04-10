import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/models/saved_address_model.dart';

/// Asociază poziția curentă cu adresele salvate (Acasă / Serviciu / Școală).
class NeighborPlaceDetector {
  NeighborPlaceDetector._();

  static const double defaultRadiusM = 120;

  /// Returnează `home`, `work`, `school` sau `null`.
  static String? detectKind(
    double lat,
    double lng,
    List<SavedAddress> addresses, {
    double radiusM = defaultRadiusM,
  }) {
    String? bestKind;
    double bestDist = radiusM + 1;

    for (final a in addresses) {
      final kind = _categoryToKind(a) ?? _labelToKind(a.label);
      if (kind == null) continue;
      final plat = a.coordinates.latitude;
      final plng = a.coordinates.longitude;
      if (plat == 0 && plng == 0) continue;
      final d = Geolocator.distanceBetween(lat, lng, plat, plng);
      if (d <= radiusM && d < bestDist) {
        bestDist = d;
        bestKind = kind;
      }
    }
    return bestKind;
  }

  static String? _categoryToKind(SavedAddress a) {
    switch (a.category) {
      case SavedAddressCategory.home:
        return 'home';
      case SavedAddressCategory.work:
        return 'work';
      case SavedAddressCategory.school:
        return 'school';
      case SavedAddressCategory.gym:
      case SavedAddressCategory.other:
        return null;
    }
  }

  static String? _labelToKind(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (_homeLabels.any((h) => s == h || s.contains(h))) return 'home';
    if (_workLabels.any((w) => s == w || s.contains(w))) return 'work';
    if (_schoolLabels.any((x) => s == x || s.contains(x))) return 'school';
    return null;
  }

  static const _homeLabels = [
    'acasă',
    'acasa',
    'home',
    'domiciliu',
  ];
  static const _workLabels = [
    'serviciu',
    'job',
    'work',
    'birou',
    'office',
    'muncă',
    'munca',
  ];
  static const _schoolLabels = [
    'școală',
    'scoala',
    'school',
    'facultate',
    'universitate',
    'uni ',
    'campus',
  ];
}
