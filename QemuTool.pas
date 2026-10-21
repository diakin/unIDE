unit QemuTool;

// ---------------------------------------------------------------------------
//  Свой QEMU unIDE: запуск собранного образа ReactOS (bootcd.iso, livecd.iso
//  ...) в эмуляторе. Как свой 7-Zip (SzSetup): tools\qemu у exe или
//  %LOCALAPPDATA%\unIDE\tools\qemu; в системе ничего не ставится.
//
//  - версия - QEMU 7.0.0, сборки Stefan Weil (qemu.weilnetz.de, на них
//    ведёт qemu.org для Windows). Почему 7.0.0: в сборках 7.1, 7.2, 8.0,
//    8.2, 9.0, 9.2 qemu-system-i386.exe импортирует PathCchSkipRoot из
//    api-ms-win-core-path-l1-1-0.dll - в Windows 7 такой нет, программа не
//    запустится. У 7.0.0 (2022-04-19, w64 и w32) импорта новее Windows 7
//    не нашлось (проверено 22.10.2026 по таблицам импорта exe и всех DLL;
//    SHA-512 установщиков совпали с опубликованными рядом);
//  - сборка: w64 на 64-битной Windows x64, w32 - на 32-битной и ARM64;
//    Windows 7 и новее;
//  - установка: качается установщик (NSIS), свой 7-Zip достаёт из него
//    только qemu-system-i386(w).exe, qemu-img.exe, DLL и прошивки x86
//    (около 120 МБ из 1,3 ГБ); установщик не запускается;
//  - ускорителей (HAXM, WHPX) нет: они ставят драйвер ядра. Процессор
//    эмулируется программно (TCG) - медленнее, зато QEMU - обычная
//    программа, которая системы не касается.
//
//  Запуск (QemuRunArgs): ISO - CD-ROM на втором IDE-канале и загрузка с
//  него, диск qcow2 (создаётся qemu-img при первом запуске) - для
//  установки ReactOS с bootcd; COM1 - в файл (отладочный вывод ReactOS
//  KDSERIAL); сеть - user (NAT), карта ne2k_pci (драйвер есть в ReactOS).
//  Проверено на QEMU 8.2 под Linux с ReactOS 0.4.15 bootcd: доходит до
//  окна установки, вывод COM1 пишется.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes, SzSetup;

const
  QemuVersion = '7.0.0';
  QemuExeName = 'qemu-system-i386w.exe';   // без окна консоли
  QemuImgName = 'qemu-img.exe';
  QemuInfoFile = 'unide_qemu.txt';
  QemuSite = 'https://qemu.weilnetz.de/';

// <папка exe>\tools\qemu\ и %LOCALAPPDATA%\unIDE\tools\qemu\
function QemuAppDir: WideString;
function QemuUserDir: WideString;
// qemu-system-i386w.exe своего QEMU (есть и прошивка BIOS); нет - ''
function QemuLocalExe: WideString;
// Куда ставить: где уже есть, иначе у exe, если туда пишется, иначе в
// профиль; '' - никуда
function QemuChooseTargetDir: WideString;
// Сборка для этой Windows; False - QEMU 7.0.0 для неё нет (до Windows 7)
function QemuChoosePackage(const AOs: TSzOsInfo;
  var APackage: TSzPackage): Boolean;
// План установки (распаковывает свой 7-Zip ASevenZip)
function QemuPlan(const APackage: TSzPackage; const AOsName: string;
  const ASevenZip: WideString): TSzPlan;
// Память гостя по умолчанию: 1024 МБ на 64-битной Windows, 512 - на
// 32-битной (у 32-битного QEMU мало адресного пространства)
function QemuDefaultMemory: Integer;
// Параметры qemu-system-i386 для образа AImage (.iso - CD-ROM и загрузка с
// него, ADisk - жёсткий диск qcow2, '' - без диска; .img / .vhd - сам
// образ как жёсткий диск). ASerialLog - файл для COM1
function QemuRunArgs(const AImage, ADisk, ASerialLog, AName: WideString;
  AMemoryMb: Integer): WideString;
// Параметры qemu-img: создать диск qcow2 ASizeGb ГБ (растёт по мере записи)
function QemuImgCreateArgs(const ADisk: WideString; ASizeGb: Integer): WideString;

