import 'package:shared_preferences/shared_preferences.dart';

/// Ascunde local carduri din Activitate (nu există delete server pe feed-ul altora).
class ActivityFeedDismissStore {
  ActivityFeedDismissStore._();

  static const _notifKey = 'activity_notif_dismissed_v1';
  static const _mapFeedKey = 'map_neighbor_activity_dismissed_v1';

  static String notifCompositeKey(String feedOwnerUid, String eventId) =>
      '$feedOwnerUid|$eventId';

  static Future<Set<String>> loadNotifDismissed() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_notifKey)?.toSet() ?? {};
  }

  static Future<void> dismissNotif(String feedOwnerUid, String eventId) async {
    final p = await SharedPreferences.getInstance();
    final set = p.getStringList(_notifKey)?.toSet() ?? {};
    set.add(notifCompositeKey(feedOwnerUid, eventId));
    await p.setStringList(_notifKey, set.toList());
  }

  static Future<void> dismissAllNotif(Iterable<String> compositeKeys) async {
    final keys = compositeKeys.toList();
    if (keys.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final set = p.getStringList(_notifKey)?.toSet() ?? {};
    set.addAll(keys);
    await p.setStringList(_notifKey, set.toList());
  }

  static Future<Set<String>> loadMapFeedDismissed() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_mapFeedKey)?.toSet() ?? {};
  }

  static Future<void> dismissMapFeedRow(String rowId) async {
    final p = await SharedPreferences.getInstance();
    final set = p.getStringList(_mapFeedKey)?.toSet() ?? {};
    set.add(rowId);
    await p.setStringList(_mapFeedKey, set.toList());
  }

  static Future<void> dismissAllMapFeed(Iterable<String> rowIds) async {
    final ids = rowIds.toList();
    if (ids.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final set = p.getStringList(_mapFeedKey)?.toSet() ?? {};
    set.addAll(ids);
    await p.setStringList(_mapFeedKey, set.toList());
  }
}