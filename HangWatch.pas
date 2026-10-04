unit HangWatch;

// ---------------------------------------------------------------------------
//  Сторож зависаний главного потока
//
//  Отдельный поток раз в секунду посылает окну приложения WM_NULL через
//  SendMessageTimeout. Нет ответа 3 секунды - главный поток не выбирает
//  сообщения: какой-то обработчик не возвращается или ждёт системный вызов.
//  Тогда главный поток на мгновение приостанавливается, с него снимаются
//  адрес текущей команды (EIP) и копия стека, и поток сразу продолжает.
//  По копии восстанавливается цепочка вызовов (по EBP) и собираются адреса
//  кода, лежащие в стеке. Адреса переводятся в имена процедур и номера
//  строк по .map рядом с exe (Project -> Options -> Linker -> Map file:
//  Detailed, у dcc32 - ключ -GD) и пишутся в журнал.
//
//  Снимков за одно зависание - три: сразу, через 10 и через 30 секунд.
//  Один и тот же адрес во всех - поток стоит на месте (ждёт или крутится в
//  коротком цикле); разные - идёт долгая работа. Когда поток снова
//  отвечает, в журнал пишется, сколько он не отвечал.
//
//  Модальный диалог зависанием не считается: он сам выбирает сообщения.
//
//  Одного WM_NULL мало. Поток, который ждёт ответа на свой SendMessage к
//  чужому окну (или ждёт в MsgWaitForMultipleObjects), присланные ему
//  сообщения обрабатывает - и на WM_NULL отвечает, - а ввод и перерисовку
//  нет, и Windows пишет в заголовке «Не отвечает». Поэтому второй признак -
//  IsHungAppWindow: так решает сама Windows (поток 5 секунд не забирал
//  сообщения из очереди).
//
//  В каждом снимке - сколько процессорного времени главный поток занял с
//  прошлого снимка. Почти всё время - он крутится в цикле; почти ноль -
//  ждёт (ответа окна, файла, другого процесса).
//
//  Пока главный поток приостановлен, сторож не трогает кучу Delphi (ни
//  строк, ни динамических массивов): поток мог остановиться, держа её
//  блокировку, и тогда сторож повис бы сам. Всё на это время - в массивах
//  фиксированного размера на стеке сторожа и системных вызовах.
//
//  Сбой - crash.log рядом с exe. Исключение, которое не перехватил никто
//  (ни VCL, ни try), Windows перед окном «Прекращена работа программы»
//  отдаёт обработчику SetUnhandledExceptionFilter. Обработчик работает в
//  упавшем потоке, у которого стека может почти не остаться (переполнение
//  стека), поэтому сам он только копирует запись исключения и регистры в
//  глобальные переменные, будит сторожа и ждёт. Сторож со своим стеком
//  пишет в журнал код исключения, адрес (процедура, модуль, строка по
//  .map), для обращения к памяти - какой адрес и чтение или запись, для
//  исключения Delphi - класс и сообщение, и цепочку вызовов упавшего
//  потока - как при зависании. Потом обработчик возвращает управление
//  Windows. Под отладчиком Windows обработчик не вызывает.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes;

// AWnd - окно, которое обслуживает главный поток (Application.Handle).
// ALogFile - журнал; пишется только при зависании. AUiWnd - главное окно
// программы: по нему спрашивается IsHungAppWindow (0 - по AWnd).
// Сбои - в crash.log рядом с ALogFile.
procedure HangWatchStart(AWnd: HWND; const ALogFile: string;
                         AUiWnd: HWND = 0);
procedure HangWatchStop;

implementation

// В Windows.pas Delphi 7 её нет; в user32 - с Windows 2000
function IsHungAppWindow(Wnd: HWND): BOOL; stdcall; external user32;

const
  // В Windows.pas Delphi 7 прав доступа к потоку нет - значения из WinNT.h
  THREAD_SUSPEND_RESUME = $0002;
  THREAD_GET_CONTEXT = $0008;
  THREAD_QUERY_INFORMATION = $0040;

  PingEvery = 1000;        // мс между проверками
  PingWait = 3000;         // мс без ответа - зависание
  StackBytes = 65536;      // сколько стека копировать от ESP
  MaxFrames = 64;
  MaxCodeAddrs = 40;

