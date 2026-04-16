import 'package:flutter/material.dart';
import 'package:nabour_app/voice/ai/ai_provider_router.dart';
import 'package:nabour_app/voice/ai/gemini_voice_engine.dart';
import 'package:nabour_app/voice/core/voice_ui_automation_registry.dart';
import 'package:nabour_app/voice/main_voice_integration.dart';
import 'package:provider/provider.dart';
import 'package:nabour_app/utils/logger.dart';

class VoiceUIDriverTestScreen extends StatefulWidget {
  const VoiceUIDriverTestScreen({super.key});

  @override
  State<VoiceUIDriverTestScreen> createState() => _VoiceUIDriverTestScreenState();
}

class _VoiceUIDriverTestScreenState extends State<VoiceUIDriverTestScreen> {
  final TextEditingController _inputController = TextEditingController();
  final List<String> _logs = [];
  bool _isProcessing = false;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _registerDummyActions();
    _addLog('🚀 Voice UI Driver initialized.');
    _addLog('📱 Registry contains: ${VoiceUIAutomationRegistry().availableActions.join(', ')}');
  }

  void _registerDummyActions() {
    final registry = VoiceUIAutomationRegistry();
    
    // Înregistrăm un buton de test
    registry.registerAction('increment_counter', () {
      setState(() => _counter++);
      _addLog('✅ Action Executed: increment_counter (Counter is now $_counter)');
    });

    registry.registerParameterizedAction('show_message', (params) {
      final msg = params['text'] ?? 'No message';
      _addLog('✅ Action Executed: show_message with text: "$msg"');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI says: $msg')));
    });

    registry.registerAction('change_bg_blue', () {
      _addLog('✅ Action Executed: change_bg_blue');
    });
  }

  void _addLog(String msg) {
    setState(() {
      _logs.insert(0, '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} - $msg');
    });
  }

  Future<void> _simulateVoiceCommand() async {
    final input = _inputController.text;
    if (input.isEmpty) return;

    setState(() => _isProcessing = true);
    _addLog('🎤 User says: "$input"');

    try {
      // 1. Apelăm motorul AI (via Router pentru a simula fluxul real)
      final response = await AIProviderRouter().processVoiceInput(input);
      
      _addLog('🧠 AI Response Type: ${response.type}');
      _addLog('💬 AI Message: "${response.message}"');
      
      if (response.appAction != null) {
        _addLog('🛠️ AI requested action: ${response.appAction}');
        if (response.params != null) {
          _addLog('📦 Params: ${response.params}');
        }

        // 2. Executăm prin Registry (ca în MainVoiceIntegration)
        final success = VoiceUIAutomationRegistry().executeAction(
          response.appAction!, 
          params: response.params
        );

        if (success) {
          _addLog('✨ SUCCESS: Registry executed the command.');
        } else {
          _addLog('⚠️ FAILED: Action not found in Registry.');
        }
      } else if (response.type == 'help_response') {
        _addLog('📖 This is a general knowledge question (Fallback active).');
      }

    } catch (e) {
      _addLog('❌ ERROR: $e');
    } finally {
      setState(() => _isProcessing = false);
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧬 Voice UI Driver Lab'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: Column(
          children: [
            // Monitor Secțiune
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text('STARE COMPONENTĂ (DOM OBJECT)', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Counter Value: $_counter', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Registered IDs:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(VoiceUIAutomationRegistry().availableActions.join(' | '), style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
                ],
              ),
            ),

            // Input Secțiune
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Simulează comandă vocală (ex: crește counterul)',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onSubmitted: (_) => _simulateVoiceCommand(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isProcessing ? null : _simulateVoiceCommand,
                    icon: _isProcessing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send),
                    style: IconButton.styleFrom(backgroundColor: Colors.blueAccent),
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Divider(color: Colors.white12),
            
            // Log Secțiune
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: log.contains('✅') || log.contains('✨') 
                          ? Colors.greenAccent 
                          : log.contains('❌') ? Colors.redAccent : Colors.white70,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
