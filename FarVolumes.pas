unit FarVolumes;

// ---------------------------------------------------------------------------
//  Сведения о дисках и томах для меню дисков unIDE FAR (Alt+F1 / Alt+F2),
//  без diskpart:
//
//  - номер физического диска и раздела тома ('0:2' - диск 0, раздел 2):
//    IOCTL_STORAGE_GET_DEVICE_NUMBER к '\\.\C:' или '\\?\Volume{...}'.
//    Номер диска - тот же, что в 'Управлении дисками' и в diskpart
//    (list disk). Номер тома diskpart (Том #) - внутренняя нумерация
//    службы VDS, ей нужны права администратора; здесь его нет;
//  - физические диски '\\.\PhysicalDriveN': модель (производитель +
//    изделие), шина (SATA, USB, ...), сменный ли -
//    IOCTL_STORAGE_QUERY_PROPERTY; размер - IOCTL_DISK_GET_DRIVE_GEOMETRY_EX
//    (нет носителя в картридере - размера нет);
//  - устройство открывается без прав на чтение и запись (dwDesiredAccess
//    = 0): так Windows разрешает запрашивать свойства устройства, обычно и
//    без прав администратора. SMART, температура, паспорт ATA требуют
//    полного доступа - их здесь нет;
//  - тома без буквы (системные, скрытые разделы, папки-точки
//    подключения) - FindFirstVolumeW / GetVolumePathNamesForVolumeNameW:
//    метка, файловая система, размер, диск и раздел;
//  - размер в виде FAR: '476,14 G', '1,82 T' (FarSizeShort).
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils;

type
  // Где лежит том: устройство, номер диска, номер раздела
  TFarDeviceNumber = record
    Valid: Boolean;
    DeviceType: DWORD;        // FILE_DEVICE_DISK (7), FILE_DEVICE_CD_ROM (2)...
    DiskNumber: Integer;
    PartNumber: Integer;      // 0 - диск без таблицы разделов; -1 - нет
  end;

  // Физический диск (или CD-привод - для модели)
  TFarDisk = record
    Number: Integer;          // N из \\.\PhysicalDriveN
    Model: WideString;        // производитель + изделие
    BusText: WideString;      // SATA, USB, SCSI, ...
    Removable: Boolean;       // сменный носитель
    HasSize: Boolean;         // размер известен (носитель есть)
    Size: Int64;
    ErrorCode: DWORD;         // не открылось - код ошибки Windows, иначе 0
  end;
  TFarDisks = array of TFarDisk;

  TFarVolume = record
    MountPath: WideString;    // папка подключения (тома без буквы) или ''
    VolLabel: WideString;
    FileSys: WideString;
    SizeText: WideString;     // размер строкой (FarSizeShort)
    Total: Int64;
    Free: Int64;
    HasSize: Boolean;
    Device: TFarDeviceNumber;
  end;
  TFarVolumes = array of TFarVolume;

// Номер диска и раздела устройства: '\\.\C:', '\\?\Volume{...}' (без '\'
// в конце). Не открылось / не ответило - False, ANumber.Valid = False
function FarDeviceNumber(const ADevicePath: WideString;
  var ANumber: TFarDeviceNumber): Boolean;
// '0:2' - диск 0, раздел 2; 'CD0' - CD-привод 0; '' - неизвестно
function FarDeviceText(const ANumber: TFarDeviceNumber): WideString;
// Модель, шина, сменный устройства (диска, CD-привода); AWithSize - и
// размер (у CD не спрашиваем: привод с диском может раскручиваться)
function FarDeviceInfo(const ADevicePath: WideString; AWithSize: Boolean;
  var ADisk: TFarDisk): Boolean;
// Физические диски \\.\PhysicalDrive0..31. Результат: 0, или (дисков нет)
// код ошибки Windows первого отказа, кроме 'нет такого диска'
function FarPhysicalDisks(var ADisks: TFarDisks): DWORD;
// Индекс диска с номером ANumber в ADisks; -1 - нет
function FarFindDisk(const ADisks: TFarDisks; ANumber: Integer): Integer;
// Тома без буквы диска (через API Windows)
procedure FarNoLetterVolumes(var AVolumes: TFarVolumes);
// Размер как в FAR: '476,14 G'
function FarSizeShort(ABytes: Int64): WideString;

const
  FarDeviceDisk = 7;          // FILE_DEVICE_DISK
  FarDeviceCdRom = 2;         // FILE_DEVICE_CD_ROM
  FarDeviceDvd = $33;         // FILE_DEVICE_DVD
  FarMaxPhysicalDisks = 32;

