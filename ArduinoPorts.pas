unit ArduinoPorts;

// COM-порты, которые есть в системе сейчас, и слежение за подключением и
// отключением устройств - как обновляется Диспетчер устройств.
//
// Перечисление - SetupAPI, класс устройств Ports: имя порта (PortName из
// ключа устройства), имя устройства (FriendlyName), VID и PID (из
// HardwareID), серийный номер (из кода экземпляра устройства USB). Порты,
// которых нет в SetupAPI, но есть в HARDWARE\DEVICEMAP\SERIALCOMM, тоже
// попадают в список - только с именем.
//
// Слежение: скрытое окно получает WM_DEVICECHANGE (рассылку Windows и
// подписку RegisterDeviceNotification на интерфейс COM-портов). При
// подключении сообщений приходит несколько подряд, поэтому список
// перечитывается через 400 мс после последнего; если он изменился -
// OnChange со списками появившихся и пропавших портов.
//
// Delphi 7 заголовков SetupAPI не содержит: функции берутся из
// setupapi.dll и cfgmgr32.dll при первом перечислении.

interface

uses
  Windows, Messages, SysUtils, Classes, Registry;

type
  TArdPortInfo = record
    Name: string;          // COM5
    FriendlyName: string;  // Arduino Due Programming Port (COM5)
    Vid: string;           // 2341 ('' - не USB или неизвестно)
    Pid: string;           // 003D
    SerialNo: string;      // '' - у устройства нет серийного номера
    InstanceId: string;    // USB\VID_2341&PID_003D\85734323430351F06171
  end;
  TArdPortArray = array of TArdPortInfo;

  // AArrived, ARemoved - имена портов (COM5)
  TArdPortsChangeEvent = procedure(Sender: TObject;
                                   AArrived, ARemoved: TStrings) of object;

  TArdPortWatcher = class
  private
    FWnd: HWND;
    FNotify: Pointer;
    FPorts: TArdPortArray;
    FOnChange: TArdPortsChangeEvent;
    procedure WndProc(var Message: TMessage);
    function GetCount: Integer;
    function GetPort(AIndex: Integer): TArdPortInfo;
  public
    constructor Create;
    destructor Destroy; override;
    // Перечитать список сейчас; если изменился - OnChange
    procedure Refresh;
    // Номер порта по имени; -1 - нет
    function IndexOf(const AName: string): Integer;
    property Count: Integer read GetCount;
    property Ports[AIndex: Integer]: TArdPortInfo read GetPort; default;
    property OnChange: TArdPortsChangeEvent read FOnChange write FOnChange;
  end;

// Порты, которые есть сейчас, по возрастанию номера
procedure ArdEnumPorts(var APorts: TArdPortArray);
// Имя устройства без хвоста " (COM5)"
function ArdPortDeviceName(const APort: TArdPortInfo): string;

implementation

const
  DIGCF_PRESENT = $00000002;
  SPDRP_HARDWAREID = $00000001;
  SPDRP_FRIENDLYNAME = $0000000C;
  DICS_FLAG_GLOBAL = $00000001;
  DIREG_DEV = $00000001;
  CR_SUCCESS = 0;

  GUID_DEVCLASS_PORTS: TGUID = '{4D36E978-E325-11CE-BFC1-08002BE10318}';
  GUID_DEVINTERFACE_COMPORT: TGUID = '{86E0D1E0-8089-11D0-9CE4-08003E301F73}';

  DBT_DEVNODES_CHANGED = $0007;
  DBT_DEVICEARRIVAL = $8000;
  DBT_DEVICEREMOVECOMPLETE = $8004;
  DBT_DEVTYP_DEVICEINTERFACE = $00000005;
  DEVICE_NOTIFY_WINDOW_HANDLE = $00000000;

  RefreshTimerId = 1;
  RefreshDelay = 400;

