import 'package:flutter/material.dart';

class MapDrivingHud extends StatelessWidget {
  final double? speedKmh;
  final String? currentInstruction;
  final String? distanceLabel;
  final String? etaLabel;
  final VoidCallback? onStop;

  const MapDrivingHud({
    super.key,
    this.speedKmh,
    this.currentInstruction,
    this.distanceLabel,
    this.etaLabel,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final curSpeed = speedKmh ?? 0.0;

    // Neon color reacts to velocity — cyan at low speed, shifting toward magenta at high speed
    final speedRatio = (curSpeed / 120).clamp(0.0, 1.0);
    final neonColor = Color.lerp(Colors.cyanAccent, const Color(0xFFFF00FF), speedRatio)!;

    return IgnorePointer(
      child: Stack(
        key: const ValueKey('driving_hud'),
        children: [
          // Top Glassmorphic Vignette
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Driving Mode Indicator (Center Top)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: neonColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: neonColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.speed_rounded, color: neonColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'MOD CONDUS',
                      style: TextStyle(
                        color: neonColor.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Live Speedometer (Left Center)
          Positioned(
            left: 16,
            top: MediaQuery.sizeOf(context).height * 0.32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: curSpeed),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Text(
                      '${value.round()}',
                      style: TextStyle(
                        color: neonColor,
                        fontSize: 64,
                        fontWeight: FontWeight.w100,
                        fontFamily: 'monospace',
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: neonColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Text(
                  'KM/H',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          
          // Optional: Instructions/ETA Overlay if provided
          if (currentInstruction != null || distanceLabel != null)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  if (currentInstruction != null)
                    Text(
                      currentInstruction!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (distanceLabel != null)
                    Text(
                      distanceLabel!,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                ],
              ),
            ),

          // Bottom Ambient Neon Glow
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    neonColor.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapDriverSpeedChip extends StatelessWidget {
  final double speedKmh;
  final double? speedLimitKmh;

  const MapDriverSpeedChip({
    super.key,
    required this.speedKmh,
    this.speedLimitKmh,
  });

  @override
  Widget build(BuildContext context) {
    final speedInt = speedKmh.round();
    final isOverLimit = speedLimitKmh != null && speedKmh > speedLimitKmh!;
    
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOverLimit 
              ? Colors.red.withValues(alpha: 0.8) 
              : Colors.black.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed_rounded, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(
              '$speedInt km/h',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapWalkingGlow extends StatelessWidget {
  final bool active;

  const MapWalkingGlow({
    super.key,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    
    return IgnorePointer(
      child: Container(
        key: const ValueKey('walking_glow'),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.transparent,
              Colors.deepPurpleAccent.withValues(alpha: 0.08),
            ],
            stops: const [0.6, 1.0],
          ),
        ),
      ),
    );
  }
}
