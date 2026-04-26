import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

// Existing FriendsRide services
import '../../services/firestore_service.dart';
import '../../models/ride_model.dart';
import '../../models/voice_models.dart';

// New Voice AI System
import '../states/voice_interaction_states.dart';
import '../passenger/passenger_voice_controller.dart';
import '../testing/nabour_ghost_orchestrator.dart';
import 'package:nabour_app/utils/logger.dart';


/// 🎯 FriendsRide Voice Integration - Sistemul vocal complet integrat cu aplicația
/// 
/// Caracteristici:
/// - Integrare perfectă cu serviciile existente FriendsRide
/// - Asistent vocal Nabour (NLP local + LLM opțional) pentru comenzi
/// - Flow complet pentru ride sharing end-to-end
/// - State management sincronizat cu UI-ul
class FriendsRideVoiceIntegration extends ChangeNotifier {
  // 🧠 Componentele AI vocale (lazy init)
  PassengerVoiceController? _voiceController;
  PassengerVoiceController? get passengerController => _voiceController;
  
  // 🚗 Serviciile FriendsRide existente
  final FirestoreService _firestoreService = FirestoreService();
  // final PricingService _pricingService = PricingService(); // Comentat temporar

  
  // 🎯 Starea curentă a sistemului vocal
  VoiceConversationContext _currentContext = VoiceConversationContext(
    rideState: RideFlowState.idle,
    processingState: VoiceProcessingState.idle,
            currentEmotion: VoiceEmotion.friendly,
    conversationHistory: [],
    availableDrivers: [],
    lastInteractionTime: DateTime.now(),
    lastConfidenceLevel: 1.0,
  );
  
  // 🚀 Starea inițializării
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  // 🎤 Starea interacțiunii vocale
  bool _isVoiceActive = false;
  final bool _isListening = false;
  final bool _isSpeaking = false;

  // Last error message surfaced via _handleError — read by MapVoiceOverlay to show snackbar.
  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  // 🎧 Continuous listening state
  bool _isContinuousListeningActive = false;
  Timer? _continuousListeningTimer;
  Timer? _syncTimer;
  // bool _isFirstInteraction = true; // not used currently

  // 🔁 Voice → UI event bridge
  String? _voiceDestination;
  String? _voicePickup;
  bool _hasNewVoiceDestination = false;
  bool _hasNewVoicePickup = false;

  // 🧭 Navigation events from secondary voice path (onCreateRideRequest)
  bool _shouldNavigateToSearching = false;
  String? _navigationRideId;
  
  // 🚗 Datele cursei curente
  RideRequest? _currentRideRequest;
  RideOffer? _currentRideOffer;
  Ride? _currentRide;
  
  // 🎯 Callback pentru navigare (comentat temporar)
  // Function(String)? _navigationCallback;
  
  // 🎯 Constructor
  FriendsRideVoiceIntegration();
  
  /// 🚀 Inițializează toate componentele vocale
  Future<void> _initializeComponents() async {
    if (_isInitializing || _isInitialized) return;
    
    try {
      _isInitializing = true;
      Logger.info('Initializing components...', tag: 'FRIENDSRIDE_VOICE');
      
      // ✅ Inițializez controller-ul vocal cu toate dependințele
      _voiceController = PassengerVoiceController(
        firestoreService: _firestoreService,
      );
      await _voiceController!.initialize();
      Logger.info('Voice controller initialized', tag: 'FRIENDSRIDE_VOICE');
      
      // 🎯 În final: Setez callback-urile
      _setupCallbacks();
      
      _isInitialized = true;
      _isInitializing = false;
      
      Logger.info('All components initialized successfully', tag: 'FRIENDSRIDE_VOICE');
      
      // 👻 Ghost Mode: Link the orchestrator if in debug mode
      if (kDebugMode) {
        try {
          NabourGhostOrchestrator().initialize(_voiceController!);
        } catch (e) {
          Logger.warning('Ghost Orchestrator failed to link: $e', tag: 'VOICE');
        }
      }
      
    } catch (e) {
      Logger.error('Initialization error: $e', tag: 'FRIENDSRIDE_VOICE', error: e);
      _isInitializing = false;
      _isInitialized = false;
    }
  }

