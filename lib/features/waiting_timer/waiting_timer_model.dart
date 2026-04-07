/// Modelul stării timer-ului de așteptare.
class WaitingTimerState {
  final bool isActive;
  final int elapsedSeconds;       // secunde scurse total
  final int freeWaitingSeconds;   // secunde gratuite (implicit 120 = 2 min)
  final double chargePerMinute;   // RON/minut după perioada gratuită (implicit 0.50)
  final double currentCharge;     // taxa acumulată curentă (RON)

  const WaitingTimerState({
    this.isActive = false,
    this.elapsedSeconds = 0,
    this.freeWaitingSeconds = 120,
    this.chargePerMinute = 0.50,
    this.currentCharge = 0.0,
  });

  bool get isFreeWaitingExpired => elapsedSeconds > freeWaitingSeconds;

  int get chargeableSeconds =>
      isFreeWaitingExpired ? elapsedSeconds - freeWaitingSeconds : 0;

  int get remainingFreeSeconds =>
      isFreeWaitingExpired ? 0 : freeWaitingSeconds - elapsedSeconds;

  String get formattedElapsed {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  WaitingTimerState copyWith({
    bool? isActive,
    int? elapsedSeconds,
    double? currentCharge,
  }) =>
      WaitingTimerState(
        isActive: isActive ?? this.isActive,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        freeWaitingSeconds: freeWaitingSeconds,
        chargePerMinute: chargePerMinute,
        currentCharge: currentCharge ?? this.currentCharge,
      );
}
