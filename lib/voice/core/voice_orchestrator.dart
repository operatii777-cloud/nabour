import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../tts/natural_voice_synthesizer.dart' as synthesizer;
import '../states/voice_interaction_states.dart';
import '../../services/audio_beep_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🎤 Voice Orchestrator - Funcționează EXACT ca Gemini Voice
/// 
/// Caracteristici:
/// - STT perfect (Speech-to-Text)
/// - TTS natural (Text-to-Speech)
/// - Integrare perfectă cu Gemini AI
/// - Flow-ul conversației natural
/// - 🚀 SINGLETON: O singură instanță pentru performanță optimă
class VoiceOrchestrator {
  // 🚀 SINGLETON PATTERN - evită inițializări multiple
  static final VoiceOrchestrator _instance = VoiceOrchestrator._internal();
  factory VoiceOrchestrator() => _instance;
  VoiceOrchestrator._internal();

  // 🎤 Lazy-initialized services
  stt.SpeechToText? _speechToText;
  synthesizer.NaturalVoiceSynthesizer? _naturalTts;
  AudioBeepService? _beepService;
  
  stt.SpeechToText get speechToText => _speechToText ??= stt.SpeechToText();
  synthesizer.NaturalVoiceSynthesizer get naturalTts => _naturalTts ??= synthesizer.NaturalVoiceSynthesizer();
  AudioBeepService get beepService => _beepService ??= AudioBeepService();
  
  // Un singur [Future] partajat — apeluri concurente la [initialize] nu mai pornesc STT/TTS de două ori.
  Future<void>? _initializationFuture;

  // 🎯 Starea curentă
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  /// Guards STT from starting while TTS is active (mirrors naturalTts.isSpeaking
  /// but also covers speak() calls routed through the orchestrator itself).
  bool _isTtsSpeaking = false;

  /// Buffer după TTS înainte de a porni STT (evită ecou / captare ultimă silabă).
  static const int postTtsBufferMs = 400;

  // 🔢 Failure tracking for consecutive STT errors / empty results
  int _consecutiveFailures = 0;
  static const int _failureThreshold = 2;
  Function(int)? _onFailureThreshold;
  
  // 🎤 Callback-uri pentru UI
  Function(String)? _onSpeechResult;
  Function(String)? _onSpeechError;
  Function(VoiceProcessingState)? _onStateChange;
  
  // 🎯 NOU: Callback pentru completarea TTS
  Function()? _onTtsCompleted;
  
  // 🎯 NOU: Manager-ul pentru conversația vocală
  VoiceConversationManager? _conversationManager;
  
  /// 🎤 Setez callback-ul pentru rezultatul speech
  void setSpeechResultCallback(Function(String) callback) {
    _onSpeechResult = callback;
  }
  
  /// 🎤 Setez callback-ul pentru erorile speech
  void setSpeechErrorCallback(Function(String) callback) {
    _onSpeechError = callback;
  }
  
  /// 🎤 Setez callback-ul pentru schimbările de stare
  void setStateChangeCallback(Function(VoiceProcessingState) callback) {
    _onStateChange = callback;
  }
  
  /// 🎯 NOU: Setez callback-ul pentru completarea TTS
  void setTtsCompletedCallback(Function() callback) {
    _onTtsCompleted = callback;
  }

  /// Register a callback that fires when consecutive STT failures reach the threshold.
  void setFailureThresholdCallback(Function(int count) callback) {
    _onFailureThreshold = callback;
  }

  /// Reset the consecutive failure counter (e.g. after a successful recognition).
  void resetFailureCount() {
    _consecutiveFailures = 0;
  }
  
  /// 🎯 NOU: Setez manager-ul pentru conversația vocală
  void setConversationManager(VoiceConversationManager manager) {
    _conversationManager = manager;
  }
  
  /// 🗣️ Getter public pentru motorul TTS
  synthesizer.NaturalVoiceSynthesizer get tts => naturalTts;
  
