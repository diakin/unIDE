unit CodeInsight;

// Code Insight редактора: имена из текста Pascal для списка подстановки
// (Code completion) и сам список - всплывающее окно у каретки.
//
// Разбор - по словам очищенного текста (комментарии и строки - пробелами),
// без разбора типов: собираются объявления
//   uses        - модули;
//   const       - константы (Name = ..., Name: T = ...);
//   type        - типы (Name = ...); поля классов и записей - переменные;
//   var         - переменные (A, B: T);
//   label       - метки;
//   procedure, function, constructor, destructor - подпрограммы (с
//                 параметрами; abstract - отдельным цветом);
//   property    - свойства.
// Тела подпрограмм (begin ... end) пропускаются. interface-часть модуля
// разбирается отдельно (AInterfaceOnly) - для модулей из uses.
//
// Список - окно без активации (WS_POPUP, WS_EX_NOACTIVATE по смыслу:
// WM_MOUSEACTIVATE - MA_NOACTIVATE): фокус и каретка остаются в редакторе,
// клавиши списку передаёт редактор (Unit1, CiBeforeMessage).

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls;

type
  TCiKind = (ckConstant, ckFunction, ckLabel, ckProcedure, ckProperty,
             ckType, ckUnit, ckVariable, ckWord);

  // Видимость члена класса (strict private, strict protected - как
  // private и protected)
  TCiVisibility = (cvPublic, cvPublished, cvProtected, cvPrivate);

  TCiSymbol = record
    Name: string;
    Kind: TCiKind;
    Detail: string;       // параметры, тип, значение - как в объявлении
    IsAbstract: Boolean;
    Line: Integer;        // строка объявления (от 0)
    Owner: string;        // класс или запись, чей это член; '' - нет
    Visibility: TCiVisibility;   // у члена; у остальных - cvPublic
  end;

  // Именованный тип: в Delphi 7 два разных "array of TCiSymbol"
  // несовместимы при присваивании
  TCiSymbolArray = array of TCiSymbol;

  TCiSymbols = class
  private
    FItems: TCiSymbolArray;
    FCount: Integer;
    function GetItem(AIndex: Integer): TCiSymbol;
  public
    procedure Clear;
    procedure Add(const ASymbol: TCiSymbol);
    procedure AddAll(ASource: TCiSymbols);
    procedure SetDetail(AIndex: Integer; const ADetail: string);
    // По имени без учёта регистра; одноимённые одного вида - один раз
    procedure SortUnique;
    property Count: Integer read FCount;
    property Items[AIndex: Integer]: TCiSymbol read GetItem; default;
  end;

  TCiAcceptEvent = procedure(Sender: TObject) of object;

  // Список подстановки
  TCiListPopup = class(TCustomControl)
  private
    FAll: TCiSymbols;          // не принадлежит списку
    FShown: array of Integer;  // номера FAll, подходящие под начало имени
    FShownCount: Integer;
    FTop: Integer;
    FSel: Integer;
    FRows: Integer;
    FRowHeight: Integer;
    FKindWidth: Integer;
    FOnAccept: TCiAcceptEvent;
    procedure WMMouseActivate(var Message: TMessage); message WM_MOUSEACTIVATE;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure MeasureRows;
    procedure EnsureSelVisible;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        X, Y: Integer); override;
    procedure DblClick; override;
  public
    // Цвета: KindColors - по CiCol* (EnvOptions), BackColor и TextColor -
    // фон и имена
    KindColors: array[0..8] of TColor;
    BackColor: TColor;
    TextColor: TColor;
    constructor Create(AOwner: TComponent); override;
    procedure SetSymbols(ASymbols: TCiSymbols);
    // Оставить имена, начинающиеся с APrefix; результат - сколько осталось
    function ApplyFilter(const APrefix: string): Integer;
    procedure MoveSel(ADelta: Integer);
    function SelectedName: string;
    // Показать под точкой экрана AX, AY (низ строки с кареткой); не
    // помещается снизу - над строкой (ALineTop - её верх)
    procedure ShowAt(AX, AY, ALineTop: Integer);
    procedure HidePopup;
    function IsShown: Boolean;
    property OnAccept: TCiAcceptEvent read FOnAccept write FOnAccept;
  end;

// Комментарии и строки - пробелами, длина строк сохраняется
procedure CiCleanLines(ASrc, AClean: TStrings);
// Объявления текста ASrc (Pascal) - в ASymbols (добавляются)
procedure CiScanPascal(ASrc: TStrings; AInterfaceOnly: Boolean;
                       ASymbols: TCiSymbols);
// Все слова текста (не Pascal: список по словам файла)
procedure CiScanWords(ASrc: TStrings; ASymbols: TCiSymbols);
// Слово вида: procedure, function, var ...
function CiKindText(AKind: TCiKind): string;
// Свойство-событие: тип - указатель на метод (...Event) или имя OnXxx.
// В списке - словом event, хотя в Pascal это свойство (property OnClick:
// TNotifyEvent).
function CiIsEvent(const ASymbol: TCiSymbol): Boolean;
// Номер цвета CiCol* для символа
function CiColorIndex(const ASymbol: TCiSymbol): Integer;

// Тип переменной, поля, свойства, константы или результата функции - из
// Detail ('' - не имя типа: array of, set of, ^T ...)
function CiTypeOfSymbol(const ASymbol: TCiSymbol): string;
// Объявление типа (Detail символа типа) - класс, запись, объект или
// интерфейс с членами
function CiIsStructType(const ADetail: string): Boolean;
// Предок класса из Detail: class(TCustomEdit) - TCustomEdit; class без
// скобок - TObject; не класс - ''
function CiParentType(const ADetail: string): string;
// Синоним: TFoo = TBar или type TBar - TBar; иначе ''
function CiAliasType(const ADetail: string): string;
// Тип параметра AName из Detail подпрограммы "(A: T; var B, C: U)"
function CiParamType(const ADetail, AName: string): string;

implementation

const
  ColAbstract = 0;
  ColConstant = 1;
  ColFunction = 2;
  ColLabel = 3;
  ColProcedure = 4;
  ColProperty = 5;
  ColType = 6;
  ColUnit = 7;
  ColVariable = 8;

function IsIdStart(AChar: Char): Boolean;
begin
  Result := AChar in ['A'..'Z', 'a'..'z', '_'];
end;

function IsIdChar(AChar: Char): Boolean;
begin
  Result := AChar in ['A'..'Z', 'a'..'z', '_', '0'..'9'];
