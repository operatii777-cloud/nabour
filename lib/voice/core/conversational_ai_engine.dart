import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'voice_analytics.dart';

import '../nlp/ride_intent_processor.dart';

/// Advanced Conversational AI Engine for Nabour
/// Handles natural conversations, context management, and personality
class ConversationalAIEngine {
  static final ConversationalAIEngine _instance = ConversationalAIEngine._internal();
  factory ConversationalAIEngine() => _instance;
  ConversationalAIEngine._internal();

  // Core components
  late RideIntentProcessor _intentProcessor;
  late ConversationContext _currentContext;
  late UserPersonality _userPersonality;
  
  // Conversation state
  ConversationState _conversationState = ConversationState.idle;
  final List<ConversationTurn> _conversationHistory = [];
  final Map<String, dynamic> _sessionMemory = {};
  
  // Memory management constants - IMPLEMENTARE PREVENIRE MEMORY LEAK
  static const int _maxConversationHistory = 50;
  static const int _maxContextStack = 20;
  static const int _maxSessionMemory = 100;
  static const Duration _maxHistoryAge = Duration(hours: 12);
  
  // AI personality and tone
  late AIPersonality _aiPersonality;
  late ToneManager _toneManager;
  
  // Context management
  final Map<String, ConversationContext> _contextStack = {};
  final Map<String, List<String>> _userPreferences = {};
  
  // Performance tracking
  final Map<String, PerformanceMetric> _performanceMetrics = {};
  
  // Timer management for memory leak prevention
  Timer? _cleanupTimer;
  
  /// Initialize the conversational AI engine
  Future<void> initialize() async {
    try {
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'conversational_ai_initialization_started'});
      
      // Initialize core components
      _intentProcessor = RideIntentProcessor();
      _currentContext = ConversationContext();
      _userPersonality = UserPersonality();
      
      // Initialize AI personality
      _aiPersonality = AIPersonality();
      _toneManager = ToneManager();
      
      // Load user preferences and context
      await _loadUserPreferences();
      await _loadConversationHistory();
      
