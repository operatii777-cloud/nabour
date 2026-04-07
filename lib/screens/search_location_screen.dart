import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nabour_app/services/routing_service.dart';

import '../utils/mapbox_utils.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class SearchLocationScreen extends StatefulWidget {
  final bool isDestination;
  const SearchLocationScreen({super.key, this.isDestination = true});

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RoutingService _routingService = RoutingService();
  MapboxMap? _mapboxMap;
  Timer? _debounce;

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getSuggestions(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      final results = await _routingService.searchPlace(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    });
  }
  
  void _onLocationSelected(Map<String, dynamic> locationData) {
    final result = {
      'address': locationData['address'],
      'latitude': locationData['latitude'],
      'longitude': locationData['longitude'],
    };
    Navigator.pop(context, result);
  }

  Future<void> _confirmPinLocation() async {
    if (_mapboxMap == null) return;

    final center = await _mapboxMap!.getCameraState();
    final point = center.center;

    // Convert Map to Point and extract coordinates
    final pointObj = MapboxUtils.convertToPoint(point);
    final addressData = await _routingService.getReverseGeocoding(
      pointObj.coordinates.lat.toDouble(), 
      pointObj.coordinates.lng.toDouble()
    );
    
    if (mounted && addressData.isNotEmpty) {
      _onLocationSelected(addressData);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu am putut determina adresa pentru acest punct.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDestination ? 'Alege Destinația' : 'Adaugă o Oprire'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Caută o adresă sau un loc...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
              onChanged: _getSuggestions,
            ),
          ),
          if (_suggestions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: Colors.blue),
                    title: Text(suggestion['address'] ?? 'Adresă invalidă'),
                    subtitle: Text(suggestion['secondary_text'] ?? ''),
                    onTap: () => _onLocationSelected(suggestion),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MapWidget(
                    onMapCreated: (controller) => _mapboxMap = controller,
                    cameraOptions: CameraOptions(
                      center: MapboxUtils.createPoint(44.4268, 26.1025),
                      zoom: 12,
                    ),
                  ),
                  IgnorePointer(
                    child: Icon(Icons.location_pin, color: Colors.red.shade600, size: 50),
                  ),
                  Positioned(
                    bottom: 20,
                    child: ElevatedButton.icon(
                      onPressed: _confirmPinLocation,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmă Locația de pe Hartă'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}