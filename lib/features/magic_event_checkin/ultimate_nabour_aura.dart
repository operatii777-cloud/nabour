import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'magic_event_model.dart';

enum NabourAuraTheme {
  magic,   // Original: Blue/Purple/Pink/Gold
  safety,  // Emergency: Red/Orange/Blood/Fire
}

/// Slot for positioning [UltimateNabourAura] over a Mapbox map (screen pixels).
class NabourAuraMapSlot {
  final String eventId;
  final Offset screenCenter;
  final double radiusPx;
  final int userDensity;
  final int rippleTick;
  final String title;
  final DateTime endsAt;
  final MagicEvent? event;

  const NabourAuraMapSlot({
    required this.eventId,
    required this.screenCenter,
    required this.radiusPx,
    required this.userDensity,
    this.rippleTick = 0,
    this.title = '',
    required this.endsAt,
    this.event,
  });

  double get widgetExtent => (radiusPx * 2.9).clamp(200.0, 720.0);
}

/// Premium procedural aura: additive blend, flow particles, holographic shimmer,
/// double-beat pulse, optional tap burst.
class UltimateNabourAura extends StatefulWidget {
  final double radiusPx;
  /// Crowd metric (e.g. participantCount); drives intensity + particle budget.
  final int userDensity;
  /// Parent increments to trigger a shockwave ring (e.g. on geo check-in).
  final int rippleTick;
  final VoidCallback? onBurst;
  final VoidCallback? onTap;
  final String? eventTitle;
  final DateTime? endsAt;
  final NabourAuraTheme theme;

  const UltimateNabourAura({
    super.key,
    required this.radiusPx,
    this.userDensity = 24,
    this.rippleTick = 0,
    this.onBurst,
    this.onTap,
    this.eventTitle,
    this.endsAt,
    this.theme = NabourAuraTheme.magic,
  });

  @override
  State<UltimateNabourAura> createState() => _UltimateNabourAuraState();
}

