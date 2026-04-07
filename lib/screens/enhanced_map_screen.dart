import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../voice/states/voice_interaction_states.dart';
import '../voice/passenger/passenger_voice_controller_adapter.dart';


class EnhancedMapScreen extends StatefulWidget {
  const EnhancedMapScreen({super.key});

  @override
  State<EnhancedMapScreen> createState() => _EnhancedMapScreenState();
}

class _EnhancedMapScreenState extends State<EnhancedMapScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isVoiceActive = false;
  bool _isListening = false;
  bool _showConversationHistory = false;
  bool _showVoiceControls = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeVoice();
  }
  
  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }
  
  Future<void> _initializeVoice() async {
    final voiceController = context.read<PassengerVoiceControllerAdapter>();
    await voiceController.initializeVoiceSystem();
    if (!mounted) return;
    
    // Considerăm că inițializarea a avut succes dacă nu a apărut o eroare
    _safeSetState(() => _isVoiceActive = true);
    if (mounted) {
      _showVoicePermissionDialog();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PassengerVoiceControllerAdapter>(
        builder: (context, voiceController, child) {
          return Stack(
            children: [
              // EXISTING MAP WIDGET - Optimized with RepaintBoundary
              RepaintBoundary(
                child: _buildMapView(),
              ),
              
              // *** OVERLAY-UL PRINCIPAL - ACESTA LIPSEA! ***
              if (voiceController.isOverlayVisible)
                RepaintBoundary(
                  child: _buildMainVoiceOverlay(voiceController),
                ),
              
              // OTHER OVERLAYS...
              if (_showConversationHistory) 
                RepaintBoundary(
                  child: _buildConversationHistoryOverlay(voiceController),
                ),
              
              if (_showVoiceControls) 
                RepaintBoundary(
                  child: _buildVoiceControlsOverlay(voiceController),
                ),
              
              // VOICE MICROPHONE BUTTON - Optimized with RepaintBoundary
              RepaintBoundary(
                child: _buildVoiceMicrophoneButton(),
              ),
              
              // TOP CONTROLS - Optimized with RepaintBoundary
              RepaintBoundary(
                child: _buildTopControls(voiceController),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildMapView() {
    // Return your existing MapBox or Google Maps widget
    // For now, showing a placeholder
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 20),
            Text(
              'Map View\n(Your existing map implementation)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Text(
              '🎤 Tap the microphone button to start voice booking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.blue[600]),
            ),
            const SizedBox(height: 10),
            Text(
              '🔊 Say "Hey Nabour" to activate voice control',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.green[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(PassengerVoiceControllerAdapter voiceController) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: Row(
        children: [
          // Voice Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isVoiceActive ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isVoiceActive ? Icons.mic : Icons.mic_off,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _isVoiceActive ? 'Voice ON' : 'Voice OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Voice Controls Toggle
          IconButton(
                         onPressed: () {
               _safeSetState(() {
                 _showVoiceControls = !_showVoiceControls;
               });
             },
            icon: Icon(
              _showVoiceControls ? Icons.settings : Icons.settings_outlined,
              color: Colors.blue,
            ),
            tooltip: 'Voice Settings',
          ),
          
          // Conversation History Toggle
          IconButton(
                         onPressed: () {
               _safeSetState(() {
                 _showConversationHistory = !_showConversationHistory;
               });
             },
            icon: Icon(
              _showConversationHistory ? Icons.history : Icons.history_outlined,
              color: Colors.orange,
            ),
            tooltip: 'Conversation History',
          ),
        ],
      ),
    );
  }
  
  Widget _buildVoiceMicrophoneButton() {
    return Consumer<PassengerVoiceControllerAdapter>(
      builder: (context, voiceController, child) {
        final isListening = _isListening || voiceController.state == RideFlowState.listeningForInitialCommand;
        
        return Positioned(
          bottom: 100,
          right: 20,
          child: Column(
            children: [
              // Detectarea "salut" Status
              if (voiceController.isWakeWordEnabled)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(204),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hearing, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Ascult pentru "salut"',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Main Microphone Button
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isListening ? _pulseAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: _isVoiceActive ? () => _handleVoiceButtonTap(voiceController) : null,
                      onLongPress: () => _showVoiceOptions(voiceController),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: isListening 
                            ? Colors.red 
                            : _isVoiceActive 
                              ? Colors.blue 
                              : Colors.grey,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isListening ? Colors.red : Colors.blue)
                                  .withAlpha(77),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Voice Status Text
              if (isListening)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(230),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Vă ascult...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceControlsOverlay(PassengerVoiceControllerAdapter voiceController) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎤 Voice Controls',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              
              // Detectarea "salut" Toggle
              SwitchListTile(
                title: const Text('Detectarea "salut"'),
                subtitle: const Text('Ascult pentru "salut"'),
                value: voiceController.isWakeWordEnabled,
                onChanged: (value) {
                  if (value) {
                    voiceController.enableWakeWordDetection();
                  } else {
                    voiceController.toggleWakeWord();
                  }
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              // Continuous Listening Toggle
              SwitchListTile(
                title: const Text('Continuous Listening'),
                subtitle: const Text('Always listen for commands'),
                value: voiceController.isContinuousListening,
                onChanged: (value) {
                  voiceController.toggleContinuousListening();
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              const Divider(),
              
              // Voice Commands Help
              ListTile(
                leading: const Icon(Icons.help, color: Colors.orange),
                title: const Text('Voice Commands Help'),
                onTap: () => _showVoiceCommandsHelp(),
                contentPadding: EdgeInsets.zero,
              ),
              
              // Test Voice
              ListTile(
                leading: const Icon(Icons.mic, color: Colors.green),
                title: const Text('Test Voice System'),
                onTap: () => _testVoiceSystem(voiceController),
                contentPadding: EdgeInsets.zero,
              ),
              
              // Error Recovery
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.blue),
                title: const Text('Recover from Error'),
                onTap: () => voiceController.recoverFromError(),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationHistoryOverlay(PassengerVoiceControllerAdapter voiceController) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Conversation History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                                         onPressed: () {
                       _safeSetState(() {
                         _showConversationHistory = false;
                       });
                     },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: voiceController.conversationHistory.isEmpty
                    ? Center(
                        child: Text(
                          'No conversation history yet.\nStart talking to see it here!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: voiceController.conversationHistory.length,
                        itemBuilder: (context, index) {
                          final message = voiceController.conversationHistory[index];
                          final isUser = message.startsWith('User:');
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue[50] : Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isUser ? Colors.blue[200]! : Colors.green[200]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isUser ? Icons.person : Icons.smart_toy,
                                  color: isUser ? Colors.blue : Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    message.substring(message.indexOf(':') + 1).trim(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  

  

  

  
  Future<void> _handleVoiceButtonTap(PassengerVoiceControllerAdapter voiceController) async {
    if (voiceController.state == RideFlowState.listeningForInitialCommand || !mounted) return;
    
    _safeSetState(() => _isListening = true);
    _pulseController.repeat(reverse: true);
    
    try {
      await voiceController.startVoiceBooking();
    } catch (e) {
      // ✅ CALL METHOD INSTEAD OF USING CONTEXT DIRECTLY
      _handleVoiceError(e.toString());
    } finally {
      _safeSetState(() => _isListening = false);
      _pulseController.stop();
    }
  }

  void _showVoiceOptions(PassengerVoiceControllerAdapter voiceController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: SingleChildScrollView(
          child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎤 Voice Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.hearing, color: Colors.blue),
              title: const Text('Detectarea "salut"'),
              subtitle: Text(voiceController.isWakeWordEnabled ? 'Activată' : 'Dezactivată'),
              onTap: () {
                Navigator.pop(context);
                voiceController.toggleWakeWord();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.mic, color: Colors.green),
              title: const Text('Continuous Listening'),
              subtitle: Text(voiceController.isContinuousListening ? 'Enabled' : 'Disabled'),
              onTap: () {
                Navigator.pop(context);
                voiceController.toggleContinuousListening();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.help, color: Colors.orange),
              title: const Text('Voice Commands Help'),
              onTap: () {
                Navigator.pop(context);
                _showVoiceCommandsHelp();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Voice Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/voice-settings');
              },
            ),
          ],
        ),
      ),
    ),
  ),
    );
  }

  void _showVoiceCommandsHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎤 Voice Commands Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Basic Commands:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• "Vreau o cursă la [destinație]"'),
              Text('• "Cursă economică la [destinație]"'),
              Text('• "Cursă urgentă la [destinație]"'),
              Text('• "Cursă premium la [destinație]"'),
              SizedBox(height: 16),
              Text('During Ride:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• "Trimite mesaj șoferului"'),
              Text('• "Unde este șoferul?"'),
              Text('• "Anulează cursa"'),
              Text('• "Vreau să plătesc cash"'),
              SizedBox(height: 16),
              Text('Voice Control:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• "salut" (cuvânt de activare)'),
              Text('• "Ajutor" (show this help)'),
              Text('• "Anulează" (cancel current operation)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _testVoiceSystem(PassengerVoiceControllerAdapter voiceController) async {
    try {
      await voiceController.voice.speak("Testez sistemul vocal. Dacă auziți această frază, sistemul funcționează corect!");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice system test completed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice system test failed: $e')),
        );
      }
    }
  }
  
  void _showVoicePermissionDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🎤 Control Vocal'),
        content: const Text(
          'Pentru experiența hands-free, activați permisiunile pentru microfon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Mai târziu'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // You can add permission handling here
            },
            child: const Text('Activează'),
          ),
        ],
      ),
    );
  }
  
  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }



  void _handleVoiceError(String error) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eroare voice: $error'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Încearcă din nou',
          onPressed: () {
            if (mounted) {
              _handleVoiceButtonTap(context.read<PassengerVoiceControllerAdapter>());
            }
          },
        ),
      ),
    );
  }



  // *** OVERLAY-UL PRINCIPAL CARE LIPSEA - ACESTA REZOLVĂ PROBLEMA! ***
  Widget _buildMainVoiceOverlay(PassengerVoiceControllerAdapter voiceController) {
    return Positioned.fill(
      child: GestureDetector(
        // *** CRUCIAL: Tap pe tot overlay-ul pentru a închide ***
        onTap: () {
          voiceController.stopVoiceInteraction();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withAlpha(179), // Semi-transparent background
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(77),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // *** HEADER CU BUTON DE ÎNCHIDERE ***
                  Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.blue, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Asistent Vocal Nabour',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      // *** BUTON X PENTRU ÎNCHIDERE ***
                      IconButton(
                        onPressed: () {
                                          voiceController.stopVoiceInteraction();
                        },
                        icon: const Icon(Icons.close),
                        tooltip: 'Închide',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // *** INDICATOR VIZUAL PENTRU PROCESING STATE ***
                  _buildProcessingStateIndicator(voiceController),
                  
                  const SizedBox(height: 16),
                  
                  // *** RĂSPUNSUL AI-ULUI ***
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      voiceController.aiResponse,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // *** BUTOANE DE ACȚIUNE ***
                  _buildActionButtons(voiceController),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // *** INDICATOR PENTRU STAREA DE PROCESARE ***
  Widget _buildProcessingStateIndicator(PassengerVoiceControllerAdapter voiceController) {
    switch (voiceController.processingState) {
      case VoiceProcessingState.listening:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              strokeWidth: 3,
            ),
            SizedBox(width: 12),
            Text(
              'Vă ascult...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        );
        
      case VoiceProcessingState.thinking:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          strokeWidth: 3,
            ),
            SizedBox(width: 12),
            Text(
              'Procesez...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ],
        );
        
      case VoiceProcessingState.speaking:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volume_up, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Text(
              'Vă răspund...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ],
        );
        
      case VoiceProcessingState.idle:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Gata să vă ascult',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
        
      case VoiceProcessingState.waiting:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              strokeWidth: 3,
            ),
            SizedBox(width: 12),
            Text(
              'Aștept...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        );
        
      case VoiceProcessingState.waitingForConfirmation:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              strokeWidth: 3,
            ),
            SizedBox(width: 12),
            Text(
              'Aștept confirmarea...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.purple,
              ),
            ),
          ],
        );
        
      case VoiceProcessingState.confirmationReceived:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Text(
              'Confirmarea primită',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ],
        );
        
      case VoiceProcessingState.error:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Text(
              'Eroare',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        );
    }
  }

  // *** BUTOANE DE ACȚIUNE CU ÎNCHIDERE ***
  Widget _buildActionButtons(PassengerVoiceControllerAdapter voiceController) {
    return Row(
      children: [
        // *** BUTON DE ANULARE/ÎNCHIDERE ***
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              voiceController.stopVoiceInteraction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close, size: 18),
                SizedBox(width: 6),
                Text('Închide'),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // *** BUTON DE RESTART ***
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              voiceController.reset();
              voiceController.startVoiceInteraction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 18),
                SizedBox(width: 6),
                Text('Reîncearcă'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
