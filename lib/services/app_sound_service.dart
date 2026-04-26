import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:nabour_app/utils/logger.dart';

/// Serviciu centralizat pentru efecte sonore și haptice în UI.
class AppSoundService {
  static final AppSoundService _instance = AppSoundService._();
  factory AppSoundService() => _instance;
  AppSoundService._();

  static AppSoundService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();

  /// Redă un sunet scurt de confirmare/navigare (Click digital).
  Future<void> playMenuClick() async {
    try {
      await HapticFeedback.lightImpact();
      // Fallback: folosim chat_sound.wav deoarece menu_click.mp3 lipsește din bundle.
      await _player.play(AssetSource('sounds/chat_sound.wav'), volume: 0.3);
    } catch (e) {
      Logger.debug('AppSoundService: menu_click error: $e');
    }
  }

  /// Feedback discret la schimbarea modului contextual (fără spam la graniță GPS).
  Future<void> playDigitalClick() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      Logger.debug('AppSoundService: digital_click error: $e');
    }
  }

  /// Redă sunetul de tip "Swipe/Navigation" (Whoosh).
  Future<void> playNavigationSlide() async {
    try {
      await HapticFeedback.selectionClick();
      // await _player.play(AssetSource('sounds/nav_slide.mp3'), volume: 0.3);
    } catch (e) {
      Logger.debug('AppSoundService: navigation_slide error: $e');
    }
  }

  /// Sunet de succes (Tranzacție/Aprobare).
  Future<void> playSuccess() async {
    try {
      await HapticFeedback.mediumImpact();
      // await _player.play(AssetSource('sounds/success_chime.mp3'), volume: 0.6);
    } catch (e) {
      Logger.debug('AppSoundService: success error: $e');
    }
  }
}
