unit StrictFix;

// ---------------------------------------------------------------------------
//  Разбор лога строгой проверки (перевод RqToFb, режим FB Smart, перед
//  rc.exe) и варианты исправления - без VCL; окно - DlgStrictFix.
//
//  Цель - места, которые rc.exe пропускает, но из-за которых программа
//  может работать не так. В логе перевода они двух уровней:
//   - Error - ошибки программы (GOTO в чужую процедуру, объект без
//     DIM / CREATE, CASE > 5 вместо CASE IS > 5 ...). Среди Error есть и
//     ограничения самого перевода (RETURN с меткой, CALLFUNC, QUICKSORT ...):
//     для rc.exe это правильный код - они отделяются (skLimit) и ни в окно,
//     ни в решение "собирать или нет" не идут;
//   - Suspect - подозрения: переменная нигде не получает значения, строка в
//     число, DECLARE без тела, повторное объявление...
//  Warning - подробности перевода, к rc.exe отношения не имеют.
//
//  Варианты: найти определение (DIM / CREATE, тело SUB / FUNCTION) в
//  других файлах и подключить файл ($INCLUDE: раскомментировать или
//  добавить); похожее имя (метка, переменная, процедура) - заменить им;
//  CASE > x - CASE IS > x. Где вариантов нет - пояснение и "не могу
//  предложить вариант исправления".
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes,
  IncCheck;     // IncFindNamesOnDisk, TIncProgress

type
  TStrictLevel = (slError, slSuspect);

  TStrictKind = (
    skOther,            // предложить нечего
    skLimit,            // ограничение перевода - для rc.exe не важно
    // ошибки программы
    skUndeclared,       // Объект.Член без DIM / CREATE
    skUndeclaredVar,    // переменная без DIM при $TYPECHECK ON
    skLabelElsewhere,   // GOTO / GOSUB в чужую процедуру
    skLabelMissing,     // метки нет
    skCaseOp,           // CASE > x вместо CASE IS > x
    skBlock,            // блок не закрыт / лишний конец блока
    skBindNoProc,       // BIND ... TO нет такой SUB
    skTypeDefined,      // TYPE объявлен дважды
    skIncludeMissing,   // $INCLUDE: файл не найден
    // подозрения
    skSusNoValue,       // не объявлена и нигде не получает значение
    skSusImplicit,      // Объект.Член без объявления - неявная переменная
    skSusTrueFalse,     // TRUE / FALSE без RAPIDQ.INC и CONST
    skSusStrNum,        // строка в число / число в строку
    skSusNoBody,        // DECLARE без тела
    skSusDeclParams,    // параметры в DECLARE и в заголовке разные
    skSusDefined);      // повторное объявление, повторный $DEFINE

  TStrictError = class
  public
    Level: TStrictLevel;
    FileName: string;   // как в сообщении (полный путь)
    Line: Integer;      // с 1
    Text: string;       // текст после "Error: " / "Suspect: "
    Kind: TStrictKind;
    Name: string;       // имя объекта, метки, переменной, процедуры
    Member: string;     // skUndeclared: свойство / метод
    Places: string;     // skLabelElsewhere: где метка
    Statement: string;  // GOTO / GOSUB; SUB / FUNCTION (skSusNoBody)
    OtherFile: string;  // первое объявление (skTypeDefined, skSusDefined)
    OtherLine: Integer;
  end;

// Строка лога перевода "файл(строка) Error: текст" или "... Suspect: ..." -
// разобранная запись; nil - другая строка (Warning, итог, прочее)
function StrictParseMessage(const AMsg: string): TStrictError;
// Совместимость: только Error
function StrictParseError(const AMsg: string): TStrictError;

// Процедура (SUB / FUNCTION), в которой строка ALineIdx (с 0): первая и
// последняя её строки, имя. False - строка вне процедур.
function StrictProcAt(ALines: TStrings; ALineIdx: Integer;
                      var AFirst, ALast: Integer; var AName: string): Boolean;

// Метки строк AFirst..ALast (с 0): "Имя=номер строки с 1"
procedure StrictLabelsIn(ALines: TStrings; AFirst, ALast: Integer;
                         ALabels: TStrings);

// Имена программы для поиска похожего: AProcs - SUB / FUNCTION (с телом и
// DECLARE), иначе переменные - DIM и "Имя = ..." в начале оператора.
// "Имя=номер строки с 1", первое место.
procedure StrictNamesIn(ALines: TStrings; AProcs: Boolean; ANames: TStrings);

// Имена из ANames, похожие на AName (до двух букв разницы, у коротких -
// одна; или одно - начало другого): в AOut "Имя=строка", ближайшие первыми
procedure StrictSimilarNames(const AName: string; ANames, AOut: TStrings);
procedure StrictSimilarLabels(const ALabel: string; ALabels, AOut: TStrings);

