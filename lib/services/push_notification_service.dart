import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/services/local_notifications_service.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Serviciu complet pentru Push Notifications cu Firebase Cloud Messaging
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // Lazy getters — accessed only after Firebase.initializeApp() has completed
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  String? _fcmToken;
  bool _isInitialized = false;
  
  /// Callback for navigation - set by app to handle navigation
  Function(String messageType, Map<String, dynamic> data)? onNavigate;
  
  /// Getter for initialization status
  bool get isInitialized => _isInitialized;
  
  /// Getter for Firebase Functions
  FirebaseFunctions get functions => _functions;

  /// Initialize push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        await _saveTokenToFirestore(_fcmToken!);
        Logger.info('FCM token obtained: ${_fcmToken!.substring(0, 20)}...', tag: 'PushNotifications');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToFirestore(newToken);
        Logger.info('FCM token refreshed', tag: 'PushNotifications');
      });

      // Setup message handlers
      await _setupMessageHandlers();

      _isInitialized = true;
      Logger.info('Push notification service initialized', tag: 'PushNotifications');
    } catch (e) {
      Logger.error('Error initializing push notifications', error: e, tag: 'PushNotifications');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        Logger.info('Notification permissions granted', tag: 'PushNotifications');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        Logger.info('Provisional notification permissions granted', tag: 'PushNotifications');
      } else {
        Logger.warning('Notification permissions denied', tag: 'PushNotifications');
      }
    } catch (e) {
      Logger.error('Error requesting notification permissions', error: e, tag: 'PushNotifications');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _db.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      Logger.info('FCM token saved to Firestore', tag: 'PushNotifications');
    } catch (e) {
      Logger.error('Error saving FCM token', error: e, tag: 'PushNotifications');
    }
  }

  /// Setup message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.info('Foreground message received: ${message.notification?.title}', tag: 'PushNotifications');
      _handleForegroundMessage(message);
    });

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Logger.info('App opened from notification: ${message.notification?.title}', tag: 'PushNotifications');
      _handleNotificationTap(message);
    });

    // Handle initial message if app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Logger.info('Initial message: ${initialMessage.notification?.title}', tag: 'PushNotifications');
      _handleInitialMessage(initialMessage);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // Handle different message types
    final messageType = message.data['type'];
    final notification = message.notification;
    final title = notification?.title ?? 'Notificare';
    final body = notification?.body ?? 'Actualizare nouă';

    switch (messageType) {
      case 'ride_assignment':
        _handleRideAssignment(message);
        LocalNotificationsService().showSimple(title: title, body: body, payload: message.data.toString());
        break;
      case 'ride_update':
        _handleRideUpdate(message);
        LocalNotificationsService().showSimple(title: title, body: body, payload: message.data.toString());
        break;
      case 'chat_message':
        _handleChatMessage(message);
        LocalNotificationsService().showSimple(
          title: title,
          body: body,
          payload: message.data.toString(),
          channelId: 'chat_messages',
        );
        break;
      case 'emergency':
        _handleEmergency(message);
        LocalNotificationsService().showSimple(title: title, body: body, payload: message.data.toString());
        break;
      case 'neighborhood_chat':
        // Ignoră notificarea dacă e propriul mesaj (sender == current user)
        final senderUid = message.data['senderUid'];
        final myUid = _auth.currentUser?.uid;
        if (senderUid != null && senderUid == myUid) break;
        LocalNotificationsService().showSimple(
          title: title,
          body: body,
          payload: message.data.toString(),
          channelId: 'chat_messages',
        );
        break;
      case 'radar_group_message':
        LocalNotificationsService().showSimple(
          title: title,
          body: body,
          payload: message.data.toString(),
          channelId: 'chat_messages',
        );
        break;
      case 'community_mystery_opened':
        LocalNotificationsService().showSimple(
          title: title,
          body: body,
          payload: message.data.toString(),
        );
        break;
      default:
        LocalNotificationsService().showSimple(title: title, body: body, payload: message.data.toString());
        Logger.debug('Unknown message type: $messageType', tag: 'PushNotifications');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final messageType = message.data['type'];
    final rideId = message.data['rideId'];
    
    // ✅ IMPLEMENTED: Navigate to appropriate screen based on message type
    Logger.info('Notification tapped: $messageType for ride $rideId', tag: 'PushNotifications');
    
    if (onNavigate != null) {
      onNavigate!(messageType ?? 'unknown', message.data);
    } else {
      Logger.warning('Navigation callback not set. Set PushNotificationService().onNavigate to handle navigation.', tag: 'PushNotifications');
    }
  }
  
  /// Set navigation callback
  void setNavigationCallback(Function(String messageType, Map<String, dynamic> data) callback) {
    onNavigate = callback;
  }

  /// Handle initial message
  void _handleInitialMessage(RemoteMessage message) {
    _handleNotificationTap(message);
  }

  /// Handle ride assignment notification
  void _handleRideAssignment(RemoteMessage message) {
    final rideId = message.data['rideId'];
    final distanceKm = message.data['distanceKm'];
    Logger.info('Ride assignment: $rideId, distance: $distanceKm km', tag: 'PushNotifications');
  }

  /// Handle ride update notification
  void _handleRideUpdate(RemoteMessage message) {
    final rideId = message.data['rideId'];
    final status = message.data['status'];
    Logger.info('Ride update: $rideId, status: $status', tag: 'PushNotifications');
  }

  /// Handle chat message notification
  void _handleChatMessage(RemoteMessage message) {
    final rideId = message.data['rideId'];
    final senderName = message.data['senderName'];
    Logger.info('Chat message: $rideId from $senderName', tag: 'PushNotifications');
  }

  /// Handle emergency notification
  void _handleEmergency(RemoteMessage message) {
    final rideId = message.data['rideId'];
    final emergencyType = message.data['emergencyType'];
    Logger.warning('Emergency: $rideId, type: $emergencyType', tag: 'PushNotifications');
  }

  /// Send notification to driver about ride assignment
  static Future<void> triggerDriverAssignment({
    required String driverId,
    required String rideId,
    required double distanceKm,
  }) async {
    try {
      final instance = PushNotificationService();
      if (!instance._isInitialized) {
        await instance.initialize();
      }

      // Call Cloud Function to send notification
      final callable = instance._functions.httpsCallable('sendDriverNotification');
      await callable.call({
        'driverId': driverId,
        'rideId': rideId,
        'type': 'ride_assignment',
        'distanceKm': distanceKm,
        'title': 'Nouă ofertă de cursă',
        'body': 'Ai primit o ofertă de cursă la ${distanceKm.toStringAsFixed(1)} km distanță',
      });

      Logger.info('Driver assignment notification sent: $driverId for ride $rideId', tag: 'PushNotifications');
    } catch (e) {
      Logger.error('Error sending driver assignment notification', error: e, tag: 'PushNotifications');
      Logger.debug(
        '[PUSH] Notify driver $driverId ride $rideId (${distanceKm.toStringAsFixed(1)} km)',
        tag: 'PushNotifications',
      );
    }
  }

  /// Send push notification for a new chat message.
  /// Looks up the recipient's FCM token and sends via Cloud Function.
  static Future<void> sendChatMessageNotification({
    required String recipientId,
    required String senderName,
    required String messageText,
    required String rideId,
  }) async {
    try {
      final instance = PushNotificationService();
      if (!instance._isInitialized) await instance.initialize();

      // Get recipient FCM token
      final userDoc = await instance._db.collection('users').doc(recipientId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) return;

      final callable = instance._functions.httpsCallable('sendChatNotification');
      await callable.call({
        'token': fcmToken,
        'rideId': rideId,
        'senderName': senderName,
        'messageText': messageText.length > 100
            ? '${messageText.substring(0, 97)}...'
            : messageText,
        'title': senderName,
        'body': messageText,
      });
    } catch (e) {
      // Cloud Function not deployed — silently ignore
      Logger.debug('Chat push skipped (no Cloud Function): $e', tag: 'PushNotifications');
    }
  }

  /// Send notification to driver about timeout
  static Future<void> triggerDriverTimeout({
    required String driverId,
    required String rideId,
  }) async {
    try {
      final instance = PushNotificationService();
      if (!instance._isInitialized) {
        await instance.initialize();
      }

      final callable = instance._functions.httpsCallable('sendDriverNotification');
      await callable.call({
        'driverId': driverId,
        'rideId': rideId,
        'type': 'ride_timeout',
        'title': 'Ofertă expirată',
        'body': 'Timpul pentru acceptarea ofertei a expirat',
      });

      Logger.info('Driver timeout notification sent: $driverId for ride $rideId', tag: 'PushNotifications');
    } catch (e) {
      Logger.error('Error sending driver timeout notification', error: e, tag: 'PushNotifications');
      Logger.debug('[PUSH] Driver timeout ride $rideId driver $driverId', tag: 'PushNotifications');
    }
  }

  /// Send notification to passenger about no driver found
  static Future<void> notifyPassengerNoDriver({
    required String passengerId,
    required String rideId,
  }) async {
    try {
      final instance = PushNotificationService();
      if (!instance._isInitialized) {
        await instance.initialize();
      }

      final callable = instance._functions.httpsCallable('sendPassengerNotification');
      await callable.call({
        'passengerId': passengerId,
        'rideId': rideId,
        'type': 'no_driver',
        'title': 'Căutăm șofer',
        'body': 'Căutăm un șofer disponibil pentru cursa ta',
      });

      Logger.info('Passenger no driver notification sent: $passengerId for ride $rideId', tag: 'PushNotifications');
    } catch (e) {
      Logger.error('Error sending passenger notification', error: e, tag: 'PushNotifications');
      Logger.debug(
        '[PUSH] Passenger $passengerId ride $rideId — căutare alt șofer',
        tag: 'PushNotifications',
      );
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;
}
