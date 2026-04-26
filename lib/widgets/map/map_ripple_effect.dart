import 'package:flutter/material.dart';

class MapRippleEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onFinished;
  final Color color;

  const MapRippleEffect({
    super.key,
    required this.position,
    required this.onFinished,
    this.color = Colors.blue,
  });

  @override
  State<MapRippleEffect> createState() => _MapRippleEffectState();
}

class _MapRippleEffectState extends State<MapRippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _radiusAnimation = Tween<double>(begin: 0, end: 150).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.6), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.6, end: 0.0), weight: 80),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 150,
      top: widget.position.dy - 150,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return SizedBox(
              width: 300,
              height: 300,
              child: CustomPaint(
                painter: RipplePainter(
                  radius: _radiusAnimation.value,
                  opacity: _opacityAnimation.value,
                  color: widget.color,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final double radius;
  final double opacity;
  final Color color;

  RipplePainter({
    required this.radius,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Primary ripple
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, paint);

    // Secondary subtle ripple
    if (radius > 20) {
      final paint2 = Paint()
        ..color = color.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius * 0.7, paint2);
    }
    
    // Fill glow
    final paint3 = Paint()
      ..color = color.withValues(alpha: opacity * 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint3);
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.opacity != opacity;
  }
}
