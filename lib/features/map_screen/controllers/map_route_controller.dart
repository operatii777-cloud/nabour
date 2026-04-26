import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Deține tot state-ul de planificare rută și navigație in-app.
///
/// Expune câmpurile ca getteri cu setteri care apelează [notifyListeners].
/// [_MapScreenState] păstrează o referință și ascultă schimbările pentru
/// a apela [setState] o singură dată per frame.
class MapRouteController extends ChangeNotifier {
  // ── Planificare rută ──────────────────────────────────────────────────────

  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final List<TextEditingController> intermediateStopsControllers = [];
  final List<String> intermediateStops = [];
  static const int maxIntermediateStops = 5;

  double? get pickupLatitude => _pickupLatitude;
  double? get pickupLongitude => _pickupLongitude;
  double? get destinationLatitude => _destinationLatitude;
  double? get destinationLongitude => _destinationLongitude;

  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _destinationLatitude;
  double? _destinationLongitude;

  bool get isFetchingAlternatives => _isFetchingAlternatives;
  bool _isFetchingAlternatives = false;

  List<Map<String, dynamic>> get alternativeRoutes => _alternativeRoutes;
  List<Map<String, dynamic>> _alternativeRoutes = [];

  int get selectedAltRouteIndex => _selectedAltRouteIndex;
  int _selectedAltRouteIndex = 0;

  double? get currentRouteDistanceMeters => _currentRouteDistanceMeters;
  double? get currentRouteDurationSeconds => _currentRouteDurationSeconds;
  double? _currentRouteDistanceMeters;
  double? _currentRouteDurationSeconds;

  String? get pickupQualityLabel => _pickupQualityLabel;
  Color? get pickupQualityColor => _pickupQualityColor;
  String? _pickupQualityLabel;
  Color? _pickupQualityColor;

  bool get tipAltRoutesSeen => _tipAltRoutesSeen;
  bool _tipAltRoutesSeen = true;

  bool get showPickupSuggestions => _showPickupSuggestions;
  List<Point> get pickupSuggestionPoints => _pickupSuggestionPoints;
  bool _showPickupSuggestions = false;
  List<Point> _pickupSuggestionPoints = [];

  // ── Navigație in-app ──────────────────────────────────────────────────────

  bool get inAppNavActive => _inAppNavActive;
  bool _inAppNavActive = false;

  double? get navDestLat => _navDestLat;
  double? get navDestLng => _navDestLng;
  String get navDestLabel => _navDestLabel;
  double? _navDestLat;
  double? _navDestLng;
  String _navDestLabel = '';

  String get navCurrentInstruction => _navCurrentInstruction;
  String _navCurrentInstruction = '';

  double get navRemainDistanceM => _navRemainDistanceM;
  Duration get navRemainEta => _navRemainEta;
  double _navRemainDistanceM = 0;
  Duration _navRemainEta = Duration.zero;

  bool get navHasArrived => _navHasArrived;
  bool _navHasArrived = false;

  List<Map<String, dynamic>> get navSteps => _navSteps;
  int get navStepIndex => _navStepIndex;
  int navLastSpokenStep = -1;
  List<Map<String, dynamic>> _navSteps = [];
  int _navStepIndex = 0;

  /// Subscripție GPS activă în timpul navigației — gestionată de [_MapScreenState].
  StreamSubscription<geolocator.Position>? navGpsSubscription;

  /// Instanță TTS — creată și distrusă de [_MapScreenState] la start/stop nav.
  FlutterTts? navTts;

  /// Timer reîmprospătare ETA — gestionat de [_MapScreenState].
  Timer? navEtaTimer;

  // ── Setteri individuali (pentru setState blocks în _MapScreenState) ────────

  set pickupLatitude(double? v) { _pickupLatitude = v; notifyListeners(); }
  set pickupLongitude(double? v) { _pickupLongitude = v; notifyListeners(); }
  set destinationLatitude(double? v) { _destinationLatitude = v; notifyListeners(); }
  set destinationLongitude(double? v) { _destinationLongitude = v; notifyListeners(); }
  set isFetchingAlternatives(bool v) { _isFetchingAlternatives = v; notifyListeners(); }
  set selectedAltRouteIndex(int v) { _selectedAltRouteIndex = v; notifyListeners(); }
  set currentRouteDistanceMeters(double? v) { _currentRouteDistanceMeters = v; notifyListeners(); }
  set currentRouteDurationSeconds(double? v) { _currentRouteDurationSeconds = v; notifyListeners(); }
  set pickupQualityLabel(String? v) { _pickupQualityLabel = v; notifyListeners(); }
  set pickupQualityColor(Color? v) { _pickupQualityColor = v; notifyListeners(); }
  set tipAltRoutesSeen(bool v) { _tipAltRoutesSeen = v; notifyListeners(); }
  set showPickupSuggestions(bool v) { _showPickupSuggestions = v; notifyListeners(); }
  set alternativeRoutes(List<Map<String, dynamic>> v) { _alternativeRoutes = v; notifyListeners(); }
  set pickupSuggestionPoints(List<Point> v) { _pickupSuggestionPoints = v; notifyListeners(); }
  set inAppNavActive(bool v) { _inAppNavActive = v; notifyListeners(); }
  set navDestLat(double? v) { _navDestLat = v; notifyListeners(); }
  set navDestLng(double? v) { _navDestLng = v; notifyListeners(); }
  set navDestLabel(String v) { _navDestLabel = v; notifyListeners(); }
  set navCurrentInstruction(String v) { _navCurrentInstruction = v; notifyListeners(); }
  set navRemainDistanceM(double v) { _navRemainDistanceM = v; notifyListeners(); }
  set navRemainEta(Duration v) { _navRemainEta = v; notifyListeners(); }
  set navHasArrived(bool v) { _navHasArrived = v; notifyListeners(); }
  set navSteps(List<Map<String, dynamic>> v) { _navSteps = v; notifyListeners(); }
  set navStepIndex(int v) { _navStepIndex = v; notifyListeners(); }

