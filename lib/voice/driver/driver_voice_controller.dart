import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ride_model.dart';
import '../../models/support_ticket_model.dart';
import '../../services/firestore_service.dart';
import '../core/voice_orchestrator.dart';
import '../states/voice_interaction_states.dart';
import 'package:nabour_app/utils/logger.dart';

class DriverVoiceController extends ChangeNotifier {
  DriverVoiceController({
    VoiceOrchestrator? voiceOrchestrator,
    FirestoreService? firestoreService,
  })  : _voice = voiceOrchestrator ?? VoiceOrchestrator(),
        _firestoreService = firestoreService ?? FirestoreService();

  final VoiceOrchestrator _voice;
  final FirestoreService _firestoreService;
  
  bool _isInitialized = false;
  final bool _isInCall = false;
  bool _isListeningForCommand = false;
  DriverVoiceRideRequest? _currentRequest;
  DriverVoiceState _state = DriverVoiceState.idle;
  bool _isEmergencyMode = false;
  bool _isSafetyMode = true;
  final List<String> _voiceCommands = [];
  int _commandCount = 0;
  DateTime? _lastCommandTime;
  static const Duration _commandCooldown = Duration(milliseconds: 500);
  
  bool _isProcessingAccept = false;
  bool _isProcessingReject = false;

  Future<void> Function()? _onAcceptRideCallback;
  Future<void> Function()? _onDeclineRideCallback;
  Future<void> Function()? _onNavigateToActiveRideCallback;
  StreamSubscription<Ride?>? _rideStatusSubscription;
  Timer? _safetyMonitoringTimer;
  
  bool get isProcessingAccept => _isProcessingAccept;
  bool get isProcessingReject => _isProcessingReject;

  // Getters
  bool get isInCall => _isInCall;
  bool get isListeningForCommand => _isListeningForCommand;
  DriverVoiceRideRequest? get currentRequest => _currentRequest;
  DriverVoiceState get state => _state;
  bool get isEmergencyMode => _isEmergencyMode;
  bool get isSafetyMode => _isSafetyMode;
  List<String> get voiceCommands => List.unmodifiable(_voiceCommands);
  
