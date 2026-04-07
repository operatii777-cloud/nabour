import 'package:geolocator/geolocator.dart';

/// Categorii disponibile pentru POI-uri
enum PoiCategory {
  /// Obiective turistice (static)
  tourism('tourism', 'Turism', '🏛️'),
  /// Benzinării (dinamic)
  gasStation('gas_station', 'Benzinării', '⛽'),
  /// Restaurante (dinamic)
  restaurant('restaurant', 'Restaurante', '🍽️'),
  /// Parcări (dinamic)
  parking('parking', 'Parcări', '🅿️'),
  /// Hoteluri (dinamic)
  hotel('lodging', 'Hoteluri', '🏨'),
  /// Spitale (dinamic)
  hospital('hospital', 'Spitale', '🏥'),
  /// Farmacii (dinamic)
  pharmacy('pharmacy', 'Farmacii', '💊'),
  /// Supermarketuri (dinamic)
  supermarket('supermarket', 'Supermarketuri', '🛒'),
  /// Bănci (dinamic)
  bank('bank', 'Bănci', '🏦'),
  /// ATM-uri (dinamic)
  atm('atm', 'ATM', '🏧'),
  /// Școli (amenity=school/kindergarten)
  school('school', 'Școli', '🏫'),
  /// Universități/College
  university('university', 'Universități', '🎓'),
  /// Biblioteci
  library('library', 'Biblioteci', '📚'),
  /// Poliție
  police('police', 'Poliție', '👮'),
  /// Poștă
  postOffice('post_office', 'Poștă', '📮'),
  /// Malluri/Piețe
  mall('mall', 'Malluri/Piețe', '🛍️'),
  /// Brutării
  bakery('bakery', 'Brutării', '🥖'),
  /// Baruri și Puburi
  barPub('bar_pub', 'Baruri/Puburi', '🍺'),
  /// Parcuri
  park('park', 'Parcuri', '🌳'),
  /// Muzee
  museum('museum', 'Muzee', '🏛️'),
  /// Cinematografe
  cinema('cinema', 'Cinematografe', '🎬'),
  /// Teatre
  theatre('theatre', 'Teatre', '🎭'),
  /// Locuri de joacă
  playground('playground', 'Locuri de joacă', '🧸'),
  /// Încărcare EV
  chargingStation('charging', 'Încărcare EV', '🔌'),
  /// Spălătorii auto
  carWash('car_wash', 'Spălătorii Auto', '🚿'),
  /// Service auto
  carRepair('car_repair', 'Service Auto', '🛠️'),
  /// Transport public (bus/tram/metrou/train)
  publicTransport('transport', 'Transport Public', '🚌'),
  /// Aeroporturi
  airport('airport', 'Aeroporturi', '✈️'),
  /// Altele (fallback)
  other('other', 'Altele', '📍');

  const PoiCategory(this.mapboxType, this.displayName, this.emoji);
  
  final String mapboxType;
  final String displayName;
  final String emoji;
}

extension PoiCategoryExtension on PoiCategory {
  static PoiCategory mapboxTypeToCategory(String mapboxType) {
    switch (mapboxType.toLowerCase()) {
      case 'gas_station':
      case 'fuel':
        return PoiCategory.gasStation;
      case 'restaurant':
      case 'food':
      case 'cafe':
        return PoiCategory.restaurant;
      case 'parking':
        return PoiCategory.parking;
      case 'lodging':
      case 'hotel':
        return PoiCategory.hotel;
      case 'hospital':
      case 'medical':
        return PoiCategory.hospital;
      case 'pharmacy':
        return PoiCategory.pharmacy;
      case 'supermarket':
      case 'grocery':
      case 'convenience':
        return PoiCategory.supermarket;
      case 'bank':
        return PoiCategory.bank;
      case 'atm':
        return PoiCategory.atm;
      case 'school':
      case 'kindergarten':
        return PoiCategory.school;
      case 'university':
      case 'college':
        return PoiCategory.university;
      case 'library':
        return PoiCategory.library;
      case 'police':
        return PoiCategory.police;
      case 'post_office':
        return PoiCategory.postOffice;
      case 'shopping_mall':
      case 'mall':
      case 'marketplace':
        return PoiCategory.mall;
      case 'bakery':
        return PoiCategory.bakery;
      case 'bar':
      case 'pub':
        return PoiCategory.barPub;
      case 'park':
        return PoiCategory.park;
      case 'museum':
        return PoiCategory.museum;
      case 'cinema':
        return PoiCategory.cinema;
      case 'theatre':
        return PoiCategory.theatre;
      case 'playground':
        return PoiCategory.playground;
      case 'charging_station':
        return PoiCategory.chargingStation;
      case 'car_wash':
        return PoiCategory.carWash;
      case 'car_repair':
        return PoiCategory.carRepair;
      case 'bus_stop':
      case 'train_station':
      case 'tram_stop':
      case 'subway_entrance':
      case 'public_transport':
        return PoiCategory.publicTransport;
      case 'aerodrome':
      case 'airport':
        return PoiCategory.airport;
      default:
        return PoiCategory.other;
    }
  }

