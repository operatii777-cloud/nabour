import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geocoding/geocoding.dart' as geocoding; // ✅ FIX: Adăugat pentru locationFromAddress (serviciul nativ)
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show Point, Position;
import 'package:shared_preferences/shared_preferences.dart';
import '../ai/gemini_voice_engine.dart';
import '../ai/ai_provider_router.dart';
import '../tts/natural_voice_synthesizer.dart' as tts;
import '../states/voice_interaction_states.dart';
import '../core/voice_orchestrator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nabour_app/voice/nlp/ride_intent_engine.dart';
import 'package:nabour_app/voice/nlp/ride_intent_models.dart';
import '../../services/firestore_service.dart';
import '../../services/audio_beep_service.dart';
import '../../services/geocoding_service.dart' as geocoding_svc;
import '../../models/ride_model.dart';
import '../../models/saved_address_model.dart';
import '../../screens/searching_for_driver_screen.dart';
import '../../utils/deprecated_apis_fix.dart';
import '../../utils/input_validator.dart';
import '../../services/buc_locations_db.dart';
import '../utils/voice_translations.dart';
import '../../utils/logger.dart';
import '../../screens/help_screen.dart';
import '../../screens/account_screen.dart';
import '../../screens/history_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/driver_dashboard_screen.dart';
import '../../screens/token_shop_screen.dart';

/// ✅ Helper: Obține limba curentă din SharedPreferences
Future<String> _getCurrentLanguageCode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale');
    return code ?? 'ro'; // Default română
  } catch (e) {
    Logger.error('Error getting language: $e', tag: 'RIDE_FLOW', error: e);
    return 'ro'; // Default română
  }
}

/// Gestionarul fluxului de cursă pentru voce: stări, NLP local, LLM opțional, TTS prin orchestrator.
class RideFlowManager {
  final GeminiVoiceEngine _geminiEngine;
  final tts.NaturalVoiceSynthesizer _tts;
  final FirestoreService _firestoreService;
  final VoiceOrchestrator _voiceOrchestrator; // 🎯 NOU - pentru continuarea conversației
  final AudioBeepService _beepService = AudioBeepService(); // 🔔 NOU - pentru beep-uri
  final Stream<Ride> Function(String rideId) _rideStreamOverride;
  
  // 🎯 Starea curentă a cursei
  RideFlowState _currentState = RideFlowState.idle;
  
  // 🚗 Datele cursei
  String? _destination;
  String? _pickup;
  double? _estimatedPrice;
  List<String> _availableDrivers = [];
  String? _pendingDriverId;
  String? _currentRideId; // ✅ NOU: ID-ul cursei curente pentru confirmarea șoferului
  StreamSubscription<Ride>? _rideStatusSubscription;
  Timer? _driverResponseTimeout;
  double? _calculatedDistanceKm;
  double? _calculatedDurationMinutes;
  Map<String, double>? _fareBreakdown;
  RideCategory _currentRideCategory = RideCategory.standard;
  
  // 📍 Coordonate GPS reale
  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _destinationLatitude;
  double? _destinationLongitude;
  
  // 🗣️ Ultimul mesaj rostit pentru UI
  String _lastSpokenMessage = '';
  // String? _selectedDriver; // ❌ Necesar pentru viitoare implementări
  
  // 🎤 Contextul conversației
  final List<String> _conversationHistory = [];
  
  // ✅ NAVIGATION GUARD: Previne navigare duplicată
  bool _isNavigating = false;

  // 🗺️ Sugestii pentru disambiguare adresă
  List<geocoding_svc.AddressSuggestion> _disambiguationSuggestions = [];
  
  // 🎯 Callback-uri abstracte pentru acțiuni în UI - fără cunoștințe despre widget-uri
  // ✅ FIX: Adăugăm coordonatele opționale pentru a folosi coordonatele deja geocodate din UI
  final Function(String pickup, String destination, {double? pickupLat, double? pickupLng, double? destLat, double? destLng}) onFillAddressInUI;
  final Function(RideCategory category) onSelectRideOptionInUI;
  final Function() onPressConfirmButtonInUI;
  final Function(Widget screen) onNavigateToScreen;
  final Function(Map<String, dynamic> rideRequest) onCreateRideRequest;
  final Function(String driverId, bool accepted) onDriverResponse;
  final Function() onCloseAI;
  final Function(String action, String? screen, Map<String, dynamic>? params) onAppAction;
  final Function(String address, double lat, double lng)? onAddStop;
  final Function(int stars, String? comment)? onRateDriver;
  final Function(String message)? onSendMessageToDriver;
  final Function(bool isDark)? onToggleTheme;
  final Function(String languageCode)? onLanguageChange;

  RideFlowManager({
    required GeminiVoiceEngine geminiEngine,
    required tts.NaturalVoiceSynthesizer tts,
    required FirestoreService firestoreService,
    required VoiceOrchestrator voiceOrchestrator,
    required this.onFillAddressInUI,
    required this.onSelectRideOptionInUI,
    required this.onPressConfirmButtonInUI,
    required this.onNavigateToScreen,
    required this.onCreateRideRequest,
    required this.onDriverResponse,
    required this.onCloseAI,
    required this.onAppAction,
    this.onAddStop,
    this.onRateDriver,
    this.onSendMessageToDriver,
    this.onToggleTheme,
    this.onLanguageChange,
    Stream<Ride> Function(String rideId)? rideStreamOverride,
  })  : _geminiEngine = geminiEngine,
        _tts = tts,
        _firestoreService = firestoreService,
        _voiceOrchestrator = voiceOrchestrator,
        _rideStreamOverride = rideStreamOverride ?? firestoreService.getRideStream;
  
