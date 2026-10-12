unit RunConsole;

// Запуск консольной программы из среды так, чтобы её окно не закрывалось
// сразу после конца (ошибка RapidQ "Exception ... Cannot open file" и т.п.
// иначе мелькает и пропадает), и чтение текста этого окна для лога.
//
// Программа запускается через cmd: "<exe>" & echo. & pause. Консоль живёт,
// пока cmd ждёт клавишу. cmd и программа - в одном job object: по нему
// видно, что сама программа закончилась (в job остался один cmd), и
// Program reset снимает обоих.
//
// Текст окна читается так: на время чтения среда подключается к консоли
// программы (AttachConsole), читает буфер через CONOUT$ и отключается
// (FreeConsole). Пока подключена, Ctrl+C этой консоли среда не получает.

interface

uses
  Windows, SysUtils, Classes;

type
  TRunConsole = class
  private
    FExe: string;
    FPid: DWORD;
    FProcess: THandle;     // свой дескриптор cmd (копия)
    FJob: THandle;         // 0 - job не создан, тогда только cmd
    FText: string;         // последний прочитанный текст окна
    FProgramDone: Boolean; // сама программа закончилась, cmd ждёт клавишу
    FLogged: Boolean;
    function ReadText(var AText: string): Boolean;
    function ProgramRunning: Boolean;
  public
    constructor Create(const AExe: string; AProcess: THandle; APid: DWORD;
      AJob: THandle);
    destructor Destroy; override;
    // Опрос по таймеру. True - программа только что закончилась (или cmd
    // закрыли раньше), текст для лога - в Text, и больше True не будет.
    function Poll: Boolean;
    function Finished: Boolean;
    procedure Kill;
    property Exe: string read FExe;
    property Text: string read FText;
    property Logged: Boolean read FLogged write FLogged;
  end;

// Консольная ли программа (подсистема в заголовке PE)
function ExeIsConsole(const AExe: string): Boolean;

// Запустить консольную программу с паузой в конце. AProcess - дескриптор
// cmd для списка запущенных программ (его закрывает вызывающий), ACon -
// объект для чтения окна. False - не запустилась, ошибка в AError.
function RunConsoleStart(const AExe, ADir: string; var AProcess: THandle;
  var ACon: TRunConsole; var AError: string): Boolean;

// Убрать строку "pause" (последняя непустая, кончается на ". . .") и
// пустые строки в конце
function ConsoleTrimPause(const AText: string): string;

implementation

const
  ConsoleMaxLines = 300;   // в лог - не больше последних строк окна
  ImageSubsystemConsole = 3;
  JobBasicAccounting = 1;

type
  TJobAccounting = record
    TotalUserTime: Int64;
    TotalKernelTime: Int64;
    ThisPeriodTotalUserTime: Int64;
    ThisPeriodTotalKernelTime: Int64;
    TotalPageFaultCount: DWORD;
    TotalProcesses: DWORD;
    ActiveProcesses: DWORD;
    TotalTerminatedProcesses: DWORD;
  end;

  TAttachConsole = function(APid: DWORD): BOOL; stdcall;

function RcCreateJobObject(lpJobAttributes: Pointer; lpName: PChar): THandle;
  stdcall; external kernel32 name 'CreateJobObjectA';
function RcAssignProcessToJobObject(hJob, hProcess: THandle): BOOL;
  stdcall; external kernel32 name 'AssignProcessToJobObject';
function RcTerminateJobObject(hJob: THandle; uExitCode: UINT): BOOL;
  stdcall; external kernel32 name 'TerminateJobObject';
function RcQueryInformationJobObject(hJob: THandle; JobInfoClass: Integer;
  lpJobInfo: Pointer; cbJobInfoLength: DWORD; lpReturnLength: PDWORD): BOOL;
  stdcall; external kernel32 name 'QueryInformationJobObject';

var
  AttachConsoleFn: TAttachConsole = nil;
  AttachLoaded: Boolean = False;

function GetAttachConsole: TAttachConsole;
begin
  if not AttachLoaded then
  begin
    AttachLoaded := True;
    @AttachConsoleFn := GetProcAddress(GetModuleHandle(kernel32),
                                       'AttachConsole');
  end;
  Result := AttachConsoleFn;
end;

