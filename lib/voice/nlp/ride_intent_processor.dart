import 'dart:async';
import 'dart:isolate';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:nabour_app/config/environment.dart';
import 'package:nabour_app/services/nabour_functions.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🚀 ISOLATE OPTIMIZATION: Advanced NLP processing in background isolates
/// 
/// Features:
/// - Background processing to prevent UI blocking
/// - Intent caching for faster recognition
/// - Parallel processing for multiple requests
/// - Memory-efficient communication
class RideIntentProcessor {
  static final RideIntentProcessor _instance = RideIntentProcessor._internal();
  factory RideIntentProcessor() => _instance;
  RideIntentProcessor._internal();

  // ISOLATE OPTIMIZATION: Isolate management
  static Isolate? _processingIsolate;
  static SendPort? _isolateSendPort;
  static ReceivePort? _mainReceivePort;
  static bool _isIsolateInitialized = false;
  static bool _isInitializing = false; // *** CORECTAT: Mutat aici ca static ***
  
  // ISOLATE OPTIMIZATION: Request queue and caching
  static final Map<String, RideIntent> _intentCache = {};
  static final List<_IntentRequest> _requestQueue = [];
  static int _requestCounter = 0;
  static const int _maxCacheSize = 500;

  
  // ISOLATE OPTIMIZATION: Performance monitoring
  static final Map<String, DateTime> _requestTimes = {};
  static final Map<String, Duration> _processingTimes = {};
  
