unit GitTool;

// ---------------------------------------------------------------------------
//  Git для unIDE: найти установленный в системе Git for Windows или
//  поставить свой (PortableGit в tools\git) и открыть терминал Git Bash в
//  папке проекта.
//
//  - поиск (GitFindRoot): сначала Git в системе - запись установщика
//    HKLM / HKCU\SOFTWARE\GitForWindows, InstallPath (и 64-битная ветвь
//    реестра: unIDE 32-битный), git.exe в PATH (<корень>\cmd, \bin,
//    \mingw64\bin), Program Files\Git, %LOCALAPPDATA%\Programs\Git; потом
//    свой - tools\git у exe или в %LOCALAPPDATA%\unIDE\tools\git;
//  - свой: PortableGit 2.46.2 - последняя версия Git for Windows для
//    Windows 7 (с 2.47 Windows 7 и 8 не поддерживаются). Архив 7z с
//    распаковщиком (sfx) из выпуска на GitHub, размер и SHA-256 - как
//    опубликованы в выпуске (сверено 22.10.2026). Распаковывает свой 7-Zip
//    (SzSetup), сам архив не запускается; после распаковки нужен
//    post-install.bat (так в README.portable) - его запускает Unit1
//    (GitPostInstallCommand). В реестр и PATH ничего не пишется;
//  - сборка: 64-bit на 64-битной Windows x64, 32-bit - на 32-битной и
//    ARM64; Windows 7 и новее.
//  - версия Git (GitRootVersion) - из ресурса версии git.exe, без запуска:
//    Git 2.47 и новее в Windows 7 / 8.0 не стартует (sh.exe: нет
//    GetSystemTimePreciseAsFileTime в KERNEL32.dll). Нет ресурса - значение
//    CurrentVersion установщика в реестре. Такой системный Git
//    GitFindRoot пропускает: берётся свой, нет своего - '' (GitEnsure
//    предложит установить).
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes, SzSetup;

const
  GitVersion = '2.46.2';
  GitBashName = 'git-bash.exe';
  GitPostInstallName = 'post-install.bat';
  GitInfoFile = 'unide_git.txt';
  // Первая версия Git for Windows, которой нужна Windows 8.1 (6.3)
  GitFirstWin81Only = '2.47.0';

// <папка exe>\tools\git\ и %LOCALAPPDATA%\unIDE\tools\git\
function GitAppDir: WideString;
function GitUserDir: WideString;
// Корень Git for Windows, установленного в системе ('' - нет). AHow - где
// найден (реестр, PATH, папка)
function GitFindInstalled(var AHow: string): WideString;
// Корень своего Git unIDE (есть git-bash.exe и cmd\git.exe); '' - нет
function GitLocalRoot: WideString;
// Версия Git в папке ARoot ('2.46.2'): ресурс версии git.exe, иначе
// CurrentVersion установщика в реестре (если InstallPath - эта папка);
// '' - не узнать. Git не запускается
function GitRootVersion(const ARoot: WideString): string;
// Git версии AVersion работает в этой Windows: с 2.47 нужна Windows 8.1
// и новее. Версия неизвестна - True (проверить нечем)
function GitVersionFitsOs(const AVersion: string;
  const AOs: TSzOsInfo): Boolean;
// Git в папке ARoot работает в этой Windows
function GitRootFitsOs(const ARoot: WideString): Boolean;
// Корень Git: системный (если работает в этой Windows), иначе свой; ''
// - нет подходящего
function GitFindRoot(var AHow: string): WideString;
// Куда ставить свой: где уже есть, иначе у exe, если туда пишется, иначе
// в профиль; '' - никуда
function GitChooseTargetDir: WideString;
// Сборка для этой Windows; False - PortableGit 2.46.2 для неё нет
function GitChoosePackage(const AOs: TSzOsInfo;
  var APackage: TSzPackage): Boolean;
// План установки (распаковывает свой 7-Zip ASevenZip)
function GitPlan(const APackage: TSzPackage; const AOsName: string;
  const ASevenZip: WideString): TSzPlan;
