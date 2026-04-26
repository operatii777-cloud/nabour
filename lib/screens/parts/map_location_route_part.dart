// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapLocationRouteMethods on _MapScreenState {
  void _freezeMapWidgetCameraIfNeeded() {
    if (_mapWidgetFrozenCamera != null) return;
    // Nu îngheța camera în zoom „overview” înainte de secvența „din spațiu” (altfel dispar globul).
    if (!_mapSpaceIntroDone && !AppDrawer.lowDataMode) return;
    final p = _currentPositionObject;
    if (p == null) return;
    _mapWidgetFrozenCamera = CameraOptions(
      center: MapboxUtils.createPoint(p.latitude, p.longitude),
      zoom: _overviewZoomForLatitude(p.latitude),
    );
  }

  CameraOptions get _mapWidgetCameraOptions {
    if (_mapWidgetFrozenCamera != null) return _mapWidgetFrozenCamera!;
    // Prima deschidere: glob (zoom foarte mic), apoi [ _runSpaceIntroFlyFromGlobe ] face flyTo spre user.
    if (!_mapSpaceIntroDone && !AppDrawer.lowDataMode) {
      final lat = _currentPositionObject?.latitude ?? 44.4268;
      final lng = _currentPositionObject?.longitude ?? 26.1025;
      return CameraOptions(
        center: MapboxUtils.createPoint(lat, lng),
        zoom: _MapScreenState._spaceIntroGlobeZoom,
        pitch: 0,
        bearing: 0,
      );
    }
    _mapWidgetFallbackCamera ??= CameraOptions(
      center: MapboxUtils.createPoint(44.4268, 26.1025),
      zoom: _overviewZoomForLatitude(44.4268),
      pitch: 0.0,
    );
    return _mapWidgetFallbackCamera!;
  }

  /// ðŸš€ PERFORMANÈšÄ‚: ObÈ›ine ultima locaÈ›ie cunoscutÄƒ IMEDIAT, fÄƒrÄƒ a aÈ™tepta hardware-ul GPS.
  /// Astfel, harta se va deschide deja centratÄƒ pe utilizator.
  Future<void> _tryPreloadLastKnownLocation() async {
    try {
      // 1. Prioritate: Locația pre-încărcată în SplashScreen (AppInitializer)
      final appInit = Provider.of<AppInitializer>(context, listen: false);
      geolocator.Position? pos = appInit.prefetchedPosition;

      // 2. Fallback: Last known position direct de la hardware
      pos ??= await geolocator.Geolocator.getLastKnownPosition();

      final fixedPos = pos;
      if (fixedPos != null && mounted) {
        setState(() {
          _currentPositionObject = fixedPos;
          _mapWidgetFallbackCamera = CameraOptions(
            center: MapboxUtils.createPoint(fixedPos.latitude, fixedPos.longitude),
            zoom: _overviewZoomForLatitude(fixedPos.latitude),
          );
        });
        unawaited(_updateUserMarker(centerCamera: false));
        unawaited(_updateCurrentStreetName());
        _ensureNeighborsListeningAfterPosition();
        _refreshNeighborhoodRequestBubbles();
      }
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
  }

  /// Locație pentru puck / stradă fără să mutăm camera (warmup acoperă încă harta).
  Future<void> _primeLocationWhileWarmup() async {
    if (_currentPositionObject != null && mounted) {
      try {
        LocationCacheService.instance.record(_currentPositionObject!);
        unawaited(_updateWeatherAndStyle(
          _currentPositionObject!.latitude,
          _currentPositionObject!.longitude,
        ));
        unawaited(_updateUserMarker(centerCamera: false));
        unawaited(_updateCurrentStreetName());
        _refreshNeighborhoodRequestBubbles();
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }
    try {
      final lastKnown = await geolocator.Geolocator.getLastKnownPosition().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (lastKnown != null && mounted) {
        LocationCacheService.instance.record(lastKnown);
        setState(() {
          _currentPositionObject = lastKnown;
        });
        unawaited(_updateWeatherAndStyle(
          lastKnown.latitude,
          lastKnown.longitude,
        ));
        unawaited(_updateUserMarker(centerCamera: false));
        unawaited(_updateCurrentStreetName());
        _refreshNeighborhoodRequestBubbles();
      }
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    await _getCurrentLocation(centerCamera: false);
  }

  /// După ce stilul e gata: fie fly animat din „spațiu” (glob) spre user, fie centrare clasică ~3 km.
  Future<void> _centerOnLocationOnMapReady({bool preferSpaceIntro = false}) async {
    if (_mapReadyCenterInFlight) return;
    _mapReadyCenterInFlight = true;
    try {
    if (_warmupBlocksCamera) {
      await _primeLocationWhileWarmup();
      return;
    }
    if (_startupCameraPrimed) return;
    _startupCameraPrimed = true;

    if (AppDrawer.lowDataMode || _mapboxMap == null) {
      _cinematicIntroLock = false;
    }

    bool attemptedSpaceIntro = false;
    if (!AppDrawer.lowDataMode &&
        !_mapSpaceIntroDone &&
        _mapboxMap != null &&
        (preferSpaceIntro || !_spaceIntroInFlight)) {
      attemptedSpaceIntro = true;
      final flew = await _runSpaceIntroFlyFromGlobe();
      if (flew) {
        await _getCurrentLocation(centerCamera: false);
        return;
      }
    }

    // 🔄 MIDDLEWARE SYNC: Verificăm dacă avem deja o stare în provider (ex. am trecut de la OSM)
    if (!mounted) return;
    final camSync = context.read<MapCameraProvider>();
    bool startupCentered = false;
    
    if (camSync.lastLat != null && camSync.lastLng != null) {
      startupCentered = true;
      // Starea este aplicată automat de setMapInstance/setOsmController,
      // deci aici doar marcăm ca centrat pentru fluxul de startup.
    } else if (_currentPositionObject != null && mounted && (_mapboxMap != null || _osmMapController != null)) {
      try {
        LocationCacheService.instance.record(_currentPositionObject!);
        await _centerCameraOnCurrentPosition();
        startupCentered = true;
        unawaited(_updateWeatherAndStyle(
          _currentPositionObject!.latitude,
          _currentPositionObject!.longitude,
        ));
        unawaited(_updateUserMarker(centerCamera: false));
        unawaited(_updateCurrentStreetName());
      } catch (_) { /* Map provider op — expected on style reload or missing layer */ }
    }

    try {
      final lastKnown = await geolocator.Geolocator.getLastKnownPosition().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (lastKnown != null && mounted) {
        LocationCacheService.instance.record(lastKnown);
        setState(() {
          _currentPositionObject = lastKnown;
          _freezeMapWidgetCameraIfNeeded();
        });
        unawaited(_updateWeatherAndStyle(
          lastKnown.latitude,
          lastKnown.longitude,
        ));
        if (!startupCentered) {
          await _centerCameraOnCurrentPosition();
          startupCentered = true;
        }
        unawaited(_updateUserMarker(centerCamera: false));
        unawaited(_updateCurrentStreetName());
      }
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }

    // Evităm un al treilea recenter la startup (produce bucle de zoom pe unele device-uri).
    await _getCurrentLocation(centerCamera: false);
    // Dacă warmup-ul s-a închis foarte devreme și nu aveam încă poziție, încercăm din nou fly-ul
    // imediat ce prima locație validă devine disponibilă.
    if (attemptedSpaceIntro &&
        !_mapSpaceIntroDone &&
        !AppDrawer.lowDataMode &&
        _currentPositionObject != null &&
        mounted &&
        _mapboxMap != null) {
      final flewLate = await _runSpaceIntroFlyFromGlobe();
      if (flewLate) {
        await _getCurrentLocation(centerCamera: false);
      }
    }
    _cinematicIntroLock = false;
    } finally {
      _mapReadyCenterInFlight = false;
    }
  }

  /// O singură dată la deschiderea hărții: de la zoom glob la vederea obișnuită (~3 km) peste locația userului.
  Future<bool> _runSpaceIntroFlyFromGlobe() async {
    if (_mapboxMap == null || !mounted) return false;
    if (_spaceIntroInFlight) return false;
    if (AppDrawer.lowDataMode) {
      setState(() => _mapSpaceIntroDone = true);
      _cinematicIntroLock = false;
      return false;
    }
    _spaceIntroInFlight = true;

    geolocator.Position? pos = _currentPositionObject;
    try {
      pos ??= await geolocator.Geolocator.getLastKnownPosition();
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }

    if (pos == null) {
      // Nu marcăm intro-ul ca "done": fără poziție la acest moment, retry-ul trebuie să rămână posibil.
      _spaceIntroInFlight = false;
      _cinematicIntroLock = false;
      return false;
    }

    final target = pos;

    LocationCacheService.instance.record(target);
    setState(() {
      _currentPositionObject = target;
    });
    unawaited(_updateUserMarker(centerCamera: false));
    unawaited(_updateCurrentStreetName());
    _ensureNeighborsListeningAfterPosition();
    _refreshNeighborhoodRequestBubbles();

    await Future.delayed(const Duration(milliseconds: _MapScreenState._spaceIntroPauseBeforeFlyMs));
    if (!mounted || _mapboxMap == null) {
      _spaceIntroInFlight = false;
      _cinematicIntroLock = false;
      return false;
    }

    try {
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: MapboxUtils.createPoint(target.latitude, target.longitude),
          zoom: _overviewZoomForLatitude(target.latitude),
          pitch: 0.0,
          bearing: 0.0,
        ),
        MapAnimationOptions(duration: _MapScreenState._spaceIntroFlyDurationMs),
      );
    } catch (e) {
      Logger.warning('Space intro flyTo failed: $e', tag: 'MAP');
    }

    if (!mounted) {
      _spaceIntroInFlight = false;
      _cinematicIntroLock = false;
      return false;
    }

    setState(() {
      _mapSpaceIntroDone = true;
      _mapWidgetFallbackCamera = CameraOptions(
        center: MapboxUtils.createPoint(target.latitude, target.longitude),
        zoom: _overviewZoomForLatitude(target.latitude),
        pitch: 0.0,
      );
    });

    unawaited(_updateWeatherAndStyle(target.latitude, target.longitude));
    // Așteptăm markerul după fly — altfel reaplicarea puck 3D rămânea în cursă în spatele altor evenimente.
    await _updateUserMarker(centerCamera: false);
    unawaited(_updateCurrentStreetName());
    _cinematicIntroLock = false;
    _spaceIntroInFlight = false;
    return true;
  }

  Future<void> _centerCameraOnCurrentPosition() async {
    if (_cinematicIntroLock) return;
    if (!mounted || (_mapboxMap == null && _osmMapController == null)) return;

    // 🔄 MIDDLEWARE SYNC: Folosim direct providerul pentru recentrare (unifică Mapbox/OSM)
    await context.read<MapCameraProvider>().centerOnCurrentPosition();
    if (!mounted) return;
    
    // Sincronizăm starea locală cu cea a providerului
    final camSync = context.read<MapCameraProvider>();
    _followingEnabled = camSync.isFollowingUser;
    
    if (mounted) {
      unawaited(_updateUserMarker(centerCamera: false));
    }
  }

  /// Returnează viteza în km/h folosind cea mai fiabilă sursă disponibilă.
  /// Prioritate: GPS cu acuratețe confirmată (acc > 0) → delta-poziție.
  /// Când acc == 0 (chipset nu furnizează acuratețe), NU folosim viteza brută GPS
  /// deoarece unele chipseturi (ex. Lenovo) raportează 15-18 km/h zgomot Doppler
  /// când dispozitivul e staționar.
  double? _computeReliableSpeedKph(geolocator.Position position) {
    final rawMps = position.speed;
    final acc = position.speedAccuracy; // m/s; > 0 = chip GPS a furnizat acuratețe

    // acc == 0.0 pe Android = "info indisponibilă", nu "eroare zero".
    if (!rawMps.isNaN && rawMps >= 0 && acc > 0) {
      return rawMps <= acc ? 0.0 : rawMps * 3.6;
    }

    // Fallback: calcul din delta pozitii consecutive.
    final prev = _previousPositionObject;
    if (prev == null) return null;
    final elapsedMs = position.timestamp.difference(prev.timestamp).inMilliseconds;
    if (elapsedMs < 300 || elapsedMs > 12000) return null;
    final distM = geolocator.Geolocator.distanceBetween(
      prev.latitude, prev.longitude,
      position.latitude, position.longitude,
    );
    return (distM / (elapsedMs / 1000.0)) * 3.6;
  }

  void _updateLiveSpeedFromPosition(geolocator.Position position) {
    if (!mounted) return;
    final rawMps = position.speed;
    if (!rawMps.isNaN && rawMps >= 0) {
      final acc = position.speedAccuracy;
      if (acc > 0) {
        // Chipul GPS a furnizat acuratețe — filtrăm zgomotul Doppler.
        final filteredMps = rawMps <= acc ? 0.0 : rawMps;
        setState(() => _currentSpeedKph = (filteredMps * 3.6).clamp(0.0, 220.0));
        return;
      }
      // acc == 0: chipsetul nu furnizează acuratețe — nu ne bazăm pe viteza brută GPS.
      // Cădem pe delta-poziții (mai jos), imune la zgomotul Doppler.
    }
    final kph = _computeReliableSpeedKph(position);
    if (kph == null) return;
    setState(() => _currentSpeedKph = kph.clamp(0.0, 220.0));
  }

  Future<void> _maybeAutoFollowDriver(geolocator.Position position) async {
    if (!mounted) return;
    if (_mapboxMap == null && _osmMapController == null) return;
    if (!_followingEnabled) return;
    if (_cinematicIntroLock || _spaceIntroInFlight || _warmupBlocksCamera) return;
    if (_isRadarMode || _rideAddressSheetVisible || _universalSearchOpen) return;
    if (_isDestinationPreviewMode) return;

    final targetLat = position.latitude;
    final targetLng = position.longitude;
    final targetZoom = _liveCameraZoom.isNaN
        ? _overviewZoomForLatitude(targetLat)
        : _liveCameraZoom.clamp(15.2, 18.8);

    try {
      _followEaseInFlight = true;

      if (mounted && _showRecenterBtn) {
        setState(() => _showRecenterBtn = false);
      }

      // ── Mapbox Move ────────────────────────────────────────────────────────
      if (_mapboxMap != null) {
        unawaited(_mapboxMap!.easeTo(
          CameraOptions(
            center: MapboxUtils.createPoint(targetLat, targetLng),
            zoom: targetZoom,
          ),
          MapAnimationOptions(duration: 800),
        ));
      }

      // ── OSM Move ───────────────────────────────────────────────────────────
      if (_osmMapController != null) {
        _animatedMoveOsm(
          ll.LatLng(targetLat, targetLng),
          targetZoom,
          durationMs: 700, // Mai rapid pentru OSM
        );
      }

    } catch (e) {
      Logger.debug('Auto-follow error: $e', tag: 'MAP');
    } finally {
      Future.delayed(const Duration(milliseconds: 650), () {
        _followEaseInFlight = false;
      });
    }
  }

  /// Origine pentru [PointNavigationScreen]: puck GPS → cache → centrul camerei hărții.
  Future<({double? lat, double? lng})> _navigationOriginSeedLatLng() async {
    final p = _currentPositionObject;
    if (p != null) {
      return (lat: p.latitude, lng: p.longitude);
    }
    final cached = LocationCacheService.instance.peekRecent(
      maxAge: const Duration(minutes: 10),
    );
    if (cached != null) {
      return (lat: cached.latitude, lng: cached.longitude);
    }
    final map = _mapboxMap;
    if (map != null && mounted) {
      try {
        final cam = await map.getCameraState();
        final lat = cam.center.coordinates.lat.toDouble();
        final lng = cam.center.coordinates.lng.toDouble();
        Logger.info(
          'POINT_NAV seed: centrul camerei hărții (fără GPS încă) '
          '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}',
          tag: 'MAP',
        );
        return (lat: lat, lng: lng);
      } catch (e) {
        Logger.debug('navigationOriginSeed camera: $e');
      }
    }
    return (lat: null, lng: null);
  }

  Future<void> _getCurrentLocation({bool centerCamera = false}) async {
    try {
      // 🚀 PERFORMANȚĂ: Timeout pentru verificarea permisiunilor
      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission()
          .timeout(const Duration(seconds: 8), onTimeout: () {
        Logger.warning('Permission check timeout');
        return geolocator.LocationPermission.denied;
      });
      
      if (permission == geolocator.LocationPermission.denied) {
        permission = await PermissionManager().requestLocationPermission();
        
        if (permission != geolocator.LocationPermission.whileInUse && 
            permission != geolocator.LocationPermission.always) {
          return;
        }
      }
      
      // 🚀 PERFORMANȚĂ: Timeout pentru obținerea locației
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        ),
      ).timeout(const Duration(seconds: 18), onTimeout: () {
        throw TimeoutException('Location request timeout');
      });
      
      if (mounted) {
        LocationCacheService.instance.record(position);
        setState(() {
          _currentPositionObject = position;
          _freezeMapWidgetCameraIfNeeded();
        });
        unawaited(_updateWeatherAndStyle(
          position.latitude,
          position.longitude,
        ));
        if (centerCamera && !_cinematicIntroLock) {
          await _centerCameraOnCurrentPosition();
        }
        unawaited(_updateUserMarker(centerCamera: false));
        unawaited(_syncMapOrientationPinAnnotation());
        unawaited(_updateCurrentStreetName());
        _ensureNeighborsListeningAfterPosition();
        _refreshNeighborhoodRequestBubbles();
      }
    } catch (e) {
      Logger.debug("Could not get current location: $e");
      // 🚀 PERFORMANȚĂ: Încercăm să folosim ultima locație cunoscută
      try {
        final lastKnownPosition = await geolocator.Geolocator.getLastKnownPosition()
            .timeout(const Duration(seconds: 3));
        if (lastKnownPosition != null && mounted) {
          LocationCacheService.instance.record(lastKnownPosition);
          setState(() {
            _currentPositionObject = lastKnownPosition;
            _freezeMapWidgetCameraIfNeeded();
          });
          unawaited(_updateWeatherAndStyle(
            lastKnownPosition.latitude,
            lastKnownPosition.longitude,
          ));
          if (centerCamera && !_cinematicIntroLock) {
            await _centerCameraOnCurrentPosition();
          }
          unawaited(_updateUserMarker(centerCamera: false));
          unawaited(_syncMapOrientationPinAnnotation());
          _ensureNeighborsListeningAfterPosition();
          _refreshNeighborhoodRequestBubbles();
        }
      } catch (fallbackError) {
        Logger.debug("Could not get last known location: $fallbackError");
      }
    }
  }

  /// Actualizează vremea pentru overlay (max ~1 dată / 60 min). Stilul hărții = doar tema UI.
  Future<void> _updateWeatherAndStyle(double latitude, double longitude) async {
    if (_weatherLoading) return;
    final now = DateTime.now();
    if (_lastWeatherUpdate != null && now.difference(_lastWeatherUpdate!) < const Duration(minutes: 60)) return;

    setState(() => _weatherLoading = true);
    try {
      final data = await OpenMeteoService().fetchCurrentWeather(latitude: latitude, longitude: longitude);
      if (data != null && mounted) {
        setState(() {
          _weatherTemp = data['temp'];
          _weatherType = _getWeatherTypeFromCode(data['weatherCode']);
          _lastWeatherUpdate = now;
          _weatherLoading = false;
        });
        // Stilul hărții nu se mai schimbă automat după zi/noapte meteo — doar din tema UI (user).
      }
    } catch (e) {
      Logger.error('Weather update failed: $e');
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  WeatherType _getWeatherTypeFromCode(int code) {
    if (code == 0) return WeatherType.sunny;
    if (code >= 1 && code <= 3) return WeatherType.cloudy;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return WeatherType.rainy;
    if (code >= 71 && code <= 77) return WeatherType.snowy;
    if (code >= 95) return WeatherType.thunderstorm;
    return WeatherType.none;
  }

  static const Set<String> _activeRideStatusesForTelemetry = {
    'accepted',
    'arrived',
    'in_progress',
    'driver_found',
  };

  /// Context pentru `telemetry/active_rides/{rideId}` când șoferul are cursă activă.
  ({String rideId, String passengerId})? _activeRideLocationContext() {
    final ride = _currentActiveRide;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (ride == null || uid == null) return null;
    if (ride.driverId != uid) return null;
    if (!_activeRideStatusesForTelemetry.contains(ride.status)) return null;
    return (rideId: ride.id, passengerId: ride.passengerId);
  }

  void _pushDriverLocationToBackend(
    geolocator.Position position, {
    double? bearing,
  }) {
    final ctx = _activeRideLocationContext();
    _firestoreService.updateDriverLocation(
      position,
      bearing: bearing,
      activeRideId: ctx?.rideId,
      activeRidePassengerId: ctx?.passengerId,
    );
  }

  Future<void> _pushDriverLocationToBackendAwait(geolocator.Position position) async {
    _pushDriverLocationToBackend(position);
  }

  // ✅ ÎMBUNĂTĂȚIT: Adaptive GPS — high accuracy în mișcare, low-power la static.
  void _startDriverLocationUpdates({bool lowPower = false}) {
    _stopLocationUpdates();
    _driverGpsInLowPowerMode = lowPower;

    // AndroidSettings: interval minim de timp + filtru distanță.
    // intervalDuration garantează update-uri periodice chiar când șoferul stă pe loc,
    // astfel vitezometrul revine la 0 corect la semafoare.
    final locationSettings = lowPower
        ? geolocator.AndroidSettings(
            accuracy: geolocator.LocationAccuracy.medium,
            distanceFilter: 5,
            intervalDuration: const Duration(seconds: 2),
          )
        : geolocator.AndroidSettings(
            accuracy: geolocator.LocationAccuracy.best,
            distanceFilter: 0,
            intervalDuration: const Duration(milliseconds: 800),
          );

    // ✅ CURSOR FIX: Timer cu background execution
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!mounted) return;

      if (_isDriverAvailable && _currentRole == UserRole.driver) {
        unawaited(_updateDriverLocationInBackground());
      }

      // Social map: vizibilitate vecini sau șofer disponibil (fără Ghost Mode).
      if (_wantsNeighborSocialPublish && _currentPositionObject != null) {
        _publishNeighborSocialMapFreshUnawaited(_currentPositionObject!);
      }
    });

    // Pornim ascultarea stream-ului pentru mișcări în timp real
    _positionSubscription = geolocator.Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((geolocator.Position position) {
      // Calculăm viteza corectată ÎNAINTE de a alimenta ContextEngine,
      // astfel starea (stationary/walking/driving) reflectă viteza reală, nu zero-ul fals al GPS.
      _updateLiveSpeedFromPosition(position);
      ContextEngineService.instance.feedSpeed(_currentSpeedKph / 3.6);
      
      // 1) LOCAL (fluid): actualizÄƒm starea hÄƒrÈ›ii la fiecare tick GPS util.
      _previousPositionObject = _currentPositionObject;
      if (mounted) {
        setState(() {
          _currentPositionObject = position;
          _freezeMapWidgetCameraIfNeeded();
        });
      }

      // Recentrare cinematica la PORNIRE (doar dacÄƒ este prima locaÈ›ie bunÄƒ È™i nu suntem lock-uiÈ›i)
      if (!_startupCameraPrimed && !_cinematicIntroLock && mounted) {
        unawaited(_centerOnLocationOnMapReady());
      }

      if (_shouldRunFullUserMarkerRedrawForGps(position)) {
        unawaited(_updateUserMarker(centerCamera: false));
      }

      if (!mounted || !_isDriverAvailable || _currentRole != UserRole.driver) {
        return;
      }

      final snappedPosition = _applyRoadSnapping(position);
      LocationCacheService.instance.record(snappedPosition);
      unawaited(_maybeAutoFollowDriver(snappedPosition));

      // 2) Adaptive GPS mode: comutăm între low-power și high-accuracy bazat pe viteză.
      final speedKph = (position.speed >= 0 && !position.speed.isNaN)
          ? position.speed * 3.6
          : _currentSpeedKph;
      final shouldBeLowPower = speedKph < _MapScreenState._kDriverMoveThresholdKph - _MapScreenState._kDriverMoveHysteresisKph;
      final shouldBeHighPower = speedKph >= _MapScreenState._kDriverMoveThresholdKph;

      if (_driverGpsInLowPowerMode && shouldBeHighPower) {
        // Trecem în mișcare → restart stream high-accuracy (cu debounce 3s anti-oscilație)
        _driverAdaptiveGpsDebounce?.cancel();
        _driverAdaptiveGpsDebounce = Timer(const Duration(seconds: 3), () {
          if (!mounted || !_isDriverAvailable || _currentRole != UserRole.driver) return;
          Logger.debug('Driver GPS: low-power → high-accuracy (${speedKph.toStringAsFixed(1)} km/h)', tag: 'GPS');
          _startDriverLocationUpdates(lowPower: false);
        });
      } else if (!_driverGpsInLowPowerMode && shouldBeLowPower) {
        // Stăm pe loc → coborâm la low-power (cu debounce 8s ca să nu triggere la opriri scurte)
        _driverAdaptiveGpsDebounce?.cancel();
        _driverAdaptiveGpsDebounce = Timer(const Duration(seconds: 8), () {
          if (!mounted || !_isDriverAvailable || _currentRole != UserRole.driver) return;
          Logger.debug('Driver GPS: high-accuracy → low-power (${speedKph.toStringAsFixed(1)} km/h)', tag: 'GPS');
          _startDriverLocationUpdates(lowPower: true);
        });
      } else {
        _driverAdaptiveGpsDebounce?.cancel();
      }

      // 3) CLOUD (ieftin): păstrăm publish throttled, fără creșterea frecvenței externe.
      final now = DateTime.now();
      int currentInterval;
      final speed = position.speed;
      if (speed < 1.5) {
        currentInterval = _standingInterval;
      } else if (speed < 10) {
        currentInterval = _slowSpeedInterval;
      } else {
        currentInterval = _highSpeedInterval;
      }

      if (_lastUpdateTime == null || now.difference(_lastUpdateTime!).inSeconds >= currentInterval) {
        Logger.debug('--> Sending location update. Speed: ${speed.toStringAsFixed(2)} m/s. Interval: $currentInterval s.');

        // Bearing are sens doar în mișcare.
        final movingBearing = snappedPosition.speed >= 0.5 ? snappedPosition.heading : null;
        _pushDriverLocationToBackend(snappedPosition, bearing: movingBearing);
        _updateDriverRideEstimates(snappedPosition);
        _publishNeighborSocialMapFreshUnawaited(snappedPosition);
        unawaited(_maybePollMagicEventsThrottled());
        _refreshNeighborhoodRequestBubbles();
        _lastUpdateTime = now;
      }
    }, onError: (error) {
      Logger.error("Eroare la stream-ul de locație: $error", error: error);
    });

    Logger.info('▶ Started location stream');
  }

  /// Pasager sau șofer indisponibil: stream ușor ca GPS-ul să aibă deja fix când deschizi navigarea la punct.
  void _ensurePassiveLocationWarmupIfNeeded() {
    if (!mounted) return;
    if (_passengerWarmupSubscription != null) return;
    if (_currentRole == UserRole.driver && _isDriverAvailable) return;

    try {
      _passengerWarmupSubscription =
          geolocator.Geolocator.getPositionStream(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.medium,
          // Mai fluid local pentru markerul pasager, fără impact pe publish cloud.
          distanceFilter: 8,
        ),
      ).listen(
        (geolocator.Position p) {
          // Filtrăm zgomotul Doppler GPS (ex. Lenovo ~16 km/h staționar).
          final rawMps = p.speed.isNaN || p.speed < 0 ? 0.0 : p.speed;
          final filteredMps = p.speedAccuracy > 0 && rawMps <= p.speedAccuracy ? 0.0 : rawMps;
          ContextEngineService.instance.feedSpeed(filteredMps);
          LocationCacheService.instance.record(p);
          if (!mounted) return;
          if (_currentRole == UserRole.driver && _isDriverAvailable) return;
          setState(() {
            _currentPositionObject = p;
            _freezeMapWidgetCameraIfNeeded();
          });
          if (_shouldRunFullUserMarkerRedrawForGps(p)) {
            unawaited(_updateUserMarker(centerCamera: false));
            if (_useAndroidFlutterUserMarkerOverlay) {
              unawaited(_projectAndroidUserMarkerOverlay());
            }
          }
          unawaited(_updateCurrentStreetName(throttle: true));
          unawaited(_maybeAutoFollowDriver(p));
          unawaited(_maybePollMagicEventsThrottled());

          // 🛰️ NOU: Publicăm locația către vecini în timp real (dacă suntem vizibili)
          if (_isVisibleToNeighbors) {
            _publishNeighborSocialMapFreshUnawaited(p);
          }

          _ensureNeighborsListeningAfterPosition();
          _refreshNeighborhoodRequestBubbles();
        },
        onError: (Object e) {
          Logger.warning('Passive GPS warmup: $e', tag: 'MAP');
        },
      );
      Logger.info('Passive GPS warmup stream started', tag: 'MAP');
    } catch (e) {
      Logger.warning('Passive GPS warmup failed: $e', tag: 'MAP');
    }
  }

  // ✅ ÎMBUNĂTĂȚIT: Oprește și stream-ul și timer-ul
  void _stopLocationUpdates() {
    // Anulăm debounce-ul de tranziție adaptive GPS înainte de orice cancel stream.
    _driverAdaptiveGpsDebounce?.cancel();
    _driverAdaptiveGpsDebounce = null;
    _driverGpsInLowPowerMode = false;

    if (_passengerWarmupSubscription != null) {
      _passengerWarmupSubscription!.cancel();
      _passengerWarmupSubscription = null;
      Logger.debug('Stopped passive GPS warmup stream');
    }
    if (_positionSubscription != null) {
      _positionSubscription!.cancel();
      _positionSubscription = null;
      Logger.debug('⏹ Stopped location stream');
    }
    
    // ✅ ADĂUGAT: Oprește și timer-ul constant
    if (_locationUpdateTimer != null) {
      _locationUpdateTimer!.cancel();
      _locationUpdateTimer = null;
      Logger.debug('⏹ Stopped location timer');
    }

    // Social map periodic publish (pasager / driver indisponibil)
    if (_visibilityPublishTimer != null) {
      _visibilityPublishTimer!.cancel();
      _visibilityPublishTimer = null;
      Logger.debug('⏹ Stopped visibility publish timer');
    }
  }

  /// Timer 60s: poziție pentru backend + UI. Pe mobil 5s pentru [getCurrentPosition] e prea puțin
  /// (interior, GPS rece, throttling) → TimeoutException. Folosim ultima poziție recentă + timeout mai mare.
  Future<void> _updateDriverLocationInBackground() async {
    geolocator.Position? position;

    final last = await geolocator.Geolocator.getLastKnownPosition();
    if (last != null) {
      final age = DateTime.now().difference(last.timestamp);
      if (age <= const Duration(minutes: 2)) {
        position = last;
      }
    }

    if (position == null) {
      try {
        position = await geolocator.Geolocator.getCurrentPosition(
          locationSettings: DeprecatedAPIsFix.createLocationSettings(
            accuracy: geolocator.LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 25),
          ),
        );
      } on TimeoutException catch (e) {
        position = await geolocator.Geolocator.getLastKnownPosition();
        if (position == null) {
          Logger.warning(
            'Background location: timeout GPS (25s), fără ultima poziție — interior / permisiuni / GPS oprit.',
            tag: 'APP',
          );
          return;
        }
        Logger.debug(
          'Background location: după timeout folosim ultima poziție cunoscută ($e)',
          tag: 'MAP',
        );
      } catch (e) {
        position = await geolocator.Geolocator.getLastKnownPosition();
        if (position == null) {
          Logger.error(
            'Background location update failed: $e',
            error: e,
            tag: 'MAP',
          );
          return;
        }
        Logger.debug(
          'Background location: eroare getCurrentPosition, folosim ultima poziție: $e',
          tag: 'MAP',
        );
      }
    }

    try {
      final p = position;
      LocationCacheService.instance.record(p);
      await _pushDriverLocationToBackendAwait(p);

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _currentPositionObject = p;
            _freezeMapWidgetCameraIfNeeded();
          });
          _updateDriverRideEstimates(p);
          _refreshNeighborhoodRequestBubbles();
        });
      }

      Logger.debug('Background location update successful', tag: 'MAP');
    } catch (e) {
      Logger.error(
        'Background location push/cache failed: $e',
        error: e,
        tag: 'MAP',
      );
    }
  }

  void _resetDriverEtaMetrics() {
    if (!mounted) return;
    setState(() {
      _driverPickupDistanceKm = null;
      _driverPickupEta = null;
      _driverPickupArrivalTime = null;
      _driverDestinationDistanceKm = null;
      _driverDestinationEta = null;
      _driverDestinationArrivalTime = null;
      _driverTrafficSummary = null;
    });
  }

  bool _shouldIncludePickupLeg(String? status) {
    const pickupStates = {
      'driver_found',
      'accepted',
      'driver_en_route',
      'arrived',
    };
    if (status == null) return true;
    return pickupStates.contains(status);
  }

  void _updateDriverRideEstimates(geolocator.Position driverPosition) {
    if (!mounted || _currentActiveRide == null) return;

    final ride = _currentActiveRide!;
    final includePickupLeg = _shouldIncludePickupLeg(ride.status);

    double? pickupDistanceMeters;
    double? destinationDistanceMeters;

    if (includePickupLeg &&
        ride.startLatitude != null &&
        ride.startLongitude != null) {
      pickupDistanceMeters = geolocator.Geolocator.distanceBetween(
        driverPosition.latitude,
        driverPosition.longitude,
        ride.startLatitude!,
        ride.startLongitude!,
      );
    }

    if (ride.destinationLatitude != null && ride.destinationLongitude != null) {
      destinationDistanceMeters = geolocator.Geolocator.distanceBetween(
        driverPosition.latitude,
        driverPosition.longitude,
        ride.destinationLatitude!,
        ride.destinationLongitude!,
      );
    }

    const averageSpeedMps = 10.0;
    Duration? pickupEta;
    Duration? destinationEta;
    DateTime? pickupArrival;
    DateTime? destinationArrival;

    if (!includePickupLeg) {
      pickupDistanceMeters = 0;
      pickupEta = Duration.zero;
      pickupArrival = DateTime.now();
    } else if (pickupDistanceMeters != null) {
      final etaSeconds =
          (pickupDistanceMeters / averageSpeedMps).clamp(0, 60 * 60 * 2).toInt();
      pickupEta = Duration(seconds: etaSeconds);
      pickupArrival = DateTime.now().add(pickupEta);
    }

    if (destinationDistanceMeters != null) {
      final etaSeconds = (destinationDistanceMeters / averageSpeedMps)
          .clamp(0, 60 * 60 * 3)
          .toInt();
      destinationEta = Duration(seconds: etaSeconds);
      destinationArrival = DateTime.now().add(destinationEta);
    }

    setState(() {
      _driverPickupDistanceKm = pickupDistanceMeters != null
          ? pickupDistanceMeters / 1000.0
          : (includePickupLeg ? null : 0);
      _driverPickupEta = pickupEta;
      _driverPickupArrivalTime = pickupArrival;

      _driverDestinationDistanceKm = destinationDistanceMeters != null
          ? destinationDistanceMeters / 1000.0
          : null;
      _driverDestinationEta = destinationEta;
      _driverDestinationArrivalTime = destinationArrival;

      if (pickupDistanceMeters == null &&
          destinationDistanceMeters == null &&
          !includePickupLeg) {
        _driverTrafficSummary = null;
      }
    });

    final now = DateTime.now();
    final hasRecentRequest = _driverLastEtaRequestTime != null &&
        now.difference(_driverLastEtaRequestTime!) < _MapScreenState._driverEtaThrottle;

    final bool movedEnough;
    if (_driverLastEtaPosition == null) {
      movedEnough = true;
    } else {
      final movedMeters = geolocator.Geolocator.distanceBetween(
        driverPosition.latitude,
        driverPosition.longitude,
        _driverLastEtaPosition!.latitude,
        _driverLastEtaPosition!.longitude,
      );
      movedEnough = movedMeters >= _MapScreenState._driverEtaDistanceThresholdMeters;
    }

    if (hasRecentRequest || !movedEnough || _driverIsFetchingEta) {
      return;
    }

    _driverLastEtaRequestTime = now;
    _driverLastEtaPosition = driverPosition;
    unawaited(_fetchDriverPreciseEta(driverPosition));
  }

  Future<void> _fetchDriverPreciseEta(geolocator.Position driverPosition) async {
    if (_driverIsFetchingEta || _currentActiveRide == null) return;

    final ride = _currentActiveRide!;
    final includePickupLeg = _shouldIncludePickupLeg(ride.status);

    final waypoints = <Point>[
      MapboxUtils.createPoint(driverPosition.latitude, driverPosition.longitude),
    ];

    if (includePickupLeg &&
        ride.startLatitude != null &&
        ride.startLongitude != null) {
      waypoints.add(MapboxUtils.createPoint(ride.startLatitude!, ride.startLongitude!));
    }

    if (ride.destinationLatitude != null && ride.destinationLongitude != null) {
      waypoints.add(MapboxUtils.createPoint(ride.destinationLatitude!, ride.destinationLongitude!));
    }

    if (waypoints.length < 2) return;

    _driverIsFetchingEta = true;
    try {
      final routeResult = await _routingService.getRoute(waypoints);
      if (!mounted || routeResult == null) return;

      final routes = routeResult['routes'];
      if (routes is! List || routes.isEmpty) return;

      final route = routes.first;
      if (route is! Map<String, dynamic>) return;

      final totalDistance = (route['distance'] as num?)?.toDouble();
      final totalDuration = (route['duration'] as num?)?.toDouble();

      double? pickupDistance;
      double? pickupDuration;
      String? trafficSummary;

      final legs = route['legs'];
      if (legs is List && legs.isNotEmpty) {
        final congestionCounts = <String, int>{};
        for (final legEntry in legs) {
          if (legEntry is Map<String, dynamic>) {
            final congestion = (legEntry['annotation'] as Map<String, dynamic>?)
                ?['congestion'];
            if (congestion is List) {
              for (final value in congestion) {
                if (value is String && value.isNotEmpty) {
                  congestionCounts.update(value, (v) => v + 1, ifAbsent: () => 1);
                }
              }
            }
          }
        }

        if (congestionCounts.isNotEmpty) {
          final dominant = congestionCounts.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
          trafficSummary = switch (dominant) {
            'low' => 'Trafic lejer',
            'moderate' => 'Trafic moderat',
            'heavy' => 'Trafic aglomerat',
            'severe' => 'Trafic foarte aglomerat',
            _ => null,
          };
        }

        if (includePickupLeg) {
          final firstLeg = legs.first;
          if (firstLeg is Map<String, dynamic>) {
            pickupDistance = (firstLeg['distance'] as num?)?.toDouble();
            pickupDuration = (firstLeg['duration'] as num?)?.toDouble();
          }
        }
      }

      if (!includePickupLeg) {
        pickupDistance ??= 0;
        pickupDuration ??= 0;
      }

      if (!mounted) return;

      setState(() {
        if (pickupDistance != null) {
          _driverPickupDistanceKm = pickupDistance / 1000.0;
        }
        if (pickupDuration != null) {
          _driverPickupEta = Duration(seconds: pickupDuration.round());
          _driverPickupArrivalTime = DateTime.now().add(_driverPickupEta!);
        }

        if (totalDistance != null) {
          _driverDestinationDistanceKm = totalDistance / 1000.0;
        }
        if (totalDuration != null) {
          _driverDestinationEta = Duration(seconds: totalDuration.round());
          _driverDestinationArrivalTime = DateTime.now().add(_driverDestinationEta!);
        }

        if (trafficSummary != null) {
          _driverTrafficSummary = trafficSummary;
        }
      });
    } catch (e) {
      Logger.error('Driver precise ETA calculation failed: $e', error: e);
    } finally {
      _driverIsFetchingEta = false;
    }
  }





  Future<void> _onRouteCalculated(Map<String, dynamic>? routeData) async {
    await _routeAnnotationManager?.deleteAll();
    await _altRouteAnnotationManager?.deleteAll();
    await _routeMarkersAnnotationManager?.deleteAll();
    await _pickupCircleManager?.deleteAll();
    await _destinationCircleManager?.deleteAll();
    
    if (routeData == null || !mounted) {
      setState(() {
        _routeCtrl.currentRouteDistanceMeters = null;
        _routeCtrl.currentRouteDurationSeconds = null;
        _isDestinationPreviewMode = false;
        _isDraggingPin = false;
      });
      Logger.debug('Route cleared in MapScreen');
      unawaited(_resetMapPinAfterRouteCleared());
      return;
    }
    // Rută confirmată — ieșim din modul preview; pinul rămâne pe hartă (util pentru navigare/favorite).
    _isDestinationPreviewMode = false;
    if (mounted) {
      unawaited(() async {
        if (_previewPinPoint != null) {
          await _updatePreviewPinScreenPos(_previewPinPoint!);
        }
        if (mounted) setState(() {});
      }());
    }
    
          try {
        // Ensure managers exist before drawing
        _routeAnnotationManager ??= await _mapboxMap?.annotations.createPolylineAnnotationManager(id: 'route-manager');
        _routeMarkersAnnotationManager ??= await _mapboxMap?.annotations.createPointAnnotationManager(id: 'route-markers-manager');
        _pickupCircleManager ??= await _mapboxMap?.annotations.createCircleAnnotationManager(id: 'pickup-circle-manager');
        _destinationCircleManager ??= await _mapboxMap?.annotations.createCircleAnnotationManager(id: 'destination-circle-manager');
        final routes = (routeData['routes'] as List?) ?? const [];
        if (routes.isEmpty) return;
        final route = routes[0];
        final geometry = route['geometry'] as Map<String, dynamic>;
        final meters = (route['distance'] as num?)?.toDouble();
        final seconds = (route['duration'] as num?)?.toDouble();
        if (meters != null && seconds != null) {
          if (mounted) {
            setState(() {
              _routeCtrl.currentRouteDistanceMeters = meters;
              _routeCtrl.currentRouteDurationSeconds = seconds;
            });
          }
        }

        // Pickup spot quality: distanța dintre punctul de preluare și primul punct al rutei
        try {
          if (_routeCtrl.pickupLatitude != null && _routeCtrl.pickupLongitude != null) {
            final coords = (geometry['coordinates'] as List<dynamic>);
            if (coords.isNotEmpty) {
              final first = coords.first as List<dynamic>;
              final firstLng = (first[0] as num).toDouble();
              final firstLat = (first[1] as num).toDouble();
              final d = _calculateDirectDistance(_routeCtrl.pickupLatitude!, _routeCtrl.pickupLongitude!, firstLat, firstLng);
              String label;
              Color color;
              if (d <= 10) {
                label = 'Excelent';
                color = Colors.green;
              } else if (d <= 25) {
                label = 'Bun';
                color = Colors.teal;
              } else if (d <= 50) {
                label = 'OK';
                color = Colors.amber.shade700;
              } else {
                label = 'Slab';
                color = Colors.redAccent;
              }
              if (mounted) {
                setState(() {
                  _routeCtrl.pickupQualityLabel = label;
                  _routeCtrl.pickupQualityColor = color;
                });
              }
            }
          } else {
            if (mounted) {
              setState(() {
                _routeCtrl.pickupQualityLabel = null;
                _routeCtrl.pickupQualityColor = null;
              });
            }
          }
        } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
        
        // ✅ CORECTAT: Creez obiect LineString pentru Mapbox (fără cast strict)
        final List<dynamic> coordinates = geometry['coordinates'] as List<dynamic>;
        final lineStringGeometry = LineString(
          coordinates: coordinates.map((coord) {
            final List<dynamic> c = coord as List<dynamic>;
            final double lng = (c[0] as num).toDouble();
            final double lat = (c[1] as num).toDouble();
            return Position(lng, lat);
          }).toList(),
        );
        
        // Delete previous active route if any (to avoid stacking)
        if (_activeRouteAnnotation != null) {
          try { await _routeAnnotationManager?.delete(_activeRouteAnnotation!); } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          _activeRouteAnnotation = null;
        }

        // Base route line (solid blue)
        _activeRouteAnnotation = await _routeAnnotationManager?.create(
          PolylineAnnotationOptions(
            geometry: lineStringGeometry,
            lineColor: Colors.blue.toARGB32(),
            lineWidth: 6.0,
            lineOpacity: 1.0,
          ),
        );

        // Animated pulse overlay (slightly thicker, varying opacity)
        if (_routePulse != null) {
          final double currentOpacity = (_routePulse!.value).clamp(0.4, 1.0);
          await _routeAnnotationManager?.create(
            PolylineAnnotationOptions(
              geometry: lineStringGeometry,
              lineColor: Colors.blueAccent.toARGB32(),
              lineWidth: 7.0,
              lineOpacity: currentOpacity,
            ),
          );
        }

        // Desenează rutele alternative dacă există (faint)
        if (routes.length > 1) {
          // Ensure alt manager exists
          _altRouteAnnotationManager ??= await _mapboxMap?.annotations.createPolylineAnnotationManager(id: 'alt-route-manager');
          for (int i = 1; i < routes.length; i++) {
            final alt = routes[i] as Map<String, dynamic>;
            final g = (alt['geometry'] as Map<String, dynamic>);
            final coords = (g['coordinates'] as List<dynamic>).cast<List<dynamic>>();
            final altLine = LineString(
              coordinates: coords.map((c) => Position((c[0] as num).toDouble(), (c[1] as num).toDouble())).toList(),
            );
            await _altRouteAnnotationManager?.create(
              PolylineAnnotationOptions(
                geometry: altLine,
                lineColor: Colors.grey.shade500.toARGB32(),
                lineWidth: 4.0,
                lineOpacity: 0.4,
              ),
            );
          }
        }
      
      await _addRouteCircles(routeData);
      
      // ✅ Adaugă pin de destinație imediat după desenarea rutei
      try {
        final List<dynamic> endCoord = ((routeData['routes'][0]['geometry']['coordinates']) as List).last as List;
        await _addDestinationMarker(
          MapboxUtils.createPoint((endCoord[1] as num).toDouble(), (endCoord[0] as num).toDouble()),
          'Destinație',
        );
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      
      // ✅ Ajustează camera astfel încât să fie vizibil întreg traseul
      try {
        final List<dynamic> coords = (geometry['coordinates'] as List<dynamic>);
        if (coords.isNotEmpty) {
          final List<double> lats = <double>[];
          final List<double> lngs = <double>[];
          for (final dynamic c in coords) {
            final List<dynamic> p = c as List<dynamic>;
            lngs.add((p[0] as num).toDouble());
            lats.add((p[1] as num).toDouble());
          }
          final southwest = MapboxUtils.createPoint(
            lats.reduce((a, b) => a < b ? a : b),
            lngs.reduce((a, b) => a < b ? a : b),
          );
          final northeast = MapboxUtils.createPoint(
            lats.reduce((a, b) => a > b ? a : b),
            lngs.reduce((a, b) => a > b ? a : b),
          );
          final bounds = CoordinateBounds(
            southwest: southwest,
            northeast: northeast,
            infiniteBounds: false,
          );
          final cameraOptions = await _mapboxMap?.cameraForCoordinateBounds(
            bounds,
            MbxEdgeInsets(
              top: 100.0,
              left: 50.0,
              bottom: 300.0, // spațiu pentru panoul cu opțiuni
              right: 50.0,
            ),
            0.0,
            0.0,
            null,
            null,
          );
          if (cameraOptions != null) {
            await _mapboxMap?.flyTo(cameraOptions, MapAnimationOptions(duration: 1200));
          }
        }
      } catch (e) {
        Logger.error('Failed to fit camera to route: $e', error: e);
      }
      
      Logger.debug('Route and circles displayed in MapScreen');
    } catch (e) {
      Logger.error('Error processing route geometry: $e', error: e);
      Logger.error('Route data structure: $routeData');
    }
  }

  Future<void> _addRouteCircles(Map<String, dynamic> routeData) async {
    if (_pickupCircleManager == null || _destinationCircleManager == null || !mounted) return;
    
    try {
      final route = routeData['routes'][0];
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      
      if (coordinates.isEmpty) return;
      
      final startCoord = coordinates.first as List<dynamic>;
      final endCoord = coordinates.last as List<dynamic>;
      
      final baseRadius = 12.0;
      final animatedRadius = _pickupPulse?.value != null ? baseRadius * _pickupPulse!.value : baseRadius;
      final pickupOptions = CircleAnnotationOptions(
        geometry: MapboxUtils.createPoint(startCoord[1], startCoord[0]),
        circleRadius: animatedRadius,
        circleColor: Colors.green.toARGB32(),
        circleStrokeWidth: 2,
        circleStrokeColor: Colors.white.toARGB32(),
      );
      
      final destinationOptions = CircleAnnotationOptions(
        geometry: MapboxUtils.createPoint(endCoord[1], endCoord[0]),
        circleRadius: 12,
        circleColor: Colors.red.toARGB32(),
        circleStrokeWidth: 2,
        circleStrokeColor: Colors.white.toARGB32(),
      );
      
      await _pickupCircleManager?.create(pickupOptions);
      await _destinationCircleManager?.create(destinationOptions);
      
      Logger.info('Route circles added successfully');
      
    } catch (e) {
      Logger.error('Error adding route circles: $e', error: e);
    }
  }

  void _resumeMapAfterRideFlow() {
    Logger.debug('Returned from active ride / pickup flow - resuming background processes');
    _shouldResetRoute = true;
    if (mounted && _isDriverAvailable && _currentRole == UserRole.driver) {
      _startDriverLocationUpdates();
    } else if (mounted) {
      _ensurePassiveLocationWarmupIfNeeded();
    }
    if (mounted) {
      _listenForNearbyDrivers();
      _resetRouteStateIfNeeded();
    }
  }

  /// Flux șofer: preluare (hartă înghețată în UI-ul de pickup), fără ActiveRideScreen.
  Future<void> _navigateDriverPickupWithRide(Ride ride) async {
    Logger.debug('Navigating to DriverRidePickupScreen - stopping background processes', tag: 'MAP');
    _stopLocationUpdates();
    _nearbyDriversSubscription?.cancel();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverRidePickupScreen(
          rideId: ride.id,
          ride: ride,
        ),
      ),
    );
    _resumeMapAfterRideFlow();
  }

  Future<void> _navigateDriverPickupByRideId(String rideId) async {
    _stopLocationUpdates();
    _nearbyDriversSubscription?.cancel();
    final ride = await _firestoreService.getRideById(rideId);
    if (!mounted) return;
    if (ride == null) {
      _resumeMapAfterRideFlow();
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverRidePickupScreen(
          rideId: ride.id,
          ride: ride,
        ),
      ),
    );
    _resumeMapAfterRideFlow();
  }

  /// Flux cursă din hartă: **pasagerul nu are** ecran „active ride” dedicat — doar sesiune pe hartă
  /// ([_beginPassengerRideSession], overlay). Pentru șofer: flux preluare (pickup).
  void _openRideFlowFromMap(String rideId) {
    Logger.debug('Opening ride flow from map (role=$_currentRole)');
    if (_currentRole == UserRole.driver) {
      _stopLocationUpdates();
      _nearbyDriversSubscription?.cancel();
      unawaited(_navigateDriverPickupByRideId(rideId));
      return;
    }

    _beginPassengerRideSession(rideId);
  }

  Widget _buildContextualOverlay() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutExpo,
      switchOutCurve: Curves.easeInCirc,
      child: _contextState == NabourContextState.driving
          ? MapDrivingHud(speedKmh: _currentSpeedKph)
          : _contextState == NabourContextState.walking
              ? const MapWalkingGlow(active: true)
              : const SizedBox.shrink(),
    );
  }
}

