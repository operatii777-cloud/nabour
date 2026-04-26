// ignore_for_file: invalid_use_of_protected_member
part of '../map_screen.dart';

extension _MapRideFlowMethods on _MapScreenState {
  void _onSearchingForDriverPopped(Object? value) {
    if (!mounted || _currentRole != UserRole.passenger) return;
    try {
      Provider.of<FriendsRideVoiceIntegration>(context, listen: false)
          .markReturnedFromDriverSearch();
    } catch (_) { /* Mapbox op — expected on style reload or missing layer/annotation */ }
    if (value is PassengerSearchFlowResult) {
      _handlePassengerSearchFlowResult(value);
    }
  }

  void _onPassengerRideBus() {
    if (PassengerRideServiceBus.pending.value != null) {
      _drainPassengerRideBus();
    }
  }

  void _drainPassengerRideBus() {
    final v = PassengerRideServiceBus.pending.value;
    if (v == null || !mounted) return;
    PassengerRideServiceBus.pending.value = null;
    _handlePassengerSearchFlowResult(v);
  }

  void _handlePassengerSearchFlowResult(PassengerSearchFlowResult r) {
    if (!mounted || _currentRole != UserRole.passenger) return;
    if (r.shouldOpenSummary) {
      _endPassengerRideSession();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RideSummaryScreen(rideId: r.rideId)),
      );
      return;
    }
    _beginPassengerRideSession(r.rideId);
  }

  void _endPassengerRideSession() {
    _passengerRideSessionSub?.cancel();
    _passengerRideSessionSub = null;
    _passengerRideSessionId = null;
    _passengerSessionRide = null;
    _passengerDestinationHandoffStarted = false;
    if (mounted) setState(() {});
  }

  void _beginPassengerRideSession(String rideId) {
    if (!mounted || _currentRole != UserRole.passenger) return;
    if (_passengerRideSessionId == rideId && _passengerRideSessionSub != null) {
      return;
    }
    _endPassengerRideSession();
    _passengerRideSessionId = rideId;
    _passengerDestinationHandoffStarted = false;
    _passengerRideSessionSub =
        _firestoreService.getRideStream(rideId).listen((ride) {
      if (!mounted) return;
      if (_passengerRideSessionId != ride.id) return;
      setState(() => _passengerSessionRide = ride);

      if (ride.status == 'arrived' && !_passengerDestinationHandoffStarted) {
        final lat = ride.destinationLatitude;
        final lng = ride.destinationLongitude;
        if (lat != null && lng != null) {
          _passengerDestinationHandoffStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(_runPassengerDestinationHandoffFromMap(lat, lng));
          });
        }
      }

      if (const {'completed', 'cancelled', 'expired'}.contains(ride.status)) {
        final summary = ride.status == 'completed';
        _endPassengerRideSession();
        if (summary && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RideSummaryScreen(rideId: ride.id)),
          );
        }
      }
    });
  }

  Future<void> _runPassengerDestinationHandoffFromMap(
    double destLat,
    double destLng,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) return;
    await ExternalMapsLauncher.showNavigationChooser(
      context,
      destLat,
      destLng,
      title: l10n.mapFinalDestinationTitle,
      hint: l10n.mapOpenNavigationToDestinationHint,
    );
  }

  String _passengerRideSessionStatusLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'driver_found':
        return l10n.mapPassengerStatusDriverFound;
      case 'accepted':
        return l10n.mapPassengerStatusDriverOnWay;
      case 'arrived':
        return l10n.mapPassengerStatusDriverAtPickup;
      case 'in_progress':
        return l10n.mapPassengerStatusInProgress;
      default:
        return l10n.mapPassengerStatusGeneric(status);
    }
  }

  Widget _buildPassengerRideSessionOverlay() {
    final ride = _passengerSessionRide;
    if (ride == null) return const SizedBox.shrink();

    final pickupLat = ride.startLatitude;
    final pickupLng = ride.startLongitude;
    final destLat = ride.destinationLatitude;
    final destLng = ride.destinationLongitude;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _passengerRideSessionStatusLabel(ride.status),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (ride.pickupCode != null &&
                ride.pickupCode!.length >= 4 &&
                (ride.status == 'driver_found' ||
                    ride.status == 'accepted' ||
                    ride.status == 'arrived' ||
                    ride.status == 'in_progress')) ...[
              Text(
                'Cod la urcare pentru șofer',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                ride.pickupCode!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            if (ride.status == 'accepted' &&
                pickupLat != null &&
                pickupLng != null)
              OutlinedButton.icon(
                onPressed: () {
                  unawaited(
                    ExternalMapsLauncher.showNavigationChooser(
                      context,
                      pickupLat,
                      pickupLng,
                      title: AppLocalizations.of(context)!.mapNavigationToPickupTitle,
                      hint: AppLocalizations.of(context)!.mapExternalNavigationNoRouteHint,
                    ),
                  );
                },
                icon: const Icon(Icons.place_outlined, size: 20),
                label: Text(AppLocalizations.of(context)!.mapPickupExternalNavigation),
              ),
            if (ride.status == 'arrived' && destLat != null && destLng != null) ...[
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.mapOpenSameDestinationAsDriver,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  unawaited(
                    ExternalMapsLauncher.showNavigationChooser(
                      context,
                      destLat,
                      destLng,
                      title: AppLocalizations.of(context)!.mapFinalDestinationTitle,
                      hint: AppLocalizations.of(context)!.mapExternalNavigationNoRouteHint,
                    ),
                  );
                },
                icon: const Icon(Icons.flag_rounded, size: 20),
                label: Text(AppLocalizations.of(context)!.mapDestinationExternalNavigation),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _endPassengerRideSession,
                child: Text(AppLocalizations.of(context)!.mapClosePanel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ RESTAURARE SESIUNE: Verifică dacă utilizatorul curent are o cursă activă (pasager sau șofer)
  /// și îl redirecționează către ecranul respectiv.
  Future<void> _checkActiveRide() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Verificăm statusurile care indică o cursă în desfășurare
      final activeStatuses = ['accepted', 'arrived', 'in_progress', 'driver_found'];
      
      // 1. Verificăm dacă este pasager într-o cursă activă
      final passengerQuery = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('passengerId', isEqualTo: currentUserId)
          .where('status', whereIn: activeStatuses)
          .limit(1)
          .get();

      if (passengerQuery.docs.isNotEmpty && mounted) {
        final rideDoc = passengerQuery.docs.first;
        Logger.info('Restoring passenger session on map for ride: ${rideDoc.id}');
        _beginPassengerRideSession(rideDoc.id);
        return;
      }

      // 2. Verificăm dacă este șofer într-o cursă activă
      final driverQuery = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('driverId', isEqualTo: currentUserId)
          .where('status', whereIn: activeStatuses)
          .limit(1)
          .get();
          
      if (driverQuery.docs.isNotEmpty && mounted) {
         final rideDoc = driverQuery.docs.first;
         Logger.info('Restoring driver session for ride: ${rideDoc.id}');
         if (mounted) {
           final ride = Ride.fromFirestore(
             rideDoc as DocumentSnapshot<Map<String, dynamic>>,
           );
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => DriverRidePickupScreen(
                 rideId: rideDoc.id,
                 ride: ride,
               ),
             ),
           );
         }
      }
    } catch (e) {
      Logger.error('Error during session restoration check: $e', error: e);
    }
  }

  /// După încărcarea agendei, stream-urile vecini/șoferi nu reemit automat — refacem straturile din cache.
  Future<void> _reapplyContactFilterOnMap() async {
    if (!mounted) return;
    await _updateNeighborAnnotations(_lastRawNeighborsForMap);
    await _updateNearbyDrivers(_lastNearbyDriverDocs);
  }

  void _rebuildMergedContactUids() {
    final fromAgenda = _contactUsers.map((u) => u.uid).toSet();
    _contactUids = {...fromAgenda, ..._friendPeerUids};
    NeighborMapFeedController.instance.setContactUids(_contactUids!);
  }

  void _listenFriendPeers() {
    _friendPeersSub?.cancel();
    _friendPeersSub =
        FriendRequestService.instance.friendPeerUidsStream().listen((peers) {
      if (!mounted) return;
      setState(() {
        _friendPeerUids = peers;
        _rebuildMergedContactUids();
      });
      unawaited(_reapplyContactFilterOnMap());
      _maybeRepublishSocialMapAfterContactsLoaded();
    });
  }

  /// Firestore trimite actualizări în timp real — nu există interval fix de „refresh”.
  void _listenIncomingFriendRequests() {
    _incomingFriendRequestsSub?.cancel();
    _incomingFriendRequestsSub =
        FriendRequestService.instance.incomingPendingStream().listen(
      (list) {
        if (!mounted) return;
        _badgesCtrl.setFriendRequestCount(list.length);
      },
      onError: (Object e, StackTrace st) {
        Logger.error(
          'Incoming friend requests stream: $e',
          error: e,
          stackTrace: st,
          tag: 'SOCIAL',
        );
      },
    );
  }

  /// Sincronizare prieteni acceptați (când tu ai trimis cererea) + reîncărcare UID-uri.
  Future<void> _syncFriendPeersIntoContactUids() async {
    if (!mounted) return;
    await FriendRequestService.instance.ensureFriendPeersForAcceptedOutgoing();
    if (!mounted) return;
    final peers = await FriendRequestService.instance.loadFriendPeerUidSet();
    if (!mounted) return;
    setState(() {
      _friendPeerUids = peers;
      _rebuildMergedContactUids();
    });
    await _reapplyContactFilterOnMap();
    _maybeRepublishSocialMapAfterContactsLoaded();
  }

  Future<void> _loadContactUids() async {
    await FriendRequestService.instance.ensureFriendPeersForAcceptedOutgoing();
    final users = await _contactsService.loadContactUsers();
    final peers = await FriendRequestService.instance.loadFriendPeerUidSet();
    final excluded = await VisibilityPreferencesService().loadExcludedUids();
    if (mounted) {
      setState(() {
        _contactUsers = users;
        _friendPeerUids = peers;
        _rebuildMergedContactUids();
        _excludedUids = excluded;
      });
      unawaited(_reapplyContactFilterOnMap());
      _maybeRepublishSocialMapAfterContactsLoaded();
      if (users.isEmpty && _friendPeerUids.isEmpty && !_contactEmptyHintShown) {
        _contactEmptyHintShown = true;
        _showSafeSnackBar(AppLocalizations.of(context)!.mapContactsVisibilityHint, Colors.blueGrey);
      }
    }
  }

  /// ✅ NOU: Sincronizare manuală contacte
  Future<void> _refreshContacts() async {
    if (!mounted) return;
    _showSafeSnackBar(AppLocalizations.of(context)!.mapSyncingContacts, Colors.indigo);
    
    await FriendRequestService.instance.ensureFriendPeersForAcceptedOutgoing();
    // Force refresh cache în service
    final users = await _contactsService.loadContactUsers(forceRefresh: true);
    final peers = await FriendRequestService.instance.loadFriendPeerUidSet();
    final excluded = await VisibilityPreferencesService().loadExcludedUids();
    
    if (mounted) {
      setState(() {
        _contactUsers = users;
        _friendPeerUids = peers;
        _rebuildMergedContactUids();
        _excludedUids = excluded;
      });
      unawaited(_reapplyContactFilterOnMap());
      _maybeRepublishSocialMapAfterContactsLoaded();
      _showSafeSnackBar(AppLocalizations.of(context)!.mapSyncComplete(users.length), Colors.green);
    }
  }

  /// Cursele „doar contacte”: lista trebuie încărcată și nevidă. Lista goală în Firestore exclude toți șoferii.
  bool _canRequestRideWithContactFilter() {
    if (_contactUids == null) return false;
    return _contactUids!.isNotEmpty;
  }

  void _handleRoleChange(bool isDriver) {
    if (isDriver && !_isDriverAccountVerified) {
      _showSafeSnackBar(
        AppLocalizations.of(context)!.mapEnableDriverProfileHint,
        Colors.orange,
      );
      return;
    }
    final newRole = isDriver ? UserRole.driver : UserRole.passenger;
    if (_currentRole == newRole) return;

    if (!isDriver && _isDriverAvailable) {
      _stopLocationUpdates();
      _stopListeningForRides();
      unawaited(_firestoreService.updateDriverAvailability(false));
      setState(() { _isDriverAvailable = false; });
      _ensurePassiveLocationWarmupIfNeeded();
    }

    // âœ… FIX: Actualizează imediat rolul local pentru un feedback UI instantaneu
    setState(() { _currentRole = newRole; });
    
    // Reset─âm cache marker pentru a for╚øa recrearea pe noul rol (pasager vs ╚Öofer)
    _userMarkerVisualCacheKey = null;
    _userDriverMarkerIconInFlight = null;
    _forceUserCarMarkerFullRebuild = true;
    _MapInitMethods._staticMarkerIconCache.clear();

    // Dup─â frame: `setState` e vizibil, apoi desen─âm slotul corect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _clearGpsUserMarkerThrottle();
      unawaited(_updateUserMarker(centerCamera: false));
      unawaited(_updateLocationPuck());
      unawaited(_loadCustomCarAvatar());
    });

    // Salvează asincron și remapează ascultătorii existenți
    _firestoreService.setUserRole(newRole).then((_) {
        if (mounted) { 
          unawaited(_clearSocialMapMarkers()); // ✅ CURĂȚĂ Tot înainte de re-inițializare
          unawaited(_initializeScreen(useCommittedLocalRole: true));
        }
    });

    if (isDriver) {
      // În UI există doar comutatorul rolului; când intri pe șofer, te marcăm
      // imediat disponibil pentru a primi curse de la contacte.
      unawaited(_enableDriverAvailabilityFromRoleSwitch());
    }
  }

  Future<void> _enableDriverAvailabilityFromRoleSwitch() async {
    if (!_isDriverAccountVerified || _driverCategory == null) return;
    try {
      final ids = _resolvedPlateAndPublicName();
      if (ids.plate == null || ids.name == null) return;
      await _firestoreService.updateDriverAvailability(
        true,
        displayName: ids.name,
        licensePlate: ids.plate,
        category: _driverCategory!,
      );
      if (!mounted) return;
      setState(() => _isDriverAvailable = true);
      _startListeningForRides();
      _startDriverLocationUpdates();
      if (_currentPositionObject != null) {
        _publishNeighborSocialMapFreshUnawaited(
          _currentPositionObject!,
          forceNeighborTelemetry: true,
        );
      }
    } catch (e) {
      Logger.error('Role switch availability enable failed: $e', tag: 'MAP', error: e);
    }
  }

}

