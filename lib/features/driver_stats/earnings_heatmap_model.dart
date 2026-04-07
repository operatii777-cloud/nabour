class EarningsZone {
  final double centerLat;
  final double centerLng;
  final double radiusKm;
  final double averageEarningsPerHour; // RON/oră în această zonă
  final int totalRides;
  final String zoneName;

  const EarningsZone({
    required this.centerLat,
    required this.centerLng,
    required this.radiusKm,
    required this.averageEarningsPerHour,
    required this.totalRides,
    required this.zoneName,
  });
}
