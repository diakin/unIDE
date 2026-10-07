# Список свойств, методов и событий классов RapidQ для CREATE ... END CREATE
# в RqToFb.pas (константа RqClassMembersText между строками-метками
# "// --- rqmembers: начало" и "// --- rqmembers: конец").
# Источники: документация RapidQ (rapidq_ref/html_doc, таблицы Properties,
# Methods, Events) и типы в RqLcl/inc/*.bi.
# Запуск из корня репозитория: python RqLcl/tofb/gen_members.py
import glob, html, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DOC_DIR = os.path.join(ROOT, 'rapidq_ref', 'html_doc')
INC_DIR = os.path.join(ROOT, 'RqLcl', 'inc')
PAS_FILE = os.path.join(ROOT, 'RqLcl', 'tofb', 'RqToFb.pas')
SKIP_MEMBERS = {'SETEVENTEX', 'CALLINTS', 'OPTIONLIST', 'DRAWINTS', 'CALLINT1',
                'ADDONE', 'INSERTAT', 'DELETEAT', 'FINDSORTED', 'CHECKINDEX',
                'QUICKSORT', 'BASEHANDLE', 'READRAW', 'WRITEERROR', 'READBUF',
                'WRITEBUF', 'STREAMSIZE', 'SETSIZE'}
EXTRA = {'QSTRINGGRID': {'ADDOPTIONS': 'M'}}


def doc_classes():
    result = {}
    for file_name in sorted(glob.glob(os.path.join(DOC_DIR, '*.html'))):
        text = open(file_name, encoding='cp1251', errors='replace').read()
        title = re.search(r'Appendix A:\s*([A-Za-z0-9_]+)', re.sub(r'<[^>]+>', ' ', text))
        if not title:
            continue
        members = {}
        section = None
        for part in re.split(r'(?i)(Properties|Methods|Events)\s*</', text):
            low = part.lower()
            if low in ('properties', 'methods', 'events'):
                section = low
                continue
            if section is None:
                continue
            kind = {'properties': 'P', 'methods': 'M', 'events': 'E'}[section]
            for name in re.findall(r'(?is)<TR[^>]*>\s*<TD[^>]*>\s*(?:<b>)?\s*'
                                   r'([A-Za-z_][A-Za-z0-9_$]*)\s*(?:</b>)?\s*</TD>', part):
                if name.upper() not in ('FIELD', 'METHOD', 'EVENT', 'TYPE'):
                    members.setdefault(name.upper(), kind)
            section = None
        result.setdefault(title.group(1).upper(), {}).update(members)
    return result


def bi_classes():
    text = ''
    for file_name in glob.glob(os.path.join(INC_DIR, '*.bi')):
        text += open(file_name, encoding='cp1251').read().replace('\r', '') + '\n'
    types = {}
    for found in re.finditer(r'\nType (\w+)(?: Extends (\w+))?\n(.*?)\nEnd Type', text, re.S):
        members = {}
        for decl in re.finditer(r'Declare (Property|Sub|Function) (\w+)', found.group(3)):
            name = decl.group(2).upper()
            kind = 'E' if name.startswith('ON') else ('P' if decl.group(1) == 'Property' else 'M')
            members.setdefault(name, kind)
        types[found.group(1).upper()] = ((found.group(2) or '').upper(), members)

    def all_members(type_name):
        base, members = types[type_name]
        result = dict(all_members(base)) if base in types else {}
        result.update(members)
        return result
    return {name: all_members(name) for name in types if name.startswith('Q') and name != 'QCONTROL'}


def main():
    classes = doc_classes()
    for name, members in bi_classes().items():
        target = classes.setdefault(name, {})
        for member, kind in members.items():
            if member not in SKIP_MEMBERS:
                target.setdefault(member, kind)
    for name, members in EXTRA.items():
        classes.setdefault(name, {}).update(members)
    chunks = []
    for name in sorted(classes):
        line = name + ':' + ','.join(f'{m}={k}' for m, k in sorted(classes[name].items())) + '|'
        while line:
            chunks.append(line[:180])
            line = line[180:]
    block = ('// Свойства (P), методы (M) и события (E) классов RapidQ - из документации\n'
             '// (rapidq_ref/html_doc) и типов RqLcl/inc/*.bi. Нужен для CREATE ...\n'
             '// END CREATE: какие слова внутри - свойства объекта.\n'
             '// Формат: КЛАСС:ИМЯ=вид,...|\n'
             'const\n  RqClassMembersText =\n' +
             ' +\n'.join("    '" + chunk + "'" for chunk in chunks) + ';\n')
    pas = open(PAS_FILE, encoding='cp1251', newline='').read()
    begin_mark = '// --- rqmembers: начало'
    end_mark = '// --- rqmembers: конец'
    start = pas.index(begin_mark)
    start = pas.index('\n', start) + 1
    stop = pas.index(end_mark)
    pas = pas[:start] + block.replace('\n', '\r\n') + pas[stop:]
    open(PAS_FILE, 'w', encoding='cp1251', newline='').write(pas)
    print(len(classes), 'classes')


main()