end;

function CiKindText(AKind: TCiKind): string;
begin
  case AKind of
    ckConstant: Result := 'const';
    ckFunction: Result := 'function';
    ckLabel: Result := 'label';
    ckProcedure: Result := 'procedure';
    ckProperty: Result := 'property';
    ckType: Result := 'type';
    ckUnit: Result := 'unit';
    ckVariable: Result := 'var';
  else
    Result := '';
  end;
end;

function CiIsEvent(const ASymbol: TCiSymbol): Boolean;
var
  TypeName: string;
begin
  Result := False;
  if ASymbol.Kind <> ckProperty then
    Exit;
  TypeName := CiTypeOfSymbol(ASymbol);
  if TypeName <> '' then
    Result := LowerCase(Copy(TypeName, Length(TypeName) - 4, 5)) = 'event'
  else
    Result := (Length(ASymbol.Name) > 2) and
              (LowerCase(Copy(ASymbol.Name, 1, 2)) = 'on') and
              (ASymbol.Name[3] in ['A'..'Z']);
end;

function CiColorIndex(const ASymbol: TCiSymbol): Integer;
begin
  if ASymbol.IsAbstract then
  begin
    Result := ColAbstract;
    Exit;
  end;
  case ASymbol.Kind of
    ckConstant: Result := ColConstant;
    ckFunction: Result := ColFunction;
    ckLabel: Result := ColLabel;
    ckProcedure: Result := ColProcedure;
    ckProperty: Result := ColProperty;
    ckType: Result := ColType;
    ckUnit: Result := ColUnit;
  else
    Result := ColVariable;
  end;
end;

// ---------------------------------------------------------------------------
//  Типы из объявлений
// ---------------------------------------------------------------------------

// Первое имя в AText (с точками - последняя часть: Unit.TType - TType);
// ключевые слова, после которых не имя типа, - ''
function FirstTypeName(const AText: string): string;
var
  CharIdx, StartIdx: Integer;
  Low: string;
begin
  Result := '';
  CharIdx := 1;
  while (CharIdx <= Length(AText)) and (AText[CharIdx] = ' ') do
    Inc(CharIdx);
  if (CharIdx > Length(AText)) or not IsIdStart(AText[CharIdx]) then
    Exit;
  repeat
    StartIdx := CharIdx;
    while (CharIdx <= Length(AText)) and IsIdChar(AText[CharIdx]) do
      Inc(CharIdx);
    Result := Copy(AText, StartIdx, CharIdx - StartIdx);
    if (CharIdx < Length(AText)) and (AText[CharIdx] = '.') and
       IsIdStart(AText[CharIdx + 1]) then
      Inc(CharIdx)
    else
      Break;
  until False;
  Low := LowerCase(Result);
  if (Low = 'array') or (Low = 'set') or (Low = 'file') or
     (Low = 'record') or (Low = 'packed') or (Low = 'procedure') or
     (Low = 'function') or (Low = 'class') or (Low = 'object') or
     (Low = 'interface') then
    Result := '';
end;

// Текст после ':' на нулевой вложенности скобок, начиная с AFrom
function AfterColon(const AText: string; AFrom: Integer): string;
var
  CharIdx, Depth: Integer;
begin
  Result := '';
  Depth := 0;
  for CharIdx := AFrom to Length(AText) do
    case AText[CharIdx] of
      '(', '[': Inc(Depth);
      ')', ']': Dec(Depth);
      ':':
        if Depth = 0 then
        begin
          Result := Copy(AText, CharIdx + 1, MaxInt);
          Exit;
        end;
    end;
end;

function CiTypeOfSymbol(const ASymbol: TCiSymbol): string;
var
  TypeText: string;
  EqPos: Integer;
begin
  Result := '';
  case ASymbol.Kind of
    ckVariable, ckConstant, ckProperty, ckFunction:
      begin
        TypeText := AfterColon(ASymbol.Detail, 1);
        EqPos := Pos('=', TypeText);
        if EqPos > 0 then
          SetLength(TypeText, EqPos - 1);
        Result := FirstTypeName(TypeText);
      end;
  end;
end;

function CiIsStructType(const ADetail: string): Boolean;
var
  Low: string;
begin
  Low := LowerCase(Trim(ADetail));
  if Copy(Low, 1, 7) = 'packed ' then
    Low := Trim(Copy(Low, 8, MaxInt));
  Result := ((Copy(Low, 1, 5) = 'class') and (Copy(Low, 1, 8) <> 'class of')) or
            (Copy(Low, 1, 6) = 'record') or (Copy(Low, 1, 6) = 'object') or
            (Copy(Low, 1, 9) = 'interface') or
            (Copy(Low, 1, 13) = 'dispinterface');
end;

function CiParentType(const ADetail: string): string;
var
  Low: string;
  ParenPos: Integer;
begin
  Result := '';
  Low := LowerCase(Trim(ADetail));
  if not ((Copy(Low, 1, 5) = 'class') or (Copy(Low, 1, 6) = 'object') or
          (Copy(Low, 1, 9) = 'interface')) then
    Exit;
  ParenPos := Pos('(', ADetail);
  if ParenPos > 0 then
    Result := FirstTypeName(Copy(ADetail, ParenPos + 1, MaxInt))
  else if Copy(Low, 1, 5) = 'class' then
    Result := 'TObject';
end;

function CiAliasType(const ADetail: string): string;
var
  Text: string;
begin
  Text := Trim(ADetail);
  if LowerCase(Copy(Text, 1, 5)) = 'type ' then
    Text := Trim(Copy(Text, 6, MaxInt));
  Result := FirstTypeName(Text);
end;

function CiParamType(const ADetail, AName: string): string;
var
  Inner, Group, NamesPart: string;
  OpenPos, CloseIdx, Depth, SemiPos, ColonPos, CharIdx: Integer;
