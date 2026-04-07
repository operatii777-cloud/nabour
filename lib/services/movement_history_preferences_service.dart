import 'package:shared_preferences/shared_preferences.dart';

class MovementHistoryPreferencesService {
  MovementHistoryPreferencesService._();
  static final MovementHistoryPreferencesService instance =
      MovementHistoryPreferencesService._();

  static const String _kEnabledKey = 'movement_history_enabled';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, value);
  }
}
