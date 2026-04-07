/// 🧪 Helper mod test: curse în `ride_requests` + simulare GPS pentru șofer de test.
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/utils/logger.dart';

class TestModeHelper {
  static const bool _isTestMode = bool.fromEnvironment('TEST_MODE');

  static bool get isTestMode => _isTestMode || kDebugMode;

  static const Map<String, Map<String, String>> testAccounts = {
    'passenger': {
      'email': 'pasager.test@friendsride.ro',
      'password': 'Test123456',
      'name': 'Pasager Test',
      'role': 'passenger',
    },
    'driver': {
      'email': 'sofer.test@friendsride.ro',
      'password': 'Test123456',
      'name': 'Șofer Test',
      'role': 'driver',
    },
  };

  static const Map<String, String> testRouteAddresses = {
    'pickup': 'Prelungirea Ghencea 45 bloc D4, București',
    'destination': 'Aeroport Otopeni - Sosiri, București',
  };

  static const Map<String, Map<String, double>> testRouteCoordinates = {
    'pickup': {'lat': 44.4268, 'lng': 26.1025},
    'destination': {'lat': 44.5711, 'lng': 26.0858},
  };

  /// Ultimul UID șofer de test (după `prepareTestAccounts`).
  static String? lastPreparedDriverUid;

  static Future<UserCredential?> quickLogin(String accountType) async {
    if (!isTestMode) {
      Logger.warning('Test mode disabled.', tag: 'TestMode');
      return null;
    }
    final account = testAccounts[accountType];
    if (account == null) return null;
    final auth = FirebaseAuth.instance;
    try {
      return await auth.signInWithEmailAndPassword(
        email: account['email']!,
        password: account['password']!,
      );
    } catch (_) {
      final credential = await auth.createUserWithEmailAndPassword(
        email: account['email']!,
        password: account['password']!,
      );
      await _createTestUserProfile(credential.user!.uid, account);
      return credential;
    }
  }

  static Future<void> _createTestUserProfile(String uid, Map<String, String> account) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'id': uid,
      'email': account['email'],
      'displayName': account['name'],
      'role': account['role'],
      'createdAt': FieldValue.serverTimestamp(),
      'isTestAccount': true,
    }, SetOptions(merge: true));
  }

  /// Loghează șoferul, completează profilul pentru UI, apoi pasagerul.
  static Future<String?> prepareTestAccounts() async {
    if (!isTestMode) return null;
    try {
      final d = await quickLogin('driver');
      if (d?.user == null) return null;
      final driverId = d!.user!.uid;
      lastPreparedDriverUid = driverId;
      await FirebaseFirestore.instance.collection('users').doc(driverId).set({
        'displayName': 'Șofer Test MOCK',
        'licensePlate': 'B-99-MOK',
        'driverCategory': 'standard',
        'averageRating': 4.9,
        'phone': '+40700111222',
        'role': 'driver',
        'isTestAccount': true,
      }, SetOptions(merge: true));

      final p = await quickLogin('passenger');
      if (p?.user == null) return null;
      await FirebaseFirestore.instance.collection('users').doc(p!.user!.uid).set({
        'displayName': 'Pasager Test MOCK',
        'role': 'passenger',
        'isTestAccount': true,
      }, SetOptions(merge: true));
      return driverId;
    } catch (e) {
      Logger.warning('prepareTestAccounts: $e', tag: 'TestMode');
      return null;
    }
  }

  static double haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Aceeași precizie ca FirestoreService (6).
  static String encodeGeohashForTests(double lat, double lng, {int precision = 6}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    double minLat = -90, maxLat = 90, minLng = -180, maxLng = 180;
    var geohash = '';
    var bit = 0;
    var ch = 0;
    while (geohash.length < precision) {
      if (bit % 2 == 0) {
        final mid = (minLng + maxLng) / 2;
        if (lng >= mid) {
          ch |= 1 << (4 - bit % 5);
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          ch |= 1 << (4 - bit % 5);
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }
      bit++;
      if (bit % 5 == 0) {
        geohash += base32[ch];
        ch = 0;
      }
    }
    return geohash;
  }

  static double calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = (lng2 - lng1) * (math.pi / 180);
    final lat1Rad = lat1 * (math.pi / 180);
    final lat2Rad = lat2 * (math.pi / 180);
    final y = math.sin(dLng) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLng);
    return (math.atan2(y, x) * (180 / math.pi) + 360) % 360;
  }

  /// Cursă nouă în `ride_requests` (ca producție).
  static Future<String?> createMockRideRequest(String passengerId) async {
    if (!isTestMode) return null;
    final pu = testRouteCoordinates['pickup']!;
    final dest = testRouteCoordinates['destination']!;
    final dist = haversineKm(pu['lat']!, pu['lng']!, dest['lat']!, dest['lng']!);
    final ride = Ride(
      id: '',
      passengerId: passengerId,
      startAddress: testRouteAddresses['pickup']!,
      destinationAddress: testRouteAddresses['destination']!,
      distance: dist,
      startLatitude: pu['lat'],
      startLongitude: pu['lng'],
      destinationLatitude: dest['lat'],
      destinationLongitude: dest['lng'],
      durationInMinutes: 35,
      baseFare: 10.0,
      perKmRate: 2.5,
      perMinRate: 0.5,
      totalCost: 45.0,
      appCommission: 5.0,
      driverEarnings: 35.0,
      timestamp: DateTime.now(),
      status: 'pending',
    );
    final m = Map<String, dynamic>.from(ride.toMap());
    m['timestamp'] = FieldValue.serverTimestamp();
    m['searchRadius'] = 5.0;
    m['searchStartTime'] = FieldValue.serverTimestamp();
    m['isMockRide'] = true;
    m['wasCancelled'] = false;
    final ref = await FirebaseFirestore.instance.collection('ride_requests').add(m);
    return ref.id;
  }

  static Future<void> writeMockDriverLocation({
    required String driverId,
    required double lat,
    required double lng,
    double? prevLat,
    double? prevLng,
  }) async {
    final bearing = (prevLat != null && prevLng != null)
        ? calculateBearing(prevLat, prevLng, lat, lng)
        : 0.0;
    await FirebaseFirestore.instance.collection('driver_locations').doc(driverId).set({
      'position': GeoPoint(lat, lng),
      'geohash': encodeGeohashForTests(lat, lng),
      'lastUpdate': Timestamp.now(),
      'isOnline': true,
      'bearing': bearing,
      'displayName': 'Șofer Test MOCK',
      'licensePlate': 'B-99-MOK',
      'category': RideCategory.standard.name,
    }, SetOptions(merge: true));
  }

  static Future<void> patchRideRequest(String rideId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('ride_requests').doc(rideId).update(data);
  }
}

