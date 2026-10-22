unit RufusTool;

// ---------------------------------------------------------------------------
//  Rufus для unIDE: запись образа (ReactOS bootcd.iso и др.) на флешку.
//  Свой Rufus в tools\rufus (как 7-Zip, QEMU, Git): в системе ничего не
//  ставится, Rufus работает переносимо - имя rufusp.exe ('p' в имени), его
//  настройки - rufus.ini рядом, не в реестре.
//
//  - где: <папка exe>\tools\rufus\; если туда не записать -
//    %LOCALAPPDATA%\unIDE\tools\rufus\;
//  - какую сборку брать (RufusChoosePackage):
//      Windows 8 и новее - официальный Rufus 4.15 (Пит Батард, подпись
//        Akeo Consulting): x64, x86 или ARM64 по Windows;
//      Windows 7 - Rufus 4.6.2208 из форка Alex313031/rufus-win7 (сборка
//        автора форка, без подписи; разбор кода - в документе проекта
//        Rufus_win7_ревью_2026-10-22.md). Ему нужна функция
//        SetDefaultDllDirectories (обновление KB2533623): exe её
//        импортирует и без неё не запустится;
//      Windows 7 без KB2533623 - официальный Rufus 3.22 (последний с
//        поддержкой Windows 7, x86, подписан);
//      Vista и старше - нет (Rufus 3.x - Windows 7 и новее);
//  - официальные exe качаются как есть (не распаковываются) и
//    записываются под именем rufusp.exe; форк - zip, из него свой 7-Zip
//    unIDE достаёт rufusp.exe (diskcopy.dll из zip не берётся: Rufus сам
//    скачает его с сервера Microsoft, если выбрать MS-DOS);
//  - размеры и SHA-256 сняты с файлов выпусков на GitHub 22.10.2026;
//  - запуск: rufusp.exe -g -i "<образ>" - образ выбран, флешку и запись
//    выбирает пользователь в окне Rufus. Rufus требует прав
//    администратора (манифест), поэтому Unit1 запускает его через
//    ShellExecute: Windows покажет запрос UAC.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, SzSetup;

type
  // Сборка Rufus
  TRufusPackage = record
    Version: string;
    Arch: string;            // 'x64' / 'x86' / 'ARM64'
    Origin: string;          // кто собрал
    Need64: Boolean;         // только 64-битная Windows x64
    NeedArm64: Boolean;      // только Windows ARM64
    MinMajor, MinMinor: Integer;
    MaxMajor, MaxMinor: Integer;   // 0, 0 - без верхней границы
    NeedDllDirs: Boolean;    // нужен SetDefaultDllDirectories (KB2533623)
    FileName: string;        // имя файла выпуска
    Size: Integer;
    Sha256: string;
    Url1, Url2: string;
    ZipSubDir: string;       // '' - exe; иначе zip, папка с rufusp.exe
  end;

const
  RufusExeName = 'rufusp.exe';
  RufusInfoFile = 'unide_rufus.txt';
  RufusSite = 'https://rufus.ie';

// <папка exe>\tools\rufus\ и %LOCALAPPDATA%\unIDE\tools\rufus\
function RufusAppDir: WideString;
function RufusUserDir: WideString;
// rufusp.exe своего Rufus: сначала у exe, потом в профиле; нет - ''
function RufusLocalExe: WideString;
// Куда ставить: где уже есть, иначе у exe, если туда пишется, иначе в
// профиль; '' - никуда
function RufusChooseTargetDir: WideString;
// В kernel32 есть SetDefaultDllDirectories (Windows 8+, в Windows 7 - с
// обновлением KB2533623)
function RufusHasDllDirs: Boolean;
// Сборка для этой Windows. False - нет (AReason - почему); True и
// AReason <> '' - выбор с оговоркой (например, Windows 7 без KB2533623)
function RufusChoosePackage(const AOs: TSzOsInfo;
  var APackage: TRufusPackage; var AReason: string): Boolean;
