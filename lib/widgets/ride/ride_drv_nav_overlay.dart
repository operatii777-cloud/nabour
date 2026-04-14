import 'package:flutter/material.dart';

class RideDriverNavigationOverlay extends StatelessWidget {
  final double currentSpeed;
  final int currentSpeedLimit;
  final void Function(int newLimit) onSpeedLimitChanged;

  const RideDriverNavigationOverlay({
    super.key,
    required this.currentSpeed,
    required this.currentSpeedLimit,
    required this.onSpeedLimitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final speedKmh = currentSpeed * 3.6;
    final bool isOverSpeed = speedKmh > currentSpeedLimit + 3;

    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🧭 Driver Navigation',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                // Speed limit pill
                GestureDetector(
                  onTap: () {
                    // Cycle common limits 30→50→60→70→80→90→100→30
                    final List<int> limits = [30, 50, 60, 70, 80, 90, 100];
                    final idx = limits.indexOf(currentSpeedLimit);
                    final next = limits[(idx >= 0 ? (idx + 1) % limits.length : 1)];
                    onSpeedLimitChanged(next);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOverSpeed ? Colors.red : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isOverSpeed ? Colors.red.shade700 : Colors.grey.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.speed, size: 16, color: isOverSpeed ? Colors.white : Colors.black87),
                        const SizedBox(width: 6),
                        Text(
                          '$currentSpeedLimit',
                          style: TextStyle(
                            color: isOverSpeed ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${speedKmh.toStringAsFixed(0)} km/h',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
