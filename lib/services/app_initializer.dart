import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/firebase_options.dart';
import 'package:nabour_app/config/environment.dart';
import 'package:nabour_app/services/firebase_service.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/push_notification_service.dart';
import 'package:nabour_app/services/offline_manager.dart';
import 'package:nabour_app/services/connectivity_service.dart';
import 'package:nabour_app/services/app_monitor.dart';
import 'package:nabour_app/utils/mapbox_config.dart';
import 'package:nabour_app/voice/nlp/ride_intent_processor.dart';
import 'package:nabour_app/services/startup_timer.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabour_app/services/contacts_service.dart';
import 'package:nabour_app/utils/nametag_helper.dart';
import 'package:nabour_app/services/trial_config_service.dart';
import 'package:nabour_app/services/presence_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/services/location_cache_service.dart';

enum AppStatus { initializing, ready, backendReady, error }

class AppInitializer extends ChangeNotifier {
  AppStatus _status = AppStatus.initializing;
  AppStatus get status => _status;

  bool _started = false;
  Completer<void>? _backendReadyCompleter;
  StreamSubscription<User?>? _authSubscription;
  Position? _prefetchedPosition;

  /// Poziția GPS obținută în timpul startup-ului (prefetch).
  Position? get prefetchedPosition => _prefetchedPosition;

  /// Se rezolvă când inițializările "heavy" din fundal s-au terminat.
  Future<void> get backendReadyFuture => _backendReadyCompleter?.future ?? Future.value();

