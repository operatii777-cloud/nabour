import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/screens/auth_screen.dart';
import 'package:nabour_app/screens/map_with_warmup_screen.dart';
import 'package:nabour_app/theme/app_text_styles.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.handshake_rounded,
      title: 'Bun venit la Nabour!',
      description:
          'Aplicația care conectează vecini. Mergi undeva? Postează o cerere și un vecin disponibil te duce.',
      color: Color(0xFF7C3AED),
      gradient: [Color(0xFF7C3AED), Color(0xFF9F5FF1)],
    ),
    _OnboardingPage(
      icon: Icons.people_alt_rounded,
      title: 'Numai vecini & prieteni',
      description:
          'Nabour funcționează exclusiv cu persoane din agenda ta. Nu există străini.',
      color: Color(0xFF388E3C),
      gradient: [Color(0xFF388E3C), Color(0xFF66BB6A)],
    ),
    _OnboardingPage(
      icon: Icons.attach_money_rounded,
      title: 'Sustenabilitate & Ajutor',
      description:
          'Aplicația NU intermediază plăți între utilizatori. Susținem platforma prin abonament (10 RON persoane fizice / 15 RON firme).',
      color: Color(0xFF84CC16),
      gradient: [Color(0xFF5B8F0E), Color(0xFF84CC16)],
    ),
    _OnboardingPage(
      icon: Icons.chat_bubble_rounded,
      title: 'Chat de cartier',
      description:
          'Mesaje private și de grup cu persoanele din agenda ta. Coordonați-vă rapid, ca între prieteni.',
      color: Color(0xFFF57C00),
      gradient: [Color(0xFFF57C00), Color(0xFFFFB74D)],
    ),
    _OnboardingPage(
      icon: Icons.celebration_rounded,
      title: 'Gata de plecare?',
      description:
          'Creează un cont sau autentifică-te pentru a vedea vecinii disponibili din zona ta.',
      color: Color(0xFF7C3AED),
      gradient: [Color(0xFF7C3AED), Color(0xFFAB47BC)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim =
        Tween<double>(begin: 0, end: 1).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _markSeenAndGo(Widget destination) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() { HapticFeedback.lightImpact(); _markSeenAndGo(const AuthScreen()); }
  void _goToAuth() { HapticFeedback.mediumImpact(); _markSeenAndGo(const AuthScreen()); }
  void _goToHome() { HapticFeedback.lightImpact(); _markSeenAndGo(const MapWithWarmupScreen()); }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: page.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Progress text
                    Text(
                      '${_currentPage + 1} / ${_pages.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Skip button
                    TextButton(
                      onPressed: _skip,
                      child: const Text(
                        'Sari peste',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Page content ───────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    _fadeController.forward(from: 0);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),

              // ── Dots ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? Colors.white
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Buttons ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: isLast
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _goToAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: page.color,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Creează cont / Autentifică-te',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _goToHome,
                            child: const Text(
                              'Continuă ca oaspete',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: page.color,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Continuă',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 2),
              ),
              child: Icon(page.icon, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 48),
            Text(
              page.title,
              style: AppTextStyles.heading2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              page.description,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.gradient,
  });
}
