import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/animation.dart';
import 'package:nabour_app/utils/logger.dart';

/// Sunete pentru recap cinematic: vânt (loop + volum în trepte) și pop balon.
///
/// Fișiere: [assets/sounds/recap_wind.mp3], [assets/sounds/recap_balloon_pop.mp3]
/// — efecte Mixkit (https://mixkit.co/license/#sfxFree), utilizare gratuită în aplicații.
class MovementRecapAudioController {
  MovementRecapAudioController();

  final AudioPlayer _wind = AudioPlayer();
  final AudioPlayer _pop = AudioPlayer();

  bool _windStarted = false;
  int _lastPopSegment = -1;
  bool _disposed = false;

  static const double _tSpaceEnd = 0.14;
  static const double _tZoomInEnd = 0.38;
  static const double _tRouteEnd = 0.78;

  /// Pregătește modul loop pentru vânt.
  Future<void> prepare() async {
    if (_disposed) return;
    try {
      await _wind.setReleaseMode(ReleaseMode.loop);
      await _wind.setVolume(0);
      await _pop.setReleaseMode(ReleaseMode.release);
      await _pop.setVolume(0.85);
    } catch (e) {
      Logger.warning('MovementRecapAudio prepare: $e', tag: 'RECAP_AUDIO');
    }
  }

  void resetForRecap() {
    _windStarted = false;
    _lastPopSegment = -1;
  }

  /// Aliniază volumul vântului și declanșează pop-uri după progresul traseului.
  Future<void> syncTimeline({
    required double t,
    required double hotspotRouteProgress,
    required int waypointCount,
  }) async {
    if (_disposed) return;
    t = t.clamp(0.0, 1.0);

    try {
      if (t <= _tSpaceEnd) {
        await _wind.setVolume(0);
        if (_windStarted) {
          await _wind.stop();
          _windStarted = false;
        }
        _lastPopSegment = -1;
        return;
      }

      if (!_windStarted) {
        _windStarted = true;
        await _wind.play(AssetSource('sounds/recap_wind.mp3'));
      }

      if (t <= _tZoomInEnd) {
        final u = (t - _tSpaceEnd) / (_tZoomInEnd - _tSpaceEnd);
        final ease = Curves.easeOutCubic.transform(u);
        await _wind.setVolume((ease * 0.62).clamp(0.0, 1.0));
        _lastPopSegment = -1;
        return;
      }

      if (t <= _tRouteEnd) {
        await _wind.setVolume(0.14);
        if (waypointCount >= 2) {
          final seg = (hotspotRouteProgress * (waypointCount - 1)).floor().clamp(0, waypointCount - 1);
          _firePopsUpTo(seg);
        }
        return;
      }

      final u = (t - _tRouteEnd) / (1.0 - _tRouteEnd);
      final ease = Curves.easeInCubic.transform(u);
      await _wind.setVolume((0.48 * (1.0 - ease)).clamp(0.0, 1.0));
      if (ease >= 0.98) {
        await stop();
      }
    } catch (e) {
      Logger.warning('MovementRecapAudio sync: $e', tag: 'RECAP_AUDIO');
    }
  }

  void _firePopsUpTo(int segmentIndex) {
    while (_lastPopSegment < segmentIndex) {
      _lastPopSegment++;
      if (_lastPopSegment > 0) {
        unawaited(_playPop());
      }
    }
  }

  Future<void> _playPop() async {
    if (_disposed) return;
    try {
      await _pop.stop();
      await _pop.play(AssetSource('sounds/recap_balloon_pop.mp3'));
    } catch (e) {
      Logger.warning('MovementRecapAudio pop: $e', tag: 'RECAP_AUDIO');
    }
  }

  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _wind.stop();
      await _pop.stop();
    } catch (_) {}
    _windStarted = false;
    _lastPopSegment = -1;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    try {
      await _wind.stop();
      await _pop.stop();
    } catch (_) {}
    _disposed = true;
    _windStarted = false;
    _lastPopSegment = -1;
    try {
      await _wind.dispose();
      await _pop.dispose();
    } catch (_) {}
  }
}