implementation

const
  QemuPackageCount = 2;
  QemuPackages: array[0..QemuPackageCount - 1] of TSzPackage = (
    (Version: '7.0.0'; Arch: 'x64'; Need64: True; MinMajor: 6; MinMinor: 1;
     FileName: 'qemu-w64-setup-20220419.exe'; Size: 132732320;
     Sha256: '410c674d87a28760cc90a3c1bf0b7cb8bf5d2e4253a8f9e07b218d2bc7300af3';
     Url1: 'https://qemu.weilnetz.de/w64/2022/qemu-w64-setup-20220419.exe';
     Url2: ''),
    (Version: '7.0.0'; Arch: 'x86'; Need64: False; MinMajor: 6; MinMinor: 1;
     FileName: 'qemu-w32-setup-20220419.exe'; Size: 139283976;
     Sha256: '69dd281848108162496a60f19608ece2ac7940e0a3f8516d7ff417996c3645c3';
     Url1: 'https://qemu.weilnetz.de/w32/2022/qemu-w32-setup-20220419.exe';
     Url2: ''));

  // Что достать из установщика: эмулятор x86, qemu-img, все DLL, прошивки
  // x86 (BIOS, VGA, сетевые ROM), раскладки клавиатуры, значки GTK
  QemuExtractNames =
    'qemu-system-i386.exe'#13#10 +
    'qemu-system-i386w.exe'#13#10 +
    'qemu-img.exe'#13#10 +
    '*.dll'#13#10 +
    'COPYING'#13#10 +
    'COPYING.LIB'#13#10 +
    'README.rst'#13#10 +
    'VERSION'#13#10 +
    'lib'#13#10 +
    'share\bios*.bin'#13#10 +
    'share\vgabios*.bin'#13#10 +
    'share\kvmvapic.bin'#13#10 +
    'share\linuxboot*.bin'#13#10 +
    'share\multiboot*.bin'#13#10 +
    'share\pvh.bin'#13#10 +
    'share\qboot.rom'#13#10 +
    'share\sgabios.bin'#13#10 +
    'share\efi-*.rom'#13#10 +
    'share\pxe-*.rom'#13#10 +
    'share\keymaps'#13#10 +
    'share\icons'#13#10 +
    'share\firmware';

function QemuAppDir: WideString;
begin
  Result := SzToolsAppDir + 'qemu\';
end;

function QemuUserDir: WideString;
begin
  Result := SzToolsUserDir;
  if Result <> '' then
    Result := Result + 'qemu\';
end;

function QemuLocalExe: WideString;
var
  Dirs: array[0..1] of WideString;
  DirIndex: Integer;
begin
  Result := '';
  Dirs[0] := QemuAppDir;
  Dirs[1] := QemuUserDir;
  for DirIndex := 0 to 1 do
    if (Dirs[DirIndex] <> '') and SzFileExists(Dirs[DirIndex] + QemuExeName) and
       SzFileExists(Dirs[DirIndex] + 'share\bios-256k.bin') then
    begin
      Result := Dirs[DirIndex] + QemuExeName;
      Exit;
    end;
end;

// Можно ли создать папку ADir: проверяется пробой в папке выше (сама папка
// при установке заменяется целиком)
function QemuCanPlace(const ADir: WideString): Boolean;
begin
  Result := (ADir <> '') and
    SzCanWrite(ExtractFilePath(string(SzNoSlash(ADir))));
end;

function QemuChooseTargetDir: WideString;
var
  Existing: WideString;
begin
  Existing := QemuLocalExe;
  if Existing <> '' then
  begin
    Result := ExtractFilePath(string(Existing));
    if QemuCanPlace(Result) then
      Exit;
  end;
  Result := QemuAppDir;
  if QemuCanPlace(Result) then
    Exit;
  Result := QemuUserDir;
  if QemuCanPlace(Result) then
    Exit;
  Result := '';
end;

function QemuChoosePackage(const AOs: TSzOsInfo;
  var APackage: TSzPackage): Boolean;
var
  PackageIndex: Integer;
