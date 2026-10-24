unit GitDiffView;

// ---------------------------------------------------------------------------
//  Разница git (git diff) с подсветкой, как на GitHub: для окон Commit и
//  History (DlgGitCommit, DlgGitHistory).
//
//  TGitDiffView - RichEdit 4.1 (msftedit.dll) или 2.0 (riched20.dll), как
//  TRtfViewEdit в FmtView. Текст разницы разбирается построчно и
//  загружается одним RTF (EM_STREAMIN):
//    - слева две колонки номеров строк - старый и новый файл;
//    - добавленные строки - зелёный фон, удалённые - красный, заголовок
//      куска (@@ -881,6 +881,10 @@) - синий; колонка номеров у них темнее;
//    - заголовки файла (diff --git, index, ---, +++) и «\ No newline» -
//      приглушённым цветом.
//  Фон всего окна и цвет текста - из темы (Edit.BG, Edit.Text); цвета
//  строк - свои для тёмного и светлого фона. RichEdit красит фон только
//  под символами, поэтому строки дополняются пробелами до самой длинной
//  (не длиннее DiffPadMax) - полосы идут во всю ширину.
//  Не разница (сообщение «выберите файл» и т. п.) - простым текстом.
//  Смена темы - текст перерисовывается новыми цветами (UM_UITHEMECHANGED).
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, ComCtrls,
  UiTheme;

type
  TGitDiffView = class(TRichEdit)
  private
    FLastText: string;
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure Render;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Разница git или простой текст (определяется по содержимому)
    procedure ShowDiff(const AText: string);
  end;

implementation

const
  DiffPadMax = 300;        // строки длиннее не дополняются пробелами
  DiffTabSize = 4;
  EmStreamIn = WM_USER + 73;
  EmSetTargetDevice = WM_USER + 72;
  SfRtf = $0002;

  // Цвета таблицы RTF (\cfN, \highlightN)
  ciText = 1;
  ciDim = 2;
  ciNumber = 3;
  ciHunkText = 4;
  ciAddBack = 5;
  ciAddGutter = 6;
  ciDelBack = 7;
  ciDelGutter = 8;
  ciHunkBack = 9;
  ciCount = 9;

var
  DiffEditLib: HMODULE = 0;
  DiffEditClass: string = '';

type
  TDiffStreamCallback = function(ACookie: Longint; ABuffer: PByte;
    ACount: Longint; var ADone: Longint): Longint; stdcall;
  TDiffEditStream = record
    Cookie: Longint;
    Error: Longint;
    Callback: TDiffStreamCallback;
  end;
  TDiffStreamSource = record
    Data: string;
    ReadPos: Integer;
  end;
  PDiffStreamSource = ^TDiffStreamSource;

function DiffStreamRead(ACookie: Longint; ABuffer: PByte; ACount: Longint;
  var ADone: Longint): Longint; stdcall;
var
  Source: PDiffStreamSource;
  Left: Integer;
begin
  Source := PDiffStreamSource(ACookie);
  Left := Length(Source^.Data) - Source^.ReadPos + 1;
  if Left > ACount then
    Left := ACount;
  if Left < 0 then
    Left := 0;
  if Left > 0 then
    Move(Source^.Data[Source^.ReadPos], ABuffer^, Left);
  Inc(Source^.ReadPos, Left);
  ADone := Left;
  Result := 0;
end;

// Табуляции - пробелами до следующей позиции, кратной DiffTabSize
function ExpandTabs(const ALine: WideString): WideString;
var
  CharIdx: Integer;
begin
  Result := '';
  for CharIdx := 1 to Length(ALine) do
    if ALine[CharIdx] = #9 then
      repeat
        Result := Result + ' ';
      until Length(Result) mod DiffTabSize = 0
    else
      Result := Result + ALine[CharIdx];
end;

// Текст для RTF: \ { } - с обратной косой, не ASCII - \uN?
function RtfEscape(const AText: WideString): string;
var
  CharIdx, Code: Integer;
