unit RosProj;

// ---------------------------------------------------------------------------
//  Проект ReactOS / LiberNT: сборка CMake + Ninja. Без VCL.
//
//  Проект этого типа - готовое дерево исходников. Его узнают по трём
//  файлам в корне: configure.cmd, CMakeLists.txt и PreLoad.cmake. Главный
//  файл проекта (Target) - configure.cmd, папка исходников - его папка.
//
//  configure.cmd создаёт папку сборки output-* (reactosVG14 с RosBE 2.2.1:
//  output-MinGW-i386; LiberNT: output-<метка>-<arch>-<debug|release>), в
//  ней build.ninja. Сборка - ninja -C <папка сборки> <цель>.
//
//  Настройки - в разделе проекта ([Project.<имя>] в editor.ini, через
//  TProjectIni), с приставкой ReactOS_:
//    ReactOS_BuildDir=output-MinGW-i386   папка сборки; внутри папки
//                                         исходников - от неё, иначе полный путь
//    ReactOS_NinjaTarget=bootcd           bootcd, livecd, liberntimg ... или
//                                         имя модуля (ntoskrnl, ...)
//    ReactOS_ConfigureArgs=               параметры configure.cmd
//                                         (LiberNT: /gcc, /clang, /arch=...)
//    ReactOS_EnvScript=                   скрипт окружения перед командами
//                                         (RosBE 2.2.1 для reactosVG14:
//                                         ...\RosBE\RosBE.cmd); у LiberNT
//                                         пусто - configure.cmd находит
//                                         RosBE сам
//
//  Сборка (Unit1, CompileReactOS) - два шага, каждый своим .cmd во
//  временной папке (RosBuildScript), вывод - в лог:
//    configure - если в папке сборки нет build.ninja: скрипт окружения,
//                затем configure.cmd в папке исходников;
//    ninja     - скрипт окружения, затем ninja <цель> в папке сборки.
//  ninja должен быть в PATH после скрипта окружения (RosBE его добавляет).
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, PrjStore;

const
  RosProjectType = 'ReactOS';      // тип в [Project.<имя>] Type
  RosMainFile = 'configure.cmd';   // главный файл (Target)
  RosSection = 'ReactOS';          // ключи ReactOS_* в разделе проекта
  RosDefaultTarget = 'bootcd';

type
  TRosSettings = record
    SourceDir: string;      // папка исходников, с \ в конце
    BuildDir: string;       // папка сборки, полный путь без \ в конце
    NinjaTarget: string;
    ConfigureArgs: string;
    EnvScript: string;      // полный путь или пусто
  end;

// В папке - дерево исходников ReactOS / LiberNT
function RosIsSourceDir(const ADir: string): Boolean;
// Папки сборки output-* в папке исходников - имена без пути, по алфавиту
function RosFindOutputDirs(const ASourceDir: string; AList: TStrings): Integer;
// Папка сборки по умолчанию: одна output-* - она; несколько - первая с
// build.ninja; иначе пусто
function RosDefaultBuildDir(const ASourceDir: string): string;
// Цели ninja для списка: образы дисков; модуль вписывается руками
procedure RosNinjaTargets(AList: TStrings);
// Путь в настройках: внутри папки исходников - от неё, иначе полный
function RosPathToStore(const ASourceDir, APath: string): string;
function RosPathFromStore(const ASourceDir, AValue: string): string;
// Настройки проекта из раздела и в раздел. ASourceDir - папка исходников
// (папка Target): от неё считаются пути.
procedure RosLoadSettings(APrj: TProjectIni; const ASourceDir: string;
                          var ASettings: TRosSettings);
procedure RosSaveSettings(APrj: TProjectIni; const ASettings: TRosSettings);
// Команда сборки: ninja -C "<папка сборки>" <цель>
function RosNinjaCommand(const ASettings: TRosSettings): string;
// Что и как будет собрано - строками для лога сборки
procedure RosDescribeBuild(const ASettings: TRosSettings; ALines: TStrings);

