// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapDriverMethods on _MapScreenState {
  Future<void> _loadMagicEventCheckinIds() async {
    try {
      final s = await MagicEventCheckinStore.instance.load();
      if (!mounted) return;
      setState(() {
        _magicEventCheckedInIds
          ..clear()
          ..addAll(s);
      });
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
  }

  void _startMagicEventPolling() {
    unawaited(_loadMagicEventCheckinIds());
    _magicEventPollTimer?.cancel();
    _magicEventPollTimer =
        Timer.periodic(const Duration(seconds: 48), (_) {
      unawaited(_pollMagicEventsOnce());
    });
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (mounted) unawaited(_pollMagicEventsOnce());
    });
  }

  Future<void> _maybePollMagicEventsThrottled() async {
    if (FirebaseAuth.instance.currentUser?.uid == null) return;
    final now = DateTime.now();
    if (_lastMagicEventPoll != null &&
        now.difference(_lastMagicEventPoll!) <
            const Duration(seconds: 40)) {
      return;
    }
    _lastMagicEventPoll = now;
    await _pollMagicEventsOnce();
  }

  Future<void> _pollMagicEventsOnce() async {
    if (!mounted || _mapboxMap == null) return;
    final pos = _currentPositionObject;
    if (pos == null) return;
    if (FirebaseAuth.instance.currentUser?.uid == null) return;

    try {
      final now = DateTime.now();
      final candidates =
          await MagicEventService.instance.fetchActiveCandidatesInArea(
        userLat: pos.latitude,
        userLng: pos.longitude,
        searchRadiusKm: 10,
      );
      final timeOk = candidates
          .where((e) => magicEventIsActiveAt(e, now))
          .toList();
      await _syncMagicEventMarkers(timeOk);

      final inside = magicEventsUserIsInsideNow(
        userLat: pos.latitude,
        userLng: pos.longitude,
        candidates: timeOk,
        now: now,
      );

      if (!mounted) return;
      setState(() {
        _magicEventsUserInside = inside;
        _magicEventsAuraCandidates = timeOk;
      });
      unawaited(_projectMagicEventAuraSlots());

      for (final e in inside) {
        if (_magicEventCheckedInIds.contains(e.id)) continue;
        await MagicEventCheckinStore.instance.add(e.id);
        if (!mounted) return;
        setState(() {
          _magicEventCheckedInIds.add(e.id);
          _magicStarShowerVisible = true;
          _magicEventRippleTick[e.id] =
              (_magicEventRippleTick[e.id] ?? 0) + 1;
        });
        unawaited(_projectMagicEventAuraSlots());
        _showSafeSnackBar(
          'Bun venit la ${e.title}!',
          const Color(0xFF7C3AED),
        );
        break;
      }
    } catch (e, st) {
      Logger.error(
        'Magic event poll: $e',
        error: e,
        stackTrace: st,
        tag: 'MAGIC_EVENT',
      );
    }
  }

  Future<void> _syncMagicEventMarkers(List<MagicEvent> events) async {
    if (!mounted || _mapboxMap == null) return;
    try {
      if (_magicEventAnnotationManager == null) {
        try {
          _magicEventAnnotationManager = await _mapboxMap!.annotations
              .createPointAnnotationManager(
            id: 'magic-events-layer',
            below: 'map-moments-layer',
          );
        } catch (_) {
          _magicEventAnnotationManager = await _mapboxMap!.annotations
              .createPointAnnotationManager(
            id: 'magic-events-layer',
          );
        }
      }
    } catch (e) {
      Logger.warning('Magic event manager: $e', tag: 'MAGIC_EVENT');
      return;
    }

    final mgr = _magicEventAnnotationManager;
    if (mgr == null) return;

    final activeIds = events.map((e) => e.id).toSet();
    for (final id in _magicEventAnnotations.keys.toList()) {
      if (!activeIds.contains(id)) {
        try {
          final ann = _magicEventAnnotations.remove(id);
          if (ann != null) await mgr.delete(ann);
        } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
      }
    }

    final pin = await MagicEventMarkerIcons.pinPng();
    const double iconSize = 1.35;
    const List<double> textOffset = [0, 2.2];
    const int textColor = 0xFF6D28D9;

    for (final e in events) {
      final geom = MapboxUtils.createPoint(e.latitude, e.longitude);
      final label = '${e.participantCount} prezențe';
      if (_magicEventAnnotations.containsKey(e.id)) {
        try {
          final ann = _magicEventAnnotations[e.id]!;
          final magicImageName = 'nabour_magic_${e.id}';
          final magicImgOk = await _registerStyleImageFromPng(magicImageName, pin);
          await mgr.update(
            ann
              ..geometry = geom
              ..iconImage = magicImgOk ? magicImageName : null
              ..image = null
              ..iconSize = iconSize
              ..iconAnchor = IconAnchor.CENTER
              ..textField = label
              ..textSize = 10
              ..textOffset = textOffset
              ..textColor = textColor
              ..textHaloColor = 0xFFFFFFFF
              ..textHaloWidth = 1.5,
          );
        } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
        continue;
      }
      final magicImageName = 'nabour_magic_${e.id}';
      final magicImgOk = await _registerStyleImageFromPng(magicImageName, pin);
      
      final options = PointAnnotationOptions(
        geometry: geom,
        iconImage: magicImgOk ? magicImageName : null,
        // image: pin, // DO NOT USE
        iconSize: iconSize,
        iconAnchor: IconAnchor.CENTER,
        textField: label,
        textSize: 10,
        textOffset: textOffset,
        textColor: textColor,
        textHaloColor: 0xFFFFFFFF,
        textHaloWidth: 1.5,
      );
      final ann = await mgr.create(options);
      _magicEventAnnotations[e.id] = ann;
    }
  }

  void _showMagicEventDetailSheet(MagicEvent event) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String fmt(DateTime d) {
          final loc = d.toLocal();
          final h = loc.hour.toString().padLeft(2, '0');
          final m = loc.minute.toString().padLeft(2, '0');
          return '${loc.day}.${loc.month}.${loc.year} · $h:$m';
        }

        final sub = event.subtitle;

        return DraggableScrollableSheet(
          initialChildSize: 0.42,
          minChildSize: 0.32,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title.isEmpty ? 'Magic event' : event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (sub != null && sub.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      sub,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '${fmt(event.startAt)} – ${fmt(event.endAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rază ~${event.radiusMeters.round()} m · '
                    '${event.participantCount} participanți',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context)!.close),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _projectMagicEventAuraSlots() async {
    if (!mounted || _mapboxMap == null) return;
    final events = _magicEventsAuraCandidates;
    if (events.isEmpty) {
      if (_magicEventAuraSlots.isNotEmpty && mounted) {
        setState(() => _magicEventAuraSlots = []);
      }
      return;
    }
    try {
      final cam = await _mapboxMap!.getCameraState();
      final zoom = cam.zoom.toDouble();
      final sorted = [...events]
        ..sort((a, b) => b.participantCount.compareTo(a.participantCount));
      final top = sorted.take(6).toList();
      final slots = <NabourAuraMapSlot>[];
      for (final e in top) {
        final pt = MapboxUtils.createPoint(e.latitude, e.longitude);
        final sc = await _mapboxMap!.pixelForCoordinate(pt);
        final mpp = await _mapboxMap!.projection.getMetersPerPixelAtLatitude(
          e.latitude,
          zoom,
        );
        final radiusPx = (e.radiusMeters / mpp).clamp(48.0, 340.0);
        final center = Offset(sc.x.toDouble(), sc.y.toDouble());
        final density = math.max(12, e.participantCount + 16);
        slots.add(NabourAuraMapSlot(
          eventId: e.id,
          screenCenter: center,
          radiusPx: radiusPx,
          userDensity: density,
          rippleTick: _magicEventRippleTick[e.id] ?? 0,
          title: e.title,
          endsAt: e.endAt,
          event: e,
        ));
      }
      if (mounted) setState(() => _magicEventAuraSlots = slots);
    } catch (e) {
      Logger.debug('Aura project: $e', tag: 'MAGIC_EVENT');
    }
  }

  /// [useCommittedLocalRole]: după comutare rol în UI, nu citim `getUserRole` — evită lag replica
  /// care readucea vechiul rol și lăsa avatarul „înghețat” pe cel anterior.
  Future<void> _initializeScreen({bool useCommittedLocalRole = false}) async {
    try {
      await GhostModeService.instance.ensureLoaded();

      late final UserRole role;
      if (useCommittedLocalRole) {
        role = _currentRole;
      } else {
        role = await _firestoreService.getUserRole().timeout(
          const Duration(seconds: 5),
          onTimeout: () => UserRole.passenger,
        );
        if (!mounted) return;
        setState(() {
          _currentRole = role;
        });
      }

      // Validate that driver accounts also have car profile completed.
      final profileSnapshot = await _firestoreService
          .getUserProfileStream()
          .first
          .timeout(const Duration(seconds: 5), onTimeout: () => throw TimeoutException('profile timeout'));
      final profileData = profileSnapshot.data();
      final isVerifiedDriverProfile = _isDriverProfileComplete(profileData);
      if (mounted) {
        final parsedShowHome = _parseShowSavedHomePinOnMap(profileData);
        setState(() {
          _driverProfile = profileData;
          _manualOrientationPin = _parseMapOrientationPin(profileData);
          _manualOrientationPinLabel = _parseMapOrientationPinLabel(profileData);
          _showSavedHomePinOnMap = parsedShowHome;
          _isDriverAccountVerified = isVerifiedDriverProfile;
          // Nu mai coborâm rolul la pasager: contul rămâne șofer în UI (switch în AppBar).
          // Disponibilitatea pentru curse se pornește din `_checkAndStartDriverSystemIfReady`
          // când rolul e șofer și profilul mașinii e complet.
        });
        Provider.of<MapSettingsProvider>(context, listen: false)
            .setShowHomePinOnMap(parsedShowHome);
        _profileGarageSlotIdsSig = _garageSlotIdsSigFromProfile(profileData);
        unawaited(_syncMapOrientationPinAnnotation());
        if (_positionForUserMapMarker() != null) {
          unawaited(_updateUserMarker(centerCamera: false));
        }
      }

      if (profileData != null) {
        if (!profileData.containsKey('ghostMode')) {
          await GhostModeService.instance.setBlocking(true);
        } else {
          await GhostModeService.instance
              .syncFromServer(profileData['ghostMode'] == true);
        }
      }
      // La fiecare startup curățăm prezența veche din `user_visible_locations` și RTDB,
      // indiferent de preferința ghost mode. Dacă app-ul a fost ucis brusc în sesiunea
      // anterioară (fără a apuca să cheme setInvisible), documentul putea rămâne
      // isVisible=true — ceea ce ar expune login-ul utilizatorului contactelor din apropiere.
      // Vizibilitatea socială se activează EXCLUSIV prin acțiune explicită a utilizatorului.
      await NeighborLocationService().setInvisible();

      // --- SEQUENTIAL STARTUP SEQUENCE ---
      // We yield to the UI between heavy tasks to prevent frame drops/ANRs.
      
      // 1. Critical: Location (awaits permission if needed)
      await _getCurrentLocation(centerCamera: false);
      
      // 2. Background streams (listener registration is fast)
      _listenForNearbyDrivers();
      _listenForNeighbors();
      _listenIncomingFriendRequests();
      _listenForEmergencyAlerts();
      if (_currentRole == UserRole.driver) {
        _listenForRideBroadcasts();
      }

      // 3. Deferred tasks (after first frame to let map render)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        
        // Load contacts (awaits permission if needed)
        _listenFriendPeers();
        await _loadContactUids();
        
        if (!mounted) return;
        
        // Session restoration
        unawaited(_checkActiveRide());
        
        if (role == UserRole.passenger) {
          unawaited(_checkInactiveUser());
        }
      });


      _savedAddressesForHomePinSub?.cancel();
      _savedAddressesForHomePinSub =
          _firestoreService.getSavedAddresses().listen((list) {
        if (!mounted) return;
        setState(() {
          _savedAddressesForHomePin = list;
          _savedAddressesFirestoreHydrated = true;
        });
        unawaited(_syncMapOrientationPinAnnotation());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_syncMapOrientationPinAnnotation());
        });
      }, onError: (Object e) {
        Logger.error('Saved addresses stream: $e', tag: 'MAP', error: e);
        if (mounted) {
          setState(() => _savedAddressesFirestoreHydrated = true);
        }
      });

      _driverProfileSubscription?.cancel();
      _driverProfileSubscription =
          _firestoreService.getUserProfileStream().listen((snapshot) {
        if (!mounted || !snapshot.exists) return;
        final updatedProfile = snapshot.data();
        final newGarageSig = _garageSlotIdsSigFromProfile(updatedProfile);
        if (newGarageSig != _profileGarageSlotIdsSig) {
          _profileGarageSlotIdsSig = newGarageSig;
          unawaited(_loadCustomCarAvatar());
        }
        if (_currentRole == UserRole.driver) {
          final wasAvailable = _isDriverAvailable;
          final parsedShowHomeDriver = _parseShowSavedHomePinOnMap(updatedProfile);
          setState(() {
            _driverProfile = updatedProfile;
            _manualOrientationPin = _parseMapOrientationPin(updatedProfile);
            _manualOrientationPinLabel = _parseMapOrientationPinLabel(updatedProfile);
            _showSavedHomePinOnMap = parsedShowHomeDriver;
            _isDriverAccountVerified = _isDriverProfileComplete(updatedProfile);
            if (!_isDriverAccountVerified && _isDriverAvailable) {
              _isDriverAvailable = false;
            }
          });
          Provider.of<MapSettingsProvider>(context, listen: false)
              .setShowHomePinOnMap(parsedShowHomeDriver);
          if (!_isDriverAccountVerified && wasAvailable && mounted) {
            _stopListeningForRides();
            _stopLocationUpdates();
            unawaited(_firestoreService.updateDriverAvailability(false));
            _ensurePassiveLocationWarmupIfNeeded();
            unawaited(_updateLocationPuck());
          }
          _initializeDriverRideSystem();
        } else {
          final parsedShowHomePassenger = _parseShowSavedHomePinOnMap(updatedProfile);
          setState(() {
            _manualOrientationPin = _parseMapOrientationPin(updatedProfile);
            _manualOrientationPinLabel = _parseMapOrientationPinLabel(updatedProfile);
            _showSavedHomePinOnMap = parsedShowHomePassenger;
          });
          Provider.of<MapSettingsProvider>(context, listen: false)
              .setShowHomePinOnMap(parsedShowHomePassenger);
          unawaited(_syncMapOrientationPinAnnotation());
        }
        unawaited(_syncMapOrientationPinAnnotation());
        if (_positionForUserMapMarker() != null) {
          unawaited(_updateUserMarker(centerCamera: false));
        }
      }, onError: (e) {
        Logger.error('User profile stream error: $e', tag: 'MAP', error: e);
      });

      unawaited(_loadCustomCarAvatar());
    } catch (e) {
      Logger.error('Screen initialization error: $e', error: e);
      if (mounted) {
        setState(() {
          _currentRole = UserRole.passenger;
        });
      }
    }
  }

  /// Plăcuță + nume public pentru eticheta mașinii tale (Firestore `users` + fallback Auth).
  ({String? plate, String? name}) _resolvedPlateAndPublicName() {
    final p = _driverProfile;
    var plate = (p?['licensePlate'] ?? '').toString().trim();
    if (plate.isEmpty) {
      plate = (p?['carPlate'] ?? p?['plate'] ?? '').toString().trim();
    }
    var name = (p?['displayName'] ?? '').toString().trim();
    if (name.isEmpty) {
      name = (p?['name'] ?? p?['publicName'] ?? '').toString().trim();
    }
    if (name.isEmpty) {
      name = (FirebaseAuth.instance.currentUser?.displayName ?? '').trim();
    }
    return (
      plate: plate.isEmpty ? null : plate,
      name: name.isEmpty ? null : name,
    );
  }

  /// După ce `_contactUids` include prietenii, re-trimitem `allowedUids` la Firestore/RTDB.
  void _maybeRepublishSocialMapAfterContactsLoaded() {
    final pos = _currentPositionObject;
    if (pos == null) return;
    if (!_wantsNeighborSocialPublish) return;
    _publishNeighborSocialMapFreshUnawaited(pos, forceNeighborTelemetry: true);
  }

  bool _isDriverProfileComplete(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    String read(String key) => (profile[key] ?? '').toString().trim();
    final hasPlate = read('licensePlate').isNotEmpty;
    // driver_applications folosește carBrand; users folosește adesea carMake
    final hasMake =
        read('carMake').isNotEmpty || read('carBrand').isNotEmpty;
    final hasModel = read('carModel').isNotEmpty;
    final hasColor = read('carColor').isNotEmpty;
    final hasYear = read('carYear').isNotEmpty;
    final hasCategory = read('driverCategory').isNotEmpty;
    return hasPlate && hasMake && hasModel && hasColor && hasYear && hasCategory;
  }

  void _initializeDriverRideSystem() {
    if (_driverProfile != null) {
      final categoryStr = _driverProfile!['driverCategory'] as String?;
      _driverCategory = _getCategoryFromString(categoryStr);
      
      // âœ… FIX: Nu pornim listener-ul aici
      if (_driverCategory != null) {
        Logger.info('Driver system initialized for category: ${_driverCategory!.name}', tag: 'MAP');
        
        // âœ… FIX: Verifică dacă șoferul e deja disponibil din storage
        _checkAndStartDriverSystemIfReady();
      }
    }
  }

  // âœ… SOLUÈšIE COMBINATÄ‚: Metodă nouă pentru verificare completă
  void _checkAndStartDriverSystemIfReady() async {
    final gen = ++_driverAvailabilityCheckGen;
    try {
      var currentStatus = await _firestoreService.getDriverAvailability();

      if (!mounted || gen != _driverAvailabilityCheckGen) return;

      // Rol „șofer” din meniu = vrei flux de șofer: nu există un al doilea comutator
      // în UI; dacă Firestore încă are `isAvailable: false`, îl aliniem aici după
      // profil complet (altfel pasagerul nu te vede niciodată în matching).
      if (!currentStatus &&
          _currentRole == UserRole.driver &&
          _isDriverAccountVerified &&
          _driverCategory != null) {
        final ids = _resolvedPlateAndPublicName();
        if (ids.plate != null && ids.name != null) {
          try {
            await _firestoreService.updateDriverAvailability(
              true,
              displayName: ids.name,
              licensePlate: ids.plate,
              category: _driverCategory!,
            );
            currentStatus = true;
          } catch (e) {
            Logger.error('Auto-enable driver availability failed: $e', tag: 'MAP', error: e);
          }
        }
      }

      if (!mounted || gen != _driverAvailabilityCheckGen) return;

      setState(() { _isDriverAvailable = currentStatus; });
      unawaited(_loadCustomCarAvatar());
      unawaited(_updateLocationPuck());

      if (_driverCategory != null && _isDriverAvailable) {
        final cat = _driverCategory!;
        final alreadyRunning = _driverPipelineCategory == cat &&
            _pendingRidesSubscription != null &&
            _positionSubscription != null;
        if (alreadyRunning) {
          if (_currentPositionObject != null) {
            unawaited(_updateUserMarker(centerCamera: false));
          }
          return;
        }
        _driverPipelineCategory = cat;
        Logger.debug(
          'Starting driver system - category: ${cat.name}, available: $_isDriverAvailable',
          tag: 'MAP',
        );
        _startListeningForRides();
        _startDriverLocationUpdates();
      } else {
        _driverPipelineCategory = null;
      }

      if (_currentPositionObject != null) {
        unawaited(_updateUserMarker(centerCamera: false));
        if (_isVisibleToNeighbors &&
            _isDriverAvailable &&
            _currentRole == UserRole.driver) {
          _publishNeighborSocialMapFreshUnawaited(
            _currentPositionObject!,
            forceNeighborTelemetry: true,
          );
        }
      }
    } catch (e) {
      Logger.error('Error checking driver status: $e', error: e);
    }
  }

  RideCategory? _getCategoryFromString(String? categoryStr) {
    switch (categoryStr) {
      case 'any':
        return RideCategory.any;
      case 'standard':
        return RideCategory.standard;
      case 'family':
        return RideCategory.family;
      case 'energy':
        return RideCategory.energy;
      case 'best':
        return RideCategory.best;
      case 'utility':
        return RideCategory.utility;
      case null:
        return null;
      default:
        return RideCategory.standard;
    }
  }

  void _startListeningForRides() {
    if (_driverCategory == null || !_isDriverAvailable) return;
    
    Logger.debug('Starting to listen for ${_driverCategory!.name} rides', tag: 'MAP');
    
    _pendingRidesSubscription?.cancel();

    // Restore cache (fără sonerie) ca să vezi oferta instant dacă stream-ul Ã®ntârzie.
    _restoreCachedOfferIfPossible(playSound: false);

    _pendingRidesSubscription = _firestoreService
        .getPendingRideRequests(_driverCategory!)
        .listen((rides) {
      Logger.debug('Received ${rides.length} pending rides', tag: 'MAP');

      if (!mounted) return;

      final currentDriverId = FirebaseAuth.instance.currentUser?.uid;
      final availableRides = rides.where((ride) {
        if (ride.status == 'pending') return true;
        if (ride.status == 'driver_found') {
          if (ride.driverId == null || ride.driverId!.isEmpty) return true;
          if (currentDriverId != null && ride.driverId == currentDriverId) return true;
          return false;
        }
        return false;
      }).toList();

      // Update cache scurt.
      _pendingRidesCache = availableRides;
      _offersCacheUpdatedAt = DateTime.now();

      final newFirstRideId = availableRides.isNotEmpty ? availableRides.first.id : null;
      final currentOfferId = _currentRideOffer?.id;

      // Aceeași ofertă â€” actualizează datele fără reset countdown (un singur setState).
      if (_currentRideOffer != null &&
          newFirstRideId != null &&
          currentOfferId == newFirstRideId) {
        setState(() {
          _pendingRides = availableRides;
          _currentRideOffer = availableRides.first;
        });
        return;
      }

      // Ofertă nouă când nu era niciuna afișată.
      if (availableRides.isNotEmpty && _currentRideOffer == null) {
        setState(() { _pendingRides = availableRides; });
        _showRideOffer(availableRides.first, playSound: true);
      } else if (availableRides.isNotEmpty && _currentRideOffer != null) {
        // Switch pe altă ofertă (ID diferit).
        setState(() { _pendingRides = availableRides; });
        _showRideOffer(availableRides.first, playSound: true);
      } else if (availableRides.isEmpty && _currentRideOffer != null) {
        setState(() { _pendingRides = availableRides; });
        _dismissRideOffer();
      } else {
        setState(() { _pendingRides = availableRides; });
      }
    }, onError: (e) {
      Logger.error('Ride offers stream error: $e', tag: 'MAP', error: e);
      // Dacă stream-ul eșuează, păstrează perceived performance prin cache.
      if (mounted) _restoreCachedOfferIfPossible(playSound: false);
    });
  }

  void _stopListeningForRides() {
    _pendingRidesSubscription?.cancel();
    _pendingRidesSubscription = null;
    _driverPipelineCategory = null;
    _rideOfferTimer?.cancel();
    if (mounted) {
      setState(() {
        _pendingRides.clear();
        _currentRideOffer = null;
      });
    }
  }

  void _restoreCachedOfferIfPossible({required bool playSound}) {
    if (_currentRideOffer != null) return;
    if (_pendingRidesCache.isEmpty) return;
    if (_offersCacheUpdatedAt == null) return;

    final age = DateTime.now().difference(_offersCacheUpdatedAt!);
    if (age > _offersCacheTtl) return;

    final ride = _pendingRidesCache.first;
    final elapsedSeconds = age.inSeconds;
    final remaining = (30 - elapsedSeconds).clamp(1, 30).toInt();

    setState(() {
      _pendingRides = _pendingRidesCache;
    });

    _showRideOffer(
      ride,
      playSound: playSound,
      remainingSecondsOverride: remaining,
    );
  }

  void _showRideOffer(
    Ride ride, {
    bool playSound = true,
    int? remainingSecondsOverride,
  }) {
    if (mounted) {
      // âœ… FIX: SETEAZÄ‚ STAREA ÃŽNTÃ‚I
      setState(() {
        _currentRideOffer = ride;
        _remainingSeconds = remainingSecondsOverride ?? 30;
      });

      // 👻 Ghost Mode: notify orchestrator
      if (kDebugMode) {
        NabourGhostOrchestrator().notifyRideOfferReceived();
      }
      
      // âœ… FIX: APOI REDÄ‚ SUNETUL DUPÄ‚ FRAME UPDATE
      if (playSound) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _playRideOfferSoundRobust();
          }
        });
      }
    }
    
    Logger.debug('Showing ride offer: ${ride.destinationAddress}', tag: 'MAP');

    _rideOfferTimer?.cancel();
    _rideOfferTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
      }
      
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _dismissRideOffer();
      }
    });
  }

  void _dismissRideOffer() {
    _rideOfferTimer?.cancel();
    _rideOfferTimer = null;
    if (mounted) {
      setState(() {
        _currentRideOffer = null;
        _remainingSeconds = 30;
        _isProcessingAccept = false;
        _isProcessingDecline = false;
      });
      try {
        unawaited(Provider.of<DriverVoiceController>(context, listen: false).reset());
      } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    }
  }

  Future<void> _acceptRide(Ride ride) async {
    // âœ… FIX: Protecție Ã®mbunătățită Ã®mpotriva apăsărilor multiple
    if (_isProcessingAccept) {
      Logger.debug('Already processing accept request, ignoring duplicate tap', tag: 'MAP');
      return;
    }
    
    // âœ… FIX: Setează starea IMEDIAT, Ã®nainte de orice altceva
    if (!mounted) return;
    setState(() {
      _isProcessingAccept = true;
    });

    // Oprim countdown-ul ca să nu expire oferta Ã®n timp ce așteptăm confirmarea pasagerului.
    _rideOfferTimer?.cancel();
    _rideOfferTimer = null;
    
    // âœ… FIX: Forțează rebuild-ul UI-ului pentru a dezactiva butonul imediat
    await Future.microtask(() {});
    
    try {
      Logger.debug('Accepting ride: ${ride.id}', tag: 'MAP');
      await _firestoreService.acceptRide(ride.id);
      _acceptedRideStatusSubscription?.cancel();
      _acceptedRideStatusSubscription =
          _firestoreService.getRideStream(ride.id).listen((updatedRide) {
        if (!mounted) return;
        if (updatedRide.status == 'accepted' ||
            updatedRide.status == 'arrived' ||
            updatedRide.status == 'in_progress') {
          _acceptedRideStatusSubscription?.cancel();
          _dismissRideOffer();
          unawaited(_navigateDriverPickupWithRide(updatedRide));
        } else if (updatedRide.status == 'cancelled' ||
            updatedRide.status == 'expired') {
          _acceptedRideStatusSubscription?.cancel();
          setState(() {
            _isProcessingAccept = false;
          });
        }
      }, onError: (e) {
        Logger.error('Accept ride watcher failed: $e', tag: 'MAP', error: e);
        if (mounted) {
          setState(() {
            _isProcessingAccept = false;
          });
        }
      });
      
      // âœ… FIX: Nu mai anulăm oferta imediat - așteptăm confirmarea pasagerului
      // _dismissRideOffer(); // Comentat - lăsăm cardul să rămână până când statusul se schimbă
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.rideAcceptedWaiting),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Logger.error('Error accepting ride: $e', tag: 'MAP', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.mapAcceptRideError(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessingAccept = false;
        });
        // âœ… FIX: Re-afișează oferta dacă acceptarea a eșuat
        if (_currentRideOffer?.id == ride.id) {
          // Oferta rămâne activă
        }
      }
    } finally {
      // Resetarea _isProcessingAccept se face Ã®n _dismissRideOffer()
      // când stream-ul confirmă că oferta a fost consumată.
    }
  }

  Future<void> _declineRide(Ride ride) async {
    // ðŸš— FIX: Protecție Ã®mpotriva apăsărilor multiple
    if (_isProcessingDecline) {
      Logger.debug('Already processing decline request, ignoring duplicate tap', tag: 'MAP');
      return;
    }
    _acceptedRideStatusSubscription?.cancel();

    // Cere motivul anulării de la șofer
    CancellationReason? declineReason;
    if (mounted) {
      declineReason = await CancellationDialog.show(context);
      if (declineReason == null) return; // șoferul a apăsat înapoi
    }

    setState(() {
      _isProcessingDecline = true;
    });

    // Oprim countdown-ul imediat.
    _rideOfferTimer?.cancel();
    _rideOfferTimer = null;

    try {
      Logger.debug('Declining ride: ${ride.id}', tag: 'MAP');
      await _firestoreService.declineRide(ride.id);
      if (declineReason != null) {
        unawaited(
          CancellationService().recordDriverCancellation(ride.id, declineReason),
        );
      }
      _dismissRideOffer();
      
      final remainingRides = _pendingRides.where((r) => r.id != ride.id).toList();
      if (remainingRides.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showRideOffer(remainingRides.first);
          }
        });
      }
    } catch (e) {
      Logger.error('Error declining ride: $e', tag: 'MAP', error: e);
    } finally {
      // ðŸš— FIX: Reset protecția după procesare
      if (mounted) {
        setState(() {
          _isProcessingDecline = false;
        });
      }
    }
  }

}

