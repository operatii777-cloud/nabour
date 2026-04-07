import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nabour_app/voice/core/voice_orchestrator.dart';
import 'package:nabour_app/voice/states/voice_interaction_states.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:nabour_app/voice/integration/friendsride_voice_integration.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🎤 VoiceInputButton - Buton reutilizabil pentru input vocal în câmpurile de adrese
/// 
/// Integrează cu VoiceOrchestrator-ul existent pentru a oferi funcționalitate STT
/// fără a crea servicii noi sau a duplica codul
class VoiceInputButton extends StatefulWidget {
  /// Callback-ul pentru rezultatul recunoașterii vocale
  final Function(String) onSpeechResult;
  
  /// Callback-ul pentru erorile de recunoaștere
  final Function(String)? onSpeechError;
  
  /// Callback-ul pentru schimbările de stare
  final Function(VoiceProcessingState)? onStateChange;
  
  /// Textul de hint pentru utilizator
  final String? hintText;
  
  /// Culoarea butonului când nu este activ
  final Color? inactiveColor;
  
  /// Culoarea butonului când înregistrează
  final Color? activeColor;
  
  /// Dimensiunea butonului
  final double size;
  
  /// Timeout-ul pentru înregistrare (în secunde)
  final int timeoutSeconds;

  const VoiceInputButton({
    super.key,
    required this.onSpeechResult,
    this.onSpeechError,
    this.onStateChange,
    this.hintText,
    this.inactiveColor,
    this.activeColor,
    this.size = 40.0,
    this.timeoutSeconds = 10,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with TickerProviderStateMixin {
  // 🚀 SINGLETON: Refolosește instanța globală pentru performanță
  final VoiceOrchestrator _voiceOrchestrator = VoiceOrchestrator();
  late final AnimationController _pulseController;
  late final AnimationController _colorController;
  
  bool _isListening = false;
  bool _isInitialized = false;
  bool _hasPermission = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // 🚀 Defer initialization to avoid blocking first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeVoice();
    });
  }

