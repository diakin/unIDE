# RqToFb — перевод исходников RapidQ в FreeBASIC

Препроцессор перед fbc: программа RapidQ (главный .bas и все `$INCLUDE`) переводится в файлы FreeBASIC в отдельную папку, затем собирается fbc с `-i RqLcl\inc` (там `rqrt.bi` и `rqlcl.bi`). Правила — `../RAPIDQ_RULES.md`.

## Файлы

- `RqToFb.pas` — модуль без VCL (Delphi 7 / FPC `-Mdelphi`): `RqToFbConvert(главный файл, опции, сообщения, результат)`. Будет подключён в unIDE.
- `rqtofbcli.dpr` — консольная утилита: `rqtofbcli <главный.bas> <папка вывода> [smart|compat] [папки include через ;]`. Пишет сообщения, затем `APPTYPE=`, `OUT=`, `ERRORS=`/`WARNINGS=`; код 1 — были ошибки.
- `../inc/rqrt.bi` — функции, которые вставляет перевод: `RqNum`/`RqLong`/`RqShort`/`RqByte`/`RqWord`/`RqDword`/`RqSng`/`RqStr` (присваивание), `RqFmt` (PRINT), сообщения об ошибках (окно, stderr, `<программа>_error.log`), режимы `RQ_SMART`/`RQ_COMPAT`.
- `tests/` — проверочные программы и ожидаемый вывод (`*_expected.txt`; для `types16` — вывод самого RapidQ).

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

## Проверено (Linux, Wine, fbc 1.10.1 win32)

- `tests/types16.bas` — вывод совпадает с RapidQ построчно.
- `tests/b_eq_a.bas` — `b=a` (a — STRING) даёт 0, как в RapidQ, с предупреждением при переводе.
- `tests/gui1.bas` + `mylib.inc` — QFORM/QLABEL/QEDIT/QBUTTON, обработчики без Sender, DECLARE, FUNCTION с `Result` и с именем, CONST, DEFINT, массив, SELECT CASE, FOR, однострочный IF/ELSE, неявные переменные модуля и локальные, `$INCLUDE`, `$DEFINE`, `$IFDEF`/`$IFNDEF`, `$ESCAPECHARS`.
- `rapidq.inc` из `rapidq_ref/inc` (с его include) переводится без ошибок перевода за 0,3 с; fbc на результате — около 300 ошибок, в основном нет классов (QMEMORYSTREAM, QRICHEDIT, QFONT…) и функций RapidQ (FIELD$, REPLACESUBSTR$, ShowMessage, RINSTR…), остальное — следствия.

## Пока не сделано

- В unIDE не подключено (сборка RapidQ через fbc).
- CREATE … END CREATE, TYPE … EXTENDS, SUBI/FUNCTIONI, `$MACRO`, `$RESOURCE`, VARIANT, LPRINT, PRINT USING.
- Функции RapidQ без пары в FreeBASIC; присваивание свойству объекта числа или строки — без преобразования.
- Передача по ссылке через `@` при вызове (предупреждение, параметр получает копию).
