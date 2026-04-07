import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('ro'); // Limba implicită este româna

  Locale get locale => _locale;

  LocaleProvider() {
    _loadPersistedLocale();
  }

  Future<void> _loadPersistedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('locale');
      if (code != null && AppLocalizations.supportedLocales.contains(Locale(code))) {
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', locale.languageCode);
    } catch (_) {}
  }
}