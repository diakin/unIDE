unit ArdWinMap;
// ---------------------------------------------------------------------------
//  Карта окон скетча Arduino: функции-окна WinXXX() и переходы между ними
//
//  Без VCL. Окно - функция, которую вызывает ветка case оператора
//  switch (Переменная) с тремя и больше такими ветками (BS10:
//  switch (WinState) в loop()). Номер окна - число в case.
//
//  Переходы:
//    - меню: массив TMenuItem (const TMenuItem mnuWin0[] = {{&lbl, "1",
//      100}, ...}), который упоминает тело окна. Target - номер окна;
//      отрицательный (#define actRepeat -2) - действие внутри окна;
//    - код: присваивание Переменная = число в теле окна или в setup().
//      Клавиша - строки в кавычках из условия if, внутри которого стоит
//      присваивание (if (btnName == "#")). Присваивание своего же номера
//      без условия (WinState = 10; в начале Win10) - не переход;
//    - вызов: функция Win..., которой нет в switch, вызвана из окна
//      напрямую (Win1F1() - помощь, после неё возврат в то же окно).
//  Начальное значение переменной (static int WinState = 0) - переход из
//  узла setup().
//
//  Номера строк - от нуля.
// ---------------------------------------------------------------------------

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils;

type
  TWmNodeKind = (
    wnkWindow,    // окно: case N: WinN();
    wnkModal,     // функция Win..., вызванная из окна напрямую
    wnkSetup,     // setup(): начальный переход
    wnkMissing);  // номер, на который есть переход, а ветки case нет

  TWmEdgeKind = (
    wekMenu,      // пункт TMenuItem
    wekCode,      // присваивание в коде окна
    wekCall);     // прямой вызов функции

  TWmNode = class
  public
    Kind: TWmNodeKind;
    State: Integer;         // номер окна; у wnkModal, wnkSetup - 0
    FuncName: string;       // Win25, setup; у wnkMissing - ''
    Caption: string;        // комментарий у заголовка функции или у case
    FileName: string;       // где функция ('' - не найдена)
    Line: Integer;          // строка заголовка функции, -1 - не найдена
    CaseFile: string;       // где ветка case этого номера
    CaseLine: Integer;
    Reachable: Boolean;     // есть путь от setup() (или от начального окна)
    // Место на карте (левый верхний угол), задаёт расстановка или файл
    // .winmap; PosSet - место из файла
    PosX, PosY: Integer;
    PosSet: Boolean;
    function Key: string;   // имя для файла .winmap: Win25, setup
    function Title: string; // первая строка подписи узла
  end;

  TWmEdge = class
  public
    Kind: TWmEdgeKind;
    FromNode, ToNode: TWmNode;
    Keys: string;           // "1", "Ent", "#, Esc"; у действия - и его имя
    Action: string;         // actRepeat, actHelp - переход внутри окна
    Cond: string;           // условие, в котором стоит переход (код)
    FileName: string;       // строка пункта меню или присваивания
    Line: Integer;
  end;

  // Файл скетча для разбора: имя и текст
  TWmMap = class
  private
    FNodes: TList;
    FEdges: TList;
    FFiles: TStringList;      // имена файлов; Objects - нет
    FTexts: TStringList;      // тексты файлов, по номерам FFiles
    FToks: TList;             // слова всех файлов подряд
    FFuncs: TList;            // TWmFunc
    FDefines: TStringList;    // Name=Value
    FStateVar: string;
    FSwitchFile: string;
    FSwitchLine: Integer;
    FInitialState: Integer;
    FHasInitial: Boolean;
    procedure Clear;
    procedure Tokenize(AFileIdx: Integer);
    function Tok(AIdx: Integer): TObject;
    function TokText(AIdx: Integer): string;
    function IsPunct(AIdx: Integer; const AText: string): Boolean;
    function MatchClose(AOpen: Integer): Integer;
    function MatchOpen(AClose: Integer): Integer;
    procedure ScanFuncs;
    function FuncByName(const AName: string): TObject;
    function FuncOfTok(AIdx: Integer): TObject;
    procedure FindSwitch;
    procedure FindInitial;
    procedure ScanMenus;
    procedure ScanAssignments;
    procedure ScanCalls;
    procedure MarkReachable;
    function HeaderComment(AFileIdx, ALine: Integer): string;
    function CondAt(AIdx, ABodyStart: Integer; var ACond: string): string;
    function NumberOf(const AText: string; var AValue: Integer): Boolean;
    function NodeOfState(AState: Integer; ACreate: Boolean): TWmNode;
    function NodeOfFunc(const AName: string): TWmNode;
    function AddEdge(AKind: TWmEdgeKind; AFrom, ATo: TWmNode;
      const AKeys, AAction, ACond, AFile: string; ALine: Integer): TWmEdge;
    function GetNode(AIdx: Integer): TWmNode;
    function GetEdge(AIdx: Integer): TWmEdge;
  public
    constructor Create;
    destructor Destroy; override;
    // Файлы скетча (главный .ino первым, затем подключённые .h и другие
    // .ino папки) - до Parse
    procedure AddFile(const AFileName, AText: string);
    procedure Parse;
    function NodeCount: Integer;
    function EdgeCount: Integer;
    property Nodes[AIdx: Integer]: TWmNode read GetNode;
    property Edges[AIdx: Integer]: TWmEdge read GetEdge;
    function NodeByKey(const AKey: string): TWmNode;
    // Переменная номера окна (WinState) и где её switch: туда эмулятор
    // доходит, прежде чем открыть окно
    property StateVar: string read FStateVar;
    property SwitchFile: string read FSwitchFile;
    property SwitchLine: Integer read FSwitchLine;
    // Расставить узлы без места из файла: столбцы по числу переходов от
    // setup(); недостижимые - в последнем столбце. ACellW, ACellH - шаг
    procedure AutoLayout(ACellW, ACellH: Integer; AOnlyUnset: Boolean);
    // Места узлов: файл .winmap (ini, секция [Nodes], Ключ=x,y)
    procedure LoadPositions(const AIniFile: string);
    procedure SavePositions(const AIniFile: string);
  end;

