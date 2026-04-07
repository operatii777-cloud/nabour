import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String? id;
  final String userId;
  final String? rideId; // Opțional, pentru a lega tichetul de o cursă
  final String reportType; // ex: 'Obiect Pierdut', 'Incident'
  final String message;
  final Timestamp timestamp;
  final String status; // 'nou', 'în progres', 'rezolvat'

  SupportTicket({
    this.id,
    required this.userId,
    this.rideId,
    required this.reportType,
    required this.message,
    required this.timestamp,
    this.status = 'nou',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rideId': rideId,
      'reportType': reportType,
      'message': message,
      'timestamp': timestamp,
      'status': status,
    };
  }
}