type
  TStackCopy = array[0..StackBytes div 4 - 1] of Cardinal;

  THangWatch = class(TThread)
  private
    FWnd: HWND;
    FUiWnd: HWND;          // окно для IsHungAppWindow
    FMain: THandle;        // главный поток, с правом приостановки
    FLastCpu: Int64;       // процессорное время потока при прошлом снимке, мс
    FLastTick: Cardinal;
    FWhy: string;          // по какому признаку зависание
    FStop: THandle;        // событие: пора выходить
    FLogFile: string;
    FCrashFile: string;    // crash.log
    FMapFile: string;
    FCodeBase, FCodeEnd: Cardinal;   // сегмент кода exe в памяти
    // Карта: публичные имена и номера строк, смещения от начала сегмента
    FMapTried: Boolean;
    FMapOk: Boolean;
    FPubOfs: array of Cardinal;
    FPubCount: Integer;
    FPubName: TStringList;
    FLineOfs: array of Cardinal;
    FLineNo: array of Integer;
    FLineUnit: array of Integer;     // номер в FUnits
    FLineCount: Integer;
    FUnits: TStringList;
    procedure FindCode;
    procedure LoadMap;
    function InCode(A: Cardinal): Boolean;
    function Describe(A: Cardinal): string;
    procedure Sample(ANum: Integer; AHungMs: Cardinal);
    procedure DescribeStack(AEip, AEsp, AEbp: Cardinal;
                            const AStack: TStackCopy; AGot: Cardinal;
                            ALines: TStrings);
    procedure CrashReport;
    procedure WriteLog(const S: string);
    procedure WriteCrash(ALines: TStrings);
    function ThreadCpuMs: Int64;
  protected
    procedure Execute; override;
  public
    constructor Create(AWnd: HWND; const ALogFile: string; AUiWnd: HWND);
    destructor Destroy; override;
  end;

var
  Watch: THangWatch = nil;

  // Сбой: что скопировал обработчик (HangCrashFilter) - без кучи, его
  // стека может не хватить
  CrashRec: TExceptionRecord;
  CrashCtx: TContext;
  CrashThread: DWORD;
  CrashEvent: THandle = 0;   // обработчик - сторожу: сбой, разбери
  CrashDone: THandle = 0;    // сторож - обработчику: записано
  CrashOnce: Integer = 0;    // второй сбой (в разборе первого) не ждёт
  OldCrashFilter: TFNTopLevelExceptionFilter = nil;

const
  // Исключение Delphi (raise): ExceptionInformation[1] - объект исключения
  DelphiExceptCode = $0EEDFADE;

// ---------------------------------------------------------------------------

constructor THangWatch.Create(AWnd: HWND; const ALogFile: string;
                              AUiWnd: HWND);
begin
  inherited Create(True);
  FWnd := AWnd;
  FUiWnd := AUiWnd;
  if FUiWnd = 0 then
    FUiWnd := AWnd;
  FLogFile := ALogFile;
  FCrashFile := ExtractFilePath(ALogFile) + 'crash.log';
  FMapFile := ChangeFileExt(ParamStr(0), '.map');
  FStop := CreateEvent(nil, True, False, nil);
  // Настоящий дескриптор главного потока: GetCurrentThread даёт
  // псевдодескриптор, годный только внутри самого потока. Создаётся сторож
  // из главного потока.
  DuplicateHandle(GetCurrentProcess, GetCurrentThread, GetCurrentProcess,
                  @FMain, THREAD_SUSPEND_RESUME or THREAD_GET_CONTEXT or
                  THREAD_QUERY_INFORMATION, False, 0);
  FPubName := TStringList.Create;
  FUnits := TStringList.Create;
  FindCode;
end;

destructor THangWatch.Destroy;
begin
  if FMain <> 0 then
    CloseHandle(FMain);
  if FStop <> 0 then
    CloseHandle(FStop);
  FUnits.Free;
  FPubName.Free;
  inherited;
end;

// Сегмент кода exe: первая секция с кодом по заголовку PE. В .map он -
// сегмент 0001, смещения в карте отсчитываются от его начала.
procedure THangWatch.FindCode;
var
  Base: Cardinal;
  Dos: PImageDosHeader;
  Nt: PImageNtHeaders;
  Sec: PImageSectionHeader;
  I: Integer;
