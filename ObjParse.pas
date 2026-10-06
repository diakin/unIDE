unit ObjParse;

// ---------------------------------------------------------------------------
//  Разбор формы для инспектора объектов, без VCL-формы:
//    - узел дерева TDfmNode и разбор текста .dfm (ParseDfmNodes);
//    - строки .dfm: DecodeDfmString, EncodeDfmString;
//    - код модуля: аргументы и параметры, помощники (функции, настройщики,
//      создатели через var-параметр), вызовы помощников, создания в цикле,
//      родитель-параметр (Code*);
//    - кэш разбора: CRC-32, запись и чтение файла (DfmCacheWrite,
//      DfmCacheRead);
//    - дерево из кода модуля (BuildCodeRuntime), слияние со снимком живой
//      формы (MergeSnapNode), имена переменных у узлов снимка
//      (ResolveRuntimeNames) и узлы кода на местах из снимка
//      (DedupeSnapNodes).
//  Всё нужное приходит параметрами: список узлов, строки текста. Узлы
//  создаются в переданном списке ANodes и живут, пока живёт он.
//
//  Вынесено из Unit1 без изменения поведения.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, StrUtils;

type
// Узел дерева инспектора объектов: один объект из .dfm со своими
// свойствами и событиями. Номера строк .dfm лежат в Objects списков - они
// понадобятся, когда дойдёт до правки значений.
  TDfmNode = class
  public
    Name, ClassNm: string;
    Line: Integer;              // строка заголовка object в .dfm, от нуля
    EndLine: Integer;           // строка его end, -1 - не дошли (оборван)
    PropN, PropV: TStringList;  // свойства в порядке файла
    // Значение как оно записано в строке .dfm, после " = ". Objects = 1 -
    // значение многострочное (строка через +, список, двоичные данные,
    // коллекция): такое одной строкой не заменить, правка закрыта.
    PropRaw: TStringList;
    EvN, EvV: TStringList;      // события: OnClick = Button1Click
    Parent: TDfmNode;
    Children: TList;            // узлы-дети; владеет ими общий список узлов
                                // (у формы - FDfmNodes), не он
    IsSnap: Boolean;            // узел из снимка живой формы
    IsRuntime: Boolean;         // создан в коде: в .dfm его нет
    IsLink: Boolean;            // компонент из .dfm внутри runtime-панели
    SnapRoot: Boolean;          // корень снимка чужой формы, стоит отдельно
    VarName: string;            // переменная из исходника: FToolbar
    CreateLine: Integer;        // строка её X := TКласс.Create, -1 - нет
    FromCode: Boolean;          // узел из разбора исходника; строки свойств -
                                // строки модуля, а не .dfm
    IsLive: Boolean;            // значения подставлены из снимка
    Note: string;               // приписка к подписи в дереве инспектора
                                // (у объектов RapidQ - номер строки CREATE)
    constructor Create;
    destructor Destroy; override;
  end;

  // Функция-помощник модуля, создающая компонент: какой класс и в каких
  // параметрах родитель и подпись (номера от нуля, -1 - нет)
  TFactoryRec = class
  public
    Name, Cls: string;
    ParIdx, CapIdx: Integer;
    // Родитель задан в самом помощнике, не параметром:
    // Result.Parent := pnlSearchIn (MakeBtn в панели поиска)
    FixedPar: string;
    // Процедура-настройщик: компонент приходит параметром и получает в
    // ней родителя (SetupSwatch(pnlGutterBG, ...): APanel.Parent :=
    // grpEditorColors). Номер этого параметра, -1 - не настройщик.
    CompIdx: Integer;
    // Процедура-создатель: компонент создаётся в ней и отдаётся через
    // var-параметр (MakeCmpButton(var ABtn: TSpeedButton; ...): ABtn :=
    // TSpeedButton.Create(Self)). Номер и имя этого параметра, -1 - нет.
    // Имя переменной - аргумент вызова: MakeCmpButton(btnViewUnit, ...).
    OutIdx: Integer;
    OutName: string;
    // Параметр с подсказкой (Result.Hint := AHint / ABtn.Hint := AHint),
    // -1 - нет. Подсказка различает одинаковые кнопки одного помощника.
    HintIdx: Integer;
    // Строки заголовка и конца тела: создание внутри тела создателя - не
    // отдельный компонент, а тот, что получит аргумент вызова
    HdrLine, EndLine: Integer;
  end;

// --- .dfm
function DecodeDfmString(const S: string): string;
function EncodeDfmString(const S: string): string;
function ParseDfmNodes(const AText: string; ASnap: Boolean;
                       ANodes: TList): TDfmNode;

// --- код модуля
function CodeCreatePos(const SU: string): Integer;
procedure CodeSplitArgs(const S: string; AList: TStrings);
procedure CodeParamNames(const AHdr: string; AList: TStrings);
function CodeIdentAfterAssign(const S: string): string;
procedure CodeCollectFactories(ALines: TStrings; AFacts: TList);
function CodeInCreatorBody(AFacts: TList; ALine: Integer;
                           const ALhs: string): Boolean;
function CodeFactoryCall(ALines: TStrings; I: Integer; AFacts: TList;
                         var ALhs, AClass, APar, ACap: string): Boolean;
function CodeConfCall(ALines: TStrings; J: Integer; AFacts: TList;
                      var AVar, APar, ACap: string): Boolean;
function CodeResolveParamPar(ALines: TStrings; ALine: Integer;
                             const APar: string): string;
function CodeLineInLoop(ALines: TStrings; ALine: Integer): Boolean;
// Список помощников (TFactoryRec) - освободить вместе с записями
procedure FreeFactories(AFacts: TList);

// --- кэш разбора
function Crc32Of(const S: string): Cardinal;
function CacheEsc(const S: string): string;
function CacheUnesc(const S: string): string;
procedure SplitTabs(const S: string; AList: TStrings);
procedure DfmCacheWrite(const AFile, AKey, AInfo: string; ARoots: TList);
function DfmCacheRead(const AFile, AKey: string; ANodes, ARoots: TList): Boolean;

// --- дерево: код модуля и снимок
function BuildCodeRuntime(ADfmRoot: TDfmNode; const AText, AFormClass: string;
                          AFull: Boolean; ANodes: TList): TDfmNode;
// AGone - имена, которые были в .dfm собранного exe, но из .dfm вкладки
// убраны (вырезаны, удалены, переименованы). Живая форма их ещё держит, но
// созданными в коде они не стали: такие узлы снимка в дерево не идут.
procedure MergeSnapNode(ATarget, ASnap: TDfmNode; AIndex: TStringList;
                        AGone: TStrings = nil);
// Новый текст модуля отличается от прежнего только в строках-объявлениях
// ("Panel5: TPanel;"): строки [AHead, AOldEnd) прежнего стали [AHead,
// ANewEnd) нового. По нему кэши разбора модуля сдвигают номера строк,
// а не разбирают модуль заново.
function CodeDiffPlain(AOld, ANew: TStrings;
                       var AHead, AOldEnd, ANewEnd: Integer): Boolean;
procedure ResolveRuntimeNames(ARoot: TDfmNode; const AText: string);
procedure DedupeSnapNodes(ANode: TDfmNode; AByLine: TStringList;
                          ANodes: TList);

implementation

constructor TDfmNode.Create;
begin
  inherited Create;
  Children := TList.Create;
  CreateLine := -1;
  EndLine := -1;
  PropN := TStringList.Create;
  PropRaw := TStringList.Create;
  PropV := TStringList.Create;
  EvN := TStringList.Create;
  EvV := TStringList.Create;
end;

destructor TDfmNode.Destroy;
begin
  Children.Free;
  PropRaw.Free;
  EvV.Free;
  EvN.Free;
  PropV.Free;
  PropN.Free;
  inherited;
end;

// ---------------------------------------------------------------------------
//  Кэш разбора формы (dsgcache): контрольная сумма и запись полей
// ---------------------------------------------------------------------------

var
  Crc32Table: array[0..255] of Cardinal;
  Crc32Ready: Boolean = False;

// CRC-32 строки - ключ кэша: тот же текст формы и модуля или уже другой
function Crc32Of(const S: string): Cardinal;
var
  I, K: Integer;
  C: Cardinal;
begin
  if not Crc32Ready then
  begin
    for I := 0 to 255 do
    begin
      C := Cardinal(I);
      for K := 1 to 8 do
        if (C and 1) <> 0 then
          C := (C shr 1) xor $EDB88320
        else
          C := C shr 1;
      Crc32Table[I] := C;
    end;
    Crc32Ready := True;
  end;
  C := $FFFFFFFF;
  for I := 1 to Length(S) do
    C := Crc32Table[Byte(C xor Cardinal(Ord(S[I])))] xor (C shr 8);
  Result := not C;
end;

