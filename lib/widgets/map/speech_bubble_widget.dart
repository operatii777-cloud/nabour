import 'dart:async';
import 'package:flutter/material.dart';

/// Speech-bubble animat afișat deasupra unui avatar de pe hartă.
///
/// Suportă:
///   - Typing indicator (3 puncte animate) când [isTyping] = true
///   - Text mesaj cu fade-in / fade-out automat după [displayDuration]
///   - Coada bulei orientată în jos (spre avatar)
class MapSpeechBubble extends StatefulWidget {
  final String text;
  final bool isTyping;
  final String avatarEmoji;
  final String senderName;

  /// Cât timp rămâne vizibilă bula după ce mesajul apare (default 8s).
  final Duration displayDuration;

  /// Culoarea de fundal a bulei (default alb cu opacitate).
  final Color? bubbleColor;

  /// Callback apelat când bula dispare (fade-out complet).
  final VoidCallback? onDismissed;

  const MapSpeechBubble({
    super.key,
    this.text = '',
    this.isTyping = false,
    this.avatarEmoji = '🙂',
    this.senderName = '',
    this.displayDuration = const Duration(seconds: 8),
    this.bubbleColor,
    this.onDismissed,
  });

  @override
  State<MapSpeechBubble> createState() => _MapSpeechBubbleState();
}

class _MapSpeechBubbleState extends State<MapSpeechBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  Timer? _autoHideTimer;
  int _dotStep = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _startDotAnimation();
    if (!widget.isTyping && widget.text.isNotEmpty) {
      _scheduleAutoHide();
    }
  }

  @override
  void didUpdateWidget(MapSpeechBubble old) {
    super.didUpdateWidget(old);
    // Mesaj nou sau schimbare typing → reset animatie
    if (old.text != widget.text || old.isTyping != widget.isTyping) {
      _autoHideTimer?.cancel();
      _animCtrl.forward(from: 0);
      if (!widget.isTyping && widget.text.isNotEmpty) {
        _scheduleAutoHide();
      }
    }
  }

  void _startDotAnimation() {
    _dotTimer?.cancel();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted) return;
      setState(() => _dotStep = (_dotStep + 1) % 4);
    });
  }

  void _scheduleAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(widget.displayDuration, () {
      if (!mounted) return;
      _animCtrl.reverse().then((_) {
        widget.onDismissed?.call();
      });
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _autoHideTimer?.cancel();
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.bubbleColor ??
        (isDark
            ? Colors.grey.shade800.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.97));
    final textColor = isDark ? Colors.white : Colors.black87;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Bula principală ───────────────────────────────────────────────
          Container(
            constraints: const BoxConstraints(maxWidth: 180, minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: widget.isTyping
                ? _TypingDots(dotStep: _dotStep)
                : Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          // ── Coada bulei ───────────────────────────────────────────────────
          CustomPaint(
            size: const Size(14, 7),
            painter: _BubbleTailPainter(color: bg),
          ),
        ],
      ),
    );
  }
}

/// Punctele animate pentru „typing..."
class _TypingDots extends StatelessWidget {
  final int dotStep;
  const _TypingDots({required this.dotStep});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final active = i < dotStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? (isDark ? Colors.white70 : Colors.black54)
                : (isDark ? Colors.white24 : Colors.black12),
          ),
        );
      }),
    );
  }
}

/// Pictează coada triunghiulară a bulei (orientată în jos).
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  const _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Wrapper poziționabil pe hartă (folosit în Stack-ul MapScreen)
// ─────────────────────────────────────────────────────────────────────────────

/// Un [MapSpeechBubble] poziționat absolut în Stack-ul hartii.
/// [screenOffset] = centrul orizontal al avatarului în coordonate ecran.
/// Bula apare deasupra avatarului (offset vertical negativ).
class PositionedSpeechBubble extends StatelessWidget {
  final Offset screenOffset;
  final String text;
  final bool isTyping;
  final String avatarEmoji;
  final String senderName;
  final Duration displayDuration;
  final VoidCallback? onDismissed;

  /// Înălțimea aproximativă a avatarului (px) — offset vertical al bulei.
  final double avatarHeightPx;

  const PositionedSpeechBubble({
    super.key,
    required this.screenOffset,
    required this.text,
    this.isTyping = false,
    this.avatarEmoji = '🙂',
    this.senderName = '',
    this.displayDuration = const Duration(seconds: 8),
    this.onDismissed,
    this.avatarHeightPx = 56,
  });

  @override
  Widget build(BuildContext context) {
    // Bula are maxWidth 180px — o centrăm orizontal față de avatarul marker.
    const double bubbleMaxW = 180;
    const double estimatedBubbleH = 72; // bula + coada

    final left = screenOffset.dx - bubbleMaxW / 2;
    final top = screenOffset.dy - avatarHeightPx - estimatedBubbleH;

    return Positioned(
      left: left.clamp(4.0, double.infinity),
      top: top.clamp(4.0, double.infinity),
      width: bubbleMaxW,
      child: MapSpeechBubble(
        text: text,
        isTyping: isTyping,
        avatarEmoji: avatarEmoji,
        senderName: senderName,
        displayDuration: displayDuration,
        onDismissed: onDismissed,
      ),
    );
  }
}
