import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/utils/logger.dart';
import 'smart_suggestion_model.dart';

/// Serviciu care generează sugestii inteligente de destinații.
/// Bazat pe: adrese salvate, istoric curse, ora zilei, ziua săptămânii.
class SmartSuggestionsService {
  static final SmartSuggestionsService _instance =
      SmartSuggestionsService._();
  factory SmartSuggestionsService() => _instance;
  SmartSuggestionsService._();

  static const String _tag = 'SMART_SUGGESTIONS';
  static const String _historyKey = 'destination_history_v2';
  static const int _maxSuggestions = 5;

  /// Returnează lista de sugestii relevante pentru momentul curent.
  Future<List<SmartSuggestion>> getSuggestions({
    SmartSuggestion? homeAddress,
    SmartSuggestion? workAddress,
  }) async {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday; // 1=Luni, 7=Duminică
    final isWeekend = weekday >= 6;

    final List<SmartSuggestion> suggestions = [];

    // 1. SUGESTII BAZATE PE ORA ZILEI
    if (!isWeekend) {
      if (hour >= 6 && hour <= 9 && workAddress != null) {
        suggestions.add(workAddress);
      } else if (hour >= 16 && hour <= 20 && homeAddress != null) {
        suggestions.add(homeAddress);
      }
    }

    // 2. ADRESA DE ACASĂ (dacă nu e deja adăugată)
    if (homeAddress != null && !suggestions.contains(homeAddress)) {
      suggestions.add(homeAddress);
    }

    // 3. ADRESA DE SERVICIU
    if (workAddress != null && !suggestions.contains(workAddress)) {
      suggestions.add(workAddress);
    }

    // 4. FRECVENTE DIN ISTORIC
    final frequent = await _getFrequentDestinations();
    for (final dest in frequent) {
      if (suggestions.length >= _maxSuggestions) break;
      final isDuplicate = suggestions.any(
        (s) =>
            (s.latitude - dest.latitude).abs() < 0.001 &&
            (s.longitude - dest.longitude).abs() < 0.001,
      );
      if (!isDuplicate) suggestions.add(dest);
    }

    // Evită sute de linii în log la fiecare rebuild MapScreen (înainte era Future nou la fiecare build).
    if (kDebugMode && suggestions.isNotEmpty) {
      Logger.debug('Generated ${suggestions.length} smart suggestions', tag: _tag);
    }
    return suggestions.take(_maxSuggestions).toList();
  }

  /// Înregistrează o destinație folosită pentru a actualiza istoricul.
  Future<void> recordDestinationUsed(SmartSuggestion destination) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      final List<Map<String, dynamic>> history = raw != null
          ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
          : [];

      final existingIndex = history.indexWhere(
        (h) => ((h['latitude'] as double? ?? 0) - destination.latitude).abs() <
            0.001,
      );

      if (existingIndex >= 0) {
        history[existingIndex]['frequencyScore'] =
            (history[existingIndex]['frequencyScore'] ?? 0) + 1;
      } else {
        history.add({...destination.toJson(), 'frequencyScore': 1});
      }

      history.sort((a, b) =>
          (b['frequencyScore'] as int).compareTo(a['frequencyScore'] as int));
      final trimmed = history.take(20).toList();

      await prefs.setString(_historyKey, jsonEncode(trimmed));
    } catch (e) {
      Logger.error('Failed to record destination: $e', tag: _tag, error: e);
    }
  }

  Future<List<SmartSuggestion>> _getFrequentDestinations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null) return [];
      final list =
          (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list
          .map(SmartSuggestion.fromJson)
          .where((s) => s.frequencyScore >= 2)
          .take(3)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