      // Initialize performance monitoring
      _initializePerformanceMonitoring();
      
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'conversational_ai_initialization_completed'});
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'conversational_ai_initialization_failed',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }



  /// Process user input and generate contextual response
  Future<ConversationResponse> processUserInput(
    String userInput, {
    UserContext? userContext,
    ConversationMode mode = ConversationMode.normal,
  }) async {
    try {
      VoiceAnalytics().startPerformanceTimer('user_input_processing');
      
      // Update conversation state
      _conversationState = ConversationState.processing;
      
      // Analyze user input
      final inputAnalysis = await _analyzeUserInput(userInput, userContext);
      
      // Update context
      _updateConversationContext(inputAnalysis, userContext);
      
      // Generate response based on context and personality
      final response = await _generateContextualResponse(inputAnalysis, mode);
      
      // Update conversation history
      _addToConversationHistory(userInput, response);
      
      // Update conversation state
      _conversationState = ConversationState.waitingForUser;
      
      VoiceAnalytics().endPerformanceTimer('user_input_processing');
      VoiceAnalytics().trackEvent(VoiceEventType.userInteraction, data: {'operation': 'user_input_processed_successfully'});
      
      return response;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'user_input_processing_failed',
        errorMessage: e.toString(),
      );
      _conversationState = ConversationState.error;
      return _generateFallbackResponse(userInput);
    }
  }

  /// Analyze user input for intent, entities, and sentiment
  Future<UserInputAnalysis> _analyzeUserInput(
    String userInput, 
    UserContext? userContext,
  ) async {
    try {
      // Intent recognition
      final intent = await _intentProcessor.extractIntent(userInput);
      
      // Entity extraction
      final entities = await _extractEntities(userInput);
      
      // Sentiment analysis
      final sentiment = await _analyzeSentiment(userInput);
      
      // Context relevance
      final contextRelevance = _calculateContextRelevance(userInput);
      
      return UserInputAnalysis(
        originalInput: userInput,
        intent: intent,
        entities: entities,
        sentiment: sentiment,
        contextRelevance: contextRelevance,
        userContext: userContext,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'input_analysis_failed',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Extract entities from user input
  Future<List<Entity>> _extractEntities(String userInput) async {
    final entities = <Entity>[];
    
    // Location entities
    final locationPatterns = [
      RegExp(r'\b(la|spre|către|din|de la)\s+([A-Za-zăâîșțĂÂÎȘȚ\s]+)\b'),
      RegExp(r'\b(mall|centru|aeroport|gara|spital|universitate|birou|acasă)\b'),
    ];
    
    for (final pattern in locationPatterns) {
      final matches = pattern.allMatches(userInput);
      for (final match in matches) {
        entities.add(Entity(
          type: EntityType.location,
          value: match.group(2) ?? match.group(0) ?? '',
          confidence: 0.9,
          startIndex: match.start,
          endIndex: match.end,
        ));
      }
    }
    
    // Time entities
    final timePatterns = [
      RegExp(r'\b(acum|imediat|mâine|azi|dimineața|seara|la\s+\d{1,2}[:\.]\d{2})\b'),
      RegExp(r'\b(în\s+\d+\s+minute|peste\s+\d+\s+ore)\b'),
    ];
    
    for (final pattern in timePatterns) {
      final matches = pattern.allMatches(userInput);
      for (final match in matches) {
        entities.add(Entity(
          type: EntityType.time,
          value: match.group(0) ?? '',
          confidence: 0.8,
          startIndex: match.start,
          endIndex: match.end,
        ));
      }
    }
    
    // Preference entities
    final preferencePatterns = [
      RegExp(r'\b(mașină\s+mare|mașină\s+curată|șofer\s+prietenos|preț\s+mic|viteză)\b'),
    ];
    
    for (final pattern in preferencePatterns) {
      final matches = pattern.allMatches(userInput);
      for (final match in matches) {
        entities.add(Entity(
          type: EntityType.preference,
          value: match.group(0) ?? '',
          confidence: 0.7,
          startIndex: match.start,
          endIndex: match.end,
        ));
      }
    }
    
    return entities;
  }

  /// Analyze sentiment of user input
  Future<SentimentAnalysis> _analyzeSentiment(String userInput) async {
    // Simple sentiment analysis based on keywords
    final positiveWords = [
      'mulțumesc', 'super', 'excelent', 'perfect', 'bun', 'frumos', 'plăcut'
    ];
    final negativeWords = [
      'prost', 'rău', 'teribil', 'enervant', 'frustrant', 'dezamăgit'
    ];
    final urgentWords = [
      'urgent', 'imediat', 'acum', 'rapid', 'grabă', 'important'
    ];
    
    final lowerInput = userInput.toLowerCase();
    int positiveScore = 0;
    int negativeScore = 0;
    int urgencyScore = 0;
    
    for (final word in positiveWords) {
      if (lowerInput.contains(word)) positiveScore++;
    }
    
    for (final word in negativeWords) {
      if (lowerInput.contains(word)) negativeScore++;
    }
    
    for (final word in urgentWords) {
      if (lowerInput.contains(word)) urgencyScore++;
    }
    
    SentimentType sentimentType;
    if (positiveScore > negativeScore) {
      sentimentType = SentimentType.positive;
    } else if (negativeScore > positiveScore) {
      sentimentType = SentimentType.negative;
    } else {
      sentimentType = SentimentType.neutral;
    }
    
    return SentimentAnalysis(
      type: sentimentType,
      confidence: 0.8,
      positiveScore: positiveScore,
      negativeScore: negativeScore,
      urgencyScore: urgencyScore,
    );
  }

  /// Calculate context relevance of user input
  double _calculateContextRelevance(String userInput) {
    if (_conversationHistory.isEmpty) return 1.0;
    
    // Check if current input is a clarification or correction
    if (_isClarificationOrCorrection(userInput)) {
      return 0.8;
    }
    
    // Check if current input is a new topic
    if (_isNewTopic(userInput)) {
      return 0.3;
    }
    
    return 0.6;
  }

  /// Generate contextual response based on analysis
  Future<ConversationResponse> _generateContextualResponse(
    UserInputAnalysis analysis,
    ConversationMode mode,
  ) async {
    try {
      // Determine response strategy
      final responseStrategy = _determineResponseStrategy(analysis, mode);
      
      // Generate response based on strategy
      switch (responseStrategy) {
        case ResponseStrategy.directAnswer:
          return await _generateDirectAnswer(analysis);
        case ResponseStrategy.clarificationQuestion:
          return await _generateClarificationQuestion(analysis);
        case ResponseStrategy.contextualResponse:
          return await _generateContextualResponse(analysis, mode);
        case ResponseStrategy.personalityResponse:
          return await _generatePersonalityResponse(analysis);
        case ResponseStrategy.proactiveSuggestion:
          return await _generateProactiveSuggestion(analysis);
            case ResponseStrategy.fallback:
      return await _generateDefaultResponse(analysis);
      }
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'response_generation_failed',
        errorMessage: e.toString(),
      );
      return _generateFallbackResponse(analysis.originalInput);
    }
  }

    /// Determine the best response strategy
  ResponseStrategy _determineResponseStrategy(
    UserInputAnalysis analysis,
    ConversationMode mode,
  ) {
    // High urgency requires direct answers
    if (analysis.sentiment.urgencyScore > 2) {
      return ResponseStrategy.directAnswer;
    }

    // Missing required information needs clarification
    if (_needsClarification(analysis)) {
      return ResponseStrategy.clarificationQuestion;
    }

    // High context relevance suggests contextual response
    if (analysis.contextRelevance > 0.8) {
      return ResponseStrategy.contextualResponse;
    }

    // Personality mode for casual conversations
    if (mode == ConversationMode.casual) {
      return ResponseStrategy.personalityResponse;
    }

    // Proactive suggestions for routine patterns
    if (_shouldSuggestProactive(analysis)) {
      return ResponseStrategy.proactiveSuggestion;
    }

    return ResponseStrategy.fallback;
  }

  /// Generate direct answer to user input
  Future<ConversationResponse> _generateDirectAnswer(UserInputAnalysis analysis) async {
    final intent = analysis.intent;
    
    // Generate response based on intent
    switch (intent.type) {
      case RideIntentType.destination:
        return await _generateRideBookingResponse(analysis);
      case RideIntentType.location:
        return await _generatePriceResponse(analysis);
      case RideIntentType.pickup:
        return await _generateETAResponse(analysis);
      case RideIntentType.cancel:
        return await _generateCancellationResponse(analysis);
      case RideIntentType.unknown:
        return await _generateHelpResponse(analysis);
    }
  }

  /// Generate clarification question
  Future<ConversationResponse> _generateClarificationQuestion(UserInputAnalysis analysis) async {
    final intent = analysis.intent;
    final missingInfo = _determineMissingInformation(analysis);
    
    final question = _aiPersonality.getClarificationQuestion(
      missingInfo: missingInfo,
      context: _getIntentContext(intent.type),
    );
    
    return ConversationResponse(
      text: question,
      intent: intent,
      confidence: 0.8,
      requiresClarification: true,
      clarificationType: _getClarificationType(missingInfo),
      suggestions: _generateClarificationSuggestions(missingInfo),
    );
  }



  /// Generate personality-based response
  Future<ConversationResponse> _generatePersonalityResponse(UserInputAnalysis analysis) async {
    final personalityText = _aiPersonality.getPersonalityResponse(
      intent: analysis.intent.type,
      sentiment: analysis.sentiment.type,
      context: analysis.userContext?.mode ?? ConversationMode.normal,
    );
    
    return ConversationResponse(
      text: personalityText,
      intent: analysis.intent,
      confidence: 0.85,
      suggestions: _generatePersonalitySuggestions(analysis),
    );
  }

  /// Generate proactive suggestion
  Future<ConversationResponse> _generateProactiveSuggestion(UserInputAnalysis analysis) async {
    final suggestion = _generateProactiveSuggestionText(analysis);
    
    return ConversationResponse(
      text: suggestion,
      intent: analysis.intent,
      confidence: 0.8,
      suggestions: _generateProactiveSuggestions(analysis),
      action: ConversationAction.getInfo,
    );
  }

  /// Generate default response
  Future<ConversationResponse> _generateDefaultResponse(UserInputAnalysis analysis) async {
    return ConversationResponse(
      text: _aiPersonality.getDefaultResponse(analysis.intent.type),
      intent: analysis.intent,
      confidence: 0.7,
    );
  }

  /// Generate price response
  Future<ConversationResponse> _generatePriceResponse(UserInputAnalysis analysis) async {
    final destination = _extractDestination(analysis);
    
    if (destination == null) {
      return ConversationResponse(
        text: _aiPersonality.getClarificationQuestion(
          missingInfo: 'destinația',
          context: 'calculare preț',
        ),
        intent: analysis.intent,
        confidence: 0.8,
        requiresClarification: true,
        clarificationType: ClarificationType.location,
      );
    }
    
    // Mock price calculation
    final estimatedPrice = _calculateEstimatedPrice(destination);
    
    return ConversationResponse(
      text: 'Prețul estimat pentru cursă la $destination este de $estimatedPrice lei. Să rezervi?',
      intent: analysis.intent,
      confidence: 0.9,
      action: ConversationAction.confirmRide,
      actionData: {
        'destination': destination,
        'estimatedPrice': estimatedPrice,
      },
    );
  }

  /// Generate ETA response
  Future<ConversationResponse> _generateETAResponse(UserInputAnalysis analysis) async {
    final destination = _extractDestination(analysis);
    
    if (destination == null) {
      return ConversationResponse(
        text: _aiPersonality.getClarificationQuestion(
          missingInfo: 'destinația',
          context: 'calculare timp sosire',
        ),
        intent: analysis.intent,
        confidence: 0.8,
        requiresClarification: true,
        clarificationType: ClarificationType.location,
      );
    }
    
    // Mock ETA calculation
    final eta = _calculateEstimatedTime(destination);
    
    return ConversationResponse(
      text: 'Timpul estimat de sosire la $destination este de $eta minute. Să rezervi cursă?',
      intent: analysis.intent,
      confidence: 0.9,
      action: ConversationAction.confirmRide,
      actionData: {
        'destination': destination,
        'eta': eta,
      },
    );
  }

  /// Generate cancellation response
  Future<ConversationResponse> _generateCancellationResponse(UserInputAnalysis analysis) async {
    return ConversationResponse(
      text: 'Înțeleg că vrei să anulezi cursa. Să confirm anularea?',
      intent: analysis.intent,
      confidence: 0.9,
      requiresClarification: true,
      clarificationType: ClarificationType.general,
      action: ConversationAction.cancelRide,
      suggestions: ['Da, anulează', 'Nu, păstrează cursa'],
    );
  }

  /// Generate help response
  Future<ConversationResponse> _generateHelpResponse(UserInputAnalysis analysis) async {
    final helpText = _aiPersonality.getHelpResponse(analysis.intent.type);
    
    return ConversationResponse(
      text: helpText,
      intent: analysis.intent,
      confidence: 0.9,
      action: ConversationAction.help,
      suggestions: [
        'Cum să rezerv o cursă?',
        'Cum să verific prețul?',
        'Cum să anulez o cursă?',
        'Cum să contactez suportul?',
      ],
    );
  }



  /// Determine missing information for clarification
  String _determineMissingInformation(UserInputAnalysis analysis) {
    final intent = analysis.intent;
    
    switch (intent.type) {
      case RideIntentType.destination:
        if (!_hasPickupLocation(analysis)) return 'punctul de plecare';
        if (!_hasDestination(analysis)) return 'destinația';
        if (!_hasTimePreference(analysis)) return 'timpul de plecare';
        break;
      case RideIntentType.pickup:
        if (!_hasPickupLocation(analysis)) return 'punctul de plecare';
        break;
      case RideIntentType.location:
        if (!_hasDestination(analysis)) return 'destinația';
        break;
      case RideIntentType.cancel:
        // No specific information needed for cancellation
        break;
      case RideIntentType.unknown:
        // No specific information needed for unknown intent
        break;
    }
    
    return 'informații suplimentare';
  }

  /// Check if analysis has pickup location
  bool _hasPickupLocation(UserInputAnalysis analysis) {
    return analysis.entities.any((e) => e.type == EntityType.location);
  }

  /// Check if analysis has destination
  bool _hasDestination(UserInputAnalysis analysis) {
    return analysis.entities.any((e) => e.type == EntityType.location);
  }

  /// Check if analysis has time preference
  bool _hasTimePreference(UserInputAnalysis analysis) {
    return analysis.entities.any((e) => e.type == EntityType.time);
  }

  /// Get intent context for clarification
  String _getIntentContext(RideIntentType intentType) {
    switch (intentType) {
      case RideIntentType.destination:
        return 'rezervare cursă';
      case RideIntentType.pickup:
        return 'stabilire punct plecare';
      case RideIntentType.location:
        return 'calculare preț';
      case RideIntentType.cancel:
        return 'anulare cursă';
      case RideIntentType.unknown:
        return 'ajutor';
    }
  }

  /// Get clarification type based on missing information
  ClarificationType _getClarificationType(String missingInfo) {
    if (missingInfo.contains('plecare') || missingInfo.contains('destinația')) {
      return ClarificationType.location;
    } else if (missingInfo.contains('timp')) {
      return ClarificationType.time;
    } else if (missingInfo.contains('preferință')) {
      return ClarificationType.preference;
    }
    return ClarificationType.general;
  }

  /// Generate clarification suggestions
  List<String> _generateClarificationSuggestions(String missingInfo) {
    if (missingInfo.contains('plecare')) {
      return ['De la birou', 'De la acasă', 'De la gara de nord'];
    } else if (missingInfo.contains('destinația')) {
      return ['La mall', 'La centru', 'La aeroport'];
    } else if (missingInfo.contains('timp')) {
      return ['Acum', 'În 10 minute', 'La 15:00'];
    }
    return ['Poți să fii mai specific?'];
  }



  /// Generate personality suggestions
  List<String> _generatePersonalitySuggestions(UserInputAnalysis analysis) {
    // Generate suggestions based on user personality and mood
    final suggestions = <String>[];
    
    if (analysis.sentiment.type == SentimentType.positive) {
      suggestions.addAll(['Mulțumesc!', 'Super!', 'Continuă']);
    } else if (analysis.sentiment.type == SentimentType.negative) {
      suggestions.addAll(['Îmi pare rău', 'Să te ajut', 'Să rezolv problema']);
    }
    
    return suggestions;
  }

  /// Generate proactive suggestions
  List<String> _generateProactiveSuggestions(UserInputAnalysis analysis) {
    // Generate proactive suggestions based on various factors
    final suggestions = <String>[];
    
    // Time-based suggestions
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour <= 9) {
      suggestions.add('E ora de vârf dimineața. Vrei să rezervi taxi pentru muncă?');
    } else if (hour >= 17 && hour <= 19) {
      suggestions.add('E ora de vârf seara. Vrei să rezervi taxi pentru acasă?');
    }
    
    // Location-based suggestions
    if (analysis.userContext?.location != null) {
      final location = analysis.userContext!.location!;
      if (location.contains('mall') || location.contains('centru')) {
        suggestions.add('Ești în centru. Vrei să rezervi taxi pentru acasă?');
      }
    }
    
    // Pattern-based suggestions
    if (_conversationHistory.isNotEmpty) {
      final lastTurn = _conversationHistory.last;
      if (lastTurn.response.intent.type == RideIntentType.destination) {
        suggestions.add('Vrei să programezi și cursa de întoarcere?');
      }
    }
    
    return suggestions;
  }





  /// Calculate estimated price
  double _calculateEstimatedPrice(String destination) {
    // Mock price calculation based on destination
    const basePrice = 15.0;
    final distanceMultiplier = _getDistanceMultiplier(destination);
    return (basePrice * distanceMultiplier).roundToDouble();
  }

  /// Calculate estimated time
  int _calculateEstimatedTime(String destination) {
    // Mock time calculation based on destination
    const baseTime = 15;
    final trafficMultiplier = _getTrafficMultiplier(destination);
    return (baseTime * trafficMultiplier).round();
  }

  /// Get distance multiplier for price calculation
  double _getDistanceMultiplier(String destination) {
    final destinationLower = destination.toLowerCase();
    
    if (destinationLower.contains('mall') || destinationLower.contains('centru')) {
      return 1.2;
    } else if (destinationLower.contains('aeroport')) {
      return 2.5;
    } else if (destinationLower.contains('gara')) {
      return 1.5;
    }
    
    return 1.0;
  }

  /// Get traffic multiplier for time calculation
  double _getTrafficMultiplier(String destination) {
    final destinationLower = destination.toLowerCase();
    
    if (destinationLower.contains('centru') || destinationLower.contains('mall')) {
      return 1.3; // More traffic in city center
    } else if (destinationLower.contains('aeroport')) {
      return 0.8; // Less traffic to airport
    }
    
    return 1.0;
  }

  /// Generate proactive suggestion text
  String _generateProactiveSuggestionText(UserInputAnalysis analysis) {
    // Generate proactive suggestions based on various factors
    final suggestions = <String>[];
    
    // Time-based suggestions
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour <= 9) {
      suggestions.add('E ora de vârf dimineața. Vrei să rezervi taxi pentru muncă?');
    } else if (hour >= 17 && hour <= 19) {
      suggestions.add('E ora de vârf seara. Vrei să rezervi taxi pentru acasă?');
    }
    
    // Location-based suggestions
    if (analysis.userContext?.location != null) {
      final location = analysis.userContext!.location!;
      if (location.contains('mall') || location.contains('centru')) {
        suggestions.add('Ești în centru. Vrei să rezervi taxi pentru acasă?');
      }
    }
    
    // Pattern-based suggestions
    if (_conversationHistory.isNotEmpty) {
      final lastTurn = _conversationHistory.last;
      if (lastTurn.response.intent.type == RideIntentType.destination) {
        suggestions.add('Vrei să programezi și cursa de întoarcere?');
      }
    }
    
    return suggestions.isNotEmpty ? suggestions.first : 'Vrei să faci ceva altceva?';
  }



  /// Generate ride booking response
  Future<ConversationResponse> _generateRideBookingResponse(UserInputAnalysis analysis) async {
    final pickup = _extractPickupLocation(analysis);
    final destination = _extractDestination(analysis);
    
    if (pickup == null || destination == null) {
      return ConversationResponse(
        text: _aiPersonality.getClarificationQuestion(
          missingInfo: pickup == null ? 'punctul de plecare' : 'destinația',
          context: 'rezervare cursă',
        ),
        intent: analysis.intent,
        confidence: 0.8,
        requiresClarification: true,
        clarificationType: ClarificationType.location,
      );
    }
    
    // Generate confirmation response
    final response = _aiPersonality.getConfirmationResponse(
      action: 'rezervare cursă',
      details: 'de la $pickup la $destination',
      tone: _toneManager.getToneForContext(analysis.userContext),
    );
    
    return ConversationResponse(
      text: response,
      intent: analysis.intent,
      confidence: 0.95,
      action: ConversationAction.confirmRide,
      actionData: {
        'pickup': pickup,
        'destination': destination,
        'entities': analysis.entities.map((e) => e.toMap()).toList(),
      },
    );
  }

  /// Extract pickup location from analysis
  String? _extractPickupLocation(UserInputAnalysis analysis) {
    final locationEntities = analysis.entities
        .where((e) => e.type == EntityType.location)
        .toList();
    
    if (locationEntities.isEmpty) return null;
    
    // Look for pickup indicators
    final pickupIndicators = ['de la', 'din', 'plec de la'];
    final input = analysis.originalInput.toLowerCase();
    
    for (final indicator in pickupIndicators) {
      final index = input.indexOf(indicator);
      if (index != -1) {
        // Find the location entity that comes after this indicator
        for (final entity in locationEntities) {
          if (entity.startIndex > index) {
            return entity.value;
          }
        }
      }
    }
    
    // Default to first location entity if no clear pickup indicator
    return locationEntities.first.value;
  }

  /// Extract destination from analysis
  String? _extractDestination(UserInputAnalysis analysis) {
    final locationEntities = analysis.entities
        .where((e) => e.type == EntityType.location)
        .toList();
    
    if (locationEntities.isEmpty) return null;
    
    // Look for destination indicators
    final destinationIndicators = ['la', 'spre', 'către', 'până la'];
    final input = analysis.originalInput.toLowerCase();
    
    for (final indicator in destinationIndicators) {
      final index = input.indexOf(indicator);
      if (index != -1) {
        // Find the location entity that comes after this indicator
        for (final entity in locationEntities) {
          if (entity.startIndex > index) {
            return entity.value;
          }
        }
      }
    }
    
    // Default to last location entity if no clear destination indicator
    return locationEntities.last.value;
  }

  /// Generate fallback response when processing fails
  ConversationResponse _generateFallbackResponse(String userInput) {
    return ConversationResponse(
      text: _aiPersonality.getFallbackResponse(userInput),
      intent: RideIntent(type: RideIntentType.unknown, destination: '', pickupLocation: '', confidence: 0.0),
      confidence: 0.5,
      requiresClarification: true,
      clarificationType: ClarificationType.general,
    );
  }

  /// Update conversation context with new information
  void _updateConversationContext(UserInputAnalysis analysis, UserContext? userContext) {
    _currentContext.updateWith(analysis);
    
    if (userContext != null) {
      _currentContext.mergeUserContext(userContext);
    }
    
    // Store context in stack for complex conversations
    _contextStack[DateTime.now().millisecondsSinceEpoch.toString()] = _currentContext.clone();
  }

  /// Add conversation turn to history
  void _addToConversationHistory(String userInput, ConversationResponse response) {
    final turn = ConversationTurn(
      userInput: userInput,
      response: response,
      timestamp: DateTime.now(),
      context: _currentContext.clone(),
    );
    
    _conversationHistory.add(turn);
    
    // IMPLEMENTARE CLEANUP AVANSAT PENTRU PREVENIREA MEMORY LEAK
    if (_conversationHistory.length > _maxConversationHistory) {
      _conversationHistory.removeAt(0);
    }
    
    // Cleanup expired conversation turns
    _cleanupExpiredConversationHistory();
    
    // Cleanup context stack if it grows too large
    _cleanupContextStack();
  }

  /// Load user preferences from storage
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString('user_preferences');
      
      if (preferencesJson != null) {
        final preferences = json.decode(preferencesJson) as Map<String, dynamic>;
        _userPreferences.addAll(Map<String, List<String>>.from(preferences));
      }
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'user_preferences_loading_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Load conversation history from storage
  Future<void> _loadConversationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('conversation_history');
      
      if (historyJson != null) {
        // Reconstruct conversation turns from stored data
        // This is a simplified version - in production, you'd want more robust serialization
        _conversationHistory.clear();
      }
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'conversation_history_loading_failed',
        errorMessage: e.toString(),
      );
    }
  }
  
  /// Cleanup expired conversation history to prevent memory leaks
  void _cleanupExpiredConversationHistory() {
    final cutoff = DateTime.now().subtract(_maxHistoryAge);
    _conversationHistory.removeWhere((turn) => turn.timestamp.isBefore(cutoff));
  }
  
  /// Cleanup context stack to prevent memory leaks
  void _cleanupContextStack() {
    if (_contextStack.length > _maxContextStack) {
      final excess = _contextStack.length - _maxContextStack;
      final keysToRemove = _contextStack.keys.take(excess).toList();
      for (final key in keysToRemove) {
        _contextStack.remove(key);
      }
    }
    
    // IMPLEMENTARE CLEANUP AVANSAT PENTRU PREVENIREA MEMORY LEAK
    // Cleanup expired contexts
    final cutoff = DateTime.now().subtract(_maxHistoryAge);
    _contextStack.removeWhere((key, context) => 
      context.lastUpdated.isBefore(cutoff)
    );
    
    // Cleanup individual context data
    for (final context in _contextStack.values) {
      if (context.data.length > 50) {
        final excess = context.data.length - 50;
        final keysToRemove = context.data.keys.take(excess).toList();
        for (final key in keysToRemove) {
          context.data.remove(key);
        }
      }
    }
  }
  
  /// Cleanup session memory to prevent memory leaks
  void _cleanupSessionMemory() {
    if (_sessionMemory.length > _maxSessionMemory) {
      final excess = _sessionMemory.length - _maxSessionMemory;
      final keysToRemove = _sessionMemory.keys.take(excess).toList();
      for (final key in keysToRemove) {
        _sessionMemory.remove(key);
      }
    }
  }

  /// Initialize performance monitoring
  void _initializePerformanceMonitoring() {
    _performanceMetrics['response_time'] = PerformanceMetric(
      name: 'response_time',
      value: 0.0,
      unit: 'ms',
      metadata: {'initialized': true},
      timestamp: DateTime.now(),
    );
    
    // IMPLEMENTARE CLEANUP PERIODIC PENTRU PREVENIREA MEMORY LEAK
    _startPeriodicCleanup();
  }
  
  /// Start periodic cleanup to prevent memory leaks
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredConversationHistory();
      _cleanupContextStack();
      _cleanupSessionMemory();
    });
  }

  /// Check if input needs clarification
  bool _needsClarification(UserInputAnalysis analysis) {
    final intent = analysis.intent;
    
    switch (intent.type) {
      case RideIntentType.destination:
        return !_hasRequiredRideInfo(analysis);
      case RideIntentType.location:
        return !_hasRequiredPriceInfo(analysis);
      case RideIntentType.pickup:
        return !_hasRequiredETAInfo(analysis);
      default:
        return false;
    }
  }

  /// Check if ride booking has required information
  bool _hasRequiredRideInfo(UserInputAnalysis analysis) {
    final hasPickup = analysis.entities.any((e) => e.type == EntityType.location);
    final hasDestination = analysis.entities.any((e) => e.type == EntityType.location);
    
    return hasPickup && hasDestination;
  }

  /// Check if price request has required information
  bool _hasRequiredPriceInfo(UserInputAnalysis analysis) {
    return analysis.entities.any((e) => e.type == EntityType.location);
  }

  /// Check if ETA request has required information
  bool _hasRequiredETAInfo(UserInputAnalysis analysis) {
    return analysis.entities.any((e) => e.type == EntityType.location);
  }

  /// Check if should suggest proactive actions
  bool _shouldSuggestProactive(UserInputAnalysis analysis) {
    // Suggest proactive actions based on patterns, time, location, etc.
    return false; // Simplified for now
  }





  /// Check if input is clarification or correction
  bool _isClarificationOrCorrection(String userInput) {
    final clarificationWords = [
      'nu', 'greșit', 'altul', 'altă', 'diferit', 'clarificare',
      'corect', 'exact', 'precis', 'specific'
    ];
    
    final lowerInput = userInput.toLowerCase();
    return clarificationWords.any((word) => lowerInput.contains(word));
  }

  /// Check if input is new topic
  bool _isNewTopic(String userInput) {
    final newTopicWords = [
      'altceva', 'altă întrebare', 'schimb subiectul', 'nou',
      'diferit', 'altă problemă'
    ];
    
    final lowerInput = userInput.toLowerCase();
    return newTopicWords.any((word) => lowerInput.contains(word));
  }

  /// Get current conversation state
  ConversationState get conversationState => _conversationState;
  
  /// Get conversation history
  List<ConversationTurn> get conversationHistory => List.unmodifiable(_conversationHistory);
  
  /// Get current context
  ConversationContext get currentContext => _currentContext;
  
  /// Get user personality
  UserPersonality get userPersonality => _userPersonality;
  
  /// Get AI personality
  AIPersonality get aiPersonality => _aiPersonality;
  
  /// Dispose resources
  void dispose() {
    // IMPLEMENTARE CLEANUP COMPLET PENTRU PREVENIREA MEMORY LEAK
    
    // Cancel cleanup timer
    _cleanupTimer?.cancel();
    
    // Cleanup conversation history
    _conversationHistory.clear();
    
    // Cleanup context stack
    _contextStack.clear();
    
    // Cleanup session memory
    _sessionMemory.clear();
    
    // Cleanup performance metrics
    _performanceMetrics.clear();
    
    // Cleanup user preferences
    _userPreferences.clear();
    
    // Reset conversation state
    _conversationState = ConversationState.idle;
    
    // Cleanup current context
    _currentContext = ConversationContext();
  }
}

