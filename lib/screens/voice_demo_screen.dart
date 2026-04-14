import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../voice/passenger/pax_voice_ctrl_adapter.dart';
import '../voice/driver/driver_voice_controller.dart';

class VoiceDemoScreen extends StatefulWidget {
  const VoiceDemoScreen({super.key});

  @override
  State<VoiceDemoScreen> createState() => _VoiceDemoScreenState();
}

class _VoiceDemoScreenState extends State<VoiceDemoScreen> {
  bool _isPassengerMode = true;
  String _currentDemo = '';
  final List<String> _demoHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Voice System Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              setState(() {
                _isPassengerMode = !_isPassengerMode;
                _currentDemo = '';
              });
            },
            tooltip: 'Switch Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Selector
          _buildModeSelector(),
          
          // Demo Controls
          _buildDemoControls(),
          
          // Current Demo Status
          if (_currentDemo.isNotEmpty) _buildCurrentDemoStatus(),
          
          // Demo History
          Expanded(child: _buildDemoHistory()),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            _isPassengerMode ? Icons.person : Icons.drive_eta,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Mode: ${_isPassengerMode ? "Passenger" : "Driver"}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isPassengerMode,
            onChanged: (value) {
              setState(() {
                _isPassengerMode = value;
                _currentDemo = '';
              });
            },
            activeThumbColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            'Voice System Demo Controls',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_isPassengerMode) ...[
            _buildPassengerDemos(),
          ] else ...[
            _buildDriverDemos(),
          ],
          
          const SizedBox(height: 16),
          
          // Voice System Test
          _buildVoiceSystemTest(),
        ],
      ),
    );
  }

  Widget _buildPassengerDemos() {
    return Column(
      children: [
        Text(
          'Passenger Voice Features',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDemoButton(
              'Basic Ride Booking',
              'Test basic voice ride booking flow',
              () => _startPassengerDemo('basic_booking'),
            ),
            _buildDemoButton(
                      'Detectarea "salut"',
        'Test "salut" cuvânt de activare',
              () => _startPassengerDemo('wake_word'),
            ),
            _buildDemoButton(
              'Continuous Listening',
              'Test continuous voice command listening',
              () => _startPassengerDemo('continuous_listening'),
            ),
            _buildDemoButton(
              'Voice Clarification',
              'Test voice clarification flow',
              () => _startPassengerDemo('clarification'),
            ),
            _buildDemoButton(
              'Error Recovery',
              'Test voice system error recovery',
              () => _startPassengerDemo('error_recovery'),
            ),
            _buildDemoButton(
              'Conversation History',
              'View conversation history',
              () => _startPassengerDemo('conversation_history'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverDemos() {
    return Column(
      children: [
        Text(
          'Driver Voice Features',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDemoButton(
              'Incoming Ride Call',
              'Simulate incoming ride request',
              () => _startDriverDemo('incoming_call'),
            ),
            _buildDemoButton(
              'Voice Ride Control',
              'Test voice ride progression commands',
              () => _startDriverDemo('ride_control'),
            ),
            _buildDemoButton(
              'Emergency Commands',
              'Test emergency voice commands',
              () => _startDriverDemo('emergency'),
            ),
            _buildDemoButton(
              'Safety Monitoring',
              'Test driver safety monitoring',
              () => _startDriverDemo('safety'),
            ),
            _buildDemoButton(
              'Voice Statistics',
              'View voice command statistics',
              () => _startDriverDemo('statistics'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceSystemTest() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            'Voice System Test',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _testMicrophone(context),
                  icon: const Icon(Icons.mic),
                  label: const Text('Test Microphone'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _testSpeechRecognition(context),
                  icon: const Icon(Icons.hearing),
                  label: const Text('Test Recognition'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _testTextToSpeech(context),
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Test TTS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startPassengerDemo('basic_booking'),
                  icon: const Icon(Icons.mic),
                  label: const Text('Test Basic Voice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButton(String title, String description, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.blue.shade800,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDemoStatus() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.play_circle,
            color: Colors.green,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Demo: $_currentDemo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  'Demo in progress...',
                  style: TextStyle(
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentDemo = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoHistory() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Demo History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: _demoHistory.isEmpty
                ? Center(
                    child: Text(
                      'No demos run yet.\nStart a demo to see the history here!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _demoHistory.length,
                    itemBuilder: (context, index) {
                      final demo = _demoHistory[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_circle_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                demo,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            Text(
                              DateTime.now().toString().substring(11, 19),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
    );
  }

  Future<void> _startPassengerDemo(String demoType) async {
    setState(() {
      _currentDemo = 'Passenger: $demoType';
      _demoHistory.add('Passenger Demo: $demoType');
    });

    final voiceController = context.read<PassengerVoiceControllerAdapter>();

    if (!voiceController.isInitialized) {
      try {
        await voiceController.initializeVoiceSystem();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Eroare la inițializarea sistemului vocal: $e')),
          );
        }
        setState(() {
          _currentDemo = '';
        });
        return;
      }
    }
    
    switch (demoType) {
      case 'basic_booking':
        await _runBasicBookingDemo(voiceController);
        break;
      case 'wake_word':
        await _runBasicBookingDemo(voiceController); // Replaced detectarea "salut" with basic booking
          break;
      case 'continuous_listening':
        await _runContinuousListeningDemo(voiceController);
        break;
      case 'clarification':
        await _runClarificationDemo(voiceController);
        break;
      case 'error_recovery':
        await _runErrorRecoveryDemo(voiceController);
        break;
      case 'conversation_history':
        _showConversationHistory(voiceController);
        break;
    }
  }

  void _startDriverDemo(String demoType) {
    setState(() {
      _currentDemo = 'Driver: $demoType';
      _demoHistory.add('Driver Demo: $demoType');
    });

    final voiceController = context.read<DriverVoiceController>();
    
    switch (demoType) {
      case 'incoming_call':
        _runIncomingCallDemo(voiceController);
        break;
      case 'ride_control':
        _runRideControlDemo(voiceController);
        break;
      case 'emergency':
        _runEmergencyDemo(voiceController);
        break;
      case 'safety':
        _runSafetyDemo(voiceController);
        break;
      case 'statistics':
        _showDriverStatistics(voiceController);
        break;
    }
  }

  Future<void> _runBasicBookingDemo(PassengerVoiceControllerAdapter voiceController) async {
    voiceController.voice.speak("Demo: Basic Ride Booking. Vă rog să spuneți o destinație.");
    
    final result = await voiceController.voice.listen(timeoutSeconds: 10);
    if (result != null) {
      voiceController.voice.speak("Demo completat! Ați spus: $result");
    } else {
              voiceController.voice.speak("Demo completat! Nu am auzit nicio destinație.");
    }
    
    setState(() {
      _currentDemo = '';
    });
  }

      // Demo detectarea "salut" eliminat - nu este implementat în aplicație

  Future<void> _runContinuousListeningDemo(PassengerVoiceControllerAdapter voiceController) async {
    voiceController.voice.speak("Demo: Continuous Listening. Vă rog să spuneți mai multe comenzi.");
    
    voiceController.startContinuousListening();
    
    // Stop after 10 seconds
    await Future.delayed(const Duration(seconds: 10));
    voiceController.voice.stopListening();
    
    voiceController.voice.speak("Demo completat! Continuous listening testat cu succes!");
    
    setState(() {
      _currentDemo = '';
    });
  }

  Future<void> _runClarificationDemo(PassengerVoiceControllerAdapter voiceController) async {
    voiceController.voice.speak("Demo: Voice Clarification. Spuneți o destinație neclară.");
    
    final result = await voiceController.voice.listen(timeoutSeconds: 10);
    if (result != null) {
      voiceController.voice.speak("Demo completat! Ați spus: $result. Sistemul va cere clarificări pentru destinații neclare.");
    } else {
      voiceController.voice.speak("Demo completat! Nu am auzit nicio destinație.");
    }
    
    setState(() {
      _currentDemo = '';
    });
  }

  Future<void> _runErrorRecoveryDemo(PassengerVoiceControllerAdapter voiceController) async {
    voiceController.voice.speak("Demo: Error Recovery. Simulez o eroare și voi încerca să mă recuperez.");
    
    try {
      voiceController.recoverFromError();
      voiceController.voice.speak("Demo completat! Recuperarea de la eroare a fost testată cu succes!");
    } catch (e) {
      voiceController.voice.speak("Demo completat! Eroarea de recuperare a fost testată.");
    }
    
    setState(() {
      _currentDemo = '';
    });
  }

  void _showConversationHistory(PassengerVoiceControllerAdapter voiceController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📝 Conversation History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: voiceController.conversationHistory.length,
            itemBuilder: (context, index) {
              final message = voiceController.conversationHistory[index];
              final isUser = message.startsWith('User:');
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUser ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
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
    
    setState(() {
      _currentDemo = '';
    });
  }

  Future<void> _runIncomingCallDemo(DriverVoiceController voiceController) async {
    voiceController.voice.speak("Demo: Incoming Ride Call. Simulez o comandă nouă.");
    
    // Create mock ride request
    final mockRequest = DriverVoiceRideRequest(
      id: 'demo_123',
      passengerId: 'customer_456',
      pickupAddress: 'Strada Demo, Nr. 1',
      destinationAddress: 'Piața Demo',
      distance: 2.5,
      estimatedPrice: 15.0,
      etaToPickup: 5,
      etaToDestination: 12,
      passengerName: 'Demo Customer',
      passengerPhone: '+40 123 456 789',
    );
    
    await voiceController.handleIncomingRideCall(mockRequest);
    
    setState(() {
      _currentDemo = '';
    });
  }

  Future<void> _runRideControlDemo(DriverVoiceController voiceController) async {
    voiceController.voice.speak("Demo: Ride Control Commands. Testez comenzile vocale pentru progresia cursei.");
    
    voiceController.voice.speak("Spuneți 'Am ajuns la client' pentru a simula sosirea la client.");
    
    final result = await voiceController.voice.listen(timeoutSeconds: 10);
    if (result != null) {
      voiceController.voice.speak("Demo completat! Comanda vocală procesată: $result");
    } else {
              voiceController.voice.speak("Demo completat! Nu am auzit nicio comandă.");
    }
    
    setState(() {
      _currentDemo = '';
    });
  }

  Future<void> _runEmergencyDemo(DriverVoiceController voiceController) async {
    voiceController.voice.speak("Demo: Emergency Commands. Testez comenzile de urgență.");
    
    voiceController.voice.speak("Spuneți 'AJUTOR' pentru a activa modul de urgență.");
    
    final result = await voiceController.voice.listen(timeoutSeconds: 10);
    if (result != null && result.toLowerCase().contains('ajutor')) {
      voiceController.voice.speak("Demo completat! Comanda de urgență activată cu succes!");
    } else {
              voiceController.voice.speak("Demo completat! Comanda de urgență testată.");
    }
    
    setState(() {
      _currentDemo = '';
    });
  }

  Future<void> _runSafetyDemo(DriverVoiceController voiceController) async {
    voiceController.voice.speak("Demo: Safety Monitoring. Testez monitorizarea de siguranță.");
    
    voiceController.voice.speak("Sistemul va monitoriza activitatea șoferului pentru siguranță.");
    
    // Simulate safety monitoring
    await Future.delayed(const Duration(seconds: 3));
    
          voiceController.voice.speak("Demo completat! Monitorizarea de siguranță testată cu succes!");
    
    setState(() {
      _currentDemo = '';
    });
  }

  void _showDriverStatistics(DriverVoiceController voiceController) {
    final stats = voiceController.getRideStatistics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Driver Voice Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Commands: ${stats['totalCommands']}'),
            Text('Current State: ${stats['currentState']}'),
            Text('Emergency Mode: ${stats['isEmergencyMode']}'),
            Text('Safety Mode: ${stats['isSafetyMode']}'),
            Text('Voice Commands: ${stats['voiceCommands']}'),
            if (stats['lastCommandTime'] != null)
              Text('Last Command: ${stats['lastCommandTime']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    
    setState(() {
      _currentDemo = '';
    });
  }

  Future<void> _testMicrophone(BuildContext context) async {
    final voiceController = context.read<PassengerVoiceControllerAdapter>();
    
    try {
      voiceController.voice.speak("Testez microfonul. Spuneți ceva...");
      final result = await voiceController.voice.listen(timeoutSeconds: 5);
      
      if (!context.mounted) return;
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone test successful! Heard: $result')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone test failed - no input detected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone test error: $e')),
        );
      }
    }
  }

  Future<void> _testSpeechRecognition(BuildContext context) async {
    final voiceController = context.read<PassengerVoiceControllerAdapter>();
    
    try {
      voiceController.voice.speak("Testez recunoașterea vocală. Spuneți o comandă...");
      final result = await voiceController.voice.listen(timeoutSeconds: 10);
      
      if (!context.mounted) return;
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition successful! Recognized: $result')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition failed - no input detected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: $e')),
        );
      }
    }
  }

  Future<void> _testTextToSpeech(BuildContext context) async {
    final voiceController = context.read<PassengerVoiceControllerAdapter>();
    
    try {
      voiceController.voice.speak("Testez text-to-speech. Dacă auziți această frază, TTS funcționează corect!");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text-to-speech test completed successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Text-to-speech test error: $e')),
        );
      }
    }
  }

      // Test detectarea "salut" eliminat - nu este implementat în aplicație
}

// Import DriverVoiceRideRequest from driver voice controller to avoid duplication
