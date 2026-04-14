import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_device_telemetry.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_place_detector.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_saved_places_cache.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_stationary_tracker.dart';
import 'package:nabour_app/features/fuzzy_location/fuzzy_location_snapper.dart';
import 'package:nabour_app/features/explorari/explorari_service.dart';
import 'package:nabour_app/features/smart_places/smart_places_db.dart';
import 'package:nabour_app/services/ghost_mode_service.dart';
import 'package:nabour_app/services/neighbor_location_service.dart';

/// Publică vizibilitatea pe hartă cu telemetrie (viteză, heading, baterie), fără a umfla [map_screen.dart].
Future<void> publishNeighborMapVisibility({
  required geolocator.Position position,
  required String avatar,
  required String displayName,
  bool isDriver = false,
  String? licensePlate,
  String? photoURL,
  bool isPulsing = false,
  List<String> allowedUids = const [],
  bool forceNeighborTelemetry = false,
  String? carAvatarId,
}) async {
  await GhostModeService.instance.ensureLoaded();
  if (GhostModeService.instance.isBlocking) return;

  await NeighborSavedPlacesCache.instance.ensureSubscribed();

  // Record GPS sample for smart-places learning (fire-and-forget)
  unawaited(SmartPlacesDb.instance.recordSample(
    position.latitude,
    position.longitude,
    speed: position.speed,
  ));

  // Detect place kind: first try saved addresses, then learned places
  String? placeKind = NeighborPlaceDetector.detectKind(
    position.latitude,
    position.longitude,
    NeighborSavedPlacesCache.instance.latest,
  );
  placeKind ??=
      await SmartPlacesDb.instance.detectCurrentPlaceKind(
    position.latitude,
    position.longitude,
  );

  final stationarySince = NeighborStationaryTracker.instance.touch(position);

  // Fuzzy location: snap to grid if enabled
  double pubLat = position.latitude;
  double pubLng = position.longitude;
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('fuzzy_location') ?? false) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final snapped =
        FuzzyLocationSnapper.snapWithJitter(pubLat, pubLng, uid);
    pubLat = snapped.lat;
    pubLng = snapped.lng;
  }

  unawaited(ExplorariService.instance.recordVisit(pubLat, pubLng));

  final bat = await NeighborDeviceTelemetryReader.instance.snapshot();
  await NeighborLocationService().publishLocation(
    lat: pubLat,
    lng: pubLng,
    avatar: avatar,
    displayName: displayName,
    isDriver: isDriver,
    licensePlate: licensePlate,
    photoURL: photoURL,
    isPulsing: isPulsing,
    allowedUids: allowedUids,
    heading: position.heading,
    speed: position.speed,
    battery: bat?.level,
    charging: bat?.isCharging ?? false,
    placeKind: placeKind,
    stationarySince: stationarySince,
    forceNeighborTelemetry: forceNeighborTelemetry,
    carAvatarId: carAvatarId,
  );
}

/// Varianta fire-and-forget pentru apeluri din timer / stream.
void publishNeighborMapVisibilityUnawaited({
  required geolocator.Position position,
  required String avatar,
  required String displayName,
  bool isDriver = false,
  String? licensePlate,
  String? photoURL,
  bool isPulsing = false,
  List<String> allowedUids = const [],
  bool forceNeighborTelemetry = false,
  String? carAvatarId,
}) {
  unawaited(
    publishNeighborMapVisibility(
      position: position,
      avatar: avatar,
      displayName: displayName,
      isDriver: isDriver,
      licensePlate: licensePlate,
      photoURL: photoURL,
      isPulsing: isPulsing,
      allowedUids: allowedUids,
      forceNeighborTelemetry: forceNeighborTelemetry,
      carAvatarId: carAvatarId,
    ),
  );
}
