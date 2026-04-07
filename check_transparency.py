from PIL import Image
import os

def check_transparency(path):
    try:
        with Image.open(path) as img:
            if img.mode != 'RGBA':
                return f"No (Mode: {img.mode})"
            
            # Check if there are any transparent pixels
            alpha = img.getchannel('A')
            min_alpha, max_alpha = alpha.getextrema()
            if min_alpha < 255:
                return f"Da, are transparență (Min: {min_alpha}, Max: {max_alpha})"
            else:
                return f"Nu, este RGBA dar toate pixelii sunt opaci (Min: {min_alpha})"
    except Exception as e:
        return f"Eroare: {e}"

if __name__ == "__main__":
    print(f"Elephant: {check_transparency('assets/images/avatars/elephant.png')}")
    print(f"Rhino: {check_transparency('assets/images/avatars/rhino.png')}")
    print(f"Horse: {check_transparency('assets/images/avatars/horse.png')}")
