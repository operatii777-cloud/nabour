import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:nabour_app/utils/logger.dart';

/// Sincronizează celulele de explorare în `users/{uid}/scratch_map_tiles/{tileId}`.
/// (Numele colecției rămâne pentru compatibilitate cu datele existente.)
/// `scratchTileCount` pe `users/{uid}` e actualizat de Cloud Function.
class ExplorariFirestoreSync {
  ExplorariFirestoreSync._();
  static final ExplorariFirestoreSync instance = ExplorariFirestoreSync._();

  final Map<String, _PendingTile> _pending = {};
  Timer? _debounce;

  static const _debounceDuration = Duration(seconds: 20);
  static const _flushThreshold = 60;

  void enqueue(String tileId, double lat, double lng) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || tileId.isEmpty) return;
    _pending[tileId] = _PendingTile(lat: lat, lng: lng);
    _debounce?.cancel();
    if (_pending.length >= _flushThreshold) {
      unawaited(_flush(uid));
    } else {
      _debounce = Timer(_debounceDuration, () => _flush(uid));
    }
  }

  Future<void> _flush(String uid) async {
    _debounce?.cancel();
    _debounce = null;
    if (_pending.isEmpty) return;
    final entries = _pending.entries.toList();
    _pending.clear();
    const chunk = 400;
    for (var i = 0; i < entries.length; i += chunk) {
      final slice = entries.sublist(
        i,
        i + chunk > entries.length ? entries.length : i + chunk,
      );
      final batch = FirebaseFirestore.instance.batch();
      final base =
          FirebaseFirestore.instance.collection('users').doc(uid).collection(
                'scratch_map_tiles',
              );
      for (final e in slice) {
        batch.set(
          base.doc(e.key),
          {
            'lat': e.value.lat,
            'lng': e.value.lng,
            'syncedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      try {
        await batch.commit();
      } catch (err, st) {
        Logger.error('ExplorariFirestoreSync flush: $err',
            error: err, stackTrace: st, tag: 'EXPLORARI');
        for (final e in slice) {
          _pending[e.key] = e.value;
        }
      }
    }
  }

  /// Îmbogățește SQLite local din nor (aceleași ID-uri de celule).
  Future<int> mergeRemoteIntoLocal(
    Future<bool> Function(String tileId) insertIfMissing,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scratch_map_tiles')
          .limit(5000)
          .get();
      var n = 0;
      for (final d in snap.docs) {
        final ok = await insertIfMissing(d.id);
        if (ok) n++;
      }
      return n;
    } catch (e, st) {
      Logger.error('mergeRemoteIntoLocal: $e',
          error: e, stackTrace: st, tag: 'EXPLORARI');
      return 0;
    }
  }
}

class _PendingTile {
  final double lat;
  final double lng;
  _PendingTile({required this.lat, required this.lng});
}
