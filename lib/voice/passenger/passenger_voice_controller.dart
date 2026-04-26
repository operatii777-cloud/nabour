import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ride/ride_flow_manager.dart';
import '../ai/gemini_voice_engine.dart';
import '../tts/natural_voice_synthesizer.dart' as tts;
import '../core/voice_orchestrator.dart';
import '../states/voice_interaction_states.dart';
import '../advanced/advanced_voice_processor.dart';
import '../../services/firestore_service.dart';
import '../../models/ride_model.dart';
import '../../models/voice_models.dart';
import '../../widgets/address_confirmation_screen.dart';
import '../../screens/searching_for_driver_screen.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/services/pax_allowed_drv_uids.dart';
import 'package:nabour_app/services/passenger_ride_session_bus.dart';
import '../testing/nabour_ghost_orchestrator.dart';

/// ✅ Helper: Obține limba curentă din SharedPreferences
Future<String> _getCurrentLanguageCode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale');
    return code ?? 'ro'; // Default română
  } catch (e) {
    Logger.error('Error getting language: $e', tag: 'VOICE_CONTROLLER', error: e);
    return 'ro'; // Default română
  }
}

/// ✅ Helper: Convertește languageCode la localeId pentru Speech Recognition
String _languageCodeToLocaleId(String languageCode) {
  switch (languageCode) {
    case 'en':
      return 'en_US';
    case 'ro':
    default:
      return 'ro_RO';
  }
}

/// 🎯 Controller-ul pentru vocea pasagerului - implementează callback-urile AI-ului
class PassengerVoiceController extends ChangeNotifier {
  late RideFlowManager _rideFlowManager;
  late GeminiVoiceEngine _geminiEngine;
  late tts.NaturalVoiceSynthesizer _tts;
  late VoiceOrchestrator _voiceOrchestrator;
  final FirestoreService _firestoreService;
  VoiceProcessingState _processingState = VoiceProcessingState.idle;
  bool _isInitialized = false;
  
  // ✅ Stări pentru UI - controller-ul gestionează starea
  String? _pickupAddressForUI;
  String? _destinationAddressForUI;
  /// Ultimele coordonate primite din RideFlow (evită geocoding dublu în map_screen).
  double? _voicePickupLat;
  double? _voicePickupLng;
  double? _voiceDestLat;
  double? _voiceDestLng;
  RideCategory? _selectedCategoryForUI;
  bool _showRideConfirmation = false;
  bool _showSearchingDriver = false;
  String? _currentRideId;
  final AdvancedVoiceProcessor _advancedVoiceProcessor = AdvancedVoiceProcessor();
  StreamSubscription<WakeWordEvent>? _wakeWordSubscription;
  bool _wakeWordEnabled = false;
  bool _continuousListeningEnabled = false;

  // 🔢 Failure tracking for voice fallback UI
  int _consecutiveVoiceFailures = 0;
  static const int _voiceFailureThreshold = 2;

  // 🔗 Callbacks catre panelul de adrese din UI (setate din map_screen)
  Function(String pickup, String dest, {double? pickupLat, double? pickupLng, double? destLat, double? destLng})? _uiAddressCallback;
  VoidCallback? _uiConfirmCallback;

  /// Conecteaza asistentul vocal la widgeturile reale din UI.
  /// Apelat din map_screen dupa ce panelul de adrese este montat.
  void setRidePanelCallbacks({
    required Function(String pickup, String dest, {double? pickupLat, double? pickupLng, double? destLat, double? destLng}) onFillAddress,
    required VoidCallback onConfirm,
  }) {
    _uiAddressCallback = onFillAddress;
    _uiConfirmCallback = onConfirm;
    Logger.info('RidePanel callbacks connected', tag: 'VOICE_CONTROLLER');
  }

  // ✅ Getters pentru UI
  String? get pickupAddressForUI => _pickupAddressForUI;
  String? get destinationAddressForUI => _destinationAddressForUI;
  double? get voicePickupLatitude => _voicePickupLat;
  double? get voicePickupLongitude => _voicePickupLng;
  double? get voiceDestinationLatitude => _voiceDestLat;
  double? get voiceDestinationLongitude => _voiceDestLng;
  RideCategory? get selectedCategoryForUI => _selectedCategoryForUI;
  bool get showRideConfirmation => _showRideConfirmation;
  bool get showSearchingDriver => _showSearchingDriver;
  String? get currentRideId => _currentRideId;
  bool get wakeWordEnabled => _wakeWordEnabled;
  bool get continuousListeningEnabled => _continuousListeningEnabled;

