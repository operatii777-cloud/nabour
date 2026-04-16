import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/utils/logger.dart';
import '../config/cerebras_config.dart';
import '../config/grok_config.dart';
import 'gemini_voice_engine.dart';

/// Router multi-provider AI — alege automat cel mai bun provider disponibil.
///
/// Ordinea de prioritate:
///   1. Cerebras  (cel mai rapid, cost minim)
///   2. Grok      (fallback secundar, procesare avansată)
///   3. Gemini    (fallback final)
///
/// Dacă un provider returnează eroare sau nu e configurat, se trece automat
/// la următorul. Răspunsul e întotdeauna un [GeminiVoiceResponse] (format unificat).
///
/// **On-device întâi:** NLP local din [GeminiVoiceEngine] rulează înainte de deducerea
/// tokenilor, astfel încât asistentul rămâne util offline / fără sold / fără rețea
/// pentru comenzile recunoscute local.
class AIProviderRouter {
  static final AIProviderRouter _instance = AIProviderRouter._internal();
  factory AIProviderRouter() => _instance;
  AIProviderRouter._internal();

  static const String _tag = 'AI_ROUTER';

  static const String _systemPrompt = '''
Ești "Nabour Gemini OS", nucleul inteligent al aplicației Nabour.
Personalitate: Ultra-competent, empatic, rapid, stil "Gemini Live Real". Nu ești un simplu chat, ești interfața directă a utilizatorului cu sistemul Nabour.

OBIECTIV: Îndeplinește orice sarcină pe care utilizatorul ar face-o prin butoane, exclusiv prin voce.

CAPABILITĂȚI ȘI COMENZI (type: "app_action"):
- "open_map", "open_profile", "open_settings", "open_help", "show_history", "wallet", "find_neighbor".
- "add_stop": Adaugă o destinație intermediară.
- "rate_driver": Oferă stele (1-5) și comentariu șoferului.
- "send_message": Trimite mesaj șoferului curent.
- "toggle_theme": Schimbă Mod Noapte/Zi.
- "change_language": Schimbă limba (ro/en).
- "logout": Deconectare securizată.

RIDE FLOW (type: "destination", "ride_request"):
- Extrage adresa exactă. Dacă e ambiguă, cere clarificări scurte.
- Dacă utilizatorul vrea o categorie specifică (Premium, XL, Economy), setează "rideType".

INFO GENERALĂ / AJUTOR (type: "help_response"):
- Răspunde la orice întrebare a utilizatorului, chiar dacă nu are legătură cu Nabour (ex: curs BNR, vreme, istorie, restaurante etc.).
- Fii scurt, precis și revino subtil la Nabour dacă e cazul (ex: "Cursul euro este X. Te pot ajuta să ajungi la o bancă?").

STIL CONVERSAȚIE:
- Folosește filleri naturali: "Aha", "Hmm", "Sigur", "Imediat", "O secundă", "Să vedem".
- Dacă sarcina e complexă, confirmă pas cu pas.

RĂSPUNS JSON STRICT (FĂRĂ ALT TEXT):
{
  "type": "destination|destination_confirmed|confirmation|ride_request|needs_clarification|final_confirmation|driver_acceptance|app_action|help_response",
  "message": "Răspunsul tău vocal ultra-natural",
  "confidence": 0.98,
  "needsClarification": false,
  "clarificationQuestion": null,
  "destination": "Adresa (dacă e cazul)",
  "appAction": "nume_actiune",
  "appScreen": "nume_ecran",
  "rideType": "economy|premium|xl",
  "suggestedActions": ["listă", "acțiuni"]
}
''';

