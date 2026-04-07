import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/utils/logger.dart';


/// Voice analytics service for tracking voice-related events and performance metrics
class VoiceAnalytics {
  // MEMORY LEAK PREVENTION CONSTANTS
  static const int _maxEventHistory = 100;
  static const int _maxPerformanceMetrics = 50;
  static const int _maxUserSessions = 20;
  static const Duration _maxEventAge = Duration(hours: 24);
  static const Duration _cleanupInterval = Duration(minutes: 5);
  
  static final VoiceAnalytics _instance = VoiceAnalytics._internal();
  factory VoiceAnalytics() => _instance;
  VoiceAnalytics._internal();

  // MEMORY LEAK PREVENTION - Stream Controller Management
  final StreamController<VoiceEvent> _eventController = StreamController<VoiceEvent>.broadcast();
  final StreamController<PerformanceMetric> _performanceController = StreamController<PerformanceMetric>.broadcast();
  
  // Event tracking
  final List<VoiceEvent> _eventHistory = [];
  final Map<String, List<PerformanceMetric>> _performanceMetrics = {};
  final Map<String, UserSession> _userSessions = {};
  
  // Cleanup management
  Timer? _cleanupTimer;
  bool _isInitialized = false;
  
  /// Stream of voice events
  Stream<VoiceEvent> get events => _eventController.stream;
  
  /// Stream of performance metrics
  Stream<PerformanceMetric> get performanceMetrics => _performanceController.stream;
  
