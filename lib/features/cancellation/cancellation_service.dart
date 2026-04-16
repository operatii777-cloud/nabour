import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/utils/logger.dart';
import 'cancellation_model.dart';

/// Serviciu care înregistrează anulările și calculează rata.
class CancellationService {
  static final CancellationService _instance = CancellationService._();
  factory CancellationService() => _instance;
  CancellationService._();

  static const String _tag = 'CANCELLATION';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Înregistrează o anulare din partea șoferului.
  Future<void> recordDriverCancellation(
    String rideId,
    CancellationReason reason,
  ) async {
    if (_uid.isEmpty) return;
    try {
      final batch = _db.batch();

      // Cursa activă e în `ride_requests/{rideId}`; nu scriem în `rides/` (alt model + reguli).
      // Refuzul pe documentul cursei face FirestoreService.declineRide (declinedBy).

      // 1. Incrementează contorul de anulări al șoferului
      batch.update(_db.collection('users').doc(_uid), {
        'cancellationCount': FieldValue.increment(1),
        'lastCancellationAt': FieldValue.serverTimestamp(),
      });

      // 2. Log în subcollecție pentru audit (reguli: users/{uid}/cancellations)
      batch.set(
        _db
            .collection('users')
            .doc(_uid)
            .collection('cancellations')
            .doc(rideId),
        {
          'rideId': rideId,
          'reason': reason.name,
          'timestamp': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      Logger.info('Cancellation recorded for ride $rideId', tag: _tag);
    } catch (e) {
      Logger.error('Failed to record cancellation: $e', tag: _tag, error: e);
    }
  }

  /// Calculează statisticile de anulare pentru șoferul curent.
  Future<CancellationStats> getDriverStats() async {
    if (_uid.isEmpty) {
      return const CancellationStats(
          totalRides: 0, cancelledRides: 0, cancellationRate: 0.0);
    }
    try {
      final doc = await _db.collection('users').doc(_uid).get();
      final data = doc.data() ?? {};
      final totalRides = (data['totalRides'] ?? 0) as int;
      final cancelled = (data['cancellationCount'] ?? 0) as int;
      final rate = totalRides > 0 ? cancelled / totalRides : 0.0;
      return CancellationStats(
        totalRides: totalRides,
        cancelledRides: cancelled,
        cancellationRate: rate,
      );
    } catch (e) {
      Logger.error('Failed to get cancellation stats: $e', tag: _tag, error: e);
      return const CancellationStats(
          totalRides: 0, cancelledRides: 0, cancellationRate: 0.0);
    }
  }
}
