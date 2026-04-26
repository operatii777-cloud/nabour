"""
Fix Part 2: Remove stub method signatures at file ends and add missing extension closers.
Fixes DEPTH=1 in all 9 part files.
"""
import sys
import os
sys.stdout.reconfigure(encoding='utf-8')

BASE = os.path.dirname(os.path.abspath(__file__))

def read_file(path):
    return open(os.path.join(BASE, path), encoding='utf-8').readlines()

def write_file(path, lines):
    with open(os.path.join(BASE, path), 'w', encoding='utf-8') as f:
        f.writelines(lines)
    depth = sum(l.count('{') - l.count('}') for l in lines)
    print(f'  Written: {path} ({len(lines)} lines, DEPTH={depth})')

def remove_line(lines, idx_0based):
    """Remove single line at idx_0based (0-indexed)."""
    return lines[:idx_0based] + lines[idx_0based+1:]

def remove_lines(lines, start_0, end_0_inclusive):
    return lines[:start_0] + lines[end_0_inclusive+1:]

def insert_before(lines, idx_0based, text):
    return lines[:idx_0based] + [text + '\n'] + lines[idx_0based:]

def add_extension_closer(lines):
    """Add extension closing } at end of file."""
    # Remove trailing blank lines, then add '}\n' + blank
    while lines and lines[-1].strip() == '':
        lines = lines[:-1]
    return lines + ['}\n', '\n']

# ─── Fix 1: map_bg_voice_part.dart ───────────────────────────────────────────
# Remove L376 stub: '  Future<void> _onMapCreated(MapboxMap mapboxMap) async {'
print("Fix 1: map_bg_voice_part.dart — remove _onMapCreated stub at L376")
lines = read_file(r'lib\screens\parts\map_bg_voice_part.dart')
assert '_onMapCreated' in lines[375], f'Expected stub at L376, got: {lines[375]!r}'
lines = remove_line(lines, 375)
write_file(r'lib\screens\parts\map_bg_voice_part.dart', lines)

# ─── Fix 2: map_emoji_moments_part.dart ──────────────────────────────────────
# Remove L1744-1745: '@override' + 'void didChangeDependencies() {'
print("\nFix 2: map_emoji_moments_part.dart — remove @override + didChangeDependencies stub")
lines = read_file(r'lib\screens\parts\map_emoji_moments_part.dart')
# Find @override + didChangeDependencies at end
target_idx = None
for i in range(len(lines)-1, max(0, len(lines)-20), -1):
    if '@override' in lines[i]:
        if i+1 < len(lines) and 'didChangeDependencies' in lines[i+1]:
            target_idx = i
            break
assert target_idx is not None, 'Could not find @override+didChangeDependencies at end'
print(f'  Found at L{target_idx+1}: {lines[target_idx].rstrip()!r}')
print(f'  Next L{target_idx+2}: {lines[target_idx+1].rstrip()!r}')
lines = remove_lines(lines, target_idx, target_idx+1)  # remove @override + signature
write_file(r'lib\screens\parts\map_emoji_moments_part.dart', lines)

# ─── Fix 3: map_init_part.dart ───────────────────────────────────────────────
# Remove stub: '  void _resetDriverMarkerInterpolation() {'
print("\nFix 3: map_init_part.dart — remove _resetDriverMarkerInterpolation stub")
lines = read_file(r'lib\screens\parts\map_init_part.dart')
target_idx = None
for i in range(len(lines)-1, max(0, len(lines)-10), -1):
    if '_resetDriverMarkerInterpolation' in lines[i] and '{' in lines[i]:
        target_idx = i
        break
assert target_idx is not None
print(f'  Found at L{target_idx+1}: {lines[target_idx].rstrip()!r}')
lines = remove_line(lines, target_idx)
write_file(r'lib\screens\parts\map_init_part.dart', lines)

