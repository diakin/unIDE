unit ArdWinNew;

// ---------------------------------------------------------------------------
//  Новое окно скетча (конструктор окон, кнопка «Создать новое окно»).
//
//  Окно-образец - Win100 в BS10: функция WinN() с clrScr, Draw() надписей и
//  циклом RunMenu по массиву mnuWinN[] из файла форм. Новое окно пустое:
//  заголовок и один пункт - переход в следующее окно по клавише (Ent).
//
//  Что меняется (WnCreateWindow):
//   - файл форм (где массив меню предыдущего окна): надписи lblTitle_WinN,
//     lblNext_WinN и массив mnuWinN[] - после массива предыдущего окна;
//     в массиве предыдущего окна - Target пункта (вставка в переход) или
//     новый пункт с надписью lblToN_WinP (объявлена перед массивом);
//   - .ino: функция WinN() - после функции предыдущего окна, ветка
//     case N: WinN(); break; - после ветки предыдущего окна, у нового
//     пункта - его Draw() в функции предыдущего окна.
//  Стиль надписей берётся с надписей предыдущего окна (заголовок - верхняя,
//  пункт - пункт его меню). Окна без массива меню (переход кодом) не
//  меняются: WnCodeLines показывает строки переходов для ручной правки.
// ---------------------------------------------------------------------------

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, ArdWinMap;

type
  TWnParams = record
    PrevState: Integer;      // окно, из которого переход
    PrevKey: string;         // клавиша в нём: 1, Ent, #
    NextState: Integer;      // окно, куда ведёт новое
    NextKey: string;
    InsertInto: Boolean;     // пункт PrevKey (уже ведёт в NextState) -
                             // перенаправить на новое окно
    NewState: Integer;
    Title: string;           // текст заголовка, без кавычек
  end;

// Свободный номер окна рядом с APrev: APrev + 1, + 2, ...
function WnFreeState(AMap: TWmMap; APrev: Integer): Integer;
// Номер занят: есть ветка case, переход или функция WinN
function WnStateUsed(AMap: TWmMap; AState: Integer): Boolean;
// Клавиши пунктов меню (TMenuItem) окна ANode - через запятую
function WnMenuKeys(AMap: TWmMap; ANode: TWmNode): TStringList;
// Пункт меню ANode -> ATo (nil - нет); AKey <> '' - именно с этой клавишей
function WnMenuEdge(AMap: TWmMap; ANode, ATo: TWmNode; const AKey: string): TWmEdge;
// Строки переходов кодом из окна (для ручной правки): "файл:строка: текст"
function WnCodeLines(AMap: TWmMap; ANode: TWmNode): string;
// Файл и имя массива меню окна (по любому его пункту); False - массива нет
function WnMenuArray(AMap: TWmMap; ANode: TWmNode; var AFile, AArray: string;
  AFormsLines: TStringList): Boolean;

// Правка текстов: AForms - файл форм (где массив меню предыдущего окна),
// AIno - файл с функцией предыдущего окна и (тот же или другой) с веткой
// case. Если файлы совпадают, передаётся один и тот же список. AReport -
// что сделано (или почему нельзя)
function WnCreateWindow(AMap: TWmMap; const AParams: TWnParams;
  AForms, AIno, ACaseLines: TStringList; var AReport: string): Boolean;

type
  // Панель настройки нового окна
  TArdWinNewForm = class(TForm)
  private
    FMap: TWmMap;
    FWindows: TList;
    FPrevCombo, FPrevKeyCombo, FNextCombo, FNextKeyCombo: TComboBox;
    FInsertCheck: TCheckBox;
    FNumberEdit, FTitleEdit: TEdit;
    FInfo: TLabel;
    procedure PrevChange(Sender: TObject);
    procedure NextChange(Sender: TObject);
    procedure InsertClick(Sender: TObject);
    procedure OkClick(Sender: TObject);
    procedure FillKeys;
    function NodeOfCombo(ACombo: TComboBox): TWmNode;
    function AddLabel(const ACaption: string; ATop: Integer): TLabel;
    function AddCombo(ATop: Integer): TComboBox;
  public
    constructor CreateFor(AOwner: TComponent; AMap: TWmMap; ACurrent: Integer); reintroduce;
    destructor Destroy; override;
    function GetParams(var AParams: TWnParams): Boolean;
  end;

implementation

uses
  Dialogs;

const
  DigitKeys: array[0..9] of string = ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0');

function IsIdentChar(ACh: Char): Boolean;
begin
  Result := ACh in ['A'..'Z', 'a'..'z', '0'..'9', '_'];
end;

// Позиция слова AWord в AText (целиком), 0 - нет
function WordPos(const AWord, AText: string; AFrom: Integer): Integer;
var
  StartPos, Found: Integer;
  Rest: string;
begin
  Result := 0;
  StartPos := AFrom;
  while StartPos <= Length(AText) do
  begin
    Rest := Copy(AText, StartPos, MaxInt);
    Found := Pos(AWord, Rest);
    if Found = 0 then
      Exit;
    Found := Found + StartPos - 1;
    if ((Found = 1) or not IsIdentChar(AText[Found - 1])) and
       ((Found + Length(AWord) > Length(AText)) or
        not IsIdentChar(AText[Found + Length(AWord)])) then
    begin
      Result := Found;
      Exit;
    end;
    StartPos := Found + 1;
  end;
end;

function SplitKeys(const AKeys: string; AList: TStrings): Integer;
var
  Rest, Part: string;
  CommaPos: Integer;
begin
  Rest := AKeys;
  while Rest <> '' do
  begin
    CommaPos := Pos(',', Rest);
    if CommaPos = 0 then
    begin
      Part := Trim(Rest);
      Rest := '';
    end
    else
    begin
      Part := Trim(Copy(Rest, 1, CommaPos - 1));
      Rest := Copy(Rest, CommaPos + 1, MaxInt);
    end;
    // "1 actRepeat" - клавиша и действие
    if Pos(' ', Part) > 0 then
      Part := Copy(Part, 1, Pos(' ', Part) - 1);
    if (Part <> '') and (AList.IndexOf(Part) < 0) then
      AList.Add(Part);
  end;
  Result := AList.Count;
end;

function WnStateUsed(AMap: TWmMap; AState: Integer): Boolean;
var
  NodeIdx: Integer;
  Node: TWmNode;
