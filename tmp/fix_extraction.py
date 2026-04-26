"""
Fix extraction issues:
1. map_screen.dart missing closing } for _MapScreenState
2. _calculateDirectDistance split across files
3. map_interactions_part.dart has extra } (extracted class close)
"""
import sys
sys.stdout.reconfigure(encoding='utf-8')

# === Fix map_interactions_part.dart ===
PART = r'lib\screens\parts\map_interactions_part.dart'
with open(PART, encoding='utf-8') as f:
    part_lines = f.readlines()

print(f'map_interactions_part.dart: {len(part_lines)} linii')

# The complete _calculateDirectDistance function
CALC_DISTANCE_FUNC = '''  double _calculateDirectDistance(double lat1, double lon1, double lat2, double lon2) {
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

'''

# Lines 5-17 (0-based: 4-16) are the orphaned body of _calculateDirectDistance
# Replace them with the complete function (including signature)
# Line 4 (0-based) = "    final dLat = ..."
# Find the end of the orphaned body (the closing "  }" after "return earthRadius * c;")
# Lines: 4=final dLat, 5=final dLon, 6=blank, 7=final a, 8=..., 9=..., 10=..., 11=..., 12=blank, 13=final c, 14=blank, 15=return, 16=  }, 17=blank, 18=blank
# Let me find where the orphaned body ends
orphan_end = 4  # start
for i in range(4, len(part_lines)):
    line = part_lines[i].strip()
    if line == '}':
        orphan_end = i
        break

print(f'Orphaned body: lines 4-{orphan_end} (0-based)')
print('Content:')
for i in range(4, orphan_end + 2):
    print(f'  [{i}]: {repr(part_lines[i].rstrip()[:60])}')

# Replace orphaned body with complete function
new_part_lines = part_lines[:4] + [CALC_DISTANCE_FUNC] + part_lines[orphan_end + 1:]

# Also fix the extra closing } at the end (the extracted class close)
# Last few lines should be: "  }\n" (last method), "}\n" (extension close)
# But there's an extra "}\n" from the extracted class closing brace
# Find the second-to-last "}\n" and remove it
print('\nLast 5 lines of new_part_lines:')
for i, l in enumerate(new_part_lines[-5:], len(new_part_lines)-5):
    print(f'  [{i}]: {repr(l.rstrip())}')

# The last few should be: ..., "  }\n", "}\n", "}\n"
# We need to remove one of the last "}\n"s
# The first one (second to last) was the class closing brace
# The last one was added by script to close extension
if len(new_part_lines) >= 2:
    last = new_part_lines[-1].strip()
    second_last = new_part_lines[-2].strip()
    if last == '}' and second_last == '}':
        # Remove the second-to-last
        new_part_lines.pop(-2)
        print('Removed extra closing brace (class close)')

with open(PART, 'w', encoding='utf-8') as f:
    f.writelines(new_part_lines)
print(f'\nmap_interactions_part.dart: {len(new_part_lines)} linii (fixed)')

# === Fix map_screen.dart ===
MS = r'lib\screens\map_screen.dart'
with open(MS, encoding='utf-8') as f:
    ms_lines = f.readlines()

print(f'\nmap_screen.dart: {len(ms_lines)} linii')

# Remove lines 3136-3137 (0-based, 1-based: 3137-3138) 
# These are the orphaned partial function
# Line 3136 (0-based): '  double _calculateDirectDistance...'
# Line 3137 (0-based): '    const double earthRadius = 6371000;...'
print(f'Removing orphaned lines:')
for i in range(3135, len(ms_lines)):
    print(f'  [{i}]: {repr(ms_lines[i].rstrip()[:70])}')

# Remove from line 3136 (0-based) to end, then add closing }
ms_lines = ms_lines[:3136]

# Add closing } for _MapScreenState
ms_lines.append('}\n')

with open(MS, 'w', encoding='utf-8') as f:
    f.writelines(ms_lines)

print(f'map_screen.dart: {len(ms_lines)} linii (fixed)')
