unit DbgEngine;

// ---------------------------------------------------------------------------
//  Отладчик запущенной программы: точки останова, продолжение (этап 1),
//  шаги по строкам и Run to cursor (этап 2)
//
//  Программа запускается под отладчиком Win32 (CreateProcess с
//  DEBUG_ONLY_THIS_PROCESS). События отладки - запуск, потоки, исключения,
//  OutputDebugString, завершение - приходят тому потоку, который создал
//  процесс, поэтому весь цикл WaitForDebugEvent идёт в своём потоке
//  (TDbgThread), а главный поток получает от него записи через очередь и
//  сообщение окну AllocateHWnd.
//
//  Точка останова - байт INT3 ($CC) поверх первого байта кода строки.
//  Адрес строки берётся из .map (Map file: Detailed, ключ dcc32 -GD):
//  раздел "Line numbers for Unit1(Unit1.pas) segment CODE" даёт пары
//  "номер строки - смещение от начала сегмента кода". Начало сегмента в
//  памяти - база образа плюс адрес первой секции кода из заголовка PE.
//
//  Остановка: EIP возвращается на адрес точки, прежний байт кладётся на
//  место, главный поток получает адрес и показывает строку. Продолжение:
//  одна команда пошагово (флаг трассировки), после неё INT3 ставится
//  обратно, и программа идёт дальше.
//
//  Первое исключение BREAKPOINT - системное, его выдаёт загрузчик до
//  запуска программы; оно пропускается. Остальные исключения программа
//  обрабатывает сама (DBG_EXCEPTION_NOT_HANDLED), в лог уходит их код,
//  класс и сообщение исключения Delphi и строка, где оно возникло.
//
//  Этап 2: шаги по строкам.
//
//  Trace into и Step over - поток, который стоит, идёт по одной команде
//  (флаг трассировки) до первого адреса, который в .map записан как
//  начало строки. После каждой команды проверяется, не была ли она
//  CALL: ESP уменьшился на 4, а на вершине стека адрес сразу за прежней
//  командой (CALL занимает от 2 до 7 байт). Тогда:
//    - Step over - всегда, Trace into - если у вызванного кода нет
//      номеров строк (RTL, VCL, DLL): на адрес возврата ставится
//      временная точка, программа идёт свободно до неё, дальше снова по
//      одной команде. Точка возврата срабатывает только у того же потока
//      и только при ESP выше, чем был внутри вызова: рекурсивный вызов
//      той же процедуры проходит её без остановки;
//    - Trace into в код с номерами строк - остановка на его первой строке.
//  Если шаг ушёл в код без номеров строк не через CALL (RET из
//  обработчика обратно в VCL), программа идёт дальше свободно - так же,
//  как в Delphi без отладочных DCU.
//
//  Run to cursor - временные точки на адресах строки, программа идёт
//  свободно; остановка на любой из них в любом потоке. Любая остановка
//  (точка, шаг, курсор) снимает все временные точки и прерывает шаг.
//
//  Запуск с F7/F8 - временная точка на адресе входа exe: у программы на
//  Delphi это begin главного блока .dpr.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes;

type
  TDbgOffsetArray = array of Cardinal;

  // Таблица номеров строк из .map
  TDbgLineMap = class
  private
    FUnitFile: TStringList;    // файл раздела: Unit1.pas, var.inc
    FUnitModule: TStringList;  // модуль раздела: Unit1
    FLineOfs: array of Cardinal;
    FLineNum: array of Integer;
    FLineUnit: array of Integer;
    FLineCount: Integer;
    // Сегменты модулей в коде (раздел Detailed map of segments)
    FModName: TStringList;
    FModStart: array of Cardinal;
    FModLen: array of Cardinal;
    FModLines: array of Boolean;   // у модуля есть номера строк
    // Смещения строк по возрастанию (для шагов: поиск начала строки)
    FSortedOfs: TDbgOffsetArray;
    FMinOfs, FMaxOfs: Cardinal;
    procedure AddLine(AOffset: Cardinal; ALine, AUnit: Integer);
    procedure AddModule(const AName: string; AStart, ALen: Cardinal);
    procedure BuildIndex;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromFile(const AMapFile: string): Boolean;
    // Смещения кода строки ALine (с 1) файла AFileName (имя без пути): по
    // одному на каждый раздел, где она есть, - начало строки
    procedure OffsetsOfLine(const AFileName: string; ALine: Integer;
                            AOffsets: TList);
    // Строка, к которой относится смещение: ближайшая не дальше него в том
    // же модуле. False - модуль без номеров строк
    function LineOfOffset(AOffset: Cardinal; var AFileName: string;
                          var ALine: Integer): Boolean;
    // Для потока отладки (только чтение, после LoadFromFile):
    // смещение - начало строки по .map
    function IsLineStart(AOffset: Cardinal): Boolean;
    // смещение - в модуле, у которого есть номера строк
    function HasLines(AOffset: Cardinal): Boolean;
    property LineCount: Integer read FLineCount;
  end;

  TDbgStopEvent = procedure(Sender: TObject; AOffset: Cardinal) of object;
  TDbgLogEvent = procedure(Sender: TObject; const AText: string) of object;
  TDbgExitEvent = procedure(Sender: TObject; AExitCode: Cardinal) of object;

  // Запись от потока отладки главному потоку
  TDbgNote = record
    Kind: Integer;       // DbgNote* ниже
    Address: Cardinal;   // адрес в процессе программы
    Value: Cardinal;     // код выхода, код исключения
    Text: string;
  end;

  TDbgThread = class;

  // Сеанс отладки. Создаётся, живёт и освобождается в главном потоке.
  // Обработчики событий вызываются в главном потоке; освобождать сеанс
  // прямо из них нельзя - только позже (PostMessage).
  TDbgSession = class
  private
    FExeFile: string;
    FWorkDir: string;
    FMap: TDbgLineMap;
    FWnd: HWND;
    FLock: TRTLCriticalSection;
    FNotes: array of TDbgNote;
    FNoteCount: Integer;
    FThread: TDbgThread;
    FPaused: Boolean;
    FFinished: Boolean;
    FStarted: Boolean;
    FLeaked: Boolean;         // поток не закончился - память не трогаем
    FCodeBase: Cardinal;      // начало сегмента кода в процессе программы
    FResumeEvent: THandle;    // поток отладки ждёт его на остановке
    FProcess: THandle;        // дескриптор процесса, пока поток его держит
    FKillWanted: Boolean;
    // Изменения точек для потока: смещение и включить/выключить
    FPendOfs: array of Cardinal;
    FPendOn: array of Boolean;
    FPendCount: Integer;
    // Команда потоку на остановке: DbgCmd* и смещения для Run to cursor.
    // До запуска - цели первого хода (Run to cursor до старта).
    FCmdMode: Integer;
    FCmdOfs: TDbgOffsetArray;
    FStopAtEntry: Boolean;
    FExcLogged: Integer;      // сколько исключений ушло в лог
    FOnStopped: TDbgStopEvent;
    FOnLog: TDbgLogEvent;
    FOnExited: TDbgExitEvent;
    procedure WndProc(var Msg: TMessage);
    procedure DrainNotes;
    procedure PushNote(AKind: Integer; AAddress, AValue: Cardinal;
                       const AText: string);
    function WhereText(AAddress: Cardinal): string;
    procedure Command(AMode: Integer; AOffsets: TList);
  public
    constructor Create(const AExeFile, AWorkDir: string; AMap: TDbgLineMap);
    destructor Destroy; override;
    procedure Start;
    // Точка по смещению от начала сегмента кода (из TDbgLineMap)
    procedure SetBreakpoint(AOffset: Cardinal; AOn: Boolean);
    // Команды на остановке (Paused). Continue:
    procedure Resume;
    // Trace into и Step over - до следующей строки
    procedure StepInto;
    procedure StepOver;
    // Run to cursor - до одного из смещений (адреса строки). До Start -
    // цели первого хода программы.
    procedure RunTo(AOffsets: TList);
    procedure Kill;
    property Map: TDbgLineMap read FMap;
    property Paused: Boolean read FPaused;
    property Finished: Boolean read FFinished;
    property ExeFile: string read FExeFile;
    // До Start: остановиться на адресе входа (begin главного блока .dpr)
    property StopAtEntry: Boolean read FStopAtEntry write FStopAtEntry;
    property OnStopped: TDbgStopEvent read FOnStopped write FOnStopped;
    property OnLog: TDbgLogEvent read FOnLog write FOnLog;
    property OnExited: TDbgExitEvent read FOnExited write FOnExited;
  end;

  // Точка в процессе программы. Пользовательская (UserRef) и временная
  // (TempRef: возврат из вызова при шаге, Run to cursor, вход в
  // программу) могут совпасть по адресу - INT3 один, пока есть хоть одна.
  TDbgBreak = record
    Address: Cardinal;
    OrigByte: Byte;
    Inserted: Boolean;   // INT3 сейчас стоит в коде
    UserRef: Integer;    // одна строка может прийти дважды
    TempRef: Integer;
  end;

  // Поток проходит снятую на время точку одной командой (флаг
  // трассировки): после этой команды INT3 обратно
  TDbgRearm = record
    ThreadId: DWORD;
    Address: Cardinal;
  end;

  TDbgThreadRef = record
    ThreadId: DWORD;
    Handle: THandle;
  end;

  TDbgThread = class(TThread)
  private
    FOwner: TDbgSession;
    FMap: TDbgLineMap;
    FProcess: THandle;
    FProcessId: DWORD;
    FCodeBase: Cardinal;
    FLoaderBreakSeen: Boolean;
    FBreaks: array of TDbgBreak;
    FRearms: array of TDbgRearm;
    FThreads: array of TDbgThreadRef;
    FGone: array of Cardinal;   // адреса снятых точек: INT3 мог сработать
    // Потоки, у которых флаг трассировки сняли при прерванном шаге: их
    // SINGLE_STEP мог уже стоять в очереди событий
    FStale: array of DWORD;
    // Шаг (Trace into / Step over): поток, режим, фаза
    FStepThread: DWORD;
    FStepMode: Integer;          // DbgCmdInto, DbgCmdOver
    FStepPhase: Integer;         // DbgPhase*
    FPrevEip, FPrevEsp: Cardinal;  // до последней команды
    FRetAddr, FRetEsp: Cardinal;   // точка возврата из вызова и ESP в нём
    // Адреса временных точек Run to cursor и входа в программу
    FRunTo: array of Cardinal;
    function StartProcess: Boolean;
    function ReadCodeBase(AImageBase: Cardinal): Cardinal;
    function PokeByte(AAddress: Cardinal; AValue: Byte;
                      var AOldValue: Byte): Boolean;
    function ReadDword(AAddress: Cardinal; var AValue: Cardinal): Boolean;
    function ReadAnsi(AAddress: Cardinal; ALen: Integer): string;
    procedure ApplyPending;
    procedure BreakAdd(AAddress: Cardinal; ATemp: Boolean);
    procedure BreakRelease(AAddress: Cardinal; ATemp: Boolean);
    procedure BreakLift(AAddress: Cardinal);
    function FindBreak(AAddress: Cardinal): Integer;
    function IsGone(AAddress: Cardinal): Boolean;
    function ThreadHandleOf(AThreadId: DWORD): THandle;
    procedure AddThread(AThreadId: DWORD; AHandle: THandle);
    procedure RemoveThread(AThreadId: DWORD);
    function SetEip(AThreadId: DWORD; AEip: Cardinal;
                    ATrace: Boolean): Boolean;
    function SetTrace(AThreadId: DWORD; AOn: Boolean): Boolean;
    function GetEipEsp(AThreadId: DWORD; var AEip, AEsp: Cardinal): Boolean;
    function InLineCode(AAddress: Cardinal): Boolean;
    function IsLineAddress(AAddress: Cardinal): Boolean;
    procedure AddRearm(AThreadId: DWORD; AAddress: Cardinal);
    function TakeRearm(AThreadId: DWORD): Boolean;
    procedure AddStale(AThreadId: DWORD);
    function TakeStale(AThreadId: DWORD): Boolean;
    procedure AddRunTo(AAddress: Cardinal);
    function IsRunTo(AAddress: Cardinal): Boolean;
    procedure ClearRunTo;
    procedure CancelStep;
    procedure ReadCommand(var AMode: Integer; var AOffsets: TDbgOffsetArray);
    function WaitResume: Boolean;
    function PauseAt(AThreadId: DWORD; AAddress: Cardinal): DWORD;
    function OnBreakpoint(AThreadId: DWORD; AAddress: Cardinal): DWORD;
    function OnSingleStep(AThreadId: DWORD): DWORD;
    function StepEvent(AThreadId: DWORD): DWORD;
    function DelphiExceptionText(const AInfo: array of DWORD): string;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TDbgSession);
  end;

