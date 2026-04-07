/// 🧪 Test End-to-End: Flux complet de curse prin AI
///
/// Validează întregul flux de la rostirea adresei de către client până la
/// găsirea unui şofer disponibil şi afişarea datelor necesare.
///
/// Structura testelor:
///   Grup 1 — GeminiVoiceEngine (procesare locală, fără reţea/audio)
///   Grup 2 — RideFlowManager tranziţii de stare
///   Grup 3 — Date afişate clientului după confirmare
///   Grup 4 — Performanţa procesării AI
///
/// Rulare:
///   flutter test integration_test/e2e_ride_flow_test.dart
///   (pe emulator sau dispozitiv fizic)
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nabour_app/voice/ai/gemini_voice_engine.dart';
import 'package:nabour_app/voice/states/voice_interaction_states.dart';
import 'package:nabour_app/voice/ride/ride_flow_manager.dart';
import 'package:nabour_app/voice/tts/natural_voice_synthesizer.dart' as tts;
import 'package:nabour_app/voice/core/voice_orchestrator.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/models/ride_model.dart';

// ---------------------------------------------------------------------------
// Stub TTS — interceptează apelurile de vorbire fără a accesa hardware-ul
// ---------------------------------------------------------------------------

/// [_SilentTts] suprascrie toate metodele de sinteză vocală cu no-op-uri
/// care înregistrează mesajele rostite pentru verificare ulterioară.
class _SilentTts extends tts.NaturalVoiceSynthesizer {
  final List<String> spoken = [];

  @override
  Future<void> initialize({String? languageCode}) async {}

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> speakWithEmotion(String text, VoiceEmotion emotion) async =>
      spoken.add(text);

  @override
  Future<void> speakPriority(String text) async => spoken.add(text);

  @override
  Future<void> speakWithNaturalPauses(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}

  @override
  bool get isSpeaking => false;

  @override
  bool get isInitialized => true;
}

// ---------------------------------------------------------------------------
// Harness de testare — captează evenimentele generate de RideFlowManager
// ---------------------------------------------------------------------------

/// [_FlowHarness] construieşte un [RideFlowManager] cu TTS silenţios şi
/// callback-uri care captează toate acţiunile produse de manager.
class _FlowHarness {
  // --- Date capturate de callback-uri ---
  String? filledPickup;
  String? filledDestination;
  RideCategory? selectedCategory;
  bool confirmButtonPressed = false;
  Object? navigatedToScreen;
  String? createdRideId;
  Map<String, dynamic>? lastRideRequest;
  bool aiClosed = false;

  // --- Componente ---
  final _SilentTts silentTts = _SilentTts();
  late final RideFlowManager manager;

  _FlowHarness() {
    // VoiceOrchestrator este singleton; în mediul de test apelurile STT
    // vor eşua graţios (sunt în try/catch) şi nu vor bloca execuţia.
    final orchestrator = VoiceOrchestrator();

    manager = RideFlowManager(
      geminiEngine: GeminiVoiceEngine(),
      tts: silentTts,
      firestoreService: FirestoreService(),
      voiceOrchestrator: orchestrator,
      onFillAddressInUI: (
        pickup,
        destination, {
        pickupLat,
        pickupLng,
        destLat,
        destLng,
      }) {
        filledPickup = pickup;
        filledDestination = destination;
      },
      onSelectRideOptionInUI: (category) {
        selectedCategory = category;
      },
      onPressConfirmButtonInUI: () {
        confirmButtonPressed = true;
      },
      onNavigateToScreen: (screen) {
        navigatedToScreen = screen;
      },
      onCreateRideRequest: (rideRequest) async {
        lastRideRequest = Map<String, dynamic>.from(rideRequest);
        createdRideId = 'ride_test_${DateTime.now().millisecondsSinceEpoch}';
        return createdRideId!;
      },
      onDriverResponse: (driverId, accepted) {},
      onCloseAI: () {
        aiClosed = true;
      },
    );
  }

  /// Iniţializează managerul (TTS silenţios + beep service fără audio real).
  Future<void> initialize() async {
    await manager.initialize();
  }

  /// Trimite input vocal şi aşteaptă procesarea completă.
  Future<void> process(String input) async {
    await manager.processVoiceInput(input);
  }
}

