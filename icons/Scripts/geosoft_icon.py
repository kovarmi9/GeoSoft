# Theodolite on a globe, writes ..\GeoSoft.ico
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

GRID = 256          # drawn in a 256 x 256 grid
SUPER = 8           # drawn 8x larger, then scaled down smoothly

BLACK = (0, 0, 0)
BLUE = (21, 96, 130)
BOX = (4, 36, 51)
WHITE = (255, 255, 255)

# Icon size: line width in the grid, small icons need thicker lines
SIZES = {256: 12, 64: 12, 48: 14, 40: 14, 32: 16, 24: 20, 20: 22, 16: 24}

OUTPUT = Path(__file__).resolve().parent.parent / 'GeoSoft.ico'


def draw_icon(size):
    line = SIZES[size]
    scale = size * SUPER / GRID
    width = round(line * scale)

    def xy(*points):
        """Grid points to pixels of the large image."""
        return [(x * scale, y * scale) for x, y in points]

    def box(x1, y1, x2, y2):
        return [x1 * scale, y1 * scale, x2 * scale, y2 * scale]

    big = size * SUPER
    icon = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    draw.ellipse(box(0, 0, 256, 256), fill=WHITE)

    # Globe, the circle cuts it later
    globe = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    dg = ImageDraw.Draw(globe)
    dg.ellipse(box(46, 4, 210, 252), outline=BLUE, width=width)
    dg.line(xy((128, 0), (128, 256)), fill=BLUE, width=width)
    dg.line(xy((0, 128), (256, 128)), fill=BLUE, width=width)
    # Parallels are arcs of circles with radius 186
    dg.arc(box(-58, -308, 314, 64 + line / 2), 0, 180, fill=BLUE, width=width)
    dg.arc(box(-58, 192 - line / 2, 314, 564), 180, 360, fill=BLUE, width=width)
    field = Image.new('L', (big, big), 0)
    ImageDraw.Draw(field).ellipse(box(4, 4, 252, 252), fill=255)
    globe.putalpha(ImageChops.multiply(globe.getchannel('A'), field))
    icon.alpha_composite(globe)

    # Tripod, the legs end at the rim
    draw.line(xy((110, 128), (66, 233)), fill=BLACK, width=width)
    draw.line(xy((128, 128), (128, 246)), fill=BLACK, width=width)
    draw.line(xy((146, 128), (190, 233)), fill=BLACK, width=width)
    draw.polygon(xy((114, 116), (142, 116), (148, 136), (108, 136)), fill=BLACK)

    # Instrument on top
    draw.rectangle(box(80, 78, 166, 118), fill=WHITE, outline=BOX, width=width)

    # Black rim
    draw.ellipse(box(0, 0, 256, 256), outline=BLACK, width=width)

    return icon.resize((size, size), Image.LANCZOS)


images = [draw_icon(size) for size in SIZES]
images[0].save(OUTPUT, format='ICO',
               sizes=[(size, size) for size in SIZES], append_images=images[1:])
print('Hotovo:', OUTPUT)
