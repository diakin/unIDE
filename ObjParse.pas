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
    // Объект RapidQ/FreeBASIC, объявленный "DIM Имя AS Qкласс", а не блоком
    // CREATE: свойства в коде - "Имя.Свойство = значение", CreateLine -
    // строка DIM, EndLine - последняя строка его свойств
    IsDim: Boolean;
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
function DecodeDfmString(const Str: string): string;
function EncodeDfmString(const Str: string): string;
function ParseDfmNodes(const AText: string; ASnap: Boolean;
                       ANodes: TList): TDfmNode;

// --- код модуля
function CodeCreatePos(const SU: string): Integer;
procedure CodeSplitArgs(const Str: string; AList: TStrings);
procedure CodeParamNames(const AHdr: string; AList: TStrings);
function CodeIdentAfterAssign(const Str: string): string;
procedure CodeCollectFactories(ALines: TStrings; AFacts: TList);
function CodeInCreatorBody(AFacts: TList; ALine: Integer;
                           const ALhs: string): Boolean;
function CodeFactoryCall(ALines: TStrings; Idx: Integer; AFacts: TList;
                         var ALhs, AClass, APar, ACap: string): Boolean;
function CodeConfCall(ALines: TStrings; Idx2: Integer; AFacts: TList;
                      var AVar, APar, ACap: string): Boolean;
function CodeResolveParamPar(ALines: TStrings; ALine: Integer;
                             const APar: string): string;
function CodeLineInLoop(ALines: TStrings; ALine: Integer): Boolean;
// Список помощников (TFactoryRec) - освободить вместе с записями
procedure FreeFactories(AFacts: TList);

// --- кэш разбора
function Crc32Of(const Str: string): Cardinal;
function CacheEsc(const Str: string): string;
function CacheUnesc(const Str: string): string;
procedure SplitTabs(const Str: string; AList: TStrings);
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

{$IFDEF FPC}{$IFDEF MSWINDOWS}
uses
  Windows;
{$ENDIF}{$ENDIF}

// Символ Юникода (#1053 в .dfm) - в кодировке редактора (CP_ACP). В Delphi 7
// это делает string(WideString); в Lazarus string(WideString) дал бы UTF-8
function WideCharToEditor(ACode: Integer): string;
var
  WordStr: WideString;
  {$IFDEF FPC}{$IFDEF MSWINDOWS}
  Buf: array[0..7] of AnsiChar;
  Len: Integer;
  {$ENDIF}{$ENDIF}
begin
  WordStr := WideChar(ACode);
  {$IFDEF FPC}
  {$IFDEF MSWINDOWS}
  Len := WideCharToMultiByte(CP_ACP, 0, PWideChar(WordStr), 1, @Buf[0],
    SizeOf(Buf), nil, nil);
  SetString(Result, PAnsiChar(@Buf[0]), Len);
  {$ELSE}
  Result := UTF8Encode(WordStr);
  {$ENDIF}
  {$ELSE}
  Result := string(WordStr);
  {$ENDIF}
end;

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
function Crc32Of(const Str: string): Cardinal;
var
  I, K: Integer;
  CrcVal: Cardinal;
begin
  if not Crc32Ready then
  begin
    for I := 0 to 255 do
    begin
      CrcVal := Cardinal(I);
      for K := 1 to 8 do
        if (CrcVal and 1) <> 0 then
          CrcVal := (CrcVal shr 1) xor $EDB88320
        else
          CrcVal := CrcVal shr 1;
      Crc32Table[I] := CrcVal;
    end;
    Crc32Ready := True;
  end;
  CrcVal := $FFFFFFFF;
  for I := 1 to Length(Str) do
    CrcVal := Crc32Table[Byte(CrcVal xor Cardinal(Ord(Str[I])))] xor (CrcVal shr 8);
  Result := not CrcVal;
end;

// Поле записи кэша: табуляция и переводы строки внутри - \t, \r, \n,
// остальные управляющие - \xHH. Прежде всего #0: он бывает в значениях
// (PasswordChar = #0 из снимка), а TStringList.LoadFromFile на нём
// обрывает текст - файл кэша читался бы обрезанным и не годился.
function CacheEsc(const Str: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Str) do
    case Str[I] of
      '\': Result := Result + '\\';
      #9:  Result := Result + '\t';
      #10: Result := Result + '\n';
      #13: Result := Result + '\r';
      #0..#8, #11, #12, #14..#31:
        Result := Result + '\x' + IntToHex(Ord(Str[I]), 2);
    else
      Result := Result + Str[I];
    end;
end;

function CacheUnesc(const Str: string): string;
var
  Idx: Integer;
