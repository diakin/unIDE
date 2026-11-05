unit ArdObjParse;

// ---------------------------------------------------------------------------
//  Инспектор объектов для скетча Arduino (.ino): что выводится на экран
//
//  Без VCL: разбор текста скетча на функции и вызовы вывода на TFT
//  (библиотека UTFT). Инспектор (Unit1, ArdRefreshInspector) строит по
//  нему дерево Objects - Tree и таблицу свойств.
//
//  Что считается выводом:
//    - методы объекта UTFT (UTFT myGLCD(...)): текст (print, printNumI,
//      printNumF, printChar), графика (drawLine, drawRect, fillRect,
//      drawRoundRect, fillRoundRect, drawCircle, fillCircle, drawPixel),
//      картинки (drawBitmap), очистка (clrScr, fillScr);
//    - вызов функции самого скетча, которая выводит на экран - прямо или
//      через другие такие функции (Label, Win0...).
//  setColor, setBackColor и setFont - не вывод: у текста и графики они
//  показываются строками свойств - ближайший такой вызов выше в той же
//  функции.
//
//  Комментарии, строки и символы в кавычках, строки препроцессора
//  пропускаются: апостроф в комментарии ('!) разбору не мешает.
//  #define без параметров запоминаются (цвета clw, шрифт-синоним
//  arial_normal), extern uint8_t Имя[] - список шрифтов.
//
//  Номера строк - от нуля, колонки - от единицы, в знаках текста. Строки
//  разделяются CR, LF или CRLF.
// ---------------------------------------------------------------------------

interface

uses
  Classes, SysUtils;

type
  TArdCallKind = (
    ackText,      // print, printNumI, printNumF, printChar
    ackGraph,     // линии, прямоугольники, круги, точки
    ackImage,     // drawBitmap
    ackScreen,    // clrScr, fillScr
    ackSetColor,  // setColor
    ackSetBack,   // setBackColor
    ackSetFont,   // setFont
    ackUser);     // функция скетча, выводящая на экран

  TArdFunc = class;

  TArdCall = class
  public
    Name: string;       // print, drawLine, Label
    ObjName: string;    // объект UTFT (myGLCD), у функции скетча - ''
    Kind: TArdCallKind;
    Line, Col: Integer; // начало имени (у метода - имени объекта)
    Func: TArdFunc;     // в какой функции стоит
    Target: TArdFunc;   // ackUser: какую функцию вызывает
    Args: TStringList;  // аргументы как написаны, без пробелов по краям
    // Где аргумент в тексте: строка, колонка, длина. ArgLine = -1 -
    // аргумент на нескольких строках, одной заменой не правится.
    ArgLine, ArgCol, ArgLen: array of Integer;
    // Весь текст между скобками (для setColor(r, g, b)); ArgsLine = -1 -
    // на нескольких строках
    ArgsLine, ArgsCol, ArgsLen: Integer;
    ArgsText: string;
    // Текст и графика: последний setColor / setBackColor / setFont выше в
    // той же функции, nil - в функции не задан
    ColorCall, BackCall, FontCall: TArdCall;
    constructor Create;
    destructor Destroy; override;
    function KindText: string;
  end;

  TArdFunc = class
  public
    Name, RetType: string;
    Line, EndLine: Integer;      // заголовок и закрывающая скобка тела
    ParamNames, ParamTypes: TStringList;
    Calls: TList;                // TArdCall тела по порядку, и set...
    Draws: Boolean;              // выводит на экран (прямо или через другие)
    // Номера слов { и } тела - только на время разбора
    BodyTok, EndTok: Integer;
    constructor Create;
    destructor Destroy; override;
    function OutCount: Integer;  // вызовов вывода (без set...)
  end;

  TArdSketch = class
  private
    FText: string;
    FTokens: TList;
    procedure Tokenize;
    procedure ScanTopLevel;
    procedure ScanBodies;
    procedure ResolveDraws;
    procedure LinkSetters;
    function ParseCallAt(ATokIdx: Integer; AFunc: TArdFunc;
                         const AObj, AName: string; ANameTok: Integer): Integer;
    function EvalColor(const AExpr: string; ADepth: Integer;
                       var AColor: Integer): Boolean;
  public
    Funcs: TList;              // TArdFunc - все функции с телом
    Calls: TList;              // TArdCall - все найденные вызовы
    Fonts: TStringList;        // extern uint8_t Имя[] и #define-синонимы
    Defines: TStringList;      // #define ИМЯ значение: Name=Value
    MacroFuncs: TStringList;   // #define ИМЯ(...) - имена
    ScreenObjs: TStringList;   // объекты UTFT
    constructor Create;
    destructor Destroy; override;
    procedure Parse(const AText: string);
    function FuncByName(const AName: string): TArdFunc;
    // Цвет выражения как TColor ($00BBGGRR): число RGB565 (0xF800, 63488),
    // VGA_..., RGB24TOLCD(0xRRGGBB), три числа "r, g, b", имя #define.
    // False - не вычисляется (переменная, выражение).
    function ColorOf(const AExpr: string; var AColor: Integer): Boolean;
    // Имена цветов для списка: VGA_... и #define скетча, у которых цвет
    // вычисляется и которые стоят в аргументах цвета
    procedure ColorNames(AList: TStrings);
    // Цвет диалога - текстом для скетча: RGB24TOLCD(0xRRGGBB), если такой
    // макрос в скетче есть, иначе 0xNNNN (RGB565)
    function ColorToText(AColor: Integer): string;
  end;

// Параметр функции скетча - цвет / шрифт / строка (по имени и типу)
function ArdParamIsColor(const AName, AType: string): Boolean;
function ArdParamIsFont(const AName, AType: string): Boolean;
// Имена параметров метода UTFT (print - Text, X, Y, Deg)
procedure ArdMethodParams(const AMethod: string; AArgCount: Integer;
                          AList: TStrings);
