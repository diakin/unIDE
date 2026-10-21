"""Group components by name and show version lineages (similarity of TYPE blocks)."""
import difflib
import json
import re
import sys

inc_dir, inv_path = sys.argv[1], sys.argv[2]
files = json.load(open(inv_path, encoding='utf-8'))


def block_lines(rel, comp):
    with open(inc_dir + '/' + rel, 'rb') as src:
        lines = src.read().decode('cp1251', errors='replace').splitlines()
    end = comp['end_line'] or len(lines)
    body = lines[comp['line'] - 1:end]
    return [re.sub(r'\s+', ' ', line.strip().lower()) for line in body if line.strip()]


groups = {}
for item in files:
    for comp in item['components']:
        groups.setdefault(comp['name'].upper(), []).append((item, comp))

for name in sorted(groups):
    members = groups[name]
    if len(members) < 2:
        continue
    print('==', name)
    texts = [block_lines(item['file'], comp) for item, comp in members]
    for pos, (item, comp) in enumerate(members):
        sims = []
        for other in range(len(members)):
            if other != pos:
                ratio = difflib.SequenceMatcher(None, texts[pos], texts[other]).ratio()
                sims.append('%d:%.2f' % (other, ratio))
        print('  %d %-28s %5d lines blk %4d ver=%s yrs=%s md5=%s  %s' % (
            pos, item['file'], item['lines'], len(texts[pos]), ','.join(item['versions']),
            ','.join(item['years']), item['norm_md5'][:6], ' '.join(sims)))
