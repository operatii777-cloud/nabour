enum CancellationReason {
  passengerNotFound,       // Pasagerul nu a putut fi găsit
  passengerNotResponding,  // Pasagerul nu răspunde
  wrongAddress,            // Adresă greșită
  vehicleIssue,            // Problemă cu vehiculul
  emergencyPersonal,       // Urgență personală
  other,                   // Alt motiv
}

extension CancellationReasonLabel on CancellationReason {
  String get label {
    switch (this) {
      case CancellationReason.passengerNotFound:
        return 'Pasagerul nu a putut fi găsit';
      case CancellationReason.passengerNotResponding:
        return 'Pasagerul nu răspunde';
      case CancellationReason.wrongAddress:
        return 'Adresă greșită';
      case CancellationReason.vehicleIssue:
        return 'Problemă cu vehiculul';
      case CancellationReason.emergencyPersonal:
        return 'Urgență personală';
      case CancellationReason.other:
        return 'Alt motiv';
    }
  }
}

class CancellationStats {
  final int totalRides;
  final int cancelledRides;
  final double cancellationRate; // 0.0 - 1.0

  const CancellationStats({
    required this.totalRides,
    required this.cancelledRides,
    required this.cancellationRate,
  });

  bool get hasWarning => cancellationRate > 0.10; // >10%
  bool get isSuspended => cancellationRate > 0.25; // >25%
}
