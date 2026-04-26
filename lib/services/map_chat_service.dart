import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/map_chat_message.dart';

/// Durata de viată a unui mesaj pe hartă (bula dispare după 60s, mesajul e păstrat 5min).
const Duration _kBubbleTtl = Duration(seconds: 60);
const Duration _kMessageStoreTtl = Duration(minutes: 5);

/// Serviciu Firestore pentru chat-ul vizibil pe hartă (speech-bubble + mini-monitor).
///
/// Structura Firestore:
///   `map_chat_sessions/{chatId}/messages/{msgId}` — mesajele
///   `map_chat_typing/{chatId}_{userId}` — indicatori typing (doc per user)
class MapChatService {
  MapChatService._();
  static final MapChatService instance = MapChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Trimitere mesaj ────────────────────────────────────────────────────────

  /// Trimite un mesaj text într-un chat pe hartă.
  /// [peerUid] — uid-ul destinatarului (pentru chat 1:1).
  /// [text] — textul mesajului.
  /// [senderName] / [senderAvatarEmoji] — datele vizuale ale sender-ului.
  Future<void> sendMessage({
    required String peerUid,
    required String text,
    required String senderName,
    required String senderAvatarEmoji,
  }) async {
    final me = _auth.currentUser;
    if (me == null || text.trim().isEmpty) return;

    final chatId = MapChatMessage.chatIdFor1to1(me.uid, peerUid);
    final now = DateTime.now();
    final msg = MapChatMessage(
      id: '',
      chatId: chatId,
      senderId: me.uid,
      senderName: senderName,
      senderAvatarEmoji: senderAvatarEmoji,
      text: text.trim(),
      timestamp: now,
      expiresAt: now.add(_kMessageStoreTtl),
    );

    await _db
        .collection('map_chat_sessions')
        .doc(chatId)
        .collection('messages')
        .add(msg.toMap());

    // Oprește typing indicator la trimitere.
    await setTyping(chatId: chatId, isTyping: false);
  }

  // ─── Stream mesaje ──────────────────────────────────────────────────────────

  /// Stream de mesaje recente (ultimele 5min) pentru un chatId.
  /// Filtrăm și client-side mesajele expirate.
  Stream<List<MapChatMessage>> messagesStream(String chatId) {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(_kMessageStoreTtl),
    );
    return _db
        .collection('map_chat_sessions')
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isGreaterThan: cutoff)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MapChatMessage.fromDoc(d))
            .where((m) => !m.isExpired)
            .toList());
  }

  /// Stream pentru bulele active ale unui user specific (ultimul mesaj trimis de el).
  /// Util pentru a afișa bula deasupra avatarului lui pe hartă.
  Stream<MapChatMessage?> latestBubbleForUser({
    required String chatId,
    required String userId,
  }) {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(_kBubbleTtl));
    return _db
        .collection('map_chat_sessions')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .where('timestamp', isGreaterThan: cutoff)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final msg = MapChatMessage.fromDoc(snap.docs.first);
      return msg.isExpired ? null : msg;
    });
  }

  // ─── Typing indicator ───────────────────────────────────────────────────────

  /// Actualizează starea de typing în Firestore.
  /// Documentul expiră natural după 5s fără update (verificat client-side via [MapChatTypingIndicator.isStale]).
  Future<void> setTyping({
    required String chatId,
    required bool isTyping,
  }) async {
    final me = _auth.currentUser;
    if (me == null) return;
    final docId = '${chatId}_${me.uid}';
    await _db.collection('map_chat_typing').doc(docId).set({
      'userId': me.uid,
      'chatId': chatId,
      'isTyping': isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream de typing indicator pentru un user specific.
  Stream<bool> typingStream({
    required String chatId,
    required String userId,
  }) {
    final docId = '${chatId}_$userId';
    return _db
        .collection('map_chat_typing')
        .doc(docId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return false;
      final ind = MapChatTypingIndicator.fromDoc(snap);
      return ind.isTyping && !ind.isStale;
    });
  }

  // ─── Curățare ───────────────────────────────────────────────────────────────

  /// Șterge mesajele expirate din chatId (apelat ocazional la deschiderea chat-ului).
  Future<void> cleanupExpired(String chatId) async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(_kMessageStoreTtl),
    );
    final old = await _db
        .collection('map_chat_sessions')
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isLessThan: cutoff)
        .get();
    final batch = _db.batch();
    for (final doc in old.docs) {
      batch.delete(doc.reference);
    }
    if (old.docs.isNotEmpty) await batch.commit();
  }
}
