import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/services/routing_service.dart';
import 'package:nabour_app/utils/logger.dart';

/// Generează PNG al traseului pentru Storage: preferă **Mapbox Snapshotter** (stil ca în app),
/// cu fallback **OSM / flutter_map** dacă Mapbox e indisponibil.
class RoutePreviewCaptureService {
  RoutePreviewCaptureService._();

  static const double _captureWidth = 720;
  static const double _captureHeight = 960;

  static const int _maxCameraPoints = 64;

  static List<LatLng> _cameraPolylineSample(List<LatLng> pts) {
    if (pts.length <= _maxCameraPoints) return pts;
    final step = ((pts.length - 1) / (_maxCameraPoints - 1)).ceil().clamp(1, pts.length);
    final out = <LatLng>[pts.first];
    for (var i = step; i < pts.length - 1; i += step) {
      out.add(pts[i]);
    }
    out.add(pts.last);
    return out;
  }

  /// Mapbox static snapshot (același tip de hartă ca în aplicație).
  static Future<Uint8List?> _captureMapboxRoutePng({
    required List<LatLng> polyline,
    required LatLng start,
    required LatLng end,
  }) async {
    mbx.Snapshotter? snapshotter;
    try {
      final uniq = DateTime.now().millisecondsSinceEpoch;
      final srcId = 'route-cap-src-$uniq';
      final layerId = 'route-cap-layer-$uniq';

      final coords = polyline.length >= 2 ? polyline : [start, end];
      final forCamera = _cameraPolylineSample(coords);
      final cameraPoints = forCamera
          .map((ll) => mbx.Point(coordinates: mbx.Position(ll.longitude, ll.latitude)))
          .toList();

      final styleReady = Completer<void>();
      snapshotter = await mbx.Snapshotter.create(
        options: mbx.MapSnapshotOptions(
          size: mbx.Size(width: _captureWidth, height: _captureHeight),
          pixelRatio: 2,
          showsLogo: false,
          showsAttribution: true,
        ),
        onStyleLoadedListener: (_) {
          if (!styleReady.isCompleted) styleReady.complete();
        },
      );

      await snapshotter.style.setStyleURI(mbx.MapboxStyles.MAPBOX_STREETS);
      await styleReady.future.timeout(const Duration(seconds: 25));

      final lineData = json.encode({
        'type': 'LineString',
        'coordinates': coords.map((p) => [p.longitude, p.latitude]).toList(),
      });

      await snapshotter.style.addSource(mbx.GeoJsonSource(id: srcId, data: lineData));
      await snapshotter.style.addLayer(mbx.LineLayer(
        id: layerId,
        sourceId: srcId,
        lineColor: const Color(0xFF1565C0).toARGB32(),
        lineWidth: 5.0,
        lineOpacity: 0.92,
      ));

      final cam = await snapshotter.camera(
        coordinates: cameraPoints,
        padding: mbx.MbxEdgeInsets(top: 100, left: 100, bottom: 100, right: 100),
        bearing: 0,
        pitch: 0,
      );
      await snapshotter.setCamera(cam);
      await Future<void>.delayed(const Duration(milliseconds: 900));

      final out = await snapshotter.start();
      if (out == null || out.isEmpty) return null;
      return out;
    } catch (e, st) {
      Logger.warning('RoutePreviewCaptureService: Mapbox snapshot failed ($e)\n$st');
      return null;
    } finally {
      try {
        await snapshotter?.dispose();
      } catch (_) {}
    }
  }

