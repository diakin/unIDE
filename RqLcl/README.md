# RqLcl — компоненты RapidQ поверх LCL для FreeBASIC (прототип)

Проверка подхода: классы RapidQ (QFORM, QBUTTON, …) не пишутся заново, а берутся из LCL (Lazarus). LCL собрана в DLL с плоским набором функций; программа на FreeBASIC подключает `rqlcl.bi`, где классы RapidQ — обычные `Type` со свойствами и событиями.

## Что есть

| Класс | Свойства | События, методы |
|---|---|---|
| общее (QCONTROL) | Left, Top, Width, Height, ClientWidth, ClientHeight, Visible, Enabled, Color, Cursor, Hint, ShowHint, Parent, PopupMenu (запись), Font, Handle (HWND, чтение) | Show, Hide, Repaint, SetFocus |
| QFORM | Caption | OnShow, OnClose; ShowModal, Close, Center |
| QBUTTON | Caption | OnClick; Click |
| QLABEL | Caption | — |
| QEDIT | Text | OnChange |
| QFONT | Name, Size, Color, Charset, Pitch, Bold, Italic, Underline, StrikeOut, Handle (HFONT), FontCount, FontName(i) | AddStyles, DelStyles (до четырёх стилей за вызов) |
| QRICHEDIT | Text, Align, Alignment, BorderStyle, HideScrollBars (только запоминается), HideSelection, Line(i), LineCount, Modified, PlainText, ReadOnly, ScrollBars, SelAttributes, SelLength, SelStart, SelText, TabOrder, Tag, WantTabs, WhereX, WhereY, WordWrap | OnChange; AddStrings (до четырёх строк), AddString, Clear, CopyToClipboard, CutToClipboard, PasteFromClipboard, SelectAll, LoadFromFile, SaveToFile, LoadFromStream, SaveToStream |
| QSTRINGGRID | Cell(c, r) (запись — `SetCell`, см. ниже), ColWidths(i), RowHeights(i), Align, BorderStyle, Col, ColCount, DefaultColWidth, DefaultRowHeight, EditorMode, FixedColor, FixedCols, FixedRows, GridHeight, GridLineWidth, GridWidth, LeftCol, Row, RowCount, ScrollBars, Separator, TabOrder, Tag, TopRow, VisibleColCount, VisibleRowCount | AddOptions, DelOptions, DeleteCol, DeleteRow, InsertCol, InsertRow, SwapCols, SwapRows, LoadFromFile, SaveToFile, LoadFromStream, SaveToStream, TextWidth, TextHeight |
| QDIRTREE | Directory, InitialDir, Align, BorderStyle, HideSelection, ReadOnly, TabOrder, Tag; FastLoad, ReadOnStart (только запоминаются) | OnChange; AddDirTypes, DelDirTypes, AddDriveTypes, DelDriveTypes (только запоминаются), FullCollapse, FullExpand, Reload |
| QMAINMENU | — (MainMenu.Parent = Form) | AddItems, DelItems, DelIndex, Insert |
| QMENUITEM | Caption («-» — разделитель), Checked, RadioItem, ShortCut ("Ctrl+O"), MenuIndex, Count, Command, Tag | OnClick; AddItems, DelItems, DelIndex, Insert |
| QPOPUPMENU | Alignment, AutoPopup, Tag (элемент: PopupMenu = Меню) | OnPopup; AddItems, DelItems, DelIndex, Insert, Popup(x, y) |
| QPANEL | Caption, Align, Alignment, BevelInner, BevelOuter, BevelWidth, BorderStyle, TabOrder, Tag | OnClick, OnDblClick, мышь |
| QCOOLBTN | Caption, Align, AllowAllUp, BMP (файл .bmp, запись), BMPHandle (HBITMAP, запись), Down, Flat, GroupIndex, Layout, NumBMPs, Spacing, Tag | OnClick, мышь |
| QCOMBOBOX | Item(i), ItemCount, ItemIndex, ItemHeight, Text, Style, Sorted, DropDownCount, MaxLength, Align, TabOrder, Tag | OnChange, OnDrawItem, клавиатура; AddItems, Clear, DelItems, InsertItem, TextWidth/Height, рисование |
| QCHECKBOX | Caption, Checked, Align, TabOrder, Tag | OnClick, клавиатура, мышь |
| QLISTBOX | Item(i), ItemCount, ItemIndex, Selected(i), SelCount, MultiSelect, ExtendedSelect, Sorted, Style, ItemHeight, Columns, TopIndex, Text (строки через CR LF), BorderStyle, Align, TabOrder, Tag | OnClick, OnDblClick, OnDrawItem, клавиатура, мышь; AddItems, Clear, DelItems, InsertItem, LoadFromFile, SaveToFile, TextWidth/Height, рисование |
| QSPLITTER | Align, Beveled, MinSize, Tag | OnMoved |
| QSTRINGLIST | Item(i), ItemCount, Text, Sorted, Duplicates | AddItems (до шести), AddList, Build, Clear, DelItems (до шести), Exchange, Find, IndexOf, InsertItem, LoadFromFile, SaveToFile, LoadFromStream, SaveToStream, Parse, Sort — в `inc/rqstrlist.bi`, без DLL |
| QREGISTRY | RootKey, CurrentKey, CurrentPath, HasSubKeys, KeyItemCount, ValueItemCount; GetDataSize(имя), GetDataType(имя) | CloseKey, CreateKey, DeleteKey (с подключами), DeleteValue, KeyExists, KeyItem, MoveKey, OpenKey, ReadBinary, ReadFloat, ReadInteger, ReadString, RegistryConnect, RenameValue, ValueExists, ValueItem, WriteBinary, WriteFloat, WriteInteger, WriteString — в `inc/rqreg.bi`, без DLL, функции advapi32 |
| QMEMORYSTREAM, QFILESTREAM | Position, Size, LineCount; у памяти `Pointer` (в FreeBASIC — `PointerAddr`, препроцессор переименовывает) | Read/Write, ReadNum/WriteNum, ReadStr/WriteStr, ReadLine/WriteLine, CopyFrom, Seek; у файла Open, Close — в `inc/rqstream.bi`, без DLL |

