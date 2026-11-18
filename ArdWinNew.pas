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

// Буфер «Копировать окно»: надписи TLabel, которые окно рисует
// безусловно (вызов Draw на верхнем уровне тела функции), с объявлениями
type
  TWnClip = class
  public
    SourceFunc: string;      // Win20
    Names: TStringList;      // имена надписей
    Decls: TStringList;      // объявления (строки через #10)
    Draws: TStringList;      // оператор вызова: lblX.Draw(); с цепочкой
    Skipped: Integer;        // надписи только в условных ветках - не взяты
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Count: Integer;
  end;

// AFiles - тексты всех файлов скетча (TStringList), AFileNames - их имена
// в том же порядке. Функция окна - в файле ANode.FileName.
// Копировать: надписи окна ANode в AClip
function WnCopyWindow(ANode: TWmNode; AFiles: TList; AFileNames: TStrings;
  AClip: TWnClip; var AReport: string): Boolean;
// Вставить: копии надписей AClip (новые имена _WinN) - объявления рядом
// с надписями/меню окна, вызовы Draw - после его надписей
function WnPasteWindow(ANode: TWmNode; AFiles: TList; AFileNames: TStrings;
  AClip: TWnClip; var AReport: string): Boolean;
// Очистить: убрать безусловные вызовы Draw надписей окна; объявления,
// на которые больше нет ссылок (меню и др.), - удалить
function WnClearWindow(ANode: TWmNode; AFiles: TList; AFileNames: TStrings;
  var AReport: string): Boolean;
// Клонировать окно ASource: новое окно AParams.NewState с переходом из
// AParams.PrevState (как WnCreateWindow), в нём - копия функции (номер окна
// в StateVar = S заменён), надписей *_WinS (-> *_WinN) и массива mnuWinS
function WnCloneWindow(AMap: TWmMap; const AParams: TWnParams; ASource: TWmNode;
  AFiles: TList; AFileNames: TStrings; var AReport: string): Boolean;

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
    FNextLabel, FNextKeyLabel: TLabel;
    FCloneSource: TWmNode;
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
    // Режим «Клонировать окно»: следующего окна нет, копируется ASource
    procedure SetCloneSource(ASource: TWmNode);
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

{$IFNDEF FPC}
type
  PtrInt = Integer;
{$ENDIF}

{ Копировать, вставить, очистить окно }

constructor TWnClip.Create;
begin
  inherited Create;
  Names := TStringList.Create;
  Decls := TStringList.Create;
  Draws := TStringList.Create;
end;

destructor TWnClip.Destroy;
begin
  Names.Free;
  Decls.Free;
  Draws.Free;
  inherited Destroy;
end;

procedure TWnClip.Clear;
begin
  SourceFunc := '';
  Names.Clear;
  Decls.Clear;
  Draws.Clear;
  Skipped := 0;
end;

function TWnClip.Count: Integer;
begin
  Result := Names.Count;
end;

function FileIndexOf(AFileNames: TStrings; const AFileName: string): Integer;
var
  FileIdx: Integer;
begin
  Result := -1;
  for FileIdx := 0 to AFileNames.Count - 1 do
    if CompareText(ExpandFileName(AFileNames[FileIdx]), ExpandFileName(AFileName)) = 0 then
    begin
      Result := FileIdx;
      Exit;
    end;
end;

// Глубина скобок {} в начале каждой строки AFrom..ATo (0 - вне функции,
// 1 - тело функции); комментарии и строки пропускаются
procedure LineDepths(ALines: TStringList; AFrom, ATo: Integer; var ADepths: array of Integer);
var
  LineIdx, CharIdx, Depth: Integer;
  LineText: string;
  InBlock, InStr: Boolean;
  Quote: Char;
begin
  Depth := 0;
  InBlock := False;
  Quote := '"';
  for LineIdx := AFrom to ATo do
  begin
    ADepths[LineIdx - AFrom] := Depth;
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
        Inc(Depth)
      else if LineText[CharIdx] = '}' then
        Dec(Depth);
      Inc(CharIdx);
    end;
  end;
end;

// Строка начинается с вызова надписи: "lblX.Draw();" или
// "lblX.Caption(...).Draw();" - имя и оператор до ';' включительно
function DrawStatement(const ALine: string; var AName, AStmt: string): Boolean;
var
  Text: string;
  EndPos, DrawPos, SemiPos: Integer;
