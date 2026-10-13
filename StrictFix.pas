unit StrictFix;

// ---------------------------------------------------------------------------
//  Разбор ошибок строгой проверки (перевод RqToFb, режим FB Smart, перед
//  rc.exe) и варианты их исправления - без VCL; окно - DlgStrictFix.
//
//  Что умеет предложить:
//   - "X.Член: X не объявлен - ни переменной, ни объектом": найти DIM X /
//     CREATE X в inc и bas папок Include, программы и папки выше; найденный
//     файл подключить - раскомментировать его $INCLUDE в программе, если он
//     там закомментирован, иначе добавить строку $INCLUDE;
//   - "GOTO метка: метка в другой процедуре" и "метки нет": похожая метка в
//     той же процедуре (опечатка: w8file вместо w81file) - заменить ею.
//  Прочее - "не могу предложить вариант исправления".
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes,
  IncCheck;     // IncFindNamesOnDisk, TIncProgress

type
  TStrictKind = (skOther,           // предложить нечего
                 skUndeclared,      // объект без DIM / CREATE
                 skLabelElsewhere,  // метка в другой процедуре
                 skLabelMissing);   // метки нет нигде

  TStrictError = class
  public
    FileName: string;   // как в сообщении (полный путь)
    Line: Integer;      // с 1
    Text: string;       // текст ошибки после "Error: "
    Kind: TStrictKind;
    Name: string;       // имя объекта или метки
    Member: string;     // skUndeclared: свойство / метод (Item, ItemCount)
    Places: string;     // skLabelElsewhere: где метка (из сообщения)
    Statement: string;  // GOTO или GOSUB
  end;

// Строка лога перевода "файл(строка) Error: текст" - ошибка; nil - строка
// не ошибка (Warning, Suspect, прочее)
function StrictParseError(const AMsg: string): TStrictError;

// Процедура (SUB / FUNCTION), в которой строка ALineIdx (с 0): первая и
// последняя её строки, имя. False - строка вне процедур.
function StrictProcAt(ALines: TStrings; ALineIdx: Integer;
                      var AFirst, ALast: Integer; var AName: string): Boolean;

// Метки строк AFirst..ALast (с 0): "Имя=номер строки с 1"
procedure StrictLabelsIn(ALines: TStrings; AFirst, ALast: Integer;
                         ALabels: TStrings);

// Метки из ALabels, похожие на ALabel (отличие до двух букв, или одна -
// начало другой): в AOut "Имя=строка", ближайшие первыми
procedure StrictSimilarLabels(const ALabel: string; ALabels, AOut: TStrings);

// В строке ALine GOTO / GOSUB AOld заменить на ANew. False - не нашлось.
function StrictReplaceGoto(const ALine, AOld, ANew: string;
                           var AResult: string): Boolean;

// DIM / CREATE AName в .inc, .bas, .cmp папок ARoots с подпапками, кроме
// файла ASkipFile. В AOut: "файл|строка|1 - закомментировано, 0 - нет|
// текст строки". False - прервано.
function StrictFindDefinitions(const AName: string; ARoots: TStrings;
                               const ASkipFile: string; AOut: TStrings;
                               AProgress: TIncProgress): Boolean;

// Как подключить AIncFile к программе AMainLines (папка AMainDir, папка
// -I AIncDir): закомментированный $INCLUDE этого файла - раскомментировать
// (AInsert = False, ALineNo - его строка с 1, AOld - как есть, ANew -
// без комментария); иначе - новая строка $INCLUDE после последнего
// $INCLUDE в начале программы (AInsert = True, ALineNo - перед какой
// строкой). Путь - относительно папки -I или программы, если файл в ней.
procedure StrictIncludePlan(AMainLines: TStrings;
                            const AIncFile, AMainDir, AIncDir: string;
                            var ALineNo: Integer; var AOld, ANew: string;
                            var AInsert: Boolean);

// Пояснение к ошибке: причина и что можно сделать. ALines - текст файла
// ошибки (nil - не прочитан).
function StrictExplain(AErr: TStrictError; ALines: TStrings): string;

implementation

const
  IdentStart = ['A'..'Z', 'a'..'z', '_'];
  IdentChars = ['A'..'Z', 'a'..'z', '0'..'9', '_'];

// Первое слово (буквы, цифры, _) с позиции APos; APos - за ним
function WordAt(const AText: string; var APos: Integer): string;
var
  StartPos: Integer;
