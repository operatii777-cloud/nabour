import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/services/active_ride_telemetry_rtdb_service.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/routing_service.dart';
import 'package:nabour_app/utils/external_maps_launcher.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/utils/driver_icon_helper.dart';
import 'package:nabour_app/utils/mapbox_utils.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/services/telemetry_service.dart';
import 'package:nabour_app/services/local_notifications_service.dart';
import 'package:nabour_app/widgets/app_drawer.dart';

/// Cursă activă: hartă Mapbox + tracking până la pickup; după pickup — doar Maps/Waze spre destinație.
class ActiveRideScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic>? routeGeoJSON;
  final bool isDriverView;

  const ActiveRideScreen({
    super.key,
    required this.rideId,
    this.routeGeoJSON,
    this.isDriverView = false,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  static const _kRouteSourceId = 'active-ride-route-src';
  static const _kRouteLayerId = 'active-ride-route-layer';

  final FirestoreService _firestoreService = FirestoreService();
  final RoutingService _routingService = RoutingService();

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _markersManager;
  PointAnnotation? _driverAnnotation;
  PointAnnotation? _startAnnotation;
  PointAnnotation? _endAnnotation;

  bool _mapReady = false;
  bool _isManualPan = false;
  Timer? _autoRecenterTimer;
  Timer? _cameraFollowDebounce;

  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  StreamSubscription<Ride>? _rideStatusSubscription;
  StreamSubscription<ActiveRideDriverLocation?>? _driverLocationSubscription;
  StreamSubscription<double>? _crashSubscription;
  StreamSubscription<double>? _aggressiveSubscription;

  bool _hasNavigatedOnCompletion = false;
  bool _passengerDestinationHandoffStarted = false;
  bool _isDriverView = false;

  Point? _startPoint;
  Point? _endPoint;
  List<Point> _routeLinePoints = [];
  bool _routeLoadFailed = false;

  /// Ultima poziție șofer (pentru SOS / recentre).
  final ValueNotifier<Point?> _driverPointNotifier = ValueNotifier(null);
  double? _driverHeadingDeg;
  DateTime? _lastDriverAnnotationUpdate;

  Uint8List? _driverIconBytes;
  Uint8List? _startIconBytes;
  Uint8List? _endIconBytes;

  bool _isGpsLost = false;
  DateTime? _lastGpsUpdate;
  Timer? _gpsWatchdog;

  @override
  void initState() {
    super.initState();
    _isDriverView = widget.isDriverView;
    WakelockPlus.enable();
    unawaited(_loadMarkerIcons());
    _initializeRideAndSubscribe();
    _startGpsWatchdog();

    if (_isDriverView) {
      _startTelemetry();
    }
  }

  Future<void> _loadMarkerIcons() async {
    try {
      final d = await DriverIconHelper.getDriverIconBytes();
      if (mounted) _driverIconBytes = d;
    } catch (_) {}
    try {
      final s = await rootBundle.load('assets/images/passenger_icon.png');
      final e = await rootBundle.load('assets/images/pin_icon.png');
      if (mounted) {
        _startIconBytes = s.buffer.asUint8List();
        _endIconBytes = e.buffer.asUint8List();
        if (_mapReady) unawaited(_syncMapContent());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _rideStatusSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    _gpsWatchdog?.cancel();
    _autoRecenterTimer?.cancel();
    _cameraFollowDebounce?.cancel();
    _driverPointNotifier.dispose();

    if (_isDriverView) {
      _crashSubscription?.cancel();
      _aggressiveSubscription?.cancel();
      TelemetryService().stopTracking();
    }

    unawaited(_tearDownMapLayers());
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _tearDownMapLayers() async {
    final map = _mapboxMap;
    if (map == null) return;
    try {
      await map.style.removeStyleLayer(_kRouteLayerId);
    } catch (_) {}
    try {
      await map.style.removeStyleSource(_kRouteSourceId);
    } catch (_) {}
  }

  void _startTelemetry() {
    TelemetryService().startTracking();

    _crashSubscription = TelemetryService().onCrashDetected.listen((magnitude) {
      if (!mounted) return;
      _showCrashEmergencyOverlay();
    });

    _aggressiveSubscription =
        TelemetryService().onAggressiveEvent.listen((magnitude) {
      Logger.debug('Aggressive event pe hartă: $magnitude');
    });
  }

  void _showCrashEmergencyOverlay() {
    bool cancelled = false;
    int secondsLeft = 10;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            Timer? timer;
            timer = Timer.periodic(const Duration(seconds: 1), (t) {
              if (cancelled) {
                t.cancel();
                return;
              }
              if (secondsLeft <= 1) {
                t.cancel();
                Navigator.of(ctx).pop();
                _triggerSOSAlert();
              } else {
                setState(() => secondsLeft--);
              }
            });

            return Dialog(
              backgroundColor: Colors.red.shade800,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'IMPACT DETECTAT!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Alerta SOS se trimite cartierului în...',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '$secondsLeft',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          cancelled = true;
                          timer?.cancel();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('SUNT BINE - ANULEAZĂ',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _triggerSOSAlert() async {
    Logger.error('SOS DECLANȘAT: Impact rutier nesoluționat!', tag: 'TELEMETRY');
    LocalNotificationsService().showSimple(
      title: '🚨 ALERTĂ SOS TRIMISĂ 🚨',
      body: 'Locația a fost trimisă contactelor de urgență.',
      payload: 'sos_alert',
    );

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    double? lat;
    double? lng;
    try {
      final p = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      lat = p.latitude;
      lng = p.longitude;
    } catch (_) {
      try {
        final last = await geo.Geolocator.getLastKnownPosition();
        lat = last?.latitude;
        lng = last?.longitude;
      } catch (_) {}
    }
    final pt = _driverPointNotifier.value;
    lat ??= pt?.coordinates.lat.toDouble();
    lng ??= pt?.coordinates.lng.toDouble();

    final userName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Șofer Nabour';

    try {
      await FirebaseFirestore.instance.collection('emergency_alerts').add({
        'userId': uid,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': lat,
        'longitude': lng,
        'rideId': widget.rideId,
        'status': 'active',
      });
    } catch (e) {
      Logger.error('Scriere emergency_alerts eșuată: $e',
          error: e, tag: 'TELEMETRY');
    }
  }

  Future<void> _initializeRideAndSubscribe() async {
    final r = await _firestoreService.getRideStream(widget.rideId).first;
    if (!mounted) return;

    await _loadStaticRoute(r);

    _subscribeToRideStatusChanges();
    _startDriverLocationTracking();
  }

  Future<void> _loadStaticRoute(Ride ride) async {
    if (ride.startLatitude == null ||
        ride.startLongitude == null ||
        ride.destinationLatitude == null ||
        ride.destinationLongitude == null) {
      if (mounted) setState(() => _routeLoadFailed = true);
      return;
    }

    _startPoint = MapboxUtils.createPoint(
        ride.startLatitude!, ride.startLongitude!);
    _endPoint = MapboxUtils.createPoint(
        ride.destinationLatitude!, ride.destinationLongitude!);

    try {
      final route = await _routingService.getRoute([
        Point(
            coordinates: Position(
                ride.startLongitude!, ride.startLatitude!)),
        Point(
            coordinates: Position(ride.destinationLongitude!,
                ride.destinationLatitude!)),
      ]);
      if (!mounted) return;
      final pts =
          route != null ? _routingService.extractRouteCoordinates(route) : null;
      setState(() {
        _routeLinePoints = pts != null && pts.isNotEmpty
            ? pts
            : [_startPoint!, _endPoint!];
        _routeLoadFailed = pts == null;
      });
      await _syncMapContent();
    } catch (e) {
      Logger.error('Static route load failed: $e', error: e);
      if (mounted) {
        setState(() {
          _routeLinePoints = [_startPoint!, _endPoint!];
          _routeLoadFailed = true;
        });
        await _syncMapContent();
      }
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _mapReady = true;
    try {
      _markersManager = await map.annotations
          .createPointAnnotationManager(id: 'active-ride-${widget.rideId}');
    } catch (e) {
      Logger.warning('Active ride annotation manager: $e', tag: 'ACTIVE_RIDE');
    }
    await _syncMapContent();
  }

  Future<void> _syncMapContent() async {
    if (!_mapReady || _mapboxMap == null) return;

    await _updateRoutePolylineLayer();
    await _ensureStartEndMarkers();
    await _updateDriverAnnotation();

    if (_driverPointNotifier.value == null) {
      _fitRouteInView();
    }
  }

  Future<void> _updateRoutePolylineLayer() async {
    final map = _mapboxMap;
    if (map == null) return;
    final lineColor = Theme.of(context).colorScheme.primary.toARGB32();

    try {
      await map.style.removeStyleLayer(_kRouteLayerId);
    } catch (_) {}
    try {
      await map.style.removeStyleSource(_kRouteSourceId);
    } catch (_) {}

    if (_routeLinePoints.length < 2) return;

    final coords = _routeLinePoints
        .map((p) => [p.coordinates.lng.toDouble(), p.coordinates.lat.toDouble()])
        .toList();

    final feature = {
      'type': 'Feature',
      'geometry': {
        'type': 'LineString',
        'coordinates': coords,
      },
      'properties': <String, dynamic>{},
    };

    try {
      await map.style.addSource(
        GeoJsonSource(id: _kRouteSourceId, data: json.encode(feature)),
      );
      if (!mounted) return;
      await map.style.addLayer(LineLayer(
        id: _kRouteLayerId,
        sourceId: _kRouteSourceId,
        lineColor: lineColor,
        lineWidth: 5.0,
        lineOpacity: 0.85,
      ));
    } catch (e) {
      Logger.warning('Route layer: $e', tag: 'ACTIVE_RIDE');
    }
  }

  Future<void> _ensureStartEndMarkers() async {
    final mgr = _markersManager;
    if (mgr == null) return;

    if (_startPoint != null && _startIconBytes != null) {
      try {
        if (_startAnnotation != null) {
          await mgr.delete(_startAnnotation!);
          _startAnnotation = null;
        }
        _startAnnotation = await mgr.create(PointAnnotationOptions(
          geometry: _startPoint!,
          image: _startIconBytes!,
          iconSize: 0.28,
          iconAnchor: IconAnchor.BOTTOM,
        ));
      } catch (_) {}
    }

    if (_endPoint != null && _endIconBytes != null) {
      try {
        if (_endAnnotation != null) {
          await mgr.delete(_endAnnotation!);
          _endAnnotation = null;
        }
        _endAnnotation = await mgr.create(PointAnnotationOptions(
          geometry: _endPoint!,
          image: _endIconBytes!,
          iconSize: 0.42,
          iconAnchor: IconAnchor.BOTTOM,
        ));
      } catch (_) {}
    }
  }

  Future<void> _updateDriverAnnotation() async {
    final mgr = _markersManager;
    final p = _driverPointNotifier.value;
    if (mgr == null || p == null) return;

    final now = DateTime.now();
    if (_lastDriverAnnotationUpdate != null &&
        now.difference(_lastDriverAnnotationUpdate!) <
            const Duration(milliseconds: 80)) {
      return;
    }
    _lastDriverAnnotationUpdate = now;

    final rot = _driverHeadingDeg;
    final iconRot = (rot != null && !rot.isNaN && rot >= 0) ? rot : 0.0;

    Uint8List img;
    if (_driverIconBytes != null) {
      img = _driverIconBytes!;
    } else {
      try {
        final fb =
            await rootBundle.load('assets/images/passenger_icon.png');
        img = fb.buffer.asUint8List();
      } catch (_) {
        return;
      }
    }

    try {
      if (_driverAnnotation != null) {
        _driverAnnotation!.geometry = p;
        _driverAnnotation!.iconRotate = iconRot;
        await mgr.update(_driverAnnotation!);
      } else {
        _driverAnnotation = await mgr.create(PointAnnotationOptions(
          geometry: p,
          image: img,
          iconSize: 0.42,
          iconAnchor: IconAnchor.CENTER,
          iconRotate: iconRot,
        ));
      }
    } catch (e) {
      Logger.debug('Driver annotation update: $e', tag: 'ACTIVE_RIDE');
    }
  }

  void _fitRouteInView() {
    if (!_mapReady || _mapboxMap == null) return;
    final pts = <Point>[
      if (_startPoint != null) _startPoint!,
      ..._routeLinePoints,
      if (_endPoint != null) _endPoint!,
    ];
    if (pts.length < 2) return;

    double minLat = pts.first.coordinates.lat.toDouble();
    double maxLat = minLat;
    double minLng = pts.first.coordinates.lng.toDouble();
    double maxLng = minLng;
    for (final p in pts) {
      final la = p.coordinates.lat.toDouble();
      final ln = p.coordinates.lng.toDouble();
      if (la < minLat) minLat = la;
      if (la > maxLat) maxLat = la;
      if (ln < minLng) minLng = ln;
      if (ln > maxLng) maxLng = ln;
    }

    final cLat = (minLat + maxLat) / 2;
    final cLng = (minLng + maxLng) / 2;
    final latD = (maxLat - minLat).abs();
    final lngD = (maxLng - minLng).abs();
    var zoom = 14.0;
    if (latD > 0.12 || lngD > 0.12) {
      zoom = 11.5;
    } else if (latD > 0.06 || lngD > 0.06) {
      zoom = 12.5;
    }

    unawaited(_mapboxMap!.flyTo(
      CameraOptions(
        center: MapboxUtils.createPoint(cLat, cLng),
        zoom: zoom,
        padding: MbxEdgeInsets(top: 72, left: 24, bottom: 240, right: 24),
      ),
      MapAnimationOptions(duration: 900),
    ));
  }

  void _startDriverLocationTracking() {
    _driverLocationSubscription?.cancel();
    Logger.debug('RTDB driver tracking start: ${widget.rideId}',
        tag: 'ACTIVE_RIDE');

    _driverLocationSubscription = ActiveRideTelemetryRtdbService.instance
        .listenDriverLocation(widget.rideId)
        .listen((loc) {
      if (!mounted || loc == null) return;

      final newPt = MapboxUtils.createPoint(loc.lat, loc.lng);
      _lastGpsUpdate = DateTime.now();
      if (_isGpsLost) setState(() => _isGpsLost = false);

      _driverPointNotifier.value = newPt;
      if (loc.heading != null && !loc.heading!.isNaN) {
        _driverHeadingDeg = loc.heading;
      }

      unawaited(_updateDriverAnnotation());

      _cameraFollowDebounce?.cancel();
      _cameraFollowDebounce =
          Timer(const Duration(milliseconds: 320), () {
        if (!mounted || _isManualPan || _mapboxMap == null) return;
        final center = _driverPointNotifier.value;
        if (center == null) return;
        final h = _driverHeadingDeg;
        final bearing = (h != null && !h.isNaN) ? -h : 0.0;
        unawaited(_mapboxMap!.easeTo(
          CameraOptions(
            center: center,
            zoom: 16.0,
            bearing: bearing,
            pitch: 48.0,
          ),
          MapAnimationOptions(duration: 650),
        ));
      });
    }, onError: (e) {
      Logger.error('RTDB tracking error: $e', tag: 'ACTIVE_RIDE');
    });
  }

  void _startGpsWatchdog() {
    _gpsWatchdog = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final lost = _lastGpsUpdate != null &&
          DateTime.now().difference(_lastGpsUpdate!).inSeconds > 8;
      if (lost != _isGpsLost) setState(() => _isGpsLost = lost);
    });
  }

  void _subscribeToRideStatusChanges() {
    _rideStatusSubscription =
        _firestoreService.getRideStream(widget.rideId).listen((ride) {
      if (!mounted) return;
      if (ride.status == 'completed' && !_hasNavigatedOnCompletion) {
        _hasNavigatedOnCompletion = true;
        Navigator.of(context).popUntil((r) => r.isFirst);
        return;
      }
      if (['cancelled', 'expired'].contains(ride.status)) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        return;
      }
      if (ride.status == 'arrived' &&
          !_isDriverView &&
          !_passengerDestinationHandoffStarted) {
        final lat = ride.destinationLatitude;
        final lng = ride.destinationLongitude;
        if (lat != null && lng != null) {
          _passengerDestinationHandoffStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              unawaited(_runPassengerDestinationHandoff(lat, lng));
            }
          });
        }
      }
    });
  }

  Future<void> _handleDriverArrived(Ride ride) async {
    final dLat = ride.destinationLatitude;
    final dLng = ride.destinationLongitude;
    if (dLat == null || dLng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lipsește destinația cursei — nu putem deschide navigația externă.'),
          ),
        );
      }
      return;
    }
    await _firestoreService.updateRideStatus(widget.rideId, 'arrived');
    await _runDriverDestinationHandoff(dLat, dLng);
  }

  Future<void> _runDriverDestinationHandoff(double destLat, double destLng) async {
    if (!mounted) return;
    await ExternalMapsLauncher.showNavigationChooser(
      context,
      destLat,
      destLng,
      title: 'Destinație finală',
      hint: 'Deschide în Google Maps sau Waze. Navigarea nu mai e în Nabour.',
    );
    if (!mounted) return;
    try {
      await _firestoreService.updateRideStatus(widget.rideId, 'completed');
    } catch (e) {
      Logger.warning('updateRideStatus completed: $e', tag: 'ACTIVE_RIDE');
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _runPassengerDestinationHandoff(
    double destLat,
    double destLng,
  ) async {
    if (!mounted) return;
    await ExternalMapsLauncher.showNavigationChooser(
      context,
      destLat,
      destLng,
      title: 'Destinație finală',
      hint: 'Deschide în Google Maps sau Waze. Navigarea nu mai e în Nabour.',
    );
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialCenter =
        _startPoint ?? MapboxUtils.createPoint(44.4268, 26.1025);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.activeRide ?? 'Cursă Activă'),
        actions: [
          if (_isGpsLost)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.gps_off, color: Colors.orange),
            ),
          IconButton(
            onPressed: () => SharePlus.instance
                .share(ShareParams(text: 'Urmărește cursa mea pe Nabour App!')),
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: StreamBuilder<Ride>(
        stream: _firestoreService.getRideStream(widget.rideId),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ride = snap.data!;
          final isD = _currentUserId == ride.driverId;
          return Stack(
            children: [
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) {
                  if (!_isManualPan) setState(() => _isManualPan = true);
                  _autoRecenterTimer?.cancel();
                  _autoRecenterTimer =
                      Timer(const Duration(seconds: 8), () {
                    if (mounted) setState(() => _isManualPan = false);
                  });
                },
                child: MapWidget(
                  key: ValueKey('active_ride_map_${widget.rideId}'),
                  onMapCreated: _onMapCreated,
                  cameraOptions: CameraOptions(
                    center: initialCenter,
                    zoom: 14,
                  ),
                  styleUri: AppDrawer.lowDataMode
                      ? MapboxStyles.LIGHT
                      : (isDark
                          ? MapboxStyles.DARK
                          : MapboxStyles.MAPBOX_STREETS),
                ),
              ),
              if (_isManualPan)
                Positioned(
                  top: 8,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'active_ride_recenter',
                    backgroundColor: Colors.white,
                    onPressed: () {
                      setState(() => _isManualPan = false);
                      final p = _driverPointNotifier.value;
                      if (p != null && _mapboxMap != null) {
                        final h = _driverHeadingDeg;
                        final b = (h != null && !h.isNaN) ? -h : 0.0;
                        unawaited(_mapboxMap!.easeTo(
                          CameraOptions(
                            center: p,
                            zoom: 16,
                            bearing: b,
                            pitch: 48,
                          ),
                          MapAnimationOptions(duration: 800),
                        ));
                      } else {
                        _fitRouteInView();
                      }
                    },
                    child:
                        const Icon(Icons.my_location, color: Colors.black87),
                  ),
                ),
              _buildCaption(_routeLoadFailed
                  ? 'Traseu orientativ. Șofer urmărit live.'
                  : 'Traseu Mapbox. Șofer urmărit live.'),
              DraggableScrollableSheet(
                initialChildSize: 0.32,
                minChildSize: 0.2,
                maxChildSize: 0.62,
                builder: (ctx2, sc) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _rideStatusLabel(ride.status),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isD && ride.status == 'accepted')
                              ElevatedButton(
                                onPressed: () => unawaited(_handleDriverArrived(ride)),
                                child: const Text('Am ajuns la pickup'),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: sc,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            const SizedBox(height: 8),
                            _buildNavigationActions(ride),
                            if (ride.status == 'arrived') ...[
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  isD
                                      ? 'După ce alegi Maps sau Waze, revii la harta Nabour.'
                                      : 'Șoferul a ajuns la pickup — deschide navigația spre destinația finală.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCaption(String text) {
    return Positioned(
      left: 12,
      right: 12,
      top: 8,
      child: Material(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ),
    );
  }

  Widget _buildNavigationActions(Ride ride) {
    final hasPickup =
        ride.startLatitude != null && ride.startLongitude != null;
    final dLat = ride.destinationLatitude;
    final dLng = ride.destinationLongitude;

    if (ride.status == 'accepted' && hasPickup) {
      final lat = ride.startLatitude!;
      final lng = ride.startLongitude!;
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () {
            unawaited(
              ExternalMapsLauncher.showNavigationChooser(
                context,
                lat,
                lng,
                title: 'Navigare spre pickup',
                hint: 'Google Maps sau Waze (fără navigare în Nabour).',
              ),
            );
          },
          icon: const Icon(Icons.place_outlined),
          label: const Text('Pickup: Maps / Waze'),
        ),
      );
    }

    if (ride.status == 'arrived' && dLat != null && dLng != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () {
            unawaited(
              ExternalMapsLauncher.showNavigationChooser(
                context,
                dLat,
                dLng,
                title: 'Destinație finală',
                hint: 'Google Maps sau Waze (fără navigare în Nabour).',
              ),
            );
          },
          icon: const Icon(Icons.flag_rounded),
          label: const Text('Destinație: Maps / Waze'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _rideStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Șofer în drum spre tine';
      case 'arrived':
        return 'Șofer a ajuns';
      case 'in_progress':
        return 'Cursă în desfășurare';
      case 'completed':
        return 'Cursă finalizată';
      default:
        return status;
    }
  }
}