type
  TRosStep = (rsConfigure, rsNinja);

// Текст .cmd для шага сборки. Пояснения - латиницей: cmd читает файл в
// OEM-кодировке.
procedure RosBuildScript(const ASettings: TRosSettings; AStep: TRosStep;
                         ALines: TStrings);
// Где скачать инструменты сборки (меню ReactOS - Download Build Tools):
// строки "подпись=адрес"; '-' - разделитель
procedure RosToolLinks(AList: TStrings);
// Строка хода ninja "[12/3456] Building C object ...": ADone = 12,
// ATotal = 3456
function RosParseNinjaStatus(const ALine: string;
                             var ADone, ATotal: Integer): Boolean;

implementation

function RosIsSourceDir(const ADir: string): Boolean;
var
  Dir: string;
begin
  Result := False;
  if Trim(ADir) = '' then
    Exit;
  Dir := IncludeTrailingPathDelimiter(Trim(ADir));
  Result := FileExists(Dir + RosMainFile) and
            FileExists(Dir + 'CMakeLists.txt') and
            FileExists(Dir + 'PreLoad.cmake');
end;

function RosFindOutputDirs(const ASourceDir: string; AList: TStrings): Integer;
var
  SR: TSearchRec;
  Dir: string;
  Names: TStringList;
begin
  AList.Clear;
  Result := 0;
  if Trim(ASourceDir) = '' then
    Exit;
  Dir := IncludeTrailingPathDelimiter(Trim(ASourceDir));
  Names := TStringList.Create;
  try
    if FindFirst(Dir + 'output-*', faDirectory, SR) = 0 then
    try
      repeat
        if ((SR.Attr and faDirectory) <> 0) and (SR.Name <> '.') and
           (SR.Name <> '..') then
          Names.Add(SR.Name);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
    Names.Sort;
    AList.Assign(Names);
  finally
    Names.Free;
  end;
  Result := AList.Count;
end;

function RosDefaultBuildDir(const ASourceDir: string): string;
var
  Dirs: TStringList;
  Dir: string;
  DirIdx: Integer;
begin
  Result := '';
  Dirs := TStringList.Create;
  try
    if RosFindOutputDirs(ASourceDir, Dirs) = 0 then
      Exit;
    Dir := IncludeTrailingPathDelimiter(Trim(ASourceDir));
    if Dirs.Count = 1 then
    begin
      Result := Dir + Dirs[0];
      Exit;
    end;
    for DirIdx := 0 to Dirs.Count - 1 do
      if FileExists(Dir + Dirs[DirIdx] + '\build.ninja') then
      begin
        Result := Dir + Dirs[DirIdx];
        Exit;
      end;
  finally
    Dirs.Free;
  end;
end;

procedure RosNinjaTargets(AList: TStrings);
begin
  AList.Clear;
  AList.Add('bootcd');
  AList.Add('livecd');
  AList.Add('liberntimg');   // только LiberNT
  AList.Add('liberntvhd');   // только LiberNT
  AList.Add('all');
end;

function RosPathToStore(const ASourceDir, APath: string): string;
var
  Dir: string;
begin
  Result := ExcludeTrailingPathDelimiter(Trim(APath));
  if (Result = '') or (Trim(ASourceDir) = '') then
    Exit;
  Dir := IncludeTrailingPathDelimiter(Trim(ASourceDir));
  if (Length(Result) > Length(Dir)) and
     (AnsiCompareText(Copy(Result, 1, Length(Dir)), Dir) = 0) then
    Result := Copy(Result, Length(Dir) + 1, MaxInt);
end;

function RosPathFromStore(const ASourceDir, AValue: string): string;
begin
  Result := ExcludeTrailingPathDelimiter(Trim(AValue));
  if Result = '' then
    Exit;
  // Полный путь: диск (C:\...) или сетевой (\\server\...)
  if ((Length(Result) >= 2) and (Result[2] = ':')) or
     (Copy(Result, 1, 2) = '\\') then
    Exit;
  if Trim(ASourceDir) <> '' then
    Result := IncludeTrailingPathDelimiter(Trim(ASourceDir)) + Result;
