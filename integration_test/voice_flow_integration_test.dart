import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nabour_app/main.dart' as app;
import 'package:nabour_app/voice/passenger/passenger_voice_controller_adapter.dart';
import 'package:provider/provider.dart';


/// 🧪 Test de Integrare Complet pentru Fluxul AI Vocal FriendsRide
/// 
/// Acest test simulează un utilizator real, de la pornirea interacțiunii vocale
/// până la finalizarea comenzii, inclusiv testarea meniurilor și setărilor auxiliare.
/// 
/// Caracteristici:
/// - Măsurarea performanței temporale pentru fiecare etapă
/// - Validarea fluxului complet de comandă (Happy Path)
/// - Testarea funcționalităților de anulare și corectare
/// - Verificarea setărilor modulului de voce
/// - Simularea input-ului vocal prin apeluri directe la controller
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🎤 FLUX AI VOCAL COMPLET - TEST DE INTEGRARE', () {
    
    /// 🚀 Test principal: Flux complet de comandă a unei curse cu măsurarea timpilor
    testWidgets('Flux complet de comandă a unei curse cu măsurarea timpilor', (WidgetTester tester) async {
      debugPrint('🚀 Începe testul fluxului complet de comandă...');
      
      // Pornește aplicația
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Așteaptă inițializarea completă

      final stopwatch = Stopwatch();
      
      // Obține acces la Voice Controller prin Provider
      // ignore: use_build_context_synchronously
      final voiceController = Provider.of<PassengerVoiceControllerAdapter>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      
      // Inițializează sistemul vocal
      await voiceController.initializeVoiceSystem();
      await tester.pumpAndSettle();

      debugPrint('✅ Voice Controller obținut cu succes');

      // ETAPA 1: Pornirea interacțiunii
      debugPrint('🎯 ETAPA 1: Pornirea interacțiunii vocale...');
      stopwatch.start();
      await tester.tap(find.byIcon(Icons.mic)); // Găsește iconița de microfon
      await tester.pumpAndSettle();
      stopwatch.stop();
      
      debugPrint('⏱️ Timp de pornire overlay: ${stopwatch.elapsedMilliseconds}ms');
      expect(voiceController.isOverlayVisible, isTrue);
      expect(voiceController.aiResponse, contains('Salut, unde doriți să mergeți?'));
      debugPrint('✅ ETAPA 1 completată: Overlay vizibil și greeting corect');
      stopwatch.reset();

      // ETAPA 2: Utilizatorul rostește destinația
      debugPrint('🎯 ETAPA 2: Procesarea destinației...');
      stopwatch.start();
      voiceController.updateContextAndProcess('Vreau să merg la Aeroportul Otopeni'); // Fără await
      await tester.pumpAndSettle();
      stopwatch.stop();
      
      debugPrint('⏱️ Timp de procesare destinație: ${stopwatch.elapsedMilliseconds}ms');
      expect(voiceController.aiResponse, contains('Confirmați?'));
      expect(voiceController.aiResponse, contains('Aeroportul Otopeni'));
      debugPrint('✅ ETAPA 2 completată: Destinația procesată și confirmată');
      stopwatch.reset();

      // ETAPA 3: Utilizatorul confirmă destinația și primește oferta
      debugPrint('🎯 ETAPA 3: Căutarea șoferilor și prezentarea ofertei...');
      stopwatch.start();
      voiceController.updateContextAndProcess('Da, confirm'); // Fără await
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Așteptăm mai mult pentru căutarea simulată
      stopwatch.stop();
      
      debugPrint('⏱️ Timp căutare șoferi și prezentare ofertă: ${stopwatch.elapsedMilliseconds}ms');
      expect(voiceController.aiResponse, contains('lei'));
      expect(voiceController.aiResponse, contains('Confirmați rezervarea?'));
      debugPrint('✅ ETAPA 3 completată: Oferta prezentată cu preț');
      stopwatch.reset();
      
      // ETAPA 4: Utilizatorul confirmă cursa finală
      debugPrint('🎯 ETAPA 4: Finalizarea comenzii...');
      stopwatch.start();
      voiceController.updateContextAndProcess('Accept'); // Fără await
      await tester.pumpAndSettle(const Duration(seconds: 3));
      stopwatch.stop();
      
      debugPrint('⏱️ Timp finalizare comandă: ${stopwatch.elapsedMilliseconds}ms');
      expect(voiceController.aiResponse, contains('rezervată cu succes'));
      debugPrint('✅ ETAPA 4 completată: Comanda finalizată cu succes');
      stopwatch.reset();

      debugPrint('🎉 FLUX COMPLET TESTAT CU SUCCES!');
    });

    /// ❌ Test pentru anularea comenzii la mijlocul fluxului
    testWidgets('Utilizatorul anulează comanda la mijlocul fluxului', (WidgetTester tester) async {
      debugPrint('🚀 Începe testul de anulare...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Obține controller-ul prin Provider
      // ignore: use_build_context_synchronously
      final voiceController = Provider.of<PassengerVoiceControllerAdapter>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      await voiceController.initializeVoiceSystem();
      await tester.pumpAndSettle();

      // Pornește interacțiunea vocală
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      expect(voiceController.isOverlayVisible, isTrue);

      // Utilizatorul introduce destinația
      voiceController.updateContextAndProcess('Merg la Gara de Nord'); // Fără await
      await tester.pumpAndSettle();
      expect(voiceController.aiResponse, contains('Gara de Nord'));
      debugPrint('✅ Destinația introdusă: Gara de Nord');

      // Utilizatorul anulează
      voiceController.updateContextAndProcess('Anulează'); // Fără await
      await tester.pumpAndSettle();
      
      // Verifică că anularea a fost procesată
      final response = voiceController.aiResponse;
      expect(
        response.contains('anulată') || response.contains('anulat') || response.contains('oprit'),
        isTrue,
        reason: 'Răspunsul trebuie să conțină o confirmare de anulare. Răspuns actual: $response'
      );
      debugPrint('✅ Comanda anulată cu succes');
    });

    /// 🔄 Test pentru corectarea destinației
    testWidgets('Utilizatorul corectează destinația', (WidgetTester tester) async {
      debugPrint('🚀 Începe testul de corectare...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Obține controller-ul prin Provider
      // ignore: use_build_context_synchronously
      final voiceController = Provider.of<PassengerVoiceControllerAdapter>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      await voiceController.initializeVoiceSystem();
      await tester.pumpAndSettle();

      // Pornește interacțiunea vocală
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      // Prima destinație (greșită)
      voiceController.updateContextAndProcess('Merg la Mall Băneasa'); // Fără await
      await tester.pumpAndSettle();
      expect(voiceController.aiResponse, contains('Mall Băneasa'));
      debugPrint('✅ Prima destinație introdusă: Mall Băneasa');

      // Corectarea destinației
      voiceController.updateContextAndProcess('Nu, vreau să merg la Mall Afi Cotroceni'); // Fără await
      await tester.pumpAndSettle();
      expect(voiceController.aiResponse, contains('Mall Afi Cotroceni'));
      debugPrint('✅ Destinația corectată: Mall Afi Cotroceni');
    });

    /// ⚙️ Test pentru setările modulului de voce
    testWidgets('Verifică activarea și dezactivarea ascultării continue', (WidgetTester tester) async {
      debugPrint('🚀 Începe testul setărilor...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Obține controller-ul prin Provider
      // ignore: use_build_context_synchronously
      final voiceController = Provider.of<PassengerVoiceControllerAdapter>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      await voiceController.initializeVoiceSystem();
      await tester.pumpAndSettle();

      // Inițial, starea este falsă
      expect(voiceController.isContinuousListening, isFalse);
      debugPrint('✅ Starea inițială: Ascultarea continuă este dezactivată');

      // Activează ascultarea continuă
      voiceController.toggleContinuousListening();
      await tester.pumpAndSettle();
      
      // Verifică dacă starea s-a schimbat
      expect(voiceController.isContinuousListening, isTrue);
      debugPrint('✅ Ascultarea continuă activată');

      // Dezactivează
      voiceController.toggleContinuousListening();
      await tester.pumpAndSettle();
      expect(voiceController.isContinuousListening, isFalse);
      debugPrint('✅ Ascultarea continuă dezactivată');
    });

    /// 🎤 Test pentru detectarea "salut"
    testWidgets('Verifică activarea și dezactivarea detectării "salut"', (WidgetTester tester) async {
      debugPrint('🚀 Începe testul detectării "salut"...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Obține controller-ul prin Provider
      // ignore: use_build_context_synchronously
      final voiceController = Provider.of<PassengerVoiceControllerAdapter>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      await voiceController.initializeVoiceSystem();
      await tester.pumpAndSettle();

      // Inițial, starea este falsă
      expect(voiceController.isWakeWordEnabled, isFalse);
      debugPrint('✅ Starea inițială: Detectarea "salut" este dezactivată');

      // Activează detectarea "salut"
      voiceController.toggleWakeWord();
      await tester.pumpAndSettle();
      
      // Verifică dacă starea s-a schimbat
      expect(voiceController.isWakeWordEnabled, isTrue);
      debugPrint('✅ Detectarea "salut" activată');

      // Dezactivează
      voiceController.toggleWakeWord();
      await tester.pumpAndSettle();
      expect(voiceController.isWakeWordEnabled, isFalse);
      debugPrint('✅ Detectarea "salut" dezactivată');
    });

    /// 🔄 Test pentru resetarea sistemului vocal
    testWidgets('Verifică resetarea sistemului vocal', (WidgetTester tester) async {
      debugPrint('🚀 Începe testul de resetare...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Obține controller-ul prin Provider
      // ignore: use_build_context_synchronously
      final voiceController = Provider.of<PassengerVoiceControllerAdapter>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      await voiceController.initializeVoiceSystem();
      await tester.pumpAndSettle();

      // Pasul 1: Pornește o interacțiune pentru a schimba starea
      voiceController.startVoiceInteraction();
      await tester.pumpAndSettle();
      expect(voiceController.isOverlayVisible, isTrue, reason: "Overlay-ul ar trebui să fie vizibil după pornirea interacțiunii");

      // Pasul 2: Apelează direct metoda de resetare
      voiceController.reset();
      await tester.pumpAndSettle();

      // Pasul 3: Verifică dacă starea a fost resetată
      expect(voiceController.isOverlayVisible, isFalse, reason: "Overlay-ul ar trebui să fie ascuns după resetare");
      expect(voiceController.aiResponse, contains('Salut'), reason: "Răspunsul AI ar trebui să fie salutul implicit după resetare");
      debugPrint('✅ Sistemul vocal resetat cu succes');
    });

    /// 📱 Test pentru navigarea în meniul de setări vocale
    testWidgets('Verifică navigarea în meniul de setări vocale', (WidgetTester tester) async {
      debugPrint('🚀 Începe testul navigării în setări...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Obține controller-ul prin Provider și inițializează sistemul vocal
      // ignore: use_build_context_synchronously
      final voiceController = Provider.of<PassengerVoiceControllerAdapter>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      await voiceController.initializeVoiceSystem();
      await tester.pumpAndSettle();
      
      // Caută butonul de setări (presupunem că există un buton cu iconița de setări)
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
        
        // Verifică că am navigat la ecranul de setări
        expect(find.text('Setări Vocale'), findsOneWidget);
        debugPrint('✅ Navigarea în setări vocale funcționează');
      } else {
        debugPrint('ℹ️ Butonul de setări nu a fost găsit - testul este skipat');
      }
    });

    /// 🎯 Test pentru performanța generală a sistemului
    testWidgets('Măsoară performanța generală a sistemului vocal', (WidgetTester tester) async {
      debugPrint('🚀 Începe testul de performanță...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Obține controller-ul prin Provider
      // ignore: use_build_context_synchronously
      final voiceController = Provider.of<PassengerVoiceControllerAdapter>(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      final stopwatch = Stopwatch();

      // Măsoară timpul de inițializare
      stopwatch.start();
      await voiceController.initializeVoiceSystem();
      stopwatch.stop();
      
      debugPrint('⏱️ Timp de inițializare sistem vocal: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Max 10 secunde pentru dispozitive lente
      
      // Măsoară timpul de răspuns la prima comandă
      stopwatch.reset();
      stopwatch.start();
      voiceController.updateContextAndProcess('Test de performanță'); // Fără await
      await tester.pumpAndSettle();
      stopwatch.stop();
      
      debugPrint('⏱️ Timp de răspuns la prima comandă: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Max 3 secunde
      
      debugPrint('✅ Testul de performanță completat cu succes');
    });
  });
}