// Supporting classes and enums

enum ConversationState {
  idle,
  listening,
  processing,
  waitingForUser,
  error,
  completed,
}

enum ConversationMode {
  normal,
  casual,
  business,
  emergency,
  family,
}

enum ResponseStrategy {
  directAnswer,
  clarificationQuestion,
  contextualResponse,
  personalityResponse,
  proactiveSuggestion,
  fallback,
}

enum ClarificationType {
  location,
  time,
  preference,
  general,
}

enum ConversationAction {
  confirmRide,
  cancelRide,
  getInfo,
  help,
  none,
}

enum EntityType {
  location,
  time,
  preference,
  person,
  vehicle,
  payment,
}

enum SentimentType {
  positive,
  negative,
  neutral,
  urgent,
}

class ConversationResponse {
  final String text;
  final RideIntent intent;
  final double confidence;
  final bool requiresClarification;
  final ClarificationType? clarificationType;
  final ConversationAction? action;
  final Map<String, dynamic>? actionData;
  final List<String> suggestions;
  final Map<String, dynamic> metadata;

  const ConversationResponse({
    required this.text,
    required this.intent,
    required this.confidence,
    this.requiresClarification = false,
    this.clarificationType,
    this.action,
    this.actionData,
    this.suggestions = const [],
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'intent': intent.toMap(),
      'confidence': confidence,
      'requiresClarification': requiresClarification,
      'clarificationType': clarificationType?.name,
      'action': action?.name,
      'actionData': actionData,
      'suggestions': suggestions,
      'metadata': metadata,
    };
  }
}

