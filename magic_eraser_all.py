import os
from PIL import Image

def clean_all_assets(root_path):
    print(f"Scanning assets in: {root_path}")
    count = 0
    for root, dirs, files in os.walk(root_path):
        for file in files:
            if file.lower().endswith('.png'):
                path = os.path.join(root, file)
                try:
                    _clean_single_image(path)
                    count += 1
                except Exception as e:
                    print(f"Skipping {file} due to error: {e}")
    print(f"Finished. Cleaned {count} images.")

def _clean_single_image(path):
    with Image.open(path) as img:
        # Avoid cleaning very small icons or app icons that might be sensitive
        if img.size[0] < 48 or img.size[1] < 48:
            return
        
        img = img.convert("RGBA")
        datas = img.getdata()
        
        new_data = []
        bg_color = img.getpixel((0,0))
        
        # Don't clean if it's already highly transparent in the corner 
        # (prevents double-cleaning artifacts)
        if len(bg_color) == 4 and bg_color[3] < 50:
            return

        for item in datas:
            r, g, b, a = item
            # Pure black, pure white, or edge-match
            if (r == g == b == 0) or (r == g == b == 255) or \
               (abs(r - bg_color[0]) < 15 and abs(g - bg_color[1]) < 15 and abs(b - bg_color[2]) < 15):
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
        
        img.putdata(new_data)
        
        # Crop but keep a small margin (5px) for shadows
        bbox = img.getbbox()
        if bbox:
            img = img.crop(bbox)
        
        img.save(path, "PNG", optimize=True)
        print(f"  [FIXED] {os.path.basename(path)} (Size: {img.size})")

if __name__ == "__main__":
    clean_all_assets('assets')
