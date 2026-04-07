import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/models/user_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/pricing_service.dart';
import 'package:nabour_app/services/routing_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/utils/external_maps_launcher.dart';
import 'package:nabour_app/utils/logger.dart';


/// Ecran premium de preluare cursă pentru șoferi
/// Oferă o experiență completă similar cu Uber/Bolt
class DriverRidePickupScreen extends StatefulWidget {
  final String rideId;
  final Ride ride;

  const DriverRidePickupScreen({
    super.key,
    required this.rideId,
    required this.ride,
  });

  @override
  State<DriverRidePickupScreen> createState() => _DriverRidePickupScreenState();
}

class _DriverRidePickupScreenState extends State<DriverRidePickupScreen>
    with TickerProviderStateMixin {
  
  final FirestoreService _firestoreService = FirestoreService();
  final RoutingService _routingService = RoutingService();
  
  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  
  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  // State variables
  UserModel? _passengerProfile;
  geo.Position? _currentPosition;
  double? _distanceToPickup;
  int? _etaToPickup;
  Timer? _locationTimer;
  Timer? _etaTimer;
  bool _isLoading = true;
  bool _isAtPickupLocation = false;
  bool _hasNotifiedArrival = false;

  // Feature: Wait time fee — tracks wait duration after driver arrives
  Timer? _waitTimer;
  DateTime? _waitStartTime;
  int _waitedMinutes = 0;
  double _accumulatedWaitFee = 0.0;

  // Feature: Pickup code — driver verifies passenger's 4-digit code
  static const int _pickupCodeLength = 4;
  final TextEditingController _pickupCodeController = TextEditingController();
  bool _isVerifyingCode = false;
  bool _codeVerified = false;
  
  // Pickup process states
  PickupState _pickupState = PickupState.approaching;
  String _statusMessage = 'Te îndrepți către pasager...';

  @override
  void initState() {
    super.initState();
    _hydratePickupProgressFromRide();
    _initializeAnimations();
    _loadPassengerProfile();
    _startLocationTracking();
    _startEtaUpdates();
  }

  /// Restaurare sesiune: curse vechi sau relansare app cu status deja `arrived` / `in_progress`.
  void _hydratePickupProgressFromRide() {
    final s = widget.ride.status;
    if (s == 'arrived') {
      _pickupState = PickupState.pickingUp;
      _hasNotifiedArrival = true;
      _codeVerified = true;
      _statusMessage = 'Pasagerul se îmbarcă...';
    } else if (s == 'in_progress') {
      _pickupState = PickupState.pickingUp;
      _hasNotifiedArrival = true;
      _codeVerified = true;
      _statusMessage = 'Navigare spre destinație în Maps / Waze';
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _locationTimer?.cancel();
    _etaTimer?.cancel();
    _waitTimer?.cancel();
    _pickupCodeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadPassengerProfile() async {
    try {
      final profileDoc = await _firestoreService.getProfileByIdStream(widget.ride.passengerId).first;
      if (profileDoc.exists) {
        setState(() {
          _passengerProfile = UserModel.fromFirestore(profileDoc);
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading passenger profile: $e', error: e);
      setState(() => _isLoading = false);
    }
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateCurrentLocation();
    });
    _updateCurrentLocation(); // Initial update
  }

  void _startEtaUpdates() {
    _etaTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateEtaToPickup();
    });
    _updateEtaToPickup(); // Initial update
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final position = await geo.Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);

      unawaited(_firestoreService.updateDriverLocation(
        position,
        activeRideId: widget.rideId,
        activeRidePassengerId: widget.ride.passengerId,
      ));
      
      // Calculate distance to pickup
      if (widget.ride.startLatitude != null && widget.ride.startLongitude != null) {
        final distance = geo.Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          widget.ride.startLatitude!,
          widget.ride.startLongitude!,
        );
        
        setState(() {
          _distanceToPickup = distance;
          _isAtPickupLocation = distance <= 50; // Within 50 meters
        });

        // Auto-notify arrival if close enough and not yet notified
        if (_isAtPickupLocation && !_hasNotifiedArrival && _pickupState == PickupState.approaching) {
          _updatePickupState(PickupState.arrived);
        }
      }
    } catch (e) {
      Logger.error('Error updating location: $e', error: e);
    }
  }

  Future<void> _updateEtaToPickup() async {
    if (_currentPosition == null || widget.ride.startLatitude == null || widget.ride.startLongitude == null) {
      return;
    }

    try {
      final waypoints = [
        Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)),
        Point(coordinates: Position(widget.ride.startLongitude!, widget.ride.startLatitude!)),
      ];
      final route = await _routingService.getRoute(waypoints);

      if (route != null && route['duration'] != null) {
        setState(() {
          _etaToPickup = (route['duration'] as num).round();
        });
      }
    } catch (e) {
      Logger.error('Error calculating ETA: $e', error: e);
    }
  }

  void _updatePickupState(PickupState newState) {
    setState(() {
      _pickupState = newState;
      switch (newState) {
        case PickupState.approaching:
          _statusMessage = 'Te îndrepți către pasager...';
          break;
        case PickupState.arrived:
          _statusMessage = 'Ai ajuns! Anunță pasagerul.';
          break;
        case PickupState.waiting:
          _statusMessage = 'Aștepți pasagerul...';
          break;
        case PickupState.pickingUp:
          _statusMessage = 'Pasagerul se îmbarcă...';
          break;
      }
    });

    // Auto-notify passenger when arrived
    if (newState == PickupState.arrived && !_hasNotifiedArrival) {
      _notifyArrival();
    }
  }

  Future<void> _notifyArrival() async {
    try {
      // Feature: Wait time fee — use markDriverArrived to record wait start time
      await _firestoreService.markDriverArrived(widget.rideId);
      setState(() {
        _hasNotifiedArrival = true;
        _waitStartTime = DateTime.now();
      });
      _startWaitTimer();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pasagerul a fost notificat că ai ajuns!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error notifying arrival: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Eroare la notificarea sosirii'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startWaitTimer() {
    _waitTimer?.cancel();
    _waitTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      final start = _waitStartTime;
      if (start == null) return;
      setState(() {
        _waitedMinutes = DateTime.now().difference(start).inMinutes;
        _accumulatedWaitFee = PricingService.calculateWaitTimeFee(start);
      });
    });
  }

  Future<void> _verifyPickupCode() async {
    final enteredCode = _pickupCodeController.text.trim();
    if (enteredCode.length != _pickupCodeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introdu codul de $_pickupCodeLength cifre al pasagerului')),
      );
      return;
    }
    setState(() => _isVerifyingCode = true);
    try {
      final rideDoc = await _firestoreService.getRideById(widget.rideId);
      final correctCode = rideDoc?.pickupCode;
      if (correctCode == null || correctCode != enteredCode) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Cod incorect. Verificați din nou cu pasagerul.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() => _codeVerified = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cod verificat! Poți porni cursa.'),
              backgroundColor: Colors.green,
            ),
          );
          _updatePickupState(PickupState.pickingUp);
        }
      }
    } catch (e) {
      Logger.error('Error verifying pickup code: $e', error: e);
    } finally {
      if (mounted) setState(() => _isVerifyingCode = false);
    }
  }

  Future<void> _callPassenger() async {
    if (_passengerProfile?.phoneNumber != null) {
      final Uri phoneUri = Uri(scheme: 'tel', path: _passengerProfile!.phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nu se poate deschide aplicația de telefon')),
          );
        }
      }
    }
  }

  void _messagePassenger() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          rideId: widget.rideId,
          otherUserId: widget.ride.passengerId,
          otherUserName: _passengerProfile?.displayName ?? 'Pasager',
          collectionName: 'ride_requests',
        ),
      ),
    );
  }

  Future<void> _openPickupInExternalMaps() async {
    final lat = widget.ride.startLatitude;
    final lng = widget.ride.startLongitude;
    if (lat == null || lng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lipsește punctul de îmbarcare pe hartă.')),
        );
      }
      return;
    }
    await ExternalMapsLauncher.showNavigationChooser(
      context,
      lat,
      lng,
      title: 'Navigare spre pickup',
      hint: 'Google Maps sau Waze (fără navigare în Nabour).',
    );
  }

  /// După îmbarcare: doar Maps/Waze spre destinație, apoi cursă încheiată în Firestore.
  Future<void> _openDestinationExternalNavAndComplete() async {
    try {
      _waitTimer?.cancel();
      await _firestoreService.finalizeWaitTimeFee(widget.rideId);

      final dLat = widget.ride.destinationLatitude;
      final dLng = widget.ride.destinationLongitude;
      if (dLat == null || dLng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lipsește destinația — nu putem deschide navigația externă.'),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      await ExternalMapsLauncher.showNavigationChooser(
        context,
        dLat,
        dLng,
        title: 'Destinație finală',
        hint: 'Deschide în aplicația de navigație. După aceea revii la harta principală.',
      );
      if (!mounted) return;
      try {
        await _firestoreService.updateRideStatus(widget.rideId, 'completed');
      } catch (e) {
        Logger.warning('updateRideStatus completed: $e', tag: 'DRIVER_PICKUP');
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      Logger.error('Error completing ride handoff: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Eroare la finalizarea cursei'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelRide() async {
    final reason = await _showCancelDialog();
    if (reason != null) {
      try {
        await _firestoreService.cancelRide(widget.rideId);
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cursa anulată: $reason'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        Logger.error('Error cancelling ride: $e', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Eroare la anularea cursei'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<String?> _showCancelDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anulează cursa'),
        content: const Text('Selectează motivul anulării:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Înapoi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'Pasagerul nu răspunde'),
            child: const Text('Pasager nu răspunde'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'Problemă cu mașina'),
            child: const Text('Problemă tehnică'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'Altă urgență'),
            child: const Text('Urgență'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Preluare Cursă'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _cancelRide,
            icon: const Icon(Icons.cancel_outlined),
            tooltip: 'Anulează cursa',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildPassengerCard(),
                    const SizedBox(height: 16),
                    _buildRideDetailsCard(),
                    const SizedBox(height: 16),
                    _buildActionsCard(),
                    const SizedBox(height: 24),
                    _buildPickupActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor().withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (_distanceToPickup != null) ...[
                const SizedBox(height: 8),
                Text(
                  '📍 ${(_distanceToPickup! / 1000).toStringAsFixed(1)} km distanță',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (_etaToPickup != null) ...[
                const SizedBox(height: 4),
                Text(
                  '⏱️ ${_etaToPickup! ~/ 60}m ${_etaToPickup! % 60}s ETA',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerCard() {
    if (_passengerProfile == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('Se încarcă informațiile pasagerului...')),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: _passengerProfile!.profileImageUrl != null
                      ? NetworkImage(_passengerProfile!.profileImageUrl!)
                      : null,
                  child: _passengerProfile!.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 30,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // ✅ FIX: Adăugat mainAxisSize
                    children: [
                      Text(
                        _passengerProfile!.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1, // ✅ FIX: Adăugat maxLines
                        overflow: TextOverflow.ellipsis, // ✅ FIX: Adăugat overflow
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_passengerProfile!.averageRating?.toStringAsFixed(1) ?? 'N/A'} ⭐',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Special requests removed as not in model

          ],
        ),
      ),
    );
  }

  Widget _buildRideDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalii Cursă',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLocationItem(
              icon: Icons.radio_button_checked,
              iconColor: Colors.green,
              title: 'Pickup',
              address: widget.ride.startAddress,
            ),
            const SizedBox(height: 12),
            _buildLocationItem(
              icon: Icons.location_on,
              iconColor: Colors.red,
              title: 'Destinație',
              address: widget.ride.destinationAddress,
            ),
            const SizedBox(height: 16),
            Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  icon: Icons.payments,
                  label: 'Tarif estimat',
                  value: '${widget.ride.totalCost.toStringAsFixed(2)} RON',
                  color: Colors.green,
                ),
                _buildInfoItem(
                  icon: Icons.directions_car,
                  label: 'Categorie',
                  value: widget.ride.category.displayName,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acțiuni Rapide',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.phone,
                    label: 'Sună',
                    color: Colors.green,
                    onPressed: _callPassenger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.message,
                    label: 'Mesaj',
                    color: Colors.blue,
                    onPressed: _messagePassenger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.map,
                    label: 'Pickup',
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () => unawaited(_openPickupInExternalMaps()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupActions() {
    return Column(
      children: [
        // Feature: Wait time fee — show wait timer when driver is arrived
        if (_waitStartTime != null && _pickupState != PickupState.approaching) ...[
          Card(
            color: _accumulatedWaitFee > 0 ? Colors.orange.shade50 : Colors.green.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: _accumulatedWaitFee > 0 ? Colors.orange : Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    _waitedMinutes <= PricingService.freeWaitMinutes
                        ? 'Așteptare: $_waitedMinutes min (gratuit ${PricingService.freeWaitMinutes} min)'
                        : 'Așteptare: $_waitedMinutes min • Taxa: ${_accumulatedWaitFee.toStringAsFixed(2)} RON',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _accumulatedWaitFee > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_pickupState == PickupState.approaching && _isAtPickupLocation) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updatePickupState(PickupState.arrived),
              icon: const Icon(Icons.location_on),
              label: const Text('Am ajuns - Anunță pasagerul'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Feature: Pickup code — show code verification when arrived/waiting
        if ((_pickupState == PickupState.arrived || _pickupState == PickupState.waiting) && !_codeVerified) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Verifică codul pasagerului',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pickupCodeController,
                          keyboardType: TextInputType.number,
                          maxLength: _pickupCodeLength,
                          decoration: const InputDecoration(
                            hintText: 'Cod 4 cifre',
                            counterText: '',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isVerifyingCode ? null : _verifyPickupCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isVerifyingCode
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Verifică'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_pickupState == PickupState.pickingUp) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => unawaited(_openDestinationExternalNavAndComplete()),
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Destinație: Maps / Waze'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor() {
    switch (_pickupState) {
      case PickupState.approaching:
        return Colors.blue;
      case PickupState.arrived:
        return Colors.orange;
      case PickupState.waiting:
        return Colors.amber;
      case PickupState.pickingUp:
        return Colors.green;
    }
  }

  IconData _getStatusIcon() {
    switch (_pickupState) {
      case PickupState.approaching:
        return Icons.directions_car;
      case PickupState.arrived:
        return Icons.location_on;
      case PickupState.waiting:
        return Icons.schedule;
      case PickupState.pickingUp:
        return Icons.directions_walk;
    }
  }
}

enum PickupState {
  approaching,
  arrived,
  waiting,
  pickingUp,
}
