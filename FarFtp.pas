unit FarFtp;

// ---------------------------------------------------------------------------
//  FTP для unIDE FAR (пункт FTP в меню дисков Alt+F1 / Alt+F2):
//
//  - список FTP-адресов (хостов): имя или IP, порт, начальная папка,
//    пользователь, пароль, описание, «спрашивать пароль», пассивный режим.
//    Хранится в editor.ini, раздел [FarFtp]; пароль - зашифрован DPAPI
//    (CryptProtectData, ключ - учётная запись Windows): на другой учётной
//    записи или машине он не расшифруется, его придётся ввести заново;
//  - разбор адреса ftp://user:password@host:port/dir (FarFtpParseUrl);
//  - соединение и чтение папки - WinInet (wininet.dll: InternetConnect,
//    FtpSetCurrentDirectory, FtpFindFirstFile), в своём потоке
//    (TFarFtpThread): сеть может отвечать долго. Соединение (TFarFtpConn)
//    живёт, пока панель на FTP, и переиспользуется; разорвано сервером -
//    поток соединяется заново один раз;
//  - имена файлов приходят байтами сервера (функции WinInet *A): байты
//    хранятся как есть (Raw - для команд серверу), для показа - UTF-8,
//    если байты - верный UTF-8, иначе - кодировка Windows (cp1251).
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes;

type
  TFarFtpHost = record
    Host: string;            // имя или IP
    Port: Integer;           // 0 - стандартный (21)
    Home: WideString;        // начальная папка; '' - какую даст сервер
    User: WideString;        // '' - anonymous
    Password: WideString;
    Description: WideString;
    AskPassword: Boolean;    // пароль не хранить - спрашивать при входе
    Passive: Boolean;        // пассивный режим (PASV)
  end;
  TFarFtpHosts = array of TFarFtpHost;

  TFarFtpEntry = record
    Raw: string;             // имя байтами сервера
    Name: WideString;        // для показа
    IsDir: Boolean;
    Size: Int64;
    Time: TFileTime;
    Attr: DWORD;
  end;
  TFarFtpEntries = array of TFarFtpEntry;

  // Соединение WinInet: сеанс и FTP-соединение
  TFarFtpConn = class
  private
    FSession: Pointer;
    FConnect: Pointer;
  public
    destructor Destroy; override;
    // Закрыть дескрипторы (можно из другого потока - прерывает ожидание)
    procedure Close;
    function Connected: Boolean;
  end;

  // Задача потока: перейти в папку и прочитать её
  TFarFtpThread = class(TThread)
  private
    FConn: TFarFtpConn;
    FHost: TFarFtpHost;
    FDir: string;            // куда перейти (байтами); '' - начальная папка
    FEntries: TFarFtpEntries;
    FCurDir: string;         // папка сервера после перехода (байтами)
    FErrorText: string;
    FErrorCode: DWORD;       // код последней ошибки WinInet
    FFinished: Integer;
    FCancelled: Integer;
    function GetFinished: Boolean;
    function DoConnect: Boolean;
    function DoList: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AConn: TFarFtpConn; const AHost: TFarFtpHost;
      const ADir: string);
    // Прервать: закрыть соединение (WinInet вернётся с ошибкой)
    procedure Cancel;
    property Conn: TFarFtpConn read FConn;
    property Entries: TFarFtpEntries read FEntries;
    property CurDir: string read FCurDir;
    property ErrorText: string read FErrorText;
    property Finished: Boolean read GetFinished;
  end;

