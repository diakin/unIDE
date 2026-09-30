unit DbgEngine;

// ---------------------------------------------------------------------------
//  Отладчик запущенной программы (этап 1): точки останова и продолжение
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
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes;

type
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
    procedure AddLine(AOffset: Cardinal; ALine, AUnit: Integer);
    procedure AddModule(const AName: string; AStart, ALen: Cardinal);
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
    FExcLogged: Integer;      // сколько исключений ушло в лог
    FOnStopped: TDbgStopEvent;
    FOnLog: TDbgLogEvent;
    FOnExited: TDbgExitEvent;
    procedure WndProc(var Msg: TMessage);
    procedure DrainNotes;
    procedure PushNote(AKind: Integer; AAddress, AValue: Cardinal;
                       const AText: string);
    function WhereText(AAddress: Cardinal): string;
  public
    constructor Create(const AExeFile, AWorkDir: string; AMap: TDbgLineMap);
    destructor Destroy; override;
    procedure Start;
    // Точка по смещению от начала сегмента кода (из TDbgLineMap)
    procedure SetBreakpoint(AOffset: Cardinal; AOn: Boolean);
    procedure Resume;
    procedure Kill;
    property Map: TDbgLineMap read FMap;
    property Paused: Boolean read FPaused;
    property Finished: Boolean read FFinished;
    property ExeFile: string read FExeFile;
    property OnStopped: TDbgStopEvent read FOnStopped write FOnStopped;
    property OnLog: TDbgLogEvent read FOnLog write FOnLog;
    property OnExited: TDbgExitEvent read FOnExited write FOnExited;
  end;

  // Точка в процессе программы
  TDbgBreak = record
    Address: Cardinal;
    OrigByte: Byte;
    Inserted: Boolean;   // INT3 сейчас стоит в коде
    RefCount: Integer;   // одна строка может прийти дважды
  end;

  // Поток, прошедший точку по флагу трассировки: после шага INT3 обратно
  TDbgStep = record
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
    FProcess: THandle;
    FProcessId: DWORD;
    FCodeBase: Cardinal;
    FLoaderBreakSeen: Boolean;
    FBreaks: array of TDbgBreak;
    FSteps: array of TDbgStep;
    FThreads: array of TDbgThreadRef;
    FGone: array of Cardinal;   // адреса снятых точек: INT3 мог сработать
    function StartProcess: Boolean;
    function ReadCodeBase(AImageBase: Cardinal): Cardinal;
    function PokeByte(AAddress: Cardinal; AValue: Byte;
                      var AOldValue: Byte): Boolean;
    function ReadDword(AAddress: Cardinal; var AValue: Cardinal): Boolean;
    function ReadAnsi(AAddress: Cardinal; ALen: Integer): string;
    procedure ApplyPending;
    procedure AddBreak(AAddress: Cardinal);
    procedure RemoveBreak(AAddress: Cardinal);
    function FindBreak(AAddress: Cardinal): Integer;
    function IsGone(AAddress: Cardinal): Boolean;
    function ThreadHandleOf(AThreadId: DWORD): THandle;
    procedure AddThread(AThreadId: DWORD; AHandle: THandle);
    procedure RemoveThread(AThreadId: DWORD);
    function SetEip(AThreadId: DWORD; AEip: Cardinal;
                    ATrace: Boolean): Boolean;
    function WaitResume: Boolean;
    function OnBreakpoint(AThreadId: DWORD; AAddress: Cardinal): DWORD;
    function OnSingleStep(AThreadId: DWORD): DWORD;
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
  finally
    Words.Free;
    MapText.Free;
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

procedure TDbgSession.Resume;
begin
  if not FPaused then
    Exit;
  FPaused := False;
  SetEvent(FResumeEvent);
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

procedure TDbgThread.AddBreak(AAddress: Cardinal);
var
  BreakIdx: Integer;
  OldByte: Byte;