// Нужен свой 7-Zip (сборка - zip)
function RufusNeeds7Zip(const APackage: TRufusPackage): Boolean;
// План установки; ASevenZip - свой 7z.exe (для zip)
function RufusPlan(const APackage: TRufusPackage; const AOsName: string;
  const ASevenZip: WideString): TSzPlan;
// Параметры запуска с образом AImage ('' - без образа)
function RufusRunParams(const AImage: WideString): WideString;
// Версия установленного (из unide_rufus.txt, первая строка); '' - нет
function RufusInstalledInfo(const AExe: WideString): string;

implementation

const
  RufusPackageCount = 6;
  RufusPackages: array[0..RufusPackageCount - 1] of TRufusPackage = (
    (Version: '4.15'; Arch: 'ARM64'; Origin: 'официальный, pbatard';
     Need64: False; NeedArm64: True; MinMajor: 6; MinMinor: 2;
     MaxMajor: 0; MaxMinor: 0; NeedDllDirs: False;
     FileName: 'rufus-4.15_arm64.exe'; Size: 5491048;
     Sha256: 'af01a2136db7391eb8a52de7001fd231f0731cd27e042318dc2743d87fa35c1c';
     Url1: 'https://github.com/pbatard/rufus/releases/download/v4.15/' +
           'rufus-4.15_arm64.exe';
     Url2: ''; ZipSubDir: ''),
    (Version: '4.15'; Arch: 'x64'; Origin: 'официальный, pbatard';
     Need64: True; NeedArm64: False; MinMajor: 6; MinMinor: 2;
     MaxMajor: 0; MaxMinor: 0; NeedDllDirs: False;
     FileName: 'rufus-4.15.exe'; Size: 1989992;
     Sha256: '84c8a437f8af89257524478489e5c85f1edf25f761d299e2bcde46ac0afbe106';
     Url1: 'https://github.com/pbatard/rufus/releases/download/v4.15/' +
           'rufus-4.15.exe';
     Url2: ''; ZipSubDir: ''),
    (Version: '4.15'; Arch: 'x86'; Origin: 'официальный, pbatard';
     Need64: False; NeedArm64: False; MinMajor: 6; MinMinor: 2;
     MaxMajor: 0; MaxMinor: 0; NeedDllDirs: False;
     FileName: 'rufus-4.15_x86.exe'; Size: 1933672;
     Sha256: '20e1345715aff4aebf016839f721390882201a2b5d00655424c4ca38cb919576';
     Url1: 'https://github.com/pbatard/rufus/releases/download/v4.15/' +
           'rufus-4.15_x86.exe';
     Url2: ''; ZipSubDir: ''),
    (Version: '4.6.2208'; Arch: 'x64'; Origin: 'форк Alex313031/rufus-win7';
     Need64: True; NeedArm64: False; MinMajor: 6; MinMinor: 1;
     MaxMajor: 6; MaxMinor: 1; NeedDllDirs: True;
     FileName: 'Rufus_4.6.2208_x64.zip'; Size: 2722702;
     Sha256: '23a12bd8847163963174b490ed6590adf47faf2f48365a63b3322735088b49a2';
     Url1: 'https://github.com/Alex313031/rufus-win7/releases/download/' +
           'v4.6.2208/Rufus_4.6.2208_x64.zip';
     Url2: ''; ZipSubDir: 'Rufus_4.6.2208_x64'),
    (Version: '4.6.2208'; Arch: 'x86'; Origin: 'форк Alex313031/rufus-win7';
     Need64: False; NeedArm64: False; MinMajor: 6; MinMinor: 1;
     MaxMajor: 6; MaxMinor: 1; NeedDllDirs: True;
     FileName: 'Rufus_4.6.2208_x32.zip'; Size: 2677952;
     Sha256: '743dbe6e3b2083bd7a15d708194f0b53dd90d02e667e2c7f1f351fc9cb68c81d';
     Url1: 'https://github.com/Alex313031/rufus-win7/releases/download/' +
           'v4.6.2208/Rufus_4.6.2208_x32.zip';
     Url2: ''; ZipSubDir: 'Rufus_4.6.2208_x32'),
    (Version: '3.22'; Arch: 'x86'; Origin: 'официальный, pbatard';
     Need64: False; NeedArm64: False; MinMajor: 6; MinMinor: 1;
     MaxMajor: 6; MaxMinor: 1; NeedDllDirs: False;
     FileName: 'rufus-3.22.exe'; Size: 1419336;
     Sha256: 'ac2a1743bbfc19268c36280b50a003366d41854863d4808099cd87f77fa5f433';
     Url1: 'https://github.com/pbatard/rufus/releases/download/v3.22/' +
           'rufus-3.22.exe';
     Url2: ''; ZipSubDir: ''));

