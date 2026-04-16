import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nabour_app/models/neighborhood_request_model.dart';
import 'package:nabour_app/screens/ride_broadcast_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/location_cache_service.dart';
import 'package:nabour_app/services/map_qa_badge_prefs.dart';
import 'package:nabour_app/features/neighborhood_requests/nbhd_requests_manager.dart';
import 'package:nabour_app/services/nbr_telem_rtdb_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Gestionează toate badge-urile de pe butoanele rapide ale hărții.
///
/// Ascultă: cereri de ride broadcast, cereri cartier, chat cartier, mesaje
/// private necitite și cereri de prietenie primite. Expune contoare prin
/// getteri; apelează [notifyListeners] la orice schimbare.
class MapBadgesController extends ChangeNotifier {
  // ── State public ──────────────────────────────────────────────────────────

  int get cereriCount => _cereriCount;
  int get chatBadgeCount => _chatBadgeCount;
  int get privateChatUnreadCount => _privateChatUnreadCount;
  int get friendRequestCount => _friendRequestCount;

  // ── State intern ──────────────────────────────────────────────────────────

  int _cereriCount = 0;
  int _chatBadgeCount = 0;
  int _privateChatUnreadCount = 0;
  int _friendRequestCount = 0;

  List<RideBroadcastRequest> _broadcastSnapshot = const [];
  List<NeighborhoodRequest> _nbRequestsSnapshot = const [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _cereriBroadcastsSub;
  StreamSubscription<List<NeighborhoodRequest>>? _nbRequestsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _nbChatSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _privateChatSub;
  StreamSubscription<List<dynamic>>? _friendRequestsSub;

  String? _nbChatRoomId;
  String? _nbRoomPushTopic;

  // Callback opțional pentru a accesa poziția curentă a utilizatorului.
  geolocator.Position? Function()? _positionProvider;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Pornește toți ascultătorii pentru [uid]. Apelează [setPositionProvider]
  /// înainte dacă vrei badge-ul „Cereri" să ia în calcul distanța.
  void startListening(
    String uid, {
    geolocator.Position? Function()? positionProvider,
  }) {
    _positionProvider = positionProvider;
    _listenBroadcasts(uid);
    _listenNbRequests();
    _listenPrivateChat(uid);
    _rebindNbChatListener();
  }

  void setFriendRequestCount(int count) {
    if (_friendRequestCount == count) return;
    _friendRequestCount = count;
    notifyListeners();
  }

  /// Recompute badge-ul „Cereri" după ce utilizatorul a deschis feed-ul.
  Future<void> recomputeCereri() => _recomputeCereri();

  /// Rebind-ează ascultătorul de chat cartier (după schimbare de poziție).
  Future<void> rebindNbChatListener() => _rebindNbChatListener();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _cereriBroadcastsSub?.cancel();
    _nbRequestsSub?.cancel();
    _nbChatSub?.cancel();
    _privateChatSub?.cancel();
    _friendRequestsSub?.cancel();
    super.dispose();
  }

  // ── Ascultători interni ───────────────────────────────────────────────────

