import sys
sys.stdout.reconfigure(encoding='utf-8')

path = r'lib\screens\map_screen.dart'
with open(path, encoding='utf-8') as f:
    lines = f.readlines()

removes = [
    "import 'package:nabour_app/services/map_search_metrics_service.dart';",
    "import 'package:nabour_app/services/local_address_database.dart';",
]

kept = []
removed = []
for line in lines:
    stripped = line.strip()
    if stripped in removes:
        removed.append(stripped)
    else:
        kept.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(kept)

for r in removed:
    print(f'Removed: {r}')
for r in removes:
    if r not in removed:
        print(f'NOT FOUND: {r}')
print(f'map_screen.dart: {len(kept)} linii')
