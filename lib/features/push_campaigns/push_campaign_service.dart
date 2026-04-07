import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/utils/logger.dart';

/// Serviciu pentru notificări push contextuale.
/// Verifică condițiile și trimite notificări la momentul potrivit.
/// Nu trimite mai mult de 1 notificare push per tip per 24h.
class PushCampaignService {
  static final PushCampaignService _instance = PushCampaignService._();
  factory PushCampaignService() => _instance;
  PushCampaignService._();

  static const String _tag = 'PUSH_CAMPAIGN';

  /// Verifică dacă utilizatorul e inactiv >7 zile și trimite promoție.
  Future<void> checkInactiveUser(DateTime? lastRideDate) async {
    if (lastRideDate == null) return;
    final daysSinceLastRide =
        DateTime.now().difference(lastRideDate).inDays;
    if (daysSinceLastRide < 7) return;
    if (!await _canSend('inactive_7d')) return;

    Logger.info('Sending inactive user push ($daysSinceLastRide days)',
        tag: _tag);
    // PushNotificationService().sendLocalNotification(
    //   title: 'Te-ai gândit la o cursă? 🚗',
    //   body: 'Nu ai mai călătorit de $daysSinceLastRide zile. Ai 20% reducere azi!',
    // );
    await _markSent('inactive_7d');
  }

  /// Verifică traficul și notifică utilizatorul că șoferii sunt disponibili.
  Future<void> notifyHighSupply(int availableDrivers) async {
    if (availableDrivers < 5) return;
    final hour = DateTime.now().hour;
    if (hour < 7 || hour > 22) return; // nu deranja noaptea
    if (!await _canSend('high_supply')) return;

    Logger.info(
        'Sending high supply push: $availableDrivers drivers', tag: _tag);
    // PushNotificationService().sendLocalNotification(
    //   title: 'Șoferi disponibili în zona ta!',
    //   body: '$availableDrivers șoferi sunt aproape. Comandă acum!',
    // );
    await _markSent('high_supply');
  }

  /// Notifică șoferul când are o perioadă bună de câștiguri.
  Future<void> notifyDriverPeakHour() async {
    final hour = DateTime.now().hour;
    // Ore de vârf: 7-9 dimineața, 17-20 seara
    final isPeak =
        (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 20);
    if (!isPeak) return;
    if (!await _canSend('driver_peak_hour')) return;

    Logger.info('Notifying driver of peak hour ($hour:00)', tag: _tag);
    await _markSent('driver_peak_hour');
  }

  Future<bool> _canSend(String campaignKey) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSent = prefs.getString('push_campaign_$campaignKey');
    if (lastSent == null) return true;
    final lastSentDate = DateTime.tryParse(lastSent);
    if (lastSentDate == null) return true;
    return DateTime.now().difference(lastSentDate).inHours >= 24;
  }

  Future<void> _markSent(String campaignKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'push_campaign_$campaignKey', DateTime.now().toIso8601String());
  }
}
