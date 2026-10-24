unit FarVolumes;

// ---------------------------------------------------------------------------
//  Сведения о томах для меню дисков unIDE FAR (Alt+F1 / Alt+F2):
//
//  - номер тома (Том #), состояние и сведения (загрузочный, системный,
//    скрытый) - из diskpart (list volume), как их показывает diskpart.
//    diskpart требует прав администратора: unIDE запущен без них -
//    CreateProcess отвечает ERROR_ELEVATION_REQUIRED (740), номеров нет.
//    Запрос - в своём потоке (diskpart отвечает секунду-две), один раз за
//    открытие FAR; вывод - в кодировке OEM;
//  - тома без буквы (системные, скрытые разделы, папки-точки
//    подключения) - FindFirstVolumeW / GetVolumePathNamesForVolumeNameW:
//    метка, файловая система, размер; работает и без прав администратора;
//  - размер в виде FAR: '476,14 G', '1,82 T' (FarSizeShort).
//
//  Разбор вывода diskpart не зависит от языка: колонки - по строке из
//  дефисов под заголовком, номер тома - число в конце первой колонки.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes;

type
  TFarVolume = record
    Number: Integer;          // Том # (diskpart); -1 - неизвестен
    Letter: WideChar;         // #0 - без буквы
    MountPath: WideString;    // папка подключения (тома без буквы) или ''
    VolLabel: WideString;
    FileSys: WideString;
    TypeText: WideString;     // тип из diskpart (Раздел, Сменный, ...)
    SizeText: WideString;     // размер строкой (diskpart или FarSizeShort)
    Status: WideString;       // состояние (diskpart)
    Info: WideString;         // сведения (diskpart)
    Total: Int64;
    Free: Int64;
    HasSize: Boolean;
  end;
  TFarVolumes = array of TFarVolume;

  // diskpart list volume в своём потоке
  TFarDiskpartThread = class(TThread)
  private
    FOutput: WideString;
    FErrorCode: DWORD;        // 0 - отработал; 740 - нужны права администратора
    FFinished: Integer;
    function GetFinished: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create;
    property Output: WideString read FOutput;
    property ErrorCode: DWORD read FErrorCode;
    property Finished: Boolean read GetFinished;
  end;

// Вывод diskpart (list volume) -> тома с номерами
procedure FarParseDiskpart(const AText: WideString; var AVolumes: TFarVolumes);
// Тома без буквы диска (через API Windows)
procedure FarNoLetterVolumes(var AVolumes: TFarVolumes);
// Размер как в FAR: '476,14 G'
function FarSizeShort(ABytes: Int64): WideString;

const
  FarErrorElevation = 740;    // ERROR_ELEVATION_REQUIRED

implementation

const
  FvCreateNoWindow = $08000000;
  FvStartfUseStdHandles = $00000100;
  FvStartfUseShowWindow = $00000001;
  FvCpOem = 1;                // CP_OEMCP

type
  TFvStartupInfoW = record
    cb: DWORD;
    lpReserved, lpDesktop, lpTitle: PWideChar;
    dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars,
    dwFillAttribute, dwFlags: DWORD;
    wShowWindow, cbReserved2: Word;
    lpReserved2: Pointer;
    hStdInput, hStdOutput, hStdError: THandle;
  end;
  TFvProcessInfo = record
    hProcess, hThread: THandle;
    dwProcessId, dwThreadId: DWORD;
  end;
  TFvSecurity = record
    nLength: DWORD;
    lpSecurityDescriptor: Pointer;
    bInheritHandle: BOOL;
  end;
  TFvGetPathNames = function(AVolumeName, APathNames: PWideChar;
    ABufferLength: DWORD; var AReturnLength: DWORD): BOOL; stdcall;
  TFvFindFirstVolume = function(AVolumeName: PWideChar;
    ABufferLength: DWORD): THandle; stdcall;
  TFvFindNextVolume = function(AFindHandle: THandle; AVolumeName: PWideChar;
    ABufferLength: DWORD): BOOL; stdcall;
  TFvFindVolumeClose = function(AFindHandle: THandle): BOOL; stdcall;

