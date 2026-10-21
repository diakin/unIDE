"""Write rapidq_ref/inc/COMPONENTS.md (Russian): components, moved files, decisions.

Usage: python3 -I gen_list.py <repo dir>
"""
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from decisions import OLD, DISPUTED  # noqa: E402

repo = sys.argv[1]
catalog = json.load(open(os.path.join(HERE, 'catalog.json'), encoding='utf-8'))['components']
inv = json.load(open(os.path.join(HERE, 'inv.json'), encoding='utf-8'))
notes = {}
for path in sorted(glob.glob(os.path.join(HERE, 'notes', '*.json'))):
    notes.update(json.load(open(path, encoding='utf-8')))


def cell(text):
    return (text or '').replace('|', '\\|').replace('\n', ' ').strip()


ordered = sorted(catalog, key=lambda entry: (entry['key'], entry['file'].lower()))
lines = []
lines.append('# Компоненты RapidQ в rapidq_ref/inc')
lines.append('')
lines.append('Компоненты, написанные на самом RapidQ (`TYPE Имя EXTENDS Класс`), из файлов этой папки и `object/`. '
             'Описание каждого — страница в `rapidq_ref/html_doc` (Appendix B, оглавление — `html_doc/custom.html`). '
             'Страницы собраны по исходникам: таблицы — открытые (PUBLIC) поля, методы и события из блока TYPE, '
             'значения по умолчанию — из CONSTRUCTOR, описания — по коду и комментариям в нём. Примеры на страницах, '
             'кроме помеченных «from the comments in the source file», написаны по списку членов и не запускались.')
lines.append('')
lines.append('Состояние на 2026-10-08. Работоспособность компонентов не проверялась — это следующий этап.')
lines.append('')
lines.append('## Список (%d)' % len(ordered))
lines.append('')
lines.append('| Компонент | Наследует | Файл | Автор, версия | Описание | Страница |')
lines.append('|---|---|---|---|---|---|')
for entry in ordered:
    note = notes.get(entry['id'], {})
    who = ', '.join(part for part in (note.get('author', ''), note.get('version', '')) if part)
    lines.append('| %s | %s | `%s` | %s | %s | [%s](../html_doc/%s) |' % (
        entry['name'].upper(), entry['base'].upper(), entry['file'], cell(who),
        cell(note.get('summary_ru', '')), entry['page'], entry['page']))
lines.append('')

same = {}
for entry in ordered:
    same.setdefault(entry['key'], []).append(entry)
clashes = {key: items for key, items in same.items() if len(items) > 1}
lines.append('## Одно имя — разные компоненты')
lines.append('')
lines.append('Это не версии одного кода, а разные компоненты с одним именем типа. Подключить два файла с одним '
             'именем в одну программу нельзя.')
lines.append('')
for key, items in sorted(clashes.items()):
    lines.append('- **%s**: %s' % (key, '; '.join('`%s` — %s' % (
        item['file'], cell(notes.get(item['id'], {}).get('summary_ru', ''))) for item in items)))
lines.append('')

lines.append('## Редакции в rapidq2.inc и rapidq.inc')
lines.append('')
lines.append('`rapidq2.inc` (JohnK, версия 1.4k, 2013) и `rapidq.inc` содержат свои редакции части компонентов. '
             'Они остаются в этих файлах; страница описывает отдельный файл, а редакция упомянута в разделе '
             '«Other versions» на ней.')
lines.append('')
for entry in ordered:
    for edition in entry.get('editions', []):
        extra = ', '.join(edition['extra_members'])
        lines.append('- %s: `%s`, строка %d%s' % (entry['name'].upper(), edition['file'], edition['line'],
                                                 ('; есть только там: ' + extra) if extra else ''))
lines.append('')

lines.append('## Перенесены в inc/old (файлов: %d)' % len(OLD))
lines.append('')
lines.append('Правило: оставлена последняя версия — по номеру версии или дате в заголовке, по имени файла '
             '(QTButton95 > 94b > 94), по признакам в коде; из точных копий остаётся одна (в `inc/`, кроме тех, '
             'что RQdebugger подключает как `Object\\...`). Файлы, которые подключаются из исходников в репозитории '
             '(RQdebugger844-40.bas, RQFormDsg2026-7.bas, DataParser15.bas, $DbgDisplay.bas, include других '
             'файлов), не переносились. `RqDataBuild` папку `old` пропускает.')
lines.append('')
lines.append('| Файл в inc/old | Компонент | Оставлен | Причина |')
lines.append('|---|---|---|---|')
for old_file, (comp, kept, reason) in sorted(OLD.items(), key=lambda pair: (pair[1][0], pair[0].lower())):
    lines.append('| `%s` | %s | `%s` | %s |' % (old_file, comp, kept, cell(reason)))
lines.append('')

lines.append('## Выбор по косвенным признакам')
lines.append('')
lines.append('Здесь версию нельзя было определить по номеру или дате. При необходимости файлы можно поменять местами (git mv).')
lines.append('')
for key, text in sorted(DISPUTED.items()):
    lines.append('- **%s**: %s' % (key, text))
lines.append('')

no_comp = [item['file'] for item in inv if not item['components']]
lines.append('## Что не трогалось')
lines.append('')
lines.append('- Файлы без компонентов (объявления Windows API, константы, функции) — %d файлов. Среди них тоже есть '
             'старые варианты (`Files1.inc`, `Files2.inc`, `FilesBug.inc`, `conversionOld.inc`, `RAPIDQl.INC`, '
             '`RAPIDQbug.INC`, `rapidq2007.inc`, `rapidq_ex.inc`), но они вне этого списка.' % len(no_comp))
lines.append('- `rapidq_ref/ComponentAll.data` не пересобирался: полная пересборка `RqDataBuild` меняет и другие части '
             'файла (убирает комментарии в начале), а для QINI взяла бы `QWinIni.inc` (другой компонент). В нём у '
             'части классов строка `\'@source` указывает на файлы, которые теперь в `old` (QTButton.inc, QAbout.inc, '
             'qposic.inc и др.); она только показывается в подсказке конструктора.')
lines.append('')

out_path = os.path.join(repo, 'rapidq_ref', 'inc', 'COMPONENTS.md')
open(out_path, 'w', encoding='utf-8', newline='\r\n').write('\n'.join(lines))
print('written', out_path, len(lines), 'lines')
