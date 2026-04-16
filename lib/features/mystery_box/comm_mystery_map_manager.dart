import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/features/mystery_box/comm_mystery_box_service.dart';
import 'package:nabour_app/features/mystery_box/mystery_box_marker_painter.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/utils/mapbox_utils.dart';

/// Cutii comunitare pe hartă (layer separat de cele business).
class CommunityMysteryBoxMapManager {
  static const String _layerId = 'community-mystery-layer';

  final MapboxMap mapboxMap;
  final BuildContext context;
  final ({double lat, double lng})? Function()? getUserLatLng;

  static const double _kBaseIconSize = 0.735;

  PointAnnotationManager? _mgr;
  final CommunityMysteryBoxService _svc = CommunityMysteryBoxService.instance;

  final Map<String, CommunityMysteryBoxPin> _pins = {};
  final Map<String, PointAnnotation> _ann = {};

  bool _ready = false;
  Uint8List? _icon;
  DateTime? _lastFetch;

  /// Aplică scalare bazată pe zoom — aceeași logică ca avatarele vecinilor.
  Future<void> applyZoomScale(double factor) async {
    final mgr = _mgr;
    if (mgr == null) return;
    final targetSize = _kBaseIconSize * factor;
    for (final ann in _ann.values) {
      if ((ann.iconSize ?? _kBaseIconSize) == targetSize) continue;
      ann.iconSize = targetSize;
      try {
        await mgr.update(ann);
      } catch (_) {}
    }
  }

  CommunityMysteryBoxMapManager({
    required this.mapboxMap,
    required this.context,
    this.getUserLatLng,
  });

  Future<void> initialize() async {
    if (_ready) return;
    _mgr = await mapboxMap.annotations.createPointAnnotationManager(id: _layerId);
    _icon = await MysteryBoxMarkerPainter.generateCommunityBoxIcon();
    _mgr?.tapEvents(onTap: _onTap);
    _ready = true;
    await _moveLayerFront();
    Logger.info('CommunityMysteryMapManager ready', tag: 'COMM_MB');
  }

  Future<void> _moveLayerFront() async {
    try {
      await mapboxMap.style.moveStyleLayer(_layerId, null);
    } catch (e) {
      Logger.debug('community layer move: $e', tag: 'COMM_MB');
    }
  }

  Future<void> updateBoxes(double lat, double lng, {bool force = false}) async {
    if (!_ready) await initialize();
    final now = DateTime.now();
    if (!force &&
        _lastFetch != null &&
        now.difference(_lastFetch!) < const Duration(minutes: 2)) {
      return;
    }
    _lastFetch = now;
    try {
      final list = await _svc.fetchNearby(lat: lat, lng: lng, radiusKm: 6);
      // Afișăm și cutiile plasate de utilizator (serverul blochează claim-ul propriu).
      await _sync(list);
      await _moveLayerFront();
    } catch (e) {
      Logger.error('community update: $e', tag: 'COMM_MB');
    }
  }

  Future<void> _sync(List<CommunityMysteryBoxPin> list) async {
    final m = _mgr;
    if (m == null || _icon == null) return;
    final ids = list.map((e) => e.id).toSet();
    final old = _ann.keys.toSet();

    for (final id in old.difference(ids)) {
      final a = _ann.remove(id);
      if (a != null) {
        try {
          await m.delete(a);
        } catch (e) {
          Logger.debug('CommMysteryMapManager: annotation delete failed: $e', tag: 'MYSTERY_BOX');
        }
      }
      _pins.remove(id);
    }

    final same = ids.intersection(old);
    for (final id in same) {
      _pins[id] = list.firstWhere((p) => p.id == id);
    }

    for (final id in ids.difference(old)) {
      final pin = list.firstWhere((p) => p.id == id);
      _pins[pin.id] = pin;
      final label = pin.message.trim().isEmpty ? 'Cutie!' : pin.message;
      final opts = PointAnnotationOptions(
        geometry: MapboxUtils.createPoint(pin.latitude, pin.longitude),
        image: _icon,
        iconSize: 0.735,
        symbolSortKey: 1e6 - 1,
        textField: label.length > 22 ? '${label.substring(0, 20)}…' : label,
        textSize: 12,
        textColor: const Color(0xFF0D9488).toARGB32(),
        textOffset: [0, 2.7],
      );
      final a = await m.create(opts);
      _ann[pin.id] = a;
    }
  }

  Future<({double lat, double lng})?> _userLl() async {
    final fromMap = getUserLatLng?.call();
    if (fromMap != null) return fromMap;
    try {
      final p = await geolocator.Geolocator.getLastKnownPosition();
      if (p != null) return (lat: p.latitude, lng: p.longitude);
    } catch (e) {
      Logger.debug('CommMysteryMapManager._userLl getLastKnownPosition failed: $e', tag: 'MYSTERY_BOX');
    }
    final perm = await geolocator.Geolocator.checkPermission();
    if (perm == geolocator.LocationPermission.denied) {
      await geolocator.Geolocator.requestPermission();
    }
    try {
      final p = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.low,
        ),
      );
      return (lat: p.latitude, lng: p.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onTap(PointAnnotation a) async {
    String? pinId;
    for (final e in _ann.entries) {
      if (e.value.id == a.id) pinId = e.key;
    }
    if (pinId == null) return;
    final pin = _pins[pinId];
    if (pin == null) return;

    final curUid = FirebaseAuth.instance.currentUser?.uid;
    if (curUid != null && pin.placerUid == curUid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aceasta este cutia ta pe hartă. Alți utilizatori o pot deschide când sunt aproape.',
            ),
          ),
        );
      }
      return;
    }

    final user = await _userLl();
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nu am poziția ta — activează GPS.')),
        );
      }
      return;
    }

    final dist = geolocator.Geolocator.distanceBetween(
      user.lat,
      user.lng,
      pin.latitude,
      pin.longitude,
    );

    if (dist > 100) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ești la ${dist.round()} m. Apropie-te sub 100 m pentru a deschide.',
            ),
          ),
        );
      }
      return;
    }

    // După tap pe stratul Mapbox, amânăm dialogul ca să nu rămână bariera fără focus.
    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Cutie comunitară'),
        content: Text(
          pin.message.trim().isEmpty
              ? 'Deschizi cutia și primești ${pin.rewardTokens} tokeni Nabour?'
              : '${pin.message}\n\nPrimești ${pin.rewardTokens} tokeni.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Renunț')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Deschide')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      final reward = await _svc.claim(
        boxId: pin.id,
        claimLat: user.lat,
        claimLng: user.lng,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Felicitări! +$reward tokeni. Plasatorul a fost notificat.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      await updateBoxes(user.lat, user.lng, force: true);
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Nu s-a putut deschide.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare: $e')),
      );
    }
  }

  void dispose() {
    _mgr?.deleteAll();
    _ready = false;
  }
}
