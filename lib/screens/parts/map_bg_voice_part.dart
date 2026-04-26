// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapBgVoiceMethods on _MapScreenState {



  void _resetRouteStateIfNeeded() {
    if (!_shouldResetRoute || !mounted) return;
    
    Logger.debug('MapScreen: Resetting route state after ride completion');
    
    _routeAnnotationManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing route annotations: $e', error: e);
    });
    
    _routeMarkersAnnotationManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing route markers: $e', error: e);
    });

    _pickupCircleManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing pickup circle: $e', error: e);
    });

    _destinationCircleManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing destination circle: $e', error: e);
    });
    
    _rideRequestPanelKey.currentState?.resetPanel();
    
    _shouldResetRoute = false;

    Logger.info('MapScreen: Route state reset completed');
  }

  // ── Voice→UI bridge ──────────────────────────────────────────────────────────
  // Listener înregistrat pe FriendsRideVoiceIntegration. Când AI-ul rezolvă
  // o adresă și o publică via onFillAddressInUI, aceasta propagă adresa în
  // controller-ele hărții, geocodează și declanșează calculul de rută.
  void _onVoiceAddressChanged() {
    if (!mounted) return;
    try {
      final voice = Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
      if (!voice.hasNewVoiceDestination && !voice.hasNewVoicePickup) return;

      final dest = voice.voiceDestination;
      final pickup = voice.voicePickup;
      final destLat = voice.voiceDestinationLatitude;
      final destLng = voice.voiceDestinationLongitude;
      final pickupLat = voice.voicePickupLatitude;
      final pickupLng = voice.voicePickupLongitude;
      voice.markVoiceEventsProcessed();

      if (dest != null && dest.isNotEmpty) {
        setState(() => _routeCtrl.destinationController.text = dest);
        if (destLat != null && destLng != null) {
          setState(() {
            _routeCtrl.destinationLatitude = destLat;
            _routeCtrl.destinationLongitude = destLng;
          });
          unawaited(_checkAndShowRouteAutomatically());
        } else {
          unawaited(_geocodeVoiceAddress(dest, isPickup: false));
        }
      }
      if (pickup != null && pickup.isNotEmpty) {
        setState(() => _routeCtrl.pickupController.text = pickup);
        if (!_isPlaceholderCurrentLocationLabel(pickup)) {
          if (pickupLat != null && pickupLng != null) {
            setState(() {
              _routeCtrl.pickupLatitude = pickupLat;
              _routeCtrl.pickupLongitude = pickupLng;
            });
            unawaited(_checkAndShowRouteAutomatically());
          } else {
            unawaited(_geocodeVoiceAddress(pickup, isPickup: true));
          }
        }
      }

      // Navigate to SearchingForDriverScreen when secondary voice path creates a ride
      if (voice.shouldNavigateToSearching && voice.navigationRideId != null) {
        final rideId = voice.navigationRideId!;
        voice.markNavigationToSearchingProcessed();
        unawaited(voice.stopVoiceInteraction());
        Navigator.push<Object?>(
          context,
          AppTransitions.slideUp(SearchingForDriverScreen(rideId: rideId)),
        ).then(_onSearchingForDriverPopped);
      }
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
  }

  /// Etichete UI pentru „punctul de plecare curent” — nu sunt adresă pentru Nominatim.
  bool _isPlaceholderCurrentLocationLabel(String address) {
    final t = address.toLowerCase().trim();
    return t == 'locația curentă' ||
        t == 'locatia curenta' ||
        t == 'current location' ||
        t == 'poziția curentă' ||
        t == 'pozitia curenta' ||
        t == 'locație curentă' ||
        t == 'locatie curenta';
  }

  Future<void> _geocodeVoiceAddress(String address, {required bool isPickup}) async {
    if (_isPlaceholderCurrentLocationLabel(address)) return;
    final point = await _geocodeAddress(address);
    if (point == null || !mounted) return;
    setState(() {
      if (isPickup) {
        _routeCtrl.pickupLatitude = point.coordinates.lat.toDouble();
        _routeCtrl.pickupLongitude = point.coordinates.lng.toDouble();
      } else {
        _routeCtrl.destinationLatitude = point.coordinates.lat.toDouble();
        _routeCtrl.destinationLongitude = point.coordinates.lng.toDouble();
      }
    });
    unawaited(_checkAndShowRouteAutomatically());
  }
  // ─────────────────────────────────────────────────────────────────────────────

  // ✅ FIX: Metodă robustă cu multiple fallback-uds
  Future<void> _playRideOfferSoundRobust() async {
    // ✅ VERIFICĂ DOAR mounted - eliminăm verificarea _currentRideOffer
    if (!mounted) return;
    
    Logger.debug('Starting ride offer sound...', tag: 'SOUND');
    
    try {
      // ✅ FIX 1: Testează multiple metode de redare audio
      bool audioPlayed = false;
      
      // Metodă 1: AudioService
      try {
        await _audioService.playRideRequestSound();
        audioPlayed = true;
        Logger.info('AudioService played successfully');
      } catch (e) {
        Logger.error('AudioService failed: $e', error: e);
      }
      
      // Metodă 2: Fallback la system sounds
      if (!audioPlayed) {
        try {
          await SystemSound.play(SystemSoundType.alert);
          audioPlayed = true;
          Logger.info('SystemSound played successfully');
        } catch (e) {
          Logger.error('SystemSound failed: $e', error: e);
        }
      }
      
      // Metodă 3: Fallback la multiple HapticFeedback
      if (!audioPlayed) {
        try {
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 300));
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 300));
          HapticFeedback.heavyImpact();
          Logger.info('HapticFeedback sequence played');
        } catch (e) {
          Logger.error('HapticFeedback failed: $e', error: e);
        }
      }
      
      // ✅ FIX 2: Redă sunetele suplimentare cu interval mai mare
      if (mounted) {
        for (int i = 1; i <= 3; i++) {
          Future.delayed(Duration(milliseconds: 1000 * i), () async {
            if (mounted) {
              try {
                await _audioService.playRideRequestSound();
              } catch (e) {
                HapticFeedback.heavyImpact();
              }
            }
          });
        }
      }
      
    } catch (e) {
      Logger.error('CRITICAL: All audio methods failed: $e', error: e);
      // Ultimate fallback: Show visual notification
      if (!mounted) return;
      final l10n = lookupAppLocalizations(WidgetsBinding.instance.platformDispatcher.locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.newRideAudioUnavailable),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _listenForChatMessages(String rideId) {
    _chatMessagesSubscription?.cancel();
    _chatMessagesSubscription = _firestoreService.getChatMessages(rideId).listen((snapshot) {
      if (!mounted) return;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final messageData = change.doc.data();
          final senderId = messageData?['senderId'] as String?;
          final messageText = messageData?['message'] as String? ?? messageData?['text'] as String?;

          // ✅ FIX: Audio pentru mesaje de la șofer către pasager (sau invers)
          if (senderId != null && senderId != currentUserId) {
            // 🔊 FIX: Redă sunetul doar pentru mesajele de chat reale (nu pentru actualizări de locație sau mesaje de sistem)
            if (messageText != null && 
                messageText.isNotEmpty && 
                !messageText.contains('location_update') &&
                !messageText.startsWith('system:')) {
              
              Logger.debug('New message from $senderId to $currentUserId - playing sound notification', tag: 'MAP_CHAT');
              
              // ✅ FIX: Redă sunetul pe background thread
              unawaited(_audioService.playMessageReceivedSound().catchError((e) async {
                Logger.error('Error playing chat sound: $e', tag: 'MAP_CHAT', error: e);
                // ✅ FALLBACK: Încearcă sunetul de sistem dacă audio custom eșuează
                try {
                  await SystemSound.play(SystemSoundType.alert);
                } catch (e2) {
                  Logger.error('Even system sound failed: $e2', tag: 'MAP_CHAT');
                }
              }));
              
              // ✅ FIX: Înlocuiește Vibration cu HapticFeedback
              HapticFeedback.mediumImpact();
            }
          }
        }
      }
    }, onError: (e) {
      Logger.error('Chat messages stream error: $e', tag: 'MAP_CHAT', error: e);
    });
  }

  geolocator.Position _applyRoadSnapping(geolocator.Position rawPosition) {
    if (_previousPositionObject == null) {
      return rawPosition;
    }

    final distanceFromPrevious = geolocator.Geolocator.distanceBetween(
      _previousPositionObject!.latitude,
      _previousPositionObject!.longitude,
      rawPosition.latitude,
      rawPosition.longitude,
    );

    if (distanceFromPrevious > 100) {
      Logger.debug('GPS jump detected: ${distanceFromPrevious.toStringAsFixed(1)}m - applying road snapping');
      final interpolationFactor = 100 / distanceFromPrevious;
      final correctedLat = _previousPositionObject!.latitude + 
          (rawPosition.latitude - _previousPositionObject!.latitude) * interpolationFactor;
      final correctedLng = _previousPositionObject!.longitude + 
          (rawPosition.longitude - _previousPositionObject!.longitude) * interpolationFactor;

      return geolocator.Position(
        latitude: correctedLat, longitude: correctedLng,
        timestamp: rawPosition.timestamp, accuracy: rawPosition.accuracy,
        altitude: rawPosition.altitude, altitudeAccuracy: rawPosition.altitudeAccuracy,
        heading: rawPosition.heading, headingAccuracy: rawPosition.headingAccuracy,
        speed: rawPosition.speed, speedAccuracy: rawPosition.speedAccuracy,
      );
    }

    if (distanceFromPrevious < 5 && rawPosition.accuracy > 10) {
      Logger.debug('GPS noise detected - applying smoothing');
      const smoothingFactor = 0.7;
      final smoothedLat = rawPosition.latitude * smoothingFactor + 
          _previousPositionObject!.latitude * (1 - smoothingFactor);
      final smoothedLng = rawPosition.longitude * smoothingFactor + 
          _previousPositionObject!.longitude * (1 - smoothingFactor);

      return geolocator.Position(
        latitude: smoothedLat, longitude: smoothedLng,
        timestamp: rawPosition.timestamp, accuracy: rawPosition.accuracy,
        altitude: rawPosition.altitude, altitudeAccuracy: rawPosition.altitudeAccuracy,
        heading: rawPosition.heading, headingAccuracy: rawPosition.headingAccuracy,
        speed: rawPosition.speed, speedAccuracy: rawPosition.speedAccuracy,
      );
    }
    return rawPosition;
  }

  /// Resetează toți managerii de adnotare la null (lazy recreation) după o schimbare de stil.
  /// Mapbox invalidează automat managerii existenți la loadStyleURI.
  void _resetAnnotationManagers() {
    _routeAnnotationManager = null;
    _altRouteAnnotationManager = null;
    _routeMarkersAnnotationManager = null;
    _userPointAnnotationManager = null;
    _driversAnnotationManager = null;
    _driversAnnotationTapListenerRegistered = false;
    _driverAnnotationIdToUid.clear();
    _neighborsAnnotationManager = null;
    _neighborsAnnotationTapListenerRegistered = false;
    _pickupCircleManager = null;
    _destinationCircleManager = null;
    _pickupSuggestionsManager = null;
    _poiLayersInitialized = false;
    _userPointAnnotation = null;
    _userMarkerVisualCacheKey = null;
    _clearAndroidUserMarkerOverlayFields();
    _clearAndroidPrivatePinOverlayFields();
    _savedHomeFavoritePinManager = null;
    _savedHomeFavoritePinTapRegistered = false;
    _orientationReperPinManager = null;
    _orientationReperPinTapRegistered = false;
    _resetDriverMarkerInterpolation();
    _nearbyDriverAnnotations.clear();
    _neighborAnnotations.clear();
    _neighborUidsBeingCreated.clear();
    _poiAnnotations.clear();
    _emojiAnnotationManager = null;
    _emojiAnnotations.clear();
    _lastMapEmojiLayerSig = null;
    _momentAnnotationManager = null;
    _momentAnnotations.clear();
    _momentAnnotationIdToMomentId.clear();
    _parkingSwapAnnotationManager = null;
    _parkingSpotAnnotations.clear();
    _parkingYieldMySpotManager = null;
    _parkingYieldMySpotAnnotation = null;
    _parkingYieldTargetLat = null;
    _parkingYieldTargetLng = null;
    _awaitingParkingYieldMapPick = false;
  }

  /// După multe modificări runtime pe straturi, pe unele driver-e GPU managerii PointAnnotation
  /// rămân apelabili din Dart dar nu mai randează. [deleteAll] + reset referințe obligă recrearea lazy.
  ///
  /// IMPORTANT: Managerii home/reper NU sunt nullați aici — ei folosesc ID-uri fixe native.
  /// Dacă sunt nullați și re-creați cu același ID înainte ca layer-ul nativ să fie eliminat din
  /// stil, Mapbox aruncă "layer already exists" și pinul nu mai apare. _syncMapOrientationPinAnnotation
  /// face oricum deleteAll() + re-creare adnotări, deci nu e nevoie de reset here.
  Future<void> _disposePointAnnotationManagersAfterRuntimeStyleMutation() async {
    if (!mounted || _mapboxMap == null) return;
    try {
      await _userPointAnnotationManager?.deleteAll();
    } catch (e) {
      Logger.debug('User marker deleteAll before style sync: $e', tag: 'MAP');
    } finally {
      _userPointAnnotationManager = null;
      _userPointAnnotation = null;
      _userMarkerVisualCacheKey = null;
      _clearAndroidUserMarkerOverlayFields();
      if (mounted) {
        setState(_clearAndroidPrivatePinOverlayFields);
      } else {
        _clearAndroidPrivatePinOverlayFields();
      }
    }
    Logger.info(
      'Point annotation managers disposed after style overlays (will recreate on next sync)',
      tag: 'MAP',
    );
  }

}

