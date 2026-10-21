unit SzSetup;

// ---------------------------------------------------------------------------
//  unIDE FAR: загрузка 7-Zip в tools\7zip, когда его там нет
//
//  - какую сборку брать - по Windows: x64 на 64-битной Windows (XP x64 и
//    новее), x86 - на 32-битной (2000 и новее) и на ARM64; 9x и NT 4 -
//    7-Zip 26.04 не поддерживает (заявлено: Windows 2000 - 11);
//  - качается 7zr.exe (маленький 7-Zip только для формата 7z) и установщик
//    7-Zip; установщик - архив 7z, из него 7zr.exe достаёт 7z.exe и 7z.dll
//    (это делает UnFar, процессом). Сам установщик не запускается: ничего
//    не регистрируется в системе;
//  - загрузка - WinINet (настройки прокси и TLS - как у Internet Explorer)
//    в своём потоке, с ходом и отменой; каждый файл проверяется по размеру
//    и SHA-256, записанным здесь (версия закреплена; новая - новые размеры
//    и суммы в SzPackages / SzTool).
// ---------------------------------------------------------------------------

{$Q-}
{$R-}

interface

uses
  Windows, SysUtils, Classes;

type
  // Сведения о Windows для выбора сборки 7-Zip
  TSzOsInfo = record
    Major, Minor, Build: Integer;
    IsNT: Boolean;
    Is64: Boolean;       // 64-битная Windows x64 (на ARM64 - False)
    IsArm64: Boolean;
    Name: string;        // 'Windows 7 (64-bit)'
  end;

  // Файл для загрузки: адреса по порядку (первый не вышел - следующий),
  // размер и SHA-256 (строчными буквами)
  TSzFile = record
    Url1, Url2: string;
    FileName: WideString;   // куда записать
    Size: Integer;
    Sha256: string;
  end;
  TSzFiles = array of TSzFile;

  // Сборка 7-Zip
  TSzPackage = record
    Version: string;
    Arch: string;          // 'x86' / 'x64'
    Need64: Boolean;       // только для 64-битной Windows
    MinMajor, MinMinor: Integer;
    FileName: string;      // имя установщика
    Size: Integer;
    Sha256: string;
    Url1, Url2: string;
  end;

  // Загрузка списка файлов в своём потоке. Ход - FileIndex, Done, Total
  // (читает главный поток по таймеру); конец - Finished, ошибка - ErrorText
  TSzDownload = class(TThread)
  private
    FFiles: TSzFiles;
    FSession: Pointer;
    FLock: TRTLCriticalSection;
    FCancelled: Boolean;
    FFileIndex: Integer;
    FDone: Integer;
    FTotal: Integer;
    FFinished: Integer;
    FErrorText: string;
    function GetFile(const AFile: TSzFile; const AUrl: string;
      var AError: string): Boolean;
    function GetFinished: Boolean;
    function TakeSession: Pointer;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFiles: TSzFiles);
    destructor Destroy; override;
    procedure Cancel;
    property FileIndex: Integer read FFileIndex;
    property Done: Integer read FDone;
    property Total: Integer read FTotal;
    property Finished: Boolean read GetFinished;
    property Cancelled: Boolean read FCancelled;
    property ErrorText: string read FErrorText;
  end;

const
  SzToolName = '7zr.exe';
  SzDownloadPage = 'https://www.7-zip.org/download.html';

procedure SzGetOsInfo(var AInfo: TSzOsInfo);
// Сборка для этой Windows; False - 7-Zip для неё нет
function SzChoosePackage(const AOs: TSzOsInfo;
  var APackage: TSzPackage): Boolean;
// 7zr.exe той же версии
procedure SzToolFile(var AFile: TSzFile);
// SHA-256 файла (строчными буквами); '' - не прочитать
function SzFileSha256(const AFileName: WideString): string;

implementation

// ---------------------------------------------------------------------------
//  Версия 7-Zip: 26.04 (2026-10-05). Источники - официальные: релизы
//  github.com/ip7z/7zip (на них ведёт www.7-zip.org/download.html) и
//  проект sevenzip на SourceForge (запасной). Размеры и SHA-256 сняты с
//  файлов обоих адресов 21.10.2026 - совпали
// ---------------------------------------------------------------------------