`Label.Font = Font` копирует значения шрифта в элемент, как в RapidQ. `Label.Font` при чтении — QFONT поверх шрифта самого элемента: `Label.Font.Size = 20` меняет элемент. `Font` и `SelAttributes` в `rqlcl.bi` — функции `ByRef`, а не свойства: у свойства FreeBASIC с парой get/set запись `Label.Font.Size = 20` не компилируется (fbc 1.10.1); присваивание `Label.Font = Font` идёт через `Operator Let` у QFONT.

## События с параметрами

| Событие | Параметры обработчика | Классы |
|---|---|---|
| OnKeyDown, OnKeyUp | `ByRef Key As Long, ByVal Shift As Long` | QFORM, QBUTTON, QEDIT, QRICHEDIT, QSTRINGGRID, QDIRTREE |
| OnKeyPress | `ByRef Key As Long` (код символа в CP1251, кириллица тоже) | те же |
| OnMouseDown, OnMouseUp | `ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long` | те же и QLABEL |
| OnMouseMove | `ByVal X As Long, ByVal Y As Long, ByVal Shift As Long` | те же и QLABEL |
| OnSelectCell | `ByVal Col As Long, ByVal Row As Long, ByRef CanSelect As Long` | QSTRINGGRID |
| OnDrawCell | `ByVal Col As Long, ByVal Row As Long, ByVal State As Long, ByRef R As QRECT` | QSTRINGGRID |
| OnSetEditText | `ByVal Col As Long, ByVal Row As Long, ByVal Value As String` | QSTRINGGRID |
| OnDrawItem | `ByVal Index As Long, ByVal State As Long, ByRef R As QRECT` (State: выделен 1, серый 2, недоступен 4, отмечен 8, в фокусе 16) | QLISTBOX, QCOMBOBOX (Style = 1 или 2 — пункты рисует программа) |

