import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'map_voice_controller.dart';

class MapVoiceOverlay extends StatelessWidget {
  const MapVoiceOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MapVoiceController>();
    
    if (controller.state == VoiceAssistantState.idle) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              border: Border.all(
                color: _getStateColor(controller.state).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(controller),
                const SizedBox(height: 24),
                _buildFeedback(controller),
                const SizedBox(height: 24),
                _buildVisualizer(controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MapVoiceController controller) {
    return Row(
      children: [
        Icon(
          _getStateIcon(controller.state),
          color: _getStateColor(controller.state),
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          _getStateLabel(controller.state),
          style: TextStyle(
            color: _getStateColor(controller.state),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => controller.stopListening(),
        ),
      ],
    );
  }

  Widget _buildFeedback(MapVoiceController controller) {
    return Text(
      controller.feedbackMessage,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        height: 1.5,
      ),
    );
  }

  Widget _buildVisualizer(MapVoiceController controller) {
    if (controller.state == VoiceAssistantState.processing) {
      return const LinearProgressIndicator(
        backgroundColor: Colors.white10,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
      );
    }
    
    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _getStateColor(controller.state).withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getStateColor(VoiceAssistantState state) {
    switch (state) {
      case VoiceAssistantState.listening: return Colors.cyanAccent;
      case VoiceAssistantState.processing: return Colors.orangeAccent;
      case VoiceAssistantState.success: return Colors.greenAccent;
      case VoiceAssistantState.error: return Colors.redAccent;
      default: return Colors.white54;
    }
  }

  IconData _getStateIcon(VoiceAssistantState state) {
    switch (state) {
      case VoiceAssistantState.listening: return Icons.mic;
      case VoiceAssistantState.processing: return Icons.auto_awesome;
      case VoiceAssistantState.success: return Icons.check_circle_outline;
      case VoiceAssistantState.error: return Icons.error_outline;
      default: return Icons.blur_on;
    }
  }

  String _getStateLabel(VoiceAssistantState state) {
    switch (state) {
      case VoiceAssistantState.listening: return "ASCULT...";
      case VoiceAssistantState.processing: return "PROCESEZ...";
      case VoiceAssistantState.success: return "SUCCES";
      case VoiceAssistantState.error: return "EROARE";
      default: return "";
    }
  }
}
