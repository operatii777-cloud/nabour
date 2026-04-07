import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:nabour_app/utils/logger.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  String _currentLanguage = 'ro';
  
  // Setări TTS
  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  
  // NOU: Debouncing pentru a evita frame skip-urile
  Timer? _speakDebounceTimer;
  String? _lastSpokenText;
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  Future<void> initialize({String language = 'ro'}) async {
    if (_isInitialized) return;
    
    try {
      _currentLanguage = language;
      
      // Configurare de bază
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);
      
      // Configurări specifice pentru platforme
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _flutterTts.setEngine("com.google.android.tts");
        // NOU: Dezactivăm awaitSpeakCompletion pentru a evita blocarea thread-ului principal
        await _flutterTts.awaitSpeakCompletion(false);
      }
      
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.allowBluetooth],
        );
      }
      
      // Setează callback-uri
      _flutterTts.setStartHandler(() {
        Logger.info("TTS Started");
      });
      
      _flutterTts.setCompletionHandler(() {
        Logger.info("TTS Completed");
      });
      
      _flutterTts.setErrorHandler((msg) {
        Logger.error("TTS Error: $msg");
      });
      
      _isInitialized = true;
      Logger.info("TTS Service initialized with language: $_currentLanguage");
      
    } catch (e) {
      Logger.error("TTS initialization error: $e", error: e);
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // NOU: Debouncing pentru a evita frame skip-urile
    if (_speakDebounceTimer?.isActive == true) {
      _speakDebounceTimer?.cancel();
    }
    
    // Dacă același text a fost spus recent, nu-l repetăm
    if (_lastSpokenText == text) {
      return;
    }
    
    _speakDebounceTimer = Timer(_debounceDelay, () async {
      try {
        _lastSpokenText = text;
        await _flutterTts.speak(text);
        Logger.debug("TTS Speaking: $text");
      } catch (e) {
        Logger.error("TTS Speak error: $e", error: e);
      }
    });
  }

  Future<void> stop() async {
    try {
      _speakDebounceTimer?.cancel();
      await _flutterTts.stop();
    } catch (e) {
      Logger.error("TTS Stop error: $e", error: e);
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      Logger.error("TTS Pause error: $e", error: e);
    }
  }

  // Setări pentru limbă
  Future<void> setLanguage(String language) async {
    if (_currentLanguage == language) return;
    
    _currentLanguage = language;
    try {
      await _flutterTts.setLanguage(_currentLanguage);
      Logger.debug("TTS Language changed to: $_currentLanguage");
    } catch (e) {
      Logger.error("TTS Language change error: $e", error: e);
    }
  }

  // Setări pentru viteză
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    try {
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (e) {
      Logger.error("TTS Speech rate error: $e", error: e);
    }
  }

  // Setări pentru volum
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _flutterTts.setVolume(_volume);
    } catch (e) {
      Logger.error("TTS Volume error: $e", error: e);
    }
  }

  // Setări pentru pitch
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    try {
      await _flutterTts.setPitch(_pitch);
    } catch (e) {
      Logger.error("TTS Pitch error: $e", error: e);
    }
  }

  // Verifică dacă TTS-ul este disponibil
  Future<bool> isLanguageAvailable(String language) async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.contains(language);
    } catch (e) {
      Logger.error("TTS Language check error: $e", error: e);
      return false;
    }
  }

  // Obține lista de limbi disponibile
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      Logger.error("TTS Get languages error: $e", error: e);
      return [];
    }
  }

  // Obține lista de voci disponibile
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(voices);
    } catch (e) {
      Logger.error("TTS Get voices error: $e", error: e);
      return [];
    }
  }

  // Setează vocea specifică
  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice(voice);
    } catch (e) {
      Logger.error("TTS Set voice error: $e", error: e);
    }
  }

  // Getteri pentru setările actuale
  String get currentLanguage => _currentLanguage;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  bool get isInitialized => _isInitialized;

  // Verifică dacă TTS-ul vorbește acum
  Future<bool> get isSpeaking async {
    try {
      // flutter_tts 4.2.3 nu mai are isSpeaking getter
      // Returnăm false ca fallback
      return false;
    } catch (e) {
      Logger.error("TTS isSpeaking error: $e", error: e);
      return false;
    }
  }

  // NOU: Cleanup la dispose
  void dispose() {
    _speakDebounceTimer?.cancel();
    _flutterTts.stop();
  }
}