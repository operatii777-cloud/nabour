import 'package:flutter/material.dart';
import 'skeleton_widget.dart';

/// Skeleton pentru un card din istoricul curselor.
/// Folosit în: history_screen.dart, wallet_screen.dart
class SkeletonRideCard extends StatelessWidget {
  const SkeletonRideCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 44, height: 44, borderRadius: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 160, height: 12),
                SizedBox(height: 6),
                SkeletonBox(width: 100, height: 10),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonBox(width: 60, height: 20),
        ],
      ),
    );
  }
}
