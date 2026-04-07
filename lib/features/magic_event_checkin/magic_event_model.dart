import 'package:cloud_firestore/cloud_firestore.dart';

/// Merchant map zone event ("Magic Event Check-in").
class MagicEvent {
  final String id;
  final String businessId;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final DateTime startAt;
  final DateTime endAt;
  final String title;
  final String? subtitle;
  final String geohash;
  final bool isActive;
  final int participantCount;

  const MagicEvent({
    required this.id,
    required this.businessId,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.startAt,
    required this.endAt,
    required this.title,
    this.subtitle,
    required this.geohash,
    this.isActive = true,
    this.participantCount = 0,
  });

  factory MagicEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return MagicEvent(
      id: doc.id,
      businessId: data['businessId'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (data['radiusMeters'] as num?)?.toDouble() ??
          (data['radius'] as num?)?.toDouble() ??
          300,
      startAt: (data['startAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endAt: (data['endAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String?,
      geohash: data['geohash'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      participantCount: (data['participantCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'businessId': businessId,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      'geohash': geohash,
      'isActive': isActive,
      'participantCount': participantCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