class UserInputAnalysis {
  final String originalInput;
  final RideIntent intent;
  final List<Entity> entities;
  final SentimentAnalysis sentiment;
  final double contextRelevance;
  final UserContext? userContext;
  final DateTime timestamp;

  const UserInputAnalysis({
    required this.originalInput,
    required this.intent,
    required this.entities,
    required this.sentiment,
    required this.contextRelevance,
    this.userContext,
    required this.timestamp,
  });
}

class Entity {
  final EntityType type;
  final String value;
  final double confidence;
  final int startIndex;
  final int endIndex;
  final Map<String, dynamic>? metadata;

  const Entity({
    required this.type,
    required this.value,
    required this.confidence,
    required this.startIndex,
    required this.endIndex,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'value': value,
      'confidence': confidence,
      'startIndex': startIndex,
      'endIndex': endIndex,
      'metadata': metadata,
    };
  }
}

class SentimentAnalysis {
  final SentimentType type;
  final double confidence;
  final int positiveScore;
  final int negativeScore;
  final int urgencyScore;

  const SentimentAnalysis({
    required this.type,
    required this.confidence,
    required this.positiveScore,
    required this.negativeScore,
    required this.urgencyScore,
  });
}

class ConversationTurn {
  final String userInput;
  final ConversationResponse response;
  final DateTime timestamp;
  final ConversationContext context;

