// lib/widgets/ride_request_panel.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/models/stop_location.dart';
import 'package:nabour_app/screens/searching_for_driver_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/passenger_allowed_driver_uids.dart';
// PricingService removal handled in imports (none used anymore)
import 'package:nabour_app/services/routing_service.dart';
import 'package:nabour_app/widgets/address_input_view.dart';
import 'package:nabour_app/widgets/ride_confirmation_view.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/utils/logger.dart';

enum PanelState { addressInput, destinationPreview, rideConfirmation }

class RideRequestPanel extends StatefulWidget {
  final geolocator.Position startPosition;
  final Function(Map<String, dynamic>?) onRouteCalculated;
  final void Function(Point destPoint, String destAddress)? onDestinationPreview;
  final void Function(Point destPoint, String destAddress)? onStartNavigation;
  final bool isNavigating;
  /// Opțional: control din [MapScreen] pentru a deschide/închide sheet-ul (buton în bara de jos).
  final DraggableScrollableController? draggableController;
  /// Închide complet cardul (ascuns de pe hartă până la următoarea deschidere).
  final VoidCallback onClose;

  const RideRequestPanel({
    super.key,
    required this.startPosition,
    required this.onRouteCalculated,
    this.onDestinationPreview,
    this.onStartNavigation,
    this.isNavigating = false,
    this.draggableController,
    required this.onClose,
  });

  @override
  State<RideRequestPanel> createState() => RideRequestPanelState();
}

class RideRequestPanelState extends State<RideRequestPanel> {
  PanelState _panelState = PanelState.addressInput;
  bool _isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();
  // final PricingService _pricingService = PricingService(); // Eliminat - Nabour free model
  final RoutingService _routingService = RoutingService();
  // final EtaService _etaService = EtaService(); // Eliminat

  Point? _startPoint;
  Point? _endPoint;
  String _startAddress = '';
  String _destinationAddress = '';

  // Preview destinație (înainte de confirmare)
  Point? _previewPoint;
  String _previewAddress = '';

  // ADĂUGAT: Variabile pentru opriri multiple
  final List<StopLocation> _stops = <StopLocation>[];
  
  Map<RideCategory, Map<String, double>> _faresByCategory = {};
  Map<RideCategory, DriverEtaResult?> _etaByCategory = {};
  double _distanceInKm = 0;
  double _estimatedDurationInMinutes = 0;
  RideCategory _selectedCategory = RideCategory.standard;

  StreamSubscription? _driverLocationSubscription;

  @override
  void initState() {
    super.initState();
    _startPoint = Point(coordinates: Position(widget.startPosition.longitude, widget.startPosition.latitude));
  }

