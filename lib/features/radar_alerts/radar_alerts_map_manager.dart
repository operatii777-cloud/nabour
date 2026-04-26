import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nabour_app/models/radar_alert_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/utils/logger.dart';

class RadarAlertsMapManager {
  final BuildContext context;
  final VoidCallback onDataChanged;

  StreamSubscription? _subscription;
  List<RadarAlert> _alerts = [];
  bool _initialized = false;

  RadarAlertsMapManager({
    required this.context,
    required this.onDataChanged,
  });

  List<RadarAlert> get alerts => _alerts;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    Logger.info('Initializing RadarAlertsMapManager', tag: 'RADAR');

    _subscription = FirestoreService().getRecentRadarAlerts().listen(
      (data) {
        _alerts = data;
        onDataChanged();
      },
      onError: (e) {
        Logger.error('RadarAlerts subscription error: $e', tag: 'RADAR');
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
