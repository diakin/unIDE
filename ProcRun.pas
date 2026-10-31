unit ProcRun;

// Запуск внешних программ (шаг 0.2 плана портирования): одно место вместо
// CreateProcess, каналов и ожидания в каждом модуле.
//
// TProcRun - один процесс: строка команды, папка, окно (скрыто / обычное),
// консоль (как у среды / без окна / своя), вывод (в канал - Read, в файл -
// OutputFile), вход (канал - WriteInput / CloseInput, или текст InputText,
// записанный сразу после запуска), окружение (EnvBlockW). Дальше - чтение
// вывода без блокировки, ожидание, снятие, код выхода.
//
// Под Windows - CreateProcess / CreateProcessW и анонимные каналы, как было
// в модулях до этого шага. Не под Windows - TProcess (FPC, модуль Process):
// вывод в канал, вход, ожидание, снятие, код выхода; OutputFile, окно и
// консоль там не действуют.
//
// Delphi 7: без PtrUInt, Exit(значение), inline.

interface

uses
  {$IFDEF MSWINDOWS}Windows,{$ELSE}Process,{$ENDIF} SysUtils, Classes;

type
  // Окно программы (Windows, STARTF_USESHOWWINDOW)
  TProcWindow = (pwDefault, pwHidden, pwNormal, pwMinimized);
  // Консоль: как решит Windows / без окна (CREATE_NO_WINDOW) / своя
  // (CREATE_NEW_CONSOLE)
  TProcConsole = (pcDefault, pcNoWindow, pcNewConsole);

  TProcRun = class
  private
    FStarted: Boolean;
    FExited: Boolean;
    FExitCode: Integer;
    FErrorCode: Integer;
    FErrorText: string;
    FPid: Cardinal;
    {$IFDEF MSWINDOWS}
    FProcess: THandle;
    FOutRead: THandle;    // свой конец канала вывода
    FInWrite: THandle;    // свой конец канала входа
    {$ELSE}
    FProc: TProcess;
    {$ENDIF}
    procedure SetError(ACode: Integer; const AWhat: string);
    procedure CheckExit;
  public
    // Строка команды целиком: '"C:\fbc\fbc.exe" -x a.bas'. CommandLineW,
    // если задана, - вместо неё (CreateProcessW: имена вне кодовой страницы)
    CommandLine: string;
    CommandLineW: WideString;
    // Текущая папка программы; '' - как у среды
    Dir: string;
    DirW: WideString;
    Window: TProcWindow;
    Console: TProcConsole;
    // Вывод и ошибки (stdout + stderr) - в канал, читать Read
    CaptureOutput: Boolean;
    // Вывод и ошибки - в файл (создаётся заново); CaptureOutput не нужен
    OutputFile: string;
    // Вход - канал: WriteInput, CloseInput. InputText - записать сразу
    // после запуска и закрыть (короткий текст, умещается в буфер канала)
    PipeInput: Boolean;
    InputText: string;
    // Размер буфера канала вывода, 0 - по умолчанию системы
    PipeSize: Cardinal;
    // Окружение: блок 'A=1'#0'B=2'#0#0 (Unicode), '' - как у среды
    EnvBlockW: WideString;

    constructor Create;
    destructor Destroy; override;

    // Запустить. False - не запустилась: ErrorCode, ErrorText
    function Start: Boolean;
    // Сколько байт вывода ждёт в канале (без чтения)
    function Available: Cardinal;
    // Дописать в AText то, что есть в канале вывода, не ожидая. Результат -
    // прочитано байт; -1 - канал закрыт (программа вышла и всё прочитано)
    // или вывод не в канал
    function Read(var AText: string): Integer;
    // Записать во вход (PipeInput). False - канал закрыт
    function WriteInput(const AData: string): Boolean;
    // Закрыть вход: для программы - конец ввода
    procedure CloseInput;
    // Ждать конца не дольше AMs (INFINITE - сколько угодно). True - вышла
    function WaitFor(AMs: Cardinal): Boolean;
    function Running: Boolean;
    // Снять программу (только её)
    procedure Terminate(ACode: Cardinal);
    // Снять программу со всеми дочерними (Windows: taskkill /T)
    procedure KillTree;
    // Отдать дескриптор процесса вызывающему (списки запущенных программ
    // в Unit1 хранят его сами): закрывать его теперь ему, объект его не
    // трогает. Не под Windows - 0
    function DetachHandle: THandle;

    property Started: Boolean read FStarted;
    // Код выхода; до выхода - -1
    property ExitCode: Integer read FExitCode;
    property Pid: Cardinal read FPid;
    property ErrorCode: Integer read FErrorCode;
    property ErrorText: string read FErrorText;
    {$IFDEF MSWINDOWS}
    property Handle: THandle read FProcess;
    {$ENDIF}
  end;

