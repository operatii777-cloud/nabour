import 'package:shared_preferences/shared_preferences.dart';

/// Preferințe pentru notificările locale „prieten aproape” (hartă socială).
class NearbySocialNotificationsPrefs {
  NearbySocialNotificationsPrefs._();
  static final NearbySocialNotificationsPrefs instance =
      NearbySocialNotificationsPrefs._();

  static const _kEnabled = 'nearby_friend_notify_enabled';
  static const _kRadius = 'nearby_friend_notify_radius_m';

  bool _enabled = true;
  int _radiusM = 500;
  bool _loaded = false;

  bool get enabled => !_loaded || _enabled;
  int get radiusM => _radiusM;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _enabled = p.getBool(_kEnabled) ?? true;
    _radiusM = p.getInt(_kRadius) ?? 500;
    if (_radiusM < 100) _radiusM = 100;
    if (_radiusM > 2000) _radiusM = 2000;
    _loaded = true;
  }

  Future<void> setEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, v);
    _enabled = v;
    _loaded = true;
  }

  Future<void> setRadiusM(int meters) async {
    final m = meters.clamp(100, 2000);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kRadius, m);
    _radiusM = m;
    _loaded = true;
  }
}
