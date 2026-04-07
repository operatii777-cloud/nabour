import 'package:flutter_tts/flutter_tts.dart';
import '../states/voice_interaction_states.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🗣️ Natural Voice Synthesizer - Funcționează EXACT ca Gemini Voice TTS
/// 
/// Caracteristici:
/// - Vocea naturală și fluidă
/// - Răspuns instant (fără pauze)
/// - Procesare continuă a textului
/// - Integrare perfectă cu Nabour
class NaturalVoiceSynthesizer {
  // Lazy: FlutterTts() constructor triggers Android TTS service binding (~640ms
  // BpBinder IPC). Only instantiate on first actual TTS call, not at construction.
  FlutterTts? _ttsInstance;
  FlutterTts get _tts => _ttsInstance ??= FlutterTts();
  
  // 🎯 Configurații pentru vocea naturală
  static const String _defaultVoiceRo = 'ro-RO';
  static const String _defaultVoiceEn = 'en-US';
  String _currentLanguage = _defaultVoiceRo; // ✅ NOU: Limba curentă
  static const double _defaultRate = 0.5; // Viteza naturală
  static const double _defaultPitch = 1.0; // Pitch natural
  static const double _defaultVolume = 1.0; // Volum maxim
  
  // 🚀 Starea curentă
  bool _isSpeaking = false;
  bool _isInitialized = false;
  Future<void>? _initFuture;
  
  /// ✅ NOU: Setează limba pentru TTS
  Future<void> setLanguage(String languageCode) async {
    try {
      String ttsLanguage;
      if (languageCode == 'en') {
        ttsLanguage = _defaultVoiceEn;
      } else {
        ttsLanguage = _defaultVoiceRo; // Default română
      }
      
      if (_currentLanguage != ttsLanguage) {
        _currentLanguage = ttsLanguage;
        await _tts.setLanguage(ttsLanguage);
        Logger.debug('Language changed to: $ttsLanguage', tag: 'NATURAL_TTS');
      }
    } catch (e) {
      Logger.error('Error setting language: $e', tag: 'NATURAL_TTS', error: e);
    }
  }
  