Обработчик может быть в четырёх видах: с этими параметрами; с ними и `ByRef Sender As <класс>` последним (как в RapidQ: `SUB GridDraw(Col%, Row%, State%, Rect AS QRect, Sender AS QStringGrid)`); только с Sender; без параметров. Shift — как TShiftState Delphi: Shift 1, Alt 2, Ctrl 4, кнопки мыши 8/16/32, двойной щелчок 64. Button: 0 левая, 1 правая, 2 средняя. State в OnDrawCell: выделена 1, в фокусе 2, фиксированная 4. `Key = 0` в OnKeyPress — символ не вводится; `CanSelect = 0` в OnSelectCell — ячейку выбрать нельзя; `Key` в OnKeyDown/OnKeyUp тоже возвращается в LCL. Препроцессор сам приводит заголовок обработчика к этим типам (`Key AS WORD` → `ByRef Key As Long`), потому что адрес процедуры в rqlcl.bi передаётся без преобразования и типы должны совпасть точно.

В DLL: `RqSetEventEx(объект, событие, номер, процедура)`; LCL вызывает переходник `TRqEventLink`, тот — процедуру с номером события и записью `TRqEventArgs` (8 целых и строка). В rqlcl.bi обработчики лежат в `QCONTROL.EventProcs`, вызывает их `RqLclEventEx`.

Рисование на QSTRINGGRID, QLISTBOX, QCOMBOBOX (обычно в OnDrawCell / OnDrawItem; координаты — в окне таблицы, прямоугольник ячейки — параметр R): FillRect(x1, y1, x2, y2, цвет), TextOut(x, y, текст, цвет, фон; фон -1 — прозрачный), Line, Rectangle, RoundRect, Circle(x1, y1, x2, y2, цвет, заливка), Pset, Paint. QRECT — Left, Top, Right, Bottom.

QSTRINGGRID — `TStringGrid` LCL. У свойства FreeBASIC один индекс, поэтому `Cell(c, r)` — функция, а запись — `SetCell(c, r, значение)`; препроцессор сам переводит `Grid.Cell(c, r) = x` в `Grid.SetCell(c, r, x)`. Ячейка вне таблицы: Smart — пустая строка и предупреждение в лог, Compat — сообщение и конец программы. Начальные значения как в документации RapidQ (DefaultColWidth 64, DefaultRowHeight 24); ScrollBars 1–3 — полосы, только когда нужны (так у Delphi). Separator по умолчанию — Tab (в документации RapidQ значения по умолчанию нет). LoadFromFile(файл, RowOffset, ColOffset, MaxRows): строка файла — строка таблицы с RowOffset, ячейки — с ColOffset, MaxRows 0 — все строки; RowCount становится RowOffset + число строк, ColCount растёт под самую длинную строку — как это делает RapidQ, не проверено. Пока нет ColumnStyle, ColumnList, TabStops, OnEllipsisClick, OnListDropDown, Draw, CopyRect, StretchDraw, TextRect.

