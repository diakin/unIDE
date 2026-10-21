unit SzSetup;

// ---------------------------------------------------------------------------
//  Свой 7-Zip unIDE: tools\7zip рядом с exe (unIDE FAR - архивы, ReactOS -
//  распаковка RosBE). Установленный в системе 7-Zip не используется и не
//  меняется: unIDE работает со своей копией.
//
//  - где: <папка exe>\tools\7zip\; если туда не записать (unIDE в
//    Program Files без прав) - %LOCALAPPDATA%\unIDE\tools\7zip\
//    (SzLocalExe ищет в обеих, SzChooseTargetDir выбирает, куда ставить);
//  - какую сборку брать - по Windows: x64 на 64-битной Windows (XP x64 и
//    новее), x86 - на 32-битной (2000 и новее) и на ARM64; 9x и NT 4 -
//    7-Zip 26.04 не поддерживает (заявлено: Windows 2000 - 11);
//  - установка (TSzInstall, свой поток): качаются 7zr.exe (маленький 7-Zip
//    только для формата 7z) и установщик 7-Zip; установщик - архив 7z, из
//    него 7zr.exe достаёт 7z.exe, 7z.dll и License.txt. Сам установщик не
//    запускается: ничего не регистрируется в системе, права администратора
//    не нужны;
//  - загрузка - WinINet (настройки прокси и TLS - как у Internet Explorer),
//    с ходом и отменой; каждый файл проверяется по размеру и SHA-256,
//    записанным здесь (версия закреплена; новая - новые размеры и суммы в
//    SzPackages / SzTool);
//  - асинхронно (unIDE FAR: таймер читает ход потока) или синхронно
//    (SzInstallSync: ход - через событие, как у окна хода ReactOS).
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

  // Шаг установки: загрузка, распаковка 7zr.exe
  TSzStage = (ssDownload, ssExtract);

  // Ход долгого шага (как TRosStepEvent): ADone из ATotal; False - стоп
  TSzStepEvent = function(ADone, ATotal: Cardinal): Boolean of object;

  // Что и как ставить (7-Zip - Sz7ZipPlan, QEMU - QemuTool):
  //   Files        - что скачать (FileName - только имя; папка - загрузки);
  //   Extractor    - чем распаковывать: '' - первым скачанным (7zr.exe),
  //                  иначе полный путь (свой 7z.exe);
  //   Archive      - номер скачанного файла, который распаковывать;
  //   ExtractNames - что достать: имена и маски через #13#10 (список 7-Zip);
  //   MoveNames    - что перенести в папку по одному, через ';' (последний
  //                  - признак полной установки); '' - папка заменяется
  //                  целиком распакованным;
  //   CheckFile    - файл, который должен быть после установки;
  //   InfoFile, InfoText - откуда установлено (текст рядом)
  TSzPlan = record
    Title: string;
    Files: TSzFiles;
    Extractor: WideString;
    Archive: Integer;
    ExtractNames: string;
    MoveNames: string;
    CheckFile: string;
    InfoFile: string;
    InfoText: string;
  end;

  // Установка по плану в ATargetDir в своём потоке. Ход - Stage, FileIndex,
  // Done, Total (читает главный поток); конец - Finished, ошибка -
  // ErrorText ('' - установлено)
  TSzInstall = class(TThread)
  private
    FFiles: TSzFiles;
    FTargetDir: WideString;
    FDownloadDir: WideString;
    FPlan: TSzPlan;
    FStage: TSzStage;
    FProcess: THandle;
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
    function Download: string;
    function Extract: string;
    function MoveInPlace: string;
    procedure WriteInfo;
  protected
    procedure Execute; override;
  public
    constructor Create(const ATargetDir: WideString; const APlan: TSzPlan);
    destructor Destroy; override;
    procedure Cancel;
    property Stage: TSzStage read FStage;
    property FileIndex: Integer read FFileIndex;
    property Done: Integer read FDone;
    property Total: Integer read FTotal;
    property Finished: Boolean read GetFinished;
    property Cancelled: Boolean read FCancelled;
    property ErrorText: string read FErrorText;
  end;

const
  SzVersion = '26.04';
  SzToolName = '7zr.exe';
  SzDownloadPage = 'https://www.7-zip.org/download.html';
  SzInfoFile = 'unide_7zip.txt';

