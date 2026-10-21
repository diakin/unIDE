unit RosTools;

// ---------------------------------------------------------------------------
//  Инструменты сборки ReactOS: скачивание и установка RosBE. Без VCL.
//
//  RosBE 2.2.1 (для reactosVG14) - установщик NSIS 3.05 с SourceForge,
//  77 584 546 байт. Установщик просит права администратора (в манифесте
//  requireAdministrator) - Windows покажет запрос UAC. Его сценарий -
//  RosBE-Windows/RosBE.nsi, тег RosBE-2.2.1 в github.com/reactos/RosBE:
//    - .onInit ставит $INSTDIR := C:\RosBE, поэтому /D=<папка> не
//      действует: тихая установка (/S) - всегда в C:\RosBE; другую папку
//      можно выбрать только в окнах установщика;
//    - есть запись об удалении "ReactOS Build Environment" (HKCU или HKLM)
//      - установщик спрашивает, удалить ли прежнюю версию (MessageBox без
//      /SD); ответ не Yes и не No ведёт в Abort - код завершения 2. Тот же
//      код - при уже запущенном установщике (мьютекс RosBE-v2.2.1-
//      Installer) и при ошибке запуска самого NSIS: файл не прошёл
//      проверку целостности (CRCCheck force) или не создаётся временная
//      папка - NSIS 3.05, Source/exehead/Main.c, ExitProcess(2);
//    - после установки HKCU\Software\Microsoft\Windows\CurrentVersion\
//      App Paths\RosBE.cmd (значение по умолчанию) = <папка>\RosBE.cmd.
//  Файл на SourceForge (SHA-256 ниже, совпадает с MD5/SHA1 на странице
//  файла) сам не проходит эту проверку целостности: CRC32 данных
//  0x7AD84B9F, записано 0x12A04F53 (проверено 15.10.2026 по алгоритму
//  NSIS 3.05 exehead/fileform.c, на nsis-3.05-setup.exe он сходится).
//  Запуск всегда даёт "Installer integrity check has failed" и код 2, а
//  CRCCheck force не даёт обойти её ключом /NCRC. Сами файлы 7-Zip
//  распаковывает без ошибок (9457 файлов; заголовки PE и архивов .a
//  целы), поэтому установка - распаковкой 7-Zip (RosExtractArgs).
//  RosBE.cmd переносим (%~dp0), записи в реестре ему не нужны.
//
//  RosBE.cmd - скрипт окружения проекта (ReactOS_EnvScript, см. RosProj).
//
//  Скачивание - WinINet (InternetOpenUrl): переадресации SourceForge на
//  зеркало он проходит сам. HTTPS на Windows 7 идёт через настройки
//  Internet Explorer: без TLS 1.2 в Свойствах обозревателя SourceForge не
//  ответит - тогда текст ошибки говорит об этом.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes, WinInet, ShellAPI, Registry;

const
  RosBE221Url = 'https://downloads.sourceforge.net/project/reactos/' +
                'RosBE-Windows/i386/2.2.1/RosBE-2.2.1.exe';
  RosBE221File = 'RosBE-2.2.1.exe';
  RosBE221Size = 77584546;
  // SHA-256 файла с SourceForge (проверено 15.10.2026)
  RosBE221Sha256 =
    'a72b220a1b21927629cb7bc5606baf64fd7c30666b9bdc4ba21aabcbe00b3649';
  RosBEScript = 'RosBE.cmd';

  // 7-Zip для распаковки RosBE - свой 7-Zip unIDE (SzSetup, tools\7zip):
  // поиск, версия и установка там; системный 7-Zip не используется

type
  // Ход долгого шага: ADone из ATotal (ATotal = 0 - размер не известен).
  // False - остановить.
  TRosStepEvent = function(ADone, ATotal: Cardinal): Boolean of object;

