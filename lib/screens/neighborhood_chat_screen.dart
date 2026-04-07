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
import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/utils/content_filter.dart';
import 'package:nabour_app/services/nabour_functions.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nabour_app/services/walkie_talkie_service.dart';
import 'package:shimmer/shimmer.dart';

class NeighborhoodChatScreen extends StatefulWidget {
  /// Mesaj pre-completat în câmpul de text (de ex. trimis prin comandă vocală).
  final String? initialMessage;

  const NeighborhoodChatScreen({super.key, this.initialMessage});

  @override
  State<NeighborhoodChatScreen> createState() =>
      _NeighborhoodChatScreenState();
}

class _NeighborhoodChatScreenState extends State<NeighborhoodChatScreen> {
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
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  // Profilul userului curent (cached)
  String _myAvatar = '🙂';
  String _myName = 'Vecin';

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _textController.text = widget.initialMessage!;
    }
    _init();
  }

  @override
  void dispose() {
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
    setState(() => _isMuted = prefs.getBool('chat_muted_$_roomId') ?? false);
  }

  Future<void> _toggleMute() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMuted = !_isMuted;
      prefs.setBool('chat_muted_$_roomId', _isMuted);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMuted ? 'Chat silențios' : 'Sunet activat'),
        duration: const Duration(seconds: 1),
      ),
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
        });
      }
    } catch (_) {}
  }

  Future<void> _resolveRoom() async {
    try {
      final bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locating = false;
            _locationError = 'GPS dezactivat. Activează locația pentru chat.';
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
            _locationError = 'Permisiune GPS refuzată.';
          });
        }
        return;
      }

      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.reduced,
        ),
      ).timeout(const Duration(seconds: 8));

      String? roomId;
      try {
        final callable =
            NabourFunctions.instance.httpsCallable('nabourSyncNeighborhoodRoom');
        final res = await callable.call(<String, dynamic>{
          'lat': pos.latitude,
          'lng': pos.longitude,
        });
        final data = res.data as Map?;
        roomId = data?['roomId'] as String?;
        if (roomId == null || roomId.isEmpty) {
          if (mounted) {
            setState(() {
              _locating = false;
              _locationError =
                  'Chat cartier: răspuns invalid de la server (roomId H3).';
            });
          }
          return;
        }
        await _auth.currentUser?.getIdToken(true);
      } on FirebaseFunctionsException catch (e) {
        Logger.error('NeighborhoodChat: nabourSyncNeighborhoodRoom ${e.code} ${e.message}', error: e);
        if (mounted) {
          setState(() {
            _locating = false;
            _locationError = 'Chat cartier: Functions indisponibile (${e.code}).';
          });
        }
        return;
      } catch (e) {
        Logger.error('NeighborhoodChat: sync room claim failed: $e', error: e);
        if (mounted) {
          setState(() {
            _locating = false;
            _locationError = 'Nu s-a putut activa chat-ul.';
          });
        }
        return;
      }

      final resolvedRoom = roomId;
      await FirebaseMessaging.instance.subscribeToTopic('neighborhood_$resolvedRoom');
      if (mounted) {
        setState(() {
          _roomId = resolvedRoom;
          _locating = false;
        });
      }
    } catch (e) {
      Logger.error('NeighborhoodChat: location error: $e', error: e);
      if (mounted) setState(() { _locating = false; _locationError = 'Nu s-a putut determina locația.'; });
    }
  }

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _firestore.collection('neighborhood_chats').doc(_roomId!).collection('messages');

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _roomId == null) return;

    final filterResult = ContentFilter.check(text);
    if (!filterResult.isClean) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(filterResult.message ?? 'Inadecvat.')));
      return;
    }

    _textController.clear();
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _messagesRef.add({
        'uid': uid, 'avatar': _myAvatar, 'displayName': _myName, 'text': text, 'createdAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } catch (e) { Logger.error('NeighborhoodChat: send error: $e'); }
  }

  Future<void> _sendOmw() async {
    if (_roomId == null) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    geo.Position? pos;
    try {
      pos = await geo.Geolocator.getCurrentPosition(locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high)).timeout(const Duration(seconds: 6));
    } catch (_) {}

    try {
      await _messagesRef.add({
        'uid': uid, 'avatar': _myAvatar, 'displayName': _myName, 'text': '🚗 Sunt pe drum!', 'type': 'omw',
        if (pos != null) 'lat': pos.latitude, if (pos != null) 'lng': pos.longitude, 'createdAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _sendLocation() async {
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
        'uid': uid, 'avatar': _myAvatar, 'displayName': _myName, 'text': '📍 Am marcat o locație pe hartă', 'type': 'location',
        'lat': pos.latitude, 'lng': pos.longitude, 'createdAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _startRecording() async {
    setState(() { _isRecording = true; _recordingStartTime = DateTime.now(); });
    HapticFeedback.mediumImpact();
    await _walkieTalkieService.startRecording();
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecording) return;
    final duration = DateTime.now().difference(_recordingStartTime!);
    setState(() => _isRecording = false);
    
    if (duration.inMilliseconds < 500) return;

    final url = await _walkieTalkieService.stopRecordingAndUpload(_roomId!);
    if (url != null) {
      await _messagesRef.add({
        'uid': _auth.currentUser?.uid, 'avatar': _myAvatar, 'displayName': _myName, 'text': '🎤 Mesaj vocal instant',
        'type': 'voice', 'voiceUrl': url, 'createdAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    }
  }

  void _showMessageOptions(String docId, String currentText) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit), title: const Text('Editează'), onTap: () { Navigator.pop(ctx); _editMessage(docId, currentText); }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Șterge'), onTap: () { Navigator.pop(ctx); _deleteMessage(docId); }),
          ],
        ),
      ),
    );
  }

  Future<void> _editMessage(String docId, String currentText) async {
    final controller = TextEditingController(text: currentText);
    final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Editează'), content: TextField(controller: controller),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')), FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Salvează'))],
    ));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat cartier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          if (_roomId != null) ...[
            IconButton(icon: Icon(_isMuted ? Icons.notifications_off : Icons.notifications_active), onPressed: _toggleMute),
            IconButton(icon: const Icon(Icons.person_add_rounded, size: 20), tooltip: 'Invită vecini', onPressed: _shareInvite),
          ],
          IconButton(icon: const Icon(Icons.info_outline), onPressed: _showInfoSheet),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_locating) return _buildSkeleton();
    if (_locationError != null) return Center(child: Text(_locationError!));

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
              if (!snap.hasData) return _buildSkeleton();
              final docs = snap.data!.docs;
              return ListView.builder(
                controller: _scrollController,
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data();
                  final isMe = data['uid'] == _auth.currentUser?.uid;
                  return _MessageBubble(
                    docId: docs[i].id,
                    avatar: data['avatar'] ?? '🙂',
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

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.directions_car, color: Colors.orange),
            onPressed: () { HapticFeedback.lightImpact(); _sendOmw(); },
          ),
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.blue),
            onPressed: () { HapticFeedback.lightImpact(); _sendLocation(); },
          ),
          Expanded(child: TextField(controller: _textController, decoration: const InputDecoration(hintText: 'Scrie ceva...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12)))),
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopAndSendRecording(),
            child: CircleAvatar(
              backgroundColor: _isRecording ? Colors.red : Colors.blue.shade100,
              child: Icon(_isRecording ? Icons.settings_voice : Icons.mic, color: _isRecording ? Colors.white : Colors.blue),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF7C3AED)),
            onPressed: () { HapticFeedback.lightImpact(); _sendMessage(); },
          ),
        ],
      ),
    );
  }

  void _shareInvite() async {
    if (_roomId == null) return;
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Vino în chat-ul cartierului Nabour! Suntem vecini în zona H3: $_roomId',
      ),
    );
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏡 Chat de Cartier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Acesta este un spațiu efemer pentru vecinii din aceeași zonă H3 (aprox. 1km²).', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('• Mesajele dispar automat după 30 de minute.\n• Poți trimite locația sau un Walkie-Talkie (apasă lung pe microfon).\n• Respectă vecinii și păstrează comunitatea curată!', textAlign: TextAlign.left),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Am înțeles')),
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
    required this.docId, required this.avatar, required this.displayName, required this.text, required this.timestamp,
    required this.isMe, this.isOmw = false, this.isLocation = false, this.isVoice = false,
    this.onLongPress, this.onLocationTap, this.onPlayVoice, this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) 
            GestureDetector(
              onTap: onAvatarTap,
              child: Text(avatar, style: const TextStyle(fontSize: 24)),
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
                          Text('Mesaj vocal', style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 12, fontStyle: FontStyle.italic)),
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
                                  'Locație pe hartă',
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
                          const Text(
                            'Apasă pentru animația "FlyTo" către punctul marcat de vecin.',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.touch_app, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'VEZI PE HARTĂ',
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
            Text(avatar, style: const TextStyle(fontSize: 24)),
          ],
        ],
      ),
    );
  }
}
