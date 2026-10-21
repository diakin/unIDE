"""Build catalog.json: documented components, page names, bundle editions, batches.

Usage: python3 -I catalog.py <inv.json> <html_doc dir> <out catalog.json> <batch dir> <batch count>
"""
import json
import os
import re
import sys

inv_path, doc_dir, out_path, batch_dir, batch_count = sys.argv[1:6]
batch_count = int(batch_count)
files = json.load(open(inv_path, encoding='utf-8'))
BUNDLES = {'rapidq.inc', 'rapidq2.inc'}

# standard component pages: "Appendix A: NAME" -> file
std_pages = {}
for name in os.listdir(doc_dir):
    if not name.lower().endswith('.html') or name.startswith('c_'):
        continue
    text = open(os.path.join(doc_dir, name), encoding='cp1252', errors='replace').read()
    match = re.search(r'Appendix A:\s*([A-Za-z0-9_]+)', re.sub(r'<[^>]+>', ' ', text))
    if match and name.lower().startswith('q'):
        std_pages[match.group(1).upper()] = name
std_pages['QOBJECT'] = 'chapter10.html'


def member_names(comp):
    out = {}
    for field in comp['fields']:
        out[field['name'].upper()] = ('P', field)
    for event in comp['events']:
        out[event['name'].upper()] = ('E', event)
    for method in comp['methods']:
        out.setdefault(method['name'].upper(), ('M', method))
    return out


standalone = {}
bundle = []
for item in files:
    for comp in item['components']:
        entry = {'name': comp['name'], 'file': item['file'], 'comp': comp, 'info': item}
        if item['file'] in BUNDLES:
            bundle.append(entry)
        else:
            standalone.setdefault(comp['name'].upper(), []).append(entry)

for entry in bundle:
    key = entry['name'].upper()
    if key in standalone:
        for target in standalone[key]:
            target.setdefault('editions', []).append(entry)
    else:
        standalone.setdefault(key, []).append(entry)

catalog = []
for key in sorted(standalone):
    entries = standalone[key]
    for entry in entries:
        stem = re.sub(r'[^a-z0-9]+', '_', os.path.splitext(entry['file'])[0].lower())
        page = 'c_%s.html' % key.lower() if len(entries) == 1 else 'c_%s_%s.html' % (key.lower(), stem)
        comp = entry['comp']
        public = member_names({'fields': [f for f in comp['fields'] if f['visibility'] == 'public'],
                               'events': [e for e in comp['events'] if e['visibility'] == 'public'],
                               'methods': [m for m in comp['methods'] if m['visibility'] == 'public']})
        editions = []
        for edition in entry.get('editions', []):
            extra = sorted(set(member_names(edition['comp'])) - set(member_names(comp)))
            editions.append({'file': edition['file'], 'line': edition['comp']['line'],
                             'extra_members': extra})
        catalog.append({
            'id': '%s@%s' % (comp['name'], entry['file']),
            'name': comp['name'], 'key': key, 'page': page, 'file': entry['file'],
            'line': comp['line'], 'end_line': comp['end_line'], 'base': comp['base'],
            'base_upper': comp['base'].upper(),
            'members': {name: kind for name, (kind, item) in public.items()},
            'editions': editions,
        })

# base links: standard page or custom page
custom_pages = {}
for item in catalog:
    custom_pages.setdefault(item['key'], item['page'])
for item in catalog:
    base = item['base_upper']
    if base in custom_pages:
        item['base_page'] = custom_pages[base]
    else:
        item['base_page'] = std_pages.get(base, '')

json.dump({'components': catalog, 'std_pages': std_pages}, open(out_path, 'w', encoding='utf-8'),
          ensure_ascii=False, indent=1)

# batches balanced by source size
os.makedirs(batch_dir, exist_ok=True)
by_file = {}
for item in catalog:
    by_file.setdefault(item['file'], []).append(item)
sizes = sorted(((sum((it['end_line'] or it['line']) - it['line'] + 40 for it in items), name)
                for name, items in by_file.items()), reverse=True)
batches = [[] for _ in range(batch_count)]
loads = [0] * batch_count
for size, name in sizes:
    pos = loads.index(min(loads))
    batches[pos].extend(by_file[name])
    loads[pos] += size
for pos, batch in enumerate(batches):
    json.dump([{'id': it['id'], 'file': it['file'], 'line': it['line'], 'end_line': it['end_line'],
                'base': it['base'], 'members': it['members']} for it in batch],
              open(os.path.join(batch_dir, 'batch%d.json' % (pos + 1)), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
print('components', len(catalog), 'std pages', len(std_pages), 'batch loads', loads)
