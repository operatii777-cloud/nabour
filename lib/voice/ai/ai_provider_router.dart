import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:nabour_app/utils/logger.dart';
import '../config/cerebras_config.dart';
import '../config/grok_config.dart';
import 'gemini_voice_engine.dart';

/// Router multi-provider AI — alege automat cel mai ieftin provider disponibil.
///
/// Ordinea de prioritate (cost crescător):
///   1. Cerebras  (~$0.10/M tokens  — cel mai ieftin, cel mai rapid)
///   2. Gemini    (~$0.50/M tokens  — fallback principal)
///   3. Grok      (~$2.00/M tokens  — fallback final, capabilități avansate)
///
/// Dacă un provider returnează eroare sau nu e configurat, se trece automat
/// la următorul. Răspunsul e întotdeauna un [GeminiVoiceResponse] (format unificat).
class AIProviderRouter {
  static final AIProviderRouter _instance = AIProviderRouter._internal();
  factory AIProviderRouter() => _instance;
  AIProviderRouter._internal();

  static const String _tag = 'AI_ROUTER';

  static const String _systemPrompt = '''
Ești asistentul vocal Nabour. Analizează input-ul utilizatorului și returnează EXCLUSIV un JSON valid (fără markdown, fără text suplimentar) cu structura:
{
  "type": "<destination|confirmation|cancellation|greeting|help|unknown>",
  "message": "<răspuns natural în română>",
  "confidence": <0.0-1.0>,
  "needsClarification": <true|false>,
  "clarificationQuestion": "<întrebare dacă needsClarification=true, altfel null>",
  "destination": "<adresa destinației dacă e menționată, altfel null>",
  "pickup": "<adresa de preluare dacă e menționată, altfel null>",
  "rideType": "<standard|premium|shared|null>"
}
''';

  /// Încearcă providerii în ordine de cost și returnează primul răspuns valid.
  /// Verifică soldul de tokeni înainte de orice apel AI.
  Future<GeminiVoiceResponse> route(
    String userInput,
    VoiceContext context, {
    String languageCode = 'ro',
  }) async {
    // ── Verificare și deducere tokeni ─────────────────────────────────────
    final tokenResult = await TokenService().spend(TokenTransactionType.aiQuery);
    if (!tokenResult.success) {
      Logger.warning('Deducere tokeni eșuată: ${tokenResult.errorMessage}', tag: _tag);
      final isInsufficient = tokenResult.errorMessage?.contains('insuficient') ?? false;
      
      return GeminiVoiceResponse(
        type: 'token_limit',
        message: isInsufficient 
            ? 'Ai epuizat tokenii. Accesează Profilul → Tokeni pentru a cumpăra mai mulți sau așteaptă resetul lunar.'
            : 'Contul tău de tokeni nu a putut fi accesat. Te rugăm să închizi și să redeschizi aplicația.',
        confidence: 1.0,
        needsClarification: false,
      );
    }

    final prompt = _buildPrompt(userInput, context, languageCode);

    // 1️⃣ Cerebras — cel mai ieftin
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
    } else {
      Logger.debug('Cerebras neconfigurat, se sare', tag: _tag);
    }

    // 2️⃣ Gemini — fallback principal (gestionat de GeminiVoiceEngine)
    try {
      Logger.debug('Încerc Gemini...', tag: _tag);
      final geminiEngine = GeminiVoiceEngine();
      final geminiResp = await geminiEngine.processVoiceInput(
        userInput,
        context,
        languageCode: languageCode,
      );
      Logger.info('Răspuns de la Gemini', tag: _tag);
      return geminiResp;
    } catch (e) {
      Logger.warning('Gemini a eșuat: $e', tag: _tag);
    }

    // 3️⃣ Grok — fallback final
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
    } else {
      Logger.debug('Grok neconfigurat, se sare', tag: _tag);
    }

    // Toți providerii au eșuat
    Logger.error('Toți providerii AI au eșuat, răspuns fallback', tag: _tag);
    return _fallbackResponse(userInput);
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

  GeminiVoiceResponse _fallbackResponse(String input) {
    return GeminiVoiceResponse(
      type: 'unknown',
      message: 'Momentan nu pot procesa cererea. Încearcă din nou sau folosește butoanele.',
      confidence: 0.0,
      needsClarification: false,
    );
  }
}
