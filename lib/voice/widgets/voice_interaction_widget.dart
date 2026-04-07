import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main_voice_integration.dart';
import '../states/voice_interaction_states.dart';

/// 🎯 Voice Interaction Widget - Widget-ul UI pentru interacțiunea vocală
/// 
/// Caracteristici:
/// - Integrare perfectă cu UI-ul Nabour
/// - Display pentru stările vocale
/// - Butoane pentru controlul vocal
/// - Feedback vizual în timp real
class VoiceInteractionWidget extends StatelessWidget {
  const VoiceInteractionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MainVoiceIntegration>(
      builder: (context, voiceIntegration, child) {
        final context = voiceIntegration.currentContext;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎯 Header cu starea curentă
              _buildHeader(context),
              
              const SizedBox(height: 16),
              
              // 🎤 Butoane de control
              _buildControlButtons(voiceIntegration),
              
              const SizedBox(height: 16),
              
              // 📝 Istoricul conversației
              _buildConversationHistory(context),
              
              const SizedBox(height: 16),
              
              // 🚗 Informații despre cursă
              _buildRideInfo(context),
            ],
          ),
        );
      },
    );
  }
  
  /// 🎯 Construiește header-ul cu starea curentă
  Widget _buildHeader(VoiceConversationContext context) {
    return Row(
      children: [
        // 🎤 Icon pentru starea vocală
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStateColor(context.processingState),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStateIcon(context.processingState),
            color: Colors.white,
            size: 20,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // 📝 Text cu starea curentă
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.stateDescription,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Starea: ${context.processingState.toString().split('.').last}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // 🎭 Emoția vocală
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _getEmotionColor(context.currentEmotion),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            _getEmotionIcon(context.currentEmotion),
            color: Colors.white,
            size: 16,
          ),
        ),
      ],
    );
  }
  
  /// 🎤 Construiește butoanele de control
  Widget _buildControlButtons(MainVoiceIntegration voiceIntegration) {
    return Row(
      children: [
        // 🎤 Buton pentru începerea interacțiunii
        Expanded(
          child: ElevatedButton.icon(
            onPressed: voiceIntegration.isInitialized
                ? () => voiceIntegration.startVoiceInteraction()
                : null,
            icon: const Icon(Icons.mic),
            label: const Text('Începe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // 🛑 Buton pentru oprirea interacțiunii
        Expanded(
          child: ElevatedButton.icon(
            onPressed: voiceIntegration.isInitialized
                ? () => voiceIntegration.stopVoiceInteraction()
                : null,
            icon: const Icon(Icons.stop),
            label: const Text('Oprește'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 📝 Construiește istoricul conversației
  Widget _buildConversationHistory(VoiceConversationContext voiceContext) {
    if (voiceContext.conversationHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Încă nu există conversații',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: voiceContext.conversationHistory.length,
        itemBuilder: (context, index) {
          final message = voiceContext.conversationHistory[index];
          final isUser = message.startsWith('User:');
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  isUser ? Icons.person : Icons.smart_toy,
                  size: 16,
                  color: isUser ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUser ? Colors.blue[700] : Colors.green[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// 🚗 Construiește informațiile despre cursă
  Widget _buildRideInfo(VoiceConversationContext voiceContext) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚗 Informații Cursă',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          
          // 🎯 Destinația
          if (voiceContext.currentDestination != null)
            _buildInfoRow('🎯 Destinația:', voiceContext.currentDestination!),
          
          // 🚗 Pickup-ul
          if (voiceContext.currentPickup != null)
            _buildInfoRow('🚗 Pickup:', voiceContext.currentPickup!),
          
          // 💰 Prețul
          if (voiceContext.estimatedPrice != null)
            _buildInfoRow('💰 Prețul:', '${voiceContext.estimatedPrice!.toInt()} lei'),
          
          // 🚗 Șoferii
          if (voiceContext.availableDrivers.isNotEmpty)
            _buildInfoRow('🚗 Șoferi:', '${voiceContext.availableDrivers.length} disponibili'),
          
          // 🎯 Starea cursei
          _buildInfoRow('🎯 Starea:', voiceContext.rideState.toString().split('.').last),
        ],
      ),
    );
  }
  
  /// 📝 Construiește o linie de informații
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 🎨 Obține culoarea pentru starea vocală
  Color _getStateColor(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.idle:
        return Colors.grey;
      case VoiceProcessingState.listening:
        return Colors.blue;
      case VoiceProcessingState.thinking:
        return Colors.orange;
      case VoiceProcessingState.speaking:
        return Colors.green;
      case VoiceProcessingState.waiting:
        return Colors.yellow;
      case VoiceProcessingState.waitingForConfirmation:
        return Colors.purple;
      case VoiceProcessingState.confirmationReceived:
        return Colors.green;
      case VoiceProcessingState.error:
        return Colors.red;
    }
  }
  
  /// 🎨 Obține icon-ul pentru starea vocală
  IconData _getStateIcon(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.idle:
        return Icons.mic_off;
      case VoiceProcessingState.listening:
        return Icons.mic;
      case VoiceProcessingState.thinking:
        return Icons.psychology;
      case VoiceProcessingState.speaking:
        return Icons.record_voice_over;
      case VoiceProcessingState.waiting:
        return Icons.hourglass_empty;
      case VoiceProcessingState.waitingForConfirmation:
        return Icons.question_answer;
      case VoiceProcessingState.confirmationReceived:
        return Icons.check_circle;
      case VoiceProcessingState.error:
        return Icons.error;
    }
  }
  
  /// 🎨 Obține culoarea pentru emoția vocală
  Color _getEmotionColor(VoiceEmotion emotion) {
    switch (emotion) {
      case VoiceEmotion.happy:
        return Colors.green;
      case VoiceEmotion.confident:
        return Colors.blue;
      case VoiceEmotion.calm:
        return Colors.teal;
      case VoiceEmotion.urgent:
        return Colors.red;
      case VoiceEmotion.curious:
        return Colors.orange;
      case VoiceEmotion.friendly:
        return Colors.lightGreen;
      case VoiceEmotion.direct:
        return Colors.indigo;
    }
  }
  
  /// 🎨 Obține icon-ul pentru emoția vocală
  IconData _getEmotionIcon(VoiceEmotion emotion) {
    switch (emotion) {
      case VoiceEmotion.happy:
        return Icons.sentiment_satisfied;
      case VoiceEmotion.confident:
        return Icons.psychology;
      case VoiceEmotion.calm:
        return Icons.sentiment_satisfied;
      case VoiceEmotion.urgent:
        return Icons.warning;
      case VoiceEmotion.curious:
        return Icons.help_outline;
      case VoiceEmotion.friendly:
        return Icons.sentiment_very_satisfied;
      case VoiceEmotion.direct:
        return Icons.arrow_forward;
    }
  }
}
