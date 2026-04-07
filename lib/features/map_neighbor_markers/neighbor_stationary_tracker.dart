import 'package:geolocator/geolocator.dart' as geolocator;

/// Urmărește când utilizatorul stă pe loc (viteză mică + fără deplasare semnificativă).
class NeighborStationaryTracker {
  NeighborStationaryTracker._();
  static final NeighborStationaryTracker instance = NeighborStationaryTracker._();

  DateTime? _since;
  double? _anchorLat;
  double? _anchorLng;

  static const double _speedCutoffMps = 0.9;
  static const double _moveResetM = 28;

  /// Timestamp local (ms) de la care stăm pe loc, sau null dacă ne mișcăm.
  int? touch(geolocator.Position p) {
    if (p.speed >= _speedCutoffMps) {
      _since = null;
      _anchorLat = null;
      _anchorLng = null;
      return null;
    }
    if (_since != null && _anchorLat != null && _anchorLng != null) {
      final moved = geolocator.Geolocator.distanceBetween(
        _anchorLat!,
        _anchorLng!,
        p.latitude,
        p.longitude,
      );
      if (moved > _moveResetM) {
        _since = DateTime.now();
        _anchorLat = p.latitude;
        _anchorLng = p.longitude;
      }
    } else {
      _since = DateTime.now();
      _anchorLat = p.latitude;
      _anchorLng = p.longitude;
    }
    return _since!.millisecondsSinceEpoch;
  }

  void reset() {
    _since = null;
    _anchorLat = null;
    _anchorLng = null;
  }
}
