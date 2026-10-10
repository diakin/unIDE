unit RqDeclFind;

// Поиск объявления идентификатора в исходниках RapidQ Basic - для панели
// объявления над редактором (Unit1, DeclPanelUpdateRq). Без VCL.
//
// Текст разбирается построчно: комментарии (' и REM), строки "..." и
// блоки brem ... erem - пробелами; операторы в строке - через ':'.
// Объявлениями считаются:
//   DIM, CONST, CREATE, DEFINT/DEFSTR/... (списки через запятую);
//   SUB, FUNCTION, SUBI, FUNCTIONI (в том числе Тип.Метод), DECLARE;
//   TYPE Имя (и члены внутри TYPE ... END TYPE: поля "Имя AS ...", DIM,
//   CREATE, методы SUB/FUNCTION/EVENT/PROPERTY SET);
//   $DEFINE / #define, $RESOURCE, метки "Имя:" в начале строки;
//   параметры и DIM внутри процедуры - локальные, видны только в ней.
// Суффикс типа ($ % & ! # ?) у имён отбрасывается: a$ и a - одно имя.

interface

uses
  SysUtils, Classes;

type
  TRqDeclKind = (rdkLocal, rdkGlobal, rdkMember);

  TRqDeclItem = record
    Name: string;       // в верхнем регистре, без суффикса; Тип.Метод - целиком
    ShortName: string;  // часть после последней точки (без точки - как Name)
    Kind: TRqDeclKind;
    Line: Integer;      // строка объявления, от нуля
    Col: Integer;       // позиция имени в строке, с 1
    Owner: string;      // у члена - TYPE, в верхнем регистре
    ScopeFirst: Integer; // у локального - строки процедуры, от нуля
    ScopeLast: Integer;
  end;

  // Блок TYPE ... END TYPE: строки от нуля
  TRqTypeRange = record
    Name: string;
    FirstLine: Integer;
    LastLine: Integer;
  end;

  TRqDeclIndex = class
  private
    FItems: array of TRqDeclItem;
    FCount: Integer;
    FTypes: array of TRqTypeRange;
    FTypeCount: Integer;
    FAge: Integer;      // дата файла (TRqDeclCache)
    procedure AddItem(const AName: string; AKind: TRqDeclKind;
                      ALine, ACol: Integer; const AOwner: string;
                      AScopeFirst: Integer);
    procedure AddType(const AName: string; ALine: Integer);
  public
    procedure Build(ALines: TStrings);
    // Объявление AWord (в верхнем регистре, без суффикса) вида AKind;
    // для rdkLocal - видимое на строке ALine; для rdkMember - у типа
    // AOwner ('' - у любого). -1 - нет.
    function Find(const AWord: string; AKind: TRqDeclKind; ALine: Integer;
                  const AOwner: string): Integer;
    // TYPE, внутри которого строка ALine; '' - вне TYPE
    function TypeAt(ALine: Integer): string;
    function Item(AIndex: Integer): TRqDeclItem;
    property Count: Integer read FCount;
  end;

  // Разобранные файлы с диска: заново, когда сменилась дата файла
  TRqDeclCache = class
  private
    FFiles: TStringList;   // путь в верхнем регистре -> TRqDeclIndex
  public
    constructor Create;
    destructor Destroy; override;
    // Разбор файла AFile с диска; nil - не прочитался
    function IndexOfFile(const AFile: string): TRqDeclIndex;
    procedure Clear;
  end;

// Имя без суффикса типа, в верхнем регистре
function RqDeclStrip(const AName: string): string;
// Слово RapidQ (оператор, ключевое слово) - объявления у него не ищется
function RqDeclIsKeyword(const AWordUp: string): Boolean;
// Очищенная строка: комментарии и содержимое строк - пробелами, длина та
// же. AInBrem - внутри блока brem ... erem (меняется по строкам).
function RqDeclCleanLine(const ALine: string; var AInBrem: Boolean): string;
// Символы имени RapidQ
function RqDeclIdStart(ACh: Char): Boolean;
function RqDeclIdChar(ACh: Char): Boolean;
function RqDeclSuffix(ACh: Char): Boolean;

implementation

const
  SuffixChars = ['$', '%', '&', '!', '#', '?'];

function RqDeclIdStart(ACh: Char): Boolean;
begin
  Result := ACh in ['A'..'Z', 'a'..'z', '_'];
end;