begin
  Result := False;
  for NodeIdx := 0 to AMap.NodeCount - 1 do
  begin
    Node := AMap.Nodes[NodeIdx];
    if ((Node.Kind in [wnkWindow, wnkMissing]) and (Node.State = AState)) or
       (CompareText(Node.FuncName, 'Win' + IntToStr(AState)) = 0) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function WnFreeState(AMap: TWmMap; APrev: Integer): Integer;
begin
  Result := APrev + 1;
  while WnStateUsed(AMap, Result) and (Result < APrev + 1000) do
    Inc(Result);
end;

function WnMenuKeys(AMap: TWmMap; ANode: TWmNode): TStringList;
var
  EdgeIdx: Integer;
  Edge: TWmEdge;
begin
  Result := TStringList.Create;
  for EdgeIdx := 0 to AMap.EdgeCount - 1 do
  begin
    Edge := AMap.Edges[EdgeIdx];
    if (Edge.FromNode = ANode) and (Edge.Kind = wekMenu) then
      SplitKeys(Edge.Keys, Result);
  end;
end;

function WnMenuEdge(AMap: TWmMap; ANode, ATo: TWmNode; const AKey: string): TWmEdge;
var
  EdgeIdx: Integer;
  Edge: TWmEdge;
  Keys: TStringList;
begin
  Result := nil;
  Keys := TStringList.Create;
  try
    for EdgeIdx := 0 to AMap.EdgeCount - 1 do
    begin
      Edge := AMap.Edges[EdgeIdx];
      if (Edge.FromNode = ANode) and (Edge.ToNode = ATo) and (Edge.Kind = wekMenu) and
         (Edge.Action = '') then
      begin
        Keys.Clear;
        SplitKeys(Edge.Keys, Keys);
        if (AKey = '') or (Keys.IndexOf(AKey) >= 0) then
        begin
          Result := Edge;
          Exit;
        end;
      end;
    end;
  finally
    Keys.Free;
  end;
end;

function WnCodeLines(AMap: TWmMap; ANode: TWmNode): string;
var
  EdgeIdx: Integer;
  Edge: TWmEdge;
begin
  Result := '';
  for EdgeIdx := 0 to AMap.EdgeCount - 1 do
  begin
    Edge := AMap.Edges[EdgeIdx];
    if (Edge.FromNode = ANode) and (Edge.Kind = wekCode) and (Edge.ToNode <> nil) then
      Result := Result + ExtractFileName(Edge.FileName) + ':' + IntToStr(Edge.Line + 1) +
        ': -> ' + Edge.ToNode.Title + #13#10;
  end;
end;

// Имя массива на строке "const TMenuItem mnuWin100[] = {"
function ArrayNameOf(const ALine: string): string;
var
  StartPos, EndPos: Integer;
