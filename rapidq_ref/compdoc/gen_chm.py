"""Build rapidq_ref/help/rapidq.chm from rapidq_ref/html_doc, plus the F1 keyword map.

Usage: python3 -I gen_chm.py <repo dir> [chmcmd]
- table of contents (rapidq.hhc) from contents.html: chapters, Appendix A,
  Appendix B (custom components), Appendix C, nested as in contents.html;
- index (rapidq.hhk) from indexa.html links, "Appendix A: NAME" of component
  pages and the Appendix B pages;
- rapidq_ref/help/keywords.txt: WORD=page.html[#anchor], one per line, for F1
  in unIDE (first target of each index keyword, upper case);
- the CHM is compiled with chmcmd (Free Pascal) in a temporary copy of html_doc.
"""
import html
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from html.parser import HTMLParser

repo = sys.argv[1]
chmcmd = sys.argv[2] if len(sys.argv) > 2 else 'chmcmd'
doc_dir = os.path.join(repo, 'rapidq_ref', 'html_doc')
out_dir = os.path.join(repo, 'rapidq_ref', 'help')
TITLE = 'Rapid-Q Documentation'


def read(name):
    return open(os.path.join(doc_dir, name), 'rb').read().decode('cp1252')


class Node:
    def __init__(self, text='', href=''):
        self.text = text
        self.href = href
        self.children = []


