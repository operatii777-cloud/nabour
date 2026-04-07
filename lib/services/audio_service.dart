import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:nabour_app/utils/logger.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDisposed = false;

  /// Redă sunetul pentru mesaje primite în chat (ding dulce 2 tonuri)
  Future<void> playMessageReceivedSound() async {
    if (_isDisposed) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/chat_sound.wav'));
      HapticFeedback.mediumImpact();
    } catch (e) {
      Logger.error('Error playing message sound: $e', error: e);
      HapticFeedback.mediumImpact();
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  /// Redă sunetul pentru o nouă solicitare de cursă (dublu beep alert)
  Future<void> playRideRequestSound() async {
    if (_isDisposed) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/message_sound.wav'));
      HapticFeedback.heavyImpact();
    } catch (e) {
      Logger.error('Error playing ride request sound: $e', error: e);
      HapticFeedback.heavyImpact();
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  /// Redă sunetul de "Balloon Pop" pentru Bump-ul de vecin
  Future<void> playNeighborBumpSound() async {
    if (_isDisposed) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/recap_balloon_pop.mp3'));
    } catch (_) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  /// Redă sunetul de claxon virtual (beep scurt + haptic)
  Future<void> playHonkSound() async {
    if (_isDisposed) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/chat_sound.wav'));
      HapticFeedback.vibrate();
      Logger.debug('Honk sound played');
    } catch (_) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  /// Redă sunetul pentru apeluri primite
  Future<void> playIncomingCallSound() async {
    if (_isDisposed) return;
    
    try {
      SystemSound.play(SystemSoundType.alert);
      Logger.debug('Playing incoming call sound (system default)');
    } catch (e) {
      Logger.error('Error playing call sound: $e', error: e);
      HapticFeedback.mediumImpact();
    }
  }

  /// Oprește toate sunetele în curs de redare
  Future<void> stopAllSounds() async {
    if (_isDisposed) return;
    
    try {
      await _audioPlayer.stop();
      Logger.debug('Stopped all audio playback');
    } catch (e) {
      Logger.error('Error stopping audio: $e', error: e);
    }
  }

  /// Setează volumul pentru sunetele custom (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;
    
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      Logger.debug('Audio volume set to: ${(volume * 100).round()}%');
    } catch (e) {
      Logger.error('Error setting volume: $e', error: e);
    }
  }

  /// Cleanup - se apelează când serviciul nu mai este necesar
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    _audioPlayer.dispose();
    Logger.debug('AudioService disposed');
  }
}