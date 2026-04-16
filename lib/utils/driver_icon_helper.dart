import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_model.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Shared marker icon generator for map previews (căutare cursă, șoferi în apropiere, pickup).
class DriverIconHelper {
  static const String _assetPath = 'assets/images/driver_icon.png';

  // Cache
  static Uint8List? _cachedDriverBytes;
  static Uint8List? _cachedPassengerBytes;
  static final Map<String, Uint8List> _garageDriverMarkerPngByAvatarId = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Marker PNG pentru un șofer pe baza profilului Firestore (slot garaj „la volan”).
  /// Aliniat vizual cu randarea din `MapScreen` (pătrat 120px, verificare opacitate).
  static Future<Uint8List> getDriverMarkerBytesForUserProfile(
    Map<String, dynamic>? profile,
  ) async {
    final raw = CarAvatarService.resolveSlotId(profile, CarAvatarMapSlot.driver);
    final id = CarAvatarService.coerceDriverAvatarIdForMap(raw);
    final av = CarAvatarService().getAvatarById(id);
    if (av.isDefault) {
      return getDriverIconBytes();
    }
    final hit = _garageDriverMarkerPngByAvatarId[id];
    if (hit != null) return hit;

    try {
      final bytes = await _renderGarageMapMarkerPng(av.assetPath);
      _garageDriverMarkerPngByAvatarId[id] = bytes;
      return bytes;
    } catch (e, st) {
      Logger.warning(
        'Garage driver marker failed for avatar=$id: $e\n$st',
        tag: 'MAP_MARKER',
      );
      return getDriverIconBytes();
    }
  }

  static int _countRgbaOpaquePixels(Uint8List rgba, int w, int h, {int minAlpha = 28}) {
    var n = 0;
    for (var i = 0; i < w * h; i++) {
      if (rgba[i * 4 + 3] >= minAlpha) n++;
    }
    return n;
  }

  static Future<Uint8List> _renderGarageMapMarkerPng(String assetPath) async {
    final ByteData imageBytes = await rootBundle.load(assetPath);
    final Uint8List sourceBytes = imageBytes.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final ui.Image decoded = frame.image;

    const double maxSize = 120.0;
    ui.Image? composed;
    try {
      final double srcW = decoded.width.toDouble();
      final double srcH = decoded.height.toDouble();
      final double aspectRatio = srcW / srcH;

      double destW, destH;
      if (aspectRatio > 1.0) {
        destW = maxSize;
        destH = maxSize / aspectRatio;
      } else {
        destH = maxSize;
        destW = maxSize * aspectRatio;
      }

      final double destX = (maxSize - destW) / 2;
      final double destY = (maxSize - destH) / 2;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, maxSize, maxSize));

      canvas.drawImageRect(
        decoded,
        ui.Rect.fromLTWH(0, 0, srcW, srcH),
        ui.Rect.fromLTWH(destX, destY, destW, destH),
        ui.Paint()..isAntiAlias = true..filterQuality = ui.FilterQuality.high,
      );

      final picture = recorder.endRecording();
      composed = await picture.toImage(maxSize.toInt(), maxSize.toInt());
      final img = composed;

