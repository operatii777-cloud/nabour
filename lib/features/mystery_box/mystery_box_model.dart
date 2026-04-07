import 'package:cloud_firestore/cloud_firestore.dart';

class MysteryBox {
  final String id; // usually the businessOfferId
  final String businessId;
  final String businessName;
  final double latitude;
  final double longitude;
  final DateTime? openedAt;
  final bool isOpened;

  const MysteryBox({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.latitude,
    required this.longitude,
    this.openedAt,
    this.isOpened = false,
  });

  factory MysteryBox.fromOffer(dynamic offer) {
    return MysteryBox(
      id: offer.id,
      businessId: offer.businessId,
      businessName: offer.businessName,
      latitude: offer.businessLatitude,
      longitude: offer.businessLongitude,
    );
  }

  Map<String, dynamic> toMap() => {
    'businessId': businessId,
    'businessName': businessName,
    'latitude': latitude,
    'longitude': longitude,
    'openedAt': openedAt != null ? Timestamp.fromDate(openedAt!) : null,
  };
}