  const ConversationTurn({
    required this.userInput,
    required this.response,
    required this.timestamp,
    required this.context,
  });
}

class ConversationContext {
  final Map<String, dynamic> data;
  final DateTime lastUpdated;
  final String sessionId;

  ConversationContext({
    Map<String, dynamic>? data,
    DateTime? lastUpdated,
    String? sessionId,
  }) : 
    data = data ?? {},
    lastUpdated = lastUpdated ?? DateTime.now(),
    sessionId = sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

  void updateWith(UserInputAnalysis analysis) {
    data['lastIntent'] = analysis.intent.type.name;
    data['lastEntities'] = analysis.entities.map((e) => e.toMap()).toList();
    data['lastSentiment'] = analysis.sentiment.type.name;
    data['lastUpdate'] = DateTime.now().toIso8601String();
  }

  void mergeUserContext(UserContext userContext) {
    data['userLocation'] = userContext.location;
    data['userTime'] = userContext.currentTime;
    data['userMode'] = userContext.mode;
    data['userPreferences'] = userContext.preferences;
  }

  ConversationContext clone() {
    return ConversationContext(
      data: Map<String, dynamic>.from(data),
      lastUpdated: lastUpdated,
      sessionId: sessionId,
    );
  }
}

class UserContext {
  final String? location;
  final DateTime currentTime;
  final ConversationMode mode;
  final Map<String, dynamic> preferences;