const
  SzPackageCount = 2;
  SzPackages: array[0..SzPackageCount - 1] of TSzPackage = (
    (Version: '26.04'; Arch: 'x64'; Need64: True; MinMajor: 5; MinMinor: 2;
     FileName: '7z2604-x64.exe'; Size: 1664082;
     Sha256: 'd54bf805f9f3704d1e8db2fa3498ae7ef2df0312b40b558e7c71c734430a665d';
     Url1: 'https://github.com/ip7z/7zip/releases/download/26.04/7z2604-x64.exe';
     Url2: 'https://downloads.sourceforge.net/project/sevenzip/7-Zip/26.04/7z2604-x64.exe'),
    (Version: '26.04'; Arch: 'x86'; Need64: False; MinMajor: 5; MinMinor: 0;
     FileName: '7z2604.exe'; Size: 1361691;
     Sha256: '39bf65045153fc26c42fa9fe47afd8cd1b11671c7f11d031e738c9a13960c009';
     Url1: 'https://github.com/ip7z/7zip/releases/download/26.04/7z2604.exe';
     Url2: 'https://downloads.sourceforge.net/project/sevenzip/7-Zip/26.04/7z2604.exe'));

  SzToolSize = 602624;
  SzToolSha256 =
    '256feca8e274e5da655e2a284fabafd9f554365eb164862089dacd4e8276d282';
  SzToolUrl1 = 'https://github.com/ip7z/7zip/releases/download/26.04/7zr.exe';
  SzToolUrl2 =
    'https://downloads.sourceforge.net/project/sevenzip/7-Zip/26.04/7zr.exe';

// ---------------------------------------------------------------------------
//  Функции Windows (W-версии и то, чего нет в Windows.pas Delphi 7)
// ---------------------------------------------------------------------------

const
  SzInternetOpenPreconfig = 0;
  SzFlagReload = $80000000;
  SzFlagNoCacheWrite = $04000000;
  SzFlagPragmaNoCache = $00000100;
  SzFlagNoUi = $00000200;
  SzFlagNoCookies = $00080000;
  SzOptionConnectTimeout = 2;
  SzOptionReceiveTimeout = 6;
  SzQueryStatusCode = 19;
  SzQueryFlagNumber = $20000000;
  SzFormatFromHModule = $00000800;
  SzFormatFromSystem = $00001000;
  SzFormatIgnoreInserts = $00000200;
  SzGenericRead = $80000000;
  SzGenericWrite = $40000000;
  SzFileShareRead = 1;
  SzCreateAlways = 2;
  SzOpenExisting = 3;
  SzFileAttrNormal = $80;
  SzMachineAmd64 = $8664;
  SzMachineArm64 = $AA64;

type
  TSzOsVersionW = record
    dwOSVersionInfoSize: DWORD;
    dwMajorVersion: DWORD;
    dwMinorVersion: DWORD;
    dwBuildNumber: DWORD;
    dwPlatformId: DWORD;
    szCSDVersion: array[0..127] of WideChar;
  end;
  TSzRtlGetVersion = function(var AInfo: TSzOsVersionW): LongInt; stdcall;
  TSzIsWow64Process = function(AProcess: THandle;
    var AWow64: BOOL): BOOL; stdcall;
  TSzIsWow64Process2 = function(AProcess: THandle; var AProcessMachine,
    ANativeMachine: Word): BOOL; stdcall;

function SzInternetOpen(AAgent: PWideChar; AAccessType: DWORD;
  AProxy, AProxyBypass: PWideChar; AFlags: DWORD): Pointer; stdcall;
  external 'wininet.dll' name 'InternetOpenW';
function SzInternetOpenUrl(ASession: Pointer; AUrl: PWideChar;
  AHeaders: PWideChar; AHeadersLength: DWORD; AFlags: DWORD;
  AContext: DWORD): Pointer; stdcall;
  external 'wininet.dll' name 'InternetOpenUrlW';
