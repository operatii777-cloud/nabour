import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:nabour_app/utils/logger.dart';

class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  // Thresholds in m/s²
  // 1 G = 9.81 m/s²
  // Frână / accelerare bruscă (> 0.5 G)
  final double aggressiveThreshold = 5.0; 
  // Impact major / Accident (> 3.5 G) - ajustabil pentru testing
  // Utilizatorul poate testa lovind ușor telefonul de podul palmei.
  final double crashThreshold = 35.0; 

  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;

  bool _isTracking = false;
  int _aggressiveEventsCount = 0;
  
  // Controller pentru a notifica UI-ul de crash
  final _crashController = StreamController<double>.broadcast();
  Stream<double> get onCrashDetected => _crashController.stream;

  // Controller pentru alerte smooth driving warnings
  final _aggressiveAlertController = StreamController<double>.broadcast();
  Stream<double> get onAggressiveEvent => _aggressiveAlertController.stream;

  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;
    _aggressiveEventsCount = 0;

    // userAccelerometer scoate gravitația, deci ne dă doar accelerația reală a mașinii/telefonului
    _accelSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      // Calculăm magnitudinea (intensitatea forței G curente pe toate axele)
      final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude > crashThreshold) {
        // Impact detectat!
        Logger.warning(
          'Crash-scale accelerație: ${magnitude.toStringAsFixed(1)} m/s²',
          tag: 'Telemetry',
        );
        _crashController.add(magnitude);
        
        // Pauză logică scurtă pentru a nu emite zeci de alerte în timpul unei rostogoliri/vibrații
        stopTracking(); 
      } else if (magnitude > aggressiveThreshold) {
        // Frână bruscă
        _aggressiveEventsCount++;
        Logger.debug(
          'Frână/accelerație bruscă: ${magnitude.toStringAsFixed(1)} m/s²',
          tag: 'Telemetry',
        );
        _aggressiveAlertController.add(magnitude);
      }
    });

    Logger.debug('Telemetry tracking started', tag: 'Telemetry');
  }

  void stopTracking() {
    if (!_isTracking) return;
    _accelSubscription?.cancel();
    _isTracking = false;
    Logger.debug('Telemetry tracking stopped', tag: 'Telemetry');
  }

  int get aggressiveEvents => _aggressiveEventsCount;

  bool isSmoothRider() {
    // Arbitrar: dacă ai sub 3 evenimente de agresivitate într-o cursă, ești "Smooth Rider"
    return _aggressiveEventsCount < 3;
  }

  void dispose() {
    stopTracking();
    _crashController.close();
    _aggressiveAlertController.close();
  }
}
