"""
Fix all broken part files and map_screen.dart.
Applies all fixes needed for the part/extension pattern errors.
"""
import sys
import os
sys.stdout.reconfigure(encoding='utf-8')

BASE = os.path.dirname(os.path.abspath(__file__))

def read_file(path):
    full = os.path.join(BASE, path)
    return open(full, encoding='utf-8').readlines()

def write_file(path, lines):
    full = os.path.join(BASE, path)
    with open(full, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print(f'  Written: {path} ({len(lines)} lines)')

def insert_before_line(lines, idx, text):
    """Insert text before lines[idx] (0-based)."""
    return lines[:idx] + [text + '\n'] + lines[idx:]

def remove_lines(lines, start_0, end_0_inclusive):
    """Remove lines from start_0 to end_0_inclusive (0-based, inclusive)."""
    return lines[:start_0] + lines[end_0_inclusive+1:]

print("=" * 60)
print("Fix 1: map_emoji_moments_part.dart")
print("=" * 60)
# Insert 'void _initEmojiListener() {' before L5 (idx=4)
lines = read_file(r'lib\screens\parts\map_emoji_moments_part.dart')
print(f'  L5 before fix: {lines[4].rstrip()!r}')
lines = insert_before_line(lines, 4, '  void _initEmojiListener() {')
print(f'  L5 after fix: {lines[4].rstrip()!r}')
print(f'  L6 after fix: {lines[5].rstrip()!r}')
write_file(r'lib\screens\parts\map_emoji_moments_part.dart', lines)

print()
print("=" * 60)
print("Fix 2: map_init_part.dart")
print("=" * 60)
# Insert 'Future<void> _onMapCreated(MapboxMap mapboxMap) async {' before L5 (idx=4)
lines = read_file(r'lib\screens\parts\map_init_part.dart')
print(f'  L5 before fix: {lines[4].rstrip()!r}')
lines = insert_before_line(lines, 4, '  Future<void> _onMapCreated(MapboxMap mapboxMap) async {')
print(f'  L5 after fix: {lines[4].rstrip()!r}')
write_file(r'lib\screens\parts\map_init_part.dart', lines)

print()
print("=" * 60)
print("Fix 3: map_location_route_part.dart")
print("=" * 60)
# Insert 'void _freezeMapWidgetCameraIfNeeded() {' before L5 (idx=4)
lines = read_file(r'lib\screens\parts\map_location_route_part.dart')
print(f'  L5 before fix: {lines[4].rstrip()!r}')
lines = insert_before_line(lines, 4, '  void _freezeMapWidgetCameraIfNeeded() {')
print(f'  L5 after fix: {lines[4].rstrip()!r}')
write_file(r'lib\screens\parts\map_location_route_part.dart', lines)

print()
print("=" * 60)
print("Fix 4: map_markers_part.dart")
print("=" * 60)
# Insert 'void _resetDriverMarkerInterpolation() {' before L5 (idx=4)
lines = read_file(r'lib\screens\parts\map_markers_part.dart')
print(f'  L5 before fix: {lines[4].rstrip()!r}')
lines = insert_before_line(lines, 4, '  void _resetDriverMarkerInterpolation() {')
print(f'  L5 after fix: {lines[4].rstrip()!r}')
write_file(r'lib\screens\parts\map_markers_part.dart', lines)

print()
print("=" * 60)
print("Fix 5: map_neighbor_part.dart")
print("=" * 60)
# Insert 'void _listenForRideBroadcasts() {' before L5 (idx=4)
lines = read_file(r'lib\screens\parts\map_neighbor_part.dart')
print(f'  L5 before fix: {lines[4].rstrip()!r}')
lines = insert_before_line(lines, 4, '  void _listenForRideBroadcasts() {')
print(f'  L5 after fix: {lines[4].rstrip()!r}')
write_file(r'lib\screens\parts\map_neighbor_part.dart', lines)

print()
print("=" * 60)
print("Fix 6: map_social_part.dart - remove orphaned _buildBumpFloatingButton body (L5-29)")
print("=" * 60)
# Remove L5-L29 (0-based idx 4-28) - orphaned body of _buildBumpFloatingButton
# that already exists complete in map_neighbor_part.dart
lines = read_file(r'lib\screens\parts\map_social_part.dart')
print(f'  L5 before fix: {lines[4].rstrip()!r}')
print(f'  L29 before fix: {lines[28].rstrip()!r}')
print(f'  L30 before fix (will become L5): {lines[29].rstrip()!r}')
lines = remove_lines(lines, 4, 28)
print(f'  L5 after fix: {lines[4].rstrip()!r}')
write_file(r'lib\screens\parts\map_social_part.dart', lines)

print()
print("=" * 60)
print("Fix 7: map_driver_part.dart")
print("=" * 60)
# Insert 'Future<void> _loadMagicEventCheckinIds() async {' before L5 (idx=4)
lines = read_file(r'lib\screens\parts\map_driver_part.dart')
print(f'  L5 before fix: {lines[4].rstrip()!r}')
lines = insert_before_line(lines, 4, '  Future<void> _loadMagicEventCheckinIds() async {')
print(f'  L5 after fix: {lines[4].rstrip()!r}')
write_file(r'lib\screens\parts\map_driver_part.dart', lines)

print()
print("=" * 60)
print("Fix 8: map_bg_voice_part.dart - move didChangeAppLifecycleState to map_screen.dart")
print("=" * 60)
lines_bg = read_file(r'lib\screens\parts\map_bg_voice_part.dart')
# Extract @override + method L6-L83 (0-based 5-82)
lifecycle_lines = lines_bg[5:83]  # @override through closing }
print(f'  Extracting L6-L83: {len(lifecycle_lines)} lines')
print(f'  First: {lifecycle_lines[0].rstrip()!r}')
print(f'  Last: {lifecycle_lines[-1].rstrip()!r}')

# New bg_voice: header (L1-4) + blank + rest (L84-end = idx 83+)
new_bg = lines_bg[:4] + ['\n'] + lines_bg[83:]
print(f'  New bg_voice: {len(new_bg)} lines (was {len(lines_bg)})')
print(f'  New L5: {new_bg[4].rstrip()!r}')
print(f'  New L6: {new_bg[5].rstrip()!r}')
write_file(r'lib\screens\parts\map_bg_voice_part.dart', new_bg)

print()
print("=" * 60)
print("Fix 9: map_screen.dart changes")
print("=" * 60)
lines_ms = read_file(r'lib\screens\map_screen.dart')

# 9a: Change '_initEmojiListener()' stub signature to 'didChangeDependencies()'
# at L1129 (idx=1128)
# The body is already correct (has super.didChangeDependencies() and theme logic)
print(f'  L1129 before: {lines_ms[1128].rstrip()!r}')
lines_ms[1128] = '  @override\n'
# L1130 was already "  void _initEmojiListener() {", now we need to adjust
# After insertion, old L1130 becomes L1131, but we inserted @override at 1128
# Wait, actually we need to REPLACE the line, not insert
# The structure is: L1129 = "  void _initEmojiListener() {", we want "@override\n  void didChangeDependencies() {"
# Let's do it properly: replace line 1128 with @override + signature
old_sig = lines_ms[1128]  # This is now '@override\n' (we just set it)
# Actually, let me redo this more carefully
# lines_ms[1128] was "  void _initEmojiListener() {\n"
# We want to replace it with "@override\n  void didChangeDependencies() {\n" — TWO lines
# So we need to insert one line and replace the other

# Re-read to start fresh for this section
lines_ms2 = read_file(r'lib\screens\map_screen.dart')
print(f'  Re-read: {len(lines_ms2)} lines')
print(f'  L1129 (idx 1128): {lines_ms2[1128].rstrip()!r}')

# Replace "  void _initEmojiListener() {\n" at idx 1128 with 
# "  @override\n" + "  void didChangeDependencies() {\n"
if '  void _initEmojiListener() {' in lines_ms2[1128]:
    lines_ms2[1128] = '  @override\n  void didChangeDependencies() {\n'
    print(f'  Fixed L1129 to: @override + void didChangeDependencies()')
else:
    print(f'  ERROR: L1129 not as expected: {lines_ms2[1128].rstrip()!r}')

# 9b: Insert didChangeAppLifecycleState after dispose() at L1287 (idx 1286)
# Find dispose() end more robustly
depth = 0; in_m = False; dispose_end_idx = None
for i, l in enumerate(lines_ms2):
    if '  void dispose() {' in l:
        in_m = True
    if in_m:
        for c in l:
            if c == '{': depth += 1
            elif c == '}': depth -= 1
        if depth == 0 and in_m and i > 0:
            dispose_end_idx = i
            break

print(f'  dispose() ends at L{dispose_end_idx+1} (idx {dispose_end_idx})')
print(f'  After dispose: {lines_ms2[dispose_end_idx+1].rstrip()!r}')

# Insert lifecycle method after dispose_end_idx
# lifecycle_lines are from the bg_voice part: @override + method
insert_text = '\n' + ''.join(lifecycle_lines) + '\n'
insert_at = dispose_end_idx + 1  # insert after closing }

lines_before = lines_ms2[:insert_at]
lines_after = lines_ms2[insert_at:]
lines_ms2 = lines_before + ['\n'] + lifecycle_lines + ['\n'] + lines_after

print(f'  Inserted didChangeAppLifecycleState after L{dispose_end_idx+1}')
print(f'  New map_screen.dart: {len(lines_ms2)} lines (was {len(lines_ms2) - len(lifecycle_lines) - 2})')

write_file(r'lib\screens\map_screen.dart', lines_ms2)

print()
print("=" * 60)
print("ALL FIXES APPLIED SUCCESSFULLY")
print("=" * 60)
