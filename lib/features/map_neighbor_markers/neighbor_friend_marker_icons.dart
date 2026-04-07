import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:nabour_app/utils/logger.dart';

/// Bitmap-uri pentru markerele emoji ale vecinilor (inclusiv badge-uri tip Bump: baterie, viteză).
class NeighborFriendMarkerIcons {
  NeighborFriendMarkerIcons._();

  static final Map<String, Uint8List> _cache = {};

  static final Uint8List _kMinimalPngBytes = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    ),
  );

  static Uint8List _pngBytesOrMinimal(ByteData? data, String context) {
    if (data != null) return data.buffer.asUint8List();
    Logger.warning(
      '$context: Image.toByteData returned null; using minimal PNG',
      tag: 'MAP',
    );
    return _kMinimalPngBytes;
  }

  static int? _speedKmhBucket(double? speedMps) {
    if (speedMps == null || speedMps < 1.39) return null;
    return (speedMps * 3.6).round();
  }

  static int? _batteryBucket(int? level) {
    if (level == null) return null;
    return (level / 5).round() * 5;
  }

  /// Minute staționare (cuantificate) pentru cache sau null.
  static int? _stationaryBucket(int? stationarySinceMs, double? speedMps) {
    if (stationarySinceMs == null) return null;
    if (speedMps != null && speedMps >= 1.2) return null;
    final mins = DateTime.now()
        .difference(
          DateTime.fromMillisecondsSinceEpoch(stationarySinceMs),
        )
        .inMinutes;
    if (mins < 15) return null;
    return (mins ~/ 5) * 5;
  }

  static String? _placeEmoji(String? placeKind) {
    switch (placeKind) {
      case 'home':
        return '🏠';
      case 'work':
        return '💼';
      case 'school':
        return '🎓';
      default:
        return null;
    }
  }

  /// Marker circular cu emoji + opțional baterie / încărcare / viteză (stil apropiat de Bump).
  static Future<Uint8List> buildEmojiMarker({
    required String emoji,
    String? status,
    bool isOnline = false,
    double? speedMps,
    int? batteryLevel,
    bool isCharging = false,
    String? placeKind,
    int? stationarySinceMs,
  }) async {
    final kmh = _speedKmhBucket(speedMps);
    final batB = _batteryBucket(batteryLevel);
    final stB = _stationaryBucket(stationarySinceMs, speedMps);
    final cacheKey =
        '$emoji|${status ?? ''}|$isOnline|${batB ?? 'n'}|$isCharging|${kmh ?? 'n'}|${placeKind ?? 'n'}|${stB ?? 'n'}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    const double size = 80;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));

    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x30000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2 + 2),
      size / 2 - 4,
      shadowPaint,
    );

    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2),
      size / 2 - 4,
      bgPaint,
    );

    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF7C3AED)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2),
      size / 2 - 4,
      borderPaint,
    );

    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: 42,
      textAlign: ui.TextAlign.center,
    ))
      ..addText(emoji);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: size));
    final textY = (size - paragraph.height) / 2;
    canvas.drawParagraph(paragraph, ui.Offset(0, textY));

    if (batB != null) {
      final fill = batB >= 40
          ? const ui.Color(0xFF22C55E)
          : (batB >= 15
              ? const ui.Color(0xFFF59E0B)
              : const ui.Color(0xFFEF4444));
      const chipW = 42.0;
      const chipH = 18.0;
      final cx = size - chipW / 2 - 2;
      const cy = 4.0 + chipH / 2;
      final chip = ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
          center: ui.Offset(cx, cy),
          width: chipW,
          height: chipH,
        ),
        const ui.Radius.circular(9),
      );
      final chipBg = ui.Paint()..color = fill;
      canvas.drawRRect(chip, chipBg);

      final label = isCharging ? '⚡$batB%' : '$batB%';
      final chipText = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: 10,
        fontWeight: ui.FontWeight.w700,
        textAlign: ui.TextAlign.center,
      ))
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFFFFFFF)))
        ..addText(label);
      final chipPara = chipText.build();
      chipPara.layout(const ui.ParagraphConstraints(width: chipW + 4));
      canvas.drawParagraph(chipPara, ui.Offset(cx - chipW / 2 - 2, 1));
    }

    final placeEm = _placeEmoji(placeKind);
    if (placeEm != null) {
      final placeBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: status == 'driving' ? 11 : 14,
        textAlign: ui.TextAlign.center,
      ))
        ..addText(placeEm);
      final pp = placeBuilder.build();
      pp.layout(const ui.ParagraphConstraints(width: 28));
      final py = status == 'driving' ? 22.0 : 6.0;
      canvas.drawParagraph(pp, ui.Offset(size - 26, py));
    }

    double speedBottomY = size - 18;
    if (stB != null) {
      final h = stB ~/ 60;
      final m = stB % 60;
      final label = h == 0
          ? '${stB}m'
          : (m == 0 ? '${h}h' : '${h}h ${m}m');
      final stText = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: 9,
        fontWeight: ui.FontWeight.w600,
        textAlign: ui.TextAlign.center,
      ))
        ..addText('⏱ $label');
      final stp = stText.build();
      stp.layout(const ui.ParagraphConstraints(width: 56));
      final stY = kmh != null ? size - 32 : size - 28;
      canvas.drawParagraph(stp, ui.Offset((size - 52) / 2, stY));
      if (kmh != null) speedBottomY = size - 14;
    }

    if (kmh != null) {
      final speedText = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: 10,
        fontWeight: ui.FontWeight.w600,
        textAlign: ui.TextAlign.center,
      ))
        ..addText('$kmh km/h');
      final sp = speedText.build();
      sp.layout(const ui.ParagraphConstraints(width: 56));
      canvas.drawParagraph(sp, ui.Offset(4, speedBottomY));
    }

    if (isOnline) {
      final onlinePaint = ui.Paint()..color = const ui.Color(0xFF22C55E);
      canvas.drawCircle(const ui.Offset(size - 18, size - 18), 8, onlinePaint);
      final onlineStroke = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(const ui.Offset(size - 18, size - 18), 8, onlineStroke);
    }

    if (status == 'driving') {
      final carPaint = ui.Paint()..color = const ui.Color(0xFF7C3AED);
      canvas.drawCircle(const ui.Offset(size - 14, 14), 10, carPaint);
      const carEmoji = '🚗';
      final carBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: 10,
        textAlign: ui.TextAlign.center,
      ))
        ..addText(carEmoji);
      final carPara = carBuilder.build();
      carPara.layout(const ui.ParagraphConstraints(width: 20));
      canvas.drawParagraph(carPara, ui.Offset(size - 24, 8));
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = _pngBytesOrMinimal(byteData, 'NeighborFriendMarkerIcons.buildEmojiMarker');
    _cache[cacheKey] = bytes;
    return bytes;
  }

  /// Marker circular cu poza de profil descărcată din rețea.
  /// Fallback pe emoji '👤' dacă descărcarea eșuează.
  static Future<Uint8List> buildPhotoMarker({
    required String photoURL,
    bool isOnline = false,
    int? batteryLevel,
    bool isCharging = false,
  }) async {
    final batB = _batteryBucket(batteryLevel);
    final cacheKey =
        'photo|$photoURL|$isOnline|${batB ?? 'n'}|$isCharging';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    const double size = 96;

    ui.Image? networkImage;
    try {
      final provider = NetworkImage(photoURL);
      final completer = Completer<ImageInfo>();
      final stream = provider.resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          completer.complete(info);
          stream.removeListener(listener);
        },
        onError: (e, _) {
          completer.completeError(e);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      final info = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Photo download timeout'),
      );
      networkImage = info.image;
    } catch (e) {
      Logger.warning('buildPhotoMarker: failed to load $photoURL: $e', tag: 'MAP');
      return buildEmojiMarker(
        emoji: '👤',
        isOnline: isOnline,
        batteryLevel: batteryLevel,
        isCharging: isCharging,
      );
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
    const double radius = size / 2 - 4;

    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x30000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2 + 2), radius, shadowPaint,
    );

    canvas.save();
    final clipPath = ui.Path()
      ..addOval(ui.Rect.fromCircle(
        center: const ui.Offset(size / 2, size / 2),
        radius: radius,
      ));
    canvas.clipPath(clipPath);

    final src = ui.Rect.fromLTWH(
      0, 0,
      networkImage.width.toDouble(),
      networkImage.height.toDouble(),
    );
    final dst = ui.Rect.fromCircle(
      center: const ui.Offset(size / 2, size / 2),
      radius: radius,
    );
    canvas.drawImageRect(networkImage, src, dst, ui.Paint());
    canvas.restore();

    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF7C3AED)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2), radius, borderPaint,
    );

    if (batB != null) {
      final fill = batB >= 40
          ? const ui.Color(0xFF22C55E)
          : (batB >= 15
              ? const ui.Color(0xFFF59E0B)
              : const ui.Color(0xFFEF4444));
      const chipW = 42.0;
      const chipH = 18.0;
      final cx = size - chipW / 2 - 2;
      const cy = 4.0 + chipH / 2;
      final chip = ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
          center: ui.Offset(cx, cy),
          width: chipW,
          height: chipH,
        ),
        const ui.Radius.circular(9),
      );
      canvas.drawRRect(chip, ui.Paint()..color = fill);

      final label = isCharging ? '⚡$batB%' : '$batB%';
      final chipText = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: 10,
        fontWeight: ui.FontWeight.w700,
        textAlign: ui.TextAlign.center,
      ))
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFFFFFFF)))
        ..addText(label);
      final chipPara = chipText.build();
      chipPara.layout(const ui.ParagraphConstraints(width: chipW + 4));
      canvas.drawParagraph(chipPara, ui.Offset(cx - chipW / 2 - 2, 1));
    }

    if (isOnline) {
      final onlinePaint = ui.Paint()..color = const ui.Color(0xFF22C55E);
      canvas.drawCircle(const ui.Offset(size - 18, size - 18), 10, onlinePaint);
      final onlineStroke = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(const ui.Offset(size - 18, size - 18), 10, onlineStroke);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = _pngBytesOrMinimal(byteData, 'NeighborFriendMarkerIcons.buildPhotoMarker');
    _cache[cacheKey] = bytes;
    return bytes;
  }
}