// Папка тихой установки RosBE 2.2.1 - C:\RosBE (её задаёт сам установщик)
function RosBE221DefaultDir: string;
// RosBE.cmd из записи установщика (App Paths), если файл есть; иначе пусто
function RosBERegisteredScript: string;
// Есть запись об удалении RosBE (прежняя установка): AVersion - её версия
function RosBEPreviousInstall(var AVersion: string): Boolean;
// В папке установлен RosBE (есть RosBE.cmd)
function RosBEInstalledIn(const ADir: string): Boolean;
// SHA-256 файла строчными hex-цифрами; ошибка чтения или CryptoAPI - пусто
function RosFileSha256(const AFile: string): string;
// Запущен установщик RosBE 2.2.1 (занят его мьютекс из .onInit)
function RosBE221InstallerRunning: Boolean;
// 64-битная Windows (unIDE 32-битный и работает под WOW64)
function RosIs64BitWindows: Boolean;
// Параметры 7z.exe: распаковать установщик AInstaller в ADestDir так, как
// ставит установщик по умолчанию - без своих служебных папок ($PLUGINSDIR,
// $DESKTOP), деинсталлятора и компилятора AMD64 (он в установщике выключен)
function RosExtractArgs(const AInstaller, ADestDir: string): string;
// Скачать AUrl в AFile. Ошибка или остановка - False и текст в AError.
function RosDownload(const AUrl, AFile: string; AOnProgress: TRosStepEvent;
                     var AError: string): Boolean;
// Запустить установщик и дождаться его. Запрос UAC отклонён, не
// запустился или остановлен - False и текст в AError.
function RosRunInstaller(const AExe, AParams: string; AOnWait: TRosStepEvent;
                         var AExitCode: DWORD; var AError: string): Boolean;

implementation

const
  RosBE221Mutex = 'RosBE-v2.2.1-Installer';
  // CryptoAPI (wincrypt.h): в Windows.pas Delphi 7 этих объявлений нет
  PROV_RSA_AES = 24;
  CRYPT_VERIFYCONTEXT = $F0000000;
  CALG_SHA_256 = $0000800C;
  HP_HASHVAL = 2;

type
  HCRYPTPROV = Cardinal;
  HCRYPTHASH = Cardinal;

function CryptAcquireContext(var phProv: HCRYPTPROV; pszContainer,
  pszProvider: PChar; dwProvType, dwFlags: DWORD): BOOL; stdcall;
  external advapi32 name 'CryptAcquireContextA';
function CryptReleaseContext(hProv: HCRYPTPROV; dwFlags: DWORD): BOOL;
  stdcall; external advapi32 name 'CryptReleaseContext';
function CryptCreateHash(hProv: HCRYPTPROV; Algid: Cardinal; hKey: Cardinal;
  dwFlags: DWORD; var phHash: HCRYPTHASH): BOOL; stdcall;
  external advapi32 name 'CryptCreateHash';
function CryptHashData(hHash: HCRYPTHASH; pbData: Pointer; dwDataLen,
  dwFlags: DWORD): BOOL; stdcall; external advapi32 name 'CryptHashData';
function CryptGetHashParam(hHash: HCRYPTHASH; dwParam: DWORD; pbData: Pointer;
  var pdwDataLen: DWORD; dwFlags: DWORD): BOOL; stdcall;
  external advapi32 name 'CryptGetHashParam';
function CryptDestroyHash(hHash: HCRYPTHASH): BOOL; stdcall;
  external advapi32 name 'CryptDestroyHash';

const
  RosBEAppPathKey = 'Software\Microsoft\Windows\CurrentVersion\App Paths\' +
                    'RosBE.cmd';
  RosBEUninstallKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\' +
                      'ReactOS Build Environment';

function RosBE221DefaultDir: string;
begin
  Result := 'C:\RosBE';
end;

// Значение ключа реестра; ключа или значения нет - пусто
function ReadRegValue(ARoot: HKEY; const AKey, AName: string): string;
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := TRegistry.Create;
  try
    Reg.RootKey := ARoot;
    if Reg.OpenKeyReadOnly(AKey) then
    try
      if Reg.ValueExists(AName) then
        Result := Reg.ReadString(AName);
    finally
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

function RosBERegisteredScript: string;
begin
  Result := Trim(ReadRegValue(HKEY_CURRENT_USER, RosBEAppPathKey, ''));
  // Значение могут записать в кавычках
  if (Length(Result) > 1) and (Result[1] = '"') then
    Result := Copy(Result, 2, Length(Result) - 2);
  if (Result <> '') and not FileExists(Result) then
    Result := '';
end;

function RosBEPreviousInstall(var AVersion: string): Boolean;
var
  Uninstall: string;
begin
  AVersion := '';
  Uninstall := ReadRegValue(HKEY_CURRENT_USER, RosBEUninstallKey,
                            'UninstallString');
  if Uninstall <> '' then
    AVersion := ReadRegValue(HKEY_CURRENT_USER, RosBEUninstallKey,
                             'DisplayVersion')
  else
  begin
    Uninstall := ReadRegValue(HKEY_LOCAL_MACHINE, RosBEUninstallKey,
                              'UninstallString');
    AVersion := ReadRegValue(HKEY_LOCAL_MACHINE, RosBEUninstallKey,
                             'DisplayVersion');
  end;
  Result := Uninstall <> '';
