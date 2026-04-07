import 'package:flutter/material.dart';
import 'package:nabour_app/voice/states/voice_interaction_states.dart';
import 'package:nabour_app/l10n/app_localizations.dart';

/// 🎨 Overlay vizual pentru feedback AI vocal
/// 
/// Afișează:
/// - 🟢 VERDE când AI vorbește (utilizatorul ascultă)
/// - 🔴 ROȘU când AI ascultă (utilizatorul vorbește)
/// - 🟡 GALBEN când AI procesează
class AIVoiceVisualFeedback extends StatefulWidget {
  final VoiceProcessingState state;
  final String? message;
  final VoidCallback? onClose;
  
  const AIVoiceVisualFeedback({
    super.key,
    required this.state,
    this.message,
    this.onClose,
  });

  @override
  State<AIVoiceVisualFeedback> createState() => _AIVoiceVisualFeedbackState();
}

class _AIVoiceVisualFeedbackState extends State<AIVoiceVisualFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Determină culoarea și mesajul în funcție de stare
    Color backgroundColor;
    IconData icon;
    String statusText;
    
    switch (widget.state) {
      case VoiceProcessingState.speaking:
        backgroundColor = Colors.green.withValues(alpha: 0.85);
        icon = Icons.volume_up;
        statusText = l10n.aiSpeaking;
        break;
        
      case VoiceProcessingState.listening:
        backgroundColor = Colors.red.withValues(alpha: 0.85);
        icon = Icons.mic;
        statusText = l10n.aiListening;
        break;
        
      case VoiceProcessingState.thinking:
        backgroundColor = Colors.orange.withValues(alpha: 0.85);
        icon = Icons.psychology;
        statusText = l10n.aiProcessing;
        break;
        
      case VoiceProcessingState.waiting:
        backgroundColor = Colors.blue.withValues(alpha: 0.85);
        icon = Icons.hourglass_empty;
        statusText = l10n.waitingResponse;
        break;
        
      case VoiceProcessingState.waitingForConfirmation:
        backgroundColor = Colors.purple.withValues(alpha: 0.85);
        icon = Icons.help_outline;
        statusText = l10n.waitingConfirmation;
        break;
        
      case VoiceProcessingState.idle:
      default:
        // Nu afișăm overlay când e idle
        return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: backgroundColor,
        child: SafeArea(
          child: Stack(
            children: [
              // Conținut principal
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon animat
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              icon,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Text status
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Mesaj suplimentar
                    if (widget.message != null && widget.message!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          widget.message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 40),
                    
                    // Indicator vizual pentru pulsație
                    if (widget.state == VoiceProcessingState.listening ||
                        widget.state == VoiceProcessingState.speaking)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 60,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: 0.3 + (0.7 * _pulseController.value),
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              
              // ✅ FIX: Buton de închidere - ÎNTOTDEAUNA VIZIBIL (chiar și în listening/speaking)
              if (widget.onClose != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 32),
                      onPressed: widget.onClose,
                      tooltip: 'Închide AI',
                      // ✅ FIX: Butonul este întotdeauna funcțional, chiar și când AI vorbește sau ascultă
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎨 Widget compact pentru feedback în widget-uri mici
class AIVoiceCompactIndicator extends StatelessWidget {
  final VoiceProcessingState state;
  final double size;
  
  const AIVoiceCompactIndicator({
    super.key,
    required this.state,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (state) {
      case VoiceProcessingState.speaking:
        color = Colors.green;
        icon = Icons.volume_up;
        break;
      case VoiceProcessingState.listening:
        color = Colors.red;
        icon = Icons.mic;
        break;
      case VoiceProcessingState.thinking:
        color = Colors.orange;
        icon = Icons.psychology;
        break;
      default:
        color = Colors.blue;
        icon = Icons.mic_none;
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}