function RqDeclIdChar(ACh: Char): Boolean;
begin
  Result := ACh in ['A'..'Z', 'a'..'z', '_', '0'..'9'];
end;

function RqDeclSuffix(ACh: Char): Boolean;
begin
  Result := ACh in SuffixChars;
end;

function RqDeclStrip(const AName: string): string;
begin
  Result := UpperCase(Trim(AName));
  while (Result <> '') and (Result[Length(Result)] in SuffixChars) do
    SetLength(Result, Length(Result) - 1);
end;

function RqDeclIsKeyword(const AWordUp: string): Boolean;
const
  Words: array[0..83] of string = (
    'AND', 'AS', 'BYREF', 'BYVAL', 'CASE', 'CONST', 'CONSTRUCTOR', 'CREATE',
    'DECLARE', 'DEFBYTE', 'DEFDBL', 'DEFDWORD', 'DEFINT', 'DEFLNG',
    'DEFSHORT', 'DEFSNG', 'DEFSTR', 'DEFWORD', 'DIM', 'DO', 'DOUBLE', 'DWORD',
    'ELSE', 'ELSEIF', 'END', 'EVENT', 'EXIT', 'EXTENDS', 'FOR', 'FUNCTION',
    'FUNCTIONI', 'GOSUB', 'GOTO', 'IF', 'IN', 'INC', 'DEC', 'INTEGER', 'IS',
    'LIB', 'ALIAS', 'LONG', 'LOOP', 'MOD', 'NEXT', 'NOT', 'OR', 'PRINT',
    'PRIVATE', 'PROPERTY', 'PUBLIC', 'REDIM', 'RESULT', 'RETURN', 'SELECT',
    'SET', 'SHARED', 'SHL', 'SHR', 'SHORT', 'SINGLE', 'STEP', 'STRING',
    'SUB', 'SUBI', 'THEN', 'THIS', 'TO', 'TYPE', 'UNTIL', 'VARIANT', 'WEND',
    'WHILE', 'WITH', 'XOR', 'BYTE', 'WORD', 'INV', 'SWAP', 'BIND', 'CALLFUNC',
    'CODEPTR', 'VARPTR', 'SIZEOF');
var
  WordIdx: Integer;
begin
  Result := True;
  for WordIdx := Low(Words) to High(Words) do
    if Words[WordIdx] = AWordUp then
      Exit;
  Result := False;
end;

// Первое слово очищенной строки (верхний регистр)
function FirstWord(const AClean: string): string;
var
  Pos1, Pos2: Integer;
