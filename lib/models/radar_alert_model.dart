import 'package:cloud_firestore/cloud_firestore.dart';

enum RadarAlertType {
  police,
  radar,
  accident,
  hazard,
  other
}

class RadarAlert {
  final String id;
  final String senderUid;
  final String senderName;
  final String message;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final RadarAlertType type;

  RadarAlert({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.type = RadarAlertType.radar,
  });

  factory RadarAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RadarAlert(
      id: doc.id,
      senderUid: data['senderUid'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: _parseType(data['type']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderUid': senderUid,
      'senderName': senderName,
      'message': message,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.name,
    };
  }

  static RadarAlertType _parseType(String? type) {
    return RadarAlertType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => RadarAlertType.radar,
    );
  }
}
