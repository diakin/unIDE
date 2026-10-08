"""Generate Appendix B pages for custom components, the custom.html index,
the Appendix B section of contents.html and rapidq_ref/inc/COMPONENTS.md.

Usage: python3 -I gen_pages.py <repo dir>
Inputs next to this script: inv.json, catalog.json, notes/*.json, decisions.py.
"""
import glob
import html
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from decisions import OLD, DISPUTED  # noqa: E402

repo = sys.argv[1]
doc_dir = os.path.join(repo, 'rapidq_ref', 'html_doc')
inc_dir = os.path.join(repo, 'rapidq_ref', 'inc')
inv = json.load(open(os.path.join(HERE, 'inv.json'), encoding='utf-8'))
catalog = json.load(open(os.path.join(HERE, 'catalog.json'), encoding='utf-8'))['components']
notes = {}
for path in sorted(glob.glob(os.path.join(HERE, 'notes', '*.json'))):
    notes.update(json.load(open(path, encoding='utf-8')))

AUTHOR_DOCS = {'QCHART': ('qChart.html', 'QChart guide by Michael J. Zito (2003)'),
               'QTABCONTROLEX': ('QTabControlEx.html', 'QTabControlEx documentation by D. Glodt (2004)')}
NAV = ('<div class="rq-nav"><a href="contents.html">Contents</a>'
       '<a href="contents.html#appa">Components (A)</a>'
       '<a href="custom.html">Custom components (B)</a>'
       '<a href="contents.html#appc">Keywords (C)</a>'
       '<a href="indexa.html">Alphabetic index</a></div>')

comp_by_id = {}
for item in inv:
    for comp in item['components']:
        comp_by_id['%s@%s' % (comp['name'], item['file'])] = (item, comp)


def esc(text):
    return html.escape(text or '', quote=True)


def page_start(title, section):
    return ('<!DOCTYPE html>\n<html>\n<head>\n<meta http-equiv="X-UA-Compatible" content="IE=edge">\n'
            '<!-- rq-generated: rapidq_ref/inc sources, see COMPONENTS.md -->\n'
            '<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">\n'
            '<title>%s</title>\n<link rel="stylesheet" type="text/css" href="rq.css">\n'
            '</head>\n<body class="rqdoc">\n'
            '<div class="rq-head"><span class="rq-brand">Rapid-Q Documentation &mdash; custom components'
            '</span><span class="rq-section">%s</span></div>\n%s\n' % (esc(title), esc(section), NAV))


def write_page(name, text):
    data = text.encode('ascii', 'xmlcharrefreplace').replace(b'\n', b'\r\n')
    open(os.path.join(doc_dir, name), 'wb').write(data)


def sig_params(params):
    params = re.sub(r'\s+', ' ', params or '').strip()
    return '(' + params + ')' if params else ''


def base_link(entry):
    if entry['base_page']:
        return '<a href="%s">%s</a>' % (esc(entry['base_page']), esc(entry['base'].upper()))
    return esc(entry['base'].upper())


def member_desc(note, name):
    return (note.get('members') or {}).get(name.upper(), '')


def row_class(desc):
    return ' class="rq-internal"' if desc.startswith('Internal') else ''


