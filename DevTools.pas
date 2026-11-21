unit DevTools;

// ---------------------------------------------------------------------------
//  Инструменты общего плана для меню Instruments (Unit1): 32-битный MinGW
//  для сборки make-проектов (Walker), GCC, Clang, Python. Без VCL.
//
//  - MinGW 32-bit: MinGW-w64 GCC 8.1.0, сборка i686 (posix, dwarf, rt_v6)
//    с SourceForge (mingw-builds), архив 7z около 43 МБ. Подходит для
//    Windows 7 (новые сборки GCC на UCRT там могут не запуститься), даёт
//    gcc, g++, windres и mingw32-make. 64-битный компилятор для Walker не
//    годится: движок и lcc (QVM) рассчитаны на 32 бита. Размер и SHA-256
//    архива сняты с файла, скачанного с SourceForge 21.11.2026 (на
//    странице SourceForge опубликованы только SHA-1 и MD5; SHA-1 файла -
//    dd4f34f473e84c79b6b446adb3a5fac7919ba9cb). В архиве одна папка
//    mingw32 - она становится tools\mingw32. В реестр и PATH ничего не
//    пишется: PATH дополняется только для запущенного make (Unit1);
//  - поиск MinGW: свой (tools\mingw32), mingw32-make.exe в PATH, обычные
//    папки (C:\mingw32, C:\MinGW, C:\msys64\mingw32, Program Files
//    (x86)\mingw-w64\*\mingw32);
//  - Python: найденный в системе (PATH, запись PythonCore в реестре,
//    обычные папки) или свой - Python 3.8.10 (последний для Windows 7),
//    embeddable zip с python.org в tools\python. pip в такой сборке нет:
//    Unit1 скачивает get-pip.py (bootstrap.pypa.io, ветка для 3.8),
//    включает site в python38._pth и запускает get-pip.py. Размер и
//    SHA-256 заранее не записаны (сайт отсюда не открывался): проверяется
//    только то, что файл скачался по HTTPS;
//  - Clang и GCC: только поиск (PATH, LLVM в Program Files, свои MinGW) и
//    версия в журнал; установщика Clang нет - ссылка на выпуски LLVM.
// ---------------------------------------------------------------------------

interface

uses
  {$IFDEF MSWINDOWS}Windows,{$ENDIF} SysUtils, Classes, SzSetup;

const
  ExeSuffix = {$IFDEF UNIX}''{$ELSE}'.exe'{$ENDIF};

  MgwVersion = '8.1.0';
  MgwBuild = 'i686-posix-dwarf-rt_v6-rev0';
  MgwFileName = 'i686-8.1.0-release-posix-dwarf-rt_v6-rev0.7z';
  MgwSize = 45050859;
  MgwSha256 = 'adb84b70094c0225dd30187ff995e311d19424b1eb8f60934c60e4903297f946';
  MgwSfPath = 'mingw-w64/files/Toolchains%20targetting%20Win32/' +
    'Personal%20Builds/mingw-builds/8.1.0/threads-posix/dwarf/';
  MgwUrl1 = 'https://downloads.sourceforge.net/project/mingw-w64/' +
    'Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/8.1.0/' +
    'threads-posix/dwarf/' + MgwFileName;
  MgwUrl2 = 'https://sourceforge.net/projects/' + MgwSfPath + MgwFileName +
    '/download';
  MgwPage = 'https://sourceforge.net/projects/' + MgwSfPath;
  MgwInfoFile = 'unide_mingw32.txt';
  MgwMakeName = 'mingw32-make' + ExeSuffix;

  PyVersion = '3.8.10';
  PyInfoFile = 'unide_python.txt';
  PyGetPipName = 'get-pip.py';
  PyGetPipUrl = 'https://bootstrap.pypa.io/pip/3.8/get-pip.py';
  PyPage = 'https://www.python.org/downloads/release/python-3810/';
  // Пакеты для генераторов данных Walker (walker\tools)
  PyWalkerPackages = 'numpy scipy Pillow';

  LlvmPage = 'https://github.com/llvm/llvm-project/releases';

