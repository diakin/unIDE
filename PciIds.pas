unit PciIds;

// ---------------------------------------------------------------------------
//  База pci.ids (https://pci-ids.ucw.cz/) и INF системных устройств для
//  дерева ReactOS / LiberNT. Меню ReactOS: "Update pci.ids" и "Generate
//  System Devices INF" (Unit1). Без VCL.
//
//  В machine.inf для чипсетов есть только записи по классу (PCI\CC_0600,
//  0601, 0604) и несколько устройств Intel 440FX/440BX/PIIX, поэтому мосты
//  и служебные устройства чипсетов называются "Standard ... bridge" или
//  остаются без драйвера. Генератор берёт из pci.ids коды и имена таких
//  устройств и пишет media\inf\pciids.inf:
//    PCI_ISA_Inst - мосты PCI-ISA и LPC (все производители);
//    PCI_Inst     - мосты PCI-PCI и порты PCI Express (все производители);
//    NO_DRV       - служебные устройства чипсета без драйвера (контроллер
//                   памяти, SMBus, управление питанием ...) - только
//                   производители из списка проекта.
//  Класса устройства в pci.ids нет, раздел выбирается по словам в имени
//  (PciClassify). USB, SATA, IDE, звук, видео, сеть и т. п. в файл не
//  попадают никогда: запись по коду оборудования ранжируется выше записи
//  по коду класса, и NO_DRV отобрал бы у устройства настоящий драйвер.
//  Коды, которые уже есть в других INF (media\inf, drivers), пропускаются.
//  Имена, не подошедшие ни под одно правило, - в отчёт на ручную проверку.
//
//  Файлы (от папки исходников):
//    sdk\tools\pciids\pci.ids           база, "Update pci.ids"
//    sdk\tools\pciids\translations.ini  ручные переводы: раздел на язык
//                                       ([0419]), строки
//                                       PCI\VEN_8086&DEV_27B9=Имя
//    sdk\tools\pciids\pciids-report.txt отчёт последней генерации
//    media\inf\pciids.inf               результат, перезаписывается
//                                       целиком
//  Кодировка INF - UTF-8 без BOM, как machine.inf (её переводит в UTF-16
//  add_driver_inf); переводы в translations.ini - UTF-8 или ANSI.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes;

const
  PciIdsUrl = 'https://pci-ids.ucw.cz/v2.2/pci.ids';
  PciIdsRelFile = 'sdk\tools\pciids\pci.ids';
  PciTranslRelFile = 'sdk\tools\pciids\translations.ini';
  PciReportRelFile = 'sdk\tools\pciids\pciids-report.txt';
  PciInfRelFile = 'media\inf\pciids.inf';
  PciInfName = 'pciids.inf';
  PciMachineRelFile = 'media\inf\machine.inf';
  PciCMakeRelFile = 'media\inf\CMakeLists.txt';
  // Производители чипсетов для NO_DRV по умолчанию (ключ проекта
  // ReactOS_PciVendors)
  PciDefaultVendors = '8086 1022 1002 1106 1039 10DE 10B9 1045 1060 1004 ' +
                      '1078 100B 1166 1279 17F3 1D17 1D94';

type
  TPciInstKind = (pkNone, pkExclude, pkPciIsa, pkPci, pkNoDrv);

  TPciDevice = record
    Vendor: string;     // 4 hex-цифры, заглавные
    Device: string;
    Name: string;       // UTF-8, как в pci.ids
  end;
  TPciDeviceArray = array of TPciDevice;

  TPciDb = class
  private
    FVendors: TStringList;      // "8086=Intel Corporation"
    FIndex: TStringList;        // сортированный "8086:27B9", Objects - номер
  public
    Version: string;
    Date: string;
    Devices: TPciDeviceArray;
    Count: Integer;
    constructor Create;
    destructor Destroy; override;
    // Прочитать pci.ids. Не файл pci.ids или нет устройств - False.
    function LoadFromFile(const AFile: string): Boolean;
    function VendorName(const AVendor: string): string;
    // Номер устройства в Devices или -1
    function IndexOf(const AVendor, ADevice: string): Integer;
  end;

  TPciCompare = record
    Added: Integer;
    Changed: Integer;
    Removed: Integer;
  end;

  TPciGenStats = record
    PciIsa: Integer;
    Pci: Integer;
    NoDrv: Integer;
    Known: Integer;         // уже есть в других INF
    Review: Integer;        // не подошли ни под одно правило
    Excluded: Integer;      // USB, SATA, звук ... - не включаются
    OtherVendor: Integer;   // NO_DRV производителей не из списка
    Translated: Integer;    // строк в разделах [Strings.<язык>]
    FirstTime: Boolean;     // pciids.inf раньше не было
  end;

// Путь от папки исходников: на Windows - как есть
function PciPath(const ASourceDir, ARelFile: string): string;
// Строки "Version:" и "Date:" из заголовка pci.ids (первые 4 КБ)
function PciReadHeader(const AFile: string; var AVersion,
                       ADate: string): Boolean;
// Список производителей "8086, 1022 ..." - в сортированный список кодов
// из 4 заглавных hex-цифр; неверные элементы - в AInvalid
procedure PciParseVendors(const AText: string; AList: TStringList;
                          var AInvalid: string);
// Раздел установки по имени устройства (без учёта списка производителей)
function PciClassify(const AName: string): TPciInstKind;
// Разница баз для производителей AVendors (пусто - все): новые, с другим
// именем, удалённые устройства
procedure PciCompareDb(AOld, ANew: TPciDb; AVendors: TStringList;
                       var ACompare: TPciCompare);
