import sys
sys.stdout.reconfigure(encoding="utf-8")
path = r"e:\variante app friends\03.07.2025 MAP BOX\nabour_app\lib\screens\map_screen.dart"
with open(path, encoding="utf-8") as f: lines = f.readlines()
removes = ["map_qa_badge_prefs", "neighborhood_request_model", "map_top_bar"]
new_lines = []
for l in lines:
    if any(r in l for r in removes) and l.strip().startswith("import "):
        print(f"Removed: {l.strip()[:80]}")
    else:
        new_lines.append(l)
with open(path, "w", encoding="utf-8") as f: f.writelines(new_lines)
print(f"Lines: {len(new_lines)}")
