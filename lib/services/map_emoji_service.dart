import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/utils/logger.dart';

/// Mapbox poate randa U+2764 fără VS ca simbol negru; forțăm prezentarea emoji.
String normalizeMapEmojiForEngine(String emoji) {
  final s = emoji.trim();
  if (s.isEmpty) return s;
  final runes = s.runes.toList();
  if (runes.length == 1 && runes.first == 0x2764) {
    return '\u2764\uFE0F';
  }
  return s;
}

class MapEmoji {
  final String id;
  final double lat;
  final double lng;
  final String emoji;
  final DateTime timestamp;
  final String senderId;

  MapEmoji({
    required this.id,
    required this.lat,
    required this.lng,
    required this.emoji,
    required this.timestamp,
    required this.senderId,
  });

  factory MapEmoji.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['timestamp'];
    if (ts is! Timestamp) {
      throw StateError('map_emoji ${doc.id}: missing timestamp');
    }
    final senderId = (data['senderId'] as String?) ?? '';
    // Cheie stabilă pentru marker: același user = același punct pe hartă (inclusiv doc-uri vechi cu id random).
    final stableId = senderId.isNotEmpty ? senderId : doc.id;
    return MapEmoji(
      id: stableId,
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      emoji: normalizeMapEmojiForEngine(data['emoji'] as String? ?? '😊'),
      timestamp: ts.toDate(),
      senderId: senderId,
    );
  }
}

class MapEmojiService {
  static final MapEmojiService _instance = MapEmojiService._();
  factory MapEmojiService() => _instance;
  MapEmojiService._();

  /// Documentele sunt șterse automat de Firestore TTL pe câmpul [MapEmojiService.expireAtField].
  static const Duration emojiTtl = Duration(minutes: 30);
  static const String expireAtField = 'expireAt';

  final _db = FirebaseFirestore.instance.collection('map_emojis');

  /// Plasează / actualizează reacția ta pe hartă (un singur doc per `senderId` → același marker se schimbă).
  /// Returnează `senderId` ca id stabil pentru UI (înainte de snapshot).
  Future<String?> addEmoji({
    required double lat,
    required double lng,
    required String emoji,
    required String senderId,
  }) async {
    try {
      // Timestamp client (nu serverTimestamp): e valabil imediat în query-uri cu inequality;
      // serverTimestamp rămâne deseori null în cache până la commit → documentul nu apare în stream.
      final placedAt = DateTime.now();
      final t = Timestamp.fromDate(placedAt);
      final expireAt = Timestamp.fromDate(placedAt.add(emojiTtl));
      final normalized = normalizeMapEmojiForEngine(emoji);
      await _db.doc(senderId).set(
            {
              'lat': lat,
              'lng': lng,
              'emoji': normalized,
              'senderId': senderId,
              'timestamp': t,
              expireAtField: expireAt,
            },
            SetOptions(merge: true),
          );
      Logger.info('Set map emoji: $normalized at ($lat, $lng) → doc $senderId', tag: 'EMOJI');
      return senderId;
    } catch (e) {
      Logger.error('Error adding map emoji: $e', tag: 'EMOJI');
      rethrow;
    }
  }

  /// Șterge documentul tău din `map_emojis` — emoji-ul dispare pentru toți vecinii.
  Future<void> removeMyEmoji(String senderId) async {
    if (senderId.isEmpty) return;
    try {
      await _db.doc(senderId).delete();
      Logger.info('Removed map emoji doc for $senderId', tag: 'EMOJI');
    } catch (e) {
      Logger.error('Error removing map emoji: $e', tag: 'EMOJI');
      rethrow;
    }
  }

  /// Emoji-uri încă valide: `expireAt` în viitor (TTL server șterge documentul la expirare).
  /// Fără `orderBy` pe server — evită index compus; sortăm local după timestamp.
  Stream<List<MapEmoji>> listenToRecentEmojis() {
    final now = Timestamp.fromDate(DateTime.now());
    return _db.where(expireAtField, isGreaterThan: now).snapshots().map((snap) {
      final bySender = <String, MapEmoji>{};
      for (final doc in snap.docs) {
        try {
          final m = MapEmoji.fromFirestore(doc);
          final key = m.senderId.isNotEmpty ? m.senderId : m.id;
          final prev = bySender[key];
          if (prev == null || m.timestamp.isAfter(prev.timestamp)) {
            bySender[key] = m;
          }
        } catch (e) {
          Logger.warning('Skip map_emoji doc: $e', tag: 'EMOJI');
        }
      }
      final out = bySender.values.toList();
      out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return out;
    });
  }
}