// Файл в папках PATH ('' - нет). Под Windows без .exe в имени - с .exe
function DevFindInPath(const AExeName: string): string;
// Первые строки вывода программы (stdout + stderr), не дольше ATimeoutMs.
// Результат - код выхода; -1 - не запустилась (причина - в AOutput),
// -2 - не ответила за время
function DevRunCapture(const AExe, AArgs: string; ATimeoutMs: Cardinal;
  var AOutput: string): Integer;
// Первая непустая строка текста
function DevFirstLine(const AText: string): string;
// Добавить в список путь, которого там ещё нет (без учёта регистра)
procedure DevAddUnique(AList: TStrings; const APath: string);

// ---- MinGW 32-bit -------------------------------------------------------
// <папка exe>\tools\mingw32\ и %LOCALAPPDATA%\unIDE\tools\mingw32\
function MgwAppDir: WideString;
function MgwUserDir: WideString;
// Папка bin своего MinGW (есть gcc.exe и mingw32-make.exe), с \ в конце;
// нет - ''
function MgwLocalBin: string;
// Куда ставить: где уже есть, иначе у exe, иначе в профиль; '' - никуда
function MgwChooseTargetDir: WideString;
// План установки (распаковывает свой 7-Zip ASevenZip)
function MgwPlan(const ASevenZip: WideString; const AOsName: string): TSzPlan;
// Папки bin с gcc и mingw32-make: свой MinGW первым, потом PATH и обычные
// папки. Результат - их число
function MgwFindBins(AList: TStrings): Integer;
// Ответ gcc -dumpmachine - 32-битный MinGW (i686-w64-mingw32, mingw32)
function MgwIs32Bit(const ADumpMachine: string): Boolean;

// ---- GCC и Clang ----------------------------------------------------------
// gcc (и i686-/x86_64-w64-mingw32-gcc своих MinGW) - полные пути
function GccFindAll(AList: TStrings): Integer;
// clang - полные пути (PATH, Program Files\LLVM, свои MinGW)
function ClangFindAll(AList: TStrings): Integer;

// ---- Python ---------------------------------------------------------------
function PyAppDir: WideString;
function PyUserDir: WideString;
// python.exe своего Python; нет - ''
function PyLocalExe: string;
function PyChooseTargetDir: WideString;
// Embeddable zip для этой Windows (64-битный на x64)
function PyPlan(AIs64: Boolean; const ASevenZip: WideString;
  const AOsName: string): TSzPlan;
// План загрузки get-pip.py в корень Python (не распаковывается)
function PyGetPipPlan: TSzPlan;
// Python в системе: PATH, реестр PythonCore, обычные папки; свой - первым
function PyFindAll(AList: TStrings): Integer;
// Embeddable Python в ARoot: строку "#import site" в pythonXY._pth - без
// решётки (тогда работают site-packages и pip). True - уже так или
// исправлено
function PyEnableSite(const ARoot: string): Boolean;

implementation

uses
  ProcRun;

// ---------------------------------------------------------------------------
//  Общее
// ---------------------------------------------------------------------------

function DevFindInPath(const AExeName: string): string;
var
  ExeName: string;
begin
  ExeName := AExeName;
  {$IFNDEF UNIX}
  if ExtractFileExt(ExeName) = '' then
    ExeName := ExeName + '.exe';
  {$ENDIF}
  Result := FileSearch(ExeName, GetEnvironmentVariable('PATH'));
  if Result <> '' then
    Result := ExpandFileName(Result);
end;

function DevRunCapture(const AExe, AArgs: string; ATimeoutMs: Cardinal;
  var AOutput: string): Integer;
var
  Proc: TProcRun;
  Chunk: string;
  Got: Integer;
  StartTick: Cardinal;
  Ended: Boolean;
