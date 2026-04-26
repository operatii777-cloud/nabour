import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/services/ghost_mode_service.dart';

// Sentinel: alegere „invizibil permanent"
const Duration _kInvisibleChoice = Duration(microseconds: -1);

/// Sheet cu opțiunile de vizibilitate socială ale utilizatorului pe hartă.
///
/// Returnează:
///  • `null`                   — utilizatorul a închis fără alegere
///  • `_kInvisibleChoice`      — dorește mod fantomă (invizibil)
///  • `Duration.zero`          — vizibil permanent (fără limită de timp)
///  • altă [Duration]          — vizibil pentru durata aleasă
class GhostModeSheet extends StatelessWidget {
  const GhostModeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtleColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    final bool currentlyBlocking = GhostModeService.instance.isBlocking;

    // Duration until midnight (for "Until tomorrow" option)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final untilMidnight = midnight.difference(now);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: subtleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            loc.mapGhostDurationTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            loc.mapGhostDurationSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Invisible / Ghost toggle
          _DurationTile(
            icon: Icons.visibility_off_rounded,
            iconColor: const Color(0xFF9C27B0),
            label: loc.mapGhostInvisibleLabel,
            subtitle: loc.mapGhostInvisibleSub,
            selected: currentlyBlocking,
            isDark: isDark,
            onTap: () => Navigator.pop(context, _kInvisibleChoice),
          ),
          const SizedBox(height: 8),

          // Permanent visible
          _DurationTile(
            icon: Icons.visibility_rounded,
            iconColor: const Color(0xFF4CAF50),
            label: loc.mapGhostPermanentLabel,
            subtitle: loc.mapGhostPermanentSub,
            selected: !currentlyBlocking,
            isDark: isDark,
            onTap: () => Navigator.pop(context, Duration.zero),
          ),
          const SizedBox(height: 12),

          // Timed options
          _DurationTile(
            icon: Icons.timer_outlined,
            iconColor: Colors.blue,
            label: loc.mapGhostOneHourLabel,
            subtitle: loc.mapGhostOneHourSub,
            selected: false,
            isDark: isDark,
            onTap: () => Navigator.pop(context, const Duration(hours: 1)),
          ),
          const SizedBox(height: 8),
          _DurationTile(
            icon: Icons.timer_outlined,
            iconColor: Colors.orange,
            label: loc.mapGhostFourHoursLabel,
            subtitle: loc.mapGhostFourHoursSub,
            selected: false,
            isDark: isDark,
            onTap: () => Navigator.pop(context, const Duration(hours: 4)),
          ),
          const SizedBox(height: 8),
          _DurationTile(
            icon: Icons.nights_stay_outlined,
            iconColor: Colors.deepPurple,
            label: loc.mapGhostUntilTomorrowLabel,
            subtitle: loc.mapGhostUntilTomorrowSub,
            selected: false,
            isDark: isDark,
            onTap: () => Navigator.pop(context, untilMidnight),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DurationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _DurationTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? iconColor.withValues(alpha: 0.12)
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade50);
    final border = selected
        ? iconColor.withValues(alpha: 0.5)
        : (isDark ? Colors.grey.shade700 : Colors.grey.shade200);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: iconColor, size: 22),
          ],
        ),
      ),
    );
  }
}
