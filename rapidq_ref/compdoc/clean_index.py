"""Rewrite html_doc/indexa.html (Alphabetic Index) in one plain format.

Usage: python3 -I clean_index.py <repo dir>
The original index (FrontPage, Stanescu Serban 2001) mixes fonts, sizes,
colours and highlight backgrounds from entry to entry, and its links open
in a frame "doc" that does not exist outside the old framed help. Here the
entries are read out of it - letter sections, link, text after the link -
and written again as one list: "NAME - description" per line. Links to
pages that are not in html_doc (../tasklist.htm, ../faq/...) become plain
text. Run after normalize.py and gen_pages.py (which points ../custom/
links at the Appendix B pages); running it again gives the same file.
"""
import html
import os
import re
import sys
from html.parser import HTMLParser

repo = sys.argv[1]
doc_dir = os.path.join(repo, 'rapidq_ref', 'html_doc')
path = os.path.join(doc_dir, 'indexa.html')
MARK = '<!-- rq-index-clean -->'


class IndexParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.sections = []          # [letter, [entries]]
        self.entry = None           # {'name', 'href', 'text'}
        self.link = None            # open <a href>
        self.started = False
        self.stopped = False

    def close_entry(self):
        if self.entry is not None and self.sections:
            self.entry['text'] = re.sub(r'\s+', ' ', self.entry['text']).strip(' -– ')
            if self.entry['name']:
                self.sections[-1][1].append(self.entry)
        self.entry = None

    def handle_starttag(self, tag, attrs):
        if self.stopped:
            return
        attrs = dict(attrs)
        if tag == 'a' and attrs.get('name') and re.fullmatch(r'[a-zA-Z]', attrs['name']):
            self.close_entry()
            self.started = True
            self.sections.append([attrs['name'].upper(), []])
            return
        if not self.started:
            return
        if tag == 'br':
            self.close_entry()
        elif tag == 'a' and attrs.get('href'):
            href = attrs['href']
            if href.startswith('#'):
                self.link = {'skip': True, 'text': ''}
                return
            self.close_entry()
            self.link = {'skip': False, 'href': href, 'text': ''}

    def handle_endtag(self, tag):
        if tag == 'a' and self.link is not None:
            link = self.link
            self.link = None
            if not link['skip']:
                self.entry = {'name': re.sub(r'\s+', ' ', link['text']).strip(),
                              'href': link['href'], 'text': ''}

    def handle_data(self, data):
        if not self.started or self.stopped:
            return
        if 'Rapid-Q Index' in data:
            self.close_entry()
            self.stopped = True
            return
        if self.link is not None:
            self.link['text'] += data
            return
        if self.entry is not None:
            self.entry['text'] += data
            return
        text = re.sub(r'\s+', ' ', data).strip('  ')
        # одиночная буква - подзаголовок (P<a name="p">, жёлтые A, B... в Q)
        if text and not re.fullmatch(r'[A-Za-z]', text) and self.sections:
            self.entry = {'name': text, 'href': '', 'text': ''}


def main():
    text = open(path, 'rb').read().decode('cp1252')
    if MARK in text:
        print('already clean')
        return
    head_end = text.index('<body')
    head_end = text.index('>', head_end) + 1
    head = text[:head_end]
    bar = re.search(r'<div class="rq-head">.*?</div>\s*<div class="rq-nav">.*?</div>', text, re.S)
    parser = IndexParser()
    parser.feed(text[bar.end():] if bar else text[head_end:])
    parser.close_entry()

    out = [head, '\n', MARK, '\n', bar.group(0) if bar else '', '\n',
           '<a name="sus"></a>\n<h1>Alphabetic Index</h1>\n<p class="rq-letters">']
    letters = [letter for letter, entries in parser.sections]
    out.append(' '.join('<a href="#%s">%s</a>' % (letter.lower(), letter) for letter in letters))
    out.append('</p>\n')
    count = 0
    for letter, entries in parser.sections:
        out.append('<h2><a name="%s"></a>%s</h2>\n' % (letter.lower(), letter))
        for entry in entries:
            href = entry['href']
            local = href and '../' not in href and ':' not in href.split('#')[0] and \
                os.path.exists(os.path.join(doc_dir, href.split('#')[0]))
            name = html.escape(entry['name'])
            if local:
                item = '<a href="%s">%s</a>' % (html.escape(href, quote=True), name)
            elif href:
                item = '<span class="rq-missing">%s</span>' % name
            else:
                item = '<span class="rq-text">%s</span>' % name
            desc = html.escape(entry['text'])
            out.append('<p class="rq-ix">%s%s</p>\n' % (item, (' &ndash; ' + desc) if desc else ''))
            count += 1
        out.append('<p class="rq-up"><a href="#sus">Up</a></p>\n')
    out.append('<p class="rq-meta">Rapid-Q Index &copy; Stanescu Serban, 2001. Names in grey refer to '
               'pages that are not part of this collection.</p>\n</body>\n</html>\n')
    data = ''.join(out).replace('\r\n', '\n').replace('\n', '\r\n')
    open(path, 'wb').write(data.encode('cp1252', 'xmlcharrefreplace'))
    print('sections', len(letters), 'entries', count)


main()
