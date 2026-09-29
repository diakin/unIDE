# -*- coding: utf-8 -*-
# Toolbar icons for SyntaxHLClaude from the Lazarus "general_purpose" set by
# Roland Hahn (CC0 1.0, see svg/readme_RolandHahn.txt). The SVG sources are in
# svg/ (copied from gitlab.com/freepascal.org/lazarus/resources,
# image_sources/images/general_purpose/svg (Roland Hahn)).
#
# Renders every icon from SVG at 28x28 with alpha and writes:
#   icons_light.bmp, icons_dark.bmp - strips 28*N x 56, 32-bit BGRA with
#                                     premultiplied alpha (for AlphaBlend):
#                                     row 0 normal, row 1 disabled
#   ..\toolbar_icons.res            - BMP_ICONS_LIGHT, BMP_ICONS_DARK
#                                     (same as brcc32 toolbar_icons.rc)
#   preview.png                     - both themes, real size and x3
# Needs Python 3, Pillow and cairosvg.  Run: python make_icons.py
import io, os, struct
import cairosvg
from PIL import Image

SIZE = 28

# Order = index in the strip (Unit1.pas, IconOpen..IconStepOver)
ICONS = [
    ('open',      'Open_01'),
    ('save',      'Save_01'),
    ('saveprj',   'SaveAs_01'),
    ('undo',      'Undo_01'),
    ('cut',       'Cut_01'),
    ('copy',      'Copy_01'),
    ('paste',     'Paste_01'),
    ('run',       'Play_01'),
    ('viewunit',  'File_02'),
    ('viewform',  'Window_02'),
    ('newform',   'Window_19'),
    ('pause',     'Pause_01'),
    ('reset',     'Stop_01'),
    ('traceinto', 'Arrow_28'),
    ('stepover',  'Arrow_44'),
]

# Floppy body: black as usual instead of the original blue; on the dark
# theme a dark grey, otherwise it would vanish on the dark panel
FLOPPY_BLUE = '#0062f5'
FLOPPY = {'light': '#262626', 'dark': '#707070'}
FLOPPY_ICONS = ('Save_01', 'SaveAs_01')

THEMES = {
    # face for the preview, disabled: grey level range and alpha factor
    'light': ((0xF0, 0xF0, 0xF0), (110, 200), 0.55),
    'dark':  ((0x30, 0x2D, 0x2D), (150, 215), 0.6),
}


def render(theme, name):
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, 'svg', name + '_32.svg'), encoding='utf-8') as fin:
        svg = fin.read()
    if name in FLOPPY_ICONS:
        svg = svg.replace(FLOPPY_BLUE, FLOPPY[theme])
    png = cairosvg.svg2png(bytestring=svg.encode('utf-8'),
                           output_width=SIZE, output_height=SIZE)
    return Image.open(io.BytesIO(png)).convert('RGBA')


def disabled(icon, theme):
    """Grey copy: brightness squeezed into a range, alpha reduced."""
    _, (low, high), alpha_mul = THEMES[theme]
    out = Image.new('RGBA', icon.size)
    src = icon.load()
    dst = out.load()
    for yy in range(icon.height):
        for xx in range(icon.width):
            red, green, blue, alpha = src[xx, yy]
            lum = (red * 30 + green * 59 + blue * 11) // 100
            grey = low + (high - low) * lum // 255
            dst[xx, yy] = (grey, grey, grey, int(alpha * alpha_mul))
    return out


def build_strip(theme):
    strip = Image.new('RGBA', (SIZE * len(ICONS), SIZE * 2), (0, 0, 0, 0))
    for index, (_, name) in enumerate(ICONS):
        icon = render(theme, name)
        strip.paste(icon, (index * SIZE, 0))
        strip.paste(disabled(icon, theme), (index * SIZE, SIZE))
    return strip


def bmp32_bytes(image):
    """Whole .bmp file: 32-bit BI_RGB, bottom-up, premultiplied BGRA."""
    width, height = image.size
    pix = image.load()
    rows = bytearray()
    for yy in range(height - 1, -1, -1):
        for xx in range(width):
            red, green, blue, alpha = pix[xx, yy]
            rows += bytes((blue * alpha // 255, green * alpha // 255,
                           red * alpha // 255, alpha))
    info = struct.pack('<IiiHHIIiiII', 40, width, height, 1, 32, 0,
                       len(rows), 2835, 2835, 0, 0)
    head = struct.pack('<2sIHHI', b'BM', 14 + len(info) + len(rows), 0, 0,
                       14 + len(info))
    return head + info + bytes(rows)


def res_entry(res_type, name, data):
    def ident(value):
        if isinstance(value, int):
            return struct.pack('<HH', 0xFFFF, value)
        return (value + '\0').encode('utf-16-le')
    head = ident(res_type) + ident(name)
    head += b'\0' * ((4 - (8 + len(head)) % 4) % 4)
    head += struct.pack('<IHHII', 0, 0x0030, 0x0409, 0, 0)
    entry = struct.pack('<II', len(data), 8 + len(head)) + head + data
    return entry + b'\0' * ((4 - len(entry) % 4) % 4)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    strips = {theme: build_strip(theme) for theme in THEMES}
    # empty entry that marks a 32-bit .res file
    res = struct.pack('<II', 0, 32) + struct.pack('<HHHH', 0xFFFF, 0, 0xFFFF, 0) + b'\0' * 16
    for theme, strip in strips.items():
        data = bmp32_bytes(strip)
        with open(os.path.join(here, 'icons_%s.bmp' % theme), 'wb') as fout:
            fout.write(data)
        # RT_BITMAP = the .bmp without its 14-byte BITMAPFILEHEADER
        res += res_entry(2, 'BMP_ICONS_' + theme.upper(), data[14:])
    with open(os.path.join(here, '..', 'toolbar_icons.res'), 'wb') as fout:
        fout.write(res)

    # preview: each theme on its face, x3 and real size
    zoom = 3
    cell = SIZE * zoom + 10
    count = len(ICONS)
    prev = Image.new('RGB', (cell * count + 10, 2 * (cell * 2 + SIZE + 20)),
                     (255, 255, 255))
    top = 0
    for theme, strip in strips.items():
        face = THEMES[theme][0]
        band = Image.new('RGB', (prev.width, cell * 2 + SIZE + 20), face)
        for index in range(count):
            for row in range(2):
                icon = strip.crop((index * SIZE, row * SIZE,
                                   index * SIZE + SIZE, row * SIZE + SIZE))
                big = icon.resize((SIZE * zoom, SIZE * zoom), Image.NEAREST)
                band.paste(big, (5 + index * cell, 5 + row * cell), big)
            icon = strip.crop((index * SIZE, 0, index * SIZE + SIZE, SIZE))
            band.paste(icon, (5 + index * cell + (SIZE * zoom - SIZE) // 2,
                              cell * 2 + 10), icon)
        prev.paste(band, (0, top))
        top += band.height
    prev.save(os.path.join(here, 'preview.png'))


if __name__ == '__main__':
    main()
