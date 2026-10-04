unit RqDbgInstr;

// ---------------------------------------------------------------------------
//  Отладчик RapidQ: инструментированная копия программы
//
//  Exe RapidQ - интерпретатор с байткодом, адреса строк у него нет, поэтому
//  отлаживается копия главного .bas, в которой перед каждым оператором
//  стоит проверка с номером точки:
//      IF RqDbgBrk(12) THEN RqDbg(12, RqDbgLvl, 345)
//  RqDbgBrk - массив флагов точек. Пока флаг 0, проверка стоит одного
//  сравнения (тест RqDbgT3: x1.7 к программе без вставок). Флаги ставит сама
//  программа по файлу команды от unIDE: при Run - точки останова, при шаге -
//  все, при Run to cursor - точки останова и строка курсора.
//  RqDbg решает, стоять ли (шаг через вызов, та же строка), и останавливает
//  программу: пишет файл состояния ("s номер уровень"), поднимает событие
//  "stop" и ждёт события "go" (WaitForSingleObject - поток стоит целиком,
//  окна программы не перерисовываются, как в Delphi). unIDE по событию
//  показывает строку, по F9/F7/F8/F4 пишет файл команды и поднимает "go".
//
//  Уровень вызова (для Step over): в начале каждой SUB/FUNCTION локальная
//  RqDbgLvl = глубина + 1, перед END SUB и EXIT SUB глубина = RqDbgLvl - 1.
//  EXIT SUB внутри однострочного IF не меняется (вставка туда изменила бы
//  строку): пропущенный выход исправляет следующая точка вызывающей SUB -
//  RqDbg пишет в глубину уровень своей точки.
//
//  Строка копии - строка исходника: каждая вставленная или пересобранная
//  строка помнит строку исходника (SrcLineOfCopy), по ней показываются
//  ошибки компиляции копии.
//
//  Куда проверка не ставится: блоки CREATE ... END CREATE и TYPE ... END
//  TYPE (целиком, как есть), DECLARE, DIM, CONST, DEF..., директивы $,
//  комментарии; ELSE, ELSEIF, CASE, LOOP, NEXT, WEND, END IF/SELECT/WITH,
//  заголовки и концы SUB; между SELECT CASE и первым CASE. Однострочный IF
//  (что-то после THEN) - один оператор вместе со всем, что за ним в строке.
//  Строки с продолжением "_" склеиваются. Строки, где вставлять нечего,
//  переносятся в копию как есть, с комментариями.
//
//  Условная сборка: $IFDEF имя, $IFNDEF, $ELSE, $ENDIF и их псевдонимы
//  через $DEFINE (brem/erem и remb/reme из RAPIDQ.INC известны заранее:
//  "brem 0 ... erem" - блок-комментарий). Имена считаются определёнными,
//  только если их $DEFINE есть в самом файле: $IFDEF неизвестного имени -
//  блок не собирается, переносится как есть, без проверок; $IFNDEF -
//  собирается. Ошибка в эту сторону стоит только точек внутри блока.
//
//  Имена кода отладчика в копии - с префиксом RqDbg. Если в исходнике
//  уже есть слово с таким началом (в любом месте, даже в комментарии),
//  берётся другой префикс (UniDbg, UnideDbg, RqDbgZ3, ...): иначе rc.exe
//  выдаст "identifier already in use". Имена событий и пути файлов от
//  префикса не зависят.
//
//  Этап 1: инструментируется только главный .bas; $INCLUDE-файлы - как
//  есть.
//
//  Без VCL: проверяется FPC (fpc -Mdelphi).
// ---------------------------------------------------------------------------

interface

uses
  Classes, SysUtils;

const
  RqDbgModeRun   = 0;   // до точки останова
  RqDbgModeInto  = 1;   // Trace into: следующая строка
  RqDbgModeOver  = 2;   // Step over: следующая строка этого уровня или выше
  RqDbgModeRunTo = 3;   // Run to cursor: строка курсора или точка останова

type
  TRqDbgInstr = class
  private
    FSrcFile: string;
    FCopyFile: string;
    FCmdFile: string;
    FStateFile: string;
    FEventBase: string;
    FLastError: string;
    FPrefix: string;                // начало имён кода отладчика в копии
    FPointCount: Integer;
    FPointLine: array of Integer;   // номер точки -> строка исходника (с 0)
    FLinePoint: array of Integer;   // строка исходника -> первая точка, 0 - нет
    FCopySrc: array of Integer;     // строка копии -> строка исходника, -1
    FCopyCount: Integer;
    procedure AddCopyLine(AOut: TStrings; const AText: string;
                          ASrcLine: Integer);
    function NewPoint(ASrcLine: Integer): Integer;
    procedure AddRuntime(AOut: TStrings);
    function Pfx(const AText: string): string;
  public
    // Копия ASrcFile в ACopyFile. ACmdFile, AStateFile - файлы команды и
    // состояния (пути целиком), AEventBase - начало имён событий. False -
    // причина в LastError.
    function Build(const ASrcFile, ACopyFile, ACmdFile, AStateFile,
                   AEventBase: string): Boolean;
    // Первая точка строки исходника (с 0), 0 - на строке нет кода
    function PointOfLine(ALine: Integer): Integer;
    // Строка исходника (с 0) точки, -1 - нет такой
    function LineOfPoint(APoint: Integer): Integer;
    // Строка исходника (с 0) по строке копии (с 0), -1 - строка добавлена
    function SrcLineOfCopy(ACopyLine: Integer): Integer;
    property SrcFile: string read FSrcFile;
    property CopyFile: string read FCopyFile;
    property CmdFile: string read FCmdFile;
    property StateFile: string read FStateFile;
    property EventBase: string read FEventBase;
    property PointCount: Integer read FPointCount;
    property LastError: string read FLastError;
    property Prefix: string read FPrefix;
  end;

// Путь для строки в копии: прямые косые (обратная при $ESCAPECHARS ON -
// начало escape)
function RqDbgSlashPath(const APath: string): string;

// Имена событий по началу AEventBase
function RqDbgStopEventName(const AEventBase: string): string;
function RqDbgGoEventName(const AEventBase: string): string;