// Файл мест для скетча: папка скетча\Имя.winmap
function WmMapFileOf(const ASketchFile: string): string;

implementation

uses
  IniFiles;

type
  TWmTokKind = (wtkIdent, wtkNumber, wtkString, wtkChar, wtkPunct);

  TWmTok = class
  public
    Kind: TWmTokKind;
    Text: string;
    FileIdx: Integer;
    Line: Integer;
  end;

  TWmFunc = class
  public
    Name: string;
    FileIdx: Integer;
    Line: Integer;            // строка имени в заголовке
    BodyOpen, BodyClose: Integer;  // номера слов { и }
  end;

const
  IdentStart = ['A'..'Z', 'a'..'z', '_'];
  IdentChars = ['A'..'Z', 'a'..'z', '0'..'9', '_'];

function WmMapFileOf(const ASketchFile: string): string;
begin
  Result := ChangeFileExt(ASketchFile, '.winmap');
end;

{ TWmNode }

function TWmNode.Key: string;
begin
  if FuncName <> '' then
    Result := FuncName
  else
    Result := 'State' + IntToStr(State);
end;

function TWmNode.Title: string;
begin
  case Kind of
    wnkWindow:
      Result := FuncName + '  (' + IntToStr(State) + ')';
    wnkMissing:
      Result := IntToStr(State) + ': нет окна';
  else
    Result := FuncName + '()';
  end;
end;

{ TWmMap }

constructor TWmMap.Create;
begin
  inherited Create;
  FNodes := TList.Create;
  FEdges := TList.Create;
  FFiles := TStringList.Create;
  FTexts := TStringList.Create;
  FToks := TList.Create;
  FFuncs := TList.Create;
  FDefines := TStringList.Create;
  FSwitchLine := -1;
end;

destructor TWmMap.Destroy;
begin
  Clear;
  FNodes.Free;
  FEdges.Free;
  FFiles.Free;
  FTexts.Free;
  FToks.Free;
  FFuncs.Free;
  FDefines.Free;
  inherited Destroy;
end;

procedure TWmMap.Clear;
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to FNodes.Count - 1 do
    TObject(FNodes[ItemIdx]).Free;
  FNodes.Clear;
  for ItemIdx := 0 to FEdges.Count - 1 do
    TObject(FEdges[ItemIdx]).Free;
  FEdges.Clear;
  for ItemIdx := 0 to FToks.Count - 1 do
    TObject(FToks[ItemIdx]).Free;
  FToks.Clear;
  for ItemIdx := 0 to FFuncs.Count - 1 do
    TObject(FFuncs[ItemIdx]).Free;
  FFuncs.Clear;
  FDefines.Clear;
  FStateVar := '';
  FSwitchFile := '';
  FSwitchLine := -1;
  FHasInitial := False;
end;

procedure TWmMap.AddFile(const AFileName, AText: string);
begin
  FFiles.Add(AFileName);
  FTexts.Add(AText);
end;

function TWmMap.GetNode(AIdx: Integer): TWmNode;
begin
  Result := TWmNode(FNodes[AIdx]);
end;

function TWmMap.GetEdge(AIdx: Integer): TWmEdge;
begin
  Result := TWmEdge(FEdges[AIdx]);
end;

function TWmMap.NodeCount: Integer;
begin
  Result := FNodes.Count;
end;

function TWmMap.EdgeCount: Integer;
begin
  Result := FEdges.Count;
end;

function TWmMap.NodeByKey(const AKey: string): TWmNode;
var
  NodeIdx: Integer;
begin
  for NodeIdx := 0 to FNodes.Count - 1 do
  begin
    Result := TWmNode(FNodes[NodeIdx]);
    if CompareText(Result.Key, AKey) = 0 then
      Exit;
  end;
  Result := nil;
end;

function TWmMap.Tok(AIdx: Integer): TObject;
begin
  if (AIdx >= 0) and (AIdx < FToks.Count) then
    Result := TObject(FToks[AIdx])
  else
    Result := nil;
end;

function TWmMap.TokText(AIdx: Integer): string;
begin
  if (AIdx >= 0) and (AIdx < FToks.Count) then
    Result := TWmTok(FToks[AIdx]).Text
  else
    Result := '';
end;

function TWmMap.IsPunct(AIdx: Integer; const AText: string): Boolean;
begin
  Result := (AIdx >= 0) and (AIdx < FToks.Count) and
            (TWmTok(FToks[AIdx]).Kind = wtkPunct) and
            (TWmTok(FToks[AIdx]).Text = AText);
end;

// Слова одного файла: комментарии и строки препроцессора пропускаются,
// #define ИМЯ значение - в FDefines
procedure TWmMap.Tokenize(AFileIdx: Integer);
var
  Text, Word, DefLine: string;
  CharPos, Len, Line, StartPos: Integer;
  Ch: Char;
  NewTok: TWmTok;

  procedure Add(AKind: TWmTokKind; const AText: string; ALine: Integer);
  begin
    NewTok := TWmTok.Create;
    NewTok.Kind := AKind;
    NewTok.Text := AText;
    NewTok.FileIdx := AFileIdx;
    NewTok.Line := ALine;
    FToks.Add(NewTok);
  end;

  procedure DefineLine(const AText: string);
  var
    Body, Name, Value: string;
    CutPos: Integer;
  begin
    Body := Trim(AText);
    if Copy(Body, 1, 1) <> '#' then
      Exit;
    Body := Trim(Copy(Body, 2, MaxInt));
    if Copy(Body, 1, 6) <> 'define' then
      Exit;
    Body := Trim(Copy(Body, 7, MaxInt));
    CutPos := 1;
    while (CutPos <= Length(Body)) and (Body[CutPos] in IdentChars) do
      Inc(CutPos);
    Name := Copy(Body, 1, CutPos - 1);
    if (Name = '') or ((CutPos <= Length(Body)) and (Body[CutPos] = '(')) then
      Exit;
    Value := Copy(Body, CutPos, MaxInt);
    CutPos := Pos('//', Value);
    if CutPos > 0 then
      Value := Copy(Value, 1, CutPos - 1);
    Value := Trim(Value);
    if FDefines.IndexOfName(Name) < 0 then
      FDefines.Add(Name + '=' + Value);
  end;