  /// 🚀 ISOLATE OPTIMIZATION: Initialize isolate for background processing
  static Future<void> initializeIsolate() async {
    // *** CORECTAT: Verificare dublă pentru a preveni multiple isolate-uri ***
    if (_isIsolateInitialized && _processingIsolate != null && _isolateSendPort != null) {
      Logger.info('Isolate already initialized and ready, skipping...', tag: 'ISOLATE_NLP');
      return;
    }
    
    // *** CORECTAT: Verificare dacă se inițializează deja ***
    if (_isInitializing) {
      Logger.debug('Isolate is already initializing, waiting...', tag: 'ISOLATE_NLP');
      // Așteaptă până se termină inițializarea
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    _isInitializing = true;
    
    try {
      Logger.info('Initializing background NLP isolate...', tag: 'ISOLATE_NLP');
      
      // *** CORECTAT: Cleanup complet înainte de recreare ***
      if (_mainReceivePort != null) {
        Logger.debug('Cleaning up existing ports...', tag: 'ISOLATE_NLP');
        _mainReceivePort!.close();
        _mainReceivePort = null;
      }
      
      if (_processingIsolate != null) {
        Logger.debug('Killing existing isolate...', tag: 'ISOLATE_NLP');
        _processingIsolate!.kill();
        _processingIsolate = null;
      }
      
      _isolateSendPort = null;
      _isIsolateInitialized = false;
      
      _mainReceivePort = ReceivePort();
      
      // Spawn isolate for NLP processing
      _processingIsolate = await Isolate.spawn(
        _isolateEntryPoint,
        _mainReceivePort!.sendPort,
      );
      
      // Wait for isolate to be ready
      final completer = Completer<void>();
      late StreamSubscription subscription;
      
      subscription = _mainReceivePort!.listen((message) {
        if (message is Map && message['type'] == 'isolate_ready') {
          _isolateSendPort = message['sendPort'] as SendPort;
          _isIsolateInitialized = true;
          completer.complete();
          subscription.cancel();
        }
      });
      
      await completer.future.timeout(const Duration(seconds: 10));
      
      // *** CORECTAT: Nu mai asculta de două ori pe același port ***
      // _mainReceivePort!.listen(_handleIsolateMessage); // REMOVED - duplicat!
      
      Logger.info('Background NLP isolate initialized successfully', tag: 'ISOLATE_NLP');
      
    } catch (e) {
      Logger.error('Failed to initialize isolate: $e', tag: 'ISOLATE_NLP', error: e);
      _isIsolateInitialized = false;
      _mainReceivePort?.close();
      _mainReceivePort = null;
      _processingIsolate?.kill();
      _processingIsolate = null;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Isolate entry point
  static void _isolateEntryPoint(SendPort mainSendPort) async {
    final isolateReceivePort = ReceivePort();
    
    // Send back the SendPort for two-way communication
    mainSendPort.send({
      'type': 'isolate_ready',
      'sendPort': isolateReceivePort.sendPort,
    });
    
    Logger.info('NLP isolate started successfully', tag: 'ISOLATE_NLP');
    
    // Listen for processing requests
    await for (final message in isolateReceivePort) {
      if (message is Map) {
        try {
          await _processRequestInIsolate(Map<String, dynamic>.from(message), mainSendPort);
        } catch (e) {
          Logger.error('Error processing request in isolate: $e', tag: 'ISOLATE_NLP', error: e);
          mainSendPort.send({
            'type': 'error',
            'requestId': message['requestId'],
            'error': e.toString(),
          });
        }
      }
    }
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Process intent request in isolate
  static Future<void> _processRequestInIsolate(
    Map<String, dynamic> request,
    SendPort mainSendPort,
  ) async {
    final requestId = request['requestId'] as String;
    final text = request['text'] as String;
    final type = request['type'] as String;
    
    try {
      Logger.debug('Processing request in isolate: $requestId', tag: 'ISOLATE_NLP');
      
      RideIntent result;
      
      switch (type) {
        case 'process_intent':
          result = await _processIntentInIsolate(text);
          break;
        case 'extract_location':
          result = await _extractLocationInIsolate(text);
          break;
        case 'analyze_context':
          result = await _analyzeContextInIsolate(text, request['context']);
          break;
        default:
          throw Exception('Unknown request type: $type');
      }
      
      mainSendPort.send({
        'type': 'result',
        'requestId': requestId,
        'result': result.toMap(),
      });
      
      Logger.info('Request processed successfully: $requestId', tag: 'ISOLATE_NLP');
      
    } catch (e) {
      Logger.error('Error in isolate processing: $e', tag: 'ISOLATE_NLP', error: e);
      mainSendPort.send({
        'type': 'error',
        'requestId': requestId,
        'error': e.toString(),
      });
    }
  }
  
  /// Doar pattern-uri locale — Gemini rulează pe firul principal (Firebase + Callable).
  static Future<RideIntent> _processIntentInIsolate(String text) async {
    return _processLocalPatterns(text);
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Extract location in isolate
  static Future<RideIntent> _extractLocationInIsolate(String text) async {
    final locations = _extractLocationsFromText(text);
    
    return RideIntent(
      type: RideIntentType.location,
      destination: locations.isNotEmpty ? locations.first : '',
      pickupLocation: 'current_location',
      confidence: locations.isNotEmpty ? 0.9 : 0.3,
      parameters: {'locations': locations},
    );
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Analyze context in isolate
  static Future<RideIntent> _analyzeContextInIsolate(String text, Map<String, dynamic>? context) async {
    // Context-aware processing
    final baseIntent = await _processIntentInIsolate(text);
    
    if (context != null) {
      // Enhance intent with context
      if (context['previousDestination'] != null && baseIntent.destination.isEmpty) {
        // Create new intent with updated values
        final updatedIntent = RideIntent(
          type: baseIntent.type,
          destination: context['previousDestination'] as String? ?? baseIntent.destination,
          pickupLocation: baseIntent.pickupLocation,
          confidence: (baseIntent.confidence + 0.2).clamp(0.0, 1.0),
          parameters: baseIntent.parameters,
          needsClarification: baseIntent.needsClarification,
          clarificationQuestion: baseIntent.clarificationQuestion,
        );
        return updatedIntent;
      }
    }
    
    return baseIntent;
  }
  
  // *** CORECTAT: Metoda comentată temporar - nu mai este folosită ***
  // /// 🚀 ISOLATE OPTIMIZATION: Handle messages from isolate
  // static void _handleIsolateMessage(dynamic message) {
  //   if (message is Map) {
  //     final type = message['type'] as String;
  //     final requestId = message['requestId'] as String?;
  //     
  //     if (requestId != null) {
  //       final request = _requestQueue.firstWhere(
  //         (req) => req.id == requestId,
  //         orElse: () => _IntentRequest('', '', RideIntentType.unknown),
  //       );
  //       
  //       if (request.id == requestId) {
  //         switch (type) {
  //           case 'result':
  //             final resultMap = message['result'] as Map<String, dynamic>;
  //             final result = RideIntent.fromMap(resultMap);
  //             request.completer.complete(result);
  //             break;
  //         case 'error':
  //             final error = message['error'] as String;
  //             request.completer.completeError(Exception(error));
  //             break;
  //       }
  //       
  //       _requestQueue.removeWhere((req) => req.id == requestId);
  //       
  //       // Record processing time
  //       final startTime = _requestTimes[requestId];
  //       if (startTime != null) {
  //         _processingTimes[requestId] = DateTime.now().difference(startTime);
  //         _requestTimes.remove(requestId);
  //       }
  //     }
  //   }
  // }
  
  /// 🚀 ISOLATE OPTIMIZATION: Process intent with caching and isolate
  Future<RideIntent> processIntent(String text) async {
    try {
      // Check cache first
      final cacheKey = text.toLowerCase().trim();
      final cached = _getCachedIntent(cacheKey);
      if (cached != null) {
        Logger.info('Using cached intent for: $text', tag: 'ISOLATE_NLP');
        return cached;
      }
      
      // *** CORECTAT: Nu mai inițializez isolate-ul aici - se face doar în main.dart ***
      // if (!_isIsolateInitialized) {
      //   await initializeIsolate();
      // }
      
      // Create request
      final requestId = 'intent_${++_requestCounter}';
      final request = _IntentRequest(requestId, text, RideIntentType.destination);
      _requestQueue.add(request);
      _requestTimes[requestId] = DateTime.now();
      
      // Send to isolate
      _isolateSendPort!.send({
        'type': 'process_intent',
        'requestId': requestId,
        'text': text,
      });
      
      // Wait for result (local patterns din isolate)
      var result = await request.completer.future;

      // Gemini pe firul principal: Callable (cheie pe server) sau fallback dev cu cheie locală
      if (result.confidence < 0.9) {
        try {
          final gemini = await _processWithGeminiSecure(text);
          if (gemini.confidence >= result.confidence) {
            result = gemini;
          }
        } catch (e) {
          Logger.debug('Gemini secure path skipped: $e', tag: 'GEMINI_API');
        }
      }

      // Cache successful result
      if (result.confidence > 0.5) {
        _cacheIntent(cacheKey, result);
      }

      return result;
      
    } catch (e) {
      Logger.error('Error processing intent: $e', tag: 'ISOLATE_NLP', error: e);
      // Fallback to local processing
      return _processLocalPatterns(text);
    }
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Extract locations with isolate
  Future<List<String>> extractLocations(String text) async {
    try {
      final intent = await _processWithIsolate('extract_location', text);
      return (intent.parameters['locations'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      
    } catch (e) {
      Logger.error('Error extracting locations: $e', tag: 'ISOLATE_NLP', error: e);
      return _extractLocationsFromText(text);
    }
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Extract intent from text
  Future<RideIntent> extractIntent(String text) async {
    return await processIntent(text);
  }

  /// 🚀 ISOLATE OPTIMIZATION: Process ride request
  Future<RideIntent> processRideRequest(String text) async {
    return await processIntent(text);
  }

  /// 🚀 ISOLATE OPTIMIZATION: Generic isolate processing
  Future<RideIntent> _processWithIsolate(String type, String text, {Map<String, dynamic>? context}) async {
    // *** CORECTAT: Nu mai inițializez isolate-ul aici - se face doar în main.dart ***
    // if (!_isIsolateInitialized) {
    //   await initializeIsolate();
    // }
    
    final requestId = '${type}_${++_requestCounter}';
    final request = _IntentRequest(requestId, text, RideIntentType.unknown);
    _requestQueue.add(request);
    _requestTimes[requestId] = DateTime.now();
    
    _isolateSendPort!.send({
      'type': type,
      'requestId': requestId,
      'text': text,
      'context': context,
    });
    
    return await request.completer.future;
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Cache management
  static RideIntent? _getCachedIntent(String key) {
    return _intentCache[key];
  }
  
  static void _cacheIntent(String key, RideIntent intent) {
    _intentCache[key] = intent;
    
    // Cleanup cache if too large
    if (_intentCache.length > _maxCacheSize) {
      final excess = _intentCache.length - _maxCacheSize;
      final keysToRemove = _intentCache.keys.take(excess).toList();
      for (final key in keysToRemove) {
        _intentCache.remove(key);
      }
    }
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Local pattern processing (fast path)
  static RideIntent _processLocalPatterns(String text) {
    final lowerText = text.toLowerCase().trim();

    // ✅ Check saved-address aliases FIRST (before generic 'la ' extraction)
    // so "vreau să merg la acasă" / "vreau să merg acasă" both resolve to alias
    if (lowerText.contains('acasă') || lowerText.contains('acasa')) {
      return RideIntent(
        type: RideIntentType.destination,
        destination: 'Acasă',
        pickupLocation: 'current_location',
        confidence: 0.9,
        parameters: {'method': 'local_pattern', 'alias': 'true'},
      );
    }

    if (lowerText.contains('serviciu') || lowerText.contains('birou') || lowerText.contains('muncă')) {
      return RideIntent(
        type: RideIntentType.destination,
        destination: 'Serviciu',
        pickupLocation: 'current_location',
        confidence: 0.9,
        parameters: {'method': 'local_pattern', 'alias': 'true'},
      );
    }

    // Fast pattern matching for generic destinations
    if (lowerText.contains('du-mă') || lowerText.contains('mergi') || lowerText.contains('la ')) {
      final destination = _extractDestinationFromText(lowerText);
      return RideIntent(
        type: RideIntentType.destination,
        destination: destination,
        pickupLocation: 'current_location',
        confidence: destination.isNotEmpty ? 0.8 : 0.4,
        parameters: {'method': 'local_pattern'},
      );
    }
    
    if (lowerText.contains('anulează') || lowerText.contains('oprește') || lowerText.contains('stop')) {
      return RideIntent(
        type: RideIntentType.cancel,
        destination: '',
        pickupLocation: 'current_location',
        confidence: 0.95,
        parameters: {'method': 'local_pattern'},
      );
    }
    
    return RideIntent(
      type: RideIntentType.unknown,
      destination: '',
      pickupLocation: 'current_location',
      confidence: 0.1,
      parameters: {'method': 'local_pattern'},
    );
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Extract destination from text
  static String _extractDestinationFromText(String text) {
    final patterns = [
      RegExp(r'(?:du-mă|mergi|la)\s+(.+)', caseSensitive: false),
      RegExp(r'vreau\s+(?:să\s+merg\s+)?la\s+(.+)', caseSensitive: false),
      RegExp(r'destinația?\s+(?:este\s+)?(.+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    
    return '';
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Extract locations from text
  static List<String> _extractLocationsFromText(String text) {
    final locations = <String>[];
    
    // Common location patterns in Romanian
    final patterns = [
      RegExp(r'(?:la|în|pe|prin)\s+([A-Z][a-zA-ZĂÂÎŞŞăâîşţ\s]{2,})', caseSensitive: false),
      RegExp(r'\b([A-Z][a-zA-ZĂÂÎŞŞăâîşţ\s]{2,})\s+(?:sector|strada|stația)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        if (match.group(1) != null) {
          locations.add(match.group(1)!.trim());
        }
      }
    }
    
    return locations.toSet().toList(); // Remove duplicates
  }
  
  static String _buildGeminiNlpPrompt(String text) {
    return '''
      Ești un procesor de limbaj natural pentru o aplicație de ride-sharing din România, numită Nabour.
      Rolul tău este să analizezi textul utilizatorului și să extragi intenția și entitățile relevante pentru o comandă.
      Răspunde OBLIGATORIU în format JSON, fără excepții. Nu adăuga text înainte sau după JSON.

      Textul utilizatorului: "$text"

      Entitățile posibile pe care le poți extrage sunt:
      - "destination": Destinația cursei.
      - "pickup": Punctul de preluare. Dacă nu este specificat, folosește "current_location".
      - "time_info": Orice referință la timp (ex: "acum", "peste 10 minute", "la 17:30").
      - "category": Tipul cursei, dacă este specificat (ex: "economic", "confort", "XL").

      Tipurile de intenție posibile sunt:
      - "destination": Utilizatorul specifică o destinație.
      - "cancel": Utilizatorul vrea să anuleze ceva.
      - "status": Utilizatorul cere starea unei curse.
      - "unknown": Intenția nu este clară.

      Analizează textul și returnează un JSON cu următoarea structură:
      {
        "type": "tipul_intentiei",
        "destination": "destinatia_extrasa_sau_goala",
        "pickup": "preluarea_extrasa_sau_current_location",
        "confidence": valoare_intre_0.0_si_1.0,
        "parameters": {
          "time_info": "informatie_timp_sau_goala",
          "category": "categorie_cursa_sau_goala"
        }
      }
      ''';
  }

  static String _stripGeminiMarkdownJson(String content) {
    var c = content.trim();
    if (c.startsWith('```json')) {
      c = c.replaceFirst('```json', '').replaceFirst('```', '').trim();
    }
    if (c.startsWith('```')) {
      c = c.replaceFirst('```', '').replaceFirst('```', '').trim();
    }
    return c;
  }

  static RideIntent _rideIntentFromGeminiJsonString(String cleanedJson) {
    final intentData = jsonDecode(cleanedJson) as Map<String, dynamic>;
    final confRaw = intentData['confidence'];
    final conf = confRaw is num ? confRaw.toDouble() : 0.7;
    return RideIntent(
      type: _parseIntentType('${intentData['type'] ?? 'unknown'}'),
      destination: '${intentData['destination'] ?? ''}',
      pickupLocation: '${intentData['pickup'] ?? 'current_location'}',
      confidence: conf,
      parameters: Map<String, dynamic>.from(intentData['parameters'] as Map? ?? {}),
    );
  }

  /// Preferă `nabourGeminiProxy` (cheie pe server). Fallback: cheie în `.env` doar dacă `PREFER_SERVER_GEMINI=false`.
  static Future<RideIntent> _processWithGeminiSecure(String text) async {
    if (Environment.preferServerGemini || Environment.geminiApiKey.isEmpty) {
      try {
        final callable =
            NabourFunctions.instance.httpsCallable('nabourGeminiProxy');
        final res = await callable
            .call({'prompt': _buildGeminiNlpPrompt(text)})
            .timeout(const Duration(seconds: 25));
        final map = Map<String, dynamic>.from(res.data as Map);
        final raw = map['text'] as String? ?? '';
        final cleaned = _stripGeminiMarkdownJson(raw);
        Logger.debug('Gemini proxy JSON: $cleaned', tag: 'GEMINI_API');
        return _rideIntentFromGeminiJsonString(cleaned);
      } on FirebaseFunctionsException catch (e) {
        Logger.warning(
            'nabourGeminiProxy: ${e.code} ${e.message}', tag: 'GEMINI_API');
        if (!Environment.preferServerGemini &&
            Environment.geminiApiKey.isNotEmpty) {
          return _processWithGeminiDirectClient(text);
        }
        rethrow;
      }
    }
    return _processWithGeminiDirectClient(text);
  }

  static Future<RideIntent> _processWithGeminiDirectClient(String text) async {
    final apiKey = Environment.geminiApiKey;
    if (apiKey.isEmpty) return _processLocalPatterns(text);

    Logger.warning(
      'Gemini: apel direct din client (evită în producție). Setează nabourGeminiProxy + GEMINI_API_KEY pe Functions.',
      tag: 'GEMINI_API',
    );

    final prompt = _buildGeminiNlpPrompt(text);
    final response = await http
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {'parts': [{'text': prompt}]}
            ]
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      Logger.error(
          'Gemini direct HTTP ${response.statusCode}: ${response.body}',
          tag: 'GEMINI_API');
      return _processLocalPatterns(text);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    String content =
        (data['candidates'] as List).first['content']['parts'][0]['text'] as String;
    content = _stripGeminiMarkdownJson(content);
    return _rideIntentFromGeminiJsonString(content);
  }
  
  /// Parse intent type from string
  static RideIntentType _parseIntentType(String type) {
    switch (type.toLowerCase()) {
      case 'destination':
        return RideIntentType.destination;
      case 'cancel':
        return RideIntentType.cancel;
      case 'location':
        return RideIntentType.location;
      case 'status':
        return RideIntentType.unknown; // Map to unknown for now
      default:
        return RideIntentType.unknown;
    }
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Get processing statistics
  Map<String, dynamic> getProcessingStats() {
    return {
      'isIsolateInitialized': _isIsolateInitialized,
      'cacheSize': _intentCache.length,
      'queueSize': _requestQueue.length,
      'averageProcessingTime': _calculateAverageProcessingTime(),
      'cacheHitRate': _calculateCacheHitRate(),
    };
  }
  
  static Duration _calculateAverageProcessingTime() {
    if (_processingTimes.isEmpty) return Duration.zero;
    
    final totalMs = _processingTimes.values
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return Duration(milliseconds: totalMs ~/ _processingTimes.length);
  }
  
  static double _calculateCacheHitRate() {
    // This would need to track cache hits vs misses
    return 0.0; // Placeholder
  }
  
  /// 🚀 ISOLATE OPTIMIZATION: Cleanup resources
  static Future<void> dispose() async {
    try {
      _processingIsolate?.kill();
      _mainReceivePort?.close();
      _intentCache.clear();
      _requestQueue.clear();
      _requestTimes.clear();
      _processingTimes.clear();
      _isIsolateInitialized = false;
      
      Logger.info('Resources disposed successfully', tag: 'ISOLATE_NLP');
      
    } catch (e) {
      Logger.error('Error disposing resources: $e', tag: 'ISOLATE_NLP', error: e);
    }
  }
}

/// 🚀 ISOLATE OPTIMIZATION: Request wrapper for isolate communication
class _IntentRequest {
  final String id;
  final String text;
  final RideIntentType type;
  final Completer<RideIntent> completer = Completer<RideIntent>();
  
  _IntentRequest(this.id, this.text, this.type);
}

/// Ride intent types
enum RideIntentType {
  destination,
  pickup,
  cancel,
  location,
  unknown,
}

/// Ride intent result
class RideIntent {
  final RideIntentType type;
  final String destination;
  final String pickupLocation;
  final double confidence;
  final Map<String, dynamic> parameters;
  final bool needsClarification;
  final String? clarificationQuestion;
  final String urgency;
  final String category;
  final Map<String, dynamic> metadata;
  
  // Câmpuri pentru acces mai ușor la datele Gemini
  String get timeInfo => parameters['time_info'] as String? ?? '';
  String get rideCategory => parameters['category'] as String? ?? '';
  
  RideIntent({
    required this.type,
    required this.destination,
    required this.pickupLocation,
    required this.confidence,
    this.parameters = const {},
    this.needsClarification = false,
    this.clarificationQuestion,
    this.urgency = 'normal',
    this.category = 'general',
    this.metadata = const {},
  });
  
  /// Convert to map for isolate communication
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'destination': destination,
      'pickupLocation': pickupLocation,
      'confidence': confidence,
      'parameters': parameters,
      'needsClarification': needsClarification,
      'clarificationQuestion': clarificationQuestion,
      'urgency': urgency,
      'category': category,
      'metadata': metadata,
    };
  }
  
  /// Create from map for isolate communication
  factory RideIntent.fromMap(Map<String, dynamic> map) {
    return RideIntent(
      type: RideIntentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RideIntentType.unknown,
      ),
      destination: map['destination'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
      needsClarification: map['needsClarification'] ?? false,
      clarificationQuestion: map['clarificationQuestion'],
      urgency: map['urgency'] ?? 'normal',
      category: map['category'] ?? 'general',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}