unit IncEdit;

// Правка состава inc-файлов RapidQ для INC Manager (Unit3), без VCL:
//
//  - TIncDoc: файл, разобранный на единицы - процедуры (SUB / FUNCTION с
//    телом), DECLARE (свои и из DLL), TYPE (записи и компоненты TYPE ...
//    EXTENDS), CONST, $DEFINE, DIM / DEFxxx, CREATE и прочие строки.
//    Комментарии сразу над объявлением (без пустой строки) - его часть.
//  - IncExtract: отмеченные пункты (процедуры, функции DLL, компоненты) -
//    каждый в свой файл <имя>.inc рядом с исходным. С пунктом уходит то,
//    чем пользуется только он (CONST, TYPE, DECLARE, другие процедуры).
//    Новый файл подключает исходный ($INCLUDE), исходный - без
//    изъятого (прежний текст - в <файл>.bak).
//  - IncMerge: несколько файлов - в один; из одноимённых объявлений
//    остаётся первое, расхождения - в отчёт.
//
// Имена RapidQ сравниваются без учёта регистра и без суффикса типа
// ($ % & ! # ?). Пункт, которым пользуется что-то оставшееся в файле, не
// изымается: изъятие сломало бы исходный файл.

interface

uses
  SysUtils, Classes;

type
  TIncUnitKind = (iuOther, iuConst, iuDefine, iuDeclare, iuDllDeclare,
                  iuProc, iuType, iuComponent, iuDim, iuCreate);

  TIncUnit = class
  public
    Kind: TIncUnitKind;
    Name: string;          // как в тексте (у DIM / CONST - первое имя)
    First, Last: Integer;  // строки файла с нуля, с комментариями над ним
    Head: Integer;         // строка самого объявления
    Depth: Integer;        // вложенность $IFDEF (стражи $IFNDEF X / $DEFINE X
                           // не считаются: в общих файлах так обёрнут каждый
                           // исходный файл)
    Names: TStringList;    // объявленные имена: ключи NameKey
    Uses_: TStringList;    // имена, встречающиеся в коде единицы (ключи)
    Pair: TIncUnit;        // процедура <-> её DECLARE без LIB в том же файле
    Lib: string;           // у функции DLL - имя DLL
    HeadWord: string;      // первое слово объявления: SUB, FUNCTION, TYPE ...
    constructor Create;
    destructor Destroy; override;
    function Caption: string;
    function Offered: Boolean;   // пункт для списка (изымаемое)
  end;

  TIncDoc = class
  public
    FileName: string;
    Lines: TStringList;
    Units: TList;
    GuardName: string;     // страж файла ('' - нет)
    GuardOpen, GuardDefine, GuardClose: Integer;  // его строки, -1 - нет
    constructor Create;
    destructor Destroy; override;
    function LoadFromFile(const AFile: string): Boolean;
    procedure Parse;
    // Пункты для списка: процедуры (с DECLARE - одним пунктом), функции
    // DLL, компоненты - в порядке файла
    procedure OfferedItems(AList: TList);
    function UnitAtLine(ALine: Integer): TIncUnit;
  end;

// Ключ имени: верхний регистр, без суффикса типа
function IncNameKey(const AName: string): string;
// Код строки без комментария ' (вне кавычек) и без REM
function IncCodePart(const ALine: string): string;

// Изъять AItems (TIncUnit из ADoc) - каждый в свой файл рядом с ADoc.
// AReport - что сделано и что нет (по строке на пункт). AOverwrite -
// перезаписывать ли уже существующие файлы пунктов. Результат - сколько
// пунктов изъято.
function IncExtract(ADoc: TIncDoc; AItems: TList; AOverwrite: Boolean;
  AReport: TStrings; AExternal: TStringList = nil;
  AExternalFiles: TStrings = nil): Integer;

// Имена, которыми пользуются файлы из ACandidates, подключающие AIncFile
// (прямо или через другой файл из ACandidates): изъять их - сломать эти
// файлы. AUses - ключи имён (сортированный), Objects - номер файла в
// ACandidates. Результат - сколько таких файлов.
function IncExternalUses(const AIncFile: string; ACandidates: TStrings;
  AUses: TStringList): Integer;

// Файл пункта (куда IncExtract его положит)
function IncItemFileName(ADoc: TIncDoc; AItem: TIncUnit): string;

// Собрать AFiles (в этом порядке) в AOutFile. Из одноимённых объявлений
// разных файлов остаётся первое; разный текст - строкой в AReport.
// False - не вышло (AReport - почему).
function IncMerge(AFiles: TStrings; const AOutFile: string;
  AReport: TStrings): Boolean;

implementation

const
  NameChars = ['A'..'Z', 'a'..'z', '0'..'9', '_'];
  SuffixChars = ['$', '%', '&', '!', '#', '?'];

{ TIncUnit }

constructor TIncUnit.Create;
begin
  inherited Create;
  Names := TStringList.Create;
  Names.Sorted := True;
  Names.Duplicates := dupIgnore;
  Uses_ := TStringList.Create;
  Uses_.Sorted := True;
  Uses_.Duplicates := dupIgnore;
end;

destructor TIncUnit.Destroy;
begin
  Names.Free;
  Uses_.Free;
  inherited Destroy;
end;

function TIncUnit.Caption: string;
begin
  case Kind of
    iuProc:
      if Pos('FUNCTION', HeadWord) = 1 then
        Result := 'Fn   ' + Name
      else
        Result := 'Sub  ' + Name;
    iuDllDeclare:
      Result := 'DLL  ' + Name + '  (' + Lib + ')';
    iuComponent:
      Result := 'Comp ' + Name;
  else
    Result := Name;
  end;
end;

function TIncUnit.Offered: Boolean;
begin
  Result := (Depth = 0) and (Kind in [iuProc, iuDllDeclare, iuComponent]);
end;

{ разбор строк }

function IncCodePart(const ALine: string): string;
var
  CharIdx: Integer;
  InStr: Boolean;
