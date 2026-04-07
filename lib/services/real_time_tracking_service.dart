import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/utils/coordinate_helpers.dart';
import 'package:nabour_app/services/ai_location_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🚀 Real-time Tracking Service cu AI Integration
/// 
/// Acest serviciu oferă:
/// - Live location tracking pentru șoferi și pasageri
/// - AI-powered ETA predictions
/// - Real-time communication
/// - Emergency tracking și safety features
/// - Performance optimization cu caching și batching
class RealTimeTrackingService {
  static final RealTimeTrackingService _instance = RealTimeTrackingService._internal();
  factory RealTimeTrackingService() => _instance;
  RealTimeTrackingService._internal();

  // Core Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AILocationService _aiLocationService = AILocationService();
  
  // Tracking State
  bool _isTrackingActive = false;
  String? _currentRideId;
  String? _currentUserId;
  UserRole _currentUserRole = UserRole.passenger;
  
  // Real-time Streams
  StreamSubscription<geolocator.Position>? _locationSubscription;
  StreamSubscription<DocumentSnapshot>? _rideSubscription;
  StreamSubscription<QuerySnapshot>? _locationUpdatesSubscription;
  
  // Performance Optimization
  Timer? _batchUpdateTimer;
  Timer? _aiPredictionTimer;
  final List<Map<String, dynamic>> _pendingLocationUpdates = [];
  static const Duration _batchUpdateInterval = Duration(seconds: 2);
  static const int _maxBatchSize = 10;
  
  // AI Prediction Cache
  final Map<String, AIPrediction> _predictionCache = {};
  static const Duration _predictionCacheExpiry = Duration(minutes: 5);
  
  // Callbacks
  Function(RealTimeLocationUpdate)? onLocationUpdate;
  Function(AIPrediction)? onPredictionUpdate;
  Function(RealTimeCommunication)? onCommunicationUpdate;
  Function(EmergencyAlert)? onEmergencyAlert;
  
  // Configuration
  static const int _locationAccuracy = 10; // meters
  static const Duration _predictionUpdateInterval = Duration(seconds: 30);
  
  /// 🚀 Pornește real-time tracking pentru o cursă
  Future<void> startTracking({
    required String rideId,
    required String userId,
    required UserRole userRole,
    required Point startLocation,
    required Point destination,
  }) async {
    try {
      Logger.info('Starting real-time tracking for ride: $rideId');
      
      _currentRideId = rideId;
      _currentUserId = userId;
      _currentUserRole = userRole;
      
      // Initialize tracking session
      await _initializeTrackingSession(startLocation, destination);
      
      // Start location monitoring
      await _startLocationMonitoring();
      
      // Start ride monitoring
      await _startRideMonitoring();
      
      // Start AI predictions
      await _startAIPredictions();
      
      // Start batch updates
      _startBatchUpdates();
      
      _isTrackingActive = true;
      
      Logger.info('Real-time tracking started successfully');
      
    } catch (e) {
      Logger.error('Failed to start tracking: $e', error: e);
      rethrow;
    }
  }
  
  /// 🛑 Oprește real-time tracking
  Future<void> stopTracking() async {
    try {
      Logger.debug('Stopping real-time tracking');
      
      // Stop all subscriptions
      await _locationSubscription?.cancel();
      await _rideSubscription?.cancel();
      await _locationUpdatesSubscription?.cancel();
      
      // Stop timers
      _batchUpdateTimer?.cancel();
      
      // Flush pending updates
      await _flushPendingUpdates();
      
      // Clear state
      _isTrackingActive = false;
      _currentRideId = null;
      _currentUserId = null;
      _pendingLocationUpdates.clear();
      _predictionCache.clear();
      
      Logger.info('Real-time tracking stopped successfully');
      
    } catch (e) {
      Logger.error('Error stopping tracking: $e', error: e);
    }
  }
  
  /// 🧹 Dispose resources with MEMORY LEAK PREVENTION
  void dispose() {
    Logger.debug('Disposing RealTimeTrackingService');
    
    // Cancel all subscriptions
    _locationSubscription?.cancel();
    _rideSubscription?.cancel();
    _locationUpdatesSubscription?.cancel();
    
    // Cancel all timers
    _batchUpdateTimer?.cancel();
    _aiPredictionTimer?.cancel();
    
    // Clear all data
    _pendingLocationUpdates.clear();
    _predictionCache.clear();
    
    // Reset state
    _isTrackingActive = false;
    _currentRideId = null;
    _currentUserId = null;
    
    Logger.info('RealTimeTrackingService disposed successfully');
  }
  