const
  DbgNoteLog       = 0;
  DbgNoteStopped   = 1;
  DbgNoteException = 2;
  DbgNoteExited    = 3;
  DbgNoteCodeBase  = 4;

  // Команды на остановке
  DbgCmdGo    = 0;   // Continue
  DbgCmdInto  = 1;   // Trace into
  DbgCmdOver  = 2;   // Step over
  DbgCmdRunTo = 3;   // Run to cursor

  // Фазы шага
  DbgPhaseNone   = 0;
  DbgPhaseTrace  = 1;   // по одной команде
  DbgPhaseReturn = 2;   // свободно до точки возврата из вызова

implementation

const
  WM_DBG_NOTE = WM_USER + 1;

  DbgOnlyThisProcess = $00000002;
  DbgContinue        = $00010002;
  DbgNotHandled      = $80010001;

  DbgEvException     = 1;
  DbgEvCreateThread  = 2;
  DbgEvCreateProcess = 3;
  DbgEvExitThread    = 4;
  DbgEvExitProcess   = 5;
  DbgEvLoadDll       = 6;
  DbgEvDebugString   = 8;

  DbgExcBreakpoint  = $80000003;
  DbgExcSingleStep  = $80000004;
  DbgExcWx86Break   = $4000001F;  // загрузчик WOW64
  DbgExcDelphi      = $0EEDFADE;  // raise в программе на Delphi
  DbgExcThreadName  = $406D1388;  // имя потока для отладчика Visual C++
  DbgExcPrintA      = $40010006;  // OutputDebugString изнутри
  DbgExcPrintW      = $4001000A;

  DbgTrapFlag       = $100;
  DbgInt3           = $CC;
  DbgMaxExcLog      = 50;         // исключений в лог за сеанс
  DbgVmtClassName   = -44;        // vmtClassName в System.pas Delphi 7

type
  TDbgExceptionRecord = record
    ExceptionCode: DWORD;
    ExceptionFlags: DWORD;
    ExceptionRecord: Pointer;
    ExceptionAddress: Pointer;
    NumberParameters: DWORD;
    ExceptionInformation: array[0..14] of DWORD;
  end;

  TDbgExceptionInfo = record
    ExceptionRecord: TDbgExceptionRecord;
    FirstChance: DWORD;
  end;

  TDbgCreateThreadInfo = record
    ThreadHandle: THandle;
    ThreadLocalBase: Pointer;
    StartAddress: Pointer;
  end;

  TDbgCreateProcessInfo = record
    FileHandle: THandle;
    ProcessHandle: THandle;
    ThreadHandle: THandle;
    BaseOfImage: Pointer;
    DebugInfoFileOffset: DWORD;
    DebugInfoSize: DWORD;
    ThreadLocalBase: Pointer;
    StartAddress: Pointer;
    ImageName: Pointer;
    Unicode: Word;
  end;

  TDbgExitInfo = record
    ExitCode: DWORD;
  end;

  TDbgLoadDllInfo = record
    FileHandle: THandle;
    BaseOfDll: Pointer;
    DebugInfoFileOffset: DWORD;
    DebugInfoSize: DWORD;
    ImageName: Pointer;
    Unicode: Word;
  end;

  TDbgDebugStringInfo = record
    StringData: Pointer;
    Unicode: Word;
    StringLength: Word;
  end;

  // DEBUG_EVENT. Свои описания, а не Windows.pas: так поля и вызовы не
  // зависят от того, как их назвали в конкретной версии Delphi.
  TDbgDebugEvent = record
    EventCode: DWORD;
    ProcessId: DWORD;
    ThreadId: DWORD;
    case Integer of
      0: (Exception: TDbgExceptionInfo);
      1: (CreateThread: TDbgCreateThreadInfo);
      2: (CreateProcess: TDbgCreateProcessInfo);
      3: (ExitThread: TDbgExitInfo);
      4: (ExitProcess: TDbgExitInfo);
      5: (LoadDll: TDbgLoadDllInfo);
      6: (DebugString: TDbgDebugStringInfo);
      7: (Padding: array[0..95] of Byte);
  end;

function DbgWaitForDebugEvent(var AEvent: TDbgDebugEvent;
  AMilliseconds: DWORD): BOOL; stdcall;
  external kernel32 name 'WaitForDebugEvent';
function DbgContinueDebugEvent(AProcessId, AThreadId,
  AStatus: DWORD): BOOL; stdcall;
  external kernel32 name 'ContinueDebugEvent';
function DbgReadMemory(AProcess: THandle; AAddress: Pointer;
  ABuffer: Pointer; ASize: DWORD; var ADone: DWORD): BOOL; stdcall;
  external kernel32 name 'ReadProcessMemory';
function DbgWriteMemory(AProcess: THandle; AAddress: Pointer;
  ABuffer: Pointer; ASize: DWORD; var ADone: DWORD): BOOL; stdcall;
  external kernel32 name 'WriteProcessMemory';
function DbgVirtualProtectEx(AProcess: THandle; AAddress: Pointer;
  ASize, ANewProtect: DWORD; var AOldProtect: DWORD): BOOL; stdcall;
  external kernel32 name 'VirtualProtectEx';
function DbgFlushInstructionCache(AProcess: THandle; AAddress: Pointer;
  ASize: DWORD): BOOL; stdcall;
  external kernel32 name 'FlushInstructionCache';

// ---------------------------------------------------------------------------
//  TDbgLineMap
// ---------------------------------------------------------------------------

constructor TDbgLineMap.Create;
begin
  inherited Create;
  FUnitFile := TStringList.Create;
  FUnitModule := TStringList.Create;
  FModName := TStringList.Create;
end;

