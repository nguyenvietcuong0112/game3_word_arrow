import os
from PIL import Image

atlas_path = r'e:\game\word_arrow\words_arrow_flutter\assets\images\gameplay\sactx-0-2048x2048-ETC2-WordOutBoardSpriteAtlas-847d347d.png'
out_dir = r'e:\game\word_arrow\words_arrow_flutter\assets\images\board\slices'
os.makedirs(out_dir, exist_ok=True)

img = Image.open(atlas_path)
w, h = img.size
alpha = img.getchannel('A')
pix = alpha.load()

visited = bytearray(w * h)
boxes = []

for y in range(h):
    for x in range(w):
        idx = y * w + x
        if visited[idx] or pix[x, y] == 0:
            continue
        min_x, max_x = x, x
        min_y, max_y = y, y
        stack = [(x, y)]
        visited[idx] = 1
        count = 0
        while stack:
            cx, cy = stack.pop()
            count += 1
            if cx < min_x: min_x = cx
            if cx > max_x: max_x = cx
            if cy < min_y: min_y = cy
            if cy > max_y: max_y = cy
            for nx, ny in ((cx+1, cy), (cx-1, cy), (cx, cy+1), (cx, cy-1)):
                if 0 <= nx < w and 0 <= ny < h:
                    nidx = ny * w + nx
                    if not visited[nidx] and pix[nx, ny] > 0:
                        visited[nidx] = 1
                        stack.append((nx, ny))
        if count > 50:
            boxes.append((min_x, min_y, max_x + 1, max_y + 1, count))

boxes.sort(key=lambda b: (b[1], b[0]))

html = [
    '<!DOCTYPE html><html><head><meta charset="utf-8">',
    '<style>',
    'body { background: #1e1e24; color: #fff; font-family: -apple-system, sans-serif; padding: 20px; }',
    '.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 16px; }',
    '.card { background: #2b2b36; border-radius: 8px; padding: 12px; text-align: center; }',
    '.card img { max-width: 120px; max-height: 120px; background: #3a3a4c; border-radius: 6px; margin-bottom: 8px; object-fit: contain; }',
    '.card .title { font-weight: bold; font-size: 13px; color: #ffca28; }',
    '.card .meta { font-size: 11px; color: #aaa; margin-top: 4px; }',
    '</style></head><body>',
    '<h2>WordOut Board Sprite Atlas Slices</h2>',
    '<div class="grid">'
]

for i, (bx1, by1, bx2, by2, cnt) in enumerate(boxes):
    sw = bx2 - bx1
    sh = by2 - by1
    cropped = img.crop((bx1, by1, bx2, by2))
    name = f'slice_{i:02d}_{sw}x{sh}.png'
    cropped.save(os.path.join(out_dir, name))
    
    html.append(f'<div class="card">')
    html.append(f'  <img src="slices/{name}">')
    html.append(f'  <div class="title">#{i:02d} ({sw}x{sh})</div>')
    html.append(f'  <div class="meta">bbox: {bx1},{by1},{bx2},{by2}</div>')
    html.append(f'</div>')

html.append('</div></body></html>')

preview_path = r'e:\game\word_arrow\words_arrow_flutter\assets\images\board\preview.html'
with open(preview_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(html))

print(f'Done! Saved {len(boxes)} slices and preview to {preview_path}')