// Снять процесс APid со всеми дочерними: taskkill /T /F (есть с Windows XP
// Professional), ждём его не дольше 10 с
procedure ProcKillTree(APid: Cardinal);

// Запустить и забыть: окно программы своё, среда её не ждёт. False - не
// запустилась, текст ошибки - в AError
function ProcLaunch(const ACmdLine, ADir: string; var AError: string): Boolean;

implementation

{$IFDEF MSWINDOWS}

// Объявления W-функций и SetHandleInformation - свои: в Windows.pas
// Delphi 7 части из них нет или они с другими типами параметров
function ProcCreateProcessW(AAppName, ACmdLine: PWideChar;
  AProcAttr, AThreadAttr: Pointer; AInherit: BOOL; AFlags: DWORD;
  AEnv: Pointer; ADir: PWideChar; var AStartup: TStartupInfo;
  var AInfo: TProcessInformation): BOOL; stdcall;
  external 'kernel32.dll' name 'CreateProcessW';
function ProcSetHandleInfo(AHandle: THandle; AMask, AFlags: DWORD): BOOL;
  stdcall; external 'kernel32.dll' name 'SetHandleInformation';

const
  ProcHandleFlagInherit = 1;
  ProcCreateUnicodeEnv = $00000400;
  ProcCreateNoWindow = $08000000;

{$ENDIF}

constructor TProcRun.Create;
begin
  inherited Create;
  FExitCode := -1;
  Window := pwDefault;
  Console := pcDefault;
end;

destructor TProcRun.Destroy;
begin
  {$IFDEF MSWINDOWS}
  if FInWrite <> 0 then
    CloseHandle(FInWrite);
  if FOutRead <> 0 then
    CloseHandle(FOutRead);
  if FProcess <> 0 then
    CloseHandle(FProcess);
  {$ELSE}
  FProc.Free;
  {$ENDIF}
  inherited Destroy;
end;

procedure TProcRun.SetError(ACode: Integer; const AWhat: string);
begin
  FErrorCode := ACode;
  if ACode <> 0 then
    FErrorText := AWhat + ': ' + SysErrorMessage(ACode)
  else
    FErrorText := AWhat;
end;

{$IFDEF MSWINDOWS}

function TProcRun.Start: Boolean;
var
  Security: TSecurityAttributes;
  Startup: TStartupInfo;
  Info: TProcessInformation;
  OutWrite, InRead, FileHandle: THandle;
  Flags: DWORD;
  Inherit: Boolean;
  CmdA, DirA: string;
  CmdW: WideString;
  EnvPtr: Pointer;
  Written: DWORD;
  Ok: BOOL;