# ─── Fix 4: map_interactions_part.dart ───────────────────────────────────────
# Insert '  }' before the last '}' (extension closer) to close _showParkingSwapDialog
print("\nFix 4: map_interactions_part.dart — insert method close before extension close")
lines = read_file(r'lib\screens\parts\map_interactions_part.dart')
# Find last '}' with 0 indentation (extension closer)
last_closer_idx = None
for i in range(len(lines)-1, max(0, len(lines)-10), -1):
    if lines[i].strip() == '}' and not lines[i].startswith(' '):
        last_closer_idx = i
        break
assert last_closer_idx is not None
print(f'  Extension closer at L{last_closer_idx+1}')
lines = insert_before(lines, last_closer_idx, '  }')
write_file(r'lib\screens\parts\map_interactions_part.dart', lines)

# ─── Fix 5: map_location_route_part.dart ─────────────────────────────────────
# Add extension closer '}' at end
print("\nFix 5: map_location_route_part.dart — add extension closer }")
lines = read_file(r'lib\screens\parts\map_location_route_part.dart')
lines = add_extension_closer(lines)
write_file(r'lib\screens\parts\map_location_route_part.dart', lines)

# ─── Fix 6: map_markers_part.dart ────────────────────────────────────────────
# Remove stub: '  void _listenForRideBroadcasts() {'
print("\nFix 6: map_markers_part.dart — remove _listenForRideBroadcasts stub")
lines = read_file(r'lib\screens\parts\map_markers_part.dart')
target_idx = None
for i in range(len(lines)-1, max(0, len(lines)-10), -1):
    if '_listenForRideBroadcasts' in lines[i] and '{' in lines[i]:
        target_idx = i
        break
assert target_idx is not None
print(f'  Found at L{target_idx+1}: {lines[target_idx].rstrip()!r}')
lines = remove_line(lines, target_idx)
write_file(r'lib\screens\parts\map_markers_part.dart', lines)

# ─── Fix 7: map_neighbor_part.dart ───────────────────────────────────────────
# Add extension closer '}' at end
print("\nFix 7: map_neighbor_part.dart — add extension closer }")
lines = read_file(r'lib\screens\parts\map_neighbor_part.dart')
lines = add_extension_closer(lines)
write_file(r'lib\screens\parts\map_neighbor_part.dart', lines)

# ─── Fix 8: map_ride_flow_part.dart ──────────────────────────────────────────
# Remove stub: '  void _freezeMapWidgetCameraIfNeeded() {'
print("\nFix 8: map_ride_flow_part.dart — remove _freezeMapWidgetCameraIfNeeded stub")
lines = read_file(r'lib\screens\parts\map_ride_flow_part.dart')
target_idx = None
for i in range(len(lines)-1, max(0, len(lines)-10), -1):
    if '_freezeMapWidgetCameraIfNeeded' in lines[i] and '{' in lines[i]:
        target_idx = i
        break
assert target_idx is not None
print(f'  Found at L{target_idx+1}: {lines[target_idx].rstrip()!r}')
lines = remove_line(lines, target_idx)
write_file(r'lib\screens\parts\map_ride_flow_part.dart', lines)

# ─── Fix 9: map_social_part.dart ─────────────────────────────────────────────
# Remove stub: '  Future<void> _loadMagicEventCheckinIds() async {'
print("\nFix 9: map_social_part.dart — remove _loadMagicEventCheckinIds stub")
lines = read_file(r'lib\screens\parts\map_social_part.dart')
target_idx = None
for i in range(len(lines)-1, max(0, len(lines)-10), -1):
    if '_loadMagicEventCheckinIds' in lines[i] and '{' in lines[i]:
        target_idx = i
        break
assert target_idx is not None
print(f'  Found at L{target_idx+1}: {lines[target_idx].rstrip()!r}')
lines = remove_line(lines, target_idx)
write_file(r'lib\screens\parts\map_social_part.dart', lines)

print()
print("=" * 60)
print("ALL DEPTH FIXES APPLIED")
print("=" * 60)
