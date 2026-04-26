import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Source;

import '../utils/deprecated_apis_fix.dart';
import 'package:nabour_app/models/chat_message_model.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/models/saved_address_model.dart';
import 'package:nabour_app/models/neighborhood_request_model.dart';
import 'package:nabour_app/models/stop_location.dart';
import 'package:nabour_app/models/support_ticket_model.dart';
import 'package:nabour_app/models/voice_models.dart';
import 'package:nabour_app/models/radar_alert_model.dart';
// (PricingService import removed - rides now cost 0.0 except for 1 token)
import 'package:nabour_app/services/active_ride_telem_rtdb.dart';
import 'package:nabour_app/services/contacts_service.dart';
import 'package:nabour_app/services/pax_allowed_drv_uids.dart';
import 'package:nabour_app/services/pax_drv_search_config.dart';
import 'package:nabour_app/services/ghost_mode_service.dart';
import 'package:nabour_app/services/push_notification_service.dart';
import 'package:nabour_app/services/routing_service.dart';
import 'package:nabour_app/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/utils/logger.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_model.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_service.dart';
import 'package:nabour_app/services/location_cache_service.dart';

enum DateFilter { all, today, lastWeek, lastMonth, last3Months, thisYear }

enum UserRole { passenger, driver }

/// ✅ NOU: Excepție specială pentru cursa activă (pentru dialog de confirmare)
class ActiveRideException implements Exception {
  final String activeRideId;
  final String activeRideStatus;
  final String message;
  
  ActiveRideException({
    required this.activeRideId,
    required this.activeRideStatus,
    required this.message,
  });
  
  @override
  String toString() => message;
}

class DriverEtaResult {
  final String driverId;
  final int durationInMinutes;
  final double distanceInKm;

  const DriverEtaResult({
    required this.driverId,
    required this.durationInMinutes,
    required this.distanceInKm,
  });
}

