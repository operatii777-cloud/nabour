import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nabour_app/models/map_chat_message.dart';
import 'package:nabour_app/services/map_chat_service.dart';

/// Mini-monitor de chat drag-abil, afișat ca overlay în colțul hartii.
///
/// Afișează:
///   - Ultimele [maxVisible] mesaje din chat-ul activ
///   - Typing indicator pentru peer
///   - Input de trimitere mesaj
///
/// Poate fi:
///   - Minimizat (doar un buton pulsant)
///   - Expandat (panel complet)
///   - Închis complet
class MapChatMonitor extends StatefulWidget {
  final String chatId;
  final String myUid;
  final String peerUid;
  final String peerName;
  final String peerAvatarEmoji;
  final String myName;
  final String myAvatarEmoji;

  /// Callback apelat când userul închide monitorul.
  final VoidCallback onClose;

  /// Callback apelat la trimitere mesaj (pentru a declanșa bula pe hartă).
  final void Function(MapChatMessage msg)? onMessageSent;

  const MapChatMonitor({
    super.key,
    required this.chatId,
    required this.myUid,
    required this.peerUid,
    required this.peerName,
    required this.peerAvatarEmoji,
    required this.myName,
    required this.myAvatarEmoji,
    required this.onClose,
    this.onMessageSent,
  });

  @override
  State<MapChatMonitor> createState() => _MapChatMonitorState();
}

class _MapChatMonitorState extends State<MapChatMonitor>
    with SingleTickerProviderStateMixin {
  static const int _maxVisible = 6;
  static const double _monitorW = 280;
  static const double _monitorHExpanded = 340;

  bool _minimized = false;
  bool _peerTyping = false;
  Offset _position = const Offset(12, 120);

  List<MapChatMessage> _messages = [];
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  StreamSubscription<List<MapChatMessage>>? _msgSub;
  StreamSubscription<bool>? _typingSub;
  Timer? _typingDebounce;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  bool _hasNewMsg = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _subscribeMessages();
    _subscribeTyping();
    MapChatService.instance.cleanupExpired(widget.chatId);
  }

  void _subscribeMessages() {
    _msgSub?.cancel();
    _msgSub = MapChatService.instance
        .messagesStream(widget.chatId)
        .listen((msgs) {
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        if (_minimized && msgs.isNotEmpty) _hasNewMsg = true;
      });
      _scrollToBottom();
    });
  }

  void _subscribeTyping() {
    _typingSub?.cancel();
    _typingSub = MapChatService.instance
        .typingStream(chatId: widget.chatId, userId: widget.peerUid)
        .listen((typing) {
      if (!mounted) return;
      setState(() => _peerTyping = typing);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTextChanged(String val) {
    // Typing indicator: debounce 1s
    _typingDebounce?.cancel();
    if (val.isNotEmpty) {
      MapChatService.instance.setTyping(
          chatId: widget.chatId, isTyping: true);
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        MapChatService.instance.setTyping(
            chatId: widget.chatId, isTyping: false);
      });
    } else {
      MapChatService.instance.setTyping(
          chatId: widget.chatId, isTyping: false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    _typingDebounce?.cancel();
    await MapChatService.instance.setTyping(
        chatId: widget.chatId, isTyping: false);
    await MapChatService.instance.sendMessage(
      peerUid: widget.peerUid,
      text: text,
      senderName: widget.myName,
      senderAvatarEmoji: widget.myAvatarEmoji,
    );
    // Notificare externă (bula pe hartă)
    if (widget.onMessageSent != null) {
      final msg = MapChatMessage(
        id: '',
        chatId: widget.chatId,
        senderId: widget.myUid,
        senderName: widget.myName,
        senderAvatarEmoji: widget.myAvatarEmoji,
        text: text,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      widget.onMessageSent!(msg);
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _typingDebounce?.cancel();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (d) {
          if (!mounted) return;
          setState(() {
            _position = Offset(
              (_position.dx + d.delta.dx).clamp(0, MediaQuery.sizeOf(context).width - _monitorW),
              (_position.dy + d.delta.dy).clamp(0, MediaQuery.sizeOf(context).height - 80),
            );
          });
        },
        child: _minimized ? _buildMinimized() : _buildExpanded(),
      ),
    );
  }

  Widget _buildMinimized() {
    return ScaleTransition(
      scale: _pulseAnim,
      child: GestureDetector(
        onTap: () => setState(() {
          _minimized = false;
          _hasNewMsg = false;
        }),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _hasNewMsg
                ? const Color(0xFF6366F1)
                : Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                widget.peerAvatarEmoji,
                style: const TextStyle(fontSize: 24),
              ),
              if (_hasNewMsg)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Colors.grey.shade900.withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.97);
    final borderColor = isDark
        ? Colors.white12
        : Colors.black12;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: _monitorW,
        height: _monitorHExpanded,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(child: _buildMessageList(isDark)),
            if (_peerTyping) _buildTypingRow(isDark),
            _buildInputRow(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Text(widget.peerAvatarEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.peerName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Minimize
          GestureDetector(
            onTap: () => setState(() => _minimized = true),
            child: const Icon(Icons.remove, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 8),
          // Close
          GestureDetector(
            onTap: widget.onClose,
            child: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    final visible = _messages.length > _maxVisible
        ? _messages.sublist(_messages.length - _maxVisible)
        : _messages;

    if (visible.isEmpty) {
      return Center(
        child: Text(
          '👋 Trimite primul mesaj!',
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 12,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      itemCount: visible.length,
      itemBuilder: (ctx, i) {
        final msg = visible[i];
        final isMe = msg.senderId == widget.myUid;
        return _MessageBubble(msg: msg, isMe: isMe, isDark: isDark);
      },
    );
  }

  Widget _buildTypingRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Text(widget.peerAvatarEmoji,
              style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            '${widget.peerName} scrie...',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              onChanged: _onTextChanged,
              onSubmitted: (_) => _sendMessage(),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Scrie un mesaj...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bula mesaj individual în monitor ─────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MapChatMessage msg;
  final bool isMe;
  final bool isDark;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgMe = const Color(0xFF6366F1);
    final bgPeer = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07);
    final textMe = Colors.white;
    final textPeer = isDark ? Colors.white : Colors.black87;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: isMe ? bgMe : bgPeer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(msg.senderAvatarEmoji,
                      style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(
                    msg.senderName,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 12,
                color: isMe ? textMe : textPeer,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
