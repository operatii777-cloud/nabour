import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nabour_app/models/neighbor_location_model.dart';

/// Animație ecran complet la întâlnire în proximitate (efect „Hit”).
class NeighborBumpMatchOverlay extends StatefulWidget {
  const NeighborBumpMatchOverlay({
    super.key,
    required this.neighbor,
    required this.onFinished,
  });

  final NeighborLocation neighbor;
  final VoidCallback onFinished;

  static void show(BuildContext context, NeighborLocation neighbor) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => NeighborBumpMatchOverlay(
        neighbor: neighbor,
        onFinished: () {
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<NeighborBumpMatchOverlay> createState() =>
      _NeighborBumpMatchOverlayState();
}

class _NeighborBumpMatchOverlayState extends State<NeighborBumpMatchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onFinished,
        child: AnimatedBuilder(
          animation: t,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RipplePainter(progress: t.value, color: const Color(0xFF7C3AED)),
                  ),
                ),
                Center(
                  child: Transform.scale(
                    scale: 0.4 + 0.65 * math.sin(t.value * math.pi * 0.85),
                    child: Opacity(
                      opacity: (1.0 - (t.value - 0.65).clamp(0.0, 0.35) / 0.35 * 0.9)
                          .clamp(0.15, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.neighbor.avatar,
                            style: const TextStyle(fontSize: 72),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'HIT!',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.9),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.neighbor.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: size.height * 0.12,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Atinge oriunde pentru a închide',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = math.max(size.width, size.height) * 0.85;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 4; i++) {
      final p = ((progress * 1.15) - i * 0.18).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final radius = maxR * p;
      paint.color = color.withValues(alpha: (0.22 - i * 0.04) * (1 - p * 0.4));
      canvas.drawCircle(c, radius, paint);
    }

    final scrim = Paint()
      ..color = Colors.black.withValues(alpha: 0.35 * (1 - progress * 0.25));
    canvas.drawRect(Offset.zero & size, scrim);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