/// Orchestrare automată: driver_found → mișcare → accepted → (opțional) in_progress.
class MockRideFlowOrchestrator {
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  bool get isCancelled => _cancelled;

  Future<void> runPassengerJourney({
    required String rideId,
    required String driverId,
    required void Function(String line) log,
    bool autoConfirmDriver = true,
    bool advanceToInProgress = true,
  }) async {
    final pu = TestModeHelper.testRouteCoordinates['pickup']!;
    final dest = TestModeHelper.testRouteCoordinates['destination']!;
    final pickupLat = pu['lat']!;
    final pickupLng = pu['lng']!;
    final destLat = dest['lat']!;
    final destLng = dest['lng']!;

    Future<void> tick(String msg) async {
      if (_cancelled) return;
      log(msg);
    }

    try {
      await Future.delayed(const Duration(seconds: 2));
      if (_cancelled) return;
      await tick('→ driver_found');
      await TestModeHelper.patchRideRequest(rideId, {
        'status': 'driver_found',
        'driverId': driverId,
        'pickupCode': '4242',
        'acceptedAt': FieldValue.serverTimestamp(),
        'driverAcceptanceStatus': 'accepted',
        'driverAcceptanceUpdatedAt': FieldValue.serverTimestamp(),
        'wasCancelled': false,
      });

      // Apropiere de pickup (de la ~3 km sud)
      var prevLat = pickupLat - 0.028;
      var prevLng = pickupLng;
      const stepsPickup = 14;
      for (var i = 0; i <= stepsPickup; i++) {
        if (_cancelled) return;
        final t = i / stepsPickup;
        final lat = prevLat + (pickupLat - prevLat) * t;
        final lng = prevLng + (pickupLng - prevLng) * t;
        try {
          await TestModeHelper.writeMockDriverLocation(
            driverId: driverId,
            lat: lat,
            lng: lng,
            prevLat: i == 0 ? lat : prevLat,
            prevLng: i == 0 ? lng : prevLng,
          );
        } catch (e) {
          await tick('⚠️ driver_locations: $e (deploy firestore.rules?)');
        }
        prevLat = lat;
        prevLng = lng;
        await Future.delayed(const Duration(milliseconds: 550));
      }

      if (_cancelled) return;
      if (autoConfirmDriver) {
        await tick('→ accepted (confirmare automată)');
        await TestModeHelper.patchRideRequest(rideId, {
          'status': 'accepted',
          'wasCancelled': false,
        });
      } else {
        await tick('— Apasă „Confirmă Șoferul” în UI');
        return;
      }

      await Future.delayed(const Duration(seconds: 3));
      if (_cancelled) return;

      if (advanceToInProgress) {
        await tick('→ in_progress');
        await TestModeHelper.patchRideRequest(rideId, {
          'status': 'in_progress',
          'wasCancelled': false,
        });
      }

      // Spre destinație
      const stepsDest = 18;
      for (var i = 0; i <= stepsDest; i++) {
        if (_cancelled) return;
        final t = i / stepsDest;
        final lat = pickupLat + (destLat - pickupLat) * t;
        final lng = pickupLng + (destLng - pickupLng) * t;
        try {
          await TestModeHelper.writeMockDriverLocation(
            driverId: driverId,
            lat: lat,
            lng: lng,
            prevLat: prevLat,
            prevLng: prevLng,
          );
        } catch (e) {
          await tick('⚠️ driver_locations: $e');
        }
        prevLat = lat;
        prevLng = lng;
        await Future.delayed(const Duration(milliseconds: 700));
      }

      await tick('✅ simulare traseu completă (poți completa cursa din UI șofer sau anula)');
    } catch (e, st) {
      log('❌ $e\n$st');
    }
  }
}
