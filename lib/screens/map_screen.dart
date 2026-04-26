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
import 'package:provider/provider.dart';

import 'package:nabour_app/services/audio_service.dart';
import 'package:nabour_app/services/app_sound_service.dart';
import 'package:nabour_app/services/context_engine_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nabour_app/providers/map_settings_provider.dart';
import 'package:nabour_app/providers/map_camera_provider.dart';
import 'package:nabour_app/widgets/map/map_ripple_effect.dart';
import 'package:nabour_app/widgets/map/osm_map_widget.dart';
import 'package:nabour_app/widgets/map/animated_avatar_marker.dart';
import 'package:nabour_app/widgets/map/floating_marker_wrapper.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_map/flutter_map.dart' as fm;

import '../utils/mapbox_utils.dart';
import '../utils/driver_icon_helper.dart';
import '../utils/deprecated_apis_fix.dart';
import 'package:nabour_app/models/ride_model.dart';
import 'package:nabour_app/screens/driver_ride_pickup_screen.dart';
import 'package:nabour_app/screens/ride_summary_screen.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/passenger_ride_session_bus.dart';
import 'package:nabour_app/services/location_cache_service.dart';
import 'package:nabour_app/widgets/app_drawer.dart';
import 'package:nabour_app/config/nabour_map_styles.dart';
import 'package:nabour_app/screens/personal_info_screen.dart';
import 'package:nabour_app/widgets/ride_request_panel.dart';
import 'package:nabour_app/screens/business_offers_screen.dart';
import 'package:nabour_app/voice/integration/friends_voice_integration.dart';
import 'package:nabour_app/utils/permission_manager.dart';
import 'package:nabour_app/voice/driver/driver_voice_controller.dart';
import 'package:nabour_app/voice/states/voice_interaction_states.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// POI interactive model
import 'package:nabour_app/models/poi_model.dart';
import 'package:nabour_app/services/routing_service.dart';
import 'package:nabour_app/screens/searching_for_driver_screen.dart';
import 'package:nabour_app/core/animations/app_transitions.dart';
import 'package:nabour_app/core/haptics/haptic_service.dart';
import 'package:nabour_app/features/cancellation/cancellation_dialog.dart';
import 'package:nabour_app/features/cancellation/cancellation_model.dart';
import 'package:nabour_app/features/cancellation/cancellation_service.dart';
import 'package:nabour_app/features/smart_suggestions/smart_suggestions_widget.dart';
import 'package:nabour_app/features/smart_suggestions/smart_suggestions_service.dart';
import 'package:nabour_app/features/smart_suggestions/smart_suggestion_model.dart';
import 'package:nabour_app/features/ghost_mode/ghost_mode_sheet.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_profile_sheet.dart';
import 'package:nabour_app/features/map_screen/widgets/map_tap_geocode_sheet.dart';
import 'package:nabour_app/features/map_screen/controllers/map_badges_controller.dart';
import 'package:nabour_app/features/map_screen/controllers/map_route_controller.dart';
import 'package:nabour_app/features/map_screen/widgets/parking_reservation_sheet.dart';
import 'package:nabour_app/features/map_screen/widgets/map_hud_widgets.dart';
import 'package:nabour_app/features/map_screen/widgets/map_universal_search_overlay.dart';
import 'package:nabour_app/features/push_campaigns/push_campaign_service.dart';
import 'package:nabour_app/services/buc_locations_db.dart';
import 'package:nabour_app/services/geocoding_service.dart';
import 'package:nabour_app/models/saved_address_model.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/widgets/assistant_status_overlay.dart';
import 'package:nabour_app/services/connectivity_service.dart';
import 'package:nabour_app/services/app_initializer.dart';
import 'package:nabour_app/providers/assistant_status_provider.dart';
import 'package:nabour_app/widgets/map/map_voice_overlay.dart';
import 'package:nabour_app/widgets/map/map_drv_offer_sheet.dart';
import 'package:nabour_app/widgets/map/map_poi_card.dart';
import 'package:nabour_app/widgets/map/map_poi_category_chips.dart';
import 'package:nabour_app/services/poi_service.dart';

import 'package:nabour_app/widgets/map/map_driver_interface.dart';
import 'package:nabour_app/widgets/map/map_ride_info_panel.dart';
import 'package:nabour_app/widgets/map/map_intermediate_stops.dart';
import 'package:nabour_app/widgets/map/radar_alert_banner.dart';
import 'package:nabour_app/utils/logger.dart';

import 'package:nabour_app/models/neighbor_location_model.dart';
import 'package:nabour_app/services/neighbor_location_service.dart';
import 'package:nabour_app/features/map_neighbor_markers/nbr_activity_feed_panel.dart';
import 'package:nabour_app/features/map_neighbor_markers/nbr_friend_marker_icons.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_device_telemetry.dart';
import 'package:nabour_app/features/map_neighbor_markers/nbr_marker_layout.dart';
import 'package:nabour_app/features/map_neighbor_markers/nbr_map_feed_controller.dart';
import 'package:nabour_app/features/map_neighbor_markers/nbr_map_vis_publish.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_saved_places_cache.dart';
import 'package:nabour_app/features/map_neighbor_markers/neighbor_stationary_tracker.dart';
import 'package:nabour_app/features/neighbor_bump/neighbor_bump_match_overlay.dart';
import 'package:nabour_app/features/ble_bump/ble_bump_service.dart';
import 'package:nabour_app/features/ble_bump/ble_bump_bridge.dart';
import 'package:nabour_app/features/smart_places/smart_places_db.dart';
import 'package:nabour_app/features/activity_feed/activity_feed_service.dart';
import 'package:nabour_app/features/activity_feed/activity_feed_writer.dart';
import 'package:nabour_app/features/radar_alerts/radar_alerts_map_manager.dart';
import 'package:nabour_app/features/map_moments/map_moment_service.dart';
import 'package:nabour_app/features/map_moments/map_moment_model.dart';
import 'package:nabour_app/features/map_moments/post_moment_sheet.dart';
import 'package:nabour_app/features/neighborhood_requests/nbhd_requests_manager.dart';
import 'package:nabour_app/services/nbr_telem_rtdb_service.dart';
import 'package:nabour_app/services/walkie_talkie_service.dart';
import 'package:nabour_app/services/open_meteo_service.dart';
import 'package:nabour_app/services/local_notifications_service.dart'
    show LocalNotificationsService;
import 'package:nabour_app/services/assistant_voice_ui_prefs.dart';
import 'package:nabour_app/voice/testing/nabour_ghost_orchestrator.dart';
import 'package:nabour_app/voice/core/voice_ui_automation_registry.dart';
import 'package:nabour_app/screens/neighborhood_chat_screen.dart';
import 'package:nabour_app/widgets/radar_group_broadcast_sheet.dart';
import 'package:nabour_app/screens/chat_screen.dart';
import 'package:nabour_app/screens/ride_broadcast_screen.dart';
import 'package:nabour_app/services/contacts_service.dart';
import 'package:nabour_app/services/friend_request_service.dart';
import 'package:nabour_app/services/vis_prefs_service.dart';
import 'package:nabour_app/services/ghost_mode_service.dart';
import 'package:nabour_app/services/nearby_social_notif_prefs.dart';
import 'package:nabour_app/screens/vis_exclusions_screen.dart';

import 'package:nabour_app/screens/week_review_screen.dart';
import 'package:nabour_app/services/movement_history_service.dart';
import 'package:nabour_app/services/mhist_prefs_service.dart';
import 'package:nabour_app/screens/add_address_screen.dart';
import 'package:nabour_app/screens/favorite_addresses_screen.dart';
import 'package:nabour_app/screens/point_navigation_screen.dart';
import 'package:nabour_app/utils/external_maps_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nabour_app/features/mystery_box/comm_mystery_map_manager.dart';
import 'package:nabour_app/features/mystery_box/comm_mystery_map_refresh.dart';
import 'package:nabour_app/features/mystery_box/comm_mystery_box_service.dart'
    show CommunityMysteryBoxService;
import 'package:nabour_app/features/mystery_box/mystery_box_map_manager.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_checkin_store.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_geofence.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_marker_icons.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_model.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_event_service.dart';
import 'package:nabour_app/features/magic_event_checkin/magic_star_shower_overlay.dart';
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
import 'package:nabour_app/widgets/map/map_activity_toast.dart';
import 'package:nabour_app/screens/friend_suggestions_screen.dart';
import 'package:nabour_app/screens/activity_notifs_screen.dart';
import 'package:nabour_app/widgets/map/weather_overlay.dart';
import 'package:nabour_app/models/map_chat_message.dart';
import 'package:nabour_app/services/map_chat_service.dart';
import 'package:nabour_app/widgets/map/speech_bubble_widget.dart';
import 'package:nabour_app/widgets/map/map_chat_monitor_widget.dart';

// ── Part files (method groups extracted from _MapScreenState) ──
part 'parts/map_bg_voice_part.dart';
part 'parts/map_driver_part.dart';
part 'parts/map_emoji_moments_part.dart';
part 'parts/map_geocoding_nav_part.dart';
part 'parts/map_init_part.dart';
part 'parts/map_interactions_part.dart';
part 'parts/map_location_route_part.dart';
part 'parts/map_markers_part.dart';
part 'parts/map_neighbor_part.dart';
part 'parts/map_ride_flow_part.dart';
part 'parts/map_social_part.dart';
part 'parts/map_chat_part.dart';
part 'parts/map_osm_part.dart';

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
const double _kMapReactionEmojiIconSize = 0.70;

// ─────────────────────────────────────────────────────────────────────────────

/// Zoom pentru care lățimea vizibilă pe sol ≈ [visibleWidthM] m (Web Mercator; același model ca eticheta scale bar).
double _mapZoomForVisibleGroundWidthMeters({
  required double latitudeDeg,
  required double mapWidthPx,
  double visibleWidthM = 3000.0,
}) {
  if (mapWidthPx <= 0 || visibleWidthM <= 0) return 14.0;
  final cosLat = math.cos(latitudeDeg.clamp(-85.0, 85.0) * math.pi / 180);
  final z =
      math.log(156543.03392 * cosLat * mapWidthPx / visibleWidthM) / math.ln2;
  return z.clamp(3.0, 19.0);
}

class MapScreen extends StatefulWidget {
  /// Cât timp e [true], camera rămâne la zoom glob; la [false] se poate rula fly din spațiu.
  /// Folosit de [MapWithWarmupScreen] ca overlay-ul să acopere harta înainte de animație.
  final ValueNotifier<bool>? warmupOverlayVisible;

  const MapScreen({super.key, this.warmupOverlayVisible});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  /// Deschidere hartă / recentrare utilizator: ~3 km lățime vizibilă pe sol (înainte de zoom manual).
  static const double _defaultOverviewVisibleWidthM = 3000.0;

  /// Zoom inițial „glob” (Mapbox v11: proiecție glob la zoom mic) înainte de fly către user.
  static const double _spaceIntroGlobeZoom = 1.38;
  static const int _spaceIntroFlyDurationMs = 1800;
  static const int _spaceIntroPauseBeforeFlyMs = 500;

