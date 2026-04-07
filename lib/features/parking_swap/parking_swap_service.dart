import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/features/parking_swap/parking_event_model.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/utils/logger.dart';

class ParkingSwapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TokenService _tokenService = TokenService();

  static const String collectionPath = 'parking_swap_events';

  /// Anunță un loc liber (cel care pleacă)
  Future<String?> announceLeaving(double lat, double lng) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final expiresAt = DateTime.now().add(const Duration(minutes: 3)); // Valabil 3 min
      final docRef = _firestore.collection(collectionPath).doc();
      
      final event = ParkingSpotEvent(
        id: docRef.id,
        providerId: uid,
        latitude: lat,
        longitude: lng,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      await docRef.set(event.toMap());
      Logger.info('Loc liber anunțat: ${docRef.id} la $lat, $lng', tag: 'ParkingSwap');
      return docRef.id;
    } catch (e) {
      Logger.error('Eroare la anunțare loc parcare', error: e, tag: 'ParkingSwap');
      return null;
    }
  }

  /// Rezervă locul (cel care caută)
  Future<bool> reserveSpot(String spotId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    return _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection(collectionPath).doc(spotId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) return false;
      final data = snapshot.data();
      if (data == null || data['status'] != ParkingSpotStatus.available.name) {
        return false;
      }

      // Verifică dacă a expirat deja
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        transaction.update(docRef, {'status': ParkingSpotStatus.expired.name});
        return false;
      }

      // Efectuează rezervarea
      transaction.update(docRef, {
        'status': ParkingSpotStatus.reserved.name,
        'claimerId': uid,
      });
      return true;
    }).catchError((e) {
      Logger.error('Eroare la rezervare loc', error: e, tag: 'ParkingSwap');
      return false;
    });
  }

  /// Confirmă că schimbul a avut loc (cel care ajunge la loc)
  Future<bool> claimSpot(String spotId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      final docRef = _firestore.collection(collectionPath).doc(spotId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return false;

      final event = ParkingSpotEvent.fromFirestore(snapshot);
      if (event.status != ParkingSpotStatus.reserved || event.claimerId != uid) {
        return false;
      }

      // Finalizare: Plătește-l pe cel care a oferit locul (provider)
      // Folosim addTokens care apelează Cloud Function-ul securizat
      await _tokenService.addTokens(
        event.providerId,
        event.rewardAmount,
        TokenTransactionType.bonus,
        description: 'ParkingSwap Reward - Loc cedat pe Nabour',
      );
      
      await docRef.update({'status': ParkingSpotStatus.claimed.name});
      Logger.info('Loc ocupat cu succes. Tokeni transferați către ${event.providerId}', tag: 'ParkingSwap');
      return true;
    } catch (e) {
      Logger.error('Eroare la confirmare loc parcare', error: e, tag: 'ParkingSwap');
      return false;
    }
  }

  /// Stream cu locurile disponibile în zonă (pentru hartă)
  Stream<List<ParkingSpotEvent>> getNearbySpots() {
    return _firestore
        .collection(collectionPath)
        .where('status', isEqualTo: ParkingSpotStatus.available.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParkingSpotEvent.fromFirestore(doc))
            .where((e) => !e.isExpired)
            .toList());
  }
}
