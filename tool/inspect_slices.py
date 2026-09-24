import os
from PIL import Image

slices_dir = r'e:\game\word_arrow\words_arrow_flutter\assets\images\board\slices'
files = sorted([f for f in os.listdir(slices_dir) if f.endswith('.png')])

for f in files:
    path = os.path.join(slices_dir, f)
    img = Image.open(path)
    w, h = img.size
    # Check center pixel
    center = img.getpixel((w // 2, h // 2))
    # Check corner pixels
    corners = [img.getpixel((2, 2)), img.getpixel((w - 3, 2)), img.getpixel((2, h - 3)), img.getpixel((w - 3, h - 3))]
    print(f'{f:30s} size={w}x{h:3d} center={center} aspect={w/h:.2f}')
