"""Inventory of RapidQ custom components (TYPE ... EXTENDS) in rapidq_ref/inc.

Usage: python3 -I inventory.py <inc dir> <out json>
Scans every text file in <inc dir> and its subfolders (except 'old'),
collects per file: md5, size, lines, header comment, author/version/date
hints, $INCLUDE list, and per component: name, base, line, comments before
TYPE, members (fields, events, methods, property setters, base-event
handlers, constructor defaults) with visibility and trailing comments.
"""
import hashlib
import json
import os
import re
import sys

BINARY_EXT = {'.bmp', '.ico', '.cur', '.res', '.exe', '.dll', '.gif', '.jpg', '.png', '.wav'}

TYPE_RE = re.compile(r'^\s*TYPE\s+(\w+)\s*(?:<[^>]*>)?\s+EXTENDS\s+(\w+)', re.I)
END_TYPE_RE = re.compile(r'^\s*END\s+TYPE\b', re.I)
INCLUDE_RE = re.compile(r'^\s*\$INCLUDE\s+["<]([^">]+)[">]', re.I)
VIS_RE = re.compile(r'^\s*(PUBLIC|PRIVATE)\s*:\s*$', re.I)
SUB_RE = re.compile(r'^\s*(SUBI|SUB|FUNCTIONI|FUNCTION)\s+(\w+[$%&!#?]*)\s*(\((.*?)\))?\s*(AS\s+(\w+))?', re.I)
PROP_RE = re.compile(r'^\s*PROPERTY\s+SET\s+(\w+)\s*(\((.*?)\))?', re.I)
EVENT_HANDLER_RE = re.compile(r'^\s*EVENT\s+([\w.]+)\s*(\((.*?)\))?', re.I)
CONSTRUCTOR_RE = re.compile(r'^\s*CONSTRUCTOR\b', re.I)
END_BLOCK_RE = re.compile(r'^\s*END\s+(SUB|SUBI|FUNCTION|FUNCTIONI|PROPERTY|EVENT|CONSTRUCTOR)\b', re.I)
FIELD_RE = re.compile(
    r'^\s*(\w+[$%&!#?]*)\s*(\(([^)]*)\))?\s+AS\s+(EVENT\s*\(\s*(\w+)\s*\)|\w+)'
    r'(\s*\*\s*\d+)?(\s+PROPERTY\s+SET\s+(\w+))?', re.I)
ASSIGN_RE = re.compile(r'^\s*(?:\w+\.)?(\w+)\s*=\s*(.+?)\s*$')
VERSION_RE = re.compile(r'\b(?:version|ver\.?|v)\s*[:.]?\s*(\d+(?:\.\d+)+[a-z]?|\d+[a-z]?)\b', re.I)
DATE_RE = re.compile(r'\b((?:19|20)\d\d)\b')
AUTHOR_RE = re.compile(r'\b(?:by|author|auteur|par|created by|cr..? par|written by)\s*[:]?\s*([A-Z][\w.\- ]{2,40})', re.I)


def read_text(path):
    with open(path, 'rb') as src:
        raw = src.read()
    return raw, raw.decode('cp1251', errors='replace')


def split_code_comment(line):
    """Split a line into code and trailing ' comment (strings respected)."""
    in_str = False
    for idx, char in enumerate(line):
        if char == '"':
            in_str = not in_str
        elif char == "'" and not in_str:
            return line[:idx], line[idx + 1:].strip()
    code = line
    stripped = code.strip()
    if re.match(r'^REM\b', stripped, re.I):
        return '', stripped[3:].strip()
    return code, ''


def header_comment(lines):
    out = []
    for line in lines:
        code, comment = split_code_comment(line)
        if code.strip():
            break
        if comment or not line.strip():
            out.append(comment)
    while out and not out[-1]:
        out.pop()
    while out and not out[0]:
        out.pop(0)
    return out


def comments_before(lines, idx):
    out = []
    pos = idx - 1
    while pos >= 0:
        code, comment = split_code_comment(lines[pos])
        if code.strip():
            break
        if not lines[pos].strip():
            if out:
                break
            pos -= 1
            continue
        out.insert(0, comment)
        pos -= 1
    return out


