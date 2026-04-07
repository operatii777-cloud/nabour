import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:nabour_app/config/neighbor_telemetry_config.dart';
import 'package:nabour_app/config/trial_policy_config.dart';
import 'package:nabour_app/services/connectivity_service.dart';
import 'package:nabour_app/services/offline_manager.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Orchestrare minimă „autonomă”: la revenirea din background și la rețea din nou,
/// verifică conectivitatea, actualizează Remote Config pentru telemetrie, încearcă
/// sync cozi offline și menține portofelul token fără acțiune manuală.
class AutonomousAppCoordinator with WidgetsBindingObserver {
  AutonomousAppCoordinator._();
  static final AutonomousAppCoordinator instance = AutonomousAppCoordinator._();

  StreamSubscription<bool>? _connectivitySub;
  Timer? _resumeDebounce;
  bool _started = false;

  void start(ConnectivityService connectivity) {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _connectivitySub = connectivity.onStatusChange.listen((online) {
      if (online) {
        unawaited(_onNetworkAvailable());
      }
    });
    Logger.info('AutonomousAppCoordinator pornit', tag: 'AUTONOMY');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _resumeDebounce?.cancel();
    _resumeDebounce = null;
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeDebounce?.cancel();
      _resumeDebounce = Timer(const Duration(milliseconds: 450), () {
        unawaited(_onAppResumed());
      });
    }
  }

  Future<void> _onAppResumed() async {
    try {
      await ConnectivityService().checkNow();
    } catch (e) {
      Logger.warning('Autonomy resume: checkNow $e', tag: 'AUTONOMY');
    }
    unawaited(
      NeighborTelemetryConfig.instance
          .refreshFromRemote()
          .catchError((Object e, StackTrace st) {
        Logger.warning('Autonomy resume: Remote Config $e', tag: 'AUTONOMY');
      }),
    );
    unawaited(
      TrialPolicyConfig.instance.refreshFromRemote().catchError((Object e) {
        Logger.warning('Autonomy resume: trial policy $e', tag: 'AUTONOMY');
      }),
    );
    await _syncOfflineIfNeeded();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      unawaited(
        TokenService().ensureWalletExists(user.uid).catchError((Object e) {
          Logger.warning('Autonomy resume: token wallet $e', tag: 'AUTONOMY');
        }),
      );
    }
  }

  Future<void> _onNetworkAvailable() async {
    unawaited(
      NeighborTelemetryConfig.instance
          .refreshFromRemote()
          .catchError((Object e, StackTrace st) {
        Logger.warning('Autonomy online: Remote Config $e', tag: 'AUTONOMY');
      }),
    );
    await _syncOfflineIfNeeded();
  }

  Future<void> _syncOfflineIfNeeded() async {
    final om = OfflineManager();
    if (!om.isInitialized || !om.isOnline || om.pendingOperationsCount == 0) {
      return;
    }
    try {
      await om.forceSync();
      Logger.debug('Autonomy: coadă offline procesată', tag: 'AUTONOMY');
    } catch (e) {
      Logger.warning('Autonomy: forceSync ignorat — $e', tag: 'AUTONOMY');
    }
  }
}
