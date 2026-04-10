import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/models/chat_message_model.dart';
import 'package:nabour_app/theme/app_colors.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/services/app_audio_session.dart';

/// Widget pentru butonul de înregistrare voice message
class VoiceRecordButton extends StatefulWidget {
  final String rideId;
  final VoidCallback? onRecordingComplete;
  final VoidCallback? onError;
  /// If provided, called with (voiceUrl, durationSecs) instead of
  /// FirestoreService.sendChatMessage. Allows the parent to save to the
  /// correct Firestore collection.
  final Future<void> Function(String voiceUrl, int durationSecs)? onVoiceReady;

  const VoiceRecordButton({
    super.key,
    required this.rideId,
    this.onRecordingComplete,
    this.onError,
    this.onVoiceReady,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isUploading = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  String? _audioPath;

  @override
  void dispose() {
    _durationTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _checkPermissions() async {
    final micPermission = await Permission.microphone.status;
    if (!micPermission.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permisiunea pentru microfon este necesară pentru înregistrare.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }
    return true;
  }

  Future<void> _startRecording() async {
    if (!await _checkPermissions()) return;

    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _audioPath = '${directory.path}/voice_message_$timestamp.m4a';

      if (await _audioRecorder.hasPermission()) {
        await AppAudioSession.ensureConfiguredForVoiceCommunication();
        await _audioRecorder.start(
          kVoiceRecordingRecordConfig,
          path: _audioPath!,
        );

        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });

        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordingDuration = Duration(seconds: timer.tick);
            });
          }
        });
      }
    } catch (e) {
      Logger.warning('Voice record start error: $e', tag: 'ChatVoice');
      if (mounted) {
        widget.onError?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la începerea înregistrării: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording(bool send) async {
    if (!_isRecording) return;

    _durationTimer?.cancel();
    final path = await _audioRecorder.stop();
    
    setState(() {
      _isRecording = false;
    });

    if (path == null || path.isEmpty) {
      Logger.warning('No audio file recorded', tag: 'ChatVoice');
      return;
    }

    if (!send) {
      // Anulează înregistrarea - șterge fișierul
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        Logger.warning('Delete cancelled recording: $e', tag: 'ChatVoice');
      }
      return;
    }

    // Trimite mesajul vocal
    await _uploadAndSendVoiceMessage(path);
  }

  Future<void> _uploadAndSendVoiceMessage(String audioPath) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('Fișierul audio nu există');
      }

      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        throw Exception('Fișierul audio este prea mare (max 10MB)');
      }

      // Upload la Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('voice_messages')
          .child('${widget.rideId}_$timestamp.m4a');

      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'audio/m4a',
          customMetadata: {
            'rideId': widget.rideId,
            'recordedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      final duration = _recordingDuration.inSeconds;

      // Trimite mesajul în chat: dacă există callback extern, îl folosim;
      // altfel trimitem direct prin FirestoreService (compatibilitate active_ride_screen).
      if (widget.onVoiceReady != null) {
        await widget.onVoiceReady!(downloadUrl, duration);
      } else {
        await FirestoreService().sendChatMessage(
          widget.rideId,
          '🎤 Mesaj vocal',
          type: MessageType.voice,
          voiceUrl: downloadUrl,
          voiceDuration: duration,
        );
      }

      // Șterge fișierul local
      try {
        await file.delete();
      } catch (e) {
        Logger.warning('Delete local voice file: $e', tag: 'ChatVoice');
      }

      if (mounted) {
        widget.onRecordingComplete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesaj vocal trimis!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Logger.warning('Voice upload/send error: $e', tag: 'ChatVoice');
      if (mounted) {
        widget.onError?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la trimiterea mesajului vocal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_isRecording) {
      return GestureDetector(
        // onTap handles both short tap and any press-release on the recording button.
        // onLongPressUp was removed — it fired BEFORE onLongPressEnd, cancelling
        // every recording. Using only onTap (no competing onLongPress) means Flutter
        // fires onTap on any release, whether short or long.
        onTap: () => _stopRecording(true),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic, color: Colors.white, size: 20),
              Text(
                _formatDuration(_recordingDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: _startRecording,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mic,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
}

