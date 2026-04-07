import 'package:cloud_firestore/cloud_firestore.dart';

/// Status-ul unui gift ride
enum GiftRideStatus {
  pending,   // Trimis, nereclamat
  claimed,   // Reclamat de destinatar
  expired,   // Expirat
  cancelled, // Anulat de expeditor
}

/// Model pentru cadouri de cursă (gift rides)
class GiftRide {
  final String id;
  final String senderId;
  final String? recipientEmail;
  final String? recipientPhone;
  final String recipientName;
  final double amount; // Valoarea în RON
  final String? message;
  final String code; // Cod unic de revendicare
  final GiftRideStatus status;
  final Timestamp createdAt;
  final Timestamp? claimedAt;
  final Timestamp expiresAt;
  final String? claimedByUserId;

  const GiftRide({
    required this.id,
    required this.senderId,
    this.recipientEmail,
    this.recipientPhone,
    required this.recipientName,
    required this.amount,
    this.message,
    required this.code,
    required this.status,
    required this.createdAt,
    this.claimedAt,
    required this.expiresAt,
    this.claimedByUserId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      if (recipientEmail != null) 'recipientEmail': recipientEmail,
      if (recipientPhone != null) 'recipientPhone': recipientPhone,
      'recipientName': recipientName,
      'amount': amount,
      if (message != null) 'message': message,
      'code': code,
      'status': status.name,
      'createdAt': createdAt,
      if (claimedAt != null) 'claimedAt': claimedAt,
      'expiresAt': expiresAt,
      if (claimedByUserId != null) 'claimedByUserId': claimedByUserId,
    };
  }

  factory GiftRide.fromMap(Map<String, dynamic> map) {
    return GiftRide(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      recipientEmail: map['recipientEmail'],
      recipientPhone: map['recipientPhone'],
      recipientName: map['recipientName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      message: map['message'],
      code: map['code'] ?? '',
      status: GiftRideStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => GiftRideStatus.pending,
      ),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      claimedAt: map['claimedAt'],
      expiresAt: map['expiresAt'] ?? Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 365)),
      ),
      claimedByUserId: map['claimedByUserId'],
    );
  }

  /// Verifică dacă gift ride-ul este valid (neclamat și neexpirat)
  bool get isValid {
    if (status == GiftRideStatus.claimed ||
        status == GiftRideStatus.cancelled) {
      return false;
    }
    return DateTime.now().isBefore(expiresAt.toDate());
  }

  GiftRide copyWith({
    String? id,
    String? senderId,
    String? recipientEmail,
    String? recipientPhone,
    String? recipientName,
    double? amount,
    String? message,
    String? code,
    GiftRideStatus? status,
    Timestamp? createdAt,
    Timestamp? claimedAt,
    Timestamp? expiresAt,
    String? claimedByUserId,
  }) {
    return GiftRide(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientName: recipientName ?? this.recipientName,
      amount: amount ?? this.amount,
      message: message ?? this.message,
      code: code ?? this.code,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      claimedAt: claimedAt ?? this.claimedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      claimedByUserId: claimedByUserId ?? this.claimedByUserId,
    );
  }
}
