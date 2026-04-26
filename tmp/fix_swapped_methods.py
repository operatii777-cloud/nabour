"""
Fix the 5 method body swap issues caused by off-by-one extraction.

Issues:
1. map_screen.dart: _maybeStartMovementHistoryRecorder has lifecycle code (wrong)
2. map_screen.dart: _backgroundSocialMapPublishTick has AnimatedSwitcher widget (wrong)
3. map_bg_voice_part.dart: orphaned body lines 4-8 + didChangeAppLifecycleState has wrong body
4. map_location_route_part.dart: _buildContextualOverlay has empty body
5. map_neighbor_part.dart: _buildBumpFloatingButton has empty body
"""

import sys
sys.stdout.reconfigure(encoding='utf-8')

# ── Correct method bodies (from original git) ──────────────────────────────

RECORDER_METHOD = '''  Future<void> _maybeStartMovementHistoryRecorder() async {
    final enabled = await MovementHistoryPreferencesService.instance.isEnabled();
    if (!enabled) return;
    await MovementHistoryService.instance.startRecorder();
  }
'''

LIFECYCLE_BODY = '''  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _mapSurfaceSafeForUserMarker = true;
      Logger.info('App resumed - checking if we need to reset route state');

      _pausedSocialPublishTimer?.cancel();
      _pausedSocialPublishTimer = null;
      unawaited(AssistantVoiceUiPrefs.instance.load());

      final shouldRestoreDriverLiveMap = _hidDriverLiveMapPresenceForBackground &&
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
        Logger.debug('App resumed - restarting location updates and ride listener');
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
      if (_currentRole == UserRole.driver && _isDriverAvailable) {
        _hidDriverLiveMapPresenceForBackground = true;
        unawaited(_firestoreService.hideDriverLiveMapPresenceForAppBackground());
      }
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
'''

BG_PUBLISH_METHOD = '''  Future<void> _backgroundSocialMapPublishTick() async {
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
'''

CONTEXTUAL_OVERLAY_METHOD = '''  Widget _buildContextualOverlay() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutExpo,
      switchOutCurve: Curves.easeInCirc,
      child: _contextState == NabourContextState.driving
          ? MapDrivingHud(speedKmh: _currentSpeedKph)
          : _contextState == NabourContextState.walking
              ? const MapWalkingGlow(active: true)
              : const SizedBox.shrink(),
    );
  }
'''

BUMP_BUTTON_METHOD = '''  Widget _buildBumpFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black,
    Color bgColor = Colors.white,
    double size = 44,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
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
        child: Icon(icon, color: color, size: size * 0.54),
      ),
    );
  }
'''


def find_method_end(lines, start_idx):
    """Find the closing } of a method starting at start_idx."""
    depth = 0
    for i in range(start_idx, min(start_idx + 300, len(lines))):
        for ch in lines[i]:
            if ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
        if depth == 0 and i > start_idx:
            return i
    return start_idx + 50


# ── Fix 1 & 2: map_screen.dart ─────────────────────────────────────────────
print('=== Fixing map_screen.dart ===')
with open(r'lib\screens\map_screen.dart', encoding='utf-8') as f:
    ms_lines = f.readlines()

print(f'  Initial: {len(ms_lines)} lines')

# Find _maybeStartMovementHistoryRecorder
ms_recorder_start = None
for i, l in enumerate(ms_lines):
    if '_maybeStartMovementHistoryRecorder' in l and 'Future<void>' in l:
        ms_recorder_start = i
        break

if ms_recorder_start is None:
    print('  ERROR: Could not find _maybeStartMovementHistoryRecorder!')
else:
    ms_recorder_end = find_method_end(ms_lines, ms_recorder_start)
    print(f'  _maybeStartMovementHistoryRecorder: L{ms_recorder_start+1}-L{ms_recorder_end+1}')
    
    # Find _backgroundSocialMapPublishTick (AFTER recorder)
    ms_bg_start = None
    for i in range(ms_recorder_end + 1, min(ms_recorder_end + 50, len(ms_lines))):
        if '_backgroundSocialMapPublishTick' in ms_lines[i] and 'Future<void>' in ms_lines[i]:
            ms_bg_start = i
            break
    
    if ms_bg_start is None:
        print('  ERROR: Could not find _backgroundSocialMapPublishTick!')
    else:
        ms_bg_end = find_method_end(ms_lines, ms_bg_start)
        print(f'  _backgroundSocialMapPublishTick: L{ms_bg_start+1}-L{ms_bg_end+1}')
        
        # Replace both methods
        # Keep: lines before recorder, RECORDER_METHOD, blank, BG_PUBLISH_METHOD, lines after bg
        new_ms_lines = (
            ms_lines[:ms_recorder_start] +
            [RECORDER_METHOD] +
            ms_lines[ms_recorder_end + 1:ms_bg_start] +
            [BG_PUBLISH_METHOD] +
            ms_lines[ms_bg_end + 1:]
        )
        
        with open(r'lib\screens\map_screen.dart', 'w', encoding='utf-8') as f:
            f.writelines(new_ms_lines)
        print(f'  Fixed: {len(new_ms_lines)} lines')


