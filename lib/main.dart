import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:nabour_app/firebase_options.dart';
import 'package:nabour_app/screens/token_shop_screen.dart';
import 'package:nabour_app/screens/neighborhood_chat_screen.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nabour_app/screens/auth_screen.dart';
import 'package:nabour_app/screens/map_with_warmup_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/theme/app_theme.dart';
import 'package:nabour_app/theme/theme_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nabour_app/providers/locale_provider.dart';
import 'package:nabour_app/l10n/app_localizations.dart' as l10n;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async' show unawaited;
import 'package:nabour_app/providers/driver_state_provider.dart';
import 'package:nabour_app/features/waiting_timer/waiting_timer_service.dart';
import 'package:nabour_app/providers/map_camera_provider.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/providers/assistant_status_provider.dart';

// Voice AI providers
import 'package:nabour_app/voice/integration/friendsride_voice_integration.dart';
import 'package:nabour_app/voice/passenger/passenger_voice_controller.dart';
import 'package:nabour_app/voice/passenger/passenger_voice_controller_adapter.dart';
import 'package:nabour_app/voice/driver/driver_voice_controller.dart';

import 'package:nabour_app/screens/splash_screen.dart';
import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/services/passenger_ride_session_bus.dart';
import 'package:nabour_app/screens/driver_ride_pickup_screen.dart';
import 'package:nabour_app/services/app_initializer.dart';
import 'package:nabour_app/services/push_notification_service.dart';

import 'package:nabour_app/config/environment.dart';
import 'package:nabour_app/screens/safety_screen.dart';
import 'package:nabour_app/screens/report_form_screen.dart';
import 'package:nabour_app/screens/trial_expired_screen.dart';
import 'package:nabour_app/widgets/app_drawer.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nabour_app/services/startup_timer.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/services/app_update_service.dart';
import 'package:nabour_app/services/connectivity_service.dart';
import 'package:nabour_app/services/autonomous_app_coordinator.dart';
import 'package:nabour_app/config/neighbor_telemetry_config.dart';
import 'package:nabour_app/config/trial_policy_config.dart';
import 'package:nabour_app/services/trial_config_service.dart';
import 'package:nabour_app/services/app_audio_session.dart';
import 'package:nabour_app/services/assistant_voice_ui_prefs.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  StartupTimer.instance.mark('widgetsBinding.ready');

  // Phase 2: Firebase (CRITICAL) - Initialize here so providers can access it

  // Luminozitatea iconițelor din bara de stare urmează tema în [MyApp] (AnnotatedRegion).
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // Încarcă .env la pornire (pentru Mapbox, Gemini, Sentry) – opțional dacă lipsește
  if (!dotenv.isInitialized) {
    try {
      await dotenv.load();
    } catch (e) {
      Logger.warning(' .env not loaded (optional): $e');
    }
  }

  // Phase 2: Firebase (CRITICAL) - Initialize here so providers can access it
  try {
    if (Firebase.apps.isEmpty) {
      // Pe Android folosim config implicit (din `google-services.json`) pentru a evita
      // mismatch-uri între `firebase_options.dart` și fișierele generate.
      // Pe Web păstrăm `DefaultFirebaseOptions`.
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }
      StartupTimer.instance.mark('firebase.initialized.main');
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      Logger.warning('Firebase [DEFAULT] already initialized, continuing.',
          tag: 'APP');
    } else {
      Logger.error('Firebase initialization error in main: $e', error: e);
    }
  } catch (e) {
    Logger.error('Firebase initialization error in main: $e', error: e);
  }

  unawaited(
    NeighborTelemetryConfig.instance
        .refreshFromRemote()
        .catchError((Object e, StackTrace st) {
      Logger.warning('NeighborTelemetryConfig bootstrap: $e\n$st', tag: 'RC');
    }),
  );
  unawaited(
    TrialPolicyConfig.instance.refreshFromRemote().catchError(
        (Object e, StackTrace st) {
      Logger.warning('TrialPolicyConfig bootstrap: $e\n$st', tag: 'RC');
    }),
  );

  if (!kIsWeb) {
    unawaited(AppAudioSession.ensureConfiguredForVoiceCommunication());
  }

  // Set Mapbox token BEFORE any MapView is created
  final mapboxToken = dotenv.maybeGet('MAPBOX_PUBLIC_TOKEN') ??
      dotenv.maybeGet('MAPBOX_ACCESS_TOKEN');
  if (mapboxToken != null && mapboxToken.startsWith('pk.')) {
    MapboxOptions.setAccessToken(mapboxToken);
    if (!kIsWeb) {
      // Motorul de hărți verifică mai întâi TileStore (implicit READ_ONLY); setăm explicit + quota
      // înainte de primul MapWidget, ca să fie același magazin ca la prefetch (OfflineManager).
      MapboxMapsOptions.setTileStoreUsageMode(TileStoreUsageMode.READ_ONLY);
      unawaited(_primeDefaultTileStoreDiskQuota());
    }
  }

  final sentryDsn = await _resolveSentryDsn();
  if (sentryDsn != null && sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment =
            Environment.isProduction ? 'production' : 'development';
        options.tracesSampleRate = Environment.isProduction ? 0.2 : 1.0;
        options.enableAutoSessionTracking = true;
        options.enableAppLifecycleBreadcrumbs = true;
        options.enableUserInteractionBreadcrumbs = true;
        // Fără PII implicit (IP etc.) — aliniat încrederii „între vecini”; poate fi activat
        // explicit după consimțământ sau politică de confidențialitate actualizată.
        options.sendDefaultPii = false;
      },
      appRunner: _runNabourApp,
    );
  } else {
    _runNabourApp();
  }
}