begin
  Result := -1;
  AOutput := '';
  Proc := TProcRun.Create;
  try
    Proc.CommandLine := '"' + AExe + '" ' + AArgs;
    Proc.Dir := ExtractFilePath(AExe);
    Proc.Window := pwHidden;
    Proc.Console := pcNoWindow;
    Proc.CaptureOutput := True;
    if not Proc.Start then
    begin
      AOutput := Proc.ErrorText;
      Exit;
    end;
    Ended := False;
    StartTick := GetTickCount;
    repeat
      Chunk := '';
      Got := Proc.Read(Chunk);
      if Got < 0 then
        Break;
      if Got > 0 then
      begin
        AOutput := AOutput + Chunk;
        Continue;
      end;
      if Ended then
        Break;
      if Proc.WaitFor(50) then
        Ended := True;
      if GetTickCount - StartTick > ATimeoutMs then
      begin
        Proc.Terminate(1);
        Result := -2;
        Exit;
      end;
    until False;
    Proc.WaitFor(1000);
    Result := Proc.ExitCode;
  finally
    Proc.Free;
  end;
end;

function DevFirstLine(const AText: string): string;
var
  Lines: TStringList;
  LineIdx: Integer;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for LineIdx := 0 to Lines.Count - 1 do
      if Trim(Lines[LineIdx]) <> '' then
      begin
        Result := Trim(Lines[LineIdx]);
        Exit;
      end;
  finally
    Lines.Free;
  end;
end;

procedure DevAddUnique(AList: TStrings; const APath: string);
var
  ItemIdx: Integer;
begin
  if APath = '' then
    Exit;
  for ItemIdx := 0 to AList.Count - 1 do
    if CompareText(AList[ItemIdx], APath) = 0 then
      Exit;
  AList.Add(APath);
end;

function DevEnv(const AName: string): string;
begin
  Result := GetEnvironmentVariable(AName);
  if Result <> '' then
    Result := IncludeTrailingPathDelimiter(Result);
end;

// Подпапки AMask папки ADir (полные пути с \), по алфавиту
procedure DevSubDirs(const ADir, AMask: string; AList: TStrings);
var
  SR: TSearchRec;
  Names: TStringList;
  NameIdx: Integer;
begin
  if (ADir = '') or not DirectoryExists(ADir) then
    Exit;
  Names := TStringList.Create;
  try
    if FindFirst(IncludeTrailingPathDelimiter(ADir) + AMask, faDirectory,
                 SR) = 0 then
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
    for NameIdx := 0 to Names.Count - 1 do
      AList.Add(IncludeTrailingPathDelimiter(ADir) + Names[NameIdx] +
                PathDelim);
  finally
    Names.Free;
  end;
end;

// Папку можно создать или заменить: пишется в папку над ней
function DevCanPlace(const ADir: WideString): Boolean;
begin
  Result := (ADir <> '') and
    SzCanWrite(ExtractFilePath(string(SzNoSlash(ADir))));
end;

// ---------------------------------------------------------------------------
//  MinGW 32-bit
// ---------------------------------------------------------------------------

function MgwAppDir: WideString;
begin
  Result := SzToolsAppDir + 'mingw32' + PathDelim;
end;

function MgwUserDir: WideString;
begin
  Result := SzToolsUserDir;
  if Result <> '' then
    Result := Result + 'mingw32' + PathDelim;
end;

function MgwBinOk(const ABin: string): Boolean;
begin
  Result := (ABin <> '') and FileExists(ABin + 'gcc' + ExeSuffix) and
            FileExists(ABin + MgwMakeName);
end;

function MgwLocalBin: string;
begin
  Result := string(MgwAppDir) + 'bin' + PathDelim;
  if MgwBinOk(Result) then
    Exit;
  if MgwUserDir <> '' then
  begin
    Result := string(MgwUserDir) + 'bin' + PathDelim;
    if MgwBinOk(Result) then
      Exit;
  end;
  Result := '';
end;

function MgwChooseTargetDir: WideString;
var
  LocalBin: string;
begin
  LocalBin := MgwLocalBin;
  if LocalBin <> '' then
  begin
    // <корень>\bin\ -> <корень>\
    Result := ExtractFilePath(ExcludeTrailingPathDelimiter(LocalBin));
    if DevCanPlace(Result) then
      Exit;
  end;
  Result := MgwAppDir;
  if DevCanPlace(Result) then
    Exit;
  Result := MgwUserDir;
  if DevCanPlace(Result) then
    Exit;
  Result := '';
end;

