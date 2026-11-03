# Project Properties: вкладка Project options как в Delphi 7 (2026-10-09)

Ветка **RQFreeBasic**, коммит 2a0757b. У пользователя не проверено: в Delphi 7 не собиралось.

## Что сделано
- Окно Project Properties (`DlgNewPrj`) увеличено (760×560). Вкладки: **Project** (имя, папка, тип, как было) и **Project options**. Внутри Project options — страницы как в Delphi 7: Forms, Application, Compiler, Compiler Messages, Linker, Directories/Conditionals, Version Info, Packages.
- Project options показывается только для проекта типа Delphi с главным .dpr (Target). New Project — окно прежнего размера, без этой вкладки.
- Где что хранится (как у Delphi 7):
  - `.dof` — Compiler, Compiler Messages, Linker, Directories/Conditionals, Version Info, Packages ([Excluded Packages]);
  - `.dpr` — Title, Help file, список `Application.CreateForm` (главная форма — первая);
  - `.res` — значок MAINICON (Load Icon) и VERSIONINFO.
- При сборке Delphi (`CompileDelphi`) перед dcc32: Auto-increment build number, VERSIONINFO пишется в .res (`DofPrepareBuild`).
- `DofCompilerParams` дополнительно передаёт dcc32: `-V` (TD32), `-VR`, `-$M<min>,<max>`, `-K$<адрес>` (если не $00400000), `-LU<пакеты>` (Build with runtime packages).

## Модули
- `DelphiOpts.pas` (без VCL): умолчания .dof Delphi 7, ключи версии, правка .dpr, `DofPrepareBuild`.
- `ResFile.pas` (без VCL): чтение/запись .res, VS_VERSIONINFO, замена/извлечение MAINICON.

## Проверено
- ResFile, DelphiOpts — тестами FPC; получившиеся .res разобраны windres (VERSIONINFO, MAINICON, круговая запись SyntaxHLClaude.res байт в байт).
- DlgNewPrj — компиляцией FPC с заглушками VCL; соответствие компонентов .dfm и полей класса — скриптом.

## Допущения и не сделано
- Галка Generate console application = `[Linker] ConsoleApp=0` (в .dof оконных проектов Delphi 7 стоит ConsoleApp=1). dcc32 тип программы берёт из `{$APPTYPE}`, ключ из .dof ему не передаётся.
- Linker output (DCU / C object files), Use Debug DCUs, Target file extension, галка Default — не сделаны (ключи .dof не проверены).
- Design packages — из реестра `HKCU\Software\Borland\Delphi\7.0\Known Packages` (иначе HKLM); без Delphi список пуст, [Excluded Packages] не трогается.
- .cfg проекта не переписывается.