// Адреса: чтение и запись editor.ini ([FarFtp])
procedure FarFtpHostsLoad(const AIniName: string; var AHosts: TFarFtpHosts);
procedure FarFtpHostsSave(const AIniName: string; const AHosts: TFarFtpHosts);
procedure FarFtpHostClear(var AHost: TFarFtpHost);
// 'ftp://user:password@host:port/dir', 'host:port/dir', 'host'. В AHost -
// только части, что есть в тексте (остальные не меняются). False - нет
// имени хоста
function FarFtpParseUrl(const AText: WideString; var AHost: TFarFtpHost): Boolean;
// Адрес для заголовка: 'ftp://user@host:port'
function FarFtpHostUrl(const AHost: TFarFtpHost): WideString;
// Имя с сервера (байты) -> для показа: UTF-8 или кодировка Windows
function FarFtpDecode(const ARaw: string): WideString;
// Путь, набранный человеком, -> байты для сервера: ASCII - как есть,
// иначе UTF-8
function FarFtpEncode(const AText: WideString): string;
// Папка + имя ('/' между ними)
function FarFtpJoin(const ADir, AName: string): string;
// Папка выше; AChild - имя, из которого вышли. Корень ('/' или '') - ''
function FarFtpParent(const ADir: string; var AChild: string): string;
// Пароль <-> шестнадцатеричная строка DPAPI ('' - не вышло)
function FarFtpProtect(const AText: WideString): string;
function FarFtpUnprotect(const AHex: string): WideString;

const
  FarFtpDefaultPort = 21;

implementation

uses
  IniBuf;       // TBufIniFile - editor.ini пишется один раз

const
  FtpIniSection = 'FarFtp';
  FtpUtf8Prefix = 'utf8:';
  FtpCpUtf8 = 65001;
  FtpCpAnsi = 0;
  FtpOpenTypeDirect = 1;            // INTERNET_OPEN_TYPE_DIRECT
  FtpServiceFtp = 1;                // INTERNET_SERVICE_FTP
  FtpFlagPassive = $08000000;       // INTERNET_FLAG_PASSIVE
  FtpFlagReload = $80000000;        // INTERNET_FLAG_RELOAD
  FtpFlagNoCacheWrite = $04000000;  // INTERNET_FLAG_NO_CACHE_WRITE
  FtpOptionConnectTimeout = 2;
  FtpOptionSendTimeout = 5;
  FtpOptionReceiveTimeout = 6;
  FtpTimeoutMs = 20000;
  FtpErrorExtended = 12003;         // ERROR_INTERNET_EXTENDED_ERROR
  FtpErrorNoMoreFiles = 18;         // ERROR_NO_MORE_FILES
  FtpCryptUiForbidden = 1;          // CRYPTPROTECT_UI_FORBIDDEN

type
  // WIN32_FIND_DATAA (своё описание - одинаково во всех версиях Delphi)
  TFtpFindData = record
    dwFileAttributes: DWORD;
    ftCreationTime: TFileTime;
    ftLastAccessTime: TFileTime;
    ftLastWriteTime: TFileTime;
    nFileSizeHigh: DWORD;
    nFileSizeLow: DWORD;
    dwReserved0: DWORD;
    dwReserved1: DWORD;
    cFileName: array[0..MAX_PATH - 1] of AnsiChar;
    cAlternateFileName: array[0..13] of AnsiChar;
  end;
  TFtpDataBlob = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PFtpDataBlob = ^TFtpDataBlob;

function FtpInternetOpen(AAgent: PAnsiChar; AAccessType: DWORD;
  AProxy, AProxyBypass: PAnsiChar; AFlags: DWORD): Pointer; stdcall;
  external 'wininet.dll' name 'InternetOpenA';
function FtpInternetConnect(ASession: Pointer; AServer: PAnsiChar;
  APort: Word; AUser, APassword: PAnsiChar; AService, AFlags: DWORD;
  AContext: DWORD): Pointer; stdcall;
  external 'wininet.dll' name 'InternetConnectA';
function FtpInternetCloseHandle(AHandle: Pointer): BOOL; stdcall;
  external 'wininet.dll' name 'InternetCloseHandle';
function FtpInternetSetOption(AHandle: Pointer; AOption: DWORD;
  ABuffer: Pointer; ABufferLength: DWORD): BOOL; stdcall;
  external 'wininet.dll' name 'InternetSetOptionA';
function FtpSetCurrentDir(AConnect: Pointer; ADir: PAnsiChar): BOOL; stdcall;
  external 'wininet.dll' name 'FtpSetCurrentDirectoryA';
