import 'package:flutter/material.dart';
import '../utils/mapbox_utils.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/screens/help_screen.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/widgets/favorite_driver_button.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:nabour_app/utils/logger.dart';

class RideDetailsScreen extends StatefulWidget {
  final Ride ride;
  const RideDetailsScreen({super.key, required this.ride});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  Point? _startPoint;
  Point? _endPoint;
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _markersManager;

  @override
  void initState() {
    super.initState();
    _getCoordinatesFromAddresses();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _markersManager = await _mapboxMap?.annotations.createPointAnnotationManager(id: "ride-markers-manager");
    _updateMarkersAndCamera();
  }

  Future<void> _updateMarkersAndCamera() async {
    if (_markersManager == null || _startPoint == null || _endPoint == null) return;
    
    _markersManager?.deleteAll();
    final ByteData startIcon = await rootBundle.load("assets/images/passenger_icon.png");
    final ByteData endIcon = await rootBundle.load("assets/images/pin_icon.png");

    await _markersManager?.createMulti([
      PointAnnotationOptions(
        geometry: MapboxUtils.createPoint(
          _startPoint!.coordinates.lat.toDouble(), 
          _startPoint!.coordinates.lng.toDouble()
        ), 
        image: startIcon.buffer.asUint8List(), 
        iconAnchor: IconAnchor.BOTTOM, 
        iconSize: 0.3 // MODIFICAT: Redus dimensiunea
      ),
      PointAnnotationOptions(
        geometry: MapboxUtils.createPoint(
          _endPoint!.coordinates.lat.toDouble(), 
          _endPoint!.coordinates.lng.toDouble()
        ), 
        image: endIcon.buffer.asUint8List(), 
        iconAnchor: IconAnchor.BOTTOM, 
        iconSize: 0.5 // MODIFICAT: Redus dimensiunea
      ),
    ]);
    
    final List<Point> points = [_startPoint!, _endPoint!];
    
    final double minLat = points.map((p) => p.coordinates.lat).reduce((a, b) => a < b ? a : b).toDouble();
    final double maxLat = points.map((p) => p.coordinates.lat).reduce((a, b) => a > b ? a : b).toDouble();
    final double minLng = points.map((p) => p.coordinates.lng).reduce((a, b) => a < b ? a : b).toDouble();
    final double maxLng = points.map((p) => p.coordinates.lng).reduce((a, b) => a > b ? a : b).toDouble();

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    
    final double latDiff = maxLat - minLat;
    final double lngDiff = maxLng - minLng;
    double zoom = 13.0;
    if (latDiff > 0.1 || lngDiff > 0.1) {
      zoom = 11.0;
    } else if (latDiff > 0.05 || lngDiff > 0.05) {
      zoom = 12.0;
    }

    _mapboxMap?.flyTo(
      CameraOptions(
        center: MapboxUtils.createPoint(centerLat, centerLng),
        zoom: zoom,
        padding: MbxEdgeInsets(top: 80, left: 80, bottom: 80, right: 80),
      ),
      MapAnimationOptions(duration: 1000)
    );
  }
  
  Future<void> _getCoordinatesFromAddresses() async {
    try {
      final List<Location> startLocations = await locationFromAddress(widget.ride.startAddress);
      final List<Location> endLocations = await locationFromAddress(widget.ride.destinationAddress);

      if (mounted && startLocations.isNotEmpty && endLocations.isNotEmpty) {
        setState(() {
          _startPoint = MapboxUtils.createPoint(startLocations.first.latitude, startLocations.first.longitude);
          _endPoint = MapboxUtils.createPoint(endLocations.first.latitude, endLocations.first.longitude);
        });
        if (_mapboxMap != null) {
          _updateMarkersAndCamera();
        }
      }
    } catch (e) {
      Logger.debug("Eroare la geocodare în RideDetailsScreen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.rideDetailsCompleted);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              child: (_startPoint != null && _endPoint != null)
                  ? MapWidget(
                      onMapCreated: _onMapCreated,
                      cameraOptions: CameraOptions(
                        center: _startPoint!,
                        zoom: 13,
                      ),
                      styleUri: MapboxStyles.MAPBOX_STREETS,
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      final locale = Localizations.localeOf(context);
                      final dateFormat = DateFormat('dd MMMM HH:mm', locale.languageCode == 'en' ? 'en_US' : 'ro_RO');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.rideFrom(dateFormat.format(widget.ride.timestamp)),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(l10n.from, widget.ride.startAddress),
                          _buildDetailRow(l10n.to, widget.ride.destinationAddress),
                          const Divider(height: 24),
                          Text(l10n.costSummary, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          _buildDetailRow(l10n.baseFare, '${widget.ride.baseFare.toStringAsFixed(2)} ${l10n.ron}'),
                          _buildDetailRow(l10n.distance(widget.ride.distance.toStringAsFixed(1)), '${(widget.ride.distance * widget.ride.perKmRate).toStringAsFixed(2)} ${l10n.ron}'),
                          _buildDetailRow(l10n.time((widget.ride.durationInMinutes?.toStringAsFixed(0) ?? '0')), '${((widget.ride.durationInMinutes ?? 0) * widget.ride.perMinRate).toStringAsFixed(2)} ${l10n.ron}'),
                          const Divider(),
                          _buildDetailRow(l10n.totalPaid, '${widget.ride.totalCost.toStringAsFixed(2)} ${l10n.ron}', isTotal: true),
                          const Divider(height: 24),
                          _buildDetailRow(l10n.ratingGiven, widget.ride.passengerRating != null ? '${widget.ride.passengerRating?.toStringAsFixed(1)} ★' : l10n.noRatingGiven),
                          if (widget.ride.driverId != null && widget.ride.driverId!.isNotEmpty) ...[
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Șofer preferat',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                FavoriteDriverButton(driverId: widget.ride.driverId!),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                   OutlinedButton.icon(
                     icon: const Icon(Icons.help_outline),
                     label: Builder(
                       builder: (context) {
                         final l10n = AppLocalizations.of(context)!;
                         return Text(l10n.reportProblem);
                       },
                     ),
                     onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
                     },
                   )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}