      try {
        final raw = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (raw != null) {
          final w = maxSize.toInt();
          final opaque = _countRgbaOpaquePixels(raw.buffer.asUint8List(), w, w);
          const minOp = 80;
          if (opaque < minOp) {
            Logger.warning(
              'Garage skin aproape invizibilă ($opaque px) pentru $assetPath — fallback berlină',
              tag: 'MAP_MARKER',
            );
            return getDriverIconBytes();
          }
        }
      } catch (e) {
        Logger.debug('Verificare opacitate garage marker: $e', tag: 'MAP_MARKER');
      }

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return getDriverIconBytes();
      }
      return byteData.buffer.asUint8List();
    } finally {
      decoded.dispose();
      composed?.dispose();
    }
  }

  /// Blue 3D car icon — used for the driver marker on any map.
  static Future<Uint8List> getDriverIconBytes() async {
    if (_cachedDriverBytes != null) return _cachedDriverBytes!;
    try {
      // Try PNG asset first (overrides generated icon if provided)
      final ByteData data = await rootBundle.load(_assetPath);
      final Uint8List sourceBytes = data.buffer.asUint8List();

      const double maxSide = 96;
      final probeCodec = await ui.instantiateImageCodec(sourceBytes);
      final probeFrame = await probeCodec.getNextFrame();
      final nw = probeFrame.image.width;
      final nh = probeFrame.image.height;
      probeFrame.image.dispose();

      final ui.Codec loadCodec;
      if (nw >= nh) {
        loadCodec = await ui.instantiateImageCodec(
          sourceBytes,
          targetWidth: maxSide.toInt(),
        );
      } else {
        loadCodec = await ui.instantiateImageCodec(
          sourceBytes,
          targetHeight: maxSide.toInt(),
        );
      }
      final frame = await loadCodec.getNextFrame();
      final decoded = frame.image;
      final outW = decoded.width;
      final outH = decoded.height;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        ui.Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
      );
      canvas.drawImage(decoded, ui.Offset.zero, ui.Paint()..isAntiAlias = true);
      decoded.dispose();

      final picture = recorder.endRecording();
      final img = await picture.toImage(outW, outH);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      _cachedDriverBytes = byteData!.buffer.asUint8List();
      return _cachedDriverBytes!;
    } catch (_) {
      _cachedDriverBytes = await generateBlueCarIcon();
      return _cachedDriverBytes!;
    }
  }

  /// Blue 3D car PNG bytes — identical to map_screen LocationPuck icon.
  static Future<Uint8List> generateBlueCarIcon() async {
    if (_cachedDriverBytes != null) return _cachedDriverBytes!;
    const double size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, size, size));
    final paint = ui.Paint()..isAntiAlias = true;
    const double cx = size / 2;
    const double cy = size / 2;

    // 1. Drop shadow
    paint
      ..color = const ui.Color(0x55000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(center: const ui.Offset(cx + 2, cy + 5), width: 38, height: 62),
        const ui.Radius.circular(12),
      ),
      paint,
    );
    paint.maskFilter = null;

    // 2. Caroserie — gradient lateral 3D
    paint.shader = ui.Gradient.linear(
      const ui.Offset(cx - 19, cy),
      const ui.Offset(cx + 19, cy),
      [
        const ui.Color(0xFF0D1457),
        const ui.Color(0xFF3949AB),
        const ui.Color(0xFF283593),
        const ui.Color(0xFF0D1457),
      ],
      [0.0, 0.35, 0.65, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(center: const ui.Offset(cx, cy), width: 38, height: 64),
        const ui.Radius.circular(12),
      ),
      paint,
    );
    paint.shader = null;

    // 3-6. Roți
    _draw3DWheel(canvas, paint, cx - 22, cy - 20, 8, 12);
    _draw3DWheel(canvas, paint, cx + 14, cy - 20, 8, 12);
    _draw3DWheel(canvas, paint, cx - 22, cy + 10, 8, 12);
    _draw3DWheel(canvas, paint, cx + 14, cy + 10, 8, 12);

    // 7. Capotă față
    paint.shader = ui.Gradient.linear(
      const ui.Offset(cx, cy - 32),
      const ui.Offset(cx, cy - 16),
      [const ui.Color(0xFF5C6BC0), const ui.Color(0xFF283593)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(cx - 15, cy - 32, 30, 16),
        const ui.Radius.circular(5),
      ),
      paint,
    );
    paint.shader = null;

    // 8. Pavilion (roof)
    paint.shader = ui.Gradient.linear(
      const ui.Offset(cx - 12, cy - 18),
      const ui.Offset(cx + 12, cy + 10),
      [const ui.Color(0xFF7986CB), const ui.Color(0xFF3949AB), const ui.Color(0xFF1A237E)],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(cx - 12, cy - 18, 24, 30),
        const ui.Radius.circular(7),
      ),
      paint,
    );
    paint.shader = null;

    // 9. Parbriz față
    paint.shader = ui.Gradient.linear(
      const ui.Offset(cx - 10, cy - 17),
      const ui.Offset(cx + 10, cy - 5),
      [const ui.Color(0xCC9CE7FF), const ui.Color(0x9954D1F7)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(cx - 10, cy - 17, 20, 12),
        const ui.Radius.circular(3),
      ),
      paint,
    );
    paint.shader = null;
    // Reflexie parbriz
    paint.color = const ui.Color(0x55FFFFFF);
    final glarePath = ui.Path()
      ..moveTo(cx - 9, cy - 16)
      ..lineTo(cx - 3, cy - 16)
      ..lineTo(cx - 6, cy - 6)
      ..lineTo(cx - 10, cy - 6)
      ..close();
    canvas.drawPath(glarePath, paint);

    // 10. Luneta spate
    paint.shader = ui.Gradient.linear(
      const ui.Offset(cx, cy + 4),
      const ui.Offset(cx, cy + 14),
      [const ui.Color(0x9954D1F7), const ui.Color(0xCC1E6E8A)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(cx - 9, cy + 4, 18, 10),
        const ui.Radius.circular(3),
      ),
      paint,
    );
    paint.shader = null;

    // 11. Capotă spate
    paint.shader = ui.Gradient.linear(
      const ui.Offset(cx, cy + 16),
      const ui.Offset(cx, cy + 32),
      [const ui.Color(0xFF283593), const ui.Color(0xFF0D1457)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(cx - 15, cy + 16, 30, 16),
        const ui.Radius.circular(5),
      ),
      paint,
    );
    paint.shader = null;

    // 12. Faruri față
    _drawHeadlight(canvas, paint, cx - 13, cy - 32, isRear: false);
    _drawHeadlight(canvas, paint, cx + 13, cy - 32, isRear: false);

    // 13. Stopuri spate
    _drawHeadlight(canvas, paint, cx - 13, cy + 32, isRear: true);
    _drawHeadlight(canvas, paint, cx + 13, cy + 32, isRear: true);

    // 14. Highlight corp 3D
    paint.shader = ui.Gradient.linear(
      const ui.Offset(cx - 19, cy - 32),
      const ui.Offset(cx - 5, cy),
      [const ui.Color(0x44FFFFFF), const ui.Color(0x00FFFFFF)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(cx - 19, cy - 32, 14, 45),
        const ui.Radius.circular(12),
      ),
      paint,
    );
    paint.shader = null;

    // 15. Indicator disponibil (punct verde)
    paint
      ..color = const ui.Color(0x6600C853)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawCircle(const ui.Offset(cx + 16, cy + 28), 8, paint);
    paint.maskFilter = null;
    paint.color = const ui.Color(0xFF00E676);
    canvas.drawCircle(const ui.Offset(cx + 16, cy + 28), 6, paint);
    paint.color = const ui.Color(0xFF69F0AE);
    canvas.drawCircle(const ui.Offset(cx + 16, cy + 28), 3, paint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    _cachedDriverBytes = byteData!.buffer.asUint8List();
    return _cachedDriverBytes!;
  }

  /// Blue circle with white dot — passenger position marker.
  static Future<Uint8List> generatePassengerIcon() async {
    if (_cachedPassengerBytes != null) return _cachedPassengerBytes!;
    const double size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, size, size));
    final paint = ui.Paint()..isAntiAlias = true;
    const center = ui.Offset(size / 2, size / 2);
    const radius = size / 2 - 4;

    // Shadow
    paint
      ..color = const ui.Color(0x44000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    canvas.drawCircle(center.translate(0, 2), radius, paint);
    paint.maskFilter = null;
    // White ring
    paint.color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(center, radius + 2, paint);
    // Blue fill
    paint.color = const ui.Color(0xFF1976D2);
    canvas.drawCircle(center, radius, paint);
    // White center dot
    paint.color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(center, radius * 0.38, paint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    _cachedPassengerBytes = byteData!.buffer.asUint8List();
    return _cachedPassengerBytes!;
  }

  // ── Private drawing helpers ───────────────────────────────────────────────

  static void _draw3DWheel(
      ui.Canvas canvas, ui.Paint paint, double x, double y, double w, double h) {
    paint.shader = ui.Gradient.linear(
      ui.Offset(x, y),
      ui.Offset(x + w, y + h),
      [const ui.Color(0xFF424242), const ui.Color(0xFF212121)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(x, y, w, h),
        const ui.Radius.circular(3),
      ),
      paint,
    );
    paint.shader = null;
    paint.color = const ui.Color(0x66FFFFFF);
    canvas.drawOval(ui.Rect.fromLTWH(x + 1.5, y + 1.5, w - 3, h * 0.45), paint);
  }

  static void _drawHeadlight(
      ui.Canvas canvas, ui.Paint paint, double cx, double cy,
      {required bool isRear}) {
    final glowColor =
        isRear ? const ui.Color(0xAAFF1744) : const ui.Color(0xAAFFFFFF);
    final coreColor =
        isRear ? const ui.Color(0xFFFF1744) : const ui.Color(0xFFFFFFFF);
    final innerColor =
        isRear ? const ui.Color(0xFFFF8A80) : const ui.Color(0xFFFFEB3B);
    paint
      ..color = glowColor
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawOval(
        ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 10, height: 6), paint);
    paint.maskFilter = null;
    paint.color = coreColor;
    canvas.drawOval(
        ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 7, height: 4), paint);
    paint.color = innerColor;
    canvas.drawOval(
        ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 4, height: 2.5), paint);
  }
}