function SzInternetReadFile(AFile: Pointer; ABuffer: Pointer;
  AToRead: DWORD; var ARead: DWORD): BOOL; stdcall;
  external 'wininet.dll' name 'InternetReadFile';
function SzInternetCloseHandle(AHandle: Pointer): BOOL; stdcall;
  external 'wininet.dll' name 'InternetCloseHandle';
function SzInternetSetOption(AHandle: Pointer; AOption: DWORD;
  ABuffer: Pointer; ABufferLength: DWORD): BOOL; stdcall;
  external 'wininet.dll' name 'InternetSetOptionW';
function SzHttpQueryInfo(ARequest: Pointer; AInfoLevel: DWORD;
  ABuffer: Pointer; var ABufferLength: DWORD; var AIndex: DWORD): BOOL;
  stdcall; external 'wininet.dll' name 'HttpQueryInfoW';
function SzCreateFile(AFileName: PWideChar; AAccess, AShareMode: DWORD;
  ASecurity: Pointer; ACreation, AFlags: DWORD;
  ATemplate: THandle): THandle; stdcall;
  external 'kernel32.dll' name 'CreateFileW';
function SzWriteFile(AFile: THandle; const ABuffer; ACount: DWORD;
  var AWritten: DWORD; AOverlapped: Pointer): BOOL; stdcall;
  external 'kernel32.dll' name 'WriteFile';
function SzReadFile(AFile: THandle; var ABuffer; ACount: DWORD;
  var ARead: DWORD; AOverlapped: Pointer): BOOL; stdcall;
  external 'kernel32.dll' name 'ReadFile';
function SzDeleteFile(AFileName: PWideChar): BOOL; stdcall;
  external 'kernel32.dll' name 'DeleteFileW';
function SzFormatMessage(AFlags: DWORD; ASource: Pointer; AMessageId: DWORD;
  ALanguageId: DWORD; ABuffer: PChar; ASize: DWORD;
  AArguments: Pointer): DWORD; stdcall;
  external 'kernel32.dll' name 'FormatMessageA';

// ---------------------------------------------------------------------------
//  SHA-256 (FIPS 180-4) - своя, без CryptoAPI: в Windows 2000 и XP до SP3
//  SHA-256 в CryptoAPI нет
// ---------------------------------------------------------------------------

type
  TSzSha256 = record
    State: array[0..7] of LongWord;
    Buffer: array[0..63] of Byte;
    BufferLen: Integer;
    TotalLen: Int64;
  end;

const
  SzShaK: array[0..63] of LongWord = (
    $428a2f98, $71374491, $b5c0fbcf, $e9b5dba5, $3956c25b, $59f111f1,
    $923f82a4, $ab1c5ed5, $d807aa98, $12835b01, $243185be, $550c7dc3,
    $72be5d74, $80deb1fe, $9bdc06a7, $c19bf174, $e49b69c1, $efbe4786,
    $0fc19dc6, $240ca1cc, $2de92c6f, $4a7484aa, $5cb0a9dc, $76f988da,
    $983e5152, $a831c66d, $b00327c8, $bf597fc7, $c6e00bf3, $d5a79147,
    $06ca6351, $14292967, $27b70a85, $2e1b2138, $4d2c6dfc, $53380d13,
    $650a7354, $766a0abb, $81c2c92e, $92722c85, $a2bfe8a1, $a81a664b,
    $c24b8b70, $c76c51a3, $d192e819, $d6990624, $f40e3585, $106aa070,
    $19a4c116, $1e376c08, $2748774c, $34b0bcb5, $391c0cb3, $4ed8aa4a,
    $5b9cca4f, $682e6ff3, $748f82ee, $78a5636f, $84c87814, $8cc70208,
    $90befffa, $a4506ceb, $bef9a3f7, $c67178f2);

function SzRor(AValue: LongWord; ACount: Integer): LongWord;
begin
  Result := (AValue shr ACount) or (AValue shl (32 - ACount));
end;