begin
  Text := FTexts[AFileIdx];
  Len := Length(Text);
  CharPos := 1;
  Line := 0;
    while CharPos <= Len do
    begin
      Ch := Text[CharPos];
      if Ch = #10 then
      begin
        Inc(Line);
        Inc(CharPos);
      end
      else if Ch = #13 then
      begin
        Inc(Line);
        Inc(CharPos);
        if (CharPos <= Len) and (Text[CharPos] = #10) then
          Inc(CharPos);
      end
      else if Ch in [' ', #9, #12, #11] then
        Inc(CharPos)
      else if (Ch = '/') and (CharPos < Len) and (Text[CharPos + 1] = '/') then
      begin
        while (CharPos <= Len) and not (Text[CharPos] in [#10, #13]) do
          Inc(CharPos);
      end
      else if (Ch = '/') and (CharPos < Len) and (Text[CharPos + 1] = '*') then
      begin
        Inc(CharPos, 2);
        while (CharPos <= Len) and
              not ((Text[CharPos] = '*') and (CharPos < Len) and (Text[CharPos + 1] = '/')) do
        begin
          if Text[CharPos] = #10 then
            Inc(Line)
          else if (Text[CharPos] = #13) and not ((CharPos < Len) and (Text[CharPos + 1] = #10)) then
            Inc(Line);
          Inc(CharPos);
        end;
        Inc(CharPos, 2);
      end
      else if Ch = '#' then
      begin
        // строка препроцессора (с продолжениями \)
        StartPos := CharPos;
        DefLine := '';
        repeat
          while (CharPos <= Len) and not (Text[CharPos] in [#10, #13]) do
            Inc(CharPos);
          DefLine := DefLine + Copy(Text, StartPos, CharPos - StartPos);
          if (CharPos > StartPos) and (Text[CharPos - 1] = '\') and (CharPos <= Len) then
          begin
            Delete(DefLine, Length(DefLine), 1);
            if Text[CharPos] = #13 then
              Inc(CharPos);
            if (CharPos <= Len) and (Text[CharPos] = #10) then
              Inc(CharPos);
            Inc(Line);
            StartPos := CharPos;
          end
          else
            Break;
        until CharPos > Len;
        DefineLine(DefLine);
      end
      else if Ch in IdentStart then
      begin
        StartPos := CharPos;
        while (CharPos <= Len) and (Text[CharPos] in IdentChars) do
          Inc(CharPos);
        Add(wtkIdent, Copy(Text, StartPos, CharPos - StartPos), Line);
      end
      else if Ch in ['0'..'9'] then
      begin
        StartPos := CharPos;
        while (CharPos <= Len) and (Text[CharPos] in IdentChars + ['.']) do
          Inc(CharPos);
        Add(wtkNumber, Copy(Text, StartPos, CharPos - StartPos), Line);
      end
      else if (Ch = '"') or (Ch = '''') then
      begin
        StartPos := CharPos;
        Inc(CharPos);
        Word := '';
        while (CharPos <= Len) and (Text[CharPos] <> Ch) and not (Text[CharPos] in [#10, #13]) do
        begin
          if (Text[CharPos] = '\') and (CharPos < Len) then
          begin
            Word := Word + Text[CharPos + 1];
            Inc(CharPos, 2);
          end
          else
          begin
            Word := Word + Text[CharPos];
            Inc(CharPos);
          end;
        end;
        Inc(CharPos);
        if Ch = '"' then
          Add(wtkString, Word, Line)
        else
          Add(wtkChar, Word, Line);
      end
      else
      begin
        Word := Copy(Text, CharPos, 2);
        if (Word = '==') or (Word = '!=') or (Word = '<=') or (Word = '>=') or
           (Word = '&&') or (Word = '||') or (Word = '->') or (Word = '++') or
           (Word = '--') or (Word = '+=') or (Word = '-=') or (Word = '*=') or
           (Word = '/=') or (Word = '::') or (Word = '<<') or (Word = '>>') or
           (Word = '|=') or (Word = '&=') then
        begin
          Add(wtkPunct, Word, Line);
          Inc(CharPos, 2);
        end
        else
        begin
          Add(wtkPunct, Ch, Line);
          Inc(CharPos);
        end;
      end;
    end;
end;

function TWmMap.MatchClose(AOpen: Integer): Integer;
var
  Depth: Integer;
  OpenText, CloseText: string;
begin
  OpenText := TokText(AOpen);
  if OpenText = '(' then
    CloseText := ')'
  else if OpenText = '[' then
    CloseText := ']'
  else
    CloseText := '}';
  Depth := 0;
  Result := AOpen;
  while Result < FToks.Count do
  begin
    if IsPunct(Result, OpenText) then
      Inc(Depth)
    else if IsPunct(Result, CloseText) then
    begin
      Dec(Depth);
      if Depth = 0 then
        Exit;
    end;
    Inc(Result);
  end;
  Result := -1;
end;

function TWmMap.MatchOpen(AClose: Integer): Integer;
var
  Depth: Integer;
  OpenText, CloseText: string;
begin
  CloseText := TokText(AClose);
  if CloseText = ')' then
    OpenText := '('
  else if CloseText = ']' then
    OpenText := '['
  else
    OpenText := '{';
  Depth := 0;
  Result := AClose;
  while Result >= 0 do
  begin
    if IsPunct(Result, CloseText) then
      Inc(Depth)
    else if IsPunct(Result, OpenText) then
    begin
      Dec(Depth);
      if Depth = 0 then
        Exit;
    end;
    Dec(Result);
  end;
end;

// Функции с телом: Имя ( ... ) { на верхнем уровне файла
procedure TWmMap.ScanFuncs;
var
  TokIdx, CloseIdx, Depth: Integer;
  Cur: TWmTok;
  Func: TWmFunc;
begin
  Depth := 0;
  TokIdx := 0;
  while TokIdx < FToks.Count do
  begin
    Cur := TWmTok(FToks[TokIdx]);
    if (Cur.Kind = wtkPunct) and (Cur.Text = '{') then
      Inc(Depth)
    else if (Cur.Kind = wtkPunct) and (Cur.Text = '}') then
    begin
      if Depth > 0 then
        Dec(Depth);
    end
    else if (Depth = 0) and (Cur.Kind = wtkIdent) and IsPunct(TokIdx + 1, '(') and
            (TokIdx > 0) and (TWmTok(FToks[TokIdx - 1]).Kind = wtkIdent) and
            (TWmTok(FToks[TokIdx - 1]).FileIdx = Cur.FileIdx) then
    begin
      CloseIdx := MatchClose(TokIdx + 1);
      if (CloseIdx > 0) and IsPunct(CloseIdx + 1, '{') then
      begin
        Func := TWmFunc.Create;
        Func.Name := Cur.Text;
        Func.FileIdx := Cur.FileIdx;
        Func.Line := Cur.Line;
        Func.BodyOpen := CloseIdx + 1;
        Func.BodyClose := MatchClose(CloseIdx + 1);
        if Func.BodyClose < 0 then
          Func.BodyClose := FToks.Count - 1;
        FFuncs.Add(Func);
        TokIdx := Func.BodyClose + 1;
        Continue;
      end;
    end;
    Inc(TokIdx);
  end;
end;

function TWmMap.FuncByName(const AName: string): TObject;
var
  FuncIdx: Integer;
begin
  for FuncIdx := 0 to FFuncs.Count - 1 do
    if TWmFunc(FFuncs[FuncIdx]).Name = AName then
    begin
      Result := TWmFunc(FFuncs[FuncIdx]);
      Exit;
    end;
  Result := nil;
end;

function TWmMap.FuncOfTok(AIdx: Integer): TObject;
var
  FuncIdx: Integer;
  Func: TWmFunc;
begin
  for FuncIdx := 0 to FFuncs.Count - 1 do
  begin
    Func := TWmFunc(FFuncs[FuncIdx]);
    if (AIdx > Func.BodyOpen) and (AIdx < Func.BodyClose) then
    begin
      Result := Func;
      Exit;
    end;
  end;
  Result := nil;
end;

// Комментарий // в строке ALine файла: подпись окна без !, * и =
function TWmMap.HeaderComment(AFileIdx, ALine: Integer): string;
var
  Lines: TStringList;
  CutPos: Integer;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := FTexts[AFileIdx];
    if (ALine < 0) or (ALine >= Lines.Count) then
      Exit;
    CutPos := Pos('//', Lines[ALine]);
    if CutPos = 0 then
      Exit;
    Result := Copy(Lines[ALine], CutPos + 2, MaxInt);
  finally
    Lines.Free;
  end;
  while (Result <> '') and (Result[1] in ['!', '*', '=', ' ', '-', #9, '/']) do
    Delete(Result, 1, 1);
  while (Result <> '') and (Result[Length(Result)] in ['!', '*', '=', ' ', '-', #9, ';']) do
    Delete(Result, Length(Result), 1);
  if Length(Result) > 34 then
    Result := Copy(Result, 1, 32) + '..';
end;

function TWmMap.NumberOf(const AText: string; var AValue: Integer): Boolean;
var
  Value: string;
  Depth: Integer;
begin
  Value := Trim(AText);
  Depth := 0;
  // имя #define - его значение (до 4 ступеней)
  while (Value <> '') and (Value[1] in IdentStart) and (Depth < 4) and
        (FDefines.IndexOfName(Value) >= 0) do
  begin
    Value := Trim(FDefines.Values[Value]);
    Inc(Depth);
  end;
  if (Length(Value) > 2) and (Value[1] = '(') and (Value[Length(Value)] = ')') then
    Value := Trim(Copy(Value, 2, Length(Value) - 2));
  Value := StringReplace(Value, ' ', '', [rfReplaceAll]);
  Result := TryStrToInt(Value, AValue);
end;

function TWmMap.NodeOfState(AState: Integer; ACreate: Boolean): TWmNode;
var
  NodeIdx: Integer;
begin
  for NodeIdx := 0 to FNodes.Count - 1 do
  begin
    Result := TWmNode(FNodes[NodeIdx]);
    if (Result.Kind in [wnkWindow, wnkMissing]) and (Result.State = AState) then
      Exit;
  end;
  Result := nil;
  if not ACreate then
    Exit;
  Result := TWmNode.Create;
  Result.Kind := wnkMissing;
  Result.State := AState;
  Result.Line := -1;
  Result.CaseLine := -1;
  FNodes.Add(Result);
end;

function TWmMap.NodeOfFunc(const AName: string): TWmNode;
var
  NodeIdx: Integer;
begin
  for NodeIdx := 0 to FNodes.Count - 1 do
  begin
    Result := TWmNode(FNodes[NodeIdx]);
    if Result.FuncName = AName then
      Exit;
  end;
  Result := nil;
end;

function TWmMap.AddEdge(AKind: TWmEdgeKind; AFrom, ATo: TWmNode;
  const AKeys, AAction, ACond, AFile: string; ALine: Integer): TWmEdge;
var
  EdgeIdx: Integer;
  KeyList: TStringList;
begin
  // тот же переход ещё раз (два места с '#' -> 0): клавиши - в один
  for EdgeIdx := 0 to FEdges.Count - 1 do
  begin
    Result := TWmEdge(FEdges[EdgeIdx]);
    if (Result.Kind = AKind) and (Result.FromNode = AFrom) and
       (Result.ToNode = ATo) and (Result.Action = AAction) then
    begin
      if AKeys <> '' then
      begin
        KeyList := TStringList.Create;
        try
          KeyList.CommaText := StringReplace(Result.Keys, ', ', ',', [rfReplaceAll]);
          if (Result.Keys = '') or (KeyList.IndexOf(AKeys) < 0) then
          begin
            if Result.Keys = '' then
              Result.Keys := AKeys
            else
              Result.Keys := Result.Keys + ', ' + AKeys;
          end;
        finally
          KeyList.Free;
        end;
      end;
      Exit;
    end;
  end;
  Result := TWmEdge.Create;
  Result.Kind := AKind;
  Result.FromNode := AFrom;
  Result.ToNode := ATo;
  Result.Keys := AKeys;
  Result.Action := AAction;
  Result.Cond := ACond;
  Result.FileName := AFile;
  Result.Line := ALine;
  FEdges.Add(Result);
end;

// switch (Имя) { case N: Функция(); ... } - с наибольшим числом таких
// веток (не меньше трёх): окна
procedure TWmMap.FindSwitch;
var
  TokIdx, BlockOpen, BlockClose, ScanIdx, Count, BestCount, Number: Integer;
  BestIdx: Integer;
  Func: TWmFunc;
  Node: TWmNode;
  CaseTok: TWmTok;
begin
  BestCount := 0;
  BestIdx := -1;
  for TokIdx := 0 to FToks.Count - 6 do
    if (TWmTok(FToks[TokIdx]).Kind = wtkIdent) and (TokText(TokIdx) = 'switch') and
       IsPunct(TokIdx + 1, '(') and (TWmTok(FToks[TokIdx + 2]).Kind = wtkIdent) and
       IsPunct(TokIdx + 3, ')') and IsPunct(TokIdx + 4, '{') then
    begin
      BlockClose := MatchClose(TokIdx + 4);
      if BlockClose < 0 then
        Continue;
      Count := 0;
      for ScanIdx := TokIdx + 5 to BlockClose - 4 do
        if (TokText(ScanIdx) = 'case') and IsPunct(ScanIdx + 2, ':') and
           (TWmTok(FToks[ScanIdx + 3]).Kind = wtkIdent) and IsPunct(ScanIdx + 4, '(') then
          Inc(Count);
      if Count > BestCount then
      begin
        BestCount := Count;
        BestIdx := TokIdx;
      end;
    end;
  if BestCount < 3 then
    Exit;
  FStateVar := TokText(BestIdx + 2);
  FSwitchFile := FFiles[TWmTok(FToks[BestIdx]).FileIdx];
  FSwitchLine := TWmTok(FToks[BestIdx]).Line;
  BlockOpen := BestIdx + 4;
  BlockClose := MatchClose(BlockOpen);
  for ScanIdx := BlockOpen + 1 to BlockClose - 4 do
    if (TokText(ScanIdx) = 'case') and IsPunct(ScanIdx + 2, ':') and
       (TWmTok(FToks[ScanIdx + 3]).Kind = wtkIdent) and IsPunct(ScanIdx + 4, '(') and
       NumberOf(TokText(ScanIdx + 1), Number) and (NodeOfState(Number, False) = nil) then
    begin
      CaseTok := TWmTok(FToks[ScanIdx]);
      Node := TWmNode.Create;
      Node.Kind := wnkWindow;
      Node.State := Number;
      Node.FuncName := TokText(ScanIdx + 3);
      Node.CaseFile := FFiles[CaseTok.FileIdx];
      Node.CaseLine := CaseTok.Line;
      Node.Line := -1;
      Func := TWmFunc(FuncByName(Node.FuncName));
      if Func <> nil then
      begin
        Node.FileName := FFiles[Func.FileIdx];
        Node.Line := Func.Line;
        Node.Caption := HeaderComment(Func.FileIdx, Func.Line);
      end;
      if Node.Caption = '' then
        Node.Caption := HeaderComment(TWmTok(FToks[ScanIdx + 3]).FileIdx,
                                      TWmTok(FToks[ScanIdx + 3]).Line);
      FNodes.Add(Node);
    end;
end;

// Начальное значение: [static] [volatile] int Имя = число; вне функций
procedure TWmMap.FindInitial;
var
  TokIdx, Number: Integer;
begin
  for TokIdx := 1 to FToks.Count - 3 do
    if (TokText(TokIdx) = FStateVar) and IsPunct(TokIdx + 1, '=') and
       (TWmTok(FToks[TokIdx - 1]).Kind = wtkIdent) and (FuncOfTok(TokIdx) = nil) and
       NumberOf(TokText(TokIdx + 2), Number) then
    begin
      FInitialState := Number;
      FHasInitial := True;
      Exit;
    end;
end;

// Массивы const TMenuItem Имя[] = { {Label, Key, Target, Param}, ... } и
// тела окон, которые их упоминают
procedure TWmMap.ScanMenus;
type
  TMenuItemRec = record
    Key, TargetText: string;
    Line, FileIdx: Integer;
  end;
var
  TokIdx, ListOpen, ListClose, ItemOpen, ItemClose, FieldIdx, ScanIdx: Integer;
  RefIdx, ItemIdx, Target, NodeIdx: Integer;
  MenuName, FieldText: string;
  Items: array of TMenuItemRec;
  Fields: TStringList;
  Func: TWmFunc;
  FromNode, ToNode: TWmNode;
  Used: Boolean;
begin
  Fields := TStringList.Create;
  try
    TokIdx := 0;
    while TokIdx < FToks.Count - 6 do
    begin
      if (TokText(TokIdx) = 'TMenuItem') and (TWmTok(FToks[TokIdx + 1]).Kind = wtkIdent) and
         IsPunct(TokIdx + 2, '[') and IsPunct(TokIdx + 3, ']') and
         IsPunct(TokIdx + 4, '=') and IsPunct(TokIdx + 5, '{') and
         (FuncOfTok(TokIdx) = nil) then
      begin
        MenuName := TokText(TokIdx + 1);
        ListOpen := TokIdx + 5;
        ListClose := MatchClose(ListOpen);
        if ListClose < 0 then
          Break;
        SetLength(Items, 0);
        ItemOpen := ListOpen + 1;
        while ItemOpen < ListClose do
        begin
          if not IsPunct(ItemOpen, '{') then
          begin
            Inc(ItemOpen);
            Continue;
          end;
          ItemClose := MatchClose(ItemOpen);
          if (ItemClose < 0) or (ItemClose > ListClose) then
            Break;
          // поля через запятую
          Fields.Clear;
          FieldText := '';
          for ScanIdx := ItemOpen + 1 to ItemClose - 1 do
            if IsPunct(ScanIdx, ',') then
            begin
              Fields.Add(FieldText);
              FieldText := '';
            end
            else
              FieldText := FieldText + TokText(ScanIdx);
          Fields.Add(FieldText);
          if Fields.Count >= 3 then
          begin
            SetLength(Items, Length(Items) + 1);
            FieldIdx := High(Items);
            // Key - строка: в FieldText без кавычек (слово wtkString)
            Items[FieldIdx].Key := Fields[1];
            Items[FieldIdx].TargetText := Fields[2];
            Items[FieldIdx].Line := TWmTok(FToks[ItemOpen]).Line;
            Items[FieldIdx].FileIdx := TWmTok(FToks[ItemOpen]).FileIdx;
          end;
          ItemOpen := ItemClose + 1;
        end;
        // окна, в теле которых упомянут этот массив
        for NodeIdx := 0 to FNodes.Count - 1 do
        begin
          FromNode := TWmNode(FNodes[NodeIdx]);
          if FromNode.Kind <> wnkWindow then
            Continue;
          Func := TWmFunc(FuncByName(FromNode.FuncName));
          if Func = nil then
            Continue;
          Used := False;
          for RefIdx := Func.BodyOpen + 1 to Func.BodyClose - 1 do
            if TokText(RefIdx) = MenuName then
            begin
              Used := True;
              Break;
            end;
          if not Used then
            Continue;
          for ItemIdx := 0 to High(Items) do
          begin
            if NumberOf(Items[ItemIdx].TargetText, Target) and (Target >= 0) then
            begin
              ToNode := NodeOfState(Target, True);
              AddEdge(wekMenu, FromNode, ToNode, Items[ItemIdx].Key, '', '',
                      FFiles[Items[ItemIdx].FileIdx], Items[ItemIdx].Line);
            end
            else
              AddEdge(wekMenu, FromNode, FromNode, Items[ItemIdx].Key,
                      Items[ItemIdx].TargetText, '',
                      FFiles[Items[ItemIdx].FileIdx], Items[ItemIdx].Line);
          end;
        end;
        TokIdx := ListClose + 1;
        Continue;
      end;
      Inc(TokIdx);
    end;
  finally
    Fields.Free;
  end;
end;

// Условие, внутри которого стоит слово AIdx: if (...) перед ним или перед
// блоком { }, где оно стоит. Результат - строки в кавычках условия
// ("#", "Ent"), ACond - условие текстом
function TWmMap.CondAt(AIdx, ABodyStart: Integer; var ACond: string): string;
var
  ScanIdx, Depth, OpenIdx, ParenOpen, CondIdx: Integer;
  Cur: TWmTok;
begin
  Result := '';
  ACond := '';
  ParenOpen := -1;
  // if (...) Имя = ...; - без скобок блока
  if IsPunct(AIdx - 1, ')') then
  begin
    ParenOpen := MatchOpen(AIdx - 1);
    if (ParenOpen <= ABodyStart) or (TokText(ParenOpen - 1) <> 'if') then
      ParenOpen := -1;
  end;
  if ParenOpen < 0 then
  begin
    // блок, где стоит слово
    Depth := 0;
    OpenIdx := -1;
    ScanIdx := AIdx - 1;
    while ScanIdx > ABodyStart do
    begin
      if IsPunct(ScanIdx, '}') then
        Inc(Depth)
      else if IsPunct(ScanIdx, '{') then
      begin
        if Depth = 0 then
        begin
          OpenIdx := ScanIdx;
          Break;
        end;
        Dec(Depth);
      end;
      Dec(ScanIdx);
    end;
    if (OpenIdx > 0) and IsPunct(OpenIdx - 1, ')') then
    begin
      ParenOpen := MatchOpen(OpenIdx - 1);
      if (ParenOpen <= ABodyStart) or (TokText(ParenOpen - 1) <> 'if') then
        ParenOpen := -1;
    end;
  end;
  if ParenOpen < 0 then
    Exit;
  for CondIdx := ParenOpen + 1 to MatchClose(ParenOpen) - 1 do
  begin
    Cur := TWmTok(FToks[CondIdx]);
    if Cur.Kind = wtkString then
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + Cur.Text;
      ACond := ACond + '"' + Cur.Text + '"';
    end
    else
    begin
      if (ACond <> '') and (Cur.Kind in [wtkIdent, wtkNumber]) and
         (ACond[Length(ACond)] in IdentChars) then
        ACond := ACond + ' ';
      ACond := ACond + Cur.Text;
    end;
  end;
end;

// Имя = число в телах окон и setup()
procedure TWmMap.ScanAssignments;
var
  TokIdx, Number: Integer;
  Func: TWmFunc;
  FromNode, ToNode: TWmNode;
  Keys, Cond: string;
  Cur: TWmTok;
begin
  if FStateVar = '' then
    Exit;
  for TokIdx := 0 to FToks.Count - 3 do
  begin
    Cur := TWmTok(FToks[TokIdx]);
    if (Cur.Kind <> wtkIdent) or (Cur.Text <> FStateVar) or not IsPunct(TokIdx + 1, '=') or
       not NumberOf(TokText(TokIdx + 2), Number) or not IsPunct(TokIdx + 3, ';') then
      Continue;
    Func := TWmFunc(FuncOfTok(TokIdx));
    if Func = nil then
      Continue;
    FromNode := NodeOfFunc(Func.Name);
    if FromNode = nil then
      Continue;
    Keys := CondAt(TokIdx, Func.BodyOpen, Cond);
    if (FromNode.Kind = wnkWindow) and (Number = FromNode.State) and (Cond = '') then
      Continue;
    // if (item->Target == actHelp) - ветка пункта меню: переход уже из меню
    if Pos('->', Cond) > 0 then
      Continue;
    // переход в своё же окно по условию без клавиши (ошибка ввода и т.п.)
    // - не на карте
    if (Keys = '') and (FromNode.Kind = wnkWindow) and (Number = FromNode.State) then
      Continue;
    ToNode := NodeOfState(Number, True);
    if (Keys = '') and (Cond <> '') then
    begin
      Keys := Cond;
      if Length(Keys) > 24 then
        Keys := Copy(Keys, 1, 22) + '..';
    end;
    AddEdge(wekCode, FromNode, ToNode, Keys, '', Cond, FFiles[Cur.FileIdx], Cur.Line);
  end;
end;

// Win...() без ветки case, вызванные из окна напрямую
procedure TWmMap.ScanCalls;
var
  NodeIdx, TokIdx, ModalIdx: Integer;
  Node, ModalNode: TWmNode;
  Func, Callee: TWmFunc;
  Name, Keys, Cond: string;
  HasLoop: Boolean;
  WindowCount: Integer;
begin
  WindowCount := FNodes.Count;
  for NodeIdx := 0 to WindowCount - 1 do
  begin
    Node := TWmNode(FNodes[NodeIdx]);
    if Node.Kind <> wnkWindow then
      Continue;
    Func := TWmFunc(FuncByName(Node.FuncName));
    if Func = nil then
      Continue;
    for TokIdx := Func.BodyOpen + 1 to Func.BodyClose - 1 do
    begin
      Name := TokText(TokIdx);
      if (TWmTok(FToks[TokIdx]).Kind <> wtkIdent) or not IsPunct(TokIdx + 1, '(') or
         (CompareText(Copy(Name, 1, 3), 'win') <> 0) or IsPunct(TokIdx - 1, '.') or
         (NodeOfFunc(Name) <> nil) and (NodeOfFunc(Name).Kind = wnkWindow) then
        Continue;
      Callee := TWmFunc(FuncByName(Name));
      if Callee = nil then
        Continue;
      // окно-вызов ждёт клавишу: в теле есть цикл
      HasLoop := False;
      for ModalIdx := Callee.BodyOpen + 1 to Callee.BodyClose - 1 do
        if (TokText(ModalIdx) = 'while') or (TokText(ModalIdx) = 'for') then
        begin
          HasLoop := True;
          Break;
        end;
      if not HasLoop then
        Continue;
      ModalNode := NodeOfFunc(Name);
      if ModalNode = nil then
      begin
        ModalNode := TWmNode.Create;
        ModalNode.Kind := wnkModal;
        ModalNode.FuncName := Name;
        ModalNode.FileName := FFiles[Callee.FileIdx];
        ModalNode.Line := Callee.Line;
        ModalNode.CaseLine := -1;
        ModalNode.Caption := HeaderComment(Callee.FileIdx, Callee.Line);
        FNodes.Add(ModalNode);
      end;
      Keys := CondAt(TokIdx, Func.BodyOpen, Cond);
      AddEdge(wekCall, Node, ModalNode, Keys, '', Cond,
              FFiles[TWmTok(FToks[TokIdx]).FileIdx], TWmTok(FToks[TokIdx]).Line);
    end;
  end;
end;

procedure TWmMap.MarkReachable;
var
  Queue: TList;
  QueueIdx, EdgeIdx: Integer;
  Node: TWmNode;
  Edge: TWmEdge;
begin
  Queue := TList.Create;
  try
    Node := NodeOfFunc('setup');
    if Node = nil then
      Node := NodeOfState(FInitialState, False);
    if Node = nil then
      Exit;
    Node.Reachable := True;
    Queue.Add(Node);
    QueueIdx := 0;
    while QueueIdx < Queue.Count do
    begin
      Node := TWmNode(Queue[QueueIdx]);
      Inc(QueueIdx);
      for EdgeIdx := 0 to FEdges.Count - 1 do
      begin
        Edge := TWmEdge(FEdges[EdgeIdx]);
        if (Edge.FromNode = Node) and not Edge.ToNode.Reachable then
        begin
          Edge.ToNode.Reachable := True;
          Queue.Add(Edge.ToNode);
        end;
      end;
    end;
  finally
    Queue.Free;
  end;
end;

procedure TWmMap.Parse;
var
  FileIdx: Integer;
  SetupFunc: TWmFunc;
  SetupNode, StartNode: TWmNode;
begin
  Clear;
  for FileIdx := 0 to FFiles.Count - 1 do
    Tokenize(FileIdx);
  ScanFuncs;
  FindSwitch;
  if FStateVar = '' then
    Exit;
  FindInitial;
  SetupFunc := TWmFunc(FuncByName('setup'));
  if SetupFunc <> nil then
  begin
    SetupNode := TWmNode.Create;
    SetupNode.Kind := wnkSetup;
    SetupNode.FuncName := 'setup';
    SetupNode.FileName := FFiles[SetupFunc.FileIdx];
    SetupNode.Line := SetupFunc.Line;
    SetupNode.CaseLine := -1;
    FNodes.Insert(0, SetupNode);
    if FHasInitial then
    begin
      StartNode := NodeOfState(FInitialState, True);
      AddEdge(wekCode, SetupNode, StartNode, 'старт', '', '',
              SetupNode.FileName, SetupNode.Line);
    end;
  end;
  ScanMenus;
  ScanCalls;
  ScanAssignments;
  MarkReachable;
end;

procedure TWmMap.AutoLayout(ACellW, ACellH: Integer; AOnlyUnset: Boolean);
var
  Layer, Row: array of Integer;
  Desired: array of Double;
  NodeIdx, EdgeIdx, MaxLayer, LayerIdx, StartIdx, FromIdx, ToIdx: Integer;
  SortIdx, OtherIdx, PrevRow, PredCount, Swap: Integer;
  Node: TWmNode;
  Edge: TWmEdge;
  Changed: Boolean;
  Order: array of Integer;
  OrderCount: Integer;
  PredSum: Double;
begin
  SetLength(Layer, FNodes.Count);
  SetLength(Row, FNodes.Count);
  SetLength(Desired, FNodes.Count);
  SetLength(Order, FNodes.Count);
  for NodeIdx := 0 to FNodes.Count - 1 do
  begin
    Layer[NodeIdx] := -1;
    Row[NodeIdx] := -1;
  end;
  StartIdx := FNodes.IndexOf(NodeOfFunc('setup'));
  if StartIdx < 0 then
    StartIdx := FNodes.IndexOf(NodeOfState(FInitialState, False));
  if StartIdx >= 0 then
    Layer[StartIdx] := 0;
  // столбец - кратчайший путь (по числу переходов) от начала
  repeat
    Changed := False;
    for EdgeIdx := 0 to FEdges.Count - 1 do
    begin
      Edge := TWmEdge(FEdges[EdgeIdx]);
      if Edge.FromNode = Edge.ToNode then
        Continue;
      FromIdx := FNodes.IndexOf(Edge.FromNode);
      ToIdx := FNodes.IndexOf(Edge.ToNode);
      if (Layer[FromIdx] >= 0) and
         ((Layer[ToIdx] < 0) or (Layer[ToIdx] > Layer[FromIdx] + 1)) then
      begin
        Layer[ToIdx] := Layer[FromIdx] + 1;
        Changed := True;
      end;
    end;
  until not Changed;
  MaxLayer := 0;
  for NodeIdx := 0 to FNodes.Count - 1 do
    if Layer[NodeIdx] > MaxLayer then
      MaxLayer := Layer[NodeIdx];
  // недостижимые - столбец после всех
  for NodeIdx := 0 to FNodes.Count - 1 do
    if Layer[NodeIdx] < 0 then
      Layer[NodeIdx] := MaxLayer + 1;
  // строка - около средней строки окон, откуда в узел ведут переходы
  for LayerIdx := 0 to MaxLayer + 1 do
  begin
    OrderCount := 0;
    for NodeIdx := 0 to FNodes.Count - 1 do
      if Layer[NodeIdx] = LayerIdx then
      begin
        PredSum := 0;
        PredCount := 0;
        for EdgeIdx := 0 to FEdges.Count - 1 do
        begin
          Edge := TWmEdge(FEdges[EdgeIdx]);
          if (Edge.ToNode <> FNodes[NodeIdx]) or (Edge.FromNode = Edge.ToNode) then
            Continue;
          FromIdx := FNodes.IndexOf(Edge.FromNode);
          if (Layer[FromIdx] < LayerIdx) and (Row[FromIdx] >= 0) then
          begin
            PredSum := PredSum + Row[FromIdx];
            Inc(PredCount);
          end;
        end;
        if PredCount > 0 then
          Desired[NodeIdx] := PredSum / PredCount
        else
          Desired[NodeIdx] := 1000 + NodeIdx;
        Order[OrderCount] := NodeIdx;
        Inc(OrderCount);
      end;
    // по Desired, при равных - по порядку в списке (вставками)
    for SortIdx := 1 to OrderCount - 1 do
    begin
      OtherIdx := SortIdx;
      while (OtherIdx > 0) and (Desired[Order[OtherIdx - 1]] > Desired[Order[OtherIdx]]) do
      begin
        Swap := Order[OtherIdx - 1];
        Order[OtherIdx - 1] := Order[OtherIdx];
        Order[OtherIdx] := Swap;
        Dec(OtherIdx);
      end;
    end;
    PrevRow := -1;
    for SortIdx := 0 to OrderCount - 1 do
    begin
      NodeIdx := Order[SortIdx];
      if Desired[NodeIdx] >= 1000 then
        Row[NodeIdx] := PrevRow + 1
      else
      begin
        Row[NodeIdx] := Round(Desired[NodeIdx]);
        if Row[NodeIdx] <= PrevRow then
          Row[NodeIdx] := PrevRow + 1;
      end;
      PrevRow := Row[NodeIdx];
    end;
  end;
  for NodeIdx := 0 to FNodes.Count - 1 do
  begin
    Node := TWmNode(FNodes[NodeIdx]);
    if AOnlyUnset and Node.PosSet then
      Continue;
    Node.PosX := 16 + Layer[NodeIdx] * ACellW;
    Node.PosY := 16 + Row[NodeIdx] * ACellH;
  end;
end;

procedure TWmMap.LoadPositions(const AIniFile: string);
var
  Ini: TIniFile;
  NodeIdx, CommaPos, PosX, PosY: Integer;
  Node: TWmNode;
  Value: string;
begin
  if not FileExists(AIniFile) then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    for NodeIdx := 0 to FNodes.Count - 1 do
    begin
      Node := TWmNode(FNodes[NodeIdx]);
      Value := Ini.ReadString('Nodes', Node.Key, '');
      CommaPos := Pos(',', Value);
      if (CommaPos > 0) and TryStrToInt(Trim(Copy(Value, 1, CommaPos - 1)), PosX) and
         TryStrToInt(Trim(Copy(Value, CommaPos + 1, MaxInt)), PosY) then
      begin
        Node.PosX := PosX;
        Node.PosY := PosY;
        Node.PosSet := True;
      end;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TWmMap.SavePositions(const AIniFile: string);
var
  Ini: TIniFile;
  NodeIdx: Integer;
  Node: TWmNode;
begin
  Ini := TIniFile.Create(AIniFile);
  try
    for NodeIdx := 0 to FNodes.Count - 1 do
    begin
      Node := TWmNode(FNodes[NodeIdx]);
      Ini.WriteString('Nodes', Node.Key, IntToStr(Node.PosX) + ',' + IntToStr(Node.PosY));
    end;
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

end.
