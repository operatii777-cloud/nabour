import 'dart:convert';
import 'dart:ui' as ui;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/translation_service.dart';
import '../config/gemini_config.dart';
import '../../utils/input_validator.dart';
import 'package:nabour_app/utils/logger.dart';

/// ✅ Helper: Obține limba curentă din SharedPreferences
Future<String> _getCurrentLanguageCode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale');
    return code ?? 'ro'; // Default română
  } catch (e) {
    Logger.error('Error getting language: $e', tag: 'GEMINI_VOICE', error: e);
    return 'ro'; // Default română
  }
}

/// 🧠 Gemini Voice Engine - Funcționează EXACT ca interacțiunea cu Gemini Voice
/// 
/// Caracteristici:
/// - Răspuns instant (fără pauze)
/// - Înțelegere perfectă a contextului
/// - Procesare naturală a intențiilor
/// - Integrare completă cu Nabour
class GeminiVoiceEngine {
  static final GeminiVoiceEngine _instance = GeminiVoiceEngine._internal();
  factory GeminiVoiceEngine() => _instance;
  GeminiVoiceEngine._internal();

  // 🎯 Configurația se ia din GeminiConfig
  
  // 🎯 Context pentru conversația curentă
  final Map<String, dynamic> _conversationContext = {};
  GenerativeModel? _model;
  ChatSession? _chat;
  
  /// 🚀 Inițializează engine-ul Gemini
  Future<void> initialize() async {
    try {
      Logger.debug('Initializing...', tag: 'GEMINI_VOICE');
      
      // 🎯 Verific configurația
      if (!GeminiConfig.isValid) {
        throw Exception(GeminiConfig.configurationErrorMessage);
      }
      // Initializează modelul Gemini stateful (chat)
      final apiKey = GeminiConfig.apiKey;
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      _chat = _model!.startChat();
      
      Logger.info('Initialized successfully', tag: 'GEMINI_VOICE');
    } catch (e) {
      Logger.error('Initialization error: $e', tag: 'GEMINI_VOICE', error: e);
      rethrow;
    }
  }
  
  // 🚗 Context specific Nabour (pentru viitoare implementări)
  // String? _currentDestination;
  // String? _currentPickup;
  // double? _estimatedPrice;
  // List<String> _availableDrivers = [];
  
  /// 🎤 Procesează input-ul vocal EXACT ca Gemini Voice
  Future<GeminiVoiceResponse> processVoiceInput(String userInput, VoiceContext context, {String? languageCode}) async {
    try {
      Logger.debug('Processing: "$userInput"', tag: 'GEMINI_VOICE');

      // ✅ NOU: Obțin limba curentă dacă nu este specificată
      final currentLanguage = languageCode ?? await _getCurrentLanguageCode();
      
      // Încearcă procesarea locală inteligentă
      final localResponse = await _processLocalCommand(userInput, context: context, languageCode: currentLanguage);
      if (localResponse != null) {
        Logger.info('Local processing successful!', tag: 'GEMINI_VOICE');
        return localResponse;
      }

      if (!GeminiConfig.isValid) {
        Logger.warning('Gemini config invalid, using fallback', tag: 'GEMINI_VOICE');
        return await _createFallbackResponse(userInput, 'Gemini configuration invalid');
      }

      // Asigură inițializarea modelului și a sesiunii chat
      _model ??= GenerativeModel(model: 'gemini-1.5-flash', apiKey: GeminiConfig.apiKey);
      _chat ??= _model!.startChat();

      // ✅ NOU: Obțin limba curentă dacă nu este specificată
      final currentLang = languageCode ?? await _getCurrentLanguageCode();
      final prompt = _buildGeminiPrompt(userInput, context, languageCode: currentLang);

      // 1️⃣ Încercare cu sesiunea chat
      try {
        final chatResponse = await _chat!.sendMessage(
          Content.text(prompt),
        );
        final chatText = chatResponse.text ?? '';
        if (chatText.isNotEmpty) {
          final cleanedResponse = _cleanGeminiResponse(chatText);
          final parsedResponse = await _processGeminiResponse(cleanedResponse);
          _updateConversationContext(userInput, parsedResponse);
          return parsedResponse;
        }
        Logger.warning('Empty chat response, falling back to HTTP API', tag: 'GEMINI_VOICE');
      } catch (e) {
        Logger.error('Chat API error: $e', tag: 'GEMINI_VOICE', error: e);
      }

      // 2️⃣ Fallback la API HTTP cu retry
      try {
        final apiResponse = await _callGeminiAPIWithRetry(prompt);
        final extractedText = _extractTextFromHttpResponse(apiResponse);
        if (extractedText.isEmpty) {
          Logger.warning('Empty HTTP response payload', tag: 'GEMINI_VOICE');
          return await _createFallbackResponse(userInput, 'Empty response from Gemini');
        }
        final cleanedResponse = _cleanGeminiResponse(extractedText);
        final parsedResponse = await _processGeminiResponse(cleanedResponse);
        _updateConversationContext(userInput, parsedResponse);
        return parsedResponse;
      } catch (e) {
        Logger.error('HTTP API error: $e', tag: 'GEMINI_VOICE', error: e);
      }

      // Fallback generic dacă toate încercările eșuează
      return await _createFallbackResponse(userInput, 'No specific command detected');

    } catch (e) {
      Logger.error('Local processing error: $e', tag: 'GEMINI_VOICE', error: e);
      return await _createFallbackResponse(userInput, e.toString());
    }
  }