procedure SzShaInit(var ACtx: TSzSha256);
begin
  ACtx.State[0] := $6a09e667;
  ACtx.State[1] := $bb67ae85;
  ACtx.State[2] := $3c6ef372;
  ACtx.State[3] := $a54ff53a;
  ACtx.State[4] := $510e527f;
  ACtx.State[5] := $9b05688c;
  ACtx.State[6] := $1f83d9ab;
  ACtx.State[7] := $5be0cd19;
  ACtx.BufferLen := 0;
  ACtx.TotalLen := 0;
end;

procedure SzShaBlock(var ACtx: TSzSha256; const ABlock: array of Byte);
var
  Words: array[0..63] of LongWord;
  ValA, ValB, ValC, ValD, ValE, ValF, ValG, ValH: LongWord;
  Sum0, Sum1, Choice, Major, Temp1, Temp2, Sig0, Sig1: LongWord;
  Round: Integer;
begin
  for Round := 0 to 15 do
    Words[Round] := (LongWord(ABlock[Round * 4]) shl 24) or
      (LongWord(ABlock[Round * 4 + 1]) shl 16) or
      (LongWord(ABlock[Round * 4 + 2]) shl 8) or
      LongWord(ABlock[Round * 4 + 3]);
  for Round := 16 to 63 do
  begin
    Sig0 := SzRor(Words[Round - 15], 7) xor SzRor(Words[Round - 15], 18) xor
      (Words[Round - 15] shr 3);
    Sig1 := SzRor(Words[Round - 2], 17) xor SzRor(Words[Round - 2], 19) xor
      (Words[Round - 2] shr 10);
    Words[Round] := Words[Round - 16] + Sig0 + Words[Round - 7] + Sig1;
  end;
  ValA := ACtx.State[0];
  ValB := ACtx.State[1];
  ValC := ACtx.State[2];
  ValD := ACtx.State[3];
  ValE := ACtx.State[4];
  ValF := ACtx.State[5];
  ValG := ACtx.State[6];
  ValH := ACtx.State[7];
  for Round := 0 to 63 do
  begin
    Sum1 := SzRor(ValE, 6) xor SzRor(ValE, 11) xor SzRor(ValE, 25);
    Choice := (ValE and ValF) xor ((not ValE) and ValG);
    Temp1 := ValH + Sum1 + Choice + SzShaK[Round] + Words[Round];
    Sum0 := SzRor(ValA, 2) xor SzRor(ValA, 13) xor SzRor(ValA, 22);
    Major := (ValA and ValB) xor (ValA and ValC) xor (ValB and ValC);
    Temp2 := Sum0 + Major;
    ValH := ValG;
    ValG := ValF;
    ValF := ValE;
    ValE := ValD + Temp1;
    ValD := ValC;
    ValC := ValB;
    ValB := ValA;
    ValA := Temp1 + Temp2;
  end;
  ACtx.State[0] := ACtx.State[0] + ValA;
  ACtx.State[1] := ACtx.State[1] + ValB;
  ACtx.State[2] := ACtx.State[2] + ValC;
  ACtx.State[3] := ACtx.State[3] + ValD;
  ACtx.State[4] := ACtx.State[4] + ValE;
  ACtx.State[5] := ACtx.State[5] + ValF;
  ACtx.State[6] := ACtx.State[6] + ValG;
  ACtx.State[7] := ACtx.State[7] + ValH;
end;

procedure SzShaUpdate(var ACtx: TSzSha256; AData: PByte; ALength: Integer);
var
  Chunk: Integer;
begin
  Inc(ACtx.TotalLen, ALength);
  while ALength > 0 do
  begin
    Chunk := 64 - ACtx.BufferLen;
    if Chunk > ALength then
      Chunk := ALength;
    Move(AData^, ACtx.Buffer[ACtx.BufferLen], Chunk);
    Inc(ACtx.BufferLen, Chunk);
    Inc(AData, Chunk);
    Dec(ALength, Chunk);
    if ACtx.BufferLen = 64 then
    begin
      SzShaBlock(ACtx, ACtx.Buffer);
      ACtx.BufferLen := 0;
    end;
  end;
