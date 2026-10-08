"""Which files in rapidq_ref/inc are included ($INCLUDE) by sources in the repo.

Usage: python3 -I refs.py <repo dir> <out json>
Source files: .bas .inc .bi .cmp .tpl .rqb anywhere in the repo (not .git).
An include name is resolved case-insensitively against rapidq_ref/inc, its
subfolders by relative path ("Object\\QINI.inc"), and the including file's
own folder. Result: {inc rel path: [referencing files]}.
"""
import json
import os
import re
import sys

repo, out_path = sys.argv[1], sys.argv[2]
inc_dir = os.path.join(repo, 'rapidq_ref', 'inc')
SRC_EXT = {'.bas', '.inc', '.bi', '.cmp', '.tpl', '.rqb'}
INCLUDE_RE = re.compile(r'^\s*(?:\'\s*)?\$INCLUDE\s*["<]([^">]+)[">]', re.I)

inc_index = {}
for root, dirs, names in os.walk(inc_dir):
    for name in names:
        rel = os.path.relpath(os.path.join(root, name), inc_dir).replace(os.sep, '/')
        inc_index[rel.lower()] = rel

refs = {}
unresolved = []
for root, dirs, names in os.walk(repo):
    dirs[:] = [d for d in dirs if d != '.git']
    for name in names:
        if os.path.splitext(name)[1].lower() not in SRC_EXT:
            continue
        path = os.path.join(root, name)
        src_rel = os.path.relpath(path, repo).replace(os.sep, '/')
        with open(path, 'rb') as src:
            text = src.read().decode('cp1251', errors='replace')
        for line_no, line in enumerate(text.splitlines(), 1):
            if line.lstrip().startswith("'") and '$include' not in line.lower():
                continue
            match = INCLUDE_RE.match(line)
            if not match:
                continue
            commented = line.lstrip().startswith("'")
            target = match.group(1).replace('\\', '/').strip()
            key = target.lower()
            hit = inc_index.get(key)
            if hit is None:
                own_dir = os.path.relpath(root, inc_dir).replace(os.sep, '/')
                if not own_dir.startswith('..'):
                    hit = inc_index.get((own_dir + '/' + key).lower().lstrip('./'))
            if hit is None:
                base = key.split('/')[-1]
                if base in inc_index:
                    hit = inc_index[base]
            if hit is None:
                unresolved.append('%s:%d %s' % (src_rel, line_no, target))
                continue
            refs.setdefault(hit, []).append('%s:%d%s' % (src_rel, line_no, ' (commented)' if commented else ''))

with open(out_path, 'w', encoding='utf-8') as out:
    json.dump({'refs': refs, 'unresolved': unresolved}, out, ensure_ascii=False, indent=1)
print('referenced inc files', len(refs), 'unresolved includes', len(unresolved))
