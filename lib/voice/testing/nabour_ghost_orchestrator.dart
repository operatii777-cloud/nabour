import 'dart:async';
import 'package:flutter/foundation.dart';
import '../passenger/passenger_voice_controller.dart';
import '../core/voice_ui_automation_registry.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🎭 Rolurile posibile pentru testarea automată
enum GhostRole {
  none,
  passengerOnly, // Rezervă prin voce, așteaptă șofer real
  driverOnly,    // Așteaptă cerere și acceptă automat
  singleDevice   // Face totul pe un singur dispozitiv (comută roluri)
}

/// 🎭 Etapele detaliate ale testului
enum GhostTestStep {
  idle,
  passengerInitialRequest,
  passengerConfirmingAddress,
  passengerSearchingDriver,
  switchingToDriver,
  driverAcceptingRide,
  switchingToPassenger,
  passengerConfirmingRide,
  finished
}

/// 🧬 NabourGhostOrchestrator: Orchestrează testele pe unul sau mai multe dispozitive.
class NabourGhostOrchestrator extends ChangeNotifier {
  static final NabourGhostOrchestrator _instance = NabourGhostOrchestrator._internal();
  factory NabourGhostOrchestrator() => _instance;
  NabourGhostOrchestrator._internal();

  GhostRole _activeRole = GhostRole.none;
  GhostRole get activeRole => _activeRole;

  GhostTestStep _currentStep = GhostTestStep.idle;
  GhostTestStep get currentStep => _currentStep;

  bool get isActive => _activeRole != GhostRole.none;

  String _lastRobotMessage = '';
  String get lastRobotMessage => _lastRobotMessage;
  
  PassengerVoiceController? _passengerController;
  
  void initialize(PassengerVoiceController controller) {
    _passengerController = controller;
    _passengerController?.voiceOrchestrator.naturalTts.onCompletion = onTtsFinished;
    Logger.info('Ghost Orchestrator initialized with role: $_activeRole', tag: 'GHOST_ENGINE');
  }

  /// 🎬 Pornește simularea cu un rol specific
  Future<void> startSimulation(GhostRole role) async {
    if (isActive) stopTest();
    
    _activeRole = role;
    _currentStep = GhostTestStep.idle;
    notifyListeners();

    Logger.info('🚀 --- STARTING GHOST SIMULATION (Role: $role) ---', tag: 'GHOST_ENGINE');

    if (role == GhostRole.passengerOnly || role == GhostRole.singleDevice) {
      _currentStep = GhostTestStep.passengerInitialRequest;
      notifyListeners();
      await _simulateVoiceInput("Salut Nabour, vreau să merg până la Aeroportul Otopeni, terminalul plecări.");
    } else if (role == GhostRole.driverOnly) {
      _currentStep = GhostTestStep.driverAcceptingRide;
      notifyListeners();
      Logger.info('⏳ Driver Ghost: Waiting for any ride offer...', tag: 'GHOST_ENGINE');
    }
  }

  /// 🤝 Notificare externă (din MapScreen) că a apărut o ofertă de cursă
  void notifyRideOfferReceived() async {
    if (_activeRole == GhostRole.driverOnly || (_activeRole == GhostRole.singleDevice && _currentStep == GhostTestStep.switchingToDriver)) {
      Logger.info('🔔 Ghost detected ride offer! Processing auto-acceptance...', tag: 'GHOST_ENGINE');
      await Future.delayed(const Duration(seconds: 2));
      await _simulateDriverAcceptance();
    }
  }

  Future<void> _simulateVoiceInput(String text) async {
    if (_passengerController == null) return;
    Logger.info('🎭 Ghost says: "$text"', tag: 'GHOST_ENGINE');
    await _passengerController!.handleManualInput(text);
  }

  void onTtsFinished(String message) {
    if (!isActive) return;
    _lastRobotMessage = message.toLowerCase();
    _processNextStep();
  }

  void _processNextStep() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!isActive) return;

    switch (_currentStep) {
      case GhostTestStep.passengerInitialRequest:
        if (_lastRobotMessage.contains('otopeni') || _lastRobotMessage.contains('aeroport')) {
           _currentStep = GhostTestStep.passengerConfirmingAddress;
           await _simulateVoiceInput("Da, așa este. Confirm adresa.");
        }
        break;
        
      case GhostTestStep.passengerConfirmingAddress:
        if (_lastRobotMessage.contains('căutăm un șofer') || _lastRobotMessage.contains('comandat')) {
          _currentStep = GhostTestStep.passengerSearchingDriver;
          
          if (_activeRole == GhostRole.singleDevice) {
            await _moveToDriverSequence();
          } else {
            Logger.info('🛰️ Passenger Ghost: Ride requested. Waiting for a real driver to accept...', tag: 'GHOST_ENGINE');
          }
        }
        break;
        
      case GhostTestStep.switchingToDriver:
         // În single device, am ajuns aici după switch
         _currentStep = GhostTestStep.driverAcceptingRide;
         // _simulateDriverAcceptance va fi chemat de notifyRideOfferReceived sau manual aici
         break;

      case GhostTestStep.driverAcceptingRide:
         // Dacă suntem DriverOnly, am terminat misiunea după accept
         if (_activeRole == GhostRole.driverOnly) {
           _currentStep = GhostTestStep.finished;
           Logger.info('✅ Driver Ghost: MISSION ACCOMPLISHED', tag: 'GHOST_ENGINE');
           // Nu oprim testul complet ca să putem vedea starea pe HUD
         }
         break;
         
      case GhostTestStep.passengerConfirmingRide:
         await _simulateVoiceInput("Perfect, mulțumesc!");
         _currentStep = GhostTestStep.finished;
         Logger.info('✅ Passenger Ghost: MISSION ACCOMPLISHED', tag: 'GHOST_ENGINE');
         break;

      default: break;
    }
    notifyListeners();
  }

  Future<void> _moveToDriverSequence() async {
    _currentStep = GhostTestStep.switchingToDriver;
    notifyListeners();
    VoiceUIAutomationRegistry().executeAction('set_role_driver');
    await Future.delayed(const Duration(seconds: 4));
    // notifyRideOfferReceived va fi declanșat de MapScreen când apare oferta
  }

  Future<void> _simulateDriverAcceptance() async {
    Logger.info('🖱️ Ghost: Clicking ACCEPT...', tag: 'GHOST_ENGINE');
    final success = VoiceUIAutomationRegistry().executeAction('accept_ride_request');
    
    if (success) {
      if (_activeRole == GhostRole.singleDevice) {
        await Future.delayed(const Duration(seconds: 3));
        _currentStep = GhostTestStep.passengerConfirmingRide;
        VoiceUIAutomationRegistry().executeAction('set_role_passenger');
      } else if (_activeRole == GhostRole.driverOnly) {
        _currentStep = GhostTestStep.finished;
      }
    }
    notifyListeners();
  }

  void stopTest() {
    _activeRole = GhostRole.none;
    _currentStep = GhostTestStep.idle;
    notifyListeners();
    Logger.info('🛑 Ghost simulation stopped.', tag: 'GHOST_ENGINE');
  }
}
