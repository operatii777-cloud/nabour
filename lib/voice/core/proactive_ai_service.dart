import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cron/cron.dart';
import 'voice_analytics.dart';
import 'eco_integration_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Proactive AI Service for Nabour
/// Anticipates user needs and provides proactive transportation suggestions
class ProactiveAIService {
  static final ProactiveAIService _instance = ProactiveAIService._internal();
  factory ProactiveAIService() => _instance;
  ProactiveAIService._internal();

  // Core services
  late EcosystemIntegrationService _ecosystemService;
  
  // Learning and prediction
  late UserBehaviorAnalyzer _behaviorAnalyzer;
  late RoutineLearner _routineLearner;
  late PredictionEngine _predictionEngine;
  
  // Scheduling and notifications
  late Cron _scheduler;
  final Map<String, Timer> _activeTimers = {};
  final List<ScheduledTask> _scheduledTasks = [];
  
  // User patterns and preferences
  final Map<String, UserPattern> _userPatterns = {};
  final Map<String, Routine> _userRoutines = {};
  final Map<String, Preference> _userPreferences = {};
  
  // Configuration
  bool _isInitialized = false;
  bool _isEnabled = true;

  
  /// Initialize the proactive AI service
  Future<void> initialize() async {
    try {
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'proactive_ai_initialization_started'});
      
      // Initialize core services
      _ecosystemService = EcosystemIntegrationService();
      _behaviorAnalyzer = UserBehaviorAnalyzerImpl();
      _routineLearner = RoutineLearnerImpl();
      _predictionEngine = PredictionEngineImpl();
      
      // Initialize scheduler
      _scheduler = Cron();
      
      // Load user data and patterns
      await _loadUserData();
      
      // Initialize services
      await Future.wait([
        _behaviorAnalyzer.initialize(),
        _routineLearner.initialize(),
        _predictionEngine.initialize(),
      ]);
      
      // Start proactive monitoring
      await _startProactiveMonitoring();
      
