"""Bring rapidq_ref/html_doc pages to one look without changing their text.

Usage: python3 -I normalize.py <html_doc dir>
For every page except the generated ones (c_*.html, custom.html):
- head: <title> kept, charset meta and rq.css link added, old <style>/<base>/
  doctype/meta dropped;
- <body ...> -> <body class="rqdoc"> (bgcolor, font and margin attributes dropped);
- the Rapid-Q header table ("Rapid-Q Documentation by ...") becomes the
  header bar <div class="rq-head">, keeping both texts (gen_members.py in
  RqLcl/tofb reads "Appendix A: NAME" from it); pages without that table get
  a header bar with the page title;
- a navigation bar follows the header.
The rest of the page is left as it is. Running it again does nothing new.
"""
import os
import re
import sys

doc_dir = sys.argv[1]
NAV = ('<div class="rq-nav"><a href="contents.html">Contents</a>'
       '<a href="contents.html#appa">Components (A)</a>'
       '<a href="custom.html">Custom components (B)</a>'
       '<a href="contents.html#appc">Keywords (C)</a>'
       '<a href="indexa.html">Alphabetic index</a></div>')
MARK = '<!-- rq-normalized -->'

HEAD_TABLE_RE = re.compile(r'<TABLE[^>]*>(.*?)</TABLE>', re.I | re.S)
FIRST_ROW_RE = re.compile(
    r'<TR[^>]*>\s*<TD[^>]*>(.*?)</TD>\s*<TD[^>]*ALIGN\s*=\s*"?RIGHT"?[^>]*>(.*?)</TD>', re.I | re.S)


def inner_text(fragment):
    return re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', ' ', fragment)).strip()


def normalize(text, name):
    if MARK in text:
        return None
    title_match = re.search(r'<TITLE>(.*?)</TITLE>', text, re.I | re.S)
    title = title_match.group(1).strip() if title_match else os.path.splitext(name)[0]
    body_match = re.search(r'<BODY\b[^>]*>', text, re.I)
    if not body_match:
        raise ValueError('no <body> in ' + name)
    rest = text[body_match.end():]
    # DOCTYPE и X-UA-Compatible: окно CHM (движок IE) без них показывает
    # страницу в режиме IE7/quirks - без селекторов атрибутов и inherit в CSS,
    # шрифт в таблицах не наследуется
    head = ('<!DOCTYPE html>\n<html>\n<head>\n'
            '<meta http-equiv="X-UA-Compatible" content="IE=edge">\n' + MARK + '\n'
            '<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">\n'
            '<title>' + title + '</title>\n'
            '<link rel="stylesheet" type="text/css" href="rq.css">\n'
            '</head>\n<body class="%s">\n' % ('rqdoc rq-index' if name == 'indexa.html' else 'rqdoc'))
    head_table = HEAD_TABLE_RE.search(rest[:3000])
    first_row = FIRST_ROW_RE.search(head_table.group(1)) if head_table else None
    if first_row and 'Rapid-Q' in inner_text(first_row.group(1)) + inner_text(first_row.group(2)):
        # the whole header table (with its HR row, if any) becomes the bar
        bar = ('<div class="rq-head"><span class="rq-brand">' + first_row.group(1).strip() +
               '</span><span class="rq-section">' + first_row.group(2).strip() + '</span></div>\n')
        rest = rest[:head_table.start()] + bar + NAV + '\n' + rest[head_table.end():]
    else:
        bar = ('<div class="rq-head"><span class="rq-brand">Rapid-Q Documentation</span>'
               '<span class="rq-section">' + inner_text(title) + '</span></div>\n')
        rest = bar + NAV + '\n' + rest
    # TARGET="doc" - кадр старой справки с фреймами; в окне CHM и в
    # браузере такой ссылке открыться негде
    rest = re.sub(r'\s+target\s*=\s*"doc"', '', rest, flags=re.I)
    return head + rest


def main():
    changed = 0
    for name in sorted(os.listdir(doc_dir)):
        if not name.lower().endswith('.html') or name.startswith('c_') or name == 'custom.html':
            continue
        path = os.path.join(doc_dir, name)
        raw = open(path, 'rb').read()
        text = raw.decode('cp1252', errors='strict') if all(b < 0x80 for b in raw) else raw.decode('cp1252')
        crlf = b'\r\n' in raw
        new = normalize(text.replace('\r\n', '\n'), name)
        if new is None:
            continue
        if crlf:
            new = new.replace('\n', '\r\n')
        open(path, 'wb').write(new.encode('cp1252'))
        changed += 1
    print('normalized', changed)


main()
