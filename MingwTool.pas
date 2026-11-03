unit MingwTool;

// ---------------------------------------------------------------------------
//  MinGW-w64 (GCC для Windows) для unIDE: свой компилятор в tools\mingw -
//  для сборки скетча Arduino под ПК (эмулятор: скетч + заглушки UTFT и
//  Arduino API собираются g++ в обычный exe). В системе ничего не
//  ставится: ни реестра, ни PATH; g++ вызывается по полному пути.
//
//  - сборка: xPack MinGW-w64 GCC 12.2.0-1 (xpack-dev-tools), архив
//    win32-x64.zip, около 308 МБ; GitHub, зеркало - SourceForge. GCC 16
//    (WinLibs) в Windows 7, по словам Андрея, не работает, поэтому GCC 12.
//    По странице выпуска xPack: Windows 7 с Universal C Runtime
//    (обновление KB2999226), Windows 8, 10; только 64-битная Windows;
//  - точный размер заранее не записан: SHA-256 берётся из файла
//    <архив>.sha того же выпуска (качается первым) и проверяется после
//    загрузки архива (SzSetup, SzShaFromPrev). На странице выпуска сумма
//    zip - 43ca4e24...26132567;
//  - распаковывает свой 7-Zip unIDE; из архива берётся папка
//    xpack-mingw-w64-gcc-12.2.0-1, она становится tools\mingw. В ней
//    bin\x86_64-w64-mingw32-g++.exe (64-битные программы) и
//    bin\i686-w64-mingw32-g++.exe (32-битные), g++.exe без приставки нет.
//    Имя папки - по обычной раскладке архивов xPack, сам архив отсюда не
//    открывался: не та раскладка - установка скажет, что нет CheckFile;
//  - после установки Unit1 запускает g++ --version и пишет ответ в журнал.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes, SzSetup;

const
  MingwVersion = '12.2.0';
  MingwRuntime = 'xPack 12.2.0-1';
  MingwRelease = 'v12.2.0-1';
  MingwGppName = 'x86_64-w64-mingw32-g++.exe';
  MingwGpp32Name = 'i686-w64-mingw32-g++.exe';
  MingwInfoFile = 'unide_mingw.txt';
  MingwSite = 'https://xpack-dev-tools.github.io/mingw-w64-gcc-xpack/';

type
  TMingwPackage = record
    Arch: string;            // 'x64'
    Need64: Boolean;
    FileName: string;        // архив выпуска
    ApproxSize: Integer;     // примерно, байт (для хода и вопроса)
    SubDir: string;          // папка внутри архива
  end;

// <папка exe>\tools\mingw\ и %LOCALAPPDATA%\unIDE\tools\mingw\
function MingwAppDir: WideString;
function MingwUserDir: WideString;
// g++ своего MinGW (64-битный): сначала у exe, потом в профиле; нет - ''
function MingwLocalGpp: WideString;
// Куда ставить: где уже есть, иначе у exe, если туда пишется, иначе в
// профиль; '' - никуда
function MingwChooseTargetDir: WideString;
// В system32 есть ucrtbase.dll (Universal C Runtime)
function MingwHasUcrt: Boolean;
// Сборка для этой Windows; False - нет (AReason - почему). True и
// AReason <> '' - с оговоркой (нет UCRT)
function MingwChoosePackage(const AOs: TSzOsInfo;
  var APackage: TMingwPackage; var AReason: string): Boolean;
// Адрес файла выпуска: GitHub и зеркало на SourceForge
function MingwUrl(const AFileName: string): string;
function MingwUrl2(const AFileName: string): string;
// План установки (распаковывает свой 7-Zip ASevenZip)
function MingwPlan(const APackage: TMingwPackage; const AOsName: string;
  const ASevenZip: WideString): TSzPlan;
// Что записано в unide_mingw.txt своего MinGW (первая строка); '' - нет
function MingwInstalledInfo(const AGpp: WideString): string;

implementation

