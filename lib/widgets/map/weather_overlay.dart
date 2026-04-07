import 'dart:math' as math;
import 'package:flutter/material.dart';

enum WeatherType { sunny, cloudy, rainy, snowy, thunderstorm, none }

class WeatherOverlay extends StatefulWidget {
  final WeatherType type;
  const WeatherOverlay({super.key, required this.type});

  @override
  State<WeatherOverlay> createState() => _WeatherOverlayState();
}

class _WeatherOverlayState extends State<WeatherOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == WeatherType.none) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _WeatherPainter(type: widget.type, progress: _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _WeatherPainter extends CustomPainter {
  final WeatherType type;
  final double progress;
  _WeatherPainter({required this.type, required this.progress});

  final math.Random _random = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case WeatherType.rainy:
        _paintRain(canvas, size);
        break;
      case WeatherType.snowy:
        _paintSnow(canvas, size);
        break;
      case WeatherType.sunny:
        _paintSun(canvas, size);
        break;
      case WeatherType.thunderstorm:
        _paintThunder(canvas, size);
        break;
      default:
        break;
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 50; i++) {
        double startX = _random.nextDouble() * size.width;
        double startY = (_random.nextDouble() * size.height + progress * size.height) % size.height;
        canvas.drawLine(Offset(startX, startY), Offset(startX - 5, startY + 15), paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
        double startX = _random.nextDouble() * size.width + math.sin(progress * math.pi * 2 + i) * 10;
        double startY = (_random.nextDouble() * size.height + progress * size.height * 0.5) % size.height;
        canvas.drawCircle(Offset(startX, startY), _random.nextDouble() * 3 + 2, paint);
    }
  }

  void _paintSun(Canvas canvas, Size size) {
    // Subtle lens flare in top right
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.orange.withValues(alpha: 0.15),
          Colors.orange.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.8, 100), radius: 200 + math.sin(progress * math.pi) * 20));
    
    canvas.drawCircle(Offset(size.width * 0.8, 100), 300, paint);
  }

  void _paintThunder(Canvas canvas, Size size) {
    _paintRain(canvas, size);
    if (progress > 0.9) {
       canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: 0.1));
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter oldDelegate) => true;
}
