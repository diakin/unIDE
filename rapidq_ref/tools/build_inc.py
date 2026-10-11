#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Сборка системных inc RapidQ из rapidq_ref/inc_good по плану
rapidq_ref/inc_merge_plan.md (см. rapidq_ref/inc_about.md):

  inc_sys/rapidqAllProc.inc     - константы, DECLARE, процедуры;
  inc_sys/rapidqComponents.inc  - компоненты (TYPE ... EXTENDS), подключает
                                  rapidqAllProc.inc сам;
  inc_sys/build_report.md       - что убрано как повтор, что расходится.

Каждое имя объявляется один раз: повтор (CONST, $DEFINE, DECLARE, TYPE,
SUB/FUNCTION, глобальный DIM/DEFxxx, CREATE) превращается в комментарий
'~dup с местом первого объявления. Первым считается объявление в файле,
который идёт раньше: rapidq2.inc, rapidq.inc, затем остальные по алфавиту;
у компонентов - выбранная по плану версия раньше прочих.

Исходные файлы не меняются. Запуск: python3 build_inc.py (из любой папки).
"""
import os
import re
import collections

HERE = os.path.dirname(os.path.abspath(__file__))
REF = os.path.dirname(HERE)
SRC = os.path.join(REF, 'inc_good')
OUT = os.path.join(REF, 'inc_sys')
PLAN = os.path.join(REF, 'inc_merge_plan.md')

# Варианты rapidq*.inc: в общий файл идут rapidq2.inc и rapidq.inc; rapidq3.inc
# - копия rapidq.inc, остальные - старые версии (cm* номерами 0..14 и т.п.)
RQ_MAIN = ['rapidq2.inc', 'rapidq.inc']
RQ_SKIP = ['rapidq3.inc', 'rapidqbug.inc', 'rapidql.inc', 'rapidq2007.inc',
           'rapidq_ex.inc']


def read_lines(path):
    data = open(path, 'rb').read().decode('cp1251')
    return data.replace('\r\n', '\n').replace('\r', '\n').split('\n')


def code_part(line):
    """Строка без комментария ' (вне кавычек) и без REM."""
    out = []
    in_str = False
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


def parse_plan():
    text = open(PLAN, encoding='utf-8').read().split('\n')
    chosen = {}          # класс (верхний регистр) -> выбранный файл
    take = {}            # файл (нижний регистр) -> 'да' / '?'
    section = 0
    for line in text:
        m = re.match(r'## (\d)\.', line)
        if m:
            section = int(m.group(1))
            continue
        if not line.startswith('| ') or line.startswith('|---'):
            continue
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if section == 1 and len(cells) == 3 and cells[0] != 'Класс':
            chosen[cells[0].upper()] = cells[2]
        elif section in (2, 3) and cells[0] != 'Файл':
            take[cells[0].lower()] = cells[-1]
    return chosen, take


# ---------------------------------------------------------------------------
#  Разбор файла на единицы: строка или блок (TYPE, SUB, DECLARE с "_" ...)
# ---------------------------------------------------------------------------

Unit = collections.namedtuple('Unit', 'first last key names text')


