import 'package:cloud_firestore/cloud_firestore.dart';

/// Categorie stabilă pentru adrese salvate (persistată în Firestore ca `category`).
enum SavedAddressCategory {
  home,
  work,
  school,
  gym,
  other,
}

extension SavedAddressCategoryLabels on SavedAddressCategory {
  /// Etichetă scurtă pentru UI (RO) — același ecran folosește deja texte în română.
  String get labelRo {
    switch (this) {
      case SavedAddressCategory.home:
        return 'Acasă';
      case SavedAddressCategory.work:
        return 'Serviciu';
      case SavedAddressCategory.school:
        return 'Școală';
      case SavedAddressCategory.gym:
        return 'Sală / sport';
      case SavedAddressCategory.other:
        return 'Altele';
    }
  }
}

class SavedAddress {
  final String id;
  final String label; // ex: poreclă sau repetă categoria
  final String address; // Adresa completă, ca text
  final GeoPoint coordinates; // Coordonatele geografice
  final SavedAddressCategory category;

  SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.coordinates,
    this.category = SavedAddressCategory.other,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'address': address,
      'coordinates': coordinates,
      'category': category.name,
    };
  }

  static GeoPoint _parseCoordinates(dynamic v) {
    if (v is GeoPoint) return v;
    if (v is Map) {
      final lat = (v['latitude'] ?? v['lat']) as num?;
      final lng = (v['longitude'] ?? v['lng'] ?? v['lon']) as num?;
      if (lat != null && lng != null) {
        return GeoPoint(lat.toDouble(), lng.toDouble());
      }
    }
    return const GeoPoint(0, 0);
  }

  static SavedAddressCategory _inferCategoryFromLabel(String label) {
    final t = label.trim().toLowerCase();
    final ascii = t
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ș', 's')
        .replaceAll('ț', 't');
    if (t == 'acasă' ||
        ascii == 'acasa' ||
        t == 'home' ||
        ascii == 'home' ||
        t == '🏠' ||
        t.contains('🏠')) {
      return SavedAddressCategory.home;
    }
    if (t == 'serviciu' ||
        t == 'birou' ||
        t == 'job' ||
        t == 'muncă' ||
        ascii == 'munca' ||
        t == 'work') {
      return SavedAddressCategory.work;
    }
    return SavedAddressCategory.other;
  }

  static SavedAddressCategory _parseCategory(dynamic raw, String label) {
    if (raw is String && raw.isNotEmpty) {
      for (final c in SavedAddressCategory.values) {
        if (c.name == raw) return c;
      }
    }
    return _inferCategoryFromLabel(label);
  }

  factory SavedAddress.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final label = data['label']?.toString() ?? '';
    return SavedAddress(
      id: doc.id,
      label: label,
      address: data['address']?.toString() ?? '',
      coordinates: _parseCoordinates(data['coordinates']),
      category: _parseCategory(data['category'], label),
    );
  }

  /// Acasă / Serviciu — pentru secțiuni și filtre.
  bool get isHomeCategory => category == SavedAddressCategory.home;
  bool get isWorkCategory => category == SavedAddressCategory.work;

  /// Favorite generale (nu sloturile Acasă / Serviciu).
  bool get isGeneralFavorite =>
      category != SavedAddressCategory.home &&
      category != SavedAddressCategory.work;
}