begin
  Result := False;
  FErrorCode := 0;
  FErrorText := '';
  if FStarted then
  begin
    SetError(0, 'процесс уже запущен');
    Exit;
  end;

  FillChar(Security, SizeOf(Security), 0);
  Security.nLength := SizeOf(Security);
  Security.bInheritHandle := True;

  OutWrite := 0;
  InRead := 0;
  FileHandle := INVALID_HANDLE_VALUE;
  FillChar(Startup, SizeOf(Startup), 0);
  Startup.cb := SizeOf(Startup);

  if Window <> pwDefault then
  begin
    Startup.dwFlags := Startup.dwFlags or STARTF_USESHOWWINDOW;
    case Window of
      pwHidden: Startup.wShowWindow := SW_HIDE;
      pwMinimized: Startup.wShowWindow := SW_SHOWMINNOACTIVE;
    else
      Startup.wShowWindow := SW_SHOWNORMAL;
    end;
  end;

  // Вывод: файл или канал
  if OutputFile <> '' then
  begin
    FileHandle := CreateFile(PChar(OutputFile), GENERIC_WRITE,
      FILE_SHARE_READ, @Security, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if FileHandle = INVALID_HANDLE_VALUE then
    begin
      SetError(GetLastError, 'файл вывода не создан (' + OutputFile + ')');
      Exit;
    end;
  end
  else if CaptureOutput then
  begin
    if not CreatePipe(FOutRead, OutWrite, @Security, PipeSize) then
    begin
      SetError(GetLastError, 'канал вывода не создан');
      Exit;
    end;
    // Свой конец программа не наследует, иначе канал не закроется с её
    // выходом
    ProcSetHandleInfo(FOutRead, ProcHandleFlagInherit, 0);
  end;

  if PipeInput or (InputText <> '') then
  begin
    if not CreatePipe(InRead, FInWrite, @Security, 0) then
    begin
      SetError(GetLastError, 'канал входа не создан');
      if OutWrite <> 0 then
        CloseHandle(OutWrite);
      if FileHandle <> INVALID_HANDLE_VALUE then
        CloseHandle(FileHandle);
      Exit;
    end;
    ProcSetHandleInfo(FInWrite, ProcHandleFlagInherit, 0);
  end;

  Inherit := (OutWrite <> 0) or (InRead <> 0) or
             (FileHandle <> INVALID_HANDLE_VALUE);
  if Inherit then
  begin
    Startup.dwFlags := Startup.dwFlags or STARTF_USESTDHANDLES;
    Startup.hStdInput := InRead;
    if FileHandle <> INVALID_HANDLE_VALUE then
    begin
      Startup.hStdOutput := FileHandle;
      Startup.hStdError := FileHandle;
    end
    else
    begin
      Startup.hStdOutput := OutWrite;
      Startup.hStdError := OutWrite;
    end;
  end;

  Flags := 0;
  case Console of
    pcNoWindow: Flags := ProcCreateNoWindow;
    pcNewConsole: Flags := CREATE_NEW_CONSOLE;
  end;

  FillChar(Info, SizeOf(Info), 0);
  if (CommandLineW <> '') or (DirW <> '') or (EnvBlockW <> '') then
  begin
    // Строку команды CreateProcessW может менять - своя копия (WideString
    // копируется при присваивании)
    if CommandLineW <> '' then
      CmdW := CommandLineW
    else
      CmdW := WideString(CommandLine);
    EnvPtr := nil;
    if EnvBlockW <> '' then
    begin
      EnvPtr := PWideChar(EnvBlockW);
      Flags := Flags or ProcCreateUnicodeEnv;
    end;
    if DirW <> '' then
      Ok := ProcCreateProcessW(nil, PWideChar(CmdW), nil, nil, Inherit, Flags,
        EnvPtr, PWideChar(DirW), Startup, Info)
    else if Dir <> '' then
      Ok := ProcCreateProcessW(nil, PWideChar(CmdW), nil, nil, Inherit, Flags,
        EnvPtr, PWideChar(WideString(Dir)), Startup, Info)
    else
      Ok := ProcCreateProcessW(nil, PWideChar(CmdW), nil, nil, Inherit, Flags,
        EnvPtr, nil, Startup, Info);
  end
  else
  begin
    CmdA := CommandLine;
    UniqueString(CmdA);
    DirA := Dir;
    if DirA <> '' then
      Ok := CreateProcess(nil, PChar(CmdA), nil, nil, Inherit, Flags, nil,
        PChar(DirA), Startup, Info)
    else
      Ok := CreateProcess(nil, PChar(CmdA), nil, nil, Inherit, Flags, nil,
        nil, Startup, Info);
  end;

  if not Ok then
    SetError(GetLastError, 'не запустить');

  // Концы, отданные программе, у себя закрываем сразу: иначе чтение не
  // увидит конца вывода, а программа - конца входа
  if OutWrite <> 0 then
    CloseHandle(OutWrite);
  if InRead <> 0 then
    CloseHandle(InRead);
  if FileHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FileHandle);

  if not Ok then
  begin
    if FOutRead <> 0 then
    begin
      CloseHandle(FOutRead);
      FOutRead := 0;
    end;
    if FInWrite <> 0 then
    begin
      CloseHandle(FInWrite);
      FInWrite := 0;
    end;
    Exit;
  end;

  CloseHandle(Info.hThread);
  FProcess := Info.hProcess;
  FPid := Info.dwProcessId;
  FStarted := True;
  Result := True;

  if InputText <> '' then
  begin
    Written := 0;
    WriteFile(FInWrite, PChar(InputText)^, Length(InputText), Written, nil);
    if not PipeInput then
      CloseInput;
  end;
