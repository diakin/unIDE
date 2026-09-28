# -*- coding: utf-8 -*-
# Toolbar icons for SyntaxHLClaude: flat rounded tiles with a white glyph.
# Draws every icon at 8x size, scales down to 20x20 and writes:
#   icons_light.bmp, icons_dark.bmp - strips 20*N x 40: row 0 normal,
#                                     row 1 disabled; transparent = clFuchsia
#   ..\toolbar_icons.res            - BMP_ICONS_LIGHT, BMP_ICONS_DARK
#   preview.png                     - both themes, real size and x4
# Needs Python 3 + Pillow.  Run: python make_icons.py
import colorsys, os, struct
from PIL import Image, ImageDraw

SIZE = 20          # icon side, px
SCALE = 8          # supersampling
BIG = SIZE * SCALE
FUCHSIA = (255, 0, 255)

# Order = index in the strip (used by Unit1.pas, see IconIdx* constants)
ICONS = [
    ('open',      (0xE3, 0x8E, 0x2A)),
    ('save',      (0x2F, 0x6D, 0xB5)),
    ('undo',      (0x6B, 0x5B, 0xA6)),
    ('cut',       (0xC2, 0x43, 0x4C)),
    ('copy',      (0x1F, 0x8A, 0x78)),
    ('paste',     (0x8B, 0x5E, 0x34)),
    ('saveprj',   (0x25, 0x50, 0x8F)),
    ('run',       (0x3C, 0x9A, 0x3F)),
    ('viewunit',  (0x1B, 0x96, 0xD0)),
    ('viewform',  (0x4B, 0x6E, 0x9E)),
    ('newform',   (0x2E, 0x9A, 0x6B)),
    ('pause',     (0xD9, 0x93, 0x1E)),
    ('reset',     (0xC9, 0x3A, 0x36)),
    ('traceinto', (0x7A, 0x58, 0xB0)),
    ('stepover',  (0x57, 0x67, 0xB8)),
]


def px(value):
    """Icon pixels -> supersampled coordinates."""
    return int(round(value * SCALE))


def box(left, top, right, bottom):
    return [px(left), px(top), px(right), px(bottom)]


def rrect(draw, coords, radius, fill):
    draw.rounded_rectangle(box(*coords), radius=px(radius), fill=fill)


def line(draw, points, width, fill=255):
    pts = [(px(xx), px(yy)) for xx, yy in points]
    draw.line(pts, fill=fill, width=px(width), joint='curve')
    for xx, yy in pts[:1] + pts[-1:]:
        rad = px(width) / 2
        draw.ellipse([xx - rad, yy - rad, xx + rad, yy + rad], fill=fill)


def poly(draw, points, fill=255):
    draw.polygon([(px(xx), px(yy)) for xx, yy in points], fill=fill)


def ring(draw, cx, cy, rad, width, fill=255):
    draw.ellipse(box(cx - rad, cy - rad, cx + rad, cy + rad), fill=fill)
    inner = rad - width
    draw.ellipse(box(cx - inner, cy - inner, cx + inner, cy + inner), fill=0)


# Each glyph: 255 = glyph colour, 0 = tile shows through
def glyph_open(draw):
    poly(draw, [(3.5, 5), (8, 5), (9.5, 6.5), (15, 6.5), (15, 8.5),
                (3.5, 8.5)])
    poly(draw, [(3.5, 5), (5, 5), (5, 15), (3.5, 15)])
    poly(draw, [(5.5, 9.3), (17.2, 9.3), (14.8, 15.2), (3.5, 15.2)])


def floppy(draw, left, top, side):
    right, bottom = left + side, top + side
    cut = side * 0.22
    poly(draw, [(left, top), (right - cut, top), (right, top + cut),
                (right, bottom), (left, bottom)])
    # shutter window
    draw.rectangle(box(left + side * 0.24, top, left + side * 0.70,
                       top + side * 0.33), fill=0)
    draw.rectangle(box(left + side * 0.50, top + side * 0.05,
                       left + side * 0.62, top + side * 0.27), fill=255)
    # label
    rrect(draw, (left + side * 0.18, top + side * 0.52, right - side * 0.18,
                 bottom - side * 0.08), side * 0.06, 0)


def glyph_save(draw):
    floppy(draw, 3.5, 3.5, 13)


def glyph_saveprj(draw):
    # back floppy as an outline corner, front floppy solid
    poly(draw, [(3, 3), (12, 3), (12, 4.6), (4.6, 4.6), (4.6, 12), (3, 12)])
    floppy(draw, 6, 6, 11)


def glyph_undo(draw):
    draw.arc(box(6.2, 6, 16.4, 15.6), start=-90, end=110, fill=255,
             width=px(2.4))
    line(draw, [(11.3, 7.2), (8.2, 7.2)], 2.4)
    poly(draw, [(3.2, 7.2), (8.6, 3.2), (8.6, 11.2)])
    line(draw, [(9.6, 14.4), (7, 14.4)], 2.4)


