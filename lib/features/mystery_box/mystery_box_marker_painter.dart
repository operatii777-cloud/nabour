import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:typed_data';

class MysteryBoxMarkerPainter {
  /// Generates a PNG of a stylized Mystery Box for Mapbox markers.
  static Future<Uint8List> generateBoxIcon() async {
    const int size = 144;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
    
    final paint = Paint()..isAntiAlias = true;
    
    // 1. Shadow
    paint.color = Colors.black.withValues(alpha: 0.3);
    canvas.drawOval(Rect.fromLTWH(24, 108, 96, 24), paint);

    // 2. Main Box Body (Purple Gradient)
    final boxRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 24, 96, 96),
      const Radius.circular(14),
    );
    
    final gradient = ui.Gradient.linear(
      const Offset(72, 24),
      const Offset(72, 120),
      [const Color(0xFF7C3AED), const Color(0xFF4C1D95)],
    );
    paint.shader = gradient;
    canvas.drawRRect(boxRect, paint);
    paint.shader = null;

    // 3. Gold Ribbon / Band
    paint.color = const Color(0xFFFFD700); // Gold
    canvas.drawRect(const Rect.fromLTWH(60, 24, 24, 96), paint);
    canvas.drawRect(const Rect.fromLTWH(24, 60, 96, 24), paint);

    // 4. Ribbon Bow (Simple circle/symbol in the middle)
    paint.color = const Color(0xFFEAB308); // Darker Gold
    canvas.drawCircle(const Offset(72, 72), 14, paint);
    
    // 5. Question Mark (?) in the center
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(72 - textPainter.width/2, 72 - textPainter.height/2));

    // 6. Highlight/Glow
    paint.color = Colors.white.withValues(alpha: 0.2);
    canvas.drawCircle(const Offset(48, 48), 18, paint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Icon similar, gradient verde-teal pentru cutiile plasate de utilizatori.
  static Future<Uint8List> generateCommunityBoxIcon() async {
    const int size = 144;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );
    final paint = Paint()..isAntiAlias = true;
    paint.color = Colors.black.withValues(alpha: 0.3);
    canvas.drawOval(Rect.fromLTWH(24, 108, 96, 24), paint);
    final boxRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 24, 96, 96),
      const Radius.circular(14),
    );
    final gradient = ui.Gradient.linear(
      const Offset(72, 24),
      const Offset(72, 120),
      [const Color(0xFF059669), const Color(0xFF0F766E)],
    );
    paint.shader = gradient;
    canvas.drawRRect(boxRect, paint);
    paint.shader = null;
    paint.color = const Color(0xFF99F6E4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 36, 72, 72),
        const Radius.circular(10),
      ),
      paint,
    );
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '★',
        style: TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(72 - textPainter.width / 2, 72 - textPainter.height / 2),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
