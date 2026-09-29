# -*- coding: utf-8 -*-
# Toolbar icons for SyntaxHLClaude from the Lazarus "general_purpose" set by
# Roland Hahn (CC0 1.0, see png/readme_general_purpose.txt).
#   png/ - the 24x24 PNG files as they are in Lazarus (images/general_purpose)
#   svg/ - SVG sources of the two floppies (gitlab.com/freepascal.org/lazarus/
#          resources, image_sources/images/general_purpose/svg (Roland Hahn)):
#          they are rendered here, with the blue body recoloured
#
# Writes:
#   icons_light.bmp, icons_dark.bmp - strips 24*N x 48, 32-bit BGRA with
#                                     premultiplied alpha (for AlphaBlend):
#                                     row 0 normal, row 1 disabled
#   ..\toolbar_icons.res            - BMP_ICONS_LIGHT, BMP_ICONS_DARK
#                                     (same as brcc32 toolbar_icons.rc)
#   preview.png                     - buttons as TUiIconButton draws them,
#                                     both themes, x3 and real size
# Needs Python 3, Pillow and cairosvg.  Run: python make_icons.py
import io, os, struct
import cairosvg
from PIL import Image

SIZE = 24

# Order = index in the strip. MUST match the constants in Unit1.pas:
# IconOpen = 0, IconSave = 1, IconUndo = 2, IconCut = 3, IconCopy = 4,
# IconPaste = 5, IconSavePrj = 6, IconRun = 7 ... IconStepOver = 14
ICONS = [
    ('open',      'Open_01'),
    ('save',      'Save_01'),
    ('undo',      'Undo_01'),
    ('cut',       'Cut_01'),
    ('copy',      'Copy_01'),
    ('paste',     'Paste_01'),
    ('saveprj',   'SaveAs_01'),
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
    """Lazarus PNG as is; the floppies from their SVG with the body
    recoloured (the PNG of the same SVG differs from this render by a few
    levels of 255 at most)."""
    here = os.path.dirname(os.path.abspath(__file__))
    if name not in FLOPPY_ICONS:
        return Image.open(os.path.join(here, 'png', '%s_%d.png' % (name, SIZE))
                          ).convert('RGBA')
    with open(os.path.join(here, 'svg', '%s_%d.svg' % (name, SIZE)),
              encoding='utf-8') as fin:
        svg = fin.read()
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

    # preview: toolbar buttons as TUiIconButton draws them (34x34, ring 2,
    # corner 8): normal, under the mouse, disabled; real size and x3
    from PIL import ImageDraw
    button, ring, corner = 34, 2, 8
    looks = {  # panel, plate (IconButton.BG), hot (IconButton.HotBG), RGB
        'light': ((0xF0, 0xF0, 0xF0), (0xFC, 0xFC, 0xFC), (0xC4, 0xDC, 0xF2)),
        'dark':  ((0x2D, 0x2D, 0x30), (0x48, 0x48, 0x48), (0x60, 0x60, 0x60)),
    }
    count = len(ICONS)
    rows = []
    for theme, strip in strips.items():
        panel, plate, hot = looks[theme]
        for state in ('normal', 'hot', 'disabled'):
            row = Image.new('RGB', (count * (button + 1) + 1, button + 2), panel)
            draw = ImageDraw.Draw(row)
            for index in range(count):
                left = 1 + index * (button + 1)
                outer = hot if state == 'hot' else panel
                draw.rounded_rectangle([left, 1, left + button - 1, button],
                                       radius=corner, fill=outer)
                draw.rounded_rectangle([left + ring, 1 + ring,
                                        left + button - 1 - ring,
                                        button - ring],
                                       radius=corner - ring, fill=plate)
                src_row = 1 if state == 'disabled' else 0
                icon = strip.crop((index * SIZE, src_row * SIZE,
                                   index * SIZE + SIZE, src_row * SIZE + SIZE))
                offset = (button - SIZE) // 2
                row.paste(icon, (left + offset, 1 + offset), icon)
            rows.append(row)
    width = rows[0].width
    prev = Image.new('RGB', (width * 3, sum(r.height for r in rows) * 3 +
                             sum(r.height for r in rows) + 8), (255, 255, 255))
    top = 0
    for row in rows:
        prev.paste(row.resize((row.width * 3, row.height * 3), Image.NEAREST),
                   (0, top))
        top += row.height * 3
    top += 8
    for row in rows:
        prev.paste(row, (0, top))
        top += row.height
    prev.save(os.path.join(here, 'preview.png'))


if __name__ == '__main__':
    main()
