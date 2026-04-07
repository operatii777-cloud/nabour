import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Navigăm direct către ecranele finale pentru a evita intermediarul "profil"
import 'package:nabour_app/screens/auth_screen.dart';
import 'package:nabour_app/screens/map_with_warmup_screen.dart';
import 'package:nabour_app/screens/onboarding_wizard_screen.dart';
import 'package:provider/provider.dart';
import 'package:nabour_app/services/app_initializer.dart';
import 'package:nabour_app/widgets/romanian_flag.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nabour_app/services/startup_timer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/core/animations/app_transitions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _positionAnimation;
  bool _navigated = false;
  bool _minVisibleElapsed = false;

  AppInitializer? _appInit;

  // Timeout for fallback navigation
  Timer? _stuckTimer;
  /// Dacă animația nu ajunge la `completed` (vsync / lifecycle), tot permitem navigarea.
  Timer? _minVisibleFallbackTimer;
  bool _isStuck = false;

  void _onAppInitChanged() {
    if (!mounted || _navigated) return;
    final init = _appInit;
    if (init == null) return;
    final s = init.status;
    if (s != AppStatus.ready && s != AppStatus.backendReady) return;
    if (!_minVisibleElapsed) return;
    _goToNextScreen();
  }

  Future<void> _goToNextScreen() async {
    if (_navigated || !mounted) return;
    Logger.info('App is READY. Navigating away from Splash...', tag: 'SPLASH');
    _navigated = true;
    _stuckTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      Logger.debug('Current user: ${user?.uid ?? 'NULL'}', tag: 'SPLASH');

      if (user == null) {
        Logger.info('No user session. Navigating to Onboarding/Auth.', tag: 'SPLASH');

        bool hasSeenOnboarding = false;
        try {
          final prefs = await SharedPreferences.getInstance();
          hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
        } catch (e) {
          Logger.error('Error reading onboarding pref: $e', tag: 'SPLASH');
        }

        if (!mounted) return;

        if (!hasSeenOnboarding) {
          Navigator.of(context).pushReplacement(
            AppTransitions.slideUp(const OnboardingWizardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            AppTransitions.fade(const AuthScreen()),
          );
        }
      } else {
        Logger.info('User session detected. Navigating to MapWithWarmup.', tag: 'SPLASH');
        Navigator.of(context).pushReplacement(
          AppTransitions.fade(const MapWithWarmupScreen()),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // Animația vizuală: trebuie să țină suficient cât să se vadă complet "Nabour".
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Navigăm spre următorul ecran doar după ce animația a terminat,
    // ca să nu se taie textul ("Nab", "Nabo", etc).
    _controller.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        _minVisibleFallbackTimer?.cancel();
        setState(() {
          _minVisibleElapsed = true;
        });
        _onAppInitChanged();
      }
    });

    _minVisibleFallbackTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _navigated || _minVisibleElapsed) return;
      setState(() {
        _minVisibleElapsed = true;
      });
      _onAppInitChanged();
    });

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(-0.8, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.25, 1, 0.5, 1),
      ),
    );

    // Pornim procesul de inițializare și navigație
    _initializeApp();

    // Safety check: if stuck on splash for more than 12 seconds, allow bypass or show error
    _stuckTimer = Timer(const Duration(seconds: 12), () {
      if (!_navigated && mounted) {
        Logger.warning('Splash screen stuck for 12s. Showing bypass option.', tag: 'SPLASH');
        setState(() {
          _isStuck = true;
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    Logger.info('initializeApp start', tag: 'SPLASH');
    StartupTimer.instance.mark('splash.init');
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Attach listener BEFORE triggering initialize to avoid race condition
      _appInit = context.read<AppInitializer>();
      _appInit!.addListener(_onAppInitChanged);

      _appInit!.initialize();
      StartupTimer.instance.mark('initializer.triggered');

      // Check immediately in case it was already ready (e.g. hot restart)
      _onAppInitChanged();

      if (!kIsWeb) {
        try {
          FlutterNativeSplash.remove();
          StartupTimer.instance.mark('nativeSplash.removed');
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _appInit?.removeListener(_onAppInitChanged);
    _stuckTimer?.cancel();
    _minVisibleFallbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7C3AED),
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: SlideTransition(
                    position: _positionAnimation,
                    child: CustomPaint(
                      painter: LogoPainter(
                        progress: _progressAnimation.value,
                      ),
                    ),
                  ),
                ),
                // Live status watcher: when ready -> navigate
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Consumer<AppInitializer>(
                        builder: (context, init, _) {
                          // Navigarea la READY se face prin _onAppInitChanged (nu depinde de rebuild-uri AnimatedBuilder).

                          // UI STATE: ERROR
                          if (init.status == AppStatus.error) {
                            _stuckTimer?.cancel();
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.orange, size: 32),
                                const SizedBox(height: 12),
                                const Text(
                                  'A apărut o eroare la pornire.\nVerifică internetul și încearcă din nou.',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => init.retry(),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.white24,
                                  ),
                                  child: const Text('REÎNCEARCĂ'),
                                ),
                              ],
                            );
                          }

                          // UI STATE: STUCK (Bypass)
                          if (_isStuck && !_navigated) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Pornirea durează mai mult...',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    Logger.warning('User triggered manual bypass from Splash.', tag: 'SPLASH');
                                    setState(() {
                                      _navigated = true;
                                      _stuckTimer?.cancel();
                                    });
                                    Navigator.of(context).pushReplacement(
                                      AppTransitions.fade(const AuthScreen()),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white30),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('CONTINUĂ ORICUM'),
                                ),
                              ],
                            );
                          }

                          // DEFAULT: PROGRESS
                          return const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Fabricat în România',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontFamily: 'DancingScript',
                        ),
                      ),
                      SizedBox(width: 8),
                      RomanianFlag(height: 18),
                    ],
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

// Clasa LogoPainter rămâne neschimbată
class LogoPainter extends CustomPainter {
  final double progress;

  LogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Typewriter/reveal effect for 'Nabour'
    const String fullText = 'Nabour';
    const int totalChars = fullText.length;
    final int visibleChars = (progress.clamp(0.0, 1.0) * totalChars).ceil().clamp(0, totalChars);
    final String visibleText = fullText.substring(0, visibleChars);

    const TextStyle textStyle = TextStyle(
      fontFamily: 'DancingScript',
      fontWeight: FontWeight.w700,
      fontSize: 70,
      color: Colors.white,
    );

    final TextSpan textSpan = TextSpan(text: visibleText, style: textStyle);
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    // Center the text on the canvas
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final Offset drawOffset = Offset(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, drawOffset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LogoPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