function FtpGetCurrentDir(AConnect: Pointer; ADir: PAnsiChar;
  var ALength: DWORD): BOOL; stdcall;
  external 'wininet.dll' name 'FtpGetCurrentDirectoryA';
function FtpFindFirst(AConnect: Pointer; ASearch: PAnsiChar;
  var AFindData: TFtpFindData; AFlags: DWORD; AContext: DWORD): Pointer;
  stdcall; external 'wininet.dll' name 'FtpFindFirstFileA';
function FtpFindNext(AFind: Pointer; var AFindData: TFtpFindData): BOOL;
  stdcall; external 'wininet.dll' name 'InternetFindNextFileA';
function FtpLastResponse(var AError: DWORD; ABuffer: PAnsiChar;
  var ALength: DWORD): BOOL; stdcall;
  external 'wininet.dll' name 'InternetGetLastResponseInfoA';
function FtpMultiToWide(ACodePage: UINT; AFlags: DWORD; AMulti: PAnsiChar;
  AMultiLen: Integer; AWide: PWideChar; AWideLen: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'MultiByteToWideChar';
function FtpWideToMulti(ACodePage: UINT; AFlags: DWORD; AWide: PWideChar;
  AWideLen: Integer; AMulti: PAnsiChar; AMultiLen: Integer;
  ADefault: PAnsiChar; AUsedDefault: Pointer): Integer; stdcall;
  external 'kernel32.dll' name 'WideCharToMultiByte';
function FtpCryptProtect(ADataIn: PFtpDataBlob; ADescr: PWideChar;
  AEntropy: PFtpDataBlob; AReserved, APrompt: Pointer; AFlags: DWORD;
  ADataOut: PFtpDataBlob): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptProtectData';
function FtpCryptUnprotect(ADataIn: PFtpDataBlob; ADescr: Pointer;
  AEntropy: PFtpDataBlob; AReserved, APrompt: Pointer; AFlags: DWORD;
  ADataOut: PFtpDataBlob): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptUnprotectData';
function FtpLocalFree(AMem: Pointer): Pointer; stdcall;
  external 'kernel32.dll' name 'LocalFree';

// ---------------------------------------------------------------------------
//  Кодировки
// ---------------------------------------------------------------------------

function FtpMultiToWideStr(ACodePage: UINT; const AText: string): WideString;
var
  WideLen: Integer;
begin
  Result := '';
  if AText = '' then
    Exit;
  WideLen := FtpMultiToWide(ACodePage, 0, PAnsiChar(AText), Length(AText),
    nil, 0);
  if WideLen <= 0 then
    Exit;
  SetLength(Result, WideLen);
  FtpMultiToWide(ACodePage, 0, PAnsiChar(AText), Length(AText),
    PWideChar(Result), WideLen);
end;

function FtpWideToMultiStr(ACodePage: UINT; const AText: WideString): string;
var
  MultiLen: Integer;
begin
  Result := '';
  if AText = '' then
    Exit;
  MultiLen := FtpWideToMulti(ACodePage, 0, PWideChar(AText), Length(AText),
    nil, 0, nil, nil);
  if MultiLen <= 0 then
    Exit;
  SetLength(Result, MultiLen);
  FtpWideToMulti(ACodePage, 0, PWideChar(AText), Length(AText),
    PAnsiChar(Result), MultiLen, nil, nil);
end;

// Есть ли байты > 127 и все ли последовательности - верный UTF-8
function FtpIsUtf8(const ARaw: string; var AHasHigh: Boolean): Boolean;
var
  BytePos, TailCount, TailIdx: Integer;
  ByteValue: Byte;
begin
  Result := True;
  AHasHigh := False;
  BytePos := 1;
  while BytePos <= Length(ARaw) do
  begin
    ByteValue := Ord(ARaw[BytePos]);
    if ByteValue < $80 then
    begin
      Inc(BytePos);
      Continue;
    end;
    AHasHigh := True;
    if (ByteValue >= $C2) and (ByteValue <= $DF) then
      TailCount := 1
    else if (ByteValue >= $E0) and (ByteValue <= $EF) then
      TailCount := 2
    else if (ByteValue >= $F0) and (ByteValue <= $F4) then
      TailCount := 3
    else
    begin
      Result := False;
      Exit;
    end;
    if BytePos + TailCount > Length(ARaw) then
    begin
      Result := False;
      Exit;
    end;
    for TailIdx := 1 to TailCount do
      if (Ord(ARaw[BytePos + TailIdx]) and $C0) <> $80 then
      begin
        Result := False;
        Exit;
      end;
    Inc(BytePos, TailCount + 1);
  end;
end;

function FarFtpDecode(const ARaw: string): WideString;
var
  HasHigh: Boolean;
begin
  if FtpIsUtf8(ARaw, HasHigh) and HasHigh then
    Result := FtpMultiToWideStr(FtpCpUtf8, ARaw)
  else
    Result := FtpMultiToWideStr(FtpCpAnsi, ARaw);
end;

function FarFtpEncode(const AText: WideString): string;
var
  CharIdx: Integer;
  IsAscii: Boolean;
begin
  IsAscii := True;
  for CharIdx := 1 to Length(AText) do
    if Ord(AText[CharIdx]) > 127 then
    begin
      IsAscii := False;
      Break;
    end;
  if IsAscii then
    Result := string(AText)
  else
    Result := FtpWideToMultiStr(FtpCpUtf8, AText);
end;

// Строка для editor.ini: ASCII - как есть, иначе 'utf8:' + UTF-8
function FtpIniEncode(const AText: WideString): string;
var
  CharIdx: Integer;
begin
  for CharIdx := 1 to Length(AText) do
    if Ord(AText[CharIdx]) > 127 then
    begin
      Result := FtpUtf8Prefix + FtpWideToMultiStr(FtpCpUtf8, AText);
      Exit;
    end;
  Result := string(AText);
end;

function FtpIniDecode(const AText: string): WideString;
begin
  if Copy(AText, 1, Length(FtpUtf8Prefix)) = FtpUtf8Prefix then
    Result := FtpMultiToWideStr(FtpCpUtf8, Copy(AText,
      Length(FtpUtf8Prefix) + 1, MaxInt))
  else
    Result := FtpMultiToWideStr(FtpCpAnsi, AText);
end;

// ---------------------------------------------------------------------------
//  Пароль: DPAPI
// ---------------------------------------------------------------------------

function FarFtpProtect(const AText: WideString): string;
var
  DataIn, DataOut: TFtpDataBlob;
  Plain: string;
  ByteIdx: Integer;
  OutBytes: PByteArray;
begin
  Result := '';
  if AText = '' then
    Exit;
  Plain := FtpWideToMultiStr(FtpCpUtf8, AText);
  DataIn.cbData := Length(Plain);
  DataIn.pbData := PByte(PAnsiChar(Plain));
  DataOut.cbData := 0;
  DataOut.pbData := nil;
  if not FtpCryptProtect(@DataIn, nil, nil, nil, nil, FtpCryptUiForbidden,
     @DataOut) then
    Exit;
  try
    OutBytes := PByteArray(DataOut.pbData);
    for ByteIdx := 0 to Integer(DataOut.cbData) - 1 do
      Result := Result + IntToHex(OutBytes^[ByteIdx], 2);
  finally
    FtpLocalFree(DataOut.pbData);
  end;
end;

function FarFtpUnprotect(const AHex: string): WideString;
var
  DataIn, DataOut: TFtpDataBlob;
  Blob, Plain: string;
  ByteIdx, ByteValue: Integer;
begin
  Result := '';
  if (AHex = '') or (Length(AHex) mod 2 <> 0) then
    Exit;
  SetLength(Blob, Length(AHex) div 2);
  for ByteIdx := 1 to Length(Blob) do
  begin
    ByteValue := StrToIntDef('$' + Copy(AHex, ByteIdx * 2 - 1, 2), -1);
    if ByteValue < 0 then
      Exit;
    Blob[ByteIdx] := Chr(ByteValue);
  end;
  DataIn.cbData := Length(Blob);
  DataIn.pbData := PByte(PAnsiChar(Blob));
  DataOut.cbData := 0;
  DataOut.pbData := nil;
  if not FtpCryptUnprotect(@DataIn, nil, nil, nil, nil, FtpCryptUiForbidden,
     @DataOut) then
    Exit;
  try
    SetString(Plain, PAnsiChar(DataOut.pbData), DataOut.cbData);
    Result := FtpMultiToWideStr(FtpCpUtf8, Plain);
  finally
    FtpLocalFree(DataOut.pbData);
  end;
end;

// ---------------------------------------------------------------------------
//  Адреса
// ---------------------------------------------------------------------------

procedure FarFtpHostClear(var AHost: TFarFtpHost);
begin
  AHost.Host := '';
  AHost.Port := 0;
  AHost.Home := '';
  AHost.User := '';
  AHost.Password := '';
  AHost.Description := '';
  AHost.AskPassword := False;
  AHost.Passive := True;
end;

procedure FarFtpHostsLoad(const AIniName: string; var AHosts: TFarFtpHosts);
var
  Ini: TBufIniFile;
  HostCount, HostIdx, Flags: Integer;
  Key: string;
  Host: TFarFtpHost;
begin
  SetLength(AHosts, 0);
  if (AIniName = '') or not FileExists(AIniName) then
    Exit;
  Ini := TBufIniFile.Create(AIniName);
  try
    HostCount := StrToIntDef(Ini.ReadString(FtpIniSection, 'Count', '0'), 0);
    for HostIdx := 1 to HostCount do
    begin
      Key := IntToStr(HostIdx);
      FarFtpHostClear(Host);
      Host.Host := Trim(Ini.ReadString(FtpIniSection, 'Host' + Key, ''));
      if Host.Host = '' then
        Continue;
      Host.Port := StrToIntDef(Ini.ReadString(FtpIniSection, 'Port' + Key,
        '0'), 0);
      Host.Home := FtpIniDecode(Ini.ReadString(FtpIniSection, 'Home' + Key,
        ''));
      Host.User := FtpIniDecode(Ini.ReadString(FtpIniSection, 'User' + Key,
        ''));
      Host.Password := FarFtpUnprotect(Ini.ReadString(FtpIniSection,
        'Pass' + Key, ''));
      Host.Description := FtpIniDecode(Ini.ReadString(FtpIniSection,
        'Descr' + Key, ''));
      Flags := StrToIntDef(Ini.ReadString(FtpIniSection, 'Flags' + Key, '2'),
        2);
      Host.AskPassword := (Flags and 1) <> 0;
      Host.Passive := (Flags and 2) <> 0;
      SetLength(AHosts, Length(AHosts) + 1);
      AHosts[High(AHosts)] := Host;
    end;
  finally
    Ini.Free;
  end;
end;

procedure FarFtpHostsSave(const AIniName: string; const AHosts: TFarFtpHosts);
var
  Ini: TBufIniFile;
  HostIdx, Flags: Integer;
  Key: string;
begin
  if AIniName = '' then
    Exit;
  Ini := TBufIniFile.Create(AIniName);
  try
    Ini.EraseSection(FtpIniSection);
    Ini.WriteString(FtpIniSection, 'Count', IntToStr(Length(AHosts)));
    for HostIdx := 0 to High(AHosts) do
    begin
      Key := IntToStr(HostIdx + 1);
      Flags := 0;
      if AHosts[HostIdx].AskPassword then
        Flags := Flags or 1;
      if AHosts[HostIdx].Passive then
        Flags := Flags or 2;
      Ini.WriteString(FtpIniSection, 'Host' + Key, AHosts[HostIdx].Host);
      Ini.WriteString(FtpIniSection, 'Port' + Key,
        IntToStr(AHosts[HostIdx].Port));
      Ini.WriteString(FtpIniSection, 'Home' + Key,
        FtpIniEncode(AHosts[HostIdx].Home));
      Ini.WriteString(FtpIniSection, 'User' + Key,
        FtpIniEncode(AHosts[HostIdx].User));
      // «Спрашивать пароль» - пароль не хранится
      if AHosts[HostIdx].AskPassword then
        Ini.WriteString(FtpIniSection, 'Pass' + Key, '')
      else
        Ini.WriteString(FtpIniSection, 'Pass' + Key,
          FarFtpProtect(AHosts[HostIdx].Password));
      Ini.WriteString(FtpIniSection, 'Descr' + Key,
        FtpIniEncode(AHosts[HostIdx].Description));
      Ini.WriteString(FtpIniSection, 'Flags' + Key, IntToStr(Flags));
    end;
  finally
    Ini.Free;
  end;
end;

function FarFtpParseUrl(const AText: WideString; var AHost: TFarFtpHost): Boolean;
var
  Rest, Auth, HostPart, PortText: WideString;
  SepPos, CharIdx: Integer;
begin
  Result := False;
  Rest := AText;
  // Пробелы по краям
  while (Rest <> '') and (Rest[1] = ' ') do
    Delete(Rest, 1, 1);
  while (Rest <> '') and (Rest[Length(Rest)] = ' ') do
    SetLength(Rest, Length(Rest) - 1);
  if WideLowerCase(Copy(Rest, 1, 6)) = 'ftp://' then
    Delete(Rest, 1, 6);
  if Rest = '' then
    Exit;
  // Папка - с первой '/'
  SepPos := 0;
  for CharIdx := 1 to Length(Rest) do
    if Rest[CharIdx] = '/' then
    begin
      SepPos := CharIdx;
      Break;
    end;
  if SepPos > 0 then
  begin
    AHost.Home := Copy(Rest, SepPos, MaxInt);
    Rest := Copy(Rest, 1, SepPos - 1);
  end;
  // user:password@ - до последней '@' (в пароле '@' бывает)
  SepPos := 0;
  for CharIdx := Length(Rest) downto 1 do
    if Rest[CharIdx] = '@' then
    begin
      SepPos := CharIdx;
      Break;
    end;
  if SepPos > 0 then
  begin
    Auth := Copy(Rest, 1, SepPos - 1);
    HostPart := Copy(Rest, SepPos + 1, MaxInt);
    SepPos := 0;
    for CharIdx := 1 to Length(Auth) do
      if Auth[CharIdx] = ':' then
      begin
        SepPos := CharIdx;
        Break;
      end;
    if SepPos > 0 then
    begin
      AHost.User := Copy(Auth, 1, SepPos - 1);
      AHost.Password := Copy(Auth, SepPos + 1, MaxInt);
    end
    else
      AHost.User := Auth;
  end
  else
    HostPart := Rest;
  // host:port
  SepPos := 0;
  for CharIdx := Length(HostPart) downto 1 do
    if HostPart[CharIdx] = ':' then
    begin
      SepPos := CharIdx;
      Break;
    end;
  if SepPos > 0 then
  begin
    PortText := Copy(HostPart, SepPos + 1, MaxInt);
    HostPart := Copy(HostPart, 1, SepPos - 1);
    AHost.Port := StrToIntDef(string(PortText), 0);
  end;
  if HostPart = '' then
    Exit;
  AHost.Host := string(HostPart);
  Result := True;
end;

function FarFtpHostUrl(const AHost: TFarFtpHost): WideString;
begin
  Result := 'ftp://';
  if AHost.User <> '' then
    Result := Result + AHost.User + '@';
  Result := Result + WideString(AHost.Host);
  if (AHost.Port > 0) and (AHost.Port <> FarFtpDefaultPort) then
    Result := Result + ':' + WideString(IntToStr(AHost.Port));
end;

function FarFtpJoin(const ADir, AName: string): string;
begin
  if (ADir = '') or (ADir[Length(ADir)] = '/') then
    Result := ADir + AName
  else
    Result := ADir + '/' + AName;
end;

function FarFtpParent(const ADir: string; var AChild: string): string;
var
  Dir: string;
  SepPos: Integer;
begin
  Result := '';
  AChild := '';
  Dir := ADir;
  while (Length(Dir) > 1) and (Dir[Length(Dir)] = '/') do
    SetLength(Dir, Length(Dir) - 1);
  if (Dir = '') or (Dir = '/') then
    Exit;
  SepPos := Length(Dir);
  while (SepPos > 0) and (Dir[SepPos] <> '/') do
    Dec(SepPos);
  AChild := Copy(Dir, SepPos + 1, MaxInt);
  if SepPos <= 1 then
    Result := '/'
  else
    Result := Copy(Dir, 1, SepPos - 1);
end;

// ---------------------------------------------------------------------------
//  Соединение и поток
// ---------------------------------------------------------------------------

destructor TFarFtpConn.Destroy;
begin
  Close;
  inherited Destroy;
end;

procedure TFarFtpConn.Close;
var
  Handle: Pointer;
begin
  Handle := FConnect;
  FConnect := nil;
  if Handle <> nil then
    FtpInternetCloseHandle(Handle);
  Handle := FSession;
  FSession := nil;
  if Handle <> nil then
    FtpInternetCloseHandle(Handle);
end;

function TFarFtpConn.Connected: Boolean;
begin
  Result := FConnect <> nil;
end;

// Текст последней ошибки WinInet: ответ сервера или сообщение Windows
function FtpErrorText(ACode: DWORD): string;
var
  Buffer: array[0..2047] of AnsiChar;
  BufLen, ServerError: DWORD;
  MsgLen: DWORD;
begin
  Result := '';
  if ACode = FtpErrorExtended then
  begin
    BufLen := SizeOf(Buffer) - 1;
    ServerError := 0;
    FillChar(Buffer, SizeOf(Buffer), 0);
    if FtpLastResponse(ServerError, @Buffer[0], BufLen) and (BufLen > 0) then
    begin
      SetString(Result, PAnsiChar(@Buffer[0]), BufLen);
      Result := Trim(StringReplace(StringReplace(Result, #13, ' ',
        [rfReplaceAll]), #10, ' ', [rfReplaceAll]));
      Exit;
    end;
  end;
  MsgLen := FormatMessage(FORMAT_MESSAGE_FROM_HMODULE or
    FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS,
    Pointer(GetModuleHandle('wininet.dll')), ACode, 0, @Buffer[0],
    SizeOf(Buffer), nil);
  if MsgLen = 0 then
    Result := 'ошибка ' + IntToStr(ACode)
  else
  begin
    SetString(Result, PAnsiChar(@Buffer[0]), MsgLen);
    Result := Trim(Result) + ' (' + IntToStr(ACode) + ')';
  end;
end;

constructor TFarFtpThread.Create(AConn: TFarFtpConn; const AHost: TFarFtpHost;
  const ADir: string);
begin
  FConn := AConn;
  FHost := AHost;
  FDir := ADir;
  FEntries := nil;
  FCurDir := '';
  FErrorText := '';
  FErrorCode := 0;
  FFinished := 0;
  FCancelled := 0;
  FreeOnTerminate := False;
  inherited Create(False);
end;

function TFarFtpThread.GetFinished: Boolean;
begin
  Result := FFinished <> 0;
end;

procedure TFarFtpThread.Cancel;
begin
  InterlockedExchange(FCancelled, 1);
  FConn.Close;
end;

function TFarFtpThread.DoConnect: Boolean;
var
  Timeout: DWORD;
  User, Password: string;
  Port: Word;
  Flags: DWORD;
begin
  Result := False;
  FConn.Close;
  FConn.FSession := FtpInternetOpen('unIDE FAR', FtpOpenTypeDirect, nil, nil,
    0);
  if FConn.FSession = nil then
  begin
    FErrorText := FtpErrorText(GetLastError);
    Exit;
  end;
  Timeout := FtpTimeoutMs;
  FtpInternetSetOption(FConn.FSession, FtpOptionConnectTimeout, @Timeout,
    SizeOf(Timeout));
  FtpInternetSetOption(FConn.FSession, FtpOptionSendTimeout, @Timeout,
    SizeOf(Timeout));
  FtpInternetSetOption(FConn.FSession, FtpOptionReceiveTimeout, @Timeout,
    SizeOf(Timeout));
  if FHost.User = '' then
  begin
    User := 'anonymous';
    Password := 'unide@';
  end
  else
  begin
    User := FtpWideToMultiStr(FtpCpAnsi, FHost.User);
    Password := FtpWideToMultiStr(FtpCpAnsi, FHost.Password);
  end;
  if FHost.Port > 0 then
    Port := FHost.Port
  else
    Port := FarFtpDefaultPort;
  Flags := 0;
  if FHost.Passive then
    Flags := FtpFlagPassive;
  FConn.FConnect := FtpInternetConnect(FConn.FSession, PAnsiChar(FHost.Host),
    Port, PAnsiChar(User), PAnsiChar(Password), FtpServiceFtp, Flags, 0);
  if FConn.FConnect = nil then
  begin
    FErrorText := FtpErrorText(GetLastError);
    FConn.Close;
    Exit;
  end;
  Result := True;
end;

function TFarFtpThread.DoList: Boolean;
var
  FindHandle: Pointer;
  FindData: TFtpFindData;
  DirBuffer: array[0..1023] of AnsiChar;
  DirLen, ErrorCode: DWORD;
  Entry: TFarFtpEntry;
  Count: Integer;
begin
  Result := False;
  FEntries := nil;
  FErrorCode := 0;
  if FDir <> '' then
    if not FtpSetCurrentDir(FConn.FConnect, PAnsiChar(FDir)) then
    begin
      FErrorCode := GetLastError;
      FErrorText := FtpErrorText(FErrorCode);
      Exit;
    end;
  DirLen := SizeOf(DirBuffer) - 1;
  FillChar(DirBuffer, SizeOf(DirBuffer), 0);
  if FtpGetCurrentDir(FConn.FConnect, @DirBuffer[0], DirLen) then
    FCurDir := PAnsiChar(@DirBuffer[0])
  else
    FCurDir := FDir;
  FillChar(FindData, SizeOf(FindData), 0);
  FindHandle := FtpFindFirst(FConn.FConnect, nil, FindData,
    FtpFlagReload or FtpFlagNoCacheWrite, 0);
  if FindHandle = nil then
  begin
    ErrorCode := GetLastError;
    // Пустая папка
    if ErrorCode = FtpErrorNoMoreFiles then
    begin
      Result := True;
      Exit;
    end;
    FErrorCode := ErrorCode;
    FErrorText := FtpErrorText(ErrorCode);
    Exit;
  end;
  Count := 0;
  try
    repeat
      Entry.Raw := PAnsiChar(@FindData.cFileName[0]);
      if (Entry.Raw <> '') and (Entry.Raw <> '.') and (Entry.Raw <> '..') then
      begin
        Entry.Name := FarFtpDecode(Entry.Raw);
        Entry.Attr := FindData.dwFileAttributes;
        Entry.IsDir := (FindData.dwFileAttributes and
          FILE_ATTRIBUTE_DIRECTORY) <> 0;
        Entry.Size := Int64(FindData.nFileSizeHigh) shl 32 or
          FindData.nFileSizeLow;
        Entry.Time := FindData.ftLastWriteTime;
        SetLength(FEntries, Count + 1);
        FEntries[Count] := Entry;
        Inc(Count);
      end;
      FillChar(FindData, SizeOf(FindData), 0);
    until (FCancelled <> 0) or not FtpFindNext(FindHandle, FindData);
  finally
    FtpInternetCloseHandle(FindHandle);
  end;
  Result := FCancelled = 0;
end;

procedure TFarFtpThread.Execute;
var
  WasConnected: Boolean;
begin
  try
    WasConnected := FConn.Connected;
    if not WasConnected then
      if not DoConnect then
        Exit;
    // Ответ сервера (550 и т.п.) - ошибка как есть; разрыв соединения
    // (сервер закрыл его за время простоя) - соединиться ещё раз
    if not DoList and WasConnected and (FCancelled = 0) and
       (FErrorCode <> FtpErrorExtended) then
    begin
      FErrorText := '';
      if DoConnect then
        DoList;
    end;
    if FCancelled <> 0 then
      FErrorText := 'прервано';
  finally
    InterlockedExchange(FFinished, 1);
  end;
end;

end.