type
  TSpDevInfoData = record
    cbSize: DWORD;
    ClassGuid: TGUID;
    DevInst: DWORD;
    Reserved: Cardinal;
  end;

  TDevBroadcastDeviceInterface = record
    dbcc_size: DWORD;
    dbcc_devicetype: DWORD;
    dbcc_reserved: DWORD;
    dbcc_classguid: TGUID;
    dbcc_name: array[0..0] of Char;
  end;

  TSetupDiGetClassDevs = function(ClassGuid: PGUID; Enumerator: PChar;
    HwndParent: HWND; Flags: DWORD): THandle; stdcall;
  TSetupDiEnumDeviceInfo = function(DeviceInfoSet: THandle; MemberIndex: DWORD;
    var DeviceInfoData: TSpDevInfoData): BOOL; stdcall;
  TSetupDiGetDeviceRegistryProperty = function(DeviceInfoSet: THandle;
    var DeviceInfoData: TSpDevInfoData; PropertyId: DWORD;
    PropertyRegDataType: PDWORD; PropertyBuffer: PByte;
    PropertyBufferSize: DWORD; RequiredSize: PDWORD): BOOL; stdcall;
  TSetupDiOpenDevRegKey = function(DeviceInfoSet: THandle;
    var DeviceInfoData: TSpDevInfoData; Scope, HwProfile, KeyType: DWORD;
    SamDesired: REGSAM): HKEY; stdcall;
  TSetupDiGetDeviceInstanceId = function(DeviceInfoSet: THandle;
    var DeviceInfoData: TSpDevInfoData; DeviceInstanceId: PChar;
    DeviceInstanceIdSize: DWORD; RequiredSize: PDWORD): BOOL; stdcall;
  TSetupDiDestroyDeviceInfoList = function(DeviceInfoSet: THandle): BOOL;
    stdcall;
  TCmGetParent = function(var DevInstParent: DWORD; DevInst: DWORD;
    Flags: ULONG): DWORD; stdcall;
  TCmGetDeviceId = function(DevInst: DWORD; Buffer: PChar; BufferLen: ULONG;
    Flags: ULONG): DWORD; stdcall;
  TRegisterDeviceNotification = function(Recipient: THandle;
    NotificationFilter: Pointer; Flags: DWORD): Pointer; stdcall;
  TUnregisterDeviceNotification = function(Handle: Pointer): BOOL; stdcall;

var
  ApiLoaded: Boolean = False;
  SetupLib: HMODULE = 0;
  CfgLib: HMODULE = 0;
  SetupDiGetClassDevsApi: TSetupDiGetClassDevs = nil;
  SetupDiEnumDeviceInfoApi: TSetupDiEnumDeviceInfo = nil;
  SetupDiGetDeviceRegistryPropertyApi: TSetupDiGetDeviceRegistryProperty = nil;
  SetupDiOpenDevRegKeyApi: TSetupDiOpenDevRegKey = nil;
  SetupDiGetDeviceInstanceIdApi: TSetupDiGetDeviceInstanceId = nil;
  SetupDiDestroyDeviceInfoListApi: TSetupDiDestroyDeviceInfoList = nil;
  CmGetParentApi: TCmGetParent = nil;
  CmGetDeviceIdApi: TCmGetDeviceId = nil;

procedure LoadApi;
begin
  if ApiLoaded then
    Exit;
  ApiLoaded := True;
  SetupLib := LoadLibrary('setupapi.dll');
  if SetupLib <> 0 then
  begin
    @SetupDiGetClassDevsApi := GetProcAddress(SetupLib,
                                              'SetupDiGetClassDevsA');
    @SetupDiEnumDeviceInfoApi := GetProcAddress(SetupLib,
                                                'SetupDiEnumDeviceInfo');
    @SetupDiGetDeviceRegistryPropertyApi := GetProcAddress(SetupLib,
      'SetupDiGetDeviceRegistryPropertyA');
    @SetupDiOpenDevRegKeyApi := GetProcAddress(SetupLib,
                                               'SetupDiOpenDevRegKey');
    @SetupDiGetDeviceInstanceIdApi := GetProcAddress(SetupLib,
      'SetupDiGetDeviceInstanceIdA');
    @SetupDiDestroyDeviceInfoListApi := GetProcAddress(SetupLib,
      'SetupDiDestroyDeviceInfoList');
  end;
  CfgLib := LoadLibrary('cfgmgr32.dll');
  if CfgLib <> 0 then
  begin
    @CmGetParentApi := GetProcAddress(CfgLib, 'CM_Get_Parent');
    @CmGetDeviceIdApi := GetProcAddress(CfgLib, 'CM_Get_Device_IDA');
  end;
end;

// ---------------------------------------------------------------------------
//  Перечисление
// ---------------------------------------------------------------------------