end;

function SzShaFinal(var ACtx: TSzSha256): string;
var
  BitLen: Int64;
  Pad: array[0..71] of Byte;
  PadLen, ByteIndex, StateIndex: Integer;
begin
  BitLen := ACtx.TotalLen * 8;
  FillChar(Pad, SizeOf(Pad), 0);
  Pad[0] := $80;
  if ACtx.BufferLen < 56 then
    PadLen := 56 - ACtx.BufferLen
  else
    PadLen := 120 - ACtx.BufferLen;
  for ByteIndex := 0 to 7 do
    Pad[PadLen + ByteIndex] := Byte(BitLen shr (56 - ByteIndex * 8));
  SzShaUpdate(ACtx, @Pad[0], PadLen + 8);
  Result := '';
  for StateIndex := 0 to 7 do
    Result := Result + LowerCase(IntToHex(Int64(ACtx.State[StateIndex]), 8));
end;

function SzFileSha256(const AFileName: WideString): string;
var
  FileHandle: THandle;
  Ctx: TSzSha256;
  Buffer: array[0..32767] of Byte;
  ReadCount: DWORD;
begin
  Result := '';
  FileHandle := SzCreateFile(PWideChar(AFileName), SzGenericRead,
    SzFileShareRead, nil, SzOpenExisting, SzFileAttrNormal, 0);
  if FileHandle = INVALID_HANDLE_VALUE then
    Exit;
  try
    SzShaInit(Ctx);
    repeat
      ReadCount := 0;
      if not SzReadFile(FileHandle, Buffer, SizeOf(Buffer), ReadCount, nil) then
        Exit;
      if ReadCount > 0 then
        SzShaUpdate(Ctx, @Buffer[0], ReadCount);
    until ReadCount = 0;
    Result := SzShaFinal(Ctx);
  finally
    CloseHandle(FileHandle);
  end;
end;

// ---------------------------------------------------------------------------
//  Windows и выбор сборки
// ---------------------------------------------------------------------------

procedure SzGetOsInfo(var AInfo: TSzOsInfo);
var
  NtDll, Kernel: HMODULE;
  RtlGetVersion: TSzRtlGetVersion;
  IsWow64Process: TSzIsWow64Process;
  IsWow64Process2: TSzIsWow64Process2;
  VersionInfo: TSzOsVersionW;
  Wow64: BOOL;
  ProcessMachine, NativeMachine: Word;
  Bits: string;