destructor TDbgLineMap.Destroy;
begin
  FUnitFile.Free;
  FUnitModule.Free;
  FModName.Free;
  inherited;
end;

procedure TDbgLineMap.AddLine(AOffset: Cardinal; ALine, AUnit: Integer);
begin
  // Записей десятки тысяч - массивы растут кусками
  if FLineCount = Length(FLineOfs) then
  begin
    SetLength(FLineOfs, FLineCount + 16384);
    SetLength(FLineNum, FLineCount + 16384);
    SetLength(FLineUnit, FLineCount + 16384);
  end;
  FLineOfs[FLineCount] := AOffset;
  FLineNum[FLineCount] := ALine;
  FLineUnit[FLineCount] := AUnit;
  Inc(FLineCount);
end;

procedure TDbgLineMap.AddModule(const AName: string; AStart, ALen: Cardinal);
var
  ModIdx: Integer;
begin
  ModIdx := FModName.Add(AName);
  SetLength(FModStart, ModIdx + 1);
  SetLength(FModLen, ModIdx + 1);
  FModStart[ModIdx] := AStart;
  FModLen[ModIdx] := ALen;
end;

// "0001:0000ABCD" -> $ABCD; не сегмент кода или не число - False
function MapCodeOfs(const AText: string; var AOfs: Cardinal): Boolean;
var
  Value: Integer;
begin
  Result := False;
  if (Length(AText) < 13) or (Copy(AText, 1, 5) <> '0001:') then
    Exit;
  Value := StrToIntDef('$' + Copy(AText, 6, 8), -1);
  if Value < 0 then
    Exit;
  AOfs := Cardinal(Value);
  Result := True;
end;

// Разделы карты Delphi, которые нужны:
//
//   Detailed map of segments
//    0001:00000000 00006234 C=CODE     S=.text    G=(none)   M=System ...
//
//   Line numbers for Unit1(Unit1.pas) segment CODE
//     13302 0001:0001A2B4  13303 0001:0001A2C0 ...
//
// Номера строк есть только у модулей, собранных с отладочной информацией
// ($D+).
function TDbgLineMap.LoadFromFile(const AMapFile: string): Boolean;
var
  MapText, Words: TStringList;
  RowIdx, WordIdx, OpenPos, ClosePos, UnitIdx, LineNo: Integer;
  Row, ModPart: string;
  InSegments: Boolean;
  Ofs, SegLen: Cardinal;
  LenValue: Integer;
