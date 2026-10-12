"""Appendix D pages for the functions of rapidq_ref/inc_sys/rapidqAllProc.inc.

Usage: python3 -I gen_funcs.py <repo dir>
Inputs next to this script: inc_funcs.json (inc_funcs.py) and
funcs_notes/*.json (descriptions: {"id": {"desc": ..., "doc": ...}}).

Writes to rapidq_ref/html_doc:
- fi_<file>.html - one page per source include file: every DECLARE ... LIB
  and SUB / FUNCTION with its declaration and description; Windows API
  functions link to the Microsoft documentation;
- funcs.html - list of the files, links to the Windows API reference;
- funcs_az.html - all names A..Z;
and the Appendix D part between <!-- rq-funcs --> and <!-- /rq-funcs --> in
contents.html. funcs_index.json (next to this script) - NAME: page#anchor,
read by gen_chm.py for the CHM index and keywords.txt (F1).
"""
import collections
import glob
import html
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
repo = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..')
doc_dir = os.path.join(repo, 'rapidq_ref', 'html_doc')

MS_API_REF = 'https://learn.microsoft.com/en-us/windows/win32/api/'
MS_API_LIST = 'https://learn.microsoft.com/en-us/windows/win32/apiindex/windows-api-list'
MS_SEARCH = 'https://learn.microsoft.com/en-us/search/?terms='

NAV = ('<div class="rq-nav"><a href="contents.html">Contents</a>'
       '<a href="contents.html#appa">Components (A)</a>'
       '<a href="custom.html">Custom components (B)</a>'
       '<a href="contents.html#appc">Keywords (C)</a>'
       '<a href="funcs.html">Include functions (D)</a>'
       '<a href="indexa.html">Alphabetic index</a></div>')

items = json.load(open(os.path.join(HERE, 'inc_funcs.json'), encoding='utf-8'))
notes = {}
for path in sorted(glob.glob(os.path.join(HERE, 'funcs_notes', '*.json'))):
    notes.update(json.load(open(path, encoding='utf-8')))


def esc(text):
    return html.escape(text or '', quote=True)


def slug(name):
    return 'fi_' + re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_') + '.html'


def anchor(name):
    return re.sub(r'[^A-Za-z0-9_]', '_', name.upper())


def page_start(title, section):
    return ('<!DOCTYPE html>\n<html>\n<head>\n<meta http-equiv="X-UA-Compatible" content="IE=edge">\n'
            '<!-- rq-generated: rapidq_ref/compdoc/gen_funcs.py -->\n'
            '<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">\n'
            '<title>%s</title>\n<link rel="stylesheet" type="text/css" href="rq.css">\n'
            '</head>\n<body class="rqdoc">\n'
            '<div class="rq-head"><span class="rq-brand">Rapid-Q Documentation &mdash; functions '
            'from include files</span><span class="rq-section">%s</span></div>\n%s\n'
            % (esc(title), esc(section), NAV))


def write_page(name, text):
    data = (text + '</body>\n</html>\n').encode('ascii', 'xmlcharrefreplace').replace(b'\n', b'\r\n')
    open(os.path.join(doc_dir, name), 'wb').write(data)


def kind_text(item):
    if item['kind'] == 'api':
        return 'DLL function, %s' % item['lib']
    if item['kind'] == 'decl':
        return 'declaration only'
    word = item['decl'].split()[0].upper()
    return word if word in ('SUB', 'FUNCTION', 'SUBI', 'FUNCTIONI') else 'procedure'


by_file = collections.OrderedDict()
for item in sorted(items, key=lambda it: it['file'].lower()):
    by_file.setdefault(item['file'], []).append(item)

index = {}
api_total = 0
for fname, group in by_file.items():
    page = slug(fname)
    group.sort(key=lambda it: it['name'].upper())
    api_count = sum(1 for it in group if it['kind'] == 'api')
    api_total += api_count
    out = [page_start(fname, 'Appendix D: ' + fname)]
    out.append('<h1>%s</h1>' % esc(fname))
    out.append('<p class="rq-meta">Source: <code>rapidq_ref/incOld/%s</code>, merged into '
               '<code>rapidq_ref/inc_sys/rapidqAllProc.inc</code> &middot; %d functions'
               '%s</p>' % (esc(fname), len(group),
                           (' &middot; %d DLL functions' % api_count) if api_count else ''))
    if api_count:
        out.append('<p>DLL functions are declared with <code>DECLARE ... LIB</code>; the name '
                   'after ALIAS is the exported name. The description follows the Microsoft '
                   'documentation; the link opens the search for that name on learn.microsoft.com. '
                   'Windows API reference: <a href="%s">%s</a>.</p>' % (MS_API_REF, MS_API_REF))
    out.append('<p>' + ' &middot; '.join('<a href="#%s">%s</a>' % (anchor(it['name']), esc(it['name']))
                                          for it in group) + '</p>')
    for item in group:
        note = notes.get(item['id'], {})
        out.append('<h3><a name="%s"></a>%s</h3>' % (anchor(item['name']), esc(item['name'])))
        out.append('<p class="rq-meta">%s &middot; rapidqAllProc.inc, line %d</p>'
                   % (esc(kind_text(item)), item['line']))
        out.append('<pre>%s</pre>' % esc(item['decl']))
        out.append('<p>%s</p>' % esc(note.get('desc', '')))
        doc_name = note.get('doc', '') if item['kind'] == 'api' else ''
        if doc_name:
            out.append('<p>Microsoft: <a href="%s%s">%s</a></p>'
                       % (MS_SEARCH, esc(doc_name), esc(doc_name)))
        index.setdefault(item['name'].upper(), page + '#' + anchor(item['name']))
    write_page(page, '\n'.join(out) + '\n')