begin
  FCodeBase := 0;
  FCodeEnd := 0;
  Base := GetModuleHandle(nil);
  Dos := PImageDosHeader(Base);
  if Dos^.e_magic <> IMAGE_DOS_SIGNATURE then
    Exit;
  Nt := PImageNtHeaders(Base + Cardinal(Dos^._lfanew));
  if Nt^.Signature <> IMAGE_NT_SIGNATURE then
    Exit;
  Sec := PImageSectionHeader(Cardinal(@Nt^.OptionalHeader) +
                             Nt^.FileHeader.SizeOfOptionalHeader);
  for I := 0 to Nt^.FileHeader.NumberOfSections - 1 do
  begin
    if (Sec^.Characteristics and IMAGE_SCN_CNT_CODE) <> 0 then
    begin
      FCodeBase := Base + Sec^.VirtualAddress;
      FCodeEnd := FCodeBase + Sec^.Misc.VirtualSize;
      Exit;
    end;
    Inc(Sec);
  end;
end;

function THangWatch.InCode(A: Cardinal): Boolean;
begin
  Result := (A >= FCodeBase) and (A < FCodeEnd);
end;

// Шестнадцатеричное смещение "0001:0000ABCD" -> $ABCD; не сегмент кода -
// False
function MapOfs(const S: string; var AOfs: Cardinal): Boolean;
var
  V: Integer;
begin
  Result := False;
  if (Length(S) < 13) or (Copy(S, 1, 5) <> '0001:') then
    Exit;
  V := StrToIntDef('$' + Copy(S, 6, 8), -1);
  if V < 0 then
    Exit;
  AOfs := Cardinal(V);
  Result := True;
end;

// Карта Delphi (Map file: Detailed). Нужны два раздела:
//   Address  Publics by Value
//    0001:0001A2B4       Unit1.TForm1.FormCreate
//   Line numbers for Unit1(Unit1.pas) segment CODE
//     13302 0001:0001A2B4  13303 0001:0001A2C0 ...
// Номера строк есть только у модулей, собранных с отладочной информацией.
procedure THangWatch.LoadMap;
var
  SL, W: TStringList;
  I, K, N, U, LineNo: Integer;
  S, T: string;
  InPub: Boolean;
  Ofs: Cardinal;