// Командная строка post-install.bat (без окна), рабочая папка - ARoot; ''
// - запускать нечего (уже выполнен)
function GitPostInstallCommand(const ARoot: WideString): WideString;
// Командная строка терминала в папке ADir: Git Bash, а без git-bash.exe
// (MinGit) - cmd.exe с <корень>\cmd в PATH (рабочая папка - ADir)
function GitTerminalCommand(const ARoot, ADir: WideString): WideString;

implementation

const
  GitPackageCount = 2;
  GitPackages: array[0..GitPackageCount - 1] of TSzPackage = (
    (Version: '2.46.2'; Arch: '64-bit'; Need64: True; MinMajor: 6;
     MinMinor: 1; FileName: 'PortableGit-2.46.2-64-bit.7z.exe';
     Size: 61723136;
     Sha256: '58ae5c1a27d3f9ce8518c1a187860973cfa4dd604f518350e84f7baf418fc9fa';
     Url1: 'https://github.com/git-for-windows/git/releases/download/' +
           'v2.46.2.windows.1/PortableGit-2.46.2-64-bit.7z.exe';
     Url2: ''),
    (Version: '2.46.2'; Arch: '32-bit'; Need64: False; MinMajor: 6;
     MinMinor: 1; FileName: 'PortableGit-2.46.2-32-bit.7z.exe';
     Size: 58971296;
     Sha256: '7351e28f498010f0aa2fd63abbd704698db38cf6f881e2417fb3d73e5a7e6f87';
     Url1: 'https://github.com/git-for-windows/git/releases/download/' +
           'v2.46.2.windows.1/PortableGit-2.46.2-32-bit.7z.exe';
     Url2: ''));

  GitRegKey = 'SOFTWARE\GitForWindows';
  GitKeyRead = $20019;          // KEY_READ
  GitKeyWow64_64 = $0100;       // KEY_WOW64_64KEY
  GitRegSz = 1;
  GitRegExpandSz = 2;

function GitRegOpenKeyEx(AKey: HKEY; ASubKey: PWideChar; AOptions: DWORD;
  ADesired: DWORD; var AResult: HKEY): LongInt; stdcall;
  external 'advapi32.dll' name 'RegOpenKeyExW';
function GitRegQueryValueEx(AKey: HKEY; AValueName: PWideChar;
  AReserved: Pointer; AType: PDWORD; AData: Pointer;
  ADataSize: PDWORD): LongInt; stdcall;
  external 'advapi32.dll' name 'RegQueryValueExW';
function GitRegCloseKey(AKey: HKEY): LongInt; stdcall;
  external 'advapi32.dll' name 'RegCloseKey';
function GitGetFileVersionInfoSize(AFileName: PWideChar;
  var AHandle: DWORD): DWORD; stdcall;
  external 'version.dll' name 'GetFileVersionInfoSizeW';
function GitGetFileVersionInfo(AFileName: PWideChar; AHandle, ASize: DWORD;
  AData: Pointer): BOOL; stdcall;
  external 'version.dll' name 'GetFileVersionInfoW';
function GitVerQueryValue(ABlock: Pointer; ASubBlock: PWideChar;
  var ABuffer: Pointer; var ALength: UINT): BOOL; stdcall;
  external 'version.dll' name 'VerQueryValueW';

type
  // VS_FIXEDFILEINFO
  TGitFixedFileInfo = record
    dwSignature, dwStrucVersion: DWORD;
    dwFileVersionMS, dwFileVersionLS: DWORD;
    dwProductVersionMS, dwProductVersionLS: DWORD;
    dwFileFlagsMask, dwFileFlags, dwFileOS, dwFileType, dwFileSubtype: DWORD;
    dwFileDateMS, dwFileDateLS: DWORD;
  end;
  PGitFixedFileInfo = ^TGitFixedFileInfo;
function GitGetEnv(AName: PWideChar; ABuffer: PWideChar;
  ASize: DWORD): DWORD; stdcall;
  external 'kernel32.dll' name 'GetEnvironmentVariableW';

