import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Provider pentru gestionarea stării șoferului
/// Extrage logica de driver din map_screen.dart
class DriverStateProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // Driver state
  bool _isDriverAvailable = false;
  Map<String, dynamic>? _driverProfile;
  RideCategory? _driverCategory;
  List<Ride> _pendingRides = [];
  Ride? _currentRideOffer;
  Timer? _rideOfferTimer;
  int _remainingSeconds = 30;

  // Subscriptions pentru cleanup
  StreamSubscription<List<Ride>>? _pendingRidesSubscription;
  StreamSubscription? _driverProfileSubscription;
  StreamSubscription<Position>? _locationStreamSubscription;

  // Getters
  bool get isDriverAvailable => _isDriverAvailable;
  Map<String, dynamic>? get driverProfile => _driverProfile;
  RideCategory? get driverCategory => _driverCategory;
  List<Ride> get pendingRides => _pendingRides;
  Ride? get currentRideOffer => _currentRideOffer;
  int get remainingSeconds => _remainingSeconds;
  bool get hasActiveRideOffer => _currentRideOffer != null;

  /// Inițializează driver state și subscriptions
  Future<void> initializeDriverState(String? userId) async {
    if (userId == null) return;

    Logger.debug('Initializing driver state...');

    try {
      // Încarcă profilul șoferului
      await _loadDriverProfile(userId);
      
      // Inițializează listening-ul pentru ride-uri
      _initializeDriverRideSystem();
      
      Logger.info('Driver state initialized');
    } catch (e) {
      Logger.error('Error initializing driver state: $e', error: e);
    }
  }

  /// Încarcă profilul șoferului din Firestore
  Future<void> _loadDriverProfile(String userId) async {
    try {
      _driverProfileSubscription?.cancel();
      _driverProfileSubscription = _firestoreService.getUserProfileStream().listen((snapshot) {
        if (snapshot.exists) {
          _driverProfile = snapshot.data();
          _driverCategory = _getCategoryFromProfile(_driverProfile!);
          Logger.info('Driver profile loaded: ${_driverProfile?['displayName']}');
          notifyListeners();
        }
      });
    } catch (e) {
      Logger.error('Error loading driver profile: $e', error: e);
    }
  }

  /// Convertește category string la enum
  RideCategory _getCategoryFromProfile(Map<String, dynamic> profile) {
    final categoryStr = profile['driverCategory'] as String?;
    switch (categoryStr) {
      case 'standard': return RideCategory.standard;
      case 'energy': return RideCategory.energy;
      case 'best': return RideCategory.best;
      default: return RideCategory.standard;
    }
  }

  /// Inițializează sistemul de ascultare pentru ride-uri
  void _initializeDriverRideSystem() {
    if (_driverCategory == null) {
      Logger.warning('Cannot start ride system - no driver category');
      return;
    }

    Logger.info('Starting ride listening system for category: ${_driverCategory!.name}');
    
    _pendingRidesSubscription?.cancel();
    _pendingRidesSubscription = _firestoreService
        .getPendingRideRequests(_driverCategory!)
        .listen(_handleNewRideOffers);
  }

  /// Procesează ride offers noi
  void _handleNewRideOffers(List<Ride> rides) {
    _pendingRides = rides;
    
    if (_currentRideOffer == null && rides.isNotEmpty && _isDriverAvailable) {
      _showRideOffer(rides.first);
    }
    
    Logger.debug('Received ${rides.length} pending rides');
    notifyListeners();
  }

  /// Afișează o ofertă de cursă cu timer
  void _showRideOffer(Ride ride) {
    _currentRideOffer = ride;
    _remainingSeconds = 30;
    
    Logger.info('New ride offer: ${ride.id}');
    
    _rideOfferTimer?.cancel();
    _rideOfferTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      notifyListeners();
      
      if (_remainingSeconds <= 0) {
        _declineRideOffer();
      }
    });
    
    notifyListeners();
  }

  /// Toggle driver availability
  Future<void> toggleDriverAvailability(bool value) async {
    if (_driverProfile == null) {
      Logger.warning('Cannot toggle availability - no driver profile');
      return;
    }

    Logger.debug('Toggling driver availability to: $value');

    try {
      if (value) {
        await _firestoreService.updateDriverAvailability(
          true,
          displayName: _driverProfile!['displayName'],
          licensePlate: _driverProfile!['licensePlate'],
          category: _driverCategory!,
        );
        _initializeDriverRideSystem();
        await _startLocationStream();
      } else {
        await _stopLocationStream();
        await _firestoreService.updateDriverAvailability(false);
        _stopListeningForRides();
      }

      _isDriverAvailable = value;
      notifyListeners();

      Logger.info('Driver availability updated to: $value');
    } catch (e) {
      Logger.error('Error updating driver availability: $e', error: e);
      _isDriverAvailable = !value;
      notifyListeners();
      rethrow;
    }
  }

  /// Porneşte stream-ul continuu de locaţie cât timp şoferul e online.
  /// Actualizează Firestore la fiecare 20 m sau la fiecare 5 secunde.
  Future<void> _startLocationStream() async {
    await _locationStreamSubscription?.cancel();

    final androidSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
      intervalDuration: const Duration(seconds: 5),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Nabour — Ești online',
        notificationText: 'Locația ta este partajată pentru a găsi curse.',
        enableWakeLock: true,
      ),
    );
    final appleSettings = AppleSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
      activityType: ActivityType.automotiveNavigation,
    );

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );

    late LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = androidSettings;
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = appleSettings;
    } else {
      locationSettings = settings;
    }

    _locationStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) {
      _firestoreService.updateDriverLocation(position);
      Logger.debug(
          'Driver location updated: ${position.latitude.toStringAsFixed(5)}, '
          '${position.longitude.toStringAsFixed(5)}',
          tag: 'DriverLocation');
    }, onError: (e) {
      Logger.error('Location stream error: $e', tag: 'DriverLocation');
    });

    Logger.info('Driver location stream started', tag: 'DriverLocation');
  }

  /// Opreşte stream-ul de locaţie şi marchează şoferul offline în Firestore.
  Future<void> _stopLocationStream() async {
    await _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
    Logger.info('Driver location stream stopped', tag: 'DriverLocation');
  }

  /// Acceptă o ofertă de cursă
  Future<void> acceptRideOffer() async {
    if (_currentRideOffer == null) return;

    final ride = _currentRideOffer!;
    Logger.info('Accepting ride offer: ${ride.id}');

    try {
      await _firestoreService.acceptRide(ride.id);
      _clearCurrentRideOffer();
      notifyListeners();
    } catch (e) {
      Logger.error('Error accepting ride: $e', error: e);
      rethrow;
    }
  }

  /// Refuză o ofertă de cursă
  Future<void> declineRideOffer() async {
    _declineRideOffer();
  }

  void _declineRideOffer() {
    if (_currentRideOffer == null) return;

    Logger.error('Declining ride offer: ${_currentRideOffer!.id}');
    _clearCurrentRideOffer();
    
    // Caută următoarea cursă disponibilă
    if (_pendingRides.length > 1) {
      final nextRide = _pendingRides.skip(1).first;
      _showRideOffer(nextRide);
    }
    
    notifyListeners();
  }

  /// Șterge oferta curentă și oprește timer-ul
  void _clearCurrentRideOffer() {
    _rideOfferTimer?.cancel();
    _rideOfferTimer = null;
    _currentRideOffer = null;
    _remainingSeconds = 30;
  }

  /// Oprește ascultarea pentru ride-uri
  void _stopListeningForRides() {
    _pendingRidesSubscription?.cancel();
    _pendingRidesSubscription = null;
    _clearCurrentRideOffer();
    _pendingRides.clear();
    Logger.info('Stopped listening for rides');
  }

  /// Cleanup la dispose
  @override
  void dispose() {
    Logger.debug('Disposing DriverStateProvider');

    _rideOfferTimer?.cancel();
    _stopListeningForRides();
    _driverProfileSubscription?.cancel();
    _locationStreamSubscription?.cancel();

    super.dispose();
  }
}