  const UserContext({
    this.location,
    required this.currentTime,
    this.mode = ConversationMode.normal,
    this.preferences = const {},
  });
}

class UserPersonality {
  final Map<String, dynamic> traits;
  final Map<String, List<String>> preferences;
  final Map<String, DateTime> learningHistory;

  UserPersonality({
    Map<String, dynamic>? traits,
    Map<String, List<String>>? preferences,
    Map<String, DateTime>? learningHistory,
  }) : 
    traits = traits ?? {},
    preferences = preferences ?? {},
    learningHistory = learningHistory ?? {};

  // IMPLEMENTARE CLEANUP PENTRU PREVENIREA MEMORY LEAK
  static const int _maxPreferences = 100;
  static const int _maxLearningHistory = 200;
  static const Duration _maxLearningAge = Duration(days: 30);

  void learnPreference(String category, String value) {
    if (!preferences.containsKey(category)) {
      preferences[category] = [];
    }
    
    if (!preferences[category]!.contains(value)) {
      preferences[category]!.add(value);
    }
    
    learningHistory['$category:$value'] = DateTime.now();
    
    // IMPLEMENTARE CLEANUP AUTOMAT PENTRU PREVENIREA MEMORY LEAK
    _cleanupPreferences();
    _cleanupLearningHistory();
  }
  
