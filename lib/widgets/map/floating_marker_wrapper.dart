import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingMarkerWrapper extends StatefulWidget {
  final Widget child;
  final double size;
  final bool isFloating;
  final bool showShadow;

  const FloatingMarkerWrapper({
    super.key,
    required this.child,
    this.size = 40.0,
    this.isFloating = true,
    this.showShadow = true,
  });

  @override
  State<FloatingMarkerWrapper> createState() => _FloatingMarkerWrapperState();
}

class _FloatingMarkerWrapperState extends State<FloatingMarkerWrapper>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatValue = widget.isFloating ? math.sin(_controller.value * 2 * math.pi) * 4 : 0.0;
        final scaleValue = 1.0 + (math.sin(_controller.value * 2 * math.pi) * 0.04);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Shadow
            if (widget.isFloating && widget.showShadow)
              Transform.translate(
                offset: const Offset(0, 12),
                child: Container(
                    width: widget.size * 0.5 * scaleValue,
                    height: widget.size * 0.15,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          // Impeller fix: opacity direct în culoarea shadow în loc de Opacity widget
                          color: Colors.black.withValues(alpha: (0.15 + (floatValue.abs() / 25)) * 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ),
            // The Content
            Transform.translate(
              offset: Offset(0, floatValue),
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}
