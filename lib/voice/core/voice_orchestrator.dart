import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../tts/natural_voice_synthesizer.dart' as synthesizer;
import '../states/voice_interaction_states.dart';
import '../../services/audio_beep_service.dart';
import 'package:nabour_app/utils/logger.dart';
import 'voice_barge_in_monitor.dart';
import 'voice_turn_taking.dart';

/// Orchestrare vocală Nabour: STT, TTS, sincronizare, barge-in, moduri de ascultare.
///
/// Contract recomandat (asistenți vocali):
/// - **Un singur sens pe tură**: nu deschide STT cât timp TTS este activ; [listen] așteaptă sfârșitul redării.
/// - **Gol fonic după TTS**: pauză [micSettleDelayAfterTtsMs] înainte de microfon, ca să nu fie transcris ecoul.
/// - **Barge-in**: utilizatorul poate întrerupe TTS ([speak]); microfonul nu pornește automat decât după [speakThenListen] / [listen].
/// - **Tură serializată**: [speakThenListen] este înlănțuit — evită două mesaje + două ascultări suprapuse.
/// - **Moduri STT**: dictation pentru propoziții lungi; confirmation pentru da/nu, cu pauză mai scurtă.
///
/// O singură instanță (singleton) partajată în aplicație.
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
  synthesizer.NaturalVoiceSynthesizer get naturalTts =>
      _naturalTts ??= synthesizer.NaturalVoiceSynthesizer();
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

  /// Pauză după oprirea TTS înainte de a deschide microfonul (ecou, ultima silabă).
  static const int micSettleDelayAfterTtsMs = 400;

  /// Alias pentru cod existent — același interval ca [micSettleDelayAfterTtsMs].
  static const int postTtsBufferMs = micSettleDelayAfterTtsMs;

  /// După salut („unde doriți să mergeți?”): fereastră scurtă pentru destinație (max. câteva secunde).
  static const int initialAddressListenSeconds = 5;

  /// Tăcere înainte de finalizare; trebuie ≤ fereastra de ascultare ca să încheie natural înainte de timeout.
  static const int initialAddressPauseForSeconds = 3;

  /// Conversație normală (după primul turn): propoziții lungi, pauze naturale.
  static const int defaultListenMaxSeconds = 45;
  static const int defaultPauseForSeconds = 7;

  /// Întrebări cu răspuns scurt (da/nu): mod „confirmation” + pauză mai mică.
  static const int confirmationListenMaxSeconds = 18;
  static const int confirmationPauseForSeconds = 4;

  // 🔢 Failure tracking for consecutive STT errors / empty results
  int _consecutiveFailures = 0;
  static const int _failureThreshold = 2;
  Function(int)? _onFailureThreshold;

  /// Fragmente concatenate când utilizatorul face pauză la mijlocul propoziției (mod dictation).
  String _utteranceCarryOver = '';
  int _incompleteListenChain = 0;
  static const int _maxIncompleteListenChain = 5;

  final VoiceBargeInMonitor _bargeInMonitor = VoiceBargeInMonitor();

  /// Lanț pentru [speakThenListen]: o tură TTS→STT la un moment dat.
  Future<void> _speakThenListenChain = Future<void>.value();

  /// True cât timp o tură [speakThenListen] serializată rulează (inclusiv ascultarea).
  bool _speakThenListenInProgress = false;

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

          if (status == 'notListening' ||
              status == 'done' ||
              status == 'error') {
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
      Logger.error('Initialization error: $e',
          tag: 'VOICE_ORCHESTRATOR', error: e);
      _isInitialized = false;
      rethrow;
    }
  }

  stt.SpeechListenOptions _buildListenOptions({
    required stt.ListenMode listenMode,
    required bool partialResults,
  }) {
    return stt.SpeechListenOptions(
      listenMode: listenMode,
      partialResults: partialResults,
      cancelOnError: false,
    );
  }

  void _handleSpeechListenResult(
    SpeechRecognitionResult result, {
    required int effectiveTimeout,
    required int effectivePause,
    required String localeId,
    required bool partialResults,
    required stt.ListenMode listenMode,
  }) {
    if (!result.finalResult) {
      if (partialResults) {
        Logger.debug('Partial: "${result.recognizedWords}"',
            tag: 'VOICE_ORCHESTRATOR');
      }
      return;
    }

    Logger.debug('Final result: "${result.recognizedWords}"',
        tag: 'VOICE_ORCHESTRATOR');

    final trimmed = result.recognizedWords.trim();
    if (trimmed.isEmpty) {
      _utteranceCarryOver = '';
      _incompleteListenChain = 0;
      _incrementFailure();
      return;
    }

    final merged =
        _utteranceCarryOver.isEmpty ? trimmed : '$_utteranceCarryOver $trimmed';

    final dictationIncomplete = listenMode == stt.ListenMode.dictation &&
        VoiceTurnTaking.looksGrammaticallyIncomplete(merged);

    if (dictationIncomplete &&
        _incompleteListenChain < _maxIncompleteListenChain) {
      _incompleteListenChain++;
      _utteranceCarryOver = merged;
      Logger.debug(
        'Utterance looks incomplete, continuing listen (chain=$_incompleteListenChain): "$merged"',
        tag: 'VOICE_ORCHESTRATOR',
      );
      Future.microtask(() async {
        try {
          await stopListening();
          await Future.delayed(const Duration(milliseconds: 80));
          await listen(
            timeoutSeconds: effectiveTimeout,
            pauseForSeconds: effectivePause,
            localeId: localeId,
            partialResults: partialResults,
            listenMode: listenMode,
            playStartBeep: false,
          );
        } catch (e, st) {
          Logger.error(
            'Carry-over listen restart failed: $e',
            tag: 'VOICE_ORCHESTRATOR',
            error: e,
            stackTrace: st,
          );
        }
      });
      return;
    }

    _utteranceCarryOver = '';
    _incompleteListenChain = 0;
    _consecutiveFailures = 0;

    beepService.playProcessingStartBeeps();
    _onSpeechResult?.call(merged);
  }

  /// Ascultare vocală. Implicit: [ListenMode.dictation] + [defaultPauseForSeconds] pentru pauze lungi (respirație).
  /// Pentru confirmări scurte folosește [listenMode]: [stt.ListenMode.confirmation] și pauză mai mică.
  Future<String?> listen({
    int? timeoutSeconds,
    int? pauseForSeconds,
    String localeId = 'ro_RO',
    bool partialResults = true,
    stt.ListenMode listenMode = stt.ListenMode.dictation,
    bool playStartBeep = true,
  }) async {
    final effectiveTimeout = timeoutSeconds ?? defaultListenMaxSeconds;
    final effectivePause = pauseForSeconds ?? defaultPauseForSeconds;
    if (!_isInitialized) {
      Logger.warning('Not initialized, initializing now...',
          tag: 'VOICE_ORCHESTRATOR');
      await initialize();
    }

    if (_isListening) {
      Logger.warning('Already listening, stopping current session...',
          tag: 'VOICE_ORCHESTRATOR');
      await stopListening();
    }

    if (_isSpeaking) {
      Logger.warning('Currently speaking, stopping speech...',
          tag: 'VOICE_ORCHESTRATOR');
      await stopSpeaking();
    }

    // ✅ TTS-STT sync: Never start STT while TTS is still speaking.
    // Check both the local _isTtsSpeaking flag (set by orchestrator speak calls)
    // and naturalTts.isSpeaking (for direct TTS calls from RideFlowManager).
    if (_isTtsSpeaking || naturalTts.isSpeaking) {
      Logger.warning('TTS still active, waiting for it to finish...',
          tag: 'VOICE_ORCHESTRATOR');
      while (_isTtsSpeaking || naturalTts.isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Același interval ca după [speak] în [speakThenListen] — evită ecoul TTS.
      await Future.delayed(
        const Duration(milliseconds: micSettleDelayAfterTtsMs),
      );
    }

    try {
      _isListening = true;
      _updateState(VoiceProcessingState.listening);

      Logger.warning(
        'Starting to listen: max=${effectiveTimeout}s pause=${effectivePause}s mode=$listenMode',
        tag: 'VOICE_ORCHESTRATOR',
      );

      // 🔔 BEEP de "acum te ascult" - utilizatorul știe când să vorbească
      await beepService.playListeningStartBeep();

      await speechToText.listen(
        localeId: localeId,
        listenFor: Duration(seconds: effectiveTimeout),
        pauseFor: Duration(seconds: effectivePause),
        listenOptions: _buildListenOptions(
          listenMode: listenMode,
          partialResults: partialResults,
        ),
        onResult: (result) => _handleSpeechListenResult(
          result,
          effectiveTimeout: effectiveTimeout,
          effectivePause: effectivePause,
          localeId: localeId,
          partialResults: partialResults,
          listenMode: listenMode,
        ),
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

  /// Sintetizează mesajul cu emoție opțională; activează barge-in pe durata redării.
  Future<void> speak(String text,
      {VoiceEmotion emotion = VoiceEmotion.confident}) async {
    if (!_isInitialized) {
      Logger.warning('Not initialized, initializing now...',
          tag: 'VOICE_ORCHESTRATOR');
      await initialize();
    }

    if (_isListening) {
      Logger.warning('Currently listening, stopping...',
          tag: 'VOICE_ORCHESTRATOR');
      await stopListening();
    }

    if (_isSpeaking) {
      Logger.warning('Already speaking, stopping current speech...',
          tag: 'VOICE_ORCHESTRATOR');
      await stopSpeaking();
    }

    try {
      _isSpeaking = true;
      _isTtsSpeaking = true;
      _updateState(VoiceProcessingState.speaking);

      Logger.debug('Speaking: "$text"', tag: 'VOICE_ORCHESTRATOR');

      unawaited(_bargeInMonitor.start(() {
        Logger.info('Barge-in: stopping TTS', tag: 'VOICE_ORCHESTRATOR');
        naturalTts.stop();
        _isSpeaking = false;
        _isTtsSpeaking = false;
        _updateState(VoiceProcessingState.idle);
      }));

      await naturalTts.speakWithEmotion(text, emotion);

      _isSpeaking = false;
      _isTtsSpeaking = false;
      _updateState(VoiceProcessingState.idle);

      _onTtsCompleted?.call();

      Logger.info('Speech completed', tag: 'VOICE_ORCHESTRATOR');
    } catch (e) {
      Logger.error('Speech error: $e', tag: 'VOICE_ORCHESTRATOR', error: e);
      _isSpeaking = false;
      _isTtsSpeaking = false;
      _updateState(VoiceProcessingState.error);
      _onSpeechError?.call(e.toString());
    } finally {
      await _bargeInMonitor.stop();
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

      unawaited(_bargeInMonitor.start(() {
        Logger.info('Barge-in: stopping TTS (natural pauses)',
            tag: 'VOICE_ORCHESTRATOR');
        naturalTts.stop();
        _isSpeaking = false;
        _isTtsSpeaking = false;
        _updateState(VoiceProcessingState.idle);
      }));

      await naturalTts.speakWithNaturalPauses(text);

      _isSpeaking = false;
      _isTtsSpeaking = false;
      _updateState(VoiceProcessingState.idle);

      Logger.info('Speech completed, transitioning to listening...',
          tag: 'VOICE_ORCHESTRATOR');

      _onTtsCompleted?.call();

      beepService.playConversationEndBeep();

      await _startAutomaticListening();
    } catch (e) {
      Logger.error('Natural pauses speech error: $e',
          tag: 'VOICE_ORCHESTRATOR', error: e);
      _isSpeaking = false;
      _isTtsSpeaking = false;
      _updateState(VoiceProcessingState.error);
    } finally {
      await _bargeInMonitor.stop();
    }
  }

  /// 🗣️ Vorbește apoi pornește ascultarea cu buffer fix (sincronizare TTS → STT).
  /// Apelurile sunt **serializate** pentru a evita curse între două ture converse.
  Future<void> speakThenListen(
    String text, {
    VoiceEmotion emotion = VoiceEmotion.calm,
    int? timeoutSeconds,
    int? pauseForSeconds,
    String localeId = 'ro_RO',
    stt.ListenMode listenMode = stt.ListenMode.dictation,
  }) {
    final Future<void> thisTurn = _speakThenListenChain.then((_) async {
      _speakThenListenInProgress = true;
      try {
        await speak(text, emotion: emotion);
        await Future.delayed(
          const Duration(milliseconds: micSettleDelayAfterTtsMs),
        );
        await listen(
          timeoutSeconds: timeoutSeconds,
          pauseForSeconds: pauseForSeconds,
          localeId: localeId,
          listenMode: listenMode,
        );
      } finally {
        _speakThenListenInProgress = false;
      }
    });
    _speakThenListenChain = thisTurn.catchError((Object e, StackTrace s) {
      Logger.error(
        'speakThenListen queue: $e',
        tag: 'VOICE_ORCHESTRATOR',
        error: e,
        stackTrace: s,
      );
    });
    return thisTurn;
  }

  /// TTS → STT pentru răspunsuri scurte (da/nu), fără mod dictation lung.
  Future<void> speakThenListenConfirmation(
    String text, {
    VoiceEmotion emotion = VoiceEmotion.calm,
    String localeId = 'ro_RO',
  }) {
    return speakThenListen(
      text,
      emotion: emotion,
      localeId: localeId,
      timeoutSeconds: confirmationListenMaxSeconds,
      pauseForSeconds: confirmationPauseForSeconds,
      listenMode: stt.ListenMode.confirmation,
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
      Logger.error('Stop listening error: $e',
          tag: 'VOICE_ORCHESTRATOR', error: e);
    }
  }

  /// 🛑 Oprește vorbirea
  Future<void> stopSpeaking() async {
    try {
      await _bargeInMonitor.stop();
      if (_isSpeaking) {
        await naturalTts.stop();
        _isSpeaking = false;
        _isTtsSpeaking = false;
        _updateState(VoiceProcessingState.idle);
        Logger.debug('Speech stopped', tag: 'VOICE_ORCHESTRATOR');
      }
    } catch (e) {
      Logger.error('Stop speech error: $e',
          tag: 'VOICE_ORCHESTRATOR', error: e);
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
        Logger.info('Listening paused (temporarily)',
            tag: 'VOICE_ORCHESTRATOR');
      }
    } catch (e) {
      Logger.error('Pause listening error: $e',
          tag: 'VOICE_ORCHESTRATOR', error: e);
    }
  }

  /// ▶️ Reia listening-ul după pauză
  Future<void> resumeListening({
    String localeId = 'ro_RO',
    int? timeoutSeconds,
    int? pauseForSeconds,
    stt.ListenMode listenMode = stt.ListenMode.dictation,
  }) async {
    try {
      if (!_isListening) {
        _isListening = true;
        _updateState(VoiceProcessingState.listening);
        final t = timeoutSeconds ?? defaultListenMaxSeconds;
        final p = pauseForSeconds ?? defaultPauseForSeconds;
        await speechToText.listen(
          localeId: localeId,
          listenFor: Duration(seconds: t),
          pauseFor: Duration(seconds: p),
          listenOptions: _buildListenOptions(
            listenMode: listenMode,
            partialResults: true,
          ),
          onResult: (result) => _handleSpeechListenResult(
            result,
            effectiveTimeout: t,
            effectivePause: p,
            localeId: localeId,
            partialResults: true,
            listenMode: listenMode,
          ),
        );

        Logger.info('Listening resumed', tag: 'VOICE_ORCHESTRATOR');
      }
    } catch (e) {
      Logger.error('Resume listening error: $e',
          tag: 'VOICE_ORCHESTRATOR', error: e);
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
    Logger.warning('Consecutive STT failures: $_consecutiveFailures',
        tag: 'VOICE_ORCHESTRATOR');
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

  /// True cât timp rulează o tură [speakThenListen] (inclusiv [listen]).
  bool get isSpeakThenListenInProgress => _speakThenListenInProgress;

  /// 🎯 Verifică dacă e disponibil (fără suprapunere cu tură vocală activă).
  bool get isAvailable =>
      _isInitialized &&
      !_isListening &&
      !_isTtsSpeaking &&
      !naturalTts.isSpeaking &&
      !_speakThenListenInProgress;

  /// 🎯 AUTOMAT: Pornește ascultarea imediat după TTS
  Future<void> _startAutomaticListening() async {
    try {
      Logger.info('Starting automatic listening after TTS...',
          tag: 'VOICE_ORCHESTRATOR');

      // Așteaptă puțin pentru ca utilizatorul să proceseze mesajul
      await Future.delayed(const Duration(milliseconds: 800));

      // Verifică dacă nu sunt deja în proces de ascultare
      if (!_isListening && !_isSpeaking) {
        await listen();
      }
    } catch (e) {
      Logger.error('Auto-listen error: $e',
          tag: 'VOICE_ORCHESTRATOR', error: e);
    }
  }

  /// 🎯 NOU: Pornește automat ascultarea pentru confirmare
  Future<void> startListeningForConfirmation({
    int? timeoutSeconds,
    String localeId = 'ro_RO',
  }) async {
    if (_conversationManager?.currentState ==
        VoiceConversationState.waitingForConfirmation) {
      Logger.info('Starting automatic listening for confirmation...',
          tag: 'VOICE_ORCHESTRATOR');

      // Așteaptă puțin înainte de a porni ascultarea
      await Future.delayed(const Duration(milliseconds: 500));

      await listen(
        timeoutSeconds: timeoutSeconds ?? confirmationListenMaxSeconds,
        localeId: localeId,
        pauseForSeconds: confirmationPauseForSeconds,
        listenMode: stt.ListenMode.confirmation,
      );
    } else {
      Logger.debug('Not in confirmation state, skipping auto-listen',
          tag: 'VOICE_ORCHESTRATOR');
    }
  }

  /// 🎤 Verifică dacă speech recognition-ul e disponibil
  Future<bool> isSpeechRecognitionAvailable() async {
    try {
      return await speechToText.initialize();
    } catch (e) {
      Logger.error('Speech recognition check failed: $e',
          tag: 'VOICE_ORCHESTRATOR', error: e);
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
    unawaited(_bargeInMonitor.stop());
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
