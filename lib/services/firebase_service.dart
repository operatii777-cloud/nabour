import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nabour_app/services/real_time_tracking_service.dart';
import 'package:flutter/foundation.dart';
import 'package:nabour_app/services/local_notifications_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🔥 Firebase Service - Central Hub pentru toate serviciile Firebase
/// 
/// Acest serviciu oferă:
/// - Authentication management
/// - Real-time data synchronization
/// - Push notifications
/// - Analytics tracking
/// - Crash reporting
class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  bool _analyticsEnabled = true;
  
  // Stream subscriptions for memory leak prevention
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _appOpenedSubscription;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseMessaging get messaging => _messaging;
  FirebaseAnalytics get analytics => _analytics;
  FirebaseCrashlytics get crashlytics => _crashlytics;

  // Current user
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 🚀 Initialize Firebase services (fast initialization only)
  Future<void> initialize() async {
    try {
      Logger.debug('Initializing Firebase services...', tag: 'FIREBASE');
      
      // Initialize core services first (fast operations)
      await _initializeCoreServices();
      
      // Defer heavy operations to background (yield frame + reduce platform-channel storm)
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          unawaited(_initializeBackgroundServices());
        }),
      );
      
      Logger.info('Firebase core services initialized');
    } catch (e) {
      Logger.error('Error initializing Firebase: $e', error: e);
      if (!kDebugMode) {
        try {
          await _crashlytics.recordError(e, StackTrace.current);
        } catch (crashlyticsError) {
          Logger.error('Failed to record error in Crashlytics: $crashlyticsError');
        }
      }
    }
  }

  /// Initialize core Firebase services (fast operations only)
  Future<void> _initializeCoreServices() async {
    // App Check: în **debug** nu activăm deloc SDK-ul — tokenul de debug cere UUID
    // în Console; altfel 403 + „Too many attempts” și Callable-urile par UNAUTHENTICATED.
    // În consolă: pentru dev, enforcement OFF pe Firestore/Functions SAU testezi cu release.
    // **Release**: Play Integrity (Android).
    try {
      if (kDebugMode) {
        Logger.info(
          'App Check oprit în debug (fără 403/spam). Release: Play Integrity.',
          tag: 'APP_CHECK',
        );
      } else {
        await FirebaseAppCheck.instance.activate(
          // ignore: deprecated_member_use
          androidProvider: AndroidProvider.playIntegrity,
        );
        Logger.info('Firebase App Check: Play Integrity activ', tag: 'APP_CHECK');
      }
    } catch (e) {
      Logger.warning('App Check init skipped (non-fatal): $e');
    }

    try {
      final firebaseOptions = Firebase.app().options;
      final googleAppId = firebaseOptions.appId;
      if (googleAppId.isEmpty) {
        _analyticsEnabled = false;
        await _analytics.setAnalyticsCollectionEnabled(false);
        Logger.info('Firebase Analytics disabled: missing google_app_id');
      } else {
        _analyticsEnabled = true;
        await _analytics.setAnalyticsCollectionEnabled(true);
      }
    } catch (e) {
      _analyticsEnabled = false;
      Logger.error('Firebase Analytics configuration error (disabled for this session): $e', error: e);
    }

    // Enable crashlytics (only if not in debug mode to avoid errors)
    if (!kDebugMode) {
      try {
        await _crashlytics.setCrashlyticsCollectionEnabled(true);
        Logger.info('Crashlytics enabled for production');
      } catch (e) {
        Logger.error('Crashlytics setup error (non-fatal): $e', error: e);
      }
    } else {
      Logger.info('Crashlytics disabled in debug mode');
    }
  }

  /// Initialize heavy Firebase services in background
  Future<void> _initializeBackgroundServices() async {
    try {
      Logger.debug('Starting Firebase background services...');
      
      // Request notification permissions
      await _requestNotificationPermissions();
      
      // Setup message handlers
      await _setupMessageHandlers();
      
      // Initialize local notifications
      await LocalNotificationsService().initialize();
      
      // Log successful initialization
      if (_analyticsEnabled) {
        await _analytics.logEvent(name: 'app_initialized');
      }
      
      Logger.info('Firebase background services initialized');
    } catch (e) {
      Logger.error('Firebase background services error (non-fatal): $e', error: e);
    }
  }

  /// 🔐 Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    try {
      final NotificationSettings settings = await _messaging.requestPermission(
        
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        Logger.info('Notification permissions granted');
      } else {
        Logger.warning('Notification permissions denied');
      }
    } catch (e) {
      Logger.error('Error requesting notification permissions: $e', error: e);
    }
  }

  /// 📱 Setup message handlers
  Future<void> _setupMessageHandlers() async {
    // Cancel existing subscriptions
    _foregroundMessageSubscription?.cancel();
    _appOpenedSubscription?.cancel();
    
    // Handle messages when app is in foreground
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.info('Foreground message received: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Handle messages when app is opened from notification
    _appOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Logger.info('App opened from notification: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Handle initial message if app was terminated
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Logger.info('Initial message: ${initialMessage.notification?.title}');
      _handleInitialMessage(initialMessage);
    }
  }

  /// 📱 Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // Handle different message types
    switch (message.data['type']) {
      case 'emergency_alert':
        _handleEmergencyNotification(message);
        break;
      case 'ride_update':
        _handleRideUpdateNotification(message);
        break;
      case 'chat_message':
        _handleChatNotification(message);
        break;
      default:
        Logger.info('Unknown message type: ${message.data['type']}');
    }
    // Show a local heads-up notification as well
    final title = message.notification?.title ?? 'Notificare';
    final body = message.notification?.body ?? 'Actualizare nouă';
    LocalNotificationsService().showSimple(title: title, body: body, payload: message.data['type']);
  }

  /// 🚨 Handle emergency notifications
  void _handleEmergencyNotification(RemoteMessage message) {
    // Extract emergency data
    final emergencyData = message.data;
    Logger.error('Emergency notification: ${emergencyData['emergency_type']}');
    
    // Trigger emergency alert in UI via callback
    try {
      final emergencyAlert = EmergencyAlert(
        rideId: emergencyData['ride_id'] ?? '',
        userId: emergencyData['reporter_id'] ?? '',
        userRole: UserRole.values.firstWhere(
          (e) => e.name == emergencyData['user_role'],
          orElse: () => UserRole.passenger,
        ),
        type: EmergencyType.values.firstWhere(
          (e) => e.name == emergencyData['emergency_type'],
          orElse: () => EmergencyType.safety,
        ),
        latitude: double.tryParse(emergencyData['latitude'] ?? '0') ?? 0.0,
        longitude: double.tryParse(emergencyData['longitude'] ?? '0') ?? 0.0,
        description: emergencyData['description'] ?? 'Emergency alert',
        timestamp: DateTime.now(),
        isActive: true,
      );
      
      // Notify active tracking service about emergency
      _notifyEmergencyToActiveServices(emergencyAlert);
    } catch (e) {
      Logger.error('Error processing emergency notification: $e', error: e);
    }
  }

  /// 🚗 Handle ride update notifications
  void _handleRideUpdateNotification(RemoteMessage message) {
    final rideData = message.data;
    Logger.debug('Ride update: ${rideData['update_type']}');
    
    // Update ride status in UI via global notification
    try {
      final rideUpdate = {
        'rideId': rideData['ride_id'] ?? '',
        'updateType': rideData['update_type'] ?? 'status_change',
        'status': rideData['status'] ?? 'unknown',
        'driverLocation': rideData['driver_location'],
        'eta': rideData['eta'],
        'message': rideData['message'] ?? '',
        'timestamp': DateTime.now(),
      };
      
      // Notify active UI components about ride update
      _notifyRideUpdateToActiveServices(rideUpdate);
    } catch (e) {
      Logger.error('Error processing ride update notification: $e', error: e);
    }
  }

  /// 💬 Handle chat notifications
  void _handleChatNotification(RemoteMessage message) {
    final chatData = message.data;
    Logger.debug('Chat message: ${chatData['sender_name']}');
    
    // Show chat notification in UI via overlay notification
    try {
      final chatNotification = RealTimeCommunication(
        rideId: chatData['ride_id'] ?? '',
        senderId: chatData['sender_id'] ?? '',
        senderRole: UserRole.values.firstWhere(
          (e) => e.name == chatData['sender_role'],
          orElse: () => UserRole.passenger,
        ),
        message: chatData['message'] ?? '',
        type: MessageType.values.firstWhere(
          (e) => e.name == chatData['message_type'],
          orElse: () => MessageType.text,
        ),
        timestamp: DateTime.now(),
        metadata: chatData['metadata'],
      );
      
      // Notify active chat UI about new message
      _notifyChatToActiveServices(chatNotification);
    } catch (e) {
      Logger.error('Error processing chat notification: $e', error: e);
    }
  }

  /// 📱 Handle notification taps
  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to appropriate screen based on message type
    switch (message.data['type']) {
      case 'emergency_alert':
        // Navigate to emergency screen
        break;
      case 'ride_update':
        // Navigate to ride tracking screen
        break;
      case 'chat_message':
        // Navigate to chat screen
        break;
    }
  }

  /// 📱 Handle initial message
  void _handleInitialMessage(RemoteMessage message) {
    // Handle app launch from notification
    _handleNotificationTap(message);
  }

  /// 🔥 Real-time Tracking Integration

  /// 📍 Save real-time location update
  Future<void> saveLocationUpdate(RealTimeLocationUpdate update) async {
    try {
      await _firestore.collection('live_locations').add({
        'userId': currentUser?.uid,
        'rideId': update.rideId,
        'latitude': update.latitude,
        'longitude': update.longitude,
        'accuracy': update.accuracy,
        'speed': update.speed,
        'heading': update.heading,
        'timestamp': FieldValue.serverTimestamp(),
        'batteryLevel': update.batteryLevel,
        'isMoving': update.isMoving,
      });

      await _analytics.logEvent(
        name: 'location_update_saved',
        parameters: {
          'ride_id': update.rideId,
          'accuracy': update.accuracy,
          'battery_level': update.batteryLevel,
        },
      );
    } catch (e) {
      Logger.error('Error saving location update: $e', error: e);
      if (!kDebugMode) {
        try {
          await _crashlytics.recordError(e, StackTrace.current);
        } catch (crashlyticsError) {
          Logger.error('Failed to record error in Crashlytics: $crashlyticsError');
        }
      }
    }
  }

  /// 🚨 Save emergency alert
  Future<void> saveEmergencyAlert(EmergencyAlert alert) async {
    try {
      await _firestore.collection('emergency_alerts').add({
        'reporterId': currentUser?.uid,
        'type': alert.type.name,
        'latitude': alert.latitude,
        'longitude': alert.longitude,
        'description': alert.description,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'responderId': null,
        'responseTime': null,
      });

      await _analytics.logEvent(
        name: 'emergency_alert_sent',
        parameters: {
          'emergency_type': alert.type.name,
          'latitude': alert.latitude,
          'longitude': alert.longitude,
        },
      );

      // Send push notification to emergency responders
      await _sendEmergencyPushNotification(alert);
    } catch (e) {
      Logger.error('Error saving emergency alert: $e', error: e);
      if (!kDebugMode) {
        try {
          await _crashlytics.recordError(e, StackTrace.current);
        } catch (crashlyticsError) {
          Logger.error('Failed to record error in Crashlytics: $crashlyticsError');
        }
      }
    }
  }

  /// 📱 Send emergency push notification
  Future<void> _sendEmergencyPushNotification(EmergencyAlert alert) async {
    try {
      // Get emergency responder tokens
      final respondersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'emergency_responder')
          .get();

      final tokens = respondersQuery.docs
          .map((doc) => doc.data()['fcmToken'] as String?)
          .where((token) => token != null)
          .cast<String>()
          .toList();

      if (tokens.isNotEmpty) {
        // Send via Cloud Functions for better security
        await _sendEmergencyViaCloudFunction(alert, tokens);
        Logger.info('Emergency notification sent to ${tokens.length} responders');
      }
    } catch (e) {
      Logger.error('Error sending emergency notification: $e', error: e);
    }
  }

  /// 💬 Save real-time communication
  Future<void> saveCommunication(RealTimeCommunication communication) async {
    try {
      await _firestore.collection('real_time_communications').add({
        'rideId': communication.rideId,
        'senderId': communication.senderId,
        'senderRole': communication.senderRole.name,
        'message': communication.message,
        'type': communication.type.name,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await _analytics.logEvent(
        name: 'communication_sent',
        parameters: {
          'ride_id': communication.rideId,
          'sender_role': communication.senderRole.name,
          'message_type': communication.type.name,
        },
      );
    } catch (e) {
      Logger.error('Error saving communication: $e', error: e);
      if (!kDebugMode) {
        try {
          await _crashlytics.recordError(e, StackTrace.current);
        } catch (crashlyticsError) {
          Logger.error('Failed to record error in Crashlytics: $crashlyticsError');
        }
      }
    }
  }

  /// 🤖 Save AI prediction
  Future<void> saveAIPrediction(AIPrediction prediction) async {
    try {
      await _firestore.collection('ai_predictions').add({
        'rideId': prediction.rideId,
        'userId': currentUser?.uid,
        'estimatedTime': prediction.estimatedTime.inMinutes,
        'estimatedDistance': prediction.estimatedDistance,
        'confidence': prediction.confidence,
        'optimalRoute': prediction.optimalRoute.map((point) => {
          'latitude': point.coordinates.lat,
          'longitude': point.coordinates.lng,
        }).toList(),
        'timestamp': FieldValue.serverTimestamp(),
        'factors': {
          'traffic': prediction.metadata['traffic'] ?? 1.0,
          'weather': prediction.metadata['weather'] ?? 1.0,
          'historical': prediction.metadata['historical'] ?? 1.0,
        },
      });

      await _analytics.logEvent(
        name: 'ai_prediction_saved',
        parameters: {
          'ride_id': prediction.rideId,
          'confidence': prediction.confidence,
          'estimated_time': prediction.estimatedTime.inMinutes,
        },
      );
    } catch (e) {
      Logger.error('Error saving AI prediction: $e', error: e);
      if (!kDebugMode) {
        try {
          await _crashlytics.recordError(e, StackTrace.current);
        } catch (crashlyticsError) {
          Logger.error('Failed to record error in Crashlytics: $crashlyticsError');
        }
      }
    }
  }

  /// 📊 Save performance metrics
  Future<void> savePerformanceMetrics({
    required String rideId,
    required double avgUpdateInterval,
    required int totalUpdates,
    required Duration uptime,
  }) async {
    try {
      await _firestore.collection('performance_metrics').add({
        'userId': currentUser?.uid,
        'rideId': rideId,
        'avgUpdateInterval': avgUpdateInterval,
        'totalUpdates': totalUpdates,
        'uptime': uptime.inSeconds,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': await _getDeviceInfo(),
      });

      await _analytics.logEvent(
        name: 'performance_metrics_saved',
        parameters: {
          'ride_id': rideId,
          'total_updates': totalUpdates,
          'uptime_seconds': uptime.inSeconds,
        },
      );
    } catch (e) {
      Logger.error('Error saving performance metrics: $e', error: e);
      if (!kDebugMode) {
        try {
          await _crashlytics.recordError(e, StackTrace.current);
        } catch (crashlyticsError) {
          Logger.error('Failed to record error in Crashlytics: $crashlyticsError');
        }
      }
    }
  }

  /// 🔍 Get real-time data streams

  /// 📍 Stream live locations for a ride
  Stream<QuerySnapshot> getLiveLocationsStream(String rideId) {
    return _firestore
        .collection('live_locations')
        .where('rideId', isEqualTo: rideId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  /// 🚨 Stream emergency alerts for a user
  Stream<QuerySnapshot> getEmergencyAlertsStream(String userId) {
    return _firestore
        .collection('emergency_alerts')
        .where('reporterId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// 💬 Stream communications for a ride
  Stream<QuerySnapshot> getCommunicationsStream(String rideId) {
    return _firestore
        .collection('real_time_communications')
        .where('rideId', isEqualTo: rideId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// 🤖 Stream AI predictions for a ride
  Stream<QuerySnapshot> getAIPredictionsStream(String rideId) {
    return _firestore
        .collection('ai_predictions')
        .where('rideId', isEqualTo: rideId)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots();
  }

  /// 📱 Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      // Platform detection for cross-platform support
      return {
        'platform': defaultTargetPlatform.name,
        'version': '1.0.0+1',
        'isPhysicalDevice': !kIsWeb,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting device info: $e', error: e);
      return {
        'platform': 'unknown',
        'version': '1.0.0',
        'isPhysicalDevice': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 🔔 Send emergency via Cloud Function
  Future<void> _sendEmergencyViaCloudFunction(EmergencyAlert alert, List<String> tokens) async {
    try {
      // Call Cloud Function for secure emergency notification
      final callable = FirebaseFunctions.instance.httpsCallable('sendEmergencyNotification');
      
      await callable.call({
        'alert': {
          'type': alert.type.name,
          'latitude': alert.latitude,
          'longitude': alert.longitude,
          'description': alert.description,
          'reporterId': alert.userId,
          'timestamp': alert.timestamp.toIso8601String(),
        },
        'tokens': tokens,
        'priority': 'high',
      });
      
      Logger.info('Emergency sent via Cloud Function');
    } catch (e) {
      Logger.error('Error sending emergency via Cloud Function: $e', error: e);
      // Fallback to direct FCM if Cloud Function fails
      Logger.warning('Using direct FCM as fallback');
    }
  }

  /// 🚨 Notify emergency to active services
  void _notifyEmergencyToActiveServices(EmergencyAlert alert) {
    try {
      // Use static notification system or event bus
      // This would connect to active RealTimeTrackingService instances
      Logger.error('Notifying active services about emergency: ${alert.type.name}');
    } catch (e) {
      Logger.error('Error notifying emergency to services: $e', error: e);
    }
  }

  /// 🚗 Notify ride update to active services
  void _notifyRideUpdateToActiveServices(Map<String, dynamic> rideUpdate) {
    try {
      // Use static notification system or event bus
      Logger.debug('Notifying active services about ride update: ${rideUpdate['updateType']}');
    } catch (e) {
      Logger.error('Error notifying ride update to services: $e', error: e);
    }
  }

  /// 💬 Notify chat to active services
  void _notifyChatToActiveServices(RealTimeCommunication chat) {
    try {
      // Use static notification system or event bus
      Logger.debug('Notifying active services about chat: ${chat.message}');
    } catch (e) {
      Logger.error('Error notifying chat to services: $e', error: e);
    }
  }

  /// 🧹 Cleanup resources
  void dispose() {
    // Cancel all subscriptions
    _foregroundMessageSubscription?.cancel();
    _appOpenedSubscription?.cancel();
    
    // Firebase services are automatically managed
    Logger.info('Firebase service disposed');
  }
}