// Поле записи кэша: табуляция и переводы строки внутри - \t, \r, \n,
// остальные управляющие - \xHH. Прежде всего #0: он бывает в значениях
// (PasswordChar = #0 из снимка), а TStringList.LoadFromFile на нём
// обрывает текст - файл кэша читался бы обрезанным и не годился.
function CacheEsc(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    case S[I] of
      '\': Result := Result + '\\';
      #9:  Result := Result + '\t';
      #10: Result := Result + '\n';
      #13: Result := Result + '\r';
      #0..#8, #11, #12, #14..#31:
        Result := Result + '\x' + IntToHex(Ord(S[I]), 2);
    else
      Result := Result + S[I];
    end;
end;

function CacheUnesc(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '\') and (I < Length(S)) then
    begin
      Inc(I);
      case S[I] of
        't': Result := Result + #9;
        'n': Result := Result + #10;
        'r': Result := Result + #13;
        'x':
          begin
            Result := Result + Chr(StrToIntDef('$' + Copy(S, I + 1, 2), 63));
            Inc(I, 2);
          end;
      else
        Result := Result + S[I];
      end;
    end
    else
      Result := Result + S[I];
    Inc(I);
  end;
end;

// Строка записи - поля через табуляцию
procedure SplitTabs(const S: string; AList: TStrings);
var
  P, Q: Integer;
begin
  AList.Clear;
  P := 1;
  repeat
    Q := PosEx(#9, S, P);
    if Q = 0 then
    begin
      AList.Add(Copy(S, P, MaxInt));
      Break;
    end;
    AList.Add(Copy(S, P, Q - P));
    P := Q + 1;
  until False;
end;

// Строковое значение .dfm в читаемом виде: 'abc' + 'def'#13#10'x'.
// Апострофы внутри удвоены, символы вне кавычек записаны как #код.
// Значение не строковое (число, идентификатор, набор) - возвращается как есть.
function DecodeDfmString(const S: string): string;
var
  I, N, Code: Integer;
  W: WideString;
begin
  Result := '';
  if (S = '') or not (S[1] in ['''', '#']) then
  begin
    Result := S;
    Exit;
  end;

  I := 1;
  N := Length(S);
  while I <= N do
  begin
    if S[I] = '''' then
    begin
      Inc(I);
      while I <= N do
      begin
        if S[I] = '''' then
        begin
          if (I < N) and (S[I + 1] = '''') then
          begin
            Result := Result + '''';
            Inc(I, 2);
            Continue;
          end;
          Inc(I);
          Break;
        end;
        Result := Result + S[I];
        Inc(I);
      end;
    end
    else if S[I] = '#' then
    begin
      Inc(I);
      Code := 0;
      while (I <= N) and (S[I] in ['0'..'9']) do
      begin
        Code := Code * 10 + Ord(S[I]) - Ord('0');
        Inc(I);
      end;
      // Выше 255 - символ Юникода: переводим в текущую кодовую страницу
      if Code < 256 then
        Result := Result + Chr(Code)
      else
      begin
        W := WideChar(Code);
        Result := Result + string(W);
      end;
    end
    else if S[I] in [' ', '+'] then
      Inc(I)
    else
    begin
      // Посреди строки - не строковое выражение; показываем как было
      Result := S;
      Exit;
    end;
  end;
end;

// Строка в записи .dfm: апострофы удваиваются, управляющие символы - #код
function EncodeDfmString(const S: string): string;
var
  I: Integer;
  InQ: Boolean;
begin
  Result := '';
  InQ := False;
  for I := 1 to Length(S) do
    if S[I] < ' ' then
    begin
      if InQ then
      begin
        Result := Result + '''';
        InQ := False;
      end;
      Result := Result + '#' + IntToStr(Ord(S[I]));
    end
    else
    begin
      if not InQ then
      begin
        Result := Result + '''';
        InQ := True;
      end;
      if S[I] = '''' then
        Result := Result + ''''''
      else
        Result := Result + S[I];
    end;
  if InQ then
    Result := Result + '''';
  if Result = '' then
    Result := '''''';
end;

// Разбор текста .dfm в узлы TDfmNode. Возвращает корневой объект; все узлы
// попадают в ANodes (у формы - FDfmNodes) и освобождаются вместе с ним. ASnap - текст взят из
// снимка живой формы, а не из файла.
//
// Строки формата:
//   object Name: TClass / inherited ... / inline ...  - начало объекта
//   end                                                - конец объекта
//   Prop = значение                                    - свойство
// Значение бывает многострочным: строка, склеенная через +, список в
// круглых скобках, двоичные данные в фигурных, коллекция в угловых. Для
// просмотра они сворачиваются в одну строку.
function ParseDfmNodes(const AText: string; ASnap: Boolean;
                       ANodes: TList): TDfmNode;
var
  SL: TStringList;
  I, P, D, Items, PropLine: Integer;
  Line, Up, Head, Nm, Cls, PName, PVal, Rest, Acc, L2, Raw0, RawAcc: string;
  Stack: array of TDfmNode;
  Top: Integer;
  Obj, Cur, Root: TDfmNode;
  Closed: Boolean;

  function IsIdent(const S: string): Boolean;
  var
    J: Integer;
  begin
    Result := S <> '';
    for J := 1 to Length(S) do
      if not (S[J] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) then
      begin
        Result := False;
        Exit;
      end;
  end;

  function Shorten(const S: string): string;
  begin
    Result := S;
    if Length(Result) > 300 then
      Result := Copy(Result, 1, 300) + '...';
  end;

begin
  Root := nil;
  SL := TStringList.Create;
  try
    SL.Text := AText;
    SetLength(Stack, 0);
    Top := -1;
    Cur := nil;

    I := 0;
    while I < SL.Count do
    begin
      Line := Trim(SL[I]);
      Up := UpperCase(Line);

      // --- начало объекта
      if (Copy(Up, 1, 7) = 'OBJECT ') or (Copy(Up, 1, 10) = 'INHERITED ') or
         (Copy(Up, 1, 7) = 'INLINE ') then
      begin
        Head := Trim(Copy(Line, Pos(' ', Line) + 1, MaxInt));
        P := Pos('[', Head);          // [0] - индекс у наследованных
        if P > 0 then
          Head := Trim(Copy(Head, 1, P - 1));
        P := Pos(':', Head);
        if P > 0 then
        begin
          Nm := Trim(Copy(Head, 1, P - 1));
          Cls := Trim(Copy(Head, P + 1, MaxInt));
        end
        else
        begin
          Nm := '';
          Cls := Head;
        end;

        Obj := TDfmNode.Create;
        Obj.Name := Nm;
        Obj.ClassNm := Cls;
        Obj.Line := I;
        Obj.IsSnap := ASnap;
        ANodes.Add(Obj);

        if Top >= 0 then
        begin
          Obj.Parent := Stack[Top];
          Stack[Top].Children.Add(Obj);
        end
        else if Root = nil then
          Root := Obj;

        Inc(Top);
        SetLength(Stack, Top + 1);
        Stack[Top] := Obj;
        Cur := Obj;
        Inc(I);
        Continue;
      end;

      // --- конец объекта
      if Up = 'END' then
      begin
        if Top >= 0 then
        begin
          Stack[Top].EndLine := I;
          Dec(Top);
        end;
        if Top >= 0 then
          Cur := Stack[Top]
        else
          Cur := nil;
        Inc(I);
        Continue;
      end;

      // --- свойство
      P := Pos(' = ', Line);
      if P > 0 then
      begin
        PName := Copy(Line, 1, P - 1);
        PVal := Copy(Line, P + 3, MaxInt);
      end
      else if (Length(Line) > 2) and (Copy(Line, Length(Line) - 1, 2) = ' =') then
      begin
        // Длинная строка: значение начинается со следующей строки
        PName := Copy(Line, 1, Length(Line) - 2);
        PVal := '';
      end
      else
      begin
        Inc(I);
        Continue;
      end;

      PropLine := I;
      Raw0 := PVal;   // как записано в строке - для правки
      if (PVal = '') and (I + 1 < SL.Count) then
      begin
        Inc(I);
        PVal := Trim(SL[I]);
      end;

      if PVal <> '' then
        case PVal[1] of
          '(':
            begin
              // Список: элементы по строкам до закрывающей скобки.
              // Для показа - через запятую и расшифрованные; как записано
              // (RawAcc) - одной строкой в скобках: по нему конструктор
              // заполняет Tabs, Items, Lines компонентов из кода
              Acc := '';
              RawAcc := '';
              Items := 0;
              Rest := Copy(PVal, 2, MaxInt);
              repeat
                Closed := (Rest <> '') and (Rest[Length(Rest)] = ')');
                if Closed then
                  Rest := Copy(Rest, 1, Length(Rest) - 1);
                if Trim(Rest) <> '' then
                begin
                  Inc(Items);
                  if Acc <> '' then
                    Acc := Acc + ', ';
                  Acc := Acc + DecodeDfmString(Trim(Rest));
                  RawAcc := RawAcc + ' ' + Trim(Rest);
                end;
                if Closed then
                  Break;
                Inc(I);
                if I >= SL.Count then
                  Break;
                Rest := Trim(SL[I]);
              until False;
              PVal := Shorten('(' + Acc + ')');
              Raw0 := '(' + Trim(RawAcc) + ')';
            end;

          '{':
            begin
              // Двоичные данные - картинки, иконки: показывать нечего
              while ((PVal = '') or (PVal[Length(PVal)] <> '}')) and
                    (I + 1 < SL.Count) do
              begin
                Inc(I);
                PVal := Trim(SL[I]);
              end;
              PVal := '(двоичные данные)';
            end;

          '<':
            begin
              if PVal = '<>' then
                PVal := '(коллекция пуста)'
              else
              begin
                // Коллекция: элементы item ... end, внутри бывают свои
                // коллекции - считаем вложенность угловых скобок
                D := 1;
                Items := 0;
                while (D > 0) and (I + 1 < SL.Count) do
                begin
                  Inc(I);
                  L2 := Trim(SL[I]);
                  if (D = 1) and SameText(L2, 'item') then
                    Inc(Items);
                  // Пустая вложенная коллекция (Columns = <>) глубину
                  // не меняет
                  if Copy(L2, Length(L2) - 1, 2) = '<>' then
                  else if (L2 <> '') and (L2[Length(L2)] = '>') then
                    Dec(D)
                  else if (L2 <> '') and (L2[Length(L2)] = '<') then
                    Inc(D);
                end;
                PVal := Format('(коллекция, элементов: %d)', [Items]);
              end;
            end;
        else
          // Строка, склеенная из частей через +
          while (Length(PVal) > 1) and (PVal[Length(PVal)] = '+') and
                (I + 1 < SL.Count) do
          begin
            Inc(I);
            PVal := PVal + ' ' + Trim(SL[I]);
          end;
          PVal := Shorten(DecodeDfmString(PVal));
        end;

      if Cur <> nil then
      begin
        // Событие: On* с именем обработчика. В снимке у обработчика, не
        // объявленного published, имени нет - там стоит (без имени)
        if (Copy(PName, 1, 2) = 'On') and
           (IsIdent(PVal) or ((PVal <> '') and (PVal[1] = '('))) then
        begin
          Cur.EvN.AddObject(PName, TObject(PropLine));
          Cur.EvV.Add(PVal);
        end
        else
        begin
          Cur.PropN.AddObject(PName, TObject(PropLine));
          Cur.PropV.Add(PVal);
          // Значение заняло больше одной строки - правка закрыта
          Cur.PropRaw.AddObject(Raw0, TObject(Ord(I <> PropLine)));
        end;
      end;

      Inc(I);
    end;
  finally
    SL.Free;
  end;

  Result := Root;
end;

// Строка кода без комментария // в конце (// в строке в кавычках - не
// комментарий). "Sheet := F1;   // .dfm: Sheet := TTabSheet.Create(Self);"
// -> "Sheet := F1;": создание в комментарии - не создание.
function CodeNoComment(const ALine: string): string;
var
  Index: Integer;
  InQuote: Boolean;
begin
  Result := ALine;
  InQuote := False;
  for Index := 1 to Length(ALine) - 1 do
    if ALine[Index] = '''' then
      InQuote := not InQuote
    else if not InQuote and (ALine[Index] = '/') and
            (ALine[Index + 1] = '/') then
    begin
      Result := TrimRight(Copy(ALine, 1, Index - 1));
      Exit;
    end;
end;

// Позиция ".Create" в строке (прописными), если за ним идёт "(" -
// возможно, через продолжение имени конструктора: .Create(, .CreateNew(,
// .CreatePalette(. 0 - это не создание.
function CodeCreatePos(const SU: string): Integer;
var
  P, K: Integer;
begin
  Result := 0;
  P := Pos('.CREATE', SU);
  while P > 0 do
  begin
    K := P + 7;
    while (K <= Length(SU)) and (SU[K] in ['A'..'Z', '0'..'9', '_']) do
      Inc(K);
    if (K <= Length(SU)) and (SU[K] = '(') then
    begin
      Result := P;
      Exit;
    end;
    P := PosEx('.CREATE', SU, P + 1);
  end;
end;

// ---------------------------------------------------------------------------
//  Функции-помощники модуля, создающие компоненты
//  (FObjProps := MakeView(Sheet); mFind := MakeItem(Self, mEdit, '&Find',...)).
//  Общие для разбора кода (BuildCodeRuntime): помощник - функция модуля с
//  Result := TКласс.Create(...); из её тела видно, какой параметр -
//  родитель, а какой - подпись.
// ---------------------------------------------------------------------------

// Аргументы вызова верхнего уровня; запятые в строках и во вложенных
// скобках не делят
procedure CodeSplitArgs(const S: string; AList: TStrings);
var
  P, D: Integer;
  Q: Boolean;
  Cur: string;
begin
  AList.Clear;
  D := 0;
  Q := False;
  Cur := '';
  for P := 1 to Length(S) do
  begin
    if S[P] = '''' then
      Q := not Q;
    if not Q then
    begin
      if S[P] = '(' then
        Inc(D)
      else if S[P] = ')' then
        Dec(D)
      else if (S[P] = ',') and (D = 0) then
      begin
        AList.Add(Trim(Cur));
        Cur := '';
        Continue;
      end;
    end;
    Cur := Cur + S[P];
  end;
  if Trim(Cur) <> '' then
    AList.Add(Trim(Cur));
end;

// Имена параметров из заголовка функции по порядку
procedure CodeParamNames(const AHdr: string; AList: TStrings);
var
  P1, P2, P, C: Integer;
  Body, Grp: string;
  Parts: TStringList;
begin
  AList.Clear;
  P1 := Pos('(', AHdr);
  P2 := LastDelimiter(')', AHdr);
  if (P1 = 0) or (P2 <= P1) then
    Exit;
  Body := Copy(AHdr, P1 + 1, P2 - P1 - 1) + ';';
  Parts := TStringList.Create;
  try
    repeat
      P := Pos(';', Body);
      Grp := Trim(Copy(Body, 1, P - 1));
      Delete(Body, 1, P);
      C := Pos(':', Grp);
      if C > 0 then
        Grp := Trim(Copy(Grp, 1, C - 1));
      if CompareText(Copy(Grp, 1, 6), 'const ') = 0 then
        Delete(Grp, 1, 6)
      else if CompareText(Copy(Grp, 1, 4), 'var ') = 0 then
        Delete(Grp, 1, 4)
      else if CompareText(Copy(Grp, 1, 4), 'out ') = 0 then
        Delete(Grp, 1, 4);
      CodeSplitArgs(Grp, Parts);
      for C := 0 to Parts.Count - 1 do
        if Trim(Parts[C]) <> '' then
          AList.Add(Trim(Parts[C]));
    until Trim(Body) = '';
  finally
    Parts.Free;
  end;
end;

// Идентификатор справа от := (до ; и пробела)
function CodeIdentAfterAssign(const S: string): string;
var
  P, Q: Integer;
begin
  Result := '';
  P := Pos(':=', S);
  if P = 0 then
    Exit;
  Result := Trim(Copy(S, P + 2, MaxInt));
  Q := 1;
  while (Q <= Length(Result)) and
        (Result[Q] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) do
    Inc(Q);
  Result := Copy(Result, 1, Q - 1);
end;

// Все помощники модуля - в AFacts (TFactoryRec)
procedure CodeCollectFactories(ALines: TStrings; AFacts: TList);
var
  I, E: Integer;

  // Отступ строки - число пробелов и табуляций в начале
  function IndentOf(const S: string): Integer;
  begin
    Result := 0;
    while (Result < Length(S)) and (S[Result + 1] in [' ', #9]) do
      Inc(Result);
  end;

  function IsHeader(const S: string): Boolean;
  var
    T: string;
  begin
    T := Trim(S);
    Result := (CompareText(Copy(T, 1, 9), 'function ') = 0) or
              (CompareText(Copy(T, 1, 10), 'procedure ') = 0);
  end;

  // Заголовок в строке AHdr и тело до конца подпрограммы. AEnd - строка,
  // на которой тело кончилось.
  // Подпрограмма с первой колонки кончается на "end;" с первой колонки.
  // Вложенная (MakeView внутри BuildObjectInspector) - на "end;" с тем же
  // отступом, что у её заголовка; строка с первой колонки её тоже
  // обрывает, чтобы разбор не ушёл дальше своей процедуры. Вложенные
  // заголовки внутри тела разбираются отдельно, как свои помощники:
  // раньше тело внешней процедуры проглатывало их целиком.
  procedure ParseRoutine(AHdr: Integer; var AEnd: Integer);
  var
    J, K, P, P2, Ind, Dummy: Integer;
    T, TU, Hdr, V, L: string;
    F: TFactoryRec;
    Prms: TStringList;
    IsProc, Nested: Boolean;
  begin
    T := Trim(ALines[AHdr]);
    IsProc := CompareText(Copy(T, 1, 10), 'procedure ') = 0;
    Ind := IndentOf(ALines[AHdr]);
    Nested := Ind > 0;

    Hdr := T;
    J := AHdr;
    while (Pos(')', Hdr) = 0) and
          not ((Pos('(', Hdr) = 0) and (Pos(';', Hdr) > 0)) and
          (J + 1 < ALines.Count) and (J < AHdr + 6) do
    begin
      Inc(J);
      Hdr := Hdr + ' ' + Trim(ALines[J]);
    end;

    Prms := TStringList.Create;
    F := TFactoryRec.Create;
    try
      F.ParIdx := -1;
      F.CapIdx := -1;
      F.CompIdx := -1;
      F.OutIdx := -1;
      F.HintIdx := -1;
      F.HdrLine := AHdr;
      if IsProc then
        V := Trim(Copy(Hdr, 11, MaxInt))
      else
        V := Trim(Copy(Hdr, 10, MaxInt));
      P := Pos('(', V);
      if P > 0 then
        V := Copy(V, 1, P - 1);
      P := Pos(':', V);
      if P > 0 then
        V := Copy(V, 1, P - 1);
      P := Pos(';', V);
      if P > 0 then
        V := Copy(V, 1, P - 1);
      P := LastDelimiter('.', V);
      if P > 0 then
        Delete(V, 1, P);
      F.Name := Trim(V);
      CodeParamNames(Hdr, Prms);

      K := J + 1;
      while K < ALines.Count do
      begin
        L := ALines[K];
        if Nested then
        begin
          if (Trim(L) = 'end;') and (IndentOf(L) = Ind) then
            Break;
          // Строка с первой колонки - вложенная кончилась раньше, чем
          // нашёлся её end (разбор чужого форматирования): не уходить
          if (L <> '') and not (L[1] in [' ', #9]) then
            Break;
        end
        else
        begin
          if CompareText(TrimRight(L), 'end;') = 0 then
            Break;
          // Заголовок без тела (объявление в interface, forward): до его
          // end; дело не дойдёт - следующая подпрограмма или граница
          // раздела с первой колонки. Иначе разбор проглотил бы её целиком.
          if (L <> '') and not (L[1] in [' ', #9]) and
             (IsHeader(L) or
              (CompareText(Copy(Trim(L), 1, 14), 'implementation') = 0)) then
          begin
            Dec(K);
            Break;
          end;
        end;

        // Вложенный заголовок - свой помощник. Тело внешней при этом
        // читается дальше как было: его строки ей не мешают.
        if not Nested and (IndentOf(L) > 0) and IsHeader(L) then
          ParseRoutine(K, Dummy);

        T := Trim(L);
        TU := UpperCase(T);
        // Создатель: var-параметр := TКласс.Create(...)
        P := Pos(':=', T);
        P2 := Pos('.CREATE', TU);
        if IsProc and (P > 1) and (P2 > P) and
           (Prms.IndexOf(Trim(Copy(T, 1, P - 1))) >= 0) then
        begin
          V := Trim(Copy(T, P + 2, P2 - P - 2));
          if IsValidIdent(V) then
          begin
            F.OutIdx := Prms.IndexOf(Trim(Copy(T, 1, P - 1)));
            F.OutName := Trim(Copy(T, 1, P - 1));
            F.Cls := V;
          end;
        end;
        // Настройщик: Параметр.Parent := ... / Параметр.Caption := ...
        P := Pos('.', T);
        if IsProc and (P > 1) and (Pos(':=', T) > P) and
           (Prms.IndexOf(Copy(T, 1, P - 1)) >= 0) then
        begin
          V := UpperCase(Trim(Copy(T, P + 1, Pos(':=', T) - P - 1)));
          if V = 'PARENT' then
          begin
            F.CompIdx := Prms.IndexOf(Copy(T, 1, P - 1));
            F.ParIdx := Prms.IndexOf(CodeIdentAfterAssign(T));
            if F.ParIdx < 0 then
              F.FixedPar := CodeIdentAfterAssign(T);
          end
          else if (V = 'CAPTION') or (V = 'TEXT') then
            F.CapIdx := Prms.IndexOf(CodeIdentAfterAssign(T))
          else if V = 'HINT' then
            F.HintIdx := Prms.IndexOf(CodeIdentAfterAssign(T));
        end;
        P := Pos('.CREATE(', TU);
        if (Copy(TU, 1, 6) = 'RESULT') and (P > 0) and (Pos(':=', T) > 0) then
          F.Cls := Trim(Copy(T, Pos(':=', T) + 2, P - Pos(':=', T) - 2));
        if Copy(TU, 1, 15) = 'RESULT.CAPTION ' then
          F.CapIdx := Prms.IndexOf(CodeIdentAfterAssign(T))
        else if Copy(TU, 1, 12) = 'RESULT.TEXT ' then
          F.CapIdx := Prms.IndexOf(CodeIdentAfterAssign(T))
        else if Copy(TU, 1, 12) = 'RESULT.HINT ' then
          F.HintIdx := Prms.IndexOf(CodeIdentAfterAssign(T))
        else if Copy(TU, 1, 14) = 'RESULT.PARENT ' then
        begin
          F.ParIdx := Prms.IndexOf(CodeIdentAfterAssign(T));
          if F.ParIdx < 0 then
            F.FixedPar := CodeIdentAfterAssign(T);
        end
        else if (Pos('.ADD(RESULT)', TU) > 0) or
                ((Pos('.INSERT(', TU) > 0) and (Pos('RESULT)', TU) > 0)) then
          F.ParIdx := Prms.IndexOf(Trim(Copy(T, 1, Pos('.', T) - 1)));
        Inc(K);
      end;
      AEnd := K;
      F.EndLine := K;

      if (F.Name <> '') and
         ((not IsProc and (F.Cls <> '') and IsValidIdent(F.Cls)) or
          (IsProc and ((F.CompIdx >= 0) or (F.OutIdx >= 0)))) then
      begin
        if IsProc and (F.OutIdx < 0) then
          F.Cls := '';        // настройщик ничего не создаёт
        AFacts.Add(F);
        F := nil;
      end;
    finally
      F.Free;
      Prms.Free;
    end;
  end;

begin
  I := 0;
  while I < ALines.Count do
  begin
    if not IsHeader(ALines[I]) then
    begin
      Inc(I);
      Continue;
    end;
    ParseRoutine(I, E);
    I := E + 1;
  end;
end;

// Строка ALine - создание внутри тела процедуры-создателя, в её
// var-параметр (ABtn := TSpeedButton.Create(Self) в MakeCmpButton)? Такая
// строка - не отдельный компонент: компоненты - это вызовы создателя.
function CodeInCreatorBody(AFacts: TList; ALine: Integer;
                           const ALhs: string): Boolean;
var
  M: Integer;
  F: TFactoryRec;
begin
  Result := False;
  if (AFacts = nil) or (ALhs = '') then
    Exit;
  for M := 0 to AFacts.Count - 1 do
  begin
    F := TFactoryRec(AFacts[M]);
    if (F.OutIdx >= 0) and (ALine > F.HdrLine) and (ALine <= F.EndLine) and
       (CompareText(F.OutName, ALhs) = 0) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

// Строка I - "X := Помощник(...)"? Класс, родитель (аргумент-имя, .Items
// отброшен) и подпись (аргумент как записан). Вызов может занимать
// несколько строк. Процедура-создатель вызывается без присваивания:
// "MakeCmpButton(btnViewUnit, ...)" - переменная тогда из аргумента.
function CodeFactoryCall(ALines: TStrings; I: Integer; AFacts: TList;
                         var ALhs, AClass, APar, ACap: string): Boolean;
var
  T, V, Call: string;
  B, Q, J, K, Depth, M: Integer;
  InQ: Boolean;
  F: TFactoryRec;
  Args: TStringList;
begin
  Result := False;
  T := Trim(CodeNoComment(ALines[I]));
  if (Copy(T, 1, 2) = '//') or (AFacts.Count = 0) then
    Exit;
  B := Pos(':=', T);
  if B > 0 then
  begin
    ALhs := Trim(Copy(T, 1, B - 1));
    if not IsValidIdent(ALhs) then
      Exit;
    V := Trim(Copy(T, B + 2, MaxInt));
  end
  else
  begin
    ALhs := '';   // только создатель: имя - из его var-параметра
    V := T;
  end;
  Q := Pos('(', V);
  if Q = 0 then
    Exit;
  F := nil;
  for M := 0 to AFacts.Count - 1 do
    if (TFactoryRec(AFacts[M]).Cls <> '') and
       (CompareText(TFactoryRec(AFacts[M]).Name, Trim(Copy(V, 1, Q - 1))) = 0) then
    begin
      F := TFactoryRec(AFacts[M]);
      Break;
    end;
  if F = nil then
    Exit;
  // Функция - только с присваиванием, создатель - только без него
  if (B > 0) <> (F.OutIdx < 0) then
    Exit;

  Call := Copy(V, Q + 1, MaxInt);
  J := I;
  repeat
    Depth := 1;
    InQ := False;
    for K := 1 to Length(Call) do
      if Call[K] = '''' then
        InQ := not InQ
      else if not InQ then
        if Call[K] = '(' then
          Inc(Depth)
        else if Call[K] = ')' then
        begin
          Dec(Depth);
          if Depth = 0 then
          begin
            SetLength(Call, K - 1);
            Break;
          end;
        end;
    if (Depth = 0) or (J + 1 >= ALines.Count) or (J > I + 6) then
      Break;
    Inc(J);
    Call := Call + ' ' + Trim(ALines[J]);
  until False;

  Args := TStringList.Create;
  try
    CodeSplitArgs(Call, Args);
    AClass := F.Cls;
    APar := F.FixedPar;
    ACap := '';
    if (F.ParIdx >= 0) and (F.ParIdx < Args.Count) then
    begin
      V := Args[F.ParIdx];
      if CompareText(Copy(V, Length(V) - 5, 6), '.Items') = 0 then
        Delete(V, Length(V) - 5, 6);
      if IsValidIdent(V) then
        APar := V;
    end;
    if (F.CapIdx >= 0) and (F.CapIdx < Args.Count) then
      ACap := Args[F.CapIdx];
    if F.OutIdx >= 0 then
      if F.OutIdx < Args.Count then
        ALhs := Trim(Args[F.OutIdx])
      else
        ALhs := '';
  finally
    Args.Free;
  end;
  Result := IsValidIdent(ALhs);
end;

// Строка J - вызов настройщика: SetupSwatch(pnlGutterBG, 'BG', '...')?
// AVar - переданный компонент, APar - родитель, который он получит,
// ACap - аргумент подписи как записан.
function CodeConfCall(ALines: TStrings; J: Integer; AFacts: TList;
                      var AVar, APar, ACap: string): Boolean;
var
  T, Call, V: string;
  Q, K, M, Depth, L: Integer;
  InQ: Boolean;
  F: TFactoryRec;
  Args: TStringList;
begin
  Result := False;
  T := Trim(CodeNoComment(ALines[J]));
  if (Copy(T, 1, 2) = '//') or (AFacts.Count = 0) then
    Exit;
  Q := Pos('(', T);
  if (Q = 0) or ((Pos(':=', T) > 0) and (Pos(':=', T) < Q)) then
    Exit;
  V := Trim(Copy(T, 1, Q - 1));
  if not IsValidIdent(V) then
    Exit;
  F := nil;
  for M := 0 to AFacts.Count - 1 do
    if (TFactoryRec(AFacts[M]).CompIdx >= 0) and
       (CompareText(TFactoryRec(AFacts[M]).Name, V) = 0) then
    begin
      F := TFactoryRec(AFacts[M]);
      Break;
    end;
  if F = nil then
    Exit;

  Call := Copy(T, Q + 1, MaxInt);
  L := J;
  repeat
    Depth := 1;
    InQ := False;
    for K := 1 to Length(Call) do
      if Call[K] = '''' then
        InQ := not InQ
      else if not InQ then
        if Call[K] = '(' then
          Inc(Depth)
        else if Call[K] = ')' then
        begin
          Dec(Depth);
          if Depth = 0 then
          begin
            SetLength(Call, K - 1);
            Break;
          end;
        end;
    if (Depth = 0) or (L + 1 >= ALines.Count) or (L > J + 6) then
      Break;
    Inc(L);
    Call := Call + ' ' + Trim(ALines[L]);
  until False;

  Args := TStringList.Create;
  try
    CodeSplitArgs(Call, Args);
    if F.CompIdx >= Args.Count then
      Exit;
    AVar := Trim(Args[F.CompIdx]);
    if not IsValidIdent(AVar) then
      Exit;
    APar := F.FixedPar;
    if (F.ParIdx >= 0) and (F.ParIdx < Args.Count) and
       IsValidIdent(Trim(Args[F.ParIdx])) then
      APar := Trim(Args[F.ParIdx]);
    ACap := '';
    if (F.CapIdx >= 0) and (F.CapIdx < Args.Count) then
      ACap := Trim(Args[F.CapIdx]);
    Result := APar <> '';
  finally
    Args.Free;
  end;
end;

// Родитель, заданный параметром своей процедуры: lstCompTypes.Parent :=
// ATab внутри BuildCompilersTab(ATab: TWinControl). Настоящий родитель -
// аргумент из вызова: BuildCompilersTab(TabDirs) -> TabDirs. Берётся
// первый найденный вызов, в котором этот аргумент - просто имя. APar - не
// параметр или вызова нет - возвращается как есть.
function CodeResolveParamPar(ALines: TStrings; ALine: Integer;
                             const APar: string): string;
var
  I, J, K, P, Q, Idx, Depth: Integer;
  T, U, Hdr, Name, Call: string;
  Prms, Args: TStringList;
  InQ: Boolean;
begin
  Result := APar;
  if (APar = '') or (ALine < 0) or (ALine >= ALines.Count) then
    Exit;

  // Заголовок своей процедуры - вверх до строки с первой колонки
  I := ALine;
  while I >= 0 do
  begin
    U := UpperCase(ALines[I]);
    if (Copy(U, 1, 10) = 'PROCEDURE ') or (Copy(U, 1, 9) = 'FUNCTION ') then
      Break;
    Dec(I);
  end;
  if I < 0 then
    Exit;
  Hdr := Trim(ALines[I]);
  J := I;
  while (Pos(')', Hdr) = 0) and
        not ((Pos('(', Hdr) = 0) and (Pos(';', Hdr) > 0)) and
        (J + 1 < ALines.Count) and (J < I + 6) do
  begin
    Inc(J);
    Hdr := Hdr + ' ' + Trim(ALines[J]);
  end;

  // Имя процедуры без класса: TForm2.BuildCompilersTab -> BuildCompilersTab
  if UpperCase(Copy(Hdr, 1, 10)) = 'PROCEDURE ' then
    Name := Trim(Copy(Hdr, 11, MaxInt))
  else
    Name := Trim(Copy(Hdr, 10, MaxInt));
  P := Pos('(', Name);
  if P > 0 then
    Name := Copy(Name, 1, P - 1);
  P := LastDelimiter('.', Name);
  if P > 0 then
    Delete(Name, 1, P);
  Name := Trim(Name);
  if not IsValidIdent(Name) then
    Exit;

  Prms := TStringList.Create;
  Args := TStringList.Create;
  try
    CodeParamNames(Hdr, Prms);
    Idx := Prms.IndexOf(APar);
    if Idx < 0 then
      Exit;

    // Вызовы: Name( ... ) не в заголовках и не в комментариях
    for K := 0 to ALines.Count - 1 do
    begin
      T := Trim(ALines[K]);
      U := UpperCase(T);
      if (Copy(T, 1, 2) = '//') or (Copy(U, 1, 10) = 'PROCEDURE ') or
         (Copy(U, 1, 9) = 'FUNCTION ') then
        Continue;
      P := Pos(UpperCase(Name) + '(', U);
      if P = 0 then
        Continue;
      if (P > 1) and (U[P - 1] in ['A'..'Z', '0'..'9', '_']) then
        Continue;
      Call := Copy(T, P + Length(Name) + 1, MaxInt);
      // До закрывающей скобки вызова
      Depth := 1;
      InQ := False;
      for Q := 1 to Length(Call) do
        if Call[Q] = '''' then
          InQ := not InQ
        else if not InQ then
          if Call[Q] = '(' then
            Inc(Depth)
          else if Call[Q] = ')' then
          begin
            Dec(Depth);
            if Depth = 0 then
            begin
              SetLength(Call, Q - 1);
              Break;
            end;
          end;
      CodeSplitArgs(Call, Args);
      if (Idx < Args.Count) and IsValidIdent(Trim(Args[Idx])) then
      begin
        Result := Trim(Args[Idx]);
        Exit;
      end;
    end;
  finally
    Args.Free;
    Prms.Free;
  end;
end;

// Строка ALine лежит в теле цикла (for, while, repeat) своей подпрограммы?
// Смотрим вверх охватывающие строки - с меньшим отступом, чем у текущего
// уровня. begin на отдельной строке относится к строке над ним с тем же
// отступом ("for ... do" / "begin"), поэтому после него уровень - его
// отступ плюс один. Заголовок подпрограммы с первой колонки - граница.
function CodeLineInLoop(ALines: TStrings; ALine: Integer): Boolean;
var
  I, Ind, Cur: Integer;
  T, U: string;

  function IndentOf(const S: string): Integer;
  begin
    Result := 0;
    while (Result < Length(S)) and (S[Result + 1] in [' ', #9]) do
      Inc(Result);
  end;

begin
  Result := False;
  if (ALine < 0) or (ALine >= ALines.Count) then
    Exit;
  Ind := IndentOf(ALines[ALine]);
  for I := ALine - 1 downto 0 do
  begin
    T := ALines[I];
    U := UpperCase(Trim(T));
    if (U = '') or (Copy(U, 1, 2) = '//') then
      Continue;
    Cur := IndentOf(T);
    if (Cur = 0) and ((Copy(U, 1, 10) = 'PROCEDURE ') or
                      (Copy(U, 1, 9) = 'FUNCTION ') or
                      (Copy(U, 1, 12) = 'CONSTRUCTOR ') or
                      (Copy(U, 1, 11) = 'DESTRUCTOR ')) then
      Exit;
    if Cur >= Ind then
      Continue;
    if (Copy(U, 1, 4) = 'FOR ') or (Copy(U, 1, 6) = 'WHILE ') or
       (U = 'REPEAT') or (Copy(U, 1, 7) = 'REPEAT ') then
    begin
      Result := True;
      Exit;
    end;
    if U = 'BEGIN' then
      Ind := Cur + 1
    else
      Ind := Cur;
  end;
end;

procedure FreeFactories(AFacts: TList);
var
  I: Integer;
begin
  if AFacts = nil then
    Exit;
  for I := 0 to AFacts.Count - 1 do
    TObject(AFacts[I]).Free;
  AFacts.Free;
end;

// ---------------------------------------------------------------------------
//  Кэш разбора формы: dsgcache\<форма>_<crc пути>.objcache
//
//  Разбор .dfm, модуля формы и слияние со снимком дают дерево узлов. Оно
//  пишется в файл целиком, с номерами строк. Ключ - контрольные суммы и
//  длины текста формы, текста модуля и снимка, плюс дата exe (другая сборка
//  редактора могла разбирать иначе). Ключ совпал - дерево читается из
//  файла, разбора нет.
//
//  Запись - после полного разбора и после каждой правки из инспектора
//  (ObjCacheSaveCurrent): узлы в памяти тогда точно отвечают тексту. После
//  правки руками выше объектов - нет: номера поправлены сдвигом, но одна
//  неудачная правка, и кэш хранил бы неверные строки.
//
//  Строки файла - поля через табуляцию:
//    O  имя класс переменная строка конец строка_создания флаги
//    P  строка многострочное имя значение показ   (свойство)
//    E  строка имя обработчик                    (событие)
//    R  номер                                     (ребёнок, уже записанный)
//    X                                            (конец объекта)
//    A  номер номер_родителя                      (Parent узла)
//  Узлы нумеруются по порядку записи O.
// ---------------------------------------------------------------------------

procedure DfmCacheWrite(const AFile, AKey, AInfo: string; ARoots: TList);
var
  SL: TStringList;
  Ids: TList;
  I, P: Integer;

  function Flags(N: TDfmNode): string;
  begin
    Result := '';
    if N.IsSnap then
      Result := Result + 'S';
    if N.IsRuntime then
      Result := Result + 'R';
    if N.IsLink then
      Result := Result + 'K';
    if N.SnapRoot then
      Result := Result + 'T';
    if N.FromCode then
      Result := Result + 'C';
    if N.IsLive then
      Result := Result + 'V';
  end;

  procedure WriteNode(N: TDfmNode);
  var
    K: Integer;
    Raw, RawFlag, V: string;
  begin
    K := Ids.IndexOf(N);
    if K >= 0 then
    begin
      SL.Add('R'#9 + IntToStr(K)); // узел уже записан - ссылка на него
      Exit;
    end;
    Ids.Add(N);
    SL.Add('O'#9 + CacheEsc(N.Name) + #9 + CacheEsc(N.ClassNm) + #9 +
           CacheEsc(N.VarName) + #9 + IntToStr(N.Line) + #9 +
           IntToStr(N.EndLine) + #9 + IntToStr(N.CreateLine) + #9 + Flags(N));
    for K := 0 to N.PropN.Count - 1 do
    begin
      // Текста значения может не быть - тогда флаг -1
      if K < N.PropRaw.Count then
      begin
        Raw := N.PropRaw[K];
        RawFlag := IntToStr(Integer(N.PropRaw.Objects[K]));
      end
      else
      begin
        Raw := '';
        RawFlag := '-1';
      end;
      if K < N.PropV.Count then
        V := N.PropV[K]
      else
        V := '';
      SL.Add('P'#9 + IntToStr(Integer(N.PropN.Objects[K])) + #9 + RawFlag +
             #9 + CacheEsc(N.PropN[K]) + #9 + CacheEsc(Raw) + #9 +
             CacheEsc(V));
    end;
    for K := 0 to N.EvN.Count - 1 do
    begin
      if K < N.EvV.Count then
        V := N.EvV[K]
      else
        V := '';
      SL.Add('E'#9 + IntToStr(Integer(N.EvN.Objects[K])) + #9 +
             CacheEsc(N.EvN[K]) + #9 + CacheEsc(V));
    end;
    for K := 0 to N.Children.Count - 1 do
      WriteNode(TDfmNode(N.Children[K]));
    SL.Add('X');
  end;

begin
  if (AFile = '') or (ARoots = nil) or (ARoots.Count = 0) then
    Exit;
  SL := TStringList.Create;
  Ids := TList.Create;
  try
    SL.Add('SHLC-OBJCACHE'#9'2');
    SL.Add('KEY'#9 + CacheEsc(AKey));
    SL.Add('FILE'#9 + CacheEsc(AInfo));
    for I := 0 to ARoots.Count - 1 do
      WriteNode(TDfmNode(ARoots[I]));
    // Parent - отдельно: родитель может быть записан позже ребёнка
    for I := 0 to Ids.Count - 1 do
      if TDfmNode(Ids[I]).Parent <> nil then
      begin
        P := Ids.IndexOf(TDfmNode(Ids[I]).Parent);
        if P >= 0 then
          SL.Add('A'#9 + IntToStr(I) + #9 + IntToStr(P));
      end;
    try
      ForceDirectories(ExtractFilePath(AFile));
      SL.SaveToFile(AFile);
    except
      // кэш не записался - в следующий раз будет разбор, и только
    end;
  finally
    Ids.Free;
    SL.Free;
  end;
end;

function DfmCacheRead(const AFile, AKey: string; ANodes, ARoots: TList): Boolean;
var
  SL, F: TStringList;
  Nodes, Stack: TList;
  I, Start: Integer;
  T: string;
  N: TDfmNode;

  function Top: TDfmNode;
  begin
    if Stack.Count = 0 then
      raise Exception.Create('cache: нет объекта');
    Result := TDfmNode(Stack[Stack.Count - 1]);
  end;

  procedure Need(ACount: Integer);
  begin
    if F.Count < ACount then
      raise Exception.Create('cache: мало полей');
  end;

begin
  Result := False;
  if (AFile = '') or not FileExists(AFile) or (ANodes = nil) then
    Exit;
  SL := TStringList.Create;
  F := TStringList.Create;
  Nodes := TList.Create;
  Stack := TList.Create;
  Start := ANodes.Count;
  try
    try
      SL.LoadFromFile(AFile);
      if (SL.Count < 2) or (SL[0] <> 'SHLC-OBJCACHE'#9'2') or
         (SL[1] <> 'KEY'#9 + CacheEsc(AKey)) then
        Exit;
      for I := 2 to SL.Count - 1 do
      begin
        T := SL[I];
        if T = '' then
          Continue;
        SplitTabs(T, F);
        case T[1] of
          'O':
            begin
              Need(8);
              N := TDfmNode.Create;
              ANodes.Add(N);
              Nodes.Add(N);
              N.Name := CacheUnesc(F[1]);
              N.ClassNm := CacheUnesc(F[2]);
              N.VarName := CacheUnesc(F[3]);
              N.Line := StrToInt(F[4]);
              N.EndLine := StrToInt(F[5]);
              N.CreateLine := StrToInt(F[6]);
              N.IsSnap := Pos('S', F[7]) > 0;
              N.IsRuntime := Pos('R', F[7]) > 0;
              N.IsLink := Pos('K', F[7]) > 0;
              N.SnapRoot := Pos('T', F[7]) > 0;
              N.FromCode := Pos('C', F[7]) > 0;
              N.IsLive := Pos('V', F[7]) > 0;
              if Stack.Count > 0 then
                Top.Children.Add(N)
              else
                ARoots.Add(N);
              Stack.Add(N);
            end;
          'P':
            begin
              Need(6);
              N := Top;
              N.PropN.AddObject(CacheUnesc(F[3]), TObject(StrToInt(F[1])));
              if StrToInt(F[2]) >= 0 then
                N.PropRaw.AddObject(CacheUnesc(F[4]), TObject(StrToInt(F[2])));
              N.PropV.Add(CacheUnesc(F[5]));
            end;
          'E':
            begin
              Need(4);
              N := Top;
              N.EvN.AddObject(CacheUnesc(F[2]), TObject(StrToInt(F[1])));
              N.EvV.Add(CacheUnesc(F[3]));
            end;
          'R':
            begin
              Need(2);
              N := TDfmNode(Nodes[StrToInt(F[1])]);
              if Stack.Count > 0 then
                Top.Children.Add(N)
              else
                ARoots.Add(N);
            end;
          'X':
            begin
              Top;
              Stack.Delete(Stack.Count - 1);
            end;
          'A':
            begin
              Need(3);
              TDfmNode(Nodes[StrToInt(F[1])]).Parent :=
                TDfmNode(Nodes[StrToInt(F[2])]);
            end;
        end;
      end;
      Result := (ARoots.Count > 0) and (Stack.Count = 0);
    except
      Result := False;
    end;
  finally
    if not Result then
    begin
      for I := ANodes.Count - 1 downto Start do
      begin
        TObject(ANodes[I]).Free;
        ANodes.Delete(I);
      end;
      ARoots.Clear;
    end;
    Stack.Free;
    Nodes.Free;
    F.Free;
    SL.Free;
  end;
end;

// Вливание снимка в дерево из .dfm. .dfm остаётся главным: его узлы и их
// свойства не трогаются. Из снимка берётся только то, чего в .dfm нет.
//
// ATarget - узел результата, соответствующий узлу снимка ASnap. Для каждого
// ребёнка снимка:
//   - есть в .dfm (по имени, в любом месте дерева) - спускаемся в его узел
//     .dfm: созданное в коде внутри него встанет туда;
//   - нет в .dfm - это компонент, созданный в коде: он и его содержимое
//     встают под ATarget с пометкой runtime.
// Компонент из .dfm, который код перенёс в созданную в рантайме панель,
// внутри этой панели показывается ссылкой - без свойств, они у него на
// своём месте.
procedure MergeSnapNode(ATarget, ASnap: TDfmNode; AIndex: TStringList;
                        AGone: TStrings);
var
  Old: TList;
  I, K: Integer;
  Tgt, Snp, C, D: TDfmNode;
begin
  Tgt := TDfmNode(ATarget);
  Snp := TDfmNode(ASnap);

  // Список детей снимка переписывается, если узел сам стал частью
  // результата - поэтому идём по копии
  Old := TList.Create;
  try
    for I := 0 to Snp.Children.Count - 1 do
      Old.Add(Snp.Children[I]);
    if Tgt = Snp then
      Snp.Children.Clear;

    for I := 0 to Old.Count - 1 do
    begin
      C := TDfmNode(Old[I]);
      D := nil;
      if C.Name <> '' then
      begin
        K := AIndex.IndexOf(C.Name);
        if K >= 0 then
          D := TDfmNode(AIndex.Objects[K]);
      end;

      if D <> nil then
      begin
        if Tgt.IsRuntime then
        begin
          C.IsLink := True;
          Tgt.Children.Add(C);
        end;
        MergeSnapNode(D, C, AIndex, AGone);
      end
      else if (AGone <> nil) and (C.Name <> '') and
              (AGone.IndexOf(C.Name) >= 0) then
        // Был в .dfm при сборке exe, из .dfm вкладки убран: это не
        // созданное в коде, а прежний вид формы. Вместе со всем, что в нём
        // лежит, - в дерево не идёт (узел остаётся в общем списке узлов и
        // освобождается с ним).
        Continue
      else
      begin
        C.IsRuntime := True;
        Tgt.Children.Add(C);
        MergeSnapNode(C, C, AIndex, AGone);
      end;
    end;
  finally
    Old.Free;
  end;
end;

// Подпись без знака горячей клавиши: '&Find' -> 'Find', '&&' -> '&'.
// Как StripHotkey из Menus, только без VCL.
function CapStripHotkey(const Text: string): string;
var
  I: Integer;
begin
  Result := Text;
  I := 1;
  while I <= Length(Result) do
  begin
    if Result[I] = '&' then
      Delete(Result, I, 1);
    Inc(I);
  end;
end;

// ---------------------------------------------------------------------------
//  Имена переменных у компонентов, созданных в коде
//
//  Объект не знает, в какой переменной лежит, а RTTI Delphi 7 видит только
//  published-поля, так что FToolbar из снимка не достать. Имя берётся из
//  исходника: каждое X := TКласс.Create(...) и строки X.Parent,
//  X.Caption / X.Text, X.Align после него сверяются с тем, что снимок знает
//  о компоненте. Родитель - уже разрешённый: сначала находится FToolbar
//  (Parent := Self), затем всё, у чего Parent := FToolbar, и так вниз.
//
//  Подходят несколько компонентов под одно описание (кнопки из одного
//  помощника) - имя не ставится: лучше без имени, чем с чужим.
//
//  Родитель в коде - не только X.Parent := P, но и P.Items.Add(X), P.Add(X),
//  P.Items.Insert(N, X), P.Insert(N, X): так в меню попадают пункты. Одинаковые
//  описания у одного родителя (разделители "-") различаются порядком:
//  k-й в коде - k-й среди таких же в снимке. Компонент без родителя и без
//  подписи (TPopupMenu) узнаётся по детям: сколько подписей его пунктов из
//  кода совпадает с подписями детей в снимке.
//
//  Создание через свою функцию-помощник тоже понимается:
//    mFind := MakeItem(Self, mEdit, '&Find', FindPanelClick, ...);
//  Функция модуля считается помощником, если в ней есть
//  Result := TКласс.Create(...). Какой её параметр - родитель
//  (P.Add(Result), P.Items.Add(Result), Result.Parent := P), а какой -
//  подпись (Result.Caption := P), видно из её тела; значения берутся из
//  аргументов вызова. Подпись учитывается, только если аргумент - литерал.
// ---------------------------------------------------------------------------

type
  TCreateRec = class
  public
    LHS, Cls, Par, Cap, Align: string;
    // Все подписи, какие этой переменной присваиваются в модуле: подпись
    // часто меняется в другом месте (mProject.Caption := '&Project' при
    // создании и 'Projects' в BuildProjectsMenu). Подходит любая из них.
    Caps: TStringList;
    Line: Integer;
    Ord: Integer;    // который по счёту среди таких же (Par, Cls, Cap) в коде
    Used: Boolean;
    ParGuess: Boolean; // родитель угадан по аргументу конструктора
    Hint: string;      // подсказка из аргумента помощника-создателя
    // Создание в теле цикла: одна строка кода - несколько компонентов
    // (пункты меню New по списку Kinds). Достаётся всем подходящим узлам.
    InLoop: Boolean;
    procedure AddCap(const S: string);
    destructor Destroy; override;
  end;

procedure TCreateRec.AddCap(const S: string);
begin
  if S = '' then
    Exit;
  if Caps = nil then
    Caps := TStringList.Create;
  if Caps.IndexOf(S) < 0 then
    Caps.Add(S);
  if Cap = '' then
    Cap := S;
end;

destructor TCreateRec.Destroy;
begin
  Caps.Free;
  inherited;
end;

// Подписи совпадают без учёта знака ускорителя: VCL сам вставляет '&' в
// пункты меню (AutoHotkeys), и в снимке 'Projects' оказывается '&Projects'
function CapSame(const A, B: string): Boolean;
begin
  Result := CapStripHotkey(Trim(A)) = CapStripHotkey(Trim(B));
end;

// Подходит ли подпись узла к любой из подписей описания
function RecCapMatches(ARec: TCreateRec; const ACap: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  if ARec.Caps = nil then
    Exit;
  for I := 0 to ARec.Caps.Count - 1 do
    if CapSame(ARec.Caps[I], ACap) then
    begin
      Result := True;
      Exit;
    end;
end;

// Подпись в работе начинается с подписи из кода и длиннее её: к
// 'Compiler' в работе дописано имя проекта - 'Compiler - SyntaxHLClaude'
// (UpdateCompilerCaption через другую переменную, FCompilerBox). Совпадение
// слабее полного, но не противоречие.
function RecCapStarts(ARec: TCreateRec; const ACap: string): Boolean;
var
  I: Integer;
  R, S: string;
begin
  Result := False;
  if ARec.Caps = nil then
    Exit;
  R := CapStripHotkey(Trim(ACap));
  for I := 0 to ARec.Caps.Count - 1 do
  begin
    S := CapStripHotkey(Trim(ARec.Caps[I]));
    if (S <> '') and (Length(R) > Length(S)) and
       (Copy(R, 1, Length(S)) = S) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

// У переменной в коде только пустые подписи (FObjHeader.Caption := '').
// Такая подпись - не примета: пустой Caption у многих панелей, а свою
// настоящую подпись компонент может получать в работе выражением, которого
// разбор не видит. Ни плюса, ни запрета она не даёт.
function RecCapsEmpty(ARec: TCreateRec): Boolean;
var
  I: Integer;
begin
  Result := False;
  if ARec.Caps = nil then
    Exit;
  for I := 0 to ARec.Caps.Count - 1 do
    if Trim(ARec.Caps[I]) <> '' then
      Exit;
  Result := True;
end;

// Кэш ResolveRuntimeNames: описания созданий по последнему тексту модуля
var
  RrnKey: string = '';        // CRC:длина текста; '' - кэша нет
  RrnLines: TStringList = nil;
  RrnRecs: TList = nil;       // TCreateRec
  RrnCrs: TList = nil;        // TFactoryRec

procedure RrnFree;
var
  I: Integer;
begin
  RrnKey := '';
  if RrnRecs <> nil then
    for I := 0 to RrnRecs.Count - 1 do
      TCreateRec(RrnRecs[I]).Free;
  FreeAndNil(RrnRecs);
  FreeFactories(RrnCrs);
  RrnCrs := nil;
  FreeAndNil(RrnLines);
end;

// Строка-объявление поля или переменной: "Panel5: TPanel; // ...",
// "A, B: TLabel;". Описаний созданий в такой строке нет: ни присваивания,
// ни вызова, ни скобок комментария, которые меняли бы смысл соседних строк.
// Заголовок без скобок ("function GetX: TPanel;") объявлением не считается:
// это граница процедуры и, бывает, помощник-создатель. Пустая строка и
// строка-комментарий // - тоже годятся.
function RrnPlainLine(const ALine: string): Boolean;
var
  Code, Before, After, FirstWord: string;
  CharIdx, CommentPos, ColonPos: Integer;
begin
  Code := ALine;
  CommentPos := Pos('//', Code);
  if CommentPos > 0 then
    Code := Copy(Code, 1, CommentPos - 1);
  Code := Trim(Code);
  Result := True;
  if Code = '' then
    Exit;
  Result := False;
  for CharIdx := 1 to Length(Code) do
    if not (Code[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_', ' ', #9,
                               ',', ':', ';', '.']) then
      Exit;
  ColonPos := Pos(':', Code);
  if (ColonPos <= 1) or (Code[Length(Code)] <> ';') then
    Exit;
  // Слева - имена через запятую, справа - один тип (можно с модулем)
  Before := Trim(Copy(Code, 1, ColonPos - 1));
  After := Trim(Copy(Code, ColonPos + 1, Length(Code) - ColonPos - 1));
  if (After = '') or (Pos(':', After) > 0) or (Pos(' ', After) > 0) or
     (Pos(',', After) > 0) or (Pos(';', After) > 0) then
    Exit;
  if (Pos(';', Before) > 0) or (Pos('.', Before) > 0) then
    Exit;
  FirstWord := Before;
  CharIdx := 1;
  while (CharIdx <= Length(FirstWord)) and
        (FirstWord[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
    Inc(CharIdx);
  FirstWord := LowerCase(Copy(FirstWord, 1, CharIdx - 1));
  if (FirstWord = 'procedure') or (FirstWord = 'function') or
     (FirstWord = 'constructor') or (FirstWord = 'destructor') or
     (FirstWord = 'property') or (FirstWord = 'class') or
     (FirstWord = 'var') or (FirstWord = 'const') or (FirstWord = 'type') or
     (FirstWord = 'out') or (FirstWord = 'label') or (FirstWord = 'case') then
    Exit;
  Result := True;
end;

// Где новый текст отличается от прежнего: строки [AHead, AOldEnd) прежнего
// стали строками [AHead, ANewEnd) нового. True - отличие небольшое и только
// в строках-объявлениях (RrnPlainLine).
function CodeDiffPlain(AOld, ANew: TStrings;
                       var AHead, AOldEnd, ANewEnd: Integer): Boolean;
const
  DiffMaxLines = 500;
var
  Idx: Integer;
begin
  Result := False;
  AHead := 0;
  while (AHead < AOld.Count) and (AHead < ANew.Count) and
        (AOld[AHead] = ANew[AHead]) do
    Inc(AHead);
  AOldEnd := AOld.Count;
  ANewEnd := ANew.Count;
  while (AOldEnd > AHead) and (ANewEnd > AHead) and
        (AOld[AOldEnd - 1] = ANew[ANewEnd - 1]) do
  begin
    Dec(AOldEnd);
    Dec(ANewEnd);
  end;
  if (AOldEnd - AHead > DiffMaxLines) or (ANewEnd - AHead > DiffMaxLines) then
    Exit;
  for Idx := AHead to AOldEnd - 1 do
    if not RrnPlainLine(AOld[Idx]) then
      Exit;
  for Idx := AHead to ANewEnd - 1 do
    if not RrnPlainLine(ANew[Idx]) then
      Exit;
  Result := True;
end;

// Номер строки ALine прежнего текста - в новом. False - строка была среди
// изменившихся.
function CodeShiftLine(var ALine: Integer; AHead, AOldEnd, ADelta: Integer): Boolean;
begin
  Result := True;
  if ALine < AHead then
    Exit;
  if ALine < AOldEnd then
  begin
    Result := False;
    Exit;
  end;
  Inc(ALine, ADelta);
end;

// Текст модуля изменился только в строках-объявлениях (конструктор форм
// убрал или добавил поле компонента): описания созданий прежние, у них
// сдвигаются только номера строк. Разбор всего модуля заново (у Unit1.pas
// это сотни миллисекунд на каждую правку в конструкторе) не нужен.
// True - кэш переведён на новый текст.
function RrnRemap(const AText, AKey: string): Boolean;
var
  NewLines: TStringList;
  HeadCnt, OldEnd, NewEnd, Delta, Idx: Integer;
  Rec: TCreateRec;
  Fact: TFactoryRec;
begin
  Result := False;
  if (RrnKey = '') or (RrnLines = nil) or (RrnRecs = nil) or (RrnCrs = nil) then
    Exit;
  NewLines := TStringList.Create;
  try
    NewLines.Text := AText;
    // Изменились строки [HeadCnt, OldEnd) прежнего текста - теперь
    // [HeadCnt, NewEnd). Большая правка или не объявления - разбор заново.
    if not CodeDiffPlain(RrnLines, NewLines, HeadCnt, OldEnd, NewEnd) then
      Exit;
    for Idx := 0 to RrnRecs.Count - 1 do
    begin
      Rec := TCreateRec(RrnRecs[Idx]);
      if (Rec.Line >= HeadCnt) and (Rec.Line < OldEnd) then
        Exit;
    end;
    for Idx := 0 to RrnCrs.Count - 1 do
    begin
      Fact := TFactoryRec(RrnCrs[Idx]);
      if (Fact.HdrLine >= HeadCnt) and (Fact.HdrLine < OldEnd) then
        Exit;
      if (Fact.EndLine >= HeadCnt) and (Fact.EndLine < OldEnd) then
        Exit;
    end;

    Delta := NewEnd - OldEnd;
    if Delta <> 0 then
    begin
      for Idx := 0 to RrnRecs.Count - 1 do
      begin
        Rec := TCreateRec(RrnRecs[Idx]);
        if Rec.Line >= OldEnd then
          Inc(Rec.Line, Delta);
      end;
      for Idx := 0 to RrnCrs.Count - 1 do
      begin
        Fact := TFactoryRec(RrnCrs[Idx]);
        if Fact.HdrLine >= OldEnd then
          Inc(Fact.HdrLine, Delta);
        if Fact.EndLine >= OldEnd then
          Inc(Fact.EndLine, Delta);
      end;
    end;
    RrnLines.Free;
    RrnLines := NewLines;
    NewLines := nil;
    RrnKey := AKey;
    Result := True;
  finally
    NewLines.Free;
  end;
end;

procedure ResolveRuntimeNames(ARoot: TDfmNode; const AText: string);
var
  Lines: TStringList;
  Recs: TList;
  Key: string;
  // Помощники модуля (TFactoryRec, CodeCollectFactories): функции,
  // процедуры-создатели и процедуры-настройщики
  Crs: TList;
  // Описания с подписью по имени родителя - для ChildMatches
  ByPar: TStringList;
  CVar, CPar, CCap: string;
  Args, Prms: TStringList;
  F: TFactoryRec;
  K, Depth: Integer;
  Call: string;
  InQuote: Boolean;
  I, J, Q, B, E: Integer; // E - и во вложенной ParseCreate
  T, TU, Cls, Lhs, V: string;
  R: TCreateRec;

  // Правая часть присваивания: идентификатор (Self, FToolbar, alTop)
  function IdentAfterAssign(const ALine: string): string;
  var
    S: string;
    K: Integer;
  begin
    Result := '';
    K := Pos(':=', ALine);
    if K <= 0 then
      Exit;
    S := Trim(Copy(ALine, K + 2, MaxInt));
    K := 1;
    while (K <= Length(S)) and
          (S[K] in ['a'..'z', 'A'..'Z', '0'..'9', '_', '.']) do
      Inc(K);
    Result := Copy(S, 1, K - 1);
  end;

  // Строковый литерал справа от := : 'текст' и #коды до ';' или комментария
  function LiteralAfterAssign(const ALine: string): string;
  var
    S: string;
    K: Integer;
    InQ: Boolean;
  begin
    Result := '';
    K := Pos(':=', ALine);
    if K <= 0 then
      Exit;
    S := Trim(Copy(ALine, K + 2, MaxInt));
    if (S = '') or not (S[1] in ['''', '#']) then
      Exit;
    K := 1;
    InQ := False;
    while K <= Length(S) do
    begin
      if S[K] = '''' then
        InQ := not InQ
      else if not InQ and not (S[K] in ['#', '0'..'9', '+', ' ']) then
        Break;
      Inc(K);
    end;
    Result := DecodeDfmString(Trim(Copy(S, 1, K - 1)));
  end;

  // "  X := TКласс.Create(" -> класс и переменная. Комментарий в конце
  // строки не читается.
  function ParseCreate(const ALine: string; var AClass, ALhs: string): Boolean;
  var
    S, SU: string;
    K, P: Integer;
  begin
    Result := False;
    S := Trim(ALine);
    if Copy(S, 1, 2) = '//' then
      Exit;
    S := CodeNoComment(S);
    SU := UpperCase(S);
    P := CodeCreatePos(SU);
    if P <= 0 then
      Exit;
    K := P - 1;
    while (K >= 1) and (S[K] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) do
      Dec(K);
    AClass := Copy(S, K + 1, P - 1 - K);
    ALhs := '';
    E := Pos(':=', S);
    if (E > 0) and (E < K + 1) then
      ALhs := Trim(Copy(S, 1, E - 1));
    Result := AClass <> '';
  end;

  // Аргументы вызова верхнего уровня: "Self, mEdit, 'a, b', F(1, 2)" ->
  // четыре строки. Запятые в строках и во вложенных скобках не делят.
  procedure SplitArgs(const S: string; AList: TStrings);
  var
    P, D: Integer;
    Q: Boolean;
    Cur: string;
  begin
    AList.Clear;
    D := 0;
    Q := False;
    Cur := '';
    for P := 1 to Length(S) do
    begin
      if S[P] = '''' then
        Q := not Q;
      if not Q then
      begin
        if S[P] = '(' then
          Inc(D)
        else if S[P] = ')' then
          Dec(D)
        else if (S[P] = ',') and (D = 0) then
        begin
          AList.Add(Trim(Cur));
          Cur := '';
          Continue;
        end;
      end;
      Cur := Cur + S[P];
    end;
    if Trim(Cur) <> '' then
      AList.Add(Trim(Cur));
  end;


  // Помощник по имени, nil - нет такого
  function FindFactory(const AName: string): TFactoryRec;
  var
    M: Integer;
  begin
    Result := nil;
    for M := 0 to Crs.Count - 1 do
      if (TFactoryRec(Crs[M]).Cls <> '') and
         (CompareText(TFactoryRec(Crs[M]).Name, AName) = 0) then
      begin
        Result := TFactoryRec(Crs[M]);
        Exit;
      end;
  end;

  function PropOf(N: TDfmNode; const AName: string): string;
  var
    K: Integer;
  begin
    Result := '';
    K := N.PropN.IndexOf(AName);
    if K >= 0 then
      Result := N.PropV[K];
  end;

  // Сколько подписей детей этого описания в коде (P.Items.Add(X) и т.п.)
  // совпадает с подписями детей узла в снимке. Дети описания - из ByPar:
  // перебирать все описания на каждый вызов - сотни тысяч сравнений.
  function ChildMatches(ARec: TCreateRec; N: TDfmNode): Integer;
  var
    K, L: Integer;
    CR: TCreateRec;
    CN: TDfmNode;
  begin
    Result := 0;
    if (ARec.LHS = '') or not ByPar.Find(ARec.LHS, K) then
      Exit;
    // Find в списке с повторами - первое совпадение; на всякий случай
    // отступаем к началу группы
    while (K > 0) and (CompareText(ByPar[K - 1], ARec.LHS) = 0) do
      Dec(K);
    for K := K to ByPar.Count - 1 do
    begin
      if CompareText(ByPar[K], ARec.LHS) <> 0 then
        Break;
      CR := TCreateRec(ByPar.Objects[K]);
      for L := 0 to N.Children.Count - 1 do
      begin
        CN := TDfmNode(N.Children[L]);
        if RecCapMatches(CR, PropOf(CN, 'Caption')) or
           RecCapMatches(CR, PropOf(CN, 'Text')) then
        begin
          Inc(Result);
          Break;
        end;
      end;
    end;
  end;

  // Насколько описание из исходника подходит узлу. -1 - противоречит.
  // AOrd - который по счёту узел среди братьев того же класса и подписи.
  function Score(ARec: TCreateRec; N: TDfmNode; const AParent: string;
                 AOrd: Integer): Integer;
  var
    C: string;
  begin
    Result := -1;
    if CompareText(ARec.Cls, N.ClassNm) <> 0 then
      Exit;
    Result := 2 * ChildMatches(ARec, N);
    if ARec.Par <> '' then
      if CompareText(ARec.Par, AParent) = 0 then
        Inc(Result, 10)
      else
      begin
        Result := -1;
        Exit;
      end;
    if (ARec.Caps <> nil) and not RecCapsEmpty(ARec) then
    begin
      C := PropOf(N, 'Caption');
      if C = '' then
        C := PropOf(N, 'Text');
      if RecCapMatches(ARec, C) then
        Inc(Result, 10)
      else if RecCapStarts(ARec, C) then
        Inc(Result, 5)   // к подписи из кода в работе что-то дописали
      else
      begin
        Result := -1;
        Exit;
      end;
    end;
    if ARec.Align <> '' then
      if CompareText(ARec.Align, PropOf(N, 'Align')) = 0 then
        Inc(Result, 3)
      else
      begin
        Result := -1;
        Exit;
      end;
    // Подсказка из аргумента помощника различает одинаковые кнопки
    // (MakeCmpButton(btnViewUnit, 1, 'View Unit - ...')). Не совпала - не
    // запрет: подсказку могли поменять в работе.
    if (ARec.Hint <> '') and (ARec.Hint = PropOf(N, 'Hint')) then
      Inc(Result, 10);
    // Порядок - только довесок к остальным совпадениям: различает
    // одинаковые описания у одного родителя (разделители)
    if (Result > 0) and (ARec.Ord = AOrd) then
      Inc(Result);
  end;

  // Который по счёту узел K среди братьев того же класса и подписи
  function NodeOrd(AParentNode: TDfmNode; K: Integer): Integer;
  var
    M: Integer;
    A, B: TDfmNode;
    CapA: string;
  begin
    Result := 0;
    A := TDfmNode(AParentNode.Children[K]);
    CapA := PropOf(A, 'Caption');
    for M := 0 to K - 1 do
    begin
      B := TDfmNode(AParentNode.Children[M]);
      if (CompareText(B.ClassNm, A.ClassNm) = 0) and
         (PropOf(B, 'Caption') = CapA) then
        Inc(Result);
    end;
  end;

  // Братья под одним родителем: у каждого безымянного - лучшее описание.
  // Описание, лучшее сразу для двоих, не достаётся никому.
  procedure ResolveLevel(AParentNode: TDfmNode; const AParentName: string);
  var
    K, M, Best, BestSc, Sc, Cnt, Top, Ord: Integer;
    C: TDfmNode;
    Pick, PickSc: array of Integer;
    Tie, Changed: Boolean;
    ChildName: string;
  begin
    // Проходов несколько: описание, которое досталось одному узлу, выходит
    // из игры, и у другого узла, где была ничья или спор, может остаться
    // единственный подходящий вариант. Так BtnPnl и FObjHeader - две
    // безымянные TPanel у одного родителя - расходятся по своим именам.
    repeat
      Changed := False;
      SetLength(Pick, AParentNode.Children.Count);
      SetLength(PickSc, AParentNode.Children.Count);
      for K := 0 to AParentNode.Children.Count - 1 do
      begin
        Pick[K] := -1;
        PickSc[K] := 0;
        C := TDfmNode(AParentNode.Children[K]);
        // Имя ищем только у узлов снимка: у узлов из кода оно уже есть.
        // Уже названные на прошлом проходе - пропускаем.
        if C.IsLink or (C.Name <> '') or not C.IsSnap or (C.VarName <> '') then
          Continue;
        Best := -1;
        BestSc := 0;
        Tie := False;
        // Порядок узла среди братьев не зависит от описания - считаем раз
        Ord := NodeOrd(AParentNode, K);
        for M := 0 to Recs.Count - 1 do
        begin
          // Использованное описание выходит из игры - кроме созданного в
          // цикле: одна его строка создаёт много компонентов
          if (TCreateRec(Recs[M]).Used and not TCreateRec(Recs[M]).InLoop) or
             (TCreateRec(Recs[M]).LHS = '') then
            Continue; // без переменной - только свидетель для родителя
          Sc := Score(TCreateRec(Recs[M]), C, AParentName, Ord);
          if Sc <= 0 then
            Continue;
          if Sc > BestSc then
          begin
            BestSc := Sc;
            Best := M;
            Tie := False;
          end
          else if Sc = BestSc then
            Tie := True;
        end;
        if not Tie then
        begin
          Pick[K] := Best;
          PickSc[K] := BestSc;
        end;
      end;

      // Одно описание - одному компоненту. Если его выбрали несколько узлов,
      // оно достаётся тому, кому подходит строго лучше остальных; при
      // равенстве - никому (лучше без имени, чем с чужим).
      for K := 0 to High(Pick) do
      begin
        if Pick[K] < 0 then
          Continue;
        Top := 0;
        Cnt := 0;
        for M := 0 to High(Pick) do
          if Pick[M] = Pick[K] then
            if PickSc[M] > Top then
            begin
              Top := PickSc[M];
              Cnt := 1;
            end
            else if PickSc[M] = Top then
              Inc(Cnt);
        // Описание из цикла делить не надо - оно общее для всех своих
        if not TCreateRec(Recs[Pick[K]]).InLoop and
           ((PickSc[K] <> Top) or (Cnt > 1)) then
          Continue;
        C := TDfmNode(AParentNode.Children[K]);
        C.VarName := TCreateRec(Recs[Pick[K]]).LHS;
        C.CreateLine := TCreateRec(Recs[Pick[K]]).Line;
        Changed := True;
      end;
      for K := 0 to High(Pick) do
        if (Pick[K] >= 0) and (TDfmNode(AParentNode.Children[K]).VarName <> '') then
          TCreateRec(Recs[Pick[K]]).Used := True;
    until not Changed;

    // Вниз: имя родителя для детей - имя из .dfm или найденная переменная
    for K := 0 to AParentNode.Children.Count - 1 do
    begin
      C := TDfmNode(AParentNode.Children[K]);
      if C.IsLink then
        Continue;
      if C.Name <> '' then
        ChildName := C.Name
      else
        ChildName := C.VarName;
      ResolveLevel(C, ChildName);
    end;
  end;

begin
  if (ARoot = nil) or (AText = '') then
    Exit;

  // Описания созданий зависят только от текста модуля. Форму разбирают
  // заново и при том же тексте - снимок другой, правка .dfm в конструкторе:
  // тогда описания берутся из прошлого вызова, только с Used - заново.
  Key := IntToHex(Crc32Of(AText), 8) + ':' + IntToStr(Length(AText));
  if (Key = RrnKey) or RrnRemap(AText, Key) then
  begin
    Lines := RrnLines;
    Recs := RrnRecs;
    Crs := RrnCrs;
    for I := 0 to Recs.Count - 1 do
      TCreateRec(Recs[I]).Used := False;
  end
  else
  begin
    RrnFree;
    Lines := TStringList.Create;
    Recs := TList.Create;
    Crs := TList.Create;
    RrnLines := Lines;
    RrnRecs := Recs;
    RrnCrs := Crs;
    Args := TStringList.Create;
    Prms := TStringList.Create;
    try
      Lines.Text := AText;
      // Помощники - общим разбором, тем же, что у BuildCodeRuntime
      CodeCollectFactories(Lines, Crs);

      // Описания созданий: класс, переменная и то, что ей присвоено ниже
      for I := 0 to Lines.Count - 1 do
      begin
        // Создание через помощник: X := MakeItem(Self, mEdit, '&Find', ...).
        // Вызов без присваивания (MakeItem(Self, FTabsPopup.Items, ...))
        // тоже учитывается, с пустой переменной: имя из него не взять, но
        // по его подписи узнаётся родитель.
        T := Trim(Lines[I]);
        B := Pos(':=', T);
        if (Copy(T, 1, 2) <> '//') and (Crs.Count > 0) then
        begin
          if B > 0 then
          begin
            Lhs := Trim(Copy(T, 1, B - 1));
            V := Trim(Copy(T, B + 2, MaxInt));
          end
          else
          begin
            Lhs := '';
            V := T;
          end;
          Q := Pos('(', V);
          if (Q > 0) and ((Lhs = '') or IsValidIdent(Lhs)) and
             (Pos('.', Trim(Copy(V, 1, Q - 1))) = 0) then
          begin
            // Функция-помощник или процедура-создатель (MakeCmpButton(btnX,
            // ...)). Создатель вызывается только без присваивания.
            F := FindFactory(Trim(Copy(V, 1, Q - 1)));
            if (F <> nil) and (B > 0) and (F.OutIdx >= 0) then
              F := nil;
            if F <> nil then
            begin
              // Вызов целиком, он может занимать несколько строк
              Call := Copy(V, Q + 1, MaxInt);
              J := I;
              repeat
                Depth := 1;
                InQuote := False;
                for K := 1 to Length(Call) do
                  if Call[K] = '''' then
                    InQuote := not InQuote
                  else if not InQuote then
                    if Call[K] = '(' then
                      Inc(Depth)
                    else if Call[K] = ')' then
                    begin
                      Dec(Depth);
                      if Depth = 0 then
                      begin
                        SetLength(Call, K - 1);
                        Break;
                      end;
                    end;
                if (Depth = 0) or (J + 1 >= Lines.Count) or (J > I + 6) then
                  Break;
                Inc(J);
                Call := Call + ' ' + Trim(Lines[J]);
              until False;
              SplitArgs(Call, Args);

              // Создатель: переменная - аргумент на месте var-параметра
              if F.OutIdx >= 0 then
              begin
                Lhs := '';
                if (F.OutIdx < Args.Count) and IsValidIdent(Trim(Args[F.OutIdx])) then
                  Lhs := Trim(Args[F.OutIdx]);
              end;

              R := TCreateRec.Create;
              R.LHS := Lhs;
              R.Cls := F.Cls;
              R.Line := I;
              R.Par := F.FixedPar;
              if (F.ParIdx >= 0) and (F.ParIdx < Args.Count) then
              begin
                V := Args[F.ParIdx];
                // FTabsPopup.Items -> FTabsPopup
                if CompareText(Copy(V, Length(V) - 5, 6), '.Items') = 0 then
                  Delete(V, Length(V) - 5, 6);
                if IsValidIdent(V) then
                  R.Par := V;
              end;
              if (F.CapIdx >= 0) and (F.CapIdx < Args.Count) and
                 (Args[F.CapIdx] <> '') and (Args[F.CapIdx][1] in ['''', '#']) then
                R.AddCap(DecodeDfmString(Args[F.CapIdx]));
              if (F.HintIdx >= 0) and (F.HintIdx < Args.Count) and
                 (Args[F.HintIdx] <> '') and (Args[F.HintIdx][1] in ['''', '#']) then
                R.Hint := DecodeDfmString(Args[F.HintIdx]);
              Recs.Add(R);
              Continue;
            end;
          end;
        end;

        if not ParseCreate(Lines[I], Cls, Lhs) then
          Continue;
        if (Lhs = '') or (CompareText(Lhs, 'Result') = 0) then
          Continue;
        // Создание в теле процедуры-создателя - это её вызовы, не строка
        if CodeInCreatorBody(Crs, I, Lhs) then
          Continue;

        R := TCreateRec.Create;
        R.LHS := Lhs;
        R.Cls := Cls;
        R.Line := I;
        Recs.Add(R);

        for J := I + 1 to I + 80 do
        begin
          if J >= Lines.Count then
            Break;
          T := Trim(Lines[J]);
          // Создание другой переменной - дальше описание не наше
          if ParseCreate(T, V, TU) and (CompareText(TU, Lhs) <> 0) then
            Break;
          TU := AnsiUpperCase(T);
          Q := Length(Lhs) + 1;
          if Copy(TU, 1, Q) <> AnsiUpperCase(Lhs) + '.' then
            Continue;
          B := Pos(':=', T);
          if B <= 0 then
            Continue;
          V := UpperCase(Trim(Copy(T, Q + 1, B - Q - 1)));
          if V = 'PARENT' then
            R.Par := IdentAfterAssign(T)
          else if (V = 'CAPTION') or (V = 'TEXT') then
            R.AddCap(LiteralAfterAssign(T))
          else if V = 'ALIGN' then
            R.Align := IdentAfterAssign(T);
        end;
      end;

      // Родитель через добавление: P.Items.Add(X), P.Add(X), P.Items.Insert(N,
      // X), P.Insert(N, X). Так в меню попадают пункты - Parent у них нет.
      for I := 0 to Lines.Count - 1 do
      begin
        T := Trim(Lines[I]);
        if Copy(T, 1, 2) = '//' then
          Continue;
        TU := UpperCase(T);
        B := Pos('.ADD(', TU);
        if B = 0 then
        begin
          B := Pos('.INSERT(', TU);
          if B = 0 then
            Continue;
          V := Copy(T, B + 8, MaxInt);       // "N, X);"
          Q := Pos(',', V);
          if Q = 0 then
            Continue;
          V := Trim(Copy(V, Q + 1, MaxInt));
        end
        else
          V := Trim(Copy(T, B + 5, MaxInt));  // "X);"
        Q := 1;
        while (Q <= Length(V)) and (V[Q] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) do
          Inc(Q);
        V := Copy(V, 1, Q - 1);             // X
        Lhs := Trim(Copy(T, 1, B - 1));       // P или P.Items
        if CompareText(Copy(Lhs, Length(Lhs) - 5, 6), '.Items') = 0 then
          Delete(Lhs, Length(Lhs) - 5, 6);
        if (V = '') or (Lhs = '') or (Pos('.', Lhs) > 0) or (Pos(' ', Lhs) > 0) then
          Continue;
        // Последнее создание X выше этой строки
        for J := Recs.Count - 1 downto 0 do
        begin
          R := TCreateRec(Recs[J]);
          if (R.Line < I) and (CompareText(R.LHS, V) = 0) then
          begin
            if R.Par = '' then
              R.Par := Lhs;
            Break;
          end;
        end;
      end;

      // Родитель и подпись из процедуры-настройщика:
      // SetupSwatch(pnlGutterBG, 'BG', ...) - APanel.Parent := grpEditorColors
      for I := 0 to Lines.Count - 1 do
        if CodeConfCall(Lines, I, Crs, CVar, CPar, CCap) then
          for J := Recs.Count - 1 downto 0 do
          begin
            R := TCreateRec(Recs[J]);
            if (R.Line < I) and (CompareText(R.LHS, CVar) = 0) then
            begin
              if R.Par = '' then
                R.Par := CPar;
              if (CCap <> '') and (CCap[1] in ['''', '#']) then
                R.AddCap(DecodeDfmString(CCap));
              Break;
            end;
          end;

      // Родитель, переданный конструктору (TDsgPalette.CreatePalette(Self,
      // pnlPaletteIn, ...)): первый аргумент, который сам создан в коде
      for I := 0 to Recs.Count - 1 do
      begin
        R := TCreateRec(Recs[I]);
        if (R.Par <> '') or (R.LHS = '') then
          Continue;
        T := Lines[R.Line];
        Q := CodeCreatePos(UpperCase(T));
        if Q = 0 then
          Continue;
        T := Copy(T, Q + 1, MaxInt);
        Q := Pos('(', T);
        B := LastDelimiter(')', T);
        if (Q = 0) or (B <= Q) then
          Continue;
        SplitArgs(Copy(T, Q + 1, B - Q - 1), Args);
        for J := 0 to Args.Count - 1 do
        begin
          V := Trim(Args[J]);
          if not IsValidIdent(V) or (CompareText(V, 'Self') = 0) or
             (CompareText(V, 'nil') = 0) or (CompareText(V, 'Owner') = 0) or
             (CompareText(V, 'AOwner') = 0) or
             (CompareText(V, 'Application') = 0) then
            Continue;
          for K := 0 to Recs.Count - 1 do
            if (K <> I) and (CompareText(TCreateRec(Recs[K]).LHS, V) = 0) then
            begin
              R.Par := V;
              R.ParGuess := True;
              Break;
            end;
          if R.Par <> '' then
            Break;
        end;
      end;

      // Родитель, присвоенный далеко от создания: окно после создания
      // обрывается на создании следующей переменной, а родителя часто ставят
      // позже, когда готов контейнер (udPale.Parent := grpIndent - через
      // сотню строк после udPale := TUpDown.Create). Относится к последнему
      // созданию X выше строки.
      for I := 0 to Lines.Count - 1 do
      begin
        T := Trim(Lines[I]);
        if Copy(T, 1, 2) = '//' then
          Continue;
        B := Pos(':=', T);
        if B = 0 then
          Continue;
        TU := UpperCase(Trim(Copy(T, 1, B - 1)));
        Q := LastDelimiter('.', TU);
        if Q = 0 then
          Continue;
        V := Copy(TU, Q + 1, MaxInt);
        if (V <> 'PARENT') and (V <> 'PAGECONTROL') then
          Continue;
        Lhs := Trim(Copy(T, 1, Q - 1));
        if not IsValidIdent(Lhs) then
          Continue;
        for J := Recs.Count - 1 downto 0 do
        begin
          R := TCreateRec(Recs[J]);
          if (R.Line < I) and (CompareText(R.LHS, Lhs) = 0) then
          begin
            // Явный .Parent важнее догадки по аргументу конструктора
            if (R.Par = '') or R.ParGuess then
            begin
              R.Par := IdentAfterAssign(T);
              R.ParGuess := False;
            end;
            Break;
          end;
        end;
      end;

      // Подписи, присвоенные где угодно в модуле: X.Caption := '...'.
      // Относятся к последнему созданию X выше строки, а если выше его нет
      // (подпись меняется в методе, который стоит в тексте раньше) - к
      // первому созданию X.
      for I := 0 to Lines.Count - 1 do
      begin
        T := Trim(Lines[I]);
        if Copy(T, 1, 2) = '//' then
          Continue;
        B := Pos(':=', T);
        if B = 0 then
          Continue;
        TU := UpperCase(Trim(Copy(T, 1, B - 1)));
        Q := LastDelimiter('.', TU);
        if Q = 0 then
          Continue;
        V := Copy(TU, Q + 1, MaxInt);
        if (V <> 'CAPTION') and (V <> 'TEXT') then
          Continue;
        Lhs := Trim(Copy(T, 1, Q - 1));
        if not IsValidIdent(Lhs) then
          Continue;
        V := LiteralAfterAssign(T);
        if V = '' then
          Continue;
        R := nil;
        for J := 0 to Recs.Count - 1 do
          if CompareText(TCreateRec(Recs[J]).LHS, Lhs) = 0 then
          begin
            if (R = nil) or (TCreateRec(Recs[J]).Line < I) then
              R := TCreateRec(Recs[J]);
            if TCreateRec(Recs[J]).Line > I then
              Break;
          end;
        if R <> nil then
          R.AddCap(V);
      end;

      // Родитель - параметр процедуры: подставляем аргумент из её вызова
      for I := 0 to Recs.Count - 1 do
      begin
        R := TCreateRec(Recs[I]);
        if R.Par <> '' then
          R.Par := CodeResolveParamPar(Lines, R.Line, R.Par);
      end;

      // Создания в теле цикла
      for I := 0 to Recs.Count - 1 do
        TCreateRec(Recs[I]).InLoop :=
          CodeLineInLoop(Lines, TCreateRec(Recs[I]).Line);

      // Порядок одинаковых описаний у одного родителя
      for I := 0 to Recs.Count - 1 do
      begin
        R := TCreateRec(Recs[I]);
        R.Ord := 0;
        for J := 0 to I - 1 do
          if (CompareText(TCreateRec(Recs[J]).Par, R.Par) = 0) and
             (CompareText(TCreateRec(Recs[J]).Cls, R.Cls) = 0) and
             (TCreateRec(Recs[J]).Cap = R.Cap) then
            Inc(R.Ord);
      end;

      // Сбор дошёл до конца - описания годятся и для следующих вызовов
      RrnKey := Key;
    finally
      Args.Free;
      Prms.Free;
    end;
  end;

  ByPar := TStringList.Create;
  try
    // Дети по родителю, у кого есть подпись (кроме разделителей '-')
    ByPar.CaseSensitive := False;
    ByPar.Sorted := True;
    ByPar.Duplicates := dupAccept;
    for I := 0 to Recs.Count - 1 do
    begin
      R := TCreateRec(Recs[I]);
      if (R.Caps <> nil) and (R.Cap <> '-') and (R.Par <> '') then
        ByPar.AddObject(R.Par, R);
    end;

    // Корень - сама форма: для её детей родитель в коде - Self
    ResolveLevel(TDfmNode(ARoot), 'Self');
  finally
    ByPar.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Созданное в коде - из исходника модуля формы
//
//  Основной путь для runtime-компонентов: работает сразу при открытии
//  формы, для любого проекта и без запуска программы. Имена точные - они
//  берутся из самой строки X := TКласс.Create(...).
//
//  Что попадает в дерево:
//    - поля класса формы, созданные в коде (FToolbar, FTabs);
//    - локальные переменные, если им назначен родитель (панели и вкладки,
//      собранные внутри процедуры). Временные окна без родителя (Dlg) -
//      нет: это не часть формы.
//  Родитель - из X.Parent := Y, у вкладок - X.PageControl := Y, у пунктов
//  меню - Y.Add(X). Y - Self, имя из .dfm или другая переменная; у
//  переменной берётся ближайшее создание выше по тексту - локальные имена
//  повторяются в разных процедурах.
//  Свойства и события - строки X.Имя := значение в той же процедуре, как
//  они написаны в коде. Двойной щелчок по свойству - к его строке.
//
//  Помощники модуля (функции X := MakeBtn(...), процедуры-создатели и
//  настройщики) понимаются через CodeCollectFactories. Чего разбор не
//  видит: with TКласс.Create do, массивы, Parent := AParent в чужом модуле.
//  Что создано, но к родителю не привязалось, - в ветке "родитель не
//  определён".
// ---------------------------------------------------------------------------


type
  TCodeRec = class
  public
    LHS, Cls, Par: string;
    Cap: string;     // подпись из аргумента помощника, как записана
    Line, ParLine, EndLine: Integer;
    Node: TDfmNode;
    // Лежит внутри временного окна (Dlg := TForm.Create) - в дерево формы
    // не идёт: живёт, пока открыт диалог
    Dropped: Boolean;
    // Только у записей кэша: идёт ли в дерево и свойства будущего узла
    InTree: Boolean;
    Tpl: TDfmNode;
    destructor Destroy; override;
  end;

destructor TCodeRec.Destroy;
begin
  Tpl.Free;
  inherited;
end;

// Кэш BuildCodeRuntime: создания, их свойства и родители из текста модуля.
// Зависят от текста, класса формы, AFull и имён компонентов .dfm (родитель
// бывает угадан по аргументу конструктора - имени из .dfm). Раскладка по
// узлам дерева делается каждый раз заново - по копиям записей.
var
  CbrKey: string = '';
  CbrLines: TStringList = nil;
  CbrRecs: TList = nil;         // TCodeRec с шаблонами узлов
  CbrNames: TStringList = nil;  // имена .dfm, по которым собран кэш
  CbrClassFull: string = '';    // класс формы и AFull того же сбора

procedure CbrFree;
var
  I: Integer;
begin
  CbrKey := '';
  CbrClassFull := '';
  FreeAndNil(CbrNames);
  if CbrRecs <> nil then
    for I := 0 to CbrRecs.Count - 1 do
      TCodeRec(CbrRecs[I]).Free;
  FreeAndNil(CbrRecs);
  FreeAndNil(CbrLines);
end;

// Кэш BuildCodeRuntime - на новый текст модуля и новые имена .dfm без
// разбора модуля, если правка - только строки-объявления (конструктор форм
// убрал или добавил поле компонента: Cut, Delete, Paste). Записи кэша
// верны, если:
//  - ни одна их строка (создание, родитель, свойство, событие) не среди
//    изменившихся - строки ниже правки сдвигаются;
//  - переменная записи не объявлена в изменившихся строках: от того, поле
//    ли она формы, зависит, идёт ли запись в дерево;
//  - ни одно имя .dfm, которое появилось или пропало, не стоит в строке
//    создания: по нему угадывается родитель из аргумента конструктора.
// True - кэш переведён на новый текст и имена.
function CbrRemap(const AText, AKey, AClassFull: string;
                  ANames: TStringList): Boolean;
var
  NewLines, Changed, Declared: TStringList;
  HeadCnt, OldEnd, NewEnd, Delta, Idx, PropIdx, NameIdx: Integer;
  Rec: TCodeRec;
  NewLine, Word: string;
  LineNo: Integer;

  // Имена слева от ':' в строке-объявлении - в Declared
  procedure AddDeclared(const ALine: string);
  var
    Code: string;
    CommaPos, ColonPos: Integer;
  begin
    Code := ALine;
    CommaPos := Pos('//', Code);
    if CommaPos > 0 then
      Code := Copy(Code, 1, CommaPos - 1);
    ColonPos := Pos(':', Code);
    if ColonPos <= 0 then
      Exit;
    Code := Copy(Code, 1, ColonPos - 1);
    repeat
      CommaPos := Pos(',', Code);
      if CommaPos > 0 then
      begin
        Declared.Add(Trim(Copy(Code, 1, CommaPos - 1)));
        Delete(Code, 1, CommaPos);
      end
      else
        Declared.Add(Trim(Code));
    until CommaPos <= 0;
  end;

  // Слово AWord (без учёта регистра) стоит в строке отдельным словом
  function HasWord(const ALine, AWord: string): Boolean;
  var
    UpLine, UpWord: string;
    FoundPos, AfterPos: Integer;
  begin
    Result := False;
    UpLine := UpperCase(ALine);
    UpWord := UpperCase(AWord);
    FoundPos := Pos(UpWord, UpLine);
    while FoundPos > 0 do
    begin
      AfterPos := FoundPos + Length(UpWord);
      if ((FoundPos = 1) or
          not (UpLine[FoundPos - 1] in ['A'..'Z', '0'..'9', '_'])) and
         ((AfterPos > Length(UpLine)) or
          not (UpLine[AfterPos] in ['A'..'Z', '0'..'9', '_'])) then
      begin
        Result := True;
        Exit;
      end;
      UpLine[FoundPos] := '#';
      FoundPos := Pos(UpWord, UpLine);
    end;
  end;

begin
  Result := False;
  if (CbrKey = '') or (CbrLines = nil) or (CbrRecs = nil) or
     (CbrNames = nil) or (AClassFull <> CbrClassFull) then
    Exit;
  NewLines := TStringList.Create;
  Changed := TStringList.Create;
  Declared := TStringList.Create;
  try
    NewLines.Text := AText;
    if not CodeDiffPlain(CbrLines, NewLines, HeadCnt, OldEnd, NewEnd) then
      Exit;
    for Idx := HeadCnt to OldEnd - 1 do
      AddDeclared(CbrLines[Idx]);
    for Idx := HeadCnt to NewEnd - 1 do
      AddDeclared(NewLines[Idx]);
    Declared.CaseSensitive := False;

    // Имена .dfm, которые появились или пропали
    Changed.CaseSensitive := False;
    for NameIdx := 0 to ANames.Count - 1 do
      if CbrNames.IndexOf(ANames[NameIdx]) < 0 then
        Changed.Add(ANames[NameIdx]);
    for NameIdx := 0 to CbrNames.Count - 1 do
      if ANames.IndexOf(CbrNames[NameIdx]) < 0 then
        Changed.Add(CbrNames[NameIdx]);

    Delta := NewEnd - OldEnd;
    // Сначала только проверка: кэш меняется, лишь когда годится весь
    for Idx := 0 to CbrRecs.Count - 1 do
    begin
      Rec := TCodeRec(CbrRecs[Idx]);
      if Declared.IndexOf(Rec.LHS) >= 0 then
        Exit;
      LineNo := Rec.Line;
      if not CodeShiftLine(LineNo, HeadCnt, OldEnd, Delta) then
        Exit;
      if Rec.ParLine >= 0 then
      begin
        LineNo := Rec.ParLine;
        if not CodeShiftLine(LineNo, HeadCnt, OldEnd, Delta) then
          Exit;
      end;
      if Rec.Tpl <> nil then
      begin
        for PropIdx := 0 to Rec.Tpl.PropN.Count - 1 do
        begin
          LineNo := Integer(Rec.Tpl.PropN.Objects[PropIdx]);
          if (LineNo >= 0) and
             not CodeShiftLine(LineNo, HeadCnt, OldEnd, Delta) then
            Exit;
        end;
        for PropIdx := 0 to Rec.Tpl.EvN.Count - 1 do
        begin
          LineNo := Integer(Rec.Tpl.EvN.Objects[PropIdx]);
          if (LineNo >= 0) and
             not CodeShiftLine(LineNo, HeadCnt, OldEnd, Delta) then
            Exit;
        end;
      end;
      if Changed.Count > 0 then
      begin
        NewLine := CbrLines[Rec.Line];
        for NameIdx := 0 to Changed.Count - 1 do
        begin
          Word := Changed[NameIdx];
          if HasWord(NewLine, Word) then
            Exit;
        end;
      end;
    end;

    // Годится - сдвиг номеров строк
    if Delta <> 0 then
      for Idx := 0 to CbrRecs.Count - 1 do
      begin
        Rec := TCodeRec(CbrRecs[Idx]);
        CodeShiftLine(Rec.Line, HeadCnt, OldEnd, Delta);
        if Rec.ParLine >= 0 then
          CodeShiftLine(Rec.ParLine, HeadCnt, OldEnd, Delta);
        // Конец описания - строка перед границей (а граница - не
        // объявление, она ниже правки) или последняя строка модуля
        if Rec.EndLine + 1 >= OldEnd then
          Inc(Rec.EndLine, Delta);
        if Rec.Tpl <> nil then
        begin
          for PropIdx := 0 to Rec.Tpl.PropN.Count - 1 do
          begin
            LineNo := Integer(Rec.Tpl.PropN.Objects[PropIdx]);
            if LineNo >= 0 then
            begin
              CodeShiftLine(LineNo, HeadCnt, OldEnd, Delta);
              Rec.Tpl.PropN.Objects[PropIdx] := TObject(LineNo);
            end;
          end;
          for PropIdx := 0 to Rec.Tpl.EvN.Count - 1 do
          begin
            LineNo := Integer(Rec.Tpl.EvN.Objects[PropIdx]);
            if LineNo >= 0 then
            begin
              CodeShiftLine(LineNo, HeadCnt, OldEnd, Delta);
              Rec.Tpl.EvN.Objects[PropIdx] := TObject(LineNo);
            end;
          end;
        end;
      end;
    CbrLines.Free;
    CbrLines := NewLines;
    NewLines := nil;
    CbrNames.Assign(ANames);
    CbrKey := AKey;
    Result := True;
  finally
    Declared.Free;
    Changed.Free;
    NewLines.Free;
  end;
end;

// AFormClass - класс формы: по нему в модуле ищутся её поля. AFull - полное
// дерево (вкладка Code): и окна-диалоги, и локальные переменные без родителя.
function BuildCodeRuntime(ADfmRoot: TDfmNode; const AText, AFormClass: string;
                          AFull: Boolean; ANodes: TList): TDfmNode;
var
  Lines, Fields, Index: TStringList;
  Recs: TList;
  Facts: TList;          // функции-помощники модуля (TFactoryRec)
  FCap, FPar: string;
  CtorArgs: TStringList; // аргументы конструктора - поиск родителя
  CVar, CPar, CCap: string;
  Bound: array of Boolean;
  I, J, K, P, Q: Integer;
  T, U, Cls, Lhs, PName, V: string;
  R, R2, C: TCodeRec;
  Root, Target, Grp, N, D, LinkTo: TDfmNode;
  Key, Names: string;

  function IsIdentChar(C: Char): Boolean;
  begin
    Result := C in ['a'..'z', 'A'..'Z', '0'..'9', '_'];
  end;

  // Значение справа от := до ';' или комментария, кавычки учитываются
  function ValueAfterAssign(const ALine: string): string;
  var
    S: string;
    M: Integer;
    InQ: Boolean;
  begin
    Result := '';
    M := Pos(':=', ALine);
    if M <= 0 then
      Exit;
    S := Trim(Copy(ALine, M + 2, MaxInt));
    InQ := False;
    for M := 1 to Length(S) do
    begin
      if S[M] = '''' then
        InQ := not InQ
      else if not InQ and ((S[M] = ';') or
              ((S[M] = '/') and (M < Length(S)) and (S[M + 1] = '/'))) then
      begin
        Result := Trim(Copy(S, 1, M - 1));
        Exit;
      end;
    end;
    Result := S;
  end;

  // "  X := TКласс.Create(" -> класс и переменная. Комментарий в конце
  // строки не читается.
  function ParseCreate(const ALine: string; var AClass, ALhs: string): Boolean;
  var
    S, SU: string;
    M, C: Integer;
  begin
    Result := False;
    S := Trim(ALine);
    if Copy(S, 1, 2) = '//' then
      Exit;
    S := CodeNoComment(S);
    SU := UpperCase(S);
    C := CodeCreatePos(SU);
    if C <= 0 then
      Exit;
    M := C - 1;
    while (M >= 1) and IsIdentChar(S[M]) do
      Dec(M);
    AClass := Copy(S, M + 1, C - 1 - M);
    ALhs := '';
    Q := Pos(':=', S);
    if (Q > 0) and (Q < M + 1) then
      ALhs := Trim(Copy(S, 1, Q - 1));
    if CompareText(Copy(ALhs, 1, 5), 'Self.') = 0 then
      ALhs := Copy(ALhs, 6, MaxInt);
    Result := (AClass <> '') and (UpCase(AClass[1]) = 'T');
  end;

  // Поля класса формы: строки "Имя1, Имя2: TТип;" между "TForm1 = class"
  // и его end
  procedure CollectFields;
  var
    M, C: Integer;
    S, SU, Names, One: string;
    Inside: Boolean;
  begin
    Inside := False;
    for M := 0 to Lines.Count - 1 do
    begin
      S := Trim(Lines[M]);
      SU := UpperCase(S);
      if not Inside then
      begin
        if Pos(UpperCase(AFormClass) + ' = CLASS', SU) = 1 then
          Inside := True;
        Continue;
      end;
      if SU = 'END;' then
        Break;
      if (S = '') or (Copy(S, 1, 2) = '//') or (S[1] = '{') then
        Continue;
      if (Pos('PROCEDURE ', SU) = 1) or (Pos('FUNCTION ', SU) = 1) or
         (Pos('PROPERTY ', SU) = 1) or (Pos('CONSTRUCTOR ', SU) = 1) or
         (Pos('DESTRUCTOR ', SU) = 1) then
        Continue;
      C := Pos(':', S);
      if C <= 0 then
        Continue;
      Names := Copy(S, 1, C - 1);
      while Names <> '' do
      begin
        C := Pos(',', Names);
        if C > 0 then
        begin
          One := Trim(Copy(Names, 1, C - 1));
          Names := Copy(Names, C + 1, MaxInt);
        end
        else
        begin
          One := Trim(Names);
          Names := '';
        end;
        if One <> '' then
          Fields.Add(One);
      end;
    end;
  end;

  // Ближайшее создание переменной AName выше строки ABefore; нет выше -
  // любое. nil - такой переменной в разборе нет. AAll - и те, что в дерево
  // не попали: по ним узнаётся содержимое временных окон.
  function RecOf(const AName: string; ABefore: Integer;
                 AAll: Boolean = False): TCodeRec;
  var
    M: Integer;
    X: TCodeRec;
  begin
    Result := nil;
    for M := 0 to Recs.Count - 1 do
    begin
      X := TCodeRec(Recs[M]);
      if ((X.Node = nil) and not AAll) or (CompareText(X.LHS, AName) <> 0) then
        Continue;
      if X.Line < ABefore then
        Result := X
      else if Result = nil then
      begin
        Result := X;
        Break;
      end;
    end;
  end;

  function NewNode(const AName, AClass: string): TDfmNode;
  begin
    Result := TDfmNode.Create;
    Result.Name := AName;
    Result.ClassNm := AClass;
    Result.Line := -1;
    ANodes.Add(Result);
  end;

begin
  Result := nil;
  Root := TDfmNode(ADfmRoot);
  if (Root = nil) or (AText = '') then
    Exit;

  Index := TStringList.Create;
  Recs := nil;
  Fields := nil;
  Facts := nil;
  CtorArgs := nil;
  try
    // Имена из .dfm - по ним узнаются родители из дизайнера
    Index.Sorted := True;
    Index.CaseSensitive := False;
    Index.Duplicates := dupIgnore;
    for I := 0 to ANodes.Count - 1 do
      if TDfmNode(ANodes[I]).Name <> '' then
        Index.AddObject(TDfmNode(ANodes[I]).Name, ANodes[I]);

    // Тот же текст модуля, класс, AFull и имена .dfm - создания и их свойства
    // из прошлого вызова (форму разбирают заново из-за снимка или правки
    // значений в .dfm)
    Names := Index.Text;
    Key := IntToHex(Crc32Of(AText), 8) + ':' + IntToStr(Length(AText)) +
           '|' + AFormClass + '|' + IntToStr(Ord(AFull)) + '|' +
           IntToHex(Crc32Of(Names), 8);
    if (Key = CbrKey) or
       CbrRemap(AText, Key, AFormClass + '|' + IntToStr(Ord(AFull)), Index) then
      Lines := CbrLines
    else
    begin
      CbrFree;
      Lines := TStringList.Create;
      CbrLines := Lines;
      CbrRecs := TList.Create;
      Recs := CbrRecs;          // сбор - прямо в кэш
      Fields := TStringList.Create;
      CtorArgs := TStringList.Create;
      Lines.Text := AText;
      Fields.Sorted := True;
      Fields.CaseSensitive := False;
      Fields.Duplicates := dupIgnore;
      CollectFields;

      // Границы процедур: заголовок реализации стоит с первой колонки,
      // вложенные процедуры - с отступом и границей не считаются
      SetLength(Bound, Lines.Count);
      for I := 0 to Lines.Count - 1 do
      begin
        U := UpperCase(Lines[I]);
        Bound[I] := (Pos('PROCEDURE ', U) = 1) or (Pos('FUNCTION ', U) = 1) or
                    (Pos('CONSTRUCTOR ', U) = 1) or (Pos('DESTRUCTOR ', U) = 1) or
                    (Pos('INITIALIZATION', U) = 1) or (Pos('END.', U) = 1);
      end;

      // --- создания; и через помощники модуля (X := MakeView(Sheet))
      Facts := TList.Create;
      CodeCollectFactories(Lines, Facts);
      for I := 0 to Lines.Count - 1 do
      begin
        FCap := '';
        FPar := '';
        if CodeFactoryCall(Lines, I, Facts, Lhs, Cls, FPar, FCap) then
          // создание через помощник - родитель и подпись из аргументов
        else if not ParseCreate(Lines[I], Cls, Lhs) or
                CodeInCreatorBody(Facts, I, Lhs) then
          // не создание, или создание в теле создателя - его компоненты
          // даёт вызов (MakeCmpButton(btnViewUnit, ...)), а не эта строка
          Continue;
        if (Lhs = '') or (CompareText(Lhs, 'Result') = 0) or
           (Pos('.', Lhs) > 0) or (Pos('[', Lhs) > 0) then
          Continue;

        R := TCodeRec.Create;
        R.LHS := Lhs;
        R.Cls := Cls;
        R.Line := I;
        R.ParLine := -1;
        if FPar <> '' then
        begin
          R.Par := FPar;
          R.ParLine := I;
        end;
        R.Cap := FCap;
        Recs.Add(R);

        // Описание - до конца процедуры или до нового создания этой же
        // переменной (локальную переиспользуют)
        R.EndLine := Lines.Count - 1;
        for J := I + 1 to Lines.Count - 1 do
        begin
          if Bound[J] then
          begin
            R.EndLine := J - 1;
            Break;
          end;
          if ParseCreate(Lines[J], V, U) and (CompareText(U, Lhs) = 0) then
          begin
            R.EndLine := J - 1;
            Break;
          end;
        end;
      end;

      // --- свойства, события и родитель каждого создания
      for K := 0 to Recs.Count - 1 do
      begin
        R := TCodeRec(Recs[K]);
        N := nil;

        for J := R.Line + 1 to R.EndLine do
        begin
          T := Trim(Lines[J]);
          if (T = '') or (Copy(T, 1, 2) = '//') then
            Continue;
          U := AnsiUpperCase(T);

          // Настройщик: SetupSwatch(pnlGutterBG, ...) даёт родителя
          if (R.Par = '') and
             CodeConfCall(Lines, J, Facts, CVar, CPar, CCap) and
             (CompareText(CVar, R.LHS) = 0) then
          begin
            R.Par := CPar;
            R.ParLine := J;
            Continue;
          end;

          // Пункт меню: Y.Add(X) или Y.Items.Add(X)
          P := Pos('.ADD(' + AnsiUpperCase(R.LHS) + ')', U);
          if P > 0 then
          begin
            V := Trim(Copy(T, 1, P - 1));
            if CompareText(Copy(V, Length(V) - 5, 6), '.Items') = 0 then
              V := Copy(V, 1, Length(V) - 6);
            R.Par := V;
            R.ParLine := J;
            Continue;
          end;

          if Pos(AnsiUpperCase(R.LHS) + '.', U) <> 1 then
            Continue;
          Q := Pos(':=', T);
          if Q <= 0 then
            Continue;
          PName := Trim(Copy(T, Length(R.LHS) + 2, Q - Length(R.LHS) - 2));
          if (PName = '') or (Pos('(', PName) > 0) then
            Continue;
          V := ValueAfterAssign(T);

          if (CompareText(PName, 'Parent') = 0) or
             (CompareText(PName, 'PageControl') = 0) then
          begin
            R.Par := V;
            R.ParLine := J;
          end;

          if N = nil then
            N := TDfmNode.Create; // временный сборщик, узел - ниже
          if (Copy(PName, 1, 2) = 'On') and (V <> '') and IsIdentChar(V[1]) then
          begin
            N.EvN.AddObject(PName, TObject(J));
            N.EvV.Add(V);
          end
          else
          begin
            N.PropN.AddObject(PName, TObject(J));
            N.PropV.Add(V);
            N.PropRaw.AddObject(V, TObject(1));
          end;
        end;

        // Родителя нет ни в .Parent, ни в .Add - его могли передать
        // конструктору: TDsgPalette.CreatePalette(Self, pnlPaletteIn, ...).
        // Берётся первый аргумент, который - известный компонент (из .dfm
        // или созданный в коде); Self, nil и прочее - не родитель.
        if R.Par = '' then
        begin
          T := Lines[R.Line];
          P := CodeCreatePos(UpperCase(T));
          if P > 0 then
          begin
            T := Copy(T, P + 1, MaxInt);
            P := Pos('(', T);
            Q := LastDelimiter(')', T);
            if (P > 0) and (Q > P) then
            begin
              CtorArgs.Clear;
              CodeSplitArgs(Copy(T, P + 1, Q - P - 1), CtorArgs);
              for J := 0 to CtorArgs.Count - 1 do
              begin
                V := Trim(CtorArgs[J]);
                if not IsValidIdent(V) or (CompareText(V, 'Self') = 0) or
                   (CompareText(V, 'nil') = 0) or
                   (CompareText(V, 'Application') = 0) or
                   (CompareText(V, 'Owner') = 0) or
                   (CompareText(V, 'AOwner') = 0) then
                  Continue;
                if (Index.IndexOf(V) >= 0) or
                   ((RecOf(V, R.Line, True) <> nil) and
                    (RecOf(V, R.Line, True) <> R)) then
                begin
                  R.Par := V;
                  R.ParLine := R.Line;
                  Break;
                end;
              end;
            end;
          end;
        end;

        // Подпись из аргумента помощника - как свойство со строкой вызова
        if (R.Cap <> '') and (R.Cap[1] in ['''', '#']) then
        begin
          if N = nil then
            N := TDfmNode.Create;
          N.PropN.AddObject('Caption', TObject(R.Line));
          N.PropV.Add(R.Cap);
          N.PropRaw.AddObject(R.Cap, TObject(1));
        end;

        // В дерево - поля формы и то, у чего есть родитель. Для полного
        // дерева вкладки Code - всё: и окна-диалоги (Dlg := TForm.Create)
        if (Fields.IndexOf(R.LHS) < 0) and (R.Par = '') and not AFull then
        begin
          N.Free;
          Continue;
        end;

        // В дерево пойдёт: свойства - в шаблон записи кэша, узел из него
        // делается ниже, при каждом вызове свой
        R.InTree := True;
        if N = nil then
          N := TDfmNode.Create;
        R.Tpl := N;
      end;

      // Сбор дошёл до конца - годится и для следующих вызовов
      CbrKey := Key;
      CbrClassFull := AFormClass + '|' + IntToStr(Ord(AFull));
      CbrNames := TStringList.Create;
      CbrNames.Sorted := True;
      CbrNames.CaseSensitive := False;
      CbrNames.Duplicates := dupIgnore;
      CbrNames.Assign(Index);
    end;

    // --- узлы этого вызова: копии записей кэша (раскладка их меняет) и
    // узлы по шаблонам
    Recs := TList.Create;
    for K := 0 to CbrRecs.Count - 1 do
    begin
      C := TCodeRec(CbrRecs[K]);
      R := TCodeRec.Create;
      R.LHS := C.LHS;
      R.Cls := C.Cls;
      R.Par := C.Par;
      R.Cap := C.Cap;
      R.Line := C.Line;
      R.ParLine := C.ParLine;
      R.EndLine := C.EndLine;
      if C.InTree then
      begin
        R.Node := NewNode('', R.Cls);
        R.Node.VarName := R.LHS;
        R.Node.CreateLine := R.Line;
        R.Node.IsRuntime := True;
        R.Node.FromCode := True;
        R.Node.PropN.Assign(C.Tpl.PropN);
        R.Node.PropV.Assign(C.Tpl.PropV);
        R.Node.PropRaw.Assign(C.Tpl.PropRaw);
        R.Node.EvN.Assign(C.Tpl.EvN);
        R.Node.EvV.Assign(C.Tpl.EvV);
      end;
      Recs.Add(R);
    end;

    // Границы процедур нужны и раскладке (родитель через переменную); при
    // сборе из кэша их ещё нет
    if Length(Bound) <> Lines.Count then
    begin
      SetLength(Bound, Lines.Count);
      for I := 0 to Lines.Count - 1 do
      begin
        U := UpperCase(Lines[I]);
        Bound[I] := (Pos('PROCEDURE ', U) = 1) or (Pos('FUNCTION ', U) = 1) or
                    (Pos('CONSTRUCTOR ', U) = 1) or (Pos('DESTRUCTOR ', U) = 1) or
                    (Pos('INITIALIZATION', U) = 1) or (Pos('END.', U) = 1);
      end;
    end;

    // --- раскладка по родителям, в порядке текста
    Grp := nil;
    for K := 0 to Recs.Count - 1 do
    begin
      R := TCodeRec(Recs[K]);
      if R.Node = nil then
        Continue;

      // Родитель - параметр процедуры (lstCompTypes.Parent := ATab в
      // BuildCompilersTab(ATab)) - подставляем аргумент из её вызова.
      // Если параметру выше в той же процедуре присвоен новый объект
      // (AForm := TForm.Create(Self) в MakeListWindow(var AForm: TForm)),
      // родитель - этот объект, подстановка не нужна.
      if R.Par <> '' then
      begin
        if R.ParLine >= 0 then
          P := R.ParLine
        else
          P := R.Line;
        R2 := RecOf(R.Par, P, True);
        if (R2 = nil) or (R2 = R) or (R2.Line >= P) or (R2.EndLine < P) then
          R.Par := CodeResolveParamPar(Lines, R.Line, R.Par);
      end;

      Target := nil;
      if (R.Par = '') or (CompareText(R.Par, 'Self') = 0) or
         (CompareText(R.Par, Root.Name) = 0) then
        Target := Root
      else
      begin
        J := Index.IndexOf(R.Par);
        if J >= 0 then
          Target := TDfmNode(Index.Objects[J])
        else
        begin
          if R.ParLine >= 0 then
            R2 := RecOf(R.Par, R.ParLine, True)
          else
            R2 := RecOf(R.Par, R.Line, True);
          if (R2 <> nil) and (R2 <> R) then
          begin
            // Родитель - временное окно или то, что в нём лежит: и этот
            // компонент к форме не относится
            if (R2.Node = nil) or R2.Dropped then
            begin
              R.Dropped := True;
              Continue;
            end;
            Target := R2.Node;
          end;
        end;
      end;

      // Родитель - переменная, которой выше в той же процедуре присвоен
      // готовый компонент: Sheet := FObjPagesSheet1; ... MakeView(Sheet)
      // (так пишет перенос в .dfm). Родитель - этот компонент.
      if (Target = nil) and (R.Par <> '') then
      begin
        if R.ParLine >= 0 then
          P := R.ParLine
        else
          P := R.Line;
        for J := P - 1 downto 0 do
        begin
          if Bound[J] then
            Break;
          T := Trim(CodeNoComment(Lines[J]));
          Q := Pos(':=', T);
          if (Q = 0) or (CompareText(Trim(Copy(T, 1, Q - 1)), R.Par) <> 0) then
            Continue;
          V := ValueAfterAssign(T);
          if IsValidIdent(V) then
          begin
            Q := Index.IndexOf(V);
            if Q >= 0 then
              Target := TDfmNode(Index.Objects[Q]);
          end;
          Break;   // ближайшее присваивание решает
        end;
      end;

      if Target = nil then
      begin
        // Родитель в переменной, которую разбор не знает (AParent и т.п.)
        if Grp = nil then
        begin
          Grp := NewNode('', '(родитель не определён)');
          Result := Grp;
        end;
        Target := Grp;
      end;

      R.Node.Parent := Target;
      Target.Children.Add(R.Node);
    end;

    // --- компоненты из .dfm, перенесённые кодом в созданную панель:
    // D.Parent := X. Внутри X - ссылка, свойства у D на своём месте.
    // X может лежать и в .dfm (панель, которую раньше создавал код,
    // перенесли в .dfm): ссылка нужна и тогда, если X - не тот, в чьём
    // блоке D лежит в .dfm. По ссылке конструктор переставляет D туда же,
    // куда его ставит код.
    for I := 0 to Lines.Count - 1 do
    begin
      T := Trim(Lines[I]);
      if (T = '') or (Copy(T, 1, 2) = '//') then
        Continue;
      P := Pos('.', T);
      Q := Pos(':=', T);
      if (P <= 1) or (Q <= P) then
        Continue;
      if CompareText(Trim(Copy(T, P + 1, Q - P - 1)), 'Parent') <> 0 then
        Continue;
      J := Index.IndexOf(Copy(T, 1, P - 1));
      if J < 0 then
        Continue;
      D := TDfmNode(Index.Objects[J]);
      R2 := RecOf(ValueAfterAssign(T), I);
      if (R2 <> nil) and (R2.Node <> nil) then
        LinkTo := R2.Node
      else
      begin
        K := Index.IndexOf(ValueAfterAssign(T));
        if K < 0 then
          Continue;
        LinkTo := TDfmNode(Index.Objects[K]);
        if (LinkTo = D) or (LinkTo = D.Parent) then
          Continue;
      end;
      N := NewNode(D.Name, D.ClassNm);
      N.IsLink := True;
      N.Parent := LinkTo;
      LinkTo.Children.Add(N);
    end;
  finally
    // Recs - копии этого вызова; записи кэша (CbrRecs) и Lines живут дальше.
    // Сбор оборвался - Recs и есть кэш, он без ключа: освободит CbrFree.
    if (Recs <> nil) and (Recs <> CbrRecs) then
    begin
      for I := 0 to Recs.Count - 1 do
        TCodeRec(Recs[I]).Free;
      Recs.Free;
    end;
    FreeFactories(Facts);
    CtorArgs.Free;
    Index.Free;
    Fields.Free;
  end;
end;

// Снимок поверх разбора кода: у узла из кода и узла из снимка одна строка
// создания - это один компонент. Узел кода получает живые значения
// (совпавшие по имени свойства - заменяются, остальные добавляются без
// строки в коде), а дети снимка, которых код не нашёл, переезжают к нему.
// Остальное из снимка остаётся как было - то, чего разбор не раскрыл.
//
// Место в дереве - по снимку. Вложенность снимка - это Parent объектов в
// работающей программе (FormSnapshot обходит Controls[]), а родитель из
// разбора текста - лишь вывод из .Parent :=, аргументов и помощников. Узел
// кода уходит с места, которое ему дал разбор (в том числе из «родитель не
// определён»), и встаёт на место узла снимка. Разбор родителя по тексту
// остаётся для случая, когда снимка нет.
//
// Перенос не делается, если родитель из снимка по тексту лежит внутри
// самого узла кода - вышел бы цикл, - и если узел кода уже поставлен по
// другому объекту снимка с той же строкой создания (создание в цикле или
// в помощнике): тогда как раньше - узел снимка вливается в него.
procedure DedupeSnapNodes(ANode: TDfmNode; AByLine: TStringList;
                          ANodes: TList);
var
  Placed: TList; // узлы кода, уже поставленные по снимку
  // Строки создания, которые сопоставлены сразу нескольким узлам снимка:
  // создание в цикле (пункты меню New по списку). Такие узлы снимка
  // остаются каждый сам по себе - с переменной и строкой создания, - а
  // узел кода, один на всех, из дерева уходит.
  Multi: TStringList;

  // AWhat - сам ARoot или лежит в его поддереве
  function Inside(AWhat, ARoot: TDfmNode; ADepth: Integer): Boolean;
  var
    J: Integer;
  begin
    Result := AWhat = ARoot;
    if Result or (ADepth > 64) then
      Exit;
    for J := 0 to ARoot.Children.Count - 1 do
      if Inside(AWhat, TDfmNode(ARoot.Children[J]), ADepth + 1) then
      begin
        Result := True;
        Exit;
      end;
  end;

  // Узел - прочь из списка детей, где бы он ни стоял
  procedure Detach(AWhat: TDfmNode);
  var
    J: Integer;
  begin
    for J := 0 to ANodes.Count - 1 do
      TDfmNode(ANodes[J]).Children.Remove(AWhat);
  end;

  procedure Walk(N: TDfmNode);
  var
    C, T: TDfmNode;
    I, K, M: Integer;
    Found, Move: Boolean;
  begin
    // Перенос узла кода мог укоротить и этот список - индекс проверяется
    for I := N.Children.Count - 1 downto 0 do
      if I < N.Children.Count then
        Walk(TDfmNode(N.Children[I]));

    for I := N.Children.Count - 1 downto 0 do
    begin
      if I >= N.Children.Count then
        Continue; // список укоротился переносом узла кода
      C := TDfmNode(N.Children[I]);
      if not C.IsSnap or (C.CreateLine < 0) then
        Continue;
      if Multi.IndexOf(IntToStr(C.CreateLine)) >= 0 then
        Continue;
      K := AByLine.IndexOf(IntToStr(C.CreateLine));
      if K < 0 then
        Continue;
      T := TDfmNode(AByLine.Objects[K]);
      if T = C then
        Continue;

      for M := 0 to C.PropN.Count - 1 do
      begin
        // Свойство может присваиваться в коде несколько раз
        // (chkList.Left := 240; ... chkList.Left := chkList.Left + D) - живое
        // значение получают все такие строки. И не только показ (PropV), но
        // и текст значения (PropRaw): по нему конструктор ставит компонент,
        // и выражение из кода там дало бы Left = 0.
        Found := False;
        for K := 0 to T.PropN.Count - 1 do
          if CompareText(T.PropN[K], C.PropN[M]) = 0 then
          begin
            T.PropV[K] := C.PropV[M];
            // Текст значения - как записан в снимке (строки в апострофах),
            // а не показ: показ расшифрован, и конструктор его не разберёт
            if (K < T.PropRaw.Count) and (M < C.PropRaw.Count) then
              T.PropRaw[K] := C.PropRaw[M];
            Found := True;
          end;
        if not Found then
        begin
          T.PropN.AddObject(C.PropN[M], TObject(-1));
          T.PropV.Add(C.PropV[M]);
          if M < C.PropRaw.Count then
            T.PropRaw.AddObject(C.PropRaw[M], TObject(1))
          else
            T.PropRaw.AddObject(C.PropV[M], TObject(1));
        end;
      end;
      T.IsLive := True;

      Move := (Placed.IndexOf(T) < 0) and not Inside(N, T, 0);
      if Move then
        // С прежнего места - до переноса детей: узел кода мог уже лежать
        // внутри узла снимка (его туда поставил перенос уровнем ниже)
        Detach(T)
      else if Inside(T, C, 0) then
        // Узел кода остаётся внутри узла снимка: влить в него детей узла
        // снимка - получить цикл. Узел снимка остаётся как есть.
        Continue;

      for M := 0 to C.Children.Count - 1 do
      begin
        TDfmNode(C.Children[M]).Parent := T;
        T.Children.Add(C.Children[M]);
      end;
      C.Children.Clear;

      K := N.Children.IndexOf(C);
      if Move then
      begin
        // Узел кода - на место узла снимка, под настоящего родителя
        if K >= 0 then
          N.Children[K] := T
        else
          N.Children.Add(T);
        T.Parent := N;
        Placed.Add(T);
      end
      else if K >= 0 then
        // Как раньше: узел кода остаётся где был, узел снимка уходит
        N.Children.Delete(K);
    end;
  end;

var
  I, K: Integer;
  S: TStringList;
  T: TDfmNode;
begin
  Placed := TList.Create;
  Multi := TStringList.Create;
  S := TStringList.Create;
  try
    // Сколько узлов снимка на каждой строке создания
    S.Sorted := True;
    Multi.Sorted := True;
    Multi.Duplicates := dupIgnore;
    for I := 0 to ANodes.Count - 1 do
    begin
      T := TDfmNode(ANodes[I]);
      if not T.IsSnap or (T.CreateLine < 0) then
        Continue;
      if S.Find(IntToStr(T.CreateLine), K) then
        Multi.Add(IntToStr(T.CreateLine))
      else
        S.Add(IntToStr(T.CreateLine));
    end;

    Walk(TDfmNode(ANode));

    // Узел кода с такой строкой - один на весь цикл; его компоненты уже
    // стоят в дереве узлами снимка. Детей из кода у него нет - убираем.
    for I := 0 to Multi.Count - 1 do
    begin
      K := AByLine.IndexOf(Multi[I]);
      if K < 0 then
        Continue;
      T := TDfmNode(AByLine.Objects[K]);
      if (T <> nil) and not T.IsSnap and (T.Children.Count = 0) then
        Detach(T);
    end;
  finally
    S.Free;
    Multi.Free;
    Placed.Free;
  end;
end;

initialization

finalization
  RrnFree;
  CbrFree;

end.