begin
  Result := False;
  Text := TrimLeft(ALine);
  EndPos := 1;
  while (EndPos <= Length(Text)) and IsIdentChar(Text[EndPos]) do
    Inc(EndPos);
  if (EndPos = 1) or (EndPos > Length(Text)) or (Text[EndPos] <> '.') then
    Exit;
  AName := Copy(Text, 1, EndPos - 1);
  DrawPos := Pos('.Draw', Text);
  if DrawPos = 0 then
    Exit;
  SemiPos := DrawPos;
  while (SemiPos <= Length(Text)) and (Text[SemiPos] <> ';') do
    Inc(SemiPos);
  if SemiPos > Length(Text) then
    Exit;
  AStmt := Copy(Text, 1, SemiPos);
  Result := True;
end;

// Объявление надписи AName в одном из файлов: номер файла, строки
function FindLabelAny(AFiles: TList; const AName: string;
  var AFileIdx, AStart, AEnd: Integer): Boolean;
var
  FileIdx: Integer;
begin
  Result := False;
  for FileIdx := 0 to AFiles.Count - 1 do
    if FindLabelDecl(TStringList(AFiles[FileIdx]), AName, AStart, AEnd) then
    begin
      AFileIdx := FileIdx;
      Result := True;
      Exit;
    end;
end;

function NameUsed(AFiles: TList; const AName: string): Boolean;
var
  FileIdx, LineIdx: Integer;
  Lines: TStringList;
begin
  Result := True;
  for FileIdx := 0 to AFiles.Count - 1 do
  begin
    Lines := TStringList(AFiles[FileIdx]);
    for LineIdx := 0 to Lines.Count - 1 do
      if WordPos(AName, Lines[LineIdx], 1) > 0 then
        Exit;
  end;
  Result := False;
end;

// Тело функции окна: файл, строки заголовка и '}'
function WindowFunc(ANode: TWmNode; AFiles: TList; AFileNames: TStrings;
  var AIno: TStringList; var AHeader, AEnd: Integer; var AReport: string): Boolean;
var
  FileIdx: Integer;
begin
  Result := False;
  FileIdx := FileIndexOf(AFileNames, ANode.FileName);
  if (ANode.Kind <> wnkWindow) or (FileIdx < 0) then
  begin
    AReport := 'Не найден файл функции окна ' + ANode.Title + '.';
    Exit;
  end;
  AIno := TStringList(AFiles[FileIdx]);
  AHeader := FindFuncHeader(AIno, ANode.FuncName);
  if AHeader < 0 then
  begin
    AReport := 'Не найдена функция ' + ANode.FuncName + '().';
    Exit;
  end;
  AEnd := FuncEndLine(AIno, AHeader);
  if AEnd < 0 then
  begin
    AReport := 'Не найден конец функции ' + ANode.FuncName + '().';
    Exit;
  end;
  Result := True;
end;

// Безусловные вызовы надписей в теле: номера строк (Objects) и имена
procedure TopDraws(AFiles: TList; AIno: TStringList; AHeader, AEnd: Integer;
  ALines, ANames, AStmts: TStringList; var ACondCount: Integer);
var
  Depths: array of Integer;
  LineIdx, FileIdx, DeclStart, DeclEnd: Integer;
  LabelName, Stmt: string;
  CondNames: TStringList;
begin
  ACondCount := 0;
  SetLength(Depths, AEnd - AHeader + 1);
  LineDepths(AIno, AHeader, AEnd, Depths);
  CondNames := TStringList.Create;
  try
    for LineIdx := AHeader + 1 to AEnd - 1 do
    begin
      if not DrawStatement(AIno[LineIdx], LabelName, Stmt) then
        Continue;
      if not FindLabelAny(AFiles, LabelName, FileIdx, DeclStart, DeclEnd) then
        Continue;
      if Depths[LineIdx - AHeader] = 1 then
      begin
        ALines.AddObject(LabelName, TObject(PtrInt(LineIdx)));
        if ANames.IndexOf(LabelName) < 0 then
        begin
          ANames.Add(LabelName);
          AStmts.Add(Stmt);
        end;
      end
      else if CondNames.IndexOf(LabelName) < 0 then
        CondNames.Add(LabelName);
    end;
    for LineIdx := 0 to CondNames.Count - 1 do
      if ANames.IndexOf(CondNames[LineIdx]) < 0 then
        Inc(ACondCount);
  finally
    CondNames.Free;
  end;
end;

function WnCopyWindow(ANode: TWmNode; AFiles: TList; AFileNames: TStrings;
  AClip: TWnClip; var AReport: string): Boolean;
var
  Ino, DeclLines, Names, Stmts: TStringList;
  HeaderLine, EndLine, NameIdx, FileIdx, DeclStart, DeclEnd, LineIdx, CondCount: Integer;
  Block: string;