  /// 🚀 Public warm-up API for lazy background initialization
  Future<void> warmUp() async {
    try {
      await _initializeComponents();
    } catch (e) {
      Logger.error('warmUp error: $e', tag: 'FRIENDSRIDE_VOICE', error: e);
    }
  }
  
  /// 🎯 Setez callback-urile pentru toate componentele
  void _setupCallbacks() {
    // 🎤 Periodic bridge: sync conversation, processing state, and address events
    _syncTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isInitialized || !_isVoiceActive || _voiceController == null) return;
      try {
        // Sync history (compare by length — the controller reuses the same list object)
        final history = _voiceController!.conversationHistory;
        if (history.length != _currentContext.conversationHistory.length) {
          _currentContext = _currentContext.copyWith(
            conversationHistory: List.from(history), // snapshot so future length comparisons work
            lastInteractionTime: DateTime.now(),
          );
          notifyListeners();
        }

        // Sync processing state
        final p = _voiceController!.processingState;
        if (p != _currentContext.processingState) {
          _currentContext = _currentContext.copyWith(
            processingState: p,
            lastInteractionTime: DateTime.now(),
          );
          notifyListeners();
        }

        // Sync ride state (so MapVoiceOverlay can react when destination is confirmed)
        final r = _voiceController!.rideState;
        if (r != _currentContext.rideState) {
          _currentContext = _currentContext.copyWith(
            rideState: r,
            lastInteractionTime: DateTime.now(),
          );
          notifyListeners();
        }

        // Address events
        final dest = _voiceController!.destinationAddressForUI;
        if (dest != null && dest != _voiceDestination) {
          _voiceDestination = dest;
          _hasNewVoiceDestination = true;
          notifyListeners();
        }
        final pick = _voiceController!.pickupAddressForUI;
        if (pick != null && pick != _voicePickup) {
          _voicePickup = pick;
          _hasNewVoicePickup = true;
          notifyListeners();
        }

        // Navigation event: secondary voice path requested SearchingForDriverScreen
        final ctrl = _voiceController!;
        if (ctrl.showSearchingDriver &&
            ctrl.currentRideId != null &&
            ctrl.currentRideId != _navigationRideId) {
          _navigationRideId = ctrl.currentRideId;
          _shouldNavigateToSearching = true;
          notifyListeners();
        }
      } catch (e) {
        Logger.warning('FriendsVoiceIntegration: driver state listener error: $e', tag: 'VOICE');
      }
    });
  }

  /// 🎯 Setează callback-ul pentru navigare
  void setNavigationCallback(Function(String) callback) {
          // _navigationCallback = callback; // Comentat temporar
  }

  /// Conecteaza vocea la panelul de adrese din UI.
  /// Apelat din map_screen dupa montarea RideRequestPanel.
  void setRidePanelCallbacks({
    required Function(String pickup, String dest, {double? pickupLat, double? pickupLng, double? destLat, double? destLng}) onFillAddress,
    required VoidCallback onConfirm,
  }) {
    _voiceController?.setRidePanelCallbacks(
      onFillAddress: onFillAddress,
      onConfirm: onConfirm,
    );
  }
  
    // 🎤 Callback-urile sunt gestionate de controller-ul vocal
  
  // 🎤 Contextul este gestionat de controller-ul vocal
  
  // 🚀 Procesarea input-ului vocal este gestionată de controller-ul vocal
  
  // 📝 Contextul este actualizat automat de controller-ul vocal
  
  // 🎯 Starea cursei este gestionată de controller-ul vocal
  
  // 🚗 Integrarea cu serviciile FriendsRide este gestionată de controller-ul vocal
  
    // 🎯 Destinația confirmată este gestionată de controller-ul vocal
  
  // 🚗 Șoferii găsiți sunt gestionați de controller-ul vocal
  
  // 🚗 Toate aceste operații sunt gestionate de controller-ul vocal
  
  /// 🎯 Gestionează erorile
  void _handleError(String error) {
    Logger.error('Error: $error', tag: 'FRIENDSRIDE_VOICE', error: error);

    _lastErrorMessage = _friendlyErrorMessage(error);

    _currentContext = _currentContext.copyWith(
      rideState: RideFlowState.error,
      processingState: VoiceProcessingState.error,
      lastInteractionTime: DateTime.now(),
    );

    notifyListeners();
  }

  /// Maps technical error strings to short, user-friendly Romanian messages.
  static String _friendlyErrorMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('quota') || lower.contains('rate') || lower.contains('429')) {
      return 'Asistentul vocal este temporar indisponibil (limită depășită). Încearcă din nou în câteva minute.';
    }
    if (lower.contains('network') || lower.contains('socket') || lower.contains('connection')) {
      return 'Conexiune întreruptă. Verifică internetul și încearcă din nou.';
    }
    if (lower.contains('timeout')) {
      return 'Răspunsul a durat prea mult. Încearcă din nou.';
    }
    if (lower.contains('microphone') || lower.contains('permission') || lower.contains('mic')) {
      return 'Nu am acces la microfon. Verifică permisiunile aplicației.';
    }
    if (lower.contains('not initialized') || lower.contains('not available')) {
      return 'Asistentul vocal nu este inițializat. Repornește funcția vocală.';
    }
    return 'Asistentul vocal a întâmpinat o eroare. Încearcă din nou.';
  }
  
  /// 🎤 Începe interacțiunea vocală
  Future<void> startVoiceInteraction() async {
    if (!_isInitialized) {
      await _initializeComponents();
    }
    
    try {
      Logger.info('Starting voice interaction...', tag: 'FRIENDSRIDE_VOICE');
      
      _isVoiceActive = true;
      // _isFirstInteraction = true;

      // Instant greeting in UI (AUTONOM)
      const greetingMessage = 'Salutare! Sunt asistentul vocal Nabour. Spune-mi unde vrei să mergi și găsesc un vecin disponibil pentru tine. Unde doriți să mergeți?';
      _currentContext = _currentContext.copyWith(
        conversationHistory: [..._currentContext.conversationHistory, 'AI: $greetingMessage'],
        rideState: RideFlowState.listeningForInitialCommand,
        processingState: VoiceProcessingState.speaking,
        currentEmotion: VoiceEmotion.friendly,
        lastInteractionTime: DateTime.now(),
      );
      notifyListeners();

      // TTS + initial listen
      await _voiceController!.startContinuousConversation();

      // Start continuous loop
      await _startContinuousListening();

      // Actualizează contextul
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.listeningForInitialCommand,
        processingState: VoiceProcessingState.listening,
        currentEmotion: VoiceEmotion.friendly,
        lastInteractionTime: DateTime.now(),
      );

      notifyListeners();
      
    } catch (e) {
      Logger.error('Start voice interaction error: $e', tag: 'FRIENDSRIDE_VOICE', error: e);
      _handleError(e.toString());
    }
  }
  
  /// 🛑 Oprește interacțiunea vocală
  Future<void> stopVoiceInteraction() async {
    try {
      Logger.info('Stopping voice interaction...', tag: 'FRIENDSRIDE_VOICE');
      
      _isVoiceActive = false;
      await _stopContinuousListening();
      
      // Verifică dacă componentele sunt inițializate înainte să le oprești
      if (_isInitialized && _voiceController != null) {
        _voiceController!.reset();
      }
      
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.idle,
        processingState: VoiceProcessingState.idle,
        lastInteractionTime: DateTime.now(),
      );
      
      notifyListeners();
      
    } catch (e) {
      Logger.error('Stop voice interaction error: $e', tag: 'FRIENDSRIDE_VOICE', error: e);
      // În caz de eroare, forțează resetarea
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.idle,
        processingState: VoiceProcessingState.idle,
        lastInteractionTime: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// 🔁 Continuous listening loop: relaunch listen sessions when idle (CORECTAT)
  Future<void> _startContinuousListening() async {
    if (_isContinuousListeningActive) return;
    _isContinuousListeningActive = true;
    _continuousListeningTimer?.cancel();
    _continuousListeningTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isContinuousListeningActive || !_isVoiceActive || _voiceController == null) {
        timer.cancel();
        return;
      }
      try {
        final state = _currentContext.processingState;
        // RideFlow pornește singur STT la confirmare șofer / mesaje critice — nu suprapune listenOnce.
        final rs = _voiceController!.rideState;
        if (rs == RideFlowState.awaitingDriverAcceptance ||
            rs == RideFlowState.driverFound ||
            rs == RideFlowState.awaitingDestinationGeocodeDetail ||
            rs == RideFlowState.awaitingAddressSelection) {
          return;
        }
        // CORECTAT: Verifică doar starea idle, nu waiting (care poate fi folosită pentru sincronizare)
        if (state == VoiceProcessingState.idle) {
          // CORECTAT: Verifică dacă VoiceOrchestrator nu este deja în proces de ascultare sau vorbire
          final voiceOrchestrator = _voiceController!.voiceOrchestrator;
          if (voiceOrchestrator.isAvailable) {
            Logger.info('Auto-starting listening (state: $state)', tag: 'FRIENDSRIDE_VOICE');
            _currentContext = _currentContext.copyWith(
              processingState: VoiceProcessingState.listening,
              lastInteractionTime: DateTime.now(),
            );
            notifyListeners();
            await _voiceController!.listenOnce(localeId: 'ro_RO');
          } else {
            Logger.info('VoiceOrchestrator not available (listening: ${voiceOrchestrator.isListening}, speaking: ${voiceOrchestrator.isSpeaking})', tag: 'FRIENDSRIDE_VOICE');
          }
        }
      } catch (e) {
        Logger.error('Continuous listening error: $e', tag: 'FRIENDSRIDE_VOICE', error: e);
      }
    });
  }

  Future<void> _stopContinuousListening() async {
    _isContinuousListeningActive = false;
    _continuousListeningTimer?.cancel();
    _continuousListeningTimer = null;
  }
  
  // 🎯 Reset-ul sistemului vocal este gestionat de controller-ul vocal
  
    // 📍 Locația curentă și calculul prețului sunt gestionate de controller-ul vocal
  
  // 🔍 Căutarea șoferilor și crearea ride-ului sunt gestionate de controller-ul vocal
  
  // 🎤 Getters pentru UI
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  bool get isVoiceActive => _isVoiceActive;
  bool get isContinuousListeningActive => _isContinuousListeningActive;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String? get voiceDestination => _voiceDestination;
  String? get voicePickup => _voicePickup;
  /// Coordonate deja rezolvate în RideFlow (evită Nominatim dublu în map_screen).
  double? get voiceDestinationLatitude => _voiceController?.voiceDestinationLatitude;
  double? get voiceDestinationLongitude => _voiceController?.voiceDestinationLongitude;
  double? get voicePickupLatitude => _voiceController?.voicePickupLatitude;
  double? get voicePickupLongitude => _voiceController?.voicePickupLongitude;
  bool get hasNewVoiceDestination => _hasNewVoiceDestination;
  bool get hasNewVoicePickup => _hasNewVoicePickup;

  /// Mark voice events as processed
  void markVoiceEventsProcessed() {
    _hasNewVoiceDestination = false;
    _hasNewVoicePickup = false;
  }

  bool get shouldNavigateToSearching => _shouldNavigateToSearching;
  String? get navigationRideId => _navigationRideId;

  /// Mark navigation event as processed (called by map_screen after pushing the screen).
  void markNavigationToSearchingProcessed() {
    _shouldNavigateToSearching = false;
    _navigationRideId = null;
  }

  /// După închiderea căutării șoferului: sincronizează starea vocală cu harta principală.
  void markReturnedFromDriverSearch() {
    _voiceController?.onClosedDriverSearchSheet();
    markNavigationToSearchingProcessed();
  }

  /// Update booking progress into chat
  void updateBookingProgress(String message) {
    _currentContext = _currentContext.copyWith(
      conversationHistory: [..._currentContext.conversationHistory, 'AI: $message'],
      lastInteractionTime: DateTime.now(),
    );
    notifyListeners();
  }
  
  /// 🎯 Obține contextul curent
  VoiceConversationContext get currentContext => _currentContext;
  
  /// 🚗 Obține ride request-ul curent
  RideRequest? get currentRideRequest => _currentRideRequest;
  
  /// 🚗 Obține ride offer-ul curent
  RideOffer? get currentRideOffer => _currentRideOffer;
  
  /// 🚗 Obține ride-ul curent
  Ride? get currentRide => _currentRide;
  
  /// 🚗 Gestionează cererea de cursă
  Future<void> handleRideRequest(Map<String, dynamic> rideData) async {
    try {
      Logger.info('Handling ride request...', tag: 'FRIENDSRIDE_VOICE');
      
      if (_voiceController != null) {
        await _voiceController!.processVoiceInput('confirm ride request');
      }
      
      // Actualizează contextul
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.listeningForInitialCommand,
        lastInteractionTime: DateTime.now(),
      );
      notifyListeners();
      
    } catch (e) {
      Logger.error('Ride request error: $e', tag: 'FRIENDSRIDE_VOICE', error: e);
      _handleError(e.toString());
    }
  }
  
  /// 📍 Procesează comanda de locație
  Future<void> processLocationCommand(String locationCommand) async {
    try {
      Logger.info('Processing location command: $locationCommand', tag: 'FRIENDSRIDE_VOICE');
      
      if (_voiceController != null) {
        await _voiceController!.processVoiceInput(locationCommand);
      }
      
      // Actualizează contextul
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.listeningForInitialCommand,
        lastInteractionTime: DateTime.now(),
      );
      notifyListeners();
      
    } catch (e) {
      Logger.error('Location command error: $e', tag: 'FRIENDSRIDE_VOICE', error: e);
      _handleError(e.toString());
    }
  }
  
  /// 🔄 Execută fluxul complet de cursă
  Future<void> executeRideFlow() async {
    try {
      Logger.info('Executing ride flow...', tag: 'FRIENDSRIDE_VOICE');
      
      if (_voiceController != null) {
        await _voiceController!.processVoiceInput('execute ride flow');
      }
      
      // Actualizează contextul
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.listeningForInitialCommand,
        lastInteractionTime: DateTime.now(),
      );
      notifyListeners();
      
    } catch (e) {
      Logger.error('Ride flow execution error: $e', tag: 'FRIENDSRIDE_VOICE', error: e);
      _handleError(e.toString());
    }
  }

  /// 🧹 Cleanup
  @override
  void dispose() {
    _syncTimer?.cancel();
    _continuousListeningTimer?.cancel();
    // VoiceOrchestrator-ul este gestionat de controller-ul vocal
    _voiceController?.dispose();
    // TTS-ul este gestionat de controller-ul vocal
    super.dispose();
  }
}

/// 🎯 Provider pentru FriendsRide Voice Integration
class FriendsRideVoiceIntegrationProvider extends ChangeNotifierProvider<FriendsRideVoiceIntegration> {
  FriendsRideVoiceIntegrationProvider({
    super.key,
    super.child,
  }) : super(
    create: (context) => FriendsRideVoiceIntegration(),
  );
  
  }