  /// Whether to show the voice fallback UI (manual input card).
  bool get showVoiceFallback => _consecutiveVoiceFailures >= _voiceFailureThreshold;

  /// Current consecutive voice failure count (exposed for testing).
  int get consecutiveVoiceFailures => _consecutiveVoiceFailures;
  RideFlowState get rideState => _rideFlowManager.currentState;
  String get lastAiMessage => _rideFlowManager.lastSpokenMessage;
  List<String> get availableDrivers => _rideFlowManager.availableDrivers;
  bool get isInitialized => _isInitialized;

  PassengerVoiceController({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  /// 🚀 Inițializează controller-ul
  Future<void> initialize() async {
    if (_isInitialized) {
      Logger.info('Already initialized, skipping.', tag: 'VOICE_CONTROLLER');
      return;
    }
    try {
      Logger.debug('Initializing...', tag: 'VOICE_CONTROLLER');
      
      // ✅ Inițializează serviciile
      _geminiEngine = GeminiVoiceEngine();
      _voiceOrchestrator = VoiceOrchestrator();
      
      // ✅ FIX: Initialize orchestrator first so its shared NaturalVoiceSynthesizer
      // is created, then reuse that same instance for _tts. This ensures
      // VoiceOrchestrator can always observe the TTS speaking state.
      await _voiceOrchestrator.initialize();
      _tts = _voiceOrchestrator.naturalTts;

      // ✅ NOU: Inițializează orchestratorul fantomă pentru testare autonomă
      NabourGhostOrchestrator().initialize(this);

      // Wire STT callbacks to route results into the AI flow and reflect state to UI
      _voiceOrchestrator.setSpeechResultCallback((result) async {
        // Reset failure counter on successful recognition.
        if (result.trim().isNotEmpty) {
          _consecutiveVoiceFailures = 0;
        }
        final normalized = _normalizeUtterance(result);
        await processVoiceInput(normalized);
      });
      _voiceOrchestrator.setSpeechErrorCallback((error) {
        _consecutiveVoiceFailures++;
        notifyListeners();
      });
      _voiceOrchestrator.setFailureThresholdCallback((count) {
        Logger.warning('Voice failure threshold reached: $count', tag: 'VOICE_CONTROLLER');
        // showVoiceFallback getter already derives from _consecutiveVoiceFailures.
        notifyListeners();
      });
      _voiceOrchestrator.setStateChangeCallback((state) {
        _processingState = state;
        notifyListeners();
      });
      
      // ✅ Inițializează RideFlowManager cu callback-urile implementate
      _rideFlowManager = RideFlowManager(
        geminiEngine: _geminiEngine,
        tts: _tts,
        firestoreService: _firestoreService,
        voiceOrchestrator: _voiceOrchestrator,
        
        // ✅ Callback-uri implementate pentru acțiuni în UI
        onFillAddressInUI: (pickup, destination, {pickupLat, pickupLng, destLat, destLng}) {
          Logger.debug('Filling address in UI: $pickup → $destination', tag: 'VOICE_CONTROLLER');
          _pickupAddressForUI = pickup;
          _destinationAddressForUI = destination;
          _voicePickupLat = pickupLat;
          _voicePickupLng = pickupLng;
          _voiceDestLat = destLat;
          _voiceDestLng = destLng;
          // Forwardeaza catre panelul real de adrese (conectat din map_screen)
          _uiAddressCallback?.call(
            pickup, destination,
            pickupLat: pickupLat, pickupLng: pickupLng,
            destLat: destLat, destLng: destLng,
          );
          notifyListeners();
        },

        onSelectRideOptionInUI: (category) {
          Logger.debug('Selecting ride option: $category', tag: 'VOICE_CONTROLLER');
          _selectedCategoryForUI = category;
          _showRideConfirmation = true;
          notifyListeners();
        },

        onPressConfirmButtonInUI: () {
          Logger.debug('Pressing confirm button', tag: 'VOICE_CONTROLLER');
          _showRideConfirmation = false;
          _showSearchingDriver = true;
          // Apasa efectiv butonul Confirma din panelul de adrese
          _uiConfirmCallback?.call();
          notifyListeners();
        },
        
        onNavigateToScreen: (screen) {
          Logger.debug('Navigating to screen: ${screen.runtimeType}', tag: 'VOICE_CONTROLLER');
          // ✅ Folosește navigator-ul global pentru navigare
          _navigateToScreen(screen);
        },
        
        onCreateRideRequest: (rideRequest) async {
          Logger.debug('Creating ride request in Firebase', tag: 'VOICE_CONTROLLER');
          // ✅ ÎMBUNĂTĂȚIT: Creează efectiv solicitarea în Firebase cu validări complete
          // Convertim Map<String, dynamic> la RideRequest
          
          // ✅ FIX: Obține user ID real dacă lipsește
          final passengerId = rideRequest['passengerId'] as String?;
          if (passengerId == null || passengerId.isEmpty) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId == null) {
              throw Exception('Utilizatorul nu este autentificat.');
            }
            rideRequest['passengerId'] = currentUserId;
          }
          
          // ✅ FIX: Validează că avem toate datele necesare
          final pickup = rideRequest['pickup'] as String?;
          final destination = rideRequest['destination'] as String?;
          if (pickup == null || pickup.isEmpty || destination == null || destination.isEmpty) {
            throw Exception('Adresele pickup sau destinație lipsesc.');
          }
          
          // ✅ FIX: Extrage coordonatele (sunt necesare pentru validare)
          final startLat = (rideRequest['startLatitude'] as num?)?.toDouble();
          final startLng = (rideRequest['startLongitude'] as num?)?.toDouble();
          final destLat = (rideRequest['destinationLatitude'] as num?)?.toDouble();
          final destLng = (rideRequest['destinationLongitude'] as num?)?.toDouble();

          List<String> allowedDriverUids;
          final rawAllowed = rideRequest['allowedDriverUids'];
          if (rawAllowed is List && rawAllowed.isNotEmpty) {
            allowedDriverUids = rawAllowed.map((e) => e.toString()).toList();
          } else {
            allowedDriverUids = await PassengerAllowedDriverUids.loadMergedUidList();
          }
          if (allowedDriverUids.isEmpty) {
            throw Exception(
              'Nabour trimite cererea doar către șoferii din contactele tale. '
              'Adaugă în agendă numerele prietenilor cu cont Nabour sau acordă permisiunea la contacte.',
            );
          }
          
          final rideRequestObj = RideRequest(
            id: rideRequest['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            passengerId: rideRequest['passengerId'] as String,
            pickupLocation: rideRequest['pickup'] as String? ?? rideRequest['startAddress'] as String? ?? '',
            destination: rideRequest['destination'] as String? ?? rideRequest['destinationAddress'] as String? ?? '',
            estimatedPrice: (rideRequest['estimatedPrice'] as num?)?.toDouble() ?? 
                           (rideRequest['totalCost'] as num?)?.toDouble() ?? 0.0,
            category: rideRequest['category'] as String? ?? 'standard',
            urgency: rideRequest['urgency'] as String? ?? 'normal',
            timestamp: DateTime.now(),
            status: rideRequest['status'] as String? ?? 'pending',
            // ✅ FIX: Adaugă coordonatele dacă există
            pickupLatitude: startLat,
            pickupLongitude: startLng,
            destinationLatitude: destLat,
            destinationLongitude: destLng,
            allowedDriverUids: allowedDriverUids,
          );
          
          try {
            final rideId = await _firestoreService.createRideRequest(rideRequestObj);
            _currentRideId = rideId;
            notifyListeners();
            return rideId;
          } on ActiveRideException catch (e) {
            // Cursa a fost deja creată (race cu _autoProgressToBooking) — folosim rideId-ul existent
            Logger.warning('Active ride exists: ${e.activeRideId}, using it', tag: 'VOICE_CONTROLLER');
            _currentRideId = e.activeRideId;
            _showSearchingDriver = true;
            notifyListeners();
            return e.activeRideId;
          }
        },
        
        onDriverResponse: (driverId, accepted) {
          Logger.debug('Driver response: $driverId, accepted: $accepted', tag: 'VOICE_CONTROLLER');
          if (accepted) {
            _showSearchingDriver = false;
            _signalPassengerRideSessionOnMap();
          }
          // Refuzul și passengerDeclineDriver sunt gestionate în RideFlowManager (fără dublu apel).
          notifyListeners();
        },
        
        onCloseAI: () {
          Logger.debug('Closing AI', tag: 'VOICE_CONTROLLER');
          // ✅ Închide AI-ul și resetează stările
          _resetVoiceStates();
          notifyListeners();
        },
        
        onAppAction: (action, screen, params) {
          Logger.debug('AI requested generic App Action: $action on screen: $screen', tag: 'VOICE_CONTROLLER');
          // Dispatch to anyone interested via the registry or local logic
          // (MainVoiceIntegration usually handles this, but we bridge it here if needed)
        },
      );
      
      await _rideFlowManager.initialize();
      
      Logger.info('Initialized successfully', tag: 'VOICE_CONTROLLER');
      _isInitialized = true;
    } catch (e) {
      Logger.error('Initialization error: $e', tag: 'VOICE_CONTROLLER', error: e);
      rethrow;
    }
  }

  // Normalize utterances like: remove surrounding quotes and trim whitespace
  String _normalizeUtterance(String text) {
    String t = text.trim();
    t = t.replaceAll(RegExp(r'^["“”]+'), '');
    t = t.replaceAll(RegExp(r'["“”]+$'), '');
    return t.trim();
  }

  /// 🎤 Procesează input-ul vocal
  Future<void> processVoiceInput(String userInput) async {
    try {
      Logger.debug('Processing voice input: $userInput', tag: 'VOICE_CONTROLLER');
      _processingState = VoiceProcessingState.thinking;
      notifyListeners();
      await _rideFlowManager.processVoiceInput(userInput);
    } catch (e) {
      Logger.error('Voice processing error: $e', tag: 'VOICE_CONTROLLER', error: e);
      _processingState = VoiceProcessingState.idle;
      notifyListeners();
    } finally {
      // Dacă orchestratorul nu a trecut deja la speaking/listening (TTS/STT), ieșim din thinking.
      scheduleMicrotask(() {
        if (_processingState != VoiceProcessingState.thinking) return;
        if (_voiceOrchestrator.isSpeaking ||
            _voiceOrchestrator.isListening ||
            _voiceOrchestrator.isTtsSpeaking ||
            _voiceOrchestrator.isSpeakThenListenInProgress) {
          return;
        }
        _processingState = VoiceProcessingState.idle;
        notifyListeners();
      });
    }
  }

  /// 🎤 Pornește conversația cu salut + continuous listening
  Future<void> startContinuousConversation() async {
    try {
      // Salut
      const greeting = 'Salut, unde doriți să mergeți?';
      await _voiceOrchestrator.speak(greeting, emotion: VoiceEmotion.friendly);
      // Adaugă la istoric pentru UI
      _rideFlowManager.addAiMessage(greeting);
      notifyListeners();
      // ✅ NOU: Obțin limba curentă și o folosesc
      final languageCode = await _getCurrentLanguageCode();
      final localeId = _languageCodeToLocaleId(languageCode);
      await _tts.setLanguage(languageCode);
      
      // După salut: beep + ascultare scurtă (apoi procesare), fără așteptare 30s
      await _voiceOrchestrator.listen(
        timeoutSeconds: VoiceOrchestrator.initialAddressListenSeconds,
        pauseForSeconds: VoiceOrchestrator.initialAddressPauseForSeconds,
        localeId: localeId,
      );
    } catch (e) {
      Logger.warning('PassengerVoiceController: greet+listen failed: $e', tag: 'VOICE');
    }
  }

  /// Start a single listening session (used by integration loop)
  Future<void> listenOnce({int? timeoutSeconds, int? pauseForSeconds, String? localeId}) async {
    final finalLocaleId = localeId ?? _languageCodeToLocaleId(await _getCurrentLanguageCode());
    await _voiceOrchestrator.listen(
      timeoutSeconds: timeoutSeconds,
      pauseForSeconds: pauseForSeconds,
      localeId: finalLocaleId,
    );
  }

  Future<void> enableWakeWordDetection() async {
    if (_wakeWordEnabled) return;
    final initialized = await _advancedVoiceProcessor.initialize();
    if (!initialized) {
      Logger.error('Wake word initialization failed', tag: 'VOICE_CONTROLLER');
      return;
    }
    _wakeWordSubscription ??= _advancedVoiceProcessor.wakeWordEvents.listen(_handleWakeWordDetected);
    await _advancedVoiceProcessor.startWakeWordDetection();
    _wakeWordEnabled = true;
    notifyListeners();
  }

  Future<void> disableWakeWordDetection() async {
    if (!_wakeWordEnabled) return;
    await _advancedVoiceProcessor.stopListening();
    await _wakeWordSubscription?.cancel();
    _wakeWordSubscription = null;
    _wakeWordEnabled = false;
    notifyListeners();
  }

  Future<void> toggleWakeWordDetection() async {
    if (_wakeWordEnabled) {
      await disableWakeWordDetection();
    } else {
      await enableWakeWordDetection();
    }
  }

  Future<void> enableContinuousListening() async {
    if (_continuousListeningEnabled) return;
    _continuousListeningEnabled = true;
    notifyListeners();
    unawaited(_startContinuousListeningLoop());
  }

  Future<void> disableContinuousListening() async {
    if (!_continuousListeningEnabled) return;
    _continuousListeningEnabled = false;
    await _voiceOrchestrator.stopListening();
    notifyListeners();
  }

  Future<void> toggleContinuousListening() async {
    if (_continuousListeningEnabled) {
      await disableContinuousListening();
    } else {
      await enableContinuousListening();
    }
  }

  Future<void> _handleWakeWordDetected(WakeWordEvent event) async {
    Logger.debug('Wake word detected: ${event.text}', tag: 'VOICE_CONTROLLER');
    if (!_wakeWordEnabled) return;
    await _voiceOrchestrator.stopListening();
    
    // ✅ NOU: Obțin limba curentă și o folosesc
    final languageCode = await _getCurrentLanguageCode();
    final localeId = _languageCodeToLocaleId(languageCode);
    await _tts.setLanguage(languageCode);
    
    final responseMessage = languageCode == 'en' ? 'Yes, I\'m listening.' : 'Da, vă ascult.';
    await _voiceOrchestrator.speak(responseMessage, emotion: VoiceEmotion.friendly);
    await _voiceOrchestrator.listen(
      timeoutSeconds: 20,
      localeId: localeId,
    );
    if (_wakeWordEnabled) {
      await _advancedVoiceProcessor.startWakeWordDetection();
    }
  }

  Future<void> _startContinuousListeningLoop() async {
    if (!_continuousListeningEnabled) return;
    // RideFlow pornește STT dedicat (ex. confirmare șofer) — nu intercepta cu încă un listen.
    final rs = _rideFlowManager.currentState;
    if (rs == RideFlowState.awaitingDriverAcceptance || rs == RideFlowState.driverFound) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_continuousListeningEnabled) {
        await _startContinuousListeningLoop();
      }
      return;
    }
    // Nu suprapune tura TTS→STT atomică din RideFlow ([speakThenListen] serializat).
    if (_voiceOrchestrator.isSpeakThenListenInProgress) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (_continuousListeningEnabled) {
        await _startContinuousListeningLoop();
      }
      return;
    }
    // Procesare NLU/LLM sau redare: așteaptă (altfel două sesiuni STT).
    if (_processingState == VoiceProcessingState.thinking ||
        _processingState == VoiceProcessingState.speaking) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (_continuousListeningEnabled) {
        await _startContinuousListeningLoop();
      }
      return;
    }
    // Don't start a new STT session while TTS is still speaking.
    if (_voiceOrchestrator.isTtsSpeaking) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (_continuousListeningEnabled) {
        await _startContinuousListeningLoop();
      }
      return;
    }
    if (_voiceOrchestrator.isListening || _processingState == VoiceProcessingState.listening) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_continuousListeningEnabled) {
        await _startContinuousListeningLoop();
      }
      return;
    }
    // ✅ NOU: Obțin limba curentă și o folosesc
    final languageCode = await _getCurrentLanguageCode();
    final localeId = _languageCodeToLocaleId(languageCode);
    await _tts.setLanguage(languageCode);
    
    await _voiceOrchestrator.listen(localeId: localeId);
    if (_continuousListeningEnabled) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _startContinuousListeningLoop();
    }
  }

  /// 🎯 Gestionează confirmarea adreselor din UI
  Future<void> handleAddressConfirmation() async {
    try {
      Logger.debug('Handling address confirmation from UI', tag: 'VOICE_CONTROLLER');
      await _rideFlowManager.handleAddressConfirmation();
    } catch (e) {
      Logger.error('Address confirmation error: $e', tag: 'VOICE_CONTROLLER', error: e);
    }
  }

  /// 🎤 Getter pentru VoiceOrchestrator (pentru verificări de disponibilitate)
  VoiceOrchestrator get voiceOrchestrator => _voiceOrchestrator;

  /// 🚗 Gestionează confirmarea cursei din UI
  Future<void> handleRideConfirmation() async {
    try {
      Logger.debug('Handling ride confirmation from UI', tag: 'VOICE_CONTROLLER');
      // Aici se va apela logica pentru confirmarea cursei
      _showRideConfirmation = false;
      _showSearchingDriver = true;
      notifyListeners();
    } catch (e) {
      Logger.error('Ride confirmation error: $e', tag: 'VOICE_CONTROLLER', error: e);
    }
  }

  /// 🎯 Navighează la un ecran
  void _navigateToScreen(Widget screen) {
    // ✅ Implementează navigarea prin context sau navigator global
    // Pentru moment, doar actualizează stările
    if (screen is AddressConfirmationScreen) {
      _showRideConfirmation = false;
      notifyListeners();
    } else if (screen is SearchingForDriverScreen) {
      _showSearchingDriver = true;
      notifyListeners();
    }
  }

  /// Nabour: nu există ecran „cursă activă” pentru pasager — doar sesiune pe hartă (overlay + stream).
  void _signalPassengerRideSessionOnMap() {
    final id = _currentRideId;
    if (id == null || id.isEmpty) return;
    PassengerRideServiceBus.emit(PassengerSearchFlowResult(rideId: id));
    notifyListeners();
  }

  /// Apelat când utilizatorul închide ecranul de căutare șofer (hartă revine în prim-plan).
  void onClosedDriverSearchSheet() {
    _showSearchingDriver = false;
    notifyListeners();
  }

  /// 🧹 Resetează stările vocale
  void _resetVoiceStates() {
    _pickupAddressForUI = null;
    _destinationAddressForUI = null;
    _voicePickupLat = null;
    _voicePickupLng = null;
    _voiceDestLat = null;
    _voiceDestLng = null;
    _selectedCategoryForUI = null;
    _showRideConfirmation = false;
    _showSearchingDriver = false;
    _currentRideId = null;
  }

  /// 🔄 Resetează fallback-ul vocal (după ce utilizatorul a trimis input manual)
  void resetVoiceFallback() {
    _consecutiveVoiceFailures = 0;
    _voiceOrchestrator.resetFailureCount();
    notifyListeners();
  }

  /// ✍️ Procesează input-ul manual ca și cum ar fi venit prin voce
  Future<void> handleManualInput(String text) async {
    if (text.trim().isEmpty) return;
    resetVoiceFallback();
    await processVoiceInput(text.trim());
  }

  /// 🎯 Resetează controller-ul
  void reset() {
    _resetVoiceStates();
    notifyListeners();
  }

  /// 🧹 Cleanup
  @override
  void dispose() {
    _wakeWordSubscription?.cancel();
    _wakeWordSubscription = null;
    _advancedVoiceProcessor.stopListening();
    _rideFlowManager.dispose();
    _wakeWordEnabled = false;
    _continuousListeningEnabled = false;
    _resetVoiceStates();
    _isInitialized = false;
    super.dispose();
  }

  // Expose convo history and processing state for UI/overlay
  List<String> get conversationHistory => _rideFlowManager.conversationHistoryCopy;
  VoiceProcessingState get processingState => _processingState;
  double? get estimatedPrice => _rideFlowManager.estimatedPrice;
  double? get estimatedDistanceKm => _rideFlowManager.calculatedDistanceKm;
  double? get estimatedDurationMinutes => _rideFlowManager.calculatedDurationMinutes;
  Map<String, double>? get fareBreakdown => _rideFlowManager.fareBreakdown;
  RideCategory get currentRideCategory => _rideFlowManager.currentRideCategory;
  /// 🚀 Inițializează starea (delegat către initialize)
  Future<void> initState() async {
    await initialize();
  }
  
    /// 🎤 Gestionează comanda vocală (delegat către processVoiceInput)
  Future<void> onVoiceCommand(String command) async {
    await processVoiceInput(command);
  }
  
  }