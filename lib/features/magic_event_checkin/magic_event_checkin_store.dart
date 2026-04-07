import 'package:shared_preferences/shared_preferences.dart';

/// Local uniqueness for Magic Event presence UX until server-side check-in exists.
class MagicEventCheckinStore {
  MagicEventCheckinStore._();
  static final MagicEventCheckinStore instance = MagicEventCheckinStore._();

  static const String _key = 'magic_event_checkin_ids_v1';

  Future<Set<String>> load() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key);
    return list?.toSet() ?? {};
  }

  Future<void> add(String eventId) async {
    final p = await SharedPreferences.getInstance();
    final list = [...(p.getStringList(_key) ?? <String>[])];
    if (!list.contains(eventId)) {
      list.add(eventId);
      await p.setStringList(_key, list);
    }
  }

  Future<void> clearForTesting() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