// <папка exe>\tools\ и %LOCALAPPDATA%\unIDE\tools\ ('' - папки профиля
// нет): свои инструменты unIDE (7zip, qemu)
function SzToolsAppDir: WideString;
function SzToolsUserDir: WideString;
// Путь с '\' в конце / без него (кроме корня диска)
function SzWithSlash(const APath: WideString): WideString;
function SzNoSlash(const APath: WideString): WideString;
// <папка exe>\tools\7zip\
function SzAppDir: WideString;
// %LOCALAPPDATA%\unIDE\tools\7zip\ ('' - папки профиля нет)
function SzUserDir: WideString;
// 7z.exe своего 7-Zip (есть и 7z.dll): сначала у exe, потом в профиле;
// нет - ''
function SzLocalExe: WideString;
// Куда ставить: где уже есть свой 7-Zip, иначе у exe, если туда можно
// писать, иначе в профиль; '' - никуда
function SzChooseTargetDir: WideString;
// Версия файла ('26.04'); '' - не прочитать
function SzFileVersion(const AFileName: WideString): string;
// Версия AOld ('24.09') старше ANew ('26.04')
function SzVersionOlder(const AOld, ANew: string): Boolean;
// Идёт установка (поток TSzInstall есть)
function SzInstallRunning: Boolean;
// Установить синхронно: AOnStep - ход (и обработка сообщений окна), False
// из него - остановить. APackage - что ставилось; ошибка - False и AError
function SzInstallSync(AOnStep: TSzStepEvent; var APackage: TSzPackage;
  var AError: string): Boolean;
// План установки 7-Zip сборки APackage
function Sz7ZipPlan(const APackage: TSzPackage; const AOsName: string): TSzPlan;
// Установить по плану в ATargetDir синхронно (ход - AOnStep)
function SzInstallPlanSync(const ATargetDir: WideString; const APlan: TSzPlan;
  AOnStep: TSzStepEvent; var AError: string): Boolean;
// Папка существует / создать со всеми выше / можно ли в неё писать
// (создаётся) / файл существует
function SzDirExists(const APath: WideString): Boolean;
function SzForceDirs(const APath: WideString): Boolean;
function SzCanWrite(const ADir: WideString): Boolean;
function SzFileExists(const APath: WideString): Boolean;

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
  SzInvalidAttr = $FFFFFFFF;
  SzAttrDirectory = $10;
  SzMoveReplace = 1;          // MOVEFILE_REPLACE_EXISTING
  SzMoveCopyAllowed = 2;      // MOVEFILE_COPY_ALLOWED
  SzStartfUseShowWindow = 1;
  SzStartfUseStdHandles = $100;
  SzCreateNoWindow = $08000000;
  SzCsidlLocalAppData = $1C;
  SzWaitTimeout = $102;

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

  TSzFindData = record
    dwFileAttributes: DWORD;
    ftCreationTime, ftLastAccessTime, ftLastWriteTime: TFileTime;
    nFileSizeHigh, nFileSizeLow: DWORD;
    dwReserved0, dwReserved1: DWORD;
    cFileName: array[0..MAX_PATH - 1] of WideChar;
    cAlternateFileName: array[0..13] of WideChar;
  end;

  TSzStartupInfo = record
    cb: DWORD;
    lpReserved, lpDesktop, lpTitle: PWideChar;
    dwX, dwY, dwXSize, dwYSize: DWORD;
    dwXCountChars, dwYCountChars, dwFillAttribute: DWORD;
    dwFlags: DWORD;
    wShowWindow: Word;
    cbReserved2: Word;
    lpReserved2: Pointer;
    hStdInput, hStdOutput, hStdError: THandle;
  end;

  TSzProcessInfo = record
    hProcess, hThread: THandle;
    dwProcessId, dwThreadId: DWORD;
  end;

  TSzSecurityAttributes = record
    nLength: DWORD;
    lpSecurityDescriptor: Pointer;
    bInheritHandle: BOOL;
  end;

  // VS_FIXEDFILEINFO
  TSzFixedFileInfo = record
    dwSignature, dwStrucVersion: DWORD;
    dwFileVersionMS, dwFileVersionLS: DWORD;
    dwProductVersionMS, dwProductVersionLS: DWORD;
    dwFileFlagsMask, dwFileFlags, dwFileOS, dwFileType, dwFileSubtype: DWORD;
    dwFileDateMS, dwFileDateLS: DWORD;
  end;
  PSzFixedFileInfo = ^TSzFixedFileInfo;

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
function SzMoveFileEx(AExisting, ANew: PWideChar; AFlags: DWORD): BOOL;
  stdcall; external 'kernel32.dll' name 'MoveFileExW';