function RufusAppDir: WideString;
begin
  Result := SzToolsAppDir + 'rufus\';
end;

function RufusUserDir: WideString;
begin
  Result := SzToolsUserDir;
  if Result <> '' then
    Result := Result + 'rufus\';
end;

function RufusLocalExe: WideString;
begin
  Result := RufusAppDir + RufusExeName;
  if SzFileExists(Result) then
    Exit;
  Result := RufusUserDir;
  if Result <> '' then
  begin
    Result := Result + RufusExeName;
    if SzFileExists(Result) then
      Exit;
  end;
  Result := '';
end;

function RufusCanPlace(const ADir: WideString): Boolean;
begin
  Result := (ADir <> '') and SzCanWrite(ADir);
end;

function RufusChooseTargetDir: WideString;
begin
  Result := RufusLocalExe;
  if Result <> '' then
  begin
    Result := ExtractFilePath(string(Result));
    if RufusCanPlace(Result) then
      Exit;
  end;
  Result := RufusAppDir;
  if RufusCanPlace(Result) then
    Exit;
  Result := RufusUserDir;
  if RufusCanPlace(Result) then
    Exit;
  Result := '';
end;

function RufusHasDllDirs: Boolean;
var
  Kernel: HMODULE;
begin
  Kernel := GetModuleHandle('kernel32.dll');
  Result := (Kernel <> 0) and
    (GetProcAddress(Kernel, 'SetDefaultDllDirectories') <> nil);
end;

// Версия AMajor.AMinor не ниже AMinMajor.AMinMinor
function RufusVerAtLeast(AMajor, AMinor, AMinMajor, AMinMinor: Integer): Boolean;
begin
  Result := (AMajor > AMinMajor) or
    ((AMajor = AMinMajor) and (AMinor >= AMinMinor));
end;

function RufusChoosePackage(const AOs: TSzOsInfo;
  var APackage: TRufusPackage; var AReason: string): Boolean;
var
  PackageIndex: Integer;
  HasDllDirs, SkippedDllDirs: Boolean;
  Item: TRufusPackage;
begin
  Result := False;
  AReason := '';
  if not AOs.IsNT or not RufusVerAtLeast(AOs.Major, AOs.Minor, 6, 1) then
  begin
    AReason := 'Rufus 3.22 и новее работает в Windows 7 и новее, здесь ' +
      AOs.Name;
    Exit;
  end;
  HasDllDirs := RufusHasDllDirs;
  SkippedDllDirs := False;
  for PackageIndex := 0 to RufusPackageCount - 1 do
  begin
    Item := RufusPackages[PackageIndex];
    if Item.Need64 and not AOs.Is64 then
      Continue;
    if Item.NeedArm64 <> AOs.IsArm64 then
      Continue;
    if not RufusVerAtLeast(AOs.Major, AOs.Minor, Item.MinMajor, Item.MinMinor) then
      Continue;
    if ((Item.MaxMajor <> 0) or (Item.MaxMinor <> 0)) and
       RufusVerAtLeast(AOs.Major, AOs.Minor, Item.MaxMajor, Item.MaxMinor + 1) then
      Continue;
    if Item.NeedDllDirs and not HasDllDirs then
    begin
      SkippedDllDirs := True;
      Continue;
    end;
    APackage := Item;
    Result := True;
    if SkippedDllDirs then
      AReason := 'в Windows нет обновления KB2533623 (функция ' +
        'SetDefaultDllDirectories) - Rufus 4.6.2208 для Windows 7 без него ' +
        'не запустится, поэтому выбран официальный Rufus 3.22';
    Exit;
  end;
  AReason := 'подходящей сборки Rufus для ' + AOs.Name + ' нет';