def build_page(entry, prev_entry, next_entry):
    item, comp = comp_by_id[entry['id']]
    note = notes.get(entry['id'], {})
    title = entry['name'].upper()
    out = [page_start(title, 'Appendix B: ' + title)]
    out.append('<h1>%s Component</h1>\n' % esc(title))
    meta = ['Extends ' + base_link(entry),
            'source: <code>inc/%s</code>, line %d' % (esc(entry['file']), entry['line'])]
    for label in ('author', 'version', 'date'):
        if note.get(label):
            meta.append('%s: %s' % (label, esc(note[label])))
    out.append('<p class="rq-meta">%s</p>\n' % ' &middot; '.join(meta))
    if note.get('summary_en'):
        out.append('<p><b>%s</b></p>\n' % esc(note['summary_en']))
    for para in note.get('description_en') or []:
        out.append('<p>%s</p>\n' % esc(para))
    if entry['key'] in AUTHOR_DOCS:
        page, label = AUTHOR_DOCS[entry['key']]
        out.append('<p class="rq-note">Original documentation: <a href="%s">%s</a>.</p>\n' % (page, esc(label)))
    out.append('<p>%s inherits the properties, methods and events of %s; the tables below list only '
               'what the component adds or redefines (public members).</p>\n' % (esc(title), base_link(entry)))
    if note.get('requires'):
        out.append('<h2>Requires</h2>\n<ul>\n%s</ul>\n' % ''.join('<li>%s</li>\n' % esc(req) for req in note['requires']))

    defaults = {item_d['name'].upper(): item_d['value'] for item_d in comp['defaults']}
    fields = [field for field in comp['fields'] if field['visibility'] == 'public']
    if fields:
        out.append('<a name="1"></a><h2>%s Properties</h2>\n<table class="rq-ref">\n'
                   '<tr><th>Field</th><th>Type</th><th>R/W</th><th>Default</th><th>Description</th></tr>\n' % esc(entry['name']))
        for field in fields:
            desc = member_desc(note, field['name'])
            ftype = field['type'] + ('(%s)' % field['array'] if field['array'] else '')
            if field['array']:
                ftype = 'ARRAY(%s) OF %s' % (field['array'], field['type'])
            out.append('<tr%s><td class="rq-name">%s</td><td class="rq-type">%s</td><td>RW</td><td>%s</td><td>%s</td></tr>\n' % (
                row_class(desc), esc(field['name']), esc(ftype), esc(defaults.get(field['name'].upper(), '')), esc(desc)))
        out.append('</table>\n')
    methods = [method for method in comp['methods'] if method['visibility'] == 'public']
    if methods:
        out.append('<a name="2"></a><h2>%s Methods</h2>\n<table class="rq-ref">\n'
                   '<tr><th>Method</th><th>Type</th><th>Description</th></tr>\n' % esc(entry['name']))
        for method in methods:
            desc = member_desc(note, method['name'])
            mtype = method['kind'] + sig_params(method['params'])
            if method['returns']:
                mtype += ' AS ' + method['returns'].upper()
            out.append('<tr%s><td class="rq-name">%s</td><td class="rq-type">%s</td><td>%s</td></tr>\n' % (
                row_class(desc), esc(method['name']), esc(mtype), esc(desc)))
        out.append('</table>\n')
    events = [event for event in comp['events'] if event['visibility'] == 'public']
    if events:
        out.append('<a name="3"></a><h2>%s Events</h2>\n<table class="rq-ref">\n'
                   '<tr><th>Event</th><th>Type</th><th>Occurs when...</th></tr>\n' % esc(entry['name']))
        for event in events:
            desc = member_desc(note, event['name'])
            out.append('<tr%s><td class="rq-name">%s</td><td class="rq-type">%s</td><td>%s</td></tr>\n' % (
                row_class(desc), esc(event['name']), esc('SUB' + sig_params(event.get('params', ''))), esc(desc)))
        out.append('</table>\n')
    handlers = sorted({handler['name'] for handler in comp['handlers']}, key=str.lower)
    if handlers:
        out.append('<p>The component handles these events itself (EVENT blocks in the TYPE): %s.</p>\n'
                   % ', '.join('<code>%s</code>' % esc(name) for name in handlers))
    if not (fields or methods or events):
        out.append('<p>The component adds no public members of its own.</p>\n')
    if note.get('caveats_en'):
        out.append('<h2>Notes</h2>\n<ul>\n%s</ul>\n' % ''.join('<li>%s</li>\n' % esc(cav) for cav in note['caveats_en']))
    others = []
    for edition in entry.get('editions', []):
        extra = ', '.join(edition['extra_members'][:20])
        others.append('<li><code>inc/%s</code> (line %d) contains its own edition of %s%s.</li>\n' % (
            esc(edition['file']), edition['line'], esc(title),
            ('; it has members that are not in this file: ' + esc(extra)) if extra else ''))
    for old_file, (old_comp, kept, reason) in sorted(OLD.items()):
        if old_comp == entry['key'] and kept == entry['file']:
            kind = 'identical copy' if reason.startswith('копия') else 'older version'
            others.append('<li><code>inc/old/%s</code> &mdash; %s (moved; the reason is in COMPONENTS.md).</li>\n' % (esc(old_file), kind))
    if others:
        out.append('<h2>Other versions</h2>\n<ul>\n%s</ul>\n' % ''.join(others))
    if note.get('example'):
        origin = 'from the comments in the source file' if note.get('example_origin') == 'source' else 'written for this page from the members above; not run'
        out.append('<a name="4"></a><h2>%s Examples</h2>\n<p class="rq-meta">Example %s.</p>\n<pre>%s</pre>\n' % (
            esc(entry['name']), origin, esc(note['example'].replace('\r', ''))))
    foot = ['<a href="%s">Prev component</a>' % prev_entry['page'] if prev_entry else '',
            '<a href="custom.html">Custom components</a>', '<a href="contents.html">Contents</a>',
            '<a href="%s">Next component</a>' % next_entry['page'] if next_entry else '']
    out.append('<div class="rq-foot">%s</div>\n</body>\n</html>\n' % ''.join(part for part in foot if part))
    return ''.join(out)