end;

function RosFileSha256(const AFile: string): string;
const
  ChunkSize = 65536;
var
  Provider: HCRYPTPROV;
  Hash: HCRYPTHASH;
  Input: TFileStream;
  Buffer: array[0..ChunkSize - 1] of Byte;
  Digest: array[0..31] of Byte;
  BytesRead: Integer;
  DigestLen: DWORD;
  Idx: Integer;
  HashOk: Boolean;
begin
  Result := '';
  if not FileExists(AFile) then
    Exit;
  if not CryptAcquireContext(Provider, nil, nil, PROV_RSA_AES,
                             CRYPT_VERIFYCONTEXT) then
    Exit;
  try
    if not CryptCreateHash(Provider, CALG_SHA_256, 0, 0, Hash) then
      Exit;
    try
      try
        Input := TFileStream.Create(AFile, fmOpenRead or fmShareDenyWrite);
      except
        Exit;
      end;
      HashOk := True;
      try
        repeat
          BytesRead := Input.Read(Buffer, ChunkSize);
          if (BytesRead > 0) and
             not CryptHashData(Hash, @Buffer, BytesRead, 0) then
            HashOk := False;
        until (BytesRead <= 0) or not HashOk;
      finally
        Input.Free;
      end;
      DigestLen := SizeOf(Digest);
      if HashOk and CryptGetHashParam(Hash, HP_HASHVAL, @Digest, DigestLen, 0)
         and (DigestLen = SizeOf(Digest)) then
        for Idx := 0 to High(Digest) do
          Result := Result + LowerCase(IntToHex(Digest[Idx], 2));
    finally
      CryptDestroyHash(Hash);
    end;
  finally
    CryptReleaseContext(Provider, 0);
  end;
end;

function RosBE221InstallerRunning: Boolean;
var
  Mutex: THandle;
begin
  // Мьютекс создаёт установщик с правами администратора: обычному процессу
  // OpenMutex может ответить "доступ запрещён" - это тоже значит "есть"
  Mutex := OpenMutex(SYNCHRONIZE, False, RosBE221Mutex);
  if Mutex <> 0 then
  begin
    CloseHandle(Mutex);
    Result := True;
  end
  else
    Result := GetLastError = ERROR_ACCESS_DENIED;
end;

function RosIs64BitWindows: Boolean;
type
  TIsWow64Process = function(hProcess: THandle;
                             var Wow64Process: BOOL): BOOL; stdcall;
var
  IsWow64Proc: TIsWow64Process;
  Wow64: BOOL;
begin
  Result := False;
  // IsWow64Process есть не во всех Windows и не объявлена в Delphi 7
  @IsWow64Proc := GetProcAddress(GetModuleHandle(kernel32),
                                 'IsWow64Process');
  if Assigned(IsWow64Proc) and IsWow64Proc(GetCurrentProcess, Wow64) then
    Result := Wow64;
end;

function RosExtractArgs(const AInstaller, ADestDir: string): string;
begin
  // -bd - без индикатора процентов: вывод идёт в журнал построчно
  Result := 'x -y -bd -o"' + ExcludeTrailingPathDelimiter(ADestDir) +
            '" "' + AInstaller + '" -x!$PLUGINSDIR -x!$DESKTOP ' +
            '-x!Uninstall.exe -x!amd64';
end;

function RosBEInstalledIn(const ADir: string): Boolean;
begin
  Result := (Trim(ADir) <> '') and
            FileExists(IncludeTrailingPathDelimiter(Trim(ADir)) + RosBEScript);
end;

function RosDownload(const AUrl, AFile: string; AOnProgress: TRosStepEvent;
                     var AError: string): Boolean;
const
  ChunkSize = 65536;
var
  Session, Request: HINTERNET;
  Buffer: array[0..ChunkSize - 1] of Byte;
  BytesRead, InfoLen, InfoIndex, StatusCode, TotalSize, DoneSize: DWORD;
  Output: TFileStream;
  PartFile: string;