function MgwPlan(const ASevenZip: WideString; const AOsName: string): TSzPlan;
begin
  Result.Title := 'MinGW-w64 GCC ' + MgwVersion + ' (i686)';
  SetLength(Result.Files, 1);
  Result.Files[0].Url1 := MgwUrl1;
  Result.Files[0].Url2 := MgwUrl2;
  Result.Files[0].FileName := MgwFileName;
  Result.Files[0].Size := MgwSize;
  Result.Files[0].Sha256 := MgwSha256;
  Result.Extractor := ASevenZip;
  Result.Archive := 0;
  Result.ExtractNames := 'mingw32';
  Result.ExtractSubDir := 'mingw32';
  Result.MoveNames := '';            // папка tools\mingw32 - целиком
  Result.CheckFile := 'bin\' + MgwMakeName;
  Result.InfoFile := MgwInfoFile;
  Result.InfoText := 'MinGW-w64 GCC ' + MgwVersion + ' (' + MgwBuild +
    '), установлен unIDE ' + FormatDateTime('yyyy-mm-dd hh:nn', Now) +
    ' для ' + AOsName + #13#10 + MgwUrl1 + #13#10 +
    'SHA-256 ' + MgwSha256 + ' сверен.' + #13#10 +
    'Распакован своим 7-Zip unIDE. В реестр и PATH ничего не записано.' +
    #13#10 + 'bin: gcc.exe, g++.exe, windres.exe, mingw32-make.exe' + #13#10;
end;

function MgwFindBins(AList: TStrings): Integer;
var
  Candidates: TStringList;
  CandIdx: Integer;
  MakePath, ProgX86: string;
