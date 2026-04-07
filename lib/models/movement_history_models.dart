class MovementSample {
  const MovementSample({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? speed;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lat': latitude,
      'lng': longitude,
      'ts': timestamp.millisecondsSinceEpoch,
      if (accuracy != null) 'acc': accuracy,
      if (speed != null) 'speed': speed,
    };
  }

  factory MovementSample.fromMap(Map<String, dynamic> map) {
    final ts = map['ts'];
    DateTime date;
    if (ts is int) {
      date = DateTime.fromMillisecondsSinceEpoch(ts);
    } else if (ts is String) {
      date = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return MovementSample(
      latitude: (map['lat'] as num).toDouble(),
      longitude: (map['lng'] as num).toDouble(),
      timestamp: date,
      accuracy: map['acc'] == null ? null : (map['acc'] as num).toDouble(),
      speed: map['speed'] == null ? null : (map['speed'] as num).toDouble(),
    );
  }
}

class MovementHotspot {
  const MovementHotspot({
    required this.latitude,
    required this.longitude,
    required this.weight,
  });

  final double latitude;
  final double longitude;
  final int weight;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lat': latitude,
      'lng': longitude,
      'w': weight,
    };
  }

  factory MovementHotspot.fromMap(Map<String, dynamic> map) {
    return MovementHotspot(
      latitude: (map['lat'] as num).toDouble(),
      longitude: (map['lng'] as num).toDouble(),
      weight: (map['w'] as num?)?.toInt() ?? 1,
    );
  }
}

class DailyMovementSummary {
  const DailyMovementSummary({
    required this.dayKey,
    required this.path,
    required this.hotspots,
    required this.rawSamples,
    required this.distanceMeters,
    required this.updatedAt,
  });

  final String dayKey;
  final List<MovementSample> path;
  final List<MovementHotspot> hotspots;
  final int rawSamples;
  final double distanceMeters;
  final DateTime updatedAt;

  factory DailyMovementSummary.fromMap(String dayKey, Map<String, dynamic> map) {
    final pathRaw = (map['path'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(MovementSample.fromMap)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final hotspotsRaw = (map['hotspots'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(MovementHotspot.fromMap)
        .toList();

    final ts = map['updatedAt'];
    final updated = ts is String ? (DateTime.tryParse(ts) ?? DateTime.now()) : DateTime.now();

    return DailyMovementSummary(
      dayKey: dayKey,
      path: pathRaw,
      hotspots: hotspotsRaw,
      rawSamples: (map['rawSamples'] as num?)?.toInt() ?? pathRaw.length,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0,
      updatedAt: updated,
    );
  }
}
