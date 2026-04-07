import 'package:flutter/material.dart';

/// Bottom bar central cu 3 butoane circulare stil Bump.
/// [onLeft] = dismiss/close, [onCenter] = acțiune principală, [onRight] = history/activity.
class BumpBottomBar extends StatelessWidget {
  final VoidCallback? onLeft;
  final VoidCallback? onCenter;
  final VoidCallback? onRight;
  /// Al patrulea buton (ex. deschide cardul plecare/destinație), între vizibilitate și prieteni.
  final VoidCallback? onItinerary;
  final IconData leftIcon;
  final IconData centerIcon;
  final IconData rightIcon;
  final IconData itineraryIcon;
  final int? badge;

  const BumpBottomBar({
    super.key,
    this.onLeft,
    this.onCenter,
    this.onRight,
    this.onItinerary,
    this.leftIcon = Icons.close_rounded,
    this.centerIcon = Icons.people_alt_rounded,
    this.rightIcon = Icons.access_time_rounded,
    this.itineraryIcon = Icons.edit_location_alt_rounded,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final w = MediaQuery.sizeOf(context).width;
    final narrow = w < 340;
    final gap = narrow ? 8.0 : 14.0;
    final side = narrow ? 42.0 : 48.0;
    final mid = narrow ? 50.0 : 56.0;
    final itinerarySize = narrow ? 40.0 : 46.0;
    return Positioned(
      bottom: 16 + bottomPad,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCircle(
            icon: leftIcon,
            onTap: onLeft,
            size: side,
            bgColor: Colors.white,
            iconColor: Colors.black87,
            borderColor: Colors.grey.shade300,
          ),
          if (onItinerary != null) ...[
            SizedBox(width: gap),
            _buildCircle(
              icon: itineraryIcon,
              onTap: onItinerary,
              size: itinerarySize,
              bgColor: Colors.white,
              iconColor: const Color(0xFF0EA5E9),
              borderColor: const Color(0xFF0EA5E9),
            ),
          ],
          SizedBox(width: gap),
          _buildCircle(
            icon: centerIcon,
            onTap: onCenter,
            size: mid,
            bgColor: const Color(0xFF7C3AED),
            iconColor: Colors.white,
            badge: badge,
          ),
          SizedBox(width: gap),
          _buildCircle(
            icon: rightIcon,
            onTap: onRight,
            size: side,
            bgColor: Colors.white,
            iconColor: const Color(0xFF7C3AED),
            borderColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle({
    required IconData icon,
    VoidCallback? onTap,
    double size = 50,
    Color bgColor = Colors.white,
    Color iconColor = Colors.black,
    Color? borderColor,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: size * 0.44),
          ),
          if (badge != null && badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints:
                    const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: badge > 9 ? 10 : 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
