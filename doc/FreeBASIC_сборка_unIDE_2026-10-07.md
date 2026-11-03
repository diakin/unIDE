# FreeBASIC в unIDE — этап 1 (сборка, запуск, ошибки), 2026-10-07

Работа по FreeBASIC идёт в ветке **FreeBasic** (создана из RapidQ на коммите 9df83f7; коммитить и пушить в неё). Сделать её веткой по умолчанию через прокси сессии нельзя (настройки репозитория закрыты) — пользователь переключает сам: GitHub - Settings - General - Default branch.

Коммиты: 9df83f7 (сборка FreeBASIC), b5cde40 (путь пробной сборки редактора `_newbuild\`), 2f2f0b0 (пустые Include/Library — папки компилятора). У пользователя не проверено (синтаксис новых процедур проверен FPC в обвязке; разбор строк fbc и поиск #include — тестами).

## Решения пользователя
- Установлены оба компилятора, 32 и 64 бит; у каждого свои inc и lib.
- Пустые Include и Library — компилятор берёт свои папки по умолчанию.
- Вид результата (GUI / Console / DLL) — список в рамке Project.
- Главный файл — как у RapidQ (IncOwner, цель проекта).
- Этап: сборка, запуск, разбор ошибок; отладчик — позже.

## Что сделано
- `CompileFreeBasic`: fbc `-s gui | -s console | -dll`, `-x <главный>.exe/.dll` рядом с главным .bas. `-i` (IncPath) и `-p` (LibPath) — только если поля заполнены; пустые — ключей нет, в лог пишутся папки компилятора (`FbDefaultDirs`: inc и lib\win32 / lib\win64 рядом с fbc). `_compile.bat`, `_compile.log`, переход к первой ошибке. Вывод fbc без перевода из OEM (`FCompNoOem` в `RunCompiler`).
- `FbTargetBas`: IncOwner → цель проекта FreeBASIC, если она подключает активный .bas через #include (с вложенными) → файл вкладки (записывается целью проекта).
- `cmbFbKind`, `cmbFbBits` (Unit1.dfm, pnlBuildKind, видны в режиме FreeBASIC). Хранение: editor.ini `[FreeBASIC.Build]` `путь=GUI 32`. По умолчанию Console, 32 (64 — если есть только 64-битный fbc).
- IDE Options - Compilers - FreeBASIC: `FBCompPath` (32: fbc32.exe, иначе fbc.exe), `FBComp64Path` (64: fbc64.exe, иначе fbc.exe; пустое — fbc64.exe в папке 32), Include, Library (пустые — папки компилятора).
- `RunTarget`, `RunTargetExe`: exe главного файла; DLL — сообщение. Отладчик Delphi для FreeBASIC не запускается. F7/F8/F4 — сообщение.
- `FbParseErrorLine` (в `ParseCompilerLine` первым), `FbIsErrorLine` (в `IsCompilerError`): `файл(строка) error N:` / `warning N(M):`, путь может содержать скобки; linking failed, ld cannot find, undefined reference — красным.
- Вкладка Includes и для FreeBASIC (`#include`, `#include once`; поиск: папка подключающего, папка главного, Include из настроек, а он пустой — inc компилятора разрядности главного файла). .bas с IncOwner — сборщик по главному файлу.

## Открыто / дальше
- Проверка у пользователя: настройки путей, сборка GUI/Console/DLL, 32/64, переход по ошибкам.
- Консольная программа запускается напрямую: окно закрывается, когда программа заканчивается.
- Отладчик FreeBASIC (gdb или инструментированная копия) — не начат.
- Дополнительные ключи fbc (-g, -exx и др.) из IDE не задаются; возможен `#cmdline` в исходнике (fbc 1.08+).
