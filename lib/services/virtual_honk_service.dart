import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nabour_app/utils/logger.dart';

class VirtualHonkService {
  static final VirtualHonkService _instance = VirtualHonkService._();
  factory VirtualHonkService() => _instance;
  VirtualHonkService._();

  /// Trebuie să coincidă cu `database.rules.json` → `telemetry/honks`.
  static const String _honksPath = 'telemetry/honks';

  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  /// Trimite un claxon virtual către un alt utilizator.
  Future<void> sendHonk(String targetUid, String senderName) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final honkId = DateTime.now().millisecondsSinceEpoch.toString();
      await _db.child(_honksPath).child(targetUid).child(honkId).set({
        'senderUid': uid,
        'senderName': senderName,
        'timestamp': ServerValue.timestamp,
        'type': 'beep', // Default for now
      });
      
      // Auto-ștergere după 10 secunde (pentru a nu aglomera baza de date)
      Future.delayed(const Duration(seconds: 10), () {
        _db.child(_honksPath).child(targetUid).child(honkId).remove();
      });

      Logger.info('Sent honk to $targetUid', tag: 'HONK');
    } catch (e) {
      Logger.error('Error sending honk: $e', tag: 'HONK');
    }
  }

  /// Ascultă pentru claxoane primite.
  Stream<Map<String, dynamic>> listenForHonks() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db.child(_honksPath).child(uid).onChildAdded
        .map((event) {
          final data = event.snapshot.value as Map?;
          if (data == null) return <String, dynamic>{};
          return Map<String, dynamic>.from(data);
        })
        .handleError((Object e, StackTrace st) {
          // Evită erori neprinse dacă un consumer uită onError (ex. Permission denied)
          Logger.error(
            'Honk RTDB: $e (verifică regulile pentru $_honksPath/$uid)',
            error: e,
            stackTrace: st,
            tag: 'HONK',
          );
        });
  }
}
