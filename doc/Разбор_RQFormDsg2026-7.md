# RQFormDsg2026-7.bas — разбор прототипа конструктора форм RapidQ

Файл: rapidq_ref/RQFormDsg2026-7.bas, 15634 строки, 281 SUB/FUNCTION. Основа — RapidFRM (Don Homans, 2009–13; Jordi Ramos, JohnK), доработки Andrew Shelkovenko до 1.90b / vb274 Dec 2021. Номера строк — по этому файлу.

## Живой путь работы

1. **Open_Click (1775)**: исходник целиком в SrcEdit (QRichEdit с подсветкой HiLightdllv4.dll), затем BuildObjTree.
2. **BuildObjTree (2225)**: операторы через GetOpersList/GetOperators1 (15372/15395) — деление по ":" и концу строки вне кавычек, склейка "_". Каждый оператор в нижнем регистре (2318: `LFAke$=LCase$(...)`). CREATE/END CREATE с вложенностью (LevelIdx, ObjParentIdx). Свойства — в PropertyGrid, по объекту файл `<проект>\<obj>.datP`.
3. Слияние с умолчаниями из `data\<TYPE>.data` → `<obj>.dat`; нет файла типа — берётся qpanel.
4. **Замер геометрии**: в текст SrcEdit перед первым `.ShowModal` вставляется код вывода height/width/top/left в PropList.txt (1830–1833), копия компилируется rc.exe и запускается, значения переносятся в .dat (1903–1957). Вставленный код остаётся в SrcEdit.
5. **ShowObjects (9893)**: по списку cmboxObj — AddNewForm (7722) или AddNewObject (11996).
6. **Редактирование**: ScanTimer 50 мс → ScanMouse (3616), WindowFromPoint + мышиный хук (RapidFRM.inc). Перемещение/размер — MouseMoveObject (3467) / MouseResizeObject (3404), 8 маркеров QPANEL 6×6 (ShowCarets 3979), объект переносится один раз в конце (RefreshObject 3201). Сетка — PaintFormGrid (4895), точки через 10 px, без привязки.
7. **Свойства**: PropertyGrid (имя / значение / числовое значение константы из RapidQ2.inc / номер строки / R-W), редакторы FieldEdit / FieldBox (варианты через "|"), применение к экранному объекту — ReDrawComponentByField (5127–6140, ~1000 строк, SELECT CASE по ~30 типам).
8. **Генерация**: BuildFormCode (7480) → CodeText: только CREATE-блоки форм; каждое непустое свойство, кроме Parent/Handle/"<...>" (7218–7233), без сравнения с умолчанием.

## Представление компонентов на форме

- Заглушки QPANEL: EDIT, RICHEDIT, LABEL, BUTTON, COOLBTN, PANEL, OLE, SPLITTER, контейнер TabControl, IMAGE, CANVAS, GAUGE.
- Настоящие контролы RapidQ: QCHECKBOX, QRADIOBUTTON, QCOMBOBOX, QLISTBOX, QGROUPBOX, QSCROLLBOX, QSCROLLBAR; QTABCONTROL и QOVALBTN — внутри своей панели; QSTRINGGRID показывается как QLISTVIEW.
- Невизуальные — кнопки на NonVisPanel (AddNonVisible 9346).

## Ограничения и дефекты (по коду)

- Регистр всех значений теряется, включая Caption (2318).
- Строковое значение определяется по `instr(LSrc$,"qt")` (2459) — ищется текст "qt", а не кавычка.
- В .dat попадают только свойства, которые есть в `data\<TYPE>.data`; методы, WITH и прочее теряются.
- Сгенерированный код в исходник не возвращается; SaveAsOnClick (10020) сохраняет SrcEdit — с вставленным кодом замера.
- Пользовательский код вне CREATE не участвует в генерации; SaveAndExit (13378) со «сращиванием» зависит от ParseInputStream, который выходит первой строкой (13095).
- Align / Copy / Paste / Delete, события и методы (EditEventField, EditMethodField, UpdatePropGrid) работают со старой моделью AddedObjectList — помечены «необновленные процедуры».
- ReDrawComponent (6487) — `exit sub` первой строкой.
- ScanMouse: `ObjectHandle(ObjectIndex)=hWnd` (3664) до проверки индекса; `IF ObjectIndex<>ObjectIndex` (3812) всегда ложно.
- AddNonVisible увеличивает ObjectCount второй раз (9466; первый — AddNewObject 12001).
- Много мёртвого кода: *_OLD, AddQ…1, старый конвейер LoadProject → ParseInputStream → ShowProject.
- FreeBasic-вывод (BuildFBCode и FB_*) читает старый AddedObjectList.

## Что уже есть в unIDE

- FormDesigner.pas — конструктор форм Delphi по .dfm (настоящие контролы VCL, сетка, выделение, перемещение, 8 маркеров по схеме RQFormDsg).
- DsgPalette.pas / DsgClasses.pas — палитра по вкладкам.
- RqComponents.pas + rapidq_ref/ComponentAll.data — описания классов RapidQ (встроенные и TYPE…EXTENDS), значения перечислений.
- Разбор CREATE в дерево (RapidQCreateNodes), снимок значений из работающей копии (RapidQProbeRun), правка свойства в тексте CREATE (RapidQApplyEdit).
