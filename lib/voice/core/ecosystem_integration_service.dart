import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:nabour_app/config/environment.dart';
import 'voice_analytics.dart';
import 'conversational_ai_engine.dart';


/// Ecosystem Integration Service for Nabour
/// Integrates with calendar, contacts, location, weather, and traffic services
class EcosystemIntegrationService {
  static final EcosystemIntegrationService _instance = EcosystemIntegrationService._internal();
  factory EcosystemIntegrationService() => _instance;
  EcosystemIntegrationService._internal();

  // Core services
  late CalendarService _calendarService;
  late ContactService _contactService;
  late LocationService _locationService;
  late WeatherService _weatherService;
  late TrafficService _trafficService;
  
  // Configuration
  bool _isInitialized = false;
  final Map<String, dynamic> _userPreferences = {};
  final Map<String, dynamic> _learnedLocations = {};
  
  // Performance tracking
  final Map<String, PerformanceMetric> _performanceMetrics = {};
  
  /// Initialize the ecosystem integration service
  Future<void> initialize() async {
    try {
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'ecosystem_integration_initialization_started'});
      
      // Initialize core services
      _calendarService = CalendarServiceImpl();
      _contactService = ContactServiceImpl();
      _locationService = LocationServiceImpl();
      _weatherService = WeatherServiceImpl();
      _trafficService = TrafficServiceImpl();
      
      // Request permissions
      await _requestPermissions();
      
      // Load user preferences and learned locations
      await _loadUserData();
      
      // Initialize services
      await Future.wait([
        _calendarService.initialize(),
        _contactService.initialize(),
        _locationService.initialize(),
        _weatherService.initialize(),
        _trafficService.initialize(),
      ]);
      
