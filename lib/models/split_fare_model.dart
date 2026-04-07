import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a split-fare request between a ride initiator and one
/// or more participants. No real payment is processed — the model simply
/// tracks who owes what so everyone can settle up outside the app.
class SplitFare {
  final String id;
  final String rideId;
  final String initiatorId;

  /// List of participant objects: {email, userId?, amountOwed, hasPaid}
  final List<Map<String, dynamic>> participants;
  final double amountPerPerson;

  /// Overall status: 'pending' | 'partial' | 'settled'
  final String status;
  final DateTime createdAt;

  const SplitFare({
    required this.id,
    required this.rideId,
    required this.initiatorId,
    required this.participants,
    required this.amountPerPerson,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'initiatorId': initiatorId,
      'participants': participants,
      'amountPerPerson': amountPerPerson,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SplitFare.fromMap(String id, Map<String, dynamic> map) {
    return SplitFare(
      id: id,
      rideId: map['rideId'] as String? ?? '',
      initiatorId: map['initiatorId'] as String? ?? '',
      participants: List<Map<String, dynamic>>.from(
        (map['participants'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      ),
      amountPerPerson: (map['amountPerPerson'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory SplitFare.fromFirestore(DocumentSnapshot doc) {
    return SplitFare.fromMap(
        doc.id, doc.data() as Map<String, dynamic>? ?? {});
  }

  SplitFare copyWith({
    String? rideId,
    String? initiatorId,
    List<Map<String, dynamic>>? participants,
    double? amountPerPerson,
    String? status,
    DateTime? createdAt,
  }) {
    return SplitFare(
      id: id,
      rideId: rideId ?? this.rideId,
      initiatorId: initiatorId ?? this.initiatorId,
      participants: participants ?? this.participants,
      amountPerPerson: amountPerPerson ?? this.amountPerPerson,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