  /// 📍 Trimite update de locație în timp real
  Future<void> sendLocationUpdate(geolocator.Position position) async {
    if (!_isTrackingActive || _currentRideId == null) return;
    
    try {
      final locationUpdate = RealTimeLocationUpdate(
        rideId: _currentRideId!,
        userId: _currentUserId!,
        userRole: _currentUserRole,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: DateTime.now(),
        batteryLevel: await _getBatteryLevel(),
        isMoving: position.speed > 1.0, // > 3.6 km/h
      );
      
      // Add to batch for performance
      _pendingLocationUpdates.add(locationUpdate.toMap());
      
      // Trigger callback
      onLocationUpdate?.call(locationUpdate);
      
      // Flush if batch is full
      if (_pendingLocationUpdates.length >= _maxBatchSize) {
        await _flushPendingUpdates();
      }
      
    } catch (e) {
      Logger.error('Error sending location update: $e', error: e);
    }
  }
  
  /// 🧠 Obține predicții AI pentru ETA și routing
  Future<AIPrediction> getAIPrediction({
    required Point currentLocation,
    required Point destination,
    List<Point>? waypoints,
  }) async {
    try {
      final cacheKey = _generatePredictionCacheKey(currentLocation, destination, waypoints);
      
      // Check cache first
      if (_predictionCache.containsKey(cacheKey)) {
        final cached = _predictionCache[cacheKey]!;
        if (DateTime.now().difference(cached.timestamp) < _predictionCacheExpiry) {
          return cached;
        }
      }
      
      // Generate new AI prediction
      final prediction = await _aiLocationService.generateLocationPrediction(
        currentLocation: currentLocation,
        destination: destination,
        waypoints: waypoints,
        userRole: _currentUserRole,
        rideId: _currentRideId,
      );
      
      // Cache prediction
      _predictionCache[cacheKey] = prediction;
      
      // Trigger callback
      onPredictionUpdate?.call(prediction);
      
      return prediction;
      
    } catch (e) {
      Logger.error('Error getting AI prediction: $e', error: e);
      return AIPrediction.empty();
    }
  }
  
  /// 📡 Trimite mesaj în timp real
  Future<void> sendRealTimeMessage({
    required String message,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isTrackingActive || _currentRideId == null) return;
    
    try {
      final communication = RealTimeCommunication(
        rideId: _currentRideId!,
        senderId: _currentUserId!,
        senderRole: _currentUserRole,
        message: message,
        type: type,
        metadata: metadata,
        timestamp: DateTime.now(),
      );
      
      // Save to Firestore
      await _firestore
          .collection('rides')
          .doc(_currentRideId)
          .collection('communications')
          .add(communication.toMap());
      
      // Trigger callback
      onCommunicationUpdate?.call(communication);
      
    } catch (e) {
      Logger.error('Error sending real-time message: $e', error: e);
    }
  }
  
