import 'dart:async';

import 'voice_analytics.dart';
import 'package:nabour_app/utils/logger.dart';

class VoiceAnalyticsBridgeSnapshot {
  const VoiceAnalyticsBridgeSnapshot({
    required this.totalEvents,
    required this.totalMetrics,
    required this.totalErrors,
    this.lastEventAt,
  });

  final int totalEvents;
  final int totalMetrics;
  final int totalErrors;
  final DateTime? lastEventAt;

  Map<String, dynamic> toMap() => {
        'totalEvents': totalEvents,
        'totalMetrics': totalMetrics,
        'totalErrors': totalErrors,
        'lastEventAt': lastEventAt?.toIso8601String(),
      };
}

class VoiceAnalyticsBridge {
  VoiceAnalyticsBridge({
    required VoiceAnalytics analytics,
    Future<void> Function(String key, Object? value)? crashlyticsKeySetter,
    void Function(String category, Map<String, dynamic> data)? breadcrumbRecorder,
  })  : _analytics = analytics,
        _setCustomKey = crashlyticsKeySetter,
        _recordBreadcrumb = breadcrumbRecorder;

  final VoiceAnalytics _analytics;
  final Future<void> Function(String key, Object? value)? _setCustomKey;
  final void Function(String category, Map<String, dynamic> data)? _recordBreadcrumb;

  StreamSubscription<VoiceEvent>? _eventSubscription;
  StreamSubscription<PerformanceMetric>? _metricSubscription;

  int _forwardedEvents = 0;
  int _forwardedMetrics = 0;
  int _forwardedErrors = 0;
  DateTime? _lastEventAt;

  bool _started = false;

  VoiceAnalyticsBridgeSnapshot get snapshot => VoiceAnalyticsBridgeSnapshot(
        totalEvents: _forwardedEvents,
        totalMetrics: _forwardedMetrics,
        totalErrors: _forwardedErrors,
        lastEventAt: _lastEventAt,
      );

  void start() {
    if (_started) return;
    _started = true;

    _eventSubscription = _analytics.events.listen(_handleEvent, onError: _handleStreamError);
    _metricSubscription = _analytics.performanceMetrics.listen(_handleMetric, onError: _handleStreamError);
  }

  void dispose() {
    _eventSubscription?.cancel();
    _metricSubscription?.cancel();
    _eventSubscription = null;
    _metricSubscription = null;
    _started = false;
  }

  void recordCrash(String type) {
    _forwardedErrors++;
    _recordBreadcrumb?.call('voice.crash', {
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _handleEvent(VoiceEvent event) {
    _forwardedEvents++;
    _lastEventAt = event.timestamp;

    final errorMessage = event.errorMessage ?? event.data['error_message']?.toString();

    if (event.type == VoiceEventType.error) {
      _forwardedErrors++;
      if (_setCustomKey != null && errorMessage != null) {
        unawaited(_setCustomKey!.call('voice_last_error', errorMessage));
      }
    }

    if (_setCustomKey != null) {
      unawaited(_setCustomKey!.call('voice_last_event', event.type.name));
    }

    _recordBreadcrumb?.call(
      'voice.event.${event.type.name}',
      _sanitize({
        'userId': event.userId,
        'sessionId': event.sessionId,
        'data': event.data.isNotEmpty ? _sanitize(event.data) : null,
        'errorMessage': errorMessage,
        'errorType': event.errorType ?? event.data['error_type']?.toString(),
        'timestamp': event.timestamp.toIso8601String(),
      }),
    );
  }

  void _handleMetric(PerformanceMetric metric) {
    _forwardedMetrics++;
    _lastEventAt = metric.timestamp;

    if (_setCustomKey != null) {
      unawaited(_setCustomKey!.call('voice_metric_${metric.name}', metric.value));
    }

    _recordBreadcrumb?.call(
      'voice.metric.${metric.name}',
      _sanitize({
        'value': metric.value,
        'unit': metric.unit,
        'userId': metric.userId,
        'metadata': metric.metadata.isNotEmpty ? _sanitize(metric.metadata) : null,
        'timestamp': metric.timestamp.toIso8601String(),
      }),
    );
  }

  void _handleStreamError(Object error) {
    Logger.error('[VoiceAnalyticsBridge] Stream error: $error', error: error);
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> source) {
    final result = <String, dynamic>{};
    source.forEach((key, value) {
      if (value == null) return;
      if (result.length >= 8) return; // prevent oversized payloads
      if (value is String) {
        result[key] = value.length > 256 ? '${value.substring(0, 253)}...' : value;
      } else if (value is num || value is bool) {
        result[key] = value;
      } else if (value is Map) {
        final mapped = <String, dynamic>{};
        value.forEach((k, v) => mapped[k.toString()] = v);
        result[key] = _sanitize(mapped);
      } else if (value is Iterable) {
        result[key] = value.take(5).map((item) => item.toString()).toList();
      } else {
        result[key] = value.toString();
      }
    });
    return result;
  }
}