  /// Cleanup preferences to prevent memory leaks
  void _cleanupPreferences() {
    for (final category in preferences.keys) {
      if (preferences[category]!.length > _maxPreferences) {
        final excess = preferences[category]!.length - _maxPreferences;
        preferences[category]!.removeRange(0, excess);
      }
    }
  }
  
  /// Cleanup learning history to prevent memory leaks
  void _cleanupLearningHistory() {
    final cutoff = DateTime.now().subtract(_maxLearningAge);
    learningHistory.removeWhere((key, timestamp) => timestamp.isBefore(cutoff));
    
    if (learningHistory.length > _maxLearningHistory) {
      final excess = learningHistory.length - _maxLearningHistory;
      final keysToRemove = learningHistory.keys.take(excess).toList();
      for (final key in keysToRemove) {
        learningHistory.remove(key);
      }
    }
  }
  
  /// Cleanup all data to prevent memory leaks
  void cleanup() {
    _cleanupPreferences();
    _cleanupLearningHistory();
  }
}

class AIPersonality {
  final Map<String, String> responses;
  final Map<String, String> fallbackResponses;
  final Map<String, String> clarificationQuestions;

  AIPersonality({
    Map<String, String>? responses,
    Map<String, String>? fallbackResponses,
    Map<String, String>? clarificationQuestions,
  }) : 
    responses = responses ?? _defaultResponses,
    fallbackResponses = fallbackResponses ?? _defaultFallbackResponses,
    clarificationQuestions = clarificationQuestions ?? _defaultClarificationQuestions;

  String getClarificationQuestion({
    required String missingInfo,
    required String context,
  }) {
    final key = '${context}_$missingInfo';
    return clarificationQuestions[key] ?? 
           'Îmi poți spune $missingInfo pentru $context?';
  }

  String getConfirmationResponse({
    required String action,
    required String details,
    required String tone,
  }) {
    final key = '${action}_confirmation';
    final baseResponse = responses[key] ?? 
                        'Perfect! Am înțeles că vrei să $action: $details. Să confirm?';
    
    return _applyTone(baseResponse, tone);
  }

  String getFallbackResponse(String userInput) {
    return fallbackResponses['general'] ?? 
           'Îmi pare rău, nu am înțeles exact ce vrei. Poți să reformulezi?';
  }