DEFAULT_RE = re.compile(r'^\s*(?:(\w+)\.)?(\w+)\s*(\(\s*[^()]+?\s*\))?\s*=\s*(.+?)\s*$')


def add_default(comp, part):
    """Constructor line 'Name = value' (or This./TypeName. prefix) -> default."""
    if re.match(r'^\s*(IF|FOR|DIM|WITH|ELSE|END|CASE|SELECT)\b', part, re.I):
        return
    match = DEFAULT_RE.match(part)
    if not match:
        return
    prefix = (match.group(1) or '').upper()
    if prefix and prefix not in ('THIS', comp['name'].upper()):
        return
    name = match.group(2)
    value = match.group(4)
    if match.group(3):
        # array element: collect "(i)=value" pairs in one default
        element = re.sub(r'\s+', '', match.group(3)) + '=' + value
        for item in comp['defaults']:
            if item['name'].upper() == name.upper():
                item['value'] = item['value'] + '; ' + element if item.get('array') else element
                item['array'] = True
                return
        comp['defaults'].append({'name': name, 'value': element, 'array': True})
        return
    for item in comp['defaults']:
        if item['name'].upper() == name.upper():
            item['value'] = value     # last assignment wins
            return
    comp['defaults'].append({'name': name, 'value': value})


def parse_type(lines, start):
    """Parse TYPE block from line index start; return (component, end index)."""
    match = TYPE_RE.match(split_code_comment(lines[start])[0])
    comp = {
        'name': match.group(1), 'base': match.group(2), 'line': start + 1,
        'comment_before': comments_before(lines, start),
        'type_line_comment': split_code_comment(lines[start])[1],
        'fields': [], 'events': [], 'methods': [], 'setters': [],
        'handlers': [], 'defaults': [], 'end_line': None,
    }
    visibility = 'public'
    block = None          # current body kind
    block_item = None
    idx = start + 1
    while idx < len(lines):
        raw = lines[idx]
        code, comment = split_code_comment(raw)
        text = code.strip()
        if block is None and END_TYPE_RE.match(text):
            comp['end_line'] = idx + 1
            return comp, idx
        if block is not None:
            if END_BLOCK_RE.match(text):
                block = None
                block_item = None
            elif block == 'constructor':
                for part in re.split(r':(?=(?:[^"]*"[^"]*")*[^"]*$)', text):
                    add_default(comp, part)
            elif block_item is not None and comment and not block_item.get('body_comment'):
                block_item['body_comment'] = comment
            idx += 1
            continue
        if not text:
            idx += 1
            continue
        vis = VIS_RE.match(text)
        if vis:
            visibility = vis.group(1).lower()
            idx += 1
            continue
        if CONSTRUCTOR_RE.match(text):
            block = 'constructor'
            rest = text[len('CONSTRUCTOR'):].lstrip(':').strip()
            if rest:
                add_default(comp, rest)
            idx += 1
            continue
        sub = SUB_RE.match(text)
        if sub and not re.match(r'^\s*\w+\s+AS\b', text, re.I):
            item = {'kind': sub.group(1).upper(), 'name': sub.group(2),
                    'params': (sub.group(4) or '').strip(),
                    'returns': sub.group(6) or '', 'visibility': visibility,
                    'line': idx + 1, 'comment': comment,
                    'comment_before': comments_before(lines, idx)}
            comp['methods'].append(item)
            # one-line body: "SUB X: stmt: END SUB"
            if not re.search(r'\bEND\s+(SUB|FUNCTION)\b', text, re.I):
                block = 'method'
                block_item = item
            idx += 1
            continue
        prop = PROP_RE.match(text)
        if prop:
            item = {'name': prop.group(1), 'params': (prop.group(3) or '').strip(),
                    'line': idx + 1, 'comment': comment}
            comp['setters'].append(item)
            if not re.search(r'\bEND\s+PROPERTY\b', text, re.I):
                block = 'setter'
                block_item = item
            idx += 1
            continue
        handler = EVENT_HANDLER_RE.match(text)
        if handler and not re.match(r'^\s*\w+\s+AS\b', text, re.I):
            item = {'name': handler.group(1), 'params': (handler.group(3) or '').strip(),
                    'visibility': visibility, 'line': idx + 1, 'comment': comment}
            comp['handlers'].append(item)
            if not re.search(r'\bEND\s+EVENT\b', text, re.I):
                block = 'handler'
                block_item = item
            idx += 1
            continue
        # fields, possibly several separated by ':' or ','
        for part in re.split(r'[:,](?![^(]*\))', text):
            field = FIELD_RE.match(part)
            if not field:
                continue
            ftype = field.group(4)
            if field.group(5):
                comp['events'].append({'name': field.group(1), 'template': field.group(5),
                                       'visibility': visibility, 'line': idx + 1,
                                       'comment': comment})
            else:
                comp['fields'].append({'name': field.group(1), 'type': ftype.upper(),
                                       'array': (field.group(3) or '').strip(),
                                       'setter': field.group(8) or '',
                                       'visibility': visibility, 'line': idx + 1,
                                       'comment': comment})
        idx += 1
    comp['end_line'] = None
    return comp, idx


