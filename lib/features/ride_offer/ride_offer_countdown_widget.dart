import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nabour_app/core/haptics/haptic_service.dart';
import 'ride_offer_model.dart';

/// Bottom sheet complet cu oferta de cursă + countdown circular 15s.
/// Afișat peste MapScreen când șoferul primește o ofertă.
/// Se auto-închide la expirare cu reject implicit.
class RideOfferCountdownSheet extends StatefulWidget {
  final RideOfferModel offer;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideOfferCountdownSheet({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<RideOfferCountdownSheet> createState() =>
      _RideOfferCountdownSheetState();
}

class _RideOfferCountdownSheetState extends State<RideOfferCountdownSheet>
    with TickerProviderStateMixin {
  late int _secondsLeft;
  late Timer _timer;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.offer.countdownSeconds;

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.offer.countdownSeconds),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);

      // Ultimele 5 secunde: haptic + pulse animație
      if (_secondsLeft <= 5 && _secondsLeft > 0) {
        HapticService.instance.light();
        _pulseController.forward(from: 0);
      }
      if (_secondsLeft <= 0) {
        t.cancel();
        widget.onReject();
      }
    });

    // Haptic la primire
    HapticService.instance.notification();
  }

  @override
  void dispose() {
    _timer.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _countdownColor {
    if (_secondsLeft > 10) return Colors.green;
    if (_secondsLeft > 5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header: countdown + titlu
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (_, __) => CircularProgressIndicator(
                        value: 1 - _progressController.value,
                        strokeWidth: 4,
                        color: _countdownColor,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    Center(
                      child: Text(
                        '$_secondsLeft',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _countdownColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cursă nouă disponibilă',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${widget.offer.distanceToPickupKm.toStringAsFixed(1)} km până la pasager',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Pasager info
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: widget.offer.passengerPhotoUrl.isNotEmpty
                    ? NetworkImage(widget.offer.passengerPhotoUrl)
                    : null,
                child: widget.offer.passengerPhotoUrl.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.offer.passengerName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Colors.amber),
                        Text(
                          ' ${widget.offer.passengerRating.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Câștig estimat
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.offer.estimatedEarnings.toStringAsFixed(2)} RON',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '${widget.offer.rideTotalDistanceKm.toStringAsFixed(1)} km cursă',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Adrese
          _AddressRow(
            icon: Icons.radio_button_checked,
            color: Colors.blue,
            address: widget.offer.pickupAddress,
          ),
          const SizedBox(height: 6),
          _AddressRow(
            icon: Icons.location_on,
            color: Colors.red,
            address: widget.offer.destinationAddress,
          ),
          const SizedBox(height: 20),

          // Butoane Accept / Reject
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticService.instance.medium();
                    widget.onReject();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Refuză', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    HapticService.instance.heavy();
                    widget.onAccept();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Acceptă',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String address;

  const _AddressRow({
    required this.icon,
    required this.color,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
