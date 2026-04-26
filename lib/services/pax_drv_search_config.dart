/// Raze de cautare sofer pentru pasager: doar driver_locations cu isOnline == true
/// (comutator disponibil ca sofer) si intersectat cu allowedDriverUids (contacte in app + prieteni).
class PassengerDriverSearchConfig {
  PassengerDriverSearchConfig._();

  static const double initialRadiusKm = 20.0;
  static const double extendedRadiusKm = 20.0;
  static const double expandStepKm = 5.0;
  static const double maxRadiusKm = 20.0;
}