begin
  Result := '';
  StartPos := WordPos('TMenuItem', ALine, 1);
  if StartPos = 0 then
    Exit;
  StartPos := StartPos + Length('TMenuItem');
  while (StartPos <= Length(ALine)) and (ALine[StartPos] in [' ', #9, '*']) do
    Inc(StartPos);
  EndPos := StartPos;
  while (EndPos <= Length(ALine)) and IsIdentChar(ALine[EndPos]) do
    Inc(EndPos);
  Result := Copy(ALine, StartPos, EndPos - StartPos);
end;

function WnMenuArray(AMap: TWmMap; ANode: TWmNode; var AFile, AArray: string;
  AFormsLines: TStringList): Boolean;
var
  EdgeIdx, LineIdx: Integer;
  Edge: TWmEdge;
begin
  Result := False;
  AFile := '';
  AArray := '';
  for EdgeIdx := 0 to AMap.EdgeCount - 1 do
  begin
    Edge := AMap.Edges[EdgeIdx];
    if (Edge.FromNode = ANode) and (Edge.Kind = wekMenu) and (Edge.FileName <> '') then
    begin
      AFile := Edge.FileName;
      if AFormsLines = nil then
      begin
        Result := True;
        Exit;
      end;
      // массив - выше по файлу, строка с TMenuItem
      LineIdx := Edge.Line;
      if LineIdx >= AFormsLines.Count then
        LineIdx := AFormsLines.Count - 1;
      while (LineIdx >= 0) and (WordPos('TMenuItem', AFormsLines[LineIdx], 1) = 0) do
        Dec(LineIdx);
      if LineIdx >= 0 then
      begin
        AArray := ArrayNameOf(AFormsLines[LineIdx]);
        Result := AArray <> '';
      end;
      Exit;
    end;
  end;
end;

{ Правка текстов }

// Строка начала массива AArray и строка с '};' - его конец
function FindArray(ALines: TStringList; const AArray: string;
  var AStart, AEnd: Integer): Boolean;
var
  LineIdx: Integer;
begin
  Result := False;
  AStart := -1;
  AEnd := -1;
  for LineIdx := 0 to ALines.Count - 1 do
    if (WordPos('TMenuItem', ALines[LineIdx], 1) > 0) and
       (WordPos(AArray, ALines[LineIdx], 1) > 0) and (Pos('[', ALines[LineIdx]) > 0) then
    begin
      AStart := LineIdx;
      Break;
    end;
  if AStart < 0 then
    Exit;
  for LineIdx := AStart to ALines.Count - 1 do
    if Pos('};', ALines[LineIdx]) > 0 then
    begin
      AEnd := LineIdx;
      Result := True;
      Exit;
    end;
end;

// Объявление надписи: "... TLabel AName = {" ... "};"
function FindLabelDecl(ALines: TStringList; const AName: string;
  var AStart, AEnd: Integer): Boolean;
var
  LineIdx: Integer;
  LineText: string;
begin
  Result := False;
  AStart := -1;
  AEnd := -1;
  for LineIdx := 0 to ALines.Count - 1 do
  begin
    LineText := ALines[LineIdx];
    if (WordPos('TLabel', LineText, 1) > 0) and (WordPos(AName, LineText, 1) > 0) and
       (Pos('=', LineText) > 0) then
    begin
      AStart := LineIdx;
      Break;
    end;
  end;
  if AStart < 0 then
    Exit;
  for LineIdx := AStart to ALines.Count - 1 do
    if Pos('};', ALines[LineIdx]) > 0 then
    begin
      AEnd := LineIdx;
      Result := True;
      Exit;
    end;
end;

function FirstLabelName(ALines: TStringList): string;
var
  LineIdx, StartPos, EndPos: Integer;
  LineText: string;
begin
  Result := '';
  for LineIdx := 0 to ALines.Count - 1 do
  begin
    LineText := ALines[LineIdx];
    StartPos := WordPos('TLabel', LineText, 1);
    if (StartPos > 0) and (Pos('=', LineText) > 0) and (Pos('{', LineText) > 0) and
       (Pos('(', LineText) = 0) then
    begin
      StartPos := StartPos + Length('TLabel');
      while (StartPos <= Length(LineText)) and (LineText[StartPos] = ' ') do
        Inc(StartPos);
      EndPos := StartPos;
      while (EndPos <= Length(LineText)) and IsIdentChar(LineText[EndPos]) do
        Inc(EndPos);
      Result := Copy(LineText, StartPos, EndPos - StartPos);
      if Result <> '' then
        Exit;
    end;
  end;
end;

function DeclBlock(ALines: TStringList; const AName: string): string;
var
  StartLine, EndLine, LineIdx: Integer;
begin
  Result := '';
  if not FindLabelDecl(ALines, AName, StartLine, EndLine) then
    Exit;
  for LineIdx := StartLine to EndLine do
    Result := Result + ALines[LineIdx] + #10;
end;

// Позиция значения свойства после метки /*Tag*/ и его длина
function PropSpan(const ABlock, ATag: string; var AStart, ALen: Integer): Boolean;
var
  TagPos, CharPos: Integer;
begin
  Result := False;
  TagPos := Pos(ATag, ABlock);
  if TagPos = 0 then
    Exit;
  CharPos := TagPos + Length(ATag);
  while (CharPos <= Length(ABlock)) and (ABlock[CharPos] in [' ', #9]) do
    Inc(CharPos);
  AStart := CharPos;
  if (CharPos <= Length(ABlock)) and (ABlock[CharPos] = '"') then
  begin
    Inc(CharPos);
    while (CharPos <= Length(ABlock)) and (ABlock[CharPos] <> '"') do
    begin
      if ABlock[CharPos] = '\' then
        Inc(CharPos);
      Inc(CharPos);
    end;
    Inc(CharPos);
  end
  else
    while (CharPos <= Length(ABlock)) and not (ABlock[CharPos] in [',', '}', #10, #13]) do
      Inc(CharPos);
  ALen := CharPos - AStart;
  // пробелы перед запятой - не часть значения
  while (ALen > 0) and (ABlock[AStart + ALen - 1] = ' ') do
    Dec(ALen);
  Result := True;
end;

function PropGet(const ABlock, ATag: string): string;
var
  StartPos, Len: Integer;
begin
  Result := '';
  if PropSpan(ABlock, ATag, StartPos, Len) then
    Result := Copy(ABlock, StartPos, Len);
end;

function PropSet(const ABlock, ATag, AValue: string): string;
var
  StartPos, Len: Integer;
begin
  Result := ABlock;
  if PropSpan(ABlock, ATag, StartPos, Len) then
    Result := Copy(ABlock, 1, StartPos - 1) + AValue + Copy(ABlock, StartPos + Len, MaxInt);
end;

function CQuote(const AText: string): string;
var
  CharIdx: Integer;
begin
  Result := '"';
  for CharIdx := 1 to Length(AText) do
  begin
    if AText[CharIdx] in ['"', '\'] then
      Result := Result + '\';
    Result := Result + AText[CharIdx];
  end;
  Result := Result + '"';
end;

// Объявление новой надписи по образцу: имя, место, текст; комментарий
// образца после '{' убирается
function MakeLabel(const ATemplate, AOldName, ANewName: string;
  ALeft, ATop, AWidth, AHeight: Integer; const ACaption: string): string;
var
  NamePos, BracePos, LineEnd: Integer;
begin
  Result := ATemplate;
  NamePos := WordPos(AOldName, Result, 1);
  if NamePos > 0 then
    Result := Copy(Result, 1, NamePos - 1) + ANewName +
              Copy(Result, NamePos + Length(AOldName), MaxInt);
  BracePos := Pos('{', Result);
  if BracePos > 0 then
  begin
    LineEnd := BracePos;
    while (LineEnd <= Length(Result)) and (Result[LineEnd] <> #10) do
      Inc(LineEnd);
    Result := Copy(Result, 1, BracePos) + ' // unIDE: new window' +
              Copy(Result, LineEnd, MaxInt);
  end;
  Result := PropSet(Result, '/*Left*/', IntToStr(ALeft));
  Result := PropSet(Result, '/*Top*/', IntToStr(ATop));
  if AWidth >= 0 then
    Result := PropSet(Result, '/*Width*/', IntToStr(AWidth));
  if AHeight > 0 then
    Result := PropSet(Result, '/*Height*/', IntToStr(AHeight));
  Result := PropSet(Result, '/*Caption*/', CQuote(ACaption));
  Result := PropSet(Result, '/*Visible*/', '1');
end;

procedure InsertBlock(ALines: TStringList; AAt: Integer; const ABlock: string);
var
  Parts: TStringList;
  PartIdx: Integer;
  Text: string;
begin
  Text := ABlock;
  if (Text <> '') and (Text[Length(Text)] = #10) then
    Delete(Text, Length(Text), 1);
  Parts := TStringList.Create;
  try
    Parts.Text := Text;
    for PartIdx := Parts.Count - 1 downto 0 do
      ALines.Insert(AAt, Parts[PartIdx]);
  finally
    Parts.Free;
  end;
end;

// Имена надписей на строках пунктов массива: "&lblName"
procedure ItemLabels(ALines: TStringList; AStart, AEnd: Integer;
  ANames, AKeys: TStringList);
var
  LineIdx, AmpPos, EndPos, QuotePos, QuoteEnd: Integer;
  LineText, LabelName, KeyName: string;
begin
  for LineIdx := AStart to AEnd do
  begin
    LineText := ALines[LineIdx];
    AmpPos := Pos('&', LineText);
    if AmpPos = 0 then
      Continue;
    EndPos := AmpPos + 1;
    while (EndPos <= Length(LineText)) and IsIdentChar(LineText[EndPos]) do
      Inc(EndPos);
    LabelName := Copy(LineText, AmpPos + 1, EndPos - AmpPos - 1);
    KeyName := '';
    QuotePos := EndPos;
    while (QuotePos <= Length(LineText)) and (LineText[QuotePos] <> '"') do
      Inc(QuotePos);
    QuoteEnd := QuotePos + 1;
    while (QuoteEnd <= Length(LineText)) and (LineText[QuoteEnd] <> '"') do
      Inc(QuoteEnd);
    if QuoteEnd <= Length(LineText) then
      KeyName := Copy(LineText, QuotePos + 1, QuoteEnd - QuotePos - 1);
    ANames.Add(LabelName);
    AKeys.Add(KeyName);
  end;
end;

// На строке пункта с клавишей AKey - заменить номер окна (третье поле)
function RetargetItem(var ALine: string; const AKey: string; ATarget: Integer): Boolean;
var
  KeyPos, CharPos, NumStart: Integer;
begin
  Result := False;
  KeyPos := Pos('"' + AKey + '"', ALine);
  if KeyPos = 0 then
    Exit;
  CharPos := KeyPos + Length(AKey) + 2;
  while (CharPos <= Length(ALine)) and (ALine[CharPos] <> ',') do
    Inc(CharPos);
  if CharPos > Length(ALine) then
    Exit;
  Inc(CharPos);
  // пробелы и /*Target*/
  repeat
    while (CharPos <= Length(ALine)) and (ALine[CharPos] in [' ', #9]) do
      Inc(CharPos);
    if Copy(ALine, CharPos, 2) = '/*' then
    begin
      while (CharPos < Length(ALine)) and (Copy(ALine, CharPos, 2) <> '*/') do
        Inc(CharPos);
      Inc(CharPos, 2);
    end
    else
      Break;
  until CharPos > Length(ALine);
  NumStart := CharPos;
  while (CharPos <= Length(ALine)) and IsIdentChar(ALine[CharPos]) do
    Inc(CharPos);
  if CharPos = NumStart then
    Exit;
  ALine := Copy(ALine, 1, NumStart - 1) + IntToStr(ATarget) + Copy(ALine, CharPos, MaxInt);
  Result := True;
end;

// Строка закрывающей скобки функции, заголовок которой на AHeader
function FuncEndLine(ALines: TStringList; AHeader: Integer): Integer;
var
  LineIdx, CharIdx, Depth: Integer;
  LineText: string;
  Started, InBlock, InStr: Boolean;
  Quote: Char;
begin
  Result := -1;
  Depth := 0;
  Started := False;
  InBlock := False;
  Quote := '"';
  for LineIdx := AHeader to ALines.Count - 1 do
  begin
    LineText := ALines[LineIdx];
    InStr := False;
    CharIdx := 1;
    while CharIdx <= Length(LineText) do
    begin
      if InBlock then
      begin
        if Copy(LineText, CharIdx, 2) = '*/' then
        begin
          InBlock := False;
          Inc(CharIdx);
        end;
      end
      else if InStr then
      begin
        if LineText[CharIdx] = '\' then
          Inc(CharIdx)
        else if LineText[CharIdx] = Quote then
          InStr := False;
      end
      else if Copy(LineText, CharIdx, 2) = '//' then
        Break
      else if Copy(LineText, CharIdx, 2) = '/*' then
      begin
        InBlock := True;
        Inc(CharIdx);
      end
      else if LineText[CharIdx] in ['"', ''''] then
      begin
        InStr := True;
        Quote := LineText[CharIdx];
      end
      else if LineText[CharIdx] = '{' then
      begin
        Inc(Depth);
        Started := True;
      end
      else if LineText[CharIdx] = '}' then
      begin
        Dec(Depth);
        if Started and (Depth = 0) then
        begin
          Result := LineIdx;
          Exit;
        end;
      end;
      Inc(CharIdx);
    end;
  end;
end;

function FindFuncHeader(ALines: TStringList; const AName: string): Integer;
var
  LineIdx, NamePos: Integer;
  LineText, Rest: string;
begin
  Result := -1;
  for LineIdx := 0 to ALines.Count - 1 do
  begin
    LineText := ALines[LineIdx];
    if WordPos('void', LineText, 1) <> 1 then
      if Pos('void', TrimLeft(LineText)) <> 1 then
        Continue;
    NamePos := WordPos(AName, LineText, 1);
    if NamePos = 0 then
      Continue;
    Rest := TrimLeft(Copy(LineText, NamePos + Length(AName), MaxInt));
    if (Rest <> '') and (Rest[1] = '(') and (Pos(';', Rest) = 0) then
    begin
      Result := LineIdx;
      Exit;
    end;
  end;
end;

// Строка "case AState:" - ближайшая к AHint
function FindCaseLine(ALines: TStringList; AState, AHint: Integer): Integer;
var
  LineIdx, CasePos, CharPos, NumStart: Integer;
  LineText: string;
begin
  Result := -1;
  for LineIdx := 0 to ALines.Count - 1 do
  begin
    LineText := ALines[LineIdx];
    CasePos := WordPos('case', LineText, 1);
    if CasePos = 0 then
      Continue;
    CharPos := CasePos + 4;
    while (CharPos <= Length(LineText)) and (LineText[CharPos] in [' ', #9]) do
      Inc(CharPos);
    NumStart := CharPos;
    while (CharPos <= Length(LineText)) and (LineText[CharPos] in ['0'..'9']) do
      Inc(CharPos);
    if (CharPos > NumStart) and
       (StrToIntDef(Copy(LineText, NumStart, CharPos - NumStart), -1) = AState) and
       (Pos(':', Copy(LineText, CharPos, MaxInt)) > 0) then
      if (Result < 0) or (Abs(LineIdx - AHint) < Abs(Result - AHint)) then
        Result := LineIdx;
  end;
end;

function IndentOf(const ALine: string): string;
var
  CharIdx: Integer;
begin
  CharIdx := 1;
  while (CharIdx <= Length(ALine)) and (ALine[CharIdx] in [' ', #9]) do
    Inc(CharIdx);
  Result := Copy(ALine, 1, CharIdx - 1);
end;

function StrToIntTrim(const AText: string; ADefault: Integer): Integer;
begin
  Result := StrToIntDef(Trim(AText), ADefault);
end;

function NodeOfStateIn(AMap: TWmMap; AState: Integer): TWmNode;
var
  NodeIdx: Integer;
begin
  Result := nil;
  for NodeIdx := 0 to AMap.NodeCount - 1 do
    if (AMap.Nodes[NodeIdx].Kind = wnkWindow) and (AMap.Nodes[NodeIdx].State = AState) then
    begin
      Result := AMap.Nodes[NodeIdx];
      Exit;
    end;
end;

function AsciiOnly(const AText, ADefault: string): string;
var
  CharIdx: Integer;
begin
  Result := '';
  for CharIdx := 1 to Length(AText) do
    if (AText[CharIdx] >= ' ') and (AText[CharIdx] < #127) then
      Result := Result + AText[CharIdx];
  Result := Trim(Result);
  if Result = '' then
    Result := ADefault;
end;

function WnCreateWindow(AMap: TWmMap; const AParams: TWnParams;
  AForms, AIno, ACaseLines: TStringList; var AReport: string): Boolean;
var
  PrevNode, NextNode: TWmNode;
  Edge: TWmEdge;
  FormsFile, ArrName, NewName, PrevName, Block, TitleTpl, ItemTpl, TitleName,
  ItemName, PrevLabel, PrevLabelTpl, PrevTplName, ItemLine, NextCaption,
  Indent, DrawName: string;
  ArrStart, ArrEnd, LineIdx, HeaderLine, EndLine, CaseLine, BreakLine,
  DrawLine, NameIdx, TopValue, BestTop, ItemLineIdx, PrevLeft, PrevTop, PrevW,
  PrevH: Integer;
  Names, Keys, FuncLabels: TStringList;
begin
  Result := False;
  AReport := '';
  PrevNode := NodeOfStateIn(AMap, AParams.PrevState);
  NextNode := NodeOfStateIn(AMap, AParams.NextState);
  if (PrevNode = nil) or (NextNode = nil) then
  begin
    AReport := 'Нет окна ' + IntToStr(AParams.PrevState) + ' или ' +
               IntToStr(AParams.NextState) + ' в карте окон.';
    Exit;
  end;
  if WnStateUsed(AMap, AParams.NewState) then
  begin
    AReport := 'Номер ' + IntToStr(AParams.NewState) + ' уже занят.';
    Exit;
  end;
  if not WnMenuArray(AMap, PrevNode, FormsFile, ArrName, AForms) then
  begin
    AReport := 'У окна ' + PrevNode.Title + ' нет массива меню (TMenuItem): ' +
      'переходы написаны кодом, их правят вручную:'#13#10 + WnCodeLines(AMap, PrevNode);
    Exit;
  end;
  if not FindArray(AForms, ArrName, ArrStart, ArrEnd) then
  begin
    AReport := 'Не найден массив ' + ArrName + ' в файле форм.';
    Exit;
  end;
  NewName := 'Win' + IntToStr(AParams.NewState);
  PrevName := PrevNode.FuncName;
  HeaderLine := FindFuncHeader(AIno, PrevName);
  if HeaderLine < 0 then
  begin
    AReport := 'Не найдена функция ' + PrevName + '().';
    Exit;
  end;
  EndLine := FuncEndLine(AIno, HeaderLine);
  if EndLine < 0 then
  begin
    AReport := 'Не найден конец функции ' + PrevName + '().';
    Exit;
  end;
  CaseLine := FindCaseLine(ACaseLines, AParams.PrevState, PrevNode.CaseLine);
  if CaseLine < 0 then
  begin
    AReport := 'Не найдена ветка case ' + IntToStr(AParams.PrevState) + ':.';
    Exit;
  end;
  BreakLine := -1;
  for LineIdx := CaseLine to ACaseLines.Count - 1 do
    if WordPos('break', ACaseLines[LineIdx], 1) > 0 then
    begin
      BreakLine := LineIdx;
      Break;
    end;
  if BreakLine < 0 then
  begin
    AReport := 'Не найден break после case ' + IntToStr(AParams.PrevState) + ':.';
    Exit;
  end;

  Names := TStringList.Create;
  Keys := TStringList.Create;
  FuncLabels := TStringList.Create;
  try
    // образцы стиля: пункт меню предыдущего окна (цифра, ниже всех) и
    // верхняя надпись его функции
    ItemLabels(AForms, ArrStart, ArrEnd, Names, Keys);
    ItemTpl := '';
    ItemName := '';
    PrevTplName := '';
    BestTop := -1;
    for NameIdx := 0 to Names.Count - 1 do
      if (Length(Keys[NameIdx]) = 1) and (Keys[NameIdx][1] in ['0'..'9']) then
      begin
        Block := DeclBlock(AForms, Names[NameIdx]);
        TopValue := StrToIntTrim(PropGet(Block, '/*Top*/'), -1);
        if (Block <> '') and (TopValue > BestTop) and (TopValue < 280) then
        begin
          BestTop := TopValue;
          ItemTpl := Block;
          ItemName := Names[NameIdx];
        end;
      end;
    PrevLabelTpl := ItemTpl;
    PrevTplName := ItemName;
    for LineIdx := HeaderLine to EndLine do
    begin
      DrawLine := Pos('.Draw', AIno[LineIdx]);
      if DrawLine > 0 then
      begin
        Block := TrimLeft(Copy(AIno[LineIdx], 1, DrawLine - 1));
        if (Block <> '') and (Pos('/', Block) = 0) then
        begin
          // lblX.Caption(...).Draw() - имя до первой точки
          if Pos('.', Block) > 0 then
            Block := Copy(Block, 1, Pos('.', Block) - 1);
          FuncLabels.Add(Block);
        end;
      end;
    end;
    TitleTpl := '';
    TitleName := '';
    BestTop := 1000;
    for NameIdx := 0 to FuncLabels.Count - 1 do
    begin
      Block := DeclBlock(AForms, FuncLabels[NameIdx]);
      TopValue := StrToIntTrim(PropGet(Block, '/*Top*/'), 1000);
      if (Block <> '') and (TopValue < BestTop) and (TopValue < 60) then
      begin
        BestTop := TopValue;
        TitleTpl := Block;
        TitleName := FuncLabels[NameIdx];
      end;
    end;
    if ItemTpl = '' then
    begin
      ItemTpl := TitleTpl;
      ItemName := TitleName;
    end;
    if ItemTpl = '' then
    begin
      ItemName := FirstLabelName(AForms);
      ItemTpl := DeclBlock(AForms, ItemName);
    end;
    if TitleTpl = '' then
    begin
      TitleTpl := ItemTpl;
      TitleName := ItemName;
    end;
    if ItemTpl = '' then
    begin
      AReport := 'В файле форм нет ни одной надписи TLabel - не с чего взять стиль.';
      Exit;
    end;

    // 1. Массив предыдущего окна
    ItemLineIdx := -1;
    PrevLabel := '';
    if AParams.InsertInto then
    begin
      Edge := WnMenuEdge(AMap, PrevNode, NextNode, AParams.PrevKey);
      if Edge <> nil then
        ItemLineIdx := Edge.Line;
      if (ItemLineIdx < ArrStart) or (ItemLineIdx > ArrEnd) or
         (Pos('"' + AParams.PrevKey + '"', AForms[ItemLineIdx]) = 0) then
      begin
        ItemLineIdx := -1;
        for LineIdx := ArrStart to ArrEnd do
          if Pos('"' + AParams.PrevKey + '"', AForms[LineIdx]) > 0 then
          begin
            ItemLineIdx := LineIdx;
            Break;
          end;
      end;
      if ItemLineIdx < 0 then
      begin
        AReport := 'В ' + ArrName + ' нет пункта с клавишей ' + AParams.PrevKey + '.';
        Exit;
      end;
      ItemLine := AForms[ItemLineIdx];
      if not RetargetItem(ItemLine, AParams.PrevKey, AParams.NewState) then
      begin
        AReport := 'Не разобрана строка пункта: ' + Trim(ItemLine);
        Exit;
      end;
      AForms[ItemLineIdx] := ItemLine;
      AReport := AReport + ArrName + ': клавиша ' + AParams.PrevKey + ' ведёт в ' +
                 NewName + #13#10;
    end
    else
    begin
      if PrevLabelTpl = '' then
      begin
        PrevLabelTpl := ItemTpl;
        PrevTplName := ItemName;
      end;
      PrevLabel := 'lblTo' + IntToStr(AParams.NewState) + '_' + PrevName;
      // "{ ... } };" -> "{ ... }," и новый последний пункт
      ItemLine := AForms[ArrEnd];
      LineIdx := Pos('};', ItemLine);
      ItemLine := TrimRight(Copy(ItemLine, 1, LineIdx - 1));
      if (ItemLine <> '') and (ItemLine[Length(ItemLine)] = '}') then
        AForms[ArrEnd] := ItemLine + ','
      else
        AForms[ArrEnd] := ItemLine;
      AForms.Insert(ArrEnd + 1, '  { /*Label*/ &' + PrevLabel + ', /*Key*/ ' +
        CQuote(AParams.PrevKey) + ', /*Target*/ ' + IntToStr(AParams.NewState) +
        ' } }; // unIDE: new window');
      Inc(ArrEnd);
      AReport := AReport + ArrName + ': новый пункт ' + AParams.PrevKey + ' -> ' +
                 NewName + ' (' + PrevLabel + ')'#13#10;
    end;

    // 2. Новое окно: надписи и меню - после массива предыдущего
    NextCaption := AParams.NextKey + '-' + NextNode.FuncName;
    Block := #10'// ---------------- ' + NewName + ' ---------------- (unIDE: new window)'#10 +
      MakeLabel(TitleTpl, TitleName, 'lblTitle_' + NewName,
        StrToIntTrim(PropGet(TitleTpl, '/*Left*/'), 45),
        StrToIntTrim(PropGet(TitleTpl, '/*Top*/'), 10), -1, 0,
        AsciiOnly(AParams.Title, NewName)) +
      MakeLabel(ItemTpl, ItemName, 'lblNext_' + NewName,
        StrToIntTrim(PropGet(ItemTpl, '/*Left*/'), 45), 70, -1, 0, NextCaption) +
      #10'// ' + AsciiOnly(AParams.Title, NewName) + ' (' + NewName + ')'#10 +
      'const TMenuItem mnu' + NewName + '[] = {'#10 +
      '  { /*Label*/ &lblNext_' + NewName + ', /*Key*/ ' + CQuote(AParams.NextKey) +
      ', /*Target*/ ' + IntToStr(AParams.NextState) + ' } };'#10;
    InsertBlock(AForms, ArrEnd + 1, Block);

    // 3. Надпись нового пункта предыдущего окна - перед его массивом
    if PrevLabel <> '' then
    begin
      PrevLeft := StrToIntTrim(PropGet(PrevLabelTpl, '/*Left*/'), 45);
      PrevTop := StrToIntTrim(PropGet(PrevLabelTpl, '/*Top*/'), 35);
      PrevW := StrToIntTrim(PropGet(PrevLabelTpl, '/*Width*/'), -1);
      PrevH := StrToIntTrim(PropGet(PrevLabelTpl, '/*Height*/'), 25);
      if PrevH <= 0 then
        PrevH := 25;
      if PrevLabelTpl = TitleTpl then
        PrevTop := 35;
      Block := MakeLabel(PrevLabelTpl, PrevTplName, PrevLabel, PrevLeft,
        PrevTop + PrevH + 10, PrevW, 0, AParams.PrevKey + '-' +
        AsciiOnly(AParams.Title, NewName));
      InsertBlock(AForms, ArrStart, Block);
    end;

    // 4. .ino. Файл форм мог быть тем же - места ищутся заново
    HeaderLine := FindFuncHeader(AIno, PrevName);
    EndLine := FuncEndLine(AIno, HeaderLine);
    CaseLine := FindCaseLine(ACaseLines, AParams.PrevState, CaseLine);
    BreakLine := -1;
    if CaseLine >= 0 then
      for LineIdx := CaseLine to ACaseLines.Count - 1 do
        if WordPos('break', ACaseLines[LineIdx], 1) > 0 then
        begin
          BreakLine := LineIdx;
          Break;
        end;
    if (HeaderLine < 0) or (EndLine < 0) or (BreakLine < 0) then
    begin
      AReport := 'После правки файла форм не найдены ' + PrevName + '() или case.';
      Exit;
    end;
    // сначала то, что ниже по файлу (номера строк выше не сдвигаются)
    Block :=
      #10'void ' + NewName + '() // ' + AsciiOnly(AParams.Title, NewName) + #10 +
      '{'#10 +
      '  myGLCD.clrScr();'#10 +
      '  kbcol = 0;'#10 +
      '  lblTitle_' + NewName + '.Draw();'#10 +
      '  lblNext_' + NewName + '.Draw();'#10 +
      '  const TMenuItem *item; // menu mnu' + NewName + #10 +
      '  do'#10 +
      '    item = RunMenu(mnu' + NewName + ', MENU_COUNT(mnu' + NewName + '));'#10 +
      '  while (item == NULL);'#10 +
      '  ' + AMap.StateVar + ' = item->Target;'#10 +
      '}'#10;
    Indent := IndentOf(ACaseLines[CaseLine]);
    DrawLine := -1;
    DrawName := '';
    if PrevLabel <> '' then
    begin
      for LineIdx := HeaderLine to EndLine do
        if (PrevTplName <> '') and (WordPos(PrevTplName, AIno[LineIdx], 1) > 0) and
           (Pos('.Draw', AIno[LineIdx]) > 0) then
          DrawLine := LineIdx;
      if DrawLine < 0 then
        for LineIdx := HeaderLine to EndLine do
          if Pos('clrScr', AIno[LineIdx]) > 0 then
          begin
            DrawLine := LineIdx;
            Break;
          end;
      if DrawLine < 0 then
        DrawLine := HeaderLine + 1;
      DrawName := IndentOf(AIno[DrawLine]) + PrevLabel + '.Draw(); // unIDE: new window';
      if IndentOf(AIno[DrawLine]) = '' then
        DrawName := '  ' + DrawName;
    end;
    if (ACaseLines = AIno) and (BreakLine > EndLine) then
    begin
      ACaseLines.Insert(BreakLine + 1, Indent + 'case ' + IntToStr(AParams.NewState) + ':');
      ACaseLines.Insert(BreakLine + 2, Indent + NewName + '(); //' + AsciiOnly(AParams.Title, NewName));
      ACaseLines.Insert(BreakLine + 3, Indent + 'break;');
      InsertBlock(AIno, EndLine + 1, Block);
      if DrawLine >= 0 then
        AIno.Insert(DrawLine + 1, DrawName);
    end
    else
    begin
      InsertBlock(AIno, EndLine + 1, Block);
      if DrawLine >= 0 then
        AIno.Insert(DrawLine + 1, DrawName);
      // case выше функции в том же файле - номер строки не сдвинулся
      ACaseLines.Insert(BreakLine + 1, Indent + 'case ' + IntToStr(AParams.NewState) + ':');
      ACaseLines.Insert(BreakLine + 2, Indent + NewName + '(); //' + AsciiOnly(AParams.Title, NewName));
      ACaseLines.Insert(BreakLine + 3, Indent + 'break;');
    end;
    AReport := AReport + 'Новое окно ' + NewName + ': надписи lblTitle_' + NewName +
      ', lblNext_' + NewName + ', меню mnu' + NewName + ' (' + AParams.NextKey +
      ' -> ' + NextNode.Title + '), функция ' + NewName + '() после ' + PrevName +
      '(), case ' + IntToStr(AParams.NewState) + ':'#13#10;
    Result := True;
  finally
    Names.Free;
    Keys.Free;
    FuncLabels.Free;
  end;
end;

{ TArdWinNewForm }

constructor TArdWinNewForm.CreateFor(AOwner: TComponent; AMap: TWmMap; ACurrent: Integer);
var
  NodeIdx, Index, NextIdx: Integer;
  Node: TWmNode;
  Btn: TButton;
  Order: TList;
begin
  CreateNew(AOwner);
  FMap := AMap;
  FWindows := TList.Create;
  Caption := 'Создать новое окно';
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  ClientWidth := 420;
  ClientHeight := 330;

  AddLabel('Предыдущее окно (откуда переход):', 10);
  FPrevCombo := AddCombo(28);
  AddLabel('Клавиша в предыдущем окне:', 58);
  FPrevKeyCombo := AddCombo(76);
  FPrevKeyCombo.Width := 120;
  FInsertCheck := TCheckBox.Create(Self);
  FInsertCheck.Parent := Self;
  FInsertCheck.SetBounds(150, 78, 260, 20);
  FInsertCheck.Caption := 'Вставить в существующий переход';
  FInsertCheck.OnClick := InsertClick;
  AddLabel('Следующее окно (куда ведёт новое):', 106);
  FNextCombo := AddCombo(124);
  AddLabel('Клавиша перехода в следующее окно:', 154);
  FNextKeyCombo := AddCombo(172);
  FNextKeyCombo.Width := 120;
  FNextKeyCombo.Items.CommaText := 'Ent,#,Esc,1,2,3,4,5,6,7,8,9,0,F1,F2';
  FNextKeyCombo.ItemIndex := 0;
  AddLabel('Номер окна:', 202);
  FNumberEdit := TEdit.Create(Self);
  FNumberEdit.Parent := Self;
  FNumberEdit.SetBounds(10, 220, 80, 24);
  with AddLabel('Заголовок (латиница - шрифты прибора):', 202) do
    Left := 110;
  FTitleEdit := TEdit.Create(Self);
  FTitleEdit.Parent := Self;
  FTitleEdit.SetBounds(110, 220, 300, 24);
  FTitleEdit.Text := 'New window';
  FInfo := AddLabel('', 252);
  FInfo.WordWrap := True;
  FInfo.AutoSize := False;
  FInfo.SetBounds(10, 250, 400, 36);

  Btn := TButton.Create(Self);
  Btn.Parent := Self;
  Btn.SetBounds(220, 292, 90, 28);
  Btn.Caption := 'Создать';
  Btn.Default := True;
  Btn.OnClick := OkClick;
  Btn := TButton.Create(Self);
  Btn.Parent := Self;
  Btn.SetBounds(320, 292, 90, 28);
  Btn.Caption := 'Отмена';
  Btn.Cancel := True;
  Btn.ModalResult := mrCancel;

  Order := TList.Create;
  try
    FMap.TreeOrder(Order);
    for NodeIdx := 0 to Order.Count - 1 do
    begin
      Node := TWmNode(Order[NodeIdx]);
      if Node.Kind = wnkWindow then
        FWindows.Add(Node);
    end;
  finally
    Order.Free;
  end;
  Index := 0;
  for NodeIdx := 0 to FWindows.Count - 1 do
  begin
    Node := TWmNode(FWindows[NodeIdx]);
    FPrevCombo.Items.Add(Node.Title + '  ' + Node.Caption);
    FNextCombo.Items.Add(Node.Title + '  ' + Node.Caption);
    if Node.State = ACurrent then
      Index := NodeIdx;
  end;
  FPrevCombo.ItemIndex := Index;
  // следующее - первое окно, куда ведёт меню текущего
  NextIdx := -1;
  if FWindows.Count > 0 then
    for NodeIdx := 0 to FMap.EdgeCount - 1 do
      if (FMap.Edges[NodeIdx].FromNode = FWindows[Index]) and
         (FMap.Edges[NodeIdx].Kind = wekMenu) and (FMap.Edges[NodeIdx].Action = '') and
         (FMap.Edges[NodeIdx].ToNode <> nil) and (FMap.Edges[NodeIdx].ToNode.Kind = wnkWindow) then
      begin
        NextIdx := FWindows.IndexOf(FMap.Edges[NodeIdx].ToNode);
        if NextIdx >= 0 then
          Break;
      end;
  if NextIdx < 0 then
    NextIdx := 0;
  FNextCombo.ItemIndex := NextIdx;
  FPrevCombo.OnChange := PrevChange;
  FNextCombo.OnChange := NextChange;
  PrevChange(nil);
end;

destructor TArdWinNewForm.Destroy;
begin
  FWindows.Free;
  inherited Destroy;
end;

function TArdWinNewForm.AddLabel(const ACaption: string; ATop: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(10, ATop, 400, 16);
  Result.Caption := ACaption;
end;

function TArdWinNewForm.AddCombo(ATop: Integer): TComboBox;
begin
  Result := TComboBox.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(10, ATop, 400, 24);
  Result.Style := csDropDownList;
  Result.DropDownCount := 30;
end;

function TArdWinNewForm.NodeOfCombo(ACombo: TComboBox): TWmNode;
begin
  Result := nil;
  if (ACombo.ItemIndex >= 0) and (ACombo.ItemIndex < FWindows.Count) then
    Result := TWmNode(FWindows[ACombo.ItemIndex]);
end;

procedure TArdWinNewForm.PrevChange(Sender: TObject);
var
  PrevNode: TWmNode;
begin
  PrevNode := NodeOfCombo(FPrevCombo);
  if PrevNode <> nil then
    FNumberEdit.Text := IntToStr(WnFreeState(FMap, PrevNode.State));
  NextChange(nil);
end;

procedure TArdWinNewForm.NextChange(Sender: TObject);
var
  PrevNode, NextNode: TWmNode;
  HasEdge: Boolean;
begin
  PrevNode := NodeOfCombo(FPrevCombo);
  NextNode := NodeOfCombo(FNextCombo);
  HasEdge := (PrevNode <> nil) and (NextNode <> nil) and
             (WnMenuEdge(FMap, PrevNode, NextNode, '') <> nil);
  FInsertCheck.Enabled := HasEdge;
  FInsertCheck.Checked := HasEdge;
  FillKeys;
end;

procedure TArdWinNewForm.InsertClick(Sender: TObject);
begin
  FillKeys;
end;

// Клавиши предыдущего окна: при вставке - пункты, ведущие в следующее,
// иначе - свободные цифры его меню
procedure TArdWinNewForm.FillKeys;
var
  PrevNode, NextNode: TWmNode;
  Used, EdgeKeys: TStringList;
  KeyIdx, EdgeIdx: Integer;
  Edge: TWmEdge;
  ArrFile, ArrName: string;
begin
  FPrevKeyCombo.Items.Clear;
  PrevNode := NodeOfCombo(FPrevCombo);
  NextNode := NodeOfCombo(FNextCombo);
  if PrevNode = nil then
    Exit;
  if FInsertCheck.Checked and FInsertCheck.Enabled then
  begin
    EdgeKeys := TStringList.Create;
    try
      for EdgeIdx := 0 to FMap.EdgeCount - 1 do
      begin
        Edge := FMap.Edges[EdgeIdx];
        if (Edge.FromNode = PrevNode) and (Edge.ToNode = NextNode) and
           (Edge.Kind = wekMenu) and (Edge.Action = '') then
          SplitKeys(Edge.Keys, EdgeKeys);
      end;
      FPrevKeyCombo.Items.Assign(EdgeKeys);
    finally
      EdgeKeys.Free;
    end;
  end
  else
  begin
    Used := WnMenuKeys(FMap, PrevNode);
    try
      for KeyIdx := Low(DigitKeys) to High(DigitKeys) do
        if Used.IndexOf(DigitKeys[KeyIdx]) < 0 then
          FPrevKeyCombo.Items.Add(DigitKeys[KeyIdx]);
    finally
      Used.Free;
    end;
  end;
  if FPrevKeyCombo.Items.Count > 0 then
    FPrevKeyCombo.ItemIndex := 0;
  if not WnMenuArray(FMap, PrevNode, ArrFile, ArrName, nil) then
    FInfo.Caption := 'У окна ' + PrevNode.Title + ' переходы написаны кодом, ' +
      'без массива меню - его надо будет править вручную.'
  else if FInsertCheck.Checked and FInsertCheck.Enabled then
    FInfo.Caption := 'Пункт предыдущего окна будет вести в новое окно, а новое - ' +
      'в следующее.'
  else
    FInfo.Caption := 'В предыдущем окне появится новый пункт меню, прежние ' +
      'переходы останутся.';
end;

procedure TArdWinNewForm.OkClick(Sender: TObject);
var
  Params: TWnParams;
begin
  if not GetParams(Params) then
    Exit;
  ModalResult := mrOk;
end;

function TArdWinNewForm.GetParams(var AParams: TWnParams): Boolean;
var
  PrevNode, NextNode: TWmNode;
begin
  Result := False;
  PrevNode := NodeOfCombo(FPrevCombo);
  NextNode := NodeOfCombo(FNextCombo);
  if (PrevNode = nil) or (NextNode = nil) then
    Exit;
  if FPrevKeyCombo.ItemIndex < 0 then
  begin
    ShowMessage('Нет свободной клавиши в окне ' + PrevNode.Title + '.');
    Exit;
  end;
  AParams.PrevState := PrevNode.State;
  AParams.NextState := NextNode.State;
  AParams.PrevKey := FPrevKeyCombo.Items[FPrevKeyCombo.ItemIndex];
  AParams.NextKey := FNextKeyCombo.Text;
  AParams.InsertInto := FInsertCheck.Checked and FInsertCheck.Enabled;
  AParams.NewState := StrToIntDef(Trim(FNumberEdit.Text), -1);
  AParams.Title := FTitleEdit.Text;
  if AParams.NewState < 0 then
  begin
    ShowMessage('Номер окна - целое число.');
    Exit;
  end;
  if WnStateUsed(FMap, AParams.NewState) then
  begin
    ShowMessage('Номер ' + IntToStr(AParams.NewState) + ' уже занят.');
    Exit;
  end;
  Result := True;
end;

end.