  /// Comutare 3D user (LocationPuck GLB) vs marker 2D, cu histerezis ca să evităm flicker la prag.
  static const double _kMapUser3dZoomEnterThreshold = 13.5;
  static const double _kMapUser3dZoomExitThreshold = 13.0;

  double _overviewZoomForLatitude(double latitudeDeg) {
    final w = mounted ? MediaQuery.sizeOf(context).width : 400.0;
    return _mapZoomForVisibleGroundWidthMeters(
      latitudeDeg: latitudeDeg,
      mapWidthPx: w,
      visibleWidthM: _defaultOverviewVisibleWidthM,
    );
  }

  // Controllers
  final MapBadgesController _badgesCtrl = MapBadgesController();
  final MapRouteController _routeCtrl = MapRouteController();

  bool _isUpdatingNeighbors = false;

  // Services
  final FirestoreService _firestoreService = FirestoreService();
  final AudioService _audioService = AudioService();
  final RoutingService _routingService = RoutingService();
  final ContactsService _contactsService = ContactsService();
  NeighborhoodRequestsManager? _requestsManager;
  Timer? _requestsRefreshDebounce;

  // Map & Basic UI
  MapboxMap? _mapboxMap;
  fm.MapController? _osmMapController;
  bool? _lastKnownDarkMode;

  /// La schimbări rapide de temă, [loadStyleURI] poate finaliza în ordine greșită — ignorăm completările vechi.
  int _mapStyleThemeGeneration = 0;
  /// Generație pentru _onMapCreated: previne ca operații async din apeluri vechi să afecteze instanța nouă.
  int _mapCreatedGeneration = 0;
  bool _isCreatingNeighborsManager = false;
  /// True dacă un _updateNeighborAnnotations a fost blocat de _isUpdatingNeighbors — se re-rulează la final.
  bool _neighborUpdatePending = false;

  /// Mapbox cere tapEvents pe manager; dacă managerul e creat în RTDB subscribe, altfel nu se înregistra tap.
  bool _neighborsAnnotationTapListenerRegistered = false;
  bool _isCreatingDriversManager = false;
  Future<Uint8List>? _userDriverMarkerIconInFlight;
  final Map<String, Uint8List> _nearbyDriverMarkerIconBytesCache = {};
  final Map<String, Future<Uint8List>> _nearbyDriverMarkerIconLoads = {};

  /// Registru persistent: name → PNG bytes. Re-înregistrat la fiecare style-load pentru a evita
  /// dispariția iconurilor după onTrimMemory / style refresh (Mapbox șterge imaginile custom).
  final Map<String, Uint8List> _nabourStyleImageRegistry = {};

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
  NabourContextState _contextState = NabourContextState.stationary;
  StreamSubscription<NabourContextState>? _contextSub;
  double _currentSpeedKph = 0;
  StreamSubscription<double>? _speedSub;

  /// Limitează hapticul la schimbarea modului (evită spam dacă GPS oscilează).
  DateTime? _lastContextMorphFeedback;

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

  // Position following (both roles)
  bool _followingEnabled = true;
  bool _showRecenterBtn = false;
  bool _followEaseInFlight = false;

  // Profile photo on map
  static const String _kPrefUseProfilePhotoOnMap = 'use_profile_photo_on_map';
  bool _useProfilePhotoOnMap = false;
  String? _myProfilePhotoUrl;
  bool _universalSearchOpen = false;

  // ── Map Chat (Speech Bubbles on Map) ──────────────────────────────────────
  String? _mapChatActivePeerUid;
  String? _mapChatActiveChatId;
  bool _mapChatMonitorVisible = false;
  final Map<String, String> _mapChatBubbleTexts = {};
  final Map<String, bool> _mapChatBubbleTyping = {};
  final Map<String, Offset> _mapChatBubblePositions = {};
  // Passive listeners: un sub per vecin vizibil — detectează automat mesajele primite
  final Map<String, StreamSubscription<MapChatMessage?>> _passiveBubbleSubs =
      {};
  StreamSubscription<bool>? _mapChatTypingBubbleSub;
  Timer? _mapChatBubblePosTimer;
  String _mapChatMyName = '';
  String _mapChatMyEmoji = '🙂';

  // Social & Neighbors Tracking
  bool _isVisibleToNeighbors = true;

  /// Ascunde sertarul „Activitate” până la următoarea activare vizibilitate.
  bool _neighborActivityFeedDismissed = false;
  Timer? _locationUpdateTimer;
  Timer? _visibilityPublishTimer;

  /// Publicare socială când aplicația e în fundal (stream-ul GPS e oprit la pause).
  Timer? _pausedSocialPublishTimer;

  /// Evită toast-uri repetate la același utilizator după refresh/reconectare markeri.
  final Set<String> _neighborMapActivityToastOnceUids = {};
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

  final DraggableScrollableController _rideSheetController =
      DraggableScrollableController();
  bool _rideAddressSheetVisible = false;
  MysteryBoxMapManager? _mysteryBoxManager;
  CommunityMysteryBoxMapManager? _communityMysteryManager;
  RadarAlertsMapManager? _radarAlertsManager;
  String? _lastDismissedRadarAlertId;

  /// Galaxy Garage: căi asset per slot — ambele active pe tot parcursul sesiunii (ex. ROBO pasager + OZN șofer).
  String? _garageAssetPathForPassengerSlot;
  String? _garageAssetPathForDriverSlot;

  /// Aceleași id-uri ca la [_loadCustomCarAvatar] — pentru 3D (nu doar cache vecini sociali).
  String _garageAvatarIdForDriverSlot = 'default_car';
  String _garageAvatarIdForPassengerSlot = 'default_car';

  // 3D Model Support

  bool _isUsing3DUserModel = false;

  /// Semnătură id-uri slot garaj din ultimul snapshot `users` — pentru a reapela [_loadCustomCarAvatar] doar la schimbare reală.
  String? _profileGarageSlotIdsSig;
  AnimationController? _osmMoveController;

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

  /// După [flyTo], motorul poate reface straturile înainte ca sursa modelului 3D să fie gata — reprogramăm puck-ul la map idle.
  Timer? _mapIdle3dResyncDebounce;
  String? _last3dPuckModelUri;
  DateTime? _last3dPuckApplyAt;
  bool _is3DZoomGateOpen = false;
  int _consecutive3DSourceMisses = 0;
  DateTime? _suspend3DUntil;
  static const int _k3DSourceMissesBeforeCooldown = 3;
  static const Duration _k3DSourceMissingCooldown = Duration(seconds: 12);
  static const Duration _k3DPostEnableStabilityProbeDelay =
      Duration(milliseconds: 900);
  PointAnnotationManager? _magicEventAnnotationManager;
  final Map<String, PointAnnotation> _magicEventAnnotations =
      <String, PointAnnotation>{};
  bool _magicStarShowerVisible = false;

  // Map ripple effects
  final List<({String id, Offset position})> _activeRipples = [];
  int _rippleIdCounter = 0;

  // Smart places clustering timer
  Timer? _smartPlacesClusterTimer;

  // Map moments
  StreamSubscription? _momentsSubscription;
  Timer? _momentsExpiryTimer;
  List<MapMoment> _activeMoments = [];

  // Server-side activity feed subscription
  StreamSubscription? _activityFeedSubscription;

  // Zoom slider state — sub pragul 3D până la primul eveniment cameră / sync din hartă (evită flash 3D fals).
  double _mapZoomLevel = 1.0;

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
  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _lastNearbyDriverDocs = [];

  geolocator.Position? _currentPositionObject;
  geolocator.Position? _previousPositionObject;

  /// Limitează redesenările markerului din fluxurile GPS (reduce lockHardwareCanvas / frame drops).
  static const double _userMarkerGpsRedrawMinMeters = 5.0;
  static const Duration _userMarkerGpsRedrawMaxInterval = Duration(seconds: 4);
  geolocator.Position? _lastGpsUserMarkerAnchor;
  DateTime? _lastGpsUserMarkerRedrawTime;
  int _gpsUserMarkerRedrawDebugCount = 0;
  DateTime? _lastPuckInfoLogAt;
  bool? _lastPuckInfoEnabled;
  String? _lastPuckInfoPosKey;

  void _clearGpsUserMarkerThrottle() {
    _lastGpsUserMarkerAnchor = null;
    _lastGpsUserMarkerRedrawTime = null;
  }

  void _scheduleVoiceWarmUpAfterBackendReady(
      FriendsRideVoiceIntegration voice) {
    if (_voiceWarmUpRequested) return;
    _voiceWarmUpRequested = true;
    try {
      final initializer = Provider.of<AppInitializer>(context, listen: false);
      unawaited(() async {
        await initializer.backendReadyFuture;
        if (!mounted) return;
        await Future<void>.delayed(const Duration(seconds: 10));
        if (!mounted) return;
        await voice.warmUp();
      }()
          .catchError((_) {
        _voiceWarmUpRequested = false;
      }));
    } catch (_) {
      _voiceWarmUpRequested = false;
    }
  }

  bool _shouldLogPuckInfo({
    required bool enabled,
    required String posKey,
  }) {
    final now = DateTime.now();
    final stateChanged = _lastPuckInfoEnabled != enabled;
    final posChanged = _lastPuckInfoPosKey != posKey;
    final elapsedEnough = _lastPuckInfoLogAt == null ||
        now.difference(_lastPuckInfoLogAt!) >= const Duration(seconds: 20);
    final shouldLog = stateChanged || posChanged || elapsedEnough;
    if (shouldLog) {
      _lastPuckInfoLogAt = now;
      _lastPuckInfoEnabled = enabled;
      _lastPuckInfoPosKey = posKey;
    }
    return shouldLog;
  }

  /// Dacă e false, poziția poate fi actualizată în stare dar nu forțăm desen Mapbox (cost mare).
  bool _shouldRunFullUserMarkerRedrawForGps(geolocator.Position p) {
    final anchor = _lastGpsUserMarkerAnchor;
    final lastAt = _lastGpsUserMarkerRedrawTime;
    final now = DateTime.now();
    var allow = false;
    // Fluiditate locală: în mers la volan redesenăm mai des, fără a crește publish-ul în cloud.
    final speedKph = p.speed.isNaN ? 0.0 : (p.speed * 3.6);
    final bool driverActive =
        _currentRole == UserRole.driver && _isDriverAvailable;
    final bool passengerActive =
        _currentRole != UserRole.driver || !_isDriverAvailable;
    final double minDistanceM = driverActive
        ? (speedKph >= 25.0
            ? 2.0
            : (speedKph >= 10.0 ? 3.0 : _userMarkerGpsRedrawMinMeters))
        : (passengerActive
            ? (speedKph >= 25.0
                ? 2.5
                : (speedKph >= 10.0 ? 3.5 : _userMarkerGpsRedrawMinMeters))
            : _userMarkerGpsRedrawMinMeters);
    final Duration maxInterval = driverActive
        ? (speedKph >= 25.0
            ? const Duration(seconds: 1)
            : (speedKph >= 10.0
                ? const Duration(seconds: 2)
                : _userMarkerGpsRedrawMaxInterval))
        : (passengerActive
            ? (speedKph >= 25.0
                ? const Duration(seconds: 2)
                : (speedKph >= 10.0
                    ? const Duration(seconds: 3)
                    : _userMarkerGpsRedrawMaxInterval))
            : _userMarkerGpsRedrawMaxInterval);

    if (anchor == null) {
      _lastGpsUserMarkerAnchor = p;
      _lastGpsUserMarkerRedrawTime = now;
      allow = true;
    } else {
      final movedM = geolocator.Geolocator.distanceBetween(
        anchor.latitude,
        anchor.longitude,
        p.latitude,
        p.longitude,
      );
      if (movedM >= minDistanceM) {
        _lastGpsUserMarkerAnchor = p;
        _lastGpsUserMarkerRedrawTime = now;
        allow = true;
      } else if (lastAt != null && now.difference(lastAt) >= maxInterval) {
        _lastGpsUserMarkerAnchor = p;
        _lastGpsUserMarkerRedrawTime = now;
        allow = true;
      }
    }
    if (allow && kDebugMode) {
      _gpsUserMarkerRedrawDebugCount++;
      Logger.debug(
        'GPS user marker redraw #$_gpsUserMarkerRedrawDebugCount @ ${now.toIso8601String()}',
        tag: 'MAP_MARKER_GPS',
      );
    }
    return allow;
  }

