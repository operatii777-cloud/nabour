import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nabour_app/utils/logger.dart';

class LocalNotificationsService {
  static final LocalNotificationsService _instance = LocalNotificationsService._internal();
  factory LocalNotificationsService() => _instance;
  LocalNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

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
    });

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'ride_updates',
        'Ride Updates',
        description: 'Notificări pentru actualizări de cursă',
        importance: Importance.high,
      ));
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'chat_messages',
        'Mesaje Chat',
        description: 'Notificări pentru mesaje de chat între vecini',
        importance: Importance.high,
      ));
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'social_proximity',
        'Aproape de prieteni',
        description: 'Alertă când un contact e foarte aproape pe harta socială',
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
    String channelDescription = 'Notificări pentru actualizări de cursă';
    if (channelId == 'chat_messages') {
      channelName = 'Mesaje Chat';
      channelDescription = 'Notificări pentru mesaje de chat între vecini';
    } else if (channelId == 'social_proximity') {
      channelName = 'Aproape de prieteni';
      channelDescription = 'Contacte aproape pe harta socială';
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



