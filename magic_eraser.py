from PIL import Image, ImageChops

def make_truly_transparent(path):
    print(f"Fixing transparency for {path}...")
    with Image.open(path) as img:
        img = img.convert("RGBA")
        datas = img.getdata()
        
        new_data = []
        # Since it's a solid SUBJECT in the center, we look for 
        # pixels at the very edges of the image to define 'background'
        # Top-left is a good candidate for the background color
        bg_color = img.getpixel((0,0))
        
        for item in datas:
            # If the pixel is very close to the corner background color
            # OR if it's pure black (common AI output artifact for transparency)
            r, g, b, a = item
            if (r == g == b == 0) or (abs(r - bg_color[0]) < 10 and abs(g - bg_color[1]) < 10 and abs(b - bg_color[2]) < 10):
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)
        
        img.putdata(new_data)
        
        # Crop to subject (optional but keeps icons clean)
        bbox = img.getbbox()
        if bbox:
            img = img.crop(bbox)
        
        img.save(path, "PNG")
        print(f"Successfully cleaned {path}")

if __name__ == "__main__":
    make_truly_transparent('assets/images/avatars/elephant.png')
    make_truly_transparent('assets/images/avatars/rhino.png')
    make_truly_transparent('assets/images/home_pin.png')