/// Câmp pe `driver_locations`: când e `false`, pasagerul nu desenează avatarul pe hartă
/// (șoferul poate rămâne în fluxul de curse / ETA).
const String kDriverLocationShowOnPassengerLiveMap = 'showOnPassengerLiveMap';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Lazy getters — accessed only after Firebase.initializeApp() has completed
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseFirestore get instance => _db; // ✅ NOU: Acces direct la instanță
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;
  final RoutingService _routingService = RoutingService();
  // (PricingService field removed)

  // PERFORMANCE CACHE
  final Map<String, dynamic> _cache = {};
  final Map<String, Timer> _cacheTimers = {};
  final Map<String, DateTime> _lastLocationUpdate = {};
  
  // DEBOUNCING
  Timer? _locationDebouncer;
  Timer? _rideSearchDebouncer;
  geolocator.Position? _lastKnownPosition;
  
  // BATCH OPERATIONS
  final List<Map<String, dynamic>> _pendingUpdates = [];
  Timer? _batchTimer;
  
  // ✅ NOU: Timer pentru resetare automată a curselor blocate
  Timer? _stuckRideCleanupTimer;
  static const int _stuckRideThresholdMinutes = 10; // 10 minute pentru curse blocate
  
  // UID caching to reduce repeated logs/calls
  String? _cachedUid;
  DateTime? _cachedUidAt;
  String? _cachedDriverCarAvatarIdForLocation;
  DateTime? _cachedDriverCarAvatarIdAt;

  String? get _uid {
    final now = DateTime.now();
    if (_cachedUid != null && _cachedUidAt != null && now.difference(_cachedUidAt!).inSeconds < 30) {
      return _cachedUid;
    }
    final uid = _auth.currentUser?.uid;
    _cachedUid = uid;
    _cachedUidAt = now;
    Logger.debug('Getting UID: $uid', tag: 'AUTH');
    Logger.debug('Current user: ${_auth.currentUser?.email}', tag: 'AUTH');
    Logger.debug('Auth state: ${_auth.currentUser != null}', tag: 'AUTH');
    return uid;
  }

  /// `true` dacă șoferul a ales vizibilitatea socială și nu e în modul fantomă.
  /// Cursă activă forțează afișarea pe hartă pentru telemetrie/preluare.
  Future<bool> _driverShouldShowOnPassengerLiveMap() async {
    await GhostModeService.instance.ensureLoaded();
    if (GhostModeService.instance.isBlocking) return false;
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool('social_map_visible') ?? false;
    } catch (_) {
      return false;
    }
  }

  // GEOHASHING CONSTANTS
  static const double _earthRadius = 6371000; // meters
  static const int _geohashPrecision = 6; // ~1.2km radius
  static const Duration _driverAvatarLocationCacheTtl = Duration(minutes: 5);

  Future<String> _resolveDriverCarAvatarIdForLocationWrite({
    bool forceRefresh = false,
  }) async {
    final uid = _uid;
    if (uid == null) return 'default_car';
    final now = DateTime.now();
    final cached = _cachedDriverCarAvatarIdForLocation;
    final cachedAt = _cachedDriverCarAvatarIdAt;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        now.difference(cachedAt) <= _driverAvatarLocationCacheTtl) {
      return cached;
    }
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final raw = CarAvatarService.resolveSlotId(
        doc.data(),
        CarAvatarMapSlot.driver,
      );
      final id = CarAvatarService.coerceDriverAvatarIdForMap(raw);
      _cachedDriverCarAvatarIdForLocation = id;
      _cachedDriverCarAvatarIdAt = now;
      return id;
    } catch (e) {
      Logger.warning('Driver avatar resolve for location write failed: $e', tag: 'FIRESTORE');
      return cached ?? 'default_car';
    }
  }

  /// Actualizează imediat flag-ul de afișare pe harta pasagerului (fără debounce la locație).
  Future<void> mergeDriverPassengerLiveMapVisibilityForCurrentUser(bool show) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final ref = _db.collection('driver_locations').doc(uid);
      final snap = await ref.get();
      if (!snap.exists) return;
      await ref.set(
        {kDriverLocationShowOnPassengerLiveMap: show},
        SetOptions(merge: true),
      );
    } catch (e) {
      Logger.warning('mergeDriverPassengerLiveMapVisibility: $e', tag: 'FIRESTORE');
    }
  }

  /// Re-sincronizează imediat `carAvatarId` din `driver_locations` după schimbări de avatar.
  Future<void> refreshDriverLocationAvatarNow() async {
    final uid = _uid;
    if (uid == null) return;
    if (!await _driverShouldShowOnPassengerLiveMap()) return;
    try {
      final id = await _resolveDriverCarAvatarIdForLocationWrite(forceRefresh: true);
      await _db.collection('driver_locations').doc(uid).set(
        <String, dynamic>{
          'carAvatarId': id,
          'lastUpdate': Timestamp.now(),
          'isOnline': true,
          kDriverLocationShowOnPassengerLiveMap: true,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      Logger.warning('refreshDriverLocationAvatarNow failed: $e', tag: 'FIRESTORE');
    }
  }
  
  // OPTIMIZED CACHE METHODS
  T? _getCached<T>(String key) {
    final cached = _cache[key];
    return cached is T ? cached : null;
  }

  void _setCached<T>(String key, T value, {Duration? ttl}) {
    _cache[key] = value;
    
    if (ttl != null) {
      _cacheTimers[key]?.cancel();
      _cacheTimers[key] = Timer(ttl, () {
        _cache.remove(key);
        _cacheTimers.remove(key);
      });
    }
  }

  // GEOHASHING METHODS
  String _encodeGeohash(double lat, double lng) {
    const String base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    const int bits = 5;
    
    double minLat = -90.0;
    double maxLat = 90.0;
    double minLng = -180.0;
    double maxLng = 180.0;
    
    String geohash = '';
    int bit = 0;
    int ch = 0;
    
    while (geohash.length < _geohashPrecision) {
      if (bit % 2 == 0) {
        final double mid = (minLng + maxLng) / 2;
        if (lng >= mid) {
          ch |= (1 << (4 - bit % bits));
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final double mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          ch |= (1 << (4 - bit % bits));
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }
      
      bit++;
      if (bit % bits == 0) {
        geohash += base32[ch];
        ch = 0;
      }
    }
    
    return geohash;
  }
  
  List<String> _getNearbyGeohashes(double lat, double lng, double radiusKm) {
    final List<String> geohashes = [];
    final double radiusMeters = radiusKm * 1000;
    
    // Calculate the geohash for the center point
    final centerGeohash = _encodeGeohash(lat, lng);
    geohashes.add(centerGeohash);
    
    // Calculate nearby geohashes based on radius
    final double latDelta = radiusMeters / _earthRadius * (180 / math.pi);
    final double lngDelta = radiusMeters / (_earthRadius * math.cos(lat * math.pi / 180)) * (180 / math.pi);
    
    // Add geohashes for nearby areas
    for (double dLat = -latDelta; dLat <= latDelta; dLat += latDelta / 2) {
      for (double dLng = -lngDelta; dLng <= lngDelta; dLng += lngDelta / 2) {
        if (dLat == 0 && dLng == 0) continue;
        
        final nearbyLat = lat + dLat;
        final nearbyLng = lng + dLng;
        
        if (nearbyLat >= -90 && nearbyLat <= 90 && nearbyLng >= -180 && nearbyLng <= 180) {
          final nearbyGeohash = _encodeGeohash(nearbyLat, nearbyLng);
          if (!geohashes.contains(nearbyGeohash)) {
            geohashes.add(nearbyGeohash);
          }
        }
      }
    }
    
    return geohashes;
  }

  // OPTIMIZED GEOLOCATION WITH CACHING
  Future<geolocator.Position?> _getCachedPosition() async {
    final now = DateTime.now();
    final lastUpdate = _lastLocationUpdate[_uid ?? 'anonymous'];

    // 0. Prioritate: VerificÄƒm cache-ul global (AppInitializer / Map fix recent)
    final globalCache = LocationCacheService.instance.peekRecent(maxAge: const Duration(seconds: 45));
    if (globalCache != null) {
      _lastKnownPosition = globalCache;
      _lastLocationUpdate[_uid ?? 'anonymous'] = now;
      return globalCache;
    }

    // 1. Return cached position if less than 30 seconds old
    if (_lastKnownPosition != null && 
        lastUpdate != null && 
        now.difference(lastUpdate).inSeconds < 30) {
      return _lastKnownPosition;
    }

    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 3),
        ),
      );
      
      _lastKnownPosition = position;
      _lastLocationUpdate[_uid ?? 'anonymous'] = now;
      return position;
    } catch (e) {
      Logger.error('Location error', error: e, tag: 'FIRESTORE');
      return _lastKnownPosition; // Return last known if current fails
    }
  }

  // BATCH UPDATE SYSTEM
  void _addToBatch(String collection, String docId, Map<String, dynamic> data) {
    _pendingUpdates.add({
      'collection': collection,
      'docId': docId,
      'data': data,
      'timestamp': DateTime.now(),
    });

    _batchTimer?.cancel();
    // Execută batch-ul imediat pentru actualizări critice
    if (data.containsKey('status') && data['status'] == 'driver_found') {
      Logger.warning('Critical update detected - executing immediately', tag: 'BATCH');
      _processBatch();
    } else {
      _batchTimer = Timer(const Duration(milliseconds: 100), _processBatch);
    }
  }

  /// Anulează debounce-ul și scrie imediat — folosit înainte de tranzacții care citesc aceleași doc-uri în reguli (ex. rating).
  Future<void> _commitBatchNow() async {
    _batchTimer?.cancel();
    await _processBatch();
  }

  Future<void> _processBatch() async {
    if (_pendingUpdates.isEmpty) return;

    final batch = _db.batch();
    final updates = List.from(_pendingUpdates);
    _pendingUpdates.clear();

    try {
      for (final update in updates) {
        final ref = _db.collection(update['collection']).doc(update['docId']);
        batch.set(ref, update['data'], SetOptions(merge: true)); // Changed from update to set
      }
      
      await batch.commit();
      Logger.info('Batch processed: ${updates.length} updates', tag: 'BATCH');
    } catch (e) {
      Logger.error('Batch error', error: e, tag: 'BATCH');
      // Re-add failed updates
_pendingUpdates.addAll(updates.map((e) => e as Map<String, dynamic>));
    }
  }

  // HEAVILY OPTIMIZED RIDE SEARCH - PERFORMANCE IMPROVEMENTS
  /// Rules allow listing `ride_requests` only if status is `pending` or the user is
  /// passenger/driver. A single query on pending+driver_found returns docs the user
  /// cannot read → PERMISSION_DENIED. We merge two rule-safe queries instead.
  Stream<List<Ride>> getPendingRideRequests(RideCategory driverCategory) {
    if (_uid == null) return Stream.value([]);

    final uid = _uid!;
    final cats = _getVisibleCategories(driverCategory);
    final col = _db.collection('ride_requests');
    QuerySnapshot<Map<String, dynamic>>? snapPending;
    QuerySnapshot<Map<String, dynamic>>? snapDriverFound;
    Timer? debouncer;

    late final StreamSubscription subPending;
    late final StreamSubscription subAssigned;
    final controller = StreamController<List<Ride>>(
      onCancel: () {
        debouncer?.cancel();
        subPending.cancel();
        subAssigned.cancel();
      },
    );

    Future<void> runMergedProcess() async {
      debouncer?.cancel();
      debouncer = Timer(const Duration(milliseconds: 200), () async {
        final pendingDocs = snapPending?.docs ?? const [];
        final assignedDocs = snapDriverFound?.docs ?? const [];
        final merged = <QueryDocumentSnapshot<Map<String, dynamic>>>[
          ...pendingDocs,
          ...assignedDocs,
        ];
        try {
          final filteredRides = await _processRidesInBackgroundDocs(merged);
          if (!controller.isClosed) controller.add(filteredRides);
        } catch (e, st) {
          if (!controller.isClosed) controller.addError(e, st);
        }
      });
    }

    subPending = col
        .where('status', isEqualTo: 'pending')
        .where('category', whereIn: cats)
        .limit(50)
        .snapshots()
        .listen((s) {
          snapPending = s;
          unawaited(runMergedProcess());
        }, onError: controller.addError);

    subAssigned = col
        .where('status', isEqualTo: 'driver_found')
        .where('driverId', isEqualTo: uid)
        .where('category', whereIn: cats)
        .limit(50)
        .snapshots()
        .listen((s) {
          snapDriverFound = s;
          unawaited(runMergedProcess());
        }, onError: controller.addError);

    return controller.stream;
  }

  List<String> _getVisibleCategories(RideCategory driverCategory) {
    switch (driverCategory) {
      case RideCategory.best:
        return ['best', 'family', 'energy', 'standard', 'any'];
      case RideCategory.energy:
        return ['energy', 'standard', 'any'];
      case RideCategory.family:
        return ['family', 'standard', 'any'];
      case RideCategory.standard:
        return ['standard', 'any'];
      case RideCategory.utility:
        return ['utility', 'any'];
      case RideCategory.any:
        return ['standard', 'any'];
    }
  }

  // BACKGROUND PROCESSING FOR RIDES
  Future<List<Ride>> _processRidesInBackgroundDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final position = await _getCachedPosition();
    if (position == null) return [];

    final allRides = docs.map((doc) => Ride.fromFirestore(doc)).toList();
    final currentUid = _uid;
    
    // Filter in chunks to avoid blocking UI
    final nearbyRides = <Ride>[];
    const chunkSize = 10;
    
    for (int i = 0; i < allRides.length; i += chunkSize) {
      final chunk = allRides.skip(i).take(chunkSize);
      
      for (final ride in chunk) {
        bool isRelevant = false;
        if (ride.status == 'pending' && currentUid != null && !ride.declinedBy.contains(currentUid)) {
          // âœ… RE-INTĂRIT: Filtru contacte - arată cursa doar dacă suntem în lista de contacte (dacă e restricționată)
          if (ride.allowedDriverUids != null && !ride.allowedDriverUids!.contains(currentUid)) {
            isRelevant = false;
          } else {
            isRelevant = true;
          }
        } else if (ride.status == 'driver_found' && ride.driverId == currentUid) {
          isRelevant = true;
        }
        
        if (isRelevant && ride.startLatitude != null && ride.startLongitude != null) {
          final distance = geolocator.Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            ride.startLatitude!,
            ride.startLongitude!,
          ) / 1000;
          
          if (distance <= PassengerDriverSearchConfig.maxRadiusKm) {
            nearbyRides.add(ride);
          }
        }
      }
      
      // Yield control back to UI between chunks
      if (i + chunkSize < allRides.length) {
        await Future.delayed(const Duration(microseconds: 1));
      }
    }
    
    // Sort by distance (keep this fast)
    nearbyRides.sort((a, b) {
      final distanceA = geolocator.Geolocator.distanceBetween(
        position.latitude, position.longitude,
        a.startLatitude!, a.startLongitude!,
      );
      final distanceB = geolocator.Geolocator.distanceBetween(
        position.latitude, position.longitude,
        b.startLatitude!, b.startLongitude!,
      );
      return distanceA.compareTo(distanceB);
    });
    
    return nearbyRides;
  }

  // OPTIMIZED DRIVER ETA WITH GEOHASHING
  Future<DriverEtaResult?> getNearestDriverEta(Point passengerPickupPoint, RideCategory category) async {
    final cacheKey = 'driver_eta_${category.name}_${passengerPickupPoint.coordinates.lng}_${passengerPickupPoint.coordinates.lat}';
    
    // Return cached result if less than 2 minutes old
    final cached = _getCached<DriverEtaResult>(cacheKey);
    if (cached != null) return cached;

    Logger.debug('Starting geohash-based search for category: ${category.name}', tag: 'ETA');
    
    try {
      // Calculate geohashes for the passenger location with a 10km radius
      final nearbyGeohashes = _getNearbyGeohashes(
        passengerPickupPoint.coordinates.lat.toDouble(), 
        passengerPickupPoint.coordinates.lng.toDouble(), 
        10.0
      );
      
      Logger.debug('Searching in ${nearbyGeohashes.length} geohash areas', tag: 'ETA');
      
      // Query drivers only in the relevant geohash areas
      final driversSnapshot = await _queryDriversByGeohashes(nearbyGeohashes, category);
      
      if (driversSnapshot.isEmpty) {
        Logger.warning('No drivers found in geohash areas, expanding search', tag: 'ETA');
        
        // Fallback: search in a larger radius if no drivers found
        final expandedGeohashes = _getNearbyGeohashes(
          passengerPickupPoint.coordinates.lat.toDouble(), 
          passengerPickupPoint.coordinates.lng.toDouble(), 
          25.0
        );
        
        final expandedSnapshot = await _queryDriversByGeohashes(expandedGeohashes, category);
            
        if (expandedSnapshot.isEmpty) {
          Logger.warning('No drivers available in expanded area', tag: 'ETA');
          return null;
        }
        
        final compatibleDrivers = _filterCompatibleDrivers(expandedSnapshot, category);
        if (compatibleDrivers.isEmpty) {
          Logger.warning('No compatible drivers found in expanded area', tag: 'ETA');
          return null;
        }
        
        final result = await _findNearestDriver(compatibleDrivers, passengerPickupPoint);
        if (result != null) {
          _setCached(cacheKey, result, ttl: const Duration(minutes: 2));
        }
        return result;
      }

      final compatibleDrivers = _filterCompatibleDrivers(driversSnapshot, category);
      
      if (compatibleDrivers.isEmpty) {
        Logger.warning('No compatible drivers found in geohash areas', tag: 'ETA');
        return null;
      }

      Logger.info('Found ${compatibleDrivers.length} compatible drivers in geohash areas', tag: 'ETA');
      
      final result = await _findNearestDriver(compatibleDrivers, passengerPickupPoint);
      
      if (result != null) {
        _setCached(cacheKey, result, ttl: const Duration(minutes: 2));
      }
      
      return result;
    } catch (e) {
      Logger.critical('ETA calculation error', error: e, tag: 'ETA');
      return null;
    }
  }

  List<String> _getCompatibleCategories(RideCategory category) {
    switch (category) {
      case RideCategory.any:
        return ['standard', 'family', 'energy', 'best', 'utility'];
      case RideCategory.standard:
        return ['standard', 'family', 'energy', 'best'];
      case RideCategory.family:
        return ['family', 'energy', 'best'];
      case RideCategory.energy:
        return ['energy', 'best'];
      case RideCategory.best:
        return ['best'];
      case RideCategory.utility:
        return ['utility'];
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _queryDriversByGeohashes(
    List<String> geohashes,
    RideCategory category,
  ) async {
    if (geohashes.isEmpty) {
      return const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }

    final compatibleCategories = _getCompatibleCategories(category);
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents = [];

    const int maxWhereIn = 10;
    for (var i = 0; i < geohashes.length; i += maxWhereIn) {
      final chunk = geohashes.sublist(i, i + maxWhereIn > geohashes.length ? geohashes.length : i + maxWhereIn);
      if (chunk.isEmpty) continue;

      final snapshot = await _db
          .collection('driver_locations')
          .where('category', whereIn: compatibleCategories)
          .where('geohash', whereIn: chunk)
          .where('isOnline', isEqualTo: true)
          .get();
      documents.addAll(snapshot.docs);
    }

    return documents;
  }

  List<Map<String, dynamic>> _filterCompatibleDrivers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    RideCategory category,
  ) {
    final compatibleDrivers = <Map<String, dynamic>>[];
    
    for (final doc in docs) {
      final data = doc.data();
      final driverCategoryStr = data['category'] as String?;
      final driverPosition = data['position'] as GeoPoint?;
      
      if (driverPosition != null && _isDriverCategoryCompatible(category, driverCategoryStr)) {
        compatibleDrivers.add({
          'id': doc.id,
          'position': driverPosition,
        });
      }
    }
    
    return compatibleDrivers;
  }

  Future<DriverEtaResult?> _findNearestDriver(List<Map<String, dynamic>> drivers, Point passengerPoint) async {
    Map<String, dynamic>? nearestDriverData;
    double shortestDuration = double.infinity;

    // Process drivers in smaller batches to avoid blocking
    const batchSize = 5;
    for (int i = 0; i < drivers.length; i += batchSize) {
      final batch = drivers.skip(i).take(batchSize);
      
      for (final driverData in batch) {
        final driverId = driverData['id'];
        final driverPoint = Point(
          coordinates: Position(
            driverData['position'].longitude, 
            driverData['position'].latitude
          )
        );
        
        try {
          final route = await _routingService.getRoute([driverPoint, passengerPoint]);
          final durationInMinutes = _routingService.extractDuration(route) / 60;

          if (durationInMinutes < shortestDuration) {
            shortestDuration = durationInMinutes;
            nearestDriverData = driverData;
          }
        } catch (e) {
          Logger.error('Route calculation error for driver $driverId', error: e, tag: 'ETA');
          continue;
        }
      }
      
      // Yield control between batches
      if (i + batchSize < drivers.length) {
        await Future.delayed(const Duration(microseconds: 1));
      }
    }

    if (nearestDriverData != null) {
      final driverPoint = Point(
        coordinates: Position(
          nearestDriverData['position'].longitude, 
          nearestDriverData['position'].latitude
        )
      );
      final finalRoute = await _routingService.getRoute([driverPoint, passengerPoint]);
      final distance = _routingService.extractDistance(finalRoute) / 1000;
      final duration = _routingService.extractDuration(finalRoute) / 60;

      return DriverEtaResult(
        driverId: nearestDriverData['id'],
        durationInMinutes: duration.ceil(),
        distanceInKm: distance
      );
    }

    return null;
  }

  // OPTIMIZED DRIVER LOCATION UPDATE WITH GEOHASHING
  Future<void> updateDriverLocation(
    geolocator.Position position, {
    double? bearing,
    String? activeRideId,
    String? activeRidePassengerId,
  }) async {
    if (_uid == null) return;

    final hasActiveRide = activeRideId != null &&
        activeRideId.isNotEmpty &&
        activeRidePassengerId != null &&
        activeRidePassengerId.isNotEmpty;

    if (activeRideId != null &&
        activeRideId.isNotEmpty &&
        activeRidePassengerId != null &&
        activeRidePassengerId.isNotEmpty) {
      unawaited(_syncActiveRideDriverRtdb(
        position: position,
        bearing: bearing,
        rideId: activeRideId,
        passengerId: activeRidePassengerId,
      ));
    }

    // Throttling pentru costuri:
    // - dacă nu există cursă activă, coalesăm actualizările driver_locations la max ~1 dată/60s
    //   (în prezent erau mult mai dese și generau costuri prin scrieri/citiri).
    // - dacă există cursă activă păstrăm un interval mai scurt pentru UX/telemetrie.
    final debounce = hasActiveRide
        ? const Duration(seconds: 20)
        : const Duration(seconds: 60);

    _locationDebouncer?.cancel();
    _locationDebouncer = Timer(debounce, () async {
      // Calculate geohash for the new position
      final geohash = _encodeGeohash(position.latitude, position.longitude);
      final carAvatarId = await _resolveDriverCarAvatarIdForLocationWrite();
      final showOnPassengerLiveMap =
          hasActiveRide || await _driverShouldShowOnPassengerLiveMap();

      final updateData = <String, dynamic>{
        'position': GeoPoint(position.latitude, position.longitude),
        'geohash': geohash,
        'lastUpdate': Timestamp.now(),
        'isOnline': true,
        'carAvatarId': carAvatarId,
        kDriverLocationShowOnPassengerLiveMap: showOnPassengerLiveMap,
      };

      if (bearing != null && !bearing.isNaN) {
        updateData['bearing'] = bearing;
        Logger.debug('Saving bearing to Firestore: ${bearing.toStringAsFixed(1)}°', tag: 'FIRESTORE');
      }

      // Update driver_locations (for passenger map & geohash queries)
      _addToBatch('driver_locations', _uid!, updateData);

      // Also update drivers/{uid} with flat lat/lng for Cloud Function matching queries
      _addToBatch('drivers', _uid!, {
        'currentLatitude': position.latitude,
        'currentLongitude': position.longitude,
        'isOnline': true,
        'isAvailable': true,
        'lastLocationAt': Timestamp.now(),
      });
    });
  }

  Future<void> _syncActiveRideDriverRtdb({
    required geolocator.Position position,
    required String rideId,
    required String passengerId,
    double? bearing,
  }) async {
    if (_uid == null) return;
    try {
      await ActiveRideTelemetryRtdbService.instance.ensureRideMeta(
        rideId: rideId,
        driverId: _uid!,
        passengerId: passengerId,
      );
      await ActiveRideTelemetryRtdbService.instance.publishDriverLocation(
        rideId: rideId,
        lat: position.latitude,
        lng: position.longitude,
        heading: (bearing != null && !bearing.isNaN) ? bearing : null,
        speed: position.speed,
      );
    } catch (e) {
      Logger.warning('Active ride RTDB sync: $e', tag: 'FIRESTORE');
    }
  }

  // OPTIMIZED TRANSACTION FOR ADDING STOPS
  Future<void> addStopToRide(String rideId, StopLocation newStop) async {
    if (_uid == null) throw Exception("Passenger not authenticated.");
    
    // Get data first, then process in background
    final rideRef = _db.collection('ride_requests').doc(rideId);
    final rideSnapshot = await rideRef.get();
    
    if (!rideSnapshot.exists) {
      throw Exception("Ride not found.");
    }
    
    // Process heavy calculations in background
    Future.microtask(() async {
      try {
        final ride = Ride.fromFirestore(rideSnapshot);
        final updatedStopsMap = List.from(ride.stops)..add(newStop.toMap());
        
        final routePoints = <Point>[
          Point(coordinates: Position(ride.startLongitude!, ride.startLatitude!)),
          ...updatedStopsMap.map((stopMap) {
            final stop = StopLocation.fromMap(stopMap);
            return Point(coordinates: Position(stop.longitude, stop.latitude));
          }),
          Point(coordinates: Position(ride.destinationLongitude!, ride.destinationLatitude!)),
        ];

        final routeData = await _routingService.getRoute(routePoints);
        final newDistanceKm = _routingService.extractDistance(routeData) / 1000;
        final newDurationMinutes = _routingService.extractDuration(routeData) / 60;
        
        final newFareData = {
          'totalCost': 0.0,
          'baseFare': 0.0,
          'perKmRate': 0.0,
          'perMinRate': 0.0,
          'appCommission': 0.0,
          'driverEarnings': 0.0,
        };

        // Use batch update
        _addToBatch('ride_requests', rideId, {
          'stops': updatedStopsMap,
          'distance': newDistanceKm,
          'durationInMinutes': newDurationMinutes,
          'totalCost': newFareData['totalCost'],
          'driverEarnings': newFareData['driverEarnings'],
          'appCommission': newFareData['appCommission'],
          'baseFare': newFareData['baseFare'],
          'perKmRate': newFareData['perKmRate'],
          'perMinRate': newFareData['perMinRate'],
        });
      } catch (e) {
        Logger.error('Error adding stop', error: e, tag: 'FIRESTORE');
      }
    });
  }

  // ── NEIGHBORHOOD REQUESTS (EVAPORATING) ──────────────────────────────────
  Future<void> createNeighborhoodRequest(NeighborhoodRequest request) async {
    await _db.collection('neighborhood_requests').doc(request.id).set(request.toMap());
  }

  Future<void> resolveNeighborhoodRequest(String id) async {
    try {
      await _db.collection('neighborhood_requests').doc(id).update({'resolved': true});
    } catch (e) {
      Logger.error('Error resolving neighborhood request: $e', tag: 'FIRESTORE');
    }
  }

  Future<void> deleteNeighborhoodRequest(String id) async {
    try {
      await _db.collection('neighborhood_requests').doc(id).delete();
    } catch (e) {
      Logger.error('Error deleting neighborhood request: $e', tag: 'FIRESTORE');
      rethrow;
    }
  }

  Stream<List<NeighborhoodRequest>> getActiveNeighborhoodRequests() {
    // În mod real ar trebui filtrat și pe geohash, dar pentru testare luăm tot ce e valid pe tip
    final now = Timestamp.now();
    return _db
        .collection('neighborhood_requests')
        .where('resolved', isEqualTo: false)
        .where('expiresAt', isGreaterThan: now)
        .snapshots()
        .map((snapshot) {
      final clientNow = DateTime.now();
      return snapshot.docs
          .map((doc) => NeighborhoodRequest.fromMap(doc.id, doc.data()))
          .where((r) => !r.resolved && r.expiresAt.isAfter(clientNow))
          .toList();
    });
  }

  /// Aceeași regulă ca stream-ul de mai sus — pentru sincron imediat după reset Mapbox (stil / manageri).
  Future<List<NeighborhoodRequest>> fetchActiveNeighborhoodRequestsOnce() async {
    final now = Timestamp.now();
    final snapshot = await _db
        .collection('neighborhood_requests')
        .where('resolved', isEqualTo: false)
        .where('expiresAt', isGreaterThan: now)
        .get();
    final clientNow = DateTime.now();
    return snapshot.docs
        .map((doc) => NeighborhoodRequest.fromMap(doc.id, doc.data()))
        .where((r) => !r.resolved && r.expiresAt.isAfter(clientNow))
        .toList();
  }

  // OPTIMIZED DRIVER SEARCH WITH REDUCED COMPLEXITY
  Future<void> _startAutomaticDriverSearch(String rideId, Ride ride) async {
    Logger.info('Starting optimized driver search for ride $rideId', tag: 'FIRESTORE');
  
    if (ride.startLatitude == null || ride.startLongitude == null) {
      Logger.error('Ride $rideId missing coordinates');
      return;
    }
  
    // Set expiration timer
    Timer(const Duration(minutes: 2), () async {
      final rideDoc = await _db.collection('ride_requests').doc(rideId).get();
      if (rideDoc.exists && rideDoc.data()?['status'] == 'pending') {
        await updateRideStatus(rideId, 'expired');
      }
    });
    
    // Căutare în rază mică, apoi extinsă (șoferi: contacte în app + comutator disponibil + poziție proaspătă).
    await _searchDriversInRadius(
      rideId,
      ride,
      PassengerDriverSearchConfig.initialRadiusKm,
    );
    
    // Extended search after 30 seconds
    Timer(const Duration(seconds: 30), () async {
      final rideDoc = await _db.collection('ride_requests').doc(rideId).get();
      if (rideDoc.exists && rideDoc.data()?['status'] == 'pending') {
        _addToBatch('ride_requests', rideId, {
          'searchRadius': PassengerDriverSearchConfig.extendedRadiusKm,
        });
        await _searchDriversInRadius(
          rideId,
          ride,
          PassengerDriverSearchConfig.extendedRadiusKm,
        );
      }
    });
  }

  // ✅ IMPROVED: Advanced driver search with batch matching
  Future<void> _searchDriversInRadius(String rideId, Ride ride, double radiusKm) async {
    try {
      // Citim lista actualizată de șoferi refuzați direct din Firestore
      // (ride-ul din memorie poate fi vechi dacă pasagerul tocmai a refuzat un șofer)
      final rideSnap = await _db.collection('ride_requests').doc(rideId).get();
      final declinedByList = List<String>.from(rideSnap.data()?['declinedBy'] ?? []);

      // ✅ BATCH: Query multiple categories in parallel
      final compatibleCategories = _getCompatibleCategories(ride.category);
      final List<Future<QuerySnapshot>> categoryQueries = [];

      // isOnline = comutator „disponibil ca șofer” (vezi [updateDriverAvailability]).
      for (final category in compatibleCategories) {
        categoryQueries.add(
          _db.collection('driver_locations')
              .where('category', isEqualTo: category)
              .where('isOnline', isEqualTo: true)
              .get()
        );
      }

      final queryResults = await Future.wait(categoryQueries);

      final availableDrivers = <Map<String, dynamic>>[];
      // Must exceed worst-case gaps between driver_locations writes (debounced updates
      // when idle + distanceFilter), otherwise eligible drivers disappear from matching.
      final driverLocationFreshnessCutoff =
          DateTime.now().subtract(const Duration(minutes: 15));

      // Process all results
      for (final snapshot in queryResults) {
        for (final driverDoc in snapshot.docs) {
          // ✅ Exclude șoferii care au refuzat sau au fost refuzați de pasager
          if (declinedByList.contains(driverDoc.id)) continue;

          // Doar UID-uri din rețeaua pasagerului (agendă + prieteni); lista e rezolvată la crearea cursei.
          if (ride.allowedDriverUids != null && !ride.allowedDriverUids!.contains(driverDoc.id)) continue;

          final driverData = driverDoc.data() as Map<String, dynamic>?;
          if (driverData == null) continue;

          final driverPosition = driverData['position'] as GeoPoint?;
          final lastUpdate = driverData['lastUpdate'] as Timestamp?;

          if (lastUpdate != null &&
              lastUpdate.toDate().isAfter(driverLocationFreshnessCutoff) &&
              driverPosition != null) {

            final distance = geolocator.Geolocator.distanceBetween(
              ride.startLatitude!, ride.startLongitude!,
              driverPosition.latitude, driverPosition.longitude,
            ) / 1000;

            if (distance <= radiusKm) {
              availableDrivers.add({
                'driverId': driverDoc.id,
                'distance': distance,
                'category': driverData['category'] ?? 'standard',
                'data': driverData
              });
            }
          }
        }
      }
      
      // ✅ Women-only matching: filter by gender when passenger prefers a female driver
      List<Map<String, dynamic>> filteredDrivers = availableDrivers;
      if (ride.ridePreferences?.preferFemaleDriver == true) {
        final genderChecks = await Future.wait(
          availableDrivers.map((d) => isDriverFemale(d['driverId'] as String)),
        );
        filteredDrivers = [
          for (var i = 0; i < availableDrivers.length; i++)
            if (genderChecks[i]) availableDrivers[i],
        ];
        Logger.info(
          'Women-only filter: ${filteredDrivers.length}/${availableDrivers.length} drivers qualify',
          tag: 'DriverMatching',
        );
      }

      if (filteredDrivers.isNotEmpty) {
        // ✅ BATCH OFFERS: Select top 3 drivers and create batch offer
        final topDrivers = await _selectTopDriversForBatch(filteredDrivers, ride);
        if (topDrivers.isNotEmpty) {
          // Get the best driver for single assignment (backward compatibility)
          final best = topDrivers.first;
          // Create batch offer with top drivers
          await _createBatchOfferForDriver(best['driverId'] as String, rideId, ride, topDrivers);
        } else {
          Logger.warning('No drivers found, expanding search radius', tag: 'DriverMatching');
          if (radiusKm <
              PassengerDriverSearchConfig.maxRadiusKm -
                  PassengerDriverSearchConfig.expandStepKm) {
            await _searchDriversInRadius(
              rideId,
              ride,
              radiusKm + PassengerDriverSearchConfig.expandStepKm,
            );
          }
        }
      } else {
        if (radiusKm < PassengerDriverSearchConfig.maxRadiusKm) {
          Logger.info(
            'No drivers found in radius $radiusKm, expanding to ${radiusKm + PassengerDriverSearchConfig.expandStepKm}',
            tag: 'DriverMatching',
          );
          await _searchDriversInRadius(
            rideId,
            ride,
            radiusKm + PassengerDriverSearchConfig.expandStepKm,
          );
        }
      }
    } catch (e) {
      Logger.error('Driver search error', error: e, tag: 'DriverMatching');
    }
  }

  /// Select top N drivers for batch offers
  Future<List<Map<String, dynamic>>> _selectTopDriversForBatch(
    List<Map<String, dynamic>> candidates,
    Ride ride,
    {int count = 3}
  ) async {
    if (candidates.isEmpty) return [];

    // Sort by distance first
    candidates.sort((a, b) => (a['distance'] as num).compareTo(b['distance'] as num));
    final topCandidates = candidates.take(count * 2).toList(); // Get more candidates for better selection

    // Score all candidates (simplified version for batch)
    final scored = <Map<String, dynamic>>[];
    for (final cand in topCandidates) {
      final double distanceKm = (cand['distance'] as num).toDouble();
      
      // Simple scoring for batch (distance + rating)
      final score = distanceKm; // Simplified - can be enhanced
      scored.add({
        ...cand,
        'score': score,
      });
    }

    // Sort by score and return top N
    scored.sort((a, b) => (a['score'] as num).compareTo(b['score'] as num));
    return scored.take(count).toList();
  }

  /// Create batch offer for a driver with multiple rides
  Future<void> _createBatchOfferForDriver(
    String driverId,
    String primaryRideId,
    Ride primaryRide,
    List<Map<String, dynamic>> driverCandidates,
  ) async {
    try {
      // ✅ IMPLEMENTED: Collect multiple pending rides and create batch offer
      final bestDriver = driverCandidates.first;
      
      // Collect other pending rides in the same area for batch offer
      final pendingRides = await _db.collection('ride_requests')
          .where('status', isEqualTo: 'pending')
          .where('category', isEqualTo: primaryRide.category.name)
          .where('startLatitude', isGreaterThanOrEqualTo: primaryRide.startLatitude! - 0.05)
          .where('startLatitude', isLessThanOrEqualTo: primaryRide.startLatitude! + 0.05)
          .where('startLongitude', isGreaterThanOrEqualTo: primaryRide.startLongitude! - 0.05)
          .where('startLongitude', isLessThanOrEqualTo: primaryRide.startLongitude! + 0.05)
          .limit(5) // Max 5 rides in batch
          .get();
      
      final batchRides = <Map<String, dynamic>>[];
      
      // Add primary ride
      batchRides.add({
        'rideId': primaryRideId,
        'ride': primaryRide,
        'driverDistance': bestDriver['distance'] as double,
      });
      
      // Add other compatible rides
      for (final rideDoc in pendingRides.docs) {
        if (rideDoc.id == primaryRideId) continue; // Skip primary ride
        
        final ride = Ride.fromFirestore(rideDoc);
        if (ride.startLatitude == null || ride.startLongitude == null) continue;
        
        // Calculate distance from driver to this ride
        final driverPos = bestDriver['data']['position'] as GeoPoint?;
        if (driverPos == null) continue;
        
        final distance = geolocator.Geolocator.distanceBetween(
          driverPos.latitude, driverPos.longitude,
          ride.startLatitude!, ride.startLongitude!,
        ) / 1000;
        
        if (distance <= 10.0) { // Within 10km
          batchRides.add({
            'rideId': rideDoc.id,
            'ride': ride,
            'driverDistance': distance,
          });
        }
      }
      
      // Sort by driver distance
      batchRides.sort((a, b) => (a['driverDistance'] as double).compareTo(b['driverDistance'] as double));
      
      // Create batch offer document
      if (batchRides.length > 1) {
        final batchOfferId = _db.collection('batch_offers').doc().id;
        final batchOfferData = {
          'id': batchOfferId,
          'driverId': driverId,
          'rides': batchRides.map((r) {
            final ride = r['ride'] as Ride;
            return {
              'rideId': r['rideId'],
              'passengerName': 'Passenger', // Will be fetched from user profile if needed
              'pickupAddress': ride.startAddress,
              'destinationAddress': ride.destinationAddress,
              'distanceKm': ride.distance,
              'estimatedFare': ride.totalCost,
              'estimatedDurationMinutes': ride.durationInMinutes?.toInt() ?? 0,
              'driverDistanceKm': r['driverDistance'] as double,
              'driverEtaMinutes': (r['driverDistance'] as double) * 2, // Approximate: 30 km/h
              'category': ride.category.name,
            };
          }).toList(),
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(seconds: 30))),
          'status': 'pending',
        };
        
        await _db.collection('batch_offers').doc(batchOfferId).set(batchOfferData);
        Logger.info('Batch offer created for driver $driverId with ${batchRides.length} rides', tag: 'BatchOffers');
      } else {
        // Single ride - use existing assignment
        await _assignRideToDriver(primaryRideId, bestDriver);
        Logger.info('Single ride assigned to driver $driverId', tag: 'BatchOffers');
      }
    } catch (e) {
      Logger.error('Error creating batch offer', error: e, tag: 'BatchOffers');
      // Fallback to single assignment
      try {
        final bestDriver = driverCandidates.first;
        await _assignRideToDriver(primaryRideId, bestDriver);
      } catch (fallbackError) {
        Logger.error('Fallback assignment also failed', error: fallbackError, tag: 'BatchOffers');
      }
    }
  }

  // Keep existing methods but use batch updates where possible
  Future<void> updateRideStatus(String rideId, String newStatus) async {
    final updateData = <String, dynamic>{'status': newStatus};

    if (newStatus == 'cancelled' || newStatus == 'expired') { 
      updateData['wasCancelled'] = true;
      updateData['cancelledBy'] = _uid;
    } else {
      updateData['wasCancelled'] = false;
    }

    if (const {'completed', 'cancelled', 'expired'}.contains(newStatus)) {
      unawaited(ActiveRideTelemetryRtdbService.instance.removeRideTelemetry(rideId));
    }
    
    _addToBatch('ride_requests', rideId, updateData);
  }

  Future<void> acceptRide(String rideId) async {
    Logger.debug('Accepting ride: $rideId', tag: 'DRIVER');

    if (_uid == null) {
      Logger.error('Driver not authenticated - _uid is null', tag: 'DRIVER');
      throw Exception("Driver not authenticated. Please log in again.");
    }

    // Verify role before starting transaction (read-only, no race risk)
    final userRole = await getUserRole();
    if (userRole != UserRole.driver) {
      Logger.error('User is not a driver: $userRole', tag: 'DRIVER');
      throw Exception("User is not a driver. Cannot accept rides.");
    }

    // Generate pickup code outside transaction (no side effects inside)
    final secureRandom = math.Random.secure();
    final pickupCode = (1000 + secureRandom.nextInt(9000)).toString();

    final rideRef = _db.collection('ride_requests').doc(rideId);
    String? passengerId;

    try {
      await _db.runTransaction((transaction) async {
        final rideDoc = await transaction.get(rideRef);

        if (!rideDoc.exists) {
          throw Exception("Ride not found: $rideId");
        }

        final data = rideDoc.data()!;
        final currentStatus = data['status'] as String?;
        final currentDriverId = data['driverId'];

        // Reject if already accepted by another driver — atomic check
        if (currentDriverId != null && currentDriverId != _uid) {
          Logger.warning('acceptRide: ride $rideId already taken by $currentDriverId', tag: 'DRIVER');
          throw Exception("Ride already assigned to another driver");
        }

        // Only accept rides that are still available
        if (currentStatus != null &&
            currentStatus != 'pending' &&
            currentStatus != 'searching' &&
            currentStatus != 'driver_found') {
          Logger.warning('acceptRide: ride $rideId has unexpected status: $currentStatus', tag: 'DRIVER');
          throw Exception("Ride no longer available (status: $currentStatus)");
        }

        passengerId = data['passengerId'] as String?;

        transaction.update(rideRef, {
          'status': 'driver_found',
          'driverId': _uid,
          'acceptedAt': FieldValue.serverTimestamp(),
          'driverAcceptanceStatus': 'accepted',
          'driverAcceptanceUpdatedAt': FieldValue.serverTimestamp(),
          'pickupCode': pickupCode,
        });
      });

      if (passengerId != null && passengerId!.isNotEmpty) {
        unawaited(ActiveRideTelemetryRtdbService.instance.ensureRideMeta(
          rideId: rideId,
          driverId: _uid!,
          passengerId: passengerId!,
        ));
      }

      Logger.info('Ride $rideId accepted atomically by $_uid', tag: 'DRIVER');
    } catch (e) {
      Logger.error('Error accepting ride: $e', tag: 'DRIVER', error: e);
      if (e is FirebaseException) {
        Logger.error('Firebase error code: ${e.code} — ${e.message}', tag: 'DRIVER');
      }
      rethrow;
    }
  }

  Future<void> updateRideFields(String rideId, Map<String, dynamic> data) async {
    await _db.collection('ride_requests').doc(rideId).update(data);
  }

  // ✅ NOU: OPTIMIZED TRANSACTION FOR UPDATING DESTINATION
  Future<void> updateRideDestination(String rideId, String newDestinationAddress, double newDestinationLatitude, double newDestinationLongitude) async {
    if (_uid == null) throw Exception("Passenger not authenticated.");
    
    // Get data first, then process in background
    final rideRef = _db.collection('ride_requests').doc(rideId);
    final rideSnapshot = await rideRef.get();
    
    if (!rideSnapshot.exists) {
      throw Exception("Ride not found.");
    }
    
    final ride = Ride.fromFirestore(rideSnapshot);
    
    // Verifică dacă pasagerul are permisiunea să modifice destinația
    if (ride.passengerId != _uid) {
      throw Exception("Only the passenger can modify the destination.");
    }
    
    // Verifică dacă cursa permite modificarea destinației
    if (ride.status == 'completed' || ride.status == 'cancelled') {
      throw Exception("Cannot modify destination for completed or cancelled ride.");
    }
    
    // Process heavy calculations in background
    Future.microtask(() async {
      try {
        // Construiește route points cu noua destinație
        final routePoints = <Point>[
          Point(coordinates: Position(ride.startLongitude!, ride.startLatitude!)),
          ...ride.stops.map((stopMap) {
            final stop = StopLocation.fromMap(stopMap);
            return Point(coordinates: Position(stop.longitude, stop.latitude));
          }),
          Point(coordinates: Position(newDestinationLongitude, newDestinationLatitude)),
        ];

        final routeData = await _routingService.getRoute(routePoints);
        final newDistanceKm = _routingService.extractDistance(routeData) / 1000;
        final newDurationMinutes = _routingService.extractDuration(routeData) / 60;
        
        final newFareData = {
          'totalCost': 0.0,
          'baseFare': 0.0,
          'perKmRate': 0.0,
          'perMinRate': 0.0,
          'appCommission': 0.0,
          'driverEarnings': 0.0,
        };

        // Use batch update
        _addToBatch('ride_requests', rideId, {
          'destinationAddress': newDestinationAddress,
          'destinationLatitude': newDestinationLatitude,
          'destinationLongitude': newDestinationLongitude,
          'distance': newDistanceKm,
          'durationInMinutes': newDurationMinutes,
          'totalCost': newFareData['totalCost'],
          'driverEarnings': newFareData['driverEarnings'],
          'appCommission': newFareData['appCommission'],
          'baseFare': newFareData['baseFare'],
          'perKmRate': newFareData['perKmRate'],
          'perMinRate': newFareData['perMinRate'],
          'destinationUpdatedAt': FieldValue.serverTimestamp(),
        });
        
        // Trimite mesaj de sistem pentru șofer
        await sendSystemMessage(rideId, 'Destination was updated: $newDestinationAddress');
        
        Logger.info('Destination updated for ride $rideId', tag: 'FIRESTORE');
      } catch (e) {
        Logger.error('Error updating destination', error: e, tag: 'FIRESTORE');
        rethrow;
      }
    });
  }

  Future<void> updateDriverAcceptanceStatus(String rideId, String status) async {
    await updateRideFields(rideId, {
      'driverAcceptanceStatus': status,
      'driverAcceptanceUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> passengerConfirmDriver(String rideId, {String? routePreviewUrl}) async {
    final data = <String, dynamic>{'status': 'accepted'};
    if (routePreviewUrl != null && routePreviewUrl.isNotEmpty) {
      data['routePreviewUrl'] = routePreviewUrl;
    }
    await _db.collection('ride_requests').doc(rideId).update(data);
  }

  /// Încarcă PNG în `ride_route_previews/{rideId}/preview.png` (aliniază regulile Storage cu `rideId` în path).
  Future<String> uploadRideRoutePreviewPng(String rideId, Uint8List pngBytes) async {
    if (_uid == null) {
      throw Exception('User not authenticated');
    }
    final ref = _storage.ref().child('ride_route_previews').child(rideId).child('preview.png');
    await ref.putData(
      pngBytes,
      SettableMetadata(contentType: 'image/png'),
    );
    return ref.getDownloadURL();
  }

  Future<void> declineRide(String rideId) async {
    if (_uid == null) return;
    
    try {
      final rideDoc = await _db.collection('ride_requests').doc(rideId).get();
      if (!rideDoc.exists) return;
      
      final rideData = rideDoc.data()!;
      final currentStatus = rideData['status'];
      
      if (currentStatus == 'driver_found') {
        // Șoferul refuză după ce a fost ales - revin la pending
        await _db.collection('ride_requests').doc(rideId).update({
          'status': 'pending',
          'driverId': FieldValue.delete(),
          'declinedBy': FieldValue.arrayUnion([_uid]),
          'declinedAt': FieldValue.serverTimestamp(),
        });
        Logger.debug('Driver declined assigned ride, returned to pending');
      } else {
        // Decline normal
        _addToBatch('ride_requests', rideId, {
          'declinedBy': FieldValue.arrayUnion([_uid])
        });
      }
    } catch (e) {
      Logger.error('Error in declineRide: $e', error: e);
    }
  }

  // Cleanup method to prevent memory leaks
  void dispose() {
    _locationDebouncer?.cancel();
    _rideSearchDebouncer?.cancel();
    _batchTimer?.cancel();
    
    for (final timer in _cacheTimers.values) {
      timer.cancel();
    }
    
    _cache.clear();
    _cacheTimers.clear();
    _lastLocationUpdate.clear();
    _pendingUpdates.clear();
  }

  bool _isDriverCategoryCompatible(RideCategory rideCategory, String? driverCategory) {
    if (driverCategory == null) return false;

    switch (rideCategory) {
      case RideCategory.any:
        return true; // orice șofer acceptă cereri "any"
      case RideCategory.standard:
        return ['standard', 'family', 'energy', 'best'].contains(driverCategory);
      case RideCategory.family:
        return ['family', 'energy', 'best'].contains(driverCategory);
      case RideCategory.energy:
        return ['energy', 'best'].contains(driverCategory);
      case RideCategory.best:
        return driverCategory == 'best';
      case RideCategory.utility:
        return driverCategory == 'utility';
    }
  }

  // Keep all other existing methods unchanged for compatibility
  Future<String> uploadProfileImage(File imageFile) async {
    if (_uid == null) throw Exception("User not authenticated.");
    try {
      final ref = _storage.ref().child('profile_images').child('$_uid.jpg');
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      await _db.collection('users').doc(_uid).set({'photoURL': downloadUrl}, SetOptions(merge: true));
      return downloadUrl;
    } catch (e) {
      Logger.error("Profile image upload error: $e", error: e);
      rethrow;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getProfileByIdStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }
  
  Future<void> updatePassengerProfile({
    required String displayName,
    required String phoneNumber,
  }) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).set({
      'displayName': displayName,
      ...ContactsService.userPhoneFieldsForProfile(phoneNumber),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> deleteUserAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return {'success': false, 'message': 'User not authenticated.'};
    }

    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await _db.collection('users').doc(user.uid).delete();
      await user.delete();
      return {'success': true, 'message': 'Account deleted successfully.'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'INVALID_LOGIN_CREDENTIALS') {
        return {'success': false, 'message': 'Incorrect password.'};
      }
      return {'success': false, 'message': 'Error deleting account: ${e.message}'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return {'success': false, 'message': 'User not authenticated.'};
    }
    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return {'success': true, 'message': 'Password changed successfully!'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'INVALID_LOGIN_CREDENTIALS') {
        return {'success': false, 'message': 'Current password is incorrect.'};
      } else {
        return {'success': false, 'message': 'Error occurred: ${e.message}'};
      }
    }
  }
  
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream() {
    if (_uid == null) return const Stream.empty();
    return _db.collection('users').doc(_uid).snapshots();
  }

  /// Punct personal pe hartă (reper „acasă” / orientare), vizibil doar pentru contul curent.
  /// [label] — denumire afișată pe hartă și în căutare (opțională; dacă lipsește, câmpul e șters).
  Future<void> setMapOrientationPin(
    double latitude,
    double longitude, {
    String? label,
  }) async {
    if (_uid == null) return;
    final data = <String, dynamic>{
      'mapOrientationPin': GeoPoint(latitude, longitude),
    };
    final t = label?.trim() ?? '';
    if (t.isNotEmpty) {
      data['mapOrientationPinLabel'] = t;
    } else {
      data['mapOrientationPinLabel'] = FieldValue.delete();
    }
    await _db.collection('users').doc(_uid).set(data, SetOptions(merge: true));
  }

  Future<void> clearMapOrientationPin() async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'mapOrientationPin': FieldValue.delete(),
      'mapOrientationPinLabel': FieldValue.delete(),
    });
  }

  /// Afișează pe hartă (doar pentru tine) pinul la adresa „Acasă” din `saved_addresses`.
  Future<void> setShowSavedHomePinOnMap(bool show) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).set(
      {'showSavedHomePinOnMap': show},
      SetOptions(merge: true),
    );
  }
  
  Future<void> updateFullDriverProfile({
    required String displayName, 
    required String phoneNumber,
    required String licensePlate,
    required RideCategory category,
    required String carMake,
    required String carModel,
    required String carColor,
    required String carYear,
    required String age,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName);
    await _db.collection('users').doc(user.uid).set({
      'displayName': displayName,
      ...ContactsService.userPhoneFieldsForProfile(phoneNumber),
      'licensePlate': licensePlate,
      'driverCategory': category.name,
      'carMake': carMake,
      'carModel': carModel,
      'carColor': carColor,
      'carYear': carYear,
      'age': age,
      'role': 'driver',
    }, SetOptions(merge: true));
  }

  Future<bool> activateDriverWithCode(String code) async {
    if (_uid == null) {
      throw Exception("User not authenticated.");
    }

    try {
      Logger.debug('Attempting to activate driver code: $code for user: $_uid');
      final userDoc = await _db.collection('users').doc(_uid).get();
      
      if (!userDoc.exists) {
        Logger.debug('User document does not exist for user: $_uid');
        return false;
      }

      final userData = userDoc.data()!;
      final storedCode = userData['activationCode'] as String?;
      final isCodeActive = userData['isCodeActive'] as bool?;

      if (storedCode == null || storedCode != code) {
        Logger.debug('Invalid activation code. Expected: $storedCode, Got: $code');
        return false;
      }

      if (isCodeActive != true) {
        Logger.debug('Activation code is not active or was already used');
        return false;
      }

      await _db.collection('users').doc(_uid).update({
        'role': 'driver',
        'isCodeActive': false, 
        'driverActivatedAt': FieldValue.serverTimestamp(),
        'activationCodeUsedAt': FieldValue.serverTimestamp(),
      });

      Logger.debug('Driver activation successful for user: $_uid with code: $code');
      return true;

    } catch (e) {
      Logger.error('Error activating driver code: $e', error: e);
      throw Exception('Code validation error: $e');
    }
  }

  Future<Map<String, dynamic>> checkActivationCodeStatus() async {
    if (_uid == null) {
      return {'hasCode': false, 'isActive': false, 'message': 'User not authenticated'};
    }

    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      
      if (!userDoc.exists) {
        return {'hasCode': false, 'isActive': false, 'message': 'User document not found'};
      }

      final userData = userDoc.data()!;
      final hasCode = userData['activationCode'] != null;
      final isActive = userData['isCodeActive'] == true;
      final userRole = userData['role'] as String?;

      return {
        'hasCode': hasCode,
        'isActive': isActive,
        'isAlreadyDriver': userRole == 'driver',
        'message': hasCode 
            ? (isActive ? 'Active code available' : 'Code used or deactivated')
            : 'No activation code exists'
      };

    } catch (e) {
      Logger.error('Error checking activation code status: $e', error: e);
      return {'hasCode': false, 'isActive': false, 'message': 'Verification error'};
    }
  }
  
  Stream<Ride?> getActiveDriverRideStream() {
    if (_uid == null) {
      Logger.debug('getActiveDriverRideStream: UID is null, returning empty stream');
      return Stream.value(null);
    }
    
    Logger.debug('getActiveDriverRideStream: Querying for UID: $_uid');
    
    return _db.collection('ride_requests')
        .where('driverId', isEqualTo: _uid)
        .where('status', whereIn: ['accepted', 'arrived', 'in_progress'])
        .limit(1)
        .snapshots()
        .map((snapshot) {
          Logger.debug('getActiveDriverRideStream: Found ${snapshot.docs.length} driver rides');
          
          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            final data = doc.data();
            Logger.debug('Driver ride data:');
            Logger.debug('- ID: ${doc.id}');
            Logger.debug('- Status: ${data['status']}');
            Logger.debug('- DriverId: ${data['driverId']}');
            Logger.debug('- PassengerId: ${data['passengerId']}');
            
            final ride = Ride.fromFirestore(snapshot.docs.first);
            return ride;
          } else {
            Logger.debug('getActiveDriverRideStream: No driver rides found');
          }
          return null;
        })
        .handleError((error) {
          Logger.error('Error in getActiveDriverRideStream: $error', tag: 'FIRESTORE', error: error);
          return null; // Return null on error instead of crashing
        });
  }

  Stream<Ride?> getActivePassengerRideStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(null);
    }

    return _db
        .collection('ride_requests')
        .where('passengerId', isEqualTo: userId)  // ✅ MODIFICAT: userId → passengerId
        .where('status', whereIn: ['accepted', 'arrived', 'in_progress', 'driver_found'])
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Ride.fromFirestore(doc);
      }
      return null;
    });
  }

  Stream<List<Ride>> getDriverRidesHistory({DateFilter filter = DateFilter.all}) {
    if (_uid == null) return Stream.value([]);

    // Only this driver's completed rides — matches Firestore rules (must not list others' docs).
    return _db
        .collection('ride_requests')
        .where('driverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final driverRides = snapshot.docs
              .map((doc) => Ride.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList();

          if (filter == DateFilter.all) {
            return driverRides;
          }
          
          final DateTime now = DateTime.now();
          DateTime? startDate;

          switch (filter) {
            case DateFilter.today:
              startDate = DateTime(now.year, now.month, now.day);
              break;
            case DateFilter.lastWeek:
              startDate = now.subtract(const Duration(days: 7));
              break;
            case DateFilter.lastMonth:
              startDate = DateTime(now.year, now.month - 1, now.day);
              break;
            case DateFilter.last3Months:
              startDate = DateTime(now.year, now.month - 3, now.day);
              break;
            case DateFilter.thisYear:
              startDate = DateTime(now.year);
              break;
            case DateFilter.all:
              break;
          }

          if (startDate != null) {
            return driverRides.where((ride) => ride.timestamp.isAfter(startDate!)).toList();
          }
          
          return driverRides;
        });
  }
  
  Future<void> submitSupportTicket(SupportTicket ticket) async {
    if (_uid == null) throw Exception("User not authenticated.");
    final ticketData = ticket.toMap();
    ticketData['userId'] = _uid; 
    await _db.collection('support_tickets').add(ticketData);
  }

  Future<Map<String, dynamic>> validateVoucher(
    String code, {
    bool consume = true,
  }) async {
    if (_uid == null) return {'success': false, 'message': 'User not authenticated.'};

    final upperCode = code.trim().toUpperCase();
    try {
      // 1. Check if voucher exists and is valid
      final snap = await _db
          .collection('vouchers')
          .where('code', isEqualTo: upperCode)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return {'success': false, 'message': 'Voucher code is invalid or expired.'};
      }

      final doc = snap.docs.first;
      final data = doc.data();
      final expiryTs = data['expiryDate'] as Timestamp?;
      if (expiryTs != null && expiryTs.toDate().isBefore(DateTime.now())) {
        return {'success': false, 'message': 'Voucher code has expired.'};
      }

      final maxUses = (data['maxUses'] as num?)?.toInt();
      final timesUsed = (data['timesUsed'] as num?)?.toInt() ?? 0;
      if (maxUses != null && timesUsed >= maxUses) {
        return {'success': false, 'message': 'Voucher code is no longer available.'};
      }

      // 2. Check if user already used this voucher
      final userVoucherSnap = await _db
          .collection('users')
          .doc(_uid)
          .collection('user_vouchers')
          .where('voucherId', isEqualTo: doc.id)
          .limit(1)
          .get();

      if (userVoucherSnap.docs.isNotEmpty) {
        return {'success': false, 'message': 'You already used this voucher.'};
      }

      // 3. Save to user's vouchers and increment usage counter (optional for preview UX)
      if (consume) {
        await _db
            .collection('users')
            .doc(_uid)
            .collection('user_vouchers')
            .add({
          'voucherId': doc.id,
          'code': upperCode,
          'description': data['description'] ?? '',
          'value': data['value'] ?? 0,
          'type': data['type'] ?? 'percentage',
          'appliedAt': FieldValue.serverTimestamp(),
          'isUsed': false,
        });

        await _db.collection('vouchers').doc(doc.id).update({
          'timesUsed': FieldValue.increment(1),
        });
      }

      final description = data['description'] as String? ?? 'Voucher applied successfully!';
      final double value = (data['value'] as num?)?.toDouble() ?? 0.0;
      final String type = data['type'] as String? ?? 'percentage';
      return {
        'success': true,
        'message': description,
        'voucherId': doc.id,
        'value': value,
        'type': type,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error validating voucher.'};
    }
  }

  Future<void> submitRating({ 
    required String rideId, 
    required double rating, 
    String? comment,
    double? tip, // ✅ ADĂUGAT: Parametru pentru bacșiș
  }) async {
    if (_uid == null) return;
    final rideDoc = await _db.collection('ride_requests').doc(rideId).get();
    if (!rideDoc.exists) return;
    final rideData = rideDoc.data()!;
    final bool isPassenger = rideData['passengerId'] == _uid;  // ✅ MODIFICAT: userId → passengerId
    
    if (isPassenger) {
      final Map<String, dynamic> updateData = {
        'passengerRating': rating,
        'passengerComment': comment,
      };
      
      // ✅ ADĂUGAT: Include bacșișul dacă este specificat
      if (tip != null && tip > 0) {
        updateData['tip'] = tip;
      }
      
      _addToBatch('ride_requests', rideId, updateData);
      await _commitBatchNow();

      final driverId = rideData['driverId'];
      if (driverId != null) {
        // Process rating update in background to avoid blocking UI
        Future.microtask(() async {
          final driverProfileRef = _db.collection('users').doc(driverId);
          await _db.runTransaction((transaction) async {
            final snapshot = await transaction.get(driverProfileRef);
            final oldRating = (snapshot.data()?['averageRating'] as num?)?.toDouble() ?? 0.0;
            final rideCount = (snapshot.data()?['totalRides'] as num?)?.toInt() ?? 0;
            final newRideCount = rideCount + 1;
            final newAverageRating = ((oldRating * rideCount) + rating) / newRideCount;
            
            transaction.update(driverProfileRef, {
              'totalRides': newRideCount,
              'averageRating': newAverageRating,
              'rideId': rideId,
            });
          });
        });
      }
    } else {
      _addToBatch('ride_requests', rideId, {
        'driverRating': rating,
        'driverComment': comment
      });
      await _commitBatchNow();
    }
  }

  Future<void> ratePassenger({
    required String rideId,
    required double rating,
    String? characterization,
  }) async {
    final driverId = _uid;
    if (driverId == null) throw Exception("Driver not authenticated.");

    final rideDocRef = _db.collection('ride_requests').doc(rideId);
    final rideDoc = await rideDocRef.get();

    if (!rideDoc.exists) return;

    final passengerId = rideDoc.data()?['passengerId'];  // ✅ MODIFICAT: userId → passengerId
    if (passengerId == null) return;

    final Map<String, dynamic> rideUpdateData = {
      'driverRatingForPassenger': rating,
    };
    if (characterization != null && characterization.isNotEmpty) {
      rideUpdateData['driverCharacterizationForPassenger'] = characterization;
    }
    
    _addToBatch('ride_requests', rideId, rideUpdateData);
    await _commitBatchNow();

    // Process passenger rating update in background
    Future.microtask(() async {
      final passengerProfileRef = _db.collection('users').doc(passengerId);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(passengerProfileRef);

        if (!snapshot.exists) {
          Logger.error("Error: Passenger profile with ID $passengerId not found. Transaction cancelled.");
          return; 
        }

        final oldRating = (snapshot.data()?['passengerAverageRating'] as num?)?.toDouble() ?? 0.0;
        final rideCount = (snapshot.data()?['totalRidesAsPassenger'] as num?)?.toInt() ?? 0;
        final newRideCount = rideCount + 1;
        
        final newAverageRating = ((oldRating * rideCount) + rating) / newRideCount;

        final Map<String, dynamic> profileUpdateData = {
          'totalRidesAsPassenger': newRideCount,
          'rideId': rideId,
        };
        
        if (newAverageRating.isFinite) {
          profileUpdateData['passengerAverageRating'] = newAverageRating;
        }
        
        if (characterization != null && characterization.isNotEmpty) {
          profileUpdateData['lastCharacterization'] = characterization;
        }

        transaction.update(passengerProfileRef, profileUpdateData);
      });
    });
  }

  Stream<List<SavedAddress>> getSavedAddresses() {
    if (_uid == null) return Stream.value([]);
    return _db.collection('users').doc(_uid).collection('saved_addresses').snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => SavedAddress.fromFirestore(doc)).toList());
  }

  Future<void> addSavedAddress(SavedAddress address) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).collection('saved_addresses').add(address.toMap());
  }

  Future<void> deleteSavedAddress(String addressId) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).collection('saved_addresses').doc(addressId).delete();
  }
  
  Future<void> updateSavedAddress(String addressId, SavedAddress address) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).collection('saved_addresses').doc(addressId).update(address.toMap());
  }

  Future<void> initializeDefaultAddresses() async {
    if (_uid == null) return;
    
    final addressesRef = _db.collection('users').doc(_uid).collection('saved_addresses');
    final snapshot = await addressesRef.get();
    
    bool hasHome = false;
    bool hasWork = false;
    
    for (var doc in snapshot.docs) {
      final d = doc.data();
      final label = d['label']?.toString().toLowerCase() ?? '';
      final cat = d['category']?.toString();
      if (cat == 'home' || label == 'home') hasHome = true;
      if (cat == 'work' || label == 'work') hasWork = true;
    }
    
    if (!hasHome) {
      await addressesRef.add({
        'label': 'Home',
        'address': '',
        'coordinates': const GeoPoint(44.4268, 26.1025),
        'category': 'home',
      });
    }
    
    if (!hasWork) {
      await addressesRef.add({
        'label': 'Work',
        'address': '',
        'coordinates': const GeoPoint(44.4268, 26.1025),
        'category': 'work',
      });
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getDriverLocationStream(String driverId) {
    return _db.collection('driver_locations').doc(driverId).snapshots();
  }

  Stream<Ride> getRideStream(String rideId) {
    Logger.debug('Creating ride stream for ride: $rideId', tag: 'STREAM');
    return _db.collection('ride_requests').doc(rideId).snapshots().map((doc) {
      final ride = Ride.fromFirestore(doc);
      Logger.debug('Ride $rideId status: ${ride.status}', tag: 'STREAM');
      return ride;
    });
  }

  Future<Ride?> getRideById(String rideId) async {
    final doc = await _db.collection('ride_requests').doc(rideId).get();
    if (!doc.exists) return null;
    return Ride.fromFirestore(doc);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNearbyAvailableDrivers() {
    return _db.collection('driver_locations').snapshots();
  }

  Future<void> setUserRole(UserRole role) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).set({'role': role.name}, SetOptions(merge: true));
  }

  Future<UserRole> getUserRole() async {
    if (_uid == null) return UserRole.passenger;
    final doc = await _db.collection('users').doc(_uid).get();
    if (doc.exists && doc.data()!['role'] != null) {
      final roleString = doc.data()!['role'] as String;
      try {
        return UserRole.values.byName(roleString);
      } catch (e) {
        return UserRole.passenger;
      }
    }
    return UserRole.passenger;
  }

  Future<void> updateDriverAvailability(bool isAvailable, {String? displayName, String? licensePlate, RideCategory? category}) async {
    if (_uid == null) return;

    if (!isAvailable) {
      await _db.collection('driver_locations').doc(_uid).delete();
      await _db.collection('drivers').doc(_uid).set({
        'isAvailable': false,
        'isOnline': false,
      }, SetOptions(merge: true));
      await _db.collection('users').doc(_uid).set({
        'driverSessionStartedAt': null,
      }, SetOptions(merge: true));
      return;
    }

    await _db.collection('drivers').doc(_uid).set({'isAvailable': true}, SetOptions(merge: true));

    if (displayName != null && licensePlate != null && category != null) {
      final position = await _getCachedPosition();
      if (position != null) {
        final geohash = _encodeGeohash(position.latitude, position.longitude);
        final carAvatarId = await _resolveDriverCarAvatarIdForLocationWrite();
        final showOnPassengerLiveMap = await _driverShouldShowOnPassengerLiveMap();
        // `_searchDriversInRadius` cere `isOnline == true`; fără asta, pasagerul nu vede
        // șoferul până la primul `updateDriverLocation` (debounce până la ~60s).
        await _db.collection('driver_locations').doc(_uid).set({
          'position': GeoPoint(position.latitude, position.longitude),
          'displayName': displayName,
          'licensePlate': licensePlate,
          'category': category.name,
          'lastUpdate': Timestamp.now(),
          'isOnline': true,
          'geohash': geohash,
          'carAvatarId': carAvatarId,
          kDriverLocationShowOnPassengerLiveMap: showOnPassengerLiveMap,
        }, SetOptions(merge: true));
        await _db.collection('drivers').doc(_uid).set({
          'isOnline': true,
          'currentLatitude': position.latitude,
          'currentLongitude': position.longitude,
          'lastLocationAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await _db.collection('drivers').doc(_uid).set({'isOnline': false}, SetOptions(merge: true));
      }
      await _db.collection('users').doc(_uid).set({
        'driverSessionStartedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Șterge `driver_locations` când aplicația intră în fundal: avatarul dispare de pe hărțile altora.
  /// Nu schimbă `isAvailable` pe `drivers` — la revenire se republică poziția cu
  /// [restoreDriverLiveMapPresenceAfterForeground].
  Future<void> hideDriverLiveMapPresenceForAppBackground() async {
    if (_uid == null) return;
    final uid = _uid!;
    _locationDebouncer?.cancel();
    _locationDebouncer = null;
    _pendingUpdates.removeWhere(
      (u) =>
          (u['collection'] == 'driver_locations' && u['docId'] == uid) ||
          (u['collection'] == 'drivers' && u['docId'] == uid),
    );
    _batchTimer?.cancel();
    _batchTimer = null;
    try {
      await _db.collection('driver_locations').doc(uid).delete();
      await _db.collection('drivers').doc(uid).set(
        {'isOnline': false},
        SetOptions(merge: true),
      );
      Logger.debug('Driver live map presence cleared (app background)', tag: 'FIRESTORE');
    } catch (e, st) {
      Logger.warning(
        'hideDriverLiveMapPresenceForAppBackground: $e\n$st',
        tag: 'FIRESTORE',
      );
    }
  }

  /// După revenirea din fundal: recreează documentul de hartă fără să reseteze `driverSessionStartedAt`.
  Future<void> restoreDriverLiveMapPresenceAfterForeground({
    required String displayName,
    required String licensePlate,
    required RideCategory category,
  }) async {
    if (_uid == null) return;
    final uid = _uid!;
    geolocator.Position? position = await _getCachedPosition();
    position ??= await geolocator.Geolocator.getCurrentPosition(
      locationSettings: DeprecatedAPIsFix.createLocationSettings(
        accuracy: geolocator.LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      ),
    );

    final geohash = _encodeGeohash(position.latitude, position.longitude);
    final carAvatarId = await _resolveDriverCarAvatarIdForLocationWrite();
    final showOnPassengerLiveMap = await _driverShouldShowOnPassengerLiveMap();
    try {
      await _db.collection('driver_locations').doc(uid).set(
        {
          'position': GeoPoint(position.latitude, position.longitude),
          'displayName': displayName,
          'licensePlate': licensePlate,
          'category': category.name,
          'lastUpdate': Timestamp.now(),
          'isOnline': true,
          'geohash': geohash,
          'carAvatarId': carAvatarId,
          kDriverLocationShowOnPassengerLiveMap: showOnPassengerLiveMap,
        },
        SetOptions(merge: true),
      );
      await _db.collection('drivers').doc(uid).set(
        {
          'isOnline': true,
          'isAvailable': true,
          'currentLatitude': position.latitude,
          'currentLongitude': position.longitude,
          'lastLocationAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      Logger.debug('Driver live map presence restored (app foreground)', tag: 'FIRESTORE');
    } catch (e, st) {
      Logger.warning(
        'restoreDriverLiveMapPresenceAfterForeground: $e\n$st',
        tag: 'FIRESTORE',
      );
    }
  }

  /// Feature: Wait time fee — marks driver has arrived and starts wait timer.
  Future<void> markDriverArrived(String rideId) async {
    if (_uid == null) throw Exception("Driver not authenticated.");
    await _db.collection('ride_requests').doc(rideId).update({
      'status': 'arrived',
      'waitStartedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Feature: Wait time fee — finalizes wait time fee when ride starts.
  Future<double> finalizeWaitTimeFee(String rideId) async {
    final rideDoc = await _db.collection('ride_requests').doc(rideId).get();
    if (!rideDoc.exists) return 0.0;

    final data = rideDoc.data()!;
    final waitStartedAt = (data['waitStartedAt'] as Timestamp?)?.toDate();
    if (waitStartedAt == null) return 0.0;

    // Nabour rides are free (1 token fixed request cost handled elsewhere)
    const fee = 0.0;
    Logger.info('Wait time fee calculated: 0.0 (Nabour free model)', tag: 'FIRESTORE');
    if (fee > 0) {
      await _db.collection('ride_requests').doc(rideId).update({
        'waitTimeFee': fee,
      });
    }
    return fee;
  }

  /// Feature: Driver hours limit — gets how many hours the current driver has been online this session.
  Future<double> getDriverSessionHours() async {
    if (_uid == null) return 0.0;
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists) return 0.0;
    final sessionStart = (doc.data()?['driverSessionStartedAt'] as Timestamp?)?.toDate();
    if (sessionStart == null) return 0.0;
    return DateTime.now().difference(sessionStart).inMinutes / 60.0;
  }

  /// Feature: Selfie verification — uploads selfie and sets status to pending.
  Future<void> submitSelfieVerification(File selfieFile) async {
    if (_uid == null) throw Exception("User not authenticated.");
    final ref = _storage.ref().child('selfie_verification/$_uid/selfie.jpg');
    await ref.putFile(selfieFile);
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(_uid).set({
      'selfieVerificationStatus': 'pending',
      'selfieImageUrl': url,
      'selfieSubmittedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Feature: Women-only rides — returns true if the given driver has registered
  /// their gender as female. Used during driver matching when a passenger has
  /// enabled the `preferFemaleDriver` preference in their ride request.
  Future<bool> isDriverFemale(String driverId) async {
    final doc = await _db.collection('users').doc(driverId).get();
    if (!doc.exists) return false;
    return doc.data()?['gender'] == 'female';
  }

  Future<bool> getDriverAvailability() async {
    if (_uid == null) return false;
    final doc = await _db.collection('drivers').doc(_uid).get();
    return doc.exists && doc.data()?['isAvailable'] == true;
  }

  /// Lista de UID-uri către care are voie să notifice cursa: contacte din telefon cu cont Nabour + prieteni acceptați.
  /// Fără intrări, cursa nu poate fi trimisă (aceeași regulă ca la rezervarea vocală).
  Future<List<String>> _ensureAllowedDriverUidsOrThrow(List<String>? existing) async {
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final merged = await PassengerAllowedDriverUids.loadMergedUidList();
    if (merged.isEmpty) {
      throw Exception(
        'Nabour sends the request only to drivers from your contacts. '
        'Add your friends\' phone numbers to contacts, or grant contacts permission.',
      );
    }
    return merged;
  }

  Future<String> requestRide(Ride ride) async {
    // ✅ ERROR HANDLING: Complete error handling pentru funcție critică
    try {
      if (_uid == null) {
        Logger.error('User not authenticated for ride request', tag: 'FIRESTORE');
        throw Exception("User not authenticated.");
      }
    
      // ✅ VALIDARE: Verifică dacă utilizatorul are deja o cursă activă
      // NOTĂ: Nu aruncăm excepție direct - returnăm informații pentru dialog de confirmare
      final activeRides = await SafeFirestoreOperations.safeFirestoreOperation<QuerySnapshot>(
        'check_active_rides',
        () => _db.collection('ride_requests')
          .where('passengerId', isEqualTo: _uid)
          .where('status', whereIn: ['pending', 'accepted', 'driver_found', 'in_progress', 'searching'])
          .limit(1)
          .get(),
      );
      
      if (activeRides == null) {
        Logger.error('Failed to check active rides', tag: 'FIRESTORE');
        throw Exception('Error checking active ride. Please try again.');
      }
      
      // ✅ NOU: Returnăm informații despre cursa activă în loc să aruncăm excepție
      // UI-ul va afișa un dialog de confirmare
      if (activeRides.docs.isNotEmpty) {
        final activeRideId = activeRides.docs.first.id;
        final activeRideData = activeRides.docs.first.data() as Map<String, dynamic>?;
        final activeRideStatus = activeRideData?['status'] as String?;
        Logger.warning('User already has an active ride: $activeRideId (status: $activeRideStatus)', tag: 'FIRESTORE');
        
        // ✅ Aruncăm o excepție specială care conține informații despre cursa activă
        throw ActiveRideException(
          activeRideId: activeRideId,
          activeRideStatus: activeRideStatus ?? 'unknown',
          message: 'You already have an active ride. Do you want to cancel it to create a new one?',
        );
      }
  
      final allowedDriverUids = await _ensureAllowedDriverUidsOrThrow(ride.allowedDriverUids);

      // Deducere token pentru postarea cursei (1 token)
      unawaited(TokenService().spend(TokenTransactionType.broadcastPost,
          customDescription: 'Ride post: ${ride.startAddress} -> ${ride.destinationAddress}'));

      final rideData = ride.toMap();
      rideData['passengerId'] = _uid;  // ✅ MODIFICAT: userId → passengerId
      rideData['timestamp'] = FieldValue.serverTimestamp();
      rideData['allowedDriverUids'] = allowedDriverUids;
      rideData['searchRadius'] = PassengerDriverSearchConfig.initialRadiusKm;
      rideData['searchStartTime'] = FieldValue.serverTimestamp();

      Logger.info('Creating ride for user: $_uid', tag: 'FIRESTORE');
      
      final docRef = await SafeFirestoreOperations.safeFirestoreOperation<DocumentReference>(
        'create_ride',
        () => _db.collection('ride_requests').add(rideData),
      );
      
      if (docRef == null) {
        Logger.error('Failed to create ride', tag: 'FIRESTORE');
        throw Exception('Error creating ride. Please try again.');
      }
      
      Logger.info('Ride created with ID: ${docRef.id}', tag: 'FIRESTORE');

      final rideForSearch = Ride.fromMap(
        Map<String, dynamic>.from(ride.toMap())
          ..['id'] = docRef.id
          ..['allowedDriverUids'] = allowedDriverUids,
      );
  
      // ✅ ERROR HANDLING: Start driver search în background (nu blochează)
      unawaited(_startAutomaticDriverSearch(docRef.id, rideForSearch).catchError((e) {
        Logger.error('Error starting automatic driver search', error: e, tag: 'FIRESTORE');
      }));
  
      return docRef.id;
    } on FirebaseException catch (e) {
      Logger.critical('Firebase error in requestRide: ${e.code}', error: e, tag: 'FIRESTORE');
      throw Exception('Firebase error: ${e.message ?? e.code}');
    } on Exception catch (e) {
      Logger.error('Exception in requestRide', error: e, tag: 'FIRESTORE');
      rethrow;
    } catch (e, stackTrace) {
      Logger.critical('Unexpected error in requestRide', error: e, stackTrace: stackTrace, tag: 'FIRESTORE');
      throw Exception('Unexpected error while creating ride: $e');
    }
  }

  // ✅ ÎMBUNĂTĂȚIT: Metoda pentru crearea unui RideRequest direct (cu validări complete + ERROR HANDLING)
  Future<String> createRideRequest(RideRequest rideRequest) async {
    // ✅ ERROR HANDLING: Complete error handling pentru funcție critică
    try {
      if (_uid == null) {
        Logger.error('User not authenticated for createRideRequest', tag: 'FIRESTORE');
        throw Exception("User not authenticated.");
      }
    
      // ✅ VALIDARE 1: Verifică dacă utilizatorul are deja o cursă activă
      final activeRides = await SafeFirestoreOperations.safeFirestoreOperation<QuerySnapshot>(
        'check_active_rides_create',
        () => _db.collection('ride_requests')
          .where('passengerId', isEqualTo: _uid)
          .where('status', whereIn: ['pending', 'accepted', 'driver_found', 'in_progress', 'searching'])
          .limit(1)
          .get(),
      );
      
      if (activeRides == null) {
        Logger.error('Failed to check active rides in createRideRequest', tag: 'FIRESTORE');
        throw Exception('Error checking active ride. Please try again.');
      }
      
      if (activeRides.docs.isNotEmpty) {
        final activeRideId = activeRides.docs.first.id;
        final activeRideData = activeRides.docs.first.data() as Map<String, dynamic>?;
        final activeRideStatus = activeRideData?['status'] as String?;
        Logger.warning('User already has an active ride: $activeRideId (status: $activeRideStatus)', tag: 'FIRESTORE');
        throw ActiveRideException(
          activeRideId: activeRideId,
          activeRideStatus: activeRideStatus ?? 'unknown',
          message: 'You already have an active ride. Cancel it before creating a new one.',
        );
      }

      // ✅ VALIDARE 2: Verifică coordonatele
      final pickupLat = rideRequest.pickupLatitude;
      final pickupLng = rideRequest.pickupLongitude;
      final destLat = rideRequest.destinationLatitude;
      final destLng = rideRequest.destinationLongitude;
    
      if (pickupLat == null || pickupLng == null || destLat == null || destLng == null) {
        Logger.warning('Incomplete coordinates in createRideRequest', tag: 'FIRESTORE');
        throw Exception('Coordinates are incomplete. All coordinates are required.');
      }
    
      // ✅ VALIDARE 3: Verifică range-ul coordonatelor
      if (pickupLat < -90 || pickupLat > 90 || pickupLng < -180 || pickupLng > 180) {
        Logger.warning('Invalid pickup coordinates: $pickupLat, $pickupLng', tag: 'FIRESTORE');
        throw Exception('Pickup coordinates are invalid.');
      }
    
      if (destLat < -90 || destLat > 90 || destLng < -180 || destLng > 180) {
        Logger.warning('Invalid destination coordinates: $destLat, $destLng', tag: 'FIRESTORE');
        throw Exception('Destination coordinates are invalid.');
      }
    
      // ✅ VALIDARE 4: Calculează și validează distanța
      final distance = _calculateHaversineDistance(pickupLat, pickupLng, destLat, destLng);
    
      if (distance < 0.1) {
        Logger.warning('Distance too small: $distance km', tag: 'FIRESTORE');
        throw Exception('Distance is too short. Minimum distance is 100 meters.');
      }
    
      if (distance > 200) {
        Logger.warning('Distance too large: $distance km', tag: 'FIRESTORE');
        throw Exception('Distance is too long. Maximum distance is 200 km.');
      }

      final allowedDriverUids =
          await _ensureAllowedDriverUidsOrThrow(rideRequest.allowedDriverUids);
    
      final rideData = rideRequest.toMap();
      rideData['passengerId'] = _uid;
      rideData['timestamp'] = FieldValue.serverTimestamp();
      rideData['allowedDriverUids'] = allowedDriverUids;
      rideData['searchRadius'] = PassengerDriverSearchConfig.initialRadiusKm;
      rideData['searchStartTime'] = FieldValue.serverTimestamp();
      rideData['distance'] = distance;
      // Aliasuri canonice — câmpurile pe care Ride.fromFirestore() și
      // _processRidesInBackground() le citesc. RideRequest.toMap() le scrie
      // cu nume diferite (pickupLocation, pickupLatitude etc.), deci le adăugăm
      // explicit pentru compatibilitate cu restul fluxului.
      rideData['startAddress'] = rideRequest.pickupLocation;
      rideData['destinationAddress'] = rideRequest.destination;
      rideData['startLatitude'] = rideRequest.pickupLatitude;
      rideData['startLongitude'] = rideRequest.pickupLongitude;
      // destinationLatitude / destinationLongitude sunt deja corecte în toMap()
      rideData['totalCost'] = (rideData['totalCost'] as num?)?.toDouble() ?? (rideData['estimatedPrice'] as num?)?.toDouble() ?? 0.0;
      rideData['baseFare'] = (rideData['baseFare'] as num?)?.toDouble() ?? 0.0;
      rideData['perKmRate'] = (rideData['perKmRate'] as num?)?.toDouble() ?? 0.0;
      rideData['perMinRate'] = (rideData['perMinRate'] as num?)?.toDouble() ?? 0.0;
      rideData['driverEarnings'] = (rideData['driverEarnings'] as num?)?.toDouble() ?? 0.0;
      rideData['appCommission'] = (rideData['appCommission'] as num?)?.toDouble() ?? 0.0;
      rideData['declinedBy'] = List<String>.from(rideData['declinedBy'] as List? ?? []);
      rideData['stops'] = rideData['stops'] ?? [];
    
      // Deducere token pentru postarea cursei (1 token)
      unawaited(TokenService().spend(TokenTransactionType.broadcastPost,
          customDescription: 'Voice ride post: ${rideRequest.pickupLocation} -> ${rideRequest.destination}'));

      Logger.info('Creating ride request for user: $_uid (distance: ${distance.toStringAsFixed(2)} km)', tag: 'FIRESTORE');

      final docRef = await SafeFirestoreOperations.safeFirestoreOperation<DocumentReference>(
        'create_ride_request',
        () => _db.collection('ride_requests').add(rideData),
      );
      
      if (docRef == null) {
        Logger.error('Failed to create ride request', tag: 'FIRESTORE');
        throw Exception('Error creating ride request. Please try again.');
      }
      
      Logger.info('Ride request created with ID: ${docRef.id}', tag: 'FIRESTORE');
    
      // Construiește un Ride minimal cu câmpurile canonice pentru a putea
      // folosi _startAutomaticDriverSearch (aceeași logică ca fluxul manual).
      final rideForSearch = Ride(
        id: docRef.id,
        passengerId: _uid!,
        startAddress: rideRequest.pickupLocation,
        destinationAddress: rideRequest.destination,
        distance: distance,
        startLatitude: rideRequest.pickupLatitude,
        startLongitude: rideRequest.pickupLongitude,
        destinationLatitude: rideRequest.destinationLatitude,
        destinationLongitude: rideRequest.destinationLongitude,
        baseFare: 0, perKmRate: 0, perMinRate: 0,
        totalCost: 0, appCommission: 0, driverEarnings: 0,
        timestamp: DateTime.now(),
        status: 'pending',
        category: RideCategory.values.firstWhere(
          (e) => e.name == rideRequest.category,
          orElse: () => RideCategory.standard,
        ),
        allowedDriverUids: allowedDriverUids,
      );

      // Start driver search în background cu aceeași logică ca requestRide()
      try {
        unawaited(_startAutomaticDriverSearch(docRef.id, rideForSearch).catchError((e) {
          Logger.error('Error starting automatic driver search', error: e, tag: 'FIRESTORE');
        }));
      } catch (e) {
        Logger.warning('Error starting driver search: $e', tag: 'FIRESTORE');
      }
    
      return docRef.id;
    } on FirebaseException catch (e) {
      Logger.critical('Firebase error in createRideRequest: ${e.code}', error: e, tag: 'FIRESTORE');
      throw Exception('Firebase error: ${e.message ?? e.code}');
    } on Exception catch (e) {
      Logger.error('Exception in createRideRequest', error: e, tag: 'FIRESTORE');
      rethrow;
    } catch (e, stackTrace) {
      Logger.critical('Unexpected error in createRideRequest', error: e, stackTrace: stackTrace, tag: 'FIRESTORE');
      throw Exception('Unexpected error while creating ride request: $e');
    }
  }
  
  // ✅ Helper: Calculează distanța folosind formula Haversine
  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadiansHaversine(lat2 - lat1);
    final dLon = _degreesToRadiansHaversine(lon2 - lon1);
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final a = sinDLat * sinDLat +
        math.cos(_degreesToRadiansHaversine(lat1)) * math.cos(_degreesToRadiansHaversine(lat2)) *
        sinDLon * sinDLon;
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
  
  double _degreesToRadiansHaversine(double degrees) => degrees * math.pi / 180;


  Future<void> _assignRideToDriver(String rideId, Map<String, dynamic> driverInfo) async {
    final driverId = driverInfo['driverId'] as String;
    final distance = driverInfo['distance'] as double;
    
    Logger.debug('Auto-assigning ride $rideId to driver $driverId (${distance.toStringAsFixed(1)}km away)');
    
    try {
      await SafeFirestoreOperations.safeFirestoreOperation(
        'assignRideToDriver_$rideId',
        () => _db.collection('ride_requests').doc(rideId).update({
          'status': 'driver_found',
          'driverId': driverId,
          'driverAcceptanceStatus': 'awaiting_acceptance',
          'driverAssignedAt': FieldValue.serverTimestamp(),
          'assignedAt': FieldValue.serverTimestamp(),
          'assignmentMethod': 'automatic',
          'driverDistance': distance,
        }),
      );

      // Send push notification to driver
      unawaited(PushNotificationService.triggerDriverAssignment(
        driverId: driverId,
        rideId: rideId,
        distanceKm: distance,
      ));

      Timer(const Duration(seconds: 25), () async {
        final rideDoc = await _db.collection('ride_requests').doc(rideId).get();
        if (!rideDoc.exists) return;
        final data = rideDoc.data()!;
        if (data['status'] == 'driver_found' &&
            data['driverAcceptanceStatus'] == 'awaiting_acceptance') {
          Logger.debug('Driver $driverId did not respond for ride $rideId, resuming search.');
          await _handleDriverNoResponse(rideId, driverId);
        }
      });
    } catch (e) {
      Logger.error('Error assigning ride to driver: $e', error: e);
    }
  }

  Future<void> _handleDriverNoResponse(String rideId, String driverId) async {
    try {
      await SafeFirestoreOperations.safeFirestoreOperation(
        'handleDriverNoResponse_$rideId',
        () async {
          final docRef = _db.collection('ride_requests').doc(rideId);
          final snapshot = await docRef.get();
          if (!snapshot.exists) return;
          final data = snapshot.data()!;
          if (data['status'] != 'driver_found') {
            return;
          }

          await docRef.update({
            'status': 'pending',
            'driverId': FieldValue.delete(),
            'driverAcceptanceStatus': 'timeout',
            'driverTimeoutAt': FieldValue.serverTimestamp(),
            'declinedBy': FieldValue.arrayUnion([driverId]),
            'systemLogs': FieldValue.arrayUnion([
              {
                'type': 'auto_reassign',
                'message':
                    'Driver did not respond in time, ride returned to pending.',
                'driverId': driverId,
                'timestamp': Timestamp.now(), // ✅ FIX: Folosește Timestamp.now() în loc de FieldValue.serverTimestamp() în arrayUnion
              }
            ]),
          });

          final Ride ride = Ride.fromMap({
            ...data,
            'id': rideId,
          });

          await _searchDriversInRadius(
            rideId,
            ride,
            data['searchRadius'] is num
                ? (data['searchRadius'] as num).toDouble()
                : (ride.searchRadius ?? 3.0),
          );

          PushNotificationService.triggerDriverTimeout(
            driverId: driverId,
            rideId: rideId,
          );
          PushNotificationService.notifyPassengerNoDriver(
            passengerId: data['passengerId'] as String,
            rideId: rideId,
          );
        },
      );
    } catch (e) {
      Logger.error('Error handling driver no response: $e', error: e);
    }
  }

  Stream<List<Ride>> getRidesHistory({DateFilter filter = DateFilter.all, int? limit}) {
    if (_uid == null) return Stream.value([]);

    // Only this passenger's completed rides — matches Firestore rules (no global completed scan).
    return _db
        .collection('ride_requests')
        .where('passengerId', isEqualTo: _uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          List<Ride> passengerRides = snapshot.docs
              .map((doc) => Ride.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList();

          if (limit != null && passengerRides.length > limit) {
            passengerRides = passengerRides.take(limit).toList();
          }
          
          if (filter == DateFilter.all) {
            return passengerRides;
          }
          
          final DateTime now = DateTime.now();
          DateTime? startDate;

          switch (filter) {
            case DateFilter.today:
              startDate = DateTime(now.year, now.month, now.day);
              break;
            case DateFilter.lastWeek:
              startDate = now.subtract(const Duration(days: 7));
              break;
            case DateFilter.lastMonth:
              startDate = DateTime(now.year, now.month - 1, now.day);
              break;
            case DateFilter.last3Months:
              startDate = DateTime(now.year, now.month - 3, now.day);
              break;
            case DateFilter.thisYear:
              startDate = DateTime(now.year);
              break;
            case DateFilter.all:
              break;
          }

          if (startDate != null) {
            return passengerRides.where((ride) => ride.timestamp.isAfter(startDate!)).toList();
          }
          
          return passengerRides;
        });
  }
  
  Future<void> deleteRide(String rideId) async {
    if (_uid == null) return;
    final rideDoc = await _db.collection('ride_requests').doc(rideId).get();
    if (rideDoc.exists && rideDoc.data()?['passengerId'] == _uid) {  // ✅ MODIFICAT: userId → passengerId
      await _db.collection('ride_requests').doc(rideId).delete();
      Logger.debug('Ride $rideId deleted by user $_uid');
    } else {
      Logger.debug('User $_uid attempted to delete ride $rideId without permission.');
      throw Exception("You don't have permission to delete this ride.");
    }
  }

  Stream<List<Ride>> getDriverAcceptedRides() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('ride_requests')
        .where('driverId', isEqualTo: _uid)
        .where('status', whereIn: ['accepted', 'arrived'])
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Ride.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList());
  }
  
  Future<void> sendChatMessage(
    String rideId,
    String text, {
    String? quickReplyId,
    Map<String, dynamic>? locationData,
    MessageType type = MessageType.text,
    String? voiceUrl,
    int? voiceDuration,
    String? imageUrl,
    String? gifUrl,
    String? gifId,
  }) async {
    if (_uid == null) return;
    if (type != MessageType.voice && type != MessageType.image && type != MessageType.gif && text.trim().isEmpty) return;
    if (type == MessageType.voice && voiceUrl == null) return;
    if (type == MessageType.image && imageUrl == null) return;
    if (type == MessageType.gif && gifUrl == null) return;

    String? senderPhoto;
    var senderEmoji = '🙂';
    try {
      final u = await _db.collection('users').doc(_uid!).get();
      final d = u.data();
      final raw = d?['photoURL'];
      if (raw is String && raw.trim().isNotEmpty) senderPhoto = raw.trim();
      final av = d?['avatar'];
      if (av is String && av.trim().isNotEmpty) senderEmoji = av.trim();
    } catch (e) {
      Logger.debug('FirestoreService: sender profile fetch failed: $e', tag: 'FIRESTORE');
    }
    final authPhoto = _auth.currentUser?.photoURL?.trim();
    if ((senderPhoto == null || senderPhoto.isEmpty) &&
        authPhoto != null &&
        authPhoto.isNotEmpty) {
      senderPhoto = authPhoto;
    }

    final message = ChatMessage(
      senderId: _uid!,
      text: type == MessageType.voice ? '🎤 Voice message' : text.trim(),
      timestamp: Timestamp.now(),
      type: type,
      quickReplyId: quickReplyId,
      locationData: locationData,
      voiceUrl: voiceUrl,
      voiceDuration: voiceDuration,
      imageUrl: imageUrl,
      gifUrl: gifUrl,
      gifId: gifId,
      senderPhotoUrl: senderPhoto,
      senderAvatarEmoji: senderEmoji,
    );
    
    final messageRef = await _db
        .collection('ride_requests')
        .doc(rideId)
        .collection('chat')
        .add(message.toMap());
    
    // Marchează mesajul ca livrat imediat după trimitere
    await messageRef.update({
      'deliveredAt': FieldValue.serverTimestamp(),
      'status': MessageStatus.delivered.name,
    });
    
    // Trimite notificare push (dacă nu este mesaj de sistem)
    if (type != MessageType.system) {
      await _sendChatPushNotification(rideId, text);
    }
  }

  /// Trimite notificare push pentru mesaj nou
  Future<void> _sendChatPushNotification(String rideId, String messageText) async {
    try {
      // Obține informații despre cursă
      final rideDoc = await _db.collection('ride_requests').doc(rideId).get();
      if (!rideDoc.exists) return;
      
      final rideData = rideDoc.data()!;
      final currentUserId = _uid;
      final isDriver = currentUserId == rideData['driverId'];
      final otherUserId = isDriver ? rideData['passengerId'] : rideData['driverId'];
      
      if (otherUserId == null) return;
      
      // Obține FCM token pentru celălalt utilizator
      final otherUserDoc = await _db.collection('users').doc(otherUserId).get();
      if (!otherUserDoc.exists) return;
      
      final fcmToken = otherUserDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) return;
      
      // Obține numele expeditorului
      final senderName = isDriver ? 'Driver' : 'Passenger';
      
      // Note: Push notification will be sent via Cloud Function in future update
      // For now, only log
      Logger.info('Chat notification: $senderName: ${messageText.substring(0, messageText.length > 50 ? 50 : messageText.length)}...', tag: 'PUSH');
      
    } catch (e) {
      Logger.error('Error sending chat push notification: $e', error: e);
    }
  }

  /// Marchează mesajul ca citit
  Future<void> markMessagesAsReadBatch(String rideId, List<String> messageIds) async {
    if (_uid == null || messageIds.isEmpty) return;
    try {
      final batch = _db.batch();
      final now = FieldValue.serverTimestamp();
      for (final id in messageIds) {
        final ref = _db
            .collection('ride_requests')
            .doc(rideId)
            .collection('chat')
            .doc(id);
        batch.update(ref, {'readAt': now, 'status': MessageStatus.read.name});
      }
      await batch.commit();
    } catch (e) {
      Logger.error('Error batch marking messages as read: $e', error: e);
    }
  }

  Future<void> markMessageAsRead(String rideId, String messageId) async {
    if (_uid == null) return;
    
    try {
      await _db
          .collection('ride_requests')
          .doc(rideId)
          .collection('chat')
          .doc(messageId)
          .update({
        'readAt': FieldValue.serverTimestamp(),
        'status': MessageStatus.read.name,
      });
    } catch (e) {
      Logger.error('Error marking message as read: $e', error: e);
    }
  }

  /// Marchează toate mesajele ca citite pentru o cursă
  Future<void> markAllMessagesAsRead(String rideId) async {
    if (_uid == null) return;
    
    try {
      final messages = await _db
          .collection('ride_requests')
          .doc(rideId)
          .collection('chat')
          .where('senderId', isNotEqualTo: _uid)
          .where('status', isNotEqualTo: MessageStatus.read.name)
          .get();
      
      final batch = _db.batch();
      for (final doc in messages.docs) {
        batch.update(doc.reference, {
          'readAt': FieldValue.serverTimestamp(),
          'status': MessageStatus.read.name,
        });
      }
      
      await batch.commit();
    } catch (e) {
      Logger.error('Error marking all messages as read: $e', error: e);
    }
  }

  /// Setează typing indicator
  Future<void> setTypingIndicator(String rideId, bool isTyping) async {
    if (_uid == null) return;
    
    try {
      await _db
          .collection('ride_requests')
          .doc(rideId)
          .update({
        'typing': {
          _uid!: {
            'isTyping': isTyping,
            'timestamp': FieldValue.serverTimestamp(),
          },
        },
      });
    } catch (e) {
      Logger.error('Error setting typing indicator: $e', error: e);
    }
  }

  /// Obține typing indicator pentru o cursă
  Stream<Map<String, dynamic>?> getTypingIndicator(String rideId) {
    return _db
        .collection('ride_requests')
        .doc(rideId)
        .snapshots()
        .map((doc) => doc.data()?['typing'] as Map<String, dynamic>?);
  }

  /// Trimite mesaj de sistem
  Future<void> sendSystemMessage(String rideId, String text) async {
    await sendChatMessage(
      rideId,
      text,
      type: MessageType.system,
    );
  }

  // ✅ FIX: Metodă pentru editarea mesajelor de chat
  Future<void> editChatMessage(String rideId, String messageId, String newText) async {
    if (_uid == null || newText.trim().isEmpty) return;
    
    try {
      final messageRef = _db.collection('ride_requests').doc(rideId).collection('chat').doc(messageId);
      final messageDoc = await messageRef.get();
      
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }
      
      final messageData = messageDoc.data();
      if (messageData == null || messageData['senderId'] != _uid) {
        throw Exception('You cannot edit other users\' messages');
      }
      
      await messageRef.update({
        'text': newText.trim(),
        'editedAt': FieldValue.serverTimestamp(),
        'isEdited': true,
      });
      
      Logger.info('Chat message edited successfully');
    } catch (e) {
      Logger.error('Error editing chat message: $e', error: e);
      rethrow;
    }
  }

  // ✅ NOU: Metodă pentru a salva traducerea unui mesaj
  Future<void> translateChatMessage(String rideId, String messageId, String translatedText) async {
    if (_uid == null || translatedText.trim().isEmpty) return;
    
    try {
      final messageRef = _db.collection('ride_requests').doc(rideId).collection('chat').doc(messageId);
      await messageRef.update({
        'translatedText': translatedText.trim(),
      });
      Logger.info('Chat message translated successfully');
    } catch (e) {
      Logger.error('Error translating chat message: $e', error: e);
      rethrow;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getChatMessages(String rideId) {
    return _db
        .collection('ride_requests')
        .doc(rideId)
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .limit(60)
        .snapshots();
  }

  Future<void> cancelRide(String rideId) async {
    if (_uid == null) throw Exception("User not authenticated.");
    
    final rideRef = _db.collection('ride_requests').doc(rideId);
    final rideDoc = await rideRef.get();
    
    if (!rideDoc.exists) {
      Logger.debug("Ride $rideId not found for cancellation.");
      return;
    }
    
    final ride = Ride.fromFirestore(rideDoc);
    
    if (ride.status == 'completed' || ride.status == 'cancelled') {
      Logger.info("Ride $rideId is already completed or cancelled.");
      return;
    }
    
    double fee = 0.0;

    // ✅ Pentru status "searching" sau "pending", nu se aplică taxă de anulare
    if (ride.status == 'accepted' || ride.status == 'arrived') {
      // Taxa este 30 RON sau prețul preafișat al cursei (se va debita valoarea cea mai mică)
      fee = math.min(30.0, ride.totalCost);
    }

    _addToBatch('ride_requests', rideId, {
      'status': 'cancelled',
      'cancelledBy': _uid,
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancellationFee': fee > 0 ? fee : FieldValue.delete(),
    });
    
    // ✅ EXECUTĂ BATCH-UL pentru a aplica modificările
    await _processBatch();
  }
  
  /// ✅ NOU: Anulează automat toate cursele blocate pentru user-ul curent (pentru testare)
  Future<void> cancelAllStuckRides() async {
    if (_uid == null) return;
    
    try {
      Logger.info('🧹 Cancelling all stuck rides for user: $_uid', tag: 'FIRESTORE');
      
      // Găsește toate cursele blocate (inclusiv "searching")
      final stuckRides = await _db.collection('ride_requests')
          .where('passengerId', isEqualTo: _uid)
          .where('status', whereIn: ['searching', 'pending', 'driver_found', 'accepted', 'arrived', 'in_progress'])
          .get();
      
      if (stuckRides.docs.isEmpty) {
        Logger.debug('No stuck rides to cancel', tag: 'FIRESTORE');
        return;
      }
      
      final batch = _db.batch();
      int cancelledCount = 0;
      
      for (final doc in stuckRides.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        
        // Pentru status "searching" sau "pending", anulează fără taxă
        batch.update(doc.reference, {
          'status': 'cancelled',
          'cancelledBy': _uid,
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledReason': 'auto_cancel_stuck_ride',
          'systemLogs': FieldValue.arrayUnion([
            {
              'type': 'auto_cancel_stuck_ride',
              'message': 'Stuck ride automatically cancelled (status: $status)',
              'previousStatus': status,
              'timestamp': Timestamp.now(), // ✅ FIX: Folosește Timestamp.now() în loc de FieldValue.serverTimestamp() în arrayUnion
              'triggeredBy': 'manual_cleanup',
            }
          ]),
        });
        cancelledCount++;
      }
      
      if (cancelledCount > 0) {
        await batch.commit();
        Logger.info('✅ Cancelled $cancelledCount stuck rides for user $_uid', tag: 'FIRESTORE');
      }
    } catch (e) {
      Logger.error('❌ Error cancelling stuck rides', error: e, tag: 'FIRESTORE');
    }
  }

  Future<void> passengerDeclineDriver(String rideId) async {
    Logger.debug('Passenger declining driver for ride $rideId');
    final rideDoc = await _db.collection('ride_requests').doc(rideId).get();
    if (!rideDoc.exists || rideDoc.data()?['driverId'] == null) return;

    final data = rideDoc.data()!;
    final driverId = data['driverId'] as String;

    // Revenim la pending și adăugăm șoferul în lista de excluși
    await _db.collection('ride_requests').doc(rideId).update({
      'status': 'pending',
      'driverId': FieldValue.delete(),
      'declinedBy': FieldValue.arrayUnion([driverId]),
      'passengerDeclinedDrivers': FieldValue.arrayUnion([driverId]),
    });

    Logger.info('Passenger declined driver $driverId — searching for next driver', tag: 'FIRESTORE');

    // Repornim căutarea cu aceeași rază (șoferul tocmai refuzat e deja în declinedBy)
    final ride = Ride.fromMap({...data, 'id': rideId});
    final searchRadius = data['searchRadius'] is num
        ? (data['searchRadius'] as num).toDouble()
        : 5.0;
    await _searchDriversInRadius(rideId, ride, searchRadius);
  }

  Future<String?> logEmergencyEvent({
    required String rideId,
    required String triggeredByUserId,
    required String userRole,
    required String eventType,
    GeoPoint? location,
    String? rideStatus,
    String? note,
    Map<String, dynamic>? metadata,
  }) async {
    return SafeFirestoreOperations.safeFirestoreOperation<String>(
        'logEmergencyEvent_$rideId', () async {
      final docRef = _db.collection('ride_emergency_events').doc();
      final now = FieldValue.serverTimestamp();
      final payload = <String, dynamic>{
        'rideId': rideId,
        'triggeredBy': triggeredByUserId,
        'userRole': userRole,
        'eventType': eventType,
        'status': 'triggered',
        'rideStatus': rideStatus,
        'note': note,
        'createdAt': now,
        'updatedAt': now,
      };
      if (location != null) {
        payload['location'] = location;
      }
      if (metadata != null && metadata.isNotEmpty) {
        payload['metadata'] = metadata;
      }
      await docRef.set(payload);
      return docRef.id;
    });
  }

  Future<void> updateEmergencyEventStatus(
    String eventId, {
    required String status,
    String? note,
    Map<String, dynamic>? metadata,
  }) async {
    await SafeFirestoreOperations.safeFirestoreOperation(
        'updateEmergencyEventStatus_$eventId', () async {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (note != null) {
        updateData['note'] = note;
      }
      if (metadata != null && metadata.isNotEmpty) {
        updateData['metadataLogs'] = FieldValue.arrayUnion([metadata]);
      }
      await _db.collection('ride_emergency_events').doc(eventId).set(
            updateData,
            SetOptions(merge: true),
          );
    });
  }

  /// Actualizează permisiunile utilizatorului
  Future<void> updateUserPermissions(Map<String, dynamic> permissions) async {
    if (_uid == null) return;
    
    try {
      await _db.collection('users').doc(_uid).update({
        'permissions': permissions,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      Logger.info('User permissions updated');
    } catch (e) {
      Logger.error('Error updating user permissions: $e', error: e);
      rethrow;
    }
  }

  /// Actualizează token-ul FCM pentru notificări push
  Future<void> updateUserFCMToken(String? token) async {
    if (_uid == null || token == null) return;
    
    try {
      await _db.collection('users').doc(_uid).set({
        'fcmToken': token,
        'fcmTokenUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      Logger.info('FCM token updated');
    } catch (e) {
      Logger.error('Error updating FCM token: $e', error: e);
    }
  }

  /// Verifică dacă utilizatorul a completat onboarding-ul
  Future<bool> hasCompletedOnboarding() async {
    if (_uid == null) return false;
    
    try {
      final doc = await _db.collection('users').doc(_uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['permissions']?['onboarding_completed'] ?? false;
      }
      return false;
    } catch (e) {
      Logger.error('Error checking onboarding status: $e', error: e);
      return false;
    }
  }

  /// ✅ NOU: Obține balanța wallet-ului utilizatorului
  Future<double> getWalletBalance() async {
    if (_uid == null) return 0.0;
    
    try {
      final doc = await _db.collection('users').doc(_uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['walletBalance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      Logger.error('Error getting wallet balance', error: e, tag: 'FIRESTORE');
      return 0.0;
    }
  }

  /// ✅ NOU: Obține metodele de plată ale utilizatorului
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    if (_uid == null) return [];
    
    try {
      final snapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('payment_methods')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'card',
          'brand': data['brand'] ?? '',
          'last4': data['last4'],
          'holderName': data['holderName'],
          'canSendToContact': data['canSendToContact'] ?? false,
          'isDefault': data['isDefault'] ?? false,
          'expiryMonth': data['expiryMonth'],
          'expiryYear': data['expiryYear'],
        };
      }).toList();
    } catch (e) {
      Logger.error('Error getting payment methods', error: e, tag: 'FIRESTORE');
      return [];
    }
  }

  /// ✅ NOU: Obține numărul de vouchere active ale utilizatorului
  Future<int> getVoucherCount() async {
    if (_uid == null) return 0;
    
    try {
      final snapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('vouchers')
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      Logger.error('Error getting voucher count', error: e, tag: 'FIRESTORE');
      return 0;
    }
  }

  /// ✅ NOU: Stream pentru balanța wallet-ului
  Stream<double> getWalletBalanceStream() {
    if (_uid == null) return Stream.value(0.0);
    
    return _db
        .collection('users')
        .doc(_uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['walletBalance'] as num?)?.toDouble() ?? 0.0;
          }
          return 0.0;
        });
  }

  /// ✅ NOU: Stream pentru metodele de plată
  Stream<List<Map<String, dynamic>>> getPaymentMethodsStream() {
    if (_uid == null) return Stream.value([]);
    
    return _db
        .collection('users')
        .doc(_uid)
        .collection('payment_methods')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'type': data['type'] ?? 'card',
              'brand': data['brand'] ?? '',
              'last4': data['last4'],
              'holderName': data['holderName'],
              'canSendToContact': data['canSendToContact'] ?? false,
              'isDefault': data['isDefault'] ?? false,
              'expiryMonth': data['expiryMonth'],
              'expiryYear': data['expiryYear'],
            };
          }).toList();
        });
  }

  /// ✅ NOU: Șterge o metodă de plată
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    if (_uid == null) throw Exception("User not authenticated.");
    
    try {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('payment_methods')
          .doc(paymentMethodId)
          .delete();
      
      Logger.info('Payment method $paymentMethodId deleted', tag: 'FIRESTORE');
    } catch (e) {
      Logger.error('Error deleting payment method', error: e, tag: 'FIRESTORE');
      rethrow;
    }
  }

  /// ✅ NOU: Trimite cerere pentru profil business
  Future<void> requestBusinessProfile({
    required String companyName,
    required String companyEmail,
    String? companyPhone,
    String? notes,
  }) async {
    if (_uid == null) throw Exception("User not authenticated.");
    
    try {
      await _db.collection('business_profile_requests').add({
        'userId': _uid,
        'companyName': companyName,
        'companyEmail': companyEmail,
        'companyPhone': companyPhone,
        'notes': notes,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      Logger.info('Business profile request created for user $_uid', tag: 'FIRESTORE');
    } catch (e) {
      Logger.error('Error creating business profile request', error: e, tag: 'FIRESTORE');
      rethrow;
    }
  }

  /// ✅ NOU: Validează un cod de recomandare
  Future<Map<String, dynamic>> validateReferralCode(String code) async {
    if (_uid == null) {
      return {'success': false, 'message': 'User not authenticated.'};
    }
    
    try {
      // Verifică dacă codul există în Firestore
      final snapshot = await _db
          .collection('referral_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return {'success': false, 'message': 'Codul de recomandare este invalid sau expirat.'};
      }
      
      final referralData = snapshot.docs.first.data();
      final expiryDate = referralData['expiryDate'] as Timestamp?;
      
      // Verifică dacă codul a expirat
      if (expiryDate != null && expiryDate.toDate().isBefore(DateTime.now())) {
        return {'success': false, 'message': 'Codul de recomandare a expirat.'};
      }
      
      // Verifică dacă utilizatorul a folosit deja acest cod
      final userReferrals = await _db
          .collection('users')
          .doc(_uid)
          .collection('referrals')
          .where('referralCode', isEqualTo: code.toUpperCase())
          .get();
      
      if (userReferrals.docs.isNotEmpty) {
        return {'success': false, 'message': 'Ai folosit deja acest cod de recomandare.'};
      }
      
      // Salvează referal-ul pentru utilizator
      await _db.collection('users').doc(_uid).collection('referrals').add({
        'referralCode': code.toUpperCase(),
        'appliedAt': FieldValue.serverTimestamp(),
        'benefits': referralData['benefits'] ?? {},
      });
      
      Logger.info('Referral code $code applied for user $_uid', tag: 'FIRESTORE');
      
      return {
        'success': true,
        'message': 'Referral code applied successfully!',
        'benefits': referralData['benefits'] ?? {},
      };
    } catch (e) {
      Logger.error('Error validating referral code', error: e, tag: 'FIRESTORE');
      return {'success': false, 'message': 'Error validating referral code.'};
    }
  }

  /// DATABASE OPTIMIZATION: Search users with advanced filtering
  Future<List<Map<String, dynamic>>> searchUsersOptimized({
    required String query,
    required String field,
    int limit = 20,
    bool useCache = true,
  }) async {
    try {
      final cacheKey = 'users_search_${query}_${field}_$limit';
      
      if (useCache) {
        final cached = _getCached<List<Map<String, dynamic>>>(cacheKey);
        if (cached != null) return cached;
      }
      
      final usersRef = _db.collection('users');
      final querySnapshot = await usersRef
          .where(field, isGreaterThanOrEqualTo: query)
          .where(field, isLessThan: '$query\uf8ff')
          .limit(limit)
          .get();
      
      final users = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      
      _setCached(cacheKey, users, ttl: const Duration(minutes: 5));
      return users;
      
    } catch (e) {
      Logger.error('Error in searchUsersOptimized: $e', error: e);
      return [];
    }
  }

  /// DATABASE OPTIMIZATION: Find online drivers with geolocation
  Future<List<Map<String, dynamic>>> findOnlineDriversOptimized({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 10,
    bool useCache = true,
  }) async {
    try {
      final cacheKey = 'drivers_online_${latitude}_${longitude}_${radiusKm}_$limit';
      
      if (useCache) {
        final cached = _getCached<List<Map<String, dynamic>>>(cacheKey);
        if (cached != null) return cached;
      }
      
      final driversRef = _db.collection('drivers');
      final querySnapshot = await driversRef
          .where('isOnline', isEqualTo: true)
          .where('status', isEqualTo: 'available')
          .get();
      
      // Filter by distance
      final nearbyDrivers = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((driver) {
            final driverLat = driver['location']?['latitude'] ?? 0.0;
            final driverLng = driver['location']?['longitude'] ?? 0.0;
            final distance = _calculateDistance(latitude, longitude, driverLat, driverLng);
            return distance <= radiusKm;
          })
          .take(limit)
          .toList();
      
      _setCached(cacheKey, nearbyDrivers, ttl: const Duration(minutes: 2));
      return nearbyDrivers;
      
    } catch (e) {
      Logger.error('Error in findOnlineDriversOptimized: $e', error: e);
      return [];
    }
  }

  /// DATABASE OPTIMIZATION: Batch update with retry logic
  Future<bool> batchUpdateOptimized(List<Map<String, dynamic>> updates) async {
    try {
      final batch = _db.batch();
      
      for (final update in updates) {
        final docRef = _db.collection(update['collection']).doc(update['id']);
        batch.update(docRef, update['data']);
      }
      
      await batch.commit();
      Logger.info('Batch update completed: ${updates.length} documents');
      return true;
      
    } catch (e) {
      Logger.error('Error in batchUpdateOptimized: $e', error: e);
      return false;
    }
  }

  /// DATABASE OPTIMIZATION: Get ride history with pagination
  Future<List<Map<String, dynamic>>> getRideHistoryOptimized({
    required String userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    bool useCache = true,
  }) async {
    try {
      final cacheKey = 'ride_history_${userId}_$limit';
      
      if (useCache) {
        final cached = _getCached<List<Map<String, dynamic>>>(cacheKey);
        if (cached != null) return cached;
      }
      
      final ridesRef = _db.collection('rides');
      Query query = ridesRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final querySnapshot = await query.get();
      final rides = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data != null && data is Map<String, dynamic>) {
              return {'id': doc.id, ...data};
            }
            return {'id': doc.id};
          })
          .toList();
      
      _setCached(cacheKey, rides, ttl: const Duration(minutes: 10));
      return rides;
      
    } catch (e) {
      Logger.error('Error in getRideHistoryOptimized: $e', error: e);
      return [];
    }
  }

  /// Helper method to calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadiansDistance(lat2 - lat1);
    final dLon = _degreesToRadiansDistance(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadiansDistance(lat1)) * math.cos(_degreesToRadiansDistance(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Helper method to convert degrees to radians
  double _degreesToRadiansDistance(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  /// Get analytics data with optimization
  Future<Map<String, dynamic>> getAnalyticsOptimized({
    required String userId,
    required DateFilter filter,
    UserRole? userRole,
  }) async {
    try {
      final cacheKey = 'analytics_${userId}_${filter}_${userRole ?? 'all'}';

      // Check cache first
      final cached = _cache[cacheKey] as Map<String, dynamic>?;
      if (cached != null) {
        return cached;
      }

      // Build query based on filter
      Query query = FirebaseFirestore.instance.collection('rides');

      switch (filter) {
        case DateFilter.today:
          final today = DateTime.now();
          final startOfDay = DateTime(today.year, today.month, today.day);
          query = query.where('createdAt', isGreaterThanOrEqualTo: startOfDay);
          break;
        case DateFilter.lastWeek:
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          query = query.where('createdAt', isGreaterThanOrEqualTo: weekAgo);
          break;
        case DateFilter.lastMonth:
          final monthAgo = DateTime.now().subtract(const Duration(days: 30));
          query = query.where('createdAt', isGreaterThanOrEqualTo: monthAgo);
          break;
        case DateFilter.last3Months:
          final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
          query = query.where('createdAt', isGreaterThanOrEqualTo: threeMonthsAgo);
          break;
        case DateFilter.thisYear:
          final year = DateTime.now().year;
          final startOfYear = DateTime(year);
          query = query.where('createdAt', isGreaterThanOrEqualTo: startOfYear);
          break;
        case DateFilter.all:
          // No additional filtering needed for all time
          break;
      }

      if (userRole != null) {
        query = query.where('userRole', isEqualTo: userRole.toString());
      }

      final snapshot = await query.get();

      // Process analytics data
      final analytics = <String, dynamic>{
        'totalRides': snapshot.docs.length,
        'totalRevenue': 0.0,
        'averageRating': 0.0,
        'completedRides': 0,
        'cancelledRides': 0,
      };

      double totalRevenue = 0.0;
      double totalRating = 0.0;
      int ratingCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['status'] == 'completed') {
          analytics['completedRides'] = analytics['completedRides'] + 1;
          totalRevenue += (data['price'] ?? 0.0).toDouble();
        } else if (data != null && data['status'] == 'cancelled') {
          analytics['cancelledRides'] = analytics['cancelledRides'] + 1;
        }

        if (data != null && data['rating'] != null) {
          totalRating += (data['rating'] ?? 0.0).toDouble();
          ratingCount++;
        }
      }

      if (analytics['completedRides'] > 0) {
        analytics['totalRevenue'] = totalRevenue;
        analytics['averageRating'] = ratingCount > 0 ? totalRating / ratingCount : 0.0;
      }

      // Cache result for 15 minutes
      _cache[cacheKey] = analytics;

      return analytics;

    } catch (e) {
      Logger.error('Failed to get analytics: $e', tag: 'ANALYTICS', error: e);
      return <String, dynamic>{
        'totalRides': 0,
        'totalRevenue': 0.0,
        'averageRating': 0.0,
        'completedRides': 0,
        'cancelledRides': 0,
      };
    }
  }
  
  /// Cleanup expired data from cache and database
  Future<void> cleanupExpiredData({Duration maxAge = const Duration(days: 7)}) async {
    try {
      Logger.debug('Starting expired data cleanup...', tag: 'CLEANUP');

      final cutoffDate = DateTime.now().subtract(maxAge);

      // Cleanup expired cache entries
      final expiredCacheKeys = <String>[];
      for (final entry in _cache.entries) {
        if (entry.value is Map && entry.value['timestamp'] != null) {
          final timestamp = entry.value['timestamp'] as DateTime;
          if (timestamp.isBefore(cutoffDate)) {
            expiredCacheKeys.add(entry.key);
          }
        }
      }

      for (final key in expiredCacheKeys) {
        _cache.remove(key);
        _cacheTimers[key]?.cancel();
        _cacheTimers.remove(key);
      }

      // Cleanup expired location updates
      final expiredLocationKeys = <String>[];
      for (final entry in _lastLocationUpdate.entries) {
        if (entry.value.isBefore(cutoffDate)) {
          expiredLocationKeys.add(entry.key);
        }
      }

      for (final key in expiredLocationKeys) {
        _lastLocationUpdate.remove(key);
      }

      // Cleanup expired batch operations
      _pendingUpdates.removeWhere((update) {
        final timestamp = update['timestamp'] as DateTime?;
        return timestamp != null && timestamp.isBefore(cutoffDate);
      });

      Logger.info('Expired data cleanup completed. Removed ${expiredCacheKeys.length} cache entries, ${expiredLocationKeys.length} location updates', tag: 'CLEANUP');

    } catch (e) {
      Logger.error('Failed to cleanup expired data: $e', tag: 'CLEANUP', error: e);
    }
  }
  
  /// ✅ NOU: Pornește timer-ul automat pentru resetare curse blocate
  void startStuckRideCleanupTimer() {
    // Anulează timer-ul anterior dacă există
    _stuckRideCleanupTimer?.cancel();
    
    // Pornește timer periodic care verifică la fiecare 2 minute
    _stuckRideCleanupTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _autoCleanupStuckRides();
    });
    
    Logger.info('🔄 Stuck ride cleanup timer started (checks every 2 minutes)', tag: 'FIRESTORE');
    
    // Rulează imediat prima verificare
    _autoCleanupStuckRides();
  }
  
  /// ✅ NOU: Oprește timer-ul de cleanup
  void stopStuckRideCleanupTimer() {
    _stuckRideCleanupTimer?.cancel();
    _stuckRideCleanupTimer = null;
    Logger.info('🛑 Stuck ride cleanup timer stopped', tag: 'FIRESTORE');
  }
  
  /// Curăță cursele blocate doar unde utilizatorul curent este participant (conform rules).
  Future<void> _autoCleanupStuckRides() async {
    if (_uid == null) return;
    try {
      final now = DateTime.now();
      
      Logger.debug('🧹 Auto cleanup: Checking for stuck rides older than $_stuckRideThresholdMinutes minutes', tag: 'FIRESTORE');
      
      const stuckStatuses = ['searching', 'driver_found', 'accepted', 'arrived', 'in_progress'];
      final passengerSnap = await _db.collection('ride_requests')
          .where('passengerId', isEqualTo: _uid)
          .where('status', whereIn: stuckStatuses)
          .get();
      final driverSnap = await _db.collection('ride_requests')
          .where('driverId', isEqualTo: _uid)
          .where('status', whereIn: stuckStatuses)
          .get();

      final seen = <String>{};
      final stuckDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final d in [...passengerSnap.docs, ...driverSnap.docs]) {
        if (seen.add(d.id)) stuckDocs.add(d);
      }
      
      if (stuckDocs.isEmpty) {
        Logger.debug('🧹 Auto cleanup: No stuck rides found', tag: 'FIRESTORE');
        return;
      }
      
      final batch = _db.batch();
      int cleanedCount = 0;
      
      for (final doc in stuckDocs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        
        if (timestamp == null) continue;
        
        final rideTime = timestamp.toDate();
        final differenceInMinutes = now.difference(rideTime).inMinutes;
        
        // ✅ Verifică dacă cursa este blocată (praguri diferențiate pe status)
        final status = data['status'] as String?;
        int thresholdMinutes = _stuckRideThresholdMinutes; // Default 10
        
        switch (status) {
          case 'searching':
            thresholdMinutes = 5;
            break;
          case 'arrived':
            thresholdMinutes = 20; // 20 min max waiting
            break;
          case 'in_progress':
            thresholdMinutes = 60; // 1h safety net for active rides
            break;
          default:
            thresholdMinutes = _stuckRideThresholdMinutes; // 10 min for driver_found, accepted
        }
        
        if (differenceInMinutes > thresholdMinutes) {
          final rideId = doc.id;
          final passengerId = data['passengerId'] as String?;
          final driverId = data['driverId'] as String?;
          
          Logger.info('🧹 Auto cleanup: Resetting stuck ride $rideId ($differenceInMinutes minutes old, status: $status, threshold: $thresholdMinutes min)', tag: 'FIRESTORE');
          
          // ✅ LOGGING ÎN FIREBASE: Adaugă în systemLogs pentru tracking în Firebase Console
          batch.update(doc.reference, {
            'status': 'expired',
            'expiredAt': FieldValue.serverTimestamp(),
            'expiredReason': 'auto_reset_stuck_ride_timeout',
            'stuckDurationMinutes': differenceInMinutes,
            'systemLogs': FieldValue.arrayUnion([
              {
                'type': 'auto_expire_stuck_ride',
                'message': 'Stuck ride automatically reset after $thresholdMinutes minutes (status: $status, stuck duration: $differenceInMinutes minutes)',
                'previousStatus': status,
                'passengerId': passengerId,
                'driverId': driverId,
                'timestamp': Timestamp.now(), // ✅ FIX: Folosește Timestamp.now() în loc de FieldValue.serverTimestamp() în arrayUnion
                'triggeredBy': 'auto_cleanup_timer',
              }
            ]),
          });
          cleanedCount++;
        }
      }
      
      if (cleanedCount > 0) {
        await batch.commit();
        Logger.info('✅ Auto cleanup: Reset $cleanedCount stuck rides (logged in Firebase)', tag: 'FIRESTORE');
      } else {
        Logger.debug('🧹 Auto cleanup: No rides needed reset (all are recent)', tag: 'FIRESTORE');
      }
    } catch (e) {
      Logger.error('❌ Error in auto cleanup stuck rides', error: e, tag: 'FIRESTORE');
    }
  }
  
  /// ✅ NOU: Curăță cursele blocate la pornirea aplicației (pentru user-ul curent)
  Future<void> resetStuckRides() async {
    if (_uid == null) return;
    
    try {
      Logger.info('🧹 Cleaning up stuck rides for user: $_uid', tag: 'FIRESTORE');
      
      // ✅ Resetează doar cursele în faze de negociere (searching, driver_found, accepted)
      // NU resetăm 'in_progress' sau 'arrived' — utilizatorul poate fi în mijlocul unei curse reale
      final passengerRides = await _db.collection('ride_requests')
          .where('passengerId', isEqualTo: _uid)
          .where('status', whereIn: ['searching', 'driver_found', 'accepted'])
          .get();

      // ✅ Găsește cursele blocate pentru șofer
      final driverRides = await _db.collection('ride_requests')
          .where('driverId', isEqualTo: _uid)
          .where('status', whereIn: ['searching', 'driver_found', 'accepted'])
          .get();
      
      final batch = _db.batch();
      
      // Marchează cursele ca expirate
      for (final doc in [...passengerRides.docs, ...driverRides.docs]) {
        batch.update(doc.reference, {
          'status': 'expired',
          'expiredAt': FieldValue.serverTimestamp(),
          'expiredReason': 'auto_reset_stuck_ride',
        });
      }
      
      await batch.commit();
      Logger.info('✅ Reset ${passengerRides.docs.length + driverRides.docs.length} stuck rides for user $_uid', tag: 'FIRESTORE');
    } catch (e) {
      Logger.error('❌ Error resetting stuck rides', error: e, tag: 'FIRESTORE');
    }
  }
  
  /// ✅ NOU: Cleanup complet al curselor eronate
  Future<void> forceCleanupAllActiveRides() async {
    if (_uid == null) return;
    
    try {
      Logger.debug('Force cleanup all active rides for user: $_uid');
      
      const activeStatuses = ['driver_found', 'accepted', 'arrived', 'in_progress', 'pending'];
      final asPassenger = await _db.collection('ride_requests')
          .where('passengerId', isEqualTo: _uid)
          .where('status', whereIn: activeStatuses)
          .get();
      final asDriver = await _db.collection('ride_requests')
          .where('driverId', isEqualTo: _uid)
          .where('status', whereIn: activeStatuses)
          .get();

      final seen = <String>{};
      final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final d in [...asPassenger.docs, ...asDriver.docs]) {
        if (seen.add(d.id)) docs.add(d);
      }
      
      final batch = _db.batch();
      int cleanedCount = 0;
      
      for (final doc in docs) {
        final data = doc.data();
        final passengerId = data['passengerId'];
        final driverId = data['driverId'];
        
        Logger.debug('Cleaning ride: ${doc.id} (passenger: $passengerId, driver: $driverId)');
        
        batch.update(doc.reference, {
          'status': 'force_expired',
          'expiredAt': FieldValue.serverTimestamp(),
          'expiredReason': 'force_cleanup_on_app_start',
        });
        cleanedCount++;
      }
      
      if (cleanedCount > 0) {
        await batch.commit();
        Logger.debug('Force cleaned $cleanedCount rides');
      } else {
        Logger.debug('No rides to clean');
      }
      
    } catch (e) {
      Logger.error('Error in force cleanup: $e', error: e);
    }
  }

  /// Returnează un număr mascat (proxy) pentru apel driver ↔ pasager dacă există pentru cursă.
  /// Caută întâi pe documentul cursei, apoi pe profilul utilizatorilor implicați.
  Future<String?> getMaskedPhoneForRide({required String rideId, required String otherUserId}) async {
    try {
      final rideDoc = await _db.collection('ride_requests').doc(rideId).get();
      if (rideDoc.exists) {
        final data = rideDoc.data();
        final masked = data?['maskedPhone'] as String?;
        if (masked != null && masked.isNotEmpty) return masked;
      }

      // Verifică și pe profilul celuilalt utilizator (poate are un număr proxy alocat)
      final userDoc = await _db.collection('users').doc(otherUserId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final masked = data?['maskedPhone'] as String?;
        if (masked != null && masked.isNotEmpty) return masked;
      }
    } catch (e) {
      Logger.error('getMaskedPhoneForRide error: $e', error: e);
    }
    return null;
  }

  // ─── Feature: Favorite Drivers ───────────────────────────────────────────

  Future<void> addFavoriteDriver(String driverId) async {
    if (_uid == null) throw Exception("User not authenticated.");
    await _db
        .collection('users')
        .doc(_uid)
        .collection('favoriteDrivers')
        .doc(driverId)
        .set({'addedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeFavoriteDriver(String driverId) async {
    if (_uid == null) throw Exception("User not authenticated.");
    await _db
        .collection('users')
        .doc(_uid)
        .collection('favoriteDrivers')
        .doc(driverId)
        .delete();
  }

  Future<bool> isFavoriteDriver(String driverId) async {
    if (_uid == null) return false;
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('favoriteDrivers')
        .doc(driverId)
        .get();
    return doc.exists;
  }

  Stream<List<String>> getFavoriteDriverIds() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('favoriteDrivers')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  // ─── Feature: Cancellation Fee Check ─────────────────────────────────────

  /// Returns true if the driver was assigned more than 3 minutes ago,
  /// meaning a 5 RON cancellation fee should apply.
  Future<bool> getCancellationFeeApplicable(String rideId) async {
    try {
      final doc = await _db.collection('ride_requests').doc(rideId).get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      final assignedAt = (data['assignedAt'] as Timestamp?)?.toDate();
      if (assignedAt == null) return false;
      return DateTime.now().difference(assignedAt).inMinutes >= 3;
    } catch (e) {
      Logger.error('getCancellationFeeApplicable error: $e', error: e);
      return false;
    }
  }

  // ─── Feature: Driver Daily Stats ─────────────────────────────────────────

  /// Returns today's completed rides for the current driver.
  Stream<List<Ride>> getDriverTodayRides() {
    if (_uid == null) return Stream.value([]);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _db
        .collection('ride_requests')
        .where('driverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'completed')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Ride.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  // ── RADAR ALERTS ──
  Future<void> saveRadarAlert(RadarAlert alert) async {
    try {
      await _db.collection('radar_alerts').add(alert.toFirestore());
      Logger.info('Radar alert saved to Firestore: ${alert.message}', tag: 'RADAR');
    } catch (e) {
      Logger.error('saveRadarAlert error: $e', error: e, tag: 'FIRESTORE');
    }
  }

  Stream<List<RadarAlert>> getRecentRadarAlerts({Duration maxAge = const Duration(hours: 1)}) {
    final threshold = DateTime.now().subtract(maxAge);
    return _db.collection('radar_alerts')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(threshold))
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => RadarAlert.fromFirestore(doc)).toList());
  }
}

/// DATABASE OPTIMIZATION: Query cache entry with custom TTL
class QueryCacheEntry {
  final dynamic result;
  final DateTime timestamp;
  final Duration ttl;
  
  QueryCacheEntry(this.result, this.timestamp, [this.ttl = const Duration(minutes: 5)]);
  
  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

// IMPLEMENTARE SAFE FIRESTORE OPERATIONS - FIX ERROR HANDLING
class SafeFirestoreOperations {
  static final SafeFirestoreOperations _instance = SafeFirestoreOperations._internal();
  factory SafeFirestoreOperations() => _instance;
  SafeFirestoreOperations._internal();
  
  // DATABASE OPTIMIZATION: Query cache and performance monitoring
  static final Map<String, QueryCacheEntry> _queryCache = {};
  static final Map<String, DateTime> _lastQueryTimes = {};
  static const int _maxCacheSize = 100;

  static const Duration _minQueryInterval = Duration(seconds: 1);
  
  /// DATABASE OPTIMIZATION: Cached query result
  static QueryCacheEntry? getCachedQuery(String queryKey) {
    final cached = _queryCache[queryKey];
    if (cached != null && !cached.isExpired) {
      return cached;
    }
    return null;
  }
  
  /// DATABASE OPTIMIZATION: Cache query result (improved)
  static void cacheQuery(String queryKey, dynamic result) {
    // Dynamic TTL based on query type
    Duration ttl = const Duration(minutes: 5); // Default TTL
    if (queryKey.contains('user_profile')) {
      ttl = const Duration(minutes: 30); // User profiles cache longer
    } else if (queryKey.contains('driver_location') || queryKey.contains('real_time')) {
      ttl = const Duration(seconds: 30); // Real-time data cache shorter
    } else if (queryKey.contains('static') || queryKey.contains('poi')) {
      ttl = const Duration(hours: 1); // Static data cache much longer
    }
    
    _queryCache[queryKey] = QueryCacheEntry(result, DateTime.now(), ttl);
    
    // Intelligent cache cleanup
    if (_queryCache.length > _maxCacheSize) {
      // Remove expired entries first
      final expiredKeys = _queryCache.entries
          .where((entry) => entry.value.isExpired)
          .map((entry) => entry.key)
          .toList();
      
      for (final key in expiredKeys) {
        _queryCache.remove(key);
      }
      
      // If still too large, remove oldest entries
      if (_queryCache.length > _maxCacheSize) {
        final sortedEntries = _queryCache.entries.toList()
          ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
        
        final entriesToRemove = sortedEntries.take(_queryCache.length - _maxCacheSize + 10);
        for (final entry in entriesToRemove) {
          _queryCache.remove(entry.key);
        }
      }
    }
  }
  
  /// DATABASE OPTIMIZATION: Check if query can be executed (improved rate limiting)
  static bool canExecuteQuery(String queryKey) {
    final lastTime = _lastQueryTimes[queryKey];
    if (lastTime == null) return true;
    
    final timeDiff = DateTime.now().difference(lastTime);
    
    // Dynamic rate limiting based on query type
    Duration minInterval = _minQueryInterval;
    if (queryKey.contains('driver_location') || queryKey.contains('real_time')) {
      minInterval = const Duration(milliseconds: 500); // More frequent for real-time data
    } else if (queryKey.contains('user_profile') || queryKey.contains('static')) {
      minInterval = const Duration(seconds: 5); // Less frequent for static data
    }
    
    return timeDiff >= minInterval;
  }
  
  /// DATABASE OPTIMIZATION: Record query execution
  static void recordQueryExecution(String queryKey) {
    _lastQueryTimes[queryKey] = DateTime.now();
  }
  
  /// Wrapper securizat pentru operațiile Firestore cu retry logic și error handling
  static Future<T?> safeFirestoreOperation<T>(
    String operation,
    Future<T> Function() operationFunc,
    {int maxRetries = 3, Duration? customTimeout}
  ) async {
    final timeout = customTimeout ?? const Duration(seconds: 30);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        Logger.debug('Firestore operation: $operation (attempt ${attempt + 1}/$maxRetries)', tag: 'FIRESTORE');
        
        return await operationFunc().timeout(timeout);
        
      } on FirebaseException catch (e) {
        Logger.error('Firebase error for $operation: ${e.code} - ${e.message}', error: e, tag: 'FIRESTORE');
        
        if (e.code == 'permission-denied') {
          Logger.warning('Permission denied for $operation - stopping retries', tag: 'FIRESTORE');
          return null;
        }
        
        if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
          if (attempt == maxRetries - 1) {
            Logger.error('Max retries exceeded for $operation', tag: 'FIRESTORE');
            rethrow;
          }
          
          final delay = Duration(seconds: math.pow(2, attempt).toInt());
          Logger.warning('Retrying $operation in ${delay.inSeconds} seconds...', tag: 'FIRESTORE');
          await Future.delayed(delay);
          continue;
        }
        
        // For other Firebase errors, don't retry
        Logger.error('Non-retryable Firebase error for $operation: ${e.code}', tag: 'FIRESTORE');
        return null;
        
      } on TimeoutException catch (e) {
        Logger.warning('Timeout for $operation: $e', tag: 'FIRESTORE');
        if (attempt == maxRetries - 1) {
          Logger.error('Max retries exceeded for $operation due to timeouts', tag: 'FIRESTORE');
          return null;
        }
        
        final delay = Duration(seconds: math.pow(2, attempt).toInt());
        Logger.warning('Retrying $operation after timeout in ${delay.inSeconds} seconds...', tag: 'FIRESTORE');
        await Future.delayed(delay);
        
      } catch (e) {
        Logger.error('Unexpected error for $operation', error: e, tag: 'FIRESTORE');
        if (attempt == maxRetries - 1) {
          Logger.debug('Max retries exceeded for $operation due to unexpected errors');
          return null;
        }
        
        const delay = Duration(seconds: 1);
        Logger.error('Retrying $operation after unexpected error in ${delay.inSeconds} second...');
        await Future.delayed(delay);
      }
    }
    
    Logger.error('All retry attempts failed for $operation');
    return null;
  }
  
  /// Operație securizată pentru query-uri cu caching
  static Future<QuerySnapshot?> safeQuery(
    Query query,
    {int maxRetries = 3, bool useCache = true}
  ) async {
    final queryKey = query.toString().hashCode.toString();
    
    // Check cache first
    if (useCache) {
      final cached = getCachedQuery(queryKey);
      if (cached != null) {
        Logger.info('Using cached query result: $queryKey', tag: 'DB_OPTIMIZATION');
        return cached.result as QuerySnapshot?;
      }
    }
    
    // Check rate limiting
    if (!canExecuteQuery(queryKey)) {
      Logger.warning('Query rate limited: $queryKey', tag: 'DB_OPTIMIZATION');
      return null;
    }
    
    final result = await safeFirestoreOperation(
      'query_$queryKey',
      () => query.get(),
      maxRetries: maxRetries,
    );
    
    // Cache successful result
    if (result != null && useCache) {
      cacheQuery(queryKey, result);
    }
    
    // Record query execution for rate limiting
    recordQueryExecution(queryKey);
    
    return result;
  }
}