implementation

const
  FvShareReadWrite = 3;       // FILE_SHARE_READ or FILE_SHARE_WRITE
  FvCpAnsi = 0;               // CP_ACP
  // CTL_CODE(тип, функция, METHOD_BUFFERED, FILE_ANY_ACCESS)
  FvIoctlStorageGetDeviceNumber = $002D1080;
  FvIoctlStorageQueryProperty = $002D1400;
  FvIoctlDiskGetDriveGeometryEx = $000700A0;
  FvErrorFileNotFound = 2;
  FvErrorPathNotFound = 3;

type
  TFvStorageDeviceNumber = packed record
    DeviceType: DWORD;
    DeviceNumber: DWORD;
    PartitionNumber: DWORD;
  end;
  TFvStoragePropertyQuery = packed record
    PropertyId: DWORD;        // StorageDeviceProperty = 0
    QueryType: DWORD;         // PropertyStandardQuery = 0
    Additional: array[0..3] of Byte;
  end;
  // STORAGE_DEVICE_DESCRIPTOR (начало); строки - по смещениям от начала
  TFvStorageDeviceDescriptor = packed record
    Version: DWORD;
    Size: DWORD;
    DeviceType: Byte;
    DeviceTypeModifier: Byte;
    RemovableMedia: Byte;
    CommandQueueing: Byte;
    VendorIdOffset: DWORD;
    ProductIdOffset: DWORD;
    ProductRevisionOffset: DWORD;
    SerialNumberOffset: DWORD;
    BusType: DWORD;
    RawPropertiesLength: DWORD;
  end;
  PFvStorageDeviceDescriptor = ^TFvStorageDeviceDescriptor;
  // DISK_GEOMETRY_EX (начало): DISK_GEOMETRY (24 байта), DiskSize
  TFvDiskGeometryEx = packed record
    Cylinders: Int64;
    MediaType: DWORD;
    TracksPerCylinder: DWORD;
    SectorsPerTrack: DWORD;
    BytesPerSector: DWORD;
    DiskSize: Int64;
  end;
  PFvDiskGeometryEx = ^TFvDiskGeometryEx;

  TFvGetPathNames = function(AVolumeName, APathNames: PWideChar;
    ABufferLength: DWORD; var AReturnLength: DWORD): BOOL; stdcall;
  TFvFindFirstVolume = function(AVolumeName: PWideChar;
    ABufferLength: DWORD): THandle; stdcall;
  TFvFindNextVolume = function(AFindHandle: THandle; AVolumeName: PWideChar;
    ABufferLength: DWORD): BOOL; stdcall;
  TFvFindVolumeClose = function(AFindHandle: THandle): BOOL; stdcall;