  /// Initialize voice analytics
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadHistoricalData();
      _startPeriodicCleanup();
      _isInitialized = true;
      Logger.info('VoiceAnalytics initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize VoiceAnalytics: $e', error: e);
    }
  }
  
  /// Track a voice event
  void trackEvent(VoiceEventType type, {
    Map<String, dynamic>? data,
    String? userId,
    String? sessionId,
  }) {
    final event = VoiceEvent(
      type: type,
      data: data ?? {},
      userId: userId,
      sessionId: sessionId,
      timestamp: DateTime.now(),
    );
    
    _addToEventHistory(event);
    _eventController.add(event);
    
    // Update user session
    if (userId != null) {
      _updateUserSession(userId, sessionId, event);
    }
  }
  
  /// Track performance metric
  void trackPerformance(String metricName, {
    double value = 0.0,
    String unit = '',
    Map<String, dynamic>? metadata,
    String? userId,
  }) {
    final metric = PerformanceMetric(
      name: metricName,
      value: value,
      unit: unit,
      metadata: metadata ?? {},
      userId: userId,
      timestamp: DateTime.now(),
    );
    
    _addToPerformanceMetrics(metric);
    _performanceController.add(metric);
  }
  
  /// ✅ RESET SESSION: Curăță toate datele din sesiunea curentă
  void resetSession() {
    Logger.debug('VoiceAnalytics: Resetting session data...');
    
    // Clear event history
    _eventHistory.clear();
    
    // Clear performance metrics
    _performanceMetrics.clear();
    
    // Clear user sessions
    _userSessions.clear();
    
    // Reset cleanup timer
    _cleanupTimer?.cancel();
    
    Logger.info('VoiceAnalytics: Session reset completed');
  }

  /// Start performance timer
  void startPerformanceTimer(String operation) {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    _performanceMetrics[operation] = [PerformanceMetric(
      name: operation,
      value: startTime.toDouble(),
      unit: 'ms',
      metadata: {'startTime': startTime},
      timestamp: DateTime.now(),
    )];
  }

  /// End performance timer
  void endPerformanceTimer(String operation) {
    final metrics = _performanceMetrics[operation];
    if (metrics != null && metrics.isNotEmpty) {
      final startMetric = metrics.first;
      final startTime = startMetric.metadata['startTime'] as int?;
      if (startTime != null) {
        final duration = DateTime.now().millisecondsSinceEpoch - startTime;
        trackPerformance(
          '${operation}_duration',
          value: duration.toDouble(),
          unit: 'ms',
          metadata: {'operation': operation, 'duration': duration},
        );
      }
    }
  }

  /// Track voice recognition accuracy
  void trackRecognitionAccuracy({
    required double accuracy,
    required String language,
    required String userId,
    String? sessionId,
  }) {
    trackPerformance('recognition_accuracy', 
      value: accuracy,
      unit: 'percentage',
      metadata: {
        'language': language,
        'session_id': sessionId,
      },
      userId: userId,
    );
  }
  
  /// Track response time
  void trackResponseTime({
    required Duration responseTime,
    required String action,
    required String userId,
    String? sessionId,
  }) {
    trackPerformance('response_time',
      value: responseTime.inMilliseconds.toDouble(),
      unit: 'milliseconds',
      metadata: {
        'action': action,
        'session_id': sessionId,
      },
      userId: userId,
    );
  }
  
  /// Track error occurrence
  void trackError({
    required String errorType,
    required String errorMessage,
    String? userId,
    String? sessionId,
    StackTrace? stackTrace,
  }) {
    trackEvent(VoiceEventType.error, data: {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace?.toString().substring(0, 500), // Limit stack trace size
      'session_id': sessionId,
    }, userId: userId, sessionId: sessionId);
  }
  
  /// Track user interaction
  void trackUserInteraction({
    required String interactionType,
    required String userId,
    String? sessionId,
    Map<String, dynamic>? additionalData,
  }) {
    trackEvent(VoiceEventType.userInteraction, data: {
      'interaction_type': interactionType,
      'session_id': sessionId,
      ...?additionalData,
    }, userId: userId, sessionId: sessionId);
  }
  
  /// Get event history for a user
  List<VoiceEvent> getUserEventHistory(String userId, {int limit = 50}) {
    final userEvents = _eventHistory
        .where((event) => event.userId == userId)
        .toList();
    
    userEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return userEvents.take(limit).toList();
  }
  
  /// Get performance metrics for a user
  Map<String, List<PerformanceMetric>> getUserPerformanceMetrics(String userId) {
    final userMetrics = <String, List<PerformanceMetric>>{};
    
    for (final entry in _performanceMetrics.entries) {
      final userSpecificMetrics = entry.value
          .where((metric) => metric.userId == userId)
          .toList();
      
      if (userSpecificMetrics.isNotEmpty) {
        userMetrics[entry.key] = userSpecificMetrics;
      }
    }
    
    return userMetrics;
  }
  
  /// Get user session statistics
  UserSessionStats getUserSessionStats(String userId) {
    final userSessions = _userSessions[userId];
    if (userSessions == null) {
      return UserSessionStats(
        totalSessions: 0,
        averageSessionDuration: Duration.zero,
        totalEvents: 0,
        averageEventsPerSession: 0.0,
      );
    }
    
    final totalSessions = userSessions.sessions.length;
    final totalEvents = userSessions.totalEvents;
    final averageEventsPerSession = totalSessions > 0 ? totalEvents / totalSessions : 0.0;
    
    // Calculate average session duration
    Duration totalDuration = Duration.zero;
    int validSessions = 0;
    
    for (final session in userSessions.sessions) {
      if (session.endTime != null) {
        totalDuration += session.endTime!.difference(session.startTime);
        validSessions++;
      }
    }
    
    final averageSessionDuration = validSessions > 0 
        ? Duration(milliseconds: totalDuration.inMilliseconds ~/ validSessions)
        : Duration.zero;
    
    return UserSessionStats(
      totalSessions: totalSessions,
      averageSessionDuration: averageSessionDuration,
      totalEvents: totalEvents,
      averageEventsPerSession: averageEventsPerSession,
    );
  }
  
  /// MEMORY LEAK PREVENTION - Add to event history with cleanup
  void _addToEventHistory(VoiceEvent event) {
    _eventHistory.add(event);
    
    // Limit event history size
    if (_eventHistory.length > _maxEventHistory) {
      _eventHistory.removeRange(0, _eventHistory.length - _maxEventHistory);
    }
  }
  
  /// MEMORY LEAK PREVENTION - Add to performance metrics with cleanup
  void _addToPerformanceMetrics(PerformanceMetric metric) {
    if (!_performanceMetrics.containsKey(metric.name)) {
      _performanceMetrics[metric.name] = [];
    }
    
    _performanceMetrics[metric.name]!.add(metric);
    
    // Limit metrics per category
    if (_performanceMetrics[metric.name]!.length > _maxPerformanceMetrics) {
      _performanceMetrics[metric.name]!.removeRange(0, _performanceMetrics[metric.name]!.length - _maxPerformanceMetrics);
    }
  }
  
  /// MEMORY LEAK PREVENTION - Update user session with cleanup
  void _updateUserSession(String userId, String? sessionId, VoiceEvent event) {
    if (!_userSessions.containsKey(userId)) {
      _userSessions[userId] = UserSession(userId: userId);
    }
    
    final userSession = _userSessions[userId]!;
    userSession.addEvent(event, sessionId);
    
    // Limit user sessions
    if (_userSessions.length > _maxUserSessions) {
      final oldestUserId = _userSessions.keys.first;
      _userSessions.remove(oldestUserId);
    }
  }
  
  /// MEMORY LEAK PREVENTION - Periodic cleanup
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      _cleanupExpiredEvents();
      _cleanupExpiredMetrics();
      _cleanupExpiredSessions();
    });
  }
  
  /// Cleanup expired events
  void _cleanupExpiredEvents() {
    final cutoff = DateTime.now().subtract(_maxEventAge);
    _eventHistory.removeWhere((event) => event.timestamp.isBefore(cutoff));
  }
  
  /// Cleanup expired metrics
  void _cleanupExpiredMetrics() {
    final cutoff = DateTime.now().subtract(_maxEventAge);
    
    for (final entry in _performanceMetrics.entries) {
      entry.value.removeWhere((metric) => metric.timestamp.isBefore(cutoff));
    }
    
    // Remove empty metric categories
    _performanceMetrics.removeWhere((key, value) => value.isEmpty);
  }
  
  /// Cleanup expired sessions
  void _cleanupExpiredSessions() {
    final cutoff = DateTime.now().subtract(_maxEventAge);
    
    for (final entry in _userSessions.entries) {
      entry.value.sessions.removeWhere((session) => 
          session.endTime != null && session.endTime!.isBefore(cutoff));
    }
    
    // Remove users with no active sessions
    _userSessions.removeWhere((key, value) => value.sessions.isEmpty);
  }
  
  /// Load historical data from persistent storage
  Future<void> _loadHistoricalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load event history
      final eventHistoryJson = prefs.getString('voice_analytics_events');
      if (eventHistoryJson != null) {
        final List<dynamic> eventList = jsonDecode(eventHistoryJson);
        _eventHistory.clear();
        for (final eventMap in eventList) {
          try {
            final event = VoiceEvent(
              type: VoiceEventType.values.firstWhere(
                (e) => e.name == eventMap['type'],
                orElse: () => VoiceEventType.unknown,
              ),
              data: Map<String, dynamic>.from(eventMap['data'] ?? {}),
              userId: eventMap['userId'],
              sessionId: eventMap['sessionId'],
              timestamp: DateTime.parse(eventMap['timestamp']),
              errorMessage: eventMap['errorMessage'],
              errorType: eventMap['errorType'],
              properties: eventMap['properties'] != null 
                ? Map<String, dynamic>.from(eventMap['properties'])
                : null,
            );
            _eventHistory.add(event);
          } catch (e) {
            Logger.error('Failed to parse event: $e', error: e);
          }
        }
      }
      
      // Load performance metrics
      final metricsJson = prefs.getString('voice_analytics_metrics');
      if (metricsJson != null) {
        final Map<String, dynamic> metricsMap = jsonDecode(metricsJson);
        _performanceMetrics.clear();
        for (final entry in metricsMap.entries) {
          final List<dynamic> metricList = entry.value;
          _performanceMetrics[entry.key] = metricList.map((metricMap) {
            return PerformanceMetric(
              name: metricMap['name'],
              value: (metricMap['value'] ?? 0.0).toDouble(),
              unit: metricMap['unit'] ?? '',
              metadata: Map<String, dynamic>.from(metricMap['metadata'] ?? {}),
              userId: metricMap['userId'],
              timestamp: DateTime.parse(metricMap['timestamp']),
            );
          }).toList();
        }
      }
      
      // Load user sessions
      final sessionsJson = prefs.getString('voice_analytics_sessions');
      if (sessionsJson != null) {
        final Map<String, dynamic> sessionsMap = jsonDecode(sessionsJson);
        _userSessions.clear();
        for (final entry in sessionsMap.entries) {
          final sessionData = entry.value;
          final userSession = UserSession(userId: entry.key);
          userSession.totalEvents = sessionData['totalEvents'] ?? 0;
          
          final sessionsList = sessionData['sessions'] as List<dynamic>?;
          if (sessionsList != null) {
            for (final sessionMap in sessionsList) {
              final session = SessionInfo(
                id: sessionMap['id'],
                startTime: DateTime.parse(sessionMap['startTime']),
              );
              session.endTime = sessionMap['endTime'] != null 
                ? DateTime.parse(sessionMap['endTime'])
                : null;
              session.eventCount = sessionMap['eventCount'] ?? 0;
              userSession.sessions.add(session);
            }
          }
          _userSessions[entry.key] = userSession;
        }
      }
      
      Logger.info('Historical data loaded successfully');
    } catch (e) {
      Logger.error('Failed to load historical data: $e', error: e);
    }
  }
  
  /// Save current data to persistent storage
  Future<void> saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save event history
      final eventHistoryList = _eventHistory.map((event) => {
        'type': event.type.name,
        'data': event.data,
        'userId': event.userId,
        'sessionId': event.sessionId,
        'timestamp': event.timestamp.toIso8601String(),
        'errorMessage': event.errorMessage,
        'errorType': event.errorType,
        'properties': event.properties,
      }).toList();
      await prefs.setString('voice_analytics_events', jsonEncode(eventHistoryList));
      
      // Save performance metrics
      final metricsMap = _performanceMetrics.map((key, value) => MapEntry(key, 
        value.map((metric) => {
          'name': metric.name,
          'value': metric.value,
          'unit': metric.unit,
          'metadata': metric.metadata,
          'userId': metric.userId,
          'timestamp': metric.timestamp.toIso8601String(),
        }).toList()
      ));
      await prefs.setString('voice_analytics_metrics', jsonEncode(metricsMap));
      
      // Save user sessions
      final sessionsMap = _userSessions.map((key, value) => MapEntry(key, {
        'totalEvents': value.totalEvents,
        'sessions': value.sessions.map((session) => {
          'id': session.id,
          'startTime': session.startTime.toIso8601String(),
          'endTime': session.endTime?.toIso8601String(),
          'eventCount': session.eventCount,
        }).toList(),
      }));
      await prefs.setString('voice_analytics_sessions', jsonEncode(sessionsMap));
      
      Logger.debug('Data saved successfully');
    } catch (e) {
      Logger.error('Failed to save data: $e', error: e);
    }
  }
  
  /// MEMORY LEAK PREVENTION - Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    
    // Close stream controllers
    _eventController.close();
    _performanceController.close();
    
    // Clear data
    _eventHistory.clear();
    _performanceMetrics.clear();
    _userSessions.clear();
    
    _isInitialized = false;
  }
}

