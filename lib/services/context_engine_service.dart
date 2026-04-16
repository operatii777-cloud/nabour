import 'dart:async';
import 'package:nabour_app/utils/logger.dart';

enum NabourContextState {
  stationary, // La cafea/acasă (Social Mode maxim)
  walking,    // În mișcare ușoară (Hybrid Mode)
  driving,    // În mașină (Hyper-Focus HUD Mode)
}

/// Motorul de inteligență ambientală care detectează starea utilizatorului.
///
/// **Nu creează propriul stream GPS** — evită dublarea subscripțiilor cu
/// MapScreen (care are deja `Geolocator.getPositionStream`).
///
/// Utilizare:
/// ```dart
/// ContextEngineService.instance.start();           // activează
/// ContextEngineService.instance.feedSpeed(pos.speed); // alimentează din callback GPS
/// ContextEngineService.instance.stop();             // oprește
/// ```
class ContextEngineService {
  static final ContextEngineService _instance = ContextEngineService._();
  factory ContextEngineService() => _instance;
  ContextEngineService._();

  static ContextEngineService get instance => _instance;

  StreamController<NabourContextState> _stateController =
      StreamController<NabourContextState>.broadcast();
  Stream<NabourContextState> get stateStream => _stateController.stream;

  StreamController<double> _speedController =
      StreamController<double>.broadcast();
  /// Viteza curentă în km/h, actualizată la fiecare update GPS.
  Stream<double> get speedStream => _speedController.stream;
  
  NabourContextState _currentState = NabourContextState.stationary;
  NabourContextState get currentState => _currentState;

  double _currentSpeedKph = 0;
  double get currentSpeedKph => _currentSpeedKph;

  bool _running = false;
  bool get isRunning => _running;

  /// Activează motorul. Nu creează stream GPS propriu.
  void start() {
    if (_running) return;
    _running = true;

    // Recreăm controllers dacă au fost închiși anterior.
    if (_stateController.isClosed) {
      _stateController = StreamController<NabourContextState>.broadcast();
    }
    if (_speedController.isClosed) {
      _speedController = StreamController<double>.broadcast();
    }

    Logger.info('ContextEngineService: Motion Engine activated (passive GPS mode).');
  }

  /// Alimentează motorul cu viteza din GPS (m/s).
  /// Apelat din callback-ul GPS deja existent al MapScreen.
  void feedSpeed(double speedMps) {
    if (!_running) return;
    // Android returnează -1.0 când GPS-ul nu are fix de viteză — ignorăm.
    if (speedMps < 0) return;
    _updateStateFromSpeed(speedMps);
  }

  /// Praguri cu histerezis — evită oscilații la graniță (GPS zgomotos).
  static const double _enterWalkKph = 4.0;
  static const double _exitWalkToStatKph = 2.5;
  static const double _enterDriveKph = 16.0;
  static const double _exitDriveToWalkKph = 12.0;
  static const double _jumpToDriveKph = 18.0;

  void _updateStateFromSpeed(double speedMps) {
    final speedKph = speedMps * 3.6;
    _currentSpeedKph = speedKph;

    final newState = _stateFromSpeedHysteresis(speedKph);

    if (newState != _currentState) {
      _currentState = newState;
      if (!_stateController.isClosed) {
        _stateController.add(_currentState);
      }
      Logger.debug(
        'ContextEngineService: Morphing to ${newState.name} (${speedKph.toStringAsFixed(1)} km/h)',
      );
    }

    // După schimbarea de stare — UI-ul poate folosi modul corect la același cadru.
    if (!_speedController.isClosed) {
      _speedController.add(speedKph);
    }
  }

  NabourContextState _stateFromSpeedHysteresis(double kph) {
    switch (_currentState) {
      case NabourContextState.stationary:
        if (kph >= _jumpToDriveKph) return NabourContextState.driving;
        if (kph >= _enterWalkKph) return NabourContextState.walking;
        return NabourContextState.stationary;
      case NabourContextState.walking:
        if (kph >= _enterDriveKph) return NabourContextState.driving;
        if (kph < _exitWalkToStatKph) return NabourContextState.stationary;
        return NabourContextState.walking;
      case NabourContextState.driving:
        if (kph < _exitDriveToWalkKph) {
          if (kph < _exitWalkToStatKph) return NabourContextState.stationary;
          return NabourContextState.walking;
        }
        return NabourContextState.driving;
    }
  }

  void stop() {
    _running = false;
    // Nu închidem controllers — permit re-subscribe la re-start.
  }
}