function GitAppDir: WideString;
begin
  Result := SzToolsAppDir + 'git\';
end;

function GitUserDir: WideString;
begin
  Result := SzToolsUserDir;
  if Result <> '' then
    Result := Result + 'git\';
end;

// В папке - Git for Windows: есть cmd\git.exe
function GitIsRoot(const ARoot: WideString): Boolean;
begin
  Result := (ARoot <> '') and SzFileExists(SzWithSlash(ARoot) + 'cmd\git.exe');
end;

function GitEnv(const AName: WideString): WideString;
var
  Buffer: array[0..32767] of WideChar;
  Len: DWORD;
begin
  Len := GitGetEnv(PWideChar(AName), Buffer, Length(Buffer));
  if (Len = 0) or (Len >= DWORD(Length(Buffer))) then
    Result := ''
  else
    Result := PWideChar(@Buffer[0]);
end;

// Строковое значение AName из HKLM / HKCU\SOFTWARE\GitForWindows
// (AWow64 - 64-битная ветвь)
function GitRegValue(ARoot: HKEY; AWow64: Boolean;
  const AName: WideString): WideString;
var
  KeyHandle: HKEY;
  Access, ValueType, DataSize: DWORD;
  Buffer: array[0..1023] of WideChar;
  ValueName: WideString;
begin
  Result := '';
  Access := GitKeyRead;
  if AWow64 then
    Access := Access or GitKeyWow64_64;
  if GitRegOpenKeyEx(ARoot, GitRegKey, 0, Access, KeyHandle) <> 0 then
    Exit;
  try
    ValueName := AName;
    FillChar(Buffer, SizeOf(Buffer), 0);
    DataSize := SizeOf(Buffer) - SizeOf(WideChar);
    ValueType := 0;
    if (GitRegQueryValueEx(KeyHandle, PWideChar(ValueName), nil, @ValueType,
       @Buffer[0], @DataSize) = 0) and
       ((ValueType = GitRegSz) or (ValueType = GitRegExpandSz)) then
      Result := PWideChar(@Buffer[0]);
  finally
    GitRegCloseKey(KeyHandle);
  end;
end;

// InstallPath из HKLM / HKCU\SOFTWARE\GitForWindows
function GitRegInstallPath(ARoot: HKEY; AWow64: Boolean): WideString;
begin
  Result := GitRegValue(ARoot, AWow64, 'InstallPath');
end;

// Позиция символа AChar в AText (0 - нет); Pos для WideString в Delphi 7
// не годится
function GitCharPos(AChar: WideChar; const AText: WideString): Integer;
var
  CharIndex: Integer;
begin
  Result := 0;
  for CharIndex := 1 to Length(AText) do
    if AText[CharIndex] = AChar then
    begin
      Result := CharIndex;
      Exit;
    end;
end;

// AText кончается на ATail
function GitEndsWith(const AText, ATail: WideString): Boolean;
begin
  Result := (Length(AText) >= Length(ATail)) and
    (Copy(AText, Length(AText) - Length(ATail) + 1, Length(ATail)) = ATail);
end;

// git.exe в папке из PATH -> корень Git for Windows
function GitFromPath: WideString;
var
  PathText, Dir, Lower: WideString;
  SemiPos: Integer;
begin
  Result := '';
  PathText := GitEnv('PATH');
  while PathText <> '' do
  begin
    SemiPos := GitCharPos(';', PathText);
    if SemiPos = 0 then
      SemiPos := Length(PathText) + 1;
    Dir := Trim(Copy(PathText, 1, SemiPos - 1));
    Delete(PathText, 1, SemiPos);
    if (Dir <> '') and (Dir[1] = '"') then
      Dir := Copy(Dir, 2, Length(Dir) - 2);
    Dir := SzNoSlash(Dir);
    if (Dir = '') or not SzFileExists(Dir + '\git.exe') then
      Continue;
    Lower := WideLowerCase(Dir);
    // <корень>\cmd, <корень>\bin, <корень>\mingw64\bin, <корень>\mingw32\bin
    if GitEndsWith(Lower, '\mingw64\bin') or GitEndsWith(Lower, '\mingw32\bin') then
      Result := Copy(Dir, 1, Length(Dir) - Length('\mingw64\bin') + 1)
    else if GitEndsWith(Lower, '\cmd') or GitEndsWith(Lower, '\bin') then
      Result := Copy(Dir, 1, Length(Dir) - 3);
    if GitIsRoot(Result) then
      Exit;
    Result := '';
  end;