  /// 🚨 Trimite alertă de urgență
  Future<void> sendEmergencyAlert({
    required EmergencyType type,
    required Point location,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isTrackingActive || _currentRideId == null) return;
    
    try {
      final alert = EmergencyAlert(
        rideId: _currentRideId!,
        userId: _currentUserId!,
        userRole: _currentUserRole,
        type: type,
        latitude: location.coordinates.lat.toDouble(),
        longitude: location.coordinates.lng.toDouble(),
        description: description,
        metadata: metadata,
        timestamp: DateTime.now(),
        isActive: true,
      );
      
      // Save emergency alert
      await _firestore
          .collection('emergencies')
          .add(alert.toMap());
      
      // Update ride status
      await _firestore
          .collection('rides')
          .doc(_currentRideId)
          .update({
        'emergencyAlert': alert.toMap(),
        'status': 'emergency',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Trigger callback
      onEmergencyAlert?.call(alert);
      
    } catch (e) {
      Logger.error('Error sending emergency alert: $e', error: e);
    }
  }
  
  // =================
  // PRIVATE METHODS
  // =================
  
  /// Initialize tracking session în Firestore
  Future<void> _initializeTrackingSession(Point startLocation, Point destination) async {
    await _firestore
        .collection('rides')
        .doc(_currentRideId)
        .update({
      'trackingStarted': FieldValue.serverTimestamp(),
      'trackingStatus': 'active',
      'startLocation': CoordinateHelpers.pointToFirestoreData(startLocation),
      'destination': CoordinateHelpers.pointToFirestoreData(destination),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  /// Pornește monitorizarea locației
  Future<void> _startLocationMonitoring() async {
    const locationSettings = geolocator.LocationSettings(
      accuracy: geolocator.LocationAccuracy.high,
      distanceFilter: _locationAccuracy,
    );
    
    _locationSubscription = geolocator.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) => sendLocationUpdate(position),
      onError: (error) => Logger.error('Location monitoring error: $error', error: error),
    );
  }
  
  /// Pornește monitorizarea cursei
  Future<void> _startRideMonitoring() async {
    _rideSubscription = _firestore
        .collection('rides')
        .doc(_currentRideId)
        .snapshots()
        .listen(
      (snapshot) => _handleRideUpdate(snapshot),
      onError: (error) => Logger.error('Ride monitoring error: $error', error: error),
    );
  }
  
  /// Pornește predicțiile AI
  Future<void> _startAIPredictions() async {
    _aiPredictionTimer?.cancel();
    _aiPredictionTimer = Timer.periodic(_predictionUpdateInterval, (timer) async {
      if (!_isTrackingActive) {
        timer.cancel();
        return;
      }
      
      try {
              // Get current location from last update
      if (_pendingLocationUpdates.isNotEmpty) {
        final lastUpdate = _pendingLocationUpdates.last;
        final currentLocation = CoordinateHelpers.createPoint(
          (lastUpdate['longitude'] as num).toDouble(),
          (lastUpdate['latitude'] as num).toDouble(),
        );
          
          // Get destination from ride data
          final rideDoc = await _firestore
              .collection('rides')
              .doc(_currentRideId)
              .get();
          
          if (rideDoc.exists) {
            final destination = CoordinateHelpers.createPoint(
              rideDoc.data()!['destination']['longitude'] as double,
              rideDoc.data()!['destination']['latitude'] as double,
            );
            
            // Generate AI prediction
            await getAIPrediction(
              currentLocation: currentLocation,
              destination: destination,
            );
          }
        }
      } catch (e) {
        Logger.error('AI prediction error: $e', error: e);
      }
    });
  }
  
  /// Pornește batch updates pentru performanță
  void _startBatchUpdates() {
    _batchUpdateTimer = Timer.periodic(_batchUpdateInterval, (timer) async {
      if (!_isTrackingActive) {
        timer.cancel();
        return;
      }
      
      await _flushPendingUpdates();
    });
  }
  
  /// Flush pending location updates
  Future<void> _flushPendingUpdates() async {
    if (_pendingLocationUpdates.isEmpty) return;
    
    try {
      final batch = _firestore.batch();
      
      for (final update in _pendingLocationUpdates) {
        final docRef = _firestore
            .collection('rides')
            .doc(_currentRideId)
            .collection('locationUpdates')
            .doc();
        
        batch.set(docRef, update);
      }
      
      await batch.commit();
      
      // Clear pending updates
      _pendingLocationUpdates.clear();
      
      Logger.info('Flushed ${_pendingLocationUpdates.length} location updates');
      
    } catch (e) {
      Logger.error('Error flushing updates: $e', error: e);
    }
  }
  
  /// Handle ride updates
  void _handleRideUpdate(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    
    final data = snapshot.data() as Map<String, dynamic>;
    final status = data['status'] as String?;
    
    // Handle status changes
    switch (status) {
      case 'completed':
      case 'cancelled':
        stopTracking();
        break;
      case 'emergency':
        // Handle emergency status
        break;
    }
  }
  
  /// Get battery level (mock implementation)
  Future<double> _getBatteryLevel() async {
    // Implementare reală pentru detectarea nivelului bateriei când plugin-ul va fi disponibil
    // For now, simulate realistic battery patterns based on time and usage
    final now = DateTime.now();
    final hour = now.hour;
    
    // Simulate battery drain patterns
    if (hour >= 7 && hour <= 9) {
      return 0.75; // Morning - battery drained from overnight
    } else if (hour >= 17 && hour <= 19) {
      return 0.45; // Evening - heavy usage during day
    } else if (hour >= 22 || hour <= 6) {
      return 0.90; // Night - less usage, charging possible
    } else {
      return 0.65; // Normal hours - moderate usage
    }
  }
  
  /// Generate cache key for predictions
  String _generatePredictionCacheKey(Point current, Point destination, List<Point>? waypoints) {
    final waypointsStr = waypoints?.map((p) => '${p.coordinates.lat},${p.coordinates.lng}').join('|') ?? '';
    return '${current.coordinates.lat},${current.coordinates.lng}_${destination.coordinates.lat},${destination.coordinates.lng}_$waypointsStr';
  }
  
  // =================
  // GETTERS
  // =================
  
  bool get isTrackingActive => _isTrackingActive;
  String? get currentRideId => _currentRideId;
  String? get currentUserId => _currentUserId;
  UserRole get currentUserRole => _currentUserRole;
}

// =================
// DATA MODELS
// =================

/// User role în sistem
enum UserRole { driver, passenger }

/// Real-time location update
class RealTimeLocationUpdate {
  final String rideId;
  final String userId;
  final UserRole userRole;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final DateTime timestamp;
  final double batteryLevel;
  final bool isMoving;
  
  RealTimeLocationUpdate({
    required this.rideId,
    required this.userId,
    required this.userRole,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.timestamp,
    required this.batteryLevel,
    required this.isMoving,
  });
  
  Map<String, dynamic> toMap() => {
    'rideId': rideId,
    'userId': userId,
    'userRole': userRole.name,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'speed': speed,
    'heading': heading,
    'timestamp': timestamp.toIso8601String(),
    'batteryLevel': batteryLevel,
    'isMoving': isMoving,
  };
  
  factory RealTimeLocationUpdate.fromMap(Map<String, dynamic> map) => RealTimeLocationUpdate(
    rideId: map['rideId'] as String,
    userId: map['userId'] as String,
    userRole: UserRole.values.firstWhere((e) => e.name == map['userRole']),
    latitude: map['latitude'] as double,
    longitude: map['longitude'] as double,
    accuracy: map['accuracy'] as double,
    speed: map['speed'] as double,
    heading: map['heading'] as double,
    timestamp: DateTime.parse(map['timestamp'] as String),
    batteryLevel: map['batteryLevel'] as double,
    isMoving: map['isMoving'] as bool,
  );
}

/// AI Prediction pentru ETA și routing
class AIPrediction {
  final String rideId;
  final Point currentLocation;
  final Point destination;
  final Duration estimatedTime;
  final double estimatedDistance;
  final List<Point> optimalRoute;
  final double confidence;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  
  AIPrediction({
    required this.rideId,
    required this.currentLocation,
    required this.destination,
    required this.estimatedTime,
    required this.estimatedDistance,
    required this.optimalRoute,
    required this.confidence,
    required this.metadata,
    required this.timestamp,
  });
  
  factory AIPrediction.empty() => AIPrediction(
    rideId: '',
    currentLocation: Point(coordinates: Position(0, 0)),
    destination: Point(coordinates: Position(0, 0)),
    estimatedTime: Duration.zero,
    estimatedDistance: 0.0,
    optimalRoute: [],
    confidence: 0.0,
    metadata: {},
    timestamp: DateTime.now(),
  );
  
  Map<String, dynamic> toMap() => {
    'rideId': rideId,
    'currentLocation': CoordinateHelpers.pointToFirestoreData(currentLocation),
    'destination': CoordinateHelpers.pointToFirestoreData(destination),
    'estimatedTime': estimatedTime.inSeconds,
    'estimatedDistance': estimatedDistance,
    'optimalRoute': optimalRoute.map((p) => CoordinateHelpers.pointToFirestoreData(p)).toList(),
    'confidence': confidence,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Real-time communication
class RealTimeCommunication {
  final String rideId;
  final String senderId;
  final UserRole senderRole;
  final String message;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  
  RealTimeCommunication({
    required this.rideId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.type,
    this.metadata,
    required this.timestamp,
  });
  
  Map<String, dynamic> toMap() => {
    'rideId': rideId,
    'senderId': senderId,
    'senderRole': senderRole.name,
    'message': message,
    'type': type.name,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Message types
enum MessageType { text, voice, location, emergency, system }

/// Emergency alert
class EmergencyAlert {
  final String rideId;
  final String userId;
  final UserRole userRole;
  final EmergencyType type;
  final double latitude;
  final double longitude;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final bool isActive;
  
  EmergencyAlert({
    required this.rideId,
    required this.userId,
    required this.userRole,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.description,
    this.metadata,
    required this.timestamp,
    required this.isActive,
  });
  
  Map<String, dynamic> toMap() => {
    'rideId': rideId,
    'userId': userId,
    'userRole': userRole.name,
    'type': type.name,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    'isActive': isActive,
  };
}

/// Emergency types
enum EmergencyType { accident, medical, breakdown, safety, other }
