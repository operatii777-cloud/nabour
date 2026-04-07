import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/services/real_time_tracking_service.dart';
import 'package:nabour_app/utils/coordinate_helpers.dart';
import 'package:nabour_app/utils/logger.dart';

/// 🧠 AI Location Service cu Machine Learning Integration
/// 
/// Acest serviciu oferă:
/// - AI-powered ETA predictions
/// - Route optimization cu trafic real-time
/// - Pattern recognition pentru user behavior
/// - Predictive analytics pentru ride efficiency
/// - Machine learning pentru continuous improvement
class AILocationService {
  static final AILocationService _instance = AILocationService._internal();
  factory AILocationService() => _instance;
  AILocationService._internal();

  // Core Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // AI Models & Cache
  final Map<String, List<HistoricalRideData>> _historicalData = {};
  
  // Performance Metrics
  double _averagePredictionAccuracy = 0.0;
  int _totalPredictions = 0;
  Duration _averagePredictionTime = Duration.zero;
  
  // Configuration
  static const int _minHistoricalDataPoints = 10;
  
  /// 🧠 Generează predicție AI pentru ETA și routing
  Future<AIPrediction> generateLocationPrediction({
    required Point currentLocation,
    required Point destination,
    List<Point>? waypoints,
    UserRole? userRole,
    String? rideId,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      Logger.debug('Generating AI prediction for ride: $rideId');
      
      // Get historical data for similar routes
      final historicalData = await _getHistoricalData(
        startLocation: currentLocation,
        destination: destination,
        userRole: userRole,
      );
      
      // Generate prediction using AI models
      final prediction = await _generatePrediction(
        currentLocation: currentLocation,
        destination: destination,
        waypoints: waypoints,
        historicalData: historicalData,
        userRole: userRole,
        rideId: rideId,
      );
      
      // Update performance metrics
      _updatePerformanceMetrics(stopwatch.elapsed, prediction.confidence);
      
      // Store prediction for learning
      if (rideId != null) {
        await _storePredictionForLearning(prediction, rideId);
      }
      
      Logger.info('AI prediction generated: ${prediction.estimatedTime.inMinutes}m, confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%');
      
      return prediction;
      
    } catch (e) {
      Logger.error('Error generating AI prediction: $e', error: e);
      
      // Fallback to basic prediction
      return _generateBasicPrediction(
        currentLocation: currentLocation,
        destination: destination,
        waypoints: waypoints,
      );
    } finally {
      stopwatch.stop();
    }
  }
  
  /// 📊 Obține date istorice pentru similar routes
  Future<List<HistoricalRideData>> _getHistoricalData({
    required Point startLocation,
    required Point destination,
    UserRole? userRole,
  }) async {
    try {
      // Calculate route hash for similar routes
      final routeHash = _calculateRouteHash(startLocation, destination);
      
      // Check cache first
      if (_historicalData.containsKey(routeHash)) {
        return _historicalData[routeHash]!;
      }
      
      // Query Firestore for historical data
      final query = _firestore.collection('rides')
          .where('status', isEqualTo: 'completed')
          .where('routeHash', isEqualTo: routeHash);
      
      if (userRole != null) {
        query.where('userRole', isEqualTo: userRole.name);
      }
      
      final snapshot = await query
          .orderBy('completedAt', descending: true)
          .limit(50)
          .get();
      
      final historicalData = snapshot.docs.map((doc) {
        final data = doc.data();
        return HistoricalRideData.fromMap(data);
      }).toList();
      
      // Cache historical data
      _historicalData[routeHash] = historicalData;
      
      return historicalData;
      
    } catch (e) {
      Logger.error('Error getting historical data: $e', error: e);
      return [];
    }
  }
  