class _UltimateNabourAuraState extends State<UltimateNabourAura>
    with TickerProviderStateMixin {
  late AnimationController _pulse;
  late AnimationController _burst;
  late List<FlowParticle> _particles;
  final math.Random _rng = math.Random();
  int _lastRippleTick = 0;

  int get _particleBudget =>
      (12 + (widget.userDensity * 0.45).round()).clamp(12, 72);

  double get _intensity =>
      (widget.userDensity / 100.0).clamp(0.35, 1.0).toDouble();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _particles =
        List.generate(_particleBudget, (_) => FlowParticle(_rng, widget.radiusPx));
    _lastRippleTick = widget.rippleTick;
  }

  @override
  void didUpdateWidget(covariant UltimateNabourAura oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.radiusPx != widget.radiusPx ||
        oldWidget.userDensity != widget.userDensity) {
      _particles =
          List.generate(_particleBudget, (_) => FlowParticle(_rng, widget.radiusPx));
    }
    if (widget.rippleTick != _lastRippleTick) {
      _lastRippleTick = widget.rippleTick;
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _burst.dispose();
    super.dispose();
  }

  /// Two soft peaks per cycle ("lub-dub").
  static double _heartbeatScale(double t) {
    double g(double c, double w) =>
        math.exp(-math.pow((t - c) / w, 2) as double);
    return 1.0 + 0.058 * g(0.20, 0.040) + 0.046 * g(0.34, 0.034);
  }

  void _handleTap() {
    widget.onTap?.call();
    _burst.forward(from: 0);
    widget.onBurst?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ext = (widget.radiusPx * 2.9).clamp(200.0, 720.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _burst]),
          builder: (context, _) {
            for (final p in _particles) {
              p.update();
            }
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(ext, ext),
                  painter: _MasterpieceAuraPainter(
                    pulseT: _pulse.value,
                    burstT: _burst.value,
                    scale: _heartbeatScale(_pulse.value),
                    particles: _particles,
                    radius: widget.radiusPx,
                    intensity: _intensity,
                    theme: widget.theme,
                  ),
                ),
                if (widget.endsAt != null)
                  _AuraCountdownCenter(
                    endsAt: widget.endsAt!,
                    intensity: _intensity,
                    eventTitle: widget.eventTitle,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Compact countdown label until end time (mockup-style timer).
class _AuraCountdownCenter extends StatefulWidget {
  final DateTime endsAt;
  final double intensity;
  final String? eventTitle;

  const _AuraCountdownCenter({
    required this.endsAt,
    required this.intensity,
    this.eventTitle,
  });

  @override
  State<_AuraCountdownCenter> createState() => _AuraCountdownCenterState();
}

class _AuraCountdownCenterState extends State<_AuraCountdownCenter> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      if (!mounted) return;
      if (DateTime.now().isAfter(widget.endsAt)) {
        _timer?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.endsAt.difference(DateTime.now());
    if (left.isNegative) {
      return const SizedBox.shrink();
    }
    final h = left.inHours;
    final m = left.inMinutes.remainder(60);
    final s = left.inSeconds.remainder(60);
    final text =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final glow = 4.0 + 10 * widget.intensity;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.eventTitle != null && widget.eventTitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              widget.eventTitle!.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: const Color(0xFFFF00D4), blurRadius: glow * 0.4),
                ],
              ),
            ),
          ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.white,
            shadows: [
              Shadow(color: const Color(0xFFFFE600), blurRadius: glow),
              Shadow(color: const Color(0xFFFF00D4), blurRadius: glow * 0.6),
            ],
          ),
        ),
        Text(
          'Hyper Gold',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.92),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _MasterpieceAuraPainter extends CustomPainter {
  final double pulseT;
  final double burstT;
  final double scale;
  final List<FlowParticle> particles;
  final double radius;
  final double intensity;
  final NabourAuraTheme theme;

  _MasterpieceAuraPainter({
    required this.pulseT,
    required this.burstT,
    required this.scale,
    required this.particles,
    required this.radius,
    required this.intensity,
    required this.theme,
  });

  // Theme: Magic (Original)
  static const Color _outerM = Color(0xFF0062FF);
  static const Color _purpleM = Color(0xFF7000FF);
  static const Color _pinkM = Color(0xFFFF00D4);
  static const Color _goldM = Color(0xFFFFE600);

  // Theme: Safety (Red Alert)
  static const Color _outerS = Color(0xFF7F1D1D); // Dark Blood Red
  static const Color _redS = Color(0xFFB91C1C);   // Bright Emergency Red
  static const Color _orangeS = Color(0xFFEA580C); // Alert Orange
  static const Color _glowS = Color(0xFFFDE047);  // Bright Yellow Glow

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Offset.zero & size;

    canvas.saveLayer(
      rect,
      Paint()..blendMode = BlendMode.plus,
    );

    final bool isSafety = theme == NabourAuraTheme.safety;
    final List<_AuraLayer> layers = isSafety 
      ? [
          _AuraLayer(_outerS, 1.42, 0.14),
          _AuraLayer(_redS, 1.02, 0.26),
          _AuraLayer(_orangeS, 0.62, 0.42),
          _AuraLayer(_glowS, 0.34, 0.72),
        ]
      : [
          _AuraLayer(_outerM, 1.42, 0.14),
          _AuraLayer(_purpleM, 1.02, 0.26),
          _AuraLayer(_pinkM, 0.62, 0.42),
          _AuraLayer(_goldM, 0.34, 0.72),
        ];

    for (final layer in layers) {
      final r = radius * layer.rMul * scale;
      final op = layer.opBase * intensity;
      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          center,
          r,
          [
            layer.color.withValues(alpha: op),
            layer.color.withValues(alpha: 0),
          ],
          const [0.28, 1.0],
        );
      canvas.drawCircle(center, r, paint);
    }

    _drawOrganicHalo(canvas, center, scale);

    _drawShimmer(canvas, center, size);

    _drawLensFlare(canvas, center, size);

    _drawOrbitalDust(canvas, center, scale);

    final Color pColorA = isSafety ? _redS : _pinkM;
    final Color pColorB = isSafety ? _glowS : _goldM;

    for (final p in particles) {
      final c = Color.lerp(pColorA, pColorB, 1.0 - p.life.clamp(0.0, 1.0))!;
      final paint = Paint()
        ..color = c.withValues(alpha: p.opacity * intensity)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, p.size * 0.85);
      canvas.drawCircle(
        Offset(center.dx + p.x, center.dy + p.y),
        p.size,
        paint,
      );
    }

    if (burstT > 0) {
      for (var i = 0; i < 3; i++) {
        final t = ((burstT - i * 0.12) / 0.88).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = (isSafety ? _glowS : _goldM).withValues(alpha: (1 - t) * 0.55 * intensity)
          ..blendMode = BlendMode.plus;
        canvas.drawCircle(center, radius * scale * (0.35 + t * 1.15), ringPaint);
      }
    }

    final coreR = radius * 0.11 * scale;
    final corePaint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(
        center,
        coreR * 1.6,
        [
          Colors.white.withValues(alpha: 0.75 * intensity),
          Colors.white.withValues(alpha: 0),
        ],
        const [0.15, 1.0],
      );
    canvas.drawCircle(center, coreR, corePaint);

    canvas.restore();
  }

  void _drawOrganicHalo(Canvas canvas, Offset center, double scale) {
    final bool isSafety = theme == NabourAuraTheme.safety;
    final path = Path();
    const steps = 48;
    final base = radius * 1.18 * scale;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final ang = t * math.pi * 2;
      final wobble =
          1.0 + 0.07 * math.sin(ang * 5 + pulseT * math.pi * 2) + 0.04 * math.sin(ang * 11);
      final r = base * wobble;
      final x = center.dx + math.cos(ang) * r;
      final y = center.dy + math.sin(ang) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..blendMode = BlendMode.plus
      ..color = (isSafety ? _redS : _pinkM).withValues(alpha: 0.22 * intensity);
    canvas.drawPath(path, paint);
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..blendMode = BlendMode.plus
      ..color = (isSafety ? _outerS : _outerM).withValues(alpha: 0.12 * intensity);
    canvas.drawPath(path, paint2);
  }

  void _drawLensFlare(Canvas canvas, Offset center, Size size) {
    final bool isSafety = theme == NabourAuraTheme.safety;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.72 + pulseT * math.pi * 0.04);
    final len = size.width * 1.15;
    final h = len * 0.09;
    final rect = Rect.fromCenter(center: Offset.zero, width: len, height: h);
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.linear(
        Offset(-len / 2, 0),
        Offset(len / 2, 0),
        [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.06 * intensity),
          (isSafety ? _orangeS : const Color(0xFF00E5FF)).withValues(alpha: 0.11 * intensity),
          (isSafety ? _redS : const Color(0xFFFF00D4)).withValues(alpha: 0.13 * intensity),
          (isSafety ? _glowS : const Color(0xFFFFE600)).withValues(alpha: 0.15 * intensity),
          Colors.transparent,
        ],
        const [0.0, 0.32, 0.44, 0.52, 0.6, 1.0],
      );
    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  void _drawOrbitalDust(Canvas canvas, Offset center, double scale) {
    final bool isSafety = theme == NabourAuraTheme.safety;
    const n = 32;
    final r0 = radius * 0.55 * scale;
    final rot = pulseT * math.pi * 2 * 0.4;
    for (var i = 0; i < n; i++) {
      final a = (i / n) * math.pi * 2 + rot;
      final jitter = 1.0 + 0.06 * math.sin(i * 1.7 + pulseT * 8);
      final rr = r0 * jitter;
      final x = center.dx + math.cos(a) * rr;
      final y = center.dy + math.sin(a) * rr;
      final Color dColorA = isSafety ? _glowS : _goldM;
      final Color dColorB = isSafety ? _redS : _pinkM;
      final dust = Color.lerp(dColorA, dColorB, (i % 5) / 5.0)!.withValues(
        alpha: (0.15 + 0.35 * intensity) *
            (0.5 + 0.5 * math.sin(i + pulseT * 6)),
      );
      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..color = dust
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.2);
      canvas.drawCircle(Offset(x, y), 1.4 + (i % 3) * 0.35, paint);
    }
  }

  void _drawShimmer(Canvas canvas, Offset center, Size size) {
    final angle = pulseT * math.pi * 2 + 1.1;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final w = radius * 2.8;
    final h = radius * 0.55;
    final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    final sweep = pulseT * 3.0;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.linear(
        Offset(-w / 2, 0),
        Offset(w / 2, 0),
        [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.12 * intensity),
          Colors.white.withValues(alpha: 0.18 * intensity),
          Colors.white.withValues(alpha: 0),
        ],
        [
          (sweep - 0.22).clamp(0.0, 1.0),
          sweep.clamp(0.0, 1.0),
          (sweep + 0.12).clamp(0.0, 1.0),
          (sweep + 0.28).clamp(0.0, 1.0),
        ],
      );
    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MasterpieceAuraPainter oldDelegate) =>
      oldDelegate.pulseT != pulseT ||
      oldDelegate.burstT != burstT ||
      oldDelegate.scale != scale ||
      oldDelegate.intensity != intensity;
}

class _AuraLayer {
  final Color color;
  final double rMul;
  final double opBase;
  _AuraLayer(this.color, this.rMul, this.opBase);
}

class FlowParticle {
  double x = 0, y = 0;
  double angle = 0;
  double dist = 0;
  double size = 0;
  double opacity = 0;
  double life = 1;
  final math.Random random;
  final double maxRadius;

  FlowParticle(this.random, this.maxRadius) {
    reset();
  }

  void reset() {
    angle = random.nextDouble() * 2 * math.pi;
    dist = random.nextDouble() * maxRadius * 0.12;
    size = random.nextDouble() * 2.8 + 1.2;
    life = 1.0;
    opacity = random.nextDouble() * 0.35 + 0.45;
  }

  void update() {
    final swirl = 0.028 + 0.015 * (1.0 - life);
    angle += swirl;
    dist += 0.55 + 0.85 * (1.0 - life);

    x = math.cos(angle) * dist;
    y = math.sin(angle) * dist;

    life -= 0.0085;
    opacity = life.clamp(0.0, 1.0);
    final r = math.sqrt(x * x + y * y);
    if (life <= 0 || r > maxRadius * 1.25) {
      reset();
    }
  }
}