const
  MingwPackageCount = 1;
  MingwPackages: array[0..MingwPackageCount - 1] of TMingwPackage = (
    (Arch: 'x64'; Need64: True;
     FileName: 'xpack-mingw-w64-gcc-12.2.0-1-win32-x64.zip';
     ApproxSize: 323000000; SubDir: 'xpack-mingw-w64-gcc-12.2.0-1'));

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
    // <корень>\bin\g++ -> <корень>\
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

function MingwHasUcrt: Boolean;
var
  SysDir: array[0..MAX_PATH] of Char;
  DirLen: UINT;
begin
  DirLen := GetSystemDirectory(SysDir, MAX_PATH);
  Result := (DirLen > 0) and
    FileExists(IncludeTrailingPathDelimiter(string(SysDir)) + 'ucrtbase.dll');
end;

function MingwChoosePackage(const AOs: TSzOsInfo;
  var APackage: TMingwPackage; var AReason: string): Boolean;
var
  PackageIdx: Integer;
begin
  Result := False;
  AReason := '';
  if not AOs.IsNT or (AOs.Major < 6) or
     ((AOs.Major = 6) and (AOs.Minor < 1)) then
  begin
    AReason := 'xPack MinGW-w64 GCC ' + MingwVersion + ' работает в ' +
      'Windows 7 и новее, здесь ' + AOs.Name;
    Exit;
  end;
  for PackageIdx := 0 to MingwPackageCount - 1 do
    if not MingwPackages[PackageIdx].Need64 or AOs.Is64 then
    begin
      APackage := MingwPackages[PackageIdx];
      Result := True;
      Break;
    end;
  if not Result then
  begin
    AReason := 'xPack MinGW-w64 GCC ' + MingwVersion + ' есть только для ' +
      '64-битной Windows, здесь ' + AOs.Name;
    Exit;
  end;
  if not MingwHasUcrt then
    AReason := 'в Windows нет Universal C Runtime (ucrtbase.dll в ' +
      'system32). GCC из xPack без него, скорее всего, не запустится: ' +
      'поставьте обновление KB2999226 (или распространяемый пакет ' +
      'Visual C++ 2015 и новее)';
end;

function MingwUrl(const AFileName: string): string;
begin
  Result := 'https://github.com/xpack-dev-tools/mingw-w64-gcc-xpack/' +
    'releases/download/' + MingwRelease + '/' + AFileName;
end;

function MingwUrl2(const AFileName: string): string;
begin
  Result := 'https://downloads.sourceforge.net/project/mingw-w64-gcc-xpack/' +
    MingwRelease + '/' + AFileName;
end;

function MingwPlan(const APackage: TMingwPackage; const AOsName: string;
  const ASevenZip: WideString): TSzPlan;
begin
  Result.Title := 'MinGW-w64 GCC ' + MingwVersion + ' (' + APackage.Arch + ')';
  SetLength(Result.Files, 2);
  // Сначала - сумма архива из того же выпуска ('<сумма>  <имя>')
  Result.Files[0].Url1 := MingwUrl(APackage.FileName + '.sha');
  Result.Files[0].Url2 := MingwUrl2(APackage.FileName + '.sha');
  Result.Files[0].FileName := APackage.FileName + '.sha';
  Result.Files[0].Size := -200;
  Result.Files[0].Sha256 := '';
  Result.Files[1].Url1 := MingwUrl(APackage.FileName);
  Result.Files[1].Url2 := MingwUrl2(APackage.FileName);
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
    ', ' + APackage.Arch + '), установлен unIDE ' +
    FormatDateTime('yyyy-mm-dd hh:nn', Now) + ' для ' + AOsName + #13#10 +
    MingwUrl(APackage.FileName) + #13#10 +
    'SHA-256 сверен с ' + APackage.FileName + '.sha выпуска.' + #13#10 +
    'Распакован своим 7-Zip unIDE. В реестр и PATH ничего не записано.' +
    #13#10 + 'g++: bin\' + MingwGppName + ' (64-бит), bin\' +
    MingwGpp32Name + ' (32-бит).' + #13#10;
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
