import 'package:flutter/material.dart';
import 'package:nabour_app/models/driver_verification_model.dart';

/// Widget pentru badge-uri de verificare șofer (Uber-like)
class DriverVerificationBadgeWidget extends StatelessWidget {
  final DriverVerificationBadge badge;
  final bool showLabel;
  final double size;

  const DriverVerificationBadgeWidget({
    super.key,
    required this.badge,
    this.showLabel = true,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badge.color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badge.color,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badge.icon,
            size: size,
            color: badge.color,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              badge.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badge.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget pentru lista de badge-uri de verificare
class DriverVerificationBadgesList extends StatelessWidget {
  final List<DriverVerificationBadge> badges;
  final bool compact;

  const DriverVerificationBadgesList({
    super.key,
    required this.badges,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: badges.map((badge) {
          return DriverVerificationBadgeWidget(
            badge: badge,
            showLabel: false,
            size: 20,
          );
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verificări',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges.map((badge) {
            return DriverVerificationBadgeWidget(
              badge: badge,
            );
          }).toList(),
        ),
      ],
    );
  }
}

