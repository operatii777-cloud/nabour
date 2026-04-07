import os
from PIL import Image

def forensic_clean(input_path, output_path):
    print(f"Forensic cleaning {os.path.basename(input_path)}...")
    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Sample background colors from edges
        bg_samples = [
            img.getpixel((0, 0)), 
            img.getpixel((width-1, 0)), 
            img.getpixel((0, height-1)), 
            img.getpixel((width-1, height-1)),
            img.getpixel((1, 0)), # Potential second checker color
            img.getpixel((0, 1))
        ]
        
        new_data = []
        for item in img.getdata():
            r, g, b, a = item
            is_bg = False
            
            # Distance check against all edge samples
            for br, bg, bb, ba in bg_samples:
                if abs(r - br) < 15 and abs(g - bg) < 15 and abs(b - bb) < 15:
                    is_bg = True
                    break
            
            # Additional logic for standard grids/whites
            if r > 240 and g > 240 and b > 240: is_bg = True
            elif r < 12 and g < 12 and b < 12: is_bg = True
            
            if is_bg:
                new_data.append((0, 0, 0, 0))
            else:
                new_data.append(item)
                
        img.putdata(new_data)
        
        # Trim again just in case
        bbox = img.getbbox()
        if bbox:
            img = img.crop(bbox)
            
        img.save(output_path, "PNG")
        print(f"✓ {os.path.basename(input_path)} forensically cleaned.")
    except Exception as e:
        print(f"✗ Failed to clean {input_path}: {e}")

avatars_dir = "assets/images/avatars"
# Focusing on the Unicorn and any others that might have traps
files_to_clean = ["unicorn.png", "mythic.png", "scooter.png", "moto.png", "yacht.png", "salupa.png"]

for filename in files_to_clean:
    path = os.path.join(avatars_dir, filename)
    if os.path.exists(path):
        forensic_clean(path, path)

print("\nForensic Clean-up Complete!")
