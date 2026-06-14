from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

out = Path('assets/publishing')
out.mkdir(parents=True, exist_ok=True)

font_path = None
for path in ['/Library/Fonts/Helvetica.ttf', '/Library/Fonts/Arial.ttf', '/System/Library/Fonts/SFNS.ttf']:
    if Path(path).exists():
        font_path = path
        break

font = ImageFont.truetype(font_path, 140) if font_path else ImageFont.load_default()
small_font = ImageFont.truetype(font_path, 72) if font_path else ImageFont.load_default()

colors = [(44, 107, 239), (34, 208, 167), (116, 0, 255)]

def gradient(size, colors):
    width, height = size
    base = Image.new('RGB', size, colors[0])
    draw = ImageDraw.Draw(base)
    for y in range(height):
        t = y / (height - 1)
        if t < 0.5:
            c1, c2 = colors[0], colors[1]
            nt = t / 0.5
        else:
            c1, c2 = colors[1], colors[2]
            nt = (t - 0.5) / 0.5
        r = int(c1[0] + (c2[0] - c1[0]) * nt)
        g = int(c1[1] + (c2[1] - c1[1]) * nt)
        b = int(c1[2] + (c2[2] - c1[2]) * nt)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    return base


def draw_brand(image, title, subtitle=None):
    draw = ImageDraw.Draw(image)
    w, h = image.size
    circle_size = int(min(w, h) * 0.4)
    circle = Image.new('RGBA', (circle_size, circle_size), (255, 255, 255, 0))
    circ_draw = ImageDraw.Draw(circle)
    circ_draw.ellipse((0, 0, circle_size, circle_size), fill=(255, 255, 255, 230))
    image.paste(circle, ((w - circle_size) // 2, int(h * 0.08)), circle)
    text = title
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((w - tw) / 2, h * 0.58), text, font=font, fill='white')
    if subtitle:
        sbbox = draw.textbbox((0, 0), subtitle, font=small_font)
        stw, sth = sbbox[2] - sbbox[0], sbbox[3] - sbbox[1]
        draw.text(((w - stw) / 2, h * 0.75), subtitle, font=small_font, fill='white')

assets = [
    ('zen_sound_app_icon_1024.png', (1024, 1024), 'ZenSound', 'Sleep & Focus'),
    ('play_store_feature_graphic_1024x500.png', (1024, 500), 'ZenSound', 'Sleep sounds • focus • calm'),
    ('play_store_promo_graphic_180x120.png', (180, 120), 'ZenSound', None),
    ('play_store_badge_512x512.png', (512, 512), 'ZenSound', None),
    ('play_store_screenshot_1_1080x1920.png', (1080, 1920), 'ZenSound', 'Relaxing soundscapes'),
    ('play_store_screenshot_2_1080x1920.png', (1080, 1920), 'ZenSound', 'Smart timer & premium content')
]

for name, size, title, subtitle in assets:
    print('creating', name)
    img = gradient(size, colors)
    draw_brand(img, title, subtitle)
    target = out / name
    img.save(target)
    print('saved', target, target.exists(), target.stat().st_size)