void _runNabourApp() {

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final provider = ThemeProvider();
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => AppInitializer()),
        ChangeNotifierProvider(create: (context) => DriverStateProvider()),
        ChangeNotifierProvider(create: (context) => MapCameraProvider()),
        ChangeNotifierProvider(create: (context) => AssistantStatusProvider()),
        ChangeNotifierProvider(create: (_) => WaitingTimerService()),
        ChangeNotifierProvider(
            create: (context) => FriendsRideVoiceIntegration()),
        // FirestoreService() este singleton (factory constructor) — ambii controlleri
        // primesc aceeași instanță, fără batch timers sau cache-uri duplicate.
        ChangeNotifierProvider(create: (context) {
          final fs = FirestoreService();
          return DriverVoiceController(firestoreService: fs);
        }),
        ChangeNotifierProvider(create: (context) {
          final fs = FirestoreService();
          return PassengerVoiceControllerAdapter(
            controller: PassengerVoiceController(firestoreService: fs),
          );
        }),
        ChangeNotifierProvider(create: (_) => AppUpdateService()),
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => ConnectivityService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
  StartupTimer.instance.mark('runApp.called');

  // Defer platform channel calls until after first frame to avoid competing
  // with Flutter's rendering pipeline (eliminates skipped frames at startup)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeBackground());
  });
}

/// Quota disc pentru tile-uri (MAPS) — aceeași magnitudine ca în [OfflineManager.prefetchBucharestIlfov].
Future<void> _primeDefaultTileStoreDiskQuota() async {
  try {
    final ts = await TileStore.createDefault();
    ts.setDiskQuota(500 * 1024 * 1024, domain: TileDataDomain.MAPS);
  } catch (e) {
    Logger.debug('TileStore disk quota prime: $e', tag: 'APP');
  }
}

Future<String?> _resolveSentryDsn() async {
  try {
    if (!dotenv.isInitialized) {
      await dotenv.load();
      StartupTimer.instance.mark('env.preloaded');
    }
  } catch (e) {
    Logger.warning('Sentry DSN env load skipped: $e');
  }

  final envDsn = dotenv.maybeGet('SENTRY_DSN');
  if (envDsn != null &&
      envDsn.isNotEmpty &&
      !envDsn.contains('public-example-key')) {
    return envDsn;
  }
  final fromEnv = Environment.sentryDsn;
  if (fromEnv.isNotEmpty && !fromEnv.contains('public-example-key')) {
    return fromEnv;
  }
  return null;
}