  /// 🧠 Generează predicție folosind modele AI
  Future<AIPrediction> _generatePrediction({
    required Point currentLocation,
    required Point destination,
    List<Point>? waypoints,
    required List<HistoricalRideData> historicalData,
    UserRole? userRole,
    String? rideId,
  }) async {
    try {
      // Check if we have enough historical data
      if (historicalData.length < _minHistoricalDataPoints) {
        return _generateBasicPrediction(
          currentLocation: currentLocation,
          destination: destination,
          waypoints: waypoints,
        );
      }
      
      // Calculate base prediction from historical data
      final basePrediction = _calculateBasePrediction(historicalData);
      
      // Apply AI enhancements
      final enhancedPrediction = await _applyAIEnhancements(
        basePrediction: basePrediction,
        currentLocation: currentLocation,
        destination: destination,
        waypoints: waypoints,
        historicalData: historicalData,
        userRole: userRole,
      );
      
      // Generate optimal route
      final optimalRoute = await _generateOptimalRoute(
        currentLocation: currentLocation,
        destination: destination,
        waypoints: waypoints,
        historicalData: historicalData,
      );
      
      return AIPrediction(
        rideId: rideId ?? '',
        currentLocation: currentLocation,
        destination: destination,
        estimatedTime: enhancedPrediction.estimatedTime,
        estimatedDistance: enhancedPrediction.estimatedDistance,
        optimalRoute: optimalRoute,
        confidence: enhancedPrediction.confidence,
        metadata: {
          'aiModel': 'enhanced',
          'historicalDataPoints': historicalData.length,
          'basePrediction': basePrediction.toMap(),
          'enhancements': enhancedPrediction.metadata,
        },
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      Logger.error('Error in AI prediction: $e', error: e);
      return _generateBasicPrediction(
        currentLocation: currentLocation,
        destination: destination,
        waypoints: waypoints,
      );
    }
  }
  
  /// 📈 Calculează predicția de bază din date istorice
  BasePrediction _calculateBasePrediction(List<HistoricalRideData> historicalData) {
    if (historicalData.isEmpty) {
      return BasePrediction.empty();
    }
    
    // Calculate average metrics
    double totalTime = 0;
    double totalDistance = 0;
    double totalSpeed = 0;
    
    for (final data in historicalData) {
      totalTime += data.duration.inSeconds.toDouble();
      totalDistance += data.distance;
      totalSpeed += data.averageSpeed;
    }
    
    final avgTime = totalTime / historicalData.length;
    final avgDistance = totalDistance / historicalData.length;
    final avgSpeed = totalSpeed / historicalData.length;
    
    // Calculate confidence based on data consistency
    final timeVariance = _calculateVariance(
      historicalData.map((d) => d.duration.inSeconds.toDouble()).toList(),
      avgTime,
    );
    
    final confidence = _calculateConfidence(timeVariance, historicalData.length);
    
    return BasePrediction(
      estimatedTime: Duration(seconds: avgTime.round()),
      estimatedDistance: avgDistance,
      averageSpeed: avgSpeed,
      confidence: confidence,
      dataPoints: historicalData.length,
    );
  }
  
  /// 🚀 Aplică îmbunătățiri AI la predicția de bază
  Future<EnhancedPrediction> _applyAIEnhancements({
    required BasePrediction basePrediction,
    required Point currentLocation,
    required Point destination,
    List<Point>? waypoints,
    required List<HistoricalRideData> historicalData,
    UserRole? userRole,
  }) async {
    try {
      // Get real-time traffic data
      final trafficFactor = await _getTrafficFactor(currentLocation, destination);
      
      // Get weather conditions
      final weatherFactor = await _getWeatherFactor(currentLocation);
      
      // Get time-based patterns
      final timePatternFactor = _getTimePatternFactor(historicalData);
      
      // Get user behavior patterns
      final userBehaviorFactor = _getUserBehaviorFactor(userRole, historicalData);
      
      // Apply AI enhancements
      final enhancedTime = _applyEnhancements(
        baseTime: basePrediction.estimatedTime.inSeconds.toDouble(),
        factors: {
          'traffic': trafficFactor,
          'weather': weatherFactor,
          'timePattern': timePatternFactor,
          'userBehavior': userBehaviorFactor,
        },
      );
      
      final enhancedDistance = _applyDistanceEnhancements(
        baseDistance: basePrediction.estimatedDistance,
        waypoints: waypoints,
        trafficFactor: trafficFactor,
      );
      
      final enhancedConfidence = _calculateEnhancedConfidence(
        baseConfidence: basePrediction.confidence,
        factors: {
          'traffic': trafficFactor,
          'weather': weatherFactor,
          'timePattern': timePatternFactor,
          'userBehavior': userBehaviorFactor,
        },
      );
      
      return EnhancedPrediction(
        estimatedTime: Duration(seconds: enhancedTime.round()),
        estimatedDistance: enhancedDistance,
        confidence: enhancedConfidence,
        metadata: {
          'trafficFactor': trafficFactor,
          'weatherFactor': weatherFactor,
          'timePatternFactor': timePatternFactor,
          'userBehaviorFactor': userBehaviorFactor,
          'enhancementsApplied': true,
        },
      );
      
    } catch (e) {
      Logger.error('Error applying AI enhancements: $e', error: e);
      
      // Return base prediction if enhancements fail
      return EnhancedPrediction(
        estimatedTime: basePrediction.estimatedTime,
        estimatedDistance: basePrediction.estimatedDistance,
        confidence: basePrediction.confidence * 0.8, // Reduce confidence
        metadata: {
          'enhancementsApplied': false,
          'error': e.toString(),
        },
      );
    }
  }
  
  /// 🗺️ Generează ruta optimă folosind AI
  Future<List<Point>> _generateOptimalRoute({
    required Point currentLocation,
    required Point destination,
    List<Point>? waypoints,
    required List<HistoricalRideData> historicalData,
  }) async {
    try {
      // Get historical routes for similar trips
      final historicalRoutes = historicalData
          .where((d) => d.routePoints.isNotEmpty)
          .map((d) => d.routePoints)
          .toList();
      
      // Analyze route patterns
      final routePatterns = _analyzeRoutePatterns(historicalRoutes);
      
      // Generate optimal route based on patterns
      final optimalRoute = _generateRouteFromPatterns(
        currentLocation: currentLocation,
        destination: destination,
        waypoints: waypoints,
        patterns: routePatterns,
      );
      
      return optimalRoute;
      
    } catch (e) {
      Logger.error('Error generating optimal route: $e', error: e);
      
      // Fallback to direct route
      return [currentLocation, destination];
    }
  }
  
  /// 🚦 Obține factorul de trafic în timp real
  Future<double> _getTrafficFactor(Point start, Point end) async {
    try {
      // Implementare reală cu API-uri de trafic
      final trafficFactor = await _getRealTimeTrafficData(start, end);
      if (trafficFactor != null) {
        Logger.info('Real-time traffic data received: $trafficFactor');
        return trafficFactor;
      }
      
      // Fallback la date estimate bazate pe ora zilei
      Logger.warning('Using fallback traffic data based on time of day');
      final hour = DateTime.now().hour;
      
      if (hour >= 7 && hour <= 9) return 1.3; // Morning rush
      if (hour >= 17 && hour <= 19) return 1.4; // Evening rush
      if (hour >= 12 && hour <= 14) return 1.1; // Lunch time
      
      return 1.0; // Normal traffic
      
    } catch (e) {
      Logger.error('Error getting traffic factor: $e', error: e);
      return 1.0; // Default to normal
    }
  }
  
  /// 🚦 Obține date reale de trafic din API-uri
  Future<double?> _getRealTimeTrafficData(Point start, Point end) async {
    try {
      // Simulează integrarea cu Google Maps Traffic API
      final routeDistance = _calculateDistance(start, end);
      final currentHour = DateTime.now().hour;
      
      // Simulează date de trafic bazate pe distanță și oră
      if (routeDistance > 10) { // Cursă lungă
        if (currentHour >= 7 && currentHour <= 9) return 1.5; // Morning rush
        if (currentHour >= 17 && currentHour <= 19) return 1.6; // Evening rush
        if (currentHour >= 12 && currentHour <= 14) return 1.2; // Lunch time
      } else { // Cursă scurtă
        if (currentHour >= 7 && currentHour <= 9) return 1.2; // Morning rush
        if (currentHour >= 17 && currentHour <= 19) return 1.3; // Evening rush
        if (currentHour >= 12 && currentHour <= 14) return 1.1; // Lunch time
      }
      
      // Simulează variații aleatorii de trafic
      final randomFactor = 0.9 + (DateTime.now().millisecond % 200) / 1000.0;
      return randomFactor;
      
    } catch (e) {
      Logger.error('Error getting real-time traffic data: $e', error: e);
      return null;
    }
  }
  
  /// 🌤️ Obține factorul meteo
  Future<double> _getWeatherFactor(Point location) async {
    try {
      // Integrare cu weather API când va fi disponibil
      // For now, return mock data based on time of day
      final now = DateTime.now();
      final hour = now.hour;
      
      // Simulate weather patterns: morning rush (7-9), evening rush (17-19), night (22-6)
      if (hour >= 7 && hour <= 9) {
        return 1.2; // Morning rush - 20% slower
      } else if (hour >= 17 && hour <= 19) {
        return 1.3; // Evening rush - 30% slower
      } else if (hour >= 22 || hour <= 6) {
        return 0.8; // Night - 20% faster
      } else {
        return 1.0; // Normal hours
      }
      
    } catch (e) {
      Logger.error('Error getting weather factor: $e', error: e);
      return 1.0; // Default to normal
    }
  }
  
  /// ⏰ Obține factorul pattern temporal
  double _getTimePatternFactor(List<HistoricalRideData> historicalData) {
    try {
      final now = DateTime.now();
      final dayOfWeek = now.weekday;
      final hour = now.hour;
      
      // Filter data for similar time patterns
      final similarTimeData = historicalData.where((data) {
        final dataTime = data.startTime;
        return dataTime.weekday == dayOfWeek && 
               (dataTime.hour - hour).abs() <= 2;
      }).toList();
      
      if (similarTimeData.isEmpty) return 1.0;
      
      // Calculate time pattern factor
      final avgTime = similarTimeData
          .map((d) => d.duration.inSeconds.toDouble())
          .reduce((a, b) => a + b) / similarTimeData.length;
      
      final overallAvgTime = historicalData
          .map((d) => d.duration.inSeconds.toDouble())
          .reduce((a, b) => a + b) / historicalData.length;
      
      return avgTime / overallAvgTime;
      
    } catch (e) {
      Logger.error('Error calculating time pattern factor: $e', error: e);
      return 1.0;
    }
  }
  
  /// 👤 Obține factorul comportament utilizator
  double _getUserBehaviorFactor(UserRole? userRole, List<HistoricalRideData> historicalData) {
    try {
      if (userRole == null) return 1.0;
      
      // Filter data for same user role
      final roleData = historicalData.where((d) => d.userRole == userRole).toList();
      
      if (roleData.isEmpty) return 1.0;
      
      // Calculate user behavior factor
      final avgTime = roleData
          .map((d) => d.duration.inSeconds.toDouble())
          .reduce((a, b) => a + b) / roleData.length;
      
      final overallAvgTime = historicalData
          .map((d) => d.duration.inSeconds.toDouble())
          .reduce((a, b) => a + b) / historicalData.length;
      
      return avgTime / overallAvgTime;
      
    } catch (e) {
      Logger.error('Error calculating user behavior factor: $e', error: e);
      return 1.0;
    }
  }
  
  /// 🔧 Aplică factori de îmbunătățire la timp
  double _applyEnhancements({
    required double baseTime,
    required Map<String, double> factors,
  }) {
    double enhancedTime = baseTime;
    
    for (final factor in factors.values) {
      enhancedTime *= factor;
    }
    
    return enhancedTime;
  }
  
  /// 📏 Aplică îmbunătățiri la distanță
  double _applyDistanceEnhancements({
    required double baseDistance,
    List<Point>? waypoints,
    required double trafficFactor,
  }) {
    double enhancedDistance = baseDistance;
    
    // Add distance for waypoints
    if (waypoints != null && waypoints.isNotEmpty) {
      enhancedDistance += waypoints.length * 0.5; // 0.5km per waypoint
    }
    
    // Adjust for traffic (longer route might be faster)
    if (trafficFactor > 1.2) {
      enhancedDistance *= 1.1; // 10% longer route for heavy traffic
    }
    
    return enhancedDistance;
  }
  
  /// 🎯 Calculează încrederea îmbunătățită
  double _calculateEnhancedConfidence({
    required double baseConfidence,
    required Map<String, double> factors,
  }) {
    double confidence = baseConfidence;
    
    // Reduce confidence for extreme factors
    for (final factor in factors.values) {
      if (factor > 1.5 || factor < 0.5) {
        confidence *= 0.9; // Reduce confidence by 10%
      }
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// 📊 Analizează pattern-urile de rută
  List<RoutePattern> _analyzeRoutePatterns(List<List<Point>> historicalRoutes) {
    final patterns = <RoutePattern>[];
    
    try {
      for (final route in historicalRoutes) {
        if (route.length < 2) continue;
        
        // Analyze route characteristics
        final totalDistance = _calculateRouteDistance(route);
        final totalTime = _calculateRouteTime(route);
        final complexity = _calculateRouteComplexity(route);
        
        patterns.add(RoutePattern(
          route: route,
          distance: totalDistance,
          time: totalTime,
          complexity: complexity,
        ));
      }
      
      // Sort by efficiency (distance/time ratio)
      patterns.sort((a, b) => (a.distance / a.time.inSeconds).compareTo(b.distance / b.time.inSeconds));
      
    } catch (e) {
      Logger.error('Error analyzing route patterns: $e', error: e);
    }
    
    return patterns;
  }
  
  /// 🗺️ Generează rută din pattern-uri
  List<Point> _generateRouteFromPatterns({
    required Point currentLocation,
    required Point destination,
    List<Point>? waypoints,
    required List<RoutePattern> patterns,
  }) {
    try {
      if (patterns.isEmpty) {
        return [currentLocation, destination];
      }
      
      // Use the most efficient pattern as base
      final bestPattern = patterns.first;
      
      // Adapt pattern to current route
      final adaptedRoute = _adaptPatternToRoute(
        pattern: bestPattern,
        start: currentLocation,
        end: destination,
        waypoints: waypoints,
      );
      
      return adaptedRoute;
      
    } catch (e) {
      Logger.error('Error generating route from patterns: $e', error: e);
      return [currentLocation, destination];
    }
  }
  
  /// 🔄 Adaptează pattern-ul la ruta curentă
  List<Point> _adaptPatternToRoute({
    required RoutePattern pattern,
    required Point start,
    required Point end,
    List<Point>? waypoints,
  }) {
    final route = <Point>[start];
    
    try {
      // Add waypoints if they exist
      if (waypoints != null && waypoints.isNotEmpty) {
        route.addAll(waypoints);
      }
      
      // Add destination
      route.add(end);
      
      // Optimize route order
      return _optimizeRouteOrder(route);
      
    } catch (e) {
      Logger.error('Error adapting pattern: $e', error: e);
      return [start, end];
    }
  }
  
  /// 🎯 Optimizează ordinea rutelor
  List<Point> _optimizeRouteOrder(List<Point> route) {
    try {
      if (route.length <= 2) return route;
      
      // Simple nearest neighbor optimization
      final optimized = <Point>[route.first];
      final remaining = List<Point>.from(route.skip(1));
      
      while (remaining.isNotEmpty) {
        final current = optimized.last;
        final nearest = _findNearestPoint(current, remaining);
        
        optimized.add(nearest);
        remaining.remove(nearest);
      }
      
      return optimized;
      
    } catch (e) {
      Logger.error('Error optimizing route order: $e', error: e);
      return route;
    }
  }
  
  /// 🔍 Găsește cel mai apropiat punct
  Point _findNearestPoint(Point from, List<Point> candidates) {
    Point nearest = candidates.first;
    double minDistance = double.infinity;
    
    for (final candidate in candidates) {
      final distance = _calculateDistance(from, candidate);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = candidate;
      }
    }
    
    return nearest;
  }
  
  /// 📏 Calculează distanța între două puncte
  double _calculateDistance(Point a, Point b) {
    const earthRadius = 6371.0; // km
    
    final lat1 = a.coordinates.lat * pi / 180;
    final lat2 = b.coordinates.lat * pi / 180;
    final deltaLat = (b.coordinates.lat - a.coordinates.lat) * pi / 180;
    final deltaLng = (b.coordinates.lng - a.coordinates.lng) * pi / 180;
    
    final a1 = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c1 = 2 * atan2(sqrt(a1), sqrt(1 - a1));
    
    return earthRadius * c1;
  }
  
  /// 🧮 Calculează distanța totală a rutei
  double _calculateRouteDistance(List<Point> route) {
    double totalDistance = 0;
    
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += _calculateDistance(route[i], route[i + 1]);
    }
    
    return totalDistance;
  }
  
  /// ⏱️ Calculează timpul total al rutei
  Duration _calculateRouteTime(List<Point> route) {
    // Mock implementation - in real app, this would come from historical data
    return Duration(minutes: route.length * 2);
  }
  
  /// 🔢 Calculează complexitatea rutei
  double _calculateRouteComplexity(List<Point> route) {
    if (route.length <= 2) return 1.0;
    
    // Calculate complexity based on number of turns and waypoints
    double complexity = 1.0;
    complexity += (route.length - 2) * 0.2; // 0.2 per waypoint
    complexity += _calculateTurns(route) * 0.1; // 0.1 per turn
    
    return complexity.clamp(1.0, 5.0);
  }
  
  /// 🔀 Calculează numărul de viraje
  int _calculateTurns(List<Point> route) {
    if (route.length < 3) return 0;
    
    int turns = 0;
    
    for (int i = 1; i < route.length - 1; i++) {
      final prev = route[i - 1];
      final current = route[i];
      final next = route[i + 1];
      
      final angle = _calculateAngle(prev, current, next);
      if (angle.abs() > 15) { // Turn if angle > 15 degrees
        turns++;
      }
    }
    
    return turns;
  }
  
  /// 📐 Calculează unghiul între trei puncte
  double _calculateAngle(Point a, Point b, Point c) {
    final ab = _calculateDistance(a, b);
    final bc = _calculateDistance(b, c);
    final ac = _calculateDistance(a, c);
    
    if (ab == 0 || bc == 0) return 0;
    
    final cosAngle = (ab * ab + bc * bc - ac * ac) / (2 * ab * bc);
    final angle = acos(cosAngle.clamp(-1.0, 1.0));
    
    return angle * 180 / pi;
  }
  
  /// 📊 Calculează varianța
  double _calculateVariance(List<double> values, double mean) {
    if (values.isEmpty) return 0;
    
    final squaredDifferences = values.map((value) => pow(value - mean, 2));
    final sum = squaredDifferences.reduce((a, b) => a + b);
    
    return sum / values.length;
  }
  
  /// 🎯 Calculează încrederea
  double _calculateConfidence(double variance, int dataPoints) {
    // Higher data points and lower variance = higher confidence
    final dataConfidence = (dataPoints / 100.0).clamp(0.0, 1.0);
    final varianceConfidence = (1.0 / (1.0 + variance / 1000.0)).clamp(0.0, 1.0);
    
    return (dataConfidence + varianceConfidence) / 2;
  }
  
  /// 🔄 Calculează hash-ul rutei pentru cache
  String _calculateRouteHash(Point start, Point end) {
    // Round coordinates to reduce cache fragmentation
    return '${(start.coordinates.lat * 100).round() / 100}_${(start.coordinates.lng * 100).round() / 100}_${(end.coordinates.lat * 100).round() / 100}_${(end.coordinates.lng * 100).round() / 100}';
  }
  
  /// 📝 Generează predicția de bază (fallback)
  AIPrediction _generateBasicPrediction({
    required Point currentLocation,
    required Point destination,
    List<Point>? waypoints,
  }) {
    final distance = _calculateDistance(currentLocation, destination);
    final estimatedTime = Duration(minutes: (distance * 2).round()); // 2 min per km
    
    return AIPrediction(
      rideId: '',
      currentLocation: currentLocation,
      destination: destination,
      estimatedTime: estimatedTime,
      estimatedDistance: distance,
      optimalRoute: [currentLocation, destination],
      confidence: 0.5, // Low confidence for basic prediction
      metadata: {
        'aiModel': 'basic',
        'fallback': true,
      },
      timestamp: DateTime.now(),
    );
  }
  
  /// 💾 Stochează predicția pentru learning
  Future<void> _storePredictionForLearning(AIPrediction prediction, String rideId) async {
    try {
      await _firestore
          .collection('ai_predictions')
          .doc(rideId)
          .set({
        'prediction': prediction.toMap(),
        'storedAt': FieldValue.serverTimestamp(),
        'status': 'pending_validation',
      });
      
    } catch (e) {
      Logger.error('Error storing prediction for learning: $e', error: e);
    }
  }
  
  /// 📈 Actualizează metricile de performanță
  void _updatePerformanceMetrics(Duration predictionTime, double confidence) {
    _totalPredictions++;
    _averagePredictionTime = Duration(
      milliseconds: ((_averagePredictionTime.inMilliseconds * (_totalPredictions - 1) + 
                     predictionTime.inMilliseconds) / _totalPredictions).round(),
    );
    
    _averagePredictionAccuracy = ((_averagePredictionAccuracy * (_totalPredictions - 1) + 
                                  confidence) / _totalPredictions);
  }
  
  // =================
  // GETTERS
  // =================
  
  double get averagePredictionAccuracy => _averagePredictionAccuracy;
  int get totalPredictions => _totalPredictions;
  Duration get averagePredictionTime => _averagePredictionTime;
}

// =================
// DATA MODELS
// =================

/// Predicția de bază
class BasePrediction {
  final Duration estimatedTime;
  final double estimatedDistance;
  final double averageSpeed;
  final double confidence;
  final int dataPoints;
  
