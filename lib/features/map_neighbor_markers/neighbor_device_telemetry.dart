import 'package:battery_plus/battery_plus.dart';

/// Citește bateria locală pentru telemetria hărții sociale (trimisă către vecini prin RTDB).
class NeighborDeviceTelemetryReader {
  NeighborDeviceTelemetryReader._();
  static final NeighborDeviceTelemetryReader instance =
      NeighborDeviceTelemetryReader._();

  final Battery _battery = Battery();

  /// `null` dacă platforma nu suportă sau citirea eșuează.
  Future<NeighborBatterySnapshot?> snapshot() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final charging = state == BatteryState.charging ||
          state == BatteryState.full;
      if (level < 0 || level > 100) return null;
      return NeighborBatterySnapshot(level: level, isCharging: charging);
    } catch (_) {
      return null;
    }
  }
}

class NeighborBatterySnapshot {
  final int level;
  final bool isCharging;

  const NeighborBatterySnapshot({
    required this.level,
    required this.isCharging,
  });
}