def split_units(lines):
    """Список Unit. key - вид объявления ('T','P','D','C','M','V') или None;
    names - имена (верхний регистр); text - нормализованный текст для
    сравнения повторов."""
    units = []
    idx = 0
    count = len(lines)
    while idx < count:
        code = code_part(lines[idx])
        low = code.lower()
        first = idx

        def block(end_re, nest_re=None):
            nonlocal idx
            depth = 1
            while idx + 1 < count:
                idx += 1
                inner = code_part(lines[idx])
                if nest_re and re.match(nest_re, inner, re.I):
                    depth += 1
                elif re.match(end_re, inner, re.I):
                    depth -= 1
                    if depth == 0:
                        break

        def norm(a, b):
            return re.sub(r'\s+', ' ', ' '.join(code_part(l) for l in lines[a:b + 1])).strip().upper()

        code = re.sub(r'^(?:private|public)\s+(?=(type|declare|const|sub|function)\b)', '', code,
                      flags=re.I)
        m = re.match(r'type\s+(\w+)', code, re.I)
        if m and not re.match(r'type\s+\w+\s+as\s', code, re.I) and \
                not re.match(r'type\s*\(', code, re.I):
            block(r'end\s+type\b')
            units.append(Unit(first, idx, 'T', [m.group(1).upper()], norm(first, idx)))
            idx += 1
            continue
        m = re.match(r'(sub|function|subi|functioni)\s+(\w+(?:\.\w+)?[\$%&!#]?)', code, re.I)
        if m:
            block(r'end\s+(sub|function)\b')
            units.append(Unit(first, idx, 'P', [m.group(2).upper()], norm(first, idx)))
            idx += 1
            continue
        m = re.match(r'declare\s+(sub|function|subi|functioni)\s+(\w+(?:\.\w+)?[\$%&!#]?)', code, re.I)
        if m:
            while code_part(lines[idx]).rstrip().endswith('_') and idx + 1 < count:
                idx += 1
            units.append(Unit(first, idx, 'D', [m.group(2).upper()], norm(first, idx)))
            idx += 1
            continue
        m = re.match(r'create\s+(\w+)\s+as\s', code, re.I)
        if m:
            block(r'end\s+create\b', r'create\s+\w+\s+as\s')
            units.append(Unit(first, idx, 'V', [m.group(1).upper()], norm(first, idx)))
            idx += 1
            continue
        m = re.match(r'const\s+(\w+[\$%&!#]?)\s*(?:as\s+\w+\s*)?=\s*(.*)$', code, re.I)
        if m:
            while code_part(lines[idx]).rstrip().endswith('_') and idx + 1 < count:
                idx += 1
            units.append(Unit(first, idx, 'C', [m.group(1).upper()], norm(first, idx)))
            idx += 1
            continue
        m = re.match(r'[\$#]define\s+(\w+)\s*(.*)$', code, re.I)
        if m:
            units.append(Unit(first, idx, 'M', [m.group(1).upper()],
                              re.sub(r'\s+', ' ', m.group(2)).strip().upper()))
            idx += 1
            continue
        m = re.match(r'(dim|defint|deflng|defstr|defdbl|defsng|defbyte|defword|defdword|defshort)\s+(.*)$',
                     code, re.I)
        if m:
            rest = m.group(2)
            while code_part(lines[idx]).rstrip().endswith('_') and idx + 1 < count:
                rest = rest.rstrip().rstrip('_') + ' '
                idx += 1
                rest += code_part(lines[idx])
            names = []
            for part in split_top(rest):
                nm = re.match(r'\s*(\w+[\$%&!#]?)', part)
                if nm and nm.group(1).upper() not in ('SHARED',):
                    names.append(nm.group(1).upper())
            units.append(Unit(first, idx, 'V', names, norm(first, idx)))
            idx += 1
            continue
        units.append(Unit(first, idx, None, [], ''))
        idx += 1
    return units


# Внутренние процедуры файла с короткими именами, которые в общей сборке
# совпадают с переменными других файлов и программ (QXLS.INC: DIM F AS
# QFileStream при FUNCTION F из CMD5.inc). В сборке - с приставкой; снаружи
# файла их никто не вызывает (проверено поиском по inc_good).
RENAMES = {'cmd5.inc': ('MD5_', ['F', 'G', 'H', 'FF', 'GG', 'HH', 'II'])}


def rename_words(line, prefix, names):
    """Слова names в коде строки (вне строк в кавычках и комментария) - с
    приставкой prefix; не после точки."""
    pat = re.compile(r'(?<![\w.])(' + '|'.join(names) + r')(?![\w$%&!#])', re.I)
    out, buf, in_str = [], '', False
    idx = 0
    while idx < len(line):
        ch = line[idx]
        if ch == '"':
            if not in_str:
                out.append(pat.sub(lambda m: prefix + m.group(1), buf))
                buf = ''
            in_str = not in_str
            out.append(ch)
        elif ch == "'" and not in_str:
            break
        elif in_str:
            out.append(ch)
        else:
            buf += ch
        idx += 1
    out.append(pat.sub(lambda m: prefix + m.group(1), buf))
    return ''.join(out) + line[idx:]


TYPE_WORDS = ('INTEGER', 'LONG', 'SHORT', 'BYTE', 'WORD', 'DWORD', 'STRING', 'DOUBLE',
              'SINGLE')


def strip_strings(code):
    return re.sub(r'"[^"]*"?', '""', code)