function ExeIsConsole(const AExe: string): Boolean;
var
  Stream: TFileStream;
  PeOfs: Longint;
  Sign: DWORD;
  Subsystem: Word;
begin
  Result := False;
  try
    Stream := TFileStream.Create(AExe, fmOpenRead or fmShareDenyNone);
    try
      Stream.Position := $3C;
      if Stream.Read(PeOfs, SizeOf(PeOfs)) <> SizeOf(PeOfs) then
        Exit;
      Stream.Position := PeOfs;
      if (Stream.Read(Sign, SizeOf(Sign)) <> SizeOf(Sign)) or
         (Sign <> $00004550) then   // 'PE'#0#0
        Exit;
      // Подсистема: 4 (подпись) + 20 (файловый заголовок) + 68 в
      // необязательном - одинаково для PE32 и PE32+
      Stream.Position := PeOfs + 4 + 20 + 68;
      if Stream.Read(Subsystem, SizeOf(Subsystem)) <> SizeOf(Subsystem) then
        Exit;
      Result := Subsystem = ImageSubsystemConsole;
    finally
      Stream.Free;
    end;
  except
    Result := False;
  end;
end;

function RunConsoleStart(const AExe, ADir: string; var AProcess: THandle;
  var ACon: TRunConsole; var AError: string): Boolean;
var
  ComSpec, Cmd: string;
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  Job: THandle;
begin
  Result := False;
  AProcess := 0;
  ACon := nil;
  AError := '';
  SetLength(ComSpec, MAX_PATH);
  SetLength(ComSpec, Windows.GetEnvironmentVariable('ComSpec', PChar(ComSpec),
                                                    MAX_PATH));
  if (ComSpec = '') or (Length(ComSpec) >= MAX_PATH) then
    ComSpec := 'cmd.exe';
  // /s: cmd снимает только внешние кавычки, путь exe остаётся в своих
  Cmd := '"' + ComSpec + '" /d /s /c ""' + AExe + '" & echo. & pause"';
  FillChar(StartInfo, SizeOf(StartInfo), 0);
  StartInfo.cb := SizeOf(StartInfo);
  if not CreateProcess(nil, PChar(Cmd), nil, nil, False,
                       CREATE_NEW_CONSOLE or CREATE_SUSPENDED, nil,
                       PChar(ADir), StartInfo, ProcInfo) then
  begin
    AError := SysErrorMessage(GetLastError);
    Exit;
  end;
  // Среда сама в job (запущена из другой среды) - на Windows 7 второй job
  // не назначить; тогда без него: конец программы виден по закрытию cmd
  Job := RcCreateJobObject(nil, nil);
  if (Job <> 0) and not RcAssignProcessToJobObject(Job, ProcInfo.hProcess) then
  begin
    CloseHandle(Job);
    Job := 0;
  end;
  ResumeThread(ProcInfo.hThread);
  CloseHandle(ProcInfo.hThread);
  AProcess := ProcInfo.hProcess;
  ACon := TRunConsole.Create(AExe, ProcInfo.hProcess, ProcInfo.dwProcessId, Job);
  Result := True;
end;

function ConsoleTrimPause(const AText: string): string;
var
  Lines: TStringList;
  Last: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    while (Lines.Count > 0) and (Trim(Lines[Lines.Count - 1]) = '') do
      Lines.Delete(Lines.Count - 1);
    if Lines.Count > 0 then
    begin
      Last := TrimRight(Lines[Lines.Count - 1]);
      if (Length(Last) >= 5) and (Copy(Last, Length(Last) - 4, 5) = '. . .') then
        Lines.Delete(Lines.Count - 1);
    end;
    while (Lines.Count > 0) and (Trim(Lines[Lines.Count - 1]) = '') do
      Lines.Delete(Lines.Count - 1);
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

{ TRunConsole }

constructor TRunConsole.Create(const AExe: string; AProcess: THandle;
  APid: DWORD; AJob: THandle);
begin
  inherited Create;
  FExe := AExe;
  FPid := APid;
  FJob := AJob;
  if not DuplicateHandle(GetCurrentProcess, AProcess, GetCurrentProcess,
                         @FProcess, 0, False, DUPLICATE_SAME_ACCESS) then
    FProcess := 0;
end;

destructor TRunConsole.Destroy;
begin
  if FProcess <> 0 then
    CloseHandle(FProcess);
  if FJob <> 0 then
    CloseHandle(FJob);
  inherited Destroy;