class ContentsParser(HTMLParser):
    """contents.html -> tree. <B> and <LI> start an item under the current
    parent; <UL> makes the last item the parent of the nested list."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Node()
        self.stack = [self.root]
        self.last = None
        self.current = None       # item that collects text
        self.in_list = False
        self.started = False

    def start_item(self):
        node = Node()
        self.stack[-1].children.append(node)
        self.current = node
        self.last = node

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'h1':
            self.started = True
        if not self.started:
            return
        if tag == 'ul':
            self.current = None
            if self.last is not None and self.in_list:
                self.stack.append(self.last)
            self.in_list = True
        elif tag in ('li', 'b'):
            if tag == 'b' and self.current is not None and not self.current.text.strip():
                return            # <LI><B>... - same item
            self.start_item()
        elif tag == 'a' and self.current is not None and attrs.get('href') and not self.current.href:
            self.current.href = attrs['href']

    def handle_endtag(self, tag):
        if not self.started:
            return
        if tag == 'ul':
            self.current = None
            if len(self.stack) > 1:
                self.stack.pop()
        elif tag == 'b':
            self.current = None

    def handle_data(self, data):
        if self.current is not None:
            self.current.text += data


def clean_tree(node):
    out = []
    for child in node.children:
        child.text = re.sub(r'\s+', ' ', child.text).strip(' ,').split(' \u2014 ')[0]
        clean_tree(child)
        if child.text or child.children:
            if not child.text:
                child.text = child.children[0].text
            out.append(child)
    node.children = out


def sitemap_item(text, hrefs):
    params = ['<param name="Name" value="%s">' % html.escape(text, quote=True)]
    for href in hrefs:
        params.append('<param name="Local" value="%s">' % html.escape(href, quote=True))
    return '<LI><OBJECT type="text/sitemap">%s</OBJECT>\n' % ''.join(params)


def write_toc(root, path):
    lines = ['<HTML><HEAD><meta name="GENERATOR" content="unIDE gen_chm.py"></HEAD><BODY>\n',
             '<OBJECT type="text/site properties"><param name="Window Styles" value="0x800025"></OBJECT>\n']

    def emit(node):
        lines.append('<UL>\n')
        for child in node.children:
            lines.append(sitemap_item(child.text, [child.href] if child.href else []))
            if child.children:
                emit(child)
        lines.append('</UL>\n')
    emit(root)
    lines.append('</BODY></HTML>\n')
    open(path, 'wb').write(''.join(lines).encode('cp1252', 'xmlcharrefreplace'))


def collect_index():
    index = {}

    def add(key, href):
        key = re.sub(r'\s+', ' ', key).strip()
        if not key or not href or href.startswith('#') or '../' in href or ':' in href.split('#')[0]:
            return
        if not os.path.exists(os.path.join(doc_dir, href.split('#')[0])):
            return
        targets = index.setdefault(key, [])
        if href not in targets:
            targets.append(href)

    # только строки указателя (clean_index.py), без строки навигации
    text = ''.join(re.findall(r'<p class="rq-ix">.*?</p>', read('indexa.html'), re.S))
    for href, label in re.findall(r'<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', text, re.I | re.S):
        label = html.unescape(re.sub(r'<[^>]+>', '', label)).strip()
        if len(label) > 1 and label.lower() not in ('up',) and not re.fullmatch(r'\[\d+\]', label):
            add(label, href)
    for name in sorted(os.listdir(doc_dir)):
        if not name.endswith('.html'):
            continue
        page = read(name)
        found = re.search(r'Appendix ([AB]):\s*([A-Za-z0-9_]+)', re.sub(r'<[^>]+>', ' ', page))
        if found and found.group(2).upper() not in ('RAPID', 'CUSTOM'):
            add(found.group(2).upper(), name)
    # Appendix D: functions of rapidqAllProc.inc (gen_funcs.py) - after the
    # index entries, so a Rapid-Q keyword keeps its own page for F1
    funcs_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'funcs_index.json')
    if os.path.exists(funcs_path):
        for name, href in sorted(json.load(open(funcs_path, encoding='utf-8')).items()):
            add(name, href)
    return index


def write_index(index, path):
    lines = ['<HTML><HEAD><meta name="GENERATOR" content="unIDE gen_chm.py"></HEAD><BODY>\n<UL>\n']
    for key in sorted(index, key=lambda item: item.upper()):
        lines.append(sitemap_item(key, index[key]))
    lines.append('</UL>\n</BODY></HTML>\n')
    open(path, 'wb').write(''.join(lines).encode('cp1252', 'xmlcharrefreplace'))


def main():
    parser = ContentsParser()
    parser.feed(read('contents.html'))
    root = parser.root
    clean_tree(root)
    # Appendix A heading has no link of its own
    for node in root.children:
        if node.text.startswith('Appendix A') and not node.href:
            node.href = 'contents.html#appa'
        if node.text.startswith('Appendix C') and not node.href:
            node.href = 'contents.html#appc'
    root.children.insert(0, Node('Contents', 'contents.html'))
    root.children.append(Node('Alphabetic index', 'indexa.html'))
    index = collect_index()

    build = tempfile.mkdtemp(prefix='rqchm_')
    try:
        work = os.path.join(build, 'html_doc')
        shutil.copytree(doc_dir, work)
        write_toc(root, os.path.join(work, 'rapidq.hhc'))
        write_index(index, os.path.join(work, 'rapidq.hhk'))
        files = sorted(name for name in os.listdir(work)
                       if os.path.splitext(name)[1].lower() in ('.html', '.htm', '.css', '.gif', '.jpg', '.png'))
        project = ('[OPTIONS]\r\nCompatibility=1.1 or later\r\nCompiled file=rapidq.chm\r\n'
                   'Contents file=rapidq.hhc\r\nIndex file=rapidq.hhk\r\nDefault topic=contents.html\r\n'
                   'Default Window=main\r\nDisplay compile progress=No\r\nFull-text search=Yes\r\n'
                   'Binary Index=No\r\nLanguage=0x409 English (United States)\r\nTitle=%s\r\n\r\n'
                   '[WINDOWS]\r\nmain="%s","rapidq.hhc","rapidq.hhk","contents.html","contents.html",,,,,'
                   '0x63520,220,0x10384e,[40,40,1240,900],,,,,,,0\r\n\r\n'
                   '[FILES]\r\n%s\r\n' % (TITLE, TITLE, '\r\n'.join(files)))
        open(os.path.join(work, 'rapidq.hhp'), 'w', newline='').write(project)
        result = subprocess.run([chmcmd, '--no-html-scan', 'rapidq.hhp'], cwd=work,
                                capture_output=True, text=True)
        if result.returncode != 0 or not os.path.exists(os.path.join(work, 'rapidq.chm')):
            sys.exit('chmcmd failed:\n' + result.stdout + result.stderr)
        os.makedirs(out_dir, exist_ok=True)
        shutil.copyfile(os.path.join(work, 'rapidq.chm'), os.path.join(out_dir, 'rapidq.chm'))
    finally:
        shutil.rmtree(build, ignore_errors=True)

    keywords = {}
    for key, targets in index.items():
        upper = key.upper()
        if re.fullmatch(r'[A-Z_$][A-Z0-9_$%&!#?]*', upper) and upper not in keywords:
            keywords[upper] = targets[0]
    lines = ['; F1 in unIDE: word = topic in rapidq.chm (gen_chm.py, do not edit)']
    lines += ['%s=%s' % (key, keywords[key]) for key in sorted(keywords)]
    open(os.path.join(out_dir, 'keywords.txt'), 'w', newline='\r\n').write('\n'.join(lines) + '\n')

    def count(node):
        return sum(1 + count(child) for child in node.children)
    print('toc items', count(root), 'index keywords', len(index), 'F1 words', len(keywords),
          'chm', os.path.getsize(os.path.join(out_dir, 'rapidq.chm')))


main()