// Коды VEN_xxxx&DEV_yyyy из INF дерева исходников (media\inf и drivers,
// без pciids.inf) - в сортированный список "8086:27B9"
procedure PciCollectInfIds(const ASourceDir: string; AIds: TStringList);
// Сгенерировать media\inf\pciids.inf. Отчёт (ANSI) - в AReport. Нет
// pci.ids или machine.inf, не записалось - False, причина в AError.
function PciGenerateInf(const ASourceDir, AVendors: string;
                        AReport: TStrings; var AStats: TPciGenStats;
                        var AError: string): Boolean;
// pciids.inf уже в списке INF_FILES в media\inf\CMakeLists.txt
function PciCMakeHasInf(const ASourceDir: string): Boolean;
// Вписать pciids.inf в INF_FILES после machine.inf. Не нашлось места -
// False.
function PciCMakeAddInf(const ASourceDir: string): Boolean;

implementation

{$IFNDEF FPC}
type
  PtrInt = Integer;
{$ENDIF}

const
  // Порядок проверки: сначала исключения, затем мосты PCI-ISA, затем
  // главные мосты (их имена бывают "CPU to PCI Bridge" - не PCI_Inst),
  // затем мосты PCI-PCI, затем остальное служебное. Сравнение без учёта
  // регистра, слово целиком (по краям - не буква и не цифра).
  ExcludeWords: array[0..46] of string = (
    'USB', 'xHCI', 'EHCI', 'OHCI', 'UHCI', 'SATA', 'IDE', 'PATA', 'AHCI',
    'RAID', 'NVMe', 'SCSI', 'SAS', 'Storage', 'Audio', 'Azalia', 'AC''97',
    'AC97', 'Sound', 'Graphics', 'VGA', 'Display', 'GPU', 'Video',
    'Ethernet', 'Network', 'LAN', 'Gigabit', 'Wireless', 'WLAN', 'Wi-Fi',
    'WiFi', 'Bluetooth', 'Modem', 'CardBus', 'PCMCIA', 'FireWire', '1394',
    'SD Host', 'MMC', 'Card Reader', 'Serial Port', 'UART',
    'Parallel Port', 'Floppy',
    // Мост в непрозрачном режиме - класс 0680, не мост PCI-PCI
    'non-transparent', 'NTB');
  // Имена видеоадаптеров без других слов ("RV380 [Radeon X600]"): не на
  // проверку. Не исключения - "MCP78S [GeForce 8200] LPC Bridge" - мост.
  VideoNameWords: array[0..7] of string = (
    'Radeon', 'GeForce', 'Quadro', 'FireGL', 'FirePro', 'FireMV', 'Rage',
    'Mach64');
  PciIsaWords: array[0..5] of string = (
    'LPC Interface Bridge', 'LPC Bridge', 'PCI to ISA', 'PCI-to-ISA',
    'PCI-ISA', 'ISA Bridge');
  HostBridgeWords: array[0..5] of string = (
    'Host Bridge', 'Host-PCI', 'Host/PCI', 'Host to PCI', 'CPU to PCI',
    'CPU-to-PCI');
  PciBridgeWords: array[0..12] of string = (
    'PCI Express Port', 'PCI Express Root Port', 'PCIe Root Port',
    'Root Port', 'PCI Bridge', 'PCI-to-PCI', 'PCI to PCI', 'P2P Bridge',
    'PCI Express Bridge', 'Upstream Port', 'Downstream Port',
    'AGP Bridge', 'PCI to AGP');
  NoDrvWords: array[0..21] of string = (
    'Memory Controller Hub', 'Memory Controller', 'DRAM Controller',
    'DRAM', 'SMBus', 'Power Management', 'LPC', 'Thermal', 'Watchdog',
    'HyperTransport', 'Address Map', 'Miscellaneous', 'Link Control',
    'I/O APIC', 'IOAPIC', 'HPET', 'Northbridge', 'Southbridge',
    'Hub Interface', 'System Management', 'Performance Monitor',
    'Host Controller Interface Bridge');
  // Разделы установки из machine.inf, которые копируются в pciids.inf
  CopySectionPrefixes: array[0..5] of string = (
    'NO_DRV', 'PCI_ISA_', 'PCI_Inst', 'PCI_CopyFiles', 'isapnp_Service',
    'pci_Service');
  InstSection: array[TPciInstKind] of string = (
    '', '', 'PCI_ISA_Inst', 'PCI_Inst', 'NO_DRV');
  // Длина строки описания устройства в INF (LINE_LEN = 256)
  MaxDescLen = 250;