end;

function TProcRun.Available: Cardinal;
var
  Avail: DWORD;
begin
  Result := 0;
  if FOutRead = 0 then
    Exit;
  Avail := 0;
  if PeekNamedPipe(FOutRead, nil, 0, nil, @Avail, nil) then
    Result := Avail;
end;

function TProcRun.Read(var AText: string): Integer;
var
  Buf: array[0..4095] of Char;
  Avail, Want, Got: DWORD;
  OldLen: Integer;
begin
  Result := -1;
  if FOutRead = 0 then
    Exit;
  Result := 0;
  repeat
    Avail := 0;
    // Ошибка - канал закрыт с той стороны и пуст
    if not PeekNamedPipe(FOutRead, nil, 0, nil, @Avail, nil) then
    begin
      if Result = 0 then
        Result := -1;
      Exit;
    end;
    if Avail = 0 then
      Exit;
    Want := Avail;
    if Want > SizeOf(Buf) then
      Want := SizeOf(Buf);
    Got := 0;
    if not ReadFile(FOutRead, Buf, Want, Got, nil) or (Got = 0) then
    begin
      if Result = 0 then
        Result := -1;
      Exit;
    end;
    OldLen := Length(AText);
    SetLength(AText, OldLen + Integer(Got));
    Move(Buf[0], AText[OldLen + 1], Got);
    Inc(Result, Got);
  until False;
end;

function TProcRun.WriteInput(const AData: string): Boolean;
var
  Written: DWORD;
begin
  Result := False;
  if FInWrite = 0 then
    Exit;
  if AData = '' then
  begin
    Result := True;
    Exit;
  end;
  Written := 0;
  Result := WriteFile(FInWrite, PChar(AData)^, Length(AData), Written, nil) and
            (Integer(Written) = Length(AData));
end;

procedure TProcRun.CloseInput;
begin
  if FInWrite <> 0 then
  begin
    CloseHandle(FInWrite);
    FInWrite := 0;
  end;
end;

procedure TProcRun.CheckExit;
var
  Code: DWORD;
begin
  if FExited or (FProcess = 0) then
    Exit;
  if WaitForSingleObject(FProcess, 0) <> WAIT_OBJECT_0 then
    Exit;
  FExited := True;
  Code := 0;
  if GetExitCodeProcess(FProcess, Code) then
    FExitCode := Integer(Code);
end;

function TProcRun.WaitFor(AMs: Cardinal): Boolean;
begin
  Result := FExited;
  if Result or (FProcess = 0) then
    Exit;
  if WaitForSingleObject(FProcess, AMs) = WAIT_OBJECT_0 then
    CheckExit;
  Result := FExited;
end;

function TProcRun.Running: Boolean;
begin
  CheckExit;
  Result := FStarted and (FProcess <> 0) and not FExited;
end;

procedure TProcRun.Terminate(ACode: Cardinal);
begin
  if (FProcess <> 0) and not FExited then
    TerminateProcess(FProcess, ACode);
end;

procedure TProcRun.KillTree;
begin
  if FStarted and (FPid <> 0) and Running then
    ProcKillTree(FPid);
  Terminate(1);
end;

function TProcRun.DetachHandle: THandle;
begin
  Result := FProcess;
  FProcess := 0;
end;

procedure ProcKillTree(APid: Cardinal);
var
  Kill: TProcRun;
begin
  Kill := TProcRun.Create;
  try
    Kill.CommandLine := 'taskkill /T /F /PID ' + IntToStr(APid);
    Kill.Window := pwHidden;
    Kill.Console := pcNoWindow;
    if Kill.Start then
      Kill.WaitFor(10000);
  finally
    Kill.Free;
  end;
end;

{$ELSE}

// Не Windows: TProcess. Строка команды разбирается TProcess (кавычки как в
// оболочке); окно, консоль и OutputFile не действуют

function TProcRun.Start: Boolean;
var
  Options: TProcessOptions;