begin
  Result := '';
  OpenPos := Pos('(', ADetail);
  if OpenPos = 0 then
    Exit;
  Depth := 0;
  CloseIdx := Length(ADetail);
  for CharIdx := OpenPos to Length(ADetail) do
  begin
    if ADetail[CharIdx] = '(' then
      Inc(Depth)
    else if ADetail[CharIdx] = ')' then
    begin
      Dec(Depth);
      if Depth = 0 then
      begin
        CloseIdx := CharIdx;
        Break;
      end;
    end;
  end;
  Inner := Copy(ADetail, OpenPos + 1, CloseIdx - OpenPos - 1);
  while Inner <> '' do
  begin
    SemiPos := Pos(';', Inner);
    if SemiPos = 0 then
      SemiPos := Length(Inner) + 1;
    Group := Trim(Copy(Inner, 1, SemiPos - 1));
    Delete(Inner, 1, SemiPos);
    ColonPos := Pos(':', Group);
    if ColonPos = 0 then
      Continue;
    // const, var, out перед именами - тоже слова, имя ищется среди слов
    NamesPart := ' ' + StringReplace(Copy(Group, 1, ColonPos - 1), ',', ' ',
                                     [rfReplaceAll]) + ' ';
    if Pos(' ' + LowerCase(AName) + ' ', LowerCase(NamesPart)) > 0 then
    begin
      Group := Copy(Group, ColonPos + 1, MaxInt);
      if Pos('=', Group) > 0 then
        SetLength(Group, Pos('=', Group) - 1);
      Result := FirstTypeName(Group);
      Exit;
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  TCiSymbols
// ---------------------------------------------------------------------------

function TCiSymbols.GetItem(AIndex: Integer): TCiSymbol;
begin
  Result := FItems[AIndex];
end;

procedure TCiSymbols.Clear;
begin
  FItems := nil;
  FCount := 0;
end;

procedure TCiSymbols.Add(const ASymbol: TCiSymbol);
begin
  if ASymbol.Name = '' then
    Exit;
  if FCount = Length(FItems) then
    SetLength(FItems, FCount * 2 + 64);
  FItems[FCount] := ASymbol;
  Inc(FCount);
end;

procedure TCiSymbols.AddAll(ASource: TCiSymbols);
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to ASource.Count - 1 do
    Add(ASource.FItems[ItemIdx]);
end;

procedure TCiSymbols.SetDetail(AIndex: Integer; const ADetail: string);
begin
  FItems[AIndex].Detail := ADetail;
end;

procedure TCiSymbols.SortUnique;
var
  Keys: TStringList;
  ItemIdx, KeyIdx: Integer;
  Sorted: TCiSymbolArray;
  Key: string;
begin
  Keys := TStringList.Create;
  try
    Keys.Sorted := True;
    Keys.Duplicates := dupIgnore;
    Keys.CaseSensitive := False;
    for ItemIdx := 0 to FCount - 1 do
    begin
      // Вид - после имени: одноимённые разных видов остаются оба
      Key := FItems[ItemIdx].Name + #1 + IntToStr(Ord(FItems[ItemIdx].Kind));
      if Keys.IndexOf(Key) < 0 then
        Keys.AddObject(Key, TObject(ItemIdx));
    end;
    SetLength(Sorted, Keys.Count);
    for KeyIdx := 0 to Keys.Count - 1 do
      Sorted[KeyIdx] := FItems[Integer(Keys.Objects[KeyIdx])];
    FItems := Sorted;
    FCount := Keys.Count;
  finally
    Keys.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Очистка и слова
// ---------------------------------------------------------------------------

procedure CiCleanLines(ASrc, AClean: TStrings);
var
  LineIdx, CharIdx: Integer;
  Line, Clean: string;
  InBrace, InStar: Boolean;
