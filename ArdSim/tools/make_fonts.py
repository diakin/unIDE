# ArdSim: generates stand-in fonts in UTFT format (fonts/*.c).
# They are used only when the real UTFT font files of the sketch are not
# found: each font is a separate .c file in libardsim_fonts.a, so the
# linker takes it only for a name nobody else defined.
# Format: xsize, ysize, first char, char count; then each char row by row,
# xsize/8 bytes per row, most significant bit = leftmost pixel.
import os
import sys
from PIL import Image, ImageDraw, ImageFont

FontDir = '/usr/share/fonts/truetype'
Mono = FontDir + '/dejavu/DejaVuSansMono.ttf'
MonoBold = FontDir + '/dejavu/DejaVuSansMono-Bold.ttf'
Sans = FontDir + '/dejavu/DejaVuSans.ttf'
SansBold = FontDir + '/dejavu/DejaVuSans-Bold.ttf'
Arial = FontDir + '/liberation/LiberationSans-Regular.ttf'
ArialBold = FontDir + '/liberation/LiberationSans-Bold.ttf'

# name, cell width, cell height, ttf
Fonts = [
    ('SmallFont', 8, 12, Mono),
    ('BigFont', 16, 16, MonoBold),
    ('SevenSegNumFont', 32, 50, SansBold),
    ('UbuntuBold', 24, 32, SansBold),
    ('Ubuntu', 24, 32, Sans),
    ('arial_bold', 16, 16, ArialBold),
    ('arial_normal', 16, 16, Arial),
    ('GroteskBold16x32', 16, 32, SansBold),
    ('GroteskBold24x48', 24, 48, SansBold),
    ('Retro8x16', 8, 16, Mono),
    ('various_symbols', 16, 16, Sans),
    ('Various_Symbols_16x32', 16, 32, Sans),
]
First = 0x20
Count = 95


def fitFont(path, width, height):
    # the largest size where the line (ascent + descent) fits the cell
    # height; the width is fitted later by stretching (UTFT fonts fill
    # their cells, a TrueType glyph at this size is narrower)
    best = ImageFont.truetype(path, 4)
    for size in range(4, height * 2):
        font = ImageFont.truetype(path, size)
        ascent, descent = font.getmetrics()
        if ascent + descent > height:
            break
        best = font
    return best


def widestGlyph(font, first, count):
    return max(font.getbbox(chr(code))[2] - font.getbbox(chr(code))[0]
               for code in range(first, first + count) if chr(code) != ' ')


def glyphBytes(font, char, width, height, widest):
    # render 4x larger in grey, stretch the widest glyph to the cell width
    # minus one pixel of spacing, then threshold to 1 bit
    scale = 4
    big = ImageFont.truetype(font.path, font.size * scale)
    ascent, descent = big.getmetrics()
    left, top, right, bottom = big.getbbox(char)
    canvasW = max(right - left, 1) + 2 * scale
    canvasH = height * scale
    image = Image.new('L', (canvasW, canvasH), 0)
    draw = ImageDraw.Draw(image)
    offsetY = (canvasH - (ascent + descent)) // 2
    draw.text((scale - left, offsetY), char, font=big, fill=255)
    stretch = (width - 1) / float(widest)
    if stretch < 1.0:
        stretch = 1.0
    glyphW = max(1, int(round((right - left) / float(scale) * stretch)))
    glyphW = min(glyphW, width)
    small = image.crop((scale, 0, scale + max(right - left, 1), canvasH)).resize(
        (glyphW, height), Image.LANCZOS)
    cell = Image.new('1', (width, height), 0)
    offsetX = (width - glyphW) // 2
    for row in range(height):
        for col in range(glyphW):
            if small.getpixel((col, row)) >= 100:
                cell.putpixel((offsetX + col, row), 1)
    result = []
    for row in range(height):
        for byteIndex in range(width // 8):
            value = 0
            for bitIndex in range(8):
                if cell.getpixel((byteIndex * 8 + bitIndex, row)):
                    value |= 0x80 >> bitIndex
            result.append(value)
    return result


def main(outDir):
    os.makedirs(outDir, exist_ok=True)
    for name, width, height, path in Fonts:
        font = fitFont(path, width, height)
        # SevenSegNumFont in UTFT holds only the digits
        first, count = (0x30, 10) if name == 'SevenSegNumFont' else (First, Count)
        data = [width, height, first, count]
        widest = widestGlyph(font, first, count)
        for code in range(first, first + count):
            data += glyphBytes(font, chr(code), width, height, widest)
        lines = ['// ArdSim stand-in for the UTFT font %s (%dx%d), made by' % (name, width, height),
                 '// tools/make_fonts.py. Replaced by the real font file when it is linked.',
                 'const unsigned char %s[%d] = {' % (name, len(data))]
        for start in range(0, len(data), 16):
            lines.append('  ' + ','.join('0x%02X' % value for value in data[start:start + 16]) + ',')
        lines.append('};')
        with open(os.path.join(outDir, name + '.c'), 'w', newline='\r\n') as output:
            output.write('\n'.join(lines) + '\n')
        print(name, width, height, len(data))


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '..', 'fonts'))