def local_type_defines(seq):
    """$DEFINE имени типом (createWind.inc: $DEFINE HWND INTEGER) действует
    на все файлы ниже по сборке: у них hWnd - имя параметра, и после замены
    получается INTEGER. seq - [(файл, строки, keep)] в порядке сборки.
    Результат: {(файл, ИМЯ): причина} - такие $DEFINE снимаются $UNDEF в
    конце своего файла; и список [(файл, ИМЯ, причина)] неразрешённых
    (ниже есть и такое имя, и "AS ИМЯ" без своего $DEFINE)."""
    codes = []
    for fname, lines, keep in seq:
        code = [strip_strings(code_part(l)) for num, l in enumerate(lines)
                if keep is None or keep(num)]
        codes.append((fname, code))
    local, unresolved = {}, []
    for pos, (fname, code) in enumerate(codes):
        for line in code:
            m = re.match(r'[\$#]define\s+(\w+)\s+(\w+)\s*$', line, re.I)
            if not m or m.group(2).upper() not in TYPE_WORDS:
                continue
            name = m.group(1)
            if (fname, name.upper()) in local:
                continue
            # файл сам снимает (WIN32API.INC: $UNDEF TRUE, FALSE, ANY, INTEGER)
            if any(re.match(r'\$undef\b.*\b' + re.escape(name) + r'\b', l, re.I) for l in code):
                continue
            word = re.compile(r'(?<![\w.])' + re.escape(name) + r'(?![\w$%&!#])', re.I)
            as_use = re.compile(r'\bas\s+' + re.escape(name) + r'\b', re.I)
            own_def = re.compile(r'[\$#](define|undef|ifdef|ifndef)\s+' + re.escape(name) + r'\b', re.I)
            bad, needs = None, None
            for other, ocode in codes[pos + 1:]:
                defines_it = any(own_def.match(l) for l in ocode)
                for num, l in enumerate(ocode):
                    if own_def.match(l):
                        continue
                    if as_use.search(l) and not defines_it and needs is None:
                        needs = '%s(%d)' % (other, num + 1)
                    if word.search(as_use.sub('', l)) and bad is None:
                        bad = '%s(%d): %s' % (other, num + 1, l[:60])
            if bad and not needs:
                local[(fname, name.upper())] = bad
            elif bad:
                unresolved.append((fname, name, bad + '; AS ' + name + ': ' + needs))
    return local, unresolved


def line_keep(take_val):
    """'да, строки 1-228' в плане - из файла берутся только эти строки
    (дальше пример программы). Функция от номера строки с 0 или None."""
    m = re.search(r'строки\s+(\d+)\s*-\s*(\d+)', take_val)
    if not m:
        return None
    first, last = int(m.group(1)) - 1, int(m.group(2)) - 1
    return lambda num: first <= num <= last


def split_top(text):
    parts, depth, cur = [], 0, ''
    in_str = False
    for ch in text:
        if ch == '"':
            in_str = not in_str
        if not in_str:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            elif ch == ',' and depth == 0:
                parts.append(cur)
                cur = ''
                continue
        cur += ch
    parts.append(cur)
    return parts


# ---------------------------------------------------------------------------
#  rapidq2.inc: разделы компонентов
# ---------------------------------------------------------------------------

def rapidq2_component_ranges(lines):
    """Диапазоны строк (с 0) разделов компонентов rapidq2.inc: блок
    $IFNDEF __X_INC ... $ENDIF (не _SA) и TYPE ... EXTENDS вне таких блоков."""
    ranges = []
    idx = 0
    count = len(lines)
    while idx < count:
        code = code_part(lines[idx])
        if re.match(r'\$ifndef\s+__\w+_INC\s*$', code, re.I):
            start = idx
            depth = 1
            while idx + 1 < count and depth > 0:
                idx += 1
                inner = code_part(lines[idx])
                if re.match(r'\$if', inner, re.I):
                    depth += 1
                elif re.match(r'\$endif\b', inner, re.I):
                    depth -= 1
            ranges.append((start, idx))
        elif re.match(r'type\s+\w+\s+extends\s+\w+', code, re.I):
            start = idx
            while idx + 1 < count and not re.match(r'end\s+type\b', code_part(lines[idx]), re.I):
                idx += 1
            ranges.append((start, idx))
        idx += 1
    return ranges


# ---------------------------------------------------------------------------
#  Сборка
# ---------------------------------------------------------------------------

