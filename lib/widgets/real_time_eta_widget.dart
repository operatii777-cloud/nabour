import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Widget pentru ETA în timp real (Uber-like)
/// Afișează countdown timer și notificări când șoferul se apropie
class RealTimeETAWidget extends StatefulWidget {
  final Ride ride;
  final Point? driverLocation;
  final Point? pickupLocation;
  final Point? destinationLocation;
  final bool isDriver;

  const RealTimeETAWidget({
    super.key,
    required this.ride,
    this.driverLocation,
    this.pickupLocation,
    this.destinationLocation,
    this.isDriver = false,
  });

  @override
  State<RealTimeETAWidget> createState() => _RealTimeETAWidgetState();
}

class _RealTimeETAWidgetState extends State<RealTimeETAWidget> {
  Timer? _updateTimer;
  Duration? _eta;
  Duration? _timeToPickup;
  Duration? _timeToDestination;
  bool _nearPickup = false;
  bool _nearDestination = false;

  @override
  void initState() {
    super.initState();
    _startETATimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startETATimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _calculateETA();
      }
    });
    _calculateETA();
  }

  void _calculateETA() {
    // Calculează ETA bazat pe status-ul cursei
    if (widget.isDriver) {
      if (widget.ride.status == 'in_progress' && widget.driverLocation != null && widget.destinationLocation != null) {
        // ETA până la destinație pentru șofer
        _timeToDestination = _estimateTimeToDestination();
        _eta = _timeToDestination;
        _checkNearDestination();
      } else if (widget.ride.status == 'arrived' || widget.ride.status == 'accepted') {
        // ETA până la pickup
        _timeToPickup = _estimateTimeToPickup();
        _eta = _timeToPickup;
        _checkNearPickup();
      }
    } else {
      // Pentru pasager
      if (widget.ride.status == 'accepted' || widget.ride.status == 'driver_found') {
        // ETA până la pickup
        _timeToPickup = _estimateTimeToPickup();
        _eta = _timeToPickup;
        _checkNearPickup();
      } else if (widget.ride.status == 'in_progress') {
        // ETA până la destinație
        _timeToDestination = _estimateTimeToDestination();
        _eta = _timeToDestination;
        _checkNearDestination();
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Duration? _estimateTimeToPickup() {
    if (widget.driverLocation == null || widget.pickupLocation == null) {
      return null;
    }

    // Calculează distanța și estimează timpul
    final distance = _calculateDistance(
      widget.driverLocation!.coordinates.lat.toDouble(),
      widget.driverLocation!.coordinates.lng.toDouble(),
      widget.pickupLocation!.coordinates.lat.toDouble(),
      widget.pickupLocation!.coordinates.lng.toDouble(),
    );

    // Viteza medie: 40 km/h în oraș
    const averageSpeed = 40.0; // km/h
    final timeInMinutes = (distance / averageSpeed) * 60;
    return Duration(minutes: timeInMinutes.round());
  }

  Duration? _estimateTimeToDestination() {
    if (widget.driverLocation == null || widget.destinationLocation == null) {
      return null;
    }

    final distance = _calculateDistance(
      widget.driverLocation!.coordinates.lat.toDouble(),
      widget.driverLocation!.coordinates.lng.toDouble(),
      widget.destinationLocation!.coordinates.lat.toDouble(),
      widget.destinationLocation!.coordinates.lng.toDouble(),
    );

    const averageSpeed = 40.0; // km/h
    final timeInMinutes = (distance / averageSpeed) * 60;
    return Duration(minutes: timeInMinutes.round());
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  void _checkNearPickup() {
    if (widget.driverLocation == null || widget.pickupLocation == null) {
      _nearPickup = false;
      return;
    }

    final distance = _calculateDistance(
      widget.driverLocation!.coordinates.lat.toDouble(),
      widget.driverLocation!.coordinates.lng.toDouble(),
      widget.pickupLocation!.coordinates.lat.toDouble(),
      widget.pickupLocation!.coordinates.lng.toDouble(),
    );

    _nearPickup = distance < 0.5; // Mai puțin de 500m
  }

  void _checkNearDestination() {
    if (widget.driverLocation == null || widget.destinationLocation == null) {
      _nearDestination = false;
      return;
    }

    final distance = _calculateDistance(
      widget.driverLocation!.coordinates.lat.toDouble(),
      widget.driverLocation!.coordinates.lng.toDouble(),
      widget.destinationLocation!.coordinates.lat.toDouble(),
      widget.destinationLocation!.coordinates.lng.toDouble(),
    );

    _nearDestination = distance < 0.5; // Mai puțin de 500m
  }

  @override
  Widget build(BuildContext context) {
    if (_eta == null) {
      return const SizedBox.shrink();
    }

    final minutes = _eta!.inMinutes;
    final seconds = _eta!.inSeconds % 60;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (widget.isDriver) {
      if (widget.ride.status == 'in_progress') {
        statusText = 'Până la destinație';
        statusColor = Colors.blue;
        statusIcon = Icons.flag;
      } else {
        statusText = 'Până la pickup';
        statusColor = Colors.green;
        statusIcon = Icons.location_on;
      }
    } else {
      if (widget.ride.status == 'in_progress') {
        statusText = 'Până la destinație';
        statusColor = Colors.blue;
        statusIcon = Icons.flag;
      } else {
        statusText = 'Șoferul ajunge în';
        statusColor = _nearPickup ? Colors.orange : Colors.green;
        statusIcon = _nearPickup ? Icons.warning : Icons.directions_car;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  minutes > 0
                      ? '$minutes min ${seconds > 0 ? "$seconds sec" : ""}'
                      : '$seconds sec',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (_nearPickup || _nearDestination)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Aproape!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

