// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapInteractionsMethods on _MapScreenState {
  double _calculateDirectDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // metri
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }



  // REMOVED: _clearExistingPois was unused after switching to SymbolLayer-based rendering.

  // REMOVED: _getCategoryColor was only used by the old PointAnnotation rendering path.

  /// Lățimea vizibilă pe ecran la zoom/latitudine (Web Mercator) — aceeași logică ca la scale bar nativ.
  String _formatVisibleMapWidthLabel(double latDeg, double zoom, double widthPx) {
    if (widthPx <= 0 || zoom.isNaN) return _scaleBarText;
    final mpp =
        156543.03392 * math.cos(latDeg.clamp(-85.0, 85.0) * math.pi / 180) / math.pow(2.0, zoom);
    final visibleM = mpp * widthPx;
    if (visibleM < 250) {
      return '${visibleM.round()} m';
    }
    if (visibleM < 950) {
      return '${(visibleM / 1000).toStringAsFixed(2)} km';
    }
    if (visibleM < 9950) {
      return '${(visibleM / 1000).toStringAsFixed(1)} km';
    }
    return '${(visibleM / 1000).round()} km';
  }

  void _onCameraChanged(CameraChangedEventData data) {
    if (!mounted) return;
    final lat = data.cameraState.center.coordinates.lat.toDouble();
    final lng = data.cameraState.center.coordinates.lng.toDouble();
    final zoom = data.cameraState.zoom.toDouble();
    final bearing = data.cameraState.bearing.toDouble();
    final pitch = data.cameraState.pitch.toDouble();

    // 🔄 MIDDLEWARE SYNC: Salvăm starea în provider pentru tranziție perfectă către OSM
    context.read<MapCameraProvider>().syncFromNative(
      lat: lat,
      lng: lng,
      zoom: zoom,
      bearing: bearing,
      pitch: pitch,
      following: _followingEnabled,
    );

    _liveCameraZoom = zoom;
    _neighborZoomDebounce?.cancel();
    _neighborZoomDebounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        unawaited(_applyUserAvatarLayersZoomScale());
      }
    });
    final w = MediaQuery.sizeOf(context).width;

    // Actualizare text scară (metri vizibili pe sol)
    final next = _formatVisibleMapWidthLabel(lat, zoom, w);
    if (next != _scaleBarText) {
      setState(() => _scaleBarText = next);
    }

    // Prag 3D cu histerezis (coincide cu [canShow3D] în _runUserMarkerUpdate).
    final bool wasAbove = _is3DZoomGateOpen;
    _mapZoomLevel = zoom;
    final bool isAbove = _compute3DZoomGate(zoom);
    if (wasAbove != isAbove && !_spaceIntroInFlight && _mapSpaceIntroDone) {
      _clearGpsUserMarkerThrottle();
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        unawaited(_updateUserMarker(centerCamera: false));
      });
    }

    _auraProjectDebounce?.cancel();
    _auraProjectDebounce = Timer(const Duration(milliseconds: 56), () {
      if (mounted) {
        unawaited(_projectMagicEventAuraSlots());
        unawaited(_projectEmergencyAuraSlots());
        unawaited(_projectAndroidUserMarkerOverlay());
        unawaited(_projectAndroidPrivatePinOverlays());
      }
    });
  }

  // Called when camera stops moving; acum declanșăm POI-urile locale (safe, no traffic)
  void _onMapIdle(MapIdleEventData data) {
    // Afișează chip "Caută Ã®n această zonă" doar dacă deplasarea e semnificativă
    _updateSearchAreaChipVisibility();
    // Protecție panning: împiedicăm request-uri masive de tile-uri
    unawaited(_maybeClampCameraToPanningRadius());
    // Detectare pan manual: dacă camera s-a oprit departe de user și nu noi am mutat-o
    unawaited(_detectUserPan());

    // Recalculează poziția pe ecran a pinului după ce harta se oprește din mișcare
    if (_previewPinPoint != null) {
      unawaited(_updatePreviewPinScreenPos(_previewPinPoint!));
    }
    unawaited(_projectAndroidUserMarkerOverlay());
    unawaited(_projectAndroidPrivatePinOverlays());
    // Update street name overlay (Bump style)
    unawaited(_updateCurrentStreetName());
    // Track zoom for slider
    unawaited(_syncZoomLevel());
    unawaited(_projectMagicEventAuraSlots());
    _schedule3DLocationResyncAfterMapIdle();
  }

  /// După animații cameră (ex. fly to user), straturile de locație 3D pot rămâne fără sursă de model validă.
  void _schedule3DLocationResyncAfterMapIdle() {
    final av = _getCurrentAvatarObject();
    if (av == null || !av.is3D || av.modelPath == null) return;
    _mapIdle3dResyncDebounce?.cancel();
    _mapIdle3dResyncDebounce = Timer(const Duration(milliseconds: 2500), () {
      _mapIdle3dResyncDebounce = null;
      if (!mounted || _mapboxMap == null) return;
      unawaited(() async {
        try {
          final cam = await _mapboxMap!.getCameraState();
          if (!mounted) return;
          if (!_compute3DZoomGate(cam.zoom.toDouble())) return;
          await _enable3DUserModel(av.modelPath!);
        } catch (e) {
          Logger.debug('3D resync după map idle: $e', tag: 'MAP_3D');
        }
      }());
    });
  }

  Future<void> _syncZoomLevel() async {
    if (_mapboxMap == null) return;
    try {
      final cam = await _mapboxMap!.getCameraState();
      final z = cam.zoom.toDouble();
      if ((z - _mapZoomLevel).abs() > 0.3 && mounted) {
        setState(() => _mapZoomLevel = z);
      }
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
  }

  Future<void> _updateCurrentStreetName({bool throttle = false}) async {
    if (!mounted) return;
    if (throttle && _lastStreetNameUpdate != null) {
      final elapsed = DateTime.now().difference(_lastStreetNameUpdate!);
      if (elapsed.inSeconds < 20) return;
    }
    try {
      double lat;
      double lng;
      if (_currentPositionObject != null) {
        lat = _currentPositionObject!.latitude;
        lng = _currentPositionObject!.longitude;
      } else if (_mapboxMap != null) {
        final cam = await _mapboxMap!.getCameraState();
        lat = cam.center.coordinates.lat.toDouble();
        lng = cam.center.coordinates.lng.toDouble();
      } else {
        return;
      }
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      _lastStreetNameUpdate = DateTime.now();
      if (placemarks.isNotEmpty && mounted) {
        final street = placemarks.first.street ?? '';
        if (street != _currentStreetName) {
          setState(() {
            _currentStreetName = street;
          });
        }
      }
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
  }

  /// Dacă userul a panning-uit prea mult față de locația curentă, readuce camera
  /// înapoi într-o zonă aproximativă (bounding box) de tip hard radius.
  ///
  /// Dezactivează snap-back în modul preview destinație / când pinul e folosit activ ca să nu te lupți cu
  /// animarea / drag-ul pinului.
  Future<void> _maybeClampCameraToPanningRadius() async {
    if (!mounted || _mapboxMap == null) return;
    if (_isPanClamping) return;
    if (_isDestinationPreviewMode) return;
    if (_previewPinPoint != null) return;
    if (_currentPositionObject == null) return;

    final now = DateTime.now();
    if (now.difference(_lastPanClampAt) < _MapScreenState._panClampMinGap) return;

    try {
      final cam = await _mapboxMap!.getCameraState();
      final center = cam.center;
      final centerLat = center.coordinates.lat.toDouble();
      final centerLng = center.coordinates.lng.toDouble();

      final myLat = _currentPositionObject!.latitude;
      final myLng = _currentPositionObject!.longitude;

      final movedMeters = MapboxUtils.calculateDistance(
        MapboxUtils.createPoint(myLat, myLng),
        MapboxUtils.createPoint(centerLat, centerLng),
      );

      final hardMeters = (_MapScreenState._panningHardRadiusKm * 1000).toDouble();
      if (movedMeters <= hardMeters) return;

      // Bounding box aproximativ pentru un "hard radius" în km.
      final latDelta = _MapScreenState._panningHardRadiusKm / 111.0;
      final lngDelta =
          _MapScreenState._panningHardRadiusKm / (111.0 * math.cos(myLat * math.pi / 180));

      final clampedLat = centerLat.clamp(myLat - latDelta, myLat + latDelta);
      final clampedLng = centerLng.clamp(myLng - lngDelta, myLng + lngDelta);

      if (clampedLat == centerLat && clampedLng == centerLng) return;

      _isPanClamping = true;
      _lastPanClampAt = now;
      try {
        await _mapboxMap!.flyTo(
          CameraOptions(
            center: MapboxUtils.createPoint(clampedLat, clampedLng),
            zoom: cam.zoom,
          ),
          MapAnimationOptions(duration: AppDrawer.lowDataMode ? 200 : 350),
        );
      } finally {
        _isPanClamping = false;
      }
    } catch (_) {
      // best-effort only
    }
  }

  /// Detectează dacă userul a panning-uit manual departe de poziția sa.
  /// Dacă da, dezactivează urmărirea și afișează butonul de recentrare.
  Future<void> _detectUserPan() async {
    if (_followEaseInFlight) return;
    if (_currentPositionObject == null || _mapboxMap == null) return;
    if (!mounted) return;
    try {
      final cam = await _mapboxMap!.getCameraState();
      final camLat = cam.center.coordinates.lat.toDouble();
      final camLng = cam.center.coordinates.lng.toDouble();
      final distM = geolocator.Geolocator.distanceBetween(
        _currentPositionObject!.latitude,
        _currentPositionObject!.longitude,
        camLat,
        camLng,
      );
      if (distM > 60 && _followingEnabled) {
        if (mounted) setState(() { _followingEnabled = false; _showRecenterBtn = true; });
      }
    } catch (_) {}
  }

  void _updateSearchAreaChipVisibility() async {
    if (_mapboxMap == null) return;
    final widthPx = MediaQuery.sizeOf(context).width;
    try {
      final cam = await _mapboxMap!.getCameraState();
      if (!mounted) return;
      final center = cam.center;
      final lat = center.coordinates.lat.toDouble();
      final lng = center.coordinates.lng.toDouble();
      final zoom = cam.zoom;
      final kmText = _formatVisibleMapWidthLabel(lat, zoom, widthPx);
      setState(() {
        _scaleBarText = kmText;
      });
      final lastLat = _lastSearchCenterLat;
      final lastLng = _lastSearchCenterLng;
      if (lastLat == null || lastLng == null) {
        setState(() { _showSearchAreaChip = true; });
        return;
      }
      final movedMeters = MapboxUtils.calculateDistance(
        MapboxUtils.createPoint(lastLat, lastLng),
        MapboxUtils.createPoint(lat, lng),
      );
      final shouldShow = movedMeters > 150.0; // prag mic
      if (shouldShow != _showSearchAreaChip) {
        setState(() { _showSearchAreaChip = shouldShow; });
      }
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
  }

  /// Tap scurt: doar POI / selecții native; pinul roșu se plasează la long-press.
  void _handleMapTap(Point tappedPoint) {
    if (_checkForPOIAtPoint(tappedPoint)) return;
  }

  /// Long-press: mută pinul și deschide direct foaia (navigare / favorite) — nu mai e nevoie să apeși separat pe pin.
  void _handleMapLongPress(Point point) {
    if (_awaitingMapOrientationPinPlacement) {
      unawaited(_finishMapOrientationPinPlacement(point));
      return;
    }
    if (_isDestinationPreviewMode) {
      unawaited(_moveMapPinToPoint(point, syncRidePanel: true));
      return;
    }
    if (_awaitingParkingYieldMapPick) {
      if (_checkForPOIAtPoint(point)) return;
      unawaited(_finishParkingYieldMapPick(point));
      return;
    }
    if (_checkForPOIAtPoint(point)) return;
    unawaited(_openMapLocationSheetAfterMovingPin(point));
  }

  Future<void> _openMapLocationSheetAfterMovingPin(Point point) async {
    await _moveMapPinToPoint(point, syncRidePanel: false);
    if (!mounted) return;
    await _showMapTapLocationSheet(point);
  }

  /// Apelat de RideRequestPanel când userul selectează o destinație din sugestii.
  Future<void> _onDestinationPreview(Point destPoint, String destAddress) async {
    _isDestinationPreviewMode = true;
    _previewPinPoint = destPoint;
    // Zbor camera la destinație
    await _mapboxMap?.flyTo(
      CameraOptions(center: destPoint, zoom: 15.0),
      MapAnimationOptions(duration: 900),
    );
    // Așteptăm să se termine animația, apoi calculăm poziția pe ecran
    await Future.delayed(const Duration(milliseconds: 950));
    await _updatePreviewPinScreenPos(destPoint);
    if (mounted) setState(() {});
  }

  Future<void> _moveMapPinToPoint(Point newPoint, {required bool syncRidePanel}) async {
    _previewPinPoint = newPoint;
    await _updatePreviewPinScreenPos(newPoint);
    if (syncRidePanel && _isDestinationPreviewMode) {
      final geocoding = await _geocodingServiceForPreview(newPoint);
      _rideRequestPanelKey.currentState?.updatePreviewDestination(newPoint, geocoding);
    }
    _resetPinAutoHideTimer();
  }

  void _resetPinAutoHideTimer() {
    _pinAutoHideTimer?.cancel();
    if (_isDestinationPreviewMode || _routeCtrl.inAppNavActive || _isDraggingPin) return;
    _pinAutoHideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_isDraggingPin || _isDestinationPreviewMode || _routeCtrl.inAppNavActive) return;
      setState(() {
        _previewPinScreenPos = null;
        _previewPinPoint = null;
      });
    });
  }

  Future<void> _resetMapPinAfterRouteCleared() async {
    if (!mounted) return;
    _previewPinPoint = null;
    _previewPinScreenPos = null;
    if (mounted) setState(() {});
  }

  /// Convertește coordonate hartă â†’ pixeli ecran și actualizează poziția widget-ului pin.
  Future<void> _updatePreviewPinScreenPos(Point point) async {
    final sc = await _projectLatLngToScreen(
      point.coordinates.lat.toDouble(),
      point.coordinates.lng.toDouble(),
    );
    if (sc != null && mounted) {
      setState(() => _previewPinScreenPos = sc);
    }
  }

  Future<void> _triggerRippleAtLatLng(double lat, double lng) async {
    final pos = await _projectLatLngToScreen(lat, lng);
    if (pos != null && mounted) {
      final id = 'ripple_${_rippleIdCounter++}';
      setState(() {
        _activeRipples.add((id: id, position: pos));
      });
    }
  }

  /// Proiecție coordonate -> pixeli ecran, agnostic față de motorul de hartă (Mapbox/OSM).
  Future<Offset?> _projectLatLngToScreen(double lat, double lng) async {
    if (!mounted) return null;
    final mapSettings = Provider.of<MapSettingsProvider>(context, listen: false);
    
    if (mapSettings.isOsm) {
      if (_osmMapController != null) {
        final pt = _osmMapController!.camera.latLngToScreenPoint(ll.LatLng(lat, lng));
        return Offset(pt.x.toDouble(), pt.y.toDouble());
      }
      return null;
    } else {
      if (_mapboxMap != null) {
        try {
          final sc = await _mapboxMap!.pixelForCoordinate(MapboxUtils.createPoint(lat, lng));
          return Offset(sc.x.toDouble(), sc.y.toDouble());
        } catch (_) {}
      }
      return null;
    }
  }

  /// Drag update â€” mută widget-ul pin instant pe ecran.
  void _onPinDragUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    _pinAutoHideTimer?.cancel();
    setState(() {
      _isDraggingPin = true;
      _previewPinScreenPos = (_previewPinScreenPos ?? Offset.zero) + details.delta;
    });
  }

  /// Drag end â€” convertește poziția finală Ã®n coordonate și reverse geocodează.
  Future<void> _onPinDragEnd(DragEndDetails details) async {
    if (!mounted || _previewPinScreenPos == null) return;
    setState(() => _isDraggingPin = false);
    _resetPinAutoHideTimer();
    final sc = ScreenCoordinate(
      x: _previewPinScreenPos!.dx,
      y: _previewPinScreenPos!.dy,
    );
    try {
      final coord = await _mapboxMap?.coordinateForPixel(sc);
      if (coord == null || !mounted) return;
      _previewPinPoint = coord;
      if (_isDestinationPreviewMode) {
        final geocoding = await _geocodingServiceForPreview(coord);
        _rideRequestPanelKey.currentState?.updatePreviewDestination(coord, geocoding);
      }
    } catch (e) {
      Logger.error('Pin drag end error: $e', error: e);
    }
  }

  Future<String> _geocodingServiceForPreview(Point point) async {
    final address = await GeocodingService().getAddressFromCoordinates(
      point.coordinates.lat.toDouble(),
      point.coordinates.lng.toDouble(),
    );
    return address ?? 'Locație selectată';
  }

  Widget _buildAiGlassButton({
    required VoiceProcessingState? processingState,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    Color accentColor;
    IconData icon;
    bool isPulse = false;

    switch (processingState) {
      case VoiceProcessingState.listening:
        accentColor = const Color(0xFFFF003C); // Cyber Red
        icon = Icons.mic_rounded;
        isPulse = true;
        break;
      case VoiceProcessingState.thinking:
        accentColor = const Color(0xFFFFD700); // Amber
        icon = Icons.auto_awesome_rounded;
        isPulse = true;
        break;
      case VoiceProcessingState.speaking:
        accentColor = const Color(0xFF00FF9D); // Emerald
        icon = Icons.volume_up_rounded;
        isPulse = true;
        break;
      default:
        accentColor = const Color(0xFF00E5FF); // Cyber Blue
        icon = Icons.mic_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.25 : 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: isPulse ? 0.4 : 0.1),
                  blurRadius: isPulse ? 15 : 5,
                  spreadRadius: isPulse ? 2 : 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 22,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }





  /// Verifică dacă tap-ul este pe un POI. Returnează `true` dacă s-a tratat un POI.
  bool _checkForPOIAtPoint(Point tappedPoint) {
    final pois = _currentPois;
    
    // Verifică distanța față de fiecare POI (raza de detectare: ~50 metri)
    const double detectionRadiusMeters = 50.0;
    
    for (int i = 0; i < pois.length; i++) {
      final poi = pois[i];
      final poiPoint = Point(
        coordinates: Position(poi.location.longitude, poi.location.latitude)
      );
      
      // Calculează distanța aproximativă
      final distance = _calculateDistanceBetweenPoints(tappedPoint, poiPoint);
      
      if (distance <= detectionRadiusMeters) {
        Logger.debug('POI detected: ${poi.name}');
        _onPoiTapped(poi);
        return true;
      }
    }
    return false;
  }

  Future<void> _showMapTapLocationSheet(Point point) async {
    if (!mounted) return;
    // NU folosi `context` din interiorul [FutureBuilder] pentru navigare după pop:
    // acel context e al sheet-ului și devine unmounted imediat ce închizi sheet-ul,
    // deci showNavigationChooser / push către PointNavigationScreen nu rulează.
    final mapScreenContext = context;
    final lat = point.coordinates.lat.toDouble();
    final lng = point.coordinates.lng.toDouble();

    await showModalBottomSheet<void>(
      context: mapScreenContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Locație selectată',
                  style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    'Sfat: ține apăsat pe hartă la un punct ca să ajungi aici direct, fără să apeși pe pin.',
                    style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                MapTapGeocodeSheetBody(
                  lat: lat,
                  lng: lng,
                  sheetContext: sheetCtx,
                  mapScreenContext: mapScreenContext,
                  onOpenFavorite: _openAddFavoriteFlow,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAddFavoriteFlow(double lat, double lng, String address) async {
    if (!mounted) return;
    if (FirebaseAuth.instance.currentUser == null) {
      _showSafeSnackBar(
        'Conectează-te pentru a salva adrese favorite.',
        Colors.orange,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => AddAddressScreen(
          prefilledCoordinates: GeoPoint(lat, lng),
          prefilledAddress: address,
          initialLabel: 'Favorite',
        ),
      ),
    );
  }

  Future<void> _onPoiAddFavorite(PointOfInterest poi) async {
    final lat = poi.location.latitude;
    final lng = poi.location.longitude;
    final resolved = await GeocodingService().getAddressFromCoordinates(lat, lng);
    final address = resolved != null && resolved.trim().isNotEmpty
        ? resolved.trim()
        : '${poi.name}. ${poi.description}';
    await _openAddFavoriteFlow(lat, lng, address);
  }

  void _onPoiNavigateHere(PointOfInterest poi) {
    final lat = poi.location.latitude;
    final lng = poi.location.longitude;
    ExternalMapsLauncher.showNavigationChooser(
      context,
      lat,
      lng,
      onOpenNabour: () async {
        if (!mounted) return;
        final seed = await _navigationOriginSeedLatLng();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (ctx) => PointNavigationScreen(
              destinationLat: lat,
              destinationLng: lng,
              destinationLabel: poi.name,
              mapKnownOriginLat: seed.lat,
              mapKnownOriginLng: seed.lng,
            ),
          ),
        );
      },
    );
  }

  /// Calculează distanța aproximativă Ã®ntre două puncte Ã®n metri
  double _calculateDistanceBetweenPoints(Point point1, Point point2) {
    const double earthRadius = 6371000; // metri
    final lat1Rad = point1.coordinates.lat * (math.pi / 180);
    final lat2Rad = point2.coordinates.lat * (math.pi / 180);
    final deltaLatRad = (point2.coordinates.lat - point1.coordinates.lat) * (math.pi / 180);
    final deltaLngRad = (point2.coordinates.lng - point1.coordinates.lng) * (math.pi / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Handler pentru POI selectat
  void _onPoiTapped(PointOfInterest poi) {
    Logger.info('POI tapped: ${poi.name}');
    HapticFeedback.selectionClick();
    unawaited(_triggerRippleAtLatLng(poi.location.latitude, poi.location.longitude));
    
    setState(() {
      _selectedPoi = poi;
      _showPoiCard = true;
      // Keep tap-detection logic consistent: we only draw/select this POI.
      _currentPois
        ..clear()
        ..add(poi);
      // Reset position so the card starts in a visible spot
      _poiCardPosition = const Offset(16, 180);
    });

    // Ensure zoom to de-cluster and center (debounced and thresholded)
    _cameraFlyToTimer?.cancel();
    _cameraFlyToTimer = Timer(const Duration(milliseconds: 250), () async {
      final double targetLat = poi.location.latitude;
      final double targetLng = poi.location.longitude;

      // ── Mapbox Fly To ───────────────────────────────────────────────────
      if (_mapboxMap != null) {
        try {
          final cam = await _mapboxMap!.getCameraState();
          final dMeters = MapboxUtils.calculateDistance(
            MapboxUtils.createPoint(cam.center.coordinates.lat.toDouble(), cam.center.coordinates.lng.toDouble()),
            MapboxUtils.createPoint(targetLat, targetLng),
          );
          if (dMeters < 80.0 && (cam.zoom - 16.0).abs() < 0.15) return;

          unawaited(_mapboxMap!.flyTo(
            CameraOptions(
              center: MapboxUtils.createPoint(targetLat, targetLng),
              zoom: 16.0,
              padding: MbxEdgeInsets(top: 80, left: 16, bottom: 320, right: 16),
            ),
            MapAnimationOptions(duration: AppDrawer.lowDataMode ? 350 : 600),
          ));
        } catch (_) {}
      }

      // ── OSM Fly To ──────────────────────────────────────────────────────
      if (_osmMapController != null) {
        _animatedMoveOsm(
          ll.LatLng(targetLat, targetLng),
          16.0,
          durationMs: AppDrawer.lowDataMode ? 400 : 750,
        );
      }
    });

    // Update selected POI highlight
    _updateSelectedPoiHighlight(poi);

    // Afișăm pe hartă DOAR POI-ul selectat (nu toată categoria).
    // Astfel evităm încărcarea/afișarea automată a tuturor POI-urilor.
    unawaited(_updatePoiGeoJson([poi]));

    // âœ… Auto-hide: dacă nu se inițiază nicio acțiune (pickup/destination/stop),
    // curățăm highlight-ul și cardul după 60 secunde pentru a elibera memorie
    _selectedPoiAutoHideTimer?.cancel();
    _selectedPoiAutoHideTimer = Timer(const Duration(seconds: 60), () async {
      if (!mounted) return;
      if (_selectedPoi?.id == poi.id) {
        await _clearSelectedPoiHighlight();
        if (mounted) {
          setState(() {
            _selectedPoi = null;
            _showPoiCard = false;
          });
        }
        Logger.debug('Auto-hide POI ${poi.name} după 5s (fără navigare)');
      }
    });

    // Optional: alege intrarea pentru POI-uri mari
    _maybeShowEntrancePicker(poi);

    // Sugestii pickup Ã®n jurul POI
    _generatePickupSuggestionsAround(poi);
  }

  Future<void> _updateSelectedPoiHighlight(PointOfInterest poi) async {
    if (_mapboxMap == null) return;
    try {
      final feature = {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [poi.location.longitude, poi.location.latitude]
        },
        'properties': {
          'id': poi.id,
          'name': poi.name,
        }
      };
      final fc = {'type': 'FeatureCollection', 'features': [feature]};
      // Update highlight but don't block UI
      unawaited(_mapboxMap!.style.setStyleSourceProperty(
        _MapScreenState._selectedPoiSourceId,
        'data',
        json.encode(fc),
      ));
    } catch (e) {
      Logger.error('Failed to update selected POI highlight: $e', error: e);
    }
  }

  Future<void> _clearSelectedPoiHighlight() async {
    if (_mapboxMap == null) return;
    try {
      final empty = {'type': 'FeatureCollection', 'features': []};
      await _mapboxMap!.style.setStyleSourceProperty(
        _MapScreenState._selectedPoiSourceId,
        'data',
        json.encode(empty),
      );
    } catch (e) {
      Logger.error('Failed to clear selected POI highlight: $e', error: e);
    }
  }
  Future<void> _updatePoiGeoJson(List<PointOfInterest> pois) async {
    if (_mapboxMap == null) return;
    try {
      final features = pois.map((poi) => {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [poi.location.longitude, poi.location.latitude]
        },
        'properties': {
          'id': poi.id,
          'name': poi.name,
          'category': poi.category.name,
          'rating': poi.additionalInfo?['rating'],
          'isOpen': poi.additionalInfo?['opening_hours'] != null,
          'icon': poi.category.emoji
        }
      }).toList();

      final fc = {'type': 'FeatureCollection', 'features': features};
      await _mapboxMap!.style.setStyleSourceProperty(_MapScreenState._poiSourceId, 'data', json.encode(fc));
    } catch (e) {
      Logger.error('Failed to update POI GeoJson: $e', error: e);
    }
  }




  /// Setează POI ca punct de plecare
  void _setPOIAsPickup(PointOfInterest poi) {
    Logger.info('Setting POI as pickup: ${poi.name}');
    
    try {
      // âœ… PERFORMANCE: Cancel previous operations
      _poiOperationTimer?.cancel();
      
      // âœ… PERFORMANCE: Quick UI update - batch all setState calls
      setState(() {
        Logger.info('Updating pickup state...');
        _routeCtrl.pickupController.text = poi.name;
        _routeCtrl.pickupLatitude = poi.location.latitude;
        _routeCtrl.pickupLongitude = poi.location.longitude;
        // âœ… PERFORMANCE: Close POI card in same setState
        _selectedPoi = null;
        _showPoiCard = false;
        Logger.info('Pickup state updated: lat=$_routeCtrl.pickupLatitude, lng=$_routeCtrl.pickupLongitude');
      });

      // âœ… PERFORMANCE: Close POI card immediately - no additional navigation
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // âœ… PERFORMANCE: Show SnackBar immediately
      _showSafeSnackBar(
        '${poi.name} setat ca punct de plecare',
        Colors.blue,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => _clearPickup(),
        ),
      );

      // âœ… PERFORMANCE: Debounce heavy operations
      _poiOperationTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          Logger.info('Executing deferred operations for pickup...');
          _updateRideRequestPanelPickup(poi);
          _updateMapWithNewPickup();
          // âœ… CONECTARE: Folosește batch map updates
          _batchMapUpdates();
          // âœ… CONECTARE: Folosește _routingService pentru route update
          _updateRouteAfterPOI();
        }
      });

      // Afișează automat ruta dacă avem pickup + destinație
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkAndShowRouteAutomatically();
      });
      
    } catch (e) {
      Logger.error('CRASH in _setPOIAsPickup: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _closePoiCard();
        _showSafeSnackBar(AppLocalizations.of(context)!.mapSetPickupError(e.toString()), Colors.red);
      }
    }
  }

  /// Setează POI ca punct de destinație
  void _setPOIAsDestination(PointOfInterest poi) {
    Logger.info('Setting POI as destination: ${poi.name}');
    
    try {
      // âœ… PERFORMANCE: Cancel previous operations
      _poiOperationTimer?.cancel();
      
      // âœ… PERFORMANCE: Quick UI update - batch all setState calls
      setState(() {
        Logger.info('Updating destination state...');
        _routeCtrl.destinationController.text = poi.name;
        _routeCtrl.destinationLatitude = poi.location.latitude;
        _routeCtrl.destinationLongitude = poi.location.longitude;
        // âœ… PERFORMANCE: Close POI card in same setState
        _selectedPoi = null;
        _showPoiCard = false;
        Logger.info('Destination state updated: lat=$_routeCtrl.destinationLatitude, lng=$_routeCtrl.destinationLongitude');
      });

      // âœ… PERFORMANCE: Close POI card immediately - no additional navigation
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // âœ… PERFORMANCE: Show SnackBar immediately
      _showSafeSnackBar(
        '${poi.name} setat ca destinație',
        Colors.green,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => _clearDestination(),
        ),
      );

      // âœ… PERFORMANCE: Debounce heavy operations
      _poiOperationTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          Logger.info('Executing deferred operations for destination...');
          _updateRideRequestPanelDestination(poi);
          _updateMapWithNewDestination();
          // âœ… CONECTARE: Folosește batch map updates
          _batchMapUpdates();
          // âœ… CONECTARE: Folosește _routingService pentru route update
          _updateRouteAfterPOI();
        }
      });

      // Afișează automat ruta dacă avem pickup + destinație
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkAndShowRouteAutomatically();
      });
      
    } catch (e) {
      Logger.error('CRASH in _setPOIAsDestination: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _closePoiCard();
        _showSafeSnackBar(AppLocalizations.of(context)!.mapSetDestinationError(e.toString()), Colors.red);
      }
    }
  }

    /// Adaugă POI ca oprire intermediară
  void _addPOIAsStop(PointOfInterest poi) {
    Logger.debug('Adding POI as stop: ${poi.name}');
    
    try {
      // âœ… PERFORMANCE: Cancel previous operations
      _poiOperationTimer?.cancel();
      
      // Validation
      if (_routeCtrl.intermediateStops.length >= MapRouteController.maxIntermediateStops) {
        _showSafeSnackBar(AppLocalizations.of(context)!.mapMaxIntermediateStops(MapRouteController.maxIntermediateStops), Colors.orange);
        return;
      }

      // Check for duplicates
      final existingStop = _routeCtrl.intermediateStops.any((stop) =>
          stop == poi.name);
      
      if (existingStop) {
        _showSafeSnackBar(AppLocalizations.of(context)!.mapStopAlreadyAdded, Colors.orange);
        return;
      }

      // âœ… PERFORMANCE: Quick UI update - batch all setState calls
      setState(() {
        Logger.debug('Adding stop to list...');
        _routeCtrl.intermediateStops.add(poi.name);
        // âœ… PERFORMANCE: Close POI card in same setState
        _selectedPoi = null;
        _showPoiCard = false;
        Logger.debug('Stop added. Total stops: ${_routeCtrl.intermediateStops.length}');
      });

      // âœ… PERFORMANCE: Close POI card immediately - no additional navigation
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // âœ… PERFORMANCE: Show SnackBar immediately
      _showSafeSnackBar(
        AppLocalizations.of(context)!.mapIntermediateStopAdded(poi.name),
        Colors.orange,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => _removeLastStop(),
        ),
      );

      // âœ… PERFORMANCE: Debounce heavy operations
      _poiOperationTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          Logger.debug('Executing deferred operations for stop...');
          _updateMapWithAllPoints();
          // âœ… CONECTARE: Folosește batch map updates
          _batchMapUpdates();
          // âœ… CONECTARE: Folosește _routingService pentru route update
          _updateRouteAfterPOI();
        }
      });

      // Afișează automat ruta dacă avem pickup + destinație
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkAndShowRouteAutomatically();
      });
      
    } catch (e) {
      Logger.error('CRASH in _addPOIAsStop: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _closePoiCard();
        _showSafeSnackBar(AppLocalizations.of(context)!.mapAddStopError(e.toString()), Colors.red);
      }
    }
  }

  /// Metodă helper pentru a șterge ultimul stop adăugat
  void _removeLastStop() {
    if (_routeCtrl.intermediateStops.isNotEmpty) {
      setState(() {
        _routeCtrl.intermediateStops.removeLast();
      });
      
      // Update ruta după ștergere
      if (_routeCtrl.pickupLatitude != null && _routeCtrl.destinationLatitude != null) {
        _updateRouteWithAllPoints();
      }
    }
  }

  /// È˜terge un stop specific din listă
  void _removeStop(String stopName) {
    setState(() {
      _routeCtrl.intermediateStops.removeWhere((s) => s == stopName);
    });
    
    // Feedback vizual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mapStopRemoved(stopName)),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    // Update ruta după ștergere
    if (_routeCtrl.pickupLatitude != null && _routeCtrl.destinationLatitude != null) {
      _updateRouteWithAllPoints();
    }
  }

  // _buildIntermediateStopsList() extracted to lib/widgets/map/map_intermediate_stops.dart

  /// Curăță pickup-ul
  void _clearPickup() {
    setState(() {
      _routeCtrl.pickupController.clear();
      _routeCtrl.pickupLatitude = null;
      _routeCtrl.pickupLongitude = null;


    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pickupPointDeleted)),
      );
    }
    
    _updateMapWithAllPoints();
  }

  /// Curăță destinația
  void _clearDestination() {
    setState(() {
      _routeCtrl.destinationController.clear();
      _routeCtrl.destinationLatitude = null;
      _routeCtrl.destinationLongitude = null;

    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.destinationDeleted)),
      );
    }
    
    _updateMapWithAllPoints();
  }



  /// Update hartă cu noul pickup
  void _updateMapWithNewPickup() {
    if (_routeCtrl.pickupLatitude != null && _routeCtrl.pickupLongitude != null) {
      // Center camera pe pickup
      _mapboxMap?.flyTo(
        CameraOptions(
          center: MapboxUtils.createPoint(_routeCtrl.pickupLatitude!, _routeCtrl.pickupLongitude!),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 1000)
      );
      
      // Update route dacă avem și destinația
      if (_routeCtrl.destinationLatitude != null && _routeCtrl.destinationLongitude != null) {
        _updateRouteWithAllPoints();
      }
    }
  }

  /// Update hartă cu noua destinație
  void _updateMapWithNewDestination() {
    if (_routeCtrl.destinationLatitude != null && _routeCtrl.destinationLongitude != null) {
      // Update route dacă avem și pickup-ul
      if (_routeCtrl.pickupLatitude != null && _routeCtrl.pickupLongitude != null) {
        _updateRouteWithAllPoints();
      }
    }
  }



  /// Update hartă cu toate punctele
  void _updateMapWithAllPoints() {
    List<Point> allPoints = [];
    
    // Adaugă pickup
    if (_routeCtrl.pickupLatitude != null && _routeCtrl.pickupLongitude != null) {
      allPoints.add(Point(coordinates: Position(_routeCtrl.pickupLongitude!, _routeCtrl.pickupLatitude!)));
    }
    
    // Adaugă destination
    if (_routeCtrl.destinationLatitude != null && _routeCtrl.destinationLongitude != null) {
      allPoints.add(Point(coordinates: Position(_routeCtrl.destinationLongitude!, _routeCtrl.destinationLatitude!)));
    }
    
    // Adaugă intermediate stops
    // (Acest lucru ar trebui să fie gestionat de _buildWaypoints și _updateRouteWithAllPoints)
    // Pentru a centra camera pe toate punctele, ar trebui să geocodezi opririle aici
    // sau să te bazezi pe _buildWaypoints pentru a le obține.
    // Momentan, _fitCameraToPoints nu ia Ã®n considerare opririle intermediare.
    // Pentru simplitate, vom lăsa așa cum este, presupunând că pickup și destination sunt suficiente pentru centrare.
    
    // Fit camera pentru toate punctele
    if (allPoints.isNotEmpty) {
      _fitCameraToPoints(allPoints);
    }
    
    // Update route dacă avem pickup și destination
    if (_routeCtrl.pickupLatitude != null && _routeCtrl.destinationLatitude != null) {
      _updateRouteWithAllPoints();
    }
  }

  /// Fit camera pentru toate punctele
  void _fitCameraToPoints(List<Point> points) {
    if (points.isEmpty || _mapboxMap == null) return;
    
    double minLat = points.first.coordinates.lat.toDouble();
    double maxLat = points.first.coordinates.lat.toDouble();
    double minLng = points.first.coordinates.lng.toDouble();
    double maxLng = points.first.coordinates.lng.toDouble();
    
    for (var point in points) {
      minLat = math.min(minLat, point.coordinates.lat.toDouble());
      maxLat = math.max(maxLat, point.coordinates.lat.toDouble());
      minLng = math.min(minLng, point.coordinates.lng.toDouble());
      maxLng = math.max(maxLng, point.coordinates.lng.toDouble());
    }
    
    // Adaugă padding
    const double padding = 0.01; // ~1km
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;
    
    final center = Point(
      coordinates: Position(
        (minLng + maxLng) / 2,
        (minLat + maxLat) / 2,
      )
    );
    
    _mapboxMap?.flyTo(
      CameraOptions(center: center, zoom: 12.0),
      MapAnimationOptions(duration: AppDrawer.lowDataMode ? 600 : 1000)
    );
  }

  /// âœ… PERFORMANCE: Update route cu toate punctele - optimized with async
  void _updateRouteWithAllPoints() async {
    Logger.debug('Starting route update...');
    
    if (_routeCtrl.pickupLatitude == null || _routeCtrl.destinationLatitude == null) {
      Logger.debug('Missing pickup or destination - skipping route update');
      return;
    }
    
    try {
      // âœ… PERFORMANCE: Give UI time to settle before heavy operations
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      Logger.debug('Building waypoints...');
      final waypoints = await _buildWaypoints(); // âœ… CONECTARE: Folosește helper method
      Logger.debug('Built ${waypoints.length} waypoints');

      Logger.debug('Calculating route with ${waypoints.length} waypoints...');
      
      // âœ… PERFORMANCE: Execute in next frame to avoid blocking
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        
        try {
          // âœ… CONECTARE: Folosește _routingService helper method
          await _calculateRouteWithService(waypoints);
          // âœ… Ne-blocant: rute alternative pentru UI
          if (!AppDrawer.lowDataMode) {
            unawaited(_fetchAlternativeRoutes(waypoints));
          }
        } catch (e) {
          Logger.error('Route calculation failed: $e', error: e);
          if (mounted) {
            _showSafeSnackBar(AppLocalizations.of(context)!.mapRouteCalculationError(e.toString()), Colors.red);
          }
        }
      });
      
    } catch (e) {
      Logger.error('Route setup failed: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _showSafeSnackBar(AppLocalizations.of(context)!.mapRouteSetupError(e.toString()), Colors.red);
      }
    }
  }

  /// âœ… PERFORMANCE: Helper method pentru building waypoints
  Future<List<Point>> _buildWaypoints() async {
    List<Point> waypoints = [];
    
    // Pickup
    if (_routeCtrl.pickupLatitude != null && _routeCtrl.pickupLongitude != null) {
      waypoints.add(Point(
        coordinates: Position(_routeCtrl.pickupLongitude!, _routeCtrl.pickupLatitude!)
      ));
      Logger.debug('Added pickup waypoint');
    }
    
    // Stops
    if (_routeCtrl.intermediateStops.isNotEmpty) {
      for (var stop in _routeCtrl.intermediateStops) {
        // Implementează geocoding pentru opririle intermediare
        final coordinates = await _getCoordinatesForDestination(stop);
        if (coordinates != null) {
          waypoints.add(coordinates);
          Logger.debug('Added intermediate stop: $stop');
        }
      }
      Logger.debug('Found ${_routeCtrl.intermediateStops.length} intermediate stops');
    }
    
    // Destination
    if (_routeCtrl.destinationLatitude != null && _routeCtrl.destinationLongitude != null) {
      waypoints.add(Point(
        coordinates: Position(_routeCtrl.destinationLongitude!, _routeCtrl.destinationLatitude!)
      ));
      Logger.debug('Added destination waypoint');
    }
    
    return waypoints;
  }

  /// Start ride request complet
  void _startRideRequest() async {
    // Validare
    if (_routeCtrl.pickupLatitude == null || _routeCtrl.destinationLatitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectPickupAndDestination),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_contactUids == null) {
      if (!mounted) return;
      _showSafeSnackBar(
        'Se încarcă contactele din agendă. Încearcă din nou în câteva secunde.',
        Colors.orange,
      );
      unawaited(_loadContactUids());
      return;
    }
    if (!_canRequestRideWithContactFilter()) {
      if (!mounted) return;
      _showSafeSnackBar(
        'Nabour trimite cererea doar către șoferii din contactele tale. Adaugă în agendă numerele prietenilor cu cont Nabour sau acordă permisiunea la contacte.',
        Colors.orange,
      );
      return;
    }

    try {
      // Creează obiectul Ride
      final newRide = Ride(
        id: '',
        passengerId: FirebaseAuth.instance.currentUser?.uid ?? '',  // âœ… MODIFICAT: userId â†’ passengerId
        startAddress: _routeCtrl.pickupController.text,
        destinationAddress: _routeCtrl.destinationController.text,
        distance: 0, // Va fi calculat de serviciu
        startLatitude: _routeCtrl.pickupLatitude!,
        startLongitude: _routeCtrl.pickupLongitude!,
        destinationLatitude: _routeCtrl.destinationLatitude!,
        destinationLongitude: _routeCtrl.destinationLongitude!,
        durationInMinutes: 0, // Va fi calculat de serviciu
        baseFare: 0, // Va fi calculat de serviciu
        perKmRate: 0, // Va fi calculat de serviciu
        perMinRate: 0, // Va fi calculat de serviciu
        totalCost: 0, // Va fi calculat de serviciu
        appCommission: 0, // Va fi calculat de serviciu
        driverEarnings: 0, // Va fi calculat de serviciu
        timestamp: DateTime.now(),
        status: 'pending',
        category: RideCategory.standard,
        stops: await Future.wait(_routeCtrl.intermediateStops.map<Future<Map<String, dynamic>>>((stop) async {
          // âœ… FIX: Geocoding real pentru opriri (nu coordonate default)
          final coordinates = await _getCoordinatesForDestination(stop);
          return {
            'address': stop,
            'name': stop,
            'latitude': coordinates?.coordinates.lat ?? 44.4268, // Fallback doar dacă geocoding eșuează
            'longitude': coordinates?.coordinates.lng ?? 26.1025, // Fallback doar dacă geocoding eșuează
          };
        })),
        allowedDriverUids: _contactUids!.toList(), // doar contacte (deja validate mai sus)
      );
      
      final rideId = await _firestoreService.requestRide(newRide);
      if (!mounted) return;
      
      // Success feedback
      unawaited(HapticService.instance.heavy());
      Navigator.push<Object?>(
        context,
        AppTransitions.slideUp(SearchingForDriverScreen(rideId: rideId)),
      ).then(_onSearchingForDriverPopped);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.mapCreateRideError(e.toString()))),
      );
    }
  }

  // ── POI Category Sheet ─────────────────────────────────────────────
  Future<void> _placeCommunityMysteryBoxFlow() async {
    final pos = _currentPositionObject;
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mapWaitingGpsToPlaceBox)),
        );
      }
      return;
    }
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final msgCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.mapCommunityMysteryBoxTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(ctx)!.mapCommunityMysteryBoxDescription(TokenCost.mysteryBoxSlot),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                maxLength: 120,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(ctx)!.mapShortMessageOptional,
                  hintText: AppLocalizations.of(ctx)!.mapShortMessageHint,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(ctx)!.mapPlace),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      msgCtrl.dispose();
      return;
    }
    try {
      final id = await CommunityMysteryBoxService.instance.place(
        lat: pos.latitude,
        lng: pos.longitude,
        message: msgCtrl.text.trim(),
      );
      msgCtrl.dispose();
      if (!mounted) return;
      if (id != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.mapBoxPlaced(TokenCost.mysteryBoxSlot),
            ),
            backgroundColor: Colors.teal.shade700,
          ),
        );
        unawaited(_communityMysteryManager?.updateBoxes(
          pos.latitude,
          pos.longitude,
          force: true,
        ));
      }
    } on FirebaseFunctionsException catch (e) {
      msgCtrl.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Nu am putut plasa cutia.')),
      );
    } catch (e) {
      msgCtrl.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString()))),
      );
    }
  }

  void _showPoiCategorySheet() {
    showModalBottomSheet<PoiCategory>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Puncte de interes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              MapPoiCategoryChips(
                onCategoryTapped: (category) {
                  Navigator.of(ctx).pop(category);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).then((category) {
      if (category != null && mounted) {
        _onPoiCategorySelected(category);
      }
    });
  }

  Future<void> _onPoiCategorySelected(PoiCategory category) async {
    if (_currentPositionObject == null) return;

    final lat = _currentPositionObject!.latitude;
    final lng = _currentPositionObject!.longitude;

    try {
      final pois = await PoiService().fetchPoisFromApi(
        {'latitude': lat, 'longitude': lng},
        category,
        radiusKm: 3.0,
      );

      if (!mounted) return;

      if (pois.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mapNoPoiFoundInArea(category.displayName))),
        );
        return;
      }

      setState(() {
        _currentPois
          ..clear()
          ..addAll(pois);
      });

      if (!_poiLayersInitialized) {
        await _ensurePoiLayersInitialized();
      }
      await _updatePoiGeoJson(pois);

      Logger.info('Loaded ${pois.length} POIs for ${category.displayName}', tag: 'POI');

      _showPoiListSheet(category, pois);
    } catch (e) {
      Logger.error('Failed to load POIs for ${category.displayName}: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mapPoiLoadError(e.toString()))),
        );
      }
    }
  }

  void _showPoiListSheet(PoiCategory category, List<PointOfInterest> pois) {
    showModalBottomSheet<PointOfInterest>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (ctx) {
        final sheetH = MediaQuery.sizeOf(ctx).height * 0.6;
        return SafeArea(
          child: SizedBox(
            height: sheetH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${category.emoji} ${category.displayName}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  '${pois.length} rezultate in zona ta',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: pois.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (ctx, i) {
                    final poi = pois[i];
                    final distM = _currentPositionObject != null
                        ? _calculateDirectDistance(
                            _currentPositionObject!.latitude,
                            _currentPositionObject!.longitude,
                            poi.location.latitude,
                            poi.location.longitude,
                          )
                        : null;
                    String distLabel = '';
                    if (distM != null) {
                      distLabel = distM >= 1000
                          ? '${(distM / 1000).toStringAsFixed(1)} km'
                          : '${distM.round()} m';
                    }

                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(category.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      title: Text(
                        poi.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: poi.description.isNotEmpty
                          ? Text(
                              poi.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            )
                          : null,
                      trailing: distLabel.isNotEmpty
                          ? Text(
                              distLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            )
                          : null,
                      onTap: () => Navigator.of(ctx).pop(poi),
                    );
                  },
                ),
              ),
            ],
            ),
          ),
        );
      },
    ).then((selectedPoi) {
      if (selectedPoi != null && mounted) {
        _onPoiTapped(selectedPoi);
      }
    });
  }

  /// Widget pentru butonul de start ride
  // _buildStartRideButton() extracted to lib/widgets/map/map_ride_info_panel.dart
  void _closePoiCard() {
    Logger.debug('Closing POI card safely...');
    if (mounted) {
      try {
        setState(() {
          // Doar Ã®nchide cardul; NU afecta adresele sau selecția din AddressInputView
          _showPoiCard = false;
        });
        // Curăță highlight la Ã®nchiderea cardului
        unawaited(_clearSelectedPoiHighlight());
        Logger.debug('POI card closed successfully');
      } catch (e) {
        Logger.error('Error closing POI card: $e', error: e);
      }
    }
  }

  /// âœ… PERFORMANCE: Deferred RideRequestPanel update for pickup
  void _updateRideRequestPanelPickup(PointOfInterest poi) {
    Logger.info('Calling RideRequestPanel setPickup...');
    _ensureRidePanelVisibleForExternalAction(() {
      _rideRequestPanelKey.currentState?.setPickup(
        address: poi.name,
        latitude: poi.location.latitude,
        longitude: poi.location.longitude,
      );
    });
  }

  /// âœ… PERFORMANCE: Deferred RideRequestPanel update for destination
  void _updateRideRequestPanelDestination(PointOfInterest poi) {
    Logger.info('Calling RideRequestPanel setDestination...');
    _ensureRidePanelVisibleForExternalAction(() {
      _rideRequestPanelKey.currentState?.setDestination(
        address: poi.name,
        latitude: poi.location.latitude,
        longitude: poi.location.longitude,
      );
    });
  }

  /// âœ… PERFORMANCE: Batch map updates pentru a reduce overhead-ul
  void _batchMapUpdates() async {
    if (!mounted) return;
    
    Logger.debug('Starting batch map updates...');
    
    // âœ… PERFORMANCE: Collect all updates
    final List<Future<void> Function()> updates = [];
    
    if (_routeCtrl.pickupLatitude != null && _routeCtrl.pickupLongitude != null) {
      updates.add(() async {
        Logger.debug('Updating pickup marker...');
        await _addPickupMarker();
      });
    }
    
    if (_routeCtrl.destinationLatitude != null && _routeCtrl.destinationLongitude != null) {
      updates.add(() async {
        Logger.debug('Updating destination marker...');
        final coordinates = Point(coordinates: Position(_routeCtrl.destinationLongitude!, _routeCtrl.destinationLatitude!));
        await _addDestinationMarker(coordinates, 'Destinație');
      });
    }
    
    if (_routeCtrl.intermediateStops.isNotEmpty) {
      updates.add(() async {
        Logger.debug('Updating stop markers...');
        await _addStopMarkers();
      });
    }
    
    // âœ… PERFORMANCE: Execute all updates with frame delays
    for (int i = 0; i < updates.length; i++) {
      if (!mounted) break;
      
      try {
        await updates[i]();
        // âœ… PERFORMANCE: One frame delay between operations
        if (i < updates.length - 1) {
          await Future.delayed(const Duration(milliseconds: 16)); // 60fps = 16ms per frame
        }
      } catch (e) {
        Logger.error('Map update $i failed: $e', error: e);
      }
    }
    
    Logger.info('Batch map updates completed');
  }

  /// âœ… PERFORMANCE: Add pickup marker with performance optimization
  Future<void> _addPickupMarker() async {
    // Implementation for adding pickup marker
    // This would replace existing map marker logic
    Logger.info('Pickup marker added');
  }

  /// âœ… PERFORMANCE: Add stop markers with performance optimization (reserved)
  Future<void> _addStopMarkers() async {
    // Implementation for adding stop markers
    // This would replace existing map marker logic
    Logger.info('Stop markers added');
  }

  Future<void> _fetchAlternativeRoutes(List<Point> waypoints) async {
    if (!mounted) return;
    setState(() { _routeCtrl.isFetchingAlternatives = true; _routeCtrl.alternativeRoutes = []; _routeCtrl.selectedAltRouteIndex = 0; });
    try {
      final data = await _routingService.getAlternativeRoutes(waypoints);
      if (!mounted) return;
      final routes = (data?['routes'] as List?) ?? const [];
      setState(() { _routeCtrl.alternativeRoutes = routes.cast<Map<String, dynamic>>(); });
    } catch (e) {
      Logger.error('Alternative routes fetch failed: $e', error: e);
    } finally {
      if (mounted) setState(() { _routeCtrl.isFetchingAlternatives = false; });
    }
  }

  // Heuristic entrance picker (client-only)
  void _maybeShowEntrancePicker(PointOfInterest poi) {
    final name = poi.name.toLowerCase();
    final largePoiKeywords = ['mall', 'spital', 'hospital', 'university', 'campus', 'aeroport'];
    final isLarge = largePoiKeywords.any((k) => name.contains(k));
    if (!isLarge) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final entries = ['Nord', 'Est', 'Sud', 'Vest'];
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Alege intrarea', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: entries.map((e) {
                return ActionChip(
                  label: Text(e),
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Heuristică: offset mic pe direcție
                    final delta = 0.0008; // ~80m
                    double lat = poi.location.latitude;
                    double lng = poi.location.longitude;
                    switch (e) {
                      case 'Nord': lat += delta; break;
                      case 'Sud': lat -= delta; break;
                      case 'Est': lng += delta; break;
                      case 'Vest': lng -= delta; break;
                    }
                    final adjustedPoi = PointOfInterest(
                      id: poi.id,
                      name: '${poi.name} - $e',
                      description: poi.description,
                      imageUrl: poi.imageUrl,
                      location: geolocator.Position(
                        latitude: lat,
                        longitude: lng,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitude: 0,
                        altitudeAccuracy: 0,
                        heading: 0,
                        headingAccuracy: 0,
                        speed: 0,
                        speedAccuracy: 0,
                      ),
                      category: poi.category,
                      isStatic: poi.isStatic,
                      additionalInfo: poi.additionalInfo,
                    );
                    _onPoiTapped(adjustedPoi);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
        );
      },
    );
  }

  void _generatePickupSuggestionsAround(PointOfInterest poi) async {
    if (_pickupSuggestionsManager == null) return;
    try {
      await _pickupSuggestionsManager?.deleteAll();
      final baseLat = poi.location.latitude;
      final baseLng = poi.location.longitude;
      const deltas = [
        [0.0005, 0.0],
        [0.0, 0.0005],
        [-0.0005, 0.0],
        [0.0, -0.0005],
      ];
      final points = <Point>[];
      final options = <CircleAnnotationOptions>[];
      for (final d in deltas) {
        final lat = baseLat + d[0];
        final lng = baseLng + d[1];
        final p = MapboxUtils.createPoint(lat, lng);
        points.add(p);
        options.add(CircleAnnotationOptions(
          geometry: p,
          circleRadius: 8,
          circleColor: Colors.orange.toARGB32(),
          circleStrokeWidth: 2,
          circleStrokeColor: Colors.white.toARGB32(),
        ));
      }
      setState(() {
        _routeCtrl.pickupSuggestionPoints = points;
        _routeCtrl.showPickupSuggestions = true;
      });
      await _pickupSuggestionsManager?.createMulti(options);
    } catch (e) {
      Logger.error('Failed to generate pickup suggestions: $e', error: e);
    }
  }

  /// âœ… CONECTARE: Helper method pentru route calculation cu _routingService
  Future<void> _calculateRouteWithService(List<Point> waypoints) async {
    if (!mounted) return;
    
    try {
      Logger.debug('Calculating route with service for ${waypoints.length} waypoints...');
      
      // âœ… FOLOSEÈ˜TE _routingService instance
      final routeData = await _routingService.getRoute(waypoints);
      
      if (!mounted) return;
      
      if (routeData != null) {
        Logger.debug('Route calculated successfully with service');
        await _onRouteCalculated(routeData);
        // AUTO-PROGRESSION: dacă voice este activ, Ã®ncearcă auto-booking după calcul rută
        try {
          if (!mounted) return;
          try {
            final voice = Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
            if (voice.isVoiceActive && routeData.isNotEmpty) {
              voice.updateBookingProgress('Ruta calculată cu succes! Estimez prețul și pornesc rezervarea...');
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && voice.isVoiceActive) {
                  _autoProgressToBooking(voice);
                }
              });
            }
          } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
        } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      } else {
        Logger.debug('Route calculation returned null');
        if (mounted) {
          _showSafeSnackBar(AppLocalizations.of(context)!.mapCouldNotCalculateRoute, Colors.orange);
        }
      }
    } catch (e) {
      Logger.error('Route calculation with service failed: $e', error: e);
      if (mounted) {
        _showSafeSnackBar(AppLocalizations.of(context)!.mapRouteCalculationError(e.toString()), Colors.red);
      }
    }
  }

  Future<void> _autoProgressToBooking(FriendsRideVoiceIntegration voice) async {
    try {
      if (_routeCtrl.pickupLatitude == null || _routeCtrl.destinationLatitude == null) {
        voice.updateBookingProgress('Nu pot continua - informații de locație incomplete.');
        return;
      }
      if (_contactUids == null) {
        voice.updateBookingProgress('Aștept încărcarea contactelor din agendă. Încearcă rezervarea manual peste câteva secunde.');
        unawaited(_loadContactUids());
        return;
      }
      if (!_canRequestRideWithContactFilter()) {
        voice.updateBookingProgress(
          'Nu există utilizatori Nabour în agendă. Adaugă contacte cu numerele lor ca să poți comanda prin rețea.',
        );
        return;
      }
      final newRide = Ride(
        id: '',
        passengerId: FirebaseAuth.instance.currentUser?.uid ?? '',
        startAddress: _routeCtrl.pickupController.text.isNotEmpty ? _routeCtrl.pickupController.text : 'Locația curentă',
        destinationAddress: _routeCtrl.destinationController.text,
        distance: (_routeCtrl.currentRouteDistanceMeters ?? 0) / 1000,
        startLatitude: _routeCtrl.pickupLatitude!,
        startLongitude: _routeCtrl.pickupLongitude!,
        destinationLatitude: _routeCtrl.destinationLatitude!,
        destinationLongitude: _routeCtrl.destinationLongitude!,
        durationInMinutes: (_routeCtrl.currentRouteDurationSeconds ?? 0) / 60,
        baseFare: 0,
        perKmRate: 0,
        perMinRate: 0,
        totalCost: 0,
        appCommission: 0,
        driverEarnings: 0,
        timestamp: DateTime.now(),
        status: 'pending',
        category: RideCategory.standard,
        stops: await Future.wait(_routeCtrl.intermediateStops.map<Future<Map<String, dynamic>>>((stop) async {
          // âœ… FIX: Geocoding real pentru opriri (nu coordonate default)
          final coordinates = await _getCoordinatesForDestination(stop);
          return {
            'address': stop,
            'name': stop,
            'latitude': coordinates?.coordinates.lat ?? 44.4268, // Fallback doar dacă geocoding eșuează
            'longitude': coordinates?.coordinates.lng ?? 26.1025, // Fallback doar dacă geocoding eșuează
          };
        })),
        allowedDriverUids: _contactUids!.toList(),
      );
      voice.updateBookingProgress('Creez solicitarea de cursă...');
      final rideId = await _firestoreService.requestRide(newRide);
      voice.updateBookingProgress('✅ Solicitarea de cursă a fost trimisă! Caut șoferi disponibili...');
      
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.push<Object?>(
            context,
            AppTransitions.slideUp(SearchingForDriverScreen(rideId: rideId)),
          ).then(_onSearchingForDriverPopped);
          voice.stopVoiceInteraction();
        });
      }
    } catch (e) {
      Logger.error('Auto-booking error: $e', tag: 'MAP_SCREEN', error: e);
      voice.updateBookingProgress('A apărut o eroare la crearea rezervării. Vă rog să încercați manual.');
    }
  }
  Future<void> _toggleFlashlight() async {
    try {
      final hasTorch = await TorchLight.isTorchAvailable();
      if (!hasTorch) {
        if (mounted) _showSafeSnackBar(AppLocalizations.of(context)!.mapFlashlightUnavailable, Colors.orange);
        return;
      }
      if (_flashlightOn) {
        await TorchLight.disableTorch();
        if (mounted) setState(() => _flashlightOn = false);
      } else {
        await TorchLight.enableTorch();
        if (mounted) setState(() => _flashlightOn = true);
      }
    } catch (e) {
      Logger.warning('Flashlight toggle error: $e', tag: 'MAP');
      if (mounted) _showSafeSnackBar(AppLocalizations.of(context)!.mapFlashlightActivationError, Colors.red);
    }
  }

  Future<void> _startPulseMode() async {
    if (_isPulseActive) return;
    
    // 1. Pregătim starea Pulse
    if (mounted) {
      setState(() {
        _isPulseActive = true;
      });
    }
    
    Logger.info('Pulse Mode started (Shake detected)');
    HapticFeedback.vibrate();

    // 2. Publicăm starea isPulsing către vecini
    final pos = _currentPositionObject;
    if (pos != null && _isVisibleToNeighbors) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        publishNeighborMapVisibilityUnawaited(
          position: pos,
          avatar: _neighborAvatarCache[uid] ?? '🙂',
          displayName: _neighborDisplayNameCache[uid] ?? 'Vecin',
          isDriver: _currentRole == UserRole.driver && _isDriverAvailable,
          licensePlate: _neighborLicensePlateCache[uid],
          photoURL: _neighborPhotoURLCache[uid],
          allowedUids: _contactUids?.toList() ?? [],
          isPulsing: true,
          carAvatarId: _effectivePublishedCarAvatarId(
            uid,
            useDriverGarageSlot: _mapShowsDriverTransportIdentity,
          ),
        );
      }
    }

    // 3. Verificăm interactiv dacă cineva din jur pulsează deja (Match instant)
    _checkForPulseMatches();

    // 4. Feedback vizual fizic (Blitz intermitent la shake)
    final wasFlashlightOn = _flashlightOn;
    final endTime = DateTime.now().add(const Duration(seconds: 4));
    bool isOn = false;
    
    try {
      final hasTorch = await TorchLight.isTorchAvailable();
      while (DateTime.now().isBefore(endTime) && mounted && hasTorch) {
        isOn ? await TorchLight.disableTorch() : await TorchLight.enableTorch();
        isOn = !isOn;
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }

    try {
      if (wasFlashlightOn) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    
    if (mounted) {
      setState(() {
        _isPulseActive = false;
      });
    }

    // Resetăm starea isPulsing la false pe server
    if (pos != null && _isVisibleToNeighbors && mounted) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        publishNeighborMapVisibilityUnawaited(
          position: pos,
          avatar: _neighborAvatarCache[uid] ?? '🙂',
          displayName: _neighborDisplayNameCache[uid] ?? 'Vecin',
          isDriver: _currentRole == UserRole.driver && _isDriverAvailable,
          licensePlate: _neighborLicensePlateCache[uid],
          photoURL: _neighborPhotoURLCache[uid],
          allowedUids: _contactUids?.toList() ?? [],
          isPulsing: false,
          carAvatarId: _effectivePublishedCarAvatarId(
            uid,
            useDriverGarageSlot: _mapShowsDriverTransportIdentity,
          ),
        );
      }
    }
    
    Logger.info('Pulse Mode stopped');
  }

  void _checkForPulseMatches() {
    if (_lastRawNeighborsForMap.isEmpty) return;
    
    // Căutăm vecini care au isPulsing: true
    final pulsingNeighbors = _lastRawNeighborsForMap.where((n) => n.isPulsing).toList();
    
    if (pulsingNeighbors.isNotEmpty) {
      Logger.info('SOCIAL MATCH! ${pulsingNeighbors.length} neighbors are pulsing nearby.');
      HapticFeedback.heavyImpact();
      
      // Notificare vizuală
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Te-ai conectat cu ${pulsingNeighbors.first.displayName} și încă ${pulsingNeighbors.length - 1} vecini!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7C3AED), // Nabour Purple
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      
      // Sunet de succes
      _audioService.playMessageReceivedSound();
    }
  }
  /// ✅ CONECTARE: Quick route update pentru POI changes
  Future<void> _updateRouteAfterPOI() async {
    if (_routeCtrl.pickupLatitude != null && _routeCtrl.destinationLatitude != null) {
      try {
        final List<Point> waypoints = [];
        waypoints.add(Point(coordinates: Position(_routeCtrl.pickupLongitude!, _routeCtrl.pickupLatitude!)));
        for (final stop in _routeCtrl.intermediateStops) {
          final coord = await _getCoordinatesForDestination(stop);
          if (coord != null) waypoints.add(coord);
        }
        waypoints.add(Point(coordinates: Position(_routeCtrl.destinationLongitude!, _routeCtrl.destinationLatitude!)));
        
        await _onRouteCalculated(await _routingService.getRoute(waypoints));
      } catch (e) {
        Logger.error('Route update after POI error: $e', error: e);
      }
    }
  }

  void _listenToShake() {
    _accelerometerSubscription = userAccelerometerEventStream().listen(
      (event) {
        final double acceleration = math.sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z);
        if (acceleration > _MapScreenState._shakeThreshold && !_isPulseActive) {
          final now = DateTime.now();
          if (now.difference(_lastShakeTime) > _MapScreenState._shakeWindow) {
            _shakeCount = 0;
          }
          _shakeCount++;
          _lastShakeTime = now;
          if (_shakeCount >= _MapScreenState._requiredShakes) {
            _shakeCount = 0;
            _startPulseMode();
          }
        }
      },
      onError: (Object e) {
        _accelerometerSubscription?.cancel();
        _accelerometerSubscription = null;
        final s = e.toString();
        if (s.contains('NO_SENSOR') || s.contains('Sensor not found')) {
          Logger.debug(
            'Pulse shake: dispozitiv fără accelerometru user (ex. unele tablete) — modul shake ignorat.',
            tag: 'MAP',
          );
          return;
        }
        Logger.error('Pulse mode shake error: $e');
      },
      cancelOnError: true,
    );
  }

  void _showSafeSnackBar(String message, Color backgroundColor, {SnackBarAction? action}) {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          action: action,
        ),
      );
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
  }

  Future<Uint8List> _generateParkingIcon(bool isReserved) async {
    const double size = 100;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
    final paint = ui.Paint()..isAntiAlias = true;

    // 1. GALAXY GLOW
    paint
      ..color = Colors.amber.withValues(alpha: 0.3)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12);
    canvas.drawCircle(const ui.Offset(size / 2, size / 2), 35, paint);
    paint.maskFilter = null;

    // 2. NEON RING
    paint
      ..color = Colors.amber
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const ui.Offset(size / 2, size / 2), 30, paint);

    // 3. INNER BG
    paint
      ..color = const Color(0xFF1A237E)
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(const ui.Offset(size / 2, size / 2), 28, paint);

    // 4. DRAW "P"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'P',
        style: TextStyle(
          color: Colors.amber,
          fontSize: 38,
          fontWeight: FontWeight.w900,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      ui.Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _clearParkingYieldTarget() async {
    _parkingYieldTargetLat = null;
    _parkingYieldTargetLng = null;
    _awaitingParkingYieldMapPick = false;
    if (_parkingYieldMySpotAnnotation != null && _parkingYieldMySpotManager != null) {
      try {
        await _parkingYieldMySpotManager!.delete(_parkingYieldMySpotAnnotation!);
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }
    _parkingYieldMySpotAnnotation = null;
    if (mounted) setState(() {});
  }

  Future<void> _updateParkingYieldMySpotMarker() async {
    if (_mapboxMap == null || !mounted) return;
    final lat = _parkingYieldTargetLat;
    final lng = _parkingYieldTargetLng;
    if (lat == null || lng == null) return;

    _parkingYieldMySpotManager ??= await _mapboxMap!.annotations.createPointAnnotationManager(
      id: 'parking-yield-my-spot',
    );
    if (_parkingYieldMySpotAnnotation != null) {
      try {
        await _parkingYieldMySpotManager!.delete(_parkingYieldMySpotAnnotation!);
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      _parkingYieldMySpotAnnotation = null;
    }
    _parkingIconInFlight ??= _generateParkingIcon(false);
    final iconBytes = await _parkingIconInFlight!;
    final parkingImageName = 'nabour_parking_yield_me';
    final pkgImgOk = await _registerStyleImageFromPng(parkingImageName, iconBytes);
    
    final ann = await _parkingYieldMySpotManager!.create(
      PointAnnotationOptions(
        geometry: MapboxUtils.createPoint(lat, lng),
        iconImage: pkgImgOk ? parkingImageName : null,
        // image: iconBytes, // DO NOT USE
        iconSize: 0.92,
        textField: 'LOCUL MEU',
        textColor: Colors.lightGreenAccent.toARGB32(),
        textHaloColor: Colors.black.toARGB32(),
        textHaloWidth: 2.0,
        textSize: 9,
        textOffset: [0.0, 2.5],
      ),
    );
    _parkingYieldMySpotAnnotation = ann;
  }

  Future<void> _applyParkingYieldTarget(double lat, double lng) async {
    _parkingYieldTargetLat = lat;
    _parkingYieldTargetLng = lng;
    await _updateParkingYieldMySpotMarker();
    if (!mounted) return;
    setState(() {});
    final map = _mapboxMap;
    if (map != null) {
      try {
        await map.flyTo(
          CameraOptions(center: MapboxUtils.createPoint(lat, lng), zoom: 16.2),
          MapAnimationOptions(duration: 650),
        );
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }
  }

  Future<void> _finishParkingYieldMapPick(Point point) async {
    if (!mounted) return;
    setState(() => _awaitingParkingYieldMapPick = false);
    final lat = point.coordinates.lat.toDouble();
    final lng = point.coordinates.lng.toDouble();
    await _applyParkingYieldTarget(lat, lng);
    if (!mounted) return;
    _showSafeSnackBar(
      'Loc marcat după coordonate. Poți porni navigarea din meniul parcare când ești departe.',
      Colors.green.shade700,
    );
  }

  Future<void> _showEstablishParkingYieldDialog() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Identifică locul de parcare',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Mai întâi stabilim punctul exact pe hartă (coordenate). '
          'Apoi te poți ghida navigând la el; când ești în zonă, poți face locul disponibil pentru vecini.',
          style: TextStyle(color: Colors.white70, height: 1.35),
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Anulează', style: TextStyle(color: Colors.grey.shade400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'map'),
            child: const Text('Pe hartă', style: TextStyle(color: Colors.amber)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'gps'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Unde sunt acum', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'gps') {
      final p = _currentPositionObject;
      if (p == null) return;
      await _applyParkingYieldTarget(p.latitude, p.longitude);
      _showSafeSnackBar(
        'Loc setat la poziția curentă. Dacă nu ești la parcare, folosește „Navighează” din același buton.',
        Colors.amber.shade800,
      );
    } else if (choice == 'map') {
      setState(() => _awaitingParkingYieldMapPick = true);
      _showSafeSnackBar(
        'Ține apăsat pe hartă exact la locul de parcare.',
        Colors.amber.shade800,
      );
    }
  }

  Future<void> _showNavigateToParkingYieldSheet(double distanceM) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final r = _MapScreenState._parkingYieldVerifyRadiusM.round();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Încă nu ești la locul marcat',
                  style: TextStyle(
                    color: Colors.amber.shade200,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'GPS-ul tău e la circa ${distanceM.round()} m față de coordonatele locului. '
                  'Navighează la punctul „LOCUL MEU”; când distanța e sub $r m, poți disponibiliza locul.',
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final la = _parkingYieldTargetLat;
                    final ln = _parkingYieldTargetLng;
                    if (la == null || ln == null) return;
                    unawaited(_startInAppNavigation(la, ln, 'Locul tău de parcare'));
                  },
                  icon: const Icon(Icons.navigation_rounded),
                  label: Text(AppLocalizations.of(context)!.mapNavigateToMarkedPlace),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _clearParkingYieldTarget();
                  },
                  child: Text(AppLocalizations.of(context)!.mapDeleteMarkerAndRestart),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndAnnounceParkingYield() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Disponibilizezi locul?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Coordonatele marcate vor fi anunțate ca loc liber. '
          'Primești tokeni dacă un vecin îl ocupă.',
          style: TextStyle(color: Colors.white70),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NU', style: TextStyle(color: Colors.amber)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('DA', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final la = _parkingYieldTargetLat;
    final ln = _parkingYieldTargetLng;
    if (la == null || ln == null) return;

    final id = await ParkingSwapService().announceLeaving(la, ln);
    if (!mounted) return;
    if (id != null) {
      await _clearParkingYieldTarget();
      _showSafeSnackBar(l10n.mapSpotAnnouncedAvailable, Colors.green.shade700);
    } else {
      _showSafeSnackBar(l10n.mapCouldNotAnnounceTryAgain, Colors.red.shade800);
    }
  }

  void _showParkingSwapDialog(String firestoreSpotId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ParkingReservationSheet(
        spotId: firestoreSpotId,
        onReserved: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.mapSpotReserved)),
          );
        },
      ),
    );
  }

  void _handleLeavingParking() async {
    if (!mounted) return;

    if (_awaitingParkingYieldMapPick) {
      setState(() => _awaitingParkingYieldMapPick = false);
      _showSafeSnackBar(AppLocalizations.of(context)!.mapSelectionCancelled, Colors.grey.shade700);
      return;
    }

    if (_currentPositionObject == null) {
      _showSafeSnackBar(
        'Activează locația ca să folosești schimbul de parcare.',
        Colors.orange.shade800,
      );
      return;
    }

    if (_parkingYieldTargetLat == null || _parkingYieldTargetLng == null) {
      await _showEstablishParkingYieldDialog();
      return;
    }

    final pos = _currentPositionObject!;
    final dist = geolocator.Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      _parkingYieldTargetLat!,
      _parkingYieldTargetLng!,
    );

    if (dist > _MapScreenState._parkingYieldVerifyRadiusM) {
      await _showNavigateToParkingYieldSheet(dist);
      return;
    }

    await _confirmAndAnnounceParkingYield();
  }
}

