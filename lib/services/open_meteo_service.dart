import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nabour_app/utils/logger.dart';

/// Open-Meteo client pentru temperatură (fără cheie API).
///
/// Notă: folosește cache in-memory ca să nu facă request la fiecare rebuild.
class OpenMeteoService {
  static final OpenMeteoService _instance = OpenMeteoService._internal();
  factory OpenMeteoService() => _instance;
  OpenMeteoService._internal();

  Future<Map<String, dynamic>?> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&current=temperature_2m,weather_code,is_day'
      '&temperature_unit=celsius'
      '&timezone=auto',
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;

      final data = json.decode(res.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      
      if (current != null) {
        return {
          'temp': (current['temperature_2m'] as num).toDouble(),
          'weatherCode': (current['weather_code'] as num).toInt(),
          'isDay': (current['is_day'] as num).toInt() == 1,
        };
      }
    } catch (e) {
      Logger.error('Open-Meteo fetch failed: $e', tag: 'OpenMeteoService');
    }
    return null;
  }
}

