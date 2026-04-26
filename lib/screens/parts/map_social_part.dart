// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapSocialMethods on _MapScreenState {

  Widget _buildMiniAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null && badge > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints:
                    const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: badge > 9 ? 9 : 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // _showNeighborsListSheet replaced by _openFriendSuggestions (Bump-style screen)

  /// ✅ NOU: Marker pentru Cereri de Cursă (Amber/Gold border)
  static Future<Uint8List> _generateDemandMarker(String emoji) async {
    final cacheKey = 'demand_$emoji';
    if (_MapScreenState._emojiMarkerCache.containsKey(cacheKey)) return _MapScreenState._emojiMarkerCache[cacheKey]!;

    const double size = 80;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));

    // Fundal cerc alb cu umbră aurie
    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x40FF8F00)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawCircle(const ui.Offset(size / 2, size / 2 + 2), size / 2 - 4, shadowPaint);

    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(const ui.Offset(size / 2, size / 2), size / 2 - 4, bgPaint);

    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFFFF8F00) // Amber/Orange pentru Cerere
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(const ui.Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

    // Emoji text
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 42, textAlign: TextAlign.center))
      ..addText(emoji);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: size));
    canvas.drawParagraph(paragraph, Offset(0, (size - paragraph.height) / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = _MapScreenState._pngBytesOrMinimalFallback(byteData, '_generateDemandMarker');
    _MapScreenState._emojiMarkerCache[cacheKey] = bytes;
    return bytes;
  }

  /// Fonturi încercate la rasterizare — pe Xiaomi / MIUI (ex. Redmi Note 11 Pro) numele efectiv
  /// al fontului emoji diferă; lista lungă crește șansa să se folosească glyph-uri color.
  static List<String> _mapReactionEmojiFontFallbacks() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const [
          'Noto Color Emoji',
          'NotoColorEmoji',
          'Noto Sans Color Emoji',
          'Noto Sans Symbols 2',
          'SamsungColorEmoji',
          'Segoe UI Emoji',
          'Noto Emoji',
        ];
      case TargetPlatform.iOS:
        return const [
          'Apple Color Emoji',
          'Noto Color Emoji',
        ];
      default:
        return const [
          'Noto Color Emoji',
          'Apple Color Emoji',
          'Segoe UI Emoji',
          'Noto Emoji',
        ];
    }
  }

  /// Emoji color pe hartă: `ParagraphBuilder` (dart:ui) poate folosi font fără color glyph → monocrom.
  /// `TextPainter` + fallback-uri Android/MIUI pentru raster corect.
  static Future<Uint8List> _generateMapReactionMarkerPng(String emoji) async {
    final cacheKey = 'map_reaction_v5_$emoji';
    if (_MapScreenState._emojiMarkerCache.containsKey(cacheKey)) return _MapScreenState._emojiMarkerCache[cacheKey]!;

    const double size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));

    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x35000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
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
      ..color = const ui.Color(0xFFE91E63)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2),
      size / 2 - 4,
      borderPaint,
    );

    final emojiFallbacks = _mapReactionEmojiFontFallbacks();
    final tp = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: 52,
          height: 1.0,
          // Pe Android, un fontFamily principal + fallback-uri MIUI/AOSP.
          fontFamily: defaultTargetPlatform == TargetPlatform.android
              ? emojiFallbacks.first
              : null,
          fontFamilyFallback: emojiFallbacks,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout(maxWidth: size);
    final dx = (size - tp.width) / 2;
    final dy = (size - tp.height) / 2;
    tp.paint(canvas, Offset(dx, dy));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = _MapScreenState._pngBytesOrMinimalFallback(byteData, '_generateMapReactionMarkerPng');
    _MapScreenState._emojiMarkerCache[cacheKey] = bytes;
    return bytes;
  }

  /// Bulă circulară pentru postări pe hartă — aceeași rezoluție ca reacțiile emoji (~96px),
  /// bordură magenta ca să se distingă de markerele vecinilor (violet).
  static Future<Uint8List> _generateMapMomentBubblePng(String symbol) async {
    final cacheKey = 'map_moment_bubble_v1_$symbol';
    if (_MapScreenState._emojiMarkerCache.containsKey(cacheKey)) {
      return _MapScreenState._emojiMarkerCache[cacheKey]!;
    }

    const double size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));

    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x35000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
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
      ..color = const ui.Color(0xFFE040FB)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2),
      size / 2 - 4,
      borderPaint,
    );

    final emojiFallbacks = _mapReactionEmojiFontFallbacks();
    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: 50,
          height: 1.0,
          fontFamily: defaultTargetPlatform == TargetPlatform.android
              ? emojiFallbacks.first
              : null,
          fontFamilyFallback: emojiFallbacks,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout(maxWidth: size);
    final dx = (size - tp.width) / 2;
    final dy = (size - tp.height) / 2;
    tp.paint(canvas, Offset(dx, dy));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = _MapScreenState._pngBytesOrMinimalFallback(byteData, '_generateMapMomentBubblePng');
    _MapScreenState._emojiMarkerCache[cacheKey] = bytes;
    return bytes;
  }

  /// Generează iconița mașinuță 3D pentru vecinii care sunt șoferi disponibili.
  /// Portată din friendsride_app. Cache inclusiv nivel baterie (chip pe icon).
  static Future<Uint8List> _generateNeighborCarMarker({
    int? batteryLevel,
    bool isCharging = false,
  }) async {
    final batKey =
        NeighborFriendMarkerIcons.batteryBucketForMarker(batteryLevel)?.toString() ?? 'n';
    final cacheKey = 'neighbor_driver_3d_b$batKey${isCharging ? 'c' : 'n'}';
    if (_MapScreenState._emojiMarkerCache.containsKey(cacheKey)) return _MapScreenState._emojiMarkerCache[cacheKey]!;

    const double size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
    final paint = ui.Paint()..isAntiAlias = true;

    final double cx = size / 2;
    final double cy = size / 2;
    const double radius = size / 2 - 4;

    // 1. Fundal cerc alb (consistență cu markerii social emoji)
    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(ui.Offset(cx, cy), radius, bgPaint);

    // 2. Bordură violet Nabour
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF7C3AED)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(ui.Offset(cx, cy), radius, borderPaint);

    // 3. Drop shadow pentru mașină
    paint
      ..color = const ui.Color(0x55000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(center: ui.Offset(cx + 1, cy + 3), width: 34, height: 58),
        const ui.Radius.circular(10),
      ),
      paint,
    );
    paint.maskFilter = null;

    // Caroserie â€” gradient lateral 3D
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx - 19, cy),
      ui.Offset(cx + 19, cy),
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
        ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 38, height: 64),
        const ui.Radius.circular(12),
      ),
      paint,
    );
    paint.shader = null;

    // Roți
    _drawNeighborWheel(canvas, paint, cx - 22, cy - 20, 8, 12);
    _drawNeighborWheel(canvas, paint, cx + 14, cy - 20, 8, 12);
    _drawNeighborWheel(canvas, paint, cx - 22, cy + 10, 8, 12);
    _drawNeighborWheel(canvas, paint, cx + 14, cy + 10, 8, 12);

    // Capotă față
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx, cy - 32),
      ui.Offset(cx, cy - 16),
      [const ui.Color(0xFF5C6BC0), const ui.Color(0xFF283593)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 15, cy - 32, 30, 16),
        const ui.Radius.circular(5),
      ),
      paint,
    );
    paint.shader = null;

    // Pavilion (roof)
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx - 12, cy - 18),
      ui.Offset(cx + 12, cy + 10),
      [const ui.Color(0xFF7986CB), const ui.Color(0xFF3949AB), const ui.Color(0xFF1A237E)],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 12, cy - 18, 24, 30),
        const ui.Radius.circular(7),
      ),
      paint,
    );
    paint.shader = null;

    // Parbriz față
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx - 10, cy - 17),
      ui.Offset(cx + 10, cy - 5),
      [const ui.Color(0xCC9CE7FF), const ui.Color(0x9954D1F7)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 10, cy - 17, 20, 12),
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

    // Luneta spate
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx, cy + 4),
      ui.Offset(cx, cy + 14),
      [const ui.Color(0x9954D1F7), const ui.Color(0xCC1E6E8A)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 9, cy + 4, 18, 10),
        const ui.Radius.circular(3),
      ),
      paint,
    );
    paint.shader = null;

    // Capotă spate
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx, cy + 16),
      ui.Offset(cx, cy + 32),
      [const ui.Color(0xFF283593), const ui.Color(0xFF0D1457)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 15, cy + 16, 30, 16),
        const ui.Radius.circular(5),
      ),
      paint,
    );
    paint.shader = null;

    // Faruri față
    _drawNeighborHeadlight(canvas, paint, cx - 13, cy - 32, isRear: false);
    _drawNeighborHeadlight(canvas, paint, cx + 13, cy - 32, isRear: false);

    // Stopuri spate
    _drawNeighborHeadlight(canvas, paint, cx - 13, cy + 32, isRear: true);
    _drawNeighborHeadlight(canvas, paint, cx + 13, cy + 32, isRear: true);

    // Highlight 3D
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx - 19, cy - 32),
      ui.Offset(cx - 5, cy),
      [const ui.Color(0x44FFFFFF), const ui.Color(0x00FFFFFF)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 19, cy - 32, 14, 45),
        const ui.Radius.circular(12),
      ),
      paint,
    );
    paint.shader = null;

    // Indicator disponibil (punct verde)
    paint
      ..color = const ui.Color(0x6600C853)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 8, paint);
    paint.maskFilter = null;
    paint.color = const ui.Color(0xFF00E676);
    canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 6, paint);
    paint.color = const ui.Color(0xFF69F0AE);
    canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 3, paint);

    NeighborFriendMarkerIcons.paintBatteryChip(
      canvas,
      size,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes =
        _MapScreenState._pngBytesOrMinimalFallback(byteData, '_generateNeighborCarMarker');
    _MapScreenState._emojiMarkerCache[cacheKey] = bytes;
    return bytes;
  }

  static void _drawNeighborWheel(
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

  static void _drawNeighborHeadlight(
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

  /// Activează vizibilitatea cu o durată opțională (null = permanent).
  Future<void> _activateVisibility({Duration? duration}) async {
    await GhostModeService.instance.setBlocking(false);
    _ghostModeTimer?.cancel();
    _ghostModeTimer = null;
    setState(() {
      _isVisibleToNeighbors = true;
      _neighborActivityFeedDismissed = false;
    });

    final pos = _currentPositionObject;
    if (pos != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users').doc(uid).get();
        final data = userDoc.data() ?? {};

        final avatar = data['avatar'] as String? ?? '🙂';
        final displayName = data['displayName'] as String? ?? 'Vecin';
        final licensePlate = data['licensePlate'] as String?;
        final photoURL = data['photoURL'] as String?;

        _neighborAvatarCache[uid] = avatar;
        _neighborDisplayNameCache[uid] = displayName;
        if (licensePlate != null) _neighborLicensePlateCache[uid] = licensePlate;
        if (photoURL != null) _neighborPhotoURLCache[uid] = photoURL;
        _setNeighborGarageCachesFromUserData(uid, data);
        final isDrv = _currentRole == UserRole.driver && _isDriverAvailable;
        final carAvatarId = _effectivePublishedCarAvatarId(
          uid,
          useDriverGarageSlot: _mapShowsDriverTransportIdentity,
        );

        await publishNeighborMapVisibility(
          position: pos,
          avatar: avatar,
          displayName: displayName,
          isDriver: isDrv,
          licensePlate: licensePlate,
          photoURL: photoURL,
          allowedUids: _contactUids?.toList() ?? [],
          carAvatarId: carAvatarId,
        );
        if (isDrv) {
          unawaited(
            _firestoreService.mergeDriverPassengerLiveMapVisibilityForCurrentUser(true),
          );
        }
      }
    }
    _listenForNeighbors();
    _subscribeToMoments();

    // Prune old activity feed events in background
    unawaited(ActivityFeedService.instance.pruneOldEvents());

    // Pornește periodic publish pentru pasager (și pentru driver indisponibil),
    // doar dacă nu există deja timerul dedicat driverului disponibil.
    final bool shouldPeriodicPublish =
        !(_currentRole == UserRole.driver && _isDriverAvailable);
    if (shouldPeriodicPublish) {
      _visibilityPublishTimer?.cancel();
      _visibilityPublishTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (!mounted || !_isVisibleToNeighbors) return;
        final p = _currentPositionObject;
        if (p == null) return;

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        final isDrv = _currentRole == UserRole.driver && _isDriverAvailable;

        publishNeighborMapVisibilityUnawaited(
          position: p,
          avatar: _neighborAvatarCache[uid] ?? '🙂',
          displayName: _neighborDisplayNameCache[uid] ?? 'Vecin',
          isDriver: isDrv,
          licensePlate: _neighborLicensePlateCache[uid],
          photoURL: _neighborPhotoURLCache[uid],
          allowedUids: _contactUids?.toList() ?? [],
          carAvatarId: _effectivePublishedCarAvatarId(
            uid,
            useDriverGarageSlot: _mapShowsDriverTransportIdentity,
          ),
        );
      });
    }

    // Timer auto-dezactivare
    if (duration != null) {
      _ghostModeTimer = Timer(duration, () {
        if (mounted) _deactivateVisibility();
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('social_map_visible', true);
  }

  /// Doar când utilizatorul a ales explicit „vizibil vecinilor” (nu și la simplul „șofer disponibil”).
  bool get _wantsNeighborSocialPublish => _isVisibleToNeighbors;

  void _setNeighborGarageCachesFromUserData(String uid, Map<String, dynamic> data) {
    final rawDriver = CarAvatarService.resolveSlotId(data, CarAvatarMapSlot.driver);
    _neighborCarAvatarDriverCache[uid] =
        CarAvatarService.coerceDriverAvatarIdForMap(rawDriver);
    final rawPassenger =
        CarAvatarService.resolveSlotId(data, CarAvatarMapSlot.passenger);
    _neighborCarAvatarPassengerCache[uid] =
        CarAvatarService.coercePassengerAvatarIdForMap(rawPassenger);
  }

  String _effectivePublishedCarAvatarId(
    String uid, {
    required bool useDriverGarageSlot,
  }) {
    if (useDriverGarageSlot) {
      return _neighborCarAvatarDriverCache[uid] ?? 'default_car';
    }
    return _neighborCarAvatarPassengerCache[uid] ?? 'default_car';
  }

  Future<void> _publishNeighborSocialMapFresh(
    geolocator.Position position, {
    bool forceNeighborTelemetry = false,
  }) async {
    if (!_wantsNeighborSocialPublish) return;
    await GhostModeService.instance.ensureLoaded();
    if (GhostModeService.instance.isBlocking) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;
      final data = doc.data() ?? {};
      final auth = FirebaseAuth.instance.currentUser;
      final dn = (data['displayName'] as String?)?.trim();
      final authName = auth?.displayName?.trim();
      final resolvedName = (dn != null && dn.isNotEmpty) ? dn : (authName ?? 'Vecin');
      final rawPlate = (data['licensePlate'] as String?)?.trim();
      final plate = (rawPlate != null && rawPlate.isNotEmpty)
          ? rawPlate
          : (data['carPlate'] ?? data['plate'])?.toString().trim();

      _setNeighborGarageCachesFromUserData(uid, data);
      final isDrv = _currentRole == UserRole.driver && _isDriverAvailable;
      final carAvatarId = _effectivePublishedCarAvatarId(
        uid,
        useDriverGarageSlot: _mapShowsDriverTransportIdentity,
      );

      await publishNeighborMapVisibility(
        position: position,
        avatar: data['avatar'] as String? ?? '🙂',
        displayName: resolvedName,
        isDriver: isDrv,
        licensePlate: (plate != null && plate.isNotEmpty) ? plate : null,
        photoURL: data['photoURL'] as String?,
        allowedUids: _contactUids?.toList() ?? [],
        forceNeighborTelemetry: forceNeighborTelemetry,
        carAvatarId: carAvatarId,
      );
    } catch (e) {
      Logger.error('Social map publish failed: $e', error: e, tag: 'MAP');
    }
  }

  void _publishNeighborSocialMapFreshUnawaited(
    geolocator.Position position, {
    bool forceNeighborTelemetry = false,
  }) {
    unawaited(_publishNeighborSocialMapFresh(
      position,
      forceNeighborTelemetry: forceNeighborTelemetry,
    ));
  }

  Future<void> _deactivateVisibility() async {
    _ghostModeTimer?.cancel();
    _ghostModeTimer = null;
    _pausedSocialPublishTimer?.cancel();
    _pausedSocialPublishTimer = null;
    _visibilityPublishTimer?.cancel();
    _visibilityPublishTimer = null;
    setState(() {
      _isVisibleToNeighbors = false;
      _neighborActivityFeedDismissed = false;
    });
    _cancelNeighborLocationSubscriptions();
    await NeighborLocationService().setInvisible();
    NeighborStationaryTracker.instance.reset();
    NeighborSavedPlacesCache.instance.dispose();
    NeighborMapFeedController.instance.setNeighbors([]);
    for (final ann in _neighborAnnotations.values) {
      try { await _neighborsAnnotationManager?.delete(ann); } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }
    _neighborAnnotations.clear();
    _neighborAnnotationIdToUid.clear();
    _neighborData.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('social_map_visible', false);
  }

  /// Arată mereu sheet-ul cu opțiunile de vizibilitate (inclusiv Invizibil).
  Future<void> _toggleVisibleToNeighbors() async {
    if (!mounted) return;
    final result = await showModalBottomSheet<Duration?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: SingleChildScrollView(child: const GhostModeSheet()),
      ),
    );
    if (result == null) return; // user a Ã®nchis fără să aleagă

    if (result == _kInvisibleChoice) {
      await _deactivateVisibility();
      await GhostModeService.instance.setBlocking(true);
      return;
    }
    // Duration.zero = permanent
    await _activateVisibility(
      duration: result == Duration.zero ? null : result,
    );
  }

  Future<void> _checkInactiveUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('last_ride_date');
      if (raw == null) return;
      final lastRide = DateTime.tryParse(raw);
      await PushCampaignService().checkInactiveUser(lastRide);
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
  }

}