# funcs.html - files
out = [page_start('Functions of rapidqAllProc.inc', 'Appendix D: include functions')]
out.append('<h1>Functions of rapidqAllProc.inc</h1>')
out.append('<p><code>rapidq_ref/inc_sys/rapidqAllProc.inc</code> joins the constants, '
           'DECLAREs and procedures of the old include files. Here are its %d functions, one page '
           'per source file: %d DLL functions (Windows API and a few other DLLs, '
           '<code>DECLARE ... LIB</code>) and %d procedures written in Rapid-Q.</p>'
           % (len(items), api_total, len(items) - api_total))
out.append('<p>Windows API documentation (Microsoft): <a href="%s">Programming reference for the '
           'Win32 API</a> &middot; <a href="%s">Windows API index</a>. Each DLL function also links '
           'to its page search on learn.microsoft.com.</p>' % (MS_API_REF, MS_API_LIST))
out.append('<p><a href="funcs_az.html">All functions A&ndash;Z</a></p>')
out.append('<table class="rq-table"><tr><th>File</th><th>Functions</th><th>DLL functions</th></tr>')
for fname, group in by_file.items():
    api_count = sum(1 for it in group if it['kind'] == 'api')
    out.append('<tr><td><a href="%s">%s</a></td><td>%d</td><td>%d</td></tr>'
               % (slug(fname), esc(fname), len(group), api_count))
out.append('</table>')
write_page('funcs.html', '\n'.join(out) + '\n')

# funcs_az.html
out = [page_start('Include functions A-Z', 'Appendix D: A-Z')]
out.append('<h1>Functions of rapidqAllProc.inc, A&ndash;Z</h1>')
letters = collections.OrderedDict()
for item in sorted(items, key=lambda it: it['name'].upper()):
    first = item['name'][0].upper()
    letters.setdefault(first if first.isalpha() else '#', []).append(item)
out.append('<p>' + ' '.join('<a href="#L_%s">%s</a>' % (anchor(key), esc(key)) for key in letters) + '</p>')
for key, group in letters.items():
    out.append('<h3><a name="L_%s"></a>%s</h3>' % (anchor(key), esc(key)))
    for item in group:
        desc = notes.get(item['id'], {}).get('desc', '')
        short = desc.split('. ')[0].rstrip('.') + '.' if desc else ''
        out.append('<p class="rq-ix"><a href="%s#%s">%s</a> &ndash; %s <span class="rq-meta">(%s)</span></p>'
                   % (slug(item['file']), anchor(item['name']), esc(item['name']), esc(short),
                      esc(item['file'])))
write_page('funcs_az.html', '\n'.join(out) + '\n')

# contents.html, Appendix D
contents_path = os.path.join(doc_dir, 'contents.html')
text = open(contents_path, 'rb').read().decode('cp1252')
block = ['<!-- rq-funcs -->',
         '  <LI><a href="funcs.html">Functions of rapidqAllProc.inc</a> &mdash; %d functions of the merged '
         'include file, one page per source file: Windows API declarations with descriptions and links '
         'to Microsoft, and procedures written in Rapid-Q.' % len(items),
         '     <UL>']
for fname, group in by_file.items():
    block.append('      <LI><a href="%s">%s</a> (%d)' % (slug(fname), esc(fname), len(group)))
block += ['     </UL>',
          '  <LI><a href="funcs_az.html">Include functions A&ndash;Z</a>',
          '  <LI><a href="%s">Windows API reference (Microsoft, learn.microsoft.com)</a>' % MS_API_REF,
          '<!-- /rq-funcs -->']
new_block = '\r\n'.join(block)
if '<!-- rq-funcs -->' in text:
    text = re.sub(r'<!-- rq-funcs -->.*?<!-- /rq-funcs -->', lambda m: new_block, text, flags=re.S)
else:
    marker = re.search(r'(<a name="appd"></a>.*?<UL>\r?\n)', text, re.S)
    if not marker:
        sys.exit('contents.html: Appendix D not found')
    text = text[:marker.end()] + new_block + '\r\n' + text[marker.end():]
open(contents_path, 'wb').write(text.encode('cp1252', 'xmlcharrefreplace'))

json.dump(index, open(os.path.join(HERE, 'funcs_index.json'), 'w', encoding='utf-8'), indent=0, sort_keys=True)
print('pages', len(by_file), 'functions', len(items), 'api', api_total,
      'without description', sum(1 for it in items if not notes.get(it['id'], {}).get('desc')))
