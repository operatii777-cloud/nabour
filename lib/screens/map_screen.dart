import 'map/map_voice_assistant_ui.dart';
import 'map/map_voice_controller.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'package:nabour_app/services/audio_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../utils/mapbox_utils.dart';
import '../utils/deprecated_apis_fix.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/screens/driver_ride_pickup_screen.dart';
import 'package:nabour_app/screens/ride_summary_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/passenger_ride_session_bus.dart';
import 'package:nabour_app/services/location_cache_service.dart';
import 'package:nabour_app/widgets/app_drawer.dart';
import 'package:nabour_app/screens/personal_info_screen.dart';
import 'package:nabour_app/widgets/ride_request_panel.dart';
import 'package:nabour_app/voice/integration/friendsride_voice_integration.dart';
import 'package:nabour_app/voice/driver/driver_voice_controller.dart';
import 'package:nabour_app/voice/states/voice_interaction_states.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:nabour_app/theme/theme_provider.dart';
// POI interactive model
import 'package:nabour_app/models/poi_model.dart';
import 'package:nabour_app/services/routing_service.dart';
import 'package:nabour_app/screens/searching_for_driver_screen.dart';
import 'package:nabour_app/core/animations/app_transitions.dart';
import 'package:nabour_app/core/haptics/haptic_service.dart';
import 'package:nabour_app/features/cancellation/cancellation_dialog.dart';
import 'package:nabour_app/features/cancellation/cancellation_service.dart';
import 'package:nabour_app/features/smart_suggestions/smart_suggestions_widget.dart';
import 'package:nabour_app/features/smart_suggestions/smart_suggestions_service.dart';
import 'package:nabour_app/features/smart_suggestions/smart_suggestion_model.dart';
import 'package:nabour_app/features/push_campaigns/push_campaign_service.dart';
import 'package:nabour_app/services/bucharest_locations_database.dart';
import 'package:nabour_app/services/geocoding_service.dart';
import 'package:nabour_app/services/local_address_database.dart';
import 'package:nabour_app/models/saved_address_model.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/widgets/assistant_status_overlay.dart';
import 'package:nabour_app/services/connectivity_service.dart';
import 'package:nabour_app/providers/assistant_status_provider.dart';
import 'package:nabour_app/widgets/map/map_voice_overlay.dart';
import 'package:nabour_app/widgets/map/map_driver_ride_offer_bottom_sheet.dart';
import 'package:nabour_app/widgets/map/map_poi_card.dart';
import 'package:nabour_app/widgets/map/map_poi_category_chips.dart';
import 'package:nabour_app/services/poi_service.dart';

import 'package:nabour_app/widgets/map/map_driver_interface.dart';
import 'package:nabour_app/widgets/map/map_ride_info_panel.dart';
import 'package:nabour_app/widgets/map/map_intermediate_stops.dart';
import 'package:nabour_app/utils/logger.dart';

import 'package:nabour_app/models/neighbor_location_model.dart';
import 'package:nabour_app/services/neighbor_location_service.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_activity_feed_panel.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_friend_marker_icons.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_marker_display_layout.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_map_feed_controller.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_map_visibility_publish.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_saved_places_cache.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_stationary_tracker.dart';
import 'package:nabour_app/features/neighbor_bump/neighbor_bump_match_overlay.dart';
import 'package:nabour_app/features/ble_bump/ble_bump_service.dart';
import 'package:nabour_app/features/ble_bump/ble_bump_bridge.dart';
import 'package:nabour_app/features/smart_places/smart_places_db.dart';
import 'package:nabour_app/features/activity_feed/activity_feed_service.dart';
import 'package:nabour_app/features/activity_feed/activity_feed_writer.dart';
import 'package:nabour_app/features/map_moments/map_moment_service.dart';
import 'package:nabour_app/features/map_moments/map_moment_model.dart';
import 'package:nabour_app/features/map_moments/post_moment_sheet.dart';
import 'package:nabour_app/features/neighborhood_requests/neighborhood_requests_manager.dart';
import 'package:nabour_app/services/neighbor_telemetry_rtdb_service.dart';
import 'package:nabour_app/services/walkie_talkie_service.dart';
import 'package:nabour_app/services/open_meteo_service.dart';
import 'package:nabour_app/services/local_notifications_service.dart'
    show LocalNotificationsService;
import 'package:nabour_app/screens/neighborhood_chat_screen.dart';
import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/screens/ride_broadcast_screen.dart';
import 'package:nabour_app/services/contacts_service.dart';
import 'package:nabour_app/services/friend_request_service.dart';
import 'package:nabour_app/services/visibility_preferences_service.dart';
import 'package:nabour_app/services/ghost_mode_service.dart';
import 'package:nabour_app/services/nearby_social_notifications_prefs.dart';
import 'package:nabour_app/screens/visibility_exclusions_screen.dart';

import 'package:nabour_app/screens/week_review_screen.dart';
import 'package:nabour_app/services/movement_history_service.dart';
import 'package:nabour_app/services/movement_history_preferences_service.dart';
import 'package:nabour_app/screens/add_address_screen.dart';
import 'package:nabour_app/screens/favorite_addresses_screen.dart';
import 'package:nabour_app/screens/point_navigation_screen.dart';
import 'package:nabour_app/utils/external_maps_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nabour_app/features/mystery_box/community_mystery_box_map_manager.dart';
import 'package:nabour_app/features/mystery_box/community_mystery_box_service.dart'
    show CommunityMysteryBoxService;
import 'package:nabour_app/features/mystery_box/mystery_box_map_manager.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_checkin_store.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_geofence.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_marker_icons.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_model.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_service.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_star_shower_overlay.dart';
import 'package:nabour_app/features/magic_event_checkin/ultimate_nabour_aura.dart';
import 'package:nabour_app/models/token_wallet_model.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_model.dart';
import 'package:nabour_app/features/car_avatars/car_avatar_service.dart';
import 'package:nabour_app/features/parking_swap/parking_event_model.dart';
import 'package:nabour_app/features/parking_swap/parking_swap_service.dart';
import 'package:nabour_app/services/virtual_honk_service.dart';
import 'package:nabour_app/services/map_emoji_service.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nabour_app/widgets/map/spider_net_radar_selector.dart';
import 'package:nabour_app/widgets/map/bump_bottom_bar.dart';
import 'package:nabour_app/widgets/map/map_activity_toast.dart';
import 'package:nabour_app/screens/friend_suggestions_screen.dart';
import 'package:nabour_app/screens/activity_notifications_screen.dart';
import 'package:nabour_app/widgets/map/weather_overlay.dart';

/// Rezultat metrici sociale pentru căutarea pe hartă (`users` + `friend_peers`).
class MapUniversalSearchPeopleMetrics {
  const MapUniversalSearchPeopleMetrics({
    required this.friendCountByUid,
    required this.mutualFriendPeersByUid,
  });

  final Map<String, int> friendCountByUid;
  final Map<String, int> mutualFriendPeersByUid;
}

class MapUniversalSearchMetricsService {
  MapUniversalSearchMetricsService._();
  static final MapUniversalSearchMetricsService instance =
      MapUniversalSearchMetricsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _readFriendCount(String uid, Map<String, dynamic>? data) {
    final fc = data?['friendCount'];
    if (fc is int) return fc;
    if (fc is num) return fc.toInt();
    return 10 + uid.hashCode.abs() % 60;
  }

  /// [myFriendPeerUids] — setul tău de prieteni confirmați (din hartă).
  Future<MapUniversalSearchPeopleMetrics> loadPeopleMetrics({
    required Set<String> candidateUids,
    required Set<String> myFriendPeerUids,
  }) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final outFriends = <String, int>{};
    final outMutual = <String, int>{};

    if (myUid == null || candidateUids.isEmpty) {
      return MapUniversalSearchPeopleMetrics(
        friendCountByUid: outFriends,
        mutualFriendPeersByUid: outMutual,
      );
    }

    await Future.wait(candidateUids.map((uid) async {
      if (uid.isEmpty || uid == myUid) return;
      try {
        final userDoc = await _db.collection('users').doc(uid).get();
        outFriends[uid] = _readFriendCount(uid, userDoc.data());

        if (myFriendPeerUids.isEmpty) {
          outMutual[uid] = 0;
          return;
        }
        final peersSnap = await _db
            .collection('users')
            .doc(uid)
            .collection('friend_peers')
            .get();
        final theirPeers = peersSnap.docs.map((d) => d.id).toSet();
        outMutual[uid] = myFriendPeerUids.intersection(theirPeers).length;
      } catch (e) {
        Logger.warning('map search metrics $uid: $e', tag: 'MAP_SEARCH');
        outFriends[uid] = outFriends[uid] ?? 0;
        outMutual[uid] = outMutual[uid] ?? 0;
      }
    }));

    return MapUniversalSearchPeopleMetrics(
      friendCountByUid: outFriends,
      mutualFriendPeersByUid: outMutual,
    );
  }
}

// Sentinel: utilizatorul a ales să fie invizibil permanent
const Duration _kInvisibleChoice = Duration(microseconds: -1);

/// Emoji-uri plasabile pe hartă (reacții rapide).
const List<String> _kMapReactionEmojis = [
  // Inimă roșie cu VS explicit — randare mai corectă în Mapbox; 🖤/🤍 la final (evită tap greșit).
  '\u2764\uFE0F', '🧡', '💛', '💚', '💙', '💜',
  '😂', '🤣', '😍', '🥰', '😎', '🤔', '😮', '🥺',
  '👍', '👎', '👏', '🙌', '🤝', '🙏', '💪', '✌️',
  '🔥', '✨', '💫', '⭐', '🌟', '🌈', '⚡', '💥',
  '🎉', '🎊', '🎈', '🎁', '🎶', '🎸', '🎮', '📸',
  '☕', '🍕', '🍔', '🍦', '🚗', '🏎️', '🛵', '🚲',
  '🚀', '✈️', '🏠', '📍', '🐕', '🐱', '🌙', '☀️',
  '💤', '😴', '🥳', '😭', '🤯', '🤠', '👀', '💩',
  '🖤', '🤍',
];

/// Dimensiune icon Mapbox pentru bulă emoji (PNG raster, nu text).
const double _kMapReactionEmojiIconSize = 0.56;

// ─────────────────────────────────────────────────────────────────────────────
class _GhostModeSheet extends StatelessWidget {
  const _GhostModeSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('👥', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            'Cât timp ești vizibil vecinilor?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Vecinii te vor vedea ca bulă pe hartă.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          _DurationTile(
            icon: '⏰',
            label: '1 oră',
            sub: 'Util pentru o ieșire scurtă',
            duration: const Duration(hours: 1),
          ),
          _DurationTile(
            icon: '🕓',
            label: '4 ore',
            sub: 'Util pentru o după-amiază',
            duration: const Duration(hours: 4),
          ),
          _DurationTile(
            icon: '🌙',
            label: 'Până mâine',
            sub: 'Se resetează la miezul nopții',
            duration: Duration(
              hours: 23 - DateTime.now().hour,
              minutes: 59 - DateTime.now().minute,
            ),
          ),
          _DurationTile(
            icon: '♾️',
            label: 'Permanent',
            sub: 'Rămâi vizibil până dezactivezi manual',
            duration: Duration.zero, // sentinel = permanent
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _DurationTile(
            icon: '🫥',
            label: 'Invizibil (mod fantomă)',
            sub: 'Nu apari pe hartă; profilul marchează ghostMode în cont (sync între dispozitive).',
            duration: _kInvisibleChoice,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  final String icon;
  final String label;
  final String sub;
  final Duration duration;
  final bool isDestructive;

  const _DurationTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.duration,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : const Color(0xFF7C3AED);
    return ListTile(
      dense: true,
      leading: Text(icon, style: const TextStyle(fontSize: 22)),
      title: Text(label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDestructive ? Colors.red.shade700 : null)),
      subtitle: Text(sub,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      trailing: Icon(Icons.chevron_right_rounded, color: color),
      onTap: () => Navigator.of(context).pop(duration),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Zoom pentru care lățimea vizibilă pe sol ≈ [visibleWidthM] m (Web Mercator; același model ca eticheta scale bar).
double _mapZoomForVisibleGroundWidthMeters({
  required double latitudeDeg,
  required double mapWidthPx,
  double visibleWidthM = 3000.0,
}) {
  if (mapWidthPx <= 0 || visibleWidthM <= 0) return 14.0;
  final cosLat = math.cos(latitudeDeg.clamp(-85.0, 85.0) * math.pi / 180);
  final z = math.log(156543.03392 * cosLat * mapWidthPx / visibleWidthM) / math.ln2;
  return z.clamp(3.0, 19.0);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  /// Deschidere hartă / recentrare utilizator: ~3 km lățime vizibilă pe sol (înainte de zoom manual).
  static const double _defaultOverviewVisibleWidthM = 3000.0;

  double _overviewZoomForLatitude(double latitudeDeg) {
    final w = mounted ? MediaQuery.sizeOf(context).width : 400.0;
    return _mapZoomForVisibleGroundWidthMeters(
      latitudeDeg: latitudeDeg,
      mapWidthPx: w,
      visibleWidthM: _defaultOverviewVisibleWidthM,
    );
  }

  // Services
  final FirestoreService _firestoreService = FirestoreService();
  final AudioService _audioService = AudioService();
  final RoutingService _routingService = RoutingService();
  final ContactsService _contactsService = ContactsService();
  NeighborhoodRequestsManager? _requestsManager;
  late MapVoiceController _voiceController;
    
  // Map & Basic UI
  MapboxMap? _mapboxMap;
  bool? _lastKnownDarkMode;
  bool _isCreatingNeighborsManager = false;
  /// Mapbox cere tapEvents pe manager; dacă managerul e creat în RTDB subscribe, altfel nu se înregistra tap.
  bool _neighborsAnnotationTapListenerRegistered = false;
  bool _isCreatingDriversManager = false;
  bool _isCreatingUserMarkerManager = false;
  Future<Uint8List>? _userDriverMarkerIconInFlight;
  Future<Uint8List>? _nearbyDriversMarkerIconInFlight;
  /// Ultimul bitmap randat: cheie din [_ownUserMarkerVisualKey] (garaj / șofer standard / emoji).
  String? _userMarkerVisualCacheKey;
  Offset _poiCardPosition = const Offset(16, 180);
  String _scaleBarText = '';
  static const int _poiCardPanThrottleMs = 24;
  DateTime _lastPoiCardPanUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  // Feature: Shake to Pulse Mode
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  bool _isPulseActive = false;
  bool _flashlightOn = false;
  static const double _shakeThreshold = 40.0;
  int _shakeCount = 0;
  DateTime _lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _requiredShakes = 3;
  static const Duration _shakeWindow = Duration(seconds: 2);

  // Annotation Managers
  PolylineAnnotationManager? _routeAnnotationManager;
  PolylineAnnotationManager? _altRouteAnnotationManager;
  PointAnnotationManager? _userPointAnnotationManager;
  PointAnnotationManager? _routeMarkersAnnotationManager;
  PointAnnotationManager? _driversAnnotationManager;
  PointAnnotationManager? _neighborsAnnotationManager;
  CircleAnnotationManager? _pickupCircleManager;
  CircleAnnotationManager? _destinationCircleManager;
  CircleAnnotationManager? _pickupSuggestionsManager;
  PointAnnotationManager? _rideBroadcastsAnnotationManager;
  PointAnnotationManager? _parkingSwapAnnotationManager;
  final Map<String, PointAnnotation> _parkingSpotAnnotations = {};
  StreamSubscription<List<ParkingSpotEvent>>? _parkingSpotsSubscription;
  Future<Uint8List>? _parkingIconInFlight;

  /// Schimb parcare: coordonatele locului de cedat (după marcare GPS sau long-press pe hartă).
  double? _parkingYieldTargetLat;
  double? _parkingYieldTargetLng;
  bool _awaitingParkingYieldMapPick = false;
  PointAnnotationManager? _parkingYieldMySpotManager;
  PointAnnotation? _parkingYieldMySpotAnnotation;
  /// Trebuie să fii cel mult la această distanță de punctul marcat ca să poți anunța locul liber.
  static const double _parkingYieldVerifyRadiusM = 45.0;
  /// Buton P pe hartă — dezactivat până la validarea fluxului de schimb parcare.
  static const bool _showParkingYieldMapButton = false;

  // Radar / Spider Net Selection
  bool _isRadarMode = false;
  Point? _radarCenter;
  /// Raza în pixeli ecran; metrii reali = raza × getMetersPerPixelAtLatitude (depind de zoom).
  double _radarRadius = 180.0;
  String _currentStreetName = '';
  DateTime? _lastStreetNameUpdate;

  // POI Tracking
  final Map<String, PointAnnotation> _poiAnnotations = {};
  PointOfInterest? _selectedPoi;
  bool _showPoiCard = false;
  final List<PointOfInterest> _currentPois = [];
  Timer? _poiUpdateTimer;
  Timer? _poiOperationTimer;
  Timer? _selectedPoiAutoHideTimer;
  bool _poiLayersInitialized = false;
  static const String _poiSourceId = 'poi-source';
  static const String _poiClusterLayerId = 'poi-clusters';
  static const String _poiClusterCountLayerId = 'poi-cluster-count';
  static const String _poiSymbolLayerId = 'poi-symbols';
  static const String _selectedPoiSourceId = 'selected-poi-source';
  static const String _selectedPoiLayerId = 'selected-poi-layer';

  // Camera & Panning Logic
  Timer? _cameraFlyToTimer;
  static const double _panningHardRadiusKm = 8.0;
  static const Duration _panClampMinGap = Duration(seconds: 3);
  bool _isPanClamping = false;
  DateTime _lastPanClampAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _showSearchAreaChip = false;
  double? _lastSearchCenterLat;
  double? _lastSearchCenterLng;
  bool _universalSearchOpen = false;

  // Routing State
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final List<TextEditingController> _intermediateStopsControllers = [];
  final List<String> _intermediateStops = [];
  final int _maxIntermediateStops = 5;
  double? _pickupLatitude, _pickupLongitude, _destinationLatitude, _destinationLongitude;
  
  bool _isFetchingAlternatives = false;
  List<Map<String, dynamic>> _alternativeRoutes = [];
  int _selectedAltRouteIndex = 0;
  double? _currentRouteDistanceMeters;
  double? _currentRouteDurationSeconds;
  String? _pickupQualityLabel;
  Color? _pickupQualityColor;
  bool _tipAltRoutesSeen = true;

  bool _showPickupSuggestions = false;
  List<Point> _pickupSuggestionPoints = [];

  // Social & Neighbors Tracking
  bool _isVisibleToNeighbors = false;
  /// Ascunde sertarul „Activitate” până la următoarea activare vizibilitate.
  bool _neighborActivityFeedDismissed = false;
  bool _showCerereButton = true;
  Timer? _locationUpdateTimer;
  Timer? _visibilityPublishTimer;
  Timer? _ghostModeTimer;
  final Map<String, PointAnnotation> _neighborAnnotations = {};
  final Map<String, String> _neighborAnnotationIdToUid = {};
  final Map<String, NeighborLocation> _neighborData = {};
  final Set<String> _neighborUidsBeingCreated = {};
  bool _isInitializingNeighbors = false;
  final Set<String> _recentlyBumpedUids = {};
  
  Set<String>? _contactUids;
  List<ContactAppUser> _contactUsers = [];
  /// Prieteni acceptați în Firestore (`users/me/friend_peers`), incluși în filtrele hărții.
  Set<String> _friendPeerUids = {};
  StreamSubscription<Set<String>>? _friendPeersSub;
  bool _contactEmptyHintShown = false;
  
  Map<String, String> _neighborAvatarCache = {};
  Map<String, String> _neighborDisplayNameCache = {};
  Map<String, String> _neighborLicensePlateCache = {};
  Map<String, String> _neighborPhotoURLCache = {};
  final Map<String, String> _neighborCarAvatarDriverCache = {};
  final Map<String, String> _neighborCarAvatarPassengerCache = {};
  Set<String> _excludedUids = {};

  final DraggableScrollableController _rideSheetController = DraggableScrollableController();
  bool _rideAddressSheetVisible = false;
  MysteryBoxMapManager? _mysteryBoxManager;
  CommunityMysteryBoxMapManager? _communityMysteryManager;
  /// Galaxy Garage: căi asset per slot — ambele active pe tot parcursul sesiunii (ex. ROBO pasager + OZN șofer).
  String? _garageAssetPathForPassengerSlot;
  String? _garageAssetPathForDriverSlot;
  /// Semnătură id-uri slot garaj din ultimul snapshot `users` — pentru a reapela [_loadCustomCarAvatar] doar la schimbare reală.
  String? _profileGarageSlotIdsSig;

  Timer? _magicEventPollTimer;
  DateTime? _lastMagicEventPoll;
  final Set<String> _magicEventCheckedInIds = <String>{};
  List<MagicEvent> _magicEventsUserInside = <MagicEvent>[];
  void _initParkingSwapStream() {
    if (!_showParkingYieldMapButton) return;
    _parkingSpotsSubscription?.cancel();
    _parkingSpotsSubscription = ParkingSwapService().getNearbySpots().listen(
      (spots) {
        if (!mounted) return;
        _updateParkingMarkers(spots);
      },
      onError: (Object e, StackTrace st) {
        Logger.error(
          'Parking swap Firestore stream: $e',
          error: e,
          stackTrace: st,
          tag: 'PARKING_SWAP',
        );
      },
    );
  }
  List<MagicEvent> _magicEventsAuraCandidates = <MagicEvent>[];
  List<NabourAuraMapSlot> _magicEventAuraSlots = <NabourAuraMapSlot>[];
  final Map<String, int> _magicEventRippleTick = <String, int>{};
  Timer? _auraProjectDebounce;
  PointAnnotationManager? _magicEventAnnotationManager;
  final Map<String, PointAnnotation> _magicEventAnnotations =
      <String, PointAnnotation>{};
  bool _magicStarShowerVisible = false;

  // Smart places clustering timer
  Timer? _smartPlacesClusterTimer;

  // Map moments
  StreamSubscription? _momentsSubscription;
  Timer? _momentsExpiryTimer;
  List<MapMoment> _activeMoments = [];

  // Server-side activity feed subscription
  StreamSubscription? _activityFeedSubscription;

  // Zoom slider state
  double _mapZoomLevel = 14.0;

  // Driver & Telemetry
  UserRole _currentRole = UserRole.passenger;
  bool _isDriverAvailable = false;
  bool _isDriverAccountVerified = false;
  Map<String, dynamic>? _driverProfile;
  final Set<String> _nearbyDriverUidsBeingCreated = {};
  bool _isInitializingDrivers = false;
  final List<NeighborLocation> _lastRawNeighborsForMap = [];
  final Map<String, PointAnnotation> _nearbyDriverAnnotations = {};
  final Map<String, String> _driverAnnotationIdToUid = {};
  bool _driversAnnotationTapListenerRegistered = false;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _lastNearbyDriverDocs = [];
  
  geolocator.Position? _currentPositionObject;
  geolocator.Position? _previousPositionObject;
  CameraOptions? _mapWidgetFrozenCamera;
  CameraOptions? _mapWidgetFallbackCamera;
  
  double? _driverMarkerSmoothLat;
  double? _driverMarkerSmoothLng;
  double? _driverMarkerSmoothHeadingDeg;
  
  StreamSubscription<geolocator.Position>? _positionSubscription;
  StreamSubscription<geolocator.Position>? _passengerWarmupSubscription;
  StreamSubscription? _neighborsSubscription;
  DateTime? _lastUpdateTime;
  final int _standingInterval = 15;
  final int _slowSpeedInterval = 7;
  final int _highSpeedInterval = 7;
  static const bool _verboseBuildLogs = false;

  // Rides & Broadcasts
  Ride? _currentActiveRide;
  List<Ride> _pendingRides = [];
  Ride? _currentRideOffer;
  Timer? _rideOfferTimer;
  int _remainingSeconds = 30;
  bool _isProcessingAccept = false;
  bool _isProcessingDecline = false;
  bool _shouldResetRoute = false;
  final GlobalKey<RideRequestPanelState> _rideRequestPanelKey = GlobalKey<RideRequestPanelState>();
  final Map<String, PointAnnotation> _rideBroadcastAnnotations = {};
  final Map<String, RideBroadcastRequest> _rideBroadcastData = {};
  StreamSubscription? _rideBroadcastsSubscription;

  // Driver Ride Telemetry
  double? _driverPickupDistanceKm;
  Duration? _driverPickupEta;
  DateTime? _driverPickupArrivalTime;
  double? _driverDestinationDistanceKm;
  Duration? _driverDestinationEta;
  DateTime? _driverDestinationArrivalTime;
  String? _driverTrafficSummary;
  geolocator.Position? _driverLastEtaPosition;
  DateTime? _driverLastEtaRequestTime;
  bool _driverIsFetchingEta = false;
  static const Duration _driverEtaThrottle = Duration(seconds: 10);
  static const double _driverEtaDistanceThresholdMeters = 80.0;
  RideCategory? _driverCategory;
  final Duration _offersCacheTtl = const Duration(seconds: 25);
  List<Ride> _pendingRidesCache = [];
  DateTime? _offersCacheUpdatedAt;

  // Subscriptions & Gens
  StreamSubscription<List<Ride>>? _pendingRidesSubscription;
  int _driverAvailabilityCheckGen = 0;
  RideCategory? _driverPipelineCategory;
  StreamSubscription<Ride>? _acceptedRideStatusSubscription;
  StreamSubscription<DocumentSnapshot>? _driverProfileSubscription;
  StreamSubscription<List<SavedAddress>>? _savedAddressesForHomePinSub;
  List<SavedAddress> _savedAddressesForHomePin = [];
  /// Primul snapshot din `saved_addresses` (inclusiv listă goală) — evită ștergerea pinului „Acasă” înainte de date.
  bool _savedAddressesFirestoreHydrated = false;
  StreamSubscription? _nearbyDriversSubscription;
  StreamSubscription<QuerySnapshot>? _chatMessagesSubscription;
  PointAnnotationManager? _emergencyAnnotationManager;
  final Map<String, PointAnnotation> _emergencyAnnotations = {};
  /// Aurele roșii (SOS) randate peste hartă în jurul urgențelor.
  List<NabourAuraMapSlot> _emergencyAuraSlots = [];
  
  StreamSubscription? _emergencyAlertsSubscription;
  StreamSubscription<List<FriendRequestEntry>>? _incomingFriendRequestsSub;
  /// Cereri de prietenie primite, încă pending (badge pe butonul Sugestii).
  int _pendingIncomingFriendRequestCount = 0;

  // Proximity & PNG markers
  final Set<String> _proximitNotifiedUids = {};
  DateTime _proximityNotifResetTime = DateTime.now();
  final Set<String> _friendsTogetherHintPairs = {};
  DateTime? _lastFriendsTogetherHintAny;
  static final Map<String, Uint8List> _emojiMarkerCache = {};
  static final Uint8List _kMinimalPngBytes = Uint8List.fromList(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='));
  bool _marker15StyleImageAdded = false;

  // In-App Navigation State
  bool _inAppNavActive = false;
  double? _navDestLat, _navDestLng;
  String _navDestLabel = '';
  String _navCurrentInstruction = '';
  double _navRemainDistanceM = 0;
  Duration _navRemainEta = Duration.zero;
  bool _navHasArrived = false;
  List<Map<String, dynamic>> _navSteps = [];
  int _navStepIndex = 0;
  int _navLastSpokenStep = -1;
  StreamSubscription<geolocator.Position>? _navGpsSubscription;
  FlutterTts? _navTts;
  Timer? _navEtaTimer;

  // Animations & Pulse Controllers
  AnimationController? _pickupPulseController;
  Animation<double>? _pickupPulse;
  AnimationController? _routePulseController;
  Animation<double>? _routePulse;
  PolylineAnnotation? _activeRouteAnnotation;
  PointAnnotation? _userPointAnnotation;
  /// Reper manual pe hartă (`users.mapOrientationPin`).
  GeoPoint? _manualOrientationPin;
  /// „Acasă” din favorite pe hartă (`users.showSavedHomePinOnMap` + coordonate din `saved_addresses`).
  bool _showSavedHomePinOnMap = false;
  bool _awaitingMapOrientationPinPlacement = false;
  PointAnnotationManager? _mapOrientationPinManager;
  bool _mapOrientationPinTapRegistered = false;
  Future<void>? _homePinUpdateChain; // ✅ Serialize updates (Acas─â / Manual)
  static const List<String> _kHomePinAssetCandidates = [
    'assets/images/home_pin_v2.png',
    'assets/images/home_pin.png',
    'assets/images/home_pinv2.png',
  ];

  /// După schimbare avatar în garaj: următorul update șterge toate punctele user și recreează (Mapbox poate raporta
  /// „isn't an active annotation” la `update` fără excepție în Dart).
  bool _forceUserCarMarkerFullRebuild = false;
  /// Mapbox GL e în pauză când aplicația e în background — update pe annotation → „isn't an active annotation”.
  bool _mapSurfaceSafeForUserMarker = true;
  /// Android: același bitmap ca la PointAnnotation, randat în Flutter — ocol pentru GPU (ex. Mali) unde simbolul nativ lipsește.
  Point? _androidUserMarkerGeometry;
  Offset? _androidUserMarkerOverlayPx;
  double _androidUserMarkerOverlayHeadingDeg = 0;
  Uint8List? _androidUserMarkerOverlayImageBytes;
  String? _androidUserMarkerOverlayLabel;
  static const double _androidUserMarkerOverlaySize = 88.0;
  /// Android: pin reper / Acasă randat în Flutter (același motiv ca la markerul user — PointAnnotation nativ poate lipsi pe unele GPU).
  Point? _androidHomePinGeometry;
  Offset? _androidHomePinOverlayPx;
  Uint8List? _androidHomePinOverlayBytes;
  static const double _androidHomePinOverlayWidth = 48.0;
  static const double _androidHomePinOverlayHeight = 56.0;
  /// Serialize user-marker updates so concurrent GPS ticks do not race Mapbox `update` vs `delete`.
  Future<void>? _userMarkerUpdateChain;
  StreamSubscription? _honkSubscription;
  StreamSubscription? _emojiSubscription;
  PointAnnotationManager? _emojiAnnotationManager;
  final Map<String, PointAnnotation> _emojiAnnotations = {};
  /// Evită deleteAll+recreate la fiecare snapshot Firestore identic (`null` = încă neinițializat după reset).
  String? _lastMapEmojiLayerSig;
  PointAnnotationManager? _momentAnnotationManager;
  final Map<String, PointAnnotation> _momentAnnotations = {};
  /// Mapbox annotation id → document `map_moments` id (pentru tap).
  final Map<String, String> _momentAnnotationIdToMomentId = {};
  /// Ultimele emoji-uri din Firestore — refacem marker-ele după schimbare de stil Mapbox.
  List<MapEmoji> _lastReceivedEmojis = [];
  bool _showEmojiPicker = false;
  
  // Weather & Atmosphere
  WeatherType _weatherType = WeatherType.none;
  double? _weatherTemp;
  DateTime? _lastWeatherUpdate;
  bool _weatherLoading = false;

  /// Pasager: cursă activă afișată pe hartă (fără ActiveRideScreen).
  StreamSubscription<Ride>? _passengerRideSessionSub;
  Ride? _passengerSessionRide;
  String? _passengerRideSessionId;
  bool _passengerDestinationHandoffStarted = false;

  /// O singură viitoare query SharedPreferences pentru sugestii — nu la fiecare rebuild.
  late Future<List<SmartSuggestion>> _smartSuggestionsFuture;

  // Methods & Getters
  bool get canShowVoiceAI {
    if (_currentRole == UserRole.passenger) return true;
    if (_currentRole == UserRole.driver && !_isDriverAvailable) return true;
    return false;
  }

  Future<void> _prewarmTiles() async {
    try {
      final cam = await _mapboxMap?.getCameraState();
      if (cam == null) return;
      const List<String> candidateSources = ['composite', 'mapbox', 'basemap', 'raster-dem'];
      for (final src in candidateSources) {
        try {
          await _mapboxMap!.style.setStyleSourceProperty(src, 'prefetch-zoom-delta', 2);
        } catch (_) {}
      }
      final center = cam.center;
      final zoom = cam.zoom;
      await _mapboxMap?.flyTo(CameraOptions(center: center, zoom: (zoom - 0.01).clamp(0.0, 22.0)), MapAnimationOptions(duration: 250));
      await _mapboxMap?.flyTo(CameraOptions(center: center, zoom: zoom), MapAnimationOptions(duration: 200));
    } catch (_) {}
  }

  static Uint8List _pngBytesOrMinimalFallback(ByteData? data, String context) {
    if (data != null) return data.buffer.asUint8List();
    Logger.warning('$context: Image.toByteData returned null; using minimal PNG', tag: 'MAP');
    return _kMinimalPngBytes;
  }

  /// Evită PNG-uri aproape complet transparente după „strip” BFS (unele decodări / DPI diferă).
  static int _countRgbaOpaquePixels(Uint8List rgba, int w, int h, {int minAlpha = 28}) {
    var n = 0;
    for (var i = 0; i < w * h; i++) {
      if (rgba[i * 4 + 3] >= minAlpha) n++;
    }
    return n;
  }

  /// Dacă abonarea vecini a eșuat la start (fără GPS încă), o repornim când avem poziție.
  void _ensureNeighborsListeningAfterPosition() {
    if (!mounted) return;
    if (_neighborsSubscription != null) return;
    if (_isInitializingNeighbors) return;
    if (_positionForUserMapMarker() == null) return;
    _listenForNeighbors();
  }

  // ── Destination preview ──────────────────────────────────────────────────────
  bool _isDestinationPreviewMode = false;
  Point? _previewPinPoint;
  Offset? _previewPinScreenPos;
  bool _isDraggingPin = false;
  Timer? _pinAutoHideTimer;

  // Afișare automată traseu când avem pickup + destinație (+ opriri)
    _smartSuggestionsFuture = SmartSuggestionsService().getSuggestions();
    PassengerRideServiceBus.pending.addListener(_onPassengerRideBus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
        final List<Point> waypoints = [];
        waypoints.add(Point(coordinates: Position(_pickupLongitude!, _pickupLatitude!)));
        for (final stop in _intermediateStops) {
    WidgetsBinding.instance.addObserver(this);
          if (coords != null) waypoints.add(coords);
        }
        waypoints.add(Point(coordinates: Position(_destinationLongitude!, _destinationLatitude!)));
        final routeData = await _routingService.getRoute(waypoints);
        if (routeData != null && mounted) await _onRouteCalculated(routeData);
    WidgetsBinding.instance.addPostFrameCallback((_) {
        Logger.error('Auto route calculation error: $e', error: e);
      }
    }
  }
  @override
  void initState() {
    super.initState();
    _voiceController = MapVoiceController(
      onPostToChat: (msg) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NeighborhoodChatScreen(initialMessage: msg),
          ),
        );
      },
      onAddToFavorites: () {
        if (!mounted) return;
        final pos = _currentPositionObject;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AddAddressScreen(
              prefilledCoordinates: pos != null
                  ? GeoPoint(pos.latitude, pos.longitude)
                  : null,
              initialLabel: 'Favorite',
            ),
          ),
        );
      },
      onScanFeatures: _showPoiCategorySheet,
    );
    _smartSuggestionsFuture = SmartSuggestionsService().getSuggestions();
    PassengerRideServiceBus.pending.addListener(_onPassengerRideBus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _drainPassengerRideBus();
    });

    WidgetsBinding.instance.addObserver(this);
    // Stage heavy startup work so first frame can render quickly.
    _runDeferredStartupAfterFirstFrame();

    // Locație cât mai devreme: ultima poziție cunoscută + fix GPS în fundal,
    // ca la onMapCreated camera să poată centra imediat pe user.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_tryPreloadLastKnownLocation());
      unawaited(_getCurrentLocation(centerCamera: false));
    });

    // Lazy-init voice services after first frame to avoid blocking first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final voice = Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
        voice.addListener(_onVoiceAddressChanged);
        // Delay TTS warmup: FlutterTts.setLanguage() triggers an Android BpBinder
        // IPC call (~640ms) that blocks the platform thread and causes Choreographer
        // to skip frames. Deferring by 8s lets the map render and animate smoothly.
        Future.delayed(const Duration(seconds: 8), () {
          if (!mounted) return;
          unawaited(voice.warmUp().catchError((_) {}));
        });

        // Wire voice→panel callbacks so AI can fill addresses and press confirm
        voice.setRidePanelCallbacks(
          onFillAddress: (pickup, dest, {pickupLat, pickupLng, destLat, destLng}) {
            _ensureRidePanelVisibleForExternalAction(() {
              if (destLat != null && destLng != null) {
                _rideRequestPanelKey.currentState?.setDestination(
                  address: dest,
                  latitude: destLat,
                  longitude: destLng,
                );
              }
              if (pickupLat != null && pickupLng != null) {
                _rideRequestPanelKey.currentState?.setPickup(
                  address: pickup,
                  latitude: pickupLat,
                  longitude: pickupLng,
                );
              }
            });
          },
          onConfirm: () {
            _ensureRidePanelVisibleForExternalAction(() {
              _rideRequestPanelKey.currentState?.confirmAddressesVoice();
            });
          },
        );
      } catch (_) {}
    });

    // Pulse marker controller
    if (!AppDrawer.lowDataMode) {
      _pickupPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pickupPulseController?.repeat(reverse: true);
        }
      });
      _pickupPulse = Tween<double>(begin: 1.0, end: 1.25).animate(CurvedAnimation(parent: _pickupPulseController!, curve: Curves.easeInOut));
    }

    unawaited(_loadCustomCarAvatar());
  }

  void _runDeferredStartupAfterFirstFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        _initializeScreen();
        _listenToShake();
        unawaited(_maybeStartMovementHistoryRecorder());
        _startBleBump();
        _startSmartPlacesClustering();
        unawaited(_loadSocialBumpPrefs());
        _initHonkListener();
        _initEmojiListener();
        _startMagicEventPolling();
        if (_showParkingYieldMapButton) {
          _initParkingSwapStream();
        }
      });
    });
  }

  void _initEmojiListener() {
    _emojiSubscription = MapEmojiService().listenToRecentEmojis().listen(
      (emojis) {
        if (!mounted) return;
        _lastReceivedEmojis = List<MapEmoji>.from(emojis);
        unawaited(_updateEmojiMarkers(_lastReceivedEmojis));
      },
      onError: (Object e, StackTrace st) {
        Logger.error(
          'Map emoji Firestore stream error: $e',
          error: e,
          stackTrace: st,
          tag: 'EMOJI',
        );
      },
    );
  }

  bool _hasMyMapEmojiPlaced(String? uid) {
    if (uid == null || uid.isEmpty) return false;
    return _lastReceivedEmojis.any((m) => m.senderId == uid || m.id == uid);
  }

  Future<void> _removeMyMapEmoji() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      await MapEmojiService().removeMyEmoji(uid);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _lastReceivedEmojis =
            _lastReceivedEmojis.where((x) => x.senderId != uid && x.id != uid).toList();
        _lastMapEmojiLayerSig = null;
        _showEmojiPicker = false;
      });
      unawaited(_updateEmojiMarkers(_lastReceivedEmojis));
      _showSafeSnackBar('Emoji-ul tău a fost scos de pe hartă', Colors.green.shade700);
    } catch (_) {
      if (mounted) {
        _showSafeSnackBar(
          'Nu am putut șterge emoji-ul. Încearcă din nou.',
          const Color(0xFFB71C1C),
        );
      }
    }
  }

  String _signatureForMapEmojiLayer(List<MapEmoji> emojis) {
    final b = StringBuffer();
    for (final e in emojis) {
      final label = normalizeMapEmojiForEngine(e.emoji);
      b.write(e.id);
      b.write('|');
      b.write(label);
      b.write('|');
      b.write(e.lat.toStringAsFixed(5));
      b.write('|');
      b.write(e.lng.toStringAsFixed(5));
      b.write(';');
    }
    return b.toString();
  }

  Future<void> _updateEmojiMarkers(List<MapEmoji> emojis) async {
    if (_mapboxMap == null) return;
    try {
      _emojiAnnotationManager ??= await _mapboxMap!.annotations.createPointAnnotationManager(id: 'map-emojis-layer');

      final sig = _signatureForMapEmojiLayer(emojis);
      if (_lastMapEmojiLayerSig != null && sig == _lastMapEmojiLayerSig) return;

      // `PointAnnotation.update` păstrează uneori textField vechi / nu aplică corect `image` — reconstruim stratul.
      try {
        await _emojiAnnotationManager?.deleteAll();
      } catch (_) {}
      _emojiAnnotations.clear();

      double iconSize = _kMapReactionEmojiIconSize;
      if (mounted) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        // Min puțin mai mare ca emoji-urile să rămână lizibile lângă alte straturi.
        iconSize = (0.24 * dpr).clamp(0.62, 1.12);
      }

      for (final e in emojis) {
        final label = normalizeMapEmojiForEngine(e.emoji);
        final point = MapboxUtils.createPoint(e.lat, e.lng);
        final png = await _generateMapReactionMarkerPng(label);
        final options = PointAnnotationOptions(
          geometry: point,
          image: png,
          iconSize: iconSize,
          iconAnchor: IconAnchor.BOTTOM,
        );
        final ann = await _emojiAnnotationManager?.create(options);
        if (ann != null) {
          _emojiAnnotations[e.id] = ann;
        }
      }
      _lastMapEmojiLayerSig = sig;
    } catch (e, st) {
      Logger.error('Update emoji markers failed (stale layer?): $e',
          error: e, stackTrace: st, tag: 'EMOJI');
      _emojiAnnotationManager = null;
      _emojiAnnotations.clear();
      _lastMapEmojiLayerSig = null;
    }
  }

  /// Emoji-urile plasate pe hartă trebuie să stea deasupra bulelor de postări — ordinea de creare contează în Mapbox.
  Future<void> _rebuildEmojiThenMomentLayers() async {
    if (_mapboxMap == null || !mounted) return;
    await _updateEmojiMarkers(_lastReceivedEmojis);
    if (!mounted || _mapboxMap == null) return;
    await _updateMomentMarkers(_activeMoments);
  }

  /// Emoji / avatar afișat în bula circulară (aceeași scară vizuală ca markerele vecinilor).
  String _symbolForMapMoment(MapMoment m) {
    if (m.emoji != null && m.emoji!.trim().isNotEmpty) return m.emoji!.trim();
    if (m.authorAvatar.trim().isNotEmpty) return m.authorAvatar.trim();
    return '✨';
  }

  /// Text sub bulă (caption scurt sau nume).
  String _mapMomentCaptionBubble(MapMoment m) {
    final cap = m.caption.trim();
    if (cap.isNotEmpty) {
      final runes = cap.runes;
      return runes.length > 42
          ? '${String.fromCharCodes(runes.take(39))}…'
          : cap;
    }
    final n = m.authorName.trim();
    if (n.isNotEmpty) return n;
    return 'Moment';
  }

  void _onMomentMarkerTapped(PointAnnotation annotation) {
    if (!mounted) return;
    final momentId = _momentAnnotationIdToMomentId[annotation.id];
    if (momentId == null) return;
    MapMoment? found;
    for (final x in _activeMoments) {
      if (x.id == momentId) {
        found = x;
        break;
      }
    }
    if (found == null) return;
    _showMapMomentActions(found);
  }

  void _showMapMomentActions(MapMoment m) {
    final self = FirebaseAuth.instance.currentUser?.uid;
    final isMine = self != null && self == m.authorUid;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final left = m.expiresAt.difference(DateTime.now());
        final expiryLabel = left.isNegative
            ? 'Expirat'
            : left.inMinutes >= 1
                ? '~${left.inMinutes} min până dispare de pe hartă'
                : 'Dispare în curând de pe hartă';

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(m.authorAvatar, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            expiryLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  m.caption.isEmpty ? 'Moment' : m.caption,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Ștergi momentul?'),
                          content: const Text(
                            'Postarea va dispărea de pe hartă pentru toți.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: const Text('Renunță'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text('Șterge'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true || !mounted) return;
                      final deleted =
                          await MapMomentService.instance.delete(m.id);
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showSafeSnackBar(
                        deleted
                            ? 'Momentul a fost șters.'
                            : 'Nu s-a putut șterge. Încearcă din nou.',
                        deleted ? Colors.green.shade700 : const Color(0xFFB71C1C),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Șterge / anulează postarea'),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Închide'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateMomentMarkers(List<MapMoment> moments) async {
    if (_mapboxMap == null) return;
    try {
      // Stratul emoji trebuie să existe în stil înainte de `below`; altfel bulele de momente
      // sunt desenate deasupra și acoperă emoji-urile plasate pe hartă.
      _emojiAnnotationManager ??=
          await _mapboxMap!.annotations.createPointAnnotationManager(
        id: 'map-emojis-layer',
      );

      if (_momentAnnotationManager == null) {
        _momentAnnotationManager =
            await _mapboxMap!.annotations.createPointAnnotationManager(
          id: 'map-moments-layer',
          below: 'map-emojis-layer',
        );
        _momentAnnotationManager!.tapEvents(
          onTap: (PointAnnotation a) => _onMomentMarkerTapped(a),
        );
      }

      final activeIds = moments.map((m) => m.id).toSet();

      for (final id in _momentAnnotations.keys.toList()) {
        if (!activeIds.contains(id)) {
          try {
            final ann = _momentAnnotations[id]!;
            _momentAnnotationIdToMomentId.remove(ann.id);
            await _momentAnnotationManager?.delete(ann);
          } catch (_) {}
          _momentAnnotations.remove(id);
        }
      }

      const double momentIconSize = 2.4; // aliniat la markerele emoji ale vecinilor (~80px PNG)
      const List<double> momentTextOffset = [0, 2.5];
      const int momentTextColor = 0xFF7C3AED;

      for (final m in moments) {
        if (m.isExpired) continue;
        final symbol = _symbolForMapMoment(m);
        final caption = _mapMomentCaptionBubble(m);
        final png = await _generateMapMomentBubblePng(symbol);
        final geom = MapboxUtils.createPoint(m.lat, m.lng);

        if (_momentAnnotations.containsKey(m.id)) {
          try {
            final ann = _momentAnnotations[m.id]!;
            await _momentAnnotationManager?.update(
              ann
                ..geometry = geom
                ..image = png
                ..iconSize = momentIconSize
                ..iconAnchor = IconAnchor.CENTER
                ..textField = caption
                ..textSize = 10.0
                ..textOffset = momentTextOffset
                ..textColor = momentTextColor
                ..textHaloColor = 0xFFFFFFFF
                ..textHaloWidth = 2.0,
            );
          } catch (_) {}
          continue;
        }
        final options = PointAnnotationOptions(
          geometry: geom,
          image: png,
          iconSize: momentIconSize,
          iconAnchor: IconAnchor.CENTER,
          textField: caption,
          textSize: 10.0,
          textOffset: momentTextOffset,
          textColor: momentTextColor,
          textHaloColor: 0xFFFFFFFF,
          textHaloWidth: 2.0,
        );
        final ann = await _momentAnnotationManager?.create(options);
        if (ann != null) {
          _momentAnnotations[m.id] = ann;
          _momentAnnotationIdToMomentId[ann.id] = m.id;
        }
      }
    } catch (e, st) {
      Logger.error(
        'Update moment markers failed: $e',
        error: e,
        stackTrace: st,
        tag: 'MOMENTS',
      );
      _momentAnnotationManager = null;
      _momentAnnotations.clear();
      _momentAnnotationIdToMomentId.clear();
    }
  }

  void _initHonkListener() {
    _honkSubscription?.cancel();
    _honkSubscription = VirtualHonkService().listenForHonks().listen(
      (honk) {
        if (honk.isNotEmpty && mounted) {
          _handleIncomingHonk(honk);
        }
      },
      onError: (Object e, StackTrace st) {
        // RTDB Permission denied fără onError → uncaught async error (oprire în sky_engine errors.dart)
        Logger.error(
          'Honk RTDB stream error (e.g. rules): $e',
          error: e,
          stackTrace: st,
          tag: 'HONK',
        );
      },
    );
  }

  Future<void> _handleIncomingHonk(Map<String, dynamic> data) async {
    final senderName = data['senderName'] ?? 'Vecin';
    final senderUid = data['senderUid'];

    // 1. Play sound
    await _audioService.playHonkSound();

    // 2. Show brief notification
    if (mounted) {
      _showSafeSnackBar('📣 $senderName te-a claxonat!', const Color(0xFF7C3AED));
    }

    // 3. Show emoji above sender car on map (if visible)
    if (senderUid != null && _neighborAnnotations.containsKey(senderUid)) {
      final ann = _neighborAnnotations[senderUid]!;
      final originalText = ann.textField;
      
      try {
        // Temporarily change icon to a big emoji
        await _neighborsAnnotationManager?.update(ann..textField = '📢👋'..textSize = 28.0);
        
        Future.delayed(const Duration(seconds: 3), () async {
          if (mounted && _neighborAnnotations.containsKey(senderUid)) {
             await _neighborsAnnotationManager?.update(ann..textField = originalText..textSize = 11.0);
          }
        });
      } catch (_) {}
    }
  }

  /// Reîncarcă PNG-ul pentru **slotul** potrivit modului ales în UI: șofer = garaj șofer, pasager = garaj pasager.
  /// (Disponibilitatea șoferului influențează doar puck-ul / telemetria, nu ce vehicul ai setat în Galaxy Garage.)
  ///
  /// [optimisticAvatarIdForActiveSlot] — după garaj: aplică imediat ID-ul salvat, fără să așteptăm
  /// eventual consistency la citirea Firestore (evită marker vechi până la repornire).
  CarAvatarMapSlot get _garageSlotForCurrentMode =>
      _currentRole == UserRole.driver
          ? CarAvatarMapSlot.driver
          : CarAvatarMapSlot.passenger;

  /// PNG Galaxy Garage pentru rolul curent în UI (ex. ROBO pasager, OZN șofer) — din cache dual.
  String? get _garageAssetPathForCurrentRole =>
      _currentRole == UserRole.driver
          ? _garageAssetPathForDriverSlot
          : _garageAssetPathForPassengerSlot;

  /// Șofer cu „Disponibil” — folosește vehicul din garaj sau berlina implicită.
  bool get _driverOnDutyOnMap =>
      _currentRole == UserRole.driver && _isDriverAvailable;

  /// Ierarhie: **skin garaj** (non-default) → altfel **berlină implicită** pe toate modurile.
  /// În trecut, pasagerii / off-duty cu `default_car` vedeau doar emoji și dispozitivele „fără tokeni”
  /// păreau fără mașină proprie pe hartă.
  String _ownUserMarkerVisualKey() {
    final g = _garageAssetPathForCurrentRole;
    if (g != null && g.isNotEmpty) {
      return 'garage:$g|duty:$_driverOnDutyOnMap|role:${_currentRole.name}';
    }
    return 'self:berlina|duty:$_driverOnDutyOnMap|role:${_currentRole.name}';
  }

  /// Ids rezolvate (șofer|pasager) din documentul `users`, aliniate la [CarAvatarService.resolveSlotId].
  String _garageSlotIdsSigFromProfile(Map<String, dynamic>? data) {
    if (data == null) return '';
    final d = CarAvatarService.resolveSlotId(data, CarAvatarMapSlot.driver);
    final p = CarAvatarService.resolveSlotId(data, CarAvatarMapSlot.passenger);
    return '$d|$p';
  }

  Future<void> _loadCustomCarAvatar({
    String? optimisticAvatarIdForActiveSlot,
    bool nukeMarkerFirst = true,
  }) async {
    try {
      if (nukeMarkerFirst) {
        _forceUserCarMarkerFullRebuild = true;
        // Evită ca o generare PNG în curs pentru asset-ul vechi să fie refolosită (??=) la path nou.
        _userDriverMarkerIconInFlight = null;
      }
      final svc = CarAvatarService();
      late final String passengerAvatarId;
      late final String driverAvatarId;
      if (optimisticAvatarIdForActiveSlot != null) {
        final passiveSlot = _garageSlotForCurrentMode == CarAvatarMapSlot.driver
            ? CarAvatarMapSlot.passenger
            : CarAvatarMapSlot.driver;
        final passiveId = await svc.getSelectedAvatarIdForSlot(passiveSlot);
        if (_garageSlotForCurrentMode == CarAvatarMapSlot.driver) {
          driverAvatarId = optimisticAvatarIdForActiveSlot;
          passengerAvatarId = passiveId;
        } else {
          passengerAvatarId = optimisticAvatarIdForActiveSlot;
          driverAvatarId = passiveId;
        }
      } else {
        passengerAvatarId =
            await svc.getSelectedAvatarIdForSlot(CarAvatarMapSlot.passenger);
        driverAvatarId =
            await svc.getSelectedAvatarIdForSlot(CarAvatarMapSlot.driver);
      }
      final pAv = svc.getAvatarById(passengerAvatarId);
      final dAv = svc.getAvatarById(driverAvatarId);
      if (mounted) {
        setState(() {
          _garageAssetPathForPassengerSlot =
              pAv.isDefault ? null : pAv.assetPath;
          _garageAssetPathForDriverSlot = dAv.isDefault ? null : dAv.assetPath;
          _markerIconCache.clear();
        });
        if (_mapboxMap != null) {
          // Pauză scurtă după sheet + deleteAll nativ, ca create să nu lovească încă stări intermediare Mapbox.
          await Future<void>.delayed(const Duration(milliseconds: 32));
          if (!mounted) return;
          await _updateUserMarker(centerCamera: false);
          if (mounted) unawaited(_updateLocationPuck());
        }
        if (_wantsNeighborSocialPublish && _currentPositionObject != null) {
          _publishNeighborSocialMapFreshUnawaited(
            _currentPositionObject!,
            forceNeighborTelemetry: true,
          );
        }
      }
    } catch (e, st) {
      Logger.error(
        '_loadCustomCarAvatar failed: $e',
        error: e,
        stackTrace: st,
        tag: 'MAP',
      );
    }
  }

  /// Reîncarcă markerul propriu și stilul de mașină din profil (fără restart) — util dacă Mapbox rămâne desincronizat.
  Future<void> _softRefreshMapDisplay() async {
    if (!mounted || _mapboxMap == null) return;
    try {
      await _loadCustomCarAvatar();
      await _syncMapOrientationPinAnnotation();
    } catch (e, st) {
      Logger.error(
        'Reîmprospătare hartă: $e',
        error: e,
        stackTrace: st,
        tag: 'MAP',
      );
    }
  }

  GeoPoint? _parseMapOrientationPin(Map<String, dynamic>? data) {
    if (data == null) return null;
    final v = data['mapOrientationPin'];
    if (v is GeoPoint) return v;
    if (v is Map) {
      final lat = (v['latitude'] ?? v['lat']) as num?;
      final lng = (v['longitude'] ?? v['lng']) as num?;
      if (lat != null && lng != null) {
        return GeoPoint(lat.toDouble(), lng.toDouble());
      }
    }
    return null;
  }

  bool _parseShowSavedHomePinOnMap(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data['showSavedHomePinOnMap'] == true;
  }

  /// Etichete echivalente cu „Acasă” (Firestore / UI pot folosi diacritice diferite sau EN).
  static bool _labelMeansHomeSaved(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return false;
    final ascii = t
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ș', 's')
        .replaceAll('ț', 't');
    return t == 'acasă' ||
        ascii == 'acasa' ||
        t == 'home' ||
        ascii == 'home' ||
        t == '🏠';
  }

  SavedAddress? _savedHomeAddressEntry() {
    for (final a in _savedAddressesForHomePin) {
      if (_labelMeansHomeSaved(a.label)) return a;
    }
    return null;
  }

  bool _coordsPlausibleForSavedAddress(GeoPoint p) {
    if (p.latitude == 0 && p.longitude == 0) return false;
    return p.latitude.abs() <= 90 && p.longitude.abs() <= 180;
  }

  /// Coordonata pinului privat (preferă „Acasă” din favorite dacă e activat).
  GeoPoint? _resolvedPrivateHomePinCoords() {
    if (_showSavedHomePinOnMap) {
      final h = _savedHomeAddressEntry();
      if (h != null && _coordsPlausibleForSavedAddress(h.coordinates)) {
        return h.coordinates;
      }
    }
    return _manualOrientationPin;
  }

  bool get _displayingHomePinFromSavedAddress =>
      _showSavedHomePinOnMap &&
      _savedHomeAddressEntry() != null &&
      _coordsPlausibleForSavedAddress(_savedHomeAddressEntry()!.coordinates);

  Future<Uint8List> _loadHomeOrientationPinBytes() async {
    for (final path in _kHomePinAssetCandidates) {
      try {
        final bd = await rootBundle.load(path);
        return bd.buffer.asUint8List();
      } catch (_) {}
    }
    Logger.warning('Lipsește PNG reper Acasă (home_pin_v2) — folosesc pin generic.', tag: 'MAP');
    return _generatePinBytes();
  }

  Future<void> _syncMapOrientationPinAnnotation() async {
    if (!mounted || _mapboxMap == null) {
      Logger.debug('Home Pin: Skip - not mounted or map null', tag: 'MAP_HOME');
      return;
    }
    final previous = _homePinUpdateChain;
    final done = Completer<void>();
    _homePinUpdateChain = done.future;

    unawaited(() async {
      try {
        await previous;
      } catch (_) {}

      try {
        final pin = _resolvedPrivateHomePinCoords();
        if (pin == null) {
          if (_showSavedHomePinOnMap && !_savedAddressesFirestoreHydrated) {
            Logger.debug(
              'Home Pin: skip clear until saved_addresses first snapshot',
              tag: 'MAP_HOME',
            );
            return;
          }
          try {
            await _mapOrientationPinManager?.deleteAll();
          } catch (_) {}
          if (_useAndroidFlutterUserMarkerOverlay && mounted) {
            setState(_clearAndroidHomePinOverlayFields);
          } else {
            _clearAndroidHomePinOverlayFields();
          }
          return;
        }

        Logger.debug('Home Pin: Syncing to ${pin.latitude}, ${pin.longitude}', tag: 'MAP_HOME');

        final bytes = await _loadHomeOrientationPinBytes();

        double lat = pin.latitude;
        double lng = pin.longitude;
        final cur = _currentPositionObject;
        if (cur != null) {
          final dist = geolocator.Geolocator.distanceBetween(lat, lng, cur.latitude, cur.longitude);
          if (dist < 10) {
            lat += 0.00006;
          }
        }

        final geom = MapboxUtils.createPoint(lat, lng);

        if (_useAndroidFlutterUserMarkerOverlay) {
          try {
            await _mapOrientationPinManager?.deleteAll();
          } catch (_) {}
          _mapOrientationPinManager = null;
          _mapOrientationPinTapRegistered = false;
          if (!mounted) return;
          setState(() {
            _androidHomePinGeometry = geom;
            _androidHomePinOverlayBytes = bytes;
          });
          await _projectAndroidHomePinOverlay();
          Logger.debug(
            'Home Pin: Android overlay OK (${bytes.length} bytes)',
            tag: 'MAP_HOME',
          );
          return;
        }

        _clearAndroidHomePinOverlayFields();

        _mapOrientationPinManager ??= await _mapboxMap!.annotations.createPointAnnotationManager(
          id: 'user-orientation-pin-manager',
        );

        if (!_mapOrientationPinTapRegistered) {
          _mapOrientationPinTapRegistered = true;
          _mapOrientationPinManager!.tapEvents(onTap: (_) {
            if (mounted) _showMapOrientationPinActions();
          });
        }

        try {
          await _mapOrientationPinManager?.deleteAll();
        } catch (_) {}

        if (_mapOrientationPinManager != null) {
          await _mapOrientationPinManager!.create(
            PointAnnotationOptions(
              geometry: geom,
              image: bytes,
              iconSize: 0.4,
              iconAnchor: IconAnchor.BOTTOM,
              symbolSortKey: 2e6,
            ),
          );
          Logger.debug('Home Pin: Created OK (Asset bytes: ${bytes.length})', tag: 'MAP_HOME');
        }
      } catch (e, st) {
        Logger.error('Reper orientare (pin Acasă): $e', tag: 'MAP_HOME', error: e, stackTrace: st);
      } finally {
        if (!done.isCompleted) done.complete();
      }
    }());
  }

  void _showMapOrientationPlacementSnackBar(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 96),
        action: SnackBarAction(
          label: 'Închide',
          textColor: const Color(0xFF7DD3FC),
          onPressed: () {
            messenger.hideCurrentSnackBar();
            if (mounted) {
              setState(() => _awaitingMapOrientationPinPlacement = false);
            }
          },
        ),
      ),
    );
  }

  Future<void> _finishMapOrientationPinPlacement(Point point) async {
    final lat = point.coordinates.lat.toDouble();
    final lng = point.coordinates.lng.toDouble();
    try {
      await _firestoreService.setShowSavedHomePinOnMap(false);
      await _firestoreService.setMapOrientationPin(lat, lng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nu s-a putut salva reperul: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _awaitingMapOrientationPinPlacement = false;
      _showSavedHomePinOnMap = false;
      _manualOrientationPin = GeoPoint(lat, lng);
    });
    await _syncMapOrientationPinAnnotation();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reperul de orientare a fost salvat pe hartă.'),
          backgroundColor: Color(0xFF166534),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMapOrientationPinActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_displayingHomePinFromSavedAddress) ...[
              ListTile(
                leading: const Icon(Icons.bookmark_added_rounded, color: Color(0xFF38BDF8)),
                title: const Text(
                  'Editează adresa Acasă',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Schimbi poziția din Adrese salvate',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FavoriteAddressesScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.visibility_off_rounded, color: Colors.orange.shade300),
                title: Text(
                  'Ascunde Acasă de pe hartă',
                  style: TextStyle(color: Colors.orange.shade200, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _firestoreService.setShowSavedHomePinOnMap(false);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red.shade800),
                    );
                    return;
                  }
                  if (!mounted) return;
                  setState(() => _showSavedHomePinOnMap = false);
                  await _syncMapOrientationPinAnnotation();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Acasă nu mai este afișată pe hartă.')),
                  );
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF38BDF8)),
                title: const Text('Mută reperul', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Apoi ține apăsat pe hartă la noul loc',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _awaitingMapOrientationPinPlacement = true);
                  _showMapOrientationPlacementSnackBar(
                    'Ține apăsat pe hartă pentru noul reper.',
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
                title: Text(
                  'Elimină reperul manual',
                  style: TextStyle(color: Colors.red.shade200, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _firestoreService.clearMapOrientationPin();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red.shade800),
                    );
                    return;
                  }
                  if (!mounted) return;
                  setState(() => _manualOrientationPin = null);
                  await _syncMapOrientationPinAnnotation();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reperul a fost eliminat.')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _enableSavedHomePinFromDrawer() async {
    final h = _savedHomeAddressEntry();
    if (h == null || !_coordsPlausibleForSavedAddress(h.coordinates)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Salvează adresa „Acasă” în favorite (cu poziție pe hartă), apoi încearcă din nou.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    try {
      await _firestoreService.setShowSavedHomePinOnMap(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red.shade800),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _showSavedHomePinOnMap = true);
    await _syncMapOrientationPinAnnotation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_syncMapOrientationPinAnnotation());
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Acasă din favorite este afișată pe hartă (doar pentru tine).'),
        backgroundColor: Color(0xFF166534),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _removeMapOrientationPinFromMenu() async {
    if (_displayingHomePinFromSavedAddress) {
      try {
        await _firestoreService.setShowSavedHomePinOnMap(false);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red.shade800),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _showSavedHomePinOnMap = false);
      await _syncMapOrientationPinAnnotation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acasă nu mai este afișată pe hartă.')),
      );
      return;
    }
    if (_manualOrientationPin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu ai un reper pe hartă (manual sau Acasă).')),
      );
      return;
    }
    try {
      await _firestoreService.clearMapOrientationPin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red.shade800),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _manualOrientationPin = null);
    await _syncMapOrientationPinAnnotation();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reperul manual a fost eliminat de pe hartă.')),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Aplicăm stilul hărții imperativ când tema se schimbă.
    // MapWidget ignoră schimbările de styleUri la rebuild — trebuie un apel direct.
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    if (_mapboxMap != null && _lastKnownDarkMode != isDark) {
      _lastKnownDarkMode = isDark;
      final targetStyle = AppDrawer.lowDataMode
          ? MapboxStyles.LIGHT
          : (isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS);
      // Resetăm managerii de adnotare înainte de schimb — Mapbox îi invalidează la loadStyleURI
      _resetAnnotationManagers();
      unawaited(
        _mapboxMap!.loadStyleURI(targetStyle).then((_) async {
          if (!mounted) return;
          await _rebuildEmojiThenMomentLayers();
          unawaited(_syncMapOrientationPinAnnotation());
          if (_positionForUserMapMarker() != null) {
            unawaited(_updateUserMarker(centerCamera: false));
            unawaited(_updateLocationPuck());
          }
        }).catchError((_) {}),
      );
    }
  }

  // 🗺️ Obține coordonatele pentru o destinație (cu geocoding real)
  Future<Point?> _getCoordinatesForDestination(String destination) async {
    try {
      // 1. Mai întâi verifică destinațiile predefinite (rapid)
      final predefinedCoordinates = _getPredefinedDestinationCoordinates(destination);
      if (predefinedCoordinates != null) {
        Logger.info('Destinație predefinită găsită: $destination');
        return predefinedCoordinates;
      }
      
      // 2. Dacă nu e predefinită, folosește geocoding API
      Logger.debug('Caut adresa cu geocoding: $destination');
      final coordinates = await _geocodeAddress(destination);
      
      if (coordinates != null) {
        Logger.info('Coordonate găsite cu geocoding: $destination');
        return coordinates;
      }
      
      // 3. ❌ NU FOLOSIM COORDONATE DEFAULT - Returnează null și gestionează eroarea
      Logger.warning('Nu am găsit coordonatele pentru: $destination');
      // Nu returnăm coordonate default - utilizatorul trebuie să specifice o adresă validă
      return null;
      
    } catch (e) {
      Logger.error('Eroare la găsirea coordonatelor: $e', error: e);
      // ❌ NU RETURNĂM COORDONATE DEFAULT
      return null;
    }
  }
  
  // 🗺️ Verifică destinațiile predefinite (rapid) - folosește baza de date extinsă
  Point? _getPredefinedDestinationCoordinates(String destination) {
    // ✅ FIX: Folosește baza de date locală extinsă pentru locații din București și Ilfov
    try {
      final location = BucharestLocationsDatabase.findLocation(destination);
      if (location != null) {
        Logger.info('Destinație predefinită găsită în baza de date: ${location['name']} (${location['category']})');
        return Point(
          coordinates: Position(
            location['longitude'] as double,
            location['latitude'] as double,
          ),
        );
      }
    } catch (e) {
      Logger.warning('Eroare la căutarea în baza de date: $e');
    }
    
    return null; // Nu e predefinită
  }
  
  // 🌍 Geocoding real pentru orice adresă din România (cu timeout și retry)
  Future<Point?> _geocodeAddress(String address) async {
    try {
      // Adaugă "România" la adresă dacă nu e specificat
      final fullAddress = address.toLowerCase().contains('românia') || 
                          address.toLowerCase().contains('romania')
        ? address 
        : '$address, România';
      
      Logger.debug('Geocoding pentru: $fullAddress');
      
      // Folosește OpenStreetMap Nominatim API (gratuit)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(fullAddress)}'
        '&format=json'
        '&limit=1'
        '&countrycodes=ro'
        '&addressdetails=1'
      );
      
      // ✅ TIMEOUT PENTRU GEOCODING (10 secunde)
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Geocoding timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        
        if (results.isNotEmpty) {
          final result = results.first;
          final lat = double.parse(result['lat']);
          final lon = double.parse(result['lon']);
          
          // ✅ VALIDARE COORDONATE
          if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
            Logger.warning('Coordonate invalide pentru: $address');
            return null;
          }
          
          Logger.info('Geocoding reușit: $lat, $lon pentru $address');
          return Point(coordinates: Position(lon, lat));
        }
      }
      
      Logger.warning('Nu am găsit rezultate pentru: $address');
      return null;
      
    } on TimeoutException catch (e) {
      Logger.error('Geocoding timeout: $e', error: e);
      return null;
    } catch (e) {
      Logger.error('Eroare geocoding: $e', error: e);
      return null;
    }
  }
  
  // 🗺️ Generează programatic un pin icon (roșu cu punct alb)
  Future<Uint8List> _generatePinBytes() async {
    const int w = 64, h = 88;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
    final paint = Paint()..isAntiAlias = true;

    // Corp pin (cerc în top + triunghi jos)
    final path = Path()
      ..addOval(Rect.fromCircle(center: const Offset(32, 32), radius: 28))
      ..moveTo(20, 48)
      ..lineTo(32, h.toDouble())
      ..lineTo(44, 48)
      ..close();
    paint.color = const Color(0xFFEF4444); // red-500
    canvas.drawPath(path, paint);

    // Punct alb interior
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(32, 30), 10, paint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return _pngBytesOrMinimalFallback(byteData, '_generatePinBytes');
  }

  // 🗺️ Adaugă marker pentru destinație pe hartă
  Future<void> _addDestinationMarker(Point coordinates, String title) async {
    try {
      // Inițializează managerul dacă nu există (ex: în modul preview înainte de calculul rutei)
      _routeMarkersAnnotationManager ??= await _mapboxMap?.annotations
          .createPointAnnotationManager(id: 'route-markers-manager');

      // Șterge marker-ele anterioare de destinație
      await _routeMarkersAnnotationManager?.deleteAll();

      final Uint8List imageList = await _generatePinBytes();
      final destinationMarkerOptions = PointAnnotationOptions(
        geometry: coordinates,
        image: imageList,
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
      );

      // Adaugă marker-ul pe hartă
      await _routeMarkersAnnotationManager?.create(destinationMarkerOptions);

      Logger.info('Marker destinație adăugat: $title');
    } catch (e) {
      Logger.error('Eroare la adăugarea marker-ului destinație: $e', error: e);
    }
  }

  Future<void> _updateParkingMarkers(List<ParkingSpotEvent> spots) async {
    if (_mapboxMap == null || !mounted) return;

    if (_parkingSwapAnnotationManager == null) {
      _parkingSwapAnnotationManager = await _mapboxMap?.annotations.createPointAnnotationManager(
        id: 'parking-swap-manager',
      );
      // Modern Mapbox Tap Events
      _parkingSwapAnnotationManager?.tapEvents(onTap: (annotation) {
        _onParkingMarkerTapped(annotation.id);
      });
    }

    _parkingIconInFlight ??= _generateParkingIcon(false);
    final iconBytes = await _parkingIconInFlight!;

    final spotIds = spots.map((s) => s.id).toSet();
    final toRemove = _parkingSpotAnnotations.keys.where((id) => !spotIds.contains(id)).toList();
    for (final id in toRemove) {
      final ann = _parkingSpotAnnotations.remove(id);
      if (ann != null) {
        _parkingSwapAnnotationManager?.delete(ann);
      }
    }

    for (final spot in spots) {
      if (_parkingSpotAnnotations.containsKey(spot.id)) {
        final ann = _parkingSpotAnnotations[spot.id]!;
        ann.geometry = MapboxUtils.createPoint(spot.lat, spot.lng);
        _parkingSwapAnnotationManager?.update(ann);
      } else {
        final options = PointAnnotationOptions(
          geometry: MapboxUtils.createPoint(spot.lat, spot.lng),
          image: iconBytes,
          iconSize: 0.8,
          textField: 'LOC LIBER',
          textColor: Colors.amber.toARGB32(),
          textHaloColor: Colors.black.toARGB32(),
          textHaloWidth: 2.0,
          textSize: 10,
          textOffset: [0.0, 2.5],
        );
        final ann = await _parkingSwapAnnotationManager?.create(options);
        if (ann != null) {
          _parkingSpotAnnotations[spot.id] = ann;
        }
      }
    }
  }

  void _onParkingMarkerTapped(String internalAnnotationId) {
    // ID-ul intern Mapbox (ex: "point_123") se asociază cu spot.id-ul din Firestore
    final firestoreId = _parkingSpotAnnotations.entries
        .where((e) => e.value.id == internalAnnotationId)
        .map((e) => e.key)
        .firstOrNull;

    if (firestoreId != null) {
      _showParkingSwapDialog(firestoreId);
    }
  }

  
  // ═══════════════════════════════════════════════════════════════════
  // NAVIGARE INTERNĂ MAPBOX — fără a deschide o fereastră separată
  // ═══════════════════════════════════════════════════════════════════

  /// Pornește navigarea internă: calculează ruta, o desenează pe harta Mapbox
  /// principală și urmărește utilizatorul cu camera + TTS turn-by-turn.
  Future<void> _startInAppNavigation(double destLat, double destLng, String label) async {
    if (!mounted || _mapboxMap == null) return;

    // Inițializare TTS la prima utilizare
    if (_navTts == null) {
      final t = FlutterTts();
      try {
        await t.setLanguage('ro-RO');
        await t.setSpeechRate(0.42);
        await t.awaitSpeakCompletion(true);
      } catch (_) {}
      _navTts = t;
    }

    // Oprește sesiunea anterioară dacă există
    await _stopInAppNavigation(announce: false);

    setState(() {
      _inAppNavActive = true;
      _rideAddressSheetVisible = true;
      _navDestLat = destLat;
      _navDestLng = destLng;
      _navDestLabel = label;
      _navHasArrived = false;
      _navCurrentInstruction = 'Se calculează traseul...';
      _navRemainDistanceM = 0;
      _navRemainEta = Duration.zero;
      _navSteps = [];
      _navStepIndex = 0;
      _navLastSpokenStep = -1;
    });

    // Obținem poziția curentă
    final seed = await _navigationOriginSeedLatLng();
    final originLat = seed.lat;
    final originLng = seed.lng;
    if (originLat == null || originLng == null) {
      if (mounted) {
        setState(() {
          _navCurrentInstruction = 'Nu am putut obține locația. Activează GPS-ul.';
        });
      }
      return;
    }

    // Calculăm ruta
    final route = await _routingService.getPointToPointRoutePreferOsm(
      startLat: originLat,
      startLng: originLng,
      endLat: destLat,
      endLng: destLng,
    );
    if (!mounted) return;

    if (route == null) {
      setState(() {
        _navCurrentInstruction = 'Traseu indisponibil. Verifică conexiunea.';
      });
      return;
    }

    // Desenăm ruta pe harta Mapbox principală
    await _onRouteCalculated(route);
    if (!mounted) return;

    // Parsăm pașii pentru turn-by-turn
    try {
      final routes = route['routes'] as List?;
      if (routes != null && routes.isNotEmpty) {
        final legs = (routes.first as Map)['legs'] as List?;
        if (legs != null && legs.isNotEmpty) {
          final steps = (legs.first as Map)['steps'] as List?;
          if (steps != null) {
            _navSteps = steps.map((s) => Map<String, dynamic>.from(s as Map)).toList();
          }
        }
        final r = routes.first as Map;
        final dist = (r['distance'] as num?)?.toDouble() ?? 0;
        final dur = (r['duration'] as num?)?.toDouble() ?? 0;
        setState(() {
          _navRemainDistanceM = dist;
          _navRemainEta = Duration(seconds: dur.round());
        });
      }
    } catch (_) {}

    // Prima instrucțiune
    _navUpdateInstruction();
    unawaited(_navSpeakStep(force: true));

    // Abonare GPS
    _navGpsSubscription = geolocator.Geolocator.getPositionStream(
      locationSettings: DeprecatedAPIsFix.createLocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen(_navGpsTick, onError: (_) {});

    Logger.info('Navigare internă pornită → $label ($destLat,$destLng)', tag: 'NAV_INTERNAL');
  }

  /// Actualizează instrucțiunea curentă din lista de pași.
  void _navUpdateInstruction() {
    if (_navSteps.isEmpty) {
      setState(() => _navCurrentInstruction = 'Continuă pe traseu.');
      return;
    }
    final i = _navStepIndex.clamp(0, _navSteps.length - 1);
    final step = _navSteps[i];
    String text = '';
    final m = step['maneuver'];
    if (m is Map) text = m['instruction']?.toString().trim() ?? '';
    if (text.isEmpty) {
      final banners = step['banner_instructions'] ?? step['bannerInstructions'];
      if (banners is List && banners.isNotEmpty) {
        final pri = (banners.first as Map)['primary'];
        if (pri is Map) text = pri['text']?.toString().trim() ?? '';
      }
    }
    if (text.isEmpty) text = 'Continuă pe traseu.';
    if (mounted) setState(() => _navCurrentInstruction = text);
  }

  /// Callback GPS în timp real — actualizează camera, ETA și detectează sosirea.
  Future<void> _navGpsTick(geolocator.Position pos) async {
    if (!mounted || !_inAppNavActive || _navHasArrived) return;

    final destLat = _navDestLat;
    final destLng = _navDestLng;
    if (destLat == null || destLng == null) return;

    final distToDestM = geolocator.Geolocator.distanceBetween(
      pos.latitude, pos.longitude, destLat, destLng,
    );

    // Actualizam distanta si ETA
    final speedMs = pos.speed > 0.5 ? pos.speed : 8.33; // default 30 km/h
    final etaSec = (distToDestM / speedMs).round();
    if (mounted) {
      setState(() {
        _navRemainDistanceM = distToDestM;
        _navRemainEta = Duration(seconds: etaSec);
      });
    }

    // Avansăm pasul: găsim cel mai aproape pas din traseu
    if (_navSteps.isNotEmpty) {
      for (int i = _navStepIndex; i < _navSteps.length - 1; i++) {
        final step = _navSteps[i];
        final geom = step['geometry'];
        if (geom is Map) {
          final coords = geom['coordinates'];
          if (coords is List && coords.isNotEmpty) {
            final endCoord = coords.last;
            if (endCoord is List && endCoord.length >= 2) {
              final stepEndLat = (endCoord[1] as num).toDouble();
              final stepEndLng = (endCoord[0] as num).toDouble();
              final dToStepEnd = geolocator.Geolocator.distanceBetween(
                pos.latitude, pos.longitude, stepEndLat, stepEndLng,
              );
              if (dToStepEnd < 35) {
                if (_navStepIndex != i + 1) {
                  setState(() => _navStepIndex = i + 1);
                  _navUpdateInstruction();
                  unawaited(_navSpeakStep(force: false));
                }
                break;
              }
            }
          }
        }
      }
    }

    // Detectare sosire (30 m)
    if (distToDestM <= 30) {
      unawaited(_navArrival());
      return;
    }

    // Camera urmărește userul
    final map = _mapboxMap;
    if (map == null || !mounted) return;
    double bearing = pos.heading;
    if (bearing < 0 || bearing > 360 || bearing.isNaN || pos.speed < 1.0) bearing = 0;
    try {
      await map.flyTo(
        CameraOptions(
          center: MapboxUtils.createPoint(pos.latitude, pos.longitude),
          zoom: 16.5,
          bearing: bearing,
          pitch: 45.0,
        ),
        MapAnimationOptions(duration: 600),
      );
    } catch (_) {}
  }

  Future<void> _navSpeakStep({required bool force}) async {
    final tts = _navTts;
    if (tts == null || !mounted) return;
    final text = _navCurrentInstruction;
    if (text.isEmpty || (!force && _navLastSpokenStep == _navStepIndex)) return;
    _navLastSpokenStep = _navStepIndex;
    try {
      await tts.stop();
      await tts.speak(text);
    } catch (_) {}
  }

  Future<void> _navArrival() async {
    if (_navHasArrived || !mounted) return;
    setState(() {
      _navHasArrived = true;
      _navCurrentInstruction = 'Ai sosit la destinație!';
    });
    HapticFeedback.heavyImpact();
    try { await _navTts?.stop(); await _navTts?.speak('Ai sosit la destinație!'); } catch (_) {}
    await _stopInAppNavigation(announce: false);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.place_rounded, size: 48, color: Theme.of(ctx).colorScheme.primary),
        title: const Text('Ai sosit!'),
        content: Text('Ai ajuns la destinație: $_navDestLabel'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Oprește navigarea internă și resetează starea.
  Future<void> _stopInAppNavigation({bool announce = true}) async {
    await _navGpsSubscription?.cancel();
    _navGpsSubscription = null;
    _navEtaTimer?.cancel();
    _navEtaTimer = null;
    if (announce) {
      try { await _navTts?.stop(); } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _inAppNavActive = false;
        _navDestLat = null;
        _navDestLng = null;
        _navDestLabel = '';
        _navCurrentInstruction = '';
        _navRemainDistanceM = 0;
        _navRemainEta = Duration.zero;
        _navSteps = [];
        _navStepIndex = 0;
        _navLastSpokenStep = -1;
        _navHasArrived = false;
      });
    }
    // Reset cameră la modul normal
    try {
      final p = _currentPositionObject;
      if (p != null && _mapboxMap != null && mounted) {
        await _mapboxMap!.flyTo(
          CameraOptions(
            center: MapboxUtils.createPoint(p.latitude, p.longitude),
            zoom: 14.0,
            bearing: 0,
            pitch: 0,
          ),
          MapAnimationOptions(duration: 800),
        );
      }
    } catch (_) {}
    // Curăță ruta de pe hartă
    unawaited(_onRouteCalculated(null));
    Logger.info('Navigare internă oprită.', tag: 'NAV_INTERNAL');
  }



  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    
    if (_flashlightOn) {
      TorchLight.disableTorch().catchError((_) {});
      _flashlightOn = false;
    }
    
    Logger.debug('MapScreen dispose - cleaning up all resources');

    PassengerRideServiceBus.pending.removeListener(_onPassengerRideBus);
    _passengerRideSessionSub?.cancel();
    _passengerRideSessionSub = null;
    
    _audioService.dispose();
    
    // 🛑 NOU: Dispose intermediate stops controllers
    for (final controller in _intermediateStopsControllers) {
      controller.dispose();
    }
    _intermediateStopsControllers.clear();
    
    // MODIFICAT: Asigurăm oprirea noului stream de locație.
    _stopLocationUpdates();
    
    // NOU: Cleanup pentru POI-uri
    _poiAnnotations.clear();
    _poiUpdateTimer?.cancel();
    _poiOperationTimer?.cancel(); // ✅ NOU: Cancel POI operation timer
    
    // Nav internă
    _navGpsSubscription?.cancel();
    _navEtaTimer?.cancel();
    _navTts?.stop();

    // Cancel all timers
    _rideOfferTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _poiUpdateTimer?.cancel();
    _poiOperationTimer?.cancel();
    _selectedPoiAutoHideTimer?.cancel();
    _cameraFlyToTimer?.cancel();
    _pinAutoHideTimer?.cancel();
    _rideSheetController.dispose();

    // Dispose animations
    _pickupPulseController?.dispose();
    _routePulseController?.dispose();
    _requestsManager?.dispose();
    
    // Cancel all subscriptions
    _pendingRidesSubscription?.cancel();
    _pendingRidesSubscription = null;
    _acceptedRideStatusSubscription?.cancel();
    _driverProfileSubscription?.cancel();
    _savedAddressesForHomePinSub?.cancel();
    _nearbyDriversSubscription?.cancel();
    _chatMessagesSubscription?.cancel();
    _emergencyAlertsSubscription?.cancel();
    _neighborsSubscription?.cancel();
    _honkSubscription?.cancel();
    _emojiSubscription?.cancel();
    _ghostModeTimer?.cancel();
    if (_isVisibleToNeighbors) {
      NeighborLocationService().setInvisible();
    }
    BleBumpService.instance.stop();
    BleBumpBridge.instance.stop();
    _smartPlacesClusterTimer?.cancel();
    _momentsSubscription?.cancel();
    _momentsExpiryTimer?.cancel();
    _activityFeedSubscription?.cancel();
    _parkingSpotsSubscription?.cancel();
    _parkingSpotsSubscription = null;
    _friendPeersSub?.cancel();
    _incomingFriendRequestsSub?.cancel();
    _mysteryBoxManager?.dispose();
    _communityMysteryManager?.dispose();
    _magicEventPollTimer?.cancel();
    _auraProjectDebounce?.cancel();

    try {
      final voice = Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
      voice.removeListener(_onVoiceAddressChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _maybeStartMovementHistoryRecorder() async {
    final enabled = await MovementHistoryPreferencesService.instance.isEnabled();
    if (!enabled) return;
    await MovementHistoryService.instance.startRecorder();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      _mapSurfaceSafeForUserMarker = true;
      Logger.info('App resumed - checking if we need to reset route state');

      unawaited(_updateLocationPuck());
      unawaited(_updateUserMarker(centerCamera: false));
      unawaited(_syncMapOrientationPinAnnotation());
      
      unawaited(_syncFriendPeersIntoContactUids());
      _listenIncomingFriendRequests();

      unawaited(_pollMagicEventsOnce());

      _resetRouteStateIfNeeded();
      
      if (_isDriverAvailable && _currentRole == UserRole.driver) {
        Logger.debug('App resumed - restarting location updates and ride listener');
        _startDriverLocationUpdates();
        _startListeningForRides(); 
      }
    } else if (state == AppLifecycleState.paused) {
      // NU folosi `inactive`: pe Android apare des în foreground (scurtă pierdere focus)
      // și bloca markerul personalizat fără să repornească puck-ul → utilizator „invizibil”.
      _mapSurfaceSafeForUserMarker = false;
      if (_useAndroidFlutterUserMarkerOverlay && mounted) {
        setState(() {
          _clearAndroidUserMarkerOverlayFields();
          _clearAndroidHomePinOverlayFields();
        });
      }
      Logger.debug('💤 App paused - stopping location updates');
      _stopLocationUpdates();
    }
  }

  void _resetRouteStateIfNeeded() {
    if (!_shouldResetRoute || !mounted) return;
    
    Logger.debug('MapScreen: Resetting route state after ride completion');
    
    _routeAnnotationManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing route annotations: $e', error: e);
    });
    
    _routeMarkersAnnotationManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing route markers: $e', error: e);
    });

    _pickupCircleManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing pickup circle: $e', error: e);
    });

    _destinationCircleManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing destination circle: $e', error: e);
    });
    
    _rideRequestPanelKey.currentState?.resetPanel();
    
    _shouldResetRoute = false;

    Logger.info('MapScreen: Route state reset completed');
  }

  // ── Voice→UI bridge ──────────────────────────────────────────────────────────
  // Listener înregistrat pe FriendsRideVoiceIntegration. Când AI-ul rezolvă
  // o adresă și o publică via onFillAddressInUI, aceasta propagă adresa în
  // controller-ele hărții, geocodează și declanșează calculul de rută.
  void _onVoiceAddressChanged() {
    if (!mounted) return;
    try {
      final voice = Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
      if (!voice.hasNewVoiceDestination && !voice.hasNewVoicePickup) return;

      final dest = voice.voiceDestination;
      final pickup = voice.voicePickup;
      voice.markVoiceEventsProcessed();

      if (dest != null && dest.isNotEmpty) {
        setState(() => _destinationController.text = dest);
        unawaited(_geocodeVoiceAddress(dest, isPickup: false));
      }
      if (pickup != null && pickup.isNotEmpty) {
        setState(() => _pickupController.text = pickup);
        unawaited(_geocodeVoiceAddress(pickup, isPickup: true));
      }

      // Navigate to SearchingForDriverScreen when secondary voice path creates a ride
      if (voice.shouldNavigateToSearching && voice.navigationRideId != null) {
        final rideId = voice.navigationRideId!;
        voice.markNavigationToSearchingProcessed();
        unawaited(voice.stopVoiceInteraction());
        Navigator.push<Object?>(
          context,
          AppTransitions.slideUp(SearchingForDriverScreen(rideId: rideId)),
        ).then(_onSearchingForDriverPopped);
      }
    } catch (_) {}
  }

  Future<void> _geocodeVoiceAddress(String address, {required bool isPickup}) async {
    final point = await _geocodeAddress(address);
    if (point == null || !mounted) return;
    setState(() {
      if (isPickup) {
        _pickupLatitude = point.coordinates.lat.toDouble();
        _pickupLongitude = point.coordinates.lng.toDouble();
      } else {
        _destinationLatitude = point.coordinates.lat.toDouble();
        _destinationLongitude = point.coordinates.lng.toDouble();
      }
    });
    unawaited(_checkAndShowRouteAutomatically());
  }
  // ─────────────────────────────────────────────────────────────────────────────

  // ✅ FIX: Metodă robustă cu multiple fallback-uds
  Future<void> _playRideOfferSoundRobust() async {
    // ✅ VERIFICĂ DOAR mounted - eliminăm verificarea _currentRideOffer
    if (!mounted) return;
    
    Logger.debug('Starting ride offer sound...', tag: 'SOUND');
    
    try {
      // ✅ FIX 1: Testează multiple metode de redare audio
      bool audioPlayed = false;
      
      // Metodă 1: AudioService
      try {
        await _audioService.playRideRequestSound();
        audioPlayed = true;
        Logger.info('AudioService played successfully');
      } catch (e) {
        Logger.error('AudioService failed: $e', error: e);
      }
      
      // Metodă 2: Fallback la system sounds
      if (!audioPlayed) {
        try {
          await SystemSound.play(SystemSoundType.alert);
          audioPlayed = true;
          Logger.info('SystemSound played successfully');
        } catch (e) {
          Logger.error('SystemSound failed: $e', error: e);
        }
      }
      
      // Metodă 3: Fallback la multiple HapticFeedback
      if (!audioPlayed) {
        try {
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 300));
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 300));
          HapticFeedback.heavyImpact();
          Logger.info('HapticFeedback sequence played');
        } catch (e) {
          Logger.error('HapticFeedback failed: $e', error: e);
        }
      }
      
      // ✅ FIX 2: Redă sunetele suplimentare cu interval mai mare
      if (mounted) {
        for (int i = 1; i <= 3; i++) {
          Future.delayed(Duration(milliseconds: 1000 * i), () async {
            if (mounted) {
              try {
                await _audioService.playRideRequestSound();
              } catch (e) {
                HapticFeedback.heavyImpact();
              }
            }
          });
        }
      }
      
    } catch (e) {
      Logger.error('CRITICAL: All audio methods failed: $e', error: e);
      // Ultimate fallback: Show visual notification
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.newRideAudioUnavailable),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _listenForChatMessages(String rideId) {
    _chatMessagesSubscription?.cancel();
    _chatMessagesSubscription = _firestoreService.getChatMessages(rideId).listen((snapshot) {
      if (!mounted) return;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final messageData = change.doc.data();
          final senderId = messageData?['senderId'] as String?;
          final messageText = messageData?['message'] as String? ?? messageData?['text'] as String?;

          // ✅ FIX: Audio pentru mesaje de la șofer către pasager (sau invers)
          if (senderId != null && senderId != currentUserId) {
            // 🔊 FIX: Redă sunetul doar pentru mesajele de chat reale (nu pentru actualizări de locație sau mesaje de sistem)
            if (messageText != null && 
                messageText.isNotEmpty && 
                !messageText.contains('location_update') &&
                !messageText.startsWith('system:')) {
              
              Logger.debug('New message from $senderId to $currentUserId - playing sound notification', tag: 'MAP_CHAT');
              
              // ✅ FIX: Redă sunetul pe background thread
              unawaited(_audioService.playMessageReceivedSound().catchError((e) async {
                Logger.error('Error playing chat sound: $e', tag: 'MAP_CHAT', error: e);
                // ✅ FALLBACK: Încearcă sunetul de sistem dacă audio custom eșuează
                try {
                  await SystemSound.play(SystemSoundType.alert);
                } catch (e2) {
                  Logger.error('Even system sound failed: $e2', tag: 'MAP_CHAT');
                }
              }));
              
              // ✅ FIX: Înlocuiește Vibration cu HapticFeedback
              HapticFeedback.mediumImpact();
            }
          }
        }
      }
    }, onError: (e) {
      Logger.error('Chat messages stream error: $e', tag: 'MAP_CHAT', error: e);
    });
  }

  geolocator.Position _applyRoadSnapping(geolocator.Position rawPosition) {
    if (_previousPositionObject == null) {
      return rawPosition;
    }

    final distanceFromPrevious = geolocator.Geolocator.distanceBetween(
      _previousPositionObject!.latitude,
      _previousPositionObject!.longitude,
      rawPosition.latitude,
      rawPosition.longitude,
    );

    if (distanceFromPrevious > 100) {
      Logger.debug('GPS jump detected: ${distanceFromPrevious.toStringAsFixed(1)}m - applying road snapping');
      final interpolationFactor = 100 / distanceFromPrevious;
      final correctedLat = _previousPositionObject!.latitude + 
          (rawPosition.latitude - _previousPositionObject!.latitude) * interpolationFactor;
      final correctedLng = _previousPositionObject!.longitude + 
          (rawPosition.longitude - _previousPositionObject!.longitude) * interpolationFactor;

      return geolocator.Position(
        latitude: correctedLat, longitude: correctedLng,
        timestamp: rawPosition.timestamp, accuracy: rawPosition.accuracy,
        altitude: rawPosition.altitude, altitudeAccuracy: rawPosition.altitudeAccuracy,
        heading: rawPosition.heading, headingAccuracy: rawPosition.headingAccuracy,
        speed: rawPosition.speed, speedAccuracy: rawPosition.speedAccuracy,
      );
    }

    if (distanceFromPrevious < 5 && rawPosition.accuracy > 10) {
      Logger.debug('GPS noise detected - applying smoothing');
      const smoothingFactor = 0.7;
      final smoothedLat = rawPosition.latitude * smoothingFactor + 
          _previousPositionObject!.latitude * (1 - smoothingFactor);
      final smoothedLng = rawPosition.longitude * smoothingFactor + 
          _previousPositionObject!.longitude * (1 - smoothingFactor);

      return geolocator.Position(
        latitude: smoothedLat, longitude: smoothedLng,
        timestamp: rawPosition.timestamp, accuracy: rawPosition.accuracy,
        altitude: rawPosition.altitude, altitudeAccuracy: rawPosition.altitudeAccuracy,
        heading: rawPosition.heading, headingAccuracy: rawPosition.headingAccuracy,
        speed: rawPosition.speed, speedAccuracy: rawPosition.speedAccuracy,
      );
    }
    return rawPosition;
  }

  /// Resetează toți managerii de adnotare la null (lazy recreation) după o schimbare de stil.
  /// Mapbox invalidează automat managerii existenți la loadStyleURI.
  void _resetAnnotationManagers() {
    _routeAnnotationManager = null;
    _altRouteAnnotationManager = null;
    _routeMarkersAnnotationManager = null;
    _userPointAnnotationManager = null;
    _driversAnnotationManager = null;
    _driversAnnotationTapListenerRegistered = false;
    _driverAnnotationIdToUid.clear();
    _neighborsAnnotationManager = null;
    _neighborsAnnotationTapListenerRegistered = false;
    _pickupCircleManager = null;
    _destinationCircleManager = null;
    _pickupSuggestionsManager = null;
    _poiLayersInitialized = false;
    _userPointAnnotation = null;
    _userMarkerVisualCacheKey = null;
    _clearAndroidUserMarkerOverlayFields();
    _clearAndroidHomePinOverlayFields();
    _mapOrientationPinManager = null;
    _mapOrientationPinTapRegistered = false;
    _resetDriverMarkerInterpolation();
    _nearbyDriverAnnotations.clear();
    _neighborAnnotations.clear();
    _poiAnnotations.clear();
    _emojiAnnotationManager = null;
    _emojiAnnotations.clear();
    _lastMapEmojiLayerSig = null;
    _momentAnnotationManager = null;
    _momentAnnotations.clear();
    _momentAnnotationIdToMomentId.clear();
    _parkingSwapAnnotationManager = null;
    _parkingSpotAnnotations.clear();
    _parkingYieldMySpotManager = null;
    _parkingYieldMySpotAnnotation = null;
    _parkingYieldTargetLat = null;
    _parkingYieldTargetLng = null;
    _awaitingParkingYieldMapPick = false;
  }

  /// După multe modificări runtime pe straturi, pe unele driver-e GPU managerii PointAnnotation
  /// rămân apelabili din Dart dar nu mai randează. [deleteAll] + reset referințe obligă recrearea lazy.
  Future<void> _disposePointAnnotationManagersAfterRuntimeStyleMutation() async {
    if (!mounted || _mapboxMap == null) return;
    try {
      try {
        await _userPointAnnotationManager?.deleteAll();
      } catch (e) {
        Logger.debug('User marker deleteAll before style sync: $e', tag: 'MAP');
      }
      try {
        await _mapOrientationPinManager?.deleteAll();
      } catch (e) {
        Logger.debug('Home pin deleteAll before style sync: $e', tag: 'MAP');
      }
    } finally {
      _userPointAnnotationManager = null;
      _userPointAnnotation = null;
      _userMarkerVisualCacheKey = null;
      _clearAndroidUserMarkerOverlayFields();
      _mapOrientationPinManager = null;
      _mapOrientationPinTapRegistered = false;
      if (mounted) {
        setState(_clearAndroidHomePinOverlayFields);
      } else {
        _clearAndroidHomePinOverlayFields();
      }
    }
    Logger.info(
      'Point annotation managers disposed after style overlays (will recreate on next sync)',
      tag: 'MAP',
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    // Resetează managerii lazy înainte de orice await. Altfel [onStyleLoaded] poate rula
    // în timpul await-urilor de mai jos, creează markerul, iar codul vechi punea managerul
    // la null fără deleteAll nativ → pe unele dispozitive marker „creat OK” dar invizibil;
    // loguri duble „User marker created OK” cu UUID diferit.
    _routeAnnotationManager = null;
    _routeMarkersAnnotationManager = null;
    _userPointAnnotationManager = null;
    _userPointAnnotation = null;
    _userMarkerVisualCacheKey = null;
    _clearAndroidUserMarkerOverlayFields();
    _clearAndroidHomePinOverlayFields();
    _mapOrientationPinManager = null;
    _mapOrientationPinTapRegistered = false;
    _driversAnnotationManager = null;
    _driversAnnotationTapListenerRegistered = false;
    _driverAnnotationIdToUid.clear();
    _pickupCircleManager = null;
    _destinationCircleManager = null;
    _pickupSuggestionsManager = null;
    // Sincronizăm starea temei ca să evităm un loadStyleURI inutil imediat după creare
    if (mounted) {
      final tp = Provider.of<ThemeProvider>(context, listen: false);
      _lastKnownDarkMode = tp.isDarkMode;
    }
    // NOU: Inițializăm managerul de Bule de Cartier
    _requestsManager?.dispose();
    _requestsManager = NeighborhoodRequestsManager(
      mapboxMap: _mapboxMap!,
      context: context,
      onDataChanged: () { if (mounted) setState((){}); },
    );
    await _requestsManager!.initialize();
    if (!mounted) return;

    _mysteryBoxManager = MysteryBoxMapManager(
      mapboxMap: _mapboxMap!,
      context: context,
      getUserLatLng: () {
        final p = LocationCacheService.pickNewer(
          _currentPositionObject,
          LocationCacheService.instance.peekRecent(
            maxAge: const Duration(minutes: 20),
          ),
        );
        if (p == null) return null;
        return (lat: p.latitude, lng: p.longitude);
      },
    );
    unawaited(_mysteryBoxManager!.initialize());

    _communityMysteryManager = CommunityMysteryBoxMapManager(
      mapboxMap: _mapboxMap!,
      context: context,
      getUserLatLng: () {
        final p = LocationCacheService.pickNewer(
          _currentPositionObject,
          LocationCacheService.instance.peekRecent(
            maxAge: const Duration(minutes: 20),
          ),
        );
        if (p == null) return null;
        return (lat: p.latitude, lng: p.longitude);
      },
    );
    unawaited(_communityMysteryManager!.initialize());

    Logger.info("Map created. Initializing light map state...");

    try {
      // Disable default UI plugins to reduce AppCompat theme warnings and save GPU
      try {
        final compass = _mapboxMap?.compass;
        final logo = _mapboxMap?.logo;
        final attribution = _mapboxMap?.attribution;
        final scaleBar = _mapboxMap?.scaleBar;
        // Bara nativă: harta e sub SafeArea, deci marginTop mic e suficient (fără ceas peste scară).
        await compass?.updateSettings(CompassSettings(enabled: false));
        await logo?.updateSettings(LogoSettings(
          position: OrnamentPosition.TOP_LEFT,
          marginLeft: 10,
          marginTop: 10,
        ));
        await attribution?.updateSettings(AttributionSettings(
          position: OrnamentPosition.TOP_LEFT,
          marginLeft: 100,
          marginTop: 14,
        ));
        await scaleBar?.updateSettings(ScaleBarSettings(
          enabled: false,
        ));
      } catch (_) {}

      // Annotation managers: resetat la începutul lui _onMapCreated (înainte de await).

      // Initialize route pulse animation (low overhead)
      if (!AppDrawer.lowDataMode) {
        _routePulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
        _routePulse = Tween<double>(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(parent: _routePulseController!, curve: Curves.easeInOut),
        );
        // Start a bit later to avoid jank on first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _routePulseController?.repeat(reverse: true);
        });
      }
      Logger.info("Deferred annotation managers creation (lazy mode).");

      // POI: încărcăm + afișăm pe hartă doar după interacțiunea userului
      // (categoria POI și apoi POI-ul selectat din listă).
      
      // Enable location puck (blue dot showing user position).
      try {
        await _setupLocationPuck(mapboxMap);
      } catch (e) {
        Logger.warning('Could not enable location puck: $e');
      }

      // Mișcare cursivă la pan/rotate/pinch (decelerare după gest).
      try {
        await mapboxMap.gestures.updateSettings(
          GesturesSettings(
            scrollDecelerationEnabled: true,
            rotateDecelerationEnabled: true,
            pinchToZoomDecelerationEnabled: true,
            pinchPanEnabled: true,
          ),
        );
      } catch (e) {
        Logger.debug('gestures.updateSettings: $e');
      }

      if (mounted) {
        // Center on last known position immediately (no GPS wait), then fetch accurate GPS.
        unawaited(_centerOnLocationOnMapReady());
        // Warm-up tiles around current center (non-blocking)
        unawaited(_prewarmTiles());
        final markerPos = _positionForUserMapMarker();
        if (markerPos != null) {
          unawaited(_updateWeatherAndStyle(markerPos.latitude, markerPos.longitude));
          unawaited(_updateUserMarker(centerCamera: false));
          unawaited(_updateLocationPuck());
        }
        unawaited(Future.microtask(_ensurePassiveLocationWarmupIfNeeded));
        unawaited(_rebuildEmojiThenMomentLayers());
        unawaited(_syncMapOrientationPinAnnotation());
      }
    } catch (e) {
      Logger.error("CRITICAL ERROR creating annotation managers: $e. Map markers will not work.", error: e);
    }
  }

  /// Aplică estetica "Premium Neon" / "Clean Tech" prin Mapbox Runtime Styling la fiecare încărcare de stil.
  Future<void> _onStyleLoaded(StyleLoadedEventData event) async {
    if (_mapboxMap == null) return;
    Logger.info("Map style loaded. Applying Aesthetic Overlays dynamically...");

    try {
      final style = _mapboxMap!.style;
      // Doar tema aplicației (setată de user), fără zi/noapte automat din vreme.
      final isDark = !AppDrawer.lowDataMode &&
          Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

      final layers = await style.getStyleLayers();
      
      for (final l in layers) {
        final layerId = l?.id;
        if (layerId == null) continue;

        if (isDark) {
          // --- 🌌 DARK NEON MODE (Cyberpunk) ---
          if (layerId.toLowerCase().contains('road') || layerId.toLowerCase().contains('street')) {
            try {
              await style.setStyleLayerProperty(layerId, 'line-color', '#D946FF');
              await style.setStyleLayerProperty(layerId, 'line-width', 2.2);
              await style.setStyleLayerProperty(layerId, 'line-blur', 0.6);
            } catch (_) {}
          }
          if (layerId.toLowerCase().contains('water')) {
            try { await style.setStyleLayerProperty(layerId, 'fill-color', '#071626'); } catch (_) {}
          }
          if (layerId.toLowerCase().contains('park') || layerId.toLowerCase().contains('forest') || layerId.toLowerCase().contains('natural')) {
            try { await style.setStyleLayerProperty(layerId, 'fill-color', '#061a14'); } catch (_) {}
          }
          if (layerId == 'background') {
            try { await style.setStyleLayerProperty(layerId, 'background-color', '#020617'); } catch (_) {}
          }
          if (layerId.toLowerCase().contains('poi') || layerId.toLowerCase().contains('label')) {
            try {
              await style.setStyleLayerProperty(layerId, 'text-color', '#22D3EE');
              await style.setStyleLayerProperty(layerId, 'icon-color', '#22D3EE');
              await style.setStyleLayerProperty(layerId, 'text-halo-color', '#0891B2');
              await style.setStyleLayerProperty(layerId, 'text-halo-width', 1.2);
            } catch (_) {}
          }
        } 
        else {
          // --- ☀️ LIGHT MODE (Clean Tech / High-Energy) ---
          // O estetică stil "Mirror's Edge" - curată, modernă, cu accente neon pastel
          
          // 1. Drumuri (Sky Blue cu Cyan accent)
          if (layerId.toLowerCase().contains('road') || layerId.toLowerCase().contains('street')) {
            try {
              await style.setStyleLayerProperty(layerId, 'line-color', '#E0F2FE'); // Light cyan/blue back
              // Outline (dacă layer-ul e un casing sau primary)
              if (layerId.contains('primary') || layerId.contains('motorway')) {
                await style.setStyleLayerProperty(layerId, 'line-color', '#0EA5E9');
              }
              await style.setStyleLayerProperty(layerId, 'line-width', 1.8);
            } catch (_) {}
          }

          // 2. Apa (Crystalline Clear Blue)
          if (layerId.toLowerCase().contains('water')) {
            try {
              await style.setStyleLayerProperty(layerId, 'fill-color', '#BAE6FD'); // Bright cyan water
            } catch (_) {}
          }

          // 3. Zone Verzi (Digital Mint / Pastel Green)
          if (layerId.toLowerCase().contains('park') || layerId.toLowerCase().contains('forest') || layerId.toLowerCase().contains('natural')) {
            try {
              await style.setStyleLayerProperty(layerId, 'fill-color', '#ECFDF5'); // Very soft mint
              await style.setStyleLayerProperty(layerId, 'fill-outline-color', '#10B981');
            } catch (_) {}
          }

          // 4. Fundal și Teren (Ultra Clean Slate)
          if (layerId == 'background' || layerId.toLowerCase().contains('landuse-background')) {
            try {
              await style.setStyleLayerProperty(layerId, 'background-color', '#F8FAFC');
              await style.setStyleLayerProperty(layerId, 'fill-color', '#F8FAFC');
            } catch (_) {}
          }

          // 5. Clădiri (Pure White with subtle lines)
          if (layerId.toLowerCase().contains('building')) {
            try {
              await style.setStyleLayerProperty(layerId, 'fill-color', '#FFFFFF');
              await style.setStyleLayerProperty(layerId, 'fill-opacity', 0.9);
            } catch (_) {}
          }

          // 6. POI (High-Contrast Indigo / Violet)
          if (layerId.toLowerCase().contains('poi') || layerId.toLowerCase().contains('label')) {
            try {
              await style.setStyleLayerProperty(layerId, 'text-color', '#4F46E5'); // Indigo regal pt lizibilitate
              await style.setStyleLayerProperty(layerId, 'icon-color', '#4338CA');
              await style.setStyleLayerProperty(layerId, 'text-halo-color', '#FFFFFF');
              await style.setStyleLayerProperty(layerId, 'text-halo-width', 2.0);
            } catch (_) {}
          }
        }
      }
      
      // După overlay-uri runtime, pe unele GPU referința Dart la manager rămâne dar randarea se pierde.
      // Evităm cursa veche (null fără deleteAll): aici facem mereu [deleteAll] înainte de reset.
      if (mounted) {
        await _disposePointAnnotationManagersAfterRuntimeStyleMutation();
        unawaited(_requestsManager?.initialize());
        unawaited(_mysteryBoxManager?.initialize());
        unawaited(_communityMysteryManager?.initialize());
        if (_positionForUserMapMarker() != null) {
          await _updateUserMarker(centerCamera: false);
          await _updateLocationPuck();
        }
        await _syncMapOrientationPinAnnotation();
      }
      
    } catch (e) {
      Logger.error("Failed to apply Style Overlays: $e");
    }
  }

  /// Configurează puck-ul de locație pentru a afișa poziția curentă.
  /// Se utilizează puck-ul implicit Mapbox care se integrează perfect.
  Future<void> _setupLocationPuck(MapboxMap mapboxMap) async {
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingMaxRadius: 60.0,
        pulsingColor: const Color(0xFF3682F3).toARGB32(),
      ),
    );
  }

  // Initializes GeoJson source and SymbolLayers for POIs (with clustering)
  // Defer POI layer initialization until first use; method kept for future use
  // ignore: unused_element
  Future<void> _ensurePoiLayersInitialized() async {
    if (_mapboxMap == null) return;
    try {
      final style = _mapboxMap!.style;
      if (_poiLayersInitialized) {
        return; // already initialized
      }

      // Ensure we have the symbol icon image that SymbolLayer references.
      if (!_marker15StyleImageAdded) {
        try {
          final ByteData markerBytes = await rootBundle.load('assets/images/pin_icon.png');
          final Uint8List png = markerBytes.buffer.asUint8List();
          final codec = await ui.instantiateImageCodec(png);
          final frame = await codec.getNextFrame();
          final image = frame.image;
          final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          if (byteData != null) {
            final mbxImage = MbxImage(
              width: image.width,
              height: image.height,
              data: byteData.buffer.asUint8List(),
            );
            await style.addStyleImage(
              'marker-15',
              1.0,
              mbxImage,
              false,
              const [],
              const [],
              null,
            );
            _marker15StyleImageAdded = true;
          }
        } catch (e) {
          Logger.warning('Could not add marker-15 style image: $e', tag: 'POI');
        }
      }

      // Add clustered GeoJSON source for POIs (once)
      final source = GeoJsonSource(
        id: _poiSourceId,
        data: '{"type":"FeatureCollection","features":[]}',
        cluster: true,
        clusterRadius: 60,
        clusterMaxZoom: 15,
      );
      try {
        await style.addSource(source);
      } catch (e) {
        // Idempotent: dacă sursa există deja (ex. reinits pe același style), ignorăm.
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }

      // Cluster circles
      try {
        await style.addLayer(
          CircleLayer(
            id: _poiClusterLayerId,
            sourceId: _poiSourceId,
            circleColor: Colors.lightBlue.shade400.toARGB32(),
            circleRadius: 18.0,
            filter: ["has", "point_count"],
          ),
        );
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }

      // Cluster count labels
      try {
        await style.addLayer(
          SymbolLayer(
            id: _poiClusterCountLayerId,
            sourceId: _poiSourceId,
            textField: '{point_count_abbreviated}',
            textColor: Colors.white.toARGB32(),
            textSize: 12.0,
            textIgnorePlacement: true,
            textAllowOverlap: true,
            filter: ["has", "point_count"],
          ),
        );
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }

      // Individual POI symbols
      try {
        await style.addLayer(
          SymbolLayer(
            id: _poiSymbolLayerId,
            sourceId: _poiSourceId,
            iconImage: 'marker-15',
            iconAllowOverlap: true,
            filter: ["!has", "point_count"],
          ),
        );
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }

      // Selected POI highlight source + layer (always present, data empty by default)
      try {
        await style.addSource(GeoJsonSource(
          id: _selectedPoiSourceId,
          data: '{"type":"FeatureCollection","features":[]}',
        ));
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }
      try {
        await style.addLayer(CircleLayer(
          id: _selectedPoiLayerId,
          sourceId: _selectedPoiSourceId,
          circleColor: Colors.redAccent.toARGB32(),
          circleRadius: 10.0,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 2.0,
        ));
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('already exists') && !msg.contains('exists')) rethrow;
      }

      _poiLayersInitialized = true;
      _poiLayersInitialized = true;
    } catch (e) {
      Logger.error('Failed to init POI layers: $e', error: e);
    }
  }

  // Cache pentru iconițele generate programatic
  static final Map<String, Uint8List> _markerIconCache = {};

  /// Generează iconița marker:
  /// passenger = cerc albastru cu punct alb
  /// driver    = mașinuță 3D (vedere de sus, design premium)
  static Future<Uint8List> _generateMarkerIcon({required bool isPassenger, String? customAssetPath}) async {
    // Include calea asset pentru pasager cu garaj — altfel toate variantele partajau cheia „passenger”.
    final cacheKey =
        '${isPassenger ? 'p' : 'd'}_${customAssetPath ?? (isPassenger ? 'default' : 'driver_3d')}';
    if (_markerIconCache.containsKey(cacheKey)) return _markerIconCache[cacheKey]!;

    // Avatar icon: folosește asset-ul dacă este furnizat (sofer sau pasager).
    // Daca e sofer si n-are custom, folosim fallback-ul clasic de masinuta.
    if (customAssetPath != null || !isPassenger) {
      try {
        final path = customAssetPath ?? 'assets/images/driver_icon.png';
        final ByteData imageBytes = await rootBundle.load(path);
        final Uint8List sourceBytes = imageBytes.buffer.asUint8List();
        // "Berlina": ieșire rămâne pătrată (96x96) ca să fie compatibilă cu Mapbox,
        // dar desenăm imaginea cu stretch vertical în interior.
        final codec = await ui.instantiateImageCodec(sourceBytes);
        final frame = await codec.getNextFrame();
        final decoded = frame.image;

        const double maxSize = 120.0;
        final double srcW = decoded.width.toDouble();
        final double srcH = decoded.height.toDouble();
        final double aspectRatio = srcW / srcH;

        double destW, destH;
        if (aspectRatio > 1.0) {
          destW = maxSize;
          destH = maxSize / aspectRatio;
        } else {
          destH = maxSize;
          destW = maxSize * aspectRatio;
        }

        final double destX = (maxSize - destW) / 2;
        final double destY = (maxSize - destH) / 2;

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, maxSize, maxSize));
        
        canvas.drawImageRect(
          decoded,
          ui.Rect.fromLTWH(0, 0, srcW, srcH),
          ui.Rect.fromLTWH(destX, destY, destW, destH),
          ui.Paint()..isAntiAlias = true..filterQuality = ui.FilterQuality.high,
        );

        final picture = recorder.endRecording();
        var img = await picture.toImage(maxSize.toInt(), maxSize.toInt());

        final bool isCustom = customAssetPath != null;
        // După desen: dacă skin-ul din garaj rămâne aproape transparent (unele GPU / PNG-uri),
        // Mapbox raportează create OK dar utilizatorul „nu vede nimic” — trecem la berlina implicită.
        if (isCustom) {
          try {
            final raw = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
            if (raw != null) {
              final w = maxSize.toInt();
              final opaque =
                  _countRgbaOpaquePixels(raw.buffer.asUint8List(), w, w);
              const minOp = 80;
              if (opaque < minOp) {
                Logger.warning(
                  'Pictogramă garaj aproape invizibilă ($opaque px opace < $minOp) pentru $path '
                  '— berlina implicită pe hartă',
                  tag: 'MAP',
                );
                return _generateMarkerIcon(
                  isPassenger: false,
                  customAssetPath: null,
                );
              }
            }
          } catch (e) {
            Logger.debug('Verificare opacitate marker garaj: $e', tag: 'MAP');
          }
        }
        // Stripper BFS: doar pentru berlina implicită — pe PNG-uri din garaj ștergea prea mult (sprite gri/alb)
        // și markerul devenea invizibil pe hartă.
        if (!isCustom) {
          try {
            final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
            if (data != null) {
              final buffer = data.buffer.asUint8List();
              final w = maxSize.toInt();
              final h = maxSize.toInt();
              final visited = List<bool>.filled(w * h, false);
              final queue = <int>[];

              for (final startIdx in [0, (w - 1), (h - 1) * w, (h * w - 1)]) {
                if (!visited[startIdx]) queue.add(startIdx);
              }

              bool modified = false;
              while (queue.isNotEmpty) {
                final idx = queue.removeAt(0);
                if (visited[idx]) continue;
                visited[idx] = true;

                final r = buffer[idx * 4];
                final g = buffer[idx * 4 + 1];
                final b = buffer[idx * 4 + 2];
                final a = buffer[idx * 4 + 3];

                bool isBg = false;
                if (a < 20) {
                  isBg = true;
                } else if (r > 240 && g > 240 && b > 240) {
                  isBg = true;
                } else if (r == g && g == b && r > 180 && r < 235) {
                  isBg = true;
                } else if (r == g && g == b && r > 40 && r < 100) {
                  isBg = true;
                }

                if (isBg) {
                  buffer[idx * 4 + 3] = 0;
                  modified = true;

                  final x = idx % w;
                  final y = idx ~/ w;
                  if (x > 0 && !visited[idx - 1]) queue.add(idx - 1);
                  if (x < w - 1 && !visited[idx + 1]) queue.add(idx + 1);
                  if (y > 0 && !visited[idx - w]) queue.add(idx - w);
                  if (y < h - 1 && !visited[idx + w]) queue.add(idx + w);
                }
              }

              if (modified) {
                const int minOpaqueAfterStrip = 120;
                final opaque = _countRgbaOpaquePixels(buffer, w, h);
                if (opaque < minOpaqueAfterStrip) {
                  Logger.warning(
                    'Default car marker: BFS strip would leave only $opaque opaque px; keeping original',
                    tag: 'MAP',
                  );
                } else {
                  final completer = Completer<ui.Image>();
                  ui.decodeImageFromPixels(
                    buffer,
                    w,
                    h,
                    ui.PixelFormat.rgba8888,
                    completer.complete,
                  );
                  img = await completer.future;
                }
              }
            }
          } catch (e) {
            Logger.debug('Surgical Transparency Strip Error: $e');
          }
        }

        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        final bytes = _pngBytesOrMinimalFallback(
          byteData,
          '_generateMarkerIcon asset=$path',
        );
        _markerIconCache[cacheKey] = bytes;
        return bytes;
      } catch (_) {
        // Dacă dintr-un motiv asset-ul nu poate fi încărcat, continuăm cu fallback-ul de mai jos.
      }
    }

    const double size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
    final paint = ui.Paint()..isAntiAlias = true;

    if (isPassenger) {
      // ── Pasager: cerc albastru cu punct alb ──────────────────────────
      const center = ui.Offset(size / 2, size / 2);
      const radius = size / 2 - 4;
      paint
        ..color = const ui.Color(0x44000000)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
      canvas.drawCircle(center.translate(0, 2), radius, paint);
      paint.maskFilter = null;
      paint.color = const ui.Color(0xFFFFFFFF);
      canvas.drawCircle(center, radius + 2, paint);
      paint.color = const ui.Color(0xFF1976D2);
      canvas.drawCircle(center, radius, paint);
      paint.color = const ui.Color(0xFFFFFFFF);
      canvas.drawCircle(center, radius * 0.38, paint);
    } else {
      // ── Șofer: mașinuță 3D premium ──────────────────────────────────────────
      final double cx = size / 2;
      final double cy = size / 2;

      // 1. DROP SHADOW
      paint
        ..color = const ui.Color(0x55000000)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCenter(center: ui.Offset(cx + 2, cy + 5), width: 38, height: 62),
          const ui.Radius.circular(12),
        ),
        paint,
      );
      paint.maskFilter = null;

      // 2. CAROSERIE — gradient lateral pentru efect 3D
      paint.shader = ui.Gradient.linear(
        ui.Offset(cx - 19, cy),
        ui.Offset(cx + 19, cy),
        [
          const ui.Color(0xFF0D1457),
          const ui.Color(0xFF3949AB),
          const ui.Color(0xFF283593),
          const ui.Color(0xFF0D1457),
        ],
        [0.0, 0.35, 0.65, 1.0],
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 38, height: 64),
          const ui.Radius.circular(12),
        ),
        paint,
      );
      paint.shader = null;

      // 3. ROATĂ față-stânga
      _draw3DWheel(canvas, paint, cx - 22, cy - 20, 8, 12);
      // 4. ROATĂ față-dreapta
      _draw3DWheel(canvas, paint, cx + 14, cy - 20, 8, 12);
      // 5. ROATĂ spate-stânga
      _draw3DWheel(canvas, paint, cx - 22, cy + 10, 8, 12);
      // 6. ROATĂ spate-dreapta
      _draw3DWheel(canvas, paint, cx + 14, cy + 10, 8, 12);

      // 7. CAPOTĂ față — gradient
      paint.shader = ui.Gradient.linear(
        ui.Offset(cx, cy - 32),
        ui.Offset(cx, cy - 16),
        [const ui.Color(0xFF5C6BC0), const ui.Color(0xFF283593)],
        [0.0, 1.0],
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(cx - 15, cy - 32, 30, 16),
          const ui.Radius.circular(5),
        ),
        paint,
      );
      paint.shader = null;

      // 8. PAVILION (roof) — mai ridicat, culoare distinctă
      paint.shader = ui.Gradient.linear(
        ui.Offset(cx - 12, cy - 18),
        ui.Offset(cx + 12, cy + 10),
        [const ui.Color(0xFF7986CB), const ui.Color(0xFF3949AB), const ui.Color(0xFF1A237E)],
        [0.0, 0.5, 1.0],
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(cx - 12, cy - 18, 24, 30),
          const ui.Radius.circular(7),
        ),
        paint,
      );
      paint.shader = null;

      // 9. PARBRIZ față
      paint.shader = ui.Gradient.linear(
        ui.Offset(cx - 10, cy - 17),
        ui.Offset(cx + 10, cy - 5),
        [const ui.Color(0xCC9CE7FF), const ui.Color(0x9954D1F7)],
        [0.0, 1.0],
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(cx - 10, cy - 17, 20, 12),
          const ui.Radius.circular(3),
        ),
        paint,
      );
      paint.shader = null;
      // Reflexie parbriz
      paint.color = const ui.Color(0x55FFFFFF);
      final glarePath = ui.Path()
        ..moveTo(cx - 9, cy - 16)
        ..lineTo(cx - 3, cy - 16)
        ..lineTo(cx - 6, cy - 6)
        ..lineTo(cx - 10, cy - 6)
        ..close();
      canvas.drawPath(glarePath, paint);

      // 10. LUNETA spate
      paint.shader = ui.Gradient.linear(
        ui.Offset(cx, cy + 4),
        ui.Offset(cx, cy + 14),
        [const ui.Color(0x9954D1F7), const ui.Color(0xCC1E6E8A)],
        [0.0, 1.0],
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(cx - 9, cy + 4, 18, 10),
          const ui.Radius.circular(3),
        ),
        paint,
      );
      paint.shader = null;

      // 11. CAPOTĂ spate
      paint.shader = ui.Gradient.linear(
        ui.Offset(cx, cy + 16),
        ui.Offset(cx, cy + 32),
        [const ui.Color(0xFF283593), const ui.Color(0xFF0D1457)],
        [0.0, 1.0],
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(cx - 15, cy + 16, 30, 16),
          const ui.Radius.circular(5),
        ),
        paint,
      );
      paint.shader = null;

      // 12. FARURI față — glow alb-galben
      _drawHeadlight(canvas, paint, cx - 13, cy - 32, isRear: false);
      _drawHeadlight(canvas, paint, cx + 13, cy - 32, isRear: false);

      // 13. STOPURI spate — glow roșu
      _drawHeadlight(canvas, paint, cx - 13, cy + 32, isRear: true);
      _drawHeadlight(canvas, paint, cx + 13, cy + 32, isRear: true);

      // 14. HIGHLIGHT corp — shimmer stânga-sus pentru efect 3D
      paint.shader = ui.Gradient.linear(
        ui.Offset(cx - 19, cy - 32),
        ui.Offset(cx - 5, cy),
        [const ui.Color(0x44FFFFFF), const ui.Color(0x00FFFFFF)],
        [0.0, 1.0],
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(cx - 19, cy - 32, 14, 45),
          const ui.Radius.circular(12),
        ),
        paint,
      );
      paint.shader = null;

      // 15. INDICATOR disponibil (punct verde aprins)
      paint
        ..color = const ui.Color(0x6600C853)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
      canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 8, paint);
      paint.maskFilter = null;
      paint.color = const ui.Color(0xFF00E676);
      canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 6, paint);
      paint.color = const ui.Color(0xFF69F0AE);
      canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 3, paint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = _pngBytesOrMinimalFallback(
      byteData,
      '_generateMarkerIcon(vector path, isPassenger=$isPassenger)',
    );
    _markerIconCache[cacheKey] = bytes;
    return bytes;
  }

  static void _draw3DWheel(
      ui.Canvas canvas, ui.Paint paint, double x, double y, double w, double h) {
    // Outer tire (dark)
    paint.shader = ui.Gradient.linear(
      ui.Offset(x, y),
      ui.Offset(x + w, y + h),
      [const ui.Color(0xFF424242), const ui.Color(0xFF212121)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(x, y, w, h),
        const ui.Radius.circular(3),
      ),
      paint,
    );
    paint.shader = null;
    // Rim highlight
    paint.color = const ui.Color(0x66FFFFFF);
    canvas.drawOval(
      ui.Rect.fromLTWH(x + 1.5, y + 1.5, w - 3, h * 0.45),
      paint,
    );
  }

  static void _drawHeadlight(
      ui.Canvas canvas, ui.Paint paint, double cx, double cy,
      {required bool isRear}) {
    final glowColor =
        isRear ? const ui.Color(0xAAFF1744) : const ui.Color(0xAAFFFFFF);
    final coreColor =
        isRear ? const ui.Color(0xFFFF1744) : const ui.Color(0xFFFFFFFF);
    final innerColor =
        isRear ? const ui.Color(0xFFFF8A80) : const ui.Color(0xFFFFEB3B);
    // Glow
    paint
      ..color = glowColor
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawOval(ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 10, height: 6), paint);
    paint.maskFilter = null;
    // Core
    paint.color = coreColor;
    canvas.drawOval(ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 7, height: 4), paint);
    // Inner
    paint.color = innerColor;
    canvas.drawOval(ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 4, height: 2.5), paint);
  }

  /// Pe loc: netezire ușoară (zgomot GPS). În mișcare: fără interpolare poziție — avatar aliniat cu puck.
  static const double _driverMarkerPosLerpSoft = 0.34;

  void _resetDriverMarkerInterpolation() {
    _driverMarkerSmoothLat = null;
    _driverMarkerSmoothLng = null;
    _driverMarkerSmoothHeadingDeg = null;
  }

  static double _lerpBearingDegrees(double fromDeg, double toDeg, double t) {
    var delta = (toDeg - fromDeg) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    var r = fromDeg + delta * t;
    r %= 360;
    if (r < 0) r += 360;
    return r;
  }

  bool get _useAndroidFlutterUserMarkerOverlay =>
      defaultTargetPlatform == TargetPlatform.android;

  void _clearAndroidUserMarkerOverlayFields() {
    _androidUserMarkerGeometry = null;
    _androidUserMarkerOverlayPx = null;
    _androidUserMarkerOverlayHeadingDeg = 0;
    _androidUserMarkerOverlayImageBytes = null;
    _androidUserMarkerOverlayLabel = null;
  }

  void _clearAndroidHomePinOverlayFields() {
    _androidHomePinGeometry = null;
    _androidHomePinOverlayPx = null;
    _androidHomePinOverlayBytes = null;
  }

  Future<void> _projectAndroidHomePinOverlay() async {
    if (!_useAndroidFlutterUserMarkerOverlay) return;
    if (!mounted || _mapboxMap == null) return;
    final g = _androidHomePinGeometry;
    if (g == null || _androidHomePinOverlayBytes == null) {
      if (mounted) setState(() => _androidHomePinOverlayPx = null);
      return;
    }
    try {
      final sc = await _mapboxMap!.pixelForCoordinate(g);
      if (!mounted) return;
      setState(() {
        _androidHomePinOverlayPx = Offset(sc.x.toDouble(), sc.y.toDouble());
      });
    } catch (e) {
      Logger.debug('Android home pin overlay project: $e', tag: 'MAP_HOME');
    }
  }

  Future<void> _projectAndroidUserMarkerOverlay() async {
    if (!_useAndroidFlutterUserMarkerOverlay) return;
    if (!mounted || _mapboxMap == null) return;
    final g = _androidUserMarkerGeometry;
    if (g == null || _androidUserMarkerOverlayImageBytes == null) {
      if (mounted) setState(() => _androidUserMarkerOverlayPx = null);
      return;
    }
    try {
      final sc = await _mapboxMap!.pixelForCoordinate(g);
      if (!mounted) return;
      setState(() {
        _androidUserMarkerOverlayPx = Offset(sc.x.toDouble(), sc.y.toDouble());
      });
    } catch (e) {
      Logger.debug('Android user marker overlay project: $e', tag: 'MAP');
    }
  }

  Future<void> _updateUserMarker({bool centerCamera = false}) async {
    final previous = _userMarkerUpdateChain;
    final done = Completer<void>();
    _userMarkerUpdateChain = done.future;
    try {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      await _runUserMarkerUpdate(centerCamera: centerCamera);
    } finally {
      if (!done.isCompleted) done.complete();
    }
  }

  Future<void> _runUserMarkerUpdate({bool centerCamera = false}) async {
          if (!mounted) {
      Logger.debug('🔕 Skipping marker update - widget unmounted or navigating');
      return;
    }
    if (!_mapSurfaceSafeForUserMarker) {
      Logger.debug(
        'Skipping marker update — map surface flagged unsafe (e.g. app paused)',
        tag: 'MAP',
      );
      return;
    }
    if (_mapboxMap == null) return;

    final geolocator.Position? markerPos = _positionForUserMapMarker();
    if (markerPos == null) {
      Logger.warning('Skipping marker update - no current or cached position');
      if (_useAndroidFlutterUserMarkerOverlay && mounted) {
        setState(_clearAndroidUserMarkerOverlayFields);
      }
      return;
    }

    if (!_useAndroidFlutterUserMarkerOverlay) {
      if (_userPointAnnotationManager == null) {
        if (_isCreatingUserMarkerManager) return;
        _isCreatingUserMarkerManager = true;
        try {
          _userPointAnnotationManager = await _mapboxMap?.annotations.createPointAnnotationManager(id: 'user-marker-manager');
        } catch (e) {
          Logger.warning('Could not create user annotation manager: $e');
        } finally {
          _isCreatingUserMarkerManager = false;
        }

        if (_userPointAnnotationManager == null) {
          Logger.warning('Skipping marker update - annotation manager is null');
          return;
        }
      }
    }

    try {
      // Ierarhie: Galaxy Garage (non-default) → berlină standard (inclusiv pasager/off-duty cu default_car).
      final visualKey = _ownUserMarkerVisualKey();
      final bool isEmojiMode = visualKey.startsWith('passenger:emoji:');

      final live = _currentPositionObject;
      final tgtLat = live?.latitude ?? markerPos.latitude;
      final tgtLng = live?.longitude ?? markerPos.longitude;

      double rawHeading = 0.0;
      final headingSrc = live ?? markerPos;
      if (!headingSrc.heading.isNaN) {
        rawHeading = headingSrc.heading;
        if (rawHeading < 0) rawHeading += 360;
      }

      final moving = !headingSrc.speed.isNaN && headingSrc.speed >= 0.5;
      // În mers: fără lag de interpolare — același țint ca GPS-ul folosit și de puck (Geolocator).
      final snapToLivePosition = moving;
      final double posLerp =
          snapToLivePosition ? 1.0 : _driverMarkerPosLerpSoft;

      _driverMarkerSmoothLat ??= tgtLat;
      _driverMarkerSmoothLng ??= tgtLng;
      if (posLerp >= 1.0) {
        _driverMarkerSmoothLat = tgtLat;
        _driverMarkerSmoothLng = tgtLng;
      } else {
        _driverMarkerSmoothLat = _driverMarkerSmoothLat! +
            (tgtLat - _driverMarkerSmoothLat!) * posLerp;
        _driverMarkerSmoothLng = _driverMarkerSmoothLng! +
            (tgtLng - _driverMarkerSmoothLng!) * posLerp;
      }

      final headingForIcon =
          moving ? rawHeading : (_driverMarkerSmoothHeadingDeg ?? rawHeading);
      _driverMarkerSmoothHeadingDeg ??= headingForIcon;
      if (snapToLivePosition) {
        _driverMarkerSmoothHeadingDeg = headingForIcon;
      } else {
        _driverMarkerSmoothHeadingDeg = _lerpBearingDegrees(
          _driverMarkerSmoothHeadingDeg!,
          headingForIcon,
          0.12,
        );
      }

      final resolved = _resolvedPlateAndPublicName();
      final driverDuty = _driverOnDutyOnMap;
      String? textField;
      if (driverDuty) {
        if (resolved.plate != null && resolved.name != null) {
          textField = '${resolved.plate}\n${resolved.name}';
        } else if (resolved.plate != null) {
          textField = resolved.plate;
        } else if (resolved.name != null) {
          textField = resolved.name;
        }
      } else if (resolved.name != null) {
        textField = resolved.name;
      }

      const double driverLabelSize = 11.5;
      const int driverLabelColor = 0xFF1A237E;
      const List<double> driverLabelOffset = [0.0, 2.45];

      if (_useAndroidFlutterUserMarkerOverlay) {
        if (!mounted) return;
        if (_forceUserCarMarkerFullRebuild) {
          _forceUserCarMarkerFullRebuild = false;
          _userMarkerVisualCacheKey = null;
          _androidUserMarkerOverlayImageBytes = null;
        }
        if (_userPointAnnotationManager != null || _userPointAnnotation != null) {
          try {
            await _userPointAnnotationManager?.deleteAll();
          } catch (_) {}
          _userPointAnnotationManager = null;
          _userPointAnnotation = null;
        }
        if (_userMarkerVisualCacheKey != visualKey ||
            _androidUserMarkerOverlayImageBytes == null) {
          late final Uint8List imageList;
          final Future<Uint8List> bitmapFuture;
          final garagePath = _garageAssetPathForCurrentRole;
          if (garagePath != null) {
            bitmapFuture = _generateMarkerIcon(
              isPassenger: !_driverOnDutyOnMap,
              customAssetPath: garagePath,
            );
          } else {
            bitmapFuture =
                _generateMarkerIcon(isPassenger: false, customAssetPath: null);
          }
          final gen = _userDriverMarkerIconInFlight ??= bitmapFuture;
          try {
            imageList = await gen;
          } catch (e, st) {
            Logger.error(
              'Icon marker utilizator eșuat — fallback vector: $e',
              tag: 'MAP',
              error: e,
              stackTrace: st,
            );
            imageList = await _generateMarkerIcon(
              isPassenger: false,
              customAssetPath: null,
            );
          } finally {
            if (identical(_userDriverMarkerIconInFlight, gen)) {
              _userDriverMarkerIconInFlight = null;
            }
          }
          if (!mounted) return;
          _androidUserMarkerOverlayImageBytes = imageList;
          _userMarkerVisualCacheKey = visualKey;
        }
        final latU = _driverMarkerSmoothLat ?? tgtLat;
        final lngU = _driverMarkerSmoothLng ?? tgtLng;
        final headU =
            isEmojiMode ? 0.0 : (_driverMarkerSmoothHeadingDeg ?? headingForIcon);
        _androidUserMarkerGeometry = MapboxUtils.createPoint(latU, lngU);
        _androidUserMarkerOverlayHeadingDeg = headU;
        _androidUserMarkerOverlayLabel = textField;
        await _projectAndroidUserMarkerOverlay();
        Logger.info(
          'User marker Android Flutter overlay: lat=${latU.toStringAsFixed(6)} '
          'lng=${lngU.toStringAsFixed(6)} visualKey=$visualKey '
          'bytes=${_androidUserMarkerOverlayImageBytes?.length}',
          tag: 'MAP',
        );
      } else {
        if (!mounted || _userPointAnnotationManager == null) {
          Logger.debug('Aborting marker update - state changed during operation');
          return;
        }

        if (_forceUserCarMarkerFullRebuild) {
          _forceUserCarMarkerFullRebuild = false;
          try {
            await _userPointAnnotationManager!.deleteAll();
          } catch (_) {}
          _userPointAnnotation = null;
          _userMarkerVisualCacheKey = null;
        }

        // Schimbare bitmap (garaj / mod / avatar profil): recreate — Mapbox nu actualizează mereu iconul doar din `update`.
        if (_userPointAnnotation != null && _userMarkerVisualCacheKey != visualKey) {
          try {
            await _userPointAnnotationManager!.deleteAll();
          } catch (_) {}
          _userPointAnnotation = null;
        }

        final double iconSz = isEmojiMode ? 0.71 : 0.89;

        if (_userPointAnnotation != null) {
          try {
            final latU = _driverMarkerSmoothLat ?? tgtLat;
            final lngU = _driverMarkerSmoothLng ?? tgtLng;
            final headU = _driverMarkerSmoothHeadingDeg ?? headingForIcon;
            _userPointAnnotation!.geometry = MapboxUtils.createPoint(latU, lngU);
            _userPointAnnotation!.iconRotate = isEmojiMode ? 0.0 : headU;
            _userPointAnnotation!.iconSize = iconSz;
            _userPointAnnotation!.symbolSortKey = 2.55e6;
            if (textField != null) {
              _userPointAnnotation!.textField = textField;
              _userPointAnnotation!.textSize = driverLabelSize;
              _userPointAnnotation!.textOffset = driverLabelOffset;
              _userPointAnnotation!.textColor = driverLabelColor;
              _userPointAnnotation!.textHaloColor = 0xFFFFFFFF;
              _userPointAnnotation!.textHaloWidth = 2.0;
            }
            await _userPointAnnotationManager!.update(_userPointAnnotation!);
            Logger.debug(
              'User marker update OK: id=${_userPointAnnotation!.id} '
              'lat=${latU.toStringAsFixed(6)} lng=${lngU.toStringAsFixed(6)} '
              'visualKey=$visualKey iconSize=$iconSz',
              tag: 'MAP',
            );
          } catch (e) {
            Logger.debug('User marker update → full recreate: $e');
            try {
              await _userPointAnnotationManager!.deleteAll();
            } catch (_) {}
            _userPointAnnotation = null;
            _userMarkerVisualCacheKey = null;
          }
        }

        if (_userPointAnnotation == null) {
          final latBeforeAwait = _driverMarkerSmoothLat ?? tgtLat;
          final lngBeforeAwait = _driverMarkerSmoothLng ?? tgtLng;
          final headBeforeAwait = _driverMarkerSmoothHeadingDeg ?? headingForIcon;

          late final Uint8List imageList;
          // Prevent concurrent expensive icon generation (can cause ANR).
          final Future<Uint8List> bitmapFuture;
          final garagePath = _garageAssetPathForCurrentRole;
          if (garagePath != null) {
            bitmapFuture = _generateMarkerIcon(
              isPassenger: !_driverOnDutyOnMap,
              customAssetPath: garagePath,
            );
          } else {
            bitmapFuture =
                _generateMarkerIcon(isPassenger: false, customAssetPath: null);
          }
          final gen = _userDriverMarkerIconInFlight ??= bitmapFuture;
          try {
            imageList = await gen;
          } catch (e, st) {
            Logger.error(
              'Icon marker utilizator eșuat — fallback vector: $e',
              tag: 'MAP',
              error: e,
              stackTrace: st,
            );
            imageList = await _generateMarkerIcon(
              isPassenger: false,
              customAssetPath: null,
            );
          } finally {
            if (identical(_userDriverMarkerIconInFlight, gen)) {
              _userDriverMarkerIconInFlight = null;
            }
          }

          if (!mounted || _userPointAnnotationManager == null) return;

          final latForGeom = _driverMarkerSmoothLat ?? latBeforeAwait;
          final lngForGeom = _driverMarkerSmoothLng ?? lngBeforeAwait;
          final headForGeom = isEmojiMode ? 0.0 : (_driverMarkerSmoothHeadingDeg ?? headBeforeAwait);

          final options = PointAnnotationOptions(
            geometry: MapboxUtils.createPoint(latForGeom, lngForGeom),
            image: imageList,
            iconSize: iconSz,
            iconAnchor: IconAnchor.CENTER,
            iconRotate: headForGeom,
            // Mașina proprie deasupra pinului Acasă (2e6), altfel la suprapunere utilizatorul „nu vede” avatarul.
            symbolSortKey: 2.55e6,
            textField: textField,
            textSize: textField != null ? driverLabelSize : null,
            textColor: textField != null ? driverLabelColor : null,
            textHaloColor: textField != null ? 0xFFFFFFFF : null,
            textHaloWidth: textField != null ? 2.0 : null,
            textOffset: textField != null ? driverLabelOffset : null,
            textJustify: textField != null ? TextJustify.CENTER : null,
          );

          _userPointAnnotation = await _userPointAnnotationManager?.create(options);
          if (_userPointAnnotation == null) {
            _userMarkerVisualCacheKey = null;
            Logger.warning(
              'User point annotation create returned null — enabling location puck fallback '
              '(lat=${latForGeom.toStringAsFixed(6)} lng=${lngForGeom.toStringAsFixed(6)} visualKey=$visualKey imageBytes=${imageList.length})',
              tag: 'MAP',
            );
            unawaited(_updateLocationPuck());
          } else {
            _userMarkerVisualCacheKey = visualKey;
            Logger.info(
              'User marker created OK: id=${_userPointAnnotation!.id} '
              'lat=${latForGeom.toStringAsFixed(6)} lng=${lngForGeom.toStringAsFixed(6)} '
              'visualKey=$visualKey imageBytes=${imageList.length} iconSize=$iconSz',
              tag: 'MAP',
            );
          }
        }
      }

      if (centerCamera && _mapboxMap != null && mounted) {
        await _mapboxMap?.easeTo(
          CameraOptions(
            center: MapboxUtils.createPoint(tgtLat, tgtLng),
            zoom: _overviewZoomForLatitude(tgtLat),
          ),
          MapAnimationOptions(duration: AppDrawer.lowDataMode ? 480 : 920),
        );
        
        // ✅ ACTUALIZARE AUTOMATĂ POI-uri la schimbarea locației
        // (POI auto-update este dezactivat; se afișează doar POI-ul selectat)
      }
    } catch (e) {
      Logger.error('Non-fatal error during _runUserMarkerUpdate: $e', error: e);
    }

    final pBox = _currentPositionObject ?? markerPos;
    if (_mysteryBoxManager != null) {
      unawaited(_mysteryBoxManager!.updateMysteryBoxes(
        pBox.latitude,
        pBox.longitude,
      ));
    }
  }

  /// Ultima poziție utilă pentru desenarea markerului (GPS curent sau cache recent).
  geolocator.Position? _positionForUserMapMarker() {
    final cur = _currentPositionObject;
    if (cur != null) return cur;
    return LocationCacheService.instance.peekRecent(
      maxAge: const Duration(minutes: 45),
    );
  }

  /// Updates the Mapbox LocationPuck behavior.
  /// Puck activ când nu putem desena markerul personalizat în siguranță sau nu avem deloc poziție.
  Future<void> _updateLocationPuck() async {
    if (_mapboxMap == null) return;
    try {
      final pos = _positionForUserMapMarker();
      final canDrawCustom =
          _mapSurfaceSafeForUserMarker && pos != null;
      // Pe Android apar des curse Surface/GL; stratul de simbol pentru marker poate eșua
      // la randare deși create/update raportează succes — puck-ul rămâne c și indicație de rezervă.
      final usePuckBackup =
          defaultTargetPlatform == TargetPlatform.android && canDrawCustom;
      if (!canDrawCustom || usePuckBackup) {
        await _mapboxMap!.location.updateSettings(
          LocationComponentSettings(
            enabled: true,
            pulsingEnabled: true,
            pulsingMaxRadius: 60.0,
            pulsingColor: const Color(0xFF3682F3).toARGB32(),
          ),
        );
        Logger.info(
          'Location puck ON: safeSurface=$_mapSurfaceSafeForUserMarker '
          'pos=${pos != null ? '${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}' : 'null'}'
          '${usePuckBackup ? ' (Android backup alongside custom marker)' : ''}',
          tag: 'MAP',
        );
      } else {
        await _mapboxMap!.location.updateSettings(
          LocationComponentSettings(enabled: false),
        );
        Logger.debug(
          'Location puck OFF (custom marker path): '
          'pos=${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}',
          tag: 'MAP',
        );
      }
    } catch (e) {
      Logger.warning('Could not update location puck: $e', tag: 'MAP');
    }
  }

  Future<void> _updateNearbyDrivers(List<QueryDocumentSnapshot<Map<String, dynamic>>> driverDocs) async {
    if (!mounted) return;
    // ✅ LOCK: Prevenim crearea a doi manageri simultan (cauza dublurilor)
    if (_driversAnnotationManager == null) {
      if (_isCreatingDriversManager) return;
      _isCreatingDriversManager = true;
      try {
        _driversAnnotationManager ??= await _mapboxMap?.annotations.createPointAnnotationManager(
          id: 'nearby-drivers-annotation-manager',
        );
        _registerDriversAnnotationTapHandler();
      } catch (e) {
        Logger.error('Failed to create drivers manager: $e');
      } finally {
        _isCreatingDriversManager = false;
      }
    }
    if (_driversAnnotationManager == null) return;

    try {
      // Prevent concurrent expensive icon generation (can cause ANR).
      _nearbyDriversMarkerIconInFlight ??= _generateMarkerIcon(isPassenger: false);
      late final Uint8List imageList;
      try {
        imageList = await _nearbyDriversMarkerIconInFlight!;
      } finally {
        _nearbyDriversMarkerIconInFlight = null;
      }

      final currentDriverIds = driverDocs.map((doc) => doc.id).toSet();
      final displayedDriverIds = _nearbyDriverAnnotations.keys.toSet();

      final driversToRemove = displayedDriverIds.difference(currentDriverIds);
      if (driversToRemove.isNotEmpty) {
        for (final id in driversToRemove) {
          final annotation = _nearbyDriverAnnotations.remove(id);
          if (annotation != null && mounted) {
            _driverAnnotationIdToUid.remove(annotation.id);
            try {
              await _driversAnnotationManager?.delete(annotation);
            } catch (_) {}
          }
        }
      }

      final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
      for (var driverDoc in driverDocs) {
        if (!mounted) break;
        if (currentUid != null && driverDoc.id == currentUid) continue;
        
        // RE-INTĂRIT: Arată DOAR șoferii care sunt în agenda telefonului (contacte)
        if (_contactUids == null || !_contactUids!.contains(driverDoc.id)) continue;
        
        final data = driverDoc.data();
        if (data['position'] != null) {
          final GeoPoint pos = data['position'] as GeoPoint;
          final double? bearing = data['bearing'] as double?;

          double correctedBearing = 0.0;
          if (bearing != null && !bearing.isNaN) {
            correctedBearing = bearing + 180;
            if (correctedBearing >= 360) correctedBearing -= 360;
          }

          if (_nearbyDriverAnnotations.containsKey(driverDoc.id)) {
            final annotation = _nearbyDriverAnnotations[driverDoc.id]!;
            annotation.geometry = MapboxUtils.createPoint(pos.latitude, pos.longitude);
            annotation.iconRotate = correctedBearing;
            annotation.iconSize = 0.72; // vizibilitate pe hartă (contacte / șoferi disponibili)
            try {
              await _driversAnnotationManager?.update(annotation);
            } catch (_) {
              _driverAnnotationIdToUid.remove(annotation.id);
              _nearbyDriverAnnotations.remove(driverDoc.id);
            }
          } else {
            // Prevenim crearea a 2 markere pt același UID dacă stream-ul e rapid
            if (_nearbyDriverUidsBeingCreated.contains(driverDoc.id)) continue;
            _nearbyDriverUidsBeingCreated.add(driverDoc.id);

            final options = PointAnnotationOptions(
              geometry: MapboxUtils.createPoint(pos.latitude, pos.longitude), 
              image: imageList,
              iconSize: 0.72,
              iconAnchor: IconAnchor.BOTTOM,
              iconRotate: correctedBearing,
            );
            try {
              final newAnnotation = await _driversAnnotationManager?.create(options);
              if (newAnnotation != null && mounted) {
                _nearbyDriverAnnotations[driverDoc.id] = newAnnotation;
                _driverAnnotationIdToUid[newAnnotation.id] = driverDoc.id;
              }
            } catch (_) {
            } finally {
              _nearbyDriverUidsBeingCreated.remove(driverDoc.id);
            }
          }
        }
      }
    } catch (e) {
      Logger.error('Non-fatal error during _updateNearbyDrivers: $e', error: e);
    }
  }

  // ── Strat Cereri Cursă (Ride Broadcasts) — Pentru Șoferi ────────────────────

  void _listenForRideBroadcasts() {
    _rideBroadcastsSubscription?.cancel();
    if (_currentRole != UserRole.driver) return;

    // Ascultăm cererile active (status 'open') din cartier
    _rideBroadcastsSubscription = _firestoreService.instance
        .collection('ride_broadcasts')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;

      final List<RideBroadcastRequest> broadcasts = [];
      final now = DateTime.now();
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final broadcast = RideBroadcastRequest.fromMap(doc.id, data);
          if (!broadcast.expiresAt.isAfter(now)) continue;

          // Filtru contacte: șoferul vede doar cererile contactelor sale
          if (_contactUids != null && _contactUids!.contains(broadcast.passengerId)) {
             broadcasts.add(broadcast);
          }
        } catch (e) {
          Logger.error('Error parsing broadcast: $e');
        }
      }

      await _updateRideBroadcastAnnotations(broadcasts);
    });
  }

  Future<void> _updateRideBroadcastAnnotations(List<RideBroadcastRequest> broadcasts) async {
    if (_mapboxMap == null) return;

    if (_rideBroadcastsAnnotationManager == null) {
      _rideBroadcastsAnnotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();
      _rideBroadcastsAnnotationManager!.tapEvents(onTap: (annotation) {
        final broadcast = _rideBroadcastData[annotation.id];
        if (broadcast != null) {
          _onRideBroadcastClicked(broadcast);
        }
      });
    }

    final currentIds = broadcasts.map((b) => b.id).toSet();
    
    // Eliminăm cele care nu mai sunt active
    final toRemove = <String>[];
    _rideBroadcastAnnotations.forEach((id, annotation) {
      if (!currentIds.contains(id)) {
        toRemove.add(id);
      }
    });

    for (var id in toRemove) {
      final annotation = _rideBroadcastAnnotations.remove(id);
      if (annotation != null) {
        try {
          await _rideBroadcastsAnnotationManager?.delete(annotation);
          _rideBroadcastData.remove(annotation.id);
        } catch (_) {}
      }
    }

    // Adăugăm / Actualizăm
    for (var b in broadcasts) {
      final geom = MapboxUtils.createPoint(b.passengerLat, b.passengerLng);
      if (_rideBroadcastAnnotations.containsKey(b.id)) {
        final existing = _rideBroadcastAnnotations[b.id]!;
        existing.geometry = geom;
        try {
          await _rideBroadcastsAnnotationManager?.update(existing);
        } catch (_) {}
      } else {
        final icon = await _generateDemandMarker(b.passengerAvatar);
        final options = PointAnnotationOptions(
          geometry: geom,
          image: icon,
          iconSize: 2.2, 
          iconAnchor: IconAnchor.CENTER,
        );
        try {
          final annotation = await _rideBroadcastsAnnotationManager?.create(options);
          if (annotation != null) {
            _rideBroadcastAnnotations[b.id] = annotation;
            _rideBroadcastData[annotation.id] = b;
          }
        } catch (_) {}
      }
    }
  }

  void _onRideBroadcastClicked(RideBroadcastRequest broadcast) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${broadcast.passengerAvatar} ${broadcast.passengerName}', 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Vrea să meargă la: ${broadcast.destination ?? 'Destinație nestabilită'}', 
               textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                minimumSize: const ui.Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RideBroadcastFeedScreen()));
              },
              child: const Text('VEZI CEREREA ȘI OFERĂ CURSĂ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _listenForNearbyDrivers() {
    if (!mounted || _isInitializingDrivers) return;
    _isInitializingDrivers = true;

    _nearbyDriversSubscription?.cancel();
    _nearbyDriversSubscription = _firestoreService.getNearbyAvailableDrivers().listen((snapshot) {
      if (mounted) {
        _updateNearbyDrivers(snapshot.docs);
        unawaited(PushCampaignService().notifyHighSupply(snapshot.docs.length));
      }
    }, onError: (e) {
      Logger.error('Nearby drivers stream error: $e', tag: 'MAP', error: e);
      _isInitializingDrivers = false;
    });
    _isInitializingDrivers = false;
  }

  /// ✅ NOU: Radar SOS — Ascultă alertele active și randează aurele de siguranță pe hartă.
  void _listenForEmergencyAlerts() {
    _emergencyAlertsSubscription?.cancel();
    
    final fifteenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 15));
    
    _emergencyAlertsSubscription = FirebaseFirestore.instance
        .collection('emergency_alerts')
        .where('status', isEqualTo: 'active')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(fifteenMinutesAgo))
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      final currentUids = snapshot.docs.map((d) => d.id).toSet();
      
      // 1. Curățăm markerii și aurele pentru alertele dispărute / rezolvate
      final toRemove = _emergencyAnnotations.keys.where((id) => !currentUids.contains(id)).toList();
      for (var id in toRemove) {
        _removeEmergencyMarker(id);
      }

      // 2. Procesăm fiecare alertă curentă
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        
        // Nu ne auto-alertăm pe noi înșine cu radar (doar alții contează)
        if (data['userId'] == FirebaseAuth.instance.currentUser?.uid) continue;

        if (!_emergencyAnnotations.containsKey(id)) {
          _onNewEmergencyAlertReceived(id, data);
        } else {
          _updateEmergencyAuraSlot(id, data: data);
        }
      }
      
      if (mounted) setState(() {});
    }, onError: (e) => Logger.error('Emergency Radar error: $e', tag: 'MAP_SOS'));
  }

  Future<void> _onNewEmergencyAlertReceived(String id, Map<String, dynamic> data) async {
    final lat = data['latitude'] as double?;
    final lng = data['longitude'] as double?;
    final userName = data['userName'] as String? ?? 'Un vecin';
    
    if (lat == null || lng == null) return;

    // A. Adăugăm markerul SOS pe hartă
    await _addEmergencyMarker(id, lat, lng, userName);

    // B. Notificare locală
    LocalNotificationsService().showSimple(
      title: '🆘 SOS PROXIMITATE: $userName',
      body: 'Urgență activă în apropiere! Verifică radarul pe hartă.',
      payload: 'sos_$id',
    );

    // C. Fly-To cinematic (opțional, doar dacă e nou-nouță și nu suntem în navigație activă)
    if (!_inAppNavActive) {
      await _mapboxMap?.flyTo(
        CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 15.5, pitch: 45.0),
        MapAnimationOptions(duration: 3000),
      );
    }

    // D. Mesaj vocal
    if (_navTts != null) {
      unawaited(_navTts!.speak('Atenție! ALERTĂ S.O.S. în apropiere de la $userName. Radarul de proximitate este activat.'));
    }
  }

  Future<void> _addEmergencyMarker(String id, double lat, double lng, String name) async {
    if (_mapboxMap == null) return;
    
    _emergencyAnnotationManager ??= await _mapboxMap!.annotations.createPointAnnotationManager(id: 'sos-radar');

    // Generăm un icon SOS roșu neon
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 100, 100));
    final paint = ui.Paint()..color = Colors.red.shade600..isAntiAlias = true;
    
    // Glow pulsating
    paint..color = Colors.red.withValues(alpha: 0.4)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 15);
    canvas.drawCircle(const ui.Offset(50, 50), 40, paint);
    
    paint..color = Colors.red.shade900..style = ui.PaintingStyle.fill..maskFilter = null;
    canvas.drawCircle(const ui.Offset(50, 50), 30, paint);
    
    final tp = TextPainter(
      text: const TextSpan(text: '🆘', style: TextStyle(fontSize: 40)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, ui.Offset(50 - tp.width / 2, 50 - tp.height / 2));

    final img = await recorder.endRecording().toImage(100, 100);
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

    final ann = await _emergencyAnnotationManager!.create(PointAnnotationOptions(
      geometry: MapboxUtils.createPoint(lat, lng),
      image: bytes,
      iconSize: 0.8,
      textField: 'S.O.S. $name',
      textColor: Colors.redAccent.toARGB32(),
      textHaloColor: Colors.black.toARGB32(),
      textHaloWidth: 2.0,
      textSize: 10,
    ));
    
    _emergencyAnnotations[id] = ann;
    _updateEmergencyAuraSlot(id, data: {'latitude': lat, 'longitude': lng, 'userName': name});
  }

  void _updateEmergencyAuraSlot(String id, {Map<String, dynamic>? data}) async {
    if (_mapboxMap == null) return;
    
    final ann = _emergencyAnnotations[id];
    if (ann == null) return;
    
    final screenPos = await _mapboxMap!.pixelForCoordinate(ann.geometry);
    
    if (mounted) {
      setState(() {
        _emergencyAuraSlots.removeWhere((s) => s.eventId == id);
        _emergencyAuraSlots.add(NabourAuraMapSlot(
          eventId: id,
          screenCenter: Offset(screenPos.x, screenPos.y),
          radiusPx: 140, // Radar larg de proximitate
          userDensity: 80, // Intensitate maximă pentru SOS
          title: 'ZONĂ CRITICĂ',
          endsAt: DateTime.now().add(const Duration(minutes: 5)),
        ));
      });
    }
  }

  void _removeEmergencyMarker(String id) async {
    final ann = _emergencyAnnotations.remove(id);
    if (ann != null) {
      try {
        await _emergencyAnnotationManager?.delete(ann);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _emergencyAuraSlots.removeWhere((s) => s.eventId == id);
      });
    }
  }

  /// ✅ Sincronizează poziția pe ecran a aurelor de siguranță SOS cu mișcarea camerei.
  Future<void> _projectEmergencyAuraSlots() async {
    if (!mounted || _mapboxMap == null) return;
    if (_emergencyAnnotations.isEmpty) {
      if (_emergencyAuraSlots.isNotEmpty && mounted) {
        setState(() => _emergencyAuraSlots = []);
      }
      return;
    }
    try {
      final slots = <NabourAuraMapSlot>[];
      for (final entry in _emergencyAnnotations.entries) {
        final id = entry.key;
        final ann = entry.value;
        final sc = await _mapboxMap!.pixelForCoordinate(ann.geometry);
        
        slots.add(NabourAuraMapSlot(
          eventId: id,
          screenCenter: Offset(sc.x.toDouble(), sc.y.toDouble()),
          radiusPx: 140, // Radius constant pentru radar urgență
          userDensity: 80, // Intensitate plasmă (SOS e dens)
          title: '🆘 S.O.S. ACTIV',
          endsAt: DateTime.now().add(const Duration(minutes: 5)),
        ));
      }
      if (mounted) setState(() => _emergencyAuraSlots = slots);
    } catch (e) {
      Logger.debug('SOS Aura project: $e', tag: 'MAP_SOS');
    }
  }


  // ── Curățare Totală Harta Socială ──────────────────────────────────────

  Future<void> _clearSocialMapMarkers() async {
    // 1. Ștergem vecinii (emoticoane)
    for (final ann in _neighborAnnotations.values) {
      try {
        await _neighborsAnnotationManager?.delete(ann);
      } catch (_) {}
    }
    _neighborAnnotations.clear();
    _neighborAnnotationIdToUid.clear();
    _neighborData.clear();
    _neighborUidsBeingCreated.clear();

    // 2. Ștergem șoferii disponibili
    for (final ann in _nearbyDriverAnnotations.values) {
      try {
        await _driversAnnotationManager?.delete(ann);
      } catch (_) {}
    }
    _nearbyDriverAnnotations.clear();
    _driverAnnotationIdToUid.clear();
    _nearbyDriverUidsBeingCreated.clear();

    Logger.info('Social Map cleared (Role Switch / Reset)');
  }

  void _onRadarConfirmed() async {
    if (_radarCenter == null || _mapboxMap == null) return;
    
    final selected = <NeighborLocation>[];
    final cameraState = await _mapboxMap!.getCameraState();
    final metersPerPix = await _mapboxMap!.projection.getMetersPerPixelAtLatitude(
        _radarCenter!.coordinates.lat.toDouble(), cameraState.zoom);
    final radiusMeters = _radarRadius * metersPerPix;

    for (final neighbor in _neighborData.values) {
      final neighborPt = Point(coordinates: Position(neighbor.lng, neighbor.lat));
      final dist = MapboxUtils.calculateDistance(_radarCenter!, neighborPt);
      
      if (dist <= radiusMeters) {
        selected.add(neighbor);
      }
    }

    if (selected.isNotEmpty) {
      HapticService.instance.success();
      _onRadarSelectionCompleted(selected); // Reutilizăm logica de grup-chat/broadcast
    } else {
      _showSafeSnackBar('Niciun vecin găsit în radar 🕸️', Colors.blueGrey);
    }
    setState(() { _isRadarMode = false; });
  }

  void _onRadarSelectionCompleted(List<NeighborLocation> neighbors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.radar, size: 48, color: Color(0xFF7C3AED)),
            const SizedBox(height: 16),
            Text(
              '${neighbors.length} VECINI RADAR',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 8),
            Text(
              'Ai aruncat plasa peste ${neighbors.length} vecini. Poți trimite un mesaj rapid tuturor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                minimumSize: const ui.Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isRadarMode = false);
                // Broadcast flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcție Broadcast în curs de activare...')),
                );
              },
              child: const Text('TRANSMITEĂ CERERE GRUPULUI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isRadarMode = false);
              },
              child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  /// Pornește subscribe la vecini: preferă RTDB (H3 / telemetrie efemeră), fallback Firestore.
  void _registerNeighborsAnnotationTapHandler() {
    if (_neighborsAnnotationManager == null ||
        _neighborsAnnotationTapListenerRegistered) {
      return;
    }
    try {
      _neighborsAnnotationManager!.tapEvents(onTap: (annotation) {
        final uid = _neighborAnnotationIdToUid[annotation.id];
        if (uid != null) _onNeighborClicked(uid);
      });
      _neighborsAnnotationTapListenerRegistered = true;
    } catch (e) {
      Logger.warning('Neighbor annotation tap handler: $e', tag: 'MAP');
    }
  }

  void _registerDriversAnnotationTapHandler() {
    if (_driversAnnotationManager == null ||
        _driversAnnotationTapListenerRegistered) {
      return;
    }
    try {
      _driversAnnotationManager!.tapEvents(onTap: (annotation) {
        final uid = _driverAnnotationIdToUid[annotation.id];
        if (uid != null) _onNeighborClicked(uid);
      });
      _driversAnnotationTapListenerRegistered = true;
    } catch (e) {
      Logger.warning('Driver annotation tap handler: $e', tag: 'MAP');
    }
  }

  void _listenForNeighbors() {
    if (!mounted || _isInitializingNeighbors) return;
    _isInitializingNeighbors = true;
    
    _neighborsSubscription?.cancel();
    _neighborsSubscription = null;

    final pos = _positionForUserMapMarker();
    if (pos == null) {
      _isInitializingNeighbors = false;
      return;
    }

    unawaited(_subscribeNeighborsPreferredRtdb(pos).then((_) => _isInitializingNeighbors = false));
  }

  Future<void> _subscribeNeighborsPreferredRtdb(geolocator.Position pos) async {
    // ✅ LOCK: Prevenim crearea a doi manageri simultan
    if (_neighborsAnnotationManager == null) {
      if (_isCreatingNeighborsManager) return;
      _isCreatingNeighborsManager = true;
      try {
        final map = _mapboxMap;
        if (map == null) {
          Logger.warning(
            'Mapbox map not ready; skipping neighbors manager creation',
            tag: 'MAP',
          );
          // Fallback: pornim stream-ul pe Firestore ca să nu pierdem afișarea vecinilor.
          _listenForNeighborsFirestoreOnly(pos);
          return;
        }
        _neighborsAnnotationManager ??=
            await map.annotations.createPointAnnotationManager();
        _registerNeighborsAnnotationTapHandler();
      } catch (e) {
        Logger.error('Failed to create neighbors manager: $e');
      } finally {
        _isCreatingNeighborsManager = false;
      }
    }
    if (_neighborsAnnotationManager == null) {
      _isUpdatingNeighbors = false;
      return;
    }
    try {
      final room = await NeighborTelemetryRtdbService.instance
          .ensureNbRoomClaim(pos.latitude, pos.longitude, force: true);
      if (!mounted) return;
      if (room != null && room.isNotEmpty) {
        // ✅ WALKIE-TALKIE BACKGROUND AUTO-PLAY
        WalkieTalkieService().listenToRoom(room);
        
        _neighborsSubscription = NeighborTelemetryRtdbService.instance
            .listenLocationsInRoom(room)
            .map((list) {
          const stale = Duration(minutes: 5);
          final cutoff = DateTime.now().subtract(stale);
          return list.where((n) => n.lastUpdate.isAfter(cutoff)).toList();
        }).listen(
          (neighbors) {
            if (mounted) unawaited(_updateNeighborAnnotations(neighbors));
          },
          onError: (e) {
            Logger.error('Neighbors RTDB stream error: $e',
                tag: 'MAP', error: e);
            if (mounted) _listenForNeighborsFirestoreOnly(pos);
          },
        );
        return;
      }
    } catch (e) {
      Logger.warning('Neighbors RTDB unavailable, using Firestore: $e',
          tag: 'MAP');
    }
    if (mounted) _listenForNeighborsFirestoreOnly(pos);
  }

  void _listenForNeighborsFirestoreOnly(geolocator.Position pos) {
    _neighborsSubscription?.cancel();
    _neighborsSubscription = NeighborLocationService()
        .nearbyNeighbors(centerLat: pos.latitude, centerLng: pos.longitude)
        .listen(
      (neighbors) {
        if (mounted) unawaited(_updateNeighborAnnotations(neighbors));
      },
      onError: (e) {
        Logger.error('Neighbors stream error: $e', tag: 'MAP', error: e);
      },
    );
  }

  bool _isUpdatingNeighbors = false;

  /// Cale asset din bundle pentru avatarul cumpărat (același ID la toți utilizatorii).
  String? _garageBundlePathForNeighbor(String? carAvatarId) {
    if (carAvatarId == null || carAvatarId.isEmpty || carAvatarId == 'default_car') {
      return null;
    }
    final av = CarAvatarService().getAvatarById(carAvatarId);
    if (av.isDefault) return null;
    return av.assetPath;
  }

  Future<void> _updateNeighborAnnotations(
      List<NeighborLocation> neighbors) async {
    if (!mounted || _isUpdatingNeighbors) return;
    _isUpdatingNeighbors = true;
    
    _lastRawNeighborsForMap.clear();
    _lastRawNeighborsForMap.addAll(neighbors);

    if (_neighborsAnnotationManager == null) {
      if (_isCreatingNeighborsManager) {
        _isUpdatingNeighbors = false;
        return;
      }
      _isCreatingNeighborsManager = true;
      try {
        _neighborsAnnotationManager ??= await _mapboxMap?.annotations
            .createPointAnnotationManager(id: 'neighbors-layer');
        _registerNeighborsAnnotationTapHandler();
      } catch (e) {
        Logger.error('Failed to create neighbors manager: $e');
      } finally {
        _isCreatingNeighborsManager = false;
      }
    }
    if (_neighborsAnnotationManager == null) {
      _isUpdatingNeighbors = false;
      NeighborMapFeedController.instance.setNeighbors([]);
      return;
    }

    // ✅ FORCE UNIQUE: Evităm duplicarea markerelor pentru același UID la același frame/stream event.
    final Map<String, NeighborLocation> uniqueMap = {};
    for (final n in neighbors) {
      uniqueMap[n.uid] = n;
    }
    final uniqueNeighbors = uniqueMap.values.toList();

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      List<NeighborLocation> filteredNeighbors = uniqueNeighbors;
      
      if (_contactUids == null) {
        filteredNeighbors = [];
      } else {
        // ✅ FILTRĂM propriul UID pentru a nu afișa emoji peste mașinuță/bulină
        filteredNeighbors = uniqueNeighbors.where((n) => 
          _contactUids!.contains(n.uid) && n.uid != currentUserId
        ).toList();
      }

      NeighborMapFeedController.instance.setNeighbors(filteredNeighbors);

      final activeUids = filteredNeighbors.map((n) => n.uid).toSet();

      for (final uid in _neighborAnnotations.keys.toList()) {
        if (!activeUids.contains(uid)) {
          try {
            final ann = _neighborAnnotations[uid]!;
            _neighborAnnotationIdToUid.remove(ann.id);
            _neighborData.remove(uid);
            await _neighborsAnnotationManager?.delete(ann);
          } catch (_) {}
          _neighborAnnotations.remove(uid);
        }
      }

    final myPos = _currentPositionObject;
    if (myPos != null) {
      if (DateTime.now().difference(_proximityNotifResetTime).inMinutes >= 15) {
        _proximitNotifiedUids.clear();
        _proximityNotifResetTime = DateTime.now();
        _recentlyBumpedUids.clear();
        _friendsTogetherHintPairs.clear();
        _lastFriendsTogetherHintAny = null;
      }

      for (final neighbor in filteredNeighbors) {
        final distToBump = geolocator.Geolocator.distanceBetween(
          myPos.latitude, myPos.longitude, neighbor.lat, neighbor.lng,
        );
        if (distToBump < 15.0 && !_recentlyBumpedUids.contains(neighbor.uid)) {
          _triggerNeighborBump(neighbor);
        }
      }

      if (NearbySocialNotificationsPrefs.instance.enabled) {
        final radiusM = NearbySocialNotificationsPrefs.instance.radiusM.toDouble();
        const maxNeighborsForNotify = 24;
        var count = 0;
        for (final neighbor in filteredNeighbors) {
          if (count >= maxNeighborsForNotify) break;
          if (_proximitNotifiedUids.contains(neighbor.uid)) continue;
          final distM = geolocator.Geolocator.distanceBetween(
            myPos.latitude, myPos.longitude, neighbor.lat, neighbor.lng,
          );
          if (distM <= radiusM) {
            count++;
            _proximitNotifiedUids.add(neighbor.uid);
            unawaited(LocalNotificationsService().showSimple(
              title: '${neighbor.avatar} ${neighbor.displayName} e aproape!',
              body: 'La ${distM.round()} m — harta socială 📍',
              payload: 'proximity_${neighbor.uid}',
              channelId: 'social_proximity',
            ));
          }
        }
      }

      _maybeFriendsTogetherHint(filteredNeighbors);
    }

    final layoutPeers = filteredNeighbors
        .where((n) => !_nearbyDriverAnnotations.containsKey(n.uid))
        .toList();
    final displayByUid = NeighborMarkerDisplayLayout.compute(layoutPeers);

    // ── Adaugă / actualizează vecini noi (cu density-based sizing) ────
    for (final neighbor in filteredNeighbors) {
      // ✅ FIX: Dacă userul este deja afișat ca Mașină (strat Șoferi), eliminăm
      // eventualul Emoticon rămas în urmă pentru a evita suprapunerea.
      if (_nearbyDriverAnnotations.containsKey(neighbor.uid)) {
        final staleAnn = _neighborAnnotations.remove(neighbor.uid);
        if (staleAnn != null) {
          _neighborAnnotationIdToUid.remove(staleAnn.id);
          unawaited(_neighborsAnnotationManager?.delete(staleAnn));
        }
        // Păstrăm telemetria pentru foaia de jos la tap pe mașina din stratul șoferi.
        _neighborData[neighbor.uid] = neighbor;
        continue;
      }

      final Uint8List icon;
      // textField setat mai jos general
      // ── Density-based size reduction ─────────────────────────────────────
      // Calculăm câți vecini sunt în raza de 300m față de acest vecin.
      // Cu cât sunt mai mulți în apropiere, cu atât micșorăm markerul.
      int nearbyCount = 0;
      for (final other in filteredNeighbors) {
        if (other.uid == neighbor.uid) continue;
        final distKm = _calculateDirectDistance(
            neighbor.lat, neighbor.lng, other.lat, other.lng);
        if (distKm < 0.3) nearbyCount++;
      }
      // nearbyCount=0 → full size; ≥4 → minimum size (55% din original)
      final densityFactor = 1.0 - (nearbyCount.clamp(0, 4) / 4.0) * 0.45;

      final double iconSize;

      final bool isDriving = neighbor.isDriver || neighbor.activityStatus == 'driving';
      final bool hasPhoto = neighbor.photoURL != null && neighbor.photoURL!.isNotEmpty;
      final String? garagePath = _garageBundlePathForNeighbor(neighbor.carAvatarId);
      // Prioritate setări utilizator: garaj (non-default) → poză profil → fallback standard (emoji / mașină).

      if (isDriving) {
        if (garagePath != null) {
          icon = await _generateMarkerIcon(isPassenger: false, customAssetPath: garagePath);
        } else {
          icon = await _generateNeighborCarMarker();
        }
        iconSize = 1.98 * densityFactor;
      } else if (garagePath != null) {
        icon = await _generateMarkerIcon(isPassenger: true, customAssetPath: garagePath);
        iconSize = 1.72 * densityFactor;
      } else if (hasPhoto) {
        icon = await NeighborFriendMarkerIcons.buildPhotoMarker(
          photoURL: neighbor.photoURL!,
          isOnline: neighbor.isOnline,
          batteryLevel: neighbor.batteryLevel,
          isCharging: neighbor.isCharging,
        );
        iconSize = 1.55 * densityFactor;
      } else {
        icon = await NeighborFriendMarkerIcons.buildEmojiMarker(
          emoji: neighbor.avatar,
          status: neighbor.activityStatus,
          isOnline: neighbor.isOnline,
          speedMps: neighbor.speedMps,
          batteryLevel: neighbor.batteryLevel,
          isCharging: neighbor.isCharging,
          placeKind: neighbor.placeKind,
          stationarySinceMs: neighbor.stationarySinceMs,
        );
        iconSize = 1.55 * densityFactor;
      }

      String? textField;

      if (isDriving) {
        final plate = neighbor.licensePlate;
        final name = neighbor.displayName.isNotEmpty ? neighbor.displayName : null;
        if (plate != null && plate.isNotEmpty && name != null) {
          textField = '$plate\n$name';
        } else if (plate != null && plate.isNotEmpty) {
          textField = plate;
        } else {
          textField = name;
        }
      } else {
        textField = neighbor.displayName.isNotEmpty ? neighbor.displayName : null;
      }

      // Baterie: pe icon (emoji / foto), nu și în etichetă; pentru mașină rămâne în text.
      if (neighbor.batteryLevel != null && isDriving) {
        final bat = neighbor.batteryLevel!;
        final batStr = neighbor.isCharging ? '⚡$bat%' : '$bat%';
        textField = textField != null ? '$textField  $batStr' : batStr;
      }

      if (isDriving &&
          neighbor.speedMps != null &&
          neighbor.speedMps! >= 1.39) {
        final kmh = (neighbor.speedMps! * 3.6).round();
        textField =
            textField != null ? '$textField • $kmh km/h' : '$kmh km/h';
      } else if (!isDriving && neighbor.placeKind != null) {
        final pl = switch (neighbor.placeKind!) {
          'home' => 'acasă',
          'work' => 'serviciu',
          'school' => 'școală',
          _ => null,
        };
        if (pl != null) {
          textField = textField != null ? '$textField · $pl' : pl;
        }
      }

      final List<double> tOffset = isDriving ? [0, 2.45] : [0, 2.65];
      final int tColor = isDriving ? 0xFF1A237E : 0xFF7C3AED;
      final double tSize = isDriving ? 11.5 : 12.5;

        final disp = displayByUid[neighbor.uid];
        final geom = MapboxUtils.createPoint(
          disp?.lat ?? neighbor.lat,
          disp?.lng ?? neighbor.lng,
        );

        if (_neighborAnnotations.containsKey(neighbor.uid)) {
          final existing = _neighborAnnotations[neighbor.uid]!;
          existing.geometry = geom;
          existing.textField = textField;
          existing.iconSize = iconSize;
          existing.textOffset = tOffset; // ✅ Adăugat update offset
          existing.image = icon;
          try {
            await _neighborsAnnotationManager?.update(existing);
          } catch (_) {}
        } else {
          // Prevenim crearea a 2 markere pt același UID dacă stream-ul e rapid
          if (_neighborUidsBeingCreated.contains(neighbor.uid)) continue;
          _neighborUidsBeingCreated.add(neighbor.uid);

          final options = PointAnnotationOptions(
            geometry: geom,
            image: icon,
            iconSize: iconSize,
            iconAnchor: IconAnchor.CENTER,
            textField: textField,
            textSize: tSize,
            textOffset: tOffset,
            textColor: tColor,
            textHaloColor: 0xFFFFFFFF,
            textHaloWidth: 2.0,
          );
          try {
            final annotation = await _neighborsAnnotationManager?.create(options);
            if (annotation != null && mounted) {
              _neighborAnnotations[neighbor.uid] = annotation;
              _neighborAnnotationIdToUid[annotation.id] = neighbor.uid;
              _neighborData[neighbor.uid] = neighbor;
              _showMapActivityToast(
                neighbor.avatar,
                neighbor.displayName,
                'este din nou pe hartă',
                onTap: () => _onNeighborClicked(neighbor.uid),
              );
            }
          } catch (_) {
          } finally {
            _neighborUidsBeingCreated.remove(neighbor.uid);
          }
        }
      }
    } finally {
      _isUpdatingNeighbors = false;
    }
  }

  /// Două contacte vizibile foarte aproape între ei — indiciu social (throttled).
  void _maybeFriendsTogetherHint(List<NeighborLocation> list) {
    if (!mounted || list.length < 2) return;
    if (_lastFriendsTogetherHintAny != null &&
        DateTime.now().difference(_lastFriendsTogetherHintAny!) <
            const Duration(hours: 1)) {
      return;
    }
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final a = list[i];
        final b = list[j];
        final pairKey = a.uid.compareTo(b.uid) < 0
            ? '${a.uid}_${b.uid}'
            : '${b.uid}_${a.uid}';
        if (_friendsTogetherHintPairs.contains(pairKey)) continue;
        final d = geolocator.Geolocator.distanceBetween(
          a.lat, a.lng, b.lat, b.lng,
        );
        if (d < 75) {
          _friendsTogetherHintPairs.add(pairKey);
          _lastFriendsTogetherHintAny = DateTime.now();
          final msg = '${a.displayName} și ${b.displayName} par împreună în zonă 👥';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
          return;
        }
      }
    }
  }

  void _triggerNeighborBump(NeighborLocation neighbor) {
    if (!mounted) return;
    _recentlyBumpedUids.add(neighbor.uid);

    Logger.info('HIT FIZIC DETECTAT: ${neighbor.displayName}', tag: 'MAP');

    NeighborBumpMatchOverlay.show(context, neighbor);
    unawaited(ActivityFeedWriter.hitWith(neighbor.displayName));

    // 1. Efect haptic (Hit / proximitate)
    unawaited(HapticService.instance.success());
    
    // 2. Sunet de feedback (Balloon Pop)
    unawaited(AudioService().playNeighborBumpSound());

    // 3. Mesaj vizual tip Bubble (Waze-style popup)
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.9), // Nabour Purple
           content: Row(
             children: [
               Text(neighbor.avatar, style: const TextStyle(fontSize: 24)),
               const SizedBox(width: 12),
               Expanded(child: Text('Hit, ${neighbor.displayName} e chiar lângă tine! 👋',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
             ],
           ),
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
           margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.45, left: 32, right: 32),
           duration: const Duration(seconds: 5),
         )
       );
    }
  }

  void _onNeighborClicked(String uid) {
    final neighbor = _neighborData[uid];
    if (neighbor == null) return;

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    // Calculăm distanța față de utilizator
    double distanceKm = 0;
    if (_currentPositionObject != null) {
      distanceKm = geolocator.Geolocator.distanceBetween(
            _currentPositionObject!.latitude,
            _currentPositionObject!.longitude,
            neighbor.lat,
            neighbor.lng,
          ) /
          1000;
    }

    // Determinăm eticheta de timp (ex: 7 MIN ÎN URMĂ)
    final diffMin = DateTime.now().difference(neighbor.lastUpdate).inMinutes;
    final timeLabel = diffMin <= 1 ? 'CHIAR ACUM' : '$diffMin MIN ÎN URMĂ ';

    // Căutăm numărul de telefon în lista de contacte app (dacă există)
    String? phoneNumber;
    if (_contactUsers.isNotEmpty) {
      try {
        final contactUser = _contactUsers.firstWhere((u) => u.uid == uid);
        phoneNumber = contactUser.phoneNumber;
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NeighborProfileSheet(
        neighbor: neighbor,
        distanceKm: distanceKm,
        timeLabel: timeLabel,
        phoneNumber: phoneNumber,
        onMessage: () {
          Navigator.pop(ctx);
          final sorted = [myUid, uid]..sort();
          final roomId = sorted.join('_');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                rideId: roomId,
                otherUserId: uid,
                otherUserName: neighbor.displayName,
                collectionName: 'private_chats',
              ),
            ),
          );
        },
        onSendReaction: (reaction) async {
          final sorted = [myUid, uid]..sort();
          final roomId = sorted.join('_');
          final myName = FirebaseAuth.instance.currentUser?.displayName ?? 'Vecin';
          
          await FirebaseFirestore.instance
              .collection('private_chats')
              .doc(roomId)
              .collection('messages')
              .add({
            'text': reaction,
            'reaction': true,
            'senderId': myUid,
            'senderName': myName,
            'timestamp': FieldValue.serverTimestamp(),
          });
          
          HapticFeedback.mediumImpact();
          if (mounted) _showSafeSnackBar('Reacție trimisă: $reaction', const Color(0xFF7C3AED));
        },
        onCall: phoneNumber != null ? () async {
          final uri = Uri.parse('tel:$phoneNumber');
          if (await url_launcher.canLaunchUrl(uri)) {
            await url_launcher.launchUrl(uri);
          }
        } : null,
        onHonk: () async {
          final myName = FirebaseAuth.instance.currentUser?.displayName ?? 'Vecin';
          await VirtualHonkService().sendHonk(uid, myName);
          HapticFeedback.heavyImpact();
          if (mounted) _showSafeSnackBar('L-ai claxonat pe ${neighbor.displayName}!', Colors.orange);
        },
        onSendEta: () async {
          final sorted = [myUid, uid]..sort();
          final roomId = sorted.join('_');
          final myName = FirebaseAuth.instance.currentUser?.displayName ?? 'Vecin';
          
          // Exemplu simplificat de ETA
          final etaMin = (distanceKm * 2.5).toInt() + 2; 
          
          await FirebaseFirestore.instance
              .collection('private_chats')
              .doc(roomId)
              .collection('messages')
              .add({
            'text': '📍 Vin spre tine! ETA estimat: $etaMin min.',
            'isEta': true,
            'senderId': myUid,
            'senderName': myName,
            'timestamp': FieldValue.serverTimestamp(),
          });
           HapticFeedback.lightImpact();
           if (ctx.mounted) Navigator.pop(ctx);
           _showSafeSnackBar('ETA trimis lui ${neighbor.displayName}', Colors.green);
        },
        onNeighborhoodRequest: () {
          Navigator.pop(ctx);
          NeighborhoodRequestsManager.showCreateRequestSheet(
            context,
            neighbor.lat,
            neighbor.lng,
            initialMessage: '${neighbor.displayName}: ',
            locationContext:
                'Bula apare lângă ${neighbor.displayName} pe hartă. Vizibilă vecinilor ~1 oră.',
          );
        },
        onSendMapEmoji: (emoji) async {
          final chosen = normalizeMapEmojiForEngine(emoji);
          try {
            await MapEmojiService().addEmoji(
              lat: neighbor.lat,
              lng: neighbor.lng,
              emoji: chosen,
              senderId: myUid,
            );
            if (ctx.mounted) Navigator.pop(ctx);
            HapticFeedback.lightImpact();
            if (!mounted) return;
            final optimistic = MapEmoji(
              id: myUid,
              lat: neighbor.lat,
              lng: neighbor.lng,
              emoji: chosen,
              timestamp: DateTime.now(),
              senderId: myUid,
            );
            setState(() {
              _lastReceivedEmojis = [
                ..._lastReceivedEmojis.where((x) => x.id != myUid),
                optimistic,
              ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
            });
            unawaited(_updateEmojiMarkers(_lastReceivedEmojis));
            _showSafeSnackBar(
              'Emoji plasat lângă ${neighbor.displayName} pe hartă',
              const Color(0xFFE91E63),
            );
          } catch (e) {
            if (mounted) {
              _showSafeSnackBar(
                'Nu am putut plasa emoji-ul pe hartă',
                const Color(0xFFB71C1C),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _sendFriendRequestFromSearch(String uid) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || uid.isEmpty || uid == myUid) return;
    if (_friendPeerUids.contains(uid)) {
      if (mounted) {
        _showSafeSnackBar('Sunteți deja prieteni în Nabour.', Colors.orange.shade800);
      }
      return;
    }
    if (await FriendRequestService.instance.hasPendingRequestTo(uid)) {
      if (mounted) {
        _showSafeSnackBar(
          'Ai trimis deja o cerere către această persoană.',
          Colors.orange.shade800,
        );
      }
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('friend_requests').add({
        'fromUid': myUid,
        'toUid': uid,
        'status': 'pending',
        'ts': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSafeSnackBar(
          'Cerere de prietenie trimisă!',
          const Color(0xFF22C55E),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSafeSnackBar(
          (e.toString().contains('permission-denied') ||
                  e.toString().contains('PERMISSION_DENIED'))
              ? 'Nu avem voie să scriem cererea (reguli Firebase).'
              : 'Nu am putut trimite cererea. Încearcă din nou.',
          const Color(0xFFB71C1C),
        );
      }
    }
  }

  void _onUniversalSearchContact(String uid) {
    final neighbor = _neighborData[uid];
    if (neighbor == null) {
      _showSafeSnackBar(
        'Persoana nu e vizibilă pe hartă acum. Poți trimite cerere de prietenie din listă (+).',
        Colors.grey.shade800,
      );
      return;
    }
    unawaited(_mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(neighbor.lng, neighbor.lat)),
        zoom: 16.2,
        pitch: 45,
      ),
      MapAnimationOptions(duration: 1400),
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onNeighborClicked(uid);
    });
  }

  void _onUniversalSearchPlace(double lat, double lng, String label) {
    unawaited(_mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 16.5,
        pitch: 45,
      ),
      MapAnimationOptions(duration: 1800),
    ));
    unawaited(_requestsManager?.showTransientLocationPin(lat, lng));
    _showSafeSnackBar(label, const Color(0xFF3949AB));
  }

  // ── BLE Bump ────────────────────────────────────────────────────────────
  void _startBleBump() {
    unawaited(BleBumpService.instance.start());
    BleBumpBridge.instance.onBump = (peerUid) {
      if (!mounted) return;
      if (_recentlyBumpedUids.contains(peerUid)) return;
      final neighbor = _neighborData[peerUid];
      if (neighbor != null) {
        _triggerNeighborBump(neighbor);
        unawaited(ActivityFeedWriter.hitWith(neighbor.displayName));
      }
    };
    BleBumpBridge.instance.start();
  }

  // ── Smart Places background clustering ─────────────────────────────────
  void _startSmartPlacesClustering() {
    _smartPlacesClusterTimer?.cancel();
    _smartPlacesClusterTimer =
        Timer.periodic(const Duration(minutes: 5), (_) async {
      await SmartPlacesDb.instance.runClustering();
    });
  }

  Future<void> _loadSocialBumpPrefs() async {
    await GhostModeService.instance.ensureLoaded();
    await NearbySocialNotificationsPrefs.instance.load();
  }

  void _ensureRidePanelVisibleForExternalAction(VoidCallback applyToPanel) {
    if (!mounted) return;
    final needOpen = !_rideAddressSheetVisible && !_inAppNavActive;
    if (needOpen) {
      setState(() => _rideAddressSheetVisible = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        applyToPanel();
        if (_rideSheetController.isAttached) {
          _rideSheetController.animateTo(
            0.48,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      });
      return;
    }
    applyToPanel();
  }

  void _closeRideAddressSheet() {
    if (_inAppNavActive) {
      _showSafeSnackBar('Oprește mai întâi navigarea din bannerul de sus.', Colors.orange);
      return;
    }
    setState(() => _rideAddressSheetVisible = false);
  }

  /// Comută înălțimea sheet-ului când cardul e deja vizibil.
  void _toggleRideSheetExpandCollapse() {
    final c = _rideSheetController;
    if (!c.isAttached) return;
    const collapsed = 0.16;
    const expanded = 0.48;
    final next = c.size <= collapsed + 0.03 ? expanded : collapsed;
    c.animateTo(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// Butonul din bara de jos: deschide cardul sau, dacă e deja deschis, micșorează/mărește.
  void _onItineraryButtonPressed() {
    if (!_rideAddressSheetVisible && !_inAppNavActive) {
      setState(() => _rideAddressSheetVisible = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_rideSheetController.isAttached) return;
        _rideSheetController.animateTo(
          0.48,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      });
      return;
    }
    _toggleRideSheetExpandCollapse();
  }

  // ── Post Moment ────────────────────────────────────────────────────────
  void _showPostMomentSheet() {
    final pos = _currentPositionObject;
    if (pos == null) {
      _showSafeSnackBar(
        'Așteptăm poziția GPS. Încearcă din nou în câteva secunde.',
        Colors.orange,
      );
      return;
    }
    showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PostMomentSheet(lat: pos.latitude, lng: pos.longitude),
    ).then((posted) {
      if (!mounted || posted != true) return;
      // Fără asta, momentele se ascultă doar la „vizibil vecinilor” — după post vrem lista actualizată mereu.
      _subscribeToMoments();
    });
  }

  void _shareCurrentLocation() {
    final pos = _currentPositionObject;
    if (pos == null) {
      _showSafeSnackBar('Locatia GPS nu este disponibila inca', Colors.orange);
      return;
    }
    final lat = pos.latitude;
    final lng = pos.longitude;
    final googleMapsUrl = 'https://www.google.com/maps?q=$lat,$lng';
    final text = 'Sunt aici: $googleMapsUrl\n'
        'Coordonate: $lat, $lng';
    SharePlus.instance.share(ShareParams(text: text));
  }

  // ── Listen to moments nearby ───────────────────────────────────────────
  void _subscribeToMoments() {
    _momentsSubscription?.cancel();
    _momentsExpiryTimer?.cancel();
    _momentsExpiryTimer = null;
    final pos = _currentPositionObject;
    if (pos == null) return;
    _momentsSubscription = MapMomentService.instance
        .nearbyMoments(centerLat: pos.latitude, centerLng: pos.longitude)
        .listen((moments) {
      if (!mounted) return;
      setState(() => _activeMoments = moments);
      unawaited(_updateMomentMarkers(moments));
    });
    // Firestore nu re-emite când trece timpul; curățăm local la expirarea TTL.
    _momentsExpiryTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      final fresh = _activeMoments.where((m) => !m.isExpired).toList();
      if (fresh.length == _activeMoments.length) return;
      setState(() => _activeMoments = fresh);
      unawaited(_updateMomentMarkers(fresh));
    });
  }

  // ── Friend Suggestions Screen (Bump style) ──────────────────────────
  void _openFriendSuggestions() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => FriendSuggestionsScreen(
          contacts: _contactUsers,
          onlineUids: _neighborData.keys.toSet(),
          avatarCache: _neighborAvatarCache,
        ),
      ),
    ).then((_) {
      if (mounted) unawaited(_syncFriendPeersIntoContactUids());
    });
  }

  // ── Activity Notifications Screen (Bell screen, Bump style) ────────
  void _openActivityNotifications() {
    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) {
          final self = FirebaseAuth.instance.currentUser?.uid;
          final ids = <String>{...?_contactUids};
          if (self != null && self.isNotEmpty) ids.add(self);
          return ActivityNotificationsScreen(
            friendUids: ids.toList(),
            contacts: _contactUsers,
            avatarCache: _neighborAvatarCache,
          );
        },
      ),
    ).then((result) {
      if (result != null && result['action'] == 'flyTo' && mounted) {
        final lat = (result['lat'] as num?)?.toDouble();
        final lng = (result['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _mapboxMap?.flyTo(
            CameraOptions(
              center: MapboxUtils.createPoint(lat, lng),
              zoom: 16.5,
              pitch: 45,
            ),
            MapAnimationOptions(duration: 1500),
          );
        }
      }
    });
  }

  // ── Show activity toast on map (Bump style) ────────────────────────
  void _showMapActivityToast(String avatar, String name, String message, {VoidCallback? onTap}) {
    if (!mounted) return;
    MapActivityToast.show(
      context,
      avatar: avatar,
      name: name,
      message: message,
      onTap: onTap,
    );
  }

  Widget _buildBumpFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black,
    Color bgColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildMiniAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _showNeighborsListSheet replaced by _openFriendSuggestions (Bump-style screen)

  /// ✅ NOU: Marker pentru Cereri de Cursă (Amber/Gold border)
  static Future<Uint8List> _generateDemandMarker(String emoji) async {
    final cacheKey = 'demand_$emoji';
    if (_emojiMarkerCache.containsKey(cacheKey)) return _emojiMarkerCache[cacheKey]!;

    const double size = 80;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));

    // Fundal cerc alb cu umbră aurie
    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x40FF8F00)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawCircle(const ui.Offset(size / 2, size / 2 + 2), size / 2 - 4, shadowPaint);

    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(const ui.Offset(size / 2, size / 2), size / 2 - 4, bgPaint);

    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFFFF8F00) // Amber/Orange pentru Cerere
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(const ui.Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

    // Emoji text
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 42, textAlign: TextAlign.center))
      ..addText(emoji);
    final paragraph = paragraphBuilder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: size));
    canvas.drawParagraph(paragraph, Offset(0, (size - paragraph.height) / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = _pngBytesOrMinimalFallback(byteData, '_generateDemandMarker');
    _emojiMarkerCache[cacheKey] = bytes;
    return bytes;
  }

  /// Fonturi încercate la rasterizare — pe Xiaomi / MIUI (ex. Redmi Note 11 Pro) numele efectiv
  /// al fontului emoji diferă; lista lungă crește șansa să se folosească glyph-uri color.
  static List<String> _mapReactionEmojiFontFallbacks() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const [
          'Noto Color Emoji',
          'NotoColorEmoji',
          'Noto Sans Color Emoji',
          'Noto Sans Symbols 2',
          'SamsungColorEmoji',
          'Segoe UI Emoji',
          'Noto Emoji',
        ];
      case TargetPlatform.iOS:
        return const [
          'Apple Color Emoji',
          'Noto Color Emoji',
        ];
      default:
        return const [
          'Noto Color Emoji',
          'Apple Color Emoji',
          'Segoe UI Emoji',
          'Noto Emoji',
        ];
    }
  }

  /// Emoji color pe hartă: `ParagraphBuilder` (dart:ui) poate folosi font fără color glyph → monocrom.
  /// `TextPainter` + fallback-uri Android/MIUI pentru raster corect.
  static Future<Uint8List> _generateMapReactionMarkerPng(String emoji) async {
    final cacheKey = 'map_reaction_v5_$emoji';
    if (_emojiMarkerCache.containsKey(cacheKey)) return _emojiMarkerCache[cacheKey]!;

    const double size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));

    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x35000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2 + 2),
      size / 2 - 4,
      shadowPaint,
    );

    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2),
      size / 2 - 4,
      bgPaint,
    );

    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFFE91E63)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2),
      size / 2 - 4,
      borderPaint,
    );

    final emojiFallbacks = _mapReactionEmojiFontFallbacks();
    final tp = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: 52,
          height: 1.0,
          // Pe Android, un fontFamily principal + fallback-uri MIUI/AOSP.
          fontFamily: defaultTargetPlatform == TargetPlatform.android
              ? emojiFallbacks.first
              : null,
          fontFamilyFallback: emojiFallbacks,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout(maxWidth: size);
    final dx = (size - tp.width) / 2;
    final dy = (size - tp.height) / 2;
    tp.paint(canvas, Offset(dx, dy));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = _pngBytesOrMinimalFallback(byteData, '_generateMapReactionMarkerPng');
    _emojiMarkerCache[cacheKey] = bytes;
    return bytes;
  }

  /// Bulă circulară pentru postări pe hartă — aceeași rezoluție ca reacțiile emoji (~96px),
  /// bordură magenta ca să se distingă de markerele vecinilor (violet).
  static Future<Uint8List> _generateMapMomentBubblePng(String symbol) async {
    final cacheKey = 'map_moment_bubble_v1_$symbol';
    if (_emojiMarkerCache.containsKey(cacheKey)) {
      return _emojiMarkerCache[cacheKey]!;
    }

    const double size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));

    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x35000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2 + 2),
      size / 2 - 4,
      shadowPaint,
    );

    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2),
      size / 2 - 4,
      bgPaint,
    );

    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFFE040FB)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(
      const ui.Offset(size / 2, size / 2),
      size / 2 - 4,
      borderPaint,
    );

    final emojiFallbacks = _mapReactionEmojiFontFallbacks();
    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: 50,
          height: 1.0,
          fontFamily: defaultTargetPlatform == TargetPlatform.android
              ? emojiFallbacks.first
              : null,
          fontFamilyFallback: emojiFallbacks,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout(maxWidth: size);
    final dx = (size - tp.width) / 2;
    final dy = (size - tp.height) / 2;
    tp.paint(canvas, Offset(dx, dy));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = _pngBytesOrMinimalFallback(byteData, '_generateMapMomentBubblePng');
    _emojiMarkerCache[cacheKey] = bytes;
    return bytes;
  }

  /// Generează iconița mașinuță 3D pentru vecinii care sunt șoferi disponibili.
  /// Portată din friendsride_app. Cacheată cu cheia 'neighbor_driver_3d'.
  static Future<Uint8List> _generateNeighborCarMarker() async {
    const cacheKey = 'neighbor_driver_3d';
    if (_emojiMarkerCache.containsKey(cacheKey)) return _emojiMarkerCache[cacheKey]!;

    const double size = 96;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
    final paint = ui.Paint()..isAntiAlias = true;

    final double cx = size / 2;
    final double cy = size / 2;
    const double radius = size / 2 - 4;

    // 1. Fundal cerc alb (consistență cu markerii social emoji)
    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(ui.Offset(cx, cy), radius, bgPaint);

    // 2. Bordură violet Nabour
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF7C3AED)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(ui.Offset(cx, cy), radius, borderPaint);

    // 3. Drop shadow pentru mașină
    paint
      ..color = const ui.Color(0x55000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(center: ui.Offset(cx + 1, cy + 3), width: 34, height: 58),
        const ui.Radius.circular(10),
      ),
      paint,
    );
    paint.maskFilter = null;

    // Caroserie â€” gradient lateral 3D
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx - 19, cy),
      ui.Offset(cx + 19, cy),
      [
        const ui.Color(0xFF0D1457),
        const ui.Color(0xFF3949AB),
        const ui.Color(0xFF283593),
        const ui.Color(0xFF0D1457),
      ],
      [0.0, 0.35, 0.65, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 38, height: 64),
        const ui.Radius.circular(12),
      ),
      paint,
    );
    paint.shader = null;

    // Roți
    _drawNeighborWheel(canvas, paint, cx - 22, cy - 20, 8, 12);
    _drawNeighborWheel(canvas, paint, cx + 14, cy - 20, 8, 12);
    _drawNeighborWheel(canvas, paint, cx - 22, cy + 10, 8, 12);
    _drawNeighborWheel(canvas, paint, cx + 14, cy + 10, 8, 12);

    // Capotă față
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx, cy - 32),
      ui.Offset(cx, cy - 16),
      [const ui.Color(0xFF5C6BC0), const ui.Color(0xFF283593)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 15, cy - 32, 30, 16),
        const ui.Radius.circular(5),
      ),
      paint,
    );
    paint.shader = null;

    // Pavilion (roof)
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx - 12, cy - 18),
      ui.Offset(cx + 12, cy + 10),
      [const ui.Color(0xFF7986CB), const ui.Color(0xFF3949AB), const ui.Color(0xFF1A237E)],
      [0.0, 0.5, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 12, cy - 18, 24, 30),
        const ui.Radius.circular(7),
      ),
      paint,
    );
    paint.shader = null;

    // Parbriz față
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx - 10, cy - 17),
      ui.Offset(cx + 10, cy - 5),
      [const ui.Color(0xCC9CE7FF), const ui.Color(0x9954D1F7)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 10, cy - 17, 20, 12),
        const ui.Radius.circular(3),
      ),
      paint,
    );
    paint.shader = null;

    // Reflexie parbriz
    paint.color = const ui.Color(0x55FFFFFF);
    final glarePath = ui.Path()
      ..moveTo(cx - 9, cy - 16)
      ..lineTo(cx - 3, cy - 16)
      ..lineTo(cx - 6, cy - 6)
      ..lineTo(cx - 10, cy - 6)
      ..close();
    canvas.drawPath(glarePath, paint);

    // Luneta spate
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx, cy + 4),
      ui.Offset(cx, cy + 14),
      [const ui.Color(0x9954D1F7), const ui.Color(0xCC1E6E8A)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 9, cy + 4, 18, 10),
        const ui.Radius.circular(3),
      ),
      paint,
    );
    paint.shader = null;

    // Capotă spate
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx, cy + 16),
      ui.Offset(cx, cy + 32),
      [const ui.Color(0xFF283593), const ui.Color(0xFF0D1457)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 15, cy + 16, 30, 16),
        const ui.Radius.circular(5),
      ),
      paint,
    );
    paint.shader = null;

    // Faruri față
    _drawNeighborHeadlight(canvas, paint, cx - 13, cy - 32, isRear: false);
    _drawNeighborHeadlight(canvas, paint, cx + 13, cy - 32, isRear: false);

    // Stopuri spate
    _drawNeighborHeadlight(canvas, paint, cx - 13, cy + 32, isRear: true);
    _drawNeighborHeadlight(canvas, paint, cx + 13, cy + 32, isRear: true);

    // Highlight 3D
    paint.shader = ui.Gradient.linear(
      ui.Offset(cx - 19, cy - 32),
      ui.Offset(cx - 5, cy),
      [const ui.Color(0x44FFFFFF), const ui.Color(0x00FFFFFF)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(cx - 19, cy - 32, 14, 45),
        const ui.Radius.circular(12),
      ),
      paint,
    );
    paint.shader = null;

    // Indicator disponibil (punct verde)
    paint
      ..color = const ui.Color(0x6600C853)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 8, paint);
    paint.maskFilter = null;
    paint.color = const ui.Color(0xFF00E676);
    canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 6, paint);
    paint.color = const ui.Color(0xFF69F0AE);
    canvas.drawCircle(ui.Offset(cx + 16, cy + 28), 3, paint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes =
        _pngBytesOrMinimalFallback(byteData, '_generateNeighborCarMarker');
    _emojiMarkerCache[cacheKey] = bytes;
    return bytes;
  }

  static void _drawNeighborWheel(
      ui.Canvas canvas, ui.Paint paint, double x, double y, double w, double h) {
    paint.shader = ui.Gradient.linear(
      ui.Offset(x, y),
      ui.Offset(x + w, y + h),
      [const ui.Color(0xFF424242), const ui.Color(0xFF212121)],
      [0.0, 1.0],
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(x, y, w, h),
        const ui.Radius.circular(3),
      ),
      paint,
    );
    paint.shader = null;
    paint.color = const ui.Color(0x66FFFFFF);
    canvas.drawOval(ui.Rect.fromLTWH(x + 1.5, y + 1.5, w - 3, h * 0.45), paint);
  }

  static void _drawNeighborHeadlight(
      ui.Canvas canvas, ui.Paint paint, double cx, double cy,
      {required bool isRear}) {
    final glowColor =
        isRear ? const ui.Color(0xAAFF1744) : const ui.Color(0xAAFFFFFF);
    final coreColor =
        isRear ? const ui.Color(0xFFFF1744) : const ui.Color(0xFFFFFFFF);
    final innerColor =
        isRear ? const ui.Color(0xFFFF8A80) : const ui.Color(0xFFFFEB3B);
    paint
      ..color = glowColor
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawOval(
        ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 10, height: 6), paint);
    paint.maskFilter = null;
    paint.color = coreColor;
    canvas.drawOval(
        ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 7, height: 4), paint);
    paint.color = innerColor;
    canvas.drawOval(
        ui.Rect.fromCenter(center: ui.Offset(cx, cy), width: 4, height: 2.5), paint);
  }

  /// Activează vizibilitatea cu o durată opțională (null = permanent).
  Future<void> _activateVisibility({Duration? duration}) async {
    await GhostModeService.instance.setBlocking(false);
    _ghostModeTimer?.cancel();
    _ghostModeTimer = null;
    setState(() {
      _isVisibleToNeighbors = true;
      _neighborActivityFeedDismissed = false;
      _showCerereButton = true;
    });

    final pos = _currentPositionObject;
    if (pos != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users').doc(uid).get();
        final data = userDoc.data() ?? {};

        final avatar = data['avatar'] as String? ?? '🙂';
        final displayName = data['displayName'] as String? ?? 'Vecin';
        final licensePlate = data['licensePlate'] as String?;
        final photoURL = data['photoURL'] as String?;

        _neighborAvatarCache[uid] = avatar;
        _neighborDisplayNameCache[uid] = displayName;
        if (licensePlate != null) _neighborLicensePlateCache[uid] = licensePlate;
        if (photoURL != null) _neighborPhotoURLCache[uid] = photoURL;
        _setNeighborGarageCachesFromUserData(uid, data);
        final isDrv = _currentRole == UserRole.driver && _isDriverAvailable;
        final carAvatarId = _effectivePublishedCarAvatarId(
          uid,
          useDriverGarageSlot: _currentRole == UserRole.driver,
        );

        await publishNeighborMapVisibility(
          position: pos,
          avatar: avatar,
          displayName: displayName,
          isDriver: isDrv,
          licensePlate: licensePlate,
          photoURL: photoURL,
          allowedUids: _contactUids?.toList() ?? [],
          carAvatarId: carAvatarId,
        );
      }
    }
    _listenForNeighbors();
    _subscribeToMoments();

    // Prune old activity feed events in background
    unawaited(ActivityFeedService.instance.pruneOldEvents());

    // Pornește periodic publish pentru pasager (și pentru driver indisponibil),
    // doar dacă nu există deja timerul dedicat driverului disponibil.
    final bool shouldPeriodicPublish =
        !(_currentRole == UserRole.driver && _isDriverAvailable);
    if (shouldPeriodicPublish) {
      _visibilityPublishTimer?.cancel();
      _visibilityPublishTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (!mounted || !_isVisibleToNeighbors) return;
        final p = _currentPositionObject;
        if (p == null) return;

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        final isDrv = _currentRole == UserRole.driver && _isDriverAvailable;

        publishNeighborMapVisibilityUnawaited(
          position: p,
          avatar: _neighborAvatarCache[uid] ?? '🙂',
          displayName: _neighborDisplayNameCache[uid] ?? 'Vecin',
          isDriver: isDrv,
          licensePlate: _neighborLicensePlateCache[uid],
          photoURL: _neighborPhotoURLCache[uid],
          allowedUids: _contactUids?.toList() ?? [],
          carAvatarId: _effectivePublishedCarAvatarId(
            uid,
            useDriverGarageSlot: _currentRole == UserRole.driver,
          ),
        );
      });
    }

    // Timer auto-dezactivare
    if (duration != null) {
      _ghostModeTimer = Timer(duration, () {
        if (mounted) _deactivateVisibility();
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('social_map_visible', true);
  }

  /// Vizibilitate socială: foaia „vecini” sau șofer disponibil (nu în Ghost Mode).
  bool get _wantsNeighborSocialPublish =>
      _isVisibleToNeighbors ||
      (_currentRole == UserRole.driver && _isDriverAvailable);

  void _setNeighborGarageCachesFromUserData(String uid, Map<String, dynamic> data) {
    final rawDriver = CarAvatarService.resolveSlotId(data, CarAvatarMapSlot.driver);
    _neighborCarAvatarDriverCache[uid] =
        CarAvatarService.coerceDriverAvatarIdForMap(rawDriver);
    final rawPassenger =
        CarAvatarService.resolveSlotId(data, CarAvatarMapSlot.passenger);
    _neighborCarAvatarPassengerCache[uid] =
        CarAvatarService.coercePassengerAvatarIdForMap(rawPassenger);
  }

  String _effectivePublishedCarAvatarId(
    String uid, {
    required bool useDriverGarageSlot,
  }) {
    if (useDriverGarageSlot) {
      return _neighborCarAvatarDriverCache[uid] ?? 'default_car';
    }
    return _neighborCarAvatarPassengerCache[uid] ?? 'default_car';
  }

  Future<void> _publishNeighborSocialMapFresh(
    geolocator.Position position, {
    bool forceNeighborTelemetry = false,
  }) async {
    if (!_wantsNeighborSocialPublish) return;
    await GhostModeService.instance.ensureLoaded();
    if (GhostModeService.instance.isBlocking) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;
      final data = doc.data() ?? {};
      final auth = FirebaseAuth.instance.currentUser;
      final dn = (data['displayName'] as String?)?.trim();
      final authName = auth?.displayName?.trim();
      final resolvedName = (dn != null && dn.isNotEmpty) ? dn : (authName ?? 'Vecin');
      final rawPlate = (data['licensePlate'] as String?)?.trim();
      final plate = (rawPlate != null && rawPlate.isNotEmpty)
          ? rawPlate
          : (data['carPlate'] ?? data['plate'])?.toString().trim();

      _setNeighborGarageCachesFromUserData(uid, data);
      final isDrv = _currentRole == UserRole.driver && _isDriverAvailable;
      final carAvatarId = _effectivePublishedCarAvatarId(
        uid,
        useDriverGarageSlot: _currentRole == UserRole.driver,
      );

      await publishNeighborMapVisibility(
        position: position,
        avatar: data['avatar'] as String? ?? '🙂',
        displayName: resolvedName,
        isDriver: isDrv,
        licensePlate: (plate != null && plate.isNotEmpty) ? plate : null,
        photoURL: data['photoURL'] as String?,
        allowedUids: _contactUids?.toList() ?? [],
        forceNeighborTelemetry: forceNeighborTelemetry,
        carAvatarId: carAvatarId,
      );
    } catch (e) {
      Logger.error('Social map publish failed: $e', error: e, tag: 'MAP');
    }
  }

  void _publishNeighborSocialMapFreshUnawaited(
    geolocator.Position position, {
    bool forceNeighborTelemetry = false,
  }) {
    unawaited(_publishNeighborSocialMapFresh(
      position,
      forceNeighborTelemetry: forceNeighborTelemetry,
    ));
  }

  Future<void> _deactivateVisibility() async {
    _ghostModeTimer?.cancel();
    _ghostModeTimer = null;
    _visibilityPublishTimer?.cancel();
    _visibilityPublishTimer = null;
    setState(() {
      _isVisibleToNeighbors = false;
      _neighborActivityFeedDismissed = false;
    });
    _neighborsSubscription?.cancel();
    _neighborsSubscription = null;
    await NeighborLocationService().setInvisible();
    NeighborStationaryTracker.instance.reset();
    NeighborSavedPlacesCache.instance.dispose();
    NeighborMapFeedController.instance.setNeighbors([]);
    for (final ann in _neighborAnnotations.values) {
      try { await _neighborsAnnotationManager?.delete(ann); } catch (_) {}
    }
    _neighborAnnotations.clear();
    _neighborAnnotationIdToUid.clear();
    _neighborData.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('social_map_visible', false);
  }

  /// Arată mereu sheet-ul cu opțiunile de vizibilitate (inclusiv Invizibil).
  Future<void> _toggleVisibleToNeighbors() async {
    if (!mounted) return;
    final result = await showModalBottomSheet<Duration?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: SingleChildScrollView(child: const _GhostModeSheet()),
      ),
    );
    if (result == null) return; // user a Ã®nchis fără să aleagă

    if (result == _kInvisibleChoice) {
      await _deactivateVisibility();
      await GhostModeService.instance.setBlocking(true);
      return;
    }
    // Duration.zero = permanent
    await _activateVisibility(
      duration: result == Duration.zero ? null : result,
    );
  }

  Future<void> _checkInactiveUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('last_ride_date');
      if (raw == null) return;
      final lastRide = DateTime.tryParse(raw);
      await PushCampaignService().checkInactiveUser(lastRide);
    } catch (_) {}
  }

  Future<void> _loadMagicEventCheckinIds() async {
    try {
      final s = await MagicEventCheckinStore.instance.load();
      if (!mounted) return;
      setState(() {
        _magicEventCheckedInIds
          ..clear()
          ..addAll(s);
      });
    } catch (_) {}
  }

  void _startMagicEventPolling() {
    unawaited(_loadMagicEventCheckinIds());
    _magicEventPollTimer?.cancel();
    _magicEventPollTimer =
        Timer.periodic(const Duration(seconds: 48), (_) {
      unawaited(_pollMagicEventsOnce());
    });
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (mounted) unawaited(_pollMagicEventsOnce());
    });
  }

  Future<void> _maybePollMagicEventsThrottled() async {
    if (FirebaseAuth.instance.currentUser?.uid == null) return;
    final now = DateTime.now();
    if (_lastMagicEventPoll != null &&
        now.difference(_lastMagicEventPoll!) <
            const Duration(seconds: 40)) {
      return;
    }
    _lastMagicEventPoll = now;
    await _pollMagicEventsOnce();
  }

  Future<void> _pollMagicEventsOnce() async {
    if (!mounted || _mapboxMap == null) return;
    final pos = _currentPositionObject;
    if (pos == null) return;
    if (FirebaseAuth.instance.currentUser?.uid == null) return;

    try {
      final now = DateTime.now();
      final candidates =
          await MagicEventService.instance.fetchActiveCandidatesInArea(
        userLat: pos.latitude,
        userLng: pos.longitude,
        searchRadiusKm: 10,
      );
      final timeOk = candidates
          .where((e) => magicEventIsActiveAt(e, now))
          .toList();
      await _syncMagicEventMarkers(timeOk);

      final inside = magicEventsUserIsInsideNow(
        userLat: pos.latitude,
        userLng: pos.longitude,
        candidates: timeOk,
        now: now,
      );

      if (!mounted) return;
      setState(() {
        _magicEventsUserInside = inside;
        _magicEventsAuraCandidates = timeOk;
      });
      unawaited(_projectMagicEventAuraSlots());

      for (final e in inside) {
        if (_magicEventCheckedInIds.contains(e.id)) continue;
        await MagicEventCheckinStore.instance.add(e.id);
        if (!mounted) return;
        setState(() {
          _magicEventCheckedInIds.add(e.id);
          _magicStarShowerVisible = true;
          _magicEventRippleTick[e.id] =
              (_magicEventRippleTick[e.id] ?? 0) + 1;
        });
        unawaited(_projectMagicEventAuraSlots());
        _showSafeSnackBar(
          'Bun venit la ${e.title}!',
          const Color(0xFF7C3AED),
        );
        break;
      }
    } catch (e, st) {
      Logger.error(
        'Magic event poll: $e',
        error: e,
        stackTrace: st,
        tag: 'MAGIC_EVENT',
      );
    }
  }

  Future<void> _syncMagicEventMarkers(List<MagicEvent> events) async {
    if (!mounted || _mapboxMap == null) return;
    try {
      if (_magicEventAnnotationManager == null) {
        try {
          _magicEventAnnotationManager = await _mapboxMap!.annotations
              .createPointAnnotationManager(
            id: 'magic-events-layer',
            below: 'map-moments-layer',
          );
        } catch (_) {
          _magicEventAnnotationManager = await _mapboxMap!.annotations
              .createPointAnnotationManager(
            id: 'magic-events-layer',
          );
        }
      }
    } catch (e) {
      Logger.warning('Magic event manager: $e', tag: 'MAGIC_EVENT');
      return;
    }

    final mgr = _magicEventAnnotationManager;
    if (mgr == null) return;

    final activeIds = events.map((e) => e.id).toSet();
    for (final id in _magicEventAnnotations.keys.toList()) {
      if (!activeIds.contains(id)) {
        try {
          final ann = _magicEventAnnotations.remove(id);
          if (ann != null) await mgr.delete(ann);
        } catch (_) {}
      }
    }

    final pin = await MagicEventMarkerIcons.pinPng();
    const double iconSize = 1.35;
    const List<double> textOffset = [0, 2.2];
    const int textColor = 0xFF6D28D9;

    for (final e in events) {
      final geom = MapboxUtils.createPoint(e.latitude, e.longitude);
      final label = '${e.participantCount} prezențe';
      if (_magicEventAnnotations.containsKey(e.id)) {
        try {
          final ann = _magicEventAnnotations[e.id]!;
          await mgr.update(
            ann
              ..geometry = geom
              ..image = pin
              ..iconSize = iconSize
              ..iconAnchor = IconAnchor.CENTER
              ..textField = label
              ..textSize = 10
              ..textOffset = textOffset
              ..textColor = textColor
              ..textHaloColor = 0xFFFFFFFF
              ..textHaloWidth = 1.5,
          );
        } catch (_) {}
        continue;
      }
      final options = PointAnnotationOptions(
        geometry: geom,
        image: pin,
        iconSize: iconSize,
        iconAnchor: IconAnchor.CENTER,
        textField: label,
        textSize: 10,
        textOffset: textOffset,
        textColor: textColor,
        textHaloColor: 0xFFFFFFFF,
        textHaloWidth: 1.5,
      );
      final ann = await mgr.create(options);
      _magicEventAnnotations[e.id] = ann;
    }
  }

  void _showMagicEventDetailSheet(MagicEvent event) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String fmt(DateTime d) {
          final loc = d.toLocal();
          final h = loc.hour.toString().padLeft(2, '0');
          final m = loc.minute.toString().padLeft(2, '0');
          return '${loc.day}.${loc.month}.${loc.year} · $h:$m';
        }

        final sub = event.subtitle;

        return DraggableScrollableSheet(
          initialChildSize: 0.42,
          minChildSize: 0.32,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title.isEmpty ? 'Magic event' : event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (sub != null && sub.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      sub,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '${fmt(event.startAt)} – ${fmt(event.endAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rază ~${event.radiusMeters.round()} m · '
                    '${event.participantCount} participanți',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Închide'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _projectMagicEventAuraSlots() async {
    if (!mounted || _mapboxMap == null) return;
    final events = _magicEventsAuraCandidates;
    if (events.isEmpty) {
      if (_magicEventAuraSlots.isNotEmpty && mounted) {
        setState(() => _magicEventAuraSlots = []);
      }
      return;
    }
    try {
      final cam = await _mapboxMap!.getCameraState();
      final zoom = cam.zoom.toDouble();
      final sorted = [...events]
        ..sort((a, b) => b.participantCount.compareTo(a.participantCount));
      final top = sorted.take(6).toList();
      final slots = <NabourAuraMapSlot>[];
      for (final e in top) {
        final pt = MapboxUtils.createPoint(e.latitude, e.longitude);
        final sc = await _mapboxMap!.pixelForCoordinate(pt);
        final mpp = await _mapboxMap!.projection.getMetersPerPixelAtLatitude(
          e.latitude,
          zoom,
        );
        final radiusPx = (e.radiusMeters / mpp).clamp(48.0, 340.0);
        final center = Offset(sc.x.toDouble(), sc.y.toDouble());
        final density = math.max(12, e.participantCount + 16);
        slots.add(NabourAuraMapSlot(
          eventId: e.id,
          screenCenter: center,
          radiusPx: radiusPx,
          userDensity: density,
          rippleTick: _magicEventRippleTick[e.id] ?? 0,
          title: e.title,
          endsAt: e.endAt,
          event: e,
        ));
      }
      if (mounted) setState(() => _magicEventAuraSlots = slots);
    } catch (e) {
      Logger.debug('Aura project: $e', tag: 'MAGIC_EVENT');
    }
  }

  /// [useCommittedLocalRole]: după comutare rol în UI, nu citim `getUserRole` — evită lag replica
  /// care readucea vechiul rol și lăsa avatarul „înghețat” pe cel anterior.
  Future<void> _initializeScreen({bool useCommittedLocalRole = false}) async {
    try {
      late final UserRole role;
      if (useCommittedLocalRole) {
        role = _currentRole;
      } else {
        role = await _firestoreService.getUserRole().timeout(
          const Duration(seconds: 5),
          onTimeout: () => UserRole.passenger,
        );
        if (!mounted) return;
        setState(() {
          _currentRole = role;
        });
      }

      // Validate that driver accounts also have car profile completed.
      final profileSnapshot = await _firestoreService
          .getUserProfileStream()
          .first
          .timeout(const Duration(seconds: 5), onTimeout: () => throw TimeoutException('profile timeout'));
      final profileData = profileSnapshot.data();
      final isVerifiedDriverProfile = _isDriverProfileComplete(profileData);
      if (mounted) {
        setState(() {
          _driverProfile = profileData;
          _manualOrientationPin = _parseMapOrientationPin(profileData);
          _showSavedHomePinOnMap = _parseShowSavedHomePinOnMap(profileData);
          _isDriverAccountVerified = isVerifiedDriverProfile;
          // Nu mai coborâm rolul la pasager: contul rămâne șofer în UI (switch în AppBar).
          // „Disponibil” rămâne blocat de _toggleDriverAvailability până e profilul complet.
        });
        _profileGarageSlotIdsSig = _garageSlotIdsSigFromProfile(profileData);
        unawaited(_syncMapOrientationPinAnnotation());
        if (_positionForUserMapMarker() != null) {
          unawaited(_updateUserMarker(centerCamera: false));
        }
      }

      if (profileData != null && profileData.containsKey('ghostMode')) {
        await GhostModeService.instance
            .syncFromServer(profileData['ghostMode'] == true);
      }
      
      // Locația se obține Ã®n fundal
      unawaited(_getCurrentLocation(centerCamera: true));
      
      // Ascultarea șoferilor Ã®n fundal
      _listenForNearbyDrivers();
      // Vecini vizibili (social map) — fără cost, opt-in
      _listenForNeighbors();
      _listenIncomingFriendRequests();
      // ✅ NOU: Ascultăm alertele de urgență active (SOS Cinematic)
      _listenForEmergencyAlerts();
      // ✅ NOU: Ascultăm cererile de cursă active (pasageri disponibili)
      if (_currentRole == UserRole.driver) {
        _listenForRideBroadcasts();
      }
      // Contacte + prieteni acceptați (friend_peers): după primul frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _listenFriendPeers();
        unawaited(_loadContactUids());
      });

      if (role == UserRole.passenger) {
        unawaited(_checkInactiveUser());
      }
      
      // ✅ RESTAURARE SESIUNE: Verifică dacă există o cursă activă
      unawaited(_checkActiveRide());

      _savedAddressesForHomePinSub?.cancel();
      _savedAddressesForHomePinSub =
          _firestoreService.getSavedAddresses().listen((list) {
        if (!mounted) return;
        setState(() {
          _savedAddressesForHomePin = list;
          _savedAddressesFirestoreHydrated = true;
        });
        unawaited(_syncMapOrientationPinAnnotation());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_syncMapOrientationPinAnnotation());
        });
      }, onError: (Object e) {
        Logger.error('Saved addresses stream: $e', tag: 'MAP', error: e);
        if (mounted) {
          setState(() => _savedAddressesFirestoreHydrated = true);
        }
      });

      _driverProfileSubscription?.cancel();
      _driverProfileSubscription =
          _firestoreService.getUserProfileStream().listen((snapshot) {
        if (!mounted || !snapshot.exists) return;
        final updatedProfile = snapshot.data();
        final newGarageSig = _garageSlotIdsSigFromProfile(updatedProfile);
        if (newGarageSig != _profileGarageSlotIdsSig) {
          _profileGarageSlotIdsSig = newGarageSig;
          unawaited(_loadCustomCarAvatar());
        }
        if (_currentRole == UserRole.driver) {
          final wasAvailable = _isDriverAvailable;
          setState(() {
            _driverProfile = updatedProfile;
            _manualOrientationPin = _parseMapOrientationPin(updatedProfile);
            _showSavedHomePinOnMap = _parseShowSavedHomePinOnMap(updatedProfile);
            _isDriverAccountVerified = _isDriverProfileComplete(updatedProfile);
            if (!_isDriverAccountVerified && _isDriverAvailable) {
              _isDriverAvailable = false;
            }
          });
          if (!_isDriverAccountVerified && wasAvailable && mounted) {
            _stopListeningForRides();
            _stopLocationUpdates();
            unawaited(_firestoreService.updateDriverAvailability(false));
            _ensurePassiveLocationWarmupIfNeeded();
            unawaited(_updateLocationPuck());
          }
          _initializeDriverRideSystem();
        } else {
          setState(() {
            _manualOrientationPin = _parseMapOrientationPin(updatedProfile);
            _showSavedHomePinOnMap = _parseShowSavedHomePinOnMap(updatedProfile);
          });
          unawaited(_syncMapOrientationPinAnnotation());
        }
        unawaited(_syncMapOrientationPinAnnotation());
        if (_positionForUserMapMarker() != null) {
          unawaited(_updateUserMarker(centerCamera: false));
        }
      }, onError: (e) {
        Logger.error('User profile stream error: $e', tag: 'MAP', error: e);
      });

      unawaited(_loadCustomCarAvatar());
    } catch (e) {
      Logger.error('Screen initialization error: $e', error: e);
      if (mounted) {
        setState(() {
          _currentRole = UserRole.passenger;
        });
      }
    }
  }

  /// Plăcuță + nume public pentru eticheta mașinii tale (Firestore `users` + fallback Auth).
  ({String? plate, String? name}) _resolvedPlateAndPublicName() {
    final p = _driverProfile;
    var plate = (p?['licensePlate'] ?? '').toString().trim();
    if (plate.isEmpty) {
      plate = (p?['carPlate'] ?? p?['plate'] ?? '').toString().trim();
    }
    var name = (p?['displayName'] ?? '').toString().trim();
    if (name.isEmpty) {
      name = (p?['name'] ?? p?['publicName'] ?? '').toString().trim();
    }
    if (name.isEmpty) {
      name = (FirebaseAuth.instance.currentUser?.displayName ?? '').trim();
    }
    return (
      plate: plate.isEmpty ? null : plate,
      name: name.isEmpty ? null : name,
    );
  }

  /// După ce `_contactUids` include prietenii, re-trimitem `allowedUids` la Firestore/RTDB.
  void _maybeRepublishSocialMapAfterContactsLoaded() {
    final pos = _currentPositionObject;
    if (pos == null) return;
    if (!_wantsNeighborSocialPublish) return;
    _publishNeighborSocialMapFreshUnawaited(pos, forceNeighborTelemetry: true);
  }

  bool _isDriverProfileComplete(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    String read(String key) => (profile[key] ?? '').toString().trim();
    final hasPlate = read('licensePlate').isNotEmpty;
    // driver_applications folosește carBrand; users folosește adesea carMake
    final hasMake =
        read('carMake').isNotEmpty || read('carBrand').isNotEmpty;
    final hasModel = read('carModel').isNotEmpty;
    final hasColor = read('carColor').isNotEmpty;
    final hasYear = read('carYear').isNotEmpty;
    final hasCategory = read('driverCategory').isNotEmpty;
    return hasPlate && hasMake && hasModel && hasColor && hasYear && hasCategory;
  }

  void _initializeDriverRideSystem() {
    if (_driverProfile != null) {
      final categoryStr = _driverProfile!['driverCategory'] as String?;
      _driverCategory = _getCategoryFromString(categoryStr);
      
      // âœ… FIX: Nu pornim listener-ul aici
      if (_driverCategory != null) {
        Logger.info('Driver system initialized for category: ${_driverCategory!.name}', tag: 'MAP');
        
        // âœ… FIX: Verifică dacă șoferul e deja disponibil din storage
        _checkAndStartDriverSystemIfReady();
      }
    }
  }

  // âœ… SOLUÈšIE COMBINATÄ‚: Metodă nouă pentru verificare completă
  void _checkAndStartDriverSystemIfReady() async {
    final gen = ++_driverAvailabilityCheckGen;
    try {
      final currentStatus = await _firestoreService.getDriverAvailability();

      if (!mounted || gen != _driverAvailabilityCheckGen) return;

      setState(() { _isDriverAvailable = currentStatus; });
      unawaited(_loadCustomCarAvatar());
      unawaited(_updateLocationPuck());

      if (_driverCategory != null && _isDriverAvailable) {
        final cat = _driverCategory!;
        final alreadyRunning = _driverPipelineCategory == cat &&
            _pendingRidesSubscription != null &&
            _positionSubscription != null;
        if (alreadyRunning) {
          if (_currentPositionObject != null) {
            unawaited(_updateUserMarker(centerCamera: false));
          }
          return;
        }
        _driverPipelineCategory = cat;
        Logger.debug(
          'Starting driver system - category: ${cat.name}, available: $_isDriverAvailable',
          tag: 'MAP',
        );
        _startListeningForRides();
        _startDriverLocationUpdates();
      } else {
        _driverPipelineCategory = null;
      }

      if (_currentPositionObject != null) {
        unawaited(_updateUserMarker(centerCamera: false));
        if (_isDriverAvailable && _currentRole == UserRole.driver) {
          _publishNeighborSocialMapFreshUnawaited(
            _currentPositionObject!,
            forceNeighborTelemetry: true,
          );
        }
      }
    } catch (e) {
      Logger.error('Error checking driver status: $e', error: e);
    }
  }

  RideCategory? _getCategoryFromString(String? categoryStr) {
    switch (categoryStr) {
      case 'standard': return RideCategory.standard;
      case 'energy': return RideCategory.energy;
      case 'best': return RideCategory.best;
      case null: return null;
      default: return null;
    }
  }

  void _startListeningForRides() {
    if (_driverCategory == null || !_isDriverAvailable) return;
    
    Logger.debug('Starting to listen for ${_driverCategory!.name} rides', tag: 'MAP');
    
    _pendingRidesSubscription?.cancel();

    // Restore cache (fără sonerie) ca să vezi oferta instant dacă stream-ul Ã®ntârzie.
    _restoreCachedOfferIfPossible(playSound: false);

    _pendingRidesSubscription = _firestoreService
        .getPendingRideRequests(_driverCategory!)
        .listen((rides) {
      Logger.debug('Received ${rides.length} pending rides', tag: 'MAP');

      if (!mounted) return;

      final currentDriverId = FirebaseAuth.instance.currentUser?.uid;
      final availableRides = rides.where((ride) {
        if (ride.status == 'pending') return true;
        if (ride.status == 'driver_found') {
          if (ride.driverId == null || ride.driverId!.isEmpty) return true;
          if (currentDriverId != null && ride.driverId == currentDriverId) return true;
          return false;
        }
        return false;
      }).toList();

      // Update cache scurt.
      _pendingRidesCache = availableRides;
      _offersCacheUpdatedAt = DateTime.now();

      final newFirstRideId = availableRides.isNotEmpty ? availableRides.first.id : null;
      final currentOfferId = _currentRideOffer?.id;

      // Aceeași ofertă â€” actualizează datele fără reset countdown (un singur setState).
      if (_currentRideOffer != null &&
          newFirstRideId != null &&
          currentOfferId == newFirstRideId) {
        setState(() {
          _pendingRides = availableRides;
          _currentRideOffer = availableRides.first;
        });
        return;
      }

      // Ofertă nouă când nu era niciuna afișată.
      if (availableRides.isNotEmpty && _currentRideOffer == null) {
        setState(() { _pendingRides = availableRides; });
        _showRideOffer(availableRides.first, playSound: true);
      } else if (availableRides.isNotEmpty && _currentRideOffer != null) {
        // Switch pe altă ofertă (ID diferit).
        setState(() { _pendingRides = availableRides; });
        _showRideOffer(availableRides.first, playSound: true);
      } else if (availableRides.isEmpty && _currentRideOffer != null) {
        setState(() { _pendingRides = availableRides; });
        _dismissRideOffer();
      } else {
        setState(() { _pendingRides = availableRides; });
      }
    }, onError: (e) {
      Logger.error('Ride offers stream error: $e', tag: 'MAP', error: e);
      // Dacă stream-ul eșuează, păstrează perceived performance prin cache.
      if (mounted) _restoreCachedOfferIfPossible(playSound: false);
    });
  }

  void _stopListeningForRides() {
    _pendingRidesSubscription?.cancel();
    _pendingRidesSubscription = null;
    _driverPipelineCategory = null;
    _rideOfferTimer?.cancel();
    if (mounted) {
      setState(() {
        _pendingRides.clear();
        _currentRideOffer = null;
      });
    }
  }

  void _restoreCachedOfferIfPossible({required bool playSound}) {
    if (_currentRideOffer != null) return;
    if (_pendingRidesCache.isEmpty) return;
    if (_offersCacheUpdatedAt == null) return;

    final age = DateTime.now().difference(_offersCacheUpdatedAt!);
    if (age > _offersCacheTtl) return;

    final ride = _pendingRidesCache.first;
    final elapsedSeconds = age.inSeconds;
    final remaining = (30 - elapsedSeconds).clamp(1, 30).toInt();

    setState(() {
      _pendingRides = _pendingRidesCache;
    });

    _showRideOffer(
      ride,
      playSound: playSound,
      remainingSecondsOverride: remaining,
    );
  }

  void _showRideOffer(
    Ride ride, {
    bool playSound = true,
    int? remainingSecondsOverride,
  }) {
    if (mounted) {
      // âœ… FIX: SETEAZÄ‚ STAREA ÃŽNTÃ‚I
      setState(() {
        _currentRideOffer = ride;
        _remainingSeconds = remainingSecondsOverride ?? 30;
      });
      
      // âœ… FIX: APOI REDÄ‚ SUNETUL DUPÄ‚ FRAME UPDATE
      if (playSound) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _playRideOfferSoundRobust();
          }
        });
      }
    }
    
    Logger.debug('Showing ride offer: ${ride.destinationAddress}', tag: 'MAP');

    _rideOfferTimer?.cancel();
    _rideOfferTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
      }
      
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _dismissRideOffer();
      }
    });
  }

  void _dismissRideOffer() {
    _rideOfferTimer?.cancel();
    _rideOfferTimer = null;
    if (mounted) {
      setState(() {
        _currentRideOffer = null;
        _remainingSeconds = 30;
        _isProcessingAccept = false;
        _isProcessingDecline = false;
      });
      try {
        unawaited(Provider.of<DriverVoiceController>(context, listen: false).reset());
      } catch (_) {}
    }
  }

  Future<void> _acceptRide(Ride ride) async {
    // âœ… FIX: Protecție Ã®mbunătățită Ã®mpotriva apăsărilor multiple
    if (_isProcessingAccept) {
      Logger.debug('Already processing accept request, ignoring duplicate tap', tag: 'MAP');
      return;
    }
    
    // âœ… FIX: Setează starea IMEDIAT, Ã®nainte de orice altceva
    if (!mounted) return;
    setState(() {
      _isProcessingAccept = true;
    });

    // Oprim countdown-ul ca să nu expire oferta Ã®n timp ce așteptăm confirmarea pasagerului.
    _rideOfferTimer?.cancel();
    _rideOfferTimer = null;
    
    // âœ… FIX: Forțează rebuild-ul UI-ului pentru a dezactiva butonul imediat
    await Future.microtask(() {});
    
    try {
      Logger.debug('Accepting ride: ${ride.id}', tag: 'MAP');
      await _firestoreService.acceptRide(ride.id);
      _acceptedRideStatusSubscription?.cancel();
      _acceptedRideStatusSubscription =
          _firestoreService.getRideStream(ride.id).listen((updatedRide) {
        if (!mounted) return;
        if (updatedRide.status == 'accepted' ||
            updatedRide.status == 'arrived' ||
            updatedRide.status == 'in_progress') {
          _acceptedRideStatusSubscription?.cancel();
          _dismissRideOffer();
          unawaited(_navigateDriverPickupWithRide(updatedRide));
        } else if (updatedRide.status == 'cancelled' ||
            updatedRide.status == 'expired') {
          _acceptedRideStatusSubscription?.cancel();
          setState(() {
            _isProcessingAccept = false;
          });
        }
      }, onError: (e) {
        Logger.error('Accept ride watcher failed: $e', tag: 'MAP', error: e);
        if (mounted) {
          setState(() {
            _isProcessingAccept = false;
          });
        }
      });
      
      // âœ… FIX: Nu mai anulăm oferta imediat - așteptăm confirmarea pasagerului
      // _dismissRideOffer(); // Comentat - lăsăm cardul să rămână până când statusul se schimbă
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cursă acceptată! Așteptăm confirmarea pasagerului...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Logger.error('Error accepting ride: $e', tag: 'MAP', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la acceptarea cursei: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessingAccept = false;
        });
        // âœ… FIX: Re-afișează oferta dacă acceptarea a eșuat
        if (_currentRideOffer?.id == ride.id) {
          // Oferta rămâne activă
        }
      }
    } finally {
      // Resetarea _isProcessingAccept se face Ã®n _dismissRideOffer()
      // când stream-ul confirmă că oferta a fost consumată.
    }
  }

  Future<void> _declineRide(Ride ride) async {
    // ðŸš— FIX: Protecție Ã®mpotriva apăsărilor multiple
    if (_isProcessingDecline) {
      Logger.debug('Already processing decline request, ignoring duplicate tap', tag: 'MAP');
      return;
    }
    _acceptedRideStatusSubscription?.cancel();

    // Cere motivul anulării de la șofer
    if (mounted) {
      final reason = await CancellationDialog.show(context);
      if (reason == null) return; // șoferul a apăsat "ÃŽnapoi"
      unawaited(CancellationService().recordDriverCancellation(ride.id, reason));
    }

    setState(() {
      _isProcessingDecline = true;
    });

    // Oprim countdown-ul imediat.
    _rideOfferTimer?.cancel();
    _rideOfferTimer = null;

    try {
      Logger.debug('Declining ride: ${ride.id}', tag: 'MAP');
      await _firestoreService.declineRide(ride.id);
      _dismissRideOffer();
      
      final remainingRides = _pendingRides.where((r) => r.id != ride.id).toList();
      if (remainingRides.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showRideOffer(remainingRides.first);
          }
        });
      }
    } catch (e) {
      Logger.error('Error declining ride: $e', tag: 'MAP', error: e);
    } finally {
      // ðŸš— FIX: Reset protecția după procesare
      if (mounted) {
        setState(() {
          _isProcessingDecline = false;
        });
      }
    }
  }

  void _onSearchingForDriverPopped(Object? value) {
    if (!mounted || _currentRole != UserRole.passenger) return;
    try {
      Provider.of<FriendsRideVoiceIntegration>(context, listen: false)
          .markReturnedFromDriverSearch();
    } catch (_) {}
    if (value is PassengerSearchFlowResult) {
      _handlePassengerSearchFlowResult(value);
    }
  }

  void _onPassengerRideBus() {
    if (PassengerRideServiceBus.pending.value != null) {
      _drainPassengerRideBus();
    }
  }

  void _drainPassengerRideBus() {
    final v = PassengerRideServiceBus.pending.value;
    if (v == null || !mounted) return;
    PassengerRideServiceBus.pending.value = null;
    _handlePassengerSearchFlowResult(v);
  }

  void _handlePassengerSearchFlowResult(PassengerSearchFlowResult r) {
    if (!mounted || _currentRole != UserRole.passenger) return;
    if (r.shouldOpenSummary) {
      _endPassengerRideSession();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RideSummaryScreen(rideId: r.rideId)),
      );
      return;
    }
    _beginPassengerRideSession(r.rideId);
  }

  void _endPassengerRideSession() {
    _passengerRideSessionSub?.cancel();
    _passengerRideSessionSub = null;
    _passengerRideSessionId = null;
    _passengerSessionRide = null;
    _passengerDestinationHandoffStarted = false;
    if (mounted) setState(() {});
  }

  void _beginPassengerRideSession(String rideId) {
    if (!mounted || _currentRole != UserRole.passenger) return;
    if (_passengerRideSessionId == rideId && _passengerRideSessionSub != null) {
      return;
    }
    _endPassengerRideSession();
    _passengerRideSessionId = rideId;
    _passengerDestinationHandoffStarted = false;
    _passengerRideSessionSub =
        _firestoreService.getRideStream(rideId).listen((ride) {
      if (!mounted) return;
      if (_passengerRideSessionId != ride.id) return;
      setState(() => _passengerSessionRide = ride);

      if (ride.status == 'arrived' && !_passengerDestinationHandoffStarted) {
        final lat = ride.destinationLatitude;
        final lng = ride.destinationLongitude;
        if (lat != null && lng != null) {
          _passengerDestinationHandoffStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(_runPassengerDestinationHandoffFromMap(lat, lng));
          });
        }
      }

      if (const {'completed', 'cancelled', 'expired'}.contains(ride.status)) {
        final summary = ride.status == 'completed';
        _endPassengerRideSession();
        if (summary && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RideSummaryScreen(rideId: ride.id)),
          );
        }
      }
    });
  }

  Future<void> _runPassengerDestinationHandoffFromMap(
    double destLat,
    double destLng,
  ) async {
    if (!mounted) return;
    await ExternalMapsLauncher.showNavigationChooser(
      context,
      destLat,
      destLng,
      title: 'Destinație finală',
      hint: 'Deschide în aplicația de navigație spre destinație. Revii apoi la hartă.',
    );
  }

  String _passengerRideSessionStatusLabel(String status) {
    switch (status) {
      case 'driver_found':
        return 'Șofer găsit — așteptă confirmarea ta';
      case 'accepted':
        return 'Șofer în drum spre tine';
      case 'arrived':
        return 'Șofer la pickup — deschide navigația spre destinație';
      case 'in_progress':
        return 'Cursă în desfășurare';
      default:
        return 'Cursă: $status';
    }
  }

  Widget _buildPassengerRideSessionOverlay() {
    final ride = _passengerSessionRide;
    if (ride == null) return const SizedBox.shrink();

    final pickupLat = ride.startLatitude;
    final pickupLng = ride.startLongitude;
    final destLat = ride.destinationLatitude;
    final destLng = ride.destinationLongitude;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _passengerRideSessionStatusLabel(ride.status),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (ride.status == 'accepted' &&
                pickupLat != null &&
                pickupLng != null)
              OutlinedButton.icon(
                onPressed: () {
                  unawaited(
                    ExternalMapsLauncher.showNavigationChooser(
                      context,
                      pickupLat,
                      pickupLng,
                      title: 'Navigare spre pickup',
                      hint: 'Aplicație de navigație (fără rută în Nabour).',
                    ),
                  );
                },
                icon: const Icon(Icons.place_outlined, size: 20),
                label: const Text('Pickup: navigație externă'),
              ),
            if (ride.status == 'arrived' && destLat != null && destLng != null) ...[
              const SizedBox(height: 6),
              Text(
                'Deschide aceeași destinație ca și șoferul în app-ul de navigație.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  unawaited(
                    ExternalMapsLauncher.showNavigationChooser(
                      context,
                      destLat,
                      destLng,
                      title: 'Destinație finală',
                      hint: 'Aplicație de navigație (fără rută în Nabour).',
                    ),
                  );
                },
                icon: const Icon(Icons.flag_rounded, size: 20),
                label: const Text('Destinație: navigație externă'),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _endPassengerRideSession,
                child: const Text('Închide panoul'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ RESTAURARE SESIUNE: Verifică dacă utilizatorul curent are o cursă activă (pasager sau șofer)
  /// și îl redirecționează către ecranul respectiv.
  Future<void> _checkActiveRide() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Verificăm statusurile care indică o cursă în desfășurare
      final activeStatuses = ['accepted', 'arrived', 'in_progress', 'driver_found'];
      
      // 1. Verificăm dacă este pasager într-o cursă activă
      final passengerQuery = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('passengerId', isEqualTo: currentUserId)
          .where('status', whereIn: activeStatuses)
          .limit(1)
          .get();

      if (passengerQuery.docs.isNotEmpty && mounted) {
        final rideDoc = passengerQuery.docs.first;
        Logger.info('Restoring passenger session on map for ride: ${rideDoc.id}');
        _beginPassengerRideSession(rideDoc.id);
        return;
      }

      // 2. Verificăm dacă este șofer într-o cursă activă
      final driverQuery = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('driverId', isEqualTo: currentUserId)
          .where('status', whereIn: activeStatuses)
          .limit(1)
          .get();
          
      if (driverQuery.docs.isNotEmpty && mounted) {
         final rideDoc = driverQuery.docs.first;
         Logger.info('Restoring driver session for ride: ${rideDoc.id}');
         if (mounted) {
           final ride = Ride.fromFirestore(
             rideDoc as DocumentSnapshot<Map<String, dynamic>>,
           );
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => DriverRidePickupScreen(
                 rideId: rideDoc.id,
                 ride: ride,
               ),
             ),
           );
         }
      }
    } catch (e) {
      Logger.error('Error during session restoration check: $e', error: e);
    }
  }

  /// După încărcarea agendei, stream-urile vecini/șoferi nu reemit automat — refacem straturile din cache.
  Future<void> _reapplyContactFilterOnMap() async {
    if (!mounted) return;
    await _updateNeighborAnnotations(_lastRawNeighborsForMap);
    await _updateNearbyDrivers(_lastNearbyDriverDocs);
  }

  void _rebuildMergedContactUids() {
    final fromAgenda = _contactUsers.map((u) => u.uid).toSet();
    _contactUids = {...fromAgenda, ..._friendPeerUids};
  }

  void _listenFriendPeers() {
    _friendPeersSub?.cancel();
    _friendPeersSub =
        FriendRequestService.instance.friendPeerUidsStream().listen((peers) {
      if (!mounted) return;
      setState(() {
        _friendPeerUids = peers;
        _rebuildMergedContactUids();
      });
      unawaited(_reapplyContactFilterOnMap());
      _maybeRepublishSocialMapAfterContactsLoaded();
    });
  }

  /// Firestore trimite actualizări în timp real — nu există interval fix de „refresh”.
  void _listenIncomingFriendRequests() {
    _incomingFriendRequestsSub?.cancel();
    _incomingFriendRequestsSub =
        FriendRequestService.instance.incomingPendingStream().listen(
      (list) {
        if (!mounted) return;
        setState(() => _pendingIncomingFriendRequestCount = list.length);
      },
      onError: (Object e, StackTrace st) {
        Logger.error(
          'Incoming friend requests stream: $e',
          error: e,
          stackTrace: st,
          tag: 'SOCIAL',
        );
      },
    );
  }

  /// Sincronizare prieteni acceptați (când tu ai trimis cererea) + reîncărcare UID-uri.
  Future<void> _syncFriendPeersIntoContactUids() async {
    if (!mounted) return;
    await FriendRequestService.instance.ensureFriendPeersForAcceptedOutgoing();
    if (!mounted) return;
    final peers = await FriendRequestService.instance.loadFriendPeerUidSet();
    if (!mounted) return;
    setState(() {
      _friendPeerUids = peers;
      _rebuildMergedContactUids();
    });
    await _reapplyContactFilterOnMap();
    _maybeRepublishSocialMapAfterContactsLoaded();
  }

  Future<void> _loadContactUids() async {
    await FriendRequestService.instance.ensureFriendPeersForAcceptedOutgoing();
    final users = await _contactsService.loadContactUsers();
    final peers = await FriendRequestService.instance.loadFriendPeerUidSet();
    final excluded = await VisibilityPreferencesService().loadExcludedUids();
    if (mounted) {
      setState(() {
        _contactUsers = users;
        _friendPeerUids = peers;
        _rebuildMergedContactUids();
        _excludedUids = excluded;
      });
      unawaited(_reapplyContactFilterOnMap());
      _maybeRepublishSocialMapAfterContactsLoaded();
      if (users.isEmpty && _friendPeerUids.isEmpty && !_contactEmptyHintShown) {
        _contactEmptyHintShown = true;
        _showSafeSnackBar(
          'Pe hartă apar doar prietenii acceptați sau contactele din telefon care au cont Nabour. '
          'Adaugă numerele în agendă sau acceptă o cerere din Sugestii.',
          Colors.blueGrey,
        );
      }
    }
  }

  /// ✅ NOU: Sincronizare manuală contacte
  Future<void> _refreshContacts() async {
    if (!mounted) return;
    _showSafeSnackBar('Sincronizez contactele...', Colors.indigo);
    
    await FriendRequestService.instance.ensureFriendPeersForAcceptedOutgoing();
    // Force refresh cache în service
    final users = await _contactsService.loadContactUsers(forceRefresh: true);
    final peers = await FriendRequestService.instance.loadFriendPeerUidSet();
    final excluded = await VisibilityPreferencesService().loadExcludedUids();
    
    if (mounted) {
      setState(() {
        _contactUsers = users;
        _friendPeerUids = peers;
        _rebuildMergedContactUids();
        _excludedUids = excluded;
      });
      unawaited(_reapplyContactFilterOnMap());
      _maybeRepublishSocialMapAfterContactsLoaded();
      _showSafeSnackBar('Sincronizare completă: ${users.length} nume găsite.', Colors.green);
    }
  }

  /// Cursele „doar contacte”: lista trebuie încărcată și nevidă. Lista goală în Firestore exclude toți șoferii.
  bool _canRequestRideWithContactFilter() {
    if (_contactUids == null) return false;
    return _contactUids!.isNotEmpty;
  }

  void _handleRoleChange(bool isDriver) {
    if (isDriver && !_isDriverAccountVerified) {
      _showSafeSnackBar(
        'Activează profilul de șofer și adaugă mașina ca să folosești modul șofer.',
        Colors.orange,
      );
      return;
    }
    final newRole = isDriver ? UserRole.driver : UserRole.passenger;
    if (_currentRole == newRole) return;

    if (!isDriver && _isDriverAvailable) {
      _stopLocationUpdates();
      _stopListeningForRides();
      unawaited(_firestoreService.updateDriverAvailability(false));
      setState(() { _isDriverAvailable = false; });
      _ensurePassiveLocationWarmupIfNeeded();
    }

    // âœ… FIX: Actualizează imediat rolul local pentru un feedback UI instantaneu
    setState(() { _currentRole = newRole; });
    
    // Reset─âm cache marker pentru a for╚øa recrearea pe noul rol (pasager vs ╚Öofer)
    _userMarkerVisualCacheKey = null;
    _userDriverMarkerIconInFlight = null;
    _forceUserCarMarkerFullRebuild = true;
    _markerIconCache.clear();

    // Dup─â frame: `setState` e vizibil, apoi desen─âm slotul corect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_updateUserMarker(centerCamera: false));
      unawaited(_updateLocationPuck());
      unawaited(_loadCustomCarAvatar());
    });

    // Salvează asincron și remapează ascultătorii existenți
    _firestoreService.setUserRole(newRole).then((_) {
        if (mounted) { 
          unawaited(_clearSocialMapMarkers()); // ✅ CURĂȚĂ Tot înainte de re-inițializare
          unawaited(_initializeScreen(useCommittedLocalRole: true));
        }
    });
  }

  void _freezeMapWidgetCameraIfNeeded() {
    if (_mapWidgetFrozenCamera != null) return;
    final p = _currentPositionObject;
    if (p == null) return;
    _mapWidgetFrozenCamera = CameraOptions(
      center: MapboxUtils.createPoint(p.latitude, p.longitude),
      zoom: _overviewZoomForLatitude(p.latitude),
    );
  }

  CameraOptions get _mapWidgetCameraOptions {
    if (_mapWidgetFrozenCamera != null) return _mapWidgetFrozenCamera!;
    _mapWidgetFallbackCamera ??= CameraOptions(
      center: MapboxUtils.createPoint(44.4268, 26.1025),
      zoom: _overviewZoomForLatitude(44.4268),
      pitch: 45.0,
    );
    return _mapWidgetFallbackCamera!;
  }

  /// ðŸš€ PERFORMANÈšÄ‚: ObÈ›ine ultima locaÈ›ie cunoscutÄƒ IMEDIAT, fÄƒrÄƒ a aÈ™tepta hardware-ul GPS.
  /// Astfel, harta se va deschide deja centratÄƒ pe utilizator.
  Future<void> _tryPreloadLastKnownLocation() async {
    try {
      final pos = await geolocator.Geolocator.getLastKnownPosition();
      if (pos != null && mounted) {
        setState(() {
          _currentPositionObject = pos;
          _mapWidgetFallbackCamera = CameraOptions(
            center: MapboxUtils.createPoint(pos.latitude, pos.longitude),
            zoom: _overviewZoomForLatitude(pos.latitude),
          );
        });
        unawaited(_updateUserMarker(centerCamera: false));
        unawaited(_updateCurrentStreetName());
        _ensureNeighborsListeningAfterPosition();
      }
    } catch (_) {}
  }

  /// Called once the map is ready. Centers immediately on last known position
  /// (instant), then requests accurate GPS and re-centers.
  Future<void> _centerOnLocationOnMapReady() async {
    // Deja încălzit din init (preload / getCurrentLocation timpuriu) — centrează imediat.
    if (_currentPositionObject != null && mounted && _mapboxMap != null) {
      try {
        LocationCacheService.instance.record(_currentPositionObject!);
        await _centerCameraOnCurrentPosition();
        unawaited(_updateWeatherAndStyle(
          _currentPositionObject!.latitude,
          _currentPositionObject!.longitude,
        ));
        unawaited(_updateUserMarker(centerCamera: false));
        unawaited(_updateCurrentStreetName());
      } catch (_) {}
    }

    // Ultima poziție de la OS (poate fi mai proaspătă decât cache-ul din memorie).
    try {
      final lastKnown = await geolocator.Geolocator.getLastKnownPosition().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (lastKnown != null && mounted) {
        LocationCacheService.instance.record(lastKnown);
        setState(() {
          _currentPositionObject = lastKnown;
          _freezeMapWidgetCameraIfNeeded();
        });
        unawaited(_updateWeatherAndStyle(
          lastKnown.latitude,
          lastKnown.longitude,
        ));
        await _centerCameraOnCurrentPosition();
        unawaited(_updateUserMarker(centerCamera: false));
        unawaited(_updateCurrentStreetName());
      }
    } catch (_) {}

    // Fix GPS precis; recentrează dacă s-a actualizat poziția.
    await _getCurrentLocation(centerCamera: true);
  }

  Future<void> _centerCameraOnCurrentPosition() async {
    if (!mounted || _mapboxMap == null || _currentPositionObject == null) return;
    try {
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: MapboxUtils.createPoint(
            _currentPositionObject!.latitude,
            _currentPositionObject!.longitude,
          ),
          zoom: _overviewZoomForLatitude(_currentPositionObject!.latitude),
        ),
        MapAnimationOptions(duration: AppDrawer.lowDataMode ? 500 : 1100),
      );
    } catch (e) {
      Logger.warning('Auto-center failed: $e');
    }
  }

  /// Origine pentru [PointNavigationScreen]: puck GPS → cache → centrul camerei hărții.
  Future<({double? lat, double? lng})> _navigationOriginSeedLatLng() async {
    final p = _currentPositionObject;
    if (p != null) {
      return (lat: p.latitude, lng: p.longitude);
    }
    final cached = LocationCacheService.instance.peekRecent(
      maxAge: const Duration(minutes: 10),
    );
    if (cached != null) {
      return (lat: cached.latitude, lng: cached.longitude);
    }
    final map = _mapboxMap;
    if (map != null && mounted) {
      try {
        final cam = await map.getCameraState();
        final lat = cam.center.coordinates.lat.toDouble();
        final lng = cam.center.coordinates.lng.toDouble();
        Logger.info(
          'POINT_NAV seed: centrul camerei hărții (fără GPS încă) '
          '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}',
          tag: 'MAP',
        );
        return (lat: lat, lng: lng);
      } catch (e) {
        Logger.debug('navigationOriginSeed camera: $e');
      }
    }
    return (lat: null, lng: null);
  }

  Future<void> _getCurrentLocation({bool centerCamera = false}) async {
    try {
      // 🚀 PERFORMANȚĂ: Timeout pentru verificarea permisiunilor
      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission()
          .timeout(const Duration(seconds: 8), onTimeout: () {
        Logger.warning('Permission check timeout');
        return geolocator.LocationPermission.denied;
      });
      
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission()
            .timeout(const Duration(seconds: 8), onTimeout: () {
          Logger.warning('Permission request timeout');
          return geolocator.LocationPermission.denied;
        });
        
        if (permission != geolocator.LocationPermission.whileInUse && 
            permission != geolocator.LocationPermission.always) {
          return;
        }
      }
      
      // 🚀 PERFORMANȚĂ: Timeout pentru obținerea locației
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        ),
      ).timeout(const Duration(seconds: 18), onTimeout: () {
        throw TimeoutException('Location request timeout');
      });
      
      if (mounted) {
        LocationCacheService.instance.record(position);
        setState(() {
          _currentPositionObject = position;
          _freezeMapWidgetCameraIfNeeded();
        });
        unawaited(_updateWeatherAndStyle(
          position.latitude,
          position.longitude,
        ));
        if (centerCamera) {
          await _centerCameraOnCurrentPosition();
        }
        unawaited(_updateUserMarker(centerCamera: false));
        unawaited(_syncMapOrientationPinAnnotation());
        unawaited(_updateCurrentStreetName());
        _ensureNeighborsListeningAfterPosition();
      }
    } catch (e) {
      Logger.debug("Could not get current location: $e");
      // 🚀 PERFORMANȚĂ: Încercăm să folosim ultima locație cunoscută
      try {
        final lastKnownPosition = await geolocator.Geolocator.getLastKnownPosition()
            .timeout(const Duration(seconds: 3));
        if (lastKnownPosition != null && mounted) {
          LocationCacheService.instance.record(lastKnownPosition);
          setState(() {
            _currentPositionObject = lastKnownPosition;
            _freezeMapWidgetCameraIfNeeded();
          });
          unawaited(_updateWeatherAndStyle(
            lastKnownPosition.latitude,
            lastKnownPosition.longitude,
          ));
          if (centerCamera) {
            await _centerCameraOnCurrentPosition();
          }
          unawaited(_updateUserMarker(centerCamera: false));
          unawaited(_syncMapOrientationPinAnnotation());
          _ensureNeighborsListeningAfterPosition();
        }
      } catch (fallbackError) {
        Logger.debug("Could not get last known location: $fallbackError");
      }
    }
  }

  /// Actualizează vremea pentru overlay (max ~1 dată / 60 min). Stilul hărții = doar tema UI.
  Future<void> _updateWeatherAndStyle(double latitude, double longitude) async {
    if (_weatherLoading) return;
    final now = DateTime.now();
    if (_lastWeatherUpdate != null && now.difference(_lastWeatherUpdate!) < const Duration(minutes: 60)) return;

    setState(() => _weatherLoading = true);
    try {
      final data = await OpenMeteoService().fetchCurrentWeather(latitude: latitude, longitude: longitude);
      if (data != null && mounted) {
        setState(() {
          _weatherTemp = data['temp'];
          _weatherType = _getWeatherTypeFromCode(data['weatherCode']);
          _lastWeatherUpdate = now;
          _weatherLoading = false;
        });
        // Stilul hărții nu se mai schimbă automat după zi/noapte meteo — doar din tema UI (user).
      }
    } catch (e) {
      Logger.error('Weather update failed: $e');
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  WeatherType _getWeatherTypeFromCode(int code) {
    if (code == 0) return WeatherType.sunny;
    if (code >= 1 && code <= 3) return WeatherType.cloudy;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return WeatherType.rainy;
    if (code >= 71 && code <= 77) return WeatherType.snowy;
    if (code >= 95) return WeatherType.thunderstorm;
    return WeatherType.none;
  }

  static const Set<String> _activeRideStatusesForTelemetry = {
    'accepted',
    'arrived',
    'in_progress',
    'driver_found',
  };

  /// Context pentru `telemetry/active_rides/{rideId}` când șoferul are cursă activă.
  ({String rideId, String passengerId})? _activeRideLocationContext() {
    final ride = _currentActiveRide;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (ride == null || uid == null) return null;
    if (ride.driverId != uid) return null;
    if (!_activeRideStatusesForTelemetry.contains(ride.status)) return null;
    return (rideId: ride.id, passengerId: ride.passengerId);
  }

  void _pushDriverLocationToBackend(
    geolocator.Position position, {
    double? bearing,
  }) {
    final ctx = _activeRideLocationContext();
    _firestoreService.updateDriverLocation(
      position,
      bearing: bearing,
      activeRideId: ctx?.rideId,
      activeRidePassengerId: ctx?.passengerId,
    );
  }

  Future<void> _pushDriverLocationToBackendAwait(geolocator.Position position) async {
    _pushDriverLocationToBackend(position);
  }

  // ✅ ÎMBUNĂTĂȚIT: Combinăm stream-ul GPS cu timer constant pentru șoferii stăționari
  void _startDriverLocationUpdates() {
    _stopLocationUpdates();
    
    // distanceFilter mic = puncte mai dese → mișcare mai cursivă pe hartă (cost mic extra).
    const locationSettings = geolocator.LocationSettings(
      accuracy: geolocator.LocationAccuracy.high,
      distanceFilter: 4,
    );

    // ✅ CURSOR FIX: Timer cu background execution
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!mounted) return;

      if (_isDriverAvailable && _currentRole == UserRole.driver) {
        unawaited(_updateDriverLocationInBackground());
      }

      // Social map: vizibilitate vecini sau șofer disponibil (fără Ghost Mode).
      if (_wantsNeighborSocialPublish && _currentPositionObject != null) {
        _publishNeighborSocialMapFreshUnawaited(_currentPositionObject!);
      }
    });

    // Pornim ascultarea stream-ului pentru mișcări în timp real
    _positionSubscription = geolocator.Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((geolocator.Position position) {
      
      if (!mounted || !_isDriverAvailable || _currentRole != UserRole.driver) {
        return;
      }
      
      // NOU: Logica de frecvență adaptivă
      final now = DateTime.now();
      int currentInterval;
      final speed = position.speed;

      if (speed < 1.5) { // Sub ~5 km/h, considerăm că stă pe loc
        currentInterval = _standingInterval;
      } else if (speed < 10) { // Sub 36 km/h, viteză de oraș
        currentInterval = _slowSpeedInterval;
      } else { // Viteză mare
        currentInterval = _highSpeedInterval;
      }

      // Verificăm dacă a trecut suficient timp de la ultima trimitere
      if (_lastUpdateTime == null || now.difference(_lastUpdateTime!).inSeconds >= currentInterval) {
        
        Logger.debug('--> Sending location update. Speed: ${speed.toStringAsFixed(2)} m/s. Interval: $currentInterval s.');
        
        final snappedPosition = _applyRoadSnapping(position);
        LocationCacheService.instance.record(snappedPosition);
        // Bearing are sens doar in miscare — la viteza 0 GPS-ul returneaza 0.0
        // indiferent de orientarea reala, ceea ce ar roti gresit icona soferului.
        final movingBearing = snappedPosition.speed >= 0.5 ? snappedPosition.heading : null;
        _pushDriverLocationToBackend(snappedPosition, bearing: movingBearing);
        
        _previousPositionObject = _currentPositionObject;
        if (mounted) {
          setState(() {
            _currentPositionObject = snappedPosition;
            _freezeMapWidgetCameraIfNeeded();
          });
        }
        
        _updateDriverRideEstimates(snappedPosition);
        _updateUserMarker(centerCamera: false);
        _publishNeighborSocialMapFreshUnawaited(snappedPosition);
        unawaited(_maybePollMagicEventsThrottled());

        // Resetăm cronometrul
        _lastUpdateTime = now;
      }
    }, onError: (error) {
      Logger.error("Eroare la stream-ul de locație: $error", error: error);
    });

    Logger.info('▶ Started location stream');
  }

  /// Pasager sau șofer indisponibil: stream ușor ca GPS-ul să aibă deja fix când deschizi navigarea la punct.
  void _ensurePassiveLocationWarmupIfNeeded() {
    if (!mounted) return;
    if (_passengerWarmupSubscription != null) return;
    if (_currentRole == UserRole.driver && _isDriverAvailable) return;

    try {
      _passengerWarmupSubscription =
          geolocator.Geolocator.getPositionStream(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.medium,
          distanceFilter: 12,
        ),
      ).listen(
        (geolocator.Position p) {
          LocationCacheService.instance.record(p);
          if (!mounted) return;
          if (_currentRole == UserRole.driver && _isDriverAvailable) return;
          setState(() {
            _currentPositionObject = p;
            _freezeMapWidgetCameraIfNeeded();
          });
          unawaited(_updateUserMarker(centerCamera: false));
          unawaited(_updateCurrentStreetName(throttle: true));
          unawaited(_maybePollMagicEventsThrottled());
          _ensureNeighborsListeningAfterPosition();
        },
        onError: (Object e) {
          Logger.warning('Passive GPS warmup: $e', tag: 'MAP');
        },
      );
      Logger.info('Passive GPS warmup stream started', tag: 'MAP');
    } catch (e) {
      Logger.warning('Passive GPS warmup failed: $e', tag: 'MAP');
    }
  }

  // ✅ ÎMBUNĂTĂȚIT: Oprește și stream-ul și timer-ul
  void _stopLocationUpdates() {
    if (_passengerWarmupSubscription != null) {
      _passengerWarmupSubscription!.cancel();
      _passengerWarmupSubscription = null;
      Logger.debug('Stopped passive GPS warmup stream');
    }
    if (_positionSubscription != null) {
      _positionSubscription!.cancel();
      _positionSubscription = null;
      Logger.debug('⏹ Stopped location stream');
    }
    
    // ✅ ADĂUGAT: Oprește și timer-ul constant
    if (_locationUpdateTimer != null) {
      _locationUpdateTimer!.cancel();
      _locationUpdateTimer = null;
      Logger.debug('⏹ Stopped location timer');
    }

    // Social map periodic publish (pasager / driver indisponibil)
    if (_visibilityPublishTimer != null) {
      _visibilityPublishTimer!.cancel();
      _visibilityPublishTimer = null;
      Logger.debug('⏹ Stopped visibility publish timer');
    }
  }

  // ✅ CURSOR: Background location update method
  Future<void> _updateDriverLocationInBackground() async {
    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        ),
      );
      
      // ✅ Actualizează Firestore (+ RTDB cursă activă dacă e cazul)
      LocationCacheService.instance.record(position);
      await _pushDriverLocationToBackendAwait(position);
      
      // ✅ UI update pe main thread
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _currentPositionObject = position;
            _freezeMapWidgetCameraIfNeeded();
          });
          _updateDriverRideEstimates(position);
        });
      }
      
      Logger.debug('Background location update successful');
    } catch (e) {
      Logger.error('Background location update failed: $e', error: e);
    }
  }

  void _resetDriverEtaMetrics() {
    if (!mounted) return;
    setState(() {
      _driverPickupDistanceKm = null;
      _driverPickupEta = null;
      _driverPickupArrivalTime = null;
      _driverDestinationDistanceKm = null;
      _driverDestinationEta = null;
      _driverDestinationArrivalTime = null;
      _driverTrafficSummary = null;
    });
  }

  bool _shouldIncludePickupLeg(String? status) {
    const pickupStates = {
      'driver_found',
      'accepted',
      'driver_en_route',
      'arrived',
    };
    if (status == null) return true;
    return pickupStates.contains(status);
  }

  void _updateDriverRideEstimates(geolocator.Position driverPosition) {
    if (!mounted || _currentActiveRide == null) return;

    final ride = _currentActiveRide!;
    final includePickupLeg = _shouldIncludePickupLeg(ride.status);

    double? pickupDistanceMeters;
    double? destinationDistanceMeters;

    if (includePickupLeg &&
        ride.startLatitude != null &&
        ride.startLongitude != null) {
      pickupDistanceMeters = geolocator.Geolocator.distanceBetween(
        driverPosition.latitude,
        driverPosition.longitude,
        ride.startLatitude!,
        ride.startLongitude!,
      );
    }

    if (ride.destinationLatitude != null && ride.destinationLongitude != null) {
      destinationDistanceMeters = geolocator.Geolocator.distanceBetween(
        driverPosition.latitude,
        driverPosition.longitude,
        ride.destinationLatitude!,
        ride.destinationLongitude!,
      );
    }

    const averageSpeedMps = 10.0;
    Duration? pickupEta;
    Duration? destinationEta;
    DateTime? pickupArrival;
    DateTime? destinationArrival;

    if (!includePickupLeg) {
      pickupDistanceMeters = 0;
      pickupEta = Duration.zero;
      pickupArrival = DateTime.now();
    } else if (pickupDistanceMeters != null) {
      final etaSeconds =
          (pickupDistanceMeters / averageSpeedMps).clamp(0, 60 * 60 * 2).toInt();
      pickupEta = Duration(seconds: etaSeconds);
      pickupArrival = DateTime.now().add(pickupEta);
    }

    if (destinationDistanceMeters != null) {
      final etaSeconds = (destinationDistanceMeters / averageSpeedMps)
          .clamp(0, 60 * 60 * 3)
          .toInt();
      destinationEta = Duration(seconds: etaSeconds);
      destinationArrival = DateTime.now().add(destinationEta);
    }

    setState(() {
      _driverPickupDistanceKm = pickupDistanceMeters != null
          ? pickupDistanceMeters / 1000.0
          : (includePickupLeg ? null : 0);
      _driverPickupEta = pickupEta;
      _driverPickupArrivalTime = pickupArrival;

      _driverDestinationDistanceKm = destinationDistanceMeters != null
          ? destinationDistanceMeters / 1000.0
          : null;
      _driverDestinationEta = destinationEta;
      _driverDestinationArrivalTime = destinationArrival;

      if (pickupDistanceMeters == null &&
          destinationDistanceMeters == null &&
          !includePickupLeg) {
        _driverTrafficSummary = null;
      }
    });

    final now = DateTime.now();
    final hasRecentRequest = _driverLastEtaRequestTime != null &&
        now.difference(_driverLastEtaRequestTime!) < _driverEtaThrottle;

    final bool movedEnough;
    if (_driverLastEtaPosition == null) {
      movedEnough = true;
    } else {
      final movedMeters = geolocator.Geolocator.distanceBetween(
        driverPosition.latitude,
        driverPosition.longitude,
        _driverLastEtaPosition!.latitude,
        _driverLastEtaPosition!.longitude,
      );
      movedEnough = movedMeters >= _driverEtaDistanceThresholdMeters;
    }

    if (hasRecentRequest || !movedEnough || _driverIsFetchingEta) {
      return;
    }

    _driverLastEtaRequestTime = now;
    _driverLastEtaPosition = driverPosition;
    unawaited(_fetchDriverPreciseEta(driverPosition));
  }

  Future<void> _fetchDriverPreciseEta(geolocator.Position driverPosition) async {
    if (_driverIsFetchingEta || _currentActiveRide == null) return;

    final ride = _currentActiveRide!;
    final includePickupLeg = _shouldIncludePickupLeg(ride.status);

    final waypoints = <Point>[
      MapboxUtils.createPoint(driverPosition.latitude, driverPosition.longitude),
    ];

    if (includePickupLeg &&
        ride.startLatitude != null &&
        ride.startLongitude != null) {
      waypoints.add(MapboxUtils.createPoint(ride.startLatitude!, ride.startLongitude!));
    }

    if (ride.destinationLatitude != null && ride.destinationLongitude != null) {
      waypoints.add(MapboxUtils.createPoint(ride.destinationLatitude!, ride.destinationLongitude!));
    }

    if (waypoints.length < 2) return;

    _driverIsFetchingEta = true;
    try {
      final routeResult = await _routingService.getRoute(waypoints);
      if (!mounted || routeResult == null) return;

      final routes = routeResult['routes'];
      if (routes is! List || routes.isEmpty) return;

      final route = routes.first;
      if (route is! Map<String, dynamic>) return;

      final totalDistance = (route['distance'] as num?)?.toDouble();
      final totalDuration = (route['duration'] as num?)?.toDouble();

      double? pickupDistance;
      double? pickupDuration;
      String? trafficSummary;

      final legs = route['legs'];
      if (legs is List && legs.isNotEmpty) {
        final congestionCounts = <String, int>{};
        for (final legEntry in legs) {
          if (legEntry is Map<String, dynamic>) {
            final congestion = (legEntry['annotation'] as Map<String, dynamic>?)
                ?['congestion'];
            if (congestion is List) {
              for (final value in congestion) {
                if (value is String && value.isNotEmpty) {
                  congestionCounts.update(value, (v) => v + 1, ifAbsent: () => 1);
                }
              }
            }
          }
        }

        if (congestionCounts.isNotEmpty) {
          final dominant = congestionCounts.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
          trafficSummary = switch (dominant) {
            'low' => 'Trafic lejer',
            'moderate' => 'Trafic moderat',
            'heavy' => 'Trafic aglomerat',
            'severe' => 'Trafic foarte aglomerat',
            _ => null,
          };
        }

        if (includePickupLeg) {
          final firstLeg = legs.first;
          if (firstLeg is Map<String, dynamic>) {
            pickupDistance = (firstLeg['distance'] as num?)?.toDouble();
            pickupDuration = (firstLeg['duration'] as num?)?.toDouble();
          }
        }
      }

      if (!includePickupLeg) {
        pickupDistance ??= 0;
        pickupDuration ??= 0;
      }

      if (!mounted) return;

      setState(() {
        if (pickupDistance != null) {
          _driverPickupDistanceKm = pickupDistance / 1000.0;
        }
        if (pickupDuration != null) {
          _driverPickupEta = Duration(seconds: pickupDuration.round());
          _driverPickupArrivalTime = DateTime.now().add(_driverPickupEta!);
        }

        if (totalDistance != null) {
          _driverDestinationDistanceKm = totalDistance / 1000.0;
        }
        if (totalDuration != null) {
          _driverDestinationEta = Duration(seconds: totalDuration.round());
          _driverDestinationArrivalTime = DateTime.now().add(_driverDestinationEta!);
        }

        if (trafficSummary != null) {
          _driverTrafficSummary = trafficSummary;
        }
      });
    } catch (e) {
      Logger.error('Driver precise ETA calculation failed: $e', error: e);
    } finally {
      _driverIsFetchingEta = false;
    }
  }





  Future<void> _onRouteCalculated(Map<String, dynamic>? routeData) async {
    await _routeAnnotationManager?.deleteAll();
    await _altRouteAnnotationManager?.deleteAll();
    await _routeMarkersAnnotationManager?.deleteAll();
    await _pickupCircleManager?.deleteAll();
    await _destinationCircleManager?.deleteAll();
    
    if (routeData == null || !mounted) {
      setState(() {
        _currentRouteDistanceMeters = null;
        _currentRouteDurationSeconds = null;
        _isDestinationPreviewMode = false;
        _isDraggingPin = false;
      });
      Logger.debug('Route cleared in MapScreen');
      unawaited(_resetMapPinAfterRouteCleared());
      return;
    }
    // Rută confirmată — ieșim din modul preview; pinul rămâne pe hartă (util pentru navigare/favorite).
    _isDestinationPreviewMode = false;
    if (mounted) {
      unawaited(() async {
        if (_previewPinPoint != null) {
          await _updatePreviewPinScreenPos(_previewPinPoint!);
        }
        if (mounted) setState(() {});
      }());
    }
    
          try {
        // Ensure managers exist before drawing
        _routeAnnotationManager ??= await _mapboxMap?.annotations.createPolylineAnnotationManager(id: 'route-manager');
        _routeMarkersAnnotationManager ??= await _mapboxMap?.annotations.createPointAnnotationManager(id: 'route-markers-manager');
        _pickupCircleManager ??= await _mapboxMap?.annotations.createCircleAnnotationManager(id: 'pickup-circle-manager');
        _destinationCircleManager ??= await _mapboxMap?.annotations.createCircleAnnotationManager(id: 'destination-circle-manager');
        final routes = (routeData['routes'] as List?) ?? const [];
        if (routes.isEmpty) return;
        final route = routes[0];
        final geometry = route['geometry'] as Map<String, dynamic>;
        final meters = (route['distance'] as num?)?.toDouble();
        final seconds = (route['duration'] as num?)?.toDouble();
        if (meters != null && seconds != null) {
          if (mounted) {
            setState(() {
              _currentRouteDistanceMeters = meters;
              _currentRouteDurationSeconds = seconds;
            });
          }
        }

        // Pickup spot quality: distanța dintre punctul de preluare și primul punct al rutei
        try {
          if (_pickupLatitude != null && _pickupLongitude != null) {
            final coords = (geometry['coordinates'] as List<dynamic>);
            if (coords.isNotEmpty) {
              final first = coords.first as List<dynamic>;
              final firstLng = (first[0] as num).toDouble();
              final firstLat = (first[1] as num).toDouble();
              final d = _calculateDirectDistance(_pickupLatitude!, _pickupLongitude!, firstLat, firstLng);
              String label;
              Color color;
              if (d <= 10) {
                label = 'Excelent';
                color = Colors.green;
              } else if (d <= 25) {
                label = 'Bun';
                color = Colors.teal;
              } else if (d <= 50) {
                label = 'OK';
                color = Colors.amber.shade700;
              } else {
                label = 'Slab';
                color = Colors.redAccent;
              }
              if (mounted) {
                setState(() {
                  _pickupQualityLabel = label;
                  _pickupQualityColor = color;
                });
              }
            }
          } else {
            if (mounted) {
              setState(() {
                _pickupQualityLabel = null;
                _pickupQualityColor = null;
              });
            }
          }
        } catch (_) {}
        
        // ✅ CORECTAT: Creez obiect LineString pentru Mapbox (fără cast strict)
        final List<dynamic> coordinates = geometry['coordinates'] as List<dynamic>;
        final lineStringGeometry = LineString(
          coordinates: coordinates.map((coord) {
            final List<dynamic> c = coord as List<dynamic>;
            final double lng = (c[0] as num).toDouble();
            final double lat = (c[1] as num).toDouble();
            return Position(lng, lat);
          }).toList(),
        );
        
        // Delete previous active route if any (to avoid stacking)
        if (_activeRouteAnnotation != null) {
          try { await _routeAnnotationManager?.delete(_activeRouteAnnotation!); } catch (_) {}
          _activeRouteAnnotation = null;
        }

        // Base route line (solid blue)
        _activeRouteAnnotation = await _routeAnnotationManager?.create(
          PolylineAnnotationOptions(
            geometry: lineStringGeometry,
            lineColor: Colors.blue.toARGB32(),
            lineWidth: 6.0,
            lineOpacity: 1.0,
          ),
        );

        // Animated pulse overlay (slightly thicker, varying opacity)
        if (_routePulse != null) {
          final double currentOpacity = (_routePulse!.value).clamp(0.4, 1.0);
          await _routeAnnotationManager?.create(
            PolylineAnnotationOptions(
              geometry: lineStringGeometry,
              lineColor: Colors.blueAccent.toARGB32(),
              lineWidth: 7.0,
              lineOpacity: currentOpacity,
            ),
          );
        }

        // Desenează rutele alternative dacă există (faint)
        if (routes.length > 1) {
          // Ensure alt manager exists
          _altRouteAnnotationManager ??= await _mapboxMap?.annotations.createPolylineAnnotationManager(id: 'alt-route-manager');
          for (int i = 1; i < routes.length; i++) {
            final alt = routes[i] as Map<String, dynamic>;
            final g = (alt['geometry'] as Map<String, dynamic>);
            final coords = (g['coordinates'] as List<dynamic>).cast<List<dynamic>>();
            final altLine = LineString(
              coordinates: coords.map((c) => Position((c[0] as num).toDouble(), (c[1] as num).toDouble())).toList(),
            );
            await _altRouteAnnotationManager?.create(
              PolylineAnnotationOptions(
                geometry: altLine,
                lineColor: Colors.grey.shade500.toARGB32(),
                lineWidth: 4.0,
                lineOpacity: 0.4,
              ),
            );
          }
        }
      
      await _addRouteCircles(routeData);
      
      // ✅ Adaugă pin de destinație imediat după desenarea rutei
      try {
        final List<dynamic> endCoord = ((routeData['routes'][0]['geometry']['coordinates']) as List).last as List;
        await _addDestinationMarker(
          MapboxUtils.createPoint((endCoord[1] as num).toDouble(), (endCoord[0] as num).toDouble()),
          'Destinație',
        );
      } catch (_) {}
      
      // ✅ Ajustează camera astfel încât să fie vizibil întreg traseul
      try {
        final List<dynamic> coords = (geometry['coordinates'] as List<dynamic>);
        if (coords.isNotEmpty) {
          final List<double> lats = <double>[];
          final List<double> lngs = <double>[];
          for (final dynamic c in coords) {
            final List<dynamic> p = c as List<dynamic>;
            lngs.add((p[0] as num).toDouble());
            lats.add((p[1] as num).toDouble());
          }
          final southwest = MapboxUtils.createPoint(
            lats.reduce((a, b) => a < b ? a : b),
            lngs.reduce((a, b) => a < b ? a : b),
          );
          final northeast = MapboxUtils.createPoint(
            lats.reduce((a, b) => a > b ? a : b),
            lngs.reduce((a, b) => a > b ? a : b),
          );
          final bounds = CoordinateBounds(
            southwest: southwest,
            northeast: northeast,
            infiniteBounds: false,
          );
          final cameraOptions = await _mapboxMap?.cameraForCoordinateBounds(
            bounds,
            MbxEdgeInsets(
              top: 100.0,
              left: 50.0,
              bottom: 300.0, // spațiu pentru panoul cu opțiuni
              right: 50.0,
            ),
            0.0,
            0.0,
            null,
            null,
          );
          if (cameraOptions != null) {
            await _mapboxMap?.flyTo(cameraOptions, MapAnimationOptions(duration: 1200));
          }
        }
      } catch (e) {
        Logger.error('Failed to fit camera to route: $e', error: e);
      }
      
      Logger.debug('Route and circles displayed in MapScreen');
    } catch (e) {
      Logger.error('Error processing route geometry: $e', error: e);
      Logger.error('Route data structure: $routeData');
    }
  }

  Future<void> _addRouteCircles(Map<String, dynamic> routeData) async {
    if (_pickupCircleManager == null || _destinationCircleManager == null || !mounted) return;
    
    try {
      final route = routeData['routes'][0];
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      
      if (coordinates.isEmpty) return;
      
      final startCoord = coordinates.first as List<dynamic>;
      final endCoord = coordinates.last as List<dynamic>;
      
      final baseRadius = 12.0;
      final animatedRadius = _pickupPulse?.value != null ? baseRadius * _pickupPulse!.value : baseRadius;
      final pickupOptions = CircleAnnotationOptions(
        geometry: MapboxUtils.createPoint(startCoord[1], startCoord[0]),
        circleRadius: animatedRadius,
        circleColor: Colors.green.toARGB32(),
        circleStrokeWidth: 2,
        circleStrokeColor: Colors.white.toARGB32(),
      );
      
      final destinationOptions = CircleAnnotationOptions(
        geometry: MapboxUtils.createPoint(endCoord[1], endCoord[0]),
        circleRadius: 12,
        circleColor: Colors.red.toARGB32(),
        circleStrokeWidth: 2,
        circleStrokeColor: Colors.white.toARGB32(),
      );
      
      await _pickupCircleManager?.create(pickupOptions);
      await _destinationCircleManager?.create(destinationOptions);
      
      Logger.info('Route circles added successfully');
      
    } catch (e) {
      Logger.error('Error adding route circles: $e', error: e);
    }
  }

  void _resumeMapAfterRideFlow() {
    Logger.debug('Returned from active ride / pickup flow - resuming background processes');
    _shouldResetRoute = true;
    if (mounted && _isDriverAvailable && _currentRole == UserRole.driver) {
      _startDriverLocationUpdates();
    } else if (mounted) {
      _ensurePassiveLocationWarmupIfNeeded();
    }
    if (mounted) {
      _listenForNearbyDrivers();
      _resetRouteStateIfNeeded();
    }
  }

  /// Flux șofer: preluare (hartă înghețată în UI-ul de pickup), fără ActiveRideScreen.
  Future<void> _navigateDriverPickupWithRide(Ride ride) async {
    Logger.debug('Navigating to DriverRidePickupScreen - stopping background processes', tag: 'MAP');
    _stopLocationUpdates();
    _nearbyDriversSubscription?.cancel();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverRidePickupScreen(
          rideId: ride.id,
          ride: ride,
        ),
      ),
    );
    _resumeMapAfterRideFlow();
  }

  Future<void> _navigateDriverPickupByRideId(String rideId) async {
    _stopLocationUpdates();
    _nearbyDriversSubscription?.cancel();
    final ride = await _firestoreService.getRideById(rideId);
    if (!mounted) return;
    if (ride == null) {
      _resumeMapAfterRideFlow();
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverRidePickupScreen(
          rideId: ride.id,
          ride: ride,
        ),
      ),
    );
    _resumeMapAfterRideFlow();
  }

  void _navigateToActiveRideScreen(String rideId) {
    Logger.debug('Navigating to ride flow');
    if (_currentRole == UserRole.driver) {
      _stopLocationUpdates();
      _nearbyDriversSubscription?.cancel();
      unawaited(_navigateDriverPickupByRideId(rideId));
      return;
    }

    _beginPassengerRideSession(rideId);
  }

  @override
  Widget build(BuildContext context) {
    if (_verboseBuildLogs) {
      Logger.debug('DEBUG: MapScreen build() apelat');
      Logger.debug('DEBUG: _currentRole = $_currentRole');
      Logger.debug('DEBUG: _isDriverAvailable = $_isDriverAvailable');
      Logger.debug('DEBUG: ========== BUILD METHOD DEBUG ==========');
      Logger.debug('DEBUG: canShowVoiceAI = $canShowVoiceAI');
      if (canShowVoiceAI) {
        Logger.info('DEBUG:  canShowVoiceAI = true - va afișa AI button și overlay!');
      } else {
        Logger.error('DEBUG:  canShowVoiceAI = false - NU va afișa AI button și overlay!');
      }
      Logger.debug('DEBUG: ========== END BUILD METHOD DEBUG ==========');
    }
    
    final bool shouldShowPassengerUI = _currentRole == UserRole.passenger || 
                                       (_currentRole == UserRole.driver && !_isDriverAvailable);
    
    if (_verboseBuildLogs) {
      Logger.debug('DEBUG: shouldShowPassengerUI = $shouldShowPassengerUI');
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      drawer: AppDrawer(
        currentRole: _currentRole,
        onRoleChanged: _handleRoleChange,
        isVisibleToNeighbors: _isVisibleToNeighbors,
        onRefreshContacts: _refreshContacts,
        onAvatarChanged: ([
          CarAvatar? selected,
          CarAvatarMapSlot? editedSlot,
          Map<CarAvatarMapSlot, String>? appliedIdsBySlot,
        ]) {
          final activeSlot = _garageSlotForCurrentMode;
          String? optimistic;
          if (appliedIdsBySlot != null && appliedIdsBySlot.isNotEmpty) {
            optimistic = appliedIdsBySlot[activeSlot];
          } else if (selected != null && editedSlot == activeSlot) {
            optimistic = selected.id;
          }
          unawaited(_loadCustomCarAvatar(
            optimisticAvatarIdForActiveSlot: optimistic,
          ));
        },
        onToggleVisibility: () {
          Navigator.of(context).pop();
          _toggleVisibleToNeighbors();
        },
        onManageExclusions: () async {
          Navigator.of(context).pop();
          final result = await Navigator.push<Set<String>>(
            context,
            MaterialPageRoute(
              builder: (_) => VisibilityExclusionsScreen(
                contacts: _contactUsers,
                excludedUids: _excludedUids,
              ),
            ),
          );
          if (result != null && mounted) {
            setState(() => _excludedUids = result);
            await VisibilityPreferencesService().saveExcludedUids(result);
            // Re-publică locația cu noile excluderi dacă e vizibil
            if (_isVisibleToNeighbors) unawaited(_activateVisibility());
          }
        },
        onPlaceMapOrientationPin: () {
          setState(() => _awaitingMapOrientationPinPlacement = true);
          _showMapOrientationPlacementSnackBar(
            'Ține apăsat pe hartă la locul reperului tău (ex. zona „acasă”).',
          );
        },
        onEnableSavedHomePinOnMap: () => unawaited(_enableSavedHomePinFromDrawer()),
        onRemoveMapOrientationPin: () => unawaited(_removeMapOrientationPinFromMenu()),
      ),
      floatingActionButton: null,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
          Builder(
            builder: (context) {
              // Tema hărții se actualizează în [didChangeDependencies] prin loadStyleURI.
              // [listen: false] evită rebuild-uri doar din notifier; GPS nu modifică [cameraOptions] de aici.
              return Stack(
                children: [
                  MapWidget(
                    key: const ValueKey('nabour_mapbox_stable'),
                    onMapCreated: _onMapCreated,
                    onStyleLoadedListener: _onStyleLoaded,
                    onTapListener: (position) => _handleMapTap(MapboxUtils.contextToPoint(position)),
                    onLongTapListener: (position) => _handleMapLongPress(MapboxUtils.contextToPoint(position)),
                    onCameraChangeListener: _onCameraChanged,
                    onMapIdleListener: _onMapIdle,
                    cameraOptions: _mapWidgetCameraOptions,
                    styleUri: AppDrawer.lowDataMode
                        ? MapboxStyles.LIGHT
                        : (Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                            ? MapboxStyles.DARK
                            : MapboxStyles.MAPBOX_STREETS),
                  ),
                  if (_awaitingMapOrientationPinPlacement) ...[
                    Positioned(
                      top: 68,
                      left: 12,
                      right: 12,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.92),
                        elevation: 6,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.add_location_alt_rounded,
                                  color: Color(0xFF38BDF8), size: 24),
                              const SizedBox(width: 8),
                              const Icon(Icons.touch_app_rounded,
                                  color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Ține apăsat pe hartă pentru a fixa reperul.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  setState(() => _awaitingMapOrientationPinPlacement = false);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF38BDF8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  minimumSize: const ui.Size(0, 40),
                                ),
                                child: const Text('Renunță', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                                tooltip: 'Închide (anulează plasarea)',
                                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  setState(() => _awaitingMapOrientationPinPlacement = false);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Simbol reper pe hartă în timpul plasării (indicator de mod, nu poziție exactă).
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 120,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.65), width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.place_rounded,
                                    color: Colors.orange.shade300, size: 28),
                                const SizedBox(width: 10),
                                const Text(
                                  'Reper orientare',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  for (final s in _magicEventAuraSlots)
                    Positioned(
                      left: s.screenCenter.dx - s.widgetExtent / 2,
                      top: s.screenCenter.dy - s.widgetExtent / 2,
                      width: s.widgetExtent,
                      height: s.widgetExtent,
                      child: UltimateNabourAura(
                        radiusPx: s.radiusPx,
                        userDensity: s.userDensity,
                        rippleTick: s.rippleTick,
                        eventTitle: s.title.isEmpty ? null : s.title,
                        endsAt: s.endsAt,
                        theme: NabourAuraTheme.magic,
                        onTap: () {
                          if (s.event != null) {
                            _showMagicEventDetailSheet(s.event!);
                          }
                        },
                      ),
                    ),
                  
                  // SOS Radar: Aurele de siguranță roșii
                  for (final s in _emergencyAuraSlots)
                    Positioned(
                      left: s.screenCenter.dx - s.widgetExtent / 2,
                      top: s.screenCenter.dy - s.widgetExtent / 2,
                      width: s.widgetExtent,
                      height: s.widgetExtent,
                      child: UltimateNabourAura(
                        radiusPx: s.radiusPx,
                        userDensity: s.userDensity,
                        rippleTick: s.rippleTick,
                        eventTitle: '🆘 S.O.S. ACTIV',
                        endsAt: s.endsAt,
                        theme: NabourAuraTheme.safety,
                        onTap: () {
                          // Centrare pe locația de urgență folosind markerul original
                          final ann = _emergencyAnnotations[s.eventId];
                          if (ann != null && _mapboxMap != null) {
                            unawaited(_mapboxMap!.flyTo(
                              CameraOptions(center: ann.geometry, zoom: 16.0),
                              MapAnimationOptions(duration: 1000),
                            ));
                          }
                        },
                      ),
                    ),
                  // Strat atmosferic
                  WeatherOverlay(type: _weatherType),
                  if (_magicStarShowerVisible)
                    MagicEventStarShowerOverlay(
                      onComplete: () {
                        if (mounted) {
                          setState(() => _magicStarShowerVisible = false);
                        }
                      },
                    ),
                  if (_isRadarMode)
                    SpiderNetRadarSelector(
                      center: _radarCenter,
                      radius: _radarRadius,
                      mapboxMap: _mapboxMap,
                      onUpdate: (center, radius) {
                        setState(() {
                          _radarCenter = center;
                          _radarRadius = radius;
                        });
                      },
                      onConfirm: _onRadarConfirmed,
                    ),
                  if (_useAndroidFlutterUserMarkerOverlay &&
                      _androidHomePinOverlayPx != null &&
                      _androidHomePinOverlayBytes != null)
                    Positioned(
                      left: _androidHomePinOverlayPx!.dx -
                          _androidHomePinOverlayWidth / 2,
                      top: _androidHomePinOverlayPx!.dy -
                          _androidHomePinOverlayHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (mounted) _showMapOrientationPinActions();
                        },
                        child: SizedBox(
                          width: _androidHomePinOverlayWidth,
                          height: _androidHomePinOverlayHeight,
                          child: Image.memory(
                            _androidHomePinOverlayBytes!,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                    ),
                  if (_useAndroidFlutterUserMarkerOverlay &&
                      _androidUserMarkerOverlayPx != null &&
                      _androidUserMarkerOverlayImageBytes != null)
                    Positioned(
                      left: _androidUserMarkerOverlayPx!.dx -
                          _androidUserMarkerOverlaySize / 2,
                      top: _androidUserMarkerOverlayPx!.dy -
                          _androidUserMarkerOverlaySize / 2,
                      child: IgnorePointer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: _androidUserMarkerOverlaySize,
                              height: _androidUserMarkerOverlaySize,
                              child: Transform.rotate(
                                angle: _androidUserMarkerOverlayHeadingDeg *
                                    math.pi /
                                    180,
                                filterQuality: FilterQuality.medium,
                                child: Image.memory(
                                  _androidUserMarkerOverlayImageBytes!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                  filterQuality: FilterQuality.medium,
                                ),
                              ),
                            ),
                            if (_androidUserMarkerOverlayLabel != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _androidUserMarkerOverlayLabel!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A237E),
                                    height: 1.05,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.white,
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
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
          
          // 📍 STRADA + scară — margini aliniate cu hamburger+POI stânga / AI+profil dreapta
          Positioned(
            top: 68,
            left: 132,
            right: 120,
            child: Center(
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  // Aliniat cu MapWidget [styleUri]: întunecată doar când userul a ales tema întunecată.
                  final mapAppearsDark =
                      !AppDrawer.lowDataMode && themeProvider.isDarkMode;
                  const turquoiseStreet = Color(0xFF22D3EE);
                  final streetStyle = mapAppearsDark
                      ? TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: turquoiseStreet,
                          letterSpacing: -0.5,
                          shadows: const [
                            Shadow(color: Color(0xFF0EA5E9), blurRadius: 12),
                            Shadow(color: Color(0xFF0891B2), blurRadius: 22),
                            Shadow(color: Color(0x6622D3EE), blurRadius: 28),
                          ],
                        )
                      : const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        );
                  final subStyle = TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color:
                        mapAppearsDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_currentStreetName.isNotEmpty)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _currentStreetName.toUpperCase(),
                            style: streetStyle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_scaleBarText, style: subStyle),
                          if (_weatherTemp != null) ...[
                            const SizedBox(width: 8),
                            Text('${_weatherTemp!.round()}°C', style: subStyle),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          if (_magicEventsUserInside.isNotEmpty)
            Positioned(
              top: 108,
              left: 12,
              right: 12,
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFF3E8FF),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.amber.shade800),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _magicEventsUserInside
                              .map(
                                (e) =>
                                    '${e.title}: ${e.participantCount} vecini aici',
                              )
                              .join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF5B21B6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ☰ HAMBURGER + POI (stânga sus) — configurate unitar cu estetică Premium
          Positioned(
            top: 28,
            left: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (scaffoldCtx) => GestureDetector(
                    onTap: () => Scaffold.of(scaffoldCtx).openDrawer(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showPoiCategorySheet,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3), width: 1),
                    ),
                    child: const Icon(Icons.place_rounded, color: Color(0xFF0EA5E9), size: 24),
                  ),
                ),
              ],
            ),
          ),

          // 🎤 Asistent vocal + 👤 PROFIL (dreapta sus) — apoi restul coloanei Bump
          Positioned(
            top: 28,
            right: 16,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Reîmprospătează harta',
                        child: GestureDetector(
                          onTap: () => unawaited(_softRefreshMapDisplay()),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (canShowVoiceAI)
                        Consumer2<FriendsRideVoiceIntegration, AssistantStatusProvider>(
                          builder: (ctx, voiceIntegration, statusProvider, _) {
                            return _buildAiGlassButton(
                              processingState: voiceIntegration.currentContext.processingState,
                              isDark: Theme.of(context).brightness == Brightness.dark,
                              onTap: () async {
                                statusProvider.setStatus(AssistantWorkStatus.working);
                                try {
                                  await voiceIntegration.startVoiceInteraction();
                                } catch (e) {
                                  statusProvider.setStatus(AssistantWorkStatus.idle);
                                }
                              },
                            );
                          },
                        ),
                      if (canShowVoiceAI) const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                        ),
                        child: Builder(
                          builder: (context) {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null) {
                              return Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                                ),
                                child: const Center(
                                  child: Text('👤', style: TextStyle(fontSize: 24)),
                                ),
                              );
                            }
                            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .snapshots(),
                              builder: (context, snap) {
                                final data = snap.data?.data();
                                final photoURL = data?['photoURL'] as String?;
                                final hasPhoto = photoURL != null && photoURL.isNotEmpty;
                                final avatar = data?['avatar'] as String? ?? '👤';

                                if (hasPhoto) {
                                  return Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        photoURL,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.white,
                                          child: Center(child: Text(avatar, style: const TextStyle(fontSize: 24))),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                                  ),
                                  child: Center(
                                    child: Text(avatar, style: const TextStyle(fontSize: 24)),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Pulse/Flashlight
                  _buildBumpFloatingButton(
                    icon: _flashlightOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                    color: _flashlightOn ? Colors.amber : Colors.black,
                    onTap: _toggleFlashlight,
                  ),
                  // Radar / Spider Net Button
                  _buildBumpFloatingButton(
                    icon: _isRadarMode ? Icons.radar : Icons.satellite_alt_rounded,
                    color: _isRadarMode ? const Color(0xFF7C3AED) : Colors.black,
                    onTap: () async {
                      if (!_isRadarMode && _mapboxMap != null) {
                        // Centru pe GPS-ul tău, nu pe centrul camerei: altfel la hartă mutată
                        // un prieten la ~50 m poate cădea în afara cercului deși e aproape de tine.
                        final p = _currentPositionObject;
                        if (p != null) {
                          _radarCenter = MapboxUtils.createPoint(
                            p.latitude,
                            p.longitude,
                          );
                        } else {
                          final cam = await _mapboxMap!.getCameraState();
                          _radarCenter = cam.center;
                        }
                      }
                      setState(() {
                         _isRadarMode = !_isRadarMode;
                      });
                      if (_isRadarMode) {
                        _showSafeSnackBar(
                          'RADAR: plasa e ancorată pe locația ta. Mărește cercul dacă e nevoie.',
                          const Color(0xFF7C3AED),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Post Moment
                  _buildBumpFloatingButton(
                    icon: Icons.add_a_photo_outlined,
                    onTap: _showPostMomentSheet,
                  ),
                  const SizedBox(height: 12),
                  // GPS
                  _buildBumpFloatingButton(
                    icon: Icons.my_location,
                    onTap: () => _getCurrentLocation(centerCamera: true),
                  ),
                  const SizedBox(height: 12),
                  // Trimite link (distinct de „locația mea” pe hartă)
                  _buildBumpFloatingButton(
                    icon: Icons.ios_share_rounded,
                    onTap: _shareCurrentLocation,
                  ),
                  if (_showParkingYieldMapButton) ...[
                    const SizedBox(height: 12),
                    _buildBumpFloatingButton(
                      icon: Icons.local_parking_rounded,
                      color: Colors.black,
                      bgColor: Colors.amber,
                      onTap: _handleLeavingParking,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Emoji pe hartă — sub Share, aceeași coloană dreapta
                  Builder(
                    builder: (context) {
                      final myUid = FirebaseAuth.instance.currentUser?.uid;
                      final hasMine = _hasMyMapEmojiPlaced(myUid);
                      final screenW = MediaQuery.sizeOf(context).width;
                      final panelMaxW = (screenW - 48).clamp(220.0, 288.0);
                      final gridMaxH = (MediaQuery.sizeOf(context).height * 0.32).clamp(140.0, 210.0);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_showEmojiPicker && hasMine)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  onTap: _removeMyMapEmoji,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.layers_clear_rounded, color: Colors.red.shade200, size: 18),
                                        const SizedBox(width: 8),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(maxWidth: panelMaxW - 56),
                                          child: Text(
                                            'Scoate emoji',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.95),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (_showEmojiPicker)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                              width: panelMaxW,
                              constraints: BoxConstraints(
                                maxWidth: panelMaxW,
                                maxHeight: math.min(280, MediaQuery.sizeOf(context).height * 0.42),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: gridMaxH),
                                    child: SingleChildScrollView(
                                      child: Wrap(
                                        alignment: WrapAlignment.end,
                                        spacing: 2,
                                        runSpacing: 4,
                                        children: _kMapReactionEmojis.map((e) {
                                          return Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () async {
                                                if (_currentPositionObject == null) return;
                                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                                if (uid == null || uid.isEmpty) {
                                                  if (mounted) {
                                                    _showSafeSnackBar(
                                                      'Autentifică-te ca să plasezi emoji pe hartă',
                                                      const Color(0xFFB71C1C),
                                                    );
                                                  }
                                                  return;
                                                }
                                                try {
                                                  final chosen = normalizeMapEmojiForEngine(e);
                                                  final docId = await MapEmojiService().addEmoji(
                                                    lat: _currentPositionObject!.latitude,
                                                    lng: _currentPositionObject!.longitude,
                                                    emoji: chosen,
                                                    senderId: uid,
                                                  );
                                                  if (!mounted) return;
                                                  HapticFeedback.lightImpact();
                                                  if (docId != null) {
                                                    final optimistic = MapEmoji(
                                                      id: docId,
                                                      lat: _currentPositionObject!.latitude,
                                                      lng: _currentPositionObject!.longitude,
                                                      emoji: chosen,
                                                      timestamp: DateTime.now(),
                                                      senderId: uid,
                                                    );
                                                    setState(() {
                                                      _lastReceivedEmojis = [
                                                        ..._lastReceivedEmojis.where((x) => x.id != docId),
                                                        optimistic,
                                                      ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
                                                      _showEmojiPicker = false;
                                                    });
                                                    unawaited(_updateEmojiMarkers(_lastReceivedEmojis));
                                                  } else {
                                                    setState(() => _showEmojiPicker = false);
                                                  }
                                                } catch (err) {
                                                  if (mounted) {
                                                    _showSafeSnackBar(
                                                      'Nu am putut salva emoji-ul. Verifică conexiunea sau regulile Firebase.',
                                                      const Color(0xFFB71C1C),
                                                    );
                                                  }
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(10),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                child: Text(e, style: const TextStyle(fontSize: 26)),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  if (hasMine) ...[
                                    Divider(color: Colors.white.withValues(alpha: 0.2), height: 16),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                        alignment: Alignment.centerLeft,
                                      ),
                                      onPressed: _removeMyMapEmoji,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.delete_outline_rounded,
                                              color: Colors.red.shade200, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Șterge emoji-ul meu de pe hartă',
                                              style: TextStyle(
                                                color: Colors.red.shade100,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              maxLines: 3,
                                              softWrap: true,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          FloatingActionButton(
                            mini: true,
                            heroTag: 'emoji_picker_fab',
                            backgroundColor: _showEmojiPicker ? Colors.pink : Colors.white,
                            onPressed: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
                            child: Icon(
                              _showEmojiPicker ? Icons.close : Icons.face_retouching_natural_rounded,
                              color: _showEmojiPicker ? Colors.white : Colors.pink,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
          ),

          if (shouldShowPassengerUI) ...[
            // Sugestii inteligente — future memorat în initState (nu re-citire la fiecare frame).
            FutureBuilder<List<SmartSuggestion>>(
              future: _smartSuggestionsFuture,
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return SmartSuggestionsRow(
                  suggestions: snap.data!,
                  onSuggestionTap: (suggestion) {
                    _ensureRidePanelVisibleForExternalAction(() {
                      _rideRequestPanelKey.currentState?.setDestination(
                        address: suggestion.address,
                        latitude: suggestion.latitude,
                        longitude: suggestion.longitude,
                      );
                    });
                    unawaited(SmartSuggestionsService()
                        .recordDestinationUsed(suggestion));
                    if (mounted) {
                      setState(() {
                        _smartSuggestionsFuture =
                            SmartSuggestionsService().getSuggestions();
                      });
                    }
                  },
                );
              },
            ),
            if (_currentPositionObject != null) ...[
              if (_rideAddressSheetVisible || _inAppNavActive)
                RideRequestPanel(
                  key: _rideRequestPanelKey,
                  draggableController: _rideSheetController,
                  startPosition: _currentPositionObject!,
                  onRouteCalculated: _onRouteCalculated,
                  onDestinationPreview: _onDestinationPreview,
                  onStartNavigation: (pt, addr) => unawaited(_startInAppNavigation(pt.coordinates.lat.toDouble(), pt.coordinates.lng.toDouble(), addr)),
                  isNavigating: _inAppNavActive,
                  onClose: _closeRideAddressSheet,
                ),
            ] else
              const Center(child: CircularProgressIndicator()),
          ]
          else if (_currentRole == UserRole.driver && _isDriverAvailable)
            MapDriverInterface(
              firestoreService: _firestoreService,
              currentActiveRide: _currentActiveRide,
              driverPickupEta: _driverPickupEta,
              driverPickupDistanceKm: _driverPickupDistanceKm,
              driverPickupArrivalTime: _driverPickupArrivalTime,
              driverDestinationEta: _driverDestinationEta,
              driverDestinationDistanceKm: _driverDestinationDistanceKm,
              driverDestinationArrivalTime: _driverDestinationArrivalTime,
              driverTrafficSummary: _driverTrafficSummary,
              driverCategoryName: _driverCategory?.name,
              pendingRidesCount: _pendingRides.length,
              onNewRideAssigned: (ride) => unawaited(_playRideOfferSoundRobust()),
              onNavigateToRide: _navigateToActiveRideScreen,
              onListenForChat: _listenForChatMessages,
              onUpdateEstimates: _currentPositionObject != null
                  ? () => _updateDriverRideEstimates(_currentPositionObject!)
                  : null,
              onResetEtaMetrics: _resetDriverEtaMetrics,
              onActiveRideChanged: (ride) {
                _currentActiveRide = ride;
              },
            ),

          // ✅ Uber-like: oferta (pentru driver) apare ca bottom sheet, nu ca overlay sus.
          if (_currentRole == UserRole.driver && _isDriverAvailable)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _currentRideOffer != null
                  ? MapDriverRideOfferBottomSheet(
                      key: ValueKey<String>(_currentRideOffer!.id),
                      ride: _currentRideOffer!,
                      remainingSeconds: _remainingSeconds,
                      isProcessingAccept: _isProcessingAccept,
                      isProcessingDecline: _isProcessingDecline,
                      onAccept: () => _acceptRide(_currentRideOffer!),
                      onDecline: () => _declineRide(_currentRideOffer!),
                    )
                  : const SizedBox.shrink(),
            ),

          
          // NOU: Card informativ pentru POI-uri - Draggable Overlay (bounded, non-blocking)
          if (_showPoiCard && _selectedPoi != null)
            AnimatedPositioned(
              left: _poiCardPosition.dx,
              top: _poiCardPosition.dy,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: Builder(
                builder: (context) {
                  final screenSize = MediaQuery.of(context).size;
                  const double cardWidth = 340.0;
                  const double horizontalPadding = 8.0;
                  const double verticalPadding = 8.0;

                  return AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: 1.0,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final DateTime now = DateTime.now();
                        if (now.difference(_lastPoiCardPanUpdate).inMilliseconds < _poiCardPanThrottleMs) {
                          return;
                        }
                        _lastPoiCardPanUpdate = now;
                        setState(() {
                          final double maxX = screenSize.width - cardWidth - horizontalPadding;
                          final double maxY = screenSize.height - 200.0; // keep inside viewport
                          double newX = _poiCardPosition.dx + details.delta.dx;
                          double newY = _poiCardPosition.dy + details.delta.dy;
                          newX = newX.clamp(horizontalPadding, maxX);
                          newY = newY.clamp(verticalPadding, maxY);
                          _poiCardPosition = Offset(newX, newY);
                        });
                      },
                      child: SizedBox(
                        width: cardWidth,
                        child: MapPoiCard(
                          poi: _selectedPoi!,
                          onClose: _closePoiCard,
                          onSetAsPickup: () => _setPOIAsPickup(_selectedPoi!),
                          onSetAsDestination: () => _setPOIAsDestination(_selectedPoi!),
                          onAddAsStop: () => _addPOIAsStop(_selectedPoi!),
                          onAddAsFavorite: () => _onPoiAddFavorite(_selectedPoi!),
                          onNavigateHere: () => _onPoiNavigateHere(_selectedPoi!),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          

          
          // ✅ CONECTARE 1: Intermediate stops list
          if (_intermediateStops.isNotEmpty)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: MapIntermediateStops(
                stops: _intermediateStops,
                onRemoveStop: _removeStop,
              ),
            ),
          
          // Camera control buttons moved to AppBar

          // ✅ Alt routes toggle & preview card + ETA/distance preview pentru ruta curentă
          if (_alternativeRoutes.isNotEmpty)
            Positioned(
              bottom: 90 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentRouteDistanceMeters != null && _currentRouteDurationSeconds != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.directions, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_routingService.formatDuration(_currentRouteDurationSeconds!)} • ${_routingService.formatDistance(_currentRouteDistanceMeters!)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_pickupQualityLabel != null && _pickupQualityColor != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _pickupQualityColor!.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _pickupQualityColor!.withValues(alpha: 0.6)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.flag_rounded, size: 14, color: _pickupQualityColor),
                                        const SizedBox(width: 6),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 96),
                                          child: Text(
                                            _pickupQualityLabel!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontWeight: FontWeight.w600, color: _pickupQualityColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          const Text('Rute alternative', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_isFetchingAlternatives) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_alternativeRoutes.length, (i) {
                            final r = _alternativeRoutes[i];
                            final meters = (r['distance'] as num?)?.toDouble() ?? 0.0;
                            final seconds = (r['duration'] as num?)?.toDouble() ?? 0.0;
                            final dist = _routingService.formatDistance(meters);
                            final eta = _routingService.formatDuration(seconds);
                            final selected = i == _selectedAltRouteIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text('$eta • $dist'),
                                selected: selected,
                                onSelected: (val) async {
                                  setState(() { _selectedAltRouteIndex = i; });
                                  // Re-desenăm ruta: selectata ca principală + celelalte faint
                                  final reordered = <Map<String, dynamic>>[r, ..._alternativeRoutes.where((e) => !identical(e, r)).cast<Map<String, dynamic>>()];
                                  await _onRouteCalculated({'routes': reordered});
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_alternativeRoutes.isNotEmpty && !_tipAltRoutesSeen)
            Positioned(
              bottom: 160 + MediaQuery.of(context).padding.bottom,
              left: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    setState(() { _tipAltRoutesSeen = true; });
                    try { final prefs = await SharedPreferences.getInstance(); await prefs.setBool('tip_alt_routes_seen', true); } catch (_) {}
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Tip: alege ruta alternativă cea mai rapidă.', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ),
            ),

          // ✅ Pickup suggestions chips
          if (_showPickupSuggestions && _pickupSuggestionPoints.isNotEmpty)
            Positioned(
              bottom: 150 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8,
                    children: List.generate(_pickupSuggestionPoints.length, (i) {
                      return ActionChip(
                        avatar: const Icon(Icons.trip_origin, size: 18),
                        label: Text('Pickup ${i + 1}'),
                        onPressed: () {
                          final pt = _pickupSuggestionPoints[i];
                          setState(() {
                            _pickupLatitude = pt.coordinates.lat.toDouble();
                            _pickupLongitude = pt.coordinates.lng.toDouble();
                            _showPickupSuggestions = false;
                          });
                          _updateMapWithNewPickup();
                          _showSafeSnackBar('Punct de preluare selectat', Colors.blue);
                        },
                      );
                    }),
                  ),
                ),
              ),
            ),
          
          // ✅ CONECTARE 2: Ride info panel
          if ((_pickupLatitude != null || _destinationLatitude != null) && !shouldShowPassengerUI)
            Positioned(
              bottom: 200 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: MapRideInfoPanel(
                pickupLatitude: _pickupLatitude,
                destinationLatitude: _destinationLatitude,
                pickupText: _pickupController.text,
                destinationText: _destinationController.text,
                stopsCount: _intermediateStops.length,
                onClearPickup: _clearPickup,
                onClearDestination: _clearDestination,
                onStartRide: _startRideRequest,
              ),
            ),

          if (_currentRole == UserRole.passenger && _passengerSessionRide != null)
            Positioned(
              bottom: 200 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: _buildPassengerRideSessionOverlay(),
            ),
          
          
          // 📍 Pin roșu: long-press pe hartă (sau preview destinație); tap pe pin → navigare / favorite.
          if (_previewPinScreenPos != null)
            Positioned(
              // Ținta de atingere mai mare decât icon-ul — mai ușor de deschis navigarea.
              left: _previewPinScreenPos!.dx - 44,
              top: _previewPinScreenPos!.dy - 72,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _previewPinPoint == null
                    ? null
                    : () {
                        final p = _previewPinPoint!;
                        unawaited(_showMapTapLocationSheet(p));
                      },
                onPanUpdate: _onPinDragUpdate,
                onPanEnd: _onPinDragEnd,
                child: SizedBox(
                  width: 88,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Icon(
                          Icons.location_pin,
                          size: 64,
                          color: Color(0xFFEF4444),
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 14,
                        child: Icon(
                          _isDraggingPin ? Icons.open_with : Icons.drag_indicator,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Navigare internă Mapbox (Text Header minimal sub POI-uri pe o singură linie) ──
          if (_inAppNavActive)
            Positioned(
              top: 104, // Sub chips-urile de POI (body sub SafeArea)
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => unawaited(_stopInAppNavigation()), // Atinge pentru a opri navigarea
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                    border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.navigation_rounded, color: Color(0xFF00E676), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _navCurrentInstruction.isEmpty ? "Navigare activă" : _navCurrentInstruction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_navRemainDistanceM > 0 || _navRemainEta.inSeconds > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${_navRemainDistanceM > 0 ? (_navRemainDistanceM > 1000 ? "${(_navRemainDistanceM / 1000).toStringAsFixed(1)} km" : "${_navRemainDistanceM.toStringAsFixed(0)} m") : ""} ${_navRemainEta.inSeconds > 0 ? "• ${_navRemainEta.inMinutes} min" : ""}'.trim(),
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),

          // 🎤 VOICE OVERLAY - Afișat când voice interaction este activ
          Consumer2<FriendsRideVoiceIntegration, AssistantStatusProvider>(
            builder: (context, voiceIntegration, statusProvider, child) {
              // ✅ NOU: Actualizează statusul asistentului bazat pe starea voice interaction
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (voiceIntegration.isVoiceActive) {
                  statusProvider.setStatus(AssistantWorkStatus.working);
                } else {
                  statusProvider.setStatus(AssistantWorkStatus.idle);
                }
              });
              
              if (!voiceIntegration.isVoiceActive) return const SizedBox.shrink();
              
              return MapVoiceOverlay(
                voiceIntegration: voiceIntegration,
                // 🎙️ Butonul microfon din card pornește direct vocea
                onStartVoice: () async {
                  statusProvider.setStatus(AssistantWorkStatus.working);
                  try {
                    await voiceIntegration.startVoiceInteraction();
                  } catch (e) {
                    statusProvider.setStatus(AssistantWorkStatus.idle);
                  }
                },
              );
            },
          ),
          
          // ✅ NOU: Assistant Status Overlay - Indicator mic în colțul din dreapta sus
          const AssistantStatusOverlay(),

          // Banner offline — apare sub AppBar când nu există conexiune
          Consumer<ConnectivityService>(
            builder: (context, connectivity, _) {
              if (connectivity.isOnline) return const SizedBox.shrink();
              return Positioned(
                top: kToolbarHeight,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    color: const Color(0xFFB71C1C),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 15),
                        SizedBox(width: 8),
                        Text(
                          'Fără internet — unele funcții nu sunt disponibile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 🏠 Chat de cartier + Cereri de cartier — colțul dreapta jos
          // ── BOTTOM BAR CENTRAL (3 butoane, stil Bump) ─────────────────
          BumpBottomBar(
            leftIcon: _isVisibleToNeighbors
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            centerIcon: Icons.people_alt_rounded,
            rightIcon: Icons.notifications_rounded,
            badge: _pendingIncomingFriendRequestCount > 0
                ? _pendingIncomingFriendRequestCount
                : null,
            onLeft: _toggleVisibleToNeighbors,
            onCenter: _openFriendSuggestions,
            onRight: _openActivityNotifications,
            onItinerary: shouldShowPassengerUI ? _onItineraryButtonPressed : null,
          ),

          // Căutare (lupă) — stânga jos, aceeași înălțime ca bara centrală
          Positioned(
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            left: 14,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _universalSearchOpen = true),
                child: Ink(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: const Icon(Icons.search_rounded,
                      color: Colors.black87, size: 26),
                ),
              ),
            ),
          ),

          // ── Cerere FAB (above quick actions row) ─────────────────────
          if (_isVisibleToNeighbors && _showCerereButton)
            Positioned(
              bottom: 150 + MediaQuery.of(context).padding.bottom,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'cerere_fab',
                    onPressed: () {
                      if (_currentPositionObject != null) {
                        NeighborhoodRequestsManager.showCreateRequestSheet(
                          context,
                          _currentPositionObject!.latitude,
                          _currentPositionObject!.longitude,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Așteptăm localizarea GPS...')),
                        );
                      }
                    },
                    backgroundColor: Colors.indigo,
                    icon: const Icon(Icons.add_location_alt, color: Colors.white),
                    label: const Text('Cerere', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: FloatingActionButton(
                      heroTag: 'cerere_close',
                      mini: true,
                      backgroundColor: Colors.white,
                      elevation: 2,
                      onPressed: () => setState(() => _showCerereButton = false),
                      child: const Icon(Icons.close, size: 18, color: Colors.indigo),
                    ),
                  ),
                ],
              ),
            ),

          // ── Quick actions row (above bottom bar) ─────────────────────
          Positioned(
            bottom: 90 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                _buildMiniAction(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Review',
                  color: const Color(0xFFFF007F),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WeekReviewScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                _buildMiniAction(
                  icon: Icons.campaign_rounded,
                  label: 'Cereri',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RideBroadcastFeedScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                _buildMiniAction(
                  icon: Icons.forum_rounded,
                  label: 'Chat',
                  color: const Color(0xFF7C3AED),
                  onTap: () async {
                    final result = await Navigator.of(context).push<dynamic>(
                      MaterialPageRoute(builder: (_) => const NeighborhoodChatScreen()),
                    );
                    if (result != null && result is Map && result['action'] == 'flyTo' && mounted) {
                      final lat = (result['lat'] as num).toDouble();
                      final lng = (result['lng'] as num).toDouble();
                      await _mapboxMap?.flyTo(
                        CameraOptions(
                          center: Point(coordinates: Position(lng, lat)),
                          zoom: 16.5,
                          pitch: 45,
                        ),
                        MapAnimationOptions(duration: 2000),
                      );
                      unawaited(_requestsManager?.showTransientLocationPin(lat, lng));
                    }
                  },
                ),
                const SizedBox(width: 12),
                _buildMiniAction(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Cutie',
                  color: const Color(0xFF0D9488),
                  onTap: _placeCommunityMysteryBoxFlow,
                ),
                if (_activeMoments.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  _buildMiniAction(
                    icon: Icons.auto_stories_rounded,
                    label: '${_activeMoments.length}',
                    color: const Color(0xFFE040FB),
                    onTap: () {
                      final m = _activeMoments.first;
                      _showMapActivityToast(
                        m.authorAvatar,
                        m.authorName,
                        m.caption,
                      );
                    },
                  ),
                ],
                  ],
                ),
              ),
            ),
          ),

          if (_isVisibleToNeighbors && !_neighborActivityFeedDismissed)
            Positioned.fill(
              child: NeighborActivityFeedPanel(
                onClose: () {
                  if (mounted) {
                    setState(() => _neighborActivityFeedDismissed = true);
                  }
                },
              ),
            ),

          if (_universalSearchOpen)
            Positioned.fill(
              child: MapUniversalSearchOverlay(
                onClose: () {
                  if (mounted) setState(() => _universalSearchOpen = false);
                },
                contacts: _contactUsers,
                friendPeerUids: _friendPeerUids,
                visibleNeighbors: _neighborData.values.toList(),
                neighborEmojiByUid: Map<String, String>.from(_neighborAvatarCache),
                neighborPhotoUrlByUid:
                    Map<String, String>.from(_neighborPhotoURLCache),
                userPosition: _currentPositionObject,
                onPlaceChosen: _onUniversalSearchPlace,
                onContactChosen: _onUniversalSearchContact,
                onAddFriend: _sendFriendRequestFromSearch,
              ),
            ),

          MapVoiceOverlay(controller: _voiceController),

          ],
        ),
      ),
    );
  }

  double _calculateDirectDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // metri
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }


  // REMOVED: _clearExistingPois was unused after switching to SymbolLayer-based rendering.

  // REMOVED: _getCategoryColor was only used by the old PointAnnotation rendering path.

  /// Lățimea vizibilă pe ecran la zoom/latitudine (Web Mercator) — aceeași logică ca la scale bar nativ.
  String _formatVisibleMapWidthLabel(double latDeg, double zoom, double widthPx) {
    if (widthPx <= 0 || zoom.isNaN) return _scaleBarText;
    final mpp =
        156543.03392 * math.cos(latDeg.clamp(-85.0, 85.0) * math.pi / 180) / math.pow(2.0, zoom);
    final visibleM = mpp * widthPx;
    if (visibleM < 250) {
      return '${visibleM.round()} m';
    }
    if (visibleM < 950) {
      return '${(visibleM / 1000).toStringAsFixed(2)} km';
    }
    if (visibleM < 9950) {
      return '${(visibleM / 1000).toStringAsFixed(1)} km';
    }
    return '${(visibleM / 1000).round()} km';
  }

  void _onCameraChanged(CameraChangedEventData data) {
    if (!mounted) return;
    final lat = data.cameraState.center.coordinates.lat.toDouble();
    final zoom = data.cameraState.zoom;
    final w = MediaQuery.sizeOf(context).width;
    final next = _formatVisibleMapWidthLabel(lat, zoom, w);
    if (next != _scaleBarText) {
      setState(() => _scaleBarText = next);
    }
    _auraProjectDebounce?.cancel();
    _auraProjectDebounce = Timer(const Duration(milliseconds: 56), () {
      if (mounted) {
        unawaited(_projectMagicEventAuraSlots());
        unawaited(_projectEmergencyAuraSlots());
        unawaited(_projectAndroidUserMarkerOverlay());
        unawaited(_projectAndroidHomePinOverlay());
      }
    });
  }

  // Called when camera stops moving; acum declanșăm POI-urile locale (safe, no traffic)
  void _onMapIdle(MapIdleEventData data) {
    // Afișează chip "Caută Ã®n această zonă" doar dacă deplasarea e semnificativă
    _updateSearchAreaChipVisibility();
    // Protecție panning: împiedicăm request-uri masive de tile-uri
    unawaited(_maybeClampCameraToPanningRadius());
    
    // Recalculează poziția pe ecran a pinului după ce harta se oprește din mișcare
    if (_previewPinPoint != null) {
      unawaited(_updatePreviewPinScreenPos(_previewPinPoint!));
    }
    unawaited(_projectAndroidUserMarkerOverlay());
    unawaited(_projectAndroidHomePinOverlay());
    // Update street name overlay (Bump style)
    unawaited(_updateCurrentStreetName());
    // Track zoom for slider
    unawaited(_syncZoomLevel());
    unawaited(_projectMagicEventAuraSlots());
  }

  Future<void> _syncZoomLevel() async {
    if (_mapboxMap == null) return;
    try {
      final cam = await _mapboxMap!.getCameraState();
      final z = cam.zoom.toDouble();
      if ((z - _mapZoomLevel).abs() > 0.3 && mounted) {
        setState(() => _mapZoomLevel = z);
      }
    } catch (_) {}
  }

  Future<void> _updateCurrentStreetName({bool throttle = false}) async {
    if (!mounted) return;
    if (throttle && _lastStreetNameUpdate != null) {
      final elapsed = DateTime.now().difference(_lastStreetNameUpdate!);
      if (elapsed.inSeconds < 20) return;
    }
    try {
      double lat;
      double lng;
      if (_currentPositionObject != null) {
        lat = _currentPositionObject!.latitude;
        lng = _currentPositionObject!.longitude;
      } else if (_mapboxMap != null) {
        final cam = await _mapboxMap!.getCameraState();
        lat = cam.center.coordinates.lat.toDouble();
        lng = cam.center.coordinates.lng.toDouble();
      } else {
        return;
      }
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      _lastStreetNameUpdate = DateTime.now();
      if (placemarks.isNotEmpty && mounted) {
        final street = placemarks.first.street ?? '';
        if (street != _currentStreetName) {
          setState(() {
            _currentStreetName = street;
          });
        }
      }
    } catch (_) {}
  }

  /// Dacă userul a panning-uit prea mult față de locația curentă, readuce camera
  /// înapoi într-o zonă aproximativă (bounding box) de tip hard radius.
  ///
  /// Dezactivează snap-back în modul preview destinație / când pinul e folosit activ ca să nu te lupți cu
  /// animarea / drag-ul pinului.
  Future<void> _maybeClampCameraToPanningRadius() async {
    if (!mounted || _mapboxMap == null) return;
    if (_isPanClamping) return;
    if (_isDestinationPreviewMode) return;
    if (_previewPinPoint != null) return;
    if (_currentPositionObject == null) return;

    final now = DateTime.now();
    if (now.difference(_lastPanClampAt) < _panClampMinGap) return;

    try {
      final cam = await _mapboxMap!.getCameraState();
      final center = cam.center;
      final centerLat = center.coordinates.lat.toDouble();
      final centerLng = center.coordinates.lng.toDouble();

      final myLat = _currentPositionObject!.latitude;
      final myLng = _currentPositionObject!.longitude;

      final movedMeters = MapboxUtils.calculateDistance(
        MapboxUtils.createPoint(myLat, myLng),
        MapboxUtils.createPoint(centerLat, centerLng),
      );

      final hardMeters = (_panningHardRadiusKm * 1000).toDouble();
      if (movedMeters <= hardMeters) return;

      // Bounding box aproximativ pentru un "hard radius" în km.
      final latDelta = _panningHardRadiusKm / 111.0;
      final lngDelta =
          _panningHardRadiusKm / (111.0 * math.cos(myLat * math.pi / 180));

      final clampedLat = centerLat.clamp(myLat - latDelta, myLat + latDelta);
      final clampedLng = centerLng.clamp(myLng - lngDelta, myLng + lngDelta);

      if (clampedLat == centerLat && clampedLng == centerLng) return;

      _isPanClamping = true;
      _lastPanClampAt = now;
      try {
        await _mapboxMap!.flyTo(
          CameraOptions(
            center: MapboxUtils.createPoint(clampedLat, clampedLng),
            zoom: cam.zoom,
          ),
          MapAnimationOptions(duration: AppDrawer.lowDataMode ? 200 : 350),
        );
      } finally {
        _isPanClamping = false;
      }
    } catch (_) {
      // best-effort only
    }
  }

  void _updateSearchAreaChipVisibility() async {
    if (_mapboxMap == null) return;
    final widthPx = MediaQuery.sizeOf(context).width;
    try {
      final cam = await _mapboxMap!.getCameraState();
      if (!mounted) return;
      final center = cam.center;
      final lat = center.coordinates.lat.toDouble();
      final lng = center.coordinates.lng.toDouble();
      final zoom = cam.zoom;
      final kmText = _formatVisibleMapWidthLabel(lat, zoom, widthPx);
      setState(() {
        _scaleBarText = kmText;
      });
      final lastLat = _lastSearchCenterLat;
      final lastLng = _lastSearchCenterLng;
      if (lastLat == null || lastLng == null) {
        setState(() { _showSearchAreaChip = true; });
        return;
      }
      final movedMeters = MapboxUtils.calculateDistance(
        MapboxUtils.createPoint(lastLat, lastLng),
        MapboxUtils.createPoint(lat, lng),
      );
      final shouldShow = movedMeters > 150.0; // prag mic
      if (shouldShow != _showSearchAreaChip) {
        setState(() { _showSearchAreaChip = shouldShow; });
      }
    } catch (_) {}
  }

  /// Tap scurt: doar POI / selecții native; pinul roșu se plasează la long-press.
  void _handleMapTap(Point tappedPoint) {
    if (_checkForPOIAtPoint(tappedPoint)) return;
  }

  /// Long-press: mută pinul și deschide direct foaia (navigare / favorite) — nu mai e nevoie să apeși separat pe pin.
  void _handleMapLongPress(Point point) {
    if (_awaitingMapOrientationPinPlacement) {
      unawaited(_finishMapOrientationPinPlacement(point));
      return;
    }
    if (_isDestinationPreviewMode) {
      unawaited(_moveMapPinToPoint(point, syncRidePanel: true));
      return;
    }
    if (_awaitingParkingYieldMapPick) {
      if (_checkForPOIAtPoint(point)) return;
      unawaited(_finishParkingYieldMapPick(point));
      return;
    }
    if (_checkForPOIAtPoint(point)) return;
    unawaited(_openMapLocationSheetAfterMovingPin(point));
  }

  Future<void> _openMapLocationSheetAfterMovingPin(Point point) async {
    await _moveMapPinToPoint(point, syncRidePanel: false);
    if (!mounted) return;
    await _showMapTapLocationSheet(point);
  }

  /// Apelat de RideRequestPanel când userul selectează o destinație din sugestii.
  Future<void> _onDestinationPreview(Point destPoint, String destAddress) async {
    _isDestinationPreviewMode = true;
    _previewPinPoint = destPoint;
    // Zbor camera la destinație
    await _mapboxMap?.flyTo(
      CameraOptions(center: destPoint, zoom: 15.0),
      MapAnimationOptions(duration: 900),
    );
    // Așteptăm să se termine animația, apoi calculăm poziția pe ecran
    await Future.delayed(const Duration(milliseconds: 950));
    await _updatePreviewPinScreenPos(destPoint);
    if (mounted) setState(() {});
  }

  Future<void> _moveMapPinToPoint(Point newPoint, {required bool syncRidePanel}) async {
    _previewPinPoint = newPoint;
    await _updatePreviewPinScreenPos(newPoint);
    if (syncRidePanel && _isDestinationPreviewMode) {
      final geocoding = await _geocodingServiceForPreview(newPoint);
      _rideRequestPanelKey.currentState?.updatePreviewDestination(newPoint, geocoding);
    }
    _resetPinAutoHideTimer();
  }

  void _resetPinAutoHideTimer() {
    _pinAutoHideTimer?.cancel();
    if (_isDestinationPreviewMode || _inAppNavActive || _isDraggingPin) return;
    _pinAutoHideTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_isDraggingPin || _isDestinationPreviewMode || _inAppNavActive) return;
      setState(() {
        _previewPinScreenPos = null;
      });
    });
  }

  Future<void> _resetMapPinAfterRouteCleared() async {
    if (!mounted) return;
    _previewPinPoint = null;
    _previewPinScreenPos = null;
    if (mounted) setState(() {});
  }

  /// Convertește coordonate hartă â†’ pixeli ecran și actualizează poziția widget-ului pin.
  Future<void> _updatePreviewPinScreenPos(Point point) async {
    if (_mapboxMap == null || !mounted) return;
    try {
      final sc = await _mapboxMap!.pixelForCoordinate(point);
      if (mounted) setState(() => _previewPinScreenPos = Offset(sc.x, sc.y));
    } catch (_) {}
  }

  /// Drag update â€” mută widget-ul pin instant pe ecran.
  void _onPinDragUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    _pinAutoHideTimer?.cancel();
    setState(() {
      _isDraggingPin = true;
      _previewPinScreenPos = (_previewPinScreenPos ?? Offset.zero) + details.delta;
    });
  }

  /// Drag end â€” convertește poziția finală Ã®n coordonate și reverse geocodează.
  Future<void> _onPinDragEnd(DragEndDetails details) async {
    if (!mounted || _previewPinScreenPos == null) return;
    setState(() => _isDraggingPin = false);
    _resetPinAutoHideTimer();
    final sc = ScreenCoordinate(
      x: _previewPinScreenPos!.dx,
      y: _previewPinScreenPos!.dy,
    );
    try {
      final coord = await _mapboxMap?.coordinateForPixel(sc);
      if (coord == null || !mounted) return;
      _previewPinPoint = coord;
      if (_isDestinationPreviewMode) {
        final geocoding = await _geocodingServiceForPreview(coord);
        _rideRequestPanelKey.currentState?.updatePreviewDestination(coord, geocoding);
      }
    } catch (e) {
      Logger.error('Pin drag end error: $e', error: e);
    }
  }

  Future<String> _geocodingServiceForPreview(Point point) async {
    final address = await GeocodingService().getAddressFromCoordinates(
      point.coordinates.lat.toDouble(),
      point.coordinates.lng.toDouble(),
    );
    return address ?? 'Locație selectată';
  }

  Widget _buildAiGlassButton({
    required VoiceProcessingState? processingState,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    Color accentColor;
    IconData icon;
    switch (processingState) {
      case VoiceProcessingState.listening:
        accentColor = Colors.red;
        icon = Icons.mic;
        break;
      case VoiceProcessingState.thinking:
        accentColor = Colors.orange;
        icon = Icons.psychology;
        break;
      case VoiceProcessingState.speaking:
        accentColor = Colors.green;
        icon = Icons.volume_up;
        break;
      default:
        accentColor = const Color(0xFF4F46E5);
        icon = Icons.mic;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: isDark ? 0.78 : 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }





  /// Verifică dacă tap-ul este pe un POI. Returnează `true` dacă s-a tratat un POI.
  bool _checkForPOIAtPoint(Point tappedPoint) {
    final pois = _currentPois;
    
    // Verifică distanța față de fiecare POI (raza de detectare: ~50 metri)
    const double detectionRadiusMeters = 50.0;
    
    for (int i = 0; i < pois.length; i++) {
      final poi = pois[i];
      final poiPoint = Point(
        coordinates: Position(poi.location.longitude, poi.location.latitude)
      );
      
      // Calculează distanța aproximativă
      final distance = _calculateDistanceBetweenPoints(tappedPoint, poiPoint);
      
      if (distance <= detectionRadiusMeters) {
        Logger.debug('POI detected: ${poi.name}');
        _onPoiTapped(poi);
        return true;
      }
    }
    return false;
  }

  Future<void> _showMapTapLocationSheet(Point point) async {
    if (!mounted) return;
    // NU folosi `context` din interiorul [FutureBuilder] pentru navigare după pop:
    // acel context e al sheet-ului și devine unmounted imediat ce închizi sheet-ul,
    // deci showNavigationChooser / push către PointNavigationScreen nu rulează.
    final mapScreenContext = context;
    final lat = point.coordinates.lat.toDouble();
    final lng = point.coordinates.lng.toDouble();

    await showModalBottomSheet<void>(
      context: mapScreenContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Locație selectată',
                  style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    'Sfat: ține apăsat pe hartă la un punct ca să ajungi aici direct, fără să apeși pe pin.',
                    style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                _MapTapGeocodeSheetBody(
                  lat: lat,
                  lng: lng,
                  sheetContext: sheetCtx,
                  mapScreenContext: mapScreenContext,
                  onOpenFavorite: _openAddFavoriteFlow,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAddFavoriteFlow(double lat, double lng, String address) async {
    if (!mounted) return;
    if (FirebaseAuth.instance.currentUser == null) {
      _showSafeSnackBar(
        'Conectează-te pentru a salva adrese favorite.',
        Colors.orange,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => AddAddressScreen(
          prefilledCoordinates: GeoPoint(lat, lng),
          prefilledAddress: address,
          initialLabel: 'Favorite',
        ),
      ),
    );
  }

  Future<void> _onPoiAddFavorite(PointOfInterest poi) async {
    final lat = poi.location.latitude;
    final lng = poi.location.longitude;
    final resolved = await GeocodingService().getAddressFromCoordinates(lat, lng);
    final address = resolved != null && resolved.trim().isNotEmpty
        ? resolved.trim()
        : '${poi.name}. ${poi.description}';
    await _openAddFavoriteFlow(lat, lng, address);
  }

  void _onPoiNavigateHere(PointOfInterest poi) {
    final lat = poi.location.latitude;
    final lng = poi.location.longitude;
    ExternalMapsLauncher.showNavigationChooser(
      context,
      lat,
      lng,
      onOpenNabour: () async {
        if (!mounted) return;
        final seed = await _navigationOriginSeedLatLng();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (ctx) => PointNavigationScreen(
              destinationLat: lat,
              destinationLng: lng,
              destinationLabel: poi.name,
              mapKnownOriginLat: seed.lat,
              mapKnownOriginLng: seed.lng,
            ),
          ),
        );
      },
    );
  }

  /// Calculează distanța aproximativă Ã®ntre două puncte Ã®n metri
  double _calculateDistanceBetweenPoints(Point point1, Point point2) {
    const double earthRadius = 6371000; // metri
    final lat1Rad = point1.coordinates.lat * (math.pi / 180);
    final lat2Rad = point2.coordinates.lat * (math.pi / 180);
    final deltaLatRad = (point2.coordinates.lat - point1.coordinates.lat) * (math.pi / 180);
    final deltaLngRad = (point2.coordinates.lng - point1.coordinates.lng) * (math.pi / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Handler pentru POI selectat
  void _onPoiTapped(PointOfInterest poi) {
    Logger.info('POI tapped: ${poi.name}');
    HapticFeedback.selectionClick();
    
    setState(() {
      _selectedPoi = poi;
      _showPoiCard = true;
      // Keep tap-detection logic consistent: we only draw/select this POI.
      _currentPois
        ..clear()
        ..add(poi);
      // Reset position so the card starts in a visible spot
      _poiCardPosition = const Offset(16, 180);
    });

    // Ensure zoom to de-cluster and center (debounced and thresholded)
    _cameraFlyToTimer?.cancel();
    _cameraFlyToTimer = Timer(const Duration(milliseconds: 250), () async {
      final map = _mapboxMap;
      if (map == null) return;
      try {
        final cam = await map.getCameraState();
        final currentCenter = cam.center;
        final double currentLat = currentCenter.coordinates.lat.toDouble();
        final double currentLng = currentCenter.coordinates.lng.toDouble();
        final double targetLat = poi.location.latitude;
        final double targetLng = poi.location.longitude;

        final double dMeters = MapboxUtils.calculateDistance(
          MapboxUtils.createPoint(currentLat, currentLng),
          MapboxUtils.createPoint(targetLat, targetLng),
        );
        final double zoomDelta = (cam.zoom - 16.0).abs();

        // Skip tiny moves to avoid camera churn
        if (dMeters < 80.0 && zoomDelta < 0.15) return;

        unawaited(map.flyTo(
          CameraOptions(
            center: MapboxUtils.createPoint(targetLat, targetLng),
            zoom: 16.0,
            padding: MbxEdgeInsets(
              top: 80.0,
              left: 16.0,
              bottom: 320.0, // spațiu pentru cardurile de jos
              right: 16.0,
            ),
          ),
          MapAnimationOptions(duration: AppDrawer.lowDataMode ? 350 : 600),
        ));
      } catch (_) {}
    });

    // Update selected POI highlight
    _updateSelectedPoiHighlight(poi);

    // Afișăm pe hartă DOAR POI-ul selectat (nu toată categoria).
    // Astfel evităm încărcarea/afișarea automată a tuturor POI-urilor.
    unawaited(_updatePoiGeoJson([poi]));

    // âœ… Auto-hide: dacă nu se inițiază nicio acțiune (pickup/destination/stop),
    // curățăm highlight-ul și cardul după 60 secunde pentru a elibera memorie
    _selectedPoiAutoHideTimer?.cancel();
    _selectedPoiAutoHideTimer = Timer(const Duration(seconds: 60), () async {
      if (!mounted) return;
      if (_selectedPoi?.id == poi.id) {
        await _clearSelectedPoiHighlight();
        if (mounted) {
          setState(() {
            _selectedPoi = null;
            _showPoiCard = false;
          });
        }
        Logger.debug('Auto-hide POI ${poi.name} după 5s (fără navigare)');
      }
    });

    // Optional: alege intrarea pentru POI-uri mari
    _maybeShowEntrancePicker(poi);

    // Sugestii pickup Ã®n jurul POI
    _generatePickupSuggestionsAround(poi);
  }

  Future<void> _updateSelectedPoiHighlight(PointOfInterest poi) async {
    if (_mapboxMap == null) return;
    try {
      final feature = {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [poi.location.longitude, poi.location.latitude]
        },
        'properties': {
          'id': poi.id,
          'name': poi.name,
        }
      };
      final fc = {'type': 'FeatureCollection', 'features': [feature]};
      // Update highlight but don't block UI
      unawaited(_mapboxMap!.style.setStyleSourceProperty(
        _selectedPoiSourceId,
        'data',
        json.encode(fc),
      ));
    } catch (e) {
      Logger.error('Failed to update selected POI highlight: $e', error: e);
    }
  }

  Future<void> _clearSelectedPoiHighlight() async {
    if (_mapboxMap == null) return;
    try {
      final empty = {'type': 'FeatureCollection', 'features': []};
      await _mapboxMap!.style.setStyleSourceProperty(
        _selectedPoiSourceId,
        'data',
        json.encode(empty),
      );
    } catch (e) {
      Logger.error('Failed to clear selected POI highlight: $e', error: e);
    }
  }
  Future<void> _updatePoiGeoJson(List<PointOfInterest> pois) async {
    if (_mapboxMap == null) return;
    try {
      final features = pois.map((poi) => {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [poi.location.longitude, poi.location.latitude]
        },
        'properties': {
          'id': poi.id,
          'name': poi.name,
          'category': poi.category.name,
          'rating': poi.additionalInfo?['rating'],
          'isOpen': poi.additionalInfo?['opening_hours'] != null,
          'icon': poi.category.emoji
        }
      }).toList();

      final fc = {'type': 'FeatureCollection', 'features': features};
      await _mapboxMap!.style.setStyleSourceProperty(_poiSourceId, 'data', json.encode(fc));
    } catch (e) {
      Logger.error('Failed to update POI GeoJson: $e', error: e);
    }
  }




  /// Setează POI ca punct de plecare
  void _setPOIAsPickup(PointOfInterest poi) {
    Logger.info('Setting POI as pickup: ${poi.name}');
    
    try {
      // âœ… PERFORMANCE: Cancel previous operations
      _poiOperationTimer?.cancel();
      
      // âœ… PERFORMANCE: Quick UI update - batch all setState calls
      setState(() {
        Logger.info('Updating pickup state...');
        _pickupController.text = poi.name;
        _pickupLatitude = poi.location.latitude;
        _pickupLongitude = poi.location.longitude;
        // âœ… PERFORMANCE: Close POI card in same setState
        _selectedPoi = null;
        _showPoiCard = false;
        Logger.info('Pickup state updated: lat=$_pickupLatitude, lng=$_pickupLongitude');
      });

      // âœ… PERFORMANCE: Close POI card immediately - no additional navigation
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // âœ… PERFORMANCE: Show SnackBar immediately
      _showSafeSnackBar(
        '${poi.name} setat ca punct de plecare',
        Colors.blue,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => _clearPickup(),
        ),
      );

      // âœ… PERFORMANCE: Debounce heavy operations
      _poiOperationTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          Logger.info('Executing deferred operations for pickup...');
          _updateRideRequestPanelPickup(poi);
          _updateMapWithNewPickup();
          // âœ… CONECTARE: Folosește batch map updates
          _batchMapUpdates();
          // âœ… CONECTARE: Folosește _routingService pentru route update
          _updateRouteAfterPOI();
        }
      });

      // Afișează automat ruta dacă avem pickup + destinație
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkAndShowRouteAutomatically();
      });
      
    } catch (e) {
      Logger.error('CRASH in _setPOIAsPickup: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _closePoiCard();
        _showSafeSnackBar('Eroare la setarea pickup: $e', Colors.red);
      }
    }
  }

  /// Setează POI ca punct de destinație
  void _setPOIAsDestination(PointOfInterest poi) {
    Logger.info('Setting POI as destination: ${poi.name}');
    
    try {
      // âœ… PERFORMANCE: Cancel previous operations
      _poiOperationTimer?.cancel();
      
      // âœ… PERFORMANCE: Quick UI update - batch all setState calls
      setState(() {
        Logger.info('Updating destination state...');
        _destinationController.text = poi.name;
        _destinationLatitude = poi.location.latitude;
        _destinationLongitude = poi.location.longitude;
        // âœ… PERFORMANCE: Close POI card in same setState
        _selectedPoi = null;
        _showPoiCard = false;
        Logger.info('Destination state updated: lat=$_destinationLatitude, lng=$_destinationLongitude');
      });

      // âœ… PERFORMANCE: Close POI card immediately - no additional navigation
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // âœ… PERFORMANCE: Show SnackBar immediately
      _showSafeSnackBar(
        '${poi.name} setat ca destinație',
        Colors.green,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => _clearDestination(),
        ),
      );

      // âœ… PERFORMANCE: Debounce heavy operations
      _poiOperationTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          Logger.info('Executing deferred operations for destination...');
          _updateRideRequestPanelDestination(poi);
          _updateMapWithNewDestination();
          // âœ… CONECTARE: Folosește batch map updates
          _batchMapUpdates();
          // âœ… CONECTARE: Folosește _routingService pentru route update
          _updateRouteAfterPOI();
        }
      });

      // Afișează automat ruta dacă avem pickup + destinație
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkAndShowRouteAutomatically();
      });
      
    } catch (e) {
      Logger.error('CRASH in _setPOIAsDestination: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _closePoiCard();
        _showSafeSnackBar('Eroare la setarea destinației: $e', Colors.red);
      }
    }
  }

    /// Adaugă POI ca oprire intermediară
  void _addPOIAsStop(PointOfInterest poi) {
    Logger.debug('Adding POI as stop: ${poi.name}');
    
    try {
      // âœ… PERFORMANCE: Cancel previous operations
      _poiOperationTimer?.cancel();
      
      // Validation
      if (_intermediateStops.length >= _maxIntermediateStops) {
        _showSafeSnackBar('Maximum $_maxIntermediateStops opriri intermediare permise', Colors.orange);
        return;
      }

      // Check for duplicates
      final existingStop = _intermediateStops.any((stop) =>
          stop == poi.name);
      
      if (existingStop) {
        _showSafeSnackBar('Această oprire este deja adăugată', Colors.orange);
        return;
      }

      // âœ… PERFORMANCE: Quick UI update - batch all setState calls
      setState(() {
        Logger.debug('Adding stop to list...');
        _intermediateStops.add(poi.name);
        // âœ… PERFORMANCE: Close POI card in same setState
        _selectedPoi = null;
        _showPoiCard = false;
        Logger.debug('Stop added. Total stops: ${_intermediateStops.length}');
      });

      // âœ… PERFORMANCE: Close POI card immediately - no additional navigation
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // âœ… PERFORMANCE: Show SnackBar immediately
      _showSafeSnackBar(
        '${poi.name} adăugat ca oprire intermediară',
        Colors.orange,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => _removeLastStop(),
        ),
      );

      // âœ… PERFORMANCE: Debounce heavy operations
      _poiOperationTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          Logger.debug('Executing deferred operations for stop...');
          _updateMapWithAllPoints();
          // âœ… CONECTARE: Folosește batch map updates
          _batchMapUpdates();
          // âœ… CONECTARE: Folosește _routingService pentru route update
          _updateRouteAfterPOI();
        }
      });

      // Afișează automat ruta dacă avem pickup + destinație
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkAndShowRouteAutomatically();
      });
      
    } catch (e) {
      Logger.error('CRASH in _addPOIAsStop: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _closePoiCard();
        _showSafeSnackBar('Eroare la adăugarea opririi: $e', Colors.red);
      }
    }
  }

  /// Metodă helper pentru a șterge ultimul stop adăugat
  void _removeLastStop() {
    if (_intermediateStops.isNotEmpty) {
      setState(() {
        _intermediateStops.removeLast();
      });
      
      // Update ruta după ștergere
      if (_pickupLatitude != null && _destinationLatitude != null) {
        _updateRouteWithAllPoints();
      }
    }
  }

  /// È˜terge un stop specific din listă
  void _removeStop(String stopName) {
    setState(() {
      _intermediateStops.removeWhere((s) => s == stopName);
    });
    
    // Feedback vizual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$stopName eliminat din opriri'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    // Update ruta după ștergere
    if (_pickupLatitude != null && _destinationLatitude != null) {
      _updateRouteWithAllPoints();
    }
  }

  // _buildIntermediateStopsList() extracted to lib/widgets/map/map_intermediate_stops.dart

  /// Curăță pickup-ul
  void _clearPickup() {
    setState(() {
      _pickupController.clear();
      _pickupLatitude = null;
      _pickupLongitude = null;


    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Punctul de plecare a fost șters')),
      );
    }
    
    _updateMapWithAllPoints();
  }

  /// Curăță destinația
  void _clearDestination() {
    setState(() {
      _destinationController.clear();
      _destinationLatitude = null;
      _destinationLongitude = null;

    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destinația a fost ștearsă')),
      );
    }
    
    _updateMapWithAllPoints();
  }



  /// Update hartă cu noul pickup
  void _updateMapWithNewPickup() {
    if (_pickupLatitude != null && _pickupLongitude != null) {
      // Center camera pe pickup
      _mapboxMap?.flyTo(
        CameraOptions(
          center: MapboxUtils.createPoint(_pickupLatitude!, _pickupLongitude!),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 1000)
      );
      
      // Update route dacă avem și destinația
      if (_destinationLatitude != null && _destinationLongitude != null) {
        _updateRouteWithAllPoints();
      }
    }
  }

  /// Update hartă cu noua destinație
  void _updateMapWithNewDestination() {
    if (_destinationLatitude != null && _destinationLongitude != null) {
      // Update route dacă avem și pickup-ul
      if (_pickupLatitude != null && _pickupLongitude != null) {
        _updateRouteWithAllPoints();
      }
    }
  }



  /// Update hartă cu toate punctele
  void _updateMapWithAllPoints() {
    List<Point> allPoints = [];
    
    // Adaugă pickup
    if (_pickupLatitude != null && _pickupLongitude != null) {
      allPoints.add(Point(coordinates: Position(_pickupLongitude!, _pickupLatitude!)));
    }
    
    // Adaugă destination
    if (_destinationLatitude != null && _destinationLongitude != null) {
      allPoints.add(Point(coordinates: Position(_destinationLongitude!, _destinationLatitude!)));
    }
    
    // Adaugă intermediate stops
    // (Acest lucru ar trebui să fie gestionat de _buildWaypoints și _updateRouteWithAllPoints)
    // Pentru a centra camera pe toate punctele, ar trebui să geocodezi opririle aici
    // sau să te bazezi pe _buildWaypoints pentru a le obține.
    // Momentan, _fitCameraToPoints nu ia Ã®n considerare opririle intermediare.
    // Pentru simplitate, vom lăsa așa cum este, presupunând că pickup și destination sunt suficiente pentru centrare.
    
    // Fit camera pentru toate punctele
    if (allPoints.isNotEmpty) {
      _fitCameraToPoints(allPoints);
    }
    
    // Update route dacă avem pickup și destination
    if (_pickupLatitude != null && _destinationLatitude != null) {
      _updateRouteWithAllPoints();
    }
  }

  /// Fit camera pentru toate punctele
  void _fitCameraToPoints(List<Point> points) {
    if (points.isEmpty || _mapboxMap == null) return;
    
    double minLat = points.first.coordinates.lat.toDouble();
    double maxLat = points.first.coordinates.lat.toDouble();
    double minLng = points.first.coordinates.lng.toDouble();
    double maxLng = points.first.coordinates.lng.toDouble();
    
    for (var point in points) {
      minLat = math.min(minLat, point.coordinates.lat.toDouble());
      maxLat = math.max(maxLat, point.coordinates.lat.toDouble());
      minLng = math.min(minLng, point.coordinates.lng.toDouble());
      maxLng = math.max(maxLng, point.coordinates.lng.toDouble());
    }
    
    // Adaugă padding
    const double padding = 0.01; // ~1km
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;
    
    final center = Point(
      coordinates: Position(
        (minLng + maxLng) / 2,
        (minLat + maxLat) / 2,
      )
    );
    
    _mapboxMap?.flyTo(
      CameraOptions(center: center, zoom: 12.0),
      MapAnimationOptions(duration: AppDrawer.lowDataMode ? 600 : 1000)
    );
  }

  /// âœ… PERFORMANCE: Update route cu toate punctele - optimized with async
  void _updateRouteWithAllPoints() async {
    Logger.debug('Starting route update...');
    
    if (_pickupLatitude == null || _destinationLatitude == null) {
      Logger.debug('Missing pickup or destination - skipping route update');
      return;
    }
    
    try {
      // âœ… PERFORMANCE: Give UI time to settle before heavy operations
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      Logger.debug('Building waypoints...');
      final waypoints = await _buildWaypoints(); // âœ… CONECTARE: Folosește helper method
      Logger.debug('Built ${waypoints.length} waypoints');

      Logger.debug('Calculating route with ${waypoints.length} waypoints...');
      
      // âœ… PERFORMANCE: Execute in next frame to avoid blocking
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        
        try {
          // âœ… CONECTARE: Folosește _routingService helper method
          await _calculateRouteWithService(waypoints);
          // âœ… Ne-blocant: rute alternative pentru UI
          if (!AppDrawer.lowDataMode) {
            unawaited(_fetchAlternativeRoutes(waypoints));
          }
        } catch (e) {
          Logger.error('Route calculation failed: $e', error: e);
          if (mounted) {
            _showSafeSnackBar('Eroare la calcularea rutei: $e', Colors.red);
          }
        }
      });
      
    } catch (e) {
      Logger.error('Route setup failed: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _showSafeSnackBar('Eroare la configurarea rutei: $e', Colors.red);
      }
    }
  }

  /// âœ… PERFORMANCE: Helper method pentru building waypoints
  Future<List<Point>> _buildWaypoints() async {
    List<Point> waypoints = [];
    
    // Pickup
    if (_pickupLatitude != null && _pickupLongitude != null) {
      waypoints.add(Point(
        coordinates: Position(_pickupLongitude!, _pickupLatitude!)
      ));
      Logger.debug('Added pickup waypoint');
    }
    
    // Stops
    if (_intermediateStops.isNotEmpty) {
      for (var stop in _intermediateStops) {
        // Implementează geocoding pentru opririle intermediare
        final coordinates = await _getCoordinatesForDestination(stop);
        if (coordinates != null) {
          waypoints.add(coordinates);
          Logger.debug('Added intermediate stop: $stop');
        }
      }
      Logger.debug('Found ${_intermediateStops.length} intermediate stops');
    }
    
    // Destination
    if (_destinationLatitude != null && _destinationLongitude != null) {
      waypoints.add(Point(
        coordinates: Position(_destinationLongitude!, _destinationLatitude!)
      ));
      Logger.debug('Added destination waypoint');
    }
    
    return waypoints;
  }

  /// Start ride request complet
  void _startRideRequest() async {
    // Validare
    if (_pickupLatitude == null || _destinationLatitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selectează punctul de plecare și destinația'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_contactUids == null) {
      if (!mounted) return;
      _showSafeSnackBar(
        'Se încarcă contactele din agendă. Încearcă din nou în câteva secunde.',
        Colors.orange,
      );
      unawaited(_loadContactUids());
      return;
    }
    if (!_canRequestRideWithContactFilter()) {
      if (!mounted) return;
      _showSafeSnackBar(
        'Nabour trimite cererea doar către șoferii din contactele tale. Adaugă în agendă numerele prietenilor cu cont Nabour sau acordă permisiunea la contacte.',
        Colors.orange,
      );
      return;
    }

    try {
      // Creează obiectul Ride
      final newRide = Ride(
        id: '',
        passengerId: FirebaseAuth.instance.currentUser?.uid ?? '',  // âœ… MODIFICAT: userId â†’ passengerId
        startAddress: _pickupController.text,
        destinationAddress: _destinationController.text,
        distance: 0, // Va fi calculat de serviciu
        startLatitude: _pickupLatitude!,
        startLongitude: _pickupLongitude!,
        destinationLatitude: _destinationLatitude!,
        destinationLongitude: _destinationLongitude!,
        durationInMinutes: 0, // Va fi calculat de serviciu
        baseFare: 0, // Va fi calculat de serviciu
        perKmRate: 0, // Va fi calculat de serviciu
        perMinRate: 0, // Va fi calculat de serviciu
        totalCost: 0, // Va fi calculat de serviciu
        appCommission: 0, // Va fi calculat de serviciu
        driverEarnings: 0, // Va fi calculat de serviciu
        timestamp: DateTime.now(),
        status: 'pending',
        category: RideCategory.standard,
        stops: await Future.wait(_intermediateStops.map<Future<Map<String, dynamic>>>((stop) async {
          // âœ… FIX: Geocoding real pentru opriri (nu coordonate default)
          final coordinates = await _getCoordinatesForDestination(stop);
          return {
            'address': stop,
            'name': stop,
            'latitude': coordinates?.coordinates.lat ?? 44.4268, // Fallback doar dacă geocoding eșuează
            'longitude': coordinates?.coordinates.lng ?? 26.1025, // Fallback doar dacă geocoding eșuează
          };
        })),
        allowedDriverUids: _contactUids!.toList(), // doar contacte (deja validate mai sus)
      );
      
      final rideId = await _firestoreService.requestRide(newRide);
      if (!mounted) return;
      
      // Success feedback
      unawaited(HapticService.instance.heavy());
      Navigator.push<Object?>(
        context,
        AppTransitions.slideUp(SearchingForDriverScreen(rideId: rideId)),
      ).then(_onSearchingForDriverPopped);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la crearea cursei: $e')),
      );
    }
  }

  // ── POI Category Sheet ─────────────────────────────────────────────
  Future<void> _placeCommunityMysteryBoxFlow() async {
    final pos = _currentPositionObject;
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Așteptăm poziția GPS pentru a plasa cutia aici.')),
        );
      }
      return;
    }
    final msgCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mystery Box comunitar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plasezi o cutie la locația curentă. Cost: ${TokenCost.mysteryBoxSlot} tokeni. '
                'Primul utilizator care o deschide la fața locului primește aceiași tokeni — '
                'tu vei primi o notificare când se întâmplă.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                maxLength: 120,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mesaj scurt (opțional)',
                  hintText: 'ex: Bonus pe vârf — distracție plăcută!',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Renunț')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Plasează'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      msgCtrl.dispose();
      return;
    }
    try {
      final id = await CommunityMysteryBoxService.instance.place(
        lat: pos.latitude,
        lng: pos.longitude,
        message: msgCtrl.text.trim(),
      );
      msgCtrl.dispose();
      if (!mounted) return;
      if (id != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cutie plasată! (-${TokenCost.mysteryBoxSlot} tokeni)'),
            backgroundColor: Colors.teal.shade700,
          ),
        );
        unawaited(_communityMysteryManager?.updateBoxes(
          pos.latitude,
          pos.longitude,
          force: true,
        ));
      }
    } on FirebaseFunctionsException catch (e) {
      msgCtrl.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Nu am putut plasa cutia.')),
      );
    } catch (e) {
      msgCtrl.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare: $e')),
      );
    }
  }

  void _showPoiCategorySheet() {
    showModalBottomSheet<PoiCategory>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Puncte de interes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              MapPoiCategoryChips(
                onCategoryTapped: (category) {
                  Navigator.of(ctx).pop(category);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).then((category) {
      if (category != null && mounted) {
        _onPoiCategorySelected(category);
      }
    });
  }

  Future<void> _onPoiCategorySelected(PoiCategory category) async {
    if (_currentPositionObject == null) return;

    final lat = _currentPositionObject!.latitude;
    final lng = _currentPositionObject!.longitude;

    try {
      final pois = await PoiService().fetchPoisFromApi(
        {'latitude': lat, 'longitude': lng},
        category,
        radiusKm: 3.0,
      );

      if (!mounted) return;

      if (pois.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Niciun ${category.displayName} gasit in zona')),
        );
        return;
      }

      setState(() {
        _currentPois
          ..clear()
          ..addAll(pois);
      });

      if (!_poiLayersInitialized) {
        await _ensurePoiLayersInitialized();
      }
      await _updatePoiGeoJson(pois);

      Logger.info('Loaded ${pois.length} POIs for ${category.displayName}', tag: 'POI');

      _showPoiListSheet(category, pois);
    } catch (e) {
      Logger.error('Failed to load POIs for ${category.displayName}: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la incarcarea POI-urilor: $e')),
        );
      }
    }
  }

  void _showPoiListSheet(PoiCategory category, List<PointOfInterest> pois) {
    showModalBottomSheet<PointOfInterest>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${category.emoji} ${category.displayName}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  '${pois.length} rezultate in zona ta',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: pois.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (ctx, i) {
                    final poi = pois[i];
                    final distM = _currentPositionObject != null
                        ? _calculateDirectDistance(
                            _currentPositionObject!.latitude,
                            _currentPositionObject!.longitude,
                            poi.location.latitude,
                            poi.location.longitude,
                          )
                        : null;
                    String distLabel = '';
                    if (distM != null) {
                      distLabel = distM >= 1000
                          ? '${(distM / 1000).toStringAsFixed(1)} km'
                          : '${distM.round()} m';
                    }

                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(category.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      title: Text(
                        poi.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: poi.description.isNotEmpty
                          ? Text(
                              poi.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            )
                          : null,
                      trailing: distLabel.isNotEmpty
                          ? Text(
                              distLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            )
                          : null,
                      onTap: () => Navigator.of(ctx).pop(poi),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((selectedPoi) {
      if (selectedPoi != null && mounted) {
        _onPoiTapped(selectedPoi);
      }
    });
  }

  /// Widget pentru butonul de start ride
  // _buildStartRideButton() extracted to lib/widgets/map/map_ride_info_panel.dart
  void _closePoiCard() {
    Logger.debug('Closing POI card safely...');
    if (mounted) {
      try {
        setState(() {
          // Doar Ã®nchide cardul; NU afecta adresele sau selecția din AddressInputView
          _showPoiCard = false;
        });
        // Curăță highlight la Ã®nchiderea cardului
        unawaited(_clearSelectedPoiHighlight());
        Logger.debug('POI card closed successfully');
      } catch (e) {
        Logger.error('Error closing POI card: $e', error: e);
      }
    }
  }

  /// âœ… PERFORMANCE: Deferred RideRequestPanel update for pickup
  void _updateRideRequestPanelPickup(PointOfInterest poi) {
    Logger.info('Calling RideRequestPanel setPickup...');
    _ensureRidePanelVisibleForExternalAction(() {
      _rideRequestPanelKey.currentState?.setPickup(
        address: poi.name,
        latitude: poi.location.latitude,
        longitude: poi.location.longitude,
      );
    });
  }

  /// âœ… PERFORMANCE: Deferred RideRequestPanel update for destination
  void _updateRideRequestPanelDestination(PointOfInterest poi) {
    Logger.info('Calling RideRequestPanel setDestination...');
    _ensureRidePanelVisibleForExternalAction(() {
      _rideRequestPanelKey.currentState?.setDestination(
        address: poi.name,
        latitude: poi.location.latitude,
        longitude: poi.location.longitude,
      );
    });
  }

  /// âœ… PERFORMANCE: Batch map updates pentru a reduce overhead-ul
  void _batchMapUpdates() async {
    if (!mounted) return;
    
    Logger.debug('Starting batch map updates...');
    
    // âœ… PERFORMANCE: Collect all updates
    final List<Future<void> Function()> updates = [];
    
    if (_pickupLatitude != null && _pickupLongitude != null) {
      updates.add(() async {
        Logger.debug('Updating pickup marker...');
        await _addPickupMarker();
      });
    }
    
    if (_destinationLatitude != null && _destinationLongitude != null) {
      updates.add(() async {
        Logger.debug('Updating destination marker...');
        final coordinates = Point(coordinates: Position(_destinationLongitude!, _destinationLatitude!));
        await _addDestinationMarker(coordinates, 'Destinație');
      });
    }
    
    if (_intermediateStops.isNotEmpty) {
      updates.add(() async {
        Logger.debug('Updating stop markers...');
        await _addStopMarkers();
      });
    }
    
    // âœ… PERFORMANCE: Execute all updates with frame delays
    for (int i = 0; i < updates.length; i++) {
      if (!mounted) break;
      
      try {
        await updates[i]();
        // âœ… PERFORMANCE: One frame delay between operations
        if (i < updates.length - 1) {
          await Future.delayed(const Duration(milliseconds: 16)); // 60fps = 16ms per frame
        }
      } catch (e) {
        Logger.error('Map update $i failed: $e', error: e);
      }
    }
    
    Logger.info('Batch map updates completed');
  }

  /// âœ… PERFORMANCE: Add pickup marker with performance optimization
  Future<void> _addPickupMarker() async {
    // Implementation for adding pickup marker
    // This would replace existing map marker logic
    Logger.info('Pickup marker added');
  }

  /// âœ… PERFORMANCE: Add stop markers with performance optimization (reserved)
  Future<void> _addStopMarkers() async {
    // Implementation for adding stop markers
    // This would replace existing map marker logic
    Logger.info('Stop markers added');
  }

  Future<void> _fetchAlternativeRoutes(List<Point> waypoints) async {
    if (!mounted) return;
    setState(() { _isFetchingAlternatives = true; _alternativeRoutes = []; _selectedAltRouteIndex = 0; });
    try {
      final data = await _routingService.getAlternativeRoutes(waypoints);
      if (!mounted) return;
      final routes = (data?['routes'] as List?) ?? const [];
      setState(() { _alternativeRoutes = routes.cast<Map<String, dynamic>>(); });
    } catch (e) {
      Logger.error('Alternative routes fetch failed: $e', error: e);
    } finally {
      if (mounted) setState(() { _isFetchingAlternatives = false; });
    }
  }

  // Heuristic entrance picker (client-only)
  void _maybeShowEntrancePicker(PointOfInterest poi) {
    final name = poi.name.toLowerCase();
    final largePoiKeywords = ['mall', 'spital', 'hospital', 'university', 'campus', 'aeroport'];
    final isLarge = largePoiKeywords.any((k) => name.contains(k));
    if (!isLarge) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final entries = ['Nord', 'Est', 'Sud', 'Vest'];
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Alege intrarea', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: entries.map((e) {
                return ActionChip(
                  label: Text(e),
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Heuristică: offset mic pe direcție
                    final delta = 0.0008; // ~80m
                    double lat = poi.location.latitude;
                    double lng = poi.location.longitude;
                    switch (e) {
                      case 'Nord': lat += delta; break;
                      case 'Sud': lat -= delta; break;
                      case 'Est': lng += delta; break;
                      case 'Vest': lng -= delta; break;
                    }
                    final adjustedPoi = PointOfInterest(
                      id: poi.id,
                      name: '${poi.name} - $e',
                      description: poi.description,
                      imageUrl: poi.imageUrl,
                      location: geolocator.Position(
                        latitude: lat,
                        longitude: lng,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitude: 0,
                        altitudeAccuracy: 0,
                        heading: 0,
                        headingAccuracy: 0,
                        speed: 0,
                        speedAccuracy: 0,
                      ),
                      category: poi.category,
                      isStatic: poi.isStatic,
                      additionalInfo: poi.additionalInfo,
                    );
                    _onPoiTapped(adjustedPoi);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
        );
      },
    );
  }

  void _generatePickupSuggestionsAround(PointOfInterest poi) async {
    if (_pickupSuggestionsManager == null) return;
    try {
      await _pickupSuggestionsManager?.deleteAll();
      final baseLat = poi.location.latitude;
      final baseLng = poi.location.longitude;
      const deltas = [
        [0.0005, 0.0],
        [0.0, 0.0005],
        [-0.0005, 0.0],
        [0.0, -0.0005],
      ];
      final points = <Point>[];
      final options = <CircleAnnotationOptions>[];
      for (final d in deltas) {
        final lat = baseLat + d[0];
        final lng = baseLng + d[1];
        final p = MapboxUtils.createPoint(lat, lng);
        points.add(p);
        options.add(CircleAnnotationOptions(
          geometry: p,
          circleRadius: 8,
          circleColor: Colors.orange.toARGB32(),
          circleStrokeWidth: 2,
          circleStrokeColor: Colors.white.toARGB32(),
        ));
      }
      setState(() {
        _pickupSuggestionPoints = points;
        _showPickupSuggestions = true;
      });
      await _pickupSuggestionsManager?.createMulti(options);
    } catch (e) {
      Logger.error('Failed to generate pickup suggestions: $e', error: e);
    }
  }

  /// âœ… CONECTARE: Helper method pentru route calculation cu _routingService
  Future<void> _calculateRouteWithService(List<Point> waypoints) async {
    if (!mounted) return;
    
    try {
      Logger.debug('Calculating route with service for ${waypoints.length} waypoints...');
      
      // âœ… FOLOSEÈ˜TE _routingService instance
      final routeData = await _routingService.getRoute(waypoints);
      
      if (!mounted) return;
      
      if (routeData != null) {
        Logger.debug('Route calculated successfully with service');
        await _onRouteCalculated(routeData);
        // AUTO-PROGRESSION: dacă voice este activ, Ã®ncearcă auto-booking după calcul rută
        try {
          if (!mounted) return;
          try {
            final voice = Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
            if (voice.isVoiceActive && routeData.isNotEmpty) {
              voice.updateBookingProgress('Ruta calculată cu succes! Estimez prețul și pornesc rezervarea...');
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && voice.isVoiceActive) {
                  _autoProgressToBooking(voice);
                }
              });
            }
          } catch (_) {}
        } catch (_) {}
      } else {
        Logger.debug('Route calculation returned null');
        if (mounted) {
          _showSafeSnackBar('Nu s-a putut calcula ruta', Colors.orange);
        }
      }
    } catch (e) {
      Logger.error('Route calculation with service failed: $e', error: e);
      if (mounted) {
        _showSafeSnackBar('Eroare la calcularea rutei: $e', Colors.red);
      }
    }
  }

  Future<void> _autoProgressToBooking(FriendsRideVoiceIntegration voice) async {
    try {
      if (_pickupLatitude == null || _destinationLatitude == null) {
        voice.updateBookingProgress('Nu pot continua - informații de locație incomplete.');
        return;
      }
      if (_contactUids == null) {
        voice.updateBookingProgress('Aștept încărcarea contactelor din agendă. Încearcă rezervarea manual peste câteva secunde.');
        unawaited(_loadContactUids());
        return;
      }
      if (!_canRequestRideWithContactFilter()) {
        voice.updateBookingProgress(
          'Nu există utilizatori Nabour în agendă. Adaugă contacte cu numerele lor ca să poți comanda prin rețea.',
        );
        return;
      }
      final newRide = Ride(
        id: '',
        passengerId: FirebaseAuth.instance.currentUser?.uid ?? '',
        startAddress: _pickupController.text.isNotEmpty ? _pickupController.text : 'Locația curentă',
        destinationAddress: _destinationController.text,
        distance: (_currentRouteDistanceMeters ?? 0) / 1000,
        startLatitude: _pickupLatitude!,
        startLongitude: _pickupLongitude!,
        destinationLatitude: _destinationLatitude!,
        destinationLongitude: _destinationLongitude!,
        durationInMinutes: (_currentRouteDurationSeconds ?? 0) / 60,
        baseFare: 0,
        perKmRate: 0,
        perMinRate: 0,
        totalCost: 0,
        appCommission: 0,
        driverEarnings: 0,
        timestamp: DateTime.now(),
        status: 'pending',
        category: RideCategory.standard,
        stops: await Future.wait(_intermediateStops.map<Future<Map<String, dynamic>>>((stop) async {
          // âœ… FIX: Geocoding real pentru opriri (nu coordonate default)
          final coordinates = await _getCoordinatesForDestination(stop);
          return {
            'address': stop,
            'name': stop,
            'latitude': coordinates?.coordinates.lat ?? 44.4268, // Fallback doar dacă geocoding eșuează
            'longitude': coordinates?.coordinates.lng ?? 26.1025, // Fallback doar dacă geocoding eșuează
          };
        })),
        allowedDriverUids: _contactUids!.toList(),
      );
      voice.updateBookingProgress('Creez solicitarea de cursă...');
      final rideId = await _firestoreService.requestRide(newRide);
      voice.updateBookingProgress('✅ Solicitarea de cursă a fost trimisă! Caut șoferi disponibili...');
      
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.push<Object?>(
            context,
            AppTransitions.slideUp(SearchingForDriverScreen(rideId: rideId)),
          ).then(_onSearchingForDriverPopped);
          voice.stopVoiceInteraction();
        });
      }
    } catch (e) {
      Logger.error('Auto-booking error: $e', tag: 'MAP_SCREEN', error: e);
      voice.updateBookingProgress('A apărut o eroare la crearea rezervării. Vă rog să încercați manual.');
    }
  }
  Future<void> _toggleFlashlight() async {
    try {
      final hasTorch = await TorchLight.isTorchAvailable();
      if (!hasTorch) {
        if (mounted) _showSafeSnackBar('Lanterna nu este disponibila pe acest dispozitiv', Colors.orange);
        return;
      }
      if (_flashlightOn) {
        await TorchLight.disableTorch();
        if (mounted) setState(() => _flashlightOn = false);
      } else {
        await TorchLight.enableTorch();
        if (mounted) setState(() => _flashlightOn = true);
      }
    } catch (e) {
      Logger.warning('Flashlight toggle error: $e', tag: 'MAP');
      if (mounted) _showSafeSnackBar('Eroare la activarea lanternei', Colors.red);
    }
  }

  Future<void> _startPulseMode() async {
    if (_isPulseActive) return;
    
    // 1. Pregătim starea Pulse
    if (mounted) {
      setState(() {
        _isPulseActive = true;
      });
    }
    
    Logger.info('Pulse Mode started (Shake detected)');
    HapticFeedback.vibrate();

    // 2. Publicăm starea isPulsing către vecini
    final pos = _currentPositionObject;
    if (pos != null && _isVisibleToNeighbors) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        publishNeighborMapVisibilityUnawaited(
          position: pos,
          avatar: _neighborAvatarCache[uid] ?? '🙂',
          displayName: _neighborDisplayNameCache[uid] ?? 'Vecin',
          isDriver: _currentRole == UserRole.driver && _isDriverAvailable,
          licensePlate: _neighborLicensePlateCache[uid],
          photoURL: _neighborPhotoURLCache[uid],
          allowedUids: _contactUids?.toList() ?? [],
          isPulsing: true,
          carAvatarId: _effectivePublishedCarAvatarId(
            uid,
            useDriverGarageSlot: _currentRole == UserRole.driver,
          ),
        );
      }
    }

    // 3. Verificăm interactiv dacă cineva din jur pulsează deja (Match instant)
    _checkForPulseMatches();

    // 4. Feedback vizual fizic (Blitz intermitent la shake)
    final wasFlashlightOn = _flashlightOn;
    final endTime = DateTime.now().add(const Duration(seconds: 4));
    bool isOn = false;
    
    try {
      final hasTorch = await TorchLight.isTorchAvailable();
      while (DateTime.now().isBefore(endTime) && mounted && hasTorch) {
        isOn ? await TorchLight.disableTorch() : await TorchLight.enableTorch();
        isOn = !isOn;
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (_) {}

    try {
      if (wasFlashlightOn) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }
    } catch (_) {}
    
    if (mounted) {
      setState(() {
        _isPulseActive = false;
      });
    }

    // Resetăm starea isPulsing la false pe server
    if (pos != null && _isVisibleToNeighbors && mounted) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        publishNeighborMapVisibilityUnawaited(
          position: pos,
          avatar: _neighborAvatarCache[uid] ?? '🙂',
          displayName: _neighborDisplayNameCache[uid] ?? 'Vecin',
          isDriver: _currentRole == UserRole.driver && _isDriverAvailable,
          licensePlate: _neighborLicensePlateCache[uid],
          photoURL: _neighborPhotoURLCache[uid],
          allowedUids: _contactUids?.toList() ?? [],
          isPulsing: false,
          carAvatarId: _effectivePublishedCarAvatarId(
            uid,
            useDriverGarageSlot: _currentRole == UserRole.driver,
          ),
        );
      }
    }
    
    Logger.info('Pulse Mode stopped');
  }

  void _checkForPulseMatches() {
    if (_lastRawNeighborsForMap.isEmpty) return;
    
    // Căutăm vecini care au isPulsing: true
    final pulsingNeighbors = _lastRawNeighborsForMap.where((n) => n.isPulsing).toList();
    
    if (pulsingNeighbors.isNotEmpty) {
      Logger.info('SOCIAL MATCH! ${pulsingNeighbors.length} neighbors are pulsing nearby.');
      HapticFeedback.heavyImpact();
      
      // Notificare vizuală
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Te-ai conectat cu ${pulsingNeighbors.first.displayName} și încă ${pulsingNeighbors.length - 1} vecini!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7C3AED), // Nabour Purple
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      
      // Sunet de succes
      _audioService.playMessageReceivedSound();
    }
  }
  /// ✅ CONECTARE: Quick route update pentru POI changes
  Future<void> _updateRouteAfterPOI() async {
    if (_pickupLatitude != null && _destinationLatitude != null) {
      try {
        final List<Point> waypoints = [];
        waypoints.add(Point(coordinates: Position(_pickupLongitude!, _pickupLatitude!)));
        for (final stop in _intermediateStops) {
          final coord = await _getCoordinatesForDestination(stop);
          if (coord != null) waypoints.add(coord);
        }
        waypoints.add(Point(coordinates: Position(_destinationLongitude!, _destinationLatitude!)));
        
        await _onRouteCalculated(await _routingService.getRoute(waypoints));
      } catch (e) {
        Logger.error('Route update after POI error: $e', error: e);
      }
    }
  }

  void _listenToShake() {
    _accelerometerSubscription = userAccelerometerEventStream().listen(
      (event) {
        final double acceleration = math.sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z);
        if (acceleration > _shakeThreshold && !_isPulseActive) {
          final now = DateTime.now();
          if (now.difference(_lastShakeTime) > _shakeWindow) {
            _shakeCount = 0;
          }
          _shakeCount++;
          _lastShakeTime = now;
          if (_shakeCount >= _requiredShakes) {
            _shakeCount = 0;
            _startPulseMode();
          }
        }
      },
      onError: (Object e) {
        _accelerometerSubscription?.cancel();
        _accelerometerSubscription = null;
        final s = e.toString();
        if (s.contains('NO_SENSOR') || s.contains('Sensor not found')) {
          Logger.debug(
            'Pulse shake: dispozitiv fără accelerometru user (ex. unele tablete) — modul shake ignorat.',
            tag: 'MAP',
          );
          return;
        }
        Logger.error('Pulse mode shake error: $e');
      },
      cancelOnError: true,
    );
  }

  void _showSafeSnackBar(String message, Color backgroundColor, {SnackBarAction? action}) {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          action: action,
        ),
      );
    } catch (_) {}
  }

  Future<Uint8List> _generateParkingIcon(bool isReserved) async {
    const double size = 100;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, size, size));
    final paint = ui.Paint()..isAntiAlias = true;

    // 1. GALAXY GLOW
    paint
      ..color = Colors.amber.withValues(alpha: 0.3)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12);
    canvas.drawCircle(const ui.Offset(size / 2, size / 2), 35, paint);
    paint.maskFilter = null;

    // 2. NEON RING
    paint
      ..color = Colors.amber
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const ui.Offset(size / 2, size / 2), 30, paint);

    // 3. INNER BG
    paint
      ..color = const Color(0xFF1A237E)
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(const ui.Offset(size / 2, size / 2), 28, paint);

    // 4. DRAW "P"
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'P',
        style: TextStyle(
          color: Colors.amber,
          fontSize: 38,
          fontWeight: FontWeight.w900,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      ui.Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _clearParkingYieldTarget() async {
    _parkingYieldTargetLat = null;
    _parkingYieldTargetLng = null;
    _awaitingParkingYieldMapPick = false;
    if (_parkingYieldMySpotAnnotation != null && _parkingYieldMySpotManager != null) {
      try {
        await _parkingYieldMySpotManager!.delete(_parkingYieldMySpotAnnotation!);
      } catch (_) {}
    }
    _parkingYieldMySpotAnnotation = null;
    if (mounted) setState(() {});
  }

  Future<void> _updateParkingYieldMySpotMarker() async {
    if (_mapboxMap == null || !mounted) return;
    final lat = _parkingYieldTargetLat;
    final lng = _parkingYieldTargetLng;
    if (lat == null || lng == null) return;

    _parkingYieldMySpotManager ??= await _mapboxMap!.annotations.createPointAnnotationManager(
      id: 'parking-yield-my-spot',
    );
    if (_parkingYieldMySpotAnnotation != null) {
      try {
        await _parkingYieldMySpotManager!.delete(_parkingYieldMySpotAnnotation!);
      } catch (_) {}
      _parkingYieldMySpotAnnotation = null;
    }
    _parkingIconInFlight ??= _generateParkingIcon(false);
    final iconBytes = await _parkingIconInFlight!;
    final ann = await _parkingYieldMySpotManager!.create(
      PointAnnotationOptions(
        geometry: MapboxUtils.createPoint(lat, lng),
        image: iconBytes,
        iconSize: 0.92,
        textField: 'LOCUL MEU',
        textColor: Colors.lightGreenAccent.toARGB32(),
        textHaloColor: Colors.black.toARGB32(),
        textHaloWidth: 2.0,
        textSize: 9,
        textOffset: [0.0, 2.5],
      ),
    );
    _parkingYieldMySpotAnnotation = ann;
  }

  Future<void> _applyParkingYieldTarget(double lat, double lng) async {
    _parkingYieldTargetLat = lat;
    _parkingYieldTargetLng = lng;
    await _updateParkingYieldMySpotMarker();
    if (!mounted) return;
    setState(() {});
    final map = _mapboxMap;
    if (map != null) {
      try {
        await map.flyTo(
          CameraOptions(center: MapboxUtils.createPoint(lat, lng), zoom: 16.2),
          MapAnimationOptions(duration: 650),
        );
      } catch (_) {}
    }
  }

  Future<void> _finishParkingYieldMapPick(Point point) async {
    if (!mounted) return;
    setState(() => _awaitingParkingYieldMapPick = false);
    final lat = point.coordinates.lat.toDouble();
    final lng = point.coordinates.lng.toDouble();
    await _applyParkingYieldTarget(lat, lng);
    if (!mounted) return;
    _showSafeSnackBar(
      'Loc marcat după coordonate. Poți porni navigarea din meniul parcare când ești departe.',
      Colors.green.shade700,
    );
  }

  Future<void> _showEstablishParkingYieldDialog() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Identifică locul de parcare',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Mai întâi stabilim punctul exact pe hartă (coordenate). '
          'Apoi te poți ghida navigând la el; când ești în zonă, poți face locul disponibil pentru vecini.',
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Anulează', style: TextStyle(color: Colors.grey.shade400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'map'),
            child: const Text('Pe hartă', style: TextStyle(color: Colors.amber)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'gps'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Unde sunt acum', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'gps') {
      final p = _currentPositionObject;
      if (p == null) return;
      await _applyParkingYieldTarget(p.latitude, p.longitude);
      _showSafeSnackBar(
        'Loc setat la poziția curentă. Dacă nu ești la parcare, folosește „Navighează” din același buton.',
        Colors.amber.shade800,
      );
    } else if (choice == 'map') {
      setState(() => _awaitingParkingYieldMapPick = true);
      _showSafeSnackBar(
        'Ține apăsat pe hartă exact la locul de parcare.',
        Colors.amber.shade800,
      );
    }
  }

  Future<void> _showNavigateToParkingYieldSheet(double distanceM) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final r = _parkingYieldVerifyRadiusM.round();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Încă nu ești la locul marcat',
                  style: TextStyle(
                    color: Colors.amber.shade200,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'GPS-ul tău e la circa ${distanceM.round()} m față de coordonatele locului. '
                  'Navighează la punctul „LOCUL MEU”; când distanța e sub $r m, poți disponibiliza locul.',
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final la = _parkingYieldTargetLat;
                    final ln = _parkingYieldTargetLng;
                    if (la == null || ln == null) return;
                    unawaited(_startInAppNavigation(la, ln, 'Locul tău de parcare'));
                  },
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Navighează la locul marcat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _clearParkingYieldTarget();
                  },
                  child: const Text('Șterge marcajul și începe din nou'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Închide'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndAnnounceParkingYield() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Disponibilizezi locul?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Coordonatele marcate vor fi anunțate ca loc liber. '
          'Primești tokeni dacă un vecin îl ocupă.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NU', style: TextStyle(color: Colors.amber)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('DA', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final la = _parkingYieldTargetLat;
    final ln = _parkingYieldTargetLng;
    if (la == null || ln == null) return;

    final id = await ParkingSwapService().announceLeaving(la, ln);
    if (!mounted) return;
    if (id != null) {
      await _clearParkingYieldTarget();
      _showSafeSnackBar('Locul a fost anunțat disponibil.', Colors.green.shade700);
    } else {
      _showSafeSnackBar('Nu s-a putut anunța. Încearcă din nou.', Colors.red.shade800);
    }
  }

  void _showParkingSwapDialog(String firestoreSpotId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ParkingReservationSheet(
        spotId: firestoreSpotId,
        onReserved: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loc rezervat! Ai 3 minute să ajungi.')),
          );
        },
      ),
    );
  }

  void _handleLeavingParking() async {
    if (!mounted) return;

    if (_awaitingParkingYieldMapPick) {
      setState(() => _awaitingParkingYieldMapPick = false);
      _showSafeSnackBar('Selecția pe hartă a fost anulată.', Colors.grey.shade700);
      return;
    }

    if (_currentPositionObject == null) {
      _showSafeSnackBar(
        'Activează locația ca să folosești schimbul de parcare.',
        Colors.orange.shade800,
      );
      return;
    }

    if (_parkingYieldTargetLat == null || _parkingYieldTargetLng == null) {
      await _showEstablishParkingYieldDialog();
      return;
    }

    final pos = _currentPositionObject!;
    final dist = geolocator.Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      _parkingYieldTargetLat!,
      _parkingYieldTargetLng!,
    );

    if (dist > _parkingYieldVerifyRadiusM) {
      await _showNavigateToParkingYieldSheet(dist);
      return;
    }

    await _confirmAndAnnounceParkingYield();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLASE AUXILIARE (PROFILE SHEETS, OVERLAYS)
// ─────────────────────────────────────────────────────────────────────────────

class _NeighborProfileSheet extends StatefulWidget {
  final NeighborLocation neighbor;
  final double distanceKm;
  final String timeLabel;
  final String? phoneNumber;
  final VoidCallback onMessage;
  final Function(String) onSendReaction;
  final VoidCallback? onCall;
  final VoidCallback onSendEta;
  final VoidCallback onHonk;
  /// Bulă „cerere în cartier” ancorată lângă poziția lor pe hartă.
  final VoidCallback onNeighborhoodRequest;
  /// Emoji vizibil pe hartă la coordonatele lor (nu în chat).
  final void Function(String emoji) onSendMapEmoji;

  const _NeighborProfileSheet({
    required this.neighbor,
    required this.distanceKm,
    required this.timeLabel,
    this.phoneNumber,
    required this.onMessage,
    required this.onSendReaction,
    this.onCall,
    required this.onHonk,
    required this.onSendEta,
    required this.onNeighborhoodRequest,
    required this.onSendMapEmoji,
  });

  @override
  State<_NeighborProfileSheet> createState() => _NeighborProfileSheetState();
}

class _NeighborProfileSheetState extends State<_NeighborProfileSheet> {
  String _address = '';
  bool _etaDismissed = false;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        widget.neighbor.lat,
        widget.neighbor.lng,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        if (mounted) {
          setState(() {
            _address = p.street ?? '';
            if (_address.isEmpty) {
              _address = (p.subLocality ?? p.locality ?? '').trim();
            }
            if (_address.isEmpty) _address = 'Locatie necunoscuta';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _address = 'Locatie necunoscuta');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.grey.shade600 : Colors.grey.shade300;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.blueGrey;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 30, spreadRadius: 0),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: subtleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header: Street name + action icons ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _address.isNotEmpty ? _address : '...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              _HeaderIconButton(
                icon: Icons.campaign_rounded,
                color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                bgColor: isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade50,
                onTap: () {
                  widget.onHonk();
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.phone_rounded,
                color: widget.onCall != null
                    ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                bgColor: widget.onCall != null
                    ? (isDark ? Colors.green.shade900.withValues(alpha: 0.4) : Colors.green.shade50)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                onTap: widget.onCall ?? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Numar de telefon indisponibil'), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Time label + Avatar ──
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.neighbor.avatar.isNotEmpty ? widget.neighbor.avatar : '🙂',
                  style: const TextStyle(fontSize: 56),
                ),
              ),
              Positioned(
                top: -14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.timeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: labelColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── ETA banner ──
          if (!_etaDismissed)
            GestureDetector(
              onTap: widget.onSendEta,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : const Color(0xFFF1F5F9),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Va vedeti cu cineva? Trimite-ti ETA-ul live',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _etaDismissed = true),
                      child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),

          if (!_etaDismissed) const SizedBox(height: 16),

          Text(
            'Contact: ${widget.neighbor.displayName}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 12),

          // ── Message button (green pill) ──
          Row(
            children: [
              // Avatar mic stanga
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.neighbor.avatar.isNotEmpty ? widget.neighbor.avatar : '🙂',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mesaj privat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Distance badge dreapta
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.distanceKm < 1
                      ? '${(widget.distanceKm * 1000).round()} m'
                      : '${widget.distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onNeighborhoodRequest,
              icon: Icon(Icons.water_drop_outlined, color: Colors.indigo.shade700),
              label: Text(
                'Cerere în cartier (bulă pe hartă)',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.indigo.shade800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.indigo.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Emoji pe hartă (lângă ei)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: labelColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kNeighborQuickMapEmojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final em = _kNeighborQuickMapEmojis[i];
                return Material(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => widget.onSendMapEmoji(em),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: Text(em, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sticker-e în chat',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: labelColor,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Emoji reactions grid (2 rows of stickers) ──
          SizedBox(
            height: 180,
            child: GridView.count(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
              physics: const BouncingScrollPhysics(),
              children: _kReactions.map((r) {
                return _ReactionItem(
                  emoji: r['emoji']!,
                  label: r['label']!,
                  labelColor: labelColor,
                  bgColor: isDark ? Colors.grey.shade800 : Colors.white,
                  onTap: () => widget.onSendReaction(r['emoji']!),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Emoji rapide plasate pe hartă la poziția contactului (tap pe marker).
const List<String> _kNeighborQuickMapEmojis = [
  '\u2764\uFE0F',
  '👋',
  '🔥',
  '😂',
  '👍',
  '🎉',
  '📍',
  '☕',
];

const List<Map<String, String>> _kReactions = [
  {'emoji': '👍', 'label': 'Thumbs'},
  {'emoji': '🔥', 'label': 'Fire'},
  {'emoji': '😍', 'label': 'Yesssss'},
  {'emoji': '💩', 'label': 'Poop Girl'},
  {'emoji': '🤡', 'label': 'Actooor'},
  {'emoji': '❤️', 'label': 'Inimoare'},
  {'emoji': '💥', 'label': 'Stric'},
  {'emoji': '👀', 'label': 'Ochi'},
  {'emoji': '😭', 'label': 'Cry cry'},
  {'emoji': '👋', 'label': 'Hello!'},
  {'emoji': '🍺', 'label': 'Bei ceva?'},
  {'emoji': '🎉', 'label': 'Party'},
  {'emoji': '💀', 'label': 'Dead'},
  {'emoji': '🤣', 'label': 'LOL'},
  {'emoji': '🙏', 'label': 'Mersi'},
];

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _ReactionItem extends StatelessWidget {
  final String emoji;
  final String label;
  final Color labelColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _ReactionItem({
    required this.emoji,
    required this.label,
    required this.labelColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, // ✅ Redus de la 56 pentru a evita overflow de 8px
            height: 52, // ✅ Redus de la 56
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 28)), // ✅ Redus font de la 32
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Geocoding o singură dată per deschidere sheet — nu re-intră în serviciu la rebuild-uri locale.
class _MapTapGeocodeSheetBody extends StatefulWidget {
  const _MapTapGeocodeSheetBody({
    required this.lat,
    required this.lng,
    required this.sheetContext,
    required this.mapScreenContext,
    required this.onOpenFavorite,
  });

  final double lat;
  final double lng;
  final BuildContext sheetContext;
  final BuildContext mapScreenContext;
  final Future<void> Function(double lat, double lng, String address) onOpenFavorite;

  @override
  State<_MapTapGeocodeSheetBody> createState() => _MapTapGeocodeSheetBodyState();
}

class _MapTapGeocodeSheetBodyState extends State<_MapTapGeocodeSheetBody> {
  late final Future<String?> _addressFuture = GeocodingService()
      .getAddressFromCoordinates(widget.lat, widget.lng);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _addressFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final address = snap.data != null && snap.data!.trim().isNotEmpty
            ? snap.data!.trim()
            : 'Locație pe hartă';
        final lat = widget.lat;
        final lng = widget.lng;
        final sheetCtx = widget.sheetContext;
        final mapCtx = widget.mapScreenContext;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              address,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Colors.amber),
              title: const Text('Adaugă la adrese favorite'),
              onTap: () {
                Navigator.pop(sheetCtx);
                unawaited(widget.onOpenFavorite(lat, lng, address));
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation_outlined, color: Colors.green),
              title: const Text('Navighează cu Google Maps / Waze'),
              onTap: () {
                Navigator.pop(sheetCtx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mapCtx.mounted) return;
                  ExternalMapsLauncher.showNavigationChooser(mapCtx, lat, lng);
                });
              },
            ),
          ],
        );
      },
    );
  }
}

/// Overlay căutare universală (contacte + locuri), stil card alb rotunjit peste hartă semi-întunecată.
class MapUniversalSearchOverlay extends StatefulWidget {
  const MapUniversalSearchOverlay({
    super.key,
    required this.onClose,
    required this.contacts,
    required this.friendPeerUids,
    required this.visibleNeighbors,
    required this.neighborEmojiByUid,
    required this.neighborPhotoUrlByUid,
    required this.userPosition,
    required this.onPlaceChosen,
    required this.onContactChosen,
    this.onAddFriend,
  });

  final VoidCallback onClose;
  final List<ContactAppUser> contacts;
  final Set<String> friendPeerUids;
  final List<NeighborLocation> visibleNeighbors;
  /// Emoji-uri din fluxul hărții (aceeași sursă ca Sugestii prieteni).
  final Map<String, String> neighborEmojiByUid;
  final Map<String, String> neighborPhotoUrlByUid;
  final geolocator.Position? userPosition;

  final void Function(double lat, double lng, String label) onPlaceChosen;
  final void Function(String uid) onContactChosen;
  final Future<void> Function(String uid)? onAddFriend;

  @override
  State<MapUniversalSearchOverlay> createState() =>
      _MapUniversalSearchOverlayState();
}

class _MapUniversalSearchPlaceRow {
  const _MapUniversalSearchPlaceRow(this.suggestion, this.fromLocalBundle);

  final AddressSuggestion suggestion;
  final bool fromLocalBundle;
}

class _MapUniversalSearchOverlayState extends State<MapUniversalSearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  List<_MapUniversalSearchPlaceRow> _placeRows = [];
  bool _placesLoading = false;
  bool _peopleExpanded = false;
  Map<String, int> _friendCountByUid = {};
  Map<String, int> _mutualFriendPeersByUid = {};
  bool _metricsLoading = true;
  StreamSubscription<List<SavedAddress>>? _savedAddressesSub;
  List<SavedAddress> _savedAddresses = <SavedAddress>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
    unawaited(_loadPeopleMetrics());
    _savedAddressesSub = FirestoreService().getSavedAddresses().listen((list) {
      if (mounted) setState(() => _savedAddresses = list);
    });
  }

  Future<void> _loadPeopleMetrics() async {
    final uids = <String>{
      ...widget.contacts.map((c) => c.uid),
      ...widget.visibleNeighbors.map((n) => n.uid),
    };
    if (uids.isEmpty) {
      if (mounted) setState(() => _metricsLoading = false);
      return;
    }
    final m = await MapUniversalSearchMetricsService.instance.loadPeopleMetrics(
      candidateUids: uids,
      myFriendPeerUids: widget.friendPeerUids,
    );
    if (!mounted) return;
    setState(() {
      _friendCountByUid = m.friendCountByUid;
      _mutualFriendPeersByUid = m.mutualFriendPeersByUid;
      _metricsLoading = false;
    });
  }

  @override
  void dispose() {
    _savedAddressesSub?.cancel();
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<AddressSuggestion> _savedAddressSuggestions(
    String trimmed,
    geolocator.Position pos,
  ) {
    final qn = normalizeRomanianTextForSearch(trimmed);
    if (qn.length < 2) return [];
    final scored = <({SavedAddress a, double sc})>[];
    for (final addr in _savedAddresses) {
      final sc = savedAddressMatchScoreNormalized(qn, addr);
      if (sc > 0) scored.add((a: addr, sc: sc));
    }
    scored.sort((x, y) => y.sc.compareTo(x.sc));
    return scored.map((e) {
      final addr = e.a;
      final dist = geolocator.Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        addr.coordinates.latitude,
        addr.coordinates.longitude,
      );
      return AddressSuggestion(
        description: savedAddressDisplayLine(addr),
        latitude: addr.coordinates.latitude,
        longitude: addr.coordinates.longitude,
        score: (100 * e.sc).round().clamp(1, 999),
        distanceMeters: dist,
      );
    }).toList();
  }

  List<_MapUniversalSearchPlaceRow> _mergePlaceRowsWithSaved(
    List<AddressSuggestion> saved,
    List<AddressSuggestion> local,
    List<AddressSuggestion> remote,
  ) {
    final out = <_MapUniversalSearchPlaceRow>[];
    bool isDup(AddressSuggestion s) {
      return out.any((row) {
        final o = row.suggestion;
        return geolocator.Geolocator.distanceBetween(
              o.latitude,
              o.longitude,
              s.latitude,
              s.longitude,
            ) <
            85;
      });
    }

    void addAll(List<AddressSuggestion> list, bool fromLocalBundle) {
      for (final s in list) {
        if (!isDup(s)) {
          out.add(_MapUniversalSearchPlaceRow(s, fromLocalBundle));
        }
      }
    }

    addAll(saved, true);
    addAll(local, true);
    addAll(remote, false);
    return out.take(16).toList();
  }

  bool _nameMatches(String name, String q) {
    if (q.trim().isEmpty) return true;
    return name.toLowerCase().contains(q.toLowerCase().trim());
  }

  void _schedulePlacesSearch(String q) {
    _debounce?.cancel();
    final trimmed = q.trim();
    if (trimmed.length < 2) {
      setState(() {
        _placeRows = [];
        _placesLoading = false;
      });
      return;
    }
    final pos = widget.userPosition;
    if (pos == null) {
      setState(() {
        _placeRows = [];
        _placesLoading = false;
      });
      return;
    }
    setState(() => _placesLoading = true);
    _debounce = Timer(const Duration(milliseconds: 380), () async {
      List<_MapUniversalSearchPlaceRow> rows;
      try {
        final saved = _savedAddressSuggestions(trimmed, pos);
        final local = await LocalAddressDatabase().search(trimmed, pos);
        final remote = await GeocodingService().fetchSuggestions(trimmed, pos);
        rows = _mergePlaceRowsWithSaved(saved, local, remote);
      } catch (_) {
        rows = [];
      }
      if (!mounted) return;
      setState(() {
        _placeRows = rows;
        _placesLoading = false;
      });
    });
  }

import 'map/map_voice_controller.dart';
    final t = name.trim();
    if (t.isEmpty) return '?';
    final parts =
        t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
          .toUpperCase();
    }
    final one = parts.isNotEmpty ? parts[0] : t;
    if (one.length >= 3) return one.substring(0, 3).toUpperCase();
    return one.toUpperCase();
  }

  Widget _placeLeading(String title, {bool fromLocal = false}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF3949AB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _placeInitials(title),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _contactLeading(String uid, String displayName) {
    final url = widget.neighborPhotoUrlByUid[uid];
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(url));
    }
    final em = widget.neighborEmojiByUid[uid];
    if (em != null && em.isNotEmpty && em.length <= 8) {
      return CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Text(em, style: const TextStyle(fontSize: 22)),
      );
    }
    return CircleAvatar(
      backgroundColor: const Color(0xFF3949AB),
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _personSubtitle(String uid) {
    final isFriend = widget.friendPeerUids.contains(uid);
    final mutual = _mutualFriendPeersByUid[uid] ?? 0;
    final fc = _friendCountByUid[uid] ?? 0;

    if (mutual > 0) {
      return 'Cunoaște $mutual ${mutual == 1 ? 'prieten' : 'prieteni'}';
    }
    if (fc > 0) {
      if (fc > 50) {
        return isFriend ? 'Prieten în Nabour · 50+ prieteni' : '50+ prieteni';
      }
      return isFriend ? 'Prieten în Nabour · $fc prieteni' : '$fc prieteni';
    }
    if (isFriend) return 'Prieten în Nabour';
    if (widget.visibleNeighbors.any((n) => n.uid == uid)) {
      return 'Pe hartă acum';
    }
    return 'În agendă (Nabour)';
  }

  String _neighborRowSubtitle(NeighborLocation n) {
    final social = _personSubtitle(n.uid);
    final diffMin = DateTime.now().difference(n.lastUpdate).inMinutes;
    final time = diffMin <= 1 ? 'acum' : 'acum $diffMin min';
    if (!_metricsLoading &&
        (social.contains('prieteni') || social.contains('Cunoaște'))) {
      return '$social · pe hartă $time';
    }
    if (diffMin <= 1) return 'Pe hartă · actualizat acum';
    return 'Pe hartă · actualizat $time';
  }

  List<ContactAppUser> _matchingContacts(String q) {
    final out =
        widget.contacts.where((c) => _nameMatches(c.displayName, q)).toList();
    out.sort((a, b) {
      final ma = _mutualFriendPeersByUid[a.uid] ?? 0;
      final mb = _mutualFriendPeersByUid[b.uid] ?? 0;
      if (ma != mb) return mb.compareTo(ma);
      final fa = widget.friendPeerUids.contains(a.uid);
      final fb = widget.friendPeerUids.contains(b.uid);
      if (fa != fb) return fa ? -1 : 1;
      final ca = _friendCountByUid[a.uid] ?? 0;
      final cb = _friendCountByUid[b.uid] ?? 0;
      if (ca != cb) return cb.compareTo(ca);
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return out;
  }

  List<NeighborLocation> _neighborOnlyMatches(String q) {
    if (q.trim().isEmpty) return [];
    final contactUids = widget.contacts.map((c) => c.uid).toSet();
    final list = widget.visibleNeighbors
        .where(
          (n) =>
              _nameMatches(n.displayName, q) && !contactUids.contains(n.uid),
        )
        .toList();
    list.sort((a, b) {
      final ma = _mutualFriendPeersByUid[a.uid] ?? 0;
      final mb = _mutualFriendPeersByUid[b.uid] ?? 0;
      if (ma != mb) return mb.compareTo(ma);
      final ca = _friendCountByUid[a.uid] ?? 0;
      final cb = _friendCountByUid[b.uid] ?? 0;
      if (ca != cb) return cb.compareTo(ca);
      return a.displayName
          .toLowerCase()
          .compareTo(b.displayName.toLowerCase());
    });
    return list;
  }

  String _formatDistanceKm(double? meters) {
    if (meters == null) return '';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final q = _controller.text;

    final contactsShown = _matchingContacts(q);
    final neighborsShown = _neighborOnlyMatches(q);
    final peopleCap = _peopleExpanded ? 24 : 5;
    final peopleTotal = contactsShown.length + neighborsShown.length;
    final takeContacts = peopleCap.clamp(0, contactsShown.length);
    final remaining = peopleCap - takeContacts;
    final takeNeighbors = remaining.clamp(0, neighborsShown.length);

    return Material(
      color: Colors.black45,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: MediaQuery.of(context).padding.top + 6,
            bottom: 96 + bottomSafe + bottomInset,
            child: GestureDetector(
              onTap: () {},
              child: Material(
                elevation: 12,
                shadowColor: Colors.black38,
                borderRadius: BorderRadius.circular(22),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Caută prieteni și locuri...',
                          border: InputBorder.none,
                          isDense: true,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          suffixIcon: q.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: Colors.black54),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() {
                                      _placeRows = [];
                                      _placesLoading = false;
                                    });
                                    _focus.requestFocus();
                                  },
                                )
                              : const Icon(Icons.search_rounded,
                                  color: Colors.black38),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        onChanged: (v) {
                          setState(() {});
                          _schedulePlacesSearch(v);
                        },
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [
                          if (q.trim().isEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 14, 16, 6),
                              child: Text(
                                'Sugerat',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ] else ...[
                            if (contactsShown.isNotEmpty ||
                                neighborsShown.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 12, 16, 6),
                                child: Text(
                                  'Utilizatori',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                          ],
                          for (final c in contactsShown.take(takeContacts))
                            _userTile(
                              leading:
                                  _contactLeading(c.uid, c.displayName),
                              title: c.displayName,
                              subtitle: _personSubtitle(c.uid),
                              uid: c.uid,
                              mutualBadge:
                                  _mutualFriendPeersByUid[c.uid] ?? 0,
                              showAdd: !widget.friendPeerUids.contains(c.uid),
                            ),
                          for (final n in neighborsShown.take(takeNeighbors))
                            _userTile(
                              leading: n.photoURL != null &&
                                      n.photoURL!.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(n.photoURL!),
                                    )
                                  : _contactLeading(n.uid, n.displayName),
                              title: n.displayName,
                              subtitle: _neighborRowSubtitle(n),
                              uid: n.uid,
                              mutualBadge:
                                  _mutualFriendPeersByUid[n.uid] ?? 0,
                              showAdd:
                                  !widget.friendPeerUids.contains(n.uid),
                            ),
                          if (peopleTotal > peopleCap)
                            TextButton(
                              onPressed: () => setState(
                                  () => _peopleExpanded = !_peopleExpanded),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _peopleExpanded
                                        ? 'Mai puțini utilizatori'
                                        : 'VEZI MAI MULȚI UTILIZATORI',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Icon(
                                    _peopleExpanded
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                  ),
                                ],
                              ),
                            ),
                          if (q.trim().length >= 2 &&
                              widget.userPosition != null) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 6),
                              child: Text(
                                'Locuri',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            if (_placesLoading)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5),
                                  ),
                                ),
                              )
                            else if (_placeRows.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Text(
                                  'Nu am găsit locuri pentru „$q”.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            for (final row in _placeRows.take(12))
                              ListTile(
                                leading: _placeLeading(
                                  row.suggestion.description
                                      .split(',')
                                      .first
                                      .trim(),
                                  fromLocal: row.fromLocalBundle,
                                ),
                                title: Text(
                                  row.suggestion.description
                                      .split(',')
                                      .first
                                      .trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    _formatDistanceKm(
                                        row.suggestion.distanceMeters),
                                    if (row.fromLocalBundle)
                                      'În datele Nabour',
                                    row.suggestion.description,
                                  ].where((e) => e.isNotEmpty).join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                onTap: () {
                                  widget.onPlaceChosen(
                                    row.suggestion.latitude,
                                    row.suggestion.longitude,
                                    row.suggestion.description,
                                  );
                                  widget.onClose();
                                },
                              ),
                          ],
                        ],
                      ),
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

  Widget _userTile({
    required Widget leading,
    required String title,
    required String subtitle,
    required String uid,
    required int mutualBadge,
    required bool showAdd,
  }) {
    return ListTile(
      leading: leading,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          if (mutualBadge > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$mutualBadge ${mutualBadge == 1 ? 'comun' : 'comuni'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: showAdd && widget.onAddFriend != null
          ? Material(
              color: const Color(0xFF3949AB),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  await widget.onAddFriend!(uid);
                  if (mounted) setState(() {});
                },
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            )
          : null,
      onTap: () {
        widget.onContactChosen(uid);
        widget.onClose();
      },
    );
  }
}

class _ParkingReservationSheet extends StatefulWidget {
  final String spotId;
  final VoidCallback onReserved;

  const _ParkingReservationSheet({required this.spotId, required this.onReserved});

  @override
  _ParkingReservationSheetState createState() => _ParkingReservationSheetState();
}

class _ParkingReservationSheetState extends State<_ParkingReservationSheet> {
  bool _isReserving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.local_parking_rounded, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          const Text(
            'LOC DE AUR DETECTAT',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
  Future<void> _reserve() async {
    setState(() => _isReserving = true);
    final success = await ParkingSwapService().reserveSpot(widget.spotId);
    if (mounted) {
      setState(() => _isReserving = false);
      if (success) {
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isReserving ? null : _reserve,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isReserving 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('REZERVĂ LOCUL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _reserve() async {
    setState(() => _isReserving = true);
    final success = await ParkingSwapService().reserveSpot(widget.spotId);
    if (mounted) {
      setState(() => _isReserving = false);
      if (success) {
        widget.onReserved();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ne pare rău, locul a fost deja rezervat.')),
        );
      }
    }
  }
}
