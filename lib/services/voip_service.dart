import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nabour_app/utils/logger.dart';

class VoipService {
  static final VoipService _instance = VoipService._internal();
  factory VoipService() => _instance;
  VoipService._internal();

  /// Deschide dialerul nativ cu numărul primit.
  /// [dialNumber] poate fi un număr proxy/mascat; [phoneNumber] e cel afișat în UI.
  Future<bool> startCall({
    required String phoneNumber,
    required String contactName,
    required BuildContext context,
    String? dialNumber,
  }) async {
    try {
      final number = (dialNumber ?? phoneNumber).trim();
      final uri = Uri(scheme: 'tel', path: number);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        Logger.info('VoipService: apel inițiat către $number ($contactName)');
        return true;
      } else {
        Logger.error('VoipService: nu se poate lansa tel: $number');
        return false;
      }
    } catch (e) {
      Logger.error('VoipService: eroare apel: $e', error: e);
      return false;
    }
  }

  void dispose() {}
}