begin
  while (APos <= Length(AText)) and (AText[APos] in [' ', #9]) do
    Inc(APos);
  StartPos := APos;
  while (APos <= Length(AText)) and (AText[APos] in IdentChars) do
    Inc(APos);
  Result := Copy(AText, StartPos, APos - StartPos);
end;

function StrictParseError(const AMsg: string): TStrictError;
var
  ErrPos, OpenPos, CharIdx, ColonPos: Integer;
  Head, Body, Rest: string;
begin
  Result := nil;
  ErrPos := Pos(') Error: ', AMsg);
  if ErrPos = 0 then
    Exit;
  Head := Copy(AMsg, 1, ErrPos);          // "файл(строка)"
  Body := Copy(AMsg, ErrPos + 9, MaxInt);
  OpenPos := 0;
  for CharIdx := Length(Head) downto 1 do
    if Head[CharIdx] = '(' then
    begin
      OpenPos := CharIdx;
      Break;
    end;
  if OpenPos = 0 then
    Exit;
  Result := TStrictError.Create;
  Result.FileName := Trim(Copy(Head, 1, OpenPos - 1));
  Result.Line := StrToIntDef(Copy(Head, OpenPos + 1,
                                  Length(Head) - OpenPos - 1), 0);
  Result.Text := Body;
  Result.Kind := skOther;

  // "Имя.Член: Имя не объявлен - ни переменной, ни объектом (DIM, CREATE)"
  if Pos(' не объявлен - ни переменной, ни объектом', Body) > 0 then
  begin
    CharIdx := 1;
    Result.Name := WordAt(Body, CharIdx);
    if (CharIdx <= Length(Body)) and (Body[CharIdx] = '.') then
    begin
      Inc(CharIdx);
      Result.Member := WordAt(Body, CharIdx);
    end;
    if Result.Name <> '' then
      Result.Kind := skUndeclared;
    Exit;
  end;

  // "goto метка: метка в другой процедуре (места) - ..." и
  // "goto метка: метки метка нет"
  CharIdx := 1;
  Result.Statement := WordAt(Body, CharIdx);
  if (CompareText(Result.Statement, 'GOTO') = 0) or
     (CompareText(Result.Statement, 'GOSUB') = 0) then
  begin
    Result.Name := WordAt(Body, CharIdx);
    Rest := Copy(Body, CharIdx, MaxInt);
    if Pos(': метка в другой процедуре (', Rest) = 1 then
    begin
      Result.Kind := skLabelElsewhere;
      Rest := Copy(Rest, Length(': метка в другой процедуре (') + 1, MaxInt);
      ColonPos := Pos(') - ', Rest);
      if ColonPos > 0 then
        Result.Places := Copy(Rest, 1, ColonPos - 1)
      else
        Result.Places := Rest;
    end
    else if Pos(': метки ', Rest) = 1 then
      Result.Kind := skLabelMissing;
  end;
end;

// Первое слово строки кода в верхнем регистре и остаток (без ведущих
// пробелов); комментарий ' / REM - пусто
function LineHead(const ALine: string; var ARest: string): string;
var
  CharPos: Integer;
begin
  ARest := '';
  CharPos := 1;
  Result := UpperCase(WordAt(ALine, CharPos));
  if Result = 'REM' then
  begin
    Result := '';
    Exit;
  end;
  ARest := TrimLeft(Copy(ALine, CharPos, MaxInt));
end;

function IsProcStart(const ALine: string; var AName: string): Boolean;
var
  Head, Rest, Tail: string;
  CharPos: Integer;
begin
  Result := False;
  Head := LineHead(ALine, Rest);
  if (Head = 'PUBLIC') or (Head = 'PRIVATE') or (Head = 'STATIC') then
  begin
    // своя переменная для остатка: Rest - и вход, и выход нельзя
    Head := LineHead(Rest, Tail);
    Rest := Tail;
  end;
  if (Head = 'SUB') or (Head = 'FUNCTION') or (Head = 'SUBI') or
     (Head = 'FUNCTIONI') then
  begin
    CharPos := 1;
    AName := WordAt(Rest, CharPos);
    Result := AName <> '';
  end;
end;

function IsProcEnd(const ALine: string): Boolean;
var
  Head, Rest, Tail: string;
begin
  Head := LineHead(ALine, Rest);
  Result := False;
  if Head = 'END' then
  begin
    Head := LineHead(Rest, Tail);
    Result := (Head = 'SUB') or (Head = 'FUNCTION') or (Head = 'SUBI') or
              (Head = 'FUNCTIONI');
  end;
end;

function StrictProcAt(ALines: TStrings; ALineIdx: Integer;
                      var AFirst, ALast: Integer; var AName: string): Boolean;
var
  LineIdx: Integer;
  ProcName: string;
begin
  Result := False;
  AFirst := -1;
  ALast := -1;
  AName := '';
  if (ALines = nil) or (ALineIdx < 0) or (ALineIdx >= ALines.Count) then
    Exit;
  for LineIdx := ALineIdx downto 0 do
  begin
    if (LineIdx < ALineIdx) and IsProcEnd(ALines[LineIdx]) then
      Exit;
    if IsProcStart(ALines[LineIdx], ProcName) then
    begin
      AFirst := LineIdx;
      AName := ProcName;
      Break;
    end;
  end;
  if AFirst < 0 then
    Exit;
  ALast := ALines.Count - 1;
  for LineIdx := ALineIdx to ALines.Count - 1 do
    if IsProcEnd(ALines[LineIdx]) then
    begin
      ALast := LineIdx;
      Break;
    end;
  Result := True;
end;

procedure StrictLabelsIn(ALines: TStrings; AFirst, ALast: Integer;
                         ALabels: TStrings);
const
  NotLabels: array[0..4] of string = ('ELSE', 'END', 'CASE', 'DEFAULT', 'REM');
var
  LineIdx, CharPos, WordIdx: Integer;
  Line, Name: string;
  IsKeyword: Boolean;
begin
  if AFirst < 0 then
    AFirst := 0;
  if ALast >= ALines.Count then
    ALast := ALines.Count - 1;
  for LineIdx := AFirst to ALast do
  begin
    Line := ALines[LineIdx];
    CharPos := 1;
    while (CharPos <= Length(Line)) and (Line[CharPos] in [' ', #9]) do
      Inc(CharPos);
    if (CharPos > Length(Line)) or not (Line[CharPos] in IdentStart) then
      Continue;
    Name := WordAt(Line, CharPos);
    // "метка:" - двоеточие сразу за именем (у "Имя :" в RapidQ - тоже)
    while (CharPos <= Length(Line)) and (Line[CharPos] in [' ', #9]) do
      Inc(CharPos);
    if (CharPos > Length(Line)) or (Line[CharPos] <> ':') then
      Continue;
    IsKeyword := False;
    for WordIdx := Low(NotLabels) to High(NotLabels) do
      if CompareText(Name, NotLabels[WordIdx]) = 0 then
        IsKeyword := True;
    if not IsKeyword then
      ALabels.Add(Name + '=' + IntToStr(LineIdx + 1));
  end;
end;

// Сколько правок (вставка, удаление, замена буквы) между строками
function EditDistance(const AFirst, ASecond: string): Integer;
var
  Prev, Cur: array of Integer;
  RowIdx, ColIdx, Cost: Integer;
begin
  SetLength(Prev, Length(ASecond) + 1);
  SetLength(Cur, Length(ASecond) + 1);
  for ColIdx := 0 to Length(ASecond) do
    Prev[ColIdx] := ColIdx;
  for RowIdx := 1 to Length(AFirst) do
  begin
    Cur[0] := RowIdx;
    for ColIdx := 1 to Length(ASecond) do
    begin
      if UpCase(AFirst[RowIdx]) = UpCase(ASecond[ColIdx]) then
        Cost := 0
      else
        Cost := 1;
      Cur[ColIdx] := Prev[ColIdx - 1] + Cost;
      if Prev[ColIdx] + 1 < Cur[ColIdx] then
        Cur[ColIdx] := Prev[ColIdx] + 1;
      if Cur[ColIdx - 1] + 1 < Cur[ColIdx] then
        Cur[ColIdx] := Cur[ColIdx - 1] + 1;
    end;
    for ColIdx := 0 to Length(ASecond) do
      Prev[ColIdx] := Cur[ColIdx];
  end;
  Result := Prev[Length(ASecond)];
end;

procedure StrictSimilarLabels(const ALabel: string; ALabels, AOut: TStrings);
var
  Dist, LabelIdx: Integer;
  Name, UpLabel, UpName: string;
begin
  UpLabel := UpperCase(ALabel);
  for Dist := 1 to 3 do
    for LabelIdx := 0 to ALabels.Count - 1 do
    begin
      Name := ALabels.Names[LabelIdx];
      UpName := UpperCase(Name);
      if (UpName = UpLabel) or (AOut.IndexOfName(Name) >= 0) then
        Continue;
      // 1, 2 - буквы; 3 - одна метка - начало другой (w8 и w8file)
      if ((Dist <= 2) and (EditDistance(UpName, UpLabel) = Dist)) or
         ((Dist = 3) and (Length(UpLabel) >= 3) and (Length(UpName) >= 3) and
          ((Pos(UpLabel, UpName) = 1) or (Pos(UpName, UpLabel) = 1))) then
        AOut.Add(ALabels[LabelIdx]);
    end;
end;

function StrictReplaceGoto(const ALine, AOld, ANew: string;
                           var AResult: string): Boolean;
var
  UpLine, Keyword: string;
  KwIdx, KwPos, NamePos, CharPos: Integer;
begin
  Result := False;
  AResult := ALine;
  UpLine := UpperCase(ALine);
  for KwIdx := 0 to 1 do
  begin
    if KwIdx = 0 then
      Keyword := 'GOTO'
    else
      Keyword := 'GOSUB';
    KwPos := Pos(Keyword, UpLine);
    while KwPos > 0 do
    begin
      if ((KwPos = 1) or not (UpLine[KwPos - 1] in IdentChars)) and
         ((KwPos + Length(Keyword) > Length(UpLine)) or
          not (UpLine[KwPos + Length(Keyword)] in IdentChars)) then
      begin
        CharPos := KwPos + Length(Keyword);
        while (CharPos <= Length(UpLine)) and (UpLine[CharPos] in [' ', #9]) do
          Inc(CharPos);
        NamePos := CharPos;
        if (CompareText(Copy(ALine, NamePos, Length(AOld)), AOld) = 0) and
           ((NamePos + Length(AOld) > Length(ALine)) or
            not (ALine[NamePos + Length(AOld)] in IdentChars)) then
        begin
          AResult := Copy(ALine, 1, NamePos - 1) + ANew +
                     Copy(ALine, NamePos + Length(AOld), MaxInt);
          Result := True;
          Exit;
        end;
      end;
      // следующее вхождение
      CharPos := Pos(Keyword, Copy(UpLine, KwPos + 1, MaxInt));
      if CharPos = 0 then
        KwPos := 0
      else
        KwPos := KwPos + CharPos;
    end;
  end;
end;

// Строка - объявление AUpName: [' ...] DIM / CREATE Имя ... ;
// ACommented - перед ним комментарий
function IsDefinition(const ALine, AUpName: string;
                      var ACommented: Boolean): Boolean;
var
  CharPos: Integer;
  Code, Kw: string;
begin
  Result := False;
  ACommented := False;
  Code := TrimLeft(ALine);
  // ' и !!! перед строкой - закомментированное объявление
  while (Code <> '') and (Code[1] in ['''', '!', ' ', #9]) do
  begin
    if Code[1] = '''' then
      ACommented := True;
    Delete(Code, 1, 1);
  end;
  CharPos := 1;
  Kw := UpperCase(WordAt(Code, CharPos));
  if Kw = 'REM' then
  begin
    ACommented := True;
    Kw := UpperCase(WordAt(Code, CharPos));
  end;
  if (Kw <> 'DIM') and (Kw <> 'CREATE') then
    Exit;
  Result := UpperCase(WordAt(Code, CharPos)) = AUpName;
end;

function StrictFindDefinitions(const AName: string; ARoots: TStrings;
                               const ASkipFile: string; AOut: TStrings;
                               AProgress: TIncProgress): Boolean;
const
  MaxSize = 4 * 1024 * 1024;
var
  Masks, Files, Lines: TStringList;
  FileIdx, LineIdx: Integer;
  Commented, Cancel: Boolean;
  UpName: string;
  Info: TSearchRec;
begin
  UpName := UpperCase(AName);
  Masks := TStringList.Create;
  Files := TStringList.Create;
  Lines := TStringList.Create;
  try
    Masks.Sorted := True;
    Masks.Add('*.INC');
    Masks.Add('*.BAS');
    Masks.Add('*.CMP');
    Files.Sorted := True;
    Files.Duplicates := dupIgnore;
    Result := IncFindNamesOnDisk(Masks, ARoots, Files, AProgress);
    if not Result then
      Exit;
    for FileIdx := 0 to Files.Count - 1 do
    begin
      if CompareText(ExpandFileName(Files[FileIdx]),
                     ExpandFileName(ASkipFile)) = 0 then
        Continue;
      if FindFirst(Files[FileIdx], faAnyFile, Info) = 0 then
      try
        if Info.Size > MaxSize then
          Continue;
      finally
        FindClose(Info);
      end;
      if Assigned(AProgress) then
      begin
        Cancel := False;
        AProgress('Чтение: ' + Files[FileIdx], Cancel);
        if Cancel then
        begin
          Result := False;
          Exit;
        end;
      end;
      try
        Lines.LoadFromFile(Files[FileIdx]);
      except
        Continue;
      end;
      for LineIdx := 0 to Lines.Count - 1 do
        if (Pos(UpName, UpperCase(Lines[LineIdx])) > 0) and
           IsDefinition(Lines[LineIdx], UpName, Commented) then
          AOut.Add(Files[FileIdx] + '|' + IntToStr(LineIdx + 1) + '|' +
                   IntToStr(Ord(Commented)) + '|' + Trim(Lines[LineIdx]));
    end;
  finally
    Lines.Free;
    Files.Free;
    Masks.Free;
  end;
end;

// Имя файла из строки $INCLUDE "имя" (с комментарием перед ней или без);
// '' - не $INCLUDE. ACommented - строка закомментирована, AIncPos -
// позиция "$INCLUDE" в строке
function IncludeOfLine(const ALine: string; var ACommented: Boolean;
                       var AIncPos: Integer): string;
var
  UpLine: string;
  QuotePos, EndPos, CharIdx: Integer;
begin
  Result := '';
  ACommented := False;
  UpLine := UpperCase(ALine);
  AIncPos := Pos('$INCLUDE', UpLine);
  if AIncPos = 0 then
    Exit;
  for CharIdx := 1 to AIncPos - 1 do
    if ALine[CharIdx] = '''' then
      ACommented := True
    else if not (ALine[CharIdx] in [' ', #9, '!']) then
    begin
      // перед $INCLUDE - код или текст: не строка подключения
      if not ACommented then
        Exit;
    end;
  QuotePos := Pos('"', Copy(ALine, AIncPos, MaxInt));
  if QuotePos = 0 then
  begin
    QuotePos := Pos('<', Copy(ALine, AIncPos, MaxInt));
    if QuotePos = 0 then
      Exit;
  end;
  QuotePos := AIncPos + QuotePos;   // первый знак имени
  EndPos := QuotePos;
  while (EndPos <= Length(ALine)) and not (ALine[EndPos] in ['"', '>']) do
    Inc(EndPos);
  Result := Copy(ALine, QuotePos, EndPos - QuotePos);
end;

function RelativeTo(const AFile, ADir: string): string;
var
  DirSlash: string;
begin
  Result := '';
  if ADir = '' then
    Exit;
  DirSlash := IncludeTrailingPathDelimiter(ExpandFileName(ADir));
  if CompareText(Copy(ExpandFileName(AFile), 1, Length(DirSlash)),
                 DirSlash) = 0 then
    Result := Copy(ExpandFileName(AFile), Length(DirSlash) + 1, MaxInt);
end;

procedure StrictIncludePlan(AMainLines: TStrings;
                            const AIncFile, AMainDir, AIncDir: string;
                            var ALineNo: Integer; var AOld, ANew: string;
                            var AInsert: Boolean);
var
  LineIdx, IncPos, LastInclude: Integer;
  IncName, RelName, Lead, ProcName: string;
  Commented, InHead: Boolean;
begin
  ALineNo := 0;
  AOld := '';
  ANew := '';
  AInsert := True;
  LastInclude := -1;
  InHead := True;
  for LineIdx := 0 to AMainLines.Count - 1 do
  begin
    // Новая строка встанет в начале программы - до первой процедуры
    if InHead and IsProcStart(AMainLines[LineIdx], ProcName) then
      InHead := False;
    IncName := IncludeOfLine(AMainLines[LineIdx], Commented, IncPos);
    if IncName = '' then
      Continue;
    if not Commented and InHead then
      LastInclude := LineIdx;
    // Этот файл уже был подключён и закомментирован - вернуть строку
    if Commented and (CompareText(ExtractFileName(IncName),
                                  ExtractFileName(AIncFile)) = 0) then
    begin
      AInsert := False;
      ALineNo := LineIdx + 1;
      AOld := AMainLines[LineIdx];
      Lead := '';
      while (Length(Lead) < Length(AOld)) and
            (AOld[Length(Lead) + 1] in [' ', #9]) do
        Lead := Lead + AOld[Length(Lead) + 1];
      ANew := Lead + Copy(AOld, IncPos, MaxInt);
      Exit;
    end;
  end;
  // Новая строка - за последним действующим $INCLUDE (или первой строкой)
  RelName := RelativeTo(AIncFile, AIncDir);
  if RelName = '' then
    RelName := RelativeTo(AIncFile, AMainDir);
  if RelName = '' then
    RelName := AIncFile;
  ANew := '$INCLUDE "' + RelName + '"';
  ALineNo := LastInclude + 2;   // перед строкой за последним $INCLUDE
end;

function StrictExplain(AErr: TStrictError; ALines: TStrings): string;
var
  First, Last, LabelIdx: Integer;
  ProcName: string;
  Labels, Similar: TStringList;
begin
  case AErr.Kind of
    skUndeclared:
      Result := AErr.Name + ' используется как объект (' + AErr.Name + '.' +
        AErr.Member + '), но ни в программе, ни в подключённых ею файлах нет ' +
        'DIM ' + AErr.Name + ' или CREATE ' + AErr.Name + '.'#13#10 +
        'rc.exe это пропускает: при $TypeCheck off имя без объявления ' +
        'разрешено. Но объекта с таким именем в программе нет, и что вернёт ' +
        AErr.Name + '.' + AErr.Member + ', не известно.'#13#10#13#10 +
        'Что сделать: "Найти определение" ищет DIM / CREATE ' + AErr.Name +
        ' в .inc, .bas, .cmp папок Include, программы (с подпапками) и ' +
        'папки выше. Найденный файл можно подключить: закомментированный ' +
        '$INCLUDE этого файла в программе раскомментируется, иначе ' +
        'добавляется строка $INCLUDE. Подключается весь файл - с ним придут ' +
        'и другие его объявления. Если код с ' + AErr.Name + ' не нужен - ' +
        'уберите его.';
    skLabelElsewhere, skLabelMissing:
      begin
        if AErr.Kind = skLabelElsewhere then
          Result := AErr.Statement + ' ' + AErr.Name + ' ведёт в другую ' +
            'процедуру: метка ' + AErr.Name + ': - ' + AErr.Places + '.'#13#10 +
            'В RapidQ метки общие для всей программы, и rc.exe такой переход ' +
            'принимает: выполнение уходит в середину чужой процедуры, а ' +
            'параметры и локальные переменные остаются от этой. В FreeBASIC ' +
            'метка видна только в своей SUB/FUNCTION.'
        else
          Result := AErr.Statement + ' ' + AErr.Name + ': метки ' + AErr.Name +
            ' нет нигде в программе.';
        Labels := TStringList.Create;
        Similar := TStringList.Create;
        try
          if (ALines <> nil) and
             StrictProcAt(ALines, AErr.Line - 1, First, Last, ProcName) then
          begin
            Result := Result + #13#10'Переход стоит в процедуре ' + ProcName +
                      ' (строки ' + IntToStr(First + 1) + '-' +
                      IntToStr(Last + 1) + ').';
            StrictLabelsIn(ALines, First, Last, Labels);
            StrictSimilarLabels(AErr.Name, Labels, Similar);
          end;
          if Similar.Count > 0 then
          begin
            Result := Result + #13#10#13#10'В этой процедуре есть похожая ' +
              'метка - возможно, опечатка:';
            for LabelIdx := 0 to Similar.Count - 1 do
              Result := Result + #13#10'  ' + Similar.Names[LabelIdx] +
                ': (строка ' + Similar.ValueFromIndex[LabelIdx] + ')';
            Result := Result + #13#10'"Заменить" ставит в ' +
              AErr.Statement + ' первую из них. Проверьте, что переход ' +
              'должен идти именно туда.';
          end
          else
            Result := Result + #13#10#13#10'Похожей метки в этой процедуре ' +
              'нет - не могу предложить вариант исправления. Варианты ' +
              'вручную: поставить свою метку в этой процедуре или вынести ' +
              'общий код в отдельную SUB и вызывать её из обеих процедур.';
        finally
          Similar.Free;
          Labels.Free;
        end;
      end;
  else
    Result := 'Не могу предложить вариант исправления.'#13#10#13#10 +
      'Ошибка перевода RqToFb (режим FB Smart): ' + AErr.Text;
  end;
end;

end.
