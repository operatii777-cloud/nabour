// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapOsmMethods on _MapScreenState {
  List<fm.Marker> _buildOsmMarkers() {
    final List<fm.Marker> osmMarkers = [];
    final avatars = CarAvatarService().getAvailableAvatars();

    // 1. Neighbors & Driver Avatars
    final currentZoom = _osmMapController?.camera.zoom ?? 15.0;
    // Mapbox base 0.784 scale logic: 
    // Calculăm o dimensiune de bază care se ajustează cu zoom-ul (similar cu icon-size în Mapbox)
    final double zoomFactor = math.pow(1.35, currentZoom - 15).toDouble();
    // Aplicăm reducerea de 35% (factor 0.65) solicitată pentru OSM
    final double baseMarkerDimension = 220.0 * 0.784 * zoomFactor * 0.65;
    final double finalSize = baseMarkerDimension.clamp(35.0, 130.0);

    final displayByUid = _lastNeighborDisplayByUid;
    for (final neighbor in _lastFilteredNeighborsForMap) {
      final uid = neighbor.uid;
      // Resolve avatar ID with fallback
      String avatarId = neighbor.carAvatarId ?? (neighbor.isDriver ? 'default_car' : 'robo');
      
      final avatar = avatars.firstWhere(
        (a) => a.id == avatarId, 
        orElse: () => avatars.first
      );
      
      final name = _neighborDisplayNameCache[uid] ?? neighbor.displayName;
      final disp = displayByUid[uid];
      final plat = disp?.lat ?? neighbor.lat;
      final plng = disp?.lng ?? neighbor.lng;

      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(plat, plng),
          width: 200, // Mai lat pentru nume lungi
          height: 240, // Suficient pentru Avatar + Nume + Spacing
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _onNeighborClicked(uid),
            child: AnimatedAvatarMarker(
              assetPath: avatar.assetPath,
              size: finalSize,
              name: name,
              isFloating: false,
            ),
          ),
        ),
      );
    }

    // 2. Chat Bubbles
    for (final uid in _mapChatBubbleTexts.keys) {
      final text = _mapChatBubbleTexts[uid];
      if (text == null || text.isEmpty) continue;
      
      double? lat, lng;
      if (uid == FirebaseAuth.instance.currentUser?.uid) {
        final pos = _currentPositionObject;
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } else {
        final neighbor = _neighborData[uid];
        if (neighbor != null) {
          final disp = displayByUid[uid];
          lat = disp?.lat ?? neighbor.lat;
          lng = disp?.lng ?? neighbor.lng;
        }
      }
      
      if (lat != null && lng != null) {
        osmMarkers.add(
          fm.Marker(
            point: ll.LatLng(lat, lng),
            width: 180,
            height: 100,
            alignment: const Alignment(0, -1.8), // Deasupra avatarului
            child: MapSpeechBubble(
              text: text,
              isTyping: _mapChatBubbleTyping[uid] ?? false,
              onDismissed: () {
                if (mounted) setState(() => _mapChatBubbleTexts.remove(uid));
              },
            ),
          ),
        );
      }
    }

    // 3. Emoji Reactions (Smart Offset)
    final List<MapEmoji> emojis = _lastReceivedEmojis;
    final Map<String, ({double lat, double lng})> emojiLayout = _buildStaircaseLayout(
      emojis.map((e) => (id: e.id, lat: e.lat, lng: e.lng)).toList(),
      stepMeters: 18.0,
    );

    for (final emoji in emojis) {
      final p = emojiLayout[emoji.id] ?? (lat: emoji.lat, lng: emoji.lng);
      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(p.lat, p.lng),
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Center(
              child: Text(
                emoji.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        ),
      );
    }

    // 4. Neighborhood Requests
    final requests = _requestsManager?.activeRequests.values ?? [];
    for (final req in requests) {
      // Filtrăm după raza de 6 km (similar cu Mapbox implementation)
      final pos = _currentPositionObject;
      if (pos != null) {
        final km = geolocator.Geolocator.distanceBetween(
          pos.latitude, pos.longitude, req.lat, req.lng
        ) / 1000.0;
        if (km > 6.0) continue;
      }

      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(req.lat, req.lng),
          width: 260,
          height: 56,
          // Marginea stângă a markerului = locația exactă; conținutul se extinde spre dreapta.
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => _requestsManager?.onAnnotationTappedOsm(req),
            child: Padding(
              // Offset ≈ raza avatarului (finalSize ≈ 50–65px) → bula nu se suprapune cu markerul.
              padding: const EdgeInsets.only(left: 68),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getOsmRequestColor(req.type),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getOsmRequestEmoji(req.type), style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        req.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 5. Ride Broadcasts (Cereri de cursă în cartier)
    for (final b in _rideBroadcastData.values) {
      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(b.passengerLat, b.passengerLng),
          width: 200,
          height: 80,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _onRideBroadcastClicked(b),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade700, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(b.passengerAvatar, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${b.passengerName}: ${b.destination ?? '...'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 6. Moments (Smart Offset)
    final List<MapMoment> moments = _activeMoments;
    final Map<String, ({double lat, double lng})> momentLayout = _buildStaircaseLayout(
      moments.map((m) => (id: m.id, lat: m.lat, lng: m.lng)).toList(),
      stepMeters: 22.0,
    );

    for (final moment in moments) {
      final p = momentLayout[moment.id] ?? (lat: moment.lat, lng: moment.lng);
      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(p.lat, p.lng),
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _showMapMomentActions(moment),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purple, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Center(
                child: Text(
                  moment.emoji ?? '✨',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 7. Selected POI
    if (_selectedPoi != null) {
      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(_selectedPoi!.location.latitude, _selectedPoi!.location.longitude),
          width: 60,
          height: 60,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.location_pin,
            color: Colors.blue,
            size: 45,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
      );
    }

    // 8. Preview Pin (Red long-press pin)
    if (_previewPinPoint != null) {
      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(_previewPinPoint!.coordinates.lat.toDouble(), _previewPinPoint!.coordinates.lng.toDouble()),
          width: 80,
          height: 80,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.location_pin,
            color: Color(0xFFEF4444),
            size: 55,
            shadows: [Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
          ),
        ),
      );
    }

    // 9. Home Pin (Saved address)
    final homeCoords = _savedHomePinCoordsIfVisible();
    GeoPoint? reperGp = _manualOrientationPin;

    // Mică separare pe hartă dacă ambele puncte coincid (evită suprapunere perfectă)
    if (homeCoords != null &&
        reperGp != null &&
        homeCoords.latitude == reperGp.latitude &&
        homeCoords.longitude == reperGp.longitude) {
      reperGp = GeoPoint(
        reperGp.latitude + 0.00006,
        reperGp.longitude + 0.00006,
      );
    }

    if (homeCoords != null) {
      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(homeCoords.latitude, homeCoords.longitude),
          width: 80,
          height: 80,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: _showSavedHomeFavoritePinActions,
            child: FloatingMarkerWrapper(
              isFloating: true,
              size: 65,
              child: Image.asset(
                'assets/images/home_pin_v2.png',
                width: 65,
                height: 65,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
    }

    // 10. Orientation Reper (Manual pin)
    if (reperGp != null) {
      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(reperGp.latitude, reperGp.longitude),
          width: 60,
          height: 60,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: _showOrientationReperPinActions,
            child: const FloatingMarkerWrapper(
              isFloating: true,
              size: 42,
              child: Icon(
                Icons.explore_rounded,
                color: Color(0xFF16A34A), // Green
                size: 42,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
            ),
          ),
        ),
      );
    }

    // 11. Mystery Boxes (Business)
    final bizOffers = _mysteryBoxManager?.activeOffers.values ?? [];
    final bizIcon = _mysteryBoxManager?.boxIconData;
    for (final offer in bizOffers) {
      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(offer.businessLatitude, offer.businessLongitude),
          width: 120,
          height: 120,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _mysteryBoxManager?.onOfferTap(offer),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bizIcon != null)
                  Image.memory(bizIcon, width: 60, height: 60, fit: BoxFit.contain)
                else
                  const Icon(Icons.card_giftcard, size: 40, color: Colors.purple),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                  ),
                  child: Text(
                    offer.mysteryBoxRemaining != null ? '${offer.mysteryBoxRemaining} / ${offer.mysteryBoxTotal}' : 'Box!',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 12. Community Mystery Boxes
    final commPins = _communityMysteryManager?.pins.values ?? [];
    final commIcon = _communityMysteryManager?.icon;
    for (final pin in commPins) {
      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(pin.latitude, pin.longitude),
          width: 120,
          height: 120,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _communityMysteryManager?.onPinTap(pin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (commIcon != null)
                  Image.memory(commIcon, width: 55, height: 55, fit: BoxFit.contain)
                else
                  const Icon(Icons.gif_box, size: 40, color: Color(0xFF0D9488)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                  ),
                  child: Text(
                    pin.message.trim().isEmpty ? 'Cutie!' : (pin.message.length > 15 ? '${pin.message.substring(0, 13)}…' : pin.message),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 13. Radar Alerts
    final radarAlerts = _radarAlertsManager?.alerts ?? [];
    for (final alert in radarAlerts) {
      osmMarkers.add(
        fm.Marker(
          point: ll.LatLng(alert.latitude, alert.longitude),
          width: 150,
          height: 100,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${alert.senderName}: ${alert.message}'),
                  duration: const Duration(seconds: 4),
                  backgroundColor: const Color(0xFF7C3AED),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                  child: const Icon(Icons.radar, size: 22, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Text(
                    alert.message.length > 25 
                      ? '${alert.message.substring(0, 22)}…' 
                      : alert.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10, 
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return osmMarkers;
  }

  Color _getOsmRequestColor(String type) {
    switch (type) {
      case 'ride': return Colors.purple;
      case 'help': return Colors.green;
      case 'tool': return Colors.orange;
      case 'alert': return Colors.red;
      default: return Colors.blue;
    }
  }

  String _getOsmRequestEmoji(String type) {
    switch (type) {
      case 'ride': return '🚗';
      case 'help': return '🛠️';
      case 'tool': return '🔧';
      case 'alert': return '🚨';
      default: return '💬';
    }
  }

  Future<void> _onOsmMapCreated(fm.MapController ctrl) async {
    _osmMapController = ctrl;

    // 🔄 MIDDLEWARE SYNC: Înregistrăm controllerul în provider.
    // Providerul va aplica automat ultima stare salvată (lat, lng, zoom).
    context.read<MapCameraProvider>().setOsmController(ctrl);

    // Nullăm referința Mapbox: cât OSM e activ, view-ul nativ Mapbox e distrus.
    _mapboxMap = null;
    _homePinUpdateChain = null;

    // Reset Mapbox annotation manager so stream updates use the OSM setState path.
    _neighborsAnnotationManager = null;
    _neighborsAnnotationTapListenerRegistered = false;
    _neighborAnnotations.clear();
    _neighborAnnotationIdToUid.clear();
    // Immediate render from cached _lastFilteredNeighborsForMap (no stream wait).
    if (mounted) setState(() {});

    // Asigurăm pornirea managerilor de Mystery Box pentru date (indiferent de Mapbox)
    unawaited(_ensureMysteryBoxManagersInitialized(mapboxMap: null));

    Logger.info("OSM Map created. Centering from Middleware or location...");
    
    if (mounted) {
      final camSync = context.read<MapCameraProvider>();
      final lastLat = camSync.lastLat;
      final lastLng = camSync.lastLng;
      
      if (lastLat != null && lastLng != null) {
        // Dacă avem o stare în middleware (ex. tocmai am trecut de la Mapbox),
        // o folosim pentru a menține continuitatea vizuală.
        _animatedMoveOsm(
          ll.LatLng(lastLat, lastLng), 
          camSync.currentZoom,
          durationMs: 800, // Tranziție rapidă și fluidă
        );
      } else {
        // Fallback la poziția curentă dacă e prima pornire a hărții
        final pos = _currentPositionObject;
        if (pos != null) {
          _animatedMoveOsm(
            ll.LatLng(pos.latitude, pos.longitude), 
            _overviewZoomForLatitude(pos.latitude),
            durationMs: 1500,
          );
        } else {
          unawaited(_centerOnLocationOnMapReady());
        }
      }
      
      // Update markeri user
      final markerPos = _positionForUserMapMarker();
      if (markerPos != null) {
        unawaited(_updateWeatherAndStyle(markerPos.latitude, markerPos.longitude));
        unawaited(_updateUserMarker(centerCamera: false));
      }

      // 🛰️ NOU: Asigurăm pornirea stream-ului de locație pasiv (warmup) și pe OSM.
      unawaited(Future.microtask(_ensurePassiveLocationWarmupIfNeeded));
    }
  }

  /// ✅ NOU: Simulează efectul "Fly To" pentru OSM prin animație de Ticker
  void _animatedMoveOsm(ll.LatLng destLocation, double destZoom, {int durationMs = 1200}) {
    if (_osmMapController == null || !mounted) return;
    
    _osmMoveController?.stop();
    _osmMoveController?.dispose();

    final latTween = Tween<double>(begin: _osmMapController!.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _osmMapController!.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _osmMapController!.camera.zoom, end: destZoom);

    _osmMoveController = AnimationController(duration: Duration(milliseconds: durationMs), vsync: this);
    final animation = CurvedAnimation(parent: _osmMoveController!, curve: Curves.fastOutSlowIn);

    _osmMoveController!.addListener(() {
      if (mounted && _osmMapController != null) {
        _osmMapController!.move(
          ll.LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        // Nu dispunem aici dacă vrem să refolosim variabila, 
        // dar controllerul oricum se termină.
      }
    });

    _osmMoveController!.forward();
  }
}
