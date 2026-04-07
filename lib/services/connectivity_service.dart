import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:nabour_app/utils/logger.dart';

/// Singleton care monitorizează starea conexiunii la internet.
/// Se inițializează o singură dată și notifică UI-ul prin ChangeNotifier.
///
/// Utilizare:
///   ConnectivityService().initialize();   // o dată, în AppInitializer
///   ConnectivityService().isOnline;       // getter sincron
///   ConnectivityService().onStatusChange; // stream async
///   ConnectivityService.withRetry(() => myCall(), maxAttempts: 3);
class ConnectivityService with ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  /// Stream cu starea curentă: `true` = online, `false` = offline.
  Stream<bool> get onStatusChange => _statusController.stream;

  /// Inițializează monitorizarea conectivității.
  /// Apelat o singură dată din AppInitializer.
  Future<void> initialize() async {
    // Verifică starea curentă imediat
    final results = await _connectivity.checkConnectivity();
    _applyResults(results);

    // Ascultă schimbările ulterioare
    _subscription = _connectivity.onConnectivityChanged.listen(
      _applyResults,
      onError: (e) => Logger.warning('ConnectivityService stream error: $e'),
    );
  }

  void _applyResults(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    if (wasOnline != _isOnline) {
      Logger.info(
        _isOnline ? 'Conexiune restabilita.' : 'Conexiune pierduta.',
        tag: 'CONNECTIVITY',
      );
      _statusController.add(_isOnline);
      notifyListeners();
    }
  }

  /// Forțează o reverificare imediată a conectivității.
  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    _applyResults(results);
    return _isOnline;
  }

  /// Execută [operation] cu retry exponențial dacă aruncă excepție.
  ///
  /// - [maxAttempts]: numărul maxim de încercări (default 3)
  /// - [initialDelay]: delay după prima eroare (default 1s, se dublează la fiecare retry)
  /// - [shouldRetry]: opțional, determină dacă eroarea este retryable
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool Function(Object error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        final retryable = shouldRetry == null || shouldRetry(e);
        if (attempt >= maxAttempts || !retryable) {
          Logger.error(
            'ConnectivityService.withRetry: epuizat după $attempt încercări: $e',
            error: e,
          );
          rethrow;
        }
        Logger.warning(
          'ConnectivityService.withRetry: încercarea $attempt eșuată, retry în ${delay.inMilliseconds}ms',
        );
        await Future.delayed(delay);
        delay = delay * 2;
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    super.dispose();
  }
}
