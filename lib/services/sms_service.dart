import 'package:cloud_functions/cloud_functions.dart';
import 'package:nabour_app/utils/logger.dart';

/// Serviciu pentru SMS Notifications (ride updates, emergency)
/// Folosește Cloud Functions pentru trimiterea SMS-urilor
class SmsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Trimite SMS pentru ride update
  Future<bool> sendRideUpdateSms({
    required String phoneNumber,
    required String message,
    String? rideId,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendSms');
      await callable.call({
        'phoneNumber': phoneNumber,
        'message': message,
        'type': 'ride_update',
        if (rideId != null) 'rideId': rideId,
      });

      Logger.info('SMS sent to $phoneNumber', tag: 'SMS');
      return true;
    } catch (e) {
      Logger.error('Error sending SMS', error: e, tag: 'SMS');
      return false;
    }
  }

  /// Trimite SMS pentru emergency
  Future<bool> sendEmergencySms({
    required String phoneNumber,
    required String message,
    required String emergencyType,
    String? rideId,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendSms');
      await callable.call({
        'phoneNumber': phoneNumber,
        'message': message,
        'type': 'emergency',
        'emergencyType': emergencyType,
        if (rideId != null) 'rideId': rideId,
      });

      Logger.info('Emergency SMS sent to $phoneNumber', tag: 'SMS');
      return true;
    } catch (e) {
      Logger.error('Error sending emergency SMS', error: e, tag: 'SMS');
      return false;
    }
  }

  /// Trimite SMS pentru reminder cursă programată
  Future<bool> sendScheduledRideReminderSms({
    required String phoneNumber,
    required String rideDetails,
    required DateTime scheduledTime,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendSms');
      await callable.call({
        'phoneNumber': phoneNumber,
        'message': 'Reminder: Cursă programată la ${scheduledTime.toString()}. $rideDetails',
        'type': 'scheduled_ride_reminder',
      });

      Logger.info('Scheduled ride reminder SMS sent to $phoneNumber', tag: 'SMS');
      return true;
    } catch (e) {
      Logger.error('Error sending scheduled ride reminder SMS', error: e, tag: 'SMS');
      return false;
    }
  }
}

