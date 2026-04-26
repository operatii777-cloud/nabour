import 'package:flutter/material.dart';

class MapRideInfoPanel extends StatelessWidget {
  final double? pickupLatitude;
  final double? destinationLatitude;
  final String pickupText;
  final String destinationText;
  final int stopsCount;
  final VoidCallback onClearPickup;
  final VoidCallback onClearDestination;
  final VoidCallback onStartRide;

  const MapRideInfoPanel({
    super.key,
    this.pickupLatitude,
    this.destinationLatitude,
    required this.pickupText,
    required this.destinationText,
    required this.stopsCount,
    required this.onClearPickup,
    required this.onClearDestination,
    required this.onStartRide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.12).round()),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withAlpha((255 * 0.4).round()),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            Text(
              'Confirmă detaliile cursei',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),

            // Pickup Row
            if (pickupLatitude != null)
              _buildLocationItem(
                context,
                icon: Icons.my_location_rounded,
                color: Colors.blue,
                label: 'Plecare',
                text: pickupText,
                onClear: onClearPickup,
              ),
            
            if (pickupLatitude != null && destinationLatitude != null)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Container(
                  height: 10,
                  width: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),

            // Destination Row
            if (destinationLatitude != null)
              _buildLocationItem(
                context,
                icon: Icons.location_on_rounded,
                color: Colors.green,
                label: 'Destinație',
                text: destinationText,
                onClear: onClearDestination,
              ),

            if (stopsCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚡ $stopsCount opriri pe traseu',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Main Action Button
            _buildStartRideButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String text,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: theme.colorScheme.outline, size: 20),
            onPressed: onClear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStartRideButton(BuildContext context) {
    final canStartRide = pickupLatitude != null && destinationLatitude != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canStartRide ? onStartRide : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canStartRide ? Colors.black : Colors.grey.shade300,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          elevation: 0,
        ),
        child: Text(
          canStartRide ? 'Confirmă Cursa' : 'Selectează Pickup și Destinație',
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

