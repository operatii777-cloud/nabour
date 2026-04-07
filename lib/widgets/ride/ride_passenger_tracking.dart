import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RidePassengerTracking extends StatefulWidget {
  final bool isPassengerTrackingMode;
  final double currentSpeed;
  final Duration? pickupEta;
  final Duration? destinationEta;
  final DateTime? pickupArrivalTime;
  final DateTime? destinationArrivalTime;
  final double? pickupDistanceKm;
  final double? destinationDistanceKm;
  final bool shouldShowDriverMarker;
  final String? routeTrafficSummary;

  const RidePassengerTracking({
    super.key,
    required this.isPassengerTrackingMode,
    required this.currentSpeed,
    required this.shouldShowDriverMarker,
    this.pickupEta,
    this.destinationEta,
    this.pickupArrivalTime,
    this.destinationArrivalTime,
    this.pickupDistanceKm,
    this.destinationDistanceKm,
    this.routeTrafficSummary,
  });

  @override
  State<RidePassengerTracking> createState() => _RidePassengerTrackingState();
}

class _RidePassengerTrackingState extends State<RidePassengerTracking> {
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isPassengerTrackingMode) {
      return const SizedBox.shrink();
    }

    final speedKmh = widget.currentSpeed * 3.6;
    final colors = Theme.of(context).colorScheme;

    if (_minimized) {
      // ── Minimized bottom bar ──────────────────────────────────────────
      final bottomInset = MediaQuery.of(context).padding.bottom;
      return Positioned(
        bottom: 24 + bottomInset,
        left: 20,
        right: 20,
        child: GestureDetector(
          onTap: () => setState(() => _minimized = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.drive_eta_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.pickupEta != null
                        ? 'Preluare în ${widget.pickupEta!.inMinutes} min'
                        : widget.destinationEta != null
                            ? 'Destinație în ${widget.destinationEta!.inMinutes} min'
                            : 'Cursă activă',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.expand_less_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      );
    }

    // ── Full Premium Bottom Panel ──────────────────────────────────────────
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Driver Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colors.primary.withAlpha(20),
                    child: Icon(Icons.person_rounded, color: colors.primary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Șoferul este pe drum',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                            const Text(' 4.9', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text(
                              speedKmh > 5 ? '${speedKmh.toStringAsFixed(0)} km/h' : 'Staționat',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _minimized = true),
                    icon: const Icon(Icons.expand_more_rounded),
                    style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Ride Details (ETA & Distance)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha(5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.primary.withAlpha(15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _EtaBlock(
                        label: 'PRELUARE',
                        eta: widget.pickupEta,
                        distanceKm: widget.pickupDistanceKm,
                        arrivalTime: widget.pickupArrivalTime,
                        arrivalLabel: 'Ora',
                        colors: colors,
                      ),
                    ),
                    Container(width: 1, height: 40, color: colors.primary.withAlpha(20)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _EtaBlock(
                        label: 'DESTINAȚIE',
                        eta: widget.destinationEta,
                        distanceKm: widget.destinationDistanceKm,
                        arrivalTime: widget.destinationArrivalTime,
                        arrivalLabel: 'Ora',
                        colors: colors,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (widget.routeTrafficSummary != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    const Icon(Icons.traffic_rounded, size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.routeTrafficSummary!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Bottom Actions (Simulated space for Chat/Safety etc)
            SizedBox(height: bottomInset),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                   const Expanded(
                    child: Text(
                      'Nabour Ride Premium',
                      style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                  ),
                  Icon(Icons.verified_user_rounded, color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 4),
                  const Text('Siguranță activă', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EtaBlock extends StatelessWidget {
  final String label;
  final Duration? eta;
  final double? distanceKm;
  final DateTime? arrivalTime;
  final String arrivalLabel;
  final ColorScheme colors;

  const _EtaBlock({
    required this.label,
    required this.eta,
    required this.distanceKm,
    required this.arrivalTime,
    required this.arrivalLabel,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          eta != null ? '${eta!.inMinutes} min' : '—',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary),
        ),
        if (distanceKm != null)
          Text(
            '${distanceKm!.toStringAsFixed(1)} km',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        if (arrivalTime != null)
          Text(
            '$arrivalLabel ~${DateFormat.Hm().format(arrivalTime!)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }
}
