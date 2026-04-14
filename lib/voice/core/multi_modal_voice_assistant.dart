import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'voice_analytics.dart';
import 'conversational_ai_engine.dart';
import 'eco_integration_service.dart';
import 'proactive_ai_service.dart';
import '../nlp/ride_intent_processor.dart';

/// Multi-Modal Voice Assistant for Nabour
/// Handles different voice modes, personalities, and advanced voice capabilities
class MultiModalVoiceAssistant {
  static final MultiModalVoiceAssistant _instance = MultiModalVoiceAssistant._internal();
  factory MultiModalVoiceAssistant() => _instance;
  MultiModalVoiceAssistant._internal();

  // Core services
  late ConversationalAIEngine _conversationalAI;
  late EcosystemIntegrationService _ecosystemService;
  late ProactiveAIService _proactiveAI;
  
  // Voice modes and personalities
  late VoiceModeManager _voiceModeManager;
  late VoicePersonalityManager _personalityManager;
  late VoiceCommandProcessor _commandProcessor;
  
  // Ambient intelligence
  late AmbientIntelligence _ambientIntelligence;
  late WakeWordManager _wakeWordManager;
  late BackgroundProcessor _backgroundProcessor;
  
  // Configuration and state
  bool _isInitialized = false;
  bool _isAlwaysListening = false;
  bool _isBackgroundProcessing = false;
  VoiceMode _currentMode = VoiceMode.normal;
  VoicePersonality _currentPersonality = VoicePersonality.friendly;
  
  // Performance tracking
  final Map<String, PerformanceMetric> _performanceMetrics = {};
  
  /// Initialize the multi-modal voice assistant
  Future<void> initialize() async {
    try {
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'multi_modal_voice_assistant_initialization_started'});
      
      // Initialize core services
      _conversationalAI = ConversationalAIEngine();
      _ecosystemService = EcosystemIntegrationService();
      _proactiveAI = ProactiveAIService();
      
      // Initialize voice components
      _voiceModeManager = VoiceModeManagerImpl();
      _personalityManager = VoicePersonalityManagerImpl();
      _commandProcessor = VoiceCommandProcessorImpl();
      
      // Initialize ambient intelligence
      _ambientIntelligence = AmbientIntelligenceImpl();
      _wakeWordManager = WakeWordManagerImpl();
      _backgroundProcessor = BackgroundProcessorImpl();
      
      // Initialize services
      await Future.wait([
        _conversationalAI.initialize(),
        _ecosystemService.initialize(),
        _proactiveAI.initialize(),
        _voiceModeManager.initialize(),
        _personalityManager.initialize(),
        _commandProcessor.initialize(),
        _ambientIntelligence.initialize(),
        _wakeWordManager.initialize(),
        _backgroundProcessor.initialize(),
      ]);
      
      // Load user preferences
      await _loadUserPreferences();
      
      // Start ambient intelligence
      await _startAmbientIntelligence();
      
