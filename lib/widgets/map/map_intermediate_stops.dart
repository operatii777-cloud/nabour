import 'package:flutter/material.dart';

class MapIntermediateStops extends StatelessWidget {
  final List<String> stops;
  final void Function(String stop) onRemoveStop;

  const MapIntermediateStops({
    super.key,
    required this.stops,
    required this.onRemoveStop,
  });

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Opriri intermediare (${stops.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stops.length,
            itemBuilder: (context, index) {
              final stop = stops[index];
              return ListTile(
                leading: const Icon(Icons.location_on, color: Colors.orange),
                title: Text(stop),
                subtitle: Text(
                  'Oprire ${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onRemoveStop(stop),
                  tooltip: 'Șterge oprirea',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
