import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/models/chat_message_model.dart';
import 'package:intl/intl.dart';

/// Widget pentru bule de mesaje în chat (Uber-like)
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String? senderName;
  final String? senderAvatar;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderName,
    this.senderAvatar,
  });

  @override
  Widget build(BuildContext context) {
    // Mesaje de sistem
    if (message.type == MessageType.system) {
      return _buildSystemMessage(context);
    }

    // Mesaje cu locație
    if (message.type == MessageType.location && message.locationData != null) {
      return _buildLocationMessage(context);
    }

    // Mesaje text normale
    return _buildTextMessage(context);
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMessage(BuildContext context) {
    final lat = message.locationData!['latitude'] as double?;
    final lng = message.locationData!['longitude'] as double?;
    final address = message.locationData!['address'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && senderAvatar != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: senderAvatar!.startsWith('http')
                  ? NetworkImage(senderAvatar!)
                  : null,
              child: senderAvatar!.startsWith('http')
                  ? null
                  : Text(
                      senderName?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 12),
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: isMe
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address ?? 'Locație',
                          style: TextStyle(
                            color: isMe
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (lat != null && lng != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Coordonate: $lat, $lng',
                      style: TextStyle(
                        color: (isMe
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurfaceVariant)
                            .withAlpha((255 * 0.7).round()),
                        fontSize: 10,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  _buildMessageFooter(context),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildReadReceipt(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && senderAvatar != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: senderAvatar!.startsWith('http')
                  ? NetworkImage(senderAvatar!)
                  : null,
              child: senderAvatar!.startsWith('http')
                  ? null
                  : Text(
                      senderName?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 12),
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick reply indicator
                  if (message.quickReplyId != null) ...[
                    Icon(
                      Icons.reply,
                      size: 12,
                      color: (isMe
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant)
                          .withAlpha((255 * 0.7).round()),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildMessageFooter(context),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildReadReceipt(context),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTimestamp(message.timestamp),
          style: TextStyle(
            color: (isMe
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant)
                .withAlpha((255 * 0.6).round()),
            fontSize: 11,
          ),
        ),
        if (message.isEdited) ...[
          const SizedBox(width: 4),
          Text(
            'Editat',
            style: TextStyle(
              color: (isMe
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant)
                  .withAlpha((255 * 0.6).round()),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
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
        color = Colors.grey.shade400;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey.shade400;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Theme.of(context).colorScheme.primary;
        break;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
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
      return DateFormat('dd MMM HH:mm').format(date);
    }
  }
}

