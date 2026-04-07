import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Small circular pin with spark for Mapbox PointAnnotation image.
class MagicEventMarkerIcons {
  MagicEventMarkerIcons._();

  static Uint8List? _cache;

  static Future<Uint8List> pinPng() async {
    if (_cache != null) return _cache!;
    _cache = await _build();
    return _cache!;
  }

  static Future<Uint8List> _build() async {
    const double size = 80;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    final shadow = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(size / 2 + 1, size / 2 + 2), 28, shadow);

    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: const Offset(size / 2, size / 2), radius: 28));
    canvas.drawCircle(const Offset(size / 2, size / 2), 28, fill);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, size / 2), 28, border);

    final tp = TextPainter(
      text: const TextSpan(
        text: '\u2728',
        style: TextStyle(fontSize: 26),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2 - 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }
}