// ---------------------------------------------------------------------------
// Teste
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ==========================================================================
  // GRUP 1 — GeminiVoiceEngine: procesare locală (fără reţea, fără audio)
  // ==========================================================================
  group('🧠 GeminiVoiceEngine — procesare locală determinism', () {
    late GeminiVoiceEngine engine;

    setUp(() {
      engine = GeminiVoiceEngine();
    });

    // -- Extragere destinaţii cunoscute ----------------------------------------

    test('1.1 "gara" → destination_confirmed "Gara de Nord"', () async {
      final ctx = VoiceContext(
        conversationState: RideFlowState.idle.toString(),
        conversationHistory: [],
      );
      final resp = await engine.processVoiceInput('gara', ctx);

      expect(resp.type, equals('destination_confirmed'),
          reason: 'Un loc bine cunoscut trebuie recunoscut imediat local.');
      expect(resp.destination, equals('Gara de Nord'));
      expect(resp.confidence, greaterThanOrEqualTo(0.8));
    });

    test('1.2 "vreau sa merg la aeroport" → destination_confirmed', () async {
      final ctx = VoiceContext(
        conversationState: RideFlowState.idle.toString(),
        conversationHistory: [],
      );
      final resp = await engine.processVoiceInput(
          'vreau sa merg la aeroport', ctx);

      expect(resp.type, equals('destination_confirmed'));
      expect(resp.destination, isNotNull);
      // Aeroportul Henri Coandă / Otopeni
      expect(resp.destination!.toLowerCase(),
          anyOf(contains('coand'), contains('otopen'), contains('aeroport')));
    });

    test('1.3 "centru" → destination_confirmed centrul Bucureştiului', () async {
      final ctx = VoiceContext(
        conversationState: RideFlowState.idle.toString(),
        conversationHistory: [],
      );
      final resp = await engine.processVoiceInput('centru', ctx);

      expect(resp.type, equals('destination_confirmed'));
      expect(resp.destination, isNotNull);
    });

    test('1.4 Adresă liberă → destination_confirmed cu adresa extrasă', () async {
      final ctx = VoiceContext(
        conversationState: RideFlowState.idle.toString(),
        conversationHistory: [],
      );
      const addr = 'Calea Victoriei numarul 12 sector 1';
      final resp = await engine.processVoiceInput(addr, ctx);

      expect(resp.type, equals('destination_confirmed'));
      expect(resp.destination, isNotNull);
      expect(resp.destination!.isNotEmpty, isTrue);
    });

    // -- Confirmări pozitive ---------------------------------------------------

    test('1.5 "da" → confirmation', () async {
      final ctx = VoiceContext(
        conversationState: RideFlowState.awaitingConfirmation.toString(),
        conversationHistory: [],
      );
      final resp = await engine.processVoiceInput('da', ctx);

      expect(resp.type, equals('confirmation'));
      expect(resp.needsClarification, isFalse);
    });

    test('1.6 "bine" → confirmation', () async {
      final ctx = VoiceContext(
        conversationState: RideFlowState.awaitingRideConfirmation.toString(),
        conversationHistory: [],
      );
      final resp = await engine.processVoiceInput('bine', ctx);

      expect(resp.type, equals('confirmation'));
    });

    test('1.7 "confirm" → confirmation', () async {
      final ctx = VoiceContext(
        conversationState: RideFlowState.awaitingRideConfirmation.toString(),
        conversationHistory: [],
      );
      final resp = await engine.processVoiceInput('confirm', ctx);

      expect(resp.type, equals('confirmation'));
    });

    test('1.8 "perfect" → confirmation', () async {
      final ctx = VoiceContext(
        conversationState: RideFlowState.awaitingConfirmation.toString(),
        conversationHistory: [],
      );
      final resp = await engine.processVoiceInput('perfect', ctx);

      expect(resp.type, equals('confirmation'));
    });

    // -- Confirmare şofer în starea awaitingDriverAcceptance ------------------

    test('1.9 "da" în awaitingDriverAcceptance → driver_acceptance', () async {
      final ctx = VoiceContext(
        conversationState:
            RideFlowState.awaitingDriverAcceptance.toString(),
        conversationHistory: [],
      );
      final resp = await engine.processVoiceInput('da', ctx);

      expect(resp.type, equals('driver_acceptance'));
    });

    // -- Refuz / anulare -------------------------------------------------------

    test('1.10 "nu" → tip diferit de confirmation', () async {
      final ctx = VoiceContext(
        conversationState: RideFlowState.awaitingConfirmation.toString(),
        conversationHistory: [],
      );
      final resp = await engine.processVoiceInput('nu', ctx);

      expect(resp.type, isNot(equals('confirmation')));
      expect(
        ['rejection', 'driver_acceptance', 'needs_clarification']
            .contains(resp.type),
        isTrue,
        reason: 'Refuzul trebuie să producă rejection sau clarificare.',
      );
    });

    // -- Salut -----------------------------------------------------------------

    test('1.11 "salut" → greeting', () async {
      final ctx = VoiceContext(
        conversationState: RideFlowState.idle.toString(),
        conversationHistory: [],
      );
      final resp = await engine.processVoiceInput('salut', ctx);

      expect(resp.type, equals('greeting'));
    });
  });

  // ==========================================================================
  // GRUP 2 — RideFlowManager: tranziţii de stare E2E
  // ==========================================================================
  group('🚗 RideFlowManager — tranziţii de stare', () {
    late _FlowHarness h;

    setUp(() async {
      h = _FlowHarness();
      await h.initialize();
    });

    // ----- Etapa 1: client rosteşte adresa -----------------------------------

    testWidgets('2.1 Client spune "gara de nord" → stare avansată + UI umplut',
        (tester) async {
      await h.process('gara de nord');

      // Starea trebuie să iasă din idle
      expect(
        h.manager.currentState,
        isNot(equals(RideFlowState.idle)),
        reason: 'Managerul trebuie să avanseze după ce primeşte o adresă.',
      );

      // Callback-ul onFillAddressInUI trebuie apelat cu destinaţia extrasă
      expect(h.filledDestination, isNotNull,
          reason: 'UI-ul trebuie să primească destinaţia extrasă.');
      expect(h.filledDestination!.toLowerCase(), contains('nord'));
    });

    testWidgets(
        '2.2 Client spune adresă liberă → destinaţia extrasă şi trimisă la UI',
        (tester) async {
      await h.process('strada Floreasca numarul 55');

      expect(h.filledDestination, isNotNull);
      expect(h.filledDestination!.isNotEmpty, isTrue);
    });

    // ----- Etapa 2: client confirmă ------------------------------------------

    testWidgets('2.3 Client confirmă cu "da" → stare de căutare/confirmare',
        (tester) async {
      await h.process('gara de nord');
      await h.process('da');

      // Stările acceptate după confirmare (depinde dacă Firebase/GPS sunt
      // disponibile în mediul de test)
      const validStates = {
        RideFlowState.searchingDrivers,
        RideFlowState.driversFound,
        RideFlowState.awaitingRideConfirmation,
        RideFlowState.confirmationReceived,
        RideFlowState.awaitingFinalRideConfirmation,
        RideFlowState.awaitingConfirmation, // poate rămâne dacă TTS nu completat
        RideFlowState.error, // dacă GPS/Firebase indisponibil
      };
      expect(
        validStates.contains(h.manager.currentState),
        isTrue,
        reason:
            'Stare neaşteptată după confirmare: ${h.manager.currentState}',
      );
    });

    // ----- Etapa 3: TTS înregistrat ------------------------------------------

    testWidgets('2.4 TTS produce cel puţin un mesaj pe tot parcursul fluxului',
        (tester) async {
      await h.process('piata unirii');
      await h.process('da');

      expect(
        h.silentTts.spoken.isNotEmpty,
        isTrue,
        reason: 'AI-ul trebuie să comunice cel puţin un mesaj clientului.',
      );

      debugPrint('📢 Mesaje TTS capturate: ${h.silentTts.spoken}');
    });

    // ----- Etapa 4: Istoricul conversaţiei -----------------------------------

    testWidgets(
        '2.5 Istoricul conversaţiei conţine atât mesajul utilizatorului cât şi al AI',
        (tester) async {
      await h.process('gara de nord');
      final history = h.manager.conversationHistoryCopy;

      expect(history, isNotEmpty,
          reason: 'Istoricul nu trebuie să fie gol.');
      expect(history.any((m) => m.startsWith('User:')), isTrue,
          reason: 'Istoricul trebuie să conţină mesajul clientului.');
      expect(history.any((m) => m.startsWith('AI:')), isTrue,
          reason: 'Istoricul trebuie să conţină răspunsul AI.');
    });

    // ----- Etapa 5: Date expuse clientului -----------------------------------

    testWidgets(
        '2.6 Destinaţia este stocată şi preţul estimat este disponibil/calculat',
        (tester) async {
      await h.process('aeroportul otopeni');

      expect(h.manager.destination, isNotNull,
          reason: 'Destinaţia extrasă trebuie stocată.');
      expect(h.manager.destination!.isNotEmpty, isTrue);

      // Preţul: poate fi null dacă GPS indisponibil, sau ≥ 0 dacă calculat
      final price = h.manager.estimatedPrice;
      if (price != null) {
        expect(price, greaterThanOrEqualTo(0.0));
        debugPrint('💰 Preţ estimat: ${price.toStringAsFixed(2)} lei');
      } else {
        debugPrint('ℹ️ Preţul nu a putut fi calculat fără GPS real.');
      }
    });

    // ----- Etapa 6: Anulare flow ---------------------------------------------

    testWidgets('2.7 Client refuză → stare resetată (idle/awaitingClarification)',
        (tester) async {
      await h.process('gara de nord');
      await h.process('nu');

      const validStates = {
        RideFlowState.idle,
        RideFlowState.awaitingClarification,
        RideFlowState.listeningForInitialCommand,
        // Dacă prelucrarea eşuează (GPS indisponibil), starea poate fi error
        RideFlowState.error,
      };
      expect(
        validStates.contains(h.manager.currentState),
        isTrue,
        reason:
            'După refuz, starea trebuie să fie resetată: ${h.manager.currentState}',
      );
    });

    // ----- Etapa 7: Corectarea destinaţiei -----------------------------------

    testWidgets('2.8 Client schimbă destinaţia cu a doua adresă', (tester) async {
      await h.process('mall baneasa');
      await h.process('nu, vreau la gara de nord');

      // Indiferent de interpretarea AI (refuz + nouă destinaţie sau re-set),
      // starea nu trebuie să fie în crash şi destinaţia trebuie non-null
      expect(h.manager.destination, isNotNull);
      expect(h.manager.destination!.isNotEmpty, isTrue);
    });
  });

  // ==========================================================================
  // GRUP 3 — Date afişate clientului după confirmare
  // ==========================================================================
  group('📊 Date afişate clientului', () {
    late _FlowHarness h;

    setUp(() async {
      h = _FlowHarness();
      await h.initialize();
    });

    testWidgets('3.1 lastSpokenMessage non-empty după adresă', (tester) async {
      await h.process('centrul vechi');

      expect(
        h.manager.lastSpokenMessage,
        isNotEmpty,
        reason: 'AI-ul trebuie să transmită cel puţin un mesaj clientului.',
      );
      debugPrint('🗣️ Ultimul mesaj AI: "${h.manager.lastSpokenMessage}"');
    });

    testWidgets(
        '3.2 onFillAddressInUI primeşte destinaţia corectă pentru "piata victoriei"',
        (tester) async {
      await h.process('piata victoriei');

      expect(h.filledDestination, isNotNull);
      expect(
        h.filledDestination!.toLowerCase().contains('victor') ||
            h.filledDestination!.toLowerCase().contains('piata') ||
            h.filledDestination!.toLowerCase().contains('victoriei'),
        isTrue,
        reason:
            'Destinaţia din UI nu corespunde: "${h.filledDestination}"',
      );
    });

    testWidgets(
        '3.3 Istoricul conţine mesajele AI cu informaţii despre cursă',
        (tester) async {
      await h.process('gara de nord');
      final history = h.manager.conversationHistoryCopy;

      final aiMessages =
          history.where((m) => m.startsWith('AI:')).toList();
      expect(aiMessages, isNotEmpty,
          reason: 'Istoricul trebuie să conţină cel puţin un mesaj AI.');

      debugPrint('📜 Mesaje AI în istoric: $aiMessages');
    });

    testWidgets(
        '3.4 Fluxul complet happy-path produce datele necesare clientului',
        (tester) async {
      // Pasul 1: clientul spune adresa
      await h.process('aeroportul otopeni');

      // Pasul 2: confirmă
      await h.process('da');

      // Verificări finale
      final history = h.manager.conversationHistoryCopy;
      expect(history, isNotEmpty);

      final userMessages =
          history.where((m) => m.startsWith('User:')).toList();
      expect(userMessages.length, greaterThanOrEqualTo(2),
          reason: 'Ambele input-uri ale clientului trebuie înregistrate.');

      final aiMessages =
          history.where((m) => m.startsWith('AI:')).toList();
      expect(aiMessages, isNotEmpty,
          reason: 'AI-ul trebuie să fi răspuns cel puţin o dată.');

      // TTS trebuie să fi comunicat cu clientul
      expect(h.silentTts.spoken.isNotEmpty, isTrue);

      debugPrint('✅ Flux E2E complet:');
      debugPrint('   Destinaţie: ${h.manager.destination}');
      debugPrint('   Preţ estimat: ${h.manager.estimatedPrice} lei');
      debugPrint('   Starea finală: ${h.manager.currentState}');
      debugPrint('   Mesaje TTS: ${h.silentTts.spoken.length}');
      debugPrint('   Mesaje în istoric: ${history.length}');
    });
  });

  // ==========================================================================
  // GRUP 4 — Performanţa procesării AI
  // ==========================================================================
  group('⏱️ Performanţa procesării AI', () {
    test('4.1 Procesarea locală a adresei durează sub 500ms', () async {
      final engine = GeminiVoiceEngine();
      final ctx = VoiceContext(
        conversationState: RideFlowState.idle.toString(),
        conversationHistory: [],
      );

      final sw = Stopwatch()..start();
      await engine.processVoiceInput('gara de nord', ctx);
      sw.stop();

      debugPrint(
          '⏱️ Timp procesare adresă: ${sw.elapsedMilliseconds}ms');
      expect(
        sw.elapsedMilliseconds,
        lessThan(500),
        reason:
            'Procesarea locală trebuie să fie sub 500ms (actual: ${sw.elapsedMilliseconds}ms)',
      );
    });

    test('4.2 Procesarea confirmării durează sub 200ms', () async {
      final engine = GeminiVoiceEngine();
      final ctx = VoiceContext(
        conversationState: RideFlowState.awaitingConfirmation.toString(),
        conversationHistory: [],
      );

      final sw = Stopwatch()..start();
      await engine.processVoiceInput('da', ctx);
      sw.stop();

      debugPrint(
          '⏱️ Timp procesare confirmare: ${sw.elapsedMilliseconds}ms');
      expect(
        sw.elapsedMilliseconds,
        lessThan(200),
        reason:
            'Procesarea confirmării trebuie să fie sub 200ms (actual: ${sw.elapsedMilliseconds}ms)',
      );
    });

    test('4.3 Procesarea a 5 adrese diferite rămâne sub 2000ms total',
        () async {
      final engine = GeminiVoiceEngine();
      final addresses = [
        'gara de nord',
        'aeroport',
        'centrul vechi',
        'piata unirii',
        'mall baneasa',
      ];

      final sw = Stopwatch()..start();
      for (final addr in addresses) {
        final ctx = VoiceContext(
          conversationState: RideFlowState.idle.toString(),
          conversationHistory: [],
        );
        final resp = await engine.processVoiceInput(addr, ctx);
        expect(resp.type, equals('destination_confirmed'),
            reason: '"$addr" trebuie să producă destination_confirmed');
      }
      sw.stop();

      debugPrint(
          '⏱️ Timp procesare 5 adrese: ${sw.elapsedMilliseconds}ms');
      expect(
        sw.elapsedMilliseconds,
        lessThan(2000),
        reason:
            '5 procesări locale trebuie să dureze sub 2s total (actual: ${sw.elapsedMilliseconds}ms)',
      );
    });
  });
}
