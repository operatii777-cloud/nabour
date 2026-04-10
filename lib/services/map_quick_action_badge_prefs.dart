import 'package:shared_preferences/shared_preferences.dart';

/// Marcaje locale pentru badge-uri pe butoanele Cereri / Chat din ecranul harta.
class MapQuickActionBadgePrefs {
  MapQuickActionBadgePrefs._();

  static const cereriFeedOpenedKey = 'map_last_cereri_feed_opened_ms';
  static const nbChatReadKeyPrefix = 'nb_chat_last_read_';

  static Future<void> markCereriFeedOpened() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(
      cereriFeedOpenedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> markNeighborhoodChatRead(String roomId) async {
    if (roomId.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(
      '$nbChatReadKeyPrefix$roomId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