/// Voice event types
enum VoiceEventType {
  wakeWordDetected,
  speechRecognized,
  speechSynthesized,
  userInteraction,
  error,
  sessionStarted,
  sessionEnded,
  system,
  unknown,
}

/// Voice event
class VoiceEvent {
  final VoiceEventType type;
  final Map<String, dynamic> data;
  final String? userId;
  final String? sessionId;
  final DateTime timestamp;
  final String? errorMessage;
  final String? errorType;
  final Map<String, dynamic>? properties;

  VoiceEvent({
    required this.type,
    required this.data,
    this.userId,
    this.sessionId,
    required this.timestamp,
    this.errorMessage,
    this.errorType,
    this.properties,
  });
}

/// Performance metric
class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final Map<String, dynamic> metadata;
  final String? userId;
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.metadata,
    this.userId,
    required this.timestamp,
  });
}

/// User session
class UserSession {
  final String userId;
  final List<SessionInfo> sessions = [];
  int totalEvents = 0;

  UserSession({required this.userId});

  void addEvent(VoiceEvent event, String? sessionId) {
    totalEvents++;
    
    if (sessionId != null) {
      final session = sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => SessionInfo(id: sessionId, startTime: DateTime.now()),
      );
      
      if (!sessions.contains(session)) {
        sessions.add(session);
      }
      
      session.eventCount++;
    }
  }
}

/// Session information
class SessionInfo {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  int eventCount = 0;

  SessionInfo({
    required this.id,
    required this.startTime,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
}

/// User session statistics
class UserSessionStats {
  final int totalSessions;
  final Duration averageSessionDuration;
  final int totalEvents;
  final double averageEventsPerSession;

  UserSessionStats({
    required this.totalSessions,
    required this.averageSessionDuration,
    required this.totalEvents,
    required this.averageEventsPerSession,
  });
}
