import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:intl/intl.dart';
import 'package:nabour_app/models/neighborhood_request_model.dart';
import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/map_qa_badge_prefs.dart';
import 'package:nabour_app/features/neighborhood_requests/nbhd_requests_manager.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/widgets/nabour_nametag_widget.dart';
import 'package:nabour_app/services/contacts_service.dart';
import 'package:nabour_app/l10n/app_localizations.dart';

/// Model pentru o cerere de cursă broadcast
class RideBroadcastRequest {
  final String id;
  final String passengerId;
  final String passengerName;
  final String passengerAvatar; // emoji animal
  final String message; // text liber
  final String? destination;
  final double passengerLat;
  final double passengerLng;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<DriverOffer> offers;
  final String? acceptedDriverId;
  final String? acceptedDriverName;
  final String? acceptedDriverAvatar;
  final String status; // 'open', 'accepted', 'completed', 'not_done', 'cancelled', 'expired'
  final String? completionStatus; // 'done', 'not_done'
  final String? notDoneReason;
  final bool passengerConfirmed;
  final bool driverConfirmed;
  final List<BroadcastReply> replies;
  final Map<String, String> reactions; // uid -> emoji
  final List<String> allowedUids; // ✅ RE-INTĂRIT: Filtru contacte

  const RideBroadcastRequest({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    required this.passengerAvatar,
    required this.message,
    this.destination,
    required this.passengerLat,
    required this.passengerLng,
    required this.createdAt,
    required this.expiresAt,
    required this.offers,
    this.acceptedDriverId,
    this.acceptedDriverName,
    this.acceptedDriverAvatar,
    required this.status,
    this.completionStatus,
    this.notDoneReason,
    this.passengerConfirmed = false,
    this.driverConfirmed = false,
    this.replies = const [],
    this.reactions = const {},
    this.allowedUids = const [],
  });