// В строке ALine GOTO / GOSUB AOld заменить на ANew. False - не нашлось.
function StrictReplaceGoto(const ALine, AOld, ANew: string;
                           var AResult: string): Boolean;
// Первое вхождение слова AOld (вне строк "..." и комментария) - на ANew
function StrictReplaceWord(const ALine, AOld, ANew: string;
                           var AResult: string): Boolean;
// CASE > x -> CASE IS > x (и <, <=, >=, <>)
function StrictFixCase(const ALine: string; var AResult: string): Boolean;

// Определение AName в .inc, .bas, .cmp папок ARoots с подпапками, кроме
// ASkipFile: AProc - SUB / FUNCTION AName с телом, иначе DIM, CREATE,
// CONST, $DEFINE, DEFxxx (IsDefinition).
// В AOut: "файл|строка|1 - закомментировано, 0 - нет|текст строки".
// AExts - расширения через ";" (".inc;.bas;.cmp"); '' - эти три.
// False - прервано.
function StrictFindDefinitions(const AName: string; AProc: Boolean;
                               ARoots: TStrings; const ASkipFile: string;
                               AOut: TStrings; AProgress: TIncProgress;
                               const AExts: string = ''): Boolean;

// Как подключить AIncFile к программе AMainLines (см. реализацию):
// закомментированный $INCLUDE этого файла - раскомментировать (AInsert =
// False), иначе новая строка $INCLUDE после последнего $INCLUDE в начале
// программы (AInsert = True, ALineNo - перед какой строкой)
procedure StrictIncludePlan(AMainLines: TStrings;
                            const AIncFile, AMainDir, AIncDir: string;
                            var ALineNo: Integer; var AOld, ANew: string;
                            var AInsert: Boolean);

// Пояснение: причина и что можно сделать. ALines - текст файла ошибки
// (nil - не прочитан).
function StrictExplain(AErr: TStrictError; ALines: TStrings): string;

// Нужен ли поиск определения в других файлах; ищется процедура или DIM
function StrictNeedsSearch(AErr: TStrictError; var AProc: Boolean): Boolean;

implementation

const
  IdentStart = ['A'..'Z', 'a'..'z', '_'];
  IdentChars = ['A'..'Z', 'a'..'z', '0'..'9', '_'];
  TypeSuffix = ['$', '%', '&', '!', '#', '?'];

// Слово (буквы, цифры, _) с позиции APos, пробелы перед ним пропускаются;
// APos - за ним. AWithSuffix - и знак типа на конце ($ % & ! # ?)
function WordAt(const AText: string; var APos: Integer;
                AWithSuffix: Boolean = False): string;
var
  StartPos: Integer;
