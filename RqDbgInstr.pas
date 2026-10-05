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
//  Переменные на остановке (этап 2). Объявленные переменные простых типов
//  (DIM ... AS STRING/INTEGER/LONG/..., суффиксы $ % & ! # ?, DEFINT и
//  подобные) и параметры SUB пишутся в файл состояния строками
//  "вид имя|тип=значение" (вид: p - параметр, l - локальная, g - глобальная).
//  Локальные видны только в своей SUB, поэтому в конце каждой SUB/FUNCTION
//  стоит блок дампа с меткой RqDbgVars<номер> (по тесту 1: GOSUB на метку
//  после EXIT SUB работает, метки общие на программу - номер уникален):
//      RqDbgDepth = RqDbgLvl - 1
//      EXIT SUB
//    RqDbgVars3:
//      RqDbgVal("l", "Count", "LONG", STR$(Count))
//      RqDbgHalt
//      RETURN
//    END SUB
//  а проверка в SUB - блочным IF:
//      IF RqDbgBrk(12) THEN
//        RqDbg(12, RqDbgLvl, 345, 0)
//        IF RqDbgWant THEN GOSUB RqDbgVars3
//      END IF
//  RqDbg решает, стоять ли, открывает файл состояния и поднимает
//  RqDbgWant; блок дописывает локальные, RqDbgHalt - глобальные (SUB
//  RqDbgGlobals в конце копии, после всех DIM), закрывает файл и ждёт.
//  На верхнем уровне и в SUBI/FUNCTIONI локальных нет - RqDbg(..., 1)
//  останавливается сам. Массивы, объекты, VARIANT, свои TYPE, переменные
//  без DIM и глобальные из невставленных $INCLUDE-файлов не показываются.
//
//  Выражения Watch (этап 3): a(3), Form.Caption, a+b и т.п. RapidQ не
//  вычисляет текст на ходу, поэтому выражения окна Watch на момент сборки
//  вставляются в копию: в блок дампа SUB, где известны все имена
//  выражения и хотя бы одно из них - параметр или локальная этой SUB, или
//  в RqDbgGlobals, если все имена глобальные (DIM, CREATE, CONST, SUB и
//  FUNCTION главного файла и вставленных $INCLUDE). Встроенные функции (LEN, MID$...) и свойства
//  после точки именами не считаются. Строка в файле состояния -
//  "w номер|тип=значение". Элемент массива или переменная известного
//  простого типа - через STR$ или как есть, остальное - через VARIANT:
//      RqDbgWV = выражение
//      RqDbgWT = RqDbgWS + RqDbgWV     (RqDbgWS - VARIANT со строкой "":
//                                      строка + число дают строку)
//  Выражение с ":" или "'" вне кавычек не вставляется. Новое выражение в
//  Watch видно только после пересборки.
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
//  $INCLUDE-файлы. Файлы из списка AIncFiles (Build) вставляются в копию
//  текстом на место строки $INCLUDE и инструментируются вместе с главным:
//  точки, шаги, их переменные и имена для Watch. Строка $INCLUDE
//  становится комментарием, после текста файла - комментарий "конец".
//  Файл ищется, как у rc.exe и вкладки Includes: путь целиком - как есть,
//  иначе в папке главного .bas, потом в папке Include из настроек.
//  Повторный $INCLUDE уже вставленного файла - комментарий (так же
//  вкладка Includes: "уже подключён выше"). Остальные $INCLUDE остаются
//  как есть: rc.exe берёт исходный файл, без проверок. У каждой строки
//  общего текста - файл (номер в FileName) и строка в нём.
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
    FPointProc: array of Integer;   // номер точки -> процедура, -1 - главная часть
    FProcNames: TStringList;        // "SUB Имя" по номеру процедуры
    FCurProc: Integer;              // процедура, в которой идёт разбор
    FCopyWatch: array of Integer;   // строка копии -> выражение Watch, -1
    FWatchExprs: TStringList;       // выражения Watch на момент сборки
    FWatchWhere: TStringList;       // где вычисляется: "SUB A, SUB B", "*"
    FWatchNote: TStringList;        // почему не вычисляется нигде
    FFiles: TStringList;            // файлы копии: 0 - главный, дальше $INCLUDE
    FMergedFile: array of Integer;  // строка общего текста -> номер файла
    FMergedLine: array of Integer;  // -> строка в своём файле (с 0)
    FFileMerged: array of array of Integer; // файл, строка -> строка текста
    procedure AddCopyLine(AOut: TStrings; const AText: string;
                          ASrcLine: Integer; AWatch: Integer = -1);
    function NewPoint(ASrcLine: Integer): Integer;
    procedure AddRuntime(AOut: TStrings);
    function Pfx(const AText: string): string;
  public
    // Копия ASrcFile в ACopyFile. ACmdFile, AStateFile - файлы команды и
    // состояния (пути целиком), AEventBase - начало имён событий. False -
    // причина в LastError.
    // AWatch - выражения окна Watch (может быть nil). AIncFiles - пути
    // $INCLUDE-файлов, которые вставляются в копию (nil - никакие),
    // AIncDir - папка Include из настроек.
    function Build(const ASrcFile, ACopyFile, ACmdFile, AStateFile,
                   AEventBase: string; AWatch: TStrings;
                   const AIncDir: string; AIncFiles: TStrings): Boolean;
    // Файлы копии: 0 - главный, дальше вставленные $INCLUDE
    function FileCount: Integer;
    function FileName(AFileIdx: Integer): string;
    // Номер файла копии, -1 - файл в неё не вставлен
    function FileIndex(const AFile: string): Integer;
    // Номер выражения Watch этой сборки, -1 - его не было при сборке
    function WatchIndex(const AExpr: string): Integer;
    // Где вычисляется выражение ("SUB A, SUB B", "*" - везде) и почему
    // нигде (пусто - вычисляется)
    function WatchWhere(AIndex: Integer): string;
    function WatchNote(AIndex: Integer): string;
    // Выражение Watch строки копии (с 0), -1 - не его строка
    function WatchOfCopy(ACopyLine: Integer): Integer;
    // Текст выражения Watch этой сборки по номеру
    function WatchExpr(AIndex: Integer): string;
    // Первая точка строки ALine (с 0) файла AFileIdx, 0 - на строке нет
    // кода
    function PointOfLine(AFileIdx, ALine: Integer): Integer;
    // Строка (с 0) и файл точки; -1 - нет такой
    function LineOfPoint(APoint: Integer): Integer;
    function FileOfPoint(APoint: Integer): Integer;
    // Строка исходника (с 0) по строке копии (с 0), -1 - строка добавлена;
    // файл этой строки (у добавленной - 0, главный)
    function SrcLineOfCopy(ACopyLine: Integer): Integer;
    function SrcFileOfCopy(ACopyLine: Integer): Integer;
    property SrcFile: string read FSrcFile;
    property CopyFile: string read FCopyFile;
    property CmdFile: string read FCmdFile;
    property StateFile: string read FStateFile;
    property EventBase: string read FEventBase;
    property PointCount: Integer read FPointCount;
    property LastError: string read FLastError;
    property Prefix: string read FPrefix;
    // Где точка: "SUB Имя", "FUNCTION Имя" или '' - главная часть
    function ProcOfPoint(APoint: Integer): string;
    constructor Create;
    destructor Destroy; override;
  end;

// Путь для строки в копии: прямые косые (обратная при $ESCAPECHARS ON -
// начало escape)
function RqDbgSlashPath(const APath: string): string;

// Имена событий по началу AEventBase
function RqDbgStopEventName(const AEventBase: string): string;
function RqDbgGoEventName(const AEventBase: string): string;

