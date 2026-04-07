/// 🔍 DEBUG CONSOLE MONITOR
/// 
/// Acest serviciu monitorizează consola de debug pentru a detecta erori,
/// warning-uri și probleme în timp real și le raportează.
library;

import 'package:flutter/foundation.dart';
import 'package:nabour_app/utils/logger.dart';

/// Tipuri de mesaje de debug
enum DebugMessageType {
  error,
  warning,
  info,
  success,
  debug,
}

/// Model pentru mesajele de debug
class DebugMessage {
  final DebugMessageType type;
  final String message;
  final String? source;
  final DateTime timestamp;
  final StackTrace? stackTrace;

  DebugMessage({
    required this.type,
    required this.message,
    this.source,
    DateTime? timestamp,
    this.stackTrace,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    final typeStr = type.name.toUpperCase();
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    return '[$timeStr] [$typeStr] ${source != null ? '[$source] ' : ''}$message';
  }
}

/// Monitor pentru consola de debug
class DebugConsoleMonitor {
  static final DebugConsoleMonitor _instance = DebugConsoleMonitor._internal();
  factory DebugConsoleMonitor() => _instance;
  DebugConsoleMonitor._internal();

  // Stocare mesaje
  final List<DebugMessage> _messages = [];
  final List<DebugMessage> _errors = [];
  final List<DebugMessage> _warnings = [];
  
  // Configurare
  static const int _maxMessages = 1000;
  static const int _maxErrors = 100;
  static const int _maxWarnings = 200;
  
  // Callbacks
  Function(DebugMessage)? onError;
  Function(DebugMessage)? onWarning;
  Function(DebugMessage)? onMessage;
  
  // Statistici
  int _errorCount = 0;
  int _warningCount = 0;
  DateTime? _lastErrorTime;
  DateTime? _lastWarningTime;
  
  // Pattern-uri pentru detectare probleme
  static final List<RegExp> _errorPatterns = [
    RegExp(r'❌|ERROR|Error|Exception|Failed|Crash|Fatal', caseSensitive: false),
    RegExp(r'\[ERROR\]|\[CRITICAL\]|\[FATAL\]', caseSensitive: false),
    RegExp(r'Exception:|Error:|Failed:|Crash:', caseSensitive: false),
  ];
  
  static final List<RegExp> _warningPatterns = [
    RegExp(r'⚠️|WARNING|Warning|Warn|Caution', caseSensitive: false),
    RegExp(r'\[WARNING\]|\[WARN\]|\[CAUTION\]', caseSensitive: false),
    RegExp(r'Warning:|Warn:|Caution:', caseSensitive: false),
  ];
  
  /// Initializează monitorul
  void initialize() {
    if (kDebugMode) {
      Logger.debug('Initializing debug console monitor', tag: 'DebugMonitor');
      Logger.debug('Debug console monitor initialized', tag: 'DebugMonitor');
    }
  }
  
  /// Analizează un mesaj de debug
  void analyzeMessage(String message, {String? source, StackTrace? stackTrace}) {
    if (!kDebugMode) return;
    
    // Detectează tipul mesajului
    DebugMessageType type = DebugMessageType.debug;
    
    // Verifică dacă este eroare
    final bool isError = _errorPatterns.any((pattern) => pattern.hasMatch(message));
    if (isError) {
      type = DebugMessageType.error;
      _errorCount++;
      _lastErrorTime = DateTime.now();
    } else {
      // Verifică dacă este warning
      final bool isWarning = _warningPatterns.any((pattern) => pattern.hasMatch(message));
      if (isWarning) {
        type = DebugMessageType.warning;
        _warningCount++;
        _lastWarningTime = DateTime.now();
      } else if (message.contains('✅') || message.contains('SUCCESS')) {
        type = DebugMessageType.success;
      } else if (message.contains('📋') || message.contains('INFO')) {
        type = DebugMessageType.info;
      }
    }
    
    // Creează mesajul
    final debugMessage = DebugMessage(
      type: type,
      message: message,
      source: source,
      stackTrace: stackTrace,
    );
    
    // Adaugă la listă
    _addMessage(debugMessage);
    
    // Trigger callbacks
    if (type == DebugMessageType.error) {
      onError?.call(debugMessage);
    } else if (type == DebugMessageType.warning) {
      onWarning?.call(debugMessage);
    }
    onMessage?.call(debugMessage);
  }
  