  static String generateImageUrl(PoiCategory category, String name) {
    final encodedName = Uri.encodeComponent(name);
    final color = _getCategoryColor(category);
    return 'https://placehold.co/600x400/$color/FFFFFF?text=${category.emoji}+$encodedName';
  }

  static String _getCategoryColor(PoiCategory category) {
    switch (category) {
      case PoiCategory.tourism:
        return '9C27B0';
      case PoiCategory.gasStation:
        return 'FF5722';
      case PoiCategory.restaurant:
        return '4CAF50';
      case PoiCategory.parking:
        return '2196F3';
      case PoiCategory.hotel:
        return 'FF9800';
      case PoiCategory.hospital:
        return 'F44336';
      case PoiCategory.pharmacy:
        return '009688';
      case PoiCategory.supermarket:
        return '8BC34A';
      case PoiCategory.bank:
        return '3F51B5';
      case PoiCategory.atm:
        return '607D8B';
      case PoiCategory.other:
        return '9E9E9E';
      case PoiCategory.school:
        return '03A9F4';
      case PoiCategory.university:
        return '1E88E5';
      case PoiCategory.library:
        return '795548';
      case PoiCategory.police:
        return '0D47A1';
      case PoiCategory.postOffice:
        return 'FFC107';
      case PoiCategory.mall:
        return 'E91E63';
      case PoiCategory.bakery:
        return 'FFB300';
      case PoiCategory.barPub:
        return '6D4C41';
      case PoiCategory.park:
        return '2E7D32';
      case PoiCategory.museum:
        return '7B1FA2';
      case PoiCategory.cinema:
        return 'C51162';
      case PoiCategory.theatre:
        return 'AD1457';
      case PoiCategory.playground:
        return '43A047';
      case PoiCategory.chargingStation:
        return '00BCD4';
      case PoiCategory.carWash:
        return '90A4AE';
      case PoiCategory.carRepair:
        return '455A64';
      case PoiCategory.publicTransport:
        return '0288D1';
      case PoiCategory.airport:
        return '3949AB';
    }
  }
}
class PointOfInterest {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final Position location;
  final PoiCategory category;
  final bool isStatic; // true pentru POI-uri statice, false pentru dinamice
  final Map<String, dynamic>? additionalInfo; // rating, opening hours, etc.

  PointOfInterest({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.category,
    this.isStatic = false,
    this.additionalInfo,
  });

  /// Factory pentru crearea POI-urilor din răspunsul Mapbox Places API
  factory PointOfInterest.fromMapboxFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    
    final category = _mapboxTypeToCategory(properties['category'] ?? '');
    final name = properties['name'] ?? 'POI necunoscut';
    final address = properties['full_address'] ?? properties['address'] ?? '';
    
    return PointOfInterest(
      id: feature['id'] ?? 'poi_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: address.isNotEmpty ? address : 'Locație din ${category.displayName}',
      imageUrl: _generateImageUrl(category, name),
      location: Position(
        latitude: coordinates[1],
        longitude: coordinates[0],
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
      additionalInfo: {
        'rating': properties['rating'],
        'phone': properties['phone'],
        'website': properties['website'],
        'opening_hours': properties['opening_hours'],
      },
    );
  }

