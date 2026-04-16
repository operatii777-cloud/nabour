import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/utils/firestore_error_ui.dart';
import 'package:nabour_app/services/map_qa_badge_prefs.dart';
import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/utils/content_filter.dart';
import 'package:nabour_app/services/walkie_talkie_service.dart';
import 'package:nabour_app/core/ui/app_feedback.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/services/nbr_telem_rtdb_service.dart';

class NeighborhoodChatScreen extends StatefulWidget {
  const NeighborhoodChatScreen({super.key});

  @override
  State<NeighborhoodChatScreen> createState() =>
      _NeighborhoodChatScreenState();
}

class _NeighborhoodChatScreenState extends State<NeighborhoodChatScreen> {
  static const String _kLastRoomPrefKey = 'neighborhood_chat_last_room_id';
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  String? _roomId;
  bool _locating = true;
  String? _locationError;
  bool _isMuted = false;
  StreamSubscription? _msgSoundSub;
  Timer? _expireTimer;
  final _walkieTalkieService = WalkieTalkieService();
  bool _didInitDeps = false;

  // Profilul userului curent (cached)
  String _myAvatar = '🙂';
  String _myName = 'Vecin';
  String? _myPhotoUrl;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitDeps) return;
    _didInitDeps = true;
    unawaited(_init());
  }

  @override
  void dispose() {
    final rid = _roomId;
    if (rid != null && rid.isNotEmpty) {
      unawaited(MapQuickActionBadgePrefs.markNeighborhoodChatRead(rid));
    }
    _expireTimer?.cancel();
    _msgSoundSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _walkieTalkieService.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([_loadUserProfile(), _resolveRoom()]);
    await _loadMuteState(); // după _resolveRoom() — _roomId este setat corect
    _setupMessageListener();
    _cleanupOldMessages(); // șterge mesajele expirate la deschidere
    _expireTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {}); // refiltrează mesajele la fiecare minut
    });
  }

  /// Șterge mesajele mele mai vechi de 30 min (regulile Firestore permit doar delete pe propriile mesaje).
  Future<void> _cleanupOldMessages() async {
    if (_roomId == null) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(minutes: 30)),
    );
    try {
      final old = await _messagesRef
          .where('createdAt', isLessThan: cutoff)
          .get();
      if (old.docs.isEmpty) return;
      final batch = _firestore.batch();
      var n = 0;
      for (final doc in old.docs) {
        if ((doc.data()['uid'] as String?) != uid) continue;
        batch.delete(doc.reference);
        n++;
        if (n >= 400) break; // limit batch size
      }
      if (n > 0) await batch.commit();
    } catch (e) {
      Logger.error('NeighborhoodChat: cleanup error: $e', error: e);
    }
  }

  Future<void> _loadMuteState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _isMuted = prefs.getBool('chat_muted_$_roomId') ?? false);
  }

  Future<void> _toggleMute() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isMuted = !_isMuted;
      prefs.setBool('chat_muted_$_roomId', _isMuted);
    });
    if (!mounted) return;
    AppFeedback.info(
      context,
      _isMuted ? l10n.neighborhoodChatMuted : l10n.neighborhoodChatSoundOn,
      duration: const Duration(seconds: 2),
    );
  }

  void _setupMessageListener() {
    _msgSoundSub?.cancel();
    if (_roomId == null) return;
    
    // Ascultăm mesajele noi pentru a reda un sunet sau a face auto-play
    _msgSoundSub = _messagesRef
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isEmpty) return;
      final data = snap.docs.first.data();
      final senderUid = data['uid'] as String?;
      final myUid = _auth.currentUser?.uid;
      
      // Dacă mesajul e nou (ultimele 10s) și nu e de la noi
      final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
      if (senderUid != null && senderUid != myUid && !_isMuted &&
          timestamp != null && DateTime.now().difference(timestamp).inSeconds < 10) {
        
        // Dacă e mesaj vocal Walkie-Talkie, auto-play
        if (data['type'] == 'voice' && data['voiceUrl'] != null) {
          unawaited(_walkieTalkieService.playAudio(data['voiceUrl'] as String));
        } else {
          unawaited(_walkieTalkieService.playAsset('sounds/chat_sound.wav'));
          HapticFeedback.mediumImpact();
        }
      }
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      if (mounted) {
        setState(() {
          _myAvatar = data['avatar'] as String? ?? '🙂';
          _myName = data['displayName'] as String? ?? 'Vecin';
          final p = (data['photoURL'] as String?)?.trim();
          _myPhotoUrl = (p != null && p.isNotEmpty) ? p : null;
        });
      }
    } catch (e) {
      Logger.warning('NeighborhoodChat._loadUserProfile failed: $e', tag: 'NBR_CHAT');
    }
  }

  Future<void> _resolveRoom() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    try {
      final bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locating = false;
            _locationError = l10n.neighborhoodChatGpsDisabled;
          });
        }
        return;
      }
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.deniedForever ||
          permission == geo.LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locating = false;
            _locationError = l10n.neighborhoodChatGpsPermissionDenied;
          });
        }
        return;
      }

      geo.Position? pos;
      try {
        pos = await geo.Geolocator.getCurrentPosition(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.reduced,
          ),
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        pos = await geo.Geolocator.getLastKnownPosition();
      }

      String? resolvedRoom;
      if (pos != null) {
        resolvedRoom = await NeighborTelemetryRtdbService.instance
            .ensureNbRoomClaim(pos.latitude, pos.longitude, force: true);
      }

      resolvedRoom ??= prefs.getString(_kLastRoomPrefKey);
      if (resolvedRoom == null || resolvedRoom.isEmpty) {
        if (mounted) {
          setState(() {
            _locating = false;
            _locationError = l10n.neighborhoodChatActivationFailed;
          });
        }
        return;
      }

      try {
        await FirebaseMessaging.instance
            .subscribeToTopic('neighborhood_$resolvedRoom');
      } catch (e) {
        Logger.warning(
          'NeighborhoodChat: topic subscribe failed for $resolvedRoom: $e',
        );
      }

      await prefs.setString(_kLastRoomPrefKey, resolvedRoom);
      if (mounted) {
        setState(() {
          _roomId = resolvedRoom;
          _locating = false;
        });
        unawaited(
            MapQuickActionBadgePrefs.markNeighborhoodChatRead(resolvedRoom));
      }
    } catch (e) {
      Logger.error('NeighborhoodChat: location error: $e', error: e);
      if (mounted) setState(() { _locating = false; _locationError = l10n.neighborhoodChatLocationResolveFailed; });
    }
  }

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _firestore.collection('neighborhood_chats').doc(_roomId!).collection('messages');

  Future<void> _sendMessage() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _textController.text.trim();
    if (text.isEmpty || _roomId == null) return;

    final filterResult = ContentFilter.check(text);
    if (!filterResult.isClean) {
      AppFeedback.warning(context, filterResult.message ?? l10n.neighborhoodChatInappropriateMessage);
      return;
    }

    _textController.clear();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _messagesRef.add({
        'uid': uid,
        'avatar': _myAvatar,
        'displayName': _myName,
        if (_myPhotoUrl != null) 'photoURL': _myPhotoUrl,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } catch (e) { Logger.error('NeighborhoodChat: send error: $e'); }
  }

  Future<void> _sendOmw() async {
    final onMyWayText = AppLocalizations.of(context)!.neighborhoodChatOnMyWay;
    if (_roomId == null) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    geo.Position? pos;
    try {
      pos = await geo.Geolocator.getCurrentPosition(locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high)).timeout(const Duration(seconds: 6));
    } catch (_) {}

    try {
      await _messagesRef.add({
        'uid': uid,
        'avatar': _myAvatar,
        'displayName': _myName,
        if (_myPhotoUrl != null) 'photoURL': _myPhotoUrl,
        'text': '🚗 $onMyWayText',
        'type': 'omw',
        if (pos != null) 'lat': pos.latitude,
        if (pos != null) 'lng': pos.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } catch (e) {
      Logger.warning('NeighborhoodChat._sendOmw Firestore failed: $e', tag: 'NBR_CHAT');
    }
  }

  Future<void> _sendLocation() async {
    final markedLocationText =
        AppLocalizations.of(context)!.neighborhoodChatMarkedLocation;
    if (_roomId == null) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    geo.Position? pos;
    try {
      pos = await geo.Geolocator.getCurrentPosition(locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high)).timeout(const Duration(seconds: 6));
    } catch (_) {}

    if (pos == null) return;

    try {
      await _messagesRef.add({
        'uid': uid,
        'avatar': _myAvatar,
        'displayName': _myName,
        if (_myPhotoUrl != null) 'photoURL': _myPhotoUrl,
        'text': '📍 $markedLocationText',
        'type': 'location',
        'lat': pos.latitude,
        'lng': pos.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } catch (e) {
      Logger.warning('NeighborhoodChat._sendLocation Firestore failed: $e', tag: 'NBR_CHAT');
    }
  }

  void _showMessageOptions(String docId, String currentText) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit), title: Text(l10n.editMessage), onTap: () { Navigator.pop(ctx); _editMessage(docId, currentText); }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: Text(l10n.delete), onTap: () { Navigator.pop(ctx); _deleteMessage(docId); }),
          ],
        ),
      ),
    );
  }

  Future<void> _editMessage(String docId, String currentText) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentText);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade100,
        title: Text(l10n.editMessage, style: const TextStyle(color: Color(0xFF111111))),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Color(0xFF111111), fontSize: 16),
          cursorColor: const Color(0xFF7C3AED),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(l10n.save)),
        ],
      ),
    );
    if (result != null && result != currentText) {
      await _messagesRef.doc(docId).update({'text': result.trim(), 'edited': true});
    }
  }

  Future<void> _deleteMessage(String docId) async {
    await _messagesRef.doc(docId).delete();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l10n.neighborhoodChatTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          if (_roomId != null) ...[
            IconButton(icon: Icon(_isMuted ? Icons.notifications_off : Icons.notifications_active), onPressed: _toggleMute),
            IconButton(icon: const Icon(Icons.person_add_rounded, size: 20), tooltip: l10n.neighborhoodChatInviteNeighbors, onPressed: _shareInvite),
          ],
          IconButton(icon: const Icon(Icons.info_outline), onPressed: _showInfoSheet),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_locating) return _buildSkeleton();
    if (_locationError != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_rounded, size: 52, color: Colors.orange.shade700),
              const SizedBox(height: 16),
              Text(
                _locationError!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.4, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _messagesRef
                .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30))))
                .orderBy('createdAt', descending: false)
                .limitToLast(50)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                Logger.error(
                  'NeighborhoodChat messages stream: ${snap.error}',
                  error: snap.error,
                );
                return FirestoreStreamErrorCenter(
                  error: snap.error,
                  fallbackMessage: l10n.chatMessagesLoadFailed,
                  permissionDeniedMessage:
                      l10n.neighborhoodChatNoAccessOrRulesChanged,
                );
              }
              if (!snap.hasData) return _buildSkeleton();
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          l10n.neighborhoodChatNoRecentMessages,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.neighborhoodChatEmptyHint,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.35),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data();
                  final isMe = data['uid'] == _auth.currentUser?.uid;
                  return _MessageBubble(
                    docId: docs[i].id,
                    avatar: data['avatar'] ?? '🙂',
                    photoUrl: data['photoURL'] as String?,
                    displayName: data['displayName'] ?? 'Vecin',
                    text: data['text'] ?? '',
                    timestamp: (data['createdAt'] as Timestamp?)?.toDate(),
                    isMe: isMe,
                    isOmw: data['type'] == 'omw',
                    isLocation: data['type'] == 'location',
                    isVoice: data['type'] == 'voice',
                    onLocationTap: data['type'] == 'location' ? () => Navigator.pop(context, {'action': 'flyTo', 'lat': data['lat'], 'lng': data['lng']}) : null,
                    onPlayVoice: (data['type'] == 'voice' && data['voiceUrl'] != null) ? () => _walkieTalkieService.playAudio(data['voiceUrl'] as String) : null,
                    onLongPress: isMe ? () => _showMessageOptions(docs[i].id, data['text']) : null,
                    onAvatarTap: !isMe ? () => _startPrivateChat(data['uid'], data['displayName'] ?? 'Vecin') : null,
                  );
                },
              );
            },
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  /// IconButton mai îngust — reduce riscul de overflow pe ecrane înguste sau text mărit.
  static ButtonStyle _compactIconBtn() {
    return IconButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.all(6),
      minimumSize: const Size(40, 40),
    );
  }

  Widget _buildInputBar() {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    // Tastatură (viewInsets) + bară sistem / gesture (padding) — evită suprapunerea cu navigația Android.
    final bottomPad = mq.viewInsets.bottom + mq.padding.bottom;
    final compact = _compactIconBtn();
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(2, 6, 2, 6 + bottomPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              style: compact,
              tooltip: l10n.neighborhoodChatOnMyWay,
              icon: const Icon(Icons.directions_car_rounded, color: Colors.deepOrange, size: 22),
              onPressed: () {
                HapticFeedback.lightImpact();
                _sendOmw();
              },
            ),
            IconButton(
              style: compact,
              tooltip: l10n.neighborhoodChatSendLocationTooltip,
              icon: const Icon(Icons.location_on_rounded, color: Colors.blue, size: 22),
              onPressed: () {
                HapticFeedback.lightImpact();
                _sendLocation();
              },
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: l10n.writeMessage,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
              ),
            ),
            IconButton(
              style: compact,
              tooltip: l10n.send,
              icon: const Icon(Icons.send_rounded, color: Color(0xFF7C3AED), size: 22),
              onPressed: () {
                HapticFeedback.lightImpact();
                _sendMessage();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareInvite() async {
    final l10n = AppLocalizations.of(context)!;
    if (_roomId == null) return;
    await SharePlus.instance.share(
      ShareParams(
        text:
            l10n.neighborhoodChatInviteText(_roomId ?? ''),
      ),
    );
  }

  void _showInfoSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏡 ${l10n.neighborhoodChatTitle}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(l10n.neighborhoodChatInfoBody1, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.neighborhoodChatInfoBody2, textAlign: TextAlign.left),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.disclaimerUnderstood)),
          ],
        ),
      ),
    );
  }

  void _startPrivateChat(String otherUid, String otherName) {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return;
    
    final chatUids = [myUid, otherUid];
    chatUids.sort();
    final chatId = chatUids.join('_');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          rideId: chatId,
          otherUserId: otherUid,
          otherUserName: otherName,
          collectionName: 'private_chats',
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        itemCount: 10,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, i) {
          final isMe = i % 3 == 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMe) CircleAvatar(backgroundColor: Colors.grey.shade300, radius: 16),
                const SizedBox(width: 8),
                Container(
                  width: 140 + (i * 45.0) % 180,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 8),
                if (isMe) CircleAvatar(backgroundColor: Colors.grey.shade300, radius: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String docId;
  final String avatar;
  final String? photoUrl;
  final String displayName;
  final String text;
  final DateTime? timestamp;
  final bool isMe;
  final bool isOmw;
  final bool isLocation;
  final bool isVoice;
  final VoidCallback? onLongPress;
  final VoidCallback? onLocationTap;
  final VoidCallback? onPlayVoice;
  final VoidCallback? onAvatarTap;

  const _MessageBubble({
    required this.docId,
    required this.avatar,
    this.photoUrl,
    required this.displayName,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isOmw = false,
    this.isLocation = false,
    this.isVoice = false,
    this.onLongPress,
    this.onLocationTap,
    this.onPlayVoice,
    this.onAvatarTap,
  });

  Widget _leadingAvatar() {
    final url = photoUrl?.trim();
    if (url != null && url.startsWith('http')) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: CachedNetworkImageProvider(url),
      );
    }
    return Text(avatar, style: const TextStyle(fontSize: 24));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            GestureDetector(
              onTap: onAvatarTap,
              child: _leadingAvatar(),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              onTap: isLocation ? onLocationTap : isVoice ? onPlayVoice : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                decoration: BoxDecoration(
                  color: isOmw ? Colors.orange.shade50 : isLocation ? Colors.blue.shade50 : isMe ? const Color(0xFF7C3AED) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe) Text(displayName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                    if (isVoice) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_fill, color: isMe ? Colors.white : const Color(0xFF7C3AED), size: 24),
                          const SizedBox(width: 8),
                          Text(l10n.chatVoiceMessageLabel, style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 12, fontStyle: FontStyle.italic)),
                          if (timestamp != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 8, color: isMe ? Colors.white54 : Colors.black26),
                            ),
                          ],
                        ],
                      ),
                    ] else if (isLocation) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on, color: Colors.blue, size: 20),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Location on map',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              if (timestamp != null)
                                Text(
                                  '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 9, color: Colors.black26),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.neighborhoodChatFlyToHint,
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.touch_app, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                l10n.neighborhoodChatSeeOnMap,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blue.shade700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14)),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          timestamp != null 
                            ? '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}'
                            : '...',
                          style: TextStyle(
                            fontSize: 9,
                            color: isMe ? Colors.white.withValues(alpha: 0.6) : Colors.black38,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _leadingAvatar(),
          ],
        ],
      ),
    );
  }
}