  CameraOptions? _mapWidgetFrozenCamera;
  CameraOptions? _mapWidgetFallbackCamera;

  /// După primul fly din spațiu spre user, revine la [CameraOptions] „normale” pentru rebuild-uri.
  bool _mapSpaceIntroDone = false;
  bool _startupCameraPrimed = false;
  bool _mapReadyCenterInFlight = false;
  bool _spaceIntroInFlight = false;
  bool _cinematicIntroLock = true;

  double? _driverMarkerSmoothLat;
  double? _driverMarkerSmoothLng;
  double? _driverMarkerSmoothHeadingDeg;

  StreamSubscription<geolocator.Position>? _positionSubscription;
  StreamSubscription<geolocator.Position>? _passengerWarmupSubscription;

  /// Telemetrie locală (celulă H3) — poziții proaspete pentru cine e în aceeași zonă.
  StreamSubscription<List<NeighborLocation>>? _neighborRtdbSubscription;

  /// Prieteni vizibili din Firestore, oriunde în lume (fără filtru distanță).
  StreamSubscription<List<NeighborLocation>>? _neighborFirestoreSubscription;
  List<NeighborLocation> _neighborFsSnapshot = [];
  List<NeighborLocation> _neighborRtdbSnapshot = [];

  /// Sweep periodic al vecinilor stagnați (fără event nou) ca să dispară fără restart.
  Timer? _neighborStaleSweepTimer;
  bool _voiceWarmUpRequested = false;
  DateTime? _lastRequestsRefreshAt;
  double? _lastRequestsRefreshLat;
  double? _lastRequestsRefreshLng;

  /// Zoom curent al camerei (actualizat la fiecare mișcare) — scalare markere sociali.
  double _liveCameraZoom = 14.0;
  Timer? _neighborZoomDebounce;
  Timer? _emojiAvoidanceDebounce;

  /// Mărime icon vecin înainte de factorul de zoom (reaplicat la schimbare zoom).
  final Map<String, double> _neighborIconSizeBaseByUid = {};

  /// Semnăturile grupelor co-localizate pentru care s-a executat auto-zoom (per sesiune).
  final Set<String> _autoZoomedGroupSignatures = {};

  /// Puncte avatar / mașină contact pentru a îndepărta emoji-urile plasate pe hartă.
  List<({double lat, double lng})> _avatarPinsForEmojiAvoidance = [];
  List<NeighborLocation> _lastFilteredNeighborsForMap = [];
  Map<String, NeighborDisplayCoords> _lastNeighborDisplayByUid = {};
  DateTime? _lastUpdateTime;
  final int _standingInterval = 15;
  final int _slowSpeedInterval = 7;
  final int _highSpeedInterval = 7;
  static const bool _verboseBuildLogs = false;

  // ── Adaptive GPS mode (driver) ─────────────────────────────────────────────
  // Când șoferul este static (< _kDriverMoveThresholdKph) comutăm pe un stream
  // GPS ușor (medium accuracy, distanceFilter mare) — economie baterie + scrieri.
  // La depășirea pragului restartăm stream-ul în modul high-accuracy.
  static const double _kDriverMoveThresholdKph = 10.0; // ~2.78 m/s
  static const double _kDriverMoveHysteresisKph =
      2.0; // evită oscilații la graniță
  bool _driverGpsInLowPowerMode = false;
  Timer? _driverAdaptiveGpsDebounce;

  // Rides & Broadcasts
  Ride? _currentActiveRide;
  List<Ride> _pendingRides = [];
  Ride? _currentRideOffer;
  Timer? _rideOfferTimer;
  int _remainingSeconds = 30;
  bool _isProcessingAccept = false;
  bool _isProcessingDecline = false;
  bool _shouldResetRoute = false;
  final GlobalKey<RideRequestPanelState> _rideRequestPanelKey =
      GlobalKey<RideRequestPanelState>();

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
  String? _nbRoomPushTopic;
  PointAnnotationManager? _emergencyAnnotationManager;
  final Map<String, PointAnnotation> _emergencyAnnotations = {};

  /// Aurele roșii (SOS) randate peste hartă în jurul urgențelor.
  List<NabourAuraMapSlot> _emergencyAuraSlots = [];

  StreamSubscription? _emergencyAlertsSubscription;
  StreamSubscription<List<FriendRequestEntry>>? _incomingFriendRequestsSub;
  // Proximity & PNG markers
  final Set<String> _proximitNotifiedUids = {};
  DateTime _proximityNotifResetTime = DateTime.now();
  final Set<String> _friendsTogetherHintPairs = {};
  DateTime? _lastFriendsTogetherHintAny;
  static final Map<String, Uint8List> _emojiMarkerCache = {};
  static final Uint8List _kMinimalPngBytes = Uint8List.fromList(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='));
  bool _marker15StyleImageAdded = false;

  // Animations & Pulse Controllers
  AnimationController? _pickupPulseController;
  Animation<double>? _pickupPulse;
  AnimationController? _routePulseController;
  Animation<double>? _routePulse;
  PolylineAnnotation? _activeRouteAnnotation;
  PointAnnotation? _userPointAnnotation;

  /// Reper manual de orientare (`users.mapOrientationPin`) — afișat ca **ac cu gamalie verde**, separat de Acasă.
  GeoPoint? _manualOrientationPin;

  /// Denumire (`users.mapOrientationPinLabel`) — pe marker și în căutarea universală.
  String? _manualOrientationPinLabel;

  /// „Acasă” din favorite pe hartă (`users.showSavedHomePinOnMap` + coordonate din `saved_addresses`) — **casă în glob**.
  bool _showSavedHomePinOnMap = false;
  bool _homePinShowInitialized = false;
  bool _awaitingMapOrientationPinPlacement = false;

  /// Pin Acasă (favorite) — strat separat față de reperul de orientare.
  PointAnnotationManager? _savedHomeFavoritePinManager;
  bool _savedHomeFavoritePinTapRegistered = false;

  /// Reper orientare (ac compas) — strat separat.
  PointAnnotationManager? _orientationReperPinManager;
  bool _orientationReperPinTapRegistered = false;
  Future<void>?
      _homePinUpdateChain; // Serialize updates pentru ambele pinuri private

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

  /// Avatar PNG curent aplicat ca LocationPuck2D (toate platformele). Nul când e puck implicit sau 3D.
  Uint8List? _puck2DAvatarBytes;

  /// PNG compozit (avatar + etichetă chip) aplicat ca bearingImage în LocationPuck2D.
  /// Se rotește cu bearing-ul — avatar și text orientate cu direcția de mers.
  Uint8List? _puck2DLabelBytes;

  /// Textul curent baked în _puck2DLabelBytes; rebuild dacă se schimbă.
  String? _puck2DLabelCacheKey;
  static const double _androidUserMarkerOverlaySize = 88.0;

  /// Android: pin Acasă (favorite) — bitmap casă în glob.
  Point? _androidSavedHomePinGeometry;
  Offset? _androidSavedHomePinOverlayPx;
  Uint8List? _androidSavedHomePinOverlayBytes;

  /// Android: reper orientare — ac compas.
  Point? _androidOrientationReperGeometry;
  Offset? _androidOrientationReperOverlayPx;
  Uint8List? _androidOrientationReperOverlayBytes;
  static const double _androidPrivatePinOverlayWidth = 48.0;
  static const double _androidPrivatePinOverlayHeight = 56.0;

  /// Spațiu pentru eticheta deasupra reperului (Android overlay).
  static const double _androidOrientationReperLabelBlock = 38.0;

  /// Serialize user-marker updates so concurrent GPS ticks do not race Mapbox `update` vs `delete`.
  Future<void>? _userMarkerUpdateChain;
  StreamSubscription? _honkSubscription;
  StreamSubscription? _emojiSubscription;
  PointAnnotationManager? _emojiAnnotationManager;
  double _emojiIconSizeBase = 0.56;
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
    if (!AssistantVoiceUiPrefs.instance.visibilityNotifier.value) {
      return false;
    }
    if (_currentRole == UserRole.passenger) return true;
    if (_currentRole == UserRole.driver) return true;
    return false;
  }

  void _onAssistantVoiceUiPrefChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _prewarmTiles() async {
    try {
      const List<String> candidateSources = [
        'composite',
        'mapbox',
        'basemap',
        'raster-dem'
      ];
      for (final src in candidateSources) {
        try {
          await _mapboxMap!.style
              .setStyleSourceProperty(src, 'prefetch-zoom-delta', 2);
        } catch (_) {
          /* Mapbox op — expected on style reload or missing layer/annotation */
        }
      }
    } catch (_) {
      /* Mapbox op — expected on style reload or missing layer/annotation */
    }
  }

  static Uint8List _pngBytesOrMinimalFallback(ByteData? data, String context) {
    if (data != null) return data.buffer.asUint8List();
    Logger.warning(
        '$context: Image.toByteData returned null; using minimal PNG',
        tag: 'MAP');
    return _kMinimalPngBytes;
  }



  /// Dacă abonarea vecini a eșuat la start (fără GPS încă), o repornim când avem poziție.
  void _ensureNeighborsListeningAfterPosition() {
    if (!mounted) return;
    if (_neighborRtdbSubscription != null ||
        _neighborFirestoreSubscription != null) {
      return;
    }
    if (_isInitializingNeighbors) return;
    if (_positionForUserMapMarker() == null) return;
    _listenForNeighbors();
    // Start moment listener on first GPS fix — safe to call multiple times
    // since _subscribeToMoments guards with _momentsSubscription?.cancel() internally.
    if (_momentsSubscription == null) _subscribeToMoments();
  }

