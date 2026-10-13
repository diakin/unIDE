#!/usr/bin/env python3
"""Папка rapidq_ref/RQInc - набор inc, который ставится с unIDE (IDE Options -
Compilers - RapidQ Basic, поле Include UnIde).

Состав:
- файлы incOld (*.inc, *.cmp) без ошибок проверки INC Manager (IncCheck.pas,
  CheckLines: блоки, директивы без $, числа из C, CONST без =, ";" вне
  строки, $UNDEF/$DEFINE и TYPE с именем встроенного класса) - под своими
  именами, без изменений: старые программы собираются как раньше;
- из inc_sys: RQProc.inc, RQControls.inc и отдельные файлы
  *_sys.* (build_inc.py пишет их с _sys, чтобы не совпадать с именами incOld).

Файлы с ошибками - в EXCLUDE (проверка 2026-10-12, INC Manager на папке
incOld). Чтобы взять файл несмотря на замечания - внести его в ALLOW.
Отчёт - rapidq_ref/RQInc.md. Запуск: python3 build_standard.py.
Папка RQInc пишется заново (старые файлы в ней удаляются).
"""
import os
import shutil

HERE = os.path.dirname(os.path.abspath(__file__))
REF = os.path.normpath(os.path.join(HERE, '..'))
OLD = os.path.join(REF, 'incOld')
SYS = os.path.join(REF, 'inc_sys')
OUT = os.path.join(REF, 'RQInc')
REPORT = os.path.join(REF, 'RQInc.md')

# Файл incOld: что нашла проверка INC Manager (ошибки)
EXCLUDE = {
    'API_RichEdid.inc': 'незакрытые/перепутанные блоки (21); строки 56, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 138 ...',
    'cgi.inc': 'незакрытые/перепутанные блоки (2); строки 64, 137',
    'commctrl32.inc': 'числа с суффиксом U/L из C (4); CONST без = (5); строки 239, 240, 241, 242, 478, 479, 480, 481, 482',
    'cREdit.inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 206, 207',
    'Files1.inc': 'незакрытые/перепутанные блоки (1); строки 747',
    'glaux.inc': 'незакрытые/перепутанные блоки (2); строки 193, 196',
    'HiLight.inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 139, 140',
    'keys.inc': 'DEFINE без $ (46); строки 37, 38, 39, 67, 68, 69, 70, 71, 72, 73, 74, 75 ...',
    'qEditEx.inc': '$UNDEF/$DEFINE встроенного класса QEDIT (2); строки 68, 69',
    'qfocus.inc': 'незакрытые/перепутанные блоки (3); строки 63, 221, 299',
    'qmaxedit.inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 91, 92',
    'QRedEx.Inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 572, 573',
    'QREDEXTest.INC': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 611, 612',
    'qREdit.inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 206, 207',
    'QTextEdit.inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 224, 225',
    'QTextEditTest.inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 71, 72',
    'QThread.inc': 'TYPE с именем встроенного класса (1); строки 50',
    'QxEdit.inc': '$UNDEF/$DEFINE встроенного класса QEDIT (2); строки 70, 71',
    'RichEditApi.inc': '";" вне строки (3); строки 7, 227, 375',
    'RichEdPopUp.inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 137, 138',
    'RichEdPopUp1.inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 124, 125',
    'RichEdPopUpold.inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 149, 150',
    'TstRichEd.inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 13, 14',
    'ultraRichEd.inc': '$UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 206, 207',
    'vfw2.inc': 'незакрытые/перепутанные блоки (1); строки 854',
}

# Взять, несмотря на EXCLUDE (имя файла, регистр не важен)
ALLOW = set()


def main():
    allow = {name.lower() for name in ALLOW}
    exclude = {name.lower(): why for name, why in EXCLUDE.items()
               if name.lower() not in allow}
    if os.path.isdir(OUT):
        for name in os.listdir(OUT):
            path = os.path.join(OUT, name)
            if os.path.isfile(path):
                os.remove(path)
    else:
        os.makedirs(OUT)
    taken_old, skipped, taken_sys = [], [], []
    for name in sorted(os.listdir(OLD), key=str.lower):
        if os.path.splitext(name)[1].lower() not in ('.inc', '.cmp'):
            continue
        if name.lower() in exclude:
            skipped.append(name)
            continue
        shutil.copyfile(os.path.join(OLD, name), os.path.join(OUT, name))
        taken_old.append(name)
    have = {name.lower() for name in taken_old}
    for name in sorted(os.listdir(SYS), key=str.lower):
        low = name.lower()
        if os.path.splitext(low)[1] not in ('.inc', '.cmp'):
            continue
        if low not in ('rqproc.inc', 'rqcontrols.inc') and \
           not os.path.splitext(low)[0].endswith('_sys'):
            continue
        if low in have:
            raise SystemExit('inc_sys/%s: такое имя уже взято из incOld' % name)
        shutil.copyfile(os.path.join(SYS, name), os.path.join(OUT, name))
        taken_sys.append(name)

    rep = ['# Папка RQInc', '',
           'Собрана `rapidq_ref/tools/build_standard.py`. Набор inc, который ставится '
           'с unIDE: IDE Options - Compilers - RapidQ Basic, поле Include UnIde. '
           'Свои inc пользователя - поле Include User; какую папку берёт проект - '
           'Project Properties.', '',
           '- из `incOld` без изменений: %d файлов (без ошибок проверки INC Manager);' % len(taken_old),
           '- из `inc_sys`: %d файлов: %s;' % (len(taken_sys), ', '.join(taken_sys)),
           '- не взяты: %d файлов incOld с ошибками (ниже).' % len(skipped), '',
           'Старая программа подключает файлы incOld под прежними именами. Новая - '
           '`RQControls.inc` (он подключает `RQProc.inc`) и при '
           'необходимости отдельные файлы `*_sys.inc`. Отдельный файл `*_sys` сам '
           'подключает `RQControls.inc`, поэтому вместе со старым '
           '`RAPIDQ.INC` его не подключают.', '',
           '## Не взяты', '',
           'Чтобы взять файл - внести имя в `ALLOW` в build_standard.py и собрать '
           'заново, или исправить файл в incOld.', '',
           '| Файл | Что нашла проверка |', '|---|---|']
    for name in skipped:
        rep.append('| %s | %s |' % (name, exclude[name.lower()]))
    open(REPORT, 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
    print('incOld', len(taken_old), 'inc_sys', len(taken_sys), 'skipped', len(skipped))


if __name__ == '__main__':
    main()