  // ── Setteri cu notificare (batch) ─────────────────────────────────────────

  void setPickup({
    required double? lat,
    required double? lng,
    String? qualityLabel,
    Color? qualityColor,
  }) {
    _pickupLatitude = lat;
    _pickupLongitude = lng;
    _pickupQualityLabel = qualityLabel;
    _pickupQualityColor = qualityColor;
    notifyListeners();
  }

  void setDestination({required double? lat, required double? lng}) {
    _destinationLatitude = lat;
    _destinationLongitude = lng;
    notifyListeners();
  }

  void setAlternatives({
    required List<Map<String, dynamic>> routes,
    required int selectedIndex,
    double? distanceMeters,
    double? durationSeconds,
  }) {
    _alternativeRoutes = routes;
    _selectedAltRouteIndex = selectedIndex;
    _currentRouteDistanceMeters = distanceMeters;
    _currentRouteDurationSeconds = durationSeconds;
    notifyListeners();
  }

  void selectAltRoute(int index) {
    _selectedAltRouteIndex = index;
    notifyListeners();
  }

  void setFetchingAlternatives(bool value) {
    if (_isFetchingAlternatives == value) return;
    _isFetchingAlternatives = value;
    notifyListeners();
  }

  void setRouteSummary({
    required double? distanceMeters,
    required double? durationSeconds,
  }) {
    _currentRouteDistanceMeters = distanceMeters;
    _currentRouteDurationSeconds = durationSeconds;
    notifyListeners();
  }

  void setPickupSuggestions({
    required bool show,
    required List<Point> points,
  }) {
    _showPickupSuggestions = show;
    _pickupSuggestionPoints = points;
    notifyListeners();
  }

  void setTipAltRoutesSeen(bool value) {
    if (_tipAltRoutesSeen == value) return;
    _tipAltRoutesSeen = value;
    notifyListeners();
  }

  /// Resetează tot state-ul de planificare rută (fără a atinge navigația activă).
  void clearRoute() {
    _pickupLatitude = null;
    _pickupLongitude = null;
    _destinationLatitude = null;
    _destinationLongitude = null;
    _alternativeRoutes = [];
    _selectedAltRouteIndex = 0;
    _currentRouteDistanceMeters = null;
    _currentRouteDurationSeconds = null;
    _pickupQualityLabel = null;
    _pickupQualityColor = null;
    _showPickupSuggestions = false;
    _pickupSuggestionPoints = [];
    pickupController.clear();
    destinationController.clear();
    for (final c in intermediateStopsControllers) {
      c.dispose();
    }
    intermediateStopsControllers.clear();
    intermediateStops.clear();
    notifyListeners();
  }

  // ── Navigație setteri ─────────────────────────────────────────────────────

  void startNavigation({
    required double destLat,
    required double destLng,
    required String destLabel,
  }) {
    _inAppNavActive = true;
    _navDestLat = destLat;
    _navDestLng = destLng;
    _navDestLabel = destLabel;
    _navCurrentInstruction = '';
    _navRemainDistanceM = 0;
    _navRemainEta = Duration.zero;
    _navHasArrived = false;
    _navSteps = [];
    _navStepIndex = 0;
    navLastSpokenStep = -1;
    notifyListeners();
  }

  void updateNavProgress({
    required String instruction,
    required double remainDistanceM,
    required Duration remainEta,
    required int stepIndex,
    bool? hasArrived,
  }) {
    _navCurrentInstruction = instruction;
    _navRemainDistanceM = remainDistanceM;
    _navRemainEta = remainEta;
    _navStepIndex = stepIndex;
    if (hasArrived != null) _navHasArrived = hasArrived;
    notifyListeners();
  }

  void setNavSteps(List<Map<String, dynamic>> steps) {
    _navSteps = steps;
    notifyListeners();
  }

  void setNavLastSpokenStep(int index) {
    navLastSpokenStep = index;
  }

  void stopNavigation() {
    _inAppNavActive = false;
    _navDestLat = null;
    _navDestLng = null;
    _navDestLabel = '';
    _navCurrentInstruction = '';
    _navRemainDistanceM = 0;
    _navRemainEta = Duration.zero;
    _navHasArrived = false;
    _navSteps = [];
    _navStepIndex = 0;
    navLastSpokenStep = -1;
    navGpsSubscription?.cancel();
    navGpsSubscription = null;
    navEtaTimer?.cancel();
    navEtaTimer = null;
    notifyListeners();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    pickupController.dispose();
    destinationController.dispose();
    for (final c in intermediateStopsControllers) {
      c.dispose();
    }
    navGpsSubscription?.cancel();
    navEtaTimer?.cancel();
    navTts?.stop();
    super.dispose();
  }
}
