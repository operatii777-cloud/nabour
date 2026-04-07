/// Test E2E Pasager — rulat pe Lenovo (TB-J616F)
///
/// Flow:
///   1. Verifică că utilizatorul este logat
///   2. Creează un broadcast de test în Firestore
///   3. Așteaptă oferta șoferului (max 3 minute)
///   4. Acceptă oferta
///   5. Confirmă cursa ca efectuată
///
/// Rulare:
///   flutter test integration_test/e2e_two_device_passenger.dart -d HA1S0HMF

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/firebase_options.dart';

// Model minimal pentru oferta soferului (fara import din screen)
class _DriverOffer {
  final String driverId;
  final String driverName;
  final String driverAvatar;
  final String carInfo;

  _DriverOffer({
    required this.driverId,
    required this.driverName,
    required this.driverAvatar,
    required this.carInfo,
  });

  factory _DriverOffer.fromMap(Map<String, dynamic> m) => _DriverOffer(
        driverId: m['driverId'] as String? ?? '',
        driverName: m['driverName'] as String? ?? 'Sofer',
        driverAvatar: m['driverAvatar'] as String? ?? 'X',
        carInfo: m['carInfo'] as String? ?? '',
      );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('E2E Pasager: creare cursa, astept sofer, accept, confirm', () async {
    // Initializeaza Firebase daca nu e deja initializat
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Deja initializat
    }

    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // 1. Verifica ca utilizatorul este logat
    final uid = auth.currentUser?.uid;
    expect(
      uid,
      isNotNull,
      reason: 'Pasagerul nu este logat! Deschide aplicatia si logheaza-te prima data.',
    );
    print('\n================================');
    print('PASAGER uid: $uid');
    print('================================\n');

    // 2. Preia profilul utilizatorului
    final userDoc = await firestore.collection('users').doc(uid).get();
    final data = userDoc.data() ?? {};
    final name = data['displayName'] as String? ?? 'Pasager Test';
    final avatar = data['avatar'] as String? ?? '🙂';

    final testId = DateTime.now().millisecondsSinceEpoch.toString();
    final testMessage = '[E2E-TEST-$testId] Caut sofer - test automat';

    print('Creez broadcast de test cu tag: [E2E-TEST-$testId]');

    // 3. Creaza broadcast
    final now = DateTime.now();
    final docRef = await firestore.collection('ride_broadcasts').add({
      'passengerId': uid,
      'passengerName': name,
      'passengerAvatar': avatar,
      'message': testMessage,
      'destination': 'Piata Unirii, Bucuresti',
      'passengerLat': 44.4268,
      'passengerLng': 26.1025,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 30))),
      'offers': [],
      'replies': [],
      'reactions': {},
      'status': 'open',
      'isE2eTest': true,
    });

    print('Broadcast creat: ${docRef.id}');
    print('Astept oferta soferului (max 3 minute)...\n');

    // 4. Asteapta oferta soferului
    _DriverOffer? driverOffer;
    const maxWaitSeconds = 180;

    for (int i = 0; i < maxWaitSeconds; i++) {
      await Future.delayed(const Duration(seconds: 1));

      final snap = await docRef.get();
      final offers = (snap.data()?['offers'] as List<dynamic>? ?? []);

      if (offers.isNotEmpty) {
        driverOffer = _DriverOffer.fromMap(
          Map<String, dynamic>.from(offers.first as Map),
        );
        print('Oferta primita de la: ${driverOffer.driverName} (${driverOffer.carInfo})');
        break;
      }

      if (i % 10 == 0) {
        print('  ... astept soferul (${i}s / ${maxWaitSeconds}s)');
      }
    }

    expect(
      driverOffer,
      isNotNull,
      reason: 'Nicio oferta primita in $maxWaitSeconds secunde. Verifica ca soferul a pornit testul.',
    );

    // 5. Accepta oferta
    print('\nAccept oferta soferului: ${driverOffer!.driverName}');
    await docRef.update({
      'status': 'accepted',
      'acceptedDriverId': driverOffer.driverId,
      'acceptedDriverName': driverOffer.driverName,
      'acceptedDriverAvatar': driverOffer.driverAvatar,
    });
    print('Oferta acceptata!');

    // Asteapta putin pentru ca soferul sa vada acceptarea
    await Future.delayed(const Duration(seconds: 5));

    // 6. Confirma cursa ca efectuata
    await docRef.update({
      'status': 'completed',
      'completionStatus': 'done',
      'passengerConfirmed': true,
    });

    print('\n================================');
    print('PASAGER: Cursa confirmata cu succes!');
    print('Broadcast ID: ${docRef.id}');
    print('Sofer: ${driverOffer.driverName} (${driverOffer.driverAvatar})');
    print('Masina: ${driverOffer.carInfo}');
    print('================================\n');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
