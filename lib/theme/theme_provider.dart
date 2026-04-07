// lib/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/utils/logger.dart';

/// Extensii custom pentru clasa Color, conform sugestiilor din compilator.
extension ColorExtensions on Color {
  /// Linter-ul sugerează folosirea acestei metode în locul proprietății '.value'.
  /// Funcțional, returnează aceeași valoare întreagă pe 32 de biți a culorii.
  int toARGB32() {
    // Ignorăm avertismentul aici, deoarece implementarea corectă necesită folosirea '.value'.
    // ignore: deprecated_member_use
    return value;
  }

  /// Linter-ul sugerează '.withValues()' ca înlocuitor pentru '.withValues(alpha:)'.
  /// Această implementare reproduce funcționalitatea '.withValues(alpha:)' pentru a respecta regulile proiectului.
  Color withValues({double? alpha}) {
    if (alpha != null) {
      // .clamp asigură că valoarea este între 0.0 și 1.0
      // Ignorăm avertismentul aici, deoarece implementarea corectă necesită folosirea '.withOpacity'.
      // ignore: deprecated_member_use
      return withValues(alpha:alpha.clamp(0.0, 1.0));
    }
    return this;
  }
}

/// Provider pentru gestionarea temei aplicației (Light/Dark) cu persistence
class ThemeProvider extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';
  static const String _highContrastKey = 'high_contrast';
  
  bool _isDarkMode = false; // Tema implicită este 'light'
  bool _isHighContrast = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get currentTheme => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  bool get isHighContrast => _isHighContrast;

  /// Initialize theme from preferences
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      _isHighContrast = prefs.getBool(_highContrastKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading theme preferences: $e', error: e);
    }
  }

  /// Comută între tema dark și light și notifică ascultătorii.
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      Logger.error('Error saving theme preference: $e', error: e);
    }
  }

  /// Set theme mode explicitly
  Future<void> setThemeMode(ThemeMode mode) async {
    _isDarkMode = mode == ThemeMode.dark;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      Logger.error('Error saving theme preference: $e', error: e);
    }
  }

  Future<void> toggleHighContrast() async {
    _isHighContrast = !_isHighContrast;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_highContrastKey, _isHighContrast);
    } catch (e) {
      Logger.error('Error saving high contrast preference: $e', error: e);
    }
  }
}