  Future<void> _speakThenListen(
    String text, {
    VoiceEmotion emotion = VoiceEmotion.calm,
    int? timeoutSeconds,
    int? pauseForSeconds,
    /// Răspunsuri foarte scurte (da/nu); altfel folosiți implicit dictation pentru adrese și clarificări.
    bool shortConfirmation = false,
  }) async {
    try {
      _lastSpokenMessage = text;
      final languageCode = await _getCurrentLanguageCode();
      final localeId = languageCode == 'en' ? 'en_US' : 'ro_RO';

      if (shortConfirmation) {
        await _voiceOrchestrator.speakThenListenConfirmation(
          text,
          emotion: emotion,
          localeId: localeId,
        );
      } else {
        await _voiceOrchestrator.speakThenListen(
          text,
          emotion: emotion,
          timeoutSeconds: timeoutSeconds,
          pauseForSeconds: pauseForSeconds,
          localeId: localeId,
        );
      }
    } catch (e) {
      Logger.error('Speak then listen error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// Răspuns sigur când LLM-ul depășește timpul — continuă conversația, fără stare moartă.
  Future<GeminiVoiceResponse> _responseForLlmTimeout() async {
    final msg = await VoiceTranslations.getAiTimeoutRetry();
    return GeminiVoiceResponse(
      type: 'needs_clarification',
      message: msg,
      confidence: 0.3,
      needsClarification: true,
      clarificationQuestion: msg,
    );
  }

  /// Geocodarea destinației a eșuat — cere reper/cartier; păstrează pipeline-ul vocal (atomic speak→listen).
  Future<void> _promptDestinationLandmarkAndListen() async {
    _currentState = RideFlowState.awaitingDestinationGeocodeDetail;
    final languageCode = await _getCurrentLanguageCode();
    await _tts.setLanguage(languageCode);
    final message = await VoiceTranslations.getAskDestinationLandmark();
    _lastSpokenMessage = message;
    await _speakThenListen(message, emotion: VoiceEmotion.calm);
  }

  /// Mesajele vocale trec prin orchestrator: barge-in, stări UI, același guard STT/TTS ca la [speakThenListen].
  Future<void> _speakEmotion(String text, VoiceEmotion emotion) =>
      _voiceOrchestrator.speak(text, emotion: emotion);

  /// 🚀 Inițializează managerul
  Future<void> initialize() async {
    try {
      Logger.debug('Initializing...', tag: 'RIDE_FLOW');
      Logger.debug('TTS: ${_tts.toString()}', tag: 'RIDE_FLOW');
      Logger.debug('VoiceOrchestrator: ${_voiceOrchestrator.toString()}', tag: 'RIDE_FLOW');
      
      // ✅ FIX: Obțin limba curentă și o setez în TTS la inițializare
      final languageCode = await _getCurrentLanguageCode();
      await _tts.initialize(languageCode: languageCode);
      await _tts.setLanguage(languageCode); // ✅ FIX: Asigur că limba este setată
      Logger.info('TTS initialized successfully with language: $languageCode', tag: 'RIDE_FLOW');
      
      // 🔔 Inițializez serviciul de beep-uri
      await _beepService.initialize();
      Logger.info('Beep service initialized successfully', tag: 'RIDE_FLOW');
      
      Logger.info('RideFlowManager initialized successfully', tag: 'RIDE_FLOW');
    } catch (e) {
      Logger.error('Initialization error: $e', tag: 'RIDE_FLOW', error: e);
      rethrow;
    }
  }
  
  /// 🎤 Procesează input-ul vocal și gestionează flow-ul
  Future<void> processVoiceInput(String userInput) async {
    try {
      Logger.debug('Processing: "$userInput"', tag: 'RIDE_FLOW');

      // 🗺️ Dacă așteptăm selecția adresei, procesăm direct fără AI
      if (_currentState == RideFlowState.awaitingAddressSelection) {
        await _handleAddressSelection(userInput);
        return;
      }

      // ✅ Confirmare șofer: „da” scurt merge direct (fără rundă LLM), restul prin AI/NLP.
      if (_currentState == RideFlowState.awaitingDriverAcceptance) {
        await _voiceOrchestrator.stopListening();
        final cleanedDriver = _cleanInputFromTTS(userInput);
        Logger.debug('Cleaned input (driver acceptance): "$cleanedDriver"', tag: 'RIDE_FLOW');
        if (cleanedDriver.isEmpty) {
          Logger.debug('Driver acceptance: empty utterance, skip', tag: 'RIDE_FLOW');
          return;
        }
        _addToHistory('User: $cleanedDriver');
        if (_isPositiveConfirmation(cleanedDriver)) {
          await _handleDriverAcceptanceResponse(
            GeminiVoiceResponse(
              type: 'driver_acceptance',
              message: cleanedDriver,
              confidence: 1.0,
              needsClarification: false,
            ),
          );
          return;
        }
      }

      // 🎯 Sincronizare: oprește ascultarea imediat (evită ecou și captare pe timpul răspunsului)
      await _voiceOrchestrator.stopListening();
      
      // 🧹 CURĂȚ INPUT-UL DE CE SPUNE AI-UL (elimină echo-ul TTS-ului)
      String cleanedInput = _cleanInputFromTTS(userInput);
      Logger.debug('Cleaned input: "$cleanedInput"', tag: 'RIDE_FLOW');
      if (cleanedInput.isEmpty) {
        Logger.info('Empty utterance after clean — skip AI round', tag: 'RIDE_FLOW');
        return;
      }
      if (cleanedInput.length > 8000) {
        cleanedInput = '${cleanedInput.substring(0, 7997)}…';
        Logger.warning('Input truncated to 8000 chars for AI', tag: 'RIDE_FLOW');
      }

      // 📝 Adaug la istoric
      _addToHistory('User: $cleanedInput');

      // 🧠 Construiesc contextul pentru Gemini
      final context = VoiceContext(
        destination: _destination,
        pickup: _pickup,
        conversationState: _currentState.toString(),
        conversationHistory: _conversationHistory,
      );

      // 🧠 1. Încearcă procesarea locală de intenții (NLP Local)
      final intentEngine = RideIntentEngine();
      final intent = await intentEngine.process(cleanedInput);

      GeminiVoiceResponse? response;

      if (intent.handledLocally && intent.type != RideIntentType.unknown) {
        Logger.info('Handled by Local RideIntentEngine: ${intent.type}', tag: 'RIDE_FLOW');
        response = await _mapIntentToResponse(intent);
      } else {
        // 🚀 2. Router multi-provider: Cerebras → Gemini → Grok (timeout → reluare conversațională)
        final languageCode = await _getCurrentLanguageCode();
        response = await AIProviderRouter()
            .route(cleanedInput, context, languageCode: languageCode)
            .timeout(
              const Duration(seconds: 45),
              onTimeout: _responseForLlmTimeout,
            );
      }
      
      // 🔔 Beep pentru confirmarea procesării
      _beepService.playProcessingCompleteBeep();
      
      // 📝 Adaug răspunsul la istoric și gestionez flow-ul
      _addToHistory('AI: ${response.message ?? "Răspuns procesat"}');
      await _handleGeminiResponse(response);
      
      Logger.info('Input processed successfully', tag: 'RIDE_FLOW');
      
    } catch (e) {
      Logger.error('Error: $e', tag: 'RIDE_FLOW', error: e);
      await _handleError(e.toString());
    }
  }
  
  /// 🧹 Curăță input-ul de ceea ce spune AI-ul (elimină echo-ul TTS)
  String _cleanInputFromTTS(String userInput) {
    final input = userInput.trim();
    
    // ✅ FIX: Verifică mai întâi dacă input-ul conține o adresă cunoscută din baza de date
    // Dacă da, păstrează-l aproape intact (doar elimină frazele AI-ului de la început)
    final locationCheck = BucharestLocationsDatabase.findLocation(input);
    if (locationCheck != null) {
      Logger.info('Found location in database, preserving address: ${locationCheck['name']}', tag: 'RIDE_FLOW');
      // Dacă e o locație cunoscută, doar elimină frazele AI-ului de la început
      return _removeOnlyAIPhrasesFromStart(input);
    }
    
    // ✅ FIX: Verifică și părți din input (poate adresa e în mijloc, cu fraza AI-ului la început)
    // Ex: "Salut unde doriți să mergeți Aleea Barajul Dunării nr 10"
    // Elimină "Salut unde doriți să mergeți" și verifică dacă rămâne o locație cunoscută
    final tempCleaned = _removeOnlyAIPhrasesFromStart(input);
    if (tempCleaned != input && tempCleaned.length >= 5) {
      final tempLocationCheck = BucharestLocationsDatabase.findLocation(tempCleaned);
      if (tempLocationCheck != null) {
        Logger.info('Found location in database after removing AI phrases: ${tempLocationCheck['name']}', tag: 'RIDE_FLOW');
        return tempCleaned;
      }
    }
    
    // 🎯 Lista de fraze comune pe care le spune AI-ul
    final aiPhrases = [
      'salut, unde doriți să mergeți',
      'salut unde doriți să mergeți',
      'unde doriți să mergeți',
      'am înțeles că doriți să mergeți la',
      'am înțeles ca doriti sa mergeti la',
      'confirmați',
      'confirmati',
      'perfect',
      'excelent',
      'caut șoferi',
      'caut soferi',
    ];
    
    // 🔍 Elimin frazele AI-ului din input (doar dacă sunt la început)
    String cleaned = input;
    for (final phrase in aiPhrases) {
      final lowerCleaned = cleaned.toLowerCase();
      final lowerPhrase = phrase.toLowerCase();
      
      // Verifică dacă fraza AI-ului este la începutul input-ului
      if (lowerCleaned.startsWith(lowerPhrase)) {
        // Elimină doar dacă e la început
        final afterPhrase = cleaned.substring(phrase.length).trim();
        // ✅ FIX: Verifică dacă după eliminarea frazei AI-ului rămâne o adresă validă
        if (afterPhrase.length >= 5) { // Adresă minimă de 5 caractere
          cleaned = afterPhrase;
          Logger.debug('Removed AI phrase from start: "$phrase" → "$cleaned"', tag: 'RIDE_FLOW');
          break; // Oprim după prima potrivire
        } else {
          // Dacă rămâne prea puțin, păstrează originalul
          Logger.warning('Removing "$phrase" would leave too little, keeping original', tag: 'RIDE_FLOW');
          break;
        }
      } else if (lowerCleaned.contains(lowerPhrase)) {
        // ✅ FIX: Verifică dacă input-ul conține cuvinte cheie de adresă SAU e suficient de lung
        // Dacă da, NU elimină frazele AI-ului din mijloc (ar putea fi parte din adresă)
        final addressKeywords = ['aleea', 'alee', 'strada', 'stradă', 'bulevardul', 'bulevard', 'nr', 'număr', 'bloc', 'scara', 
                                 'barajul', 'baraj', 'dunării', 'dunarii', 'sadului', 'sad', 'gara', 'autogara', 'spitalul',
                                 'piata', 'piața', 'mall', 'centru', 'aeroport', 'str.', 'bd.', 'calea', 'sos.', 'soseaua',
                                 'cartier', 'sector', 'judet', 'județ', 'comuna', 'satul', 'sat', 'localitatea', 'localitate'];
        final hasAddressKeywords = addressKeywords.any((keyword) => lowerCleaned.contains(keyword));
        
        // ✅ FIX: Dacă input-ul e suficient de lung (>15 caractere), probabil e o adresă completă
        final isLongEnoughForAddress = cleaned.length > 15;
        
        if (hasAddressKeywords || isLongEnoughForAddress) {
          // Input-ul conține cuvinte de adresă SAU e suficient de lung → probabil e o adresă completă
          // NU elimină frazele AI-ului din mijloc (ar putea distruge adresa)
          Logger.warning('Input contains address keywords or is long enough (${cleaned.length} chars), skipping middle phrase removal to preserve address', tag: 'RIDE_FLOW');
        } else {
          // Dacă fraza e în mijloc și NU conține cuvinte de adresă, o elimin
          final index = lowerCleaned.indexOf(lowerPhrase);
          if (index > 0 && index < cleaned.length - phrase.length) {
            // Verifică dacă după eliminare rămâne o adresă validă (minim 5 caractere)
            final before = cleaned.substring(0, index).trim();
            final after = cleaned.substring(index + phrase.length).trim();
            final combined = '$before $after'.trim();
            
            if (combined.length >= 5) {
              cleaned = combined;
              Logger.debug('Removed AI phrase from middle: "$phrase" → "$cleaned"', tag: 'RIDE_FLOW');
            } else {
              Logger.warning('Removing "$phrase" from middle would leave too little, keeping original', tag: 'RIDE_FLOW');
            }
          }
        }
      }
    }
    
    // 🧹 Elimin cuvinte de început comune (doar dacă nu e o adresă completă)
    final prefixes = ['la ', 'in ', 'spre ', 'către '];
    for (final prefix in prefixes) {
      if (cleaned.toLowerCase().startsWith(prefix)) {
        // Verifică dacă după prefix există o adresă validă (mai mult de 5 caractere)
        final afterPrefix = cleaned.substring(prefix.length).trim();
        if (afterPrefix.length > 5) {
          cleaned = afterPrefix;
          Logger.debug('Removed prefix: "$prefix" → "$cleaned"', tag: 'RIDE_FLOW');
          break;
        }
      }
    }
    
    // ✅ Returnez inputul curățat (dacă e valid) sau originalul
    // Dacă curățarea a eliminat prea mult, păstrez originalul
    if (cleaned.length < 5 && userInput.length > 15) {
      Logger.warning('Cleaning removed too much (${cleaned.length} chars), keeping original (${userInput.length} chars)', tag: 'RIDE_FLOW');
      return userInput;
    }
    
    // ✅ Verifică dacă adresa curățată este o locație cunoscută
    final cleanedLocationCheck = BucharestLocationsDatabase.findLocation(cleaned);
    if (cleanedLocationCheck != null) {
      Logger.info('Cleaned address found in database: ${cleanedLocationCheck['name']}', tag: 'RIDE_FLOW');
      return cleaned;
    }
    
    return cleaned.isNotEmpty && cleaned.length > 2 ? cleaned : userInput;
  }
  
  /// 🧹 Elimină doar frazele AI-ului de la început (pentru adrese cunoscute)
  String _removeOnlyAIPhrasesFromStart(String input) {
    final lowerInput = input.toLowerCase();
    final aiPhrases = [
      'salut, unde doriți să mergeți',
      'salut unde doriți să mergeți',
      'unde doriți să mergeți',
    ];
    
    for (final phrase in aiPhrases) {
      if (lowerInput.startsWith(phrase.toLowerCase())) {
        final after = input.substring(phrase.length).trim();
        if (after.length >= 5) {
          return after;
        }
      }
    }
    
    return input;
  }
  
  /// 🗺️ Mapează un RideIntent la un GeminiVoiceResponse (mesaje scurte, fluente, localizate)
  Future<GeminiVoiceResponse> _mapIntentToResponse(RideIntent intent) async {
    String type = 'unknown';
    String message = '';
    bool needsClarification = false;
    final String? destination = intent.destinationText;

    switch (intent.type) {
      case RideIntentType.rideRequest:
        if (destination != null) {
          type = 'destination';
          message = 'Am înțeles! Doriți să mergeți la $destination. Confirmați?';
        } else {
          type = 'needs_clarification';
          message = await VoiceTranslations.getPleaseSpecifyDestination();
          needsClarification = true;
        }
        break;
      case RideIntentType.cancelRide:
        type = 'cancel_ride';
        message = 'Sigur, am anulat solicitarea cursei.';
        break;
      case RideIntentType.confirm:
        type = 'confirmation';
        message = 'Perfect! Am înțeles.';
        break;
      case RideIntentType.reject:
        type = 'needs_clarification';
        message = await VoiceTranslations.getFluentReject();
        needsClarification = true;
        break;
      case RideIntentType.greeting:
        type = 'needs_clarification';
        message = await VoiceTranslations.getFluentGreeting();
        needsClarification = true;
        break;
      case RideIntentType.smallTalk:
        type = 'needs_clarification';
        message = await VoiceTranslations.getFluentSmallTalk();
        needsClarification = true;
        break;
      case RideIntentType.statusQuestion:
        type = 'needs_clarification';
        message = await VoiceTranslations.getFluentStatus();
        needsClarification = true;
        break;
      case RideIntentType.paymentQuestion:
        type = 'needs_clarification';
        message = await VoiceTranslations.getFluentPayment();
        needsClarification = true;
        break;
      case RideIntentType.changeDestination:
        if (destination != null) {
          type = 'destination_confirmed';
          message = 'Am schimbat destinația la $destination.';
        } else {
          type = 'needs_clarification';
          message = await VoiceTranslations.getPleaseSpecifyDestination();
          needsClarification = true;
        }
        break;
      case RideIntentType.addStop:
        final stop = intent.extraStopText;
        if (stop != null) {
          type = 'add_stop';
          message = 'Am adăugat o oprire la $stop.';
        } else {
          type = 'needs_clarification';
          message = await VoiceTranslations.getPleaseSpecifyDestination();
          needsClarification = true;
        }
        break;
      case RideIntentType.helpQuestion:
        type = 'needs_clarification';
        message = await VoiceTranslations.getFluentHelp();
        needsClarification = true;
        break;
      case RideIntentType.appInfo:
        type = 'needs_clarification';
        message = await VoiceTranslations.getFluentAppInfo();
        needsClarification = true;
        break;
      default:
        type = 'needs_clarification';
        message = await VoiceTranslations.getFluentUnknown();
        needsClarification = true;
    }

    return GeminiVoiceResponse(
      type: type,
      message: message,
      confidence: intent.confidence,
      needsClarification: needsClarification,
      clarificationQuestion: needsClarification ? message : null,
      destination: destination,
    );
  }

  /// 🎯 Gestionează răspunsul de la Gemini și actualizează flow-ul
  Future<void> _handleGeminiResponse(GeminiVoiceResponse response) async {
    try {
      Logger.debug('Handling Gemini response: ${response.type}', tag: 'RIDE_FLOW');
      
      // ✅ NOU: Setează tipul de cursă dacă e cerut de AI
      if (response.rideType != null) {
        final category = _parseRideCategory(response.rideType!);
        _currentRideCategory = category;
        onSelectRideOptionInUI(category);
      }

      switch (response.type) {
        case 'destination':
          await _handleDestinationResponse(response);
          break;
        case 'destination_confirmed':
          await _handleDestinationConfirmedResponse(response);
          break;
        case 'confirmation':
          await _handleConfirmationResponse(response);
          break;
        case 'ride_request':
          await _handleRideRequestResponse(response);
          break;
        case 'driver_selection':
          await _handleDriverSelectionResponse(response);
          break;
        case 'price_confirmation':
          await _handlePriceConfirmationResponse(response);
          break;
        case 'booking_finalization':
          await _handleBookingFinalizationResponse(response);
          break;
        case 'needs_clarification':
          await _handleClarificationRequest(response);
          break;
        case 'offline_guidance':
          await _handleClarificationRequest(response);
          break;
        // 🎯 NOU: Cazuri pentru confirmarea finală și opțiuni
        case 'final_confirmation':
          await _handleFinalRideConfirmation(response);
          break;
        case 'ride_confirmation': 
          await _handleFinalRideConfirmation(response);
          break;
        case 'confirm_ride':
          await _handleRideRequestResponse(response);
          break;
        // 🎯 NOU: Cazuri pentru opțiunile de cursă
        case 'ride_option':
          await _handleRideOptionSelection(response);
          break;
        case 'option_confirmation':
          await _handleRideOptionSelection(response);
          break;
        case 'driver_acceptance':
          await _handleDriverAcceptanceResponse(response);
          break;
        // 🎯 NOU: Cazuri pentru închiderea AI-ului
        case 'close_ai':
          await _handleCloseAI();
          break;
        case 'exit':
          await _handleCloseAI();
          break;
        case 'stop':
          await _handleCloseAI();
          break;
        case 'greeting':
          await _handleGreetingResponse(response);
          break;
        case 'rejection':
          await _handleRejectionResponse(response);
          break;
        case 'add_stop':
          if (response.message != null && response.message!.isNotEmpty) {
            _lastSpokenMessage = response.message!;
            await _speakEmotion(response.message!, VoiceEmotion.calm);
          }
          break;
        case 'cancel_ride':
          await _cancelRideBooking();
          if (response.message != null && response.message!.isNotEmpty) {
            _lastSpokenMessage = response.message!;
            await _speakEmotion(response.message!, VoiceEmotion.calm);
          }
          break;
        case 'app_action':
          await _handleAppAction(response);
          break;
        case 'help_response':
          await _handleHelpResponse(response);
          break;
        default:
          await _handleUnknownResponse(response);
      }
      
    } catch (e) {
      Logger.error('Response handling error: $e', tag: 'RIDE_FLOW', error: e);
      await _handleError(e.toString());
    }
  }
  
  /// 🎯 ÎMBUNĂTĂȚIT: Gestionează răspunsul pentru destinație (cu preview preț)
  Future<void> _handleDestinationResponse(GeminiVoiceResponse response) async {
    if (response.destination != null) {
      // Verifică dacă e o destinație diferită de cea anterioară
      if (_destination != null && _destination != response.destination) {
        Logger.info('Destination changed from $_destination to ${response.destination}', tag: 'RIDE_FLOW');
      }
      
      _destination = response.destination;
      _currentState = RideFlowState.destinationConfirmed;

      // ✅ Rezolvă alias-urile de adrese salvate ('Acasă', 'Serviciu')
      if (!await _resolveSavedAddressAlias()) return;

      // ✅ Geocodare silențioasă a destinației pentru a asigura coordonatele la confirmare
      if (_destinationLatitude == null || _destinationLongitude == null) {
        final geocoded = await _silentlyGeocodeDestination();
        if (!geocoded) {
          try {
            if (_destination != null && _destination!.isNotEmpty) {
              final pickup = _pickup ?? 'Locația curentă';
              onFillAddressInUI(
                pickup,
                _destination!,
                pickupLat: _pickupLatitude,
                pickupLng: _pickupLongitude,
                destLat: _destinationLatitude,
                destLng: _destinationLongitude,
              );
            }
          } catch (e) {
            Logger.error('UI update callback error: $e', tag: 'RIDE_FLOW', error: e);
          }
          await _promptDestinationLandmarkAndListen();
          return;
        }
      }

      // ✅ ACTUALIZEAZĂ UI-UL CU ADRESA ȘI COORDONATELE (dacă sunt disponibile)
      try {
        if (_destination != null && _destination!.isNotEmpty) {
          final pickup = _pickup ?? 'Locația curentă';
          onFillAddressInUI(
            pickup,
            _destination!,
            pickupLat: _pickupLatitude,
            pickupLng: _pickupLongitude,
            destLat: _destinationLatitude,
            destLng: _destinationLongitude,
          );
          Logger.info('UI updated with destination: $_destination', tag: 'RIDE_FLOW');
          if (_destinationLatitude != null && _destinationLongitude != null) {
            Logger.info('Coordinates also sent: $_destinationLatitude, $_destinationLongitude', tag: 'RIDE_FLOW');
          }
        }
      } catch (e) {
        Logger.error('UI update callback error: $e', tag: 'RIDE_FLOW', error: e);
      }

      // Nabour rides are free — no price calculation needed
      // ✅ FIX: Obțin limba curentă și mesajul tradus
      final confirmMessage = await VoiceTranslations.getDestinationWithPrice(_destination ?? '');
      _lastSpokenMessage = confirmMessage;
      // Dictation: utilizatorul poate confirma sau reformula destinația într-o propoziție lungă.
      await _speakThenListen(confirmMessage, emotion: VoiceEmotion.confident);
      _currentState = RideFlowState.awaitingConfirmation;
      // ✅ AFIȘEAZĂ PREȚUL ÎN UI (dacă callback-ul este disponibil)
      try {
        // Callback pentru afișare preț în UI
        // onShowPricePreview?.call(_estimatedPrice ?? 0.0, _currentRideCategory);
      } catch (e) {
        Logger.warning('Price preview callback not available: $e', tag: 'RIDE_FLOW');
      }
      
    } else {
      await _handleClarificationRequest(response);
    }
  }


  // (Removed _startListeningForConfirmation as it's replaced by atomic _speakThenListen)
  
  
  /// 🎯 Gestionează răspunsul de confirmare - CORECTAT
  Future<void> _handleConfirmationResponse(GeminiVoiceResponse response) async {
    try {
      Logger.debug('Handling confirmation response: "${response.message}"', tag: 'RIDE_FLOW');
      Logger.debug('Response confidence: ${response.confidence}', tag: 'RIDE_FLOW');
      Logger.debug('Current state before processing: $_currentState', tag: 'RIDE_FLOW');
      Logger.debug('Pickup location: $_pickup', tag: 'RIDE_FLOW');
      
      // Verifică dacă e răspuns pozitiv (da/confirm/etc)
      final isPositive = _isPositiveConfirmation(response.message ?? '');
      Logger.debug('Is positive confirmation: $isPositive', tag: 'RIDE_FLOW');
      
      if (isPositive) {
        // ✅ RĂSPUNS POZITIV - CONTINUĂ CU FLOW-UL
        
        // 🎯 VERIFICĂ DACĂ SUNTEM ÎN CONFIRMAREA FINALĂ A RIDE-ULUI
        if (_currentState == RideFlowState.awaitingRideConfirmation) {
          Logger.info('Final ride confirmation received - CREATING RIDE REQUEST', tag: 'RIDE_FLOW');
          
          // Oprește ascultarea pentru a preveni bucla
          await _voiceOrchestrator.stopListening();
          
          final confirmMessage = await VoiceTranslations.getFinalRideConfirmation();
          // Utilizatorul a confirmat deja — doar feedback TTS, fără a deschide din nou microfonul înainte de trimitere.
          await _speakEmotion(confirmMessage, VoiceEmotion.confident);

          // CREEAZĂ CEREREA DE CURSĂ (nu mai căuta șoferi din nou!)
          await _fillAddressAndNavigateToConfirmation();
          return; // IMPORTANT: Oprește execuția aici!
        }
        
        // Verifică contextul pentru confirmările anterioare (ÎNAINTE de a schimba starea)
        final isPickupConfirmation = _currentState == RideFlowState.awaitingConfirmation && _pickup != null;
        Logger.debug('Is pickup confirmation: $isPickupConfirmation', tag: 'RIDE_FLOW');
        
        // Schimbă starea DOAR după ce am verificat contextul
        _currentState = RideFlowState.confirmationReceived;
        
        if (isPickupConfirmation) {
          // ✅ FIX: Confirmarea pickup-ului cu mesaj tradus
          final languageCode = await _getCurrentLanguageCode();
          await _tts.setLanguage(languageCode);
          final confirmMessage = await VoiceTranslations.getPickupConfirmation(_pickup ?? '');
          _lastSpokenMessage = confirmMessage;
          await _speakEmotion(confirmMessage, VoiceEmotion.confident);
          Logger.info('Pickup confirmed, proceeding to driver search', tag: 'RIDE_FLOW');
          
          // Caută șoferi
          await _searchForDrivers();
        } else {
          // ✅ FIX: Confirmarea generală cu mesaj tradus
          final languageCode = await _getCurrentLanguageCode();
          await _tts.setLanguage(languageCode);
          final confirmMessage = await VoiceTranslations.getGeneralConfirmation();
          _lastSpokenMessage = confirmMessage;
          await _speakEmotion(confirmMessage, VoiceEmotion.confident);
          Logger.info('General confirmation received, proceeding to driver search', tag: 'RIDE_FLOW');
          
          // Caută șoferi
          await _searchForDrivers();
        }
        
      } else {
        // ❌ RĂSPUNS NEGATIV SAU AMBIGUU - CERE CLARIFICARE
        Logger.error('Negative or ambiguous response, asking for clarification', tag: 'RIDE_FLOW');
        
        _currentState = RideFlowState.awaitingClarification;
        
        // ✅ FIX: Cere clarificare specifică cu mesaj tradus
        final languageCode = await _getCurrentLanguageCode();
        await _tts.setLanguage(languageCode);
        final clarifyMessage = await VoiceTranslations.getClarificationQuestion();
        _lastSpokenMessage = clarifyMessage;
        await _speakEmotion(clarifyMessage, VoiceEmotion.calm);
        
        // Pornește ascultarea pentru clarificare
        await _startListeningForClarification();
      }
      
    } catch (e) {
      Logger.error('Confirmation response error: $e', tag: 'RIDE_FLOW', error: e);
      await _handleError('Eroare la procesarea confirmării: $e');
    }
  }
  
  /// 🚗 Caută șoferi disponibili
  Future<void> _searchForDrivers() async {
    _currentState = RideFlowState.searchingDrivers;
    
    // ✅ FIX: Obțin limba curentă și mesajul tradus
    final languageCode = await _getCurrentLanguageCode();
    await _tts.setLanguage(languageCode); // ✅ FIX: Asigur că limba este setată
    final searchingMessage = await VoiceTranslations.getSearchingDrivers();
    _lastSpokenMessage = searchingMessage;
    
    // ✅ FIX: Nu oprește listening - doar pune pe pauză temporar pentru a permite TTS-ului să vorbească
    // Flow-ul continuă fluid fără întreruperi
    await _voiceOrchestrator.pauseListening();
    
    await _speakEmotion(searchingMessage, VoiceEmotion.calm);
    
    // ✅ FIX: Reia listening după ce TTS-ul termină de vorbit cu limba corectă
    final localeId = languageCode == 'en' ? 'en_US' : 'ro_RO';
    await _voiceOrchestrator.resumeListening(localeId: localeId);

    try {
      if (_pickupLatitude == null || _pickupLongitude == null) {
        await _getCurrentUserLocation();
      }

      if (_pickupLatitude == null || _pickupLongitude == null) {
        throw Exception('Locația de preluare nu este disponibilă.');
      }

      final pickupPoint = Point(
        coordinates: Position(_pickupLongitude!, _pickupLatitude!),
      );

      final etaResult = await _firestoreService.getNearestDriverEta(
        pickupPoint,
        _currentRideCategory,
      );

      // ✅ CORECTAT: Verifică dacă există șoferi disponibili
      if (etaResult == null) {
        Logger.error('Nu sunt șoferi disponibili', tag: 'RIDE_FLOW');
        _currentState = RideFlowState.idle;
        await _voiceOrchestrator.stopListening();
        await _handleNoDriverFound();
        return; // Ieșim din funcție, nu continuăm
      }

      _availableDrivers = [
        'Șofer ${etaResult.driverId} - ${etaResult.durationInMinutes} min',
      ];

      _currentState = RideFlowState.driversFound;
      final resultsMessage =
          'Am găsit un șofer la ${etaResult.durationInMinutes} minute, la ${etaResult.distanceInKm.toStringAsFixed(1)} kilometri distanță. Confirmăm rezervarea?';
      _lastSpokenMessage = resultsMessage;
      
      Logger.debug('Saying results message, will wait for TTS to complete...', tag: 'RIDE_FLOW');
      
      await _voiceOrchestrator.stopListening();
      await _speakEmotion(resultsMessage, VoiceEmotion.happy);
      
      Logger.info('TTS completed, now setting state to awaitingRideConfirmation', tag: 'RIDE_FLOW');
      _currentState = RideFlowState.awaitingRideConfirmation;

      await Future.delayed(const Duration(milliseconds: 500));
      Logger.info('Now starting final confirmation listening...', tag: 'RIDE_FLOW');
      await _startListeningForFinalConfirmation();

    } catch (e) {
      Logger.error('Driver search error: $e', tag: 'RIDE_FLOW', error: e);
      // ✅ FIX: Obțin limba curentă și mesajul tradus
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode); // ✅ FIX: Setează limba înainte de a vorbi
      final errorMessage = await VoiceTranslations.getErrorCouldNotFindDrivers();
      await _handleError(errorMessage);
    }
  }
  
  /// 🎯 ÎMBUNĂTĂȚIT: Verifică dacă răspunsul e pozitiv cu detecție avansată
  bool _isPositiveConfirmation(String response) {
    final positive = [
      'da', 'yes', 'confirmă', 'confirm', 'perfect', 'ok', 'okay',
      'sigur', 'bine', 'exact', 'clar', 'înțeleg', 'înțeles', 'perfect',
      'hai', 'hai da', 'hai să mergem',
      'continuă', 'continuă', 'procedează', 'merge', 'bun', 'buna',
      'adevărat', 'să', 'să mergem', 'să procedez',
      'accept', 'accepted', 'accepți', 'accepți', 'să mergem',
      'bine', 'buna', 'exact', 'clar', 'înțeleg', 'înțeles',
      'sigur', 'sure', 'definitely', 'absolutely', 'exactly',
      'right', 'true', 'yes', 'yep', 'yeah',
      'continuă', 'continue', 'proceed', 'go ahead', 'let\'s go',
      'merge', 'works', 'good', 'fine', 'alright', 'sounds good'
    ];
    
    final negative = [
      'nu', 'no', 'refuz', 'refuse', 'nu vreau', 'nu la', 'nu merg',
      'nu este', 'nu e', 'nu e corect', 'nu e bun', 'nu e bine',
      'greșit', 'incorect', 'nu confirm', 'nu accept',
      'nope', 'nah', 'not', 'don\'t', 'won\'t', 'can\'t',
      'wrong', 'incorrect', 'false', 'bad', 'no good',
      'stop', 'cancel', 'abort', 'never', 'nothing'
    ];
    
    final lowerResponse = response.toLowerCase().trim();
    
    Logger.debug('Analyzing confirmation: "$lowerResponse"', tag: 'RIDE_FLOW');
    
    // Verifică răspunsuri foarte scurte (probabil confirmări)
    if (lowerResponse.length <= 3) {
      if (positive.any((word) => lowerResponse.contains(word))) {
        Logger.info('Short positive response: "$lowerResponse"', tag: 'RIDE_FLOW');
        return true;
      }
      if (negative.any((word) => lowerResponse.contains(word))) {
        Logger.error('Short negative response: "$lowerResponse"', tag: 'RIDE_FLOW');
        return false;
      }
    }
    
    // Verifică răspunsuri cu cuvinte de confirmare la început
    const startsWithPositive = ['da', 'yes', 'ok', 'bine', 'confirm', 'hai', 'sigur'];
    if (startsWithPositive.any((w) => lowerResponse.startsWith(w))) {
      Logger.info('Starts with confirmation: "$lowerResponse"', tag: 'RIDE_FLOW');
      return true;
    }
    
    // Verifică răspunsuri cu "nu" la început (foarte probabil refuz)
    if (lowerResponse.startsWith('nu') || lowerResponse.startsWith('no')) {
      Logger.error('Starts with refusal: "$lowerResponse"', tag: 'RIDE_FLOW');
      return false;
    }
    
    // Verifică mai întâi răspunsurile negative cu scoring
    int negativeScore = 0;
    for (String neg in negative) {
      if (lowerResponse.contains(neg)) {
        negativeScore++;
        Logger.error('Negative keyword: "$neg" in "$lowerResponse"', tag: 'RIDE_FLOW');
      }
    }
    
    // Verifică răspunsurile pozitive cu scoring
    int positiveScore = 0;
    for (String pos in positive) {
      if (lowerResponse.contains(pos)) {
        positiveScore++;
        Logger.info('Positive keyword: "$pos" in "$lowerResponse"', tag: 'RIDE_FLOW');
      }
    }
    
    // Decizie bazată pe scoring
    if (positiveScore > negativeScore) {
      Logger.info('Positive score wins: $positiveScore vs $negativeScore', tag: 'RIDE_FLOW');
      return true;
    } else if (negativeScore > positiveScore) {
      Logger.error('Negative score wins: $negativeScore vs $positiveScore', tag: 'RIDE_FLOW');
      return false;
    }
    
    // Răspuns ambiguu
    Logger.debug('Ambiguous response: "$lowerResponse" (scores: pos=$positiveScore, neg=$negativeScore)', tag: 'RIDE_FLOW');
    return false;
  }
  
  /// 🎯 Gestionează răspunsul pentru rezervarea cursei - INTEGRARE CU UI REAL
  Future<void> _handleRideRequestResponse(GeminiVoiceResponse response) async {
    if (response.confidence > 0.7) {
      // Verifică dacă e răspuns pozitiv pentru confirmarea finală
      if (_isPositiveConfirmation(response.message ?? '')) {
        
        // ✅ OPREȘTE ASCULTAREA - evită bucla
        await _voiceOrchestrator.stop();
        
        _currentState = RideFlowState.confirmationReceived;
        
        // 🎯 COMPLETEAZĂ ADRESA ÎN UI ȘI NAVIGHEAZĂ LA CONFIRMARE
        await _fillAddressAndNavigateToConfirmation();
        
      } else {
        // Răspuns negativ - cere din nou destinația
        await _askForNewDestination();
      }
    } else {
      await _handleClarificationRequest(response);
    }
  }
  
  /// 🎯 Gestionează selecția șoferului
  Future<void> _handleDriverSelectionResponse(GeminiVoiceResponse response) async {
    // 🚗 Logica pentru selecția șoferului
    _currentState = RideFlowState.driverSelected;
  }
  
  /// 🎯 Gestionează confirmarea prețului
  Future<void> _handlePriceConfirmationResponse(GeminiVoiceResponse response) async {
    // 💰 Logica pentru confirmarea prețului
    _currentState = RideFlowState.priceConfirmed;
  }
  
  /// 🎯 Gestionează finalizarea rezervării
  Future<void> _handleBookingFinalizationResponse(GeminiVoiceResponse response) async {
    // ✅ Logica pentru finalizarea rezervării
    _currentState = RideFlowState.bookingFinalized;
  }
  
  /// 🎯 Gestionează cererea de clarificare
  Future<void> _handleClarificationRequest(GeminiVoiceResponse response) async {
    if (response.clarificationQuestion != null) {
      _lastSpokenMessage = response.clarificationQuestion!;
      _currentState = RideFlowState.awaitingClarification;
      await _speakThenListen(response.clarificationQuestion!);
    } else {
      final retryMessage = await VoiceTranslations.getPleaseSpecifyDestination();
      _lastSpokenMessage = retryMessage;
      _currentState = RideFlowState.listeningForInitialCommand;
      await _speakThenListen(retryMessage);
    }
  }
  
  /// 🎯 Gestionează răspunsuri necunoscute
  Future<void> _handleUnknownResponse(GeminiVoiceResponse response) async {
    Logger.warning('Unknown response type: ${response.type}', tag: 'RIDE_FLOW');
    final unknownMessage = await VoiceTranslations.getDidNotUnderstandRepeatDestination();
    _lastSpokenMessage = unknownMessage;
    await _speakThenListen(unknownMessage);
  }
  
  /// 🎯 Gestionează salutări
  Future<void> _handleGreetingResponse(GeminiVoiceResponse response) async {
    final greetingMessage = await VoiceTranslations.getGreeting();
    await _speakThenListen(greetingMessage, emotion: VoiceEmotion.friendly);
  }
  
  /// 🎯 Gestionează răspunsul de respingere (când utilizatorul refuză sau cere clarificare)
  Future<void> _handleRejectionResponse(GeminiVoiceResponse response) async {
    Logger.debug('Handling rejection response: ${response.message}', tag: 'RIDE_FLOW');
    if (response.clarificationQuestion != null) {
      _lastSpokenMessage = response.clarificationQuestion!;
      _currentState = RideFlowState.awaitingClarification;
      await _speakThenListen(response.clarificationQuestion!);
    } else {
      final retryMessage = await VoiceTranslations.getPleaseSpecifyDestination();
      _lastSpokenMessage = retryMessage;
      _currentState = RideFlowState.listeningForInitialCommand;
      await _speakThenListen(retryMessage, pauseForSeconds: 5);
    }
  }
  
  /// Transformă textul brut de eroare într-un mesaj scurt, fără stack / zgomot tehnic.
  String _toUserFacingError(String raw) {
    var s = raw.trim();
    const prefixes = ['Exception:', 'Exception :', 'Error:', 'Dart exception:'];
    var stripped = true;
    while (stripped) {
      stripped = false;
      for (final prefix in prefixes) {
        final pl = prefix.length;
        if (s.length >= pl && s.substring(0, pl).toLowerCase() == prefix.toLowerCase()) {
          s = s.substring(pl).trim();
          stripped = true;
          break;
        }
      }
    }
    final nl = s.indexOf('\n');
    if (nl != -1) s = s.substring(0, nl).trim();
    if (s.length > 220) s = '${s.substring(0, 217)}…';
    return s;
  }

  /// 🎯 ÎMBUNĂTĂȚIT: Eroare cu TTS + reluare conversație (nu rămâneți într-o stare moartă fără microfon).
  Future<void> _handleError(String error, {bool recoverSession = true}) async {
    Logger.error('Error: $error', tag: 'RIDE_FLOW', error: error);

    final languageCode = await _getCurrentLanguageCode();
    await _tts.setLanguage(languageCode);

    var brief = _toUserFacingError(error);
    if (brief.isEmpty) {
      brief = await VoiceTranslations.getGenericProblemShort();
    }

    final spoken = recoverSession
        ? await VoiceTranslations.composeErrorWithRecoveryHint(brief)
        : brief;

    _lastSpokenMessage = spoken;

    if (recoverSession) {
      _currentState = RideFlowState.listeningForInitialCommand;
      await _speakThenListen(spoken, emotion: VoiceEmotion.calm, pauseForSeconds: 5);
    } else {
      await _speakEmotion(spoken, VoiceEmotion.calm);
      _currentState = RideFlowState.error;
    }

    try {
      // onShowError?.call(spoken);
    } catch (e) {
      Logger.error('Error callback not available: $e', tag: 'RIDE_FLOW', error: e);
    }
  }
  

  


  /// 📝 Adaugă la istoricul conversației
  void _addToHistory(String message) {
    _conversationHistory.add(message);
    if (_conversationHistory.length > 20) {
      _conversationHistory.removeAt(0);
    }
  }

  /// 📝 Expune istoricul conversației pentru UI (copie)
  List<String> get conversationHistoryCopy => List<String>.from(_conversationHistory);

  /// 🗣️ Adaugă un mesaj AI în istoric (pentru salut/indicii UI)
  void addAiMessage(String message) {
    _addToHistory('AI: $message');
  }
  
  /// 🎯 Obține starea curentă
  RideFlowState get currentState => _currentState;
  
  /// 🚗 Obține destinația
  String? get destination => _destination;
  
  /// 🚗 Obține pickup-ul
  String? get pickup => _pickup;
  
  /// 💰 Obține prețul estimat
  double? get estimatedPrice => _estimatedPrice;

  double? get calculatedDistanceKm => _calculatedDistanceKm;

  double? get calculatedDurationMinutes => _calculatedDurationMinutes;

  Map<String, double>? get fareBreakdown => _fareBreakdown;

  RideCategory get currentRideCategory => _currentRideCategory;
  
  /// 🚗 Obține șoferii disponibili
  List<String> get availableDrivers => _availableDrivers;
  
  /// 📝 Obține istoricul conversației (read-only)
  List<String> get conversationHistory => List.unmodifiable(_conversationHistory);
  
  /// 🗣️ Obține ultimul mesaj rostit
  String get lastSpokenMessage => _lastSpokenMessage;
  
  /// 🎯 NOU: Pornește automat ascultarea pentru clarificare
  Future<void> _startListeningForClarification() async {
    try {
      // Așteaptă puțin să se termine TTS-ul complet
      await Future.delayed(const Duration(milliseconds: 1500));
      
      Logger.info('Auto-starting clarification listening...', tag: 'RIDE_FLOW');
      
      // Pornește automat ascultarea pentru clarificare
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30, // Timp suficient pentru clarificare
        pauseForSeconds: 10,
      );
      
    } catch (e) {
      Logger.error('Auto-listen for clarification error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }




  /// ❌ Anulează rezervarea
  /// 🎯 ACEASTĂ FUNCȚIE SE FOLOSEȘTE DOAR LA ACTIVAREA BUTONULUI "ANULEAZĂ" DIN UI
  /// 🚫 NU SE APEAZĂ AUTOMAT - DOAR CÂND USER-UL APASĂ BUTONUL
  Future<void> _cancelRideBooking() async {
    _currentState = RideFlowState.idle;
    // ✅ FIX: Obțin limba curentă și mesajul tradus
    final languageCode = await _getCurrentLanguageCode();
    await _tts.setLanguage(languageCode);
    final cancelMessage = languageCode == 'en' 
        ? 'I understand. The reservation has been cancelled. Can I help you with anything else?'
        : 'Înțeleg. Rezervarea a fost anulată. Vă pot ajuta cu altceva?';
    _lastSpokenMessage = cancelMessage;
    await _speakEmotion(cancelMessage, VoiceEmotion.calm);
  }

  /// Rezolvă un alias de adresă salvată ('Acasă', 'Serviciu') la adresa reală
  /// și coordonatele din Firestore. Returnează false (și rostește eroarea) dacă
  /// aliasul nu există în adresele salvate ale utilizatorului.
  Future<bool> _resolveSavedAddressAlias() async {
    if (_destination == null) return true;

    final dest = _destination!.trim();
    final isAlias = dest == 'Acasă' || dest == 'Serviciu';
    if (!isAlias) return true;

    try {
      final List<SavedAddress> addresses =
          await _firestoreService.getSavedAddresses().first;
      final destLower = dest.toLowerCase().trim();
      SavedAddress? resolved;
      if (destLower == 'acasă' || destLower == 'acasa') {
        for (final a in addresses) {
          if (a.isHomeCategory || a.label.toLowerCase().trim() == destLower) {
            resolved = a;
            break;
          }
        }
      } else if (destLower == 'serviciu' ||
          destLower == 'birou' ||
          destLower == 'job') {
        for (final a in addresses) {
          if (a.isWorkCategory || a.label.toLowerCase().trim() == destLower) {
            resolved = a;
            break;
          }
        }
      } else {
        for (final a in addresses) {
          if (a.label.toLowerCase().trim() == destLower) {
            resolved = a;
            break;
          }
        }
      }
      if (resolved != null) {
        final a = resolved;
        Logger.info(
          'Resolved alias "$dest" → "${a.address}" (${a.coordinates.latitude}, ${a.coordinates.longitude})',
          tag: 'RIDE_FLOW',
        );
        _destination = a.address;
        _destinationLatitude = a.coordinates.latitude;
        _destinationLongitude = a.coordinates.longitude;
        return true;
      }
      // Aliasul e recunoscut dar nu a fost salvat de utilizator
      final msg =
          'Nu ai o adresă salvată pentru "$dest". '
          'Poți adăuga una din Setări → Adrese salvate, sau spune adresa completă.';
      _lastSpokenMessage = msg;
      await _speakEmotion(msg, VoiceEmotion.calm);
      _destination = null;
      _currentState = RideFlowState.awaitingClarification;
      return false;
    } catch (e) {
      Logger.error('Saved address alias resolution error: $e', tag: 'RIDE_FLOW', error: e);
      return true; // non-fatal: lasă fluxul să continue
    }
  }

  /// 🎯 SINCRONIZAT: Completează adresa și navighează DIRECT la SearchingForDriverScreen (ca fluxul manual)
  /// ✅ NAVIGATION GUARD: Previne navigare duplicată
  Future<void> _fillAddressAndNavigateToConfirmation() async {
    // ✅ NAVIGATION GUARD: Verifică dacă deja navigăm
    if (_isNavigating) {
      Logger.warning('Navigation already in progress, skipping duplicate call', tag: 'RIDE_FLOW');
      return;
    }
    
    _isNavigating = true;

    try {
      Logger.debug('Filling address and navigating DIRECTLY to SearchingForDriverScreen...', tag: 'RIDE_FLOW');
      
      // ✅ 0. Sincronizează UI-ul (mută panelul în starea de confirmare)
      onPressConfirmButtonInUI();
      
      // 🗣️ Anunță că completează adresele și trimite solicitarea
      // ✅ NOU: Folosește traducere
      final message = await VoiceTranslations.getCompletingAddresses();
      await _speakEmotion(message, VoiceEmotion.confident);
      
      // ✅ 1. Salvează starea internă și geocodează pickup dacă e nevoie
      final currentLocation = await _getCurrentUserLocation();
      _pickup = _pickup ?? currentLocation;
      
      // ✅ 1.1 Geocodează pickup dacă a fost setat text de Gemini dar n-avem coordonate
      if (_pickupLatitude == null || _pickupLongitude == null) {
        await _silentlyGeocodePickup();
      }
      
      Logger.debug('Current user location: $currentLocation', tag: 'RIDE_FLOW');
      
      // ✅ 2. Validează adresele (ca fluxul manual)
      // ✅ SECURITY: Validate addresses before processing
      if (_pickup != null) {
        final pickupValidation = InputValidator.validateAddress(_pickup!);
        if (!pickupValidation.isValid) {
          await _handleError(pickupValidation.error ?? 'Adresa de preluare nu este validă.');
          return;
        }
      }
      
      if (_destination != null) {
        final destValidation = InputValidator.validateAddress(_destination!);
        if (!destValidation.isValid) {
          await _handleError(destValidation.error ?? 'Adresa de destinație nu este validă.');
          return;
        }
      }
      
      // ✅ SECURITY: Validate coordinates
      if (_pickupLatitude != null && _pickupLongitude != null) {
        final coordValidation = InputValidator.validateCoordinates(_pickupLatitude, _pickupLongitude);
        if (!coordValidation.isValid) {
          await _handleError(coordValidation.error ?? 'Coordonatele de preluare nu sunt valide.');
          return;
        }
      }
      
      if (_destinationLatitude != null && _destinationLongitude != null) {
        final coordValidation = InputValidator.validateCoordinates(_destinationLatitude, _destinationLongitude);
        if (!coordValidation.isValid) {
          await _handleError(coordValidation.error ?? 'Coordonatele de destinație nu sunt valide.');
          return;
        }
      }
      
      if (!await _validateAddresses()) {
        await _handleError('Adresele nu sunt valide. Vă rog să specificați din nou.');
        return;
      }
      
      // ✅ 3. Creează obiectul Ride complet (ca fluxul manual)
      final rideRequest = await _createCompleteRideRequest();
      
      // ✅ 5. Trimite direct la Firebase (ca fluxul manual) cu error handling
      String? rideId;
      try {
        rideId = await onCreateRideRequest(rideRequest).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Crearea cursei a durat prea mult. Vă rog să reîncercați.');
          },
        );
      } catch (e) {
        Logger.error('Error creating ride request: $e', tag: 'RIDE_FLOW', error: e);
        await _handleError('Nu am putut crea cursa: ${e.toString()}');
        return; // Oprește execuția dacă crearea cursei eșuează
      }
      
      if (rideId == null || rideId.isEmpty) {
        Logger.error('Ride ID is null or empty', tag: 'RIDE_FLOW');
        await _handleError('Nu am putut crea cursa. ID-ul cursei este invalid.');
        return;
      }
      
      // ✅ NOU: Salvează rideId pentru confirmarea ulterioară a șoferului
      _currentRideId = rideId;
      
      // ✅ 6. Mesaj după trimiterea cererii (încă se caută șofer; cursa pe hartă după acceptare)
      final farewellMessage = await VoiceTranslations.getRequestSentToDrivers();
      _lastSpokenMessage = farewellMessage;
      await _speakEmotion(farewellMessage, VoiceEmotion.happy);

      // ✅ 6.1 Începe monitorizarea statusului pentru voce (BACKGROUND)
      _monitorRideStatus(rideId);

      // ✅ 7. Navighează DIRECT la SearchingForDriverScreen (ca fluxul manual)
      try {
        final searchingScreen = SearchingForDriverScreen(rideId: rideId);
        onNavigateToScreen(searchingScreen);
        Logger.info('Ride request sent directly to Firebase, navigating to SearchingForDriverScreen', tag: 'RIDE_FLOW');
      } catch (e) {
        Logger.error('Navigation error: $e', tag: 'RIDE_FLOW', error: e);
        await _handleError('Nu am putut naviga la ecranul de căutare șoferi: ${e.toString()}');
      }
      
    } catch (e) {
      Logger.error('Fill address error: $e', tag: 'RIDE_FLOW', error: e);
      await _handleError('Eroare la completarea adreselor: ${e.toString()}');
    } finally {
      _isNavigating = false;
    }
  }

  /// 🎯 ÎMBUNĂTĂȚIT: Validează adresele complet (coordonate, distanță, validitate)
  Future<bool> _validateAddresses() async {
    try {
      // ✅ VALIDARE ADRESE TEXT
      if (_pickup == null || _destination == null) {
        await _handleError('Lipsește punctul de plecare sau destinația. Vă rog să specificați ambele.');
        return false;
      }
      
      if (_pickup!.isEmpty || _destination!.isEmpty) {
        await _handleError('Adresele nu pot fi goale. Vă rog să specificați adresele complete.');
        return false;
      }
      
      // ✅ VALIDARE COORDONATE
      if (_pickupLatitude == null || _pickupLongitude == null) {
        await _handleError('Coordonatele punctului de plecare nu sunt disponibile. Vă rog să reîncercați.');
        return false;
      }
      
      if (_destinationLatitude == null || _destinationLongitude == null) {
        await _handleError('Coordonatele destinației nu sunt disponibile. Vă rog să reîncercați.');
        return false;
      }
      
      // ✅ VALIDARE COORDONATE VALIDE (lat: -90..90, lng: -180..180)
      if (_pickupLatitude! < -90 || _pickupLatitude! > 90 ||
          _pickupLongitude! < -180 || _pickupLongitude! > 180) {
        await _handleError('Coordonatele punctului de plecare sunt invalide.');
        return false;
      }
      
      if (_destinationLatitude! < -90 || _destinationLatitude! > 90 ||
          _destinationLongitude! < -180 || _destinationLongitude! > 180) {
        await _handleError('Coordonatele destinației sunt invalide.');
        return false;
      }
      
      // ✅ VALIDARE DISTANȚĂ MINIMĂ (100 metri)
      final distanceKm = _calculateDistance();
      if (distanceKm < 0.1) {
        await _handleError('Distanța este prea mică. Distanța minimă este 100 metri. Vă rog să alegeți o destinație mai departe.');
        return false;
      }
      
      // ✅ VALIDARE DISTANȚĂ MAXIMĂ (200 km)
      if (distanceKm > 200) {
        await _handleError('Distanța este prea mare. Distanța maximă este 200 km. Vă rog să alegeți o destinație mai aproape.');
        return false;
      }
      
      Logger.info('Addresses validated: pickup=$_pickup, destination=$_destination, distance=${distanceKm.toStringAsFixed(2)}km', tag: 'RIDE_FLOW');
      return true;
    } catch (e) {
      Logger.error('Address validation error: $e', tag: 'RIDE_FLOW', error: e);
      await _handleError('Eroare la validarea adreselor: $e');
      return false;
    }
  }

  /// 🗺️ Cere utilizatorului să aleagă adresa corectă din mai multe variante
  Future<void> _askForAddressDisambiguation(
      List<geocoding_svc.AddressSuggestion> suggestions) async {
    _disambiguationSuggestions = suggestions.take(3).toList();
    _currentState = RideFlowState.awaitingAddressSelection;

    final buffer = StringBuffer(
        'Am găsit mai multe adrese. Spuneți numărul adresei dorite sau alegeți pe hartă: ');
    for (int i = 0; i < _disambiguationSuggestions.length; i++) {
      buffer.write('${i + 1}. ${_disambiguationSuggestions[i].description}. ');
    }

    final message = buffer.toString();
    _lastSpokenMessage = message;
    await _speakEmotion(message, VoiceEmotion.calm);
    await _voiceOrchestrator.listen(timeoutSeconds: 30, pauseForSeconds: 8);
  }

  /// 🗺️ Procesează selecția numerică a adresei de către utilizator
  Future<void> _handleAddressSelection(String userInput) async {
    final lower = userInput.toLowerCase().trim();

    int? selected;
    if (lower == '1' || lower.contains('unu') || lower.contains('primul') || lower.startsWith('1 ')) {
      selected = 1;
    } else if (lower == '2' || lower.contains('doi') || lower.contains('două') || lower.contains('doua') || lower.startsWith('2 ')) {
      selected = 2;
    } else if (lower == '3' || lower.contains('trei') || lower.startsWith('3 ')) {
      selected = 3;
    }

    if (selected != null && selected <= _disambiguationSuggestions.length) {
      final chosen = _disambiguationSuggestions[selected - 1];
      _destinationLatitude = chosen.latitude;
      _destinationLongitude = chosen.longitude;
      _destination = chosen.description;
      _disambiguationSuggestions = [];

      final confirmMsg = 'Am selectat: ${chosen.description}. Caut șoferi disponibili...';
      _lastSpokenMessage = confirmMsg;
      await _speakEmotion(confirmMsg, VoiceEmotion.confident);

      _currentState = RideFlowState.destinationConfirmed;
      onFillAddressInUI(
        _pickup ?? 'Locația curentă',
        _destination!,
        pickupLat: _pickupLatitude,
        pickupLng: _pickupLongitude,
        destLat: _destinationLatitude,
        destLng: _destinationLongitude,
      );
      await _searchForDrivers();
    } else if (lower.contains('hart') || lower.contains('map') || lower.contains('alege')) {
      _disambiguationSuggestions = [];
      _currentState = RideFlowState.idle;
      const mapMsg = 'Selectați destinația pe hartă sau introduceți adresa completă în câmpul de căutare.';
      _lastSpokenMessage = mapMsg;
      await _speakEmotion(mapMsg, VoiceEmotion.calm);
    } else {
      // Răspuns neclar — repetă opțiunile
      await _askForAddressDisambiguation(_disambiguationSuggestions);
    }
  }

  /// 🎯 NOUĂ METODĂ: Calculează distanța REALĂ folosind coordonate GPS și formula Haversine
  double _calculateDistance() {
    try {
      // Verifică dacă avem coordonate pentru pickup și destinație
      if (_pickupLatitude == null || _pickupLongitude == null) {
        Logger.warning('Missing pickup coordinates - using default 5km', tag: 'DISTANCE');
        return 5.0;
      }
      
      if (_destinationLatitude == null || _destinationLongitude == null) {
        Logger.warning('Missing destination coordinates - using default 5km', tag: 'DISTANCE');
        return 5.0;
      }
      
      // ✅ Calculează distanța REALĂ folosind formula Haversine
      final distance = _calculateHaversineDistance(
        _pickupLatitude!,
        _pickupLongitude!,
        _destinationLatitude!,
        _destinationLongitude!,
      );
      
      Logger.info('Calculated REAL distance: ${distance.toStringAsFixed(2)} km', tag: 'DISTANCE');
      Logger.debug('From: ($_pickupLatitude, $_pickupLongitude)');
      Logger.debug('To: ($_destinationLatitude, $_destinationLongitude)');
      
      return distance;
      
    } catch (e) {
      Logger.error('Calculation error: $e', tag: 'DISTANCE', error: e);
      return 5.0; // Fallback la 5 km
    }
  }
  
  /// 📐 Formula Haversine pentru calcul distanță între două coordonate GPS
  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Raza Pământului în km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;
    
    return distance; // Distanța în km
  }
  
  /// 📐 Convertește grade în radiani
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
  
  /// 🧠 Întreabă Gemini AI pentru o adresă mai clară și coordonate GPS când geocoding-ul eșuează
  /// Returnează un Map cu 'address' (adresa clarificată) și opțional 'latitude' și 'longitude' (dacă Gemini AI le oferă)
  /// Sau null dacă Gemini AI nu poate ajuta
  Future<Map<String, dynamic>?> _askGeminiForClarifiedAddress(String originalAddress) async {
    try {
      Logger.debug('Asking Gemini AI for clarified address and coordinates: $originalAddress', tag: 'GEMINI_GEOCODE');
      
      // ✅ FIX: Folosește metoda directă de clarificare a adresei și obținere coordonate (fără logica de conversație)
      final result = await _geminiEngine.clarifyAddressForGeocoding(originalAddress);
      
      if (result != null && result['address'] != null) {
        Logger.info('Gemini AI clarified address: ${result['address']}', tag: 'GEMINI_GEOCODE');
        if (result['latitude'] != null && result['longitude'] != null) {
          Logger.info('Gemini AI also provided coordinates: ${result['latitude']}, ${result['longitude']}', tag: 'GEMINI_GEOCODE');
        }
        return result;
      } else {
        Logger.warning('Gemini AI could not clarify address', tag: 'GEMINI_GEOCODE');
        return null;
      }
      
    } catch (e) {
      Logger.error('Error asking Gemini AI: $e', tag: 'GEMINI_GEOCODE', error: e);
      return null;
    }
  }
  
  /// 🗺️ Verifică destinațiile predefinite (rapid, fără API calls)
  /// Returnează coordonatele dacă destinația este cunoscută, altfel null
  Map<String, dynamic>? _getPredefinedDestinationCoordinates(String destination) {
    // ✅ FIX: Folosește baza de date locală extinsă pentru locații din București și Ilfov
    try {
      final location = BucharestLocationsDatabase.findLocation(destination);
      if (location != null) {
        Logger.info('Found location in database: ${location['name']} (${location['category']})', tag: 'GPS');
        return {
          'latitude': location['latitude'],
          'longitude': location['longitude'],
          'name': location['name'],
        };
      }
    } catch (e) {
      Logger.error('Error searching location database: $e', tag: 'GPS', error: e);
    }

    // ✅ Fallback: Lista de destinații cunoscute cu coordonatele exacte (pentru compatibilitate)
    final destinationCoordinates = {
      'Aeroportul Henri Coandă': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'Aeroportul Henri Coanda': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'Aeroport Otopeni': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'Aeroportul Otopeni': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'Otopeni': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'aeroport': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'Piața Victoriei': {'latitude': 44.4518, 'longitude': 26.0970, 'name': 'Piața Victoriei, București'},
      'Piața Victoriei, București': {'latitude': 44.4518, 'longitude': 26.0970, 'name': 'Piața Victoriei, București'},
      'Mall Băneasa': {'latitude': 44.5072, 'longitude': 26.0769, 'name': 'Mall Băneasa, București'},
      'Mall Băneasa, București': {'latitude': 44.5072, 'longitude': 26.0769, 'name': 'Mall Băneasa, București'},
      'Gara de Nord': {'latitude': 44.4478, 'longitude': 26.0758, 'name': 'Gara de Nord, București'},
      'Gara de Nord, București': {'latitude': 44.4478, 'longitude': 26.0758, 'name': 'Gara de Nord, București'},
      'Gara Nord': {'latitude': 44.4478, 'longitude': 26.0758, 'name': 'Gara de Nord, București'},
      'gara': {'latitude': 44.4478, 'longitude': 26.0758, 'name': 'Gara de Nord, București'},
      'Piața Universității': {'latitude': 44.4355, 'longitude': 26.1008, 'name': 'Piața Universității, București'},
      'Piața Universității, București': {'latitude': 44.4355, 'longitude': 26.1008, 'name': 'Piața Universității, București'},
      'Centrul Vechi': {'latitude': 44.4323, 'longitude': 26.0999, 'name': 'Centrul Vechi, București'},
      'Centrul Vechi, București': {'latitude': 44.4323, 'longitude': 26.0999, 'name': 'Centrul Vechi, București'},
      'Herastrau Park': {'latitude': 44.4684, 'longitude': 26.0831, 'name': 'Herastrau Park, București'},
      'Herastrau Park, București': {'latitude': 44.4684, 'longitude': 26.0831, 'name': 'Herastrau Park, București'},
      'Plaza Romania': {'latitude': 44.4486, 'longitude': 26.0188, 'name': 'Plaza Romania, București'},
      'Plaza Romania, București': {'latitude': 44.4486, 'longitude': 26.0188, 'name': 'Plaza Romania, București'},
      'Piața Unirii': {'latitude': 44.4268, 'longitude': 26.1025, 'name': 'Piața Unirii, București'},
      'Piața Unirii, București': {'latitude': 44.4268, 'longitude': 26.1025, 'name': 'Piața Unirii, București'},
      'piata unirii': {'latitude': 44.4268, 'longitude': 26.1025, 'name': 'Piața Unirii, București'},
      'centru': {'latitude': 44.4268, 'longitude': 26.1025, 'name': 'Centrul Bucureștiului'},
      'centrul': {'latitude': 44.4268, 'longitude': 26.1025, 'name': 'Centrul Bucureștiului'},
    };
    
    // Normalizează destinația pentru căutare (lowercase, fără diacritice opțional)
    final normalizedDestination = destination.toLowerCase().trim();
    
    // Caută destinația exactă sau parțială
    for (final entry in destinationCoordinates.entries) {
      final key = entry.key.toLowerCase();
      // Verifică dacă destinația conține cheia sau cheia conține destinația
      if (normalizedDestination.contains(key) || key.contains(normalizedDestination)) {
        Logger.info('Found predefined destination: ${entry.key} -> ${entry.value['name']}', tag: 'GPS');
        return entry.value;
      }
    }
    
    // Verifică și variante cu "plecări" sau "sosiri" (pentru aeroport)
    if (normalizedDestination.contains('aeroport') || normalizedDestination.contains('otopeni')) {
      if (normalizedDestination.contains('plecări') || normalizedDestination.contains('plecari') ||
          normalizedDestination.contains('sosiri') || normalizedDestination.contains('sosiri')) {
        Logger.info('Found predefined destination: Aeroportul Henri Coandă (with terminal info)', tag: 'GPS');
        return {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'};
      }
    }
    
    return null; // Nu e predefinită
  }

  /// 🎯 ÎMBUNĂTĂȚIT: Creează obiectul Ride complet (ca fluxul manual) cu validări
  Future<Map<String, dynamic>> _createCompleteRideRequest() async {
    try {
      // ✅ FIX: Obține user ID real din Firebase Auth
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        throw Exception('Utilizatorul nu este autentificat. Vă rog să vă logați.');
      }
      
      // ✅ FIX: Validează că avem coordonate valide (nu default)
      if (_pickupLatitude == null || _pickupLongitude == null) {
        throw Exception('Coordonatele pickup nu sunt disponibile. Vă rog să reîncercați.');
      }
      
      if (_destinationLatitude == null || _destinationLongitude == null) {
        throw Exception('Coordonatele destinației nu sunt disponibile. Vă rog să reîncercați.');
      }
      
      // ✅ FIX: Calculează distanța reală (nu default)
      final distance = _calculatedDistanceKm ?? _calculateDistance();
      if (distance < 0.1 || distance > 200) {
        throw Exception('Distanța calculată este invalidă: ${distance.toStringAsFixed(2)} km');
      }
      
      final rideRequest = <String, dynamic>{
        'id': '',
        'passengerId': userId, // ✅ FIX: User ID real, nu string gol
        'pickup': _pickup ?? '',
        'destination': _destination ?? '',
        'startAddress': _pickup ?? '',
        'destinationAddress': _destination ?? '',
        'distance': distance,
        'startLatitude': _pickupLatitude!,
        'startLongitude': _pickupLongitude!,
        'destinationLatitude': _destinationLatitude!,
        'destinationLongitude': _destinationLongitude!,
        'durationInMinutes': (_calculatedDurationMinutes ?? 15).round(),
        'baseFare': _fareBreakdown?['baseFare'] ?? 0.0,
        'perKmRate': _fareBreakdown?['perKmRate'] ?? 0.0,
        'perMinRate': _fareBreakdown?['perMinRate'] ?? 0.0,
        'totalCost': _estimatedPrice ?? 0.0,
        'estimatedPrice': _estimatedPrice ?? 0.0,
        'appCommission': _fareBreakdown?['appCommission'] ?? ((_estimatedPrice ?? 0.0) * 0.1),
        'driverEarnings': _fareBreakdown?['driverEarnings'] ?? ((_estimatedPrice ?? 0.0) * 0.9),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
        'category': _currentRideCategory.name,
        'urgency': 'normal',
        'stops': [],
        'isScheduled': false,
        'scheduledPickupTime': null,
      };
      
      Logger.info('Complete ride request created for user: $userId', tag: 'RIDE_FLOW');
      return rideRequest;
    } catch (e) {
      Logger.error('Ride request creation error: $e', tag: 'RIDE_FLOW', error: e);
      rethrow;
    }
  }

  /// 🎯 NOUĂ METODĂ: Gestionează confirmarea adreselor din UI
  Future<void> handleAddressConfirmation() async {
    try {
      Logger.debug('Address confirmed from UI, showing ride options...', tag: 'RIDE_FLOW');
      
      _currentState = RideFlowState.showingRideOptions;
      
      // 🗣️ Prezintă opțiunile vocale
      const optionsMessage = '''Vă arăt opțiunile disponibile:
      - Standard: Cel mai economic
      - Family: Pentru familii cu copii  
      - Energy: Mașini electrice
      - Best: Cel mai confortabil
      
      Care opțiune preferați?''';
      
      await _speakEmotion(optionsMessage, VoiceEmotion.confident);
      
      // 🎯 PORNEȘTE ASCULTAREA DOAR PENTRU OPȚIUNI
      await _startListeningForRideOption();
      
    } catch (e) {
      Logger.error('Address confirmation error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// 🎯 NOUĂ METODĂ: Ascultă pentru opțiunea de cursă
  Future<void> _startListeningForRideOption() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      Logger.info('Listening for ride option selection...', tag: 'RIDE_FLOW');
      
      _currentState = RideFlowState.awaitingRideOptionSelection;
      
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30,
      );
      
    } catch (e) {
      Logger.error('Ride option listening error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// 🎯 NOUĂ METODĂ: Gestionează selecția opțiunii de cursă
  Future<void> _handleRideOptionSelection(GeminiVoiceResponse response) async {
    try {
      // Extrage opțiunea din răspuns
      final option = _extractRideOption(response.message ?? '');
      
      if (option != null) {
        // ✅ OPREȘTE ASCULTAREA
        await _voiceOrchestrator.stop();
        
        _currentState = RideFlowState.rideOptionSelected;
        _currentRideCategory = option;
        
        // 🗣️ Confirmă opțiunea
        final confirmMessage = 'Ați ales opțiunea $option. Confirm selecția?';
        await _speakEmotion(confirmMessage, VoiceEmotion.confident);
        
        // ✅ Emite comanda abstractă pentru selecția în UI
        onSelectRideOptionInUI(option);
        
        // 🎯 AȘTEAPTĂ CONFIRMAREA FINALĂ
        await _startListeningForFinalRideConfirmation();
        
      } else {
        await _handleClarificationRequest(response);
      }
      
    } catch (e) {
      Logger.error('Ride option selection error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// 🎯 Geocodare silențioasă pentru destinație (nativ + OSM ca în fluxul principal). [true] dacă avem coordonate.
  Future<bool> _silentlyGeocodeDestination() async {
    if (_destination == null || _destination!.isEmpty) return false;

    if (_destinationLatitude != null && _destinationLongitude != null) {
      return true;
    }

    try {
      Logger.debug('Silently geocoding destination: $_destination', tag: 'GPS');
      final locations = await geocoding.locationFromAddress(_destination!);
      if (locations.isNotEmpty) {
        _destinationLatitude = locations.first.latitude;
        _destinationLongitude = locations.first.longitude;
        Logger.info('Destination geocoded to: $_destinationLatitude, $_destinationLongitude', tag: 'GPS');
        return true;
      }
    } catch (e) {
      Logger.debug('Silent geocode native: $e', tag: 'GPS');
    }

    if (_pickupLatitude != null && _pickupLongitude != null) {
      try {
        final pos = geolocator.Position(
          latitude: _pickupLatitude!,
          longitude: _pickupLongitude!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        var suggestions =
            await geocoding_svc.GeocodingService().fetchSuggestions(_destination!, pos);
        if (suggestions.isEmpty) {
          suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
            _destination!,
            pos,
          );
        }
        if (suggestions.isNotEmpty) {
          suggestions.sort((a, b) {
            final distA = a.distanceMeters ?? double.infinity;
            final distB = b.distanceMeters ?? double.infinity;
            return distA.compareTo(distB);
          });
          final closest = suggestions.first;
          _destinationLatitude = closest.latitude;
          _destinationLongitude = closest.longitude;
          Logger.info(
            'Destination geocoded via OSM: $_destinationLatitude, $_destinationLongitude',
            tag: 'GPS',
          );
          return true;
        }
      } catch (e) {
        Logger.error('Silent geocode OSM: $e', tag: 'RIDE_FLOW', error: e);
      }
    }

    return false;
  }

  /// 🎯 NOUĂ METODĂ: Geocodare silențioasă pentru pickup
  Future<void> _silentlyGeocodePickup() async {
    if (_pickup == null || _pickup!.isEmpty) return;
    
    try {
      Logger.debug('Silently geocoding pickup: $_pickup', tag: 'GPS');
      final locations = await geocoding.locationFromAddress(_pickup!);
      if (locations.isNotEmpty) {
        _pickupLatitude = locations.first.latitude;
        _pickupLongitude = locations.first.longitude;
        Logger.info('Pickup geocoded to: $_pickupLatitude, $_pickupLongitude', tag: 'GPS');
      }
    } catch (e) {
      Logger.warning('Could not geocode pickup text: $e. Falling back to current location.', tag: 'GPS');
      await _getCurrentUserLocation();
    }
  }

  /// 🎯 Extrage opțiunea de cursă din text
  RideCategory? _extractRideOption(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('standard')) return RideCategory.standard;
    if (lowerText.contains('family')) return RideCategory.family;
    if (lowerText.contains('energy')) return RideCategory.energy;
    if (lowerText.contains('best')) return RideCategory.best;
    
    return null;
  }

  /// 🎯 NOUĂ METODĂ: Confirmarea finală a cursei
  Future<void> _startListeningForFinalRideConfirmation() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      _currentState = RideFlowState.awaitingFinalRideConfirmation;
      
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30,
      );
      
    } catch (e) {
      Logger.error('Final confirmation listening error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// 🎯 ÎMBUNĂTĂȚIT: Gestionează confirmarea finală și trimite la Firebase
  Future<void> _handleFinalRideConfirmation(GeminiVoiceResponse response) async {
    if (_isPositiveConfirmation(response.message ?? '')) {
      // ✅ OPREȘTE ASCULTAREA DEFINITIV
      await _voiceOrchestrator.stop();
      
      _currentState = RideFlowState.sendingToFirebase;
      
      // ✅ Folosește flow-ul centralizat pentru creare și navigare
      await _fillAddressAndNavigateToConfirmation();
      
    } else {
      // 🎯 USER NU CONFIRMĂ - ANULEAZĂ REZERVAREA
      await _cancelRideBooking();
    }
  }



  /// 🎯 NOUĂ METODĂ: Cere din nou destinația
  Future<void> _askForNewDestination() async {
    _currentState = RideFlowState.listeningForInitialCommand;
    
    const message = 'Înțeleg că nu confirmați. Vă rog să specificați din nou unde doriți să mergeți.';
    await _speakEmotion(message, VoiceEmotion.calm);
    
    // 🎯 PORNEȘTE ASCULTAREA PENTRU NOUA DESTINAȚIE
    await _startListeningForNewDestination();
  }

  /// 🎯 NOUĂ METODĂ: Ascultă pentru noua destinație
  Future<void> _startListeningForNewDestination() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      Logger.info('Listening for new destination...', tag: 'RIDE_FLOW');
      
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30,
      );
      
    } catch (e) {
      Logger.error('New destination listening error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  // (Metoda _sendRideRequestToFirebase a fost consolidată în _fillAddressAndNavigateToConfirmation)
  /// 🎯 Gestionează confirmarea driver-ului de către pasager (când AI întreabă dacă e ok cu șoferul găsit)
  Future<void> _handleDriverAcceptanceResponse(GeminiVoiceResponse response) async {
    await _voiceOrchestrator.stop();
    final driverId = _pendingDriverId ?? 'driver';

    if (_isPositiveConfirmation(response.message ?? '')) {
      _currentState = RideFlowState.rideAccepted;
      
      // ✅ Confirmă șoferul în Firestore când pasagerul confirmă
      if (_currentRideId != null && _currentRideId!.isNotEmpty) {
        try {
          await _firestoreService.passengerConfirmDriver(_currentRideId!);
          Logger.info('Passenger confirmed driver in Firestore for ride: $_currentRideId', tag: 'RIDE_FLOW');
        } catch (e) {
          Logger.error('Error confirming driver in Firestore: $e', tag: 'RIDE_FLOW', error: e);
        }
      }
      
      final message = await VoiceTranslations.getDriverNotified();
      await _speakEmotion(message, VoiceEmotion.happy);
      onDriverResponse(driverId, true);
    } else {
      _currentState = RideFlowState.driverRejected;
      const message = 'Înțeleg. Caut un alt șofer disponibil pentru dumneavoastră.';
      await _speakEmotion(message, VoiceEmotion.calm);
      if (_currentRideId != null && _currentRideId!.isNotEmpty) {
        try {
          await _firestoreService.passengerDeclineDriver(_currentRideId!);
          Logger.info('Passenger declined driver in Firestore for ride: $_currentRideId', tag: 'RIDE_FLOW');
        } catch (e) {
          Logger.error('Error declining driver in Firestore: $e', tag: 'RIDE_FLOW', error: e);
        }
      }
      onDriverResponse(driverId, false);
    }
  }



  /// 😕 Niciun șofer găsit
  Future<void> _handleNoDriverFound() async {
    try {
      final message = await VoiceTranslations.getNoDriversAvailable();
      _lastSpokenMessage = message;
      await _voiceOrchestrator.stopListening();
      await _speakEmotion(message, VoiceEmotion.calm);
      _currentState = RideFlowState.idle;
    } catch (e) {
      Logger.error('No driver found handling error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// 🔄 Resetează flow-ul pentru o nouă cursă
  void _resetRideFlow() {
    _destination = null;
    _pickup = null;
    _estimatedPrice = null;
    _availableDrivers.clear();
    _conversationHistory.clear();
    _currentState = RideFlowState.idle;
  }

  Future<void> _handleCloseAI() async {
    try {
      Logger.debug('Closing AI...', tag: 'RIDE_FLOW');

      _rideStatusSubscription?.cancel();
      _rideStatusSubscription = null;
      _driverResponseTimeout?.cancel();
      _driverResponseTimeout = null;
      _pendingDriverId = null;

      await _voiceOrchestrator.stop();

      _currentState = RideFlowState.idle;
      _destination = null;
      _pickup = null;
      _estimatedPrice = null;
      _availableDrivers = [];

      onCloseAI();

      Logger.info('AI closed successfully', tag: 'RIDE_FLOW');
    } catch (e) {
      Logger.error('Close AI error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }



  // --- Helper Methods ---

  /// Detalii șofer + poziție pentru ETA (aliniat la fluxul FriendsRide).
  Future<Map<String, dynamic>> _fetchDriverDetailsForVoice(String? driverId) async {
    if (driverId == null) {
      return {
        'name': 'Vecinul',
        'carModel': 'vehicul',
        'carColor': '',
        'licensePlate': '',
        'driverLat': null,
        'driverLng': null,
      };
    }
    try {
      final snap = await _firestoreService.getProfileByIdStream(driverId).first;
      final data = snap.data();
      if (data == null) {
        return {
          'name': 'Vecinul',
          'carModel': 'vehicul',
          'carColor': '',
          'licensePlate': '',
          'driverLat': null,
          'driverLng': null,
        };
      }
      final pos = data['position'];
      double? driverLat;
      double? driverLng;
      if (pos != null) {
        driverLat = (pos.latitude as num?)?.toDouble();
        driverLng = (pos.longitude as num?)?.toDouble();
      }
      return {
        'name': data['displayName'] ?? 'Vecinul',
        'carModel': data['carModel'] ?? data['vehicleModel'] ?? 'vehicul',
        'carColor': data['carColor'] ?? data['vehicleColor'] ?? '',
        'licensePlate': data['licensePlate'] ?? '',
        'driverLat': driverLat,
        'driverLng': driverLng,
      };
    } catch (e) {
      Logger.error('Error fetching driver details: $e', tag: 'RIDE_FLOW', error: e);
      return {
        'name': 'Vecinul',
        'carModel': 'vehicul',
        'carColor': '',
        'licensePlate': '',
        'driverLat': null,
        'driverLng': null,
      };
    }
  }

  int _etaMinutesPickupToDriver(double? driverLat, double? driverLng) {
    if (driverLat != null &&
        driverLng != null &&
        _pickupLatitude != null &&
        _pickupLongitude != null) {
      final distKm = _calculateHaversineDistance(
        _pickupLatitude!,
        _pickupLongitude!,
        driverLat,
        driverLng,
      );
      final minutes = (distKm / 25.0 * 60).round();
      return minutes.clamp(1, 60);
    }
    return 5;
  }

  Future<void> _startListeningForDriverAcceptance() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _currentState = RideFlowState.awaitingDriverAcceptance;
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30,
        pauseForSeconds: 4,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      Logger.error('Driver acceptance listening error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// ✅ Șofer atribuit: anunț vocal + întrebare de confirmare + ascultare (fără onDriverResponse înainte de „da”).
  Future<void> _handleDriverAccepted(Ride ride) async {
    try {
      _driverResponseTimeout?.cancel();
      _currentState = RideFlowState.driverFound;
      _pendingDriverId = ride.driverId;
      _currentRideId = ride.id;

      final details = await _fetchDriverDetailsForVoice(ride.driverId);
      final eta = _etaMinutesPickupToDriver(
        details['driverLat'] as double?,
        details['driverLng'] as double?,
      );
      final driverName = details['name'] as String? ?? 'Vecinul';
      final car = details['carModel'] as String? ?? 'vehicul';
      final carColor = details['carColor'] as String? ?? '';
      final plate = details['licensePlate'] as String? ?? '';

      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode);
      final driverMessage = await VoiceTranslations.getDriverAcceptedMessage(
        driverName,
        car,
        carColor,
        plate,
        eta,
      );
      final confirmQuestion = languageCode == 'en'
          ? '\n\nDo you want to continue with this driver?'
          : '\n\nConfirmați că doriți să continuați cu acest vecin?';
      final message = '$driverMessage$confirmQuestion';
      _lastSpokenMessage = message;
      await _speakEmotion(message, VoiceEmotion.happy);
      await _startListeningForDriverAcceptance();
    } catch (e) {
      Logger.error('Handle driver accepted error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// ✅ Gestionează când șoferul este pe drum
  Future<void> _handleDriverEnRoute(Ride ride) async {
    try {
      _currentState = RideFlowState.driverEnRoute;
      final message = await VoiceTranslations.getDriverEnRoute();
      await _speakEmotion(message, VoiceEmotion.calm);
    } catch (e) {
      Logger.error('Handle driver en route error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// ✅ Gestionează când șoferul a sosit la pickup
  Future<void> _handleDriverArrived(Ride ride) async {
    try {
      _currentState = RideFlowState.driverArrived;
      final message = await VoiceTranslations.getDriverArrived();
      await _speakEmotion(message, VoiceEmotion.happy);
    } catch (e) {
      Logger.error('Handle driver arrived error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// ✅ Gestionează când șoferul a refuzat sau anulat solicitarea
  Future<void> _handleDriverDeclined(Ride ride) async {
    try {
      _currentState = RideFlowState.searchingDrivers;
      const message = 'Șoferul nu a putut prelua cursa. Căutăm alt șofer disponibil pentru dumneavoastră.';
      await _speakEmotion(message, VoiceEmotion.calm);
    } catch (e) {
      Logger.error('Handle driver declined error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// ✅ Gestionează finalizarea cu succes a cursei
  Future<void> _handleRideCompleted(Ride ride) async {
    try {
      _currentState = RideFlowState.idle;
      final message = await VoiceTranslations.getRideCompleted();
      await _speakEmotion(message, VoiceEmotion.happy);
      _resetRideFlow();
      onCloseAI();
    } catch (e) {
      Logger.error('Handle ride completed error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// ✅ Monitorizează statusul cursei pentru a anunța vocal progresul
  void _monitorRideStatus(String rideId) {
    try {
      _rideStatusSubscription?.cancel();
      _rideStatusSubscription = _rideStreamOverride(rideId).listen((ride) async {
        await _handleRideStatusUpdate(ride);
      }, onError: (error) {
        Logger.error('Ride status stream error: $error', tag: 'RIDE_FLOW');
      });

      _driverResponseTimeout?.cancel();
      _driverResponseTimeout = Timer(const Duration(minutes: 5), () {
        if (_currentState == RideFlowState.waitingForDriverResponse ||
            _currentState == RideFlowState.driverFound ||
            _currentState == RideFlowState.awaitingDriverAcceptance) {
          unawaited(_handleNoDriverFound());
        }
      });
    } catch (e) {
      Logger.error('Monitoring error: $e', tag: 'RIDE_FLOW');
    }
  }

  /// ✅ Gestionează actualizările statusului pentru voce
  Future<void> _handleRideStatusUpdate(Ride ride) async {
    Logger.debug('Ride status for voice: ${ride.status}', tag: 'RIDE_FLOW');

    switch (ride.status) {
      case 'driver_found':
        if (_currentState != RideFlowState.driverFound &&
            _currentState != RideFlowState.awaitingDriverAcceptance &&
            _currentState != RideFlowState.driverEnRoute &&
            _currentState != RideFlowState.driverArrived &&
            _currentState != RideFlowState.rideAccepted) {
          await _handleDriverAccepted(ride);
        }
        break;
      case 'accepted':
      case 'driver_en_route':
      case 'in_progress':
        if (_currentState != RideFlowState.driverEnRoute &&
            _currentState != RideFlowState.driverArrived) {
          await _handleDriverEnRoute(ride);
        }
        break;
      case 'arrived':
      case 'driver_arrived':
        if (_currentState != RideFlowState.driverArrived) {
          await _handleDriverArrived(ride);
        }
        break;
      case 'ride_started':
        await _handleRideStarted(ride);
        break;
      case 'ride_completed':
      case 'completed':
        await _handleRideCompleted(ride);
        break;
      case 'driver_rejected':
      case 'driver_declined':
        await _handleDriverDeclined(ride);
        break;
      case 'cancelled':
      case 'expired':
        await _handleRideCancelled(ride);
        break;
    }
  }

  /// ✅ Mesaj pornire cursă
  Future<void> _handleRideStarted(Ride ride) async {
    try {
      _currentState = RideFlowState.driverEnRoute;
      final message = await VoiceTranslations.getRideStartedEnjoyTrip();
      await _speakEmotion(message, VoiceEmotion.happy);
    } catch (e) {
      Logger.error('Handle ride started error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// ✅ Mesaj anulare cursă
  Future<void> _handleRideCancelled(Ride ride) async {
    try {
      _currentState = RideFlowState.idle;
      const message = 'Cursa a fost anulată. Vă pot ajuta cu o nouă căutare?';
      await _speakEmotion(message, VoiceEmotion.calm);
      _resetRideFlow();
      _rideStatusSubscription?.cancel();
    } catch (e) {
      Logger.error('Handle ride cancelled error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }


  /// 📍 Obține locația curentă a utilizatorului
  /// 🎯 ACEASTĂ FUNCȚIE SE FOLOSEȘTE DOAR LA OBTINEREA LOCAȚIEI PENTRU FIREBASE
  /// 🚫 NU SE APEAZĂ AUTOMAT - DOAR CÂND SE CREEAZĂ SOLICITAREA
  /// 🌍 Obține locația curentă cu coordonate GPS reale
  Future<String> _getCurrentUserLocation() async {
    try {
      // ✅ Obține poziția GPS reală
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ),
      );
      
      // Salvează coordonatele pentru calcul distanță
      _pickupLatitude = position.latitude;
      _pickupLongitude = position.longitude;
      
      Logger.debug('Pickup coordinates: $_pickupLatitude, $_pickupLongitude', tag: 'GPS');
      
      // Convertește coordonatele în adresă
      final address = await geocoding_svc.GeocodingService().getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      return address ?? 'Locația curentă (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      
    } catch (e) {
      Logger.error('Error getting location: $e', tag: 'GPS', error: e);
      // Fallback la București centru
      _pickupLatitude = 44.4268;
      _pickupLongitude = 26.1025;
      return 'Locația curentă';
    }
  }

/// 🎯 NOU: Pornește automat ascultarea pentru confirmarea finală
  Future<void> _startListeningForFinalConfirmation() async {
    try {
      Logger.info('Preparing to start final confirmation listening...', tag: 'RIDE_FLOW');
      
      // ⚠️ VERIFICĂ DACĂ DEJA ASCULTĂ - NU PORNI DIN NOU!
      if (_voiceOrchestrator.isListening) {
        Logger.warning('Already listening - SKIPPING duplicate listen session', tag: 'RIDE_FLOW');
        return; // OPREȘTE AICI!
      }
      
      // 🎯 Oprește orice sesiune de speaking înainte
      if (_voiceOrchestrator.isSpeaking) {
        Logger.info('Stopping speaking before listening...', tag: 'RIDE_FLOW');
        await _voiceOrchestrator.stopSpeaking();
        // Așteaptă puțin după ce oprești speaking
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // 🎯 Delay mai scurt pentru că TTS deja s-a terminat înainte de acest apel
      await Future.delayed(const Duration(milliseconds: 800));
      
      // ⚠️ VERIFICĂ DIN NOU - poate altcineva a pornit listening între timp
      if (_voiceOrchestrator.isListening) {
        Logger.warning('Someone else started listening - SKIPPING', tag: 'RIDE_FLOW');
        return;
      }
      
      Logger.info('Starting final confirmation listening NOW (state: $_currentState)', tag: 'RIDE_FLOW');
      
      // ⚠️ VERIFICĂ STAREA ÎNAINTE DE A PORNI LISTENING
      if (_currentState != RideFlowState.awaitingRideConfirmation) {
        Logger.warning('Wrong state ($_currentState) - NOT starting listening', tag: 'RIDE_FLOW');
        return;
      }
      
      // Pornește automat ascultarea pentru confirmarea finală
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30, // Timp suficient pentru confirmare
      );
      
    } catch (e) {
      Logger.error('Auto-listen for final confirmation error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// 🎯 AUTONOM: Gestionează confirmarea destinației și procesează totul automat
  Future<void> _handleDestinationConfirmedResponse(GeminiVoiceResponse response) async {
    try {
      Logger.debug('AUTONOM: Handling destination confirmation: ${response.message}', tag: 'RIDE_FLOW');
      
      // Salvează destinația confirmată
      _destination = response.destination ?? 'Destinație necunoscută';
      _currentState = RideFlowState.destinationConfirmed;

      // ✅ Rezolvă alias-urile de adrese salvate ('Acasă', 'Serviciu')
      if (!await _resolveSavedAddressAlias()) return;

      // ✅ Ca la _handleDestinationResponse: pickup + geocodare destinație înainte de UI.
      // MapScreen transmite către RideRequestPanel.setDestination doar dacă există
      // destLat/destLng — fără geocodare, utilizatorul aude „am înțeles” dar panoul rămâne gol.
      if (_pickupLatitude == null || _pickupLongitude == null) {
        _pickup = await _getCurrentUserLocation();
      }
      if (_destinationLatitude == null || _destinationLongitude == null) {
        final geocoded = await _silentlyGeocodeDestination();
        if (!geocoded) {
          try {
            if (_destination != null && _destination!.isNotEmpty) {
              final pickup = _pickup ?? 'Locația curentă';
              onFillAddressInUI(
                pickup,
                _destination!,
                pickupLat: _pickupLatitude,
                pickupLng: _pickupLongitude,
                destLat: _destinationLatitude,
                destLng: _destinationLongitude,
              );
            }
          } catch (e) {
            Logger.error('UI update callback error: $e', tag: 'RIDE_FLOW', error: e);
          }
          await _promptDestinationLandmarkAndListen();
          return;
        }
      }

      // ✅ ACTUALIZEAZĂ UI-UL CU ADRESA ȘI COORDONATELE (dacă sunt disponibile)
      try {
        if (_destination != null && _destination!.isNotEmpty) {
          final pickup = _pickup ?? 'Locația curentă';
          onFillAddressInUI(
            pickup,
            _destination!,
            pickupLat: _pickupLatitude,
            pickupLng: _pickupLongitude,
            destLat: _destinationLatitude,
            destLng: _destinationLongitude,
          );
          Logger.info('UI updated with destination: $_destination', tag: 'RIDE_FLOW');
          if (_destinationLatitude != null && _destinationLongitude != null) {
            Logger.info('Coordinates also sent: $_destinationLatitude, $_destinationLongitude', tag: 'RIDE_FLOW');
          }
        }
      } catch (e) {
        Logger.error('UI update callback error: $e', tag: 'RIDE_FLOW', error: e);
      }
      
      // 🗣️ Anunță că procesează totul automat
      // ✅ NOU: Folosește traducere
      final confirmMessage = await VoiceTranslations.getDestinationUnderstood();
      _lastSpokenMessage = confirmMessage;
      await _speakEmotion(confirmMessage, VoiceEmotion.confident);
      
      // 🎯 AUTONOM: Procesează totul automat
      await _processRideRequestAutonomously();
      
    } catch (e) {
      Logger.error('Destination confirmation error: $e', tag: 'RIDE_FLOW', error: e);
      await _handleError('Eroare la confirmarea destinației: $e');
    }
  }

  /// 🎯 AUTONOM: Procesează complet cererea de cursă automat
  Future<void> _processRideRequestAutonomously() async {
    try {
      Logger.debug('AUTONOM: Starting autonomous ride processing...', tag: 'RIDE_FLOW');
      
      // Pasul 1: Detectează locația curentă automat
      final locationPipelineOk = await _detectCurrentLocationAutonomously();
      if (!locationPipelineOk) {
        Logger.info(
          'AUTONOM: Oprit după clarificare destinație / selecție adresă — nu se caută șoferi încă.',
          tag: 'RIDE_FLOW',
        );
        return;
      }

      // Pasul 2: Caută șoferi automat (fără calcul preț — cursele sunt gratuite)
      await _searchDriversAutonomously();
      
      // Pasul 4: Selectează cel mai bun șofer automat
      await _selectBestDriverAutonomously();
      
      // Pasul 5: Confirmă automat și trimite cererea
      await _confirmAndSendRequestAutonomously();
      
      Logger.info('AUTONOM: Ride processing completed successfully', tag: 'RIDE_FLOW');
      
    } catch (e) {
      Logger.error('Autonomous processing error: $e', tag: 'RIDE_FLOW', error: e);
      await _handleError('Eroare la procesarea automată a cursei: $e');
    }
  }

  /// 🎯 AUTONOM: Detectează locația curentă automat. [false] = clarificare reper sau selecție adresă (nu continua căutarea).
  Future<bool> _detectCurrentLocationAutonomously() async {
    try {
      Logger.debug('AUTONOM: Detecting current location...', tag: 'RIDE_FLOW');
      
      // ✅ FIX: Anunță utilizatorul că detectează locația (înainte de a face lucrul în background)
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode);
      final detectingMessage = await VoiceTranslations.getDetectingCurrentLocation();
      await _speakEmotion(detectingMessage, VoiceEmotion.calm);
      
      // ✅ Obține GPS real și adresa
      final currentLocation = await _getCurrentUserLocation();
      _pickup = currentLocation;
      
      Logger.debug('AUTONOM: Current location detected: $_pickup', tag: 'RIDE_FLOW');
      
      // ✅ Obține coordonatele destinației prin geocoding ÎMBUNĂTĂȚIT
      if (_destination != null && _destination!.isNotEmpty) {
        Logger.debug('AUTONOM: Geocoding destination: $_destination', tag: 'RIDE_FLOW');
        
      // ✅ FIX: Anunță utilizatorul că verifică adresa destinației (înainte de a face lucrul în background)
      final langCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(langCode);
      final verifyingMessage = await VoiceTranslations.getVerifyingDestination();
      await _speakEmotion(verifyingMessage, VoiceEmotion.calm);
        
        // ✅ FIX: Verifică mai întâi destinațiile predefinite (rapid, fără API calls)
        final predefinedCoords = _getPredefinedDestinationCoordinates(_destination!);
        if (predefinedCoords != null) {
          _destinationLatitude = predefinedCoords['latitude'];
          _destinationLongitude = predefinedCoords['longitude'];
          Logger.info('Destination found in predefined list: $_destinationLatitude, $_destinationLongitude', tag: 'GPS');
          Logger.debug('Address: ${predefinedCoords['name']}', tag: 'GPS');
          
          // Calculează distanța pentru feedback
          if (_pickupLatitude != null && _pickupLongitude != null) {
            final distanceKm = _calculateHaversineDistance(
              _pickupLatitude!,
              _pickupLongitude!,
              _destinationLatitude!,
              _destinationLongitude!,
            );
            Logger.debug('Distance to destination: ${distanceKm.toStringAsFixed(2)} km', tag: 'GPS');
          }
        } else {
          // ✅ FIX: Folosește același serviciu ca AddressInputView (GeocodingService cu OSM Nominatim)
          // Acesta este serviciul care funcționează bine pentru autocomplete-ul adreselor
          // Folosește poziția curentă pentru context în geocoding
          final currentPos = geolocator.Position(
            latitude: _pickupLatitude!,
            longitude: _pickupLongitude!,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          
          // ✅ PRIORITATE 1: GeocodingService (OSM Nominatim) - același serviciu ca AddressInputView
          List<geocoding_svc.AddressSuggestion> suggestions = [];
          
          // Încercare 1: Query original cu GeocodingService
          Logger.info('Using GeocodingService (OSM Nominatim) - same as AddressInputView', tag: 'GPS');
          suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
            _destination!,
            currentPos,
          );
          
          // Încercare 2: Re-încearcă fără a forța țara.
          if (suggestions.isEmpty) {
            Logger.warning('Retry 1: repeat neutral query', tag: 'GPS');
            suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
              _destination!,
              currentPos,
            );
          }
          
          if (suggestions.isNotEmpty) {
            // 🎯 Sortează după distanță
            suggestions.sort((a, b) {
              final distA = a.distanceMeters ?? double.infinity;
              final distB = b.distanceMeters ?? double.infinity;
              return distA.compareTo(distB);
            });

            // 🗺️ Dacă sunt mai multe adrese semnificativ diferite, cere selecție
            final hasAmbiguity = suggestions.length >= 2 &&
                (suggestions[0].distanceMeters == null ||
                    suggestions[1].distanceMeters == null ||
                    ((suggestions[1].distanceMeters ?? 0) -
                            (suggestions[0].distanceMeters ?? 0)) >
                        300) &&
                suggestions[0].description != suggestions[1].description;

            if (hasAmbiguity) {
              Logger.info(
                  'Multiple different addresses found (${suggestions.length}), asking user to choose',
                  tag: 'GPS');
              await _askForAddressDisambiguation(suggestions);
              return false; // Fluxul continuă după selecția utilizatorului
            }

            final closest = suggestions.first;
            _destinationLatitude = closest.latitude;
            _destinationLongitude = closest.longitude;

            final distanceKm = (closest.distanceMeters ?? 0) / 1000;
            Logger.info('Destination found via GeocodingService (OSM Nominatim): $_destinationLatitude, $_destinationLongitude', tag: 'GPS');
            Logger.debug('Distance to destination: ${distanceKm.toStringAsFixed(2)} km', tag: 'GPS');
            Logger.debug('Address: ${closest.description}', tag: 'GPS');
          } else {
            // ✅ PRIORITATE 2: Dacă GeocodingService eșuează, încearcă locationFromAddress (serviciul nativ)
            Logger.error('GeocodingService failed, trying locationFromAddress (native service)...', tag: 'GPS');
            try {
              List<geocoding.Location> locations = await geocoding.locationFromAddress(_destination!);
              if (locations.isNotEmpty) {
                _destinationLatitude = locations.first.latitude;
                _destinationLongitude = locations.first.longitude;
                Logger.info('Destination found via locationFromAddress: $_destinationLatitude, $_destinationLongitude', tag: 'GPS');
                
                // Calculează distanța pentru feedback
                if (_pickupLatitude != null && _pickupLongitude != null) {
                  final distanceKm = _calculateHaversineDistance(
                    _pickupLatitude!,
                    _pickupLongitude!,
                    _destinationLatitude!,
                    _destinationLongitude!,
                  );
                  Logger.debug('Distance to destination: ${distanceKm.toStringAsFixed(2)} km', tag: 'GPS');
                }
              } else {
                // ✅ PRIORITATE 3: Dacă locationFromAddress eșuează, repetăm query-ul neutru.
                Logger.error('locationFromAddress failed, retrying neutral query...', tag: 'GPS');
                locations = await geocoding.locationFromAddress(_destination!);
                if (locations.isNotEmpty) {
                  _destinationLatitude = locations.first.latitude;
                  _destinationLongitude = locations.first.longitude;
                  Logger.info('Destination found via locationFromAddress retry: $_destinationLatitude, $_destinationLongitude', tag: 'GPS');
                } else {
                  // ✅ PRIORITATE 4: Dacă tot eșuează, încearcă Gemini AI
                  Logger.error('locationFromAddress failed, trying Gemini AI for address clarification and coordinates...', tag: 'GPS');
                  
                  try {
                    final geminiResult = await _askGeminiForClarifiedAddress(_destination!);
                    
                    if (geminiResult != null && geminiResult['address'] != null) {
                      final clarifiedAddress = geminiResult['address'] as String;
                      final geminiLatitude = geminiResult['latitude'] as double?;
                      final geminiLongitude = geminiResult['longitude'] as double?;
                      
                      Logger.info('Gemini AI suggested clearer address: $clarifiedAddress', tag: 'GPS');
                      
                      // ✅ PRIORITATE 1: Dacă Gemini AI a oferit coordonate directe, folosește-le!
                      if (geminiLatitude != null && geminiLongitude != null) {
                        _destinationLatitude = geminiLatitude;
                        _destinationLongitude = geminiLongitude;
                        _destination = clarifiedAddress;
                        
                        // Calculează distanța pentru feedback
                        if (_pickupLatitude != null && _pickupLongitude != null) {
                          final distanceKm = _calculateHaversineDistance(
                            _pickupLatitude!,
                            _pickupLongitude!,
                            _destinationLatitude!,
                            _destinationLongitude!,
                          );
                          Logger.info('Destination found with Gemini AI coordinates: $_destinationLatitude, $_destinationLongitude', tag: 'GPS');
                          Logger.debug('Distance to destination: ${distanceKm.toStringAsFixed(2)} km', tag: 'GPS');
                          Logger.debug('Address: $clarifiedAddress', tag: 'GPS');
                        } else {
                          Logger.info('Destination coordinates from Gemini AI: $_destinationLatitude, $_destinationLongitude', tag: 'GPS');
                          Logger.debug('Address: $clarifiedAddress', tag: 'GPS');
                        }
                      } else {
                        // ✅ PRIORITATE 2: Dacă Gemini AI nu a oferit coordonate, reîncearcă geocoding-ul cu adresa clarificată
                        Logger.warning('Gemini AI did not provide coordinates, retrying geocoding with clarified address...', tag: 'GPS');
                        
                        // Reîncearcă geocoding-ul cu adresa clarificată de Gemini
                        suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
                          clarifiedAddress,
                          currentPos,
                        );
                        
                        if (suggestions.isEmpty) {
                          suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
                            clarifiedAddress,
                            currentPos,
                          );
                        }
                        
                        if (suggestions.isNotEmpty) {
                          // Sortează după distanță și ia cea mai apropiată
                          suggestions.sort((a, b) {
                            final distA = a.distanceMeters ?? double.infinity;
                            final distB = b.distanceMeters ?? double.infinity;
                            return distA.compareTo(distB);
                          });
                          
                          final closest = suggestions.first;
                          _destinationLatitude = closest.latitude;
                          _destinationLongitude = closest.longitude;
                          
                          // Actualizează destinația cu adresa clarificată
                          _destination = closest.description;
                          
                          final distanceKm = (closest.distanceMeters ?? 0) / 1000;
                          Logger.info('Destination found with Gemini AI help (geocoding): $_destinationLatitude, $_destinationLongitude', tag: 'GPS');
                          Logger.debug('Distance to destination: ${distanceKm.toStringAsFixed(2)} km', tag: 'GPS');
                          Logger.debug('Address: ${closest.description}', tag: 'GPS');
                        } else {
                          Logger.error('ERROR: Could not geocode destination even with Gemini AI help!', tag: 'GPS');
                          await _promptDestinationLandmarkAndListen();
                          return false;
                        }
                      }
                    } else {
                      Logger.error('ERROR: Could not geocode destination after all retries!', tag: 'GPS');
                      await _promptDestinationLandmarkAndListen();
                      return false;
                    }
                  } catch (geminiError) {
                    Logger.error('Error asking Gemini AI for clarification: $geminiError', tag: 'GPS');
                    await _promptDestinationLandmarkAndListen();
                    return false;
                  }
                }
              }
            } catch (e) {
              Logger.error('Error in locationFromAddress: $e', tag: 'GPS', error: e);
              // Dacă locationFromAddress eșuează, încearcă Gemini AI
              Logger.error('locationFromAddress error, trying Gemini AI...', tag: 'GPS');
              try {
                final geminiResult = await _askGeminiForClarifiedAddress(_destination!);
                if (geminiResult != null && geminiResult['address'] != null) {
                  final clarifiedAddress = geminiResult['address'] as String;
                  final geminiLatitude = geminiResult['latitude'] as double?;
                  final geminiLongitude = geminiResult['longitude'] as double?;
                  
                  if (geminiLatitude != null && geminiLongitude != null) {
                    _destinationLatitude = geminiLatitude;
                    _destinationLongitude = geminiLongitude;
                    _destination = clarifiedAddress;
                    Logger.info('Destination found with Gemini AI coordinates: $_destinationLatitude, $_destinationLongitude', tag: 'GPS');
                  } else {
                    Logger.error('ERROR: Could not geocode destination after all retries!', tag: 'GPS');
                    await _promptDestinationLandmarkAndListen();
                    return false;
                  }
                } else {
                  Logger.error('ERROR: Could not geocode destination after all retries!', tag: 'GPS');
                  await _promptDestinationLandmarkAndListen();
                  return false;
                }
              } catch (geminiError) {
                Logger.error('Error asking Gemini AI: $geminiError', tag: 'GPS');
                await _promptDestinationLandmarkAndListen();
                return false;
              }
            }
          }
        }
      }
      
      // ✅ NU mai anunță coordonatele - doar confirmă locația
      // Anunțurile sunt simplificate mai jos

      return true;
    } catch (e) {
      Logger.error('Location detection error: $e', tag: 'RIDE_FLOW', error: e);
      // Folosește o locație default
      _pickup = 'Locația curentă detectată automat';
      _pickupLatitude = 44.4268;
      _pickupLongitude = 26.1025;
      return true;
    }
  }

  /// 🎯 AUTONOM: Calculează prețul automat
  /// 🎯 AUTONOM: Caută șoferi automat
  Future<void> _searchDriversAutonomously() async {
    try {
      Logger.debug('AUTONOM: Searching for drivers...', tag: 'RIDE_FLOW');
      
      // Anunță că caută șoferi
      // ✅ NOU: Folosește traducere
      final message = await VoiceTranslations.getSearchingDriversInArea();
      _lastSpokenMessage = message;
      await _speakEmotion(message, VoiceEmotion.confident);
      
      // ✅ FIX: Folosește căutarea REALĂ de șoferi (nu simulare)
      if (_pickupLatitude == null || _pickupLongitude == null) {
        await _getCurrentUserLocation();
      }

      if (_pickupLatitude == null || _pickupLongitude == null) {
        throw Exception('Locația de preluare nu este disponibilă.');
      }

      final pickupPoint = Point(
        coordinates: Position(_pickupLongitude!, _pickupLatitude!),
      );

      // ✅ FIX: Caută șoferi reali disponibili folosind FirestoreService
      final etaResult = await _firestoreService.getNearestDriverEta(
        pickupPoint,
        _currentRideCategory,
      );

      // ✅ FIX: Verifică dacă există șoferi disponibili
      if (etaResult == null) {
        Logger.error('AUTONOM:  Nu sunt șoferi disponibili', tag: 'RIDE_FLOW');
        _availableDrivers = [];
        await _handleNoDriverFound();
        return;
      }

      // ✅ FIX: Salvează informațiile despre șoferul găsit
      _availableDrivers = [
        'Șofer ${etaResult.driverId} - ${etaResult.durationInMinutes} min',
      ];
      _pendingDriverId = etaResult.driverId;
      
      Logger.info('AUTONOM:  Found driver: ${etaResult.driverId} (ETA: ${etaResult.durationInMinutes} min, Distance: ${etaResult.distanceInKm.toStringAsFixed(1)} km)', tag: 'RIDE_FLOW');
      
      // Anunță rezultatul
      // ✅ NOU: Folosește traducere
      final foundMessage = await VoiceTranslations.getDriverFound(etaResult.durationInMinutes);
      _lastSpokenMessage = foundMessage;
      await _speakEmotion(foundMessage, VoiceEmotion.confident);
      
    } catch (e) {
      Logger.error('AUTONOM:  Driver search error: $e', tag: 'RIDE_FLOW', error: e);
      _availableDrivers = [];
      await _handleNoDriverFound();
    }
  }

  /// 🎯 AUTONOM: Selectează cel mai bun șofer automat
  Future<void> _selectBestDriverAutonomously() async {
    try {
      Logger.debug('AUTONOM: Selecting best driver...', tag: 'RIDE_FLOW');
      
      if (_availableDrivers.isEmpty) {
        await _handleNoDriverFound();
        return;
      }
      
      // Selectează primul șofer (în aplicația reală ar folosi algoritmi de matching)
      final selectedDriver = _availableDrivers.first;
      
      Logger.debug('AUTONOM: Selected driver: $selectedDriver', tag: 'RIDE_FLOW');
      
      // Anunță utilizatorul
      const message = 'Am selectat cel mai bun șofer pentru dumneavoastră.';
      _lastSpokenMessage = message;
      await _speakEmotion(message, VoiceEmotion.confident);
      
    } catch (e) {
      Logger.error('Driver selection error: $e', tag: 'RIDE_FLOW', error: e);
      rethrow;
    }
  }

  /// 🎯 AUTONOM: Confirmă și trimite cererea automat
  Future<void> _confirmAndSendRequestAutonomously() async {
    try {
      Logger.debug('AUTONOM: Confirming and sending request...', tag: 'RIDE_FLOW');
      
      // Anunță că trimite cererea
      const message = 'Trimit cererea către șofer...';
      _lastSpokenMessage = message;
      await _speakEmotion(message, VoiceEmotion.confident);
      
      // Creează și trimite cererea
      final rideRequest = await _createCompleteRideRequest();
      final rideId = await onCreateRideRequest(rideRequest);
      
      // ✅ NOU: Salvează rideId pentru confirmarea ulterioară a șoferului
      _currentRideId = rideId;

      _monitorRideStatus(rideId);
      
      // Simulează răspunsul șoferului
      await Future.delayed(const Duration(seconds: 3));
      
      // Anunță rezultatul final
      await _announceFinalResult();
      
      // Navighează la ecranul de căutare (revine pe hartă după acceptare)
      final searchingScreen = SearchingForDriverScreen(rideId: rideId);
      onNavigateToScreen(searchingScreen);
      
      Logger.debug('AUTONOM: Request sent successfully, ride ID: $rideId', tag: 'RIDE_FLOW');
      
    } catch (e) {
      Logger.error('Request confirmation error: $e', tag: 'RIDE_FLOW', error: e);
      rethrow;
    }
  }

  /// 🎯 AUTONOM: Anunță rezultatul final utilizatorului
  Future<void> _announceFinalResult() async {
    try {
      // ✅ CORECTAT: Nu anunță rezultatul dacă nu există șoferi disponibili
      if (_availableDrivers.isEmpty) {
        Logger.debug('AUTONOM: Nu sunt șoferi disponibili, omițând anunțul final', tag: 'RIDE_FLOW');
        await _handleNoDriverFound();
        return;
      }
      
      // Obține datele reale ale șoferului (dacă există)
      final selectedDriver = _availableDrivers.isNotEmpty ? _availableDrivers.first : null;
      final driverName = selectedDriver != null ? 'Șoferul' : 'Un șofer';
      const etaMinutes = 5; // Va fi actualizat cu date reale când sunt disponibile

      // ✅ NOU: Folosește traducere
      final message = await VoiceTranslations.getEverythingResolved(driverName, etaMinutes);

      _lastSpokenMessage = message;
      await _speakEmotion(message, VoiceEmotion.confident);

      Logger.debug('AUTONOM: Final result announced - Driver: $driverName, ETA: $etaMinutes min', tag: 'RIDE_FLOW');
      
    } catch (e) {
      Logger.error('Final announcement error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }
  
  /// 🎯 Obține locația GPS curentă și confirmă pickup-ul
  /// DEPRECATED: Această metodă nu mai este folosită în fluxul autonom
  // ignore: unused_element
  Future<void> _getCurrentLocationAndConfirm() async {
    try {
      Logger.debug('Getting current GPS location...', tag: 'RIDE_FLOW');
      
      // Simulează obținerea locației GPS (în aplicația reală ar folosi Geolocator)
      // Pentru demo, folosim o locație fixă
      const currentLocation = 'Piața Unirii, București';
      _pickup = currentLocation;
      
      // Așteaptă puțin pentru efectul de "detectare"
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // 🗣️ Confirmă locația detectată și cere confirmarea
      const confirmMessage = 'Vă detectez la $currentLocation. Preluarea se face de la această locație?';
      _lastSpokenMessage = confirmMessage;
      await _speakEmotion(confirmMessage, VoiceEmotion.confident);
      
      // Actualizează starea pentru confirmarea pickup-ului
      _currentState = RideFlowState.awaitingConfirmation;
      
      // Pornește ascultarea pentru confirmarea pickup-ului
      await _startListeningForPickupConfirmation();
      
    } catch (e) {
      Logger.error('GPS location error: $e', tag: 'RIDE_FLOW', error: e);
      await _handleError('Eroare la detectarea locației: $e');
    }
  }
  
  /// 🎯 Pornește ascultarea pentru confirmarea pickup-ului
  Future<void> _startListeningForPickupConfirmation() async {
    try {
      // Așteaptă puțin să se termine TTS-ul complet
      await Future.delayed(const Duration(milliseconds: 1500));
      
      Logger.info('Auto-starting pickup confirmation listening...', tag: 'RIDE_FLOW');
      
      // Pornește automat ascultarea pentru confirmarea pickup-ului
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30, // Timp suficient pentru confirmare
        pauseForSeconds: 10,
      );
      
    } catch (e) {
      Logger.error('Auto-listen for pickup confirmation error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }

  /// 🛑 Oprește procesarea
  Future<void> stop() async {
    try {
      Logger.debug('Stopping...', tag: 'RIDE_FLOW');
      await _voiceOrchestrator.stopSpeaking();
      _currentState = RideFlowState.idle;
      Logger.info('Stopped successfully', tag: 'RIDE_FLOW');
    } catch (e) {
      Logger.error('Stop error: $e', tag: 'RIDE_FLOW', error: e);
    }
  }
  
  /// 🧹 Cleanup - MEMORY LEAK PREVENTION
  void dispose() {
    // ✅ Cancel all subscriptions
    _rideStatusSubscription?.cancel();
    _rideStatusSubscription = null;
    
    // ✅ Cancel all timers
    _driverResponseTimeout?.cancel();
    _driverResponseTimeout = null;
    
    // ✅ Stop voice orchestrator
    try {
      _voiceOrchestrator.stop();
    } catch (e) {
      Logger.error('Error stopping voice orchestrator: $e', tag: 'RIDE_FLOW', error: e);
    }
    
    // ✅ Dispose TTS
    try {
      _tts.dispose();
    } catch (e) {
      Logger.error('Error disposing TTS: $e', tag: 'RIDE_FLOW', error: e);
    }
    
    // ✅ Dispose beep service
    try {
      _beepService.dispose();
    } catch (e) {
      Logger.error('Error disposing beep service: $e', tag: 'RIDE_FLOW', error: e);
    }
    
    // ✅ Clear conversation history to free memory
    _conversationHistory.clear();
    _availableDrivers.clear();
    
    // ✅ Reset state
    _currentState = RideFlowState.idle;
    _destination = null;
    _pickup = null;
    _estimatedPrice = null;
    _pendingDriverId = null;
    _lastSpokenMessage = '';
    _calculatedDistanceKm = null;
    _calculatedDurationMinutes = null;
    _fareBreakdown = null;
    _pickupLatitude = null;
    _pickupLongitude = null;
    _destinationLatitude = null;
    _destinationLongitude = null;
    
    Logger.info('Dispose completed - all resources cleaned up', tag: 'RIDE_FLOW');
  }

  /// 🎯 NOU: Gestionează acțiunile aplicației cerute de AI
  Future<void> _handleAppAction(GeminiVoiceResponse response) async {
    Logger.info('Handling App Action: ${response.appAction} for screen: ${response.appScreen}', tag: 'RIDE_FLOW');
    
    // Feedback vocal
    if (response.message != null) {
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode);
      await _speakEmotion(response.message!, VoiceEmotion.happy);
    }
    
    // ✅ NOU: Acțiuni speciale care necesită logică imediată
    if (response.appAction == 'get_speed') {
      final speed = await getSpeed();
      final languageCode = await _getCurrentLanguageCode();
      final msg = languageCode == 'ro' 
          ? 'În acest moment ne deplasăm cu aproximativ ${speed.toInt()} kilometri pe oră.' 
          : 'We are currently traveling at approximately ${speed.toInt()} kilometers per hour.';
      await _speakEmotion(msg, VoiceEmotion.confident);
      return;
    }

    // Execută acțiunea în UI prin callback
    if (response.appAction != null) {
      onAppAction(response.appAction!, response.appScreen, response.params);
    } else {
      // Fallback la navigare de bază dacă nu avem callback specific
      _handleNavigationOnly(response.appScreen);
    }
  }
  
  void _handleNavigationOnly(String? screen) {
    if (screen == null) return;
    
    Widget? screenWidget;
    switch (screen) {
      case 'help': screenWidget = const HelpScreen(); break;
      case 'profile': screenWidget = const AccountScreen(); break;
      case 'settings': screenWidget = const SettingsScreen(); break;
      case 'history': screenWidget = const HistoryScreen(); break;
      case 'activity': screenWidget = const DriverDashboardScreen(); break;
      case 'wallet': screenWidget = const TokenShopScreen(); break;
    }
    
    if (screenWidget != null) {
      onNavigateToScreen(screenWidget);
    }
  }

  /// 🎯 NOU: Gestionează răspunsurile de ajutor
  Future<void> _handleHelpResponse(GeminiVoiceResponse response) async {
    Logger.info('Handling Help Response', tag: 'RIDE_FLOW');
    
    if (response.message != null) {
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode);
      await _speakEmotion(response.message!, VoiceEmotion.friendly);
    }
    
    if (response.needsClarification) {
      await _startListeningForClarification();
    }
  }

  RideCategory _parseRideCategory(String type) {
    switch (type.toLowerCase()) {
      case 'premium': return RideCategory.best;
      case 'xl': return RideCategory.family;
      default: return RideCategory.standard;
    }
  }

  Future<double> getSpeed() async {
    try {
      final pos = await geolocator.Geolocator.getCurrentPosition();
      return (pos.speed < 0 ? 0 : pos.speed) * 3.6; // Convert m/s to km/h
    } catch (e) {
      return 0.0;
    }
  }
}