// Номер порта для сортировки: COM5 -> 5, остальное - в конец
function PortNumber(const AName: string): Integer;
begin
  if CompareText(Copy(AName, 1, 3), 'COM') = 0 then
    Result := StrToIntDef(Copy(AName, 4, MaxInt), MaxInt)
  else
    Result := MaxInt;
end;

// 4 шестнадцатеричные цифры после AMark (VID_, PID_) в AText
function HexAfter(const AText, AMark: string): string;
var
  MarkPos: Integer;
begin
  Result := '';
  MarkPos := Pos(AMark, UpperCase(AText));
  if MarkPos > 0 then
    Result := UpperCase(Copy(AText, MarkPos + Length(AMark), 4));
end;

// Серийный номер - последняя часть кода экземпляра USB-устройства, если
// в ней нет '&' (с '&' - номер, который придумала Windows)
function SerialFromInstance(const AInstanceId: string): string;
var
  CharIdx: Integer;
begin
  Result := '';
  if CompareText(Copy(AInstanceId, 1, 4), 'USB\') <> 0 then
    Exit;
  for CharIdx := Length(AInstanceId) downto 1 do
    if AInstanceId[CharIdx] = '\' then
    begin
      Result := Copy(AInstanceId, CharIdx + 1, MaxInt);
      Break;
    end;
  if Pos('&', Result) > 0 then
    Result := '';
end;

function DeviceProperty(ADevInfo: THandle; var AData: TSpDevInfoData;
                        AProperty: DWORD): string;
var
  Buffer: array[0..1023] of Char;
begin
  Result := '';
  FillChar(Buffer, SizeOf(Buffer), 0);
  if SetupDiGetDeviceRegistryPropertyApi(ADevInfo, AData, AProperty, nil,
       PByte(@Buffer[0]), SizeOf(Buffer) - 2, nil) then
    Result := string(PChar(@Buffer[0]));   // REG_MULTI_SZ - первая строка
end;

function DevicePortName(ADevInfo: THandle; var AData: TSpDevInfoData): string;
var
  DevKey: HKEY;
  Buffer: array[0..255] of Char;
  ValueSize, ValueType: DWORD;
begin
  Result := '';
  DevKey := SetupDiOpenDevRegKeyApi(ADevInfo, AData, DICS_FLAG_GLOBAL, 0,
                                    DIREG_DEV, KEY_READ);
  if (DevKey = 0) or (DevKey = HKEY(INVALID_HANDLE_VALUE)) then
    Exit;
  try
    FillChar(Buffer, SizeOf(Buffer), 0);
    ValueSize := SizeOf(Buffer) - 1;
    if (RegQueryValueEx(DevKey, 'PortName', nil, @ValueType, @Buffer[0],
                        @ValueSize) = ERROR_SUCCESS) and
       (ValueType = REG_SZ) then
      Result := Trim(string(PChar(@Buffer[0])));
  finally
    RegCloseKey(DevKey);
  end;
end;

// Код экземпляра устройства; у составного устройства (MI_xx) серийный
// номер - у родителя, поэтому для него - код родителя
function DeviceInstance(ADevInfo: THandle; var AData: TSpDevInfoData;
                        var AParentId: string): string;
var
  Buffer: array[0..511] of Char;
  ParentInst: DWORD;
begin
  Result := '';
  AParentId := '';
  FillChar(Buffer, SizeOf(Buffer), 0);
  if Assigned(SetupDiGetDeviceInstanceIdApi) and
     SetupDiGetDeviceInstanceIdApi(ADevInfo, AData, @Buffer[0],
                                   SizeOf(Buffer) - 1, nil) then
    Result := string(PChar(@Buffer[0]));
  if (Pos('&MI_', UpperCase(Result)) > 0) and Assigned(CmGetParentApi) and
     Assigned(CmGetDeviceIdApi) and
     (CmGetParentApi(ParentInst, AData.DevInst, 0) = CR_SUCCESS) then
  begin
    FillChar(Buffer, SizeOf(Buffer), 0);
    if CmGetDeviceIdApi(ParentInst, @Buffer[0], SizeOf(Buffer) - 1,
                        0) = CR_SUCCESS then
      AParentId := string(PChar(@Buffer[0]));
  end;
end;

procedure AddPort(var APorts: TArdPortArray; var ACount: Integer;
                  const APort: TArdPortInfo);
var
  PortIdx: Integer;
begin
  for PortIdx := 0 to ACount - 1 do
    if CompareText(APorts[PortIdx].Name, APort.Name) = 0 then
      Exit;
  if ACount = Length(APorts) then
    SetLength(APorts, ACount + 8);
  APorts[ACount] := APort;
  Inc(ACount);
end;

procedure ArdEnumPorts(var APorts: TArdPortArray);
var
  DevInfo: THandle;
  DevData: TSpDevInfoData;
  MemberIdx, PortCount, SortIdx, NextIdx: Integer;
  OnePort, SwapPort: TArdPortInfo;
  HardwareId, ParentId: string;
  Reg: TRegistry;
  ValueNames: TStringList;
  ValueIdx: Integer;
begin
  APorts := nil;
  PortCount := 0;
  LoadApi;

  if Assigned(SetupDiGetClassDevsApi) and Assigned(SetupDiEnumDeviceInfoApi) and
     Assigned(SetupDiGetDeviceRegistryPropertyApi) and
     Assigned(SetupDiOpenDevRegKeyApi) and
     Assigned(SetupDiDestroyDeviceInfoListApi) then
  begin
    DevInfo := SetupDiGetClassDevsApi(@GUID_DEVCLASS_PORTS, nil, 0,
                                      DIGCF_PRESENT);
    if DevInfo <> INVALID_HANDLE_VALUE then
    try
      MemberIdx := 0;
      while True do
      begin
        FillChar(DevData, SizeOf(DevData), 0);
        DevData.cbSize := SizeOf(DevData);
        if not SetupDiEnumDeviceInfoApi(DevInfo, MemberIdx, DevData) then
          Break;
        Inc(MemberIdx);
        OnePort.Name := DevicePortName(DevInfo, DevData);
        // В классе Ports и LPT - только COM
        if CompareText(Copy(OnePort.Name, 1, 3), 'COM') <> 0 then
          Continue;
        OnePort.FriendlyName := DeviceProperty(DevInfo, DevData,
                                               SPDRP_FRIENDLYNAME);
        HardwareId := DeviceProperty(DevInfo, DevData, SPDRP_HARDWAREID);
        OnePort.Vid := HexAfter(HardwareId, 'VID_');
        OnePort.Pid := HexAfter(HardwareId, 'PID_');
        OnePort.InstanceId := DeviceInstance(DevInfo, DevData, ParentId);
        if ParentId <> '' then
          OnePort.SerialNo := SerialFromInstance(ParentId)
        else
          OnePort.SerialNo := SerialFromInstance(OnePort.InstanceId);
        AddPort(APorts, PortCount, OnePort);
      end;
    finally
      SetupDiDestroyDeviceInfoListApi(DevInfo);
    end;
  end;

  // Порты без устройства Plug and Play - только из SERIALCOMM
  Reg := TRegistry.Create(KEY_READ);
  ValueNames := TStringList.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('HARDWARE\DEVICEMAP\SERIALCOMM') then
    begin
      Reg.GetValueNames(ValueNames);
      for ValueIdx := 0 to ValueNames.Count - 1 do
      begin
        OnePort.Name := '';
        try
          OnePort.Name := Trim(Reg.ReadString(ValueNames[ValueIdx]));
        except
          Continue;
        end;
        if OnePort.Name = '' then
          Continue;
        OnePort.FriendlyName := ValueNames[ValueIdx];
        OnePort.Vid := '';
        OnePort.Pid := '';
        OnePort.SerialNo := '';
        OnePort.InstanceId := '';
        AddPort(APorts, PortCount, OnePort);
      end;
      Reg.CloseKey;
    end;
  finally
    ValueNames.Free;
    Reg.Free;
  end;

  SetLength(APorts, PortCount);
  for SortIdx := 0 to PortCount - 2 do
    for NextIdx := SortIdx + 1 to PortCount - 1 do
      if PortNumber(APorts[NextIdx].Name) < PortNumber(APorts[SortIdx].Name) then
      begin
        SwapPort := APorts[SortIdx];
        APorts[SortIdx] := APorts[NextIdx];
        APorts[NextIdx] := SwapPort;
      end;
end;

function ArdPortDeviceName(const APort: TArdPortInfo): string;
var
  Tail: string;
begin
  Result := APort.FriendlyName;
  Tail := ' (' + APort.Name + ')';
  if (Length(Result) > Length(Tail)) and
     (CompareText(Copy(Result, Length(Result) - Length(Tail) + 1, MaxInt),
                  Tail) = 0) then
    SetLength(Result, Length(Result) - Length(Tail));
end;

// ---------------------------------------------------------------------------
//  TArdPortWatcher
// ---------------------------------------------------------------------------

constructor TArdPortWatcher.Create;
var
  Filter: TDevBroadcastDeviceInterface;
  RegisterApi: TRegisterDeviceNotification;
begin
  inherited Create;
  FWnd := Classes.AllocateHWnd(WndProc);
  ArdEnumPorts(FPorts);

  FillChar(Filter, SizeOf(Filter), 0);
  Filter.dbcc_size := SizeOf(Filter);
  Filter.dbcc_devicetype := DBT_DEVTYP_DEVICEINTERFACE;
  Filter.dbcc_classguid := GUID_DEVINTERFACE_COMPORT;
  @RegisterApi := GetProcAddress(GetModuleHandle(user32),
                                 'RegisterDeviceNotificationA');
  if Assigned(RegisterApi) then
    FNotify := RegisterApi(FWnd, @Filter, DEVICE_NOTIFY_WINDOW_HANDLE);
end;

destructor TArdPortWatcher.Destroy;
var
  UnregisterApi: TUnregisterDeviceNotification;
begin
  if FNotify <> nil then
  begin
    @UnregisterApi := GetProcAddress(GetModuleHandle(user32),
                                     'UnregisterDeviceNotification');
    if Assigned(UnregisterApi) then
      UnregisterApi(FNotify);
    FNotify := nil;
  end;
  if FWnd <> 0 then
  begin
    KillTimer(FWnd, RefreshTimerId);
    Classes.DeallocateHWnd(FWnd);
    FWnd := 0;
  end;
  inherited Destroy;
end;

procedure TArdPortWatcher.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_DEVICECHANGE:
      begin
        if (Message.WParam = DBT_DEVICEARRIVAL) or
           (Message.WParam = DBT_DEVICEREMOVECOMPLETE) or
           (Message.WParam = DBT_DEVNODES_CHANGED) then
          SetTimer(FWnd, RefreshTimerId, RefreshDelay, nil);
        Message.Result := 1;   // BROADCAST_QUERY_DENY не возвращаем
      end;
    WM_TIMER:
      if Message.WParam = RefreshTimerId then
      begin
        KillTimer(FWnd, RefreshTimerId);
        Refresh;
      end;
  else
    Message.Result := DefWindowProc(FWnd, Message.Msg, Message.WParam,
                                    Message.LParam);
  end;
end;

procedure TArdPortWatcher.Refresh;
var
  NewPorts: TArdPortArray;
  Arrived, Removed: TStringList;
  PortIdx, OldIdx: Integer;
  Found: Boolean;
begin
  ArdEnumPorts(NewPorts);
  Arrived := TStringList.Create;
  Removed := TStringList.Create;
  try
    for PortIdx := 0 to High(NewPorts) do
    begin
      Found := False;
      for OldIdx := 0 to High(FPorts) do
        if CompareText(FPorts[OldIdx].Name, NewPorts[PortIdx].Name) = 0 then
        begin
          Found := True;
          Break;
        end;
      if not Found then
        Arrived.Add(NewPorts[PortIdx].Name);
    end;
    for OldIdx := 0 to High(FPorts) do
    begin
      Found := False;
      for PortIdx := 0 to High(NewPorts) do
        if CompareText(FPorts[OldIdx].Name, NewPorts[PortIdx].Name) = 0 then
        begin
          Found := True;
          Break;
        end;
      if not Found then
        Removed.Add(FPorts[OldIdx].Name);
    end;
    FPorts := NewPorts;
    if ((Arrived.Count > 0) or (Removed.Count > 0)) and Assigned(FOnChange) then
      FOnChange(Self, Arrived, Removed);
  finally
    Removed.Free;
    Arrived.Free;
  end;
end;

function TArdPortWatcher.IndexOf(const AName: string): Integer;
var
  PortIdx: Integer;
begin
  Result := -1;
  for PortIdx := 0 to High(FPorts) do
    if CompareText(FPorts[PortIdx].Name, AName) = 0 then
    begin
      Result := PortIdx;
      Exit;
    end;
end;

function TArdPortWatcher.GetCount: Integer;
begin
  Result := Length(FPorts);
end;

function TArdPortWatcher.GetPort(AIndex: Integer): TArdPortInfo;
begin
  Result := FPorts[AIndex];
end;

end.
