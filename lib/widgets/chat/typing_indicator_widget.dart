import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/services/firestore_service.dart';

/// Widget pentru indicatorul de typing (Uber-like)
class TypingIndicatorWidget extends StatelessWidget {
  final String rideId;
  final String? otherUserName;

  const TypingIndicatorWidget({
    super.key,
    required this.rideId,
    this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirestoreService().getTypingIndicator(rideId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final typingData = snapshot.data;
        if (typingData == null || typingData.isEmpty) {
          return const SizedBox.shrink();
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId == null) {
          return const SizedBox.shrink();
        }

        // Verifică dacă celălalt utilizator scrie
        bool isOtherUserTyping = false;

        typingData.forEach((userId, data) {
          if (userId != currentUserId) {
            final typingInfo = data as Map<String, dynamic>?;
            if (typingInfo != null && typingInfo['isTyping'] == true) {
              isOtherUserTyping = true;
            }
          }
        });

        if (!isOtherUserTyping) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8, left: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${otherUserName ?? "Utilizatorul"} scrie',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TypingDots(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_controller.value + delay) % 1.0;
            final opacity = (animationValue < 0.5)
                ? animationValue * 2
                : 2 - (animationValue * 2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withAlpha((255 * opacity).round()),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

