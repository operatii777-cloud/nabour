import 'package:flutter/material.dart';

/// Banner de navigare afișat în josul hărții Mapbox principale
/// când utilizatorul navighează cu Nabour (modul intern).
class MapNavBanner extends StatelessWidget {
  final String instruction;
  final String destLabel;
  final double remainDistanceM;
  final Duration remainEta;
  final VoidCallback onStop;

  const MapNavBanner({
    super.key,
    required this.instruction,
    required this.destLabel,
    required this.remainDistanceM,
    required this.remainEta,
    required this.onStop,
  });

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatEta(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}min';
    if (m == 0) return '< 1 min';
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomPad + 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        instruction.isEmpty ? 'Navighezi către $destLabel' : instruction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: onStop,
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                      tooltip: 'Oprește navigarea',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (remainDistanceM > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.straighten_rounded, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatDistance(remainDistanceM),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time_rounded, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatEta(remainEta),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
