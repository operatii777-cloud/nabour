import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/models/chat_message_model.dart';
import 'package:nabour_app/widgets/chat/voice_message_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// Widget pentru bubble-uri de mesaje în stil WhatsApp
/// Include: tail (triunghi), read receipts, timestamp, edited indicator
class WhatsAppMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String? otherUserName;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final Function(String messageId, String text)? onTranslate;

  const WhatsAppMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.otherUserName,
    this.onLongPress,
    this.onReply,
    this.onTranslate,
  });

  Widget _buildSenderFace() {
    const size = 32.0;
    final url = message.senderPhotoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: size,
            height: size,
            color: Colors.grey.shade300,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => _buildSenderEmojiFallback(size),
        ),
      );
    }
    return _buildSenderEmojiFallback(size);
  }

  Widget _buildSenderEmojiFallback(double size) {
    final em = (message.senderAvatarEmoji != null &&
            message.senderAvatarEmoji!.trim().isNotEmpty)
        ? message.senderAvatarEmoji!.trim()
        : '🙂';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
          width: 1.5,
        ),
      ),
      child: Text(em, style: TextStyle(fontSize: size * 0.54)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _buildSenderFace(),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: onLongPress,
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
              margin: EdgeInsets.only(
                top: 4,
                bottom: message.reactions.isNotEmpty ? 0 : 4,
                left: isMe ? 44 : 0,
                right: isMe ? 0 : 8,
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: CustomPaint(
                painter: WhatsAppBubblePainter(
                  isMe: isMe,
                  color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
                ),
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 8, bottom: 6, left: 12, right: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.replyToText != null)
                        _buildReplyPreview(context),
                      if (message.type == MessageType.voice && message.voiceUrl != null)
                        VoiceMessagePlayer(
                          audioUrl: message.voiceUrl!,
                          duration: message.voiceDuration ?? 0,
                          isMe: isMe,
                        )
                      else if (message.type == MessageType.gif && message.gifUrl != null)
                        _buildGifMessage(message.gifUrl!)
                      else if (message.type == MessageType.image && message.imageUrl != null)
                        _buildImageMessage(message.imageUrl!)
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            if (message.translatedText != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha((255 * 0.1).round()),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.withAlpha((255 * 0.2).round()),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.auto_awesome, size: 14, color: Colors.blue),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        message.translatedText!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTimestamp(message.timestamp),
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _buildReadReceipt(context),
                          ],
                          if (message.isEdited) ...[
                            const SizedBox(width: 4),
                            const Text(
                              'Editat',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (!isMe && onTranslate != null && message.translatedText == null) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => onTranslate!(message.senderId, message.text),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'AI',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (message.reactions.isNotEmpty) _buildReactionsRow(context),
                  ],
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 6),
              _buildSenderFace(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: const Border(
          left: BorderSide(color: Color(0xFF25D366), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.replyToSenderId == message.senderId
                ? 'Tu'
                : (otherUserName ?? 'Celălalt'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF25D366),
            ),
          ),
          Text(
            message.replyToText ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsRow(BuildContext context) {
    final Map<String, int> counts = {};
    for (final emoji in message.reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 0 : 12,
        right: isMe ? 12 : 0,
        bottom: 4,
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: counts.entries.map((e) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2),
            ],
          ),
          child: Text(
            e.value > 1 ? '${e.key} ${e.value}' : e.key,
            style: const TextStyle(fontSize: 13),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildReadReceipt(BuildContext context) {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.grey.shade400;
        break;
      case MessageStatus.sent:
        icon = Icons.done;
        color = Colors.grey.shade600;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey.shade600;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = const Color(0xFF4FC3F7); // Albastru WhatsApp pentru citit
        break;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  Widget _buildGifMessage(String gifUrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = (constraints.maxWidth.isFinite
                ? constraints.maxWidth.clamp(120.0, 220.0)
                : 200.0)
            .toDouble();
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: gifUrl,
            fit: BoxFit.cover,
            width: side,
            height: side,
            placeholder: (context, url) => Container(
              width: side,
              height: side,
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: side,
              height: side,
              color: Colors.grey.shade200,
              child: const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageMessage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: 200,
        height: 200,
        placeholder: (context, url) => Container(
          width: 200,
          height: 200,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 200,
          color: Colors.grey.shade200,
          child: const Icon(Icons.error),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'acum';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(date);
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }
}

/// CustomPainter pentru bubble-uri WhatsApp cu tail (triunghi)
class WhatsAppBubblePainter extends CustomPainter {
  final bool isMe;
  final Color color;

  WhatsAppBubblePainter({
    required this.isMe,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const radius = 8.0;
    const tailSize = 8.0;

    if (isMe) {
      // Bubble pentru mesajele mele (dreapta) - tail în stânga jos
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius - tailSize);
      path.quadraticBezierTo(size.width, size.height - tailSize, size.width - radius, size.height - tailSize);
      
      // Tail (triunghi) în stânga jos
      path.lineTo(tailSize, size.height - tailSize);
      path.lineTo(0, size.height);
      path.lineTo(0, size.height - tailSize);
      
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
    } else {
      // Bubble pentru mesajele primite (stânga) - tail în dreapta jos
      path.moveTo(tailSize, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
      path.lineTo(radius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - radius);
      
      // Tail (triunghi) în dreapta jos
      path.lineTo(0, size.height - tailSize);
      path.lineTo(tailSize, size.height - tailSize);
      path.lineTo(tailSize, radius);
      path.quadraticBezierTo(tailSize, 0, tailSize + radius, 0);
    }

    path.close();

    // Shadow mai întâi (sub bubble), apoi fill-ul deasupra
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WhatsAppBubblePainter oldDelegate) {
    return oldDelegate.isMe != isMe || oldDelegate.color != color;
  }
}

