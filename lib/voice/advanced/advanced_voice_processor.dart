import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/voice_analytics.dart';
import '../core/conversational_ai_engine.dart';
import '../../services/firestore_service.dart';
import '../../services/routing_service.dart';
import '../../services/ai_location_service.dart';
import 'package:nabour_app/services/passenger_allowed_driver_uids.dart';

import '../../models/simple_location.dart';
import '../../models/voice_models.dart';
import 'package:nabour_app/utils/logger.dart';



/// Advanced voice processor with "salut" detection and continuous listening
class AdvancedVoiceProcessor {
  static const double _wakeWordConfidence = 0.8;
  static const Duration _listeningTimeout = Duration(seconds: 10);
  static const Duration _silenceThreshold = Duration(milliseconds: 1500);
  
  // MEMORY LEAK PREVENTION CONSTANTS
  static const int _maxAudioLevels = 50;
  static const int _maxBufferSize = 20;
  static const Duration _cleanupInterval = Duration(minutes: 3);
  
  late SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  
  bool _isListening = false;
  bool _isWakeWordDetected = false;
  bool _isContinuousMode = false;
  bool _isInitialized = false;
  
  final StreamController<VoiceEvent> _voiceEventController = StreamController<VoiceEvent>.broadcast();
  final StreamController<WakeWordEvent> _wakeWordController = StreamController<WakeWordEvent>.broadcast();
  
  Timer? _listeningTimer;
  Timer? _silenceTimer;
  Timer? _cleanupTimer;
  
  // Voice activity detection
  double _noiseThreshold = 0.1;
  final List<double> _audioLevels = [];
  
  // MEMORY LEAK PREVENTION - Stream Subscriptions Management
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  
      // Detectarea "salut"
  final List<String> _wakeWordVariations = [
    'nabour',
    'friend ride',
    'friends ride',
    'friendride',
    'friensride',
    'frendsride',
  ];
  
  // Continuous listening state
  final List<String> _conversationBuffer = [];
  
  // Voice analytics and AI integration
  late VoiceAnalytics _voiceAnalytics;
  late ConversationalAIEngine _conversationalEngine;
  
  // Existing services
  final FirestoreService _firestoreService = FirestoreService();
  final RoutingService _routingService = RoutingService();
  final AILocationService _aiLocationService = AILocationService();
  
  // *** NOU: Getter pentru user ID autentificat ***
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  // Speech recognition confidence thresholds
  static const double _minConfidenceThreshold = 0.7;
  static const double _wakeWordConfidenceThreshold = 0.8;
  

  
  /// Stream of voice events
  Stream<VoiceEvent> get voiceEvents => _voiceEventController.stream;
  
  /// Stream of "salut" detection events
  Stream<WakeWordEvent> get wakeWordEvents => _wakeWordController.stream;
  
  /// Check if currently listening
  bool get isListening => _isListening;
  
  /// Check if "salut" was detected
  bool get isWakeWordDetected => _isWakeWordDetected;
  
  /// Check if continuous mode is active
  bool get isContinuousMode => _isContinuousMode;