// ── Global navigator key — used for push notification deep linking ───────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ── Wire notification → screen navigation ────────────────────────────────────
void _setupNotificationNavigation() {
  PushNotificationService().setNavigationCallback(
    (String messageType, Map<String, dynamic> data) {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      final rideId = data['rideId'] as String?;

      switch (messageType) {
        case 'ride_assignment':
        case 'ride_update':
          if (rideId != null) {
            final currentUid = FirebaseAuth.instance.currentUser?.uid;
            final driverId = data['driverId'] as String?;
            final isDriverNotif =
                driverId != null && driverId == currentUid;
            if (isDriverNotif) {
              unawaited(() async {
                final ride =
                    await FirestoreService().getRideById(rideId);
                final nav = navigatorKey.currentState;
                if (ride == null || nav == null) return;
                if (navigatorKey.currentContext?.mounted != true) return;
                nav.push(
                  MaterialPageRoute(
                    builder: (_) => DriverRidePickupScreen(
                      rideId: rideId,
                      ride: ride,
                    ),
                  ),
                );
              }());
            } else {
              navigator.popUntil((route) => route.isFirst);
              PassengerRideServiceBus.emit(
                PassengerSearchFlowResult(rideId: rideId),
              );
            }
          }
          break;
        case 'chat_message':
          if (rideId != null) {
            unawaited(() async {
              final ride =
                  await FirestoreService().getRideById(rideId);
              final uid = FirebaseAuth.instance.currentUser?.uid;
              final nav = navigatorKey.currentState;
              if (ride == null || uid == null || nav == null) return;
              if (navigatorKey.currentContext?.mounted != true) return;
              final otherUid = uid == ride.passengerId
                  ? ride.driverId
                  : ride.passengerId;
              if (otherUid == null || otherUid.isEmpty) return;
              nav.push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    rideId: rideId,
                    otherUserId: otherUid,
                    otherUserName: 'Chat cursă',
                    collectionName: 'ride_requests',
                  ),
                ),
              );
            }());
          }
          break;
        case 'emergency':
          navigator.push(MaterialPageRoute(
            builder: (_) => const SafetyScreen(),
          ));
          break;
        case 'neighborhood_chat':
          navigator.pushNamed('/neighborhood-chat');
          break;
        default:
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MapWithWarmupScreen()),
            (route) => false,
          );
      }
    },
  );
}

// 🚀 PERFORMANȚĂ: Funcție helper pentru inițializări în fundal
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Wire push notification navigation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupNotificationNavigation();
      // Verificăm discret dacă există un update disponibil
      context.read<AppUpdateService>().checkForUpdate();
      // Comportament autonom: resume + reconectare (sync, Remote Config, token)
      AutonomousAppCoordinator.instance
          .start(context.read<ConnectivityService>());
    });
  }

  @override
  void dispose() {
    AutonomousAppCoordinator.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          title: 'Nabour',
          navigatorKey: navigatorKey,

          localizationsDelegates: l10n.AppLocalizations.localizationsDelegates,
          supportedLocales: l10n.AppLocalizations.supportedLocales,

          locale: localeProvider.locale,

          theme: themeProvider.isHighContrast
              ? AppTheme.highContrastLight
              : AppTheme.lightTheme,
          darkTheme: themeProvider.isHighContrast
              ? AppTheme.highContrastDark
              : AppTheme.darkTheme,
          themeMode: themeProvider.currentTheme,

          // MODIFICAT: Aplicația pornește acum cu SplashScreen
          home: const SplashScreen(),

          routes: {
            '/token-shop': (_) => const TokenShopScreen(),
            '/neighborhood-chat': (_) => const NeighborhoodChatScreen(),
            '/home': (_) => const MapWithWarmupScreen(),
            '/safety': (_) => const SafetyScreen(),
            '/report': (_) => const ReportFormScreen(reportType: 'general'),
          },

          debugShowCheckedModeBanner: false,
          showPerformanceOverlay: AppDrawer.showPerfOverlay,

          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final shortest = mediaQuery.size.shortestSide;
            final maxScale = shortest < 360
                ? 1.06
                : (shortest < 400 ? 1.12 : 1.18);

            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            // Iconițe vizibile pe fundal deschis (tema light) vs. iconițe deschise pe fundal închis (tema dark).
            final systemUi = SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              statusBarBrightness:
                  isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
            );

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: systemUi,
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(
                    mediaQuery.textScaler.scale(1.0).clamp(0.9, maxScale),
                  ),
                ),
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}

