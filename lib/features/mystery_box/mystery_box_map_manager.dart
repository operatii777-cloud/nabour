import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/features/activity_feed/activity_feed_writer.dart';
import 'package:nabour_app/features/mystery_box/mystery_box_marker_painter.dart';
import 'package:nabour_app/features/mystery_box/mystery_box_service.dart';
import 'package:nabour_app/models/business_offer_model.dart';
import 'package:nabour_app/services/business_service.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/utils/mapbox_utils.dart';
import 'package:geolocator/geolocator.dart' as geolocator;

class MysteryBoxMapManager {
  /// Trebuie să coincidă cu id-ul stratului Mapbox; mutăm stratul în top ca tap-ul
  /// să nu fie interceptat de markerele create ulterior (vecini, emoji).
  static const String _kAnnotationLayerId = 'mystery-box-layer';

  final MapboxMap mapboxMap;
  final BuildContext context;
  /// Poziția deja folosită de hartă (stream GPS / Mapbox) — evită eșecul lui
  /// [getCurrentPosition] când serviciul e lent dar aplicația știe deja locul.
  final ({double lat, double lng})? Function()? getUserLatLng;

  PointAnnotationManager? _annotationManager;
  final BusinessService _businessService = BusinessService();
  final MysteryBoxService _mysteryBoxService = MysteryBoxService();

  final Map<String, BusinessOffer> _activeOffers = {};
  final Map<String, PointAnnotation> _annotations = {};
  final Map<String, BusinessOffer> _annotationIdToOffer = {};

  bool _isInitialized = false;
  Uint8List? _boxIconData;
  DateTime? _lastUpdate;

  MysteryBoxMapManager({
    required this.mapboxMap,
    required this.context,
    this.getUserLatLng,
  });

  Future<void> initialize() async {
    if (_isInitialized) return;

    _annotationManager = await mapboxMap.annotations
        .createPointAnnotationManager(id: _kAnnotationLayerId);
    _boxIconData = await MysteryBoxMarkerPainter.generateBoxIcon();

    _annotationManager?.tapEvents(onTap: _handleAnnotationTap);

    _isInitialized = true;
    await _bringMysteryBoxLayerToFront();
    Logger.info('MysteryBoxMapManager initialized', tag: 'MYSTERY_BOX');
  }

  Future<void> _bringMysteryBoxLayerToFront() async {
    try {
      await mapboxMap.style.moveStyleLayer(_kAnnotationLayerId, null);
    } catch (e) {
      Logger.debug('Mystery box layer moveStyleLayer: $e', tag: 'MYSTERY_BOX');
    }
  }

  Future<void> updateMysteryBoxes(double lat, double lng,
      {bool force = false}) async {
    if (!_isInitialized) await initialize();

    final now = DateTime.now();
    if (!force &&
        _lastUpdate != null &&
        now.difference(_lastUpdate!) < const Duration(minutes: 2)) {
      return;
    }
    _lastUpdate = now;

    try {
      final offers = await _businessService.getNearbyOffers(
        userLat: lat,
        userLng: lng,
        radiusKm: 2.0,
      );

      final List<BusinessOffer> validOffers = [];
      for (final offer in offers) {
        if (offer.mysteryBoxExhausted) continue;
        final isOpened =
            await _mysteryBoxService.isBoxOpenedToday(offer.businessId);
        if (!isOpened) {
          validOffers.add(offer);
        }
      }

      await _syncAnnotations(validOffers);
      await _bringMysteryBoxLayerToFront();
    } catch (e) {
      Logger.error('Error updating mystery boxes: $e', tag: 'MYSTERY_BOX');
    }
  }

  static String _markerLabel(BusinessOffer offer) {
    final rem = offer.mysteryBoxRemaining;
    final tot = offer.mysteryBoxTotal;
    if (rem != null && tot != null && tot > 0) {
      return '$rem / $tot';
    }
    return 'Mystery Box!';
  }

