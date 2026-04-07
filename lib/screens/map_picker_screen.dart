import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../utils/mapbox_utils.dart';

class MapPickerScreen extends StatefulWidget {
  final geolocator.Position initialLocation;

  const MapPickerScreen({super.key, required this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  MapboxMap? _mapboxMap;
  String _selectedAddress = "Se încarcă adresa...";
  Timer? _debounce;
  bool _isGeocoding = true;
  Point? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = Point(coordinates: Position(widget.initialLocation.longitude, widget.initialLocation.latitude));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    // --- CORECȚIE: Am șters apelul .subscribe() de aici ---
    // Prima geocodare inversă se face la crearea hărții
    _reverseGeocode(_selectedPoint!);
  }

  // --- CORECȚIE: Am schimbat tipul eventului din 'MapEvent' în 'MapIdleEventData' ---
  void _onMapIdle(MapIdleEventData data) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final cameraState = await _mapboxMap?.getCameraState();
      if (cameraState != null && mounted) {
        final newCenter = cameraState.center;
        _reverseGeocode(MapboxUtils.convertToPoint(newCenter));
      }
    });
  }

  Future<void> _reverseGeocode(Point point) async {
    if (!mounted) return;
    setState(() {
      _isGeocoding = true;
      _selectedPoint = point;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        point.coordinates.lat.toDouble(), 
        point.coordinates.lng.toDouble(),
      );
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = [
          place.street,
          place.locality,
          place.subAdministrativeArea,
        ].where((s) => s != null && s.isNotEmpty);
        
        setState(() {
          _selectedAddress = addressParts.join(', ');
        });
      } else {
         setState(() { _selectedAddress = "Adresă necunoscută"; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _selectedAddress = "Nu s-a putut găsi adresa."; });
      }
    } finally {
      if (mounted) setState(() { _isGeocoding = false; });
    }
  }

  void _confirmSelection() {
    if (_selectedPoint != null) {
      Navigator.of(context).pop({
        'location': _selectedPoint,
        'address': _selectedAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alege locația pe hartă"),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MapWidget(
            onMapCreated: _onMapCreated,
            // --- CORECȚIE: Aici este modul corect de a asculta evenimente ---
            onMapIdleListener: _onMapIdle, 
            cameraOptions: CameraOptions(
                              center: _selectedPoint,
              zoom: 16.0,
            ),
            styleUri: Theme.of(context).brightness == Brightness.dark
                ? MapboxStyles.DARK
                : MapboxStyles.MAPBOX_STREETS,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: Icon(Icons.location_pin, size: 50, color: Colors.red.shade700),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 10,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isGeocoding
                            ? const CircularProgressIndicator()
                            : Text(
                                _selectedAddress,
                                key: ValueKey(_selectedAddress),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text("Confirmă această locație"),
                        onPressed: (_isGeocoding || _selectedPoint == null) ? null : _confirmSelection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}