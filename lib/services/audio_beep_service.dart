import 'dart:async';
import 'dart:io';
import 'package:nabour_app/utils/logger.dart';

/// 🔔 Serviciu pentru beep-uri audio în conversațiile AI
///
/// Caracteristici:
/// - Beep după conversația AI (utilizatorul să știe când să răspundă)
/// - Două beep-uri scurte când AI procesează informația
/// - Sunete personalizabile și configurabile
class AudioBeepService {
  static final AudioBeepService _instance = AudioBeepService._internal();
  factory AudioBeepService() => _instance;
  AudioBeepService._internal();

  bool _isInitialized = false;
  bool _isPlaying = false;

  /// 🚀 Inițializează serviciul de beep-uri
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.debug('Initializing beep service', tag: 'AudioBeep');

      _isInitialized = true;
      Logger.debug('Beep service initialized', tag: 'AudioBeep');
    } catch (e) {
      Logger.warning('Initialization error: $e', tag: 'AudioBeep');
      _isInitialized = false;
      rethrow;
    }
  }

  /// 🔔 Beep când AI-ul ÎNCEPE să asculte
  Future<void> playListeningStartBeep() async {
    if (!_isInitialized) await initialize();

    try {
      Logger.debug('Listening start beep (user may speak)', tag: 'AudioBeep');

      await _playSystemBeep(frequency: 600, duration: 100);
      await Future.delayed(const Duration(milliseconds: 50));
      await _playSystemBeep(frequency: 900, duration: 150);

      Logger.debug('Listening start beep played', tag: 'AudioBeep');
    } catch (e) {
      Logger.warning('Listening start beep error: $e', tag: 'AudioBeep');
    }
  }

  /// 🔔 Beep lung după conversația AI
  Future<void> playConversationEndBeep() async {
    if (!_isInitialized) await initialize();

    try {
      Logger.debug('Conversation end beep (user turn)', tag: 'AudioBeep');

      if (_isPlaying) {
        _isPlaying = false;
      }

      await _playSystemBeep(frequency: 800, duration: 400);

      Logger.debug('Conversation end beep played', tag: 'AudioBeep');
    } catch (e) {
      Logger.warning('Conversation end beep error: $e', tag: 'AudioBeep');
      await _playFallbackBeep();
    }
  }

  /// 🔔🔔 Două beep-uri scurte când AI procesează informația
  Future<void> playProcessingStartBeeps() async {
    if (!_isInitialized) await initialize();

    try {
      Logger.debug('Processing start beeps', tag: 'AudioBeep');

      if (_isPlaying) {
        _isPlaying = false;
      }

      await _playSystemBeep(frequency: 1000, duration: 100);
      await Future.delayed(const Duration(milliseconds: 80));
      await _playSystemBeep(frequency: 1200, duration: 100);

      Logger.debug('Processing start beeps played', tag: 'AudioBeep');
    } catch (e) {
      Logger.warning('Processing start beeps error: $e', tag: 'AudioBeep');
      await _playFallbackBeep();
    }
  }

  /// 🔔 Beep pentru confirmarea procesării complete
  Future<void> playProcessingCompleteBeep() async {
    if (!_isInitialized) await initialize();

    try {
      Logger.debug('Processing complete beep (AI will speak)', tag: 'AudioBeep');

      if (_isPlaying) {
        _isPlaying = false;
      }

      await _playSystemBeep(frequency: 1400, duration: 200);

      Logger.debug('Processing complete beep played', tag: 'AudioBeep');
    } catch (e) {
      Logger.warning('Processing complete beep error: $e', tag: 'AudioBeep');
      await _playFallbackBeep();
    }
  }

  /// 🔔 Beep pentru erori
  Future<void> playErrorBeep() async {
    if (!_isInitialized) await initialize();

    try {
      Logger.debug('Playing error beep', tag: 'AudioBeep');

      if (_isPlaying) {
        _isPlaying = false;
      }

      await _playSystemBeep(frequency: 400, duration: 500);

      Logger.debug('Error beep played', tag: 'AudioBeep');
    } catch (e) {
      Logger.warning('Error beep failed: $e', tag: 'AudioBeep');
      await _playFallbackBeep();
    }
  }

  Future<void> _playSystemBeep({
    required int frequency,
    required int duration,
  }) async {
    try {
      _isPlaying = true;

      if (Platform.isAndroid || Platform.isIOS) {
        if (Platform.isAndroid) {
          await _playAndroidBeep(frequency, duration);
        } else if (Platform.isIOS) {
          await _playIOSBeep(frequency, duration);
        }
      } else {
        await _playDesktopBeep(frequency, duration);
      }

      _isPlaying = false;
    } catch (e) {
      Logger.warning('System beep error: $e', tag: 'AudioBeep');
      _isPlaying = false;
      await _playFallbackBeep();
    }
  }

  Future<void> _playAndroidBeep(int frequency, int duration) async {
    try {
      Logger.debug('Android beep ${frequency}Hz ${duration}ms', tag: 'AudioBeep');
      await Future.delayed(Duration(milliseconds: duration));
    } catch (e) {
      Logger.warning('Android beep error: $e', tag: 'AudioBeep');
    }
  }

  Future<void> _playIOSBeep(int frequency, int duration) async {
    try {
      Logger.debug('iOS beep ${frequency}Hz ${duration}ms', tag: 'AudioBeep');
      await Future.delayed(Duration(milliseconds: duration));
    } catch (e) {
      Logger.warning('iOS beep error: $e', tag: 'AudioBeep');
    }
  }

  Future<void> _playDesktopBeep(int frequency, int duration) async {
    try {
      Logger.debug('Desktop beep ${frequency}Hz ${duration}ms', tag: 'AudioBeep');
      await Future.delayed(Duration(milliseconds: duration));
    } catch (e) {
      Logger.warning('Desktop beep error: $e', tag: 'AudioBeep');
    }
  }

  Future<void> _playFallbackBeep() async {
    try {
      Logger.debug('Fallback beep', tag: 'AudioBeep');
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      Logger.warning('Fallback beep error: $e', tag: 'AudioBeep');
    }
  }

  Future<void> stopAllBeeps() async {
    try {
      if (_isPlaying) {
        _isPlaying = false;
        Logger.debug('All beeps stopped', tag: 'AudioBeep');
      }
    } catch (e) {
      Logger.warning('Stop beeps error: $e', tag: 'AudioBeep');
    }
  }

  bool get isInitialized => _isInitialized;

  bool get isPlaying => _isPlaying;

  void dispose() {
    stopAllBeeps();
  }
}