end;

function GitFindInstalled(var AHow: string): WideString;
var
  Candidates: array[0..6] of WideString;
  Hows: array[0..6] of string;
  CandIndex: Integer;
begin
  Result := '';
  AHow := '';
  Candidates[0] := GitRegInstallPath(HKEY_LOCAL_MACHINE, True);
  Hows[0] := 'реестр HKLM\' + GitRegKey;
  Candidates[1] := GitRegInstallPath(HKEY_LOCAL_MACHINE, False);
  Hows[1] := 'реестр HKLM\' + GitRegKey;
  Candidates[2] := GitRegInstallPath(HKEY_CURRENT_USER, False);
  Hows[2] := 'реестр HKCU\' + GitRegKey;
  Candidates[3] := GitFromPath;
  Hows[3] := 'git.exe в PATH';
  Candidates[4] := GitEnv('ProgramW6432');
  if Candidates[4] <> '' then
    Candidates[4] := SzWithSlash(Candidates[4]) + 'Git';
  Hows[4] := 'Program Files\Git';
  Candidates[5] := GitEnv('ProgramFiles');
  if Candidates[5] <> '' then
    Candidates[5] := SzWithSlash(Candidates[5]) + 'Git';
  Hows[5] := 'Program Files\Git';
  Candidates[6] := GitEnv('LOCALAPPDATA');
  if Candidates[6] <> '' then
    Candidates[6] := SzWithSlash(Candidates[6]) + 'Programs\Git';
  Hows[6] := '%LOCALAPPDATA%\Programs\Git';
  for CandIndex := 0 to High(Candidates) do
    if GitIsRoot(Candidates[CandIndex]) then
    begin
      Result := SzWithSlash(Candidates[CandIndex]);
      AHow := Hows[CandIndex];
      Exit;
    end;
end;

function GitLocalRoot: WideString;
var
  Dirs: array[0..1] of WideString;
  DirIndex: Integer;
begin
  Result := '';
  Dirs[0] := GitAppDir;
  Dirs[1] := GitUserDir;
  for DirIndex := 0 to 1 do
    if GitIsRoot(Dirs[DirIndex]) and
       SzFileExists(Dirs[DirIndex] + GitBashName) then
    begin
      Result := Dirs[DirIndex];
      Exit;
    end;
end;

// Версия из ресурса файла: '2.46.2' (третье число - сборка Git); ''
// - ресурса нет
function GitFileVersion(const AFileName: WideString): string;
var
  InfoSize, Dummy: DWORD;
  InfoData: Pointer;
  FixedInfo: PGitFixedFileInfo;
  FixedLen: UINT;
  RootBlock: WideString;
begin
  Result := '';
  if not SzFileExists(AFileName) then
    Exit;
  Dummy := 0;
  InfoSize := GitGetFileVersionInfoSize(PWideChar(AFileName), Dummy);
  if InfoSize = 0 then
    Exit;
  GetMem(InfoData, InfoSize);
  try
    if not GitGetFileVersionInfo(PWideChar(AFileName), 0, InfoSize,
       InfoData) then
      Exit;
    RootBlock := '\';
    FixedInfo := nil;
    FixedLen := 0;
    if GitVerQueryValue(InfoData, PWideChar(RootBlock), Pointer(FixedInfo),
       FixedLen) and (FixedInfo <> nil) and (FixedLen > 0) and
       (FixedInfo^.dwFileVersionMS <> 0) then
      Result := IntToStr(FixedInfo^.dwFileVersionMS shr 16) + '.' +
        IntToStr(FixedInfo^.dwFileVersionMS and $FFFF) + '.' +
        IntToStr(FixedInfo^.dwFileVersionLS shr 16);
  finally
    FreeMem(InfoData);
  end;