begin
  Result := '';
  for CharIdx := 1 to Length(AText) do
  begin
    Code := Ord(AText[CharIdx]);
    case Code of
      Ord('\'), Ord('{'), Ord('}'):
        Result := Result + '\' + Char(Code);
      32..91, 93..122, 124, 126:
        Result := Result + Char(Code);
    else
      if Code < 32 then
        Result := Result + ' '
      else if Code > 32767 then
        Result := Result + '\u' + IntToStr(Code - 65536) + '?'
      else
        Result := Result + '\u' + IntToStr(Code) + '?';
    end;
  end;
end;

function RtfColor(AColor: TColor): string;
var
  ColorRgb: Longint;
begin
  ColorRgb := ColorToRGB(AColor);
  Result := '\red' + IntToStr(GetRValue(ColorRgb)) + '\green' +
    IntToStr(GetGValue(ColorRgb)) + '\blue' + IntToStr(GetBValue(ColorRgb)) +
    ';';
end;

function IsDarkColor(AColor: TColor): Boolean;
var
  ColorRgb: Longint;
begin
  ColorRgb := ColorToRGB(AColor);
  Result := (GetRValue(ColorRgb) * 299 + GetGValue(ColorRgb) * 587 +
    GetBValue(ColorRgb) * 114) div 1000 < 128;
end;

// Номер для колонки (пусто - пробелы), ширина 5
function GutterNum(ANumber: Integer): string;
begin
  if ANumber <= 0 then
    Result := '     '
  else
    Result := Format('%5d', [ANumber]);
end;

// Разница ли это: есть строка заголовка куска @@ или diff --git
function LooksLikeDiff(ALines: TStrings): Boolean;
var
  LineIdx: Integer;
begin
  Result := False;
  for LineIdx := 0 to ALines.Count - 1 do
    if (Copy(ALines[LineIdx], 1, 3) = '@@ ') or
       (Copy(ALines[LineIdx], 1, 11) = 'diff --git ') then
    begin
      Result := True;
      Exit;
    end;
end;

// Номера начала из «@@ -881,6 +881,10 @@»
procedure ParseHunk(const ALine: string; var AOld, ANew: Integer);
var
  Rest: string;

  function TakeNumber(AMark: Char): Integer;
  var
    MarkPos, NumEnd: Integer;
  begin
    Result := 0;
    MarkPos := Pos(' ' + AMark, Rest);
    if MarkPos = 0 then
      Exit;
    NumEnd := MarkPos + 2;
    while (NumEnd <= Length(Rest)) and (Rest[NumEnd] in ['0'..'9']) do
      Inc(NumEnd);
    Result := StrToIntDef(Copy(Rest, MarkPos + 2, NumEnd - MarkPos - 2), 0);
  end;

begin
  Rest := ALine;
  AOld := TakeNumber('-');
  ANew := TakeNumber('+');
end;

constructor TGitDiffView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ReadOnly := True;
  PlainText := False;
  WordWrap := False;
  ScrollBars := ssBoth;
  HideSelection := False;
  BorderStyle := bsNone;
  Font.Name := 'Courier New';
  Font.Size := 9;
  Color := UiThemeColor('Edit.BG');
  Font.Color := UiThemeColor('Edit.Text');
  UiThemeAddClient(Self);
end;

destructor TGitDiffView.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

// Окно - RichEdit 4.1 или 2.0 (у 1.0 из VCL нет цвета фона под текстом).
// Библиотека не выгружается (см. FmtView: окно живёт дольше модуля)
procedure TGitDiffView.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if DiffEditClass = '' then
  begin
    DiffEditLib := LoadLibrary('msftedit.dll');
    if DiffEditLib <> 0 then
      DiffEditClass := 'RICHEDIT50W'
    else
    begin
      DiffEditLib := LoadLibrary('riched20.dll');
      if DiffEditLib <> 0 then
        DiffEditClass := 'RichEdit20A'
      else
        DiffEditClass := '-';
    end;
  end;
  if DiffEditClass <> '-' then
    CreateSubClass(Params, PChar(DiffEditClass));
end;

procedure TGitDiffView.CreateWnd;
begin
  inherited CreateWnd;
  // Строки не переносятся (ширина «устройства» 1)
  SendMessage(Handle, EmSetTargetDevice, 0, 1);
  if FLastText <> '' then
    Render;
end;

procedure TGitDiffView.UMUiThemeChanged(var Message: TMessage);
begin
  Color := UiThemeColor('Edit.BG');
  Font.Color := UiThemeColor('Edit.Text');
  if HandleAllocated then
    Render;
  Message.Result := 1;
end;

procedure TGitDiffView.ShowDiff(const AText: string);
begin
  FLastText := AText;
  if HandleAllocated then
    Render;
end;

procedure TGitDiffView.Render;
var
  Lines: TStringList;
  Rtf, Line, Gutter, Content: string;
  WideLine: WideString;
  Colors: array[1..ciCount] of TColor;
  LineIdx, MaxWidth, OldNum, NewNum, ColorIdx: Integer;
  InDiff, InHunk: Boolean;
  Source: TDiffStreamSource;
  Stream: TDiffEditStream;

  // Строка: колонка номеров (фон AGutterBack, 0 - без фона) и текст
  // (цвет ATextColor, фон ABack); фон - во всю ширину
  procedure AddRow(const AGutter: string; AGutterBack: Integer;
    const AText: WideString; ATextColor, ABack: Integer);
  var
    Shown: WideString;
  begin
    Shown := ExpandTabs(AText);
    if (ABack <> 0) and (Length(Shown) < MaxWidth) then
      Shown := Shown + StringOfChar(' ', MaxWidth - Length(Shown));
    Rtf := Rtf + '\highlight' + IntToStr(AGutterBack) + '\cf' +
      IntToStr(ciNumber) + ' ' + RtfEscape(AGutter) + '\highlight' +
      IntToStr(ABack) + '\cf' + IntToStr(ATextColor) + ' ' +
      RtfEscape(Shown) + '\highlight0\par'#13#10;
  end;

begin
  if not HandleAllocated then
    Exit;
  // Цвета: фон и текст - из темы, строки - для тёмного / светлого фона
  Colors[ciText] := Font.Color;
  if IsDarkColor(Color) then
  begin
    Colors[ciDim] := $00909090;
    Colors[ciNumber] := $00808080;
    Colors[ciHunkText] := $00FFB48C;
    Colors[ciAddBack] := $00243D1A;
    Colors[ciAddGutter] := $002F551F;
    Colors[ciDelBack] := $00221E4B;
    Colors[ciDelGutter] := $002B266B;
    Colors[ciHunkBack] := $004A2E1C;
  end
  else
  begin
    Colors[ciDim] := $00808080;
    Colors[ciNumber] := $0081776E;
    Colors[ciHunkText] := $006A6057;
    Colors[ciAddBack] := $00ECFFE6;
    Colors[ciAddGutter] := $00D8FFCC;
    Colors[ciDelBack] := $00E9EBFF;
    Colors[ciDelGutter] := $00D5D7FF;
    Colors[ciHunkBack] := $00FFF4DD;
  end;

  Lines := TStringList.Create;
  try
    Lines.Text := FLastText;
    InDiff := LooksLikeDiff(Lines);
    // Ширина полос - по самой длинной строке
    MaxWidth := 0;
    if InDiff then
      for LineIdx := 0 to Lines.Count - 1 do
      begin
        WideLine := ExpandTabs(WideString(Lines[LineIdx]));
        if (Length(WideLine) > MaxWidth) and
           (Length(WideLine) <= DiffPadMax) then
          MaxWidth := Length(WideLine);
      end;
    Inc(MaxWidth, 2);

    Rtf := '{\rtf1\ansi\ansicpg1251\deff0{\fonttbl{\f0\fmodern\fcharset204 ' +
      Font.Name + ';}}{\colortbl ;';
    for ColorIdx := 1 to ciCount do
      Rtf := Rtf + RtfColor(Colors[ColorIdx]);
    Rtf := Rtf + '}\f0\fs' + IntToStr(Font.Size * 2) + ' ';

    OldNum := 0;
    NewNum := 0;
    InHunk := False;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Lines[LineIdx];
      WideLine := WideString(Line);
      if not InDiff then
      begin
        Rtf := Rtf + '\cf' + IntToStr(ciText) + ' ' +
          RtfEscape(ExpandTabs(WideLine)) + '\par'#13#10;
        Continue;
      end;
      Gutter := '            ';    // две колонки по 5 и пробелы
      if Copy(Line, 1, 3) = '@@ ' then
      begin
        ParseHunk(Line, OldNum, NewNum);
        InHunk := True;
        AddRow('  ...  ...  ', ciHunkBack, WideLine, ciHunkText, ciHunkBack);
      end
      else if Copy(Line, 1, 11) = 'diff --git ' then
      begin
        InHunk := False;
        AddRow(Gutter, 0, WideLine, ciDim, 0);
      end
      else if not InHunk then
        AddRow(Gutter, 0, WideLine, ciDim, 0)   // index, ---, +++, mode
      else if Copy(Line, 1, 1) = '+' then
      begin
        Content := '+ ' + Copy(Line, 2, MaxInt);
        AddRow(GutterNum(0) + ' ' + GutterNum(NewNum) + ' ', ciAddGutter,
          WideString(Content), ciText, ciAddBack);
        Inc(NewNum);
      end
      else if Copy(Line, 1, 1) = '-' then
      begin
        Content := '- ' + Copy(Line, 2, MaxInt);
        AddRow(GutterNum(OldNum) + ' ' + GutterNum(0) + ' ', ciDelGutter,
          WideString(Content), ciText, ciDelBack);
        Inc(OldNum);
      end
      else if Copy(Line, 1, 1) = '\' then
        AddRow(Gutter, 0, WideLine, ciDim, 0)   // \ No newline at end of file
      else
      begin
        Content := '  ' + Copy(Line, 2, MaxInt);
        AddRow(GutterNum(OldNum) + ' ' + GutterNum(NewNum) + ' ', 0,
          WideString(Content), ciText, 0);
        Inc(OldNum);
        Inc(NewNum);
      end;
    end;
    Rtf := Rtf + '}';
  finally
    Lines.Free;
  end;

  Source.Data := Rtf;
  Source.ReadPos := 1;
  Stream.Cookie := Longint(@Source);
  Stream.Error := 0;
  Stream.Callback := DiffStreamRead;
  SendMessage(Handle, WM_SETREDRAW, 0, 0);
  try
    SendMessage(Handle, EmStreamIn, SfRtf, Longint(@Stream));
    SelStart := 0;
    SendMessage(Handle, WM_VSCROLL, SB_TOP, 0);
    SendMessage(Handle, WM_HSCROLL, SB_LEFT, 0);
  finally
    SendMessage(Handle, WM_SETREDRAW, 1, 0);
    Invalidate;
  end;
end;

end.