// Аргумент - одна строка в кавычках: True и текст без кавычек
function ArdUnquote(const AArg: string; var AText: string): Boolean;
function ArdQuote(const AText: string): string;

implementation

type
  TArdTokKind = (atkIdent, atkNumber, atkString, atkChar, atkPunct);

  TArdTok = class
  public
    Kind: TArdTokKind;
    Text: string;
    StartPos, EndPos: Integer;  // в FText, от 1; EndPos - последний знак
    Line, Col: Integer;
    EndLine: Integer;
  end;

const
  IdentStart = ['A'..'Z', 'a'..'z', '_'];
  IdentChars = ['A'..'Z', 'a'..'z', '0'..'9', '_'];

  VgaNames: array[0..15] of string = (
    'VGA_BLACK', 'VGA_WHITE', 'VGA_RED', 'VGA_GREEN', 'VGA_BLUE',
    'VGA_SILVER', 'VGA_GRAY', 'VGA_MAROON', 'VGA_YELLOW', 'VGA_OLIVE',
    'VGA_LIME', 'VGA_AQUA', 'VGA_TEAL', 'VGA_NAVY', 'VGA_FUCHSIA',
    'VGA_PURPLE');
  VgaValues: array[0..15] of Integer = (
    $0000, $FFFF, $F800, $0400, $001F, $C618, $8410, $8000, $FFE0, $8400,
    $07E0, $07FF, $0410, $0010, $F81F, $8010);

function IsKeyword(const AWord: string): Boolean;
begin
  Result := (AWord = 'if') or (AWord = 'for') or (AWord = 'while') or
            (AWord = 'switch') or (AWord = 'return') or (AWord = 'sizeof') or
            (AWord = 'do') or (AWord = 'else') or (AWord = 'case') or
            (AWord = 'catch') or (AWord = 'defined');
end;

function MethodKind(const AName: string; var AKind: TArdCallKind): Boolean;
begin
  Result := True;
  if (AName = 'print') or (AName = 'printNumI') or (AName = 'printNumF') or
     (AName = 'printChar') then
    AKind := ackText
  else if (AName = 'drawLine') or (AName = 'drawRect') or
          (AName = 'fillRect') or (AName = 'drawRoundRect') or
          (AName = 'fillRoundRect') or (AName = 'drawCircle') or
          (AName = 'fillCircle') or (AName = 'drawPixel') or
          (AName = 'drawHLine') or (AName = 'drawVLine') then
    AKind := ackGraph
  else if AName = 'drawBitmap' then
    AKind := ackImage
  else if (AName = 'clrScr') or (AName = 'fillScr') then
    AKind := ackScreen
  else if AName = 'setColor' then
    AKind := ackSetColor
  else if AName = 'setBackColor' then
    AKind := ackSetBack
  else if AName = 'setFont' then
    AKind := ackSetFont
  else
    Result := False;
end;

function ArdParamIsColor(const AName, AType: string): Boolean;
var
  Low: string;
begin
  Low := LowerCase(AName);
  Result := (Pos('color', Low) > 0) or (Pos('colour', Low) > 0) or
            (Pos('clr', Low) > 0);
end;

function ArdParamIsFont(const AName, AType: string): Boolean;
var
  LowType: string;
begin
  LowType := LowerCase(AType);
  Result := (Pos('font', LowerCase(AName)) > 0) or
            ((Pos('uint8_t', LowType) > 0) and
             ((Pos('[', LowType) > 0) or (Pos('*', LowType) > 0))) or
            (Pos('fontdatatype', LowType) > 0);
end;

procedure ArdMethodParams(const AMethod: string; AArgCount: Integer;
                          AList: TStrings);

  procedure Put(const ANames: array of string);
  var
    Idx: Integer;
  begin
    for Idx := 0 to High(ANames) do
      AList.Add(ANames[Idx]);
  end;

begin
  AList.Clear;
  if AMethod = 'print' then
    Put(['Text', 'X', 'Y', 'Deg'])
  else if AMethod = 'printNumI' then
    Put(['Number', 'X', 'Y', 'Length', 'Filler'])
  else if AMethod = 'printNumF' then
    Put(['Number', 'Decimals', 'X', 'Y', 'Divider', 'Length', 'Filler'])
  else if AMethod = 'printChar' then
    Put(['Char', 'X', 'Y'])
  else if (AMethod = 'drawLine') or (AMethod = 'drawRect') or
          (AMethod = 'fillRect') or (AMethod = 'drawRoundRect') or
          (AMethod = 'fillRoundRect') then
    Put(['X1', 'Y1', 'X2', 'Y2'])
  else if (AMethod = 'drawCircle') or (AMethod = 'fillCircle') then
    Put(['X', 'Y', 'Radius'])
  else if AMethod = 'drawPixel' then
    Put(['X', 'Y'])
  else if (AMethod = 'drawHLine') or (AMethod = 'drawVLine') then
    Put(['X', 'Y', 'Length'])
  else if AMethod = 'drawBitmap' then
  begin
    if AArgCount >= 8 then
      Put(['X', 'Y', 'SizeX', 'SizeY', 'Data', 'Deg', 'RotX', 'RotY'])
    else
      Put(['X', 'Y', 'SizeX', 'SizeY', 'Data', 'Scale']);
  end
  else if (AMethod = 'fillScr') or (AMethod = 'setColor') or
          (AMethod = 'setBackColor') then
  begin
    if AArgCount >= 3 then
      Put(['Red', 'Green', 'Blue'])
    else
      Put(['Color']);
  end
  else if AMethod = 'setFont' then
    Put(['Font']);
  // Лишние аргументы - по номеру
  while AList.Count < AArgCount do
    AList.Add('Arg' + IntToStr(AList.Count + 1));
end;