begin
  Result := '';
  Idx := 1;
  while Idx <= Length(Str) do
  begin
    if (Str[Idx] = '\') and (Idx < Length(Str)) then
    begin
      Inc(Idx);
      case Str[Idx] of
        't': Result := Result + #9;
        'n': Result := Result + #10;
        'r': Result := Result + #13;
        'x':
          begin
            Result := Result + Chr(StrToIntDef('$' + Copy(Str, Idx + 1, 2), 63));
            Inc(Idx, 2);
          end;
      else
        Result := Result + Str[Idx];
      end;
    end
    else
      Result := Result + Str[Idx];
    Inc(Idx);
  end;
end;

// Строка записи - поля через табуляцию
procedure SplitTabs(const Str: string; AList: TStrings);
var
  CharPos, TabPos: Integer;
begin
  AList.Clear;
  CharPos := 1;
  repeat
    TabPos := PosEx(#9, Str, CharPos);
    if TabPos = 0 then
    begin
      AList.Add(Copy(Str, CharPos, MaxInt));
      Break;
    end;
    AList.Add(Copy(Str, CharPos, TabPos - CharPos));
    CharPos := TabPos + 1;
  until False;
end;

// Строковое значение .dfm в читаемом виде: 'abc' + 'def'#13#10'x'.
// Апострофы внутри удвоены, символы вне кавычек записаны как #код.
// Значение не строковое (число, идентификатор, набор) - возвращается как есть.
function DecodeDfmString(const Str: string): string;
var
  Idx, Num, Code: Integer;
begin
  Result := '';
  if (Str = '') or not (Str[1] in ['''', '#']) then
  begin
    Result := Str;
    Exit;
  end;

  Idx := 1;
  Num := Length(Str);
  while Idx <= Num do
  begin
    if Str[Idx] = '''' then
    begin
      Inc(Idx);
      while Idx <= Num do
      begin
        if Str[Idx] = '''' then
        begin
          if (Idx < Num) and (Str[Idx + 1] = '''') then
          begin
            Result := Result + '''';
            Inc(Idx, 2);
            Continue;
          end;
          Inc(Idx);
          Break;
        end;
        Result := Result + Str[Idx];
        Inc(Idx);
      end;
    end
    else if Str[Idx] = '#' then
    begin
      Inc(Idx);
      Code := 0;
      while (Idx <= Num) and (Str[Idx] in ['0'..'9']) do
      begin
        Code := Code * 10 + Ord(Str[Idx]) - Ord('0');
        Inc(Idx);
      end;
      // Выше 255 - символ Юникода: переводим в текущую кодовую страницу
      if Code < 256 then
        Result := Result + Chr(Code)
      else
        Result := Result + WideCharToEditor(Code);
    end
    else if Str[Idx] in [' ', '+'] then
      Inc(Idx)
    else
    begin
      // Посреди строки - не строковое выражение; показываем как было
      Result := Str;
      Exit;
    end;
  end;
end;

// Строка в записи .dfm: апострофы удваиваются, управляющие символы - #код
function EncodeDfmString(const Str: string): string;
var
  I: Integer;
  InQ: Boolean;
begin
  Result := '';
  InQ := False;
  for I := 1 to Length(Str) do
    if Str[I] < ' ' then
    begin
      if InQ then
      begin
        Result := Result + '''';
        InQ := False;
      end;
      Result := Result + '#' + IntToStr(Ord(Str[I]));
    end
    else
    begin
      if not InQ then
      begin
        Result := Result + '''';
        InQ := True;
      end;
      if Str[I] = '''' then
        Result := Result + ''''''
      else
        Result := Result + Str[I];
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
  Idx, CharPos, Delta, Items, PropLine: Integer;
  Line, Up, Head, Nm, Cls, PName, PVal, Rest, Acc, L2, Raw0, RawAcc: string;
  Stack: array of TDfmNode;
  Top: Integer;
  Obj, Cur, Root: TDfmNode;
  Closed: Boolean;

  function IsIdent(const Str: string): Boolean;
  var
    J: Integer;
  begin
    Result := Str <> '';
    for J := 1 to Length(Str) do
      if not (Str[J] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) then
      begin
        Result := False;
        Exit;
      end;
  end;

  function Shorten(const Str: string): string;
  begin
    Result := Str;
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

    Idx := 0;
    while Idx < SL.Count do
    begin
      Line := Trim(SL[Idx]);
      Up := UpperCase(Line);

      // --- начало объекта
      if (Copy(Up, 1, 7) = 'OBJECT ') or (Copy(Up, 1, 10) = 'INHERITED ') or
         (Copy(Up, 1, 7) = 'INLINE ') then
      begin
        Head := Trim(Copy(Line, Pos(' ', Line) + 1, MaxInt));
        CharPos := Pos('[', Head);          // [0] - индекс у наследованных
        if CharPos > 0 then
          Head := Trim(Copy(Head, 1, CharPos - 1));
        CharPos := Pos(':', Head);
        if CharPos > 0 then
        begin
          Nm := Trim(Copy(Head, 1, CharPos - 1));
          Cls := Trim(Copy(Head, CharPos + 1, MaxInt));
        end
        else
        begin
          Nm := '';
          Cls := Head;
        end;

        Obj := TDfmNode.Create;
        Obj.Name := Nm;
        Obj.ClassNm := Cls;
        Obj.Line := Idx;
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
        Inc(Idx);
        Continue;
      end;

      // --- конец объекта
      if Up = 'END' then
      begin
        if Top >= 0 then
        begin
          Stack[Top].EndLine := Idx;
          Dec(Top);
        end;
        if Top >= 0 then
          Cur := Stack[Top]
        else
          Cur := nil;
        Inc(Idx);
        Continue;
      end;

      // --- свойство
      CharPos := Pos(' = ', Line);
      if CharPos > 0 then
      begin
        PName := Copy(Line, 1, CharPos - 1);
        PVal := Copy(Line, CharPos + 3, MaxInt);
      end
      else if (Length(Line) > 2) and (Copy(Line, Length(Line) - 1, 2) = ' =') then
      begin
        // Длинная строка: значение начинается со следующей строки
        PName := Copy(Line, 1, Length(Line) - 2);
        PVal := '';
      end
      else
      begin
        Inc(Idx);
        Continue;
      end;

      PropLine := Idx;
      Raw0 := PVal;   // как записано в строке - для правки
      if (PVal = '') and (Idx + 1 < SL.Count) then
      begin
        Inc(Idx);
        PVal := Trim(SL[Idx]);
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
                Inc(Idx);
                if Idx >= SL.Count then
                  Break;
                Rest := Trim(SL[Idx]);
              until False;
              PVal := Shorten('(' + Acc + ')');
              Raw0 := '(' + Trim(RawAcc) + ')';
            end;

          '{':
            begin
              // Двоичные данные - картинки, иконки: показывать нечего
              while ((PVal = '') or (PVal[Length(PVal)] <> '}')) and
                    (Idx + 1 < SL.Count) do
              begin
                Inc(Idx);
                PVal := Trim(SL[Idx]);
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
                Delta := 1;
                Items := 0;
                while (Delta > 0) and (Idx + 1 < SL.Count) do
                begin
                  Inc(Idx);
                  L2 := Trim(SL[Idx]);
                  if (Delta = 1) and SameText(L2, 'item') then
                    Inc(Items);
                  // Пустая вложенная коллекция (Columns = <>) глубину
                  // не меняет
                  if Copy(L2, Length(L2) - 1, 2) = '<>' then
                  else if (L2 <> '') and (L2[Length(L2)] = '>') then
                    Dec(Delta)
                  else if (L2 <> '') and (L2[Length(L2)] = '<') then
                    Inc(Delta);
                end;
                PVal := Format('(коллекция, элементов: %d)', [Items]);
              end;
            end;
        else
          // Строка, склеенная из частей через +
          while (Length(PVal) > 1) and (PVal[Length(PVal)] = '+') and
                (Idx + 1 < SL.Count) do
          begin
            Inc(Idx);
            PVal := PVal + ' ' + Trim(SL[Idx]);
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
          Cur.PropRaw.AddObject(Raw0, TObject(Ord(Idx <> PropLine)));
        end;
      end;

      Inc(Idx);
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
  CharPos, Idx3: Integer;
begin
  Result := 0;
  CharPos := Pos('.CREATE', SU);
  while CharPos > 0 do
  begin
    Idx3 := CharPos + 7;
    while (Idx3 <= Length(SU)) and (SU[Idx3] in ['A'..'Z', '0'..'9', '_']) do
      Inc(Idx3);
    if (Idx3 <= Length(SU)) and (SU[Idx3] = '(') then
    begin
      Result := CharPos;
      Exit;
    end;
    CharPos := PosEx('.CREATE', SU, CharPos + 1);
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
procedure CodeSplitArgs(const Str: string; AList: TStrings);
var
  P, Delta: Integer;
  InQuote: Boolean;
  Cur: string;
begin
  AList.Clear;
  Delta := 0;
  InQuote := False;
  Cur := '';
  for P := 1 to Length(Str) do
  begin
    if Str[P] = '''' then
      InQuote := not InQuote;
    if not InQuote then
    begin
      if Str[P] = '(' then
        Inc(Delta)
      else if Str[P] = ')' then
        Dec(Delta)
      else if (Str[P] = ',') and (Delta = 0) then
      begin
        AList.Add(Trim(Cur));
        Cur := '';
        Continue;
      end;
    end;
    Cur := Cur + Str[P];
  end;
  if Trim(Cur) <> '' then
    AList.Add(Trim(Cur));
end;

// Имена параметров из заголовка функции по порядку
procedure CodeParamNames(const AHdr: string; AList: TStrings);
var
  P1, P2, CharPos, C: Integer;
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
      CharPos := Pos(';', Body);
      Grp := Trim(Copy(Body, 1, CharPos - 1));
      Delete(Body, 1, CharPos);
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
function CodeIdentAfterAssign(const Str: string): string;
var
  CharPos, QuotePos: Integer;
begin
  Result := '';
  CharPos := Pos(':=', Str);
  if CharPos = 0 then
    Exit;
  Result := Trim(Copy(Str, CharPos + 2, MaxInt));
  QuotePos := 1;
  while (QuotePos <= Length(Result)) and
        (Result[QuotePos] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) do
    Inc(QuotePos);
  Result := Copy(Result, 1, QuotePos - 1);
end;

// Все помощники модуля - в AFacts (TFactoryRec)
procedure CodeCollectFactories(ALines: TStrings; AFacts: TList);
var
  Idx, EndPos: Integer;

  // Отступ строки - число пробелов и табуляций в начале
  function IndentOf(const Str: string): Integer;
  begin
    Result := 0;
    while (Result < Length(Str)) and (Str[Result + 1] in [' ', #9]) do
      Inc(Result);
  end;

  function IsHeader(const Str: string): Boolean;
  var
    Txt: string;
  begin
    Txt := Trim(Str);
    Result := (CompareText(Copy(Txt, 1, 9), 'function ') = 0) or
              (CompareText(Copy(Txt, 1, 10), 'procedure ') = 0);
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
    Idx2, Idx3, CharPos, P2, Ind, Dummy: Integer;
    Txt, TU, Hdr, ValStr, LineStr: string;
    FactoryRec: TFactoryRec;
    Prms: TStringList;
    IsProc, Nested: Boolean;
  begin
    Txt := Trim(ALines[AHdr]);
    IsProc := CompareText(Copy(Txt, 1, 10), 'procedure ') = 0;
    Ind := IndentOf(ALines[AHdr]);
    Nested := Ind > 0;

    Hdr := Txt;
    Idx2 := AHdr;
    while (Pos(')', Hdr) = 0) and
          not ((Pos('(', Hdr) = 0) and (Pos(';', Hdr) > 0)) and
          (Idx2 + 1 < ALines.Count) and (Idx2 < AHdr + 6) do
    begin
      Inc(Idx2);
      Hdr := Hdr + ' ' + Trim(ALines[Idx2]);
    end;

    Prms := TStringList.Create;
    FactoryRec := TFactoryRec.Create;
    try
      FactoryRec.ParIdx := -1;
      FactoryRec.CapIdx := -1;
      FactoryRec.CompIdx := -1;
      FactoryRec.OutIdx := -1;
      FactoryRec.HintIdx := -1;
      FactoryRec.HdrLine := AHdr;
      if IsProc then
        ValStr := Trim(Copy(Hdr, 11, MaxInt))
      else
        ValStr := Trim(Copy(Hdr, 10, MaxInt));
      CharPos := Pos('(', ValStr);
      if CharPos > 0 then
        ValStr := Copy(ValStr, 1, CharPos - 1);
      CharPos := Pos(':', ValStr);
      if CharPos > 0 then
        ValStr := Copy(ValStr, 1, CharPos - 1);
      CharPos := Pos(';', ValStr);
      if CharPos > 0 then
        ValStr := Copy(ValStr, 1, CharPos - 1);
      CharPos := LastDelimiter('.', ValStr);
      if CharPos > 0 then
        Delete(ValStr, 1, CharPos);
      FactoryRec.Name := Trim(ValStr);
      CodeParamNames(Hdr, Prms);

      Idx3 := Idx2 + 1;
      while Idx3 < ALines.Count do
      begin
        LineStr := ALines[Idx3];
        if Nested then
        begin
          if (Trim(LineStr) = 'end;') and (IndentOf(LineStr) = Ind) then
            Break;
          // Строка с первой колонки - вложенная кончилась раньше, чем
          // нашёлся её end (разбор чужого форматирования): не уходить
          if (LineStr <> '') and not (LineStr[1] in [' ', #9]) then
            Break;
        end
        else
        begin
          if CompareText(TrimRight(LineStr), 'end;') = 0 then
            Break;
          // Заголовок без тела (объявление в interface, forward): до его
          // end; дело не дойдёт - следующая подпрограмма или граница
          // раздела с первой колонки. Иначе разбор проглотил бы её целиком.
          if (LineStr <> '') and not (LineStr[1] in [' ', #9]) and
             (IsHeader(LineStr) or
              (CompareText(Copy(Trim(LineStr), 1, 14), 'implementation') = 0)) then
          begin
            Dec(Idx3);
            Break;
          end;
        end;

        // Вложенный заголовок - свой помощник. Тело внешней при этом
        // читается дальше как было: его строки ей не мешают.
        if not Nested and (IndentOf(LineStr) > 0) and IsHeader(LineStr) then
          ParseRoutine(Idx3, Dummy);

        Txt := Trim(LineStr);
        TU := UpperCase(Txt);
        // Создатель: var-параметр := TКласс.Create(...)
        CharPos := Pos(':=', Txt);
        P2 := Pos('.CREATE', TU);
        if IsProc and (CharPos > 1) and (P2 > CharPos) and
           (Prms.IndexOf(Trim(Copy(Txt, 1, CharPos - 1))) >= 0) then
        begin
          ValStr := Trim(Copy(Txt, CharPos + 2, P2 - CharPos - 2));
          if IsValidIdent(ValStr) then
          begin
            FactoryRec.OutIdx := Prms.IndexOf(Trim(Copy(Txt, 1, CharPos - 1)));
            FactoryRec.OutName := Trim(Copy(Txt, 1, CharPos - 1));
            FactoryRec.Cls := ValStr;
          end;
        end;
        // Настройщик: Параметр.Parent := ... / Параметр.Caption := ...
        CharPos := Pos('.', Txt);
        if IsProc and (CharPos > 1) and (Pos(':=', Txt) > CharPos) and
           (Prms.IndexOf(Copy(Txt, 1, CharPos - 1)) >= 0) then
        begin
          ValStr := UpperCase(Trim(Copy(Txt, CharPos + 1, Pos(':=', Txt) - CharPos - 1)));
          if ValStr = 'PARENT' then
          begin
            FactoryRec.CompIdx := Prms.IndexOf(Copy(Txt, 1, CharPos - 1));
            FactoryRec.ParIdx := Prms.IndexOf(CodeIdentAfterAssign(Txt));
            if FactoryRec.ParIdx < 0 then
              FactoryRec.FixedPar := CodeIdentAfterAssign(Txt);
          end
          else if (ValStr = 'CAPTION') or (ValStr = 'TEXT') then
            FactoryRec.CapIdx := Prms.IndexOf(CodeIdentAfterAssign(Txt))
          else if ValStr = 'HINT' then
            FactoryRec.HintIdx := Prms.IndexOf(CodeIdentAfterAssign(Txt));
        end;
        CharPos := Pos('.CREATE(', TU);
        if (Copy(TU, 1, 6) = 'RESULT') and (CharPos > 0) and (Pos(':=', Txt) > 0) then
          FactoryRec.Cls := Trim(Copy(Txt, Pos(':=', Txt) + 2, CharPos - Pos(':=', Txt) - 2));
        if Copy(TU, 1, 15) = 'RESULT.CAPTION ' then
          FactoryRec.CapIdx := Prms.IndexOf(CodeIdentAfterAssign(Txt))
        else if Copy(TU, 1, 12) = 'RESULT.TEXT ' then
          FactoryRec.CapIdx := Prms.IndexOf(CodeIdentAfterAssign(Txt))
        else if Copy(TU, 1, 12) = 'RESULT.HINT ' then
          FactoryRec.HintIdx := Prms.IndexOf(CodeIdentAfterAssign(Txt))
        else if Copy(TU, 1, 14) = 'RESULT.PARENT ' then
        begin
          FactoryRec.ParIdx := Prms.IndexOf(CodeIdentAfterAssign(Txt));
          if FactoryRec.ParIdx < 0 then
            FactoryRec.FixedPar := CodeIdentAfterAssign(Txt);
        end
        else if (Pos('.ADD(RESULT)', TU) > 0) or
                ((Pos('.INSERT(', TU) > 0) and (Pos('RESULT)', TU) > 0)) then
          FactoryRec.ParIdx := Prms.IndexOf(Trim(Copy(Txt, 1, Pos('.', Txt) - 1)));
        Inc(Idx3);
      end;
      AEnd := Idx3;
      FactoryRec.EndLine := Idx3;

      if (FactoryRec.Name <> '') and
         ((not IsProc and (FactoryRec.Cls <> '') and IsValidIdent(FactoryRec.Cls)) or
          (IsProc and ((FactoryRec.CompIdx >= 0) or (FactoryRec.OutIdx >= 0)))) then
      begin
        if IsProc and (FactoryRec.OutIdx < 0) then
          FactoryRec.Cls := '';        // настройщик ничего не создаёт
        AFacts.Add(FactoryRec);
        FactoryRec := nil;
      end;
    finally
      FactoryRec.Free;
      Prms.Free;
    end;
  end;

begin
  Idx := 0;
  while Idx < ALines.Count do
  begin
    if not IsHeader(ALines[Idx]) then
    begin
      Inc(Idx);
      Continue;
    end;
    ParseRoutine(Idx, EndPos);
    Idx := EndPos + 1;
  end;
end;

// Строка ALine - создание внутри тела процедуры-создателя, в её
// var-параметр (ABtn := TSpeedButton.Create(Self) в MakeCmpButton)? Такая
// строка - не отдельный компонент: компоненты - это вызовы создателя.
function CodeInCreatorBody(AFacts: TList; ALine: Integer;
                           const ALhs: string): Boolean;
var
  M: Integer;
  FactoryRec: TFactoryRec;
begin
  Result := False;
  if (AFacts = nil) or (ALhs = '') then
    Exit;
  for M := 0 to AFacts.Count - 1 do
  begin
    FactoryRec := TFactoryRec(AFacts[M]);
    if (FactoryRec.OutIdx >= 0) and (ALine > FactoryRec.HdrLine) and (ALine <= FactoryRec.EndLine) and
       (CompareText(FactoryRec.OutName, ALhs) = 0) then
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
function CodeFactoryCall(ALines: TStrings; Idx: Integer; AFacts: TList;
                         var ALhs, AClass, APar, ACap: string): Boolean;
var
  Txt, ValStr, Call: string;
  AssignPos, ParenPos, Idx2, K, Depth, M: Integer;
  InQ: Boolean;
  FactoryRec: TFactoryRec;
  Args: TStringList;
begin
  Result := False;
  Txt := Trim(CodeNoComment(ALines[Idx]));
  if (Copy(Txt, 1, 2) = '//') or (AFacts.Count = 0) then
    Exit;
  AssignPos := Pos(':=', Txt);
  if AssignPos > 0 then
  begin
    ALhs := Trim(Copy(Txt, 1, AssignPos - 1));
    if not IsValidIdent(ALhs) then
      Exit;
    ValStr := Trim(Copy(Txt, AssignPos + 2, MaxInt));
  end
  else
  begin
    ALhs := '';   // только создатель: имя - из его var-параметра
    ValStr := Txt;
  end;
  ParenPos := Pos('(', ValStr);
  if ParenPos = 0 then
    Exit;
  FactoryRec := nil;
  for M := 0 to AFacts.Count - 1 do
    if (TFactoryRec(AFacts[M]).Cls <> '') and
       (CompareText(TFactoryRec(AFacts[M]).Name, Trim(Copy(ValStr, 1, ParenPos - 1))) = 0) then
    begin
      FactoryRec := TFactoryRec(AFacts[M]);
      Break;
    end;
  if FactoryRec = nil then
    Exit;
  // Функция - только с присваиванием, создатель - только без него
  if (AssignPos > 0) <> (FactoryRec.OutIdx < 0) then
    Exit;

  Call := Copy(ValStr, ParenPos + 1, MaxInt);
  Idx2 := Idx;
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
    if (Depth = 0) or (Idx2 + 1 >= ALines.Count) or (Idx2 > Idx + 6) then
      Break;
    Inc(Idx2);
    Call := Call + ' ' + Trim(ALines[Idx2]);
  until False;

  Args := TStringList.Create;
  try
    CodeSplitArgs(Call, Args);
    AClass := FactoryRec.Cls;
    APar := FactoryRec.FixedPar;
    ACap := '';
    if (FactoryRec.ParIdx >= 0) and (FactoryRec.ParIdx < Args.Count) then
    begin
      ValStr := Args[FactoryRec.ParIdx];
      if CompareText(Copy(ValStr, Length(ValStr) - 5, 6), '.Items') = 0 then
        Delete(ValStr, Length(ValStr) - 5, 6);
      if IsValidIdent(ValStr) then
        APar := ValStr;
    end;
    if (FactoryRec.CapIdx >= 0) and (FactoryRec.CapIdx < Args.Count) then
      ACap := Args[FactoryRec.CapIdx];
    if FactoryRec.OutIdx >= 0 then
      if FactoryRec.OutIdx < Args.Count then
        ALhs := Trim(Args[FactoryRec.OutIdx])
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
function CodeConfCall(ALines: TStrings; Idx2: Integer; AFacts: TList;
                      var AVar, APar, ACap: string): Boolean;
var
  Txt, Call, ValStr: string;
  ParenPos, K, M, Depth, Len: Integer;
  InQ: Boolean;
  FactoryRec: TFactoryRec;
  Args: TStringList;
begin
  Result := False;
  Txt := Trim(CodeNoComment(ALines[Idx2]));
  if (Copy(Txt, 1, 2) = '//') or (AFacts.Count = 0) then
    Exit;
  ParenPos := Pos('(', Txt);
  if (ParenPos = 0) or ((Pos(':=', Txt) > 0) and (Pos(':=', Txt) < ParenPos)) then
    Exit;
  ValStr := Trim(Copy(Txt, 1, ParenPos - 1));
  if not IsValidIdent(ValStr) then
    Exit;
  FactoryRec := nil;
  for M := 0 to AFacts.Count - 1 do
    if (TFactoryRec(AFacts[M]).CompIdx >= 0) and
       (CompareText(TFactoryRec(AFacts[M]).Name, ValStr) = 0) then
    begin
      FactoryRec := TFactoryRec(AFacts[M]);
      Break;
    end;
  if FactoryRec = nil then
    Exit;

  Call := Copy(Txt, ParenPos + 1, MaxInt);
  Len := Idx2;
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
    if (Depth = 0) or (Len + 1 >= ALines.Count) or (Len > Idx2 + 6) then
      Break;
    Inc(Len);
    Call := Call + ' ' + Trim(ALines[Len]);
  until False;

  Args := TStringList.Create;
  try
    CodeSplitArgs(Call, Args);
    if FactoryRec.CompIdx >= Args.Count then
      Exit;
    AVar := Trim(Args[FactoryRec.CompIdx]);
    if not IsValidIdent(AVar) then
      Exit;
    APar := FactoryRec.FixedPar;
    if (FactoryRec.ParIdx >= 0) and (FactoryRec.ParIdx < Args.Count) and
       IsValidIdent(Trim(Args[FactoryRec.ParIdx])) then
      APar := Trim(Args[FactoryRec.ParIdx]);
    ACap := '';
    if (FactoryRec.CapIdx >= 0) and (FactoryRec.CapIdx < Args.Count) then
      ACap := Trim(Args[FactoryRec.CapIdx]);
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
  Idx2, Idx3, K, CharPos, Q, Idx, Depth: Integer;
  Txt, UpStr, Hdr, Name, Call: string;
  Prms, Args: TStringList;
  InQ: Boolean;
begin
  Result := APar;
  if (APar = '') or (ALine < 0) or (ALine >= ALines.Count) then
    Exit;

  // Заголовок своей процедуры - вверх до строки с первой колонки
  Idx2 := ALine;
  while Idx2 >= 0 do
  begin
    UpStr := UpperCase(ALines[Idx2]);
    if (Copy(UpStr, 1, 10) = 'PROCEDURE ') or (Copy(UpStr, 1, 9) = 'FUNCTION ') then
      Break;
    Dec(Idx2);
  end;
  if Idx2 < 0 then
    Exit;
  Hdr := Trim(ALines[Idx2]);
  Idx3 := Idx2;
  while (Pos(')', Hdr) = 0) and
        not ((Pos('(', Hdr) = 0) and (Pos(';', Hdr) > 0)) and
        (Idx3 + 1 < ALines.Count) and (Idx3 < Idx2 + 6) do
  begin
    Inc(Idx3);
    Hdr := Hdr + ' ' + Trim(ALines[Idx3]);
  end;

  // Имя процедуры без класса: TForm2.BuildCompilersTab -> BuildCompilersTab
  if UpperCase(Copy(Hdr, 1, 10)) = 'PROCEDURE ' then
    Name := Trim(Copy(Hdr, 11, MaxInt))
  else
    Name := Trim(Copy(Hdr, 10, MaxInt));
  CharPos := Pos('(', Name);
  if CharPos > 0 then
    Name := Copy(Name, 1, CharPos - 1);
  CharPos := LastDelimiter('.', Name);
  if CharPos > 0 then
    Delete(Name, 1, CharPos);
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
      Txt := Trim(ALines[K]);
      UpStr := UpperCase(Txt);
      if (Copy(Txt, 1, 2) = '//') or (Copy(UpStr, 1, 10) = 'PROCEDURE ') or
         (Copy(UpStr, 1, 9) = 'FUNCTION ') then
        Continue;
      CharPos := Pos(UpperCase(Name) + '(', UpStr);
      if CharPos = 0 then
        Continue;
      if (CharPos > 1) and (UpStr[CharPos - 1] in ['A'..'Z', '0'..'9', '_']) then
        Continue;
      Call := Copy(Txt, CharPos + Length(Name) + 1, MaxInt);
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
  Txt, UpStr: string;

  function IndentOf(const Str: string): Integer;
  begin
    Result := 0;
    while (Result < Length(Str)) and (Str[Result + 1] in [' ', #9]) do
      Inc(Result);
  end;

begin
  Result := False;
  if (ALine < 0) or (ALine >= ALines.Count) then
    Exit;
  Ind := IndentOf(ALines[ALine]);
  for I := ALine - 1 downto 0 do
  begin
    Txt := ALines[I];
    UpStr := UpperCase(Trim(Txt));
    if (UpStr = '') or (Copy(UpStr, 1, 2) = '//') then
      Continue;
    Cur := IndentOf(Txt);
    if (Cur = 0) and ((Copy(UpStr, 1, 10) = 'PROCEDURE ') or
                      (Copy(UpStr, 1, 9) = 'FUNCTION ') or
                      (Copy(UpStr, 1, 12) = 'CONSTRUCTOR ') or
                      (Copy(UpStr, 1, 11) = 'DESTRUCTOR ')) then
      Exit;
    if Cur >= Ind then
      Continue;
    if (Copy(UpStr, 1, 4) = 'FOR ') or (Copy(UpStr, 1, 6) = 'WHILE ') or
       (UpStr = 'REPEAT') or (Copy(UpStr, 1, 7) = 'REPEAT ') then
    begin
      Result := True;
      Exit;
    end;
    if UpStr = 'BEGIN' then
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
  I, CharPos: Integer;

  function Flags(DfmNode: TDfmNode): string;
  begin
    Result := '';
    if DfmNode.IsSnap then
      Result := Result + 'S';
    if DfmNode.IsRuntime then
      Result := Result + 'R';
    if DfmNode.IsLink then
      Result := Result + 'K';
    if DfmNode.SnapRoot then
      Result := Result + 'T';
    if DfmNode.FromCode then
      Result := Result + 'C';
    if DfmNode.IsLive then
      Result := Result + 'V';
  end;

  procedure WriteNode(DfmNode: TDfmNode);
  var
    K: Integer;
    Raw, RawFlag, ValStr: string;
  begin
    K := Ids.IndexOf(DfmNode);
    if K >= 0 then
    begin
      SL.Add('R'#9 + IntToStr(K)); // узел уже записан - ссылка на него
      Exit;
    end;
    Ids.Add(DfmNode);
    SL.Add('O'#9 + CacheEsc(DfmNode.Name) + #9 + CacheEsc(DfmNode.ClassNm) + #9 +
           CacheEsc(DfmNode.VarName) + #9 + IntToStr(DfmNode.Line) + #9 +
           IntToStr(DfmNode.EndLine) + #9 + IntToStr(DfmNode.CreateLine) + #9 + Flags(DfmNode));
    for K := 0 to DfmNode.PropN.Count - 1 do
    begin
      // Текста значения может не быть - тогда флаг -1
      if K < DfmNode.PropRaw.Count then
      begin
        Raw := DfmNode.PropRaw[K];
        RawFlag := IntToStr(Integer(DfmNode.PropRaw.Objects[K]));
      end
      else
      begin
        Raw := '';
        RawFlag := '-1';
      end;
      if K < DfmNode.PropV.Count then
        ValStr := DfmNode.PropV[K]
      else
        ValStr := '';
      SL.Add('P'#9 + IntToStr(Integer(DfmNode.PropN.Objects[K])) + #9 + RawFlag +
             #9 + CacheEsc(DfmNode.PropN[K]) + #9 + CacheEsc(Raw) + #9 +
             CacheEsc(ValStr));
    end;
    for K := 0 to DfmNode.EvN.Count - 1 do
    begin
      if K < DfmNode.EvV.Count then
        ValStr := DfmNode.EvV[K]
      else
        ValStr := '';
      SL.Add('E'#9 + IntToStr(Integer(DfmNode.EvN.Objects[K])) + #9 +
             CacheEsc(DfmNode.EvN[K]) + #9 + CacheEsc(ValStr));
    end;
    for K := 0 to DfmNode.Children.Count - 1 do
      WriteNode(TDfmNode(DfmNode.Children[K]));
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
        CharPos := Ids.IndexOf(TDfmNode(Ids[I]).Parent);
        if CharPos >= 0 then
          SL.Add('A'#9 + IntToStr(I) + #9 + IntToStr(CharPos));
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
  SL, StrList: TStringList;
  Nodes, Stack: TList;
  I, Start: Integer;
  Txt: string;
  DfmNode: TDfmNode;

  function Top: TDfmNode;
  begin
    if Stack.Count = 0 then
      raise Exception.Create('cache: нет объекта');
    Result := TDfmNode(Stack[Stack.Count - 1]);
  end;

  procedure Need(ACount: Integer);
  begin
    if StrList.Count < ACount then
      raise Exception.Create('cache: мало полей');
  end;

begin
  Result := False;
  if (AFile = '') or not FileExists(AFile) or (ANodes = nil) then
    Exit;
  SL := TStringList.Create;
  StrList := TStringList.Create;
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
        Txt := SL[I];
        if Txt = '' then
          Continue;
        SplitTabs(Txt, StrList);
        case Txt[1] of
          'O':
            begin
              Need(8);
              DfmNode := TDfmNode.Create;
              ANodes.Add(DfmNode);
              Nodes.Add(DfmNode);
              DfmNode.Name := CacheUnesc(StrList[1]);
              DfmNode.ClassNm := CacheUnesc(StrList[2]);
              DfmNode.VarName := CacheUnesc(StrList[3]);
              DfmNode.Line := StrToInt(StrList[4]);
              DfmNode.EndLine := StrToInt(StrList[5]);
              DfmNode.CreateLine := StrToInt(StrList[6]);
              DfmNode.IsSnap := Pos('S', StrList[7]) > 0;
              DfmNode.IsRuntime := Pos('R', StrList[7]) > 0;
              DfmNode.IsLink := Pos('K', StrList[7]) > 0;
              DfmNode.SnapRoot := Pos('T', StrList[7]) > 0;
              DfmNode.FromCode := Pos('C', StrList[7]) > 0;
              DfmNode.IsLive := Pos('V', StrList[7]) > 0;
              if Stack.Count > 0 then
                Top.Children.Add(DfmNode)
              else
                ARoots.Add(DfmNode);
              Stack.Add(DfmNode);
            end;
          'P':
            begin
              Need(6);
              DfmNode := Top;
              DfmNode.PropN.AddObject(CacheUnesc(StrList[3]), TObject(StrToInt(StrList[1])));
              if StrToInt(StrList[2]) >= 0 then
                DfmNode.PropRaw.AddObject(CacheUnesc(StrList[4]), TObject(StrToInt(StrList[2])));
              DfmNode.PropV.Add(CacheUnesc(StrList[5]));
            end;
          'E':
            begin
              Need(4);
              DfmNode := Top;
              DfmNode.EvN.AddObject(CacheUnesc(StrList[2]), TObject(StrToInt(StrList[1])));
              DfmNode.EvV.Add(CacheUnesc(StrList[3]));
            end;
          'R':
            begin
              Need(2);
              DfmNode := TDfmNode(Nodes[StrToInt(StrList[1])]);
              if Stack.Count > 0 then
                Top.Children.Add(DfmNode)
              else
                ARoots.Add(DfmNode);
            end;
          'X':
            begin
              Top;
              Stack.Delete(Stack.Count - 1);
            end;
          'A':
            begin
              Need(3);
              TDfmNode(Nodes[StrToInt(StrList[1])]).Parent :=
                TDfmNode(Nodes[StrToInt(StrList[2])]);
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
    StrList.Free;
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
  I, Idx3: Integer;
  Tgt, Snp, DfmNode, DfmNode2: TDfmNode;
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
      DfmNode := TDfmNode(Old[I]);
      DfmNode2 := nil;
      if DfmNode.Name <> '' then
      begin
        Idx3 := AIndex.IndexOf(DfmNode.Name);
        if Idx3 >= 0 then
          DfmNode2 := TDfmNode(AIndex.Objects[Idx3]);
      end;

      if DfmNode2 <> nil then
      begin
        if Tgt.IsRuntime then
        begin
          DfmNode.IsLink := True;
          Tgt.Children.Add(DfmNode);
        end;
        MergeSnapNode(DfmNode2, DfmNode, AIndex, AGone);
      end
      else if (AGone <> nil) and (DfmNode.Name <> '') and
              (AGone.IndexOf(DfmNode.Name) >= 0) then
        // Был в .dfm при сборке exe, из .dfm вкладки убран: это не
        // созданное в коде, а прежний вид формы. Вместе со всем, что в нём
        // лежит, - в дерево не идёт (узел остаётся в общем списке узлов и
        // освобождается с ним).
        Continue
      else
      begin
        DfmNode.IsRuntime := True;
        Tgt.Children.Add(DfmNode);
        MergeSnapNode(DfmNode, DfmNode, AIndex, AGone);
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
  Idx: Integer;
begin
  Result := Text;
  Idx := 1;
  while Idx <= Length(Result) do
  begin
    if Result[Idx] = '&' then
      Delete(Result, Idx, 1);
    Inc(Idx);
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
    procedure AddCap(const Str: string);
    destructor Destroy; override;
  end;

procedure TCreateRec.AddCap(const Str: string);
begin
  if Str = '' then
    Exit;
  if Caps = nil then
    Caps := TStringList.Create;
  if Caps.IndexOf(Str) < 0 then
    Caps.Add(Str);
  if Cap = '' then
    Cap := Str;
end;

destructor TCreateRec.Destroy;
begin
  Caps.Free;
  inherited;
end;

// Подписи совпадают без учёта знака ускорителя: VCL сам вставляет '&' в
// пункты меню (AutoHotkeys), и в снимке 'Projects' оказывается '&Projects'
function CapSame(const ArgStr, BufStr: string): Boolean;
begin
  Result := CapStripHotkey(Trim(ArgStr)) = CapStripHotkey(Trim(BufStr));
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
  RestStr, Str: string;
begin
  Result := False;
  if ARec.Caps = nil then
    Exit;
  RestStr := CapStripHotkey(Trim(ACap));
  for I := 0 to ARec.Caps.Count - 1 do
  begin
    Str := CapStripHotkey(Trim(ARec.Caps[I]));
    if (Str <> '') and (Length(RestStr) > Length(Str)) and
       (Copy(RestStr, 1, Length(Str)) = Str) then
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
  FactoryRec: TFactoryRec;
  K, Depth: Integer;
  Call: string;
  InQuote: Boolean;
  I, J, QuotePos, ByteVal, EndPos: Integer; // E - и во вложенной ParseCreate
  Txt, TU, Cls, Lhs, ValStr: string;
  CreateRec: TCreateRec;

  // Правая часть присваивания: идентификатор (Self, FToolbar, alTop)
  function IdentAfterAssign(const ALine: string): string;
  var
    Str: string;
    K: Integer;
  begin
    Result := '';
    K := Pos(':=', ALine);
    if K <= 0 then
      Exit;
    Str := Trim(Copy(ALine, K + 2, MaxInt));
    K := 1;
    while (K <= Length(Str)) and
          (Str[K] in ['a'..'z', 'A'..'Z', '0'..'9', '_', '.']) do
      Inc(K);
    Result := Copy(Str, 1, K - 1);
  end;

  // Строковый литерал справа от := : 'текст' и #коды до ';' или комментария
  function LiteralAfterAssign(const ALine: string): string;
  var
    Str: string;
    K: Integer;
    InQ: Boolean;
  begin
    Result := '';
    K := Pos(':=', ALine);
    if K <= 0 then
      Exit;
    Str := Trim(Copy(ALine, K + 2, MaxInt));
    if (Str = '') or not (Str[1] in ['''', '#']) then
      Exit;
    K := 1;
    InQ := False;
    while K <= Length(Str) do
    begin
      if Str[K] = '''' then
        InQ := not InQ
      else if not InQ and not (Str[K] in ['#', '0'..'9', '+', ' ']) then
        Break;
      Inc(K);
    end;
    Result := DecodeDfmString(Trim(Copy(Str, 1, K - 1)));
  end;

  // "  X := TКласс.Create(" -> класс и переменная. Комментарий в конце
  // строки не читается.
  function ParseCreate(const ALine: string; var AClass, ALhs: string): Boolean;
  var
    Str, SU: string;
    K, P: Integer;
  begin
    Result := False;
    Str := Trim(ALine);
    if Copy(Str, 1, 2) = '//' then
      Exit;
    Str := CodeNoComment(Str);
    SU := UpperCase(Str);
    P := CodeCreatePos(SU);
    if P <= 0 then
      Exit;
    K := P - 1;
    while (K >= 1) and (Str[K] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) do
      Dec(K);
    AClass := Copy(Str, K + 1, P - 1 - K);
    ALhs := '';
    EndPos := Pos(':=', Str);
    if (EndPos > 0) and (EndPos < K + 1) then
      ALhs := Trim(Copy(Str, 1, EndPos - 1));
    Result := AClass <> '';
  end;

  // Аргументы вызова верхнего уровня: "Self, mEdit, 'a, b', F(1, 2)" ->
  // четыре строки. Запятые в строках и во вложенных скобках не делят.
  procedure SplitArgs(const Str: string; AList: TStrings);
  var
    P, Delta: Integer;
    QuotePos: Boolean;
    Cur: string;
  begin
    AList.Clear;
    Delta := 0;
    QuotePos := False;
    Cur := '';
    for P := 1 to Length(Str) do
    begin
      if Str[P] = '''' then
        QuotePos := not QuotePos;
      if not QuotePos then
      begin
        if Str[P] = '(' then
          Inc(Delta)
        else if Str[P] = ')' then
          Dec(Delta)
        else if (Str[P] = ',') and (Delta = 0) then
        begin
          AList.Add(Trim(Cur));
          Cur := '';
          Continue;
        end;
      end;
      Cur := Cur + Str[P];
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

  function PropOf(DfmNode2: TDfmNode; const AName: string): string;
  var
    K: Integer;
  begin
    Result := '';
    K := DfmNode2.PropN.IndexOf(AName);
    if K >= 0 then
      Result := DfmNode2.PropV[K];
  end;

  // Сколько подписей детей этого описания в коде (P.Items.Add(X) и т.п.)
  // совпадает с подписями детей узла в снимке. Дети описания - из ByPar:
  // перебирать все описания на каждый вызов - сотни тысяч сравнений.
  function ChildMatches(ARec: TCreateRec; DfmNode2: TDfmNode): Integer;
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
      for L := 0 to DfmNode2.Children.Count - 1 do
      begin
        CN := TDfmNode(DfmNode2.Children[L]);
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
  function Score(ARec: TCreateRec; DfmNode2: TDfmNode; const AParent: string;
                 AOrd: Integer): Integer;
  var
    CodeStr: string;
  begin
    Result := -1;
    if CompareText(ARec.Cls, DfmNode2.ClassNm) <> 0 then
      Exit;
    Result := 2 * ChildMatches(ARec, DfmNode2);
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
      CodeStr := PropOf(DfmNode2, 'Caption');
      if CodeStr = '' then
        CodeStr := PropOf(DfmNode2, 'Text');
      if RecCapMatches(ARec, CodeStr) then
        Inc(Result, 10)
      else if RecCapStarts(ARec, CodeStr) then
        Inc(Result, 5)   // к подписи из кода в работе что-то дописали
      else
      begin
        Result := -1;
        Exit;
      end;
    end;
    if ARec.Align <> '' then
      if CompareText(ARec.Align, PropOf(DfmNode2, 'Align')) = 0 then
        Inc(Result, 3)
      else
      begin
        Result := -1;
        Exit;
      end;
    // Подсказка из аргумента помощника различает одинаковые кнопки
    // (MakeCmpButton(btnViewUnit, 1, 'View Unit - ...')). Не совпала - не
    // запрет: подсказку могли поменять в работе.
    if (ARec.Hint <> '') and (ARec.Hint = PropOf(DfmNode2, 'Hint')) then
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
    DfmNode, ByteVal: TDfmNode;
    CapA: string;
  begin
    Result := 0;
    DfmNode := TDfmNode(AParentNode.Children[K]);
    CapA := PropOf(DfmNode, 'Caption');
    for M := 0 to K - 1 do
    begin
      ByteVal := TDfmNode(AParentNode.Children[M]);
      if (CompareText(ByteVal.ClassNm, DfmNode.ClassNm) = 0) and
         (PropOf(ByteVal, 'Caption') = CapA) then
        Inc(Result);
    end;
  end;

  // Братья под одним родителем: у каждого безымянного - лучшее описание.
  // Описание, лучшее сразу для двоих, не достаётся никому.
  procedure ResolveLevel(AParentNode: TDfmNode; const AParentName: string);
  var
    K, M, Best, BestSc, Sc, Cnt, Top, Ord: Integer;
    CodeStr: TDfmNode;
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
        CodeStr := TDfmNode(AParentNode.Children[K]);
        // Имя ищем только у узлов снимка: у узлов из кода оно уже есть.
        // Уже названные на прошлом проходе - пропускаем.
        if CodeStr.IsLink or (CodeStr.Name <> '') or not CodeStr.IsSnap or (CodeStr.VarName <> '') then
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
          Sc := Score(TCreateRec(Recs[M]), CodeStr, AParentName, Ord);
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
        CodeStr := TDfmNode(AParentNode.Children[K]);
        CodeStr.VarName := TCreateRec(Recs[Pick[K]]).LHS;
        CodeStr.CreateLine := TCreateRec(Recs[Pick[K]]).Line;
        Changed := True;
      end;
      for K := 0 to High(Pick) do
        if (Pick[K] >= 0) and (TDfmNode(AParentNode.Children[K]).VarName <> '') then
          TCreateRec(Recs[Pick[K]]).Used := True;
    until not Changed;

    // Вниз: имя родителя для детей - имя из .dfm или найденная переменная
    for K := 0 to AParentNode.Children.Count - 1 do
    begin
      CodeStr := TDfmNode(AParentNode.Children[K]);
      if CodeStr.IsLink then
        Continue;
      if CodeStr.Name <> '' then
        ChildName := CodeStr.Name
      else
        ChildName := CodeStr.VarName;
      ResolveLevel(CodeStr, ChildName);
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
        Txt := Trim(Lines[I]);
        ByteVal := Pos(':=', Txt);
        if (Copy(Txt, 1, 2) <> '//') and (Crs.Count > 0) then
        begin
          if ByteVal > 0 then
          begin
            Lhs := Trim(Copy(Txt, 1, ByteVal - 1));
            ValStr := Trim(Copy(Txt, ByteVal + 2, MaxInt));
          end
          else
          begin
            Lhs := '';
            ValStr := Txt;
          end;
          QuotePos := Pos('(', ValStr);
          if (QuotePos > 0) and ((Lhs = '') or IsValidIdent(Lhs)) and
             (Pos('.', Trim(Copy(ValStr, 1, QuotePos - 1))) = 0) then
          begin
            // Функция-помощник или процедура-создатель (MakeCmpButton(btnX,
            // ...)). Создатель вызывается только без присваивания.
            FactoryRec := FindFactory(Trim(Copy(ValStr, 1, QuotePos - 1)));
            if (FactoryRec <> nil) and (ByteVal > 0) and (FactoryRec.OutIdx >= 0) then
              FactoryRec := nil;
            if FactoryRec <> nil then
            begin
              // Вызов целиком, он может занимать несколько строк
              Call := Copy(ValStr, QuotePos + 1, MaxInt);
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
              if FactoryRec.OutIdx >= 0 then
              begin
                Lhs := '';
                if (FactoryRec.OutIdx < Args.Count) and IsValidIdent(Trim(Args[FactoryRec.OutIdx])) then
                  Lhs := Trim(Args[FactoryRec.OutIdx]);
              end;

              CreateRec := TCreateRec.Create;
              CreateRec.LHS := Lhs;
              CreateRec.Cls := FactoryRec.Cls;
              CreateRec.Line := I;
              CreateRec.Par := FactoryRec.FixedPar;
              if (FactoryRec.ParIdx >= 0) and (FactoryRec.ParIdx < Args.Count) then
              begin
                ValStr := Args[FactoryRec.ParIdx];
                // FTabsPopup.Items -> FTabsPopup
                if CompareText(Copy(ValStr, Length(ValStr) - 5, 6), '.Items') = 0 then
                  Delete(ValStr, Length(ValStr) - 5, 6);
                if IsValidIdent(ValStr) then
                  CreateRec.Par := ValStr;
              end;
              if (FactoryRec.CapIdx >= 0) and (FactoryRec.CapIdx < Args.Count) and
                 (Args[FactoryRec.CapIdx] <> '') and (Args[FactoryRec.CapIdx][1] in ['''', '#']) then
                CreateRec.AddCap(DecodeDfmString(Args[FactoryRec.CapIdx]));
              if (FactoryRec.HintIdx >= 0) and (FactoryRec.HintIdx < Args.Count) and
                 (Args[FactoryRec.HintIdx] <> '') and (Args[FactoryRec.HintIdx][1] in ['''', '#']) then
                CreateRec.Hint := DecodeDfmString(Args[FactoryRec.HintIdx]);
              Recs.Add(CreateRec);
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

        CreateRec := TCreateRec.Create;
        CreateRec.LHS := Lhs;
        CreateRec.Cls := Cls;
        CreateRec.Line := I;
        Recs.Add(CreateRec);

        for J := I + 1 to I + 80 do
        begin
          if J >= Lines.Count then
            Break;
          Txt := Trim(Lines[J]);
          // Создание другой переменной - дальше описание не наше
          if ParseCreate(Txt, ValStr, TU) and (CompareText(TU, Lhs) <> 0) then
            Break;
          TU := AnsiUpperCase(Txt);
          QuotePos := Length(Lhs) + 1;
          if Copy(TU, 1, QuotePos) <> AnsiUpperCase(Lhs) + '.' then
            Continue;
          ByteVal := Pos(':=', Txt);
          if ByteVal <= 0 then
            Continue;
          ValStr := UpperCase(Trim(Copy(Txt, QuotePos + 1, ByteVal - QuotePos - 1)));
          if ValStr = 'PARENT' then
            CreateRec.Par := IdentAfterAssign(Txt)
          else if (ValStr = 'CAPTION') or (ValStr = 'TEXT') then
            CreateRec.AddCap(LiteralAfterAssign(Txt))
          else if ValStr = 'ALIGN' then
            CreateRec.Align := IdentAfterAssign(Txt);
        end;
      end;

      // Родитель через добавление: P.Items.Add(X), P.Add(X), P.Items.Insert(N,
      // X), P.Insert(N, X). Так в меню попадают пункты - Parent у них нет.
      for I := 0 to Lines.Count - 1 do
      begin
        Txt := Trim(Lines[I]);
        if Copy(Txt, 1, 2) = '//' then
          Continue;
        TU := UpperCase(Txt);
        ByteVal := Pos('.ADD(', TU);
        if ByteVal = 0 then
        begin
          ByteVal := Pos('.INSERT(', TU);
          if ByteVal = 0 then
            Continue;
          ValStr := Copy(Txt, ByteVal + 8, MaxInt);       // "N, X);"
          QuotePos := Pos(',', ValStr);
          if QuotePos = 0 then
            Continue;
          ValStr := Trim(Copy(ValStr, QuotePos + 1, MaxInt));
        end
        else
          ValStr := Trim(Copy(Txt, ByteVal + 5, MaxInt));  // "X);"
        QuotePos := 1;
        while (QuotePos <= Length(ValStr)) and (ValStr[QuotePos] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) do
          Inc(QuotePos);
        ValStr := Copy(ValStr, 1, QuotePos - 1);             // X
        Lhs := Trim(Copy(Txt, 1, ByteVal - 1));       // P или P.Items
        if CompareText(Copy(Lhs, Length(Lhs) - 5, 6), '.Items') = 0 then
          Delete(Lhs, Length(Lhs) - 5, 6);
        if (ValStr = '') or (Lhs = '') or (Pos('.', Lhs) > 0) or (Pos(' ', Lhs) > 0) then
          Continue;
        // Последнее создание X выше этой строки
        for J := Recs.Count - 1 downto 0 do
        begin
          CreateRec := TCreateRec(Recs[J]);
          if (CreateRec.Line < I) and (CompareText(CreateRec.LHS, ValStr) = 0) then
          begin
            if CreateRec.Par = '' then
              CreateRec.Par := Lhs;
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
            CreateRec := TCreateRec(Recs[J]);
            if (CreateRec.Line < I) and (CompareText(CreateRec.LHS, CVar) = 0) then
            begin
              if CreateRec.Par = '' then
                CreateRec.Par := CPar;
              if (CCap <> '') and (CCap[1] in ['''', '#']) then
                CreateRec.AddCap(DecodeDfmString(CCap));
              Break;
            end;
          end;

      // Родитель, переданный конструктору (TDsgPalette.CreatePalette(Self,
      // pnlPaletteIn, ...)): первый аргумент, который сам создан в коде
      for I := 0 to Recs.Count - 1 do
      begin
        CreateRec := TCreateRec(Recs[I]);
        if (CreateRec.Par <> '') or (CreateRec.LHS = '') then
          Continue;
        Txt := Lines[CreateRec.Line];
        QuotePos := CodeCreatePos(UpperCase(Txt));
        if QuotePos = 0 then
          Continue;
        Txt := Copy(Txt, QuotePos + 1, MaxInt);
        QuotePos := Pos('(', Txt);
        ByteVal := LastDelimiter(')', Txt);
        if (QuotePos = 0) or (ByteVal <= QuotePos) then
          Continue;
        SplitArgs(Copy(Txt, QuotePos + 1, ByteVal - QuotePos - 1), Args);
        for J := 0 to Args.Count - 1 do
        begin
          ValStr := Trim(Args[J]);
          if not IsValidIdent(ValStr) or (CompareText(ValStr, 'Self') = 0) or
             (CompareText(ValStr, 'nil') = 0) or (CompareText(ValStr, 'Owner') = 0) or
             (CompareText(ValStr, 'AOwner') = 0) or
             (CompareText(ValStr, 'Application') = 0) then
            Continue;
          for K := 0 to Recs.Count - 1 do
            if (K <> I) and (CompareText(TCreateRec(Recs[K]).LHS, ValStr) = 0) then
            begin
              CreateRec.Par := ValStr;
              CreateRec.ParGuess := True;
              Break;
            end;
          if CreateRec.Par <> '' then
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
        Txt := Trim(Lines[I]);
        if Copy(Txt, 1, 2) = '//' then
          Continue;
        ByteVal := Pos(':=', Txt);
        if ByteVal = 0 then
          Continue;
        TU := UpperCase(Trim(Copy(Txt, 1, ByteVal - 1)));
        QuotePos := LastDelimiter('.', TU);
        if QuotePos = 0 then
          Continue;
        ValStr := Copy(TU, QuotePos + 1, MaxInt);
        if (ValStr <> 'PARENT') and (ValStr <> 'PAGECONTROL') then
          Continue;
        Lhs := Trim(Copy(Txt, 1, QuotePos - 1));
        if not IsValidIdent(Lhs) then
          Continue;
        for J := Recs.Count - 1 downto 0 do
        begin
          CreateRec := TCreateRec(Recs[J]);
          if (CreateRec.Line < I) and (CompareText(CreateRec.LHS, Lhs) = 0) then
          begin
            // Явный .Parent важнее догадки по аргументу конструктора
            if (CreateRec.Par = '') or CreateRec.ParGuess then
            begin
              CreateRec.Par := IdentAfterAssign(Txt);
              CreateRec.ParGuess := False;
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
        Txt := Trim(Lines[I]);
        if Copy(Txt, 1, 2) = '//' then
          Continue;
        ByteVal := Pos(':=', Txt);
        if ByteVal = 0 then
          Continue;
        TU := UpperCase(Trim(Copy(Txt, 1, ByteVal - 1)));
        QuotePos := LastDelimiter('.', TU);
        if QuotePos = 0 then
          Continue;
        ValStr := Copy(TU, QuotePos + 1, MaxInt);
        if (ValStr <> 'CAPTION') and (ValStr <> 'TEXT') then
          Continue;
        Lhs := Trim(Copy(Txt, 1, QuotePos - 1));
        if not IsValidIdent(Lhs) then
          Continue;
        ValStr := LiteralAfterAssign(Txt);
        if ValStr = '' then
          Continue;
        CreateRec := nil;
        for J := 0 to Recs.Count - 1 do
          if CompareText(TCreateRec(Recs[J]).LHS, Lhs) = 0 then
          begin
            if (CreateRec = nil) or (TCreateRec(Recs[J]).Line < I) then
              CreateRec := TCreateRec(Recs[J]);
            if TCreateRec(Recs[J]).Line > I then
              Break;
          end;
        if CreateRec <> nil then
          CreateRec.AddCap(ValStr);
      end;

      // Родитель - параметр процедуры: подставляем аргумент из её вызова
      for I := 0 to Recs.Count - 1 do
      begin
        CreateRec := TCreateRec(Recs[I]);
        if CreateRec.Par <> '' then
          CreateRec.Par := CodeResolveParamPar(Lines, CreateRec.Line, CreateRec.Par);
      end;

      // Создания в теле цикла
      for I := 0 to Recs.Count - 1 do
        TCreateRec(Recs[I]).InLoop :=
          CodeLineInLoop(Lines, TCreateRec(Recs[I]).Line);

      // Порядок одинаковых описаний у одного родителя
      for I := 0 to Recs.Count - 1 do
      begin
        CreateRec := TCreateRec(Recs[I]);
        CreateRec.Ord := 0;
        for J := 0 to I - 1 do
          if (CompareText(TCreateRec(Recs[J]).Par, CreateRec.Par) = 0) and
             (CompareText(TCreateRec(Recs[J]).Cls, CreateRec.Cls) = 0) and
             (TCreateRec(Recs[J]).Cap = CreateRec.Cap) then
            Inc(CreateRec.Ord);
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
      CreateRec := TCreateRec(Recs[I]);
      if (CreateRec.Caps <> nil) and (CreateRec.Cap <> '-') and (CreateRec.Par <> '') then
        ByPar.AddObject(CreateRec.Par, CreateRec);
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
  I, J, K, CharPos, AssignPos: Integer;
  Txt, UpStr, Cls, Lhs, PName, ValStr: string;
  CodeRec2, R2, CodeRec: TCodeRec;
  Root, Target, Grp, DfmNode2, DfmNode, LinkTo: TDfmNode;
  Key, Names: string;

  function IsIdentChar(CodeRec: Char): Boolean;
  begin
    Result := CodeRec in ['a'..'z', 'A'..'Z', '0'..'9', '_'];
  end;

  // Значение справа от := до ';' или комментария, кавычки учитываются
  function ValueAfterAssign(const ALine: string): string;
  var
    Str: string;
    M: Integer;
    InQ: Boolean;
  begin
    Result := '';
    M := Pos(':=', ALine);
    if M <= 0 then
      Exit;
    Str := Trim(Copy(ALine, M + 2, MaxInt));
    InQ := False;
    for M := 1 to Length(Str) do
    begin
      if Str[M] = '''' then
        InQ := not InQ
      else if not InQ and ((Str[M] = ';') or
              ((Str[M] = '/') and (M < Length(Str)) and (Str[M + 1] = '/'))) then
      begin
        Result := Trim(Copy(Str, 1, M - 1));
        Exit;
      end;
    end;
    Result := Str;
  end;

  // "  X := TКласс.Create(" -> класс и переменная. Комментарий в конце
  // строки не читается.
  function ParseCreate(const ALine: string; var AClass, ALhs: string): Boolean;
  var
    Str, SU: string;
    M, CodeRec: Integer;
  begin
    Result := False;
    Str := Trim(ALine);
    if Copy(Str, 1, 2) = '//' then
      Exit;
    Str := CodeNoComment(Str);
    SU := UpperCase(Str);
    CodeRec := CodeCreatePos(SU);
    if CodeRec <= 0 then
      Exit;
    M := CodeRec - 1;
    while (M >= 1) and IsIdentChar(Str[M]) do
      Dec(M);
    AClass := Copy(Str, M + 1, CodeRec - 1 - M);
    ALhs := '';
    AssignPos := Pos(':=', Str);
    if (AssignPos > 0) and (AssignPos < M + 1) then
      ALhs := Trim(Copy(Str, 1, AssignPos - 1));
    if CompareText(Copy(ALhs, 1, 5), 'Self.') = 0 then
      ALhs := Copy(ALhs, 6, MaxInt);
    Result := (AClass <> '') and (UpCase(AClass[1]) = 'T');
  end;

  // Поля класса формы: строки "Имя1, Имя2: TТип;" между "TForm1 = class"
  // и его end
  procedure CollectFields;
  var
    M, CodeRec: Integer;
    Str, SU, Names, One: string;
    Inside: Boolean;
  begin
    Inside := False;
    for M := 0 to Lines.Count - 1 do
    begin
      Str := Trim(Lines[M]);
      SU := UpperCase(Str);
      if not Inside then
      begin
        if Pos(UpperCase(AFormClass) + ' = CLASS', SU) = 1 then
          Inside := True;
        Continue;
      end;
      if SU = 'END;' then
        Break;
      if (Str = '') or (Copy(Str, 1, 2) = '//') or (Str[1] = '{') then
        Continue;
      if (Pos('PROCEDURE ', SU) = 1) or (Pos('FUNCTION ', SU) = 1) or
         (Pos('PROPERTY ', SU) = 1) or (Pos('CONSTRUCTOR ', SU) = 1) or
         (Pos('DESTRUCTOR ', SU) = 1) then
        Continue;
      CodeRec := Pos(':', Str);
      if CodeRec <= 0 then
        Continue;
      Names := Copy(Str, 1, CodeRec - 1);
      while Names <> '' do
      begin
        CodeRec := Pos(',', Names);
        if CodeRec > 0 then
        begin
          One := Trim(Copy(Names, 1, CodeRec - 1));
          Names := Copy(Names, CodeRec + 1, MaxInt);
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
    CodeRec3: TCodeRec;
  begin
    Result := nil;
    for M := 0 to Recs.Count - 1 do
    begin
      CodeRec3 := TCodeRec(Recs[M]);
      if ((CodeRec3.Node = nil) and not AAll) or (CompareText(CodeRec3.LHS, AName) <> 0) then
        Continue;
      if CodeRec3.Line < ABefore then
        Result := CodeRec3
      else if Result = nil then
      begin
        Result := CodeRec3;
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
        UpStr := UpperCase(Lines[I]);
        Bound[I] := (Pos('PROCEDURE ', UpStr) = 1) or (Pos('FUNCTION ', UpStr) = 1) or
                    (Pos('CONSTRUCTOR ', UpStr) = 1) or (Pos('DESTRUCTOR ', UpStr) = 1) or
                    (Pos('INITIALIZATION', UpStr) = 1) or (Pos('END.', UpStr) = 1);
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

        CodeRec2 := TCodeRec.Create;
        CodeRec2.LHS := Lhs;
        CodeRec2.Cls := Cls;
        CodeRec2.Line := I;
        CodeRec2.ParLine := -1;
        if FPar <> '' then
        begin
          CodeRec2.Par := FPar;
          CodeRec2.ParLine := I;
        end;
        CodeRec2.Cap := FCap;
        Recs.Add(CodeRec2);

        // Описание - до конца процедуры или до нового создания этой же
        // переменной (локальную переиспользуют)
        CodeRec2.EndLine := Lines.Count - 1;
        for J := I + 1 to Lines.Count - 1 do
        begin
          if Bound[J] then
          begin
            CodeRec2.EndLine := J - 1;
            Break;
          end;
          if ParseCreate(Lines[J], ValStr, UpStr) and (CompareText(UpStr, Lhs) = 0) then
          begin
            CodeRec2.EndLine := J - 1;
            Break;
          end;
        end;
      end;

      // --- свойства, события и родитель каждого создания
      for K := 0 to Recs.Count - 1 do
      begin
        CodeRec2 := TCodeRec(Recs[K]);
        DfmNode2 := nil;

        for J := CodeRec2.Line + 1 to CodeRec2.EndLine do
        begin
          Txt := Trim(Lines[J]);
          if (Txt = '') or (Copy(Txt, 1, 2) = '//') then
            Continue;
          UpStr := AnsiUpperCase(Txt);

          // Настройщик: SetupSwatch(pnlGutterBG, ...) даёт родителя
          if (CodeRec2.Par = '') and
             CodeConfCall(Lines, J, Facts, CVar, CPar, CCap) and
             (CompareText(CVar, CodeRec2.LHS) = 0) then
          begin
            CodeRec2.Par := CPar;
            CodeRec2.ParLine := J;
            Continue;
          end;

          // Пункт меню: Y.Add(X) или Y.Items.Add(X)
          CharPos := Pos('.ADD(' + AnsiUpperCase(CodeRec2.LHS) + ')', UpStr);
          if CharPos > 0 then
          begin
            ValStr := Trim(Copy(Txt, 1, CharPos - 1));
            if CompareText(Copy(ValStr, Length(ValStr) - 5, 6), '.Items') = 0 then
              ValStr := Copy(ValStr, 1, Length(ValStr) - 6);
            CodeRec2.Par := ValStr;
            CodeRec2.ParLine := J;
            Continue;
          end;

          if Pos(AnsiUpperCase(CodeRec2.LHS) + '.', UpStr) <> 1 then
            Continue;
          AssignPos := Pos(':=', Txt);
          if AssignPos <= 0 then
            Continue;
          PName := Trim(Copy(Txt, Length(CodeRec2.LHS) + 2, AssignPos - Length(CodeRec2.LHS) - 2));
          if (PName = '') or (Pos('(', PName) > 0) then
            Continue;
          ValStr := ValueAfterAssign(Txt);

          if (CompareText(PName, 'Parent') = 0) or
             (CompareText(PName, 'PageControl') = 0) then
          begin
            CodeRec2.Par := ValStr;
            CodeRec2.ParLine := J;
          end;

          if DfmNode2 = nil then
            DfmNode2 := TDfmNode.Create; // временный сборщик, узел - ниже
          if (Copy(PName, 1, 2) = 'On') and (ValStr <> '') and IsIdentChar(ValStr[1]) then
          begin
            DfmNode2.EvN.AddObject(PName, TObject(J));
            DfmNode2.EvV.Add(ValStr);
          end
          else
          begin
            DfmNode2.PropN.AddObject(PName, TObject(J));
            DfmNode2.PropV.Add(ValStr);
            DfmNode2.PropRaw.AddObject(ValStr, TObject(1));
          end;
        end;

        // Родителя нет ни в .Parent, ни в .Add - его могли передать
        // конструктору: TDsgPalette.CreatePalette(Self, pnlPaletteIn, ...).
        // Берётся первый аргумент, который - известный компонент (из .dfm
        // или созданный в коде); Self, nil и прочее - не родитель.
        if CodeRec2.Par = '' then
        begin
          Txt := Lines[CodeRec2.Line];
          CharPos := CodeCreatePos(UpperCase(Txt));
          if CharPos > 0 then
          begin
            Txt := Copy(Txt, CharPos + 1, MaxInt);
            CharPos := Pos('(', Txt);
            AssignPos := LastDelimiter(')', Txt);
            if (CharPos > 0) and (AssignPos > CharPos) then
            begin
              CtorArgs.Clear;
              CodeSplitArgs(Copy(Txt, CharPos + 1, AssignPos - CharPos - 1), CtorArgs);
              for J := 0 to CtorArgs.Count - 1 do
              begin
                ValStr := Trim(CtorArgs[J]);
                if not IsValidIdent(ValStr) or (CompareText(ValStr, 'Self') = 0) or
                   (CompareText(ValStr, 'nil') = 0) or
                   (CompareText(ValStr, 'Application') = 0) or
                   (CompareText(ValStr, 'Owner') = 0) or
                   (CompareText(ValStr, 'AOwner') = 0) then
                  Continue;
                if (Index.IndexOf(ValStr) >= 0) or
                   ((RecOf(ValStr, CodeRec2.Line, True) <> nil) and
                    (RecOf(ValStr, CodeRec2.Line, True) <> CodeRec2)) then
                begin
                  CodeRec2.Par := ValStr;
                  CodeRec2.ParLine := CodeRec2.Line;
                  Break;
                end;
              end;
            end;
          end;
        end;

        // Подпись из аргумента помощника - как свойство со строкой вызова
        if (CodeRec2.Cap <> '') and (CodeRec2.Cap[1] in ['''', '#']) then
        begin
          if DfmNode2 = nil then
            DfmNode2 := TDfmNode.Create;
          DfmNode2.PropN.AddObject('Caption', TObject(CodeRec2.Line));
          DfmNode2.PropV.Add(CodeRec2.Cap);
          DfmNode2.PropRaw.AddObject(CodeRec2.Cap, TObject(1));
        end;

        // В дерево - поля формы и то, у чего есть родитель. Для полного
        // дерева вкладки Code - всё: и окна-диалоги (Dlg := TForm.Create)
        if (Fields.IndexOf(CodeRec2.LHS) < 0) and (CodeRec2.Par = '') and not AFull then
        begin
          DfmNode2.Free;
          Continue;
        end;

        // В дерево пойдёт: свойства - в шаблон записи кэша, узел из него
        // делается ниже, при каждом вызове свой
        CodeRec2.InTree := True;
        if DfmNode2 = nil then
          DfmNode2 := TDfmNode.Create;
        CodeRec2.Tpl := DfmNode2;
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
      CodeRec := TCodeRec(CbrRecs[K]);
      CodeRec2 := TCodeRec.Create;
      CodeRec2.LHS := CodeRec.LHS;
      CodeRec2.Cls := CodeRec.Cls;
      CodeRec2.Par := CodeRec.Par;
      CodeRec2.Cap := CodeRec.Cap;
      CodeRec2.Line := CodeRec.Line;
      CodeRec2.ParLine := CodeRec.ParLine;
      CodeRec2.EndLine := CodeRec.EndLine;
      if CodeRec.InTree then
      begin
        CodeRec2.Node := NewNode('', CodeRec2.Cls);
        CodeRec2.Node.VarName := CodeRec2.LHS;
        CodeRec2.Node.CreateLine := CodeRec2.Line;
        CodeRec2.Node.IsRuntime := True;
        CodeRec2.Node.FromCode := True;
        CodeRec2.Node.PropN.Assign(CodeRec.Tpl.PropN);
        CodeRec2.Node.PropV.Assign(CodeRec.Tpl.PropV);
        CodeRec2.Node.PropRaw.Assign(CodeRec.Tpl.PropRaw);
        CodeRec2.Node.EvN.Assign(CodeRec.Tpl.EvN);
        CodeRec2.Node.EvV.Assign(CodeRec.Tpl.EvV);
      end;
      Recs.Add(CodeRec2);
    end;

    // Границы процедур нужны и раскладке (родитель через переменную); при
    // сборе из кэша их ещё нет
    if Length(Bound) <> Lines.Count then
    begin
      SetLength(Bound, Lines.Count);
      for I := 0 to Lines.Count - 1 do
      begin
        UpStr := UpperCase(Lines[I]);
        Bound[I] := (Pos('PROCEDURE ', UpStr) = 1) or (Pos('FUNCTION ', UpStr) = 1) or
                    (Pos('CONSTRUCTOR ', UpStr) = 1) or (Pos('DESTRUCTOR ', UpStr) = 1) or
                    (Pos('INITIALIZATION', UpStr) = 1) or (Pos('END.', UpStr) = 1);
      end;
    end;

    // --- раскладка по родителям, в порядке текста
    Grp := nil;
    for K := 0 to Recs.Count - 1 do
    begin
      CodeRec2 := TCodeRec(Recs[K]);
      if CodeRec2.Node = nil then
        Continue;

      // Родитель - параметр процедуры (lstCompTypes.Parent := ATab в
      // BuildCompilersTab(ATab)) - подставляем аргумент из её вызова.
      // Если параметру выше в той же процедуре присвоен новый объект
      // (AForm := TForm.Create(Self) в MakeListWindow(var AForm: TForm)),
      // родитель - этот объект, подстановка не нужна.
      if CodeRec2.Par <> '' then
      begin
        if CodeRec2.ParLine >= 0 then
          CharPos := CodeRec2.ParLine
        else
          CharPos := CodeRec2.Line;
        R2 := RecOf(CodeRec2.Par, CharPos, True);
        if (R2 = nil) or (R2 = CodeRec2) or (R2.Line >= CharPos) or (R2.EndLine < CharPos) then
          CodeRec2.Par := CodeResolveParamPar(Lines, CodeRec2.Line, CodeRec2.Par);
      end;

      Target := nil;
      if (CodeRec2.Par = '') or (CompareText(CodeRec2.Par, 'Self') = 0) or
         (CompareText(CodeRec2.Par, Root.Name) = 0) then
        Target := Root
      else
      begin
        J := Index.IndexOf(CodeRec2.Par);
        if J >= 0 then
          Target := TDfmNode(Index.Objects[J])
        else
        begin
          if CodeRec2.ParLine >= 0 then
            R2 := RecOf(CodeRec2.Par, CodeRec2.ParLine, True)
          else
            R2 := RecOf(CodeRec2.Par, CodeRec2.Line, True);
          if (R2 <> nil) and (R2 <> CodeRec2) then
          begin
            // Родитель - временное окно или то, что в нём лежит: и этот
            // компонент к форме не относится
            if (R2.Node = nil) or R2.Dropped then
            begin
              CodeRec2.Dropped := True;
              Continue;
            end;
            Target := R2.Node;
          end;
        end;
      end;

      // Родитель - переменная, которой выше в той же процедуре присвоен
      // готовый компонент: Sheet := FObjPagesSheet1; ... MakeView(Sheet)
      // (так пишет перенос в .dfm). Родитель - этот компонент.
      if (Target = nil) and (CodeRec2.Par <> '') then
      begin
        if CodeRec2.ParLine >= 0 then
          CharPos := CodeRec2.ParLine
        else
          CharPos := CodeRec2.Line;
        for J := CharPos - 1 downto 0 do
        begin
          if Bound[J] then
            Break;
          Txt := Trim(CodeNoComment(Lines[J]));
          AssignPos := Pos(':=', Txt);
          if (AssignPos = 0) or (CompareText(Trim(Copy(Txt, 1, AssignPos - 1)), CodeRec2.Par) <> 0) then
            Continue;
          ValStr := ValueAfterAssign(Txt);
          if IsValidIdent(ValStr) then
          begin
            AssignPos := Index.IndexOf(ValStr);
            if AssignPos >= 0 then
              Target := TDfmNode(Index.Objects[AssignPos]);
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

      CodeRec2.Node.Parent := Target;
      Target.Children.Add(CodeRec2.Node);
    end;

    // --- компоненты из .dfm, перенесённые кодом в созданную панель:
    // D.Parent := X. Внутри X - ссылка, свойства у D на своём месте.
    // X может лежать и в .dfm (панель, которую раньше создавал код,
    // перенесли в .dfm): ссылка нужна и тогда, если X - не тот, в чьём
    // блоке D лежит в .dfm. По ссылке конструктор переставляет D туда же,
    // куда его ставит код.
    for I := 0 to Lines.Count - 1 do
    begin
      Txt := Trim(Lines[I]);
      if (Txt = '') or (Copy(Txt, 1, 2) = '//') then
        Continue;
      CharPos := Pos('.', Txt);
      AssignPos := Pos(':=', Txt);
      if (CharPos <= 1) or (AssignPos <= CharPos) then
        Continue;
      if CompareText(Trim(Copy(Txt, CharPos + 1, AssignPos - CharPos - 1)), 'Parent') <> 0 then
        Continue;
      J := Index.IndexOf(Copy(Txt, 1, CharPos - 1));
      if J < 0 then
        Continue;
      DfmNode := TDfmNode(Index.Objects[J]);
      R2 := RecOf(ValueAfterAssign(Txt), I);
      if (R2 <> nil) and (R2.Node <> nil) then
        LinkTo := R2.Node
      else
      begin
        K := Index.IndexOf(ValueAfterAssign(Txt));
        if K < 0 then
          Continue;
        LinkTo := TDfmNode(Index.Objects[K]);
        if (LinkTo = DfmNode) or (LinkTo = DfmNode.Parent) then
          Continue;
      end;
      DfmNode2 := NewNode(DfmNode.Name, DfmNode.ClassNm);
      DfmNode2.IsLink := True;
      DfmNode2.Parent := LinkTo;
      LinkTo.Children.Add(DfmNode2);
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

  procedure Walk(DfmNode2: TDfmNode);
  var
    DfmNode, DfmNode3: TDfmNode;
    I, K, M: Integer;
    Found, Move: Boolean;
  begin
    // Перенос узла кода мог укоротить и этот список - индекс проверяется
    for I := DfmNode2.Children.Count - 1 downto 0 do
      if I < DfmNode2.Children.Count then
        Walk(TDfmNode(DfmNode2.Children[I]));

    for I := DfmNode2.Children.Count - 1 downto 0 do
    begin
      if I >= DfmNode2.Children.Count then
        Continue; // список укоротился переносом узла кода
      DfmNode := TDfmNode(DfmNode2.Children[I]);
      if not DfmNode.IsSnap or (DfmNode.CreateLine < 0) then
        Continue;
      if Multi.IndexOf(IntToStr(DfmNode.CreateLine)) >= 0 then
        Continue;
      K := AByLine.IndexOf(IntToStr(DfmNode.CreateLine));
      if K < 0 then
        Continue;
      DfmNode3 := TDfmNode(AByLine.Objects[K]);
      if DfmNode3 = DfmNode then
        Continue;

      for M := 0 to DfmNode.PropN.Count - 1 do
      begin
        // Свойство может присваиваться в коде несколько раз
        // (chkList.Left := 240; ... chkList.Left := chkList.Left + D) - живое
        // значение получают все такие строки. И не только показ (PropV), но
        // и текст значения (PropRaw): по нему конструктор ставит компонент,
        // и выражение из кода там дало бы Left = 0.
        Found := False;
        for K := 0 to DfmNode3.PropN.Count - 1 do
          if CompareText(DfmNode3.PropN[K], DfmNode.PropN[M]) = 0 then
          begin
            DfmNode3.PropV[K] := DfmNode.PropV[M];
            // Текст значения - как записан в снимке (строки в апострофах),
            // а не показ: показ расшифрован, и конструктор его не разберёт
            if (K < DfmNode3.PropRaw.Count) and (M < DfmNode.PropRaw.Count) then
              DfmNode3.PropRaw[K] := DfmNode.PropRaw[M];
            Found := True;
          end;
        if not Found then
        begin
          DfmNode3.PropN.AddObject(DfmNode.PropN[M], TObject(-1));
          DfmNode3.PropV.Add(DfmNode.PropV[M]);
          if M < DfmNode.PropRaw.Count then
            DfmNode3.PropRaw.AddObject(DfmNode.PropRaw[M], TObject(1))
          else
            DfmNode3.PropRaw.AddObject(DfmNode.PropV[M], TObject(1));
        end;
      end;
      DfmNode3.IsLive := True;

      Move := (Placed.IndexOf(DfmNode3) < 0) and not Inside(DfmNode2, DfmNode3, 0);
      if Move then
        // С прежнего места - до переноса детей: узел кода мог уже лежать
        // внутри узла снимка (его туда поставил перенос уровнем ниже)
        Detach(DfmNode3)
      else if Inside(DfmNode3, DfmNode, 0) then
        // Узел кода остаётся внутри узла снимка: влить в него детей узла
        // снимка - получить цикл. Узел снимка остаётся как есть.
        Continue;

      for M := 0 to DfmNode.Children.Count - 1 do
      begin
        TDfmNode(DfmNode.Children[M]).Parent := DfmNode3;
        DfmNode3.Children.Add(DfmNode.Children[M]);
      end;
      DfmNode.Children.Clear;

      K := DfmNode2.Children.IndexOf(DfmNode);
      if Move then
      begin
        // Узел кода - на место узла снимка, под настоящего родителя
        if K >= 0 then
          DfmNode2.Children[K] := DfmNode3
        else
          DfmNode2.Children.Add(DfmNode3);
        DfmNode3.Parent := DfmNode2;
        Placed.Add(DfmNode3);
      end
      else if K >= 0 then
        // Как раньше: узел кода остаётся где был, узел снимка уходит
        DfmNode2.Children.Delete(K);
    end;
  end;

var
  I, K: Integer;
  StrList: TStringList;
  DfmNode3: TDfmNode;
begin
  Placed := TList.Create;
  Multi := TStringList.Create;
  StrList := TStringList.Create;
  try
    // Сколько узлов снимка на каждой строке создания
    StrList.Sorted := True;
    Multi.Sorted := True;
    Multi.Duplicates := dupIgnore;
    for I := 0 to ANodes.Count - 1 do
    begin
      DfmNode3 := TDfmNode(ANodes[I]);
      if not DfmNode3.IsSnap or (DfmNode3.CreateLine < 0) then
        Continue;
      if StrList.Find(IntToStr(DfmNode3.CreateLine), K) then
        Multi.Add(IntToStr(DfmNode3.CreateLine))
      else
        StrList.Add(IntToStr(DfmNode3.CreateLine));
    end;

    Walk(TDfmNode(ANode));

    // Узел кода с такой строкой - один на весь цикл; его компоненты уже
    // стоят в дереве узлами снимка. Детей из кода у него нет - убираем.
    for I := 0 to Multi.Count - 1 do
    begin
      K := AByLine.IndexOf(Multi[I]);
      if K < 0 then
        Continue;
      DfmNode3 := TDfmNode(AByLine.Objects[K]);
      if (DfmNode3 <> nil) and not DfmNode3.IsSnap and (DfmNode3.Children.Count = 0) then
        Detach(DfmNode3);
    end;
  finally
    StrList.Free;
    Multi.Free;
    Placed.Free;
  end;
end;

initialization

finalization
  RrnFree;
  CbrFree;

end.
