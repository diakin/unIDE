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
    # the largest size where 'M' and 'g' fit in the cell
    best = ImageFont.truetype(path, 4)
    for size in range(4, height * 2):
        font = ImageFont.truetype(path, size)
        ascent, descent = font.getmetrics()
        widest = max(font.getbbox(chr(code))[2] for code in range(First, First + Count))
        if ascent + descent > height or widest > width + 1:
            break
        best = font
    return best


def glyphBytes(font, char, width, height):
    image = Image.new('1', (width, height), 0)
    draw = ImageDraw.Draw(image)
    ascent, descent = font.getmetrics()
    left, top, right, bottom = font.getbbox(char)
    offsetX = (width - (right - left)) // 2 - left
    offsetY = (height - (ascent + descent)) // 2
    draw.text((offsetX, offsetY), char, font=font, fill=1)
    result = []
    for row in range(height):
        for byteIndex in range(width // 8):
            value = 0
            for bitIndex in range(8):
                if image.getpixel((byteIndex * 8 + bitIndex, row)):
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
        for code in range(first, first + count):
            data += glyphBytes(font, chr(code), width, height)
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
