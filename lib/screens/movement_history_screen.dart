import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nabour_app/models/movement_history_models.dart';
import 'package:nabour_app/services/movement_history_service.dart';
import 'package:nabour_app/utils/deprecated_apis_fix.dart';
import 'package:nabour_app/widgets/movement_recap_globe_overlay.dart';
import 'package:nabour_app/services/movement_recap_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovementHistoryScreen extends StatefulWidget {
  const MovementHistoryScreen({super.key});

  @override
  State<MovementHistoryScreen> createState() => _MovementHistoryScreenState();
}

class _MovementHistoryScreenState extends State<MovementHistoryScreen> {
  final GlobalKey _captureBoundaryKey = GlobalKey();
  final MapController _mapController = MapController();
  final MovementHistoryService _service = MovementHistoryService.instance;
  final MovementRecapAudioController _recapAudio = MovementRecapAudioController();

  final List<MovementSample> _samples = <MovementSample>[];
  final List<MovementHotspot> _hotspots = <MovementHotspot>[];

  Timer? _playbackTimer;

  bool _isLoading = true;
  bool _isPlaying = false;
  bool _cinematicRunning = false;
  bool _isExporting = false;
  double _globeOpacity = 0;
  bool _globeOverlayVisible = false;
  double _hotspotRouteProgress = 0;
  int _cinematicGen = 0;