# ── Fix 3: map_bg_voice_part.dart ─────────────────────────────────────────
print('\n=== Fixing map_bg_voice_part.dart ===')
with open(r'lib\screens\parts\map_bg_voice_part.dart', encoding='utf-8') as f:
    bg_lines = f.readlines()

print(f'  Initial: {len(bg_lines)} lines')

# The file starts with:
# Line 0: // ignore_for_file...
# Line 1: part of '../map_screen.dart';
# Line 2: (blank)
# Line 3: extension _MapBgVoiceMethods on _MapScreenState {
# Line 4-8: ORPHANED body (final enabled = await...)
# Line 9: (blank or @override)
# Line 10/11: void didChangeAppLifecycleState...  (with wrong body)
# ...

# Find extension opening brace line
ext_open = None
for i, l in enumerate(bg_lines):
    if 'extension _MapBgVoiceMethods on _MapScreenState {' in l:
        ext_open = i
        break

if ext_open is None:
    print('  ERROR: Could not find extension opening!')
else:
    print(f'  Extension opens at L{ext_open+1}')
    
    # Find didChangeAppLifecycleState
    lifecycle_start = None
    for i in range(ext_open, len(bg_lines)):
        if 'void didChangeAppLifecycleState' in bg_lines[i]:
            # Check for @override before it
            override_line = i - 1
            while override_line >= ext_open and bg_lines[override_line].strip() == '':
                override_line -= 1
            if bg_lines[override_line].strip() == '@override':
                lifecycle_start = override_line
            else:
                lifecycle_start = i
            break
    
    if lifecycle_start is None:
        print('  ERROR: Could not find didChangeAppLifecycleState!')
    else:
        lifecycle_end = find_method_end(bg_lines, lifecycle_start + (1 if bg_lines[lifecycle_start].strip() == '@override' else 0))
        print(f'  didChangeAppLifecycleState: L{lifecycle_start+1}-L{lifecycle_end+1}')
        
        # Everything between ext_open+1 and lifecycle_start is orphaned code
        orphaned_start = ext_open + 1
        orphaned_end = lifecycle_start  # exclusive
        print(f'  Orphaned code: L{orphaned_start+1}-L{orphaned_end} (will be removed)')
        
        # Build new bg_lines:
        # Keep header (0..ext_open inclusive)
        # Add blank line after extension opens
        # Skip orphaned (ext_open+1 .. lifecycle_start-1)
        # Replace lifecycle method with correct one
        # Keep rest (lifecycle_end+1 .. end)
        new_bg_lines = (
            bg_lines[:ext_open + 1] +
            ['\n'] +
            [LIFECYCLE_BODY] +
            ['\n'] +
            bg_lines[lifecycle_end + 1:]
        )
        
        with open(r'lib\screens\parts\map_bg_voice_part.dart', 'w', encoding='utf-8') as f:
            f.writelines(new_bg_lines)
        print(f'  Fixed: {len(new_bg_lines)} lines')


# ── Fix 4: map_location_route_part.dart ───────────────────────────────────
print('\n=== Fixing map_location_route_part.dart ===')
with open(r'lib\screens\parts\map_location_route_part.dart', encoding='utf-8') as f:
    lr_lines = f.readlines()

print(f'  Initial: {len(lr_lines)} lines')

lr_overlay_start = None
for i, l in enumerate(lr_lines):
    if 'Widget _buildContextualOverlay()' in l:
        lr_overlay_start = i
        break

if lr_overlay_start is None:
    print('  ERROR: Could not find _buildContextualOverlay!')
else:
    lr_overlay_end = find_method_end(lr_lines, lr_overlay_start)
    print(f'  _buildContextualOverlay: L{lr_overlay_start+1}-L{lr_overlay_end+1}')
    
    new_lr_lines = (
        lr_lines[:lr_overlay_start] +
        [CONTEXTUAL_OVERLAY_METHOD] +
        lr_lines[lr_overlay_end + 1:]
    )
    
    with open(r'lib\screens\parts\map_location_route_part.dart', 'w', encoding='utf-8') as f:
        f.writelines(new_lr_lines)
    print(f'  Fixed: {len(new_lr_lines)} lines')


# ── Fix 5: map_neighbor_part.dart ─────────────────────────────────────────
print('\n=== Fixing map_neighbor_part.dart ===')
with open(r'lib\screens\parts\map_neighbor_part.dart', encoding='utf-8') as f:
    nb_lines = f.readlines()

print(f'  Initial: {len(nb_lines)} lines')

nb_bump_start = None
for i, l in enumerate(nb_lines):
    if 'Widget _buildBumpFloatingButton(' in l:
        nb_bump_start = i
        break

if nb_bump_start is None:
    print('  ERROR: Could not find _buildBumpFloatingButton!')
else:
    nb_bump_end = find_method_end(nb_lines, nb_bump_start)
    print(f'  _buildBumpFloatingButton: L{nb_bump_start+1}-L{nb_bump_end+1}')
    
    new_nb_lines = (
        nb_lines[:nb_bump_start] +
        [BUMP_BUTTON_METHOD] +
        nb_lines[nb_bump_end + 1:]
    )
    
    with open(r'lib\screens\parts\map_neighbor_part.dart', 'w', encoding='utf-8') as f:
        f.writelines(new_nb_lines)
    print(f'  Fixed: {len(new_nb_lines)} lines')

print('\n=== All fixes applied! ===')
