import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nabour_app/core/haptics/haptic_service.dart';
import 'package:nabour_app/utils/logger.dart';
import 'waiting_timer_model.dart';

/// Serviciu singleton care gestionează timer-ul de așteptare pasager.
/// Pornit automat când șoferul marchează "Am ajuns la pasager".
/// Oprit când pasagerul urcă în mașină.
class WaitingTimerService extends ChangeNotifier {
  static final WaitingTimerService _instance = WaitingTimerService._();
  factory WaitingTimerService() => _instance;
  WaitingTimerService._();

  static const String _tag = 'WAITING_TIMER';

  WaitingTimerState _state = const WaitingTimerState();
  Timer? _ticker;

  WaitingTimerState get state => _state;

  /// Pornește timer-ul. Apelat din map_screen.dart când șoferul ajunge la pickup.
  void start() {
    if (_state.isActive) return;
    Logger.info('Waiting timer started', tag: _tag);
    _state =
        _state.copyWith(isActive: true, elapsedSeconds: 0, currentCharge: 0.0);
    notifyListeners();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final newElapsed = _state.elapsedSeconds + 1;
      double newCharge = 0.0;

      if (newElapsed > _state.freeWaitingSeconds) {
        final chargeableSecs = newElapsed - _state.freeWaitingSeconds;
        newCharge = (chargeableSecs / 60) * _state.chargePerMinute;
      }

      _state = _state.copyWith(
        elapsedSeconds: newElapsed,
        currentCharge: newCharge,
      );

      // Notificări la momente cheie
      if (newElapsed == 60) {
        Logger.debug('1 minute elapsed — notify passenger', tag: _tag);
        HapticService.instance.notification();
        _onOneMinuteWarning();
      }
      if (newElapsed == _state.freeWaitingSeconds) {
        Logger.debug('Free waiting expired — charging starts', tag: _tag);
        HapticService.instance.error();
        _onFreeWaitingExpired();
      }

      notifyListeners();
    });
  }

  /// Oprește timer-ul. Apelat când pasagerul urcă.
  /// Returnează taxa acumulată (RON) pentru a o adăuga la prețul final.
  double stop() {
    _ticker?.cancel();
    _ticker = null;
    final finalCharge = _state.currentCharge;
    Logger.info('Waiting timer stopped. Charge: $finalCharge RON', tag: _tag);
    _state = const WaitingTimerState();
    notifyListeners();
    return finalCharge;
  }

  /// Callback intern — trimite notificare push pasagerului la 1 minut
  void _onOneMinuteWarning() {
    // PushNotificationService().sendLocalNotification(
    //   title: 'Șoferul tău te așteaptă',
    //   body: 'Mai ai 1 minut gratuit. Grăbește-te!',
    // );
  }

  /// Callback intern — taxare începe
  void _onFreeWaitingExpired() {
    // Notificare pasager: "Ai depășit cele 2 minute gratuite. Taxa de așteptare a început."
  }
}
