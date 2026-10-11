# Об inc файлах

Материал для раздела документации «Об inc файлах». Ниже — решение автора
(2026-10-11), записано без правок.

---

(в ответ на предложение сделать общий файл из одних строк
`$INCLUDE "rapidq2.inc"`, `$INCLUDE "conversion.inc"`, `$INCLUDE "Files.inc"`,
`$INCLUDE "func_array.inc"`, `$INCLUDE "parse.inc"`, `$INCLUDE "eml.inc"`)

Это имело бы смысл, если бы разбиение на эти файлы изначально было бы как-то систематизировано.
Но по большей части эти файлы возникли по историческим причинам и вообще набраны из разных источников от разных авторов. Это видно по тому, что информация в них  иногда дублируется и противоречит друг другу.

Теперь о недостатках общего большого файла.
Ты писал
Чем плох один большой файл, собранный вручную:

1. каждая программа получает все имена сразу, и любое из них может совпасть с именем переменной или процедуры в программе
2.  исходные отдельные файлы перестанут быть рабочими. Новая версия компонента от автора или ваша правка в QColorDialog11.inc уже не попадут в общий файл сами.

Тут есть две ситуации -

1. Создание новых программ с нуля
2. Развитие старых программ

Для новых программ пользователь будет использовать два новых больших inc файла
Для старых программ пользователь будет использовать те inc файла, которые и использовал раньше, без всякой переделки. Его же программы раньше как-то работали!
Поэтому inc файлы надо организовать следующим образом

1. все inc c константами и функциями свести с общий rapidqAllProc.inc. Компоненты же  свести в один общий rapidqComponents.inc
2. На основании components.inc сформировать палитру компонентов для RapidQ
3. В настройках компилятора указать два пути для inc файлов - для наших новых, и для пользовательских старых
4. В настройках проекта добавить радиокнопку для выбора пользовательского (старого) или системного (нового) пути для inc. Путь к inc файлам также должен отображаться в поле ввода, и пользователь может ввести здесь какой-то свой еще один путь конкретно для этого проекта. Он сохранится в настройках проекта

---



Подсчёт скриптом по 292 файлам .inc/.cmp:

- 144 файла с компонентами (`TYPE … EXTENDS`), 170 классов; 148 файлов —
  константы, DECLARE и процедуры;
- 31 класс компонента определён в нескольких файлах в разных версиях
  (QColorDialog — QColorDialog10.inc, QColorDialog11.inc, rapidq2.inc;
  QFileDialog — три файла; QFormEx, QDockForm, ComPort — свой файл и
  rapidq2.inc и др.);
- 2670 имён констант определены более чем в одном файле; у 19 разные числа
  (LVIF_GROUPID 128 в commctrl32.inc и 256 в CommCtrl.inc, CDS_TEST 2 и 4,
  VK_EXECUTE 43 и 49 в keys.inc и др.), у 137 значения — выражения или другие
  имена, простым сравнением не сводятся.

---

## Общие файлы rapidqAllProc.inc и rapidqComponents.inc: чем они отличаются от старых inc

Общие файлы собирает скрипт `rapidq_ref/tools/build_inc.py` из папки
`rapidq_ref/incOld` (старые inc, без изменений) по плану
`rapidq_ref/inc_merge_plan.md`. Результат — папка `rapidq_ref/inc_sys`, там же
`build_report.md` с полными списками по каждому пункту ниже. Править общие
файлы руками бесполезно: при каждой сборке они пишутся заново. Править надо
файлы в `incOld` или план и собирать снова.

`rapidqComponents.inc` подключает `rapidqAllProc.inc`. Консольной программе
достаточно `rapidqAllProc.inc`.

Старая программа, которая работала со своими inc, с общими файлами может не
собраться или вести себя иначе. Причины — ниже. Такой программе в настройках
проекта выбирается пользовательская (старая) папка inc.

### 1. Не все файлы вошли

Полный список с причинами — `build_report.md`, раздел «Не вошли». Виды:

- **Другая версия того же компонента.** Из нескольких версий класса взята одна:
  самая новая, при равной дате — из `rapidq2.inc`. Например, QColorDialog —
  из `rapidq2.inc`, а не из QColorDialog10.inc / 11.inc; QMAXEDIT — из
  RichEdPopUp.inc; QRichEdit_api — из apiRe.inc (API_RichEdid.inc — черновик).
- **Куски программ**, а не библиотеки: AllProps.inc, stdObjMnu.inc,
  stdObjbar.inc, RapidFRM_Mods.inc, Splash.inc, SplashForm.inc, Form1.inc,
  menu.inc, LabelGrid.inc, LangIniHeader.inc.
- **Файлы, которые при подключении сами что-то делают** — подключать в своей
  программе отдельно, где это нужно:
  - QXpTheme.INC пишет `.manifest` и перезапускает программу;
  - StayOnTop.inc включает `$OPTION VBDLL ON` и `WEAKTYPE ON` для всего, что
    ниже, и создаёт таймер;
  - debug.inc и debugNoSend.inc создают окно отладки `_DebugFORM`;
  - WebCam.inc сразу вызывает webcam.dll.
