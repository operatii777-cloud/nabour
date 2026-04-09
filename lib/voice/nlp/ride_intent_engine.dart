import 'dart:convert';
import 'package:nabour_app/config/environment.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/voice/ai/gemini_voice_engine.dart';
import 'ride_intent_models.dart';

/// 🧠 RideIntentEngine - Procesează local intențiile utilizatorului din text
class RideIntentEngine {
  static final RideIntentEngine _instance = RideIntentEngine._internal();
  factory RideIntentEngine() => _instance;
  RideIntentEngine._internal();

  /// 🖋️ Normalizarea textului (consistență cu restul sistemului)
  String _normalize(String text) {
    if (text.isEmpty) return '';
    
    // 1. Lowercase
    String normalized = text.toLowerCase();
    
    // 2. Elimină diacriticele
    normalized = normalized
      .replaceAll('ă', 'a')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ș', 's')
      .replaceAll('ț', 't')
      .replaceAll('ş', 's')
      .replaceAll('ţ', 't');
      
    // 3. Elimină punctuația comună
    normalized = normalized.replaceAll(RegExp(r'[.,!?]'), '');
    
    // 4. Reduce spațiile multiple și trim
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return normalized;
  }

  /// 🚀 Punctul de intrare principal
  Future<RideIntent> process(String userInput) async {
    final raw = userInput;
    final normalized = _normalize(userInput);
    
    Logger.debug('Processing Intent: "$raw" (normalized: "$normalized")', tag: 'RIDE_INTENT_ENGINE');

    // 1. Încearcă procesarea locală
    final localIntent = _processLocally(raw, normalized);
    
    // Dacă am găsit o intenție clară local, o returnăm
    if (localIntent.type != RideIntentType.unknown && localIntent.confidence > 0.7) {
      Logger.info('Local intent detected: ${localIntent.type} (conf: ${localIntent.confidence})', tag: 'RIDE_INTENT_ENGINE');
      return localIntent;
    }

    // 2. Fallback la Gemini dacă este configurat
    if (Environment.useGeminiForAdvancedIntents) {
      Logger.info('Local intent uncertain (type: ${localIntent.type}), falling back to Gemini', tag: 'RIDE_INTENT_ENGINE');
      
      // 📝 Logăm fraza care ajunge la fallback (anonimizat: păstrăm doar structura/keywords dacă e cazul, dar aici logăm tot textul pentru analiză)
      Logger.warning('FALLBACK_PHRASE: "$raw"', tag: 'RIDE_INTENT_ENGINE');
      
      return await _processWithGemini(raw, normalized);
    }

    // 3. Returnăm rezultatul local (chiar dacă e unknown)
    return localIntent;
  }

