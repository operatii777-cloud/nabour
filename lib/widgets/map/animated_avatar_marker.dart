import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedAvatarMarker extends StatefulWidget {
  final String assetPath;
  final double size;
  final bool isFloating;
  final bool showShadow;
  final String? name;
  final double? speedKph;

  const AnimatedAvatarMarker({
    super.key,
    required this.assetPath,
    this.size = 50.0,
    this.isFloating = true,
    this.showShadow = true,
    this.name,
    this.speedKph,
  });

  @override
  State<AnimatedAvatarMarker> createState() => _AnimatedAvatarMarkerState();
}

class _AnimatedAvatarMarkerState extends State<AnimatedAvatarMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curSpeed = widget.speedKph ?? 0.0;
    final isMoving = curSpeed > 6.0; // 6 km/h: acoperă zgomotul GPS tipic (≤3 km/h) și mersul pe jos

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatValue = widget.isFloating ? math.sin(_controller.value * 2 * math.pi) * 5 : 0.0;
        final scaleValue = 1.0 + (math.sin(_controller.value * 2 * math.pi) * 0.05);

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Subtile Shadow
                if (widget.isFloating && widget.showShadow)
                  Transform.translate(
                    offset: const Offset(0, 10),
                    child: Container(
                        width: widget.size * 0.6 * scaleValue,
                        height: widget.size * 0.2,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              // Impeller fix: opacity direct în culoarea shadow în loc de Opacity widget
                              color: Colors.black.withValues(alpha: (0.2 + (floatValue.abs() / 20)) * 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                    ),
                  ),
                // The Avatar
                Transform.translate(
                  offset: Offset(0, floatValue - 10), // -10 to center better
                  child: Image.asset(
                    widget.assetPath,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback in case asset is wrong
                      return Icon(Icons.person_pin_circle, size: widget.size, color: Colors.purpleAccent);
                    },
                  ),
                ),
              ],
            ),
            if (widget.name != null && widget.name!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
                ),
                child: Text(
                  widget.name!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (isMoving) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD946FF), // Mov neon asortat cu strada
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD946FF).withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  '${curSpeed.round()} km/h',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
