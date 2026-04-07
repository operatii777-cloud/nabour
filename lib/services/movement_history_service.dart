import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nabour_app/models/movement_history_models.dart';
import 'package:nabour_app/services/movement_history_preferences_service.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MovementHistoryService {
  MovementHistoryService._();
  static final MovementHistoryService instance = MovementHistoryService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Compression thresholds
  static const double _minDistanceMeters = 35.0;
  static const Duration _minTimeDelta = Duration(seconds: 45);
  static const int _maxPathPerDay = 1200;
  static const int _defaultRetentionDays = 90;

  StreamSubscription<Position>? _positionSubscription;
  bool _recording = false;
  bool _persistBusy = false;
  MovementSample? _lastAcceptedSample;

  bool get isRecording => _recording;

  /// Pornește înregistrarea GPS în fundal (Android: serviciu foreground cu notificare).
  /// Returnează `false` dacă lipsește utilizatorul, preferința e off sau permisiunile sunt refuzate.
  Future<bool> startRecorder() async {
    if (kIsWeb) return false;
    if (_recording) return true;

    final user = _auth.currentUser;
    if (user == null) return false;

    final enabled = await MovementHistoryPreferencesService.instance.isEnabled();
    if (!enabled) return false;

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        Logger.warning(
          'MovementHistory: location permission denied',
          tag: 'MOVEMENT_HISTORY',
        );
        return false;
      }

      if (!kIsWeb && Platform.isAndroid) {
        final whenInUse = await Permission.locationWhenInUse.request();
        if (!whenInUse.isGranted) {
          Logger.warning(
            'MovementHistory: whenInUse not granted',
            tag: 'MOVEMENT_HISTORY',
          );
          return false;
        }
        final always = await Permission.locationAlways.request();
        if (!always.isGranted) {
          Logger.info(
            'MovementHistory: „Permite tot timpul” refuzat — înregistrarea poate fi limitată când aplicația e închisă.',
            tag: 'MOVEMENT_HISTORY',
          );
        }
      }

      final androidSettings = AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: _minDistanceMeters.round().clamp(20, 100),
        intervalDuration: _minTimeDelta,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Nabour — Istoric locație',
          notificationText:
              'Timeline / Week in Review: puncte salvate local pe telefon.',
          enableWakeLock: true,
        ),
      );
      final appleSettings = AppleSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: _minDistanceMeters.round().clamp(20, 100),
        activityType: ActivityType.otherNavigation,
        pauseLocationUpdatesAutomatically: true,
      );
      const fallback = LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 35,
      );

      late final LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = androidSettings;
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = appleSettings;
      } else {
        locationSettings = fallback;
      }

      await _positionSubscription?.cancel();
      _lastAcceptedSample = null;
      _positionSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        _onPosition,
        onError: (Object e, StackTrace st) {
          Logger.error(
            'MovementHistory stream: $e',
            error: e,
            stackTrace: st,
            tag: 'MOVEMENT_HISTORY',
          );
        },
      );
      _recording = true;
      Logger.info('MovementHistory recorder started', tag: 'MOVEMENT_HISTORY');
      return true;
    } catch (e, st) {
      Logger.error(
        'MovementHistory startRecorder: $e',
        error: e,
        stackTrace: st,
        tag: 'MOVEMENT_HISTORY',
      );
      return false;
    }
  }

  Future<void> _onPosition(Position position) async {
    if (!_recording || _persistBusy) return;
    final now = DateTime.now();
    final last = _lastAcceptedSample;
    if (last != null) {
      final d = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        position.latitude,
        position.longitude,
      );
      final dt = now.difference(last.timestamp);
      if (d < _minDistanceMeters && dt < _minTimeDelta) {
        return;
      }
    }

    _persistBusy = true;
    try {
      await recordSample(position: position, now: now);
      _lastAcceptedSample = MovementSample(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: now,
        accuracy: position.accuracy,
        speed: position.speed,
      );
    } catch (e) {
      Logger.warning('MovementHistory recordSample: $e', tag: 'MOVEMENT_HISTORY');
    } finally {
      _persistBusy = false;
    }
  }

  Future<void> stopRecorder() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _recording = false;
    _lastAcceptedSample = null;
    _persistBusy = false;
    Logger.info('MovementHistory recorder stopped', tag: 'MOVEMENT_HISTORY');
  }

  // Local-only helper for future manual ingestion (never writes to Firebase).
  Future<void> recordSample({
    required Position position,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final from = DateTime(ts.year, ts.month, ts.day);
    final to = DateTime(ts.year, ts.month, ts.day, 23, 59, 59);
    final existing = await loadRange(from: from, to: to, refreshFromFirebase: false);
    final all = existing.expand((e) => e.path).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    all.add(MovementSample(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: ts,
      accuracy: position.accuracy,
      speed: position.speed,
    ));
    final daily = _buildDailySummaries(all);
    await _saveLocalCacheForCurrentUser(daily);
  }

  Future<List<DailyMovementSummary>> loadRange({
    required DateTime from,
    required DateTime to,
    bool refreshFromFirebase = true,
    int retentionDays = _defaultRetentionDays,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return const <DailyMovementSummary>[];

    final local = await _loadLocalCacheForCurrentUser();
    if (refreshFromFirebase) {
      final remoteSamples = await _loadRemoteSamplesFromFirebase(from: from, to: to);
      if (remoteSamples.isNotEmpty) {
        final remoteDaily = _buildDailySummaries(remoteSamples);
        for (final entry in remoteDaily.entries) {
          local[entry.key] = entry.value;
        }
        _pruneByRetention(local, retentionDays);
        await _saveLocalCacheForCurrentUser(local);
      }
    }

    final min = _dayStart(from);
    final max = _dayStart(to);
    return local.values
        .where((d) {
          final day = _parseDayKey(d.dayKey);
          return !day.isBefore(min) && !day.isAfter(max);
        })
        .toList()
      ..sort((a, b) => a.dayKey.compareTo(b.dayKey));
  }

  Future<void> pruneLocalRetention({int retentionDays = _defaultRetentionDays}) async {
    final local = await _loadLocalCacheForCurrentUser();
    _pruneByRetention(local, retentionDays);
    await _saveLocalCacheForCurrentUser(local);
  }

  Future<void> clearLocalHistoryForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final file = await _cacheFile();
    if (!await file.exists()) return;

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return;
      final users = (decoded['users'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      users.remove(user.uid);
      decoded['users'] = users;
      await file.writeAsString(jsonEncode(decoded), flush: true);
    } catch (_) {}
  }

  Future<List<MovementSample>> _loadRemoteSamplesFromFirebase({
    required DateTime from,
    required DateTime to,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return const <MovementSample>[];

    final out = <MovementSample>[];
    try {
      final docs = await _firestore
          .collection('live_locations')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(to))
          .orderBy('timestamp', descending: false)
          .get();

      for (final doc in docs.docs) {
        final data = doc.data();
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        final ts = data['timestamp'];
        if (lat == null || lng == null || ts is! Timestamp) continue;
        out.add(MovementSample(
          latitude: lat,
          longitude: lng,
          timestamp: ts.toDate(),
          accuracy: (data['accuracy'] as num?)?.toDouble(),
          speed: (data['speed'] as num?)?.toDouble(),
        ));
      }
    } catch (_) {
      // Fallback for missing index/schema drift.
      try {
        final docs = await _firestore
            .collection('live_locations')
            .where('userId', isEqualTo: user.uid)
            .limit(5000)
            .get();
        for (final doc in docs.docs) {
          final data = doc.data();
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          final ts = data['timestamp'];
          if (lat == null || lng == null || ts is! Timestamp) continue;
          final dt = ts.toDate();
          if (dt.isBefore(from) || dt.isAfter(to)) continue;
          out.add(MovementSample(
            latitude: lat,
            longitude: lng,
            timestamp: dt,
            accuracy: (data['accuracy'] as num?)?.toDouble(),
            speed: (data['speed'] as num?)?.toDouble(),
          ));
        }
      } catch (_) {}
    }

    out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return _compressSamples(out);
  }

  Map<String, DailyMovementSummary> _buildDailySummaries(List<MovementSample> samples) {
    final grouped = <String, List<MovementSample>>{};
    for (final s in samples) {
      final key = _dayKey(s.timestamp);
      final list = grouped[key] ?? <MovementSample>[];
      list.add(s);
      grouped[key] = list;
    }

    final result = <String, DailyMovementSummary>{};
    for (final entry in grouped.entries) {
      final list = entry.value..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final path = list.take(_maxPathPerDay).toList(growable: false);
      final pathMap = path.map((e) => e.toMap()).toList(growable: false);
      result[entry.key] = DailyMovementSummary(
        dayKey: entry.key,
        path: path,
        hotspots: _buildHotspots(pathMap),
        rawSamples: list.length,
        distanceMeters: _estimateDistance(pathMap),
        updatedAt: DateTime.now(),
      );
    }
    return result;
  }

  List<MovementSample> _compressSamples(List<MovementSample> input) {
    if (input.length <= 2) return input;
    final out = <MovementSample>[input.first];
    var last = input.first;
    for (var i = 1; i < input.length; i++) {
      final cur = input[i];
      final d = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        cur.latitude,
        cur.longitude,
      );
      final dt = cur.timestamp.difference(last.timestamp);
      if (d >= _minDistanceMeters || dt >= _minTimeDelta || i == input.length - 1) {
        out.add(cur);
        last = cur;
      }
    }
    return out;
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/movement_history_cache_v1.json');
  }

  Future<Map<String, DailyMovementSummary>> _loadLocalCacheForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return <String, DailyMovementSummary>{};
    final file = await _cacheFile();
    if (!await file.exists()) return <String, DailyMovementSummary>{};

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return <String, DailyMovementSummary>{};
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, DailyMovementSummary>{};

      final allUsers = (decoded['users'] as Map<String, dynamic>? ?? <String, dynamic>{});
      final userBlock = (allUsers[user.uid] as Map<String, dynamic>? ?? <String, dynamic>{});
      final days = (userBlock['days'] as Map<String, dynamic>? ?? <String, dynamic>{});

      final out = <String, DailyMovementSummary>{};
      for (final entry in days.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          out[entry.key] = DailyMovementSummary.fromMap(entry.key, value);
        } else if (value is Map) {
          out[entry.key] = DailyMovementSummary.fromMap(
            entry.key,
            value.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }
      return out;
    } catch (_) {
      return <String, DailyMovementSummary>{};
    }
  }

  Future<void> _saveLocalCacheForCurrentUser(Map<String, DailyMovementSummary> days) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final file = await _cacheFile();

    Map<String, dynamic> root = <String, dynamic>{'users': <String, dynamic>{}};
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) root = decoded;
      }
    } catch (_) {}

    final usersMap = (root['users'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    usersMap[user.uid] = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
      'days': {
        for (final e in days.entries)
          e.key: <String, dynamic>{
            'path': e.value.path.map((p) => p.toMap()).toList(),
            'hotspots': e.value.hotspots.map((h) => h.toMap()).toList(),
            'rawSamples': e.value.rawSamples,
            'distanceMeters': e.value.distanceMeters,
            'updatedAt': e.value.updatedAt.toIso8601String(),
          },
      },
    };
    root['users'] = usersMap;
    await file.writeAsString(jsonEncode(root), flush: true);
  }

  String _dayKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  DateTime _dayStart(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _parseDayKey(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? 1970,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  void _pruneByRetention(Map<String, DailyMovementSummary> local, int retentionDays) {
    if (retentionDays <= 0) return;
    final cutoff = _dayStart(DateTime.now().subtract(Duration(days: retentionDays)));
    final toRemove = <String>[];
    for (final entry in local.entries) {
      final day = _parseDayKey(entry.key);
      if (day.isBefore(cutoff)) toRemove.add(entry.key);
    }
    for (final key in toRemove) {
      local.remove(key);
    }
  }

  List<MovementHotspot> _buildHotspots(List<Map<String, dynamic>> pathRaw) {
    if (pathRaw.isEmpty) return const <MovementHotspot>[];
    final Map<String, _HotspotBucket> buckets = <String, _HotspotBucket>{};

    for (final map in pathRaw) {
      final lat = (map['lat'] as num).toDouble();
      final lng = (map['lng'] as num).toDouble();
      final key = _gridKey(lat, lng, 4);
      final bucket = buckets[key] ?? _HotspotBucket();
      bucket.add(lat, lng);
      buckets[key] = bucket;
    }

    final hotspots = buckets.values
        .where((b) => b.count >= 3)
        .map((b) => MovementHotspot(
              latitude: b.avgLat,
              longitude: b.avgLng,
              weight: b.count,
            ))
        .toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));

    return hotspots.take(24).toList();
  }

  String _gridKey(double lat, double lng, int decimals) {
    final factor = math.pow(10, decimals).toDouble();
    final latQ = (lat * factor).round() / factor;
    final lngQ = (lng * factor).round() / factor;
    return '$latQ:$lngQ';
  }

  double _estimateDistance(List<Map<String, dynamic>> pathRaw) {
    if (pathRaw.length < 2) return 0;
    double total = 0;
    for (var i = 1; i < pathRaw.length; i++) {
      final a = pathRaw[i - 1];
      final b = pathRaw[i];
      total += Geolocator.distanceBetween(
        (a['lat'] as num).toDouble(),
        (a['lng'] as num).toDouble(),
        (b['lat'] as num).toDouble(),
        (b['lng'] as num).toDouble(),
      );
    }
    return total;
  }
}

class _HotspotBucket {
  int count = 0;
  double _latSum = 0;
  double _lngSum = 0;

  void add(double lat, double lng) {
    count += 1;
    _latSum += lat;
    _lngSum += lng;
  }

  double get avgLat => count == 0 ? 0 : _latSum / count;
  double get avgLng => count == 0 ? 0 : _lngSum / count;
}
