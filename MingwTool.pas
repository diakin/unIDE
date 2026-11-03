unit MingwTool;

// ---------------------------------------------------------------------------
//  MinGW-w64 (GCC для Windows) для unIDE: свой компилятор в tools\mingw -
//  для сборки скетча Arduino под ПК (эмулятор: скетч + заглушки UTFT и
//  Arduino API собираются g++ в обычный exe). В системе ничего не
//  ставится: ни реестра, ни PATH; g++ вызывается по полному пути.
//
//  - сборка: WinLibs (Brecht Sanders, winlibs.com), GCC 16.2.0 + MinGW-w64
//    14.0.0, рантайм MSVCRT (есть во всех версиях Windows; UCRT - с
//    Windows 10), без LLVM. x86_64 (posix, seh) на 64-битной Windows,
//    i686 (posix, dwarf) - на 32-битной;
//  - архив 7z из выпуска на GitHub (около 107 МБ, распакованный - около
//    0,5 ГБ). Точный размер заранее не записан: SHA-256 берётся из файла
//    <архив>.sha256 того же выпуска (качается первым) и проверяется после
//    загрузки архива (SzSetup, SzShaFromPrev);
//  - распаковывает свой 7-Zip unIDE; из архива берётся папка mingw64
//    (mingw32), она становится tools\mingw;
//  - работает ли эта сборка GCC в Windows 7, не проверено: после
//    установки Unit1 запускает g++ --version и пишет ответ в журнал.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes, SzSetup;

const
  MingwVersion = '16.2.0';
  MingwRuntime = 'MinGW-w64 14.0.0 MSVCRT';
  MingwRelease = '16.2.0posix-23.1.3-14.0.0-msvcrt-r3';
  MingwGppName = 'g++.exe';
  MingwInfoFile = 'unide_mingw.txt';
  MingwSite = 'https://winlibs.com';

type
  TMingwPackage = record
    Arch: string;            // 'x86_64' / 'i686'
    Need64: Boolean;
    FileName: string;        // архив выпуска
    ApproxSize: Integer;     // примерно, байт (для хода и вопроса)
    SubDir: string;          // папка внутри архива
  end;

// <папка exe>\tools\mingw\ и %LOCALAPPDATA%\unIDE\tools\mingw\
function MingwAppDir: WideString;
function MingwUserDir: WideString;
// g++.exe своего MinGW: сначала у exe, потом в профиле; нет - ''
function MingwLocalGpp: WideString;
// Куда ставить: где уже есть, иначе у exe, если туда пишется, иначе в
// профиль; '' - никуда
function MingwChooseTargetDir: WideString;
// Сборка для этой Windows; False - нет (не NT)
function MingwChoosePackage(const AOs: TSzOsInfo;
  var APackage: TMingwPackage): Boolean;
// Адрес файла выпуска
function MingwUrl(const AFileName: string): string;
// План установки (распаковывает свой 7-Zip ASevenZip)
function MingwPlan(const APackage: TMingwPackage; const AOsName: string;
  const ASevenZip: WideString): TSzPlan;
// Что записано в unide_mingw.txt своего MinGW (первая строка); '' - нет
function MingwInstalledInfo(const AGpp: WideString): string;

implementation

const
  MingwPackageCount = 2;
  MingwPackages: array[0..MingwPackageCount - 1] of TMingwPackage = (
    (Arch: 'x86_64'; Need64: True;
     FileName: 'winlibs-x86_64-posix-seh-gcc-16.2.0-mingw-w64msvcrt-' +
               '14.0.0-r3.7z';
     ApproxSize: 113000000; SubDir: 'mingw64'),
    (Arch: 'i686'; Need64: False;
     FileName: 'winlibs-i686-posix-dwarf-gcc-16.2.0-mingw-w64msvcrt-' +
               '14.0.0-r3.7z';
     ApproxSize: 114000000; SubDir: 'mingw32'));

function MingwAppDir: WideString;
begin
  Result := SzToolsAppDir + 'mingw\';
end;

function MingwUserDir: WideString;
begin
  Result := SzToolsUserDir;
  if Result <> '' then
    Result := Result + 'mingw\';
end;

function MingwGppOf(const ARoot: WideString): WideString;
begin
  Result := SzWithSlash(ARoot) + 'bin\' + MingwGppName;
end;