  AppInitializer() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        Logger.info('User authenticated: ${user.uid}. Ensuring token wallet & phone sync...', tag: 'INITIALIZER');
        unawaited(TrialConfigService.instance.ensureTrialAnchorFromServer());
        unawaited(_ensureWalletAfterBackendReady(user.uid));
        unawaited(PresenceService().initialize(user.uid));
        unawaited(_syncUserProfile(user));
      }
    });
  }

  Future<void> _ensureWalletAfterBackendReady(String uid) async {
    try {
      // Asigurăm existența wallet-ului fără maintain în burst-ul de startup.
      await TokenService().ensureWalletExists(uid, maintainExisting: false);

      // Nu lovim callable-ul în burst-ul inițial de auth; așteptăm backendReady.
      final readyFuture = _backendReadyCompleter?.future;
      if (readyFuture != null) {
        await readyFuture;
      } else {
        var waited = 0;
        while (_status != AppStatus.backendReady && waited < 20) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          waited++;
        }
      }
      await Future<void>.delayed(const Duration(seconds: 12));
      final current = FirebaseAuth.instance.currentUser;
      if (current == null || current.uid != uid) return;
      await TokenService().maintainWalletOnStartupOnce();
    } catch (e) {
      Logger.warning('ensureWalletAfterBackendReady: $e', tag: 'INITIALIZER');
    }
  }

  /// Silently ensures the user profile in Firestore matches Auth data (phone, etc.)
  Future<void> _syncUserProfile(User user) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      
      final updates = <String, dynamic>{};
      
      final authPhoneNormalized = user.phoneNumber != null ? ContactsService.normalizePhoneNumber(user.phoneNumber!) : null;
      final storedPhone = data?['phoneNumber'] as String?;
      
      // Prioritate 1: Dacă Auth are număr (telefon verificat), acela este sursa de adevăr.
      if (authPhoneNormalized != null && authPhoneNormalized != storedPhone) {
        updates['phoneNumber'] = authPhoneNormalized;
        updates['phoneE164'] = authPhoneNormalized;
      }
      // Prioritate 2: Dacă Auth NU are număr (login cu email), dar există unul în Firestore, îl normalizăm.
      else if (storedPhone != null && storedPhone.isNotEmpty) {
        final normalizedStored = ContactsService.normalizePhoneNumber(storedPhone);
        if (normalizedStored != null && normalizedStored != storedPhone) {
          updates['phoneNumber'] = normalizedStored;
          updates['phoneE164'] = normalizedStored;
        }
      }

      // Profiluri vechi: completează `phoneE164` (același număr canonic) pentru lookup în agendă.
      final storedE164 = data?['phoneE164'] as String?;
      if (storedPhone != null &&
          storedPhone.isNotEmpty &&
          (storedE164 == null || storedE164.isEmpty) &&
          !updates.containsKey('phoneNumber')) {
        final fields = ContactsService.userPhoneFieldsForProfile(storedPhone);
        updates['phoneNumber'] = fields['phoneNumber']!;
        updates['phoneE164'] = fields['phoneE164']!;
      }
      // Ensure UID is present
      if (data == null || data['uid'] == null) {
        updates['uid'] = user.uid;
      }
      
      // Ensure base fields if doc doesn't exist
      if (data == null) {
        updates['displayName'] = user.displayName ?? 'Vecin';
        updates['email'] = user.email ?? '';
        updates['createdAt'] = FieldValue.serverTimestamp();
      }
      
      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(updates, SetOptions(merge: true));
        Logger.info('User profile synced: ${updates.keys.join(', ')}', tag: 'INITIALIZER');
        if (updates.containsKey('phoneNumber') ||
            updates.containsKey('phoneE164')) {
          unawaited(ContactsService.clearContactUidsCache());
        }
      }
      
      // Also ensure avatar exists
      await NabourNametag.ensureAvatar(user.uid);
    } catch (e) {
      Logger.error('Error in _syncUserProfile: $e', tag: 'INITIALIZER');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    _status = AppStatus.initializing;
    notifyListeners();

    try {
      Logger.info('🚀 Starting AppInitializer...', tag: 'INITIALIZER');
      StartupTimer.instance.mark('initializer.start');

      // Phase 0: GPS Prefetch (Absolute priority)
      // Începem să căutăm sateliții în prima secundă a aplicației.
      unawaited(_prefetchLocation());
      
      // Phase 1: Environment (fast)
      // dotenv este deja încărcat din main() — doar validăm, evităm I/O redundant.
      try {
        if (!dotenv.isInitialized) {
          await dotenv.load().timeout(const Duration(seconds: 5));
          StartupTimer.instance.mark('env.loaded');
        }
        Environment.validateTokens();
        StartupTimer.instance.mark('env.validated');
        if (kDebugMode) {
          Environment.printConfigurationStatus();
        }
      } catch (e) {
        Logger.error('ENV validation error (non-fatal): $e', error: e, tag: 'INITIALIZER');
      }

      // Phase 2: Firebase (CRITICAL)
      try {
        Logger.debug('Initializing Firebase...', tag: 'INITIALIZER');
        if (Firebase.apps.isEmpty) {
          // Timeout Firebase init to prevent total hang
          if (kIsWeb) {
            await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
                .timeout(const Duration(seconds: 15), onTimeout: () {
                  Logger.error('Firebase initialization timed out!', tag: 'INITIALIZER');
                  throw TimeoutException('Firebase init timeout');
                });
          } else {
            await Firebase.initializeApp()
                .timeout(const Duration(seconds: 15), onTimeout: () {
                  Logger.error('Firebase initialization timed out!', tag: 'INITIALIZER');
                  throw TimeoutException('Firebase init timeout');
                });
          }
        }
        StartupTimer.instance.mark('firebase.ready');
      } on FirebaseException catch (e) {
        if (e.code == 'duplicate-app') {
          Logger.warning('Firebase already initialized, continuing...', tag: 'INITIALIZER');
        } else {
          rethrow;
        }
      }

      // Phase 3: Firebase Services Core (fast)
      Logger.debug('Initializing FirebaseService...', tag: 'INITIALIZER');
      await FirebaseService().initialize()
          .then((_) => StartupTimer.instance.mark('firebase.service'))
          .catchError((e) => Logger.error('FirebaseService core init: $e', error: e, tag: 'INITIALIZER'));
      
      _backendReadyCompleter = Completer<void>();

      // Phase 4: Mark READY for UI (Navigation can start now)
      Logger.info('Core initialization complete. Marking status as READY.', tag: 'INITIALIZER');
      _status = AppStatus.ready;
      notifyListeners();

      // Phase 5: Background services (unawaited)
      unawaited(
        _initializeBackgroundServices().then((_) async {
          Logger.info('Background services complete. Marking status as backendReady.', tag: 'INITIALIZER');
          _status = AppStatus.backendReady;
          notifyListeners();
          _backendReadyCompleter?.complete();
        }).catchError((e) {
          Logger.error('Background services error: $e', error: e, tag: 'INITIALIZER');
          _status = AppStatus.backendReady;
          notifyListeners();
          _backendReadyCompleter?.complete();
        }),
      );

      StartupTimer.instance.mark('initializer.ready');
      StartupTimer.instance.printSummary();
      Logger.info('App initialization phase 1 successful.');
    } catch (e) {
      Logger.critical('CRITICAL: App initialization failed at core stage: $e', error: e, tag: 'INITIALIZER');
      _status = AppStatus.error;
      notifyListeners();
    }
  }

  /// Permite reîncercarea inițializării după un eșec.
  Future<void> retry() async {
    _started = false;
    _backendReadyCompleter = null;
    await initialize();
  }

  /// Initialize heavy services in background without blocking UI
  Future<void> _initializeBackgroundServices() async {
    try {
      Logger.debug('Starting background services initialization...', tag: 'INITIALIZER');

      // Faza 1 — servicii rapide, necesare imediat (notificări + offline cache + conectivitate)
      // Notă: PushNotifications este lăsat la urmă în faza 1 pentru că poate arăta dialoguri de permisiuni pe Android 13+
      await Future.wait([
        ConnectivityService().initialize()
            .then((_) => StartupTimer.instance.mark('connectivity.ready'))
            .catchError((e) => Logger.error('ConnectivityService init: $e', error: e, tag: 'INITIALIZER')),
        OfflineManager().initialize()
            .then((_) => StartupTimer.instance.mark('offline.ready'))
            .catchError((e) => Logger.error('OfflineManager init: $e', error: e, tag: 'INITIALIZER')),
        PushNotificationService().initialize()
            .then((_) => StartupTimer.instance.mark('push.ready'))
            .catchError((e) => Logger.error('PushNotificationService init: $e', error: e, tag: 'INITIALIZER')),
      ]);

      // Scurt yield pentru primul frame; pauze lungi măresc time-to-interactive fără beneficiu clar.
      await Future<void>.delayed(const Duration(milliseconds: 32));

      // Faza 2 — cleanup curse blocate: amânat după stabilizarea hărții (nu concurează cu primul paint)
      unawaited(
        Future<void>.delayed(const Duration(seconds: 12), () {
          FirestoreService().startStuckRideCleanupTimer();
        }),
      );
      if (!kIsWeb) {
        unawaited(
          MapboxConfig.initialize()
              .then((_) => StartupTimer.instance.mark('mapbox.ready'))
              .catchError((e) => Logger.error('MapboxConfig init: $e', error: e, tag: 'INITIALIZER')),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 24));

      // Faza 3 — servicii grele: eșalonate ca să nu concureze simultan cu harta / Geolocator /
      // voice (toate lovesc platform channels + CPU; pe MIUI poate duce la ANR).
      if (!kIsWeb) {
        unawaited(
          Future<void>.delayed(const Duration(seconds: 2), () {
            unawaited(
              AppMonitor()
                  .initialize()
                  .then((_) => StartupTimer.instance.mark('appmonitor.ready'))
                  .catchError((e) => Logger.error(
                        'AppMonitor init: $e',
                        error: e,
                        tag: 'INITIALIZER',
                      )),
            );
          }),
        );

        unawaited(
          Future<void>.delayed(const Duration(seconds: 5), () {
            unawaited(
              RideIntentProcessor.initializeIsolate()
                  .then((_) => StartupTimer.instance.mark('nlp.ready'))
                  .catchError((e) => Logger.error(
                        'NLP Isolate init: $e',
                        error: e,
                        tag: 'INITIALIZER',
                      )),
            );
          }),
        );
      }

      Logger.info('Background initialization complete.', tag: 'INITIALIZER');
    } catch (e) {
      Logger.error('Background services initialization error (non-fatal): $e', error: e, tag: 'INITIALIZER');
    }
  }

  /// 🛰️ GPS PREFETCH: Obține locația în fundal în timp ce restul serviciilor se încarcă.
  Future<void> _prefetchLocation() async {
    try {
      Logger.debug('🛰️ Starting GPS prefetch...', tag: 'INITIALIZER');
      
      // 1. Încercăm Last Known (instant)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _prefetchedPosition = lastKnown;
        LocationCacheService.instance.record(lastKnown);
        Logger.info('🛰️ GPS Prefetch: Last known position cached.', tag: 'INITIALIZER');
      }

      // 2. Cerem fix proaspăt (poate dura câteva secunde, rulează în paralel)
      try {
        final fresh = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _prefetchedPosition = fresh;
        LocationCacheService.instance.record(fresh);
        Logger.info('🛰️ GPS Prefetch: Fresh high-accuracy fix obtained.', tag: 'INITIALIZER');
      } catch (e) {
        Logger.warning('🛰️ GPS Prefetch high-accuracy failed: $e', tag: 'INITIALIZER');
      }
    } catch (e) {
      Logger.warning('🛰️ GPS Prefetch error: $e', tag: 'INITIALIZER');
    }
  }
}