class Builder:
    def __init__(self, all_files):
        self.seen = {}           # (вид, имя) -> (файл, строка, текст)
        self.report_dup = collections.Counter()
        self.report_diff = []    # расходящиеся повторы
        self.report_inc = []     # $INCLUDE, которые остались
        self.report_dir = []     # директивы, на которые стоит посмотреть
        self.report_conflict = []  # процедура и DECLARE LIB с одним именем
        self.lib_seen = {}       # имя DECLARE ... LIB -> (файл, строка)
        self.local_defines = {}  # (файл, ИМЯ) -> причина (local_type_defines)
        self.all_files = all_files   # файлы, которые вошли в сборку (нижний регистр)

    def key_kind(self, kind):
        # DECLARE и тело одной процедуры - разные объявления
        return kind

    def emit_file(self, name, lines, keep=None, out=None):
        """Строки файла name в out; keep(номер строки) - брать ли строку."""
        out.append("'" + '=' * 76)
        out.append("'[build_inc] %s" % name)
        out.append("'" + '=' * 76)
        typecheck_on = False
        escape_on = False
        for unit in split_units(lines):
            if keep is not None and not keep(unit.first):
                continue
            block = lines[unit.first:unit.last + 1]
            dup_of = None
            # Имя процедуры одного файла и DECLARE ... LIB с тем же именем
            # другого (Files.inc: FUNCTION LoadString(FileName), WIN32API.INC:
            # DECLARE FUNCTION LoadString LIB "user32") - остаётся первое
            if unit.key in ('P', 'D') and unit.names:
                nm = unit.names[0]
                is_lib = unit.key == 'D' and re.search(r'\blib\b', unit.text, re.I)
                prev = None
                if is_lib:
                    prev = self.seen.get(('P', nm))
                elif unit.key == 'P':
                    prev = self.lib_seen.get(nm)
                if prev and prev[0] != name:
                    self.report_conflict.append((nm, prev[0], prev[1], name, unit.first + 1))
                    for pos, line in enumerate(block):
                        note = ''
                        if pos == 0:
                            note = "   ' сборка: имя занято, первое: %s(%d)" % (prev[0], prev[1])
                        out.append("'~conflict " + line + note)
                    continue
                if is_lib and nm not in self.lib_seen:
                    self.lib_seen[nm] = (name, unit.first + 1)
            if unit.key and unit.names:
                # Повтор внутри одного исходного файла остаётся как был
                # (rapidq2.inc: $DEFINE Boolean byte, ниже $DEFINE BOOLEAN LONG)
                hits = [(n, self.seen.get((unit.key, n))) for n in unit.names]
                hits = [(n, h if (h is None or h[0] != name) else None) for n, h in hits]
                if any(h for _, h in hits) and not all(h for _, h in hits) and \
                        unit.key == 'V' and re.match(r'(dim|def\w+)\s', code_part(block[0]), re.I):
                    # Часть имён уже объявлена - DIM без них
                    joined = ' '.join(code_part(l).rstrip().rstrip('_') for l in block)
                    kw = re.match(r'(\w+)\s+(.*)$', joined)
                    kept, gone = [], []
                    for part in split_top(kw.group(2)):
                        nm = re.match(r'\s*(\w+[\$%&!#]?)', part)
                        nmu = nm.group(1).upper() if nm else ''
                        prev = self.seen.get(('V', nmu))
                        if prev and prev[0] != name:
                            gone.append(nmu)
                            self.report_dup['V'] += 1
                        else:
                            kept.append(part.strip())
                            if nmu and not prev:
                                self.seen[('V', nmu)] = (name, unit.first + 1, unit.text)
                    for line in block:
                        out.append("'~dup " + line)
                    out.append('%s %s   \' сборка: без уже объявленных %s' % (kw.group(1), ', '.join(kept),
                                                                       ', '.join(gone)))
                    continue
                if all(h for _, h in hits):
                    dup_of = hits[0][1]
                    for nm, prev in hits:
                        self.report_dup[unit.key] += 1
                        if unit.key in ('C', 'M', 'P', 'D', 'T') and prev[2] != unit.text:
                            self.report_diff.append((unit.key, nm, prev[0], prev[1],
                                                     name, unit.first + 1, prev[2], unit.text))
                else:
                    for nm, prev in hits:
                        if prev is None:
                            self.seen[(unit.key, nm)] = (name, unit.first + 1, unit.text)
            if dup_of:
                for pos, line in enumerate(block):
                    note = ''
                    if pos == 0:
                        note = "   ' повтор, первое: %s(%d)" % (dup_of[0], dup_of[1])
                    out.append("'~dup " + line + note)
                continue
            for line in block:
                code = code_part(line)
                low = code.lower()
                m = re.match(r'\$include\s*["<]([^">]+)[">]', code, re.I)
                if m:
                    target = os.path.basename(m.group(1).replace('\\', '/')).lower()
                    if target in self.all_files or target in self.skipped:
                        out.append("'~inc " + line + "   ' уже в сборке или заменён выбранной версией")
                    else:
                        out.append(line)
                        self.report_inc.append((name, m.group(1)))
                    continue
                m = re.match(r'\$undef\s+(.*)$', code, re.I)
                if m:
                    # $UNDEF имени, которое объявил другой файл, в общей сборке
                    # сняло бы его для всех следующих (WIN32API.INC в конце:
                    # $UNDEF TRUE, FALSE, ANY, INTEGER). Такие имена не снимаем;
                    # снятое своё имя можно объявить снова.
                    keep_names, foreign = [], []
                    for part in m.group(1).split(','):
                        nmu = part.strip().upper()
                        if not nmu:
                            continue
                        prev = self.seen.get(('M', nmu))
                        if prev and prev[0] != name:
                            foreign.append(part.strip())
                        else:
                            keep_names.append(part.strip())
                            if prev:
                                del self.seen[('M', nmu)]
                    if foreign:
                        indent = line[:len(line) - len(line.lstrip())]
                        out.append("'~undef " + line + "   ' сборка: %s объявлены другим файлом"
                                   % ', '.join(foreign))
                        if keep_names:
                            out.append(indent + '$UNDEF ' + ', '.join(keep_names))
                        self.report_dir.append((name, code))
                        continue
                if re.match(r'\$typecheck\s+on\b', low) or re.match(r'\$option\s+explicit\b', low):
                    typecheck_on = True
                elif re.match(r'\$typecheck\s+off\b', low):
                    typecheck_on = False
                if re.match(r'\$escapechars\s+on\b', low):
                    escape_on = True
                elif re.match(r'\$escapechars\s+off\b', low):
                    escape_on = False
                if re.match(r'\$(apptype|option\s+icon|resource)\b', low):
                    self.report_dir.append((name, code))
                out.append(line)
        # $DEFINE имени типом, которое ниже по сборке - имя переменной
        # (local_type_defines): только для своего файла
        for (fname, nmu), why in sorted(self.local_defines.items()):
            if fname == name:
                out.append("$UNDEF %s   ' сборка: ниже это имя переменной, %s" % (nmu, why))
        # Режимы, включённые файлом, не должны действовать на следующие
        if typecheck_on:
            out.append("$TYPECHECK OFF   ' сборка: вернуть после %s" % name)
        if escape_on:
            out.append("$ESCAPECHARS OFF   ' сборка: вернуть после %s" % name)


