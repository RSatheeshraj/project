import os
from PIL import Image, ImageDraw, ImageFont

def create_placeholder(path, width, height, text, bg_color=(0,0,0,0), text_color=(244,169,0,255)):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img = Image.new('RGBA', (width, height), color=bg_color)
    d = ImageDraw.Draw(img)
    # Simple text drawing
    d.text((10, height//2 - 10), text, fill=text_color)
    img.save(path)

base = "public/branding"
create_placeholder(f"{base}/logos/logo-horizontal.png", 400, 100, "PoultryGuardLite (Horizontal)")
create_placeholder(f"{base}/logos/logo-stacked.png", 400, 300, "PoultryGuardLite (Stacked)")
create_placeholder(f"{base}/logos/logo-icon.png", 200, 200, "Icon")
create_placeholder(f"{base}/logos/logo-white.png", 400, 100, "Logo White", text_color=(255,255,255,255))
create_placeholder(f"{base}/logos/logo-monochrome.png", 400, 100, "Logo Mono", text_color=(200,200,200,255))

# favicons
create_placeholder(f"{base}/favicons/favicon.ico", 32, 32, "Fav")
create_placeholder(f"{base}/favicons/favicon-16x16.png", 16, 16, "16")
create_placeholder(f"{base}/favicons/favicon-32x32.png", 32, 32, "32")
create_placeholder(f"{base}/favicons/favicon-48x48.png", 48, 48, "48")
create_placeholder(f"{base}/favicons/apple-touch-icon.png", 180, 180, "Apple")
create_placeholder(f"{base}/favicons/icon-192.png", 192, 192, "192")
create_placeholder(f"{base}/favicons/icon-512.png", 512, 512, "512")

# reports
create_placeholder(f"{base}/reports/report-header-logo.png", 400, 100, "Report Header")
print("Placeholders created successfully.")