begin
  Result := False;
  if not AOs.IsNT then
    Exit;
  for PackageIndex := 0 to QemuPackageCount - 1 do
    with QemuPackages[PackageIndex] do
      if (not Need64 or AOs.Is64) and
         ((AOs.Major > MinMajor) or
          ((AOs.Major = MinMajor) and (AOs.Minor >= MinMinor))) then
      begin
        APackage := QemuPackages[PackageIndex];
        Result := True;
        Exit;
      end;
end;

function QemuPlan(const APackage: TSzPackage; const AOsName: string;
  const ASevenZip: WideString): TSzPlan;
begin
  Result.Title := 'QEMU ' + APackage.Version + ' (' + APackage.Arch + ')';
  SetLength(Result.Files, 1);
  Result.Files[0].Url1 := APackage.Url1;
  Result.Files[0].Url2 := APackage.Url2;
  Result.Files[0].FileName := APackage.FileName;
  Result.Files[0].Size := APackage.Size;
  Result.Files[0].Sha256 := APackage.Sha256;
  Result.Extractor := ASevenZip;
  Result.Archive := 0;
  Result.ExtractNames := QemuExtractNames;
  Result.MoveNames := '';           // папка tools\qemu - целиком
  Result.CheckFile := QemuExeName;
  Result.InfoFile := QemuInfoFile;
  Result.InfoText := 'QEMU ' + APackage.Version + ' (' + APackage.Arch +
    '), установлен unIDE ' + FormatDateTime('yyyy-mm-dd hh:nn', Now) +
    ' для ' + AOsName + #13#10 + APackage.Url1 + #13#10 + 'SHA-256 ' +
    APackage.FileName + ': ' + APackage.Sha256 + #13#10 +
    'Из установщика взяты qemu-system-i386(w).exe, qemu-img.exe, DLL и ' +
    'прошивки x86; лицензия - COPYING, COPYING.LIB.' + #13#10 +
    'Свой QEMU unIDE: в системе ничего не ставится, драйверов нет.' + #13#10;
end;

function QemuDefaultMemory: Integer;
var
  OsInfo: TSzOsInfo;
  Package: TSzPackage;
begin
  SzGetOsInfo(OsInfo);
  Result := 512;
  if QemuChoosePackage(OsInfo, Package) and (Package.Arch = 'x64') then
    Result := 1024;
end;

// Значение параметра QEMU: запятая в пути удваивается (иначе - разделитель
// подпараметров), весь параметр - в кавычках (пробелы)
function QemuQuoted(const AValue: WideString): WideString;
var
  CharIndex: Integer;
begin
  Result := '';
  for CharIndex := 1 to Length(AValue) do
    if AValue[CharIndex] = ',' then
      Result := Result + ',,'
    else
      Result := Result + AValue[CharIndex];
end;

function QemuRunArgs(const AImage, ADisk, ASerialLog, AName: WideString;
  AMemoryMb: Integer): WideString;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(string(AImage)));
  Result := WideString('-name "') + AName + WideString('" -m ') +
    WideString(IntToStr(AMemoryMb)) +
    ' -rtc base=localtime -vga std' +
    ' -netdev user,id=net0 -device ne2k_pci,netdev=net0';
  if Ext = '.iso' then
  begin
    if ADisk <> '' then
      Result := Result + WideString(' -drive "file=') + QemuQuoted(ADisk) +
        WideString(',if=ide,index=0,media=disk,format=qcow2"');
    Result := Result + WideString(' -drive "file=') + QemuQuoted(AImage) +
      WideString(',if=ide,index=2,media=cdrom" -boot d');
  end
  else if Ext = '.vhd' then
    Result := Result + WideString(' -drive "file=') + QemuQuoted(AImage) +
      WideString(',if=ide,index=0,media=disk,format=vpc" -boot c')
  else
    Result := Result + WideString(' -drive "file=') + QemuQuoted(AImage) +
      WideString(',if=ide,index=0,media=disk,format=raw" -boot c');
  if ASerialLog <> '' then
    Result := Result + WideString(' -serial "file:') + ASerialLog +
      WideString('"');
end;

function QemuImgCreateArgs(const ADisk: WideString; ASizeGb: Integer): WideString;
begin
  Result := WideString('create -f qcow2 "') + ADisk + WideString('" ') +
    WideString(IntToStr(ASizeGb)) + 'G';
end;

end.