  void _listenBroadcasts(String uid) {
    _cereriBroadcastsSub?.cancel();
    _cereriBroadcastsSub = FirebaseFirestore.instance
        .collection('ride_broadcasts')
        .where('status', isEqualTo: 'open')
        .where('expiresAt',
            isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .where('allowedUids', arrayContains: uid)
        .snapshots()
        .listen((snap) {
      _broadcastSnapshot = snap.docs
          .map((d) => RideBroadcastRequest.fromMap(d.id, d.data()))
          .toList(growable: false);
      unawaited(_recomputeCereri());
    });
  }

  void _listenNbRequests() {
    _nbRequestsSub?.cancel();
    _nbRequestsSub =
        FirestoreService().getActiveNeighborhoodRequests().listen((list) {
      _nbRequestsSnapshot = List<NeighborhoodRequest>.from(list);
      unawaited(_recomputeCereri());
    });
  }

  void _listenPrivateChat(String uid) {
    _privateChatSub?.cancel();
    _privateChatSub = FirebaseFirestore.instance
        .collection('private_chat_unreads')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      final count = (snap.data()?['count'] as num?)?.toInt() ?? 0;
      _privateChatUnreadCount = count < 0 ? 0 : count;
      notifyListeners();
    });
  }

  Future<void> _rebindNbChatListener() async {
    final pos = _currentPos;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    if (pos == null) {
      _nbChatSub?.cancel();
      _nbChatSub = null;
      _nbChatRoomId = null;
      _chatBadgeCount = 0;
      notifyListeners();
      return;
    }

    final room = await NeighborTelemetryRtdbService.instance
        .ensureNbRoomClaim(pos.latitude, pos.longitude);

    if (room == null || room.isEmpty) {
      await _unsubscribeFcmTopic();
      _nbChatSub?.cancel();
      _nbChatSub = null;
      _nbChatRoomId = null;
      _chatBadgeCount = 0;
      notifyListeners();
      return;
    }

    if (_nbRoomPushTopic != room) {
      final prev = _nbRoomPushTopic;
      _nbRoomPushTopic = room;
      if (prev != null && prev.isNotEmpty) {
        try {
          await FirebaseMessaging.instance
              .unsubscribeFromTopic('neighborhood_$prev');
        } catch (e) {
          Logger.debug(
            'MapBadgesController: FCM unsubscribe failed: $e',
            tag: 'MAP',
          );
        }
      }
      try {
        await FirebaseMessaging.instance
            .subscribeToTopic('neighborhood_$room');
      } catch (e) {
        Logger.debug(
          'MapBadgesController: FCM subscribe failed: $e',
          tag: 'MAP',
        );
      }
    }

    Future<void> applySnap(
      QuerySnapshot<Map<String, dynamic>> snap,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(
            '${MapQuickActionBadgePrefs.nbChatReadKeyPrefix}$room',
          ) ??
          0;
      final threshold = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final cutoff = DateTime.now().subtract(const Duration(minutes: 30));

      var n = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final sender = data['uid'] as String?;
        final ts = (data['createdAt'] as Timestamp?)?.toDate();
        if (sender == null || sender == myUid || ts == null) continue;
        if (ts.isBefore(cutoff)) continue;
        if (ts.isAfter(threshold)) n++;
      }
      _chatBadgeCount = n;
      notifyListeners();
    }

    final needNewSub = _nbChatRoomId != room || _nbChatSub == null;
    if (needNewSub) {
      _nbChatSub?.cancel();
      _nbChatRoomId = room;
      _nbChatSub = FirebaseFirestore.instance
          .collection('neighborhood_chats')
          .doc(room)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(80)
          .snapshots()
          .listen((snap) => unawaited(applySnap(snap)));
    }
  }

  Future<void> _recomputeCereri() async {
    final pos = _currentPos;
    if (pos == null) {
      _cereriCount = 0;
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final lastMs =
        prefs.getInt(MapQuickActionBadgePrefs.cereriFeedOpenedKey) ?? 0;
    final threshold = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final now = DateTime.now();
    final radiusKm = NeighborhoodRequestsManager.visibleRadiusKm;

    var n = 0;
    for (final b in _broadcastSnapshot) {
      if (!b.expiresAt.isAfter(now)) continue;
      if (b.passengerLat == 0 && b.passengerLng == 0) continue;
      final km = geolocator.Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            b.passengerLat,
            b.passengerLng,
          ) /
          1000.0;
      if (km > radiusKm) continue;
      if (b.createdAt.isAfter(threshold)) n++;
    }
    for (final r in _nbRequestsSnapshot) {
      if (r.resolved || !r.expiresAt.isAfter(now)) continue;
      final km = geolocator.Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            r.lat,
            r.lng,
          ) /
          1000.0;
      if (km > radiusKm) continue;
      if (r.createdAt.isAfter(threshold)) n++;
    }
    _cereriCount = n;
    notifyListeners();
  }

  Future<void> _unsubscribeFcmTopic() async {
    final prev = _nbRoomPushTopic;
    _nbRoomPushTopic = null;
    if (prev != null && prev.isNotEmpty) {
      try {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic('neighborhood_$prev');
      } catch (e) {
        Logger.debug(
          'MapBadgesController: FCM unsubscribe failed: $e',
          tag: 'MAP',
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  geolocator.Position? get _currentPos =>
      _positionProvider?.call() ??
      LocationCacheService.instance
          .peekRecent(maxAge: const Duration(minutes: 20));
}