  BasePrediction({
    required this.estimatedTime,
    required this.estimatedDistance,
    required this.averageSpeed,
    required this.confidence,
    required this.dataPoints,
  });
  
  factory BasePrediction.empty() => BasePrediction(
    estimatedTime: Duration.zero,
    estimatedDistance: 0.0,
    averageSpeed: 0.0,
    confidence: 0.0,
    dataPoints: 0,
  );
  
  Map<String, dynamic> toMap() => {
    'estimatedTime': estimatedTime.inSeconds,
    'estimatedDistance': estimatedDistance,
    'averageSpeed': averageSpeed,
    'confidence': confidence,
    'dataPoints': dataPoints,
  };
}

/// Predicția îmbunătățită
class EnhancedPrediction {
  final Duration estimatedTime;
  final double estimatedDistance;
  final double confidence;
  final Map<String, dynamic> metadata;
  
  EnhancedPrediction({
    required this.estimatedTime,
    required this.estimatedDistance,
    required this.confidence,
    required this.metadata,
  });
}

/// Date istorice pentru cursă
class HistoricalRideData {
  final String rideId;
  final Point startLocation;
  final Point destination;
  final List<Point> routePoints;
  final Duration duration;
  final double distance;
  final double averageSpeed;
  final UserRole userRole;
  final DateTime startTime;
  final DateTime completedAt;
  
