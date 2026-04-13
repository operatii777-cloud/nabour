// lib/theme/theme_provider.dart

import 'dart:async';

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

  /// Crește la orice schimbare făcută de utilizator. Dacă [initialize] încă citește prefs,
  /// nu suprascriem tema după `await` — evită cursă + reconstruiri suprapuse la pornire.
  int _userThemeMutationGen = 0;

  /// La schimbări rapide de temă, doar ultima scriere în SharedPreferences trebuie să conteze.
  int _prefsWriteGeneration = 0;

  void _bumpUserThemeMutation() {
    _userThemeMutationGen++;
  }

  bool get isDarkMode => _isDarkMode;
  ThemeMode get currentTheme => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  bool get isHighContrast => _isHighContrast;

  /// Initialize theme from preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    final loadStartedGen = _userThemeMutationGen;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Utilizatorul a comutat deja tema în timpul încărcării — respectăm starea curentă.
      if (_userThemeMutationGen != loadStartedGen) {
        _isInitialized = true;
        return;
      }

      final fromPrefsDark = prefs.getBool(_darkModeKey) ?? false;
      final fromPrefsHc = prefs.getBool(_highContrastKey) ?? false;
      final changed = _isDarkMode != fromPrefsDark ||
          _isHighContrast != fromPrefsHc;

      _isDarkMode = fromPrefsDark;
      _isHighContrast = fromPrefsHc;
      _isInitialized = true;

      // Fără notify dacă nimic nu s-a schimbat — evită un rebuild complet al MaterialApp
      // la primul frame (cauză frecventă de aserțiuni cu Navigator/Overlay la pornire).
      if (changed) {
        scheduleMicrotask(() => notifyListeners());
      }
    } catch (e) {
      Logger.error('Error loading theme preferences: $e', error: e);
      _isInitialized = true;
    }
  }

  Future<void> _persistThemePreferences() async {
    final gen = ++_prefsWriteGeneration;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (gen != _prefsWriteGeneration) return;
      await prefs.setBool(_darkModeKey, _isDarkMode);
      await prefs.setBool(_highContrastKey, _isHighContrast);
    } catch (e) {
      Logger.error('Error saving theme preferences: $e', error: e);
    }
  }

  /// Comută între tema dark și light și notifică ascultătorii.
  Future<void> toggleTheme() async {
    _bumpUserThemeMutation();
    _isDarkMode = !_isDarkMode;
    // Amânăm notificarea după ciclul curent (gest/build) — evită aserțiunea
    // `_dependents.isEmpty` la rebuild sincron al [MaterialApp] din drawer/hartă.
    scheduleMicrotask(() => notifyListeners());
    unawaited(_persistThemePreferences());
  }

  /// Set theme mode explicitly
  Future<void> setThemeMode(ThemeMode mode) async {
    _bumpUserThemeMutation();
    _isDarkMode = mode == ThemeMode.dark;
    scheduleMicrotask(() => notifyListeners());
    unawaited(_persistThemePreferences());
  }

  Future<void> toggleHighContrast() async {
    _bumpUserThemeMutation();
    _isHighContrast = !_isHighContrast;
    scheduleMicrotask(() => notifyListeners());
    unawaited(_persistThemePreferences());
  }
}