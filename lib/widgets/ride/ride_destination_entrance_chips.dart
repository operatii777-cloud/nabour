import 'package:flutter/material.dart';

class RideDestinationEntranceChips extends StatelessWidget {
  final void Function(String entry) onEntrySelected;

  const RideDestinationEntranceChips({
    super.key,
    required this.onEntrySelected,
  });

  @override
  Widget build(BuildContext context) {
    final entries = ['Nord', 'Est', 'Sud', 'Vest'];
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Alege intrarea',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries.map((e) {
                return ActionChip(
                  label: Text(e),
                  onPressed: () => onEntrySelected(e),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
