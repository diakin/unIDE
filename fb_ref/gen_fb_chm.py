#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Руководство FreeBASIC в CHM для unIDE (Help - FreeBASIC, F1).

Источник - страницы вики FreeBASIC в разметке Wakka из исходников fbc:
<fbc>/doc/manual/cache/*.wakka, оформление - <fbc>/doc/manual/html
(style.css, images) и шаблоны <fbc>/doc/manual/templates/default.
Перевод разметки в HTML повторяет libfbdoc (CWiki.bas, CWakka2Html.bas,
CWiki2Chm.bas, fbdoc_buildtoc.bas) - тот же вид страниц, что у
официального FB-manual-*.chm.

Результат:
  fb_ref/help/freebasic.chm   - справка (собирается chmcmd из Free Pascal);
  fb_ref/help/fbkeywords.txt  - СЛОВО=страница.html для F1 (из
                                 CatPgFullIndex - алфавитного списка).

Запуск:
  python3 -I fb_ref/gen_fb_chm.py <папка fbc> [<папка unIDE>]
"""

import html
import os
import re
import shutil
import subprocess
import sys

# ---------------------------------------------------------------------------
#  Разбор разметки (CWiki.bas)
# ---------------------------------------------------------------------------

WIKI_PATTERN = re.compile(
    r'%%.*?%%|'
    r'"".*?""|'
    r'\[\[[^\[]*?\]\]|'
    r'-{4,}|---|'
    r'\b[a-z]+://\S+|'
    r"\*\*|''|##|#%|@@|::c::|>>|<<|\+\+|__|<|>|//|"
    r'======|=====|====|===|==|'
    r'^[\t|~]+(?:-|&|[0-9a-zA-Z]+\))?|'
    r'\{\{.*?\}\}|'
    r'\n|\r\n',
    re.MULTILINE | re.DOTALL)

CODE_RE = re.compile(r'^%%(.*?)%%$', re.DOTALL)
RAW_RE = re.compile(r'^""(.*?)""$', re.DOTALL)
LINK_RE = re.compile(r'^\[\[([^|]+)(?:\|(.+))?\]\]$', re.DOTALL)
ACTION_RE = re.compile(r'^\{\{(.*?)\}\}$', re.DOTALL)
ACTION2_RE = re.compile(r'([a-zA-Z0-9_]+)([\t ]+(.*?$))?', re.DOTALL)
INDENT_RE = re.compile(r'^([\t|~]+)((-|&|[0-9a-zA-Z]+\))?)', re.DOTALL)
PARAM_RE = re.compile(r'([a-zA-Z]+)[ \t]*=[ \t]*"(.*?)"', re.DOTALL)

SIMPLE = {
    '<': 'LT', '>': 'GT', '<<': 'BOXLEFT', '>>': 'BOXRIGHT',
    '::c::': 'CLEAR', '#%': 'KBD', '==': 'BOLD_SECTION', '**': 'BOLD',
    '//': 'ITALIC', '__': 'UNDERLINE', '##': 'MONOSPACE', "''": 'NOTES',
    '++': 'STRIKE', '@@': 'CENTER', '---': 'FORCENL', '----': 'HORZLINE',
    '\n': 'NEWLINE', '\r\n': 'NEWLINE',
}


class Token:
    __slots__ = ('kind', 'text', 'url', 'name', 'params', 'level', 'lang')

    def __init__(self, kind, text=''):
        self.kind = kind
        self.text = text
        self.url = ''
        self.name = ''
        self.params = {}
        self.level = 0
        self.lang = ''

    def param(self, key, default=''):
        return self.params.get(key.lower(), default)


def make_token(text):
    if text in SIMPLE:
        return Token(SIMPLE[text])
    if text in ('===', '====', '=====', '======'):
        tok = Token('HEADER')
        tok.level = len(text)
        return tok
    match = CODE_RE.match(text)
    if match:
        body = match.group(1)
        for lang in ('qbasic', 'freebasic', 'c'):
            prefix = '(' + lang + ')'
            if body.startswith(prefix):
                tok = Token('CODE', body[len(prefix):])
                tok.lang = lang
                return tok
        return Token('PRE', body)
    match = RAW_RE.match(text)
    if match:
        return Token('RAW', match.group(1))
    match = LINK_RE.match(text)
    if match:
        tok = Token('LINK', (match.group(2) or '').strip())
        tok.url = match.group(1)
        return tok
    match = ACTION_RE.match(text)
    if match:
        tok = Token('ACTION')
        inner = match.group(0)
        sub = ACTION2_RE.search(inner)
        if sub:
            tok.name = sub.group(1)
            for pmatch in PARAM_RE.finditer(sub.group(2) or ''):
                key = pmatch.group(1).lower()
                if key not in tok.params:
                    tok.params[key] = pmatch.group(2)
        else:
            tok.name = inner
        return tok
    match = INDENT_RE.match(text)
    if match:
        lead = match.group(1)
        tok = Token('INDENT' if (lead[0] == '~' or match.group(2) == '')
                    else 'LIST')
        tok.level = len(lead)
        return tok
    return Token('TEXT', text)


def tokenize(body):
    tokens = []
    pos = 0
    for match in WIKI_PATTERN.finditer(body):
        if match.start() > pos:
            chunk = body[pos:match.start()]
            if chunk != '\r\n':
                tokens.append(Token('TEXT', chunk))
        tokens.append(make_token(match.group(0)))
        pos = match.end()
    if pos < len(body):
        tokens.append(Token('TEXT', body[pos:]))
    return tokens


def page_title(tokens):
    for tok in tokens:
        if tok.kind == 'ACTION' and tok.name.lower() == 'fbdoc' and \
           tok.param('item').lower() == 'title':
            return tok.param('value')
    return ''


# ---------------------------------------------------------------------------
#  Ключевые слова (fbdoc_keywords.bas)
# ---------------------------------------------------------------------------

KEYWORDS = {}


def load_keywords(path):
    with open(path, encoding='latin-1') as src:
        for line in src:
            word = line.strip()
            if word:
                KEYWORDS[word.upper()] = word


def find_keyword(text):
    if not text:
        return ''
    suffix = ''
    word = text
    if word[-1] in '$%&!#':
        suffix = word[-1]
        word = word[:-1]
    found = KEYWORDS.get(word.upper())
    if found is None:
        found = KEYWORDS.get(text.upper())
        if found is None:
            return ''
        return found
    return found + suffix


def format_page_title(text):
    found = find_keyword(text)
    if found:
        return found
    out = []
    cap = True
    for char in text:
        if 'a' <= char <= 'z':
            out.append(char.upper() if cap else char)
            cap = False
        elif 'A' <= char <= 'Z':
            out.append(char if cap else char.lower())
            cap = False
        else:
            out.append(char)
            cap = True
    return ''.join(out)


def text2html(text, brk=False, spaces=False):
    out = []
    last_cr = False
    for char in text:
        if char in ' \t':
            out.append('&nbsp;' if spaces else char)
        elif char == '\r':
            out.append('<br />' if brk else char)
        elif char == '\n':
            if brk and not last_cr:
                out.append('<br />')
            out.append(char)
        elif char == '&':
            out.append('&amp;')
        elif char == '"':
            out.append('&quot;')
        elif char == '<':
            out.append('&lt;')
        elif char == '>':
            out.append('&gt;')
        else:
            out.append(char)
        last_cr = char == '\r'
    return ''.join(out)


# ---------------------------------------------------------------------------
#  Подсветка примеров (CFbCode.bas, упрощённо): комментарии, строки, числа,
#  ключевые слова, имена, прочее
# ---------------------------------------------------------------------------

CODE_TOKEN_RE = re.compile(
    r"(?P<com>/'.*?'/|'[^\n]*|\bREM\b[^\n]*)|"
    r'(?P<quo>!?"(?:[^"\n]|"")*"?)|'
    r'(?P<num>&[HhOoBb][0-9A-Fa-f]+|\d+\.?\d*(?:[eEdD][+-]?\d+)?|\.\d+)|'
    r'(?P<name>#?[A-Za-z_][A-Za-z0-9_]*[$%&!#]?)|'
    r'(?P<nl>\r?\n)|'
    r'(?P<sp>[ \t]+)|'
    r'(?P<oth>.)', re.DOTALL | re.IGNORECASE)


def code_to_html(code):
    parts = []
    have_code = False
    last_class = ''
    for match in CODE_TOKEN_RE.finditer(code):
        kind = match.lastgroup
        text = match.group(0)
        if kind == 'name':
            css = 'key' if find_keyword(text) else 'wrd'
        elif kind in ('sp', 'nl'):
            css = ''
        else:
            css = kind
        if css != last_class:
            if last_class:
                parts.append('</span>')
            if css:
                parts.append('<span class="%s">' % css)
        if kind == 'sp':
            parts.append(text2html(text.replace('\t', '    '), False, True))
        elif kind == 'nl':
            if not have_code:
                parts = []
            else:
                parts.append('<br />\n')
        else:
            have_code = True
            if kind == 'com' and '\n' in text:
                lines = text.split('\n')
                parts.append('<br />\n'.join(text2html(line, False, True)
                                             for line in lines))
            else:
                parts.append(text2html(text, False, True))
        last_class = css
    if last_class:
        parts.append('</span>')
    return '<tt><div class="freebasic">\n' + ''.join(parts) + \
           '</div></tt><br />\n'


# ---------------------------------------------------------------------------
#  Страница в HTML (CWakka2Html.bas)
# ---------------------------------------------------------------------------

SECT_NAMES = {
    'category': 'Category', 'keyword': 'Keyword', 'title': 'Title',
    'syntax': 'Syntax', 'usage': 'Usage', 'param': 'Parameters',
    'ret': 'Return Value', 'desc': 'Description', 'ex': 'Example',
    'ver': 'Version', 'lang': 'Dialect Differences',
    'target': 'Platform Differences', 'diff': 'Differences from QB',
    'see': 'See also', 'back': 'Back', 'close': '',
}
BLOCK_ITEMS = {'syntax', 'usage', 'param', 'ret', 'desc', 'ex', 'ver',
               'lang', 'target', 'diff', 'see'}

TRIM_RE = re.compile(r'^\s*(<br />)+|(<br />)+\s*$')


def explode_link(value):
    if '|' in value:
        page, name = value.split('|', 1)
        return page, name
    return value, ''


class Converter:
    def __init__(self, out_dir):
        self.out_dir = out_dir
        self.indent_base = 0

    def reset(self):
        self.flags = {}
        self.nlcnt = 0
        self.skipnl = True
        self.indent = 0
        self.newindent = 0
        self.level = 0
        self.newlevel = 0

    def flag(self, name, delta=0):
        self.flags[name] = self.flags.get(name, 0) + delta
        return self.flags[name]

    def toggle(self, name, open_tag, close_tag):
        return open_tag if self.flag(name, 1) & 1 else close_tag

    def close_tags(self, text):
        for name, tag in (('BOLD', '</b>'), ('ITALIC', '</i>'),
                          ('UNDERLINE', '</u>'), ('MONOSPACE', '</tt>'),
                          ('NOTES', '</span>'), ('STRIKE', '</strike>'),
                          ('KEYS', '</kbd>'), ('CENTER', '</div>'),
                          ('HEADER', '</div>')):
            if self.flag(name) & 1:
                self.flag(name, -1)
                text += tag
        while self.level > 0:
            self.level -= 1
            text += '</ul>'
        while self.indent > 0:
            self.indent -= 1
            text += '</div>'
        if self.flag('BOXLEFT') & 1:
            self.flag('BOXLEFT', -1)
            text += '</td>'
            if (self.flag('BOXRIGHT') & 1) == 0:
                text += '</tr></table>'
        if self.flag('BOXRIGHT') & 1:
            self.flag('BOXRIGHT', -1)
            text += '</td></tr></table>'
        if self.flags.get('SECTION', 0):
            self.flags['SECTION'] = 0
            text += '</div>'
        return TRIM_RE.sub('', text)

    def close_list(self):
        text = ''
        while self.level > 0:
            self.level -= 1
            text += '</ul>'
        return text

    def link_href(self, page):
        return page + ('' if ':' in page else '.html')

    def action_fbdoc(self, tok):
        item = tok.param('item').lower()
        value = tok.param('value')
        res = ''
        if item in BLOCK_ITEMS:
            res = self.close_tags(res)
            self.flags['SECTION'] = 1
        if item == 'title':
            return res          # заголовок - в шапке страницы (шаблон)
        if item == 'section':
            if self.indent_base == 1:
                res = self.close_tags(res)
                self.flags['SECTION'] = 1
                return res + '<div class="fb_sect_title">' + value + \
                    '</div><div class="fb_sect_cont">'
            return res + '<b><u>' + value + '</u></b>'
        if item == 'subsect':
            if self.indent_base == 1:
                return res + '<div class="fb_sect_title">' + value + '</div>'
            return res + '<b>' + value + '</b>'
        if item == 'category':
            page, name = explode_link(value)
            return res + '<a name="' + page + '"></a><b>' + \
                text2html(name) + '</b>'
        if item == 'keyword':
            page, name = explode_link(value)
            if page.lower().startswith('keypg'):
                name = format_page_title(name)
            return res + '<a href="' + self.link_href(page) + '">' + \
                text2html(name) + '</a>'
        if item in ('back', 'filename', 'tag'):
            return res
        if item == 'close':
            if self.flags.get('SECTION', 0):
                self.flags['SECTION'] = 0
                return '</div>'
            return ''
        return res + '<div class="fb_sect_title">' + \
            SECT_NAMES.get(item, value) + '</div><div class="fb_sect_cont">'

    def action_table(self, tok):
        res = self.close_list()
        cells = html.unescape(tok.param('cells')).split(';')
        cols = int(tok.param('columns') or '1')
        res += '<div class="fb_table"><table>'
        col = 1
        for cell in cells:
            if col == 1:
                res += '<tr>'
            res += '<td>&nbsp;</td>' if cell == '###' else \
                '<td>' + text2html(cell) + '</td>'
            col += 1
            if col > cols:
                col = 1
                res += '</tr>'
        if cols > 1 and col != 1:
            while col <= cols:
                res += '<td>&nbsp;</td>'
                col += 1
            res += '</tr>'
        return res + '</table></div>'

    def action_image(self, tok):
        url = 'images/' + os.path.basename(tok.param('url'))
        if not os.path.isfile(os.path.join(self.out_dir, url)):
            return ''
        res = '<div class="fb_img"><img'
        alt = tok.param('alt')
        if alt:
            res += ' alt="' + alt + '"'
        return res + ' src="' + url + '" /></div>'

    def action_anchor(self, tok):
        name = tok.param('name')
        if '|' not in name:
            return self.close_list() + '<a name="' + name + '"></a>'
        target, label = explode_link(name)
        return '<a href="#' + target + '">' + text2html(label) + '</a>'

    def action(self, tok):
        name = tok.name.lower()
        if name == 'fbdoc':
            return self.action_fbdoc(tok)
        if name == 'table':
            return self.action_table(tok)
        if name == 'image':
            return self.action_image(tok)
        if name == 'anchor':
            return self.action_anchor(tok)
        if name in ('color', 'colour'):
            color = tok.param('c')
            text = text2html(tok.param('text'))
            return '<span style="color: %s">%s</span>' % (color, text) \
                if color else text
        return ''

    def token(self, tok):
        res = ''
        kind = tok.kind
        if kind == 'NEWLINE':
            self.nlcnt += 1
            if not self.skipnl:
                res += '<br \\>\n'
            self.skipnl = False
            self.newlevel = 0
            self.newindent = 0
            return res
        if kind == 'INDENT':
            self.newindent = max(tok.level - self.indent_base, 0)
            self.newlevel = 0
            self.skipnl = self.newindent != self.indent
            return res
        if kind == 'LIST':
            self.newindent = 0
            self.newlevel = max(tok.level, 0)

        while self.level > self.newlevel:
            self.level -= 1
            res += '</ul>'
        while self.indent > self.newindent:
            self.indent -= 1
            res += '</div>'
        while self.level < self.newlevel:
            self.level += 1
            res += '<ul>'
        while self.indent < self.newindent:
            self.indent += 1
            res += '<div class="fb_indent">'
        self.nlcnt = 0
        self.skipnl = False

        if kind == 'LT':
            return res + '&lt;'
        if kind == 'GT':
            return res + '&gt;'
        if kind == 'KBD':
            return res + self.toggle('KEYS', '<kbd >', '</kbd>')
        if kind in ('BOLD', 'BOLD_SECTION'):
            return res + self.toggle('BOLD', '<b>', '</b>')
        if kind == 'ITALIC':
            return res + self.toggle('ITALIC', '<i>', '</i>')
        if kind == 'UNDERLINE':
            return res + self.toggle('UNDERLINE', '<u>', '</u>')
        if kind == 'MONOSPACE':
            return res + self.toggle('MONOSPACE', '<tt>', '</tt>')
        if kind == 'NOTES':
            return res + self.toggle('NOTES', '<span >', '</span>')
        if kind == 'STRIKE':
            return res + self.toggle('STRIKE', '<strike>', '</strike>')
        if kind == 'CENTER':
            return res + self.toggle(
                'CENTER', '<div style="text-align: center;">', '</div>')
        if kind == 'LINK':
            if not tok.text:
                return res + tok.url
            label = tok.text
            if tok.url.lower().startswith('keypg'):
                label = format_page_title(label)
            return res + '<a href="' + self.link_href(tok.url) + '">' + \
                text2html(label) + '</a>'
        if kind == 'LIST':
            return res + '<li>'
        if kind in ('TEXT', 'RAW'):
            if (self.flag('BOLD') & 1) and (self.flag('MONOSPACE') & 1):
                found = find_keyword(tok.text)
                if found:
                    return res + found
            return res + tok.text
        if kind == 'ACTION':
            return res + self.action(tok)

        res += self.close_list()
        self.skipnl = True
        if kind == 'FORCENL':
            return res + '<br />'
        if kind == 'HORZLINE':
            return res         # как в CHM: черта не выводится
        if kind == 'BOXLEFT':
            if self.flag('BOXLEFT', 1) & 1:
                return res + '<table class="fb_box"><tr><td>'
            return res + '</td>'
        if kind == 'BOXRIGHT':
            if self.flag('BOXLEFT') & 1:
                return res + '</td></tr></table>'
            if self.flag('BOXRIGHT', 1) & 1:
                return res + '<td>'
            return res + '</td></tr></table>'
        if kind == 'CLEAR':
            return res + '<div style="clear:both">&nbsp;</div>'
        if kind == 'HEADER':
            self.skipnl = False
            if self.flag('HEADER', 1) & 1:
                return res + '<div class="fb_header">'
            return res + '</div>'
        if kind == 'PRE':
            return res + '<pre class="fb_pre">' + tok.text + '</pre>'
        if kind == 'CODE':
            return res + code_to_html(tok.text)
        return res

    def page(self, name, tokens):
        low = name.lower()
        self.indent_base = 1 if low.startswith(('keypg', 'propg')) else 0
        self.reset()
        text = ''.join(self.token(tok) for tok in tokens)
        return self.close_tags(text)


# ---------------------------------------------------------------------------
#  Оглавление и указатель (fbdoc_buildtoc.bas, CWiki2Chm.bas)
# ---------------------------------------------------------------------------

def doc_toc_links(tokens, bold_links):
    links = []          # (класс, текст, страница, уровень)
    level = 0
    idx = 0
    while idx < len(tokens):
        tok = tokens[idx]
        if tok.kind == 'LINK':
            links.append(('default', tok.text, tok.url, level))
        elif tok.kind == 'ACTION' and tok.name.lower() == 'fbdoc':
            item = tok.param('item').lower()
            value = tok.param('value')
            if item == 'section':
                links.append(('section', value, '', 0))
                level = 1
            elif item == 'subsect':
                links.append(('subsect', value, '', 1))
                level = 2
            elif item == 'keyword':
                page, title = explode_link(value)
                links.append(('keyword', title, page, level))
        elif bold_links and tok.kind == 'BOLD_SECTION' and \
                idx + 1 < len(tokens):
            idx += 1
            links.append(('section', tokens[idx].text, '', 0))
            level = 1
            idx += 1
        idx += 1
    return links


def is_toc_page(name):
    low = name.lower()
    return low == 'doctoc' or low.startswith(('catpg', 'cvs', 'svn')) or \
        low == 'extlibtoc'


def is_internal(url):
    return bool(url) and ':' not in url and '/' not in url


def build_toc(pages, start, toc, index, level, visited):
    if start not in pages or not is_toc_page(start) or start in visited:
        return
    visited.add(start)
    tokens = pages[start]
    for kind, text, url, link_level in doc_toc_links(
            tokens, start.lower() == 'catpgfunctindex'):
        add_page = add_link = follow = False
        if kind in ('section', 'subsect'):
            add_page = True
        elif kind == 'keyword' and is_internal(url):
            add_page = add_link = True
            follow = is_toc_page(url)
        elif kind == 'default' and is_internal(url):
            add_link = True
        if add_link:
            index.append((text, url))
        if add_page:
            toc.append((level + link_level, text, url))
            if follow and url in pages:
                build_toc(pages, url, toc, index, level + link_level + 1,
                          visited)


def sitemap_item(title, page):
    res = '<li><object type="text/sitemap"><param name="Name" value="' + \
        text2html(title) + '">'
    if page:
        res += '<param name="Local" value="' + page + '.html">'
    return res + '</object>\r\n'


def emit_toc(toc):
    body = []
    level = 0
    for item_level, title, page in toc:
        while level < item_level:
            body.append('<ul>\r\n')
            level += 1
        while level > item_level:
            level -= 1
            body.append('</ul>\r\n')
        if level == 0:
            body.append('<ul>\r\n')
        body.append(sitemap_item(title, page))
        if level == 0:
            body.append('</ul>\r\n')
    while level > 0:
        level -= 1
        body.append('</ul>\r\n')
    return ''.join(body)


# ---------------------------------------------------------------------------
#  F1: слова алфавитного списка CatPgFullIndex
# ---------------------------------------------------------------------------

def keyword_map(pages):
    result = {}
    tokens = pages.get('CatPgFullIndex', [])
    for tok in tokens:
        if tok.kind != 'ACTION' or tok.name.lower() != 'fbdoc' or \
           tok.param('item').lower() != 'keyword':
            continue
        page, title = explode_link(tok.param('value'))
        if not page.lower().startswith('keypg'):
            continue
        # "PRINT", "Open Com", "... (Ellipsis)", "Operator + (Add)"
        title = re.sub(r'\s*\(.*?\)\s*$', '', title).strip()
        for word in re.split(r'\s*,\s*', title):
            word = word.strip()
            if word:
                result.setdefault(word.upper(), page + '.html')
                first = word.split(' ')[0]
                if first.upper() not in ('OPERATOR',):
                    result.setdefault(first.upper(), page + '.html')
    return result


# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    fbc_dir = os.path.abspath(sys.argv[1])
    unide_dir = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else \
        os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    manual = os.path.join(fbc_dir, 'doc', 'manual')
    cache = os.path.join(manual, 'cache')
    templates = os.path.join(manual, 'templates', 'default')
    work = os.path.join(unide_dir, 'fb_ref', 'chm_work')
    out_dir = os.path.join(unide_dir, 'fb_ref', 'help')

    load_keywords(os.path.join(templates, 'keywords.lst'))
    with open(os.path.join(templates, 'code', 'chm_def.tpl.html'),
              encoding='utf-8') as src:
        page_tpl = src.read()

    if os.path.isdir(work):
        shutil.rmtree(work)
    os.makedirs(work)
    os.makedirs(out_dir, exist_ok=True)
    shutil.copy(os.path.join(manual, 'html', 'style.css'), work)
    shutil.copytree(os.path.join(manual, 'html', 'images'),
                    os.path.join(work, 'images'))

    pages = {}
    for file_name in sorted(os.listdir(cache)):
        if not file_name.endswith('.wakka'):
            continue
        with open(os.path.join(cache, file_name), 'rb') as src:
            body = src.read().decode('utf-8', errors='replace')
        pages[file_name[:-6]] = tokenize(body.replace('\r\n', '\n'))

    conv = Converter(work)
    written = []
    for name, tokens in pages.items():
        title = page_title(tokens) or name
        if name.lower().startswith('keypg'):
            title = format_page_title(title)
        body = conv.page(name, tokens)
        if not body.strip():
            continue
        text = page_tpl.replace('{$pg_body}', body)
        text = text.replace('{$pg_title}', text2html(title))
        text = text.replace('{#fb_sect_back}', 'Back')
        with open(os.path.join(work, name + '.html'), 'w',
                  encoding='utf-8', newline='\r\n') as dst:
            dst.write(text)
        written.append(name + '.html')

    toc = [(0, 'Table of Contents', 'DocToc')]
    index = []
    build_toc(pages, 'DocToc', toc, index, 1, set())

    with open(os.path.join(work, 'fbdoc.hhc'), 'w', encoding='utf-8',
              newline='') as dst:
        dst.write('<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">\r\n'
                  '<html><head><meta charset="UTF-8"></head><body>\r\n'
                  '<object type="text/site properties">\r\n'
                  '<param name="Window Styles" value="0x800025">\r\n'
                  '<param name="ImageType" value="Folder">\r\n'
                  '</object>\r\n' + emit_toc(toc) + '</body></html>\r\n')

    # Указатель: ссылки оглавлений и слова алфавитного списка (F1 ищет по
    # ним через HH_KEYWORD_LOOKUP)
    keys = keyword_map(pages)
    entries = {}
    for title, page in index:
        if title and page in pages:
            label = format_page_title(title) if \
                page.lower().startswith('keypg') else title
            entries.setdefault(label, page)
    for word, page_file in keys.items():
        entries.setdefault(word, page_file[:-5])
    with open(os.path.join(work, 'fbdoc.hhk'), 'w', encoding='utf-8',
              newline='') as dst:
        dst.write('<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">\r\n'
                  '<html><head><meta charset="UTF-8"></head><body>\r\n<ul>\r\n')
        for label in sorted(entries, key=str.lower):
            dst.write(sitemap_item(label, entries[label]))
        dst.write('</ul>\r\n</body></html>\r\n')

    files = written + ['style.css'] + \
        ['images/' + img for img in sorted(os.listdir(
            os.path.join(work, 'images')))]
    with open(os.path.join(work, 'fbdoc.hhp'), 'w', encoding='utf-8',
              newline='\r\n') as dst:
        dst.write('[OPTIONS]\n'
                  'Compatibility=1.1 or later\n'
                  'Compiled file=freebasic.chm\n'
                  'Contents file=fbdoc.hhc\n'
                  'Default topic=DocToc.html\n'
                  'Display compile progress=No\n'
                  'Full-text search=Yes\n'
                  'Index file=fbdoc.hhk\n'
                  'Language=0x409 English (United States)\n'
                  'Title=FreeBASIC Manual\n\n'
                  '[FILES]\n' + '\n'.join(files) + '\n')

    proc = subprocess.run(['chmcmd', 'fbdoc.hhp'], cwd=work,
                          capture_output=True, text=True)
    if proc.returncode != 0 or not os.path.isfile(
            os.path.join(work, 'freebasic.chm')):
        print(proc.stdout[-3000:])
        print(proc.stderr[-3000:])
        return 1
    shutil.move(os.path.join(work, 'freebasic.chm'),
                os.path.join(out_dir, 'freebasic.chm'))

    with open(os.path.join(out_dir, 'fbkeywords.txt'), 'w',
              encoding='latin-1', newline='\r\n') as dst:
        for word in sorted(keys):
            dst.write(word + '=' + keys[word] + '\n')

    if not os.environ.get("FB_CHM_KEEP"):
        shutil.rmtree(work)
    print('pages %d, toc %d, index %d, F1 words %d' %
          (len(written), len(toc), len(entries), len(keys)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
