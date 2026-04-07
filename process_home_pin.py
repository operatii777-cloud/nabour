from PIL import Image, ImageOps
import os

def process_home_pin(input_path, output_path):
    print(f"Processing {input_path}...")
    with Image.open(input_path) as img:
        # Convert to RGBA if not already
        img = img.convert("RGBA")
        
        # Since it has a checkered background, we need to remove it.
        # This specific pattern is 1024x1024.
        # I'll use a color-based threshold for the grey/black checkers.
        # Checkers: ~ (30, 30, 30) and (45, 45, 45) in dark mode viewers or white/grey in others.
        # Looking at the preview, it's dark checkers.
        
        datas = img.getdata()
        new_data = []
        for item in datas:
            # If the pixel is part of the 'checkered' pattern (neutral greys in the background)
            # and is NOT part of the glass bubble (which has highlights/reflections).
            # The house and cloud are the focus.
            
            # Simple threshold for the background pattern if it's very distinct
            r, g, b, a = item
            # Neutrals with low brightness (dark checkers)
            if r == g == b and r < 60: 
                new_data.append((255, 255, 255, 0))
            elif r == g == b and r > 200: # light checkers if they exist
                 new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
        
        img.putdata(new_data)
        
        # Resize to 512x512 for optimization
        img = img.resize((512, 512), resample=Image.LANCZOS)
        
        # Save optimized
        img.save(output_path, "PNG", optimize=True)
        print(f"Saved to {output_path}. Size: {os.path.getsize(output_path)/1024:.2f} KB")

if __name__ == "__main__":
    # Assuming the user's uploaded image is processed by the system and available
    # I will look for it in the current turn's artifacts or temporary location.
    # Since I can't directly 'grab' the binary from the chat in this thought block 
    # without a path, I'll assume the path is provided/known from the previous save.
    pass
