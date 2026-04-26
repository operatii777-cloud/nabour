import 'package:flutter/material.dart';
import 'package:nabour_app/voice/ai/ai_provider_router.dart';
import 'package:nabour_app/voice/ai/gemini_voice_engine.dart';
import 'package:nabour_app/voice/core/voice_ui_automation_registry.dart';
import 'package:nabour_app/voice/testing/nabour_ghost_orchestrator.dart';

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
      final response = await AIProviderRouter().route(
        input, 
        VoiceContext(conversationState: 'idle', conversationHistory: [])
      );
      
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
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
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

            // 🔥 GHOST MODE SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListenableBuilder(
                listenable: NabourGhostOrchestrator(),
                builder: (context, _) {
                  final ghost = NabourGhostOrchestrator();
                  if (ghost.isActive) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text('GHOST ACTIVE: ${ghost.activeRole.name}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => ghost.stopTest(),
                            icon: const Icon(Icons.stop),
                            label: const Text('STOP ALL SIMULATIONS'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      const Text('MODALITĂȚI TESTARE AUTONOMĂ (GHOST)', style: TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _GhostActionCard(
                              title: 'PASAGER (AI)',
                              icon: Icons.person_search_rounded,
                              color: Colors.blueAccent,
                              onTap: () => ghost.startSimulation(GhostRole.passengerOnly),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _GhostActionCard(
                              title: 'ȘOFER (AUTO)',
                              icon: Icons.local_taxi_rounded,
                              color: Colors.greenAccent,
                              onTap: () => ghost.startSimulation(GhostRole.driverOnly),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => ghost.startSimulation(GhostRole.singleDevice),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('FULL E2E (SINGLE DEVICE)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  );
                }
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

class _GhostActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GhostActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
