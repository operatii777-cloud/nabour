"""
Fix comprehensiv pentru toate erorile din lib/screens/parts/:
1. unqualified_reference_to_static_member_of_extended_type → prefixează cu _MapScreenState.
2. undefined_method / undefined_identifier (cross-extension statics) → prefixează cu extensia sursă
3. extension_declares_instance_field → mută câmpul în map_screen.dart
4. VoiceUIAutomationRegistry undefined → adaugă import în map_screen.dart
"""
import sys, os, re
sys.stdout.reconfigure(encoding='utf-8')

BASE = os.path.dirname(os.path.abspath(__file__))

def read_file(rel):
    return open(os.path.join(BASE, rel), encoding='utf-8').readlines()

def write_file(rel, lines):
    with open(os.path.join(BASE, rel), 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print(f'  Written: {rel} ({len(lines)} lines)')

# ────────────────────────────────────────────────────────────────────────────
# Pasul 1: Citim toate erorile din errors_current.txt
# ────────────────────────────────────────────────────────────────────────────
txt = open(os.path.join(BASE, 'errors_current.txt'), encoding='utf-8').read()
pat = re.compile(r'error - (.+?) - (lib.screens.[^:]+):(\d+):(\d+) - (\w+)')
errors = [(msg, path.replace('\\\\', '\\'), int(line), int(col), code)
          for msg, path, line, col, code in pat.findall(txt)]
print(f'Total erori: {len(errors)}')

# ────────────────────────────────────────────────────────────────────────────
# Pasul 2: Construim mapa "static în ce extensie/clasă este definit"
# ────────────────────────────────────────────────────────────────────────────

# Statici din _MapScreenState → prefix _MapScreenState.
# Statici din extensii → prefix ExtensionName.
CROSS_EXT_MAP = {
    # identifier → calificare completă
    '_generateMarkerIcon':           '_MapInitMethods._generateMarkerIcon',
    '_markerIconCache':              '_MapInitMethods._markerIconCache',
    '_driverMarkerPosLerpSoft':      '_MapInitMethods._driverMarkerPosLerpSoft',
    '_generateDemandMarker':         '_MapSocialMethods._generateDemandMarker',
    '_generateMapReactionMarkerPng': '_MapSocialMethods._generateMapReactionMarkerPng',
    '_generateMapMomentBubblePng':   '_MapSocialMethods._generateMapMomentBubblePng',
    '_generateNeighborCarMarker':    '_MapSocialMethods._generateNeighborCarMarker',
    '_lerpBearingDegrees':           '_MapMarkersMethods._lerpBearingDegrees',
}

# ────────────────────────────────────────────────────────────────────────────
# Pasul 3: Grupăm erorile pe fișier și le aplicăm
# ────────────────────────────────────────────────────────────────────────────
from collections import defaultdict
by_file = defaultdict(list)
for msg, path, line, col, code in errors:
    by_file[path].append((line, col, code, msg))

file_cache = {}
modified = {}

def get_lines(path):
    if path not in file_cache:
        file_cache[path] = read_file(path)
    return file_cache[path]

def qualify_at(lines, line_no, col_no, prefix):
    """Adaugă prefix înaintea identificatorului la line_no:col_no (1-based)."""
    l = lines[line_no - 1]
    c = col_no - 1
    # Verifică că nu e deja calificat
    if l[max(0, c-len(prefix)):c] == prefix:
        return False  # deja calificat
    lines[line_no - 1] = l[:c] + prefix + l[c:]
    return True

changes_by_file = defaultdict(int)

for path, file_errors in sorted(by_file.items()):
    lines = get_lines(path)

    # Sortăm erorile de la SFÂRŞIT la ÎNCEPUT (ca să nu ne décaleze coloanele)
    file_errors_sorted = sorted(file_errors, key=lambda x: (-x[0], -x[1]))

    for line_no, col_no, code, msg in file_errors_sorted:
        if code == 'unqualified_reference_to_static_member_of_extended_type':
            # Identificatorul este la col_no pe linia line_no
            c = col_no - 1
            l = lines[line_no - 1]
            ident_m = re.match(r'[\w_]+', l[c:])
            if not ident_m:
                print(f'  SKIP unqualified at {path}:{line_no}:{col_no} - no ident')
                continue
            ident = ident_m.group(0)
            # Verifică dacă este în CROSS_EXT_MAP (static din extensie, nu din clasă)
            if ident in CROSS_EXT_MAP:
                qualified = CROSS_EXT_MAP[ident]
                prefix = qualified[:qualified.rfind('.') + 1]  # 'ExtName.'
            else:
                prefix = '_MapScreenState.'
            # Verifică să nu fie deja calificat
            before = l[max(0, c - 20):c]
            if '_MapScreenState.' in before[-20:] or any(
                ext + '.' in before[-30:] for ext in
                ['_MapInitMethods', '_MapSocialMethods', '_MapMarkersMethods']
            ):
                continue  # deja calificat
            lines[line_no - 1] = l[:c] + prefix + l[c:]
            changes_by_file[path] += 1

        elif code in ('undefined_method', 'undefined_identifier'):
            # Extrage identificatorul din mesaj
            m = re.search(r"'([\w_]+)'", msg)
            if not m:
                continue
            ident = m.group(1)
            if ident not in CROSS_EXT_MAP:
                continue  # nu știm unde e definit (VoiceUIAutomationRegistry e tratat separat)
            # Găsim prima apariție a ident pe linia dată (la col_no sau aproape)
            l = lines[line_no - 1]
            c = col_no - 1
            # Verifică că e ident la acea coloană
            found_ident = re.match(r'[\w_]+', l[c:])
            if not found_ident or found_ident.group(0) != ident:
                # Poate coloana e uşor diferită; caută în ±5 chars
                found = False
                for dc in range(-5, 10):
                    cp = c + dc
                    if cp < 0: continue
                    fm = re.match(r'[\w_]+', l[cp:])
                    if fm and fm.group(0) == ident:
                        c = cp
                        found = True
                        break
                if not found:
                    print(f'  SKIP undefined {ident} at {path}:{line_no}:{col_no} - not found on line')
                    continue
            qualified = CROSS_EXT_MAP[ident]
            prefix = qualified[:qualified.rfind('.') + 1]
            # Verifică să nu fie deja calificat
            before = l[max(0, c-25):c]
            if prefix in before:
                continue
            lines[line_no - 1] = l[:c] + prefix + l[c:]
            changes_by_file[path] += 1

for path, count in changes_by_file.items():
    print(f'  {count} modificări în {path.split(chr(92))[-1]}')

# ────────────────────────────────────────────────────────────────────────────
# Pasul 4: Scriem fișierele modificate
# ────────────────────────────────────────────────────────────────────────────
print()
print('=== Scriem fișierele modificate ===')
for path, lines in file_cache.items():
    if path in changes_by_file:
        write_file(path, lines)

# ────────────────────────────────────────────────────────────────────────────
# Pasul 5: Mută _isUpdatingNeighbors din extensie în _MapScreenState
# ────────────────────────────────────────────────────────────────────────────
print()
print('=== Fix 5: Mută _isUpdatingNeighbors în map_screen.dart ===')
# 5a: Elimină din map_neighbor_part.dart
lines_nb = read_file(r'lib\screens\parts\map_neighbor_part.dart')
new_nb = []
for i, l in enumerate(lines_nb):
    if 'bool _isUpdatingNeighbors = false;' in l and '  bool ' in l:
        print(f'  Eliminat din map_neighbor_part.dart L{i+1}: {l.rstrip()!r}')
        # Sari și linia goală de după (dacă există)
        if i+1 < len(lines_nb) and lines_nb[i+1].strip() == '':
            new_nb.append(None)  # marker skip
        continue
    new_nb.append(l)
new_nb = [l for l in new_nb if l is not None]
write_file(r'lib\screens\parts\map_neighbor_part.dart', new_nb)

# 5b: Adaugă în map_screen.dart, în secțiunea de câmpuri (după _badgesCtrl/_routeCtrl)
lines_ms = read_file(r'lib\screens\map_screen.dart')
inserted = False
for i, l in enumerate(lines_ms):
    if '_badgesCtrl' in l and 'MapBadgesController' in l:
        # Inserăm după blocul de controlleri
        for j in range(i, min(i+10, len(lines_ms))):
            if '// Services' in lines_ms[j]:
                lines_ms.insert(j, '\n')
                lines_ms.insert(j, '  bool _isUpdatingNeighbors = false;\n')
                print(f'  Adăugat _isUpdatingNeighbors în map_screen.dart după L{j}')
                inserted = True
                break
        break
if not inserted:
    print('  WARN: nu am găsit locul pentru _isUpdatingNeighbors')
write_file(r'lib\screens\map_screen.dart', lines_ms)

# ────────────────────────────────────────────────────────────────────────────
# Pasul 6: Adaugă import VoiceUIAutomationRegistry în map_screen.dart
# ────────────────────────────────────────────────────────────────────────────
print()
print('=== Fix 6: Adaugă import VoiceUIAutomationRegistry ===')
lines_ms2 = read_file(r'lib\screens\map_screen.dart')
import_line = "import 'package:nabour_app/voice/core/voice_ui_automation_registry.dart';\n"
already = any('voice_ui_automation_registry' in l for l in lines_ms2)
if already:
    print('  Import deja există, skip.')
else:
    # Inserăm după ultimul import de voice
    last_voice_import_idx = None
    for i, l in enumerate(lines_ms2):
        if 'voice' in l and l.strip().startswith('import '):
            last_voice_import_idx = i
    if last_voice_import_idx is not None:
        lines_ms2.insert(last_voice_import_idx + 1, import_line)
        print(f'  Import adăugat după L{last_voice_import_idx+1}')
        write_file(r'lib\screens\map_screen.dart', lines_ms2)
    else:
        print('  WARN: nu am găsit loc pentru import')

print()
print('=' * 60)
print('TOATE FIXURILE APLICATE')
print('=' * 60)
