import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nabour_app/main.dart' as app;

void _log(String message) => debugPrint(message);

/// 🚗 Test End-to-End AI cu Aplicația Reală
/// 
/// Testează funcționalitatea AI-ului în contextul aplicației reale
/// Simulează utilizatorul care se conectează ca șofer disponibil
/// și testează flow-ul complet de solicitare și preluare cursă
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🚗 AI End-to-End Tests with Real App', () {
    
    testWidgets('🚗 Test 1: Simulare utilizator șofer disponibil și test AI ride flow', (WidgetTester tester) async {
      _log('🚗 [E2E_AI_TEST] Starting real app for AI testing...');
      
      // Lansez aplicația reală
      app.main();
      await tester.pumpAndSettle();
      
      _log('🚗 [E2E_AI_TEST] App launched successfully');
      
      // Simulez că utilizatorul se conectează ca șofer disponibil
      await _simulateDriverLogin(tester);
      
      // Testez că butonul AI nu este vizibil pentru șofer disponibil
      await _testAIButtonVisibilityForDriver(tester);
      
      // Simulez schimbarea rolului în pasager
      await _simulateRoleChangeToPassenger(tester);
      
      // Testez că butonul AI este vizibil pentru pasager
      await _testAIButtonVisibilityForPassenger(tester);
      
      // Testez funcționalitatea AI-ului pentru solicitarea cursei
      await _testAIRideRequestFlow(tester);
      
      _log('✅ [E2E_AI_TEST] AI end-to-end test completed successfully!');
    });

    testWidgets('🚗 Test 2: Test flow complet AI ride cu multiple interacțiuni', (WidgetTester tester) async {
      _log('🚗 [E2E_AI_TEST] Starting complete AI ride flow test...');
      
      // Lansez aplicația
      app.main();
      await tester.pumpAndSettle();
      
      // Setez rolul de pasager
      await _simulateRoleChangeToPassenger(tester);
      
      // Testez flow-ul complet AI
      await _testCompleteAIRideFlow(tester);
      
      _log('✅ [E2E_AI_TEST] Complete AI ride flow test completed!');
    });
  });
}

/// 🚗 Simulează login-ul ca șofer disponibil
Future<void> _simulateDriverLogin(WidgetTester tester) async {
  _log('👨‍💼 [E2E_AI_TEST] Simulating driver login...');
  
  // Caută și apasă pe butonul de login sau meniul hamburger
  try {
    final loginButton = find.byKey(const Key('login_button'));
    if (loginButton.evaluate().isNotEmpty) {
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
    }
  } catch (e) {
    _log('⚠️ [E2E_AI_TEST] Login button not found, trying hamburger menu...');
  }
  
  // Încearcă să acceseze meniul hamburger
  try {
    final hamburgerMenu = find.byIcon(Icons.menu);
    if (hamburgerMenu.evaluate().isNotEmpty) {
      await tester.tap(hamburgerMenu);
      await tester.pumpAndSettle();
      
      // Caută opțiunea de a schimba rolul în șofer
      final driverRoleOption = find.text('Șofer');
      if (driverRoleOption.evaluate().isNotEmpty) {
        await tester.tap(driverRoleOption);
        await tester.pumpAndSettle();
      }
    }
  } catch (e) {
    _log('⚠️ [E2E_AI_TEST] Could not access hamburger menu: $e');
  }
  
  // Simulez că șoferul este disponibil
  try {
    final availableSwitch = find.byKey(const Key('driver_available_switch'));
    if (availableSwitch.evaluate().isNotEmpty) {
      await tester.tap(availableSwitch);
      await tester.pumpAndSettle();
    }
  } catch (e) {
    _log('⚠️ [E2E_AI_TEST] Driver available switch not found: $e');
  }
  
  _log('✅ [E2E_AI_TEST] Driver login simulation completed');
}

/// 🚗 Testează vizibilitatea butonului AI pentru șofer disponibil
Future<void> _testAIButtonVisibilityForDriver(WidgetTester tester) async {
  _log('🚗 [E2E_AI_TEST] Testing AI button visibility for available driver...');
  
  // Caută butonul AI
  final aiButton = find.byKey(const Key('ai_voice_button'));
  
  // Pentru șofer disponibil, butonul AI nu ar trebui să fie vizibil
  expect(aiButton.evaluate().isEmpty, isTrue, 
         reason: 'AI button should not be visible for available driver');
  
  _log('✅ [E2E_AI_TEST] AI button correctly hidden for available driver');
}

/// 🚗 Simulează schimbarea rolului în pasager
Future<void> _simulateRoleChangeToPassenger(WidgetTester tester) async {
  _log('👤 [E2E_AI_TEST] Simulating role change to passenger...');
  
  try {
    // Deschide meniul hamburger
    final hamburgerMenu = find.byIcon(Icons.menu);
    if (hamburgerMenu.evaluate().isNotEmpty) {
      await tester.tap(hamburgerMenu);
      await tester.pumpAndSettle();
      
      // Caută opțiunea de a schimba rolul în pasager
      final passengerRoleOption = find.text('Pasager');
      if (passengerRoleOption.evaluate().isNotEmpty) {
        await tester.tap(passengerRoleOption);
        await tester.pumpAndSettle();
      }
    }
  } catch (e) {
    _log('⚠️ [E2E_AI_TEST] Could not change role to passenger: $e');
  }
  
  _log('✅ [E2E_AI_TEST] Role change to passenger completed');
}

