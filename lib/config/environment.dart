import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nabour_app/utils/logger.dart';

/// Toate cheile API se citesc din fișierul `.env` la runtime.
/// Copiază `.env.example` → `.env` și completează cu cheile tale.
class Environment {

  static String _get(String key, {String fallback = ''}) {
    try {
      return dotenv.get(key, fallback: fallback);
    } catch (_) {
      return fallback;
    }
  }

  // ── AI Providers ────────────────────────────────────────────
  static String get geminiApiKey    => _get('GEMINI_API_KEY');
  static String get cerebrasApiKey  => _get('CEREBRAS_API_KEY');
  static String get grokApiKey      => _get('GROK_API_KEY');
  static String get openaiApiKey    => _get('OPENAI_API_KEY');

  // ── Mapbox ───────────────────────────────────────────────────
  static String get mapboxPublicToken => _get('MAPBOX_ACCESS_TOKEN');
  static String get mapboxSecretToken => _get('MAPBOX_SECRET_TOKEN');

  // ── Firebase ─────────────────────────────────────────────────
  static String get firebaseApiKey   => _get('FIREBASE_API_KEY');
  static String get firebaseProjectId => _get('FIREBASE_PROJECT_ID',
      fallback: 'nabour-4b4e4');

  // ── Sentry (opțional) ────────────────────────────────────────
  static String get sentryDsn => _get('SENTRY_DSN');

  // ── Feature flags ────────────────────────────────────────────
  static bool get useGeminiTranslationFallback =>
      _get('USE_GEMINI_TRANSLATION_FALLBACK') == 'true';
  static bool get useGeminiForAdvancedIntents =>
      _get('USE_GEMINI_FOR_ADVANCED_INTENTS') == 'true';
  static bool get enableLocalDictionaryTranslation =>
      _get('ENABLE_LOCAL_DICTIONARY_TRANSLATION', fallback: 'true') == 'true';

  /// Dacă true (implicit), intent NLP folosește `nabourGeminiProxy` pe Cloud Functions, nu cheia din app.
  static bool get preferServerGemini =>
      _get('PREFER_SERVER_GEMINI', fallback: 'true') == 'true';

  // ── Social (temporar) ───────────────────────────────────────
  /// Folosit când nu facem încă login cu Facebook (evită erori de tip
  /// "Invalid application ID"). Setează în `.env` URL-ul paginii aplicației.
  static String get facebookPageUrl =>
      _get('FACEBOOK_PAGE_URL');

  /// URL pagină Instagram (ex: https://www.instagram.com/profi.ro/).
  /// Dacă nu există încă, rămâne gol și butoanele se dezactivează.
  static String get instagramPageUrl =>
      _get('INSTAGRAM_PAGE_URL');

  /// URL pagină TikTok (ex: https://www.tiktok.com/@nume/).
  /// Dacă nu există încă, rămâne gol și butoanele se dezactivează.
  static String get tiktokPageUrl =>
      _get('TIKTOK_PAGE_URL');

  // ── Environment detection ────────────────────────────────────
  static bool get isDevelopment =>
      const bool.fromEnvironment('dart.vm.product') == false;
  static bool get isProduction =>
      const bool.fromEnvironment('dart.vm.product') == true;

  // ── Validation ───────────────────────────────────────────────
  static void validateTokens() {
    if (mapboxPublicToken.isEmpty ||
        !mapboxPublicToken.startsWith('pk.eyJ1')) {
      Logger.warning('Mapbox token lipsă sau invalid — harta nu va funcționa.');
    } else {
      Logger.info('Mapbox: OK');
    }

    if (geminiApiKey.isEmpty) {
      Logger.warning('GEMINI_API_KEY lipsă — AI va folosi Cerebras/Groq.');
    }
    if (cerebrasApiKey.isEmpty) {
      Logger.warning('CEREBRAS_API_KEY lipsă — AI poate fi lent.');
    }
    if (grokApiKey.isEmpty) {
      Logger.warning('GROK_API_KEY lipsă — fallback AI indisponibil.');
    }
  }

  static void printConfigurationStatus() {
    if (!isDevelopment) return;
    Logger.debug('=== Nabour Environment ===');
    Logger.debug('Mapbox:   ${mapboxPublicToken.isNotEmpty ? "✅" : "❌ lipsă"}');
    Logger.debug('Gemini:   ${geminiApiKey.isNotEmpty ? "✅" : "❌ lipsă"}');
    Logger.debug('Cerebras: ${cerebrasApiKey.isNotEmpty ? "✅" : "❌ lipsă"}');
    Logger.debug('Groq:     ${grokApiKey.isNotEmpty ? "✅" : "❌ lipsă"}');
    Logger.debug('Firebase: $firebaseProjectId');
    Logger.debug('==========================');
  }

  static bool get isFullyConfigured {
    return mapboxPublicToken.isNotEmpty &&
        mapboxPublicToken.startsWith('pk.eyJ1');
  }
}