  /// 🚀 Inițializează TTS-ul
  Future<void> initialize({String? languageCode}) async {
    if (_isInitialized) return;
    _initFuture ??= _initializeBody(languageCode: languageCode);
    try {
      await _initFuture!;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _initializeBody({String? languageCode}) async {
    if (_isInitialized) return;
    try {
      Logger.debug('Initializing...', tag: 'NATURAL_TTS');

      if (languageCode != null) {
        await setLanguage(languageCode);
      } else {
        await _tts.setLanguage(_defaultVoiceRo);
        _currentLanguage = _defaultVoiceRo;
      }

      await _tts.setSpeechRate(_defaultRate);
      await _tts.setPitch(_defaultPitch);
      await _tts.setVolume(_defaultVolume);

      _tts.setStartHandler(() {
        Logger.info('Started speaking', tag: 'NATURAL_TTS');
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        Logger.debug('Finished speaking', tag: 'NATURAL_TTS');
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        Logger.error('Error: $msg', tag: 'NATURAL_TTS');
        _isSpeaking = false;
      });

      _isInitialized = true;
      Logger.info('Initialized successfully', tag: 'NATURAL_TTS');
    } catch (e) {
      Logger.error('Initialization error: $e', tag: 'NATURAL_TTS', error: e);
      _isInitialized = false;
    }
  }
  
  /// 🗣️ Vorbește textul EXACT ca Gemini Voice
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      Logger.warning('Not initialized, initializing now...', tag: 'NATURAL_TTS');
      await initialize();
    }
    
    if (_isSpeaking) {
      Logger.warning('Already speaking, stopping current speech...', tag: 'NATURAL_TTS');
      await stop();
    }
    
    try {
      Logger.debug('Speaking: "$text"', tag: 'NATURAL_TTS');
      
      // 🚀 Trimit textul la TTS
      // ✅ FIX: Set _isSpeaking=true BEFORE calling speak so the wait loop
      // below doesn't exit early when setStartHandler fires after the await.
      _isSpeaking = true;
      await _tts.speak(text);
      
      // 🎯 Aștept să se termine (cu safety timeout de 10 secunde)
      final startTime = DateTime.now();
      while (_isSpeaking) {
        if (DateTime.now().difference(startTime).inSeconds > 10) {
          Logger.warning('TTS Speak timeout reached, forcing idle state', tag: 'NATURAL_TTS');
          _isSpeaking = false;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      Logger.info('Speech completed', tag: 'NATURAL_TTS');
      
    } catch (e) {
      Logger.error('Speech error: $e', tag: 'NATURAL_TTS', error: e);
      _isSpeaking = false;
    }
  }
  
  /// 🗣️ Vorbește textul cu prioritate înaltă (pentru confirmări)
  Future<void> speakPriority(String text) async {
    if (_isSpeaking) {
      await stop();
    }
    
    // 🎯 Setez parametrii pentru confirmări (mai rapid)
    await _tts.setSpeechRate(0.6);
    
    await speak(text);
    
    // 🎯 Restaurez parametrii normali
    await _tts.setSpeechRate(_defaultRate);
  }
  
  /// 🗣️ Vorbește textul cu emoție (pentru răspunsuri importante)
  Future<void> speakWithEmotion(String text, VoiceEmotion emotion) async {
    if (_isSpeaking) {
      await stop();
    }
    
    // 🎯 Ajustez parametrii în funcție de emoție
    switch (emotion) {
      case VoiceEmotion.happy:
        await _tts.setPitch(1.1);
        await _tts.setSpeechRate(0.55);
        break;
      case VoiceEmotion.confident:
        await _tts.setPitch(1.05);
        await _tts.setSpeechRate(0.5);
        break;
      case VoiceEmotion.calm:
        await _tts.setPitch(0.95);
        await _tts.setSpeechRate(0.45);
        break;
      case VoiceEmotion.urgent:
        await _tts.setPitch(1.15);
        await _tts.setSpeechRate(0.65);
        break;
      case VoiceEmotion.curious:
        await _tts.setPitch(1.08);
        await _tts.setSpeechRate(0.52);
        break;
      case VoiceEmotion.friendly:
        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(0.5);
        break;
      case VoiceEmotion.direct:
        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(0.55);
        break;
    }
    
    await speak(text);
    
    // 🎯 Restaurez parametrii normali
    await _tts.setPitch(_defaultPitch);
    await _tts.setSpeechRate(_defaultRate);
  }
  
  /// 🗣️ Vorbește textul cu pauze naturale (pentru propoziții lungi)
  Future<void> speakWithNaturalPauses(String text) async {
    if (_isSpeaking) {
      await stop();
    }
    
    // 🎯 Împart textul în propoziții
    final sentences = _splitIntoSentences(text);
    
    for (final sentence in sentences) {
      if (sentence.trim().isNotEmpty) {
        await speak(sentence.trim());
        
        // 🎯 Pauză naturală între propoziții
        if (sentences.indexOf(sentence) < sentences.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    }
  }
  
  /// 🛑 Oprește vorbirea
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      Logger.debug('Speech stopped', tag: 'NATURAL_TTS');
    } catch (e) {
      Logger.error('Stop error: $e', tag: 'NATURAL_TTS', error: e);
    }
  }
  
  /// 🎯 Verifică dacă vorbește
  bool get isSpeaking => _isSpeaking;
  
  /// 🎯 Verifică dacă e inițializat
  bool get isInitialized => _isInitialized;
  
  /// 📝 Împarte textul în propoziții naturale
  List<String> _splitIntoSentences(String text) {
    // 🎯 Regex pentru propoziții românești
    final sentenceRegex = RegExp(r'[.!?]+');
    return text.split(sentenceRegex);
  }
  
  /// 🧹 Cleanup
  void dispose() {
    stop();
    _tts.setStartHandler(() {});
    _tts.setCompletionHandler(() {});
    _tts.setErrorHandler((msg) {});
  }
}