begin
  AList.Clear;
  Candidates := TStringList.Create;
  try
    Candidates.Add(MgwLocalBin);
    MakePath := DevFindInPath(MgwMakeName);
    if MakePath <> '' then
      Candidates.Add(ExtractFilePath(MakePath));
    {$IFNDEF UNIX}
    Candidates.Add('C:\mingw32\bin\');
    Candidates.Add('C:\MinGW\bin\');
    Candidates.Add('C:\msys64\mingw32\bin\');
    Candidates.Add('C:\msys32\mingw32\bin\');
    ProgX86 := DevEnv('ProgramFiles(x86)');
    if ProgX86 = '' then
      ProgX86 := DevEnv('ProgramFiles');
    if ProgX86 <> '' then
    begin
      // mingw-w64 installer: <ProgramFiles>\mingw-w64\i686-8.1.0-...\mingw32
      DevSubDirs(ProgX86 + 'mingw-w64', 'i686-*', Candidates);
      for CandIdx := 0 to Candidates.Count - 1 do
        if Pos('\mingw-w64\i686-', Candidates[CandIdx]) > 0 then
          Candidates[CandIdx] := Candidates[CandIdx] + 'mingw32\bin\';
    end;
    {$ELSE}
    ProgX86 := '';
    {$ENDIF}
    for CandIdx := 0 to Candidates.Count - 1 do
      if MgwBinOk(Candidates[CandIdx]) then
        DevAddUnique(AList, Candidates[CandIdx]);
  finally
    Candidates.Free;
  end;
  Result := AList.Count;
end;

function MgwIs32Bit(const ADumpMachine: string): Boolean;
var
  LowText: string;
begin
  LowText := LowerCase(Trim(ADumpMachine));
  Result := (Pos('x86_64', LowText) = 0) and
            ((Pos('i686', LowText) > 0) or (Pos('i586', LowText) > 0) or
             (Pos('i386', LowText) > 0) or (LowText = 'mingw32'));
end;

// ---------------------------------------------------------------------------
//  GCC и Clang
// ---------------------------------------------------------------------------

function GccFindAll(AList: TStrings): Integer;
var
  Bins: TStringList;
  BinIdx: Integer;
  OwnX64: string;
begin
  AList.Clear;
  Bins := TStringList.Create;
  try
    MgwFindBins(Bins);
    for BinIdx := 0 to Bins.Count - 1 do
      DevAddUnique(AList, Bins[BinIdx] + 'gcc' + ExeSuffix);
  finally
    Bins.Free;
  end;
  DevAddUnique(AList, DevFindInPath('gcc'));
  // Свой MinGW-w64 GCC 12 (MingwTool, меню Instruments): gcc без
  // приставки там нет
  OwnX64 := string(SzToolsAppDir) + 'mingw' + PathDelim + 'bin' + PathDelim +
            'x86_64-w64-mingw32-gcc' + ExeSuffix;
  if FileExists(OwnX64) then
    DevAddUnique(AList, OwnX64);
  if SzToolsUserDir <> '' then
  begin
    OwnX64 := string(SzToolsUserDir) + 'mingw' + PathDelim + 'bin' +
              PathDelim + 'x86_64-w64-mingw32-gcc' + ExeSuffix;
    if FileExists(OwnX64) then
      DevAddUnique(AList, OwnX64);
  end;
  Result := AList.Count;
end;

function ClangFindAll(AList: TStrings): Integer;
var
  Candidates, Bins: TStringList;
  CandIdx: Integer;
begin
  AList.Clear;
  Candidates := TStringList.Create;
  Bins := TStringList.Create;
  try
    Candidates.Add(DevFindInPath('clang'));
    {$IFNDEF UNIX}
    if DevEnv('ProgramW6432') <> '' then
      Candidates.Add(DevEnv('ProgramW6432') + 'LLVM\bin\clang.exe');
    if DevEnv('ProgramFiles') <> '' then
      Candidates.Add(DevEnv('ProgramFiles') + 'LLVM\bin\clang.exe');
    if DevEnv('ProgramFiles(x86)') <> '' then
      Candidates.Add(DevEnv('ProgramFiles(x86)') + 'LLVM\bin\clang.exe');
    Candidates.Add(string(SzToolsAppDir) + 'llvm\bin\clang.exe');
    Candidates.Add('C:\msys64\clang64\bin\clang.exe');
    Candidates.Add('C:\msys64\mingw64\bin\clang.exe');
    {$ENDIF}
    MgwFindBins(Bins);
    for CandIdx := 0 to Bins.Count - 1 do
      Candidates.Add(Bins[CandIdx] + 'clang' + ExeSuffix);
    for CandIdx := 0 to Candidates.Count - 1 do
      if (Candidates[CandIdx] <> '') and FileExists(Candidates[CandIdx]) then
        DevAddUnique(AList, Candidates[CandIdx]);
  finally
    Candidates.Free;
    Bins.Free;
  end;
  Result := AList.Count;
end;

// ---------------------------------------------------------------------------
//  Python
// ---------------------------------------------------------------------------

function PyAppDir: WideString;
begin
  Result := SzToolsAppDir + 'python' + PathDelim;
end;

function PyUserDir: WideString;
begin
  Result := SzToolsUserDir;
  if Result <> '' then
    Result := Result + 'python' + PathDelim;
end;

function PyLocalExe: string;
begin
  Result := string(PyAppDir) + 'python.exe';
  if FileExists(Result) then
    Exit;
  if PyUserDir <> '' then
  begin
    Result := string(PyUserDir) + 'python.exe';
    if FileExists(Result) then
      Exit;
  end;
  Result := '';
end;

function PyChooseTargetDir: WideString;
var
  LocalExe: string;
begin
  LocalExe := PyLocalExe;
  if LocalExe <> '' then
  begin
    Result := ExtractFilePath(LocalExe);
    if DevCanPlace(Result) then
      Exit;
  end;
  Result := PyAppDir;
  if DevCanPlace(Result) then
    Exit;
  Result := PyUserDir;
  if DevCanPlace(Result) then
    Exit;
  Result := '';
end;

function PyPlan(AIs64: Boolean; const ASevenZip: WideString;
  const AOsName: string): TSzPlan;
var
  Arch, FileName, Url: string;
begin
  if AIs64 then
    Arch := 'amd64'
  else
    Arch := 'win32';
  FileName := 'python-' + PyVersion + '-embed-' + Arch + '.zip';
  Url := 'https://www.python.org/ftp/python/' + PyVersion + '/' + FileName;
  Result.Title := 'Python ' + PyVersion + ' (' + Arch + ')';
  SetLength(Result.Files, 1);
  Result.Files[0].Url1 := Url;
  Result.Files[0].Url2 := '';
  Result.Files[0].FileName := FileName;
  // Размер заранее не записан: примерный - для хода, не проверяется
  if AIs64 then
    Result.Files[0].Size := -8400000
  else
    Result.Files[0].Size := -7400000;
  Result.Files[0].Sha256 := '';
  Result.Extractor := ASevenZip;
  Result.Archive := 0;
  Result.ExtractNames := '*';
  Result.ExtractSubDir := '';
  Result.MoveNames := '';            // папка tools\python - целиком
  Result.CheckFile := 'python.exe';
  Result.InfoFile := PyInfoFile;
  Result.InfoText := 'Python ' + PyVersion + ' embeddable (' + Arch +
    '), установлен unIDE ' + FormatDateTime('yyyy-mm-dd hh:nn', Now) +
    ' для ' + AOsName + #13#10 + Url + #13#10 +
    'Распакован своим 7-Zip unIDE. В реестр и PATH ничего не записано.' +
    #13#10 + 'pip: get-pip.py (' + PyGetPipUrl + ').' + #13#10;
end;

function PyGetPipPlan: TSzPlan;
begin
  Result.Title := PyGetPipName;
  SetLength(Result.Files, 1);
  Result.Files[0].Url1 := PyGetPipUrl;
  Result.Files[0].Url2 := '';
  Result.Files[0].FileName := PyGetPipName;
  Result.Files[0].Size := -2600000;
  Result.Files[0].Sha256 := '';
  Result.Extractor := '';
  Result.Archive := -1;             // не распаковывать
  Result.ExtractNames := '';
  Result.ExtractSubDir := '';
  Result.MoveNames := PyGetPipName;
  Result.CheckFile := PyGetPipName;
  Result.InfoFile := 'unide_getpip.txt';
  Result.InfoText := PyGetPipName + ' скачан unIDE ' +
    FormatDateTime('yyyy-mm-dd hh:nn', Now) + #13#10 + PyGetPipUrl + #13#10;
end;

{$IFDEF MSWINDOWS}
// Свои объявления функций реестра (как в GitTool): у Delphi 7 и FPC
// разные объявления параметров в модуле Windows
function DevRegOpenKeyEx(AKey: HKEY; ASubKey: PChar; AOptions: DWORD;
  ADesired: DWORD; var AResult: HKEY): LongInt; stdcall;
  external 'advapi32.dll' name 'RegOpenKeyExA';
function DevRegEnumKey(AKey: HKEY; AIndex: DWORD; AName: PChar;
  ANameSize: DWORD): LongInt; stdcall;
  external 'advapi32.dll' name 'RegEnumKeyA';
function DevRegQueryValueEx(AKey: HKEY; AValueName: PChar;
  AReserved: Pointer; AType: PDWORD; AData: Pointer;
  ADataSize: PDWORD): LongInt; stdcall;
  external 'advapi32.dll' name 'RegQueryValueExA';
function DevRegCloseKey(AKey: HKEY): LongInt; stdcall;
  external 'advapi32.dll' name 'RegCloseKey';

// InstallPath\(по умолчанию) всех версий в Software\Python\PythonCore
procedure PyRegistryRoots(ARoot: HKEY; AFlags: DWORD; AList: TStrings);
const
  CoreKey = 'Software\Python\PythonCore';
  KeyRead = $20019;
  RegSz = 1;
var
  CoreHandle, PathHandle: HKEY;
  NameBuf: array[0..255] of Char;
  ValueBuf: array[0..1023] of Char;
  ValueLen, ValueType, KeyIdx: DWORD;
begin
  if DevRegOpenKeyEx(ARoot, CoreKey, 0, KeyRead or AFlags, CoreHandle) <> 0 then
    Exit;
  try
    KeyIdx := 0;
    repeat
      FillChar(NameBuf, SizeOf(NameBuf), 0);
      if DevRegEnumKey(CoreHandle, KeyIdx, NameBuf, SizeOf(NameBuf)) <> 0 then
        Break;
      Inc(KeyIdx);
      if DevRegOpenKeyEx(CoreHandle, PChar(string(NameBuf) + '\InstallPath'),
                         0, KeyRead or AFlags, PathHandle) <> 0 then
        Continue;
      try
        FillChar(ValueBuf, SizeOf(ValueBuf), 0);
        ValueLen := SizeOf(ValueBuf) - 1;
        ValueType := 0;
        if (DevRegQueryValueEx(PathHandle, nil, nil, @ValueType, @ValueBuf[0],
                               @ValueLen) = 0) and (ValueType = RegSz) and
           (ValueBuf[0] <> #0) then
          AList.Add(IncludeTrailingPathDelimiter(string(PChar(@ValueBuf[0]))) +
                    'python.exe');
      finally
        DevRegCloseKey(PathHandle);
      end;
    until KeyIdx > 100;
  finally
    DevRegCloseKey(CoreHandle);
  end;
end;
{$ENDIF}

function PyFindAll(AList: TStrings): Integer;
const
  KeyWow64_64 = $0100;
  KeyWow64_32 = $0200;
var
  Candidates, Dirs: TStringList;
  CandIdx: Integer;
  {$IFNDEF UNIX}
  PathExe: string;
  {$ENDIF}
begin
  AList.Clear;
  Candidates := TStringList.Create;
  Dirs := TStringList.Create;
  try
    Candidates.Add(PyLocalExe);
    {$IFDEF UNIX}
    Candidates.Add(DevFindInPath('python3'));
    Candidates.Add(DevFindInPath('python'));
    {$ELSE}
    PathExe := DevFindInPath('python');
    // Windows 10: заглушка Microsoft Store (WindowsApps) - не Python
    if Pos('\windowsapps\', LowerCase(PathExe)) = 0 then
      Candidates.Add(PathExe);
    PyRegistryRoots(HKEY_CURRENT_USER, 0, Candidates);
    PyRegistryRoots(HKEY_LOCAL_MACHINE, KeyWow64_64, Candidates);
    PyRegistryRoots(HKEY_LOCAL_MACHINE, KeyWow64_32, Candidates);
    DevSubDirs(DevEnv('LOCALAPPDATA') + 'Programs\Python', 'Python3*', Dirs);
    DevSubDirs('C:\', 'Python3*', Dirs);
    if DevEnv('ProgramW6432') <> '' then
      DevSubDirs(DevEnv('ProgramW6432'), 'Python3*', Dirs);
    if DevEnv('ProgramFiles(x86)') <> '' then
      DevSubDirs(DevEnv('ProgramFiles(x86)'), 'Python3*', Dirs);
    for CandIdx := 0 to Dirs.Count - 1 do
      Candidates.Add(Dirs[CandIdx] + 'python.exe');
    {$ENDIF}
    for CandIdx := 0 to Candidates.Count - 1 do
      if (Candidates[CandIdx] <> '') and FileExists(Candidates[CandIdx]) then
        DevAddUnique(AList, Candidates[CandIdx]);
  finally
    Candidates.Free;
    Dirs.Free;
  end;
  Result := AList.Count;
end;

function PyEnableSite(const ARoot: string): Boolean;
var
  SR: TSearchRec;
  PthFile: string;
  Lines: TStringList;
  LineIdx: Integer;
  Changed: Boolean;
begin
  Result := False;
  PthFile := '';
  if FindFirst(IncludeTrailingPathDelimiter(ARoot) + 'python*._pth',
               faAnyFile, SR) = 0 then
  try
    PthFile := IncludeTrailingPathDelimiter(ARoot) + SR.Name;
  finally
    FindClose(SR);
  end;
  // ._pth нет - обычный Python, site и так работает
  if PthFile = '' then
  begin
    Result := True;
    Exit;
  end;
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(PthFile);
    except
      Exit;
    end;
    Changed := False;
    for LineIdx := 0 to Lines.Count - 1 do
      if Trim(Lines[LineIdx]) = '#import site' then
      begin
        Lines[LineIdx] := 'import site';
        Changed := True;
      end
      else if Trim(Lines[LineIdx]) = 'import site' then
        Result := True;
    if Changed then
    try
      Lines.SaveToFile(PthFile);
      Result := True;
    except
      Result := False;
    end;
  finally
    Lines.Free;
  end;
end;

end.
