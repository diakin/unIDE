// ---------------------------------------------------------------------------
//  HangWatch под Linux (этап 6 плана): то же назначение, другие средства.
//  Включается в HangWatch.pas сразу после implementation.
//
//  Зависание. Сторож (поток) кладёт в очередь главного потока пустой вызов
//  (TThread.Queue); LCL выполняет очередь в цикле сообщений. Вызов не
//  выполнен за 3 секунды - главный поток не выбирает сообщения. Тогда
//  главному потоку посылается сигнал SIGPROF; обработчик сигнала работает
//  в главном потоке, на его стеке: берёт из контекста RIP, RSP и RBP,
//  проходит цепочку кадров по RBP и собирает адреса кода программы,
//  лежащие в стеке. Обработчик не трогает кучу и строки - только
//  глобальные массивы фиксированного размера; границы стека и кода
//  программы известны заранее (/proc/self/maps при запуске сторожа), за
//  них чтение не выходит. Имена процедур и строки - BackTraceStrFunc
//  (отладочная информация в exe, ключ -gl), уже в потоке сторожа.
//  Снимков за одно зависание - три: сразу, через 10 и через 30 секунд,
//  как в Windows. В каждом - сколько процессорного времени главный поток
//  занял с прошлого снимка (/proc/self/task/<pid>/stat).
//
//  Сбой - crash.log. Free Pascal превращает SIGSEGV в исключение
//  EAccessViolation; System.RaiseProc вызывается при каждом raise, ещё до
//  раскрутки стека, с цепочкой вызовов от места сбоя. Пишутся Access
//  violation и нехватка памяти, не больше AvMaxReports записей за запуск.
//
//  Память для индикатора в строке состояния: в 64-разрядном процессе
//  адресов хватает всегда, поэтому вместо адресов - сколько памяти занимает
//  процесс (VmRSS) и сколько доступно в системе (MemAvailable).
// ---------------------------------------------------------------------------

uses
  BaseUnix;

function pthread_kill(AThread: TThreadID; ASignal: cint): cint; cdecl;
  external 'pthread' name 'pthread_kill';

const
  PollEvery = 250;         // мс между проверками
  PingWait = 3000;         // мс без ответа - зависание
  SnapWaitMs = 1000;       // сколько ждать снимка от обработчика сигнала
  SnapSignal = SIGPROF;
  MaxFrames = 48;
  MaxCodeAddrs = 40;
  StackScanBytes = 65536;  // сколько стека просматривать от RSP
  MaxCodeRanges = 8;
  AvMaxReports = 5;
  ClockTicks = 100;        // USER_HZ: единица utime/stime в /proc
  SaRestart = $10000000;   // SA_RESTART Linux (в BaseUnix его нет)

type
  THangWatch = class(TThread)
  private
    FLogFile: string;
    FCrashFile: string;
    FBuild: string;
    FLastCpu: Int64;
    FLastTick: QWord;
    procedure Pong;
    procedure Sample(ANum: Integer; AHungMs: QWord);
  protected
    procedure Execute; override;
  public
    constructor Create(const ALogFile, ABuild: string);
    function BuildNote: string;
    procedure WriteLog(const Str: string);
    procedure WriteCrash(ALines: TStrings);
  end;

  TCodeRange = record
    StartAddr: PtrUInt;
    EndAddr: PtrUInt;
  end;

var
  Watch: THangWatch = nil;
  // Пинг: 1 - вызов в очереди главного потока, ещё не выполнен
  PingPending: Longint = 0;
  // Границы стека главного потока и кода программы - из /proc/self/maps
  StackLow: PtrUInt = 0;
  StackHigh: PtrUInt = 0;
  CodeRanges: array[0..MaxCodeRanges - 1] of TCodeRange;
  CodeRangeCount: Integer = 0;
  // Снимок, который заполняет обработчик сигнала
  SnapPc: PtrUInt = 0;
  SnapFrames: array[0..MaxFrames - 1] of PtrUInt;
  SnapFrameCount: Integer = 0;
  SnapCodes: array[0..MaxCodeAddrs - 1] of PtrUInt;
  SnapCodeCount: Integer = 0;
  SnapReady: Longint = 0;
  SnapHandlerSet: Boolean = False;
  OldSnapAction: SigActionRec;
  // Сбои
  OldRaiseProc: TExceptProc = nil;
  AvBusy: Longint = 0;
  AvReports: Integer = 0;
  AvLastAddr: CodePointer = nil;