def glyph_cut(draw):
    line(draw, [(7.2, 3.2), (12.4, 12)], 1.9)
    line(draw, [(12.8, 3.2), (7.6, 12)], 1.9)
    ring(draw, 6.4, 14, 2.9, 1.5)
    ring(draw, 13.6, 14, 2.9, 1.5)
    draw.ellipse(box(9.3, 8.6, 10.7, 10), fill=0)


def sheet_lines(draw, left, top, right, count, step):
    for index in range(count):
        yy = top + index * step
        draw.rectangle(box(left, yy, right, yy + 1.1), fill=0)


def glyph_copy(draw):
    poly(draw, [(3.5, 3), (11.5, 3), (11.5, 4.7), (5.2, 4.7), (5.2, 13),
                (3.5, 13)])
    rrect(draw, (7, 6.2, 16.5, 17), 1, 255)
    sheet_lines(draw, 9, 8.8, 14.5, 3, 2.6)


def glyph_paste(draw):
    rrect(draw, (4, 4.5, 16, 17.3), 1.3, 255)
    rrect(draw, (5.6, 6.4, 14.4, 15.8), 0.6, 0)
    rrect(draw, (6.6, 2.6, 13.4, 6.4), 0.9, 0)
    rrect(draw, (7.4, 3.2, 12.6, 5.8), 0.7, 255)
    for index in range(3):
        yy = 9 + index * 2.3
        draw.rectangle(box(7.3, yy, 12.7, yy + 1.1), fill=255)


def glyph_run(draw):
    poly(draw, [(6.2, 3.8), (16, 10), (6.2, 16.2)])
    line(draw, [(6.2, 3.8), (16, 10), (6.2, 16.2), (6.2, 3.8)], 1.2)


def glyph_viewunit(draw):
    poly(draw, [(4.5, 3), (12, 3), (15.5, 6.5), (15.5, 17), (4.5, 17)])
    poly(draw, [(12, 3), (12, 6.5), (15.5, 6.5)], fill=0)
    poly(draw, [(12.6, 4.2), (12.6, 5.9), (14.3, 5.9)], fill=255)
    draw.rectangle(box(6.5, 8.5, 13.5, 9.6), fill=0)
    draw.rectangle(box(8, 11, 13.5, 12.1), fill=0)
    draw.rectangle(box(8, 13.5, 11.5, 14.6), fill=0)


def window(draw, left, top, right, bottom):
    rrect(draw, (left, top, right, bottom), 1.1, 255)
    rrect(draw, (left + 1.4, top + 3.4, right - 1.4, bottom - 1.4), 0.3, 0)


def glyph_viewform(draw):
    window(draw, 3, 4, 17, 16)
    draw.rectangle(box(6, 10, 10, 11.2), fill=255)
    draw.rectangle(box(6, 12.4, 12, 13.6), fill=255)


def glyph_newform(draw):
    window(draw, 2.8, 3.5, 15, 14)
    draw.ellipse(box(10.3, 10.3, 18, 18), fill=0)
    draw.ellipse(box(11, 11, 17.3, 17.3), fill=255)
    draw.rectangle(box(12.1, 13.6, 16.2, 14.7), fill=0)
    draw.rectangle(box(13.6, 12.1, 14.7, 16.2), fill=0)


def glyph_pause(draw):
    rrect(draw, (5.5, 4.5, 8.7, 15.5), 0.8, 255)
    rrect(draw, (11.3, 4.5, 14.5, 15.5), 0.8, 255)


def glyph_reset(draw):
    rrect(draw, (5, 5, 15, 15), 1.6, 255)


def glyph_traceinto(draw):
    line(draw, [(10, 3.2), (10, 9.5)], 2.2)
    poly(draw, [(5.8, 8.6), (14.2, 8.6), (10, 13.2)])
    rrect(draw, (4, 15, 16, 16.8), 0.9, 255)


def glyph_stepover(draw):
    draw.arc(box(3.4, 4.6, 16, 17), start=180, end=335, fill=255,
             width=px(2.2))
    poly(draw, [(16.8, 6.8), (16.4, 12.8), (11.4, 10.2)])
    draw.ellipse(box(7.9, 12.6, 12.1, 16.8), fill=255)


def tile_mask():
    mask = Image.new('L', (BIG, BIG), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, BIG - 1, BIG - 1],
                                           radius=px(4.2), fill=255)
    return mask


def glyph_mask(name):
    mask = Image.new('L', (BIG, BIG), 0)
    globals()['glyph_' + name](ImageDraw.Draw(mask))
    return mask


def shade(rgb, light_mul, sat_mul):
    hue, lit, sat = colorsys.rgb_to_hls(*[chan / 255 for chan in rgb])
    red, green, blue = colorsys.hls_to_rgb(hue, min(1, lit * light_mul),
                                           min(1, sat * sat_mul))
    return tuple(int(round(chan * 255)) for chan in (red, green, blue))


