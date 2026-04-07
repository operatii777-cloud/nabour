from PIL import Image
import os

def optimize_image(path, target_size_kb=500):
    original_size = os.path.getsize(path) / 1024
    print(f"Optimizing {path} (Original: {original_size:.2f} KB)")
    
    with Image.open(path) as img:
        # If it's very large, resize first as 1024x1024 is often overkill for map avatars
        # Try keeping 1024 first with optimization
        temp_path = path + ".tmp.png"
        img.save(temp_path, "PNG", optimize=True)
        
        new_size = os.path.getsize(temp_path) / 1024
        print(f"Size after simple optimization: {new_size:.2f} KB")
        
        if new_size > target_size_kb:
            # Resize to 512x512 which is standard for high-res mobile assets
            print(f"Still too large. Resizing to 512x512...")
            img_resized = img.resize((512, 512), resample=Image.LANCZOS)
            img_resized.save(temp_path, "PNG", optimize=True)
            new_size = os.path.getsize(temp_path) / 1024
            print(f"Size after resize: {new_size:.2f} KB")
            
        # Overwrite original
        os.replace(temp_path, path)

if __name__ == "__main__":
    optimize_image('assets/ROBO.png')
    optimize_image('assets/Uber.png')
