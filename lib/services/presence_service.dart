import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:nabour_app/utils/logger.dart';

/// Info despre prezența unui prieten (citit din RTDB /presence/{uid}).
class FriendPresenceInfo {
  final String uid;
  final bool isOnline;
  final int lastSeenMs; // epoch ms
  final String displayName;
  final String avatar; // emoji
  final String? photoURL;

  const FriendPresenceInfo({
    required this.uid,
    required this.isOnline,
    required this.lastSeenMs,
    required this.displayName,
    required this.avatar,
    this.photoURL,
  });

  factory FriendPresenceInfo.fromRtdb(String uid, Map<dynamic, dynamic> data) {
    return FriendPresenceInfo(
      uid: uid,
      isOnline: data['online'] as bool? ?? false,
      lastSeenMs: (data['lastSeen'] as int?) ?? 0,
      displayName: data['displayName'] as String? ?? '',
      avatar: data['avatar'] as String? ?? '👤',
      photoURL: data['photoURL'] as String?,
    );
  }

  /// Minute trecute de la ultima activitate (0 dacă online chiar acum).
  int get minutesSinceLastSeen {
    if (lastSeenMs == 0) return 0;
    final diff = DateTime.now().millisecondsSinceEpoch - lastSeenMs;
    return (diff / 60000).floor().clamp(0, 99999);
  }
}

/// Serviciu singleton de prezență bazat pe Firebase RTDB /presence/{uid}.
///
/// - Publică propria prezență (online/offline) la schimbări de lifecycle.
/// - Setează `onDisconnect()` pentru auto-offline la pierdere de conexiune.
/// - Expune [friendsOnlineStream] pentru a urmări prezența prietenilor.
///
/// Necesită reguli RTDB:
/// ```json
/// { "rules": { "presence": { "$uid": { ".read": "auth != null", ".write": "auth.uid === $uid" } } } }
/// ```
class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  String? _currentUid;
  bool _initialized = false;

  /// Inițializează serviciul pentru utilizatorul [uid].
  /// Poate fi apelat de mai multe ori (dacă UID-ul se schimbă, reinițializează).
  Future<void> initialize(String uid) async {
    if (_initialized && _currentUid == uid) return;
    if (_initialized) await _teardown(setOffline: true);

    _currentUid = uid;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    await _setOnline();
  }

  /// Marchează utilizatorul ca offline și oprește serviciul.
  Future<void> goOffline() async {
    await _teardown(setOffline: true);
  }

  Future<void> _teardown({required bool setOffline}) async {
    WidgetsBinding.instance.removeObserver(this);
    if (setOffline) await _setOffline();
    _initialized = false;
    _currentUid = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUid == null) return;
    // Setăm online doar la revenire în foreground.
    // Nu setăm offline la pause/detach — onDisconnect() RTDB se ocupă de asta
    // automat când conexiunea cade (app omorât, fără internet).
    // Altfel, utilizatorul rămâne „online" și când aplicația e minimizată
    // (background location publish continuă oricum la 45s).
    if (state == AppLifecycleState.resumed) {
      _setOnline();
    }
  }

  Future<void> _setOnline() async {
    final uid = _currentUid;
    if (uid == null) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final avatar = await _fetchAvatar(uid);
      final ref = FirebaseDatabase.instance.ref('presence/$uid');
      await ref.set(<String, dynamic>{
        'online': true,
        'lastSeen': ServerValue.timestamp,
        'displayName': user?.displayName ?? '',
        'photoURL': user?.photoURL ?? '',
        'avatar': avatar,
      });
      // Nu mai setăm online: false la onDisconnect(). 
      // Permitem prezenței să persiste cât timp aplicația e minimizată.
      // Dacă e închisă, va fi vizibil prin lastSeen vechi.
    } catch (e) {
      Logger.warning('PresenceService._setOnline: $e', tag: 'PRESENCE');
    }
  }

  Future<void> _setOffline() async {
    final uid = _currentUid;
    if (uid == null) return;
    try {
      await FirebaseDatabase.instance.ref('presence/$uid').update(<String, dynamic>{
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      Logger.warning('PresenceService._setOffline: $e', tag: 'PRESENCE');
    }
  }

  /// Citește avatar-ul emoji al utilizatorului din Firestore (cache-ul local din Firestore SDK).
  Future<String> _fetchAvatar(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.cache));
      final avatar = doc.data()?['avatar'] as String?;
      if (avatar != null && avatar.isNotEmpty) return avatar;
    } catch (_) {/* cache miss – ok */}
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.data()?['avatar'] as String? ?? '👤';
    } catch (_) {
      return '👤';
    }
  }

  /// Stream care emite lista prietenilor ONLINE din [friendUids].
  ///
  /// Se abonează la `/presence/{uid}` pentru fiecare uid și emite la orice schimbare.
  /// Subscripțiile se anulează automat la cancel pe stream.
  Stream<List<FriendPresenceInfo>> friendsOnlineStream(Set<String> friendUids) {
    if (friendUids.isEmpty) return Stream.value([]);

    final controller = StreamController<List<FriendPresenceInfo>>.broadcast();
    final current = <String, FriendPresenceInfo>{};
    final subs = <StreamSubscription<DatabaseEvent>>[];

    void emit() {
      if (controller.isClosed) return;
      final online = current.values
          .where((p) => p.isOnline)
          .toList()
        ..sort((a, b) => b.lastSeenMs.compareTo(a.lastSeenMs));
      controller.add(online);
    }

    for (final uid in friendUids) {
      final sub = FirebaseDatabase.instance
          .ref('presence/$uid')
          .onValue
          .listen(
        (event) {
          final data = event.snapshot.value;
          if (data is Map) {
            current[uid] = FriendPresenceInfo.fromRtdb(uid, data);
          } else {
            current.remove(uid);
          }
          emit();
        },
        onError: (_) {
          current.remove(uid);
          emit();
        },
      );
      subs.add(sub);
    }

    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };

    return controller.stream;
  }
}
