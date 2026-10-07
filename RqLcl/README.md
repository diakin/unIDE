# RqLcl — компоненты RapidQ поверх LCL для FreeBASIC (прототип)

Проверка подхода: классы RapidQ (QFORM, QBUTTON, …) не пишутся заново, а берутся из LCL (Lazarus). LCL собрана в DLL с плоским набором функций; программа на FreeBASIC подключает `rqlcl.bi`, где классы RapidQ — обычные `Type` со свойствами и событиями.

## Что есть

| Класс | Свойства | События, методы |
|---|---|---|
| общее (QCONTROL) | Left, Top, Width, Height, Visible, Enabled, Color, Hint, ShowHint, Parent, Font, Handle (HWND, чтение) | Show, Hide, Repaint, SetFocus |
| QFORM | Caption | OnShow, OnClose; ShowModal, Close, Center |
| QBUTTON | Caption | OnClick; Click |
| QLABEL | Caption | — |
| QEDIT | Text | OnChange |
| QFONT | Name, Size, Color, Charset, Pitch, Handle (HFONT), FontCount, FontName(i) | AddStyles, DelStyles (до четырёх стилей за вызов) |
| QRICHEDIT | Text, Align, Alignment, BorderStyle, HideScrollBars (только запоминается), HideSelection, Line(i), LineCount, Modified, PlainText, ReadOnly, ScrollBars, SelAttributes, SelLength, SelStart, SelText, TabOrder, Tag, WantTabs, WhereX, WhereY, WordWrap | OnChange; AddStrings (до четырёх строк), AddString, Clear, CopyToClipboard, CutToClipboard, PasteFromClipboard, SelectAll, LoadFromFile, SaveToFile, LoadFromStream, SaveToStream |
| QMEMORYSTREAM, QFILESTREAM | Position, Size, LineCount; у памяти `Pointer` (в FreeBASIC — `PointerAddr`, препроцессор переименовывает) | Read/Write, ReadNum/WriteNum, ReadStr/WriteStr, ReadLine/WriteLine, CopyFrom, Seek; у файла Open, Close — в `inc/rqstream.bi`, без DLL |

`Label.Font = Font` копирует значения шрифта в элемент, как в RapidQ. `Label.Font` при чтении — QFONT поверх шрифта самого элемента: `Label.Font.Size = 20` меняет элемент. `Font` и `SelAttributes` в `rqlcl.bi` — функции `ByRef`, а не свойства: у свойства FreeBASIC с парой get/set запись `Label.Font.Size = 20` не компилируется (fbc 1.10.1); присваивание `Label.Font = Font` идёт через `Operator Let` у QFONT.

QRICHEDIT — `TRichMemo` из пакета RichMemo (на Windows — окно RichEdit). `SelAttributes` меняет у выделения только изменённое свойство (у выделения с разными шрифтами `SelAttributes.Color = …` меняет один цвет); без выделения — атрибуты точки ввода, их получит следующий вставленный текст (`AddStrings`, `SelText`). Позиции `SelStart`/`SelLength` — в символах окна RichEdit, перевод строки там — один символ, а в `Text` — два (CR LF). LoadFromFile: RTF, если файл начинается с `{\rtf`, иначе обычный текст; SaveToFile — RTF; `PlainText = 1` — всегда обычный текст. Событий клавиатуры и мыши пока нет (у других элементов тоже).

Свойства в DLL ищутся по имени через RTTI LCL, поэтому новое свойство с тем же именем, что в LCL, добавляется в `rqlcl.bi` двумя строками, без правки DLL. Где имя у RapidQ другое — таблица `RqPropTable` в `dll/rqlclcore.pas`.

## Файлы