function ArdUnquote(const AArg: string; var AText: string): Boolean;
var
  Idx: Integer;
begin
  Result := False;
  AText := '';
  if (Length(AArg) < 2) or (AArg[1] <> '"') or (AArg[Length(AArg)] <> '"') then
    Exit;
  Idx := 2;
  while Idx < Length(AArg) do
  begin
    if AArg[Idx] = '\' then
    begin
      if Idx + 1 >= Length(AArg) then
        Exit;
      Inc(Idx);
      case AArg[Idx] of
        'n': AText := AText + #10;
        't': AText := AText + #9;
        '"', '\', '''': AText := AText + AArg[Idx];
      else
        // \x60 и прочее - не одна простая строка, правится как выражение
        Exit;
      end;
    end
    else if AArg[Idx] = '"' then
      Exit   // "a" "b" или "a" + b
    else
      AText := AText + AArg[Idx];
    Inc(Idx);
  end;
  Result := True;
end;

function ArdQuote(const AText: string): string;
var
  Idx: Integer;
begin
  Result := '"';
  for Idx := 1 to Length(AText) do
    case AText[Idx] of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #10: Result := Result + '\n';
      #9: Result := Result + '\t';
    else
      Result := Result + AText[Idx];
    end;
  Result := Result + '"';
end;

{ TArdCall }

constructor TArdCall.Create;
begin
  inherited Create;
  Args := TStringList.Create;
  ArgsLine := -1;
end;

destructor TArdCall.Destroy;
begin
  Args.Free;
  inherited Destroy;
end;

function TArdCall.KindText: string;
begin
  case Kind of
    ackText: Result := 'текст';
    ackGraph: Result := 'графика';
    ackImage: Result := 'картинка';
    ackScreen: Result := 'экран';
    ackUser: Result := 'функция скетча';
  else
    Result := 'настройка';
  end;
end;

{ TArdFunc }

constructor TArdFunc.Create;
begin
  inherited Create;
  ParamNames := TStringList.Create;
  ParamTypes := TStringList.Create;
  Calls := TList.Create;
  EndLine := -1;
end;

destructor TArdFunc.Destroy;
begin
  Calls.Free;
  ParamTypes.Free;
  ParamNames.Free;
  inherited Destroy;
end;

function TArdFunc.OutCount: Integer;
var
  Idx: Integer;
begin
  Result := 0;
  for Idx := 0 to Calls.Count - 1 do
    if TArdCall(Calls[Idx]).Kind in [ackText, ackGraph, ackImage, ackScreen,
                                     ackUser] then
      Inc(Result);
end;

{ TArdSketch }

constructor TArdSketch.Create;
begin
  inherited Create;
  FTokens := TList.Create;
  Funcs := TList.Create;
  Calls := TList.Create;
  Fonts := TStringList.Create;
  Defines := TStringList.Create;
  MacroFuncs := TStringList.Create;
  ScreenObjs := TStringList.Create;
end;

destructor TArdSketch.Destroy;
var
  Idx: Integer;
begin
  for Idx := 0 to FTokens.Count - 1 do
    TArdTok(FTokens[Idx]).Free;
  FTokens.Free;
  for Idx := 0 to Calls.Count - 1 do
    TArdCall(Calls[Idx]).Free;
  Calls.Free;
  for Idx := 0 to Funcs.Count - 1 do
    TArdFunc(Funcs[Idx]).Free;
  Funcs.Free;
  Fonts.Free;
  Defines.Free;
  MacroFuncs.Free;
  ScreenObjs.Free;
  inherited Destroy;
end;

// Текст - на слова, числа, строки и знаки. Комментарии и строки
// препроцессора в список не идут; #define и #include разбираются тут же.
procedure TArdSketch.Tokenize;
var
  Pos1, TextLen, CurLine, LineStart: Integer;
  AtLineStart: Boolean;

  procedure NewLineAt(APos: Integer);
  begin
    Inc(CurLine);
    LineStart := APos + 1;
  end;

  // Перевод строки в Pos1: CRLF, CR или LF. True - был, Pos1 за ним.
  function SkipBreak: Boolean;
  begin
    Result := False;
    if Pos1 > TextLen then
      Exit;
    if FText[Pos1] = #13 then
    begin
      if (Pos1 < TextLen) and (FText[Pos1 + 1] = #10) then
        Inc(Pos1);
      NewLineAt(Pos1);
      Inc(Pos1);
      Result := True;
    end
    else if FText[Pos1] = #10 then
    begin
      NewLineAt(Pos1);
      Inc(Pos1);
      Result := True;
    end;
  end;

  procedure AddTok(AKind: TArdTokKind; AStart, AEnd, ALine, ACol: Integer);
  var
    Tok: TArdTok;
  begin
    Tok := TArdTok.Create;
    Tok.Kind := AKind;
    Tok.StartPos := AStart;
    Tok.EndPos := AEnd;
    Tok.Text := Copy(FText, AStart, AEnd - AStart + 1);
    Tok.Line := ALine;
    Tok.Col := ACol;
    Tok.EndLine := CurLine;
    FTokens.Add(Tok);
  end;

  // Строка препроцессора от # до конца (с продолжением через \)
  procedure Preprocessor;
  var
    NameStart, NameEnd: Integer;
    Directive, Body, MacroName, MacroValue: string;
    CommentAt: Integer;
  begin
    Body := '';
    while Pos1 <= TextLen do
    begin
      if (FText[Pos1] = '\') and (Pos1 < TextLen) and
         (FText[Pos1 + 1] in [#13, #10]) then
      begin
        Inc(Pos1);
        SkipBreak;
        Body := Body + ' ';
        Continue;
      end;
      if FText[Pos1] in [#13, #10] then
        Break;
      // /* ... */ внутри строки препроцессора может уйти на другие строки
      if (FText[Pos1] = '/') and (Pos1 < TextLen) and (FText[Pos1 + 1] = '*') then
      begin
        Inc(Pos1, 2);
        while (Pos1 <= TextLen) and
              not ((FText[Pos1] = '*') and (Pos1 < TextLen) and
                   (FText[Pos1 + 1] = '/')) do
          if not SkipBreak then
            Inc(Pos1);
        Inc(Pos1, 2);
        Body := Body + ' ';
        Continue;
      end;
      Body := Body + FText[Pos1];
      Inc(Pos1);
    end;
    // #define ИМЯ значение / #define ИМЯ(параметры) тело
    CommentAt := Pos('//', Body);
    if CommentAt > 0 then
      Body := Copy(Body, 1, CommentAt - 1);
    Body := Trim(Copy(Body, 2, MaxInt));   // без #
    NameStart := 1;
    while (NameStart <= Length(Body)) and (Body[NameStart] in IdentChars) do
      Inc(NameStart);
    Directive := Copy(Body, 1, NameStart - 1);
    if Directive <> 'define' then
      Exit;
    Body := TrimLeft(Copy(Body, NameStart, MaxInt));
    NameEnd := 1;
    while (NameEnd <= Length(Body)) and (Body[NameEnd] in IdentChars) do
      Inc(NameEnd);
    MacroName := Copy(Body, 1, NameEnd - 1);
    if MacroName = '' then
      Exit;
    if (NameEnd <= Length(Body)) and (Body[NameEnd] = '(') then
    begin
      MacroFuncs.Add(MacroName);
      Exit;
    end;
    MacroValue := Trim(Copy(Body, NameEnd, MaxInt));
    Defines.Add(MacroName + '=' + MacroValue);
  end;

var
  TokStart, TokLine, TokCol: Integer;
  QuoteCh: Char;
begin
  TextLen := Length(FText);
  Pos1 := 1;
  CurLine := 0;
  LineStart := 1;
  AtLineStart := True;
  while Pos1 <= TextLen do
  begin
    if SkipBreak then
    begin
      AtLineStart := True;
      Continue;
    end;
    if FText[Pos1] in [' ', #9, #12, #11] then
    begin
      Inc(Pos1);
      Continue;
    end;
    // Комментарии
    if (FText[Pos1] = '/') and (Pos1 < TextLen) and (FText[Pos1 + 1] = '/') then
    begin
      while (Pos1 <= TextLen) and not (FText[Pos1] in [#13, #10]) do
        Inc(Pos1);
      Continue;
    end;
    if (FText[Pos1] = '/') and (Pos1 < TextLen) and (FText[Pos1 + 1] = '*') then
    begin
      Inc(Pos1, 2);
      while (Pos1 <= TextLen) and
            not ((FText[Pos1] = '*') and (Pos1 < TextLen) and
                 (FText[Pos1 + 1] = '/')) do
        if not SkipBreak then
          Inc(Pos1);
      Inc(Pos1, 2);
      Continue;
    end;
    if (FText[Pos1] = '#') and AtLineStart then
    begin
      Preprocessor;
      Continue;
    end;
    AtLineStart := False;
    TokStart := Pos1;
    TokLine := CurLine;
    TokCol := Pos1 - LineStart + 1;
    if FText[Pos1] in IdentStart then
    begin
      while (Pos1 <= TextLen) and (FText[Pos1] in IdentChars) do
        Inc(Pos1);
      AddTok(atkIdent, TokStart, Pos1 - 1, TokLine, TokCol);
    end
    else if FText[Pos1] in ['0'..'9'] then
    begin
      while (Pos1 <= TextLen) and (FText[Pos1] in IdentChars + ['.']) do
        Inc(Pos1);
      AddTok(atkNumber, TokStart, Pos1 - 1, TokLine, TokCol);
    end
    else if FText[Pos1] in ['"', ''''] then
    begin
      QuoteCh := FText[Pos1];
      Inc(Pos1);
      while (Pos1 <= TextLen) and (FText[Pos1] <> QuoteCh) and
            not (FText[Pos1] in [#13, #10]) do
      begin
        if (FText[Pos1] = '\') and (Pos1 < TextLen) then
          Inc(Pos1);
        Inc(Pos1);
      end;
      if (Pos1 <= TextLen) and (FText[Pos1] = QuoteCh) then
        Inc(Pos1);
      if QuoteCh = '"' then
        AddTok(atkString, TokStart, Pos1 - 1, TokLine, TokCol)
      else
        AddTok(atkChar, TokStart, Pos1 - 1, TokLine, TokCol);
    end
    else
    begin
      // -> и :: - одним знаком, остальное по одному
      if (Pos1 < TextLen) and
         (((FText[Pos1] = '-') and (FText[Pos1 + 1] = '>')) or
          ((FText[Pos1] = ':') and (FText[Pos1 + 1] = ':'))) then
        Inc(Pos1);
      Inc(Pos1);
      AddTok(atkPunct, TokStart, Pos1 - 1, TokLine, TokCol);
    end;
  end;
end;

function TokAt(AList: TList; AIdx: Integer): TArdTok;
begin
  if (AIdx >= 0) and (AIdx < AList.Count) then
    Result := TArdTok(AList[AIdx])
  else
    Result := nil;
end;

function TokIs(AList: TList; AIdx: Integer; const AText: string): Boolean;
var
  Tok: TArdTok;
begin
  Tok := TokAt(AList, AIdx);
  Result := (Tok <> nil) and (Tok.Kind = atkPunct) and (Tok.Text = AText);
end;

// Парная закрывающая скобка для открывающей в AOpenIdx; -1 - нет
function MatchClose(AList: TList; AOpenIdx: Integer): Integer;
var
  Depth, Idx: Integer;
  Tok: TArdTok;
begin
  Result := -1;
  Depth := 0;
  for Idx := AOpenIdx to AList.Count - 1 do
  begin
    Tok := TArdTok(AList[Idx]);
    if Tok.Kind <> atkPunct then
      Continue;
    if (Tok.Text = '(') or (Tok.Text = '[') or (Tok.Text = '{') then
      Inc(Depth)
    else if (Tok.Text = ')') or (Tok.Text = ']') or (Tok.Text = '}') then
    begin
      Dec(Depth);
      if Depth = 0 then
      begin
        Result := Idx;
        Exit;
      end;
    end;
  end;
end;

// Верхний уровень: объявления UTFT, extern-шрифты, функции с телом
procedure TArdSketch.ScanTopLevel;
var
  Idx, Depth, CloseIdx, BodyIdx, EndIdx, StartIdx, ParIdx, PartStart: Integer;
  Tok, Prev: TArdTok;
  Func: TArdFunc;
  RetType, ParName, ParType: string;

  procedure AddParam(AFrom, ATo: Integer);
  var
    Pi1, LastIdent: Integer;
    PTok: TArdTok;
  begin
    if AFrom > ATo then
      Exit;
    // Имя - последнее слово до '[' или '=' (значения по умолчанию)
    LastIdent := -1;
    ParType := '';
    for Pi1 := AFrom to ATo do
    begin
      PTok := TArdTok(FTokens[Pi1]);
      if (PTok.Kind = atkPunct) and (PTok.Text = '=') then
        Break;
      if PTok.Kind = atkIdent then
        LastIdent := Pi1;
    end;
    if LastIdent < 0 then
      Exit;
    ParName := TArdTok(FTokens[LastIdent]).Text;
    if (ParName = 'void') and (AFrom = ATo) then
      Exit;
    for Pi1 := AFrom to ATo do
    begin
      PTok := TArdTok(FTokens[Pi1]);
      if (PTok.Kind = atkPunct) and (PTok.Text = '=') then
        Break;
      if Pi1 <> LastIdent then
      begin
        // uint8_t Font[] - тип "uint8_t[]", без пробелов у скобок
        if (ParType <> '') and (PTok.Text <> '[') and (PTok.Text <> ']') and
           (ParType[Length(ParType)] <> '[') then
          ParType := ParType + ' ';
        ParType := ParType + PTok.Text;
      end;
    end;
    Func.ParamNames.Add(ParName);
    Func.ParamTypes.Add(ParType);
  end;

begin
  Depth := 0;
  Idx := 0;
  StartIdx := 0;   // первое слово текущего объявления
  while Idx < FTokens.Count do
  begin
    Tok := TArdTok(FTokens[Idx]);
    if Tok.Kind = atkPunct then
    begin
      if Tok.Text = '{' then
        Inc(Depth)
      else if Tok.Text = '}' then
      begin
        Dec(Depth);
        if Depth <= 0 then
        begin
          Depth := 0;
          StartIdx := Idx + 1;
        end;
      end
      else if (Tok.Text = ';') and (Depth = 0) then
        StartIdx := Idx + 1;
      Inc(Idx);
      Continue;
    end;
    if (Depth > 0) or (Tok.Kind <> atkIdent) then
    begin
      Inc(Idx);
      Continue;
    end;

    // UTFT имя(...)
    if (Tok.Text = 'UTFT') and (TokAt(FTokens, Idx + 1) <> nil) and
       (TokAt(FTokens, Idx + 1).Kind = atkIdent) then
    begin
      if ScreenObjs.IndexOf(TokAt(FTokens, Idx + 1).Text) < 0 then
        ScreenObjs.Add(TokAt(FTokens, Idx + 1).Text);
      Inc(Idx, 2);
      Continue;
    end;

    // extern uint8_t Имя[];  (и fontdatatype, unsigned char)
    if (Tok.Text = 'extern') then
    begin
      ParIdx := Idx + 1;
      while (TokAt(FTokens, ParIdx) <> nil) and
            (TokAt(FTokens, ParIdx).Kind = atkIdent) do
        Inc(ParIdx);
      // ParIdx - первый знак после слов; имя - перед ним
      if TokIs(FTokens, ParIdx, '[') and (ParIdx - Idx >= 3) then
      begin
        ParType := '';
        for PartStart := Idx + 1 to ParIdx - 2 do
          ParType := ParType + TArdTok(FTokens[PartStart]).Text + ' ';
        ParType := LowerCase(ParType);
        if (Pos('uint8_t', ParType) > 0) or (Pos('fontdatatype', ParType) > 0) or
           (Pos('char', ParType) > 0) then
          if Fonts.IndexOf(TArdTok(FTokens[ParIdx - 1]).Text) < 0 then
            Fonts.Add(TArdTok(FTokens[ParIdx - 1]).Text);
      end;
      Idx := ParIdx;
      Continue;
    end;

    // Имя ( ... ) { - функция с телом; ( ... ) ; - объявление, не берём
    if TokIs(FTokens, Idx + 1, '(') and not IsKeyword(Tok.Text) then
    begin
      CloseIdx := MatchClose(FTokens, Idx + 1);
      if CloseIdx < 0 then
        Break;
      BodyIdx := CloseIdx + 1;
      // void f() const {  - редкость в скетчах, но пусть
      while (TokAt(FTokens, BodyIdx) <> nil) and
            (TokAt(FTokens, BodyIdx).Kind = atkIdent) do
        Inc(BodyIdx);
      if TokIs(FTokens, BodyIdx, '{') then
      begin
        EndIdx := MatchClose(FTokens, BodyIdx);
        Func := TArdFunc.Create;
        Func.Name := Tok.Text;
        Func.Line := Tok.Line;
        RetType := '';
        for ParIdx := StartIdx to Idx - 1 do
        begin
          Prev := TArdTok(FTokens[ParIdx]);
          if RetType <> '' then
            RetType := RetType + ' ';
          RetType := RetType + Prev.Text;
        end;
        Func.RetType := RetType;
        // Параметры - по запятым верхнего уровня
        PartStart := Idx + 2;
        ParIdx := Idx + 2;
        while ParIdx < CloseIdx do
        begin
          Prev := TArdTok(FTokens[ParIdx]);
          if (Prev.Kind = atkPunct) and ((Prev.Text = '(') or (Prev.Text = '[') or
                                         (Prev.Text = '{')) then
          begin
            ParIdx := MatchClose(FTokens, ParIdx) + 1;
            if ParIdx <= 0 then
              Break;
            Continue;
          end;
          if (Prev.Kind = atkPunct) and (Prev.Text = ',') then
          begin
            AddParam(PartStart, ParIdx - 1);
            PartStart := ParIdx + 1;
          end;
          Inc(ParIdx);
        end;
        AddParam(PartStart, CloseIdx - 1);
        Func.BodyTok := BodyIdx;
        if EndIdx >= 0 then
        begin
          Func.EndLine := TArdTok(FTokens[EndIdx]).Line;
          Func.EndTok := EndIdx;
        end
        else
          Func.EndTok := FTokens.Count - 1;
        Funcs.Add(Func);
        if EndIdx < 0 then
          Break;
        Idx := EndIdx + 1;
        StartIdx := Idx;
        Continue;
      end;
      Idx := CloseIdx + 1;
      Continue;
    end;
    Inc(Idx);
  end;
end;

function TArdSketch.FuncByName(const AName: string): TArdFunc;
var
  Idx: Integer;
begin
  for Idx := 0 to Funcs.Count - 1 do
  begin
    Result := TArdFunc(Funcs[Idx]);
    if Result.Name = AName then
      Exit;
  end;
  Result := nil;
end;

// Вызов с именем в ANameTok и '(' в ATokIdx. Возвращает номер ')'.
function TArdSketch.ParseCallAt(ATokIdx: Integer; AFunc: TArdFunc;
                                const AObj, AName: string;
                                ANameTok: Integer): Integer;
var
  Call: TArdCall;
  CloseIdx, Idx, PartStart, ArgNo: Integer;
  Tok, FirstTok, LastTok, OpenTok, CloseTok: TArdTok;

  procedure AddArg(AFrom, ATo: Integer);
  begin
    if AFrom > ATo then
      Exit;
    FirstTok := TArdTok(FTokens[AFrom]);
    LastTok := TArdTok(FTokens[ATo]);
    ArgNo := Call.Args.Count;
    Call.Args.Add(Copy(FText, FirstTok.StartPos,
                       LastTok.EndPos - FirstTok.StartPos + 1));
    SetLength(Call.ArgLine, ArgNo + 1);
    SetLength(Call.ArgCol, ArgNo + 1);
    SetLength(Call.ArgLen, ArgNo + 1);
    if FirstTok.Line = LastTok.EndLine then
      Call.ArgLine[ArgNo] := FirstTok.Line
    else
      Call.ArgLine[ArgNo] := -1;
    Call.ArgCol[ArgNo] := FirstTok.Col;
    Call.ArgLen[ArgNo] := LastTok.EndPos - FirstTok.StartPos + 1;
  end;

begin
  CloseIdx := MatchClose(FTokens, ATokIdx);
  Result := CloseIdx;
  if CloseIdx < 0 then
    Exit;
  Call := TArdCall.Create;
  Call.Name := AName;
  Call.ObjName := AObj;
  Call.Func := AFunc;
  Tok := TArdTok(FTokens[ANameTok]);
  Call.Line := Tok.Line;
  Call.Col := Tok.Col;
  if AObj = '' then
    Call.Kind := ackUser
  else
    MethodKind(AName, Call.Kind);
  PartStart := ATokIdx + 1;
  Idx := ATokIdx + 1;
  while Idx < CloseIdx do
  begin
    Tok := TArdTok(FTokens[Idx]);
    if (Tok.Kind = atkPunct) and ((Tok.Text = '(') or (Tok.Text = '[') or
                                  (Tok.Text = '{')) then
    begin
      Idx := MatchClose(FTokens, Idx) + 1;
      if Idx <= 0 then
        Break;
      Continue;
    end;
    if (Tok.Kind = atkPunct) and (Tok.Text = ',') then
    begin
      AddArg(PartStart, Idx - 1);
      PartStart := Idx + 1;
    end;
    Inc(Idx);
  end;
  AddArg(PartStart, CloseIdx - 1);
  OpenTok := TArdTok(FTokens[ATokIdx]);
  CloseTok := TArdTok(FTokens[CloseIdx]);
  Call.ArgsText := Copy(FText, OpenTok.StartPos + 1,
                        CloseTok.StartPos - OpenTok.StartPos - 1);
  if OpenTok.Line = CloseTok.Line then
  begin
    Call.ArgsLine := OpenTok.Line;
    Call.ArgsCol := OpenTok.Col + 1;
    Call.ArgsLen := CloseTok.StartPos - OpenTok.StartPos - 1;
  end;
  Calls.Add(Call);
  AFunc.Calls.Add(Call);
end;

// Тела функций: методы объектов UTFT и вызовы функций скетча
procedure TArdSketch.ScanBodies;
var
  FuncIdx, Idx, BodyStart, BodyEnd: Integer;
  Func: TArdFunc;
  Tok, ObjTok: TArdTok;
  Kind: TArdCallKind;
begin
  for FuncIdx := 0 to Funcs.Count - 1 do
  begin
    Func := TArdFunc(Funcs[FuncIdx]);
    BodyStart := Func.BodyTok;
    BodyEnd := Func.EndTok;
    Idx := BodyStart + 1;
    while Idx < BodyEnd do
    begin
      Tok := TArdTok(FTokens[Idx]);
      if (Tok.Kind = atkIdent) and TokIs(FTokens, Idx + 1, '(') then
      begin
        ObjTok := nil;
        if (TokIs(FTokens, Idx - 1, '.') or TokIs(FTokens, Idx - 1, '->')) and
           (TokAt(FTokens, Idx - 2) <> nil) and
           (TokAt(FTokens, Idx - 2).Kind = atkIdent) then
          ObjTok := TokAt(FTokens, Idx - 2);
        if ObjTok <> nil then
        begin
          if (ScreenObjs.IndexOf(ObjTok.Text) >= 0) and
             MethodKind(Tok.Text, Kind) then
            ParseCallAt(Idx + 1, Func, ObjTok.Text, Tok.Text, Idx - 2);
        end
        else if not TokIs(FTokens, Idx - 1, '::') and
                not IsKeyword(Tok.Text) and (FuncByName(Tok.Text) <> nil) then
          ParseCallAt(Idx + 1, Func, '', Tok.Text, Idx);
        // Внутрь скобок - тоже: Label(..., String(x)) и вложенные вызовы
      end;
      Inc(Idx);
    end;
  end;
end;

// Кто выводит на экран: прямой вывод или вызов такой функции, по кругу,
// пока что-то меняется. Вызовы функций, которые не выводят, - прочь.
procedure TArdSketch.ResolveDraws;
var
  FuncIdx, CallIdx: Integer;
  Call: TArdCall;
  Changed: Boolean;
begin
  for CallIdx := 0 to Calls.Count - 1 do
  begin
    Call := TArdCall(Calls[CallIdx]);
    if Call.Kind = ackUser then
      Call.Target := FuncByName(Call.Name);
    if Call.Kind in [ackText, ackGraph, ackImage, ackScreen] then
      Call.Func.Draws := True;
  end;
  repeat
    Changed := False;
    for CallIdx := 0 to Calls.Count - 1 do
    begin
      Call := TArdCall(Calls[CallIdx]);
      if (Call.Kind = ackUser) and (Call.Target <> nil) and
         Call.Target.Draws and not Call.Func.Draws then
      begin
        Call.Func.Draws := True;
        Changed := True;
      end;
    end;
  until not Changed;
  // Вызовы невыводящих функций (setup вызывает calc()) - не нужны
  for CallIdx := Calls.Count - 1 downto 0 do
  begin
    Call := TArdCall(Calls[CallIdx]);
    if (Call.Kind = ackUser) and ((Call.Target = nil) or not Call.Target.Draws) then
    begin
      Call.Func.Calls.Remove(Call);
      Calls.Delete(CallIdx);
      Call.Free;
    end;
  end;
  for FuncIdx := 0 to Funcs.Count - 1 do
    TArdFunc(Funcs[FuncIdx]).Calls.Pack;
end;

// Текст и графика - последние setColor / setBackColor / setFont выше в
// той же функции, по порядку текста (ветки if не различаются)
procedure TArdSketch.LinkSetters;
var
  FuncIdx, CallIdx: Integer;
  Func: TArdFunc;
  Call, LastColor, LastBack, LastFont: TArdCall;
begin
  for FuncIdx := 0 to Funcs.Count - 1 do
  begin
    Func := TArdFunc(Funcs[FuncIdx]);
    LastColor := nil;
    LastBack := nil;
    LastFont := nil;
    for CallIdx := 0 to Func.Calls.Count - 1 do
    begin
      Call := TArdCall(Func.Calls[CallIdx]);
      case Call.Kind of
        ackSetColor: LastColor := Call;
        ackSetBack: LastBack := Call;
        ackSetFont: LastFont := Call;
        ackText:
          begin
            Call.ColorCall := LastColor;
            Call.BackCall := LastBack;
            Call.FontCall := LastFont;
          end;
        ackGraph:
          Call.ColorCall := LastColor;
      end;
    end;
  end;
end;

procedure TArdSketch.Parse(const AText: string);
var
  Idx: Integer;
  AliasValue: string;
begin
  FText := AText;
  Tokenize;
  ScanTopLevel;
  if ScreenObjs.Count = 0 then
    ScreenObjs.Add('myGLCD');
  ScanBodies;
  ResolveDraws;
  LinkSetters;
  // #define arial_normal Retro8x16 - тоже шрифт
  for Idx := 0 to Defines.Count - 1 do
  begin
    AliasValue := Defines.ValueFromIndex[Idx];
    if (Fonts.IndexOf(AliasValue) >= 0) and
       (Fonts.IndexOf(Defines.Names[Idx]) < 0) then
      Fonts.Add(Defines.Names[Idx]);
  end;
  // Слова больше не нужны - память под них прочь
  for Idx := 0 to FTokens.Count - 1 do
    TArdTok(FTokens[Idx]).Free;
  FTokens.Clear;
  FText := '';
end;

function Rgb565ToColor(AValue: Integer): Integer;
var
  Red, Green, Blue: Integer;
begin
  Red := (AValue shr 11) and $1F;
  Green := (AValue shr 5) and $3F;
  Blue := AValue and $1F;
  Red := (Red * 255 + 15) div 31;
  Green := (Green * 255 + 31) div 63;
  Blue := (Blue * 255 + 15) div 31;
  Result := Red or (Green shl 8) or (Blue shl 16);
end;

function NumberOf(const AText: string; var AValue: Integer): Boolean;
var
  Txt: string;
begin
  Txt := Trim(AText);
  // 0xF800, 0xF800u, 63488UL
  while (Length(Txt) > 1) and (UpCase(Txt[Length(Txt)]) in ['U', 'L']) and
        not ((Length(Txt) > 2) and (UpCase(Txt[2]) = 'X') and
             (UpCase(Txt[Length(Txt)]) in ['A'..'F'])) do
    SetLength(Txt, Length(Txt) - 1);
  if (Length(Txt) > 2) and (Txt[1] = '0') and (UpCase(Txt[2]) = 'X') then
    Result := TryStrToInt('$' + Copy(Txt, 3, MaxInt), AValue)
  else
    Result := (Txt <> '') and (Txt[1] in ['0'..'9']) and TryStrToInt(Txt, AValue);
end;

function StripParens(const AText: string): string;
var
  Depth, Idx: Integer;
  Whole: Boolean;
begin
  Result := Trim(AText);
  while (Length(Result) >= 2) and (Result[1] = '(') and
        (Result[Length(Result)] = ')') do
  begin
    // (a) + (b) - внешние скобки не одни
    Depth := 0;
    Whole := True;
    for Idx := 1 to Length(Result) - 1 do
    begin
      if Result[Idx] = '(' then
        Inc(Depth)
      else if Result[Idx] = ')' then
        Dec(Depth);
      if Depth = 0 then
      begin
        Whole := False;
        Break;
      end;
    end;
    if not Whole then
      Exit;
    Result := Trim(Copy(Result, 2, Length(Result) - 2));
  end;
end;

function TArdSketch.EvalColor(const AExpr: string; ADepth: Integer;
                              var AColor: Integer): Boolean;
var
  Txt, Inner: string;
  Value, Idx, CommaAt, Red, Green, Blue: Integer;
  Parts: TStringList;
begin
  Result := False;
  if ADepth > 8 then
    Exit;
  Txt := StripParens(AExpr);
  if Txt = '' then
    Exit;
  // r, g, b
  if Pos(',', Txt) > 0 then
  begin
    Parts := TStringList.Create;
    try
      Inner := Txt;
      repeat
        CommaAt := Pos(',', Inner);
        if CommaAt > 0 then
        begin
          Parts.Add(Trim(Copy(Inner, 1, CommaAt - 1)));
          Inner := Copy(Inner, CommaAt + 1, MaxInt);
        end
        else
          Parts.Add(Trim(Inner));
      until CommaAt = 0;
      if (Parts.Count = 3) and NumberOf(Parts[0], Red) and
         NumberOf(Parts[1], Green) and NumberOf(Parts[2], Blue) then
      begin
        AColor := (Red and $FF) or ((Green and $FF) shl 8) or
                  ((Blue and $FF) shl 16);
        Result := True;
      end;
    finally
      Parts.Free;
    end;
    Exit;
  end;
  if NumberOf(Txt, Value) then
  begin
    AColor := Rgb565ToColor(Value);
    Result := True;
    Exit;
  end;
  // RGB24TOLCD(0xRRGGBB) - цвет 24 бита
  if (Copy(Txt, 1, 11) = 'RGB24TOLCD(') and (Txt[Length(Txt)] = ')') then
  begin
    Inner := Copy(Txt, 12, Length(Txt) - 12);
    if NumberOf(Inner, Value) then
    begin
      AColor := ((Value shr 16) and $FF) or (Value and $FF00) or
                ((Value and $FF) shl 16);
      Result := True;
    end;
    Exit;
  end;
  for Idx := 0 to High(VgaNames) do
    if VgaNames[Idx] = Txt then
    begin
      AColor := Rgb565ToColor(VgaValues[Idx]);
      Result := True;
      Exit;
    end;
  Idx := Defines.IndexOfName(Txt);
  if Idx >= 0 then
    Result := EvalColor(Defines.ValueFromIndex[Idx], ADepth + 1, AColor);
end;

function TArdSketch.ColorOf(const AExpr: string; var AColor: Integer): Boolean;
begin
  Result := EvalColor(AExpr, 0, AColor);
end;

procedure TArdSketch.ColorNames(AList: TStrings);
var
  Idx, CallIdx, ArgIdx, ColorValue: Integer;
  Used: TStringList;
  Call: TArdCall;
  ParamName, ParamType: string;
begin
  AList.Clear;
  Used := TStringList.Create;
  try
    Used.Sorted := True;
    Used.Duplicates := dupIgnore;
    // Что стоит в аргументах цвета
    for CallIdx := 0 to Calls.Count - 1 do
    begin
      Call := TArdCall(Calls[CallIdx]);
      if Call.Kind in [ackSetColor, ackSetBack] then
      begin
        if Call.Args.Count = 1 then
          Used.Add(StripParens(Call.Args[0]));
      end
      else if (Call.Kind = ackUser) and (Call.Target <> nil) then
        for ArgIdx := 0 to Call.Args.Count - 1 do
        begin
          if ArgIdx >= Call.Target.ParamNames.Count then
            Break;
          ParamName := Call.Target.ParamNames[ArgIdx];
          ParamType := Call.Target.ParamTypes[ArgIdx];
          if ArdParamIsColor(ParamName, ParamType) then
            Used.Add(StripParens(Call.Args[ArgIdx]));
        end;
    end;
    for Idx := 0 to Defines.Count - 1 do
      if (Used.IndexOf(Defines.Names[Idx]) >= 0) and
         ColorOf(Defines.Names[Idx], ColorValue) then
        AList.Add(Defines.Names[Idx]);
    for Idx := 0 to High(VgaNames) do
      AList.Add(VgaNames[Idx]);
  finally
    Used.Free;
  end;
end;

function TArdSketch.ColorToText(AColor: Integer): string;
var
  Red, Green, Blue: Integer;
begin
  Red := AColor and $FF;
  Green := (AColor shr 8) and $FF;
  Blue := (AColor shr 16) and $FF;
  if MacroFuncs.IndexOf('RGB24TOLCD') >= 0 then
    Result := 'RGB24TOLCD(0x' + IntToHex((Red shl 16) or (Green shl 8) or Blue, 6) + ')'
  else
    Result := '0x' + IntToHex(((Red shr 3) shl 11) or ((Green shr 2) shl 5) or
                              (Blue shr 3), 4);
end;

end.
