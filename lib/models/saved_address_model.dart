import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddress {
  final String id;
  final String label; // ex: "Acasă", "Serviciu"
  final String address; // Adresa completă, ca text
  final GeoPoint coordinates; // Coordonatele geografice

  SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.coordinates,
  });

  // Convertim un obiect în formatul necesar pentru Firestore
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'address': address,
      'coordinates': coordinates,
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

  // Creăm un obiect din datele primite de la Firestore
  factory SavedAddress.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SavedAddress(
      id: doc.id,
      label: data['label'] ?? '',
      address: data['address'] ?? '',
      coordinates: _parseCoordinates(data['coordinates']),
    );
  }
}