function SzCreateDirectory(APath: PWideChar; ASecurity: Pointer): BOOL;
  stdcall; external 'kernel32.dll' name 'CreateDirectoryW';
function SzRemoveDirectory(APath: PWideChar): BOOL; stdcall;
  external 'kernel32.dll' name 'RemoveDirectoryW';
function SzGetFileAttributes(APath: PWideChar): DWORD; stdcall;
  external 'kernel32.dll' name 'GetFileAttributesW';
function SzGetModuleFileName(AModule: HMODULE; ABuffer: PWideChar;
  ASize: DWORD): DWORD; stdcall;
  external 'kernel32.dll' name 'GetModuleFileNameW';
function SzFindFirstFile(APath: PWideChar;
  var AData: TSzFindData): THandle; stdcall;
  external 'kernel32.dll' name 'FindFirstFileW';
function SzFindNextFile(AHandle: THandle;
  var AData: TSzFindData): BOOL; stdcall;
  external 'kernel32.dll' name 'FindNextFileW';
function SzCreateProcess(AAppName, ACommandLine: PWideChar;
  AProcessAttr, AThreadAttr: Pointer; AInheritHandles: BOOL;
  ACreationFlags: DWORD; AEnvironment: Pointer; ACurrentDir: PWideChar;
  var AStartupInfo: TSzStartupInfo;
  var AProcessInfo: TSzProcessInfo): BOOL; stdcall;
  external 'kernel32.dll' name 'CreateProcessW';
function SzGetExitCodeProcess(AProcess: THandle;
  var AExitCode: DWORD): BOOL; stdcall;
  external 'kernel32.dll' name 'GetExitCodeProcess';
function SzTerminateProcess(AProcess: THandle; AExitCode: UINT): BOOL;
  stdcall; external 'kernel32.dll' name 'TerminateProcess';
function SzShGetFolderPath(AOwner: HWND; AFolder: Integer; AToken: THandle;
  AFlags: DWORD; APath: PWideChar): HRESULT; stdcall;
  external 'shell32.dll' name 'SHGetFolderPathW';
function SzGetFileVersionInfoSize(AFileName: PWideChar;
  var AHandle: DWORD): DWORD; stdcall;
  external 'version.dll' name 'GetFileVersionInfoSizeW';
function SzGetFileVersionInfo(AFileName: PWideChar; AHandle, ASize: DWORD;
  AData: Pointer): BOOL; stdcall;
  external 'version.dll' name 'GetFileVersionInfoW';
function SzVerQueryValue(ABlock: Pointer; ASubBlock: PWideChar;
  var ABuffer: Pointer; var ALength: UINT): BOOL; stdcall;
  external 'version.dll' name 'VerQueryValueW';
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

var
  SzRunning: Integer = 0;

function SzInstallRunning: Boolean;
begin
  Result := SzRunning > 0;
end;

// ---------------------------------------------------------------------------
//  Папки и файлы
// ---------------------------------------------------------------------------