implementation

const
  CrLf = #13#10;

type
  // Что делать с оператором строки
  TRqPartKind = (pkPoint,      // проверка перед ним
                 pkPlain,      // как есть, без проверки
                 pkLabel,      // метка "Имя:" - отдельной строкой
                 pkSubHead,    // заголовок SUB/FUNCTION - после него уровень
                 pkSubEnd,     // END SUB/FUNCTION - перед ним глубина
                 pkExitSub);   // EXIT SUB/FUNCTION - проверка и глубина

function RqDbgSlashPath(const APath: string): string;
begin
  Result := StringReplace(APath, '\', '/', [rfReplaceAll]);
end;

function RqDbgStopEventName(const AEventBase: string): string;
begin
  Result := AEventBase + '_S';
end;

function RqDbgGoEventName(const AEventBase: string): string;
begin
  Result := AEventBase + '_G';
end;

// Конец строки в кавычках, начатой на AStart (там "). AEscape - при
// $ESCAPECHARS ON \" кавычку не закрывает. Возвращает позицию закрывающей
// кавычки или Length+1.
function SkipQuoted(const AText: string; AStart: Integer;
                    AEscape: Boolean): Integer;
begin
  Result := AStart + 1;
  while Result <= Length(AText) do
  begin
    if AEscape and (AText[Result] = '\') and (Result < Length(AText)) then
      Inc(Result, 2)
    else if AText[Result] = '"' then
      Exit
    else
      Inc(Result);
  end;
end;

// Код строки без комментария ' (вне кавычек)
function StripComment(const AText: string; AEscape: Boolean): string;
var
  CharIdx: Integer;
begin
  CharIdx := 1;
  while CharIdx <= Length(AText) do
  begin
    if AText[CharIdx] = '"' then
      CharIdx := SkipQuoted(AText, CharIdx, AEscape) + 1
    else if AText[CharIdx] = '''' then
    begin
      Result := Copy(AText, 1, CharIdx - 1);
      Exit;
    end
    else
      Inc(CharIdx);
  end;
  Result := AText;
end;

// N-е слово (с 1) заглавными; слово - буквы, цифры, _ и $
function WordAt(const AText: string; AIndex: Integer): string;
var
  CharIdx, WordStart, WordNo: Integer;
begin
  Result := '';
  WordNo := 0;
  CharIdx := 1;
  while CharIdx <= Length(AText) do
  begin
    while (CharIdx <= Length(AText)) and
          not (AText[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) do
    begin
      if AText[CharIdx] = '"' then
        Exit;   // до строки слов не набралось
      Inc(CharIdx);
    end;
    if CharIdx > Length(AText) then
      Exit;
    WordStart := CharIdx;
    while (CharIdx <= Length(AText)) and
          (AText[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) do
      Inc(CharIdx);
    Inc(WordNo);
    if WordNo = AIndex then
    begin
      Result := UpperCase(Copy(AText, WordStart, CharIdx - WordStart));
      Exit;
    end;
  end;
end;

// Позиция слова AWord (заглавными) вне кавычек, 0 - нет
function FindWord(const AText, AWord: string; AEscape: Boolean): Integer;
var
  CharIdx, WordStart: Integer;
begin
  Result := 0;
  CharIdx := 1;
  while CharIdx <= Length(AText) do
  begin
    if AText[CharIdx] = '"' then
    begin
      CharIdx := SkipQuoted(AText, CharIdx, AEscape) + 1;
      Continue;
    end;
    if AText[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '$'] then
    begin
      WordStart := CharIdx;
      while (CharIdx <= Length(AText)) and
            (AText[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) do
        Inc(CharIdx);
      if UpperCase(Copy(AText, WordStart, CharIdx - WordStart)) = AWord then
      begin
        Result := WordStart;
        Exit;
      end;
      Continue;
    end;
    Inc(CharIdx);
  end;
end;

// Однострочный IF: после THEN есть текст
function IsSingleLineIf(const AStmt: string; AEscape: Boolean): Boolean;
var
  ThenPos: Integer;
begin
  Result := False;
  if WordAt(AStmt, 1) <> 'IF' then
    Exit;
  ThenPos := FindWord(AStmt, 'THEN', AEscape);
  if ThenPos = 0 then
    Exit;
  Result := Trim(Copy(AStmt, ThenPos + 4, MaxInt)) <> '';
end;

// Операторы логической строки (уже без комментариев и "_"): по ":" вне
// кавычек. Однострочный IF забирает всё до конца строки, REM - тоже (и
// выбрасывается). AColonAfterFirst - за первым оператором стояло ":".
procedure SplitStatements(const ACode: string; AEscape: Boolean;
                          AParts: TStrings; var AColonAfterFirst: Boolean);
var
  Raw: TStringList;
  CharIdx, StartPos, RawIdx, JoinIdx: Integer;
  Stmt, Joined: string;
begin
  AParts.Clear;
  AColonAfterFirst := False;
  Raw := TStringList.Create;
  try
    StartPos := 1;
    CharIdx := 1;
    while CharIdx <= Length(ACode) do
    begin
      if ACode[CharIdx] = '"' then
      begin
        CharIdx := SkipQuoted(ACode, CharIdx, AEscape) + 1;
        Continue;
      end;
      if ACode[CharIdx] = ':' then
      begin
        Raw.Add(Copy(ACode, StartPos, CharIdx - StartPos));
        if Raw.Count = 1 then
          AColonAfterFirst := True;
        StartPos := CharIdx + 1;
      end;
      Inc(CharIdx);
    end;
    Raw.Add(Copy(ACode, StartPos, MaxInt));

    RawIdx := 0;
    while RawIdx < Raw.Count do
    begin
      Stmt := Trim(Raw[RawIdx]);
      if WordAt(Stmt, 1) = 'REM' then
        Break;
      // IF ... THEN что-то[: ещё] - один оператор до конца строки.
      // IF ... THEN и дальше ":" - тоже (THEN без текста, но строка не
      // кончилась).
      if (WordAt(Stmt, 1) = 'IF') and (FindWord(Stmt, 'THEN', AEscape) > 0) and
         (IsSingleLineIf(Stmt, AEscape) or (RawIdx < Raw.Count - 1)) then
      begin
        Joined := Raw[RawIdx];
        for JoinIdx := RawIdx + 1 to Raw.Count - 1 do
          Joined := Joined + ':' + Raw[JoinIdx];
        AParts.Add(Trim(Joined));
        Break;
      end;
      if Stmt <> '' then
        AParts.Add(Stmt)
      else if RawIdx = 0 then
        AParts.Add('');   // место первого оператора - для метки
      Inc(RawIdx);
    end;
  finally
    Raw.Free;
  end;
end;

// Одно слово без пробелов, скобок и точек - кандидат в метку "Имя:"
function IsLabelWord(const AStmt: string): Boolean;
const
  StmtWords: array[0..15] of string = ('ELSE', 'CLS', 'PRINT', 'RETURN',
    'LOOP', 'NEXT', 'WEND', 'END', 'DOEVENTS', 'BEEP', 'RANDOMIZE', 'STOP',
    'DO', 'REM', 'ENDIF', 'RESUME');
var
  CharIdx, WordIdx: Integer;
begin
  Result := False;
  if (AStmt = '') or not (AStmt[1] in ['A'..'Z', 'a'..'z', '_']) then
    Exit;
  for CharIdx := 1 to Length(AStmt) do
    if not (AStmt[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      Exit;
  for WordIdx := Low(StmtWords) to High(StmtWords) do
    if UpperCase(AStmt) = StmtWords[WordIdx] then
      Exit;
  Result := True;
end;

// Номер-метка в начале оператора ("100 PRINT x"): ALabel - номер, AStmt -
// остаток
procedure TakeNumericLabel(var AStmt: string; var ALabel: string);
var
  CharIdx: Integer;
begin
  ALabel := '';
  if (AStmt = '') or not (AStmt[1] in ['0'..'9']) then
    Exit;
  CharIdx := 1;
  while (CharIdx <= Length(AStmt)) and (AStmt[CharIdx] in ['0'..'9', '.']) do
    Inc(CharIdx);
  if (CharIdx <= Length(AStmt)) and (AStmt[CharIdx] > ' ') then
    Exit;   // не номер, а число в выражении
  ALabel := Copy(AStmt, 1, CharIdx - 1);
  AStmt := Trim(Copy(AStmt, CharIdx, MaxInt));
end;

// Первое слово строки как есть (до пробела), заглавными; ARest - остаток
function FirstToken(const ACode: string; var ARest: string): string;
var
  Trimmed: string;
  CharIdx: Integer;
begin
  Trimmed := Trim(ACode);
  CharIdx := 1;
  while (CharIdx <= Length(Trimmed)) and not (Trimmed[CharIdx] in [' ', #9]) do
    Inc(CharIdx);
  Result := UpperCase(Copy(Trimmed, 1, CharIdx - 1));
  ARest := Trim(Copy(Trimmed, CharIdx, MaxInt));
end;

function IsSubWord(const AWord: string): Boolean;
begin
  Result := (AWord = 'SUB') or (AWord = 'FUNCTION') or (AWord = 'SUBI') or
            (AWord = 'FUNCTIONI');
end;

// Блоки, которые переносятся целиком: TYPE ... END TYPE и подобные
function IsSkipBlockWord(const AWord: string): Boolean;
begin
  Result := (AWord = 'TYPE') or (AWord = 'STRUCT') or (AWord = 'UNION') or
            (AWord = 'ENUM');
end;

// Объявления DEFINT, DEFSTR и подобные
function IsDefWord(const AWord: string): Boolean;
const
  DefWords: array[0..10] of string = ('DEFINT', 'DEFSTR', 'DEFSNG', 'DEFDBL',
    'DEFLNG', 'DEFBYTE', 'DEFWORD', 'DEFDWORD', 'DEFSHORT', 'DEFVARIANT',
    'DEFCUR');
var
  WordIdx: Integer;
begin
  Result := True;
  for WordIdx := Low(DefWords) to High(DefWords) do
    if AWord = DefWords[WordIdx] then
      Exit;
  Result := False;
end;

// Вид оператора
function PartKind(const AStmt: string): TRqPartKind;
var
  First, Second: string;
begin
  First := WordAt(AStmt, 1);
  Second := WordAt(AStmt, 2);
  Result := pkPoint;
  if (AStmt = '') or (AStmt[1] in ['$', '#']) then
    Result := pkPlain
  else if (First = 'DECLARE') or (First = 'DIM') or (First = 'CONST') or
          (First = 'REM') or IsDefWord(First) then
    Result := pkPlain
  else if (First = 'ELSE') or (First = 'ELSEIF') or (First = 'CASE') or
          (First = 'LOOP') or (First = 'NEXT') or (First = 'WEND') or
          (First = 'WITH') or (First = 'ENDIF') then
    Result := pkPlain
  else if IsSubWord(First) then
    Result := pkSubHead
  else if First = 'END' then
  begin
    if IsSubWord(Second) then
      Result := pkSubEnd
    else if (Second = 'IF') or (Second = 'SELECT') or (Second = 'WITH') or
            (Second = 'CREATE') or IsSkipBlockWord(Second) then
      Result := pkPlain;
    // END без второго слова - конец программы, оператор
  end
  else if (First = 'EXIT') and IsSubWord(Second) then
    Result := pkExitSub;
end;

{ TRqDbgInstr }

procedure TRqDbgInstr.AddCopyLine(AOut: TStrings; const AText: string;
                                  ASrcLine: Integer);
begin
  AOut.Add(AText);
  if FCopyCount >= Length(FCopySrc) then
    SetLength(FCopySrc, FCopyCount * 2 + 256);
  FCopySrc[FCopyCount] := ASrcLine;
  Inc(FCopyCount);
end;

function TRqDbgInstr.NewPoint(ASrcLine: Integer): Integer;
begin
  Inc(FPointCount);
  if FPointCount >= Length(FPointLine) then
    SetLength(FPointLine, FPointCount * 2 + 256);
  FPointLine[FPointCount] := ASrcLine;
  if (ASrcLine >= 0) and (ASrcLine < Length(FLinePoint)) and
     (FLinePoint[ASrcLine] = 0) then
    FLinePoint[ASrcLine] := FPointCount;
  Result := FPointCount;
end;

// Имена кода отладчика: RqDbg в шаблоне - выбранный префикс
function TRqDbgInstr.Pfx(const AText: string): string;
begin
  Result := StringReplace(AText, 'RqDbg', FPrefix, [rfReplaceAll]);
end;

// Код отладки в копии. Имена - с RqDbg (как RqProbe у снимка), функции
// Windows - под своими именами через ALIAS: с DECLARE из RAPIDQ.INC не
// столкнутся.
procedure TRqDbgInstr.AddRuntime(AOut: TStrings);
var
  MaxIdx, CmdPath, StatePath: string;

  procedure Add(const AText: string);
  begin
    AddCopyLine(AOut, Pfx(AText), -1);
  end;

  // Строка с путём или именем события: префикс - только в коде вокруг
  procedure AddLit(const ABefore, ALiteral, AAfter: string);
  begin
    AddCopyLine(AOut, Pfx(ABefore) + ALiteral + Pfx(AAfter), -1);
  end;

begin
  MaxIdx := IntToStr(FPointCount);
  CmdPath := RqDbgSlashPath(FCmdFile);
  StatePath := RqDbgSlashPath(FStateFile);
  Add(''' --- unIDE: отладчик (копия программы, ' +
      IntToStr(FPointCount) + ' точек) ---');
  Add('DECLARE FUNCTION RqDbgCreateEvent LIB "kernel32" ALIAS "CreateEventA" ' +
      '(BYVAL RqDbgAttr AS LONG, BYVAL RqDbgManual AS LONG, ' +
      'BYVAL RqDbgInitial AS LONG, RqDbgName AS STRING) AS LONG');
  Add('DECLARE FUNCTION RqDbgSetEvent LIB "kernel32" ALIAS "SetEvent" ' +
      '(BYVAL RqDbgHandle AS LONG) AS LONG');
  Add('DECLARE FUNCTION RqDbgResetEvent LIB "kernel32" ALIAS "ResetEvent" ' +
      '(BYVAL RqDbgHandle AS LONG) AS LONG');
  Add('DECLARE FUNCTION RqDbgWait LIB "kernel32" ALIAS ' +
      '"WaitForSingleObject" (BYVAL RqDbgHandle AS LONG, ' +
      'BYVAL RqDbgMs AS LONG) AS LONG');
  Add('DIM RqDbgBrk(' + MaxIdx + ') AS INTEGER');
  Add('DIM RqDbgUser(' + MaxIdx + ') AS INTEGER');
  Add('DIM RqDbgMode AS LONG');
  Add('DIM RqDbgRunTo AS LONG');
  Add('DIM RqDbgDepth AS LONG');
  Add('DIM RqDbgStopId AS LONG');
  Add('DIM RqDbgStopLvl AS LONG');
  Add('DIM RqDbgStopKey AS LONG');
  Add('DIM RqDbgEvStop AS LONG');
  Add('DIM RqDbgEvGo AS LONG');
  Add('DECLARE SUB RqDbgReadCmd');
  Add('DECLARE SUB RqDbgStop (RqDbgPId AS LONG, RqDbgPLvl AS LONG, ' +
      'RqDbgPKey AS LONG)');
  Add('DECLARE SUB RqDbg (RqDbgPId AS LONG, RqDbgPLvl AS LONG, ' +
      'RqDbgPKey AS LONG)');
  Add('');
  // Команда: "m режим", "r точка Run to cursor", "b точка" на каждую точку
  // останова, "#end". Файла нет - Run без точек.
  Add('SUB RqDbgReadCmd');
  Add('  DIM RqDbgCmdFile AS QFILESTREAM');
  Add('  DIM RqDbgCmdLine AS STRING');
  Add('  DIM RqDbgCmdIdx AS LONG');
  Add('  DIM RqDbgCmdGuard AS LONG');
  Add('  RqDbgMode = 0');
  Add('  RqDbgRunTo = 0');
  Add('  FOR RqDbgCmdIdx = 0 TO ' + MaxIdx);
  Add('    RqDbgUser(RqDbgCmdIdx) = 0');
  Add('  NEXT');
  AddLit('  IF FILEEXISTS("', CmdPath, '") THEN');
  AddLit('    RqDbgCmdFile.Open("', CmdPath, '", 0)');
  Add('    RqDbgCmdGuard = 0');
  Add('    DO');
  Add('      IF RqDbgCmdFile.EOF THEN EXIT DO');
  Add('      RqDbgCmdLine = RqDbgCmdFile.ReadLine');
  Add('      IF LEFT$(RqDbgCmdLine, 4) = "#end" THEN EXIT DO');
  Add('      IF LEFT$(RqDbgCmdLine, 2) = "m " THEN RqDbgMode = ' +
      'VAL(MID$(RqDbgCmdLine, 3, 20))');
  Add('      IF LEFT$(RqDbgCmdLine, 2) = "r " THEN RqDbgRunTo = ' +
      'VAL(MID$(RqDbgCmdLine, 3, 20))');
  Add('      IF LEFT$(RqDbgCmdLine, 2) = "b " THEN');
  Add('        RqDbgCmdIdx = VAL(MID$(RqDbgCmdLine, 3, 20))');
  Add('        IF RqDbgCmdIdx > 0 THEN');
  Add('          IF RqDbgCmdIdx <= ' + MaxIdx +
      ' THEN RqDbgUser(RqDbgCmdIdx) = 1');
  Add('        END IF');
  Add('      END IF');
  Add('      RqDbgCmdGuard = RqDbgCmdGuard + 1');
  Add('      IF RqDbgCmdGuard > 1000000 THEN EXIT DO');
  Add('    LOOP');
  Add('    RqDbgCmdFile.Close');
  Add('  END IF');
  Add('  FOR RqDbgCmdIdx = 0 TO ' + MaxIdx);
  Add('    IF RqDbgMode = 1 THEN');
  Add('      RqDbgBrk(RqDbgCmdIdx) = 1');
  Add('    ELSEIF RqDbgMode = 2 THEN');
  Add('      RqDbgBrk(RqDbgCmdIdx) = 1');
  Add('    ELSE');
  Add('      RqDbgBrk(RqDbgCmdIdx) = RqDbgUser(RqDbgCmdIdx)');
  Add('    END IF');
  Add('  NEXT');
  Add('  IF RqDbgMode = 3 THEN');
  Add('    IF RqDbgRunTo > 0 THEN');
  Add('      IF RqDbgRunTo <= ' + MaxIdx + ' THEN RqDbgBrk(RqDbgRunTo) = 1');
  Add('    END IF');
  Add('  END IF');
  Add('END SUB');
  Add('');
  // Остановка: состояние в файл, "stop", ждать "go" (без DOEVENTS - окна
  // программы стоят), затем новая команда
  Add('SUB RqDbgStop (RqDbgPId AS LONG, RqDbgPLvl AS LONG, ' +
      'RqDbgPKey AS LONG)');
  Add('  DIM RqDbgStateFile AS QFILESTREAM');
  Add('  DIM RqDbgCallRes AS LONG');
  AddLit('  RqDbgStateFile.Open("', StatePath, '", 65535)');
  Add('  RqDbgStateFile.WriteLine("s " + STR$(RqDbgPId) + " " + ' +
      'STR$(RqDbgPLvl))');
  Add('  RqDbgStateFile.WriteLine("#end")');
  Add('  RqDbgStateFile.Close');
  Add('  RqDbgCallRes = RqDbgResetEvent(RqDbgEvGo)');
  Add('  RqDbgCallRes = RqDbgSetEvent(RqDbgEvStop)');
  Add('  RqDbgCallRes = RqDbgWait(RqDbgEvGo, -1)');
  Add('  RqDbgStopId = RqDbgPId');
  Add('  RqDbgStopLvl = RqDbgPLvl');
  Add('  RqDbgStopKey = RqDbgPKey');
  Add('  RqDbgReadCmd');
  Add('END SUB');
  Add('');
  // Точка с поднятым флагом: стоять ли здесь. Шаг не стоит дальше на той
  // же строке того же уровня (FOR ... : ... : NEXT в одной строке), Step
  // over - на точках глубже уровня остановки, если там нет точки останова.
  Add('SUB RqDbg (RqDbgPId AS LONG, RqDbgPLvl AS LONG, RqDbgPKey AS LONG)');
  Add('  RqDbgDepth = RqDbgPLvl');
  Add('  IF RqDbgMode = 1 THEN');
  Add('    IF RqDbgPKey = RqDbgStopKey THEN');
  Add('      IF RqDbgPLvl = RqDbgStopLvl THEN');
  Add('        IF RqDbgPId > RqDbgStopId THEN EXIT SUB');
  Add('      END IF');
  Add('    END IF');
  Add('  ELSEIF RqDbgMode = 2 THEN');
  Add('    IF RqDbgUser(RqDbgPId) = 0 THEN');
  Add('      IF RqDbgPLvl > RqDbgStopLvl THEN EXIT SUB');
  Add('      IF RqDbgPKey = RqDbgStopKey THEN');
  Add('        IF RqDbgPLvl = RqDbgStopLvl THEN');
  Add('          IF RqDbgPId > RqDbgStopId THEN EXIT SUB');
  Add('        END IF');
  Add('      END IF');
  Add('    END IF');
  Add('  ELSEIF RqDbgMode = 3 THEN');
  Add('    IF RqDbgPId <> RqDbgRunTo THEN');
  Add('      IF RqDbgUser(RqDbgPId) = 0 THEN EXIT SUB');
  Add('    END IF');
  Add('  ELSE');
  Add('    IF RqDbgUser(RqDbgPId) = 0 THEN EXIT SUB');
  Add('  END IF');
  Add('  RqDbgStop(RqDbgPId, RqDbgPLvl, RqDbgPKey)');
  Add('END SUB');
  Add('');
  // События создаёт unIDE до запуска; программа открывает их по имени
  AddLit('RqDbgEvStop = RqDbgCreateEvent(0, 0, 0, "',
         RqDbgStopEventName(FEventBase), '")');
  AddLit('RqDbgEvGo = RqDbgCreateEvent(0, 0, 0, "',
         RqDbgGoEventName(FEventBase), '")');
  Add('RqDbgStopKey = -1');
  Add('RqDbgStopLvl = -1');
  Add('RqDbgReadCmd');
  Add(''' --- unIDE: конец кода отладчика ---');
end;

function TRqDbgInstr.Build(const ASrcFile, ACopyFile, ACmdFile, AStateFile,
                           AEventBase: string): Boolean;
var
  Src, Body, Parts, OutLines: TStringList;
  BodySrc: array of Integer;     // строка Body -> строка исходника
  Logical: array of Integer;     // первая строка логической строки
  LogicalEnd: array of Integer;  // последняя
  LogicalCode: array of string;  // код без комментариев и "_"
  LogicalEsc: array of Boolean;  // $ESCAPECHARS ON на этой строке
  LogicalCount, LineIdx, LogIdx, PartIdx, StartLine, PointId, LeadLines,
    CharIdx: Integer;
  Code, LineCode, Stmt, Indent, NumLabel, Lvl, Word1, OutText, OutAll: string;
  Escape, InSub, AwaitCase, Changed, ColonAfterFirst, HeadDone: Boolean;
  MultiHead, MultiEnd: Boolean;
  MultiPoint: Integer;
  CreateDepth: Integer;
  SkipBlock: string;            // слово блока, который переносится целиком
  Kinds: array of TRqPartKind;
  OutStream: TFileStream;
  UpperSrc: string;
  Defined, Aliases: TStringList;  // имена $DEFINE; псевдоним=директива
  ExclStack: array of Boolean;    // блок условной сборки не собирается
  CondStack: array of Boolean;    // условие блока (для $ELSE)
  CondDepth: Integer;

  function Excluded: Boolean;
  begin
    Result := (CondDepth > 0) and ExclStack[CondDepth - 1];
  end;

  procedure PushCond(ACond: Boolean);
  var
    ParentExcl: Boolean;
  begin
    ParentExcl := Excluded;
    if CondDepth >= Length(ExclStack) then
    begin
      SetLength(ExclStack, CondDepth + 16);
      SetLength(CondStack, CondDepth + 16);
    end;
    CondStack[CondDepth] := ACond;
    ExclStack[CondDepth] := ParentExcl or not ACond;
    Inc(CondDepth);
  end;

  // Директива условной сборки (или её псевдоним) - обработана, True
  function Directive(const ACode: string): Boolean;
  var
    DirWord, DirRest, DirName, DirRepl, ReplWord, ReplRest, DirFirst: string;
    ParentExcl: Boolean;
  begin
    Result := False;
    DirWord := FirstToken(ACode, DirRest);
    if DirWord = '' then
      Exit;
    // #define - псевдоним $define из RAPIDQ.INC ($define #define $define)
    if DirWord[1] in ['$', '#'] then
      DirWord := Copy(DirWord, 2, MaxInt)
    else if Aliases.IndexOfName(DirWord) >= 0 then
      DirWord := Aliases.Values[DirWord]
    else
      Exit;
    DirName := UpperCase(FirstToken(DirRest, DirRepl));
    if DirWord = 'IFDEF' then
      PushCond(Defined.IndexOf(DirName) >= 0)
    else if DirWord = 'IFNDEF' then
      PushCond(Defined.IndexOf(DirName) < 0)
    else if DirWord = 'ELSE' then
    begin
      if CondDepth > 0 then
      begin
        ParentExcl := (CondDepth > 1) and ExclStack[CondDepth - 2];
        CondStack[CondDepth - 1] := not CondStack[CondDepth - 1];
        ExclStack[CondDepth - 1] := ParentExcl or not CondStack[CondDepth - 1];
      end;
    end
    else if DirWord = 'ENDIF' then
    begin
      if CondDepth > 0 then
        Dec(CondDepth);
    end
    else if (DirWord = 'DEFINE') and not Excluded then
    begin
      // $DEFINE brem $ifdef - псевдоним директивы, иначе - имя
      ReplWord := UpperCase(FirstToken(DirRepl, ReplRest));
      if (ReplWord = '$IFDEF') or (ReplWord = '$IFNDEF') or
         (ReplWord = '$ELSE') or (ReplWord = '$ENDIF') then
        Aliases.Values[DirName] := Copy(ReplWord, 2, MaxInt)
      else if (DirName <> '') and (Defined.IndexOf(DirName) < 0) then
        Defined.Add(DirName);
    end
    else if (DirWord = 'UNDEF') and not Excluded then
    begin
      if Defined.IndexOf(DirName) >= 0 then
        Defined.Delete(Defined.IndexOf(DirName));
    end
    else
    begin
      // псевдоним чего-то другого - обычная строка
      DirFirst := TrimLeft(ACode);
      if not (DirFirst[1] in ['$', '#']) then
        Exit;
    end;
    Result := True;
  end;

  procedure AddBody(const AText: string; ASrcLine: Integer);
  begin
    if Body.Count >= Length(BodySrc) then
      SetLength(BodySrc, Body.Count * 2 + 256);
    BodySrc[Body.Count] := ASrcLine;
    Body.Add(AText);
  end;

  // Строка кода отладчика в теле: RqDbg - выбранный префикс
  procedure AddGen(const AText: string; ASrcLine: Integer);
  begin
    AddBody(Pfx(AText), ASrcLine);
  end;

  procedure Verbatim(ALog: Integer);
  var
    PhysIdx: Integer;
  begin
    for PhysIdx := Logical[ALog] to LogicalEnd[ALog] do
      AddBody(Src[PhysIdx], PhysIdx);
  end;

  // Глубина CREATE и блоков TYPE по операторам строки
  procedure TrackBlocks(AParts: TStrings);
  var
    TrackIdx: Integer;
    TrackFirst, TrackSecond: string;
  begin
    for TrackIdx := 0 to AParts.Count - 1 do
    begin
      TrackFirst := WordAt(AParts[TrackIdx], 1);
      TrackSecond := WordAt(AParts[TrackIdx], 2);
      if SkipBlock <> '' then
      begin
        if (TrackFirst = 'END') and (TrackSecond = SkipBlock) then
          SkipBlock := '';
      end
      else if TrackFirst = 'CREATE' then
        Inc(CreateDepth)
      else if (TrackFirst = 'END') and (TrackSecond = 'CREATE') then
      begin
        if CreateDepth > 0 then
          Dec(CreateDepth);
      end
      else if (CreateDepth = 0) and IsSkipBlockWord(TrackFirst) then
        SkipBlock := TrackFirst;
    end;
  end;

  // Строка начала файла, после которой ещё рано ставить код отладчика:
  // пустая, комментарий или директива вроде $APPTYPE
  function IsLeadLine(ALog: Integer): Boolean;
  var
    LeadWord: string;
  begin
    Result := True;
    if Trim(LogicalCode[ALog]) = '' then
      Exit;
    if Copy(TrimLeft(LogicalCode[ALog]), 1, 1) = '$' then
    begin
      LeadWord := UpperCase(Trim(Copy(TrimLeft(LogicalCode[ALog]), 2, 12)));
      if (Copy(LeadWord, 1, 7) = 'APPTYPE') or
         (Copy(LeadWord, 1, 9) = 'TYPECHECK') or
         (Copy(LeadWord, 1, 8) = 'OPTIMIZE') or
         (Copy(LeadWord, 1, 11) = 'ESCAPECHARS') or
         (Copy(LeadWord, 1, 6) = 'OPTION') then
        Exit;
    end;
    Result := False;
  end;

begin
  Result := False;
  FLastError := '';
  FSrcFile := ASrcFile;
  FCopyFile := ACopyFile;
  FCmdFile := ACmdFile;
  FStateFile := AStateFile;
  FEventBase := AEventBase;
  FPointCount := 0;
  FCopyCount := 0;
  SetLength(FPointLine, 0);
  SetLength(FCopySrc, 0);
  SetLength(FLinePoint, 0);

  Src := TStringList.Create;
  Body := TStringList.Create;
  Parts := TStringList.Create;
  OutLines := TStringList.Create;
  Defined := TStringList.Create;
  Aliases := TStringList.Create;
  CondDepth := 0;
  try
    // Из RAPIDQ.INC: $define brem $ifdef, erem $endif, remb, reme
    Aliases.Values['BREM'] := 'IFDEF';
    Aliases.Values['EREM'] := 'ENDIF';
    Aliases.Values['REMB'] := 'IFDEF';
    Aliases.Values['REME'] := 'ENDIF';
    try
      Src.LoadFromFile(ASrcFile);
    except
      on E: Exception do
      begin
        FLastError := 'не прочитан ' + ASrcFile + ': ' + E.Message;
        Exit;
      end;
    end;
    SetLength(FLinePoint, Src.Count + 1);
    for LineIdx := 0 to High(FLinePoint) do
      FLinePoint[LineIdx] := 0;

    // Префикс имён, которого в исходнике нет
    UpperSrc := UpperCase(Src.Text);
    FPrefix := '';
    for LineIdx := 0 to 20 do
    begin
      case LineIdx of
        0: Word1 := 'RqDbg';
        1: Word1 := 'UniDbg';
        2: Word1 := 'UnideDbg';
      else
        Word1 := 'RqDbgZ' + IntToStr(LineIdx);
      end;
      if Pos(UpperCase(Word1), UpperSrc) = 0 then
      begin
        FPrefix := Word1;
        Break;
      end;
    end;
    UpperSrc := '';
    if FPrefix = '' then
    begin
      FLastError := 'не подобрано начало имён кода отладчика: RqDbg, UniDbg ' +
                    'и другие уже есть в исходнике';
      Exit;
    end;

    // Логические строки: строки с "_" в конце кода склеиваются
    SetLength(Logical, Src.Count);
    SetLength(LogicalEnd, Src.Count);
    SetLength(LogicalCode, Src.Count);
    SetLength(LogicalEsc, Src.Count);
    LogicalCount := 0;
    Escape := False;
    LineIdx := 0;
    while LineIdx < Src.Count do
    begin
      StartLine := LineIdx;
      Code := '';
      repeat
        LineCode := TrimRight(StripComment(Src[LineIdx], Escape));
        if (LineCode <> '') and (LineCode[Length(LineCode)] = '_') and
           (LineIdx < Src.Count - 1) then
        begin
          Code := Code + Copy(LineCode, 1, Length(LineCode) - 1) + ' ';
          Inc(LineIdx);
          Continue;
        end;
        Code := Code + LineCode;
        Break;
      until False;
      Logical[LogicalCount] := StartLine;
      LogicalEnd[LogicalCount] := LineIdx;
      LogicalCode[LogicalCount] := Code;
      LogicalEsc[LogicalCount] := Escape;
      // $ESCAPECHARS действует со следующей строки
      Word1 := UpperCase(Trim(Code));
      if Copy(Word1, 1, 12) = '$ESCAPECHARS' then
        Escape := Pos('ON', Copy(Word1, 13, MaxInt)) > 0;
      Inc(LogicalCount);
      Inc(LineIdx);
    end;

    // Начало файла (пустые строки, комментарии, $APPTYPE и подобное) -
    // как есть; код отладчика встанет после него
    LeadLines := 0;
    HeadDone := False;
    InSub := False;
    AwaitCase := False;
    CreateDepth := 0;
    SkipBlock := '';
    for LogIdx := 0 to LogicalCount - 1 do
    begin
      if not HeadDone then
      begin
        if IsLeadLine(LogIdx) then
        begin
          Verbatim(LogIdx);
          LeadLines := Body.Count;
          Continue;
        end;
        HeadDone := True;
      end;

      Code := LogicalCode[LogIdx];
      Escape := LogicalEsc[LogIdx];
      // Условная сборка: директивы и несобираемые блоки - как есть, без
      // разбора (в "brem 0 ... erem" бывает обычный текст)
      if Directive(Code) or Excluded then
      begin
        Verbatim(LogIdx);
        Continue;
      end;
      if (Trim(Code) = '') or (Copy(TrimLeft(Code), 1, 1) = '$') or
         (Copy(TrimLeft(Code), 1, 1) = '#') then
      begin
        Verbatim(LogIdx);
        Continue;
      end;
      SplitStatements(Code, Escape, Parts, ColonAfterFirst);

      // Внутри CREATE и TYPE, и строки, которые их открывают, - как есть
      Changed := (CreateDepth > 0) or (SkipBlock <> '');
      for PartIdx := 0 to Parts.Count - 1 do
      begin
        Word1 := WordAt(Parts[PartIdx], 1);
        if (Word1 = 'CREATE') or IsSkipBlockWord(Word1) then
          Changed := True;
      end;
      if Changed then
      begin
        TrackBlocks(Parts);
        Verbatim(LogIdx);
        Continue;
      end;

      // Вид каждого оператора
      SetLength(Kinds, Parts.Count);
      Changed := False;
      for PartIdx := 0 to Parts.Count - 1 do
      begin
        Stmt := Parts[PartIdx];
        if (PartIdx = 0) and ColonAfterFirst and IsLabelWord(Stmt) then
          Kinds[PartIdx] := pkLabel
        else if Stmt = '' then
          Kinds[PartIdx] := pkPlain
        else
          Kinds[PartIdx] := PartKind(Stmt);
        // Между SELECT CASE и первым CASE - ничего
        if AwaitCase then
        begin
          if (WordAt(Stmt, 1) = 'CASE') or
             ((WordAt(Stmt, 1) = 'END') and (WordAt(Stmt, 2) = 'SELECT')) then
            AwaitCase := False
          else if Kinds[PartIdx] = pkPoint then
            Kinds[PartIdx] := pkPlain;
        end;
        if (WordAt(Stmt, 1) = 'SELECT') and (Kinds[PartIdx] = pkPoint) then
          AwaitCase := True;
        if Kinds[PartIdx] in [pkPoint, pkSubHead, pkSubEnd, pkExitSub] then
          Changed := True;
      end;
      if not Changed then
      begin
        Verbatim(LogIdx);
        Continue;
      end;

      StartLine := Logical[LogIdx];
      LineCode := Src[StartLine];
      CharIdx := 1;
      while (CharIdx <= Length(LineCode)) and (LineCode[CharIdx] in [' ', #9]) do
        Inc(CharIdx);
      Indent := Copy(LineCode, 1, CharIdx - 1);
      if InSub then
        Lvl := 'RqDbgLvl'
      else
        Lvl := '0';

      // Строка с продолжением "_" переносится как есть: склеенная строка
      // могла бы изменить текст ("_" бывает и внутри кавычек - строка
      // продолжается на следующей). Одна точка - перед ней, на первый
      // оператор; заголовок SUB - уровень после неё, END SUB - глубина
      // перед ней.
      if LogicalEnd[LogIdx] > Logical[LogIdx] then
      begin
        MultiHead := False;
        MultiEnd := False;
        MultiPoint := -1;
        for PartIdx := 0 to Parts.Count - 1 do
          case Kinds[PartIdx] of
            pkSubHead: MultiHead := True;
            pkSubEnd: MultiEnd := True;
            pkPoint, pkExitSub:
              if MultiPoint < 0 then
                MultiPoint := PartIdx;
          end;
        if MultiEnd and InSub then
          AddGen(Indent + 'RqDbgDepth = RqDbgLvl - 1', StartLine);
        if (MultiPoint >= 0) and not MultiHead then
        begin
          PointId := NewPoint(StartLine);
          AddGen(Indent + 'IF RqDbgBrk(' + IntToStr(PointId) +
                  ') THEN RqDbg(' + IntToStr(PointId) + ', ' + Lvl + ', ' +
                  IntToStr(StartLine + 1) + ')', StartLine);
          if (Kinds[MultiPoint] = pkExitSub) and InSub then
            AddGen(Indent + 'RqDbgDepth = RqDbgLvl - 1', StartLine);
        end;
        Verbatim(LogIdx);
        if MultiHead then
        begin
          AddGen(Indent + '  DIM RqDbgLvl AS LONG', StartLine);
          AddGen(Indent + '  RqDbgDepth = RqDbgDepth + 1', StartLine);
          AddGen(Indent + '  RqDbgLvl = RqDbgDepth', StartLine);
          InSub := True;
        end;
        if MultiEnd then
          InSub := False;
        Continue;
      end;

      // Строка пересобирается: по оператору в строке, перед точками -
      // проверка. Отступ - как у первой строки.
      for PartIdx := 0 to Parts.Count - 1 do
      begin
        Stmt := Parts[PartIdx];
        case Kinds[PartIdx] of
          pkLabel:
            AddBody(Indent + Stmt + ':', StartLine);
          pkPlain:
            if Stmt <> '' then
              AddBody(Indent + Stmt, StartLine);
          pkSubHead:
            begin
              AddBody(Indent + Stmt, StartLine);
              AddGen(Indent + '  DIM RqDbgLvl AS LONG', StartLine);
              AddGen(Indent + '  RqDbgDepth = RqDbgDepth + 1', StartLine);
              AddGen(Indent + '  RqDbgLvl = RqDbgDepth', StartLine);
              InSub := True;
            end;
          pkSubEnd:
            begin
              if InSub then
                AddGen(Indent + '  RqDbgDepth = RqDbgLvl - 1', StartLine);
              AddBody(Indent + Stmt, StartLine);
              InSub := False;
            end;
          pkPoint, pkExitSub:
            begin
              NumLabel := '';
              if PartIdx = 0 then
                TakeNumericLabel(Stmt, NumLabel);
              PointId := NewPoint(StartLine);
              if InSub then
                Lvl := 'RqDbgLvl'
              else
                Lvl := '0';
              OutText := 'IF RqDbgBrk(' + IntToStr(PointId) + ') THEN RqDbg(' +
                         IntToStr(PointId) + ', ' + Lvl + ', ' +
                         IntToStr(StartLine + 1) + ')';
              if NumLabel <> '' then
                OutText := NumLabel + ' ' + OutText;
              AddGen(Indent + OutText, StartLine);
              if (Kinds[PartIdx] = pkExitSub) and InSub then
                AddGen(Indent + 'RqDbgDepth = RqDbgLvl - 1', StartLine);
              if Stmt <> '' then
                AddBody(Indent + Stmt, StartLine);
            end;
        end;
      end;
    end;

    // Копия: начало файла, код отладчика (число точек известно только
    // теперь), тело
    for LineIdx := 0 to LeadLines - 1 do
      AddCopyLine(OutLines, Body[LineIdx], BodySrc[LineIdx]);
    AddRuntime(OutLines);
    for LineIdx := LeadLines to Body.Count - 1 do
      AddCopyLine(OutLines, Body[LineIdx], BodySrc[LineIdx]);

    // Концы строк - CRLF, как у исходников RapidQ
    try
      OutStream := TFileStream.Create(ACopyFile, fmCreate);
      try
        for LineIdx := 0 to OutLines.Count - 1 do
        begin
          OutAll := OutLines[LineIdx] + CrLf;
          OutStream.WriteBuffer(OutAll[1], Length(OutAll));
        end;
      finally
        OutStream.Free;
      end;
    except
      on E: Exception do
      begin
        FLastError := 'не записана копия ' + ACopyFile + ': ' + E.Message;
        Exit;
      end;
    end;
    Result := True;
  finally
    Aliases.Free;
    Defined.Free;
    OutLines.Free;
    Parts.Free;
    Body.Free;
    Src.Free;
  end;
end;

function TRqDbgInstr.PointOfLine(ALine: Integer): Integer;
begin
  Result := 0;
  if (ALine >= 0) and (ALine < Length(FLinePoint)) then
    Result := FLinePoint[ALine];
end;

function TRqDbgInstr.LineOfPoint(APoint: Integer): Integer;
begin
  Result := -1;
  if (APoint >= 1) and (APoint <= FPointCount) then
    Result := FPointLine[APoint];
end;

function TRqDbgInstr.SrcLineOfCopy(ACopyLine: Integer): Integer;
begin
  Result := -1;
  if (ACopyLine >= 0) and (ACopyLine < FCopyCount) then
    Result := FCopySrc[ACopyLine];
end;

end.
