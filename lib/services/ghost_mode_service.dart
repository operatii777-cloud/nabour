import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mod fantomă Bump-style: blochează publicarea locației sociale (RTDB + Firestore vizibil)
/// și sincronizează starea pe `users/{uid}` pentru consistență multi-dispozitiv.
class GhostModeService {
  GhostModeService._();
  static final GhostModeService instance = GhostModeService._();

  static const _prefKey = 'ghost_mode_social_block';

  bool _blocking = false;
  bool _loaded = false;

  bool get isBlocking => _loaded && _blocking;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final p = await SharedPreferences.getInstance();
    _blocking = p.getBool(_prefKey) ?? false;
    _loaded = true;
  }

  /// La login / refresh profil: serverul are prioritate.
  Future<void> syncFromServer(bool serverGhost) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefKey, serverGhost);
    _blocking = serverGhost;
    _loaded = true;
  }

  /// Apelează la „Invizibil” / la activare vizibilitate.
  Future<void> setBlocking(bool block) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefKey, block);
    _blocking = block;
    _loaded = true;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'ghostMode': block,
        'socialLocationPaused': block,
        if (block) 'ghostModeAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