  /// 📖 Dicționar extensibil de reguli locale
  final Map<RideIntentType, Map<String, List<String>>> _intentDictionary = {
    RideIntentType.rideRequest: {
      'keywords': ['vreau', 'cursa', 'merg', 'du ma', 'ia ma', 'taxi', 'către', 'catre', 'plec', 'comand', 'solicit', 'nevoie', 'ride', 'want', 'go to', 'take me', 'get me'],
      'templates': [
        'vreau o cursa la {location}',
        'du ma la {location}',
        'merg la {location}',
        'ia ma de la {pickup} si du ma la {location}',
        'i want a ride to {location}',
        'take me to {location}'
      ]
    },
    RideIntentType.changeDestination: {
      'keywords': ['schimba', 'schimb', 'alta', 'alt', 'destinatie', 'merg la', 'change', 'different', 'destination', 'instead'],
      'templates': [
        'schimba destinatia la {location}',
        'vreau la {location} in loc',
        'change destination to {location}'
      ]
    },
    RideIntentType.cancelRide: {
      'keywords': ['anuleaza', 'opreste', 'stop', 'nu mai vreau', 'renunt', 'cancel', 'inchide', 'abort'],
      'templates': ['anuleaza cursa', 'nu mai vreau sa merg', 'cancel the ride']
    },
    RideIntentType.confirm: {
      'keywords': ['da', 'ok', 'okay', 'bine', 'perfect', 'sigur', 'confirm', 'corect', 'da sigur', 'da te rog', 'da bine', 'yes', 'fine', 'sure', 'right'],
      'templates': []
    },
    RideIntentType.reject: {
      'keywords': ['nu', 'nu vreau', 'refuz', 'nu mersi', 'nici o sansa', 'ba nu', 'gresit', 'no', 'dont want', 'wrong', 'no thanks'],
      'templates': []
    },
    RideIntentType.greeting: {
      'keywords': ['salut', 'buna', 'hello', 'hey', 'buna ziua', 'buna seara', 'noroc', 'hi', 'good morning', 'good evening'],
      'templates': []
    },
    RideIntentType.statusQuestion: {
      'keywords': ['unde', 'cand', 'cat', 'stare', 'sofer', 'ajunge', 'mai dureaza', 'distanta', 'where', 'when', 'how long', 'driver', 'status'],
      'templates': ['unde e soferul', 'cat mai dureaza', 'where is the driver']
    },
    RideIntentType.addStop: {
      'keywords': ['oprire', 'adauga', 'trecem', 'oprim', 'stop', 'add', 'waypoint'],
      'templates': ['adauga o oprire la {location}', 'oprim si la {location}', 'add a stop at {location}']
    },
    RideIntentType.paymentQuestion: {
      'keywords': ['plata', 'platesc', 'cash', 'card', 'bani', 'achit', 'pret', 'costa', 'pay', 'payment', 'money', 'fare', 'cost', 'price'],
      'templates': ['cum platesc', 'cat costa cursa', 'how do i pay']
    },
    RideIntentType.helpQuestion: {
      'keywords': [
        'ajutor', 'help', 'ce poti sa faci', 'ce poti face', 'cum functionezi',
        'cum lucrezi', 'how do you work', 'what can you do', 'how can you help'
      ],
      'templates': [
        'ce poti sa faci',
        'cum functionezi',
        'how do you work',
        'what can you do'
      ]
    },
    RideIntentType.appInfo: {
      'keywords': [
        'nabour', 'aplicatia', 'aplicația', 'cine te a facut', 'cine te-a facut',
        'cine v a creat', 'cine v-a creat', 'what is nabour', 'who created you'
      ],
      'templates': [
        'ce este nabour',
        'what is nabour',
        'who created you'
      ]
    },
    RideIntentType.smallTalk: {
      'keywords': [
        'multumesc', 'mersi', 'super', 'cool', 'genial', 'tare', 'fain', 'bun',
        'ce faci', 'ce mai faci', 'cum esti', 'cum merge', 'pai', 'aha', 'exact',
        'clar', 'foarte bine', 'as vrea', 'te rog', 'va rog', 'thanks', 'thank you',
        'great', 'nice', 'good', 'awesome', 'anytime', 'sure thing', 'no problem',
        'how are you', 'whats up', 'alright', 'ok then', 'got it', 'understood',
        'perfect', 'minunat', 'bravo', 'felicitari', 'congrats', 'wow', 'interesant'
      ],
      'templates': []
    }
  };