  /// 📤 Generează răspuns text la un prompt (pentru intent classification etc.)
  Future<String> generateRawText(String prompt) async {
    try {
      if (!GeminiConfig.isValid) return '';
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: GeminiConfig.apiKey);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? '';
    } catch (e) {
      Logger.error('Gemini generateRawText error: $e', tag: 'GEMINI_VOICE', error: e);
      return '';
    }
  }

  /// 🌐 Traduce un text folosind Gemini AI (pentru fallback sau chat)
  Future<String> translate(String text, String sourceLang, String targetLang) async {
    try {
      if (!GeminiConfig.isValid) return text;

      final prompt = '''
Translate the following text from $sourceLang to $targetLang.
Only return the translated text, nothing else. No explanation, no quotes.

Text: "$text"
''';

      // Folosim GenerativeModel direct (fără chat history) pentru o traducere rapidă
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: GeminiConfig.apiKey);
      final response = await model.generateContent([Content.text(prompt)]);
      
      final translated = response.text?.trim() ?? text;
      
      // Elimină ghilimelele dacă Gemini le-a adăugat
      if (translated.startsWith('"') && translated.endsWith('"')) {
        return translated.substring(1, translated.length - 1);
      }
      
      return translated;
    } catch (e) {
      Logger.error('Gemini translation error: $e', tag: 'GEMINI_VOICE', error: e);
      return text;
    }
  }
  
  /// 🎯 Construiește prompt-ul perfect pentru Gemini
  String _buildGeminiPrompt(String userInput, VoiceContext context, {String languageCode = 'ro'}) {
    // ✅ NOU: Generează prompt-ul în limba selectată
    if (languageCode == 'en') {
      return _buildGeminiPromptEnglish(userInput, context);
    } else {
      return _buildGeminiPromptRomanian(userInput, context);
    }
  }
  
  /// 🎯 Construiește prompt-ul în română
  String _buildGeminiPromptRomanian(String userInput, VoiceContext context) {
    return '''
Ești asistentul vocal pentru Nabour, o aplicație de ride sharing din România.

🎯 MOD AUTONOM: După ce utilizatorul confirmă destinația, procesezi TOTUL automat:
- Detectezi locația curentă automat
- Calculezi prețul automat  
- Cauți șoferi automat
- Selectezi cel mai bun șofer automat
- Trimiți cererea automat
- Anunți rezultatul final cu numele șoferului, ETA și preț

IMPORTANT: Dacă utilizatorul spune "nu vreau", "nu la", "nu merg la" + o locație, 
înseamnă că REFUZĂ acea destinație și vrea o destinație diferită.

CONTEXTUL CURENT:
- Destinație: ${context.destination ?? 'nedefinită'}
- Pickup: ${context.pickup ?? 'locația curentă'}
- Starea conversației: ${context.conversationState}
- Istoric: ${context.conversationHistory.take(3).join(', ')}

INPUT-UL UTILIZATORULUI: "$userInput"

INSTRUCȚIUNI:
1. Dacă utilizatorul REFUZĂ o destinație (spune "nu vreau să merg la X"), 
   răspunde cu type: "needs_clarification" și întreabă unde vrea să meargă.
2. Pentru locații noi, extrage destinația corectă și răspunde cu type: "destination".
3. Pentru confirmări pozitive ale destinației (da, confirm, ok), type: "destination_confirmed" pentru a declanșa procesarea automată.
4. Pentru confirmări generale, type: "confirmation".
5. Pentru confirmarea finală a rezervării, type: "final_confirmation".
6. Pentru cereri de cursă, type: "ride_request".
7. ✅ NOU: Dacă starea conversației conține "awaitingDriverAcceptance", utilizatorul trebuie să confirme sau să refuze șoferul care a acceptat cursa:
   - Dacă utilizatorul confirmă (da, bine, perfect, ok, sigur, continuă), type: "driver_acceptance" cu message pozitiv
   - Dacă utilizatorul refuză (nu, nu vreau, refuz), type: "driver_acceptance" cu message negativ

ANALIZEAZĂ INPUT-UL:
- Dacă utilizatorul spune o destinație (ex: "la gară", "la aeroport"), tipul este "destination"
- Dacă utilizatorul confirmă (ex: "da", "confirm", "bine", "perfect", "ok", "sigur"), tipul este "confirmation" SAU "driver_acceptance" (în funcție de stare)
- Dacă utilizatorul cere o cursă (ex: "vreau o cursă"), tipul este "ride_request"
- Dacă utilizatorul are nevoie de clarificare, tipul este "needs_clarification"
- Dacă utilizatorul confirmă rezervarea finală, tipul este "final_confirmation"
- ✅ NOU: Dacă starea este "awaitingDriverAcceptance" și utilizatorul spune "da"/"bine"/"perfect"/"ok"/"sigur", tipul este "driver_acceptance"
- ✅ NOU: Dacă starea este "awaitingDriverAcceptance" și utilizatorul spune "nu"/"nu vreau"/"refuz", tipul este "driver_acceptance" (refuz)

IMPORTANT PENTRU CONFIRMĂRI:
- "da" = confirmation (confidence: 0.9)
- "bine" = confirmation (confidence: 0.8)
- "perfect" = confirmation (confidence: 0.9)
- "ok" = confirmation (confidence: 0.8)
- "sigur" = confirmation (confidence: 0.9)
- "continuă" = confirmation (confidence: 0.8)
- "nu" = rejection (confidence: 0.9)
- "nu vreau" = rejection (confidence: 0.9)

RĂSPUNSUL TĂU (JSON):
{
  "type": "destination|destination_confirmed|confirmation|ride_request|needs_clarification|final_confirmation|driver_acceptance",
  "message": "Răspunsul tău natural în română",
  "confidence": 0.0-1.0,
  "needsClarification": true/false,
  "clarificationQuestion": "Întrebarea de clarificare dacă e necesară",
  "destination": "Destinația extrasă din input (pentru type: destination sau destination_confirmed)",
  "pickup": "Locația de preluare",
  "estimatedPrice": 0.0,
  "availableDrivers": [],
  "rideType": "standard",
  "preferredTime": null
}
''';
  }
  
  /// 🎯 Construiește prompt-ul în engleză
  String _buildGeminiPromptEnglish(String userInput, VoiceContext context) {
    return '''
You are the voice assistant for Nabour, a ride sharing app from Romania.

🎯 AUTONOMOUS MODE: After the user confirms the destination, you process EVERYTHING automatically:
- Detect current location automatically
- Calculate price automatically
- Search for drivers automatically
- Select the best driver automatically
- Send the request automatically
- Announce the final result with driver name, ETA and price

IMPORTANT: If the user says "I don't want", "not to", "I don't go to" + a location,
it means they REFUSE that destination and want a different destination.

CURRENT CONTEXT:
- Destination: ${context.destination ?? 'undefined'}
- Pickup: ${context.pickup ?? 'current location'}
- Conversation state: ${context.conversationState}
- History: ${context.conversationHistory.take(3).join(', ')}

USER INPUT: "$userInput"

INSTRUCTIONS:
1. If the user REFUSES a destination (says "I don't want to go to X"),
   respond with type: "needs_clarification" and ask where they want to go.
2. For new locations, extract the correct destination and respond with type: "destination".
3. For positive destination confirmations (yes, confirm, ok), type: "destination_confirmed" to trigger automatic processing.
4. For general confirmations, type: "confirmation".
5. For final booking confirmation, type: "final_confirmation".
6. For ride requests, type: "ride_request".
7. ✅ NEW: If the conversation state contains "awaitingDriverAcceptance", the user must confirm or reject the driver who accepted the ride:
   - If the user confirms (yes, good, perfect, ok, sure, continue), type: "driver_acceptance" with positive message
   - If the user rejects (no, I don't want, reject), type: "driver_acceptance" with negative message

ANALYZE THE INPUT:
- If the user says a destination (e.g., "to the station", "to the airport"), the type is "destination"
- If the user confirms (e.g., "yes", "confirm", "good", "perfect", "ok", "sure"), the type is "confirmation" OR "driver_acceptance" (depending on state)
- If the user requests a ride (e.g., "I want a ride"), the type is "ride_request"
- If the user needs clarification, the type is "needs_clarification"
- If the user confirms final booking, the type is "final_confirmation"
- ✅ NEW: If the state is "awaitingDriverAcceptance" and the user says "yes"/"good"/"perfect"/"ok"/"sure", the type is "driver_acceptance"
- ✅ NEW: If the state is "awaitingDriverAcceptance" and the user says "no"/"I don't want"/"reject", the type is "driver_acceptance" (rejection)

IMPORTANT FOR CONFIRMATIONS:
- "yes" = confirmation (confidence: 0.9)
- "good" = confirmation (confidence: 0.8)
- "perfect" = confirmation (confidence: 0.9)
- "ok" = confirmation (confidence: 0.8)
- "sure" = confirmation (confidence: 0.9)
- "continue" = confirmation (confidence: 0.8)
- "no" = rejection (confidence: 0.9)
- "I don't want" = rejection (confidence: 0.9)

YOUR RESPONSE (JSON):
{
  "type": "destination|destination_confirmed|confirmation|ride_request|needs_clarification|final_confirmation|driver_acceptance",
  "message": "Your natural response in English",
  "confidence": 0.0-1.0,
  "needsClarification": true/false,
  "clarificationQuestion": "Clarification question if needed",
  "destination": "Destination extracted from input (for type: destination or destination_confirmed)",
  "pickup": "Pickup location",
  "estimatedPrice": 0.0,
  "availableDrivers": [],
  "rideType": "standard",
  "preferredTime": null
}
''';
  }
  
  /// 🚀 Apelează Gemini API cu retry logic
  Future<String> _callGeminiAPIWithRetry(String prompt) async {
    final maxRetries = GeminiConfig.errorConfig['maxRetries'] as int;
    final retryDelay = GeminiConfig.errorConfig['retryDelay'] as int;
    final timeout = GeminiConfig.errorConfig['timeout'] as int;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        Logger.debug('API call attempt $attempt/$maxRetries', tag: 'GEMINI_VOICE');
        
        final response = await _callGeminiAPI(prompt)
            .timeout(Duration(milliseconds: timeout));
        
        Logger.info('API call successful on attempt $attempt', tag: 'GEMINI_VOICE');
        return response;
        
      } catch (e) {
        Logger.error('API call attempt $attempt failed: $e', tag: 'GEMINI_VOICE', error: e);
        
        if (attempt == maxRetries) {
          throw Exception('Gemini API failed after $maxRetries attempts: $e');
        }
        
        // 🎯 Pauză înainte de următoarea încercare
        await Future.delayed(Duration(milliseconds: retryDelay));
      }
    }
    
    throw Exception('Gemini API retry logic failed');
  }
  
  /// 🚀 Apelează Gemini API (metoda internă)
  Future<String> _callGeminiAPI(String prompt) async {
    // 🎯 Verific configurația
    if (!GeminiConfig.isValid) {
      Logger.warning('Gemini API Key invalid - falling back to local processing', tag: 'GEMINI_VOICE');
      throw Exception(GeminiConfig.configurationErrorMessage);
    }
    
    final url = Uri.parse(GeminiConfig.fullUrl);
    Logger.debug('Calling Gemini API: ${url.toString().replaceAll(RegExp(r'key=.*'), 'key=***')}', tag: 'GEMINI_VOICE');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              },
            ],
          },
        ],
        'generationConfig': GeminiConfig.generationConfig,
      }),
    );
    
    if (response.statusCode == 200) {
      return response.body;
    } else {
      // 🔍 Debug info pentru erori
      Logger.error('API Error ${response.statusCode}', tag: 'GEMINI_VOICE');
      Logger.debug('Response body: ${response.body}', tag: 'GEMINI_VOICE');
      
      if (response.statusCode == 404) {
        Logger.error('404 Error - Possible causes:', tag: 'GEMINI_VOICE');
        Logger.debug('- Invalid API key');
        Logger.debug('- Model name incorrect');
        Logger.debug('- API endpoint changed');
        Logger.info('Falling back to local processing');
      }
      
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }
  
  /// 🗺️ Clarifică o adresă și obține coordonate GPS folosind Gemini AI (pentru geocoding)
  /// Această metodă apelează direct API-ul Gemini cu un prompt specific pentru clarificarea adreselor,
  /// fără să treacă prin logica normală de procesare vocală
  /// Returnează un Map cu 'address' (adresa clarificată) și opțional 'latitude' și 'longitude' (dacă Gemini AI le poate oferi)
  Future<Map<String, dynamic>?> clarifyAddressForGeocoding(String originalAddress) async {
    try {
      Logger.debug('Clarifying address with Gemini AI: $originalAddress', tag: 'GEMINI_GEOCODE');
      
      if (!GeminiConfig.isValid) {
        Logger.warning('Gemini config invalid', tag: 'GEMINI_GEOCODE');
        return null;
      }
      
      // Construiește un prompt specific pentru clarificarea adresei și obținerea coordonatelor
      final prompt = '''
Ești un asistent pentru clarificarea adreselor în România și obținerea coordonatelor GPS.

TASK: Clarifică și completează următoarea adresă și, dacă este posibil, oferă coordonatele GPS exacte.

Adresa originală: "$originalAddress"

INSTRUCȚIUNI:
1. Clarifică adresa completă cu orașul și țara
2. Dacă știi coordonatele GPS exacte pentru această adresă în România, oferă-le
3. Returnează răspunsul în format JSON:
{
  "address": "Adresa clarificată completă, Oraș, România",
  "latitude": 44.4268 (sau null dacă nu știi),
  "longitude": 26.1025 (sau null dacă nu știi)
}

IMPORTANT:
- Dacă nu știi coordonatele exacte, setează latitude și longitude la null
- Adresa trebuie să fie completă și clară pentru geocoding
- Dacă adresa conține referințe la locații cunoscute (ex: "baraj", "sad", "lac"), încearcă să identifici locația exactă

Exemple:
- Input: "aeroport" → Output: {"address": "Aeroportul Henri Coandă, Otopeni, România", "latitude": 44.5721, "longitude": 26.0691}
- Input: "gară" → Output: {"address": "Gara de Nord, București, România", "latitude": 44.4478, "longitude": 26.0758}
- Input: "aleea barajului sadului nr 10" → Output: {"address": "Aleea Barajului Sadului, nr. 10, București, România", "latitude": null, "longitude": null} (dacă nu știi coordonatele exacte)

Răspuns JSON:
''';

      // Apelează direct API-ul Gemini fără logica de conversație
      String? extractedText;
      try {
        final apiResponse = await _callGeminiAPIWithRetry(prompt);
        extractedText = _extractTextFromHttpResponse(apiResponse);
      } catch (e) {
        Logger.error('Gemini API failed, trying fallback: $e', tag: 'GEMINI_GEOCODE', error: e);
        // ✅ FALLBACK: Dacă API-ul eșuează, încearcă să clarifice adresa local
        return _fallbackClarifyAddress(originalAddress);
      }
      
      if (extractedText.isEmpty) {
        Logger.warning('Empty response from Gemini, trying fallback', tag: 'GEMINI_GEOCODE');
        // ✅ FALLBACK: Dacă răspunsul este gol, încearcă clarificare locală
        return _fallbackClarifyAddress(originalAddress);
      }
      
      // Curăță răspunsul
      final cleanedResponse = _cleanGeminiResponse(extractedText);
      
      try {
        // Încearcă să parseze JSON-ul
        final jsonResponse = jsonDecode(cleanedResponse);
        
        final clarifiedAddress = jsonResponse['address'] as String?;
        final latitude = jsonResponse['latitude'] as num?;
        final longitude = jsonResponse['longitude'] as num?;
        
        if (clarifiedAddress == null || clarifiedAddress.isEmpty) {
          Logger.warning('No address in response', tag: 'GEMINI_GEOCODE');
          return null;
        }
        
        // Verifică dacă adresa clarificată este diferită de originală
        if (clarifiedAddress.toLowerCase() == originalAddress.toLowerCase()) {
          Logger.warning('Clarified address is same as original', tag: 'GEMINI_GEOCODE');
          return null;
        }
        
        // Verifică dacă răspunsul este valid (nu e un mesaj de eroare sau refuz)
        final lowerAddress = clarifiedAddress.toLowerCase();
        if (lowerAddress.contains('nu pot') || 
            lowerAddress.contains('nu știu') ||
            lowerAddress.contains('nu am putut') ||
            lowerAddress.contains('specificați') ||
            lowerAddress.contains('altă destinație') ||
            lowerAddress.length < 5) {
          Logger.warning('Gemini AI returned invalid response: $clarifiedAddress', tag: 'GEMINI_GEOCODE');
          return null;
        }
        
        final result = <String, dynamic>{
          'address': clarifiedAddress,
        };
        
        // Adaugă coordonatele dacă sunt disponibile și valide
        if (latitude != null && longitude != null) {
          final lat = latitude.toDouble();
          final lon = longitude.toDouble();
          
          // Validează coordonatele (România este între 43.5-48.5 lat și 20.0-30.0 lon)
          if (lat >= 43.5 && lat <= 48.5 && lon >= 20.0 && lon <= 30.0) {
            result['latitude'] = lat;
            result['longitude'] = lon;
            Logger.info('Gemini AI provided coordinates: $lat, $lon', tag: 'GEMINI_GEOCODE');
          } else {
            Logger.warning('Invalid coordinates from Gemini AI: $lat, $lon', tag: 'GEMINI_GEOCODE');
          }
        }
        
        Logger.info('Gemini AI clarified address: $clarifiedAddress', tag: 'GEMINI_GEOCODE');
        return result;
        
      } catch (e) {
        // Dacă nu e JSON valid, încearcă să extragă doar adresa din text
        Logger.warning('Could not parse JSON, trying to extract address from text: $e', tag: 'GEMINI_GEOCODE');
        
        String clarifiedAddress = cleanedResponse.trim();
        
        // Elimină prefixe comune
        final prefixes = ['Adresa clarificată:', 'Adresa:', 'Output:', 'Răspuns:', 'Clarificare:'];
        for (final prefix in prefixes) {
          if (clarifiedAddress.toLowerCase().startsWith(prefix.toLowerCase())) {
            clarifiedAddress = clarifiedAddress.substring(prefix.length).trim();
          }
        }
        
        // Elimină ghilimele dacă există
        if ((clarifiedAddress.startsWith('"') && clarifiedAddress.endsWith('"')) ||
            (clarifiedAddress.startsWith("'") && clarifiedAddress.endsWith("'"))) {
          clarifiedAddress = clarifiedAddress.substring(1, clarifiedAddress.length - 1).trim();
        }
        
        // Verifică dacă răspunsul este valid
        final lowerAddress = clarifiedAddress.toLowerCase();
        if (lowerAddress.contains('nu pot') || 
            lowerAddress.contains('nu știu') ||
            lowerAddress.contains('nu am putut') ||
            lowerAddress.contains('specificați') ||
            lowerAddress.contains('altă destinație') ||
            lowerAddress.length < 5) {
          Logger.warning('Gemini AI returned invalid response: $clarifiedAddress', tag: 'GEMINI_GEOCODE');
          return null;
        }
        
        // Verifică dacă adresa clarificată este diferită de originală
        if (clarifiedAddress.toLowerCase() == originalAddress.toLowerCase()) {
          Logger.warning('Clarified address is same as original', tag: 'GEMINI_GEOCODE');
          return null;
        }
        
        Logger.info('Gemini AI clarified address (text only): $clarifiedAddress', tag: 'GEMINI_GEOCODE');
        return {'address': clarifiedAddress};
      }
      
    } catch (e) {
      Logger.error('Error clarifying address: $e', tag: 'GEMINI_GEOCODE', error: e);
      // ✅ FALLBACK: Dacă toate încercările eșuează, încearcă clarificare locală
      return _fallbackClarifyAddress(originalAddress);
    }
  }
  
  /// 🔄 FALLBACK: Clarifică adresa local (fără API) când Gemini API eșuează
  Map<String, dynamic>? _fallbackClarifyAddress(String originalAddress) {
    try {
      Logger.warning('Using fallback local address clarification', tag: 'GEMINI_GEOCODE');
      
      // Normalizează adresa
      String clarified = originalAddress.trim();
      
      // Adaugă "România" dacă lipsește
      if (!clarified.toLowerCase().contains('românia') && 
          !clarified.toLowerCase().contains('romania')) {
        clarified = '$clarified, România';
      }
      
      // Încearcă să identifice orașul dacă lipsește (presupunem București pentru adrese comune)
      final lowerAddress = clarified.toLowerCase();
      if (!lowerAddress.contains('bucurești') && 
          !lowerAddress.contains('bucuresti') &&
          !lowerAddress.contains('otopeni') &&
          !lowerAddress.contains('ilfov')) {
        // Dacă adresa conține "baraj", "sad", "dunării", probabil e în București
        if (lowerAddress.contains('baraj') || 
            lowerAddress.contains('sad') || 
            lowerAddress.contains('dunării') ||
            lowerAddress.contains('dunarii')) {
          clarified = clarified.replaceAll(RegExp(r',\s*România$'), '');
          clarified = '$clarified, București, România';
        }
      }
      
      // Verifică dacă adresa clarificată este diferită de originală
      if (clarified.toLowerCase() == originalAddress.toLowerCase()) {
        Logger.warning('Fallback clarification same as original', tag: 'GEMINI_GEOCODE');
        return null;
      }
      
      Logger.warning('Fallback clarified address: $clarified', tag: 'GEMINI_GEOCODE');
      return {'address': clarified};
      
    } catch (e) {
      Logger.error('Fallback clarification error: $e', tag: 'GEMINI_GEOCODE', error: e);
      return null;
    }
  }
  
  /// 🔄 Procesează răspunsul de la Gemini
  Future<GeminiVoiceResponse> _processGeminiResponse(String apiResponse) async {
    try {
      // apiResponse este deja textul (JSON) al răspunsului modelului
      final cleanContent = _cleanGeminiResponse(apiResponse);
      
      // 📝 Parsez JSON-ul curat
      final parsedData = jsonDecode(cleanContent);
      
      return GeminiVoiceResponse.fromJson(parsedData);
      
    } catch (e) {
      Logger.error('Response parsing error: $e', tag: 'GEMINI_VOICE', error: e);
      return await _createFallbackResponse('', 'Response parsing failed');
    }
  }

  /// Extrage textul JSON din răspunsul HTTP clasic
  String _extractTextFromHttpResponse(String httpResponseBody) {
    try {
      final jsonResponse = jsonDecode(httpResponseBody);
      final content = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      return content ?? '';
    } catch (_) {
      return httpResponseBody;
    }
  }
  
  /// 🧹 Curăță răspunsul Gemini de markdown
  String _cleanGeminiResponse(String response) {
    // Elimin ```json și ``` dacă există
    if (response.contains('```json')) {
      response = response.split('```json')[1];
    }
    if (response.contains('```')) {
      response = response.split('```')[0];
    }
    
    // Elimin spațiile albe
    return response.trim();
  }
  
  /// 📝 Actualizează contextul conversației
  void _updateConversationContext(String userInput, GeminiVoiceResponse response) {
    _conversationContext['lastUserInput'] = userInput;
    _conversationContext['lastAIResponse'] = response.toJson();
    _conversationContext['timestamp'] = DateTime.now().toIso8601String();
    
    // 🚗 Actualizez contextul Nabour
    // if (response.destination != null) {
    //   _currentDestination = response.destination;
    // }
    // if (response.pickup != null) {
    //   _currentPickup = response.pickup;
    // }
    // if (response.estimatedPrice != null) {
    //   _estimatedPrice = response.estimatedPrice;
    // }
  }
  
  /// 🆘 Răspuns de fallback când Gemini eșuează - cu procesare locală inteligentă
  Future<GeminiVoiceResponse> _createFallbackResponse(String userInput, String error) async {
    Logger.warning('Using local fallback processing for: "$userInput"', tag: 'GEMINI_VOICE');
    
    // 🎯 Procesare locală inteligentă pentru comenzile comune
    final localResponse = await _processLocalCommand(userInput);
    if (localResponse != null) {
      return localResponse;
    }
    
    // 🆘 Fallback generic dacă nu pot procesa local
    return GeminiVoiceResponse(
      type: 'fallback',
      message: 'Îmi pare rău, am întâmpinat o problemă. Vă rog să repetați.',
      confidence: 0.0,
      needsClarification: true,
      clarificationQuestion: 'Puteți să repetați cererea?',
    );
  }

  /// 🧠 Procesare locală inteligentă pentru comenzile comune
  Future<GeminiVoiceResponse?> _processLocalCommand(String userInput, {VoiceContext? context, String? languageCode}) async {
    final input = userInput.toLowerCase().trim();
    
    // ✅ NOU: Folosirea TranslationService pentru a încerca o traducere locală
    // Dacă utilizatorul vorbește în engleză, traducem în română pentru procesarea interioară
    final translationService = TranslationService();
    final translatedInput = await translationService.translate(
      input,
      source: const ui.Locale('en'),
      target: const ui.Locale('ro'),
    );
    
    // De acum încolo putem folosi translatedInput pentru logică, 
    // dar păstrăm și originalul pentru cazul în care e deja în limba corectă.
    // ignore: unused_local_variable
    final effectiveInput = (translatedInput != input) ? translatedInput.toLowerCase() : input;

    // ✅ NOU: Obțin limba curentă dacă nu este specificată
    final currentLanguage = languageCode ?? await _getCurrentLanguageCode();
    
    // ✅ NOU: Verifică dacă starea este awaitingDriverAcceptance
    final isAwaitingDriverAcceptance = context != null && 
        (context.conversationState.contains('awaitingDriverAcceptance') || 
         context.conversationState.contains('RideFlowState.awaitingDriverAcceptance'));
    
    // 🎯 PRIORITATE 1: Detectez salutări (TREBUIE SĂ FIE PRIMELE!)
    if (input.contains('salut') || input.contains('bună') || input.contains('hello')) {
      return GeminiVoiceResponse(
        type: 'greeting',
        message: 'Salut! Unde doriți să mergeți astăzi?',
        confidence: 0.9,
        needsClarification: true,
        clarificationQuestion: 'Vă rog să specificați destinația.',
      );
    }
    
    // 🎯 PRIORITATE 2: Detectez confirmări
    final confirmations = ['da', 'confirm', 'corect', 'bine', 'perfect', 'ok', 'okay', 'sigur', 'continuă', 'merge'];
    if (confirmations.any((conf) => input == conf || input.startsWith('$conf ') || input.endsWith(' $conf'))) {
      Logger.info('Local processing: Positive confirmation detected', tag: 'GEMINI_VOICE');
      // ✅ FIX: Dacă starea este awaitingDriverAcceptance, returnează driver_acceptance
      if (isAwaitingDriverAcceptance) {
        return GeminiVoiceResponse(
          type: 'driver_acceptance',
          message: 'Perfect! Confirm că vrei să continui cu acest șofer.',
          confidence: 0.9,
          needsClarification: false,
        );
      }
      return GeminiVoiceResponse(
        type: 'confirmation',
        message: 'Excelent! Confirmarea a fost înregistrată.',
        confidence: 0.9,
        needsClarification: false,
      );
    }
    
    // 🎯 PRIORITATE 3: Detectez refuzuri
    if (input.contains('nu') || input.contains('refuz') || input.contains('nu vreau')) {
      // ✅ FIX: Dacă starea este awaitingDriverAcceptance, returnează driver_acceptance (refuz)
      if (isAwaitingDriverAcceptance) {
        return GeminiVoiceResponse(
          type: 'driver_acceptance',
          message: 'Înțeleg. Caut un alt șofer disponibil pentru dumneavoastră.',
          confidence: 0.9,
          needsClarification: false,
        );
      }
      return GeminiVoiceResponse(
        type: 'rejection',
        message: 'Înțeleg. Vă rog să specificați o altă destinație.',
        confidence: 0.8,
        needsClarification: true,
        clarificationQuestion: 'Unde doriți să mergeți în schimb?',
      );
    }
    
    // 🎯 PRIORITATE 4: Detectez destinații comune (pentru optimizare)
    // ✅ NOU: Dicționar dinamic bazat pe limba curentă
    final Map<String, String> destinations;
    if (currentLanguage == 'en') {
      destinations = {
        'north station': 'Gara de Nord',
        'train station': 'Gara de Nord',
        'railway station': 'Gara de Nord',
        'station': 'Gara de Nord',
        'airport': 'Aeroportul Henri Coandă',
        'bucharest airport': 'Aeroportul Henri Coandă',
        'otopeni airport': 'Aeroportul Henri Coandă',
        'center': 'Centrul Bucureștiului',
        'city center': 'Centrul Bucureștiului',
        'downtown': 'Centrul Bucureștiului',
        'old town': 'Centrul Vechi',
        'university': 'Universitatea București',
        'union square': 'Piața Unirii',
        'victory square': 'Piața Victoriei',
        'revolution square': 'Piața Revoluției',
        'romanian athenaeum': 'Ateneul Român',
        'athenaeum': 'Ateneul Român',
        'triumphal arch': 'Arcul de Triumf',
        'arch of triumph': 'Arcul de Triumf',
        'manuc\'s inn': 'Hanul lui Manuc',
        'choral temple': 'Templul Coral',
        'cec palace': 'Palatul CEC',
        'holocaust memorial': 'Memorialul Holocaustului',
        'bellu cemetery': 'Cimitirul Bellu',
        'military circle palace': 'Palatul Cercului Militar Național',
        'fire watchtower': 'Foișorul de Foc',
        'kretzulescu church': 'Biserica Kretzulescu',
        'mall': 'Mall Băneasa',
        'baneasa mall': 'Mall Băneasa',
        'afi mall': 'Mall AFI Cotroceni',
        'cotroceni': 'Mall AFI Cotroceni',
        'carrefour': 'Carrefour Orhideea',
        'carrefour orhideea': 'Carrefour Orhideea',
        'carrefour baneasa': 'Carrefour Băneasa',
        'mega image': 'Mega Image C. A. Rosetti',
        'mega image rosetti': 'Mega Image C. A. Rosetti',
        'mega image icoanei': 'Mega Image Icoanei',
        'mega image cotroceni': 'Mega Image Cotroceni',
        'mega image gemenii': 'Mega Image Piața Gemenii',
        'mega image vitan': 'Mega Image Piața Vitan',
        'lidl': 'Lidl Alexandru Șerbănescu',
        'lidl serbanescu': 'Lidl Alexandru Șerbănescu',
        'lidl gazarului': 'Lidl Drumul Gazarului',
        'lidl crisan': 'Lidl Serg. Ștefan Crișan',
        'lidl doina': 'Lidl Doina',
        'lidl maniu': 'Lidl Iuliu Maniu',
        'lidl timisoara': 'Lidl Timișoara',
        'kaufland': 'Kaufland Militari',
        'kaufland militari': 'Kaufland Militari',
        'kaufland baneasa': 'Kaufland Băneasa',
        'kaufland vitan': 'Kaufland Vitan',
        'profi': 'Profi Unirii',
        'profi unirii': 'Profi Unirii',
        'profi victoriei': 'Profi Victoriei',
        'profi romana': 'Profi Romană',
        'profi obor': 'Profi Obor',
        'caru cu bere': 'Caru\' cu Bere',
        'la mama': 'La Mama',
        'casa doina': 'Casa Doina',
        'mcdonalds': 'McDonald\'s Unirea',
        'mcdonalds unirea': 'McDonald\'s Unirea',
        'mcdonalds romana': 'McDonald\'s Romană',
        'mcdonalds vitan': 'McDonald\'s Vitan Mall',
        'mcdonalds parklake': 'McDonald\'s ParkLake',
        'mcdonalds otopeni': 'McDonald\'s Otopeni',
        'kfc': 'KFC Dorobanți',
        'kfc dorobanti': 'KFC Dorobanți',
        'kfc unirii': 'KFC Unirii',
        'kfc baneasa': 'KFC Băneasa',
        'kfc parklake': 'KFC ParkLake',
        'kfc otopeni': 'KFC Otopeni',
        'national arena': 'Arena Națională',
        'steaua stadium': 'Stadionul Steaua',
        'dinamo stadium': 'Stadionul Dinamo',
        'palace hall': 'Sala Palatului',
        'national opera': 'Opera Națională București',
        'national theatre': 'Teatrul Național "Ion Luca Caragiale"',
        'bulandra theatre': 'Teatrul Bulandra',
        'odeon theatre': 'Teatrul Odeon',
        'tineretului park': 'Parcul Tineretului',
        'ior park': 'Parcul IOR',
        'kiseleff park': 'Parcul Kiseleff',
        'sector 1 city hall': 'Primăria Sectorului 1',
        'sector 2 city hall': 'Primăria Sectorului 2',
        'sector 3 city hall': 'Primăria Sectorului 3',
        'prefecture': 'Prefectura Municipiului București',
        'government': 'Guvernul României',
        'victoria palace': 'Guvernul României',
      };
    } else {
      destinations = {
        'gara de nord': 'Gara de Nord',
        'gara nord': 'Gara de Nord', 
        'gara': 'Gara de Nord',
        'aeroport': 'Aeroportul Henri Coandă',
        'aeroportul': 'Aeroportul Henri Coandă',
        'centru': 'Centrul Bucureștiului',
        'centrul': 'Centrul Bucureștiului',
        'centrul vechi': 'Centrul Vechi',
        'universitate': 'Universitatea București',
        'piata unirii': 'Piața Unirii',
        'piata victoriei': 'Piața Victoriei',
        'piata revolutiei': 'Piața Revoluției',
        'revolutiei': 'Piața Revoluției',
        'ateneul roman': 'Ateneul Român',
        'ateneul': 'Ateneul Român',
        'arcul de triumf': 'Arcul de Triumf',
        'hanul lui manuc': 'Hanul lui Manuc',
        'manuc': 'Hanul lui Manuc',
        'templul coral': 'Templul Coral',
        'coral': 'Templul Coral',
        'palatul cec': 'Palatul CEC',
        'cec': 'Palatul CEC',
        'memorialul holocaustului': 'Memorialul Holocaustului',
        'holocaust': 'Memorialul Holocaustului',
        'cimitirul bellu': 'Cimitirul Bellu',
        'bellu': 'Cimitirul Bellu',
        'palatul cercului militar': 'Palatul Cercului Militar Național',
        'cercul militar': 'Palatul Cercului Militar Național',
        'foisorul de foc': 'Foișorul de Foc',
        'foisor': 'Foișorul de Foc',
        'biserica kretzulescu': 'Biserica Kretzulescu',
        'kretzulescu': 'Biserica Kretzulescu',
        'sfantul sava': 'Colegiul Național "Sfântul Sava"',
        'sava': 'Colegiul Național "Sfântul Sava"',
        'caragiale': 'Colegiul Național "I.L. Caragiale"',
        'lazar': 'Colegiul Național "Gheorghe Lazăr"',
        'vianu': 'Colegiul Național de Informatică "Tudor Vianu"',
        'viteazul': 'Colegiul Național "Mihai Viteazul"',
        'haret': 'Colegiul Național "Spiru Haret"',
        'policlinica gomoiu': 'Policlinica "Dr. Victor Gomoiu"',
        'policlinica cantacuzino': 'Policlinica "Dr. Ion Cantacuzino"',
        'policlinica davila': 'Policlinica "Dr. Carol Davila"',
        'primaria sector 1': 'Primăria Sectorului 1',
        'primaria sector 2': 'Primăria Sectorului 2',
        'primaria sector 3': 'Primăria Sectorului 3',
        'primaria sector 4': 'Primăria Sectorului 4',
        'primaria sector 5': 'Primăria Sectorului 5',
        'primaria sector 6': 'Primăria Sectorului 6',
        'prefectura': 'Prefectura Municipiului București',
        'guvern': 'Guvernul României',
        'palatul victoria': 'Guvernul României',
        'victoria': 'Guvernul României',
        'parcul tineretului': 'Parcul Tineretului',
        'tineretului': 'Parcul Tineretului',
        'parcul ior': 'Parcul IOR',
        'ior': 'Parcul IOR',
        'parcul kiseleff': 'Parcul Kiseleff',
        'kiseleff': 'Parcul Kiseleff',
        'arena nationala': 'Arena Națională',
        'stadionul national': 'Arena Națională',
        'steaua': 'Stadionul Steaua',
        'stadion steaua': 'Stadionul Steaua',
        'dinamo': 'Stadionul Dinamo',
        'stadion dinamo': 'Stadionul Dinamo',
        'sala palatului': 'Sala Palatului',
        'opera nationala': 'Opera Națională București',
        'opera': 'Opera Națională București',
        'teatrul national': 'Teatrul Național "Ion Luca Caragiale"',
        'teatru national': 'Teatrul Național "Ion Luca Caragiale"',
        'bulandra': 'Teatrul Bulandra',
        'odeon': 'Teatrul Odeon',
        'carrefour': 'Carrefour Orhideea',
        'carrefour orhideea': 'Carrefour Orhideea',
        'carrefour baneasa': 'Carrefour Băneasa',
        'mega image': 'Mega Image C. A. Rosetti',
        'mega image rosetti': 'Mega Image C. A. Rosetti',
        'mega image icoanei': 'Mega Image Icoanei',
        'mega image cotroceni': 'Mega Image Cotroceni',
        'mega image gemenii': 'Mega Image Piața Gemenii',
        'mega image vitan': 'Mega Image Piața Vitan',
        'lidl': 'Lidl Alexandru Șerbănescu',
        'lidl serbanescu': 'Lidl Alexandru Șerbănescu',
        'lidl gazarului': 'Lidl Drumul Gazarului',
        'lidl crisan': 'Lidl Serg. Ștefan Crișan',
        'lidl doina': 'Lidl Doina',
        'lidl maniu': 'Lidl Iuliu Maniu',
        'lidl timisoara': 'Lidl Timișoara',
        'kaufland': 'Kaufland Militari',
        'kaufland militari': 'Kaufland Militari',
        'kaufland baneasa': 'Kaufland Băneasa',
        'kaufland vitan': 'Kaufland Vitan',
        'profi': 'Profi Unirii',
        'profi unirii': 'Profi Unirii',
        'profi victoriei': 'Profi Victoriei',
        'profi romana': 'Profi Romană',
        'profi obor': 'Profi Obor',
        'caru cu bere': 'Caru\' cu Bere',
        'la mama': 'La Mama',
        'casa doina': 'Casa Doina',
        'mcdonalds': 'McDonald\'s Unirea',
        'mcdonalds unirea': 'McDonald\'s Unirea',
        'mcdonalds romana': 'McDonald\'s Romană',
        'mcdonalds vitan': 'McDonald\'s Vitan Mall',
        'mcdonalds parklake': 'McDonald\'s ParkLake',
        'mcdonalds otopeni': 'McDonald\'s Otopeni',
        'kfc': 'KFC Dorobanți',
        'kfc dorobanti': 'KFC Dorobanți',
        'kfc unirii': 'KFC Unirii',
        'kfc baneasa': 'KFC Băneasa',
        'kfc parklake': 'KFC ParkLake',
        'kfc otopeni': 'KFC Otopeni',
        'mall': 'Mall Băneasa',
        'mall băneasa': 'Mall Băneasa',
        'mall afi': 'Mall AFI Cotroceni',
        'cotroceni': 'Mall AFI Cotroceni',
      };
    }
    
    // 🔍 Caut destinația în input
    for (final entry in destinations.entries) {
      if (input.contains(entry.key)) {
        Logger.info('Local processing: Found known destination "${entry.value}"', tag: 'GEMINI_VOICE');
        return GeminiVoiceResponse(
          type: 'destination_confirmed',
          message: 'Perfect! Am înțeles că doriți să mergeți la ${entry.value}.',
          confidence: 0.9,
          needsClarification: false,
          destination: entry.value,
        );
      }
    }
    
    // 🎯 PRIORITATE 5: ORICE ALTCEVA = DESTINAȚIE!
    // Dacă nu e salut, confirmare sau refuz → este o destinație
    if (input.isNotEmpty && input.length > 2) {
      // ✅ FIX: Folosește input-ul deja curățat din ride_flow_manager (nu mai curăța aici)
      // ride_flow_manager._cleanInputFromTTS() deja face curățarea completă
      // Aici doar folosim input-ul curățat direct
      String cleanedDestination = userInput.trim();
      
      // ✅ FIX: Verifică dacă input-ul conține cuvinte cheie de adresă
      // Dacă da, elimină doar prefixele foarte comune, dar păstrează restul
      final addressKeywords = ['aleea', 'alee', 'strada', 'stradă', 'bulevardul', 'bulevard', 'nr', 'număr', 'bloc', 'scara'];
      final hasAddressKeywords = cleanedDestination.toLowerCase().split(' ').any((word) => 
        addressKeywords.any((keyword) => word.contains(keyword))
      );
      
      // Elimină doar prefixele foarte comune (doar dacă nu e o adresă completă cu cuvinte cheie)
      if (!hasAddressKeywords || cleanedDestination.length < 20) {
        final prefixes = ['la ', 'in ', 'spre ', 'către ', 'vreau la ', 'vreau sa merg la ', 'du-mă la '];
        for (final prefix in prefixes) {
          if (cleanedDestination.toLowerCase().startsWith(prefix)) {
            final afterPrefix = cleanedDestination.substring(prefix.length).trim();
            // Verifică dacă după prefix rămâne o adresă validă (minim 5 caractere)
            if (afterPrefix.length >= 5) {
              cleanedDestination = afterPrefix;
              break;
            }
          }
        }
      }
      
      Logger.info('Local processing: Treating "$cleanedDestination" as destination', tag: 'GEMINI_VOICE');
      return GeminiVoiceResponse(
        type: 'destination_confirmed',
        message: 'Perfect! Am înțeles că doriți să mergeți la $cleanedDestination.',
        confidence: 0.85,
        needsClarification: false,
        destination: cleanedDestination,
      );
    }
    
    return null; // Input prea scurt
  }
  
  /// 🛑 Oprește procesarea
  Future<void> stop() async {
    try {
      Logger.debug('Stopping...', tag: 'GEMINI_VOICE');
      _conversationContext.clear();
      Logger.info('Stopped successfully', tag: 'GEMINI_VOICE');
    } catch (e) {
      Logger.error('Stop error: $e', tag: 'GEMINI_VOICE', error: e);
    }
  }
  
  /// 🧹 Cleanup
  void dispose() {
    _conversationContext.clear();
    _chat = null;
  }

  /// 🎤 Procesează comanda vocală (alias pentru processVoiceInput)
  Future<GeminiVoiceResponse> processVoiceCommand(String userInput, VoiceContext context) async {
    // ✅ SECURITY: Validate input before processing
    final validation = InputValidator.validateVoiceCommand(userInput);
    if (!validation.isValid) {
      return GeminiVoiceResponse(
        type: 'needs_clarification',
        message: validation.error ?? 'Comandă invalidă',
        confidence: 0.0,
        needsClarification: true,
      );
    }
    
    // ✅ SECURITY: Rate limiting (use conversationState as identifier)
    final identifier = 'voice_${context.conversationState}';
    if (!InputValidator.checkRateLimit(identifier)) {
      return GeminiVoiceResponse(
        type: 'needs_clarification',
        message: 'Prea multe comenzi. Vă rog să așteptați puțin.',
        confidence: 0.0,
        needsClarification: true,
      );
    }
    return await processVoiceInput(userInput, context);
  }
  
  /// 🎤 Pornește ascultarea (delegat către VoiceOrchestrator)
  Future<void> startListening() async {
    // Această funcționalitate este gestionată de VoiceOrchestrator
    Logger.info('Start listening delegated to VoiceOrchestrator', tag: 'GEMINI_VOICE');
  }
  
  /// 🛑 Oprește ascultarea (delegat către VoiceOrchestrator)
  Future<void> stopListening() async {
    // Această funcționalitate este gestionată de VoiceOrchestrator
    Logger.info('Stop listening delegated to VoiceOrchestrator', tag: 'GEMINI_VOICE');
  }
  
  /// 🗣️ Vorbește textul (delegat către TTS)
  Future<void> speak(String text) async {
    // Această funcționalitate este gestionată de NaturalVoiceSynthesizer
    Logger.debug('Speak delegated to TTS: $text', tag: 'GEMINI_VOICE');
  }
}

