# RqToFb — перевод исходников RapidQ в FreeBASIC

Препроцессор перед fbc: программа RapidQ (главный .bas и все `$INCLUDE`) переводится в файлы FreeBASIC в отдельную папку, затем собирается fbc с `-i RqLcl\inc` (там `rqrt.bi` и `rqlcl.bi`). Правила — `../RAPIDQ_RULES.md`.

## Файлы

- `RqToFb.pas` — модуль без VCL (Delphi 7 / FPC `-Mdelphi`): `RqToFbConvert(главный файл, опции, сообщения, результат)`. Подключён в unIDE: рамка Project, список rc.exe / FB Smart / FB Compat для программы RapidQ (`CompileRapidQFb` в Unit1).
- `rqtofbcli.dpr` — консольная утилита: `rqtofbcli <главный.bas> <папка вывода> [smart|compat] [папки include через ;]`. Пишет сообщения, затем `APPTYPE=`, `MODE=`, `OUT=`, `ERRORS=`/`WARNINGS=`; код 1 — были ошибки.
- Строка `'$RQFB SMART` или `'$RQFB COMPAT` в исходнике (комментарий — rc.exe её пропускает) задаёт режим сильнее настройки.
- `../inc/rqrt.bi` — функции, которые вставляет перевод: `RqNum`/`RqLong`/`RqShort`/`RqByte`/`RqWord`/`RqDword`/`RqSng`/`RqStr` (присваивание), `RqFmt` (PRINT), сообщения об ошибках (окно, stderr, `<программа>_error.log`), режимы `RQ_SMART`/`RQ_COMPAT`.
- `tests/` — проверочные программы и ожидаемый вывод (`*_expected.txt`; для `types16` — вывод самого RapidQ).

## В unIDE

- Рамка Project для программы RapidQ: список **rc.exe / FB Smart / FB Compat** и, для FB, разрядность 32/64. Выбор запоминается для главного .bas (editor.ini `[RapidQ.Build]`, разрядность — `[FreeBASIC.Build]`).
- IDE Options → Compilers → RapidQ Basic → **RqLcl folder** — папка `RqLcl` из исходников unIDE (пустое поле — `RqLcl` рядом с exe редактора). Компилятор fbc — из IDE Options → Compilers → FreeBASIC.
- Compile: перевод в `<папка главного .bas>\_rqfb`, сообщения перевода в лог; затем fbc `-s gui|console` (по `$APPTYPE`), `-exx` в Smart, `-i RqLcl\inc`; exe рядом с главным .bas; `rqlcl32.dll`/`rqlcl64.dll` копируется рядом с exe. Ошибки fbc указывают на строки исходника RapidQ — двойной щелчок открывает их.
- Отладчик RapidQ (F7/F8/F4, точки останова) при сборке через FreeBASIC не работает — сообщение в логе.

## Как устроен перевод

- Строки переводятся один к одному; перед ними `#line 0 "исходный файл"` — ошибки fbc и сообщения программы указывают на файл и строку исходника RapidQ. Оператор, собранный заново (DIM, заголовок SUB), сохраняет число строк продолжениями ` _`.
- Два прохода в порядке включения файлов: первый собирает объявления и необъявленные переменные, второй пишет текст.
- `$DEFINE`, `$UNDEF`, `$IFDEF`/`$IFNDEF`/`$ELSE`/`$ENDIF` выполняет сам препроцессор (в RapidQ ими меняют и ключевые слова, как в `rapidq.inc`); `#define` в начале строки — то же, что `$DEFINE`.
- Переменная модуля — `Dim Shared`; необъявленные — в заголовке главного файла; необъявленная внутри SUB, которой нет в модуле, — `Dim` в строке заголовка SUB.
- Имена с суффиксом: `a$` → `a__s`, `a%` → `a__sh`, `a&` → `a__l`, `a!` → `a__f`, `a#` → `a__d`, `a?` → `a__b`, `a??` → `a__w`, `a???` → `a__dw`; имя, совпадающее со словом FreeBASIC, — с `_v`.
- Присваивание переменной: `x = выражение` → `x = RqXxx(выражение, "x", __FILE__, __LINE__)` по типу x; строка в число и число в строку — предупреждение при переводе.
- `PRINT a; b, c` → `Print RqFmt(a); RqFmt(b); RqFmt(c)`; `?` — то же.
- Параметры — `ByVal`, кроме `BYREF`, `$OPTION BYREF`, объектов, массивов и TYPE; `SUB` без параметров после `DECLARE SUB` с параметрами берёт их из DECLARE.
- `Объект.OnXxx = Процедура` → `@Процедура`; в `rqlcl.bi` обработчики и с `Sender`, и без него.
- `Result =` в функции → `Function =`; `INC x[, n]` / `DEC` → `x += n` / `x -= n`; `CALL`, `LET` убираются; `'$...` в комментарии → `' $...` (иначе fbc принимает за метакоманду).

## Функции RapidQ (rqrt.bi)

По `rapidq_ref/html_doc/otherdetail.html`, проверено на примерах оттуда (`tests/funcs.bas`):
FIELD$, REPLACESUBSTR$, INSERT$, DELETE$, REPLACE$, REVERSE$, CONVBASE$, HEX$ (8 знаков, как в Windows-версии RapidQ) — препроцессор переименовывает в `RqField`, `RqReplaceSubStr`, … ; RINSTR, TALLY, ROUND (половина — от нуля), CEIL, FLOOR, FILEEXISTS, DIREXISTS, SHOWMESSAGE, MESSAGEBOX, MESSAGEDLG — под теми же именами. FRAC есть в FreeBASIC. RINSTR с начальной позицией — как `InStrRev` FreeBASIC (пример в документации RapidQ не однозначен); ROUND для отрицательных и MESSAGEDLG — по описанию, с RapidQ не сверялись.

## Проверено (Linux, Wine, fbc 1.10.1 win32)

- `tests/types16.bas` — вывод совпадает с RapidQ построчно.
- `tests/b_eq_a.bas` — `b=a` (a — STRING) даёт 0, как в RapidQ, с предупреждением при переводе.
- `tests/gui1.bas` + `mylib.inc` — QFORM/QLABEL/QEDIT/QBUTTON, обработчики без Sender, DECLARE, FUNCTION с `Result` и с именем, CONST, DEFINT, массив, SELECT CASE, FOR, однострочный IF/ELSE, неявные переменные модуля и локальные, `$INCLUDE`, `$DEFINE`, `$IFDEF`/`$IFNDEF`, `$ESCAPECHARS`.
- `rapidq.inc` из `rapidq_ref/inc` (с его include) переводится без ошибок перевода за 0,3 с; fbc на результате — около 300 ошибок, в основном нет классов (QMEMORYSTREAM, QRICHEDIT, QFONT…) и функций RapidQ (FIELD$, REPLACESUBSTR$, ShowMessage, RINSTR…), остальное — следствия.

## Пока не сделано

- CREATE … END CREATE, TYPE … EXTENDS, SUBI/FUNCTIONI, `$MACRO`, `$RESOURCE`, VARIANT, LPRINT, PRINT USING.
- Функции RapidQ PARAMSTR$, GET$, VARPTR$, FORMAT$ и подобные; присваивание свойству объекта числа или строки — без преобразования.
- Передача по ссылке через `@` при вызове (предупреждение, параметр получает копию).
