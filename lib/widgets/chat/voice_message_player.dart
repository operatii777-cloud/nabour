import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:nabour_app/theme/app_colors.dart';
import 'package:nabour_app/theme/app_text_styles.dart';
import 'package:nabour_app/utils/logger.dart';
import 'dart:async';

/// Widget pentru redarea voice messages în chat (stil WhatsApp)
class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int duration; // Durata în secunde
  final bool isMe;
  final Color? bubbleColor;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.isMe,
    this.bubbleColor,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _duration = Duration(seconds: widget.duration);
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          // Nu există loading state în audioplayers, folosim doar playing/paused
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero || _position >= _duration) {
          await _audioPlayer.play(UrlSource(widget.audioUrl));
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      Logger.warning('Play voice message error: $e', tag: 'ChatVoice');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la redarea mesajului vocal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Buton play/pause
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.isMe 
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 18,
                      color: widget.isMe ? AppColors.primary : Colors.white,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Progress bar și durata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _getProgress(),
                    backgroundColor: widget.isMe
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isMe ? AppColors.primary : AppColors.primary,
                    ),
                    minHeight: 2,
                  ),
                ),
                const SizedBox(height: 4),
                // Durata
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: widget.isMe 
                            ? AppColors.textPrimary 
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: widget.isMe 
                            ? AppColors.textPrimary 
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

