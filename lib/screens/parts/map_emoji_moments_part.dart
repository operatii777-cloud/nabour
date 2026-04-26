// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapEmojiMomentsMethods on _MapScreenState {
  void _initEmojiListener() {
    _emojiSubscription = MapEmojiService().listenToRecentEmojis().listen(
      (emojis) {
        if (!mounted) return;
        _lastReceivedEmojis = List<MapEmoji>.from(emojis);
        unawaited(_updateEmojiMarkers(_lastReceivedEmojis));
      },
      onError: (Object e, StackTrace st) {
        Logger.error(
          'Map emoji Firestore stream error: $e',
          error: e,
          stackTrace: st,
          tag: 'EMOJI',
        );
      },
    );
  }

  bool _hasMyMapEmojiPlaced(String? uid) {
    if (uid == null || uid.isEmpty) return false;
    return _lastReceivedEmojis.any((m) => m.senderId == uid || m.id == uid);
  }

  Future<void> _removeMyMapEmoji() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      await MapEmojiService().removeMyEmoji(uid);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _lastReceivedEmojis =
            _lastReceivedEmojis.where((x) => x.senderId != uid && x.id != uid).toList();
        _lastMapEmojiLayerSig = null;
        _showEmojiPicker = false;
      });
      unawaited(_updateEmojiMarkers(_lastReceivedEmojis));
      _showSafeSnackBar(
        AppLocalizations.of(context)!.mapEmojiRemoved,
        Colors.green.shade700,
      );
    } catch (_) {
      if (mounted) {
        _showSafeSnackBar(
          AppLocalizations.of(context)!.mapEmojiDeleteError,
          const Color(0xFFB71C1C),
        );
      }
    }
  }

  String _signatureForMapEmojiLayer(List<MapEmoji> emojis) {
    final b = StringBuffer();
    for (final e in emojis) {
      final label = normalizeMapEmojiForEngine(e.emoji);
      b.write(e.id);
      b.write('|');
      b.write(label);
      b.write('|');
      b.write(e.lat.toStringAsFixed(5));
      b.write('|');
      b.write(e.lng.toStringAsFixed(5));
      b.write(';');
    }
    b.write('|av:');
    for (final p in _avatarPinsForEmojiAvoidance) {
      b.write(p.lat.toStringAsFixed(3));
      b.write(',');
      b.write(p.lng.toStringAsFixed(3));
      b.write(';');
    }
    return b.toString();
  }

  static const double _kEmojiClearOfAvatarM = 22.0;
  static const double _kEmojiPushAwayM = 28.0;

  double _neighborAvatarZoomFactor() {
    // În timpul fly-ului din spațiu camera trece prin zoom 1→15.
    // Nu scalăm în această perioadă — evităm flash-ul vizibil.
    if (_spaceIntroInFlight) return 1.0;
    
    // Zoom levels definitions
    const double zoomFull = 15.5; // Base scale (1.0)
    const double zoomMin  = 11.0; // Minimum scale (0.4)
    const double sizeMin  = 0.40;
    
    if (_liveCameraZoom >= zoomFull) {
      // ✅ User request: "when I zoom in I want the avatar to increase compared to its normal size"
      // At zoom 15.5 -> factor 1.0
      // At zoom 19.5 -> factor 2.0 (approx 25% increase per zoom level)
      return 1.0 + (_liveCameraZoom - zoomFull) * 0.25;
    }
    
    if (_liveCameraZoom <= zoomMin)  return sizeMin;
    
    // Linear interpolation between zoomMin and zoomFull
    return sizeMin + (1.0 - sizeMin) * (_liveCameraZoom - zoomMin) / (zoomFull - zoomMin);
  }

  /// Mută ușor coordonatele emoji-ului plasat ca să nu stea peste avatarul unui user.
  ({double lat, double lng}) _offsetMapEmojiFromAvatarPins(
    double lat,
    double lng,
    String stableId,
  ) {
    var la = lat;
    var ln = lng;
    if (_avatarPinsForEmojiAvoidance.isEmpty) {
      return (lat: la, lng: ln);
    }
    for (var it = 0; it < 6; it++) {
      var need = false;
      var sumNorth = 0.0;
      var sumEast = 0.0;
      for (final p in _avatarPinsForEmojiAvoidance) {
        final d = geolocator.Geolocator.distanceBetween(la, ln, p.lat, p.lng);
        if (d >= _kEmojiClearOfAvatarM) continue;
        need = true;
        if (d < 0.6) {
          final a = 2 * math.pi * ((stableId.hashCode & 0xffff) / 65536.0);
          sumNorth += math.cos(a);
          sumEast += math.sin(a);
        } else {
          final bearDeg = geolocator.Geolocator.bearingBetween(
            p.lat, p.lng, la, ln,
          );
          final bear = bearDeg * math.pi / 180.0;
          sumNorth += math.cos(bear);
          sumEast += math.sin(bear);
        }
      }
      if (!need) break;
      final mag = math.sqrt(sumNorth * sumNorth + sumEast * sumEast);
      if (mag < 1e-8) break;
      final nrmN = sumNorth / mag * _kEmojiPushAwayM;
      final nrmE = sumEast / mag * _kEmojiPushAwayM;
      final cosL =
          math.cos(la * math.pi / 180.0).abs().clamp(0.25, 1.0);
      la += nrmN / 111320.0;
      ln += nrmE / (111320.0 * cosL);
    }
    return (lat: la, lng: ln);
  }

  /// Stack vizual "pachet de carti / trepte" pentru puncte apropiate.
  /// Returneaza coordonate mutate stabil (determinist dupa id).
  Map<String, ({double lat, double lng})> _buildStaircaseLayout(
    List<({String id, double lat, double lng})> points, {
    double bucketDeg = 0.00022,
    double stepMeters = 18.0,
  }) {
    final out = <String, ({double lat, double lng})>{};
    if (points.isEmpty) return out;

    final groups = <String, List<({String id, double lat, double lng})>>{};
    for (final p in points) {
      final gx = (p.lat / bucketDeg).round();
      final gy = (p.lng / bucketDeg).round();
      final key = '$gx:$gy';
      groups.putIfAbsent(key, () => <({String id, double lat, double lng})>[])
          .add(p);
    }

    for (final g in groups.values) {
      if (g.length == 1) {
        final p = g.first;
        out[p.id] = (lat: p.lat, lng: p.lng);
        continue;
      }

      // Adaptiv: puține elemente => mai răsfirat; multe => mai compact.
      final double scale = switch (g.length) {
        <= 2 => 1.35,
        <= 4 => 1.18,
        <= 7 => 1.0,
        <= 10 => 0.84,
        _ => 0.68,
      };
      final double groupStepM = (stepMeters * scale).clamp(8.0, 24.0);

      g.sort((a, b) => a.id.compareTo(b.id));
      final baseLat = g.fold<double>(0.0, (s, p) => s + p.lat) / g.length;
      final baseLng = g.fold<double>(0.0, (s, p) => s + p.lng) / g.length;
      final cosLat = math.cos(baseLat * math.pi / 180.0).abs().clamp(0.25, 1.0);

      for (var i = 0; i < g.length; i++) {
        final p = g[i];
        // Trepte: jos + dreapta.
        final downM = i * groupStepM;
        final rightM = i * groupStepM * 0.95;
        final lat = baseLat + (-downM / 111320.0);
        final lng = baseLng + (rightM / (111320.0 * cosLat));
        out[p.id] = (lat: lat, lng: lng);
      }
    }

    return out;
  }

  void _recomputeAvatarPinsForEmojiAvoidance() {
    final filteredNeighbors = _lastFilteredNeighborsForMap;
    final displayByUid = _lastNeighborDisplayByUid;
    final pins = <({double lat, double lng})>[];
    final my = _positionForUserMapMarker();
    if (my != null) {
      pins.add((lat: my.latitude, lng: my.longitude));
    }
    for (final n in filteredNeighbors) {
      if (_nearbyDriverAnnotations.containsKey(n.uid)) continue;
      final disp = displayByUid[n.uid];
      if (disp != null) {
        pins.add((lat: disp.lat, lng: disp.lng));
      } else {
        pins.add((lat: n.lat, lng: n.lng));
      }
    }
    for (final ann in _nearbyDriverAnnotations.values) {
      try {
        final g = ann.geometry;
        final c = g.coordinates;
        pins.add((lat: c.lat.toDouble(), lng: c.lng.toDouble()));
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }
    _avatarPinsForEmojiAvoidance = pins;
    _scheduleEmojiAvoidanceRebuildDebounced();
  }

  void _scheduleEmojiAvoidanceRebuildDebounced() {
    _emojiAvoidanceDebounce?.cancel();
    _emojiAvoidanceDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _lastMapEmojiLayerSig = null;
      unawaited(_updateEmojiMarkers(_lastReceivedEmojis));
    });
  }

  // Dimensiunile de bază (la zoom full) pentru fiecare strat de markere.
  static const double _kMomentBaseSize        = 1.68;
  static const double _kParkingSwapBaseSize   = 0.8;
  static const double _kParkingYieldBaseSize  = 0.92;
  static const double _kRideBroadcastBaseSize = 2.2;
  static const double _kMagicEventBaseSize    = 1.35;
  static const double _kEmergencyBaseSize     = 0.8;

  Future<void> _applyUserAvatarLayersZoomScale() async {
    if (!mounted) return;
    final zf = _neighborAvatarZoomFactor();
    final futures = <Future<void>>[];

    // ── Avatare vecini ────────────────────────────────────────────────────
    if (_neighborsAnnotationManager != null) {
      for (final e in _neighborAnnotations.entries.toList()) {
        final base = _neighborIconSizeBaseByUid[e.key];
        if (base == null) continue;
        final ann = e.value;
        ann.iconSize = base * zf;
        futures.add(_neighborsAnnotationManager!.update(ann).catchError((_) {}));
      }
    }

    // ── Șoferi disponibili ────────────────────────────────────────────────
    if (_driversAnnotationManager != null) {
      const baseDriver = 0.72;
      for (final ann in _nearbyDriverAnnotations.values.toList()) {
        ann.iconSize = baseDriver * zf;
        futures.add(_driversAnnotationManager!.update(ann).catchError((_) {}));
      }
    }

    // ── Emoji reacții ─────────────────────────────────────────────────────
    if (_emojiAnnotationManager != null) {
      final targetEmoji = _emojiIconSizeBase * zf;
      for (final ann in _emojiAnnotations.values.toList()) {
        ann.iconSize = targetEmoji;
        futures.add(_emojiAnnotationManager!.update(ann).catchError((_) {}));
      }
    }

    // ── Momente (bule postări) ────────────────────────────────────────────
    if (_momentAnnotationManager != null) {
      final targetMoment = _kMomentBaseSize * zf;
      for (final ann in _momentAnnotations.values.toList()) {
        ann.iconSize = targetMoment;
        futures.add(_momentAnnotationManager!.update(ann).catchError((_) {}));
      }
    }

    // ── Parking swap ──────────────────────────────────────────────────────
    if (_parkingSwapAnnotationManager != null) {
      final targetParking = _kParkingSwapBaseSize * zf;
      for (final ann in _parkingSpotAnnotations.values.toList()) {
        ann.iconSize = targetParking;
        futures.add(_parkingSwapAnnotationManager!.update(ann).catchError((_) {}));
      }
    }

    // ── Parking yield ─────────────────────────────────────────────────────
    final yieldAnn = _parkingYieldMySpotAnnotation;
    if (_parkingYieldMySpotManager != null && yieldAnn != null) {
      yieldAnn.iconSize = _kParkingYieldBaseSize * zf;
      futures.add(_parkingYieldMySpotManager!.update(yieldAnn).catchError((_) {}));
    }

    // ── Ride broadcasts ───────────────────────────────────────────────────
    if (_rideBroadcastsAnnotationManager != null) {
      final targetRide = _kRideBroadcastBaseSize * zf;
      for (final ann in _rideBroadcastAnnotations.values.toList()) {
        ann.iconSize = targetRide;
        futures.add(_rideBroadcastsAnnotationManager!.update(ann).catchError((_) {}));
      }
    }

    // ── Magic events ──────────────────────────────────────────────────────
    if (_magicEventAnnotationManager != null) {
      final targetMagic = _kMagicEventBaseSize * zf;
      for (final ann in _magicEventAnnotations.values.toList()) {
        ann.iconSize = targetMagic;
        futures.add(_magicEventAnnotationManager!.update(ann).catchError((_) {}));
      }
    }

    // ── Emergency ─────────────────────────────────────────────────────────
    if (_emergencyAnnotationManager != null) {
      final targetEmergency = _kEmergencyBaseSize * zf;
      for (final ann in _emergencyAnnotations.values.toList()) {
        ann.iconSize = targetEmergency;
        futures.add(_emergencyAnnotationManager!.update(ann).catchError((_) {}));
      }
    }

    // Trimite toate update-urile concurent într-un singur batch de platform-channel calls.
    if (futures.isNotEmpty) await Future.wait(futures, eagerError: false);

    // ── Mystery boxes ─────────────────────────────────────────────────────
    await Future.wait([
      _mysteryBoxManager?.applyZoomScale(zf) ?? Future.value(),
      _communityMysteryManager?.applyZoomScale(zf) ?? Future.value(),
    ], eagerError: false);
  }

  Future<void> _updateEmojiMarkers(List<MapEmoji> emojis) async {
    if (_mapboxMap == null) return;
    try {
      _emojiAnnotationManager ??= await _mapboxMap!.annotations.createPointAnnotationManager(id: 'map-emojis-layer');

      final sig = _signatureForMapEmojiLayer(emojis);
      // Nu sări dacă managerul lipsește (ex. după loadStyleURI) — altfel rămâne sig vechi fără straturi.
      if (_emojiAnnotationManager != null &&
          _lastMapEmojiLayerSig != null &&
          sig == _lastMapEmojiLayerSig) {
        return;
      }

      // `PointAnnotation.update` păstrează uneori textField vechi / nu aplică corect `image` — reconstruim stratul.
      try {
        await _emojiAnnotationManager?.deleteAll();
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      _emojiAnnotations.clear();

      double iconSize = _kMapReactionEmojiIconSize;
      if (mounted) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        // Min puțin mai mare ca emoji-urile să rămână lizibile lângă alte straturi.
        iconSize = (0.29 * dpr).clamp(0.75, 1.35);
      }
      _emojiIconSizeBase = iconSize;
      iconSize = iconSize * _neighborAvatarZoomFactor();

      final baseEmojiPoints = <({String id, double lat, double lng})>[];
      for (final e in emojis) {
        final adj = _offsetMapEmojiFromAvatarPins(e.lat, e.lng, e.id);
        baseEmojiPoints.add((id: e.id, lat: adj.lat, lng: adj.lng));
      }
      final staircaseById = _buildStaircaseLayout(
        baseEmojiPoints,
        // Emoji: mai compacte ca să nu acopere harta.
        stepMeters: 11.0,
      );

      for (final e in emojis) {
        final label = normalizeMapEmojiForEngine(e.emoji);
        final p = staircaseById[e.id] ??
            (lat: e.lat, lng: e.lng);
        final point = MapboxUtils.createPoint(p.lat, p.lng);
        final png = await _MapSocialMethods._generateMapReactionMarkerPng(label);
        final emojiImageName = 'nabour_emoji_${e.id}';
        final emojiImgOk = _mapboxMap != null && await _registerStyleImageFromPng(emojiImageName, png);
        final options = PointAnnotationOptions(
          geometry: point,
          iconImage: emojiImgOk ? emojiImageName : null,
          iconSize: iconSize,
          iconAnchor: IconAnchor.BOTTOM,
        );
        final ann = await _emojiAnnotationManager?.create(options);
        if (ann != null) {
          _emojiAnnotations[e.id] = ann;
        }
      }
      _lastMapEmojiLayerSig = sig;
    } catch (e, st) {
      Logger.error('Update emoji markers failed (stale layer?): $e',
          error: e, stackTrace: st, tag: 'EMOJI');
      _emojiAnnotationManager = null;
      _emojiAnnotations.clear();
      _lastMapEmojiLayerSig = null;
    }
  }

  /// Emoji-urile plasate pe hartă trebuie să stea deasupra bulelor de postări — ordinea de creare contează în Mapbox.
  Future<void> _rebuildEmojiThenMomentLayers() async {
    if (_mapboxMap == null || !mounted) return;
    await _updateEmojiMarkers(_lastReceivedEmojis);
    if (!mounted || _mapboxMap == null) return;
    await _updateMomentMarkers(_activeMoments);
  }

  /// Emoji / avatar afișat în bula circulară (aceeași scară vizuală ca markerele vecinilor).
  String _symbolForMapMoment(MapMoment m) {
    if (m.emoji != null && m.emoji!.trim().isNotEmpty) return m.emoji!.trim();
    if (m.authorAvatar.trim().isNotEmpty) return m.authorAvatar.trim();
    return '✨';
  }

  /// Text sub bulă (caption scurt sau nume).
  String _mapMomentCaptionBubble(MapMoment m) {
    final cap = m.caption.trim();
    if (cap.isNotEmpty) {
      final runes = cap.runes;
      return runes.length > 42
          ? '${String.fromCharCodes(runes.take(39))}…'
          : cap;
    }
    final n = m.authorName.trim();
    if (n.isNotEmpty) return n;
    return 'Moment';
  }

  void _onMomentMarkerTapped(PointAnnotation annotation) {
    if (!mounted) return;
    final momentId = _momentAnnotationIdToMomentId[annotation.id];
    if (momentId == null) return;
    MapMoment? found;
    for (final x in _activeMoments) {
      if (x.id == momentId) {
        found = x;
        break;
      }
    }
    if (found == null) return;
    _showMapMomentActions(found);
  }

  void _showMapMomentActions(MapMoment m) {
    final self = FirebaseAuth.instance.currentUser?.uid;
    final isMine = self != null && self == m.authorUid;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final left = m.expiresAt.difference(DateTime.now());
        final expiryLabel = left.isNegative
            ? AppLocalizations.of(ctx)!.mapMomentExpired
            : left.inMinutes >= 1
                ? AppLocalizations.of(ctx)!.mapMomentExpiresInMinutes(left.inMinutes)
                : AppLocalizations.of(ctx)!.mapMomentExpiresSoon;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(m.authorAvatar, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            expiryLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  m.caption.isEmpty ? 'Moment' : m.caption,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          title: Text(AppLocalizations.of(dCtx)!.mapDeleteMomentTitle),
                          content: Text(AppLocalizations.of(dCtx)!.mapDeleteMomentContent),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: Text(AppLocalizations.of(dCtx)!.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: Text(AppLocalizations.of(dCtx)!.delete),
                            ),
                          ],
                        ),
                      );
                      if (ok != true || !mounted) return;
                      final deleted =
                          await MapMomentService.instance.delete(m.id);
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showSafeSnackBar(
                        deleted
                            ? AppLocalizations.of(context)!.mapMomentDeleted
                            : AppLocalizations.of(context)!.mapMomentDeleteError,
                        deleted ? Colors.green.shade700 : const Color(0xFFB71C1C),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(AppLocalizations.of(ctx)!.mapDeleteOrCancelPost),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(ctx)!.close),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateMomentMarkers(List<MapMoment> moments) async {
    if (_mapboxMap == null) return;
    try {
      // Stratul emoji trebuie să existe în stil înainte de `below`; altfel bulele de momente
      // sunt desenate deasupra și acoperă emoji-urile plasate pe hartă.
      _emojiAnnotationManager ??=
          await _mapboxMap!.annotations.createPointAnnotationManager(
        id: 'map-emojis-layer',
      );

      if (_momentAnnotationManager == null) {
        _momentAnnotationManager =
            await _mapboxMap!.annotations.createPointAnnotationManager(
          id: 'map-moments-layer',
          below: 'map-emojis-layer',
        );
        _momentAnnotationManager!.tapEvents(
          onTap: (PointAnnotation a) => _onMomentMarkerTapped(a),
        );
      }

      final activeIds = moments.map((m) => m.id).toSet();

      for (final id in _momentAnnotations.keys.toList()) {
        if (!activeIds.contains(id)) {
          try {
            final ann = _momentAnnotations[id]!;
            _momentAnnotationIdToMomentId.remove(ann.id);
            await _momentAnnotationManager?.delete(ann);
          } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          _momentAnnotations.remove(id);
        }
      }

      const double momentIconSize = 2.0; // aliniat la markerele emoji ale vecinilor (~80px PNG)
      const List<double> momentTextOffset = [0, 2.5];
      const int momentTextColor = 0xFF7C3AED;
      final momentPoints = <({String id, double lat, double lng})>[];
      for (final m in moments) {
        if (m.isExpired) continue;
        // Evitam suprapunerea pe pinii de user, apoi aplicam stack "trepte".
        final adj = _offsetMapEmojiFromAvatarPins(m.lat, m.lng, 'moment_${m.id}');
        momentPoints.add((id: m.id, lat: adj.lat, lng: adj.lng));
      }
      final momentStairById = _buildStaircaseLayout(
        momentPoints,
        // Momente: puțin mai răsfirate pentru lizibilitatea bulei/caption.
        stepMeters: 17.0,
      );

      for (final m in moments) {
        if (m.isExpired) continue;
        final symbol = _symbolForMapMoment(m);
        final caption = _mapMomentCaptionBubble(m);
        final png = await _MapSocialMethods._generateMapMomentBubblePng(symbol);
        final p = momentStairById[m.id] ??
            (lat: m.lat, lng: m.lng);
        final geom = MapboxUtils.createPoint(p.lat, p.lng);

        if (_momentAnnotations.containsKey(m.id)) {
          try {
            final ann = _momentAnnotations[m.id]!;
            await _momentAnnotationManager?.update(
              ann
                ..geometry = geom
                ..iconImage = 'nabour_moment_${m.id}'
                ..iconSize = momentIconSize
                ..iconAnchor = IconAnchor.CENTER
                ..textField = caption
                ..textSize = 10.0
                ..textOffset = momentTextOffset
                ..textColor = momentTextColor
                ..textHaloColor = 0xFFFFFFFF
                ..textHaloWidth = 2.0,
            );
          } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          continue;
        }
        final momentImageName = 'nabour_moment_${m.id}';
        final momentImgOk = _mapboxMap != null && await _registerStyleImageFromPng(momentImageName, png);
        final options = PointAnnotationOptions(
          geometry: geom,
          iconImage: momentImgOk ? momentImageName : null,
          iconSize: momentIconSize,
          iconAnchor: IconAnchor.CENTER,
          textField: caption,
          textSize: 10.0,
          textOffset: momentTextOffset,
          textColor: momentTextColor,
          textHaloColor: 0xFFFFFFFF,
          textHaloWidth: 2.0,
        );
        final ann = await _momentAnnotationManager?.create(options);
        if (ann != null) {
          _momentAnnotations[m.id] = ann;
          _momentAnnotationIdToMomentId[ann.id] = m.id;
        }
      }
    } catch (e, st) {
      Logger.error(
        'Update moment markers failed: $e',
        error: e,
        stackTrace: st,
        tag: 'MOMENTS',
      );
      _momentAnnotationManager = null;
      _momentAnnotations.clear();
      _momentAnnotationIdToMomentId.clear();
    }
  }

  void _initHonkListener() {
    _honkSubscription?.cancel();
    _honkSubscription = VirtualHonkService().listenForHonks().listen(
      (honk) {
        if (honk.isNotEmpty && mounted) {
          _handleIncomingHonk(honk);
        }
      },
      onError: (Object e, StackTrace st) {
        // RTDB Permission denied fără onError → uncaught async error (oprire în sky_engine errors.dart)
        Logger.error(
          'Honk RTDB stream error (e.g. rules): $e',
          error: e,
          stackTrace: st,
          tag: 'HONK',
        );
      },
    );
  }

  Future<void> _handleIncomingHonk(Map<String, dynamic> data) async {
    final senderName = data['senderName'] ?? 'Vecin';
    final senderUid = data['senderUid'];

    // 1. Play sound
    await _audioService.playHonkSound();

    // 2. Show brief notification
    if (mounted) {
      _showSafeSnackBar(AppLocalizations.of(context)!.mapHonkReceived(senderName), const Color(0xFF7C3AED));
    }

    // 3. Show emoji above sender car on map (if visible)
    if (senderUid != null && _neighborAnnotations.containsKey(senderUid)) {
      final ann = _neighborAnnotations[senderUid]!;
      final originalText = ann.textField;
      
      try {
        // Temporarily change icon to a big emoji
        await _neighborsAnnotationManager?.update(ann..textField = '📢👋'..textSize = 28.0);
        
        Future.delayed(const Duration(seconds: 3), () async {
          if (mounted && _neighborAnnotations.containsKey(senderUid)) {
             await _neighborsAnnotationManager?.update(ann..textField = originalText..textSize = 11.0);
          }
        });
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }
  }

  /// Reîncarcă PNG-ul pentru **slotul** potrivit modului ales în UI: șofer = garaj șofer, pasager = garaj pasager.
  /// (Disponibilitatea șoferului influențează doar puck-ul / telemetria, nu ce vehicul ai setat în Galaxy Garage.)
  ///
  /// [optimisticAvatarIdForActiveSlot] — după garaj: aplică imediat ID-ul salvat, fără să așteptăm
  /// eventual consistency la citirea Firestore (evită marker vechi până la repornire).
  CarAvatarMapSlot get _garageSlotForCurrentMode =>
      _currentRole == UserRole.driver
          ? CarAvatarMapSlot.driver
          : CarAvatarMapSlot.passenger;

  /// Cont șofer cu profil complet **și** mod șofer în UI — singurii care pot vedea vehicule (transport) pe propriul marker.
  bool get _mapShowsDriverTransportIdentity =>
      _isDriverAccountVerified && _currentRole == UserRole.driver;

  /// PNG Galaxy Garage pentru [markerul propriu]: transport doar dacă [_mapShowsDriverTransportIdentity];
  /// altfel doar slot pasager (animale / personaje). `null` = berlină implicită (doar șoferi) sau puck (doar pasageri).
  String? get _garageAssetPathForCurrentRole =>
      _mapShowsDriverTransportIdentity
          ? _garageAssetPathForDriverSlot
          : _garageAssetPathForPassengerSlot;

  CarAvatar? _getCurrentAvatarObject() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final avatarId = _currentRole == UserRole.driver
        ? _garageAvatarIdForDriverSlot
        : _garageAvatarIdForPassengerSlot;
    return CarAvatarService().getAvatarById(avatarId);
  }

  Future<bool> _enable3DUserModel(String modelPath) async {
    if (_mapboxMap == null || !mounted) return false;
    try {
      // Trebuie `asset://…` / `https://…` aici: [LocationComponentSettings.updateSettings] din SDK
      // rescrie doar modelUri-ul puck-ului prin getFlutterAssetPath (asset → flutter_assets).
      // [addStyleModel] NU face aceeași rescriere → pe Android „Could not read asset” pentru același path.
      final String uri = modelPath.startsWith('http') ? modelPath : 'asset://$modelPath';
      final now = DateTime.now();
      if (_suspend3DUntil != null && now.isBefore(_suspend3DUntil!)) {
        return false;
      }
      if (_isUsing3DUserModel &&
          _last3dPuckModelUri == uri &&
          _last3dPuckApplyAt != null &&
          now.difference(_last3dPuckApplyAt!) < const Duration(seconds: 4)) {
        return true;
      }
      // Înainte de orice await — dacă nu mai e primul „enable”, tot reaplicăm setările native.
      final bool firstTimeEntering3dMode = !_isUsing3DUserModel;

      double modelScale = 28.0;
      if (modelPath.contains('robo_3d')) {
        modelScale = 14.0;
      } else if (modelPath.contains('inspiration-8') || modelPath.contains('inspiration-4')) {
        modelScale = 8.0;
      }

      // Reaplică MEREU LocationComponent pentru puck 3D. După [flyTo] / animații cameră, stratul nativ
      // poate fi resetat chiar dacă [_isUsing3DUserModel] rămâne true — vechiul `if (!3d)` bloca retransmiterea.
      // LocationComponentSettings: [puckBearingEnabled] + [puckBearing] (mapbox_maps_flutter).
      await _mapboxMap!.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: false,
          puckBearingEnabled: false,
          locationPuck: LocationPuck(
            locationPuck3D: LocationPuck3D(
              modelUri: uri,
              modelScale: [modelScale, modelScale, modelScale],
              modelRotation: [0.0, 0.0, 0.0],
            ),
          ),
        ),
      );
      final hasModelSource =
          await _mapboxMap!.style.styleSourceExists('mapbox-location-model-source');
      if (!hasModelSource) {
        // Retry scurt: pe unele dispozitive sursa apare cu întârziere după updateSettings.
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted || _mapboxMap == null) return false;
        final retryCheck =
            await _mapboxMap!.style.styleSourceExists('mapbox-location-model-source');
        if (!retryCheck) {
          _consecutive3DSourceMisses++;
          if (_consecutive3DSourceMisses >= _MapScreenState._k3DSourceMissesBeforeCooldown) {
            _suspend3DUntil = DateTime.now().add(_MapScreenState._k3DSourceMissingCooldown);
            Logger.warning(
              '3D source missing repeatedly; cooldown activat',
              tag: 'MAP_3D',
            );
          }
          if (mounted && _isUsing3DUserModel) {
            setState(() => _isUsing3DUserModel = false);
          }
          Logger.warning(
            '3D fallback to 2D: mapbox-location-model-source missing after updateSettings',
            tag: 'MAP_3D',
          );
          return false;
        }
      }

      // Pitch doar la prima intrare în mod 3D (nu la fiecare reaplicare după fly).
      if (firstTimeEntering3dMode && mounted) {
        try {
          final cam = await _mapboxMap!.getCameraState();
          await _mapboxMap!.setCamera(
            CameraOptions(
              center: cam.center,
              zoom: cam.zoom,
              bearing: cam.bearing,
              pitch: 0.0,
            ),
          );
        } catch (_) {
          await _mapboxMap?.setCamera(CameraOptions(pitch: 0.0));
        }
      }

      if (mounted) {
        setState(() => _isUsing3DUserModel = true);
      }
      _consecutive3DSourceMisses = 0;
      _suspend3DUntil = null;
      _last3dPuckModelUri = uri;
      _last3dPuckApplyAt = DateTime.now();
      Logger.info(
        '${firstTimeEntering3dMode ? '3D model enabled' : '3D location puck reapplied'}: $uri',
        tag: 'MAP_3D',
      );
      _schedule3DSourceStabilityProbe();
      return true;
    } catch (e) {
      Logger.error('Error enabling 3D model: $e', tag: 'MAP_3D');
      return false;
    }
  }

  Future<void> _disable3DUserModel() async {
    if (!_isUsing3DUserModel || _mapboxMap == null) return;
    try {
      _last3dPuckModelUri = null;
      _last3dPuckApplyAt = null;
      // Resetăm flag-ul înainte de a apela _updateLocationPuck, altfel acesta ar putea returna anticipat.
      if (mounted) {
        setState(() {
          _isUsing3DUserModel = false;
        });
      }
      _userMarkerVisualCacheKey = null;
      _puck2DAvatarBytes = null; // forțează regenerare avatar la revenire pe 2D
      _puck2DLabelBytes = null;  // forțează regenerare imagine compozită la revenire pe 2D
      _puck2DLabelCacheKey = null;
      await _updateLocationPuck();
    } catch (e) {
      Logger.debug('Error disabling 3D model: $e');
    }
  }

  void _schedule3DSourceStabilityProbe() {
    // Unele device-uri raportează sursa validă imediat după enable, apoi aceasta cade după 3-7 sec.
    // Verificăm stabilitatea în mai multe puncte, nu doar la ~1 secundă.
    final probeMoments = <Duration>[
      _MapScreenState._k3DPostEnableStabilityProbeDelay,
      const Duration(seconds: 3),
      const Duration(seconds: 6),
    ];
    for (final delay in probeMoments) {
      Future<void>.delayed(delay, () async {
        if (!mounted || _mapboxMap == null || !_isUsing3DUserModel) return;
        try {
          final stillPresent =
              await _mapboxMap!.style.styleSourceExists('mapbox-location-model-source');
          if (stillPresent) return;

          _consecutive3DSourceMisses++;
          if (_consecutive3DSourceMisses >= _MapScreenState._k3DSourceMissesBeforeCooldown) {
            _suspend3DUntil = DateTime.now().add(_MapScreenState._k3DSourceMissingCooldown);
          }

          Logger.warning(
            '3D source unstable after enable (probe ${delay.inMilliseconds}ms); forced fallback to 2D',
            tag: 'MAP_3D',
          );
          await _disable3DUserModel();
          _clearGpsUserMarkerThrottle();
          await _updateUserMarker(centerCamera: false);
        } catch (e) {
          Logger.debug('3D stability probe error: $e', tag: 'MAP_3D');
        }
      });
    }
  }

  bool _compute3DZoomGate(double zoom) {
    if (_is3DZoomGateOpen) {
      if (zoom < _MapScreenState._kMapUser3dZoomExitThreshold) {
        _is3DZoomGateOpen = false;
      }
    } else if (zoom >= _MapScreenState._kMapUser3dZoomEnterThreshold) {
      _is3DZoomGateOpen = true;
    }
    return _is3DZoomGateOpen;
  }

  /// Pasager (sau cont fără profil șofer valid) fără skin de pasager deblocat → fără bitmap transport; Location Puck.
  bool get _usePassengerMapPuckOnly =>
      !_mapShowsDriverTransportIdentity &&
      (_garageAssetPathForPassengerSlot == null ||
          _garageAssetPathForPassengerSlot!.isEmpty);

  /// Șofer cu „Disponibil” — folosește vehicul din garaj sau berlina implicită.
  bool get _driverOnDutyOnMap =>
      _currentRole == UserRole.driver && _isDriverAvailable;

  String _ownUserMarkerVisualKey() {
    if (_usePassengerMapPuckOnly) {
      return 'self:location_puck|role:${_currentRole.name}';
    }
    if (_mapShowsDriverTransportIdentity) {
      final g = _garageAssetPathForDriverSlot;
      if (g != null && g.isNotEmpty) {
        return 'garage:$g|duty:$_driverOnDutyOnMap|role:${_currentRole.name}';
      }
      return 'self:berlina|duty:$_driverOnDutyOnMap|role:${_currentRole.name}';
    }
    final p = _garageAssetPathForPassengerSlot;
    if (p != null && p.isNotEmpty) {
      return 'garage:$p|passengerSkin|role:${_currentRole.name}';
    }
    return 'self:location_puck|role:${_currentRole.name}';
  }

  /// Ids rezolvate (șofer|pasager) din documentul `users`, aliniate la [CarAvatarService.resolveSlotId].
  String _garageSlotIdsSigFromProfile(Map<String, dynamic>? data) {
    if (data == null) return '';
    final d = CarAvatarService.resolveSlotId(data, CarAvatarMapSlot.driver);
    final p = CarAvatarService.resolveSlotId(data, CarAvatarMapSlot.passenger);
    return '$d|$p';
  }

  Future<void> _loadCustomCarAvatar({
    String? optimisticAvatarIdForActiveSlot,
    bool nukeMarkerFirst = true,
  }) async {
    try {
      if (nukeMarkerFirst) {
        _forceUserCarMarkerFullRebuild = true;
        // Evită ca o generare PNG în curs pentru asset-ul vechi să fie refolosită (??=) la path nou.
        _userDriverMarkerIconInFlight = null;
      }
      final svc = CarAvatarService();
      late final String passengerAvatarId;
      late final String driverAvatarId;
      if (optimisticAvatarIdForActiveSlot != null) {
        final passiveSlot = _garageSlotForCurrentMode == CarAvatarMapSlot.driver
            ? CarAvatarMapSlot.passenger
            : CarAvatarMapSlot.driver;
        final passiveId = await svc.getSelectedAvatarIdForSlot(passiveSlot);
        if (_garageSlotForCurrentMode == CarAvatarMapSlot.driver) {
          driverAvatarId = optimisticAvatarIdForActiveSlot;
          passengerAvatarId = passiveId;
        } else {
          passengerAvatarId = optimisticAvatarIdForActiveSlot;
          driverAvatarId = passiveId;
        }
      } else {
        passengerAvatarId =
            await svc.getSelectedAvatarIdForSlot(CarAvatarMapSlot.passenger);
        driverAvatarId =
            await svc.getSelectedAvatarIdForSlot(CarAvatarMapSlot.driver);
      }
      final pAv = svc.getAvatarById(passengerAvatarId);
      final dAv = svc.getAvatarById(driverAvatarId);
      if (mounted) {
        setState(() {
          _garageAvatarIdForPassengerSlot = passengerAvatarId;
          _garageAvatarIdForDriverSlot = driverAvatarId;
          _garageAssetPathForPassengerSlot =
              pAv.isDefault ? null : pAv.assetPath;
          _garageAssetPathForDriverSlot = dAv.isDefault ? null : dAv.assetPath;
          _MapInitMethods._staticMarkerIconCache.clear();
        });
        if (_mapboxMap != null) {
          // Pauză scurtă după sheet + deleteAll nativ, ca create să nu lovească încă stări intermediare Mapbox.
          await Future<void>.delayed(const Duration(milliseconds: 32));
          if (!mounted) return;
          _clearGpsUserMarkerThrottle();
          await _updateUserMarker(centerCamera: false);
          if (mounted) unawaited(_updateLocationPuck());
        }
        if (_wantsNeighborSocialPublish && _currentPositionObject != null) {
          _publishNeighborSocialMapFreshUnawaited(
            _currentPositionObject!,
            forceNeighborTelemetry: true,
          );
        }
        if (_currentRole == UserRole.driver &&
            _isDriverAvailable &&
            _isVisibleToNeighbors) {
          unawaited(_firestoreService.refreshDriverLocationAvatarNow());
        }
      }
    } catch (e, st) {
      Logger.error(
        '_loadCustomCarAvatar failed: $e',
        error: e,
        stackTrace: st,
        tag: 'MAP',
      );
    }
  }

  /// Curăță overlay-uri „stale” (vecini, dedupe proximitate) și resincronizează markerele vecinilor.
  void _sweepStaleMapOverlayState() {
    if (!mounted) return;
    _proximityNotifResetTime = DateTime.now();
    _proximitNotifiedUids.clear();
    _recentlyBumpedUids.clear();
    _friendsTogetherHintPairs.clear();
    _pruneStaleNeighborSnapshots();
    _mergeNeighborStreamsAndUpdateAnnotations();
  }

  /// Reîncarcă markerul propriu și stilul de mașină din profil (fără restart) — util dacă Mapbox rămâne desincronizat.
  Future<void> _softRefreshMapDisplay() async {
    if (!mounted) return;
    if (_mapboxMap == null && _osmMapController == null) return;

    try {
      await _loadCustomCarAvatar();
      await _syncMapOrientationPinAnnotation();
      _sweepStaleMapOverlayState();
      _restartNearbyDriversStream();
      
      // Forțează reîncărcarea cererilor din zonă
      _lastRequestsRefreshAt = null;
      _lastRequestsRefreshLat = null;
      _lastRequestsRefreshLng = null;
      _refreshNeighborhoodRequestBubbles();

      // Recentrează camera pe locația curentă a utilizatorului
      final pos = _currentPositionObject;
      if (pos != null) {
        final targetLat = pos.latitude;
        final targetLng = pos.longitude;
        const targetZoom = 15.5;

        // Mapbox Move
        if (_mapboxMap != null) {
          unawaited(_mapboxMap!.flyTo(
            CameraOptions(
              center: MapboxUtils.createPoint(targetLat, targetLng),
              zoom: targetZoom,
              bearing: 0,
              pitch: 0,
            ),
            MapAnimationOptions(duration: 800),
          ));
        }

        // OSM Move
        if (_osmMapController != null) {
          _animatedMoveOsm(
            ll.LatLng(targetLat, targetLng),
            targetZoom,
          );
        }
      }
    } catch (e, st) {
      Logger.error(
        'Reîmprospătare hartă: $e',
        error: e,
        stackTrace: st,
        tag: 'MAP',
      );
    }
  }

  GeoPoint? _parseMapOrientationPin(Map<String, dynamic>? data) {
    if (data == null) return null;
    final v = data['mapOrientationPin'];
    if (v is GeoPoint) return v;
    if (v is Map) {
      final lat = (v['latitude'] ?? v['lat']) as num?;
      final lng = (v['longitude'] ?? v['lng']) as num?;
      if (lat != null && lng != null) {
        return GeoPoint(lat.toDouble(), lng.toDouble());
      }
    }
    return null;
  }

  String? _parseMapOrientationPinLabel(Map<String, dynamic>? data) {
    if (data == null) return null;
    final v = data['mapOrientationPinLabel'];
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  /// Etichetă pe hartă / căutare (fallback dacă documentul vechi nu are câmp).
  String _effectiveOrientationPinLabelForMap() {
    final t = _manualOrientationPinLabel?.trim();
    if (t != null && t.isNotEmpty) return t;
    return 'Reper orientare';
  }

  String _orientationPinLabelForMapAnnotation() {
    final s = _effectiveOrientationPinLabelForMap();
    if (s.length <= 30) return s;
    return '${s.substring(0, 27)}…';
  }

  Future<String?> _promptOrientationPinName({
    required String title,
    String initialName = '',
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final ctl = TextEditingController(text: initialName);
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctl,
          decoration: InputDecoration(
            labelText: l10n.mapPinNameLabel,
            hintText: l10n.mapPinNameHint,
          ),
          autofocus: true,
          maxLength: 48,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final t = ctl.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(ctx, t);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    ctl.dispose();
    return result;
  }

  bool _parseShowSavedHomePinOnMap(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data['showSavedHomePinOnMap'] == true;
  }

  /// Etichete echivalente cu „Acasă” (Firestore / UI pot folosi diacritice diferite sau EN).
  static bool _labelMeansHomeSaved(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return false;
    final ascii = t
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ș', 's')
        .replaceAll('ț', 't');
    return t == 'acasă' ||
        ascii == 'acasa' ||
        t == 'home' ||
        ascii == 'home' ||
        t == '🏠';
  }

  SavedAddress? _savedHomeAddressEntry() {
    for (final a in _savedAddressesForHomePin) {
      if (a.isHomeCategory || _labelMeansHomeSaved(a.label)) return a;
    }
    return null;
  }

  bool _coordsPlausibleForSavedAddress(GeoPoint p) {
    if (p.latitude == 0 && p.longitude == 0) return false;
    return p.latitude.abs() <= 90 && p.longitude.abs() <= 180;
  }

  /// Coordonate pin „Acasă” (favorite) când afișarea e activă — **independent** de reperul manual.
  GeoPoint? _savedHomePinCoordsIfVisible() {
    if (!_showSavedHomePinOnMap) return null;
    final h = _savedHomeAddressEntry();
    if (h != null && _coordsPlausibleForSavedAddress(h.coordinates)) {
      return h.coordinates;
    }
    return null;
  }

  static const List<String> _kSavedHomeFavoritePinAssets = [
    'assets/images/home_pin_v2.png',
    'assets/images/home_pin.png',
    'assets/images/home_pinv2.png',
  ];

  /// Bitmap pin Acasă (favorite): casă în glob (asset PNG).
  Future<Uint8List> _loadSavedHomeFavoritePinBytes() async {
    for (final path in _kSavedHomeFavoritePinAssets) {
      try {
        final bd = await rootBundle.load(path);
        return bd.buffer.asUint8List();
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }
    Logger.warning(
      'Lipsește PNG Acasă favorite — folosesc pictogramă generată (casă în glob).',
      tag: 'MAP_HOME',
    );
    return _generateSavedHomeGlassHouseFallbackPinBytes();
  }

  /// Bitmap reper orientare: ac cu gamalie verde (aceeași suprafață 48×56).
  Future<Uint8List> _loadOrientationReperPinBytes() async {
    return _generateOrientationCompassNeedlePinBytes();
  }

  /// Sincronizează **două** markere independente: Acasă (favorite) și reper (ac compas).
  Future<void> _syncMapOrientationPinAnnotation() async {
    if (!mounted || _mapboxMap == null) {
      return;
    }
    final previous = _homePinUpdateChain;
    final done = Completer<void>();
    _homePinUpdateChain = done.future;

    try {
      await previous;
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }

    // Re-verifică după await: la comutare rapidă OSM↔Mapbox, _mapboxMap poate fi
    // deja null (set de _onOsmMapCreated) → NullPointerException neprins = crash.
    if (!mounted || _mapboxMap == null) {
      done.complete();
      return;
    }

    try {
      GeoPoint? homeGp = _savedHomePinCoordsIfVisible();
      GeoPoint? reperGp = _manualOrientationPin;

      if (homeGp == null &&
          reperGp == null &&
          _showSavedHomePinOnMap &&
          !_savedAddressesFirestoreHydrated) {
        Logger.debug(
          'Private pins: skip clear until saved_addresses first snapshot',
          tag: 'MAP_HOME',
        );
        done.complete();
        return;
      }

      if (homeGp == null && reperGp == null) {
        try {
          await _savedHomeFavoritePinManager?.deleteAll();
        } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
        try {
          await _orientationReperPinManager?.deleteAll();
        } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
        if (_useAndroidFlutterUserMarkerOverlay && mounted) {
          setState(_clearAndroidPrivatePinOverlayFields);
        } else {
          _clearAndroidPrivatePinOverlayFields();
        }
        done.complete();
        return;
      }

      // Mică separare pe hartă dacă ambele puncte coincid (evită suprapunere perfectă).
      if (homeGp != null &&
          reperGp != null &&
          homeGp.latitude == reperGp.latitude &&
          homeGp.longitude == reperGp.longitude) {
        reperGp = GeoPoint(
          reperGp.latitude + 0.00006,
          reperGp.longitude + 0.00006,
        );
      }

      final homeBytes = await _loadSavedHomeFavoritePinBytes();
      final reperBytes = await _loadOrientationReperPinBytes();

      Point? homeGeom;
      Point? reperGeom;
      if (homeGp != null) {
        var hLat = homeGp.latitude;
        var hLng = homeGp.longitude;
        final cur = _currentPositionObject;
        if (cur != null) {
          final dist = geolocator.Geolocator.distanceBetween(
            hLat, hLng, cur.latitude, cur.longitude,
          );
          if (dist < 10) {
            hLat += 0.00006;
          }
        }
        homeGeom = MapboxUtils.createPoint(hLat, hLng);
      }
      if (reperGp != null) {
        var rLat = reperGp.latitude;
        var rLng = reperGp.longitude;
        final cur = _currentPositionObject;
        if (cur != null) {
          final dist = geolocator.Geolocator.distanceBetween(
            rLat, rLng, cur.latitude, cur.longitude,
          );
          if (dist < 10) {
            rLat += 0.00006;
          }
        }
        reperGeom = MapboxUtils.createPoint(rLat, rLng);
      }

      // Pinurile statice (acasă / reper) folosesc întotdeauna PointAnnotation nativ
      // Mapbox — indiferent de platformă — pentru a elimina lag-ul la pan al hărții.
      _clearAndroidPrivatePinOverlayFields();

      _savedHomeFavoritePinManager ??=
          await _mapboxMap!.annotations.createPointAnnotationManager(
        id: 'user-saved-home-favorite-pin-manager',
      );
      _orientationReperPinManager ??=
          await _mapboxMap!.annotations.createPointAnnotationManager(
        id: 'user-orientation-reper-pin-manager',
      );

      if (!_savedHomeFavoritePinTapRegistered) {
        _savedHomeFavoritePinTapRegistered = true;
        _savedHomeFavoritePinManager!.tapEvents(onTap: (_) {
          if (mounted) _showSavedHomeFavoritePinActions();
        });
      }
      if (!_orientationReperPinTapRegistered) {
        _orientationReperPinTapRegistered = true;
        _orientationReperPinManager!.tapEvents(onTap: (_) {
          if (mounted) _showOrientationReperPinActions();
        });
      }

      try {
        await _savedHomeFavoritePinManager?.deleteAll();
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      try {
        await _orientationReperPinManager?.deleteAll();
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }

      if (homeGeom != null && _savedHomeFavoritePinManager != null) {
        const homePinImgName = 'nabour_home_favorite_pin';
        final imgOk = await _registerStyleImageFromPng(homePinImgName, homeBytes);
        
        await _savedHomeFavoritePinManager!.create(
          PointAnnotationOptions(
            geometry: homeGeom,
            iconImage: imgOk ? homePinImgName : null,
            // image: homeBytes, // DO NOT USE - homeBytes is PNG, options.image expects RGBA
            iconSize: 0.55,
            iconAnchor: IconAnchor.BOTTOM,
            symbolSortKey: 2e6,
          ),
        );
      }
      if (reperGeom != null && _orientationReperPinManager != null) {
        const reperPinImgName = 'nabour_orientation_reper_pin';
        final imgOk = await _registerStyleImageFromPng(reperPinImgName, reperBytes);
        
        const reperTextOffset = [0.0, -2.35];
        await _orientationReperPinManager!.create(
          PointAnnotationOptions(
            geometry: reperGeom,
            iconImage: imgOk ? reperPinImgName : null,
              // image: reperBytes, // DO NOT USE
              iconSize: 1.0,
              iconAnchor: IconAnchor.BOTTOM,
              symbolSortKey: 2e6 + 1,
              textField: _orientationPinLabelForMapAnnotation(),
              textSize: 11.5,
              textOffset: reperTextOffset,
              textColor: 0xFF0F172A,
              textHaloColor: 0xFFFFFFFF,
              textHaloWidth: 2.0,
            ),
          );
        }
        Logger.debug(
          'Private pins: synced (home=${homeGeom != null}, reper=${reperGeom != null})',
          tag: 'MAP_HOME',
        );
      } catch (e, st) {
        Logger.error('Private pins sync: $e', tag: 'MAP_HOME', error: e, stackTrace: st);
      } finally {
        if (!done.isCompleted) done.complete();
      }
  }

  void _showMapOrientationPlacementSnackBar(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 96),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.close,
          textColor: const Color(0xFF7DD3FC),
          onPressed: () {
            messenger.hideCurrentSnackBar();
            if (mounted) {
              setState(() => _awaitingMapOrientationPinPlacement = false);
            }
          },
        ),
      ),
    );
  }

  Future<void> _finishMapOrientationPinPlacement(Point point) async {
    final lat = point.coordinates.lat.toDouble();
    final lng = point.coordinates.lng.toDouble();
    if (!mounted) return;
    final name = await _promptOrientationPinName(
      title: AppLocalizations.of(context)!.mapPinNameTitle,
      initialName: _manualOrientationPinLabel ?? '',
    );
    if (!mounted) return;
    if (name == null) {
      setState(() => _awaitingMapOrientationPinPlacement = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      return;
    }
    try {
      await _firestoreService.setMapOrientationPin(lat, lng, label: name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nu s-a putut salva reperul: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _awaitingMapOrientationPinPlacement = false;
      _manualOrientationPin = GeoPoint(lat, lng);
      _manualOrientationPinLabel = name.trim();
    });
    await _syncMapOrientationPinAnnotation();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mapOrientationPinSaved),
          backgroundColor: Color(0xFF166534),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSavedHomeFavoritePinActions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_added_rounded, color: Color(0xFF38BDF8)),
              title: Text(
                l10n.mapEditHomeAddressTitle,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                l10n.mapEditHomeAddressSubtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FavoriteAddressesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.visibility_off_rounded, color: Colors.orange.shade300),
              title: Text(
                l10n.mapHideHomeFromMapTitle,
                style: TextStyle(color: Colors.orange.shade200, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await _firestoreService.setShowSavedHomePinOnMap(false);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString())),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                  return;
                }
                if (!mounted) return;
                setState(() => _showSavedHomePinOnMap = false);
                await _syncMapOrientationPinAnnotation();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.mapHomeNoLongerShown)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOrientationReperPinActions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF38BDF8)),
              title: Text(l10n.mapMoveOrientationMarkerTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(
                _manualOrientationPinLabel != null &&
                        _manualOrientationPinLabel!.trim().isNotEmpty
                    ? l10n.mapMoveOrientationMarkerWithName(_manualOrientationPinLabel!.trim())
                    : l10n.mapMoveOrientationMarkerNoName,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _awaitingMapOrientationPinPlacement = true);
                _showMapOrientationPlacementSnackBar(
                  l10n.mapLongPressForNewMarker,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
              title: Text(
                l10n.mapRemoveOrientationMarkerTitle,
                style: TextStyle(color: Colors.red.shade200, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await _firestoreService.clearMapOrientationPin();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString())),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                  return;
                }
                if (!mounted) return;
                setState(() {
                  _manualOrientationPin = null;
                  _manualOrientationPinLabel = null;
                });
                await _syncMapOrientationPinAnnotation();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.mapMarkerRemoved)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enableSavedHomePinFromDrawer() async {
    final l10n = AppLocalizations.of(context)!;
    final h = _savedHomeAddressEntry();
    if (h == null || !_coordsPlausibleForSavedAddress(h.coordinates)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mapSaveHomeFirst),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    try {
      await _firestoreService.setShowSavedHomePinOnMap(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString())),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _showSavedHomePinOnMap = true);
    Provider.of<MapSettingsProvider>(context, listen: false).setShowHomePinOnMap(true);
    await _syncMapOrientationPinAnnotation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_syncMapOrientationPinAnnotation());
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.mapHomeShownForYou),
        backgroundColor: Color(0xFF166534),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _hideSavedHomePinFromDrawer() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_showSavedHomePinOnMap) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mapHomeNotShown)),
      );
      return;
    }
    try {
      await _firestoreService.setShowSavedHomePinOnMap(false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString())),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _showSavedHomePinOnMap = false);
    Provider.of<MapSettingsProvider>(context, listen: false).setShowHomePinOnMap(false);
    await _syncMapOrientationPinAnnotation();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.mapHomeNoLongerShown)),
    );
  }

  Future<void> _removeOrientationReperFromDrawer() async {
    final l10n = AppLocalizations.of(context)!;
    if (_manualOrientationPin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mapNoOrientationMarker)),
      );
      return;
    }
    try {
      await _firestoreService.clearMapOrientationPin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString())),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _manualOrientationPin = null;
      _manualOrientationPinLabel = null;
    });
    await _syncMapOrientationPinAnnotation();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.mapOrientationMarkerRemovedFromMap)),
    );
  }

}

