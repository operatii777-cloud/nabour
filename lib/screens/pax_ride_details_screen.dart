import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/deprecated_apis_fix.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/models/user_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/screens/search_location_screen.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/utils/logger.dart';


/// Ecran premium de detalii cursă pentru pasageri
/// Oferă tracking live și management complet al cursei
class PassengerRideDetailsScreen extends StatefulWidget {
  final String rideId;
  final Ride ride;

  const PassengerRideDetailsScreen({
    super.key,
    required this.rideId,
    required this.ride,
  });

  @override
  State<PassengerRideDetailsScreen> createState() => _PassengerRideDetailsScreenState();
}

class _PassengerRideDetailsScreenState extends State<PassengerRideDetailsScreen>
    with TickerProviderStateMixin {
  
  final FirestoreService _firestoreService = FirestoreService();
  
  // Animation Controllers
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  
  // Animations
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // State variables
  UserModel? _driverProfile;
  Ride? _currentRide;
  StreamSubscription<Ride>? _rideSubscription;
  Timer? _etaTimer;
  bool _isLoading = true;
  
  // Progress tracking
  double _rideProgress = 0.0;
  String _statusMessage = 'Cursă programată';
  int? _estimatedArrivalTime;
  
  // Rating
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDriverProfile();
    _startRideTracking();
    _startEtaUpdates();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _rideSubscription?.cancel();
    _etaTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

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

    // Start animations
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadDriverProfile() async {
    if (widget.ride.driverId == null) return;
    
    try {
      final profileDoc = await _firestoreService.getProfileByIdStream(widget.ride.driverId!).first;
      if (profileDoc.exists) {
        setState(() {
          _driverProfile = UserModel.fromFirestore(profileDoc);
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading driver profile: $e', error: e);
      setState(() => _isLoading = false);
    }
  }

  void _startRideTracking() {
    _rideSubscription = _firestoreService.getRideStream(widget.rideId).listen((ride) {
      if (!mounted) return;

      setState(() {
        _currentRide = ride;
        _updateRideProgress(ride.status);
      });
    }, onError: (e) {
      Logger.error('Ride stream error: $e', tag: 'PASSENGER_DETAILS', error: e);
    });
  }

  void _startEtaUpdates() {
    _etaTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateEta();
    });
    _updateEta(); // Initial update
  }

  void _updateRideProgress(String status) {
    double progress;
    String message;
    
    switch (status) {
      case 'pending':
      case 'driver_found':
        progress = 0.2;
        message = 'Se caută șofer...';
        break;
      case 'accepted':
        progress = 0.4;
        message = 'Șoferul se îndreaptă către tine';
        break;
      case 'arrived':
        progress = 0.6;
        message = 'Șoferul a ajuns!';
        break;
      case 'in_progress':
        progress = 0.8;
        message = 'În cursă...';
        break;
      case 'completed':
        progress = 1.0;
        message = 'Cursă finalizată';
        break;
      case 'cancelled':
        progress = 0.0;
        message = 'Cursă anulată';
        break;
      default:
        progress = 0.0;
        message = 'Status necunoscut';
    }
    
    _rideProgress = progress;
    _statusMessage = message;
    _progressController.animateTo(progress);
  }

  Future<void> _updateEta() async {
    if (_currentRide?.status == 'in_progress') {
      // Calculate ETA to destination
      // This would normally use real-time traffic data
      setState(() {
        _estimatedArrivalTime = DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch;
      });
    } else if (_currentRide?.status == 'accepted') {
      // Calculate ETA for driver arrival
      setState(() {
        _estimatedArrivalTime = DateTime.now().add(const Duration(minutes: 8)).millisecondsSinceEpoch;
      });
    }
  }

  Future<void> _callDriver() async {
    if (_driverProfile?.phoneNumber != null) {
      final Uri phoneUri = Uri(scheme: 'tel', path: _driverProfile!.phoneNumber);
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

  void _messageDriver() {
    if (widget.ride.driverId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            rideId: widget.rideId,
            otherUserId: widget.ride.driverId!,
            otherUserName: _driverProfile?.displayName ?? 'Șofer',
            collectionName: 'ride_requests',
          ),
        ),
      );
    }
  }

  void _shareLocation() {
    final message = 'Urmărește-mi cursa live: https://friendsride.app/track/${widget.rideId}';
          DeprecatedAPIsFix.shareText(message);
  }

  void _emergencyContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Urgență'),
        content: const Text('Apelezi serviciile de urgență?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final Uri phoneUri = Uri(scheme: 'tel', path: '112');
              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sună 112', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _modifyDestination() async {
    // Verifică dacă cursa permite modificarea destinației
    if (_currentRide?.status == 'completed' || _currentRide?.status == 'cancelled') {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotModifyCompletedRide),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const SearchLocationScreen()),
    );

    if (result == null || !mounted) return;

    setState(() {
      // Show loading indicator
    });

    try {
      final newDestinationAddress = result['address'] as String;
      final newDestinationLatitude = result['latitude'] as double;
      final newDestinationLongitude = result['longitude'] as double;

      await _firestoreService.updateRideDestination(
        widget.rideId,
        newDestinationAddress,
        newDestinationLatitude,
        newDestinationLongitude,
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.destinationUpdatedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorUpdatingDestination(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          // Hide loading indicator
        });
      }
    }
  }

  void _addStop() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Funcția de adăugare oprire va fi disponibilă în curând'),
      ),
    );
  }

  Future<void> _cancelRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anulezi cursa?'),
        content: const Text(
          'Ești sigur că vrei să anulezi această cursă? '
          'S-ar putea să se aplice o taxă de anulare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nu'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Da, anulează', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.cancelRide(widget.rideId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cursa a fost anulată'),
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

  void _viewReceipt() {
    // Receipt screen removed (Nabour is free — no receipts needed)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Detalii Cursă'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _shareLocation,
            icon: const Icon(Icons.share_location),
            tooltip: 'Trimite locația',
          ),
          IconButton(
            onPressed: _emergencyContact,
            icon: const Icon(Icons.emergency, color: Colors.red),
            tooltip: 'Urgență',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    // Feature: Pickup code — show code when driver is on the way or arrived
                    if (_currentRide?.pickupCode != null &&
                        (_currentRide?.status == 'driver_found' ||
                         _currentRide?.status == 'accepted' ||
                         _currentRide?.status == 'arrived')) ...[
                      _buildPickupCodeCard(_currentRide!.pickupCode!),
                      const SizedBox(height: 16),
                    ],
                    if (_driverProfile != null) ...[
                      _buildDriverCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildRideProgressCard(),
                    const SizedBox(height: 16),
                    _buildCommunicationHub(),
                    const SizedBox(height: 16),
                    _buildRideManagement(),
                    const SizedBox(height: 16),
                    _buildFareBreakdown(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Feature: Pickup code — displays the 4-digit code for the driver to verify.
  Widget _buildPickupCodeCard(String code) {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pin, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Cod de preluare',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Arată acest cod șoferului la preluare',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_estimatedArrivalTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'ETA: ${_formatEta(_estimatedArrivalTime!)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) => LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Șoferul tău',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: _driverProfile!.profileImageUrl != null
                      ? NetworkImage(_driverProfile!.profileImageUrl!)
                      : null,
                  child: _driverProfile!.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 35,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverProfile!.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${_driverProfile!.averageRating?.toStringAsFixed(1) ?? 'N/A'} ⭐',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      if (_driverProfile!.licensePlate != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _driverProfile!.licensePlate!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideProgressCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progres Cursă',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildProgressStep(
              icon: Icons.search,
              title: 'Căutare șofer',
              completed: _rideProgress >= 0.2,
              active: _rideProgress >= 0.0 && _rideProgress < 0.4,
            ),
            _buildProgressStep(
              icon: Icons.directions_car,
              title: 'Șofer în drum',
              completed: _rideProgress >= 0.4,
              active: _rideProgress >= 0.4 && _rideProgress < 0.6,
            ),
            _buildProgressStep(
              icon: Icons.location_on,
              title: 'Șofer sosit',
              completed: _rideProgress >= 0.6,
              active: _rideProgress >= 0.6 && _rideProgress < 0.8,
            ),
            _buildProgressStep(
              icon: Icons.navigation,
              title: 'În cursă',
              completed: _rideProgress >= 0.8,
              active: _rideProgress >= 0.8 && _rideProgress < 1.0,
            ),
            _buildProgressStep(
              icon: Icons.check_circle,
              title: 'Finalizat',
              completed: _rideProgress >= 1.0,
              active: false,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep({
    required IconData icon,
    required String title,
    required bool completed,
    required bool active,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: completed 
                    ? Colors.green 
                    : active 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check : icon,
                color: completed || active ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: completed || active 
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 20),
            width: 2,
            height: 20,
            color: completed 
                ? Colors.green 
                : Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildCommunicationHub() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.communication,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCommunicationButton(
                            icon: Icons.phone,
                            label: l10n.callDriver,
                            color: Colors.green,
                            onPressed: _callDriver,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCommunicationButton(
                            icon: Icons.message,
                            label: l10n.chat,
                            color: Colors.blue,
                            onPressed: _messageDriver,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCommunicationButton(
                    icon: Icons.share_location,
                    label: 'Trimite Locația',
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _shareLocation,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCommunicationButton(
                    icon: Icons.emergency,
                    label: 'Urgență',
                    color: Colors.red,
                    onPressed: _emergencyContact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationButton({
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRideManagement() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(
                  l10n.rideManagement,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            if (_currentRide?.status != 'completed' && _currentRide?.status != 'cancelled')
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Column(
                    children: [
                      _buildManagementOption(
                        icon: Icons.edit_location,
                        title: l10n.modifyDestination,
                        subtitle: l10n.changeFinalLocation,
                        onTap: _modifyDestination,
                      ),
                      _buildManagementOption(
                        icon: Icons.add_location,
                        title: l10n.addStop,
                        subtitle: l10n.intermediateStop,
                        onTap: _addStop,
                      ),
                      _buildManagementOption(
                        icon: Icons.cancel,
                        title: l10n.cancelRide,
                        subtitle: l10n.mayIncludeCancellationFee,
                        onTap: _cancelRide,
                        textColor: Colors.red,
                      ),
                    ],
                  );
                },
              ),
            if (_currentRide?.status == 'completed') ...[
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Column(
                    children: [
                      _buildManagementOption(
                        icon: Icons.receipt,
                        title: l10n.viewReceipt,
                        subtitle: l10n.completeRideDetails,
                        onTap: _viewReceipt,
                      ),
                      _buildManagementOption(
                        icon: Icons.star_rate,
                        title: l10n.rateRide,
                        subtitle: l10n.provideDriverFeedback,
                        onTap: () => _showRatingDialog(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManagementOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (textColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: textColor ?? Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFareBreakdown() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalii Tarif',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFareItem('Tarif de bază', '${widget.ride.totalCost.toStringAsFixed(2)} RON'),
            _buildFareItem('Distanța', '${widget.ride.distance.toStringAsFixed(1)} km'),
            _buildFareItem('Durata estimată', '${widget.ride.durationInMinutes?.toStringAsFixed(0) ?? 'N/A'} min'),
            if (_currentRide?.status == 'completed') ...[
              const Divider(),
              _buildFareItem(
                'Total plătit', 
                '${widget.ride.totalCost.toStringAsFixed(2)} RON',
                isTotal: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFareItem(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rateRide),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.howWasYourExperience),
            const SizedBox(height: 16),
            _buildStarRating(),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: l10n.optionalComments,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Mulțumim pentru feedback!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Trimite'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_currentRide?.status) {
      case 'pending':
      case 'driver_found':
        return Icons.search;
      case 'accepted':
        return Icons.directions_car;
      case 'arrived':
        return Icons.location_on;
      case 'in_progress':
        return Icons.navigation;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatEta(int timestamp) {
    final eta = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = eta.difference(now);
    
    if (difference.inMinutes < 1) {
      return 'Acum';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < (_selectedRating ?? 0) ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _selectedRating = index + 1;
            });
          },
        );
      }),
    );
  }
}