- `bin/rqlcl32.dll`, `bin/rqlcl64.dll` — собранные DLL (FPC 3.2.2, Lazarus 3.8, LCL win32 widgetset). Около 1,9 и 2,5 МБ.
- `inc/rqlcl.bi` — обёртка для FreeBASIC. DLL выбирается по разрядности программы и загружается при создании первого объекта.
- `demo/demo.bas` — форма с надписью, полем ввода и кнопкой.
- `inc/rqstream.bi` — QMEMORYSTREAM и QFILESTREAM на FreeBASIC (без DLL).
- `demo/fonttest.bas` — проверка QFONT без пользователя.
- `demo/richtest.bas` — проверка QRICHEDIT без пользователя.
- `dll/richmemo/` — нужная часть пакета RichMemo (источник и лицензия — в его README).
- `demo/selftest.bas` — проверка без пользователя: форма открывается, OnShow нажимает кнопку три раза, сверяет свойства и закрывает форму; итог в консоль и в код завершения.
- `dll/rqlclcore.pas`, `dll/rqlcl.lpr` — исходники DLL; `dll/build.bat` — сборка своим Lazarus.

## Сборка и запуск примера

```
cd RqLcl\demo
fbc -s gui demo.bas -i ..\inc
copy ..\bin\rqlcl32.dll .        (для 64 бит - rqlcl64.dll)
demo.exe
```

`selftest.bas` — так же, но `-s console`.

## Как устроено

- DLL (`stdcall`): `RqInit`, `RqDone`, `RqCreate(класс, родитель, указатель вызывающего)`, `RqSetInt` / `RqGetInt`, `RqSetStr` / `RqGetStr`, `RqSetObj` (Parent, Font), `RqGetObj` (Font), `RqSetEvent`, `RqCall` (ShowModal, Show, Close, Click…), `RqCallInt` (метод с целым параметром: AddStyle, DelStyle, FontCount, SetHandle), `RqGetHandle` (HWND, HFONT), `RqGetItemStr` / `RqSetItemStr` (строка списка по номеру: FontName, Line), `RqCallStr` (метод со строкой: AddStrings, LoadFromFile, SaveToFile), `RqDoEvents`, `RqLastError`, `RqFree`. QFONT в DLL — `TFont` LCL; `RqSetObj(шрифт, "Assign", другой)` копирует значения. Свойства, которых нет в RTTI LCL (SelStart, SelText, Text у многострочных, Line…), и QRICHEDIT — в `dll/rqlclrich.pas`.
- Событие: в DLL у объекта свой переходник на каждое событие; LCL вызывает его метод, он — процедуру программы с адресом объекта FreeBASIC. В `rqlcl.bi` эта процедура вызывает обработчик пользователя `Sub Xxx(ByRef Sender As QBUTTON)`.
- Строки с обеих сторон — в кодировке Windows (CP1251 у исходников RapidQ); внутри DLL — UTF-8 LCL.
- Исключения через границу DLL не идут: функция возвращает 0, текст — `RqLastError`; `rqlcl.bi` показывает его окном.
- `RqDone` вызывается деструктором модуля `rqlcl.bi` в конце программы: окна и LCL освобождаются, пока программа работает, а не при выгрузке DLL.

## Проверено

В рабочей среде (Linux, Wine 9, виртуальный дисплей): DLL собраны кросс-компилятором FPC, программы — Windows-версией fbc 1.10.1 (win32 и win64) под Wine. `selftest` для 32 и 64 бит — все проверки прошли; `demo` с исходником в CP1251 и русской локалью показывает кириллицу правильно. На настоящей Windows не запускалось. `dll/build.bat` на Windows не проверялся.

## Не сделано

- Синтаксис RapidQ (`Button1.OnClick = Button1Click` без `@`, `CREATE … END CREATE`, `$INCLUDE` и т. д.) — это переводчик или форк fbc, отдельная работа.
- Остальные классы RapidQ и события с параметрами (OnKeyPress, OnMouseDown…).
- Font, свойства-объекты кроме Parent, значения True/False в стиле RapidQ (сейчас чтение даёт 0/1).

## Лицензия LCL

LCL распространяется под LGPL с исключением (`COPYING.modifiedLGPL.txt` в исходниках Lazarus): её можно компоновать с независимыми модулями и распространять результат на своих условиях; изменения самой LCL остаются под её лицензией.