begin
  AInfo.Major := Win32MajorVersion;
  AInfo.Minor := Win32MinorVersion;
  AInfo.Build := Win32BuildNumber;
  AInfo.IsNT := Win32Platform = VER_PLATFORM_WIN32_NT;
  AInfo.Is64 := False;
  AInfo.IsArm64 := False;
  // GetVersionEx в программе без манифеста совместимости с Windows 8.1+
  // отвечает 6.2; RtlGetVersion - настоящую версию
  NtDll := GetModuleHandle('ntdll.dll');
  if AInfo.IsNT and (NtDll <> 0) then
  begin
    RtlGetVersion := TSzRtlGetVersion(GetProcAddress(NtDll, 'RtlGetVersion'));
    if Assigned(RtlGetVersion) then
    begin
      FillChar(VersionInfo, SizeOf(VersionInfo), 0);
      VersionInfo.dwOSVersionInfoSize := SizeOf(VersionInfo);
      if RtlGetVersion(VersionInfo) = 0 then
      begin
        AInfo.Major := VersionInfo.dwMajorVersion;
        AInfo.Minor := VersionInfo.dwMinorVersion;
        AInfo.Build := VersionInfo.dwBuildNumber;
      end;
    end;
  end;
  // 64-битная ли Windows: unIDE - 32-битная программа (WOW64)
  Kernel := GetModuleHandle('kernel32.dll');
  if Kernel <> 0 then
  begin
    IsWow64Process2 := TSzIsWow64Process2(GetProcAddress(Kernel,
      'IsWow64Process2'));
    if Assigned(IsWow64Process2) then
    begin
      ProcessMachine := 0;
      NativeMachine := 0;
      if IsWow64Process2(GetCurrentProcess, ProcessMachine,
         NativeMachine) then
      begin
        AInfo.Is64 := NativeMachine = SzMachineAmd64;
        AInfo.IsArm64 := NativeMachine = SzMachineArm64;
      end;
    end
    else
    begin
      IsWow64Process := TSzIsWow64Process(GetProcAddress(Kernel,
        'IsWow64Process'));
      Wow64 := False;
      if Assigned(IsWow64Process) and
         IsWow64Process(GetCurrentProcess, Wow64) then
        AInfo.Is64 := Wow64;
    end;
  end;

  if not AInfo.IsNT then
    AInfo.Name := 'Windows 95 / 98 / Me'
  else if AInfo.Major < 5 then
    AInfo.Name := 'Windows NT ' + IntToStr(AInfo.Major) + '.' +
      IntToStr(AInfo.Minor)
  else if (AInfo.Major = 5) and (AInfo.Minor = 0) then
    AInfo.Name := 'Windows 2000'
  else if (AInfo.Major = 5) and (AInfo.Minor = 1) then
    AInfo.Name := 'Windows XP'
  else if (AInfo.Major = 5) and (AInfo.Minor = 2) then
    AInfo.Name := 'Windows XP / Server 2003'
  else if (AInfo.Major = 6) and (AInfo.Minor = 0) then
    AInfo.Name := 'Windows Vista'
  else if (AInfo.Major = 6) and (AInfo.Minor = 1) then
    AInfo.Name := 'Windows 7'
  else if (AInfo.Major = 6) and (AInfo.Minor = 2) then
    AInfo.Name := 'Windows 8'
  else if (AInfo.Major = 6) and (AInfo.Minor = 3) then
    AInfo.Name := 'Windows 8.1'
  else if (AInfo.Major = 10) and (AInfo.Build >= 22000) then
    AInfo.Name := 'Windows 11'
  else if AInfo.Major = 10 then
    AInfo.Name := 'Windows 10'
  else
    AInfo.Name := 'Windows ' + IntToStr(AInfo.Major) + '.' +
      IntToStr(AInfo.Minor);
  if AInfo.IsArm64 then
    Bits := 'ARM64'
  else if AInfo.Is64 then
    Bits := '64-bit'
  else
    Bits := '32-bit';
  AInfo.Name := AInfo.Name + ' (' + Bits + ')';
end;

function SzChoosePackage(const AOs: TSzOsInfo;
  var APackage: TSzPackage): Boolean;
var
  PackageIndex: Integer;
begin
  Result := False;
  if not AOs.IsNT then
    Exit;
  for PackageIndex := 0 to SzPackageCount - 1 do
    with SzPackages[PackageIndex] do
      if (not Need64 or AOs.Is64) and
         ((AOs.Major > MinMajor) or
          ((AOs.Major = MinMajor) and (AOs.Minor >= MinMinor))) then
      begin
        APackage := SzPackages[PackageIndex];
        Result := True;
        Exit;
      end;
end;

procedure SzToolFile(var AFile: TSzFile);
begin
  AFile.Url1 := SzToolUrl1;
  AFile.Url2 := SzToolUrl2;
  AFile.Size := SzToolSize;
  AFile.Sha256 := SzToolSha256;
end;

// ---------------------------------------------------------------------------
//  Загрузка
// ---------------------------------------------------------------------------

// Текст ошибки WinINet (12001..12999) или системной; для частых на старых
// Windows - что делать
function SzErrorText(ACode: DWORD): string;
var
  Buffer: array[0..511] of Char;
  Len: DWORD;
  WinInet: HMODULE;
