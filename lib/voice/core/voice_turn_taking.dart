class VoiceTurnTaking {
  VoiceTurnTaking._();

  static String normalizeForHeuristics(String text) {
    var t = text.toLowerCase().trim();
    const replacements = <String, String>{
      '\u0103': 'a',
      '\u00e2': 'a',
      '\u00ee': 'i',
      '\u0219': 's',
      '\u021b': 't',
      '\u015f': 's',
      '\u0163': 't',
    };
    replacements.forEach((k, v) => t = t.replaceAll(k, v));
    return t.replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool looksGrammaticallyIncomplete(String raw) {
    final s = normalizeForHeuristics(raw);
    if (s.length < 6) return false;

    const tailPhrases = <String>[
      ' la',
      ' spre',
      ' catre',
      ' pana la',
      ' pana ',
      ' de la',
      ' din ',
      ' undeva ',
      ' pe ',
      ' in zona',
      ' in ',
      ' la fel',
      ' vreau sa merg la',
      ' vreau sa ma duci',
      ' as vrea sa merg',
      ' mergem la',
      ' du-ma la',
      ' du ma la',
      ' ia-ma la',
      ' ia ma la',
      ' adica',
      ' deci ',
      ' gen ',
    ];
    for (final tail in tailPhrases) {
      if (s.endsWith(tail)) return true;
    }
    if (s.endsWith(' si') || s.endsWith(' sau')) return true;

    final last = s.split(' ').where((w) => w.isNotEmpty).toList();
    if (last.isEmpty) return false;
    const openFunctionWords = <String>{
      'la',
      'spre',
      'catre',
      'pana',
      'de',
      'din',
      'pe',
      'in',
      'lui',
      'meu',
      'mea',
      'si',
      'sau',
    };
    if (last.length == 1 && openFunctionWords.contains(last.last)) {
      return true;
    }
    return false;
  }
}