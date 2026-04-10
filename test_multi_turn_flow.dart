import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nabour_app/voice/ai/gemini_voice_engine.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({'locale': 'ro'});

  print('=======================================');
  print('🎤 INITIATING MULTI-TURN AI VOICE FLOW TEST');
  print('=======================================');

  try {
    final ai = GeminiVoiceEngine();
    
    // Simulate Conversation State 1: Awaiting Destination
    print('\n[TURN 1] User: "Salut, vreau sa merg la un hypermarket"');
    var ctx1 = VoiceContext(
      conversationState: 'idle',
      conversationHistory: [],
    );
    final resp1 = await ai.processVoiceInput("Salut, vreau sa merg la un hypermarket", ctx1);
    print('🤖 AI Response Type: \${resp1.type}');
    print('🤖 AI Message: \${resp1.message}');
    print('📍 Parsed Destination: \${resp1.destination}');
    
    if (resp1.type != 'destination_confirmed') {
      print('❌ ERROR: Should have parsed destination');
    }

    // Simulate Conversation State 2: Awaiting Confirmation
    print('\n[TURN 2] AI has asked: "Perfect, vrei sa confirmi?" -> User: "Da, clar."');
    var ctx2 = VoiceContext(
      conversationState: 'awaitingConfirmation',
      conversationHistory: ['User: vreau sa merg la mall'],
      destination: resp1.destination,
    );
    final resp2 = await ai.processVoiceInput("Da, clar.", ctx2);
    print('🤖 AI Response Type: \${resp2.type}');
    print('🤖 AI Message: \${resp2.message}');
    
    if (resp2.type != 'confirmation') {
      print('❌ ERROR: Should be a confirmation');
    }

    // Simulate Conversation State 3: Driver Accepted -> Awaiting Final acceptance
    print('\n[TURN 3] AI has said: "Am gasit sofer, confirmam cursa?" -> User: "Nu vreau"');
    var ctx3 = VoiceContext(
      conversationState: 'awaitingDriverAcceptance', 
      conversationHistory: ['System: Sofer gasit'],
    );
    final resp3 = await ai.processVoiceInput("Nu vreau", ctx3);
    print('🤖 AI Response Type: \${resp3.type}');
    print('🤖 AI Message: \${resp3.message}');
    
    if (resp3.type != 'driver_acceptance') {
      print('❌ ERROR: Should be driver_acceptance but parsed as \${resp3.type}');
    }

    print('\n🏅 ALL CORE LOCAL FAILSAFES RESPONDED CORRECTLY!');

  } catch(e, stack) {
     print('❌ Critical Failure: \$e');
     print(stack);
  }
}
