import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:nabour_app/utils/logger.dart';

/// In timpul TTS: daca microfonul detecteaza vorbire puternica, opreste redarea (barge-in).
class VoiceBargeInMonitor {
  VoiceBargeInMonitor();

  final AudioRecorder _rec = AudioRecorder();
  Timer? _timer;
  bool _active = false;
  bool _armed = false;

  static const double dbThreshold = -26.0;
  static const int consecutiveLoudSamples = 3;
  static const Duration sampleInterval = Duration(milliseconds: 90);
  static const Duration armDelay = Duration(milliseconds: 550);

  Future<void> start(void Function() onBargeIn) async {
    if (kIsWeb) return;
    try {
      if (!await _rec.hasPermission()) {
        Logger.debug('Barge-in: no mic permission', tag: 'VOICE_BARGE_IN');
        return;
      }
      if (await _rec.isRecording()) {
        await _rec.stop();
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/nabour_barge_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _rec.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _active = true;
      _armed = false;

      Future.delayed(armDelay, () {
        _armed = true;
      });

      var streak = 0;
      _timer = Timer.periodic(sampleInterval, (_) async {
        if (!_active || !_armed) return;
        try {
          final amp = await _rec.getAmplitude();
          if (amp.current > dbThreshold) {
            streak++;
            if (streak >= consecutiveLoudSamples) {
              Logger.info(
                'Barge-in triggered (amp=${amp.current.toStringAsFixed(1)} dBFS)',
                tag: 'VOICE_BARGE_IN',
              );
              onBargeIn();
              await stop();
            }
          } else {
            streak = 0;
          }
        } catch (_) {}
      });
    } catch (e) {
      Logger.warning('Barge-in monitor skipped: $e', tag: 'VOICE_BARGE_IN');
    }
  }

  Future<void> stop() async {
    _active = false;
    _armed = false;
    _timer?.cancel();
    _timer = null;
    try {
      if (await _rec.isRecording()) {
        await _rec.stop();
      }
    } catch (_) {}
  }
}
