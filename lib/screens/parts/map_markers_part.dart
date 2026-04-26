// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapMarkersMethods on _MapScreenState {
  /// Înregistrează o imagine custom în stilul Mapbox (ex. avatar, mașină, pin acasă).
  ///
  /// NOTĂ: mapbox_maps_flutter 2.21.1 folosește BitmapFactory.decodeByteArray pe native,
  /// deci MbxImage.data trebuie să fie bytes PNG (nu RGBA raw).
  Future<bool> _registerStyleImageFromPng(String name, Uint8List pngBytes) async {
    final map = _mapboxMap;
    if (map == null) return false;
    
    // Optimizare: Dacă avem deja imaginea în registru cu aceleași bytes, nu mai facem operația nativă.
    final existing = _nabourStyleImageRegistry[name];
    if (existing != null && _areByteListsEqual(existing, pngBytes)) {
      return true;
    }

    try {
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;

      final style = map.style;
      // Recomandat: remove înainte de add pentru a forța refresh-ul pe unele versiuni de motor.
      try { await style.removeStyleImage(name); } catch (_) {}
      
      await style.addStyleImage(
        name,
        2.0, // Scale pentru ecrane de înaltă rezoluție (Retina/Android high density)
        MbxImage(width: img.width, height: img.height, data: pngBytes),
        false, // sdf
        const [], // stretchX
        const [], // stretchY
        null, // content
      );
      
      _nabourStyleImageRegistry[name] = pngBytes;
      return true;
    } catch (e) {
      Logger.error('Failed to register style image "$name": $e', tag: 'MAP');
      return false;
    }
  }

  bool _areByteListsEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Re-înregistrează toate imaginile din registru după un style-reload (onTrimMemory, schimb temă, etc.)
  Future<void> _reRegisterAllStyleImages() async {
    if (_mapboxMap == null || _nabourStyleImageRegistry.isEmpty) return;
    final entries = Map<String, Uint8List>.from(_nabourStyleImageRegistry);
    for (final entry in entries.entries) {
      try {
        final codec = await ui.instantiateImageCodec(entry.value);
        final frame = await codec.getNextFrame();
        final img = frame.image;
        // Pass PNG bytes directly — native BitmapFactory.decodeByteArray expects PNG/JPEG.
        await _mapboxMap!.style.addStyleImage(
          entry.key, 2.0,
          MbxImage(width: img.width, height: img.height, data: entry.value),
          false, const [], const [], null,
        );
      } catch (_) {}
    }
    Logger.debug('Re-registered ${entries.length} style images after style reload', tag: 'MAP');
  }
  void _resetDriverMarkerInterpolation() {
    _driverMarkerSmoothLat = null;
    _driverMarkerSmoothLng = null;
    _driverMarkerSmoothHeadingDeg = null;
  }

  static double _lerpBearingDegrees(double fromDeg, double toDeg, double t) {
    var delta = (toDeg - fromDeg) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    var r = fromDeg + delta * t;
    r %= 360;
    if (r < 0) r += 360;
    return r;
  }

  bool get _useAndroidFlutterUserMarkerOverlay =>
      defaultTargetPlatform == TargetPlatform.android;

  void _clearAndroidUserMarkerOverlayFields() {
    _puck2DAvatarBytes = null;
    _puck2DLabelBytes = null;
    _puck2DLabelCacheKey = null;
    _androidUserMarkerGeometry = null;
    _androidUserMarkerOverlayPx = null;
    _androidUserMarkerOverlayHeadingDeg = 0;
    _androidUserMarkerOverlayImageBytes = null;
    _androidUserMarkerOverlayLabel = null;
  }

  void _clearAndroidPrivatePinOverlayFields() {
    _androidSavedHomePinGeometry = null;
    _androidSavedHomePinOverlayPx = null;
    _androidSavedHomePinOverlayBytes = null;
    _androidOrientationReperGeometry = null;
    _androidOrientationReperOverlayPx = null;
    _androidOrientationReperOverlayBytes = null;
  }

  Future<void> _projectAndroidPrivatePinOverlays() async {
    if (!_useAndroidFlutterUserMarkerOverlay) return;
    if (!mounted || _mapboxMap == null) return;

    Offset? homePx;
    if (_androidSavedHomePinGeometry != null &&
        _androidSavedHomePinOverlayBytes != null) {
      try {
        final sc = await _mapboxMap!.pixelForCoordinate(_androidSavedHomePinGeometry!);
        if (!mounted) return;
        homePx = Offset(sc.x.toDouble(), sc.y.toDouble());
      } catch (e) {
        Logger.debug('Android Acasă pin overlay project: $e', tag: 'MAP_HOME');
      }
    }

    Offset? reperPx;
    if (_androidOrientationReperGeometry != null &&
        _androidOrientationReperOverlayBytes != null) {
      try {
        final sc =
            await _mapboxMap!.pixelForCoordinate(_androidOrientationReperGeometry!);
        if (!mounted) return;
        reperPx = Offset(sc.x.toDouble(), sc.y.toDouble());
      } catch (e) {
        Logger.debug('Android reper overlay project: $e', tag: 'MAP_HOME');
      }
    }

    if (!mounted) return;
    setState(() {
      if (_androidSavedHomePinGeometry == null ||
          _androidSavedHomePinOverlayBytes == null) {
        _androidSavedHomePinOverlayPx = null;
      } else {
        _androidSavedHomePinOverlayPx = homePx;
      }
      if (_androidOrientationReperGeometry == null ||
          _androidOrientationReperOverlayBytes == null) {
        _androidOrientationReperOverlayPx = null;
      } else {
        _androidOrientationReperOverlayPx = reperPx;
      }
    });
  }

  Future<void> _projectAndroidUserMarkerOverlay() async {
    if (!mounted || _mapboxMap == null) return;
    final g = _androidUserMarkerGeometry;
    // Proiectăm poziția când avem fie imagine Flutter overlay, fie etichetă puck2D.
    if (g == null || (_androidUserMarkerOverlayImageBytes == null && _androidUserMarkerOverlayLabel == null)) {
      if (mounted) setState(() => _androidUserMarkerOverlayPx = null);
      return;
    }
    try {
      final sc = await _mapboxMap!.pixelForCoordinate(g);
      if (!mounted) return;
      setState(() {
        _androidUserMarkerOverlayPx = Offset(sc.x.toDouble(), sc.y.toDouble());
      });
    } catch (e) {
      Logger.debug('User marker overlay project: $e', tag: 'MAP');
    }
  }

  Future<void> _updateUserMarker({bool centerCamera = false}) async {
    final previous = _userMarkerUpdateChain;
    final done = Completer<void>();
    _userMarkerUpdateChain = done.future;
    try {
      if (previous != null) {
        try {
          await previous;
        } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      }
      await _runUserMarkerUpdate(centerCamera: centerCamera);
    } finally {
      if (!done.isCompleted) done.complete();
    }
  }

  Future<void> _runUserMarkerUpdate({bool centerCamera = false}) async {
          if (!mounted) {
      Logger.debug('🔕 Skipping marker update - widget unmounted or navigating');
      return;
    }
    if (!_mapSurfaceSafeForUserMarker) {
      Logger.debug(
        'Skipping marker update — map surface flagged unsafe (e.g. app paused)',
        tag: 'MAP',
      );
      return;
    }
    if (_mapboxMap == null) return;

    final geolocator.Position? markerPos = _positionForUserMapMarker();
    if (markerPos == null) {
      Logger.warning('Skipping marker update - no current or cached position');
      if (_useAndroidFlutterUserMarkerOverlay && mounted) {
        setState(_clearAndroidUserMarkerOverlayFields);
      }
      return;
    }

    // Zoom real din motor (nu doar [_mapZoomLevel] din listener — poate întârzia după flyTo / intro).
    if (_mapboxMap != null) {
      final sync3d = _getCurrentAvatarObject();
      if (sync3d != null && sync3d.is3D) {
        try {
          final cam = await _mapboxMap!.getCameraState();
          if (!mounted) return;
          _mapZoomLevel = cam.zoom.toDouble();
        } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      }
    }

    // ── 3D Model Support ──
    final currentAvatar = _getCurrentAvatarObject();
    final bool canShow3D = currentAvatar != null &&
        currentAvatar.is3D &&
        _compute3DZoomGate(_mapZoomLevel);

    if (canShow3D && currentAvatar.modelPath != null) {
      // 1. Activăm modelul 3D via LocationComponent (care se ocupă de interpolare)
      final enabled3D = await _enable3DUserModel(currentAvatar.modelPath!);
      if (enabled3D) {
        // 2. Doar după confirmarea sursei 3D ascundem markerul 2D.
        if (_userPointAnnotation != null || _androidUserMarkerOverlayImageBytes != null) {
          if (_useAndroidFlutterUserMarkerOverlay) {
            if (mounted) setState(_clearAndroidUserMarkerOverlayFields);
          } else {
            try {
              await _userPointAnnotationManager?.deleteAll();
            } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
            _userPointAnnotation = null;
          }
          _userMarkerVisualCacheKey = null;
        }
        // Nu continuăm cu randarea PointAnnotation (2D) când sursa 3D este validă.
        return;
      }
    } else {
      // Revenim la comportamentul standard 2D
      await _disable3DUserModel();
    }

    // Pasageri / conturi fără profil șofer: doar Location Puck, fără berlină sau slot șofer.
    if (_usePassengerMapPuckOnly) {
      try {
        if (_forceUserCarMarkerFullRebuild) {
          _forceUserCarMarkerFullRebuild = false;
          _userMarkerVisualCacheKey = null;
        }
        if (_useAndroidFlutterUserMarkerOverlay) {
          if (_userPointAnnotationManager != null || _userPointAnnotation != null) {
            try {
              await _userPointAnnotationManager?.deleteAll();
            } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
            _userPointAnnotationManager = null;
            _userPointAnnotation = null;
          }
          if (mounted) setState(_clearAndroidUserMarkerOverlayFields);
        } else {
          try {
            await _userPointAnnotationManager?.deleteAll();
          } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          _userPointAnnotation = null;
        }
        _userMarkerVisualCacheKey = _ownUserMarkerVisualKey();
        _userDriverMarkerIconInFlight = null;
        await _updateLocationPuck();
        if (centerCamera && _mapboxMap != null && mounted) {
          final live = _currentPositionObject;
          final tgtLat = live?.latitude ?? markerPos.latitude;
          final tgtLng = live?.longitude ?? markerPos.longitude;
          await _mapboxMap?.easeTo(
            CameraOptions(
              center: MapboxUtils.createPoint(tgtLat, tgtLng),
              zoom: _overviewZoomForLatitude(tgtLat),
            ),
            MapAnimationOptions(duration: AppDrawer.lowDataMode ? 480 : 920),
          );
        }
      } catch (e) {
        Logger.error('Non-fatal error during puck-only user marker: $e', error: e);
      }
      final pBox = _currentPositionObject ?? markerPos;
      if (_mysteryBoxManager != null) {
        unawaited(_mysteryBoxManager!.updateMysteryBoxes(
          pBox.latitude,
          pBox.longitude,
        ));
      }
      if (_communityMysteryManager != null) {
        unawaited(_communityMysteryManager!.updateBoxes(
          pBox.latitude,
          pBox.longitude,
        ));
      }
      return;
    }

    // ── Curățăm orice PointAnnotation rezidual (migrare de la abordarea veche) ──
    if (_userPointAnnotation != null || _userPointAnnotationManager != null) {
      try {
        await _userPointAnnotationManager?.deleteAll();
      } catch (_) { /* Mapbox op */ }
      _userPointAnnotationManager = null;
      _userPointAnnotation = null;
    }

    try {
      // Ierarhie: garaj (slot potrivit) → berlină doar șoferi validați mod șofer; pasageri fără skin → puck (ramura de mai sus).
      final visualKey = _ownUserMarkerVisualKey();
      final batSnap = await NeighborDeviceTelemetryReader.instance.snapshot();
      final int? userBatLevel = batSnap?.level;
      final bool userBatCharging = batSnap?.isCharging ?? false;
      final batKey =
          NeighborFriendMarkerIcons.batteryBucketForMarker(userBatLevel)?.toString() ??
              'n';
      final userMarkerCacheKey = '$visualKey|b$batKey${userBatCharging ? 'c' : 'n'}';
      final bool isEmojiMode = visualKey.startsWith('passenger:emoji:');
      // Berlina vectorială e desenată cu „botul” spre nord; GPS + iconRotate are sens.
      // Skin-urile PNG din garaj (animale, mașini raster) nu respectă aceeași axă → rămân nord-sus, fără jitter.
      final bool rotateMarkerWithGpsHeading =
          !isEmojiMode && _garageAssetPathForCurrentRole == null;

      final live = _currentPositionObject;
      final tgtLat = live?.latitude ?? markerPos.latitude;
      final tgtLng = live?.longitude ?? markerPos.longitude;

      double rawHeading = 0.0;
      final headingSrc = live ?? markerPos;
      if (!headingSrc.heading.isNaN) {
        rawHeading = headingSrc.heading;
        if (rawHeading < 0) rawHeading += 360;
      }

      final kmh = headingSrc.speed.isNaN ? 0.0 : headingSrc.speed * 3.6;
      final moving = !headingSrc.speed.isNaN &&
          (headingSrc.speed >= 0.35 || kmh >= 12.0);
      // În mers: fără lag de interpolare — același țint ca GPS-ul folosit și de puck (Geolocator).
      final snapToLivePosition = moving;
      final double posLerp =
          snapToLivePosition ? 1.0 : _MapInitMethods._driverMarkerPosLerpSoft;

      _driverMarkerSmoothLat ??= tgtLat;
      _driverMarkerSmoothLng ??= tgtLng;
      if (posLerp >= 1.0) {
        _driverMarkerSmoothLat = tgtLat;
        _driverMarkerSmoothLng = tgtLng;
      } else {
        _driverMarkerSmoothLat = _driverMarkerSmoothLat! +
            (tgtLat - _driverMarkerSmoothLat!) * posLerp;
        _driverMarkerSmoothLng = _driverMarkerSmoothLng! +
            (tgtLng - _driverMarkerSmoothLng!) * posLerp;
      }

      if (rotateMarkerWithGpsHeading) {
        final headingForIcon =
            moving ? rawHeading : (_driverMarkerSmoothHeadingDeg ?? rawHeading);
        _driverMarkerSmoothHeadingDeg ??= headingForIcon;
        if (snapToLivePosition) {
          _driverMarkerSmoothHeadingDeg = headingForIcon;
        } else {
          _driverMarkerSmoothHeadingDeg = _lerpBearingDegrees(
            _driverMarkerSmoothHeadingDeg!,
            headingForIcon,
            0.12,
          );
        }
      } else {
        _driverMarkerSmoothHeadingDeg = null;
      }

      final resolved = _resolvedPlateAndPublicName();
      final driverDuty = _driverOnDutyOnMap;
      String? textField;
      if (driverDuty) {
        if (resolved.plate != null && resolved.name != null) {
          textField = '${resolved.plate}\n${resolved.name}';
        } else if (resolved.plate != null) {
          textField = resolved.plate;
        } else if (resolved.name != null) {
          textField = resolved.name;
        }
      } else if (resolved.name != null) {
        textField = resolved.name;
      }

      if (!mounted) return;

      // ── Generare bytes avatar (cu cache cheie) ─────────────────────────────────────────
      if (_forceUserCarMarkerFullRebuild) {
        _forceUserCarMarkerFullRebuild = false;
        _userMarkerVisualCacheKey = null;
        _puck2DAvatarBytes = null;
        _userDriverMarkerIconInFlight = null;
      }

      if (_userMarkerVisualCacheKey != userMarkerCacheKey || _puck2DAvatarBytes == null) {
        final garagePath = _garageAssetPathForCurrentRole;
        final usePhoto = _useProfilePhotoOnMap && _myProfilePhotoUrl != null;
        final Future<Uint8List> bitmapFuture;
        if (usePhoto) {
          bitmapFuture = _MapInitMethods._generateProfilePhotoMarkerIcon(_myProfilePhotoUrl!).then(
            (bytes) async => bytes ?? await _MapInitMethods._generateMarkerIcon(isPassenger: false),
          );
        } else if (garagePath != null) {
          bitmapFuture = _MapInitMethods._generateMarkerIcon(
            isPassenger: !_driverOnDutyOnMap,
            customAssetPath: garagePath,
            batteryLevel: userBatLevel,
            isCharging: userBatCharging,
          );
        } else {
          bitmapFuture = _MapInitMethods._generateMarkerIcon(
            isPassenger: false,
            customAssetPath: null,
            batteryLevel: userBatLevel,
            isCharging: userBatCharging,
          );
        }

        final gen = _userDriverMarkerIconInFlight ??= bitmapFuture;
        Uint8List imageList;
        try {
          imageList = await gen;
        } catch (e, st) {
          Logger.error(
            'Icon marker utilizator eșuat — fallback vector: $e',
            tag: 'MAP',
            error: e,
            stackTrace: st,
          );
          imageList = await _MapInitMethods._generateMarkerIcon(
            isPassenger: false,
            customAssetPath: null,
            batteryLevel: userBatLevel,
            isCharging: userBatCharging,
          );
        } finally {
          if (identical(_userDriverMarkerIconInFlight, gen)) {
            _userDriverMarkerIconInFlight = null;
          }
        }

        if (!mounted) return;
        _puck2DAvatarBytes = imageList;
        _puck2DLabelBytes = null;    // invalidate composite when avatar changes
        _puck2DLabelCacheKey = null; // force composite rebuild
        _userMarkerVisualCacheKey = userMarkerCacheKey;
        Logger.info(
          'Puck2D avatar updated: visualKey=$visualKey bytes=${imageList.length}',
          tag: 'MAP',
        );
      }

      // ── Aplicăm avatarul pe LocationPuck2D (interpolare nativă Mapbox, fără lag) ──────
      await _updateLocationPuck();

      // ── Generare imagine etichetă (topImage, non-rotativă) — rebuild doar la schimbare text ──
      // Dimensionare: transparent în zona avatarului, chip cu text apare sub avatar.
      // Caractere: bitmap 380px → canvas 380px (×1.5 composite)
      // Garaj non-caracter: 256px × 1.72 iconSize vecini → 440px canvas propriu (293 × 1.5)
      // Emoji/default: 240px × 1.55 iconSize vecini → 372px canvas propriu (248 × 1.5)
      final bool isCharAvatar = CarAvatarService.isCharacterAssetPath(_garageAssetPathForCurrentRole);
      final double avatarSize = isCharAvatar ? 380.0 : (_garageAssetPathForCurrentRole != null ? 293.0 : 248.0);
      if (_puck2DLabelCacheKey != textField) {
        _puck2DLabelCacheKey = textField;
        // Apelăm întotdeauna _compositeAvatarWithLabel: funcția aplică elongarea
        // verticală ×1.65 chiar și fără text, compensând squishing-ul MapBox.
        _puck2DLabelBytes = await _MapInitMethods._compositeAvatarWithLabel(
          avatarBytes: _puck2DAvatarBytes!,
          labelText: textField,
          avatarSize: avatarSize,
        );
        // Re-aplicăm puck-ul cu imaginea compozită.
        await _updateLocationPuck();
      }

      // Anulăm orice overlay Flutter rezidual (nu mai avem nevoie de proiecție pixel).
      if (_androidUserMarkerGeometry != null || _androidUserMarkerOverlayLabel != null) {
        _androidUserMarkerGeometry = null;
        _androidUserMarkerOverlayLabel = null;
        if (mounted) setState(() => _androidUserMarkerOverlayPx = null);
      }

      Logger.debug(
        'Puck2D marker OK: lat=${(_driverMarkerSmoothLat ?? tgtLat).toStringAsFixed(6)} '
        'lng=${(_driverMarkerSmoothLng ?? tgtLng).toStringAsFixed(6)} '
        'visualKey=$visualKey label=$textField',
        tag: 'MAP',
      );

      if (centerCamera && _mapboxMap != null && mounted) {
        await _mapboxMap?.easeTo(
          CameraOptions(
            center: MapboxUtils.createPoint(tgtLat, tgtLng),
            zoom: _overviewZoomForLatitude(tgtLat),
          ),
          MapAnimationOptions(duration: AppDrawer.lowDataMode ? 480 : 920),
        );
        
        // ✅ ACTUALIZARE AUTOMATĂ POI-uri la schimbarea locației
        // (POI auto-update este dezactivat; se afișează doar POI-ul selectat)
      }
    } catch (e) {
      Logger.error('Non-fatal error during _runUserMarkerUpdate: $e', error: e);
    }

    final pBox = _currentPositionObject ?? markerPos;
    if (_mysteryBoxManager != null) {
      unawaited(_mysteryBoxManager!.updateMysteryBoxes(
        pBox.latitude,
        pBox.longitude,
      ));
    }
    if (_communityMysteryManager != null) {
      unawaited(_communityMysteryManager!.updateBoxes(
        pBox.latitude,
        pBox.longitude,
      ));
    }
  }

  /// Ultima poziție utilă pentru desenarea markerului (GPS curent sau cache recent).
  geolocator.Position? _positionForUserMapMarker() {
    final cur = _currentPositionObject;
    if (cur != null) return cur;
    return LocationCacheService.instance.peekRecent(
      maxAge: const Duration(minutes: 45),
    );
  }

  /// Updates the Mapbox LocationPuck behavior.
  /// Când avem [_puck2DAvatarBytes], avatarul e aplicat direct pe puck (interpolare nativă Mapbox).
  /// Altfel: puck de rezervă cu pulsare sau dezactivat.
  Future<void> _updateLocationPuck() async {
    if (_mapboxMap == null || _isUsing3DUserModel) return;
    try {
      final pos = _positionForUserMapMarker();
      final canDrawCustom =
          _mapSurfaceSafeForUserMarker && pos != null;
      final puckOnlyPassenger = _usePassengerMapPuckOnly;

      // ── Ramura primară: avatar 2D direct pe puck ──────────────────────────────────────
      // Condiție: avem bytes avatar, harta e sigură, nu suntem în modul pasager-puck-only.
      if (canDrawCustom && !puckOnlyPassenger && _puck2DAvatarBytes != null) {
        await _mapboxMap!.location.updateSettings(
          LocationComponentSettings(
            enabled: true,
            pulsingEnabled: false,
            puckBearingEnabled: false,
            locationPuck: LocationPuck(
              locationPuck2D: LocationPuck2D(
                // bearingImage se rotește cu bearing-ul — folosim topImage pentru afișare fixă
                topImage: _puck2DLabelBytes ?? _puck2DAvatarBytes,
                bearingImage: null,
                shadowImage: null,
              ),
            ),
          ),
        );
        final posKey = '${pos.latitude.toStringAsFixed(5)},${pos.longitude.toStringAsFixed(5)}';
        if (_shouldLogPuckInfo(enabled: true, posKey: 'puck2D|$posKey')) {
          Logger.debug(
            'LocationPuck2D avatar ON: pos=${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)} bytes=${_puck2DAvatarBytes!.length}',
            tag: 'MAP',
          );
        }
        return;
      }

      // ── Fallback: avatar bytes nu sunt încă gata (generare în curs sau după 3D→2D reset) ──
      // Afișăm puck cu pulsare ca placeholder vizual; _runUserMarkerUpdate va apela din nou
      // _updateLocationPuck() cu _puck2DAvatarBytes != null imediat ce generarea se termină.
      if (canDrawCustom) {
        await _mapboxMap!.location.updateSettings(
          LocationComponentSettings(
            enabled: true,
            pulsingEnabled: true,
            pulsingMaxRadius: 60.0,
            pulsingColor: const Color(0xFF3682F3).toARGB32(),
          ),
        );
        final posKey = '${pos.latitude.toStringAsFixed(5)},${pos.longitude.toStringAsFixed(5)}';
        if (_shouldLogPuckInfo(enabled: true, posKey: 'placeholder|$posKey')) {
          Logger.debug(
            'Location puck placeholder (avatar bytes pending): '
            'pos=${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}',
            tag: 'MAP',
          );
        }
      } else {
        await _mapboxMap!.location.updateSettings(
          LocationComponentSettings(enabled: false),
        );
        if (_shouldLogPuckInfo(enabled: false, posKey: 'no-pos')) {
          Logger.debug('Location puck OFF: no position or unsafe surface', tag: 'MAP');
        }
      }
    } catch (e) {
      Logger.warning('Could not update location puck: $e', tag: 'MAP');
    }
  }

  /// Bitmap marker pentru șoferii din `driver_locations`.
  /// Preferă `carAvatarId` din documentul de locație; fallback la profilul `users/{uid}`.
  Future<Uint8List> _nearbyDriverMarkerPngForUid(
    String uid, {
    String? locationCarAvatarId,
  }) async {
    final normalizedLocationAvatarId = (locationCarAvatarId ?? '').trim();
    final cacheKey = normalizedLocationAvatarId.isNotEmpty
        ? '$uid:$normalizedLocationAvatarId'
        : uid;
    final cached = _nearbyDriverMarkerIconBytesCache[cacheKey];
    if (cached != null) return cached;
    var inflight = _nearbyDriverMarkerIconLoads[cacheKey];
    if (inflight != null) return inflight;

    inflight = () async {
      try {
        if (normalizedLocationAvatarId.isNotEmpty) {
          final coerceId =
              CarAvatarService.coerceDriverAvatarIdForMap(normalizedLocationAvatarId);
          final bytes = await DriverIconHelper.getDriverMarkerBytesForUserProfile(
            <String, dynamic>{CarAvatarService.kFieldDriver: coerceId},
          );
          if (mounted) {
            _nearbyDriverMarkerIconBytesCache[cacheKey] = bytes;
          }
          return bytes;
        }

        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final bytes = await DriverIconHelper.getDriverMarkerBytesForUserProfile(
          doc.data(),
        );
        if (mounted) {
          _nearbyDriverMarkerIconBytesCache[cacheKey] = bytes;
        }
        return bytes;
      } catch (e) {
        Logger.warning(
          'Nearby driver marker: profil indisponibil pentru $uid: $e',
          tag: 'MAP',
        );
        return _MapInitMethods._generateMarkerIcon(isPassenger: false);
      } finally {
        _nearbyDriverMarkerIconLoads.remove(cacheKey);
      }
    }();
    _nearbyDriverMarkerIconLoads[cacheKey] = inflight;
    return inflight;
  }

  Future<void> _updateNearbyDrivers(List<QueryDocumentSnapshot<Map<String, dynamic>>> driverDocs) async {
    if (!mounted) return;
    // ✅ LOCK: Prevenim crearea a doi manageri simultan (cauza dublurilor)
    if (_driversAnnotationManager == null) {
      if (_isCreatingDriversManager) return;
      _isCreatingDriversManager = true;
      try {
        _driversAnnotationManager ??= await _mapboxMap?.annotations.createPointAnnotationManager(
          id: 'nearby-drivers-annotation-manager',
        );
        _registerDriversAnnotationTapHandler();
      } catch (e) {
        Logger.error('Failed to create drivers manager: $e');
      } finally {
        _isCreatingDriversManager = false;
      }
    }
    if (_driversAnnotationManager == null) return;

    try {
      _lastNearbyDriverDocs
        ..clear()
        ..addAll(driverDocs);

      final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
      final idsWithDriverMarker = <String>{};
      for (final doc in driverDocs) {
        if (currentUid != null && doc.id == currentUid) continue;
        if (_contactUids == null || !_contactUids!.contains(doc.id)) continue;
        final d = doc.data();
        if (d[kDriverLocationShowOnPassengerLiveMap] == false) continue;
        if (d['position'] != null) idsWithDriverMarker.add(doc.id);
      }

      final displayedDriverIds = _nearbyDriverAnnotations.keys.toSet();
      final driversToRemove = displayedDriverIds.difference(idsWithDriverMarker);
      if (driversToRemove.isNotEmpty) {
        for (final id in driversToRemove) {
          final annotation = _nearbyDriverAnnotations.remove(id);
          if (annotation != null && mounted) {
            _driverAnnotationIdToUid.remove(annotation.id);
            try {
              await _driversAnnotationManager?.delete(annotation);
            } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          }
        }
      }

      for (var driverDoc in driverDocs) {
        if (!mounted) break;
        if (currentUid != null && driverDoc.id == currentUid) continue;
        
        // RE-INTĂRIT: Arată DOAR șoferii care sunt în agenda telefonului (contacte)
        if (_contactUids == null || !_contactUids!.contains(driverDoc.id)) continue;
        
        final data = driverDoc.data();
        // Șofer invizibil social: rămâne în `driver_locations` pentru curse, dar fără marker pe hartă.
        if (data[kDriverLocationShowOnPassengerLiveMap] == false) continue;

        if (data['position'] != null) {
          final GeoPoint pos = data['position'] as GeoPoint;
          final double? bearing = data['bearing'] as double?;

          double correctedBearing = 0.0;
          if (bearing != null && !bearing.isNaN) {
            correctedBearing = bearing + 180;
            if (correctedBearing >= 360) correctedBearing -= 360;
          }

          // Construiește eticheta: nr. înmatriculare + nume public (identic cu markerul propriu).
          final rawPlate = (data['licensePlate'] as String?)?.trim() ?? '';
          final rawName = (data['displayName'] as String?)?.trim() ?? '';
          final String? driverTextField;
          if (rawPlate.isNotEmpty && rawName.isNotEmpty) {
            driverTextField = '$rawPlate\n$rawName';
          } else if (rawPlate.isNotEmpty) {
            driverTextField = rawPlate;
          } else if (rawName.isNotEmpty) {
            driverTextField = rawName;
          } else {
            driverTextField = null;
          }

          const double driverLabelSize = 11.0;
          const int driverLabelColor = 0xFFFFFFFF; // White for visibility
          const List<double> driverLabelOffset = [0.0, 2.7];

          final String? carAvatarId = (data['carAvatarId'] as String?)?.trim();
          final bool driverIsChar = CarAvatarService.isCharacterAvatarId(carAvatarId);
          final double driverIconSize = (driverIsChar ? 1.05 : 0.72) * _neighborAvatarZoomFactor();

          if (_nearbyDriverAnnotations.containsKey(driverDoc.id)) {
            final annotation = _nearbyDriverAnnotations[driverDoc.id]!;
            annotation.geometry = MapboxUtils.createPoint(pos.latitude, pos.longitude);
            annotation.iconRotate = correctedBearing;
            annotation.iconSize = driverIconSize;
            if (driverTextField != null) {
              annotation.textField = driverTextField;
              annotation.textSize = driverLabelSize;
              annotation.textOffset = driverLabelOffset;
              annotation.textColor = driverLabelColor;
              annotation.textHaloColor = 0xFF000000; // Black halo for white text
              annotation.textHaloWidth = 2.2;
            }
            try {
              await _driversAnnotationManager?.update(annotation);
            } catch (_) {
              _driverAnnotationIdToUid.remove(annotation.id);
              _nearbyDriverAnnotations.remove(driverDoc.id);
            }
          } else {
            // Prevenim crearea a 2 markere pt același UID dacă stream-ul e rapid
            if (_nearbyDriverUidsBeingCreated.contains(driverDoc.id)) continue;
            _nearbyDriverUidsBeingCreated.add(driverDoc.id);

            final Uint8List imageList = await _nearbyDriverMarkerPngForUid(
              driverDoc.id,
              locationCarAvatarId: carAvatarId,
            );
            final drvImageName = 'nabour_drv_${driverDoc.id}';
            final drvImgOk = _mapboxMap != null && await _registerStyleImageFromPng(drvImageName, imageList);
            final options = PointAnnotationOptions(
              geometry: MapboxUtils.createPoint(pos.latitude, pos.longitude),
              iconImage: drvImgOk ? drvImageName : null,
              // image: imageList, // DO NOT USE PNG bytes for RGBA field
              iconSize: driverIconSize,
              iconAnchor: IconAnchor.BOTTOM,
              iconRotate: correctedBearing,
              textField: driverTextField,
              textSize: driverTextField != null ? driverLabelSize : null,
              textColor: driverTextField != null ? driverLabelColor : null,
              textHaloColor: driverTextField != null ? 0xFF000000 : null,
              textHaloWidth: driverTextField != null ? 2.2 : null,
              textOffset: driverTextField != null ? driverLabelOffset : null,
              textJustify: driverTextField != null ? TextJustify.CENTER : null,
            );
            try {
              final newAnnotation = await _driversAnnotationManager?.create(options);
              if (newAnnotation != null && mounted) {
                _nearbyDriverAnnotations[driverDoc.id] = newAnnotation;
                _driverAnnotationIdToUid[newAnnotation.id] = driverDoc.id;
              }
            } catch (_) {
            } finally {
              _nearbyDriverUidsBeingCreated.remove(driverDoc.id);
            }
          }
        }
      }
      if (mounted) {
        _recomputeAvatarPinsForEmojiAvoidance();
      }
    } catch (e) {
      Logger.error('Non-fatal error during _updateNearbyDrivers: $e', error: e);
    }
  }

  // ── Strat Cereri Cursă (Ride Broadcasts) — Pentru Șoferi ────────────────────

}