function PciPath(const ASourceDir, ARelFile: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ASourceDir) + ARelFile;
  {$IFNDEF MSWINDOWS}
  Result := StringReplace(Result, '\', PathDelim, [rfReplaceAll]);
  {$ENDIF}
end;

function IsHexText(const AText: string): Boolean;
var
  Idx: Integer;
begin
  Result := AText <> '';
  for Idx := 1 to Length(AText) do
    if not (AText[Idx] in ['0'..'9', 'A'..'F', 'a'..'f']) then
    begin
      Result := False;
      Exit;
    end;
end;

function IsWordChar(AChar: Char): Boolean;
begin
  Result := AChar in ['0'..'9', 'A'..'Z', 'a'..'z'];
end;

// AWord есть в AUpper (имя заглавными) отдельным словом
function HasWord(const AUpper, AWord: string): Boolean;
var
  Needle, Rest: string;
  FoundPos, Offset, EndPos: Integer;
begin
  Result := False;
  Needle := UpperCase(AWord);
  Rest := AUpper;
  Offset := 0;
  repeat
    FoundPos := Pos(Needle, Rest);
    if FoundPos = 0 then
      Exit;
    EndPos := FoundPos + Length(Needle);
    if ((FoundPos = 1) or not IsWordChar(Rest[FoundPos - 1])) and
       ((EndPos > Length(Rest)) or not IsWordChar(Rest[EndPos])) then
    begin
      Result := True;
      Exit;
    end;
    Inc(Offset, FoundPos);
    Rest := Copy(AUpper, Offset + 1, MaxInt);
  until Rest = '';
end;

function HasAnyWord(const AUpper: string;
                    const AWords: array of string): Boolean;
var
  Idx: Integer;
begin
  Result := True;
  for Idx := Low(AWords) to High(AWords) do
    if HasWord(AUpper, AWords[Idx]) then
      Exit;
  Result := False;
end;

function PciClassify(const AName: string): TPciInstKind;
var
  Upper: string;
begin
  Upper := UpperCase(AName);
  if HasAnyWord(Upper, ExcludeWords) then
    Result := pkExclude
  else if HasAnyWord(Upper, PciIsaWords) then
    Result := pkPciIsa
  else if HasAnyWord(Upper, HostBridgeWords) then
    Result := pkNoDrv
  else if HasAnyWord(Upper, PciBridgeWords) then
    Result := pkPci
  else if HasAnyWord(Upper, NoDrvWords) then
    Result := pkNoDrv
  else
    Result := pkNone;
end;

{ TPciDb }

constructor TPciDb.Create;
begin
  inherited Create;
  FVendors := TStringList.Create;
  FIndex := TStringList.Create;
  FIndex.Sorted := True;
  FIndex.Duplicates := dupIgnore;
end;

destructor TPciDb.Destroy;
begin
  FVendors.Free;
  FIndex.Free;
  inherited Destroy;
end;

function TPciDb.LoadFromFile(const AFile: string): Boolean;
var
  Lines: TStringList;
  LineIdx: Integer;
  Line, Vendor, DeviceId, Field: string;
begin
  Result := False;
  Version := '';
  Date := '';
  Count := 0;
  SetLength(Devices, 0);
  FVendors.Clear;
  FIndex.Clear;
  if not FileExists(AFile) then
    Exit;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFile);
    SetLength(Devices, Lines.Count);
    Vendor := '';
    FIndex.Sorted := False;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Lines[LineIdx];
      if Line = '' then
        Continue;
      if Line[1] = '#' then
      begin
        Field := Trim(Copy(Line, 2, MaxInt));
        if (Version = '') and (Copy(Field, 1, 8) = 'Version:') then
          Version := Trim(Copy(Field, 9, MaxInt))
        else if (Date = '') and (Copy(Field, 1, 5) = 'Date:') then
          Date := Trim(Copy(Field, 6, MaxInt));
        Continue;
      end;
      // Список классов "C 00  ..." - после всех производителей
      if (Length(Line) > 2) and (Line[1] = 'C') and (Line[2] = ' ') then
        Break;
      if Line[1] <> #9 then
      begin
        // Производитель: "8086  Intel Corporation"
        Vendor := UpperCase(Copy(Line, 1, 4));
        if (Length(Line) < 7) or not IsHexText(Vendor) then
        begin
          Vendor := '';
          Continue;
        end;
        FVendors.Add(Vendor + '=' + Trim(Copy(Line, 5, MaxInt)));
      end
      else if (Length(Line) > 7) and (Line[2] <> #9) and (Vendor <> '') then
      begin
        // Устройство: "<Tab>27b9  82801GBM (ICH7-M) LPC Interface Bridge";
        // подсистемы (две табуляции) не нужны
        DeviceId := UpperCase(Copy(Line, 2, 4));
        if not IsHexText(DeviceId) then
          Continue;
        Devices[Count].Vendor := Vendor;
        Devices[Count].Device := DeviceId;
        Devices[Count].Name := Trim(Copy(Line, 6, MaxInt));
        FIndex.AddObject(Vendor + ':' + DeviceId, TObject(PtrInt(Count)));
        Inc(Count);
      end;
    end;
    SetLength(Devices, Count);
    FIndex.Sorted := True;
  finally
    Lines.Free;
  end;
  Result := (Count > 0) and (Version <> '');
end;

function TPciDb.VendorName(const AVendor: string): string;
begin
  Result := FVendors.Values[AVendor];
end;

function TPciDb.IndexOf(const AVendor, ADevice: string): Integer;
var
  FoundIdx: Integer;
begin
  Result := -1;
  if FIndex.Find(AVendor + ':' + ADevice, FoundIdx) then
    Result := Integer(PtrInt(FIndex.Objects[FoundIdx]));
end;

function PciReadHeader(const AFile: string; var AVersion,
                       ADate: string): Boolean;
const
  HeadSize = 4096;
var
  Stream: TFileStream;
  Head: string;
  Lines: TStringList;
  LineIdx: Integer;
  Field: string;
begin
  AVersion := '';
  ADate := '';
  Result := False;
  if not FileExists(AFile) then
    Exit;
  Stream := TFileStream.Create(AFile, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Head, HeadSize);
    SetLength(Head, Stream.Read(Head[1], HeadSize));
  finally
    Stream.Free;
  end;
  Lines := TStringList.Create;
  try
    Lines.Text := Head;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      if Copy(Lines[LineIdx], 1, 1) <> '#' then
        Continue;
      Field := Trim(Copy(Lines[LineIdx], 2, MaxInt));
      if (AVersion = '') and (Copy(Field, 1, 8) = 'Version:') then
        AVersion := Trim(Copy(Field, 9, MaxInt))
      else if (ADate = '') and (Copy(Field, 1, 5) = 'Date:') then
        ADate := Trim(Copy(Field, 6, MaxInt));
    end;
  finally
    Lines.Free;
  end;
  Result := AVersion <> '';
end;

procedure PciParseVendors(const AText: string; AList: TStringList;
                          var AInvalid: string);
var
  Item: string;
  CharIdx: Integer;

  procedure Flush;
  begin
    if Item = '' then
      Exit;
    if (Length(Item) = 4) and IsHexText(Item) then
      AList.Add(UpperCase(Item))
    else
    begin
      if AInvalid <> '' then
        AInvalid := AInvalid + ', ';
      AInvalid := AInvalid + Item;
    end;
    Item := '';
  end;

begin
  AList.Clear;
  AList.Sorted := True;
  AList.Duplicates := dupIgnore;
  AInvalid := '';
  Item := '';
  for CharIdx := 1 to Length(AText) do
    if AText[CharIdx] in [' ', ',', ';', #9, #13, #10] then
      Flush
    else
      Item := Item + AText[CharIdx];
  Flush;
end;

procedure PciCompareDb(AOld, ANew: TPciDb; AVendors: TStringList;
                       var ACompare: TPciCompare);
var
  DevIdx, OldIdx, VendorPos: Integer;

  function Wanted(const AVendor: string): Boolean;
  begin
    Result := (AVendors = nil) or (AVendors.Count = 0) or
              AVendors.Find(AVendor, VendorPos);
  end;

begin
  ACompare.Added := 0;
  ACompare.Changed := 0;
  ACompare.Removed := 0;
  for DevIdx := 0 to ANew.Count - 1 do
    if Wanted(ANew.Devices[DevIdx].Vendor) then
    begin
      OldIdx := AOld.IndexOf(ANew.Devices[DevIdx].Vendor,
                             ANew.Devices[DevIdx].Device);
      if OldIdx < 0 then
        Inc(ACompare.Added)
      else if AOld.Devices[OldIdx].Name <> ANew.Devices[DevIdx].Name then
        Inc(ACompare.Changed);
    end;
  for DevIdx := 0 to AOld.Count - 1 do
    if Wanted(AOld.Devices[DevIdx].Vendor) and
       (ANew.IndexOf(AOld.Devices[DevIdx].Vendor,
                     AOld.Devices[DevIdx].Device) < 0) then
      Inc(ACompare.Removed);
end;

// Файл целиком строкой (байты как есть)
function ReadRaw(const AFile: string): string;
var
  Stream: TFileStream;
begin
  Result := '';
  Stream := TFileStream.Create(AFile, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, Integer(Stream.Size));
    if Result <> '' then
      Stream.ReadBuffer(Result[1], Length(Result));
  finally
    Stream.Free;
  end;
end;

function WriteRaw(const AFile, AText: string): Boolean;
var
  Stream: TFileStream;
begin
  Result := False;
  try
    Stream := TFileStream.Create(AFile, fmCreate);
    try
      if AText <> '' then
        Stream.WriteBuffer(AText[1], Length(AText));
    finally
      Stream.Free;
    end;
    Result := True;
  except
    on EStreamError do
      Result := False;
  end;
end;

// Коды VEN_xxxx&DEV_yyyy из текста INF
procedure CollectIdsFromText(const AText: string; AIds: TStringList);
var
  Upper, VendorId, DeviceId: string;
  FoundPos, Offset: Integer;
begin
  Upper := UpperCase(AText);
  Offset := 0;
  repeat
    FoundPos := Pos('VEN_', Copy(Upper, Offset + 1, MaxInt));
    if FoundPos = 0 then
      Break;
    Inc(Offset, FoundPos);
    // Offset - позиция "V"; дальше "VEN_xxxx&DEV_yyyy"
    VendorId := Copy(Upper, Offset + 4, 4);
    DeviceId := Copy(Upper, Offset + 13, 4);
    if IsHexText(VendorId) and (Copy(Upper, Offset + 8, 5) = '&DEV_') and
       IsHexText(DeviceId) and (Length(DeviceId) = 4) then
      AIds.Add(VendorId + ':' + DeviceId);
  until False;
end;

procedure CollectIdsInDir(const ADir: string; ARecursive: Boolean;
                          AIds: TStringList);
var
  SearchRec: TSearchRec;
  Dir: string;
begin
  Dir := IncludeTrailingPathDelimiter(ADir);
  if FindFirst(Dir + '*', faAnyFile, SearchRec) = 0 then
  try
    repeat
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
        Continue;
      if (SearchRec.Attr and faDirectory) <> 0 then
      begin
        if ARecursive then
          CollectIdsInDir(Dir + SearchRec.Name, True, AIds);
      end
      else if (CompareText(ExtractFileExt(SearchRec.Name), '.inf') = 0) and
              (CompareText(SearchRec.Name, PciInfName) <> 0) then
        CollectIdsFromText(ReadRaw(Dir + SearchRec.Name), AIds);
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
end;

procedure PciCollectInfIds(const ASourceDir: string; AIds: TStringList);
begin
  AIds.Clear;
  AIds.Sorted := True;
  AIds.Duplicates := dupIgnore;
  CollectIdsInDir(ExtractFileDir(PciPath(ASourceDir, PciMachineRelFile)),
                  False, AIds);
  CollectIdsInDir(PciPath(ASourceDir, 'drivers'), True, AIds);
end;

// Текст - правильный UTF-8
function IsUtf8(const AText: string): Boolean;
var
  CharIdx, TailLen, TailIdx: Integer;
  CharByte: Byte;
begin
  Result := False;
  CharIdx := 1;
  while CharIdx <= Length(AText) do
  begin
    CharByte := Ord(AText[CharIdx]);
    if CharByte < $80 then
      TailLen := 0
    else if (CharByte and $E0) = $C0 then
      TailLen := 1
    else if (CharByte and $F0) = $E0 then
      TailLen := 2
    else if (CharByte and $F8) = $F0 then
      TailLen := 3
    else
      Exit;
    for TailIdx := 1 to TailLen do
      if (CharIdx + TailIdx > Length(AText)) or
         ((Ord(AText[CharIdx + TailIdx]) and $C0) <> $80) then
        Exit;
    Inc(CharIdx, TailLen + 1);
  end;
  Result := True;
end;

// Строка INF в кавычках: кавычка удваивается, % - тоже; длинное имя
// обрезается по границе символа UTF-8
function InfQuote(const AText: string): string;
var
  Text: string;
  CutLen: Integer;
begin
  Text := AText;
  if Length(Text) > MaxDescLen then
  begin
    CutLen := MaxDescLen;
    while (CutLen > 0) and ((Ord(Text[CutLen + 1]) and $C0) = $80) do
      Dec(CutLen);
    Text := TrimRight(Copy(Text, 1, CutLen));
  end;
  Text := StringReplace(Text, '"', '""', [rfReplaceAll]);
  Text := StringReplace(Text, '%', '%%', [rfReplaceAll]);
  Result := '"' + Text + '"';
end;

// Имя для отчёта (ANSI): UTF-8 из pci.ids переводится
function ReportText(const AUtf8: string): string;
begin
  Result := Utf8ToAnsi(AUtf8);
  if Result = '' then
    Result := AUtf8;
end;

function DeviceKey(const ADevice: TPciDevice): string;
begin
  Result := 'PCI\VEN_' + ADevice.Vendor + '&DEV_' + ADevice.Device;
end;

// Значение строки "имя=значение" (TStrings.ValueFromIndex в Delphi 7 нет)
function ValueOfLine(const ALine: string): string;
begin
  Result := Copy(ALine, Pos('=', ALine) + 1, MaxInt);
end;

// Словарь из двух списков: AKeys - сортированные ключи, Objects - номер
// значения в AValues. Поиск - Find самого списка ключей.
procedure MapPut(AKeys, AValues: TStringList; const AKey, AValue: string);
var
  FoundIdx: Integer;
begin
  if AKeys.Find(AKey, FoundIdx) then
    AValues[Integer(PtrInt(AKeys.Objects[FoundIdx]))] := AValue
  else
    AKeys.AddObject(AKey, TObject(PtrInt(AValues.Add(AValue))));
end;

function MapGet(AKeys, AValues: TStringList; const AKey: string;
                var AValue: string): Boolean;
var
  FoundIdx: Integer;
begin
  Result := AKeys.Find(AKey, FoundIdx);
  if Result then
    AValue := AValues[Integer(PtrInt(AKeys.Objects[FoundIdx]))]
  else
    AValue := '';
end;

function MapValueAt(AKeys, AValues: TStringList; AIndex: Integer): string;
begin
  Result := AValues[Integer(PtrInt(AKeys.Objects[AIndex]))];
end;

procedure MapInit(AKeys: TStringList);
begin
  AKeys.Clear;
  AKeys.Sorted := True;
  AKeys.Duplicates := dupIgnore;
end;

// Разделы установки из machine.inf (CopySectionPrefixes) - строками; там
// же LayoutFile из [Version]
procedure CopyMachineSections(const AMachine: TStringList; AOut: TStrings;
                              var ALayoutFile: string);
var
  LineIdx, PrefixIdx: Integer;
  Line, Section: string;
  Copying, InVersion: Boolean;
begin
  ALayoutFile := '';
  Copying := False;
  InVersion := False;
  for LineIdx := 0 to AMachine.Count - 1 do
  begin
    Line := Trim(AMachine[LineIdx]);
    if (Line <> '') and (Line[1] = '[') then
    begin
      Section := Copy(Line, 2, Pos(']', Line) - 2);
      InVersion := CompareText(Section, 'Version') = 0;
      Copying := False;
      for PrefixIdx := Low(CopySectionPrefixes) to High(CopySectionPrefixes) do
        if CompareText(Copy(Section, 1, Length(CopySectionPrefixes[PrefixIdx])),
                       CopySectionPrefixes[PrefixIdx]) = 0 then
          Copying := True;
      if Copying then
      begin
        if (AOut.Count > 0) and (AOut[AOut.Count - 1] <> '') then
          AOut.Add('');
        AOut.Add(Line);
      end;
      Continue;
    end;
    if InVersion and (CompareText(Copy(Line, 1, 10), 'LayoutFile') = 0) then
      ALayoutFile := Trim(Copy(Line, Pos('=', Line) + 1, MaxInt));
    // Комментарии между разделами относятся к следующему разделу
    if Copying and (Line <> '') and (Line[1] <> ';') then
      AOut.Add(AMachine[LineIdx]);
  end;
end;

// Переводы: "раздел языка" -> строки "PCI\VEN_...=текст UTF-8"
procedure LoadTranslations(const AFile: string; ALanguages: TStringList);
var
  Lines, Current: TStringList;
  LineIdx, EqPos: Integer;
  Line, Value: string;
begin
  ALanguages.Sorted := True;
  if not FileExists(AFile) then
    Exit;
  Lines := TStringList.Create;
  try
    Lines.Text := ReadRaw(AFile);
    // BOM UTF-8
    if (Lines.Count > 0) and (Copy(Lines[0], 1, 3) = #$EF#$BB#$BF) then
      Lines[0] := Copy(Lines[0], 4, MaxInt);
    Current := nil;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[LineIdx]);
      if (Line = '') or (Line[1] = ';') or (Line[1] = '#') then
        Continue;
      if Line[1] = '[' then
      begin
        Line := Trim(Copy(Line, 2, Pos(']', Line) - 2));
        Current := nil;
        if Line = '' then
          Continue;
        if ALanguages.IndexOf(Line) < 0 then
          ALanguages.AddObject(Line, TStringList.Create);
        Current := TStringList(ALanguages.Objects[ALanguages.IndexOf(Line)]);
        Continue;
      end;
      EqPos := Pos('=', Line);
      if (Current = nil) or (EqPos = 0) then
        Continue;
      Value := Trim(Copy(Line, EqPos + 1, MaxInt));
      if (Length(Value) >= 2) and (Value[1] = '"') and
         (Value[Length(Value)] = '"') then
        Value := Copy(Value, 2, Length(Value) - 2);
      if not IsUtf8(Value) then
        Value := AnsiToUtf8(Value);
      Current.Add(UpperCase(Trim(Copy(Line, 1, EqPos - 1))) + '=' + Value);
    end;
  finally
    Lines.Free;
  end;
end;

procedure FreeTranslations(ALanguages: TStringList);
var
  LangIdx: Integer;
begin
  for LangIdx := 0 to ALanguages.Count - 1 do
    ALanguages.Objects[LangIdx].Free;
  ALanguages.Free;
end;

// Записи прежнего pciids.inf: ключ PCI\VEN_xxxx&DEV_yyyy, значение
// "раздел|имя" (имя - из [Strings], как в файле, без кавычек)
procedure LoadOldEntries(const AFile: string; AKeys, AValues: TStringList);
var
  Lines, NameKeys, NameValues: TStringList;
  LineIdx, EqPos, CommaPos: Integer;
  Line, Section, Key, Value, Desc: string;
begin
  MapInit(AKeys);
  AValues.Clear;
  if not FileExists(AFile) then
    Exit;
  Lines := TStringList.Create;
  NameKeys := TStringList.Create;
  NameValues := TStringList.Create;
  try
    MapInit(NameKeys);
    Lines.Text := ReadRaw(AFile);
    Section := '';
    // Модели: %PCI\VEN_8086&DEV_27B9.DeviceDesc% = PCI_ISA_Inst,PCI\VEN_...
    // Строки: PCI\VEN_8086&DEV_27B9.DeviceDesc = "..."
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[LineIdx]);
      if (Line = '') or (Line[1] = ';') then
        Continue;
      if Line[1] = '[' then
      begin
        Section := Copy(Line, 2, Pos(']', Line) - 2);
        Continue;
      end;
      EqPos := Pos('=', Line);
      if EqPos = 0 then
        Continue;
      Key := Trim(Copy(Line, 1, EqPos - 1));
      Value := Trim(Copy(Line, EqPos + 1, MaxInt));
      if Copy(Key, 1, 9) = '%PCI\VEN_' then
      begin
        CommaPos := Pos(',', Value);
        if CommaPos > 0 then
          MapPut(AKeys, AValues, Trim(Copy(Value, CommaPos + 1, MaxInt)),
                 Trim(Copy(Value, 1, CommaPos - 1)));
      end
      else if (CompareText(Section, 'Strings') = 0) and
              (Copy(Key, 1, 8) = 'PCI\VEN_') then
      begin
        if (Length(Value) >= 2) and (Value[1] = '"') then
          Value := Copy(Value, 2, Length(Value) - 2);
        MapPut(NameKeys, NameValues, Copy(Key, 1, Pos('.', Key) - 1), Value);
      end;
    end;
    for LineIdx := 0 to AKeys.Count - 1 do
    begin
      MapGet(NameKeys, NameValues, AKeys[LineIdx], Desc);
      AValues[Integer(PtrInt(AKeys.Objects[LineIdx]))] :=
        MapValueAt(AKeys, AValues, LineIdx) + '|' + Desc;
    end;
  finally
    Lines.Free;
    NameKeys.Free;
    NameValues.Free;
  end;
end;

// DriverVer: дата pci.ids "2026-10-15 03:15:02" -> "10/15/2026"
function InfDate(const APciDate: string): string;
begin
  if (Length(APciDate) >= 10) and (APciDate[5] = '-') and
     (APciDate[8] = '-') then
    Result := Copy(APciDate, 6, 2) + '/' + Copy(APciDate, 9, 2) + '/' +
              Copy(APciDate, 1, 4)
  else
    Result := FormatDateTime('mm"/"dd"/"yyyy', Now);
end;

function PciGenerateInf(const ASourceDir, AVendors: string;
                        AReport: TStrings; var AStats: TPciGenStats;
                        var AError: string): Boolean;
var
  Db: TPciDb;
  VendorList, KnownIds, Machine, Body, Models, Strings, Review, OldKeys,
  OldValues, NewKeys, NewValues, Languages, Sections, Changes, VendorCounts,
  LangStrings: TStringList;
  DevIdx, LangIdx, EntryIdx, VendorPos, FoundIdx: Integer;
  Kind: TPciInstKind;
  Invalid, LayoutFile, Vendor, Key, Eol, MachineFile, InfFile, OldValue,
  NewValue, Desc: string;
  Added, Changed, Removed: Integer;
  LangStarted: Boolean;

  procedure AddVendorSection(const AVendor: string);
  begin
    Models.Add('');
    Models.Add('[Mfg_' + AVendor + ']');
    Strings.Add('');
    Strings.Add('Mfg_' + AVendor + ' = ' + InfQuote(Db.VendorName(AVendor)));
    VendorCounts.Add(AVendor + '=0');
  end;

begin
  Result := False;
  AError := '';
  FillChar(AStats, SizeOf(AStats), 0);
  MachineFile := PciPath(ASourceDir, PciMachineRelFile);
  InfFile := PciPath(ASourceDir, PciInfRelFile);
  if not FileExists(MachineFile) then
  begin
    AError := 'нет ' + MachineFile + ' - это не дерево ReactOS / LiberNT?';
    Exit;
  end;
  Db := TPciDb.Create;
  VendorList := TStringList.Create;
  KnownIds := TStringList.Create;
  Machine := TStringList.Create;
  Body := TStringList.Create;
  Models := TStringList.Create;
  Strings := TStringList.Create;
  Review := TStringList.Create;
  OldKeys := TStringList.Create;
  OldValues := TStringList.Create;
  NewKeys := TStringList.Create;
  NewValues := TStringList.Create;
  Languages := TStringList.Create;
  Sections := TStringList.Create;
  Changes := TStringList.Create;
  VendorCounts := TStringList.Create;
  try
    if not Db.LoadFromFile(PciPath(ASourceDir, PciIdsRelFile)) then
    begin
      AError := 'нет ' + PciPath(ASourceDir, PciIdsRelFile) + ' или это не ' +
                'pci.ids - сначала ReactOS - Update pci.ids';
      Exit;
    end;
    PciParseVendors(AVendors, VendorList, Invalid);
    PciCollectInfIds(ASourceDir, KnownIds);
    Machine.Text := ReadRaw(MachineFile);
    // Окончания строк - как у machine.inf
    if Pos(#13#10, ReadRaw(MachineFile)) > 0 then
      Eol := #13#10
    else
      Eol := #10;
    AStats.FirstTime := not FileExists(InfFile);
    LoadOldEntries(InfFile, OldKeys, OldValues);
    LoadTranslations(PciPath(ASourceDir, PciTranslRelFile), Languages);
    CopyMachineSections(Machine, Sections, LayoutFile);
    MapInit(NewKeys);

    Vendor := '';
    for DevIdx := 0 to Db.Count - 1 do
    begin
      if KnownIds.Find(Db.Devices[DevIdx].Vendor + ':' +
                       Db.Devices[DevIdx].Device, FoundIdx) then
      begin
        Inc(AStats.Known);
        Continue;
      end;
      Kind := PciClassify(Db.Devices[DevIdx].Name);
      case Kind of
        pkExclude:
          begin
            Inc(AStats.Excluded);
            Continue;
          end;
        pkNone:
          begin
            // На проверку - только производители из списка: у остальных
            // такие имена - платы расширения, не чипсет
            if HasAnyWord(UpperCase(Db.Devices[DevIdx].Name),
                          VideoNameWords) then
              Inc(AStats.Excluded)
            else if VendorList.Find(Db.Devices[DevIdx].Vendor,
                                    VendorPos) then
            begin
              Inc(AStats.Review);
              Review.Add(DeviceKey(Db.Devices[DevIdx]) + '  ' +
                         ReportText(Db.Devices[DevIdx].Name));
            end;
            Continue;
          end;
        pkNoDrv:
          if not VendorList.Find(Db.Devices[DevIdx].Vendor, VendorPos) then
          begin
            Inc(AStats.OtherVendor);
            Continue;
          end;
      end;
      case Kind of
        pkPciIsa: Inc(AStats.PciIsa);
        pkPci: Inc(AStats.Pci);
        pkNoDrv: Inc(AStats.NoDrv);
      end;
      if Db.Devices[DevIdx].Vendor <> Vendor then
      begin
        Vendor := Db.Devices[DevIdx].Vendor;
        AddVendorSection(Vendor);
      end;
      VendorCounts.Values[Vendor] :=
        IntToStr(StrToInt(VendorCounts.Values[Vendor]) + 1);
      Key := DeviceKey(Db.Devices[DevIdx]);
      Models.Add('%' + Key + '.DeviceDesc% = ' + InstSection[Kind] + ',' +
                 Key);
      Desc := InfQuote(Db.Devices[DevIdx].Name);
      Strings.Add(Key + '.DeviceDesc = ' + Desc);
      // Для сравнения с прежним файлом - как его читает LoadOldEntries
      MapPut(NewKeys, NewValues, Key, InstSection[Kind] + '|' +
             Copy(Desc, 2, Length(Desc) - 2));
    end;

    // Файл
    Body.Add('; Generated by unIDE from pci.ids ' + Db.Version + ' (' +
             Db.Date + '), do not edit.');
    Body.Add('; Source: ' + PciIdsUrl + ' (GPL v2+ or BSD 3-clause).');
    Body.Add('; Regenerate: unIDE, ReactOS - Generate System Devices INF.');
    Body.Add('');
    Body.Add('[Version]');
    Body.Add('Signature  = "$Windows NT$"');
    if LayoutFile <> '' then
      Body.Add('LayoutFile = ' + LayoutFile);
    Body.Add('Class      = System');
    Body.Add('ClassGUID  = {4D36E97D-E325-11CE-BFC1-08002BE10318}');
    Body.Add('Provider   = %ReactOS%');
    Body.Add('DriverVer  = ' + InfDate(Db.Date) + ',1.00');
    Body.Add('');
    Body.Add('[DestinationDirs]');
    Body.Add('DefaultDestDir = 12');
    Body.Add('');
    Body.Add('[Manufacturer]');
    for EntryIdx := 0 to VendorCounts.Count - 1 do
      Body.Add('%Mfg_' + VendorCounts.Names[EntryIdx] + '% = Mfg_' +
               VendorCounts.Names[EntryIdx]);
    Body.AddStrings(Models);
    Body.Add('');
    Body.Add(';------------- Install sections, copied from machine.inf ' +
             '-------------');
    Body.Add('');
    Body.AddStrings(Sections);
    Body.Add('');
    Body.Add(';------------------------------- STRINGS ' +
             '-------------------------------');
    Body.Add('');
    Body.Add('[Strings]');
    Body.Add('ReactOS = "ReactOS Team"');
    Body.AddStrings(Strings);

    // Переводы - только для устройств этого файла
    for LangIdx := 0 to Languages.Count - 1 do
    begin
      LangStarted := False;
      LangStrings := TStringList(Languages.Objects[LangIdx]);
      for EntryIdx := 0 to LangStrings.Count - 1 do
      begin
        Key := LangStrings.Names[EntryIdx];
        if not NewKeys.Find(Key, FoundIdx) then
          Continue;
        if not LangStarted then
        begin
          Body.Add('');
          Body.Add('[Strings.' + Languages[LangIdx] + ']');
          LangStarted := True;
        end;
        Body.Add(Key + '.DeviceDesc = ' +
                 InfQuote(ValueOfLine(LangStrings[EntryIdx])));
        Inc(AStats.Translated);
      end;
    end;

    ForceDirectories(ExtractFileDir(InfFile));
    if not WriteRaw(InfFile, StringReplace(Body.Text, #13#10, Eol,
                                           [rfReplaceAll])) then
    begin
      AError := 'не удалось записать ' + InfFile;
      Exit;
    end;

    // Разница с прежним файлом
    Added := 0;
    Changed := 0;
    Removed := 0;
    for EntryIdx := 0 to NewKeys.Count - 1 do
    begin
      Key := NewKeys[EntryIdx];
      NewValue := MapValueAt(NewKeys, NewValues, EntryIdx);
      if not MapGet(OldKeys, OldValues, Key, OldValue) then
      begin
        if not AStats.FirstTime then
          Changes.Add('+ ' + Key + '  ' + ReportText(NewValue));
        Inc(Added);
      end
      else
      begin
        if OldValue <> NewValue then
        begin
          Changes.Add('~ ' + Key + '  ' + ReportText(OldValue) +
                      '  ->  ' + ReportText(NewValue));
          Inc(Changed);
        end;
      end;
    end;
    for EntryIdx := 0 to OldKeys.Count - 1 do
      if not NewKeys.Find(OldKeys[EntryIdx], FoundIdx) then
      begin
        Changes.Add('- ' + OldKeys[EntryIdx] + '  ' +
                    ReportText(MapValueAt(OldKeys, OldValues, EntryIdx)));
        Inc(Removed);
      end;

    // Отчёт
    AReport.Add(PciInfRelFile + ' из pci.ids ' + Db.Version + ' (' +
                Db.Date + ')');
    AReport.Add('');
    AReport.Add(Format('Записей: %d (PCI_ISA_Inst %d, PCI_Inst %d, ' +
                       'NO_DRV %d)', [AStats.PciIsa + AStats.Pci +
                       AStats.NoDrv, AStats.PciIsa, AStats.Pci,
                       AStats.NoDrv]));
    for EntryIdx := 0 to VendorCounts.Count - 1 do
      AReport.Add(Format('  %s %s: %s', [VendorCounts.Names[EntryIdx],
        ReportText(Db.VendorName(VendorCounts.Names[EntryIdx])),
        ValueOfLine(VendorCounts[EntryIdx])]));
    AReport.Add(Format('Уже описаны в других INF (media\inf, drivers): %d',
                       [AStats.Known]));
    AReport.Add(Format('Не включены - USB, SATA, звук, видео, сеть и т. п.: ' +
                       '%d', [AStats.Excluded]));
    AReport.Add(Format('Служебные устройства производителей не из списка: ' +
                       '%d', [AStats.OtherVendor]));
    AReport.Add(Format('Строк перевода: %d', [AStats.Translated]));
    if Invalid <> '' then
      AReport.Add('Не коды производителей (пропущены): ' + Invalid);
    AReport.Add('');
    if AStats.FirstTime then
      AReport.Add('Изменения: файл создан впервые')
    else
    begin
      AReport.Add(Format('Изменения против прежнего файла: добавлено %d, ' +
                         'изменено %d, удалено %d', [Added, Changed,
                         Removed]));
      AReport.AddStrings(Changes);
    end;
    AReport.Add('');
    AReport.Add(Format('На ручную проверку (производители из списка, имя ' +
                       'не подошло ни под одно правило): %d', [AStats.Review]));
    AReport.AddStrings(Review);
    Result := True;
  finally
    Db.Free;
    VendorList.Free;
    KnownIds.Free;
    Machine.Free;
    Body.Free;
    Models.Free;
    Strings.Free;
    Review.Free;
    OldKeys.Free;
    OldValues.Free;
    NewKeys.Free;
    NewValues.Free;
    FreeTranslations(Languages);
    Sections.Free;
    Changes.Free;
    VendorCounts.Free;
  end;
end;

// Строки CMakeLists.txt и окончание строк
function LoadCMake(const ASourceDir: string; ALines: TStringList;
                   var AEol: string): Boolean;
var
  Raw: string;
begin
  Result := FileExists(PciPath(ASourceDir, PciCMakeRelFile));
  if not Result then
    Exit;
  Raw := ReadRaw(PciPath(ASourceDir, PciCMakeRelFile));
  if Pos(#13#10, Raw) > 0 then
    AEol := #13#10
  else
    AEol := #10;
  ALines.Text := Raw;
end;

function PciCMakeHasInf(const ASourceDir: string): Boolean;
var
  Lines: TStringList;
  LineIdx: Integer;
  Eol: string;
begin
  Result := False;
  Lines := TStringList.Create;
  try
    if not LoadCMake(ASourceDir, Lines, Eol) then
      Exit;
    for LineIdx := 0 to Lines.Count - 1 do
      if Pos(PciInfName, LowerCase(Lines[LineIdx])) > 0 then
      begin
        Result := True;
        Exit;
      end;
  finally
    Lines.Free;
  end;
end;

function PciCMakeAddInf(const ASourceDir: string): Boolean;
var
  Lines: TStringList;
  LineIdx, IndentLen: Integer;
  Eol, Line: string;
  InList: Boolean;
begin
  Result := False;
  Lines := TStringList.Create;
  try
    if not LoadCMake(ASourceDir, Lines, Eol) then
      Exit;
    InList := False;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Lines[LineIdx];
      if Pos('list(APPEND INF_FILES', Line) > 0 then
        InList := True;
      if InList and (CompareText(Trim(Line), 'machine.inf') = 0) then
      begin
        IndentLen := Length(Line) - Length(TrimLeft(Line));
        Lines.Insert(LineIdx + 1, Copy(Line, 1, IndentLen) + PciInfName);
        Result := WriteRaw(PciPath(ASourceDir, PciCMakeRelFile),
                           StringReplace(Lines.Text, #13#10, Eol,
                                         [rfReplaceAll]));
        Exit;
      end;
      if InList and (Pos(')', Line) > 0) then
        InList := False;
    end;
  finally
    Lines.Free;
  end;
end;

end.