begin
  Len := 0;
  if (ACode >= 12000) and (ACode < 13000) then
  begin
    WinInet := GetModuleHandle('wininet.dll');
    if WinInet <> 0 then
      Len := SzFormatMessage(SzFormatFromHModule or SzFormatIgnoreInserts,
        Pointer(WinInet), ACode, 0, Buffer, SizeOf(Buffer), nil);
  end
  else
    Len := SzFormatMessage(SzFormatFromSystem or SzFormatIgnoreInserts, nil,
      ACode, 0, Buffer, SizeOf(Buffer), nil);
  if Len > 0 then
    Result := Trim(string(PChar(@Buffer[0])))
  else
    Result := '';
  if Result = '' then
    Result := 'ошибка ' + IntToStr(ACode)
  else
    Result := Result + ' (' + IntToStr(ACode) + ')';
  case ACode of
    12157:   // ERROR_INTERNET_SECURITY_CHANNEL_ERROR
      Result := Result + '. Нет TLS 1.2: Свойства браузера - Дополнительно -' +
        ' включить «Использовать TLS 1.2»';
    12037, 12038, 12045, 12169:   // сертификат
      Result := Result + '. Сертификат сайта не проверен: обновите корневые' +
        ' сертификаты Windows';
  end;
end;

constructor TSzDownload.Create(const AFiles: TSzFiles);
var
  FileIndex: Integer;
begin
  SetLength(FFiles, Length(AFiles));
  FTotal := 0;
  for FileIndex := 0 to High(AFiles) do
  begin
    FFiles[FileIndex] := AFiles[FileIndex];
    Inc(FTotal, AFiles[FileIndex].Size);
  end;
  FFileIndex := 0;
  FDone := 0;
  FFinished := 0;
  FSession := nil;
  InitializeCriticalSection(FLock);
  FreeOnTerminate := False;
  inherited Create(False);
end;

destructor TSzDownload.Destroy;
begin
  inherited Destroy;
  DeleteCriticalSection(FLock);
end;

// Сеанс WinINet - тому, кто первым его заберёт (поток в конце или Cancel)
function TSzDownload.TakeSession: Pointer;
begin
  EnterCriticalSection(FLock);
  try
    Result := FSession;
    FSession := nil;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TSzDownload.GetFinished: Boolean;
begin
  Result := FFinished <> 0;
end;

// Отмена из главного потока: закрытие сеанса WinINet прерывает и
// подключение, и чтение, которые ждут сеть
procedure TSzDownload.Cancel;
var
  Session: Pointer;
begin
  FCancelled := True;
  Session := TakeSession;
  if Session <> nil then
    SzInternetCloseHandle(Session);
end;

function TSzDownload.GetFile(const AFile: TSzFile; const AUrl: string;
  var AError: string): Boolean;
var
  UrlHandle: Pointer;
  FileHandle: THandle;
  Buffer: array[0..32767] of Byte;
  ReadCount, Written, StatusCode, InfoLen, InfoIndex: DWORD;
  Ctx: TSzSha256;
  Received, StartDone: Integer;
  UrlText: WideString;