begin
  Result := False;
  AReport := '';
  if not WindowFunc(ANode, AFiles, AFileNames, Ino, HeaderLine, EndLine, AReport) then
    Exit;
  DeclLines := TStringList.Create;
  Names := TStringList.Create;
  Stmts := TStringList.Create;
  try
    TopDraws(AFiles, Ino, HeaderLine, EndLine, DeclLines, Names, Stmts, CondCount);
    if Names.Count = 0 then
    begin
      AReport := 'В ' + ANode.FuncName + '() нет вызовов Draw надписей TLabel ' +
                 'на верхнем уровне - копировать нечего.';
      Exit;
    end;
    AClip.Clear;
    AClip.SourceFunc := ANode.FuncName;
    AClip.Skipped := CondCount;
    for NameIdx := 0 to Names.Count - 1 do
    begin
      if not FindLabelAny(AFiles, Names[NameIdx], FileIdx, DeclStart, DeclEnd) then
        Continue;
      Block := '';
      for LineIdx := DeclStart to DeclEnd do
        Block := Block + TStringList(AFiles[FileIdx])[LineIdx] + #10;
      AClip.Names.Add(Names[NameIdx]);
      AClip.Decls.Add(Block);
      AClip.Draws.Add(Stmts[NameIdx]);
    end;
    AReport := 'Скопировано надписей: ' + IntToStr(AClip.Count) + ' из ' +
               ANode.FuncName + '()';
    if CondCount > 0 then
      AReport := AReport + '; ' + IntToStr(CondCount) +
                 ' только в условных ветках - не взяты';
    Result := True;
  finally
    DeclLines.Free;
    Names.Free;
    Stmts.Free;
  end;
end;

// Новое имя надписи для окна AFunc: суффикс _WinS -> _WinN, иначе + _WinN;
// занятое имя - с номером
function PasteName(AFiles: TList; AReserved: TStringList;
  const AName, ASourceFunc, AFunc: string): string;
var
  Base: string;
  Number: Integer;
begin
  Base := AName;
  if (Length(Base) > Length(ASourceFunc) + 1) and
     (CompareText(Copy(Base, Length(Base) - Length(ASourceFunc), MaxInt),
                  '_' + ASourceFunc) = 0) then
    Base := Copy(Base, 1, Length(Base) - Length(ASourceFunc) - 1);
  Base := Base + '_' + AFunc;
  Result := Base;
  Number := 2;
  while NameUsed(AFiles, Result) or (AReserved.IndexOf(Result) >= 0) do
  begin
    Result := Base + '_' + IntToStr(Number);
    Inc(Number);
  end;
end;

function WnPasteWindow(ANode: TWmNode; AFiles: TList; AFileNames: TStrings;
  AClip: TWnClip; var AReport: string): Boolean;
var
  Ino, Forms, DrawLines, Names, Stmts, NewNames: TStringList;
  HeaderLine, EndLine, FileIdx, FormsIdx, InsertAt, DeclStart, DeclEnd, LineIdx,
  NameIdx, CondCount, DrawAt, StopLine, OpenLine, ArrStart, ArrEnd: Integer;
  Block, Stmt, Indent, MarkText: string;
  Depths: array of Integer;
