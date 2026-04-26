import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nabour_app/theme/theme_provider.dart';
import 'package:nabour_app/widgets/map/animated_avatar_marker.dart';
import 'package:provider/provider.dart';

class OsmMapWidget extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final Function(MapController)? onMapCreated;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;
  final Function(MapCamera, bool)? onPositionChanged;
  
  final LatLng? userLocation;
  final String? userAssetPath;
  final String? userName;
  final double? userSpeedKph;
  final List<Marker>? additionalMarkers;

  const OsmMapWidget({
    super.key,
    required this.initialCenter,
    this.initialZoom = 14.0,
    this.onMapCreated,
    this.onTap,
    this.onLongPress,
    this.onPositionChanged,
    this.userLocation,
    this.userAssetPath,
    this.userName,
    this.userSpeedKph,
    this.additionalMarkers,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapCreated?.call(_mapController);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    // CartoDB Dark Matter split (Base + Labels) vs Voyager (Light)
    final String baseUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
    
    final String? labelsUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}{r}.png'
        : null;

    return Container(
      color: isDark ? const Color(0xFF101010) : const Color(0xFFE5E2DC),
      child: FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        onTap: (tapPos, latLng) => widget.onTap?.call(latLng),
        onLongPress: (tapPos, latLng) => widget.onLongPress?.call(latLng),
        onPositionChanged: (pos, hasGesture) => widget.onPositionChanged?.call(pos, hasGesture),
      ),
      children: [
        // 1. Stratul de bază (Geometrie: străzi, păduri, ape)
        TileLayer(
          urlTemplate: baseUrl,
          userAgentPackageName: 'com.operatii777.nabour',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: RetinaMode.isHighDensity(context),
          tileBuilder: isDark 
            ? (context, tileWidget, tile) {
                return ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    // R  G  B  A  Offset
                    0.7, 0, 0, 0, 22,   // R: Purpuriu subtil + lift
                    0, 0.35, 0, 0, 20,  // G: Dimmer green
                    0, 0, 1.1, 0, 42,   // B: Blue lift (navy background)
                    0, 0, 0, 1, 0,
                  ]),
                  child: tileWidget,
                );
              }
            : null,
        ),
        // 2. Stratul de etichete (Nume străzi) - doar în Dark Mode
        if (isDark && labelsUrl != null)
          TileLayer(
            urlTemplate: labelsUrl,
            userAgentPackageName: 'com.operatii777.nabour',
            subdomains: const ['a', 'b', 'c', 'd'],
            retinaMode: RetinaMode.isHighDensity(context),
            tileBuilder: (context, tileWidget, tile) {
              return ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  // Transformă etichetele (albe) în Turcoaz (G + B)
                  0.2, 0, 0, 0, 0,   // R (low red)
                  0, 1.2, 0, 0, 0,   // G (high green)
                  0, 0, 1.4, 0, 0,   // B (high blue)
                  0, 0, 0, 1, 0,
                ]),
                child: tileWidget,
              );
            },
          ),
        MarkerLayer(
          markers: [
            if (widget.additionalMarkers != null) ...widget.additionalMarkers!,
            if (widget.userLocation != null)
              Marker(
                point: widget.userLocation!,
                width: 220, // Mai lat pentru nume lungi
                height: 250, // Suficient pentru Avatar (146) + Nume + Viteza
                alignment: Alignment.center,
                child: AnimatedAvatarMarker(
                  assetPath: widget.userAssetPath ?? 'assets/images/driver_icon.png',
                  size: 146,
                  name: widget.userName ?? '',
                  isFloating: true,
                  showShadow: false,
                  speedKph: widget.userSpeedKph,
                ),
              ),
          ],
        ),
      ],
    ),
    );
  }
}