// Текст файла /proc: у таких файлов размер 0, читаются до конца чтением
function ProcFileText(const APath: string): string;
var
  FileHandle: cint;
  Buffer: array[0..4095] of Char;
  Got: TSsize;
  Chunk: string;
begin
  Result := '';
  FileHandle := FpOpen(APath, O_RDONLY);
  if FileHandle < 0 then
    Exit;
  try
    repeat
      Got := FpRead(FileHandle, Buffer, SizeOf(Buffer));
      if Got > 0 then
      begin
        SetString(Chunk, PChar(@Buffer[0]), Got);
        Result := Result + Chunk;
      end;
    until (Got <= 0) or (Length(Result) > 1024 * 1024);
  finally
    FpClose(FileHandle);
  end;
end;

// Число после "AKey:" в тексте вида /proc/self/status ("VmRSS:  1234 kB")
function ProcKeyNumber(const AText, AKey: string): Int64;
var
  KeyPos, CharIdx: Integer;
  Digits: string;
begin
  Result := -1;
  KeyPos := Pos(#10 + AKey + ':', #10 + AText);
  if KeyPos = 0 then
    Exit;
  CharIdx := KeyPos + Length(AKey) + 1;
  while (CharIdx <= Length(AText)) and (AText[CharIdx] in [' ', #9]) do
    Inc(CharIdx);
  Digits := '';
  while (CharIdx <= Length(AText)) and (AText[CharIdx] in ['0'..'9']) do
  begin
    Digits := Digits + AText[CharIdx];
    Inc(CharIdx);
  end;
  Result := StrToInt64Def(Digits, -1);
end;

// Стек главного потока ([stack]) и исполняемые участки самой программы -
// из /proc/self/maps. Вызывается в главном потоке при запуске сторожа
procedure ReadMaps;
var
  Lines: TStringList;
  LineIdx, DashPos, SpacePos: Integer;
  Line, ExeName, RangeText: string;
  RangeStart, RangeEnd: PtrUInt;
begin
  CodeRangeCount := 0;
  StackLow := 0;
  StackHigh := 0;
  ExeName := FpReadLink('/proc/self/exe');
  Lines := TStringList.Create;
  try
    Lines.Text := ProcFileText('/proc/self/maps');
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Lines[LineIdx];
      DashPos := Pos('-', Line);
      SpacePos := Pos(' ', Line);
      if (DashPos = 0) or (SpacePos < DashPos) then
        Continue;
      RangeText := Copy(Line, 1, DashPos - 1);
      RangeStart := PtrUInt(StrToQWordDef('$' + RangeText, 0));
      RangeText := Copy(Line, DashPos + 1, SpacePos - DashPos - 1);
      RangeEnd := PtrUInt(StrToQWordDef('$' + RangeText, 0));
      if (RangeStart = 0) or (RangeEnd <= RangeStart) then
        Continue;
      if Pos('[stack]', Line) > 0 then
      begin
        StackLow := RangeStart;
        StackHigh := RangeEnd;
      end
      else if (Copy(Line, SpacePos + 3, 1) = 'x') and (ExeName <> '') and
              (Copy(Line, Length(Line) - Length(ExeName) + 1,
                    Length(ExeName)) = ExeName) and
              (CodeRangeCount < MaxCodeRanges) then
      begin
        CodeRanges[CodeRangeCount].StartAddr := RangeStart;
        CodeRanges[CodeRangeCount].EndAddr := RangeEnd;
        Inc(CodeRangeCount);
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function InCode(AAddr: PtrUInt): Boolean;
var
  RangeIdx: Integer;
begin
  Result := False;
  for RangeIdx := 0 to CodeRangeCount - 1 do
    if (AAddr >= CodeRanges[RangeIdx].StartAddr) and
       (AAddr < CodeRanges[RangeIdx].EndAddr) then
    begin
      Result := True;
      Exit;
    end;
end;

// Обработчик SIGPROF - в главном потоке, посреди того, чем он занят.
// Только чтение регистров и стека в известных границах и запись в
// глобальные массивы: ни кучи, ни строк, ни вызовов RTL
procedure SnapHandler(ASignal: cint; AInfo: PSigInfo;
                      AContext: PSigContext); cdecl;
var
  Ctx: PByte;
  RegPc, RegSp, RegFp, Frame, NextFrame, RetAddr, Cell, ScanEnd: PtrUInt;
begin
  if InterLockedCompareExchange(SnapReady, 0, 0) <> 0 then
    Exit;
  SnapFrameCount := 0;
  SnapCodeCount := 0;
  SnapPc := 0;
  Ctx := PByte(AContext);
  if Ctx = nil then
  begin
    InterLockedExchange(SnapReady, 1);
    Exit;
  end;
  // ucontext_t: uc_flags, uc_link, uc_stack (stack_t), затем
  // uc_mcontext.gregs
{$IF DEFINED(CPUX86_64)}
  RegFp := PPtrUInt(Ctx + 40 + 10 * 8)^;   // REG_RBP
  RegSp := PPtrUInt(Ctx + 40 + 15 * 8)^;   // REG_RSP
  RegPc := PPtrUInt(Ctx + 40 + 16 * 8)^;   // REG_RIP
{$ELSEIF DEFINED(CPUI386)}
  RegFp := PPtrUInt(Ctx + 20 + 6 * 4)^;    // REG_EBP
  RegSp := PPtrUInt(Ctx + 20 + 7 * 4)^;    // REG_ESP
  RegPc := PPtrUInt(Ctx + 20 + 14 * 4)^;   // REG_EIP
{$ELSE}
  RegFp := 0;
  RegSp := 0;
  RegPc := 0;
{$IFEND}
  SnapPc := RegPc;
  if (StackHigh = 0) or (RegSp < StackLow) or (RegSp >= StackHigh) then
  begin
    InterLockedExchange(SnapReady, 1);
    Exit;
  end;
  // Цепочка кадров: [RBP] - прежний RBP, [RBP + 8] - адрес возврата
  Frame := RegFp;
  while (SnapFrameCount < MaxFrames) and (Frame >= RegSp) and
        (Frame + 2 * SizeOf(Pointer) <= StackHigh) and
        (Frame and (SizeOf(Pointer) - 1) = 0) do
  begin
    RetAddr := PPtrUInt(Frame + SizeOf(Pointer))^;
    NextFrame := PPtrUInt(Frame)^;
    if RetAddr = 0 then
      Break;
    SnapFrames[SnapFrameCount] := RetAddr;
    Inc(SnapFrameCount);
    if NextFrame <= Frame then
      Break;
    Frame := NextFrame;
  end;
  // Адреса кода программы, лежащие в стеке: цепочка рвётся в библиотеках
  // без RBP-кадров (libc, gtk), а адреса возврата в программу остаются
  ScanEnd := RegSp + StackScanBytes;
  if ScanEnd > StackHigh then
    ScanEnd := StackHigh;
  Cell := RegSp and not PtrUInt(SizeOf(Pointer) - 1);
  while (Cell + SizeOf(Pointer) <= ScanEnd) and
        (SnapCodeCount < MaxCodeAddrs) do
  begin
    if InCode(PPtrUInt(Cell)^) then
    begin
      SnapCodes[SnapCodeCount] := PPtrUInt(Cell)^;
      Inc(SnapCodeCount);
    end;
    Inc(Cell, SizeOf(Pointer));
  end;
  InterLockedExchange(SnapReady, 1);
end;

procedure SetSnapHandler;
var
  NewAction: SigActionRec;
begin
  FillChar(NewAction, SizeOf(NewAction), 0);
  NewAction.sa_handler := SigActionHandler_t(@SnapHandler);
  // SA_RESTART: прерванный сигналом системный вызов главного потока
  // (poll в цикле gtk, чтение файла) продолжается, а не кончается EINTR
  NewAction.sa_flags := SA_SIGINFO or SaRestart;
  FpSigEmptySet(NewAction.sa_mask);
  SnapHandlerSet := FpSigAction(SnapSignal, @NewAction, @OldSnapAction) = 0;
end;

procedure RestoreSnapHandler;
begin
  if SnapHandlerSet then
    FpSigAction(SnapSignal, @OldSnapAction, nil);
  SnapHandlerSet := False;
end;

// Адрес строкой: имя процедуры и строка по отладочной информации exe
function DescribeAddr(AAddr: PtrUInt): string;
begin
  try
    Result := Trim(BackTraceStrFunc(CodePointer(AAddr)));
  except
    Result := '$' + IntToHex(AAddr, SizeOf(Pointer) * 2);
  end;
end;

// Процессорное время главного потока, мс; -1 - не прочитать
function MainThreadCpuMs: Int64;
var
  StatText: string;
  ClosePos: Integer;
  Fields: TStringList;
begin
  Result := -1;
  StatText := ProcFileText('/proc/self/task/' + IntToStr(FpGetPid) +
                           '/stat');
  ClosePos := LastDelimiter(')', StatText);
  if ClosePos = 0 then
    Exit;
  Fields := TStringList.Create;
  try
    Fields.Delimiter := ' ';
    Fields.StrictDelimiter := True;
    Fields.DelimitedText := Trim(Copy(StatText, ClosePos + 1, MaxInt));
    // После имени: состояние (поле 3), ... utime (14), stime (15)
    if Fields.Count > 12 then
      Result := (StrToInt64Def(Fields[11], 0) + StrToInt64Def(Fields[12], 0)) *
                1000 div ClockTicks;
  finally
    Fields.Free;
  end;
end;

{ THangWatch }

constructor THangWatch.Create(const ALogFile, ABuild: string);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FLogFile := ALogFile;
  FCrashFile := ExtractFilePath(ALogFile) + 'crash.log';
  FBuild := ABuild;
  FLastCpu := -1;
  FLastTick := 0;
end;

function THangWatch.BuildNote: string;
begin
  if FBuild = '' then
    Result := ''
  else
    Result := '  [' + FBuild + ']';
end;

procedure THangWatch.WriteLog(const Str: string);
var
  TxtFile: TextFile;
begin
  try
    AssignFile(TxtFile, FLogFile);
    if FileExists(FLogFile) then
      Append(TxtFile)
    else
      Rewrite(TxtFile);
    try
      Writeln(TxtFile, Str);
    finally
      CloseFile(TxtFile);
    end;
  except
    // журнал не записался - ничего не поделать
  end;
end;

procedure THangWatch.WriteCrash(ALines: TStrings);
var
  TxtFile: TextFile;
  LineIdx: Integer;
begin
  try
    AssignFile(TxtFile, FCrashFile);
    if FileExists(FCrashFile) then
      Append(TxtFile)
    else
      Rewrite(TxtFile);
    try
      for LineIdx := 0 to ALines.Count - 1 do
        Writeln(TxtFile, ALines[LineIdx]);
      Writeln(TxtFile, '');
    finally
      CloseFile(TxtFile);
    end;
  except
    // журнал не записался - ничего не поделать
  end;
end;

// Выполняется в главном потоке, когда он дошёл до очереди
procedure THangWatch.Pong;
begin
  InterLockedExchange(PingPending, 0);
end;

procedure THangWatch.Sample(ANum: Integer; AHungMs: QWord);
var
  Lines: TStringList;
  Cpu: Int64;
  WaitStart: QWord;
  AddrIdx: Integer;
  NowTick: QWord;

  function CpuVerdict(ACpu: Int64; AMs: QWord): string;
  begin
    if AMs = 0 then
      Result := '?'
    else if ACpu * 10 >= Int64(AMs) * 8 then
      Result := 'крутится (цикл или долгая работа)'
    else if ACpu * 10 <= Int64(AMs) then
      Result := 'ждёт (окно, файл, другой процесс)'
    else
      Result := 'то работает, то ждёт';
  end;

begin
  Lines := TStringList.Create;
  try
    Lines.Add(Format('==== %s  главный поток не отвечает %.1f с  (снимок %d)%s',
                     [FormatDateTime('dd.mm.yyyy hh:nn:ss', Now),
                      AHungMs / 1000, ANum, BuildNote]));
    Lines.Add('Признак: вызов из очереди главного потока не выполнен ' +
              IntToStr(PingWait div 1000) + ' с');
    Cpu := MainThreadCpuMs;
    NowTick := GetTickCount64;
    if (ANum > 1) and (Cpu >= 0) and (FLastCpu >= 0) then
      Lines.Add(Format('Процессор: за %.1f с с прошлого снимка поток занял ' +
                       '%d мс - %s',
                       [(NowTick - FLastTick) / 1000, Cpu - FLastCpu,
                        CpuVerdict(Cpu - FLastCpu, NowTick - FLastTick)]));
    FLastCpu := Cpu;
    FLastTick := NowTick;

    InterLockedExchange(SnapReady, 0);
    if SnapHandlerSet and (pthread_kill(MainThreadID, SnapSignal) = 0) then
    begin
      WaitStart := GetTickCount64;
      while (InterLockedCompareExchange(SnapReady, 0, 0) = 0) and
            (GetTickCount64 - WaitStart < SnapWaitMs) and not Terminated do
        Sleep(10);
    end;
    if InterLockedCompareExchange(SnapReady, 0, 0) = 0 then
      Lines.Add('Снимок стека не получен (сигнал не обработан)')
    else
    begin
      Lines.Add('Место  ' + DescribeAddr(SnapPc));
      if SnapFrameCount > 0 then
      begin
        Lines.Add('Цепочка вызовов (по RBP):');
        for AddrIdx := 0 to SnapFrameCount - 1 do
          Lines.Add('  ' + DescribeAddr(SnapFrames[AddrIdx]));
      end;
      if SnapCodeCount > 0 then
      begin
        Lines.Add('Адреса кода программы в стеке (от вершины):');
        for AddrIdx := 0 to SnapCodeCount - 1 do
          Lines.Add('  ' + DescribeAddr(SnapCodes[AddrIdx]));
      end;
      // Снимок прочитан - обработчик может писать следующий
      InterLockedExchange(SnapReady, 0);
    end;
    Lines.Add('');
    for AddrIdx := 0 to Lines.Count - 1 do
      WriteLog(Lines[AddrIdx]);
  finally
    Lines.Free;
  end;
end;

procedure THangWatch.Execute;
var
  PingStart, HungSince, NowTick: QWord;
  Samples: Integer;
begin
  HungSince := 0;
  Samples := 0;
  PingStart := 0;
  while not Terminated do
  begin
    Sleep(PollEvery);
    if Terminated then
      Break;
    NowTick := GetTickCount64;
    if InterLockedCompareExchange(PingPending, 0, 0) = 0 then
    begin
      // Ответил: если до этого не отвечал - запись о конце зависания
      if HungSince <> 0 then
        WriteLog(Format('%s  главный поток снова отвечает; не отвечал ' +
                        'около %.1f с'#10,
                        [FormatDateTime('dd.mm.yyyy hh:nn:ss', Now),
                         (NowTick - HungSince) / 1000]));
      HungSince := 0;
      Samples := 0;
      InterLockedExchange(PingPending, 1);
      PingStart := NowTick;
      Queue(Pong);
      Continue;
    end;
    if NowTick - PingStart < PingWait then
      Continue;
    if HungSince = 0 then
      HungSince := PingStart;
    // Снимки: сразу, через 10 и через 30 секунд
    if ((Samples = 0) or
        ((Samples = 1) and (NowTick - HungSince >= 10000)) or
        ((Samples = 2) and (NowTick - HungSince >= 30000))) then
    begin
      Inc(Samples);
      try
        Sample(Samples, NowTick - HungSince);
      except
        // снимок не записался - дальше
      end;
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Сбои: RaiseProc - при каждом raise, в потоке, где оно случилось
// ---------------------------------------------------------------------------

procedure CrashRaiseProc(AObj: TObject; AAddr: CodePointer;
                         AFrameCount: Longint; AFrames: PCodePointer);
var
  Lines: TStringList;
  FrameIdx: Integer;
  What: string;
begin
  if (Watch <> nil) and
     ((AObj is EAccessViolation) or (AObj is EOutOfMemory)) and
     (AAddr <> AvLastAddr) and (AvReports < AvMaxReports) and
     (InterLockedExchange(AvBusy, 1) = 0) then
  begin
    AvLastAddr := AAddr;
    Inc(AvReports);
    try
      if AObj is EOutOfMemory then
        What := 'нехватка памяти (Out of memory)'
      else
        What := 'Access violation';
      Lines := TStringList.Create;
      try
        Lines.Add(Format('==== %s  %s%s',
                         [FormatDateTime('dd.mm.yyyy hh:nn:ss', Now), What,
                          Watch.BuildNote]));
        // System: в Windows (замена WinAPI) - свой GetCurrentThreadId
        if System.GetCurrentThreadId = MainThreadID then
          Lines.Add('Поток: главный')
        else
          Lines.Add('Поток: ' + IntToStr(PtrUInt(System.GetCurrentThreadId)) +
                    ' (не главный)');
        Lines.Add('Сообщение: ' + Exception(AObj).Message);
        Lines.Add('Место  ' + DescribeAddr(PtrUInt(AAddr)));
        Lines.Add(AddressSpaceText);
        if (AFrames <> nil) and (AFrameCount > 0) then
        begin
          Lines.Add('Цепочка вызовов:');
          for FrameIdx := 0 to AFrameCount - 1 do
            Lines.Add('  ' + DescribeAddr(PtrUInt(AFrames[FrameIdx])));
        end;
        Watch.WriteCrash(Lines);
      finally
        Lines.Free;
      end;
    except
      // запись не удалась - исключение идёт дальше как обычно
    end;
    InterLockedExchange(AvBusy, 0);
  end;
  if Assigned(OldRaiseProc) then
    OldRaiseProc(AObj, AAddr, AFrameCount, AFrames);
end;

// ---------------------------------------------------------------------------

procedure AddressSpaceGet(var AUsedMB, AFreeMB, ALargestMB: Integer);
var
  RssKb, AvailKb: Int64;
begin
  RssKb := ProcKeyNumber(ProcFileText('/proc/self/status'), 'VmRSS');
  AvailKb := ProcKeyNumber(ProcFileText('/proc/meminfo'), 'MemAvailable');
  if RssKb < 0 then
    RssKb := 0;
  if AvailKb < 0 then
    AvailKb := 0;
  AUsedMB := RssKb div 1024;
  AFreeMB := AvailKb div 1024;
  // Самого большого свободного участка в 64-разрядном процессе нет смысла
  // считать: индикатор смотрит на доступную память системы
  ALargestMB := AFreeMB;
end;

function AddressSpaceText: string;
var
  StatusText: string;
begin
  StatusText := ProcFileText('/proc/self/status');
  Result := Format('память - процесс занимает %d МБ (VmRSS), адресов %d МБ ' +
    '(VmSize), доступно в системе %d МБ (MemAvailable)',
    [ProcKeyNumber(StatusText, 'VmRSS') div 1024,
     ProcKeyNumber(StatusText, 'VmSize') div 1024,
     ProcKeyNumber(ProcFileText('/proc/meminfo'), 'MemAvailable') div 1024]);
end;

procedure HangWatchStart(AWnd: HWND; const ALogFile: string;
                         AUiWnd: HWND = 0; const ABuild: string = '');
begin
  if Watch <> nil then
    Exit;
  ReadMaps;
  SetSnapHandler;
  Watch := THangWatch.Create(ALogFile, ABuild);
  Watch.Start;
  OldRaiseProc := RaiseProc;
  RaiseProc := @CrashRaiseProc;
end;

// Цепочка вызовов текущего потока по RBP (get_caller_addr), с именами
procedure HangWatchCallStack(ALines: TStrings);
var
  Frame: Pointer;
  CallerAddr: CodePointer;
  FrameIdx: Integer;
begin
  Frame := get_frame;
  for FrameIdx := 0 to MaxFrames - 1 do
  begin
    CallerAddr := get_caller_addr(Frame);
    if CallerAddr = nil then
      Break;
    ALines.Add('  ' + DescribeAddr(PtrUInt(CallerAddr)));
    Frame := get_caller_frame(Frame);
    if Frame = nil then
      Break;
  end;
end;

procedure HangWatchStop;
begin
  if Watch = nil then
    Exit;
  if @RaiseProc = @CrashRaiseProc then
    RaiseProc := OldRaiseProc;
  OldRaiseProc := nil;
  Watch.Terminate;
  Watch.WaitFor;
  FreeAndNil(Watch);
  RestoreSnapHandler;
end;