end;

function TRunConsole.Finished: Boolean;
begin
  Result := (FProcess = 0) or
            (WaitForSingleObject(FProcess, 0) <> WAIT_TIMEOUT);
end;

// В job больше одного процесса - программа ещё идёт (второй - она сама).
// Без job не узнать: считаем, что идёт, пока жив cmd.
function TRunConsole.ProgramRunning: Boolean;
var
  Info: TJobAccounting;
begin
  Result := True;
  if FJob = 0 then
    Exit;
  FillChar(Info, SizeOf(Info), 0);
  if not RcQueryInformationJobObject(FJob, JobBasicAccounting, @Info,
                                     SizeOf(Info), nil) then
    Exit;
  // Пока cmd не запустил программу, в job он один
  if Info.TotalProcesses < 2 then
    Exit;
  Result := Info.ActiveProcesses > 1;
end;

function TRunConsole.ReadText(var AText: string): Boolean;
var
  Attach: TAttachConsole;
  ConOut: THandle;
  BufInfo: TConsoleScreenBufferInfo;
  Cols, FirstRow, RowCount, Row: Integer;
  Chars: WideString;
  ReadCount: DWORD;
  Origin: TCoord;
  Lines: TStringList;
begin
  Result := False;
  // Со скобками: без них Delphi присваивает саму функцию GetAttachConsole
  Attach := GetAttachConsole();
  if not Assigned(Attach) then
    Exit;
  // Своей консоли у среды нет; если вдруг есть - не трогаем
  if not Attach(FPid) then
    Exit;
  SetConsoleCtrlHandler(nil, True);
  try
    ConOut := CreateFile('CONOUT$', GENERIC_READ or GENERIC_WRITE,
                         FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                         OPEN_EXISTING, 0, 0);
    if ConOut = INVALID_HANDLE_VALUE then
      Exit;
    try
      if not GetConsoleScreenBufferInfo(ConOut, BufInfo) then
        Exit;
      Cols := BufInfo.dwSize.X;
      RowCount := BufInfo.dwCursorPosition.Y + 1;
      FirstRow := 0;
      if RowCount > ConsoleMaxLines then
      begin
        FirstRow := RowCount - ConsoleMaxLines;
        RowCount := ConsoleMaxLines;
      end;
      if (Cols <= 0) or (RowCount <= 0) then
        Exit;
      SetLength(Chars, Cols * RowCount);
      Origin.X := 0;
      Origin.Y := FirstRow;
      ReadCount := 0;
      if not ReadConsoleOutputCharacterW(ConOut, PWideChar(Chars),
                                         Length(Chars), Origin, ReadCount) then
        Exit;
      Lines := TStringList.Create;
      try
        for Row := 0 to RowCount - 1 do
          Lines.Add(TrimRight(string(Copy(Chars, Row * Cols + 1, Cols))));
        while (Lines.Count > 0) and (Lines[Lines.Count - 1] = '') do
          Lines.Delete(Lines.Count - 1);
        AText := Lines.Text;
      finally
        Lines.Free;
      end;
      Result := True;
    finally
      CloseHandle(ConOut);
    end;
  finally
    FreeConsole;
    SetConsoleCtrlHandler(nil, False);
  end;
end;

function TRunConsole.Poll: Boolean;
var
  NewText: string;
begin
  Result := False;
  if FLogged then
    Exit;
  if Finished then
  begin
    // cmd закрыт (клавиша, крестик, Program reset) - что успели прочитать
    FProgramDone := True;
    Result := True;
    Exit;
  end;
  if FProgramDone then
    Exit;
  // С job конец программы виден сразу - окно читается один раз, после
  // него. Без job - на каждом опросе: после закрытия cmd читать нечего.
  if FJob = 0 then
  begin
    if ReadText(NewText) then
      FText := NewText;
    Exit;
  end;
  if not ProgramRunning then
  begin
    // Программа вышла, cmd ждёт клавишу: окно дописано
    if ReadText(NewText) then
      FText := NewText;
    FProgramDone := True;
    Result := True;
  end;
end;

procedure TRunConsole.Kill;
begin
  if FJob <> 0 then
    RcTerminateJobObject(FJob, 1)
  else if FProcess <> 0 then
    TerminateProcess(FProcess, 1);
end;

end.
