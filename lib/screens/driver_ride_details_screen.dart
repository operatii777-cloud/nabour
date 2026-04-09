import 'package:flutter/material.dart';

import '../utils/mapbox_utils.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/widgets/rating_stars.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/screens/help_screen.dart';
import 'package:nabour_app/screens/map_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/utils/content_filter.dart';
import 'package:nabour_app/config/nabour_map_styles.dart';

class DriverRideDetailsScreen extends StatefulWidget {
  final Ride ride;
  const DriverRideDetailsScreen({super.key, required this.ride});

  @override
  State<DriverRideDetailsScreen> createState() => _DriverRideDetailsScreenState();
}

class _DriverRideDetailsScreenState extends State<DriverRideDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _characterizationController = TextEditingController();
  double _selectedRating = 0;
  bool _isLoading = false;
  bool _feedbackSubmitted = false;
  
  Point? _startPoint;
  Point? _endPoint;
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _markersManager;

  @override
  void initState() {
    super.initState();
    _getCoordinatesFromAddresses();
    if (widget.ride.driverRatingForPassenger != null) {
      _feedbackSubmitted = true;
    }
  }

  @override
  void dispose() {
    _characterizationController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _markersManager = await _mapboxMap?.annotations.createPointAnnotationManager(id: "ride-markers-manager");
    _updateMarkersAndCamera();
  }
  
  Future<void> _submitPassengerRating() async {
    if (_selectedRating == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te rugăm selectează un rating înainte de a trimite.')),
      );
      return;
    }

    // ── Filtru conținut ────────────────────────────────────────────────
    final characterization = _characterizationController.text.trim();
    if (characterization.isNotEmpty) {
      final filterResult = ContentFilter.check(characterization);
      if (!filterResult.isClean) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(filterResult.message ?? 'Cuvinte inadecvate în descriere.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
    }

    setState(() { _isLoading = true; });

    try {
      await _firestoreService.ratePassenger(
        rideId: widget.ride.id,
        rating: _selectedRating,
        characterization: _characterizationController.text,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluare trimisă cu succes!'), backgroundColor: Colors.green),
      );
      
      // ✅ FIX: Navigare sigură la MapScreen după evaluare
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          try {
            // Navighează la MapScreen pentru a permite șoferului să preia alte curse
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MapScreen()),
              (Route<dynamic> route) => false,
            );
          } catch (e) {
            Logger.error('Error during navigation: $e', error: e);
            // Fallback: navigare simplă
            try {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } catch (e2) {
              Navigator.of(context).pop();
            }
          }
        }
      });
      
    } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la trimiterea evaluării: ${e.toString()}'))
      );
    } finally {
       if (mounted) {
         setState(() { _isLoading = false; });
       }
    }
  }

  Future<void> _updateMarkersAndCamera() async {
    if (_markersManager == null || _startPoint == null || _endPoint == null) return;
    
    await _markersManager?.deleteAll();
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
        iconSize: 0.15
      ),
      PointAnnotationOptions(
        geometry: MapboxUtils.createPoint(
          _endPoint!.coordinates.lat.toDouble(), 
          _endPoint!.coordinates.lng.toDouble()
        ), 
        image: endIcon.buffer.asUint8List(), 
        iconAnchor: IconAnchor.BOTTOM, 
        iconSize: 0.18
      ),
    ]);
    
    _mapboxMap?.easeTo(
      CameraOptions(
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
        title: const Text('Detalii Cursă Finalizată'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
                      styleUri: NabourMapStyles.uriForMainMap(
                        lowDataMode: false,
                        darkMode: Theme.of(context).brightness == Brightness.dark,
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cursă din ${DateFormat('dd MMMM HH:mm', 'ro_RO').format(widget.ride.timestamp)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('De la:', widget.ride.startAddress),
                  _buildDetailRow('La:', widget.ride.destinationAddress),
                  const Divider(height: 24),
                  const Text('Detalii Sprijin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (widget.ride.totalCost > 0) ...[
                    _buildDetailRow('Total Cursă:', '${widget.ride.totalCost.toStringAsFixed(2)} RON'),
                    _buildDetailRow('Comision Aplicație:', '-${widget.ride.appCommission.toStringAsFixed(2)} RON', isNegative: true),
                    const Divider(),
                    _buildDetailRow('Câștigul Tău:', '${widget.ride.driverEarnings.toStringAsFixed(2)} RON', isTotal: true),
                  ] else ...[
                    _buildDetailRow('Tip Serviciu:', 'Sprijin Vecini (Gratuit)'),
                    _buildDetailRow('Contribuție:', 'Nabour Token (+1)'),
                    const Divider(),
                    _buildDetailRow('Total:', 'Comunitate Unită', isTotal: true),
                  ],
                  
                  const Divider(height: 24),
                  _buildPassengerRatingSection(),
                  
                  const SizedBox(height: 32),
                  Center(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.help_outline),
                      label: const Text('Raportează o problemă'),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerRatingSection() {
    if (_feedbackSubmitted) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  l10n.thanksForRating,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Center(
              child: Text(
                l10n.ratePassenger,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Center(
          // CORECTARE: Instanțierea corectă a widget-ului
          child: RatingStars(
            initialRating: _selectedRating,
            onRatingChanged: (rating) {
              setState(() {
                _selectedRating = rating;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return TextField(
              controller: _characterizationController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.shortCharacterization,
                hintText: l10n.addPrivateNoteAboutPassenger,
              ),
              maxLines: 3,
            );
          },
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            onPressed: _submitPassengerRating,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            label: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.saveRating);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isNegative ? Colors.red : (isTotal ? Colors.green : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