function FvMultiToWide(ACodePage: UINT; AFlags: DWORD; AMulti: PAnsiChar;
  AMultiLen: Integer; AWide: PWideChar; AWideLen: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'MultiByteToWideChar';
function FvCreateFile(AFileName: PWideChar; AAccess, AShare: DWORD;
  ASecurity: Pointer; ACreation, AFlags: DWORD;
  ATemplate: THandle): THandle; stdcall;
  external 'kernel32.dll' name 'CreateFileW';
function FvDeviceIoControl(ADevice: THandle; ACode: DWORD; AInBuffer: Pointer;
  AInSize: DWORD; AOutBuffer: Pointer; AOutSize: DWORD; var AReturned: DWORD;
  AOverlapped: Pointer): BOOL; stdcall;
  external 'kernel32.dll' name 'DeviceIoControl';
function FvGetVolumeInfo(ARoot, AVolumeName: PWideChar; AVolumeNameSize: DWORD;
  ASerial, AMaxComponent, AFlags: PDWORD; AFileSystem: PWideChar;
  AFileSystemSize: DWORD): BOOL; stdcall;
  external 'kernel32.dll' name 'GetVolumeInformationW';
function FvDiskFree(ADir: PWideChar; AFreeAvail, ATotalBytes,
  ATotalFree: PInt64): BOOL; stdcall;
  external 'kernel32.dll' name 'GetDiskFreeSpaceExW';

// ---------------------------------------------------------------------------

function FarSizeShort(ABytes: Int64): WideString;
const
  Units: array[0..4] of string = ('K', 'M', 'G', 'T', 'P');
var
  Value: Extended;
  UnitIdx: Integer;
begin
  if ABytes < 1024 then
  begin
    Result := IntToStr(ABytes) + ' B';
    Exit;
  end;
  Value := ABytes / 1024;
  UnitIdx := 0;
  while (Value >= 1000) and (UnitIdx < High(Units)) do
  begin
    Value := Value / 1024;
    Inc(UnitIdx);
  end;
  Result := Format('%.2f %s', [Value, Units[UnitIdx]]);
end;

function FvTrim(const AText: WideString): WideString;
var
  StartPos, EndPos: Integer;
begin
  StartPos := 1;
  EndPos := Length(AText);
  while (StartPos <= EndPos) and ((AText[StartPos] = ' ') or
        (AText[StartPos] = #9) or (AText[StartPos] = #13)) do
    Inc(StartPos);
  while (EndPos >= StartPos) and ((AText[EndPos] = ' ') or
        (AText[EndPos] = #9) or (AText[EndPos] = #13)) do
    Dec(EndPos);
  Result := Copy(AText, StartPos, EndPos - StartPos + 1);
end;

// Открыть устройство только для запроса свойств (без чтения и записи)
function FvOpenDevice(const ADevicePath: WideString): THandle;
begin
  Result := FvCreateFile(PWideChar(ADevicePath), 0, FvShareReadWrite, nil,
    OPEN_EXISTING, 0, 0);
end;

// Строка ANSI по смещению в ответе (смещение 0 или за пределами - '')
function FvDescString(ABuffer: PAnsiChar; ABufferLen, AOffset: DWORD): WideString;
var
  EndPos, WideLen: Integer;
  Raw: string;
begin
  Result := '';
  if (AOffset = 0) or (AOffset >= ABufferLen) then
    Exit;
  EndPos := AOffset;
  while (DWORD(EndPos) < ABufferLen) and (ABuffer[EndPos] <> #0) do
    Inc(EndPos);
  SetString(Raw, ABuffer + AOffset, EndPos - Integer(AOffset));
  if Raw = '' then
    Exit;
  WideLen := FvMultiToWide(FvCpAnsi, 0, PAnsiChar(Raw), Length(Raw), nil, 0);
  if WideLen <= 0 then
    Exit;
  SetLength(Result, WideLen);
  FvMultiToWide(FvCpAnsi, 0, PAnsiChar(Raw), Length(Raw), PWideChar(Result),
    WideLen);
  Result := FvTrim(Result);
end;

// STORAGE_BUS_TYPE -> название шины
function FvBusText(ABusType: DWORD): WideString;
begin
  case ABusType of
    1: Result := 'SCSI';
    2: Result := 'ATAPI';
    3: Result := 'ATA';
    4: Result := '1394';
    5: Result := 'SSA';
    6: Result := 'Fibre';
    7: Result := 'USB';
    8: Result := 'RAID';
    9: Result := 'iSCSI';
    10: Result := 'SAS';
    11: Result := 'SATA';
    12: Result := 'SD';
    13: Result := 'MMC';
    14: Result := 'Virtual';
    15: Result := 'VHD';
    16: Result := 'Spaces';
    17: Result := 'NVMe';
    18: Result := 'SCM';
    19: Result := 'UFS';
  else
    Result := '';
  end;
end;

function FarDeviceNumber(const ADevicePath: WideString;
  var ANumber: TFarDeviceNumber): Boolean;
var
  DevHandle: THandle;
  DevNumber: TFvStorageDeviceNumber;
  Returned: DWORD;
begin
  ANumber.Valid := False;
  ANumber.DeviceType := 0;
  ANumber.DiskNumber := -1;
  ANumber.PartNumber := -1;
  Result := False;
  DevHandle := FvOpenDevice(ADevicePath);
  if DevHandle = INVALID_HANDLE_VALUE then
    Exit;
  try
    FillChar(DevNumber, SizeOf(DevNumber), 0);
    Returned := 0;
    // Том на нескольких дисках (динамический, составной) - отказ
    if FvDeviceIoControl(DevHandle, FvIoctlStorageGetDeviceNumber, nil, 0,
       @DevNumber, SizeOf(DevNumber), Returned, nil) and
       (Returned >= SizeOf(DevNumber)) then
    begin
      ANumber.Valid := True;
      ANumber.DeviceType := DevNumber.DeviceType;
      ANumber.DiskNumber := Integer(DevNumber.DeviceNumber);
      if DevNumber.PartitionNumber = $FFFFFFFF then
        ANumber.PartNumber := -1
      else
        ANumber.PartNumber := Integer(DevNumber.PartitionNumber);
      Result := True;
    end;
  finally
    CloseHandle(DevHandle);
  end;
end;

function FarDeviceText(const ANumber: TFarDeviceNumber): WideString;
begin
  Result := '';
  if not ANumber.Valid then
    Exit;
  case ANumber.DeviceType of
    FarDeviceDisk:
      if ANumber.PartNumber >= 0 then
        Result := IntToStr(ANumber.DiskNumber) + ':' +
          IntToStr(ANumber.PartNumber)
      else
        Result := IntToStr(ANumber.DiskNumber);
    FarDeviceCdRom, FarDeviceDvd:
      Result := 'CD' + IntToStr(ANumber.DiskNumber);
  end;
end;

function FarDeviceInfo(const ADevicePath: WideString; AWithSize: Boolean;
  var ADisk: TFarDisk): Boolean;
var
  DevHandle: THandle;
  Query: TFvStoragePropertyQuery;
  Buffer: array[0..1023] of AnsiChar;
  Descriptor: PFvStorageDeviceDescriptor;
  Geometry: array[0..255] of Byte;
  Returned, DataLen: DWORD;
  Vendor, Product: WideString;
begin
  ADisk.Model := '';
  ADisk.BusText := '';
  ADisk.Removable := False;
  ADisk.HasSize := False;
  ADisk.Size := 0;
  ADisk.ErrorCode := 0;
  Result := False;
  DevHandle := FvOpenDevice(ADevicePath);
  if DevHandle = INVALID_HANDLE_VALUE then
  begin
    ADisk.ErrorCode := GetLastError;
    Exit;
  end;
  try
    Result := True;
    FillChar(Query, SizeOf(Query), 0);
    FillChar(Buffer, SizeOf(Buffer), 0);
    Returned := 0;
    if FvDeviceIoControl(DevHandle, FvIoctlStorageQueryProperty, @Query,
       SizeOf(Query), @Buffer[0], SizeOf(Buffer), Returned, nil) and
       (Returned >= SizeOf(TFvStorageDeviceDescriptor)) then
    begin
      Descriptor := PFvStorageDeviceDescriptor(@Buffer[0]);
      DataLen := Returned;
      if (Descriptor^.Size > 0) and (Descriptor^.Size < DataLen) then
        DataLen := Descriptor^.Size;
      Vendor := FvDescString(@Buffer[0], DataLen, Descriptor^.VendorIdOffset);
      Product := FvDescString(@Buffer[0], DataLen, Descriptor^.ProductIdOffset);
      // SATA-диски за SCSI-драйвером: производитель 'ATA' - не показываем
      if (Vendor <> '') and (UpperCase(string(Vendor)) <> 'ATA') then
        ADisk.Model := FvTrim(Vendor + ' ' + Product)
      else
        ADisk.Model := Product;
      ADisk.BusText := FvBusText(Descriptor^.BusType);
      ADisk.Removable := Descriptor^.RemovableMedia <> 0;
    end;
    // Размер: нет носителя (картридер, пустой привод) - отказ
    FillChar(Geometry, SizeOf(Geometry), 0);
    Returned := 0;
    if AWithSize and FvDeviceIoControl(DevHandle, FvIoctlDiskGetDriveGeometryEx, nil, 0,
       @Geometry[0], SizeOf(Geometry), Returned, nil) and
       (Returned >= SizeOf(TFvDiskGeometryEx)) then
    begin
      ADisk.Size := PFvDiskGeometryEx(@Geometry[0])^.DiskSize;
      ADisk.HasSize := ADisk.Size > 0;
    end;
  finally
    CloseHandle(DevHandle);
  end;
end;

function FarPhysicalDisks(var ADisks: TFarDisks): DWORD;
var
  DiskIdx, Count: Integer;
  Disk: TFarDisk;
begin
  SetLength(ADisks, 0);
  Result := 0;
  Count := 0;
  // Номера бывают с пропусками (диск отключили) - проверяем все
  for DiskIdx := 0 to FarMaxPhysicalDisks - 1 do
  begin
    if FarDeviceInfo('\\.\PhysicalDrive' + WideString(IntToStr(DiskIdx)),
       True, Disk) then
    begin
      Disk.Number := DiskIdx;
      SetLength(ADisks, Count + 1);
      ADisks[Count] := Disk;
      Inc(Count);
    end
    else if (Result = 0) and (Disk.ErrorCode <> FvErrorFileNotFound) and
       (Disk.ErrorCode <> FvErrorPathNotFound) then
      Result := Disk.ErrorCode;
  end;
  if Count > 0 then
    Result := 0;
end;

function FarFindDisk(const ADisks: TFarDisks; ANumber: Integer): Integer;
var
  DiskIdx: Integer;
begin
  Result := -1;
  for DiskIdx := 0 to High(ADisks) do
    if ADisks[DiskIdx].Number = ANumber then
    begin
      Result := DiskIdx;
      Exit;
    end;
end;

procedure FarNoLetterVolumes(var AVolumes: TFarVolumes);
var
  Kernel: HMODULE;
  GetPathNames: TFvGetPathNames;
  FindFirstVol: TFvFindFirstVolume;
  FindNextVol: TFvFindNextVolume;
  FindVolClose: TFvFindVolumeClose;
  FindHandle: THandle;
  VolName: array[0..MAX_PATH] of WideChar;
  Paths: array[0..4095] of WideChar;
  LabelBuf, FsBuf: array[0..MAX_PATH] of WideChar;
  ReturnLen: DWORD;
  PathPos: PWideChar;
  OnePath, FirstPath, DevicePath: WideString;
  HasLetter: Boolean;
  Volume: TFarVolume;
  FreeAvail, TotalBytes, TotalFree: Int64;
  Count: Integer;
begin
  SetLength(AVolumes, 0);
  Kernel := GetModuleHandle('kernel32.dll');
  if Kernel = 0 then
    Exit;
  @GetPathNames := GetProcAddress(Kernel, 'GetVolumePathNamesForVolumeNameW');
  @FindFirstVol := GetProcAddress(Kernel, 'FindFirstVolumeW');
  @FindNextVol := GetProcAddress(Kernel, 'FindNextVolumeW');
  @FindVolClose := GetProcAddress(Kernel, 'FindVolumeClose');
  if not Assigned(GetPathNames) or not Assigned(FindFirstVol) or
     not Assigned(FindNextVol) or not Assigned(FindVolClose) then
    Exit;
  FindHandle := FindFirstVol(VolName, MAX_PATH);
  if FindHandle = INVALID_HANDLE_VALUE then
    Exit;
  Count := 0;
  try
    repeat
      // Папки подключения тома: 'C:\', 'D:\mnt\x\' (через #0, в конце #0#0)
      ReturnLen := 0;
      FillChar(Paths, SizeOf(Paths), 0);
      HasLetter := False;
      FirstPath := '';
      if GetPathNames(VolName, Paths, Length(Paths) - 1, ReturnLen) then
      begin
        PathPos := @Paths[0];
        while PathPos^ <> #0 do
        begin
          OnePath := PathPos;
          Inc(PathPos, Length(OnePath) + 1);
          if (Length(OnePath) = 3) and (OnePath[2] = ':') then
            HasLetter := True
          else if FirstPath = '' then
            FirstPath := OnePath;
        end;
      end;
      if not HasLetter then
      begin
        LabelBuf[0] := #0;
        FsBuf[0] := #0;
        // Нет файловой системы (CD без диска и т.п.) - не показываем
        if FvGetVolumeInfo(VolName, LabelBuf, MAX_PATH, nil, nil, nil, FsBuf,
           MAX_PATH) then
        begin
          Volume.MountPath := FirstPath;
          Volume.VolLabel := PWideChar(@LabelBuf[0]);
          Volume.FileSys := PWideChar(@FsBuf[0]);
          Volume.HasSize := FvDiskFree(VolName, @FreeAvail, @TotalBytes,
            @TotalFree);
          Volume.Total := 0;
          Volume.Free := 0;
          Volume.SizeText := '';
          if Volume.HasSize then
          begin
            Volume.Total := TotalBytes;
            Volume.Free := TotalFree;
            Volume.SizeText := FarSizeShort(TotalBytes);
          end;
          // '\\?\Volume{...}\' -> устройство: без '\' в конце
          DevicePath := PWideChar(@VolName[0]);
          if (DevicePath <> '') and (DevicePath[Length(DevicePath)] = '\') then
            SetLength(DevicePath, Length(DevicePath) - 1);
          FarDeviceNumber(DevicePath, Volume.Device);
          SetLength(AVolumes, Count + 1);
          AVolumes[Count] := Volume;
          Inc(Count);
        end;
      end;
    until not FindNextVol(FindHandle, VolName, MAX_PATH);
  finally
    FindVolClose(FindHandle);
  end;
end;

end.
