import 'package:flutter/material.dart';
import 'package:nabour_app/voice/states/voice_interaction_states.dart';
import 'package:nabour_app/utils/logger.dart';

class DraggableAIButton extends StatefulWidget {
  final VoidCallback? onTap;
  final VoiceProcessingState? processingState;
  
  const DraggableAIButton({
    super.key, 
    this.onTap,
    this.processingState,
  });

  @override
  State<DraggableAIButton> createState() => _DraggableAIButtonState();
}

class _DraggableAIButtonState extends State<DraggableAIButton> {
  late Offset _position;
  bool _isDragging = false;
  Offset _startPanPosition = Offset.zero;
  
  @override
  void initState() {
    super.initState();
    _position = const Offset(300, 300);
    Logger.debug('DEBUG: DraggableAIButton inițializat la poziția: $_position');
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    final safeX = _position.dx.clamp(0.0, screenSize.width - 60);
    final safeY = _position.dy.clamp(50.0, screenSize.height - 120);
    
    return Positioned(
      left: safeX,
      top: safeY,
      child: GestureDetector(
        onPanStart: (details) {
          Logger.debug('DEBUG: Pan start detectat');
          _isDragging = false;
          _startPanPosition = details.globalPosition;
        },
        onPanUpdate: (details) {
          // Detectează dacă e drag sau tap
          final distance = (details.globalPosition - _startPanPosition).distance;
          if (distance > 5.0) { // threshold pentru drag
            _isDragging = true;
            setState(() {
              _position = Offset(
                (_position.dx + details.delta.dx).clamp(0.0, screenSize.width - 60),
                (_position.dy + details.delta.dy).clamp(50.0, screenSize.height - 120),
              );
            });
          }
        },
        onPanEnd: (details) {
          Logger.debug('DEBUG: Pan end - isDragging: $_isDragging');
          if (!_isDragging) {
            // A fost tap, nu drag
            Logger.debug('DEBUG: TAP DETECTAT! Apelează callback');
            if (widget.onTap != null) {
              widget.onTap!();
              Logger.debug('DEBUG: Callback executat!');
            } else {
              Logger.debug('DEBUG: Nu există callback!');
            }
          }
          _isDragging = false;
        },
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    // Determină culoarea în funcție de starea de procesare
    Color buttonColor;
    IconData buttonIcon;
    
    switch (widget.processingState) {
      case VoiceProcessingState.speaking:
        buttonColor = Colors.green; // Verde când AI-ul vorbește
        buttonIcon = Icons.volume_up;
        break;
      case VoiceProcessingState.listening:
        buttonColor = Colors.red; // Roșu când AI-ul ascultă
        buttonIcon = Icons.mic;
        break;
      case VoiceProcessingState.thinking:
        buttonColor = Colors.orange; // Portocaliu când AI-ul procesează
        buttonIcon = Icons.psychology;
        break;
      case VoiceProcessingState.waiting:
        buttonColor = Colors.yellow; // Galben când așteaptă
        buttonIcon = Icons.hourglass_empty;
        break;
      case VoiceProcessingState.waitingForConfirmation:
        buttonColor = Colors.purple; // Violet când așteaptă confirmarea
        buttonIcon = Icons.question_answer;
        break;
      case VoiceProcessingState.confirmationReceived:
        buttonColor = Colors.green; // Verde când confirmarea e primită
        buttonIcon = Icons.check_circle;
        break;
      case VoiceProcessingState.idle:
      default:
        buttonColor = Colors.blue; // Albastru când este inactiv
        buttonIcon = Icons.mic;
        break;
    }
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: buttonColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              buttonIcon,
              color: Colors.white,
              size: 24,
            ),
            const Text(
              'AI',
              style: TextStyle(
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
}
