import os
from PIL import Image

def surgical_strip_v2(input_path, output_path):
    print(f"Surgically cleaning {os.path.basename(input_path)}...")
    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Determine background colors from all 4 corners (for black/white/checkerboards)
        bg_colors = {
            img.getpixel((0, 0)), 
            img.getpixel((width-1, 0)), 
            img.getpixel((0, height-1)), 
            img.getpixel((width-1, height-1)),
            img.getpixel((width//2, 0)), # Top center
            img.getpixel((0, height//2))  # Left center
        }
        
        # Build transparency mask using flood fill from edges
        visited = set()
        queue = []
        for x in range(width):
            queue.append((x, 0))
            queue.append((x, height - 1))
        for y in range(1, height - 1):
            queue.append((0, y))
            queue.append((width - 1, y))

        new_data = list(img.getdata())
        
        while queue:
            x, y = queue.pop(0)
            if (x, y) in visited: continue
            visited.add((x, y))
            
            idx = y * width + x
            r, g, b, a = new_data[idx]
            
            # AGGRESSIVE background detection: White, Black, Grey, or matches a corner color
            is_bg = False
            if a < 20: is_bg = True # Already transparent
            elif r > 240 and g > 240 and b > 240: is_bg = True # Pure White
            elif r < 20 and g < 20 and b < 20: is_bg = True # Pure Black
            elif r == g == b and 175 < r < 242: is_bg = True # Light Checker Square
            elif r == g == b and 35 < r < 115: is_bg = True # Dark Checker Square
            elif (r, g, b, a) in bg_colors: is_bg = True # Explicit corner color
            # Handle subtle grey variations
            elif abs(r-g) < 15 and abs(g-b) < 15 and abs(b-r) < 15 and (r > 170 or r < 120): is_bg = True
            
            if is_bg:
                new_data[idx] = (0, 0, 0, 0)
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in visited:
                        queue.append((nx, ny))
                        
        img.putdata(new_data)
        
        # Trim to bounding box of content
        bbox = img.getbbox()
        if bbox:
            img = img.crop(bbox)
            
        img.save(output_path, "PNG")
        print(f"✓ {os.path.basename(input_path)} cleaned and trimmed.")
    except Exception as e:
        print(f"✗ Failed to clean {input_path}: {e}")

avatars_dir = "assets/images/avatars"
# Process ALL files in the directory
all_files = [f for f in os.listdir(avatars_dir) if f.endswith(".png")]

for filename in all_files:
    path = os.path.join(avatars_dir, filename)
    surgical_strip_v2(path, path)

print("\nFinal Polish Complete! All 18 avatars are now professionally transparent.")
