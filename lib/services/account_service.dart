import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountService {
  static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;
  AccountService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Re-authenticates the user, deletes all Firestore data, then deletes the
  /// Firebase Auth account.
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return {'success': false, 'message': 'Utilizatorul nu este autentificat.'};
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      final uid = user.uid;

      // Delete rides where user is driver
      final driverRides = await _firestore
          .collection('rides')
          .where('driverId', isEqualTo: uid)
          .get();
      for (final doc in driverRides.docs) {
        await doc.reference.delete();
      }

      // Delete rides where user is passenger
      final passengerRides = await _firestore
          .collection('rides')
          .where('passengerId', isEqualTo: uid)
          .get();
      for (final doc in passengerRides.docs) {
        await doc.reference.delete();
      }

      // Delete user document (includes sub-collections via security rules)
      await _firestore.collection('users').doc(uid).delete();

      // Delete the Firebase Auth account last
      await user.delete();

      return {'success': true, 'message': 'Contul a fost șters cu succes.'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'INVALID_LOGIN_CREDENTIALS' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        return {'success': false, 'message': 'Parola introdusă este incorectă.'};
      }
      return {
        'success': false,
        'message': 'Eroare la ștergerea contului: ${e.message}'
      };
    } catch (e) {
      return {'success': false, 'message': 'A apărut o eroare neașteptată: $e'};
    }
  }

  /// Signs out the current user from this device.
  ///
  /// Note: Firebase Auth client-side tokens on other devices cannot be
  /// invalidated without server-side Admin SDK token revocation. This method
  /// signs out the current device only. For full multi-device revocation,
  /// use Firebase Admin SDK on a backend server.
  Future<void> logoutAllDevices() async {
    // Sign out from the current device
    await _auth.signOut();
  }
}