begin
  Result := False;
  AReport := '';
  if (AClip = nil) or (AClip.Count = 0) then
  begin
    AReport := 'Буфер пуст: сначала «Копировать окно».';
    Exit;
  end;
  if not WindowFunc(ANode, AFiles, AFileNames, Ino, HeaderLine, EndLine, AReport) then
    Exit;
  DrawLines := TStringList.Create;
  Names := TStringList.Create;
  Stmts := TStringList.Create;
  NewNames := TStringList.Create;
  try
    TopDraws(AFiles, Ino, HeaderLine, EndLine, DrawLines, Names, Stmts, CondCount);
    MarkText := ' // unIDE: copied from ' + AClip.SourceFunc;
    for NameIdx := 0 to AClip.Count - 1 do
      NewNames.Add(PasteName(AFiles, NewNames, AClip.Names[NameIdx],
                             AClip.SourceFunc, ANode.FuncName));

    // 1. Файл и место объявлений: после последней надписи окна, иначе
    // перед массивом меню окна, иначе там, где объявлена исходная надпись
    FormsIdx := -1;
    InsertAt := -1;
    for NameIdx := Names.Count - 1 downto 0 do
      if FindLabelAny(AFiles, Names[NameIdx], FileIdx, DeclStart, DeclEnd) then
        if (FormsIdx < 0) or ((FileIdx = FormsIdx) and (DeclEnd + 1 > InsertAt)) then
        begin
          FormsIdx := FileIdx;
          InsertAt := DeclEnd + 1;
        end;
    // надписи окна, которые оно сейчас не рисует (меню, после «Очистить»):
    // имя *_WinN - после последней из них
    if FormsIdx < 0 then
      for FileIdx := 0 to AFiles.Count - 1 do
      begin
        Forms := TStringList(AFiles[FileIdx]);
        for LineIdx := 0 to Forms.Count - 1 do
        begin
          if (WordPos('TLabel', Forms[LineIdx], 1) = 0) or (Pos('{', Forms[LineIdx]) = 0) then
            Continue;
          Stmt := Forms[LineIdx];
          DeclStart := WordPos('TLabel', Stmt, 1) + Length('TLabel');
          while (DeclStart <= Length(Stmt)) and (Stmt[DeclStart] = ' ') do
            Inc(DeclStart);
          DeclEnd := DeclStart;
          while (DeclEnd <= Length(Stmt)) and IsIdentChar(Stmt[DeclEnd]) do
            Inc(DeclEnd);
          Stmt := Copy(Stmt, DeclStart, DeclEnd - DeclStart);
          if (Length(Stmt) > Length(ANode.FuncName) + 1) and
             (CompareText(Copy(Stmt, Length(Stmt) - Length(ANode.FuncName), MaxInt),
                          '_' + ANode.FuncName) = 0) and
             FindLabelDecl(Forms, Stmt, DeclStart, DeclEnd) and
             ((FormsIdx < 0) or (FormsIdx = FileIdx)) then
          begin
            FormsIdx := FileIdx;
            InsertAt := DeclEnd + 1;
          end;
        end;
      end;
    if FormsIdx < 0 then
      for FileIdx := 0 to AFiles.Count - 1 do
        if FindArray(TStringList(AFiles[FileIdx]), 'mnu' + ANode.FuncName,
                     ArrStart, ArrEnd) then
        begin
          FormsIdx := FileIdx;
          InsertAt := ArrStart;
          // комментарий над массивом - остаётся над ним
          while (InsertAt > 0) and
                (Copy(TrimLeft(TStringList(AFiles[FileIdx])[InsertAt - 1]), 1, 2) = '//') do
            Dec(InsertAt);
          Break;
        end;
    if FormsIdx < 0 then
      if FindLabelAny(AFiles, AClip.Names[0], FileIdx, DeclStart, DeclEnd) then
      begin
        FormsIdx := FileIdx;
        InsertAt := DeclEnd + 1;
      end;
    if FormsIdx < 0 then
    begin
      AReport := 'Не найдено, куда поставить объявления надписей.';
      Exit;
    end;
    Forms := TStringList(AFiles[FormsIdx]);
    Block := '';
    for NameIdx := 0 to AClip.Count - 1 do
    begin
      Stmt := AClip.Decls[NameIdx];
      LineIdx := WordPos(AClip.Names[NameIdx], Stmt, 1);
      if LineIdx > 0 then
        Stmt := Copy(Stmt, 1, LineIdx - 1) + NewNames[NameIdx] +
                Copy(Stmt, LineIdx + Length(AClip.Names[NameIdx]), MaxInt);
      // пометка - в конце первой строки (комментарий образца остаётся)
      LineIdx := Pos(#10, Stmt);
      if LineIdx > 0 then
        Stmt := Copy(Stmt, 1, LineIdx - 1) + MarkText + Copy(Stmt, LineIdx, MaxInt);
      Block := Block + Stmt;
    end;
    InsertBlock(Forms, InsertAt, Block);

    // 2. Вызовы Draw - в функции окна (файл мог быть тем же - места заново)
    HeaderLine := FindFuncHeader(Ino, ANode.FuncName);
    EndLine := FuncEndLine(Ino, HeaderLine);
    if (HeaderLine < 0) or (EndLine < 0) then
    begin
      AReport := 'После вставки объявлений не найдена функция ' + ANode.FuncName + '().';
      Exit;
    end;
    SetLength(Depths, EndLine - HeaderLine + 1);
    LineDepths(Ino, HeaderLine, EndLine, Depths);
    OpenLine := HeaderLine;
    while (OpenLine < EndLine) and (Pos('{', Ino[OpenLine]) = 0) do
      Inc(OpenLine);
    // до первого ожидания клавиши / цикла
    StopLine := EndLine;
    for LineIdx := OpenLine + 1 to EndLine - 1 do
      if (Depths[LineIdx - HeaderLine] = 1) and
         ((Pos('RunMenu', Ino[LineIdx]) > 0) or (Pos('InputNumber', Ino[LineIdx]) > 0) or
          (WordPos('do', Ino[LineIdx], 1) > 0) or (WordPos('while', Ino[LineIdx], 1) > 0) or
          (WordPos('for', Ino[LineIdx], 1) > 0)) and
         (Copy(TrimLeft(Ino[LineIdx]), 1, 2) <> '//') then
      begin
        StopLine := LineIdx;
        Break;
      end;
    DrawAt := -1;
    for LineIdx := OpenLine + 1 to StopLine - 1 do
      if (Depths[LineIdx - HeaderLine] = 1) and DrawStatement(Ino[LineIdx], Block, Stmt) then
        DrawAt := LineIdx + 1;
    if DrawAt < 0 then
      for LineIdx := OpenLine + 1 to StopLine - 1 do
        if (Depths[LineIdx - HeaderLine] = 1) and (Pos('clrScr', Ino[LineIdx]) > 0) and
           (Copy(TrimLeft(Ino[LineIdx]), 1, 2) <> '//') then
          DrawAt := LineIdx + 1;
    if DrawAt < 0 then
      DrawAt := OpenLine + 1;
    Indent := '  ';
    if (DrawAt - 1 > OpenLine) and (IndentOf(Ino[DrawAt - 1]) <> '') then
      Indent := IndentOf(Ino[DrawAt - 1]);
    for NameIdx := AClip.Count - 1 downto 0 do
    begin
      Stmt := AClip.Draws[NameIdx];
      Stmt := NewNames[NameIdx] + Copy(Stmt, Length(AClip.Names[NameIdx]) + 1, MaxInt);
      Ino.Insert(DrawAt, Indent + Stmt + MarkText);
    end;
    AReport := 'Вставлено надписей в ' + ANode.FuncName + '(): ' +
               IntToStr(AClip.Count) + ' (' + NewNames.CommaText + '), объявления - ' +
               ExtractFileName(AFileNames[FormsIdx]) + ', строка ' + IntToStr(InsertAt + 1);
    Result := True;
  finally
    DrawLines.Free;
    Names.Free;
    Stmts.Free;
    NewNames.Free;
  end;
end;

function WnClearWindow(ANode: TWmNode; AFiles: TList; AFileNames: TStrings;
  var AReport: string): Boolean;
var
  Ino, DrawLines, Names, Stmts, Removed, Kept: TStringList;
  HeaderLine, EndLine, LineIdx, NameIdx, CondCount, FileIdx, DeclStart, DeclEnd: Integer;
  Block: string;
begin
  Result := False;
  AReport := '';
  if not WindowFunc(ANode, AFiles, AFileNames, Ino, HeaderLine, EndLine, AReport) then
    Exit;
  DrawLines := TStringList.Create;
  Names := TStringList.Create;
  Stmts := TStringList.Create;
  Removed := TStringList.Create;
  Kept := TStringList.Create;
  try
    TopDraws(AFiles, Ino, HeaderLine, EndLine, DrawLines, Names, Stmts, CondCount);
    if DrawLines.Count = 0 then
    begin
      AReport := 'В ' + ANode.FuncName + '() нет вызовов Draw надписей на верхнем уровне.';
      Exit;
    end;
    // снизу вверх - номера строк выше не сдвигаются
    for LineIdx := DrawLines.Count - 1 downto 0 do
      Ino.Delete(PtrInt(DrawLines.Objects[LineIdx]));
    // объявления без других ссылок
    for NameIdx := 0 to Names.Count - 1 do
    begin
      if not FindLabelAny(AFiles, Names[NameIdx], FileIdx, DeclStart, DeclEnd) then
        Continue;
      Block := '';
      for LineIdx := DeclStart to DeclEnd do
        Block := Block + TStringList(AFiles[FileIdx])[LineIdx] + #10;
      for LineIdx := DeclEnd downto DeclStart do
        TStringList(AFiles[FileIdx]).Delete(LineIdx);
      if NameUsed(AFiles, Names[NameIdx]) then
      begin
        // ссылка осталась (меню, другое окно) - объявление вернуть
        InsertBlock(TStringList(AFiles[FileIdx]), DeclStart, Block);
        Kept.Add(Names[NameIdx]);
      end
      else
        Removed.Add(Names[NameIdx]);
    end;
    AReport := 'Очищено ' + ANode.FuncName + '(): убрано вызовов Draw - ' +
               IntToStr(DrawLines.Count);
    if Removed.Count > 0 then
      AReport := AReport + '; удалены объявления: ' + Removed.CommaText;
    if Kept.Count > 0 then
      AReport := AReport + '; оставлены (есть ссылки, напр. в меню): ' + Kept.CommaText;
    if CondCount > 0 then
      AReport := AReport + '; в условных ветках не тронуто: ' + IntToStr(CondCount);
    Result := True;
  finally
    DrawLines.Free;
    Names.Free;
    Stmts.Free;
    Removed.Free;
    Kept.Free;
  end;
end;

{ Клонировать окно }

// Заменить слово AOld на ANew во всей строке (границы - не буква/цифра/_)
function ReplaceWord(const ALine, AOld, ANew: string): string;
var
  WordAt, FromPos: Integer;
begin
  Result := ALine;
  FromPos := 1;
  repeat
    WordAt := WordPos(AOld, Result, FromPos);
    if WordAt > 0 then
    begin
      Result := Copy(Result, 1, WordAt - 1) + ANew + Copy(Result, WordAt + Length(AOld), MaxInt);
      FromPos := WordAt + Length(ANew);
    end;
  until WordAt = 0;
end;

// "StateVar = S", "StateVar == S", "StateVar != S" -> номер ANew
function ReplaceStateNum(const ALine, AStateVar: string; AOld, ANew: Integer): string;
var
  WordAt, CharPos, NumStart, FromPos: Integer;
begin
  Result := ALine;
  FromPos := 1;
  repeat
    WordAt := WordPos(AStateVar, Result, FromPos);
    if WordAt = 0 then
      Break;
    FromPos := WordAt + Length(AStateVar);
    CharPos := FromPos;
    while (CharPos <= Length(Result)) and (Result[CharPos] in [' ', #9]) do
      Inc(CharPos);
    if Copy(Result, CharPos, 2) = '==' then
      Inc(CharPos, 2)
    else if Copy(Result, CharPos, 2) = '!=' then
      Inc(CharPos, 2)
    else if (CharPos <= Length(Result)) and (Result[CharPos] = '=') then
      Inc(CharPos)
    else
      Continue;
    while (CharPos <= Length(Result)) and (Result[CharPos] in [' ', #9]) do
      Inc(CharPos);
    NumStart := CharPos;
    while (CharPos <= Length(Result)) and (Result[CharPos] in ['0'..'9']) do
      Inc(CharPos);
    if (CharPos > NumStart) and
       not ((CharPos <= Length(Result)) and IsIdentChar(Result[CharPos])) and
       (StrToIntDef(Copy(Result, NumStart, CharPos - NumStart), -1) = AOld) then
      Result := Copy(Result, 1, NumStart - 1) + IntToStr(ANew) + Copy(Result, CharPos, MaxInt);
  until False;
end;

// Слова строки ALine, похожие на идентификатор с окончанием ASuffix
procedure WordsWithSuffix(const ALine, ASuffix: string; AList: TStringList);
var
  CharPos, StartPos: Integer;
  Word: string;
begin
  CharPos := 1;
  while CharPos <= Length(ALine) do
  begin
    if IsIdentChar(ALine[CharPos]) then
    begin
      StartPos := CharPos;
      while (CharPos <= Length(ALine)) and IsIdentChar(ALine[CharPos]) do
        Inc(CharPos);
      Word := Copy(ALine, StartPos, CharPos - StartPos);
      if (Length(Word) > Length(ASuffix)) and
         (CompareText(Copy(Word, Length(Word) - Length(ASuffix) + 1, MaxInt), ASuffix) = 0) and
         (AList.IndexOf(Word) < 0) then
        AList.Add(Word);
    end
    else
      Inc(CharPos);
  end;
end;

function WnCloneWindow(AMap: TWmMap; const AParams: TWnParams; ASource: TWmNode;
  AFiles: TList; AFileNames: TStrings; var AReport: string): Boolean;
var
  PrevNode: TWmNode;
  FormsFile, ArrName, SrcName, NewName, Block, MarkText, CreateReport: string;
  FormsIdx, InoIdx, CaseIdx, SrcIdx, FileIdx, HeaderLine, EndLine, LineIdx,
  NameIdx, DeclStart, DeclEnd, ArrStart, ArrEnd, InsertAt, SrcArrIdx: Integer;
  Forms, SrcLines, Lines: TStringList;
  FuncText, ArrText, Words, OwnLabels, NewLabels, Reserved: TStringList;

  function Renamed(const ALine: string): string;
  var
    LabelIdx: Integer;
  begin
    Result := ALine;
    for LabelIdx := 0 to OwnLabels.Count - 1 do
      Result := ReplaceWord(Result, OwnLabels[LabelIdx], NewLabels[LabelIdx]);
    Result := ReplaceWord(Result, 'mnu' + SrcName, 'mnu' + NewName);
  end;

begin
  Result := False;
  AReport := '';
  SrcName := ASource.FuncName;
  NewName := 'Win' + IntToStr(AParams.NewState);
  MarkText := ' // unIDE: cloned from ' + SrcName;
  PrevNode := NodeOfStateIn(AMap, AParams.PrevState);
  if PrevNode = nil then
  begin
    AReport := 'Нет окна ' + IntToStr(AParams.PrevState) + '.';
    Exit;
  end;
  if not WnMenuArray(AMap, PrevNode, FormsFile, ArrName, nil) then
  begin
    AReport := 'У окна ' + PrevNode.Title + ' нет массива меню (TMenuItem): ' +
      'переход в клон не вставить автоматически.';
    Exit;
  end;
  FormsIdx := FileIndexOf(AFileNames, FormsFile);
  InoIdx := FileIndexOf(AFileNames, PrevNode.FileName);
  CaseIdx := FileIndexOf(AFileNames, PrevNode.CaseFile);
  SrcIdx := FileIndexOf(AFileNames, ASource.FileName);
  if (FormsIdx < 0) or (InoIdx < 0) or (CaseIdx < 0) or (SrcIdx < 0) then
  begin
    AReport := 'Не найдены файлы окон ' + PrevNode.Title + ' или ' + ASource.Title + '.';
    Exit;
  end;

  FuncText := TStringList.Create;
  ArrText := TStringList.Create;
  Words := TStringList.Create;
  OwnLabels := TStringList.Create;
  NewLabels := TStringList.Create;
  Reserved := TStringList.Create;
  try
    // 1. Исходное окно: функция, массив меню, его надписи (*_WinS)
    SrcLines := TStringList(AFiles[SrcIdx]);
    HeaderLine := FindFuncHeader(SrcLines, SrcName);
    EndLine := -1;
    if HeaderLine >= 0 then
      EndLine := FuncEndLine(SrcLines, HeaderLine);
    if EndLine < 0 then
    begin
      AReport := 'Не найдена функция ' + SrcName + '().';
      Exit;
    end;
    for LineIdx := HeaderLine to EndLine do
      FuncText.Add(SrcLines[LineIdx]);
    SrcArrIdx := -1;
    for FileIdx := 0 to AFiles.Count - 1 do
      if FindArray(TStringList(AFiles[FileIdx]), 'mnu' + SrcName, ArrStart, ArrEnd) then
      begin
        SrcArrIdx := FileIdx;
        for LineIdx := ArrStart to ArrEnd do
          ArrText.Add(TStringList(AFiles[FileIdx])[LineIdx]);
        Break;
      end;
    for LineIdx := 0 to FuncText.Count - 1 do
      WordsWithSuffix(FuncText[LineIdx], '_' + SrcName, Words);
    for LineIdx := 0 to ArrText.Count - 1 do
      WordsWithSuffix(ArrText[LineIdx], '_' + SrcName, Words);
    for NameIdx := 0 to Words.Count - 1 do
      if FindLabelAny(AFiles, Words[NameIdx], FileIdx, DeclStart, DeclEnd) then
      begin
        OwnLabels.Add(Words[NameIdx]);
        NewLabels.Add(PasteName(AFiles, Reserved, Words[NameIdx], SrcName, NewName));
        Reserved.Add(NewLabels[NewLabels.Count - 1]);
      end;
    // объявления копий - до правки файлов (места потом ищутся заново)
    Block := '';
    for NameIdx := 0 to OwnLabels.Count - 1 do
      if FindLabelAny(AFiles, OwnLabels[NameIdx], FileIdx, DeclStart, DeclEnd) then
        for LineIdx := DeclStart to DeclEnd do
        begin
          Lines := TStringList(AFiles[FileIdx]);
          if LineIdx = DeclStart then
            Block := Block + ReplaceWord(Lines[LineIdx], OwnLabels[NameIdx],
                                         NewLabels[NameIdx]) + MarkText + #10
          else
            Block := Block + Lines[LineIdx] + #10;
        end;

    // 2. Пустое окно с переходом из предыдущего - как «Создать новое окно»
    if not WnCreateWindow(AMap, AParams, TStringList(AFiles[FormsIdx]),
         TStringList(AFiles[InoIdx]), TStringList(AFiles[CaseIdx]), CreateReport) then
    begin
      AReport := CreateReport;
      Exit;
    end;

    // 3. Надписи заготовки -> копии надписей исходного окна
    Forms := TStringList(AFiles[FormsIdx]);
    InsertAt := -1;
    if FindLabelDecl(Forms, 'lblTitle_' + NewName, DeclStart, DeclEnd) then
    begin
      InsertAt := DeclStart;
      for LineIdx := DeclEnd downto DeclStart do
        Forms.Delete(LineIdx);
    end;
    if FindLabelDecl(Forms, 'lblNext_' + NewName, DeclStart, DeclEnd) then
      for LineIdx := DeclEnd downto DeclStart do
        Forms.Delete(LineIdx);
    // 4. Меню: копия массива исходного окна или (нет массива) - убрать
    if FindArray(Forms, 'mnu' + NewName, ArrStart, ArrEnd) then
    begin
      for LineIdx := ArrEnd downto ArrStart do
        Forms.Delete(LineIdx);
      if ArrText.Count > 0 then
      begin
        for LineIdx := ArrText.Count - 1 downto 0 do
          if LineIdx = 0 then
            Forms.Insert(ArrStart, Renamed(ArrText[LineIdx]) + MarkText)
          else
            Forms.Insert(ArrStart, Renamed(ArrText[LineIdx]));
      end
      else if (ArrStart > 0) and (Copy(TrimLeft(Forms[ArrStart - 1]), 1, 2) = '//') then
        Forms.Delete(ArrStart - 1);
    end;
    if InsertAt < 0 then
      InsertAt := Forms.Count;
    if InsertAt > Forms.Count then
      InsertAt := Forms.Count;
    InsertBlock(Forms, InsertAt, Block);

    // 5. Функция: тело заготовки -> копия исходной функции
    Lines := TStringList(AFiles[InoIdx]);
    HeaderLine := FindFuncHeader(Lines, NewName);
    EndLine := -1;
    if HeaderLine >= 0 then
      EndLine := FuncEndLine(Lines, HeaderLine);
    if EndLine < 0 then
    begin
      AReport := 'Не найдена созданная функция ' + NewName + '().';
      Exit;
    end;
    for LineIdx := EndLine downto HeaderLine do
      Lines.Delete(LineIdx);
    for LineIdx := FuncText.Count - 1 downto 0 do
    begin
      Block := Renamed(FuncText[LineIdx]);
      Block := ReplaceStateNum(Block, AMap.StateVar, ASource.State, AParams.NewState);
      if LineIdx = 0 then
      begin
        Block := ReplaceWord(Block, SrcName, NewName);
        if Pos('//', Block) > 0 then
          Block := Copy(Block, 1, Pos('//', Block) - 1);
        Block := TrimRight(Block) + ' // ' + AsciiOnly(AParams.Title, NewName) + ' (cloned from ' +
                 SrcName + ')';
      end;
      Lines.Insert(HeaderLine, Block);
    end;

    AReport := 'Клон ' + SrcName + ' -> ' + NewName + ': функция ' + NewName + '(), надписей ' +
      IntToStr(OwnLabels.Count);
    if ArrText.Count > 0 then
      AReport := AReport + ', меню mnu' + NewName
    else
      AReport := AReport + ', массива меню у ' + SrcName + ' нет';
    AReport := AReport + '; ' + StringReplace(Trim(Copy(CreateReport, 1,
      Pos(#13#10, CreateReport + #13#10) - 1)), #13#10, '; ', [rfReplaceAll]);
    if SrcArrIdx < 0 then
      SrcArrIdx := 0;
    Result := True;
  finally
    FuncText.Free;
    ArrText.Free;
    Words.Free;
    OwnLabels.Free;
    NewLabels.Free;
    Reserved.Free;
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
  FNextLabel := AddLabel('Следующее окно (куда ведёт новое):', 106);
  FNextCombo := AddCombo(124);
  FNextKeyLabel := AddLabel('Клавиша перехода в следующее окно:', 154);
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
  // клон - номер рядом с исходным окном
  if FCloneSource <> nil then
    FNumberEdit.Text := IntToStr(WnFreeState(FMap, FCloneSource.State))
  else if PrevNode <> nil then
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
  // клон: по умолчанию - новый пункт, прежний переход в исходное остаётся
  FInsertCheck.Checked := HasEdge and (FCloneSource = nil);
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
  else if (FCloneSource <> nil) and FInsertCheck.Checked and FInsertCheck.Enabled then
    FInfo.Caption := 'Пункт предыдущего окна будет вести в клон вместо ' +
      FCloneSource.Title + '.'
  else if FCloneSource <> nil then
    FInfo.Caption := 'В предыдущем окне появится новый пункт меню, ведущий в клон.'
  else if FInsertCheck.Checked and FInsertCheck.Enabled then
    FInfo.Caption := 'Пункт предыдущего окна будет вести в новое окно, а новое - ' +
      'в следующее.'
  else
    FInfo.Caption := 'В предыдущем окне появится новый пункт меню, прежние ' +
      'переходы останутся.';
end;

procedure TArdWinNewForm.SetCloneSource(ASource: TWmNode);
var
  NodeIdx: Integer;
begin
  FCloneSource := ASource;
  Caption := 'Клонировать окно ' + ASource.Title + '  ' + ASource.Caption;
  FNextLabel.Caption := 'Копируется окно (функция, надписи, меню):';
  FNextKeyLabel.Visible := False;
  FNextKeyCombo.Visible := False;
  for NodeIdx := 0 to FWindows.Count - 1 do
    if FWindows[NodeIdx] = ASource then
      FNextCombo.ItemIndex := NodeIdx;
  FNextCombo.Enabled := False;
  FInsertCheck.Caption := 'Вместо перехода в ' + ASource.Title;
  FTitleEdit.Text := AsciiOnly(ASource.Caption, ASource.FuncName) + ' (copy)';
  PrevChange(nil);
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
