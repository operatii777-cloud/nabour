import 'package:cloud_firestore/cloud_firestore.dart';

/// A short-lived "moment" posted by a user on the map — visible nearby
/// until `expiresAt` (implicit default: 30 minutes after post).
class MapMoment {
  final String id;
  final String authorUid;
  final String authorName;
  final String authorAvatar;
  final double lat;
  final double lng;
  final String caption;
  final String? emoji;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> reactions;

  const MapMoment({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorAvatar,
    required this.lat,
    required this.lng,
    required this.caption,
    this.emoji,
    this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    this.reactions = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory MapMoment.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    final created =
        (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final expires = (m['expiresAt'] as Timestamp?)?.toDate() ??
        created.add(const Duration(minutes: 30));
    return MapMoment(
      id: doc.id,
      authorUid: m['authorUid'] as String? ?? '',
      authorName: m['authorName'] as String? ?? 'Vecin',
      authorAvatar: m['authorAvatar'] as String? ?? '🙂',
      lat: (m['lat'] as num?)?.toDouble() ?? 0,
      lng: (m['lng'] as num?)?.toDouble() ?? 0,
      caption: m['caption'] as String? ?? '',
      emoji: m['emoji'] as String?,
      imageUrl: m['imageUrl'] as String?,
      createdAt: created,
      expiresAt: expires,
      reactions: (m['reactions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'authorUid': authorUid,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'lat': lat,
        'lng': lng,
        'caption': caption,
        if (emoji != null) 'emoji': emoji,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'reactions': reactions,
      };
}
