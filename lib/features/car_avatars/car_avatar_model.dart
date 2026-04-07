/// Category of a Galaxy Garage avatar.
///
/// Used by [CarAvatar.allowsPassengerMapSlot] to enforce which avatar types
/// are permitted to appear in the passive (non-driving) map slot.
enum CarCategory {
  /// Default built-in car — always allowed in every slot.
  defaultCar,

  /// Character-themed vehicles (e.g. robots, astronauts).
  characters,

  /// Animal-themed vehicles.
  animals,

  /// Real transport vehicles (buses, trucks, trams, etc.).
  /// These are only appropriate for the driver slot and must NOT appear
  /// in the passenger map slot.
  transport,
}

/// Immutable value object representing a single Galaxy Garage avatar entry.
class CarAvatar {
  const CarAvatar({
    required this.id,
    required this.assetPath,
    required this.category,
    this.isDefault = false,
  });

  /// Unique identifier (matches the value stored in Firestore / SharedPreferences).
  final String id;

  /// Bundle asset path to the PNG image file.
  final String assetPath;

  /// Category used to determine slot eligibility rules.
  final CarCategory category;

  /// Whether this is the built-in default avatar (no asset selection needed).
  final bool isDefault;

  // ──────────────────────────────────────────────────────────────────────────
  // Slot eligibility getters
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns `true` when this avatar may be shown in the **passenger** map slot.
  ///
  /// Rules (in priority order):
  /// 1. Default avatar → always allowed.
  /// 2. [CarCategory.transport] → **never** allowed in the passenger slot.
  ///    Transport vehicles (buses, trucks, trams …) are conceptually a driver
  ///    metaphor and must not leak into the passive rider view.
  /// 3. [CarCategory.characters] and [CarCategory.animals] → allowed.
  ///
  /// Using an exhaustive switch ensures a compile-time error if a new
  /// [CarCategory] value is added without explicitly deciding its eligibility.
  bool get allowsPassengerMapSlot {
    if (isDefault) return true;
    return switch (category) {
      CarCategory.defaultCar => true,
      CarCategory.characters => true,
      CarCategory.animals => true,
      CarCategory.transport => false,
    };
  }

  /// Returns `true` when this avatar may be shown in the **driver** map slot.
  ///
  /// All non-default avatars are eligible for the driver slot; the default
  /// avatar also qualifies.
  bool get allowsDriverMapSlot => true;

  @override
  String toString() =>
      'CarAvatar(id: $id, category: $category, isDefault: $isDefault)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarAvatar &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