  /// Adaugă mesaj la listă
  void _addMessage(DebugMessage message) {
    _messages.add(message);
    
    // Limitează numărul de mesaje
    if (_messages.length > _maxMessages) {
      _messages.removeAt(0);
    }
    
    // Adaugă la liste specifice
    if (message.type == DebugMessageType.error) {
      _errors.add(message);
      if (_errors.length > _maxErrors) {
        _errors.removeAt(0);
      }
    } else if (message.type == DebugMessageType.warning) {
      _warnings.add(message);
      if (_warnings.length > _maxWarnings) {
        _warnings.removeAt(0);
      }
    }
  }
  
  /// Obține toate mesajele
  List<DebugMessage> getMessages({DebugMessageType? type, int? limit}) {
    var messages = type != null 
        ? _messages.where((m) => m.type == type).toList()
        : List<DebugMessage>.from(_messages);
    
    if (limit != null && limit > 0) {
      messages = messages.length > limit 
          ? messages.sublist(messages.length - limit)
          : messages;
    }
    
    return messages;
  }
  
  /// Obține erorile
  List<DebugMessage> getErrors({int? limit}) {
    if (limit != null && limit > 0) {
      return _errors.length > limit 
          ? _errors.sublist(_errors.length - limit)
          : List<DebugMessage>.from(_errors);
    }
    return List<DebugMessage>.from(_errors);
  }
  
  /// Obține warning-urile
  List<DebugMessage> getWarnings({int? limit}) {
    if (limit != null && limit > 0) {
      return _warnings.length > limit 
          ? _warnings.sublist(_warnings.length - limit)
          : _warnings;
    }
    return List<DebugMessage>.from(_warnings);
  }
  
  /// Obține statistici
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final lastMinute = now.subtract(const Duration(minutes: 1));
    
    final recentErrors = _errors.where((e) => e.timestamp.isAfter(lastMinute)).length;
    final recentWarnings = _warnings.where((w) => w.timestamp.isAfter(lastMinute)).length;
    
    return {
      'total_messages': _messages.length,
      'total_errors': _errorCount,
      'total_warnings': _warningCount,
      'recent_errors_1min': recentErrors,
      'recent_warnings_1min': recentWarnings,
      'last_error_time': _lastErrorTime?.toIso8601String(),
      'last_warning_time': _lastWarningTime?.toIso8601String(),
      'errors_in_last_minute': recentErrors,
      'warnings_in_last_minute': recentWarnings,
    };
  }
  
  /// Verifică dacă există probleme critice
  bool hasCriticalIssues() {
    final stats = getStatistics();
    final recentErrors = stats['recent_errors_1min'] as int;
    
    // Consideră critic dacă sunt mai mult de 5 erori în ultimul minut
    return recentErrors > 5;
  }
  
  /// Obține raport de probleme
  Map<String, dynamic> getProblemReport() {
    final stats = getStatistics();
    final recentErrors = stats['recent_errors_1min'] as int;
    final recentWarnings = stats['recent_warnings_1min'] as int;
    
    final issues = <String>[];
    
    if (recentErrors > 0) {
      issues.add('$recentErrors erori în ultimul minut');
    }
    
    if (recentWarnings > 10) {
      issues.add('$recentWarnings warning-uri în ultimul minut (prea multe)');
    }
    
    if (hasCriticalIssues()) {
      issues.add('⚠️ PROBLEME CRITICE DETECTATE');
    }
    
    return {
      'has_issues': issues.isNotEmpty,
      'issues': issues,
      'statistics': stats,
      'recent_errors': getErrors(limit: 10).map((e) => e.toString()).toList(),
      'recent_warnings': getWarnings(limit: 10).map((w) => w.toString()).toList(),
    };
  }
  
  /// Șterge toate mesajele
  void clear() {
    _messages.clear();
    _errors.clear();
    _warnings.clear();
    _errorCount = 0;
    _warningCount = 0;
    _lastErrorTime = null;
    _lastWarningTime = null;
  }
  
  /// Șterge mesajele vechi (mai vechi de X minute)
  void clearOldMessages({int minutes = 60}) {
    final cutoff = DateTime.now().subtract(Duration(minutes: minutes));
    
    _messages.removeWhere((m) => m.timestamp.isBefore(cutoff));
    _errors.removeWhere((e) => e.timestamp.isBefore(cutoff));
    _warnings.removeWhere((w) => w.timestamp.isBefore(cutoff));
  }
}

