import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/services/navigation_service.dart';
import 'package:nabour_app/services/tts_service.dart';

class RideTurnByTurnWidget extends StatefulWidget {
  final NavigationStep currentNavigationStep;
  final bool voiceMuted;
  final TtsService ttsService;
  final void Function(bool muted) onVoiceMutedChanged;
  final VoidCallback onDismiss;

  const RideTurnByTurnWidget({
    super.key,
    required this.currentNavigationStep,
    required this.voiceMuted,
    required this.ttsService,
    required this.onVoiceMutedChanged,
    required this.onDismiss,
  });

  @override
  State<RideTurnByTurnWidget> createState() => _RideTurnByTurnWidgetState();
}

class _RideTurnByTurnWidgetState extends State<RideTurnByTurnWidget> {
  late bool _voiceMuted;

  @override
  void initState() {
    super.initState();
    _voiceMuted = widget.voiceMuted;
  }

  @override
  void didUpdateWidget(RideTurnByTurnWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voiceMuted != widget.voiceMuted) {
      _voiceMuted = widget.voiceMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.currentNavigationStep;
    final distance = step.distance;
    final instruction = step.instruction;

    Color backgroundColor;
    Color textColor;

    if (step.type == 'turn') {
      if (step.modifier == 'left') {
        backgroundColor = Colors.blue;
        textColor = Colors.white;
      } else if (step.modifier == 'right') {
        backgroundColor = Colors.green;
        textColor = Colors.white;
      } else {
        backgroundColor = Colors.orange;
        textColor = Colors.white;
      }
    } else if (step.type == 'arrive') {
      backgroundColor = Colors.green;
      textColor = Colors.white;
    } else {
      backgroundColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onPrimary;
    }

    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Semantics(
        label: 'Banner navigație. ${step.type ?? ''} ${step.modifier ?? ''}. Distanță ${distance.toStringAsFixed(0)} metri.',
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.3).round()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor.withAlpha((255 * 0.2).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getInstructionIcon(step),
                  color: textColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      instruction,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${distance.toStringAsFixed(0)} m',
                      style: TextStyle(
                        color: textColor.withAlpha((255 * 0.8).round()),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildLaneGuidanceChips(step, textColor),
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Repetă',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () async {
                      try {
                        if (!_voiceMuted) await widget.ttsService.speak(instruction);
                      } catch (_) {}
                    },
                    icon: Icon(Icons.volume_up, color: textColor, size: 20),
                  ),
                  IconButton(
                    tooltip: _voiceMuted ? 'Unmute voce' : 'Mute voce',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () async {
                      final newMuted = !_voiceMuted;
                      setState(() {
                        _voiceMuted = newMuted;
                      });
                      widget.onVoiceMutedChanged(newMuted);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('nav_voice_muted', newMuted);
                      } catch (_) {}
                      if (newMuted) {
                        widget.ttsService.stop();
                      }
                    },
                    icon: Icon(
                      _voiceMuted ? Icons.volume_off : Icons.volume_up,
                      color: textColor,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ascunde',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: widget.onDismiss,
                    icon: Icon(Icons.close, color: textColor, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaneGuidanceChips(NavigationStep step, Color textColor) {
    final List<Map<String, dynamic>> lanes = _deriveLanesFromStep(step);
    if (lanes.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: lanes.map((lane) {
        final bool isRecommended = lane['rec'] == true;
        final IconData icon = lane['icon'] as IconData;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isRecommended ? textColor.withAlpha((255 * 0.18).round()) : textColor.withAlpha((255 * 0.08).round()),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isRecommended ? textColor : textColor.withAlpha((255 * 0.5).round()), width: isRecommended ? 1.5 : 1.0),
          ),
          child: Icon(icon, size: 16, color: textColor),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _deriveLanesFromStep(NavigationStep step) {
    // Heuristic lane guidance based on modifier and type when lane data is unavailable
    // We present 3 lanes where the middle/left/right is recommended depending on modifier
    final String? modifier = step.modifier;
    if (modifier == null) return [];
    const IconData left = Icons.turn_left;
    const IconData straight = Icons.straight;
    const IconData right = Icons.turn_right;
    final lanes = [
      {'icon': left, 'rec': modifier.contains('left')},
      {'icon': straight, 'rec': modifier.contains('straight') || modifier == 'slight left' || modifier == 'slight right'},
      {'icon': right, 'rec': modifier.contains('right')},
    ];
    return lanes;
  }

  IconData _getInstructionIcon(NavigationStep step) {
    switch (step.type) {
      case 'turn':
        switch (step.modifier) {
          case 'left':
            return Icons.arrow_back;
          case 'right':
            return Icons.arrow_forward;
          case 'slight left':
            return Icons.arrow_back;
          case 'slight right':
            return Icons.arrow_forward;
          case 'sharp left':
            return Icons.arrow_back;
          case 'sharp right':
            return Icons.arrow_forward;
          case 'uturn':
            return Icons.refresh;
          default:
            return Icons.arrow_forward;
        }
      case 'arrive':
        return Icons.location_on;
      case 'depart':
        return Icons.directions_car;
      case 'merge':
        return Icons.arrow_forward;
      case 'exit':
        return Icons.arrow_forward;
      default:
        return Icons.navigation;
    }
  }
}