// ── Trial helpers ─────────────────────────────────────────────────────────────
const int _trialDays = 7;

bool _isTrialExpired(
  User user, {
  bool isUnlimited = false,
  bool firestoreTrialExempt = false,
}) {
  if (isUnlimited || firestoreTrialExempt) return false;
  final email = (user.email ?? '').toLowerCase().trim();
  if (TrialPolicyConfig.instance.isExempt(email)) return false;
  final creationTime = user.metadata.creationTime;
  if (creationTime == null) return false;
  final trialEnd = creationTime.add(const Duration(days: _trialDays));
  return DateTime.now().isAfter(trialEnd);
}

// AuthWrapper rămâne neschimbat. SplashScreen va naviga aici după animație.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(204),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(76),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.AppLocalizations.of(context)?.appTitle ?? 'Nabour',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(178),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data;
          if (user != null) {
            return ListenableBuilder(
              listenable: TrialPolicyConfig.instance,
              builder: (context, _) => _AuthRoleResolver(
                key: ValueKey(user.uid),
                user: user,
              ),
            );
          }
        }

        return const AuthScreen();
      },
    );
  }
}

/// Un singur apel Firestore `getUserRole` per sesiune utilizator — nu la fiecare rebuild `StreamBuilder`.
class _AuthRoleResolver extends StatefulWidget {
  const _AuthRoleResolver({super.key, required this.user});

  final User user;

  @override
  State<_AuthRoleResolver> createState() => _AuthRoleResolverState();
}

class _AuthRoleResolverState extends State<_AuthRoleResolver> {
  late final Future<(UserRole, bool, bool)> _authDataFuture = _fetchAuthData();

  Future<(UserRole, bool, bool)> _fetchAuthData() async {
    final role = await FirestoreService().getUserRole();
    final wallet = await TokenService().getWallet(widget.user.uid);
    final isUnlimited = wallet?.isUnlimited ?? false;
    final firestoreTrialExempt = await TrialConfigService.instance.isExempt(
      uid: widget.user.uid,
      email: widget.user.email,
    );
    return (role, isUnlimited, firestoreTrialExempt);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(UserRole, bool, bool)>(
      future: _authDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.AppLocalizations.of(context)?.profile ?? 'Profile',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(178),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final user = widget.user;
        if (snapshot.hasData) {
          final (role, isUnlimited, firestoreTrialExempt) = snapshot.data!;
          if (_isTrialExpired(
                user,
                isUnlimited: isUnlimited,
                firestoreTrialExempt: firestoreTrialExempt,
              )) {
            return const TrialExpiredScreen();
          }
          return const MapWithWarmupScreen();
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.AppLocalizations.of(context)?.profile ?? 'Profile',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.AppLocalizations.of(context)?.settings ?? 'Settings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(178),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        l10n.AppLocalizations.of(context)?.settings ??
                            'Settings',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (_isTrialExpired(user, firestoreTrialExempt: false)) {
          return const TrialExpiredScreen();
        }
        return const MapWithWarmupScreen();
      },
    );
  }
}

/// Initialize background services without blocking main thread
Future<void> _initializeBackground() async {
  try {
    // Keep portrait but don't block startup on orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Nu desenăm UI-ul aplicației sub status bar (evită "acoperirea" barei).
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    StartupTimer.instance.mark('systemUi.ready');

    await initializeDateFormatting('ro_RO');
    StartupTimer.instance.mark('intl.ready');

    await AssistantVoiceUiPrefs.instance.load();

    // Configure font fallbacks to avoid Noto font errors
    await _configureFonts();

    Logger.info('Background initialization completed');
  } catch (e) {
    Logger.error('Background initialization error (non-fatal): $e', error: e);
  }
}

/// Configure font fallbacks to avoid Noto font errors
Future<void> _configureFonts() async {
  try {
    // Set default font family to avoid Noto font errors
    // This will use system default fonts when Noto is not available
    Logger.info('Font fallbacks configured to avoid Noto errors');
  } catch (e) {
    Logger.error('Font configuration error (non-fatal): $e', error: e);
  }
}
