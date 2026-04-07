enum CarCategory { transport, animals, characters }

/// Avatar pe hartă: **la volan** (șofer disponibil) vs **ca pasager**.
enum CarAvatarMapSlot { driver, passenger }

class CarAvatar {
  final String id;
  final String name;
  final String assetPath;
  final int price;
  final bool isDefault;
  final CarCategory category;

  /// Artă încă neîncărcată în bundle: afișăm „În curând” și blocăm cumpărarea.
  final bool comingSoon;

  CarAvatar({
    required this.id,
    required this.name,
    required this.assetPath,
    this.price = 0,
    this.isDefault = false,
    this.category = CarCategory.transport,
    this.comingSoon = false,
  });

  factory CarAvatar.defaultCar() {
    return CarAvatar(
      id: 'default_car',
      name: 'Berlina Standard',
      assetPath: 'assets/images/driver_icon.png',
      price: 0,
      isDefault: true,
      category: CarCategory.transport,
      comingSoon: false,
    );
  }

  /// Pe hartă ca **șofer (la volan)**: doar vehicule din transport (fără animale, personaje, robo).
  bool get allowsDriverMapSlot {
    if (isDefault) return true;
    if (category == CarCategory.animals || category == CarCategory.characters) {
      return false;
    }
    if (category == CarCategory.transport && id == 'robo') return false;
    return category == CarCategory.transport;
  }

  /// Pe hartă ca **pasager**: strict caractere, animale și fallback.
  /// NU permitem vehicule (transport) în slotul de pasager.
  bool get allowsPassengerMapSlot {
    if (isDefault) return true;
    
    // Regula de Business: Transportul (mașini, salupe, van) este DOAR pentru șofer.
    if (category == CarCategory.transport) {
      return false;
    }
    
    // Permitem personajele și animăluțele.
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'assetPath': assetPath,
      'price': price,
      'isDefault': isDefault,
      'category': category.name,
      'comingSoon': comingSoon,
    };
  }
}
