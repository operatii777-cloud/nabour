import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/widgets/nabour_nametag_widget.dart';
import 'package:nabour_app/services/contacts_service.dart';

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
        driverName: m['driverName'] as String? ?? 'Șofer',
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    } catch (_) {}
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge cererea'),
        content: const Text('Ești sigur că vrei să ștergi această cerere din istoricul tău?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anulează')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Șterge', style: TextStyle(color: Colors.red))),
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
    final theme = Theme.of(context);
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cereri din cartier'),
        centerTitle: true,
        actions: [
          if (_userPosition != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message:
                    'În tab-ul „Active” afișăm cererile în cel mult ${_radiusKm.toInt()} km față de locația ta curentă (când locația e disponibilă).',
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
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Istoricul meu'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<RideBroadcastPostResult?>(
            context,
            MaterialPageRoute(builder: (_) => const NewRideBroadcastScreen()),
          );
          if (!context.mounted) return;
          if (result == null) return;
          if (result.warnNoNabourContacts) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Cererea e vizibilă doar pentru tine: în agendă nu am găsit alți utilizatori Nabour cu numărul din profilul lor.',
                ),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 6),
              ),
            );
          } else if (result.nabourContactsInAgenda > 0) {
            final n = result.nabourContactsInAgenda;
            final people = n == 1 ? '1 contact Nabour' : '$n contacte Nabour';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cererea e vizibilă pentru tine și pentru încă $people din agendă.',
                ),
                backgroundColor: Colors.green.shade800,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        icon: const Icon(Icons.directions_car_rounded),
        label: const Text('Cer o cursă'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
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
          // ── Tab 2: Istoricul meu ──────────────────────────────────
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
                        Text('Nicio cerere postată încă',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏘️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Nicio cerere activă',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Fii primul din cartier care postează o cerere de cursă.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Dacă un prieten a postat dar nu vezi: trage în jos pentru reîmprospătare, verifică că îl ai în agendă cu același număr ca în profilul Nabour și că ai permisiune la contacte.',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📍', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Nicio cerere în raza de ${_radiusKm.toInt()} km',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Există cereri în care ești inclus, dar sunt mai departe față de locația ta curentă. Te apropii sau pornești locația pentru filtre corecte.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Dacă aștepți de la un prieten apropiat, verifică și agendă + profilul Nabour cu același număr.',
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anulează cererea'),
        content: const Text('Ești sigur că vrei să anulezi această cerere?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nu'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Da, anulează',
                style: TextStyle(color: Colors.red)),
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
        carInfo: carInfo.isEmpty ? 'Mașină personală' : carInfo,
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
            content: Text('Nu s-a putut trimite oferta: $e'),
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
            content: Text('Nu s-a putut trimite răspunsul: $e'),
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
    final request = widget.request;
    final isPassenger = _isMyRequest;
    final otherUserId = isPassenger ? request.acceptedDriverId! : request.passengerId;
    final otherUserName = isPassenger ? (request.acceptedDriverName ?? 'Șofer') : request.passengerName;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(
        rideId: 'broadcast_${request.id}',
        otherUserId: otherUserId,
        otherUserName: otherUserName,
      ),
    ));
  }

  Future<void> _confirmRide(BuildContext context) async {
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmă cursa'),
        content: const Text('Cursa s-a efectuat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nu s-a efectuat', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Da, s-a efectuat'),
          ),
        ],
      ),
    );
    if (done == null || !context.mounted) return;

    String? reason;
    if (!done) {
      final reasons = ['Șoferul nu a mai venit', 'Pasagerul a anulat', 'Altă mașină', 'Alt motiv'];
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Motivul'),
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
                        'Expiră în ${_timeLeft()}',
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
                    child: const Text(
                      'Cererea mea',
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
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                'Șoferi disponibili',
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
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                'Răspunsuri',
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
                    tooltip: 'Închide',
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
                        hintText: 'Poți trimite mai multe mesaje — apasă trimitere pentru fiecare',
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
                      '${request.offers.length} ${request.offers.length == 1 ? 'ofertă' : 'oferte'}',
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
                      label: const Text('Răspunde',
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
                      label: const Text('Anulează',
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
                      label: const Text('Chat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
                      label: const Text('Confirmă', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
                        _hasMyOffer ? 'Ofertă trimisă' : 'Mă ofer',
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
                color: isMe ? const Color(0xFF7C3AED).withValues(alpha: 0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isMe ? const Color(0xFF7C3AED).withValues(alpha: 0.2) : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reply.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(height: 2),
                  Text(reply.text, style: const TextStyle(fontSize: 13)),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

  String _statusLabel() {
    switch (request.status) {
      case 'completed': return request.completionStatus == 'done' ? '✅ Efectuată' : '❌ Neefectuată';
      case 'accepted': return '🤝 Acceptată';
      case 'cancelled': return '🚫 Anulată';
      case 'open': return '🕐 Activă';
      default: return '⏱ Expirată';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
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
                child: Text(_statusLabel(), style: TextStyle(fontSize: 12, color: _statusColor(), fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade300),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(request.message, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (request.destination != null && request.destination!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on_rounded, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(child: Text(request.destination!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ],
          if (request.acceptedDriverName != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.drive_eta_rounded, size: 13, color: Color(0xFF7C3AED)),
              const SizedBox(width: 4),
              Text('Șofer: ${request.acceptedDriverName}', style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
            ]),
          ],
          if (request.notDoneReason != null && request.notDoneReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Motiv: ${request.notDoneReason}', style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontStyle: FontStyle.italic)),
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
    'Merg la supermarket, are cineva loc? 🛒',
    'Dus la stația de metrou, oricine merge? 🚇',
    'Merg spre centru în ~10 min ✌️',
    'Trebuie să ajung la spital, urgent 🏥',
    'Merg la școală cu copilul, loc disponibil? 👧',
    'Plecare spre aeroport dimineață ✈️',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _post() async {
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
              content: const Text(
                'Ai deja $_maxOpenBroadcastsPerPassenger cereri active. Închide sau așteaptă expirarea uneia (30 min) înainte de o nouă postare.',
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
              content: Text('Eroare: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cer o cursă'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hint ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cererea ta va fi vizibilă persoanelor din agenda ta timp de 30 de minute.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade700, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── Quick chips ───────────────────────────────────────
            Text('Selectează rapid sau scrie',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
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
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(msg,
                        style: const TextStyle(fontSize: 12)),
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
              decoration: InputDecoration(
                labelText: 'Mesajul tău *',
                hintText: 'Unde vrei să mergi? Orice detaliu util...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 12),

            // ── Destinație (opțional) ─────────────────────────────
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Destinație (opțional)',
                hintText: 'ex: Kaufland Titan, Stația Iancului...',
                prefixIcon: const Icon(Icons.location_on_outlined),
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
                label: const Text(
                  'Postează cererea',
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
                'Cererea expiră automat după 30 de minute.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