THEMES = {
    # tile colour transform, glyph colour, disabled tile, disabled glyph
    'light': (lambda rgb: rgb, (255, 255, 255),
              (0xC4, 0xC4, 0xC4), (0xF6, 0xF6, 0xF6)),
    'dark':  (lambda rgb: shade(rgb, 0.86, 0.88), (0xEE, 0xEE, 0xEE),
              (0x5E, 0x5E, 0x5E), (0x96, 0x96, 0x96)),
}


def render(tile_rgb, glyph_rgb, tile_small, glyph_small):
    """20x20 RGB on fuchsia. Tile edge: hard (no blend with an unknown
    button face), glyph inside the tile: anti-aliased."""
    out = Image.new('RGB', (SIZE, SIZE), FUCHSIA)
    for yy in range(SIZE):
        for xx in range(SIZE):
            if tile_small.getpixel((xx, yy)) < 128:
                continue
            part = glyph_small.getpixel((xx, yy)) / 255
            out.putpixel((xx, yy), tuple(
                int(round(tile_rgb[chan] * (1 - part) + glyph_rgb[chan] * part))
                for chan in range(3)))
    return out


def build_strip(theme):
    tint, glyph_rgb, off_tile, off_glyph = THEMES[theme]
    tile_small = tile_mask().resize((SIZE, SIZE), Image.LANCZOS)
    strip = Image.new('RGB', (SIZE * len(ICONS), SIZE * 2), FUCHSIA)
    for index, (name, base) in enumerate(ICONS):
        glyph_small = glyph_mask(name).resize((SIZE, SIZE), Image.LANCZOS)
        strip.paste(render(tint(base), glyph_rgb, tile_small, glyph_small),
                    (index * SIZE, 0))
        strip.paste(render(off_tile, off_glyph, tile_small, glyph_small),
                    (index * SIZE, SIZE))
    # bottom-left pixel of every cell must stay fuchsia (TSpeedButton key)
    for index in range(len(ICONS)):
        assert strip.getpixel((index * SIZE, SIZE - 1)) == FUCHSIA
        assert strip.getpixel((index * SIZE, SIZE * 2 - 1)) == FUCHSIA
    return strip


def bmp_dib(image):
    """24-bit bottom-up DIB without BITMAPFILEHEADER (RT_BITMAP body)."""
    width, height = image.size
    stride = (width * 3 + 3) & ~3
    rows = bytearray()
    for yy in range(height - 1, -1, -1):
        row = bytearray()
        for xx in range(width):
            red, green, blue = image.getpixel((xx, yy))
            row += bytes((blue, green, red))
        row += b'\0' * (stride - len(row))
        rows += row
    header = struct.pack('<IiiHHIIiiII', 40, width, height, 1, 24, 0,
                         len(rows), 2835, 2835, 0, 0)
    return header + bytes(rows)


def res_entry(res_type, name, data):
    def ident(value):
        if isinstance(value, int):
            return struct.pack('<HH', 0xFFFF, value)
        return (value + '\0').encode('utf-16-le')
    head = ident(res_type) + ident(name)
    head += b'\0' * ((4 - (8 + len(head)) % 4) % 4)
    head += struct.pack('<IHHII', 0, 0x1030, 0x0409, 0, 0)
    entry = struct.pack('<II', len(data), 8 + len(head)) + head + data
    return entry + b'\0' * ((4 - len(entry) % 4) % 4)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    strips = {theme: build_strip(theme) for theme in THEMES}
    res = res_entry(0, 0, b'')
    for theme, strip in strips.items():
        strip.save(os.path.join(here, 'icons_%s.bmp' % theme))
        res += res_entry(2, 'BMP_ICONS_' + theme.upper(), bmp_dib(strip))
    with open(os.path.join(here, '..', 'toolbar_icons.res'), 'wb') as fout:
        fout.write(res)

    # preview: each theme on its button face, real size and x4
    faces = {'light': (0xF0, 0xF0, 0xF0), 'dark': (0x3A, 0x3A, 0x3A)}
    count = len(ICONS)
    zoom = 4
    cell = SIZE * zoom + 12
    prev = Image.new('RGB', (cell * count + 12, 2 * (cell * 2 + 40) + 12),
                     (255, 255, 255))
    top = 6
    for theme, strip in strips.items():
        face = faces[theme]
        band = Image.new('RGB', (prev.width, cell * 2 + 34), face)
        for index in range(count):
            for row in range(2):
                icon = strip.crop((index * SIZE, row * SIZE,
                                   index * SIZE + SIZE, row * SIZE + SIZE))
                data = icon.load()
                for yy in range(SIZE):
                    for xx in range(SIZE):
                        if data[xx, yy] == FUCHSIA:
                            data[xx, yy] = face
                big = icon.resize((SIZE * zoom, SIZE * zoom), Image.NEAREST)
                band.paste(big, (6 + index * cell, 6 + row * cell))
                band.paste(icon, (6 + index * cell + SIZE * zoom // 2 - 10,
                                  cell * 2 + 8))
        prev.paste(band, (0, top))
        top += band.height + 6
    prev.save(os.path.join(here, 'preview.png'))


if __name__ == '__main__':
    main()