begin
  BreakIdx := FindBreak(AAddress);
  if BreakIdx >= 0 then
  begin
    Inc(FBreaks[BreakIdx].RefCount);
    Exit;
  end;
  BreakIdx := Length(FBreaks);
  SetLength(FBreaks, BreakIdx + 1);
  FBreaks[BreakIdx].Address := AAddress;
  FBreaks[BreakIdx].RefCount := 1;
  FBreaks[BreakIdx].Inserted := PokeByte(AAddress, DbgInt3, OldByte);
  FBreaks[BreakIdx].OrigByte := OldByte;
  if not FBreaks[BreakIdx].Inserted then
    FOwner.PushNote(DbgNoteLog, 0, 0, 'Отладчик: не удалось поставить ' +
                    'точку по адресу $' + IntToHex(AAddress, 8));
end;

procedure TDbgThread.RemoveBreak(AAddress: Cardinal);
var
  BreakIdx, GoneIdx: Integer;
  OldByte: Byte;
begin
  BreakIdx := FindBreak(AAddress);
  if BreakIdx < 0 then
    Exit;
  Dec(FBreaks[BreakIdx].RefCount);
  if FBreaks[BreakIdx].RefCount > 0 then
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
      AddBreak(FCodeBase + PendOfs[PendIdx])
    else
      RemoveBreak(FCodeBase + PendOfs[PendIdx]);
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
// EXIT_THREAD), здесь только запись
procedure TDbgThread.RemoveThread(AThreadId: DWORD);
var
  RefIdx: Integer;
begin
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

// Остановка: ждём Continue или Program reset. Точки, включённые и
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

function TDbgThread.OnBreakpoint(AThreadId: DWORD; AAddress: Cardinal): DWORD;
var
  BreakIdx: Integer;
  OldByte: Byte;
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

  // Наша точка. EIP уже за INT3 - назад на начало команды, прежний байт
  // на место: так видно настоящий код и с него же программа продолжит.
  SetEip(AThreadId, AAddress, False);
  if FBreaks[BreakIdx].Inserted then
  begin
    PokeByte(AAddress, FBreaks[BreakIdx].OrigByte, OldByte);
    FBreaks[BreakIdx].Inserted := False;
  end;

  FOwner.PushNote(DbgNoteStopped, AAddress, AThreadId, '');
  if not WaitResume then
    Exit;   // Program reset - программа уже снимается

  // Точку за время остановки могли снять - тогда просто дальше. Иначе одну
  // команду пошагово, после неё INT3 обратно (OnSingleStep).
  BreakIdx := FindBreak(AAddress);
  if BreakIdx < 0 then
    Exit;
  if SetEip(AThreadId, 0, True) then
  begin
    SetLength(FSteps, Length(FSteps) + 1);
    FSteps[High(FSteps)].ThreadId := AThreadId;
    FSteps[High(FSteps)].Address := AAddress;
  end
  else
  begin
    // Шаг не поставить - точка остаётся снятой до следующего запуска
    FOwner.PushNote(DbgNoteLog, 0, 0, 'Отладчик: точка по адресу $' +
                    IntToHex(AAddress, 8) + ' после остановки не ' +
                    'восстановлена');
  end;
end;

function TDbgThread.OnSingleStep(AThreadId: DWORD): DWORD;
var
  StepIdx, BreakIdx: Integer;
  StepAddr: Cardinal;
  OldByte: Byte;
begin
  Result := DbgNotHandled;
  for StepIdx := 0 to High(FSteps) do
    if FSteps[StepIdx].ThreadId = AThreadId then
    begin
      StepAddr := FSteps[StepIdx].Address;
      FSteps[StepIdx] := FSteps[High(FSteps)];
      SetLength(FSteps, Length(FSteps) - 1);
      SetEip(AThreadId, 0, False);
      BreakIdx := FindBreak(StepAddr);
      if (BreakIdx >= 0) and not FBreaks[BreakIdx].Inserted then
        FBreaks[BreakIdx].Inserted := PokeByte(StepAddr, DbgInt3, OldByte);
      Result := DbgContinue;
      Exit;
    end;
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
