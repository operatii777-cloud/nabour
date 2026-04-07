import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Model pentru rute alternative
class AlternativeRoute {
  final String id;
  final String name;
  final double distance; // în km
  final double duration; // în minute
  final String description; // "Fastest", "Shortest", "Avoids tolls", etc.
  final List<Point> waypoints;

  AlternativeRoute({
    required this.id,
    required this.name,
    required this.distance,
    required this.duration,
    required this.description,
    required this.waypoints,
  });
}

/// Widget pentru afișarea rutelor alternative (Uber-like)
class AlternativeRoutesWidget extends StatelessWidget {
  final List<AlternativeRoute> routes;
  final AlternativeRoute? selectedRoute;
  final ValueChanged<AlternativeRoute> onRouteSelected;

  const AlternativeRoutesWidget({
    super.key,
    required this.routes,
    this.selectedRoute,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.alt_route,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Rute Alternative',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...routes.map((route) => _buildRouteOption(context, route)),
        ],
      ),
    );
  }

  Widget _buildRouteOption(BuildContext context, AlternativeRoute route) {
    final isSelected = selectedRoute?.id == route.id;
    final isFastest = route.description.toLowerCase().contains('fastest') ||
        route.description.toLowerCase().contains('cel mai rapid');
    final isShortest = route.description.toLowerCase().contains('shortest') ||
        route.description.toLowerCase().contains('cel mai scurt');

    return InkWell(
      onTap: () => onRouteSelected(route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Route indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getRouteColor(route),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            
            // Route info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isFastest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CEL MAI RAPID',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      if (isShortest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CEL MAI SCURT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.route,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${route.distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${route.duration.toStringAsFixed(0)} min',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Color _getRouteColor(AlternativeRoute route) {
    if (route.description.toLowerCase().contains('fastest') ||
        route.description.toLowerCase().contains('cel mai rapid')) {
      return Colors.orange;
    } else if (route.description.toLowerCase().contains('shortest') ||
        route.description.toLowerCase().contains('cel mai scurt')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }
}

