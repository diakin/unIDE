unit RosTools;

// ---------------------------------------------------------------------------
//  Инструменты сборки ReactOS: скачивание и установка RosBE. Без VCL.
//
//  RosBE 2.2.1 (для reactosVG14) - установщик NSIS 3.05 с SourceForge,
//  77 584 546 байт. Установщик просит права администратора (в манифесте
//  requireAdministrator) - Windows покажет запрос UAC. Тихая установка:
//  /S /D=<папка>; /D - последним и без кавычек, даже с пробелами в пути.
//  После установки в папке лежит RosBE.cmd - скрипт окружения проекта
//  (ReactOS_EnvScript, см. RosProj).
//
//  Папка по умолчанию - %LOCALAPPDATA%\RosBE\2.2.1: писать туда можно без
//  прав администратора, рядом - RosBE для LiberNT
//  (%LOCALAPPDATA%\RosBE\pkgs\<версия>, его ищет configure.cmd LiberNT).
//
//  Скачивание - WinINet (InternetOpenUrl): переадресации SourceForge на
//  зеркало он проходит сам. HTTPS на Windows 7 идёт через настройки
//  Internet Explorer: без TLS 1.2 в Свойствах обозревателя SourceForge не
//  ответит - тогда текст ошибки говорит об этом.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes, WinInet, ShellAPI;

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

// %LOCALAPPDATA%\RosBE\2.2.1, без \ в конце
function RosBE221DefaultDir: string;
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

function RosBE221DefaultDir: string;
var
  EnvBuf: array[0..MAX_PATH] of Char;
begin
  Result := '';
  if Windows.GetEnvironmentVariable(PChar('LOCALAPPDATA'), EnvBuf,
                                    SizeOf(EnvBuf)) > 0 then
    Result := EnvBuf;
  if Result = '' then
    Result := 'C:';
  Result := IncludeTrailingPathDelimiter(Result) + 'RosBE\2.2.1';
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