  /// Returnează bytes PNG sau `null` dacă eșuează.
  static Future<Uint8List?> captureRoutePng({
    required BuildContext context,
    required Ride ride,
  }) async {
    if (ride.startLatitude == null ||
        ride.startLongitude == null ||
        ride.destinationLatitude == null ||
        ride.destinationLongitude == null) {
      return null;
    }

    final start = LatLng(ride.startLatitude!, ride.startLongitude!);
    final end = LatLng(ride.destinationLatitude!, ride.destinationLongitude!);

    final routing = RoutingService();
    List<LatLng> polyline;
    try {
      final route = await routing.getRoute([
        mbx.Point(coordinates: mbx.Position(ride.startLongitude!, ride.startLatitude!)),
        mbx.Point(coordinates: mbx.Position(ride.destinationLongitude!, ride.destinationLatitude!)),
      ]);
      if (route != null) {
        polyline = routing
            .extractRouteCoordinates(route)
            .map((p) => LatLng(p.coordinates.lat.toDouble(), p.coordinates.lng.toDouble()))
            .toList();
      } else {
        polyline = [start, end];
      }
    } catch (e) {
      Logger.warning('RoutePreviewCaptureService: routing fallback ($e)');
      polyline = [start, end];
    }
    if (polyline.length < 2) {
      polyline = [start, end];
    }

    final mapboxPng = await _captureMapboxRoutePng(polyline: polyline, start: start, end: end);
    if (mapboxPng != null && mapboxPng.isNotEmpty) {
      return mapboxPng;
    }

    if (!context.mounted) {
      return null;
    }
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      Logger.warning('RoutePreviewCaptureService: no Overlay in context (OSM fallback)');
      return null;
    }

    final completer = Completer<Uint8List?>();
    late OverlayEntry entry;
    Timer? watchdog;

    void completeCapture(Uint8List? bytes) {
      watchdog?.cancel();
      try {
        entry.remove();
      } catch (_) {}
      if (!completer.isCompleted) {
        completer.complete(bytes);
      }
    }

    entry = OverlayEntry(
      builder: (ctx) => _OffstageRouteCapture(
        width: _captureWidth,
        height: _captureHeight,
        polyline: polyline,
        start: start,
        end: end,
        onDone: completeCapture,
      ),
    );

    watchdog = Timer(const Duration(seconds: 14), () => completeCapture(null));
    overlay.insert(entry);
    return completer.future;
  }
}

class _OffstageRouteCapture extends StatefulWidget {
  const _OffstageRouteCapture({
    required this.width,
    required this.height,
    required this.polyline,
    required this.start,
    required this.end,
    required this.onDone,
  });

  final double width;
  final double height;
  final List<LatLng> polyline;
  final LatLng start;
  final LatLng end;
  final void Function(Uint8List? bytes) onDone;

  @override
  State<_OffstageRouteCapture> createState() => _OffstageRouteCaptureState();
}

class _OffstageRouteCaptureState extends State<_OffstageRouteCapture> {
  final MapController _mapController = MapController();
  final GlobalKey _boundaryKey = GlobalKey();
  bool _captureScheduled = false;

  Future<void> _runCaptureSequence() async {
    if (_captureScheduled) return;
    _captureScheduled = true;

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      widget.onDone(null);
      return;
    }

    try {
      final pts = widget.polyline.length >= 2 ? widget.polyline : [widget.start, widget.end];
      final bounds = LatLngBounds.fromPoints(pts);
      const pad = EdgeInsets.all(112);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: pad),
      );
    } catch (e) {
      Logger.debug('RoutePreviewCaptureService: fitCamera $e');
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      try {
        final pts = widget.polyline.length >= 2 ? widget.polyline : [widget.start, widget.end];
        final bounds = LatLngBounds.fromPoints(pts);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(112)),
        );
      } catch (_) {}
    }

    await Future<void>.delayed(const Duration(milliseconds: 2000));

    Uint8List? out;
    try {
      final ctx = _boundaryKey.currentContext;
      final ro = ctx?.findRenderObject();
      if (ro is RenderRepaintBoundary) {
        if (ro.debugNeedsPaint) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        final image = await ro.toImage(pixelRatio: 2);
        final bd = await image.toByteData(format: ui.ImageByteFormat.png);
        out = bd?.buffer.asUint8List();
      }
    } catch (e) {
      Logger.error('RoutePreviewCaptureService: toImage failed', error: e);
    }

    if (!mounted) return;
    widget.onDone(out);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -5000,
      top: 0,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: ColoredBox(
            color: Colors.white,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.start,
                initialZoom: 11,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                onMapReady: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Future<void>.microtask(_runCaptureSequence);
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ro.nabour.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.polyline,
                      color: const Color(0xFF1565C0),
                      strokeWidth: 5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.start,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.trip_origin, color: Colors.green, size: 32),
                    ),
                    Marker(
                      point: widget.end,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.flag, color: Colors.red, size: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
