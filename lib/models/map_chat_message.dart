import 'package:cloud_firestore/cloud_firestore.dart';

/// Mesaj de chat afișat ca speech-bubble pe hartă.
/// Colecție Firestore: `map_chat_sessions/{chatId}/messages/{msgId}`
/// TTL scurt (~5 min) — mesajele expirate se șterg via Cloud Function sau client-side filter.
class MapChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderAvatarEmoji;
  final String text;
  final DateTime timestamp;
  final DateTime expiresAt;

  const MapChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarEmoji,
    required this.text,
    required this.timestamp,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory MapChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return MapChatMessage(
      id: doc.id,
      chatId: d['chatId'] as String? ?? '',
      senderId: d['senderId'] as String? ?? '',
      senderName: d['senderName'] as String? ?? 'User',
      senderAvatarEmoji: d['senderAvatarEmoji'] as String? ?? '🙂',
      text: d['text'] as String? ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatarEmoji': senderAvatarEmoji,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };

  /// ChatId pentru chat 1:1 — sortăm uid-urile pentru a fi determinist.
  static String chatIdFor1to1(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}

/// Starea de typing pentru un user într-un chat pe hartă.
/// Colecție Firestore: `map_chat_typing/{chatId}_{userId}`
class MapChatTypingIndicator {
  final String userId;
  final String chatId;
  final bool isTyping;
  final DateTime updatedAt;

  const MapChatTypingIndicator({
    required this.userId,
    required this.chatId,
    required this.isTyping,
    required this.updatedAt,
  });

  factory MapChatTypingIndicator.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return MapChatTypingIndicator(
      userId: d['userId'] as String? ?? '',
      chatId: d['chatId'] as String? ?? '',
      isTyping: d['isTyping'] as bool? ?? false,
      updatedAt:
          (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'chatId': chatId,
        'isTyping': isTyping,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Typing-ul expiră după 5s fără update.
  bool get isStale =>
      DateTime.now().difference(updatedAt) > const Duration(seconds: 5);
}
