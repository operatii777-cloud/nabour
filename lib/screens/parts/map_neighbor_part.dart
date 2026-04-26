// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapNeighborMethods on _MapScreenState {
  void _listenForRideBroadcasts() {
    _rideBroadcastsSubscription?.cancel();
    if (_currentRole != UserRole.driver) return;

    // Ascultăm cererile active (status 'open') din cartier
    _rideBroadcastsSubscription = _firestoreService.instance
        .collection('ride_broadcasts')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;

      final List<RideBroadcastRequest> broadcasts = [];
      final now = DateTime.now();
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final broadcast = RideBroadcastRequest.fromMap(doc.id, data);
          if (!broadcast.expiresAt.isAfter(now)) continue;

          // Filtru contacte: șoferul vede doar cererile contactelor sale
          if (_contactUids != null && _contactUids!.contains(broadcast.passengerId)) {
             broadcasts.add(broadcast);
          }
        } catch (e) {
          Logger.error('Error parsing broadcast: $e');
        }
      }

      await _updateRideBroadcastAnnotations(broadcasts);
    });
  }

  Future<void> _updateRideBroadcastAnnotations(List<RideBroadcastRequest> broadcasts) async {
    if (_mapboxMap == null) return;

    if (_rideBroadcastsAnnotationManager == null) {
      _rideBroadcastsAnnotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();
      _rideBroadcastsAnnotationManager!.tapEvents(onTap: (annotation) {
        final broadcast = _rideBroadcastData[annotation.id];
        if (broadcast != null) {
          _onRideBroadcastClicked(broadcast);
        }
      });
    }

    final currentIds = broadcasts.map((b) => b.id).toSet();
    
    // Eliminăm cele care nu mai sunt active
    final toRemove = <String>[];
    _rideBroadcastAnnotations.forEach((id, annotation) {
      if (!currentIds.contains(id)) {
        toRemove.add(id);
      }
    });

    for (var id in toRemove) {
      final annotation = _rideBroadcastAnnotations.remove(id);
      if (annotation != null) {
        try {
          await _rideBroadcastsAnnotationManager?.delete(annotation);
          _rideBroadcastData.remove(annotation.id);
        } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      }
    }

    // Adăugăm / Actualizăm
    for (var b in broadcasts) {
      final geom = MapboxUtils.createPoint(b.passengerLat, b.passengerLng);
      if (_rideBroadcastAnnotations.containsKey(b.id)) {
        final existing = _rideBroadcastAnnotations[b.id]!;
        existing.geometry = geom;
        try {
          await _rideBroadcastsAnnotationManager?.update(existing);
        } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      } else {
        final icon = await _MapSocialMethods._generateDemandMarker(b.passengerAvatar);
        final rideImageName = 'nabour_ride_${b.id}';
        final rideImgOk = _mapboxMap != null && await _registerStyleImageFromPng(rideImageName, icon);
        final options = PointAnnotationOptions(
          geometry: geom,
          iconImage: rideImgOk ? rideImageName : null,
          // image: icon, // DO NOT USE
          iconSize: 2.2,
          iconAnchor: IconAnchor.CENTER,
        );
        try {
          final annotation = await _rideBroadcastsAnnotationManager?.create(options);
          if (annotation != null) {
            _rideBroadcastAnnotations[b.id] = annotation;
            _rideBroadcastData[annotation.id] = b;
          }
        } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      }
    }
  }

  void _onRideBroadcastClicked(RideBroadcastRequest broadcast) {
    HapticFeedback.heavyImpact();
    unawaited(_triggerRippleAtLatLng(broadcast.passengerLat, broadcast.passengerLng));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${broadcast.passengerAvatar} ${broadcast.passengerName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(ctx)!.mapRideBroadcastWantsToGo(
                broadcast.destination ?? AppLocalizations.of(ctx)!.mapDestinationUnset,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                minimumSize: const ui.Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RideBroadcastFeedScreen()));
              },
              child: Text(
                AppLocalizations.of(ctx)!.mapSeeRequestAndOfferRide,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _listenForNearbyDrivers() {
    if (!mounted || _isInitializingDrivers) return;
    _isInitializingDrivers = true;

    _nearbyDriversSubscription?.cancel();
    _nearbyDriversSubscription = _firestoreService.getNearbyAvailableDrivers().listen((snapshot) {
      if (mounted) {
        _updateNearbyDrivers(snapshot.docs);
        unawaited(PushCampaignService().notifyHighSupply(snapshot.docs.length));
      }
    }, onError: (e) {
      Logger.error('Nearby drivers stream error: $e', tag: 'MAP', error: e);
      _isInitializingDrivers = false;
    });
    _isInitializingDrivers = false;
  }

  /// Re-abonează la fluxul șoferilor disponibili (snapshot nou); folosit la refresh manual pe hartă.
  void _restartNearbyDriversStream() {
    if (!mounted) return;
    _nearbyDriversSubscription?.cancel();
    _nearbyDriversSubscription = null;
    _isInitializingDrivers = false;
    _listenForNearbyDrivers();
  }

  /// ✅ NOU: Radar SOS — Ascultă alertele active și randează aurele de siguranță pe hartă.
  void _listenForEmergencyAlerts() {
    _emergencyAlertsSubscription?.cancel();
    
    final fifteenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 15));
    
    _emergencyAlertsSubscription = FirebaseFirestore.instance
        .collection('emergency_alerts')
        .where('status', isEqualTo: 'active')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(fifteenMinutesAgo))
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      final currentUids = snapshot.docs.map((d) => d.id).toSet();
      
      // 1. Curățăm markerii și aurele pentru alertele dispărute / rezolvate
      final toRemove = _emergencyAnnotations.keys.where((id) => !currentUids.contains(id)).toList();
      for (var id in toRemove) {
        _removeEmergencyMarker(id);
      }

      // 2. Procesăm fiecare alertă curentă
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        
        // Nu ne auto-alertăm pe noi înșine cu radar (doar alții contează)
        if (data['userId'] == FirebaseAuth.instance.currentUser?.uid) continue;

        if (!_emergencyAnnotations.containsKey(id)) {
          _onNewEmergencyAlertReceived(id, data);
        } else {
          _updateEmergencyAuraSlot(id, data: data);
        }
      }
      
      if (mounted) setState(() {});
    }, onError: (e) => Logger.error('Emergency Radar error: $e', tag: 'MAP_SOS'));
  }

  Future<void> _onNewEmergencyAlertReceived(String id, Map<String, dynamic> data) async {
    final l10n = AppLocalizations.of(context)!;
    final lat = data['latitude'] as double?;
    final lng = data['longitude'] as double?;
    final userName = data['userName'] as String? ?? l10n.mapAneighbor;
    
    if (lat == null || lng == null) return;

    // A. Adăugăm markerul SOS pe hartă
    await _addEmergencyMarker(id, lat, lng, userName);

    // B. Notificare locală
    LocalNotificationsService().showSimple(
      title: l10n.mapSosNearbyTitle(userName),
      body: l10n.mapSosNearbyBody,
      payload: 'sos_$id',
    );

    // C. Fly-To cinematic (opțional, doar dacă e nou-nouță și nu suntem în navigație activă)
    if (!_routeCtrl.inAppNavActive) {
      await _mapboxMap?.flyTo(
        CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 15.5, pitch: 0.0),
        MapAnimationOptions(duration: 3000),
      );
    }

    // D. Mesaj vocal
    if (_routeCtrl.navTts != null) {
      unawaited(_routeCtrl.navTts!.speak(l10n.mapSosTtsAlert(userName)));
    }
  }

  Future<void> _addEmergencyMarker(String id, double lat, double lng, String name) async {
    if (_mapboxMap == null) return;
    
    _emergencyAnnotationManager ??= await _mapboxMap!.annotations.createPointAnnotationManager(id: 'sos-radar');

    // Generăm un icon SOS roșu neon
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 100, 100));
    final paint = ui.Paint()..color = Colors.red.shade600..isAntiAlias = true;
    
    // Glow pulsating
    paint..color = Colors.red.withValues(alpha: 0.4)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 15);
    canvas.drawCircle(const ui.Offset(50, 50), 40, paint);
    
    paint..color = Colors.red.shade900..style = ui.PaintingStyle.fill..maskFilter = null;
    canvas.drawCircle(const ui.Offset(50, 50), 30, paint);
    
    final tp = TextPainter(
      text: const TextSpan(text: '🆘', style: TextStyle(fontSize: 40)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, ui.Offset(50 - tp.width / 2, 50 - tp.height / 2));

    final img = await recorder.endRecording().toImage(100, 100);
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

    final sosImageName = 'nabour_sos_$id';
    final sosImgOk = _mapboxMap != null && await _registerStyleImageFromPng(sosImageName, bytes);
    final ann = await _emergencyAnnotationManager!.create(PointAnnotationOptions(
      geometry: MapboxUtils.createPoint(lat, lng),
      iconImage: sosImgOk ? sosImageName : null,
      // image: bytes, // DO NOT USE
      iconSize: 0.8,
      textField: 'S.O.S. $name',
      textColor: Colors.redAccent.toARGB32(),
      textHaloColor: Colors.black.toARGB32(),
      textHaloWidth: 2.0,
      textSize: 10,
    ));
    
    _emergencyAnnotations[id] = ann;
    _updateEmergencyAuraSlot(id, data: {'latitude': lat, 'longitude': lng, 'userName': name});
  }

  void _updateEmergencyAuraSlot(String id, {Map<String, dynamic>? data}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_mapboxMap == null) return;
    
    final ann = _emergencyAnnotations[id];
    if (ann == null) return;
    
    final screenPos = await _mapboxMap!.pixelForCoordinate(ann.geometry);
    
    if (mounted) {
      setState(() {
        _emergencyAuraSlots.removeWhere((s) => s.eventId == id);
        _emergencyAuraSlots.add(NabourAuraMapSlot(
          eventId: id,
          screenCenter: Offset(screenPos.x, screenPos.y),
          radiusPx: 140, // Radar larg de proximitate
          userDensity: 80, // Intensitate maximă pentru SOS
          title: l10n.mapCriticalZone,
          endsAt: DateTime.now().add(const Duration(minutes: 5)),
        ));
      });
    }
  }

  void _removeEmergencyMarker(String id) async {
    final ann = _emergencyAnnotations.remove(id);
    if (ann != null) {
      try {
        await _emergencyAnnotationManager?.delete(ann);
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }
    if (mounted) {
      setState(() {
        _emergencyAuraSlots.removeWhere((s) => s.eventId == id);
      });
    }
  }

  /// ✅ Sincronizează poziția pe ecran a aurelor de siguranță SOS cu mișcarea camerei.
  Future<void> _projectEmergencyAuraSlots() async {
    final l10n = AppLocalizations.of(context)!;
    if (!mounted || _mapboxMap == null) return;
    if (_emergencyAnnotations.isEmpty) {
      if (_emergencyAuraSlots.isNotEmpty && mounted) {
        setState(() => _emergencyAuraSlots = []);
      }
      return;
    }
    try {
      final slots = <NabourAuraMapSlot>[];
      for (final entry in _emergencyAnnotations.entries) {
        final id = entry.key;
        final ann = entry.value;
        final sc = await _mapboxMap!.pixelForCoordinate(ann.geometry);
        
        slots.add(NabourAuraMapSlot(
          eventId: id,
          screenCenter: Offset(sc.x.toDouble(), sc.y.toDouble()),
          radiusPx: 140, // Radius constant pentru radar urgență
          userDensity: 80, // Intensitate plasmă (SOS e dens)
          title: l10n.mapSosActiveTitle,
          endsAt: DateTime.now().add(const Duration(minutes: 5)),
        ));
      }
      if (mounted) setState(() => _emergencyAuraSlots = slots);
    } catch (e) {
      Logger.debug('SOS Aura project: $e', tag: 'MAP_SOS');
    }
  }


  // ── Curățare Totală Harta Socială ──────────────────────────────────────

  Future<void> _clearSocialMapMarkers() async {
    // 1. Ștergem vecinii (emoticoane)
    for (final ann in _neighborAnnotations.values) {
      try {
        await _neighborsAnnotationManager?.delete(ann);
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }
    _neighborAnnotations.clear();
    _neighborAnnotationIdToUid.clear();
    _neighborData.clear();
    _neighborUidsBeingCreated.clear();

    // 2. Ștergem șoferii disponibili
    for (final ann in _nearbyDriverAnnotations.values) {
      try {
        await _driversAnnotationManager?.delete(ann);
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }
    _nearbyDriverAnnotations.clear();
    _driverAnnotationIdToUid.clear();
    _nearbyDriverUidsBeingCreated.clear();
    _nearbyDriverMarkerIconBytesCache.clear();
    _nearbyDriverMarkerIconLoads.clear();

    Logger.info('Social Map cleared (Role Switch / Reset)');
  }

  void _onRadarConfirmed() async {
    final l10n = AppLocalizations.of(context)!;
    if (_radarCenter == null) return;
    
    final mapSettings = Provider.of<MapSettingsProvider>(context, listen: false);
    double metersPerPix = 1.0;
    
    if (mapSettings.isOsm) {
      if (_osmMapController != null) {
        final lat = _radarCenter!.coordinates.lat.toDouble();
        final zoom = _osmMapController!.camera.zoom;
        metersPerPix = 156543.03392 * math.cos(lat * math.pi / 180) / math.pow(2, zoom);
      }
    } else {
      if (_mapboxMap != null) {
        final cameraState = await _mapboxMap!.getCameraState();
        metersPerPix = await _mapboxMap!.projection.getMetersPerPixelAtLatitude(
            _radarCenter!.coordinates.lat.toDouble(), cameraState.zoom);
      }
    }
    
    final radiusMeters = _radarRadius * metersPerPix;

    final selected = <NeighborLocation>[];
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final contacts = _contactUids;
    for (final neighbor in _lastRawNeighborsForMap) {
      if (myUid != null && neighbor.uid == myUid) continue;
      if (contacts != null && !contacts.contains(neighbor.uid)) continue;
      final neighborPt = Point(coordinates: Position(neighbor.lng, neighbor.lat));
      final dist = MapboxUtils.calculateDistance(_radarCenter!, neighborPt);
      
      if (dist <= radiusMeters) {
        selected.add(neighbor);
      }
    }

    if (selected.isNotEmpty) {
      HapticService.instance.success();
      _onRadarSelectionCompleted(selected); // Reutilizăm logica de grup-chat/broadcast
    } else {
      _showSafeSnackBar(
        l10n.mapNoContactsInRadarCircle,
        Colors.blueGrey,
      );
    }
    setState(() { _isRadarMode = false; });
  }

  void _onRadarSelectionCompleted(List<NeighborLocation> neighbors) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RadarGroupBroadcastSheet(neighbors: neighbors),
    ).whenComplete(() {
      if (mounted) setState(() => _isRadarMode = false);
    });
  }

  /// Pornește subscribe la vecini: preferă RTDB (H3 / telemetrie efemeră), fallback Firestore.
  void _registerNeighborsAnnotationTapHandler() {
    if (_neighborsAnnotationManager == null ||
        _neighborsAnnotationTapListenerRegistered) {
      return;
    }
    try {
      _neighborsAnnotationManager!.tapEvents(onTap: (annotation) {
        final uid = _neighborAnnotationIdToUid[annotation.id];
        if (uid != null) _onNeighborClicked(uid);
      });
      _neighborsAnnotationTapListenerRegistered = true;
    } catch (e) {
      Logger.warning('Neighbor annotation tap handler: $e', tag: 'MAP');
    }
  }

  void _registerDriversAnnotationTapHandler() {
    if (_driversAnnotationManager == null ||
        _driversAnnotationTapListenerRegistered) {
      return;
    }
    try {
      _driversAnnotationManager!.tapEvents(onTap: (annotation) {
        final uid = _driverAnnotationIdToUid[annotation.id];
        if (uid != null) _onNeighborClicked(uid);
      });
      _driversAnnotationTapListenerRegistered = true;
    } catch (e) {
      Logger.warning('Driver annotation tap handler: $e', tag: 'MAP');
    }
  }

  void _cancelNeighborLocationSubscriptions() {
    _neighborRtdbSubscription?.cancel();
    _neighborRtdbSubscription = null;
    _neighborFirestoreSubscription?.cancel();
    _neighborFirestoreSubscription = null;
    _neighborStaleSweepTimer?.cancel();
    _neighborStaleSweepTimer = null;
    _neighborFsSnapshot = [];
    _neighborRtdbSnapshot = [];
    _autoZoomedGroupSignatures.clear();
  }

  bool _pruneStaleNeighborSnapshots() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    final fsBefore = _neighborFsSnapshot.length;
    final rtdbBefore = _neighborRtdbSnapshot.length;
    _neighborFsSnapshot =
        _neighborFsSnapshot.where((n) => n.lastUpdate.isAfter(cutoff)).toList();
    _neighborRtdbSnapshot = _neighborRtdbSnapshot
        .where((n) => n.lastUpdate.isAfter(cutoff))
        .toList();
    return fsBefore != _neighborFsSnapshot.length ||
        rtdbBefore != _neighborRtdbSnapshot.length;
  }

  void _startNeighborStaleSweep() {
    _neighborStaleSweepTimer?.cancel();
    _neighborStaleSweepTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      if (_pruneStaleNeighborSnapshots()) {
        _mergeNeighborStreamsAndUpdateAnnotations();
      }
    });
  }

  void _mergeNeighborStreamsAndUpdateAnnotations() {
    if (!mounted) return;
    _pruneStaleNeighborSnapshots();
    final merged = <String, NeighborLocation>{};
    for (final n in _neighborFsSnapshot) {
      merged[n.uid] = n;
    }
    for (final n in _neighborRtdbSnapshot) {
      merged[n.uid] = n;
    }
    unawaited(_updateNeighborAnnotations(merged.values.toList()));
  }

  void _startNeighborFirestoreFriendsStream(geolocator.Position pos) {
    _neighborFirestoreSubscription?.cancel();
    _neighborFirestoreSubscription =
        NeighborLocationService().nearbyNeighbors(
      centerLat: pos.latitude,
      centerLng: pos.longitude,
    ).listen(
      (list) {
        _neighborFsSnapshot = list;
        _mergeNeighborStreamsAndUpdateAnnotations();
      },
      onError: (e) {
        Logger.error('Neighbors Firestore stream error: $e',
            tag: 'MAP', error: e);
      },
    );
  }

  void _listenForNeighbors() {
    if (!mounted || _isInitializingNeighbors) return;
    _isInitializingNeighbors = true;
    
    _cancelNeighborLocationSubscriptions();

    final pos = _positionForUserMapMarker();
    if (pos == null) {
      _isInitializingNeighbors = false;
      return;
    }

    _startNeighborStaleSweep();
    unawaited(_subscribeNeighborsPreferredRtdb(pos).then((_) => _isInitializingNeighbors = false));
  }

  Future<void> _subscribeNeighborsPreferredRtdb(geolocator.Position pos) async {
    // Creăm managerul DOAR dacă nu există și nu îl creează altcineva.
    // Dacă _isCreatingNeighborsManager e true, continuăm oricum cu setup-ul stream-urilor;
    // managerul va fi gata la prima emisie a stream-ului.
    if (_neighborsAnnotationManager == null && !_isCreatingNeighborsManager) {
      _isCreatingNeighborsManager = true;
      try {
        final map = _mapboxMap;
        if (map == null) {
          Logger.warning(
            'Mapbox map not ready; skipping neighbors manager creation',
            tag: 'MAP',
          );
          _listenForNeighborsFirestoreOnly(pos);
          return;
        }
        _neighborsAnnotationManager ??=
            await map.annotations.createPointAnnotationManager();
        _registerNeighborsAnnotationTapHandler();
      } catch (e) {
        Logger.error('Failed to create neighbors manager: $e');
      } finally {
        _isCreatingNeighborsManager = false;
      }
    }
    try {
      final room = await NeighborTelemetryRtdbService.instance
          .ensureNbRoomClaim(pos.latitude, pos.longitude, force: true);
      if (!mounted) return;
      if (room != null && room.isNotEmpty) {
        // ✅ WALKIE-TALKIE BACKGROUND AUTO-PLAY
        WalkieTalkieService().listenToRoom(room);

        _neighborRtdbSubscription = NeighborTelemetryRtdbService.instance
            .listenLocationsInRoom(room)
            .map((list) {
          const stale = Duration(minutes: 5);
          final cutoff = DateTime.now().subtract(stale);
          return list.where((n) => n.lastUpdate.isAfter(cutoff)).toList();
        }).listen(
          (neighbors) {
            _neighborRtdbSnapshot = neighbors;
            _mergeNeighborStreamsAndUpdateAnnotations();
          },
          onError: (e) {
            Logger.error('Neighbors RTDB stream error: $e',
                tag: 'MAP', error: e);
            if (mounted) _listenForNeighborsFirestoreOnly(pos);
          },
        );
        _startNeighborFirestoreFriendsStream(pos);
        return;
      }
    } catch (e) {
      Logger.warning('Neighbors RTDB unavailable, using Firestore: $e',
          tag: 'MAP');
    }
    if (mounted) _listenForNeighborsFirestoreOnly(pos);
  }

  void _listenForNeighborsFirestoreOnly(geolocator.Position pos) {
    _cancelNeighborLocationSubscriptions();
    _neighborRtdbSnapshot = [];
    _startNeighborFirestoreFriendsStream(pos);
  }


  /// Cale asset din bundle pentru avatarul cumpărat (același ID la toți utilizatorii).
  String? _garageBundlePathForNeighbor(String? carAvatarId) {
    if (carAvatarId == null || carAvatarId.isEmpty || carAvatarId == 'default_car') {
      return null;
    }
    final av = CarAvatarService().getAvatarById(carAvatarId);
    if (av.isDefault) return null;
    return av.assetPath;
  }

  Future<void> _updateNeighborAnnotations(
      List<NeighborLocation> neighbors) async {
    if (!mounted || _isUpdatingNeighbors) {
      if (_isUpdatingNeighbors) _neighborUpdatePending = true;
      return;
    }
    _isUpdatingNeighbors = true;
    _neighborUpdatePending = false;
    
    _lastRawNeighborsForMap.clear();
    _lastRawNeighborsForMap.addAll(neighbors);

    try {
    final mapSettings = Provider.of<MapSettingsProvider>(context, listen: false);
    if (mapSettings.isOsm) {
      _isUpdatingNeighbors = false;
      final uniqueMap = <String, NeighborLocation>{};
      for (final n in neighbors) { uniqueMap[n.uid] = n; }
      final uniqueNeighbors = uniqueMap.values.toList();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_contactUids != null) {
        _lastFilteredNeighborsForMap = uniqueNeighbors
            .where((n) => _contactUids!.contains(n.uid) && n.uid != currentUserId)
            .toList();
      } else {
        _lastFilteredNeighborsForMap = [];
      }
      _lastNeighborDisplayByUid = Map<String, NeighborDisplayCoords>.from(
        NeighborMarkerDisplayLayout.compute(_lastFilteredNeighborsForMap),
      );
      NeighborMapFeedController.instance.setNeighbors(_lastFilteredNeighborsForMap);
      _maybeAutoZoomToColocatedGroup(_lastFilteredNeighborsForMap);
      if (mounted) setState(() {});
      return;
    }

    if (_neighborsAnnotationManager == null) {
      if (_isCreatingNeighborsManager) {
        _isUpdatingNeighbors = false;
        return;
      }
      _isCreatingNeighborsManager = true;
      try {
        _neighborsAnnotationManager ??= await _mapboxMap?.annotations
            .createPointAnnotationManager(id: 'neighbors-layer');
        _registerNeighborsAnnotationTapHandler();
      } catch (e) {
        Logger.error('Failed to create neighbors manager: $e');
      } finally {
        _isCreatingNeighborsManager = false;
      }
    }
    if (_neighborsAnnotationManager == null) {
      _isUpdatingNeighbors = false;
      
      final Map<String, NeighborLocation> uniqueMap = {};
      for (final n in neighbors) {
        uniqueMap[n.uid] = n;
      }
      final uniqueNeighbors = uniqueMap.values.toList();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      if (_contactUids != null) {
        _lastFilteredNeighborsForMap = uniqueNeighbors.where((n) => 
          _contactUids!.contains(n.uid) && n.uid != currentUserId
        ).toList();
      } else {
        _lastFilteredNeighborsForMap = [];
      }
      
      _lastNeighborDisplayByUid = Map<String, NeighborDisplayCoords>.from(
        NeighborMarkerDisplayLayout.compute(_lastFilteredNeighborsForMap),
      );
      NeighborMapFeedController.instance.setNeighbors(_lastFilteredNeighborsForMap);
      if (mounted) setState(() {});
      return;
    }

    // ✅ FORCE UNIQUE: Evităm duplicarea markerelor pentru același UID la același frame/stream event.
    final Map<String, NeighborLocation> uniqueMap = {};
    for (final n in neighbors) {
      uniqueMap[n.uid] = n;
    }
    final uniqueNeighbors = uniqueMap.values.toList();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final List<NeighborLocation> filteredNeighbors = uniqueNeighbors.where((n) {
      if (currentUserId == null || n.uid == currentUserId) return false;
      if (_contactUids == null) return false;
      return _contactUids!.contains(n.uid);
    }).toList();

    if (_MapScreenState._verboseBuildLogs) {
      Logger.debug(
        'Neighbor update: input=${uniqueNeighbors.length}, filtered=${filteredNeighbors.length}, '
        'contacts=${_contactUids?.length ?? "null"}, manager=${_neighborsAnnotationManager != null}',
        tag: 'MAP_SOCIAL',
      );
    }

    NeighborMapFeedController.instance.setNeighbors(filteredNeighbors);

      final activeUids = filteredNeighbors.map((n) => n.uid).toSet();

      for (final uid in _neighborAnnotations.keys.toList()) {
        if (!activeUids.contains(uid)) {
          try {
            final ann = _neighborAnnotations[uid]!;
            _neighborAnnotationIdToUid.remove(ann.id);
            _neighborData.remove(uid);
            _neighborIconSizeBaseByUid.remove(uid);
            await _neighborsAnnotationManager?.delete(ann);
          } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
          _neighborAnnotations.remove(uid);
        }
      }

    final myPos = _currentPositionObject;
    if (myPos != null) {
      if (DateTime.now().difference(_proximityNotifResetTime).inMinutes >= 15) {
        _proximitNotifiedUids.clear();
        _proximityNotifResetTime = DateTime.now();
        _recentlyBumpedUids.clear();
        _friendsTogetherHintPairs.clear();
        _lastFriendsTogetherHintAny = null;
      }

      for (final neighbor in filteredNeighbors) {
        final distToBump = geolocator.Geolocator.distanceBetween(
          myPos.latitude, myPos.longitude, neighbor.lat, neighbor.lng,
        );
        if (distToBump < 15.0 && !_recentlyBumpedUids.contains(neighbor.uid)) {
          _triggerNeighborBump(neighbor);
        }
      }

      if (mounted && NearbySocialNotificationsPrefs.instance.enabled &&
          _isVisibleToNeighbors) {
        final l10n = AppLocalizations.of(context)!;
        final radiusM = NearbySocialNotificationsPrefs.instance.radiusM.toDouble();
        const maxNeighborsForNotify = 24;
        var count = 0;
        for (final neighbor in filteredNeighbors) {
          if (count >= maxNeighborsForNotify) break;
          if (_proximitNotifiedUids.contains(neighbor.uid)) continue;
          final distM = geolocator.Geolocator.distanceBetween(
            myPos.latitude, myPos.longitude, neighbor.lat, neighbor.lng,
          );
          if (distM <= radiusM) {
            count++;
            _proximitNotifiedUids.add(neighbor.uid);
            unawaited(LocalNotificationsService().showSimple(
              title: l10n.mapNeighborNearbyTitle(neighbor.avatar, neighbor.displayName),
              body: l10n.mapNeighborNearbyBody(distM.round()),
              payload: 'proximity_${neighbor.uid}',
              channelId: 'social_proximity',
            ));
          }
        }
      }

      _maybeFriendsTogetherHint(filteredNeighbors);
    }

    final layoutPeers = filteredNeighbors
        .where((n) => !_nearbyDriverAnnotations.containsKey(n.uid))
        .toList();
    final displayByUid = NeighborMarkerDisplayLayout.compute(layoutPeers);

    // ── Adaugă / actualizează vecini noi (cu density-based sizing) ────
    for (final neighbor in filteredNeighbors) {
      // ✅ FIX: Dacă userul este deja afișat ca Mașină (strat Șoferi), eliminăm
      // eventualul Emoticon rămas în urmă pentru a evita suprapunerea.
      if (_nearbyDriverAnnotations.containsKey(neighbor.uid)) {
        _neighborIconSizeBaseByUid.remove(neighbor.uid);
        final staleAnn = _neighborAnnotations.remove(neighbor.uid);
        if (staleAnn != null) {
          _neighborAnnotationIdToUid.remove(staleAnn.id);
          unawaited(_neighborsAnnotationManager?.delete(staleAnn));
        }
        // Păstrăm telemetria pentru foaia de jos la tap pe mașina din stratul șoferi.
        _neighborData[neighbor.uid] = neighbor;
        continue;
      }

      final Uint8List icon;
      // textField setat mai jos general
      // ── Density-based size reduction ─────────────────────────────────────
      // Calculăm câți vecini sunt în raza de 300m față de acest vecin.
      // Cu cât sunt mai mulți în apropiere, cu atât micșorăm markerul.
      int nearbyCount = 0;
      for (final other in filteredNeighbors) {
        if (other.uid == neighbor.uid) continue;
        final distKm = _calculateDirectDistance(
            neighbor.lat, neighbor.lng, other.lat, other.lng);
        if (distKm < 0.3) nearbyCount++;
      }
      // nearbyCount=0 → full size; ≥4 → minimum size (55% din original)
      final densityFactor = 1.0 - (nearbyCount.clamp(0, 4) / 4.0) * 0.45;

      final double iconSizeBase;
      final double iconSize;

      final bool isDriving = neighbor.isDriver || neighbor.activityStatus == 'driving';
      final bool hasPhoto = neighbor.photoURL != null && neighbor.photoURL!.isNotEmpty;
      final String? garagePath = _garageBundlePathForNeighbor(neighbor.carAvatarId);
      // Prioritate setări utilizator: garaj (non-default) → poză profil → fallback standard (emoji / mașină).

      final bool isCharNeighbor = CarAvatarService.isCharacterAssetPath(garagePath);

      if (isDriving) {
        if (garagePath != null) {
          icon = await _MapInitMethods._generateMarkerIcon(
            isPassenger: false,
            customAssetPath: garagePath,
            batteryLevel: neighbor.batteryLevel,
            isCharging: neighbor.isCharging,
          );
        } else {
          icon = await _MapSocialMethods._generateNeighborCarMarker(
            batteryLevel: neighbor.batteryLevel,
            isCharging: neighbor.isCharging,
          );
        }
        // Character bitmaps are 380px vs 256px for normal avatars.
        // iconSize 1.50 → 380×1.50=570px matches the user's own puck (380×1.5).
        // iconSize 1.98 is calibrated for 256px bitmaps (256×1.98≈507px).
        iconSizeBase = (isCharNeighbor ? 1.50 : 1.98) * densityFactor;
      } else if (garagePath != null) {
        icon = await _MapInitMethods._generateMarkerIcon(
          isPassenger: true,
          customAssetPath: garagePath,
          batteryLevel: neighbor.batteryLevel,
          isCharging: neighbor.isCharging,
        );
        iconSizeBase = (isCharNeighbor ? 1.50 : 1.72) * densityFactor;
      } else if (hasPhoto) {
        icon = await NeighborFriendMarkerIcons.buildPhotoMarker(
          photoURL: neighbor.photoURL!,
          isOnline: neighbor.isOnline,
          batteryLevel: neighbor.batteryLevel,
          isCharging: neighbor.isCharging,
        );
        iconSizeBase = 1.55 * densityFactor;
      } else {
        icon = await NeighborFriendMarkerIcons.buildEmojiMarker(
          emoji: neighbor.avatar,
          status: neighbor.activityStatus,
          isOnline: neighbor.isOnline,
          speedMps: neighbor.speedMps,
          batteryLevel: neighbor.batteryLevel,
          isCharging: neighbor.isCharging,
          placeKind: neighbor.placeKind,
          stationarySinceMs: neighbor.stationarySinceMs,
        );
        iconSizeBase = 1.55 * densityFactor;
      }
      _neighborIconSizeBaseByUid[neighbor.uid] = iconSizeBase;
      iconSize = iconSizeBase * _neighborAvatarZoomFactor();

      String? textField;

      if (isDriving) {
        final plate = neighbor.licensePlate;
        final name = neighbor.displayName.isNotEmpty ? neighbor.displayName : null;
        if (plate != null && plate.isNotEmpty && name != null) {
          textField = '$plate\n$name';
        } else if (plate != null && plate.isNotEmpty) {
          textField = plate;
        } else {
          textField = name;
        }
      } else {
        textField = neighbor.displayName.isNotEmpty ? neighbor.displayName : null;
      }

      // Baterie: pe icon (emoji / foto / garaj / mașină implicită), nu duplicăm în etichetă.

      if (isDriving &&
          neighbor.speedMps != null &&
          neighbor.speedMps! >= 1.39) {
        final kmh = (neighbor.speedMps! * 3.6).round();
        textField =
            textField != null ? '$textField • $kmh km/h' : '$kmh km/h';
      } else if (!isDriving && neighbor.placeKind != null) {
        final pl = switch (neighbor.placeKind!) {
          'home' => 'acasă',
          'work' => 'serviciu',
          'school' => 'școală',
          _ => null,
        };
        if (pl != null) {
          textField = textField != null ? '$textField · $pl' : pl;
        }
      }

      final List<double> tOffset = isDriving ? [0, 2.7] : [0, 2.75];
      // Text alb cu halo negru pentru vizibilitate maximă "permanentă"
      final int tColor = 0xFFFFFFFF;
      final double tSize = isDriving ? 11.0 : 12.0;

        final disp = displayByUid[neighbor.uid];
        final geom = MapboxUtils.createPoint(
          disp?.lat ?? neighbor.lat,
          disp?.lng ?? neighbor.lng,
        );

        if (_neighborAnnotations.containsKey(neighbor.uid)) {
          final existing = _neighborAnnotations[neighbor.uid]!;
          existing.geometry = geom;
          existing.textField = textField;
          existing.iconSize = iconSize;
          existing.textOffset = tOffset;
          existing.textColor = tColor;
          existing.textSize = tSize;
          // Re-înregistrăm imaginea (poate s-a schimbat: baterie, status, viteză) cu același nume stabil.
          final updImageName = 'nabour_nbr_${neighbor.uid}';
          final updImgOk = await _registerStyleImageFromPng(updImageName, icon);
          if (updImgOk) {
            existing.iconImage = updImageName;
            // IMPORTANT: mapbox_maps_flutter 2.x - setting image to null clears the RGBA fallback 
            // if it was previously set, letting iconImage take priority.
            existing.image = null;
          } 
          // We don't use 'existing.image = icon' because icon is PNG, not RGBA.
          // If registration failed, we keep the previous icon or let it be.
          
          try {
            await _neighborsAnnotationManager?.update(existing);
          } catch (_) {}
        } else {
          // Prevenim crearea a 2 markere pt același UID dacă stream-ul e rapid
          if (_neighborUidsBeingCreated.contains(neighbor.uid)) continue;
          _neighborUidsBeingCreated.add(neighbor.uid);

          try {
            final nbrImageName = 'nabour_nbr_${neighbor.uid}';
            final nbrImgOk = await _registerStyleImageFromPng(nbrImageName, icon);
            
            final options = PointAnnotationOptions(
              geometry: geom,
              iconImage: nbrImgOk ? nbrImageName : null,
              // image: icon, // DO NOT USE - icon is PNG, options.image expects RGBA
              iconSize: iconSize,
              iconAnchor: IconAnchor.CENTER,
              textField: textField,
              textSize: tSize,
              textOffset: tOffset,
              textColor: tColor,
              textHaloColor: 0xFF000000,
              textHaloWidth: 2.2,
            );
            final annotation = await _neighborsAnnotationManager?.create(options);
            if (annotation != null && mounted) {
              _neighborAnnotations[neighbor.uid] = annotation;
              _neighborAnnotationIdToUid[annotation.id] = neighbor.uid;
              _neighborData[neighbor.uid] = neighbor;
              if (!_neighborMapActivityToastOnceUids.contains(neighbor.uid)) {
                _neighborMapActivityToastOnceUids.add(neighbor.uid);
                _showMapActivityToast(
                  neighbor.avatar,
                  neighbor.displayName,
                  'e acum pe hartă',
                  onTap: () => _onNeighborClicked(neighbor.uid),
                );
              }
            }
          } catch (_) {
          } finally {
            _neighborUidsBeingCreated.remove(neighbor.uid);
          }
        }
      }

      _lastFilteredNeighborsForMap =
          List<NeighborLocation>.from(filteredNeighbors);
      _lastNeighborDisplayByUid =
          Map<String, NeighborDisplayCoords>.from(displayByUid);
      _recomputeAvatarPinsForEmojiAvoidance();
      // Sincronizează listeners pasivi pentru chat pe hartă (speech bubbles auto)
      _syncPassiveListeners();
      _maybeAutoZoomToColocatedGroup(_lastFilteredNeighborsForMap);
    } finally {
      _isUpdatingNeighbors = false;
      if (_neighborUpdatePending && mounted) {
        _neighborUpdatePending = false;
        unawaited(_updateNeighborAnnotations(List.from(_lastRawNeighborsForMap)));
      }
    }
  }

  /// Auto-zoom la prima detectare a unui grup de vecini co-localizați (≥2 la aceeași locație).
  /// Execuție o singură dată per semnătură de grup (evităm re-zoom la fiecare update de stream).
  void _maybeAutoZoomToColocatedGroup(List<NeighborLocation> neighbors) {
    if (!mounted || neighbors.length < 2) return;
    if (_routeCtrl.inAppNavActive || _followingEnabled) return;

    final groups = NeighborMarkerDisplayLayout.computeGroups(neighbors);
    if (groups.isEmpty) return;

    // Cel mai mare grup co-localizat.
    final group = groups.reduce((a, b) => a.members.length >= b.members.length ? a : b);

    // Semnătură unică pentru combinația de UID-uri din grup.
    final sig = (group.members.map((n) => n.uid).toList()..sort()).join(',');
    if (_autoZoomedGroupSignatures.contains(sig)) return;
    _autoZoomedGroupSignatures.add(sig);

    const targetZoom = 17.5;
    final mapSettings = Provider.of<MapSettingsProvider>(context, listen: false);

    if (mapSettings.isOsm) {
      if ((_osmMapController?.camera.zoom ?? targetZoom) < targetZoom - 0.5) {
        _animatedMoveOsm(ll.LatLng(group.centerLat, group.centerLng), targetZoom);
      }
    } else {
      if (_liveCameraZoom < targetZoom - 0.5) {
        unawaited(_mapboxMap?.flyTo(
          CameraOptions(
            center: MapboxUtils.createPoint(group.centerLat, group.centerLng),
            zoom: targetZoom,
          ),
          MapAnimationOptions(duration: 1200),
        ));
      }
    }
  }

  /// Două contacte vizibile foarte aproape între ei — indiciu social (throttled).
  void _maybeFriendsTogetherHint(List<NeighborLocation> list) {
    if (!mounted || list.length < 2) return;
    if (_lastFriendsTogetherHintAny != null &&
        DateTime.now().difference(_lastFriendsTogetherHintAny!) <
            const Duration(hours: 1)) {
      return;
    }
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final a = list[i];
        final b = list[j];
        final pairKey = a.uid.compareTo(b.uid) < 0
            ? '${a.uid}_${b.uid}'
            : '${b.uid}_${a.uid}';
        if (_friendsTogetherHintPairs.contains(pairKey)) continue;
        final d = geolocator.Geolocator.distanceBetween(
          a.lat, a.lng, b.lat, b.lng,
        );
        if (d < 75) {
          _friendsTogetherHintPairs.add(pairKey);
          _lastFriendsTogetherHintAny = DateTime.now();
          final msg = '${a.displayName} și ${b.displayName} par împreună în zonă 👥';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
          return;
        }
      }
    }
  }

  void _triggerNeighborBump(NeighborLocation neighbor) {
    if (!mounted) return;
    _recentlyBumpedUids.add(neighbor.uid);

    Logger.info('HIT FIZIC DETECTAT: ${neighbor.displayName}', tag: 'MAP');

    NeighborBumpMatchOverlay.show(context, neighbor);
    unawaited(ActivityFeedWriter.hitWith(neighbor.displayName));

    // 1. Efect haptic (Hit / proximitate)
    unawaited(HapticService.instance.success());
    
    // 2. Sunet de feedback (Balloon Pop)
    unawaited(AudioService().playNeighborBumpSound());

    // 3. Mesaj vizual tip Bubble (Waze-style popup)
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.9), // Nabour Purple
           content: Row(
             children: [
               Text(neighbor.avatar, style: const TextStyle(fontSize: 24)),
               const SizedBox(width: 12),
               Expanded(child: Text('Hit, ${neighbor.displayName} e chiar lângă tine! 👋',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
             ],
           ),
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
           margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.45, left: 32, right: 32),
           duration: const Duration(seconds: 5),
         )
       );
    }
  }

  void _onNeighborClicked(String uid) {
    final neighbor = _neighborData[uid];
    if (neighbor == null) return;

    // Trigger visual hit effect
    unawaited(_triggerRippleAtLatLng(neighbor.lat, neighbor.lng));

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    // Calculăm distanța față de utilizator
    double distanceKm = 0;
    if (_currentPositionObject != null) {
      distanceKm = geolocator.Geolocator.distanceBetween(
            _currentPositionObject!.latitude,
            _currentPositionObject!.longitude,
            neighbor.lat,
            neighbor.lng,
          ) /
          1000;
    }

    // Determinăm eticheta de timp (ex: 7 MIN ÎN URMĂ)
    final diffMin = DateTime.now().difference(neighbor.lastUpdate).inMinutes;
    final timeLabel = diffMin <= 1 ? 'CHIAR ACUM' : '$diffMin MIN ÎN URMĂ ';

    // Căutăm numărul de telefon în lista de contacte app (dacă există)
    String? phoneNumber;
    if (_contactUsers.isNotEmpty) {
      try {
        final contactUser = _contactUsers.firstWhere((u) => u.uid == uid);
        phoneNumber = contactUser.phoneNumber;
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NeighborProfileSheet(
        neighbor: neighbor,
        distanceKm: distanceKm,
        timeLabel: timeLabel,
        phoneNumber: phoneNumber,
        onMessage: () {
          Navigator.pop(ctx);
          final sorted = [myUid, uid]..sort();
          final roomId = sorted.join('_');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                rideId: roomId,
                otherUserId: uid,
                otherUserName: neighbor.displayName,
                collectionName: 'private_chats',
              ),
            ),
          );
        },
        onSendReaction: (reaction) async {
          final sorted = [myUid, uid]..sort();
          final roomId = sorted.join('_');
          final myName = FirebaseAuth.instance.currentUser?.displayName ?? AppLocalizations.of(context)!.neighborFallback;
          
          await FirebaseFirestore.instance
              .collection('private_chats')
              .doc(roomId)
              .collection('messages')
              .add({
            'text': reaction,
            'reaction': true,
            'senderId': myUid,
            'senderName': myName,
            'timestamp': FieldValue.serverTimestamp(),
          });
          
          HapticFeedback.mediumImpact();
          if (mounted) _showSafeSnackBar(AppLocalizations.of(context)!.mapReactionSent(reaction), const Color(0xFF7C3AED));
        },
        onCall: phoneNumber != null ? () async {
          final uri = Uri.parse('tel:$phoneNumber');
          if (await url_launcher.canLaunchUrl(uri)) {
            await url_launcher.launchUrl(uri);
          }
        } : null,
        onHonk: () async {
          final myName = FirebaseAuth.instance.currentUser?.displayName ?? AppLocalizations.of(context)!.neighborFallback;
          await VirtualHonkService().sendHonk(uid, myName);
          HapticFeedback.heavyImpact();
          if (mounted) _showSafeSnackBar(AppLocalizations.of(context)!.mapHonkedNeighbor(neighbor.displayName), Colors.orange);
        },
        onSendEta: () async {
          final l10n = AppLocalizations.of(context)!;
          final sorted = [myUid, uid]..sort();
          final roomId = sorted.join('_');
          final myName = FirebaseAuth.instance.currentUser?.displayName ?? 'Vecin';
          
          // Exemplu simplificat de ETA
          final etaMin = (distanceKm * 2.5).toInt() + 2; 
          
          await FirebaseFirestore.instance
              .collection('private_chats')
              .doc(roomId)
              .collection('messages')
              .add({
            'text': l10n.mapEtaMessageToNeighbor(etaMin),
            'isEta': true,
            'senderId': myUid,
            'senderName': myName,
            'timestamp': FieldValue.serverTimestamp(),
          });
           HapticFeedback.lightImpact();
           if (ctx.mounted) Navigator.pop(ctx);
           _showSafeSnackBar(l10n.mapEtaSentTo(neighbor.displayName), Colors.green);
        },
        onNeighborhoodRequest: () {
          Navigator.pop(ctx);
          NeighborhoodRequestsManager.showCreateRequestSheet(
            context,
            neighbor.lat,
            neighbor.lng,
            initialMessage: '${neighbor.displayName}: ',
            locationContext:
                AppLocalizations.of(context)!.mapNeighborhoodBubbleContext(neighbor.displayName),
          );
        },
        onSendMapEmoji: (emoji) async {
          final chosen = normalizeMapEmojiForEngine(emoji);
          try {
            await MapEmojiService().addEmoji(
              lat: neighbor.lat,
              lng: neighbor.lng,
              emoji: chosen,
              senderId: myUid,
            );
            if (ctx.mounted) Navigator.pop(ctx);
            HapticFeedback.lightImpact();
            if (!mounted) return;
            final optimistic = MapEmoji(
              id: myUid,
              lat: neighbor.lat,
              lng: neighbor.lng,
              emoji: chosen,
              timestamp: DateTime.now(),
              senderId: myUid,
            );
            setState(() {
              _lastReceivedEmojis = [
                ..._lastReceivedEmojis.where((x) => x.id != myUid),
                optimistic,
              ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
            });
            unawaited(_updateEmojiMarkers(_lastReceivedEmojis));
            _showSafeSnackBar(
              AppLocalizations.of(context)!.mapEmojiPlacedNear(neighbor.displayName),
              const Color(0xFFE91E63),
            );
          } catch (e) {
            if (mounted) {
              _showSafeSnackBar(
                AppLocalizations.of(context)!.mapCannotPlaceEmoji,
                const Color(0xFFB71C1C),
              );
            }
          }
        },
        onMapChat: () {
          Navigator.pop(ctx);
          _openMapChat(uid);
        },
      ),
    );
  }

  Future<void> _sendFriendRequestFromSearch(String uid) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || uid.isEmpty || uid == myUid) return;
    if (_friendPeerUids.contains(uid)) {
      if (mounted) {
        _showSafeSnackBar(AppLocalizations.of(context)!.friendSuggestionsAlreadyFriends, Colors.orange.shade800);
      }
      return;
    }
    if (await FriendRequestService.instance.hasPendingRequestTo(uid)) {
      if (mounted) {
        _showSafeSnackBar(
          AppLocalizations.of(context)!.friendSuggestionsRequestAlreadySent,
          Colors.orange.shade800,
        );
      }
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('friend_requests').add({
        'fromUid': myUid,
        'toUid': uid,
        'status': 'pending',
        'ts': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSafeSnackBar(
          AppLocalizations.of(context)!.friendSuggestionsRequestSent,
          const Color(0xFF22C55E),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSafeSnackBar(
          (e.toString().contains('permission-denied') ||
                  e.toString().contains('PERMISSION_DENIED'))
              ? AppLocalizations.of(context)!.friendSuggestionsRequestPermissionDenied
              : AppLocalizations.of(context)!.friendSuggestionsRequestFailed,
          const Color(0xFFB71C1C),
        );
      }
    }
  }

  void _onUniversalSearchContact(String uid) {
    final neighbor = _neighborData[uid];
    if (neighbor == null) {
      _showSafeSnackBar(
        AppLocalizations.of(context)!.mapPersonNotVisibleSendFromList,
        Colors.grey.shade800,
      );
      return;
    }
    unawaited(_mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(neighbor.lng, neighbor.lat)),
        zoom: 16.2,
        pitch: 0,
      ),
      MapAnimationOptions(duration: 1400),
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onNeighborClicked(uid);
    });
  }

  void _onUniversalSearchPlace(double lat, double lng, String label) {
    // Fly-to apoi pin pe același strat ca căutarea (nu pinurile private Acasă/reper — acelea au manageri separați).
    unawaited(() async {
      await _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 16.5,
          pitch: 0,
        ),
        MapAnimationOptions(duration: 1800),
      );
      await _requestsManager?.showTransientLocationPin(lat, lng);
    }());
    _showSafeSnackBar(label, const Color(0xFF3949AB));
  }

  // ── BLE Bump ────────────────────────────────────────────────────────────
  void _startBleBump() {
    unawaited(BleBumpService.instance.start());
    BleBumpBridge.instance.onBump = (peerUid) {
      if (!mounted) return;
      if (_recentlyBumpedUids.contains(peerUid)) return;
      var neighbor = _neighborData[peerUid];
      if (neighbor == null) {
        for (final n in _lastRawNeighborsForMap) {
          if (n.uid == peerUid) {
            neighbor = n;
            break;
          }
        }
      }
      if (neighbor == null) {
        final anchor = _currentPositionObject;
        if (anchor == null) return;
        String name = 'Contact apropiat';
        String avatar = '👤';
        for (final c in _contactUsers) {
          if (c.uid == peerUid) {
            name = c.displayName;
            break;
          }
        }
        neighbor = NeighborLocation.stubForProximity(
          uid: peerUid,
          displayName: name,
          avatar: avatar,
          anchorLat: anchor.latitude,
          anchorLng: anchor.longitude,
        );
      }
      _triggerNeighborBump(neighbor);
      unawaited(ActivityFeedWriter.hitWith(neighbor.displayName));
    };
    BleBumpBridge.instance.start();
  }

  // ── Smart Places background clustering ─────────────────────────────────
  void _startSmartPlacesClustering() {
    _smartPlacesClusterTimer?.cancel();
    _smartPlacesClusterTimer =
        Timer.periodic(const Duration(minutes: 5), (_) async {
      await SmartPlacesDb.instance.runClustering();
    });
  }

  Future<void> _loadSocialBumpPrefs() async {
    await GhostModeService.instance.ensureLoaded();
    await NearbySocialNotificationsPrefs.instance.load();
  }

  void _ensureRidePanelVisibleForExternalAction(VoidCallback applyToPanel) {
    if (!mounted) return;
    final needOpen = !_rideAddressSheetVisible && !_routeCtrl.inAppNavActive;
    if (needOpen) {
      setState(() => _rideAddressSheetVisible = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        applyToPanel();
        if (_rideSheetController.isAttached) {
          _rideSheetController.animateTo(
            0.48,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      });
      return;
    }
    applyToPanel();
  }

  void _closeRideAddressSheet() {
    if (_routeCtrl.inAppNavActive) {
      _showSafeSnackBar(AppLocalizations.of(context)!.mapStopNavigationFirst, Colors.orange);
      return;
    }
    setState(() => _rideAddressSheetVisible = false);
  }

  /// Comută înălțimea sheet-ului când cardul e deja vizibil.
  void _toggleRideSheetExpandCollapse() {
    final c = _rideSheetController;
    if (!c.isAttached) return;
    const collapsed = 0.16;
    const expanded = 0.48;
    final next = c.size <= collapsed + 0.03 ? expanded : collapsed;
    c.animateTo(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// Butonul din bara de jos: deschide cardul sau, dacă e deja deschis, micșorează/mărește.
  void _onItineraryButtonPressed() {
    if (!_rideAddressSheetVisible && !_routeCtrl.inAppNavActive) {
      setState(() => _rideAddressSheetVisible = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_rideSheetController.isAttached) return;
        _rideSheetController.animateTo(
          0.48,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      });
      return;
    }
    _toggleRideSheetExpandCollapse();
  }

  // ── Post Moment ────────────────────────────────────────────────────────
  void _showPostMomentSheet() {
    final pos = _currentPositionObject;
    if (pos == null) {
      _showSafeSnackBar(
        AppLocalizations.of(context)!.mapWaitingGpsTryAgain,
        Colors.orange,
      );
      return;
    }
    showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PostMomentSheet(lat: pos.latitude, lng: pos.longitude),
    ).then((posted) {
      if (!mounted || posted != true) return;
      // Fără asta, momentele se ascultă doar la „vizibil vecinilor” — după post vrem lista actualizată mereu.
      _subscribeToMoments();
    });
  }

  void _shareCurrentLocation() {
    final pos = _currentPositionObject;
    if (pos == null) {
      _showSafeSnackBar(AppLocalizations.of(context)!.mapGpsLocationUnavailableYet, Colors.orange);
      return;
    }
    final lat = pos.latitude;
    final lng = pos.longitude;
    final googleMapsUrl = 'https://www.google.com/maps?q=$lat,$lng';
    final text = 'Sunt aici: $googleMapsUrl\n'
        'Coordonate: $lat, $lng';
    SharePlus.instance.share(ShareParams(text: text));
  }

  // ── Listen to moments nearby ───────────────────────────────────────────
  void _subscribeToMoments() {
    _momentsSubscription?.cancel();
    _momentsExpiryTimer?.cancel();
    _momentsExpiryTimer = null;
    final pos = _currentPositionObject;
    if (pos == null) return;
    _momentsSubscription = MapMomentService.instance
        .nearbyMoments(centerLat: pos.latitude, centerLng: pos.longitude)
        .listen((moments) {
      if (!mounted) return;
      setState(() => _activeMoments = moments);
      unawaited(_updateMomentMarkers(moments));
    });
    // Firestore nu re-emite când trece timpul; curățăm local la expirarea TTL.
    _momentsExpiryTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      final fresh = _activeMoments.where((m) => !m.isExpired).toList();
      if (fresh.length == _activeMoments.length) return;
      setState(() => _activeMoments = fresh);
      unawaited(_updateMomentMarkers(fresh));
    });
  }

  // ── Friend Suggestions Screen (Bump style) ──────────────────────────
  void _openFriendSuggestions() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => FriendSuggestionsScreen(
          contacts: _contactUsers,
          onlineUids: _neighborData.keys.toSet(),
          avatarCache: _neighborAvatarCache,
        ),
      ),
    ).then((_) {
      if (mounted) unawaited(_syncFriendPeersIntoContactUids());
    });
  }

  // ── Activity Notifications Screen (Bell screen, Bump style) ────────
  void _openActivityNotifications() {
    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) {
          final self = FirebaseAuth.instance.currentUser?.uid;
          final ids = <String>{...?_contactUids};
          if (self != null && self.isNotEmpty) ids.add(self);
          return ActivityNotificationsScreen(
            friendUids: ids.toList(),
            contacts: _contactUsers,
            avatarCache: _neighborAvatarCache,
          );
        },
      ),
    ).then((result) {
      if (result != null && result['action'] == 'flyTo' && mounted) {
        final lat = (result['lat'] as num?)?.toDouble();
        final lng = (result['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _mapboxMap?.flyTo(
            CameraOptions(
              center: MapboxUtils.createPoint(lat, lng),
              zoom: 16.5,
              pitch: 0,
            ),
            MapAnimationOptions(duration: 1500),
          );
        }
      }
    });
  }

  // ── Show activity toast on map (Bump style) ────────────────────────
  void _showMapActivityToast(String avatar, String name, String message, {VoidCallback? onTap}) {
    if (!mounted) return;
    MapActivityToast.show(
      context,
      avatar: avatar,
      name: name,
      message: message,
      onTap: onTap,
    );
  }

  Widget _buildBumpFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black,
    Color bgColor = Colors.white,
    double size = 44,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.54),
      ),
    );
  }
}

