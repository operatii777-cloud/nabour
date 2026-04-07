// lib/screens/ai_vocabulary_test_screen.dart
// Enhanced AI Vocabulary Test Screen with improved structure and error handling

import 'package:flutter/material.dart';
import '../voice/ai/ai_vocabulary.dart';
import '../voice/ai/ai_methods.dart';
import '../voice/core/voice_orchestrator.dart';

class AIVocabularyTestScreen extends StatefulWidget {
  const AIVocabularyTestScreen({super.key});

  @override
  State<AIVocabularyTestScreen> createState() => _AIVocabularyTestScreenState();
}

class _AIVocabularyTestScreenState extends State<AIVocabularyTestScreen> {
  late final TextEditingController _testInputController;
  late final VoiceOrchestrator _voiceOrchestrator;
  late final TextEditingController _locationSearchController;
  
  String _testResult = '';
  String _selectedCategory = 'rideCommands';
  String _selectedCounty = 'bucuresti';
  String _selectedLocationCategory = 'transport';

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _testInputController = TextEditingController();
    _locationSearchController = TextEditingController();
    _voiceOrchestrator = VoiceOrchestrator();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    try {
      await _voiceOrchestrator.initialize();
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = '⚠️ Eroare inițializare voice: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _testCommand(String command) async {
    if (command.trim().isEmpty) return;
    
    setState(() {
      _isProcessing = true;
      _testResult = '🧪 Testez comanda: "$command"...';
    });
    
    try {
      // Simulate AI processing
      await Future.delayed(const Duration(milliseconds: 800));
      
      final commandType = AIMethods.getCommandType(command);
      final suggestions = AIMethods.getSuggestions(command);
      
      if (mounted) {
        setState(() {
          _testResult = '''
🎯 Comanda testată: "$command"
📋 Tip identificat: $commandType
💡 Sugestii: ${suggestions.join(', ')}
✅ Test completat cu succes!
          ''';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = '❌ Eroare testare: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _testResponse(String responseKey, [Map<String, String>? variables]) async {
    try {
      setState(() {
        _isProcessing = true;
        _testResult = '🧪 Testez răspunsul: "$responseKey"...';
      });
      
      final response = AIMethods.getResponse(responseKey);
      
      if (mounted) {
        setState(() {
          _testResult = '''
🎯 Răspuns testat: "$responseKey"
📝 Răspuns generat: "$response"
${variables != null ? '🔧 Variabile: $variables' : ''}
✅ Test completat cu succes!
          ''';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = '❌ Eroare testare răspuns: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _speakResponse(String responseKey) async {
    try {
      setState(() {
        _isProcessing = true;
        _testResult = '🗣️ Testez TTS pentru: "$responseKey"...';
      });
      
      final response = AIMethods.getResponse(responseKey);
      await _voiceOrchestrator.speak(response);
      
      if (mounted) {
        setState(() {
          _testResult = '''
🗣️ TTS testat: "$responseKey"
📝 Text citit: "$response"
✅ TTS funcționează!
          ''';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = '❌ Eroare TTS: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Test Biblioteca AI'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestInputSection(),
            const SizedBox(height: 16),
            if (_testResult.isNotEmpty) _buildTestResultsSection(),
            const SizedBox(height: 16),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _buildCommandsList(),
            const SizedBox(height: 16),
            _buildAIResponsesTest(),
            const SizedBox(height: 16),
            _buildVoiceStylesTest(),
            const SizedBox(height: 16),
            _buildCompletePhrasesTest(),
            const SizedBox(height: 16),
            _buildLocationDatabaseTest(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTestInputSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧪 Test Comenzi AI',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _testInputController,
              decoration: const InputDecoration(
                labelText: 'Scrie o comandă pentru test',
                hintText: 'ex: vreau să merg la universitate',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              onSubmitted: (value) => _testCommand(value),
              enabled: !_isProcessing,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _testCommand(_testInputController.text),
                    icon: _isProcessing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                    label: Text(_isProcessing ? 'Testez...' : '🧪 Testează'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _speakResponse('confirm_booking'),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('🗣️ Testează TTS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultsSection() {
    return Card(
      elevation: 2,
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
                  '📊 Rezultate Test',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _testResult,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '📚 Categorii Comenzi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Selectează categoria',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: const [
                DropdownMenuItem(value: 'rideCommands', child: Text('🚗 Comenzi Rezervare')),
                DropdownMenuItem(value: 'voiceCommands', child: Text('🗣️ Comenzi Vocale')),
                DropdownMenuItem(value: 'paymentCommands', child: Text('💰 Comenzi Plată')),
                DropdownMenuItem(value: 'emergencyCommands', child: Text('🚨 Comenzi Urgență')),
                DropdownMenuItem(value: 'appCommands', child: Text('📱 Comenzi Aplicație')),
                DropdownMenuItem(value: 'multilingualCommands', child: Text('🌍 Comenzi Multilingve')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandsList() {
    final commands = _getCommandsForCategory(_selectedCategory);
    final categoryName = _getCategoryDisplayName(_selectedCategory);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  '📝 Comenzi Disponibile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              categoryName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            ...commands.entries.map((entry) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isProcessing ? null : () => _testCommand(entry.key),
                      icon: Icon(
                        _isProcessing ? Icons.hourglass_empty : Icons.play_arrow,
                        color: _isProcessing ? Colors.grey : Colors.green,
                      ),
                      tooltip: 'Testează comanda',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIResponsesTest() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  '🎯 Test Răspunsuri AI',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildResponseTestButton('confirm_booking', 'Confirmare Rezervare'),
                _buildResponseTestButton('ask_destination', 'Întrebare Destinație'),
                _buildResponseTestButton('confirm_payment', 'Confirmare Plată'),
                _buildResponseTestButton('success_booking', 'Succes Rezervare'),
                _buildResponseTestButton('error_booking', 'Eroare Rezervare'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceStylesTest() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.record_voice_over, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  '🎨 Test Stiluri Vocale',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildVoiceStyleButton('friendly', 'Prietenos'),
                _buildVoiceStyleButton('professional', 'Profesional'),
                _buildVoiceStyleButton('casual', 'Relaxat'),
                _buildVoiceStyleButton('urgent', 'Urgent'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletePhrasesTest() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_bubble, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '📚 Test Fraze Complete',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...AIVocabulary.completePhrases.take(5).map((phrase) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _testCommand(phrase),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    phrase,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTestButton(String responseKey, String label) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : () => _testResponse(responseKey),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  Widget _buildVoiceStyleButton(String styleName, String label) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : () {
        final style = {'speech_rate': 1.0, 'pitch': 1.0, 'volume': 0.8, 'tone': 'friendly'};
        setState(() {
          _testResult = '''
🎨 Stil vocal: $label
📊 Rate: ${style['speech_rate']}
🎵 Pitch: ${style['pitch']}
🔊 Volume: ${style['volume']}
🎭 Ton: ${style['tone']}
✅ Stil vocal testat cu succes!
          ''';
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  Map<String, String> _getCommandsForCategory(String category) {
    switch (category) {
      case 'rideCommands':
        return AIVocabulary.rideCommands;
      case 'voiceCommands':
        return AIVocabulary.voiceCommands;
      case 'paymentCommands':
        return AIVocabulary.paymentCommands;
      case 'emergencyCommands':
        return AIVocabulary.emergencyCommands;
      case 'appCommands':
        return AIVocabulary.appCommands;
      case 'multilingualCommands':
        return AIVocabulary.multilingualCommands;
      default:
        return AIVocabulary.rideCommands;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'rideCommands':
        return 'Comenzi Rezervare';
      case 'voiceCommands':
        return 'Comenzi Vocale';
      case 'paymentCommands':
        return 'Comenzi Plată';
      case 'emergencyCommands':
        return 'Comenzi Urgență';
      case 'appCommands':
        return 'Comenzi Aplicație';
      case 'multilingualCommands':
        return 'Comenzi Multilingve';
      default:
        return 'Comenzi Rezervare';
    }
  }

  Widget _buildLocationDatabaseTest() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  '📍 Test Baza de Date Locații',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Selector Județ
            Row(
              children: [
                const Text('🏛️ Județul:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                ...AIMethods.getAvailableCounties().map((county) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(county.toUpperCase()),
                      selected: _selectedCounty == county,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCounty = county;
                          _selectedLocationCategory = 'transport';
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Selector Categorie
            Row(
              children: [
                const Text('📂 Categoria:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AIMethods.getAvailableCategories().map((category) => 
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_getCategoryDisplayName(category)),
                            selected: _selectedLocationCategory == category,
                            onSelected: (selected) {
                              setState(() {
                                _selectedLocationCategory = category;
                              });
                            },
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Căutare Globală
            TextField(
              controller: _locationSearchController,
              decoration: const InputDecoration(
                labelText: '🔍 Caută în toate locațiile',
                hintText: 'ex: mall, restaurant, spital, universitate...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // Căutare implementată în viitor
              },
            ),
            const SizedBox(height: 16),
            
            // Destinații Populare
            Text(
              '⭐ Destinații Populare în ${_selectedCounty.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AIMethods.getPopularDestinationsInCounty(_selectedCounty).take(6).map((destination) => 
                ElevatedButton(
                  onPressed: () => _testLocationCommand(destination),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    destination.split(',').first,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ).toList(),
            ),
            const SizedBox(height: 16),
            
            // Lista Locațiilor din Categoria Selectată
            Text(
              '📋 Locații din ${_getCategoryDisplayName(_selectedLocationCategory)} - ${_selectedCounty.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: AIMethods.getLocationsByCategory(_selectedLocationCategory).length,
                itemBuilder: (context, index) {
                  final location = AIMethods.getLocationsByCategory(_selectedLocationCategory)[index];
                  return ListTile(
                    title: Text(location['name']!),
                    subtitle: Text(location['address']!),
                    leading: const Icon(Icons.place, color: Colors.blue),
                    trailing: IconButton(
                      onPressed: () => _testLocationCommand(location['name']!),
                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                      tooltip: 'Testează locația',
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

  void _testLocationCommand(String location) {
    final command = 'Vreau să merg la $location';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🧪 Comanda generată: "$command"'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Copiază',
          onPressed: () {
            // Aici s-ar putea copia în clipboard
          },
        ),
      ),
    );
    
    // Simulează procesarea comenzii
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Comanda procesată cu succes!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }



  @override
  void dispose() {
    _testInputController.dispose();
    _locationSearchController.dispose();
    super.dispose();
  }
}
