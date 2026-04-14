import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nabour_app/utils/logger.dart';

/// Apelat la tap pe notificarea locală (ex. heads-up din foreground FCM).
typedef LocalNotificationTapCallback = void Function(String? payload);

class LocalNotificationsService {
  static final LocalNotificationsService _instance = LocalNotificationsService._internal();
  factory LocalNotificationsService() => _instance;
  LocalNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  LocalNotificationTapCallback? _onTap;

  /// Înregistrează înainte de primul tap (ex. din `main` după navigator + push callback).
  void setTapHandler(LocalNotificationTapCallback? handler) {
    _onTap = handler;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      
    );

    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
      Logger.debug('LocalNotification tapped: ${response.payload}',
          tag: 'LocalNotifications');
      _onTap?.call(response.payload);
    });

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'ride_updates',
        'Ride Updates',
        description: 'Notifications for ride updates',
        importance: Importance.high,
      ));
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'chat_messages',
        'Chat Messages',
        description: 'Notifications for neighborhood chat messages',
        importance: Importance.high,
      ));
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'social_proximity',
        'Nearby Contacts',
        description: 'Alert when a contact is very close on the social map',
        importance: Importance.defaultImportance,
      ));
    }

    _initialized = true;
  }

  Future<void> showSimple({
    required String title,
    required String body,
    String? payload,
    String channelId = 'ride_updates',
  }) async {
    await initialize();
    String channelName = 'Ride Updates';
    String channelDescription = 'Notifications for ride updates';
    if (channelId == 'chat_messages') {
      channelName = 'Chat Messages';
      channelDescription = 'Notifications for neighborhood chat messages';
    } else if (channelId == 'social_proximity') {
      channelName = 'Nearby Contacts';
      channelDescription = 'Nearby contacts on the social map';
    }
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );
    final NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details, payload: payload);
  }
}



