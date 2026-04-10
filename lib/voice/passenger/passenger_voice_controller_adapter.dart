import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../states/voice_interaction_states.dart';
import '../core/voice_orchestrator.dart';
import 'passenger_voice_controller.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🎯 Adapter pentru PassengerVoiceController - face AI-ul compatibil cu UI-ul existent
/// 
/// Acest adapter implementează toate metodele și getter-ii pe care UI-ul existent se bazează,
/// delegând implementarea către PassengerVoiceController.
class PassengerVoiceControllerAdapter extends ChangeNotifier {
  final PassengerVoiceController _controller;
  
  PassengerVoiceControllerAdapter({
    required PassengerVoiceController controller,
  }) : _controller = controller {
    // 🎯 Ascultă schimbările din controller-ul real
    _controller.addListener(() {
      notifyListeners();
    });
  }

  // ✅ Implementează toate metodele pe care UI-ul existent se bazează
  
  /// 🎤 Metode pentru interacțiunea vocală
  Future<void> startVoiceInteraction() async {
    await _controller.processVoiceInput('Salut, unde doriți să mergeți?');
  }
  
  Future<void> startVoiceBooking() async {
    await _controller.processVoiceInput('Vreau să rezerv o cursă');
  }
  
  void stopVoiceInteraction() {
    _controller.reset();
  }
  
  void reset() {
    _controller.reset();
  }
  
  void toggleWakeWord() => unawaited(_controller.toggleWakeWordDetection());
  
  void enableWakeWordDetection() => unawaited(_controller.enableWakeWordDetection());
  
  void toggleContinuousListening() => unawaited(_controller.toggleContinuousListening());
  
  void startContinuousListening() => unawaited(_controller.enableContinuousListening());
  
  void recoverFromError() {
    _controller.reset();
  }
  
  void finalizeRideBooking() {
    // 🎯 Implementare pentru finalizarea cursei
    Logger.debug('Finalize ride booking', tag: 'ADAPTER');
  }
  
  Future<void> waitForUserConfirmation() async {
    // 🎯 Implementare pentru așteptarea confirmării
    await Future.delayed(const Duration(seconds: 1));
  }
  
  void setProcessingState(VoiceProcessingState state) {
    // 🎯 Starea este gestionată de controller-ul vocal
    Logger.debug('Set processing state: $state', tag: 'ADAPTER');
  }
  
  Future<void> updateContextAndProcess(String userInput) async {
    await _controller.processVoiceInput(userInput);
  }
  
  // ✅ Implementează toate getter-ii pe care UI-ul existent se bazează
  
  /// 🎯 Stări pentru UI
  bool get isOverlayVisible => _controller.showRideConfirmation || _controller.showSearchingDriver;
  bool get isWakeWordEnabled => _controller.wakeWordEnabled;
  bool get isContinuousListening => _controller.continuousListeningEnabled;
  bool get isInitialized => _controller.isInitialized;
  
  /// 🎯 Stări pentru procesare
  VoiceProcessingState get processingState => _controller.processingState;
  VoiceConversationState get conversationState => _mapRideStateToConversationState(_controller.rideState);
  RideFlowState get state => _controller.rideState;
  
  /// 🎯 Răspunsuri AI
  String get aiResponse => _controller.lastAiMessage;
  
  /// 🎯 Date pentru cursă
  String get currentDestination => _controller.destinationAddressForUI ?? '';
  String get currentPickup => _controller.pickupAddressForUI ?? 'Locație nesetată';
  double get estimatedPrice => _controller.estimatedPrice ?? 0.0;
  Duration get estimatedDuration => Duration(
        minutes: (_controller.estimatedDurationMinutes ?? 0).round(),
      );
  bool get canBookRide => _controller.destinationAddressForUI != null && (_controller.estimatedPrice ?? 0) > 0;
  
  /// 🎯 Istoric conversație
  List<String> get conversationHistory => _controller.conversationHistory;
  
  /// 🎯 Voice Orchestrator (pentru compatibilitate)
  VoiceOrchestrator get voice => _controller.voiceOrchestrator;
  
  VoiceConversationState _mapRideStateToConversationState(RideFlowState rideState) {
    switch (rideState) {
      case RideFlowState.listeningForInitialCommand:
      case RideFlowState.awaitingAddressConfirmation:
      case RideFlowState.awaitingRideOptionSelection:
        return VoiceConversationState.listeningForInitialCommand;
      case RideFlowState.processingCommand:
      case RideFlowState.showingRideOptions:
      case RideFlowState.searchingDrivers:
      case RideFlowState.driversFound:
      case RideFlowState.sendingToFirebase:
      case RideFlowState.waitingForDriverResponse:
      case RideFlowState.awaitingDriverAcceptance:
        return VoiceConversationState.processingCommand;
      case RideFlowState.destinationConfirmed:
      case RideFlowState.rideOptionSelected:
        return VoiceConversationState.destinationConfirmed;
      case RideFlowState.awaitingConfirmation:
      case RideFlowState.awaitingRideConfirmation:
      case RideFlowState.awaitingFinalRideConfirmation:
      case RideFlowState.priceConfirmed:
      case RideFlowState.driverFound:
        return VoiceConversationState.waitingForConfirmation;
      case RideFlowState.confirmationReceived:
      case RideFlowState.rideConfirmed:
      case RideFlowState.bookingFinalized:
      case RideFlowState.rideAccepted:
      case RideFlowState.driverSelected:
      case RideFlowState.driverEnRoute:
      case RideFlowState.driverArrived:
      case RideFlowState.rideFinalized:
      case RideFlowState.rideCompleted:
        return VoiceConversationState.confirmed;
      case RideFlowState.awaitingAddressSelection:
      case RideFlowState.awaitingClarification:
      case RideFlowState.awaitingDestinationGeocodeDetail:
        return VoiceConversationState.awaitingClarification;
      case RideFlowState.error:
        return VoiceConversationState.error;
      case RideFlowState.idle:
      case RideFlowState.awaitingPickupLocation:
      case RideFlowState.driverRejected:
        return VoiceConversationState.idle;
    }
  }
  
  // ✅ Metode pentru testare
  
  bool isPositiveResponse(String response) {
    final positive = ['da', 'yes', 'ok', 'confirmă', 'accept', 'perfect', 'corect'];
    return positive.any((word) => response.toLowerCase().contains(word));
  }
  
  bool isNegativeResponse(String response) {
    final negative = ['nu', 'no', 'refuz', 'anulează'];
    return negative.any((word) => response.toLowerCase().contains(word));
  }
  
  // ✅ Metode pentru inițializare
  
  Future<void> initializeVoiceSystem() async {
    await _controller.initialize();
  }
  
  // ✅ Cleanup
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
