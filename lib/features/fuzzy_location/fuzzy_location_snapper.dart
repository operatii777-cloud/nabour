/// Snaps coordinates to a coarse grid so that the published location reveals
/// the approximate neighborhood rather than the exact address.
///
/// Grid cell ≈ 110 m × 85 m at Romanian latitudes (≈ 0.001° lat × 0.001° lng).
/// The resulting coordinate is the center of the cell.
class FuzzyLocationSnapper {
  FuzzyLocationSnapper._();

  /// Default grid step in degrees (≈ 110 m N-S, ~85 m E-W at 44°N).
  static const double defaultStep = 0.001;

  /// Returns (lat, lng) snapped to the center of the grid cell.
  static ({double lat, double lng}) snap(
    double lat,
    double lng, {
    double step = defaultStep,
  }) {
    final sLat = (_roundToStep(lat, step) + step / 2);
    final sLng = (_roundToStep(lng, step) + step / 2);
    return (lat: sLat, lng: sLng);
  }

  /// Apply a deterministic per-user jitter so friends in the same cell don't
  /// overlap on the exact same pixel.  The jitter stays constant for a given
  /// uid + cell, so it doesn't jump every publish.
  static ({double lat, double lng}) snapWithJitter(
    double lat,
    double lng,
    String uid, {
    double step = defaultStep,
  }) {
    final base = snap(lat, lng, step: step);
    final hash = uid.hashCode;
    final jLat = ((hash % 97) / 97.0 - 0.5) * step * 0.45;
    final jLng = (((hash ~/ 97) % 97) / 97.0 - 0.5) * step * 0.45;
    return (lat: base.lat + jLat, lng: base.lng + jLng);
  }

  static double _roundToStep(double value, double step) {
    return (value / step).floorToDouble() * step;
  }
}