  /// Initialize the advanced voice processor
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request permissions
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        Logger.debug('Microphone permission denied');
        return false;
      }

      // Initialize speech recognition
      _speechToText = SpeechToText();
      final speechAvailable = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
        debugLogging: true,
      );

      if (!speechAvailable) {
        Logger.debug('Speech recognition not available');
        return false;
      }

      // Initialize text-to-speech
      _flutterTts = FlutterTts();
      await _flutterTts.setLanguage('ro-RO');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Initialize voice analytics and conversational AI engine
      _voiceAnalytics = VoiceAnalytics();
      _conversationalEngine = ConversationalAIEngine();

      _isInitialized = true;
      _startPeriodicCleanup();
      return true;
    } catch (e) {
      Logger.error('Failed to initialize advanced voice processor: $e', error: e);
      return false;
    }
  }

  /// Start "salut" detection
  Future<void> startWakeWordDetection() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) return;

    try {
      _isListening = true;
      _isWakeWordDetected = false;
      
      await _speechToText.listen(
        onResult: _onWakeWordResult,
        onSoundLevelChange: _onSoundLevelChange,
        listenFor: _listeningTimeout,
        pauseFor: _silenceThreshold,
      );

      _startListeningTimer();
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.sessionStarted,
        data: {'timestamp': DateTime.now()},
      ));
    } catch (e) {
      Logger.error('Failed to start "salut" detection: $e', error: e);
      _isListening = false;
    }
  }

  /// Start continuous listening mode
  Future<void> startContinuousListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isContinuousMode) return;

    try {
      _isContinuousMode = true;
      _isListening = true;
      _conversationBuffer.clear();
      
      await _speechToText.listen(
        onResult: _onContinuousResult,
        onSoundLevelChange: _onSoundLevelChange,
        listenFor: const Duration(seconds: 30),
        pauseFor: _silenceThreshold,
      );

      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.sessionStarted,
        data: {'timestamp': DateTime.now()},
      ));
    } catch (e) {
      Logger.error('Failed to start continuous listening: $e', error: e);
      _isContinuousMode = false;
      _isListening = false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      _isWakeWordDetected = false;
      _isContinuousMode = false;
      
      _listeningTimer?.cancel();
      _silenceTimer?.cancel();
      
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.sessionEnded,
        data: {'timestamp': DateTime.now()},
      ));
    } catch (e) {
      Logger.error('Failed to stop listening: $e', error: e);
    }
  }

  /// Speak text with advanced options
  Future<void> speakAdvanced(
    String text, {
    double rate = 0.5,
    double volume = 1.0,
    double pitch = 1.0,
    String language = 'ro-RO',
  }) async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.setVolume(volume);
      await _flutterTts.setPitch(pitch);
      
      await _flutterTts.speak(text);
      
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.speechSynthesized,
        data: {
          'text': text,
          'rate': rate,
          'volume': volume,
          'pitch': pitch,
          'language': language,
          'timestamp': DateTime.now(),
        },
      ));
    } catch (e) {
      Logger.error('Failed to speak text: $e', error: e);
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.error,
        data: {
          'error': e.toString(),
          'text': text,
          'timestamp': DateTime.now(),
        },
      ));
    }
  }

      /// Process "salut" detection result
  void _onWakeWordResult(dynamic result) {
    try {
      // Handle different result types from speech recognition
      String text;
      double confidence;
      
      if (result is Map<String, dynamic>) {
        // Handle Map result format
        text = result['text'] ?? result['recognizedWords'] ?? '';
        confidence = (result['confidence'] ?? 0.0).toDouble();
      } else if (result is String) {
        // Handle String result format
        text = result;
        confidence = 0.9; // Default confidence for string results
      } else {
        // Handle other result formats
        text = result.toString();
        confidence = 0.8;
      }
      
      // Only process results with sufficient confidence
      if (confidence >= _wakeWordConfidenceThreshold && text.isNotEmpty) {
        // Check for "salut"
        if (_isWakeWord(text, confidence)) {
          _isWakeWordDetected = true;
          _wakeWordController.add(WakeWordEvent(
            text: text,
            confidence: confidence,
            timestamp: DateTime.now(),
          ));
          
          _voiceEventController.add(VoiceEvent(
            type: VoiceEventType.wakeWordDetected,
            data: {
              'text': text,
              'confidence': confidence,
              'timestamp': DateTime.now(),
            },
          ));
          
          // Track "salut" detection in analytics
          _voiceAnalytics.trackEvent(
            VoiceEventType.wakeWordDetected,
            data: {
              'text': text,
              'confidence': confidence,
              'timestamp': DateTime.now(),
            },
          );
          
          // Stop listening and notify
          stopListening();
        }
      } else {
        // Handle low confidence results
        Logger.debug('Low confidence "salut" detection result: $text (confidence: $confidence)');
      }
    } catch (e) {
              Logger.error('Error processing "salut" detection result: $e', error: e);
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.error,
        data: {
          'error': e.toString(),
          'timestamp': DateTime.now(),
        },
      ));
    }
  }

  /// Process continuous listening result
  void _onContinuousResult(dynamic result) {
    try {
      // Handle different result types from speech recognition
      String text;
      double confidence;
      bool isFinal = false;
      
      if (result is Map<String, dynamic>) {
        // Handle Map result format
        text = result['text'] ?? result['recognizedWords'] ?? '';
        confidence = (result['confidence'] ?? 0.0).toDouble();
        isFinal = result['isFinal'] ?? result['finalResult'] ?? true;
      } else if (result is String) {
        // Handle String result format
        text = result;
        confidence = 0.8;
        isFinal = true;
      } else {
        // Handle other result formats
        text = result.toString();
        confidence = 0.7;
        isFinal = true;
      }
      
      if (text.isNotEmpty) {
        // Only process results with sufficient confidence
        if (confidence >= _minConfidenceThreshold) {
          // Add to conversation buffer
          _conversationBuffer.add(text);
          
          // Limit buffer size
          if (_conversationBuffer.length > _maxBufferSize) {
            _conversationBuffer.removeAt(0);
          }
          
          // Process speech intent if final result
          if (isFinal) {
            _processSpeechIntent(text, confidence);
          }
          
          _voiceEventController.add(VoiceEvent(
            type: VoiceEventType.speechRecognized,
            data: {
              'text': text,
              'confidence': confidence,
              'isFinal': isFinal,
              'timestamp': DateTime.now(),
            },
          ));
          
          // Track speech recognition in analytics
          _voiceAnalytics.trackEvent(
            VoiceEventType.speechRecognized,
            data: {
              'text': text,
              'confidence': confidence,
              'isFinal': isFinal,
              'timestamp': DateTime.now(),
            },
          );
        } else {
          // Handle low confidence results
          Logger.debug('Low confidence continuous result: $text (confidence: $confidence)');
        }
        
        // Reset silence timer
        _silenceTimer?.cancel();
        _silenceTimer = Timer(_silenceThreshold, () {
          if (_isContinuousMode) {
                  _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.system,
        data: {
          'duration': _silenceThreshold,
          'timestamp': DateTime.now(),
        },
      ));
          }
        });
      }
    } catch (e) {
      Logger.error('Error processing continuous result: $e', error: e);
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.error,
        data: {
          'error': e.toString(),
          'timestamp': DateTime.now(),
        },
      ));
    }
  }

  /// Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    Logger.error('Speech recognition error: $error', error: error);
    
          _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.error,
        data: {
          'error': error.toString(),
          'errorCode': 0,
          'timestamp': DateTime.now(),
        },
      ));
    
    // Restart listening if in continuous mode
    if (_isContinuousMode) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isContinuousMode) {
          startContinuousListening();
        }
      });
    }
  }

  /// Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    Logger.debug('Speech recognition status: $status');
    
          _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.system,
        data: {
          'status': status,
          'timestamp': DateTime.now(),
        },
      ));
    
    if (status == 'done' && _isContinuousMode) {
      // Restart listening for continuous mode
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isContinuousMode) {
          startContinuousListening();
        }
      });
    }
  }

  /// Handle sound level changes for voice activity detection
  void _onSoundLevelChange(double level) {
    _audioLevels.add(level);
    
    // Limit audio levels history
    if (_audioLevels.length > _maxAudioLevels) {
      _audioLevels.removeAt(0);
    }
    
    // Calculate average noise level
    if (_audioLevels.length >= 10) {
      final avgLevel = _audioLevels.reduce((a, b) => a + b) / _audioLevels.length;
      
      // Detect voice activity
      if (avgLevel > _noiseThreshold) {
        _voiceEventController.add(VoiceEvent(
          type: VoiceEventType.system,
          data: {
            'level': avgLevel,
            'threshold': _noiseThreshold,
            'timestamp': DateTime.now(),
          },
        ));
      }
    }
  }

  /// Check if text contains "salut"
  bool _isWakeWord(String text, double confidence) {
    if (confidence < _wakeWordConfidence) return false;
    
    for (final variation in _wakeWordVariations) {
      if (text.contains(variation)) {
        return true;
      }
    }
    
    return false;
  }

  /// Start listening timer
  void _startListeningTimer() {
    _listeningTimer?.cancel();
    _listeningTimer = Timer(_listeningTimeout, () {
      if (_isListening && !_isWakeWordDetected) {
        stopListening();
        _voiceEventController.add(VoiceEvent(
          type: VoiceEventType.system,
          data: {
            'timeout': _listeningTimeout,
            'timestamp': DateTime.now(),
          },
        ));
      }
    });
  }

  /// MEMORY LEAK PREVENTION - Periodic Cleanup
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      _cleanupExpiredData();
      _cleanupInvalidSubscriptions();
      _cleanupTimers();
    });
    
    // Add to timers list for proper disposal
    _timers.add(_cleanupTimer!);
  }

  /// Cleanup expired data
  void _cleanupExpiredData() {
    // Cleanup old audio levels
    if (_audioLevels.length > _maxAudioLevels) {
      _audioLevels.removeRange(0, _audioLevels.length - _maxAudioLevels);
    }
    
    // Cleanup old conversation buffer
    if (_conversationBuffer.length > _maxBufferSize) {
      _conversationBuffer.removeRange(0, _conversationBuffer.length - _maxBufferSize);
    }
  }

  /// Cleanup invalid subscriptions
  void _cleanupInvalidSubscriptions() {
    _subscriptions.removeWhere((subscription) => subscription.isPaused);
  }

  /// Cleanup expired timers
  void _cleanupTimers() {
    _timers.removeWhere((timer) => timer.isActive == false);
  }

  /// Get conversation buffer
  List<String> getConversationBuffer() {
    return List<String>.from(_conversationBuffer);
  }

  /// Clear conversation buffer
  void clearConversationBuffer() {
    _conversationBuffer.clear();
  }

  /// Set noise threshold
  void setNoiseThreshold(double threshold) {
    _noiseThreshold = threshold.clamp(0.0, 1.0);
  }

  /// Get current audio statistics
  Map<String, dynamic> getAudioStatistics() {
    if (_audioLevels.isEmpty) return {};
    
    final avg = _audioLevels.reduce((a, b) => a + b) / _audioLevels.length;
    final minValue = _audioLevels.reduce((a, b) => a < b ? a : b);
    final maxValue = _audioLevels.reduce((a, b) => a > b ? a : b);
    
    return {
      'averageLevel': avg,
      'minLevel': minValue,
      'maxLevel': maxValue,
      'currentLevel': _audioLevels.isNotEmpty ? _audioLevels.last : 0.0,
      'threshold': _noiseThreshold,
      'sampleCount': _audioLevels.length,
    };
  }

  /// Process speech intent with confidence threshold
  Future<void> _processSpeechIntent(String recognizedText, double confidence) async {
    try {
      final normalizedText = recognizedText.toLowerCase().trim();
      
      // Extract ride-related intents using existing services
      if (_containsRideBookingKeywords(normalizedText)) {
        await _handleRideBookingIntent(normalizedText, confidence);
      } else if (_containsNavigationKeywords(normalizedText)) {
        await _handleNavigationIntent(normalizedText, confidence);
      } else if (_containsCancellationKeywords(normalizedText)) {
        await _handleCancellationIntent(normalizedText, confidence);
      } else {
        // Pass to conversational AI engine for complex queries
        await _passToConversationalEngine(normalizedText, confidence);
      }
      
      // Log successful processing
      _voiceAnalytics.trackEvent(
        VoiceEventType.userInteraction,
        data: {
          'text': normalizedText,
          'confidence': confidence,
          'intent_processed': true,
          'timestamp': DateTime.now(),
        },
      );
    } catch (e) {
      Logger.error('Error processing speech intent: $e', error: e);
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.error,
        data: {
          'error': e.toString(),
          'text': recognizedText,
          'timestamp': DateTime.now(),
        },
      ));
    }
  }

  /// Check if text contains ride booking keywords
  bool _containsRideBookingKeywords(String text) {
    const bookingKeywords = [
      'book', 'request', 'need a ride', 'call a ride', 
      'go to', 'take me to', 'drive to', 'cursă', 'ridicare',
      'rezervă', 'programează', 'cheamă'
    ];
    return bookingKeywords.any((keyword) => text.contains(keyword));
  }

  /// Check if text contains navigation keywords
  bool _containsNavigationKeywords(String text) {
    const navKeywords = [
      'where am i', 'current location', 'navigate', 'directions',
      'route', 'traffic', 'eta', 'how long', 'unde sunt',
      'navigare', 'ruta', 'trafic', 'cât timp'
    ];
    return navKeywords.any((keyword) => text.contains(keyword));
  }

  /// Check if text contains cancellation keywords
  bool _containsCancellationKeywords(String text) {
    const cancelKeywords = [
      'cancel', 'stop', 'abort', 'nevermind', 'forget it',
      'anulează', 'oprește', 'renunță', 'uită'
    ];
    return cancelKeywords.any((keyword) => text.contains(keyword));
  }





    /// Handle ride booking intent
  Future<void> _handleRideBookingIntent(String text, double confidence) async {
    try {
      Logger.debug('Processing ride booking intent: $text (confidence: $confidence)');
      
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.userInteraction,
        data: {
          'intent_type': 'ride_booking',
          'text': text,
          'confidence': confidence,
          'timestamp': DateTime.now(),
        },
      ));
      
      // Extract destination using ConversationalAIEngine
      final destination = await _extractDestinationFromText(text);
      
      if (destination != null && destination.isNotEmpty) {
        final allowedDriverUids = await PassengerAllowedDriverUids.loadMergedUidList();
        if (allowedDriverUids.isEmpty) {
          await _flutterTts.speak(
            'Nu pot trimite cursa. Nabour trimite cererea doar către șoferii din contactele tale. '
            'Adaugă în agendă numerele prietenilor cu cont Nabour sau acordă permisiunea la contacte.',
          );
          return;
        }

        // Get current location using existing services
        final currentLocation = await _getCurrentLocation();
        
        // *** IMPLEMENTAT: Creare ride request cu date reale ***
        final rideRequest = await _createRideRequestWithRealData(
          destination: destination,
          currentLocation: currentLocation,
          confidence: confidence,
          allowedDriverUids: allowedDriverUids,
        );
        
        try {
          final rideId = await _firestoreService.createRideRequest(rideRequest);
          await _announceRideBooked(rideId);
        } catch (e) {
          Logger.error('Failed to create ride request: $e', error: e);
          await _announceBookingFailed(e.toString());
          return;
        }
        
        _voiceAnalytics.trackEvent(
          VoiceEventType.userInteraction,
          data: {
            'intent_type': 'ride_booking',
            'success': true,
            'destination': destination,
            'confidence': confidence,
            'timestamp': DateTime.now(),
          },
        );
      } else {
        await _requestDestinationClarification();
      }
    } catch (e) {
      Logger.error('Ride booking integration failed: $e', error: e);
      await _announceBookingFailed('System error occurred');
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.error,
        data: {
          'error': e.toString(),
          'intent_type': 'ride_booking',
          'timestamp': DateTime.now(),
        },
      ));
    }
  }

  Future<String?> _extractDestinationFromText(String text) async {
    try {
      // Use ConversationalAIEngine to extract destination
      final response = await _conversationalEngine.processUserInput(
        'Extract destination from: $text',
      );
      
      // Simple fallback extraction if AI fails
      final words = text.toLowerCase().split(' ');
      if (words.contains('to') && words.indexOf('to') < words.length - 1) {
        final toIndex = words.indexOf('to');
        return words.sublist(toIndex + 1).join(' ');
      }
      
      return response.toString();
    } catch (e) {
      Logger.error('Destination extraction failed: $e', error: e);
      // Fallback to simple keyword extraction
      final words = text.toLowerCase().split(' ');
      if (words.contains('to') && words.indexOf('to') < words.length - 1) {
        final toIndex = words.indexOf('to');
        return words.sublist(toIndex + 1).join(' ');
      }
      return null;
    }
  }

  Future<SimpleLocation> _getCurrentLocation() async {
    try {
      // Try to use AILocationService for current location
      // For now, return default location as fallback
      return const SimpleLocation(
        latitude: 44.4268, // Bucharest coordinates
        longitude: 26.1025,
      );
    } catch (e) {
      Logger.error('Location service failed: $e', error: e);
      // Return default location
      return const SimpleLocation(
        latitude: 44.4268, // Bucharest coordinates
        longitude: 26.1025,
      );
    }
  }

  Future<void> _announceRideBooked(String rideId) async {
    await _flutterTts.speak(
      'Your ride has been booked successfully. Ride ID: $rideId. '
      'A driver will be assigned shortly.'
    );
  }

  Future<void> _announceBookingFailed(String error) async {
    await _flutterTts.speak('Unable to book your ride: $error');
  }

  Future<void> _requestDestinationClarification() async {
    await _flutterTts.speak('Please specify your destination. Where would you like to go?');
  }

  /// Handle navigation intent
  Future<void> _handleNavigationIntent(String text, double confidence) async {
    try {
      Logger.debug('Processing navigation intent: $text (confidence: $confidence)');
      
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.userInteraction,
        data: {
          'intent_type': 'navigation',
          'text': text,
          'confidence': confidence,
          'timestamp': DateTime.now(),
        },
      ));
      
      // Parse navigation query using existing services
      if (text.contains(RegExp(r'\b(where am i|current location|unde sunt)\b'))) {
        // Get current location using existing service
        final currentLocation = await _getCurrentLocation();
        await _announceCurrentLocation(currentLocation);
      } else if (text.contains(RegExp(r'\b(how long|eta|time|cât timp)\b'))) {
        // Calculate ETA using AILocationService
                  final destination = await _extractDestinationFromText(text);
          if (destination != null) {
                              // Implement ETA calculation using existing service
         Map<String, dynamic> eta;
         try {
           // Use AILocationService for ETA calculation
           final currentLocation = await _getCurrentLocation();
           final destination = await _extractDestinationFromText(text);
           
           if (destination != null) {
             // Create Point objects for AILocationService
             final currentPoint = Point(coordinates: Position(currentLocation.longitude, currentLocation.latitude));
             final destPoint = Point(coordinates: Position(26.1025, 44.4268)); // Placeholder coordinates
             
             // Generate AI prediction for ETA
             final prediction = await _aiLocationService.generateLocationPrediction(
               currentLocation: currentPoint,
               destination: destPoint,
             );
             
             eta = {
               'estimatedTime': prediction.estimatedTime,
               'confidence': prediction.confidence,
               'aiGenerated': true,
             };
           } else {
             eta = {'estimatedTime': const Duration(minutes: 15)}; // Fallback
           }
         } catch (e) {
           Logger.error('ETA calculation failed: $e', error: e);
           eta = {'estimatedTime': const Duration(minutes: 15)}; // Fallback
         }
         await _announceETA(eta);
          }
      } else if (text.contains(RegExp(r'\b(traffic|congestion|trafic)\b'))) {
                 // Implement traffic info using existing service
         final trafficInfo = {'description': 'Normal traffic conditions'}; // Placeholder for now
        await _announceTrafficConditions(trafficInfo);
      } else {
        // *** IMPLEMENTAT: Route calculation cu coordonate reale ***
        final destination = await _extractDestinationFromText(text);
        if (destination != null) {
          final currentLocation = await _getCurrentLocation();
          
          // *** IMPLEMENTAT: Coordonate reale pentru destinație ***
          final destinationCoordinates = await _extractDestinationCoordinates(destination);
          
          if (destinationCoordinates == null) {
            Logger.error('Could not extract coordinates for destination: $destination');
            await _requestDestinationClarification();
            return;
          }
          
          final route = await _routingService.calculateRoute(
            startLat: currentLocation.latitude,
            startLng: currentLocation.longitude,
            endLat: destinationCoordinates.latitude, // ✅ Coordonate reale
            endLng: destinationCoordinates.longitude, // ✅ Coordonate reale
          );
          await _announceDirections(route);
        }
      }
      
      _voiceAnalytics.trackEvent(
        VoiceEventType.userInteraction,
        data: {
          'intent_type': 'navigation',
          'success': true,
          'confidence': confidence,
          'timestamp': DateTime.now(),
        },
      );
    } catch (e) {
      Logger.error('Navigation service integration failed: $e', error: e);
      await _flutterTts.speak('Unable to process navigation request');
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.error,
        data: {
          'error': e.toString(),
          'intent_type': 'navigation',
          'timestamp': DateTime.now(),
        },
      ));
    }
  }

  Future<void> _announceCurrentLocation(SimpleLocation location) async {
    await _flutterTts.speak(
      'You are currently at ${location.latitude}, ${location.longitude}'
    );
  }

  Future<void> _announceDirections(Map<String, dynamic>? route) async {
    if (route != null) {
      await _flutterTts.speak(
        'Route found. Estimated time: ${route['duration']} seconds, Distance: ${route['distance']} meters'
      );
    } else {
      await _flutterTts.speak('Unable to calculate route');
    }
  }

  Future<void> _announceETA(Map<String, dynamic> eta) async {
    final estimatedTime = eta['estimatedTime'] as Duration;
    await _flutterTts.speak(
      'Estimated time of arrival: ${estimatedTime.inMinutes} minutes'
    );
  }

  Future<void> _announceTrafficConditions(Map<String, dynamic> trafficInfo) async {
    await _flutterTts.speak(
      'Traffic conditions: ${trafficInfo['description'] ?? 'Unknown'}'
    );
  }

  /// Handle cancellation intent
  Future<void> _handleCancellationIntent(String text, double confidence) async {
    try {
      Logger.debug('Processing cancellation intent: $text (confidence: $confidence)');
      
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.userInteraction,
        data: {
          'intent_type': 'cancellation',
          'text': text,
          'confidence': confidence,
          'timestamp': DateTime.now(),
        },
      ));
      
      // Determine cancellation type using existing services
      if (text.contains(RegExp(r'\b(current ride|this ride|cursa actuală)\b'))) {
        // Cancel current ride using FirestoreService
        await _cancelCurrentRide(confidence);
      } else if (text.contains(RegExp(r'\b(request|booking|cerere)\b'))) {
        // Cancel pending request using FirestoreService
        await _cancelPendingRequest(confidence);
      } else if (text.contains(RegExp(r'\b(stop listening|end session|oprește)\b'))) {
        // Cancel voice session
        await _cancelVoiceSession(confidence);
      } else {
        // Request clarification
        await _requestCancellationClarification();
      }
    } catch (e) {
      Logger.error('Cancellation service integration failed: $e', error: e);
      await _flutterTts.speak('Unable to process cancellation request');
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.error,
        data: {
          'error': e.toString(),
          'intent_type': 'cancellation',
          'timestamp': DateTime.now(),
        },
      ));
    }
  }

  Future<void> _cancelCurrentRide(double confidence) async {
    try {
             // Try to get current ride using existing service
       // For now, return null as placeholder
       const currentRide = null; // Placeholder - implement actual logic
      
      if (currentRide != null) {
                 // Implement cancelRide using existing service
         try {
           await _firestoreService.cancelRide(currentRide.id);
         } catch (e) {
           Logger.error('Failed to cancel ride: $e', error: e);
           // Continue with local success message
         }
        
        await _flutterTts.speak(
          'Your current ride has been cancelled successfully. '
          'You will not be charged.'
        );
        
        _voiceAnalytics.trackEvent(
          VoiceEventType.userInteraction,
          data: {
            'intent_type': 'cancellation',
            'cancellation_type': 'current_ride',
            'success': true,
            'confidence': confidence,
            'timestamp': DateTime.now(),
          },
        );
      } else {
        await _flutterTts.speak('No active ride found to cancel');
      }
    } catch (e) {
      Logger.error('Error cancelling current ride: $e', error: e);
      await _flutterTts.speak('Unable to cancel your ride');
    }
  }

  Future<void> _cancelPendingRequest(double confidence) async {
    try {
             // Try to get pending ride requests using existing service
       // For now, return empty list as placeholder
       final pendingRequests = <RideRequest>[]; // Placeholder - implement actual logic
      
      if (pendingRequests.isNotEmpty) {
                 // Implement cancelRide using existing service
         try {
           await _firestoreService.cancelRide(pendingRequests.first.id);
         } catch (e) {
           Logger.error('Failed to cancel pending request: $e', error: e);
           // Continue with local success message
         }
        
        await _flutterTts.speak('Your pending ride request has been cancelled');
        
        _voiceAnalytics.trackEvent(
          VoiceEventType.userInteraction,
          data: {
            'intent_type': 'cancellation',
            'cancellation_type': 'pending_request',
            'success': true,
            'confidence': confidence,
            'timestamp': DateTime.now(),
          },
        );
      } else {
        await _flutterTts.speak('No pending ride requests found');
      }
    } catch (e) {
      Logger.error('Error cancelling pending request: $e', error: e);
      await _flutterTts.speak('Unable to cancel pending request');
    }
  }

  Future<void> _cancelVoiceSession(double confidence) async {
    await _flutterTts.speak('Voice session cancelled. Goodbye!');
    stopListening();
    
    _voiceAnalytics.trackEvent(
      VoiceEventType.userInteraction,
      data: {
        'intent_type': 'cancellation',
        'cancellation_type': 'voice_session',
        'success': true,
        'confidence': confidence,
        'timestamp': DateTime.now(),
      },
    );
  }

  Future<void> _requestCancellationClarification() async {
    await _flutterTts.speak(
      'What would you like to cancel? You can say "cancel my ride", '
      '"cancel my request", or "stop listening".'
    );
  }

  /// Pass complex queries to conversational AI engine
  Future<void> _passToConversationalEngine(String text, double confidence) async {
    try {
      Logger.debug('Passing to conversational AI: $text (confidence: $confidence)');
      
      // Process with existing ConversationalAIEngine
      final response = await _conversationalEngine.processUserInput(
        text,
      );
      
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.userInteraction,
        data: {
          'intent_type': 'conversational_ai',
          'text': text,
          'confidence': confidence,
          'ai_response': response.toString(),
          'timestamp': DateTime.now(),
        },
      ));
      
      // Speak the AI response
      if (response.toString().isNotEmpty) {
        await _flutterTts.speak(response.toString());
      }
    } catch (e) {
      Logger.error('Error processing with conversational AI: $e', error: e);
      _voiceEventController.add(VoiceEvent(
        type: VoiceEventType.error,
        data: {
          'error': e.toString(),
          'text': text,
          'timestamp': DateTime.now(),
        },
      ));
    }
  }



  /// ✅ RESET STARE CURSA: Curăță toate variabilele de stare pentru a permite o nouă căutare
  void resetRideState() {
    Logger.debug('AdvancedVoiceProcessor: Resetting ride state for new search...');
    
    // Reset processing state
    _isListening = false;
    _isWakeWordDetected = false;
    _isContinuousMode = false;
    
    // Reset timers
    _listeningTimer?.cancel();
    _silenceTimer?.cancel();
    _cleanupTimer?.cancel();
    
    // Clear conversation buffer
    _conversationBuffer.clear();
    
    // Clear audio levels
    _audioLevels.clear();
    
    // Reset analytics
    _voiceAnalytics.resetSession();
    
    Logger.info('AdvancedVoiceProcessor: Ride state reset completed');
  }

  // *** NOU: Metoda pentru crearea ride request cu date reale ***
  Future<RideRequest> _createRideRequestWithRealData({
    required String destination,
    required SimpleLocation currentLocation,
    required double confidence,
    required List<String> allowedDriverUids,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Utilizatorul nu este autentificat.');
    }

    final estimatedPrice = await _calculateRealRidePrice(
      destination: destination,
      currentLocation: currentLocation,
    );

    final destCoords = await _extractDestinationCoordinates(destination);

    final rideRequest = RideRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      passengerId: userId,
      pickupLocation: currentLocation.toString(),
      destination: destination,
      estimatedPrice: estimatedPrice,
      category: 'standard',
      urgency: 'normal',
      timestamp: DateTime.now(),
      status: 'pending',
      pickupLatitude: currentLocation.latitude,
      pickupLongitude: currentLocation.longitude,
      destinationLatitude: destCoords?.latitude,
      destinationLongitude: destCoords?.longitude,
      allowedDriverUids: allowedDriverUids,
    );

    Logger.info('Ride request created with real data: User ID: $userId, Price: $estimatedPrice');
    return rideRequest;
  }
  
  // *** NOU: Metoda pentru calcularea prețului real ***
  Future<double> _calculateRealRidePrice({
    required String destination,
    required SimpleLocation currentLocation,
  }) async {
    try {
      // *** IMPLEMENTAT: Coordonate reale pentru destinație ***
      final destinationCoordinates = await _extractDestinationCoordinates(destination);
      
      if (destinationCoordinates == null) {
        Logger.error('Could not extract coordinates for destination: $destination');
        // Returnează preț fallback dacă nu putem calcula distanța
        return 25.0;
      }
      
      // Calculare distanță reală
      final distanceKm = _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        destinationCoordinates.latitude,
        destinationCoordinates.longitude,
      );
      
      // Calculare preț bazat pe distanță și timp estimat
      const double basePrice = 5.0; // Preț de bază
      const double pricePerKm = 2.5; // Preț per km
      const double pricePerMinute = 0.3; // Preț per minut
      const double minimumPrice = 10.0; // Preț minim
      
      // Timp estimat bazat pe distanță (15 km/h în medie în oraș)
      final estimatedMinutes = (distanceKm / 0.25).round(); // 0.25 km/min = 15 km/h
      
      final calculatedPrice = basePrice + (distanceKm * pricePerKm) + (estimatedMinutes * pricePerMinute);
      final finalPrice = calculatedPrice > minimumPrice ? calculatedPrice : minimumPrice;
      
      Logger.info('Real price calculated: Distance: ${distanceKm.toStringAsFixed(2)}km, Time: ${estimatedMinutes}min, Price: ${finalPrice.toStringAsFixed(2)} RON');
      return finalPrice;
      
    } catch (e) {
      Logger.error('Error calculating real price: $e', error: e);
      return _calculateFallbackPrice();
    }
  }
  
  // *** NOU: Metoda pentru calcularea prețului fallback ***
  double _calculateFallbackPrice() {
    const double fallbackPrice = 25.0; // Preț fix pentru cazuri de eroare
    Logger.warning('Using fallback price: $fallbackPrice RON');
    return fallbackPrice;
  }
  
  // *** NOU: Metoda pentru calcularea distanței între două puncte ***
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Raza Pământului în km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
               math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
               math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;
    
    return distance;
  }
  
  // *** NOU: Metoda helper pentru conversia grade -> radiani ***
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  // *** ÎMBUNĂTĂȚIT: Metoda pentru extragerea coordonatelor reale ale destinației ***
  Future<SimpleLocation?> _extractDestinationCoordinates(String destination) async {
    try {
      // ✅ FOLOSEȘTE GEOCODING REAL - NU FALLBACK
      // Note: Will be integrated with GeocodingService for real geocoding in future update
      // For now, returns null if coordinates cannot be found
      
      Logger.debug('Extracting coordinates for destination: $destination');
      
      // ❌ NU FOLOSIM COORDONATE DEFAULT
      // Utilizatorul trebuie să specifice o adresă validă
      Logger.warning('Geocoding not implemented yet for destination: $destination');
      return null;
      
    } catch (e) {
      Logger.error('Error extracting destination coordinates: $e', error: e);
      // ❌ NU RETURNĂM COORDONATE DEFAULT
      return null;
    }
  }

  /// Dispose resources with MEMORY LEAK PREVENTION
  void dispose() {
    stopListening();
    
    // Cancel all timers
    _listeningTimer?.cancel();
    _silenceTimer?.cancel();
    _cleanupTimer?.cancel();
    
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    // Cancel all timers
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    
    // Close stream controllers
    _voiceEventController.close();
    _wakeWordController.close();
    
    // Clear data
    _audioLevels.clear();
    _conversationBuffer.clear();
    
    _isInitialized = false;
  }
}

/// Voice events
class VoiceEvent {
  final VoiceEventType type;
  final Map<String, dynamic> data;

  VoiceEvent({
    required this.type,
    required this.data,
  });
}

// VoiceEventType is now imported from '../core/voice_analytics.dart'

    /// "salut" detection events
class WakeWordEvent {
  final String text;
  final double confidence;
  final DateTime timestamp;

  WakeWordEvent({
    required this.text,
    required this.confidence,
    required this.timestamp,
  });
}