  Future<void> _syncAnnotations(List<BusinessOffer> currentOffers) async {
    final manager = _annotationManager;
    if (manager == null || _boxIconData == null) return;

    final currentIds = currentOffers.map((o) => o.id).toSet();
    final existingIds = _annotations.keys.toSet();

    final toRemove = existingIds.difference(currentIds);
    for (final id in toRemove) {
      final anno = _annotations.remove(id);
      if (anno != null) {
        _annotationIdToOffer.remove(anno.id);
        try {
          await manager.delete(anno);
        } catch (_) {}
      }
      _activeOffers.remove(id);
    }

    final toUpdate = currentIds.intersection(existingIds);
    for (final id in toUpdate) {
      final offer = currentOffers.firstWhere((o) => o.id == id);
      final anno = _annotations[id];
      if (anno != null) {
        final label = _markerLabel(offer);
        try {
          anno.textField = label;
          anno.textSize = 14;
          anno.textColor = Colors.purple.toARGB32();
          anno.textOffset = [0, 2.85];
          await manager.update(anno);
        } catch (e) {
          Logger.debug('Mystery box annotation update: $e', tag: 'MYSTERY_BOX');
        }
      }
      _activeOffers[id] = offer;
      if (anno != null) {
        _annotationIdToOffer[anno.id] = offer;
      }
    }

    final toAdd = currentIds.difference(existingIds);
    for (final id in toAdd) {
      final offer = currentOffers.firstWhere((o) => o.id == id);
      final label = _markerLabel(offer);

      final options = PointAnnotationOptions(
        geometry: MapboxUtils.createPoint(
            offer.businessLatitude, offer.businessLongitude),
        image: _boxIconData,
        iconSize: 1.12,
        symbolSortKey: 1e6,
        textField: label,
        textSize: 14,
        textColor: Colors.purple.toARGB32(),
        textOffset: [0, 2.85],
      );

      final anno = await manager.create(options);
      _annotations[id] = anno;
      _activeOffers[id] = offer;
      _annotationIdToOffer[anno.id] = offer;
    }
  }

  /// Lanț: poziția din app → ultima poziție cunoscută → fix GPS (fără timeLimit prea scurt).
  Future<({double lat, double lng})?> _resolveUserLatLng() async {
    final fromMap = getUserLatLng?.call();
    if (fromMap != null) {
      Logger.debug(
        'Mystery box: using map-tracked position (${fromMap.lat}, ${fromMap.lng})',
        tag: 'MYSTERY_BOX',
      );
      return fromMap;
    }

    try {
      for (final forceLm in [false, true]) {
        final last = await geolocator.Geolocator.getLastKnownPosition(
          forceAndroidLocationManager: forceLm,
        );
        if (last != null) {
          Logger.debug(
            'Mystery box: getLastKnownPosition (forceLm=$forceLm)',
            tag: 'MYSTERY_BOX',
          );
          return (lat: last.latitude, lng: last.longitude);
        }
      }
    } catch (e) {
      Logger.debug('Mystery box getLastKnownPosition: $e', tag: 'MYSTERY_BOX');
    }

    var perm = await geolocator.Geolocator.checkPermission();
    if (perm == geolocator.LocationPermission.denied) {
      perm = await geolocator.Geolocator.requestPermission();
    }
    if (perm == geolocator.LocationPermission.denied ||
        perm == geolocator.LocationPermission.deniedForever) {
      return null;
    }

    final serviceOn = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      return null;
    }