  /// 🚀 Inițializează orchestratorul (o singură dată pentru singleton)
  Future<void> initialize() async {
    if (_isInitialized) return;
    _initializationFuture ??= _initializeBody();
    try {
      await _initializationFuture!;
    } catch (_) {
      _initializationFuture = null;
      rethrow;
    }
  }

  Future<void> _initializeBody() async {
    if (_isInitialized) return;

    try {
      Logger.debug('Initializing (singleton)...', tag: 'VOICE_ORCHESTRATOR');

      final sttAvailable = await speechToText.initialize(
        onError: (error) {
          _onSpeechError?.call(error.errorMsg);
        },
        onStatus: (status) {
          final newState = _getStateFromStatus(status);
          _updateState(newState);

          if (status == 'notListening' || status == 'done' || status == 'error') {
            _isListening = false;
            if (!_isTtsSpeaking) _isSpeaking = false;
          } else if (status == 'listening') {
            _isListening = true;
          }
        },
      );

      if (!sttAvailable) {
        throw Exception('Speech recognition not available');
      }

      await naturalTts.initialize();
      await beepService.initialize();

      _isInitialized = true;
      Logger.info('Initialized (singleton)', tag: 'VOICE_ORCHESTRATOR');
    } catch (e) {
      Logger.error('Initialization error: $e', tag: 'VOICE_ORCHESTRATOR', error: e);
      _isInitialized = false;
      rethrow;
    }
  }
  
