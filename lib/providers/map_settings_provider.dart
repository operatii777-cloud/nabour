import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/utils/logger.dart';

enum MapProviderType { mapbox, osm }

class MapSettingsProvider extends ChangeNotifier {
  static const String _mapProviderKey = 'selected_map_provider';
  static const String _showHomePinKey = 'show_home_pin_on_map';

  MapProviderType _selectedProvider = MapProviderType.mapbox;
  bool _showHomePinOnMap = false;
  bool _isInitialized = false;

  MapProviderType get selectedProvider => _selectedProvider;
  bool get isMapbox => _selectedProvider == MapProviderType.mapbox;
  bool get isOsm => _selectedProvider == MapProviderType.osm;
  bool get showHomePinOnMap => _showHomePinOnMap;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getString(_mapProviderKey);
      if (savedValue != null) {
        _selectedProvider = MapProviderType.values.firstWhere(
          (e) => e.name == savedValue,
          orElse: () => MapProviderType.mapbox,
        );
      }
      _showHomePinOnMap = prefs.getBool(_showHomePinKey) ?? false;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      Logger.error('Error initializing MapSettingsProvider: $e');
      _isInitialized = true;
    }
  }

  Future<void> setMapProvider(MapProviderType type) async {
    if (_selectedProvider == type) return;
    _selectedProvider = type;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mapProviderKey, type.name);
    } catch (e) {
      Logger.error('Error saving map provider preference: $e');
    }
  }

  void toggleMapProvider() {
    setMapProvider(
      _selectedProvider == MapProviderType.mapbox
        ? MapProviderType.osm
        : MapProviderType.mapbox
    );
  }

  Future<void> setShowHomePinOnMap(bool show) async {
    if (_showHomePinOnMap == show) return;
    _showHomePinOnMap = show;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showHomePinKey, show);
    } catch (e) {
      Logger.error('Error saving show home pin preference: $e');
    }
  }
}
