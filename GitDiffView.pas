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
//    - сам код подсвечен по цветовой схеме unIDE для этого файла (схему
//      даёт OnScheme - Unit1.SchemeCopyFor по имени из заголовка разницы;
//      RTF строит SchemeRowsToRtf из SchemeRtf, как просмотр «по схеме»).
//  Фон окна и цвет текста - из схемы (без схемы - из темы: Edit.BG,
//  Edit.Text); цвета полос - свои для тёмного и светлого фона. RichEdit красит фон только
//  под символами, поэтому строки дополняются пробелами до самой длинной
//  (не длиннее DiffPadMax) - полосы идут во всю ширину.
//  Не разница (сообщение «выберите файл» и т. п.) - простым текстом.
//  Смена темы - текст перерисовывается новыми цветами (UM_UITHEMECHANGED).
//
//  Шаг 0.7.6 плана портирования: TGitDiffView - панель, внутри которой
//  окно TGitDiffRich (RichEdit, как было) или TGitDiffEd (свой редактор,
//  TEdRowsView - те же строки и цвета, без RTF). Какое - по флажку своего
//  редактора (EdOwnEditorOn), проверяется при каждом показе разницы.
//  Строки разницы строит BuildDiffRows - общая для обоих.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls, Forms,
  ComCtrls, ExtCtrls, UiTheme, ClrScheme, SchemeRtf, EdView, EdRows;

type
  // Схема подсветки для файла (свой объект - его освобождает окно); nil -
  // без подсветки
  TGitSchemeEvent = function(const AFileName: string): TClrScheme of object;

  // Разница в окне RichEdit (RTF) - как было до шага 0.7.6
  TGitDiffRich = class(TRichEdit)
  private
    FLastText: string;
    FOnScheme: TGitSchemeEvent;
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure ApplyLook;
    procedure Render;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Разница git или простой текст (определяется по содержимому)
    procedure ShowDiff(const AText: string);
    // Схема подсветки по имени файла из разницы
    property OnScheme: TGitSchemeEvent read FOnScheme write FOnScheme;
  end;

  // Разница в окне своего редактора
  TGitDiffEd = class(TEdRowsView)
  private
    FLastText: string;
    FOnScheme: TGitSchemeEvent;
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure Render;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ShowDiff(const AText: string);
    property OnScheme: TGitSchemeEvent read FOnScheme write FOnScheme;
  end;

  // Панель разницы для окон Commit и History: внутри - TGitDiffRich или
  // TGitDiffEd, по флажку своего редактора
  TGitDiffView = class(TPanel)
  private
    FRich: TGitDiffRich;
    FEd: TGitDiffEd;
    FOnScheme: TGitSchemeEvent;
    procedure SetOnScheme(AValue: TGitSchemeEvent);
  public
    constructor Create(AOwner: TComponent); override;
    // Разница git или простой текст (определяется по содержимому)
    procedure ShowDiff(const AText: string);
    property OnScheme: TGitSchemeEvent read FOnScheme write SetOnScheme;
  end;

implementation

const
  DiffPadMax = 300;        // строки длиннее не дополняются пробелами
  DiffTabSize = 4;
  EmStreamIn = WM_USER + 73;
  EmSetTargetDevice = WM_USER + 72;
  EmHideSelection = WM_USER + 63;
  SfRtf = $0002;


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
function ExpandTabs(const ALine: string): string;
var
  CharIdx: Integer;