begin
  AClean.Clear;
  InBrace := False;
  InStar := False;
  for LineIdx := 0 to ASrc.Count - 1 do
  begin
    Line := ASrc[LineIdx];
    Clean := Line;
    CharIdx := 1;
    while CharIdx <= Length(Line) do
    begin
      if InBrace then
      begin
        if Line[CharIdx] = '}' then
          InBrace := False;
        Clean[CharIdx] := ' ';
        Inc(CharIdx);
        Continue;
      end;
      if InStar then
      begin
        if (Line[CharIdx] = '*') and (CharIdx < Length(Line)) and
           (Line[CharIdx + 1] = ')') then
        begin
          InStar := False;
          Clean[CharIdx] := ' ';
          Clean[CharIdx + 1] := ' ';
          Inc(CharIdx, 2);
          Continue;
        end;
        Clean[CharIdx] := ' ';
        Inc(CharIdx);
        Continue;
      end;
      case Line[CharIdx] of
        '{':
          begin
            InBrace := True;
            Clean[CharIdx] := ' ';
          end;
        '(':
          if (CharIdx < Length(Line)) and (Line[CharIdx + 1] = '*') then
          begin
            InStar := True;
            Clean[CharIdx] := ' ';
            Clean[CharIdx + 1] := ' ';
            Inc(CharIdx);
          end;
        '/':
          if (CharIdx < Length(Line)) and (Line[CharIdx + 1] = '/') then
          begin
            while CharIdx <= Length(Line) do
            begin
              Clean[CharIdx] := ' ';
              Inc(CharIdx);
            end;
            Break;
          end;
        '''':
          begin
            // Строка - до закрывающей кавычки ('' внутри - кавычка)
            Clean[CharIdx] := ' ';
            Inc(CharIdx);
            while CharIdx <= Length(Line) do
            begin
              if Line[CharIdx] = '''' then
              begin
                if (CharIdx < Length(Line)) and (Line[CharIdx + 1] = '''') then
                begin
                  Clean[CharIdx] := ' ';
                  Clean[CharIdx + 1] := ' ';
                  Inc(CharIdx, 2);
                  Continue;
                end;
                Clean[CharIdx] := ' ';
                Break;
              end;
              Clean[CharIdx] := ' ';
              Inc(CharIdx);
            end;
          end;
      end;
      Inc(CharIdx);
    end;
    AClean.Add(Clean);
  end;
end;

type
  TCiToken = record
    Text: string;      // как в тексте
    Low: string;       // строчными - для сравнения
    Line: Integer;
    Col: Integer;      // от 1
  end;

  TCiTokens = class
  public
    Items: array of TCiToken;
    Count: Integer;
    procedure Add(const AText: string; ALine, ACol: Integer);
  end;

procedure TCiTokens.Add(const AText: string; ALine, ACol: Integer);
begin
  if Count = Length(Items) then
    SetLength(Items, Count * 2 + 256);
  Items[Count].Text := AText;
  Items[Count].Low := LowerCase(AText);
  Items[Count].Line := ALine;
  Items[Count].Col := ACol;
  Inc(Count);
end;

// Слова и знаки очищенного текста. Числа - словами, ':=' и '..' - одним
// знаком каждое.
procedure Tokenize(AClean: TStrings; ATokens: TCiTokens);
var
  LineIdx, CharIdx, StartIdx: Integer;
  Line: string;
begin
  for LineIdx := 0 to AClean.Count - 1 do
  begin
    Line := AClean[LineIdx];
    CharIdx := 1;
    while CharIdx <= Length(Line) do
    begin
      if Line[CharIdx] <= ' ' then
      begin
        Inc(CharIdx);
        Continue;
      end;
      StartIdx := CharIdx;
      if IsIdChar(Line[CharIdx]) or (Line[CharIdx] in ['$', '#']) then
      begin
        Inc(CharIdx);
        while (CharIdx <= Length(Line)) and IsIdChar(Line[CharIdx]) do
          Inc(CharIdx);
      end
      else if (Line[CharIdx] = ':') and (CharIdx < Length(Line)) and
              (Line[CharIdx + 1] = '=') then
        Inc(CharIdx, 2)
      else if (Line[CharIdx] = '.') and (CharIdx < Length(Line)) and
              (Line[CharIdx + 1] = '.') then
        Inc(CharIdx, 2)
      else
        Inc(CharIdx);
      ATokens.Add(Copy(Line, StartIdx, CharIdx - StartIdx), LineIdx,
                  StartIdx);
    end;
  end;
end;

procedure CiScanWords(ASrc: TStrings; ASymbols: TCiSymbols);
var
  LineIdx, CharIdx, StartIdx: Integer;
  Line: string;
  Symbol: TCiSymbol;
begin
  Symbol.Kind := ckWord;
  Symbol.Detail := '';
  Symbol.IsAbstract := False;
  Symbol.Owner := '';
  Symbol.Visibility := cvPublic;
  for LineIdx := 0 to ASrc.Count - 1 do
  begin
    Line := ASrc[LineIdx];
    CharIdx := 1;
    while CharIdx <= Length(Line) do
    begin
      if not IsIdStart(Line[CharIdx]) then
      begin
        // Число и хвост слова с цифрами - не начало имени
        while (CharIdx <= Length(Line)) and IsIdChar(Line[CharIdx]) do
          Inc(CharIdx);
        Inc(CharIdx);
        Continue;
      end;
      StartIdx := CharIdx;
      while (CharIdx <= Length(Line)) and IsIdChar(Line[CharIdx]) do
        Inc(CharIdx);
      if CharIdx - StartIdx >= 3 then
      begin
        Symbol.Name := Copy(Line, StartIdx, CharIdx - StartIdx);
        Symbol.Line := LineIdx;
        ASymbols.Add(Symbol);
      end;
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Разбор Pascal
// ---------------------------------------------------------------------------

type
  TCiSection = (secNone, secUses, secConst, secType, secVar, secLabel);

  TCiParser = class
  private
    FSrc: TStrings;
    FTok: TCiTokens;
    FPos: Integer;
    FSyms: TCiSymbols;
    FSection: TCiSection;
    FBodyDepth: Integer;     // вложенность class/record/object в type
    FOwners: TStringList;    // чьи члены сейчас: стек имён по FBodyDepth
                             // (Objects - текущая видимость, TCiVisibility)
    function Tok(AOffset: Integer): string;   // строчными; '' - конец
    function IsId(AIndex: Integer): Boolean;
    function SourceText(AFrom, ATo: Integer): string;
    function SkipToSemicolon: Integer;
    procedure AddSym(const AName: string; AKind: TCiKind;
                     const ADetail: string; ALine: Integer;
                     AAbstract: Boolean; const AOwner: string = #0);
    procedure SkipCodeBlock;
    procedure ParseRoutine;
    procedure ParseProperty;
    procedure ParseUses;
    procedure ParseTypeEntry;
    procedure ParseNameList(AKind: TCiKind);
    procedure ParseConstEntry;
  public
    constructor Create(ASrc: TStrings; ATokens: TCiTokens;
                       ASymbols: TCiSymbols);
    destructor Destroy; override;
    procedure Run(AInterfaceOnly: Boolean);
  end;

const
  RoutineDirectives: array[0..23] of string = (
    'virtual', 'dynamic', 'abstract', 'override', 'overload', 'reintroduce',
    'stdcall', 'cdecl', 'pascal', 'register', 'safecall', 'inline',
    'static', 'message', 'external', 'forward', 'assembler', 'deprecated',
    'platform', 'export', 'far', 'near', 'final', 'varargs');

function IsDirective(const AWord: string): Boolean;
var
  WordIdx: Integer;
begin
  Result := True;
  for WordIdx := Low(RoutineDirectives) to High(RoutineDirectives) do
    if RoutineDirectives[WordIdx] = AWord then
      Exit;
  Result := False;
end;

constructor TCiParser.Create(ASrc: TStrings; ATokens: TCiTokens;
                             ASymbols: TCiSymbols);
begin
  inherited Create;
  FSrc := ASrc;
  FTok := ATokens;
  FSyms := ASymbols;
  FOwners := TStringList.Create;
end;

destructor TCiParser.Destroy;
begin
  FOwners.Free;
  inherited Destroy;
end;

function TCiParser.Tok(AOffset: Integer): string;
begin
  if (FPos + AOffset >= 0) and (FPos + AOffset < FTok.Count) then
    Result := FTok.Items[FPos + AOffset].Low
  else
    Result := '';
end;

function TCiParser.IsId(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FTok.Count) and
            IsIdStart(FTok.Items[AIndex].Text[1]);
end;

// Текст исходника от начала слова AFrom до конца слова ATo, переводы
// строк - пробелами, лишние пробелы убраны
function TCiParser.SourceText(AFrom, ATo: Integer): string;
var
  LineIdx, FromCol, ToCol: Integer;
  Part: string;
begin
  Result := '';
  if (AFrom < 0) or (ATo >= FTok.Count) or (AFrom > ATo) then
    Exit;
  for LineIdx := FTok.Items[AFrom].Line to FTok.Items[ATo].Line do
  begin
    if LineIdx >= FSrc.Count then
      Break;
    FromCol := 1;
    ToCol := Length(FSrc[LineIdx]);
    if LineIdx = FTok.Items[AFrom].Line then
      FromCol := FTok.Items[AFrom].Col;
    if LineIdx = FTok.Items[ATo].Line then
      ToCol := FTok.Items[ATo].Col + Length(FTok.Items[ATo].Text) - 1;
    Part := Trim(Copy(FSrc[LineIdx], FromCol, ToCol - FromCol + 1));
    if Part = '' then
      Continue;
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + Part;
  end;
  Result := StringReplace(Result, #9, ' ', [rfReplaceAll]);
  if Length(Result) > 200 then
    Result := Copy(Result, 1, 197) + '...';
end;

// До ';' на нулевой вложенности скобок; FPos - на ';'. Результат - номер
// слова перед ';'.
function TCiParser.SkipToSemicolon: Integer;
var
  Depth: Integer;
begin
  Depth := 0;
  while FPos < FTok.Count do
  begin
    if (Tok(0) = '(') or (Tok(0) = '[') then
      Inc(Depth)
    else if ((Tok(0) = ')') or (Tok(0) = ']')) and (Depth > 0) then
      Dec(Depth)
    else if (Tok(0) = ';') and (Depth = 0) then
      Break;
    Inc(FPos);
  end;
  Result := FPos - 1;
end;

// AOwner = #0 - чей член, решает стек FOwners
procedure TCiParser.AddSym(const AName: string; AKind: TCiKind;
  const ADetail: string; ALine: Integer; AAbstract: Boolean;
  const AOwner: string);
var
  Symbol: TCiSymbol;
begin
  Symbol.Name := AName;
  Symbol.Kind := AKind;
  Symbol.Detail := ADetail;
  Symbol.Line := ALine;
  Symbol.IsAbstract := AAbstract;
  if AOwner <> #0 then
    Symbol.Owner := AOwner
  else if (FBodyDepth > 0) and (FOwners.Count > 0) then
    Symbol.Owner := FOwners[FOwners.Count - 1]
  else
    Symbol.Owner := '';
  Symbol.Visibility := cvPublic;
  if (FBodyDepth > 0) and (FOwners.Count > 0) then
    Symbol.Visibility :=
      TCiVisibility(Integer(FOwners.Objects[FOwners.Count - 1]));
  FSyms.Add(Symbol);
end;

// begin ... end, try ... end, case ... end, asm ... end - пропустить
procedure TCiParser.SkipCodeBlock;
var
  Depth: Integer;
  TokWord: string;
begin
  Depth := 0;
  while FPos < FTok.Count do
  begin
    TokWord := Tok(0);
    if (TokWord = 'begin') or (TokWord = 'try') or (TokWord = 'case') or
       (TokWord = 'asm') then
      Inc(Depth)
    else if TokWord = 'end' then
    begin
      Dec(Depth);
      if Depth <= 0 then
      begin
        Inc(FPos);
        Exit;
      end;
    end;
    Inc(FPos);
  end;
end;

// procedure / function / constructor / destructor Имя[.Имя](...)[: T];
// директивы
procedure TCiParser.ParseRoutine;
var
  IsFunc, IsAbstract: Boolean;
  Name, Detail, Owner: string;
  NameLine, DetailFrom, DetailTo, Depth: Integer;
begin
  IsFunc := Tok(0) = 'function';
  Inc(FPos);
  if not IsId(FPos) then
    Exit;
  Name := FTok.Items[FPos].Text;
  NameLine := FTok.Items[FPos].Line;
  Inc(FPos);
  // Имя метода с классом: TForm1.Foo - имя Foo, класс TForm1
  Owner := #0;
  while (Tok(0) = '.') and IsId(FPos + 1) do
  begin
    Owner := Name;
    Name := FTok.Items[FPos + 1].Text;
    Inc(FPos, 2);
  end;
  DetailFrom := FPos;
  DetailTo := FPos - 1;
  if Tok(0) = '(' then
  begin
    Depth := 0;
    while FPos < FTok.Count do
    begin
      if Tok(0) = '(' then
        Inc(Depth)
      else if Tok(0) = ')' then
      begin
        Dec(Depth);
        if Depth = 0 then
          Break;
      end;
      Inc(FPos);
    end;
    DetailTo := FPos;
    Inc(FPos);
  end;
  if Tok(0) = ':' then
  begin
    // Тип результата - до ';'
    DetailTo := SkipToSemicolon;
  end;
  Detail := '';
  if DetailTo >= DetailFrom then
    Detail := SourceText(DetailFrom, DetailTo);
  if Tok(0) = ';' then
    Inc(FPos);
  // Директивы: virtual; abstract; overload; message WM_X; ...
  IsAbstract := False;
  while (FPos < FTok.Count) and IsDirective(Tok(0)) do
  begin
    if Tok(0) = 'abstract' then
      IsAbstract := True;
    SkipToSemicolon;
    if Tok(0) = ';' then
      Inc(FPos);
  end;
  if IsFunc then
    AddSym(Name, ckFunction, Detail, NameLine, IsAbstract, Owner)
  else
    AddSym(Name, ckProcedure, Detail, NameLine, IsAbstract, Owner);
end;

procedure TCiParser.ParseProperty;
var
  Name, Detail: string;
  NameLine, DetailFrom, DetailTo: Integer;
begin
  Inc(FPos);
  if not IsId(FPos) then
    Exit;
  Name := FTok.Items[FPos].Text;
  NameLine := FTok.Items[FPos].Line;
  Inc(FPos);
  DetailFrom := FPos;
  DetailTo := FPos - 1;
  // [Index: Integer]: Type - до read/write/default/... или ';'
  while (FPos < FTok.Count) and (Tok(0) <> ';') and (Tok(0) <> 'read') and
        (Tok(0) <> 'write') and (Tok(0) <> 'index') and
        (Tok(0) <> 'default') and (Tok(0) <> 'stored') and
        (Tok(0) <> 'nodefault') and (Tok(0) <> 'implements') do
  begin
    DetailTo := FPos;
    Inc(FPos);
  end;
  Detail := '';
  if DetailTo >= DetailFrom then
    Detail := SourceText(DetailFrom, DetailTo);
  SkipToSemicolon;
  if Tok(0) = ';' then
    Inc(FPos);
  // default; после ';' у свойства-массива
  if Tok(0) = 'default' then
  begin
    SkipToSemicolon;
    if Tok(0) = ';' then
      Inc(FPos);
  end;
  AddSym(Name, ckProperty, Detail, NameLine, False);
end;

procedure TCiParser.ParseUses;
begin
  Inc(FPos);
  while (FPos < FTok.Count) and (Tok(0) <> ';') do
  begin
    if IsId(FPos) and (Tok(0) <> 'in') then
    begin
      // Unit.Name - имя с точками
      AddSym(FTok.Items[FPos].Text, ckUnit, '', FTok.Items[FPos].Line,
             False);
    end;
    if Tok(0) = 'in' then
    begin
      // in 'file.pas' - строка очищена; дальше ',' или ';'
      while (FPos < FTok.Count) and (Tok(0) <> ',') and (Tok(0) <> ';') do
        Inc(FPos);
      Continue;
    end;
    Inc(FPos);
  end;
  if Tok(0) = ';' then
    Inc(FPos);
end;

// Имя = ... в разделе type. Класс, запись, объект, интерфейс с телом -
// внутрь (FBodyDepth), их поля - переменные.
procedure TCiParser.ParseTypeEntry;
var
  Name: string;
  NameLine, DetailFrom, ScanPos: Integer;
  Kind: string;
  HasBody: Boolean;
begin
  Name := FTok.Items[FPos].Text;
  NameLine := FTok.Items[FPos].Line;
  Inc(FPos, 2);   // имя и '='
  DetailFrom := FPos;
  ScanPos := FPos;
  if (ScanPos < FTok.Count) and (FTok.Items[ScanPos].Low = 'packed') then
    Inc(ScanPos);
  Kind := '';
  if ScanPos < FTok.Count then
    Kind := FTok.Items[ScanPos].Low;
  HasBody := False;
  if (Kind = 'class') or (Kind = 'object') or (Kind = 'interface') or
     (Kind = 'dispinterface') then
  begin
    FPos := ScanPos + 1;
    // class of TX; - ссылка на класс, не тело
    if Tok(0) = 'of' then
    begin
      SkipToSemicolon;
      AddSym(Name, ckType, SourceText(DetailFrom, FPos - 1), NameLine, False);
      Inc(FPos);
      Exit;
    end;
    // (TParent, IIntf)
    if Tok(0) = '(' then
    begin
      while (FPos < FTok.Count) and (Tok(0) <> ')') do
        Inc(FPos);
      Inc(FPos);
    end;
    // ['{GUID}'] у интерфейса - строка очищена, остаются скобки
    if Tok(0) = '[' then
    begin
      while (FPos < FTok.Count) and (Tok(0) <> ']') do
        Inc(FPos);
      Inc(FPos);
    end;
    AddSym(Name, ckType, SourceText(DetailFrom, FPos - 1), NameLine, False);
    // TX = class; или class(TY); - объявление без тела
    if Tok(0) = ';' then
    begin
      Inc(FPos);
      Exit;
    end;
    HasBody := True;
  end
  else if Kind = 'record' then
  begin
    FPos := ScanPos + 1;
    AddSym(Name, ckType, SourceText(DetailFrom, ScanPos), NameLine, False);
    HasBody := True;
  end;
  if HasBody then
  begin
    Inc(FBodyDepth);
    FOwners.AddObject(Name, TObject(Ord(cvPublic)));
    Exit;
  end;
  // Остальное: Name = Integer; Name = (a, b); Name = procedure of object;
  SkipToSemicolon;
  AddSym(Name, ckType, SourceText(DetailFrom, FPos - 1), NameLine, False);
  // Перечисление: его значения - константы
  if (DetailFrom < FTok.Count) and (FTok.Items[DetailFrom].Low = '(') then
  begin
    ScanPos := DetailFrom + 1;
    while ScanPos < FPos do
    begin
      if IsId(ScanPos) and (ScanPos + 1 < FTok.Count) and
         ((FTok.Items[ScanPos + 1].Low = ',') or
          (FTok.Items[ScanPos + 1].Low = ')') or
          (FTok.Items[ScanPos + 1].Low = '=')) then
        AddSym(FTok.Items[ScanPos].Text, ckConstant, Name,
               FTok.Items[ScanPos].Line, False);
      Inc(ScanPos);
    end;
  end;
  if Tok(0) = ';' then
    Inc(FPos);
end;

// A, B, C: Тип; - переменные (поля) или метки
procedure TCiParser.ParseNameList(AKind: TCiKind);
var
  Names: TStringList;
  NameIdx, DetailFrom: Integer;
  Detail: string;
begin
  Names := TStringList.Create;
  try
    while (FPos < FTok.Count) and IsId(FPos) do
    begin
      Names.AddObject(FTok.Items[FPos].Text,
                      TObject(FTok.Items[FPos].Line));
      Inc(FPos);
      if Tok(0) = ',' then
        Inc(FPos)
      else
        Break;
    end;
    Detail := '';
    if Tok(0) = ':' then
    begin
      DetailFrom := FPos;
      SkipToSemicolon;
      Detail := SourceText(DetailFrom, FPos - 1);
    end
    else
      SkipToSemicolon;
    if Tok(0) = ';' then
      Inc(FPos);
    for NameIdx := 0 to Names.Count - 1 do
      AddSym(Names[NameIdx], AKind, Detail,
             Integer(Names.Objects[NameIdx]), False);
  finally
    Names.Free;
  end;
end;

// Name = значение; или Name: Тип = значение;
procedure TCiParser.ParseConstEntry;
var
  Name: string;
  NameLine, DetailFrom: Integer;
begin
  Name := FTok.Items[FPos].Text;
  NameLine := FTok.Items[FPos].Line;
  Inc(FPos);
  DetailFrom := FPos;
  SkipToSemicolon;
  AddSym(Name, ckConstant, SourceText(DetailFrom, FPos - 1), NameLine, False);
  if Tok(0) = ';' then
    Inc(FPos);
end;

procedure TCiParser.Run(AInterfaceOnly: Boolean);
var
  TokWord: string;
  StartPos: Integer;
begin
  FPos := 0;
  FSection := secNone;
  FBodyDepth := 0;
  while FPos < FTok.Count do
  begin
    StartPos := FPos;
    TokWord := Tok(0);

    // Тело класса или записи
    if FBodyDepth > 0 then
    begin
      if TokWord = 'end' then
      begin
        Dec(FBodyDepth);
        if FOwners.Count > 0 then
          FOwners.Delete(FOwners.Count - 1);
        Inc(FPos);
        if Tok(0) = ';' then
          Inc(FPos);
      end
      else if (TokWord = 'procedure') or (TokWord = 'function') or
              (TokWord = 'constructor') or (TokWord = 'destructor') then
        ParseRoutine
      else if TokWord = 'property' then
        ParseProperty
      else if (TokWord = 'record') or (TokWord = 'case') then
      begin
        // Вложенная запись или вариантная часть: 'case' закрывается тем же
        // 'end', что и запись, - пропуск до ')' вариантов не нужен
        // Вложенная запись: её поля - члены того же класса; у 'case'
        // своего 'end' нет - стек не растёт
        if TokWord = 'record' then
        begin
          Inc(FBodyDepth);
          FOwners.AddObject(FOwners[FOwners.Count - 1],
                            FOwners.Objects[FOwners.Count - 1]);
        end;
        Inc(FPos);
        if TokWord = 'case' then
          SkipToSemicolon;
      end
      else if (TokWord = 'private') or (TokWord = 'protected') or
              (TokWord = 'public') or (TokWord = 'published') or
              (TokWord = 'automated') then
      begin
        if FOwners.Count > 0 then
        begin
          if TokWord = 'private' then
            FOwners.Objects[FOwners.Count - 1] := TObject(Ord(cvPrivate))
          else if TokWord = 'protected' then
            FOwners.Objects[FOwners.Count - 1] := TObject(Ord(cvProtected))
          else if TokWord = 'published' then
            FOwners.Objects[FOwners.Count - 1] := TObject(Ord(cvPublished))
          else
            FOwners.Objects[FOwners.Count - 1] := TObject(Ord(cvPublic));
        end;
        Inc(FPos);
      end
      else if (TokWord = 'strict') or (TokWord = 'class') or
              (TokWord = 'var') or (TokWord = 'const') or
              (TokWord = 'type') then
        Inc(FPos)
      else if IsId(FPos) and ((Tok(1) = ':') or (Tok(1) = ',')) then
        ParseNameList(ckVariable)
      else
        Inc(FPos);
      if FPos = StartPos then
        Inc(FPos);
      Continue;
    end;

    if (TokWord = 'implementation') and AInterfaceOnly then
      Break;

    if (TokWord = 'unit') or (TokWord = 'program') or (TokWord = 'library') or
       (TokWord = 'package') then
    begin
      SkipToSemicolon;
      Inc(FPos);
      FSection := secNone;
    end
    else if (TokWord = 'uses') or (TokWord = 'contains') then
    begin
      ParseUses;
      FSection := secNone;
    end
    else if (TokWord = 'const') or (TokWord = 'resourcestring') then
    begin
      FSection := secConst;
      Inc(FPos);
    end
    else if TokWord = 'type' then
    begin
      FSection := secType;
      Inc(FPos);
    end
    else if (TokWord = 'var') or (TokWord = 'threadvar') then
    begin
      FSection := secVar;
      Inc(FPos);
    end
    else if TokWord = 'label' then
    begin
      Inc(FPos);
      ParseNameList(ckLabel);
      FSection := secNone;
    end
    else if (TokWord = 'interface') or (TokWord = 'implementation') or
            (TokWord = 'initialization') or (TokWord = 'finalization') then
    begin
      FSection := secNone;
      Inc(FPos);
    end
    else if (TokWord = 'begin') or (TokWord = 'asm') then
    begin
      SkipCodeBlock;
      FSection := secNone;
    end
    else if (TokWord = 'procedure') or (TokWord = 'function') or
            (TokWord = 'constructor') or (TokWord = 'destructor') then
    begin
      // Тип "procedure of object" в разделе type разбирает ParseTypeEntry
      ParseRoutine;
      FSection := secNone;
    end
    else if (TokWord = 'class') and ((Tok(1) = 'procedure') or
                                  (Tok(1) = 'function')) then
      Inc(FPos)
    else if TokWord = 'property' then
      ParseProperty
    else if (FSection = secType) and IsId(FPos) and (Tok(1) = '=') then
      ParseTypeEntry
    else if (FSection = secConst) and IsId(FPos) and
            ((Tok(1) = '=') or (Tok(1) = ':')) then
      ParseConstEntry
    else if (FSection = secVar) and IsId(FPos) and
            ((Tok(1) = ':') or (Tok(1) = ',')) then
      ParseNameList(ckVariable)
    else
      Inc(FPos);

    if FPos = StartPos then
      Inc(FPos);
  end;
end;

procedure CiScanPascal(ASrc: TStrings; AInterfaceOnly: Boolean;
                       ASymbols: TCiSymbols);
var
  Clean: TStringList;
  Tokens: TCiTokens;
  Parser: TCiParser;
begin
  Clean := TStringList.Create;
  Tokens := TCiTokens.Create;
  try
    CiCleanLines(ASrc, Clean);
    Tokenize(Clean, Tokens);
    Parser := TCiParser.Create(ASrc, Tokens, ASymbols);
    try
      Parser.Run(AInterfaceOnly);
    finally
      Parser.Free;
    end;
  finally
    Tokens.Free;
    Clean.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  TCiListPopup
// ---------------------------------------------------------------------------

const
  PopupMaxRows = 12;
  PopupWidth = 520;

constructor TCiListPopup.Create(AOwner: TComponent);
var
  ColorIdx: Integer;
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  for ColorIdx := 0 to 8 do
    KindColors[ColorIdx] := clWindowText;
  BackColor := clWindow;
  TextColor := clWindowText;
  FRowHeight := 16;
  FRows := PopupMaxRows;
  Visible := False;
end;

procedure TCiListPopup.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP or WS_BORDER;
  Params.ExStyle := WS_EX_TOOLWINDOW or WS_EX_TOPMOST;
  Params.WndParent := 0;
end;

procedure TCiListPopup.WMMouseActivate(var Message: TMessage);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TCiListPopup.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TCiListPopup.SetSymbols(ASymbols: TCiSymbols);
begin
  FAll := ASymbols;
  FShownCount := 0;
  FTop := 0;
  FSel := 0;
end;

function TCiListPopup.ApplyFilter(const APrefix: string): Integer;
var
  ItemIdx, PrefixLen: Integer;
  Prefix: string;
begin
  FShownCount := 0;
  FTop := 0;
  FSel := 0;
  if FAll = nil then
  begin
    Result := 0;
    Exit;
  end;
  SetLength(FShown, FAll.Count);
  Prefix := LowerCase(APrefix);
  PrefixLen := Length(Prefix);
  for ItemIdx := 0 to FAll.Count - 1 do
    if (PrefixLen = 0) or
       (LowerCase(Copy(FAll[ItemIdx].Name, 1, PrefixLen)) = Prefix) then
    begin
      FShown[FShownCount] := ItemIdx;
      Inc(FShownCount);
    end;
  Result := FShownCount;
  if HandleAllocated and IsShown then
    Invalidate;
end;

procedure TCiListPopup.EnsureSelVisible;
begin
  if FSel < FTop then
    FTop := FSel;
  if FSel >= FTop + FRows then
    FTop := FSel - FRows + 1;
  if FTop < 0 then
    FTop := 0;
end;

procedure TCiListPopup.MoveSel(ADelta: Integer);
begin
  if FShownCount = 0 then
    Exit;
  Inc(FSel, ADelta);
  if FSel < 0 then
    FSel := 0;
  if FSel > FShownCount - 1 then
    FSel := FShownCount - 1;
  EnsureSelVisible;
  Invalidate;
end;

function TCiListPopup.SelectedName: string;
begin
  Result := '';
  if (FAll <> nil) and (FSel >= 0) and (FSel < FShownCount) then
    Result := FAll[FShown[FSel]].Name;
end;

procedure TCiListPopup.MeasureRows;
var
  ScreenDC: HDC;
  OldFont: HFONT;
  TextSize: TSize;
  KindIdx: TCiKind;
  KindText: string;
begin
  Canvas.Font.Name := 'Tahoma';
  Canvas.Font.Height := -12;
  FRowHeight := 16;
  FKindWidth := 60;
  ScreenDC := GetDC(0);
  try
    OldFont := SelectObject(ScreenDC, Canvas.Font.Handle);
    if GetTextExtentPoint32(ScreenDC, 'Wg', 2, TextSize) then
      FRowHeight := TextSize.cy + 3;
    for KindIdx := Low(TCiKind) to High(TCiKind) do
    begin
      KindText := CiKindText(KindIdx);
      if (KindText <> '') and
         GetTextExtentPoint32(ScreenDC, PChar(KindText), Length(KindText),
                              TextSize) and (TextSize.cx + 12 > FKindWidth) then
        FKindWidth := TextSize.cx + 12;
    end;
    SelectObject(ScreenDC, OldFont);
  finally
    ReleaseDC(0, ScreenDC);
  end;
end;

procedure TCiListPopup.ShowAt(AX, AY, ALineTop: Integer);
var
  PopupHeight, WorkBottom, PosY: Integer;
  WorkRect: TRect;
begin
  HandleNeeded;
  MeasureRows;
  FRows := FShownCount;
  if FRows > PopupMaxRows then
    FRows := PopupMaxRows;
  if FRows < 1 then
    FRows := 1;
  EnsureSelVisible;
  PopupHeight := FRows * FRowHeight + 2;
  SystemParametersInfo(SPI_GETWORKAREA, 0, @WorkRect, 0);
  WorkBottom := WorkRect.Bottom;
  PosY := AY;
  if (PosY + PopupHeight > WorkBottom) and (ALineTop - PopupHeight > 0) then
    PosY := ALineTop - PopupHeight;
  if AX + PopupWidth > WorkRect.Right then
    AX := WorkRect.Right - PopupWidth;
  if AX < WorkRect.Left then
    AX := WorkRect.Left;
  SetWindowPos(Handle, HWND_TOPMOST, AX, PosY, PopupWidth, PopupHeight,
               SWP_NOACTIVATE or SWP_SHOWWINDOW);
  Invalidate;
end;

procedure TCiListPopup.HidePopup;
begin
  if HandleAllocated then
    ShowWindow(Handle, SW_HIDE);
end;

function TCiListPopup.IsShown: Boolean;
begin
  Result := HandleAllocated and IsWindowVisible(Handle);
end;

procedure TCiListPopup.Paint;
var
  RowIdx, ItemIdx, TextX: Integer;
  RowRect, TextRect: TRect;
  Symbol: TCiSymbol;
  IsSel: Boolean;
  KindText: string;
begin
  Canvas.Font.Name := 'Tahoma';
  Canvas.Font.Height := -12;
  Canvas.Brush.Color := BackColor;
  Canvas.FillRect(ClientRect);
  if FAll = nil then
    Exit;
  for RowIdx := 0 to FRows - 1 do
  begin
    ItemIdx := FTop + RowIdx;
    if ItemIdx >= FShownCount then
      Break;
    Symbol := FAll[FShown[ItemIdx]];
    RowRect := Rect(0, RowIdx * FRowHeight, ClientWidth,
                    (RowIdx + 1) * FRowHeight);
    IsSel := ItemIdx = FSel;
    if IsSel then
    begin
      Canvas.Brush.Color := clHighlight;
      Canvas.FillRect(RowRect);
    end
    else
      Canvas.Brush.Color := BackColor;
    Canvas.Brush.Style := bsClear;

    // Вид - своим цветом, имя - жирным, дальше параметры или тип
    if CiIsEvent(Symbol) then
      KindText := 'event'
    else
      KindText := CiKindText(Symbol.Kind);
    TextRect := RowRect;
    TextRect.Left := 4;
    if IsSel then
      Canvas.Font.Color := clHighlightText
    else
      Canvas.Font.Color := KindColors[CiColorIndex(Symbol)];
    Canvas.Font.Style := [];
    DrawText(Canvas.Handle, PChar(KindText), Length(KindText), TextRect,
             DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX);

    TextX := 4 + FKindWidth;
    TextRect.Left := TextX;
    if IsSel then
      Canvas.Font.Color := clHighlightText
    else
      Canvas.Font.Color := TextColor;
    Canvas.Font.Style := [fsBold];
    DrawText(Canvas.Handle, PChar(Symbol.Name), Length(Symbol.Name), TextRect,
             DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX);
    Inc(TextX, Canvas.TextWidth(Symbol.Name) + 2);
    Canvas.Font.Style := [];
    if Symbol.Detail <> '' then
    begin
      TextRect.Left := TextX;
      TextRect.Right := RowRect.Right - 4;
      DrawText(Canvas.Handle, PChar(Symbol.Detail), Length(Symbol.Detail),
               TextRect, DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or
               DT_END_ELLIPSIS);
    end;
    Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TCiListPopup.MouseDown(Button: TMouseButton; Shift: TShiftState;
                                 X, Y: Integer);
var
  RowIdx: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if FRowHeight <= 0 then
    Exit;
  RowIdx := FTop + Y div FRowHeight;
  if (RowIdx >= 0) and (RowIdx < FShownCount) then
  begin
    FSel := RowIdx;
    Invalidate;
  end;
end;

procedure TCiListPopup.DblClick;
begin
  inherited DblClick;
  if Assigned(FOnAccept) then
    FOnAccept(Self);
end;

end.
