// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapGeocodingNavMethods on _MapScreenState {
  Future<Point?> _getCoordinatesForDestination(String destination) async {
    try {
      // 1. Mai întâi verifică destinațiile predefinite (rapid)
      final predefinedCoordinates = _getPredefinedDestinationCoordinates(destination);
      if (predefinedCoordinates != null) {
        Logger.info('Destinație predefinită găsită: $destination');
        return predefinedCoordinates;
      }
      
      // 2. Dacă nu e predefinită, folosește geocoding API
      Logger.debug('Caut adresa cu geocoding: $destination');
      final coordinates = await _geocodeAddress(destination);
      
      if (coordinates != null) {
        Logger.info('Coordonate găsite cu geocoding: $destination');
        return coordinates;
      }
      
      // 3. ❌ NU FOLOSIM COORDONATE DEFAULT - Returnează null și gestionează eroarea
      Logger.warning('Nu am găsit coordonatele pentru: $destination');
      // Nu returnăm coordonate default - utilizatorul trebuie să specifice o adresă validă
      return null;
      
    } catch (e) {
      Logger.error('Eroare la găsirea coordonatelor: $e', error: e);
      // ❌ NU RETURNĂM COORDONATE DEFAULT
      return null;
    }
  }
  
  // 🗺️ Verifică destinațiile predefinite (rapid) - folosește baza de date extinsă
  Point? _getPredefinedDestinationCoordinates(String destination) {
    // ✅ FIX: Folosește baza de date locală extinsă pentru locații din București și Ilfov
    try {
      final location = BucharestLocationsDatabase.findLocation(destination);
      if (location != null) {
        Logger.info('Destinație predefinită găsită în baza de date: ${location['name']} (${location['category']})');
        return Point(
          coordinates: Position(
            location['longitude'] as double,
            location['latitude'] as double,
          ),
        );
      }
    } catch (e) {
      Logger.warning('Eroare la căutarea în baza de date: $e');
    }
    
    return null; // Nu e predefinită
  }
  
  // 🌍 Geocoding real pentru orice adresă din România (cu timeout și retry)
  Future<Point?> _geocodeAddress(String address) async {
    try {
      // Adaugă "România" la adresă dacă nu e specificat
      final fullAddress = address.toLowerCase().contains('românia') || 
                          address.toLowerCase().contains('romania')
        ? address 
        : '$address, România';
      
      Logger.debug('Geocoding pentru: $fullAddress');
      
      // Folosește OpenStreetMap Nominatim API (gratuit)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(fullAddress)}'
        '&format=json'
        '&limit=1'
        '&countrycodes=ro'
        '&addressdetails=1'
      );
      
      // ✅ TIMEOUT PENTRU GEOCODING (10 secunde)
      final response = await http
          .get(
            url,
            headers: const {
              // Nominatim (OSM) cere User-Agent identificabil — fără el rezultatele pot fi goale.
              'User-Agent': 'NabourApp/1.0 (Flutter; ride-sharing; ro)',
              'Accept-Language': 'ro,en',
            },
          )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Geocoding timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        
        if (results.isNotEmpty) {
          final result = results.first;
          final lat = double.parse(result['lat']);
          final lon = double.parse(result['lon']);
          
          // ✅ VALIDARE COORDONATE
          if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
            Logger.warning('Coordonate invalide pentru: $address');
            return null;
          }
          
          Logger.info('Geocoding reușit: $lat, $lon pentru $address');
          return Point(coordinates: Position(lon, lat));
        }
      }
      
      Logger.warning('Nu am găsit rezultate pentru: $address');
      return null;
      
    } on TimeoutException catch (e) {
      Logger.error('Geocoding timeout: $e', error: e);
      return null;
    } catch (e) {
      Logger.error('Eroare geocoding: $e', error: e);
      return null;
    }
  }
  
  /// Ac de compas pe hartă: gamalia (nord) verde; pivot spre sud — aceeași lățime/înălțime ca markerul Acasă (48×56).
  Future<Uint8List> _generateOrientationCompassNeedlePinBytes() async {
    final int w = _MapScreenState._androidPrivatePinOverlayWidth.toInt();
    final int h = _MapScreenState._androidPrivatePinOverlayHeight.toInt();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    );
    final paint = Paint()..isAntiAlias = true;

    final double cx = w / 2.0;
    const double northY = 7.0;
    final double southY = h - 3.0;
    final double midY = (northY + southY) / 2.0;
    const double halfW = 11.0;

    final northPath = Path()
      ..moveTo(cx, northY)
      ..lineTo(cx + halfW, midY)
      ..lineTo(cx - halfW, midY)
      ..close();
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF16A34A);
    canvas.drawPath(northPath, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xCC000000);
    canvas.drawPath(northPath, paint);

    final southPath = Path()
      ..moveTo(cx - halfW, midY)
      ..lineTo(cx + halfW, midY)
      ..lineTo(cx, southY)
      ..close();
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF78909C);
    canvas.drawPath(southPath, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xCC000000);
    canvas.drawPath(southPath, paint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return _MapScreenState._pngBytesOrMinimalFallback(
      byteData,
      '_generateOrientationCompassNeedlePinBytes',
    );
  }

  /// Fallback când lipsește PNG-ul: casă stilizată într-un cerc (glob de sticlă) — **nu** ac compas.
  Future<Uint8List> _generateSavedHomeGlassHouseFallbackPinBytes() async {
    final int w = _MapScreenState._androidPrivatePinOverlayWidth.toInt();
    final int h = _MapScreenState._androidPrivatePinOverlayHeight.toInt();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    );
    final paint = Paint()..isAntiAlias = true;

    final double cx = w / 2.0;
    final double cy = h / 2.0 - 2.0;
    const double r = 19.0;

    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0x5538BDF8);
    canvas.drawCircle(Offset(cx, cy), r, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF38BDF8);
    canvas.drawCircle(Offset(cx, cy), r, paint);

    final houseBody = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + 4),
        width: 16,
        height: 12,
      ),
      const Radius.circular(2),
    );
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFEA580C);
    canvas.drawRRect(houseBody, paint);

    final roof = Path()
      ..moveTo(cx - 12, cy - 2)
      ..lineTo(cx + 12, cy - 2)
      ..lineTo(cx, cy - 12)
      ..close();
    paint.color = const Color(0xFFDC2626);
    canvas.drawPath(roof, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0x99000000);
    canvas.drawPath(roof, paint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return _MapScreenState._pngBytesOrMinimalFallback(
      byteData,
      '_generateSavedHomeGlassHouseFallbackPinBytes',
    );
  }

  // 🗺️ Generează programatic un pin icon (roșu cu punct alb)
  Future<Uint8List> _generatePinBytes() async {
    const int w = 64, h = 88;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
    final paint = Paint()..isAntiAlias = true;

    // Corp pin (cerc în top + triunghi jos)
    final path = Path()
      ..addOval(Rect.fromCircle(center: const Offset(32, 32), radius: 28))
      ..moveTo(20, 48)
      ..lineTo(32, h.toDouble())
      ..lineTo(44, 48)
      ..close();
    paint.color = const Color(0xFFEF4444); // red-500
    canvas.drawPath(path, paint);

    // Punct alb interior
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(32, 30), 10, paint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return _MapScreenState._pngBytesOrMinimalFallback(byteData, '_generatePinBytes');
  }

  // 🗺️ Adaugă marker pentru destinație pe hartă
  Future<void> _addDestinationMarker(Point coordinates, String title) async {
    try {
      // Inițializează managerul dacă nu există (ex: în modul preview înainte de calculul rutei)
      _routeMarkersAnnotationManager ??= await _mapboxMap?.annotations
          .createPointAnnotationManager(id: 'route-markers-manager');

      // Șterge marker-ele anterioare de destinație
      await _routeMarkersAnnotationManager?.deleteAll();

      final Uint8List imageList = await _generatePinBytes();
      final destImgOk = _mapboxMap != null && await _registerStyleImageFromPng('nabour_dest_pin', imageList);
      final destinationMarkerOptions = PointAnnotationOptions(
        geometry: coordinates,
        iconImage: destImgOk ? 'nabour_dest_pin' : null,
        // image: imageList, // DO NOT USE
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
      );

      // Adaugă marker-ul pe hartă
      await _routeMarkersAnnotationManager?.create(destinationMarkerOptions);

      Logger.info('Marker destinație adăugat: $title');
    } catch (e) {
      Logger.error('Eroare la adăugarea marker-ului destinație: $e', error: e);
    }
  }

  Future<void> _updateParkingMarkers(List<ParkingSpotEvent> spots) async {
    if (_mapboxMap == null || !mounted) return;

    if (_parkingSwapAnnotationManager == null) {
      _parkingSwapAnnotationManager = await _mapboxMap?.annotations.createPointAnnotationManager(
        id: 'parking-swap-manager',
      );
      // Modern Mapbox Tap Events
      _parkingSwapAnnotationManager?.tapEvents(onTap: (annotation) {
        _onParkingMarkerTapped(annotation.id);
      });
    }

    _parkingIconInFlight ??= _generateParkingIcon(false);
    final iconBytes = await _parkingIconInFlight!;

    final spotIds = spots.map((s) => s.id).toSet();
    final toRemove = _parkingSpotAnnotations.keys.where((id) => !spotIds.contains(id)).toList();
    for (final id in toRemove) {
      final ann = _parkingSpotAnnotations.remove(id);
      if (ann != null) {
        _parkingSwapAnnotationManager?.delete(ann);
      }
    }

    for (final spot in spots) {
      if (_parkingSpotAnnotations.containsKey(spot.id)) {
        final ann = _parkingSpotAnnotations[spot.id]!;
        ann.geometry = MapboxUtils.createPoint(spot.lat, spot.lng);
        _parkingSwapAnnotationManager?.update(ann);
      } else {
        final pkgImgOk = await _registerStyleImageFromPng('nabour_parking_swap', iconBytes);
        final options = PointAnnotationOptions(
          geometry: MapboxUtils.createPoint(spot.lat, spot.lng),
          iconImage: pkgImgOk ? 'nabour_parking_swap' : null,
          // image: iconBytes, // DO NOT USE
          iconSize: 0.8,
          textField: 'LOC LIBER',
          textColor: Colors.amber.toARGB32(),
          textHaloColor: Colors.black.toARGB32(),
          textHaloWidth: 2.0,
          textSize: 10,
          textOffset: [0.0, 2.5],
        );
        final ann = await _parkingSwapAnnotationManager?.create(options);
        if (ann != null) {
          _parkingSpotAnnotations[spot.id] = ann;
        }
      }
    }
  }

  void _onParkingMarkerTapped(String internalAnnotationId) {
    // ID-ul intern Mapbox (ex: "point_123") se asociază cu spot.id-ul din Firestore
    final firestoreId = _parkingSpotAnnotations.entries
        .where((e) => e.value.id == internalAnnotationId)
        .map((e) => e.key)
        .firstOrNull;

    if (firestoreId != null) {
      _showParkingSwapDialog(firestoreId);
    }
  }

  
  // ═══════════════════════════════════════════════════════════════════
  // NAVIGARE INTERNĂ MAPBOX — fără a deschide o fereastră separată
  // ═══════════════════════════════════════════════════════════════════

  /// Pornește navigarea internă: calculează ruta, o desenează pe harta Mapbox
  /// principală și urmărește utilizatorul cu camera + TTS turn-by-turn.
  Future<void> _startInAppNavigation(double destLat, double destLng, String label) async {
    if (!mounted || _mapboxMap == null) return;

    // Inițializare TTS la prima utilizare
    if (_routeCtrl.navTts == null) {
      final t = FlutterTts();
      try {
        await t.setLanguage('ro-RO');
        await t.setSpeechRate(0.42);
        await t.awaitSpeakCompletion(true);
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      _routeCtrl.navTts = t;
    }

    // Oprește sesiunea anterioară dacă există
    await _stopInAppNavigation(announce: false);

    setState(() {
      _routeCtrl.inAppNavActive = true;
      _rideAddressSheetVisible = true;
      _routeCtrl.navDestLat = destLat;
      _routeCtrl.navDestLng = destLng;
      _routeCtrl.navDestLabel = label;
      _routeCtrl.navHasArrived = false;
      _routeCtrl.navCurrentInstruction = AppLocalizations.of(context)!.mapCalculatingRoute;
      _routeCtrl.navRemainDistanceM = 0;
      _routeCtrl.navRemainEta = Duration.zero;
      _routeCtrl.navSteps = [];
      _routeCtrl.navStepIndex = 0;
      _routeCtrl.navLastSpokenStep = -1;
    });

    // Obținem poziția curentă
    final seed = await _navigationOriginSeedLatLng();
    final originLat = seed.lat;
    final originLng = seed.lng;
    if (originLat == null || originLng == null) {
      if (mounted) {
        setState(() {
          _routeCtrl.navCurrentInstruction = AppLocalizations.of(context)!.mapCannotGetLocationEnableGps;
        });
      }
      return;
    }

    // Calculăm ruta
    final route = await _routingService.getPointToPointRoutePreferOsm(
      startLat: originLat,
      startLng: originLng,
      endLat: destLat,
      endLng: destLng,
    );
    if (!mounted) return;

    if (route == null) {
      setState(() {
        _routeCtrl.navCurrentInstruction = AppLocalizations.of(context)!.mapRouteUnavailableCheckConnection;
      });
      return;
    }

    // Desenăm ruta pe harta Mapbox principală
    await _onRouteCalculated(route);
    if (!mounted) return;

    // Parsăm pașii pentru turn-by-turn
    try {
      final routes = route['routes'] as List?;
      if (routes != null && routes.isNotEmpty) {
        final legs = (routes.first as Map)['legs'] as List?;
        if (legs != null && legs.isNotEmpty) {
          final steps = (legs.first as Map)['steps'] as List?;
          if (steps != null) {
            _routeCtrl.navSteps = steps.map((s) => Map<String, dynamic>.from(s as Map)).toList();
          }
        }
        final r = routes.first as Map;
        final dist = (r['distance'] as num?)?.toDouble() ?? 0;
        final dur = (r['duration'] as num?)?.toDouble() ?? 0;
        setState(() {
          _routeCtrl.navRemainDistanceM = dist;
          _routeCtrl.navRemainEta = Duration(seconds: dur.round());
        });
      }
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }

    // Prima instrucțiune
    _navUpdateInstruction();
    unawaited(_navSpeakStep(force: true));

    // Abonare GPS
    _routeCtrl.navGpsSubscription = geolocator.Geolocator.getPositionStream(
      locationSettings: DeprecatedAPIsFix.createLocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen(_navGpsTick, onError: (_) {});

    Logger.info('Navigare internă pornită → $label ($destLat,$destLng)', tag: 'NAV_INTERNAL');
  }

  /// Actualizează instrucțiunea curentă din lista de pași.
  void _navUpdateInstruction() {
    if (_routeCtrl.navSteps.isEmpty) {
      setState(() => _routeCtrl.navCurrentInstruction = AppLocalizations.of(context)!.mapContinueOnRoute);
      return;
    }
    final i = _routeCtrl.navStepIndex.clamp(0, _routeCtrl.navSteps.length - 1);
    final step = _routeCtrl.navSteps[i];
    String text = '';
    final m = step['maneuver'];
    if (m is Map) text = m['instruction']?.toString().trim() ?? '';
    if (text.isEmpty) {
      final banners = step['banner_instructions'] ?? step['bannerInstructions'];
      if (banners is List && banners.isNotEmpty) {
        final pri = (banners.first as Map)['primary'];
        if (pri is Map) text = pri['text']?.toString().trim() ?? '';
      }
    }
    if (text.isEmpty) text = 'Continuă pe traseu.';
    if (mounted) setState(() => _routeCtrl.navCurrentInstruction = text);
  }

  /// Callback GPS în timp real — actualizează camera, ETA și detectează sosirea.
  Future<void> _navGpsTick(geolocator.Position pos) async {
    final navRawMps = pos.speed.isNaN || pos.speed < 0 ? 0.0 : pos.speed;
    final navFilteredMps = pos.speedAccuracy > 0 && navRawMps <= pos.speedAccuracy ? 0.0 : navRawMps;
    ContextEngineService.instance.feedSpeed(navFilteredMps);
    if (!mounted || !_routeCtrl.inAppNavActive || _routeCtrl.navHasArrived) return;

    final destLat = _routeCtrl.navDestLat;
    final destLng = _routeCtrl.navDestLng;
    if (destLat == null || destLng == null) return;

    final distToDestM = geolocator.Geolocator.distanceBetween(
      pos.latitude, pos.longitude, destLat, destLng,
    );

    // Actualizam distanta si ETA
    final speedMs = pos.speed > 0.5 ? pos.speed : 8.33; // default 30 km/h
    final etaSec = (distToDestM / speedMs).round();
    if (mounted) {
      setState(() {
        _routeCtrl.navRemainDistanceM = distToDestM;
        _routeCtrl.navRemainEta = Duration(seconds: etaSec);
      });
    }

    // Avansăm pasul: găsim cel mai aproape pas din traseu
    if (_routeCtrl.navSteps.isNotEmpty) {
      for (int i = _routeCtrl.navStepIndex; i < _routeCtrl.navSteps.length - 1; i++) {
        final step = _routeCtrl.navSteps[i];
        final geom = step['geometry'];
        if (geom is Map) {
          final coords = geom['coordinates'];
          if (coords is List && coords.isNotEmpty) {
            final endCoord = coords.last;
            if (endCoord is List && endCoord.length >= 2) {
              final stepEndLat = (endCoord[1] as num).toDouble();
              final stepEndLng = (endCoord[0] as num).toDouble();
              final dToStepEnd = geolocator.Geolocator.distanceBetween(
                pos.latitude, pos.longitude, stepEndLat, stepEndLng,
              );
              if (dToStepEnd < 35) {
                if (_routeCtrl.navStepIndex != i + 1) {
                  setState(() => _routeCtrl.navStepIndex = i + 1);
                  _navUpdateInstruction();
                  unawaited(_navSpeakStep(force: false));
                }
                break;
              }
            }
          }
        }
      }
    }

    // Detectare sosire (30 m)
    if (distToDestM <= 30) {
      unawaited(_navArrival());
      return;
    }

    // Camera urmărește userul
    final map = _mapboxMap;
    if (map == null || !mounted) return;
    double bearing = pos.heading;
    if (bearing < 0 || bearing > 360 || bearing.isNaN || pos.speed < 1.0) bearing = 0;
    try {
      await map.flyTo(
        CameraOptions(
          center: MapboxUtils.createPoint(pos.latitude, pos.longitude),
          zoom: 16.5,
          bearing: bearing,
          pitch: 0.0,
        ),
        MapAnimationOptions(duration: 600),
      );
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
  }

  Future<void> _navSpeakStep({required bool force}) async {
    final tts = _routeCtrl.navTts;
    if (tts == null || !mounted) return;
    final text = _routeCtrl.navCurrentInstruction;
    if (text.isEmpty || (!force && _routeCtrl.navLastSpokenStep == _routeCtrl.navStepIndex)) return;
    _routeCtrl.navLastSpokenStep = _routeCtrl.navStepIndex;
    try {
      await tts.stop();
      await tts.speak(text);
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
  }

  Future<void> _navArrival() async {
    final l10n = AppLocalizations.of(context)!;
    if (_routeCtrl.navHasArrived || !mounted) return;
    setState(() {
      _routeCtrl.navHasArrived = true;
      _routeCtrl.navCurrentInstruction = l10n.mapArrivalInstruction;
    });
    HapticFeedback.heavyImpact();
    try { await _routeCtrl.navTts?.stop(); await _routeCtrl.navTts?.speak(l10n.mapArrivalInstruction); } catch (e) { Logger.debug('MapScreen TTS arrival failed: $e', tag: 'MAP'); }
    await _stopInAppNavigation(announce: false);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.place_rounded, size: 48, color: Theme.of(ctx).colorScheme.primary),
        title: Text(l10n.mapArrivedTitle),
        content: Text(
          AppLocalizations.of(context)!.mapArrivedAtDestination(_routeCtrl.navDestLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  /// Oprește navigarea internă și resetează starea.
  Future<void> _stopInAppNavigation({bool announce = true}) async {
    await _routeCtrl.navGpsSubscription?.cancel();
    _routeCtrl.navGpsSubscription = null;
    _routeCtrl.navEtaTimer?.cancel();
    _routeCtrl.navEtaTimer = null;
    if (announce) {
      try { await _routeCtrl.navTts?.stop(); } catch (e) { Logger.debug('MapScreen TTS stop failed: $e', tag: 'MAP'); }
    }
    if (mounted) {
      setState(() {
        _routeCtrl.inAppNavActive = false;
        _routeCtrl.navDestLat = null;
        _routeCtrl.navDestLng = null;
        _routeCtrl.navDestLabel = '';
        _routeCtrl.navCurrentInstruction = '';
        _routeCtrl.navRemainDistanceM = 0;
        _routeCtrl.navRemainEta = Duration.zero;
        _routeCtrl.navSteps = [];
        _routeCtrl.navStepIndex = 0;
        _routeCtrl.navLastSpokenStep = -1;
        _routeCtrl.navHasArrived = false;
      });
    }
    // Reset cameră la modul normal
    try {
      final p = _currentPositionObject;
      if (p != null && _mapboxMap != null && mounted) {
        await _mapboxMap!.flyTo(
          CameraOptions(
            center: MapboxUtils.createPoint(p.latitude, p.longitude),
            zoom: 14.0,
            bearing: 0,
            pitch: 0,
          ),
          MapAnimationOptions(duration: 800),
        );
      }
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    // Curăță ruta de pe hartă
    unawaited(_onRouteCalculated(null));
    Logger.info('Navigare internă oprită.', tag: 'NAV_INTERNAL');
  }
}
