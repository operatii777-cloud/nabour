import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:nabour_app/utils/logger.dart';

/// BLE-based proximity bump — broadcasts a tiny payload with the user's UID
/// and scans for nearby friends doing the same.
///
/// Uses platform channels because adding a full BLE package would pull in
/// heavy native code.  The Dart side only needs start / stop / stream.
///
/// Falls back gracefully: if the platform channel is not implemented
/// (e.g. iOS simulator, old Android) the service simply stays silent.
class BleBumpService {
  BleBumpService._();
  static final BleBumpService instance = BleBumpService._();

  static const _channel = MethodChannel('com.nabour/ble_bump');
  static const _eventChannel = EventChannel('com.nabour/ble_bump_events');

  StreamSubscription<dynamic>? _sub;
  final _controller = StreamController<BleBumpEvent>.broadcast();
  bool _running = false;

  /// Peers discovered nearby.
  Stream<BleBumpEvent> get discoveries => _controller.stream;
  bool get isRunning => _running;

  /// Begins advertising our UID and scanning for friends.
  Future<void> start() async {
    if (_running) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _channel.invokeMethod('start', {
        'serviceUuid': _serviceUuid,
        'payload': utf8.encode(uid.substring(0, math.min(uid.length, 20))),
      });
      _sub = _eventChannel.receiveBroadcastStream().listen(
        (raw) {
          if (raw is Map) {
            final peerUid = raw['uid'] as String?;
            final rssi = (raw['rssi'] as num?)?.toInt() ?? -100;
            if (peerUid != null && peerUid.isNotEmpty) {
              _controller.add(BleBumpEvent(peerUid: peerUid, rssi: rssi));
            }
          }
        },
        onError: (e) =>
            Logger.warning('BLE bump event error: $e', tag: 'BLE_BUMP'),
      );
      _running = true;
      Logger.info('BLE bump started', tag: 'BLE_BUMP');
    } on MissingPluginException {
      Logger.warning(
        'BLE bump platform channel not available — falling back to GPS only',
        tag: 'BLE_BUMP',
      );
    } catch (e) {
      Logger.warning('BLE bump start failed: $e', tag: 'BLE_BUMP');
    }
  }

  Future<void> stop() async {
    if (!_running) return;
    _sub?.cancel();
    _sub = null;
    _running = false;
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
    Logger.info('BLE bump stopped', tag: 'BLE_BUMP');
  }

  void dispose() {
    stop();
    _controller.close();
  }

  static const _serviceUuid = '6E61626F-7572-4275-6D70-000000000001';
}

class BleBumpEvent {
  final String peerUid;
  final int rssi;

  const BleBumpEvent({required this.peerUid, required this.rssi});

  /// Rough distance estimate from RSSI (very approximate).
  double get estimatedMeters {
    const txPower = -59;
    final ratio = (txPower - rssi) / (10.0 * 2.0);
    return math.pow(10.0, ratio).toDouble();
  }
}
