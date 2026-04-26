import 'package:flutter/foundation.dart';
import 'package:nabour_app/utils/logger.dart';

/// Metadate opționale pentru o acțiune vocală: cuvinte-cheie bilingve + răspunsuri template.
class VoiceActionMeta {
  final List<String> keywordsEN;
  final List<String> keywordsRO;
  final double confidence;
  final String? responseTemplateEN;
  final String? responseTemplateRO;

  const VoiceActionMeta({
    this.keywordsEN = const [],
    this.keywordsRO = const [],
    this.confidence = 0.9,
    this.responseTemplateEN,
    this.responseTemplateRO,
  });
}

/// Rezultatul căutării după cuvinte-cheie.
class VoiceActionMatch {
  final String actionId;
  final double score;

  /// Răspunsul vocal recomandat (în limba detectată), dacă a fost definit la înregistrare.
  final String? responseTemplate;

  const VoiceActionMatch({
    required this.actionId,
    required this.score,
    this.responseTemplate,
  });
}

/// 🤖 Voice UI Automation Registry
///
/// Acționează ca un "DOM" sau "Playwright" pentru asistentul vocal.
/// Permite înregistrarea și execuția dinamică a oricărei funcții din UI.
///
/// Plus față de versiunea inițială:
/// - cuvinte-cheie bilingve (EN + RO) indexate per acțiune
/// - scor de confidence bazat pe lungimea keyword-ului (mai specific = mai bun)
/// - template-uri de răspuns vocal per limbă
/// - [findByKeyword] — fallback NLP când AI-ul nu returnează un ID exact
class VoiceUIAutomationRegistry {
  static final VoiceUIAutomationRegistry _instance =
      VoiceUIAutomationRegistry._internal();
  factory VoiceUIAutomationRegistry() => _instance;
  VoiceUIAutomationRegistry._internal();

  final Map<String, VoidCallback> _callbacks = {};
  final Map<String, Function(Map<String, dynamic>)> _parameterizedCallbacks =
      {};

  // Metadate keyword per action ID
  final Map<String, VoiceActionMeta> _meta = {};
  // Index invers: keyword_lower -> [actionId] (lookup O(1))
  final Map<String, List<String>> _keywordIndex = {};

  // ── API existent (backward-compatible) ───────────────────────────────────

  /// Înregistrează o acțiune simplă (ex: apăsare buton).
  /// [meta] opțional — adaugă cuvinte-cheie pentru căutare vocală.
  void registerAction(
    String id,
    VoidCallback action, {
    VoiceActionMeta? meta,
  }) {
    _callbacks[id] = action;
    if (meta != null) _indexMeta(id, meta);
    Logger.info('Registered voice action: $id', tag: 'UI_AUTOMATION');
  }

  /// Înregistrează o acțiune complexă (ex: introducere text, selectare valoare).
  /// [meta] opțional — adaugă cuvinte-cheie pentru căutare vocală.
  void registerParameterizedAction(
    String id,
    Function(Map<String, dynamic>) action, {
    VoiceActionMeta? meta,
  }) {
    _parameterizedCallbacks[id] = action;
    if (meta != null) _indexMeta(id, meta);
    Logger.info(
        'Registered parameterized voice action: $id', tag: 'UI_AUTOMATION');
  }

  /// Elimină o acțiune la dispose-ul widget-ului.
  void unregisterAction(String id) {
    _callbacks.remove(id);
    _parameterizedCallbacks.remove(id);
    _removeFromIndex(id);
    Logger.debug('Unregistered voice action: $id', tag: 'UI_AUTOMATION');
  }

  /// Execută o acțiune după ID exact.
  bool executeAction(String id, {Map<String, dynamic>? params}) {
    Logger.info('🤖 Voice Automation: Attempting to execute $id',
        tag: 'UI_AUTOMATION');

    if (params != null && _parameterizedCallbacks.containsKey(id)) {
      _parameterizedCallbacks[id]!(params);
      return true;
    }

    if (_callbacks.containsKey(id)) {
      _callbacks[id]!();
      return true;
    }

    Logger.warning('Action ID "$id" not found in Registry',
        tag: 'UI_AUTOMATION');
    return false;
  }

  /// Returnează toate acțiunile disponibile în acest moment (DOM-ul curent).
  List<String> get availableActions => [
        ..._callbacks.keys,
        ..._parameterizedCallbacks.keys,
      ];

  // ── API nou: căutare după cuvinte-cheie ──────────────────────────────────

  /// Caută cea mai bună acțiune din registry pe baza textului vocal.
  ///
  /// Scorul = (lungime keyword / lungime speech) × confidence de bază.
  /// Returnează null dacă nicio acțiune nu atinge [minScore].
  ///
  /// [language] — 'ro' sau 'en', selectează template-ul de răspuns corespunzător.
  VoiceActionMatch? findByKeyword(
    String speech,
    String language, {
    double minScore = 0.35,
  }) {
    final lower = speech.toLowerCase();
    final scores = <String, double>{};

    for (final entry in _keywordIndex.entries) {
      final keyword = entry.key;
      if (!lower.contains(keyword)) continue;
      final score = (keyword.length / lower.length).clamp(0.0, 1.0);
      for (final actionId in entry.value) {
        final baseConf = _meta[actionId]?.confidence ?? 0.9;
        final weighted = score * baseConf;
        if ((scores[actionId] ?? 0) < weighted) {
          scores[actionId] = weighted;
        }
      }
    }

    if (scores.isEmpty) return null;

    final bestId =
        scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final bestScore = scores[bestId]!;
    if (bestScore < minScore) return null;

    final meta = _meta[bestId];
    final template = language == 'ro'
        ? meta?.responseTemplateRO
        : meta?.responseTemplateEN;

    Logger.info(
      'findByKeyword: "$speech" → $bestId (score=${bestScore.toStringAsFixed(2)})',
      tag: 'UI_AUTOMATION',
    );
    return VoiceActionMatch(
      actionId: bestId,
      score: bestScore,
      responseTemplate: template,
    );
  }

  // ── Privat ────────────────────────────────────────────────────────────────

  void _indexMeta(String id, VoiceActionMeta meta) {
    _meta[id] = meta;
    for (final kw in meta.keywordsEN) {
      _keywordIndex.putIfAbsent(kw.toLowerCase(), () => []).add(id);
    }
    for (final kw in meta.keywordsRO) {
      _keywordIndex.putIfAbsent(kw.toLowerCase(), () => []).add(id);
    }
  }

  void _removeFromIndex(String id) {
    _meta.remove(id);
    for (final list in _keywordIndex.values) {
      list.remove(id);
    }
    _keywordIndex.removeWhere((_, list) => list.isEmpty);
  }
}