  String getPersonalityResponse({
    required RideIntentType intent,
    required SentimentType sentiment,
    required ConversationMode context,
  }) {
    // Generate personality-based responses
    final baseResponse = _getBasePersonalityResponse(intent, sentiment);
    return _applyPersonalityTone(baseResponse, context);
  }

  String getHelpResponse(RideIntentType intentType) {
    switch (intentType) {
      case RideIntentType.destination:
        return 'Pentru a rezerva o cursă, spune-mi de unde vrei să pleci și unde vrei să ajungi. De exemplu: "Vreau să merg de la birou la mall".';
      case RideIntentType.pickup:
        return 'Pentru a stabilii punctul de plecare, spune-mi de unde vrei să pleci. De exemplu: "De la birou" sau "Din centru".';
      case RideIntentType.location:
        return 'Pentru a afla prețul, spune-mi destinația. De exemplu: "Cât costă să merg la aeroport?"';
      case RideIntentType.cancel:
        return 'Pentru a anula o cursă, spune-mi "Anulează cursa" sau "Nu mai vreau taxi".';
      default:
        return 'Sunt aici să te ajut cu orice ai nevoie legat de transport. Poți să-mi spui ce vrei să fac?';
    }
  }

  String getDefaultResponse(RideIntentType intentType) {
    switch (intentType) {
      case RideIntentType.destination:
        return 'Perfect! Să rezervis o cursă pentru tine.';
      case RideIntentType.pickup:
        return 'Să stabilesc punctul de plecare.';
      case RideIntentType.location:
        return 'Să calculez prețul pentru ruta ta.';
      case RideIntentType.cancel:
        return 'Să anulez cursa.';
      case RideIntentType.unknown:
        return 'Să te ajut cu informațiile necesare.';
    }
  }

  String _getBasePersonalityResponse(RideIntentType intent, SentimentType sentiment) {
    // Base responses based on intent and sentiment
    if (sentiment == SentimentType.positive) {
      switch (intent) {
        case RideIntentType.destination:
          return 'Super! Să rezervi o cursă pentru tine.';
        case RideIntentType.location:
          return 'Excelent! Să calculez prețul.';
        case RideIntentType.pickup:
          return 'Perfect! Să verific timpul de sosire.';
        default:
          return 'Grozav! Să continui cu operațiunea.';
      }
    } else if (sentiment == SentimentType.negative) {
      switch (intent) {
        case RideIntentType.destination:
          return 'Îmi pare rău că ai probleme. Să te ajut să rezervi o cursă.';
        case RideIntentType.location:
          return 'Înțeleg frustrarea. Să calculez prețul rapid.';
        case RideIntentType.pickup:
          return 'Să verific timpul de sosire pentru tine.';
        default:
          return 'Să te ajut să rezolvi problema.';
      }
    } else {
      return getDefaultResponse(intent);
    }
  }

  String _applyPersonalityTone(String response, ConversationMode context) {
    switch (context) {
      case ConversationMode.business:
        return 'Vă rog să confirmați: $response';
      case ConversationMode.casual:
        return 'Hei! $response';
      case ConversationMode.family:
        return 'Super! $response';
      case ConversationMode.emergency:
        return 'URGENT: $response';
      default:
        return response;
    }
  }

  String _applyTone(String response, String tone) {
    // Apply different tones to responses
    switch (tone.toLowerCase()) {
      case 'formal':
        return 'Vă rog să confirmați: $response';
      case 'casual':
        return 'Hei! $response';
      case 'friendly':
        return 'Super! $response';
      default:
        return response;
    }
  }

  static const Map<String, String> _defaultResponses = {
    'ride_booking_confirmation': 'Perfect! Am înțeles că vrei să rezervi o cursă: {details}. Să confirm?',
    'price_confirmation': 'Am calculat prețul pentru ruta ta: {details}. Să continui cu rezervarea?',
    'eta_confirmation': 'Timpul estimat de sosire este: {details}. Să rezervi cursă?',
  };

  static const Map<String, String> _defaultFallbackResponses = {
    'general': 'Îmi pare rău, nu am înțeles exact ce vrei. Poți să reformulezi?',
    'technical': 'Am o problemă tehnică momentan. Poți să încerci din nou?',
    'unclear': 'Nu sunt sigur ce vrei să fac. Poți să fii mai specific?',
  };

  static const Map<String, String> _defaultClarificationQuestions = {
    'ride_booking_pickup': 'De unde vrei să pleci?',
    'ride_booking_destination': 'Unde vrei să ajungi?',
    'ride_booking_time': 'Când vrei să pleci?',
    'price_location': 'Pentru ce rută vrei să știu prețul?',
    'eta_location': 'Pentru ce destinație vrei să știu timpul de sosire?',
  };
}

class ToneManager {
  final Map<String, String> toneRules;
  final Map<String, String> contextTones;

  ToneManager({
    Map<String, String>? toneRules,
    Map<String, String>? contextTones,
  }) : 
    toneRules = toneRules ?? _defaultToneRules,
    contextTones = contextTones ?? _defaultContextTones;

  String getToneForContext(UserContext? userContext) {
    if (userContext == null) return 'normal';
    
    // Determine tone based on context
    if (userContext.mode == ConversationMode.business) {
      return 'formal';
    } else if (userContext.mode == ConversationMode.casual) {
      return 'casual';
    } else if (userContext.mode == ConversationMode.emergency) {
      return 'urgent';
    }
    
    return 'normal';
  }

  static const Map<String, String> _defaultToneRules = {
    'business': 'formal',
    'casual': 'casual',
    'emergency': 'urgent',
    'family': 'friendly',
  };

  static const Map<String, String> _defaultContextTones = {
    'work': 'formal',
    'home': 'casual',
    'travel': 'informative',
    'shopping': 'friendly',
  };
}
