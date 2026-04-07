/// Filtru de conținut client-side pentru limba română.
/// Blochează cuvinte injurioase, obscenități și expresii jignitoare.
///
/// Utilizare:
///   final result = ContentFilter.check(text);
///   if (!result.isClean) showError(result.message);
///   final safe = ContentFilter.censor(text); // varianta cenzurată cu ***
library;

class ContentFilterResult {
  final bool isClean;
  final String? message;
  const ContentFilterResult.clean() : isClean = true, message = null;
  const ContentFilterResult.violation(this.message) : isClean = false;
}

class ContentFilter {
  ContentFilter._();

  // ── Blacklist română ──────────────────────────────────────────────────────
  // Lista include variante cu/fără diacritice și forme derivate comune.
  static const List<String> _blacklist = [
    // Obscenități de bază
    'pula', 'pule', 'pulă', 'pulii', 'puletă',
    'cacat', 'căcat', 'cacatele', 'cacare',
    'muie', 'muiță', 'muist', 'muistule',
    'futut', 'fute', 'futu-i', 'fututi', 'futui',
    'futu-ti', 'fututi', 'fututil',
    'pizdă', 'pizda', 'pizde', 'pizdar',
    'cur', 'curu', 'curule', 'curva', 'curvă',
    'curvar', 'curvari', 'curvărie',
    'pizdeț', 'pizdet',
    'nenorocit', 'nenorocita', 'nenorocită',
    'coaie', 'coaiele',
    'dracu', 'dracului',
    'pulă', 'pizdă',
    'sugi', 'suge',
    'labă', 'laba', 'labele',
    'caca', 'căca',
    'rahat', 'rahate',
    // Insulte etnice/rasiale (rămân nespecificate în detaliu dar blocate)
    'țigan', 'tigan', 'tiganca', 'tigane', 'tigani',
    'cioroi', 'ciori',
    // Jigniri grave
    'idiot', 'idiota', 'idioata', 'idiote',
    'imbecil', 'imbecila', 'imbecilă',
    'handicap', 'handicapat', 'handicapata',
    'retardat', 'retardata', 'retardată',
    'cretin', 'cretina', 'cretină', 'cretinule',
    'prost', 'proasta', 'proastă','prostule',
    'tâmpit', 'tampit', 'tampita', 'tâmpită',
    'nătâng', 'natang',
    'jigodie', 'jigodii',
    'ordinar', 'ordinara', 'ordinară',
    'las', 'laș', 'lase', 'lași',
    'fraier', 'fraiera', 'fraiere',
    'fraierit', 'fraierită',
    'escroc', 'escroci',
    'milog', 'milogi',
    'vagabond', 'vagabonzi',
    'bend', 'bende',
    'infractor', 'infractori',
    // Amenințări
    'te omor', 'te ucid', 'vă bat', 'te bat',
    'te distrug', 'te dau afară',
    // Cuvinte vulgare englezești des folosite (ROM)
    'fuck', 'fucker', 'fucking', 'shit', 'bitch',
    'asshole', 'bastard', 'dick', 'cunt', 'whore',
  ];

  // ── Normalizare ───────────────────────────────────────────────────────────
  /// Normalizează textul: lowercase + elimină diacritice + elimină spații duble.
  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ă', 'a').replaceAll('â', 'a').replaceAll('î', 'i')
        .replaceAll('ș', 's').replaceAll('ş', 's')
        .replaceAll('ț', 't').replaceAll('ţ', 't')
        // Variante cu cifre în loc de litere (leetspeak)
        .replaceAll('4', 'a').replaceAll('3', 'e').replaceAll('0', 'o')
        .replaceAll('1', 'i').replaceAll('@', 'a')
        // Elimină caractere speciale repetate (ex: p.u.l.a)
        .replaceAll(RegExp(r'[.\-_*!?]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ── API public ────────────────────────────────────────────────────────────

  /// Verifică dacă textul conține conținut interzis.
  /// Returnează [ContentFilterResult.clean] sau [ContentFilterResult.violation].
  static ContentFilterResult check(String text) {
    if (text.trim().isEmpty) return const ContentFilterResult.clean();

    final normalized = _normalize(text);

    for (final word in _blacklist) {
      // Normalizăm și cuvântul din blacklist pentru comparație corectă
      final normalizedWord = _normalize(word);
      // Căutăm ca substring (pentru a prinde și forme morfologice)
      if (normalized.contains(normalizedWord)) {
        return const ContentFilterResult.violation(
          '🚫 Mesajul conține conținut inadecvat și nu poate fi trimis.',
        );
      }
    }
    return const ContentFilterResult.clean();
  }

  /// Cenzurează textul înlocuind cuvintele interzise cu ***.
  /// Util pentru afișarea conținutului deja existent în bază de date.
  static String censor(String text) {
    if (text.trim().isEmpty) return text;
    String result = text;
    for (final word in _blacklist) {
      final pattern = RegExp(
        _normalize(word).split('').join(r'[.\-_*!\s]*'),
        caseSensitive: false,
        unicode: true,
      );
      result = result.replaceAll(pattern, '***');
    }
    return result;
  }

  /// Mesajul de disclaimer afișat utilizatorilor.
  static const String disclaimerText =
      'Prin utilizarea acestei funcții, ești de acord să comunici respectuos. '
      'Injuriile, obscenितățile sau conținutul ofensator duc la suspendarea contului.';

  static const String disclaimerShort =
      '⚠️ Comunicare respectuoasă • Conținut ofensiv → cont suspendat';
}