function FvCreateProcess(AAppName, ACmdLine: PWideChar;
  AProcAttr, AThreadAttr: Pointer; AInherit: BOOL; AFlags: DWORD;
  AEnv: Pointer; ACurDir: PWideChar; var AStartup: TFvStartupInfoW;
  var AProcInfo: TFvProcessInfo): BOOL; stdcall;
  external 'kernel32.dll' name 'CreateProcessW';
function FvCreatePipe(var ARead, AWrite: THandle; AAttr: Pointer;
  ASize: DWORD): BOOL; stdcall; external 'kernel32.dll' name 'CreatePipe';
function FvPeekPipe(APipe: THandle; ABuffer: Pointer; ASize: DWORD;
  ARead, AAvail, ALeft: PDWORD): BOOL; stdcall;
  external 'kernel32.dll' name 'PeekNamedPipe';
function FvReadFile(AFile: THandle; ABuffer: Pointer; ACount: DWORD;
  var ARead: DWORD; AOverlapped: Pointer): BOOL; stdcall;
  external 'kernel32.dll' name 'ReadFile';
function FvSetHandleInfo(AHandle: THandle; AMask, AFlags: DWORD): BOOL;
  stdcall; external 'kernel32.dll' name 'SetHandleInformation';
function FvTerminate(AProcess: THandle; ACode: UINT): BOOL; stdcall;
  external 'kernel32.dll' name 'TerminateProcess';