- **Файлам нужны ресурсы (`$RESOURCE`) или объявления программы**:
  - CodeSense.inc, QDirListView1.inc, QMarker.inc, Resources2.inc — картинки,
    которых нет;
  - QTButton95.inc (и все версии QTButton) — `btn_BMP`;
  - QTButton_AddOns.inc — тоже `btn_BMP`;
  - XPSkinMetallic — ресурсы Resources2.inc и `CONST myMainFormName`.
- **Части пакета CodeSense** (cmcs21.dll): CM_Functions.inc,
  CM_Constants.inc, C_Constants.inc, Functions.inc — тип `Bool` для них
  объявляет CodeSense.inc.
- **Особые библиотеки** (OpenGL, DAQmx, NI6210, MySQL, ACE32, zlib, cgi,
  Dbase и т.п.) — отмечены в плане «?», решение за автором. QGL.inc не вошёл,
  потому что подключает gl.inc.
- **Ошибки в самом файле**: ftiQuery.inc (FUNCTION внутри FUNCTION),
  RQdate.inc (функция названа ReadVarFromMemory2, а вызывается
  ReadVarFromMemory из rapidq2007.inc; к тому же это обёртка fbDate.dll),
  qciccio.inc (пробный класс).
- **Старые версии rapidq.inc**: rapidq3.inc (копия), rapidq2007.inc,
  rapidq_ex.inc, RAPIDQbug.INC, RAPIDQl.INC.

**Взята только часть файла** (дальше пример программы или недоделанный
текст):
- QDrawMenu.inc — строки 1–228;
- QSavePlus.inc — 1–216;
- using.inc — 1–232;
- RichEditApi.inc — 1–226 (дальше структуры, не переведённые с ассемблера).

### 2. Одно имя — одно объявление

- **Повтор (CONST, $DEFINE, DECLARE, TYPE, SUB/FUNCTION, DIM) с тем же
  именем в другом файле закомментирован** (`'~dup ... ' повтор, первое:
  файл(строка)`). Остаётся первое по сборке: сначала `rapidq2.inc`, потом
  `rapidq.inc` с подключаемыми им файлами, дальше по алфавиту.
- **CONST и $DEFINE считаются одним пространством имён.** `$DEFINE ODT_MENU 1`
  в rapidq2.inc и ниже `CONST ODT_MENU = 1` в Api.inc у RapidQ дали бы
  `CONST 1 = 1`.
- **Если значения повторов разные, взято первое.** Список —
  `build_report.md`, раздел «Повторы с другим текстом». Значимые:
  - LVIF_GROUPID = 256 и LVIF_COLUMNS = 512 (из CommCtrl.inc, а не 128/256 из
    commctrl32.inc);
  - CDS_TEST = 2;
  - VK_EXECUTE = 43;
  - cm* (CopyMode) — коды растровых операций Windows из rapidq2.inc
    (cmSrcCopy = &HCC0020), а не номера 0..14 из старых rapidq*.inc. Номера
    0..14 рисуют чёрным (проверено в RapidQ 2026-10-11).
- **Процедура и DECLARE … LIB с одним именем в разных файлах** — оставлено
  первое:
  - `LoadString` — это `FUNCTION LoadString(FileName)` из Files.inc (читает
    файл), а не функция Windows LoadStringA из WIN32API.INC / WINDOWS.INC;
  - `UpdateColors` — процедура из ODMenuXP.inc, а не функция gdi32.

### 3. DECLARE … LIB с другими параметрами — под другим именем

Одна и та же функция Windows в разных файлах объявлена с разными параметрами.
Например, `GetClientRect`:
- в rapidq2.inc — `lpRect AS QRECT`;
- в QFormSkin.inc и WIN32API.INC — `lpRect As RECT`.

В общем файле под исходным именем остаётся первое объявление, а у
следующего файла функция переименована в `Имя_Файл` (ALIAS прежний). Его
вызовы в том же файле тоже переименованы.

Таких 60, список — `build_report.md`, раздел «DECLARE … LIB с другими
параметрами». В основном это WIN32API.INC и WINDOWS.INC против rapidq2.inc:
- GetClientRect, GetWindowRect, ClientToScreen;
- CreateFile, ReadFile;
- GetMenuItemInfo, SetMenuItemInfo, InsertMenuItem;
- DrawEdge, DrawCaption, DrawFrameControl;
- GetObject, MoveToEx, SHGetFileInfo, Shell_NotifyIcon и др.

**Что это значит для программы.** Программа, написанная под WIN32API.INC,
которая вызывает `GetClientRect(h, r)` с `r AS RECT`, с общим файлом получит
версию из rapidq2.inc с QRECT, и rc.exe выдаст «Expected object of type
QRECT». Варианты:
- в программе вызывать `GETCLIENTRECT_WIN32API`;
- объявить `r` как QRECT;
- собирать программу со старыми inc.

### 4. Переименовано внутри файлов

Имена совпадали с именами других файлов. Снаружи этих файлов они не
используются:

