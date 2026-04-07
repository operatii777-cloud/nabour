/// 🔍 DEBUG LOGGER — [DebugConsoleMonitor] + [Logger] (doar în `kDebugMode`).
library;

import 'package:flutter/foundation.dart';
import 'package:nabour_app/services/debug_console_monitor.dart';
import 'package:nabour_app/utils/logger.dart';

String _tag(String? source) => source ?? 'DebugLog';

/// Wrapper cu monitorizare consolă + [Logger] (doar în debug).
void debugLog(String message, {String? source, StackTrace? stackTrace}) {
  if (kDebugMode) {
    DebugConsoleMonitor().analyzeMessage(message, source: source, stackTrace: stackTrace);
    Logger.debug(message, tag: _tag(source));
  }
}

void debugError(String message, {String? source, StackTrace? stackTrace}) {
  if (kDebugMode) {
    final errorMessage = '❌ [ERROR] $message';
    DebugConsoleMonitor().analyzeMessage(errorMessage, source: source, stackTrace: stackTrace);
    Logger.error(errorMessage, stackTrace: stackTrace, tag: _tag(source));
  }
}

void debugWarning(String message, {String? source}) {
  if (kDebugMode) {
    final warningMessage = '⚠️ [WARNING] $message';
    DebugConsoleMonitor().analyzeMessage(warningMessage, source: source);
    Logger.warning(warningMessage, tag: _tag(source));
  }
}

void debugInfo(String message, {String? source}) {
  if (kDebugMode) {
    final infoMessage = '📋 [INFO] $message';
    DebugConsoleMonitor().analyzeMessage(infoMessage, source: source);
    Logger.info(infoMessage, tag: _tag(source));
  }
}

void debugSuccess(String message, {String? source}) {
  if (kDebugMode) {
    final successMessage = '✅ [SUCCESS] $message';
    DebugConsoleMonitor().analyzeMessage(successMessage, source: source);
    Logger.info(successMessage, tag: _tag(source));
  }
}

