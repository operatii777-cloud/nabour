/// Test E2E Sofer — rulat pe Xiaomi (2201116TG)
///
/// Flow:
///   1. Verifică că utilizatorul este logat ca sofer
///   2. Asteapta un broadcast de test recent (creat in ultimele 5 minute)
///   3. Face o oferta pe acel broadcast
///   4. Asteapta acceptarea de catre pasager
///   5. Confirma cursa ca efectuata
///
/// Rulare:
///   flutter test integration_test/e2e_two_device_driver.dart -d IRXK5HT4YTGIQ4UO

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('E2E Sofer: detectez cerere, trimit oferta, astept acceptare, confirm', () async {
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

    // 1. Verifica ca soferul este logat
    final uid = auth.currentUser?.uid;
    expect(
      uid,
      isNotNull,
      reason: 'Soferul nu este logat! Deschide aplicatia si logheaza-te prima data.',
    );
    print('\n================================');
    print('SOFER uid: $uid');
    print('================================\n');

    // 2. Preia profilul soferului
    final userDoc = await firestore.collection('users').doc(uid).get();
    final data = userDoc.data() ?? {};
    final driverName = data['displayName'] as String? ?? 'Sofer Test';
    final driverAvatar = data['avatar'] as String? ?? 'X';
    final brand = data['carBrand'] as String? ?? '';
    final model = data['carModel'] as String? ?? '';
    final plate = data['licensePlate'] as String? ?? '';
    final carInfo = [
      if (brand.isNotEmpty) brand,
      if (model.isNotEmpty) model,
      if (plate.isNotEmpty) '- $plate',
    ].join(' ');

    print('Sofer: $driverName');
    print('Masina: ${carInfo.isEmpty ? "Masina personala" : carInfo}');
    print('\nAstept broadcast de test [E2E-TEST] (max 3 minute)...\n');

    // 3. Asteapta un broadcast de test recent
    DocumentSnapshot? targetDoc;
    String? broadcastId;
    const maxWaitSeconds = 180;
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(minutes: 5)),
    );

    for (int i = 0; i < maxWaitSeconds; i++) {
      await Future.delayed(const Duration(seconds: 1));

      // Folosim acelasi query ca feed-ul din app (index existent)
      final expiryCutoff = Timestamp.fromDate(DateTime.now());
      final query = await firestore
          .collection('ride_broadcasts')
          .where('status', isEqualTo: 'open')
          .where('expiresAt', isGreaterThan: expiryCutoff)
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      // Filtreaza client-side: recente (ultimele 5 min) si marcate ca test E2E
      for (final doc in query.docs) {
        final createdAt = doc.data()['createdAt'] as Timestamp?;
        final msg = doc.data()['message'] as String? ?? '';
        final isTest = doc.data()['isE2eTest'] as bool? ?? false;

        if (createdAt != null &&
            createdAt.compareTo(cutoff) >= 0 &&
            (isTest || msg.contains('[E2E-TEST'))) {
          targetDoc = doc;
          broadcastId = doc.id;
          final passengerName = doc.data()['passengerName'] as String? ?? 'Pasager';
          print('Gasit broadcast de test: $broadcastId');
          print('Pasager: $passengerName');
          print('Mesaj: $msg\n');
          break;
        }
      }

      if (targetDoc != null) break;

      if (i % 10 == 0) {
        print('  ... astept broadcast de test (${i}s / ${maxWaitSeconds}s)');
      }
    }

    expect(
      targetDoc,
      isNotNull,
      reason: 'Nu am gasit niciun broadcast de test in $maxWaitSeconds secunde. '
          'Verifica ca testul de pasager a pornit.',
    );

    // 4. Trimite oferta
    print('Trimit oferta pe broadcast: $broadcastId');
    final offerMap = {
      'driverId': uid,
      'driverName': driverName,
      'driverAvatar': driverAvatar,
      'carInfo': carInfo.isEmpty ? 'Masina personala' : carInfo,
      'etaMinutes': 3,
      'offeredAt': Timestamp.fromDate(DateTime.now()),
    };

    await firestore.collection('ride_broadcasts').doc(broadcastId).update({
      'offers': FieldValue.arrayUnion([offerMap]),
    });
    print('Oferta trimisa!');

    // 5. Asteapta acceptarea de catre pasager
    print('\nAstept ca pasagerul sa accepte oferta (max 2 minute)...');
    bool accepted = false;
    const maxAcceptSeconds = 120;

    for (int i = 0; i < maxAcceptSeconds; i++) {
      await Future.delayed(const Duration(seconds: 1));

      final snap = await firestore
          .collection('ride_broadcasts')
          .doc(broadcastId)
          .get();
      final status = snap.data()?['status'] as String? ?? 'open';
      final acceptedDriverId = snap.data()?['acceptedDriverId'] as String?;

      if (status == 'accepted' && acceptedDriverId == uid) {
        accepted = true;
        print('Oferta acceptata de pasager!');
        break;
      } else if (status == 'cancelled') {
        fail('Pasagerul a anulat cererea.');
      }

      if (i % 10 == 0) {
        print('  ... astept acceptarea (${i}s / ${maxAcceptSeconds}s)');
      }
    }

    expect(
      accepted,
      isTrue,
      reason: 'Pasagerul nu a acceptat oferta in $maxAcceptSeconds secunde.',
    );

    // Asteapta putin
    await Future.delayed(const Duration(seconds: 3));

    // 6. Confirma cursa de pe partea soferului
    await firestore.collection('ride_broadcasts').doc(broadcastId).update({
      'driverConfirmed': true,
    });

    print('\n================================');
    print('SOFER: Cursa confirmata cu succes!');
    print('Broadcast ID: $broadcastId');
    print('Sofer: $driverName ($driverAvatar)');
    print('================================\n');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
