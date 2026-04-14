import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nabour_app/models/chat_message_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/giphy_service.dart';
import 'package:nabour_app/services/push_notification_service.dart';
import 'package:nabour_app/services/translation_service.dart';
import 'package:nabour_app/services/voip_service.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/utils/firestore_error_ui.dart';
import 'package:nabour_app/widgets/chat/whatsapp_message_bubble.dart';
import 'package:nabour_app/widgets/chat/voice_record_button.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  final String otherUserId;
  final String otherUserName;
  /// Părinte document: `rides`, `private_chats` sau `ride_requests` (chat curse live).
  final String collectionName;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.otherUserId,
    required this.otherUserName,
    this.collectionName = 'rides',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  StreamSubscription? _typingSub;
  Timer? _typingTimer;


  bool _isTyping = false;
  bool _otherTyping = false;
  bool _showQuickReplies = true;
  String? _myUid;
  ChatMessage? _replyingTo;
  int _lastMessageCount = 0;
  bool _uploadingMedia = false;
  Timer? _markReadDebounce;
  /// Mesaje text trimise, afișate imediat până vine snapshot-ul Firestore.
  final List<ChatMessage> _pendingOutgoing = [];

  String? _myPhotoUrl;
  String? _otherPhotoUrl;
  String _myAvatarEmoji = '🙂';
  String _otherAvatarEmoji = '🙂';

  bool get _supportsRichAttachments =>
      widget.collectionName == 'ride_requests' ||
      widget.collectionName == 'private_chats';

  /// Subcoleție mesaje: `chat` pentru `ride_requests`, altfel `messages`.
  String get _messagesSubcollectionName =>
      widget.collectionName == 'ride_requests' ? 'chat' : 'messages';

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _db
          .collection(widget.collectionName)
          .doc(widget.rideId)
          .collection(_messagesSubcollectionName);

  DocumentReference<Map<String, dynamic>> get _chatMetaRef =>
      _db.collection(widget.collectionName).doc(widget.rideId).collection('_chat').doc('meta');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _myUid = _auth.currentUser?.uid;
    _subscribeTyping();
    unawaited(_markAllRead());
    unawaited(_loadChatParticipantProfiles());
  }

  static String? _profilePhotoFromUserData(Map<String, dynamic>? data) {
    if (data == null) return null;
    final raw = data['photoURL'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  static String _avatarEmojiFromUserData(Map<String, dynamic>? data) {
    final a = data?['avatar'];
    if (a is String && a.trim().isNotEmpty) return a.trim();
    return '🙂';
  }

  Future<void> _loadChatParticipantProfiles() async {
    final myId = _myUid;
    if (myId == null) return;
    final otherId = widget.otherUserId;
    try {
      final snaps = await Future.wait([
        _db.collection('users').doc(myId).get(),
        _db.collection('users').doc(otherId).get(),
      ]);
      if (!mounted) return;
      final myData = snaps[0].data();
      final otherData = snaps[1].data();
      setState(() {
        _myPhotoUrl = _profilePhotoFromUserData(myData) ??
            _auth.currentUser?.photoURL?.trim();
        _otherPhotoUrl = _profilePhotoFromUserData(otherData);
        _myAvatarEmoji = _avatarEmojiFromUserData(myData);
        _otherAvatarEmoji = _avatarEmojiFromUserData(otherData);
      });
    } catch (_) {}
  }

  ChatMessage _withSenderUiFields(ChatMessage m) {
    final my = _myUid;
    final hasPhoto =
        m.senderPhotoUrl != null && m.senderPhotoUrl!.trim().isNotEmpty;
    final hasEmoji = m.senderAvatarEmoji != null &&
        m.senderAvatarEmoji!.trim().isNotEmpty;
    String? photo = hasPhoto ? m.senderPhotoUrl!.trim() : null;
    String emoji = hasEmoji ? m.senderAvatarEmoji!.trim() : '🙂';

    if (my != null && m.senderId == my) {
      photo ??= _myPhotoUrl?.trim();
      if (!hasEmoji) emoji = _myAvatarEmoji;
    } else if (m.senderId == widget.otherUserId) {
      photo ??= _otherPhotoUrl?.trim();
      if (!hasEmoji) emoji = _otherAvatarEmoji;
    } else if (!hasEmoji) {
      emoji = '🙂';
    }

    final samePhoto = (photo ?? '') == (m.senderPhotoUrl?.trim() ?? '');
    final sameEmoji = emoji == (m.senderAvatarEmoji?.trim() ?? '');
    if (samePhoto && sameEmoji) return m;
    return m.copyWith(senderPhotoUrl: photo, senderAvatarEmoji: emoji);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingSub?.cancel();
    _typingTimer?.cancel();
    _markReadDebounce?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _setTyping(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_markAllRead());
  }

  // ── Firestore listeners ──────────────────────────────────────────────────

  // ── Firestore streams ───────────────────────────────────────────────────

  Stream<List<ChatMessage>> _getMessagesStream() {
    if (widget.collectionName == 'ride_requests') {
      return FirestoreService().getChatMessages(widget.rideId).map((snap) {
        final msgs = snap.docs
            .map((d) => ChatMessage.fromMap(d.data()))
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return msgs;
      });
    }
    return _messagesRef
        .orderBy('timestamp', descending: false)
        .limitToLast(60)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessage.fromMap(d.data()))
            .toList());
  }

  void _subscribeTyping() {
    if (widget.collectionName == 'ride_requests') {
      _typingSub = FirestoreService()
          .getTypingIndicator(widget.rideId)
          .listen((map) {
        if (!mounted) return;
        if (map == null || _myUid == null) {
          setState(() => _otherTyping = false);
          return;
        }
        var other = false;
        for (final e in map.entries) {
          if (e.key == _myUid) continue;
          final v = e.value;
          if (v is Map && v['isTyping'] == true) {
            other = true;
            break;
          }
        }
        final was = _otherTyping;
        if (other && !was) {
          HapticFeedback.lightImpact();
        }
        setState(() => _otherTyping = other);
      }, onError: (_) {});
      return;
    }
    _typingSub = _chatMetaRef.snapshots().listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      if (data == null) return;
      final typingUid = data['typingUid'] as String?;
      final other = typingUid != null &&
          typingUid != _myUid &&
          typingUid.isNotEmpty;
      final was = _otherTyping;
      if (other && !was) {
        HapticFeedback.lightImpact();
      }
      setState(() => _otherTyping = other);
    }, onError: (_) {});
  }

  /// Debounce: stream-ul se reemis des; evită batch-uri Firestore în serie la fiecare frame.
  void _scheduleMarkAllRead() {
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(milliseconds: 420), () {
      if (mounted) unawaited(_markAllRead());
    });
  }

  Future<void> _markAllRead() async {
    if (_myUid == null) return;
    final unread = await _messagesRef
        .where('senderId', isNotEqualTo: _myUid)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();
    final batch = _db.batch();
    final now = Timestamp.now();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'status': MessageStatus.read.name,
        'readAt': now,
      });
    }
    if (unread.docs.isNotEmpty) await batch.commit();
  }

  // ── Typing indicator ─────────────────────────────────────────────────────

  void _onTextChanged(String text) {
    setState(() => _showQuickReplies = text.isEmpty);
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _setTyping(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _isTyping = false;
      _setTyping(false);
    });
  }

  void _setTyping(bool typing) {
    if (widget.collectionName == 'ride_requests') {
      FirestoreService().setTypingIndicator(widget.rideId, typing);
      return;
    }
    _chatMetaRef.set(
      {'typingUid': typing ? (_myUid ?? '') : ''},
      SetOptions(merge: true),
    ).catchError((_) {});
  }

  void _notifyRecipientOutgoingChat(String messagePreview) {
    final l10n = AppLocalizations.of(context)!;
    final senderName = _auth.currentUser?.displayName ??
        _auth.currentUser?.email ??
        l10n.drawerDefaultUserName;
    unawaited(PushNotificationService.sendChatMessageNotification(
      recipientId: widget.otherUserId,
      senderName: senderName,
      messageText: messagePreview,
      rideId: widget.rideId,
      isPrivateChat: widget.collectionName == 'private_chats',
      senderUid: _myUid,
    ));
  }

  // ── Send message ─────────────────────────────────────────────────────────

  Future<void> _sendMessage(String text) async {
    final l10n = AppLocalizations.of(context)!;
    final trimmed = text.trim();
    if (trimmed.isEmpty || _myUid == null) return;
    final replyRef = _replyingTo;
    _textController.clear();
    _isTyping = false;
    _setTyping(false);
    final localId = const Uuid().v4();
    final msg = ChatMessage(
      senderId: _myUid!,
      text: trimmed,
      timestamp: Timestamp.now(),
      status: MessageStatus.sending,
      clientMessageId: localId,
      senderPhotoUrl: _myPhotoUrl,
      senderAvatarEmoji: _myAvatarEmoji,
      replyToText: replyRef == null
          ? null
          : (replyRef.type == MessageType.voice
              ? '🎤 ${l10n.chatVoiceMessageLabel}'
              : replyRef.type == MessageType.image
                  ? '📷 ${l10n.chatPhotoLabel}'
                  : replyRef.type == MessageType.gif
                      ? '🎬 ${l10n.chatGifLabel}'
                      : replyRef.text),
      replyToSenderId: replyRef?.senderId,
    );

    setState(() {
      _showQuickReplies = true;
      _replyingTo = null;
      _pendingOutgoing.add(msg);
    });
    _scrollToBottom();

    try {
      final ref = _messagesRef.doc();
      await ref.set({
        ...msg.toMap(),
        'status': MessageStatus.sent.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Push notification for recipient (fire-and-forget)
      _notifyRecipientOutgoingChat(trimmed);
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingOutgoing.removeWhere(
            (m) => m.clientMessageId == localId,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatMessageSendFailed)),
        );
      }
    }
  }

  bool _messageMatchesPending(ChatMessage server, ChatMessage pending) {
    final pid = pending.clientMessageId?.trim();
    final sid = server.clientMessageId?.trim();
    if (pid != null &&
        pid.isNotEmpty &&
        sid != null &&
        sid.isNotEmpty &&
        pid == sid) {
      return true;
    }
    if (server.senderId != pending.senderId ||
        server.text != pending.text ||
        server.type != pending.type) {
      return false;
    }
    if (server.replyToText != pending.replyToText) return false;
    return true;
  }

  List<ChatMessage> _messagesForUi(List<ChatMessage> server) {
    final stillPending = _pendingOutgoing
        .where(
          (p) => !server.any((s) => _messageMatchesPending(s, p)),
        )
        .toList();
    if (stillPending.length != _pendingOutgoing.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _pendingOutgoing
            ..clear()
            ..addAll(stillPending);
        });
      });
    }
    final merged = [...server, ...stillPending]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return merged.map(_withSenderUiFields).toList();
  }

  String? _chatMediaStoragePrefix() {
    if (widget.collectionName == 'ride_requests') {
      return 'ride_requests/${widget.rideId}/chat_media';
    }
    if (widget.collectionName == 'private_chats') {
      return 'private_chats/${widget.rideId}/chat_media';
    }
    return null;
  }

  Future<void> _showAttachmentOptions() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_rounded),
              title: Text(l10n.chatGalleryPhoto),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_pickAndSendImage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.gif_box_rounded),
              title: Text(l10n.chatGif),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_showGifPicker());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final l10n = AppLocalizations.of(context)!;
    final prefix = _chatMediaStoragePrefix();
    if (prefix == null || _myUid == null) return;
    final isPrivate = widget.collectionName == 'private_chats';
    // Galerie: image_picker comprimă JPEG pe dispozitiv (quality + max dimensiuni).
    // Chat privat: setări mai stricte ca să rămânem sub limita Storage (2MB) și să nu umplem bucket-ul.
    // GIF-urile din picker sunt doar URL-uri către CDN extern în Firestore — nu ocupă Storage-ul nostru.
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: isPrivate ? 72 : 85,
      maxWidth: isPrivate ? 1280 : 1600,
      maxHeight: isPrivate ? 1280 : null,
    );
    if (x == null) return;
    setState(() => _uploadingMedia = true);
    try {
      final bytes = await x.readAsBytes();
      final maxBytes = isPrivate ? (1800 * 1024) : (7 * 1024 * 1024);
      if (bytes.length > maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isPrivate
                  ? l10n.chatImageTooLargePrivate
                  : l10n.chatImageTooLargeGeneral),
            ),
          );
        }
        return;
      }
      final name = '${_myUid}_${const Uuid().v4()}.jpg';
      final ref = FirebaseStorage.instance.ref().child('$prefix/$name');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      await _sendImageMessage(url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatImageUploadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  Future<void> _sendImageMessage(String downloadUrl) async {
    final l10n = AppLocalizations.of(context)!;
    if (_myUid == null) return;
    final replyRef = _replyingTo;
    setState(() {
      _replyingTo = null;
      _showQuickReplies = true;
    });
    _scrollToBottom();
    final msg = ChatMessage(
      senderId: _myUid!,
      text: '📷 ${l10n.chatPhotoLabel}',
      timestamp: Timestamp.now(),
      type: MessageType.image,
      status: MessageStatus.sending,
      imageUrl: downloadUrl,
      senderPhotoUrl: _myPhotoUrl,
      senderAvatarEmoji: _myAvatarEmoji,
      replyToText: replyRef == null
          ? null
          : (replyRef.type == MessageType.voice
              ? '🎤 ${l10n.chatVoiceMessageLabel}'
              : replyRef.type == MessageType.image
                  ? '📷 ${l10n.chatPhotoLabel}'
                  : replyRef.type == MessageType.gif
                      ? '🎬 GIF'
                      : replyRef.text),
      replyToSenderId: replyRef?.senderId,
    );
    try {
      await _messagesRef.doc().set({
        ...msg.toMap(),
        'status': MessageStatus.sent.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _notifyRecipientOutgoingChat('📷 ${l10n.chatPhotoLabel}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatMessageSendFailed)),
        );
      }
    }
  }

  Future<void> _showGifPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        builder: (_, sc) => _GifPickerSheet(
          onPick: (url) {
            Navigator.pop(ctx);
            unawaited(_sendGifMessage(url));
          },
        ),
      ),
    );
  }

  /// [gifUrl] e URL către CDN extern; nu se încarcă fișierul în Firebase Storage — doar link în Firestore.
  Future<void> _sendGifMessage(String gifUrl) async {
    final l10n = AppLocalizations.of(context)!;
    if (_myUid == null) return;
    final replyRef = _replyingTo;
    setState(() {
      _replyingTo = null;
      _showQuickReplies = true;
    });
    _scrollToBottom();
    final msg = ChatMessage(
      senderId: _myUid!,
      text: '🎬 ${l10n.chatGifLabel}',
      timestamp: Timestamp.now(),
      type: MessageType.gif,
      status: MessageStatus.sending,
      gifUrl: gifUrl,
      senderPhotoUrl: _myPhotoUrl,
      senderAvatarEmoji: _myAvatarEmoji,
      replyToText: replyRef == null
          ? null
          : (replyRef.type == MessageType.voice
              ? '🎤 ${l10n.chatVoiceMessageLabel}'
              : replyRef.type == MessageType.image
                  ? '📷 ${l10n.chatPhotoLabel}'
                  : replyRef.type == MessageType.gif
                      ? '🎬 GIF'
                      : replyRef.text),
      replyToSenderId: replyRef?.senderId,
    );
    try {
      await _messagesRef.doc().set({
        ...msg.toMap(),
        'status': MessageStatus.sent.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _notifyRecipientOutgoingChat('🎬 ${l10n.chatGifLabel}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatMessageSendFailed)),
        );
      }
    }
  }

  // ── Phone call ───────────────────────────────────────────────────────────

  Future<void> _callOtherUser() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final doc = await _db.collection('users').doc(widget.otherUserId).get();
      final phone = doc.data()?['phoneNumber'] as String?;
      if (phone == null || phone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.chatPhoneNotAvailable)),
          );
        }
        return;
      }
      if (!mounted) return;
      await VoipService().startCall(
        phoneNumber: phone,
        contactName: widget.otherUserName,
        context: context,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatCallFailed)),
        );
      }
    }
  }

  // ── Reactions ────────────────────────────────────────────────────────────

  Future<void> _addReaction(ChatMessage msg, String emoji) async {
    if (_myUid == null) return;
    try {
      final snap = await _messagesRef
          .where('senderId', isEqualTo: msg.senderId)
          .where('timestamp', isEqualTo: msg.timestamp)
          .limit(1)
          .get();
      for (final doc in snap.docs) {
        final current = Map<String, String>.from(
          (doc.data()['reactions'] as Map?) ?? {},
        );
        if (current[_myUid] == emoji) {
          current.remove(_myUid);
        } else {
          current[_myUid!] = emoji;
        }
        await doc.reference.update({'reactions': current});
      }
    } catch (_) {}
  }

  // ── Translate ────────────────────────────────────────────────────────────

  Future<void> _translateMessage(String senderId, String text) async {
    try {
      final translated = await TranslationService().translate(text);
      if (translated.isEmpty || translated == text) return;
      final snap = await _messagesRef
          .where('senderId', isEqualTo: senderId)
          .where('text', isEqualTo: text)
          .limit(1)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.update({'translatedText': translated});
      }
    } catch (_) {}
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(max);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD),
      appBar: _buildAppBar(isDark),
      body: StreamBuilder<List<ChatMessage>>(
        stream: _getMessagesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            Logger.error(
              'ChatScreen messages stream',
              error: snapshot.error,
              tag: 'ChatScreen',
            );
            return Column(
              children: [
                Expanded(
                  child: FirestoreStreamErrorCenter(
                    error: snapshot.error,
                    fallbackMessage: l10n.chatMessagesLoadFailed,
                  ),
                ),
                if (_otherTyping) _buildTypingIndicator(isDark),
                if (_showQuickReplies && _messagesForUi(snapshot.data ?? []).isEmpty) _buildQuickReplies(),
                if (_replyingTo != null) _buildReplyBar(isDark),
                _buildInputBar(isDark),
              ],
            );
          }
          final msgs = _messagesForUi(snapshot.data ?? []);

          // Cât timp ești pe chat, mesajele primite de la celălalt trec la „read” pentru el (debounced).
          if (snapshot.hasData && (snapshot.data?.isNotEmpty ?? false)) {
            _scheduleMarkAllRead();
          }

          // Scroll la fund doar cand soseste un mesaj nou si userul e deja aproape de fund
          final newCount = msgs.length;
          if (newCount > _lastMessageCount) {
            _lastMessageCount = newCount;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (!_scrollController.hasClients) return;
              final pos = _scrollController.position;
              final nearBottom = pos.maxScrollExtent - pos.pixels < 120;
              if (nearBottom) _scrollToBottom();
            });
          }

          return Column(
            children: [
              Expanded(child: _buildMessageList(isDark, msgs)),
              if (_otherTyping) _buildTypingIndicator(isDark),
              if (_showQuickReplies && msgs.isEmpty) _buildQuickReplies(),
              if (_replyingTo != null) _buildReplyBar(isDark),
              _buildInputBar(isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOtherUserAppBarAvatar() {
    final url = _otherPhotoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.teal.shade200,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            placeholder: (_, __) => const SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Text(
              _otherAvatarEmoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.teal.shade200,
      child: Text(
        _otherAvatarEmoji,
        style: const TextStyle(fontSize: 22),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1F2C34) : const Color(0xFF075E54),
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: Row(
        children: [
          _buildOtherUserAppBarAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                if (_otherTyping)
                  Text(l10n.chatTyping,
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF25D366))),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: _callOtherUser,
          tooltip: l10n.call,
        ),
      ],
    );
  }

  Widget _buildMessageList(bool isDark, List<ChatMessage> messages) {
    final l10n = AppLocalizations.of(context)!;
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline,
                size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              l10n.chatEndToEndEncrypted,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final isMe = msg.senderId == _myUid;

        // Date separator
        final showDate = i == 0 ||
            !_sameDay(messages[i - 1].timestamp, msg.timestamp);

        return Column(
          key: ValueKey(msg.timestamp.toString() + msg.senderId),
          children: [
            if (showDate) _buildDateSeparator(msg.timestamp),
            GestureDetector(
              onLongPress: () => _showMessageOptions(context, msg, isMe),
              child: WhatsAppMessageBubble(
                message: msg,
                isMe: isMe,
                otherUserName: widget.otherUserName,
                onReply: () => setState(() {
                  _replyingTo = msg;
                  _focusNode.requestFocus();
                }),
                onTranslate: (senderId, text) => _translateMessage(senderId, text),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(Timestamp ts) {
    final l10n = AppLocalizations.of(context)!;
    final date = ts.toDate();
    final now = DateTime.now();
    String label;
    if (_sameDay(ts, Timestamp.fromDate(now))) {
      label = l10n.chatToday;
    } else if (_sameDay(
        ts, Timestamp.fromDate(now.subtract(const Duration(days: 1))))) {
      label = l10n.chatYesterday;
    } else {
      label =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 12, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2C34) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DotPulse(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    final l10n = AppLocalizations.of(context)!;
    final quickReplies = [
      l10n.chatQuickReplyHere,
      l10n.chatQuickReplyIn2Min,
      l10n.chatQuickReplyIn5Min,
      l10n.chatQuickReplyArrived,
      l10n.chatQuickReplyThanks,
      l10n.chatQuickReplyOk,
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => _sendMessage(quickReplies[i]),
            child: Chip(
              label: Text(quickReplies[i],
                  style: const TextStyle(fontSize: 13)),
              backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.15),
              side: const BorderSide(color: Color(0xFF25D366), width: 0.5),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  Widget _buildReplyBar(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final msg = _replyingTo!;
    final preview = msg.type == MessageType.voice
        ? '🎤 ${l10n.chatVoiceMessageLabel}'
        : msg.type == MessageType.image
            ? '📷 ${l10n.chatPhotoLabel}'
            : msg.type == MessageType.gif
                ? '🎬 GIF'
                : msg.text;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      color: isDark ? const Color(0xFF1F2C34) : Colors.grey.shade100,
      child: Row(
        children: [
          Container(width: 3, height: 36, color: const Color(0xFF25D366)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.senderId == _myUid ? l10n.you : widget.otherUserName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25D366),
                  ),
                ),
                Text(
                  preview,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyingTo = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_uploadingMedia)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2C34) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4)
                      ],
                    ),
                    child: Row(
                      children: [
                        if (_supportsRichAttachments)
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            color: isDark
                                ? Colors.tealAccent.shade100
                                : const Color(0xFF128C7E),
                            onPressed: _uploadingMedia
                                ? null
                                : _showAttachmentOptions,
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            onChanged: _onTextChanged,
                            onSubmitted: _sendMessage,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 4,
                            minLines: 1,
                            style: TextStyle(
                                color:
                                    isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: l10n.writeMessage,
                              hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (_, val, __) {
                    final hasText = val.text.trim().isNotEmpty;
                    if (hasText) {
                      return GestureDetector(
                        onTap: () => _sendMessage(_textController.text),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      );
                    }
                    // Chat individual: ascundem înregistrarea vocală din UI (funcția rămâne în cod).
                    if (widget.collectionName == 'private_chats') {
                      return const SizedBox.shrink();
                    }
                    return VoiceRecordButton(
                      rideId: widget.rideId,
                      onVoiceReady: (url, duration) async {
                        if (_myUid == null) return;
                        final msg = ChatMessage(
                          senderId: _myUid!,
                          text: '🎤 ${l10n.chatVoiceMessageLabel}',
                          timestamp: Timestamp.now(),
                          type: MessageType.voice,
                          status: MessageStatus.sending,
                          voiceUrl: url,
                          voiceDuration: duration,
                          senderPhotoUrl: _myPhotoUrl,
                          senderAvatarEmoji: _myAvatarEmoji,
                        );
                        _scrollToBottom();
                        try {
                          await _messagesRef.doc().set({
                            ...msg.toMap(),
                            'status': MessageStatus.sent.name,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          _notifyRecipientOutgoingChat('🎤 ${l10n.chatVoiceMessageLabel}');
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.chatVoiceMessageSendFailed),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(
      BuildContext context, ChatMessage msg, bool isMe) {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji reactions row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['❤️', '😂', '👍', '😮', '😢', '🙏'].map((emoji) =>
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _addReaction(msg, emoji);
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ).toList(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: Text(l10n.chatReply),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _replyingTo = msg);
                  _focusNode.requestFocus();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(l10n.chatCopy),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.text));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.chatMessageCopied)),
                  );
                },
              ),
              if (isMe) ...[
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: Color(0xFF7C3AED)),
                  title: Text(l10n.edit),
                  onTap: () {
                    Navigator.pop(ctx);
                    _editMessage(msg);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteMessage(msg);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editMessage(ChatMessage msg) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: msg.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editMessage),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty || result == msg.text) return;
    try {
      final snap = await _messagesRef
          .where('senderId', isEqualTo: msg.senderId)
          .where('timestamp', isEqualTo: msg.timestamp)
          .limit(1)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.update({'text': result, 'isEdited': true});
      }
    } catch (_) {}
  }

  Future<void> _deleteMessage(ChatMessage msg) async {
    try {
      final snap = await _messagesRef
          .where('senderId', isEqualTo: msg.senderId)
          .where('timestamp', isEqualTo: msg.timestamp)
          .limit(1)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
  }

  bool _sameDay(Timestamp a, Timestamp b) {
    final da = a.toDate();
    final db = b.toDate();
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }
}

// ── GIF picker (Giphy sau fallback) ───────────────────────────────────────

class _GifPickerSheet extends StatefulWidget {
  final void Function(String url) onPick;

  const _GifPickerSheet({required this.onPick});

  @override
  State<_GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<_GifPickerSheet> {
  final _q = TextEditingController(text: 'hello');
  List<GiphyGif> _gifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final list = await GiphyService.instance.search(_q.text);
    if (!mounted) return;
    setState(() {
      _gifs = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            l10n.chatChooseGif,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  decoration: InputDecoration(
                    hintText: l10n.chatSearchHint,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              IconButton(onPressed: _search, icon: const Icon(Icons.search)),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: _gifs.length,
                  itemBuilder: (context, i) {
                    final g = _gifs[i];
                    return GestureDetector(
                      onTap: () => widget.onPick(g.url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          g.previewUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Typing dots animation ─────────────────────────────────────────────────

class _DotPulse extends StatefulWidget {
  final Color color;
  const _DotPulse({required this.color});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final opacity = (0.3 + 0.7 * (1 - (offset - 0.5).abs() * 2)).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
