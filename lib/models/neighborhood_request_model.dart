import 'package:cloud_firestore/cloud_firestore.dart';

class NeighborhoodRequest {
  final String id;
  final String authorUid;
  final String authorName;
  final String type; // 'ride', 'help', 'tool', 'alert'
  final String message;
  final double lat;
  final double lng;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool resolved;

  NeighborhoodRequest({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.type,
    required this.message,
    required this.lat,
    required this.lng,
    required this.createdAt,
    required this.expiresAt,
    this.resolved = false,
  });

  factory NeighborhoodRequest.fromMap(String id, Map<String, dynamic> data) {
    return NeighborhoodRequest(
      id: id,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? 'Vecin',
      type: data['type'] ?? 'help',
      message: data['message'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 1)),
      resolved: data['resolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'type': type,
      'message': message,
      'lat': lat,
      'lng': lng,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'resolved': resolved,
    };
  }

  // A helper method to calculate the remaining lifespan
  // 1.0 = brand new, 0.0 = expired
  double get evaporationProgress {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0.0;
    
    final totalDuration = expiresAt.difference(createdAt).inSeconds;
    if (totalDuration <= 0) return 0.0;
    
    final elapsed = now.difference(createdAt).inSeconds;
    final remaining = 1.0 - (elapsed / totalDuration);
    
    return remaining.clamp(0.0, 1.0);
  }
}
