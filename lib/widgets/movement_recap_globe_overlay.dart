import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Vedere stilizată „Pământ din spațiu” pentru începutul/sfârșitul recap-ului Week in Review.
class MovementRecapGlobeOverlay extends StatelessWidget {
  /// Poziție normalizată pe disc (0–1), pentru un punct „pin” pe glob (opțional).
  final Offset? pinNormalized;
  final double opacity;

  const MovementRecapGlobeOverlay({
    super.key,
    this.pinNormalized,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: CustomPaint(
          painter: _GlobeSpacePainter(pinNormalized: pinNormalized),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _GlobeSpacePainter extends CustomPainter {
  _GlobeSpacePainter({this.pinNormalized});

  final Offset? pinNormalized;

  static const int _starSeed = 853604919;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()..shader = ui.Gradient.radial(
          rect.center,
          rect.longestSide * 0.55,
          [const Color(0xFF0A1628), const Color(0xFF02050A)],
        );
    canvas.drawRect(rect, bg);

    final rnd = math.Random(_starSeed);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (var i = 0; i < 140; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 1.2 + 0.2;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }

    final cx = size.width * 0.5;
    final cy = size.height * 0.42;
    final radius = math.min(size.width, size.height) * 0.28;

    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(Offset(cx, cy), radius * 1.08, glow);

    final ocean = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy - radius * 0.12),
        radius * 1.05,
        [
          const Color(0xFF4FC3F7),
          const Color(0xFF0288D1),
          const Color(0xFF01579B),
        ],
        [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(Offset(cx, cy), radius, ocean);

    final land = Paint()..color = const Color(0xFF8BC34A).withValues(alpha: 0.92);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius)));
    // Forme simplificate continent (stil Bump-like, abstract)
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - radius * 0.35, cy + radius * 0.05), width: radius * 0.9, height: radius * 0.55), land);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + radius * 0.42, cy - radius * 0.12), width: radius * 0.5, height: radius * 0.38), land);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + radius * 0.08, cy + radius * 0.35), width: radius * 0.35, height: radius * 0.28), land);
    canvas.restore();

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: 0.45);
    canvas.drawCircle(Offset(cx, cy), radius, rim);

    if (pinNormalized != null) {
      final px = cx - radius + pinNormalized!.dx * 2 * radius;
      final py = cy - radius + pinNormalized!.dy * 2 * radius;
      final d = math.sqrt(math.pow(px - cx, 2) + math.pow(py - cy, 2));
      if (d <= radius * 0.98) {
        final pinPaint = Paint()..color = const Color(0xFF2196F3);
        canvas.drawCircle(Offset(px, py), 7, pinPaint);
        canvas.drawCircle(
          Offset(px, py),
          9,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlobeSpacePainter oldDelegate) {
    return oldDelegate.pinNormalized != pinNormalized;
  }
}

/// Proiecție simplă equirectangular → poziție pe disc (pentru pin pe glob).
Offset? latLngToGlobePinNormalized(double lat, double lng) {
  final x = (lng + 180) / 360;
  final y = (90 - lat) / 180;
  return Offset(x.clamp(0.05, 0.95), y.clamp(0.05, 0.95));
}