/// 🎯 Contextul conversației vocale
class VoiceContext {
  final String? destination;
  final String? pickup;
  final String conversationState;
  final List<String> conversationHistory;
  
  VoiceContext({
    this.destination,
    this.pickup,
    required this.conversationState,
    required this.conversationHistory,
  });
}

/// 🗣️ Răspunsul de la Gemini Voice Engine
class GeminiVoiceResponse {
  final String type; // 'destination', 'confirmation', 'ride_request', etc.
  final String? message;
  final double confidence;
  final bool needsClarification;
  final String? clarificationQuestion;
  
  // 🚗 Câmpuri specifice Nabour
  final String? destination;
  final String? pickup;
  final double? estimatedPrice;
  final List<String>? availableDrivers;
  final String? rideType;
  final DateTime? preferredTime;
  
  GeminiVoiceResponse({
    required this.type,
    this.message,
    required this.confidence,
    required this.needsClarification,
    this.clarificationQuestion,
    this.destination,
    this.pickup,
    this.estimatedPrice,
    this.availableDrivers,
    this.rideType,
    this.preferredTime,
  });
  
  /// 📝 Convertește în JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'confidence': confidence,
      'needsClarification': needsClarification,
      'clarificationQuestion': clarificationQuestion,
      'destination': destination,
      'pickup': pickup,
      'estimatedPrice': estimatedPrice,
      'availableDrivers': availableDrivers,
      'rideType': rideType,
      'preferredTime': preferredTime?.toIso8601String(),
    };
  }
  
  /// 📝 Convertește din JSON
  factory GeminiVoiceResponse.fromJson(Map<String, dynamic> json) {
    return GeminiVoiceResponse(
      type: json['type'] ?? 'unknown',
      message: json['message'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      needsClarification: json['needsClarification'] ?? false,
      clarificationQuestion: json['clarificationQuestion'],
      destination: json['destination'],
      pickup: json['pickup'],
      estimatedPrice: json['estimatedPrice']?.toDouble(),
      availableDrivers: json['availableDrivers'] != null 
          ? List<String>.from(json['availableDrivers'])
          : null,
      rideType: json['rideType'],
      preferredTime: json['preferredTime'] != null 
          ? DateTime.parse(json['preferredTime'])
          : null,
    );
  }
}