end;

function RufusNeeds7Zip(const APackage: TRufusPackage): Boolean;
begin
  Result := APackage.ZipSubDir <> '';
end;

function RufusPlan(const APackage: TRufusPackage; const AOsName: string;
  const ASevenZip: WideString): TSzPlan;
var
  Signed: string;
begin
  Result.Title := 'Rufus ' + APackage.Version + ' (' + APackage.Arch + ')';
  SetLength(Result.Files, 1);
  Result.Files[0].Url1 := APackage.Url1;
  Result.Files[0].Url2 := APackage.Url2;
  Result.Files[0].Size := APackage.Size;
  Result.Files[0].Sha256 := APackage.Sha256;
  if APackage.ZipSubDir = '' then
  begin
    // Официальный exe: как есть, под именем rufusp.exe
    Result.Files[0].FileName := RufusExeName;
    Result.Extractor := '';
    Result.Archive := -1;
    Result.ExtractNames := '';
    Result.ExtractSubDir := '';
    Signed := 'подписан Akeo Consulting';
  end
  else
  begin
    Result.Files[0].FileName := APackage.FileName;
    Result.Extractor := ASevenZip;
    Result.Archive := 0;
    Result.ExtractNames := APackage.ZipSubDir + '\' + RufusExeName;
    Result.ExtractSubDir := APackage.ZipSubDir;
    Signed := 'без цифровой подписи, распакован своим 7-Zip unIDE';
  end;
  Result.MoveNames := RufusExeName;
  Result.CheckFile := RufusExeName;
  Result.InfoFile := RufusInfoFile;
  Result.InfoText := 'Rufus ' + APackage.Version + ' (' + APackage.Arch + ', ' +
    APackage.Origin + ')' + #13#10 + 'Установлен unIDE ' +
    FormatDateTime('yyyy-mm-dd hh:nn', Now) + ' для ' + AOsName + #13#10 +
    APackage.Url1 + #13#10 + 'SHA-256 ' + APackage.FileName + ': ' +
    APackage.Sha256 + #13#10 + 'Файл ' + Signed + '. Имя ' + RufusExeName +
    ' - переносимый режим: настройки Rufus в rufus.ini рядом, не в ' +
    'реестре.' + #13#10;
end;

function RufusRunParams(const AImage: WideString): WideString;
begin
  Result := '-g';
  if AImage <> '' then
    Result := Result + WideString(' -i "') + AImage + WideString('"');
end;

function RufusInstalledInfo(const AExe: WideString): string;
var
  InfoHandle: THandle;
  Buffer: array[0..511] of Char;
  ReadCount: DWORD;
  InfoName: string;
  LineEnd: Integer;
begin
  Result := '';
  if AExe = '' then
    Exit;
  InfoName := ExtractFilePath(string(AExe)) + RufusInfoFile;
  InfoHandle := CreateFile(PChar(InfoName), GENERIC_READ, FILE_SHARE_READ,
    nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if InfoHandle = INVALID_HANDLE_VALUE then
    Exit;
  try
    ReadCount := 0;
    if not ReadFile(InfoHandle, Buffer, SizeOf(Buffer) - 1, ReadCount, nil) then
      Exit;
    Buffer[ReadCount] := #0;
    Result := Buffer;
    LineEnd := Pos(#13, Result);
    if LineEnd > 0 then
      Result := Copy(Result, 1, LineEnd - 1);
  finally
    CloseHandle(InfoHandle);
  end;
end;

end.
