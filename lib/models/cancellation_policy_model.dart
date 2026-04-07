/// Model pentru politica de anulare (Uber-like)
class CancellationPolicy {
  final bool isFree;
  final double? fee;
  final String reason;
  final Duration? timeWindow; // Timpul în care anularea este gratuită
  final bool appliesToDriver;
  final bool appliesToPassenger;

  const CancellationPolicy({
    required this.isFree,
    this.fee,
    required this.reason,
    this.timeWindow,
    required this.appliesToDriver,
    required this.appliesToPassenger,
  });

  /// Calculează taxa de anulare bazat pe status-ul cursei și timp
  static CancellationPolicy calculatePolicy({
    required String rideStatus,
    required bool isDriver,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    double rideCost = 0.0,
  }) {
    final now = DateTime.now();

    // Anulare gratuită în primele 2 minute după acceptare
    if (acceptedAt != null) {
      final timeSinceAccepted = now.difference(acceptedAt);
      if (timeSinceAccepted.inMinutes <= 2) {
        return const CancellationPolicy(
          isFree: true,
          reason: 'Anulare gratuită în primele 2 minute după acceptare',
          appliesToDriver: true,
          appliesToPassenger: true,
          timeWindow: Duration(minutes: 2),
        );
      }
    }

    // Status: accepted - taxă mică
    if (rideStatus == 'accepted') {
      final fee = (rideCost * 0.05).clamp(3.0, 15.0); // 5% din cost, minim 3 RON, maxim 15 RON
      return CancellationPolicy(
        isFree: false,
        fee: fee,
        reason: 'Taxă de anulare (șoferul a acceptat cursa)',
        appliesToDriver: false, // Șoferul nu plătește
        appliesToPassenger: true,
      );
    }

    // Status: arrived - taxă mai mare
    if (rideStatus == 'arrived') {
      final fee = (rideCost * 0.15).clamp(10.0, 30.0); // 15% din cost, minim 10 RON, maxim 30 RON
      return CancellationPolicy(
        isFree: false,
        fee: fee,
        reason: 'Taxă de anulare (șoferul a ajuns la locația de preluare)',
        appliesToDriver: false,
        appliesToPassenger: true,
      );
    }

    // Status: in_progress - taxă maximă
    if (rideStatus == 'in_progress') {
      final fee = (rideCost * 0.25).clamp(15.0, 50.0); // 25% din cost, minim 15 RON, maxim 50 RON
      return CancellationPolicy(
        isFree: false,
        fee: fee,
        reason: 'Taxă de anulare (cursa a început)',
        appliesToDriver: false,
        appliesToPassenger: true,
      );
    }

    // Anulare gratuită pentru status-uri early
    return const CancellationPolicy(
      isFree: true,
      reason: 'Anulare gratuită (cursa nu a fost acceptată încă)',
      appliesToDriver: true,
      appliesToPassenger: true,
    );
  }

  /// Protecție pentru șoferi - compensație dacă pasagerul anulează
  static double calculateDriverCompensation({
    required String rideStatus,
    required double rideCost,
    required bool passengerCancelled,
  }) {
    if (!passengerCancelled) return 0.0;

    // Șoferul primește compensație dacă pasagerul anulează după ce șoferul a acceptat
    if (rideStatus == 'accepted' || rideStatus == 'arrived') {
      return (rideCost * 0.1).clamp(5.0, 20.0); // 10% din cost
    }

    return 0.0;
  }
}

