import 'dart:ui';
import 'package:nabour_app/config/environment.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/voice/ai/gemini_voice_engine.dart';
import 'package:nabour_app/voice/utils/translation_dictionary.dart';

/// 🧠 Translation Service - Handles local dictionary-based translation RO<->EN
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  /// 🖋️ Normalizes text for better matching
  String _normalize(String text) {
    if (text.isEmpty) return '';
    
    // 1. Lowercase
    String normalized = text.toLowerCase();
    
    // 2. Remove diacritics
    normalized = normalized
      .replaceAll('ă', 'a')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ș', 's')
      .replaceAll('ț', 't')
      .replaceAll('ş', 's') // variants
      .replaceAll('ţ', 't');
      
    // 3. Remove common punctuation
    normalized = normalized.replaceAll(RegExp(r'[.,!?]'), '');
    
    // 4. Reduce multiple spaces to one and trim
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return normalized;
  }

  /// 🗺️ Translates the given text
  Future<String> translate(String text, {Locale? source, Locale? target}) async {
    if (text.isEmpty) return '';
    if (!Environment.enableLocalDictionaryTranslation) {
      return _fallback(text);
    }

    final normalizedText = _normalize(text);
    Logger.debug('Translating: "$text" (normalized: "$normalizedText")', tag: 'TRANSLATION_SERVICE');

    // Detect direction if not specified
    bool toEn = true; // Assume RO to EN by default
    if (source != null && target != null) {
      toEn = source.languageCode == 'ro' && target.languageCode == 'en';
    } else {
      // Simple detection based on common RO words if source not provided
      final isRomanian = _detectIfRomanian(normalizedText);
      toEn = isRomanian;
    }

    final dictionary = toEn ? TranslationDictionary.roToEn : TranslationDictionary.enToRo;

    // 1. Try Exact Match
    for (final entry in dictionary) {
      if (entry['pattern'] == normalizedText) {
        Logger.info('Exact match found for: "$text" -> "${entry['translation']}"', tag: 'TRANSLATION_SERVICE');
        return entry['translation']!;
      }
    }

    // 2. Try Template Match (e.g., "ajung in {n} minute")
    final templateResult = _matchTemplate(normalizedText, dictionary);
    if (templateResult != null) {
      Logger.info('Template match found for: "$text" -> "$templateResult"', tag: 'TRANSLATION_SERVICE');
      return templateResult;
    }

    // 3. Try Fuzzy Match (Optional - let's keep it simple for now as requested)
    
    // 4. Fallback
    return _fallback(text);
  }

  /// 🔍 Simple detection if text is Romanian
  bool _detectIfRomanian(String normalizedText) {
    // List of very common Romanian words
    final roMarkers = ['buna', 'salut', 'unde', 'mergem', 'este', 'sunt', 'mai', 'poti', 'vreau', 'platesc', 'cu', 'in', 'la', 'din'];
    final words = normalizedText.split(' ');
    int roCount = 0;
    for (final word in words) {
      if (roMarkers.contains(word)) roCount++;
    }
    return roCount > 0;
  }

  /// 🧩 Matches templates with variables like {n}
  String? _matchTemplate(String text, List<Map<String, String>> dictionary) {
    for (final entry in dictionary) {
      final pattern = entry['pattern']!;
      if (!pattern.contains('{')) continue;

      // Escape pattern for regex but keep {} as capture groups
      // Example: "ajung in {n} minute" -> "^ajung in (\d+) minute$"
      final String regexPattern = RegExp.escape(pattern)
          .replaceAll(RegExp(r'\\\{n\\\}'), r'(\d+)')
          .replaceAll(RegExp(r'\\\{name\\\}'), r'(\w+)')
          .replaceAll(RegExp(r'\\\{location\\\}'), r'(.+)');
      
      final regex = RegExp('^$regexPattern\$');
      final match = regex.firstMatch(text);
      
      if (match != null) {
        String translation = entry['translation']!;
        // Replace variables in translation
        // Note: Currently assuming one variable for simplicity, can be expanded
        if (match.groupCount >= 1) {
          final value = match.group(1)!;
          translation = translation.replaceAll(RegExp(r'\{n\}|\{name\}|\{location\}'), value);
        }
        return translation;
      }
    }
    return null;
  }

  /// 🆘 Fallback logic
  Future<String> _fallback(String text) async {
    if (Environment.useGeminiTranslationFallback) {
      Logger.info('Using Gemini fallback for translation', tag: 'TRANSLATION_SERVICE');
      
      // Detecție simplă pentru direcție
      final isRomanian = _detectIfRomanian(_normalize(text));
      final sourceLang = isRomanian ? 'Romanian' : 'English';
      final targetLang = isRomanian ? 'English' : 'Romanian';
      
      return await GeminiVoiceEngine().translate(text, sourceLang, targetLang);
    }
    return text;
  }
}