QDIRTREE — `TShellTreeView` LCL (диски и папки). Directory — без `\` в конце, кроме корня диска. OnChange при выборе папки пользователем; при `Directory = …` из программы LCL OnChange не вызывает (как в RapidQ — не проверено).

QSTRINGLIST и QREGISTRY повторяют TStringList и TRegistry Delphi: IndexOf/Sort без учёта регистра (CompareString Windows); Text — строки через CR LF и CR LF в конце; OpenKey("a") — от текущего ключа, OpenKey("\a") — от корня; ReadString несуществующего значения — "", ReadInteger/ReadFloat — ошибка. Smart: ошибка (номер вне списка, нет файла, нет значения) — предупреждение в лог и stderr, работа продолжается; OpenKey без прав на запись открывает ключ на чтение. Compat: сообщение и конец программы, как в RapidQ.

QRICHEDIT — `TRichMemo` из пакета RichMemo (на Windows — окно RichEdit). `SelAttributes` меняет у выделения только изменённое свойство (у выделения с разными шрифтами `SelAttributes.Color = …` меняет один цвет); без выделения — атрибуты точки ввода, их получит следующий вставленный текст (`AddStrings`, `SelText`). Позиции `SelStart`/`SelLength` — в символах окна RichEdit, перевод строки там — один символ, а в `Text` — два (CR LF). LoadFromFile: RTF, если файл начинается с `{\rtf`, иначе обычный текст; SaveToFile — RTF; `PlainText = 1` — всегда обычный текст. События клавиатуры и мыши — см. «События с параметрами».

Свойства в DLL ищутся по имени через RTTI LCL, поэтому новое свойство с тем же именем, что в LCL, добавляется в `rqlcl.bi` двумя строками, без правки DLL. Где имя у RapidQ другое — таблица `RqPropTable` в `dll/rqlclcore.pas`.

## Файлы

- `bin/rqlcl32.dll`, `bin/rqlcl64.dll` — собранные DLL (FPC 3.2.2, Lazarus 3.8, LCL win32 widgetset). Около 1,9 и 2,5 МБ.
- `inc/rqlcl.bi` — обёртка для FreeBASIC. DLL выбирается по разрядности программы и загружается при создании первого объекта.
- `demo/demo.bas` — форма с надписью, полем ввода и кнопкой.
- `inc/rqstream.bi` — QMEMORYSTREAM и QFILESTREAM на FreeBASIC (без DLL).
- `demo/fonttest.bas` — проверка QFONT без пользователя.
- `demo/clstest.bas` — меню (щелчок через WM_COMMAND), QPANEL, QCOOLBTN, QCOMBOBOX, QCHECKBOX, QLISTBOX с OnDrawItem, QSPLITTER; 32 и 64 бит.
- `demo/evtest.bas` — события с параметрами (клавиатура и мышь через SendMessage, OnSelectCell, OnDrawCell с FillRect/TextOut), 32 и 64 бит.
- `demo/richtest.bas`, `gridtest.bas`, `listtest.bas`, `regtest.bas` — проверки QRICHEDIT, QSTRINGGRID + QDIRTREE, QSTRINGLIST, QREGISTRY без пользователя.
- `inc/rqstrlist.bi`, `inc/rqreg.bi` — QSTRINGLIST и QREGISTRY (без DLL).
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

- DLL (`stdcall`): `RqInit`, `RqDone`, `RqCreate(класс, родитель, указатель вызывающего)`, `RqSetInt` / `RqGetInt`, `RqSetStr` / `RqGetStr`, `RqSetObj` (Parent, Font), `RqGetObj` (Font), `RqSetEvent`, `RqCall` (ShowModal, Show, Close, Click…), `RqCallInt` (метод с целым параметром: AddStyle, DelStyle, FontCount, SetHandle), `RqGetHandle` (HWND, HFONT), `RqGetItemStr` / `RqSetItemStr` (строка списка по номеру: FontName, Line), `RqCallStr` (метод со строкой: AddStrings, LoadFromFile, SaveToFile), `RqGetCell` / `RqSetCell` (ячейка таблицы), `RqGetItemInt` / `RqSetItemInt` (ColWidths, RowHeights), `RqCallEx` (метод со строкой и тремя целыми: LoadFromFile таблицы, SwapCols…), `RqSetEventEx` (событие с параметрами), `RqCallInts` (метод со строкой и списком целых: рисование), `RqDoEvents`, `RqLastError`, `RqFree`. QFONT в DLL — `TFont` LCL; `RqSetObj(шрифт, "Assign", другой)` копирует значения. Свойства, которых нет в RTTI LCL (SelStart, SelText, Text у многострочных, Line…), и QRICHEDIT — в `dll/rqlclrich.pas`; QSTRINGGRID и QDIRTREE — в `dll/rqlclgrid.pas`; меню, списки, QCOOLBTN, ClientWidth/ClientHeight — в `dll/rqlclmisc.pas`. События без параметров у новых классов (OnClick, OnDblClick, OnChange, OnPopup, OnMoved) идут тем же путём, что события с параметрами (`RqSetEventEx`); `RqCallObj` — метод с объектом (AddItems пунктов меню).
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
