# Telescope view with a ranging pole, writes ..\Geus.ico
from pathlib import Path

from PIL import Image, ImageDraw

GRID = 128          # drawn in a 128 x 128 grid
SUPER = 8           # drawn 8x larger, then scaled down smoothly

BLACK = (18, 18, 18)
SKY = (34, 221, 234)
MOUNTAIN = (12, 138, 46)
MOUNTAIN_SHADE = (9, 122, 40)
MEADOW = (56, 222, 66)
RED = (236, 32, 39)
WHITE = (255, 255, 255)

# Icon size: (cross width, simple drawing)
SIZES = {256: (5, False), 48: (8, False), 32: (10, False),
         24: (12, True), 16: (16, True)}

OUTPUT = Path(__file__).resolve().parent.parent / 'Geus.ico'


def curve(start, control, end, steps=16):
    """Points of a quadratic curve, like Q in SVG."""
    points = []
    for i in range(1, steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * control[0] + t ** 2 * end[0]
        y = (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * control[1] + t ** 2 * end[1]
        points.append((x, y))
    return points


def draw_icon(size):
    cross, simple = SIZES[size]
    scale = size * SUPER / GRID

    def px(points):
        """Grid points to pixels of the large image."""
        return [(x * scale, y * scale) for x, y in points]

    def box(x1, y1, x2, y2):
        return [x1 * scale, y1 * scale, x2 * scale, y2 * scale]

    big = size * SUPER
    icon = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)

    # Black rounded tile
    draw.rounded_rectangle(box(4, 4, 124, 124), radius=26 * scale, fill=BLACK)

    # The whole scene, the circle cuts it later
    scene = Image.new('RGBA', (big, big), SKY)
    ds = ImageDraw.Draw(scene)
    if simple:
        ds.polygon(px([(0, 84), (82, 32), (128, 80), (128, 128), (0, 128)]), fill=MOUNTAIN)
        ds.rectangle(box(0, 95, 128, 128), fill=MEADOW)
        ds.rectangle(box(31, 0, 48, 128), fill=RED)
        ds.rectangle(box(31, 32, 48, 84), fill=WHITE)
    else:
        ds.polygon(px([(0, 84), (19, 69), (49, 46), (82, 32), (99, 54), (114, 69),
                       (128, 80), (128, 128), (0, 128)]), fill=MOUNTAIN)
        ds.polygon(px([(82, 32), (99, 54), (114, 69), (128, 80), (128, 128), (82, 128)]),
                   fill=MOUNTAIN_SHADE)
        meadow = [(0, 94)]
        meadow += curve((0, 94), (22, 82), (44, 88))
        meadow += curve((44, 88), (64, 98), (82, 88))
        meadow += curve((82, 88), (104, 80), (128, 92))
        meadow += [(128, 128), (0, 128)]
        ds.polygon(px(meadow), fill=MEADOW)
        ds.rectangle(box(34, 0, 47, 128), fill=RED)
        ds.rectangle(box(34, 30, 47, 84), fill=WHITE)

    # Field of view of the telescope
    field = Image.new('L', (big, big), 0)
    ImageDraw.Draw(field).ellipse(box(7, 7, 121, 121), fill=255)
    icon.paste(scene, (0, 0), field)

    # Cross hairs, two thirds of the radius
    half = cross / 2
    draw.rectangle(box(64 - half, 26, 64 + half, 102), fill=BLACK)
    draw.rectangle(box(26, 64 - half, 102, 64 + half), fill=BLACK)

    return icon.resize((size, size), Image.LANCZOS)


images = [draw_icon(size) for size in SIZES]
images[0].save(OUTPUT, format='ICO',
               sizes=[(size, size) for size in SIZES], append_images=images[1:])
print('Hotovo:', OUTPUT)