def main():
    ordered = sorted(catalog, key=lambda entry: (entry['key'], entry['file'].lower()))
    for pos, entry in enumerate(ordered):
        prev_entry = ordered[pos - 1] if pos > 0 else None
        next_entry = ordered[pos + 1] if pos + 1 < len(ordered) else None
        write_page(entry['page'], build_page(entry, prev_entry, next_entry))

    # custom.html - Appendix B index
    rows = []
    for entry in ordered:
        note = notes.get(entry['id'], {})
        rows.append('<tr><td class="rq-name"><a href="%s">%s</a></td><td class="rq-type">%s</td>'
                    '<td><code>%s</code></td><td>%s</td></tr>\n' % (
                        entry['page'], esc(entry['name'].upper()), base_link(entry), esc(entry['file']),
                        esc(note.get('summary_en', ''))))
    index = [page_start('Custom components', 'Appendix B: Custom Components'),
             '<h1>Appendix B: Custom Components</h1>\n',
             '<p>Components written in Rapid-Q itself (<code>TYPE Name EXTENDS Base</code>) that are kept in '
             '<code>rapidq_ref/inc</code>. Each page is built from the component source: the tables list the '
             'public fields, methods and events found in the TYPE block, defaults come from its CONSTRUCTOR, '
             'descriptions from the code and its comments. Older versions of the files are in '
             '<code>rapidq_ref/inc/old</code>; the full list with the reasons is in '
             '<code>rapidq_ref/inc/COMPONENTS.md</code>.</p>\n',
             '<p>Examples marked &quot;written for this page&quot; were not run. Some components need files that '
             'are not in the collection (DLLs, bitmaps); see Requires and Notes on each page.</p>\n',
             '<table class="rq-ref">\n<tr><th>Component</th><th>Extends</th><th>File</th><th>Description</th></tr>\n',
             ''.join(rows), '</table>\n',
             '<div class="rq-foot"><a href="contents.html">Contents</a><a href="indexa.html">Alphabetic index</a></div>\n'
             '</body>\n</html>\n']
    write_page('custom.html', ''.join(index))

    # contents.html: Appendix B section and anchors
    path = os.path.join(doc_dir, 'contents.html')
    text = open(path, 'rb').read().decode('cp1252')
    text = re.sub(r'[ \t]*<!-- rq-appendix-b -->.*?<!-- /rq-appendix-b -->\r?\n', '', text, flags=re.S)
    items = ''.join('  <LI><a href="%s">%s</a> &mdash; %s\r\n' % (
        entry['page'], esc(entry['name'].upper()), esc(notes.get(entry['id'], {}).get('summary_en', '')))
        for entry in ordered)
    block = ('<!-- rq-appendix-b -->\r\n  <a name="appb"></a><B><a href="custom.html">Appendix B: Custom Components</a></B>'
             ' (rapidq_ref/inc)<BR>\r\n  <UL>\r\n' + items + '  </UL>\r\n<!-- /rq-appendix-b -->\r\n')
    if '<a name="appa"></a>' not in text:
        text = text.replace('  <B>Appendix A: Rapid-Q Component/Object Reference</B>',
                            '  <a name="appa"></a><B>Appendix A: Rapid-Q Component/Object Reference</B>', 1)
    if '<a name="appc"></a>' not in text:
        text = text.replace('  <B>Appendix C: Rapid-Q Keywords & Statements</B>',
                            '  <a name="appc"></a><B>Appendix C: Rapid-Q Keywords & Statements</B>', 1)
    text = re.sub(r'[ \t]*<a name="appc"></a>', lambda found: block + '  <a name="appc"></a>', text, count=1)
    open(path, 'wb').write(text.encode('ascii', 'xmlcharrefreplace'))

    # indexa.html: links to the old ../custom/ folder -> pages of Appendix B
    pages = {}
    for entry in ordered:
        pages.setdefault(entry['key'], entry['page'])
    aliases = {'QDIR1': 'QDIR', 'QBEVELL': 'QBEVEL', 'QDEBUG1': 'QDEBUG', 'RC4CRYPT': 'QRC4'}
    path = os.path.join(doc_dir, 'indexa.html')
    text = open(path, 'rb').read().decode('cp1252')
    fixed = []

    def repoint(match):
        stem = re.sub(r'\.html?$', '', match.group(1).split('/')[-1], flags=re.I).upper()
        if stem == 'CUSTOM_CONTENTS':
            fixed.append(stem)
            return 'href="custom.html"'
        key = aliases.get(stem, stem)
        if key in pages:
            fixed.append(stem)
            return 'href="%s"' % pages[key]
        return match.group(0)
    text = re.sub(r'href="(\.\./custom/[^"#]*)"', repoint, text, flags=re.I)
    open(path, 'wb').write(text.encode('cp1252'))
    print('pages', len(ordered), 'indexa links repointed', len(fixed))


main()