begin
  Result := ALine;
  InStr := False;
  for CharIdx := 1 to Length(ALine) do
  begin
    if ALine[CharIdx] = '"' then
      InStr := not InStr
    else if (ALine[CharIdx] = '''') and not InStr then
    begin
      Result := Copy(ALine, 1, CharIdx - 1);
      Break;
    end;
  end;
  Result := Trim(Result);
  if (Length(Result) >= 3) and (UpperCase(Copy(Result, 1, 3)) = 'REM') and
     ((Length(Result) = 3) or not (Result[4] in NameChars)) then
    Result := '';
end;

function IncNameKey(const AName: string): string;
begin
  Result := UpperCase(Trim(AName));
  while (Result <> '') and (Result[Length(Result)] in SuffixChars) do
    Delete(Result, Length(Result), 1);
end;

// Первое слово строки кода (верхний регистр) и остаток после него
function FirstWord(const ACode: string; var ARest: string): string;
var
  Len: Integer;
begin
  Len := 0;
  while (Len < Length(ACode)) and
        ((ACode[Len + 1] in NameChars) or (ACode[Len + 1] = '$')) do
    Inc(Len);
  Result := UpperCase(Copy(ACode, 1, Len));
  ARest := TrimLeft(Copy(ACode, Len + 1, MaxInt));
end;

// Имя в начале AText (с точками и суффиксом); остаток - в ARest
function TakeName(const AText: string; var ARest: string): string;
var
  Len: Integer;
begin
  Len := 0;
  while (Len < Length(AText)) and
        ((AText[Len + 1] in NameChars) or (AText[Len + 1] = '.') or
         (AText[Len + 1] = '~')) do
    Inc(Len);
  while (Len < Length(AText)) and (AText[Len + 1] in SuffixChars) do
    Inc(Len);
  Result := Copy(AText, 1, Len);
  ARest := TrimLeft(Copy(AText, Len + 1, MaxInt));
end;

// Имена в коде: слова вне строк; у "A.B" - и "A", и "B", и "A.B"
procedure AddUses(const ACode: string; AList: TStringList);
var
  CharIdx, StartIdx: Integer;
  Word, Part: string;
  InStr: Boolean;
  DotPos: Integer;
begin
  CharIdx := 1;
  InStr := False;
  while CharIdx <= Length(ACode) do
  begin
    if ACode[CharIdx] = '"' then
    begin
      InStr := not InStr;
      Inc(CharIdx);
      Continue;
    end;
    if InStr or not ((ACode[CharIdx] in NameChars) or (ACode[CharIdx] = '~')) or
       ((ACode[CharIdx] in ['0'..'9']) and
        ((CharIdx = 1) or not (ACode[CharIdx - 1] in NameChars))) then
    begin
      Inc(CharIdx);
      Continue;
    end;
    StartIdx := CharIdx;
    while (CharIdx <= Length(ACode)) and
          ((ACode[CharIdx] in NameChars) or (ACode[CharIdx] = '~') or
           ((ACode[CharIdx] = '.') and (CharIdx < Length(ACode)) and
            (ACode[CharIdx + 1] in NameChars))) do
      Inc(CharIdx);
    while (CharIdx <= Length(ACode)) and (ACode[CharIdx] in SuffixChars) do
      Inc(CharIdx);
    Word := Copy(ACode, StartIdx, CharIdx - StartIdx);
    AList.Add(IncNameKey(Word));
    Part := Word;
    DotPos := Pos('.', Part);
    while DotPos > 0 do
    begin
      AList.Add(IncNameKey(Copy(Part, 1, DotPos - 1)));
      Part := Copy(Part, DotPos + 1, MaxInt);
      DotPos := Pos('.', Part);
    end;
    AList.Add(IncNameKey(Part));
  end;
end;

// Имена через запятую верхнего уровня: "A AS LONG, B(10) AS STRING, C=1"
procedure AddListNames(const AText: string; AUnit: TIncUnit);
var
  Depth, CharIdx, StartIdx: Integer;
  Part, Rest, NameText: string;
  InStr: Boolean;
begin
  Depth := 0;
  InStr := False;
  StartIdx := 1;
  for CharIdx := 1 to Length(AText) + 1 do
  begin
    if CharIdx <= Length(AText) then
    begin
      if AText[CharIdx] = '"' then
        InStr := not InStr;
      if InStr then
        Continue;
      if AText[CharIdx] = '(' then
        Inc(Depth)
      else if AText[CharIdx] = ')' then
        Dec(Depth);
      if (AText[CharIdx] <> ',') or (Depth > 0) then
        Continue;
    end;
    Part := Trim(Copy(AText, StartIdx, CharIdx - StartIdx));
    StartIdx := CharIdx + 1;
    NameText := TakeName(Part, Rest);
    if NameText <> '' then
    begin
      AUnit.Names.Add(IncNameKey(NameText));
      if AUnit.Name = '' then
        AUnit.Name := NameText;
    end;
  end;
end;

{ TIncDoc }

constructor TIncDoc.Create;
begin
  inherited Create;
  Lines := TStringList.Create;
  Units := TList.Create;
  GuardOpen := -1;
  GuardDefine := -1;
  GuardClose := -1;
end;

destructor TIncDoc.Destroy;
var
  UnitIdx: Integer;
begin
  for UnitIdx := 0 to Units.Count - 1 do
    TIncUnit(Units[UnitIdx]).Free;
  Units.Free;
  Lines.Free;
  inherited Destroy;
end;

function TIncDoc.LoadFromFile(const AFile: string): Boolean;
begin
  Result := False;
  FileName := AFile;
  try
    Lines.LoadFromFile(AFile);
  except
    Exit;
  end;
  Parse;
  Result := True;
end;

function TIncDoc.UnitAtLine(ALine: Integer): TIncUnit;
var
  UnitIdx: Integer;
begin
  Result := nil;
  for UnitIdx := 0 to Units.Count - 1 do
    if (TIncUnit(Units[UnitIdx]).First <= ALine) and
       (TIncUnit(Units[UnitIdx]).Last >= ALine) then
    begin
      Result := TIncUnit(Units[UnitIdx]);
      Exit;
    end;
end;

procedure TIncDoc.Parse;
var
  LineIdx, LineCount, Depth, CommentFirst, EndIdx, Nest: Integer;
  Code, Word, Rest, Word2, Rest2, NameText, Full: string;
  NewUnit: TIncUnit;
  Kind: TIncUnitKind;
  FirstCode, LastCode, SecondCode: Integer;
  ProcByKey: TStringList;
  UnitIdx, FoundIdx: Integer;
  Other: TIncUnit;
  CondStack: array of Boolean;   // по открытым $IF: считается ли во вложенность

  function CodeAt(AIdx: Integer): string;
  begin
    Result := IncCodePart(Lines[AIdx]);
  end;

  // Строка с продолжением " _": последняя строка оператора
  function StatementEnd(AIdx: Integer): Integer;
  begin
    Result := AIdx;
    while (Result + 1 < LineCount) and
          (Copy(TrimRight(CodeAt(Result)), Length(TrimRight(CodeAt(Result))), 1) = '_') do
      Inc(Result);
  end;

  // Блок до строки "END <AWord>" (с вложенными того же вида для CREATE)
  function BlockEnd(AIdx: Integer; const AEndWord, ANestWord: string): Integer;
  var
    Scan, Level: Integer;
    ScanCode, W1, R1, W2, R2: string;
  begin
    Level := 0;
    Scan := AIdx + 1;
    while Scan < LineCount do
    begin
      ScanCode := CodeAt(Scan);
      W1 := FirstWord(ScanCode, R1);
      if (ANestWord <> '') and (W1 = ANestWord) then
        Inc(Level)
      else if W1 = 'END' then
      begin
        W2 := FirstWord(R1, R2);
        // FUNCTIONI закрывают и END FUNCTION, и END FUNCTIONI
        if (W2 = AEndWord) or (W2 = AEndWord + 'I') then
        begin
          if Level = 0 then
          begin
            Result := Scan;
            Exit;
          end;
          Dec(Level);
        end;
      end;
      Inc(Scan);
    end;
    Result := LineCount - 1;
  end;

  procedure AddUnit(AKind: TIncUnitKind; AFirst, AHead, ALast: Integer);
  var
    Scan: Integer;
  begin
    NewUnit := TIncUnit.Create;
    NewUnit.Kind := AKind;
    NewUnit.First := AFirst;
    NewUnit.Head := AHead;
    NewUnit.Last := ALast;
    NewUnit.Depth := Depth;
    for Scan := AHead to ALast do
      AddUses(CodeAt(Scan), NewUnit.Uses_);
    Units.Add(NewUnit);
  end;

  // Ожидающие комментарии (не прикрепились) - отдельными строками
  procedure FlushComments(AUpTo: Integer);
  begin
    if CommentFirst < 0 then
      Exit;
    while CommentFirst < AUpTo do
    begin
      AddUnit(iuOther, CommentFirst, CommentFirst, CommentFirst);
      Inc(CommentFirst);
    end;
    CommentFirst := -1;
  end;

begin
  for UnitIdx := 0 to Units.Count - 1 do
    TIncUnit(Units[UnitIdx]).Free;
  Units.Clear;
  LineCount := Lines.Count;

  // Страж файла: первая строка кода $IFNDEF X, вторая $DEFINE X, последняя
  // $ENDIF
  GuardName := '';
  GuardOpen := -1;
  GuardDefine := -1;
  GuardClose := -1;
  FirstCode := -1;
  SecondCode := -1;
  LastCode := -1;
  for LineIdx := 0 to LineCount - 1 do
    if CodeAt(LineIdx) <> '' then
    begin
      if FirstCode < 0 then
        FirstCode := LineIdx
      else if SecondCode < 0 then
        SecondCode := LineIdx;
      LastCode := LineIdx;
    end;
  if (FirstCode >= 0) and (SecondCode >= 0) then
  begin
    Word := FirstWord(CodeAt(FirstCode), Rest);
    Word2 := FirstWord(CodeAt(SecondCode), Rest2);
    if (Word = '$IFNDEF') and (Word2 = '$DEFINE') and
       (IncNameKey(Rest) <> '') and
       (IncNameKey(TakeName(Rest, Full)) = IncNameKey(TakeName(Rest2, Full))) and
       (UpperCase(Copy(CodeAt(LastCode), 1, 6)) = '$ENDIF') then
    begin
      GuardName := TakeName(Rest, Full);
      GuardOpen := FirstCode;
      GuardDefine := SecondCode;
      GuardClose := LastCode;
    end;
  end;

  Depth := 0;
  CommentFirst := -1;
  LineIdx := 0;
  while LineIdx < LineCount do
  begin
    Code := CodeAt(LineIdx);
    if (LineIdx = GuardOpen) or (LineIdx = GuardDefine) or
       (LineIdx = GuardClose) then
    begin
      FlushComments(LineIdx);
      AddUnit(iuOther, LineIdx, LineIdx, LineIdx);
      CommentFirst := -1;
      Inc(LineIdx);
      Continue;
    end;
    if Code = '' then
    begin
      // комментарий подряд над объявлением - его; пустая строка рвёт.
      // Пометки сборки ('~dup, '~body ...) - сами по себе.
      if (Trim(Lines[LineIdx]) = '') or (Copy(TrimLeft(Lines[LineIdx]), 1, 2) = '''~') then
      begin
        FlushComments(LineIdx);
        AddUnit(iuOther, LineIdx, LineIdx, LineIdx);
      end
      else if CommentFirst < 0 then
        CommentFirst := LineIdx;
      Inc(LineIdx);
      Continue;
    end;

    Word := FirstWord(Code, Rest);
    if CommentFirst < 0 then
      CommentFirst := LineIdx;
    Kind := iuOther;
    EndIdx := LineIdx;
    NameText := '';

    // brem / erem (rapidq.inc: $define brem $ifdef) - тот же условный блок
    if (Word = '$IFDEF') or (Word = '$IFNDEF') or (Word = '$IF') or
       (Word = 'BREM') then
    begin
      // комментарии над директивой - отдельными строками
      FlushComments(LineIdx);
      AddUnit(iuOther, LineIdx, LineIdx, LineIdx);
      // Страж: $IFNDEF X, следующая строка кода - $DEFINE X
      SetLength(CondStack, Length(CondStack) + 1);
      CondStack[High(CondStack)] := True;
      if Word = '$IFNDEF' then
      begin
        FoundIdx := LineIdx + 1;
        while (FoundIdx < LineCount) and (CodeAt(FoundIdx) = '') do
          Inc(FoundIdx);
        if FoundIdx < LineCount then
        begin
          Word2 := FirstWord(CodeAt(FoundIdx), Rest2);
          if (Word2 = '$DEFINE') and
             (IncNameKey(TakeName(Rest2, Full)) = IncNameKey(TakeName(Rest, Full))) then
            CondStack[High(CondStack)] := False;
        end;
      end;
      if CondStack[High(CondStack)] then
        Inc(Depth);
      CommentFirst := -1;
      Inc(LineIdx);
      Continue;
    end;
    if (Word = '$ENDIF') or (Word = '$ELSE') or (Word = 'EREM') then
    begin
      FlushComments(LineIdx);
      if (Word <> '$ELSE') and (Length(CondStack) > 0) then
      begin
        if CondStack[High(CondStack)] then
          Dec(Depth);
        SetLength(CondStack, Length(CondStack) - 1);
      end;
      if Depth < 0 then
        Depth := 0;
      AddUnit(iuOther, LineIdx, LineIdx, LineIdx);
      CommentFirst := -1;
      Inc(LineIdx);
      Continue;
    end;

    if Word = 'DECLARE' then
    begin
      Word2 := FirstWord(Rest, Rest2);
      if (Word2 = 'SUB') or (Word2 = 'FUNCTION') or (Word2 = 'SUBI') or
         (Word2 = 'FUNCTIONI') then
      begin
        EndIdx := StatementEnd(LineIdx);
        NameText := TakeName(Rest2, Rest);
        Full := '';
        for FoundIdx := LineIdx to EndIdx do
          Full := Full + ' ' + CodeAt(FoundIdx);
        if Pos(' LIB ', UpperCase(Full + ' ')) > 0 then
          Kind := iuDllDeclare
        else
          Kind := iuDeclare;
      end;
    end
    else if (Word = 'SUB') or (Word = 'FUNCTION') or (Word = 'SUBI') or
            (Word = 'FUNCTIONI') then
    begin
      NameText := TakeName(Rest, Rest2);
      if (Word = 'SUBI') or (Word = 'FUNCTIONI') then
        EndIdx := BlockEnd(LineIdx, Copy(Word, 1, Length(Word) - 1), '')
      else
        EndIdx := BlockEnd(LineIdx, Word, '');
      Kind := iuProc;
    end
    else if Word = 'TYPE' then
    begin
      NameText := TakeName(Rest, Rest2);
      Word2 := FirstWord(Rest2, Rest);
      if Word2 = 'AS' then
        Kind := iuType          // TYPE X AS Y - одна строка
      else
      begin
        EndIdx := BlockEnd(LineIdx, 'TYPE', '');
        if Word2 = 'EXTENDS' then
          Kind := iuComponent
        else
          Kind := iuType;
      end;
    end
    else if Word = 'CONST' then
    begin
      EndIdx := StatementEnd(LineIdx);
      Kind := iuConst;
    end
    else if Word = '$DEFINE' then
    begin
      NameText := TakeName(Rest, Rest2);
      Kind := iuDefine;
    end
    else if (Word = 'DIM') or (Word = 'DEFINT') or (Word = 'DEFSTR') or
            (Word = 'DEFSNG') or (Word = 'DEFDBL') or (Word = 'DEFLNG') or
            (Word = 'DEFBYTE') or (Word = 'DEFWORD') or (Word = 'DEFSHORT') then
    begin
      EndIdx := StatementEnd(LineIdx);
      Kind := iuDim;
    end
    else if Word = 'CREATE' then
    begin
      NameText := TakeName(Rest, Rest2);
      EndIdx := BlockEnd(LineIdx, 'CREATE', 'CREATE');
      Kind := iuCreate;
    end
    else if Word = 'WITH' then
      EndIdx := BlockEnd(LineIdx, 'WITH', 'WITH')
    else
      EndIdx := StatementEnd(LineIdx);

    // Прочее - без прикреплённых комментариев
    if Kind = iuOther then
      FlushComments(LineIdx);
    if CommentFirst < 0 then
      CommentFirst := LineIdx;
    AddUnit(Kind, CommentFirst, LineIdx, EndIdx);
    NewUnit.Name := NameText;
    NewUnit.HeadWord := Word;
    case Kind of
      iuConst:
        AddListNames(Rest, NewUnit);
      iuDim:
        begin
          // DIM A AS ..., B AS ... ; DEFINT A = 1, B
          Full := '';
          for FoundIdx := LineIdx to EndIdx do
            Full := Full + ' ' + CodeAt(FoundIdx);
          FirstWord(Trim(Full), Rest);
          Full := StringReplace(Rest, '_ ', ' ', [rfReplaceAll]);
          AddListNames(Full, NewUnit);
        end;
    else
      if NameText <> '' then
        NewUnit.Names.Add(IncNameKey(NameText));
    end;
    // Имя самого объявления - не "использование"
    if (NewUnit.Kind in [iuProc, iuDeclare, iuDllDeclare]) and (NameText <> '') then
    begin
      FoundIdx := NewUnit.Uses_.IndexOf(IncNameKey(NameText));
      // имя внутри тела (рекурсия, присваивание результата) - не зависимость
      if FoundIdx >= 0 then
        NewUnit.Uses_.Delete(FoundIdx);
    end;
    for FoundIdx := 0 to NewUnit.Names.Count - 1 do
      if NewUnit.Uses_.IndexOf(NewUnit.Names[FoundIdx]) >= 0 then
        NewUnit.Uses_.Delete(NewUnit.Uses_.IndexOf(NewUnit.Names[FoundIdx]));
    CommentFirst := -1;
    LineIdx := EndIdx + 1;
  end;
  FlushComments(LineCount);

  // Процедура и её DECLARE без LIB (в любом порядке) - пара
  ProcByKey := TStringList.Create;
  try
    ProcByKey.Sorted := True;
    ProcByKey.Duplicates := dupIgnore;
    for UnitIdx := 0 to Units.Count - 1 do
      if TIncUnit(Units[UnitIdx]).Kind = iuProc then
        ProcByKey.AddObject(IncNameKey(TIncUnit(Units[UnitIdx]).Name),
                            Units[UnitIdx]);
    for UnitIdx := 0 to Units.Count - 1 do
    begin
      Other := TIncUnit(Units[UnitIdx]);
      if Other.Kind <> iuDeclare then
        Continue;
      FoundIdx := ProcByKey.IndexOf(IncNameKey(Other.Name));
      if (FoundIdx >= 0) and (TIncUnit(ProcByKey.Objects[FoundIdx]).Pair = nil) then
      begin
        Other.Pair := TIncUnit(ProcByKey.Objects[FoundIdx]);
        Other.Pair.Pair := Other;
      end;
    end;
  finally
    ProcByKey.Free;
  end;

  // DLL: имя библиотеки
  for UnitIdx := 0 to Units.Count - 1 do
  begin
    Other := TIncUnit(Units[UnitIdx]);
    if Other.Kind <> iuDllDeclare then
      Continue;
    Full := '';
    for FoundIdx := Other.Head to Other.Last do
      Full := Full + ' ' + Lines[FoundIdx];
    Nest := Pos(' LIB ', UpperCase(Full));
    if Nest > 0 then
    begin
      Rest := Copy(Full, Nest + 5, MaxInt);
      Nest := Pos('"', Rest);
      if Nest > 0 then
      begin
        Rest := Copy(Rest, Nest + 1, MaxInt);
        Other.Lib := Copy(Rest, 1, Pos('"', Rest) - 1);
      end;
    end;
  end;
end;

procedure TIncDoc.OfferedItems(AList: TList);
var
  UnitIdx: Integer;
  OneUnit: TIncUnit;
begin
  AList.Clear;
  for UnitIdx := 0 to Units.Count - 1 do
  begin
    OneUnit := TIncUnit(Units[UnitIdx]);
    if OneUnit.Offered then
      AList.Add(OneUnit);
  end;
end;

{ изъятие }

// Индексы: имя -> единицы, которые его объявляют / которые им пользуются
procedure BuildIndex(ADoc: TIncDoc; ADefs, AUsers: TStringList);
var
  UnitIdx, NameIdx, Found: Integer;
  OneUnit: TIncUnit;

  procedure AddTo(AIndex: TStringList; const AKey: string; AUnit: TIncUnit);
  begin
    Found := AIndex.IndexOf(AKey);
    if Found < 0 then
      Found := AIndex.AddObject(AKey, TList.Create);
    TList(AIndex.Objects[Found]).Add(AUnit);
  end;

begin
  ADefs.Sorted := True;
  AUsers.Sorted := True;
  for UnitIdx := 0 to ADoc.Units.Count - 1 do
  begin
    OneUnit := TIncUnit(ADoc.Units[UnitIdx]);
    for NameIdx := 0 to OneUnit.Names.Count - 1 do
      AddTo(ADefs, OneUnit.Names[NameIdx], OneUnit);
    for NameIdx := 0 to OneUnit.Uses_.Count - 1 do
      AddTo(AUsers, OneUnit.Uses_[NameIdx], OneUnit);
  end;
end;

procedure FreeIndex(AIndex: TStringList);
var
  Idx: Integer;
begin
  for Idx := 0 to AIndex.Count - 1 do
    AIndex.Objects[Idx].Free;
  AIndex.Free;
end;

// Кто пользуется именами единицы AUnit, кроме единиц из AExcept
procedure UsersOf(AUnit: TIncUnit; AUsers: TStringList; AExcept: TList;
  AResult: TList);
var
  NameIdx, Found, UserIdx: Integer;
  UserList: TList;
begin
  for NameIdx := 0 to AUnit.Names.Count - 1 do
  begin
    Found := AUsers.IndexOf(AUnit.Names[NameIdx]);
    if Found < 0 then
      Continue;
    UserList := TList(AUsers.Objects[Found]);
    for UserIdx := 0 to UserList.Count - 1 do
      if (AExcept.IndexOf(UserList[UserIdx]) < 0) and
         (AResult.IndexOf(UserList[UserIdx]) < 0) then
        AResult.Add(UserList[UserIdx]);
  end;
end;

// Что уходит с пунктом AItem: он сам, его пара и всё, чем пользуются только
// они (по цепочке). AOtherItems - остальные изымаемые пункты: их и их пары
// не забираем.
procedure ExtractClosure(ADoc: TIncDoc; AItem: TIncUnit; AOtherItems: TList;
  ADefs, AUsers, AExternal: TStringList; AClosure: TList);
var
  Changed: Boolean;
  MemberIdx, UseIdx, Found, DefIdx: Integer;
  Member, Candidate: TIncUnit;
  DefList, Outside, Trial: TList;

  // Имя единицы нужно файлу, подключающему этот
  function UsedOutside(AUnit: TIncUnit): Boolean;
  var
    NameIdx: Integer;
  begin
    Result := False;
    if AExternal = nil then
      Exit;
    for NameIdx := 0 to AUnit.Names.Count - 1 do
      if AExternal.IndexOf(AUnit.Names[NameIdx]) >= 0 then
      begin
        Result := True;
        Exit;
      end;
  end;

  function Movable(AUnit: TIncUnit): Boolean;
  begin
    Result := (AUnit.Depth = 0) and not UsedOutside(AUnit) and
              (AUnit.Kind in [iuConst, iuDefine, iuDeclare, iuDllDeclare,
                              iuProc, iuType, iuComponent, iuDim]) and
              (AOtherItems.IndexOf(AUnit) < 0) and
              ((AUnit.Pair = nil) or (AOtherItems.IndexOf(AUnit.Pair) < 0));
  end;

begin
  AClosure.Clear;
  AClosure.Add(AItem);
  if AItem.Pair <> nil then
    AClosure.Add(AItem.Pair);
  Outside := TList.Create;
  Trial := TList.Create;
  try
    repeat
      Changed := False;
      for MemberIdx := 0 to AClosure.Count - 1 do
      begin
        Member := TIncUnit(AClosure[MemberIdx]);
        for UseIdx := 0 to Member.Uses_.Count - 1 do
        begin
          Found := ADefs.IndexOf(Member.Uses_[UseIdx]);
          if Found < 0 then
            Continue;
          DefList := TList(ADefs.Objects[Found]);
          for DefIdx := 0 to DefList.Count - 1 do
          begin
            Candidate := TIncUnit(DefList[DefIdx]);
            if (AClosure.IndexOf(Candidate) >= 0) or not Movable(Candidate) then
              Continue;
            // Им пользуется только то, что уходит (с ним и его парой)?
            Trial.Assign(AClosure);
            Trial.Add(Candidate);
            if Candidate.Pair <> nil then
              Trial.Add(Candidate.Pair);
            Outside.Clear;
            UsersOf(Candidate, AUsers, Trial, Outside);
            if Candidate.Pair <> nil then
              UsersOf(Candidate.Pair, AUsers, Trial, Outside);
            if Outside.Count = 0 then
            begin
              AClosure.Add(Candidate);
              if (Candidate.Pair <> nil) and
                 (AClosure.IndexOf(Candidate.Pair) < 0) then
                AClosure.Add(Candidate.Pair);
              Changed := True;
            end;
          end;
        end;
        if Changed then
          Break;   // список вырос - заново, по новому составу
      end;
    until not Changed;
  finally
    Trial.Free;
    Outside.Free;
  end;
end;

function SafeFileName(const AName: string): string;
var
  CharIdx: Integer;
begin
  Result := '';
  for CharIdx := 1 to Length(AName) do
    if AName[CharIdx] in NameChars then
      Result := Result + AName[CharIdx]
    else if AName[CharIdx] in ['.', '~'] then
      Result := Result + '_';
  if Result = '' then
    Result := 'item';
end;

function IncItemFileName(ADoc: TIncDoc; AItem: TIncUnit): string;
begin
  Result := ExtractFilePath(ADoc.FileName) + SafeFileName(AItem.Name) + '.inc';
end;

function SortByLine(Item1, Item2: Pointer): Integer;
begin
  Result := TIncUnit(Item1).First - TIncUnit(Item2).First;
end;

// $INCLUDE файлов из строк ALines: имена файлов (верхний регистр)
procedure IncludedNames(ALines: TStrings; AResult: TStrings);
var
  LineIdx: Integer;
  Code, Rest: string;
begin
  for LineIdx := 0 to ALines.Count - 1 do
  begin
    Code := IncCodePart(ALines[LineIdx]);
    if UpperCase(Copy(Code, 1, 8)) <> '$INCLUDE' then
      Continue;
    Rest := Trim(Copy(Code, 9, MaxInt));
    Rest := StringReplace(StringReplace(StringReplace(Rest, '"', '',
      [rfReplaceAll]), '<', '', [rfReplaceAll]), '>', '', [rfReplaceAll]);
    AResult.Add(UpperCase(ExtractFileName(Trim(Rest))));
  end;
end;

function IncExternalUses(const AIncFile: string; ACandidates: TStrings;
  AUses: TStringList): Integer;
var
  Includers: TStringList;      // имена файлов, подключающих AIncFile
  Incs: array of TStringList;  // $INCLUDE каждого кандидата
  Taken: array of Boolean;
  FileIdx, IncIdx: Integer;
  Changed: Boolean;
  Doc: TIncDoc;
  UnitIdx, UseIdx: Integer;
begin
  Result := 0;
  AUses.Sorted := True;
  AUses.Duplicates := dupIgnore;
  Includers := TStringList.Create;
  SetLength(Incs, ACandidates.Count);
  SetLength(Taken, ACandidates.Count);
  try
    Includers.Add(UpperCase(ExtractFileName(AIncFile)));
    for FileIdx := 0 to ACandidates.Count - 1 do
    begin
      Incs[FileIdx] := TStringList.Create;
      Taken[FileIdx] := False;
      if SameText(ExpandFileName(ACandidates[FileIdx]), ExpandFileName(AIncFile)) then
        Continue;
      Doc := TIncDoc.Create;
      try
        try
          Doc.Lines.LoadFromFile(ACandidates[FileIdx]);
          IncludedNames(Doc.Lines, Incs[FileIdx]);
        except
        end;
      finally
        Doc.Free;
      end;
    end;
    // подключающие - по цепочке
    repeat
      Changed := False;
      for FileIdx := 0 to ACandidates.Count - 1 do
      begin
        if Taken[FileIdx] then
          Continue;
        for IncIdx := 0 to Incs[FileIdx].Count - 1 do
          if Includers.IndexOf(Incs[FileIdx][IncIdx]) >= 0 then
          begin
            Taken[FileIdx] := True;
            Includers.Add(UpperCase(ExtractFileName(ACandidates[FileIdx])));
            Changed := True;
            Break;
          end;
      end;
    until not Changed;
    for FileIdx := 0 to ACandidates.Count - 1 do
    begin
      if not Taken[FileIdx] then
        Continue;
      Inc(Result);
      Doc := TIncDoc.Create;
      try
        if Doc.LoadFromFile(ACandidates[FileIdx]) then
          for UnitIdx := 0 to Doc.Units.Count - 1 do
            for UseIdx := 0 to TIncUnit(Doc.Units[UnitIdx]).Uses_.Count - 1 do
              if AUses.IndexOf(TIncUnit(Doc.Units[UnitIdx]).Uses_[UseIdx]) < 0 then
                AUses.AddObject(TIncUnit(Doc.Units[UnitIdx]).Uses_[UseIdx],
                                TObject(FileIdx));
      finally
        Doc.Free;
      end;
    end;
  finally
    for FileIdx := 0 to High(Incs) do
      Incs[FileIdx].Free;
    Includers.Free;
  end;
end;

function IncExtract(ADoc: TIncDoc; AItems: TList; AOverwrite: Boolean;
  AReport: TStrings; AExternal: TStringList = nil;
  AExternalFiles: TStrings = nil): Integer;
var
  Defs, Users: TStringList;
  ItemIdx, OtherIdx, MemberIdx, LineIdx, UserIdx: Integer;
  Item, Member, OtherItem: TIncUnit;
  Closure, Outside, OthersOf, Blocked: TList;
  Closures: TList;
  NewLines, Needs: TStringList;
  Guard, OutFile, Users_Text: string;
  Removed: array of Boolean;
  MovedComment: array of string;
  AnyDone: Boolean;
begin
  Result := 0;
  Defs := TStringList.Create;
  Users := TStringList.Create;
  Closures := TList.Create;
  Blocked := TList.Create;
  Outside := TList.Create;
  OthersOf := TList.Create;
  try
    BuildIndex(ADoc, Defs, Users);

    // Состав каждого пункта
    for ItemIdx := 0 to AItems.Count - 1 do
    begin
      Item := TIncUnit(AItems[ItemIdx]);
      OthersOf.Clear;
      for OtherIdx := 0 to AItems.Count - 1 do
        if OtherIdx <> ItemIdx then
        begin
          OthersOf.Add(AItems[OtherIdx]);
          if TIncUnit(AItems[OtherIdx]).Pair <> nil then
            OthersOf.Add(TIncUnit(AItems[OtherIdx]).Pair);
        end;
      Closure := TList.Create;
      ExtractClosure(ADoc, Item, OthersOf, Defs, Users, AExternal, Closure);
      Closures.Add(Closure);
    end;

    // Пункт, которым пользуется оставшееся в файле, не изымается. Другой
    // изымаемый пункт не мешает (он подключит файл этого), если только сам
    // изымается - поэтому по кругу, пока список не устоится.
    for ItemIdx := 0 to AItems.Count - 1 do
    begin
      Item := TIncUnit(AItems[ItemIdx]);
      OutFile := IncItemFileName(ADoc, Item);
      if FileExists(OutFile) and not AOverwrite then
      begin
        Blocked.Add(Item);
        AReport.Add(Item.Name + ': не изъят - файл ' + ExtractFileName(OutFile) +
                    ' уже есть');
      end;
    end;
    // Пункт нужен файлу, который подключает этот
    if AExternal <> nil then
      for ItemIdx := 0 to AItems.Count - 1 do
      begin
        Item := TIncUnit(AItems[ItemIdx]);
        if Blocked.IndexOf(Item) >= 0 then
          Continue;
        for MemberIdx := 0 to Item.Names.Count - 1 do
        begin
          OtherIdx := AExternal.IndexOf(Item.Names[MemberIdx]);
          if OtherIdx < 0 then
            Continue;
          Blocked.Add(Item);
          Users_Text := '';
          if AExternalFiles <> nil then
            Users_Text := ExtractFileName(AExternalFiles[Integer(AExternal.Objects[OtherIdx])]);
          AReport.Add(Item.Name + ': не изъят - им пользуется ' + Users_Text +
                      ' (подключает этот файл)');
          Break;
        end;
      end;
    repeat
      AnyDone := False;
      for ItemIdx := 0 to AItems.Count - 1 do
      begin
        Item := TIncUnit(AItems[ItemIdx]);
        if Blocked.IndexOf(Item) >= 0 then
          Continue;
        Closure := TList(Closures[ItemIdx]);
        Outside.Clear;
        UsersOf(Item, Users, Closure, Outside);
        if Item.Pair <> nil then
          UsersOf(Item.Pair, Users, Closure, Outside);
        Users_Text := '';
        for UserIdx := 0 to Outside.Count - 1 do
        begin
          Member := TIncUnit(Outside[UserIdx]);
          OtherIdx := -1;
          for MemberIdx := 0 to AItems.Count - 1 do
            if (MemberIdx <> ItemIdx) and
               (Blocked.IndexOf(AItems[MemberIdx]) < 0) and
               (TList(Closures[MemberIdx]).IndexOf(Member) >= 0) then
              OtherIdx := MemberIdx;
          if OtherIdx >= 0 then
            Continue;
          if Users_Text <> '' then
            Users_Text := Users_Text + ', ';
          if Member.Name <> '' then
            Users_Text := Users_Text + Member.Name + ' (стр. ' +
                          IntToStr(Member.Head + 1) + ')'
          else
            Users_Text := Users_Text + 'стр. ' + IntToStr(Member.Head + 1);
          if Length(Users_Text) > 200 then
          begin
            Users_Text := Users_Text + ' ...';
            Break;
          end;
        end;
        if Users_Text <> '' then
        begin
          Blocked.Add(Item);
          AReport.Add(Item.Name + ': не изъят - им пользуется оставшееся в ' +
                      'файле: ' + Users_Text);
          AnyDone := True;
        end;
      end;
    until not AnyDone;

    // Файлы пунктов
    SetLength(Removed, ADoc.Lines.Count);
    SetLength(MovedComment, ADoc.Lines.Count);
    AnyDone := False;
    for ItemIdx := 0 to AItems.Count - 1 do
    begin
      Item := TIncUnit(AItems[ItemIdx]);
      if Blocked.IndexOf(Item) >= 0 then
        Continue;
      Closure := TList(Closures[ItemIdx]);
      Closure.Sort(SortByLine);
      OutFile := IncItemFileName(ADoc, Item);
      // Каким изымаемым файлам этот пункт пользуется - их тоже подключить
      Needs := TStringList.Create;
      NewLines := TStringList.Create;
      try
        for OtherIdx := 0 to AItems.Count - 1 do
        begin
          OtherItem := TIncUnit(AItems[OtherIdx]);
          if (OtherIdx = ItemIdx) or (Blocked.IndexOf(OtherItem) >= 0) then
            Continue;
          Outside.Clear;
          UsersOf(OtherItem, Users, TList(Closures[OtherIdx]), Outside);
          for MemberIdx := 0 to Closure.Count - 1 do
            if Outside.IndexOf(Closure[MemberIdx]) >= 0 then
            begin
              Needs.Add(ExtractFileName(IncItemFileName(ADoc, OtherItem)));
              Break;
            end;
        end;
        Guard := '__' + UpperCase(SafeFileName(Item.Name)) + '_INC';
        NewLines.Add('''' + ' ' + ExtractFileName(OutFile) + ' - изъято из ' +
                     ExtractFileName(ADoc.FileName) + ' (INC Manager, ' +
                     FormatDateTime('yyyy-mm-dd', Now) + ')');
        NewLines.Add('$IFNDEF ' + Guard);
        NewLines.Add('$DEFINE ' + Guard);
        NewLines.Add('$INCLUDE "' + ExtractFileName(ADoc.FileName) + '"');
        for OtherIdx := 0 to Needs.Count - 1 do
          NewLines.Add('$INCLUDE "' + Needs[OtherIdx] + '"');
        NewLines.Add('');
        for MemberIdx := 0 to Closure.Count - 1 do
        begin
          Member := TIncUnit(Closure[MemberIdx]);
          for LineIdx := Member.First to Member.Last do
          begin
            NewLines.Add(ADoc.Lines[LineIdx]);
            Removed[LineIdx] := True;
          end;
          if MemberIdx < Closure.Count - 1 then
            NewLines.Add('');
        end;
        NewLines.Add('');
        NewLines.Add('$ENDIF');
        try
          NewLines.SaveToFile(OutFile);
        except
          on E: Exception do
          begin
            AReport.Add(Item.Name + ': не изъят - ' + ExtractFileName(OutFile) +
                        ' не записан (' + E.Message + ')');
            for MemberIdx := 0 to Closure.Count - 1 do
            begin
              Member := TIncUnit(Closure[MemberIdx]);
              for LineIdx := Member.First to Member.Last do
                Removed[LineIdx] := False;
            end;
            Continue;
          end;
        end;
        MovedComment[Item.First] := '''~moved ' + Item.Name + ' -> ' +
                                    ExtractFileName(OutFile);
        AnyDone := True;
        Inc(Result);
        if Closure.Count > 1 + Ord(Item.Pair <> nil) then
          AReport.Add(Item.Name + ' -> ' + ExtractFileName(OutFile) +
                      Format(' (с ним: %d объявл.)',
                             [Closure.Count - 1 - Ord(Item.Pair <> nil)]))
        else
          AReport.Add(Item.Name + ' -> ' + ExtractFileName(OutFile));
      finally
        NewLines.Free;
        Needs.Free;
      end;
    end;

    // Исходный файл - без изъятого; прежний - в .bak
    if AnyDone then
    begin
      NewLines := TStringList.Create;
      try
        for LineIdx := 0 to ADoc.Lines.Count - 1 do
        begin
          if MovedComment[LineIdx] <> '' then
            NewLines.Add(MovedComment[LineIdx]);
          if not Removed[LineIdx] then
            NewLines.Add(ADoc.Lines[LineIdx]);
        end;
        try
          ADoc.Lines.SaveToFile(ChangeFileExt(ADoc.FileName, '.bak'));
          NewLines.SaveToFile(ADoc.FileName);
        except
          on E: Exception do
            AReport.Add(ExtractFileName(ADoc.FileName) + ' не записан: ' +
                        E.Message);
        end;
      finally
        NewLines.Free;
      end;
    end;
  finally
    for ItemIdx := 0 to Closures.Count - 1 do
      TList(Closures[ItemIdx]).Free;
    Closures.Free;
    Blocked.Free;
    Outside.Free;
    OthersOf.Free;
    FreeIndex(Defs);
    FreeIndex(Users);
  end;
end;

{ сборка }

// Пространство имён для повторов: CONST и $DEFINE - одно, DECLARE и
// процедуры - одно
function MergeKey(AUnit: TIncUnit; const AName: string): string;
begin
  case AUnit.Kind of
    iuConst, iuDefine:
      Result := 'C:' + AName;
    iuDeclare, iuDllDeclare, iuProc:
      Result := 'P:' + AName;
    iuType, iuComponent:
      Result := 'T:' + AName;
    iuDim:
      Result := 'V:' + AName;
    iuCreate:
      Result := 'O:' + AName;
  else
    Result := '';
  end;
end;

function UnitText(ADoc: TIncDoc; AUnit: TIncUnit): string;
var
  LineIdx: Integer;
begin
  Result := '';
  for LineIdx := AUnit.Head to AUnit.Last do
    Result := Result + UpperCase(StringReplace(IncCodePart(ADoc.Lines[LineIdx]),
                                               ' ', '', [rfReplaceAll]));
end;

function IncMerge(AFiles: TStrings; const AOutFile: string;
  AReport: TStrings): Boolean;
var
  Seen: TStringList;      // ключи (сортированы), Objects - номер в SeenVals
  SeenVals: TStringList;  // "файл|текст" первого объявления
  Docs: TList;
  Doc: TIncDoc;
  FileIdx, UnitIdx, NameIdx, LineIdx, Found, Dropped: Integer;
  OneUnit: TIncUnit;
  OutLines, MergedNames: TStringList;
  Key, Text, IncName, Code, Word, Rest, Value: string;
  Drop, Differs: Boolean;
begin
  Result := False;
  Seen := TStringList.Create;
  Seen.Sorted := True;
  SeenVals := TStringList.Create;
  Docs := TList.Create;
  OutLines := TStringList.Create;
  MergedNames := TStringList.Create;
  try
    for FileIdx := 0 to AFiles.Count - 1 do
    begin
      Doc := TIncDoc.Create;
      if not Doc.LoadFromFile(AFiles[FileIdx]) then
      begin
        AReport.Add(AFiles[FileIdx] + ': не прочитан');
        Doc.Free;
        Exit;
      end;
      Docs.Add(Doc);
      MergedNames.Add(UpperCase(ExtractFileName(AFiles[FileIdx])));
    end;

    IncName := '__' + UpperCase(SafeFileName(ChangeFileExt(ExtractFileName(AOutFile), ''))) + '_INC';
    OutLines.Add('''' + ' ' + ExtractFileName(AOutFile) + ' - собран INC Manager ' +
                 FormatDateTime('yyyy-mm-dd', Now) + ' из ' + IntToStr(AFiles.Count) +
                 ' файлов; из одноимённых объявлений оставлено первое');
    OutLines.Add('$IFNDEF ' + IncName);
    OutLines.Add('$DEFINE ' + IncName);
    for FileIdx := 0 to Docs.Count - 1 do
    begin
      Doc := TIncDoc(Docs[FileIdx]);
      Dropped := 0;
      OutLines.Add('');
      OutLines.Add('''' + '=== ' + ExtractFileName(Doc.FileName));
      for UnitIdx := 0 to Doc.Units.Count - 1 do
      begin
        OneUnit := TIncUnit(Doc.Units[UnitIdx]);
        // страж файла не нужен: у собранного свой
        if (OneUnit.Head = Doc.GuardOpen) or (OneUnit.Head = Doc.GuardDefine) or
           (OneUnit.Head = Doc.GuardClose) then
          Continue;
        Drop := False;
        Differs := False;
        Text := UnitText(Doc, OneUnit);
        if (OneUnit.Depth = 0) and (OneUnit.Names.Count > 0) then
        begin
          Drop := True;
          for NameIdx := 0 to OneUnit.Names.Count - 1 do
          begin
            Key := MergeKey(OneUnit, OneUnit.Names[NameIdx]);
            Found := Seen.IndexOf(Key);
            if Found < 0 then
              Drop := False
            else
            begin
              Value := SeenVals[Integer(Seen.Objects[Found])];
              // тот же файл (DECLARE и тело процедуры) - не повтор
              if Copy(Value, 1, Pos('|', Value) - 1) = IntToStr(FileIdx) then
                Drop := False
              else if Copy(Value, Pos('|', Value) + 1, MaxInt) <> Text then
                Differs := True;
            end;
          end;
          if Drop then
          begin
            Inc(Dropped);
            if Differs then
              AReport.Add(ExtractFileName(Doc.FileName) + ', стр. ' +
                          IntToStr(OneUnit.Head + 1) + ': ' + OneUnit.Name +
                          ' - уже есть с другим текстом, оставлено первое');
            Continue;
          end;
          for NameIdx := 0 to OneUnit.Names.Count - 1 do
          begin
            Key := MergeKey(OneUnit, OneUnit.Names[NameIdx]);
            if (Key <> '') and (Seen.IndexOf(Key) < 0) then
              Seen.AddObject(Key, TObject(SeenVals.Add(IntToStr(FileIdx) +
                                                        '|' + Text)));
          end;
        end;
        for LineIdx := OneUnit.First to OneUnit.Last do
        begin
          // $INCLUDE собираемого файла - уже здесь
          Code := IncCodePart(Doc.Lines[LineIdx]);
          Word := UpperCase(Copy(Code, 1, 8));
          if Word = '$INCLUDE' then
          begin
            Rest := Trim(Copy(Code, 9, MaxInt));
            Rest := StringReplace(StringReplace(StringReplace(Rest, '"', '',
              [rfReplaceAll]), '<', '', [rfReplaceAll]), '>', '', [rfReplaceAll]);
            if MergedNames.IndexOf(UpperCase(ExtractFileName(Trim(Rest)))) >= 0 then
            begin
              OutLines.Add('''~inc ' + Doc.Lines[LineIdx] + '   '' уже в этом файле');
              Continue;
            end;
          end;
          OutLines.Add(Doc.Lines[LineIdx]);
        end;
      end;
      if Dropped > 0 then
        AReport.Add(ExtractFileName(Doc.FileName) + ': повторов убрано ' +
                    IntToStr(Dropped));
    end;
    OutLines.Add('');
    OutLines.Add('$ENDIF');
    try
      // прежний файл с тем же именем - в .bak
      if FileExists(AOutFile) then
      begin
        DeleteFile(ChangeFileExt(AOutFile, '.bak'));
        RenameFile(AOutFile, ChangeFileExt(AOutFile, '.bak'));
      end;
      OutLines.SaveToFile(AOutFile);
    except
      on E: Exception do
      begin
        AReport.Add(AOutFile + ' не записан: ' + E.Message);
        Exit;
      end;
    end;
    AReport.Add('Собран ' + AOutFile + ': ' + IntToStr(OutLines.Count) + ' строк');
    Result := True;
  finally
    for FileIdx := 0 to Docs.Count - 1 do
      TIncDoc(Docs[FileIdx]).Free;
    Docs.Free;
    OutLines.Free;
    MergedNames.Free;
    SeenVals.Free;
    Seen.Free;
  end;
end;

end.