  @override
  void didUpdateWidget(RideRequestPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isNavigating != widget.isNavigating) {
      _scheduleSheetExtentSync();
    }
  }

  /// Înălțime țintă pentru [DraggableScrollableSheet] (trebuie să rămână în min/max configurate la build).
  double _targetExtentForState() {
    if (widget.isNavigating) return 0.15;
    switch (_panelState) {
      case PanelState.destinationPreview:
        return 0.24;
      case PanelState.rideConfirmation:
        return 0.55;
      case PanelState.addressInput:
        return 0.48;
    }
  }

  /// După schimbarea pasului (preview → confirmare etc.), ajustăm sheet-ul fără a recrea widget-ul
  /// (evită: „Draggable scrollable controller is already attached to a sheet”).
  void _scheduleSheetExtentSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = widget.draggableController;
      if (c == null || !c.isAttached) return;
      final target = _targetExtentForState();
      unawaited(
        c.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    super.dispose();
  }

  // ADĂUGAT: Metodă publică pentru resetarea panelului
  void resetPanel() {
    if (!mounted) return;

    Logger.debug('RideRequestPanel: Resetting panel state');

    setState(() {
      _panelState = PanelState.addressInput;
      _isLoading = false;
      _endPoint = null;
      _previewPoint = null;
      _previewAddress = '';
      _startAddress = '';
      _destinationAddress = '';
      _stops.clear(); // Resetăm opririle
      _faresByCategory.clear();
      _etaByCategory.clear();
      _distanceInKm = 0;
      _estimatedDurationInMinutes = 0;
      _selectedCategory = RideCategory.standard;
    });

    _driverLocationSubscription?.cancel();

    // Curățăm ruta din MapScreen
    widget.onRouteCalculated(null);

    Logger.info('RideRequestPanel: Reset completed');
    _scheduleSheetExtentSync();
  }

  /// Apelat de AddressInputView când userul selectează o destinație din sugestii.
  /// Comută la starea de preview fără a calcula ruta.
  void _handleDestinationPreview(
    Point startPoint,
    Point endPoint,
    String startAddress,
    String destAddress,
  ) {
    if (!mounted) return;
    setState(() {
      _startPoint = startPoint;
      _previewPoint = endPoint;
      _previewAddress = destAddress;
      _startAddress = startAddress;
      _panelState = PanelState.destinationPreview;
    });
    _scheduleSheetExtentSync();
    // Notifică MapScreen să zboare camera și să arate pin-ul
    widget.onDestinationPreview?.call(endPoint, destAddress);
    Logger.info('RideRequestPanel: destination preview → $destAddress');
  }

  /// Apelat din MapScreen când userul tapează pe hartă în modul preview
  /// pentru a repoziționa pin-ul destinației.
  void updatePreviewDestination(Point point, String address) {
    if (!mounted || _panelState != PanelState.destinationPreview) return;
    setState(() {
      _previewPoint = point;
      _previewAddress = address;
    });
    Logger.debug('RideRequestPanel: preview destination updated → $address');
  }

  /// Confirmă destinația din preview și trece la calculul rutei.
  void _confirmPreviewDestination() {
    final sp = _startPoint;
    final ep = _previewPoint;
    if (sp == null || ep == null) return;
    _onDestinationSelected(sp, ep, _startAddress, _previewAddress);
  }

  // ✅ NOU: Metodă pentru setarea destinației din exterior (POI selection)
  void setDestination({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    Logger.info('RideRequestPanel: Setting destination from POI: $address');
    Logger.info('RideRequestPanel: Destination coordinates: $latitude, $longitude');
    
    if (!mounted) {
      Logger.error('RideRequestPanel: Cannot set destination - widget not mounted');
      return;
    }
    
    try {
      setState(() {
        _destinationAddress = address;
        _endPoint = Point(coordinates: Position(longitude, latitude));
        Logger.info('RideRequestPanel: Destination state updated successfully');
      });
      
      // Recalculează ruta dacă ai și pickup
      if (_startPoint != null) {
        Logger.info('RideRequestPanel: Recalculating route with new destination...');
        _onDestinationSelected(_startPoint!, _endPoint!, _startAddress, _destinationAddress);
      } else {
        Logger.info('RideRequestPanel: No pickup point yet - waiting for pickup');
      }
      
      Logger.info('RideRequestPanel: Destination set successfully');
      
    } catch (e) {
      Logger.error('RideRequestPanel: Error setting destination: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
    }
  }
  
  // ✅ NOU: Metodă pentru setarea pickup-ului din exterior (POI selection)
  void setPickup({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    Logger.info('RideRequestPanel: Setting pickup from POI: $address');
    Logger.info('RideRequestPanel: Pickup coordinates: $latitude, $longitude');
    
    if (!mounted) {
      Logger.error('RideRequestPanel: Cannot set pickup - widget not mounted');
      return;
    }
    
    try {
      setState(() {
        _startAddress = address;
        _startPoint = Point(coordinates: Position(longitude, latitude));
        Logger.info('RideRequestPanel: Pickup state updated successfully');
      });
      
      // Recalculează ruta dacă ai și destinația
      if (_endPoint != null) {
        Logger.info('RideRequestPanel: Recalculating route with new pickup...');
        _onDestinationSelected(_startPoint!, _endPoint!, _startAddress, _destinationAddress);
      } else {
        Logger.info('RideRequestPanel: No destination yet - waiting for destination');
      }
      
      Logger.info('RideRequestPanel: Pickup set successfully');
      
    } catch (e) {
      Logger.error('RideRequestPanel: Error setting pickup: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
    }
  }

  /// Confirma adresele programatic (apelat de asistentul vocal).
  /// Echivalent cu apasarea butonului "Confirma" de catre user.
  void confirmAddressesVoice() {
    if (!mounted) return;
    final sp = _startPoint;
    final ep = _endPoint;
    if (sp == null || ep == null) {
      Logger.warning('confirmAddressesVoice: startPoint or endPoint is null', tag: 'RIDE_PANEL');
      return;
    }
    Logger.info('confirmAddressesVoice: triggering destination selection', tag: 'RIDE_PANEL');
    _onDestinationSelected(sp, ep, _startAddress, _destinationAddress);
  }

  // ✅ ÎMBUNĂTĂȚIT: Metoda addStop cu validare completă
  void addStop(StopLocation stop) {
    // ✅ VALIDARE NUMĂR MAXIM OPRIRI
    if (_stops.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poți adăuga maximum 5 opriri'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // ✅ VALIDARE DISTANȚĂ ÎNTRE OPRIRI
    if (_stops.isNotEmpty) {
      final lastStop = _stops.last;
      final distance = _calculateDistanceBetweenStops(lastStop, stop);
      if (distance < 0.1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opririle trebuie să fie la cel puțin 100m distanță'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    setState(() {
      _stops.add(stop);
    });
    
    Logger.info('Added stop: ${stop.address}. Total stops: ${_stops.length}');
    
    // Recalculăm ruta doar dacă avem și destinația setată
    if (_endPoint != null) {
      _recalculateRouteWithStops();
    }
  }
  
  // ✅ NOU: Calculează distanța între două opriri
  double _calculateDistanceBetweenStops(StopLocation stop1, StopLocation stop2) {
    const double earthRadius = 6371; // km
    final lat1 = stop1.latitude * (math.pi / 180);
    final lat2 = stop2.latitude * (math.pi / 180);
    final deltaLat = (stop2.latitude - stop1.latitude) * (math.pi / 180);
    final deltaLng = (stop2.longitude - stop1.longitude) * (math.pi / 180);
    
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  // ADĂUGAT: Metoda removeStop să recalculeze ruta
  void removeStop(int index) {
    if (index >= 0 && index < _stops.length) {
      final removedStop = _stops[index];
      setState(() {
        _stops.removeAt(index);
      });
      
      Logger.debug('Removed stop: ${removedStop.address}. Remaining stops: ${_stops.length}');
      
      // Recalculăm ruta doar dacă avem destinația
      if (_endPoint != null) {
        if (_stops.isEmpty) {
          // Dacă nu mai avem opriri, calculăm ruta simplă
          _onDestinationSelected(_startPoint!, _endPoint!, _startAddress, _destinationAddress);
        } else {
          // Altfel recalculăm cu opririle rămase
          _recalculateRouteWithStops();
        }
      }
    }
  }

  // ADĂUGAT: Metodă pentru recalcularea rutei cu opriri
  Future<void> _recalculateRouteWithStops() async {
    if (_startPoint == null || _endPoint == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Construim lista de waypoints: start -> opriri -> destinație
      final List<Point> waypoints = [_startPoint!];
      
      // Adăugăm opririle în ordinea corectă
      for (var stop in _stops) {
        waypoints.add(Point(coordinates: Position(stop.longitude, stop.latitude)));
        Logger.debug('Added stop waypoint: ${stop.address} at ${stop.latitude}, ${stop.longitude}');
      }
      
      // Adăugăm destinația
      waypoints.add(_endPoint!);
      
      Logger.debug('Recalculating route with ${waypoints.length} waypoints (${_stops.length} stops)');
      
      final routeData = await _routingService.getRoute(waypoints);
      if (!mounted) return;
      if (routeData == null) throw Exception("Nu s-a putut calcula ruta cu opriri.");

      // IMPORTANT: Trimitem ruta actualizată către MapScreen
      widget.onRouteCalculated(routeData);

      _distanceInKm = _routingService.extractDistance(routeData) / 1000;
      
      // CORECTAT: Folosim o viteză medie constantă
      const double averageSpeed = 40.0; // Viteza medie in km/h
      _estimatedDurationInMinutes = (_distanceInKm / averageSpeed) * 60;

      // Recalculăm tarifele incluzând taxa pentru opriri
      _faresByCategory = {
        for (var category in RideCategory.values)
          category: {
            'totalCost': 0.0,
            'baseFare': 0.0,
            'perKmRate': 0.0,
            'perMinRate': 0.0,
            'appCommission': 0.0,
            'driverEarnings': 0.0,
          },
      };

      await _calculateEtaForAllCategories();
      
      Logger.info('Route recalculated successfully with ${_stops.length} stops');
      
    } catch (e) {
      Logger.error('Error recalculating route with stops: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la recalcularea rutei: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onDestinationSelected(Point startPoint, Point endPoint, String startAddress, String destAddress) async {
    setState(() {
      _isLoading = true;
      _startPoint = startPoint;
      _endPoint = endPoint;
      _startAddress = startAddress;
      _destinationAddress = destAddress;
    });

    // ✅ FEEDBACK PENTRU UTILIZATOR
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se calculează ruta...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      // Construim waypoints incluzând opririle dacă există
      final List<Point> waypoints = [startPoint];
      
      // Adăugăm opririle existente
      for (var stop in _stops) {
        waypoints.add(Point(coordinates: Position(stop.longitude, stop.latitude)));
        Logger.debug('Including existing stop: ${stop.address}');
      }
      
      waypoints.add(endPoint);
      
      Logger.debug('Calculating route with ${waypoints.length} waypoints including ${_stops.length} stops');
      
      final routeData = await _routingService.getRoute(waypoints);
      if (!mounted) return;
      if (routeData == null) throw Exception("Nu s-a putut calcula ruta.");

      widget.onRouteCalculated(routeData);

      _distanceInKm = _routingService.extractDistance(routeData) / 1000;
      
      // CORECTAT: Folosim o viteză medie constantă
      const double averageSpeed = 40.0; // Viteza medie in km/h
      _estimatedDurationInMinutes = (_distanceInKm / averageSpeed) * 60;

      // MODIFICAT: Calculăm tarifele incluzând opririle
      _faresByCategory = {
        for (var category in RideCategory.values)
          category: {
            'totalCost': 0.0,
            'baseFare': 0.0,
            'perKmRate': 0.0,
            'perMinRate': 0.0,
            'appCommission': 0.0,
            'driverEarnings': 0.0,
          },
      };

      await _calculateEtaForAllCategories();
      if (!mounted) return;

      setState(() {
        _panelState = PanelState.rideConfirmation;
        _isLoading = false;
      });
      _scheduleSheetExtentSync();
      _listenForDriverUpdates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
      }
    }
  }
  
  Future<void> _calculateEtaForAllCategories() async {
    if (_startPoint == null) return;
    final results = <RideCategory, DriverEtaResult?>{};
    for (final category in RideCategory.values) {
        results[category] = await _firestoreService.getNearestDriverEta(_startPoint!, category);
    }
    if(mounted) {
        setState(() { _etaByCategory = results; });
    }
  }

  void _listenForDriverUpdates() {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = _firestoreService.getNearbyAvailableDrivers().listen((snapshot) {
      if (mounted && _panelState == PanelState.rideConfirmation) {
         _calculateEtaForAllCategories();
      }
    });
  }

  Future<void> _confirmAndRequestRide() async {
    final fareDetails = _faresByCategory[_selectedCategory];
    if (fareDetails == null || _startPoint == null || _endPoint == null) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // ✅ VALIDARE DISTANȚĂ MINIMĂ/MAXIMĂ
    if (_distanceInKm < 0.1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distanța este prea mică. Distanța minimă este 100 metri.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_distanceInKm > 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distanța este prea mare. Distanța maximă este 200 km.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    Logger.info('Creating ride for user: $userId with ${_stops.length} stops', tag: 'RIDE');
    setState(() { _isLoading = true; });

    final allowedDriverUids = await PassengerAllowedDriverUids.loadMergedUidList();
    if (allowedDriverUids.isEmpty) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Nabour trimite cererea doar către șoferii din contactele tale. '
              'Adaugă în agendă numerele prietenilor cu cont Nabour sau acordă permisiunea la contacte.',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
      return;
    }
    
    final ride = Ride(
      id: '', // Va fi generat de Firestore
      passengerId: userId,  // ✅ MODIFICAT: userId → passengerId
      startAddress: _startAddress,
      destinationAddress: _destinationAddress,
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
      allowedDriverUids: allowedDriverUids,
      // ADĂUGAT: Includem opririle în ride
      stops: _stops.map((stop) => stop.toMap()).toList(),
    );

    // ADĂUGAT: Debug pentru a verifica opririle
    Logger.info('Ride stops: ${ride.stops}', tag: 'RIDE');

    Logger.info('Calling requestRide...', tag: 'RIDE');
    String rideId;
    try {
      rideId = await _firestoreService.requestRide(ride);
    } on ActiveRideException catch (e) {
      if (!mounted) { setState(() { _isLoading = false; }); return; }
      setState(() { _isLoading = false; });
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final rootNavigator = Navigator.of(context, rootNavigator: true);
      final shouldCancel = await showGeneralDialog<bool>(
        context: context,
        barrierColor: Colors.black54,
        barrierLabel: 'Cursă activă',
        pageBuilder: (ctx, _, __) => AlertDialog(
          title: const Text('Cursă activă detectată'),
          content: Text(
            '${e.message}\n\nStatus: ${e.activeRideStatus}',
          ),
          actions: [
            TextButton(
              onPressed: () => rootNavigator.pop(false),
              child: const Text('Renunță'),
            ),
            ElevatedButton(
              onPressed: () => rootNavigator.pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Anulează cursa precedentă'),
            ),
          ],
        ),
      );

      if (shouldCancel != true || !mounted) return;
      setState(() { _isLoading = true; });
      try {
        await _firestoreService.cancelRide(e.activeRideId);
        rideId = await _firestoreService.requestRide(ride);
      } catch (cancelError) {
        if (!mounted) return;
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Eroare la anularea cursei precedente: $cancelError'),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }

    Logger.info('Ride created with ID: $rideId', tag: 'RIDE');
    if (!mounted) return;

    setState(() { _isLoading = false; });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SearchingForDriverScreen(rideId: rideId)),
    );
  }
  
  void _resetToAddressInput() {
    _driverLocationSubscription?.cancel();
    widget.onRouteCalculated(null);
    setState(() {
      _panelState = PanelState.addressInput;
      _faresByCategory.clear();
      _etaByCategory.clear();
      // Nu resetăm opririle când ne întoarcem la address input
      // Utilizatorul poate să-și păstreze opririle și să schimbe doar destinația
    });
    _scheduleSheetExtentSync();
  }

  Widget _buildDestinationPreviewPanel(ScrollController scrollController) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('destinationPreview'),
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Confirmă destinația',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ține apăsat pe hartă pentru a muta pin-ul.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_pin, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _previewAddress.isNotEmpty ? _previewAddress : 'Adresă selectată',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('Schimbă'),
                    onPressed: () {
                      setState(() {
                        _panelState = PanelState.addressInput;
                        _previewPoint = null;
                        _previewAddress = '';
                      });
                      _scheduleSheetExtentSync();
                      // Curăță pin-ul de preview din hartă
                      widget.onRouteCalculated(null);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Confirmă destinația'),
                    onPressed: _previewPoint != null ? _confirmPreviewDestination : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Navighează direct către punct (Fără Cursă)'),
                onPressed: _previewPoint != null ? () {
                  widget.onStartNavigation?.call(_previewPoint!, _previewAddress);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNavigating = widget.isNavigating;
    final isPreview = _panelState == PanelState.destinationPreview;
    final isConfirm = _panelState == PanelState.rideConfirmation;
    // Nu folosi Key care depinde de _panelState: reconstruiește sheet-ul și poate reaplica
    // același [DraggableScrollableController] înainte ca instanța veche să se detașeze → assert.
    return DraggableScrollableSheet(
      controller: widget.draggableController,
      initialChildSize: isNavigating ? 0.15 : (isPreview ? 0.24 : (isConfirm ? 0.55 : 0.48)),
      minChildSize: isNavigating ? 0.15 : (isPreview ? 0.18 : (isConfirm ? 0.42 : 0.15)),
      maxChildSize: 0.92, // ✅ FIX: Permitem mereu expandarea panoului pană la 92% din ecran
      builder: (BuildContext context, ScrollController scrollController) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withAlpha(235)
                : Colors.white.withAlpha(250),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.15).round()),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _panelState == PanelState.addressInput
                      ? AddressInputView(
                          key: const ValueKey('addressInput'),
                          scrollController: scrollController,
                          startPosition: widget.startPosition,
                          onDestinationSelected: _onDestinationSelected,
                          onDestinationPreview: _handleDestinationPreview,
                          stops: _stops,
                          onStopAdded: addStop,
                          onStopRemoved: removeStop,
                        )
                      : _panelState == PanelState.destinationPreview
                          ? _buildDestinationPreviewPanel(scrollController)
                          : RideConfirmationView(
                          key: const ValueKey('rideConfirm'),
                          scrollController: scrollController,
                          fares: _faresByCategory,
                          etas: _etaByCategory,
                          distance: _distanceInKm,
                          duration: _estimatedDurationInMinutes,
                          selectedCategory: _selectedCategory,
                          onCategorySelected: (category) { 
                            if(mounted) { 
                              setState(() { 
                                _selectedCategory = category; 
                              });
                            }
                          },
                          onConfirm: _confirmAndRequestRide,
                          onBack: _resetToAddressInput,
                          stops: _stops,
                        ),
                ),
                if (_isLoading)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                if (!widget.isNavigating)
                  Positioned(
                    top: 6,
                    right: 4,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        tooltip: 'Închide',
                        icon: const Icon(Icons.close_rounded),
                        color: isDark ? Colors.white70 : Colors.black87,
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        onPressed: widget.onClose,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}