  /// Mapare din tipurile Mapbox la categoriile noastre
  static PoiCategory _mapboxTypeToCategory(String mapboxType) {
    switch (mapboxType.toLowerCase()) {
      case 'gas_station':
      case 'fuel':
        return PoiCategory.gasStation;
      case 'restaurant':
      case 'food':
      case 'cafe':
        return PoiCategory.restaurant;
      case 'parking':
        return PoiCategory.parking;
      case 'lodging':
      case 'hotel':
        return PoiCategory.hotel;
      case 'hospital':
      case 'medical':
        return PoiCategory.hospital;
      case 'pharmacy':
        return PoiCategory.pharmacy;
      case 'supermarket':
      case 'grocery':
      case 'convenience':
        return PoiCategory.supermarket;
      case 'bank':
        return PoiCategory.bank;
      case 'atm':
        return PoiCategory.atm;
      case 'school':
      case 'kindergarten':
        return PoiCategory.school;
      case 'university':
      case 'college':
        return PoiCategory.university;
      case 'library':
        return PoiCategory.library;
      case 'police':
        return PoiCategory.police;
      case 'post_office':
        return PoiCategory.postOffice;
      case 'shopping_mall':
      case 'mall':
      case 'marketplace':
        return PoiCategory.mall;
      case 'bakery':
        return PoiCategory.bakery;
      case 'bar':
      case 'pub':
        return PoiCategory.barPub;
      case 'park':
        return PoiCategory.park;
      case 'museum':
        return PoiCategory.museum;
      case 'cinema':
        return PoiCategory.cinema;
      case 'theatre':
        return PoiCategory.theatre;
      case 'playground':
        return PoiCategory.playground;
      case 'charging_station':
        return PoiCategory.chargingStation;
      case 'car_wash':
        return PoiCategory.carWash;
      case 'car_repair':
        return PoiCategory.carRepair;
      case 'bus_stop':
      case 'train_station':
      case 'tram_stop':
      case 'subway_entrance':
      case 'public_transport':
        return PoiCategory.publicTransport;
      case 'aerodrome':
      case 'airport':
        return PoiCategory.airport;
      default:
        return PoiCategory.other;
    }
  }

  /// Generează URL pentru imagine placeholder pe baza categoriei
  static String _generateImageUrl(PoiCategory category, String name) {
    final encodedName = Uri.encodeComponent(name);
    final color = _getCategoryColor(category);
    return 'https://placehold.co/600x400/$color/FFFFFF?text=${category.emoji}+$encodedName';
  }

  /// Culori pentru categorii
  static String _getCategoryColor(PoiCategory category) {
    switch (category) {
      case PoiCategory.tourism:
        return '9C27B0'; // purple
      case PoiCategory.gasStation:
        return 'FF5722'; // deep orange
      case PoiCategory.restaurant:
        return '4CAF50'; // green
      case PoiCategory.parking:
        return '2196F3'; // blue
      case PoiCategory.hotel:
        return 'FF9800'; // orange
      case PoiCategory.hospital:
        return 'F44336'; // red
      case PoiCategory.pharmacy:
        return '009688'; // teal
      case PoiCategory.supermarket:
        return '8BC34A'; // light green
      case PoiCategory.bank:
        return '3F51B5'; // indigo
      case PoiCategory.atm:
        return '607D8B'; // blue grey
      case PoiCategory.other:
        return '9E9E9E'; // grey
      case PoiCategory.school:
        return '03A9F4'; // light blue
      case PoiCategory.university:
        return '1E88E5'; // blue
      case PoiCategory.library:
        return '795548'; // brown
      case PoiCategory.police:
        return '0D47A1'; // dark blue
      case PoiCategory.postOffice:
        return 'FFC107'; // amber
      case PoiCategory.mall:
        return 'E91E63'; // pink
      case PoiCategory.bakery:
        return 'FFB300'; // amber dark
      case PoiCategory.barPub:
        return '6D4C41'; // brown dark
      case PoiCategory.park:
        return '2E7D32'; // green dark
      case PoiCategory.museum:
        return '7B1FA2'; // purple dark
      case PoiCategory.cinema:
        return 'C51162'; // pink dark
      case PoiCategory.theatre:
        return 'AD1457'; // pink deeper
      case PoiCategory.playground:
        return '43A047'; // green
      case PoiCategory.chargingStation:
        return '00BCD4'; // cyan
      case PoiCategory.carWash:
        return '90A4AE'; // blue grey light
      case PoiCategory.carRepair:
        return '455A64'; // blue grey
      case PoiCategory.publicTransport:
        return '0288D1'; // blue
      case PoiCategory.airport:
        return '3949AB'; // indigo
    }
  }
}