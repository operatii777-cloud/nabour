import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/models/ride_sharing_model.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'dart:math' as math;

/// Serviciu pentru ride sharing (călătorie partajată) - Uber-like
class RideSharingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creează o cerere de ride sharing
  Future<RideShare?> createRideShareRequest({
    required String rideId,
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required double originalCost,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final rideShare = RideShare(
        id: _db.collection('ride_shares').doc().id,
        rideId: rideId,
        passengerId: userId,
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
        requestedAt: Timestamp.now(),
        status: 'pending',
        originalCost: originalCost,
      );

      await _db.collection('ride_shares').doc(rideShare.id).set(rideShare.toMap());

      // Încearcă să facă match automat
      _tryMatchRideShare(rideShare);

      return rideShare;
    } catch (e) {
      Logger.warning('[RIDE_SHARING] Error creating request: $e', tag: 'RideSharing');
      return null;
    }
  }

  /// Încearcă să facă match pentru o cerere de ride sharing
  Future<void> _tryMatchRideShare(RideShare rideShare) async {
    try {
      // Caută alte cereri de ride sharing care pot fi match-uite
      final pendingShares = await _db
          .collection('ride_shares')
          .where('status', isEqualTo: 'pending')
          .where('passengerId', isNotEqualTo: rideShare.passengerId)
          .get();

      for (var doc in pendingShares.docs) {
        final otherShare = RideShare.fromMap(doc.data());
        
        // Verifică dacă rutele sunt compatibile
        if (_areRoutesCompatible(rideShare, otherShare)) {
          // Creează match
          await _createMatch(rideShare, otherShare);
          break; // Un match per cerere
        }
      }
    } catch (e) {
      Logger.warning('[RIDE_SHARING] Match attempt error: $e', tag: 'RideSharing');
    }
  }

  /// Verifică dacă două rute sunt compatibile pentru sharing
  bool _areRoutesCompatible(RideShare share1, RideShare share2) {
    // Calculează distanța între pickup points
    final pickupDistance = _calculateDistance(
      share1.pickupLatitude,
      share1.pickupLongitude,
      share2.pickupLatitude,
      share2.pickupLongitude,
    );

    // Calculează distanța între destination points
    final destinationDistance = _calculateDistance(
      share1.destinationLatitude,
      share1.destinationLongitude,
      share2.destinationLatitude,
      share2.destinationLongitude,
    );

    // Rutele sunt compatibile dacă:
    // - Pickup points sunt la mai puțin de 2km unul de altul
    // - Destination points sunt la mai puțin de 2km unul de altul
    // - Sau dacă unul dintre pickup/destination este aproape de celălalt
    return pickupDistance < 2.0 && destinationDistance < 2.0;
  }

  /// Calculează distanța între două puncte (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  /// Creează un match între două cereri de ride sharing
  Future<void> _createMatch(RideShare share1, RideShare share2) async {
    try {
      // Calculează costul partajat (reducere de 30% pentru fiecare pasager)
      final sharedCost1 = share1.originalCost! * 0.7;
      final sharedCost2 = share2.originalCost! * 0.7;

      // Actualizează statusul pentru ambele cereri
      await _db.collection('ride_shares').doc(share1.id).update({
        'status': 'matched',
        'matchedRideId': share2.rideId,
        'sharedCost': sharedCost1,
        'matchedAt': Timestamp.now(),
      });

      await _db.collection('ride_shares').doc(share2.id).update({
        'status': 'matched',
        'matchedRideId': share1.rideId,
        'sharedCost': sharedCost2,
        'matchedAt': Timestamp.now(),
      });

      // ✅ NOU: Trimite mesaje de sistem pentru ambele curse
      try {
        final firestoreService = FirestoreService();
        await firestoreService.sendSystemMessage(
          share1.rideId,
          '🎉 Cursă partajată găsită! Costul tău: ${sharedCost1.toStringAsFixed(2)} RON (economie de ${(share1.originalCost! - sharedCost1).toStringAsFixed(2)} RON)',
        );
        await firestoreService.sendSystemMessage(
          share2.rideId,
          '🎉 Cursă partajată găsită! Costul tău: ${sharedCost2.toStringAsFixed(2)} RON (economie de ${(share2.originalCost! - sharedCost2).toStringAsFixed(2)} RON)',
        );
      } catch (e) {
        Logger.warning('[RIDE_SHARING] System messages error: $e', tag: 'RideSharing');
      }

      Logger.info(
        'Match created ${share1.id} ↔ ${share2.id}',
        tag: 'RideSharing',
      );
    } catch (e) {
      Logger.warning('[RIDE_SHARING] Error creating match: $e', tag: 'RideSharing');
    }
  }

  /// Obține ride share pentru o cursă
  Future<RideShare?> getRideShareForRide(String rideId) async {
    try {
      final snapshot = await _db
          .collection('ride_shares')
          .where('rideId', isEqualTo: rideId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return RideShare.fromMap(snapshot.docs.first.data());
    } catch (e) {
      Logger.warning('[RIDE_SHARING] getRideShare error: $e', tag: 'RideSharing');
      return null;
    }
  }

  /// Anulează o cerere de ride sharing
  Future<void> cancelRideShare(String rideShareId) async {
    try {
      await _db.collection('ride_shares').doc(rideShareId).update({
        'status': 'cancelled',
      });
    } catch (e) {
      Logger.warning('[RIDE_SHARING] cancel error: $e', tag: 'RideSharing');
    }
  }

  /// Stream pentru ride share updates
  Stream<RideShare?> getRideShareStream(String rideId) {
    return _db
        .collection('ride_shares')
        .where('rideId', isEqualTo: rideId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return RideShare.fromMap(snapshot.docs.first.data());
    });
  }
}

