// lib/screens/nlu_test_screen.dart
// Test Screen pentru sistemul Natural Language Understanding (NLU)

import 'package:flutter/material.dart';
import '../voice/ai/ai_methods.dart';

class NLUTestScreen extends StatefulWidget {
  const NLUTestScreen({super.key});

  @override
  State<NLUTestScreen> createState() => _NLUTestScreenState();
}

class _NLUTestScreenState extends State<NLUTestScreen> {
  final TextEditingController _commandController = TextEditingController();
  Map<String, dynamic>? _lastResult;
  final List<String> _testCommands = [
    'Vreau să merg la Mall Băneasa',
    'Du-mă la universitate',
    'Care este cea mai apropiată stație de metrou?',
    'Vreau să comand o cursă la aeroport',
    'Unde este cea mai apropiată gară?',
    'Vreau să merg acum la centru',
    'Cât costă o cursă la spital?',
    'Rezervă o cursă pentru mâine dimineață',
    'Vreau să plătesc cu cardul',
    'Hey Nabour, ajutor!',
    'Schimbă limba în engleză',
    'Care este cea mai apropiată stație de tramvai?',
    'Vreau să mă duc la restaurant',
    'Găsește cea mai apropiată farmacie',
    'Vreau să fac o comandă urgentă',
  ];

  @override
  void initState() {
    super.initState();
    _commandController.text = _testCommands.first;
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  void _testCommand(String command) {
    if (command.trim().isEmpty) return;
    
    final result = AIMethods.processVoiceCommand(command);
    setState(() {
      _lastResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Test Sistem NLU'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommandInput(),
            const SizedBox(height: 16),
            _buildTestCommands(),
            const SizedBox(height: 16),
            if (_lastResult != null) _buildResults(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandInput() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  '🧠 Testează Comanda Vocală',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commandController,
              decoration: const InputDecoration(
                labelText: 'Scrie o comandă pentru test',
                hintText: 'ex: Vreau să merg la Mall Băneasa',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _testCommand(_commandController.text),
                icon: const Icon(Icons.play_arrow),
                label: const Text('🧪 Testează Comanda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCommands() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '📝 Comenzi de Test Predefinite',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Apasă pe o comandă pentru a o testa automat:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ..._testCommands.map((command) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    _commandController.text = command;
                    _testCommand(command);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade800,
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(double.infinity, 48),
                    elevation: 1,
                  ),
                  child: Text(
                    command,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final result = _lastResult!;
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '📊 Rezultate Analiză NLU',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Intent
            _buildResultRow('🎯 Intent Recunoscut:', result['intent'] ?? 'Necunoscut', Colors.blue),
            
            // Confidence
            _buildResultRow('📊 Încredere:', '${((result['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%', 
              (result['confidence'] ?? 0.0) > 0.7 ? Colors.green : (result['confidence'] ?? 0.0) > 0.4 ? Colors.orange : Colors.red),
            
            // Response
            _buildResultRow('🗣️ Răspuns AI:', result['response'] ?? 'N/A', Colors.purple),
            
            // Entities
            if (result['entities'] != null && (result['entities'] as Map).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '🔍 Entități Extrase:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...(result['entities'] as Map<String, String>).entries.map((entry) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Suggestions
            if (result['suggestions'] != null && (result['suggestions'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '💡 Sugestii:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...(result['suggestions'] as List<String>).map((suggestion) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
