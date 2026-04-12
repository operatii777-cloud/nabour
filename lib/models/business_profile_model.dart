import 'package:cloud_firestore/cloud_firestore.dart';

enum BusinessCategory {
  restaurant,
  foodTruck,
  beauty,
  brutarie,
  minimarket,
  aprozar,
  macelarie,
  florarie,
  farmacie,
  exchange,
  librarie,
  pieseAuto,
  fitnessGym,
  supermarket,
  /// Vânzări vehicule (auto, moto).
  vanzariAutoMoto,
  /// Imobiliare — vânzări.
  imobiliareVanzari,
  /// Imobiliare — închirieri.
  imobiliareInchirieri,
  // Fallback pentru date legacy vechi; nu îl mai afișăm la selecție.
  altele;

  String displayNameForLanguage(String languageCode) {
    final isEnglish = languageCode.toLowerCase().startsWith('en');
    switch (this) {
      case BusinessCategory.restaurant: return isEnglish ? 'Restaurants' : 'Restaurante';
      case BusinessCategory.foodTruck: return isEnglish ? 'Food Truck' : 'Food truck';
      case BusinessCategory.beauty: return 'Beauty';
      case BusinessCategory.brutarie: return isEnglish ? 'Bakery' : 'Brutarie';
      case BusinessCategory.supermarket: return isEnglish ? 'Supermarket' : 'Supermarket';
      case BusinessCategory.minimarket: return isEnglish ? 'Minimarket' : 'Minimarket';
      case BusinessCategory.aprozar: return isEnglish ? 'Greengrocer' : 'Aprozar';
      case BusinessCategory.macelarie: return isEnglish ? 'Butcher Shop' : 'Macelarie';
      case BusinessCategory.florarie: return isEnglish ? 'Florist' : 'Florarie';
      case BusinessCategory.farmacie: return isEnglish ? 'Pharmacies' : 'Farmacii';
      case BusinessCategory.exchange: return isEnglish ? 'Currency Exchange' : 'Exchange';
      case BusinessCategory.librarie: return isEnglish ? 'Bookstore' : 'Librarie';
      case BusinessCategory.pieseAuto: return isEnglish ? 'Auto Parts' : 'Piese auto';
      case BusinessCategory.fitnessGym: return 'Fitness/Gym';
      case BusinessCategory.vanzariAutoMoto:
        return isEnglish ? 'Auto / motorcycle sales' : 'Vânzări auto/moto';
      case BusinessCategory.imobiliareVanzari:
        return isEnglish ? 'Real estate — sales' : 'Vânzări imobiliare';
      case BusinessCategory.imobiliareInchirieri:
        return isEnglish ? 'Real estate — rentals' : 'Închirieri imobiliare';
      case BusinessCategory.altele: return isEnglish ? 'Other (legacy)' : 'Altele (legacy)';
    }
  }

  String get displayName => displayNameForLanguage('ro');

  String get emoji {
    switch (this) {
      case BusinessCategory.restaurant: return '🍽️';
      case BusinessCategory.foodTruck: return '🚚';
      case BusinessCategory.beauty: return '💅';
      case BusinessCategory.brutarie: return '🥐';
      case BusinessCategory.supermarket: return '🛒';
      case BusinessCategory.minimarket: return '🏪';
      case BusinessCategory.aprozar: return '🥕';
      case BusinessCategory.macelarie: return '🥩';
      case BusinessCategory.florarie: return '💐';
      case BusinessCategory.farmacie: return '💊';
      case BusinessCategory.exchange: return '💱';
      case BusinessCategory.librarie: return '📚';
      case BusinessCategory.pieseAuto: return '🔧';
      case BusinessCategory.fitnessGym: return '🏋️';
      case BusinessCategory.vanzariAutoMoto: return '🚗';
      case BusinessCategory.imobiliareVanzari: return '🏠';
      case BusinessCategory.imobiliareInchirieri: return '🔑';
      case BusinessCategory.altele: return '🏪';
    }
  }

  static List<BusinessCategory> get selectable => const [
        BusinessCategory.restaurant,
        BusinessCategory.foodTruck,
        BusinessCategory.beauty,
        BusinessCategory.brutarie,
        BusinessCategory.supermarket,
        BusinessCategory.minimarket,
        BusinessCategory.aprozar,
        BusinessCategory.macelarie,
        BusinessCategory.florarie,
        BusinessCategory.farmacie,
        BusinessCategory.exchange,
        BusinessCategory.librarie,
        BusinessCategory.pieseAuto,
        BusinessCategory.fitnessGym,
        BusinessCategory.vanzariAutoMoto,
        BusinessCategory.imobiliareVanzari,
        BusinessCategory.imobiliareInchirieri,
      ];
}

class BusinessProfile {
  final String id;
  final String userId;
  final String businessName;
  final BusinessCategory category;
  final String address;
  final String phone;
  final String? website;
  final String? whatsapp;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final bool isActive;
  final bool isSuspended;
  final DateTime? subscriptionExpiresAt;

  const BusinessProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.category,
    required this.address,
    required this.phone,
    this.website,
    this.whatsapp,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.isActive = true,
    this.isSuspended = false,
    this.subscriptionExpiresAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'businessName': businessName,
    'category': category.name,
    'address': address,
    'phone': phone,
    'website': website,
    'whatsapp': whatsapp,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'location': GeoPoint(latitude, longitude),
    'createdAt': Timestamp.fromDate(createdAt),
    'isActive': isActive,
    'isSuspended': isSuspended,
    if (subscriptionExpiresAt != null)
      'subscriptionExpiresAt': Timestamp.fromDate(subscriptionExpiresAt!),
  };

  factory BusinessProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BusinessProfile(
      id: doc.id,
      userId: d['userId'] ?? '',
      businessName: d['businessName'] ?? '',
      category: BusinessCategory.values.firstWhere(
        (e) => e.name == (d['category'] ?? 'altele'),
        orElse: () => BusinessCategory.altele,
      ),
      address: d['address'] ?? '',
      phone: d['phone'] ?? '',
      website: d['website'],
      whatsapp: d['whatsapp'],
      description: d['description'] ?? '',
      latitude: (d['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (d['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: d['isActive'] ?? true,
      isSuspended: d['isSuspended'] ?? false,
      subscriptionExpiresAt:
          (d['subscriptionExpiresAt'] as Timestamp?)?.toDate(),
    );
  }
}
