#!/usr/bin/env python3
"""
Comprehensive Asset Generator for Vesperio App Publishing
Generates all required icons, graphics, and screenshots from a base icon.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import shutil

# Define the base directories
ASSETS_DIR = Path('assets/publishing')
ANDROID_ICONS = Path('android/app/src/main/res')
IOS_ICONS = Path('ios/Runner/Assets.xcassets/AppIcon.appiconset')
WEB_ICONS = Path('web/icons')
PLAYSTORE_DIR = ASSETS_DIR / 'playstore'

# Ensure directories exist
PLAYSTORE_DIR.mkdir(parents=True, exist_ok=True)
ANDROID_ICONS.mkdir(parents=True, exist_ok=True)
IOS_ICONS.mkdir(parents=True, exist_ok=True)
WEB_ICONS.mkdir(parents=True, exist_ok=True)

# Load base icon
BASE_ICON_PATH = ASSETS_DIR / 'Vesperio Icon 1.png'
base_icon = Image.open(BASE_ICON_PATH)
base_icon = base_icon.convert('RGBA')

# Android sizes (density dependent)
ANDROID_SIZES = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}

# iOS sizes (retina and non-retina variants)
IOS_SIZES = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}

# Web icon sizes
WEB_SIZES = {
    'Icon-192.png': 192,
    'Icon-512.png': 512,
    'Icon-maskable-192.png': 192,
    'Icon-maskable-512.png': 512,
}

def resize_icon(icon, size, apply_rounded=False, apply_mask=False):
    """Resize and optionally apply effects to icon."""
    resized = icon.resize((size, size), Image.Resampling.LANCZOS)
    
    if apply_rounded and size <= 192:
        # Create rounded corners for small icons
        mask = Image.new('L', (size, size), 0)
        draw = ImageDraw.Draw(mask)
        draw.ellipse([0, 0, size, size], fill=255)
        resized.putalpha(mask)
    
    return resized

def create_gradient_background(size, colors):
    """Create a gradient background for marketing materials."""
    bg = Image.new('RGB', (size, size), colors[0])
    draw = ImageDraw.Draw(bg)
    
    height = size
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
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    
    return bg

def overlay_icon_on_background(bg, icon, position='center'):
    """Overlay icon on a background."""
    bg = bg.convert('RGBA')
    icon = icon.convert('RGBA')
    
    if position == 'center':
        x = (bg.width - icon.width) // 2
        y = (bg.height - icon.height) // 2
    else:
        x, y = position
    
    bg.paste(icon, (x, y), icon)
    return bg

# Generate Android app icons
print("Generating Android app icons...")
for density, size in ANDROID_SIZES.items():
    resized = resize_icon(base_icon, size)
    output_dir = ANDROID_ICONS / f'mipmap-{density}'
    output_dir.mkdir(parents=True, exist_ok=True)
    resized.save(output_dir / 'ic_launcher.png')
    print(f"  ✓ {density} ({size}x{size})")

# Generate iOS app icons
print("\nGenerating iOS app icons...")
for filename, size in IOS_SIZES.items():
    resized = resize_icon(base_icon, size)
    resized_rgb = Image.new('RGB', resized.size, (255, 255, 255))
    resized_rgb.paste(resized, mask=resized.split()[3] if resized.mode == 'RGBA' else None)
    resized_rgb.save(IOS_ICONS / filename)
    print(f"  ✓ {filename} ({size}x{size})")

# Generate Web icons
print("\nGenerating Web icons...")
for filename, size in WEB_SIZES.items():
    resized = resize_icon(base_icon, size)
    resized.save(WEB_ICONS / filename)
    print(f"  ✓ {filename} ({size}x{size})")

# Generate Play Store Graphics
print("\nGenerating Play Store graphics...")
colors = [(44, 107, 239), (34, 208, 167), (116, 0, 255)]

# Play Store Feature Graphic (1024x500)
fg = create_gradient_background(1024, colors)
icon_512 = resize_icon(base_icon, 300)
fg = overlay_icon_on_background(fg.convert('RGBA'), icon_512, (150, 112))
fg.convert('RGB').save(PLAYSTORE_DIR / 'play_store_feature_graphic_1024x500.png')
print("  ✓ play_store_feature_graphic_1024x500.png")

# Play Store Promo Graphic (180x120)
pg = create_gradient_background(180, colors)
icon_small = resize_icon(base_icon, 80)
pg = overlay_icon_on_background(pg.convert('RGBA'), icon_small, (50, 20))
pg.convert('RGB').save(PLAYSTORE_DIR / 'play_store_promo_graphic_180x120.png')
print("  ✓ play_store_promo_graphic_180x120.png")

# Play Store Badge (512x512)
badge = create_gradient_background(512, colors)
icon_512_badge = resize_icon(base_icon, 350)
badge = overlay_icon_on_background(badge.convert('RGBA'), icon_512_badge, (81, 81))
badge.convert('RGB').save(PLAYSTORE_DIR / 'play_store_badge_512x512.png')
print("  ✓ play_store_badge_512x512.png")

# Play Store Screenshots - Mockup style (1080x1920)
print("\nGenerating Play Store screenshots...")

def create_screenshot(title, subtitle, icon_pos='top'):
    """Create a screenshot with title and content."""
    screenshot = create_gradient_background(1080, colors)
    screenshot = screenshot.convert('RGBA')
    
    icon_size = 250 if icon_pos == 'top' else 200
    icon_img = resize_icon(base_icon, icon_size)
    
    if icon_pos == 'top':
        screenshot = overlay_icon_on_background(screenshot, icon_img, (415, 200))
        text_y = 550
    else:
        screenshot = overlay_icon_on_background(screenshot, icon_img, (50, 100))
        text_y = 400
    
    draw = ImageDraw.Draw(screenshot)
    font_path = None
    for path in ['/Library/Fonts/Helvetica.ttc', '/Library/Fonts/Arial.ttf', '/System/Library/Fonts/SFNS.ttf']:
        if Path(path).exists():
            font_path = path
            break
    
    try:
        title_font = ImageFont.truetype(font_path, 80) if font_path else ImageFont.load_default()
        subtitle_font = ImageFont.truetype(font_path, 50) if font_path else ImageFont.load_default()
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
    
    # Draw text with white color
    draw.text((100, text_y), title, font=title_font, fill=(255, 255, 255))
    if subtitle:
        draw.text((100, text_y + 120), subtitle, font=subtitle_font, fill=(200, 200, 200))
    
    return screenshot.convert('RGB')

ss1 = create_screenshot('Vesperio', 'Relax & Sleep Better', 'top')
ss1.save(PLAYSTORE_DIR / 'play_store_screenshot_1_1080x1920.png')
print("  ✓ play_store_screenshot_1_1080x1920.png")

ss2 = create_screenshot('Smart Timer', 'Auto-fade & Scheduling', 'side')
ss2.save(PLAYSTORE_DIR / 'play_store_screenshot_2_1080x1920.png')
print("  ✓ play_store_screenshot_2_1080x1920.png")

ss3 = create_screenshot('Premium Sounds', 'Unlimited Premium Content', 'side')
ss3.save(PLAYSTORE_DIR / 'play_store_screenshot_3_1080x1920.png')
print("  ✓ play_store_screenshot_3_1080x1920.png")

# Generate Icon for different resolutions for app use
print("\nGenerating additional app icon variants...")
icon_variants = {
    'zen_sound_app_icon_512.png': 512,
    'zen_sound_app_icon_256.png': 256,
    'zen_sound_app_icon_192.png': 192,
}

for filename, size in icon_variants.items():
    resized = resize_icon(base_icon, size)
    resized.save(ASSETS_DIR / filename)
    print(f"  ✓ {filename} ({size}x{size})")

print("\n" + "="*60)
print("✅ All assets generated successfully!")
print("="*60)
print(f"\nGenerated assets in:")
print(f"  • Android: {ANDROID_ICONS.relative_to('.')}")
print(f"  • iOS: {IOS_ICONS.relative_to('.')}")
print(f"  • Web: {WEB_ICONS.relative_to('.')}")
print(f"  • Play Store: {PLAYSTORE_DIR.relative_to('.')}")
print(f"  • App Icons: {ASSETS_DIR.relative_to('.')}")
