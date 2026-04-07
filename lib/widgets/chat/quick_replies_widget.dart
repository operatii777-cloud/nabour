import 'package:flutter/material.dart';
import 'package:nabour_app/models/quick_reply_model.dart';
import 'package:nabour_app/services/firestore_service.dart';

/// Widget pentru mesaje rapide (quick replies) - Uber-like
class QuickRepliesWidget extends StatelessWidget {
  final String rideId;
  final bool isDriver;
  final VoidCallback? onQuickReplySent;

  const QuickRepliesWidget({
    super.key,
    required this.rideId,
    required this.isDriver,
    this.onQuickReplySent,
  });

  @override
  Widget build(BuildContext context) {
    final replies = isDriver
        ? DriverQuickReplies.replies
        : PassengerQuickReplies.replies;

    if (replies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: replies.length,
        itemBuilder: (context, index) {
          final reply = replies[index];
          return _QuickReplyButton(
            reply: reply,
            rideId: rideId,
            onSent: () => onQuickReplySent?.call(),
          );
        },
      ),
    );
  }
}

class _QuickReplyButton extends StatelessWidget {
  final QuickReply reply;
  final String rideId;
  final VoidCallback? onSent;

  const _QuickReplyButton({
    required this.reply,
    required this.rideId,
    this.onSent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: () => _sendQuickReply(context),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.5).round()),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reply.icon != null) ...[
              Text(
                reply.icon!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                reply.text,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendQuickReply(BuildContext context) async {
    try {
      final firestoreService = FirestoreService();
      await firestoreService.sendChatMessage(
        rideId,
        reply.text,
        quickReplyId: reply.id,
      );
      
      onSent?.call();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj trimis: ${reply.text}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la trimiterea mesajului: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

