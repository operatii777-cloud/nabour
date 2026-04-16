import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/mapbox_utils.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Visibility;
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/models/ride_preferences_model.dart';
import 'package:nabour_app/models/saved_address_model.dart';
import 'package:nabour_app/screens/map_picker_screen.dart';
import 'package:nabour_app/screens/searching_for_driver_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/geocoding_service.dart';
// PricingService import removed - Nabour free model
import 'package:nabour_app/services/routing_service.dart';
import 'package:nabour_app/widgets/category_card.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/config/nabour_map_styles.dart';
import 'package:nabour_app/l10n/app_localizations.dart';

class RideRequestScreen extends StatefulWidget {
  final geolocator.Position startPosition;

  const RideRequestScreen({
    super.key,
    required this.startPosition,
  });

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  // Controllers and Focus Nodes
  final _formKey = GlobalKey<FormState>();
  final _startAddressController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  // Services
  final FirestoreService _firestoreService = FirestoreService();
  // final PricingService _pricingService = PricingService(); // Eliminat - Nabour free model
  final GeocodingService _geocodingService = GeocodingService();
  final RoutingService _routingService = RoutingService();
  // final EtaService _etaService = EtaService(); // Eliminat

  // Map related
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  Map<String, dynamic>? _routeGeoJSON;

  // State Management
  bool _isLoading = false;
  bool _isShowingSuggestions = false;
  bool _isAutoStarting = false; // ✅ NOU: Indicator pentru auto-start
  Point? _startPoint;
  Point? _endPoint;

  // Ride Details
  Map<RideCategory, Map<String, double>> _faresByCategory = {};
  Map<RideCategory, DriverEtaResult?> _etaByCategory = {};
  double _distanceInKm = 0;
  double _estimatedDurationInMinutes = 0;
  RideCategory _selectedCategory = RideCategory.any;
  
  // Ride preferences
  RidePreferences? _ridePreferences;

  // User Data
  List<AddressSuggestion> _suggestions = [];
  Timer? _debounce;
  SavedAddress? _homeAddress;
  SavedAddress? _workAddress;
  List<String> _recentDestinations = [];
  

  // NOU: StreamSubscription și Timer pentru a gestiona ETA-ul stabil
  StreamSubscription? _driverLocationSubscription;
  Timer? _etaClearTimer;
  
  // ✅ NOU: Timer pentru auto-start căutare șoferi după selecția categoriei
  Timer? _autoStartTimer;
  
