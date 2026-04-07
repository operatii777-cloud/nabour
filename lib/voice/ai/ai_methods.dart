// lib/voice/ai/ai_methods.dart
// Metode lipsă pentru compatibilitatea AIVocabulary

class AIMethods {
  /// Obține tipul comenzii din input
  static String getCommandType(String input) {
    final lowerInput = input.toLowerCase();
    
    if (lowerInput.contains('vreau să merg') || lowerInput.contains('du-mă la') || lowerInput.contains('cursă')) {
      return 'booking';
    } else if (lowerInput.contains('cât costă') || lowerInput.contains('preț')) {
      return 'pricing';
    } else if (lowerInput.contains('șoferi') || lowerInput.contains('disponibil')) {
      return 'driver_search';
    } else if (lowerInput.contains('ajutor') || lowerInput.contains('help')) {
      return 'help';
    } else if (lowerInput.contains('anulează')) {
      return 'cancel';
    }
    return 'unknown';
  }

  /// Obține răspunsul pentru input
  static String getResponse(String input) {
    final commandType = getCommandType(input);
    switch (commandType) {
      case 'booking':
        return 'Înțeleg că vrei o cursă. Unde vrei să mergi?';
      case 'pricing':
        return 'Îți calculez prețul. Unde este destinația?';
      case 'driver_search':
        return 'Caut șoferi disponibili în zona ta.';
      case 'help':
        return 'Te pot ajuta să rezervi o cursă. Spune "vreau să merg la" urmat de destinație.';
      case 'cancel':
        return 'Înțeleg că vrei să anulezi. Confirm anularea?';
      default:
        return 'Nu am înțeles comanda. Poți să repeți?';
    }
  }

  /// Obține sugestii pentru input
  static List<String> getSuggestions(String input) {
    final commandType = getCommandType(input);
    switch (commandType) {
      case 'booking':
        return ['Piața Victoriei', 'Aeroportul Otopeni', 'Mall AFI'];
      case 'pricing':
        return ['Preț până la centru', 'Tarif către aeroport'];
      case 'driver_search':
        return ['Șoferi aproape', 'Timp de așteptare'];
      default:
        return ['Vreau cursă la...', 'Cât costă până la...', 'Ajutor'];
    }
  }

  /// Obține stilul vocal
  static String getVoiceStyle(String commandType) {
    switch (commandType) {
      case 'booking':
        return 'friendly';
      case 'pricing':
        return 'informative';
      case 'emergency':
        return 'urgent';
      case 'help':
        return 'supportive';
      default:
        return 'neutral';
    }
  }

  /// Obține județele disponibile
  static List<String> getAvailableCounties() {
    return ['București', 'Ilfov'];
  }

  /// Obține categoriile disponibile
  static List<String> getAvailableCategories() {
    return ['transport', 'shopping', 'restaurante', 'sport', 'medical', 'educatie'];
  }

  /// Obține destinații populare
  static List<String> getPopularDestinationsInCounty(String county) {
    switch (county.toLowerCase()) {
      case 'bucurești':
        return ['Piața Victoriei', 'Piața Unirii', 'AFI Cotroceni', 'Gara de Nord'];
      case 'ilfov':
        return ['Aeroportul Otopeni', 'Băneasa Shopping City'];
      default:
        return ['Centrul', 'Mall-ul principal'];
    }
  }

  /// Obține locații pe categorie
  static List<Map<String, String>> getLocationsByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'transport':
        return [
          {'name': 'Gara de Nord', 'address': 'Sector 1, București'},
          {'name': 'Aeroportul Otopeni', 'address': 'Otopeni, Ilfov'},
          {'name': 'Metrou Piața Victoriei', 'address': 'Sector 1, București'},
        ];
      case 'shopping':
        return [
          {'name': 'AFI Palace Cotroceni', 'address': 'Bulevardul Vasile Milea 4'},
          {'name': 'Plaza România', 'address': 'Calea Vitan 55-59'},
          {'name': 'Băneasa Shopping City', 'address': 'Șoseaua Bucureștii Noi 42D'},
        ];
      case 'medical':
        return [
          {'name': 'Spitalul Floreasca', 'address': 'Calea Floreasca 8'},
          {'name': 'Spitalul Fundeni', 'address': 'Șoseaua Fundeni 258'},
        ];
      default:
        return [
          {'name': 'Locație Test', 'address': 'Adresă Test'},
        ];
    }
  }

  /// Procesează comanda vocală
  static Map<String, dynamic> processVoiceCommand(String input) {
    final commandType = getCommandType(input);
    final response = getResponse(input);
    final suggestions = getSuggestions(input);
    
    return {
      'command_type': commandType,
      'response': response,
      'suggestions': suggestions,
      'confidence': _calculateConfidence(input),
      'intent': commandType,
      'entities': _extractEntities(input),
    };
  }

  /// Caută toate locațiile
  static List<Map<String, String>> searchAllLocations(String query) {
    final lowercaseQuery = query.toLowerCase();
    final List<Map<String, String>> results = [];
    
    // Search în toate categoriile
    for (final category in getAvailableCategories()) {
      final locations = getLocationsByCategory(category);
      for (final location in locations) {
        if (location['name']!.toLowerCase().contains(lowercaseQuery)) {
          results.add({
            'name': location['name']!,
            'address': location['address']!,
            'category': category,
          });
        }
      }
    }
    
    return results;
  }

  // Helper methods
  static double _calculateConfidence(String input) {
    final commandType = getCommandType(input);
    if (commandType == 'unknown') return 0.3;
    if (input.length < 5) return 0.5;
    return 0.8;
  }

  static Map<String, String> _extractEntities(String input) {
    final entities = <String, String>{};
    final lowerInput = input.toLowerCase();
    
    // Detectează tipul de conversație
    if (lowerInput.contains('bună ziua') || lowerInput.contains('salut')) {
      entities['conversation_type'] = 'greeting';
    } else if (lowerInput.contains('mulțumesc') || lowerInput.contains('mersi')) {
      entities['conversation_type'] = 'thanks';
    } else if (lowerInput.contains('ajutor') || lowerInput.contains('help')) {
      entities['conversation_type'] = 'help_request';
    }
    
    return entities;
  }
}