def join_continuations(lines):
    """Join a line whose code ends with ' _' with the next one; the joined
    lines become empty so that line numbers stay the same."""
    out = list(lines)
    idx = 0
    while idx < len(out):
        code, comment = split_code_comment(out[idx])
        nxt = idx + 1
        while re.search(r'\s_\s*$', code) and nxt < len(out):
            code2, comment2 = split_code_comment(out[nxt])
            code = re.sub(r'\s_\s*$', ' ', code) + code2.strip()
            comment = comment or comment2
            out[nxt] = ''
            nxt += 1
        if nxt > idx + 1:
            out[idx] = code + ((" '" + comment) if comment else '')
        idx = nxt
    return out


def scan_file(path, rel):
    raw, text = read_text(path)
    lines = join_continuations(text.splitlines())
    info = {
        'file': rel, 'size': len(raw), 'lines': len(lines),
        'md5': hashlib.md5(raw).hexdigest(),
        'norm_md5': hashlib.md5(re.sub(rb'\s+', b'', raw.lower())).hexdigest(),
        'header': header_comment(lines)[:40],
        'includes': [], 'components': [], 'subs_outside': 0,
    }
    head_text = '\n'.join(lines[:80])
    info['versions'] = sorted(set(VERSION_RE.findall(head_text)))[:5]
    info['years'] = sorted(set(DATE_RE.findall(head_text)))
    authors = AUTHOR_RE.findall(head_text)
    info['authors'] = [author.strip() for author in authors][:3]
    idx = 0
    while idx < len(lines):
        code = split_code_comment(lines[idx])[0]
        inc = INCLUDE_RE.match(lines[idx])
        if inc:
            info['includes'].append(inc.group(1))
        if TYPE_RE.match(code):
            comp, idx = parse_type(lines, idx)
            info['components'].append(comp)
        idx += 1
    templates = {}
    for line in lines:
        code = split_code_comment(line)[0]
        sub = re.match(r'^\s*(?:DECLARE\s+)?SUB\s+(\w+)\s*(\((.*?)\))?', code, re.I)
        if sub:
            templates.setdefault(sub.group(1).upper(), (sub.group(3) or '').strip())
    for comp in info['components']:
        for event in comp['events']:
            event['params'] = templates.get(event['template'].upper(), '')
    return info


def main():
    inc_dir, out_path = sys.argv[1], sys.argv[2]
    files = []
    for root, dirs, names in os.walk(inc_dir):
        dirs[:] = sorted(d for d in dirs if d.lower() != 'old')
        for name in sorted(names, key=str.lower):
            if os.path.splitext(name)[1].lower() in BINARY_EXT:
                continue
            path = os.path.join(root, name)
            rel = os.path.relpath(path, inc_dir).replace(os.sep, '/')
            files.append(scan_file(path, rel))
    with open(out_path, 'w', encoding='utf-8') as out:
        json.dump(files, out, ensure_ascii=False, indent=1)
    comp_count = sum(len(item['components']) for item in files)
    print('files', len(files), 'with components',
          sum(1 for item in files if item['components']), 'components', comp_count)


if __name__ == '__main__':
    main()
