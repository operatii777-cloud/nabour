import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistă local lista de UID-uri excluse de la vizibilitate.
/// "Exclude" = acel contact NU mă poate vedea pe hartă.
class VisibilityPreferencesService {
  static const _key = 'visibility_excluded_uids';

  Future<Set<String>> loadExcludedUids() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> saveExcludedUids(Set<String> uids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(uids.toList()));
  }
}
