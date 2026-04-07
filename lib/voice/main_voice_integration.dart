import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/firestore_service.dart';
import 'ai/gemini_voice_engine.dart';
import 'tts/natural_voice_synthesizer.dart' as tts;
import 'ride/ride_flow_manager.dart';
import 'states/voice_interaction_states.dart';
import 'core/voice_orchestrator.dart';
import 'package:nabour_app/utils/logger.dart';

/// ✅ Helper: Obține limba curentă din SharedPreferences
Future<String> _getCurrentLanguageCode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale');
    return code ?? 'ro'; // Default română
  } catch (e) {
    Logger.error('Error getting language: $e', tag: 'MAIN_VOICE', error: e);
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

/// 🎯 Main Voice Integration - Conectează toate componentele vocale
/// 
/// Caracteristici:
/// - Integrare completă cu Nabour
/// - Management centralizat al stărilor
/// - Provider pattern pentru state management
/// - Lifecycle management perfect
class MainVoiceIntegration extends ChangeNotifier {
  // 🧠 Componentele principale
  late final GeminiVoiceEngine _geminiEngine;
  late final tts.NaturalVoiceSynthesizer _naturalTts;
  late final RideFlowManager _rideFlowManager;
  late final VoiceOrchestrator _voiceOrchestrator;
  
  // 🎯 Starea curentă
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
  
  /// 🚀 Constructor
  MainVoiceIntegration() {
    _initializeComponents();
  }
  
  /// 🚀 Inițializează toate componentele
  Future<void> _initializeComponents() async {
    if (_isInitializing || _isInitialized) return;
    
    try {
      _isInitializing = true;
      Logger.info('Initializing components...', tag: 'MAIN_VOICE');
      
      // 🎤 PRIMUL: Inițializez Voice Orchestrator
      _voiceOrchestrator = VoiceOrchestrator();
      await _voiceOrchestrator.initialize();
      Logger.info('VoiceOrchestrator initialized', tag: 'MAIN_VOICE');
      
      // 🧠 AL DOILEA: Inițializez Gemini Engine
      _geminiEngine = GeminiVoiceEngine();
      Logger.info('Gemini engine created', tag: 'MAIN_VOICE');
      
      // 🗣️ AL TREILEA: Inițializez TTS natural
      _naturalTts = tts.NaturalVoiceSynthesizer();
      await _naturalTts.initialize();
      Logger.info('TTS initialized', tag: 'MAIN_VOICE');
      
      // 🚗 AL PATRULEA: Acum pot inițializa RideFlowManager cu toate dependințele
      _rideFlowManager = RideFlowManager(
        geminiEngine: _geminiEngine,
        tts: _naturalTts,
        firestoreService: FirestoreService(),
        voiceOrchestrator: _voiceOrchestrator,
        
        // ✅ Callback-uri pentru acțiuni în UI
        onFillAddressInUI: (pickup, destination, {pickupLat, pickupLng, destLat, destLng}) {
          Logger.info('Filling address: $pickup → $destination', tag: 'MAIN_VOICE');
          if (destLat != null && destLng != null) {
            Logger.info('Destination coordinates received: $destLat, $destLng', tag: 'MAIN_VOICE');
          }
        },
        onSelectRideOptionInUI: (category) {
          Logger.info('Selecting ride option: $category', tag: 'MAIN_VOICE');
        },
        onPressConfirmButtonInUI: () {
          Logger.info('Pressing confirm button', tag: 'MAIN_VOICE');
        },
        onNavigateToScreen: (screen) {
          Logger.info('Navigating to screen: ${screen.runtimeType}', tag: 'MAIN_VOICE');
        },
        onCreateRideRequest: (rideRequest) async {
          Logger.info('Creating ride request', tag: 'MAIN_VOICE');
          return 'ride_${DateTime.now().millisecondsSinceEpoch}';
        },
        onDriverResponse: (driverId, accepted) {
          Logger.info('Driver response: $driverId, accepted: $accepted', tag: 'MAIN_VOICE');
        },
        onCloseAI: () {
          Logger.info('Closing AI', tag: 'MAIN_VOICE');
        },
      );
      await _rideFlowManager.initialize();
      Logger.info('RideFlowManager initialized', tag: 'MAIN_VOICE');
      
      // 🎯 În final: Setez callback-urile
      _setupCallbacks();
      
      _isInitialized = true;
      _isInitializing = false;
      
      Logger.info('All components initialized successfully', tag: 'MAIN_VOICE');
      
    } catch (e) {
      Logger.error('Initialization error: $e', tag: 'MAIN_VOICE', error: e);
      _isInitializing = false;
      _isInitialized = false;
    }
  }
  
  /// 🎯 Setez callback-urile pentru toate componentele
  void _setupCallbacks() {
    // 🎤 Voice Orchestrator callbacks
    _voiceOrchestrator.setSpeechResultCallback(_handleSpeechResult);
    _voiceOrchestrator.setSpeechErrorCallback(_handleSpeechError);
    _voiceOrchestrator.setStateChangeCallback(_handleStateChange);
  }
  
  /// 🎤 Gestionează rezultatul speech recognition
  void _handleSpeechResult(String result) {
    Logger.info('Speech result: "$result"', tag: 'MAIN_VOICE');
    
    // 📝 Actualizez contextul
    _updateContextWithSpeechResult(result);
    
    // 🚀 Procesez cu Ride Flow Manager
    _processVoiceInput(result);
    
    notifyListeners();
  }
  
  /// 🎤 Gestionează erorile speech recognition
  void _handleSpeechError(String error) {
    Logger.error('Speech error: $error', tag: 'MAIN_VOICE', error: error);
    
    // 📝 Actualizez contextul cu eroarea
    _currentContext = _currentContext.copyWith(
      processingState: VoiceProcessingState.error,
      lastInteractionTime: DateTime.now(),
    );
    
    notifyListeners();
  }
  
  /// 🎯 Gestionează schimbările de stare
  void _handleStateChange(VoiceProcessingState newState) {
    Logger.info('State change: $newState', tag: 'MAIN_VOICE');
    
    _currentContext = _currentContext.copyWith(
      processingState: newState,
      lastInteractionTime: DateTime.now(),
    );
    
    notifyListeners();
  }
  
  /// 📝 Actualizează contextul cu rezultatul speech
  void _updateContextWithSpeechResult(String result) {
    final history = List<String>.from(_currentContext.conversationHistory);
    history.add('User: $result');
    
    if (history.length > 20) {
      history.removeAt(0);
    }
    
    _currentContext = _currentContext.copyWith(
      conversationHistory: history,
      lastInteractionTime: DateTime.now(),
    );
  }
  
  /// 🚀 Procesează input-ul vocal
  Future<void> _processVoiceInput(String userInput) async {
    try {
      Logger.info('Processing voice input: "$userInput"', tag: 'MAIN_VOICE');
      
      // 🚀 Procesez cu Ride Flow Manager
      await _rideFlowManager.processVoiceInput(userInput);
      
      // 📝 Actualizez contextul cu noua stare
      _updateContextFromRideFlow();
      
      Logger.info('Voice input processed successfully', tag: 'MAIN_VOICE');
      
    } catch (e) {
      Logger.error('Voice input processing error: $e', tag: 'MAIN_VOICE', error: e);
      _handleError(e.toString());
    }
  }
  
  /// 📝 Actualizează contextul din Ride Flow Manager
  void _updateContextFromRideFlow() {
    _currentContext = _currentContext.copyWith(
      rideState: _rideFlowManager.currentState,
      currentDestination: _rideFlowManager.destination,
      currentPickup: _rideFlowManager.pickup,
      estimatedPrice: _rideFlowManager.estimatedPrice,
      availableDrivers: _rideFlowManager.availableDrivers,
      lastInteractionTime: DateTime.now(),
    );
  }
  
  /// 🎯 Gestionează erorile
  void _handleError(String error) {
    Logger.error('Error: $error', tag: 'MAIN_VOICE', error: error);
    
    _currentContext = _currentContext.copyWith(
      rideState: RideFlowState.error,
      processingState: VoiceProcessingState.error,
      lastInteractionTime: DateTime.now(),
    );
    
    notifyListeners();
  }
  
  /// 🎤 Începe interacțiunea vocală
  Future<void> startVoiceInteraction() async {
    if (!_isInitialized) {
      await _initializeComponents();
    }
    
    try {
      Logger.info('Starting voice interaction...', tag: 'MAIN_VOICE');
      
      // ✅ NOU: Obțin limba curentă și o setez în toate componentele
      final languageCode = await _getCurrentLanguageCode();
      final localeId = _languageCodeToLocaleId(languageCode);
      
      // ✅ NOU: Setez limba în TTS
      await _naturalTts.setLanguage(languageCode);
      
      // ✅ NOU: Obțin mesajul de salut în limba corectă (va fi înlocuit cu l10n mai târziu)
      final greetingMessage = languageCode == 'en' 
          ? 'Hello, where would you like to go?'
          : 'Salut, unde doriți să mergeți?';
      
      // 🗣️ Salut utilizatorul
      await _naturalTts.speakWithEmotion(
        greetingMessage,
        VoiceEmotion.friendly,
      );
      
      // 🎤 Actualizez contextul
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.listeningForInitialCommand,
        processingState: VoiceProcessingState.listening,
        currentEmotion: VoiceEmotion.friendly,
        lastInteractionTime: DateTime.now(),
      );
      
      // 🎧 După salut: fereastră scurtă pentru adresă + beep de „ascult”
      await _voiceOrchestrator.listen(
        localeId: localeId,
        timeoutSeconds: VoiceOrchestrator.initialAddressListenSeconds,
        pauseForSeconds: VoiceOrchestrator.initialAddressPauseForSeconds,
      );
      
      notifyListeners();
      
    } catch (e) {
      Logger.error('Start voice interaction error: $e', tag: 'MAIN_VOICE', error: e);
      _handleError(e.toString());
    }
  }
  
  /// 🛑 Oprește interacțiunea vocală
  Future<void> stopVoiceInteraction() async {
    try {
      Logger.info('Stopping voice interaction...', tag: 'MAIN_VOICE');
      
      // Verifică dacă componentele sunt inițializate înainte să le oprești
      if (_isInitialized) {
        await _voiceOrchestrator.stop();
        await _rideFlowManager.stop();
      }
      
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.idle,
        processingState: VoiceProcessingState.idle,
        lastInteractionTime: DateTime.now(),
      );
      
      notifyListeners();
      
    } catch (e) {
      Logger.error('Stop voice interaction error: $e', tag: 'MAIN_VOICE', error: e);
      // În caz de eroare, forțează resetarea
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.idle,
        processingState: VoiceProcessingState.idle,
        lastInteractionTime: DateTime.now(),
      );
      notifyListeners();
    }
  }
  
  /// 🎤 Verifică dacă e inițializat
  bool get isInitialized => _isInitialized;
  
  /// 🎤 Verifică dacă e în curs de inițializare
  bool get isInitializing => _isInitializing;
  
  /// 🎯 Obține contextul curent
  VoiceConversationContext get currentContext => _currentContext;
  
  /// 🚗 Obține Ride Flow Manager
  RideFlowManager get rideFlowManager => _rideFlowManager;
  
  /// 🎤 Obține Voice Orchestrator
  VoiceOrchestrator get voiceOrchestrator => _voiceOrchestrator;
  
  /// 🗣️ Obține Natural TTS
  tts.NaturalVoiceSynthesizer get naturalTts => _naturalTts;
  
  /// 🧠 Obține Gemini Engine
  GeminiVoiceEngine get geminiEngine => _geminiEngine;
  
  /// 🧹 Cleanup
  @override
  void dispose() {
    _voiceOrchestrator.dispose();
    _rideFlowManager.dispose();
    _naturalTts.dispose();
    super.dispose();
  }
}

/// 🎯 Provider pentru Main Voice Integration
class MainVoiceIntegrationProvider extends ChangeNotifierProvider<MainVoiceIntegration> {
  MainVoiceIntegrationProvider({
    super.key,
    required super.child,
  }) : super(
    create: (context) => MainVoiceIntegration(),
  );
}
