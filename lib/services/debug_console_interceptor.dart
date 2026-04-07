/// 🔍 DEBUG CONSOLE INTERCEPTOR
/// 
/// Acest serviciu interceptează toate mesajele de debug și le salvează
/// într-un fișier pentru analiză ulterioară.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nabour_app/services/debug_console_monitor.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Interceptor pentru consola de debug
class DebugConsoleInterceptor {
  static final DebugConsoleInterceptor _instance = DebugConsoleInterceptor._internal();
  factory DebugConsoleInterceptor() => _instance;
  DebugConsoleInterceptor._internal();

  final DebugConsoleMonitor _monitor = DebugConsoleMonitor();
  File? _logFile;
  bool _isInitialized = false;
  Timer? _flushTimer;
  
  // Buffer pentru mesaje (scriem la fișier periodic)
  final List<String> _messageBuffer = [];
  static const int _bufferSize = 50;
  
  /// Initializează interceptorul
  Future<void> initialize() async {
    if (!kDebugMode || _isInitialized) return;
    
    try {
      // Creează directorul pentru log-uri
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/debug_logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      // Creează fișierul de log cu timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      _logFile = File('${logDir.path}/debug_$timestamp.log');
      
      // Scrie header
      await _logFile!.writeAsString(
        '=== DEBUG CONSOLE LOG - ${DateTime.now()} ===\n\n',
        mode: FileMode.append,
      );
      
      // Setup periodic flush
      _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) => _flushBuffer());
      
      _isInitialized = true;
      Logger.info(
        'Debug interceptor initialized: ${_logFile!.path}',
        tag: 'DebugInterceptor',
      );
    } catch (e) {
      Logger.warning('Debug interceptor init failed: $e', tag: 'DebugInterceptor');
    }
  }
  
  /// Interceptează un mesaj
  void intercept(String message, {String? source, StackTrace? stackTrace}) {
    if (!kDebugMode || !_isInitialized) return;
    
    // Analizează mesajul
    _monitor.analyzeMessage(message, source: source, stackTrace: stackTrace);
    
    // Adaugă la buffer
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] ${source != null ? '[$source] ' : ''}$message${stackTrace != null ? '\n$stackTrace' : ''}\n';
    _messageBuffer.add(logEntry);
    
    // Flush dacă buffer-ul este plin
    if (_messageBuffer.length >= _bufferSize) {
      _flushBuffer();
    }
  }
  
  /// Scrie buffer-ul în fișier
  Future<void> _flushBuffer() async {
    if (_messageBuffer.isEmpty || _logFile == null) return;
    
    try {
      final content = _messageBuffer.join();
      await _logFile!.writeAsString(content, mode: FileMode.append);
      _messageBuffer.clear();
    } catch (e) {
      Logger.warning('Debug interceptor flush failed: $e', tag: 'DebugInterceptor');
    }
  }
  
  /// Obține calea fișierului de log
  String? getLogFilePath() => _logFile?.path;
  
  /// Obține conținutul fișierului de log
  Future<String?> getLogContent({int? lastLines}) async {
    if (_logFile == null || !await _logFile!.exists()) return null;
    
    try {
      final content = await _logFile!.readAsString();
      if (lastLines != null && lastLines > 0) {
        final lines = content.split('\n');
        return lines.length > lastLines 
            ? lines.sublist(lines.length - lastLines).join('\n')
            : content;
      }
      return content;
    } catch (e) {
      Logger.warning('Debug interceptor read log failed: $e', tag: 'DebugInterceptor');
      return null;
    }
  }
  
  /// Obține raport de erori
  Future<Map<String, dynamic>> getErrorReport() async {
    final monitor = DebugConsoleMonitor();
    final stats = monitor.getStatistics();
    final errors = monitor.getErrors(limit: 20);
    final warnings = monitor.getWarnings(limit: 20);
    
    final logContent = await getLogContent(lastLines: 100);
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'statistics': stats,
      'recent_errors': errors.map((e) => {
        'message': e.message,
        'source': e.source,
        'timestamp': e.timestamp.toIso8601String(),
      }).toList(),
      'recent_warnings': warnings.map((w) => {
        'message': w.message,
        'source': w.source,
        'timestamp': w.timestamp.toIso8601String(),
      }).toList(),
      'log_file_path': getLogFilePath(),
      'last_100_log_lines': logContent,
      'has_critical_issues': monitor.hasCriticalIssues(),
    };
  }
  
  /// Șterge fișierul de log
  Future<void> clearLog() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.delete();
      _messageBuffer.clear();
    }
  }
  
  /// Dispose
  void dispose() {
    _flushTimer?.cancel();
    _flushBuffer();
  }
}