  static const LatLng _worldRecapCenter = LatLng(26, 22);
  static const double _zoomWorld = 1.55;
  static const double _zoomCity = 15.25;
  static const double _tSpaceEnd = 0.14;
  static const double _tZoomInEnd = 0.38;
  static const double _tRouteEnd = 0.78;
  double _speed = 1.0;
  double _progress = 0;
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );
  int _retentionDays = 90;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]),
    );
    unawaited(_recapAudio.prepare());
    _loadData();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _cinematicGen++;
    unawaited(_recapAudio.dispose());
    unawaited(
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    );
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _retentionDays = prefs.getInt('movement_history_retention_days') ?? 90;
    await _service.pruneLocalRetention(retentionDays: _retentionDays);
    final summaries = await _service.loadRange(
      from: _range.start,
      to: _range.end,
      retentionDays: _retentionDays,
    );

    final samples = summaries.expand((e) => e.path).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final hotspots = summaries.expand((e) => e.hotspots).toList();

    if (!mounted) return;
    setState(() {
      _samples
        ..clear()
        ..addAll(samples);
      _hotspots
        ..clear()
        ..addAll(hotspots);
      _progress = 0;
      _isPlaying = false;
      _isLoading = false;
    });

    unawaited(_runCinematicRecap());
  }

  LatLng get _cinematicTargetLatLng {
    if (_samples.isEmpty) return const LatLng(44.4268, 26.1025);
    return LatLng(_samples.last.latitude, _samples.last.longitude);
  }

  /// Hotspot-uri ordonate după prima apariție pe traseul înregistrat (cronologic).
  List<LatLng> _orderedHotspotPoints() {
    if (_hotspots.isEmpty) return const [];
    const d = Distance();
    final entries = <MapEntry<MovementHotspot, int>>[];
    for (final h in _hotspots) {
      var bestI = 0;
      var bestD = double.infinity;
      for (var i = 0; i < _samples.length; i++) {
        final s = _samples[i];
        final m = d.as(
          LengthUnit.Meter,
          LatLng(s.latitude, s.longitude),
          LatLng(h.latitude, h.longitude),
        );
        if (m < bestD) {
          bestD = m;
          bestI = i;
        }
      }
      entries.add(MapEntry(h, bestI));
    }
    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries.map((e) => LatLng(e.key.latitude, e.key.longitude)).toList();
  }

  /// Puncte legate în recap: preferă hotspot-uri; altfel eșantion din traseu.
  List<LatLng> _cinematicWaypoints() {
    final hp = _orderedHotspotPoints();
    if (hp.length >= 2) return hp;
    if (_samples.length >= 2) {
      const maxPts = 18;
      final stride = math.max(1, _samples.length ~/ maxPts);
      final out = <LatLng>[];
      for (var i = 0; i < _samples.length; i += stride) {
        out.add(LatLng(_samples[i].latitude, _samples[i].longitude));
      }
      final last = LatLng(_samples.last.latitude, _samples.last.longitude);
      if (out.isEmpty || out.last.latitude != last.latitude || out.last.longitude != last.longitude) {
        out.add(last);
      }
      if (out.length >= 2) return out;
      return [
        LatLng(_samples.first.latitude, _samples.first.longitude),
        last,
      ];
    }
    if (_samples.length == 1) {
      return [LatLng(_samples.first.latitude, _samples.first.longitude)];
    }
    return const [];
  }

  List<LatLng> _partialWaypointsPath(double t) {
    final pts = _cinematicWaypoints();
    if (pts.isEmpty) return const [];
    if (pts.length == 1) return pts;
    t = t.clamp(0.0, 1.0);
    const d = Distance();
    final segLens = <double>[];
    var total = 0.0;
    for (var i = 1; i < pts.length; i++) {
      final len = d.as(LengthUnit.Meter, pts[i - 1], pts[i]);
      segLens.add(len);
      total += len;
    }
    if (total <= 0) return pts;
    final target = total * t;
    var acc = 0.0;
    final out = <LatLng>[pts.first];
    for (var i = 0; i < segLens.length; i++) {
      final sl = segLens[i];
      if (acc + sl >= target) {
        final u = sl <= 0 ? 1.0 : (target - acc) / sl;
        final a = pts[i];
        final b = pts[i + 1];
        out.add(LatLng(
          a.latitude + (b.latitude - a.latitude) * u,
          a.longitude + (b.longitude - a.longitude) * u,
        ));
        return out;
      }
      acc += sl;
      out.add(pts[i + 1]);
    }
    return pts;
  }

  void _applyCinematicTimeline(double t, {bool silent = false}) {
    if (_samples.isEmpty) return;
    t = t.clamp(0.0, 1.0);
    final target = _cinematicTargetLatLng;
    var globeVis = false;
    var globeOp = 0.0;
    var hrp = _hotspotRouteProgress;
    LatLng center;
    double zoom;

    if (t <= _tSpaceEnd) {
      globeVis = true;
      globeOp = 1.0;
      center = _worldRecapCenter;
      zoom = _zoomWorld;
      hrp = 0.0;
    } else if (t <= _tZoomInEnd) {
      final u = (t - _tSpaceEnd) / (_tZoomInEnd - _tSpaceEnd);
      final ease = Curves.easeOutCubic.transform(u);
      const fadeOutBy = 0.72;
      globeVis = u < fadeOutBy;
      globeOp = globeVis ? (1.0 - Curves.easeIn.transform(u / fadeOutBy)).clamp(0.0, 1.0) : 0.0;
      center = LatLng(
        _worldRecapCenter.latitude + (target.latitude - _worldRecapCenter.latitude) * ease,
        _worldRecapCenter.longitude + (target.longitude - _worldRecapCenter.longitude) * ease,
      );
      zoom = _zoomWorld + (_zoomCity - _zoomWorld) * ease;
      hrp = 0.0;
    } else if (t <= _tRouteEnd) {
      globeVis = false;
      globeOp = 0.0;
      center = target;
      zoom = _zoomCity;
      hrp = (t - _tZoomInEnd) / (_tRouteEnd - _tZoomInEnd);
    } else {
      final u = (t - _tRouteEnd) / (1.0 - _tRouteEnd);
      final ease = Curves.easeInCubic.transform(u);
      center = LatLng(
        target.latitude + (_worldRecapCenter.latitude - target.latitude) * ease,
        target.longitude + (_worldRecapCenter.longitude - target.longitude) * ease,
      );
      zoom = _zoomCity + (_zoomWorld - _zoomCity) * ease;
      hrp = 1.0;
      const globeStart = 0.58;
      if (u > globeStart) {
        globeVis = true;
        final gu = (u - globeStart) / (1.0 - globeStart);
        globeOp = Curves.easeIn.transform(gu.clamp(0.0, 1.0));
      }
    }

    setState(() {
      _globeOverlayVisible = globeVis;
      _globeOpacity = globeOp;
      _hotspotRouteProgress = hrp;
    });
    _mapController.move(center, zoom);
    if (!silent) {
      final wCount = _cinematicWaypoints().length;
      unawaited(_recapAudio.syncTimeline(
        t: t,
        hotspotRouteProgress: hrp,
        waypointCount: wCount,
      ));
    }
  }

  Future<void> _runCinematicRecap() async {
    if (_samples.isEmpty) return;
    final gen = ++_cinematicGen;
    _playbackTimer?.cancel();
    await _recapAudio.stop();
    _recapAudio.resetForRecap();
    setState(() {
      _cinematicRunning = true;
      _isPlaying = false;
      _progress = 0;
    });

    const totalMs = 8200;
    const tick = 16;
    var elapsed = 0;
    while (elapsed <= totalMs && mounted && gen == _cinematicGen) {
      _applyCinematicTimeline(elapsed / totalMs);
      await Future<void>.delayed(const Duration(milliseconds: tick));
      elapsed += tick;
    }

    if (!mounted) return;
    await _recapAudio.stop();
    if (gen != _cinematicGen) return;
    if (!mounted) return;
    setState(() {
      _cinematicRunning = false;
      _globeOverlayVisible = false;
      _globeOpacity = 0;
      _hotspotRouteProgress = 0;
      _progress = 0;
    });
    _followCurrent();
  }

  void _togglePlayback() {
    if (_samples.length < 2) return;
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) return;
      final next = _progress + (0.008 * _speed);
      if (next >= 1) {
        setState(() {
          _progress = 1;
          _isPlaying = false;
        });
        _playbackTimer?.cancel();
        return;
      }
      setState(() => _progress = next);
      _followCurrent();
    });
  }

  void _followCurrent() {
    final idx = _currentIndex;
    if (idx < 0 || idx >= _samples.length) return;
    final s = _samples[idx];
    _mapController.move(LatLng(s.latitude, s.longitude), _suggestedZoom(idx));
  }

  double _suggestedZoom(int idx) {
    if (_samples.length < 2) return 15;
    final ratio = idx / (_samples.length - 1);
    if (ratio < 0.15) return 11.5;
    if (ratio > 0.8) return 15.2;
    return 13.8;
  }

  int get _currentIndex {
    if (_samples.isEmpty) return 0;
    final effective = Curves.easeInOutCubic.transform(_progress.clamp(0, 1));
    return (effective * (_samples.length - 1)).round().clamp(0, _samples.length - 1);
  }

  List<LatLng> get _visiblePath {
    if (_samples.isEmpty) return const <LatLng>[];
    final idx = _currentIndex;
    return _samples.take(idx + 1).map((s) => LatLng(s.latitude, s.longitude)).toList(growable: false);
  }

  List<CircleMarker> _buildPressureDots(List<LatLng> path) {
    if (path.length < 3) return const <CircleMarker>[];

    final buckets = <String, _PressureBucket>{};
    for (var i = 0; i < path.length; i++) {
      final p = path[i];
      final key =
          '${(p.latitude * 10000).round()}:${(p.longitude * 10000).round()}';
      final bucket = buckets[key] ?? _PressureBucket();
      bucket.add(p.latitude, p.longitude, i);
      buckets[key] = bucket;
    }

    final ordered = buckets.values.toList()
      ..sort((a, b) => a.lastIndex.compareTo(b.lastIndex));
    if (ordered.isEmpty) return const <CircleMarker>[];

    const maxDots = 180;
    final step = math.max(1, (ordered.length / maxDots).ceil());
    final circles = <CircleMarker>[];

    for (var i = 0; i < ordered.length; i += step) {
      final b = ordered[i];
      final weight = b.count.toDouble();
      final recency = (i / math.max(1, ordered.length - 1)).clamp(0.0, 1.0);
      final radius = (3.0 + weight * 1.05).clamp(3.4, 12.8).toDouble();
      final alpha =
          (0.18 + (weight / 20) + recency * 0.14).clamp(0.24, 0.68).toDouble();

      circles.add(
        CircleMarker(
          point: LatLng(b.avgLat, b.avgLng),
          radius: radius,
          color: Colors.lightBlueAccent.withValues(alpha: alpha),
          borderColor: Colors.white.withValues(alpha: alpha * 0.9),
          borderStrokeWidth: 0.9,
        ),
      );
    }

    return circles;
  }

  @override
  Widget build(BuildContext context) {
    final inCinematicView = _cinematicRunning || _isExporting;
    final List<LatLng> path;
    if (inCinematicView) {
      if (_hotspotRouteProgress <= 0) {
        path = const <LatLng>[];
      } else {
        path = _partialWaypointsPath(_hotspotRouteProgress);
      }
    } else {
      path = _visiblePath;
    }
    final pressurePath = inCinematicView && _hotspotRouteProgress > 0.02
        ? _partialWaypointsPath(_hotspotRouteProgress.clamp(0.0, 1.0))
        : path;
    final pressureDots = _buildPressureDots(pressurePath);
    final marker = _samples.isEmpty
        ? null
        : (inCinematicView && path.isNotEmpty
            ? null
            : _samples[_currentIndex]);
    final cinematicMarkerPoint =
        inCinematicView && path.isNotEmpty ? path.last : null;
    final showFinalCard =
        _samples.isNotEmpty && _progress >= 0.999 && !_cinematicRunning && !_isExporting;
    final pulse = 0.5 + 0.5 * math.sin(_progress * math.pi * 20);
    final pulseSize = 28.0 + pulse * 14.0;
    final pulseAlpha = 0.16 + pulse * 0.16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recap deplasări'),
        actions: [
          IconButton(
            tooltip: 'Share Week in Review',
            onPressed: _samples.isEmpty || _isExporting ? null : _shareWeekInReview,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: 'Selectează perioada',
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                RepaintBoundary(
                  key: _captureBoundaryKey,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(44.4268, 26.1025),
                          initialZoom: 12.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.nabour.app',
                          ),
                          if (_hotspots.isNotEmpty)
                            CircleLayer(
                              circles: _hotspots.map((h) {
                                final opacity = (h.weight / 12).clamp(0.18, 0.45);
                                return CircleMarker(
                                  point: LatLng(h.latitude, h.longitude),
                                  radius: (8 + h.weight * 1.3).clamp(10, 36),
                                  color: Colors.purple.withValues(alpha: opacity.toDouble()),
                                );
                              }).toList(growable: false),
                            ),
                          if (path.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: path,
                                  strokeWidth: 7,
                                  color: Colors.purpleAccent.withValues(alpha: 0.18),
                                ),
                              ],
                            ),
                          if (path.length >= 2)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: path,
                                  strokeWidth: 5,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ],
                            ),
                          if (pressureDots.isNotEmpty)
                            CircleLayer(circles: pressureDots),
                          if (marker != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(marker.latitude, marker.longitude),
                                  width: 42,
                                  height: 42,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: pulseSize,
                                        height: pulseSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blueAccent
                                              .withValues(alpha: pulseAlpha),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blueAccent,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 10,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          if (cinematicMarkerPoint != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: cinematicMarkerPoint,
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blueAccent,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.indigo.withValues(alpha: 0.10),
                                  Colors.purple.withValues(alpha: 0.10),
                                  Colors.black.withValues(alpha: 0.10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: _buildDateChip(
                          marker ??
                              (_samples.isNotEmpty ? _samples[_currentIndex] : null),
                        ),
                      ),
                      if (_globeOverlayVisible)
                        Positioned.fill(
                          child: MovementRecapGlobeOverlay(
                            opacity: _globeOpacity,
                            pinNormalized: latLngToGlobePinNormalized(
                              _cinematicTargetLatLng.latitude,
                              _cinematicTargetLatLng.longitude,
                            ),
                          ),
                        ),
                      if (showFinalCard)
                        Positioned(
                          top: 78,
                          left: 16,
                          right: 16,
                          child: _buildFinalStatsCard(),
                        ),
                      if (_cinematicRunning)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 14,
                  child: _buildControls(),
                ),
                if (_isExporting)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text(
                              'Export Week in Review...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDateChip(MovementSample? marker) {
    final text = marker == null
        ? 'Nu există date în perioada selectată'
        : '${marker.timestamp.day.toString().padLeft(2, '0')}.'
            '${marker.timestamp.month.toString().padLeft(2, '0')}.'
            '${marker.timestamp.year}  '
            '${marker.timestamp.hour.toString().padLeft(2, '0')}:'
            '${marker.timestamp.minute.toString().padLeft(2, '0')}';

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildFinalStatsCard() {
    final topHotspot = _hotspots.isEmpty
        ? null
        : (_hotspots.toList()..sort((a, b) => b.weight.compareTo(a.weight))).first;
    final totalKm = _calculateTotalDistanceKm();
    final activeHours = _calculateActiveHours();
    final hotspotText = topHotspot == null
        ? 'N/A'
        : '${topHotspot.latitude.toStringAsFixed(4)}, ${topHotspot.longitude.toStringAsFixed(4)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _stat('KM', totalKm.toStringAsFixed(1)),
          _stat('ORE', activeHours.toStringAsFixed(1)),
          _stat('HOTSPOT', hotspotText),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final isNarrow = MediaQuery.of(context).size.width < 390;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_cinematicRunning)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'Recap cinematic...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          Slider(
            value: _progress,
            onChanged: _samples.isEmpty || _isExporting || _cinematicRunning
                ? null
                : (v) {
                    setState(() => _progress = v);
                    _followCurrent();
                  },
          ),
          if (!isNarrow)
            Row(
              children: [
                IconButton(
                  onPressed: _samples.isEmpty || _isExporting || _cinematicRunning
                      ? null
                      : () => unawaited(_runCinematicRecap()),
                  icon: const Icon(Icons.public_rounded, color: Colors.white),
                  tooltip: 'Replay intro',
                ),
                IconButton(
                  onPressed: _samples.isEmpty || _isExporting || _cinematicRunning
                      ? null
                      : () {
                          setState(() => _progress = 0);
                          _followCurrent();
                        },
                  icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                ),
                IconButton(
                  onPressed: _samples.isEmpty || _isExporting || _cinematicRunning
                      ? null
                      : _togglePlayback,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _samples.isEmpty || _isExporting ? null : _shareWeekInReview,
                  icon: const Icon(Icons.ios_share_rounded, size: 16),
                  label: const Text('Week in Review'),
                ),
                const SizedBox(width: 10),
                _speedChip(0.5),
                const SizedBox(width: 8),
                _speedChip(1),
                const SizedBox(width: 8),
                _speedChip(2),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _samples.isEmpty || _isExporting || _cinematicRunning
                      ? null
                      : () => unawaited(_runCinematicRecap()),
                      icon: const Icon(Icons.public_rounded, color: Colors.white),
                      tooltip: 'Replay intro',
                    ),
                    IconButton(
                      onPressed: _samples.isEmpty || _isExporting
                          ? null
                          : () {
                              setState(() => _progress = 0);
                              _followCurrent();
                            },
                      icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: _samples.isEmpty || _isExporting || _cinematicRunning
                      ? null
                      : _togglePlayback,
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const Spacer(),
                    _speedChip(0.5),
                    const SizedBox(width: 8),
                    _speedChip(1),
                    const SizedBox(width: 8),
                    _speedChip(2),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _samples.isEmpty || _isExporting ? null : _shareWeekInReview,
                    icon: const Icon(Icons.ios_share_rounded, size: 16),
                    label: const Text('Week in Review'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _speedChip(double speed) {
    final selected = (_speed - speed).abs() < 0.001;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _speed = speed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.purpleAccent : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          speed == speed.roundToDouble() ? '${speed.toInt()}x' : '${speed.toStringAsFixed(1)}x',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _pickRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (selected == null) return;
    setState(() {
      _range = selected;
      _progress = 0;
      _isPlaying = false;
    });
    await _loadData();
  }

  double _calculateTotalDistanceKm() {
    if (_samples.length < 2) return 0;
    var meters = 0.0;
    const d = Distance();
    for (var i = 1; i < _samples.length; i++) {
      final prev = _samples[i - 1];
      final cur = _samples[i];
      meters += d.as(
        LengthUnit.Meter,
        LatLng(prev.latitude, prev.longitude),
        LatLng(cur.latitude, cur.longitude),
      );
    }
    return meters / 1000.0;
  }

  double _calculateActiveHours() {
    if (_samples.length < 2) return 0;
    final duration = _samples.last.timestamp.difference(_samples.first.timestamp);
    return duration.inMinutes / 60.0;
  }

  Future<void> _shareWeekInReview() async {
    if (_isExporting) return;
    setState(() {
      _isExporting = true;
      _isPlaying = false;
    });
    _playbackTimer?.cancel();
    await _recapAudio.stop();

    try {
      final prevProgress = _progress;
      final prevGlobeV = _globeOverlayVisible;
      final prevGlobeO = _globeOpacity;
      final prevHrp = _hotspotRouteProgress;
      final frameSteps = List<double>.generate(28, (i) => i / 27.0);
      final docsDir = await getApplicationDocumentsDirectory();
      final rootDir = Directory('${docsDir.path}/week_in_review_exports');
      await rootDir.create(recursive: true);
      final exportDir = Directory('${rootDir.path}/week_in_review_${DateTime.now().millisecondsSinceEpoch}');
      await exportDir.create(recursive: true);
      final exported = <String>[];

      for (var i = 0; i < frameSteps.length; i++) {
        if (!mounted) return;
        _applyCinematicTimeline(frameSteps[i], silent: true);
        await Future<void>.delayed(const Duration(milliseconds: 130));
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 45));

        final imagePath = '${exportDir.path}/nabour_week_${i.toString().padLeft(2, '0')}.png';
        final bytes = await _captureCurrentFrame();
        if (bytes != null) {
          await File(imagePath).writeAsBytes(bytes, flush: true);
          exported.add(imagePath);
        }
      }

      if (mounted) {
        setState(() {
          _progress = prevProgress;
          _globeOverlayVisible = prevGlobeV;
          _globeOpacity = prevGlobeO;
          _hotspotRouteProgress = prevHrp;
        });
        _followCurrent();
      }

      if (exported.isEmpty) {
        throw Exception('Nu s-au putut exporta cadrele.');
      }

      final totalKm = _calculateTotalDistanceKm().toStringAsFixed(1);
      final activeHours = _calculateActiveHours().toStringAsFixed(1);
      await DeprecatedAPIsFix.shareFiles(
        exported,
        subject: 'Nabour Week in Review',
        text: 'Week in Review Nabour: $totalKm km, $activeHours ore active. #Nabour #LocalRecap',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export/share nereușit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<List<int>?> _captureCurrentFrame() async {
    try {
      final ctx = _captureBoundaryKey.currentContext;
      final ro = ctx?.findRenderObject();
      if (ro is! RenderRepaintBoundary) return null;
      if (ro.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      final image = await ro.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

class _PressureBucket {
  double _latSum = 0;
  double _lngSum = 0;
  int count = 0;
  int lastIndex = 0;

  void add(double lat, double lng, int index) {
    _latSum += lat;
    _lngSum += lng;
    count += 1;
    lastIndex = index;
  }

  double get avgLat => _latSum / count;
  double get avgLng => _lngSum / count;
}