  /// 🎧 Ascultă input-ul vocal EXACT ca Gemini Voice
  Future<String?> listen({
    int timeoutSeconds = 15,
    int pauseForSeconds = 5,
    String localeId = 'ro_RO',
    bool partialResults = true,
  }) async {
    if (!_isInitialized) {
      Logger.warning('Not initialized, initializing now...', tag: 'VOICE_ORCHESTRATOR');
      await initialize();
    }
    
    if (_isListening) {
      Logger.warning('Already listening, stopping current session...', tag: 'VOICE_ORCHESTRATOR');
      await stopListening();
    }
    
    if (_isSpeaking) {
      Logger.warning('Currently speaking, stopping speech...', tag: 'VOICE_ORCHESTRATOR');
      await stopSpeaking();
    }
    
    // ✅ TTS-STT sync: Never start STT while TTS is still speaking.
    // Check both the local _isTtsSpeaking flag (set by orchestrator speak calls)
    // and naturalTts.isSpeaking (for direct TTS calls from RideFlowManager).
    if (_isTtsSpeaking || naturalTts.isSpeaking) {
      Logger.warning('TTS still active, waiting for it to finish...', tag: 'VOICE_ORCHESTRATOR');
      while (_isTtsSpeaking || naturalTts.isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Extra buffer so mic doesn't capture tail-end TTS audio as user speech.
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    try {
      _isListening = true;
      _updateState(VoiceProcessingState.listening);
      
      Logger.warning('Starting to listen with timeout: ${timeoutSeconds}s', tag: 'VOICE_ORCHESTRATOR');
      
      // 🔔 BEEP de "acum te ascult" - utilizatorul știe când să vorbească
      await beepService.playListeningStartBeep();
      
      // 🎤 Încep să ascult cu parametrii optimizați
      await speechToText.listen(
        localeId: localeId,
        listenFor: Duration(seconds: timeoutSeconds),
        pauseFor: Duration(seconds: pauseForSeconds),
        // partialResults: partialResults, // ❌ Deprecated
        onResult: (result) {
          if (result.finalResult) {
            Logger.debug('Final result: "${result.recognizedWords}"', tag: 'VOICE_ORCHESTRATOR');

            // Reset failure counter on successful recognition with actual words.
            if (result.recognizedWords.trim().isNotEmpty) {
              _consecutiveFailures = 0;
            } else {
              // Empty final result counts as a failure (e.g. timeout / silence).
              _incrementFailure();
            }
            
            // 🔔🔔 Beep-uri duble când AI procesează informația
            beepService.playProcessingStartBeeps();
            
            _onSpeechResult?.call(result.recognizedWords);
          } else if (partialResults) {
            Logger.debug('Partial: "${result.recognizedWords}"', tag: 'VOICE_ORCHESTRATOR');
          }
        },
      );
      
      // 🎯 Aștept să se termine sesiunea
      while (_isListening) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      Logger.info('Listening session completed', tag: 'VOICE_ORCHESTRATOR');
      return null; // Rezultatul vine prin callback
      
    } catch (e) {
      Logger.error('Listening error: $e', tag: 'VOICE_ORCHESTRATOR', error: e);
      _isListening = false;
      _incrementFailure();
      _updateState(VoiceProcessingState.error);
      _onSpeechError?.call(e.toString());
      return null;
    }
  }
  
  /// 🗣️ Vorbește textul EXACT ca Gemini Voice
  Future<void> speak(String text, {VoiceEmotion emotion = VoiceEmotion.confident}) async {
    if (!_isInitialized) {
      Logger.warning('Not initialized, initializing now...', tag: 'VOICE_ORCHESTRATOR');
      await initialize();
    }
    
    if (_isListening) {
      Logger.warning('Currently listening, stopping...', tag: 'VOICE_ORCHESTRATOR');
      await stopListening();
    }
    
    if (_isSpeaking) {
      Logger.warning('Already speaking, stopping current speech...', tag: 'VOICE_ORCHESTRATOR');
      await stopSpeaking();
    }
    
    try {
      _isSpeaking = true;
      _isTtsSpeaking = true;
      _updateState(VoiceProcessingState.speaking);
      
      Logger.debug('Speaking: "$text"', tag: 'VOICE_ORCHESTRATOR');
      
      // 🗣️ Vorbește cu emoția specificată
      await naturalTts.speakWithEmotion(text, emotion);
      
      _isSpeaking = false;
      _isTtsSpeaking = false;
      _updateState(VoiceProcessingState.idle);
      
      // 🎯 NOU: Notifică că TTS-ul s-a terminat
      _onTtsCompleted?.call();
      
      Logger.info('Speech completed', tag: 'VOICE_ORCHESTRATOR');
      
    } catch (e) {
      Logger.error('Speech error: $e', tag: 'VOICE_ORCHESTRATOR', error: e);
      _isSpeaking = false;
      _isTtsSpeaking = false;
      _updateState(VoiceProcessingState.error);
      _onSpeechError?.call(e.toString());
    }
  }
  
  /// 🗣️ Vorbește textul cu prioritate înaltă
  Future<void> speakPriority(String text) async {
            await speak(text, emotion: VoiceEmotion.urgent);
  }
  
  /// 🗣️ Vorbește textul cu pauze naturale și sincronizare perfectă
  Future<void> speakWithNaturalPauses(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isListening) {
      await stopListening();
    }
    
    if (_isSpeaking) {
      await stopSpeaking();
    }
    
    try {
      _isSpeaking = true;
      _isTtsSpeaking = true;
      _updateState(VoiceProcessingState.speaking);
      
      Logger.debug('Speaking: "$text"', tag: 'VOICE_ORCHESTRATOR');
      
      await naturalTts.speakWithNaturalPauses(text);
      
      _isSpeaking = false;
      _isTtsSpeaking = false;
      _updateState(VoiceProcessingState.idle);
      
      Logger.info('Speech completed, transitioning to listening...', tag: 'VOICE_ORCHESTRATOR');
      
      // 🎯 NOU: Notifică că TTS-ul s-a terminat
      _onTtsCompleted?.call();
      
      // 🔔 Beep după conversația AI - utilizatorul știe că trebuie să răspundă
      beepService.playConversationEndBeep();
      
      // 🎯 AUTOMAT: Pornește ascultarea imediat după ce AI termină de vorbit
      await _startAutomaticListening();
      
    } catch (e) {
      Logger.error('Natural pauses speech error: $e', tag: 'VOICE_ORCHESTRATOR', error: e);
      _isSpeaking = false;
      _isTtsSpeaking = false;
      _updateState(VoiceProcessingState.error);
    }
  }
  
  /// 🗣️ Vorbește apoi pornește ascultarea cu buffer fix (sincronizare TTS → STT).
  Future<void> speakThenListen(
    String text, {
    VoiceEmotion emotion = VoiceEmotion.calm,
    int timeoutSeconds = 30,
    int pauseForSeconds = 10,
    String localeId = 'ro_RO',
  }) async {
    await speak(text, emotion: emotion);
    await Future.delayed(const Duration(milliseconds: postTtsBufferMs));
    await listen(
      timeoutSeconds: timeoutSeconds,
      pauseForSeconds: pauseForSeconds,
      localeId: localeId,
    );
  }

  /// 🛑 Oprește ascultarea
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await speechToText.stop();
        _isListening = false;
        _updateState(VoiceProcessingState.idle);
        Logger.info('Listening stopped', tag: 'VOICE_ORCHESTRATOR');
      }
    } catch (e) {
      Logger.error('Stop listening error: $e', tag: 'VOICE_ORCHESTRATOR', error: e);
    }
  }
  
  /// 🛑 Oprește vorbirea
  Future<void> stopSpeaking() async {
    try {
      if (_isSpeaking) {
        await naturalTts.stop();
        _isSpeaking = false;
        _isTtsSpeaking = false;
        _updateState(VoiceProcessingState.idle);
        Logger.debug('Speech stopped', tag: 'VOICE_ORCHESTRATOR');
      }
    } catch (e) {
      Logger.error('Stop speech error: $e', tag: 'VOICE_ORCHESTRATOR', error: e);
    }
  }
  
  /// 🛑 Oprește tot
  Future<void> stop() async {
    await stopListening();
    await stopSpeaking();
    _updateState(VoiceProcessingState.idle);
  }
  
  /// ⏸️ Pune listening-ul pe pauză temporar (nu oprește complet)
  Future<void> pauseListening() async {
    try {
      if (_isListening) {
        await speechToText.stop();
        Logger.info('Listening paused (temporarily)', tag: 'VOICE_ORCHESTRATOR');
      }
    } catch (e) {
      Logger.error('Pause listening error: $e', tag: 'VOICE_ORCHESTRATOR', error: e);
    }
  }
  
  /// ▶️ Reia listening-ul după pauză
  Future<void> resumeListening({String localeId = 'ro_RO', int timeoutSeconds = 30, int pauseForSeconds = 10}) async {
    try {
      if (!_isListening) {
        _isListening = true;
        _updateState(VoiceProcessingState.listening);
        
        await speechToText.listen(
          localeId: localeId,
          listenFor: Duration(seconds: timeoutSeconds),
          pauseFor: Duration(seconds: pauseForSeconds),
          onResult: (result) {
            if (result.finalResult) {
              Logger.debug('Final result: "${result.recognizedWords}"', tag: 'VOICE_ORCHESTRATOR');
              beepService.playProcessingStartBeeps();
              _onSpeechResult?.call(result.recognizedWords);
            }
          },
        );
        
        Logger.info('Listening resumed', tag: 'VOICE_ORCHESTRATOR');
      }
    } catch (e) {
      Logger.error('Resume listening error: $e', tag: 'VOICE_ORCHESTRATOR', error: e);
      _isListening = false;
      _updateState(VoiceProcessingState.idle);
    }
  }
  

  
  /// 🎯 Actualizează starea și notifică UI-ul
  void _updateState(VoiceProcessingState newState) {
    _onStateChange?.call(newState);
  }

  /// Increments the consecutive failure count and fires the threshold callback
  /// once the count reaches [_failureThreshold].
  void _incrementFailure() {
    _consecutiveFailures++;
    Logger.warning('Consecutive STT failures: $_consecutiveFailures', tag: 'VOICE_ORCHESTRATOR');
    if (_consecutiveFailures >= _failureThreshold) {
      _onFailureThreshold?.call(_consecutiveFailures);
    }
  }
  
  /// 🎯 Convertește status-ul STT în starea noastră
  VoiceProcessingState _getStateFromStatus(String status) {
    switch (status) {
      case 'listening':
        return VoiceProcessingState.listening;
      case 'notListening':
        return VoiceProcessingState.idle;
      case 'done':
        return VoiceProcessingState.idle;
      case 'error':
        return VoiceProcessingState.error;
      default:
        return VoiceProcessingState.idle;
    }
  }
  
  /// 🎯 Verifică dacă e inițializat
  bool get isInitialized => _isInitialized;
  
  /// 🎧 Verifică dacă ascultă
  bool get isListening => _isListening;
  
  /// 🗣️ Verifică dacă vorbește
  bool get isSpeaking => _isSpeaking;

  /// Whether TTS is currently active (guards STT from starting).
  bool get isTtsSpeaking => _isTtsSpeaking || naturalTts.isSpeaking;

  /// Current consecutive STT failure count.
  int get consecutiveFailures => _consecutiveFailures;
  
  /// 🎯 Verifică dacă e disponibil
  bool get isAvailable => _isInitialized && !_isListening && !_isTtsSpeaking && !naturalTts.isSpeaking;
  
  /// 🎯 AUTOMAT: Pornește ascultarea imediat după TTS
  Future<void> _startAutomaticListening() async {
    try {
      Logger.info('Starting automatic listening after TTS...', tag: 'VOICE_ORCHESTRATOR');
      
      // Așteaptă puțin pentru ca utilizatorul să proceseze mesajul
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Verifică dacă nu sunt deja în proces de ascultare
      if (!_isListening && !_isSpeaking) {
        await listen(
          timeoutSeconds: 30,
          pauseForSeconds: 3, // Pauză scurtă pentru detectarea tăcerii
        );
      }
    } catch (e) {
      Logger.error('Auto-listen error: $e', tag: 'VOICE_ORCHESTRATOR', error: e);
    }
  }

  /// 🎯 NOU: Pornește automat ascultarea pentru confirmare
  Future<void> startListeningForConfirmation({
    int timeoutSeconds = 30,
    String localeId = 'ro_RO',
  }) async {
    if (_conversationManager?.currentState == VoiceConversationState.waitingForConfirmation) {
      Logger.info('Starting automatic listening for confirmation...', tag: 'VOICE_ORCHESTRATOR');
      
      // Așteaptă puțin înainte de a porni ascultarea
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Pornește ascultarea
      await listen(
        timeoutSeconds: timeoutSeconds,
        localeId: localeId,
        pauseForSeconds: 10,
      );
    } else {
      Logger.debug('Not in confirmation state, skipping auto-listen', tag: 'VOICE_ORCHESTRATOR');
    }
  }
  
  /// 🎤 Verifică dacă speech recognition-ul e disponibil
  Future<bool> isSpeechRecognitionAvailable() async {
    try {
      return await speechToText.initialize();
    } catch (e) {
      Logger.error('Speech recognition check failed: $e', tag: 'VOICE_ORCHESTRATOR', error: e);
      return false;
    }
  }
  
  /// 🧹 Cleanup callbacks (NU dispune serviciile - singleton partajat!)
  void dispose() {
    // 🚀 SINGLETON: Nu dispunem serviciile reale, doar curățăm callback-urile
    // Serviciile rămân active pentru alte părți ale aplicației
    _onSpeechResult = null;
    _onSpeechError = null;
    _onStateChange = null;
    _onTtsCompleted = null;
    _conversationManager = null;
    // NOTĂ: _speechToText, _naturalTts, _beepService NU se dispun - sunt partajate global
  }
  
  /// 🧹 Dispune complet singleton-ul (doar la închiderea aplicației)
  void disposeCompletely() {
    stop();
    _naturalTts?.dispose();
    _beepService?.dispose();
    _speechToText = null;
    _naturalTts = null;
    _beepService = null;
    _isInitialized = false;
    _onSpeechResult = null;
    _onSpeechError = null;
    _onStateChange = null;
    _onTtsCompleted = null;
    _conversationManager = null;
  }
}