end;

procedure RosLoadSettings(APrj: TProjectIni; const ASourceDir: string;
                          var ASettings: TRosSettings);
begin
  ASettings.SourceDir := '';
  if Trim(ASourceDir) <> '' then
    ASettings.SourceDir := IncludeTrailingPathDelimiter(Trim(ASourceDir));
  ASettings.BuildDir := RosPathFromStore(ASettings.SourceDir,
    APrj.ReadString(RosSection, 'BuildDir', ''));
  ASettings.NinjaTarget := Trim(APrj.ReadString(RosSection, 'NinjaTarget',
                                                RosDefaultTarget));
  if ASettings.NinjaTarget = '' then
    ASettings.NinjaTarget := RosDefaultTarget;
  ASettings.ConfigureArgs := Trim(APrj.ReadString(RosSection,
                                                  'ConfigureArgs', ''));
  ASettings.EnvScript := RosPathFromStore(ASettings.SourceDir,
    APrj.ReadString(RosSection, 'EnvScript', ''));
end;

procedure RosSaveSettings(APrj: TProjectIni; const ASettings: TRosSettings);
begin
  APrj.WriteString(RosSection, 'BuildDir',
                   RosPathToStore(ASettings.SourceDir, ASettings.BuildDir));
  APrj.WriteString(RosSection, 'NinjaTarget', Trim(ASettings.NinjaTarget));
  APrj.WriteString(RosSection, 'ConfigureArgs', Trim(ASettings.ConfigureArgs));
  // Скрипт RosBE обычно вне дерева исходников - полный путь
  APrj.WriteString(RosSection, 'EnvScript', Trim(ASettings.EnvScript));
end;

function RosNinjaCommand(const ASettings: TRosSettings): string;
var
  Target: string;
begin
  Target := Trim(ASettings.NinjaTarget);
  if Target = '' then
    Target := RosDefaultTarget;
  Result := 'ninja -C "' + ASettings.BuildDir + '" ' + Target;
end;

procedure RosDescribeBuild(const ASettings: TRosSettings; ALines: TStrings);
var
  HasBuildDir, HasNinjaFile: Boolean;
begin
  HasBuildDir := (ASettings.BuildDir <> '') and
                 DirectoryExists(ASettings.BuildDir);
  HasNinjaFile := HasBuildDir and
                  FileExists(IncludeTrailingPathDelimiter(ASettings.BuildDir) +
                             'build.ninja');

  ALines.Add('Папка исходников: ' + ASettings.SourceDir);
  if not RosIsSourceDir(ASettings.SourceDir) then
    ALines.Add('  в ней нет configure.cmd, CMakeLists.txt или PreLoad.cmake');
  if ASettings.BuildDir = '' then
    ALines.Add('Папка сборки: не задана (Project - Properties)')
  else if not HasBuildDir then
    ALines.Add('Папка сборки: ' + ASettings.BuildDir + '  (папки нет)')
  else if not HasNinjaFile then
    ALines.Add('Папка сборки: ' + ASettings.BuildDir +
               '  (build.ninja нет - нужен configure)')
  else
    ALines.Add('Папка сборки: ' + ASettings.BuildDir);
  ALines.Add('Цель ninja: ' + ASettings.NinjaTarget);
  if ASettings.ConfigureArgs = '' then
    ALines.Add('Параметры configure: нет')
  else
    ALines.Add('Параметры configure: ' + ASettings.ConfigureArgs);
  if ASettings.EnvScript = '' then
    ALines.Add('Скрипт окружения: не задан')
  else if not FileExists(ASettings.EnvScript) then
    ALines.Add('Скрипт окружения: ' + ASettings.EnvScript + '  (файла нет)')
  else
    ALines.Add('Скрипт окружения: ' + ASettings.EnvScript);

  ALines.Add('');
  ALines.Add('Команды:');
  if ASettings.EnvScript <> '' then
    ALines.Add('  call "' + ASettings.EnvScript + '"');
  if not HasNinjaFile then
    ALines.Add('  cd /d "' + ExcludeTrailingPathDelimiter(ASettings.SourceDir) +
               '" && ' + RosMainFile + ' ' + ASettings.ConfigureArgs);
  if ASettings.BuildDir <> '' then
    ALines.Add('  ' + RosNinjaCommand(ASettings))
  else
    ALines.Add('  ninja -C "<папка сборки>" ' + ASettings.NinjaTarget);
