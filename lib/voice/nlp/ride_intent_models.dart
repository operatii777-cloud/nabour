enum RideIntentType {
  rideRequest,          // "Vreau o cursă la aeroport"
  changeDestination,    // "Schimbă destinația la gară"
  addStop,              // "Adaugă o oprire la mall"
  cancelRide,           // "Anulează cursa"
  confirm,              // "Da", "Ok", "Perfect"
  reject,               // "Nu", "Nu mai vreau"
  statusQuestion,       // "Unde este șoferul?", "Cât mai durează?"
  paymentQuestion,      // "Cum plătesc?", "E cash sau card?"
  smallTalk,            // "Mulțumesc", "Bună"
  greeting,             // "Salut"
  helpQuestion,         // "Ce poți să faci?", "Cum comand o cursă?"
  appInfo,              // "Ce este Nabour?"
  unknown,              // Nu suntem siguri ce vrea
}

class RideIntent {
  final RideIntentType type;
  final String? rawText;          // textul original
  final String? normalizedText;   // text normalizat
  final String? destinationText;  // ex: "aeroport", "gara"
  final String? extraStopText;    // pentru addStop
  final bool requiresConfirmation;
  final bool handledLocally;      // true = nu am folosit Gemini
  final double confidence;        // scor de încredere

  const RideIntent({
    required this.type,
    this.rawText,
    this.normalizedText,
    this.destinationText,
    this.extraStopText,
    this.requiresConfirmation = false,
    this.handledLocally = true,
    this.confidence = 0.0,
  });

  @override
  String toString() {
    return 'RideIntent(type: $type, destination: $destinationText, local: $handledLocally, conf: $confidence)';
  }
}