begin
  Result := False;
  AError := '';
  PartFile := AFile + '.part';
  Session := InternetOpen('unIDE', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Session = nil then
  begin
    AError := 'WinINet: InternetOpen, код ' + IntToStr(GetLastError);
    Exit;
  end;
  try
    Request := InternetOpenUrl(Session, PChar(AUrl), nil, 0,
                               INTERNET_FLAG_RELOAD or
                               INTERNET_FLAG_NO_CACHE_WRITE, 0);
    if Request = nil then
    begin
      AError := 'не удалось соединиться (код ' + IntToStr(GetLastError) +
                '). На Windows 7 проверьте, что в Свойствах обозревателя ' +
                '(Internet Explorer) - Дополнительно включён TLS 1.2';
      Exit;
    end;
    try
      StatusCode := 0;
      InfoLen := SizeOf(StatusCode);
      InfoIndex := 0;
      if HttpQueryInfo(Request, HTTP_QUERY_STATUS_CODE or
                       HTTP_QUERY_FLAG_NUMBER, @StatusCode, InfoLen,
                       InfoIndex) and (StatusCode <> 200) then
      begin
        AError := 'сервер ответил кодом ' + IntToStr(StatusCode);
        Exit;
      end;
      TotalSize := 0;
      InfoLen := SizeOf(TotalSize);
      InfoIndex := 0;
      if not HttpQueryInfo(Request, HTTP_QUERY_CONTENT_LENGTH or
                           HTTP_QUERY_FLAG_NUMBER, @TotalSize, InfoLen,
                           InfoIndex) then
        TotalSize := 0;

      // Скачивается в .part: оборванная загрузка не выглядит готовым файлом
      Output := TFileStream.Create(PartFile, fmCreate);
      try
        DoneSize := 0;
        repeat
          BytesRead := 0;
          if not InternetReadFile(Request, @Buffer, ChunkSize, BytesRead) then
          begin
            AError := 'чтение прервалось (код ' + IntToStr(GetLastError) + ')';
            Exit;
          end;
          if BytesRead > 0 then
          begin
            Output.WriteBuffer(Buffer, BytesRead);
            Inc(DoneSize, BytesRead);
          end;
          if Assigned(AOnProgress) and not AOnProgress(DoneSize, TotalSize) then
          begin
            AError := 'остановлено';
            Exit;
          end;
        until BytesRead = 0;
      finally
        Output.Free;
      end;
      if (TotalSize > 0) and (DoneSize <> TotalSize) then
      begin
        AError := Format('получено %d байт из %d', [DoneSize, TotalSize]);
        Exit;
      end;
      if FileExists(AFile) and not DeleteFile(AFile) then
      begin
        AError := 'не удалось заменить ' + AFile;
        Exit;
      end;
      if not RenameFile(PartFile, AFile) then
      begin
        AError := 'не удалось переименовать ' + PartFile;
        Exit;
      end;
      Result := True;
    finally
      InternetCloseHandle(Request);
      if not Result then
        DeleteFile(PartFile);
    end;
  finally
    InternetCloseHandle(Session);
  end;
end;

function RosRunInstaller(const AExe, AParams: string; AOnWait: TRosStepEvent;
                         var AExitCode: DWORD; var AError: string): Boolean;
var
  ExecInfo: TShellExecuteInfo;
  WaitTicks: Cardinal;
begin
  Result := False;
  AError := '';
  AExitCode := 0;
  FillChar(ExecInfo, SizeOf(ExecInfo), 0);
  ExecInfo.cbSize := SizeOf(ExecInfo);
  ExecInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  // ShellExecuteEx, а не CreateProcess: установщик требует прав
  // администратора, и только так Windows покажет запрос UAC
  ExecInfo.lpVerb := 'open';
  ExecInfo.lpFile := PChar(AExe);
  ExecInfo.lpParameters := PChar(AParams);
  ExecInfo.nShow := SW_SHOWNORMAL;
  if not ShellExecuteEx(@ExecInfo) then
  begin
    if GetLastError = ERROR_CANCELLED then
      AError := 'установка отменена в запросе Windows (UAC)'
    else
      AError := 'установщик не запустился (код ' + IntToStr(GetLastError) + ')';
    Exit;
  end;
  if ExecInfo.hProcess = 0 then
  begin
    AError := 'нет описателя процесса установщика';
    Exit;
  end;
  try
    WaitTicks := 0;
    while WaitForSingleObject(ExecInfo.hProcess, 100) = WAIT_TIMEOUT do
    begin
      Inc(WaitTicks);
      if Assigned(AOnWait) and not AOnWait(WaitTicks, 0) then
      begin
        AError := 'ожидание установщика прервано (установщик продолжает ' +
                  'работу)';
        Exit;
      end;
    end;
    GetExitCodeProcess(ExecInfo.hProcess, AExitCode);
    Result := True;
  finally
    CloseHandle(ExecInfo.hProcess);
  end;
end;

end.