begin
  Pos1 := 1;
  while (Pos1 <= Length(AClean)) and (AClean[Pos1] in [' ', #9]) do
    Inc(Pos1);
  Pos2 := Pos1;
  while (Pos2 <= Length(AClean)) and
        (RqDeclIdChar(AClean[Pos2]) or (AClean[Pos2] in ['$', '#'])) do
    Inc(Pos2);
  Result := UpperCase(Copy(AClean, Pos1, Pos2 - Pos1));
end;

function RqDeclCleanLine(const ALine: string; var AInBrem: Boolean): string;
var
  Pos1, WordStart: Integer;
  InStr: Boolean;
  Head: string;
begin
  Result := ALine;
  UniqueString(Result);
  Head := FirstWord(ALine);
  if AInBrem then
  begin
    if Head = 'EREM' then
      AInBrem := False;
    Result := StringOfChar(' ', Length(ALine));
    Exit;
  end;
  if Head = 'BREM' then
  begin
    AInBrem := True;
    Result := StringOfChar(' ', Length(ALine));
    Exit;
  end;
  InStr := False;
  Pos1 := 1;
  while Pos1 <= Length(Result) do
  begin
    if InStr then
    begin
      if Result[Pos1] = '"' then
        InStr := False
      else
        Result[Pos1] := ' ';
      Inc(Pos1);
      Continue;
    end;
    if Result[Pos1] = '"' then
    begin
      InStr := True;
      Inc(Pos1);
      Continue;
    end;
    if Result[Pos1] = '''' then
    begin
      FillChar(Result[Pos1], Length(Result) - Pos1 + 1, ' ');
      Exit;
    end;
    if RqDeclIdStart(Result[Pos1]) then
    begin
      WordStart := Pos1;
      while (Pos1 <= Length(Result)) and RqDeclIdChar(Result[Pos1]) do
        Inc(Pos1);
      // REM - комментарий до конца строки (в начале оператора)
      if (Pos1 - WordStart = 3) and
         (UpperCase(Copy(Result, WordStart, 3)) = 'REM') then
      begin
        Head := TrimRight(Copy(Result, 1, WordStart - 1));
        if (Head = '') or (Head[Length(Head)] = ':') then
        begin
          FillChar(Result[WordStart], Length(Result) - WordStart + 1, ' ');
          Exit;
        end;
      end;
      Continue;
    end;
    Inc(Pos1);
  end;
end;

// --- лексемы оператора ---

type
  TRqTok = record
    Text: string;   // верхний регистр; имя - с точками и суффиксом
    Col: Integer;   // с 1, в строке
    IsName: Boolean;
  end;
  TRqToks = array of TRqTok;

// Лексемы части строки AClean от AFrom до ATo
procedure Tokenize(const AClean: string; AFrom, ATo: Integer;
                   var AToks: TRqToks; var ACount: Integer);
var
  Pos1, Start: Integer;

  procedure Push(AStart, AEnd: Integer; AName: Boolean);
  begin
    if ACount >= Length(AToks) then
      SetLength(AToks, ACount * 2 + 8);
    AToks[ACount].Text := UpperCase(Copy(AClean, AStart, AEnd - AStart + 1));
    AToks[ACount].Col := AStart;
    AToks[ACount].IsName := AName;
    Inc(ACount);
  end;

begin
  ACount := 0;
  Pos1 := AFrom;
  while Pos1 <= ATo do
  begin
    if AClean[Pos1] in [' ', #9] then
    begin
      Inc(Pos1);
      Continue;
    end;
    Start := Pos1;
    if RqDeclIdStart(AClean[Pos1]) or
       ((AClean[Pos1] in ['$', '#']) and (Pos1 < ATo) and
        RqDeclIdStart(AClean[Pos1 + 1])) then
    begin
      Inc(Pos1);
      while (Pos1 <= ATo) and
            (RqDeclIdChar(AClean[Pos1]) or
             ((AClean[Pos1] = '.') and (Pos1 < ATo) and
              RqDeclIdStart(AClean[Pos1 + 1]))) do
        Inc(Pos1);
      while (Pos1 <= ATo) and (AClean[Pos1] in SuffixChars) do
        Inc(Pos1);
      Push(Start, Pos1 - 1, AClean[Start] in ['A'..'Z', 'a'..'z', '_']);
      Continue;
    end;
    if AClean[Pos1] in ['0'..'9', '.'] then
    begin
      while (Pos1 <= ATo) and
            (AClean[Pos1] in ['0'..'9', '.', 'A'..'F', 'a'..'f', 'x', 'X']) do
        Inc(Pos1);
      Push(Start, Pos1 - 1, False);
      Continue;
    end;
    Push(Pos1, Pos1, False);
    Inc(Pos1);
  end;
end;

{ TRqDeclIndex }

procedure TRqDeclIndex.AddItem(const AName: string; AKind: TRqDeclKind;
                               ALine, ACol: Integer; const AOwner: string;
                               AScopeFirst: Integer);
var
  DotPos: Integer;
  NameUp: string;
begin
  NameUp := RqDeclStrip(AName);
  if (NameUp = '') or RqDeclIsKeyword(NameUp) then
    Exit;
  if FCount >= Length(FItems) then
    SetLength(FItems, FCount * 2 + 64);
  FItems[FCount].Name := NameUp;
  DotPos := LastDelimiter('.', NameUp);
  if DotPos > 0 then
    FItems[FCount].ShortName := Copy(NameUp, DotPos + 1, MaxInt)
  else
    FItems[FCount].ShortName := NameUp;
  FItems[FCount].Kind := AKind;
  FItems[FCount].Line := ALine;
  FItems[FCount].Col := ACol;
  FItems[FCount].Owner := AOwner;
  FItems[FCount].ScopeFirst := AScopeFirst;
  FItems[FCount].ScopeLast := MaxInt;
  Inc(FCount);
end;

procedure TRqDeclIndex.AddType(const AName: string; ALine: Integer);
begin
  if FTypeCount >= Length(FTypes) then
    SetLength(FTypes, FTypeCount * 2 + 16);
  FTypes[FTypeCount].Name := RqDeclStrip(AName);
  FTypes[FTypeCount].FirstLine := ALine;
  FTypes[FTypeCount].LastLine := MaxInt;
  Inc(FTypeCount);
end;

function TRqDeclIndex.Item(AIndex: Integer): TRqDeclItem;
begin
  Result := FItems[AIndex];
end;

function TRqDeclIndex.TypeAt(ALine: Integer): string;
var
  TypeIdx: Integer;
begin
  Result := '';
  for TypeIdx := 0 to FTypeCount - 1 do
    if (ALine >= FTypes[TypeIdx].FirstLine) and
       (ALine <= FTypes[TypeIdx].LastLine) then
    begin
      Result := FTypes[TypeIdx].Name;
      Exit;
    end;
end;

function TRqDeclIndex.Find(const AWord: string; AKind: TRqDeclKind;
                           ALine: Integer; const AOwner: string): Integer;
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to FCount - 1 do
    with FItems[ItemIdx] do
    begin
      if Kind <> AKind then
        Continue;
      if (Name <> AWord) and (ShortName <> AWord) then
        Continue;
      if (AKind = rdkLocal) and ((ALine < ScopeFirst) or (ALine > ScopeLast)) then
        Continue;
      if (AKind = rdkMember) and (AOwner <> '') and (Owner <> AOwner) then
        Continue;
      Result := ItemIdx;
      Exit;
    end;
  Result := -1;
end;

procedure TRqDeclIndex.Build(ALines: TStrings);
var
  LineIdx, CurLine, StmtFrom, StmtTo, TokCount, FirstLocal, ProcLine: Integer;
  Clean, CurType: string;
  InBrem, InProc: Boolean;
  Toks: TRqToks;
  // Продолжение списка на следующей строке (строка кончается на " _"):
  // 0 - нет, 1 - список DIM/CONST/DEF*, 2 - параметры процедуры.
  // PendMode - что оставил последний оператор строки, ContMode - что
  // продолжается в текущей строке.
  PendMode, ContMode: Integer;
  PendKind, ContKind: TRqDeclKind;

  function Tok(AIdx: Integer): string;
  begin
    if (AIdx >= 0) and (AIdx < TokCount) then
      Result := Toks[AIdx].Text
    else
      Result := '';
  end;

  procedure Add(ATokIdx: Integer; AKind: TRqDeclKind);
  begin
    if (ATokIdx < 0) or (ATokIdx >= TokCount) or not Toks[ATokIdx].IsName then
      Exit;
    if AKind = rdkMember then
      AddItem(Toks[ATokIdx].Text, AKind, CurLine, Toks[ATokIdx].Col, CurType, 0)
    else if AKind = rdkLocal then
      AddItem(Toks[ATokIdx].Text, AKind, CurLine, Toks[ATokIdx].Col, '',
              ProcLine)
    else
      AddItem(Toks[ATokIdx].Text, AKind, CurLine, Toks[ATokIdx].Col, '', 0);
  end;

  // Список "имя [(...)] [AS тип] [= значение], ..." с лексемы AFrom.
  // ABase - глубина скобок списка: 0 у DIM, 1 у параметров процедуры;
  // скобка, закрывшая список, его кончает.
  procedure AddList(AFrom: Integer; AKind: TRqDeclKind; ABase: Integer);
  var
    TokIdx, Depth: Integer;
    WantName: Boolean;
    Text: string;
  begin
    WantName := True;
    Depth := ABase;
    TokIdx := AFrom;
    while TokIdx < TokCount do
    begin
      Text := Toks[TokIdx].Text;
      if Text = '(' then
        Inc(Depth)
      else if Text = ')' then
      begin
        Dec(Depth);
        if Depth < ABase then
          Exit;
      end
      else if (Depth = ABase) and (Text = ',') then
        WantName := True
      else if WantName and (Depth = ABase) and Toks[TokIdx].IsName and
              (Text <> 'SHARED') and (Text <> 'BYVAL') and (Text <> 'BYREF') then
      begin
        Add(TokIdx, AKind);
        WantName := False;
      end;
      Inc(TokIdx);
    end;
  end;

  // Параметры процедуры: "(BYVAL a AS LONG, b$, ...)" после лексемы AFrom
  procedure AddParams(AFrom: Integer);
  var
    TokIdx: Integer;
  begin
    PendMode := 0;
    TokIdx := AFrom;
    while (TokIdx < TokCount) and (Toks[TokIdx].Text <> '(') do
      Inc(TokIdx);
    if TokIdx >= TokCount then
      Exit;
    AddList(TokIdx + 1, rdkLocal, 1);
    PendMode := 2;
    PendKind := rdkLocal;
  end;

  procedure EndProc;
  var
    ItemIdx: Integer;
  begin
    for ItemIdx := FirstLocal to FCount - 1 do
      if FItems[ItemIdx].Kind = rdkLocal then
        FItems[ItemIdx].ScopeLast := CurLine;
    InProc := False;
  end;

  procedure BeginProc;
  begin
    InProc := True;
    ProcLine := CurLine;
    FirstLocal := FCount;
  end;

  function IsProcHead(const AWord: string): Boolean;
  begin
    Result := (AWord = 'SUB') or (AWord = 'FUNCTION') or (AWord = 'SUBI') or
              (AWord = 'FUNCTIONI');
  end;

  function IsDefList(const AWord: string): Boolean;
  begin
    Result := (AWord = 'DEFINT') or (AWord = 'DEFSTR') or (AWord = 'DEFSNG') or
              (AWord = 'DEFDBL') or (AWord = 'DEFBYTE') or (AWord = 'DEFWORD') or
              (AWord = 'DEFLNG') or (AWord = 'DEFSHORT') or (AWord = 'DEFDWORD');
  end;

  procedure Statement(AFirstInLine: Boolean; AColonAfter: Boolean);
  var
    Head: string;
    StartIdx, TokIdx: Integer;
    LocalKind: TRqDeclKind;
  begin
    PendMode := 0;
    if TokCount = 0 then
      Exit;
    Head := Tok(0);

    // Метка "Имя:" в начале строки
    if AFirstInLine and AColonAfter and (TokCount = 1) and Toks[0].IsName and
       not RqDeclIsKeyword(Head) and (CurType = '') then
    begin
      Add(0, rdkGlobal);
      Exit;
    end;

    // Директивы
    if (Head = '$DEFINE') or (Head = '#DEFINE') or (Head = '$RESOURCE') then
    begin
      Add(1, rdkGlobal);
      Exit;
    end;
    if Head[1] in ['$', '#'] then
      Exit;

    // Конец блоков
    if Head = 'END' then
    begin
      if (Tok(1) = 'TYPE') and (CurType <> '') then
      begin
        if FTypeCount > 0 then
          FTypes[FTypeCount - 1].LastLine := CurLine;
        CurType := '';
      end
      else if InProc and (IsProcHead(Tok(1)) or (Tok(1) = 'EVENT') or
              (Tok(1) = 'PROPERTY') or (Tok(1) = 'CONSTRUCTOR')) then
        EndProc;
      Exit;
    end;

    StartIdx := 0;
    if (Head = 'PUBLIC') or (Head = 'PRIVATE') then
      StartIdx := 1;
    Head := Tok(StartIdx);
    if InProc then
      LocalKind := rdkLocal
    else if CurType <> '' then
      LocalKind := rdkMember
    else
      LocalKind := rdkGlobal;

    if Head = 'DECLARE' then
    begin
      if IsProcHead(Tok(StartIdx + 1)) then
        Add(StartIdx + 2, rdkGlobal);
      Exit;
    end;

    if IsProcHead(Head) then
    begin
      if InProc then
        EndProc;   // END SUB пропущен - новая процедура закрывает прежнюю
      if CurType <> '' then
        Add(StartIdx + 1, rdkMember)
      else
        Add(StartIdx + 1, rdkGlobal);
      BeginProc;
      AddParams(StartIdx + 2);
      Exit;
    end;

    if (Head = 'EVENT') and (CurType <> '') and not InProc then
    begin
      BeginProc;
      AddParams(StartIdx + 1);
      Exit;
    end;

    if (Head = 'PROPERTY') and (Tok(StartIdx + 1) = 'SET') then
    begin
      if CurType <> '' then
        Add(StartIdx + 2, rdkMember);
      BeginProc;
      AddParams(StartIdx + 3);
      Exit;
    end;

    if (Head = 'CONSTRUCTOR') and (CurType <> '') then
    begin
      BeginProc;
      Exit;
    end;

    if Head = 'TYPE' then
    begin
      if (StartIdx + 1 >= TokCount) or not Toks[StartIdx + 1].IsName then
        Exit;
      Add(StartIdx + 1, rdkGlobal);
      CurType := '';
      AddType(Tok(StartIdx + 1), CurLine);
      CurType := FTypes[FTypeCount - 1].Name;
      Exit;
    end;

    if (Head = 'DIM') or (Head = 'CONST') or IsDefList(Head) then
    begin
      AddList(StartIdx + 1, LocalKind, 0);
      PendMode := 1;
      PendKind := LocalKind;
      Exit;
    end;

    if Head = 'CREATE' then
    begin
      Add(StartIdx + 1, LocalKind);
      Exit;
    end;

    // Поле записи или класса: "Имя AS тип", "Имя(10) AS тип"
    if (CurType <> '') and not InProc and Toks[StartIdx].IsName then
    begin
      TokIdx := StartIdx + 1;
      if Tok(TokIdx) = '(' then
      begin
        while (TokIdx < TokCount) and (Toks[TokIdx].Text <> ')') do
          Inc(TokIdx);
        Inc(TokIdx);
      end;
      if Tok(TokIdx) = 'AS' then
        Add(StartIdx, rdkMember);
    end;
  end;

var
  CharIdx, Depth, TailPos: Integer;
  FirstStmt, HasCont: Boolean;
begin
  FCount := 0;
  FTypeCount := 0;
  CurType := '';
  InBrem := False;
  InProc := False;
  ProcLine := 0;
  FirstLocal := 0;
  ContMode := 0;
  PendMode := 0;
  PendKind := rdkGlobal;
  ContKind := rdkGlobal;
  SetLength(Toks, 32);
  for LineIdx := 0 to ALines.Count - 1 do
  begin
    CurLine := LineIdx;
    Clean := RqDeclCleanLine(ALines[LineIdx], InBrem);
    // Перенос " _" в конце строки - пробелом, запоминается
    TailPos := Length(TrimRight(Clean));
    HasCont := (TailPos > 0) and (Clean[TailPos] = '_') and
               ((TailPos = 1) or (Clean[TailPos - 1] in [' ', #9, ',', '(']));
    if HasCont then
      Clean[TailPos] := ' ';
    if ContMode <> 0 then
    begin
      // Продолжение списка с прошлой строки
      Tokenize(Clean, 1, Length(Clean), Toks, TokCount);
      AddList(0, ContKind, ContMode - 1);
      if not HasCont then
        ContMode := 0;
      Continue;
    end;
    if Trim(Clean) = '' then
      Continue;
    // Операторы через ':' (вне скобок)
    StmtFrom := 1;
    FirstStmt := True;
    Depth := 0;
    for CharIdx := 1 to Length(Clean) + 1 do
    begin
      if CharIdx <= Length(Clean) then
      begin
        if Clean[CharIdx] = '(' then
          Inc(Depth)
        else if Clean[CharIdx] = ')' then
          Dec(Depth);
        if (Clean[CharIdx] <> ':') or (Depth > 0) then
          Continue;
      end;
      StmtTo := CharIdx - 1;
      Tokenize(Clean, StmtFrom, StmtTo, Toks, TokCount);
      Statement(FirstStmt, CharIdx <= Length(Clean));
      FirstStmt := False;
      StmtFrom := CharIdx + 1;
    end;
    if HasCont and (PendMode <> 0) then
    begin
      ContMode := PendMode;
      ContKind := PendKind;
    end;
  end;
  CurLine := ALines.Count - 1;
  if InProc then
    EndProc;
end;

{ TRqDeclCache }

constructor TRqDeclCache.Create;
begin
  inherited Create;
  FFiles := TStringList.Create;
  FFiles.Sorted := True;
end;

destructor TRqDeclCache.Destroy;
begin
  Clear;
  FFiles.Free;
  inherited Destroy;
end;

procedure TRqDeclCache.Clear;
var
  FileIdx: Integer;
begin
  for FileIdx := 0 to FFiles.Count - 1 do
    FFiles.Objects[FileIdx].Free;
  FFiles.Clear;
end;

function TRqDeclCache.IndexOfFile(const AFile: string): TRqDeclIndex;
var
  Key: string;
  FileIdx, Age: Integer;
  Lines: TStringList;
begin
  Result := nil;
  Key := UpperCase(AFile);
  Age := FileAge(AFile);
  if Age = -1 then
    Exit;
  FileIdx := FFiles.IndexOf(Key);
  if FileIdx >= 0 then
  begin
    Result := TRqDeclIndex(FFiles.Objects[FileIdx]);
    if Result.FAge = Age then
      Exit;
  end;
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFile);
    except
      Result := nil;
      Exit;
    end;
    if FileIdx < 0 then
    begin
      Result := TRqDeclIndex.Create;
      FFiles.AddObject(Key, Result);
    end;
    Result.Build(Lines);
    Result.FAge := Age;
  finally
    Lines.Free;
  end;
end;

end.
