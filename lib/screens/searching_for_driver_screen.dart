import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Visibility;
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/route_preview_cap_svc.dart';
import 'package:nabour_app/screens/map_screen.dart';
import 'package:nabour_app/services/passenger_ride_session_bus.dart'; 
import 'package:nabour_app/config/nabour_map_styles.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/utils/driver_icon_helper.dart';
import 'package:nabour_app/core/skeletons/skeleton_driver_search.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import '../utils/mapbox_utils.dart';

class SearchingForDriverScreen extends StatefulWidget {
  final String rideId;

  const SearchingForDriverScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<SearchingForDriverScreen> createState() => _SearchingForDriverScreenState();
}

class _SearchingForDriverScreenState extends State<SearchingForDriverScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<Ride>? _rideSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _driverLocationSubscription;
  Timer? _searchTimeoutTimer;
  Timer? _confirmationTimeoutTimer;
  Timer? _countdownTicker;
  int _searchSecondsElapsed = 0;
  static const int _searchTimeoutSeconds = 60;

  // Map preview (Uber/Bolt-like)
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _markersManager;
  PointAnnotation? _pickupAnnotation;
  PointAnnotation? _driverAnnotation;
  Point? _pickupPoint;
  Point? _lastDriverPoint;
  double? _driverEtaMinutes;
  double? _driverDistanceMeters;

  Uint8List? _driverIconBytes;
  Uint8List? _pickupIconBytes;

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String _statusMessage = 'Searching for nearby drivers...';
  bool _isSearching = true;
  bool _isInitializing = true; // shows skeleton for first 600ms
  
  // ✅ DEFENSIVE PROGRAMMING: Operation lock pentru a preveni multiple operations
  bool _isOperationInProgress = false;
  

  String? _foundDriverDisplayName;
  String? _foundDriverLicensePlate;
  String? _foundDriverCategory;
  double? _foundDriverRating;
  String? _foundDriverId;

  static const double _avgDriverSpeedKmhForEta = 35.0; // UX-only, aproximare
  static const double _etaSpeedMps =
      _avgDriverSpeedKmhForEta * 1000.0 / 3600.0;

  @override
  void initState() {
    super.initState();
    Logger.info('SearchingForDriverScreen created with rideId: ${widget.rideId}');
    Logger.debug('SearchingForDriverScreen initState');
    
    _initializeAnimations();
    _startMonitoringRideStatus();
    _searchTimeoutTimer = Timer(const Duration(minutes: 1), _handleSearchTimeout);
    _startCountdownTicker();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isInitializing = false);
    });
  }

  Future<Uint8List> _loadAssetBytes(String assetPath) async {
    final bd = await rootBundle.load(assetPath);
    return bd.buffer.asUint8List();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _markersManager = await _mapboxMap?.annotations.createPointAnnotationManager(
      id: 'searching-driver-annotations',
    );

    // Setup location puck to avoid missing image warnings
    try {
      if (_mapboxMap != null) {
        await _setupLocationPuck(_mapboxMap!);
      }
    } catch (e) {
      Logger.warning('SearchingScreen: Could not setup location puck: $e');
    }

    // Load icons once per screen instance
    _driverIconBytes ??= await DriverIconHelper.getDriverIconBytes();
    _pickupIconBytes ??= await _loadAssetBytes('assets/images/pin_icon.png');

    if (!mounted) return;
    await _upsertPickupMarker();
    if (_lastDriverPoint != null) {
      await _upsertDriverMarker(_lastDriverPoint!);
    }
  }

  Future<void> _setupLocationPuck(MapboxMap mapboxMap) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 48, 48));
    final paint = Paint()..isAntiAlias = true;
    paint.color = Colors.white.withAlpha(200);
    canvas.drawCircle(const Offset(24, 24), 20, paint);
    paint.color = const Color(0xFF3682F3);
    canvas.drawCircle(const Offset(24, 24), 14, paint);
    final picture = recorder.endRecording();
    final img = await picture.toImage(48, 48);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List puckBytes = byteData!.buffer.asUint8List();

    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingMaxRadius: 60.0,
        locationPuck: LocationPuck(
          locationPuck2D: LocationPuck2D(
            topImage: puckBytes,
            bearingImage: puckBytes,
            shadowImage: puckBytes,
          ),
        ),
      ),
    );
  }

  Future<void> _upsertPickupMarker() async {
    if (_pickupPoint == null || _markersManager == null || _pickupIconBytes == null) return;

    final brightness = Theme.of(context).brightness;
    final textColor =
        brightness == Brightness.dark ? Colors.white.toARGB32() : Colors.black.toARGB32();
    final haloColor =
        brightness == Brightness.dark ? Colors.black.toARGB32() : Colors.white.toARGB32();

    // Re-create if needed (simple & safe).
    if (_pickupAnnotation != null) {
      try {
        await _markersManager?.delete(_pickupAnnotation!);
      } catch (_) {
        // Annotation may not have been added (e.g. map disposed).
      }
      _pickupAnnotation = null;
    }

    _pickupAnnotation = await _markersManager?.create(
      PointAnnotationOptions(
        geometry: MapboxUtils.convertToPoint(_pickupPoint!),
        image: _pickupIconBytes!,
        iconAnchor: IconAnchor.BOTTOM,
        iconSize: 0.25,
        textField: 'Pickup',
        textSize: 12.0,
        textColor: textColor,
        textHaloColor: haloColor,
        textHaloWidth: 1.5,
        textAnchor: TextAnchor.TOP,
        textOffset: [0.0, 1.2],
        textJustify: TextJustify.LEFT,
      ),
    );
  }

  Future<void> _upsertDriverMarker(Point driverPoint) async {
    if (_markersManager == null || _driverIconBytes == null) return;

    final brightness = Theme.of(context).brightness;
    final textColor =
        brightness == Brightness.dark ? Colors.white.toARGB32() : Colors.black.toARGB32();
    final haloColor =
        brightness == Brightness.dark ? Colors.black.toARGB32() : Colors.white.toARGB32();

    // Delete + recreate to guarantee text correctness after profile loads.
    if (_driverAnnotation != null) {
      try {
        await _markersManager?.delete(_driverAnnotation!);
      } catch (_) {
        // Annotation may not have been added (e.g. map disposed).
      }
      _driverAnnotation = null;
    }

    final driverName = _foundDriverDisplayName ?? 'Driver';
    final licensePlate = _foundDriverLicensePlate ?? '';

    _driverAnnotation = await _markersManager?.create(
      PointAnnotationOptions(
        geometry: MapboxUtils.convertToPoint(driverPoint),
        image: _driverIconBytes!,
        iconAnchor: IconAnchor.BOTTOM,
        iconSize: 0.25,
        iconRotate: 0.0,
        textField: (licensePlate.isNotEmpty) ? '$driverName\n$licensePlate' : driverName,
        textSize: 14.0,
        textColor: textColor,
        textHaloColor: haloColor,
        textHaloWidth: 2.0,
        textAnchor: TextAnchor.TOP,
        textOffset: [0.0, 2.5],
        textJustify: TextJustify.CENTER,
      ),
    );
  }

  double? _estimateEtaMinutesForDistanceMeters(double? distanceMeters) {
    if (distanceMeters == null || distanceMeters.isNaN || distanceMeters.isInfinite) return null;
    if (distanceMeters <= 0) return 0;

    final seconds = distanceMeters / _etaSpeedMps;
    final minutes = seconds / 60.0;
    return minutes;
  }

  String _formatDistanceMeters(double? meters) {
    if (meters == null || meters.isNaN || meters.isInfinite) return '—';
    if (meters <= 0) return '—';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatEtaMinutes(double? minutes) {
    if (minutes == null || minutes.isNaN || minutes.isInfinite) return '—';
    if (minutes <= 0) return '<1 min';
    if (minutes < 1.0) return '<1 min';
    return '~${minutes.round()} min';
  }

  Future<void> _handleDriverLocationSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final data = snap.data();
    if (data == null) return;

    final pos = data['position'] as GeoPoint?;
    if (pos == null) return;

    final driverPoint = Point(
      coordinates: Position(pos.longitude, pos.latitude),
    );

    _lastDriverPoint = driverPoint;

    if (_pickupPoint != null) {
      final distMeters = MapboxUtils.calculateDistance(_pickupPoint!, driverPoint);
      _driverDistanceMeters = distMeters;
      _driverEtaMinutes = _estimateEtaMinutesForDistanceMeters(distMeters);
    }

    // Update marker + camera.
    await _upsertDriverMarker(driverPoint);

    if (_mapboxMap != null && mounted) {
      _mapboxMap?.flyTo(
        CameraOptions(
          center: MapboxUtils.convertToPoint(driverPoint),
          zoom: 15.0,
          padding: MbxEdgeInsets(
            top: 120,
            left: 50,
            bottom: 120,
            right: 50,
          ),
        ),
        MapAnimationOptions(duration: 450),
      );
    }

    if (mounted) setState(() {});
  }

  Future<void> _stopDriverPreview() async {
    await _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
    _lastDriverPoint = null;
    _driverEtaMinutes = null;
    _driverDistanceMeters = null;

    if (_markersManager != null && _driverAnnotation != null) {
      try {
        await _markersManager?.delete(_driverAnnotation!);
      } catch (_) {
        // Annotation may not have been added (e.g. map disposed).
      }
    }
    _driverAnnotation = null;
  }

  void _initializeAnimations() {
    const mediumAnimation = Duration(milliseconds: 500);
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Slide animation
    _slideController = AnimationController(
      duration: mediumAnimation,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Fade animation
    _fadeController = AnimationController(
      duration: mediumAnimation,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  void _startMonitoringRideStatus() {
    Logger.debug('Starting ride status monitoring for ride: ${widget.rideId}', tag: 'SEARCHING');
    _rideSubscription = _firestoreService.getRideStream(widget.rideId).listen((ride) async {
      Logger.debug('Ride status updated to: ${ride.status} for ride: ${ride.id}', tag: 'SEARCHING');

      if (!mounted) {
        _rideSubscription?.cancel();
        return;
      }

      switch (ride.status) {
        case 'pending':
          if (!_isSearching) {
            final bool hasPickup =
                ride.startLatitude != null && ride.startLongitude != null;

            setState(() {
              _statusMessage = AppLocalizations.of(context)!.searchDriverSearchingNearby;
              _isSearching = true;
              _foundDriverDisplayName = null;
              _foundDriverLicensePlate = null;
              _foundDriverId = null;
              _searchTimeoutTimer?.cancel();
              _searchTimeoutTimer = Timer(const Duration(minutes: 1), _handleSearchTimeout);
              _startCountdownTicker();

              // Pickup preview.
              if (hasPickup) {
                _pickupPoint = Point(
                  coordinates: Position(ride.startLongitude!, ride.startLatitude!),
                );
              }
            });

            if (hasPickup) {
              _upsertPickupMarker();
            }
            _startSearchAnimations();
          }
          _confirmationTimeoutTimer?.cancel();
          break;

        case 'driver_found':
          Logger.info('Driver found for ride ${ride.id} - Driver ID: ${ride.driverId}', tag: 'SEARCHING');
          _searchTimeoutTimer?.cancel();
          _stopSearchAnimations();
          
          if (_confirmationTimeoutTimer == null || !_confirmationTimeoutTimer!.isActive) {
            _confirmationTimeoutTimer = Timer(const Duration(minutes: 2), _handleConfirmationTimeout);
            Logger.info('Confirmation timer started - 2 minutes', tag: 'SEARCHING');
          }

          setState(() {
            _isSearching = false;
            _statusMessage = AppLocalizations.of(context)!.searchDriverFoundWaitConfirm;
            _foundDriverId = ride.driverId;

            if (ride.startLatitude != null &&
                ride.startLongitude != null) {
              _pickupPoint = Point(
                coordinates: Position(ride.startLongitude!, ride.startLatitude!),
              );
            }
          });

          if (_pickupPoint != null) {
            _upsertPickupMarker();
          }
          
          Logger.info('UI updated - Driver found message displayed', tag: 'SEARCHING');

          _slideController.forward();

          // Start driver preview as soon as we have driverId.
          if (ride.driverId != null) {
            await _stopDriverPreview();
            _driverLocationSubscription = _firestoreService
                .getDriverLocationStream(ride.driverId!)
                .listen(
                  (snap) async {
                    if (!mounted) return;
                    await _handleDriverLocationSnapshot(snap);
                  },
                  onError: (error) {
                    Logger.error('Driver preview stream error: $error', error: error);
                  },
                );
          }

          if (ride.driverId != null) {
            final driverProfileSnapshot = await _firestoreService.getProfileByIdStream(ride.driverId!).first;
            if (!mounted) return;
            final driverData = driverProfileSnapshot.data();
            if (driverData != null) {
              setState(() {
                _foundDriverDisplayName = driverData['displayName'] ?? 'N/A';
                _foundDriverLicensePlate = driverData['licensePlate'] ?? 'N/A';
                _foundDriverCategory = driverData['driverCategory'] ?? 'Standard';
                _foundDriverRating = (driverData['averageRating'] as num?)?.toDouble();
              });

              // Refresh marker text after profile is loaded.
              if (_lastDriverPoint != null) {
                await _upsertDriverMarker(_lastDriverPoint!);
              }
            }
          }
          break;

        // ==========================================================
        // AICI ESTE MODIFICAREA CHEIE
        // ==========================================================
        case 'accepted':
        case 'arrived':
        case 'in_progress':
          await _stopDriverPreview();
          _searchTimeoutTimer?.cancel();
          _confirmationTimeoutTimer?.cancel();
          if (mounted) {
            final r = PassengerSearchFlowResult(rideId: ride.id);
            PassengerRideServiceBus.emit(r);
            Navigator.of(context).pop(r);
          }
          break;
        
        case 'completed':
          await _stopDriverPreview();
          _searchTimeoutTimer?.cancel();
          _confirmationTimeoutTimer?.cancel();
          if (mounted) {
            final r = PassengerSearchFlowResult(
              rideId: ride.id,
              shouldOpenSummary: true,
            );
            PassengerRideServiceBus.emit(r);
            Navigator.of(context).pop(r);
          }
          break;

        case 'cancelled':
        case 'expired':
          await _stopDriverPreview();
          _searchTimeoutTimer?.cancel();
          _confirmationTimeoutTimer?.cancel();
          if (mounted) {
            setState(() {
              final l10n = AppLocalizations.of(context)!;
              _statusMessage = ride.status == 'cancelled' 
                  ? l10n.searchDriverRideCancelled
                  : l10n.searchDriverNoDriverAvailable;
              _isSearching = false;
              _foundDriverDisplayName = null;
            });
            _stopSearchAnimations();
          }
          break;
        
        default:
          if (mounted) {
            setState(() {
              _statusMessage = AppLocalizations.of(context)!.searchDriverUnknownRideStatus(ride.status);
              _isSearching = false;
            });
            _stopSearchAnimations();
          }
          break;
      }
    }, onError: (error) {
      Logger.error('Error listening to ride stream: $error', error: error);
      if (mounted) {
        setState(() {
          _statusMessage = AppLocalizations.of(context)!.errorMonitoringRide;
          _isSearching = false;
        });
        _stopSearchAnimations();
      }
    });
  }

  void _startSearchAnimations() {
    _pulseController.repeat(reverse: true);
  }

  void _stopSearchAnimations() {
    _pulseController.stop();
    _countdownTicker?.cancel();
  }

  void _startCountdownTicker() {
    _countdownTicker?.cancel();
    _searchSecondsElapsed = 0;
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _searchSecondsElapsed =
            (_searchSecondsElapsed + 1).clamp(0, _searchTimeoutSeconds);
      });
    });
  }

  @override
  void dispose() {
    Logger.debug('SearchingForDriverScreen dispose - cleaning up');

    // ✅ DEFENSIVE PROGRAMMING: Cancel toate operațiunile active
    _rideSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    _searchTimeoutTimer?.cancel();
    _confirmationTimeoutTimer?.cancel();
    _countdownTicker?.cancel();
    
    // ✅ DEFENSIVE PROGRAMMING: Dispose toate animațiile
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    
    // ✅ DEFENSIVE PROGRAMMING: Reset operation lock
    _isOperationInProgress = false;
    
    super.dispose();
  }

  /// ✅ DEFENSIVE PROGRAMMING: Safe search timeout handling
  void _handleSearchTimeout() async {
    if (!mounted || !_isSearching) return;
    
    try {
      Logger.warning('⏰ Search timeout triggered - updating ride status');
      
      // ✅ TIMEOUT PROTECTION pentru Firestore operation
      final currentRide = await _firestoreService.getRideStream(widget.rideId)
          .first
          .timeout(const Duration(seconds: 10));
      
      if (!mounted) return;
      
      if (currentRide.status == 'pending') {
        // ✅ TIMEOUT PROTECTION pentru update operation
        await _firestoreService.updateRideStatus(widget.rideId, 'expired')
            .timeout(const Duration(seconds: 10));
        
        Logger.info('Ride status updated to expired');
      }
    } catch (e) {
      Logger.error('Error handling search timeout: $e', error: e);
      // Nu facem nimic la eroare - doar log
    }
  }

  /// ✅ DEFENSIVE PROGRAMMING: Safe confirmation timeout handling
  void _handleConfirmationTimeout() async {
    if (!mounted) return;
    
    try {
      Logger.warning('Confirmation timeout triggered after 2 minutes - declining driver', tag: 'TIMEOUT');
      
      // ✅ TIMEOUT PROTECTION pentru Firestore operation
      final currentRide = await _firestoreService.getRideStream(widget.rideId)
          .first
          .timeout(const Duration(seconds: 10));
      
      if (!mounted) return;
      
      if (currentRide.status == 'driver_found') {
        Logger.warning('Ride still in driver_found status - declining driver automatically', tag: 'TIMEOUT');
        // ✅ TIMEOUT PROTECTION pentru decline operation
        await _firestoreService.passengerDeclineDriver(widget.rideId)
            .timeout(const Duration(seconds: 10));
        
        Logger.warning('Driver declined due to timeout - resuming search', tag: 'TIMEOUT');
      } else {
        Logger.warning('Ride status changed to ${currentRide.status} - no action needed', tag: 'TIMEOUT');
      }
    } catch (e) {
      Logger.error('Error handling confirmation timeout: $e', tag: 'TIMEOUT', error: e);
      // Nu facem nimic la eroare - doar log
    }
  }

  /// ✅ DEFENSIVE PROGRAMMING: Safe driver confirmation (+ previzualizare traseu în Storage)
  Future<void> _confirmDriver() async {
    if (_foundDriverId == null || !mounted) return;
    if (_isOperationInProgress) return;

    setState(() => _isOperationInProgress = true);
    try {
      Logger.info('Passenger confirming ride ${widget.rideId}');

      _confirmationTimeoutTimer?.cancel();

      final ride = await _firestoreService.getRideStream(widget.rideId).first.timeout(const Duration(seconds: 10));

      if (!context.mounted) return;

      String? previewUrl;
      try {
        final png = await RoutePreviewCaptureService.captureRoutePng(
          context: context, // ignore: use_build_context_synchronously
          ride: ride,
        );
        if (!context.mounted) return;
        if (png != null && png.isNotEmpty) {
          previewUrl = await _firestoreService.uploadRideRoutePreviewPng(widget.rideId, png);
        }
      } catch (e) {
        Logger.warning('Route preview capture/upload skipped: $e', tag: 'SEARCHING');
      }

      if (!context.mounted) return;
      await _firestoreService.passengerConfirmDriver(widget.rideId, routePreviewUrl: previewUrl).timeout(const Duration(seconds: 15));

      Logger.info('Driver confirmed successfully');
    } catch (e) {
      Logger.error('Error confirming driver: $e', error: e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.searchDriverConfirmError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOperationInProgress = false);
      }
    }
  }

  /// ✅ DEFENSIVE PROGRAMMING: Safe driver decline
  void _declineDriver() async {
    if (_foundDriverId != null && mounted) {
      try {
        Logger.error('Passenger declining driver for ride ${widget.rideId}');
        
        // Cancel confirmation timeout
        _confirmationTimeoutTimer?.cancel();
        
        // ✅ TIMEOUT PROTECTION pentru decline operation
        await _firestoreService.passengerDeclineDriver(widget.rideId)
            .timeout(const Duration(seconds: 10));
        
        if (mounted) {
          setState(() {
            _foundDriverDisplayName = null;
            _statusMessage = AppLocalizations.of(context)!.searchDriverDeclinedResuming;
            _isSearching = true;
            _searchTimeoutTimer?.cancel();
            _searchTimeoutTimer = Timer(const Duration(minutes: 1), _handleSearchTimeout);
          });
          _startCountdownTicker();
          _slideController.reset();
          _startSearchAnimations();
        }
        
        Logger.info('Driver declined successfully');
      } catch (e) {
        Logger.error('Error declining driver: $e', error: e);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.searchDriverDeclineError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

    /// ✅ DEFENSIVE PROGRAMMING: Safe ride cancellation with proper navigation
  Future<void> _cancelRideEarly() async {
    // 1. VALIDATION
    if (!mounted) return;
    if (_isOperationInProgress) return;
    
    try {
      // 2. LOCK
      _isOperationInProgress = true;
      Logger.debug('User pressed cancel - starting cleanup...');
      
      // 3. TIMEOUT PROTECTION pentru Firestore operation
      await _firestoreService.cancelRide(widget.rideId)
          .timeout(const Duration(seconds: 10));
      
      if (!mounted) return;
      
      // 4. Cancel toate timer-ele și stream-urile
      _searchTimeoutTimer?.cancel();
      _confirmationTimeoutTimer?.cancel();
      _rideSubscription?.cancel();
      
      // 5. Stop toate animațiile
      _stopSearchAnimations();
      
      Logger.info('Cancel completed - navigating to MapScreen');
      
      // 6. Safe navigation cu pushAndRemoveUntil pentru clean stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MapScreen()),
          (route) => false, // Remove toate route-urile anterioare
        );
      }
      
    } catch (e) {
      Logger.error('Error cancelling search: $e', error: e);
      
      // 7. ERROR HANDLING - Fallback navigation chiar și la eroare
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.searchDriverCancelError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        
        // Forțează navigarea înapoi
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MapScreen()),
          (route) => false,
        );
      }
    } finally {
      // 8. CLEANUP
      _isOperationInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for the map
      body: Stack(
        children: [
          // 1. Full Screen Map MapBackground
          Positioned.fill(
            child: _buildMapPreview(),
          ),

          // 2. Safe Area for top overlay (Close/Cancel button)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isSearching) _buildPremiumCancelButton() else const SizedBox.shrink(),
                ],
              ),
            ),
          ),

          // 3. Premium Uber-Style Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: size.height * 0.7, // Slightly larger constraint
                ),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark 
                      ? const Color(0xFF161621) 
                      : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 120 : 40),
                      blurRadius: 40,
                      offset: const Offset(0, -10),
                    ),
                  ],
                  border: Border.all(
                    color: theme.brightness == Brightness.dark 
                        ? Colors.white.withAlpha(15) 
                        : Colors.grey.withAlpha(20),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      Container(
                        width: 48,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 28),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark 
                              ? Colors.white.withAlpha(40) 
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      
                      if (_isInitializing)
                        const SkeletonDriverSearch()
                      else if (_foundDriverDisplayName != null && !_isSearching)
                        _buildDriverFoundContent()
                      else if (_isSearching)
                        _buildSearchingContent()
                      else
                        _buildErrorContent(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    final center = _pickupPoint ?? MapboxUtils.createPoint(44.4268, 26.1025);
    return MapWidget(
      onMapCreated: (map) {
        if (_mapboxMap == null) {
          _onMapCreated(map);
        }
      },
      styleUri: NabourMapStyles.uriForMainMap(
        lowDataMode: false,
        darkMode: Theme.of(context).brightness == Brightness.dark,
      ),
      cameraOptions: CameraOptions(
        center: MapboxUtils.convertToPoint(center),
        zoom: 14.0,
      ),
    );
  }

  Widget _buildPremiumCancelButton() {
    return GestureDetector(
      onTap: _isOperationInProgress ? null : _cancelRideEarly,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).round()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.black,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSearchingContent() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final int remaining = (_searchTimeoutSeconds - _searchSecondsElapsed).clamp(0, _searchTimeoutSeconds);
    final double progress = remaining / _searchTimeoutSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.searchDriverSearchingTitle,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withAlpha(120) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Countdown Ring (Premium Style)
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(10) : Colors.blue.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      backgroundColor: isDark ? Colors.white.withAlpha(20) : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        remaining <= 10 ? Colors.redAccent : Colors.blueAccent,
                      ),
                    ),
                  ),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildSearchAnimationHorizontal(),
        const SizedBox(height: 40),
        // Premium Info Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.blueAccent.withAlpha(20) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.blueAccent.withAlpha(30) : Colors.blue.withAlpha(10),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.blueAccent, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.searchDriverPremiumHintTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.blueAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.searchDriverPremiumHintBody,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white.withAlpha(180) : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAnimationHorizontal() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              Transform.scale(
                scale: _pulseAnimation.value * 1.2,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blueAccent.withAlpha(40),
                        Colors.blueAccent.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
              // Inner Pulse
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent.withAlpha(isDark ? 30 : 20),
                  ),
                ),
              ),
              // Center Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white : Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_searching_rounded, 
                  color: isDark ? Colors.black : Colors.white, 
                  size: 28,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDriverFoundContent() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.searchDriverFoundTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white.withAlpha(120) : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          _buildUberDriverCard(),
          
          const SizedBox(height: 24),
          
          // Ride Info Preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(5) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white12 : Colors.blue.withAlpha(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRideMetric(
                  l10n.searchDriverArrivesIn,
                  _formatEtaMinutes(_driverEtaMinutes),
                  Icons.access_time_filled_rounded,
                  Colors.orangeAccent,
                  isDark,
                ),
                Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.grey[200]),
                _buildRideMetric(
                  l10n.searchDriverDistanceLabel,
                  _formatDistanceMeters(_driverDistanceMeters),
                  Icons.near_me_rounded,
                  Colors.blueAccent,
                  isDark,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          _buildUberActionButtons(),
        ],
      ),
    );
  }

  Widget _buildUberDriverCard() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white12 : Colors.grey[100],
                  border: Border.all(color: Colors.blueAccent.withAlpha(40), width: 2),
                ),
                child: const Icon(Icons.person_rounded, size: 40, color: Colors.blueAccent),
              ),
              if (_foundDriverRating != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? const Color(0xFF1E1E2D) : Colors.white, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        _foundDriverRating!.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _foundDriverDisplayName ?? l10n.searchDriverNabourDriverFallback,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _foundDriverCategory ?? l10n.searchDriverStandardCategory,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Plate
          _buildLicensePlateCard(isDark),
        ],
      ),
    );
  }

  Widget _buildUberActionButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _isOperationInProgress ? null : _declineDriver,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                foregroundColor: Colors.redAccent,
              ),
              child: Text(AppLocalizations.of(context)!.decline, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isOperationInProgress ? null : () => _confirmDriver(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                elevation: 8,
                shadowColor: (isDark ? Colors.white : Colors.black).withAlpha(40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isOperationInProgress
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.confirm,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideMetric(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildLicensePlateCard(bool isDark) {
    if (_foundDriverLicensePlate == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black, // Dark plate looks premium
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        _foundDriverLicensePlate!,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 48),
        const SizedBox(height: 16),
        Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isOperationInProgress ? null : _cancelRideEarly,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            child: Text(AppLocalizations.of(context)!.backToMap),
          ),
        ),
      ],
    );
  }
}