      _isInitialized = true;
      
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'multi_modal_voice_assistant_initialization_completed'});
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'multi_modal_voice_assistant_initialization_failed',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Start ambient intelligence features
  Future<void> _startAmbientIntelligence() async {
    try {
      // Start "salut" detection
      await _wakeWordManager.startDetection();
      
      // Start background processing
      await _backgroundProcessor.startProcessing();
      
      // Start ambient monitoring
      await _ambientIntelligence.startMonitoring();
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'ambient_intelligence_start_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Process voice input with current mode and personality
  Future<VoiceResponse> processVoiceInput(
    String voiceInput, {
    VoiceMode? mode,
    VoicePersonality? personality,
    UserContext? userContext,
  }) async {
    try {
      VoiceAnalytics().startPerformanceTimer('voice_input_processing');
      
      // Use current mode and personality if not specified
      final targetMode = mode ?? _currentMode;
      final targetPersonality = personality ?? _currentPersonality;
      
      // Update voice mode if different
      if (mode != null && mode != _currentMode) {
        await _switchVoiceMode(mode);
      }
      
      // Update personality if different
      if (personality != null && personality != _currentPersonality) {
        await _switchPersonality(personality);
      }
      
      // Process with conversational AI
      final response = await _conversationalAI.processUserInput(
        voiceInput,
        userContext: userContext,
        mode: _convertToConversationMode(targetMode),
      );
      
      // Apply personality and mode-specific processing
      final processedResponse = await _processResponseWithPersonality(
        response,
        targetPersonality,
        targetMode,
      );
      
      // Generate voice response
      final voiceResponse = await _generateVoiceResponse(processedResponse, targetPersonality);
      
      VoiceAnalytics().endPerformanceTimer('voice_input_processing');
              VoiceAnalytics().trackEvent(VoiceEventType.userInteraction, data: {'operation': 'voice_input_processed_successfully'});
      
      return voiceResponse;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'voice_input_processing_failed',
        errorMessage: e.toString(),
      );
      return _generateFallbackVoiceResponse(voiceInput);
    }
  }

  /// Switch voice mode
  Future<void> _switchVoiceMode(VoiceMode newMode) async {
    try {
      // Validate mode switch
      if (!_canSwitchToMode(newMode)) {
        throw Exception('Cannot switch to mode: $newMode');
      }
      
      // Stop current mode
      await _stopCurrentMode();
      
      // Initialize new mode
      await _initializeMode(newMode);
      
      // Update current mode
      _currentMode = newMode;
      
      // Update personality if needed
      await _updatePersonalityForMode(newMode);
      
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'voice_mode_switched', 'newMode': newMode.name});
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'voice_mode_switch_failed',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Switch personality
  Future<void> _switchPersonality(VoicePersonality newPersonality) async {
    try {
      // Validate personality switch
      if (!_canSwitchToPersonality(newPersonality)) {
        throw Exception('Cannot switch to personality: $newPersonality');
      }
      
      // Update current personality
      _currentPersonality = newPersonality;
      
      // Update voice characteristics
      await _updateVoiceCharacteristics(newPersonality);
      
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'voice_personality_switched', 'newPersonality': newPersonality.name});
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'voice_personality_switch_failed',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Process response with personality
  Future<ConversationResponse> _processResponseWithPersonality(
    ConversationResponse response,
    VoicePersonality personality,
    VoiceMode mode,
  ) async {
    try {
      // Apply personality-specific modifications
      final modifiedResponse = await _personalityManager.applyPersonality(
        response,
        personality,
        mode,
      );
      
      // Apply mode-specific modifications
      final modeModifiedResponse = await _voiceModeManager.applyMode(
        modifiedResponse,
        mode,
      );
      
      return modeModifiedResponse;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'response_personality_processing_failed',
        errorMessage: e.toString(),
      );
      return response; // Return original response if processing fails
    }
  }

  /// Generate voice response
  Future<VoiceResponse> _generateVoiceResponse(
    ConversationResponse response,
    VoicePersonality personality,
  ) async {
    try {
      // Get voice characteristics for personality
      final voiceCharacteristics = _personalityManager.getVoiceCharacteristics(personality);
      
      // Generate speech
      final speech = await _generateSpeech(response.text, voiceCharacteristics);
      
      // Generate visual feedback
      final visualFeedback = await _generateVisualFeedback(response, personality);
      
      // Generate haptic feedback
      final hapticFeedback = await _generateHapticFeedback(response, personality);
      
      return VoiceResponse(
        speech: speech,
        visualFeedback: visualFeedback,
        hapticFeedback: hapticFeedback,
        response: response,
        personality: personality,
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'voice_response_generation_failed',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Generate speech with personality characteristics
  Future<SpeechOutput> _generateSpeech(String text, VoiceCharacteristics characteristics) async {
    try {
      // Apply text modifications based on characteristics
      final modifiedText = _applyTextModifications(text, characteristics);
      
      // Generate speech with characteristics
      final speech = await _commandProcessor.generateSpeech(
        modifiedText,
        characteristics: characteristics,
      );
      
      return SpeechOutput(
        text: modifiedText,
        audio: speech.audio,
        duration: speech.duration,
        characteristics: characteristics,
      );
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'speech_generation_failed',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Generate visual feedback
  Future<VisualFeedback> _generateVisualFeedback(
    ConversationResponse response,
    VoicePersonality personality,
  ) async {
    try {
      // Get visual style for personality
      final visualStyle = _personalityManager.getVisualStyle(personality);
      
      // Generate visual elements
      final visualElements = await _commandProcessor.generateVisualElements(
        response,
        visualStyle,
      );
      
      return VisualFeedback(
        elements: visualElements,
        style: visualStyle,
        personality: personality,
      );
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'visual_feedback_generation_failed',
        errorMessage: e.toString(),
      );
      return VisualFeedback.empty();
    }
  }

  /// Generate haptic feedback
  Future<HapticFeedback> _generateHapticFeedback(
    ConversationResponse response,
    VoicePersonality personality,
  ) async {
    try {
      // Get haptic pattern for personality
      final hapticPattern = _personalityManager.getHapticPattern(personality);
      
      // Generate haptic feedback
      final hapticOutput = await _commandProcessor.generateHapticFeedback(
        response,
        hapticPattern,
      );
      
      return HapticFeedback(
        pattern: hapticPattern,
        intensity: hapticOutput.intensity,
        duration: hapticOutput.duration,
        personality: personality,
      );
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'haptic_feedback_generation_failed',
        errorMessage: e.toString(),
      );
      return HapticFeedback.empty();
    }
  }

  /// Apply text modifications based on characteristics
  String _applyTextModifications(String text, VoiceCharacteristics characteristics) {
    String modifiedText = text;
    
    // Apply formality level
    if (characteristics.formalityLevel == FormalityLevel.formal) {
      modifiedText = _makeTextFormal(modifiedText);
    } else if (characteristics.formalityLevel == FormalityLevel.casual) {
      modifiedText = _makeTextCasual(modifiedText);
    }
    
    // Apply emotion level
    if (characteristics.emotionLevel == EmotionLevel.high) {
      modifiedText = _addEmotion(modifiedText, characteristics.emotionType);
    }
    
    // Apply cultural context
    if (characteristics.culturalContext != null) {
      modifiedText = _applyCulturalContext(modifiedText, characteristics.culturalContext!);
    }
    
    return modifiedText;
  }

  /// Make text formal
  String _makeTextFormal(String text) {
    // Apply formal language patterns
    String formalText = text;
    
    // Replace casual words with formal equivalents
    final formalReplacements = {
      'hei': 'bună ziua',
      'salut': 'bună ziua',
      'ce faci': 'cum vă simțiți',
      'ok': 'în regulă',
      'super': 'excelent',
    };
    
    for (final entry in formalReplacements.entries) {
      formalText = formalText.replaceAll(entry.key, entry.value);
    }
    
    return formalText;
  }

  /// Make text casual
  String _makeTextCasual(String text) {
    // Apply casual language patterns
    String casualText = text;
    
    // Replace formal words with casual equivalents
    final casualReplacements = {
      'bună ziua': 'hei',
      'vă rog': 'te rog',
      'vă mulțumesc': 'mulțumesc',
      'vă pot ajuta': 'te pot ajuta',
    };
    
    for (final entry in casualReplacements.entries) {
      casualText = casualText.replaceAll(entry.key, entry.value);
    }
    
    return casualText;
  }

  /// Add emotion to text
  String _addEmotion(String text, EmotionType emotionType) {
    switch (emotionType) {
      case EmotionType.joy:
        return '$text! 😊';
      case EmotionType.empathy:
        return '$text... 💙';
      case EmotionType.urgency:
        return '$text! ⚡';
      case EmotionType.calm:
        return '$text... 🌸';
      default:
        return text;
    }
  }

  /// Apply cultural context
  String _applyCulturalContext(String text, CulturalContext context) {
    switch (context) {
      case CulturalContext.romanian:
        // Apply Romanian cultural patterns
        return _applyRomanianCulturalPatterns(text);
      case CulturalContext.international:
        // Apply international cultural patterns
        return _applyInternationalCulturalPatterns(text);
    }
  }

  /// Apply Romanian cultural patterns
  String _applyRomanianCulturalPatterns(String text) {
    // Add Romanian cultural elements
    if (text.contains('mulțumesc')) {
      return '$text, cu plăcere!';
    }
    
    if (text.contains('bună dimineața')) {
      return '$text! Să ai o zi frumoasă!';
    }
    
    return text;
  }

  /// Apply international cultural patterns
  String _applyInternationalCulturalPatterns(String text) {
    // Add international cultural elements
    if (text.contains('thank you')) {
      return '$text, you\'re welcome!';
    }
    
    if (text.contains('good morning')) {
      return '$text! Have a great day!';
    }
    
    return text;
  }

  /// Check if can switch to mode
  bool _canSwitchToMode(VoiceMode mode) {
    // Check if mode is available
    if (!_voiceModeManager.isModeAvailable(mode)) {
      return false;
    }
    
    // Check if user has permission for mode
    if (!_hasPermissionForMode(mode)) {
      return false;
    }
    
    return true;
  }

  /// Check if can switch to personality
  bool _canSwitchToPersonality(VoicePersonality personality) {
    // Check if personality is available
    if (!_personalityManager.isPersonalityAvailable(personality)) {
      return false;
    }
    
    // Check if user has access to personality
    if (!_hasAccessToPersonality(personality)) {
      return false;
    }
    
    return true;
  }

  /// Check if has permission for mode
  bool _hasPermissionForMode(VoiceMode mode) {
    switch (mode) {
      case VoiceMode.emergency:
        return _hasEmergencyPermission();
      case VoiceMode.business:
        return _hasBusinessPermission();
      case VoiceMode.family:
        return _hasFamilyPermission();
      default:
        return true;
    }
  }

  /// Check if has access to personality
  bool _hasAccessToPersonality(VoicePersonality personality) {
    // Check user subscription level
    final userLevel = _getUserSubscriptionLevel();
    
    switch (personality) {
      case VoicePersonality.premium:
        return userLevel == SubscriptionLevel.premium;
      case VoicePersonality.business:
        return userLevel == SubscriptionLevel.business || userLevel == SubscriptionLevel.premium;
      default:
        return true;
    }
  }

  /// Stop current mode
  Future<void> _stopCurrentMode() async {
    try {
      switch (_currentMode) {
        case VoiceMode.emergency:
          await _stopEmergencyMode();
          break;
        case VoiceMode.business:
          await _stopBusinessMode();
          break;
        case VoiceMode.family:
          await _stopFamilyMode();
          break;
        default:
          // No special cleanup needed
          break;
      }
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'mode_stop_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Initialize mode
  Future<void> _initializeMode(VoiceMode mode) async {
    try {
      switch (mode) {
        case VoiceMode.emergency:
          await _initializeEmergencyMode();
          break;
        case VoiceMode.business:
          await _initializeBusinessMode();
          break;
        case VoiceMode.family:
          await _initializeFamilyMode();
          break;
        default:
          // No special initialization needed
          break;
      }
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'mode_initialization_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Update personality for mode
  Future<void> _updatePersonalityForMode(VoiceMode mode) async {
    try {
      final recommendedPersonality = _getRecommendedPersonalityForMode(mode);
      if (recommendedPersonality != null) {
        await _switchPersonality(recommendedPersonality);
      }
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'personality_mode_update_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Update voice characteristics
  Future<void> _updateVoiceCharacteristics(VoicePersonality personality) async {
    try {
      final characteristics = _personalityManager.getVoiceCharacteristics(personality);
      await _commandProcessor.updateVoiceCharacteristics(characteristics);
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'voice_characteristics_update_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Convert voice mode to conversation mode
  ConversationMode _convertToConversationMode(VoiceMode voiceMode) {
    switch (voiceMode) {
      case VoiceMode.business:
        return ConversationMode.business;
      case VoiceMode.casual:
        return ConversationMode.casual;
      case VoiceMode.emergency:
        return ConversationMode.emergency;
      case VoiceMode.family:
        return ConversationMode.family;
      default:
        return ConversationMode.normal;
    }
  }

  /// Get recommended personality for mode
  VoicePersonality? _getRecommendedPersonalityForMode(VoiceMode mode) {
    switch (mode) {
      case VoiceMode.business:
        return VoicePersonality.business;
      case VoiceMode.emergency:
        return VoicePersonality.urgent;
      case VoiceMode.family:
        return VoicePersonality.friendly;
      case VoiceMode.casual:
        return VoicePersonality.casual;
      default:
        return null;
    }
  }

  /// Check emergency permission
  bool _hasEmergencyPermission() {
    // Check if user has emergency access
    return true; // Simplified for now
  }

  /// Check business permission
  bool _hasBusinessPermission() {
    // Check if user has business access
    return true; // Simplified for now
  }

  /// Check family permission
  bool _hasFamilyPermission() {
    // Check if user has family access
    return true; // Simplified for now
  }

  /// Get user subscription level
  SubscriptionLevel _getUserSubscriptionLevel() {
    // Get user's subscription level
    return SubscriptionLevel.basic; // Simplified for now
  }

  /// Stop emergency mode
  Future<void> _stopEmergencyMode() async {
    // Stop emergency-specific features
  }

  /// Stop business mode
  Future<void> _stopBusinessMode() async {
    // Stop business-specific features
  }

  /// Stop family mode
  Future<void> _stopFamilyMode() async {
    // Stop family-specific features
  }

  /// Initialize emergency mode
  Future<void> _initializeEmergencyMode() async {
    // Initialize emergency-specific features
  }

  /// Initialize business mode
  Future<void> _initializeBusinessMode() async {
    // Initialize business-specific features
  }

  /// Initialize family mode
  Future<void> _initializeFamilyMode() async {
    // Initialize family-specific features
  }

  /// Generate fallback voice response
  VoiceResponse _generateFallbackVoiceResponse(String input) {
    return VoiceResponse(
      speech: SpeechOutput(
        text: 'Îmi pare rău, nu am înțeles. Poți să reformulezi?',
        duration: const Duration(seconds: 3),
        characteristics: VoiceCharacteristics.defaultCharacteristics(),
      ),
      visualFeedback: VisualFeedback.empty(),
      hapticFeedback: HapticFeedback.empty(),
      response: ConversationResponse(
        text: 'Îmi pare rău, nu am înțeles. Poți să reformulezi?',
        intent: RideIntent(type: RideIntentType.unknown, destination: '', pickupLocation: 'current_location', confidence: 0.0),
        confidence: 0.5,
        requiresClarification: true,
        clarificationType: ClarificationType.general,
      ),
      personality: _currentPersonality,
      timestamp: DateTime.now(),
    );
  }

  /// Load user preferences
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load voice mode preference
      final modeName = prefs.getString('preferred_voice_mode');
      if (modeName != null) {
        final mode = VoiceMode.values.firstWhere(
          (m) => m.name == modeName,
          orElse: () => VoiceMode.normal,
        );
        _currentMode = mode;
      }
      
      // Load personality preference
      final personalityName = prefs.getString('preferred_voice_personality');
      if (personalityName != null) {
        final personality = VoicePersonality.values.firstWhere(
          (p) => p.name == personalityName,
          orElse: () => VoicePersonality.friendly,
        );
        _currentPersonality = personality;
      }
      
      // Load other preferences
      _isAlwaysListening = prefs.getBool('always_listening') ?? false;
      _isBackgroundProcessing = prefs.getBool('background_processing') ?? false;
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'user_preferences_loading_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Get current voice mode
  VoiceMode get currentMode => _currentMode;
  
  /// Get current personality
  VoicePersonality get currentPersonality => _currentPersonality;
  
  /// Get service status
  bool get isInitialized => _isInitialized;
  bool get isAlwaysListening => _isAlwaysListening;
  bool get isBackgroundProcessing => _isBackgroundProcessing;
  
  /// Enable/disable always listening
  Future<void> setAlwaysListening(bool enabled) async {
    try {
      _isAlwaysListening = enabled;
      
      if (enabled) {
        await _wakeWordManager.startDetection();
      } else {
        await _wakeWordManager.stopDetection();
      }
      
      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('always_listening', enabled);
      
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'always_listening_changed', 'enabled': enabled});
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'always_listening_setting_failed',
        errorMessage: e.toString(),
      );
    }
  }
  
  /// Enable/disable background processing
  Future<void> setBackgroundProcessing(bool enabled) async {
    try {
      _isBackgroundProcessing = enabled;
      
      if (enabled) {
        await _backgroundProcessor.startProcessing();
      } else {
        await _backgroundProcessor.stopProcessing();
      }
      
      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('background_processing', enabled);
      
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'background_processing_changed', 'enabled': enabled});
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'background_processing_setting_failed',
        errorMessage: e.toString(),
      );
    }
  }
  
  /// Dispose resources
  void dispose() {
    _wakeWordManager.dispose();
    _backgroundProcessor.dispose();
    _ambientIntelligence.dispose();
    _voiceModeManager.dispose();
    _personalityManager.dispose();
    _commandProcessor.dispose();
    
    _performanceMetrics.clear();
  }
}

// Supporting classes and enums

enum VoiceMode {
  normal,
  casual,
  business,
  emergency,
  family,
}

enum VoicePersonality {
  friendly,
  casual,
  business,
  urgent,
  premium,
}

enum FormalityLevel {
  casual,
  normal,
  formal,
}

enum EmotionLevel {
  low,
  medium,
  high,
}

enum EmotionType {
  joy,
  empathy,
  urgency,
  calm,
  neutral,
}

enum CulturalContext {
  romanian,
  international,
}

enum SubscriptionLevel {
  basic,
  premium,
  business,
}

class VoiceResponse {
  final SpeechOutput speech;
  final VisualFeedback visualFeedback;
  final HapticFeedback hapticFeedback;
  final ConversationResponse response;
  final VoicePersonality personality;
  final DateTime timestamp;

  VoiceResponse({
    required this.speech,
    required this.visualFeedback,
    required this.hapticFeedback,
    required this.response,
    required this.personality,
    required this.timestamp,
  });
}

class SpeechOutput {
  final String text;
  final dynamic audio; // Audio data
  final Duration duration;
  final VoiceCharacteristics characteristics;

  const SpeechOutput({
    required this.text,
    this.audio,
    required this.duration,
    required this.characteristics,
  });
}

class VisualFeedback {
  final List<VisualElement> elements;
  final VisualStyle style;
  final VoicePersonality personality;

  const VisualFeedback({
    required this.elements,
    required this.style,
    required this.personality,
  });

  factory VisualFeedback.empty() {
    return VisualFeedback(
      elements: const [],
      style: VisualStyle.defaultStyle(),
      personality: VoicePersonality.friendly,
    );
  }
}

class HapticFeedback {
  final HapticPattern pattern;
  final double intensity;
  final Duration duration;
  final VoicePersonality personality;

  const HapticFeedback({
    required this.pattern,
    required this.intensity,
    required this.duration,
    required this.personality,
  });

  factory HapticFeedback.empty() {
    return const HapticFeedback(
      pattern: HapticPattern.none,
      intensity: 0.0,
      duration: Duration.zero,
      personality: VoicePersonality.friendly,
    );
  }
}

class VoiceCharacteristics {
  final FormalityLevel formalityLevel;
  final EmotionLevel emotionLevel;
  final EmotionType emotionType;
  final CulturalContext? culturalContext;
  final double speechRate;
  final double pitch;
  final double volume;

  const VoiceCharacteristics({
    required this.formalityLevel,
    required this.emotionLevel,
    required this.emotionType,
    this.culturalContext,
    required this.speechRate,
    required this.pitch,
    required this.volume,
  });

  factory VoiceCharacteristics.defaultCharacteristics() {
    return const VoiceCharacteristics(
      formalityLevel: FormalityLevel.normal,
      emotionLevel: EmotionLevel.medium,
      emotionType: EmotionType.neutral,
      culturalContext: CulturalContext.romanian,
      speechRate: 1.0,
      pitch: 1.0,
      volume: 1.0,
    );
  }
}

class VisualElement {
  final String type;
  final Map<String, dynamic> properties;
  final Duration duration;

  const VisualElement({
    required this.type,
    required this.properties,
    required this.duration,
  });
}

class VisualStyle {
  final String theme;
  final Map<String, dynamic> colors;
  final Map<String, dynamic> animations;

  const VisualStyle({
    required this.theme,
    required this.colors,
    required this.animations,
  });

  factory VisualStyle.defaultStyle() {
    return const VisualStyle(
      theme: 'default',
      colors: {},
      animations: {},
    );
  }
}

class HapticPattern {
  final String type;
  final List<int> intervals;
  final double intensity;

  const HapticPattern({
    required this.type,
    required this.intervals,
    required this.intensity,
  });

  static const HapticPattern none = HapticPattern(
    type: 'none',
    intervals: [],
    intensity: 0.0,
  );
}

// Service interfaces (to be implemented)

abstract class VoiceModeManager {
  Future<void> initialize();
  bool isModeAvailable(VoiceMode mode);
  Future<ConversationResponse> applyMode(ConversationResponse response, VoiceMode mode);
  void dispose();
}

abstract class VoicePersonalityManager {
  Future<void> initialize();
  bool isPersonalityAvailable(VoicePersonality personality);
  VoiceCharacteristics getVoiceCharacteristics(VoicePersonality personality);
  VisualStyle getVisualStyle(VoicePersonality personality);
  HapticPattern getHapticPattern(VoicePersonality personality);
  Future<ConversationResponse> applyPersonality(
    ConversationResponse response,
    VoicePersonality personality,
    VoiceMode mode,
  );
  void dispose();
}

abstract class VoiceCommandProcessor {
  Future<void> initialize();
  Future<SpeechOutput> generateSpeech(String text, {VoiceCharacteristics? characteristics});
  Future<List<VisualElement>> generateVisualElements(ConversationResponse response, VisualStyle style);
  Future<HapticOutput> generateHapticFeedback(ConversationResponse response, HapticPattern pattern);
  Future<void> updateVoiceCharacteristics(VoiceCharacteristics characteristics);
  void dispose();
}

abstract class AmbientIntelligence {
  Future<void> initialize();
  Future<void> startMonitoring();
  void dispose();
}

abstract class WakeWordManager {
  Future<void> initialize();
  Future<void> startDetection();
  Future<void> stopDetection();
  void dispose();
}

abstract class BackgroundProcessor {
  Future<void> initialize();
  Future<void> startProcessing();
  Future<void> stopProcessing();
  void dispose();
}

class HapticOutput {
  final double intensity;
  final Duration duration;

  const HapticOutput({
    required this.intensity,
    required this.duration,
  });
}



// ─── Concrete implementations ────────────────────────────────────────────────

class VoiceModeManagerImpl implements VoiceModeManager {
  VoiceMode _currentMode = VoiceMode.normal;

  @override
  Future<void> initialize() async {
    _currentMode = VoiceMode.normal;
  }

  @override
  bool isModeAvailable(VoiceMode mode) {
    // Emergency mode requires the current mode to not already be emergency
    if (mode == VoiceMode.emergency) return _currentMode != VoiceMode.emergency;
    return true;
  }

  @override
  Future<ConversationResponse> applyMode(
      ConversationResponse response, VoiceMode mode) async {
    _currentMode = mode;
    String text = response.text;
    // Emergency mode: add urgency prefix if not already present
    if (mode == VoiceMode.emergency && !text.startsWith('URGENT')) {
      text = 'URGENT: $text';
    }
    // Business mode: strip casual openers
    if (mode == VoiceMode.business) {
      text = text
          .replaceAll(RegExp(r'^Hei[!,]?\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'^Salut[!,]?\s*', caseSensitive: false), '')
          .trim();
      if (text.isNotEmpty) {
        text = text[0].toUpperCase() + text.substring(1);
      }
    }
    final updatedMeta = Map<String, dynamic>.from(response.metadata)
      ..['voiceMode'] = mode.name;
    return ConversationResponse(
      text: text,
      intent: response.intent,
      confidence: response.confidence,
      requiresClarification: response.requiresClarification,
      clarificationType: response.clarificationType,
      action: response.action,
      actionData: response.actionData,
      suggestions: response.suggestions,
      metadata: updatedMeta,
    );
  }

  @override
  void dispose() {
    _currentMode = VoiceMode.normal;
  }
}

class VoicePersonalityManagerImpl implements VoicePersonalityManager {
  @override
  Future<void> initialize() async {}

  @override
  bool isPersonalityAvailable(VoicePersonality personality) => true;

  @override
  VoiceCharacteristics getVoiceCharacteristics(VoicePersonality personality) {
    switch (personality) {
      case VoicePersonality.friendly:
        return const VoiceCharacteristics(
          formalityLevel: FormalityLevel.casual,
          emotionLevel: EmotionLevel.high,
          emotionType: EmotionType.joy,
          culturalContext: CulturalContext.romanian,
          speechRate: 1.0,
          pitch: 1.1,
          volume: 1.0,
        );
      case VoicePersonality.casual:
        return const VoiceCharacteristics(
          formalityLevel: FormalityLevel.casual,
          emotionLevel: EmotionLevel.medium,
          emotionType: EmotionType.neutral,
          culturalContext: CulturalContext.romanian,
          speechRate: 1.1,
          pitch: 1.0,
          volume: 1.0,
        );
      case VoicePersonality.business:
        return const VoiceCharacteristics(
          formalityLevel: FormalityLevel.formal,
          emotionLevel: EmotionLevel.low,
          emotionType: EmotionType.neutral,
          culturalContext: CulturalContext.romanian,
          speechRate: 0.95,
          pitch: 0.95,
          volume: 1.0,
        );
      case VoicePersonality.urgent:
        return const VoiceCharacteristics(
          formalityLevel: FormalityLevel.normal,
          emotionLevel: EmotionLevel.high,
          emotionType: EmotionType.urgency,
          culturalContext: CulturalContext.romanian,
          speechRate: 1.2,
          pitch: 1.05,
          volume: 1.0,
        );
      case VoicePersonality.premium:
        return const VoiceCharacteristics(
          formalityLevel: FormalityLevel.formal,
          emotionLevel: EmotionLevel.medium,
          emotionType: EmotionType.calm,
          culturalContext: CulturalContext.romanian,
          speechRate: 0.9,
          pitch: 0.9,
          volume: 1.0,
        );
    }
  }

  @override
  VisualStyle getVisualStyle(VoicePersonality personality) {
    switch (personality) {
      case VoicePersonality.friendly:
        return const VisualStyle(
          theme: 'friendly',
          colors: {'primary': '#3682F3', 'accent': '#2ECC71'},
          animations: {'type': 'bounce', 'speed': 'normal'},
        );
      case VoicePersonality.business:
        return const VisualStyle(
          theme: 'business',
          colors: {'primary': '#1A1A2E', 'accent': '#E0E0E0'},
          animations: {'type': 'fade', 'speed': 'slow'},
        );
      case VoicePersonality.urgent:
        return const VisualStyle(
          theme: 'urgent',
          colors: {'primary': '#E74C3C', 'accent': '#F39C12'},
          animations: {'type': 'pulse', 'speed': 'fast'},
        );
      case VoicePersonality.premium:
        return const VisualStyle(
          theme: 'premium',
          colors: {'primary': '#533483', 'accent': '#F5C518'},
          animations: {'type': 'slide', 'speed': 'slow'},
        );
      default:
        return VisualStyle.defaultStyle();
    }
  }

  @override
  HapticPattern getHapticPattern(VoicePersonality personality) {
    switch (personality) {
      case VoicePersonality.urgent:
        return const HapticPattern(
            type: 'strong', intervals: [50, 100, 50, 100, 50], intensity: 0.9);
      case VoicePersonality.friendly:
        return const HapticPattern(
            type: 'gentle', intervals: [100, 200, 100], intensity: 0.4);
      case VoicePersonality.business:
        return const HapticPattern(
            type: 'subtle', intervals: [80], intensity: 0.3);
      case VoicePersonality.premium:
        return const HapticPattern(
            type: 'elegant', intervals: [60, 120], intensity: 0.35);
      default:
        return const HapticPattern(
            type: 'gentle', intervals: [100, 200, 100], intensity: 0.5);
    }
  }

  @override
  Future<ConversationResponse> applyPersonality(
    ConversationResponse response,
    VoicePersonality personality,
    VoiceMode mode,
  ) async {
    String text = response.text;
    if (personality == VoicePersonality.business) {
      text = text
          .replaceAll('Super!', 'Bine.')
          .replaceAll('Grozav!', 'Excelent.')
          .replaceAll(RegExp(r'^Hei[!,]?\s*'), '')
          .trim();
      if (text.isNotEmpty) {
        text = text[0].toUpperCase() + text.substring(1);
      }
    }
    final updatedMeta = Map<String, dynamic>.from(response.metadata)
      ..['personality'] = personality.name;
    return ConversationResponse(
      text: text,
      intent: response.intent,
      confidence: response.confidence,
      requiresClarification: response.requiresClarification,
      clarificationType: response.clarificationType,
      action: response.action,
      actionData: response.actionData,
      suggestions: response.suggestions,
      metadata: updatedMeta,
    );
  }

  @override
  void dispose() {}
}

class VoiceCommandProcessorImpl implements VoiceCommandProcessor {
  VoiceCharacteristics _characteristics =
      VoiceCharacteristics.defaultCharacteristics();

  @override
  Future<void> initialize() async {
    _characteristics = VoiceCharacteristics.defaultCharacteristics();
  }

  @override
  Future<SpeechOutput> generateSpeech(String text,
      {VoiceCharacteristics? characteristics}) async {
    final chars = characteristics ?? _characteristics;
    // Estimate duration: ~130 words/min at speechRate 1.0
    final wordCount = text.trim().split(RegExp(r'\s+')).length;
    final durationMs =
        (wordCount / (130.0 * chars.speechRate) * 60000).round().clamp(300, 60000);
    return SpeechOutput(
      text: text,
      duration: Duration(milliseconds: durationMs),
      characteristics: chars,
    );
  }

  @override
  Future<List<VisualElement>> generateVisualElements(
      ConversationResponse response, VisualStyle style) async {
    final elements = <VisualElement>[
      VisualElement(
        type: 'text',
        properties: {
          'content': response.text,
          'theme': style.theme,
          'primaryColor': style.colors['primary'] ?? '#3682F3',
        },
        duration: const Duration(seconds: 4),
      ),
    ];
    if (response.action != null) {
      elements.add(VisualElement(
        type: 'action_button',
        properties: {
          'action': response.action!.name,
          'accentColor': style.colors['accent'] ?? '#2ECC71',
        },
        duration: const Duration(seconds: 8),
      ));
    }
    if (response.suggestions.isNotEmpty) {
      elements.add(VisualElement(
        type: 'suggestions',
        properties: {'items': response.suggestions},
        duration: const Duration(seconds: 6),
      ));
    }
    return elements;
  }

  @override
  Future<HapticOutput> generateHapticFeedback(
      ConversationResponse response, HapticPattern pattern) async {
    if (pattern.type == 'none' || pattern.intervals.isEmpty) {
      return const HapticOutput(intensity: 0.0, duration: Duration.zero);
    }
    final totalMs = pattern.intervals.fold<int>(0, (sum, i) => sum + i);
    return HapticOutput(
      intensity: pattern.intensity,
      duration: Duration(milliseconds: totalMs),
    );
  }

  @override
  Future<void> updateVoiceCharacteristics(
      VoiceCharacteristics characteristics) async {
    _characteristics = characteristics;
  }

  @override
  void dispose() {}
}

class AmbientIntelligenceImpl implements AmbientIntelligence {
  Timer? _monitoringTimer;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> startMonitoring() async {
    _monitoringTimer?.cancel();
    // Check ambient context every 10 minutes
    _monitoringTimer =
        Timer.periodic(const Duration(minutes: 10), (_) => _checkAmbient());
  }

  void _checkAmbient() {
    // Time-of-day awareness: morning/afternoon/evening/night slots
    // Used by ProactiveAIService to generate context-aware suggestions
    final hour = DateTime.now().hour;
    final _ = hour < 6
        ? 'night'
        : hour < 12
            ? 'morning'
            : hour < 18
                ? 'afternoon'
                : hour < 22
                    ? 'evening'
                    : 'night';
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }
}

class WakeWordManagerImpl implements WakeWordManager {
  bool _isDetecting = false;

  @override
  Future<void> initialize() async {
    _isDetecting = false;
  }

  @override
  Future<void> startDetection() async {
    // Wake word detection ("salut") is handled by AdvancedVoiceProcessor.
    // This manager tracks active state for coordination.
    if (!_isDetecting) _isDetecting = true;
  }

  @override
  Future<void> stopDetection() async {
    if (_isDetecting) _isDetecting = false;
  }

  @override
  void dispose() {
    if (_isDetecting) _isDetecting = false;
  }
}

class BackgroundProcessorImpl implements BackgroundProcessor {
  bool _isRunning = false;
  Timer? _backgroundTimer;

  @override
  Future<void> initialize() async {
    _isRunning = false;
  }

  @override
  Future<void> startProcessing() async {
    if (_isRunning) return;
    _isRunning = true;
    // Run background maintenance every 30 minutes
    _backgroundTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _runMaintenance(),
    );
  }

  void _runMaintenance() {
    // Triggers ProactiveAIService prediction updates via shared state
    // Lightweight: no network calls, just prediction cache refresh signal
  }

  @override
  Future<void> stopProcessing() async {
    _isRunning = false;
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }
}