function SzWithSlash(const APath: WideString): WideString;
begin
  Result := APath;
  if (Result <> '') and (Result[Length(Result)] <> '\') then
    Result := Result + '\';
end;

function SzNoSlash(const APath: WideString): WideString;
begin
  Result := APath;
  if (Length(Result) > 3) and (Result[Length(Result)] = '\') then
    SetLength(Result, Length(Result) - 1);
end;

function SzFileExists(const APath: WideString): Boolean;
var
  Attr: DWORD;
begin
  Attr := SzGetFileAttributes(PWideChar(APath));
  Result := (Attr <> SzInvalidAttr) and (Attr and SzAttrDirectory = 0);
end;

function SzDirExists(const APath: WideString): Boolean;
var
  Attr: DWORD;
begin
  Attr := SzGetFileAttributes(PWideChar(SzNoSlash(APath)));
  Result := (Attr <> SzInvalidAttr) and (Attr and SzAttrDirectory <> 0);
end;

// Создать папку со всеми недостающими выше
function SzForceDirs(const APath: WideString): Boolean;
var
  Dir: WideString;
  SlashPos: Integer;
begin
  Dir := SzNoSlash(APath);
  Result := SzDirExists(Dir);
  if Result or (Length(Dir) <= 3) then
    Exit;
  SlashPos := Length(Dir);
  while (SlashPos > 0) and (Dir[SlashPos] <> '\') do
    Dec(SlashPos);
  if SlashPos > 0 then
    SzForceDirs(Copy(Dir, 1, SlashPos - 1));
  Result := SzCreateDirectory(PWideChar(Dir), nil) or SzDirExists(Dir);
end;

// Удалить папку со всем содержимым (без оболочки Windows - работает и из
// потока)
procedure SzDeleteTree(const APath: WideString);
var
  Dir, Name: WideString;
  FindHandle: THandle;
  FindData: TSzFindData;
begin
  Dir := SzWithSlash(APath);
  if not SzDirExists(Dir) then
    Exit;
  FindHandle := SzFindFirstFile(PWideChar(Dir + '*'), FindData);
  if FindHandle <> INVALID_HANDLE_VALUE then
  begin
    repeat
      Name := PWideChar(@FindData.cFileName[0]);
      if (Name = '.') or (Name = '..') then
        Continue;
      if FindData.dwFileAttributes and SzAttrDirectory <> 0 then
        SzDeleteTree(Dir + Name)
      else
        SzDeleteFile(PWideChar(Dir + Name));
    until not SzFindNextFile(FindHandle, FindData);
    Windows.FindClose(FindHandle);
  end;
  SzRemoveDirectory(PWideChar(SzNoSlash(Dir)));
end;

function SzToolsAppDir: WideString;
var
  Buffer: array[0..1023] of WideChar;
  Len: DWORD;
  SlashPos: Integer;
begin
  Len := SzGetModuleFileName(0, Buffer, Length(Buffer));
  if (Len = 0) or (Len >= DWORD(Length(Buffer))) then
  begin
    Result := ExtractFilePath(ParamStr(0)) + 'tools\';
    Exit;
  end;
  Result := PWideChar(@Buffer[0]);
  SlashPos := Length(Result);
  while (SlashPos > 0) and (Result[SlashPos] <> '\') do
    Dec(SlashPos);
  Result := Copy(Result, 1, SlashPos) + 'tools\';
end;

function SzToolsUserDir: WideString;
var
  Buffer: array[0..MAX_PATH] of WideChar;
begin
  Result := '';
  FillChar(Buffer, SizeOf(Buffer), 0);
  if SzShGetFolderPath(0, SzCsidlLocalAppData, 0, 0, Buffer) = 0 then
  begin
    Result := PWideChar(@Buffer[0]);
    if Result <> '' then
      Result := SzWithSlash(Result) + 'unIDE\tools\';
  end;
end;

function SzAppDir: WideString;
begin
  Result := SzToolsAppDir + '7zip\';
end;

function SzUserDir: WideString;
begin
  Result := SzToolsUserDir;
  if Result <> '' then
    Result := Result + '7zip\';
end;

function SzLocalExe: WideString;
var
  Dirs: array[0..1] of WideString;
  DirIndex: Integer;
begin
  Result := '';
  Dirs[0] := SzAppDir;
  Dirs[1] := SzUserDir;
  for DirIndex := 0 to 1 do
    if (Dirs[DirIndex] <> '') and SzFileExists(Dirs[DirIndex] + '7z.exe') and
       SzFileExists(Dirs[DirIndex] + '7z.dll') then
    begin
      Result := Dirs[DirIndex] + '7z.exe';
      Exit;
    end;
end;

// Можно ли писать в папку ADir (создаётся, если нет): пробный файл
function SzCanWrite(const ADir: WideString): Boolean;
var
  TestFile: WideString;
  TestHandle: THandle;
begin
  Result := False;
  if (ADir = '') or not SzForceDirs(ADir) then
    Exit;
  TestFile := ADir + '~unide_write_test.tmp';
  TestHandle := SzCreateFile(PWideChar(TestFile), SzGenericWrite, 0, nil,
    SzCreateAlways, SzFileAttrNormal, 0);
  if TestHandle = INVALID_HANDLE_VALUE then
    Exit;
  CloseHandle(TestHandle);
  SzDeleteFile(PWideChar(TestFile));
  Result := True;
end;

function SzChooseTargetDir: WideString;
var
  Existing: WideString;
begin
  Existing := SzLocalExe;
  if Existing <> '' then
  begin
    Result := ExtractFilePath(Existing);
    if SzCanWrite(Result) then
      Exit;
  end;
  Result := SzAppDir;
  if SzCanWrite(Result) then
    Exit;
  Result := SzUserDir;
  if SzCanWrite(Result) then
    Exit;
  Result := '';
end;

function SzFileVersion(const AFileName: WideString): string;
var
  InfoSize, Dummy: DWORD;
  InfoData: Pointer;
  FixedInfo: PSzFixedFileInfo;
  FixedLen: UINT;
  RootBlock: WideString;
begin
  Result := '';
  Dummy := 0;
  InfoSize := SzGetFileVersionInfoSize(PWideChar(AFileName), Dummy);
  if InfoSize = 0 then
    Exit;
  GetMem(InfoData, InfoSize);
  try
    if not SzGetFileVersionInfo(PWideChar(AFileName), 0, InfoSize,
       InfoData) then
      Exit;
    RootBlock := '\';
    FixedInfo := nil;
    FixedLen := 0;
    if SzVerQueryValue(InfoData, PWideChar(RootBlock), Pointer(FixedInfo),
       FixedLen) and (FixedInfo <> nil) and (FixedLen > 0) then
      Result := IntToStr(FixedInfo^.dwFileVersionMS shr 16) + '.' +
        Format('%.2d', [FixedInfo^.dwFileVersionMS and $FFFF]);
  finally
    FreeMem(InfoData);
  end;
end;

// '26.04' -> 2604; не разобрать - -1
function SzVersionNumber(const AVersion: string): Integer;
var
  DotPos: Integer;
begin
  DotPos := Pos('.', AVersion);
  if DotPos = 0 then
    Result := StrToIntDef(AVersion, -1) * 100
  else
    Result := StrToIntDef(Copy(AVersion, 1, DotPos - 1), -1) * 100 +
      StrToIntDef(Copy(AVersion, DotPos + 1, MaxInt), 0);
end;

function SzVersionOlder(const AOld, ANew: string): Boolean;
var
  OldNumber: Integer;
begin
  OldNumber := SzVersionNumber(AOld);
  Result := (OldNumber >= 0) and (OldNumber < SzVersionNumber(ANew));
end;

// ---------------------------------------------------------------------------
//  Установка
// ---------------------------------------------------------------------------

constructor TSzInstall.Create(const ATargetDir: WideString;
  const APlan: TSzPlan);
var
  FileIndex: Integer;
begin
  FTargetDir := SzWithSlash(ATargetDir);
  FPlan := APlan;
  FStage := ssDownload;
  FProcess := 0;
  // Файлы по одному - загрузка внутри папки; папка целиком - рядом с ней
  if FPlan.MoveNames <> '' then
    FDownloadDir := FTargetDir + '~download\'
  else
    FDownloadDir := SzNoSlash(FTargetDir) + '.~download\';
  SetLength(FFiles, Length(APlan.Files));
  FTotal := 0;
  for FileIndex := 0 to High(FFiles) do
  begin
    FFiles[FileIndex] := APlan.Files[FileIndex];
    FFiles[FileIndex].FileName := FDownloadDir + APlan.Files[FileIndex].FileName;
    Inc(FTotal, FFiles[FileIndex].Size);
  end;
  InterlockedIncrement(SzRunning);
  FFileIndex := 0;
  FDone := 0;
  FFinished := 0;
  FSession := nil;
  InitializeCriticalSection(FLock);
  FreeOnTerminate := False;
  inherited Create(False);
end;

destructor TSzInstall.Destroy;
begin
  inherited Destroy;
  DeleteCriticalSection(FLock);
  InterlockedDecrement(SzRunning);
end;

// Сеанс WinINet - тому, кто первым его заберёт (поток в конце или Cancel)
function TSzInstall.TakeSession: Pointer;
begin
  EnterCriticalSection(FLock);
  try
    Result := FSession;
    FSession := nil;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TSzInstall.GetFinished: Boolean;
begin
  Result := FFinished <> 0;
end;

// Отмена из главного потока: закрытие сеанса WinINet прерывает и
// подключение, и чтение, которые ждут сеть
procedure TSzInstall.Cancel;
var
  Session: Pointer;
begin
  FCancelled := True;
  Session := TakeSession;
  if Session <> nil then
    SzInternetCloseHandle(Session);
  // Распаковку (7zr.exe) поток прервёт сам: он ждёт процесс по 100 мс
end;

function TSzInstall.GetFile(const AFile: TSzFile; const AUrl: string;
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

function TSzInstall.Download: string;
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
  Result := ErrorText;
end;


// Распаковка (7zr.exe или свой 7z.exe): архив -> <загрузки>\x\, что
// достать - списком в файле; вывод - в extract.log
function TSzInstall.Extract: string;
var
  DownloadDir, Command, LogFile, ListFile, Extractor: WideString;
  Security: TSzSecurityAttributes;
  Startup: TSzStartupInfo;
  ProcInfo: TSzProcessInfo;
  LogHandle, ListHandle: THandle;
  ExitCode, ReadCount, Written: DWORD;
  LogText, ListText: string;
  LogWide, Line: WideString;
  LineStart, LineEnd: Integer;
begin
  Result := '';
  DownloadDir := FDownloadDir;
  LogFile := DownloadDir + 'extract.log';
  ListFile := DownloadDir + 'extract.lst';
  // Список имён - UTF-8 (-scsUTF-8)
  ListText := UTF8Encode(WideString(FPlan.ExtractNames)) + #13#10;
  ListHandle := SzCreateFile(PWideChar(ListFile), SzGenericWrite, 0, nil,
    SzCreateAlways, SzFileAttrNormal, 0);
  if ListHandle = INVALID_HANDLE_VALUE then
  begin
    Result := 'список для распаковки не создать: ' + SzErrorText(GetLastError);
    Exit;
  end;
  Written := 0;
  SzWriteFile(ListHandle, ListText[1], Length(ListText), Written, nil);
  CloseHandle(ListHandle);
  if FPlan.Extractor <> '' then
    Extractor := FPlan.Extractor
  else
    Extractor := FFiles[0].FileName;
  FillChar(Security, SizeOf(Security), 0);
  Security.nLength := SizeOf(Security);
  Security.bInheritHandle := True;
  LogHandle := SzCreateFile(PWideChar(LogFile), SzGenericWrite,
    SzFileShareRead, @Security, SzCreateAlways, SzFileAttrNormal, 0);
  if LogHandle = INVALID_HANDLE_VALUE then
  begin
    Result := 'файл журнала не создать: ' + SzErrorText(GetLastError);
    Exit;
  end;
  Command := WideString('"') + Extractor +
    WideString('" x -y -sccUTF-8 -scsUTF-8 -bso0 -bsp0 "-o') + DownloadDir +
    WideString('x" "') + FFiles[FPlan.Archive].FileName + WideString('" "@') +
    ListFile + WideString('"');
  FillChar(Startup, SizeOf(Startup), 0);
  Startup.cb := SizeOf(Startup);
  Startup.dwFlags := SzStartfUseShowWindow or SzStartfUseStdHandles;
  Startup.wShowWindow := SW_HIDE;
  Startup.hStdInput := 0;
  Startup.hStdOutput := LogHandle;
  Startup.hStdError := LogHandle;
  FillChar(ProcInfo, SizeOf(ProcInfo), 0);
  if not SzCreateProcess(nil, PWideChar(Command), nil, nil, True,
     SzCreateNoWindow, nil, PWideChar(DownloadDir), Startup, ProcInfo) then
  begin
    Result := ExtractFileName(string(Extractor)) + ' не запустить: ' +
      SzErrorText(GetLastError);
    CloseHandle(LogHandle);
    Exit;
  end;
  CloseHandle(ProcInfo.hThread);
  FProcess := ProcInfo.hProcess;
  try
    while WaitForSingleObject(ProcInfo.hProcess, 100) = SzWaitTimeout do
      if FCancelled then
      begin
        SzTerminateProcess(ProcInfo.hProcess, 1);
        WaitForSingleObject(ProcInfo.hProcess, 5000);
        Result := 'отменено';
        Break;
      end;
    ExitCode := 0;
    SzGetExitCodeProcess(ProcInfo.hProcess, ExitCode);
  finally
    FProcess := 0;
    CloseHandle(ProcInfo.hProcess);
    CloseHandle(LogHandle);
  end;
  if (Result <> '') or (ExitCode <= 1) then
    Exit;
  // Ошибка: первая строка с ERROR из журнала 7zr.exe (UTF-8)
  LogText := '';
  LogHandle := SzCreateFile(PWideChar(LogFile), SzGenericRead,
    SzFileShareRead, nil, SzOpenExisting, SzFileAttrNormal, 0);
  if LogHandle <> INVALID_HANDLE_VALUE then
  begin
    SetLength(LogText, 16384);
    ReadCount := 0;
    if SzReadFile(LogHandle, LogText[1], Length(LogText), ReadCount, nil) then
      SetLength(LogText, ReadCount)
    else
      LogText := '';
    CloseHandle(LogHandle);
  end;
  LogWide := UTF8Decode(LogText);
  LineStart := 1;
  while LineStart <= Length(LogWide) do
  begin
    LineEnd := LineStart;
    while (LineEnd <= Length(LogWide)) and (LogWide[LineEnd] <> #10) do
      Inc(LineEnd);
    Line := Trim(Copy(LogWide, LineStart, LineEnd - LineStart));
    LineStart := LineEnd + 1;
    if Pos('ERROR', string(Line)) > 0 then
    begin
      Result := ExtractFileName(string(Extractor)) + ': ' + string(Line);
      Exit;
    end;
  end;
  Result := ExtractFileName(string(Extractor)) + ' завершился с кодом ' +
    IntToStr(ExitCode);
end;

// Из <загрузки>\x\ - на место: по одному (последний - признак полной
// установки) или вся папка вместо прежней
function TSzInstall.MoveInPlace: string;
var
  Names: TStringList;
  NameIndex, SemiPos: Integer;
  Rest: string;
  Source, Target: WideString;
begin
  Result := '';
  if FPlan.MoveNames = '' then
  begin
    // Прежняя папка - своя (ставилась так же); её место - распакованной
    SzDeleteTree(FTargetDir);
    if SzDirExists(FTargetDir) then
    begin
      Result := 'прежнюю папку ' + string(FTargetDir) + ' не удалить ' +
        '(файл занят - закройте программу)';
      Exit;
    end;
    if not SzMoveFileEx(PWideChar(FDownloadDir + 'x'),
       PWideChar(SzNoSlash(FTargetDir)), 0) then
      Result := 'папку не перенести: ' + SzErrorText(GetLastError);
    Exit;
  end;
  Names := TStringList.Create;
  try
    // ';' - разделитель (DelimitedText в Delphi 7 режет и по пробелам)
    Rest := FPlan.MoveNames;
    while Rest <> '' do
    begin
      SemiPos := Pos(';', Rest);
      if SemiPos = 0 then
        SemiPos := Length(Rest) + 1;
      if Trim(Copy(Rest, 1, SemiPos - 1)) <> '' then
        Names.Add(Trim(Copy(Rest, 1, SemiPos - 1)));
      Delete(Rest, 1, SemiPos);
    end;
    for NameIndex := 0 to Names.Count - 1 do
    begin
      Source := FDownloadDir + 'x\' + WideString(Names[NameIndex]);
      Target := FTargetDir + WideString(Names[NameIndex]);
      if not SzMoveFileEx(PWideChar(Source), PWideChar(Target),
         SzMoveReplace or SzMoveCopyAllowed) then
      begin
        Result := Names[NameIndex] + ': ' + SzErrorText(GetLastError);
        Exit;
      end;
    end;
  finally
    Names.Free;
  end;
end;

// Откуда установлено - рядом, текстом
procedure TSzInstall.WriteInfo;
var
  InfoHandle: THandle;
  Written: DWORD;
begin
  if (FPlan.InfoFile = '') or (FPlan.InfoText = '') then
    Exit;
  InfoHandle := SzCreateFile(PWideChar(FTargetDir + FPlan.InfoFile),
    SzGenericWrite, 0, nil, SzCreateAlways, SzFileAttrNormal, 0);
  if InfoHandle <> INVALID_HANDLE_VALUE then
  begin
    Written := 0;
    SzWriteFile(InfoHandle, FPlan.InfoText[1], Length(FPlan.InfoText),
      Written, nil);
    CloseHandle(InfoHandle);
  end;
end;

procedure TSzInstall.Execute;
var
  ErrorText: string;
begin
  ErrorText := '';
  try
    if not SzForceDirs(FDownloadDir) then
      ErrorText := 'папку ' + string(FDownloadDir) + ' не создать: ' +
        SzErrorText(GetLastError)
    else
    begin
      ErrorText := Download;
      if ErrorText = '' then
      begin
        FStage := ssExtract;
        FDone := FTotal;
        ErrorText := Extract;
      end;
      if ErrorText = '' then
        ErrorText := MoveInPlace;
      if (ErrorText = '') and (FPlan.CheckFile <> '') and
         not SzFileExists(FTargetDir + FPlan.CheckFile) then
        ErrorText := FPlan.CheckFile + ' после установки не найден';
      if ErrorText = '' then
        WriteInfo;
    end;
  except
    on Error: Exception do
      ErrorText := Error.Message;
  end;
  SzDeleteTree(FDownloadDir);
  if FCancelled then
    ErrorText := 'отменено';
  FErrorText := ErrorText;
  InterlockedExchange(FFinished, 1);
end;

function SzInstallSync(AOnStep: TSzStepEvent; var APackage: TSzPackage;
  var AError: string): Boolean;
var
  OsInfo: TSzOsInfo;
  TargetDir: WideString;
  Install: TSzInstall;
begin
  Result := False;
  AError := '';
  if SzInstallRunning then
  begin
    AError := '7-Zip уже устанавливается';
    Exit;
  end;
  SzGetOsInfo(OsInfo);
  if not SzChoosePackage(OsInfo, APackage) then
  begin
    AError := '7-Zip ' + SzVersion + ' работает в Windows 2000 и новее, ' +
      'здесь ' + OsInfo.Name;
    Exit;
  end;
  TargetDir := SzChooseTargetDir;
  if TargetDir = '' then
  begin
    AError := 'нет папки для 7-Zip: в ' + string(SzAppDir) + ' и ' +
      string(SzUserDir) + ' не записать';
    Exit;
  end;
  Result := SzInstallPlanSync(TargetDir, Sz7ZipPlan(APackage, OsInfo.Name),
    AOnStep, AError);
  if Result and (SzLocalExe = '') then
  begin
    Result := False;
    AError := '7z.exe после установки не найден';
  end;
end;

function SzInstallPlanSync(const ATargetDir: WideString; const APlan: TSzPlan;
  AOnStep: TSzStepEvent; var AError: string): Boolean;
var
  Install: TSzInstall;
begin
  Result := False;
  AError := '';
  if SzInstallRunning then
  begin
    AError := 'уже идёт другая установка (7-Zip или QEMU)';
    Exit;
  end;
  Install := TSzInstall.Create(ATargetDir, APlan);
  try
    while not Install.Finished do
    begin
      if Assigned(AOnStep) and
         not AOnStep(Cardinal(Install.Done), Cardinal(Install.Total)) then
        Install.Cancel;
      Sleep(50);
    end;
    Install.WaitFor;
    AError := Install.ErrorText;
    Result := AError = '';
  finally
    Install.Free;
  end;
end;

function Sz7ZipPlan(const APackage: TSzPackage; const AOsName: string): TSzPlan;
begin
  Result.Title := '7-Zip ' + APackage.Version + ' (' + APackage.Arch + ')';
  SetLength(Result.Files, 2);
  SzToolFile(Result.Files[0]);
  Result.Files[0].FileName := SzToolName;
  Result.Files[1].Url1 := APackage.Url1;
  Result.Files[1].Url2 := APackage.Url2;
  Result.Files[1].FileName := APackage.FileName;
  Result.Files[1].Size := APackage.Size;
  Result.Files[1].Sha256 := APackage.Sha256;
  Result.Extractor := '';      // 7zr.exe - первый скачанный
  Result.Archive := 1;
  Result.ExtractNames := '7z.exe'#13#10'7z.dll'#13#10'License.txt';
  // 7z.exe - последним: есть 7z.exe - есть и остальное
  Result.MoveNames := '7z.dll;License.txt;7z.exe';
  Result.CheckFile := '7z.exe';
  Result.InfoFile := SzInfoFile;
  Result.InfoText := '7-Zip ' + APackage.Version + ' (' + APackage.Arch +
    '), установлен unIDE ' + FormatDateTime('yyyy-mm-dd hh:nn', Now) +
    ' для ' + AOsName + #13#10 + APackage.Url1 + #13#10 + 'SHA-256 ' +
    APackage.FileName + ': ' + APackage.Sha256 + #13#10 +
    'Из установщика взяты 7z.exe, 7z.dll, License.txt (лицензия 7-Zip).' +
    #13#10 + 'Свой 7-Zip unIDE: установленный в системе 7-Zip не ' +
    'используется и не меняется.' + #13#10;
end;

end.
