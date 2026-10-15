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
//      код - при уже запущенном установщике;
//    - после установки HKCU\Software\Microsoft\Windows\CurrentVersion\
//      App Paths\RosBE.cmd (значение по умолчанию) = <папка>\RosBE.cmd.
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
  RosBEScript = 'RosBE.cmd';

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
// Скачать AUrl в AFile. Ошибка или остановка - False и текст в AError.
function RosDownload(const AUrl, AFile: string; AOnProgress: TRosStepEvent;
                     var AError: string): Boolean;
// Запустить установщик и дождаться его. Запрос UAC отклонён, не
// запустился или остановлен - False и текст в AError.
function RosRunInstaller(const AExe, AParams: string; AOnWait: TRosStepEvent;
                         var AExitCode: DWORD; var AError: string): Boolean;

implementation

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
