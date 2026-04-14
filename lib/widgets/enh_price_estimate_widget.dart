import 'package:flutter/material.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/theme/app_text_styles.dart';

/// Widget îmbunătățit pentru estimare preț (Uber-like)
/// Afișează prețurile pentru toate categoriile cu comparație vizuală
class EnhancedPriceEstimateWidget extends StatelessWidget {
  final Map<RideCategory, Map<String, double>> faresByCategory;
  final RideCategory selectedCategory;
  final double distanceInKm;
  final double durationInMinutes;
  final Function(RideCategory) onCategorySelected;
  final bool showComparison;

  const EnhancedPriceEstimateWidget({
    super.key,
    required this.faresByCategory,
    required this.selectedCategory,
    required this.distanceInKm,
    required this.durationInMinutes,
    required this.onCategorySelected,
    this.showComparison = true,
  });

  @override
  Widget build(BuildContext context) {
    if (faresByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.volunteer_activism, // Changed from attach_money
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Opțiuni Neighbor', // Changed from Estimare Preț
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Distance and Duration - wrapped in Flexible to prevent overflow
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInfoChip(
                        context,
                        Icons.route,
                        '${distanceInKm.toStringAsFixed(1)} km',
                      ),
                      const SizedBox(width: 3),
                      _buildInfoChip(
                        context,
                        Icons.access_time,
                        '${durationInMinutes.round()} min',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Price breakdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected category price (highlighted)
                _buildSelectedCategoryCard(context),
                
                if (showComparison) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Compară cu alte categorii:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Other categories
                  ...RideCategory.values
                      .where((cat) => cat != selectedCategory)
                      .map((category) => _buildCategoryComparisonCard(
                            context,
                            category,
                            faresByCategory[category],
                          )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCategoryCard(BuildContext context) {
    if (faresByCategory[selectedCategory] == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getCategoryIcon(selectedCategory),
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              selectedCategory.displayName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryComparisonCard(
    BuildContext context,
    RideCategory category,
    Map<String, double>? fare,
  ) {
    if (fare == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () => onCategorySelected(category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha((255 * 0.3).round()),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getCategoryIcon(category),
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              category.displayName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(RideCategory category) {
    switch (category) {
      case RideCategory.any:
        return Icons.directions_car_filled;
      case RideCategory.standard:
        return Icons.directions_car;
      case RideCategory.family:
        return Icons.family_restroom;
      case RideCategory.energy:
        return Icons.eco;
      case RideCategory.best:
        return Icons.star;
      case RideCategory.utility:
        return Icons.local_shipping;
    }
  }
}

