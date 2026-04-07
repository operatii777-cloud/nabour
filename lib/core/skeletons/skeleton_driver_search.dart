import 'package:flutter/material.dart';
import 'skeleton_widget.dart';

/// Skeleton pentru ecranul de căutare șofer.
/// Afișat în searching_for_driver_screen.dart cât timp se caută.
class SkeletonDriverSearch extends StatelessWidget {
  const SkeletonDriverSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const SkeletonBox(width: 80, height: 80, borderRadius: 40),
        const SizedBox(height: 16),
        const SkeletonBox(width: 200, height: 18),
        const SizedBox(height: 8),
        const SkeletonBox(width: 140, height: 14),
        const SizedBox(height: 32),
        ...List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 24),
            child: SkeletonBox(
              width: double.infinity,
              height: 50,
              borderRadius: 12,
            ),
          ),
        ),
      ],
    );
  }
}
