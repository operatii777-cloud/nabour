import 'package:flutter/material.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/screens/map_screen.dart';
import 'package:nabour_app/utils/layout_text_scale.dart';

class AppWarmupScreen extends StatefulWidget {
  /// Called when user dismisses the warmup screen.
  /// If null, falls back to Navigator.pop().
  final VoidCallback? onDismiss;

  /// Acoperă tot ecranul (ex. peste hartă în [MapWithWarmupScreen]).
  final bool edgeToEdge;

  const AppWarmupScreen({super.key, this.onDismiss, this.edgeToEdge = false});

  @override
  State<AppWarmupScreen> createState() => _AppWarmupScreenState();
}

class _AppWarmupScreenState extends State<AppWarmupScreen> {
  final PageController _heroPageController =
      PageController(viewportFraction: 0.88);
  int _heroPage = 0;

  double _dragOffset = 0;
  static const double _dismissThreshold = 120;

  @override
  void dispose() {
    _heroPageController.dispose();
    super.dispose();
  }

  void _navigateToMap() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    }
  }

  void _dismiss() => _navigateToMap();

  List<Widget> _heroSlides(ThemeData theme, AppLocalizations l10n) => [
        _HeroSlide(
          gradient: const [Color(0xFF3682F3), Color(0xFF1A4CB0)],
          icon: Icons.handshake_rounded,
          title: l10n.warmupHeroNeighborsTitle,
          subtitle: l10n.warmupHeroNeighborsSubtitle,
        ),
        _HeroSlide(
          gradient: const [Color(0xFFFF8F00), Color(0xFFFF6B35)],
          icon: Icons.storefront_rounded,
          title: l10n.warmupHeroBusinessTitle,
          subtitle: l10n.warmupHeroBusinessSubtitle,
        ),
        _HeroSlide(
          gradient: const [Color(0xFFE74C3C), Color(0xFFC0392B)],
          icon: Icons.shield_rounded,
          title: l10n.warmupHeroSafetyTitle,
          subtitle: l10n.warmupHeroSafetySubtitle,
        ),
        _HeroSlide(
          gradient: const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          icon: Icons.forum_rounded,
          title: l10n.warmupHeroChatTitle,
          subtitle: l10n.warmupHeroChatSubtitle,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final layoutScale = layoutScaleFactor(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final heroSlides = _heroSlides(theme, l10n);
    final edge = widget.edgeToEdge;

    final sheet = GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 0) {
          setState(() {
            _dragOffset += details.delta.dy;
          });
        }
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset > _dismissThreshold ||
            (details.primaryVelocity ?? 0) > 600) {
          _dismiss();
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      child: AnimatedSlide(
        offset: Offset(0, _dragOffset / screenHeight),
        duration: _dragOffset == 0
            ? const Duration(milliseconds: 300)
            : Duration.zero,
        curve: Curves.easeOut,
        child: Material(
          color: theme.colorScheme.surface.withValues(alpha: edge ? 1.0 : 0.98),
          borderRadius: edge
              ? BorderRadius.zero
              : const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (edge)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              _TopBar(onClose: _dismiss, closeTooltip: l10n.warmupCloseTooltip),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        l10n.warmupHeadline,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 198,
                      child: PageView(
                        controller: _heroPageController,
                        onPageChanged: (i) => setState(() => _heroPage = i),
                        children: heroSlides,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DotsIndicator(
                      count: heroSlides.length,
                      current: _heroPage,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        l10n.warmupShortcutsTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SuggestionCard(
                              icon: Icons.directions_car_rounded,
                              title: l10n.warmupShortcutRideTitle,
                              subtitle: l10n.warmupShortcutRideSubtitle,
                              accent: theme.colorScheme.primary,
                              onTap: _navigateToMap,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SuggestionCard(
                              icon: Icons.map_rounded,
                              title: l10n.warmupShortcutMapTitle,
                              subtitle: l10n.warmupShortcutMapSubtitle,
                              accent: const Color(0xFF0D9488),
                              onTap: _navigateToMap,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SuggestionCard(
                              icon: Icons.chat_bubble_rounded,
                              title: l10n.warmupShortcutChatTitle,
                              subtitle: l10n.warmupShortcutChatSubtitle,
                              accent: const Color(0xFF7C3AED),
                              onTap: _navigateToMap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ScheduleLaterCard(
                        theme: theme,
                        title: l10n.warmupScheduleTitle,
                        subtitle: l10n.warmupScheduleSubtitle,
                        onTap: _navigateToMap,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        l10n.warmupWhyTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 260 * layoutScale,
                      child: ListView(
                        clipBehavior: Clip.none,
                        scrollDirection: Axis.horizontal,
                        padding:
                            scaledFromLTRB(16, 4, 16, 24, layoutScale),
                        children: [
                          _FeatureCard(
                            layoutScale: layoutScale,
                            color: const Color(0xFF7C3AED),
                            icon: Icons.hub_rounded,
                            title: l10n.warmupFeatureCommunityTitle,
                            subtitle: l10n.warmupFeatureCommunitySubtitle,
                          ),
                          _FeatureCard(
                            layoutScale: layoutScale,
                            color: const Color(0xFF0D9488),
                            icon: Icons.verified_user_rounded,
                            title: l10n.warmupFeatureContactsTitle,
                            subtitle: l10n.warmupFeatureContactsSubtitle,
                          ),
                          _FeatureCard(
                            layoutScale: layoutScale,
                            color: const Color(0xFF2563EB),
                            icon: Icons.my_location_rounded,
                            title: l10n.warmupFeatureLiveTitle,
                            subtitle: l10n.warmupFeatureLiveSubtitle,
                          ),
                          _FeatureCard(
                            layoutScale: layoutScale,
                            color: const Color(0xFF475569),
                            icon: Icons.policy_rounded,
                            title: l10n.warmupFeatureSecureTitle,
                            subtitle: l10n.warmupFeatureSecureSubtitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _navigateToMap,
                        icon: const Icon(Icons.explore_rounded, size: 22),
                        label: Text(
                          l10n.warmupCtaOpenMap,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.warmupSwipeDownHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (edge) {
      return SafeArea(
        top: true,
        bottom: true,
        child: sheet,
      );
    }
    return sheet;
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final String closeTooltip;

  const _TopBar({required this.onClose, required this.closeTooltip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Nabour',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontFamily: 'DancingScript',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            tooltip: closeTooltip,
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeroSlide({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;
  final Color color;

  const _DotsIndicator({
    required this.count,
    required this.current,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: accent, size: 24),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleLaterCard extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ScheduleLaterCard({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withValues(alpha: 0.18)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.event_available_rounded, color: primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final double layoutScale;
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.layoutScale,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final s = layoutScale;
    return Container(
      width: 186 * s,
      margin: EdgeInsets.only(right: 12 * s, bottom: 10 * s),
      padding: scaledFromLTRB(16, 14, 16, 28, s),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20 * s),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10 * s,
            offset: Offset(0, 4 * s),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8 * s),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12 * s),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: MediaQuery.textScalerOf(context).scale(26),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8 * s),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
