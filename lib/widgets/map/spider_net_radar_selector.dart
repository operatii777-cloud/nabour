import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Size;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class SpiderNetRadarSelector extends StatefulWidget {
  final Point? center;
  final double radius;
  final Function(Point center, double radius) onUpdate;
  final VoidCallback onConfirm;
  final MapboxMap? mapboxMap;

  const SpiderNetRadarSelector({
    super.key,
    required this.center,
    required this.radius,
    required this.onUpdate,
    required this.onConfirm,
    this.mapboxMap,
  });

  @override
  State<SpiderNetRadarSelector> createState() => _SpiderNetRadarSelectorState();
}

class _SpiderNetRadarSelectorState extends State<SpiderNetRadarSelector> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  ScreenCoordinate? _centerScreenPos;
  Timer? _scanTimer;
  /// Câte secunde mai durează scanarea (0 = nu rulează).
  int _scanSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _updateScreenPos();
  }

  @override
  void didUpdateWidget(SpiderNetRadarSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.center != oldWidget.center) {
      _updateScreenPos();
    }
  }

  Future<void> _updateScreenPos() async {
    if (widget.center == null || widget.mapboxMap == null) return;
    final pos = await widget.mapboxMap!.pixelForCoordinate(widget.center!);
    if (mounted) {
      setState(() {
        _centerScreenPos = pos;
      });
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  static const int _kScanDurationSec = 5;

  void _startTimedScan() {
    if (_scanSecondsRemaining > 0) return;
    setState(() => _scanSecondsRemaining = _kScanDurationSec);
    _scanTimer?.cancel();
    _pulseController.repeat();
    var elapsed = 0;
    _scanTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        _pulseController.stop();
        return;
      }
      elapsed++;
      if (elapsed >= _kScanDurationSec) {
        t.cancel();
        _pulseController.stop();
        _pulseController.reset();
        if (!mounted) return;
        setState(() => _scanSecondsRemaining = 0);
        widget.onConfirm();
      } else {
        setState(() => _scanSecondsRemaining = _kScanDurationSec - elapsed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.center == null || _centerScreenPos == null) return const SizedBox.shrink();

    final double pixelRadius = widget.radius; 

    return Stack(
      children: [
        Positioned(
          left: _centerScreenPos!.x - pixelRadius,
          top: _centerScreenPos!.y - pixelRadius,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scanning = _scanSecondsRemaining > 0;
              return GestureDetector(
                onPanUpdate: scanning
                    ? null
                    : (details) {
                        final dx = details.localPosition.dx - pixelRadius;
                        final dy = details.localPosition.dy - pixelRadius;
                        final newRadius = sqrt(dx * dx + dy * dy);
                        widget.onUpdate(widget.center!, newRadius.clamp(50.0, 300.0));
                      },
                child: CustomPaint(
                  size: ui.Size(pixelRadius * 2, pixelRadius * 2),
                  painter: RadarSpiderPainter(
                    pulseValue: _pulseController.value,
                    radius: pixelRadius,
                  ),
                ),
              );
            },
          ),
        ),
        
        Positioned(
          left: _centerScreenPos!.x - 75, // Centrat aproximativ (lățime ~150px)
          top: _centerScreenPos!.y + 30, // Mutat în interiorul cercului
          child: ElevatedButton.icon(
            onPressed: _scanSecondsRemaining > 0 ? null : _startTimedScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              disabledBackgroundColor: const Color(0xFF6D28D9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 10,
            ),
            icon: _scanSecondsRemaining > 0
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  )
                : const Icon(Icons.radar, size: 20),
            label: Text(
              _scanSecondsRemaining > 0
                  ? 'Scanează… $_scanSecondsRemaining s'
                  : 'SCANEAZĂ',
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}

class RadarSpiderPainter extends CustomPainter {
  final double pulseValue;
  final double radius;

  RadarSpiderPainter({required this.pulseValue, required this.radius});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final center = ui.Offset(size.width / 2, size.height / 2);
    final neonColor = const Color(0xFF7C3AED);
    
    final circlePaint = ui.Paint()
      ..color = neonColor.withValues(alpha: 0.8)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, circlePaint);

    final scanPaint = ui.Paint()
      ..shader = ui.Gradient.sweep(
        center,
        [neonColor.withValues(alpha: 0), neonColor],
        [0.7, 1.0],
        ui.TileMode.clamp,
        pulseValue * 2 * pi,
        pulseValue * 2 * pi + pi / 2,
      );
    
    canvas.drawCircle(center, radius, scanPaint);

    final netPaint = ui.Paint()
      ..color = neonColor.withValues(alpha: 0.2)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (var i = 1; i <= 3; i++) {
        canvas.drawCircle(center, radius * (i / 3), netPaint);
    }

    for (var i = 0; i < 8; i++) {
        final angle = i * pi / 4;
        final end = center + ui.Offset(cos(angle) * radius, sin(angle) * radius);
        canvas.drawLine(center, end, netPaint);
    }

    final corePaint = ui.Paint()
      ..color = neonColor.withValues(alpha: 0.5 * (1 - pulseValue))
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(center, 10 + 20 * pulseValue, corePaint);
  }

  @override
  bool shouldRepaint(RadarSpiderPainter oldDelegate) => true;
}