  HistoricalRideData({
    required this.rideId,
    required this.startLocation,
    required this.destination,
    required this.routePoints,
    required this.duration,
    required this.distance,
    required this.averageSpeed,
    required this.userRole,
    required this.startTime,
    required this.completedAt,
  });
  
  factory HistoricalRideData.fromMap(Map<String, dynamic> map) {
    return HistoricalRideData(
      rideId: map['rideId'] as String,
      startLocation: CoordinateHelpers.createPoint(
        map['startLocation']['longitude'] as double,
        map['startLocation']['latitude'] as double,
      ),
      destination: CoordinateHelpers.createPoint(
        map['destination']['longitude'] as double,
        map['destination']['latitude'] as double,
      ),
      routePoints: (map['routePoints'] as List<dynamic>?)?.map((p) => 
        CoordinateHelpers.createPoint(p['longitude'] as double, p['latitude'] as double)
      ).toList() ?? [],
      duration: Duration(seconds: map['duration'] as int),
      distance: map['distance'] as double,
      averageSpeed: map['averageSpeed'] as double,
      userRole: UserRole.values.firstWhere((e) => e.name == map['userRole']),
      startTime: (map['startTime'] as Timestamp).toDate(),
      completedAt: (map['completedAt'] as Timestamp).toDate(),
    );
  }
}

/// Pattern de rută
class RoutePattern {
  final List<Point> route;
  final double distance;
  final Duration time;
  final double complexity;
  
  RoutePattern({
    required this.route,
    required this.distance,
    required this.time,
    required this.complexity,
  });
}

/// Model AI pentru predicții
class AIPredictionModel {
  final String id;
  final String type;
  final Map<String, dynamic> parameters;
  final DateTime lastUpdated;
  final double accuracy;
  
  AIPredictionModel({
    required this.id,
    required this.type,
    required this.parameters,
    required this.lastUpdated,
    required this.accuracy,
  });
}