begin
  while (APos <= Length(AText)) and (AText[APos] in [' ', #9]) do
    Inc(APos);
  StartPos := APos;
  while (APos <= Length(AText)) and (AText[APos] in IdentChars) do
    Inc(APos);
  if AWithSuffix and (APos > StartPos) and (APos <= Length(AText)) and
     (AText[APos] in TypeSuffix) then
    Inc(APos);
  Result := Copy(AText, StartPos, APos - StartPos);
end;

function StartsText(const APrefix, AText: string): Boolean;
begin
  Result := CompareText(Copy(AText, 1, Length(APrefix)), APrefix) = 0;
end;

// "путь(строка)" -> путь и строка
procedure SplitPlace(const APlace: string; var AFile: string;
                     var ALine: Integer);
var
  CharIdx: Integer;
  Place: string;
begin
  AFile := '';
  ALine := 0;
  Place := Trim(APlace);
  for CharIdx := Length(Place) downto 1 do
    if Place[CharIdx] = '(' then
    begin
      AFile := Trim(Copy(Place, 1, CharIdx - 1));
      ALine := StrToIntDef(Copy(Place, CharIdx + 1,
                                Pos(')', Copy(Place, CharIdx, MaxInt)) - 2), 0);
      Exit;
    end;
end;

// Подстрока между AFrom и ATill (ATill = '' - до конца)
function Between(const AText, AFrom, ATill: string): string;
var
  FromPos, TillPos: Integer;
begin
  Result := '';
  FromPos := Pos(AFrom, AText);
  if FromPos = 0 then
    Exit;
  Result := Copy(AText, FromPos + Length(AFrom), MaxInt);
  if ATill <> '' then
  begin
    TillPos := Pos(ATill, Result);
    if TillPos > 0 then
      Result := Copy(Result, 1, TillPos - 1);
  end;
end;

procedure ParseErrorKind(AErr: TStrictError);
var
  Body, Rest: string;
  CharIdx: Integer;
begin
  Body := AErr.Text;
  // Ограничения перевода: для rc.exe это правильный код
  if (Pos('пока не поддержан', Body) > 0) or StartsText('CALLFUNC', Body) or
     StartsText('QUICKSORT', Body) or StartsText('INITARRAY', Body) or
     (Pos('папка вывода совпадает', Body) > 0) or
     StartsText('не удалось записать', Body) or
     StartsText('не удалось прочитать', Body) or
     StartsText('перевод остановлен', Body) then
  begin
    AErr.Kind := skLimit;
    Exit;
  end;
  if Pos(' не объявлен - ни переменной, ни объектом', Body) > 0 then
  begin
    CharIdx := 1;
    AErr.Name := WordAt(Body, CharIdx);
    if (CharIdx <= Length(Body)) and (Body[CharIdx] = '.') then
    begin
      Inc(CharIdx);
      AErr.Member := WordAt(Body, CharIdx, True);
    end;
    if AErr.Name <> '' then
      AErr.Kind := skUndeclared;
    Exit;
  end;
  if Pos(': переменная не объявлена ($TYPECHECK ON)', Body) > 0 then
  begin
    CharIdx := 1;
    AErr.Name := WordAt(Body, CharIdx, True);
    AErr.Kind := skUndeclaredVar;
    Exit;
  end;
  if StartsText('CASE ', Body) and (Pos('в RapidQ это не сравнение', Body) > 0) then
  begin
    AErr.Kind := skCaseOp;
    Exit;
  end;
  if (Body = '$ELSE без $IFDEF') or (Body = '$ENDIF без $IFDEF') or
     (Body = '$IFDEF без $ENDIF') or (Pos(' без END TYPE', Body) > 0) or
     (Pos(' без END CREATE', Body) > 0) or (Body = 'нет $ENDIF') then
  begin
    AErr.Kind := skBlock;
    Exit;
  end;
  if StartsText('BIND ... TO ', Body) and
     (Pos(': нет такой SUB или FUNCTION', Body) > 0) then
  begin
    CharIdx := Length('BIND ... TO ') + 1;
    AErr.Name := WordAt(Body, CharIdx, True);
    AErr.Kind := skBindNoProc;
    Exit;
  end;
  if StartsText('TYPE ', Body) and (Pos('already defined - уже объявлен в ', Body) > 0) then
  begin
    CharIdx := 6;
    AErr.Name := WordAt(Body, CharIdx);
    SplitPlace(Between(Body, 'уже объявлен в ', ';'), AErr.OtherFile,
               AErr.OtherLine);
    AErr.Kind := skTypeDefined;
    Exit;
  end;
  if StartsText('$INCLUDE: файл не найден: ', Body) then
  begin
    AErr.Name := Trim(Copy(Body, Length('$INCLUDE: файл не найден: ') + 1, MaxInt));
    AErr.Kind := skIncludeMissing;
    Exit;
  end;
  // "goto метка: метка в другой процедуре (места) - ..." / "...: метки X нет"
  CharIdx := 1;
  AErr.Statement := WordAt(Body, CharIdx);
  if (CompareText(AErr.Statement, 'GOTO') = 0) or
     (CompareText(AErr.Statement, 'GOSUB') = 0) then
  begin
    AErr.Name := WordAt(Body, CharIdx);
    Rest := Copy(Body, CharIdx, MaxInt);
    if Pos(': метка в другой процедуре (', Rest) = 1 then
    begin
      AErr.Kind := skLabelElsewhere;
      AErr.Places := Between(Rest, ': метка в другой процедуре (', ') - ');
    end
    else if Pos(': метки ', Rest) = 1 then
      AErr.Kind := skLabelMissing;
  end;
end;

procedure ParseSuspectKind(AErr: TStrictError);
var
  Body: string;
  CharIdx: Integer;
begin
  Body := AErr.Text;
  CharIdx := 1;
  // "... и здесь не получает значение" - то же, а одноимённой в другой SUB
  // значение присваивается (RqToFb, AssignedElsewhere)
  if (Pos('не объявлена и нигде не получает значение', Body) > 0) or
     (Pos('не объявлена и здесь не получает значение', Body) > 0) then
  begin
    AErr.Name := WordAt(Body, CharIdx, True);
    AErr.Kind := skSusNoValue;
  end
  else if Pos(' не объявлен - переведено как неявная переменная', Body) > 0 then
  begin
    AErr.Name := WordAt(Body, CharIdx);
    if (CharIdx <= Length(Body)) and (Body[CharIdx] = '.') then
    begin
      Inc(CharIdx);
      AErr.Member := WordAt(Body, CharIdx, True);
    end;
    AErr.Kind := skSusImplicit;
  end
  else if Pos(': не определено (нет $INCLUDE "RAPIDQ.INC" или CONST)', Body) > 0 then
  begin
    AErr.Name := WordAt(Body, CharIdx);
    AErr.Kind := skSusTrueFalse;
  end
  else if (Pos(': строка в числовую переменную', Body) > 0) or
          (Pos(': число в строковую переменную', Body) > 0) then
    AErr.Kind := skSusStrNum
  else if Pos(': объявлен (DECLARE), но тела в программе нет', Body) > 0 then
  begin
    AErr.Statement := WordAt(Body, CharIdx);
    AErr.Name := WordAt(Body, CharIdx, True);
    AErr.Kind := skSusNoBody;
  end
  else if Pos(': параметры в DECLARE (', Body) > 0 then
  begin
    AErr.Name := WordAt(Body, CharIdx, True);
    AErr.Kind := skSusDeclParams;
  end
  else if Pos(' already defined - первое объявление: ', Body) > 0 then
  begin
    SplitPlace(Between(Body, ' already defined - первое объявление: ', ''),
               AErr.OtherFile, AErr.OtherLine);
    AErr.Kind := skSusDefined;
  end
  else if StartsText('$DEFINE ', Body) and
          (Pos(' already defined - уже определён в ', Body) > 0) then
  begin
    CharIdx := 9;
    AErr.Name := WordAt(Body, CharIdx);
    SplitPlace(Between(Body, ' already defined - уже определён в ', ' как '),
               AErr.OtherFile, AErr.OtherLine);
    AErr.Kind := skSusDefined;
  end;
end;

function StrictParseMessage(const AMsg: string): TStrictError;
var
  LevelPos, OpenPos, CharIdx: Integer;
  Level: TStrictLevel;
  Head, Marker: string;
begin
  Result := nil;
  Marker := ') Error: ';
  Level := slError;
  LevelPos := Pos(Marker, AMsg);
  if LevelPos = 0 then
  begin
    Marker := ') Suspect: ';
    Level := slSuspect;
    LevelPos := Pos(Marker, AMsg);
  end;
  if LevelPos = 0 then
    Exit;
  Head := Copy(AMsg, 1, LevelPos);          // "файл(строка)"
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
  Result.Level := Level;
  Result.FileName := Trim(Copy(Head, 1, OpenPos - 1));
  Result.Line := StrToIntDef(Copy(Head, OpenPos + 1,
                                  Length(Head) - OpenPos - 1), 0);
  Result.Text := Copy(AMsg, LevelPos + Length(Marker), MaxInt);
  Result.Kind := skOther;
  if Level = slError then
    ParseErrorKind(Result)
  else
    ParseSuspectKind(Result);
end;

function StrictParseError(const AMsg: string): TStrictError;
begin
  Result := StrictParseMessage(AMsg);
  if (Result <> nil) and (Result.Level <> slError) then
    FreeAndNil(Result);
end;

// Первое слово строки кода в верхнем регистре и остаток (без ведущих
// пробелов); комментарий REM - пусто
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
    AName := WordAt(Rest, CharPos, True);
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

procedure AddName(ANames: TStrings; const AName: string; ALine: Integer);
begin
  if (AName <> '') and (ANames.IndexOfName(AName) < 0) then
    ANames.Add(AName + '=' + IntToStr(ALine));
end;

procedure StrictNamesIn(ALines: TStrings; AProcs: Boolean; ANames: TStrings);
var
  LineIdx, CharPos, Depth: Integer;
  Line, Head, Rest, Tail, Name: string;
  InStr: Boolean;
begin
  for LineIdx := 0 to ALines.Count - 1 do
  begin
    Line := ALines[LineIdx];
    if AProcs then
    begin
      if IsProcStart(Line, Name) then
        AddName(ANames, Name, LineIdx + 1)
      else
      begin
        Head := LineHead(Line, Rest);
        if Head = 'DECLARE' then
        begin
          Head := LineHead(Rest, Tail);
          if (Head = 'SUB') or (Head = 'FUNCTION') or (Head = 'SUBI') or
             (Head = 'FUNCTIONI') then
          begin
            CharPos := 1;
            AddName(ANames, WordAt(Tail, CharPos, True), LineIdx + 1);
          end;
        end;
      end;
      Continue;
    end;
    Head := LineHead(Line, Rest);
    if Head = 'DIM' then
    begin
      // DIM a AS ..., b(10) AS ... - имена до AS, через запятые вне скобок
      CharPos := 1;
      repeat
        Name := WordAt(Rest, CharPos, True);
        AddName(ANames, Name, LineIdx + 1);
        Depth := 0;
        InStr := False;
        while (CharPos <= Length(Rest)) and
              ((Rest[CharPos] <> ',') or (Depth > 0) or InStr) do
        begin
          if Rest[CharPos] = '"' then
            InStr := not InStr
          else if not InStr and (Rest[CharPos] = '(') then
            Inc(Depth)
          else if not InStr and (Rest[CharPos] = ')') then
            Dec(Depth)
          else if not InStr and (Rest[CharPos] = '''') then
            CharPos := Length(Rest);
          Inc(CharPos);
        end;
        Inc(CharPos);
      until CharPos > Length(Rest);
    end
    else
    begin
      // "Имя = ..." в начале оператора - имени присваивается значение
      CharPos := 1;
      Name := WordAt(Line, CharPos, True);
      if (Name <> '') and (Name[1] in IdentStart) then
      begin
        while (CharPos <= Length(Line)) and (Line[CharPos] in [' ', #9]) do
          Inc(CharPos);
        if (CharPos <= Length(Line)) and (Line[CharPos] = '=') then
          AddName(ANames, Name, LineIdx + 1);
      end;
    end;
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

procedure StrictSimilarNames(const AName: string; ANames, AOut: TStrings);
var
  Dist, NameIdx, MaxDist: Integer;
  Name, UpWanted, UpName: string;
begin
  UpWanted := UpperCase(AName);
  // У коротких имён (до 4 знаков) две буквы разницы - уже другое имя
  MaxDist := 2;
  if Length(UpWanted) <= 4 then
    MaxDist := 1;
  for Dist := 1 to 3 do
    for NameIdx := 0 to ANames.Count - 1 do
    begin
      Name := ANames.Names[NameIdx];
      UpName := UpperCase(Name);
      if (UpName = UpWanted) or (AOut.IndexOfName(Name) >= 0) then
        Continue;
      // 1, 2 - буквы; 3 - одно имя - начало другого (crlf и crlfcrlf)
      if ((Dist <= MaxDist) and (EditDistance(UpName, UpWanted) = Dist)) or
         ((Dist = 3) and (Length(UpWanted) >= 3) and (Length(UpName) >= 3) and
          ((Pos(UpWanted, UpName) = 1) or (Pos(UpName, UpWanted) = 1))) then
        AOut.Add(ANames[NameIdx]);
    end;
end;

procedure StrictSimilarLabels(const ALabel: string; ALabels, AOut: TStrings);
begin
  StrictSimilarNames(ALabel, ALabels, AOut);
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
      CharPos := Pos(Keyword, Copy(UpLine, KwPos + 1, MaxInt));
      if CharPos = 0 then
        KwPos := 0
      else
        KwPos := KwPos + CharPos;
    end;
  end;
end;

function StrictReplaceWord(const ALine, AOld, ANew: string;
                           var AResult: string): Boolean;
var
  CharPos: Integer;
  InStr: Boolean;
begin
  Result := False;
  AResult := ALine;
  if AOld = '' then
    Exit;
  InStr := False;
  CharPos := 1;
  while CharPos <= Length(ALine) do
  begin
    if ALine[CharPos] = '"' then
      InStr := not InStr
    else if not InStr and (ALine[CharPos] = '''') then
      Exit
    else if not InStr and
            ((CharPos = 1) or not (ALine[CharPos - 1] in IdentChars + ['.'])) and
            (CompareText(Copy(ALine, CharPos, Length(AOld)), AOld) = 0) and
            ((CharPos + Length(AOld) > Length(ALine)) or
             not (ALine[CharPos + Length(AOld)] in IdentChars + TypeSuffix)) then
    begin
      AResult := Copy(ALine, 1, CharPos - 1) + ANew +
                 Copy(ALine, CharPos + Length(AOld), MaxInt);
      Result := True;
      Exit;
    end;
    Inc(CharPos);
  end;
end;

function StrictFixCase(const ALine: string; var AResult: string): Boolean;
var
  CharPos, KwPos: Integer;
  Head: string;
begin
  Result := False;
  AResult := ALine;
  CharPos := 1;
  while (CharPos <= Length(ALine)) and (ALine[CharPos] in [' ', #9]) do
    Inc(CharPos);
  KwPos := CharPos;
  Head := WordAt(ALine, CharPos);
  if CompareText(Head, 'CASE') <> 0 then
    Exit;
  while (CharPos <= Length(ALine)) and (ALine[CharPos] in [' ', #9]) do
    Inc(CharPos);
  if (CharPos > Length(ALine)) or not (ALine[CharPos] in ['<', '>']) then
    Exit;
  AResult := Copy(ALine, 1, KwPos + 3) + ' IS ' +
             TrimLeft(Copy(ALine, KwPos + 4, MaxInt));
  Result := True;
end;

// Имена списка через запятую с позиции APos: "A = 1, B AS LONG, C(10)" -
// первое слово каждой части. Запятые в скобках и в строках - не разделители.
function ListNames(const ACode: string; APos: Integer; ANames: TStrings): Boolean;
var
  Depth: Integer;
  InStr: Boolean;
  PartPos: Integer;
begin
  ANames.Clear;
  Depth := 0;
  InStr := False;
  PartPos := APos;
  ANames.Add(UpperCase(WordAt(ACode, PartPos, True)));
  while APos <= Length(ACode) do
  begin
    case ACode[APos] of
      '"': InStr := not InStr;
      '(': if not InStr then Inc(Depth);
      ')': if not InStr and (Depth > 0) then Dec(Depth);
      '''': if not InStr then Break;    // комментарий до конца строки
      ',':
        if not InStr and (Depth = 0) then
        begin
          PartPos := APos + 1;
          ANames.Add(UpperCase(WordAt(ACode, PartPos, True)));
        end;
    end;
    Inc(APos);
  end;
  Result := ANames.Count > 0;
end;

// Строка - объявление AUpName; ACommented - перед ним комментарий.
// AProc - SUB / FUNCTION Имя с телом (не DECLARE). Иначе - всё, что даёт
// имени значение или тип: DIM, CREATE, CONST (и PUBLIC / PRIVATE / GLOBAL
// перед ним, список через запятую), $DEFINE, DEFINT / DEFLNG / DEFSTR и
// прочие DEFxxx. Раньше - только DIM / CREATE, и константа из inc
// (CONST WS_CHILD = &H40000000) не находилась.
function IsDefinition(const ALine, AUpName: string; AProc: Boolean;
                      var ACommented: Boolean): Boolean;
var
  CharPos: Integer;
  Code, Kw, Name: string;
  Names: TStringList;
  SavePos: Integer;
begin
  Result := False;
  ACommented := False;
  Code := TrimLeft(ALine);
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
    Code := Copy(Code, CharPos, MaxInt);
    CharPos := 1;
    Kw := UpperCase(WordAt(Code, CharPos));
  end;
  if AProc then
  begin
    Result := IsProcStart(Code, Name) and (UpperCase(Name) = AUpName);
    Exit;
  end;
  // $DEFINE: "$" - не буква, слово за ним
  if (Kw = '') and (Copy(Code, 1, 1) = '$') then
  begin
    CharPos := 2;
    Kw := '$' + UpperCase(WordAt(Code, CharPos));
  end;
  // PUBLIC CONST, PRIVATE CONST, GLOBAL DIM, DIM SHARED ...
  while (Kw = 'PUBLIC') or (Kw = 'PRIVATE') or (Kw = 'GLOBAL') do
    Kw := UpperCase(WordAt(Code, CharPos));
  if Kw = 'DIM' then
  begin
    SavePos := CharPos;
    if UpperCase(WordAt(Code, CharPos)) <> 'SHARED' then
      CharPos := SavePos;
  end;
  if (Kw = 'DIM') or (Kw = 'CONST') or (Kw = 'CREATE') or (Kw = '$DEFINE') or
     ((Length(Kw) >= 6) and (Copy(Kw, 1, 3) = 'DEF') and (Kw <> 'DEFAULT')) then
  begin
    if (Kw = 'CREATE') or (Kw = '$DEFINE') then
    begin
      Result := UpperCase(WordAt(Code, CharPos, True)) = AUpName;
      Exit;
    end;
    Names := TStringList.Create;
    try
      ListNames(Code, CharPos, Names);
      Result := Names.IndexOf(AUpName) >= 0;
    finally
      Names.Free;
    end;
  end;
end;

function StrictFindDefinitions(const AName: string; AProc: Boolean;
                               ARoots: TStrings; const ASkipFile: string;
                               AOut: TStrings; AProgress: TIncProgress;
                               const AExts: string): Boolean;
const
  MaxSize = 4 * 1024 * 1024;
var
  Masks, Files, Lines: TStringList;
  FileIdx, LineIdx: Integer;
  Commented, Cancel, TooBig: Boolean;
  UpName, Rest, OneExt: string;
  Info: TSearchRec;
  SemiAt: Integer;
begin
  UpName := UpperCase(AName);
  Masks := TStringList.Create;
  Files := TStringList.Create;
  Lines := TStringList.Create;
  try
    Masks.Sorted := True;
    Masks.Duplicates := dupIgnore;
    // ".inc;.bas" / "inc bas" / "*.inc" - маски "*.INC", "*.BAS"
    Rest := StringReplace(AExts, ',', ';', [rfReplaceAll]);
    Rest := StringReplace(Rest, ' ', ';', [rfReplaceAll]);
    while Rest <> '' do
    begin
      SemiAt := Pos(';', Rest);
      if SemiAt = 0 then
        SemiAt := Length(Rest) + 1;
      OneExt := UpperCase(Trim(Copy(Rest, 1, SemiAt - 1)));
      Delete(Rest, 1, SemiAt);
      if Copy(OneExt, 1, 1) = '*' then
        Delete(OneExt, 1, 1);
      if Copy(OneExt, 1, 1) = '.' then
        Delete(OneExt, 1, 1);
      if OneExt <> '' then
        Masks.Add('*.' + OneExt);
    end;
    if Masks.Count = 0 then
    begin
      Masks.Add('*.INC');
      Masks.Add('*.BAS');
      Masks.Add('*.CMP');
    end;
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
      TooBig := False;
      if FindFirst(Files[FileIdx], faAnyFile, Info) = 0 then
      begin
        TooBig := Info.Size > MaxSize;
        FindClose(Info);
      end;
      if TooBig then
        Continue;
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
           IsDefinition(Lines[LineIdx], UpName, AProc, Commented) then
          AOut.Add(Files[FileIdx] + '|' + IntToStr(LineIdx + 1) + '|' +
                   IntToStr(Ord(Commented)) + '|' + Trim(Lines[LineIdx]));
    end;
  finally
    Lines.Free;
    Files.Free;
    Masks.Free;
  end;
end;

// Имя файла из строки $INCLUDE "имя"; '' - не $INCLUDE. ACommented -
// строка закомментирована, AIncPos - позиция "$INCLUDE" в строке
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
  QuotePos := AIncPos + QuotePos;
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

// Закомментированный $INCLUDE этого файла - раскомментировать; иначе новая
// строка $INCLUDE после последнего действующего $INCLUDE до первой
// процедуры. Путь - относительно папки -I или программы, если файл в ней.
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
    if InHead and IsProcStart(AMainLines[LineIdx], ProcName) then
      InHead := False;
    IncName := IncludeOfLine(AMainLines[LineIdx], Commented, IncPos);
    if IncName = '' then
      Continue;
    if not Commented and InHead then
      LastInclude := LineIdx;
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
  RelName := RelativeTo(AIncFile, AIncDir);
  if RelName = '' then
    RelName := RelativeTo(AIncFile, AMainDir);
  if RelName = '' then
    RelName := AIncFile;
  ANew := '$INCLUDE "' + RelName + '"';
  ALineNo := LastInclude + 2;
end;

function StrictNeedsSearch(AErr: TStrictError; var AProc: Boolean): Boolean;
begin
  AProc := AErr.Kind = skSusNoBody;
  Result := AErr.Kind in [skUndeclared, skUndeclaredVar, skSusImplicit,
                          skSusNoValue, skSusNoBody];
end;

const
  CantOffer = 'Не могу предложить вариант исправления.';
  FindText = '"Найти определение" ищет его в .inc, .bas, .cmp папок ' +
    'Include, программы (с подпапками) и папки выше; найденный файл можно ' +
    'подключить: закомментированный $INCLUDE этого файла в программе ' +
    'раскомментируется, иначе добавляется строка $INCLUDE. Подключается ' +
    'весь файл - с ним придут и другие его объявления.';

function LabelExplain(AErr: TStrictError; ALines: TStrings): string;
var
  First, Last, LabelIdx: Integer;
  ProcName: string;
  Labels, Similar: TStringList;
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
      StrictSimilarNames(AErr.Name, Labels, Similar);
    end;
    if Similar.Count > 0 then
    begin
      Result := Result + #13#10#13#10'В этой процедуре есть похожая ' +
        'метка - возможно, опечатка:';
      for LabelIdx := 0 to Similar.Count - 1 do
        Result := Result + #13#10'  ' + Similar.Names[LabelIdx] +
          ': (строка ' + Similar.ValueFromIndex[LabelIdx] + ')';
      Result := Result + #13#10'"Заменить" ставит в ' + AErr.Statement +
        ' первую из них. Проверьте, что переход должен идти именно туда.';
    end
    else
      Result := Result + #13#10#13#10'Похожей метки в этой процедуре нет - ' +
        'не могу предложить вариант исправления: куда должен вести переход, ' +
        'по тексту не видно. Вручную: поставить свою метку в этой ' +
        'процедуре или вынести общий код в отдельную SUB и вызывать её из ' +
        'обеих процедур.';
  finally
    Similar.Free;
    Labels.Free;
  end;
end;

function StrictExplain(AErr: TStrictError; ALines: TStrings): string;
begin
  case AErr.Kind of
    skUndeclared, skSusImplicit:
      Result := AErr.Name + ' используется как объект (' + AErr.Name + '.' +
        AErr.Member + '), но ни в программе, ни в подключённых ею файлах нет ' +
        'DIM ' + AErr.Name + ' или CREATE ' + AErr.Name + '.'#13#10 +
        'rc.exe это пропускает: при $TypeCheck off имя без объявления ' +
        'разрешено. Но объекта с таким именем в программе нет, и что вернёт ' +
        AErr.Name + '.' + AErr.Member + ', не известно.'#13#10#13#10 +
        FindText + ' Если код с ' + AErr.Name + ' не нужен - уберите его.';
    skUndeclaredVar:
      Result := AErr.Name + ' не объявлена, а в программе стоит ' +
        '$TYPECHECK ON - при нём переменные объявляются (DIM).'#13#10#13#10 +
        'Если это опечатка - ниже похожие имена программы, "Заменить" ' +
        'ставит выбранное в строку. Если объявление в другом файле - ' +
        FindText;
    skLabelElsewhere, skLabelMissing:
      Result := LabelExplain(AErr, ALines);
    skCaseOp:
      Result := 'В RapidQ CASE > 5 - не сравнение: такая ветка не ' +
        'срабатывает (проверено: x = 7, CASE > 5 не совпало). Сравнение ' +
        'пишется CASE IS > 5 (conditions.html).'#13#10#13#10 +
        '"Заменить" вставляет IS после CASE в этой строке.';
    skBlock:
      Result := AErr.Text + '.'#13#10'Блок не закрыт или закрыт лишний раз - ' +
        'не могу предложить вариант исправления: где должен быть конец ' +
        'блока, по тексту не видно. "Открыть строку" показывает место.';
    skBindNoProc:
      Result := 'BIND ... TO ' + AErr.Name + ': SUB или FUNCTION ' +
        AErr.Name + ' в программе нет.'#13#10#13#10 +
        'Если это опечатка - ниже похожие имена процедур программы, ' +
        '"Заменить" ставит выбранное в строку. Иначе - ' + CantOffer;
    skTypeDefined:
      Result := 'TYPE ' + AErr.Name + ' объявлен дважды; первое объявление - ' +
        ExtractFileName(AErr.OtherFile) + ', строка ' +
        IntToStr(AErr.OtherLine) + '.'#13#10 +
        'Какое из них нужно, по тексту не видно - не могу предложить ' +
        'вариант исправления. "Открыть первое объявление" показывает его.';
    skIncludeMissing:
      Result := 'Файла ' + AErr.Name + ' нет ни в папке программы, ни в ' +
        'папке -I. Перед сборкой его ищет и копирует окно недостающих ' +
        'файлов (препроцессор): если оно закрыто без копирования, rc.exe ' +
        'тоже его не найдёт.';
    skSusNoValue:
      if Pos('одноимённой', AErr.Text) > 0 then
        Result := AErr.Text + '.'#13#10#13#10 +
          'Переменная без DIM внутри SUB / FUNCTION - своя у каждой ' +
          'процедуры. Если значение должно прийти из другой процедуры - ' +
          'объявите её один раз вне SUB (DIM ' + AErr.Name + ' AS ...) в ' +
          'начале программы. Если это другая переменная с тем же именем - ' +
          'здесь ей не присвоено значение.'#13#10#13#10 + FindText
      else
      Result := AErr.Name + ' нигде не объявлена и нигде не получает ' +
        'значение - в RapidQ она всегда 0 или "". Чаще всего это опечатка ' +
        '(crlfcrlf вместо crlf+crlf) или объявление в файле, который не ' +
        'подключён.'#13#10#13#10'Похожие имена программы - ниже, ' +
        '"Заменить" ставит выбранное в строку. ' + FindText;
    skSusTrueFalse:
      Result := AErr.Name + ' не определено: нет $INCLUDE "RAPIDQ.INC" и ' +
        'нет CONST ' + AErr.Name + '. В RapidQ это необъявленная ' +
        'переменная, то есть 0 - и TRUE, и FALSE.'#13#10#13#10 +
        'Если RAPIDQ.INC нашёлся в папках Include - он ниже, "Подключить" ' +
        'добавит $INCLUDE. Иначе: CONST TRUE = 1 и CONST FALSE = 0 в начале ' +
        'программы.';
    skSusStrNum:
      Result := AErr.Text + '.'#13#10'Строка в числовой переменной даёт 0, ' +
        'число в строковой - пустую строку. Что имелось в виду (VAL, STR$ ' +
        'или другая переменная), по тексту не видно - не могу предложить ' +
        'вариант исправления.';
    skSusNoBody:
      Result := AErr.Statement + ' ' + AErr.Name + ' объявлен (DECLARE) и ' +
        'вызывается, но тела в программе нет: вызов ничего не делает. ' +
        'Обычно тело - в файле, который не подключён.'#13#10#13#10 +
        '"Найти определение" ищет ' + AErr.Statement + ' ' + AErr.Name +
        ' с телом в .inc, .bas, .cmp папок Include, программы (с ' +
        'подпапками) и папки выше; найденный файл можно подключить.';
    skSusDeclParams:
      Result := AErr.Text + #13#10#13#10'Какие имена верные, по тексту не ' +
        'видно - не могу предложить вариант исправления. Приведите имена ' +
        'параметров в DECLARE и в заголовке к одним.';
    skSusDefined:
      Result := AErr.Text + #13#10#13#10'Какое объявление нужно, по тексту ' +
        'не видно - не могу предложить вариант исправления. "Открыть первое ' +
        'объявление" показывает его.';
    skLimit:
      Result := 'Ограничение перевода в FreeBASIC, для rc.exe не важно: ' +
        AErr.Text;
  else
    Result := CantOffer + #13#10#13#10 + AErr.Text;
  end;
end;

end.
