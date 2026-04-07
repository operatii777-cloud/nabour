/// Model pentru o ofertă de cursă trimisă șoferului.
class RideOfferModel {
  final String rideId;
  final String passengerName;
  final String passengerPhotoUrl;
  final double passengerRating;
  final String pickupAddress;
  final String destinationAddress;
  final double distanceToPickupKm;   // distanța șoferului până la pasager
  final double rideTotalDistanceKm;  // distanța totală a cursei
  final double estimatedEarnings;    // câștig net estimat (RON)
  final int countdownSeconds;        // implicit 15
  final DateTime receivedAt;

  const RideOfferModel({
    required this.rideId,
    required this.passengerName,
    required this.passengerPhotoUrl,
    required this.passengerRating,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.distanceToPickupKm,
    required this.rideTotalDistanceKm,
    required this.estimatedEarnings,
    this.countdownSeconds = 15,
    required this.receivedAt,
  });

  factory RideOfferModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RideOfferModel(
      rideId: id,
      passengerName: data['passengerName'] ?? 'Pasager',
      passengerPhotoUrl: data['passengerPhotoUrl'] ?? '',
      passengerRating: (data['passengerRating'] ?? 5.0).toDouble(),
      pickupAddress: data['pickupAddress'] ?? '',
      destinationAddress: data['destinationAddress'] ?? '',
      distanceToPickupKm: (data['distanceToPickupKm'] ?? 0.0).toDouble(),
      rideTotalDistanceKm: (data['rideTotalDistanceKm'] ?? 0.0).toDouble(),
      estimatedEarnings: (data['estimatedEarnings'] ?? 0.0).toDouble(),
      countdownSeconds: data['countdownSeconds'] ?? 15,
      receivedAt: DateTime.now(),
    );
  }
}
