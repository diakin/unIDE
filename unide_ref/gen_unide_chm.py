#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Руководство пользователя unIDE в CHM (Help - unIDE manual).

Исходники страниц - unide_ref/html/*.html (UTF-8, только содержимое: от
<h1> до конца). Скрипт оборачивает их в общий шаблон (шапка, навигация
назад / оглавление / вперёд, стиль), переводит в windows-1251 (просмотр
CHM в Windows), строит оглавление по страницам и их <h2>, указатель - по
заголовкам <h1>/<h2>, и собирает unide_ref/help/unide.chm утилитой chmcmd
(Free Pascal).

Запуск:  python3 -I unide_ref/gen_unide_chm.py [<папка unIDE>]
"""

import html
import os
import re
import shutil
import subprocess
import sys

PAGES = [
    'index', 'window', 'editor', 'search', 'projects', 'build', 'rapidq',
    'freebasic', 'delphi', 'arduino', 'debug', 'inspector', 'options',
    'utils', 'files', 'keys', 'help',
]

CSS = """
body { font-family: Tahoma, Verdana, sans-serif; font-size: 10pt;
       margin: 0; padding: 0 16px 24px 16px; color: #202020;
       background: #FFFFFF; }
.hdr { background: #3A2F4F; color: #FFFFFF; padding: 6px 10px;
       margin: 0 -16px 12px -16px; font-size: 9pt; }
.hdr a { color: #FFD27F; text-decoration: none; margin-right: 14px; }
h1 { font-size: 15pt; color: #3A2F4F; margin: 10px 0 10px 0; }
h2 { font-size: 12pt; color: #3A2F4F; margin: 18px 0 6px 0;
     border-bottom: 1px solid #D0C8DC; }
h3 { font-size: 10.5pt; color: #3A2F4F; margin: 12px 0 4px 0; }
code { font-family: Consolas, "Courier New", monospace; font-size: 9.5pt;
       background: #F2EEF6; padding: 0 2px; }
table { border-collapse: collapse; margin: 6px 0 10px 0; }
th, td { border: 1px solid #C8C0D4; padding: 3px 7px; vertical-align: top;
         text-align: left; }
th { background: #ECE6F2; }
li { margin: 2px 0; }
.nav { margin-top: 24px; padding-top: 6px; border-top: 1px solid #D0C8DC;
       font-size: 9pt; }
.nav a { margin-right: 14px; }
"""

TEMPLATE = """<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=windows-1251">
<title>{title}</title>
<link rel="stylesheet" type="text/css" href="unide.css">
</head>
<body>
<div class="hdr"><a href="index.html">Руководство unIDE</a>{prev}{next}</div>
{body}
<div class="nav">{prev2}<a href="index.html">Оглавление</a>{next2}</div>
</body>
</html>
"""

H1_RE = re.compile(r'<h1>(.*?)</h1>', re.S)
H2_RE = re.compile(r'<h2>(?:<a name="([^"]+)"></a>)?(.*?)</h2>', re.S)
TAG_RE = re.compile(r'<[^>]+>')


def plain(text):
    return html.unescape(TAG_RE.sub('', text)).strip()


def attr(text):
    return html.escape(text, quote=True)


def main():
    root = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else \
        os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src_dir = os.path.join(root, 'unide_ref', 'html')
    out_dir = os.path.join(root, 'unide_ref', 'help')
    work = os.path.join(root, 'unide_ref', 'chm_work')
    if os.path.isdir(work):
        shutil.rmtree(work)
    os.makedirs(work)
    os.makedirs(out_dir, exist_ok=True)

    titles = {}
    sections = {}
    bodies = {}
    for name in PAGES:
        with open(os.path.join(src_dir, name + '.html'), encoding='utf-8') as src:
            body = src.read()
        match = H1_RE.search(body)
        titles[name] = plain(match.group(1)) if match else name
        sections[name] = []
        # Заголовки разделов без якоря получают свой: в оглавление и указатель
        counter = [0]

        def anchor(h2):
            if h2.group(1):
                sections[name].append((h2.group(1), plain(h2.group(2))))
                return h2.group(0)
            counter[0] += 1
            key = 's%d' % counter[0]
            sections[name].append((key, plain(h2.group(2))))
            return '<h2><a name="%s"></a>%s</h2>' % (key, h2.group(2))

        bodies[name] = H2_RE.sub(anchor, body)

    for idx, name in enumerate(PAGES):
        prev_link = next_link = prev2 = next2 = ''
        if idx > 0:
            prev_name = PAGES[idx - 1]
            prev_link = '<a href="%s.html">&larr; %s</a>' % (
                prev_name, html.escape(titles[prev_name]))
            prev2 = prev_link
        if idx + 1 < len(PAGES):
            next_name = PAGES[idx + 1]
            next_link = '<a href="%s.html">%s &rarr;</a>' % (
                next_name, html.escape(titles[next_name]))
            next2 = next_link
        page = TEMPLATE.format(title=html.escape(titles[name]), body=bodies[name],
                               prev=prev_link, next=next_link, prev2=prev2,
                               next2=next2)
        with open(os.path.join(work, name + '.html'), 'w', encoding='cp1251',
                  errors='xmlcharrefreplace', newline='\r\n') as dst:
            dst.write(page)
    with open(os.path.join(work, 'unide.css'), 'w', encoding='cp1251',
              newline='\r\n') as dst:
        dst.write(CSS)

    def item(title, local):
        return ('<li><object type="text/sitemap"><param name="Name" value="%s">'
                '<param name="Local" value="%s"></object>\r\n' % (attr(title), local))

    head = ('<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">\r\n<html><head>'
            '<meta http-equiv="Content-Type" content="text/html; '
            'charset=windows-1251"></head><body>\r\n')
    toc = [head, '<ul>\r\n']
    for name in PAGES:
        toc.append(item(titles[name], name + '.html'))
        if sections[name]:
            toc.append('<ul>\r\n')
            for key, title in sections[name]:
                toc.append(item(title, '%s.html#%s' % (name, key)))
            toc.append('</ul>\r\n')
    toc.append('</ul>\r\n</body></html>\r\n')
    with open(os.path.join(work, 'unide.hhc'), 'w', encoding='cp1251',
              errors='replace', newline='') as dst:
        dst.write(''.join(toc))

    entries = []
    for name in PAGES:
        entries.append((titles[name], name + '.html'))
        for key, title in sections[name]:
            entries.append((title + ' (' + titles[name] + ')',
                            '%s.html#%s' % (name, key)))
    entries.sort(key=lambda pair: pair[0].lower())
    with open(os.path.join(work, 'unide.hhk'), 'w', encoding='cp1251',
              errors='replace', newline='') as dst:
        dst.write(head + '<ul>\r\n')
        for title, local in entries:
            dst.write(item(title, local))
        dst.write('</ul>\r\n</body></html>\r\n')

    with open(os.path.join(work, 'unide.hhp'), 'w', encoding='cp1251',
              newline='\r\n') as dst:
        dst.write('[OPTIONS]\n'
                  'Compatibility=1.1 or later\n'
                  'Compiled file=unide.chm\n'
                  'Contents file=unide.hhc\n'
                  'Index file=unide.hhk\n'
                  'Default topic=index.html\n'
                  'Default Window=main\n'
                  'Display compile progress=No\n'
                  'Full-text search=Yes\n'
                  'Language=0x419 Russian\n'
                  'Title=Руководство unIDE\n\n'
                  '[WINDOWS]\n'
                  'main="Руководство unIDE","unide.hhc","unide.hhk",'
                  '"index.html","index.html",,,,,0x63520,,0x387e,,,,,,,,0\n\n'
                  '[FILES]\n' +
                  '\n'.join(name + '.html' for name in PAGES) + '\nunide.css\n')

    proc = subprocess.run(['chmcmd', 'unide.hhp'], cwd=work,
                          capture_output=True, text=True, errors='replace')
    chm = os.path.join(work, 'unide.chm')
    if proc.returncode != 0 or not os.path.isfile(chm):
        print(proc.stdout[-3000:])
        print(proc.stderr[-3000:])
        return 1
    shutil.move(chm, os.path.join(out_dir, 'unide.chm'))
    if not os.environ.get('UNIDE_CHM_KEEP'):
        shutil.rmtree(work)
    print('pages %d, index %d -> %s' % (len(PAGES), len(entries),
                                        os.path.join(out_dir, 'unide.chm')))
    return 0


if __name__ == '__main__':
    sys.exit(main())