function MingwLocalGpp: WideString;
begin
  Result := MingwGppOf(MingwAppDir);
  if SzFileExists(Result) then
    Exit;
  if MingwUserDir <> '' then
  begin
    Result := MingwGppOf(MingwUserDir);
    if SzFileExists(Result) then
      Exit;
  end;
  Result := '';
end;

// Папку можно создать или заменить: пишется в папку над ней
function MingwCanPlace(const ADir: WideString): Boolean;
begin
  Result := (ADir <> '') and
    SzCanWrite(ExtractFilePath(string(SzNoSlash(ADir))));
end;

function MingwChooseTargetDir: WideString;
var
  Gpp: WideString;
begin
  Gpp := MingwLocalGpp;
  if Gpp <> '' then
  begin
    // <корень>\bin\g++.exe -> <корень>\
    Result := ExtractFilePath(string(SzNoSlash(ExtractFilePath(string(Gpp)))));
    if MingwCanPlace(Result) then
      Exit;
  end;
  Result := MingwAppDir;
  if MingwCanPlace(Result) then
    Exit;
  Result := MingwUserDir;
  if MingwCanPlace(Result) then
    Exit;
  Result := '';
end;

function MingwChoosePackage(const AOs: TSzOsInfo;
  var APackage: TMingwPackage): Boolean;
var
  PackageIdx: Integer;
begin
  Result := False;
  if not AOs.IsNT then
    Exit;
  for PackageIdx := 0 to MingwPackageCount - 1 do
    if not MingwPackages[PackageIdx].Need64 or AOs.Is64 then
    begin
      APackage := MingwPackages[PackageIdx];
      Result := True;
      Exit;
    end;
end;

function MingwUrl(const AFileName: string): string;
begin
  Result := 'https://github.com/brechtsanders/winlibs_mingw/releases/' +
    'download/' + MingwRelease + '/' + AFileName;
end;

function MingwPlan(const APackage: TMingwPackage; const AOsName: string;
  const ASevenZip: WideString): TSzPlan;
begin
  Result.Title := 'MinGW-w64 GCC ' + MingwVersion + ' (' + APackage.Arch + ')';
  SetLength(Result.Files, 2);
  // Сначала - сумма архива из того же выпуска
  Result.Files[0].Url1 := MingwUrl(APackage.FileName + '.sha256');
  Result.Files[0].Url2 := '';
  Result.Files[0].FileName := APackage.FileName + '.sha256';
  Result.Files[0].Size := -200;
  Result.Files[0].Sha256 := '';
  Result.Files[1].Url1 := MingwUrl(APackage.FileName);
  Result.Files[1].Url2 := '';
  Result.Files[1].FileName := APackage.FileName;
  Result.Files[1].Size := -APackage.ApproxSize;
  Result.Files[1].Sha256 := SzShaFromPrev;
  Result.Extractor := ASevenZip;
  Result.Archive := 1;
  // Имя папки - 7-Zip достаёт её со всем содержимым
  Result.ExtractNames := APackage.SubDir;
  Result.ExtractSubDir := APackage.SubDir;
  Result.MoveNames := '';           // папка tools\mingw - целиком
  Result.CheckFile := 'bin\' + MingwGppName;
  Result.InfoFile := MingwInfoFile;
  Result.InfoText := 'MinGW-w64 GCC ' + MingwVersion + ' (' + MingwRuntime +
    ', WinLibs, ' + APackage.Arch + '), установлен unIDE ' +
    FormatDateTime('yyyy-mm-dd hh:nn', Now) + ' для ' + AOsName + #13#10 +
    MingwUrl(APackage.FileName) + #13#10 +
    'SHA-256 сверен с ' + APackage.FileName + '.sha256 выпуска.' + #13#10 +
    'Распакован своим 7-Zip unIDE. В реестр и PATH ничего не записано.' +
    #13#10;
end;

function MingwInstalledInfo(const AGpp: WideString): string;
var
  Lines: TStringList;
  InfoName: string;
begin
  Result := '';
  if AGpp = '' then
    Exit;
  InfoName := ExtractFilePath(string(SzNoSlash(ExtractFilePath(string(AGpp))))) +
    MingwInfoFile;
  if not FileExists(InfoName) then
    Exit;
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(InfoName);
    except
      Exit;
    end;
    if Lines.Count > 0 then
      Result := Lines[0];
  finally
    Lines.Free;
  end;
end;

end.
