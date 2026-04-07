import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// „Ce ascult” manual — afișat în profil / viitor pe hartă (fără SDK Spotify obligatoriu).
class NowPlayingService {
  NowPlayingService._();
  static final NowPlayingService instance = NowPlayingService._();

  Future<void> publish({
    required String title,
    required String artist,
    String source = 'manual',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final t = title.trim();
    final a = artist.trim();
    if (t.isEmpty && a.isEmpty) {
      await clear();
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nowPlaying': {
          'title': t,
          'artist': a,
          'source': source,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> clear() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nowPlaying': FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