function FvMultiToWide(ACodePage: UINT; AFlags: DWORD; AMulti: PAnsiChar;
  AMultiLen: Integer; AWide: PWideChar; AWideLen: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'MultiByteToWideChar';
function FvGetTempPath(ABufferLen: DWORD; ABuffer: PWideChar): DWORD; stdcall;
  external 'kernel32.dll' name 'GetTempPathW';
function FvCreateFile(AFileName: PWideChar; AAccess, AShare: DWORD;
  ASecurity: Pointer; ACreation, AFlags: DWORD;
  ATemplate: THandle): THandle; stdcall;
  external 'kernel32.dll' name 'CreateFileW';
function FvWriteFile(AFile: THandle; ABuffer: Pointer; ACount: DWORD;
  var AWritten: DWORD; AOverlapped: Pointer): BOOL; stdcall;
  external 'kernel32.dll' name 'WriteFile';
function FvDeleteFile(AFileName: PWideChar): BOOL; stdcall;
  external 'kernel32.dll' name 'DeleteFileW';
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

procedure FarParseDiskpart(const AText: WideString; var AVolumes: TFarVolumes);
var
  Lines: array of WideString;
  ColStart, ColEnd: array of Integer;
  LinePos, LineEnd, LineIdx, DashLine, CharIdx, ColCount, Count: Integer;
  Line, NumText, Field: WideString;
  Volume: TFarVolume;
  NumPos: Integer;

  function Column(const ALine: WideString; AIndex: Integer): WideString;
  begin
    if AIndex >= ColCount then
      Result := ''
    else if AIndex = ColCount - 1 then
      // Последняя колонка - до конца строки (сведения бывают длиннее)
      Result := FvTrim(Copy(ALine, ColStart[AIndex], MaxInt))
    else
      Result := FvTrim(Copy(ALine, ColStart[AIndex],
        ColEnd[AIndex] - ColStart[AIndex] + 1));
  end;

begin
  SetLength(AVolumes, 0);
  // Строки
  SetLength(Lines, 0);
  LinePos := 1;
  while LinePos <= Length(AText) do
  begin
    LineEnd := LinePos;
    while (LineEnd <= Length(AText)) and (AText[LineEnd] <> #10) do
      Inc(LineEnd);
    SetLength(Lines, Length(Lines) + 1);
    Lines[High(Lines)] := Copy(AText, LinePos, LineEnd - LinePos);
    if (Lines[High(Lines)] <> '') and
       (Lines[High(Lines)][Length(Lines[High(Lines)])] = #13) then
      SetLength(Lines[High(Lines)], Length(Lines[High(Lines)]) - 1);
    LinePos := LineEnd + 1;
  end;
  // Строка из дефисов и пробелов (не меньше трёх групп) - под заголовком
  DashLine := -1;
  for LineIdx := 0 to High(Lines) do
  begin
    Line := FvTrim(Lines[LineIdx]);
    if (Length(Line) >= 10) and (Line[1] = '-') then
    begin
      ColCount := 0;
      for CharIdx := 1 to Length(Line) do
        if (Line[CharIdx] <> '-') and (Line[CharIdx] <> ' ') then
        begin
          ColCount := -1;
          Break;
        end;
      if ColCount = 0 then
      begin
        DashLine := LineIdx;
        Break;
      end;
    end;
  end;
  if DashLine < 0 then
    Exit;
  Line := Lines[DashLine];
  ColCount := 0;
  SetLength(ColStart, 0);
  SetLength(ColEnd, 0);
  CharIdx := 1;
  while CharIdx <= Length(Line) do
  begin
    if Line[CharIdx] = '-' then
    begin
      SetLength(ColStart, ColCount + 1);
      SetLength(ColEnd, ColCount + 1);
      ColStart[ColCount] := CharIdx;
      while (CharIdx <= Length(Line)) and (Line[CharIdx] = '-') do
        Inc(CharIdx);
      ColEnd[ColCount] := CharIdx - 1;
      Inc(ColCount);
    end
    else
      Inc(CharIdx);
  end;
  if ColCount < 4 then
    Exit;
  Count := 0;
  for LineIdx := DashLine + 1 to High(Lines) do
  begin
    Line := Lines[LineIdx];
    if FvTrim(Line) = '' then
      Continue;
    Field := Column(Line, 0);
    // Номер - число в конце первой колонки ('Том 0', 'Volume 12')
    NumPos := Length(Field);
    while (NumPos >= 1) and (Field[NumPos] >= '0') and (Field[NumPos] <= '9') do
      Dec(NumPos);
    NumText := Copy(Field, NumPos + 1, MaxInt);
    if NumText = '' then
      Continue;
    Volume.Number := StrToIntDef(string(NumText), -1);
    Field := Column(Line, 1);
    if (Length(Field) = 1) and (UpCase(Char(Field[1])) in ['A'..'Z']) then
      Volume.Letter := WideChar(Ord(UpCase(Char(Field[1]))))
    else
      Volume.Letter := #0;
    Volume.MountPath := '';
    Volume.VolLabel := Column(Line, 2);
    Volume.FileSys := Column(Line, 3);
    Volume.TypeText := Column(Line, 4);
    Volume.SizeText := Column(Line, 5);
    Volume.Status := Column(Line, 6);
    Volume.Info := Column(Line, 7);
    Volume.Total := 0;
    Volume.Free := 0;
    Volume.HasSize := False;
    SetLength(AVolumes, Count + 1);
    AVolumes[Count] := Volume;
    Inc(Count);
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
  OnePath, FirstPath: WideString;
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
          Volume.Number := -1;
          Volume.Letter := #0;
          Volume.MountPath := FirstPath;
          Volume.VolLabel := PWideChar(@LabelBuf[0]);
          Volume.FileSys := PWideChar(@FsBuf[0]);
          Volume.TypeText := '';
          Volume.Status := '';
          Volume.Info := '';
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

// ---------------------------------------------------------------------------

constructor TFarDiskpartThread.Create;
begin
  FOutput := '';
  FErrorCode := 0;
  FFinished := 0;
  FreeOnTerminate := False;
  inherited Create(False);
end;

function TFarDiskpartThread.GetFinished: Boolean;
begin
  Result := FFinished <> 0;
end;

procedure TFarDiskpartThread.Execute;
const
  ScriptText: string = 'list volume'#13#10'exit'#13#10;
var
  TempBuf: array[0..MAX_PATH] of WideChar;
  ScriptName, CmdLine: WideString;
  FileHandle, ReadPipe, WritePipe: THandle;
  Written, Avail, ReadCount: DWORD;
  Security: TFvSecurity;
  Startup: TFvStartupInfoW;
  ProcInfo: TFvProcessInfo;
  Buffer: array[0..4095] of AnsiChar;
  RawText, Piece: string;
  WideLen, Waited: Integer;
  Finished: Boolean;
begin
  try
    if FvGetTempPath(MAX_PATH, TempBuf) = 0 then
    begin
      FErrorCode := GetLastError;
      Exit;
    end;
    ScriptName := WideString(PWideChar(@TempBuf[0])) + 'unide_diskpart_' +
      WideString(IntToStr(GetCurrentProcessId)) + '.txt';
    FileHandle := FvCreateFile(PWideChar(ScriptName), GENERIC_WRITE, 0, nil,
      CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if FileHandle = INVALID_HANDLE_VALUE then
    begin
      FErrorCode := GetLastError;
      Exit;
    end;
    Written := 0;
    FvWriteFile(FileHandle, PAnsiChar(ScriptText), Length(ScriptText), Written,
      nil);
    CloseHandle(FileHandle);
    try
      FillChar(Security, SizeOf(Security), 0);
      Security.nLength := SizeOf(Security);
      Security.bInheritHandle := True;
      if not FvCreatePipe(ReadPipe, WritePipe, @Security, 0) then
      begin
        FErrorCode := GetLastError;
        Exit;
      end;
      FvSetHandleInfo(ReadPipe, 1, 0);
      CmdLine := 'diskpart.exe /s "' + ScriptName + '"';
      FillChar(Startup, SizeOf(Startup), 0);
      Startup.cb := SizeOf(Startup);
      Startup.dwFlags := FvStartfUseStdHandles or FvStartfUseShowWindow;
      Startup.wShowWindow := SW_HIDE;
      Startup.hStdInput := 0;
      Startup.hStdOutput := WritePipe;
      Startup.hStdError := WritePipe;
      FillChar(ProcInfo, SizeOf(ProcInfo), 0);
      if not FvCreateProcess(nil, PWideChar(CmdLine), nil, nil, True,
         FvCreateNoWindow, nil, nil, Startup, ProcInfo) then
      begin
        // 740 - unIDE запущен без прав администратора
        FErrorCode := GetLastError;
        CloseHandle(ReadPipe);
        CloseHandle(WritePipe);
        Exit;
      end;
      CloseHandle(WritePipe);
      CloseHandle(ProcInfo.hThread);
      RawText := '';
      Waited := 0;
      try
        repeat
          Finished := WaitForSingleObject(ProcInfo.hProcess, 50) = WAIT_OBJECT_0;
          Inc(Waited, 50);
          while FvPeekPipe(ReadPipe, nil, 0, nil, @Avail, nil) and
                (Avail > 0) do
          begin
            if Avail > SizeOf(Buffer) then
              Avail := SizeOf(Buffer);
            ReadCount := 0;
            if not FvReadFile(ReadPipe, @Buffer[0], Avail, ReadCount, nil) or
               (ReadCount = 0) then
              Break;
            SetString(Piece, PAnsiChar(@Buffer[0]), ReadCount);
            RawText := RawText + Piece;
          end;
          // Больше минуты - что-то не так: прервать
          if not Finished and (Waited > 60000) then
          begin
            FvTerminate(ProcInfo.hProcess, 1);
            Break;
          end;
        until Finished;
      finally
        CloseHandle(ProcInfo.hProcess);
        CloseHandle(ReadPipe);
      end;
      if RawText <> '' then
      begin
        WideLen := FvMultiToWide(FvCpOem, 0, PAnsiChar(RawText),
          Length(RawText), nil, 0);
        SetLength(FOutput, WideLen);
        if WideLen > 0 then
          FvMultiToWide(FvCpOem, 0, PAnsiChar(RawText), Length(RawText),
            PWideChar(FOutput), WideLen);
      end;
    finally
      FvDeleteFile(PWideChar(ScriptName));
    end;
  finally
    InterlockedExchange(FFinished, 1);
  end;
end;

end.