  factory RideBroadcastRequest.fromMap(String id, Map<String, dynamic> m) {
    final offersList = (m['offers'] as List<dynamic>? ?? [])
        .map((o) => DriverOffer.fromMap(o as Map<String, dynamic>))
        .toList();
    return RideBroadcastRequest(
      id: id,
      passengerId: m['passengerId'] as String? ?? '',
      passengerName: m['passengerName'] as String? ?? 'Vecin',
      passengerAvatar: m['passengerAvatar'] as String? ?? '🙂',
      message: m['message'] as String? ?? '',
      destination: m['destination'] as String?,
      passengerLat: (m['passengerLat'] as num?)?.toDouble() ?? 0,
      passengerLng: (m['passengerLng'] as num?)?.toDouble() ?? 0,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (m['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(minutes: 30)),
      offers: offersList,
      acceptedDriverId: m['acceptedDriverId'] as String?,
      acceptedDriverName: m['acceptedDriverName'] as String?,
      acceptedDriverAvatar: m['acceptedDriverAvatar'] as String?,
      status: m['status'] as String? ?? 'open',
      completionStatus: m['completionStatus'] as String?,
      notDoneReason: m['notDoneReason'] as String?,
      passengerConfirmed: m['passengerConfirmed'] as bool? ?? false,
      driverConfirmed: m['driverConfirmed'] as bool? ?? false,
      replies: (m['replies'] as List<dynamic>? ?? [])
          .map((r) => BroadcastReply.fromMap(r as Map<String, dynamic>))
          .toList(),
      reactions: Map<String, String>.from(m['reactions'] ?? {}),
      allowedUids: List<String>.from(m['allowedUids'] ?? []),
    );
  }
}

class BroadcastReply {
  final String uid;
  final String displayName;
  final String avatar;
  final String text;
  final DateTime createdAt;

  const BroadcastReply({
    required this.uid,
    required this.displayName,
    required this.avatar,
    required this.text,
    required this.createdAt,
  });

  factory BroadcastReply.fromMap(Map<String, dynamic> m) => BroadcastReply(
        uid: m['uid'] as String? ?? '',
        displayName: m['displayName'] as String? ?? 'Vecin',
        avatar: m['avatar'] as String? ?? '🙂',
        text: m['text'] as String? ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'avatar': avatar,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class DriverOffer {
  final String driverId;
  final String driverName;
  final String driverAvatar;
  final String carInfo; // "Dacia Logan · B 123 ABC"
  final int etaMinutes;
  final DateTime offeredAt;

  const DriverOffer({
    required this.driverId,
    required this.driverName,
    required this.driverAvatar,
    required this.carInfo,
    required this.etaMinutes,
    required this.offeredAt,
  });

  factory DriverOffer.fromMap(Map<String, dynamic> m) => DriverOffer(
        driverId: m['driverId'] as String? ?? '',
        driverName: m['driverName'] as String? ?? 'Driver',
        driverAvatar: m['driverAvatar'] as String? ?? '🚗',
        carInfo: m['carInfo'] as String? ?? '',
        etaMinutes: (m['etaMinutes'] as num?)?.toInt() ?? 5,
        offeredAt: (m['offeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'driverId': driverId,
        'driverName': driverName,
        'driverAvatar': driverAvatar,
        'carInfo': carInfo,
        'etaMinutes': etaMinutes,
        'offeredAt': Timestamp.fromDate(offeredAt),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed de cereri din cartier — vizibil atât pasagerilor cât și șoferilor
// ─────────────────────────────────────────────────────────────────────────────

class RideBroadcastFeedScreen extends StatefulWidget {
  const RideBroadcastFeedScreen({super.key});

  @override
  State<RideBroadcastFeedScreen> createState() =>
      _RideBroadcastFeedScreenState();
}

class _RideBroadcastFeedScreenState extends State<RideBroadcastFeedScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late TabController _tabController;

  geo.Position? _userPosition;
  static const double _radiusKm = 6.0;
  Timer? _expireTimer;

  /// Schimbă la pull-to-refresh ca StreamBuilder să se re-aboneze la query (recepție / cache).
  int _activeFeedSalt = 0;

  /// Un singur abonament Firestore — dacă [getActiveNeighborhoodRequests] e apelat la fiecare
  /// rebuild, StreamBuilder reziliază listenerul și poate rămâne goală lista în ciuda bulelor de pe hartă.
  late final Stream<List<NeighborhoodRequest>> _neighborhoodBubblesStream =
      FirestoreService().getActiveNeighborhoodRequests();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(MapQuickActionBadgePrefs.markCereriFeedOpened());
    });
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || !mounted) return;
      if (_tabController.index == 1) {
        unawaited(_loadUserPosition());
      }
      setState(() {});
    });
    _loadUserPosition();
    // Reîncarcă feed-ul la fiecare minut pentru a elimina cererile expirate
    _expireTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _expireTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPosition() async {
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.reduced,
        ),
      ).timeout(const Duration(seconds: 6));
      if (mounted) setState(() => _userPosition = pos);
    } catch (e) {
      Logger.debug('RideBroadcast._loadUserPosition failed: $e', tag: 'RIDE_BROADCAST');
    }
  }

  /// Distanța în km față de o postare. Null dacă locația nu e disponibilă.
  double? _distanceTo(RideBroadcastRequest r) {
    if (_userPosition == null) return null;
    if (r.passengerLat == 0 && r.passengerLng == 0) return null;
    return geo.Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          r.passengerLat,
          r.passengerLng,
        ) /
        1000;
  }

  double? _distanceToNeighborhoodBubble(NeighborhoodRequest r) {
    if (_userPosition == null) return null;
    return geo.Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          r.lat,
          r.lng,
        ) /
        1000;
  }

  Stream<List<RideBroadcastRequest>> _buildActiveFeedStream() {
    final uid = _auth.currentUser?.uid;
    final expiryCutoff = Timestamp.fromDate(DateTime.now());
    Query<Map<String, dynamic>> query = _firestore
        .collection('ride_broadcasts')
        .where('status', isEqualTo: 'open')
        .where('expiresAt', isGreaterThan: expiryCutoff);

    if (uid != null) {
      query = query.where('allowedUids', arrayContains: uid);
    }

    return query
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RideBroadcastRequest.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<RideBroadcastRequest>> get _historyStream {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('ride_broadcasts')
        .where('passengerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RideBroadcastRequest.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> _deleteBroadcast(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rideBroadcastDeleteRequestTitle),
        content: Text(l10n.rideBroadcastDeleteRequestConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _firestore.collection('ride_broadcasts').doc(id).delete();
    } catch (e) {
      Logger.error('Error deleting broadcast: $e', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rideBroadcastFeedTitle),
        centerTitle: true,
        actions: [
          if (_userPosition != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message:
                    l10n.rideBroadcastActiveRadiusTooltip(_radiusKm.toInt()),
                child: Chip(
                  avatar: const Icon(Icons.radar_rounded, size: 14, color: Color(0xFF7C3AED)),
                  label: Text('${_radiusKm.toInt()} km',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF7C3AED), fontWeight: FontWeight.w700)),
                  backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.10),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF7C3AED),
          tabs: [
            Tab(text: l10n.rideBroadcastTabActive),
            Tab(text: l10n.rideBroadcastTabMapBubbles),
            Tab(text: l10n.rideBroadcastTabMyHistory),
          ],
        ),
      ),
      floatingActionButton: (_tabController.index == 0 ||
              _tabController.index == 1)
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (_tabController.index == 0) {
                  final result = await Navigator.push<RideBroadcastPostResult?>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NewRideBroadcastScreen()),
                  );
                  if (!context.mounted) return;
                  if (result == null) return;
                  if (result.warnNoNabourContacts) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.rideBroadcastVisibleOnlyForYouNoContacts,
                        ),
                        backgroundColor: Colors.orange.shade800,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  } else if (result.nabourContactsInAgenda > 0) {
                    final n = result.nabourContactsInAgenda;
                    final people =
                        n == 1 ? '1 contact Nabour' : '$n contacte Nabour';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(l10n.rideBroadcastVisibleForYouAndContacts(people)),
                        backgroundColor: Colors.green.shade800,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                  return;
                }
                await _loadUserPosition();
                final p = _userPosition;
                if (!context.mounted) return;
                if (p == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.rideBroadcastEnableLocationForMapRequest,
                      ),
                    ),
                  );
                  return;
                }
                NeighborhoodRequestsManager.showCreateRequestSheet(
                  context,
                  p.latitude,
                  p.longitude,
                );
              },
              icon: Icon(_tabController.index == 0
                  ? Icons.directions_car_rounded
                  : Icons.water_drop_rounded),
              label: Text(_tabController.index == 0
                  ? l10n.rideBroadcastRequestRide
                  : l10n.rideBroadcastMapRequest),
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Cereri active ──────────────────────────────────
          StreamBuilder<List<RideBroadcastRequest>>(
            key: ValueKey(_activeFeedSalt),
            stream: _buildActiveFeedStream(),
            builder: (context, snap) {
              Future<void> onPullRefresh() async {
                setState(() => _activeFeedSalt++);
                await Future<void>.delayed(const Duration(milliseconds: 150));
              }

              if (snap.connectionState == ConnectionState.waiting) {
                return RefreshIndicator(
                  onRefresh: onPullRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 120),
                    children: const [
                      Center(child: CircularProgressIndicator()),
                    ],
                  ),
                );
              }
              final all = snap.data ?? [];
              final requests = all.where((r) {
                final d = _distanceTo(r);
                if (d == null) return true;
                return d <= _radiusKm;
              }).toList();
              if (requests.isEmpty) {
                final showRadiusHint =
                    all.isNotEmpty && _userPosition != null;
                return RefreshIndicator(
                  onRefresh: onPullRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      showRadiusHint
                          ? _buildRadiusFilteredEmptyState(theme)
                          : _buildEmptyState(theme),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: onPullRefresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: requests.length,
                  itemBuilder: (_, i) => _BroadcastCard(
                    request: requests[i],
                    distanceKm: _distanceTo(requests[i]),
                    currentUid: uid,
                    onOfferAccepted: () => setState(() {}),
                  ),
                ),
              );
            },
          ),
          // ── Tab 2: Bule pe hartă — același stream ca harta; filtru 6 km (ca tab „Active”).
          StreamBuilder<List<NeighborhoodRequest>>(
            stream: _neighborhoodBubblesStream,
            builder: (context, snap) {
              Future<void> onPullRefresh() async {
                await _loadUserPosition();
                if (mounted) setState(() {});
                await Future<void>.delayed(const Duration(milliseconds: 120));
              }

              if (snap.hasError) {
                return RefreshIndicator(
                  onRefresh: onPullRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Text(
                        l10n.rideBroadcastBubblesLoadFailed(snap.error.toString()),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return RefreshIndicator(
                  onRefresh: onPullRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 120),
                    children: const [
                      Center(child: CircularProgressIndicator()),
                    ],
                  ),
                );
              }

              final clientNow = DateTime.now();
              final raw = snap.data ?? [];
              // Fără snapshot nou, Firestore poate livra încă doc-uri expirate — refiltrăm la fiecare build (timer 1 min).
              final stillActive = raw
                  .where(
                    (r) => !r.resolved && r.expiresAt.isAfter(clientNow),
                  )
                  .toList();
              final bubbles = stillActive.where((r) {
                final d = _distanceToNeighborhoodBubble(r);
                if (d == null) return true;
                return d <= _radiusKm;
              }).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (bubbles.isEmpty) {
                final onlyOutsideRadius = stillActive.isNotEmpty &&
                    _userPosition != null;
                return RefreshIndicator(
                  onRefresh: onPullRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🫧', style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 16),
                            Text(
                              onlyOutsideRadius
                                  ? l10n.rideBroadcastNoBubbleInRadius(_radiusKm.toInt())
                                  : l10n.rideBroadcastNoActiveBubbleHere,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              onlyOutsideRadius
                                  ? l10n.rideBroadcastBubblesOutsideRadiusHint(_radiusKm.toInt())
                                  : l10n.rideBroadcastBubblesVisibilityHint,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                                height: 1.45,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final fmt = DateFormat(
                'dd.MM.yyyy · HH:mm',
                Localizations.localeOf(context).languageCode,
              );
              return RefreshIndicator(
                onRefresh: onPullRefresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: bubbles.length,
                  itemBuilder: (_, i) {
                    final r = bubbles[i];
                    return _NeighborhoodBubbleFeedCard(
                      request: r,
                      distanceKm: _distanceToNeighborhoodBubble(r),
                      createdLabel: fmt.format(r.createdAt),
                      expiresLabel: fmt.format(r.expiresAt),
                      currentUid: uid,
                    );
                  },
                ),
              );
            },
          ),
          // ── Tab 3: Istoricul meu ──────────────────────────────────
          StreamBuilder<List<RideBroadcastRequest>>(
            stream: _historyStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final history = snap.data ?? [];
              if (history.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📋', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(l10n.rideBroadcastNoPostedRequestYet,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: history.length,
                itemBuilder: (_, i) => _HistoryCard(
                  request: history[i],
                  currentUid: uid,
                  onDelete: () => _deleteBroadcast(history[i].id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏘️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              l10n.rideBroadcastNoActiveRequest,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.rideBroadcastBeFirstHint,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.rideBroadcastFriendPostedButNotVisibleHint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey.shade500, height: 1.45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusFilteredEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📍', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              l10n.rideBroadcastNoRequestInRadius(_radiusKm.toInt()),
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.rideBroadcastIncludedButFarHint,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.rideBroadcastWaitingFriendHint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey.shade500, height: 1.45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rând în tab-ul „Bule pe hartă” — aceleași documente ca markerii de pe hartă.
class _NeighborhoodBubbleFeedCard extends StatelessWidget {
  final NeighborhoodRequest request;
  final String? currentUid;
  final double? distanceKm;
  final String createdLabel;
  final String expiresLabel;

  const _NeighborhoodBubbleFeedCard({
    required this.request,
    required this.currentUid,
    this.distanceKm,
    required this.createdLabel,
    required this.expiresLabel,
  });

  String _emojiForType(String type) {
    switch (type) {
      case 'ride':
        return '🚗';
      case 'help':
        return '🛠️';
      case 'tool':
        return '🔧';
      case 'alert':
        return '🚨';
      default:
        return '🫧';
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rideBroadcastDeleteMapRequestTitle),
        content: Text(l10n.rideBroadcastDeleteMapRequestConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await FirestoreService().deleteNeighborhoodRequest(request.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.rideBroadcastMapBubbleDeleted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rideBroadcastDeleteFailed(e.toString())),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMine =
        currentUid != null && currentUid == request.authorUid && currentUid!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_emojiForType(request.type), style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    request.message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                if (isMine)
                  IconButton(
                    tooltip: l10n.rideBroadcastDeleteFromMapTooltip,
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade700),
                    onPressed: () => unawaited(_confirmDelete(context)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.authorName,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.rideBroadcastPlaced(createdLabel),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              l10n.rideBroadcastExpiresMapBubble(expiresLabel),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.deepOrange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (distanceKm != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.rideBroadcastDistanceFromYou(distanceKm!.toStringAsFixed(1)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7C3AED),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card individual pentru o cerere
// ─────────────────────────────────────────────────────────────────────────────

class _BroadcastCard extends StatefulWidget {
  final RideBroadcastRequest request;
  final String? currentUid;
  final double? distanceKm;
  final VoidCallback onOfferAccepted;

  const _BroadcastCard({
    required this.request,
    required this.currentUid,
    this.distanceKm,
    required this.onOfferAccepted,
  });

  @override
  State<_BroadcastCard> createState() => _BroadcastCardState();
}

class _BroadcastCardState extends State<_BroadcastCard> {
  bool _isOffering = false;
  bool _isReplying = false;
  final _replyController = TextEditingController();
  /// Profilul utilizatorului curent (o singură citire Firestore per card, nu la fiecare răspuns/ofertă).
  Map<String, dynamic>? _myProfileCache;

  @override
  void initState() {
    super.initState();
    _prefetchMyProfile();
  }

  Future<void> _prefetchMyProfile() async {
    final uid = widget.currentUid;
    if (uid == null || uid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!mounted) return;
      setState(() => _myProfileCache = doc.data());
    } catch (e) {
      Logger.error('prefetch profile for broadcast card: $e', error: e);
    }
  }

  Future<Map<String, dynamic>> _resolveMyProfile() async {
    if (_myProfileCache != null) return _myProfileCache!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = userDoc.data() ?? {};
      if (mounted) setState(() => _myProfileCache = data);
      return data;
    } catch (_) {
      return {};
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  bool get _isMyRequest =>
      widget.request.passengerId == widget.currentUid;

  bool get _hasMyOffer =>
      widget.request.offers.any((o) => o.driverId == widget.currentUid);

  String _timeLeft() {
    final diff = widget.request.expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'expirat';
    if (diff.inMinutes < 1) return '< 1 min';
    return '${diff.inMinutes} min';
  }

  Future<void> _cancelRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rideBroadcastCancelRequestTitle),
        content: Text(l10n.rideBroadcastCancelRequestConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.rideBroadcastNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.rideBroadcastYesCancel,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('ride_broadcasts')
          .doc(widget.request.id)
          .update({'status': 'cancelled'});
    } catch (e) {
      Logger.error('Error cancelling broadcast: $e', error: e);
    }
  }

  Future<void> _offerRide() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isOffering || _hasMyOffer) return;
    setState(() => _isOffering = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final data = await _resolveMyProfile();
      final name = data['displayName'] as String? ?? 'Vecin';
      final avatar = data['avatar'] as String? ?? '🚗';
      final brand = data['carBrand'] as String? ?? '';
      final model = data['carModel'] as String? ?? '';
      final plate = data['licensePlate'] as String? ?? '';
      final carInfo = [
        if (brand.isNotEmpty) brand,
        if (model.isNotEmpty) model,
        if (plate.isNotEmpty) '· $plate',
      ].join(' ');

      final offer = DriverOffer(
        driverId: uid,
        driverName: name,
        driverAvatar: avatar,
        carInfo: carInfo.isEmpty ? l10n.rideBroadcastPersonalCar : carInfo,
        etaMinutes: 5,
        offeredAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('ride_broadcasts')
          .doc(widget.request.id)
          .update({
        'offers': FieldValue.arrayUnion([offer.toMap()]),
      });
    } catch (e) {
      Logger.error('Error offering ride: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rideBroadcastOfferSendFailed(e.toString())),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOffering = false);
    }
  }

  Future<void> _sendReply() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final data = await _resolveMyProfile();
      final name = data['displayName'] as String? ?? 'Vecin';
      final avatar = data['avatar'] as String? ?? '🙂';

      final reply = BroadcastReply(
        uid: uid,
        displayName: name,
        avatar: avatar,
        text: text,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('ride_broadcasts')
          .doc(widget.request.id)
          .update({
        'replies': FieldValue.arrayUnion([reply.toMap()]),
      });

      // Mai multe mesaje la aceeași cerere: după succes rămâi în modul răspuns;
      // golește doar câmpul (textul nu se pierde dacă rețeaua pică).
      if (mounted) {
        _replyController.clear();
        setState(() {});
      }
    } catch (e) {
      Logger.error('Error sending reply: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rideBroadcastReplySendFailed(e.toString())),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleReaction(String emoji) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final current = widget.request.reactions[uid];
    final Map<String, dynamic> update = {};
    
    if (current == emoji) {
      update['reactions.$uid'] = FieldValue.delete();
    } else {
      update['reactions.$uid'] = emoji;
    }

    try {
      await FirebaseFirestore.instance
          .collection('ride_broadcasts')
          .doc(widget.request.id)
          .update(update);
    } catch (e) {
      Logger.error('Error toggling reaction: $e', error: e);
    }
  }

  Future<void> _acceptOffer(DriverOffer offer) async {
    await FirebaseFirestore.instance
        .collection('ride_broadcasts')
        .doc(widget.request.id)
        .update({
      'status': 'accepted',
      'acceptedDriverId': offer.driverId,
      'acceptedDriverName': offer.driverName,
      'acceptedDriverAvatar': offer.driverAvatar,
    });
    widget.onOfferAccepted();
  }

  bool get _isAcceptedDriver =>
      widget.request.status == 'accepted' &&
      widget.request.acceptedDriverId == widget.currentUid;

  bool get _isAccepted => widget.request.status == 'accepted';

  void _openChat(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final request = widget.request;
    final isPassenger = _isMyRequest;
    final otherUserId = isPassenger ? request.acceptedDriverId! : request.passengerId;
    final otherUserName = isPassenger ? (request.acceptedDriverName ?? l10n.rideBroadcastDriverFallback) : request.passengerName;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(
        rideId: 'broadcast_${request.id}',
        otherUserId: otherUserId,
        otherUserName: otherUserName,
      ),
    ));
  }

  Future<void> _confirmRide(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rideBroadcastConfirmRideTitle),
        content: Text(l10n.rideBroadcastRideCompletedQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.rideBroadcastNotCompleted, style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(l10n.rideBroadcastCompletedYes),
          ),
        ],
      ),
    );
    if (done == null || !context.mounted) return;

    String? reason;
    if (!done) {
      final reasons = [
        l10n.rideBroadcastReasonDriverNoShow,
        l10n.rideBroadcastReasonPassengerCancelled,
        l10n.rideBroadcastReasonAnotherCar,
        l10n.rideBroadcastReasonOther,
      ];
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(l10n.rideBroadcastReasonTitle),
          children: [
            ...reasons.map((r) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r),
              child: Text(r),
            )),
          ],
        ),
      );
      if (reason == null || !context.mounted) return;
    }

    final isPassenger = _isMyRequest;
    await FirebaseFirestore.instance
        .collection('ride_broadcasts')
        .doc(widget.request.id)
        .update({
      'status': 'completed',
      'completionStatus': done ? 'done' : 'not_done',
      if (!done && reason != null) 'notDoneReason': reason,
      if (isPassenger) 'passengerConfirmed': true,
      if (!isPassenger) 'driverConfirmed': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final request = widget.request;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + nume + timp rămas ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                NabourNametagWidget.bubble(
                  avatar: request.passengerAvatar,
                  displayName: request.passengerName,
                  size: 46,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.rideBroadcastExpiresIn(_timeLeft()),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                if (widget.distanceKm != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me_rounded,
                              size: 11, color: Colors.blue.shade600),
                          const SizedBox(width: 3),
                          Text(
                            widget.distanceKm! < 1
                                ? '${(widget.distanceKm! * 1000).round()} m'
                                : '${widget.distanceKm!.toStringAsFixed(1)} km',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isMyRequest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.rideBroadcastMyRequest,
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),

          // ── Mesajul cererii ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              request.message,
              style:
                  theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),

          // ── Reacții rapide ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Wrap(
              spacing: 12,
              children: ['👍', '❤️', '👏', '😮'].map((emoji) {
                final count = request.reactions.values.where((v) => v == emoji).length;
                final isSelected = request.reactions[widget.currentUid] == emoji;
                return GestureDetector(
                  onTap: () => _toggleReaction(emoji),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7C3AED).withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF7C3AED).withValues(alpha: 0.3) : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF7C3AED) : Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (request.destination != null && request.destination!.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(left: 14, right: 14, top: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.destination!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // ── Oferte primite (vizibil pasagerului) ─────────────────
          if (_isMyRequest && request.offers.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                l10n.rideBroadcastAvailableDrivers,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
            ...request.offers.map(
              (offer) => _OfferTile(
                offer: offer,
                onAccept: () => _acceptOffer(offer),
              ),
            ),
          ],

          // ── Răspunsuri (Replica locală de chat) ────────────────
          if (request.replies.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                l10n.rideBroadcastReplies,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: request.replies.map((reply) => _ReplyItem(reply: reply)).toList(),
              ),
            ),
          ],

          // ── Câmp răspuns ────────────────────────────────────────
          if (_isReplying)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.close,
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                    onPressed: () {
                      _replyController.clear();
                      setState(() => _isReplying = false);
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.rideBroadcastReplyHint,
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onSubmitted: (_) => _sendReply(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF7C3AED)),
                    onPressed: _sendReply,
                  ),
                ],
              ),
            ),

          // ── Butoane acțiune ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                // Număr oferte
                if (request.offers.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      request.offers.length == 1
                          ? l10n.rideBroadcastOffersOne(request.offers.length)
                          : l10n.rideBroadcastOffersMany(request.offers.length),
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                const Spacer(),
                // Buton Răspunde
                if (!_isAccepted && !_isReplying)
                  SizedBox(
                    height: 36,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _isReplying = true),
                      icon: const Icon(Icons.reply_rounded, size: 16),
                      label: Text(l10n.chatReply,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),

                // Buton "Anulează" (vizibil pasagerului)
                if (_isMyRequest)
                  SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: _cancelRequest,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(l10n.cancel,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                // Butoane Chat + Confirmă (după acceptare)
                if (_isAccepted && (_isMyRequest || _isAcceptedDriver)) ...[
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () => _openChat(context),
                      icon: const Icon(Icons.chat_rounded, size: 16),
                      label: Text(l10n.chat, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmRide(context),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text(l10n.confirm, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ],
                // Buton "Mă ofer" (vizibil șoferilor)
                if (!_isMyRequest && !_isAccepted)
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: _hasMyOffer ? null : _offerRide,
                      icon: _isOffering
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              _hasMyOffer
                                  ? Icons.check_rounded
                                  : Icons.directions_car_rounded,
                              size: 16,
                            ),
                      label: Text(
                        _hasMyOffer ? l10n.rideBroadcastOfferSent : l10n.rideBroadcastIOffer,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasMyOffer
                            ? Colors.grey.shade200
                            : const Color(0xFF7C3AED),
                        foregroundColor: _hasMyOffer
                            ? Colors.grey.shade600
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widget pentru un mesaj de răspuns
// ─────────────────────────────────────────────────────────────────────────────

class _ReplyItem extends StatelessWidget {
  final BroadcastReply reply;
  const _ReplyItem({required this.reply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMe = reply.uid == FirebaseAuth.instance.currentUser?.uid;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reply.avatar, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMe
                    ? cs.primary.withValues(alpha: 0.12)
                    : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isMe
                      ? cs.primary.withValues(alpha: 0.35)
                      : cs.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reply.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reply.text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile pentru o ofertă de șofer
// ─────────────────────────────────────────────────────────────────────────────

class _OfferTile extends StatelessWidget {
  final DriverOffer offer;
  final VoidCallback onAccept;

  const _OfferTile({required this.offer, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          NabourNametagWidget.bubble(
            avatar: offer.driverAvatar,
            displayName: offer.driverName,
            size: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${offer.carInfo} · ~${offer.etaMinutes} min',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onAccept,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Alege',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card istoric
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final RideBroadcastRequest request;
  final String? currentUid;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.request,
    required this.currentUid,
    required this.onDelete,
  });

  String _statusLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (request.status) {
      case 'completed': return request.completionStatus == 'done' ? l10n.rideBroadcastStatusDone : l10n.rideBroadcastStatusNotDone;
      case 'accepted': return l10n.rideBroadcastStatusAccepted;
      case 'cancelled': return l10n.rideBroadcastStatusCancelled;
      case 'open': return l10n.rideBroadcastStatusActive;
      default: return l10n.rideBroadcastStatusExpired;
    }
  }

  Color _statusColor() {
    switch (request.status) {
      case 'completed': return request.completionStatus == 'done' ? Colors.green : Colors.red;
      case 'accepted': return Colors.blue;
      case 'cancelled': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final local = request.createdAt.toLocal();
    final date = '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}, '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel(context), style: TextStyle(fontSize: 12, color: _statusColor(), fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(
                date,
                style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade300),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.message,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (request.destination != null && request.destination!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on_rounded, size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.destination!,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ],
          if (request.acceptedDriverName != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.drive_eta_rounded, size: 13, color: Color(0xFF7C3AED)),
              const SizedBox(width: 4),
              Text(l10n.rideBroadcastDriverWithName(request.acceptedDriverName!), style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
            ]),
          ],
          if (request.notDoneReason != null && request.notDoneReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(l10n.rideBroadcastReasonWithValue(request.notDoneReason!), style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ecran nou: postează o cerere de cursă
// ─────────────────────────────────────────────────────────────────────────────

/// Rezultat după postare (SnackBar-uri pe ecranul feed).
class RideBroadcastPostResult {
  const RideBroadcastPostResult({
    required this.warnNoNabourContacts,
    required this.nabourContactsInAgenda,
  });

  /// Niciun contact din agendă nu are cont Nabour potrivit — cererea e doar pentru tine.
  final bool warnNoNabourContacts;

  /// Utilizatori Nabour detectați în agendă (fără a te include pe tine).
  final int nabourContactsInAgenda;
}

class NewRideBroadcastScreen extends StatefulWidget {
  const NewRideBroadcastScreen({super.key});

  @override
  State<NewRideBroadcastScreen> createState() =>
      _NewRideBroadcastScreenState();
}

class _NewRideBroadcastScreenState
    extends State<NewRideBroadcastScreen> {
  final _messageController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _isPosting = false;

  /// Limitare soft anti-spam: cereri simultan „open” per pasager.
  static const int _maxOpenBroadcastsPerPassenger = 3;

  static const List<String> _quickMessages = [
    'Going to the supermarket, anyone has a free seat? 🛒',
    'Heading to the metro station, anyone going? 🚇',
    'I am going downtown in ~10 min ✌️',
    'I need to get to the hospital urgently 🏥',
    'Going to school with my child, any seat available? 👧',
    'Heading to the airport this morning ✈️',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final l10n = AppLocalizations.of(context)!;
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;
    setState(() => _isPosting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _isPosting = false);
        return;
      }

      final openExisting = await FirebaseFirestore.instance
          .collection('ride_broadcasts')
          .where('passengerId', isEqualTo: uid)
          .where('status', isEqualTo: 'open')
          .limit(_maxOpenBroadcastsPerPassenger)
          .get();
      if (openExisting.docs.length >= _maxOpenBroadcastsPerPassenger) {
        if (mounted) {
          setState(() => _isPosting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.rideBroadcastTooManyActiveRequests(_maxOpenBroadcastsPerPassenger),
              ),
              backgroundColor: Colors.orange.shade900,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final now = DateTime.now();

      // Preia locația, profilul și contactele în paralel. Contactele din cache
      // (fără forceRefresh) evită o rescanare completă a agendei la fiecare postare.
      Future<geo.Position?> safeGetPosition() async {
        try {
          return await geo.Geolocator.getCurrentPosition(
            locationSettings:
                const geo.LocationSettings(accuracy: geo.LocationAccuracy.high),
          ).timeout(const Duration(seconds: 5));
        } catch (_) {
          return null;
        }
      }

      Future<Map<String, dynamic>> safeGetUserData() async {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          return userDoc.data() ?? <String, dynamic>{};
        } catch (_) {
          return <String, dynamic>{};
        }
      }

      final futures = await Future.wait([
        safeGetPosition(),
        safeGetUserData(),
        ContactsService().loadContactUids(forceRefresh: false),
      ]);

      final geo.Position? pos = futures[0] as geo.Position?;
      final Map<String, dynamic> data = futures[1] as Map<String, dynamic>;
      final Set<String> contactUids = futures[2] as Set<String>;

      final double lat = pos?.latitude ?? 0;
      final double lng = pos?.longitude ?? 0;
      final String name = data['displayName'] as String? ?? 'Vecin';
      final String avatar = data['avatar'] as String? ?? '🙂';

      // IMPORTANT: trebuie să includem și UID-ul pasagerului creator,
      // altfel el nu își vede cererea în tab-ul "Active" (filtru allowedUids).
      final allowedUids = <String>{...contactUids, uid}.toList();

      Logger.info(
        'ride_broadcast post: nabourContactsInAgenda=${contactUids.length} '
        'allowedUidsTotal=${allowedUids.length}',
        tag: 'BROADCAST',
      );

      await FirebaseFirestore.instance
          .collection('ride_broadcasts')
          .add({
        'passengerId': uid,
        'passengerName': name,
        'passengerAvatar': avatar,
        'message': msg,
        'destination': _destinationController.text.trim(),
        'passengerLat': lat,
        'passengerLng': lng,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt':
            Timestamp.fromDate(now.add(const Duration(minutes: 30))),
        'offers': [],
        'replies': [],
        'reactions': {},
        'status': 'open',
        'allowedUids': allowedUids, // ✅ RE-INTĂRIT: Filtru contacte
      });

      // Stop spinner immediately after write succeeds.
      // `true` = zero Nabour contacts în agendă → SnackBar explicativ pe feed.
      if (mounted) {
        setState(() => _isPosting = false);
        Navigator.of(context).pop(RideBroadcastPostResult(
          warnNoNabourContacts: contactUids.isEmpty,
          nabourContactsInAgenda: contactUids.length,
        ));
      }
    } catch (e) {
      Logger.error('Error posting broadcast: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.rideBroadcastErrorWithMessage(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rideBroadcastAskRideTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hint (contrast sigur light + dark) ────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.rideBroadcastPostVisibilityHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.92),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── Quick chips: inverseSurface + onInverseSurface (pilule citibile mereu) ──
            Text(
              l10n.rideBroadcastQuickSelectOrWrite,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickMessages.map((msg) {
                return GestureDetector(
                  onTap: () =>
                      setState(() => _messageController.text = msg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.inverseSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      msg,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onInverseSurface,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // ── Mesaj liber ───────────────────────────────────────
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 200,
              style: TextStyle(color: cs.onSurface),
              cursorColor: cs.primary,
              decoration: InputDecoration(
                labelText: l10n.rideBroadcastYourMessageRequired,
                hintText: l10n.rideBroadcastMessageHint,
                labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.85)),
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.45)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 12),

            // ── Destinație (opțional) ─────────────────────────────
            TextField(
              controller: _destinationController,
              style: TextStyle(color: cs.onSurface),
              cursorColor: cs.primary,
              decoration: InputDecoration(
                labelText: l10n.rideBroadcastDestinationOptional,
                hintText: l10n.rideBroadcastDestinationHint,
                labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.85)),
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.45)),
                prefixIcon: Icon(Icons.location_on_outlined, color: cs.onSurfaceVariant),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 28),

            // ── Postează ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isPosting ? null : _post,
                icon: _isPosting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  l10n.rideBroadcastPostRequest,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.rideBroadcastExpiresAfterThirtyMinutes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