  // Make voice orchestrator accessible for external use
  VoiceOrchestrator get voice => _voice;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _voice.initialize();
      _setupVoiceCallbacks();
      _isInitialized = true;
      Logger.info('Driver voice system initialized');
    } catch (e) {
      Logger.error('Driver voice system failed to initialize: $e', error: e);
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  void _setupVoiceCallbacks() {
    _voice.setStateChangeCallback((state) {
      _isListeningForCommand = state == VoiceProcessingState.listening;
      notifyListeners();
    });

    _voice.setSpeechResultCallback((result) {
      _processDriverCommand(result);
    });

    _voice.setSpeechErrorCallback((error) {
      Logger.error('Driver speech error: $error', error: error);
      _handleSpeechError(error);
    });
  }

  // Handle speech errors with recovery
  void _handleSpeechError(String error) {
    Logger.error('Driver speech error: $error', error: error);
    // Auto-recovery for common errors
    if (error.contains('permission') || error.contains('microphone')) {
      Logger.error('Attempting to recover from permission error...');
      // Request permission again
      _voice.initialize();
    } else if (error.contains('network') || error.contains('connection')) {
      Logger.error('Attempting to recover from network error...');
      // Wait and retry
      Future.delayed(const Duration(seconds: 2), () {
        if (_state == DriverVoiceState.waitingForDecision) {
          _waitForDriverDecision();
        }
      });
    } else {
      Logger.error('Generic error recovery...');
      // Generic recovery
      Future.delayed(const Duration(seconds: 1), () {
        if (_state == DriverVoiceState.waitingForDecision) {
          _waitForDriverDecision();
        }
      });
    }
  }

  Future<void> _updateRideFields(Map<String, dynamic> data) async {
    if (_currentRequest == null) return;
    try {
      await _firestoreService.updateRideFields(_currentRequest!.id, data);
    } catch (e) {
      Logger.error('Failed to update ride fields: $e', tag: 'DRIVER_VOICE', error: e);
    }
  }

  Future<void> _updateRideStatus(String status, {Map<String, dynamic>? extraFields}) async {
    final payload = <String, dynamic>{
      'status': status,
      'driverStatusUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (extraFields != null) {
      payload.addAll(extraFields);
    }
    await _updateRideFields(payload);
  }

  Future<void> _updateDriverAcceptanceStatus(String status) async {
    if (_currentRequest == null) return;
    try {
      await _firestoreService.updateDriverAcceptanceStatus(_currentRequest!.id, status);
    } catch (e) {
      Logger.error('Failed to update driver acceptance status: $e', tag: 'DRIVER_VOICE', error: e);
    }
  }

  Future<void> _submitSupportTicket({
    required String reportType,
    required String message,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      final ticket = SupportTicket(
        userId: userId,
        rideId: _currentRequest?.id,
        reportType: reportType,
        message: message,
        timestamp: Timestamp.now(),
      );
      await _firestoreService.submitSupportTicket(ticket);
    } catch (e) {
      Logger.error('Failed to submit support ticket: $e', tag: 'DRIVER_VOICE', error: e);
    }
  }

  Future<void> handleIncomingRideCall(
    DriverVoiceRideRequest request, {
    Future<void> Function()? onAcceptRide,
    Future<void> Function()? onDeclineRide,
    Future<void> Function()? onNavigateToActiveRide,
  }) async {
    await ensureInitialized();
    if (_currentRequest != null &&
        _currentRequest!.id == request.id &&
        _state != DriverVoiceState.idle) {
      Logger.debug('Ride ${request.id} already announced, skipping duplicate.', tag: 'DRIVER_VOICE');
      return;
    }
    _currentRequest = request;
    _onAcceptRideCallback = onAcceptRide;
    _onDeclineRideCallback = onDeclineRide;
    _onNavigateToActiveRideCallback = onNavigateToActiveRide;
    _setState(DriverVoiceState.receivingCall);
    
    try {
      // ANNOUNCE THE RIDE REQUEST
      await _announceRideRequest(request);
      
      // WAIT FOR DRIVER RESPONSE
      await _waitForDriverDecision();
      
    } catch (e) {
      Logger.error('Driver voice call error: $e', error: e);
      _setState(DriverVoiceState.idle);
    }
  }

  Future<void> _announceRideRequest(DriverVoiceRideRequest request) async {
    _setState(DriverVoiceState.announcing);
    
    final announcement = _generateRideAnnouncement(request);
    await _voice.speak(announcement);
  }

  String _generateRideAnnouncement(DriverVoiceRideRequest request) {
    return "Comandă nouă! "
           "Ridicare de la ${request.pickupAddress}, "
           "destinația ${request.destinationAddress}. "
           "Distanța ${request.distance.toStringAsFixed(1)} kilometri, "
           "prețul estimat ${request.estimatedPrice.toStringAsFixed(0)} lei. "
           "Client: ${request.passengerName}. "
           "Spuneți 'Accept' pentru a accepta sau 'Refuz' pentru a refuza.";
  }

  Future<void> _waitForDriverDecision() async {
    _setState(DriverVoiceState.waitingForDecision);
    
    // Give driver up to 20 seconds to respond
    final response = await _voice.listen(timeoutSeconds: 20);
    
    if (response == null) {
      await _voice.speak("Nu am auzit răspunsul. Comanda a fost anulată.");
      _setState(DriverVoiceState.idle);
      return;
    }
    
    if (_isAcceptResponse(response)) {
      await acceptRide();
    } else if (_isRejectResponse(response)) {
      await rejectRide();
    } else {
      await _voice.speak("Nu am înțeles. Spuneți 'Accept' sau 'Refuz'.");
      await _waitForDriverDecision();
    }
  }

  bool _isAcceptResponse(String response) {
    final acceptKeywords = _romanianPatterns['accept']!;
    return acceptKeywords.any((word) => response.toLowerCase().contains(word));
  }

  bool _isRejectResponse(String response) {
    final rejectKeywords = _romanianPatterns['reject']!;
    return rejectKeywords.any((word) => response.toLowerCase().contains(word));
  }

  Future<void> acceptRide() async {
    // 🚗 FIX: Protecție împotriva apăsărilor multiple
    if (_isProcessingAccept) {
      Logger.debug('Already processing accept request, ignoring duplicate call', tag: 'DRIVER_VOICE');
      return;
    }
    if (_currentRequest == null) return;
    
    _isProcessingAccept = true;
    
    try {
      await _voice.speak("Comandă acceptată!");
      
      if (_onAcceptRideCallback != null) {
        await _onAcceptRideCallback!();
      } else {
        await _firestoreService.acceptRide(_currentRequest!.id);
      }

      await _updateDriverAcceptanceStatus('accepted');
      _setState(DriverVoiceState.rideAccepted);

      final navigationMessage = _generateNavigationMessage();
      await _voice.speak(navigationMessage);

      await _onNavigateToActiveRideCallback?.call();
      _onAcceptRideCallback = null;
      _onDeclineRideCallback = null;
      _onNavigateToActiveRideCallback = null;

      _monitorRideStatus();
    } catch (e) {
      await _voice.speak("Eroare la procesarea comenzii.");
      _setState(DriverVoiceState.idle);
    } finally {
      // 🚗 FIX: Reset protecția după procesare
      _isProcessingAccept = false;
      notifyListeners();
    }
  }

  String _generateNavigationMessage() {
    final request = _currentRequest!;
    return "Deschide Google Maps sau Waze pentru drum către ${request.pickupAddress}. "
           "Clientul a fost anunțat. Timp estimat: aproximativ ${request.etaToPickup} minute. "
           "Gestionează cursa din ecran: am ajuns, începe și termină cursa. "
           "Nu mai ascult comenzi vocale automate pe durata cursei.";
  }

  Future<void> rejectRide() async {
    // 🚗 FIX: Protecție împotriva apăsărilor multiple
    if (_isProcessingReject) {
      Logger.debug('Already processing reject request, ignoring duplicate call', tag: 'DRIVER_VOICE');
      return;
    }
    if (_currentRequest == null) return;
    
    _isProcessingReject = true;
    
    try {
      await _voice.speak("Comandă refuzată. Mulțumesc!");
      
      if (_onDeclineRideCallback != null) {
        await _onDeclineRideCallback!();
      } else {
        await _firestoreService.declineRide(_currentRequest!.id);
      }

      await _updateDriverAcceptanceStatus('declined');

      _setState(DriverVoiceState.idle);
      _currentRequest = null;
      _onAcceptRideCallback = null;
      _onDeclineRideCallback = null;
      _onNavigateToActiveRideCallback = null;
    } finally {
      // 🚗 FIX: Reset protecția după procesare
      _isProcessingReject = false;
      notifyListeners();
    }
  }

  Future<void> _processDriverCommand(String command) async {
    // Rate limiting for commands
    if (_lastCommandTime != null && 
        DateTime.now().difference(_lastCommandTime!) < _commandCooldown) {
      return;
    }
    
    _lastCommandTime = DateTime.now();
    _commandCount++;
    
    final cmd = command.toLowerCase();
    _addVoiceCommand(command);
    
    // Emergency commands (highest priority)
    if (_isEmergencyCommand(cmd)) {
      await _handleEmergencyCommand(cmd);
      return;
    }
    
    // Safety commands
    if (_isSafetyCommand(cmd)) {
      await _handleSafetyCommand(cmd);
      return;
    }
    
    // Standard ride commands
    if (cmd.contains('am ajuns') || cmd.contains('ajuns la client')) {
      await _handleArrivedAtPickup();
    } else if (cmd.contains('client a urcat') || cmd.contains('început cursă')) {
      await _handleRideStarted();
    } else if (cmd.contains('ajuns la destinație') || cmd.contains('cursă terminată')) {
      await _handleArrivedAtDestination();
    } else if (cmd.contains('mesaj') || cmd.contains('trimite')) {
      await _handleSendMessage();
    } else if (cmd.contains('nu găsesc') || cmd.contains('problemă')) {
      await _handleProblem();
    } else if (cmd.contains('anulează') || cmd.contains('cancel')) {
      await _handleCancelRide();
    } else if (cmd.contains('ajutor') || cmd.contains('help')) {
      await _showDriverHelp();
    } else if (cmd.contains('status') || cmd.contains('stare')) {
      await _announceRideStatus();
    } else {
      await _handleUnknownCommand(command);
    }
  }

  bool _isEmergencyCommand(String command) {
    final emergencyWords = ['ajutor', 'help', 'emergență', 'emergency', 'sos', 'urgent'];
    return emergencyWords.any((word) => command.contains(word));
  }

  bool _isSafetyCommand(String command) {
    final safetyWords = ['stop', 'oprește', 'atenție', 'attention', 'pericol', 'danger'];
    return safetyWords.any((word) => command.contains(word));
  }

  Future<void> _handleEmergencyCommand(String command) async {
    if (_currentRequest == null) return;
    _isEmergencyMode = true;
    await _voice.speak("ACTIVARE MOD EMERGENȚĂ! Ce s-a întâmplat?");
    
    final emergency = await _voice.listen();
    if (emergency != null) {
      await _voice.speak("Am înregistrat urgența. Contactez suportul și autoritățile imediat.");
      
      try {
        await _submitSupportTicket(
          reportType: 'voice_emergency_driver',
          message: 'Ride ${_currentRequest!.id}: $emergency',
        );
        await _firestoreService.sendChatMessage(
          _currentRequest!.id,
          "URGENȚĂ: $emergency. Contactez autoritățile.",
        );
        await _firestoreService.logEmergencyEvent(
          rideId: _currentRequest!.id,
          triggeredByUserId: _currentRequest!.driverId ??
              FirebaseAuth.instance.currentUser?.uid ??
              '',
          userRole: 'driver',
          eventType: 'voice_emergency',
          note: emergency,
        );
      } catch (e) {
        Logger.error('Failed to log emergency: $e', tag: 'DRIVER_VOICE', error: e);
      }
    }
    
    _isEmergencyMode = false;
  }

  Future<void> _handleSafetyCommand(String command) async {
    if (_currentRequest == null) return;
    await _voice.speak("Comandă de siguranță activată. Ce trebuie să fac?");
    
    final safety = await _voice.listen(timeoutSeconds: 10);
    if (safety != null) {
      await _voice.speak("Am înregistrat comanda de siguranță. Sunt aici să ajut.");
      
      try {
        await _submitSupportTicket(
          reportType: 'voice_safety_driver',
          message: 'Ride ${_currentRequest!.id}: $safety',
        );
      } catch (e) {
        Logger.error('Failed to log safety command: $e', tag: 'DRIVER_VOICE', error: e);
      }
    }
  }

  Future<void> _handleArrivedAtPickup() async {
    if (_state != DriverVoiceState.navigatingToPickup) return;
    
    _setState(DriverVoiceState.arrivedAtPickup);
    
    await _voice.speak("Confirmat! Ați ajuns la client. Anunț pasagerul.");
    
    await _updateRideStatus('driver_arrived', extraFields: {
      'driverArrivedAt': FieldValue.serverTimestamp(),
    });
    
    await _voice.speak(
      "Pasagerul a fost anunțat. "
      "Când urcă în mașină, spuneți 'Client a urcat' pentru a începe cursa. "
      "Comenzi disponibile: 'Client a urcat', 'Probleme cu clientul', 'Ajutor'."
    );
  }

  Future<void> _handleRideStarted() async {
    if (_state != DriverVoiceState.arrivedAtPickup) return;
    
    _setState(DriverVoiceState.rideInProgress);
    
    await _voice.speak("Cursă începută! Navigez către destinație.");
    
    await _updateRideStatus('ride_started', extraFields: {
      'rideStartedAt': FieldValue.serverTimestamp(),
    });
    
    await _voice.speak(
      "Destinația: ${_currentRequest!.destinationAddress}. "
      "Timp estimat: ${_currentRequest!.etaToDestination} minute. "
      "Când ajungeți, spuneți 'Am ajuns la destinație'. "
      "Comenzi disponibile: 'Status cursă', 'Probleme', 'Ajutor'."
    );
  }

  Future<void> _handleArrivedAtDestination() async {
    if (_state != DriverVoiceState.rideInProgress) return;
    
    _setState(DriverVoiceState.rideCompleted);
    
    await _voice.speak("Perfect! Cursă completată cu succes.");
    
    await _updateRideStatus('completed', extraFields: {
      'rideCompletedAt': FieldValue.serverTimestamp(),
    });
    
    await _voice.speak(
      "Plata de ${_currentRequest!.estimatedPrice.toStringAsFixed(0)} lei a fost procesată. "
      "Vă mulțumesc pentru cursă! "
      "Sunteți din nou disponibil pentru comenzi noi."
    );
    
    // Reset state
    _setState(DriverVoiceState.idle);
    _currentRequest = null;
  }

  Future<void> _handleSendMessage() async {
    if (_currentRequest == null) return;
    await _voice.speak("Ce mesaj doriți să trimiteți clientului?");
    
    final message = await _voice.listen();
    
    if (message != null && message.trim().isNotEmpty) {
      try {
        await _firestoreService.sendChatMessage(_currentRequest!.id, message);
        await _voice.speak("Mesajul a fost trimis: '$message'");
      } catch (e) {
        Logger.error('Failed to send chat message: $e', tag: 'DRIVER_VOICE', error: e);
        await _voice.speak("Nu am reușit să trimit mesajul. Încercați din nou.");
      }
    } else {
      await _voice.speak("Nu am înțeles mesajul.");
    }
  }

  Future<void> _handleProblem() async {
    if (_currentRequest == null) return;
    await _voice.speak("Ce problemă aveți?");
    
    final problem = await _voice.listen();
    
    if (problem != null) {
      await _voice.speak("Am înregistrat problema. Contactez suportul și clientul.");
      
      try {
        await _submitSupportTicket(
          reportType: 'driver_problem',
          message: 'Ride ${_currentRequest!.id}: $problem',
        );
        await _firestoreService.sendChatMessage(
          _currentRequest!.id,
          "Am întâmpinat o problemă: $problem. Vă contactez imediat.",
        );
      } catch (e) {
        Logger.error('Failed to log driver problem: $e', tag: 'DRIVER_VOICE', error: e);
      }
    }
  }

  Future<void> _handleCancelRide() async {
    await _voice.speak(
      "Sunteți sigur că doriți să anulați cursa? "
      "Spuneți 'Da, anulează' pentru confirmare."
    );
    
    final confirmation = await _voice.listen(timeoutSeconds: 10);
    
    if (confirmation != null && 
        (confirmation.toLowerCase().contains('da') || 
         confirmation.toLowerCase().contains('anulează'))) {
      
      await _voice.speak("Cursă anulată. Notific clientul.");
      
      await _firestoreService.cancelRide(_currentRequest!.id);
      await _updateRideStatus('cancelled', extraFields: {
        'cancelledBy': 'driver',
      });
      await _updateDriverAcceptanceStatus('cancelled');
      
      _setState(DriverVoiceState.idle);
      _currentRequest = null;
      _onAcceptRideCallback = null;
      _onDeclineRideCallback = null;
      _onNavigateToActiveRideCallback = null;
    } else {
      await _voice.speak("Anulare întreruptă. Cursa continuă.");
    }
  }

  Future<void> _showDriverHelp() async {
    const helpMessage = "Comenzi disponibile: 'Am ajuns la client', 'Client a urcat', "
                        "'Am ajuns la destinație', 'Trimite mesaj', 'Status cursă', "
                        "'Ajutor', 'Anulează cursă'. Pentru urgențe, spuneți 'AJUTOR'!";
    await _voice.speak(helpMessage);
  }

  Future<void> _announceRideStatus() async {
    final request = _currentRequest!;
    String statusMessage = "Status cursă: ";
    
    switch (_state) {
      case DriverVoiceState.navigatingToPickup:
        statusMessage += "Navigez către client la ${request.pickupAddress}. "
                        "Timp estimat: ${request.etaToPickup} minute.";
        break;
      case DriverVoiceState.arrivedAtPickup:
        statusMessage += "Am ajuns la client. Aștept să urcă în mașină.";
        break;
      case DriverVoiceState.rideInProgress:
        statusMessage += "Cursă în curs. Navigez către ${request.destinationAddress}. "
                        "Timp estimat: ${request.etaToDestination} minute.";
        break;
      default:
        statusMessage += "Cursă finalizată.";
    }
    
    await _voice.speak(statusMessage);
  }

  Future<void> _handleUnknownCommand(String command) async {
    await _voice.speak("Nu am înțeles comanda '$command'. Spuneți 'Ajutor' pentru lista de comenzi.");
  }

  void _monitorRideStatus() {
    // Cancel existing subscription
    _rideStatusSubscription?.cancel();
    if (_currentRequest == null) return;
    
    _rideStatusSubscription = _firestoreService
        .getRideStream(_currentRequest!.id)
        .listen((ride) {
      _handleExternalStatusChange(ride.status);
    });
  }

  Future<void> _handleExternalStatusChange(String status) async {
    switch (status) {
      case 'cancelled':
        if (_currentRequest == null) return;
        await _voice.speak("Cursa a fost anulată.");
        _rideStatusSubscription?.cancel();
        _rideStatusSubscription = null;
        _setState(DriverVoiceState.idle);
        _currentRequest = null;
        break;
      case 'cancelled_by_customer':
        if (_currentRequest == null) return;
        await _voice.speak("Clientul a anulat cursa.");
        _rideStatusSubscription?.cancel();
        _rideStatusSubscription = null;
        _setState(DriverVoiceState.idle);
        _currentRequest = null;
        break;
      case 'expired':
        if (_currentRequest == null) return;
        await _voice.speak("Cursa a expirat.");
        _rideStatusSubscription?.cancel();
        _rideStatusSubscription = null;
        _setState(DriverVoiceState.idle);
        _currentRequest = null;
        break;
      case 'customer_not_found':
        if (_currentRequest == null) return;
        await _voice.speak("Clientul nu a fost găsit după 5 minute. Cursa se anulează.");
        _rideStatusSubscription?.cancel();
        _rideStatusSubscription = null;
        _setState(DriverVoiceState.idle);
        _currentRequest = null;
        break;
      case 'customer_rating':
        await _voice.speak("Clientul v-a evaluat. Verificați ratingul în aplicație.");
        break;
    }
  }

  void _addVoiceCommand(String command) {
    _voiceCommands.add(command);
    if (_voiceCommands.length > 100) {
      _voiceCommands.removeAt(0);
    }
    notifyListeners();
  }

  void _setState(DriverVoiceState state) {
    _state = state;
    notifyListeners();
  }

  // Public methods
  Future<void> reset() async {
    _currentRequest = null;
    _setState(DriverVoiceState.idle);
    await _voice.stop();
    _isEmergencyMode = false;
    _voiceCommands.clear();
    _commandCount = 0;
    _lastCommandTime = null;
    _onAcceptRideCallback = null;
    _onDeclineRideCallback = null;
    _onNavigateToActiveRideCallback = null;
    _rideStatusSubscription?.cancel();
    _rideStatusSubscription = null;
    _safetyMonitoringTimer?.cancel();
    _safetyMonitoringTimer = null;
  }

  @override
  void dispose() {
    // Cancel all timers
    _safetyMonitoringTimer?.cancel();
    
    // Cancel all subscriptions
    _rideStatusSubscription?.cancel();
    
    // Dispose voice service
    _voice.dispose();
    
    super.dispose();
  }

  // Toggle safety mode
  void toggleSafetyMode() {
    _isSafetyMode = !_isSafetyMode;
    if (_isSafetyMode) {
      _voice.speak("Modul de siguranță activat.");
    } else {
      _voice.speak("Modul de siguranță dezactivat.");
    }
    notifyListeners();
  }

  // Get ride statistics
  Map<String, dynamic> getRideStatistics() {
    return {
      'totalCommands': _commandCount,
      'currentState': _state.toString(),
      'isEmergencyMode': _isEmergencyMode,
      'isSafetyMode': _isSafetyMode,
      'lastCommandTime': _lastCommandTime?.toIso8601String(),
      'voiceCommands': _voiceCommands.length,
    };
  }

  // Romanian language patterns
  static const Map<String, List<String>> _romanianPatterns = {
    'accept': ['accept', 'da', 'yes', 'ok', 'confirm', 'iau', 'confirmă', 'corect'],
    'reject': ['refuz', 'nu', 'no', 'reject', 'pas', 'anulează', 'nu vreau'],
  };
}