begin
  Result := '';
  if Pos(#9, ALine) = 0 then
  begin
    Result := ALine;
    Exit;
  end;
  for CharIdx := 1 to Length(ALine) do
    if ALine[CharIdx] = #9 then
      repeat
        Result := Result + ' ';
      until Length(Result) mod DiffTabSize = 0
    else
      Result := Result + ALine[CharIdx];
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

constructor TGitDiffRich.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ReadOnly := True;
  PlainText := False;
  WordWrap := False;
  ScrollBars := ssBoth;
  BorderStyle := bsNone;
  // HideSelection, шрифт и цвета - в CreateWnd: у TRichEdit их установка
  // может обращаться к окну (Handle) и создавать его, а до Parent окна быть
  // не может - 'Control '' has no parent window'
  UiThemeAddClient(Self);
end;

// Шрифт и цвета темы - только когда окно есть
procedure TGitDiffRich.ApplyLook;
begin
  if not HandleAllocated then
    Exit;
  Font.Name := 'Courier New';
  Font.Size := 9;
  Color := UiThemeColor('Edit.BG');
  Font.Color := UiThemeColor('Edit.Text');
end;

destructor TGitDiffRich.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

// Окно - RichEdit 4.1 или 2.0 (у 1.0 из VCL нет цвета фона под текстом).
// Библиотека не выгружается (см. FmtView: окно живёт дольше модуля)
procedure TGitDiffRich.CreateParams(var Params: TCreateParams);
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

procedure TGitDiffRich.CreateWnd;
begin
  inherited CreateWnd;
  // Выделение видно и без фокуса
  SendMessage(Handle, EmHideSelection, 0, 0);
  ApplyLook;
  // Строки не переносятся (ширина «устройства» 1)
  SendMessage(Handle, EmSetTargetDevice, 0, 1);
  if FLastText <> '' then
    Render;
end;

procedure TGitDiffRich.UMUiThemeChanged(var Message: TMessage);
begin
  if HandleAllocated then
  begin
    ApplyLook;
    Render;
  end;
  Message.Result := 1;
end;

procedure TGitDiffRich.ShowDiff(const AText: string);
begin
  FLastText := AText;
  if HandleAllocated then
    Render;
end;

// Имя файла из заголовка разницы: +++ b/путь (новый файл - тоже), у
// удалённого - --- a/путь, иначе diff --git a/... b/путь. '' - нет
function DiffFileName(ALines: TStrings): string;
var
  LineIdx, SpacePos: Integer;
  Line: string;
begin
  Result := '';
  for LineIdx := 0 to ALines.Count - 1 do
  begin
    Line := ALines[LineIdx];
    if Copy(Line, 1, 3) = '@@ ' then
      Break;
    if (Copy(Line, 1, 6) = '+++ b/') then
    begin
      Result := Copy(Line, 7, MaxInt);
      Break;
    end;
    if (Copy(Line, 1, 6) = '--- a/') then
      Result := Copy(Line, 7, MaxInt)
    else if (Result = '') and (Copy(Line, 1, 11) = 'diff --git ') then
    begin
      SpacePos := Pos(' b/', Line);
      if SpacePos > 0 then
        Result := Copy(Line, SpacePos + 3, MaxInt);
    end;
  end;
  Result := Trim(Result);
  if (Result <> '') and (Result[1] = '"') then
    Result := Copy(Result, 2, Length(Result) - 2);
  Result := StringReplace(Result, '/', '\', [rfReplaceAll]);
end;

// Строки разницы для окна: схема (по имени файла, OnScheme; освобождает
// вызывающий), цвета фона и текста, строки с номерами, полосами и
// подсветкой. Не разница - строки простого текста
procedure BuildDiffRows(const AText: string; AOnScheme: TGitSchemeEvent;
  var ARows: TSchemeRows; var AScheme: TClrScheme;
  var APageBg, ATextFg: TColor);
var
  Lines: TStringList;
  Line, Gutter, FileName: string;
  LineIdx, RowCount, MaxWidth, OldNum, NewNum: Integer;
  InDiff, InHunk: Boolean;
  DimFg, NumberFg, HunkFg: TColor;
  AddBg, AddGutterBg, DelBg, DelGutterBg, HunkBg: TColor;

  // Строка: колонка номеров (AGutter на AGutterBg), вводный кусок, текст
  procedure AddRow(const AGutter: string; AGutterBg: TColor;
    const ALead, ARowText: string; AHighlight: Boolean; ARowFg, ARowBg: TColor;
    AReset: Boolean);
  begin
    if RowCount >= Length(ARows) then
      SetLength(ARows, RowCount * 2 + 16);
    ARows[RowCount].Prefix := AGutter;
    ARows[RowCount].PrefixFg := NumberFg;
    ARows[RowCount].PrefixBg := AGutterBg;
    ARows[RowCount].Lead := ALead;
    ARows[RowCount].Text := ExpandTabs(ARowText);
    ARows[RowCount].Highlight := AHighlight;
    ARows[RowCount].TextFg := ARowFg;
    ARows[RowCount].RowBg := ARowBg;
    if ARowBg <> clNone then
      ARows[RowCount].PadTo := MaxWidth
    else
      ARows[RowCount].PadTo := 0;
    ARows[RowCount].ResetBlock := AReset;
    Inc(RowCount);
  end;

begin
  AScheme := nil;
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    InDiff := LooksLikeDiff(Lines);
    // Схема - по имени файла в заголовке разницы
    if InDiff and Assigned(AOnScheme) then
    begin
      FileName := DiffFileName(Lines);
      if FileName <> '' then
        AScheme := AOnScheme(FileName);
    end;
    // Фон и текст - из схемы, без неё - из темы
    if AScheme <> nil then
    begin
      APageBg := SchemePageColor(AScheme);
      ATextFg := AScheme.FTextFG;
      if (ATextFg = clNone) or (ATextFg = clDefault) then
        ATextFg := clWindowText;
    end
    else
    begin
      APageBg := UiThemeColor('Edit.BG');
      ATextFg := UiThemeColor('Edit.Text');
    end;
    if IsDarkColor(APageBg) then
    begin
      DimFg := $00909090;
      NumberFg := $00808080;
      HunkFg := $00FFB48C;
      AddBg := $00243D1A;
      AddGutterBg := $002F551F;
      DelBg := $00221E4B;
      DelGutterBg := $002B266B;
      HunkBg := $004A2E1C;
    end
    else
    begin
      DimFg := $00808080;
      NumberFg := $0081776E;
      HunkFg := $006A6057;
      AddBg := $00ECFFE6;
      AddGutterBg := $00D8FFCC;
      DelBg := $00E9EBFF;
      DelGutterBg := $00D5D7FF;
      HunkBg := $00FFF4DD;
    end;

    // Ширина полос - по самой длинной строке
    MaxWidth := 0;
    if InDiff then
      for LineIdx := 0 to Lines.Count - 1 do
        if (Length(Lines[LineIdx]) <= DiffPadMax) and
           (Length(ExpandTabs(Lines[LineIdx])) > MaxWidth) then
          MaxWidth := Length(ExpandTabs(Lines[LineIdx]));
    Inc(MaxWidth, 2);

    SetLength(ARows, Lines.Count + 1);
    RowCount := 0;
    OldNum := 0;
    NewNum := 0;
    InHunk := False;
    Gutter := '            ';      // две колонки по 5 и пробелы
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Lines[LineIdx];
      if not InDiff then
        AddRow('', clNone, '', Line, False, ATextFg, clNone, False)
      else if Copy(Line, 1, 3) = '@@ ' then
      begin
        ParseHunk(Line, OldNum, NewNum);
        InHunk := True;
        AddRow('  ...  ...  ', HunkBg, '', Line, False, HunkFg, HunkBg, True);
      end
      else if Copy(Line, 1, 11) = 'diff --git ' then
      begin
        InHunk := False;
        AddRow(Gutter, clNone, '', Line, False, DimFg, clNone, True);
      end
      else if not InHunk then
        // index, ---, +++, new file mode ...
        AddRow(Gutter, clNone, '', Line, False, DimFg, clNone, True)
      else if Copy(Line, 1, 1) = '+' then
      begin
        AddRow(GutterNum(0) + ' ' + GutterNum(NewNum) + ' ', AddGutterBg,
          '+ ', Copy(Line, 2, MaxInt), True, ATextFg, AddBg, False);
        Inc(NewNum);
      end
      else if Copy(Line, 1, 1) = '-' then
      begin
        AddRow(GutterNum(OldNum) + ' ' + GutterNum(0) + ' ', DelGutterBg,
          '- ', Copy(Line, 2, MaxInt), True, ATextFg, DelBg, False);
        Inc(OldNum);
      end
      else if Copy(Line, 1, 1) = '\' then
        // \ No newline at end of file
        AddRow(Gutter, clNone, '', Line, False, DimFg, clNone, False)
      else
      begin
        AddRow(GutterNum(OldNum) + ' ' + GutterNum(NewNum) + ' ', clNone,
          '  ', Copy(Line, 2, MaxInt), True, ATextFg, clNone, False);
        Inc(OldNum);
        Inc(NewNum);
      end;
    end;
    SetLength(ARows, RowCount);
  finally
    Lines.Free;
  end;
end;

procedure TGitDiffRich.Render;
var
  Rows: TSchemeRows;
  Scheme: TClrScheme;
  Rtf: string;
  PageBg, TextFg: TColor;
  Source: TDiffStreamSource;
  Stream: TDiffEditStream;
begin
  if not HandleAllocated then
    Exit;
  Scheme := nil;
  try
    BuildDiffRows(FLastText, FOnScheme, Rows, Scheme, PageBg, TextFg);
    Rtf := SchemeRowsToRtf(Rows, Scheme, Font.Name, Font.Size, TextFg,
      PageBg);
  finally
    Scheme.Free;
  end;

  Color := PageBg;
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

// ---------------------------------------------------------------------------
//  TGitDiffEd - разница в окне своего редактора
// ---------------------------------------------------------------------------

constructor TGitDiffEd.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Font.Name := 'Courier New';
  Font.Size := 9;
  UiThemeAddClient(Self);
end;

destructor TGitDiffEd.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TGitDiffEd.UMUiThemeChanged(var Message: TMessage);
begin
  Render;
  Message.Result := 1;
end;

procedure TGitDiffEd.ShowDiff(const AText: string);
begin
  FLastText := AText;
  Render;
end;

procedure TGitDiffEd.Render;
var
  Rows: TSchemeRows;
  Scheme: TClrScheme;
  PageBg, TextFg: TColor;
begin
  Scheme := nil;
  try
    BuildDiffRows(FLastText, FOnScheme, Rows, Scheme, PageBg, TextFg);
    // Выделение - как у пунктов меню темы
    SelColor := UiThemeColor('Menu.HotBG');
    SelTextColor := UiThemeColor('Menu.HotText');
    ShowRows(Rows, Scheme, TextFg, PageBg);
  finally
    Scheme.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  TGitDiffView - панель: окно RichEdit или своего редактора
// ---------------------------------------------------------------------------

constructor TGitDiffView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
end;

procedure TGitDiffView.SetOnScheme(AValue: TGitSchemeEvent);
begin
  FOnScheme := AValue;
  if FRich <> nil then
    FRich.OnScheme := AValue;
  if FEd <> nil then
    FEd.OnScheme := AValue;
end;

procedure TGitDiffView.ShowDiff(const AText: string);
begin
  // Окно - по флажку своего редактора; флажок сменился - окно другое
  if EdOwnEditorOn then
  begin
    FreeAndNil(FRich);
    if FEd = nil then
    begin
      FEd := TGitDiffEd.Create(Self);
      FEd.Parent := Self;
      FEd.Align := alClient;
      FEd.OnScheme := FOnScheme;
    end;
    FEd.ShowDiff(AText);
  end
  else
  begin
    FreeAndNil(FEd);
    if FRich = nil then
    begin
      FRich := TGitDiffRich.Create(Self);
      FRich.Parent := Self;
      FRich.Align := alClient;
      FRich.OnScheme := FOnScheme;
    end;
    FRich.ShowDiff(AText);
  end;
end;
end.