// Имя файла из строки "$INCLUDE "файл"" или "$INCLUDE <файл>"; не
// $INCLUDE (в том числе закомментированная) - пусто. Косые - обратные.
function RqDbgIncludeName(const ALine: string): string;
// Где лежит подключаемый файл: путь целиком - как есть, иначе в AMainDir,
// потом в AIncDir. '' - не найден.
function RqDbgResolveInclude(const AName, AMainDir, AIncDir: string): string;

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

function RqDbgIncludeName(const ALine: string): string;
const
  IncTag = '$include';
var
  Txt: string;
  NameStart, NameEnd: Integer;
  CloseChar: Char;
begin
  Result := '';
  Txt := TrimLeft(ALine);
  if LowerCase(Copy(Txt, 1, Length(IncTag))) <> IncTag then
    Exit;
  Txt := TrimLeft(Copy(Txt, Length(IncTag) + 1, MaxInt));
  if Txt = '' then
    Exit;
  if Txt[1] = '"' then
    CloseChar := '"'
  else if Txt[1] = '<' then
    CloseChar := '>'
  else
    Exit;
  NameStart := 2;
  NameEnd := NameStart;
  while (NameEnd <= Length(Txt)) and (Txt[NameEnd] <> CloseChar) do
    Inc(NameEnd);
  if NameEnd > Length(Txt) then
    Exit;
  Result := Trim(Copy(Txt, NameStart, NameEnd - NameStart));
  Result := StringReplace(Result, '/', '\', [rfReplaceAll]);
end;

function RqDbgResolveInclude(const AName, AMainDir, AIncDir: string): string;
begin
  Result := '';
  if AName = '' then
    Exit;
  if (ExtractFileDrive(AName) <> '') or (Copy(AName, 1, 2) = '\\') then
  begin
    if FileExists(AName) then
      Result := AName;
    Exit;
  end;
  if (AMainDir <> '') and
     FileExists(IncludeTrailingPathDelimiter(AMainDir) + AName) then
  begin
    Result := ExpandFileName(IncludeTrailingPathDelimiter(AMainDir) + AName);
    Exit;
  end;
  if (AIncDir <> '') and
     FileExists(IncludeTrailingPathDelimiter(AIncDir) + AName) then
    Result := ExpandFileName(IncludeTrailingPathDelimiter(AIncDir) + AName);
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

// Части через запятую вне скобок и кавычек
procedure SplitCommas(const AText: string; AParts: TStrings);
var
  CharIdx, Depth, StartPos: Integer;
  InQuote: Boolean;
begin
  AParts.Clear;
  Depth := 0;
  InQuote := False;
  StartPos := 1;
  for CharIdx := 1 to Length(AText) do
    case AText[CharIdx] of
      '"': InQuote := not InQuote;
      '(': if not InQuote then Inc(Depth);
      ')': if not InQuote then Dec(Depth);
      ',':
        if not InQuote and (Depth <= 0) then
        begin
          AParts.Add(Trim(Copy(AText, StartPos, CharIdx - StartPos)));
          StartPos := CharIdx + 1;
        end;
    end;
  AParts.Add(Trim(Copy(AText, StartPos, MaxInt)));
end;

// Тип, который можно показать: STRING или число. '' - нельзя (объект,
// VARIANT, свой TYPE).
function ShowableType(const AType: string): string;
const
  NumTypes: array[0..8] of string = ('BYTE', 'WORD', 'DWORD', 'SHORT',
    'INTEGER', 'LONG', 'SINGLE', 'DOUBLE', 'INT64');
var
  TypeIdx: Integer;
begin
  Result := '';
  if AType = 'STRING' then
  begin
    Result := AType;
    Exit;
  end;
  for TypeIdx := Low(NumTypes) to High(NumTypes) do
    if AType = NumTypes[TypeIdx] then
    begin
      Result := AType;
      Exit;
    end;
end;

// Тип по DEFxxx: DEFSTR - STRING, DEFINT - INTEGER... '' - не показывается
function DefWordType(const AWord: string): string;
begin
  Result := '';
  if AWord = 'DEFSTR' then Result := 'STRING'
  else if AWord = 'DEFINT' then Result := 'INTEGER'
  else if AWord = 'DEFLNG' then Result := 'LONG'
  else if AWord = 'DEFSNG' then Result := 'SINGLE'
  else if AWord = 'DEFDBL' then Result := 'DOUBLE'
  else if AWord = 'DEFBYTE' then Result := 'BYTE'
  else if AWord = 'DEFWORD' then Result := 'WORD'
  else if AWord = 'DEFDWORD' then Result := 'DWORD'
  else if AWord = 'DEFSHORT' then Result := 'SHORT';
end;

// Переменные из списка объявлений ("a AS LONG, b$, c(10) AS INTEGER" -
// после DIM, в скобках заголовка SUB, после DEFINT). ADefType - тип, если
// нет ни AS, ни суффикса ('' - такие не берутся). В AOut - строки
// "вид<TAB>имя<TAB>тип", без повторов имён.
procedure CollectVars(const AText: string; AKind: Char; const ADefType: string;
                      AOut: TStrings);
var
  Items: TStringList;
  ItemIdx, CharIdx, OutIdx: Integer;
  Item, VarName, Rest, VarType, Upper: string;
  Known: Boolean;
begin
  Items := TStringList.Create;
  try
    SplitCommas(AText, Items);
    for ItemIdx := 0 to Items.Count - 1 do
    begin
      Item := Trim(Items[ItemIdx]);
      Upper := UpperCase(Item);
      if (Copy(Upper, 1, 6) = 'BYREF ') or (Copy(Upper, 1, 6) = 'BYVAL ') then
        Item := Trim(Copy(Item, 7, MaxInt));
      if (Item = '') or not (Item[1] in ['A'..'Z', 'a'..'z', '_']) then
        Continue;
      CharIdx := 1;
      while (CharIdx <= Length(Item)) and
            (Item[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
        Inc(CharIdx);
      while (CharIdx <= Length(Item)) and
            (Item[CharIdx] in ['$', '%', '&', '!', '#', '?']) do
        Inc(CharIdx);
      VarName := Copy(Item, 1, CharIdx - 1);
      Rest := TrimLeft(Copy(Item, CharIdx, MaxInt));
      // Массив - не показывается
      if Copy(Rest, 1, 1) = '(' then
        Continue;
      VarType := '';
      if UpperCase(Copy(Rest, 1, 3)) = 'AS ' then
        VarType := UpperCase(WordAt(Copy(Rest, 4, MaxInt), 1))
      else
        case VarName[Length(VarName)] of
          '$': VarType := 'STRING';
          '%': VarType := 'SHORT';
          '&': VarType := 'LONG';
          '!': VarType := 'SINGLE';
          '#': VarType := 'DOUBLE';
          '?':
            if Copy(VarName, Length(VarName) - 1, 2) = '??' then
              VarType := 'WORD'
            else
              VarType := 'BYTE';
        else
          VarType := ADefType;
        end;
      VarType := ShowableType(VarType);
      if VarType = '' then
        Continue;
      Known := False;
      for OutIdx := 0 to AOut.Count - 1 do
        if CompareText(Copy(AOut[OutIdx], 3, Length(VarName) + 1),
                       VarName + #9) = 0 then
        begin
          Known := True;
          Break;
        end;
      if not Known then
        AOut.Add(AKind + #9 + VarName + #9 + VarType);
    end;
  finally
    Items.Free;
  end;
end;

// Параметры из заголовка "SUB Имя (a AS LONG, b$)"
function HeaderParams(const AHead: string): string;
var
  OpenPos, CharIdx, Depth: Integer;
begin
  Result := '';
  OpenPos := Pos('(', AHead);
  if OpenPos = 0 then
    Exit;
  Depth := 0;
  for CharIdx := OpenPos to Length(AHead) do
  begin
    if AHead[CharIdx] = '(' then
      Inc(Depth)
    else if AHead[CharIdx] = ')' then
    begin
      Dec(Depth);
      if Depth = 0 then
      begin
        Result := Copy(AHead, OpenPos + 1, CharIdx - OpenPos - 1);
        Exit;
      end;
    end;
  end;
end;

// Все имена объявления ("a AS LONG, b$, c(10) AS QFORM" - после DIM,
// CONST, DEFxxx, в скобках заголовка SUB) - в AOut строками "ИМЯ=ТИП",
// у массива тип с "[]". Тип по суффиксу, без AS и суффикса - пустой.
procedure CollectNames(const AText: string; AOut: TStrings);
var
  Items: TStringList;
  ItemIdx, CharIdx, Depth: Integer;
  Item, VarName, Rest, VarType: string;
  IsArray: Boolean;
begin
  Items := TStringList.Create;
  try
    SplitCommas(AText, Items);
    for ItemIdx := 0 to Items.Count - 1 do
    begin
      Item := Trim(Items[ItemIdx]);
      if (UpperCase(Copy(Item, 1, 6)) = 'BYREF ') or
         (UpperCase(Copy(Item, 1, 6)) = 'BYVAL ') then
        Item := Trim(Copy(Item, 7, MaxInt));
      if (Item = '') or not (Item[1] in ['A'..'Z', 'a'..'z', '_']) then
        Continue;
      CharIdx := 1;
      while (CharIdx <= Length(Item)) and
            (Item[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
        Inc(CharIdx);
      while (CharIdx <= Length(Item)) and
            (Item[CharIdx] in ['$', '%', '&', '!', '#', '?']) do
        Inc(CharIdx);
      VarName := UpperCase(Copy(Item, 1, CharIdx - 1));
      Rest := TrimLeft(Copy(Item, CharIdx, MaxInt));
      IsArray := Copy(Rest, 1, 1) = '(';
      if IsArray then
      begin
        Depth := 0;
        CharIdx := 1;
        while CharIdx <= Length(Rest) do
        begin
          if Rest[CharIdx] = '(' then
            Inc(Depth)
          else if Rest[CharIdx] = ')' then
          begin
            Dec(Depth);
            if Depth = 0 then
              Break;
          end;
          Inc(CharIdx);
        end;
        Rest := TrimLeft(Copy(Rest, CharIdx + 1, MaxInt));
      end;
      VarType := '';
      if UpperCase(Copy(Rest, 1, 3)) = 'AS ' then
        VarType := UpperCase(WordAt(Copy(Rest, 4, MaxInt), 1))
      else
        case VarName[Length(VarName)] of
          '$': VarType := 'STRING';
          '%': VarType := 'SHORT';
          '&': VarType := 'LONG';
          '!': VarType := 'SINGLE';
          '#': VarType := 'DOUBLE';
          '?': VarType := 'BYTE';
        end;
      if IsArray then
        VarType := VarType + '[]';
      if AOut.IndexOfName(VarName) < 0 then
        AOut.Add(VarName + '=' + VarType);
    end;
  finally
    Items.Free;
  end;
end;

// Встроенные функции и слова-операторы RapidQ: в выражении Watch это не
// имена переменных
function IsBuiltinWord(const AWord: string): Boolean;
const
  Builtins: array[0..63] of string = ('AND', 'OR', 'NOT', 'XOR', 'MOD',
    'SHL', 'SHR', 'INV', 'LEN', 'LEFT$', 'RIGHT$', 'MID$', 'STR$', 'VAL',
    'CHR$', 'ASC', 'UCASE$', 'LCASE$', 'INSTR', 'RINSTR', 'ABS', 'INT',
    'FIX', 'SQR', 'SIN', 'COS', 'TAN', 'ATN', 'EXP', 'LOG', 'SGN', 'ROUND',
    'FRAC', 'RND', 'HEX$', 'BIN$', 'OCT$', 'SPACE$', 'STRING$', 'TRIM$',
    'LTRIM$', 'RTRIM$', 'FIELD$', 'TALLY', 'DELETE$', 'INSERT$', 'REPLACE$',
    'REPLACESUBSTR$', 'REVERSE$', 'STRF$', 'FORMAT$', 'TIME$', 'DATE$',
    'TIMER', 'LBOUND', 'UBOUND', 'FILEEXISTS', 'DIREXISTS', 'CURDIR$',
    'COMMAND$', 'ENVIRON$', 'VARPTR', 'CONVBASE$', 'LCASE');
var
  WordIdx: Integer;
begin
  Result := True;
  for WordIdx := Low(Builtins) to High(Builtins) do
    if AWord = Builtins[WordIdx] then
      Exit;
  Result := False;
end;

// Имена в выражении Watch: без свойств после ".", встроенных функций и
// чисел, заглавными, без повторов. False - выражение нельзя вставить в код
// (":" или "'" вне кавычек).
function ExprNames(const AExpr: string; ANames: TStrings): Boolean;
var
  CharIdx, WordStart, PrevIdx: Integer;
  WordText: string;
  AfterDot: Boolean;
begin
  ANames.Clear;
  Result := False;
  CharIdx := 1;
  while CharIdx <= Length(AExpr) do
  begin
    case AExpr[CharIdx] of
      '"':
        begin
          CharIdx := SkipQuoted(AExpr, CharIdx, False) + 1;
          Continue;
        end;
      ':', '''', #13, #10:
        Exit;
      'A'..'Z', 'a'..'z', '_':
        begin
          WordStart := CharIdx;
          while (CharIdx <= Length(AExpr)) and
                (AExpr[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
            Inc(CharIdx);
          while (CharIdx <= Length(AExpr)) and
                (AExpr[CharIdx] in ['$', '%', '&', '!', '#', '?']) do
            Inc(CharIdx);
          WordText := UpperCase(Copy(AExpr, WordStart, CharIdx - WordStart));
          PrevIdx := WordStart - 1;
          while (PrevIdx >= 1) and (AExpr[PrevIdx] = ' ') do
            Dec(PrevIdx);
          AfterDot := (PrevIdx >= 1) and (AExpr[PrevIdx] = '.');
          if not AfterDot and not IsBuiltinWord(WordText) and
             (ANames.IndexOf(WordText) < 0) then
            ANames.Add(WordText);
          Continue;
        end;
      '0'..'9':
        begin
          while (CharIdx <= Length(AExpr)) and
                (AExpr[CharIdx] in ['0'..'9', '.', 'E', 'e']) do
            Inc(CharIdx);
          Continue;
        end;
    end;
    Inc(CharIdx);
  end;
  Result := True;
end;

// Выражение вида "Имя" или "Имя(...)" (скобки - до конца): AName - имя
// заглавными, AHasArgs - есть скобки. False - выражение сложнее.
function SimpleExpr(const AExpr: string; var AName: string;
                    var AHasArgs: Boolean): Boolean;
var
  CharIdx, Depth: Integer;
  Rest: string;
begin
  Result := False;
  AName := '';
  AHasArgs := False;
  if (AExpr = '') or not (AExpr[1] in ['A'..'Z', 'a'..'z', '_']) then
    Exit;
  CharIdx := 1;
  while (CharIdx <= Length(AExpr)) and
        (AExpr[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
    Inc(CharIdx);
  while (CharIdx <= Length(AExpr)) and
        (AExpr[CharIdx] in ['$', '%', '&', '!', '#', '?']) do
    Inc(CharIdx);
  AName := UpperCase(Copy(AExpr, 1, CharIdx - 1));
  Rest := Trim(Copy(AExpr, CharIdx, MaxInt));
  if Rest = '' then
  begin
    Result := True;
    Exit;
  end;
  if Rest[1] <> '(' then
    Exit;
  Depth := 0;
  for CharIdx := 1 to Length(Rest) do
  begin
    if Rest[CharIdx] = '(' then
      Inc(Depth)
    else if Rest[CharIdx] = ')' then
    begin
      Dec(Depth);
      if (Depth = 0) and (CharIdx < Length(Rest)) then
        Exit;   // после скобок ещё что-то: a(1).Caption, a(1)+2
    end;
  end;
  AHasArgs := True;
  Result := Depth = 0;
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
                                  ASrcLine: Integer; AWatch: Integer = -1);
begin
  AOut.Add(AText);
  if FCopyCount >= Length(FCopySrc) then
  begin
    SetLength(FCopySrc, FCopyCount * 2 + 256);
    SetLength(FCopyWatch, FCopyCount * 2 + 256);
  end;
  FCopySrc[FCopyCount] := ASrcLine;
  FCopyWatch[FCopyCount] := AWatch;
  Inc(FCopyCount);
end;

function TRqDbgInstr.WatchIndex(const AExpr: string): Integer;
var
  ExprIdx: Integer;
begin
  Result := -1;
  for ExprIdx := 0 to FWatchExprs.Count - 1 do
    if CompareText(FWatchExprs[ExprIdx], Trim(AExpr)) = 0 then
    begin
      Result := ExprIdx;
      Exit;
    end;
end;

function TRqDbgInstr.WatchWhere(AIndex: Integer): string;
begin
  Result := '';
  if (AIndex >= 0) and (AIndex < FWatchWhere.Count) then
    Result := FWatchWhere[AIndex];
end;

function TRqDbgInstr.WatchNote(AIndex: Integer): string;
begin
  Result := '';
  if (AIndex >= 0) and (AIndex < FWatchNote.Count) then
    Result := FWatchNote[AIndex];
end;

function TRqDbgInstr.WatchExpr(AIndex: Integer): string;
begin
  Result := '';
  if (AIndex >= 0) and (AIndex < FWatchExprs.Count) then
    Result := FWatchExprs[AIndex];
end;

function TRqDbgInstr.WatchOfCopy(ACopyLine: Integer): Integer;
begin
  Result := -1;
  if (ACopyLine >= 0) and (ACopyLine < FCopyCount) then
    Result := FCopyWatch[ACopyLine];
end;

constructor TRqDbgInstr.Create;
begin
  inherited Create;
  FProcNames := TStringList.Create;
  FWatchExprs := TStringList.Create;
  FWatchWhere := TStringList.Create;
  FWatchNote := TStringList.Create;
  FFiles := TStringList.Create;
end;

destructor TRqDbgInstr.Destroy;
begin
  FProcNames.Free;
  FWatchExprs.Free;
  FWatchWhere.Free;
  FWatchNote.Free;
  FFiles.Free;
  inherited;
end;

function TRqDbgInstr.ProcOfPoint(APoint: Integer): string;
begin
  Result := '';
  if (APoint >= 1) and (APoint <= FPointCount) and
     (FPointProc[APoint] >= 0) and (FPointProc[APoint] < FProcNames.Count) then
    Result := FProcNames[FPointProc[APoint]];
end;

function TRqDbgInstr.NewPoint(ASrcLine: Integer): Integer;
begin
  Inc(FPointCount);
  if FPointCount >= Length(FPointLine) then
  begin
    SetLength(FPointLine, FPointCount * 2 + 256);
    SetLength(FPointProc, FPointCount * 2 + 256);
  end;
  FPointLine[FPointCount] := ASrcLine;
  FPointProc[FPointCount] := FCurProc;
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
  Add('DIM RqDbgWant AS LONG');
  Add('DIM RqDbgPendId AS LONG');
  Add('DIM RqDbgPendLvl AS LONG');
  Add('DIM RqDbgPendKey AS LONG');
  Add('DIM RqDbgStateFile AS QFILESTREAM');
  Add('DIM RqDbgWV AS VARIANT');
  Add('DIM RqDbgWS AS VARIANT');
  Add('DIM RqDbgWT AS STRING');
  Add('DIM RqDbgBusy AS LONG');
  Add('DECLARE SUB RqDbgReadCmd');
  Add('DECLARE SUB RqDbgGlobals');
  Add('DECLARE SUB RqDbgHalt');
  Add('DECLARE SUB RqDbgVal (RqDbgVK AS STRING, RqDbgVN AS STRING, ' +
      'RqDbgVT AS STRING, RqDbgVV AS STRING)');
  Add('DECLARE SUB RqDbg (RqDbgPId AS LONG, RqDbgPLvl AS LONG, ' +
      'RqDbgPKey AS LONG, RqDbgPSelf AS LONG)');
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
  // Строка переменной в файл состояния: "вид имя|тип=значение". Длинная
  // строка - обрезается, перевод строки - знак CHR$(182).
  Add('SUB RqDbgVal (RqDbgVK AS STRING, RqDbgVN AS STRING, ' +
      'RqDbgVT AS STRING, RqDbgVV AS STRING)');
  Add('  DIM RqDbgVText AS STRING');
  Add('  RqDbgVText = RqDbgVV');
  Add('  IF LEN(RqDbgVText) > 300 THEN RqDbgVText = LEFT$(RqDbgVText, 300) + "..."');
  Add('  RqDbgVText = REPLACESUBSTR$(RqDbgVText, CHR$(13), CHR$(182))');
  Add('  RqDbgVText = REPLACESUBSTR$(RqDbgVText, CHR$(10), "")');
  Add('  RqDbgStateFile.WriteLine(RqDbgVK + " " + RqDbgVN + "|" + RqDbgVT + ' +
      '"=" + RqDbgVText)');
  Add('END SUB');
  Add('');
  // Остановка: глобальные в файл состояния (начат в RqDbg, локальные уже
  // в нём), "stop", ждать "go" (без DOEVENTS - окна программы стоят),
  // затем новая команда
  Add('SUB RqDbgHalt');
  Add('  DIM RqDbgCallRes AS LONG');
  Add('  RqDbgWant = 0');
  Add('  RqDbgGlobals');
  Add('  RqDbgStateFile.WriteLine("#end")');
  Add('  RqDbgStateFile.Close');
  Add('  RqDbgCallRes = RqDbgResetEvent(RqDbgEvGo)');
  Add('  RqDbgCallRes = RqDbgSetEvent(RqDbgEvStop)');
  Add('  RqDbgCallRes = RqDbgWait(RqDbgEvGo, -1)');
  Add('  RqDbgStopId = RqDbgPendId');
  Add('  RqDbgStopLvl = RqDbgPendLvl');
  Add('  RqDbgStopKey = RqDbgPendKey');
  Add('  RqDbgReadCmd');
  Add('  RqDbgBusy = 0');
  Add('END SUB');
  Add('');
  // Точка с поднятым флагом: стоять ли здесь. Шаг не стоит дальше на той
  // же строке того же уровня (FOR ... : ... : NEXT в одной строке), Step
  // over - на точках глубже уровня остановки, если там нет точки останова.
  // RqDbgPSelf = 1 - остановиться здесь же (главная часть, SUBI); 0 -
  // поднять RqDbgWant: SUB допишет локальные (GOSUB RqDbgVars...) и
  // позовёт RqDbgHalt
  Add('SUB RqDbg (RqDbgPId AS LONG, RqDbgPLvl AS LONG, RqDbgPKey AS LONG, ' +
      'RqDbgPSelf AS LONG)');
  // Пока идёт остановка (дамп, выражения Watch с вызовом FUNCTION
  // программы) - проверки молчат
  Add('  IF RqDbgBusy THEN EXIT SUB');
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
  Add('  RqDbgBusy = 1');
  Add('  RqDbgPendId = RqDbgPId');
  Add('  RqDbgPendLvl = RqDbgPLvl');
  Add('  RqDbgPendKey = RqDbgPKey');
  AddLit('  RqDbgStateFile.Open("', StatePath, '", 65535)');
  Add('  RqDbgStateFile.WriteLine("s " + STR$(RqDbgPId) + " " + ' +
      'STR$(RqDbgPLvl))');
  Add('  IF RqDbgPSelf THEN');
  Add('    RqDbgHalt');
  Add('  ELSE');
  Add('    RqDbgWant = 1');
  Add('  END IF');
  Add('END SUB');
  Add('');
  // События создаёт unIDE до запуска; программа открывает их по имени
  AddLit('RqDbgEvStop = RqDbgCreateEvent(0, 0, 0, "',
         RqDbgStopEventName(FEventBase), '")');
  AddLit('RqDbgEvGo = RqDbgCreateEvent(0, 0, 0, "',
         RqDbgGoEventName(FEventBase), '")');
  Add('RqDbgStopKey = -1');
  Add('RqDbgStopLvl = -1');
  Add('RqDbgWS = ""');
  Add('RqDbgReadCmd');
  Add(''' --- unIDE: конец кода отладчика ---');
end;

function TRqDbgInstr.Build(const ASrcFile, ACopyFile, ACmdFile, AStateFile,
                           AEventBase: string; AWatch: TStrings;
                           const AIncDir: string; AIncFiles: TStrings): Boolean;
const
  MaxIncDepth = 20;   // защита от зацикливания через разные имена файла
var
  Src, Body, Parts, OutLines: TStringList;
  BodySrc: array of Integer;     // строка Body -> строка исходника
  BodyWatch: array of Integer;   // строка Body -> выражение Watch, -1
  Logical: array of Integer;     // первая строка логической строки
  LogicalEnd: array of Integer;  // последняя
  LogicalCode: array of string;  // код без комментариев и "_"
  LogicalEsc: array of Boolean;  // $ESCAPECHARS ON на этой строке
  LogicalCount, LineIdx, LogIdx, PartIdx, StartLine, PointId, LeadLines,
    CharIdx: Integer;
  Code, LineCode, Stmt, Indent, NumLabel, Word1, OutAll: string;
  Escape, InSub, AwaitCase, Changed, ColonAfterFirst, HeadDone: Boolean;
  MultiHead, MultiEnd: Boolean;
  MultiPoint: Integer;
  CreateDepth: Integer;
  SkipBlock: string;            // слово блока, который переносится целиком
  Kinds: array of TRqPartKind;
  OutStream: TFileStream;
  UpperSrc: string;
  Defined, Aliases: TStringList;  // имена $DEFINE; псевдоним=директива
  GlobalVars, ProcVars: TStringList; // "вид<TAB>имя<TAB>тип" для дампа
  CurDump: Boolean;               // у SUB есть блок дампа (не SUBI)
  CurExit, CurVarsLabel: string;  // EXIT SUB/FUNCTION и метка блока
  VarIdx: Integer;
  VarRest: string;
  GlobalAll: TStringList;         // все глобальные имена: "ИМЯ=ТИП"
  ProcAll: TStringList;           // все имена SUB: параметры и DIM
  LocalAll: TStringList;          // имена всех SUB (для "не найдено")
  WatchNames: array of TStringList; // имена каждого выражения, nil - нельзя
  WatchIdx, NameIdx: Integer;
  WatchLines: TStringList;
  PreInSub: Boolean;
  PreCreate: Integer;
  PreSkip, NoteText: string;
  ExclStack: array of Boolean;    // блок условной сборки не собирается
  CondStack: array of Boolean;    // условие блока (для $ELSE)
  CondDepth: Integer;
  MainDir: string;

  // Строка общего текста: файл AFileIdx, его строка ALine
  procedure AddMerged(const AText: string; AFileIdx, ALine: Integer);
  begin
    if Src.Count >= Length(FMergedFile) then
    begin
      SetLength(FMergedFile, Src.Count * 2 + 256);
      SetLength(FMergedLine, Src.Count * 2 + 256);
    end;
    FMergedFile[Src.Count] := AFileIdx;
    FMergedLine[Src.Count] := ALine;
    Src.Add(AText);
  end;

  // Вставлять ли $INCLUDE-файл AFull
  function InIncList(const AFull: string): Boolean;
  var
    ListIdx: Integer;
  begin
    Result := False;
    if AIncFiles = nil then
      Exit;
    for ListIdx := 0 to AIncFiles.Count - 1 do
      if CompareText(ExpandFileName(AIncFiles[ListIdx]),
                     ExpandFileName(AFull)) = 0 then
      begin
        Result := True;
        Exit;
      end;
  end;

  // Файл AFile (номер AFileIdx) - в общий текст, вставляемые $INCLUDE -
  // на место своей строки. False - файл не прочитан (LastError).
  function LoadMerged(const AFile: string; AFileIdx, ADepth: Integer): Boolean;
  var
    FileLines: TStringList;
    FileLineIdx, NewIdx: Integer;
    IncName, IncFull, IncLine: string;
  begin
    Result := False;
    FileLines := TStringList.Create;
    try
      try
        FileLines.LoadFromFile(AFile);
      except
        on E: Exception do
        begin
          FLastError := 'не прочитан ' + AFile + ': ' + E.Message;
          Exit;
        end;
      end;
      SetLength(FFileMerged[AFileIdx], FileLines.Count);
      for FileLineIdx := 0 to FileLines.Count - 1 do
      begin
        FFileMerged[AFileIdx][FileLineIdx] := Src.Count;
        IncName := RqDbgIncludeName(FileLines[FileLineIdx]);
        IncFull := '';
        if (IncName <> '') and (ADepth < MaxIncDepth) then
        begin
          IncFull := RqDbgResolveInclude(IncName, MainDir, AIncDir);
          if (IncFull <> '') and not InIncList(IncFull) then
            IncFull := '';
        end;
        if IncFull = '' then
        begin
          AddMerged(FileLines[FileLineIdx], AFileIdx, FileLineIdx);
          Continue;
        end;
        IncLine := Trim(FileLines[FileLineIdx]);
        if FileIndex(IncFull) >= 0 then
        begin
          AddMerged(''' unIDE: ' + IncLine + ' - уже вставлен выше',
                    AFileIdx, FileLineIdx);
          Continue;
        end;
        AddMerged(''' unIDE: ' + IncLine + ' - текст файла ниже', AFileIdx,
                  FileLineIdx);
        FFiles.Add(ExpandFileName(IncFull));
        NewIdx := FFiles.Count - 1;
        SetLength(FFileMerged, FFiles.Count);
        if not LoadMerged(IncFull, NewIdx, ADepth + 1) then
          Exit;
        AddMerged(''' unIDE: конец ' + IncName, AFileIdx, FileLineIdx);
      end;
      Result := True;
    finally
      FileLines.Free;
    end;
  end;

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

  procedure AddBodyW(const AText: string; ASrcLine, AWatch: Integer);
  begin
    if Body.Count >= Length(BodySrc) then
    begin
      SetLength(BodySrc, Body.Count * 2 + 256);
      SetLength(BodyWatch, Body.Count * 2 + 256);
    end;
    BodySrc[Body.Count] := ASrcLine;
    BodyWatch[Body.Count] := AWatch;
    Body.Add(AText);
  end;

  procedure AddBody(const AText: string; ASrcLine: Integer);
  begin
    AddBodyW(AText, ASrcLine, -1);
  end;

  // Строка кода отладчика в теле: RqDbg - выбранный префикс
  procedure AddGen(const AText: string; ASrcLine: Integer);
  begin
    AddBody(Pfx(AText), ASrcLine);
  end;

  // Строка дампа переменной: RqDbgVal("вид", "имя", "тип", значение).
  // Префикс - только у RqDbgVal: в имени переменной программы RqDbg
  // может быть и своё.
  function ValLine(const AVarDesc: string): string;
  var
    DescKind, DescName, DescType, DescRest: string;
    TabPos: Integer;
  begin
    DescKind := Copy(AVarDesc, 1, 1);
    DescRest := Copy(AVarDesc, 3, MaxInt);
    TabPos := Pos(#9, DescRest);
    DescName := Copy(DescRest, 1, TabPos - 1);
    DescType := Copy(DescRest, TabPos + 1, MaxInt);
    if DescType = 'STRING' then
      Result := DescName
    else
      Result := 'STR$(' + DescName + ')';
    Result := Pfx('RqDbgVal("') + DescKind + '", "' + DescName + '", "' +
              DescType + '", ' + Result + ')';
  end;

  // Тип имени в области: сначала ALocal (может быть nil), потом глобальные.
  // AFound - имя известно.
  function NameType(const AName: string; ALocal: TStrings;
                    var AFound: Boolean): string;
  begin
    AFound := True;
    if (ALocal <> nil) and (ALocal.IndexOfName(AName) >= 0) then
      Result := ALocal.Values[AName]
    else if GlobalAll.IndexOfName(AName) >= 0 then
      Result := GlobalAll.Values[AName]
    else
    begin
      AFound := False;
      Result := '';
    end;
  end;

  // Выражение вычисляется в области: все его имена известны; в SUB
  // (ALocal <> nil) - хотя бы одно из них её параметр или локальная
  function WatchFits(AIdx: Integer; ALocal: TStrings): Boolean;
  var
    FitIdx: Integer;
    AnyLocal: Boolean;
  begin
    Result := False;
    if WatchNames[AIdx] = nil then
      Exit;
    AnyLocal := False;
    for FitIdx := 0 to WatchNames[AIdx].Count - 1 do
      if (ALocal <> nil) and
         (ALocal.IndexOfName(WatchNames[AIdx][FitIdx]) >= 0) then
        AnyLocal := True
      else if GlobalAll.IndexOfName(WatchNames[AIdx][FitIdx]) < 0 then
        Exit;
    Result := (ALocal = nil) or AnyLocal;
  end;

  // Строки вычисления выражения AIdx в области ALocal. Пусто - вычислять
  // не нужно или нельзя (простое имя - его покажет дамп, массив целиком,
  // объект).
  procedure WatchCode(AIdx: Integer; ALocal: TStrings; ALines: TStrings);
  var
    ExprText, SimpleName, SimpleType, ElemType, IdxText: string;
    HasArgs, Known, IsArray: Boolean;
  begin
    ALines.Clear;
    ExprText := FWatchExprs[AIdx];
    IdxText := IntToStr(AIdx);
    if SimpleExpr(ExprText, SimpleName, HasArgs) then
    begin
      SimpleType := NameType(SimpleName, ALocal, Known);
      // SUB значения не имеет; FUNCTION - вызов, через VARIANT
      if SimpleType = 'SUB' then
        Exit;
      if SimpleType = 'FUNCTION' then
        SimpleType := 'VARIANT';
      IsArray := Copy(SimpleType, Length(SimpleType) - 1, 2) = '[]';
      ElemType := SimpleType;
      if IsArray then
        ElemType := Copy(SimpleType, 1, Length(SimpleType) - 2);
      if not HasArgs then
      begin
        // Имя целиком: простой тип покажет дамп; массив и объект - нечего
        if IsArray or (ShowableType(ElemType) <> '') or
           ((ElemType <> '') and (ElemType <> 'VARIANT')) then
          Exit;
      end
      else if IsArray and (ElemType <> '') and (ElemType <> 'VARIANT') and
              (ShowableType(ElemType) = '') then
        Exit   // элемент - объект
      else if IsArray and (ShowableType(ElemType) <> '') then
      begin
        // Элемент массива известного типа
        if ElemType = 'STRING' then
          ALines.Add(Pfx('RqDbgVal("w", "') + IdxText + '", "STRING", ' +
                     ExprText + ')')
        else
          ALines.Add(Pfx('RqDbgVal("w", "') + IdxText + '", "' + ElemType +
                     '", STR$(' + ExprText + '))');
        Exit;
      end;
    end;
    // Остальное - через VARIANT
    ALines.Add(Pfx('RqDbgWV = ') + ExprText);
    ALines.Add(Pfx('RqDbgWT = RqDbgWS + RqDbgWV'));
    ALines.Add(Pfx('RqDbgVal("w", "') + IdxText + Pfx('", "", RqDbgWT)'));
  end;

  // Начало SUB/FUNCTION: номер процедуры, параметры, метка блока дампа
  procedure StartProc(const AHead: string);
  var
    HeadWord, HeadRest, ProcName: string;
    NameEnd: Integer;
  begin
    HeadWord := FirstToken(AHead, HeadRest);
    NameEnd := 1;
    while (NameEnd <= Length(HeadRest)) and
          (HeadRest[NameEnd] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '$', '%',
                                 '&', '!', '#', '?']) do
      Inc(NameEnd);
    ProcName := Copy(HeadRest, 1, NameEnd - 1);
    FProcNames.Add(HeadWord + ' ' + ProcName);
    FCurProc := FProcNames.Count - 1;
    ProcVars.Clear;
    CollectVars(HeaderParams(AHead), 'p', '', ProcVars);
    ProcAll.Clear;
    CollectNames(HeaderParams(AHead), ProcAll);
    CurDump := (HeadWord = 'SUB') or (HeadWord = 'FUNCTION');
    if HeadWord = 'FUNCTION' then
      CurExit := 'EXIT FUNCTION'
    else
      CurExit := 'EXIT SUB';
    CurVarsLabel := 'RqDbgVars' + IntToStr(FCurProc);
  end;

  // Перед END SUB: глубина, выход и блок дампа локальных
  procedure EndProc(const AIndent: string; ALine: Integer);
  var
    DumpIdx, CodeIdx, NameAdd: Integer;
  begin
    // Имена этой SUB - в общий список: для пояснения "имя не найдено"
    for NameAdd := 0 to ProcAll.Count - 1 do
      if LocalAll.IndexOf(ProcAll.Names[NameAdd]) < 0 then
        LocalAll.Add(ProcAll.Names[NameAdd]);
    if InSub then
      AddGen(AIndent + '  RqDbgDepth = RqDbgLvl - 1', ALine);
    if InSub and CurDump then
    begin
      AddGen(AIndent + '  ' + CurExit, ALine);
      AddGen(AIndent + CurVarsLabel + ':', ALine);
      for DumpIdx := 0 to ProcVars.Count - 1 do
        AddBody(AIndent + '  ' + ValLine(ProcVars[DumpIdx]), ALine);
      // Выражения Watch, имена которых есть в этой SUB
      for DumpIdx := 0 to FWatchExprs.Count - 1 do
        if WatchFits(DumpIdx, ProcAll) then
        begin
          WatchCode(DumpIdx, ProcAll, WatchLines);
          if WatchLines.Count = 0 then
            Continue;
          for CodeIdx := 0 to WatchLines.Count - 1 do
            AddBodyW(AIndent + '  ' + WatchLines[CodeIdx], ALine, DumpIdx);
          if FWatchWhere[DumpIdx] <> '' then
            FWatchWhere[DumpIdx] := FWatchWhere[DumpIdx] + ', ';
          FWatchWhere[DumpIdx] := FWatchWhere[DumpIdx] +
                                  FProcNames[FCurProc];
        end;
      AddGen(AIndent + '  RqDbgHalt', ALine);
      AddGen(AIndent + '  RETURN', ALine);
    end;
    FCurProc := -1;
    CurDump := False;
  end;

  // Проверка перед оператором. В SUB с блоком дампа - блочный IF с GOSUB
  // на блок, иначе - RqDbg останавливается сам.
  procedure AddCheck(const AIndent, ALabel: string; APoint, ALine: Integer);
  var
    LabelText, KeyText: string;
  begin
    LabelText := '';
    if ALabel <> '' then
      LabelText := ALabel + ' ';
    KeyText := IntToStr(ALine + 1);
    if InSub and CurDump then
    begin
      AddGen(AIndent + LabelText + 'IF RqDbgBrk(' + IntToStr(APoint) + ') THEN',
             ALine);
      AddGen(AIndent + '  RqDbg(' + IntToStr(APoint) + ', RqDbgLvl, ' + KeyText +
             ', 0)', ALine);
      AddGen(AIndent + '  IF RqDbgWant THEN GOSUB ' + CurVarsLabel, ALine);
      AddGen(AIndent + 'END IF', ALine);
    end
    else if InSub then
      AddGen(AIndent + LabelText + 'IF RqDbgBrk(' + IntToStr(APoint) +
             ') THEN RqDbg(' + IntToStr(APoint) + ', RqDbgLvl, ' + KeyText +
             ', 1)', ALine)
    else
      AddGen(AIndent + LabelText + 'IF RqDbgBrk(' + IntToStr(APoint) +
             ') THEN RqDbg(' + IntToStr(APoint) + ', 0, ' + KeyText + ', 1)',
             ALine);
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
  GlobalVars := TStringList.Create;
  ProcVars := TStringList.Create;
  GlobalAll := TStringList.Create;
  ProcAll := TStringList.Create;
  LocalAll := TStringList.Create;
  WatchLines := TStringList.Create;
  FWatchExprs.Clear;
  FWatchWhere.Clear;
  FWatchNote.Clear;
  SetLength(FCopyWatch, 0);
  if AWatch <> nil then
    for WatchIdx := 0 to AWatch.Count - 1 do
      if (Trim(AWatch[WatchIdx]) <> '') and
         (FWatchExprs.IndexOf(Trim(AWatch[WatchIdx])) < 0) then
        FWatchExprs.Add(Trim(AWatch[WatchIdx]));
  SetLength(WatchNames, FWatchExprs.Count);
  for WatchIdx := 0 to FWatchExprs.Count - 1 do
  begin
    FWatchWhere.Add('');
    FWatchNote.Add('');
    WatchNames[WatchIdx] := TStringList.Create;
    if not ExprNames(FWatchExprs[WatchIdx], WatchNames[WatchIdx]) then
    begin
      FreeAndNil(WatchNames[WatchIdx]);
      FWatchNote[WatchIdx] := 'в выражении ":" или комментарий - в код ' +
                              'не вставляется';
    end;
  end;
  CondDepth := 0;
  FProcNames.Clear;
  FCurProc := -1;
  SetLength(FPointProc, 0);
  CurDump := False;
  CurExit := '';
  CurVarsLabel := '';
  try
    // Из RAPIDQ.INC: $define brem $ifdef, erem $endif, remb, reme
    Aliases.Values['BREM'] := 'IFDEF';
    Aliases.Values['EREM'] := 'ENDIF';
    Aliases.Values['REMB'] := 'IFDEF';
    Aliases.Values['REME'] := 'ENDIF';
    // Главный файл и вставляемые $INCLUDE - общим текстом
    FFiles.Clear;
    FFiles.Add(ExpandFileName(ASrcFile));
    SetLength(FFileMerged, 1);
    SetLength(FMergedFile, 0);
    SetLength(FMergedLine, 0);
    MainDir := ExtractFilePath(ExpandFileName(ASrcFile));
    if not LoadMerged(ASrcFile, 0, 0) then
      Exit;
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
        // Продолжение - только в том же файле
        if (LineCode <> '') and (LineCode[Length(LineCode)] = '_') and
           (LineIdx < Src.Count - 1) and
           (FMergedFile[LineIdx + 1] = FMergedFile[LineIdx]) then
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

    // Предварительный проход: все глобальные имена общего текста (для
    // выражений Watch в SUB нужны и глобальные, объявленные ниже SUB):
    // DIM, CONST, DEFxxx вне SUB, имена CREATE, SUB и FUNCTION
    PreInSub := False;
    PreCreate := 0;
    PreSkip := '';
    for LogIdx := 0 to LogicalCount - 1 do
    begin
      Code := Trim(LogicalCode[LogIdx]);
      if (Code = '') or (Code[1] in ['$', '#']) then
        Continue;
      SplitStatements(Code, LogicalEsc[LogIdx], Parts, ColonAfterFirst);
      for PartIdx := 0 to Parts.Count - 1 do
      begin
        Stmt := Parts[PartIdx];
        Word1 := WordAt(Stmt, 1);
        VarRest := Trim(Copy(Stmt, Length(Word1) + 1, MaxInt));
        if PreSkip <> '' then
        begin
          if (Word1 = 'END') and (WordAt(Stmt, 2) = PreSkip) then
            PreSkip := '';
          Continue;
        end;
        if Word1 = 'CREATE' then
        begin
          Inc(PreCreate);
          CollectNames(VarRest, GlobalAll);   // "Имя AS QFORM" - объект
        end
        else if (Word1 = 'END') and (WordAt(Stmt, 2) = 'CREATE') then
        begin
          if PreCreate > 0 then
            Dec(PreCreate);
        end
        else if PreCreate > 0 then
          // присваивания свойств внутри CREATE
        else if IsSkipBlockWord(Word1) then
          PreSkip := Word1
        else if Word1 = 'DECLARE' then
        begin
          // Тип - SUB или FUNCTION: у SUB значения нет, FUNCTION - вызов
          if (WordAt(VarRest, 1) = 'FUNCTION') or
             (WordAt(VarRest, 1) = 'FUNCTIONI') then
            CollectNames(WordAt(VarRest, 2) + ' AS FUNCTION', GlobalAll)
          else
            CollectNames(WordAt(VarRest, 2) + ' AS SUB', GlobalAll);
        end
        else if PartKind(Stmt) = pkSubHead then
        begin
          if (Word1 = 'FUNCTION') or (Word1 = 'FUNCTIONI') then
            CollectNames(WordAt(VarRest, 1) + ' AS FUNCTION', GlobalAll)
          else
            CollectNames(WordAt(VarRest, 1) + ' AS SUB', GlobalAll);
          PreInSub := True;
        end
        else if PartKind(Stmt) = pkSubEnd then
          PreInSub := False
        else if not PreInSub and ((Word1 = 'DIM') or (Word1 = 'CONST') or
                                  (DefWordType(Word1) <> '')) then
          CollectNames(VarRest, GlobalAll);
      end;
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

      // Объявления - в списки дампа: DIM и DEFxxx в SUB - локальные, вне
      // SUB - глобальные
      for PartIdx := 0 to Parts.Count - 1 do
      begin
        Stmt := Parts[PartIdx];
        Word1 := WordAt(Stmt, 1);
        VarRest := Trim(Copy(Stmt, Length(Word1) + 1, MaxInt));
        if Word1 = 'DIM' then
        begin
          if InSub then
          begin
            CollectVars(VarRest, 'l', '', ProcVars);
            CollectNames(VarRest, ProcAll);
          end
          else
            CollectVars(VarRest, 'g', '', GlobalVars);
        end
        else if DefWordType(Word1) <> '' then
        begin
          if InSub then
          begin
            CollectVars(VarRest, 'l', DefWordType(Word1), ProcVars);
            CollectNames(VarRest, ProcAll);
          end
          else
            CollectVars(VarRest, 'g', DefWordType(Word1), GlobalVars);
        end
        else if (Word1 = 'CONST') and InSub then
          CollectNames(VarRest, ProcAll);
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
        if MultiEnd then
          EndProc(Indent, StartLine);
        if (MultiPoint >= 0) and not MultiHead then
        begin
          PointId := NewPoint(StartLine);
          AddCheck(Indent, '', PointId, StartLine);
          if (Kinds[MultiPoint] = pkExitSub) and InSub then
            AddGen(Indent + 'RqDbgDepth = RqDbgLvl - 1', StartLine);
        end;
        Verbatim(LogIdx);
        if MultiHead then
        begin
          for PartIdx := 0 to Parts.Count - 1 do
            if Kinds[PartIdx] = pkSubHead then
            begin
              StartProc(Parts[PartIdx]);
              Break;
            end;
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
              StartProc(Stmt);
              AddGen(Indent + '  DIM RqDbgLvl AS LONG', StartLine);
              AddGen(Indent + '  RqDbgDepth = RqDbgDepth + 1', StartLine);
              AddGen(Indent + '  RqDbgLvl = RqDbgDepth', StartLine);
              InSub := True;
            end;
          pkSubEnd:
            begin
              EndProc(Indent, StartLine);
              AddBody(Indent + Stmt, StartLine);
              InSub := False;
            end;
          pkPoint, pkExitSub:
            begin
              NumLabel := '';
              if PartIdx = 0 then
                TakeNumericLabel(Stmt, NumLabel);
              PointId := NewPoint(StartLine);
              AddCheck(Indent, NumLabel, PointId, StartLine);
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
      AddCopyLine(OutLines, Body[LineIdx], BodySrc[LineIdx],
                  BodyWatch[LineIdx]);
    AddRuntime(OutLines);
    for LineIdx := LeadLines to Body.Count - 1 do
      AddCopyLine(OutLines, Body[LineIdx], BodySrc[LineIdx],
                  BodyWatch[LineIdx]);
    // Глобальные - в конце, после всех их DIM
    AddCopyLine(OutLines, '', -1);
    AddCopyLine(OutLines, Pfx(''' --- unIDE: глобальные переменные для ' +
                'отладчика ---'), -1);
    AddCopyLine(OutLines, Pfx('SUB RqDbgGlobals'), -1);
    for VarIdx := 0 to GlobalVars.Count - 1 do
      AddCopyLine(OutLines, '  ' + ValLine(GlobalVars[VarIdx]), -1);
    // Выражения Watch только из глобальных имён - здесь (они видны на любой
    // остановке)
    for WatchIdx := 0 to FWatchExprs.Count - 1 do
      if (FWatchWhere[WatchIdx] = '') and WatchFits(WatchIdx, nil) then
      begin
        WatchCode(WatchIdx, nil, WatchLines);
        for LineIdx := 0 to WatchLines.Count - 1 do
          AddCopyLine(OutLines, '  ' + WatchLines[LineIdx], -1, WatchIdx);
        if WatchLines.Count > 0 then
          FWatchWhere[WatchIdx] := '*';
      end;
    AddCopyLine(OutLines, Pfx('END SUB'), -1);

    // Почему выражение не вычисляется нигде
    for WatchIdx := 0 to FWatchExprs.Count - 1 do
    begin
      if (FWatchWhere[WatchIdx] <> '') or (FWatchNote[WatchIdx] <> '') or
         (WatchNames[WatchIdx] = nil) then
        Continue;
      NoteText := '';
      for NameIdx := 0 to WatchNames[WatchIdx].Count - 1 do
        if (GlobalAll.IndexOfName(WatchNames[WatchIdx][NameIdx]) < 0) and
           (LocalAll.IndexOf(WatchNames[WatchIdx][NameIdx]) < 0) then
        begin
          if NoteText <> '' then
            NoteText := NoteText + ', ';
          NoteText := NoteText + WatchNames[WatchIdx][NameIdx];
        end;
      if NoteText <> '' then
        FWatchNote[WatchIdx] := 'не найдено: ' + NoteText + ' (нужно ' +
          'объявление DIM/CREATE в главном файле или в $INCLUDE-файле под ' +
          'отладкой; переменные без DIM не видны)'
      else
        FWatchNote[WatchIdx] := 'имена из разных SUB или простое имя, ' +
          'массив целиком, объект - не вычисляется';
    end;

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
    for WatchIdx := 0 to High(WatchNames) do
      WatchNames[WatchIdx].Free;
    WatchLines.Free;
    LocalAll.Free;
    ProcAll.Free;
    GlobalAll.Free;
    ProcVars.Free;
    GlobalVars.Free;
    Aliases.Free;
    Defined.Free;
    OutLines.Free;
    Parts.Free;
    Body.Free;
    Src.Free;
  end;
end;

function TRqDbgInstr.FileCount: Integer;
begin
  Result := FFiles.Count;
end;

function TRqDbgInstr.FileName(AFileIdx: Integer): string;
begin
  Result := '';
  if (AFileIdx >= 0) and (AFileIdx < FFiles.Count) then
    Result := FFiles[AFileIdx];
end;

function TRqDbgInstr.FileIndex(const AFile: string): Integer;
var
  FileIdx: Integer;
begin
  Result := -1;
  if AFile = '' then
    Exit;
  for FileIdx := 0 to FFiles.Count - 1 do
    if CompareText(FFiles[FileIdx], ExpandFileName(AFile)) = 0 then
    begin
      Result := FileIdx;
      Exit;
    end;
end;

function TRqDbgInstr.PointOfLine(AFileIdx, ALine: Integer): Integer;
var
  MergedIdx: Integer;
begin
  Result := 0;
  if (AFileIdx < 0) or (AFileIdx >= Length(FFileMerged)) or (ALine < 0) or
     (ALine >= Length(FFileMerged[AFileIdx])) then
    Exit;
  MergedIdx := FFileMerged[AFileIdx][ALine];
  if (MergedIdx >= 0) and (MergedIdx < Length(FLinePoint)) then
    Result := FLinePoint[MergedIdx];
end;

function TRqDbgInstr.LineOfPoint(APoint: Integer): Integer;
begin
  Result := -1;
  if (APoint >= 1) and (APoint <= FPointCount) and (FPointLine[APoint] >= 0) then
    Result := FMergedLine[FPointLine[APoint]];
end;

function TRqDbgInstr.FileOfPoint(APoint: Integer): Integer;
begin
  Result := -1;
  if (APoint >= 1) and (APoint <= FPointCount) and (FPointLine[APoint] >= 0) then
    Result := FMergedFile[FPointLine[APoint]];
end;

function TRqDbgInstr.SrcLineOfCopy(ACopyLine: Integer): Integer;
begin
  Result := -1;
  if (ACopyLine >= 0) and (ACopyLine < FCopyCount) and
     (FCopySrc[ACopyLine] >= 0) then
    Result := FMergedLine[FCopySrc[ACopyLine]];
end;

function TRqDbgInstr.SrcFileOfCopy(ACopyLine: Integer): Integer;
begin
  Result := 0;
  if (ACopyLine >= 0) and (ACopyLine < FCopyCount) and
     (FCopySrc[ACopyLine] >= 0) then
    Result := FMergedFile[FCopySrc[ACopyLine]];
end;

end.
