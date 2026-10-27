# Значок uniFAR: две синие панели с бирюзовой рамкой, как окно FAR.
# Пишет uniFAR.ico и uniFAR_icon.res (RT_ICON + RT_GROUP_ICON 'UNIFARICON').
# Запуск: python make_icon.py (нужен Pillow); результат - в эту же папку.
import os, struct
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
BLUE = (0, 0, 128, 255)
CYAN = (0, 255, 255, 255)
YELLOW = (255, 255, 0, 255)
WHITE = (255, 255, 255, 255)
TEAL = (0, 128, 128, 255)

def draw(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size / 32.0
    d.rectangle([0, 0, size - 1, size - 1], fill=BLUE)
    # две панели
    half = size // 2
    for x0 in (1, half):
        x1 = x0 + half - 2 if x0 == 1 else size - 2
        d.rectangle([x0, 1, x1, size - 6 * s], outline=CYAN)
        # строки имён
        for row in range(3):
            y = int(5 * s + row * 5 * s)
            if y + 1 >= size - 7 * s:
                break
            color = YELLOW if row == 0 else WHITE
            d.line([x0 + 2 * s, y, x1 - 2 * s, y], fill=color, width=max(1, int(s)))
    # курсор в левой панели
    y = int(10 * s)
    d.rectangle([2 * s, y - s, half - 3 * s, y + s], fill=TEAL)
    # кейбар
    d.rectangle([0, size - 4 * s, size - 1, size - 1], fill=TEAL)
    return img

def bmp_entry(img):
    # DIB 32 бит (BGRA снизу вверх) + маска AND
    w, h = img.size
    px = img.load()
    header = struct.pack('<IiiHHIIiiII', 40, w, h * 2, 1, 32, 0, 0, 0, 0, 0, 0)
    xor = bytearray()
    for y in range(h - 1, -1, -1):
        for x in range(w):
            r, g, b, a = px[x, y]
            xor += bytes((b, g, r, a))
    row_bytes = ((w + 31) // 32) * 4
    andmask = bytearray(row_bytes * h)
    return header + bytes(xor) + bytes(andmask)

sizes = [16, 32, 48]
images = [draw(sz) for sz in sizes]
entries = [bmp_entry(im) for im in images]

# .ico
ico = struct.pack('<HHH', 0, 1, len(sizes))
offset = 6 + 16 * len(sizes)
for sz, data in zip(sizes, entries):
    ico += struct.pack('<BBBBHHII', sz % 256, sz % 256, 0, 0, 1, 32, len(data), offset)
    offset += len(data)
for data in entries:
    ico += data
open(os.path.join(HERE, 'uniFAR.ico'), 'wb').write(ico)

# .res
def res_entry(rtype, name, data, lang=0x0419):
    def name_field(v):
        if isinstance(v, int):
            return struct.pack('<HH', 0xFFFF, v)
        b = v.upper().encode('utf-16-le') + b'\0\0'
        return b
    hdr = name_field(rtype) + name_field(name)
    if len(hdr) % 4:
        hdr += b'\0' * (4 - len(hdr) % 4)
    hdr += struct.pack('<IHHII', 0, 0x1030, lang, 0, 0)
    header_size = 8 + len(hdr)
    out = struct.pack('<II', len(data), header_size) + hdr + data
    if len(out) % 4:
        out += b'\0' * (4 - len(out) % 4)
    return out

res = struct.pack('<II', 0, 32) + struct.pack('<HHHH', 0xFFFF, 0, 0xFFFF, 0) + \
      struct.pack('<IHHII', 0, 0, 0, 0, 0)
group = struct.pack('<HHH', 0, 1, len(sizes))
for idx, (sz, data) in enumerate(zip(sizes, entries)):
    res += res_entry(3, 100 + idx, data)            # RT_ICON
    group += struct.pack('<BBBBHHIH', sz % 256, sz % 256, 0, 0, 1, 32, len(data), 100 + idx)
res += res_entry(14, 'UNIFARICON', group)           # RT_GROUP_ICON
open(os.path.join(HERE, 'uniFAR_icon.res'), 'wb').write(res)

print('ok')