  // ✅ NOU: Helper pentru afișarea statusului cursei
  String _getStatusDisplayName(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'searching':
        return l10n.rideRequestStatusSearching;
      case 'pending':
        return l10n.rideRequestStatusPending;
      case 'driver_found':
        return l10n.rideRequestStatusDriverFound;
      case 'accepted':
        return l10n.rideRequestStatusAccepted;
      case 'arrived':
        return l10n.rideRequestStatusDriverArrived;
      case 'in_progress':
        return l10n.rideRequestStatusInProgress;
      case 'driver_rejected':
        return l10n.rideRequestStatusDriverRejected;
      case 'driver_declined':
        return l10n.rideRequestStatusDriverDeclined;
      default:
        return status;
    }
  }

  @override
  void initState() {
    super.initState();
    _startPoint = Point(
        coordinates:
            Position(widget.startPosition.longitude, widget.startPosition.latitude));
    _getAddressFromPosition(widget.startPosition, _startAddressController);
    _startAddressController.addListener(() => _onAddressChanged(_startAddressController));
    _destinationAddressController.addListener(() => _onAddressChanged(_destinationAddressController));
    _startFocusNode.addListener(_onFocusChange);
    _destinationFocusNode.addListener(_onFocusChange);
    _loadSavedAddresses();
    _loadRidePreferences();
    _loadRecentDestinations();
  }

  Future<void> _loadRecentDestinations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('recent_destinations') ?? [];
      if (mounted) setState(() => _recentDestinations = list);
    } catch (e) {
      Logger.debug('_loadRecentDestinations failed: $e', tag: 'RIDE_REQUEST');
    }
  }

  /// Loads user ride preferences from Firestore
  Future<void> _loadRidePreferences() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data()?['ridePreferences'] != null) {
        setState(() {
          _ridePreferences = RidePreferences.fromMap(
            Map<String, dynamic>.from(doc.data()!['ridePreferences']),
          );
        });
      }
    } catch (e) {
      Logger.error('Error loading ride preferences: $e', error: e);
    }
  }

  @override
  void dispose() {
    _startAddressController.dispose();
    _destinationAddressController.dispose();
    _startFocusNode.dispose();
    _destinationFocusNode.dispose();
    _debounce?.cancel();
    _driverLocationSubscription?.cancel();
    _etaClearTimer?.cancel();
    _autoStartTimer?.cancel();
    super.dispose();
  }
  
  // --- CORE LOGIC ---

  Future<void> _calculateRouteAndEta() async {
    FocusScope.of(context).unfocus();
    if (_startPoint == null || _endPoint == null) return;

    setState(() => _isLoading = true);
    Logger.debug("--- Starting route and ETA calculation ---");

    try {
      final List<Point> waypoints = [_startPoint!, _endPoint!];
      _routeGeoJSON = await _routingService.getRoute(waypoints).timeout(const Duration(seconds: 15));
      if (_routeGeoJSON == null) throw Exception("Routing service failed.");

      _distanceInKm = _routingService.extractDistance(_routeGeoJSON) / 1000;

      final double routeDurationSeconds = _routingService.extractDuration(_routeGeoJSON);
      _estimatedDurationInMinutes = routeDurationSeconds > 0
          ? routeDurationSeconds / 60
          : (_distanceInKm / 40.0) * 60;

      _faresByCategory = {
        for (var category in RideCategory.values)
          category: {
            'baseFare': 0.0,
            'perKmRate': 0.0,
            'perMinRate': 0.0,
            'totalCost': 0.0,
            'appCommission': 0.0,
            'driverEarnings': 0.0,
          },
      };

      await _calculateEtaForAllCategories();
      
      _drawRouteAndMarkers();

      _listenForDriverUpdates();

      Logger.debug("--- Route and ETA calculation successful ---");
    } on TimeoutException {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.rideRequestTimeoutInternet), backgroundColor: Colors.red));
        }
    } catch (e) {
      Logger.error("Error in _calculateRouteAndEta: ${e.toString()}");
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.rideRequestRouteCalcError(e.toString().replaceAll("Exception: ", ""))), backgroundColor: Colors.red));
      }
    } finally {
        if(mounted) {
            setState(() => _isLoading = false);
        }
    }
  }

  void _listenForDriverUpdates() {
    _driverLocationSubscription?.cancel();
    Logger.debug("Pornit ascultătorul pentru locațiile șoferilor ---", tag: 'LIVE ETA');
    _driverLocationSubscription = _firestoreService.getNearbyAvailableDrivers().listen((snapshot) {
      Logger.debug("Detectat update la șoferi. Se recalculează ETA... ---", tag: 'LIVE ETA');
      if (mounted && _faresByCategory.isNotEmpty) {
         _calculateEtaForAllCategories();
      }
    });
  }

  void _stopListeningForDriverUpdates() {
    Logger.debug("Oprit ascultătorul pentru locațiile șoferilor ---", tag: 'LIVE ETA');
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
    _etaClearTimer?.cancel();
  }

  Future<void> _calculateEtaForAllCategories() async {
    if (_startPoint == null) return;
    
    _etaClearTimer?.cancel();

    final etaResults = <RideCategory, DriverEtaResult?>{};
    bool atLeastOneDriverFound = false;

    for (final category in RideCategory.values) {
      try {
        final etaResult = await _firestoreService.getNearestDriverEta(_startPoint!, category);
        etaResults[category] = etaResult;
        if (etaResult != null) {
          atLeastOneDriverFound = true;
        }
      } catch (e) {
        etaResults[category] = null;
      }
    }
    
    if (mounted) {
      if (atLeastOneDriverFound) {
        setState(() => _etaByCategory = etaResults);
      } else {
        Logger.debug("Niciun șofer găsit. Se va șterge ETA în 5 secunde dacă situația persistă.", tag: 'LIVE ETA');
        _etaClearTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            Logger.debug("Timer expirat. Se confirmă ștergerea ETA.", tag: 'LIVE ETA');
            setState(() => _etaByCategory.clear());
          }
        });
      }
    }
  }

  Future<void> _confirmAndRequestRide() async {
    // Anulează auto-start timer dacă utilizatorul apasă manual butonul
    _autoStartTimer?.cancel();
    if (mounted) {
      setState(() {
        _isAutoStarting = true; // Afișează indicator și pentru apăsare manuală
      });
    }
    _stopListeningForDriverUpdates();

    final fareDetails = _faresByCategory[_selectedCategory];
    if (fareDetails == null || _startPoint == null || _endPoint == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.rideRequestUserNotAuthenticated), backgroundColor: Colors.red),
      );
      return;
    }

    final newRide = Ride(
      id: '',
      passengerId: userId,
      startAddress: _startAddressController.text,
      destinationAddress: _destinationAddressController.text,
      distance: _distanceInKm,
      startLatitude: _startPoint!.coordinates.lat.toDouble(),
      startLongitude: _startPoint!.coordinates.lng.toDouble(),
      destinationLatitude: _endPoint!.coordinates.lat.toDouble(),
      destinationLongitude: _endPoint!.coordinates.lng.toDouble(),
      durationInMinutes: _estimatedDurationInMinutes,
      baseFare: fareDetails['baseFare']!,
      perKmRate: fareDetails['perKmRate']!,
      perMinRate: fareDetails['perMinRate']!,
      totalCost: fareDetails['totalCost']!,
      appCommission: fareDetails['appCommission']!,
      driverEarnings: fareDetails['driverEarnings']!,
      timestamp: DateTime.now(),
      status: 'pending',
      category: _selectedCategory,
      stops: [],
      ridePreferences: _ridePreferences,
    );

    String? rideId;
    try {
      rideId = await _firestoreService.requestRide(newRide);
    } on ActiveRideException catch (e) {
      // ✅ FIX: Afișează dialog de confirmare când există o cursă activă
      if (!mounted) {
        setState(() {
          _isLoading = false;
          _isAutoStarting = false;
        });
        return;
      }
      
      // ✅ FIX: Setează _isLoading = false înainte de a afișa dialogul pentru a nu bloca UI-ul
      setState(() {
        _isLoading = false;
        _isAutoStarting = false;
      });
      
      // ✅ FIX: Așteaptă ca UI-ul să fie complet renderat și ca loading indicator-ul să dispară
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) {
        return;
      }
      
      // ✅ FIX: Folosește showGeneralDialog cu root navigator pentru a afișa dialogul deasupra tuturor elementelor
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      final shouldCancel = await showGeneralDialog<bool>(
        context: context,
        barrierColor: Colors.black54,
        barrierLabel: AppLocalizations.of(context)!.activeRide,
        pageBuilder: (context, animation, secondaryAnimation) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.rideRequestActiveRideDetected),
            content: SingleChildScrollView(
              child: Text(
                '${e.message}\n\n'
                '${AppLocalizations.of(context)!.rideRequestStatusLabel}: ${_getStatusDisplayName(e.activeRideStatus)}\n'
                '${AppLocalizations.of(context)!.rideRequestIdLabel}: ${e.activeRideId.length > 8 ? e.activeRideId.substring(0, 8) : e.activeRideId}...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => rootNavigator.pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => rootNavigator.pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: Text(AppLocalizations.of(context)!.rideRequestCancelPreviousRide),
              ),
            ],
          );
        },
      );
      
      if (shouldCancel == true && mounted) {
        // Anulează cursa precedentă și creează una nouă
        try {
          await _firestoreService.cancelRide(e.activeRideId);
          // Reîncearcă crearea cursei
          rideId = await _firestoreService.requestRide(newRide);
        } catch (cancelError) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isAutoStarting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.rideRequestCancelPreviousRideError(cancelError.toString())),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else {
        // Utilizatorul a anulat - nu facem nimic
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isAutoStarting = false;
          });
        }
        return;
      }
    } catch (e) {
      // Alte erori
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isAutoStarting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.rideRequestCreateRideError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // După catch, rideId este garantat să fie setat dacă nu s-a făcut return
    final finalRideId = rideId;

    // Save destination to recent history (max 10 entries)
    try {
      final prefs = await SharedPreferences.getInstance();
      final dest = _destinationAddressController.text.trim();
      if (dest.isNotEmpty) {
        final raw = prefs.getStringList('recent_destinations') ?? [];
        final updated = [dest, ...raw.where((d) => d != dest)].take(10).toList();
        await prefs.setStringList('recent_destinations', updated);
      }
    } catch (e) {
      Logger.debug('_saveRecentDestination failed: $e', tag: 'RIDE_REQUEST');
    }
    
    // Ride sharing disabled for Nabour

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SearchingForDriverScreen(rideId: finalRideId)),
    );
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(_faresByCategory.isEmpty ? l10n.rideRequestWhereTo : l10n.rideRequestChooseRide),
        leading: _faresByCategory.isNotEmpty ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _resetToAddressInput,
        ) : null,
      ),
      body: Stack(
        children: [
          MapWidget(
            onMapCreated: _onMapCreated,
            cameraOptions: CameraOptions(
                              center: _startPoint != null ? _startPoint! : MapboxUtils.createPoint(widget.startPosition.latitude, widget.startPosition.longitude),
              zoom: 12.0
            ),
            styleUri: NabourMapStyles.uriForMainMap(
              lowDataMode: false,
              darkMode: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          
          _buildSlidingPanel(),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSlidingPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        elevation: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _faresByCategory.isEmpty
                  ? _buildAddressInputForm()
                  : _buildCategorySelection(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressInputForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddressInput(
            controller: _startAddressController,
            focusNode: _startFocusNode,
            labelText: 'Start location',
          ),
          const SizedBox(height: 12),
          _buildAddressInput(
            controller: _destinationAddressController,
            focusNode: _destinationFocusNode,
            labelText: 'Destination',
          ),
          const SizedBox(height: 12),
          if (_isShowingSuggestions)
            _buildSuggestionsList()
          else
            _buildQuickAddressButtons(),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildRideDetail(Icons.access_time, '${_estimatedDurationInMinutes.round()} min', 'Duration'),
            Container(height: 40, width: 1, color: Colors.grey.shade300),
            _buildRideDetail(Icons.route, '${_distanceInKm.toStringAsFixed(1)} km', 'Distance'),
          ],
        ),
        const Divider(height: 24),
        _buildAnyCategoryButton(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(l10n.rideRequestOrChooseCategory, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 8),
        ...[RideCategory.standard, RideCategory.family, RideCategory.energy, RideCategory.best, RideCategory.utility]
            .map((category) => _buildPremiumCategoryCard(category)),
        
        // Ride sharing disabled for Nabour free model

        const SizedBox(height: 16),
        // ✅ NOU: Mesaj pentru auto-start
        if (_isAutoStarting)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.searchDriverSearchingTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmAndRequestRide,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            child: Text(
              _isAutoStarting ? l10n.rideRequestSearchInProgress : l10n.rideRequestConfirmAndRequest,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideDetail(IconData icon, String value, String label) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAnyCategoryButton() {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedCategory == RideCategory.any;
    return GestureDetector(
      onTap: () => _onCategorySelected(RideCategory.any),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car_filled,
                color: isSelected ? Colors.white : const Color(0xFF7C3AED), size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.rideRequestAnyCategoryAvailable,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    l10n.rideRequestFastestDriverInArea,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCategoryCard(RideCategory category) {
    final fare = _faresByCategory[category];
    if (fare == null) return const SizedBox.shrink();
    
    final etaResult = _etaByCategory[category];
    String? estimatedTime;
    
    if (etaResult != null) {
      // Format: "~5 min • 2.3 km" (ETA și distanță)
      estimatedTime = '~${etaResult.durationInMinutes} min • ${_distanceInKm.toStringAsFixed(1)} km';
    } else if (_distanceInKm > 0) {
      // Dacă nu avem ETA dar avem distanță, afișăm doar distanța
      estimatedTime = '${_distanceInKm.toStringAsFixed(1)} km';
    }
    
    // Determină dacă este recomandat (Standard este recomandat implicit)
    final isRecommended = category == RideCategory.standard;
    
    return PremiumCategoryCard(
      category: category,
      icon: _getCategoryIcon(category),
      title: category.name[0].toUpperCase() + category.name.substring(1),
      subtitle: _getCategorySubtitle(category),
      fareDetails: fare,
      isSelected: category == _selectedCategory,
      onTap: () => _onCategorySelected(category),
      estimatedTime: estimatedTime,
      isRecommended: isRecommended,
    );
  }
  
  // ✅ NOU: Handler pentru selecția categoriei cu auto-start
  void _onCategorySelected(RideCategory category) {
    // Anulează timer-ul anterior dacă există
    _autoStartTimer?.cancel();
    
    setState(() {
      _selectedCategory = category;
      _isAutoStarting = false; // Reset indicator
    });
    
    // ✅ Auto-start căutare șoferi după 2.5 secunde (comportament Uber/Bolt)
    _autoStartTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _faresByCategory.isNotEmpty && _startPoint != null && _endPoint != null) {
        Logger.debug('Căutare șoferi declanșată automat pentru categoria: ${category.name}', tag: 'AUTO-START');
        setState(() {
          _isAutoStarting = true; // Afișează indicator
        });
        _confirmAndRequestRide();
      }
    });
  }

  Widget _buildSuggestionsList() {
    if (!_isShowingSuggestions || _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(suggestion.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => _onSuggestionSelected(suggestion),
          );
        },
      ),
    );
  }

  // --- HELPER METHODS & WIDGETS ---

  void _resetToAddressInput() {
    _stopListeningForDriverUpdates();

    setState(() {
      _faresByCategory.clear();
      _etaByCategory.clear();
      _routeGeoJSON = null;
      _destinationAddressController.clear();
      _endPoint = null;
      _mapboxMap?.style.removeStyleLayer("route-layer");
      _mapboxMap?.style.removeStyleSource("route-source");
      _pointAnnotationManager?.deleteAll();
      _addStartMarker();
    });
  }
  
  void _onFocusChange() {
    setState(() {
      _isShowingSuggestions = _startFocusNode.hasFocus || _destinationFocusNode.hasFocus;
    });
  }

  void _onAddressChanged(TextEditingController controller) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (controller.text.length < 3) {
      if (mounted) {
        setState(() => _suggestions = []);
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      final results = await _geocodingService.fetchSuggestions(controller.text, widget.startPosition);
      if (mounted) {
        setState(() => _suggestions = results);
      }
    });
  }

  // FUNCȚIA MODIFICATĂ - returnează datele când se selectează destinația
  Future<void> _onSuggestionSelected(AddressSuggestion suggestion) async {
    final focusScope = FocusScope.of(context);
    final List<Location> locations = await locationFromAddress(suggestion.description);
    
    if (!mounted || locations.isEmpty) return;

            final selectedPoint = MapboxUtils.createPoint(locations.first.latitude, locations.first.longitude);

    if (_startFocusNode.hasFocus) {
      // Logica pentru punctul de start rămâne neschimbată
      setState(() {
        _startAddressController.text = suggestion.description;
        _startPoint = selectedPoint;
        _suggestions = [];
        _isShowingSuggestions = false;
      });
      
      focusScope.unfocus();
    } else if (_destinationFocusNode.hasFocus) {
      // Pentru destinație, returnează datele către map_screen.dart
      final result = {
        'point': selectedPoint,
        'address': suggestion.description,
      };

      // Închide ecranul și returnează rezultatul
      Navigator.of(context).pop(result);
      return; // Ieși din funcție pentru a nu continua cu logica de mai jos
    }

    // Logica existentă pentru când ambele puncte sunt setate
    if (_startPoint != null && _endPoint != null) {
      _calculateRouteAndEta();
    }
  }

  Future<void> _getAddressFromPosition(geolocator.Position position, TextEditingController controller) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (mounted && placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
        controller.text = "${place.street ?? ''}, ${place.locality ?? ''}".replaceAll(RegExp(r'^, |, $'), '');
      }
    } catch (e) {
      if (mounted) {
        controller.text = "Could not get current address";
      }
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointAnnotationManager = await _mapboxMap?.annotations.createPointAnnotationManager(id: "markers-manager");
    _addStartMarker();
  }

  void _addStartMarker() async {
    if (_startPoint == null) return;
    final ByteData startIconBytes = await rootBundle.load("assets/images/passenger_icon.png");
    _pointAnnotationManager?.create(PointAnnotationOptions(
              geometry: _startPoint!,
      image: startIconBytes.buffer.asUint8List(),
      iconSize: 0.15,
      iconAnchor: IconAnchor.BOTTOM,
    ));
  }

  Future<void> _drawRouteAndMarkers() async {
    if (_mapboxMap == null) return;

    try {
      await _mapboxMap?.style.removeStyleLayer("route-layer");
      await _mapboxMap?.style.removeStyleSource("route-source");
    } catch (e) { /* Ignore if not found */ }
    _pointAnnotationManager?.deleteAll();

    if (_routeGeoJSON != null) {
      final routeGeometry = _routeGeoJSON!['routes'][0]['geometry'];
      await _mapboxMap?.style.addSource(GeoJsonSource(id: 'route-source', data: json.encode(routeGeometry)));
      await _mapboxMap?.style.addLayer(LineLayer(
          id: 'route-layer',
          sourceId: 'route-source',
          lineColor: Colors.blue.toARGB32(),
          lineWidth: 6.0,
          lineOpacity: 0.8));
    }

    final ByteData startIconBytes = await rootBundle.load("assets/images/passenger_icon.png");
    final ByteData endIconBytes = await rootBundle.load("assets/images/pin_icon.png");
    final markers = <PointAnnotationOptions>[];
    if (_startPoint != null) {
              markers.add(PointAnnotationOptions(geometry: _startPoint!, image: startIconBytes.buffer.asUint8List(), iconSize: 0.15, iconAnchor: IconAnchor.BOTTOM));
    }
    if (_endPoint != null) {
              markers.add(PointAnnotationOptions(geometry: _endPoint!, image: endIconBytes.buffer.asUint8List(), iconSize: 0.3, iconAnchor: IconAnchor.BOTTOM));
    }
    if (markers.isNotEmpty) {
      _pointAnnotationManager?.createMulti(markers);
    }

    if (_startPoint != null && _endPoint != null) {
      final centerLat = (_startPoint!.coordinates.lat + _endPoint!.coordinates.lat) / 2;
      final centerLng = (_startPoint!.coordinates.lng + _endPoint!.coordinates.lng) / 2;
              final centerPoint = MapboxUtils.createPoint(centerLat, centerLng);

      final distance = geolocator.Geolocator.distanceBetween(
        _startPoint!.coordinates.lat.toDouble(),
        _startPoint!.coordinates.lng.toDouble(),
        _endPoint!.coordinates.lat.toDouble(),
        _endPoint!.coordinates.lng.toDouble(),
      );

      double zoom = 14;
      if (distance > 1000) {
        zoom = 14 - (log(distance / 1000) / log(2));
      }
      zoom = max(zoom, 4.0);

      _mapboxMap?.flyTo(
        CameraOptions(
          center: centerPoint,
          zoom: zoom,
          padding: MbxEdgeInsets(top: 100, left: 50, bottom: 350, right: 50),
        ),
        MapAnimationOptions(duration: 1500),
      );
    }
  }
  
  // FUNCȚIA MODIFICATĂ - returnează datele pentru adresele salvate
  void _setDestinationFromSavedAddress(SavedAddress address) {
            final selectedPoint = MapboxUtils.createPoint(address.coordinates.latitude, address.coordinates.longitude);
    
    // Creează rezultatul pentru a-l returna
    final result = {
      'point': selectedPoint,
      'address': address.address,
    };

    // Închide ecranul și returnează rezultatul
    Navigator.of(context).pop(result);
  }

  Widget _buildAddressInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).canvasColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: IconButton(
          icon: const Icon(Icons.map_outlined, color: Colors.blue),
          tooltip: 'Choose on map',
          onPressed: () async {
            final result = await Navigator.of(context).push<Map<String, dynamic>>(
              MaterialPageRoute(builder: (ctx) => MapPickerScreen(initialLocation: widget.startPosition)),
            );
            if (result != null && result.containsKey('location')) {
              final newPoint = result['location'] as Point;
              final newAddress = result['address'] as String;
              
              if (focusNode == _startFocusNode) {
                // Pentru start location, setează local
                setState(() {
                  _startAddressController.text = newAddress;
                  _startPoint = newPoint;
                });
              } else {
                // Pentru destination, returnează datele
                final destinationResult = {
                  'point': newPoint,
                  'address': newAddress,
                };
                if (mounted) {
  Navigator.of(context).pop(destinationResult);
}
              }
            }
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required.';
        }
        return null;
      },
    );
  }
  
  Widget _buildQuickAddressButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_homeAddress != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                avatar: const Icon(Icons.home, size: 18),
                label: const Text('Home'),
                onPressed: () => _setDestinationFromSavedAddress(_homeAddress!),
              ),
            ),
          if (_workAddress != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                avatar: const Icon(Icons.work, size: 18),
                label: const Text('Work'),
                onPressed: () => _setDestinationFromSavedAddress(_workAddress!),
              ),
            ),
          // Recent destinations
          ..._recentDestinations.take(5).map((dest) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: const Icon(Icons.history, size: 18),
                  label: Text(
                    dest.length > 25 ? '${dest.substring(0, 22)}…' : dest,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () {
                    _destinationAddressController.text = dest;
                    _onAddressChanged(_destinationAddressController);
                  },
                ),
              )),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(RideCategory category) {
    switch (category) {
      case RideCategory.any:
        return Icons.directions_car_filled;
      case RideCategory.standard:
        return Icons.drive_eta;
      case RideCategory.family:
        return Icons.family_restroom_rounded;
      case RideCategory.energy:
        return Icons.electric_car;
      case RideCategory.best:
        return Icons.star;
      case RideCategory.utility:
        return Icons.local_shipping;
    }
  }

  String _getCategorySubtitle(RideCategory category) {
    switch (category) {
      case RideCategory.any:
        return AppLocalizations.of(context)!.rideRequestAnyCategorySubtitle;
      case RideCategory.standard:
        return "Cel mai accesibil mod de transport.";
      case RideCategory.family:
        return AppLocalizations.of(context)!.rideRequestFamilySubtitle;
      case RideCategory.energy:
        return AppLocalizations.of(context)!.rideRequestEnergySubtitle;
      case RideCategory.best:
        return "Confort premium garantat.";
      case RideCategory.utility:
        return AppLocalizations.of(context)!.rideRequestUtilitySubtitle;
    }
  }
  
  // --- DATA LOADING ---
  void _loadSavedAddresses() {
    _firestoreService.getSavedAddresses().listen((addresses) {
      if (mounted) {
        setState(() {
          try {
            _homeAddress =
                addresses.firstWhere((addr) => addr.isHomeCategory);
          } catch (e) {
            _homeAddress = null;
          }
          try {
            _workAddress =
                addresses.firstWhere((addr) => addr.isWorkCategory);
          } catch (e) {
            _workAddress = null;
          }
        });
      }
    });
  }
}