begin
  Result := False;
  FErrorCode := 0;
  FErrorText := '';
  if FStarted then
  begin
    SetError(0, 'процесс уже запущен');
    Exit;
  end;
  FProc := TProcess.Create(nil);
  if CommandLineW <> '' then
    FProc.CommandLine := UTF8Encode(CommandLineW)
  else
    FProc.CommandLine := CommandLine;
  if DirW <> '' then
    FProc.CurrentDirectory := UTF8Encode(DirW)
  else
    FProc.CurrentDirectory := Dir;
  Options := [];
  if CaptureOutput then
    Options := Options + [poUsePipes, poStderrToOutPut];
  if PipeInput or (InputText <> '') then
    Options := Options + [poUsePipes];
  FProc.Options := Options;
  if PipeSize > 0 then
    FProc.PipeBufferSize := PipeSize;
  try
    FProc.Execute;
  except
    on E: Exception do
    begin
      SetError(0, 'не запустить: ' + E.Message);
      FreeAndNil(FProc);
      Exit;
    end;
  end;
  FPid := FProc.ProcessID;
  FStarted := True;
  Result := True;
  if poUsePipes in Options then
  begin
    if InputText <> '' then
      FProc.Input.Write(InputText[1], Length(InputText));
    if not PipeInput then
      FProc.CloseInput;
  end;
end;

function TProcRun.Available: Cardinal;
begin
  Result := 0;
  if (FProc <> nil) and CaptureOutput and (FProc.Output <> nil) then
    Result := FProc.Output.NumBytesAvailable;
end;

function TProcRun.Read(var AText: string): Integer;
var
  Buf: array[0..4095] of Char;
  Avail, Want, Got, OldLen: Integer;
  WasRunning: Boolean;
begin
  Result := -1;
  if (FProc = nil) or not CaptureOutput or (FProc.Output = nil) then
    Exit;
  // Порядок: сначала узнать, работала ли программа, потом читать - тогда
  // пустой канал у вышедшей программы значит, что всё прочитано
  WasRunning := FProc.Running;
  Result := 0;
  repeat
    Avail := FProc.Output.NumBytesAvailable;
    if Avail <= 0 then
      Break;
    Want := Avail;
    if Want > SizeOf(Buf) then
      Want := SizeOf(Buf);
    Got := FProc.Output.Read(Buf, Want);
    if Got <= 0 then
      Break;
    OldLen := Length(AText);
    SetLength(AText, OldLen + Got);
    Move(Buf[0], AText[OldLen + 1], Got);
    Inc(Result, Got);
  until False;
  if (Result = 0) and not WasRunning then
    Result := -1;
end;

function TProcRun.WriteInput(const AData: string): Boolean;
begin
  Result := False;
  if (FProc = nil) or not PipeInput or (FProc.Input = nil) then
    Exit;
  if AData <> '' then
    Result := FProc.Input.Write(AData[1], Length(AData)) = Length(AData)
  else
    Result := True;
end;

procedure TProcRun.CloseInput;
begin
  if (FProc <> nil) and (FProc.Input <> nil) then
    FProc.CloseInput;
end;

procedure TProcRun.CheckExit;
begin
  if FExited or (FProc = nil) then
    Exit;
  if FProc.Running then
    Exit;
  FExited := True;
  FExitCode := FProc.ExitCode;
end;

function TProcRun.WaitFor(AMs: Cardinal): Boolean;
var
  StartTick: QWord;
begin
  Result := FExited;
  if Result or (FProc = nil) then
    Exit;
  StartTick := GetTickCount64;
  while FProc.Running do
  begin
    if (AMs <> High(Cardinal)) and (GetTickCount64 - StartTick >= AMs) then
      Break;
    Sleep(5);
  end;
  CheckExit;
  Result := FExited;
end;

function TProcRun.Running: Boolean;
begin
  CheckExit;
  Result := FStarted and (FProc <> nil) and not FExited;
end;

procedure TProcRun.Terminate(ACode: Cardinal);
begin
  if (FProc <> nil) and not FExited then
    FProc.Terminate(Integer(ACode));
end;

procedure TProcRun.KillTree;
begin
  Terminate(1);
end;

function TProcRun.DetachHandle: THandle;
begin
  Result := 0;
end;

procedure ProcKillTree(APid: Cardinal);
begin
end;

{$ENDIF}

function ProcLaunch(const ACmdLine, ADir: string; var AError: string): Boolean;
var
  Launch: TProcRun;
begin
  Launch := TProcRun.Create;
  try
    Launch.CommandLine := ACmdLine;
    Launch.Dir := ADir;
    Result := Launch.Start;
    if not Result then
      AError := Launch.ErrorText;
  finally
    Launch.Free;
  end;
end;

end.
