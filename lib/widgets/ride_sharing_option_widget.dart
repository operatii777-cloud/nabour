import 'package:flutter/material.dart';

/// Widget pentru opțiunea de ride sharing (Uber-like)
class RideSharingOptionWidget extends StatelessWidget {
  final bool isEnabled;
  final bool isSelected;
  final double originalCost;
  final double? sharedCost;
  final ValueChanged<bool> onChanged;

  const RideSharingOptionWidget({
    super.key,
    required this.isEnabled,
    required this.isSelected,
    required this.originalCost,
    this.sharedCost,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final savings = sharedCost != null ? originalCost - sharedCost! : originalCost * 0.3;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isEnabled ? () => onChanged(!isSelected) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.people_outline,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Ride Sharing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Economisește ${savings.toStringAsFixed(2)} RON',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Călătorie partajată cu alți pasageri',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (sharedCost != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Preț original: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            '${originalCost.toStringAsFixed(2)} RON',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${sharedCost!.toStringAsFixed(2)} RON',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: isEnabled ? (value) => onChanged(value ?? false) : null,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