begin
  Result := False;
  FLineCount := 0;
  FUnitFile.Clear;
  FUnitModule.Clear;
  FModName.Clear;
  SetLength(FSortedOfs, 0);
  SetLength(FModLines, 0);
  if not FileExists(AMapFile) then
    Exit;
  MapText := TStringList.Create;
  Words := TStringList.Create;
  try
    try
      MapText.LoadFromFile(AMapFile);
    except
      Exit;
    end;
    InSegments := False;
    UnitIdx := -1;
    for RowIdx := 0 to MapText.Count - 1 do
    begin
      Row := Trim(MapText[RowIdx]);
      if Row = '' then
        Continue;

      if Pos('Detailed map of segments', Row) > 0 then
      begin
        InSegments := True;
        UnitIdx := -1;
        Continue;
      end;

      if Copy(Row, 1, 17) = 'Line numbers for ' then
      begin
        InSegments := False;
        // "Line numbers for Unit1(Unit1.pas) segment CODE"
        OpenPos := Pos('(', Row);
        ClosePos := Pos(')', Row);
        if (OpenPos > 0) and (ClosePos > OpenPos) then
        begin
          UnitIdx := FUnitFile.Add(Copy(Row, OpenPos + 1,
                                        ClosePos - OpenPos - 1));
          FUnitModule.Add(Trim(Copy(Row, 18, OpenPos - 18)));
        end
        else
        begin
          UnitIdx := FUnitFile.Add(Copy(Row, 18, MaxInt));
          FUnitModule.Add('');
        end;
        Continue;
      end;

      // Прочие заголовки разделов
      if (Pos('Publics by', Row) > 0) or (Copy(Row, 1, 13) = 'Bound resourc') or
         (Copy(Row, 1, 7) = 'Program') or (Copy(Row, 1, 5) = 'Start') then
      begin
        InSegments := False;
        UnitIdx := -1;
        Continue;
      end;

      if InSegments then
      begin
        // " 0001:00000000 00006234 C=CODE S=.text G=(none) M=System ACBP=A9"
        Words.Clear;
        ExtractStrings([' ', #9], [], PChar(Row), Words);
        if (Words.Count >= 3) and MapCodeOfs(Words[0], Ofs) then
        begin
          LenValue := StrToIntDef('$' + Words[1], -1);
          if LenValue < 0 then
            Continue;
          SegLen := Cardinal(LenValue);
          ModPart := '';
          for WordIdx := 2 to Words.Count - 1 do
            if Copy(Words[WordIdx], 1, 2) = 'M=' then
              ModPart := Copy(Words[WordIdx], 3, MaxInt);
          if ModPart <> '' then
            AddModule(ModPart, Ofs, SegLen);
        end;
      end
      else if UnitIdx >= 0 then
      begin
        // Пары "номер строки" и "0001:смещение"
        Words.Clear;
        ExtractStrings([' ', #9], [], PChar(Row), Words);
        WordIdx := 0;
        while WordIdx + 1 < Words.Count do
        begin
          LineNo := StrToIntDef(Words[WordIdx], -1);
          if (LineNo > 0) and MapCodeOfs(Words[WordIdx + 1], Ofs) then
          begin
            AddLine(Ofs, LineNo, UnitIdx);
            Inc(WordIdx, 2);
          end
          else
            Inc(WordIdx);
        end;
      end;
    end;
    Result := FLineCount > 0;
    if Result then
      BuildIndex;
  finally
    Words.Free;
    MapText.Free;
  end;
end;

procedure SortOffsets(var AValues: TDbgOffsetArray; ALow, AHigh: Integer);
var
  LeftIdx, RightIdx: Integer;
  Pivot, Swap: Cardinal;
begin
  while ALow < AHigh do
  begin
    LeftIdx := ALow;
    RightIdx := AHigh;
    Pivot := AValues[(ALow + AHigh) shr 1];
    repeat
      while AValues[LeftIdx] < Pivot do
        Inc(LeftIdx);
      while AValues[RightIdx] > Pivot do
        Dec(RightIdx);
      if LeftIdx <= RightIdx then
      begin
        Swap := AValues[LeftIdx];
        AValues[LeftIdx] := AValues[RightIdx];
        AValues[RightIdx] := Swap;
        Inc(LeftIdx);
        Dec(RightIdx);
      end;
    until LeftIdx > RightIdx;
    // Меньшая часть - рекурсией, большая - в цикле: глубина стека мала
    if RightIdx - ALow < AHigh - LeftIdx then
    begin
      if ALow < RightIdx then
        SortOffsets(AValues, ALow, RightIdx);
      ALow := LeftIdx;
    end
    else
    begin
      if LeftIdx < AHigh then
        SortOffsets(AValues, LeftIdx, AHigh);
      AHigh := RightIdx;
    end;
  end;
end;

// Поиск для шагов: после каждой команды - есть ли такое начало строки и
// в модуле ли с номерами строк. Перебор десятков тысяч строк на каждую
// команду был бы медленным, поэтому смещения отсортированы.
procedure TDbgLineMap.BuildIndex;
var
  LineIdx, ModIdx, UnitIdx: Integer;
  SortedOfs: TDbgOffsetArray;
begin
  SetLength(SortedOfs, FLineCount);
  for LineIdx := 0 to FLineCount - 1 do
    SortedOfs[LineIdx] := FLineOfs[LineIdx];
  if FLineCount > 1 then
    SortOffsets(SortedOfs, 0, FLineCount - 1);
  FSortedOfs := SortedOfs;
  FMinOfs := FSortedOfs[0];
  FMaxOfs := FSortedOfs[FLineCount - 1];

  SetLength(FModLines, FModName.Count);
  for ModIdx := 0 to FModName.Count - 1 do
  begin
    FModLines[ModIdx] := False;
    for UnitIdx := 0 to FUnitModule.Count - 1 do
      if CompareText(FUnitModule[UnitIdx], FModName[ModIdx]) = 0 then
      begin
        FModLines[ModIdx] := True;
        Break;
      end;
  end;
end;

function TDbgLineMap.IsLineStart(AOffset: Cardinal): Boolean;
var
  LowIdx, HighIdx, MidIdx: Integer;
begin
  Result := False;
  LowIdx := 0;
  HighIdx := Length(FSortedOfs) - 1;
  while LowIdx <= HighIdx do
  begin
    MidIdx := (LowIdx + HighIdx) shr 1;
    if FSortedOfs[MidIdx] = AOffset then
    begin
      Result := True;
      Exit;
    end;
    if FSortedOfs[MidIdx] < AOffset then
      LowIdx := MidIdx + 1
    else
      HighIdx := MidIdx - 1;
  end;
end;

function TDbgLineMap.HasLines(AOffset: Cardinal): Boolean;
var
  ModIdx: Integer;
begin
  Result := False;
  if Length(FSortedOfs) = 0 then
    Exit;
  // Карта без раздела сегментов - хотя бы в пределах кода со строками
  if FModName.Count = 0 then
  begin
    Result := (AOffset >= FMinOfs) and (AOffset <= FMaxOfs);
    Exit;
  end;
  for ModIdx := 0 to FModName.Count - 1 do
    if (AOffset >= FModStart[ModIdx]) and
       (AOffset < FModStart[ModIdx] + FModLen[ModIdx]) then
    begin
      Result := FModLines[ModIdx];
      Exit;
    end;
end;

procedure TDbgLineMap.OffsetsOfLine(const AFileName: string; ALine: Integer;
                                    AOffsets: TList);
var
  UnitMatch: array of Boolean;
  BestOfs: array of Cardinal;
  BestSet: array of Boolean;
  UnitIdx, LineIdx: Integer;
  AnyMatch: Boolean;
begin
  AOffsets.Clear;
  SetLength(UnitMatch, FUnitFile.Count);
  SetLength(BestOfs, FUnitFile.Count);
  SetLength(BestSet, FUnitFile.Count);
  AnyMatch := False;
  for UnitIdx := 0 to FUnitFile.Count - 1 do
  begin
    UnitMatch[UnitIdx] := CompareText(FUnitFile[UnitIdx], AFileName) = 0;
    BestSet[UnitIdx] := False;
    if UnitMatch[UnitIdx] then
      AnyMatch := True;
  end;
  if not AnyMatch then
    Exit;
  // У строки бывает несколько адресов (заголовок цикла for - начало и
  // проверка). Точка - на первом, как в Delphi.
  for LineIdx := 0 to FLineCount - 1 do
    if (FLineNum[LineIdx] = ALine) and UnitMatch[FLineUnit[LineIdx]] then
    begin
      UnitIdx := FLineUnit[LineIdx];
      if not BestSet[UnitIdx] or (FLineOfs[LineIdx] < BestOfs[UnitIdx]) then
      begin
        BestOfs[UnitIdx] := FLineOfs[LineIdx];
        BestSet[UnitIdx] := True;
      end;
    end;
  for UnitIdx := 0 to FUnitFile.Count - 1 do
    if BestSet[UnitIdx] and (AOffsets.IndexOf(Pointer(BestOfs[UnitIdx])) < 0) then
      AOffsets.Add(Pointer(BestOfs[UnitIdx]));
end;

function TDbgLineMap.LineOfOffset(AOffset: Cardinal; var AFileName: string;
                                  var ALine: Integer): Boolean;
var
  ModIdx, UnitIdx, LineIdx, BestIdx: Integer;
  ModWanted: string;
  UnitAllowed: array of Boolean;
begin
  Result := False;
  AFileName := '';
  ALine := 0;
  // Модуль, в чей код попало смещение. Без него ближайшая строка могла бы
  // оказаться в соседнем модуле: у модулей без отладочной информации (VCL)
  // строк нет.
  ModWanted := '';
  for ModIdx := 0 to FModName.Count - 1 do
    if (AOffset >= FModStart[ModIdx]) and
       (AOffset < FModStart[ModIdx] + FModLen[ModIdx]) then
    begin
      ModWanted := FModName[ModIdx];
      Break;
    end;
  SetLength(UnitAllowed, FUnitFile.Count);
  for UnitIdx := 0 to FUnitFile.Count - 1 do
    UnitAllowed[UnitIdx] := (ModWanted = '') or (FModName.Count = 0) or
                            (CompareText(FUnitModule[UnitIdx], ModWanted) = 0);
  BestIdx := -1;
  for LineIdx := 0 to FLineCount - 1 do
    if (FLineOfs[LineIdx] <= AOffset) and UnitAllowed[FLineUnit[LineIdx]] then
      if (BestIdx < 0) or (FLineOfs[LineIdx] > FLineOfs[BestIdx]) then
        BestIdx := LineIdx;
  if BestIdx < 0 then
    Exit;
  AFileName := FUnitFile[FLineUnit[BestIdx]];
  ALine := FLineNum[BestIdx];
  Result := True;
end;

// ---------------------------------------------------------------------------
//  TDbgSession
// ---------------------------------------------------------------------------

constructor TDbgSession.Create(const AExeFile, AWorkDir: string;
                               AMap: TDbgLineMap);
begin
  inherited Create;
  FExeFile := AExeFile;
  FWorkDir := AWorkDir;
  FMap := AMap;
  InitializeCriticalSection(FLock);
  FResumeEvent := CreateEvent(nil, False, False, nil);
  FWnd := Classes.AllocateHWnd(WndProc);
end;

destructor TDbgSession.Destroy;
begin
  if FThread <> nil then
  begin
    if not FFinished then
      Kill;
    // Программа снята - цикл отладки получит EXIT_PROCESS и закончится
    if WaitForSingleObject(FThread.Handle, 10000) = WAIT_OBJECT_0 then
      FreeAndNil(FThread)
    else
      FLeaked := True;
  end;
  Classes.DeallocateHWnd(FWnd);
  FWnd := 0;
  // Поток не закончился - он ещё обращается к очереди и событию, их не
  // освобождаем (такого быть не должно, это страховка от падения)
  if FLeaked then
    Exit;
  CloseHandle(FResumeEvent);
  DeleteCriticalSection(FLock);
  FMap.Free;
  inherited;
end;

procedure TDbgSession.Start;
begin
  if FStarted then
    Exit;
  FStarted := True;
  FThread := TDbgThread.Create(Self);
  FThread.Resume;
end;

procedure TDbgSession.SetBreakpoint(AOffset: Cardinal; AOn: Boolean);
begin
  EnterCriticalSection(FLock);
  try
    if FPendCount = Length(FPendOfs) then
    begin
      SetLength(FPendOfs, FPendCount + 16);
      SetLength(FPendOn, FPendCount + 16);
    end;
    FPendOfs[FPendCount] := AOffset;
    FPendOn[FPendCount] := AOn;
    Inc(FPendCount);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

// Команда потоку отладки. На остановке - выполнить её и идти; до Start -
// запомнить цели первого хода (только Run to cursor).
procedure TDbgSession.Command(AMode: Integer; AOffsets: TList);
var
  OfsIdx, OfsCount: Integer;
begin
  if FStarted and not FPaused then
    Exit;
  EnterCriticalSection(FLock);
  try
    FCmdMode := AMode;
    OfsCount := 0;
    if AOffsets <> nil then
      OfsCount := AOffsets.Count;
    SetLength(FCmdOfs, OfsCount);
    for OfsIdx := 0 to OfsCount - 1 do
      FCmdOfs[OfsIdx] := Cardinal(AOffsets[OfsIdx]);
  finally
    LeaveCriticalSection(FLock);
  end;
  if not FStarted then
    Exit;
  FPaused := False;
  SetEvent(FResumeEvent);
end;

procedure TDbgSession.Resume;
begin
  if not FPaused then
    Exit;
  Command(DbgCmdGo, nil);
end;

procedure TDbgSession.StepInto;
begin
  if not FPaused then
    Exit;
  Command(DbgCmdInto, nil);
end;

procedure TDbgSession.StepOver;
begin
  if not FPaused then
    Exit;
  Command(DbgCmdOver, nil);
end;

procedure TDbgSession.RunTo(AOffsets: TList);
begin
  if (AOffsets = nil) or (AOffsets.Count = 0) then
    Exit;
  if FStarted and not FPaused then
    Exit;
  Command(DbgCmdRunTo, AOffsets);
end;

procedure TDbgSession.Kill;
begin
  EnterCriticalSection(FLock);
  try
    FKillWanted := True;
    if FProcess <> 0 then
      TerminateProcess(FProcess, 1);
  finally
    LeaveCriticalSection(FLock);
  end;
  FPaused := False;
  // Стоит на точке - пусть идёт дальше, к EXIT_PROCESS
  SetEvent(FResumeEvent);
end;

procedure TDbgSession.PushNote(AKind: Integer; AAddress, AValue: Cardinal;
                               const AText: string);
begin
  EnterCriticalSection(FLock);
  try
    if FNoteCount = Length(FNotes) then
      SetLength(FNotes, FNoteCount + 32);
    FNotes[FNoteCount].Kind := AKind;
    FNotes[FNoteCount].Address := AAddress;
    FNotes[FNoteCount].Value := AValue;
    FNotes[FNoteCount].Text := AText;
    Inc(FNoteCount);
  finally
    LeaveCriticalSection(FLock);
  end;
  if FWnd <> 0 then
    PostMessage(FWnd, WM_DBG_NOTE, 0, 0);
end;

procedure TDbgSession.WndProc(var Msg: TMessage);
begin
  if Msg.Msg = WM_DBG_NOTE then
  begin
    DrainNotes;
    Msg.Result := 0;
  end
  else
    Msg.Result := DefWindowProc(FWnd, Msg.Msg, Msg.WParam, Msg.LParam);
end;

// Место в исходнике словами: ", Unit1.pas строка 123"; не нашлось - адрес
function TDbgSession.WhereText(AAddress: Cardinal): string;
var
  SrcFile: string;
  SrcLine: Integer;
begin
  Result := ' по адресу $' + IntToHex(AAddress, 8);
  if (FCodeBase = 0) or (AAddress < FCodeBase) then
    Exit;
  if FMap.LineOfOffset(AAddress - FCodeBase, SrcFile, SrcLine) then
    Result := Result + ', ' + SrcFile + ' строка ' + IntToStr(SrcLine);
end;

procedure TDbgSession.DrainNotes;
var
  Batch: array of TDbgNote;
  BatchCount, NoteIdx: Integer;
begin
  EnterCriticalSection(FLock);
  try
    BatchCount := FNoteCount;
    SetLength(Batch, BatchCount);
    for NoteIdx := 0 to BatchCount - 1 do
    begin
      Batch[NoteIdx] := FNotes[NoteIdx];
      FNotes[NoteIdx].Text := '';
    end;
    FNoteCount := 0;
  finally
    LeaveCriticalSection(FLock);
  end;

  for NoteIdx := 0 to BatchCount - 1 do
    case Batch[NoteIdx].Kind of
      DbgNoteCodeBase:
        FCodeBase := Batch[NoteIdx].Address;
      DbgNoteLog:
        if Assigned(FOnLog) then
          FOnLog(Self, Batch[NoteIdx].Text);
      DbgNoteException:
        begin
          Inc(FExcLogged);
          if FExcLogged <= DbgMaxExcLog then
          begin
            if Assigned(FOnLog) then
              FOnLog(Self, Batch[NoteIdx].Text +
                     WhereText(Batch[NoteIdx].Address));
          end
          else if (FExcLogged = DbgMaxExcLog + 1) and Assigned(FOnLog) then
            FOnLog(Self, 'Отладчик: исключений больше ' +
                   IntToStr(DbgMaxExcLog) + ', дальше в лог не пишутся');
        end;
      DbgNoteStopped:
        begin
          FPaused := True;
          if Assigned(FOnStopped) then
            FOnStopped(Self, Batch[NoteIdx].Address - FCodeBase);
        end;
      DbgNoteExited:
        begin
          FFinished := True;
          FPaused := False;
          if Assigned(FOnExited) then
            FOnExited(Self, Batch[NoteIdx].Value);
        end;
    end;
end;

// ---------------------------------------------------------------------------
//  TDbgThread
// ---------------------------------------------------------------------------

constructor TDbgThread.Create(AOwner: TDbgSession);
begin
  inherited Create(True);
  FOwner := AOwner;
  FMap := AOwner.FMap;
  FreeOnTerminate := False;
end;

function TDbgThread.StartProcess: Boolean;
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  CmdLine: string;
begin
  Result := False;
  CmdLine := '"' + FOwner.FExeFile + '"';
  FillChar(StartInfo, SizeOf(StartInfo), 0);
  StartInfo.cb := SizeOf(StartInfo);
  FillChar(ProcInfo, SizeOf(ProcInfo), 0);
  if not CreateProcess(nil, PChar(CmdLine), nil, nil, False,
                       DbgOnlyThisProcess, nil, PChar(FOwner.FWorkDir),
                       StartInfo, ProcInfo) then
  begin
    FOwner.PushNote(DbgNoteLog, 0, 0, 'Отладчик: запуск не удался (' +
                    SysErrorMessage(GetLastError) + '): ' + FOwner.FExeFile);
    Exit;
  end;
  // Поток программы придёт с событием CREATE_PROCESS своим дескриптором
  CloseHandle(ProcInfo.hThread);
  FProcess := ProcInfo.hProcess;
  FProcessId := ProcInfo.dwProcessId;
  EnterCriticalSection(FOwner.FLock);
  try
    FOwner.FProcess := FProcess;
    // Program reset нажали, пока процесс создавался
    if FOwner.FKillWanted then
      TerminateProcess(FProcess, 1);
  finally
    LeaveCriticalSection(FOwner.FLock);
  end;
  Result := True;
end;

// Начало первой секции кода по заголовку PE образа в памяти программы
function TDbgThread.ReadCodeBase(AImageBase: Cardinal): Cardinal;
var
  Head: array[0..4095] of Byte;
  Done: DWORD;
  DosHead: PImageDosHeader;
  NtHead: PImageNtHeaders;
  SecHead: PImageSectionHeader;
  SecIdx: Integer;
begin
  Result := 0;
  if not DbgReadMemory(FProcess, Pointer(AImageBase), @Head, SizeOf(Head),
                       Done) then
    Exit;
  DosHead := PImageDosHeader(@Head);
  if (DosHead^.e_magic <> IMAGE_DOS_SIGNATURE) or (DosHead^._lfanew < 0) or
     (DosHead^._lfanew > SizeOf(Head) - SizeOf(TImageNtHeaders)) then
    Exit;
  NtHead := PImageNtHeaders(Cardinal(@Head) + Cardinal(DosHead^._lfanew));
  if NtHead^.Signature <> IMAGE_NT_SIGNATURE then
    Exit;
  SecHead := PImageSectionHeader(Cardinal(@NtHead^.OptionalHeader) +
                                 NtHead^.FileHeader.SizeOfOptionalHeader);
  for SecIdx := 0 to NtHead^.FileHeader.NumberOfSections - 1 do
  begin
    if Cardinal(SecHead) + SizeOf(TImageSectionHeader) >
       Cardinal(@Head) + SizeOf(Head) then
      Exit;
    if (SecHead^.Characteristics and IMAGE_SCN_CNT_CODE) <> 0 then
    begin
      Result := AImageBase + SecHead^.VirtualAddress;
      Exit;
    end;
    Inc(SecHead);
  end;
end;

// Один байт кода: прежний - в AOldValue. Страница кода только для чтения -
// на время записи права меняются.
function TDbgThread.PokeByte(AAddress: Cardinal; AValue: Byte;
                             var AOldValue: Byte): Boolean;
var
  Done: DWORD;
  OldProtect, TmpProtect: DWORD;
  ProtectOk: Boolean;
begin
  Result := False;
  if not DbgReadMemory(FProcess, Pointer(AAddress), @AOldValue, 1, Done) then
    Exit;
  ProtectOk := DbgVirtualProtectEx(FProcess, Pointer(AAddress), 1,
                                   PAGE_EXECUTE_READWRITE, OldProtect);
  Result := DbgWriteMemory(FProcess, Pointer(AAddress), @AValue, 1, Done) and
            (Done = 1);
  if ProtectOk then
    DbgVirtualProtectEx(FProcess, Pointer(AAddress), 1, OldProtect,
                        TmpProtect);
  DbgFlushInstructionCache(FProcess, Pointer(AAddress), 1);
end;

function TDbgThread.ReadDword(AAddress: Cardinal;
                              var AValue: Cardinal): Boolean;
var
  Done: DWORD;
begin
  Result := DbgReadMemory(FProcess, Pointer(AAddress), @AValue, 4, Done) and
            (Done = 4);
end;

function TDbgThread.ReadAnsi(AAddress: Cardinal; ALen: Integer): string;
var
  Done: DWORD;
begin
  Result := '';
  if (AAddress = 0) or (ALen <= 0) then
    Exit;
  SetLength(Result, ALen);
  if not DbgReadMemory(FProcess, Pointer(AAddress), PChar(Result), ALen,
                       Done) then
  begin
    Result := '';
    Exit;
  end;
  SetLength(Result, Done);
end;

function TDbgThread.FindBreak(AAddress: Cardinal): Integer;
var
  BreakIdx: Integer;
begin
  Result := -1;
  for BreakIdx := 0 to High(FBreaks) do
    if FBreaks[BreakIdx].Address = AAddress then
    begin
      Result := BreakIdx;
      Exit;
    end;
end;

function TDbgThread.IsGone(AAddress: Cardinal): Boolean;
var
  GoneIdx: Integer;
begin
  Result := False;
  for GoneIdx := 0 to High(FGone) do
    if FGone[GoneIdx] = AAddress then
    begin
      Result := True;
      Exit;
    end;
end;

// Точка по адресу: пользовательская (ATemp = False) или временная. Новый
// адрес - INT3 сразу. У адреса, где точка уже есть, только счётчик:
// снятый на остановке INT3 вернёт шаг через него (TDbgRearm).
procedure TDbgThread.BreakAdd(AAddress: Cardinal; ATemp: Boolean);
var
  BreakIdx: Integer;
  OldByte: Byte;
begin
  BreakIdx := FindBreak(AAddress);
  if BreakIdx < 0 then
  begin
    BreakIdx := Length(FBreaks);
    SetLength(FBreaks, BreakIdx + 1);
    FBreaks[BreakIdx].Address := AAddress;
    FBreaks[BreakIdx].UserRef := 0;
    FBreaks[BreakIdx].TempRef := 0;
    FBreaks[BreakIdx].Inserted := PokeByte(AAddress, DbgInt3, OldByte);
    FBreaks[BreakIdx].OrigByte := OldByte;
    if not FBreaks[BreakIdx].Inserted then
      FOwner.PushNote(DbgNoteLog, 0, 0, 'Отладчик: не удалось поставить ' +
                      'точку по адресу $' + IntToHex(AAddress, 8));
  end;
  if ATemp then
    Inc(FBreaks[BreakIdx].TempRef)
  else
    Inc(FBreaks[BreakIdx].UserRef);
end;

procedure TDbgThread.BreakRelease(AAddress: Cardinal; ATemp: Boolean);
var
  BreakIdx, GoneIdx: Integer;
  OldByte: Byte;
begin
  BreakIdx := FindBreak(AAddress);
  if BreakIdx < 0 then
    Exit;
  if ATemp then
  begin
    if FBreaks[BreakIdx].TempRef > 0 then
      Dec(FBreaks[BreakIdx].TempRef);
  end
  else if FBreaks[BreakIdx].UserRef > 0 then
    Dec(FBreaks[BreakIdx].UserRef);
  if FBreaks[BreakIdx].UserRef + FBreaks[BreakIdx].TempRef > 0 then
    Exit;
  if FBreaks[BreakIdx].Inserted then
    PokeByte(AAddress, FBreaks[BreakIdx].OrigByte, OldByte);
  FBreaks[BreakIdx] := FBreaks[High(FBreaks)];
  SetLength(FBreaks, Length(FBreaks) - 1);
  // Другой поток мог уже выполнить INT3 - его событие ещё в очереди
  if not IsGone(AAddress) then
  begin
    GoneIdx := Length(FGone);
    SetLength(FGone, GoneIdx + 1);
    FGone[GoneIdx] := AAddress;
  end;
end;

// INT3 на время убрать (точка остаётся в списке): поток стоит на этом
// адресе или проходит его одной командой
procedure TDbgThread.BreakLift(AAddress: Cardinal);
var
  BreakIdx: Integer;
  OldByte: Byte;
begin
  BreakIdx := FindBreak(AAddress);
  if (BreakIdx < 0) or not FBreaks[BreakIdx].Inserted then
    Exit;
  PokeByte(AAddress, FBreaks[BreakIdx].OrigByte, OldByte);
  FBreaks[BreakIdx].Inserted := False;
end;

// Изменения точек из главного потока. Пока не известно начало кода
// (событие CREATE_PROCESS ещё не пришло) - ждут.
procedure TDbgThread.ApplyPending;
var
  PendOfs: array of Cardinal;
  PendOn: array of Boolean;
  PendCount, PendIdx: Integer;
begin
  if FCodeBase = 0 then
    Exit;
  EnterCriticalSection(FOwner.FLock);
  try
    PendCount := FOwner.FPendCount;
    SetLength(PendOfs, PendCount);
    SetLength(PendOn, PendCount);
    for PendIdx := 0 to PendCount - 1 do
    begin
      PendOfs[PendIdx] := FOwner.FPendOfs[PendIdx];
      PendOn[PendIdx] := FOwner.FPendOn[PendIdx];
    end;
    FOwner.FPendCount := 0;
  finally
    LeaveCriticalSection(FOwner.FLock);
  end;
  for PendIdx := 0 to PendCount - 1 do
    if PendOn[PendIdx] then
      BreakAdd(FCodeBase + PendOfs[PendIdx], False)
    else
      BreakRelease(FCodeBase + PendOfs[PendIdx], False);
end;

function TDbgThread.ThreadHandleOf(AThreadId: DWORD): THandle;
var
  RefIdx: Integer;
begin
  Result := 0;
  for RefIdx := 0 to High(FThreads) do
    if FThreads[RefIdx].ThreadId = AThreadId then
    begin
      Result := FThreads[RefIdx].Handle;
      Exit;
    end;
end;

procedure TDbgThread.AddThread(AThreadId: DWORD; AHandle: THandle);
var
  RefIdx: Integer;
begin
  RefIdx := Length(FThreads);
  SetLength(FThreads, RefIdx + 1);
  FThreads[RefIdx].ThreadId := AThreadId;
  FThreads[RefIdx].Handle := AHandle;
end;

// Дескрипторы потоков закрывает система (после ContinueDebugEvent на
// EXIT_THREAD), здесь только запись. Шаг этого потока кончен.
procedure TDbgThread.RemoveThread(AThreadId: DWORD);
var
  RefIdx: Integer;
begin
  if FStepThread = AThreadId then
    CancelStep;
  while TakeRearm(AThreadId) do
    ;
  while TakeStale(AThreadId) do
    ;
  for RefIdx := 0 to High(FThreads) do
    if FThreads[RefIdx].ThreadId = AThreadId then
    begin
      FThreads[RefIdx] := FThreads[High(FThreads)];
      SetLength(FThreads, Length(FThreads) - 1);
      Exit;
    end;
end;

// EIP потока; ATrace - ещё и флаг трассировки: остановка после одной
// команды (EXCEPTION_SINGLE_STEP)
function TDbgThread.SetEip(AThreadId: DWORD; AEip: Cardinal;
                           ATrace: Boolean): Boolean;
var
  ThreadHandle: THandle;
  Ctx: TContext;
begin
  Result := False;
  ThreadHandle := ThreadHandleOf(AThreadId);
  if ThreadHandle = 0 then
    Exit;
  FillChar(Ctx, SizeOf(Ctx), 0);
  Ctx.ContextFlags := CONTEXT_CONTROL;
  if not GetThreadContext(ThreadHandle, Ctx) then
    Exit;
  if AEip <> 0 then
    Ctx.Eip := AEip;
  if ATrace then
    Ctx.EFlags := Ctx.EFlags or DbgTrapFlag
  else
    Ctx.EFlags := Ctx.EFlags and not DbgTrapFlag;
  Result := SetThreadContext(ThreadHandle, Ctx);
end;

function TDbgThread.SetTrace(AThreadId: DWORD; AOn: Boolean): Boolean;
begin
  Result := SetEip(AThreadId, 0, AOn);
end;

function TDbgThread.GetEipEsp(AThreadId: DWORD;
                              var AEip, AEsp: Cardinal): Boolean;
var
  ThreadHandle: THandle;
  Ctx: TContext;
begin
  Result := False;
  AEip := 0;
  AEsp := 0;
  ThreadHandle := ThreadHandleOf(AThreadId);
  if ThreadHandle = 0 then
    Exit;
  FillChar(Ctx, SizeOf(Ctx), 0);
  Ctx.ContextFlags := CONTEXT_CONTROL;
  if not GetThreadContext(ThreadHandle, Ctx) then
    Exit;
  AEip := Ctx.Eip;
  AEsp := Ctx.Esp;
  Result := True;
end;

// Адрес в коде модуля, у которого есть номера строк
function TDbgThread.InLineCode(AAddress: Cardinal): Boolean;
begin
  Result := (FCodeBase <> 0) and (AAddress >= FCodeBase) and
            FMap.HasLines(AAddress - FCodeBase);
end;

// Адрес - начало строки по .map
function TDbgThread.IsLineAddress(AAddress: Cardinal): Boolean;
begin
  Result := (FCodeBase <> 0) and (AAddress >= FCodeBase) and
            FMap.IsLineStart(AAddress - FCodeBase);
end;

procedure TDbgThread.AddRearm(AThreadId: DWORD; AAddress: Cardinal);
var
  RearmIdx: Integer;
begin
  RearmIdx := Length(FRearms);
  SetLength(FRearms, RearmIdx + 1);
  FRearms[RearmIdx].ThreadId := AThreadId;
  FRearms[RearmIdx].Address := AAddress;
end;

// Поток прошёл одну команду: INT3 обратно на адрес, который он проходил.
// False - для потока такой записи нет.
function TDbgThread.TakeRearm(AThreadId: DWORD): Boolean;
var
  RearmIdx, BreakIdx: Integer;
  RearmAddr: Cardinal;
  OldByte: Byte;
begin
  Result := False;
  for RearmIdx := 0 to High(FRearms) do
    if FRearms[RearmIdx].ThreadId = AThreadId then
    begin
      RearmAddr := FRearms[RearmIdx].Address;
      FRearms[RearmIdx] := FRearms[High(FRearms)];
      SetLength(FRearms, Length(FRearms) - 1);
      BreakIdx := FindBreak(RearmAddr);
      if (BreakIdx >= 0) and not FBreaks[BreakIdx].Inserted then
        FBreaks[BreakIdx].Inserted := PokeByte(RearmAddr, DbgInt3, OldByte);
      Result := True;
      Exit;
    end;
end;

procedure TDbgThread.AddStale(AThreadId: DWORD);
var
  StaleIdx: Integer;
begin
  for StaleIdx := 0 to High(FStale) do
    if FStale[StaleIdx] = AThreadId then
      Exit;
  StaleIdx := Length(FStale);
  SetLength(FStale, StaleIdx + 1);
  FStale[StaleIdx] := AThreadId;
end;

function TDbgThread.TakeStale(AThreadId: DWORD): Boolean;
var
  StaleIdx: Integer;
begin
  Result := False;
  for StaleIdx := 0 to High(FStale) do
    if FStale[StaleIdx] = AThreadId then
    begin
      FStale[StaleIdx] := FStale[High(FStale)];
      SetLength(FStale, Length(FStale) - 1);
      Result := True;
      Exit;
    end;
end;

procedure TDbgThread.AddRunTo(AAddress: Cardinal);
var
  RunIdx: Integer;
begin
  if IsRunTo(AAddress) then
    Exit;
  BreakAdd(AAddress, True);
  RunIdx := Length(FRunTo);
  SetLength(FRunTo, RunIdx + 1);
  FRunTo[RunIdx] := AAddress;
end;

function TDbgThread.IsRunTo(AAddress: Cardinal): Boolean;
var
  RunIdx: Integer;
begin
  Result := False;
  for RunIdx := 0 to High(FRunTo) do
    if FRunTo[RunIdx] = AAddress then
    begin
      Result := True;
      Exit;
    end;
end;

procedure TDbgThread.ClearRunTo;
var
  RunIdx: Integer;
begin
  for RunIdx := 0 to High(FRunTo) do
    BreakRelease(FRunTo[RunIdx], True);
  SetLength(FRunTo, 0);
end;

// Шаг прерван (остановка в другом месте, исключение, конец потока).
// Флаг трассировки снимается; если SINGLE_STEP потока уже в очереди,
// его съест TakeStale.
procedure TDbgThread.CancelStep;
begin
  if FStepThread = 0 then
    Exit;
  case FStepPhase of
    DbgPhaseTrace:
      begin
        SetTrace(FStepThread, False);
        AddStale(FStepThread);
      end;
    DbgPhaseReturn:
      BreakRelease(FRetAddr, True);
  end;
  FStepThread := 0;
  FStepMode := DbgCmdGo;
  FStepPhase := DbgPhaseNone;
  FRetAddr := 0;
  FRetEsp := 0;
end;

procedure TDbgThread.ReadCommand(var AMode: Integer;
                                 var AOffsets: TDbgOffsetArray);
var
  OfsIdx: Integer;
begin
  EnterCriticalSection(FOwner.FLock);
  try
    AMode := FOwner.FCmdMode;
    SetLength(AOffsets, Length(FOwner.FCmdOfs));
    for OfsIdx := 0 to High(FOwner.FCmdOfs) do
      AOffsets[OfsIdx] := FOwner.FCmdOfs[OfsIdx];
    FOwner.FCmdMode := DbgCmdGo;
    SetLength(FOwner.FCmdOfs, 0);
  finally
    LeaveCriticalSection(FOwner.FLock);
  end;
end;

// Остановка: ждём команду или Program reset. Точки, включённые и
// снятые на остановке, ставятся сразу. False - программу снимают.
function TDbgThread.WaitResume: Boolean;
var
  WaitRes: DWORD;
begin
  repeat
    WaitRes := WaitForSingleObject(FOwner.FResumeEvent, 100);
    ApplyPending;
  until (WaitRes = WAIT_OBJECT_0) or FOwner.FKillWanted;
  Result := not FOwner.FKillWanted;
end;

// Поток AThreadId стоит на AAddress (EIP уже там). Шаг и временные точки
// снимаются, главный поток показывает строку, дальше - по команде.
function TDbgThread.PauseAt(AThreadId: DWORD; AAddress: Cardinal): DWORD;
var
  CmdMode, OfsIdx: Integer;
  CmdOfs: TDbgOffsetArray;
  NeedRearm: Boolean;
begin
  Result := DbgContinue;
  CancelStep;
  ClearRunTo;
  // Прежний байт на место: так видно настоящий код и с него же программа
  // продолжит
  BreakLift(AAddress);

  FOwner.PushNote(DbgNoteStopped, AAddress, AThreadId, '');
  if not WaitResume then
    Exit;   // Program reset - программа уже снимается

  ReadCommand(CmdMode, CmdOfs);
  if CmdMode = DbgCmdRunTo then
    for OfsIdx := 0 to High(CmdOfs) do
      AddRunTo(FCodeBase + CmdOfs[OfsIdx]);

  // Точка на этом адресе (прежняя, поставленная на остановке или Run to
  // cursor на текущую строку) - INT3 не трогаем до конца первой команды,
  // иначе программа сразу встала бы снова здесь же
  BreakLift(AAddress);
  NeedRearm := FindBreak(AAddress) >= 0;
  if NeedRearm then
    AddRearm(AThreadId, AAddress);

  case CmdMode of
    DbgCmdInto, DbgCmdOver:
      begin
        FStepThread := AThreadId;
        FStepMode := CmdMode;
        FStepPhase := DbgPhaseTrace;
        if not GetEipEsp(AThreadId, FPrevEip, FPrevEsp) or
           not SetTrace(AThreadId, True) then
        begin
          FStepThread := 0;
          FStepPhase := DbgPhaseNone;
          FOwner.PushNote(DbgNoteLog, 0, 0, 'Отладчик: шаг не начат (нет ' +
                          'доступа к регистрам потока) - программа идёт ' +
                          'дальше');
          if NeedRearm then
            SetTrace(AThreadId, True);
        end;
      end;
  else
    // Continue и Run to cursor
    if NeedRearm and not SetTrace(AThreadId, True) then
      FOwner.PushNote(DbgNoteLog, 0, 0, 'Отладчик: точка по адресу $' +
                      IntToHex(AAddress, 8) + ' после остановки не ' +
                      'восстановлена');
  end;
end;

function TDbgThread.OnBreakpoint(AThreadId: DWORD; AAddress: Cardinal): DWORD;
var
  BreakIdx: Integer;
  CurEip, CurEsp: Cardinal;
  UserHit, ReturnHit: Boolean;
begin
  Result := DbgContinue;
  BreakIdx := FindBreak(AAddress);
  if BreakIdx < 0 then
  begin
    if not FLoaderBreakSeen then
      // Системная точка загрузчика - программа ещё не начала работу
      FLoaderBreakSeen := True
    else if IsGone(AAddress) then
      // Наша снятая точка: INT3 выполнен до того, как байт вернули на
      // место, - команду с начала
      SetEip(AThreadId, AAddress, False)
    else
      FOwner.PushNote(DbgNoteLog, 0, 0, 'Отладчик: INT3 в коде программы ' +
                      'по адресу $' + IntToHex(AAddress, 8) + ', идёт дальше');
    Exit;
  end;

  // Наша точка. EIP уже за INT3 - назад на начало команды.
  SetEip(AThreadId, AAddress, False);
  GetEipEsp(AThreadId, CurEip, CurEsp);

  UserHit := (FBreaks[BreakIdx].UserRef > 0) or IsRunTo(AAddress);
  if UserHit then
  begin
    Result := PauseAt(AThreadId, AAddress);
    Exit;
  end;

  // Возврат из вызова, через который шёл шаг: тот же поток и стек выше,
  // чем был внутри вызова (не рекурсивный вызов той же процедуры)
  ReturnHit := (FStepPhase = DbgPhaseReturn) and
               (AThreadId = FStepThread) and (AAddress = FRetAddr) and
               (CurEsp > FRetEsp);
  if ReturnHit then
  begin
    BreakRelease(FRetAddr, True);
    FRetAddr := 0;
    FRetEsp := 0;
    if IsLineAddress(AAddress) then
    begin
      // Вызов был последней командой строки - следующая строка уже здесь
      FStepThread := 0;
      FStepPhase := DbgPhaseNone;
      Result := PauseAt(AThreadId, AAddress);
      Exit;
    end;
    FStepPhase := DbgPhaseTrace;
    FPrevEip := AAddress;
    FPrevEsp := CurEsp;
    if not SetTrace(AThreadId, True) then
      CancelStep;
    Exit;
  end;

  // Временная точка, но не для этого потока или не этот уровень стека:
  // поток проходит её одной командой, INT3 возвращается после неё
  BreakLift(AAddress);
  AddRearm(AThreadId, AAddress);
  SetTrace(AThreadId, True);
end;

function TDbgThread.OnSingleStep(AThreadId: DWORD): DWORD;
var
  Rearmed: Boolean;
begin
  Result := DbgContinue;
  Rearmed := TakeRearm(AThreadId);
  if (FStepThread = AThreadId) and (FStepPhase = DbgPhaseTrace) then
  begin
    Result := StepEvent(AThreadId);
    Exit;
  end;
  if Rearmed then
  begin
    SetTrace(AThreadId, False);
    Exit;
  end;
  // Флаг сняли при прерванном шаге, а событие уже было в очереди
  if TakeStale(AThreadId) then
    Exit;
  // Не наше - программе
  Result := DbgNotHandled;
end;

// Поток шага выполнил одну команду
function TDbgThread.StepEvent(AThreadId: DWORD): DWORD;
var
  CurEip, CurEsp, RetAddr: Cardinal;
  CallMade, InLines: Boolean;
begin
  Result := DbgContinue;
  if not GetEipEsp(AThreadId, CurEip, CurEsp) then
  begin
    CancelStep;
    Exit;
  end;

  // Была ли команда CALL: ESP меньше на 4, на вершине стека адрес сразу
  // за прежней командой, а EIP ушёл за её пределы
  CallMade := (CurEsp = FPrevEsp - 4) and ReadDword(CurEsp, RetAddr) and
              (RetAddr > FPrevEip + 1) and (RetAddr <= FPrevEip + 7) and
              ((CurEip < FPrevEip) or (CurEip > FPrevEip + 7));
  InLines := InLineCode(CurEip);

  if CallMade and ((FStepMode = DbgCmdOver) or not InLines) then
  begin
    // Вызов проходится целиком: свободно до адреса возврата
    FRetAddr := RetAddr;
    FRetEsp := CurEsp;
    BreakAdd(FRetAddr, True);
    FStepPhase := DbgPhaseReturn;
    SetTrace(AThreadId, False);
    Exit;
  end;

  if InLines and IsLineAddress(CurEip) then
  begin
    // Шаг дошёл до строки. Флаг трассировки уже снят процессором - шаг
    // закончен без CancelStep (тот пометил бы поток как прерванный).
    FStepThread := 0;
    FStepPhase := DbgPhaseNone;
    Result := PauseAt(AThreadId, CurEip);
    Exit;
  end;

  if not InLines then
  begin
    // Не через CALL: возврат из процедуры в вызывающий код без номеров
    // строк (RTL, VCL) или переход туда. Дальше программа идёт сама.
    FStepThread := 0;
    FStepPhase := DbgPhaseNone;
    SetTrace(AThreadId, False);
    FOwner.PushNote(DbgNoteLog, 0, 0, 'Отладчик: шаг вышел в код без ' +
                    'номеров строк (адрес $' + IntToHex(CurEip, 8) +
                    ') - программа идёт дальше до точки останова');
    Exit;
  end;

  // Та же строка - следующая команда
  FPrevEip := CurEip;
  FPrevEsp := CurEsp;
  if not SetTrace(AThreadId, True) then
    CancelStep;
end;

// Исключение Delphi: класс и сообщение из памяти программы.
// AInfo[1] - объект исключения; у объекта первым полем - VMT, у VMT по
// смещению vmtClassName - имя класса (ShortString); у Exception первое
// поле - FMessage.
function TDbgThread.DelphiExceptionText(const AInfo: array of DWORD): string;
var
  ObjAddr, VmtAddr, NameAddr, MsgAddr, MsgLen: Cardinal;
  LenByte: string;
  ClsName, MsgText: string;
begin
  Result := '';
  if High(AInfo) < 1 then
    Exit;
  ObjAddr := AInfo[1];
  if (ObjAddr = 0) or not ReadDword(ObjAddr, VmtAddr) then
    Exit;
  ClsName := '';
  if ReadDword(Cardinal(Integer(VmtAddr) + DbgVmtClassName), NameAddr) then
  begin
    LenByte := ReadAnsi(NameAddr, 1);
    if LenByte <> '' then
      ClsName := ReadAnsi(NameAddr + 1, Ord(LenByte[1]));
  end;
  MsgText := '';
  if ReadDword(ObjAddr + 4, MsgAddr) and (MsgAddr <> 0) and
     ReadDword(MsgAddr - 4, MsgLen) then
  begin
    if MsgLen > 1024 then
      MsgLen := 1024;
    MsgText := ReadAnsi(MsgAddr, MsgLen);
  end;
  Result := ClsName;
  if MsgText <> '' then
    Result := Result + ': ' + MsgText;
end;

procedure TDbgThread.Execute;
var
  DebugEvt: TDbgDebugEvent;
  Status: DWORD;
  Running: Boolean;
  ExcCode, ExcAddr: Cardinal;
  ImageBase: Cardinal;
  OdsText, ExcText: string;
  OdsLen: Integer;
  IdleAfterExit: Integer;   // пустых ожиданий после конца процесса
  ProcExitCode: DWORD;
  StartMode, StartIdx: Integer;
  StartOfs: TDbgOffsetArray;
begin
  if not StartProcess then
  begin
    FOwner.PushNote(DbgNoteExited, 0, Cardinal(-1), '');
    Exit;
  end;

  Running := True;
  IdleAfterExit := 0;
  while Running do
  begin
    ApplyPending;
    if not DbgWaitForDebugEvent(DebugEvt, 100) then
    begin
      // Нет событий - ещё раз, заодно изменения точек. Страховка: процесс
      // закончился, а EXIT_PROCESS за 5 с так и не пришёл - сеанс кончен.
      if WaitForSingleObject(FProcess, 0) = WAIT_OBJECT_0 then
      begin
        Inc(IdleAfterExit);
        if IdleAfterExit >= 50 then
        begin
          ProcExitCode := 0;
          GetExitCodeProcess(FProcess, ProcExitCode);
          FOwner.PushNote(DbgNoteExited, 0, ProcExitCode, '');
          Running := False;
        end;
      end;
      Continue;
    end;

    Status := DbgContinue;
    case DebugEvt.EventCode of
      DbgEvCreateProcess:
        begin
          if DebugEvt.CreateProcess.FileHandle <> 0 then
            CloseHandle(DebugEvt.CreateProcess.FileHandle);
          AddThread(DebugEvt.ThreadId, DebugEvt.CreateProcess.ThreadHandle);
          ImageBase := Cardinal(DebugEvt.CreateProcess.BaseOfImage);
          FCodeBase := ReadCodeBase(ImageBase);
          if FCodeBase = 0 then
            FOwner.PushNote(DbgNoteLog, 0, 0, 'Отладчик: не найден сегмент ' +
                            'кода в заголовке exe - точки не ставятся')
          else
          begin
            FOwner.PushNote(DbgNoteCodeBase, FCodeBase, 0, '');
            // Образ уже в памяти, код ещё не выполнялся - точки сразу
            ApplyPending;
            // Цели первого хода: Run to cursor до запуска, остановка на
            // входе (F7/F8 до запуска - begin главного блока .dpr)
            ReadCommand(StartMode, StartOfs);
            if StartMode = DbgCmdRunTo then
              for StartIdx := 0 to High(StartOfs) do
                AddRunTo(FCodeBase + StartOfs[StartIdx]);
            if FOwner.FStopAtEntry and
               (DebugEvt.CreateProcess.StartAddress <> nil) then
              AddRunTo(Cardinal(DebugEvt.CreateProcess.StartAddress));
          end;
        end;

      DbgEvCreateThread:
        AddThread(DebugEvt.ThreadId, DebugEvt.CreateThread.ThreadHandle);

      DbgEvExitThread:
        RemoveThread(DebugEvt.ThreadId);

      DbgEvLoadDll:
        if DebugEvt.LoadDll.FileHandle <> 0 then
          CloseHandle(DebugEvt.LoadDll.FileHandle);

      DbgEvDebugString:
        begin
          OdsLen := DebugEvt.DebugString.StringLength;
          if OdsLen > 4096 then
            OdsLen := 4096;
          if DebugEvt.DebugString.Unicode = 0 then
          begin
            OdsText := ReadAnsi(Cardinal(DebugEvt.DebugString.StringData),
                                OdsLen);
            if Pos(#0, OdsText) > 0 then
              SetLength(OdsText, Pos(#0, OdsText) - 1);
            while (OdsText <> '') and (OdsText[Length(OdsText)] in [#13, #10]) do
              SetLength(OdsText, Length(OdsText) - 1);
            FOwner.PushNote(DbgNoteLog, 0, 0, 'ODS: ' + OdsText);
          end;
        end;

      DbgEvException:
        begin
          ExcCode := DebugEvt.Exception.ExceptionRecord.ExceptionCode;
          ExcAddr := Cardinal(DebugEvt.Exception.ExceptionRecord.ExceptionAddress);
          if (ExcCode = DbgExcBreakpoint) or (ExcCode = DbgExcWx86Break) then
            Status := OnBreakpoint(DebugEvt.ThreadId, ExcAddr)
          else if ExcCode = DbgExcSingleStep then
            Status := OnSingleStep(DebugEvt.ThreadId)
          else
          begin
            // Остальные - программе: у неё свои try..except
            Status := DbgNotHandled;
            if (ExcCode <> DbgExcThreadName) and (ExcCode <> DbgExcPrintA) and
               (ExcCode <> DbgExcPrintW) then
            begin
              // Шаг этого потока дальше не ведётся: управление уходит в
              // обработчик исключения
              if (FStepThread <> 0) and (DebugEvt.ThreadId = FStepThread) then
              begin
                CancelStep;
                FOwner.PushNote(DbgNoteLog, 0, 0, 'Отладчик: шаг прерван ' +
                                'исключением - программа идёт дальше до ' +
                                'точки останова');
              end;
              ExcText := '';
              if ExcCode = DbgExcDelphi then
              begin
                ExcText := DelphiExceptionText(
                  DebugEvt.Exception.ExceptionRecord.ExceptionInformation);
                // Адрес raise, а не RaiseException в kernel32
                if DebugEvt.Exception.ExceptionRecord.NumberParameters >= 1 then
                  ExcAddr := DebugEvt.Exception.ExceptionRecord.ExceptionInformation[0];
              end;
              if DebugEvt.Exception.FirstChance <> 0 then
                ExcText := 'Исключение ' + IntToHex(ExcCode, 8) + ' ' + ExcText
              else
                ExcText := 'Необработанное исключение ' + IntToHex(ExcCode, 8) +
                           ' ' + ExcText + ' - программа будет закрыта';
              FOwner.PushNote(DbgNoteException, ExcAddr, ExcCode, ExcText);
            end;
          end;
        end;

      DbgEvExitProcess:
        begin
          FOwner.PushNote(DbgNoteExited, 0, DebugEvt.ExitProcess.ExitCode, '');
          Running := False;
        end;
    end;
    DbgContinueDebugEvent(DebugEvt.ProcessId, DebugEvt.ThreadId, Status);
  end;

  EnterCriticalSection(FOwner.FLock);
  try
    FOwner.FProcess := 0;
  finally
    LeaveCriticalSection(FOwner.FLock);
  end;
  CloseHandle(FProcess);
  FProcess := 0;
end;

end.