      _isInitialized = true;
      
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'proactive_ai_initialization_completed'});
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'proactive_ai_initialization_failed',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Start proactive monitoring and scheduling
  Future<void> _startProactiveMonitoring() async {
    try {
      // Schedule daily routine checks
      _scheduleDailyRoutineChecks();
      
      // Schedule weather and traffic monitoring
      _scheduleWeatherTrafficMonitoring();
      
      // Schedule pattern analysis
      _schedulePatternAnalysis();
      
      // Start immediate proactive suggestions
      _startImmediateProactiveSuggestions();
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'proactive_monitoring_start_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Schedule daily routine checks
  void _scheduleDailyRoutineChecks() {
    // Morning routine check at 6:30 AM
    _scheduler.schedule(Schedule.parse('30 6 * * *'), () {
      _checkMorningRoutine();
    });
    
    // Evening routine check at 5:30 PM
    _scheduler.schedule(Schedule.parse('30 17 * * *'), () {
      _checkEveningRoutine();
    });
    
    // Weekend routine check at 9:00 AM
    _scheduler.schedule(Schedule.parse('0 9 * * 6,0'), () {
      _checkWeekendRoutine();
    });
  }

  /// Schedule weather and traffic monitoring
  void _scheduleWeatherTrafficMonitoring() {
    // Check weather every 2 hours
    _scheduler.schedule(Schedule.parse('0 */2 * * *'), () {
      _checkWeatherConditions();
    });
    
    // Check traffic during peak hours
    _scheduler.schedule(Schedule.parse('0 7,8,9,17,18,19 * * 1-5'), () {
      _checkTrafficConditions();
    });
  }

  /// Schedule pattern analysis
  void _schedulePatternAnalysis() {
    // Analyze patterns weekly on Sunday at 2:00 AM
    _scheduler.schedule(Schedule.parse('0 2 * * 0'), () {
      _analyzeUserPatterns();
    });
  }

  /// Start immediate proactive suggestions
  void _startImmediateProactiveSuggestions() {
    // Check for immediate opportunities
    Timer(const Duration(minutes: 5), () {
      _checkImmediateOpportunities();
    });
  }

  /// Check morning routine
  Future<void> _checkMorningRoutine() async {
    try {
      final currentTime = DateTime.now();
      final dayOfWeek = currentTime.weekday;
      
      // Only check on weekdays
      if (dayOfWeek >= 6) return;
      
      // Check if user has morning routine
      final morningRoutine = _getRoutineByType(RoutineType.morning);
      if (morningRoutine != null) {
        final suggestion = await _generateRoutineSuggestion(
          routine: morningRoutine,
          context: 'morning_commute',
          time: currentTime,
        );
        
        if (suggestion != null) {
          await _sendProactiveNotification(suggestion);
        }
      }
      
      // Check for calendar events that might need transportation
      final calendarSuggestions = await _getCalendarBasedSuggestions(currentTime);
      for (final suggestion in calendarSuggestions) {
        await _sendProactiveNotification(suggestion);
      }
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'morning_routine_check_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Check evening routine
  Future<void> _checkEveningRoutine() async {
    try {
      final currentTime = DateTime.now();
      final dayOfWeek = currentTime.weekday;
      
      // Only check on weekdays
      if (dayOfWeek >= 6) return;
      
      // Check if user has evening routine
      final eveningRoutine = _getRoutineByType(RoutineType.evening);
      if (eveningRoutine != null) {
        final suggestion = await _generateRoutineSuggestion(
          routine: eveningRoutine,
          context: 'evening_commute',
          time: currentTime,
        );
        
        if (suggestion != null) {
          await _sendProactiveNotification(suggestion);
        }
      }
      
      // Check for return transportation needs
      final returnSuggestions = await _getReturnTransportSuggestions(currentTime);
      for (final suggestion in returnSuggestions) {
        await _sendProactiveNotification(suggestion);
      }
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'evening_routine_check_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Check weekend routine
  Future<void> _checkWeekendRoutine() async {
    try {
      final currentTime = DateTime.now();
      
      // Check if user has weekend routine
      final weekendRoutine = _getRoutineByType(RoutineType.weekend);
      if (weekendRoutine != null) {
        final suggestion = await _generateRoutineSuggestion(
          routine: weekendRoutine,
          context: 'weekend_activity',
          time: currentTime,
        );
        
        if (suggestion != null) {
          await _sendProactiveNotification(suggestion);
        }
      }
      
      // Check for weekend-specific opportunities
      final weekendSuggestions = await _getWeekendSuggestions(currentTime);
      for (final suggestion in weekendSuggestions) {
        await _sendProactiveNotification(suggestion);
      }
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'weekend_routine_check_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Check weather conditions
  Future<void> _checkWeatherConditions() async {
    try {
      // Get user's current or last known location
      final userLocation = await _getUserLocation();
      if (userLocation == null) return;
      
      // Check weather conditions
      final weather = await _ecosystemService.weatherService.getCurrentWeather(userLocation);
      if (weather != null) {
        final weatherSuggestion = _generateWeatherBasedSuggestion(weather, userLocation);
        if (weatherSuggestion != null) {
          await _sendProactiveNotification(weatherSuggestion);
        }
      }
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'weather_condition_check_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Check traffic conditions
  Future<void> _checkTrafficConditions() async {
    try {
      // Get user's current or last known location
      final userLocation = await _getUserLocation();
      if (userLocation == null) return;
      
      // Check traffic conditions
      final traffic = await _ecosystemService.trafficService.getCurrentTraffic(userLocation);
      if (traffic != null && traffic.congestionLevel > 0.6) {
        final trafficSuggestion = _generateTrafficBasedSuggestion(traffic, userLocation);
        if (trafficSuggestion != null) {
          await _sendProactiveNotification(trafficSuggestion);
        }
      }
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'traffic_condition_check_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Check immediate opportunities
  Future<void> _checkImmediateOpportunities() async {
    try {
      final currentTime = DateTime.now();
      
      // Check for immediate transportation needs
      final immediateSuggestions = await _getImmediateSuggestions(currentTime);
      for (final suggestion in immediateSuggestions) {
        await _sendProactiveNotification(suggestion);
      }
      
      // Check for cost-saving opportunities
      final costSavingSuggestions = await _getCostSavingSuggestions(currentTime);
      for (final suggestion in costSavingSuggestions) {
        await _sendProactiveNotification(suggestion);
      }
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'immediate_opportunities_check_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Analyze user patterns
  Future<void> _analyzeUserPatterns() async {
    try {
      VoiceAnalytics().startPerformanceTimer('user_pattern_analysis');
      
      // Analyze transportation patterns
      await _behaviorAnalyzer.analyzeTransportationPatterns();
      
      // Learn new routines
      await _routineLearner.learnNewRoutines();
      
      // Update predictions
      await _predictionEngine.updatePredictions();
      
      // Save learned patterns
      await _saveUserPatterns();
      
      VoiceAnalytics().endPerformanceTimer('user_pattern_analysis');
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'user_patterns_analyzed'});
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'user_pattern_analysis_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Generate routine-based suggestion
  Future<ProactiveSuggestion?> _generateRoutineSuggestion({
    required Routine routine,
    required String context,
    required DateTime time,
  }) async {
    try {
      // Check if routine should be triggered
      if (!_shouldTriggerRoutine(routine, time)) {
        return null;
      }
      
      // Generate suggestion based on routine type
      switch (routine.type) {
        case RoutineType.morning:
          return _generateMorningRoutineSuggestion(routine, context, time);
        case RoutineType.evening:
          return _generateEveningRoutineSuggestion(routine, context, time);
        case RoutineType.weekend:
          return _generateWeekendRoutineSuggestion(routine, context, time);
        case RoutineType.custom:
          return _generateCustomRoutineSuggestion(routine, context, time);
      }
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'routine_suggestion_generation_failed',
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Generate morning routine suggestion
  ProactiveSuggestion _generateMorningRoutineSuggestion(
    Routine routine,
    String context,
    DateTime time,
  ) {
    final destination = routine.destination ?? 'muncă';
    final urgency = _calculateRoutineUrgency(routine, time);
    
    return ProactiveSuggestion(
      type: SuggestionType.routine,
      title: 'Rutina de dimineață',
      description: 'E timpul să pleci la $destination. Să rezervi taxi?',
      relevanceScore: 0.9,
      action: SuggestionAction.bookRide,
      actionData: {
        'pickup': 'acasă',
        'destination': destination,
        'urgency': urgency,
        'routineId': routine.id,
        'context': context,
      },
      priority: _getPriorityFromUrgency(urgency),
      expiresAt: time.add(const Duration(minutes: 30)),
    );
  }

  /// Generate evening routine suggestion
  ProactiveSuggestion _generateEveningRoutineSuggestion(
    Routine routine,
    String context,
    DateTime time,
  ) {
    final pickup = routine.pickup ?? 'muncă';
    final destination = routine.destination ?? 'acasă';
    final urgency = _calculateRoutineUrgency(routine, time);
    
    return ProactiveSuggestion(
      type: SuggestionType.routine,
      title: 'Rutina de seară',
      description: 'E timpul să pleci de la $pickup. Să rezervi taxi pentru acasă?',
      relevanceScore: 0.9,
      action: SuggestionAction.bookRide,
      actionData: {
        'pickup': pickup,
        'destination': destination,
        'urgency': urgency,
        'routineId': routine.id,
        'context': context,
      },
      priority: _getPriorityFromUrgency(urgency),
      expiresAt: time.add(const Duration(minutes: 30)),
    );
  }

  /// Generate weekend routine suggestion
  ProactiveSuggestion _generateWeekendRoutineSuggestion(
    Routine routine,
    String context,
    DateTime time,
  ) {
    final destination = routine.destination ?? 'centru';
    final urgency = _calculateRoutineUrgency(routine, time);
    
    return ProactiveSuggestion(
      type: SuggestionType.routine,
      title: 'Rutina de weekend',
      description: 'E weekend! Să rezervi taxi pentru $destination?',
      relevanceScore: 0.8,
      action: SuggestionAction.bookRide,
      actionData: {
        'pickup': 'acasă',
        'destination': destination,
        'urgency': urgency,
        'routineId': routine.id,
        'context': context,
      },
      priority: _getPriorityFromUrgency(urgency),
      expiresAt: time.add(const Duration(hours: 2)),
    );
  }

  /// Generate custom routine suggestion
  ProactiveSuggestion _generateCustomRoutineSuggestion(
    Routine routine,
    String context,
    DateTime time,
  ) {
    final title = routine.name;
    final description = routine.description;
    final urgency = _calculateRoutineUrgency(routine, time);
    
    return ProactiveSuggestion(
      type: SuggestionType.routine,
      title: title,
      description: description ?? '',
      relevanceScore: 0.8,
      action: SuggestionAction.bookRide,
      actionData: {
        'pickup': routine.pickup ?? '',
        'destination': routine.destination ?? '',
        'urgency': urgency,
        'routineId': routine.id,
        'context': context,
      },
      priority: _getPriorityFromUrgency(urgency),
      expiresAt: time.add(const Duration(minutes: 30)),
    );
  }

  /// Generate weather-based suggestion
  ProactiveSuggestion? _generateWeatherBasedSuggestion(
    WeatherInfo weather,
    String location,
  ) {
    if (weather.condition.contains('rain') || weather.condition.contains('snow')) {
      return ProactiveSuggestion(
        type: SuggestionType.weather,
        title: 'Vreme rea - transport alternativ',
        description: 'Plouă/ninge în $location. Vrei să rezervi taxi?',
        relevanceScore: 0.8,
        action: SuggestionAction.bookRide,
        actionData: {
          'urgency': 'medium',
          'reason': 'vreme_rea',
          'weather': weather.condition,
          'location': location,
        },
        priority: SuggestionPriority.medium,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
    }
    
    if (weather.temperature < -5 || weather.temperature > 35) {
      return ProactiveSuggestion(
        type: SuggestionType.weather,
        title: 'Temperatură extremă',
        description: 'Temperatura este ${weather.temperature}°C în $location. Vrei să rezervi taxi?',
        relevanceScore: 0.7,
        action: SuggestionAction.bookRide,
        actionData: {
          'urgency': 'medium',
          'reason': 'temperatură_extremă',
          'temperature': weather.temperature,
          'location': location,
        },
        priority: SuggestionPriority.medium,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
    }
    
    return null;
  }

  /// Generate traffic-based suggestion
  ProactiveSuggestion? _generateTrafficBasedSuggestion(
    TrafficInfo traffic,
    String location,
  ) {
    if (traffic.congestionLevel > 0.7) {
      return ProactiveSuggestion(
        type: SuggestionType.traffic,
        title: 'Trafic intens - transport alternativ',
        description: 'E trafic intens în $location. Vrei să rezervi taxi pentru a evita aglomerația?',
        relevanceScore: 0.8,
        action: SuggestionAction.bookRide,
        actionData: {
          'urgency': 'medium',
          'reason': 'trafic_intens',
          'congestionLevel': traffic.congestionLevel,
          'location': location,
          'alternativeRoutes': traffic.alternativeRoutes,
        },
        priority: SuggestionPriority.medium,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
    }
    
    return null;
  }

  /// Get calendar-based suggestions
  Future<List<ProactiveSuggestion>> _getCalendarBasedSuggestions(DateTime time) async {
    try {
      final suggestions = <ProactiveSuggestion>[];
      
      // Get upcoming events that might need transportation
      final upcomingEvents = await _ecosystemService.calendarService.getUpcomingEvents(
        startTime: time,
        endTime: time.add(const Duration(hours: 4)),
      );
      
      for (final event in upcomingEvents) {
        if (_shouldSuggestTransportForEvent(event, time)) {
          final suggestion = ProactiveSuggestion(
            type: SuggestionType.calendar,
            title: 'Rezervă taxi pentru ${event.title}',
            description: 'Întâlnirea ta e la ${_formatTime(event.startTime)}. Să rezervi taxi?',
            relevanceScore: _calculateEventRelevance(event, time),
            action: SuggestionAction.bookRide,
            actionData: {
              'destination': event.location ?? 'destinația întâlnirii',
              'time': event.startTime,
              'eventId': event.id,
            },
            priority: _calculateEventPriority(event, time),
            expiresAt: event.startTime.subtract(const Duration(minutes: 30)),
          );
          
          suggestions.add(suggestion);
        }
      }
      
      return suggestions;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'calendar_suggestions_generation_failed',
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Get return transport suggestions
  Future<List<ProactiveSuggestion>> _getReturnTransportSuggestions(DateTime time) async {
    try {
      final suggestions = <ProactiveSuggestion>[];
      
      // Check if user is at a location that typically requires return transport
      final userLocation = await _getUserLocation();
      if (userLocation != null && _isLocationRequiringReturnTransport(userLocation)) {
        final suggestion = ProactiveSuggestion(
          type: SuggestionType.location,
          title: 'Rezervă taxi pentru acasă',
          description: 'Ești la $userLocation. Vrei să rezervi taxi pentru acasă?',
          relevanceScore: 0.8,
          action: SuggestionAction.bookRide,
          actionData: {
            'pickup': userLocation,
            'destination': 'acasă',
            'urgency': 'normal',
            'reason': 'return_transport',
          },
          priority: SuggestionPriority.medium,
          expiresAt: time.add(const Duration(hours: 2)),
        );
        
        suggestions.add(suggestion);
      }
      
      return suggestions;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'return_transport_suggestions_generation_failed',
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Get weekend suggestions
  Future<List<ProactiveSuggestion>> _getWeekendSuggestions(DateTime time) async {
    try {
      final suggestions = <ProactiveSuggestion>[];
      
      // Weekend-specific transportation opportunities
      suggestions.add(ProactiveSuggestion(
        type: SuggestionType.pattern,
        title: 'Taxi pentru weekend',
        description: 'E weekend! Vrei să rezervi taxi pentru ieșire?',
        relevanceScore: 0.7,
        action: SuggestionAction.bookRide,
        actionData: {
          'urgency': 'normal',
          'reason': 'weekend',
        },
        priority: SuggestionPriority.medium,
        expiresAt: time.add(const Duration(hours: 4)),
      ));
      
      return suggestions;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'weekend_suggestions_generation_failed',
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Get immediate suggestions
  Future<List<ProactiveSuggestion>> _getImmediateSuggestions(DateTime time) async {
    try {
      final suggestions = <ProactiveSuggestion>[];
      
      // Check for immediate transportation needs based on patterns
      final immediatePatterns = _getImmediatePatterns(time);
      for (final pattern in immediatePatterns) {
        final suggestion = ProactiveSuggestion(
          type: SuggestionType.pattern,
          title: 'Oportunitate imediată',
          description: 'Bazat pe pattern-ul tău, ar trebui să rezervi taxi acum.',
          relevanceScore: 0.8,
          action: SuggestionAction.bookRide,
          actionData: {
            'patternId': pattern.id,
            'urgency': 'high',
            'reason': 'immediate_pattern',
          },
          priority: SuggestionPriority.high,
          expiresAt: time.add(const Duration(minutes: 15)),
        );
        
        suggestions.add(suggestion);
      }
      
      return suggestions;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'immediate_suggestions_generation_failed',
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Get cost-saving suggestions
  Future<List<ProactiveSuggestion>> _getCostSavingSuggestions(DateTime time) async {
    try {
      final suggestions = <ProactiveSuggestion>[];
      
      // Check for cost-saving opportunities
      final costSavings = await _analyzeCostSavingOpportunities(time);
      for (final saving in costSavings) {
        final suggestion = ProactiveSuggestion(
          type: SuggestionType.cost,
          title: 'Economisește cu transportul',
          description: 'Poți economisi ${saving.amount} lei dacă aștepți ${saving.waitTime} minute.',
          relevanceScore: 0.7,
          action: SuggestionAction.showAlternatives,
          actionData: {
            'savings': saving.amount,
            'waitTime': saving.waitTime,
            'reason': 'cost_saving',
          },
          priority: SuggestionPriority.medium,
          expiresAt: time.add(const Duration(minutes: 30)),
        );
        
        suggestions.add(suggestion);
      }
      
      return suggestions;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'cost_saving_suggestions_generation_failed',
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Check if routine should be triggered
  bool _shouldTriggerRoutine(Routine routine, DateTime time) {
    // Check if routine is active
    if (!routine.isActive) return false;
    
    // Check if it's the right time
    final routineTime = routine.scheduledTime;
    if (routineTime != null) {
      final timeDifference = (time.hour * 60 + time.minute) - (routineTime.hour * 60 + routineTime.minute);
      return timeDifference.abs() <= routine.timeWindow;
    }
    
    // Check if it's the right day
    if (routine.daysOfWeek.isNotEmpty) {
      return routine.daysOfWeek.contains(time.weekday);
    }
    
    return false;
  }

  /// Calculate routine urgency
  String _calculateRoutineUrgency(Routine routine, DateTime time) {
    final routineTime = routine.scheduledTime;
    if (routineTime == null) return 'normal';
    
    final timeDifference = (time.hour * 60 + time.minute) - (routineTime.hour * 60 + routineTime.minute);
    
    if (timeDifference.abs() <= 15) {
      return 'high';
    } else if (timeDifference.abs() <= 30) {
      return 'medium';
    } else {
      return 'normal';
    }
  }

  /// Get priority from urgency
  SuggestionPriority _getPriorityFromUrgency(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return SuggestionPriority.high;
      case 'medium':
        return SuggestionPriority.medium;
      case 'low':
        return SuggestionPriority.low;
      default:
        return SuggestionPriority.medium;
    }
  }

  /// Check if transport should be suggested for an event
  bool _shouldSuggestTransportForEvent(CalendarEvent event, DateTime currentTime) {
    // Don't suggest for events in the past
    if (event.startTime.isBefore(currentTime)) return false;
    
    // Don't suggest for events too far in the future (more than 2 hours)
    if (event.startTime.difference(currentTime).inHours > 2) return false;
    
    // Suggest for events with locations
    if (event.location != null && event.location!.isNotEmpty) return true;
    
    // Suggest for events during commute hours
    final eventHour = event.startTime.hour;
    if (eventHour >= 7 && eventHour <= 9 || eventHour >= 17 && eventHour <= 19) {
      return true;
    }
    
    return false;
  }

  /// Calculate event relevance score
  double _calculateEventRelevance(CalendarEvent event, DateTime currentTime) {
    double score = 0.5; // Base score
    
    // Time proximity bonus
    final timeDifference = event.startTime.difference(currentTime).inMinutes;
    if (timeDifference <= 30) {
      score += 0.3; // High urgency
    } else if (timeDifference <= 60) {
      score += 0.2; // Medium urgency
    } else if (timeDifference <= 120) {
      score += 0.1; // Low urgency
    }
    
    // Location bonus
    if (event.location != null && event.location!.isNotEmpty) {
      score += 0.2;
    }
    
    // Event type bonus
    if (event.type == EventType.meeting || event.type == EventType.appointment) {
      score += 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate event priority
  SuggestionPriority _calculateEventPriority(CalendarEvent event, DateTime currentTime) {
    final timeDifference = event.startTime.difference(currentTime).inMinutes;
    
    if (timeDifference <= 30) {
      return SuggestionPriority.high;
    } else if (timeDifference <= 60) {
      return SuggestionPriority.medium;
    } else {
      return SuggestionPriority.low;
    }
  }

  /// Check if location requires return transport
  bool _isLocationRequiringReturnTransport(String location) {
    final returnTransportLocations = [
      'mall', 'centru', 'centru vechi', 'shopping', 'restaurant',
      'cinema', 'teatru', 'club', 'bar', 'cafenea'
    ];
    
    final lowerLocation = location.toLowerCase();
    return returnTransportLocations.any((pattern) => lowerLocation.contains(pattern));
  }

  /// Get immediate patterns
  List<UserPattern> _getImmediatePatterns(DateTime time) {
    return _userPatterns.values
        .where((pattern) => pattern.type == PatternType.immediate)
        .where((pattern) => _isPatternActive(pattern, time))
        .toList();
  }

  /// Check if pattern is active
  bool _isPatternActive(UserPattern pattern, DateTime time) {
    // Check if pattern is active at the current time
    if (!pattern.isActive) return false;
    
    // Check time constraints
    if (pattern.startTime != null && pattern.endTime != null) {
      final currentTime = time.hour * 60 + time.minute;
      final startTime = pattern.startTime!.hour * 60 + pattern.startTime!.minute;
      final endTime = pattern.endTime!.hour * 60 + pattern.endTime!.minute;
      
      if (currentTime < startTime || currentTime > endTime) {
        return false;
      }
    }
    
    // Check day constraints
    if (pattern.daysOfWeek.isNotEmpty) {
      return pattern.daysOfWeek.contains(time.weekday);
    }
    
    return true;
  }

  /// Analyze cost-saving opportunities
  Future<List<CostSaving>> _analyzeCostSavingOpportunities(DateTime time) async {
    try {
      final savings = <CostSaving>[];
      
      // Mock cost-saving analysis
      // In production, this would analyze real-time pricing data
      savings.add(const CostSaving(
        amount: 15.0,
        waitTime: 20,
        reason: 'demand_fluctuation',
        confidence: 0.8,
      ));
      
      return savings;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'cost_saving_analysis_failed',
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Get routine by type
  Routine? _getRoutineByType(RoutineType type) {
    try {
      return _userRoutines.values.firstWhere((routine) => routine.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Get user location
  Future<String?> _getUserLocation() async {
    try {
      // Try to get current location
      final position = await _ecosystemService.locationService.getCurrentLocation();
      if (position != null) {
        final address = await _ecosystemService.locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        return address;
      }
      
      // Fallback to last known location
      return _userPreferences['last_known_location'] as String?;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'user_location_error_retrieval_failed',
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Send proactive notification
  Future<void> _sendProactiveNotification(ProactiveSuggestion suggestion) async {
    try {
      // In production, this would integrate with the notification system
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {
        'operation': 'proactive_notification_sent',
        'suggestionType': suggestion.type.name,
        'priority': suggestion.priority.name,
        'action': suggestion.action.name,
      });
      
      // Store suggestion for user to see
      await _storeProactiveSuggestion(suggestion);
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'proactive_notification_sending_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Store proactive suggestion
  Future<void> _storeProactiveSuggestion(ProactiveSuggestion suggestion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final suggestionsJson = prefs.getString('proactive_suggestions') ?? '[]';
      final suggestions = List<Map<String, dynamic>>.from(
        json.decode(suggestionsJson) as List<dynamic>,
      );
      
      suggestions.add(suggestion.toMap());
      
      // Keep only last 50 suggestions
      if (suggestions.length > 50) {
        suggestions.removeRange(0, suggestions.length - 50);
      }
      
      await prefs.setString('proactive_suggestions', json.encode(suggestions));
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'proactive_suggestion_storing_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Load user data
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user patterns
      final patternsJson = prefs.getString('user_patterns');
      if (patternsJson != null) {
        final patterns = json.decode(patternsJson) as Map<String, dynamic>;
        _userPatterns.addAll(Map<String, UserPattern>.from(patterns));
      }
      
      // Load user routines
      final routinesJson = prefs.getString('user_routines');
      if (routinesJson != null) {
        final routines = json.decode(routinesJson) as Map<String, dynamic>;
        _userRoutines.addAll(Map<String, Routine>.from(routines));
      }
      
      // Load user preferences
      final preferencesJson = prefs.getString('user_preferences');
      if (preferencesJson != null) {
        final preferences = json.decode(preferencesJson) as Map<String, dynamic>;
        // Convert dynamic map to Preference objects
        for (final entry in preferences.entries) {
          if (entry.value is Map<String, dynamic>) {
            final prefData = entry.value as Map<String, dynamic>;
            _userPreferences[entry.key] = Preference(
              id: entry.key,
              category: prefData['category'] ?? 'general',
              value: prefData['value'] ?? '',
              weight: (prefData['weight'] as num?)?.toDouble() ?? 1.0,
              lastUpdated: DateTime.tryParse(prefData['lastUpdated'] ?? '') ?? DateTime.now(),
            );
          }
        }
      }
      
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'user_data_loading_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Save user patterns
  Future<void> _saveUserPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_patterns', json.encode(_userPatterns));
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'user_patterns_saving_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Get service status
  bool get isInitialized => _isInitialized;
  bool get isEnabled => _isEnabled;
  
  /// Enable/disable proactive features
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
          VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'proactive_ai_enabled_changed', 'enabled': enabled});
  }
  
  /// Dispose resources
  void dispose() {
    _scheduler.close();
    
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    
    _scheduledTasks.clear();
    _userPatterns.clear();
    _userRoutines.clear();
    _userPreferences.clear();
  }
}

// Supporting classes and enums

enum SuggestionType {
  routine,
  calendar,
  location,
  weather,
  traffic,
  pattern,
  cost,
}

enum SuggestionAction {
  bookRide,
  showAlternatives,
  showInfo,
  reminder,
  none,
}

enum SuggestionPriority {
  low,
  medium,
  high,
  urgent,
}

enum RoutineType {
  morning,
  evening,
  weekend,
  custom,
}

enum PatternType {
  immediate,
  scheduled,
  conditional,
  recurring,
}

class ProactiveSuggestion {
  final SuggestionType type;
  final String title;
  final String description;
  final double relevanceScore;
  final SuggestionAction action;
  final Map<String, dynamic> actionData;
  final SuggestionPriority priority;
  final DateTime? expiresAt;
  final List<String>? alternatives;

  const ProactiveSuggestion({
    required this.type,
    required this.title,
    required this.description,
    required this.relevanceScore,
    required this.action,
    required this.actionData,
    required this.priority,
    this.expiresAt,
    this.alternatives,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'relevanceScore': relevanceScore,
      'action': action.name,
      'actionData': actionData,
      'priority': priority.name,
      'expiresAt': expiresAt?.toIso8601String(),
      'alternatives': alternatives,
    };
  }
}

class Routine {
  final String id;
  final String name;
  final String? description;
  final RoutineType type;
  final TimeOfDay? scheduledTime;
  final int timeWindow; // in minutes
  final List<int> daysOfWeek; // 1-7, where 1 is Monday
  final String? pickup;
  final String? destination;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastTriggered;

  const Routine({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.scheduledTime,
    this.timeWindow = 30,
    this.daysOfWeek = const [],
    this.pickup,
    this.destination,
    this.isActive = true,
    required this.createdAt,
    required this.lastTriggered,
  });
}

class UserPattern {
  final String id;
  final String name;
  final PatternType type;
  final String? description;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<int> daysOfWeek;
  final Map<String, dynamic> conditions;
  final bool isActive;
  final double confidence;
  final DateTime lastMatched;

  const UserPattern({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.startTime,
    this.endTime,
    this.daysOfWeek = const [],
    this.conditions = const {},
    this.isActive = true,
    required this.confidence,
    required this.lastMatched,
  });
}

class Preference {
  final String id;
  final String category;
  final String value;
  final double weight;
  final DateTime lastUpdated;

  const Preference({
    required this.id,
    required this.category,
    required this.value,
    required this.weight,
    required this.lastUpdated,
  });
}

class CostSaving {
  final double amount;
  final int waitTime; // in minutes
  final String reason;
  final double confidence;

  const CostSaving({
    required this.amount,
    required this.waitTime,
    required this.reason,
    required this.confidence,
  });
}

class ScheduledTask {
  final String id;
  final String name;
  final DateTime scheduledTime;
  final Function callback;
  final bool isRecurring;
  final Duration? recurrenceInterval;

  const ScheduledTask({
    required this.id,
    required this.name,
    required this.scheduledTime,
    required this.callback,
    this.isRecurring = false,
    this.recurrenceInterval,
  });
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay(this.hour, this.minute);
}

// Service interfaces (to be implemented)

abstract class UserBehaviorAnalyzer {
  Future<void> initialize();
  Future<void> analyzeTransportationPatterns();
  void dispose();
}

abstract class RoutineLearner {
  Future<void> initialize();
  Future<void> learnNewRoutines();
  void dispose();
}

abstract class PredictionEngine {
  Future<void> initialize();
  Future<void> updatePredictions();
  void dispose();
}

// ─── Concrete implementations ────────────────────────────────────────────────

class UserBehaviorAnalyzerImpl implements UserBehaviorAnalyzer {
  static const _historyKey = 'ride_history_v1';
  static const _topDestsKey = 'top_destinations_v1';

  @override
  Future<void> initialize() async {}

  @override
  Future<void> analyzeTransportationPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null) return;

      final history = jsonDecode(raw) as List;
      final destinationCounts = <String, int>{};
      final hourCounts = <int, int>{};

      for (final entry in history) {
        final ride = entry as Map<String, dynamic>;
        final dest = ride['destination'] as String?;
        final timeStr = ride['time'] as String?;
        if (dest != null && dest.isNotEmpty) {
          destinationCounts[dest] = (destinationCounts[dest] ?? 0) + 1;
        }
        if (timeStr != null) {
          final t = DateTime.tryParse(timeStr);
          if (t != null) {
            hourCounts[t.hour] = (hourCounts[t.hour] ?? 0) + 1;
          }
        }
      }

      // Persist top 5 destinations by frequency
      final sortedDests = destinationCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      await prefs.setStringList(
        _topDestsKey,
        sortedDests.take(5).map((e) => e.key).toList(),
      );

      // Persist peak usage hours (top 3)
      final sortedHours = hourCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      await prefs.setStringList(
        'peak_hours_v1',
        sortedHours.take(3).map((e) => e.key.toString()).toList(),
      );
    } catch (e) {
      Logger.debug('UsageTrackerImpl.trackUsage failed: $e', tag: 'PROACTIVE_AI');
    }
  }

  @override
  void dispose() {}
}

class RoutineLearnerImpl implements RoutineLearner {
  static const _historyKey = 'ride_history_v1';
  static const _routinesKey = 'learned_routines_v1';
  // Minimum repetitions before a trip is considered a routine
  static const int _minRepetitions = 3;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> learnNewRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null) return;

      final history = jsonDecode(raw) as List;
      // Key: "weekday_hour" → destination → count
      final patternMap = <String, Map<String, int>>{};

      for (final entry in history) {
        final ride = entry as Map<String, dynamic>;
        final dest = ride['destination'] as String?;
        final timeStr = ride['time'] as String?;
        if (dest == null || timeStr == null) continue;
        final t = DateTime.tryParse(timeStr);
        if (t == null) continue;

        final key = '${t.weekday}_${t.hour}';
        patternMap[key] ??= {};
        patternMap[key]![dest] = (patternMap[key]![dest] ?? 0) + 1;
      }

      // Extract routines that exceed minimum repetition threshold
      final routines = <String>[];
      for (final slotEntry in patternMap.entries) {
        for (final destEntry in slotEntry.value.entries) {
          if (destEntry.value >= _minRepetitions) {
            // Format: "weekday_hour:destination"
            routines.add('${slotEntry.key}:${destEntry.key}');
          }
        }
      }

      await prefs.setStringList(_routinesKey, routines);
    } catch (e) {
      Logger.debug('RoutineLearnerImpl.learnNewRoutines failed: $e', tag: 'PROACTIVE_AI');
    }
  }

  @override
  void dispose() {}
}

class PredictionEngineImpl implements PredictionEngine {
  static const _routinesKey = 'learned_routines_v1';
  static const _topDestsKey = 'top_destinations_v1';
  static const _predictionsKey = 'current_predictions_v1';

  @override
  Future<void> initialize() async {}

  @override
  Future<void> updatePredictions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routines = prefs.getStringList(_routinesKey) ?? [];
      final topDests = prefs.getStringList(_topDestsKey) ?? [];

      final now = DateTime.now();
      final currentKey = '${now.weekday}_${now.hour}';

      // Find destinations matching current weekday+hour slot
      final predictions = <String>[];
      for (final routine in routines) {
        final parts = routine.split(':');
        if (parts.length >= 2 && parts[0] == currentKey) {
          final dest = parts.sublist(1).join(':');
          if (!predictions.contains(dest)) predictions.add(dest);
        }
      }

      // Fill up to 3 predictions using top destinations
      for (final dest in topDests) {
        if (predictions.length >= 3) break;
        if (!predictions.contains(dest)) predictions.add(dest);
      }

      await prefs.setStringList(_predictionsKey, predictions.take(3).toList());
    } catch (e) {
      Logger.debug('PredictionEngineImpl.updatePredictions failed: $e', tag: 'PROACTIVE_AI');
    }
  }

  @override
  void dispose() {}
}