  /// Încearcă mai întâi NLP on-device, apoi (dacă e nevoie de LLM în cloud) deduce tokeni
  /// și încearcă Cerebras → Grok → Gemini.
  Future<GeminiVoiceResponse> route(
    String userInput,
    VoiceContext context, {
    String languageCode = 'ro',
  }) async {
    final engine = GeminiVoiceEngine();

    // 1) NLP local + asistent on-device (fără API). Funcționează offline.
    final onDevice = await engine.processVoiceInput(
      userInput,
      context,
      languageCode: languageCode,
      skipRemoteLLM: true,
    );
    if (_isSatisfiedByOnDeviceAssistant(onDevice)) {
      Logger.info('Răspuns on-device (fără tokeni cloud)', tag: _tag);
      return onDevice;
    }

    // 2) LLM cloud: tokeni obligatorii
    final tokenResult = await TokenService().spend(TokenTransactionType.aiQuery);
    if (!tokenResult.success) {
      Logger.warning(
        'Deducere tokeni eșuată: ${tokenResult.errorMessage} — păstrăm ghidajul on-device',
        tag: _tag,
      );
      return onDevice;
    }

    final prompt = _buildPrompt(userInput, context, languageCode);

    // 1️⃣ Cerebras — Prima opțiune
    if (CerebrasConfig.isValid) {
      final result = await _callOpenAICompatible(
        name: 'Cerebras',
        url: CerebrasConfig.baseUrl,
        headers: CerebrasConfig.headers,
        body: CerebrasConfig.buildRequestBody(_systemPrompt, prompt),
        timeout: CerebrasConfig.timeout,
      );
      if (result != null) {
        Logger.info('Răspuns de la Cerebras', tag: _tag);
        return result;
      }
    }

    // 2️⃣ Grok (Groq) — Fallback secundar
    if (GrokConfig.isValid) {
      final result = await _callOpenAICompatible(
        name: 'Grok',
        url: GrokConfig.baseUrl,
        headers: GrokConfig.headers,
        body: GrokConfig.buildRequestBody(_systemPrompt, prompt),
        timeout: GrokConfig.timeout,
      );
      if (result != null) {
        Logger.info('Răspuns de la Grok', tag: _tag);
        return result;
      }
    }

    // 3️⃣ Gemini (API) — Fallback final (include rețea; NLP local deja încercat)
    try {
      Logger.debug('Încerc Gemini (fallback final)...', tag: _tag);
      final geminiResp = await engine.processVoiceInput(
        userInput,
        context,
        languageCode: languageCode,
        skipRemoteLLM: false,
      );
      Logger.info('Răspuns de la Gemini', tag: _tag);
      return geminiResp;
    } catch (e) {
      Logger.warning('Gemini a eșuat: $e', tag: _tag);
    }

    // Toți providerii au eșuat
    Logger.error('Toți providerii AI au eșuat', tag: _tag);
    return onDevice;
  }

  /// Dacă NLP-ul local a rezolvat clar, nu mai cheltuim tokeni pe cloud.
  /// `offline_guidance` = doar mesaj de ajutor când NLP strict nu a clasificat — încercăm LLM dacă avem tokeni.
  bool _isSatisfiedByOnDeviceAssistant(GeminiVoiceResponse r) {
    return r.type != 'fallback' && r.type != 'offline_guidance';
  }


  /// Apelează orice API OpenAI-compatibil și parsează răspunsul.
  Future<GeminiVoiceResponse?> _callOpenAICompatible({
    required String name,
    required String url,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    required Duration timeout,
  }) async {
    try {
      Logger.debug('Încerc $name...', tag: _tag);
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        Logger.warning(
          '$name HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}',
          tag: _tag,
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;

      final content =
          (choices.first as Map<String, dynamic>)['message']?['content'] as String?;
      if (content == null || content.isEmpty) return null;

      return _parseJsonResponse(content);
    } catch (e) {
      Logger.warning('$name eroare: $e', tag: _tag);
      return null;
    }
  }

  /// Parsează JSON-ul returnat de orice provider în [GeminiVoiceResponse].
  GeminiVoiceResponse? _parseJsonResponse(String raw) {
    try {
      // Elimină eventuale backtick-uri markdown
      final cleaned = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return GeminiVoiceResponse.fromJson(json);
    } catch (e) {
      Logger.warning('Parse JSON eșuat: $e', tag: _tag);
      return null;
    }
  }

  String _buildPrompt(String input, VoiceContext ctx, String lang) {
    final buffer = StringBuffer();
    buffer.writeln('Limbă răspuns: $lang');
    if (ctx.userName != null) {
      buffer.writeln('Utilizator: ${ctx.userName}');
    }
    if (ctx.userLocation != null) {
      buffer.writeln('Locație actuală: ${ctx.userLocation}');
    }
    if (ctx.destination != null) {
      buffer.writeln('Destinație curentă: ${ctx.destination}');
    }
    if (ctx.pickup != null) {
      buffer.writeln('Punct preluare: ${ctx.pickup}');
    }
    if (ctx.conversationHistory.isNotEmpty) {
      buffer.writeln('Istoric recent: ${ctx.conversationHistory.take(3).join(' | ')}');
    }
    buffer.writeln('Input utilizator: $input');
    return buffer.toString();
  }
}