    /// Pe Android, FusedLocation poate depăși 12s fără un timeLimit explicit în Dart;
    /// păstrăm 45s și încercăm și LocationManager ca rezervă.
    const fallbackTimeout = Duration(seconds: 45);

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final p = await geolocator.Geolocator.getCurrentPosition(
          locationSettings: geolocator.AndroidSettings(
            accuracy: geolocator.LocationAccuracy.low,
            timeLimit: fallbackTimeout,
            forceLocationManager: false,
          ),
        );
        return (lat: p.latitude, lng: p.longitude);
      }
      final p = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.low,
          timeLimit: fallbackTimeout,
          distanceFilter: 0,
        ),
      );
      return (lat: p.latitude, lng: p.longitude);
    } catch (e) {
      Logger.warning('Mystery box getCurrentPosition(low): $e', tag: 'MYSTERY_BOX');
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final p = await geolocator.Geolocator.getCurrentPosition(
          locationSettings: geolocator.AndroidSettings(
            accuracy: geolocator.LocationAccuracy.medium,
            timeLimit: fallbackTimeout,
            forceLocationManager: true,
          ),
        );
        return (lat: p.latitude, lng: p.longitude);
      }
      final p = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.medium,
          timeLimit: fallbackTimeout,
        ),
      );
      return (lat: p.latitude, lng: p.longitude);
    } catch (e) {
      Logger.error('Mystery box getCurrentPosition(fallback): $e',
          error: e, tag: 'MYSTERY_BOX');
      return null;
    }
  }

  Future<void> _handleAnnotationTap(PointAnnotation annotation) async {
    final offer = _annotationIdToOffer[annotation.id];
    if (offer == null) return;

    final userLL = await _resolveUserLatLng();
    if (userLL == null) {
      final perm = await geolocator.Geolocator.checkPermission();
      final deniedForever =
          perm == geolocator.LocationPermission.deniedForever;
      final denied = perm == geolocator.LocationPermission.denied;
      final serviceOn = await geolocator.Geolocator.isLocationServiceEnabled();
      String msg;
      if (!serviceOn) {
        msg = 'Locația este oprită la nivel de sistem. Pornește GPS-ul / Locația și încearcă din nou.';
      } else if (deniedForever) {
        msg = 'Nabour nu are permisiune de locație. Activează-o din Setări aplicație și încearcă din nou.';
      } else if (denied) {
        msg = 'Permisiunea de locație a fost refuzată. Acceptă accesul la locație pentru Nabour.';
      } else {
        msg = 'Nu am putut obține poziția curentă. Așteaptă ca punctul tău albastru să apară pe hartă, apoi apasă din nou pe cutie.';
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    final dist = geolocator.Geolocator.distanceBetween(
      userLL.lat,
      userLL.lng,
      offer.businessLatitude,
      offer.businessLongitude,
    );

    if (dist <= 100) {
      unawaited(ActivityFeedWriter.mysteryBoxNearby(
        offer.businessName,
        lat: userLL.lat,
        lng: userLL.lng,
      ));
      MysteryBoxClaimResult claimResult = MysteryBoxClaimResult.failure;
      try {
        claimResult = await _mysteryBoxService.openBox(offer);
      } on FirebaseFunctionsException catch (e) {
        if (!context.mounted) return;
        final msg = switch (e.code) {
          'resource-exhausted' =>
            'Toate cutiile acestei oferte au fost deja deschise.',
          'failed-precondition' =>
            e.message ?? 'Oferta nu mai e disponibilă.',
          _ => e.message ??
              'Nu s-a putut deschide cutia. Încearcă din nou.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.orange,
          ),
        );
        unawaited(updateMysteryBoxes(userLL.lat, userLL.lng, force: true));
        return;
      }
      if (claimResult.success && context.mounted) {
        unawaited(ActivityFeedWriter.mysteryBoxOpened(
          offer.businessName,
          lat: offer.businessLatitude,
          lng: offer.businessLongitude,
        ));
        _showSuccessDialog(
          offer,
          redemptionCode: claimResult.redemptionCode,
        );
        unawaited(updateMysteryBoxes(userLL.lat, userLL.lng, force: true));
      } else if (context.mounted) {
        final msg = claimResult.alreadyOpenedToday
            ? 'Ai deschis deja o cutie azi la acest magazin.'
            : 'Cutia nu s-a putut deschide. Poate a apărut o problemă de rețea.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.orange),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ești prea departe! Apropie-te la ${dist.round()}m de ${offer.businessName} ca să deschizi cutia.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(
    BusinessOffer offer, {
    String? redemptionCode,
  }) {
    if (!context.mounted) return;
    final code = redemptionCode?.trim();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                '🎉 Felicitări!',
                style: TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              tooltip: 'Închide',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'Ai deschis Mystery Box de la ${offer.businessName}!',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ai primit 50 Tokeni Nabour!',
                style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(
                offer.title,
                style: const TextStyle(
                    color: Colors.white70, fontStyle: FontStyle.italic),
              ),
              if (code != null && code.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Cod pentru reducere la magazin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Arată codul sau QR-ul personalului. Valabil 7 zile, o singură folosire.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  code,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: code,
                    size: 160,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1E1B4B),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Cod copiat în clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, color: Colors.amber),
                  label: const Text(
                    'Copiază codul',
                    style: TextStyle(color: Colors.amber),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('SUPER!', style: TextStyle(color: Colors.amber)),
          )
        ],
      ),
    );
  }

  void dispose() {
    _annotationIdToOffer.clear();
    _annotationManager?.deleteAll();
    _isInitialized = false;
  }
}
