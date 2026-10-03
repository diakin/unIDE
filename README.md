<p align="center"><img src="icons/unIDE_logo.png" alt="unIDE"></p>

# unIDE

**Version: beta 0.1**

[English](#english) · [Русский](#русский)

---

## English

### What it is

unIDE is a universal IDE for several programming languages, aimed at
Windows 7 and later. It is written in Delphi 7 and works as a shell over the
Delphi 7 toolchain: Delphi projects are built by the Delphi 7 command-line
compiler (dcc32), the form designer uses the VCL and the component packages
installed in Delphi 7. Projects in other languages are edited, highlighted
and searched in the same environment.

### Languages

| Language / project type | Highlighting | Projects | Build & run | Debugger | Form designer |
|---|---|---|---|---|---|
| Delphi 7 (Object Pascal) | yes | yes | yes (dcc32) | yes | yes |
| Lazarus / Free Pascal | yes | yes | not yet | – | – |
| RapidQ Basic | yes | yes | not yet | – | – |
| FreeBASIC | yes | yes | not yet | – | – |
| Visual Basic 6 | yes | yes | not yet | – | – |
| Arduino | yes | yes | not yet | – | – |
| C, C++ | yes | yes | not yet | – | – |
| Go | yes | yes | not yet | – | – |
| Python | yes | yes | not yet | – | – |
| Rust | yes | yes | not yet | – | – |
| Web site (HTML, JS, TS) | yes | yes | – | – | – |

Highlighting schemes also exist for INI, BAT, PowerShell, SQL, XML, Java, C#,
R, Fortran, Inno Setup scripts and manifests (`schemes/*.clr`).

### Main features

**Editor**
- Syntax highlighting by colour schemes (`.clr`), one scheme per file type.
- IDE themes: Light, Dark and Custom; own themed controls (`UiLib`).
- Tabs, Windows list, Reopen; a file changed on disk while edited in the
  window is merged (three-way merge, conflicts marked in the text).
- Search and replace: case, whole word, go to line, list of matches,
  F3 / Shift+F3 search for the selection; Find in Files in open tabs, in the
  project or in a folder on disk.
- Bookmarks per file, LastBM (back through visited bookmarks), Hot Bookmarks
  (last 8 visited across all tabs plus pinned ones), bookmark clean-up.
- Code tree of procedures, declaration panel (click an identifier to see its
  declaration, click the panel to jump there and back), name of the current
  procedure.
- Format text (Pascal indentation), case conversion, code templates.

**Projects**
- Project types from the table above; new project from scratch or on top of
  an existing folder (the main file such as `.dpr` gives the project name).
- Manage, scan and delete projects; fix paths after moving a project; find
  lost files in search folders; open the project folder in Explorer.

**Delphi 7**
- Build with dcc32, error list with jump to the line; library and browse
  paths imported from the Delphi 7 registry settings.
- Build Release: finds the files the program needs besides the exe.
- Debugger on TD32 debug info: breakpoints (F5), Run (F9), Step into (F7),
  Step over (F8), Run to cursor (F4), Pause, Program reset (Ctrl+F2), value
  hints under the mouse.
- Watch list (Ctrl+F5): variables, fields, records, objects; static and
  dynamic arrays shown as a table with index fields.
- Visual form designer: the form is built from `.dfm` with real VCL
  controls; component palette with standard components and third-party
  packages installed in Delphi 7 (read from `.bpl` without running their
  code); object inspector with properties and events; alignment tools;
  menu editor and menu wizard; rename and replace components; move
  components created in code into `.dfm`; snapshot of a running form; list
  of project units and forms.

**Service**
- Hang watch: a hang of the main thread is written to `hang.log` with the
  call stack.

### Requirements

- Windows 7 or later.
- Delphi 7 installed: to build Delphi projects, for the debugger and for
  third-party components in the designer.

### Building unIDE

Open `SyntaxHLClaude.dpr` in Delphi 7, or run in the project folder:

```
dcc32 SyntaxHLClaude.dpr
```

Settings are kept in `editor.ini` next to the exe, IDE theme colours in
`IDE.clr`, highlighting schemes in `schemes`.

### License

MIT, see [LICENSE](LICENSE).

---

## Русский

### Что это

unIDE — универсальная среда разработки для нескольких языков
программирования под Windows 7 и новее. Написана на Delphi 7 и работает как
оболочка над инструментами Delphi 7: проекты Delphi собирает компилятор
командной строки Delphi 7 (dcc32), конструктор форм использует VCL и пакеты
компонентов, установленные в Delphi 7. Проекты на других языках
редактируются, подсвечиваются и ищутся в той же среде.

### Языки

| Язык / тип проекта | Подсветка | Проекты | Сборка и запуск | Отладчик | Конструктор форм |
|---|---|---|---|---|---|
| Delphi 7 (Object Pascal) | да | да | да (dcc32) | да | да |
| Lazarus / Free Pascal | да | да | пока нет | – | – |
| RapidQ Basic | да | да | пока нет | – | – |
| FreeBASIC | да | да | пока нет | – | – |
| Visual Basic 6 | да | да | пока нет | – | – |
| Arduino | да | да | пока нет | – | – |
| C, C++ | да | да | пока нет | – | – |
| Go | да | да | пока нет | – | – |
| Python | да | да | пока нет | – | – |
| Rust | да | да | пока нет | – | – |
| Сайт (HTML, JS, TS) | да | да | – | – | – |

Схемы подсветки есть также для INI, BAT, PowerShell, SQL, XML, Java, C#, R,
Fortran, сценариев Inno Setup и манифестов (`schemes/*.clr`).

### Основные возможности

**Редактор**
- Подсветка синтаксиса по цветовым схемам (`.clr`), своя схема для каждого
  типа файлов.
- Темы среды: Light, Dark и Custom; свои элементы управления с темами
  (`UiLib`).
- Вкладки, список окон, Reopen; файл, изменённый на диске во время правки в
  окне, сливается с правками (слияние трёх версий, конфликты помечаются в
  тексте).
- Поиск и замена: регистр, слово целиком, переход к строке, список
  совпадений, F3 / Shift+F3 — поиск выделенного; Find in Files по открытым
  вкладкам, по проекту или по папке на диске.
- Закладки в каждом файле, LastBM (возврат по посещённым закладкам), Hot
  Bookmarks (8 последних посещённых по всем вкладкам и закреплённые),
  чистка закладок.
- Дерево процедур, панель объявления (щелчок по идентификатору показывает
  его объявление, щелчок по панели — переход к нему и обратно), имя текущей
  процедуры.
- Форматирование текста (отступы Pascal), смена регистра, шаблоны кода.

**Проекты**
- Типы проектов из таблицы; новый проект с нуля или на базе существующей
  папки (имя проекта берётся по главному файлу, например `.dpr`).
- Управление, сканирование и удаление проектов; исправление путей после
  переноса проекта; поиск потерянных файлов в папках поиска; открытие папки
  проекта в Проводнике.

**Delphi 7**
- Сборка через dcc32, список ошибок с переходом к строке; пути Library и
  Browse импортируются из настроек Delphi 7 в реестре.
- Build Release: поиск файлов, которые нужны программе кроме exe.
- Отладчик по отладочной информации TD32: точки останова (F5), Run (F9),
  Step into (F7), Step over (F8), Run to cursor (F4), пауза, Program reset
  (Ctrl+F2), подсказки со значениями под мышью.
- Окно Watch (Ctrl+F5): переменные, поля, записи, объекты; статические и
  динамические массивы — таблицей с полями индексов.
- Визуальный конструктор форм: форма строится из `.dfm` настоящими
  контролами VCL; палитра со стандартными компонентами и сторонними
  пакетами, установленными в Delphi 7 (читаются из `.bpl` без выполнения их
  кода); инспектор объектов со свойствами и событиями; выравнивание;
  редактор меню и мастер меню; переименование и замена компонентов; перенос
  компонентов, созданных в коде, в `.dfm`; снимок работающей формы; список
  модулей и форм проекта.

**Служебное**
- Сторож зависаний: зависание главного потока записывается в `hang.log` со
  стеком вызовов.

### Требования

- Windows 7 или новее.
- Установленная Delphi 7: для сборки проектов Delphi, для отладчика и для
  сторонних компонентов в конструкторе.

### Сборка unIDE

Открыть `SyntaxHLClaude.dpr` в Delphi 7 или в папке проекта выполнить:

```
dcc32 SyntaxHLClaude.dpr
```

Настройки хранятся в `editor.ini` рядом с exe, цвета темы среды — в
`IDE.clr`, схемы подсветки — в папке `schemes`.

### Лицензия

MIT, см. [LICENSE](LICENSE).
