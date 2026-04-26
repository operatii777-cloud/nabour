import 'dart:async';
import 'package:nabour_app/utils/logger.dart';

/// Comprehensive performance monitoring service with memory leak prevention
class PerformanceMonitor {
  // MEMORY LEAK PREVENTION CONSTANTS
  static const int _maxDataEntries = 50;
  static const Duration _maxMetricAge = Duration(days: 7);
  static const Duration _maxAlertAge = Duration(days: 3);
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const int _maxStackTraceLength = 500;
  
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // MEMORY LEAK PREVENTION - Stream Controller Management
  final StreamController<PerformanceMetric> _metricController = StreamController<PerformanceMetric>.broadcast();
  final StreamController<PerformanceAlert> _alertController = StreamController<PerformanceAlert>.broadcast();
  
  // Data storage with memory limits
  final Map<String, List<dynamic>> _metrics = {};
  final List<PerformanceAlert> _alerts = [];
  
  // Cleanup management
  Timer? _cleanupTimer;
  bool _isInitialized = false;
  
  /// Stream of performance metrics
  Stream<PerformanceMetric> get metrics => _metricController.stream;
  
  /// Stream of performance alerts
  Stream<PerformanceAlert> get alerts => _alertController.stream;
  
  /// Initialize performance monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _startPeriodicCleanup();
      _isInitialized = true;
      Logger.info('PerformanceMonitor initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize PerformanceMonitor: $e', error: e);
    }
  }
  
  /// Record a performance metric
  void recordMetric(String name, dynamic value, {
    Map<String, dynamic>? metadata,
    String? category,
    String? userId,
  }) {
    final metric = PerformanceMetric(
      name: name,
      value: value,
      metadata: metadata ?? {},
      category: category,
      userId: userId,
      timestamp: DateTime.now(),
    );
    
    _addMetric(name, metric);
    if (!_metricController.isClosed) _metricController.add(metric);
    
    // Check for performance thresholds
    _checkPerformanceThresholds(name, value, metadata);
  }

  /// Helper: record navigation telemetry (reroute time, route calc, tts failure)
  void recordNavTelemetry(String event, Map<String, dynamic> data) {
    recordMetric('nav_$event', 1, metadata: data, category: 'navigation');
  }
  
  /// Record a performance error
  void recordError(String errorType, String message, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? userId,
    String? category,
  }) {
    // Limit stack trace size to prevent memory issues
    String? limitedStackTrace;
    if (stackTrace != null) {
      final stackTraceStr = stackTrace.toString();
      limitedStackTrace = stackTraceStr.length > _maxStackTraceLength
          ? stackTraceStr.substring(0, _maxStackTraceLength)
          : stackTraceStr;
    }
    
    final alert = PerformanceAlert(
      type: AlertType.error,
      title: errorType,
      message: message,
      stackTrace: limitedStackTrace,
      context: context,
      userId: userId,
      category: category,
      timestamp: DateTime.now(),
      severity: AlertSeverity.high,
    );
    
    _addAlert(alert);
    if (!_alertController.isClosed) _alertController.add(alert);

    // Record as metric for tracking
    recordMetric('error_count', 1, metadata: {
      'error_type': errorType,
      'message': message,
      'has_stack_trace': stackTrace != null,
    }, category: category, userId: userId);
  }
  
  /// Record a performance warning
  void recordWarning(String warningType, String message, {
    Map<String, dynamic>? context,
    String? userId,
    String? category,
  }) {
    final alert = PerformanceAlert(
      type: AlertType.warning,
      title: warningType,
      message: message,
      context: context,
      userId: userId,
      category: category,
      timestamp: DateTime.now(),
      severity: AlertSeverity.medium,
    );
    
    _addAlert(alert);
    if (!_alertController.isClosed) _alertController.add(alert);
  }

  /// Record a performance info message
  void recordInfo(String infoType, String message, {
    Map<String, dynamic>? context,
    String? userId,
    String? category,
  }) {
    final alert = PerformanceAlert(
      type: AlertType.info,
      title: infoType,
      message: message,
      context: context,
      userId: userId,
      category: category,
      timestamp: DateTime.now(),
      severity: AlertSeverity.low,
    );
    
    _addAlert(alert);
    if (!_alertController.isClosed) _alertController.add(alert);
  }

  /// Start a performance timer
  void startTimer(String operationName, {
    Map<String, dynamic>? metadata,
    String? category,
    String? userId,
  }) {
    final timerKey = 'timer_$operationName';
    recordMetric(timerKey, DateTime.now().millisecondsSinceEpoch, 
      metadata: metadata, category: category, userId: userId);
  }
  
  /// End a performance timer and record duration
  void endTimer(String operationName, {
    Map<String, dynamic>? metadata,
    String? category,
    String? userId,
  }) {
    final timerKey = 'timer_$operationName';
    final startTime = _getTimerStartTime(timerKey);
    
    if (startTime != null) {
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;
      recordMetric('${operationName}_duration', duration, 
        metadata: metadata, category: category, userId: userId);
      
      // Remove timer start time
      _removeTimerStartTime(timerKey);
    }
  }
  
  /// Get performance metrics for a specific category
  List<dynamic> getMetrics(String name, {int limit = 50}) {
    final metricList = _metrics[name];
    if (metricList == null) return [];
    
    final sortedMetrics = List<dynamic>.from(metricList);
    sortedMetrics.sort((a, b) {
      if (a is PerformanceMetric && b is PerformanceMetric) {
        return b.timestamp.compareTo(a.timestamp);
      }
      return 0;
    });
    
    return sortedMetrics.take(limit).toList();
  }
  
  /// Get all performance alerts
  List<PerformanceAlert> getAlerts({int limit = 50}) {
    final sortedAlerts = List<PerformanceAlert>.from(_alerts);
    sortedAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedAlerts.take(limit).toList();
  }
  
  /// Get alerts by severity
  List<PerformanceAlert> getAlertsBySeverity(AlertSeverity severity, {int limit = 50}) {
    final filteredAlerts = _alerts.where((alert) => alert.severity == severity).toList();
    filteredAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filteredAlerts.take(limit).toList();
  }
  
  /// Get alerts by category
  List<PerformanceAlert> getAlertsByCategory(String category, {int limit = 50}) {
    final filteredAlerts = _alerts.where((alert) => alert.category == category).toList();
    filteredAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filteredAlerts.take(limit).toList();
  }
  
  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    
    final recentMetrics = <String, int>{};
    final recentErrors = _alerts.where((alert) => 
        alert.type == AlertType.error && alert.timestamp.isAfter(last24h)).length;
    
    // Count recent metrics by category
    for (final entry in _metrics.entries) {
      final recentCount = entry.value.where((metric) {
        if (metric is PerformanceMetric) {
          return metric.timestamp.isAfter(last24h);
        }
        return false;
      }).length;
      
      if (recentCount > 0) {
        recentMetrics[entry.key] = recentCount;
      }
    }
    
    return {
      'total_metrics': _metrics.values.fold(0, (sum, list) => sum + list.length),
      'total_alerts': _alerts.length,
      'recent_metrics_24h': recentMetrics,
      'recent_errors_24h': recentErrors,
      'categories': _metrics.keys.toList(),
      'is_initialized': _isInitialized,
    };
  }
  
  /// MEMORY LEAK PREVENTION - Add metric with cleanup
  void _addMetric(String name, PerformanceMetric metric) {
    if (!_metrics.containsKey(name)) {
      _metrics[name] = [];
    }
    
    _metrics[name]!.add(metric);
    
    // Limit data entries per metric
    if (_metrics[name]!.length > _maxDataEntries) {
      _metrics[name]!.removeRange(0, _metrics[name]!.length - _maxDataEntries);
    }
    
    // Cleanup large data to prevent memory issues
    _cleanupMetricData(name);
  }
  
  /// MEMORY LEAK PREVENTION - Add alert with cleanup
  void _addAlert(PerformanceAlert alert) {
    _alerts.add(alert);
    
    // Limit total alerts
    if (_alerts.length > _maxDataEntries * 2) {
      _alerts.removeRange(0, _alerts.length - _maxDataEntries * 2);
    }
  }
  
  /// MEMORY LEAK PREVENTION - Cleanup metric data
  void _cleanupMetricData(String metricName) {
    final metricList = _metrics[metricName];
    if (metricList == null) return;
    
    // Remove large data that could cause memory issues
    metricList.removeWhere((metric) {
      if (metric is PerformanceMetric) {
        // Check metadata size
        if (metric.metadata.length > 20) return true;
        
        // Check individual metadata values
        for (final value in metric.metadata.values) {
          if (value is String && value.length > 1000) return true;
          if (value is Map && value.length > 20) return true;
          if (value is List && value.length > 50) return true;
        }
      }
      return false;
    });
  }
  
  /// Get timer start time
  int? _getTimerStartTime(String timerKey) {
    final metricList = _metrics[timerKey];
    if (metricList == null || metricList.isEmpty) return null;
    
    final lastMetric = metricList.last;
    if (lastMetric is PerformanceMetric) {
      return lastMetric.value as int?;
    }
    return null;
  }
  
  /// Remove timer start time
  void _removeTimerStartTime(String timerKey) {
    _metrics.remove(timerKey);
  }
  
  /// Check performance thresholds
  void _checkPerformanceThresholds(String name, dynamic value, Map<String, dynamic>? metadata) {
    // Example threshold checks
    if (value is num) {
      if (name.contains('duration') && value > 5000) {
        recordWarning('Slow Operation', 'Operation $name took ${value}ms', 
          context: metadata, category: 'performance');
      }
      
      if (name.contains('memory') && value > 100 * 1024 * 1024) { // 100MB
        recordWarning('High Memory Usage', 'Memory usage is ${(value / (1024 * 1024)).toStringAsFixed(2)}MB', 
          context: metadata, category: 'memory');
      }
    }
  }
  
  /// MEMORY LEAK PREVENTION - Periodic cleanup
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      _cleanupOldData();
    });
  }
  
  /// Cleanup old data
  void _cleanupOldData() {
    final metricCutoff = DateTime.now().subtract(_maxMetricAge);
    final alertCutoff = DateTime.now().subtract(_maxAlertAge);
    
    // Cleanup old metrics
    for (final entry in _metrics.entries) {
      entry.value.removeWhere((metric) {
        if (metric is PerformanceMetric) {
          return metric.timestamp.isBefore(metricCutoff);
        }
        return false;
      });
    }
    
    // Remove empty metric categories
    _metrics.removeWhere((key, value) => value.isEmpty);
    
    // Cleanup old alerts
    _alerts.removeWhere((alert) => alert.timestamp.isBefore(alertCutoff));
  }
  
  /// Stop monitoring
  void stopMonitoring() {
    _cleanupTimer?.cancel();
    _isInitialized = false;
  }
  
  /// MEMORY LEAK PREVENTION - Dispose resources
  void dispose() {
    stopMonitoring();
    
    // Close stream controllers
    _metricController.close();
    _alertController.close();
    
    // Clear data
    _metrics.clear();
    _alerts.clear();
    
    _isInitialized = false;
  }
}

/// Performance metric
class PerformanceMetric {
  final String name;
  final dynamic value;
  final Map<String, dynamic> metadata;
  final String? category;
  final String? userId;
  final DateTime timestamp;

  PerformanceMetric({
    required this.name,
    required this.value,
    required this.metadata,
    this.category,
    this.userId,
    required this.timestamp,
  });
}

/// Performance alert
class PerformanceAlert {
  final AlertType type;
  final String title;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? context;
  final String? userId;
  final String? category;
  final DateTime timestamp;
  final AlertSeverity severity;

  PerformanceAlert({
    required this.type,
    required this.title,
    required this.message,
    this.stackTrace,
    this.context,
    this.userId,
    this.category,
    required this.timestamp,
    required this.severity,
  });
}

/// Alert types
enum AlertType {
  info,
  warning,
  error,
}

/// Alert severity levels
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}
