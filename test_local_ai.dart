import 'package:nabour_app/voice/ai/gemini_voice_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Set up mock SharedPreferences
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({'locale': 'ro'});
  
  print('========================');
  print('Testing Local AI Fallback...');
  print('========================');

  final engine = GeminiVoiceEngine();
  
  // Create a mock context
  final context = VoiceContext(
    conversationState: 'idle',
    conversationHistory: [],
    destination: null,
    pickup: null,
  );

  print('1. Simulating empty or invalid Gemini API key (fallback trigger)');
  final userInput = "vreau o cursă la aeroport";
  
  try {
    // We expect processVoiceInput to hit local matching or Ollama caller fallback 
    // because API keys in test environment are not set.
    final response = await engine.processVoiceInput(userInput, context);
    
    print('✅ AI Engine Response:');
    print('  - Type: ${response.type}');
    print('  - Message: ${response.message}');
    print('  - Confidence: ${response.confidence}');
    print('  - Destination detected: ${response.destination}');
    
    if (response.destination != null && response.destination!.toLowerCase().contains('aeroport')) {
      print('🏆 TEST PASSED: Intent and Destination successfully parsed locally!!');
    } else {
      print('❌ TEST FAILED: Didn\'t parse destination right.');
    }
  } catch (e) {
    print('❌ TEST ERROR: $e');
  }
  
  print('========================');
}