begin
  FMapTried := True;
  FMapOk := False;
  if not FileExists(FMapFile) then
    Exit;
  SL := TStringList.Create;
  W := TStringList.Create;
  try
    try
      SL.LoadFromFile(FMapFile);
    except
      Exit;
    end;
    InPub := False;
    U := -1;
    for I := 0 to SL.Count - 1 do
    begin
      S := SL[I];
      T := Trim(S);
      if T = '' then
        Continue;
      if Pos('Publics by Value', T) > 0 then
      begin
        InPub := True;
        U := -1;
        Continue;
      end;
      if Copy(T, 1, 17) = 'Line numbers for ' then
      begin
        InPub := False;
        // "Line numbers for Unit1(Unit1.pas) segment CODE" -> Unit1.pas
        K := Pos('(', T);
        N := Pos(')', T);
        if (K > 0) and (N > K) then
          U := FUnits.Add(Copy(T, K + 1, N - K - 1))
        else
          U := FUnits.Add(Copy(T, 18, MaxInt));
        Continue;
      end;
      if (Copy(T, 1, 13) = 'Bound resourc') or (Copy(T, 1, 7) = 'Program') then
      begin
        InPub := False;
        U := -1;
        Continue;
      end;

      if InPub then
      begin
        // " 0001:0001A2B4       Unit1.TForm1.FormCreate"
        if MapOfs(Copy(T, 1, 13), Ofs) then
        begin
          // Массивы растут кусками: записей десятки тысяч
          if FPubCount = Length(FPubOfs) then
            SetLength(FPubOfs, FPubCount + 4096);
          FPubOfs[FPubCount] := Ofs;
          Inc(FPubCount);
          FPubName.Add(Trim(Copy(T, 14, MaxInt)));
        end;
      end
      else if U >= 0 then
      begin
        // Пары "номер строки" и "0001:смещение"
        W.Clear;
        ExtractStrings([' ', #9], [], PChar(T), W);
        K := 0;
        while K + 1 < W.Count do
        begin
          LineNo := StrToIntDef(W[K], -1);
          if (LineNo > 0) and MapOfs(W[K + 1], Ofs) then
          begin
            if FLineCount = Length(FLineOfs) then
            begin
              SetLength(FLineOfs, FLineCount + 16384);
              SetLength(FLineNo, FLineCount + 16384);
              SetLength(FLineUnit, FLineCount + 16384);
            end;
            FLineOfs[FLineCount] := Ofs;
            FLineNo[FLineCount] := LineNo;
            FLineUnit[FLineCount] := U;
            Inc(FLineCount);
            Inc(K, 2);
          end
          else
            Inc(K);
        end;
      end;
    end;
    FMapOk := FPubCount > 0;
  finally
    W.Free;
    SL.Free;
  end;
end;

// Адрес словами: процедура+смещение (модуль, строка) или системный модуль
function THangWatch.Describe(A: Cardinal): string;
var
  Ofs, Best: Cardinal;
  I, BI: Integer;
  MBI: TMemoryBasicInformation;
  Buf: array[0..MAX_PATH] of Char;
begin
  if not InCode(A) then
  begin
    Result := '';
    if VirtualQuery(Pointer(A), MBI, SizeOf(MBI)) = SizeOf(MBI) then
      if GetModuleFileName(HMODULE(MBI.AllocationBase), Buf,
                           SizeOf(Buf)) > 0 then
        Result := ExtractFileName(Buf);
    if Result = '' then
      Result := '(не код exe)';
    Exit;
  end;

  if not FMapTried then
    LoadMap;
  if not FMapOk then
  begin
    Result := '(нет карты)';
    Exit;
  end;
  Ofs := A - FCodeBase;

  // Процедура: ближайшее публичное имя не выше адреса
  BI := -1;
  Best := 0;
  for I := 0 to FPubCount - 1 do
    if (FPubOfs[I] <= Ofs) and ((BI < 0) or (FPubOfs[I] >= Best)) then
    begin
      Best := FPubOfs[I];
      BI := I;
    end;
  if BI >= 0 then
    Result := FPubName[BI] + '+$' + IntToHex(Ofs - Best, 1)
  else
    Result := '?';

  // Строка: ближайшая запись номеров строк не выше адреса
  BI := -1;
  Best := 0;
  for I := 0 to FLineCount - 1 do
    if (FLineOfs[I] <= Ofs) and ((BI < 0) or (FLineOfs[I] >= Best)) then
    begin
      Best := FLineOfs[I];
      BI := I;
    end;
  if BI >= 0 then
    Result := Result + '  (' + FUnits[FLineUnit[BI]] + ', строка ' +
              IntToStr(FLineNo[BI]) + ')';
end;

// Процессорное время главного потока (ядро + пользователь), мс; -1 - нет
function THangWatch.ThreadCpuMs: Int64;
var
  C, E, K, U: TFileTime;
begin
  Result := -1;
  if (FMain <> 0) and GetThreadTimes(FMain, C, E, K, U) then
    Result := (Int64(K) + Int64(U)) div 10000;
end;

procedure THangWatch.WriteLog(const S: string);
var
  F: TextFile;
begin
  try
    AssignFile(F, FLogFile);
    if FileExists(FLogFile) then
      Append(F)
    else
      Rewrite(F);
    try
      Writeln(F, S);
    finally
      CloseFile(F);
    end;
  except
    // журнал не записался - ничего не поделать
  end;
end;

// Снимок главного потока. Между SuspendThread и ResumeThread - только
// системные вызовы и память на стеке сторожа (см. заголовок модуля).
procedure THangWatch.Sample(ANum: Integer; AHungMs: Cardinal);
var
  Ctx: TContext;
  Stack: TStackCopy;
  Got, Size, Esp, Ebp, Eip: Cardinal;
  MBI: TMemoryBasicInformation;
  I: Integer;
  Ok: Boolean;
  SL: TStringList;
  Cpu: Int64;

  // Доля процессора за промежуток: крутится или ждёт
  function CpuVerdict(ACpu: Int64; AMs: Cardinal): string;
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
  if FMain = 0 then
    Exit;
  Got := 0;
  Ok := False;
  Esp := 0;
  Ebp := 0;
  Eip := 0;

  if SuspendThread(FMain) = DWORD(-1) then
    Exit;
  try
    FillChar(Ctx, SizeOf(Ctx), 0);
    Ctx.ContextFlags := CONTEXT_CONTROL or CONTEXT_INTEGER;
    if GetThreadContext(FMain, Ctx) then
    begin
      Ok := True;
      Esp := Ctx.Esp;
      Ebp := Ctx.Ebp;
      Eip := Ctx.Eip;
      // Копия стека от ESP до конца его области памяти, не больше StackBytes
      if VirtualQuery(Pointer(Esp), MBI, SizeOf(MBI)) = SizeOf(MBI) then
      begin
        Size := Cardinal(MBI.BaseAddress) + MBI.RegionSize - Esp;
        if Size > StackBytes then
          Size := StackBytes;
        if not ReadProcessMemory(GetCurrentProcess, Pointer(Esp), @Stack,
                                 Size, Got) then
          Got := 0;
      end;
    end;
  finally
    ResumeThread(FMain);
  end;
  if not Ok then
    Exit;

  // Дальше - уже можно и строки, и кучу: поток продолжил работу
  SL := TStringList.Create;
  try
    SL.Add(Format('==== %s  главный поток не отвечает %.1f с  (снимок %d)',
                  [FormatDateTime('dd.mm.yyyy hh:nn:ss', Now),
                   AHungMs / 1000, ANum]));
    SL.Add('Признак: ' + FWhy);
    Cpu := ThreadCpuMs;
    if (ANum > 1) and (Cpu >= 0) and (FLastCpu >= 0) then
      SL.Add(Format('Процессор: за %.1f с с прошлого снимка поток занял ' +
                    '%d мс - %s',
                    [(GetTickCount - FLastTick) / 1000, Cpu - FLastCpu,
                     CpuVerdict(Cpu - FLastCpu, GetTickCount - FLastTick)]));
    FLastCpu := Cpu;
    FLastTick := GetTickCount;
    if not FileExists(FMapFile) then
      SL.Add('Карты ' + FMapFile + ' нет - адреса без имён. Нужна сборка ' +
             'с картой: Project -> Options -> Linker -> Map file: Detailed ' +
             '(у dcc32 ключ -GD).');
    DescribeStack(Eip, Esp, Ebp, Stack, Got, SL);
    SL.Add('');
    for I := 0 to SL.Count - 1 do
      WriteLog(SL[I]);
  finally
    SL.Free;
  end;
end;

// EIP, цепочка вызовов по EBP и адреса кода в копии стека AStack (AGot
// байт от AEsp) - строками в ALines
procedure THangWatch.DescribeStack(AEip, AEsp, AEbp: Cardinal;
                                   const AStack: TStackCopy; AGot: Cardinal;
                                   ALines: TStrings);
var
  Frames: array[0..MaxFrames - 1] of Cardinal;
  Codes: array[0..MaxCodeAddrs - 1] of Cardinal;
  E, Nxt, V: Cardinal;
  FC, CC, I, J: Integer;
  Dup: Boolean;
begin
  Frames[0] := AEip;
  FC := 1;
  // Цепочка по EBP: [EBP] - EBP вызывающего, [EBP+4] - адрес возврата.
  // Только внутри копии; процедуры без кадра стека в неё не попадают.
  E := AEbp;
  while (FC < MaxFrames) and (E >= AEsp) and (E + 8 <= AEsp + AGot) and
        ((E and 3) = 0) do
  begin
    Nxt := AStack[(E - AEsp) div 4];
    V := AStack[(E - AEsp) div 4 + 1];
    Frames[FC] := V;
    Inc(FC);
    if Nxt <= E then
      Break;
    E := Nxt;
  end;

  // Все адреса кода exe в копии стека, кроме уже найденных цепочкой
  CC := 0;
  for I := 0 to Integer(AGot div 4) - 1 do
  begin
    if CC >= MaxCodeAddrs then
      Break;
    V := AStack[I];
    if not InCode(V) then
      Continue;
    Dup := False;
    for J := 0 to FC - 1 do
      if Frames[J] = V then
        Dup := True;
    for J := 0 to CC - 1 do
      if Codes[J] = V then
        Dup := True;
    if not Dup then
    begin
      Codes[CC] := V;
      Inc(CC);
    end;
  end;

  ALines.Add(Format('EIP  %.8x  %s', [Frames[0], Describe(Frames[0])]));
  if FC > 1 then
  begin
    ALines.Add('Цепочка вызовов (по EBP):');
    for I := 1 to FC - 1 do
      ALines.Add(Format('  %2d  %.8x  %s', [I, Frames[I], Describe(Frames[I])]));
  end;
  if CC > 0 then
  begin
    ALines.Add('Адреса кода в стеке (не только цепочка - бывают и старые):');
    for I := 0 to CC - 1 do
      ALines.Add(Format('      %.8x  %s', [Codes[I], Describe(Codes[I])]));
  end;
end;

// Код исключения словами
function CrashCodeText(ACode: DWORD): string;
begin
  // Сравнения, а не case: коды больше MaxInt
  if ACode = $C0000005 then
    Result := 'обращение к недоступной памяти (access violation)'
  else if ACode = $C00000FD then
    Result := 'переполнение стека (stack overflow) - обычно бесконечная ' +
              'рекурсия: в цепочке повторяются одни и те же строки'
  else if ACode = $C0000094 then
    Result := 'целое деление на ноль'
  else if ACode = $C0000095 then
    Result := 'переполнение целого'
  else if ACode = $C000008E then
    Result := 'деление на ноль с плавающей точкой'
  else if ACode = $C0000090 then
    Result := 'недопустимая операция с плавающей точкой'
  else if ACode = $C0000091 then
    Result := 'переполнение с плавающей точкой'
  else if ACode = $C000001D then
    Result := 'недопустимая команда процессора'
  else if ACode = $C0000096 then
    Result := 'привилегированная команда'
  else if ACode = $C0000409 then
    Result := 'порча буфера в стеке'
  else if ACode = $C0000374 then
    Result := 'порча кучи'
  else if ACode = $C0000025 then
    Result := 'продолжение после неустранимого исключения'
  else if ACode = $80000003 then
    Result := 'точка останова (int 3)'
  else if ACode = DelphiExceptCode then
    Result := 'исключение Delphi (raise), не перехваченное'
  else
    Result := '';
end;

// Разбор сбоя по тому, что скопировал HangCrashFilter, - в crash.log.
// Упавший поток стоит в обработчике и ждёт, его стек выше ESP исключения
// не меняется: копия читается без остановки потока.
procedure THangWatch.CrashReport;
var
  Stack: TStackCopy;
  Got, Size, FaultAddr: Cardinal;
  MBI: TMemoryBasicInformation;
  SL: TStringList;
  ExcObj: TObject;
  AccessKind: string;
begin
  SL := TStringList.Create;
  try
    SL.Add(Format('==== %s  сбой: исключение $%.8x  %s',
                  [FormatDateTime('dd.mm.yyyy hh:nn:ss', Now),
                   CrashRec.ExceptionCode,
                   CrashCodeText(CrashRec.ExceptionCode)]));
    if CrashThread = MainThreadID then
      SL.Add('Поток: главный')
    else
      SL.Add('Поток: ' + IntToStr(CrashThread) + ' (не главный)');
    FaultAddr := Cardinal(CrashRec.ExceptionAddress);
    SL.Add(Format('Адрес: %.8x  %s', [FaultAddr, Describe(FaultAddr)]));
    // Обращение к памяти: что делали и по какому адресу
    if (CrashRec.ExceptionCode = $C0000005) and
       (CrashRec.NumberParameters >= 2) then
    begin
      case CrashRec.ExceptionInformation[0] of
        0: AccessKind := 'чтение';
        1: AccessKind := 'запись';
        8: AccessKind := 'исполнение (DEP)';
      else
        AccessKind := 'доступ';
      end;
      SL.Add(Format('Память: %s по адресу %.8x',
                    [AccessKind, CrashRec.ExceptionInformation[1]]));
    end;
    // Исключение Delphi: класс и сообщение объекта. Объект в куче - если
    // она испорчена, чтение может упасть: тогда без него.
    if (CrashRec.ExceptionCode = DelphiExceptCode) and
       (CrashRec.NumberParameters >= 2) then
    try
      ExcObj := TObject(CrashRec.ExceptionInformation[1]);
      if ExcObj is Exception then
        SL.Add('Исключение: ' + ExcObj.ClassName + ': ' +
               Exception(ExcObj).Message)
      else if ExcObj <> nil then
        SL.Add('Исключение: объект ' + ExcObj.ClassName);
    except
      SL.Add('Исключение: объект не прочитался');
    end;
    if not FileExists(FMapFile) then
      SL.Add('Карты ' + FMapFile + ' нет - адреса без имён. Нужна сборка ' +
             'с картой: Project -> Options -> Linker -> Map file: Detailed ' +
             '(у dcc32 ключ -GD).');

    // Стек упавшего потока от ESP исключения
    Got := 0;
    if VirtualQuery(Pointer(CrashCtx.Esp), MBI, SizeOf(MBI)) = SizeOf(MBI) then
    begin
      Size := Cardinal(MBI.BaseAddress) + MBI.RegionSize - CrashCtx.Esp;
      if Size > StackBytes then
        Size := StackBytes;
      if not ReadProcessMemory(GetCurrentProcess, Pointer(CrashCtx.Esp),
                               @Stack, Size, Got) then
        Got := 0;
    end;
    DescribeStack(CrashCtx.Eip, CrashCtx.Esp, CrashCtx.Ebp, Stack, Got, SL);
    SL.Add('');
    WriteCrash(SL);
  finally
    SL.Free;
  end;
end;

procedure THangWatch.WriteCrash(ALines: TStrings);
var
  F: TextFile;
  LineIdx: Integer;
begin
  try
    AssignFile(F, FCrashFile);
    if FileExists(FCrashFile) then
      Append(F)
    else
      Rewrite(F);
    try
      for LineIdx := 0 to ALines.Count - 1 do
        Writeln(F, ALines[LineIdx]);
    finally
      CloseFile(F);
    end;
  except
    // журнал не записался - ничего не поделать
  end;
end;

procedure THangWatch.Execute;
var
  R, Waited: DWORD;
  HungSince, Now_: Cardinal;
  Samples: Integer;
  Ok: Boolean;
  WaitFor2: array[0..1] of THandle;

  // Обработчик сбоя ждёт разбора - разобрать и отпустить его
  function CrashPending: Boolean;
  begin
    Result := (CrashEvent <> 0) and
              (WaitForSingleObject(CrashEvent, 0) = WAIT_OBJECT_0);
    if Result then
    begin
      try
        CrashReport;
      except
        // разбор не удался - Windows покажет своё окно и так
      end;
      SetEvent(CrashDone);
    end;
  end;

begin
  HungSince := 0;
  Samples := 0;
  WaitFor2[0] := FStop;
  WaitFor2[1] := CrashEvent;
  while not Terminated do
  begin
    if CrashEvent <> 0 then
      Waited := WaitForMultipleObjects(2, @WaitFor2, False, PingEvery)
    else
      Waited := WaitForSingleObject(FStop, PingEvery);
    if Waited = WAIT_OBJECT_0 then
      Break;
    // Сбой - разбор и дальше: процесс всё равно закроется
    if CrashPending then
      Continue;
    if not IsWindow(FWnd) then
      Break;
    R := 0;
    Ok := SendMessageTimeout(FWnd, WM_NULL, 0, 0, SMTO_NORMAL, PingWait,
                             R) <> 0;
    // Главный поток не ответил, потому что упал и ждёт в обработчике
    if CrashPending then
      Continue;
    if not Ok then
      FWhy := 'нет ответа на WM_NULL ' + IntToStr(PingWait div 1000) + ' с'
    else if IsWindow(FUiWnd) and IsHungAppWindow(FUiWnd) then
    begin
      // На присланное отвечает, а очередь не разбирает - «Не отвечает»
      // по мнению Windows
      Ok := False;
      FWhy := 'Windows считает окно зависшим (IsHungAppWindow): присланные ' +
              'сообщения поток обрабатывает, очередь - нет';
    end;
    if Ok then
    begin
      if (HungSince <> 0) and not Terminated then
        WriteLog(Format('%s  главный поток снова отвечает; не отвечал ' +
                        'около %.1f с'#13#10,
                        [FormatDateTime('dd.mm.yyyy hh:nn:ss', Now),
                         (GetTickCount - HungSince) / 1000]));
      HungSince := 0;
      Samples := 0;
      Continue;
    end;
    // Выход программы: окно уже не отвечает, но это не зависание
    if Terminated or (WaitForSingleObject(FStop, 0) = WAIT_OBJECT_0) then
      Break;
    Now_ := GetTickCount;
    // С какого момента: WM_NULL ждали PingWait, а IsHungAppWindow говорит
    // «да» после 5 секунд без разбора очереди
    if HungSince = 0 then
      if Copy(FWhy, 1, 7) = 'Windows' then
        HungSince := Now_ - 5000
      else
        HungSince := Now_ - PingWait;
    if (Samples = 0) or
       ((Samples = 1) and (Now_ - HungSince >= 13000)) or
       ((Samples = 2) and (Now_ - HungSince >= 33000)) then
    begin
      Inc(Samples);
      try
        Sample(Samples, Now_ - HungSince);
      except
        // снимок не удался - следующий через ту же проверку
      end;
    end;
  end;
end;

// ---------------------------------------------------------------------------

// Исключение, которое никто не перехватил. Здесь - только копии в
// глобальные переменные и ожидание: стека у упавшего потока может почти не
// остаться. Разбирает и пишет сторож (CrashReport). Сбой в самом стороже
// или повторный - без разбора.
function HangCrashFilter(ExceptionInfo: PExceptionPointers): Longint; stdcall;
begin
  Result := EXCEPTION_CONTINUE_SEARCH;
  if (Watch <> nil) and (CrashEvent <> 0) and (ExceptionInfo <> nil) and
     (GetCurrentThreadId <> Watch.ThreadID) and
     (InterlockedExchange(CrashOnce, 1) = 0) then
  begin
    if ExceptionInfo^.ExceptionRecord <> nil then
      CrashRec := ExceptionInfo^.ExceptionRecord^;
    if ExceptionInfo^.ContextRecord <> nil then
      CrashCtx := ExceptionInfo^.ContextRecord^;
    CrashThread := GetCurrentThreadId;
    SetEvent(CrashEvent);
    WaitForSingleObject(CrashDone, 20000);
  end;
  if Assigned(OldCrashFilter) then
    Result := OldCrashFilter(ExceptionInfo);
end;

procedure HangWatchStart(AWnd: HWND; const ALogFile: string;
                         AUiWnd: HWND = 0);
begin
  if Watch <> nil then
    Exit;
  // С ручным сбросом: сторож и ждёт его в WaitForMultipleObjects, и
  // проверяет потом - сигнал не должен съедаться
  CrashEvent := CreateEvent(nil, True, False, nil);
  CrashDone := CreateEvent(nil, False, False, nil);
  Watch := THangWatch.Create(AWnd, ALogFile, AUiWnd);
  Watch.Resume;
  OldCrashFilter := SetUnhandledExceptionFilter(@HangCrashFilter);
end;

// Событие и Terminate, потом ожидание. Если сторож в это время сидит в
// SendMessageTimeout к главному окну, ожидание не зависнет: TThread.WaitFor
// в главном потоке обрабатывает присланные ему сообщения, и WM_NULL
// получает ответ. Журнал при выходе не пишется.
procedure HangWatchStop;
begin
  if Watch = nil then
    Exit;
  SetUnhandledExceptionFilter(OldCrashFilter);
  OldCrashFilter := nil;
  SetEvent(Watch.FStop);
  Watch.Terminate;
  Watch.WaitFor;
  FreeAndNil(Watch);
  if CrashEvent <> 0 then
    CloseHandle(CrashEvent);
  if CrashDone <> 0 then
    CloseHandle(CrashDone);
  CrashEvent := 0;
  CrashDone := 0;
end;

end.
