# -*- coding: utf-8 -*-
# unIDE FAR: шрифт панелей в ресурсах exe
#
#   ter-c18b.fnt  - Terminus Bold 10x18, кодовая страница Windows-1251
#                   (Terminus Font 4.49.1, Dimitar Toshkov Zhekov,
#                   SIL Open Font License 1.1 - Terminus-OFL.TXT).
#                   Собран из исходников шрифта инструментами самого
#                   Terminus (bin/ucstoany.py + bin/bdftofnt.py), как в его
#                   win32/Makefile:
#                     ucstoany.py ter-u18b.bdf Microsoft CP1251
#                         uni/cntrl.uni uni/ascii-h.uni uni/x11-1251.uni
#                         uni/win-1251.uni | bdftofnt.py -fModern -o ter-c18b.fnt
#   ..\farfont.res - RCDATA FAR_TER_C18B = ter-c18b.fnt (подключён в UnFar.pas)
#
# Запуск: python make_farfont.py (из папки fonts)

import os
import struct


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
    with open(os.path.join(here, 'ter-c18b.fnt'), 'rb') as fin:
        font_data = fin.read()
    # пустая запись в начале - признак 32-битного .res
    res = struct.pack('<II', 0, 32) + struct.pack('<HHHH', 0xFFFF, 0, 0xFFFF, 0) + b'\0' * 16
    # RT_RCDATA = 10
    res += res_entry(10, 'FAR_TER_C18B', font_data)
    with open(os.path.join(here, '..', 'farfont.res'), 'wb') as fout:
        fout.write(res)


if __name__ == '__main__':
    main()
