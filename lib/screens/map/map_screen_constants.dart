/// Constants, layer IDs, and shared magic numbers for the map screen.
/// Extracted from the monolithic map_screen.dart — see map_screen.dart for mixin map.

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Sentinel: the user chose to be permanently invisible.
// ---------------------------------------------------------------------------
const Duration kInvisibleChoice = Duration(microseconds: -1);

// ---------------------------------------------------------------------------
// Emoji reactions placed on the map (quick reactions).
// ---------------------------------------------------------------------------

/// Emoji-uri plasabile pe hartă (reacții rapide).
const List<String> kMapReactionEmojis = [
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
const double kMapReactionEmojiIconSize = 0.56;

/// Emoji rapide plasate pe hartă la poziția contactului (tap pe marker).
const List<String> kNeighborQuickMapEmojis = [
  '\u2764\uFE0F',
  '👋',
  '🔥',
  '😂',
  '👍',
  '🎉',
  '📍',
  '☕',
];

const List<Map<String, String>> kReactions = [
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

// ---------------------------------------------------------------------------
// Home-pin asset resolution order.
// ---------------------------------------------------------------------------
const List<String> kHomePinAssetCandidates = [
  'assets/images/home_pin_v2.png',
  'assets/images/home_pin.png',
  'assets/images/home_pinv2.png',
];

// ---------------------------------------------------------------------------
// Zoom helper (Web Mercator).
// ---------------------------------------------------------------------------

/// Zoom pentru care lățimea vizibilă pe sol ≈ [visibleWidthM] m (Web Mercator;
/// același model ca eticheta scale bar).
double mapZoomForVisibleGroundWidthMeters({
  required double latitudeDeg,
  required double mapWidthPx,
  double visibleWidthM = 3000.0,
}) {
  if (mapWidthPx <= 0 || visibleWidthM <= 0) return 14.0;
  final cosLat = math.cos(latitudeDeg.clamp(-85.0, 85.0) * math.pi / 180);
  final z = math.log(156543.03392 * cosLat * mapWidthPx / visibleWidthM) / math.ln2;
  return z.clamp(3.0, 19.0);
}

// ---------------------------------------------------------------------------
// Former _MapScreenState static constants — now top-level for mixin access.
// ---------------------------------------------------------------------------
const double defaultOverviewVisibleWidthM = 3000.0;
const int poiCardPanThrottleMs = 24;

// Shake-detection tuning.
const double shakeThreshold = 40.0;
const int requiredShakes = 3;
const Duration shakeWindow = Duration(seconds: 2);

// Panning hard-clamp radius & gap.
const double panningHardRadiusKm = 8.0;
const Duration panClampMinGap = Duration(seconds: 3);

// Intermediate stops.
const int maxIntermediateStops = 5;

// Parking-yield verify.
const double parkingYieldVerifyRadiusM = 45.0;
const bool showParkingYieldMapButton = false;

// Debug / verbose build logs.
const bool verboseBuildLogs = false;

// Driver-ETA throttle.
const Duration driverEtaThrottle = Duration(seconds: 10);
const double driverEtaDistanceThresholdMeters = 80.0;

// Location-update intervals (seconds).
const int standingInterval = 15;
const int slowSpeedInterval = 7;
const int highSpeedInterval = 7;

// POI source / layer IDs.
const String poiSourceId = 'poi-source';
const String poiClusterLayerId = 'poi-clusters';
const String poiClusterCountLayerId = 'poi-cluster-count';
const String poiSymbolLayerId = 'poi-symbols';
const String selectedPoiSourceId = 'selected-poi-source';
const String selectedPoiLayerId = 'selected-poi-layer';
