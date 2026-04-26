// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapInitMethods on _MapScreenState {
  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    final int gen = ++_mapCreatedGeneration;

    // 🔄 MIDDLEWARE SYNC: Înregistrăm instanța în provider pentru a aplica ultima stare (tranzit OSM->Mapbox)
    context.read<MapCameraProvider>().setMapInstance(mapboxMap);
    _isUsing3DUserModel = false;
    // Resetăm lanțul de pin-uri: dacă era blocat (ex. await pe MapBox mort în timpul OSM),
    // noua instanță nu va mai aştepta indefinit vechea promisiune nerezolvată.
    _homePinUpdateChain = null;
    // Resetează managerii lazy înainte de orice await. Altfel [onStyleLoaded] poate rula
    // în timpul await-urilor de mai jos, creează markerul, iar codul vechi punea managerul
    // la null fără deleteAll nativ → pe unele dispozitive marker „creat OK” dar invizibil;
    // loguri duble „User marker created OK” cu UUID diferit.
    _routeAnnotationManager = null;
    _routeMarkersAnnotationManager = null;
    _userPointAnnotationManager = null;
    _userPointAnnotation = null;
    _userMarkerVisualCacheKey = null;
    _nabourStyleImageRegistry.clear();
    _clearAndroidUserMarkerOverlayFields();
    _clearAndroidPrivatePinOverlayFields();
    _savedHomeFavoritePinManager = null;
    _savedHomeFavoritePinTapRegistered = false;
    _orientationReperPinManager = null;
    _orientationReperPinTapRegistered = false;
    _driversAnnotationManager = null;
    _driversAnnotationTapListenerRegistered = false;
    _driverAnnotationIdToUid.clear();
    _pickupCircleManager = null;
    _destinationCircleManager = null;
    _pickupSuggestionsManager = null;
    // Sincronizăm starea temei ca să evităm un loadStyleURI inutil imediat după creare
    if (mounted) {
      _lastKnownDarkMode = Theme.of(context).brightness == Brightness.dark;
    }
    // NOU: Inițializăm managerul de Bule de Cartier
    _requestsManager?.dispose();
    _requestsManager = NeighborhoodRequestsManager(
      mapboxMap: _mapboxMap!,
      context: context,
      onDataChanged: () {
        if (mounted) setState(() {});
      },
      getUserLatLng: () {
        final p = LocationCacheService.pickNewer(
          _currentPositionObject,
          LocationCacheService.instance.peekRecent(
            maxAge: const Duration(minutes: 20),
          ),
        );
        if (p == null) return null;
        return (lat: p.latitude, lng: p.longitude);
      },
    );
    await _requestsManager!.initialize();
    if (!mounted || gen != _mapCreatedGeneration) return;

    await _ensureMysteryBoxManagersInitialized(mapboxMap: _mapboxMap);
    if (!mounted || gen != _mapCreatedGeneration) return;
    
    Logger.info("Map created. Initializing light map state...");

    try {
      // Disable default UI plugins to reduce AppCompat theme warnings and save GPU
      try {
        final compass = _mapboxMap?.compass;
        final logo = _mapboxMap?.logo;
        final attribution = _mapboxMap?.attribution;
        final scaleBar = _mapboxMap?.scaleBar;
        // Bara nativă: harta e sub SafeArea, deci marginTop mic e suficient (fără ceas peste scară).
        await compass?.updateSettings(CompassSettings(enabled: false));
        await logo?.updateSettings(LogoSettings(
          position: OrnamentPosition.TOP_LEFT,
          marginLeft: 10,
          marginTop: 10,
        ));
        await attribution?.updateSettings(AttributionSettings(
          position: OrnamentPosition.TOP_LEFT,
          marginLeft: 100,
          marginTop: 14,
        ));
        await scaleBar?.updateSettings(ScaleBarSettings(
          enabled: false,
        ));
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }

      // Annotation managers: resetat la începutul lui _onMapCreated (înainte de await).

      // Initialize route pulse animation (low overhead)
      if (!AppDrawer.lowDataMode) {
        _routePulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
        _routePulse = Tween<double>(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(parent: _routePulseController!, curve: Curves.easeInOut),
        );
        // Start a bit later to avoid jank on first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _routePulseController?.repeat(reverse: true);
        });
      }
      Logger.info("Deferred annotation managers creation (lazy mode).");

      // POI: încărcăm + afișăm pe hartă doar după interacțiunea userului
      // (categoria POI și apoi POI-ul selectat din listă).
      
      // Enable location puck (blue dot showing user position).
      try {
        await _setupLocationPuck(mapboxMap);
      } catch (e) {
        Logger.warning('Could not enable location puck: $e');
      }
      if (!mounted || gen != _mapCreatedGeneration) return;

      // Mișcare cursivă la pan/rotate/pinch (decelerare după gest).
      try {
        await mapboxMap.gestures.updateSettings(
          GesturesSettings(
            scrollDecelerationEnabled: true,
            rotateDecelerationEnabled: true,
            pinchToZoomDecelerationEnabled: true,
            pinchPanEnabled: true,
          ),
        );
      } catch (e) {
        Logger.debug('gestures.updateSettings: $e');
      }

      if (mounted) {
        // Center on last known position immediately (no GPS wait), then fetch accurate GPS.
        unawaited(_centerOnLocationOnMapReady());
        // Warm-up tiles around current center (non-blocking)
        unawaited(_prewarmTiles());
        final markerPos = _positionForUserMapMarker();
        if (markerPos != null) {
          unawaited(_updateWeatherAndStyle(markerPos.latitude, markerPos.longitude));
          unawaited(_updateUserMarker(centerCamera: false));
          unawaited(_updateLocationPuck());
        }

        // ðŸ”„ SOFT REFRESH: Recentrare automatÄƒ dupÄƒ 2 secunde pentru a asigura precizia maximÄƒ
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _centerCameraOnCurrentPosition();
          }
        });

        unawaited(Future.microtask(_ensurePassiveLocationWarmupIfNeeded));
        unawaited(_rebuildEmojiThenMomentLayers());
        unawaited(_syncMapOrientationPinAnnotation());

        // Restart neighbor streams now that MapBox is ready.
        // If streams were started before _onMapCreated (while _mapboxMap was null),
        // they fell back to Firestore-only and RTDB was never subscribed.
        // Re-running _listenForNeighbors cancels stale subs and sets up RTDB properly.
        _neighborsAnnotationManager = null;
        _neighborsAnnotationTapListenerRegistered = false;
        _neighborAnnotations.clear();
        _neighborAnnotationIdToUid.clear();
        _isInitializingNeighbors = false; // allow restart even if previous init was partial
        _listenForNeighbors();
        // Also replay any data already in cache immediately (stream re-emit can be slow).
        unawaited(_reapplyContactFilterOnMap());
        // Safety net: retry after streams have had time to emit data (covers slow GPS + frame drops).
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _mapboxMap != null) unawaited(_reapplyContactFilterOnMap());
        });
      }
    } catch (e) {
      Logger.error("CRITICAL ERROR creating annotation managers: $e. Map markers will not work.", error: e);
    }
  }

  /// Aplică estetica "Premium Neon" / "Clean Tech" prin Mapbox Runtime Styling la fiecare încărcare de stil.
  Future<void> _onStyleLoaded(StyleLoadedEventData event) async {
    if (_mapboxMap == null) return;
    _isUsing3DUserModel = false;
    Logger.info("Map style loaded. Applying Aesthetic Overlays dynamically...");

    // Capturăm isDark înainte de orice await (evităm async-gap pe BuildContext).
    final isDark = !AppDrawer.lowDataMode &&
        Theme.of(context).brightness == Brightness.dark;

    // Re-înregistrează toate imaginile custom în noul stil înainte de orice altceva.
    // Mapbox șterge imaginile adăugate via addStyleImage la fiecare style-reload/onTrimMemory.
    await _reRegisterAllStyleImages();

    try {
      final style = _mapboxMap!.style;

      final layers = await style.getStyleLayers();
      
      for (final l in layers) {
        final layerId = l?.id;
        if (layerId == null) continue;

        if (isDark) {
          // --- 🌌 DARK: "Cyber Neon" cu contrast ridicat ---
          // Background: Albastru-negru adânc pentru adâncime
          if (layerId == 'background') {
            try { await style.setStyleLayerProperty(layerId, 'background-color', '#0F172A'); } catch (_) {}
          }
          // Drumuri: Neon Violet/Cyan cu lățime mai mare pentru vizibilitate
          if (layerId.toLowerCase().contains('road') || layerId.toLowerCase().contains('street')) {
            try {
              final isPrimary = layerId.contains('primary') || layerId.contains('motorway');
              await style.setStyleLayerProperty(layerId, 'line-color', isPrimary ? '#A855F7' : '#6366F1');
              await style.setStyleLayerProperty(layerId, 'line-width', isPrimary ? 2.8 : 1.8);
              await style.setStyleLayerProperty(layerId, 'line-opacity', 0.85);
            } catch (_) {}
          }
          // Apă: Albastru „Deep Sea”
          if (layerId.toLowerCase().contains('water')) {
            try {
              await style.setStyleLayerProperty(layerId, 'fill-color', '#1E293B');
              await style.setStyleLayerProperty(layerId, 'fill-opacity', 1.0);
            } catch (_) {}
          }
          // Zone verzi: Verde „Midnight”
          if (layerId.toLowerCase().contains('landcover') || layerId.toLowerCase().contains('park') || layerId.toLowerCase().contains('forest')) {
            try {
              await style.setStyleLayerProperty(layerId, 'fill-color', '#064E3B');
              await style.setStyleLayerProperty(layerId, 'fill-opacity', 0.6);
            } catch (_) {}
          }
          // Clădiri: Gri închis cu extrudare subtilă
          if (layerId.toLowerCase().contains('building')) {
            try {
              await style.setStyleLayerProperty(layerId, 'fill-color', '#1E293B');
              await style.setStyleLayerProperty(layerId, 'fill-opacity', 0.65);
              await style.setStyleLayerProperty(layerId, 'fill-outline-color', '#334155');
            } catch (_) {}
          }
          // Etichete: Cyan Neon pentru lizibilitate maximă
          if (layerId.toLowerCase().contains('poi') || layerId.toLowerCase().contains('label')) {
            try {
              await style.setStyleLayerProperty(layerId, 'text-color', '#22D3EE');
              await style.setStyleLayerProperty(layerId, 'text-halo-color', '#0F172A');
              await style.setStyleLayerProperty(layerId, 'text-halo-width', 1.5);
            } catch (_) {}
          }
        } 
        else {
          // --- ☀️ LIGHT MODE (Clean Tech / High-Energy) ---
          // O estetică stil "Mirror's Edge" - curată, modernă, cu accente neon pastel
          
          // 1. Drumuri (Sky Blue cu Cyan accent)
          if (layerId.toLowerCase().contains('road') || layerId.toLowerCase().contains('street')) {
            try {
              await style.setStyleLayerProperty(layerId, 'line-color', '#E0F2FE'); // Light cyan/blue back
              // Outline (dacă layer-ul e un casing sau primary)
              if (layerId.contains('primary') || layerId.contains('motorway')) {
                await style.setStyleLayerProperty(layerId, 'line-color', '#0EA5E9');
              }
              await style.setStyleLayerProperty(layerId, 'line-width', 1.8);
            } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          }

          // 2. Apa (Crystalline Clear Blue)
          if (layerId.toLowerCase().contains('water')) {
            try {
              await style.setStyleLayerProperty(layerId, 'fill-color', '#BAE6FD'); // Bright cyan water
            } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          }

          // 3. Zone Verzi (Digital Mint / Pastel Green)
          if (layerId.toLowerCase().contains('park') || layerId.toLowerCase().contains('forest') || layerId.toLowerCase().contains('natural')) {
            try {
              await style.setStyleLayerProperty(layerId, 'fill-color', '#ECFDF5'); // Very soft mint
              await style.setStyleLayerProperty(layerId, 'fill-outline-color', '#10B981');
            } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          }

          // 4. Fundal și Teren (Ultra Clean Slate)
          if (layerId == 'background' || layerId.toLowerCase().contains('landuse-background')) {
            try {
              await style.setStyleLayerProperty(layerId, 'background-color', '#F8FAFC');
              await style.setStyleLayerProperty(layerId, 'fill-color', '#F8FAFC');
            } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          }

          // 5. Clădiri (Pure White with subtle lines)
          if (layerId.toLowerCase().contains('building')) {
            try {
              await style.setStyleLayerProperty(layerId, 'fill-color', '#FFFFFF');
              await style.setStyleLayerProperty(layerId, 'fill-opacity', 0.9);
            } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          }

          // 6. POI (High-Contrast Indigo / Violet)
          if (layerId.toLowerCase().contains('poi') || layerId.toLowerCase().contains('label')) {
            try {
              await style.setStyleLayerProperty(layerId, 'text-color', '#4F46E5'); // Indigo regal pt lizibilitate
              await style.setStyleLayerProperty(layerId, 'icon-color', '#4338CA');
              await style.setStyleLayerProperty(layerId, 'text-halo-color', '#FFFFFF');
              await style.setStyleLayerProperty(layerId, 'text-halo-width', 2.0);
            } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          }
        }
      }
      
      // După overlay-uri runtime, pe unele GPU referința Dart la manager rămâne dar randarea se pierde.
      // Evităm cursa veche (null fără deleteAll): aici facem mereu [deleteAll] înainte de reset.
      if (mounted) {
        await _disposePointAnnotationManagersAfterRuntimeStyleMutation();
        // Așteptăm reinilizarea cererilor de cartier + pin fly-to; altfel managerii rămân invalizi după stil.
        await _requestsManager?.initialize();
        unawaited(_mysteryBoxManager?.initialize());
        unawaited(_communityMysteryManager?.initialize());
        if (_positionForUserMapMarker() != null) {
          await _updateUserMarker(centerCamera: false);
          await _updateLocationPuck();
        }
        await _syncMapOrientationPinAnnotation();
        // Re-adaugă markerii vecinilor/contactelor după ce _disposePointAnnotationManagersAfterRuntimeStyleMutation()
        // i-a şters. Fără asta, la fiecare reload de stil harta MapBox rămâne goală de vecini.
        unawaited(_reapplyContactFilterOnMap());
      }

    } catch (e) {
      Logger.error("Failed to apply Style Overlays: $e");
    }
  }

  /// Configurează puck-ul de locație pentru a afișa poziția curentă.
  /// Se utilizează puck-ul implicit Mapbox care se integrează perfect.
  Future<void> _setupLocationPuck(MapboxMap mapboxMap) async {
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingMaxRadius: 60.0,
        pulsingColor: const Color(0xFF3682F3).toARGB32(),
      ),
    );
  }

  // Initializes GeoJson source and SymbolLayers for POIs (with clustering)
  // Defer POI layer initialization until first use; method kept for future use
  // ignore: unused_element
  Future<void> _ensurePoiLayersInitialized() async {
    if (_mapboxMap == null) return;
    try {
      final style = _mapboxMap!.style;
      if (_poiLayersInitialized) {
        return; // already initialized
      }

      // Ensure we have the symbol icon image that SymbolLayer references.
      if (!_marker15StyleImageAdded) {
        try {
          final ByteData markerBytes = await rootBundle.load('assets/images/pin_icon.png');
          final Uint8List png = markerBytes.buffer.asUint8List();
          final codec = await ui.instantiateImageCodec(png);
          final frame = await codec.getNextFrame();
          final image = frame.image;
          final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          if (byteData != null) {
            final mbxImage = MbxImage(
              width: image.width,
              height: image.height,
              data: byteData.buffer.asUint8List(),
            );
            await style.addStyleImage(
              'marker-15',
              1.0,
              mbxImage,
              false,
              const [],
              const [],
              null,
            );
            _marker15StyleImageAdded = true;
          }
        } catch (e) {
          Logger.warning('Could not add marker-15 style image: $e', tag: 'POI');
        }
      }

      // Add clustered GeoJSON source for POIs (once)
      final source = GeoJsonSource(
        id: _MapScreenState._poiSourceId,
        data: '{"type":"FeatureCollection","features":[]}',
        cluster: true,
        clusterRadius: 60,
        clusterMaxZoom: 15,
      );
      try {
        await style.addSource(source);
      } catch (e) {
        // Idempotent: dacă sursa există deja (ex. reinits pe același style), ignorăm.
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }

      // Cluster circles
      try {
        await style.addLayer(
          CircleLayer(
            id: _MapScreenState._poiClusterLayerId,
            sourceId: _MapScreenState._poiSourceId,
            circleColor: Colors.lightBlue.shade400.toARGB32(),
            circleRadius: 18.0,
            filter: ["has", "point_count"],
          ),
        );
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }

      // Cluster count labels
      try {
        await style.addLayer(
          SymbolLayer(
            id: _MapScreenState._poiClusterCountLayerId,
            sourceId: _MapScreenState._poiSourceId,
            textField: '{point_count_abbreviated}',
            textColor: Colors.white.toARGB32(),
            textSize: 12.0,
            textIgnorePlacement: true,
            textAllowOverlap: true,
            filter: ["has", "point_count"],
          ),
        );
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }

      // Individual POI symbols
      try {
        await style.addLayer(
          SymbolLayer(
            id: _MapScreenState._poiSymbolLayerId,
            sourceId: _MapScreenState._poiSourceId,
            iconImage: 'marker-15',
            iconAllowOverlap: true,
            filter: ["!has", "point_count"],
          ),
        );
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }

      // Selected POI highlight source + layer (always present, data empty by default)
      try {
        await style.addSource(GeoJsonSource(
          id: _MapScreenState._selectedPoiSourceId,
          data: '{"type":"FeatureCollection","features":[]}',
        ));
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }
      try {
        await style.addLayer(CircleLayer(
          id: _MapScreenState._selectedPoiLayerId,
          sourceId: _MapScreenState._selectedPoiSourceId,
          circleColor: Colors.redAccent.toARGB32(),
          circleRadius: 10.0,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 2.0,
        ));
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }

      _poiLayersInitialized = true;
      _poiLayersInitialized = true;
    } catch (e) {
      Logger.error('Failed to init POI layers: $e', error: e);
    }
  }

  // Cache pentru iconițele generate programatic
  static final Map<String, Uint8List> _staticMarkerIconCache = {};

  /// Generează iconița marker:
  /// passenger = cerc albastru cu punct alb
  /// driver    = mașinuță 3D (vedere de sus, design premium)
  static Future<Uint8List> _generateMarkerIcon({
    required bool isPassenger,
    String? customAssetPath,
    int? batteryLevel,
    bool isCharging = false,
  }) async {
    final batKey = NeighborFriendMarkerIcons.batteryBucketForMarker(batteryLevel)?.toString() ?? 'n';
    final cacheKey = 'v2_${isPassenger ? 'p' : 'd'}_${customAssetPath ?? (isPassenger ? 'default' : 'driver_3d')}_b$batKey${isCharging ? 'c' : 'n'}';
    
    if (_staticMarkerIconCache.containsKey(cacheKey)) return _staticMarkerIconCache[cacheKey]!;

    if (customAssetPath != null || !isPassenger) {
      try {
        final path = customAssetPath ?? 'assets/images/driver_icon.png';
        final ByteData imageBytes = await rootBundle.load(path);
        final Uint8List sourceBytes = imageBytes.buffer.asUint8List();
        
        final codec = await ui.instantiateImageCodec(sourceBytes);
        final frame = await codec.getNextFrame();
        final decoded = frame.image;

        final bool isCharacter = CarAvatarService.isCharacterAssetPath(customAssetPath);
        final double maxSize = isCharacter ? 380.0 : 256.0;
        const double safeScale = 0.88; // 12% padding to prevent clipping
        final double srcW = decoded.width.toDouble();
        final double srcH = decoded.height.toDouble();
        final double aspectRatio = srcW / srcH;

        double destW, destH;
        if (aspectRatio > 1.0) {
          destW = maxSize * safeScale;
          destH = (maxSize * safeScale) / aspectRatio;
        } else {
          destH = maxSize * safeScale;
          destW = (maxSize * safeScale) * aspectRatio;
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
        var img = await picture.toImage(maxSize.toInt(), maxSize.toInt());

        final bool isCustom = customAssetPath != null;

        // Stripper BFS: Curăță fundalul "pătrat" (alb, gri sau aproape negru)
        try {
          final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
          if (data != null) {
            final buffer = data.buffer.asUint8List();
            final w = maxSize.toInt();
            final h = maxSize.toInt();
            final visited = List<bool>.filled(w * h, false);
            final queue = <int>[];

            for (final startIdx in [0, (w - 1), (h - 1) * w, (h * w - 1)]) {
              if (!visited[startIdx]) queue.add(startIdx);
            }

            bool modified = false;
            while (queue.isNotEmpty) {
              final idx = queue.removeAt(0);
              if (visited[idx]) continue;
              visited[idx] = true;

              final r = buffer[idx * 4];
              final g = buffer[idx * 4 + 1];
              final b = buffer[idx * 4 + 2];
              final a = buffer[idx * 4 + 3];

              bool isBg = false;
              if (a < 15) { // Pixeli deja semi-transparenți sunt considerați fundal
                isBg = true;
              } else {
                // Verificare chirurgicală fundal (alb, griuri, negru AI)
                final bool isPrincess = customAssetPath?.contains('princess_cristina') ?? false;
                if (!isCustom || isPrincess) {
                  // 1. Aproape alb / Gri foarte deschis
                  if (r > 215 && g > 215 && b > 215) {
                    isBg = true;
                  } 
                  // 2. Griuri medii (toleranță mică între canale)
                  else if (r > 160 && (r - g).abs() < 12 && (r - b).abs() < 12) {
                    isBg = true;
                  }
                  // 3. Aproape negru (fundaluri AI întunecate) - dar evităm culorile părului/hainelor
                  // Fundalul e de obicei uniform, deci cerem r,g,b să fie foarte apropiate.
                  else if (r < 65 && g < 65 && b < 65 && (r - g).abs() < 8 && (r - b).abs() < 8) {
                    isBg = true;
                  }
                }
              }

              if (isBg) {
                buffer[idx * 4 + 3] = 0;
                modified = true;
                final x = idx % w;
                final y = idx ~/ w;
                if (x > 0 && !visited[idx - 1]) queue.add(idx - 1);
                if (x < w - 1 && !visited[idx + 1]) queue.add(idx + 1);
                if (y > 0 && !visited[idx - w]) queue.add(idx - w);
                if (y < h - 1 && !visited[idx + w]) queue.add(idx + w);
              }
            }

            if (modified) {
              final completer = Completer<ui.Image>();
              ui.decodeImageFromPixels(buffer, w, h, ui.PixelFormat.rgba8888, completer.complete);
              img = await completer.future;
            }
          }
        } catch (e) {
          Logger.debug('Surgical Transparency Strip Error: $e');
        }

        ui.Image imgOut = img;
        if (NeighborFriendMarkerIcons.batteryBucketForMarker(batteryLevel) != null) {
          final overlay = ui.PictureRecorder();
          final overlayCanvas = ui.Canvas(overlay, ui.Rect.fromLTWH(0, 0, maxSize, maxSize));
          overlayCanvas.drawImage(img, ui.Offset.zero, ui.Paint());
          NeighborFriendMarkerIcons.paintBatteryChip(overlayCanvas, maxSize, batteryLevel: batteryLevel, isCharging: isCharging);
          final pic = overlay.endRecording();
          imgOut = await pic.toImage(maxSize.toInt(), maxSize.toInt());
        }

        final byteData = await imgOut.toByteData(format: ui.ImageByteFormat.png);
        final bytes = _MapScreenState._pngBytesOrMinimalFallback(byteData, '_generateMarkerIcon asset=$path');
        _staticMarkerIconCache[cacheKey] = bytes;
        return bytes;
      } catch (e) {
        Logger.error('Failed to generate marker icon from asset: $e');
      }
    }

    // Fallback: Vector-drawn marker
    const double size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
    final paint = ui.Paint()..isAntiAlias = true;

    if (isPassenger) {
      const center = ui.Offset(size / 2, size / 2);
      const radius = size / 2 - 4;
      paint..color = const ui.Color(0x44000000)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
      canvas.drawCircle(center.translate(0, 2), radius, paint);
      paint.maskFilter = null;
      paint.color = const ui.Color(0xFFFFFFFF);
      canvas.drawCircle(center, radius + 2, paint);
      paint.color = const ui.Color(0xFF1976D2);
      canvas.drawCircle(center, radius, paint);
      paint.color = const ui.Color(0xFFFFFFFF);
      canvas.drawCircle(center, radius * 0.38, paint);
    } else {
      final double cx = size / 2;
      final double cy = size / 2;

      // 1. DROP SHADOW
      paint..color = const ui.Color(0x55000000)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7);
      canvas.drawRRect(ui.RRect.fromRectAndRadius(ui.Rect.fromCenter(center: ui.Offset(cx + 2, cy + 5), width: 38, height: 62), const ui.Radius.circular(12)), paint);
      paint.maskFilter = null;

      // 2. CAROSERIE
      paint.shader = ui.Gradient.linear(ui.Offset(cx - 19, cy), ui.Offset(cx + 19, cy), [const ui.Color(0xFF0D1457), const ui.Color(0xFF3949AB), const ui.Color(0xFF283593), const ui.Color(0xFF0D1457)], [0.0, 0.35, 0.65, 1.0]);
      canvas.drawRRect(ui.RRect.fromRectAndRadius(ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 38, height: 64), const ui.Radius.circular(12)), paint);
      paint.shader = null;

      // 3-6. ROȚI
      _draw3DWheel(canvas, paint, cx - 22, cy - 20, 8, 12);
      _draw3DWheel(canvas, paint, cx + 14, cy - 20, 8, 12);
      _draw3DWheel(canvas, paint, cx - 22, cy + 10, 8, 12);
      _draw3DWheel(canvas, paint, cx + 14, cy + 10, 8, 12);

      // 7. CAPOTĂ față
      paint.shader = ui.Gradient.linear(ui.Offset(cx, cy - 32), ui.Offset(cx, cy - 16), [const ui.Color(0xFF5C6BC0), const ui.Color(0xFF283593)], [0.0, 1.0]);
      canvas.drawRRect(ui.RRect.fromRectAndRadius(ui.Rect.fromLTWH(cx - 15, cy - 32, 30, 16), const ui.Radius.circular(5)), paint);
      paint.shader = null;

      // 8. PAVILION
      paint.shader = ui.Gradient.linear(ui.Offset(cx - 12, cy - 18), ui.Offset(cx + 12, cy + 10), [const ui.Color(0xFF7986CB), const ui.Color(0xFF3949AB), const ui.Color(0xFF1A237E)], [0.0, 0.5, 1.0]);
      canvas.drawRRect(ui.RRect.fromRectAndRadius(ui.Rect.fromLTWH(cx - 12, cy - 18, 24, 30), const ui.Radius.circular(7)), paint);
      paint.shader = null;

      // 9. PARBRIZ
      paint.shader = ui.Gradient.linear(ui.Offset(cx - 10, cy - 17), ui.Offset(cx + 10, cy - 5), [const ui.Color(0xCC9CE7FF), const ui.Color(0x9954D1F7)], [0.0, 1.0]);
      canvas.drawRRect(ui.RRect.fromRectAndRadius(ui.Rect.fromLTWH(cx - 10, cy - 17, 20, 12), const ui.Radius.circular(3)), paint);
      paint.shader = null;

      // 10. LUNETĂ
      paint.shader = ui.Gradient.linear(ui.Offset(cx, cy + 4), ui.Offset(cx, cy + 14), [const ui.Color(0x9954D1F7), const ui.Color(0xCC1E6E8A)], [0.0, 1.0]);
      canvas.drawRRect(ui.RRect.fromRectAndRadius(ui.Rect.fromLTWH(cx - 9, cy + 4, 18, 10), const ui.Radius.circular(3)), paint);
      paint.shader = null;

      // 11. CAPOTĂ spate
      paint.shader = ui.Gradient.linear(ui.Offset(cx, cy + 16), ui.Offset(cx, cy + 32), [const ui.Color(0xFF283593), const ui.Color(0xFF0D1457)], [0.0, 1.0]);
      canvas.drawRRect(ui.RRect.fromRectAndRadius(ui.Rect.fromLTWH(cx - 15, cy + 16, 30, 16), const ui.Radius.circular(5)), paint);
      paint.shader = null;

      // 12-13. FARURI ȘI STOPURI
      _drawHeadlight(canvas, paint, cx - 13, cy - 32, isRear: false);
      _drawHeadlight(canvas, paint, cx + 13, cy - 32, isRear: false);
      _drawHeadlight(canvas, paint, cx - 13, cy + 32, isRear: true);
      _drawHeadlight(canvas, paint, cx + 13, cy + 32, isRear: true);

      // 14. INDICATOR
      paint..color = const ui.Color(0x6600C853)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
      canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 8, paint);
      paint.maskFilter = null;
      paint.color = const ui.Color(0xFF00E676);
      canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 6, paint);
      paint.color = const ui.Color(0xFF69F0AE);
      canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 3, paint);
    }

    NeighborFriendMarkerIcons.paintBatteryChip(canvas, size, batteryLevel: batteryLevel, isCharging: isCharging);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = _MapScreenState._pngBytesOrMinimalFallback(byteData, '_generateMarkerIcon fallback');
    _staticMarkerIconCache[cacheKey] = bytes;
    return bytes;
  }

  /// Descarcă poza de profil de la [url], o taie circular și returnează PNG 120×120
  /// compatibil cu [_compositeAvatarWithLabel] / LocationPuck2D.
  static Future<Uint8List?> _generateProfilePhotoMarkerIcon(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final codec = await ui.instantiateImageCodec(response.bodyBytes, targetWidth: 120, targetHeight: 120);
      final frame = await codec.getNextFrame();
      final src = frame.image;
      const double size = 120.0;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
      // clip circular
      final path = ui.Path()..addOval(ui.Rect.fromLTWH(0, 0, size, size));
      canvas.clipPath(path);
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
        ui.Rect.fromLTWH(0, 0, size, size),
        ui.Paint()..isAntiAlias = true..filterQuality = ui.FilterQuality.high,
      );
      // border alb subțire
      canvas.drawCircle(
        const ui.Offset(size / 2, size / 2),
        size / 2 - 1,
        ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      src.dispose();
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      return byteData?.buffer.asUint8List();
    } catch (e) {
      Logger.warning('Profile photo marker generation failed: $e', tag: 'MAP');
      return null;
    }
  }

  /// Generează un PNG compozit (avatar + etichetă chip) pentru [LocationPuck2D.bearingImage].
  ///
  /// Canvas-ul este simetric vertical (spațiu transparent egal deasupra și sub avatar)
  /// → ancora GPS (centrul imaginii) cade exact pe centrul avatarului.
  /// Font mare (36px) → text lizibil pe dispozitive @3x (≈12dp afișați).
  static Future<Uint8List> _compositeAvatarWithLabel({
    required Uint8List avatarBytes,
    required String? labelText,
    double avatarSize = 120.0,
  }) async {
    final lines = (labelText ?? '').split('\n').where((l) => l.isNotEmpty).toList();

    // Imaginea se afișează prin topImage (nu bearingImage) → nu mai e comprimată
    // de Mapbox pe axa Y → canvas pătrat, fără elongare.
    final double avatarDrawSize = avatarSize * 1.5;
    final double canvasW = math.max(240.0, avatarDrawSize);
    final double avatarOffsetX = (canvasW - avatarDrawSize) / 2;

    final codec = await ui.instantiateImageCodec(avatarBytes);
    final frame = await codec.getNextFrame();
    final srcImg = frame.image;

    // ── Caz fără etichetă: canvas pătrat, avatar centrat ─────────────────────────
    if (lines.isEmpty) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, canvasW, canvasW));
      canvas.drawImageRect(
        srcImg,
        ui.Rect.fromLTWH(0, 0, srcImg.width.toDouble(), srcImg.height.toDouble()),
        ui.Rect.fromLTWH(avatarOffsetX, (canvasW - avatarDrawSize) / 2, avatarDrawSize, avatarDrawSize),
        ui.Paint()..isAntiAlias = true..filterQuality = ui.FilterQuality.high,
      );
      srcImg.dispose();
      final picture = recorder.endRecording();
      final img = await picture.toImage(canvasW.toInt(), canvasW.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      return byteData != null ? byteData.buffer.asUint8List() : avatarBytes;
    }

    // ── Caz cu etichetă: avatar pătrat + chip text sub el ────────────────────────
    const double fontSize = 36.0;
    const double lineH = fontSize + 6.0;
    const double padV = 8.0;
    const double gap = 6.0;
    const double chipMarginH = 8.0;

    final double chipW = canvasW - chipMarginH * 2;
    final double chipH = lines.length * lineH + padV * 2;
    // Înălțimea logică a conținutului (avatar + gap + chip, simetric vertical).
    final double contentH = avatarDrawSize + 2.0 * (gap + chipH);

    // Canvas PĂTRAT — Mapbox LocationPuck2D scalează imaginea la un pătrat intern;
    // dacă PNG-ul este dreptunghiular (mai înalt decât lat), avatarul se turtește.
    // Folosim side = max(canvasW, contentH) și centrăm conținutul.
    final double side = math.max(canvasW, contentH);
    final double offsetX = (side - canvasW) / 2;   // centrare orizontală a conținutului
    final double offsetY = (side - contentH) / 2;  // centrare verticală a conținutului

    final double avatarOffsetYLabel = offsetY + gap + chipH;
    final double chipY = avatarOffsetYLabel + avatarDrawSize + gap;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, side, side));

    // Avatar centrat, proporții originale — canvas pătrat, fără distorsiune.
    canvas.drawImageRect(
      srcImg,
      ui.Rect.fromLTWH(0, 0, srcImg.width.toDouble(), srcImg.height.toDouble()),
      ui.Rect.fromLTWH(offsetX + avatarOffsetX, avatarOffsetYLabel, avatarDrawSize, avatarDrawSize),
      ui.Paint()
        ..isAntiAlias = true
        ..filterQuality = ui.FilterQuality.high,
    );

    // Chip etichetă sub avatar (fără fundal — doar text cu umbră).
    // canvas.drawRRect eliminat — fundalul e transparent.

    for (int i = 0; i < lines.length; i++) {
      final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: fontSize,
        fontWeight: ui.FontWeight.w700,
        textAlign: ui.TextAlign.center,
      ))
        ..pushStyle(ui.TextStyle(
          color: const ui.Color(0xFF39FF14),
          shadows: const [
            ui.Shadow(
              color: ui.Color(0xAA000000),
              blurRadius: 5,
              offset: ui.Offset(0, 1),
            ),
          ],
        ))
        ..addText(lines[i]);
      final para = pb.build()
        ..layout(ui.ParagraphConstraints(width: chipW - 8.0));
      canvas.drawParagraph(
        para,
        ui.Offset(offsetX + chipMarginH + 4.0, chipY + padV + i * lineH),
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(side.toInt(), side.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return avatarBytes;
    return byteData.buffer.asUint8List();
  }

  static void _draw3DWheel(
      ui.Canvas canvas, ui.Paint paint, double x, double y, double w, double h) {
    // Outer tire (dark)
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
    // Rim highlight
    paint.color = const ui.Color(0x66FFFFFF);
    canvas.drawOval(
      ui.Rect.fromLTWH(x + 1.5, y + 1.5, w - 3, h * 0.45),
      paint,
    );
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
    // Glow
    paint
      ..color = glowColor
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawOval(ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 10, height: 6), paint);
    paint.maskFilter = null;
    // Core
    paint.color = coreColor;
    canvas.drawOval(ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 7, height: 4), paint);
    // Inner
    paint.color = innerColor;
    canvas.drawOval(ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 4, height: 2.5), paint);
  }

  /// Pe loc: netezire ușoară (zgomot GPS). În mișcare: fără interpolare poziție — avatar aliniat cu puck.
  static const double _driverMarkerPosLerpSoft = 0.34;

  /// Încarcă preferința "afișează poza de profil pe hartă" din SharedPreferences
  /// și URL-ul pozei din Firestore / Firebase Auth.
  Future<void> _loadProfilePhotoMapPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usePic = prefs.getBool(_MapScreenState._kPrefUseProfilePhotoOnMap) ?? false;
      // URL poză: Firestore users/{uid}/photoURL, fallback FirebaseAuth
      String? photoUrl;
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          final raw = doc.data()?['photoURL'];
          if (raw is String && raw.trim().isNotEmpty) photoUrl = raw.trim();
        }
      } catch (_) {}
      photoUrl ??= FirebaseAuth.instance.currentUser?.photoURL?.trim();
      if (!mounted) return;
      setState(() {
        _useProfilePhotoOnMap = usePic;
        _myProfilePhotoUrl = photoUrl;
      });
      if (usePic) {
        _forceUserCarMarkerFullRebuild = true;
        unawaited(_updateUserMarker(centerCamera: false));
      }
    } catch (e) {
      Logger.warning('_loadProfilePhotoMapPref failed: $e', tag: 'MAP');
    }
  }

  Future<void> _ensureMysteryBoxManagersInitialized({MapboxMap? mapboxMap}) async {
    if (_mysteryBoxManager == null) {
      _mysteryBoxManager = MysteryBoxMapManager(
        mapboxMap: mapboxMap,
        context: context,
        getUserLatLng: () {
          final p = LocationCacheService.pickNewer(
            _currentPositionObject,
            LocationCacheService.instance.peekRecent(
              maxAge: const Duration(minutes: 20),
            ),
          );
          if (p == null) return null;
          return (lat: p.latitude, lng: p.longitude);
        },
      );
      unawaited(_mysteryBoxManager!.initialize());
    }

    if (_communityMysteryManager == null) {
      _communityMysteryManager = CommunityMysteryBoxMapManager(
        mapboxMap: mapboxMap,
        context: context,
        getUserLatLng: () {
          final p = LocationCacheService.pickNewer(
            _currentPositionObject,
            LocationCacheService.instance.peekRecent(
              maxAge: const Duration(minutes: 20),
            ),
          );
          if (p == null) return null;
          return (lat: p.latitude, lng: p.longitude);
        },
      );
      unawaited(_communityMysteryManager!.initialize());
    }

    if (_radarAlertsManager == null) {
      _radarAlertsManager = RadarAlertsMapManager(
        context: context,
        onDataChanged: () {
          if (mounted) setState(() {});
        },
      );
      unawaited(_radarAlertsManager!.initialize());
    }
  }
}