| Файл | Было | Стало | С чем совпадало |
|---|---|---|---|
| CMD5.inc | F, G, H, FF, GG, HH, II | MD5_F … MD5_II | DIM F AS QFileStream в QXLS.INC; FOR ii в eml.inc |
| using.inc | const log10 | USING_log10 | FUNCTION LOG10 из Math.inc |
| using.inc | DIM FORMAT$ | USING_format$ | встроенная FORMAT$ нынешнего RapidQ |
| SetFileTimeAttrib.inc | sysdir$ | SFTA_sysdir$ | FUNCTION SysDir из Files.inc |
| QMaxSplitter.inc | DIM Rect1 | MSPLIT_Rect1 | rc.exe: «Identifier RECT1 already used»; другого Rect1 в сборке нет, причина не найдена, после переименования ошибки нет |

Если программа обращалась к этим именам напрямую (например, вызывала
`FF` из CMD5.inc), с общим файлом нужно новое имя.

### 5. $DEFINE и $UNDEF

- **$DEFINE имени типом — только для своего файла.** Если ниже это же имя
  встречается как имя переменной, в конце файла стоит `$UNDEF`:
  - `$DEFINE HWND INTEGER` (createWind.inc, apiRe.inc) — иначе параметры
    `hWnd` других файлов становились `INTEGER`;
  - `$DEFINE CHAR BYTE` (keys.inc).

  Программа, которая писала `x AS HWND`, рассчитывая на этот `$DEFINE`,
  должна объявить его у себя.
- **`$UNDEF` имени, которое объявил другой файл, закомментирован.**
  WIN32API.INC в конце снимал TRUE и FALSE для всего, что ниже. В общем файле
  TRUE и FALSE после него остаются (1 и 0).
- **`brem … erem` (`$ifdef` по необъявленному имени) и `$IFDEF число`**
  перенесены как есть: RapidQ их не читает, и объявления внутри не закрывают
  настоящие ниже.

### 6. Порядок в rapidqAllProc.inc

- **Подключаемый файл вставлен на место первого `$INCLUDE` его.**
  Например, conversion.inc, Files.inc, func_array.inc, parse.inc,
  fbscancodes.inc и eml.inc — внутрь rapidq.inc, как при обычном подключении.
- **Декларации впереди, тела SUB/FUNCTION — в конце файла** (по исходным
  файлам), а на месте тела — `DECLARE` с тем же заголовком. Тело остаётся на
  месте, если:
  - оно внутри условного блока;
  - имя с точкой (`FUNCTION Screen.MousePresent`);
  - в заголовке нет скобок (`function GetRusdate as string`) — после такого
    DECLARE rc.exe тело не принимает;
  - в файле есть `$UNDEF`;
  - тело использует имя, которое объявлено ниже (иначе изменился бы смысл).
- **CONST, TYPE и DECLARE, нужные раньше своего места, подняты к первому
  использованию** (пометка «сборка: поднято из файл(строка)»):
  - CBEN_FIRST в commctrl32.inc;
  - TYPE NMHDR для CommCtrl.inc;
  - GetDiskFreeSpace и другие функции Kernel32.inc для Copy of NOTA.inc;
  - FILETIME и другие внутри WIN32API.INC.

### 7. Режимы компилятора

После каждого файла и в конце общего файла режимы выключены:
- `$TYPECHECK OFF`;
- `$ESCAPECHARS OFF`;
- `$OPTION WEAKTYPE OFF`;
- `$OPTION VBDLL OFF`.

Если программа рассчитывала, что их включает какой-то inc (например, CMD5.inc
включал WEAKTYPE и VBDLL), ей нужно включить их самой.

`$OPTION INKEY$ TRAPALL` из keys.inc в общем файле закомментирован: он меняет
INKEY$ во всей программе. Кому нужно — пишет в своей программе.

### 8. Исправлено в тексте старых файлов

Только в общих файлах, `incOld` не меняется:
- commctrl32.inc: числа с суффиксом C (`-880U`) — без U; `CONST` без `=` —
  с `=`;
- keys.inc: `define ИМЯ значение` без `$` — `$define`;
- RichEditApi.inc: строки-комментарии ассемблера `; ...` — `'`.

### 9. Имена программы

Общий файл даёт программе сразу все свои имена. Переменная или процедура
программы с тем же именем, что у константы, функции или `$DEFINE` из общего
файла, вызовет «already defined» или изменит смысл. Особенно это касается
`$DEFINE`: он подменяет слово везде ниже. Список объявленных имён — в самих
общих файлах; повторы и их источники — в `build_report.md`.

### 10. Компоненты и палитра

В `rapidqComponents.inc` — по одной версии каждого класса (п. 1). Палитра
RapidQ строит из него страницы RQ Comp (визуальные) и RQ Comp System. Если
поставить такой компонент на форму, в программу добавляется
`$INCLUDE "rapidqComponents.inc"`. Если проект собирается со старой папкой
inc, путь добавляется полный. Наследники QFORM в палитру не входят.