end;

function GitRootVersion(const ARoot: WideString): string;
const
  ExeCount = 4;
  ExeNames: array[0..ExeCount - 1] of string = (
    'mingw64\bin\git.exe', 'mingw32\bin\git.exe', 'clangarm64\bin\git.exe',
    'cmd\git.exe');
var
  Root, RootLower: WideString;
  ExeIndex, RegIndex: Integer;
  RegRoots: array[0..2] of HKEY;
  RegWow64: array[0..2] of Boolean;
begin
  Result := '';
  if ARoot = '' then
    Exit;
  Root := SzWithSlash(ARoot);
  for ExeIndex := 0 to ExeCount - 1 do
  begin
    Result := GitFileVersion(Root + WideString(ExeNames[ExeIndex]));
    if Result <> '' then
      Exit;
  end;
  // Запись установщика - только если она про эту папку
  RegRoots[0] := HKEY_LOCAL_MACHINE;
  RegWow64[0] := True;
  RegRoots[1] := HKEY_LOCAL_MACHINE;
  RegWow64[1] := False;
  RegRoots[2] := HKEY_CURRENT_USER;
  RegWow64[2] := False;
  RootLower := WideLowerCase(Root);
  for RegIndex := 0 to 2 do
    if WideLowerCase(SzWithSlash(GitRegInstallPath(RegRoots[RegIndex],
       RegWow64[RegIndex]))) = RootLower then
    begin
      Result := Trim(string(GitRegValue(RegRoots[RegIndex], RegWow64[RegIndex],
        'CurrentVersion')));
      if Result <> '' then
        Exit;
    end;
end;

// '2.46.2' -> 2046002; '2.46' -> 2046000; не число - -1
function GitVersionNumber(const AVersion: string): Integer;
var
  Rest, Part: string;
  PartIndex, DotPos, PartValue: Integer;
begin
  Result := 0;
  Rest := Trim(AVersion);
  if Rest = '' then
  begin
    Result := -1;
    Exit;
  end;
  for PartIndex := 0 to 2 do
  begin
    DotPos := Pos('.', Rest);
    if DotPos = 0 then
      DotPos := Length(Rest) + 1;
    Part := Copy(Rest, 1, DotPos - 1);
    Delete(Rest, 1, DotPos);
    if (Part = '') and (PartIndex > 0) then
      PartValue := 0
    else
      PartValue := StrToIntDef(Part, -1);
    if (PartValue < 0) or (PartValue > 999) then
    begin
      Result := -1;
      Exit;
    end;
    Result := Result * 1000 + PartValue;
  end;
end;

function GitVersionFitsOs(const AVersion: string;
  const AOs: TSzOsInfo): Boolean;
var
  VersionNumber: Integer;
begin
  Result := True;
  VersionNumber := GitVersionNumber(AVersion);
  if VersionNumber < 0 then
    Exit;
  // Windows 8.1 - 6.3; Windows 10 и новее - 10.0
  if (AOs.Major > 6) or ((AOs.Major = 6) and (AOs.Minor >= 3)) then
    Exit;
  Result := VersionNumber < GitVersionNumber(GitFirstWin81Only);
end;

function GitRootFitsOs(const ARoot: WideString): Boolean;
var
  OsInfo: TSzOsInfo;
begin
  SzGetOsInfo(OsInfo);
  Result := GitVersionFitsOs(GitRootVersion(ARoot), OsInfo);
end;

function GitFindRoot(var AHow: string): WideString;
var
  Installed: WideString;
  InstalledHow: string;
begin
  Installed := GitFindInstalled(InstalledHow);
  if (Installed <> '') and GitRootFitsOs(Installed) then
  begin
    Result := Installed;
    AHow := InstalledHow;
    Exit;
  end;
  Result := GitLocalRoot;
  if Result <> '' then
  begin
    AHow := 'свой Git unIDE';
    if Installed <> '' then
      AHow := AHow + '; Git ' + GitRootVersion(Installed) + ' в системе ' +
        'в этой Windows не работает';
    Exit;
  end;
  AHow := '';