/// 🚗 Testează vizibilitatea butonului AI pentru pasager
Future<void> _testAIButtonVisibilityForPassenger(WidgetTester tester) async {
  _log('🚗 [E2E_AI_TEST] Testing AI button visibility for passenger...');
  
  // Caută butonul AI
  final aiButton = find.byKey(const Key('ai_voice_button'));
  
  // Pentru pasager, butonul AI ar trebui să fie vizibil
  expect(aiButton.evaluate().isNotEmpty, isTrue, 
         reason: 'AI button should be visible for passenger');
  
  _log('✅ [E2E_AI_TEST] AI button correctly visible for passenger');
}

/// 🚗 Testează flow-ul AI pentru solicitarea cursei
Future<void> _testAIRideRequestFlow(WidgetTester tester) async {
  _log('🚗 [E2E_AI_TEST] Testing AI ride request flow...');
  
  // Caută și apasă pe butonul AI
  final aiButton = find.byKey(const Key('ai_voice_button'));
  if (aiButton.evaluate().isNotEmpty) {
    await tester.tap(aiButton);
    await tester.pumpAndSettle();
    
    _log('🎤 [E2E_AI_TEST] AI button tapped, waiting for voice interaction...');
    
    // Așteaptă să se inițializeze interacțiunea vocală
    await Future.delayed(const Duration(seconds: 2));
    
    // Caută indicatorul de interacțiune vocală activă
    final voiceIndicator = find.byKey(const Key('voice_interaction_indicator'));
    if (voiceIndicator.evaluate().isNotEmpty) {
      _log('🎤 [E2E_AI_TEST] Voice interaction indicator found');
    }
    
    // Simulez că utilizatorul vorbește
    await _simulateVoiceInput(tester, 'Vreau să merg la Gara de Nord');
    
    // Așteaptă procesarea AI
    await Future.delayed(const Duration(seconds: 3));
    
    // Simulez confirmarea
    await _simulateVoiceInput(tester, 'Da, confirm');
    
    // Așteaptă finalizarea procesării
    await Future.delayed(const Duration(seconds: 2));
    
    _log('✅ [E2E_AI_TEST] AI ride request flow test completed');
  } else {
    _log('❌ [E2E_AI_TEST] AI button not found for testing');
  }
}

/// 🚗 Simulează input vocal
Future<void> _simulateVoiceInput(WidgetTester tester, String text) async {
  _log('🎤 [E2E_AI_TEST] Simulating voice input: "$text"');
  
  // În contextul real, aceasta ar fi gestionată de sistemul de speech-to-text
  // Pentru test, simulăm că textul este procesat
  
  // Caută câmpul de text pentru input vocal (dacă există)
  final voiceInputField = find.byKey(const Key('voice_input_field'));
  if (voiceInputField.evaluate().isNotEmpty) {
    await tester.enterText(voiceInputField, text);
    await tester.pumpAndSettle();
  }
  
  // Simulez pauza de procesare
  await Future.delayed(const Duration(milliseconds: 1500));
}

/// 🚗 Testează flow-ul complet AI ride
Future<void> _testCompleteAIRideFlow(WidgetTester tester) async {
  _log('🚗 [E2E_AI_TEST] Testing complete AI ride flow...');
  
  // Flow-ul complet de testare AI ride
  final rideFlowSteps = [
    'Vreau să rezerv o cursă',
    'La Aeroportul Henri Coandă',
    'De la Piața Unirii',
    'Da, confirm cursa',
    'Cât costă aproximativ?',
    'Când vine șoferul?',
    'Perfect, aștept',
    'Șoferul a ajuns?',
    'Excelent, ieșim',
    'Am ajuns la destinație?',
    'Mulțumesc pentru cursă',
  ];
  
  // Activează AI-ul
  final aiButton = find.byKey(const Key('ai_voice_button'));
  if (aiButton.evaluate().isNotEmpty) {
    await tester.tap(aiButton);
    await tester.pumpAndSettle();
    
    // Simulez fiecare pas din flow
    for (int i = 0; i < rideFlowSteps.length; i++) {
      final step = rideFlowSteps[i];
      _log('🎤 [E2E_AI_TEST] Step ${i + 1}: "$step"');
      
      await _simulateVoiceInput(tester, step);
      
      // Așteaptă procesarea AI
      await Future.delayed(const Duration(seconds: 2));
    }
    
    _log('✅ [E2E_AI_TEST] Complete AI ride flow test completed');
  }
}

/// 📊 Raport pentru testele E2E AI
class E2EAIReport {
  static void generateReport(Map<String, dynamic> metrics) {
    _log('📊 [E2E_AI_REPORT] AI End-to-End Test Report');
    _log('📊 [E2E_AI_REPORT] ========================');
    
    _log('📊 [E2E_AI_REPORT] Tests run: ${metrics['testsRun'] ?? 0}');
    _log('📊 [E2E_AI_REPORT] Tests passed: ${metrics['testsPassed'] ?? 0}');
    _log('📊 [E2E_AI_REPORT] Tests failed: ${metrics['testsFailed'] ?? 0}');
    _log('📊 [E2E_AI_REPORT] AI interactions tested: ${metrics['aiInteractions'] ?? 0}');
    _log('📊 [E2E_AI_REPORT] Average AI response time: ${metrics['avgResponseTime'] ?? 0}ms');
    _log('📊 [E2E_AI_REPORT] Voice commands processed: ${metrics['voiceCommands'] ?? 0}');
    
    // Evaluare performanță
    final successRate = metrics['testsPassed'] / (metrics['testsRun'] ?? 1) * 100;
    if (successRate == 100) {
      _log('📊 [E2E_AI_REPORT] ⭐ All E2E AI tests PASSED!');
    } else if (successRate > 80) {
      _log('📊 [E2E_AI_REPORT] ✅ Most E2E AI tests passed');
    } else {
      _log('📊 [E2E_AI_REPORT] ❌ Some E2E AI tests failed');
    }
    
    _log('📊 [E2E_AI_REPORT] ========================');
  }
}
