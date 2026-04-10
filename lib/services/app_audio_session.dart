import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:nabour_app/utils/logger.dart';

/// Voice recording: NS/AEC when supported; Android voiceCommunication + comm mode.
const RecordConfig kVoiceRecordingRecordConfig = RecordConfig(
  encoder: AudioEncoder.aacLc,
  noiseSuppress: true,
  echoCancel: true,
  autoGain: true,
  numChannels: 1,
  sampleRate: 44100,
  androidConfig: AndroidRecordConfig(
    audioSource: AndroidAudioSource.voiceCommunication,
    audioManagerMode: AudioManagerMode.modeInCommunication,
    manageBluetooth: true,
  ),
);

class AppAudioSession {
  AppAudioSession._();

  static bool _voiceConfigured = false;

  static Future<void> ensureConfiguredForVoiceCommunication() async {
    if (kIsWeb) return;
    if (_voiceConfigured) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker |
                  AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );
      _voiceConfigured = true;
      Logger.debug('Audio session: voice communication configured', tag: 'AUDIO');
    } catch (e, st) {
      Logger.warning('Audio session configure skipped: $e\n$st', tag: 'AUDIO');
    }
  }
}