"""
Extrage metode din map_screen.dart in fisiere part-of cu extension methods.
"""
import sys, os, pathlib
sys.stdout.reconfigure(encoding='utf-8')

SRC = r'lib\screens\map_screen.dart'
PARTS_DIR = r'lib\screens\parts'

# Ranges are 1-based, inclusive on both ends.
# Format: (start_line, end_line, part_filename, extension_name)
# Note: lifecycle methods stay in main file:
#   - initState: ~L964-L1083
#   - didChangeDependencies: ~L2845-L2887
#   - dispose: ~L3535-L3644
#   - didChangeAppLifecycleState: ~L3652-L3730
#   - build + _buildContextualOverlay: ~L10954-L12742
GROUPS = [
    (1105, 2844, 'map_emoji_moments_part.dart', '_MapEmojiMomentsMethods'),
    (2888, 3534, 'map_geocoding_nav_part.dart', '_MapGeocodingNavMethods'),
    (3645, 3651, 'map_bg_voice_part.dart', '_MapBgVoiceMethods'),  # _maybeStartMovementHistoryRecorder
    (3731, 4120, 'map_bg_voice_part.dart', '_MapBgVoiceMethods'),  # remainder before _onMapCreated
    (4121, 5048, 'map_init_part.dart', '_MapInitMethods'),
    (5049, 5868, 'map_markers_part.dart', '_MapMarkersMethods'),
    (5869, 7370, 'map_neighbor_part.dart', '_MapNeighborMethods'),
    (7371, 8167, 'map_social_part.dart', '_MapSocialMethods'),
    (8168, 9094, 'map_driver_part.dart', '_MapDriverMethods'),
    (9095, 9561, 'map_ride_flow_part.dart', '_MapRideFlowMethods'),
    (9562, 10953, 'map_location_route_part.dart', '_MapLocationRouteMethods'),
    (12743, 15251, 'map_interactions_part.dart', '_MapInteractionsMethods'),
]

os.makedirs(PARTS_DIR, exist_ok=True)

with open(SRC, encoding='utf-8') as f:
    all_lines = f.readlines()

total = len(all_lines)
print(f'Total linii sursa: {total}')

# Build set of all lines to extract (0-based indices)
lines_to_extract = {}  # line_index (0-based) -> (filename, extension_name)
for (s, e, fname, extname) in GROUPS:
    s0 = s - 1  # convert to 0-based
    e0 = e - 1  # inclusive
    e0 = min(e0, total - 1)
    for i in range(s0, e0 + 1):
        lines_to_extract[i] = (fname, extname)

# Group lines by file
from collections import OrderedDict
file_lines = {}  # filename -> [(extname, [(line_idx, line_content)])]
for idx, (fname, extname) in sorted(lines_to_extract.items()):
    if fname not in file_lines:
        file_lines[fname] = {}
    if extname not in file_lines[fname]:
        file_lines[fname][extname] = []
    file_lines[fname][extname].append(all_lines[idx])

# Write part files
part_filenames = []
for fname, ext_dict in file_lines.items():
    part_path = os.path.join(PARTS_DIR, fname)
    # Deduplicate extension names (multiple ranges may use same extension)
    # For 'map_bg_voice_part.dart', both ranges use '_MapBgVoiceMethods'
    with open(part_path, 'w', encoding='utf-8') as f:
        f.write(f"// ignore_for_file: invalid_use_of_protected_member\n")
        f.write(f"part of '../map_screen.dart';\n\n")
        
        for extname, lines in ext_dict.items():
            f.write(f"extension {extname} on _MapScreenState {{\n")
            for line in lines:
                f.write(line)
            # Ensure proper closing
            f.write("}\n\n")
    
    line_count = sum(len(lines) for lines in ext_dict.values())
    print(f'Created {part_path} ({line_count} linii)')
    part_filenames.append(fname)

# Remove extracted lines from map_screen.dart
kept = []
for i, line in enumerate(all_lines):
    if i not in lines_to_extract:
        kept.append(line)

# Add 'part' directives after the imports section (find last import line)
last_import_idx = 0
for i, line in enumerate(kept):
    if line.strip().startswith("import '") or line.strip().startswith('import "'):
        last_import_idx = i

# Build part directives
part_directives = []
for fname in sorted(set(file_lines.keys())):
    part_directives.append(f"part 'parts/{fname}';\n")

# Insert part directives after last import
insert_at = last_import_idx + 1
# Skip blank lines after imports
while insert_at < len(kept) and kept[insert_at].strip() == '':
    insert_at += 1

kept.insert(insert_at, '\n')
for i, pd in enumerate(reversed(part_directives)):
    kept.insert(insert_at, pd)
kept.insert(insert_at, '// ── Part files (method groups extracted from _MapScreenState) ──\n')

with open(SRC, 'w', encoding='utf-8') as f:
    f.writelines(kept)

print(f'\nmap_screen.dart: {len(kept)} linii (era {total})')
print(f'Extras: {len(lines_to_extract)} linii in {len(file_lines)} fisiere')