  /// Evită false positive: `contains('no')` se potrivea în **„nord”**, `contains('nu')` în cuvinte rare, etc.
  bool _keywordMatches(String normalized, String keyword) {
    final k = keyword.trim();
    if (k.isEmpty) return false;
    if (k.contains(' ')) {
      final escaped =
          k.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).map(RegExp.escape).join(r'\s+');
      return RegExp('\\b$escaped\\b').hasMatch(normalized);
    }
    if (k.length <= 3) {
      return RegExp('\\b${RegExp.escape(k)}\\b').hasMatch(normalized);
    }
    return normalized.contains(k);
  }

  /// Locuri frecvente fără „str.” / „șoseaua” în față (totuși destinații valide pentru cursă).
  bool _looksLikeLikelyPoiPhrase(String normalized) {
    if (normalized.length < 4) return false;
    return RegExp(
      r'\b(gara|autogara|aeroport|terminal|mall|hypermarket|spital|clinica|piata|parc|campus|stadion|muzeu|biserica|sala palatului|centru comercial|universitate|facultate)\b',
    ).hasMatch(normalized);
  }

  /// 🧠 Logica de procesare locală bazată pe reguli și keywords
  RideIntent _processLocally(String raw, String normalized) {
    final words = normalized.split(' ');
    RideIntentType bestType = RideIntentType.unknown;
    double bestConfidence = 0.0;
    String? destination;
    String? extraStop;

    // 1. Verificăm fiecare intenție din dicționar
    _intentDictionary.forEach((type, rules) {
      double currentConfidence = 0.0;
      final keywords = rules['keywords']!;
      
      // Scor bazat pe keywords
      for (var k in keywords) {
        if (_keywordMatches(normalized, k)) {
          // Keywords mai lungi sau exacte au pondere mai mare
          if (normalized == k || (words.length == 1 && words[0] == k)) {
            currentConfidence += 0.5;
          } else {
            currentConfidence += 0.2;
          }
        }
      }

      // Maximizăm încrederea dacă avem multe match-uri
      currentConfidence = (currentConfidence / 2).clamp(0.0, 0.9);

      if (currentConfidence > bestConfidence) {
        bestConfidence = currentConfidence;
        bestType = type;
      }
    });

    // 2. Extracție specifică pentru Ride Request, Change Destination, Add Stop
    if (bestType == RideIntentType.rideRequest || bestType == RideIntentType.changeDestination ||
        normalized.contains('schimba') || normalized.contains('merg la')) {
      destination = _extractDestination(normalized);
      if (destination != null) {
        bestConfidence += 0.2;
        if (bestType == RideIntentType.unknown) bestType = RideIntentType.rideRequest;
      }
    }
    if (bestType == RideIntentType.addStop) {
      extraStop = _extractDestination(normalized);
      if (extraStop != null) bestConfidence += 0.2;
    }

    // 3. Ajustări specifice pentru confirmări/refuzuri scurte (foarte comune)
    if (words.length <= 2) {
      if (['da', 'ok', 'okay', 'da sigur', 'da te rog'].contains(normalized)) {
        bestType = RideIntentType.confirm;
        bestConfidence = 0.95;
      } else if (['nu', 'nu mersi', 'ba nu'].contains(normalized)) {
        bestType = RideIntentType.reject;
        bestConfidence = 0.95;
      }
    }

    // 3b. Adresă / loc spus direct, fără „vreau cursă la…” (ex. „Șoseaua Vergului 22”, „Gara de Nord”)
    // Evită clasificarea greșită ca smallTalk doar pentru că fraza are puține cuvinte.
    if (bestType == RideIntentType.unknown &&
        (_looksLikeFreeformAddress(normalized) || _looksLikeLikelyPoiPhrase(normalized))) {
      bestType = RideIntentType.rideRequest;
      bestConfidence = 0.88;
      destination = raw.trim();
    }

    // 4. Conversație fluidă: orice frază scurtă nerecunoscută → smallTalk (răspundem mereu, redirecționăm la cursă)
    final rideKeywords = [
      'cursa', 'merg', 'taxi', 'ride', 'destinatie', 'destination', 'adresa', 'address',
      'soseaua', 'strada', 'bulevard', 'calea ', 'aleea ', 'splai', 'piata ', 'drumul ',
      'intrarea', 'fundatura', 'blocul ', 'scara ', 'sectorul ', 'cartierul ',
    ];
    final looksLikeRide = rideKeywords.any((k) => normalized.contains(k)) ||
        _looksLikeLikelyPoiPhrase(normalized);
    if (bestType == RideIntentType.unknown && normalized.isNotEmpty && !looksLikeRide) {
      if (words.length <= 6) {
        bestType = RideIntentType.smallTalk;
        bestConfidence = bestConfidence < 0.5 ? 0.65 : bestConfidence;
      }
    }

    return RideIntent(
      type: bestType,
      rawText: raw,
      normalizedText: normalized,
      destinationText: destination,
      extraStopText: extraStop,
      confidence: bestConfidence.clamp(0.0, 1.0),
      requiresConfirmation: bestType == RideIntentType.rideRequest || bestType == RideIntentType.changeDestination,
    );
  }

  /// Rute precum „Șoseaua X 22”, „Str. Y”, „Bd. Z”, „nr. 10” (text deja normalizat fără diacritice).
  bool _looksLikeFreeformAddress(String normalized) {
    if (normalized.length < 6) return false;

    const hints = [
      'soseaua ',
      'soseaua.',
      'sos ',
      'sos.',
      'strada ',
      'strada.',
      'str ',
      'str.',
      'bulevard',
      'calea ',
      'calea.',
      'aleea ',
      'aleea.',
      'alee ',
      'splai',
      'piata ',
      'piata.',
      'drumul ',
      'intrarea ',
      'fundatura',
      'complexul ',
      'cartierul ',
      'sectorul ',
      'sector ',
      'blocul ',
      'bl ',
      'bl.',
      'scara ',
      'sc.',
    ];
    for (final h in hints) {
      if (normalized.contains(h)) return true;
    }
    if (RegExp(r'\b(nr|numar|numarul)\b').hasMatch(normalized) &&
        normalized.length >= 10) {
      return true;
    }
    return false;
  }

  /// 🗺️ Extrage destinația din text
  String? _extractDestination(String normalized) {
    final markers = [' la ', ' catre ', ' spre ', ' pana la ', ' to ', ' towards '];
    int bestStart = -1;
    String markerUsed = '';

    for (var marker in markers) {
      final int idx = normalized.indexOf(marker);
      if (idx != -1 && (bestStart == -1 || idx < bestStart)) {
        bestStart = idx;
        markerUsed = marker;
      }
    }

    // Cazul în care începe cu marker (ex: "La aeroport")
    if (bestStart == -1) {
       for (var marker in markers) {
         final trimmedMarker = marker.trim();
         if (normalized.startsWith('$trimmedMarker ')) {
           bestStart = 0;
           markerUsed = '$trimmedMarker ';
           break;
         }
       }
    }

    if (bestStart == -1) return null;

    var dest = normalized.substring(bestStart + markerUsed.length).trim();
    
    // Curățăm cuvinte suplimentare la final
    final noise = ['te rog', 'va rog', 'acum', 'imediat', 'multumesc', 'mersi', 'urgent'];
    for (var n in noise) {
      if (dest.endsWith(' $n')) {
        dest = dest.substring(0, dest.length - n.length - 1).trim();
      }
    }

    return dest.isEmpty ? null : dest;
  }

  /// 🤖 Fallback la Gemini pentru clasificarea intenției
  Future<RideIntent> _processWithGemini(String raw, String normalized) async {
    try {
      final gemini = GeminiVoiceEngine();
      
      final prompt = '''
Clasifică următoarea comandă vocală pentru o aplicație de ride-sharing.
Input utilizator: "$raw"

Returnează un obiect JSON VALID cu:
- "intent": "ride_request", "change_destination", "add_stop", "cancel_ride", "confirm", "reject", "status", "smalltalk", "unknown"
- "destination": destinația extrasă (dacă există)
- "confidence": scor 0.0-1.0

Exemplu răspuns: {"intent": "ride_request", "destination": "Aeroport", "confidence": 0.95}
''';

      final result = await gemini.generateRawText(prompt);
      if (result.isEmpty) {
        return RideIntent(type: RideIntentType.unknown, rawText: raw, normalizedText: normalized, handledLocally: false);
      }

      try {
        final jsonStr = result.contains('{') && result.contains('}')
            ? result.substring(result.indexOf('{'), result.lastIndexOf('}') + 1)
            : '{}';
        final Map<String, dynamic> data = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        final intentStr = data['intent'] as String?;
        RideIntentType type = RideIntentType.unknown;
        
        if (intentStr != null) {
          switch (intentStr) {
            case 'ride_request': type = RideIntentType.rideRequest; break;
            case 'change_destination': type = RideIntentType.changeDestination; break;
            case 'add_stop': type = RideIntentType.addStop; break;
            case 'cancel_ride': type = RideIntentType.cancelRide; break;
            case 'confirm': type = RideIntentType.confirm; break;
            case 'reject': type = RideIntentType.reject; break;
            case 'status': type = RideIntentType.statusQuestion; break;
            case 'smalltalk': type = RideIntentType.smallTalk; break;
          }
        }

        return RideIntent(
          type: type,
          rawText: raw,
          normalizedText: normalized,
          destinationText: data['destination'] as String?,
          confidence: (data['confidence'] ?? 0.5).toDouble(),
          handledLocally: false,
        );
      } catch (e) {
        Logger.error('Failed to parse Gemini intent JSON: $e', tag: 'RIDE_INTENT_ENGINE');
      }
      
      return RideIntent(
        type: RideIntentType.unknown,
        rawText: raw,
        normalizedText: normalized,
        handledLocally: false,
      );
    } catch (e) {
      Logger.error('Gemini intent fallback error: $e', tag: 'RIDE_INTENT_ENGINE');
      return RideIntent(type: RideIntentType.unknown, rawText: raw, normalizedText: normalized);
    }
  }
}
