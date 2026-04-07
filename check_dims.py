from PIL import Image
import sys
import os

def get_info(path):
    try:
        with Image.open(path) as img:
            return f"Size: {img.size}, Mode: {img.mode}"
    except Exception as e:
        return f"Error: {e}"

if __name__ == "__main__":
    print(f"ROBO.png: {get_info('assets/ROBO.png')}")
    print(f"Uber.png: {get_info('assets/Uber.png')}")
    print(f"ufo.png (existing): {get_dimensions('assets/images/avatars/ufo.png')}")
    print(f"dacia.png (existing): {get_dimensions('assets/images/avatars/dacia.png')}")
