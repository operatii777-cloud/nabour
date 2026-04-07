import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Short full-screen star fall animation (3s).
class MagicEventStarShowerOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const MagicEventStarShowerOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  State<MagicEventStarShowerOverlay> createState() =>
      _MagicEventStarShowerOverlayState();
}

class _MagicEventStarShowerOverlayState extends State<MagicEventStarShowerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward().whenComplete(() {
        if (mounted) widget.onComplete();
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(
            painter: _StarShowerPainter(progress: _c.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _StarShowerPainter extends CustomPainter {
  final double progress;

  _StarShowerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = size.height * 0.22;
    final rnd = math.Random(42);
    for (var i = 0; i < 18; i++) {
      final ox = (rnd.nextDouble() - 0.5) * size.width * 0.55;
      final delay = rnd.nextDouble() * 0.35;
      final t = ((progress - delay) / 0.65).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final y = top + t * (size.height * 0.42);
      final x = cx + ox * (1 - t * 0.15);
      final fade = (1 - t) * (1 - t);
      final paint = Paint()..color = Color.lerp(
        const Color(0xFFFFD54F),
        const Color(0xFFFFE082),
        rnd.nextDouble(),
      )!.withValues(alpha: 0.2 + 0.65 * fade);
      final s = 4.0 + rnd.nextDouble() * 6;
      _drawStar(canvas, Offset(x, y), s, paint);
    }
  }

  void _drawStar(Canvas c, Offset o, double r, Paint paint) {
    const n = 5;
    final inner = r * 0.42;
    final path = Path();
    for (var i = 0; i < n * 2; i++) {
      final rad = i.isEven ? r : inner;
      final a = (math.pi / 2) + i * math.pi / n;
      final x = o.dx + rad * math.cos(a);
      final y = o.dy + rad * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    c.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarShowerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
