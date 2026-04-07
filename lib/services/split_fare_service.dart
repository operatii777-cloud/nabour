import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/split_fare_model.dart';

/// Service for managing split-fare requests.
///
/// No real payment processing is performed — the service simply writes
/// tracking documents to the `split_fares` Firestore collection so that
/// participants know how much they owe.
class SplitFareService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  SplitFareService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Creates a new split-fare document and returns its ID.
  ///
  /// [rideId] — the Firestore ride document ID.
  /// [contactEmails] — list of participant e-mail addresses to split with.
  /// [totalAmount] — total ride cost to be divided equally.
  Future<String> initiateSplit(
    String rideId,
    List<String> contactEmails,
    double totalAmount,
  ) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');
    if (contactEmails.isEmpty) {
      throw ArgumentError('At least one contact email is required');
    }

    // Total people = initiator + contacts
    final totalPeople = contactEmails.length + 1;
    final amountPerPerson = totalAmount / totalPeople;

    final participants = contactEmails
        .map((email) => {
              'email': email,
              'amountOwed': amountPerPerson,
              'hasPaid': false,
            })
        .toList();

    final splitFare = SplitFare(
      id: '',
      rideId: rideId,
      initiatorId: uid,
      participants: participants,
      amountPerPerson: amountPerPerson,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final docRef = await _db.collection('split_fares').add(splitFare.toMap());
    return docRef.id;
  }

  /// Marks a participant as having paid their share.
  ///
  /// [splitId] — ID of the split_fare document.
  /// [userId] — the user's Firebase UID.
  /// [email] — the user's email (used to locate the participant when the
  ///   userId has not yet been stored against the participant entry).
  Future<void> acceptSplit(String splitId, String userId,
      {String? email}) async {
    final docRef = _db.collection('split_fares').doc(splitId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception('Split fare not found: $splitId');

    final splitFare = SplitFare.fromFirestore(doc);

    bool matched = false;
    final updatedParticipants = splitFare.participants.map((p) {
      // Match first by stored userId, then by email if provided
      final bool isMatch = p['userId'] == userId ||
          (email != null &&
              p['email'] != null &&
              (p['email'] as String).toLowerCase() == email.toLowerCase() &&
              p['userId'] == null);
      if (isMatch && !matched) {
        matched = true;
        return {...p, 'hasPaid': true, 'userId': userId};
      }
      return p;
    }).toList();

    final allPaid = updatedParticipants.every((p) => p['hasPaid'] == true);
    final anyPaid = updatedParticipants.any((p) => p['hasPaid'] == true);
    final newStatus = allPaid
        ? 'settled'
        : anyPaid
            ? 'partial'
            : 'pending';

    await docRef.update({
      'participants': updatedParticipants,
      'status': newStatus,
    });
  }

  /// Returns a stream of the split-fare documents for a given ride.
  Stream<List<SplitFare>> getSplitStatus(String rideId) {
    return _db
        .collection('split_fares')
        .where('rideId', isEqualTo: rideId)
        .snapshots()
        .map((snap) =>
            snap.docs.map(SplitFare.fromFirestore).toList());
  }

  /// Convenience method to get the latest split for a ride as a one-shot
  /// future (returns null if none exists).
  Future<SplitFare?> getLatestSplit(String rideId) async {
    final snap = await _db
        .collection('split_fares')
        .where('rideId', isEqualTo: rideId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return SplitFare.fromFirestore(snap.docs.first);
  }
}