      _isInitialized = true;
      
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'ecosystem_integration_initialization_completed'});
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'ecosystem_integration_initialization_failed',
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Request necessary permissions for calendar + contacts (aligned with device_calendar / flutter_contacts).
  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    try {
      final permissions = <Permission>[Permission.contacts];
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        permissions.add(Permission.calendarFullAccess);
      } else {
        // Android: citire calendar (echivalent READ_CALENDAR)
        // ignore: deprecated_member_use
        permissions.add(Permission.calendar);
      }

      for (final permission in permissions) {
        final status = await permission.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'permission_denied', 'permission': permission.toString()});
        }
      }
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'permission_request_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Load user data from storage
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user preferences
      final preferencesJson = prefs.getString('user_preferences');
      if (preferencesJson != null) {
        final preferences = json.decode(preferencesJson) as Map<String, dynamic>;
        _userPreferences.addAll(preferences);
      }
      
      // Load learned locations
      final locationsJson = prefs.getString('learned_locations');
      if (locationsJson != null) {
        final locations = json.decode(locationsJson) as Map<String, dynamic>;
        _learnedLocations.addAll(locations);
      }
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'user_data_loading_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Get smart transportation suggestions based on context
  Future<List<SmartSuggestion>> getSmartSuggestions({
    required UserContext userContext,
    required DateTime currentTime,
    required String? userLocation,
  }) async {
    try {
      VoiceAnalytics().startPerformanceTimer('smart_suggestions_generation');
      
      final suggestions = <SmartSuggestion>[];
      
      // Calendar-based suggestions
      final calendarSuggestions = await _getCalendarBasedSuggestions(userContext, currentTime);
      suggestions.addAll(calendarSuggestions);
      
      // Location-based suggestions
      if (userLocation != null) {
        final locationSuggestions = await _getLocationBasedSuggestions(userLocation, currentTime);
        suggestions.addAll(locationSuggestions);
      }
      
      // Time-based suggestions
      final timeSuggestions = _getTimeBasedSuggestions(currentTime);
      suggestions.addAll(timeSuggestions);
      
      // Weather-based suggestions
      final weatherSuggestions = await _getWeatherBasedSuggestions(userLocation, currentTime);
      suggestions.addAll(weatherSuggestions);
      
      // Traffic-based suggestions
      final trafficSuggestions = await _getTrafficBasedSuggestions(userLocation, currentTime);
      suggestions.addAll(trafficSuggestions);
      
      // Sort suggestions by relevance
      suggestions.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      
      VoiceAnalytics().endPerformanceTimer('smart_suggestions_generation');
      VoiceAnalytics().trackEvent(VoiceEventType.system, data: {'operation': 'smart_suggestions_generated', 'count': suggestions.length});
      
      return suggestions;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'smart_suggestions_generation_failed',
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Get calendar-based transportation suggestions
  Future<List<SmartSuggestion>> _getCalendarBasedSuggestions(
    UserContext userContext,
    DateTime currentTime,
  ) async {
    try {
      final suggestions = <SmartSuggestion>[];
      
      // Get upcoming calendar events
      final upcomingEvents = await _calendarService.getUpcomingEvents(
        startTime: currentTime,
        endTime: currentTime.add(const Duration(hours: 24)),
      );
      
      for (final event in upcomingEvents) {
        if (_shouldSuggestTransportForEvent(event, currentTime)) {
          final suggestion = SmartSuggestion(
            type: SuggestionType.calendar,
            title: 'Rezervă taxi pentru ${event.title}',
            description: 'Întâlnirea ta e la ${_formatTime(event.startTime)}. Să rezervi taxi?',
            relevanceScore: _calculateEventRelevance(event, currentTime),
            action: SuggestionAction.bookRide,
            actionData: {
              'destination': event.location ?? 'destinația întâlnirii',
              'time': event.startTime,
              'eventId': event.id,
            },
            priority: _calculateEventPriority(event, currentTime),
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

  /// Get location-based transportation suggestions
  Future<List<SmartSuggestion>> _getLocationBasedSuggestions(
    String userLocation,
    DateTime currentTime,
  ) async {
    try {
      final suggestions = <SmartSuggestion>[];
      
      // Check if user is at a location that typically requires return transport
      if (_isLocationRequiringReturnTransport(userLocation)) {
        final suggestion = SmartSuggestion(
          type: SuggestionType.location,
          title: 'Rezervă taxi pentru acasă',
          description: 'Ești la $userLocation. Vrei să rezervi taxi pentru acasă?',
          relevanceScore: 0.8,
          action: SuggestionAction.bookRide,
          actionData: {
            'pickup': userLocation,
            'destination': 'acasă',
            'urgency': 'normal',
          },
          priority: SuggestionPriority.medium,
        );
        
        suggestions.add(suggestion);
      }
      
      // Check for nearby transportation options
      final nearbyOptions = await _getNearbyTransportationOptions(userLocation);
      for (final option in nearbyOptions) {
        final suggestion = SmartSuggestion(
          type: SuggestionType.location,
          title: 'Transport alternativ disponibil',
          description: 'Ai ${option.type} la ${option.distance} minute de mers.',
          relevanceScore: 0.6,
          action: SuggestionAction.showAlternatives,
          actionData: {
            'alternatives': nearbyOptions,
            'userLocation': userLocation,
          },
          priority: SuggestionPriority.low,
        );
        
        suggestions.add(suggestion);
      }
      
      return suggestions;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'location_suggestions_generation_failed',
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Get time-based transportation suggestions
  List<SmartSuggestion> _getTimeBasedSuggestions(DateTime currentTime) {
    final suggestions = <SmartSuggestion>[];
    final hour = currentTime.hour;
    
    // Morning commute suggestions
    if (hour >= 7 && hour <= 9) {
      suggestions.add(const SmartSuggestion(
        type: SuggestionType.time,
        title: 'Taxi pentru muncă',
        description: 'E ora de vârf dimineața. Vrei să rezervi taxi pentru muncă?',
        relevanceScore: 0.9,
        action: SuggestionAction.bookRide,
        actionData: {
          'pickup': 'acasă',
          'destination': 'muncă',
          'urgency': 'high',
          'reason': 'ora_de_vârf_dimineața',
        },
        priority: SuggestionPriority.high,
      ));
    }
    
    // Evening commute suggestions
    if (hour >= 17 && hour <= 19) {
      suggestions.add(const SmartSuggestion(
        type: SuggestionType.time,
        title: 'Taxi pentru acasă',
        description: 'E ora de vârf seara. Vrei să rezervi taxi pentru acasă?',
        relevanceScore: 0.9,
        action: SuggestionAction.bookRide,
        actionData: {
          'pickup': 'muncă',
          'destination': 'acasă',
          'urgency': 'high',
          'reason': 'ora_de_vârf_seara',
        },
        priority: SuggestionPriority.high,
      ));
    }
    
    // Weekend suggestions
    if (currentTime.weekday >= 6) {
      suggestions.add(const SmartSuggestion(
        type: SuggestionType.time,
        title: 'Taxi pentru weekend',
        description: 'E weekend! Vrei să rezervi taxi pentru ieșire?',
        relevanceScore: 0.7,
        action: SuggestionAction.bookRide,
        actionData: {
          'urgency': 'normal',
          'reason': 'weekend',
        },
        priority: SuggestionPriority.medium,
      ));
    }
    
    return suggestions;
  }

  /// Get weather-based transportation suggestions
  Future<List<SmartSuggestion>> _getWeatherBasedSuggestions(
    String? userLocation,
    DateTime currentTime,
  ) async {
    try {
      final suggestions = <SmartSuggestion>[];
      
      if (userLocation == null) return suggestions;
      
      // Get current weather
      final weather = await _weatherService.getCurrentWeather(userLocation);
      
      if (weather != null) {
        // Rain/snow suggestions
        if (weather.condition.contains('rain') || weather.condition.contains('snow')) {
          suggestions.add(SmartSuggestion(
            type: SuggestionType.weather,
            title: 'Vreme rea - rezervă taxi',
            description: 'Plouă/ninge. Vrei să rezervi taxi în loc să mergi pe jos?',
            relevanceScore: 0.8,
            action: SuggestionAction.bookRide,
            actionData: {
              'urgency': 'medium',
              'reason': 'vreme_rea',
              'weather': weather.condition,
            },
            priority: SuggestionPriority.medium,
          ));
        }
        
        // Extreme weather suggestions
        if (weather.temperature < -5 || weather.temperature > 35) {
          suggestions.add(SmartSuggestion(
            type: SuggestionType.weather,
            title: 'Temperatură extremă',
            description: 'Temperatura este ${weather.temperature}°C. Vrei să rezervi taxi?',
            relevanceScore: 0.7,
            action: SuggestionAction.bookRide,
            actionData: {
              'urgency': 'medium',
              'reason': 'temperatură_extremă',
              'temperature': weather.temperature,
            },
            priority: SuggestionPriority.medium,
          ));
        }
      }
      
      return suggestions;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'weather_suggestions_generation_failed',
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Get traffic-based transportation suggestions
  Future<List<SmartSuggestion>> _getTrafficBasedSuggestions(
    String? userLocation,
    DateTime currentTime,
  ) async {
    try {
      final suggestions = <SmartSuggestion>[];
      
      if (userLocation == null) return suggestions;
      
      // Get current traffic conditions
      final traffic = await _trafficService.getCurrentTraffic(userLocation);
      
      if (traffic != null && traffic.congestionLevel > 0.7) {
        suggestions.add(SmartSuggestion(
          type: SuggestionType.traffic,
          title: 'Trafic intens - rezervă taxi',
          description: 'E trafic intens în zona ta. Vrei să rezervi taxi pentru a evita aglomerația?',
          relevanceScore: 0.8,
          action: SuggestionAction.bookRide,
          actionData: {
            'urgency': 'medium',
            'reason': 'trafic_intens',
            'congestionLevel': traffic.congestionLevel,
            'alternativeRoutes': traffic.alternativeRoutes,
          },
          priority: SuggestionPriority.medium,
        ));
      }
      
      return suggestions;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'traffic_suggestions_generation_failed',
        errorMessage: e.toString(),
      );
      return [];
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

  /// Get nearby transportation options
  Future<List<TransportationOption>> _getNearbyTransportationOptions(String userLocation) async {
    try {
      final options = <TransportationOption>[];
      
      // Mock data - in production, this would call actual APIs
      options.add(const TransportationOption(
        type: 'Metrou',
        distance: 5,
        timeToReach: 3,
        cost: 0.0,
        reliability: 0.9,
      ));
      
      options.add(const TransportationOption(
        type: 'Autobuz',
        distance: 8,
        timeToReach: 5,
        cost: 2.5,
        reliability: 0.7,
      ));
      
      options.add(const TransportationOption(
        type: 'Tramvai',
        distance: 12,
        timeToReach: 7,
        cost: 2.5,
        reliability: 0.8,
      ));
      
      return options;
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'nearby_transportation_options_failed',
        errorMessage: e.toString(),
      );
      return [];
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Get user's learned locations
  Map<String, dynamic> getLearnedLocations() {
    return Map.unmodifiable(_learnedLocations);
  }

  /// Learn a new location from user behavior
  Future<void> learnLocation(String location, LocationContext context) async {
    try {
      if (!_learnedLocations.containsKey(location)) {
        _learnedLocations[location] = {
          'context': context.name,
          'firstSeen': DateTime.now().toIso8601String(),
          'visitCount': 0,
          'lastVisit': null,
          'preferredTransport': null,
        };
      }
      
      final locationData = _learnedLocations[location] as Map<String, dynamic>;
      locationData['visitCount'] = (locationData['visitCount'] as int) + 1;
      locationData['lastVisit'] = DateTime.now().toIso8601String();
      
      // Save to storage
      await _saveLearnedLocations();
      
              VoiceAnalytics().trackEvent(VoiceEventType.system, data: {
        'operation': 'location_learned',
        'location': location,
        'context': context.name,
        'visitCount': locationData['visitCount'],
      });
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'location_learning_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Save learned locations to storage
  Future<void> _saveLearnedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('learned_locations', json.encode(_learnedLocations));
    } catch (e) {
      VoiceAnalytics().trackError(
        errorType: 'learned_locations_saving_failed',
        errorMessage: e.toString(),
      );
    }
  }

  /// Get service status
  bool get isInitialized => _isInitialized;
  
  /// Get weather service
  WeatherService get weatherService => _weatherService;
  
  /// Get traffic service
  TrafficService get trafficService => _trafficService;
  
  /// Get location service
  LocationService get locationService => _locationService;
  
  /// Get calendar service
  CalendarService get calendarService => _calendarService;
  
  /// Dispose resources
  void dispose() {
    _calendarService.dispose();
    _contactService.dispose();
    _locationService.dispose();
    _weatherService.dispose();
    _trafficService.dispose();
    
    _userPreferences.clear();
    _learnedLocations.clear();
    _performanceMetrics.clear();
  }
}

// Supporting classes and enums

enum SuggestionType {
  calendar,
  location,
  time,
  weather,
  traffic,
  pattern,
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

enum LocationContext {
  home,
  work,
  shopping,
  entertainment,
  transport,
  other,
}

class SmartSuggestion {
  final SuggestionType type;
  final String title;
  final String description;
  final double relevanceScore;
  final SuggestionAction action;
  final Map<String, dynamic> actionData;
  final SuggestionPriority priority;
  final List<String>? alternatives;
  final DateTime? expiresAt;

  const SmartSuggestion({
    required this.type,
    required this.title,
    required this.description,
    required this.relevanceScore,
    required this.action,
    required this.actionData,
    required this.priority,
    this.alternatives,
    this.expiresAt,
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
      'alternatives': alternatives,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final bool isAllDay;
  final List<String> attendees;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.isAllDay = false,
    this.attendees = const [],
  });
}

enum EventType {
  meeting,
  appointment,
  reminder,
  task,
  other,
}

class TransportationOption {
  final String type;
  final int distance; // in minutes of walking
  final int timeToReach; // in minutes
  final double cost;
  final double reliability; // 0.0 to 1.0

  const TransportationOption({
    required this.type,
    required this.distance,
    required this.timeToReach,
    required this.cost,
    required this.reliability,
  });
}

class WeatherInfo {
  final String condition;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String description;

  const WeatherInfo({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
  });
}

class TrafficInfo {
  final double congestionLevel; // 0.0 to 1.0
  final List<String> alternativeRoutes;
  final int estimatedDelay; // in minutes
  final String description;

  const TrafficInfo({
    required this.congestionLevel,
    required this.alternativeRoutes,
    required this.estimatedDelay,
    required this.description,
  });
}

// Service interfaces (to be implemented)

abstract class CalendarService {
  Future<void> initialize();
  Future<List<CalendarEvent>> getUpcomingEvents({
    required DateTime startTime,
    required DateTime endTime,
  });
  void dispose();
}

abstract class ContactService {
  Future<void> initialize();
  Future<List<Contact>> getContacts();
  Future<Contact?> getContactById(String id);
  void dispose();
}

abstract class LocationService {
  Future<void> initialize();
  Future<Position?> getCurrentLocation();
  Future<String?> getAddressFromCoordinates(double lat, double lng);
  void dispose();
}

abstract class WeatherService {
  Future<void> initialize();
  Future<WeatherInfo?> getCurrentWeather(String location);
  Future<WeatherInfo?> getWeatherForecast(String location, DateTime date);
  void dispose();
}

abstract class TrafficService {
  Future<void> initialize();
  Future<TrafficInfo?> getCurrentTraffic(String location);
  Future<List<String>> getAlternativeRoutes(String from, String to);
  void dispose();
}

class Contact {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? address;

  const Contact({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.address,
  });
}

// ─── Concrete implementations ────────────────────────────────────────────────

/// Evenimente calendar: stocate local (SharedPreferences).
/// Notă: pachetul `device_calendar` 3.x nu compilează pe Flutter/AGP actual (API embedding vechi);
/// pentru citire din calendar sistem poți reveni la un pachet întreținut sau la un canal nativ dedicat.
class CalendarServiceImpl implements CalendarService {
  static const _eventsKey = 'nabour_calendar_events_v1';
  final List<CalendarEvent> _events = [];

  @override
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_eventsKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _events.clear();
        _events.addAll(list.map((e) => _eventFromMap(e as Map<String, dynamic>)));
      }
    } catch (_) {}
  }

  CalendarEvent _eventFromMap(Map<String, dynamic> m) => CalendarEvent(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        description: m['description'] as String?,
        location: m['location'] as String?,
        startTime: DateTime.tryParse(m['startTime'] as String? ?? '') ?? DateTime.now(),
        endTime: DateTime.tryParse(m['endTime'] as String? ?? '') ?? DateTime.now(),
        type: EventType.values.firstWhere(
          (t) => t.name == (m['type'] as String?),
          orElse: () => EventType.other,
        ),
        isAllDay: (m['isAllDay'] as bool?) ?? false,
        attendees: (m['attendees'] as List?)?.cast<String>() ?? [],
      );

  @override
  Future<List<CalendarEvent>> getUpcomingEvents({
    required DateTime startTime,
    required DateTime endTime,
  }) async =>
      _events
          .where((e) =>
              e.startTime.isAfter(startTime) && e.startTime.isBefore(endTime))
          .toList();

  @override
  void dispose() {}
}

/// Reads contacts from the **system address book** via [flutter_contacts].
class ContactServiceImpl implements ContactService {
  bool _canAccess = false;

  static bool _isGranted(fc.PermissionStatus s) =>
      s == fc.PermissionStatus.granted || s == fc.PermissionStatus.limited;

  @override
  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      if (await fc.FlutterContacts.permissions.has(fc.PermissionType.read)) {
        _canAccess = true;
        return;
      }
      final req = await fc.FlutterContacts.permissions.request(fc.PermissionType.read);
      _canAccess = _isGranted(req);
    } catch (_) {
      _canAccess = false;
    }
  }

  static Contact _mapFcContact(fc.Contact c) {
    final first = c.name?.first ?? '';
    final last = c.name?.last ?? '';
    final combined =
        '${first.isEmpty ? '' : '$first '}${last.isEmpty ? '' : last}'.trim();
    final display = c.displayName;
    final name = (display != null && display.isNotEmpty)
        ? display
        : (combined.isEmpty ? 'Contact' : combined);

    String? phone;
    if (c.phones.isNotEmpty) {
      phone = c.phones.first.number;
    }
    String? email;
    if (c.emails.isNotEmpty) {
      email = c.emails.first.address;
    }
    String? address;
    if (c.addresses.isNotEmpty) {
      final a = c.addresses.first;
      address = a.formatted;
      if (address == null || address.isEmpty) {
        final parts = <String>[];
        for (final s in [a.street, a.city, a.postalCode, a.country]) {
          if (s != null && s.isNotEmpty) parts.add(s);
        }
        address = parts.isEmpty ? null : parts.join(', ');
      }
    }

    return Contact(
      id: c.id ?? '',
      name: name,
      phoneNumber: phone,
      email: email,
      address: address,
    );
  }

  @override
  Future<List<Contact>> getContacts() async {
    if (kIsWeb || !_canAccess) return [];
    try {
      final list = await fc.FlutterContacts.getAll(
        properties: {
          fc.ContactProperty.phone,
          fc.ContactProperty.email,
          fc.ContactProperty.address,
        },
      );
      return list.map(_mapFcContact).toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Contact?> getContactById(String id) async {
    if (kIsWeb || !_canAccess || id.isEmpty) return null;
    try {
      final c = await fc.FlutterContacts.get(
        id,
        properties: {
          fc.ContactProperty.phone,
          fc.ContactProperty.email,
          fc.ContactProperty.address,
        },
      );
      return c == null ? null : _mapFcContact(c);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {}
}

class LocationServiceImpl implements LocationService {
  @override
  Future<void> initialize() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (_) {}
  }

  @override
  Future<Position?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final token = Environment.mapboxPublicToken;
      final url =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json'
          '?access_token=$token&language=ro&limit=1';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          return features.first['place_name'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {}
}

class WeatherServiceImpl implements WeatherService {
  @override
  Future<void> initialize() async {}

  Future<Map<String, double>?> _geocode(String location) async {
    try {
      final token = Environment.mapboxPublicToken;
      final encoded = Uri.encodeComponent(location);
      final response = await http.get(Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json'
          '?access_token=$token&limit=1'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final coords = features.first['center'] as List;
          return {
            'lng': (coords[0] as num).toDouble(),
            'lat': (coords[1] as num).toDouble(),
          };
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<WeatherInfo?> getCurrentWeather(String location) async {
    try {
      final coords = await _geocode(location);
      if (coords == null) return null;
      final url =
          'https://api.open-meteo.com/v1/forecast'
          '?latitude=${coords['lat']}&longitude=${coords['lng']}'
          '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code'
          '&timezone=auto';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>;
        final temp = (current['temperature_2m'] as num).toDouble();
        final humidity = (current['relative_humidity_2m'] as num).toDouble();
        final wind = (current['wind_speed_10m'] as num).toDouble();
        final code = current['weather_code'] as int;
        return WeatherInfo(
          condition: _codeToCondition(code),
          temperature: temp,
          humidity: humidity,
          windSpeed: wind,
          description: _codeToDescription(code, temp),
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<WeatherInfo?> getWeatherForecast(String location, DateTime date) async {
    try {
      final coords = await _geocode(location);
      if (coords == null) return null;
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final url =
          'https://api.open-meteo.com/v1/forecast'
          '?latitude=${coords['lat']}&longitude=${coords['lng']}'
          '&daily=weather_code,temperature_2m_max,temperature_2m_min,'
          'relative_humidity_2m_mean,wind_speed_10m_max'
          '&timezone=auto&start_date=$dateStr&end_date=$dateStr';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final daily = data['daily'] as Map<String, dynamic>;
        final codes = daily['weather_code'] as List;
        if (codes.isEmpty) return null;
        final maxT = (daily['temperature_2m_max'] as List).first as num;
        final minT = (daily['temperature_2m_min'] as List).first as num;
        final humidity = ((daily['relative_humidity_2m_mean'] as List?)?.first as num?)?.toDouble() ?? 60.0;
        final wind = ((daily['wind_speed_10m_max'] as List).first as num).toDouble();
        final code = codes.first as int;
        final avgTemp = (maxT + minT) / 2;
        return WeatherInfo(
          condition: _codeToCondition(code),
          temperature: avgTemp,
          humidity: humidity,
          windSpeed: wind,
          description: _codeToDescription(code, avgTemp),
        );
      }
    } catch (_) {}
    return null;
  }

  String _codeToCondition(int code) {
    if (code == 0) return 'sunny';
    if (code <= 3) return 'cloudy';
    if (code <= 49) return 'foggy';
    if (code <= 67) return 'rainy';
    if (code <= 77) return 'snowy';
    if (code <= 82) return 'showers';
    return 'stormy';
  }

  String _codeToDescription(int code, double temp) {
    final t = '${temp.toStringAsFixed(1)}°C';
    if (code == 0) return 'Senin, $t';
    if (code <= 3) return 'Parțial noros, $t';
    if (code <= 49) return 'Ceață, $t';
    if (code <= 67) return 'Ploaie, $t';
    if (code <= 77) return 'Ninsoare, $t';
    if (code <= 82) return 'Averse, $t';
    return 'Furtună, $t';
  }

  @override
  void dispose() {}
}

class TrafficServiceImpl implements TrafficService {
  @override
  Future<void> initialize() async {}

  @override
  Future<TrafficInfo?> getCurrentTraffic(String location) async {
    // Estimate traffic based on time of day (rush hours)
    final hour = DateTime.now().hour;
    final double congestion;
    final String description;
    final int delay;
    if ((hour >= 7 && hour <= 9) || (hour >= 16 && hour <= 19)) {
      congestion = 0.8;
      delay = 15;
      description = 'Trafic intens — oră de vârf';
    } else if ((hour >= 10 && hour <= 15) || (hour >= 20 && hour <= 22)) {
      congestion = 0.4;
      delay = 5;
      description = 'Trafic moderat';
    } else {
      congestion = 0.1;
      delay = 0;
      description = 'Trafic ușor';
    }
    return TrafficInfo(
      congestionLevel: congestion,
      alternativeRoutes: [],
      estimatedDelay: delay,
      description: description,
    );
  }

  @override
  Future<List<String>> getAlternativeRoutes(String from, String to) async {
    try {
      final token = Environment.mapboxPublicToken;
      final fromCoords = await _geocode(from);
      final toCoords = await _geocode(to);
      if (fromCoords == null || toCoords == null) return [];
      final url =
          'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/'
          '${fromCoords['lng']},${fromCoords['lat']};'
          '${toCoords['lng']},${toCoords['lat']}'
          '?alternatives=true&geometries=geojson&steps=false&access_token=$token';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List? ?? [];
        return routes.asMap().entries.map((entry) {
          final r = entry.value as Map<String, dynamic>;
          final duration = ((r['duration'] as num) / 60).round();
          final distance = ((r['distance'] as num) / 1000).toStringAsFixed(1);
          return 'Ruta ${entry.key + 1}: ${distance}km, ~${duration}min';
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, double>?> _geocode(String location) async {
    try {
      final token = Environment.mapboxPublicToken;
      final encoded = Uri.encodeComponent(location);
      final response = await http.get(Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json'
          '?access_token=$token&limit=1'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final coords = features.first['center'] as List;
          return {
            'lng': (coords[0] as num).toDouble(),
            'lat': (coords[1] as num).toDouble(),
          };
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {}
}