  void _refreshNeighborhoodRequestBubbles() {
    final m = _requestsManager;
    if (m == null) return;
    final pos = _currentPositionObject ??
        LocationCacheService.instance
            .peekRecent(maxAge: const Duration(minutes: 20));
    if (pos != null &&
        _lastRequestsRefreshAt != null &&
        _lastRequestsRefreshLat != null &&
        _lastRequestsRefreshLng != null) {
      final elapsed = DateTime.now().difference(_lastRequestsRefreshAt!);
      final movedM = geolocator.Geolocator.distanceBetween(
        _lastRequestsRefreshLat!,
        _lastRequestsRefreshLng!,
        pos.latitude,
        pos.longitude,
      );
      if (elapsed < const Duration(seconds: 3) && movedM < 25) {
        return;
      }
    }
    _requestsRefreshDebounce?.cancel();
    _requestsRefreshDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (pos != null) {
        _lastRequestsRefreshAt = DateTime.now();
        _lastRequestsRefreshLat = pos.latitude;
        _lastRequestsRefreshLng = pos.longitude;
      }
      unawaited(m.refreshForUserLocation());
      unawaited(_recomputeCereriQuickActionBadge());
      unawaited(_rebindNbChatQuickActionBadgeListener());
    });
  }

  void _startQuickActionBadgeListeners() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _badgesCtrl.startListening(uid,
        positionProvider: () => _currentPositionObject);
  }

  void _disposeQuickActionBadgeListeners() {
    // Handled by _badgesCtrl.dispose() in dispose()
  }

  Future<void> _recomputeCereriQuickActionBadge() =>
      _badgesCtrl.recomputeCereri();

  Future<void> _rebindNbChatQuickActionBadgeListener() =>
      _badgesCtrl.rebindNbChatListener();

  Future<void> _recountNbChatQuickActionBadge() =>
      _badgesCtrl.rebindNbChatListener();

  // ── Destination preview ──────────────────────────────────────────────────────
  bool _isDestinationPreviewMode = false;
  Point? _previewPinPoint;
  Offset? _previewPinScreenPos;
  bool _isDraggingPin = false;
  Timer? _pinAutoHideTimer;

  // Afișare automată traseu când avem pickup + destinație (+ opriri)
  Future<void> _checkAndShowRouteAutomatically() async {
    if (_routeCtrl.pickupLatitude != null &&
        _routeCtrl.pickupLongitude != null &&
        _routeCtrl.destinationLatitude != null &&
        _routeCtrl.destinationLongitude != null) {
      try {
        final List<Point> waypoints = [];
        waypoints.add(Point(
            coordinates: Position(
                _routeCtrl.pickupLongitude!, _routeCtrl.pickupLatitude!)));
        for (final stop in _routeCtrl.intermediateStops) {
          final coords = await _getCoordinatesForDestination(stop);
          if (coords != null) waypoints.add(coords);
        }
        waypoints.add(Point(
            coordinates: Position(_routeCtrl.destinationLongitude!,
                _routeCtrl.destinationLatitude!)));
        final routeData = await _routingService.getRoute(waypoints);
        if (routeData != null && mounted) await _onRouteCalculated(routeData);
      } catch (e) {
        Logger.error('Auto route calculation error: $e', error: e);
      }
    }
  }

  bool get _warmupBlocksCamera => widget.warmupOverlayVisible?.value == true;

  void _onWarmupOverlayChanged() {
    if (!mounted) return;
    if (widget.warmupOverlayVisible?.value != false) return;
    unawaited(_centerOnLocationOnMapReady(preferSpaceIntro: true));
  }

  void _onCommunityMysteryMapRefreshRequested() {
    if (!mounted) return;
    final p = _currentPositionObject;
    if (p == null) return;
    unawaited(_communityMysteryManager?.updateBoxes(
      p.latitude,
      p.longitude,
      force: true,
    ));
  }

  @override
  void initState() {
    super.initState();
    _badgesCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _routeCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    widget.warmupOverlayVisible?.addListener(_onWarmupOverlayChanged);
    _smartSuggestionsFuture = SmartSuggestionsService().getSuggestions();
    PassengerRideServiceBus.pending.addListener(_onPassengerRideBus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _drainPassengerRideBus();
    });

    WidgetsBinding.instance.addObserver(this);
    unawaited(AssistantVoiceUiPrefs.instance.load());
    AssistantVoiceUiPrefs.instance.visibilityNotifier
        .addListener(_onAssistantVoiceUiPrefChanged);
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
        final voice =
            Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
        voice.addListener(_onVoiceAddressChanged);
        // Inițializează stack-ul vocal doar la finalul init-ului existent.
        _scheduleVoiceWarmUpAfterBackendReady(voice);

        // Wire voice→panel callbacks so AI can fill addresses and press confirm
        voice.setRidePanelCallbacks(
          onFillAddress: (pickup, dest,
              {pickupLat, pickupLng, destLat, destLng}) {
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
      } catch (_) {
        /* Mapbox op — expected on style reload or missing layer/annotation */
      }
    });

    // Pulse marker controller
    if (!AppDrawer.lowDataMode) {
      _pickupPulseController = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 1200));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pickupPulseController?.repeat(reverse: true);
        }
      });
      _pickupPulse = Tween<double>(begin: 1.0, end: 1.25).animate(
          CurvedAnimation(
              parent: _pickupPulseController!, curve: Curves.easeInOut));
    }

    unawaited(_loadCustomCarAvatar());

    // Context Engine — UI contextual (HUD / glow); viteza vine din același flux GPS ca harta.
    _contextSub = ContextEngineService.instance.stateStream.listen((state) {
      if (mounted && _contextState != state) {
        setState(() => _contextState = state);
        final now = DateTime.now();
        if (_lastContextMorphFeedback == null ||
            now.difference(_lastContextMorphFeedback!) >
                const Duration(seconds: 5)) {
          _lastContextMorphFeedback = now;
          unawaited(AppSoundService.instance.playDigitalClick());
        }
      }
    });
    // Fallback pentru modul pasager (stream warmup pasiv care nu apelează
    // _updateLiveSpeedFromPosition). În modul șofer, viteza e deja actualizată
    // de _updateLiveSpeedFromPosition cu speedAccuracy fix, deci pragul 1.5 km/h
    // previne o suprascriere inutilă cu valoarea brută din GPS.
    _speedSub = ContextEngineService.instance.speedStream.listen((kph) {
      if (!mounted) return;
      if ((kph - _currentSpeedKph).abs() < 0.3) return;
      setState(() => _currentSpeedKph = kph);
    });
    ContextEngineService.instance.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startQuickActionBadgeListeners();
    });

    CommunityMysteryMapRefresh.instance
        .addListener(_onCommunityMysteryMapRefreshRequested);

    // 🤖 Înregistrăm acțiunile de automatizare pentru Ghost Mode / Testare autonomă
    final registry = VoiceUIAutomationRegistry();
    registry.registerAction(
      'set_role_driver',
      () => _handleRoleChange(true),
      meta: const VoiceActionMeta(
        keywordsEN: [
          'driver mode',
          'go online',
          'start driving',
          'become driver'
        ],
        keywordsRO: [
          'mod șofer',
          'intru online',
          'devin șofer',
          'activez șofer'
        ],
        responseTemplateEN: 'Switching to driver mode.',
        responseTemplateRO: 'Trec în modul șofer.',
      ),
    );
    registry.registerAction(
      'set_role_passenger',
      () => _handleRoleChange(false),
      meta: const VoiceActionMeta(
        keywordsEN: [
          'passenger mode',
          'go offline',
          'stop driving',
          'become passenger'
        ],
        keywordsRO: [
          'mod pasager',
          'ies offline',
          'devin pasager',
          'opresc șoferul'
        ],
        responseTemplateEN: 'Switching to passenger mode.',
        responseTemplateRO: 'Trec în modul pasager.',
      ),
    );
    registry.registerAction(
      'accept_ride_request',
      () {
        if (_currentRideOffer != null) {
          _acceptRide(_currentRideOffer!);
        } else {
          Logger.warning('Ghost: No active ride offer to accept',
              tag: 'UI_AUTOMATION');
        }
      },
      meta: const VoiceActionMeta(
        keywordsEN: ['accept ride', 'accept request', 'take the ride'],
        keywordsRO: ['acceptă cursa', 'acceptă cererea', 'iau cursa', 'accept'],
        responseTemplateEN: 'Accepting the ride request.',
        responseTemplateRO: 'Accept cererea de cursă.',
      ),
    );
    registry.registerAction(
      'show_parking_sheet',
      () => _showParkingSwapDialog('ghost_spot_123'),
      meta: const VoiceActionMeta(
        keywordsEN: ['parking', 'park here', 'show parking'],
        keywordsRO: ['parcare', 'parcarez', 'arată parcare'],
        responseTemplateEN: 'Opening parking options.',
        responseTemplateRO: 'Deschid opțiunile de parcare.',
      ),
    );
    registry.registerAction(
      'reserve_parking',
      () => _handleParkingReservationSync(),
      meta: const VoiceActionMeta(
        keywordsEN: ['reserve parking', 'book parking', 'confirm parking'],
        keywordsRO: ['rezerv parcarea', 'confirmă parcarea', 'blochez locul'],
        responseTemplateEN: 'Reserving the parking spot.',
        responseTemplateRO: 'Rezerv locul de parcare.',
      ),
    );
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
        unawaited(_loadProfilePhotoMapPref());
        _initHonkListener();
        _initEmojiListener();
        _startMagicEventPolling();
        if (_showParkingYieldMapButton) {
          _initParkingSwapStream();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // La prima rulare, încarcă preferința "acasă pe hartă" din SharedPreferences
    // (via MapSettingsProvider) înainte ca Firestore să răspundă — elimină lag-ul de afișare.
    if (!_homePinShowInitialized) {
      _homePinShowInitialized = true;
      final mapSettings = Provider.of<MapSettingsProvider>(context, listen: false);
      if (mapSettings.showHomePinOnMap && !_showSavedHomePinOnMap) {
        _showSavedHomePinOnMap = true;
      }
    }

    // Folosim [Theme] (nu Provider cu listen implicit) ca să nu dublăm dependența
    // față de Consumer-ul din [MaterialApp] — altfel notifyListeners + loadStyleURI în
    // același ciclu pot declanșa aserțiunea _elements.contains(element).
    // MapWidget: nu legați [styleUri] direct de [Theme.of(context)] la fiecare rebuild —
    // același ciclu cu [loadStyleURI] poate corupe platform view-ul. Folosiți
    // [_lastKnownDarkMode] (actualizat în post-frame) sau fallback doar cât _lastKnownDarkMode e null.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_mapboxMap == null || _lastKnownDarkMode == isDark) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _mapboxMap == null) return;
      final isDarkNow = Theme.of(context).brightness == Brightness.dark;
      if (_lastKnownDarkMode == isDarkNow) return;

      final gen = ++_mapStyleThemeGeneration;
      _lastKnownDarkMode = isDarkNow;
      final targetStyle = NabourMapStyles.uriForMainMap(
        lowDataMode: AppDrawer.lowDataMode,
        darkMode: isDarkNow,
      );
      _resetAnnotationManagers();
      unawaited(
        _mapboxMap!.loadStyleURI(targetStyle).then((_) async {
          if (!mounted || gen != _mapStyleThemeGeneration) return;
          await _rebuildEmojiThenMomentLayers();
          if (!mounted || gen != _mapStyleThemeGeneration) return;
          unawaited(_syncMapOrientationPinAnnotation());
          if (_positionForUserMapMarker() != null) {
            _clearGpsUserMarkerThrottle();
            unawaited(_updateUserMarker(centerCamera: false));
            unawaited(_updateLocationPuck());
          }
          // După loadStyleURI managerii de adnotări sunt resetați; stream-ul vecini poate să nu reemită imediat.
          unawaited(_reapplyContactFilterOnMap());
          if (mounted && gen == _mapStyleThemeGeneration) setState(() {});
        }).catchError((_) {}),
      );
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AssistantVoiceUiPrefs.instance.visibilityNotifier
        .removeListener(_onAssistantVoiceUiPrefChanged);

    if (_flashlightOn) {
      TorchLight.disableTorch().catchError((_) {});
      _flashlightOn = false;
    }

    Logger.debug('MapScreen dispose - cleaning up all resources');

    CommunityMysteryMapRefresh.instance
        .removeListener(_onCommunityMysteryMapRefreshRequested);
    final roomTopic = _nbRoomPushTopic;
    if (roomTopic != null && roomTopic.isNotEmpty) {
      unawaited(
        FirebaseMessaging.instance
            .unsubscribeFromTopic('neighborhood_$roomTopic'),
      );
    }
    widget.warmupOverlayVisible?.removeListener(_onWarmupOverlayChanged);
    PassengerRideServiceBus.pending.removeListener(_onPassengerRideBus);
    _passengerRideSessionSub?.cancel();
    _passengerRideSessionSub = null;

    _audioService.dispose();

    // 🛑 NOU: Dispose intermediate stops controllers
    for (final controller in _routeCtrl.intermediateStopsControllers) {
      controller.dispose();
    }
    _routeCtrl.intermediateStopsControllers.clear();

    // MODIFICAT: Asigurăm oprirea noului stream de locație.
    _stopLocationUpdates();

    // NOU: Cleanup pentru POI-uri
    _poiAnnotations.clear();
    _poiUpdateTimer?.cancel();
    _poiOperationTimer?.cancel(); // ✅ NOU: Cancel POI operation timer

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
    _osmMoveController?.dispose();

    // Cancel all subscriptions
    _pendingRidesSubscription?.cancel();
    _pendingRidesSubscription = null;
    _acceptedRideStatusSubscription?.cancel();
    _driverProfileSubscription?.cancel();
    _savedAddressesForHomePinSub?.cancel();
    _nearbyDriversSubscription?.cancel();
    _chatMessagesSubscription?.cancel();
    _emergencyAlertsSubscription?.cancel();
    _cancelNeighborLocationSubscriptions();
    _honkSubscription?.cancel();
    _emojiSubscription?.cancel();
    _ghostModeTimer?.cancel();
    if (_isVisibleToNeighbors) {
      NeighborLocationService().setInvisible();
    }
    BleBumpService.instance.stop();
    BleBumpBridge.instance.stop();
    _smartPlacesClusterTimer?.cancel();
    _pausedSocialPublishTimer?.cancel();
    _pausedSocialPublishTimer = null;
    _momentsSubscription?.cancel();
    _momentsExpiryTimer?.cancel();
    _activityFeedSubscription?.cancel();
    _parkingSpotsSubscription?.cancel();
    _parkingSpotsSubscription = null;
    _friendPeersSub?.cancel();
    _incomingFriendRequestsSub?.cancel();
    _mysteryBoxManager?.dispose();
    _communityMysteryManager?.dispose();
    _radarAlertsManager?.dispose();
    _magicEventPollTimer?.cancel();
    _auraProjectDebounce?.cancel();
    _mapIdle3dResyncDebounce?.cancel();
    _neighborZoomDebounce?.cancel();
    _neighborStaleSweepTimer?.cancel();
    _emojiAvoidanceDebounce?.cancel();
    _requestsRefreshDebounce?.cancel();

    _disposeQuickActionBadgeListeners();
    _badgesCtrl.dispose();
    _routeCtrl.dispose();

    try {
      final voice =
          Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
      voice.removeListener(_onVoiceAddressChanged);
    } catch (_) {
      /* Mapbox op — expected on style reload or missing layer/annotation */
    }
    _contextSub?.cancel();
    _speedSub?.cancel();

    // ── Map Chat cleanup ──
    _disposeMapChat();

    // 🤖 Curățăm acțiunile de automatizare
    final registry = VoiceUIAutomationRegistry();
    registry.unregisterAction('set_role_driver');
    registry.unregisterAction('set_role_passenger');
    registry.unregisterAction('accept_ride_request');

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _mapSurfaceSafeForUserMarker = true;
      Logger.info('App resumed - checking if we need to reset route state');

      _pausedSocialPublishTimer?.cancel();
      _pausedSocialPublishTimer = null;
      unawaited(AssistantVoiceUiPrefs.instance.load());

      /*
      final shouldRestoreDriverLiveMap =
          _hidDriverLiveMapPresenceForBackground &&
              _currentRole == UserRole.driver &&
              _isDriverAvailable &&
              _isVisibleToNeighbors;
      _hidDriverLiveMapPresenceForBackground = false;
      if (shouldRestoreDriverLiveMap) {
        final ids = _resolvedPlateAndPublicName();
        if (ids.plate != null && ids.name != null && _driverCategory != null) {
          unawaited(
            _firestoreService.restoreDriverLiveMapPresenceAfterForeground(
              displayName: ids.name!,
              licensePlate: ids.plate!,
              category: _driverCategory!,
            ),
          );
        }
      }
      */

      if (_isDriverAvailable && _currentRole == UserRole.driver) {
        _startDriverLocationUpdates();
      } else {
        _ensurePassiveLocationWarmupIfNeeded();
      }

      unawaited(_updateLocationPuck());
      unawaited(_updateUserMarker(centerCamera: false));
      unawaited(_syncMapOrientationPinAnnotation());

      unawaited(_syncFriendPeersIntoContactUids());
      _listenIncomingFriendRequests();

      unawaited(_pollMagicEventsOnce());

      _resetRouteStateIfNeeded();

      if (_isDriverAvailable && _currentRole == UserRole.driver) {
        Logger.debug(
            'App resumed - restarting location updates and ride listener');
        _startDriverLocationUpdates();
        _startListeningForRides();
      }
    } else if (state == AppLifecycleState.paused) {
      // NU folosi `inactive`: pe Android apare des în foreground (scurtă pierdere focus)
      // și bloca markerul personalizat fără să repornească puck-ul → utilizator „invizibil".
      _mapSurfaceSafeForUserMarker = false;
      if (_useAndroidFlutterUserMarkerOverlay && mounted) {
        setState(() {
          _clearAndroidUserMarkerOverlayFields();
          _clearAndroidPrivatePinOverlayFields();
        });
      }
      Logger.debug('💤 App paused - stopping location updates');
      _stopLocationUpdates();
      /*
      if (_currentRole == UserRole.driver && _isDriverAvailable) {
        _hidDriverLiveMapPresenceForBackground = true;
        unawaited(
            _firestoreService.hideDriverLiveMapPresenceForAppBackground());
      }
      */
      if (_wantsNeighborSocialPublish) {
        _pausedSocialPublishTimer?.cancel();
        _pausedSocialPublishTimer =
            Timer.periodic(const Duration(seconds: 45), (_) {
          unawaited(_backgroundSocialMapPublishTick());
        });
        unawaited(_backgroundSocialMapPublishTick());
      }
    }
  }

  Future<void> _maybeStartMovementHistoryRecorder() async {
    final enabled =
        await MovementHistoryPreferencesService.instance.isEnabled();
    if (!enabled) return;
    await MovementHistoryService.instance.startRecorder();
  }

  /// Menține Firestore + RTDB când utilizatorul e vizibil dar aplicația e în fundal.
  Future<void> _backgroundSocialMapPublishTick() async {
    if (!_wantsNeighborSocialPublish) return;
    try {
      final p = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 8),
        ),
      );
      LocationCacheService.instance.record(p);
      if (mounted) {
        setState(() {
          _currentPositionObject = p;
          _freezeMapWidgetCameraIfNeeded();
        });
      }
      await _publishNeighborSocialMapFresh(p, forceNeighborTelemetry: true);
    } catch (e) {
      Logger.debug('Background social publish tick: $e', tag: 'MAP');
    }
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
        Logger.info(
            'DEBUG:  canShowVoiceAI = true - va afișa AI button și overlay!');
      } else {
        Logger.error(
            'DEBUG:  canShowVoiceAI = false - NU va afișa AI button și overlay!');
      }
      Logger.debug('DEBUG: ========== END BUILD METHOD DEBUG ==========');
    }

    final bool shouldShowPassengerUI = _currentRole == UserRole.passenger ||
        (_currentRole == UserRole.driver && !_isDriverAvailable);

    if (_verboseBuildLogs) {
      Logger.debug('DEBUG: shouldShowPassengerUI = $shouldShowPassengerUI');
    }

    final l10n = AppLocalizations.of(context)!;

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
        onEnableSavedHomePinOnMap: () =>
            unawaited(_enableSavedHomePinFromDrawer()),
        onHideSavedHomePinOnMap: () => unawaited(_hideSavedHomePinFromDrawer()),
        onRemoveOrientationReperFromMap: () =>
            unawaited(_removeOrientationReperFromDrawer()),
        isHomePinVisible: _showSavedHomePinOnMap,
        isOrientationReperVisible: _manualOrientationPin != null,
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
                    Consumer<MapSettingsProvider>(
                      builder: (context, mapSettings, _) {
                        if (mapSettings.isOsm) {
                          return OsmMapWidget(
                            key: const ValueKey('nabour_osm_stable'),
                            // 🔄 MIDDLEWARE SYNC: Folosim direct providerul pentru recentrare (unifică Mapbox/OSM)
                            initialCenter: ll.LatLng(
                              _currentPositionObject?.latitude ?? 44.4268,
                              _currentPositionObject?.longitude ?? 26.1025,
                            ),
                            initialZoom: _liveCameraZoom,
                            onMapCreated: _onOsmMapCreated,
                            onTap: (latLng) => _handleMapTap(Point(
                              coordinates: Position(latLng.longitude, latLng.latitude),
                            )),
                            onLongPress: (latLng) => _handleMapLongPress(Point(
                              coordinates: Position(latLng.longitude, latLng.latitude),
                            )),
                            onPositionChanged: (pos, hasGesture) {
                              // Actualizăm zoom-ul live → avatar-ele se redimensionează la rebuild.
                              final newZoom = pos.zoom;
                              final lat = pos.center.latitude;
                              final lng = pos.center.longitude;

                              // 🔄 MIDDLEWARE SYNC: Salvăm starea în provider pentru tranziție perfectă către Mapbox
                              context.read<MapCameraProvider>().syncFromNative(
                                    lat: lat,
                                    lng: lng,
                                    zoom: newZoom,
                                    following: _followingEnabled,
                                  );

                              if ((newZoom - _liveCameraZoom).abs() > 0.05) {
                                _liveCameraZoom = newZoom;
                                _neighborZoomDebounce?.cancel();
                                _neighborZoomDebounce = Timer(
                                  const Duration(milliseconds: 120),
                                  () {
                                    if (mounted) setState(() {});
                                  },
                                );
                              }
                              if (hasGesture) {
                                unawaited(_updateCurrentStreetName(throttle: true));
                                // Actualizăm Mystery Boxes când utilizatorul mută harta pe OSM
                                unawaited(_mysteryBoxManager?.updateMysteryBoxes(lat, lng));
                                unawaited(_communityMysteryManager?.updateBoxes(lat, lng));
                              }
                            },
                            userLocation: _currentPositionObject != null 
                                ? ll.LatLng(_currentPositionObject!.latitude, _currentPositionObject!.longitude)
                                : null,
                            userAssetPath: _currentRole == UserRole.passenger
                                ? _garageAssetPathForPassengerSlot
                                : _garageAssetPathForDriverSlot,
                            userName: _mapChatMyName.isNotEmpty
                                ? _mapChatMyName
                                : (_resolvedPlateAndPublicName().name ??
                                    FirebaseAuth.instance.currentUser?.displayName ??
                                    'Tu'),
                            userSpeedKph: _currentSpeedKph,
                            additionalMarkers: _buildOsmMarkers(),
                          );
                        }

                        return MapWidget(
                          key: const ValueKey('nabour_mapbox_stable'),
                          onMapCreated: _onMapCreated,
                          onStyleLoadedListener: _onStyleLoaded,
                          onTapListener: (position) =>
                              _handleMapTap(MapboxUtils.contextToPoint(position)),
                          onLongTapListener: (position) => _handleMapLongPress(
                              MapboxUtils.contextToPoint(position)),
                          onCameraChangeListener: _onCameraChanged,
                          onMapIdleListener: _onMapIdle,
                          cameraOptions: _mapWidgetCameraOptions,
                          styleUri: NabourMapStyles.uriForMainMap(
                            lowDataMode: AppDrawer.lowDataMode,
                            darkMode: _lastKnownDarkMode ??
                                Theme.of(context).brightness == Brightness.dark,
                          ),
                        );
                      },
                    ),
                    // Map ripples overlay
                    ..._activeRipples.map((ripple) => MapRippleEffect(
                          key: ValueKey(ripple.id),
                          position: ripple.position,
                          onFinished: () {
                            setState(() {
                              _activeRipples.removeWhere((r) => r.id == ripple.id);
                            });
                          },
                          color: const Color(0xFF00E5FF), // Cyber Blue
                        )),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.add_location_alt_rounded,
                                    color: Color(0xFF38BDF8), size: 24),
                                const SizedBox(width: 8),
                                const Icon(Icons.touch_app_rounded,
                                    color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .mapLongPressToSetLandmark,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    setState(() =>
                                        _awaitingMapOrientationPinPlacement =
                                            false);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF38BDF8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    minimumSize: const ui.Size(0, 40),
                                  ),
                                  child: Text(
                                      AppLocalizations.of(context)!.cancel,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: Color(0xFFE53935), size: 26),
                                  tooltip: AppLocalizations.of(context)!
                                      .mapCloseCancelPlacement,
                                  constraints: const BoxConstraints(
                                      minWidth: 48, minHeight: 48),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    setState(() =>
                                        _awaitingMapOrientationPinPlacement =
                                            false);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_radarAlertsManager != null && _radarAlertsManager!.alerts.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final latest = _radarAlertsManager!.alerts.first;
                            if (latest.id == _lastDismissedRadarAlertId) return const SizedBox.shrink();
                            
                            return Positioned(
                              top: 68 + (_awaitingMapOrientationPinPlacement ? 60 : 0),
                              left: 0,
                              right: 0,
                              child: RadarAlertBanner(
                                alert: latest,
                                onTap: () {
                                  if (latest.latitude != 0 && latest.longitude != 0) {
                                    final mapSettings = Provider.of<MapSettingsProvider>(context, listen: false);
                                    if (mapSettings.isOsm) {
                                      _animatedMoveOsm(ll.LatLng(latest.latitude, latest.longitude), 15.0);
                                    } else {
                                      _mapboxMap?.flyTo(
                                        CameraOptions(
                                          center: MapboxUtils.createPoint(latest.latitude, latest.longitude),
                                          zoom: 15.0,
                                        ),
                                        MapAnimationOptions(duration: 1000),
                                      );
                                    }
                                  }
                                },
                                onClose: () {
                                  setState(() => _lastDismissedRadarAlertId = latest.id);
                                },
                              ),
                            );
                          },
                        ),
                      // Simbol reper pe hartă în timpul plasării (indicator de mod, nu poziție exactă).
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 120,
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.65),
                                    width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.explore_rounded,
                                    color: const Color(0xFF16A34A),
                                    size: 28,
                                  ),
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
                    Positioned.fill(child: _buildContextualOverlay()),
                    // if (_currentRole == UserRole.driver && _isDriverAvailable)
                    //   Positioned(
                    //     left: 14,
                    //     top: 126,
                    //     child: MapDriverSpeedChip(speedKmh: _currentSpeedKph),
                    //   ),
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
                        projection: (pt) => _projectLatLngToScreen(
                            pt.coordinates.lat.toDouble(),
                            pt.coordinates.lng.toDouble()),
                        onUpdate: (center, radius) {
                          setState(() {
                            _radarCenter = center;
                            _radarRadius = radius;
                          });
                        },
                        onConfirm: _onRadarConfirmed,
                      ),
                    if (_useAndroidFlutterUserMarkerOverlay &&
                        _androidSavedHomePinOverlayPx != null &&
                        _androidSavedHomePinOverlayBytes != null)
                      Positioned(
                        left: _androidSavedHomePinOverlayPx!.dx -
                            _androidPrivatePinOverlayWidth / 2,
                        top: _androidSavedHomePinOverlayPx!.dy -
                            _androidPrivatePinOverlayHeight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (mounted) _showSavedHomeFavoritePinActions();
                          },
                          child: SizedBox(
                            width: _androidPrivatePinOverlayWidth,
                            height: _androidPrivatePinOverlayHeight,
                            child: Image.memory(
                              _androidSavedHomePinOverlayBytes!,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      ),
                    if (_useAndroidFlutterUserMarkerOverlay &&
                        _androidOrientationReperOverlayPx != null &&
                        _androidOrientationReperOverlayBytes != null)
                      Positioned(
                        left: _androidOrientationReperOverlayPx!.dx -
                            _androidPrivatePinOverlayWidth / 2,
                        top: _androidOrientationReperOverlayPx!.dy -
                            _androidPrivatePinOverlayHeight -
                            _androidOrientationReperLabelBlock,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (mounted) _showOrientationReperPinActions();
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 160,
                                height: _androidOrientationReperLabelBlock,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      _orientationPinLabelForMapAnnotation(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: _androidPrivatePinOverlayWidth,
                                height: _androidPrivatePinOverlayHeight,
                                child: Image.memory(
                                  _androidOrientationReperOverlayBytes!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                  filterQuality: FilterQuality.medium,
                                ),
                              ),
                            ],
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
                                Builder(
                                  builder: (context) {
                                    final mapAppearsDark =
                                        !AppDrawer.lowDataMode &&
                                            Theme.of(context).brightness ==
                                                Brightness.dark;
                                    const strongOrangeMapHud =
                                        Color(0xFFFF6D00);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        _androidUserMarkerOverlayLabel!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: mapAppearsDark
                                              ? strongOrangeMapHud
                                              : const Color(0xFF1A237E),
                                          height: 1.05,
                                          shadows: [
                                            Shadow(
                                              color: mapAppearsDark
                                                  ? Colors.black54
                                                  : Colors.white,
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    // Eticheta proprie (nume/număr) este acum baked în LocationPuck2D.topImage
                    // și nu mai necesită overlay Flutter (eliminat pentru a nu rămâne în urmă).
                  ],
                );
              },
            ),

            // 📍 STRADA + scară — margini aliniate cu hamburger+POI stânga / AI+profil dreapta
            Positioned(
              top: 78,
              left: 132,
              right: 120,
              child: Center(
                child: Builder(
                  builder: (context) {
                    // Folosim [Theme] din [MaterialApp], nu [Consumer<ThemeProvider>] —
                    // evităm dublă notificare în același ciclu cu schimbarea de stil Mapbox.
                    final mapAppearsDark = !AppDrawer.lowDataMode &&
                        Theme.of(context).brightness == Brightness.dark;
                    const strongOrangeMapHud = Color(0xFFFF6D00);
                    final streetStyle = TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: mapAppearsDark ? strongOrangeMapHud : Colors.black,
                      letterSpacing: -0.5,
                    );
                    // Scară + °C: același tratament ca strada — bold, fără umbre/contur.
                    final subStyle = TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: mapAppearsDark
                          ? strongOrangeMapHud
                          : Colors.grey.shade800,
                      letterSpacing: -0.5,
                      shadows: const <Shadow>[],
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
                              Text('${_weatherTemp!.round()}°C',
                                  style: subStyle),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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
                            BoxShadow(
                                color: Colors.white.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                          border: Border.all(color: Colors.white12, width: 1),
                        ),
                        child: const Icon(Icons.menu_rounded,
                            color: Colors.white, size: 24),
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
                          BoxShadow(
                              color: const Color(0xFF0EA5E9)
                                  .withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                        border: Border.all(
                            color:
                                const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                            width: 1),
                      ),
                      child: const Icon(Icons.place_rounded,
                          color: Color(0xFF0EA5E9), size: 24),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BusinessOffersScreen()),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFFF6D00)
                                  .withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                        border: Border.all(
                            color:
                                const Color(0xFFFF6D00).withValues(alpha: 0.3),
                            width: 1),
                      ),
                      child: const Icon(Icons.local_offer_rounded,
                          color: Color(0xFFFF6D00), size: 22),
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
                      if (canShowVoiceAI) ...[
                        const SizedBox(width: 8),
                        Consumer2<FriendsRideVoiceIntegration,
                            AssistantStatusProvider>(
                          builder: (ctx, voiceIntegration, statusProvider, _) {
                            return _buildAiGlassButton(
                              processingState: voiceIntegration
                                  .currentContext.processingState,
                              isDark: Theme.of(context).brightness ==
                                  Brightness.dark,
                              onTap: () async {
                                statusProvider
                                    .setStatus(AssistantWorkStatus.working);
                                try {
                                  await voiceIntegration
                                      .startVoiceInteraction();
                                } catch (e) {
                                  statusProvider
                                      .setStatus(AssistantWorkStatus.idle);
                                }
                              },
                            );
                          },
                        ),
                      ],
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => unawaited(_softRefreshMapDisplay()),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: Colors.white12, width: 1),
                          ),
                          child: const Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PersonalInfoScreen()),
                        ),
                        child: Builder(
                          builder: (context) {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null) {
                              return Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black12, blurRadius: 10)
                                  ],
                                ),
                                child: const Center(
                                  child: Text('👤',
                                      style: TextStyle(fontSize: 24)),
                                ),
                              );
                            }
                            return StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .snapshots(),
                              builder: (context, snap) {
                                final data = snap.data?.data();
                                final photoURL = data?['photoURL'] as String?;
                                final hasPhoto =
                                    photoURL != null && photoURL.isNotEmpty;
                                final avatar =
                                    data?['avatar'] as String? ?? '👤';

                                if (hasPhoto) {
                                  return Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 10)
                                      ],
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        photoURL,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.white,
                                          child: Center(
                                              child: Text(avatar,
                                                  style: const TextStyle(
                                                      fontSize: 24))),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black12, blurRadius: 10)
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(avatar,
                                        style: const TextStyle(fontSize: 24)),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) {
                      final myUid = FirebaseAuth.instance.currentUser?.uid;
                      final hasMine = _hasMyMapEmojiPlaced(myUid);
                      final screenW = MediaQuery.sizeOf(context).width;
                      final panelMaxW = (screenW - 48).clamp(220.0, 288.0);
                      if (!_showEmojiPicker && !hasMine) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_showEmojiPicker)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding:
                                    const EdgeInsets.fromLTRB(10, 10, 10, 8),
                                width: panelMaxW,
                                constraints: BoxConstraints(
                                  maxWidth: panelMaxW,
                                  maxHeight: math.min(280,
                                      MediaQuery.sizeOf(context).height * 0.42),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black26, blurRadius: 10)
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          alignment: WrapAlignment.end,
                                          spacing: 2,
                                          runSpacing: 4,
                                          children:
                                              _kMapReactionEmojis.map((e) {
                                            return Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () async {
                                                  if (_currentPositionObject ==
                                                      null) {
                                                    return;
                                                  }
                                                  final uid = FirebaseAuth
                                                      .instance
                                                      .currentUser
                                                      ?.uid;
                                                  if (uid == null ||
                                                      uid.isEmpty) {
                                                    if (mounted) {
                                                      _showSafeSnackBar(
                                                        'Autentifică-te ca să plasezi emoji pe hartă',
                                                        const Color(0xFFB71C1C),
                                                      );
                                                    }
                                                    return;
                                                  }
                                                  try {
                                                    final chosen =
                                                        normalizeMapEmojiForEngine(
                                                            e);
                                                    final docId =
                                                        await MapEmojiService()
                                                            .addEmoji(
                                                      lat:
                                                          _currentPositionObject!
                                                              .latitude,
                                                      lng:
                                                          _currentPositionObject!
                                                              .longitude,
                                                      emoji: chosen,
                                                      senderId: uid,
                                                    );
                                                    if (!mounted) return;
                                                    HapticFeedback
                                                        .lightImpact();
                                                    if (docId != null) {
                                                      final optimistic =
                                                          MapEmoji(
                                                        id: docId,
                                                        lat:
                                                            _currentPositionObject!
                                                                .latitude,
                                                        lng:
                                                            _currentPositionObject!
                                                                .longitude,
                                                        emoji: chosen,
                                                        timestamp:
                                                            DateTime.now(),
                                                        senderId: uid,
                                                      );
                                                      setState(() {
                                                        _lastReceivedEmojis = [
                                                          ..._lastReceivedEmojis
                                                              .where((x) =>
                                                                  x.id !=
                                                                  docId),
                                                          optimistic,
                                                        ]..sort((a, b) => a
                                                            .timestamp
                                                            .compareTo(
                                                                b.timestamp));
                                                        _showEmojiPicker =
                                                            false;
                                                      });
                                                      unawaited(_updateEmojiMarkers(
                                                          _lastReceivedEmojis));
                                                    } else {
                                                      setState(() =>
                                                          _showEmojiPicker =
                                                              false);
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
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 4),
                                                  child: Text(e,
                                                      style: const TextStyle(
                                                          fontSize: 26)),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    if (hasMine) ...[
                                      Divider(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          height: 16),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 8),
                                          alignment: Alignment.centerLeft,
                                        ),
                                        onPressed: _removeMyMapEmoji,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.delete_outline_rounded,
                                                color: Colors.red.shade200,
                                                size: 20),
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
                            if (!_showEmojiPicker && hasMine)
                              Material(
                                color: Colors.black.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  onTap: _removeMyMapEmoji,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.layers_clear_rounded,
                                          color: Colors.red.shade200,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                              maxWidth: panelMaxW - 56),
                                          child: Text(
                                            'Scoate emoji',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.95),
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
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  RightGlassFloatingPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildBumpFloatingButton(
                          icon: Icons.search_rounded,
                          onTap: () =>
                              setState(() => _universalSearchOpen = true),
                        ),
                        const SizedBox(height: 12),
                        _buildBumpFloatingButton(
                          icon: _isVisibleToNeighbors
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          onTap: _toggleVisibleToNeighbors,
                        ),
                        const SizedBox(height: 12),
                        _buildBumpFloatingButton(
                          icon: Icons.add_a_photo_outlined,
                          onTap: _showPostMomentSheet,
                        ),
                        const SizedBox(height: 12),
                        // Emoji pe hartă
                        Builder(
                          builder: (context) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FloatingActionButton(
                                  mini: true,
                                  heroTag: 'emoji_picker_fab',
                                  backgroundColor: _showEmojiPicker
                                      ? Colors.pink
                                      : Colors.white,
                                  onPressed: () => setState(() =>
                                      _showEmojiPicker = !_showEmojiPicker),
                                  child: Icon(
                                    _showEmojiPicker
                                        ? Icons.close
                                        : Icons.face_retouching_natural_rounded,
                                    color: _showEmojiPicker
                                        ? Colors.white
                                        : Colors.pink,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildBumpFloatingButton(
                                  icon: _showRecenterBtn
                                      ? Icons.my_location
                                      : Icons.my_location,
                                  color: _showRecenterBtn
                                      ? Colors.blue
                                      : Colors.black,
                                  onTap: () {
                                    setState(() {
                                      _followingEnabled = true;
                                      _showRecenterBtn = false;
                                    });
                                    _getCurrentLocation(centerCamera: true);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildBumpFloatingButton(
                                  icon: _flashlightOn
                                      ? Icons.flashlight_on_rounded
                                      : Icons.flashlight_off_rounded,
                                  color: _flashlightOn
                                      ? Colors.amber
                                      : Colors.black,
                                  onTap: _toggleFlashlight,
                                ),
                                const SizedBox(height: 12),
                                _buildBumpFloatingButton(
                                  icon: Icons.ios_share_rounded,
                                  onTap: _shareCurrentLocation,
                                ),
                                const SizedBox(height: 12),
                                _buildBumpFloatingButton(
                                  icon: Icons.radar,
                                  color: Colors.white,
                                  bgColor: const Color(0xFF7C3AED),
                                  onTap: () {
                                    if (_currentPositionObject != null) {
                                      setState(() {
                                        _radarCenter = Point(
                                          coordinates: Position(
                                            _currentPositionObject!.longitude,
                                            _currentPositionObject!.latitude,
                                          ),
                                        );
                                        _isRadarMode = true;
                                      });
                                    } else {
                                      _showSafeSnackBar(
                                          l10n.mapWaitingGpsLocation,
                                          Colors.red);
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildBumpFloatingButton(
                                  icon: Icons.add_location_alt_rounded,
                                  color: Colors.white,
                                  bgColor: Colors.indigo,
                                  onTap: () {
                                    if (_currentPositionObject != null) {
                                      NeighborhoodRequestsManager
                                          .showCreateRequestSheet(
                                        context,
                                        _currentPositionObject!.latitude,
                                        _currentPositionObject!.longitude,
                                      );
                                    } else {
                                      _showSafeSnackBar(
                                          l10n.mapWaitingGpsLocation,
                                          Colors.red);
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildBumpFloatingButton(
                                  icon: Icons.notifications_rounded,
                                  color: const Color(0xFF7C3AED),
                                  onTap: _openActivityNotifications,
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
                                if (shouldShowPassengerUI) ...[
                                  const SizedBox(height: 12),
                                  _buildBumpFloatingButton(
                                    icon: Icons.edit_location_alt_rounded,
                                    color: const Color(0xFF0EA5E9),
                                    onTap: _onItineraryButtonPressed,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (!shouldShowPassengerUI &&
                _currentRole == UserRole.driver &&
                _isDriverAvailable)
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
                onNewRideAssigned: (ride) =>
                    unawaited(_playRideOfferSoundRobust()),
                onNavigateToRide: _openRideFlowFromMap,
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
                          if (now
                                  .difference(_lastPoiCardPanUpdate)
                                  .inMilliseconds <
                              _poiCardPanThrottleMs) {
                            return;
                          }
                          _lastPoiCardPanUpdate = now;
                          setState(() {
                            final double maxX = screenSize.width -
                                cardWidth -
                                horizontalPadding;
                            final double maxY = screenSize.height -
                                200.0; // keep inside viewport
                            double newX =
                                _poiCardPosition.dx + details.delta.dx;
                            double newY =
                                _poiCardPosition.dy + details.delta.dy;
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
                            onSetAsDestination: () =>
                                _setPOIAsDestination(_selectedPoi!),
                            onAddAsStop: () => _addPOIAsStop(_selectedPoi!),
                            onAddAsFavorite: () =>
                                _onPoiAddFavorite(_selectedPoi!),
                            onNavigateHere: () =>
                                _onPoiNavigateHere(_selectedPoi!),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ✅ CONECTARE 1: Intermediate stops list
            if (_routeCtrl.intermediateStops.isNotEmpty)
              Positioned(
                top: 100,
                left: 16,
                right: 16,
                child: MapIntermediateStops(
                  stops: _routeCtrl.intermediateStops,
                  onRemoveStop: _removeStop,
                ),
              ),

            // Camera control buttons moved to AppBar

            // ✅ Alt routes toggle & preview card + ETA/distance preview pentru ruta curentă
            if (_routeCtrl.alternativeRoutes.isNotEmpty)
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
                        if (_routeCtrl.currentRouteDistanceMeters != null &&
                            _routeCtrl.currentRouteDurationSeconds != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.directions, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_routingService.formatDuration(_routeCtrl.currentRouteDurationSeconds!)} • ${_routingService.formatDistance(_routeCtrl.currentRouteDistanceMeters!)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_routeCtrl.pickupQualityLabel != null &&
                                    _routeCtrl.pickupQualityColor != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _routeCtrl.pickupQualityColor!
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: _routeCtrl
                                                .pickupQualityColor!
                                                .withValues(alpha: 0.6)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.flag_rounded,
                                              size: 14,
                                              color: _routeCtrl
                                                  .pickupQualityColor),
                                          const SizedBox(width: 6),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth: 96),
                                            child: Text(
                                              _routeCtrl.pickupQualityLabel!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: _routeCtrl
                                                      .pickupQualityColor),
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
                            const Text('Rute alternative',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (_routeCtrl.isFetchingAlternatives)
                              const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                                _routeCtrl.alternativeRoutes.length, (i) {
                              final r = _routeCtrl.alternativeRoutes[i];
                              final meters =
                                  (r['distance'] as num?)?.toDouble() ?? 0.0;
                              final seconds =
                                  (r['duration'] as num?)?.toDouble() ?? 0.0;
                              final dist =
                                  _routingService.formatDistance(meters);
                              final eta =
                                  _routingService.formatDuration(seconds);
                              final selected =
                                  i == _routeCtrl.selectedAltRouteIndex;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text('$eta • $dist'),
                                  selected: selected,
                                  onSelected: (val) async {
                                    setState(() {
                                      _routeCtrl.selectedAltRouteIndex = i;
                                    });
                                    // Re-desenăm ruta: selectata ca principală + celelalte faint
                                    final reordered = <Map<String, dynamic>>[
                                      r,
                                      ..._routeCtrl.alternativeRoutes
                                          .where((e) => !identical(e, r))
                                          .cast<Map<String, dynamic>>()
                                    ];
                                    await _onRouteCalculated(
                                        {'routes': reordered});
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
            if (_routeCtrl.alternativeRoutes.isNotEmpty &&
                !_routeCtrl.tipAltRoutesSeen)
              Positioned(
                bottom: 160 + MediaQuery.of(context).padding.bottom,
                left: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      setState(() {
                        _routeCtrl.tipAltRoutesSeen = true;
                      });
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('tip_alt_routes_seen', true);
                      } catch (_) {
                        /* Mapbox op — expected on style reload or missing layer/annotation */
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                          'Tip: alege ruta alternativă cea mai rapidă.',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ),
              ),

            // ✅ Pickup suggestions chips
            if (_routeCtrl.showPickupSuggestions &&
                _routeCtrl.pickupSuggestionPoints.isNotEmpty)
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
                      children: List.generate(
                          _routeCtrl.pickupSuggestionPoints.length, (i) {
                        return ActionChip(
                          avatar: const Icon(Icons.trip_origin, size: 18),
                          label: Text(AppLocalizations.of(context)!
                              .mapPickupIndex(i + 1)),
                          onPressed: () {
                            final pt = _routeCtrl.pickupSuggestionPoints[i];
                            setState(() {
                              _routeCtrl.pickupLatitude =
                                  pt.coordinates.lat.toDouble();
                              _routeCtrl.pickupLongitude =
                                  pt.coordinates.lng.toDouble();
                              _routeCtrl.showPickupSuggestions = false;
                            });
                            _updateMapWithNewPickup();
                            _showSafeSnackBar(
                                AppLocalizations.of(context)!
                                    .mapPickupPointSelected,
                                Colors.blue);
                          },
                        );
                      }),
                    ),
                  ),
                ),
              ),

            // ✅ CONECTARE 2: Ride info panel
            if ((_routeCtrl.pickupLatitude != null ||
                    _routeCtrl.destinationLatitude != null) &&
                !shouldShowPassengerUI)
              Positioned(
                bottom: 200 + MediaQuery.of(context).padding.bottom,
                left: 16,
                right: 16,
                child: MapRideInfoPanel(
                  pickupLatitude: _routeCtrl.pickupLatitude,
                  destinationLatitude: _routeCtrl.destinationLatitude,
                  pickupText: _routeCtrl.pickupController.text,
                  destinationText: _routeCtrl.destinationController.text,
                  stopsCount: _routeCtrl.intermediateStops.length,
                  onClearPickup: _clearPickup,
                  onClearDestination: _clearDestination,
                  onStartRide: _startRideRequest,
                ),
              ),

            if (_currentRole == UserRole.passenger &&
                _passengerSessionRide != null)
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
                              Shadow(
                                  color: Colors.black38,
                                  blurRadius: 10,
                                  offset: Offset(0, 4)),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 14,
                          child: Icon(
                            _isDraggingPin
                                ? Icons.open_with
                                : Icons.drag_indicator,
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
            if (_routeCtrl.inAppNavActive)
              Positioned(
                top: 104, // Sub chips-urile de POI (body sub SafeArea)
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => unawaited(
                      _stopInAppNavigation()), // Atinge pentru a opri navigarea
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                      ],
                      border: Border.all(
                          color: const Color(0xFF00E676).withValues(alpha: 0.5),
                          width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.navigation_rounded,
                            color: Color(0xFF00E676), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _routeCtrl.navCurrentInstruction.isEmpty
                                ? "Navigare activă"
                                : _routeCtrl.navCurrentInstruction,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_routeCtrl.navRemainDistanceM > 0 ||
                            _routeCtrl.navRemainEta.inSeconds > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${_routeCtrl.navRemainDistanceM > 0 ? (_routeCtrl.navRemainDistanceM > 1000 ? "${(_routeCtrl.navRemainDistanceM / 1000).toStringAsFixed(1)} km" : "${_routeCtrl.navRemainDistanceM.toStringAsFixed(0)} m") : ""} ${_routeCtrl.navRemainEta.inSeconds > 0 ? "• ${_routeCtrl.navRemainEta.inMinutes} min" : ""}'
                                .trim(),
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

                if (!canShowVoiceAI) return const SizedBox.shrink();
                if (!voiceIntegration.isVoiceActive) {
                  return const SizedBox.shrink();
                }

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

            // Indicator asistent — doar dacă UI vocal e activat în setări
            if (canShowVoiceAI) const AssistantStatusOverlay(),

            // 👻 GHOST HUD (Debug only)
            if (kDebugMode)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 16,
                right: 16,
                child: _GhostHUD(),
              ),

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
                          MaterialPageRoute(
                              builder: (_) => const WeekReviewScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildMiniAction(
                        icon: Icons.campaign_rounded,
                        label: 'Cereri',
                        color: const Color(0xFF7C3AED),
                        badge: _badgesCtrl.cereriCount > 0
                            ? _badgesCtrl.cereriCount
                            : null,
                        onTap: () {
                          Navigator.of(context)
                              .push<void>(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const RideBroadcastFeedScreen()),
                          )
                              .then((_) {
                            if (mounted) {
                              unawaited(_recomputeCereriQuickActionBadge());
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _openFriendSuggestions,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.35),
                                  width: 1.4,
                                ),
                              ),
                              child: const Icon(
                                Icons.people_alt_rounded,
                                size: 21,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            if (_badgesCtrl.friendRequestCount > 0)
                              Positioned(
                                top: -5,
                                right: -5,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    _badgesCtrl.friendRequestCount > 99
                                        ? '99+'
                                        : '$_badgesCtrl.friendRequestCount',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          _badgesCtrl.friendRequestCount > 9
                                              ? 9
                                              : 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            if (_badgesCtrl.privateChatUnreadCount > 0)
                              Positioned(
                                top: -6,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      _badgesCtrl.privateChatUnreadCount > 99
                                          ? '99+'
                                          : '${_badgesCtrl.privateChatUnreadCount}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            _badgesCtrl.privateChatUnreadCount >
                                                    9
                                                ? 9
                                                : 11,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildMiniAction(
                        icon: Icons.forum_rounded,
                        label: 'Chat',
                        color: const Color(0xFF7C3AED),
                        badge: _badgesCtrl.chatBadgeCount > 0
                            ? _badgesCtrl.chatBadgeCount
                            : null,
                        onTap: () async {
                          final result =
                              await Navigator.of(context).push<dynamic>(
                            MaterialPageRoute(
                                builder: (_) => const NeighborhoodChatScreen()),
                          );
                          if (mounted) {
                            unawaited(_recountNbChatQuickActionBadge());
                          }
                          if (result != null &&
                              result is Map &&
                              result['action'] == 'flyTo' &&
                              mounted) {
                            final lat = (result['lat'] as num).toDouble();
                            final lng = (result['lng'] as num).toDouble();
                            await _mapboxMap?.flyTo(
                              CameraOptions(
                                center: Point(coordinates: Position(lng, lat)),
                                zoom: 16.5,
                                pitch: 0,
                              ),
                              MapAnimationOptions(duration: 2000),
                            );
                            unawaited(_requestsManager
                                ?.showTransientLocationPin(lat, lng));
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

            // Pasager: sugestii + panou cursă — după bara de jos ca să fie deasupra (z-order).
            if (shouldShowPassengerUI) ...[
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
                if (_rideAddressSheetVisible || _routeCtrl.inAppNavActive)
                  RideRequestPanel(
                    key: _rideRequestPanelKey,
                    draggableController: _rideSheetController,
                    startPosition: _currentPositionObject!,
                    onRouteCalculated: _onRouteCalculated,
                    onDestinationPreview: _onDestinationPreview,
                    onStartNavigation: (pt, addr) => unawaited(
                        _startInAppNavigation(pt.coordinates.lat.toDouble(),
                            pt.coordinates.lng.toDouble(), addr)),
                    isNavigating: _routeCtrl.inAppNavActive,
                    onClose: _closeRideAddressSheet,
                  ),
              ] else
                const Center(child: CircularProgressIndicator()),
            ],

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

            // ── Map Chat: bule de vorbire + monitor ──
            ..._buildMapChatOverlays(),

            if (_universalSearchOpen)
              Positioned.fill(
                child: MapUniversalSearchOverlay(
                  onClose: () {
                    if (mounted) setState(() => _universalSearchOpen = false);
                  },
                  contacts: _contactUsers,
                  friendPeerUids: _friendPeerUids,
                  visibleNeighbors: _neighborData.values.toList(),
                  neighborEmojiByUid:
                      Map<String, String>.from(_neighborAvatarCache),
                  neighborPhotoUrlByUid:
                      Map<String, String>.from(_neighborPhotoURLCache),
                  userPosition: _currentPositionObject,
                  orientationLandmark: _manualOrientationPin == null
                      ? null
                      : (
                          label: _effectiveOrientationPinLabelForMap(),
                          lat: _manualOrientationPin!.latitude,
                          lng: _manualOrientationPin!.longitude,
                        ),
                  onPlaceChosen: _onUniversalSearchPlace,
                  onContactChosen: _onUniversalSearchContact,
                  onAddFriend: _sendFriendRequestFromSearch,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleParkingReservationSync() {
    _showSafeSnackBar(
        'GHOST: Rezervare loc parcare confirmată!', Colors.amber.shade900);
  }
}

class _GhostHUD extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NabourGhostOrchestrator(),
      builder: (context, _) {
        final ghost = NabourGhostOrchestrator();
        if (!ghost.isActive) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.purpleAccent.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Colors.purpleAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AI GHOST MODE ACTIVE',
                      style: TextStyle(
                        color: Colors.purpleAccent.shade100,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_getStepLabel(ghost.currentStep)} [${ghost.activeRole.name.toUpperCase()}]',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (ghost.lastRobotMessage.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LAST: "${ghost.lastRobotMessage}"',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getStepLabel(GhostTestStep step) {
    switch (step) {
      case GhostTestStep.idle:
        return 'Idle';
      case GhostTestStep.passengerInitialRequest:
        return 'Ghost: Requesting ride...';
      case GhostTestStep.passengerConfirmingAddress:
        return 'Ghost: Confirming address...';
      case GhostTestStep.passengerSearchingDriver:
        return 'Ghost: Searching for driver...';
      case GhostTestStep.switchingToDriver:
        return 'System: Switching to Driver...';
      case GhostTestStep.driverAcceptingRide:
        return 'Ghost: Accepting ride...';
      case GhostTestStep.switchingToPassenger:
        return 'System: Returning to Passenger...';
      case GhostTestStep.passengerConfirmingRide:
        return 'Ghost: Confirming trip...';
      case GhostTestStep.finished:
        return 'Completed ✅';
    }
  }
}