end;

function GitCanPlace(const ADir: WideString): Boolean;
begin
  Result := (ADir <> '') and
    SzCanWrite(ExtractFilePath(string(SzNoSlash(ADir))));
end;

function GitChooseTargetDir: WideString;
begin
  Result := GitLocalRoot;
  if (Result <> '') and GitCanPlace(Result) then
    Exit;
  Result := GitAppDir;
  if GitCanPlace(Result) then
    Exit;
  Result := GitUserDir;
  if GitCanPlace(Result) then
    Exit;
  Result := '';
end;

function GitChoosePackage(const AOs: TSzOsInfo;
  var APackage: TSzPackage): Boolean;
var
  PackageIndex: Integer;
begin
  Result := False;
  if not AOs.IsNT then
    Exit;
  for PackageIndex := 0 to GitPackageCount - 1 do
    with GitPackages[PackageIndex] do
      if (not Need64 or AOs.Is64) and
         ((AOs.Major > MinMajor) or
          ((AOs.Major = MinMajor) and (AOs.Minor >= MinMinor))) then
      begin
        APackage := GitPackages[PackageIndex];
        Result := True;
        Exit;
      end;
end;

function GitPlan(const APackage: TSzPackage; const AOsName: string;
  const ASevenZip: WideString): TSzPlan;
begin
  Result.Title := 'Git ' + APackage.Version + ' (' + APackage.Arch + ')';
  SetLength(Result.Files, 1);
  Result.Files[0].Url1 := APackage.Url1;
  Result.Files[0].Url2 := APackage.Url2;
  Result.Files[0].FileName := APackage.FileName;
  Result.Files[0].Size := APackage.Size;
  Result.Files[0].Sha256 := APackage.Sha256;
  Result.Extractor := ASevenZip;
  Result.Archive := 0;
  Result.ExtractNames := '*';       // всё содержимое (около 400 МБ)
  Result.ExtractSubDir := '';
  Result.MoveNames := '';           // папка tools\git - целиком
  Result.CheckFile := GitBashName;
  Result.InfoFile := GitInfoFile;
  Result.InfoText := 'Git for Windows ' + APackage.Version + ' (PortableGit, ' +
    APackage.Arch + '), установлен unIDE ' +
    FormatDateTime('yyyy-mm-dd hh:nn', Now) + ' для ' + AOsName + #13#10 +
    APackage.Url1 + #13#10 + 'SHA-256 ' + APackage.FileName + ': ' +
    APackage.Sha256 + #13#10 +
    'Распакован своим 7-Zip unIDE, затем выполнен post-install.bat ' +
    '(README.portable). В реестр и PATH ничего не записано.' + #13#10;
end;

function GitPostInstallCommand(const ARoot: WideString): WideString;
var
  Root: WideString;
begin
  Result := '';
  Root := SzWithSlash(ARoot);
  if not SzFileExists(Root + GitPostInstallName) or
     not SzFileExists(Root + GitBashName) then
    Exit;
  // Так велит сам post-install.bat: без окна консоли
  Result := WideString('"') + Root + GitBashName +
    WideString('" --no-needs-console --hide --no-cd --command=') +
    GitPostInstallName;
end;

function GitTerminalCommand(const ARoot, ADir: WideString): WideString;
var
  Root, Dir: WideString;
begin
  Root := SzWithSlash(ARoot);
  // Корень диска 'D:\' - 'D:\.': '\' перед кавычкой её экранирует
  Dir := SzNoSlash(ADir);
  if (Dir <> '') and (Dir[Length(Dir)] = '\') then
    Dir := Dir + '.';
  if SzFileExists(Root + GitBashName) then
    Result := WideString('"') + Root + GitBashName + WideString('" "--cd=') +
      Dir + WideString('"')
  else
    // set "PATH=..." - вся строка после /K, кавычки снаружи cmd не снимет
    Result := WideString('cmd.exe /K set "PATH=') + Root +
      WideString('cmd;%PATH%"');
end;

end.
