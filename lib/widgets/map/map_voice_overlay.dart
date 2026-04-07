// lib/widgets/map/map_voice_overlay.dart
//
// Buton mic pulsatoriu pentru asistentul vocal.
// Inlocuieste cardul mare care se suprapunea peste panelul de adrese.

import 'package:flutter/material.dart';
import 'package:nabour_app/voice/integration/friendsride_voice_integration.dart';
import 'package:nabour_app/voice/states/voice_interaction_states.dart';

/// Buton pulsatoriu flotant pentru controlul asistentului vocal.
/// Afisat in dreapta hartii, deasupra panelului de adrese.
/// Nu se suprapune niciodata peste UI-ul de introducere adrese.
class MapVoiceOverlay extends StatefulWidget {
  final FriendsRideVoiceIntegration voiceIntegration;
  final Future<void> Function()? onStartVoice;

  const MapVoiceOverlay({
    super.key,
    required this.voiceIntegration,
    this.onStartVoice,
  });

  @override
  State<MapVoiceOverlay> createState() => _MapVoiceOverlayState();
}

class _MapVoiceOverlayState extends State<MapVoiceOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;
  bool _showLastMessage = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_rotateController);
    widget.voiceIntegration.addListener(_onVoiceStateChanged);
  }

  void _onVoiceStateChanged() {
    if (!mounted) return;
    final rideState = widget.voiceIntegration.currentContext.rideState;
    // Hide the greeting bubble once the AI has processed a destination and placed a pin
    final pinVisible = rideState != RideFlowState.idle &&
        rideState != RideFlowState.listeningForInitialCommand &&
        rideState != RideFlowState.processingCommand;
    setState(() {
      if (pinVisible) _showLastMessage = false;
    });
  }

  @override
  void didUpdateWidget(MapVoiceOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voiceIntegration != widget.voiceIntegration) {
      oldWidget.voiceIntegration.removeListener(_onVoiceStateChanged);
      widget.voiceIntegration.addListener(_onVoiceStateChanged);
    }
  }

  @override
  void dispose() {
    widget.voiceIntegration.removeListener(_onVoiceStateChanged);
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Color _stateColor(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.listening:
        return Colors.red.shade600;
      case VoiceProcessingState.speaking:
        return Colors.green.shade600;
      case VoiceProcessingState.thinking:
        return Colors.orange.shade600;
      case VoiceProcessingState.waiting:
      case VoiceProcessingState.waitingForConfirmation:
        return Colors.blue.shade600;
      case VoiceProcessingState.error:
        return Colors.grey.shade700;
      default:
        return const Color(0xFF4F46E5);
    }
  }

  IconData _stateIcon(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.listening:
        return Icons.hearing_rounded;           // ureche
      case VoiceProcessingState.speaking:
        return Icons.record_voice_over_rounded; // omulet care vorbeste
      case VoiceProcessingState.thinking:
        return Icons.settings_rounded;          // rotita (animata)
      case VoiceProcessingState.waiting:
      case VoiceProcessingState.waitingForConfirmation:
        return Icons.back_hand_rounded;         // mana ridicata = asteapta
      case VoiceProcessingState.error:
        return Icons.close_rounded;             // X
      default:
        return Icons.mic_none_rounded;
    }
  }

  bool _shouldPulse(VoiceProcessingState state) {
    return state == VoiceProcessingState.listening ||
        state == VoiceProcessingState.speaking;
  }

  bool _shouldRotate(VoiceProcessingState state) {
    return state == VoiceProcessingState.thinking;
  }

  String _getLastAIMessage(List<String> history) {
    for (int i = history.length - 1; i >= 0; i--) {
      if (history[i].startsWith('AI:')) {
        return history[i].substring(3).trim();
      }
    }
    return 'Unde doriți să mergeți?';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.voiceIntegration.currentContext.processingState;
    final history = widget.voiceIntegration.currentContext.conversationHistory;
    final color = _stateColor(state);
    final icon = _stateIcon(state);
    final pulsing = _shouldPulse(state);
    final rotating = _shouldRotate(state);
    final lastMessage = _getLastAIMessage(history);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 12,
      bottom: bottomInset + 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bula cu ultimul mesaj AI
          if (_showLastMessage && lastMessage.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _showLastMessage = false),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 220),
                margin: const EdgeInsets.only(bottom: 8, right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(200),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  lastMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Butonul mic pulsatoriu + X
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Buton X — inchide asistentul
              GestureDetector(
                onTap: () async {
                  try {
                    await widget.voiceIntegration.stopVoiceInteraction();
                  } catch (_) {}
                },
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),

              // Butonul mic cu puls
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final scale = pulsing ? _pulseAnimation.value : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: () async {
                    setState(() => _showLastMessage = true);
                    if (state == VoiceProcessingState.idle &&
                        widget.onStartVoice != null) {
                      await widget.onStartVoice!();
                    }
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(120),
                          blurRadius: pulsing ? 18 : 8,
                          spreadRadius: pulsing ? 4 : 1,
                        ),
                      ],
                    ),
                    child: rotating
                        ? AnimatedBuilder(
                            animation: _rotateAnimation,
                            builder: (_, __) => Transform.rotate(
                              angle: _rotateAnimation.value * 6.2832,
                              child: Icon(icon, color: Colors.white, size: 26),
                            ),
                          )
                        : Icon(icon, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
