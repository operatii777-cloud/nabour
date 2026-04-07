import 'package:flutter/foundation.dart';

/// Rezultat cand [SearchingForDriverScreen] se inchide (in locul unui ecran separat pentru pasager).
class PassengerSearchFlowResult {
  final String rideId;
  final bool shouldOpenSummary;

  const PassengerSearchFlowResult({
    required this.rideId,
    this.shouldOpenSummary = false,
  });
}

/// Evenimente pentru harta principala cand pasagerul are cursa activa.
class PassengerRideServiceBus {
  PassengerRideServiceBus._();

  static final ValueNotifier<PassengerSearchFlowResult?> pending =
      ValueNotifier<PassengerSearchFlowResult?>(null);

  static void emit(PassengerSearchFlowResult result) {
    pending.value = result;
  }
}