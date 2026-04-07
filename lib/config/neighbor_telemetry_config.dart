import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:nabour_app/utils/logger.dart';

/// Punte între Firebase Remote Config și throttling-ul telemetriei RTDB (harta socială
/// și, prin aceleași getter-e, [ActiveRideTelemetryRtdbService]).
///
/// Chei în consola Firebase (tip Number):
/// - [keyThrottleTimeSec] — secunde minime între două publicări acceptate.
/// - [keyThrottleDistanceM] — metri minimi față de ultima poziție publicată.
///
/// La eșecul fetch-ului sau rețea slabă la pornire, rămân [defaultThrottleTimeSec] /
/// [defaultThrottleDistanceM].
class NeighborTelemetryConfig {
  NeighborTelemetryConfig._();
  static final NeighborTelemetryConfig instance = NeighborTelemetryConfig._();

  static const String keyThrottleTimeSec = 'telemetry_throttle_time_sec';
  static const String keyThrottleDistanceM = 'telemetry_throttle_distance_m';

  static const int defaultThrottleTimeSec = 3;
  static const double defaultThrottleDistanceM = 7.0;

  static const int _minTimeSec = 1;
  static const int _maxTimeSec = 600;
  static const double _minDistanceM = 0.5;
  static const double _maxDistanceM = 500.0;

  Duration _publishMinInterval =
      const Duration(seconds: defaultThrottleTimeSec);
  double _publishMinDistanceM = defaultThrottleDistanceM;

  Duration get publishMinInterval => _publishMinInterval;
  double get publishMinDistanceM => _publishMinDistanceM;

  /// Apelat după [Firebase.initializeApp]. Nu aruncă — la eroare rămân fallback-urile locale.
  Future<void> refreshFromRemote() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.ensureInitialized();

      await rc.setDefaults(<String, dynamic>{
        keyThrottleTimeSec: defaultThrottleTimeSec,
        keyThrottleDistanceM: defaultThrottleDistanceM,
      });

      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 12),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 5)
              : const Duration(hours: 1),
        ),
      );

      _applyFromRemote(rc);

      try {
        await rc.fetchAndActivate();
      } catch (e, st) {
        Logger.warning(
          'NeighborTelemetryConfig: fetchAndActivate failed, using in-app defaults: $e\n$st',
          tag: 'RC',
        );
      }

      _applyFromRemote(rc);
    } catch (e, st) {
      Logger.warning(
        'NeighborTelemetryConfig: init failed, using hard defaults: $e\n$st',
        tag: 'RC',
      );
      _resetToHardDefaults();
    }
  }

  void _resetToHardDefaults() {
    _publishMinInterval = const Duration(seconds: defaultThrottleTimeSec);
    _publishMinDistanceM = defaultThrottleDistanceM;
  }

  void _applyFromRemote(FirebaseRemoteConfig rc) {
    var sec = rc.getInt(keyThrottleTimeSec);
    if (sec < _minTimeSec) {
      sec = defaultThrottleTimeSec;
    } else if (sec > _maxTimeSec) {
      sec = _maxTimeSec;
    }
    _publishMinInterval = Duration(seconds: sec);

    var d = rc.getDouble(keyThrottleDistanceM);
    if (d.isNaN || d < _minDistanceM) {
      d = defaultThrottleDistanceM;
    } else if (d > _maxDistanceM) {
      d = _maxDistanceM;
    }
    _publishMinDistanceM = d;
  }
}