begin
  Result := False;
  StartDone := FDone;
  UrlText := AUrl;
  UrlHandle := SzInternetOpenUrl(FSession, PWideChar(UrlText), nil, 0,
    SzFlagReload or SzFlagNoCacheWrite or SzFlagPragmaNoCache or SzFlagNoUi or
    SzFlagNoCookies, 0);
  if UrlHandle = nil then
  begin
    if FCancelled then
      AError := 'отменено'
    else
      AError := SzErrorText(GetLastError);
    Exit;
  end;
  try
    // Ответ сервера (после переадресаций) - 200
    StatusCode := 0;
    InfoLen := SizeOf(StatusCode);
    InfoIndex := 0;
    if SzHttpQueryInfo(UrlHandle, SzQueryStatusCode or SzQueryFlagNumber,
       @StatusCode, InfoLen, InfoIndex) and (StatusCode <> 200) then
    begin
      AError := 'сервер ответил HTTP ' + IntToStr(StatusCode);
      Exit;
    end;
    FileHandle := SzCreateFile(PWideChar(AFile.FileName), SzGenericWrite, 0,
      nil, SzCreateAlways, SzFileAttrNormal, 0);
    if FileHandle = INVALID_HANDLE_VALUE then
    begin
      AError := 'файл не создать: ' + SzErrorText(GetLastError);
      Exit;
    end;
    Received := 0;
    SzShaInit(Ctx);
    try
      repeat
        if FCancelled then
        begin
          AError := 'отменено';
          Exit;
        end;
        ReadCount := 0;
        if not SzInternetReadFile(UrlHandle, @Buffer[0], SizeOf(Buffer),
           ReadCount) then
        begin
          if FCancelled then
            AError := 'отменено'
          else
            AError := SzErrorText(GetLastError);
          Exit;
        end;
        if ReadCount > 0 then
        begin
          Inc(Received, ReadCount);
          if Received > AFile.Size then
          begin
            AError := 'файл больше ожидаемого';
            Exit;
          end;
          SzShaUpdate(Ctx, @Buffer[0], ReadCount);
          if not SzWriteFile(FileHandle, Buffer, ReadCount, Written, nil) or
             (Written <> ReadCount) then
          begin
            AError := 'запись: ' + SzErrorText(GetLastError);
            Exit;
          end;
          FDone := StartDone + Received;
        end;
      until ReadCount = 0;
    finally
      CloseHandle(FileHandle);
      if AError <> '' then
        SzDeleteFile(PWideChar(AFile.FileName));
    end;
    if Received <> AFile.Size then
      AError := 'получено ' + IntToStr(Received) + ' байт из ' +
        IntToStr(AFile.Size)
    else if SzShaFinal(Ctx) <> AFile.Sha256 then
      AError := 'контрольная сумма SHA-256 не совпала';
    if AError <> '' then
    begin
      SzDeleteFile(PWideChar(AFile.FileName));
      FDone := StartDone;
      Exit;
    end;
    Result := True;
  finally
    SzInternetCloseHandle(UrlHandle);
  end;
end;

procedure TSzDownload.Execute;
var
  Agent: WideString;
  Timeout: DWORD;
  Session: Pointer;
  FileIndex, StartDone: Integer;
  ErrorText, HostError: string;
begin
  ErrorText := '';
  try
    Agent := 'unIDE';
    Session := SzInternetOpen(PWideChar(Agent), SzInternetOpenPreconfig, nil,
      nil, 0);
    EnterCriticalSection(FLock);
    try
      if FCancelled and (Session <> nil) then
      begin
        SzInternetCloseHandle(Session);
        Session := nil;
      end;
      FSession := Session;
    finally
      LeaveCriticalSection(FLock);
    end;
    if FCancelled then
      ErrorText := 'отменено'
    else if Session = nil then
      ErrorText := 'WinINet: ' + SzErrorText(GetLastError)
    else
    begin
      Timeout := 30000;
      SzInternetSetOption(Session, SzOptionConnectTimeout, @Timeout,
        SizeOf(Timeout));
      SzInternetSetOption(Session, SzOptionReceiveTimeout, @Timeout,
        SizeOf(Timeout));
      for FileIndex := 0 to High(FFiles) do
      begin
        FFileIndex := FileIndex;
        StartDone := FDone;
        // Первый адрес не вышел - второй; в ошибке - оба ответа
        HostError := '';
        if not GetFile(FFiles[FileIndex], FFiles[FileIndex].Url1,
           HostError) then
        begin
          ErrorText := HostError;
          FDone := StartDone;
          HostError := '';
          if FCancelled or (FFiles[FileIndex].Url2 = '') or
             not GetFile(FFiles[FileIndex], FFiles[FileIndex].Url2,
               HostError) then
          begin
            if not FCancelled and (HostError <> '') and
               (HostError <> ErrorText) then
              ErrorText := ErrorText + '; ' + HostError;
            if FCancelled then
              ErrorText := 'отменено';
            Break;
          end;
          ErrorText := '';
        end;
      end;
    end;
  except
    on Error: Exception do
      ErrorText := Error.Message;
  end;
  Session := TakeSession;
  if Session <> nil then
    SzInternetCloseHandle(Session);
  if FCancelled and (ErrorText = '') then
    ErrorText := 'отменено';
  FErrorText := ErrorText;
  InterlockedExchange(FFinished, 1);
end;

end.
