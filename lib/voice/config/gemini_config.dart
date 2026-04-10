// Configurare pentru motorul de limbaj opțional (API Google Generative Language) — folosit de asistentul vocal Nabour când cheia e setată.
// Caracteristici: chei API, medii, validare, fallback la procesare locală când lipsește cheia.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nabour_app/config/environment.dart';

class GeminiConfig {
  // 🎯 API Configuration
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // 🔑 API Keys - Folosește Environment pentru securitate
  static String get _developmentApiKey => Environment.geminiApiKey;
  static String get _productionApiKey => Environment.geminiApiKey;
  
  // 🌍 Environment detection — auto-detectat din dart.vm.product
  static bool get _isProduction =>
      const bool.fromEnvironment('dart.vm.product');
  
  /// 🔑 Obține API key-ul pentru mediul curent
  /// Ordine: 1) .env (GEMINI_API_KEY), 2) --dart-define, 3) Environment
  static String get apiKey {
    // 1) .env (runtime) – folosit la flutter run când .env e încărcat
    if (dotenv.isInitialized) {
      final fromDotenv = dotenv.maybeGet('GEMINI_API_KEY');
      if (fromDotenv != null && fromDotenv.isNotEmpty) {
        return fromDotenv;
      }
    }
    // 2) dart-define (compile-time)
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    // 3) Fallback la configurația statică
    if (_isProduction) {
      return _productionApiKey;
    } else {
      return _developmentApiKey;
    }
  }
  
  /// 🌐 Obține URL-ul de bază
  static String get baseUrl => _baseUrl;
  
  /// 🎯 Obține URL-ul complet cu API key
  static String get fullUrl => '$_baseUrl?key=$apiKey';
  
  /// ✅ Verifică dacă configurația e validă
  static bool get isValid {
    final key = apiKey;
    return key.isNotEmpty && 
           !key.contains('PLACEHOLDER') &&
           !key.contains('YOUR_DEVELOPMENT_GEMINI_API_KEY') && 
           !key.contains('YOUR_PRODUCTION_GEMINI_API_KEY');
  }
  
  /// 🚨 Obține mesajul de eroare pentru configurația invalidă
  static String get configurationErrorMessage {
    if (!isValid) {
      return '''
🧠 [GEMINI_CONFIG] ❌ Configurația Gemini este invalidă!

Pentru a funcționa, trebuie să:
1. Obții un API key de la Google AI Studio
2. Configurezi cheia în fișierul de configurare
3. Sau setezi variabila de mediu GEMINI_API_KEY

Link: https://makersuite.google.com/app/apikey
''';
    }
    return '';
  }
  
  /// 🔧 Configurații pentru generare
  static Map<String, dynamic> get generationConfig => {
    'temperature': 0.1,        // 🎯 Răspunsuri consistente
    'topK': 1,                 // 🎯 Cel mai bun răspuns
    'topP': 0.8,               // 🎯 Diversitate controlată
    'maxOutputTokens': 1024,   // 🎯 Lungimea maximă
    'candidateCount': 1,       // 🎯 Un singur răspuns
  };
  
  /// 🎯 Configurații pentru prompt-uri
  static Map<String, dynamic> get promptConfig => {
    'maxTokens': 500,          // 🎯 Lungimea maximă a prompt-ului
    'systemPrompt': '''
Ești asistentul vocal integrat în aplicația Nabour: conversație clară, naturală, orientată spre curse și adrese.

INSTRUCȚIUNI:
1. Analizează input-ul utilizatorului în contextul Nabour
2. Identifică intenția exactă
3. Răspunde concis și natural, potrivit pentru citire vocală
4. Respectă istoricul și destinația/preluarea din context
5. Returnează JSON valid cu toate câmpurile necesare

FORMATUL RĂSPUNSULUI:
- JSON valid, fără markdown
- Câmpuri clare și concise
- Tipul răspunsului specificat
- Nivelul de încredere (0.0 - 1.0)
''',
  };
  
  /// 🚨 Configurații pentru error handling
  static Map<String, dynamic> get errorConfig => {
    'maxRetries': 3,           // 🎯 Numărul maxim de reîncercări
    'retryDelay': 1000,        // 🎯 Pauza între reîncercări (ms)
    'timeout': 30000,          // 🎯 Timeout pentru API calls (ms)
  };
  
  /// 🔍 Configurații pentru debugging
  static Map<String, dynamic> get debugConfig => {
    'enableLogging': true,     // 🎯 Activează logging-ul
    'logLevel': 'info',        // 🎯 Nivelul de logging
    'enableMetrics': true,     // 🎯 Activează metricile
    'enableProfiling': false,  // 🎯 Activează profiling-ul
  };
  
  /// 📊 Configurații pentru performance
  static Map<String, dynamic> get performanceConfig => {
    'enableCaching': true,     // 🎯 Activează cache-ul
    'cacheSize': 100,          // 🎯 Dimensiunea cache-ului
    'cacheTTL': 300,           // 🎯 Time-to-live cache (secunde)
    'enableCompression': true, // 🎯 Activează compresia
  };
  
  /// 🧹 Cleanup și reset
  static void reset() {
    // 🎯 Aici se pot reseta configurările dacă e necesar
    // Logger.debug('Configuration reset', tag: 'GEMINI_CONFIG');
  }
}