enum DriverVoiceState {
  idle,
  receivingCall,
  announcing,
  waitingForDecision,
  rideAccepted,
  navigatingToPickup,
  arrivedAtPickup,
  rideInProgress,
  rideCompleted,
}

class DriverVoiceRideRequest {
  final String id;
  final String passengerId;
  final String pickupAddress;
  final String destinationAddress;
  final double distance;
  final double estimatedPrice;
  final int etaToPickup;
  final int etaToDestination;
  final String passengerName;
  final String passengerPhone;
  final String? driverId;

  DriverVoiceRideRequest({
    required this.id,
    required this.passengerId,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.distance,
    required this.estimatedPrice,
    required this.etaToPickup,
    required this.etaToDestination,
    required this.passengerName,
    required this.passengerPhone,
    this.driverId,
  });

  factory DriverVoiceRideRequest.fromRide(
    Ride ride, {
    String? passengerName,
    String? passengerPhone,
  }) {
    final pickupEta = ride.driverDistance != null
        ? ride.driverDistance!.ceil()
        : (ride.durationInMinutes?.clamp(1, 15) ?? 5).toInt();
    final destinationEta = ride.durationInMinutes?.ceil() ?? 10;

    return DriverVoiceRideRequest(
      id: ride.id,
      passengerId: ride.passengerId,
      pickupAddress: ride.startAddress,
      destinationAddress: ride.destinationAddress,
      distance: ride.distance,
      estimatedPrice: ride.totalCost,
      etaToPickup: pickupEta,
      etaToDestination: destinationEta,
      passengerName: passengerName ?? 'Pasager',
      passengerPhone: passengerPhone ?? '',
      driverId: ride.driverId,
    );
  }
}

// Enhanced Mock services for testing
