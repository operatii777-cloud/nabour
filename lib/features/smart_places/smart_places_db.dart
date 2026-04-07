import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:nabour_app/utils/logger.dart';

/// On-device learned-places engine backed by sqflite.
///
/// Records GPS samples periodically and clusters them into "learned places"
/// when enough dwell-time accumulates in the same area.
class SmartPlacesDb {
  SmartPlacesDb._();
  static final SmartPlacesDb instance = SmartPlacesDb._();

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'nabour_smart_places.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE gps_samples (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL NOT NULL,
            lng REAL NOT NULL,
            ts INTEGER NOT NULL,
            speed REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE learned_places (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL NOT NULL,
            lng REAL NOT NULL,
            label TEXT,
            kind TEXT,
            total_dwell_min INTEGER DEFAULT 0,
            visit_count INTEGER DEFAULT 0,
            first_seen INTEGER NOT NULL,
            last_seen INTEGER NOT NULL,
            confidence REAL DEFAULT 0.0
          )
        ''');
      },
    );
    return _db!;
  }

  /// Record a GPS sample (call from publish helper; very cheap).
  Future<void> recordSample(double lat, double lng, {double? speed}) async {
    try {
      final db = await _open();
      await db.insert('gps_samples', {
        'lat': lat,
        'lng': lng,
        'ts': DateTime.now().millisecondsSinceEpoch,
        'speed': speed,
      });
    } catch (e) {
      Logger.warning('SmartPlaces: failed to record sample: $e', tag: 'PLACES');
    }
  }

  /// Cluster recent stationary samples into learned places.
  /// Should be called periodically (e.g. every 5 min, in background timer).
  Future<void> runClustering({double radiusM = 80, int minDwellMin = 25}) async {
    try {
      final db = await _open();
      final cutoff =
          DateTime.now().subtract(const Duration(days: 14)).millisecondsSinceEpoch;

      // Only stationary samples (speed < 1.2 m/s)
      final rows = await db.query(
        'gps_samples',
        where: 'ts > ? AND (speed IS NULL OR speed < 1.2)',
        whereArgs: [cutoff],
        orderBy: 'ts ASC',
      );

      if (rows.isEmpty) return;

      final clusters = <_Cluster>[];

      for (final row in rows) {
        final lat = row['lat'] as double;
        final lng = row['lng'] as double;
        final ts = row['ts'] as int;

        _Cluster? match;
        double bestDist = radiusM + 1;
        for (final c in clusters) {
          final d = Geolocator.distanceBetween(lat, lng, c.lat, c.lng);
          if (d <= radiusM && d < bestDist) {
            match = c;
            bestDist = d;
          }
        }
        if (match != null) {
          match.addSample(lat, lng, ts);
        } else {
          clusters.add(_Cluster(lat, lng, ts));
        }
      }

      // Persist clusters that meet minimum dwell time
      for (final c in clusters) {
        if (c.dwellMinutes < minDwellMin) continue;
        final existing = await db.query(
          'learned_places',
          where:
              'lat BETWEEN ? AND ? AND lng BETWEEN ? AND ?',
          whereArgs: [
            c.lat - 0.001,
            c.lat + 0.001,
            c.lng - 0.001,
            c.lng + 0.001,
          ],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final id = existing.first['id'] as int;
          await db.update(
            'learned_places',
            {
              'total_dwell_min': c.dwellMinutes,
              'visit_count': c.visitCount,
              'last_seen': c.lastTs,
              'confidence':
                  (c.dwellMinutes / 60.0).clamp(0.0, 1.0),
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        } else {
          await db.insert('learned_places', {
            'lat': c.lat,
            'lng': c.lng,
            'total_dwell_min': c.dwellMinutes,
            'visit_count': c.visitCount,
            'first_seen': c.firstTs,
            'last_seen': c.lastTs,
            'confidence':
                (c.dwellMinutes / 60.0).clamp(0.0, 1.0),
          });
        }
      }

      // Cleanup old samples
      await db.delete('gps_samples', where: 'ts < ?', whereArgs: [cutoff]);
    } catch (e) {
      Logger.warning('SmartPlaces: clustering failed: $e', tag: 'PLACES');
    }
  }

  /// All learned places with confidence above threshold, ordered by dwell time.
  Future<List<LearnedPlace>> getLearnedPlaces({double minConfidence = 0.3}) async {
    try {
      final db = await _open();
      final rows = await db.query(
        'learned_places',
        where: 'confidence >= ?',
        whereArgs: [minConfidence],
        orderBy: 'total_dwell_min DESC',
      );
      return rows.map(LearnedPlace.fromRow).toList();
    } catch (e) {
      Logger.warning('SmartPlaces: getLearnedPlaces failed: $e', tag: 'PLACES');
      return [];
    }
  }

  /// Detect current place kind from learned places.
  Future<String?> detectCurrentPlaceKind(double lat, double lng,
      {double radiusM = 100}) async {
    final places = await getLearnedPlaces();
    LearnedPlace? best;
    double bestDist = radiusM + 1;
    for (final p in places) {
      final d = Geolocator.distanceBetween(lat, lng, p.lat, p.lng);
      if (d <= radiusM && d < bestDist) {
        best = p;
        bestDist = d;
      }
    }
    if (best == null) return null;
    if (best.kind != null) return best.kind;
    if (best.dwellMinutes >= 300) return 'frequent';
    return 'visited';
  }

  /// Label a learned place with a human-readable kind/name.
  Future<void> labelPlace(int placeId, String kind, {String? label}) async {
    try {
      final db = await _open();
      await db.update(
        'learned_places',
        {
          'kind': kind,
          if (label != null) 'label': label,
        },
        where: 'id = ?',
        whereArgs: [placeId],
      );
    } catch (_) {}
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

class _Cluster {
  double lat;
  double lng;
  int firstTs;
  int lastTs;
  int sampleCount = 1;
  double _sumLat;
  double _sumLng;

  _Cluster(this.lat, this.lng, this.firstTs)
      : lastTs = firstTs,
        _sumLat = lat,
        _sumLng = lng;

  void addSample(double sLat, double sLng, int ts) {
    sampleCount++;
    _sumLat += sLat;
    _sumLng += sLng;
    lat = _sumLat / sampleCount;
    lng = _sumLng / sampleCount;
    if (ts < firstTs) firstTs = ts;
    if (ts > lastTs) lastTs = ts;
  }

  int get dwellMinutes => ((lastTs - firstTs) / 60000).round();
  int get visitCount => sampleCount;
}

class LearnedPlace {
  final int id;
  final double lat;
  final double lng;
  final String? label;
  final String? kind;
  final int dwellMinutes;
  final int visitCount;
  final double confidence;
  final DateTime firstSeen;
  final DateTime lastSeen;

  const LearnedPlace({
    required this.id,
    required this.lat,
    required this.lng,
    this.label,
    this.kind,
    required this.dwellMinutes,
    required this.visitCount,
    required this.confidence,
    required this.firstSeen,
    required this.lastSeen,
  });

  factory LearnedPlace.fromRow(Map<String, Object?> row) {
    return LearnedPlace(
      id: row['id'] as int,
      lat: row['lat'] as double,
      lng: row['lng'] as double,
      label: row['label'] as String?,
      kind: row['kind'] as String?,
      dwellMinutes: (row['total_dwell_min'] as int?) ?? 0,
      visitCount: (row['visit_count'] as int?) ?? 0,
      confidence: (row['confidence'] as num?)?.toDouble() ?? 0,
      firstSeen: DateTime.fromMillisecondsSinceEpoch(
          (row['first_seen'] as int?) ?? 0),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(
          (row['last_seen'] as int?) ?? 0),
    );
  }
}
