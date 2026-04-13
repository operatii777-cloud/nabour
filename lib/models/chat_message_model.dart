import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  system,
  location,
  quickReply,
  voice,
  image,
  gif,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

class ChatMessage {
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final Timestamp? editedAt;
  final bool isEdited;
  final MessageType type;
  final MessageStatus status;
  final Timestamp? readAt;
  final Timestamp? deliveredAt;
  final Map<String, dynamic>? locationData; // Pentru mesaje cu locație
  final String? quickReplyId; // ID pentru mesaje rapide
  final String? voiceUrl; // URL pentru voice messages (Firebase Storage)
  final int? voiceDuration; // Durata în secunde pentru voice messages
  final String? imageUrl; // URL pentru imagini (Firebase Storage)
  final String? gifUrl; // URL pentru GIF-uri (Giphy sau Firebase Storage)
  final String? gifId; // ID pentru GIF-uri de la Giphy
  final String? translatedText;
  final String? replyToText;       // textul mesajului la care se răspunde
  final String? replyToSenderId;   // uid-ul expeditorului mesajului citat
  final Map<String, String> reactions; // uid -> emoji
  /// URL poză profil la trimitere (opțional).
  final String? senderPhotoUrl;
  /// Emoji avatar aplicație la trimitere (fallback vizual).
  final String? senderAvatarEmoji;

  ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.editedAt,
    this.isEdited = false,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.readAt,
    this.deliveredAt,
    this.locationData,
    this.quickReplyId,
    this.voiceUrl,
    this.voiceDuration,
    this.imageUrl,
    this.gifUrl,
    this.gifId,
    this.translatedText,
    this.replyToText,
    this.replyToSenderId,
    this.reactions = const {},
    this.senderPhotoUrl,
    this.senderAvatarEmoji,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      if (editedAt != null) 'editedAt': editedAt,
      'isEdited': isEdited,
      'type': type.name,
      'status': status.name,
      if (readAt != null) 'readAt': readAt,
      if (deliveredAt != null) 'deliveredAt': deliveredAt,
      if (locationData != null) 'locationData': locationData,
      if (quickReplyId != null) 'quickReplyId': quickReplyId,
      if (voiceUrl != null) 'voiceUrl': voiceUrl,
      if (voiceDuration != null) 'voiceDuration': voiceDuration,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (gifUrl != null) 'gifUrl': gifUrl,
      if (gifId != null) 'gifId': gifId,
      if (translatedText != null) 'translatedText': translatedText,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
      if (reactions.isNotEmpty) 'reactions': reactions,
      if (senderPhotoUrl != null && senderPhotoUrl!.trim().isNotEmpty)
        'senderPhotoUrl': senderPhotoUrl!.trim(),
      if (senderAvatarEmoji != null && senderAvatarEmoji!.trim().isNotEmpty)
        'senderAvatarEmoji': senderAvatarEmoji!.trim(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      editedAt: map['editedAt'],
      isEdited: map['isEdited'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      readAt: map['readAt'],
      deliveredAt: map['deliveredAt'],
      locationData: map['locationData'] != null
          ? Map<String, dynamic>.from(map['locationData'])
          : null,
      quickReplyId: map['quickReplyId'],
      voiceUrl: map['voiceUrl'],
      voiceDuration: map['voiceDuration'],
      imageUrl: map['imageUrl'],
      gifUrl: map['gifUrl'],
      gifId: map['gifId'],
      translatedText: map['translatedText'],
      replyToText: map['replyToText'] as String?,
      replyToSenderId: map['replyToSenderId'] as String?,
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      senderPhotoUrl: map['senderPhotoUrl'] as String?,
      senderAvatarEmoji: map['senderAvatarEmoji'] as String?,
    );
  }

  ChatMessage copyWith({
    String? senderId,
    String? text,
    Timestamp? timestamp,
    Timestamp? editedAt,
    bool? isEdited,
    MessageType? type,
    MessageStatus? status,
    Timestamp? readAt,
    Timestamp? deliveredAt,
    Map<String, dynamic>? locationData,
    String? quickReplyId,
    String? voiceUrl,
    int? voiceDuration,
    String? imageUrl,
    String? gifUrl,
    String? gifId,
    String? translatedText,
    String? replyToText,
    String? replyToSenderId,
    Map<String, String>? reactions,
    String? senderPhotoUrl,
    String? senderAvatarEmoji,
  }) {
    return ChatMessage(
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      type: type ?? this.type,
      status: status ?? this.status,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      locationData: locationData ?? this.locationData,
      quickReplyId: quickReplyId ?? this.quickReplyId,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      imageUrl: imageUrl ?? this.imageUrl,
      gifUrl: gifUrl ?? this.gifUrl,
      gifId: gifId ?? this.gifId,
      translatedText: translatedText ?? this.translatedText,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      reactions: reactions ?? this.reactions,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      senderAvatarEmoji: senderAvatarEmoji ?? this.senderAvatarEmoji,
    );
  }
}