  @override
  void dispose() {
    // Înlocuiește callback-urile cu no-op pentru a evita setState după dispose
    _voiceOrchestrator.setSpeechResultCallback((_) {});
    _voiceOrchestrator.setSpeechErrorCallback((_) {});
    _voiceOrchestrator.setStateChangeCallback((_) {});
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  /// 🚀 Inițializează sistemul vocal
  Future<void> _initializeVoice() async {
    try {
      // Verifică permisiunile pentru microfon
      final permissionStatus = await Permission.microphone.status;
      
      if (permissionStatus.isDenied) {
        final result = await Permission.microphone.request();
        if (result.isDenied) {
          _showError('Permisiunea pentru microfon a fost refuzată');
          return;
        }
      }
      
      if (permissionStatus.isPermanentlyDenied) {
        _showError('Permisiunea pentru microfon este permanent refuzată. Mergi la Setări → Aplicații → Nabour → Permisiuni → Microfon');
        return;
      }
      
      if (permissionStatus.isGranted) {
        _hasPermission = true;
        
        // Inițializează VoiceOrchestrator-ul
        await _voiceOrchestrator.initialize();
        
        // Setează callback-urile
        _voiceOrchestrator.setSpeechResultCallback(_onSpeechResult);
        _voiceOrchestrator.setSpeechErrorCallback(_onSpeechError);
        _voiceOrchestrator.setStateChangeCallback(_onStateChange);
        
        _isInitialized = true;
        if (!mounted) return;
        setState(() {});

        Logger.info('VoiceInputButton: Initialized successfully');
      }
    } catch (e) {
      Logger.error('VoiceInputButton: Initialization error: $e', error: e);
      _showError('Eroare la inițializarea sistemului vocal: $e');
    }
  }

  /// 🎤 Gestionează rezultatul recunoașterii vocale
  void _onSpeechResult(String result) {
    if (mounted) {
      setState(() {
        _isListening = false;
        _statusMessage = '✅ Text recunoscut';
      });
      
      // Oprește animațiile
      _pulseController.stop();
      _colorController.reverse();
      
      // Trimite rezultatul către parent
      widget.onSpeechResult(result);
      
      // Curăță mesajul după 2 secunde
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    }
  }

  /// ❌ Gestionează erorile de recunoaștere
  void _onSpeechError(String error) {
    if (mounted) {
      setState(() {
        _isListening = false;
        _statusMessage = '❌ Eroare: $error';
      });
      
      // Oprește animațiile
      _pulseController.stop();
      _colorController.reverse();
      
      // Trimite eroarea către parent dacă există callback
      widget.onSpeechError?.call(error);
      
      // Curăță mesajul după 3 secunde
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    }
  }

  /// 🔄 Gestionează schimbările de stare
  void _onStateChange(VoiceProcessingState state) {
    if (mounted) {
      setState(() {
        switch (state) {
          case VoiceProcessingState.listening:
            _isListening = true;
            _statusMessage = '🎤 Ascult...';
            break;
          case VoiceProcessingState.thinking:
            _isListening = false;
            _statusMessage = '🧠 Procesez...';
            break;
          case VoiceProcessingState.speaking:
            _isListening = false;
            _statusMessage = '🗣️ Vorbesc...';
            break;
          case VoiceProcessingState.waiting:
            _isListening = false;
            _statusMessage = '⏳ Aștept...';
            break;
          case VoiceProcessingState.waitingForConfirmation:
            _isListening = false;
            _statusMessage = '⏳ Aștept confirmarea...';
            break;
          case VoiceProcessingState.confirmationReceived:
            _isListening = false;
            _statusMessage = '✅ Confirmarea primită';
            break;
          case VoiceProcessingState.error:
            _isListening = false;
            _statusMessage = '❌ Eroare';
            break;
          case VoiceProcessingState.idle:
            _isListening = false;
            _statusMessage = '';
            break;
        }
      });
      
      // Actualizează animațiile
      if (_isListening) {
        _pulseController.repeat();
        _colorController.forward();
      } else {
        _pulseController.stop();
        _colorController.reverse();
      }
    }
    
    // Trimite starea către parent dacă există callback
    widget.onStateChange?.call(state);
  }

  /// 🎤 Pornește înregistrarea vocală
  Future<void> _startListening() async {
    if (!_isInitialized || !_hasPermission) {
      _showError('Sistemul vocal nu este inițializat sau nu ai permisiuni');
      return;
    }

    if (_isListening) {
      await _stopListening();
      return;
    }

    try {
      setState(() {
        _statusMessage = '🎤 Pornește înregistrarea...';
      });

      // Pornește înregistrarea cu VoiceOrchestrator-ul
      await _voiceOrchestrator.listen(
        timeoutSeconds: widget.timeoutSeconds,
      );

      // Animațiile vor fi pornite prin callback-ul de stare
    } catch (e) {
      Logger.error('VoiceInputButton: Start listening error: $e', error: e);
      _showError('Eroare la pornirea înregistrării: $e');
    }
  }

  /// 🛑 Oprește înregistrarea vocală
  Future<void> _stopListening() async {
    try {
      await _voiceOrchestrator.stopListening();
      
      setState(() {
        _isListening = false;
        _statusMessage = '🛑 Înregistrarea oprită';
      });
      
      // Oprește animațiile
      _pulseController.stop();
      _colorController.reverse();
      
      // Curăță mesajul după 2 secunde
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    } catch (e) {
      Logger.error('VoiceInputButton: Stop listening error: $e', error: e);
    }
  }

  /// ❌ Afișează o eroare
  void _showError(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
      
      // Curăță mesajul după 3 secunde
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = widget.inactiveColor ?? theme.primaryColor;
    final activeColor = widget.activeColor ?? Colors.red;
    FriendsRideVoiceIntegration? voiceIntegration;
    bool externalReady = false;
    bool externalInitializing = false;
    try {
      voiceIntegration = Provider.of<FriendsRideVoiceIntegration>(context);
      externalReady = voiceIntegration.isInitialized;
      externalInitializing = voiceIntegration.isInitializing && !externalReady;
    } catch (_) {
      // Provider not found; fallback to internal state only
    }
    final bool isReady = (_isInitialized && _hasPermission) || externalReady;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Butonul principal cu microfon
        AnimatedBuilder(
          animation: _colorController,
          builder: (context, child) {
            final currentColor = Color.lerp(inactiveColor, activeColor, _colorController.value);
            
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _isListening 
                    ? 1.0 + (0.1 * _pulseController.value)
                    : 1.0;
                
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: isReady ? currentColor : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: _isListening ? [
                        BoxShadow(
                          color: currentColor?.withValues(alpha: 0.3) ?? Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: widget.size * 0.5,
                      ),
                      onPressed: isReady ? _startListening : null,
                      tooltip: _isListening 
                          ? 'Oprește înregistrarea' 
                          : (externalInitializing ? 'Se inițializează serviciile vocale…' : 'Începe înregistrarea vocală'),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                );
              },
            );
          },
        ),
        
        // Mesajul de stare
        if (_statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _statusMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _isListening ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        
        // Indicator subtil când serviciile se inițializează în fundal
        if (!isReady && externalInitializing)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade500),
              ),
            ),
          ),

        // Hint text dacă există
        if (widget.hintText != null && !_isListening)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.hintText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
  /// 👆 Callback pentru tap (alias pentru onPressed)
  void onTap() {
    _startListening();
  }
  
    /// 👆👆 Callback pentru long press
  void onLongPress() {
    _stopListening();
  }
  
  }
