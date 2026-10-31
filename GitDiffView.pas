unit GitDiffView;

// ---------------------------------------------------------------------------
//  Разница git (git diff) с подсветкой, как на GitHub: для окон Commit и
//  History (DlgGitCommit, DlgGitHistory).
//
//  TGitDiffView - окно своего редактора (TEdRowsView). Текст разницы
//  разбирается построчно:
//    - слева две колонки номеров строк - старый и новый файл;
//    - добавленные строки - зелёный фон, удалённые - красный, заголовок
//      куска (@@ -881,6 +881,10 @@) - синий; колонка номеров у них темнее;
//    - заголовки файла (diff --git, index, ---, +++) и «\ No newline» -
//      приглушённым цветом.
//    - сам код подсвечен по цветовой схеме unIDE для этого файла (схему
//      даёт OnScheme - Unit1.SchemeCopyFor по имени из заголовка разницы;
//      строки - TSchemeRows из SchemeRtf, как просмотр «по схеме»).
//  Фон окна и цвет текста - из схемы (без схемы - из темы: Edit.BG,
//  Edit.Text); цвета полос - свои для тёмного и светлого фона. Строки
//  дополняются пробелами до самой длинной (не длиннее DiffPadMax) - полосы
//  идут во всю ширину.
//  Не разница (сообщение «выберите файл» и т. п.) - простым текстом.
//  Смена темы - текст перерисовывается новыми цветами (UM_UITHEMECHANGED).
//
//  Шаг 0.7.7 плана портирования: окно RichEdit (TGitDiffRich, RTF) убрано,
//  разница всегда в окне своего редактора (TGitDiffEd).
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  ExtCtrls, UiTheme, ClrScheme, SchemeRtf, EdView, EdRows;

type
  // Схема подсветки для файла (свой объект - его освобождает окно); nil -
  // без подсветки
  TGitSchemeEvent = function(const AFileName: string): TClrScheme of object;

  // Строка о времени показа разницы (для Git log)
  TGitDiffTraceEvent = procedure(const AText: string) of object;

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

  // Панель разницы для окон Commit и History: внутри - TGitDiffEd
  TGitDiffView = class(TPanel)
  private
    FEd: TGitDiffEd;
    FOnScheme: TGitSchemeEvent;
    procedure SetOnScheme(AValue: TGitSchemeEvent);
  public
    constructor Create(AOwner: TComponent); override;
    // Разница git или простой текст (определяется по содержимому)
    procedure ShowDiff(const AText: string);
    property OnScheme: TGitSchemeEvent read FOnScheme write SetOnScheme;
  end;

var
  // Задано - TGitDiffEd.ShowDiff сообщает сюда размер разницы и время
  // показа (окно Commit, Unit1.GitCommitIn)
  GitDiffTrace: TGitDiffTraceEvent = nil;

implementation

const
  DiffPadMax = 300;        // строки длиннее не дополняются пробелами
  DiffTabSize = 4;

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

// ---------------------------------------------------------------------------
//  TGitDiffEd - разница в окне своего редактора
// ---------------------------------------------------------------------------

constructor TGitDiffEd.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Font.Name := 'Courier New';
  Font.Size := 9;
  UiThemeAddClient(Self);
  // Пустое окно - сразу цветами темы, а не белым: окно History показывает
  // разницу только после выбора коммита
  Render;
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
var
  StartTick: DWORD;
begin
  FLastText := AText;
  StartTick := GetTickCount;
  Render;
  if Assigned(GitDiffTrace) then
    GitDiffTrace('Git: показ разницы - ' + IntToStr(Length(AText) div 1024) +
      ' КБ, ' + IntToStr(GetTickCount - StartTick) + ' мс');
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
//  TGitDiffView - панель с окном своего редактора
// ---------------------------------------------------------------------------

constructor TGitDiffView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  FEd := TGitDiffEd.Create(Self);
  FEd.Parent := Self;
  FEd.Align := alClient;
end;

procedure TGitDiffView.SetOnScheme(AValue: TGitSchemeEvent);
begin
  FOnScheme := AValue;
  FEd.OnScheme := AValue;
end;

procedure TGitDiffView.ShowDiff(const AText: string);
begin
  FEd.ShowDiff(AText);
end;
end.
