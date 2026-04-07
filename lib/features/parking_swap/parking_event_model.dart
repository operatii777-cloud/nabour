import 'package:cloud_firestore/cloud_firestore.dart';

enum ParkingSpotStatus { available, reserved, claimed, expired, cancelled }

class ParkingSpotEvent {
  final String id;
  final String providerId; // UID celui care pleacă
  final String? claimerId; // UID celui care vine (sau null)
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime expiresAt;
  final ParkingSpotStatus status;
  final int rewardAmount;

  ParkingSpotEvent({
    required this.id,
    required this.providerId,
    this.claimerId,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.expiresAt,
    this.status = ParkingSpotStatus.available,
    this.rewardAmount = 50, // Recompensa standard pentru eliberare loc
  });

  factory ParkingSpotEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParkingSpotEvent(
      id: doc.id,
      providerId: data['providerId'] ?? '',
      claimerId: data['claimerId'],
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      status: ParkingSpotStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'available'),
        orElse: () => ParkingSpotStatus.available,
      ),
      rewardAmount: data['rewardAmount'] ?? 50,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'claimerId': claimerId,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status.name,
      'rewardAmount': rewardAmount,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isReserved => status == ParkingSpotStatus.reserved;
  double get lat => latitude;
  double get lng => longitude;
}
