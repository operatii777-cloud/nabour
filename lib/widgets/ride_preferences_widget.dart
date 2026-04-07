import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_preferences_model.dart';

/// Widget pentru setarea preferințelor de cursă (Uber-like)
class RidePreferencesWidget extends StatefulWidget {
  final RidePreferences? initialPreferences;
  final Function(RidePreferences) onPreferencesChanged;

  const RidePreferencesWidget({
    super.key,
    this.initialPreferences,
    required this.onPreferencesChanged,
  });

  @override
  State<RidePreferencesWidget> createState() => _RidePreferencesWidgetState();
}

class _RidePreferencesWidgetState extends State<RidePreferencesWidget> {
  late RidePreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences ?? const RidePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Preferințe Cursă',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Muzică
          _buildPreferenceSwitch(
            'Prefer muzică',
            _preferences.preferMusic ?? false,
            (value) {
              setState(() {
                _preferences = _preferences.copyWith(preferMusic: value);
              });
              widget.onPreferencesChanged(_preferences);
            },
            Icons.music_note,
          ),
          
          if (_preferences.preferMusic == true) ...[
            const SizedBox(height: 8),
            _buildPreferenceDropdown(
              'Tip muzică',
              _preferences.musicPreference,
              ['Pop', 'Rock', 'Jazz', 'Clasică', 'Electronică'],
              (value) {
                setState(() {
                  _preferences = _preferences.copyWith(musicPreference: value);
                });
                widget.onPreferencesChanged(_preferences);
              },
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Conversație
          _buildPreferenceSwitch(
            'Prefer conversație',
            _preferences.preferConversation ?? false,
            (value) {
              setState(() {
                _preferences = _preferences.copyWith(preferConversation: value);
              });
              widget.onPreferencesChanged(_preferences);
            },
            Icons.chat,
          ),
          
          const SizedBox(height: 16),
          
          // Liniște
          _buildPreferenceSwitch(
            'Prefer liniște',
            _preferences.preferQuiet ?? false,
            (value) {
              setState(() {
                _preferences = _preferences.copyWith(preferQuiet: value);
              });
              widget.onPreferencesChanged(_preferences);
            },
            Icons.volume_off,
          ),
          
          const SizedBox(height: 16),
          
          // Temperatură
          _buildPreferenceDropdown(
            'Temperatură',
            _preferences.temperaturePreference,
            ['Rece', 'Normal', 'Cald'],
            (value) {
              setState(() {
                _preferences = _preferences.copyWith(temperaturePreference: value);
              });
              widget.onPreferencesChanged(_preferences);
            },
            icon: Icons.thermostat,
          ),
          
          const SizedBox(height: 16),
          
          // Geam deschis
          _buildPreferenceSwitch(
            'Prefer geam deschis',
            _preferences.preferWindowOpen ?? false,
            (value) {
              setState(() {
                _preferences = _preferences.copyWith(preferWindowOpen: value);
              });
              widget.onPreferencesChanged(_preferences);
            },
            Icons.window,
          ),
          
          const SizedBox(height: 16),
          
          // Rută
          _buildPreferenceDropdown(
            'Preferință rută',
            _preferences.routePreference,
            ['Cel mai rapid', 'Scenic', 'Evită taxe'],
            (value) {
              setState(() {
                _preferences = _preferences.copyWith(routePreference: value);
              });
              widget.onPreferencesChanged(_preferences);
            },
            icon: Icons.route,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitch(
    String label,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPreferenceDropdown(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged, {
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