def main():
    chosen, take = parse_plan()
    files = sorted((f for f in os.listdir(SRC) if re.search(r'\.(inc|cmp)$', f, re.I)),
                   key=str.lower)
    by_low = {f.lower(): f for f in files}
    texts = {f: read_lines(os.path.join(SRC, f)) for f in files}
    renamed = []
    for f in files:
        if f.lower() in RENAMES:
            prefix, names = RENAMES[f.lower()]
            texts[f] = [rename_words(l, prefix, names) for l in texts[f]]
            renamed.append('%s: %s -> %s...' % (f, ', '.join(names), prefix))

    classes = {}
    for f in files:
        classes[f] = [(m.group(1), m.group(2)) for m in
                      (re.match(r'\s*type\s+(\w+)\s+extends\s+(\w+)', l, re.I) for l in texts[f]) if m]

    # Компоненты: выбранная версия класса раньше; файл, все классы которого
    # уступили выбранной версии другого файла, не берётся
    comp_files, skipped = [], set()
    why = {}
    for f in files:
        low = f.lower()
        if low in RQ_MAIN or low in RQ_SKIP or not classes[f]:
            continue
        if not take.get(low, 'да').startswith('да'):
            skipped.add(low)
            why[low] = take[low]
            continue
        lost = [c for c, _ in classes[f] if c.upper() in chosen and chosen[c.upper()].lower() != low]
        if len(lost) == len(classes[f]):
            skipped.add(low)
            why[low] = 'взята другая версия: ' + ', '.join(
                '%s - %s' % (c, chosen[c.upper()]) for c in lost)
            continue
        comp_files.append(f)
    # Базовый класс из другого файла - тот файл раньше
    owner = {}
    for f in comp_files:
        for c, _ in classes[f]:
            owner.setdefault(c.upper(), f)
    ordered, done = [], set()

    def place(f, stack=()):
        if f in done or f in stack:
            return
        for _, base in classes[f]:
            dep = owner.get(base.upper())
            if dep and dep != f:
                place(dep, stack + (f,))
        done.add(f)
        ordered.append(f)
    first_files = [f for f in comp_files if any(chosen.get(c.upper(), '').lower() == f.lower()
                                                 for c, _ in classes[f])]
    for f in first_files + [f for f in comp_files if f not in first_files]:
        place(f)

    proc_files = []
    for f in files:
        low = f.lower()
        if low in RQ_MAIN or low in RQ_SKIP or classes[f]:
            continue
        if not take.get(low, 'да').startswith('да'):
            skipped.add(low)
            why[low] = take[low]
            continue
        proc_files.append(f)
    for low in RQ_SKIP:
        skipped.add(low)
        why[low] = 'копия rapidq.inc' if low == 'rapidq3.inc' else 'старая версия rapidq.inc'
    for low in why:
        if why[low] == '?':
            why[low] = 'в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно'

    all_files = set(f.lower() for f in proc_files + ordered + [by_low[x] for x in RQ_MAIN])
    builder = Builder(all_files)
    builder.skipped = skipped

    rq2 = by_low['rapidq2.inc']
    comp_ranges = rapidq2_component_ranges(texts[rq2])
    in_comp = set()
    for a, b in comp_ranges:
        in_comp.update(range(a, b + 1))

    order = [(rq2, texts[rq2], lambda n: n not in in_comp),
             (by_low['rapidq.inc'], texts[by_low['rapidq.inc']], None)]
    order += [(f, texts[f], line_keep(take.get(f.lower(), 'да'))) for f in proc_files]
    order += [(rq2 + ' (компоненты)', texts[rq2], lambda n: n in in_comp)]
    order += [(f, texts[f], line_keep(take.get(f.lower(), 'да'))) for f in ordered]
    builder.local_defines, unresolved_defines = local_type_defines(order)

    head = ["' rapidqAllProc.inc - константы, DECLARE и процедуры RapidQ одним файлом.",
            "' Собран rapidq_ref/tools/build_inc.py из rapidq_ref/inc_good по",
            "' rapidq_ref/inc_merge_plan.md. Не правьте вручную - правьте исходные",
            "' файлы или план и соберите заново. Повторы - '~dup, с местом первого.",
            "$IFNDEF __RQALLPROC_INC",
            "$DEFINE __RQALLPROC_INC"]
    out = list(head)
    builder.emit_file(rq2, texts[rq2], keep=lambda n: n not in in_comp, out=out)
    builder.emit_file(by_low['rapidq.inc'], texts[by_low['rapidq.inc']], out=out)
    for f in proc_files:
        builder.emit_file(f, texts[f], keep=line_keep(take.get(f.lower(), 'да')), out=out)
    out.append("$ENDIF ' __RQALLPROC_INC")
    write(os.path.join(OUT, 'rapidqAllProc.inc'), out)

    out = ["' rapidqComponents.inc - компоненты RapidQ (TYPE ... EXTENDS) одним файлом.",
           "' Собран rapidq_ref/tools/build_inc.py; подключает rapidqAllProc.inc.",
           "' Не правьте вручную - правьте исходные файлы или план и соберите заново.",
           "$IFNDEF __RQCOMPONENTS_INC",
           "$DEFINE __RQCOMPONENTS_INC",
           '$INCLUDE "rapidqAllProc.inc"']
    builder.emit_file(rq2 + ' (компоненты)', texts[rq2], keep=lambda n: n in in_comp, out=out)
    for f in ordered:
        builder.emit_file(f, texts[f], keep=line_keep(take.get(f.lower(), 'да')), out=out)
    out.append("$ENDIF ' __RQCOMPONENTS_INC")
    write(os.path.join(OUT, 'rapidqComponents.inc'), out)

    # Отчёт
    rep = ['# Сборка rapidqAllProc.inc и rapidqComponents.inc', '',
           'Собрано rapidq_ref/tools/build_inc.py из inc_good по inc_merge_plan.md.', '',
           '## Состав', '',
           '- rapidqAllProc.inc: rapidq2.inc (без разделов компонентов), rapidq.inc, '
           'и %d файлов: %s' % (len(proc_files), ', '.join(proc_files)),
           '- rapidqComponents.inc: разделы компонентов rapidq2.inc и %d файлов: %s'
           % (len(ordered), ', '.join(ordered)),
           '- не вошли: %d файлов (ниже)' % len(skipped), '']
    cut = [(f, take[f.lower()]) for f in ordered + proc_files if line_keep(take.get(f.lower(), 'да'))]
    if cut:
        rep += ['## Взята часть файла', '']
        rep += ['- %s: %s' % (f, v[len('да, '):]) for f, v in cut]
        rep.append('')
    rep += ['## Не вошли', '', '| Файл | Почему |', '|---|---|']
    rep += ['| %s | %s |' % (by_low.get(x, x), why.get(x, '').replace('|', '\\|'))
            for x in sorted(skipped)]
    if renamed:
        rep += ['', '## Переименовано в сборке', '',
                'Внутренние процедуры с короткими именами (совпадали с переменными '
                'других файлов: QXLS.INC DIM F AS QFileStream):', '']
        rep += ['- ' + r for r in renamed]
    if builder.local_defines or unresolved_defines:
        rep += ['', '## $DEFINE имени типом - только для своего файла', '',
                'Имя ниже по сборке - имя переменной или параметра; в конце файла '
                '$UNDEF.', '', '| Файл | Имя | Где ниже |', '|---|---|---|']
        rep += ['| %s | %s | %s |' % (f, n, w.replace('|', '\\|'))
                for (f, n), w in sorted(builder.local_defines.items())]
        if unresolved_defines:
            rep += ['', 'Не снято (ниже нужно и как тип):', '']
            rep += ['- %s: %s - %s' % u for u in unresolved_defines]
    if builder.report_conflict:
        rep += ['', '## Одно имя у процедуры и у DECLARE ... LIB (оставлено первое)', '',
                '| Имя | Оставлено | Закомментировано |', '|---|---|---|']
        rep += ['| %s | %s(%d) | %s(%d) |' % c for c in builder.report_conflict]
    rep += ['',
           '## Убрано как повтор', '']
    names = {'C': 'CONST', 'M': '$DEFINE', 'D': 'DECLARE', 'P': 'SUB/FUNCTION', 'T': 'TYPE',
             'V': 'DIM/DEFxxx/CREATE'}
    for k, v in sorted(builder.report_dup.items()):
        rep.append('- %s: %d' % (names[k], v))
    rep += ['', '## Повторы с другим текстом (оставлено первое)', '',
            '| Вид | Имя | Оставлено | Убрано |', '|---|---|---|---|']
    for kind, nm, f1, l1, f2, l2, t1, t2 in builder.report_diff:
        short1 = t1[:80].replace('|', '\\|')
        short2 = t2[:80].replace('|', '\\|')
        rep.append('| %s | %s | %s(%d): `%s` | %s(%d): `%s` |' % (names[kind], nm, f1, l1, short1,
                                                              f2, l2, short2))
    rep += ['', '## $INCLUDE файлов, которых нет в сборке (остались как есть)', '']
    for f, inc in builder.report_inc:
        rep.append('- %s: %s' % (f, inc))
    rep += ['', '## Директивы, на которые стоит посмотреть', '']
    for f, code in builder.report_dir:
        rep.append('- %s: `%s`' % (f, code))
    open(os.path.join(OUT, 'build_report.md'), 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
    print('proc files', len(proc_files), 'comp files', len(ordered), 'skipped', len(skipped))
    print('dups', dict(builder.report_dup), 'diffs', len(builder.report_diff),
          'includes left', len(builder.report_inc))


def write(path, lines):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = '\r\n'.join(lines) + '\r\n'
    open(path, 'wb').write(data.encode('cp1251'))


if __name__ == '__main__':
    main()