end;

procedure RosBuildScript(const ASettings: TRosSettings; AStep: TRosStep;
                         ALines: TStrings);
var
  Target: string;
begin
  ALines.Clear;
  ALines.Add('@echo off');
  ALines.Add('rem unIDE: ReactOS build step, file is rewritten on every build');
  // Скрипт окружения RosBE ставит PATH (gcc, cmake, ninja) и переменные
  // сборки. call - чтобы после него вернуться в этот файл.
  if ASettings.EnvScript <> '' then
    ALines.Add('call "' + ASettings.EnvScript + '"');
  case AStep of
    rsConfigure:
    begin
      ALines.Add('cd /d "' + ExcludeTrailingPathDelimiter(ASettings.SourceDir) +
                 '"');
      ALines.Add('call ' + RosMainFile + ' ' + Trim(ASettings.ConfigureArgs));
    end;
    rsNinja:
    begin
      Target := Trim(ASettings.NinjaTarget);
      if Target = '' then
        Target := RosDefaultTarget;
      ALines.Add('cd /d "' + ASettings.BuildDir + '"');
      ALines.Add('ninja ' + Target);
    end;
  end;
  ALines.Add('exit /b %errorlevel%');
end;

procedure RosToolLinks(AList: TStrings);
begin
  AList.Clear;
  // reactosVG14 (ReactOS 0.4.14)
  AList.Add('RosBE 2.2.1 - для reactosVG14 (установщик, Windows XP и новее)=' +
            'https://sourceforge.net/projects/reactos/files/RosBE-Windows/' +
            'i386/2.2.1/');
  AList.Add('-');
  // LiberNT: установщик rosbe.exe на Windows 7 не запускается - архивы
  // компонентов распаковываются руками в %LOCALAPPDATA%\RosBE\pkgs\<версия>
  AList.Add('RosBE для LiberNT - выпуски winget-rosbe (архивы компонентов)=' +
            'https://github.com/ahmedarif193/winget-rosbe/releases');
  AList.Add('Universal C Runtime (KB2999226) - нужен GCC 16 и Clang LiberNT=' +
            'https://www.microsoft.com/en-us/download/details.aspx?id=48234');
  AList.Add('Python 3.8.10 - последний для Windows 7, нужен LiberNT /clang=' +
            'https://www.python.org/downloads/release/python-3810/');
  AList.Add('-');
  AList.Add('Git for Windows 2.46.2 - последний для Windows 7=' +
            'https://github.com/git-for-windows/git/releases/tag/' +
            'v2.46.2.windows.1');
end;

function RosParseNinjaStatus(const ALine: string;
                             var ADone, ATotal: Integer): Boolean;
var
  Text: string;
  SlashPos, ClosePos: Integer;
begin
  Result := False;
  Text := TrimLeft(ALine);
  if (Text = '') or (Text[1] <> '[') then
    Exit;
  SlashPos := Pos('/', Text);
  ClosePos := Pos(']', Text);
  if (SlashPos < 3) or (ClosePos < SlashPos + 2) then
    Exit;
  ADone := StrToIntDef(Copy(Text, 2, SlashPos - 2), -1);
  ATotal := StrToIntDef(Copy(Text, SlashPos + 1, ClosePos - SlashPos - 1), -1);
  Result := (ADone >= 0) and (ATotal > 0);
end;

end.
