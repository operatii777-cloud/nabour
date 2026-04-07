import 'dart:async';

import 'package:nabour_app/features/ble_bump/ble_bump_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Connects [BleBumpService] discoveries to the neighbor map layer so that
/// a bump can be triggered even when GPS alone wouldn't detect proximity.
class BleBumpBridge {
  BleBumpBridge._();
  static final BleBumpBridge instance = BleBumpBridge._();

  StreamSubscription<BleBumpEvent>? _sub;
  final _bumpedPeers = <String, DateTime>{};
  static const _cooldown = Duration(minutes: 10);

  /// Threshold RSSI — peers with signal stronger than this are "bump-close".
  static const int rssiThreshold = -65;

  void Function(String peerUid)? onBump;

  void start() {
    _sub?.cancel();
    _sub = BleBumpService.instance.discoveries.listen(_handle);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _bumpedPeers.clear();
  }

  void _handle(BleBumpEvent e) {
    if (e.rssi > rssiThreshold) {
      final last = _bumpedPeers[e.peerUid];
      if (last != null && DateTime.now().difference(last) < _cooldown) return;
      _bumpedPeers[e.peerUid] = DateTime.now();
      Logger.info(
        'BLE BUMP DETECTED: ${e.peerUid} RSSI=${e.rssi} ~${e.estimatedMeters.toStringAsFixed(1)}m',
        tag: 'BLE_BUMP',
      );
      onBump?.call(e.peerUid);
    }
  }

  /// Cleanup old entries.
  void purge() {
    final cutoff = DateTime.now().subtract(_cooldown);
    _bumpedPeers.removeWhere((_, t) => t.isBefore(cutoff));
  }
}
