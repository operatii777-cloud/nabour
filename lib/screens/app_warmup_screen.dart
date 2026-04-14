import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/screens/map_screen.dart';

class AppWarmupScreen extends StatefulWidget {
  final VoidCallback? onDismiss;
  final bool edgeToEdge;

  const AppWarmupScreen({super.key, this.onDismiss, this.edgeToEdge = false});

  @override
  State<AppWarmupScreen> createState() => _AppWarmupScreenState();
}

class _AppWarmupScreenState extends State<AppWarmupScreen> {
  void _navigateToMap() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Immersive Blur Background
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ),

          // 2. UI Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // Top Close Button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: IconButton(
                        onPressed: _navigateToMap,
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Header
                  Text(
                    'Nabour',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    l10n.warmupSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // Vertically Stacked Glass Cards
                  _GlassStackCard(
                    icon: Icons.groups_rounded,
                    iconBg: const Color(0xFF60A5FA),
                    title: l10n.warmupHeroNeighborsTitle,
                    subtitle: l10n.warmupExampleRidesCount('4'),
                    details: '${l10n.warmupExampleRide1}\n${l10n.warmupExampleRide2}',
                  ),
                  const SizedBox(height: 16),
                  _GlassStackCard(
                    icon: Icons.local_offer_rounded,
                    iconBg: const Color(0xFFF87171),
                    title: l10n.warmupHeroBusinessTitle,
                    subtitle: l10n.warmupExampleDealsCount('12'),
                    details: '${l10n.warmupExampleOffer1}\n${l10n.warmupExampleOffer2}',
                  ),
                  const SizedBox(height: 16),
                  _GlassStackCard(
                    icon: Icons.forum_rounded,
                    iconBg: const Color(0xFF34D399),
                    title: l10n.warmupHeroChatTitle,
                    subtitle: l10n.warmupExampleMessagesCount('8'),
                    details: '${l10n.warmupExampleChat1}\n${l10n.warmupExampleChat2}',
                  ),

                  const Spacer(flex: 3),

                  // "Go to map" Button
                  Container(
                    width: double.infinity,
                    height: 68,
                    margin: const EdgeInsets.only(bottom: 40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.8),
                          const Color(0xFF1E293B).withValues(alpha: 0.9),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigateToMap,
                        borderRadius: BorderRadius.circular(34),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.warmupCtaOpenMap,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassStackCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String details;

  const _GlassStackCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconBg, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                details,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


