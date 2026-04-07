// Professional Logging Framework for Nabour App
// Replaces all debugPrint statements with structured logging
// Supports log levels, rotation, and production-safe logging

import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Log levels for different severity
enum LogLevel {
  debug,    // Detailed information for debugging
  info,     // General informational messages
  warning,  // Warning messages that don't stop execution
  error,    // Error messages that need attention
  critical, // Critical errors that may cause app failure
}

/// Professional logger for Nabour app
/// 
/// Features:
/// - Log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
/// - Automatic log rotation
/// - Production-safe (only ERROR+ in production)
/// - Structured logging with context
/// - Performance tracking
class Logger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.error;
  static final List<LogEntry> _logBuffer = [];
  static const int _maxBufferSize = 1000;
  static DateTime? _lastCleanup;
  static const Duration _cleanupInterval = Duration(hours: 1);

  /// Set minimum log level
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Get current minimum log level
  static LogLevel get minLevel => _minLevel;

  /// Log a debug message
  static void debug(String message, {String? tag, Map<String, dynamic>? context}) {
    _log(LogLevel.debug, message, tag: tag, context: context);
  }

  /// Log an info message
  static void info(String message, {String? tag, Map<String, dynamic>? context}) {
    _log(LogLevel.info, message, tag: tag, context: context);
  }

  /// Log a warning message
  static void warning(String message, {String? tag, Map<String, dynamic>? context}) {
    _log(LogLevel.warning, message, tag: tag, context: context);
  }

  /// Log an error message
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag, Map<String, dynamic>? context}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace, tag: tag, context: context);
  }

  /// Log a critical error
  static void critical(String message, {Object? error, StackTrace? stackTrace, String? tag, Map<String, dynamic>? context}) {
    _log(LogLevel.critical, message, error: error, stackTrace: stackTrace, tag: tag, context: context);
  }

  /// Internal logging method
  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
    Map<String, dynamic>? context,
  }) {
    // Skip if below minimum level
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      tag: tag ?? 'APP',
      error: error,
      stackTrace: stackTrace,
      context: context,
    );

    // Add to buffer
    _addToBuffer(entry);

    // Output based on environment
    if (kDebugMode) {
      _outputDebug(entry);
    } else {
      _outputProduction(entry);
    }

    // Periodic cleanup
    _performCleanupIfNeeded();
  }

  /// Add entry to buffer
  static void _addToBuffer(LogEntry entry) {
    _logBuffer.add(entry);
    
    // Rotate buffer if too large
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeRange(0, _logBuffer.length - _maxBufferSize);
    }
  }

  /// Output in debug mode (verbose)
  static void _outputDebug(LogEntry entry) {
    final emoji = _getEmoji(entry.level);
    final prefix = '$emoji [${entry.tag}]';
    final timestamp = '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';
    
    final logMessage = '$prefix $timestamp: ${entry.message}';
    
    // Use developer.log for better formatting
    developer.log(
      logMessage,
      name: entry.tag,
      level: entry.level.index,
      error: entry.error,
      stackTrace: entry.stackTrace,
    );

    // Also output context if present
    if (entry.context != null && entry.context!.isNotEmpty) {
      developer.log(
        'Context: ${entry.context}',
        name: '${entry.tag}.CONTEXT',
        level: entry.level.index,
      );
    }
  }

  /// Output in production mode (only errors)
  static void _outputProduction(LogEntry entry) {
    // In production, only log errors and critical issues
    if (entry.level.index >= LogLevel.error.index) {
      // Use developer.log for production
      developer.log(
        entry.message,
        name: entry.tag,
        level: entry.level.index,
        error: entry.error,
        stackTrace: entry.stackTrace,
      );

      // Note: Send to error tracking service (Sentry, Firebase Crashlytics, etc.)
      // _sendToErrorTracking(entry);
    }
  }

  /// Get emoji for log level
  static String _getEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }

  /// Perform cleanup if needed
  static void _performCleanupIfNeeded() {
    final now = DateTime.now();
    if (_lastCleanup == null || now.difference(_lastCleanup!) > _cleanupInterval) {
      _cleanup();
      _lastCleanup = now;
    }
  }

  /// Cleanup old logs
  static void _cleanup() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _logBuffer.removeWhere((entry) => entry.timestamp.isBefore(cutoff));
  }

  /// Get recent logs (for debugging)
  static List<LogEntry> getRecentLogs({int count = 50, LogLevel? minLevel}) {
    var logs = _logBuffer.reversed.take(count).toList();
    
    if (minLevel != null) {
      logs = logs.where((entry) => entry.level.index >= minLevel.index).toList();
    }
    
    return logs;
  }

  /// Clear all logs
  static void clear() {
    _logBuffer.clear();
  }

  /// Get log statistics
  static Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    
    final recentLogs = _logBuffer.where((entry) => entry.timestamp.isAfter(last24h)).toList();
    
    return {
      'total_logs': _logBuffer.length,
      'recent_logs_24h': recentLogs.length,
      'by_level': {
        'debug': recentLogs.where((e) => e.level == LogLevel.debug).length,
        'info': recentLogs.where((e) => e.level == LogLevel.info).length,
        'warning': recentLogs.where((e) => e.level == LogLevel.warning).length,
        'error': recentLogs.where((e) => e.level == LogLevel.error).length,
        'critical': recentLogs.where((e) => e.level == LogLevel.critical).length,
      },
    };
  }
}

/// Log entry model
class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final String tag;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    required this.tag,
    this.error,
    this.stackTrace,
    this.context,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[$level] $tag: $message');
    if (error != null) {
      buffer.write(' | Error: $error');
    }
    if (context != null && context!.isNotEmpty) {
      buffer.write(' | Context: $context');
    }
    return buffer.toString();
  }
}

/// Extension for easy logging
extension LoggerExtension on Object {
  /// Log debug message with object context
  void logDebug(String message, {String? tag}) {
    Logger.debug(message, tag: tag ?? runtimeType.toString(), context: {'object': toString()});
  }

  /// Log error with object context
  void logError(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    Logger.error(
      message,
      error: error,
      stackTrace: stackTrace,
      tag: tag ?? runtimeType.toString(),
      context: {'object': toString()},
    );
  }
}

