import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/services/contacts_service.dart';

/// Sistemul de nametag-uri Nabour.
/// Fiecare user primește un emoji animal unic + prenumele său.
/// Ex: "🦊 Radu", "🐧 Ana", "🐻 Mihai"
class NabourNametag {
  static const List<String> _animals = [
    '🦊', '🐧', '🐻', '🦁', '🐯', '🦝', '🦔', '🐺',
    '🦄', '🐸', '🦋', '🐼', '🐨', '🦦', '🦥', '🐙',
    '🦜', '🦩', '🦚', '🦢', '🦭', '🐬', '🐳', '🦈',
    '🦊', '🐝', '🦉', '🐦', '🦤', '🦋', '🐢', '🦎',
    '🐿️', '🦔', '🐇', '🦌', '🐓', '🦃', '🦛', '🦏',
  ];

  /// Returnează un emoji animal aleatoriu.
  static String randomAnimal() {
    return _animals[Random().nextInt(_animals.length)];
  }

  /// Construiește nametag-ul complet: "🦊 Radu"
  static String build(String avatar, String displayName) {
    final firstName = displayName.split(' ').first;
    return '$avatar $firstName';
  }

  /// Returnează nametag-ul din date Firestore.
  static String fromData(Map<String, dynamic>? data) {
    final avatar = data?['avatar'] as String? ?? '🙂';
    final name = data?['displayName'] as String? ?? 'Vecin';
    return build(avatar, name);
  }

  /// Asignează un avatar utilizatorului dacă nu are deja unul.
  /// Apelat la login și la înregistrare.
  static Future<String> ensureAvatar(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final existing = doc.data()?['avatar'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    final avatar = randomAnimal();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'avatar': avatar}, SetOptions(merge: true));

    return avatar;
  }

  /// Apelat la înregistrare — creează profilul cu avatar inclus.
  static Future<void> initUserProfile({
    required String uid,
    required String displayName,
    String? email,
    String? phoneNumber,
    String? photoURL,
  }) async {
    final avatar = randomAnimal();
    final phoneFields = ContactsService.userPhoneFieldsForProfile(phoneNumber);
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'displayName': displayName,
      'email': email ?? '',
      ...phoneFields,
      'photoURL': photoURL ?? '',
      'avatar': avatar,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
