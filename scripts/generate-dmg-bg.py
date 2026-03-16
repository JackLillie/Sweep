#!/usr/bin/env python3
"""Generate a DMG background image — light gradient with subtle arrow."""

from PIL import Image, ImageDraw

W, H = 660, 400
RETINA = 2
w, h = W * RETINA, H * RETINA

img = Image.new("RGB", (w, h))
draw = ImageDraw.Draw(img)

# light gradient — triggers black label text in Finder
for y in range(h):
    t = y / h
    r = int(232 - t * 20)
    g = int(234 - t * 20)
    b = int(238 - t * 18)
    draw.line([(0, y), (w, y)], fill=(r, g, b))

# arrow between icon positions
cx = w // 2
cy = int(180 * RETINA)
arrow_len = int(80 * RETINA)
arrow_w = int(3 * RETINA)
head_size = int(12 * RETINA)

overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
odraw = ImageDraw.Draw(overlay)

arrow_color = (100, 105, 115, 110)

x1 = cx - arrow_len // 2
x2 = cx + arrow_len // 2
odraw.line([(x1, cy), (x2, cy)], fill=arrow_color, width=arrow_w)

odraw.polygon([
    (x2, cy),
    (x2 - head_size, cy - head_size),
    (x2 - head_size, cy + head_size),
], fill=arrow_color)

img = img.convert("RGBA")
img = Image.alpha_composite(img, overlay)
img = img.convert("RGB")

img.save("dmg/background.png")
img.resize((W, H), Image.LANCZOS).save("dmg/background@1x.png")
print(f"Generated dmg/background.png ({w}x{h}) and dmg/background@1x.png ({W}x{H})")
