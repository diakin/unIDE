"""Functions of rapidq_ref/inc_sys/RQProc.inc for Appendix D of the
help: every DECLARE ... LIB (Windows API and other DLLs) and every own SUB /
FUNCTION, grouped by the source include file (the '[build_inc] file'
sections of the merged file; 'file (тела)' sections - bodies moved to the
end - belong to the same file).

Usage: python3 -I inc_funcs.py <repo dir> [out.json]
Writes inc_funcs.json next to this script (or out.json): a list of
{id, name, file, kind, lib, alias, decl, line, comment, body}.
kind: 'api' - DECLARE ... LIB; 'proc' - own SUB / FUNCTION (with body),
'decl' - DECLARE without LIB and without a body in the file.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
repo = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..')
out_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, 'inc_funcs.json')
src = os.path.join(repo, 'rapidq_ref', 'inc_sys', 'RQProc.inc')


def code_part(line):
    out, in_str = [], False
    for ch in line:
        if ch == '"':
            in_str = not in_str
        if ch == "'" and not in_str:
            break
        out.append(ch)
    code = ''.join(out).strip()
    if re.match(r'rem\b', code, re.I):
        return ''
    return code


def comment_part(line):
    in_str = False
    for idx, ch in enumerate(line):
        if ch == '"':
            in_str = not in_str
        if ch == "'" and not in_str:
            return line[idx + 1:].strip()
    return ''


lines = open(src, 'rb').read().decode('cp1251').replace('\r\n', '\n').split('\n')
items = {}
order = []
cur_file = ''
idx = 0
while idx < len(lines):
    line = lines[idx]
    mark = re.match(r"'\[build_inc\]\s+(.*?)\s*$", line)
    if mark:
        cur_file = re.sub(r'\s*\((тела|компоненты)\)\s*$', '', mark.group(1)).strip()
        again = re.match(r'\(дальше снова (.+)\)$', cur_file)
        if again:
            cur_file = again.group(1).strip()
        idx += 1
        continue
    code = code_part(line)
    decl = re.match(r'declare\s+(sub|function)i?\s+([\w~]+[$%&!#?]*)', code, re.I)
    proc = re.match(r'(sub|function)(i?)\s+([\w~.]+[$%&!#?]*)', code, re.I)
    if not decl and not proc:
        idx += 1
        continue
    # comments right above (and on the line itself)
    above = []
    back = idx - 1
    while back >= 0 and len(above) < 8:
        text = lines[back].strip()
        if text.startswith("'") and not text.startswith("'~") and not text.startswith("'["):
            body = text[1:].strip()
            if body and not re.fullmatch(r'[-=*_#\s]+', body):
                above.insert(0, body)
            back -= 1
        else:
            break
    # whole statement with continuations
    full = code
    first = idx
    tail_comment = comment_part(line)
    while full.rstrip().endswith('_') and idx + 1 < len(lines):
        idx += 1
        full = full.rstrip()[:-1].rstrip() + ' ' + code_part(lines[idx])
        if comment_part(lines[idx]):
            tail_comment += ' ' + comment_part(lines[idx])
    full = re.sub(r'\s+', ' ', full).strip()
    comment = ' / '.join(above + ([tail_comment.strip()] if tail_comment.strip() else []))
    if decl:
        name = decl.group(2)
        lib = re.search(r'\blib\s+"([^"]+)"', full, re.I)
        alias = re.search(r'\balias\s+"([^"]+)"', full, re.I)
        key = (cur_file.lower(), name.upper())
        kind = 'api' if lib else 'decl'
        if key in items:
            if kind == 'api':
                items[key].update(kind='api', lib=lib.group(1), decl=full)
        else:
            items[key] = {'name': name, 'file': cur_file, 'kind': kind,
                          'lib': lib.group(1) if lib else '',
                          'alias': alias.group(1) if alias else '',
                          'decl': full, 'line': first + 1, 'comment': comment, 'body': ''}
            order.append(key)
        idx += 1
        continue
    # own SUB / FUNCTION with body up to END SUB / END FUNCTION
    name = proc.group(3)
    word = proc.group(1).lower() + proc.group(2).lower()
    end_re = re.compile(r'end\s+' + proc.group(1) + (r'i' if proc.group(2) else '') + r'\b', re.I)
    body = []
    scan = idx + 1
    while scan < len(lines) and not end_re.match(code_part(lines[scan])):
        if len(body) < 60:
            body.append(lines[scan].rstrip())
        scan += 1
    key = (cur_file.lower(), name.upper())
    if key in items and items[key]['kind'] == 'decl':
        items[key].update(kind='proc', decl=full, body='\n'.join(body))
        if comment and comment not in items[key]['comment']:
            items[key]['comment'] = (items[key]['comment'] + ' / ' + comment).strip(' /')
    elif key not in items:
        items[key] = {'name': name, 'file': cur_file, 'kind': 'proc', 'lib': '', 'alias': '',
                      'decl': full, 'line': first + 1, 'comment': comment,
                      'body': '\n'.join(body)}
        order.append(key)
    idx = scan + 1

result = []
for key in order:
    item = items[key]
    item['id'] = '%s@%s' % (item['name'], item['file'])
    result.append(item)
json.dump(result, open(out_path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
kinds = {}
for item in result:
    kinds[item['kind']] = kinds.get(item['kind'], 0) + 1
print(len(result), kinds, 'files', len(set(item['file'] for item in result)))
