unit DlgIconEdit;

// Окно значков палитры (View - Palette Icons, или правая кнопка на кнопке
// палитры - Edit Icon): скрипт значка (формат - DsgIcons.pas), превью в
// светлой и тёмной теме, цвет частей. Применённое пишется в файл своих
// значков (palette_icons.txt рядом с программой) и сразу видно на палитре
// (OnApply - главное окно перерисовывает кнопки). Встроенный значок
// возвращает кнопка «Встроенный».
//
// Щелчок по крупному превью выделяет фигуру (команду скрипта) под мышью -
// последнюю нарисованную в этой точке; Ctrl+щелчок добавляет или убирает.
// Выделенные обведены рамкой, первая выделена в скрипте. «Цвет...» и «Цвет
// темы (@)» красят выделенные: вокруг каждой строки - @ цвет и возврат к
// цвету, что был до неё; лишние строки @ убираются (NormalizeColors).
//
// Окно описано в DlgIconEdit.dfm и правится в конструкторе форм. Форма
// создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, Dialogs,
  UiButton,       // TUiButton
  UiEditCtrls,    // TUiListBox, TUiMemo
  UiStdDlgs,      // TUiColorDialog
  DsgIcons,       // скрипты значков, свои значки
  DsgPalette,     // DsgDrawSmoothScript
  UiDialogs;      // MessageDlg, ShowMessage по теме - последним

type
  TDlgIconEdit = class(TForm)
    lstIcons: TUiListBox;
    lblScript: TLabel;
    memScript: TUiMemo;
    pbPreview: TPaintBox;
    lblState: TLabel;
    lblCoords: TLabel;
    lblHelp: TLabel;
    btnColor: TUiButton;
    btnThemeInk: TUiButton;
    btnBuiltin: TUiButton;
    btnApply: TUiButton;
    btnClose: TUiButton;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure lstIconsClick(Sender: TObject);
    procedure memScriptChange(Sender: TObject);
    procedure pbPreviewPaint(Sender: TObject);
    procedure pbPreviewMouseMove(Sender: TObject; Shift: TShiftState;
                                 X, Y: Integer);
    procedure pbPreviewMouseDown(Sender: TObject; Button: TMouseButton;
                                 Shift: TShiftState; X, Y: Integer);
    procedure memScriptClick(Sender: TObject);
    procedure memScriptKeyUp(Sender: TObject; var Key: Word;
                             Shift: TShiftState);
    procedure btnColorClick(Sender: TObject);
    procedure btnThemeInkClick(Sender: TObject);
    procedure btnBuiltinClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
  private
    FCurName: string;        // значок в окне
    FModified: Boolean;      // скрипт правили и не применили
    FLoading: Boolean;       // скрипт ставит код - не правка
    FLightInk, FLightBack, FDarkInk, FDarkBack: TColor;
    FOnApply: TNotifyEvent;
    // Выделенные фигуры: номера строк скрипта и их рамки (в точках холста
    // 96x96 - он же крупное превью)
    FSelLines: array of Integer;
    FSelBoxes: array of TRect;
    FKeepSel: Boolean;       // скрипт меняет покраска - выделение не сбрасывать
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
    function ItemName(AIndex: Integer): string;
    function ItemCaption(const AName: string): string;
    procedure FillList(const ASelect: string);
    procedure ShowIcon(const AName: string);
    function ScriptFromMemo: string;
    procedure UpdateState;
    function AskApply: Boolean;
    procedure InsertLine(const AText: string);
    procedure SaveUser;
    function IsDrawLine(ALineIdx: Integer): Boolean;
    function CommandBox(const ACmd: string; var ABox: TRect;
                        APixX, APixY: Integer; var AHit: Boolean): Boolean;
    function HitLine(APixX, APixY: Integer): Integer;
    procedure UpdateSelBoxes;
    procedure ShowSelInMemo;
    function IsSelected(ALineIdx: Integer): Boolean;
    procedure ToggleSel(ALineIdx: Integer);
    procedure ApplyColorToSel(const AColor: string);
  public
    // Цвета превью: значок и фон светлой и тёмной темы. ASelect - значок,
    // который открыть ('' - первый).
    procedure Prepare(const ASelect: string; ALightInk, ALightBack,
                      ADarkInk, ADarkBack: TColor);
    // Значки сменились (Применить, Встроенный): палитру - перерисовать
    property OnApply: TNotifyEvent read FOnApply write FOnApply;
  end;

implementation

{$R *.dfm}

const
  // Превью: крупно - в 4 раза, точка значка = 4 точки экрана
  PreviewZoom = 4;
  PreviewSide = 24;
  BigLeft = 8;
  BigTop = 18;
  SmallLeft = 8 + PreviewSide * PreviewZoom + 16;
  PanelHeight = PreviewSide * PreviewZoom + 26;
  // Отметка своего значка в списке
  UserMark = '  *';

procedure TDlgIconEdit.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgIconEdit.FormCreate(Sender: TObject);
begin
  FLightInk := clBlack;
  FLightBack := clBtnFace;
  FDarkInk := $00B0B0B0;
  FDarkBack := $00302D2D;
  lblHelp.Caption :=
    'Команда на строку, координаты в точках значка 24x24, дробные - через точку.' +
    #13#10 +
    'F x1 y1 x2 y2 - прямоугольник;  E ... - стереть;  R x1 y1 x2 y2 [w] - ' +
    'рамка;  O x1 y1 x2 y2 r [w] - скруглённая рамка' + #13#10 +
    'L x1 y1 x2 y2 [w] - линия;  C cx cy r [w] - окружность;  D cx cy r - ' +
    'круг;  K cx cy r - стереть круг' + #13#10 +
    'P x1 y1 x2 y2 ... - многоугольник;  Q ... - стереть;  T x y h B|N ' +
    'текст - надпись Arial' + #13#10 +
    '@ RRGGBB - дальше этим цветом;  @ - снова цветом значка темы.' +
    #13#10 +
    'Щелчок по крупному превью - выделить фигуру (Ctrl - несколько), ' +
    '«Цвет...» красит выделенные. Координаты под мышью - под превью.';
end;

procedure TDlgIconEdit.Prepare(const ASelect: string; ALightInk, ALightBack,
                               ADarkInk, ADarkBack: TColor);
begin
  FLightInk := ALightInk;
  FLightBack := ALightBack;
  FDarkInk := ADarkInk;
  FDarkBack := ADarkBack;
  FillList(ASelect);
end;

function TDlgIconEdit.ItemCaption(const AName: string): string;
begin
  Result := AName;
  if DsgIconUser(AName) <> '' then
    Result := Result + UserMark;
end;

function TDlgIconEdit.ItemName(AIndex: Integer): string;
var
  SpacePos: Integer;
begin
  Result := '';
  if (AIndex < 0) or (AIndex >= lstIcons.Items.Count) then
    Exit;
  Result := lstIcons.Items[AIndex];
  SpacePos := Pos(' ', Result);
  if SpacePos > 0 then
    Result := Copy(Result, 1, SpacePos - 1);
end;

procedure TDlgIconEdit.FillList(const ASelect: string);
var
  Names: TStringList;
  NameIdx, SelIdx: Integer;
begin
  Names := TStringList.Create;
  try
    DsgIconNames(Names);
    // Свои компоненты TUiX берут значок TX - ищем его
    if (CompareText(Copy(ASelect, 1, 3), 'TUi') = 0) and
       (Names.IndexOf(ASelect) < 0) then
      SelIdx := Names.IndexOf('T' + Copy(ASelect, 4, MaxInt))
    else
      SelIdx := Names.IndexOf(ASelect);
    lstIcons.Items.BeginUpdate;
    try
      lstIcons.Items.Clear;
      for NameIdx := 0 to Names.Count - 1 do
        lstIcons.Items.Add(ItemCaption(Names[NameIdx]));
    finally
      lstIcons.Items.EndUpdate;
    end;
  finally
    Names.Free;
  end;
  if SelIdx < 0 then
    SelIdx := 0;
  if lstIcons.Items.Count > 0 then
  begin
    lstIcons.ItemIndex := SelIdx;
    ShowIcon(ItemName(SelIdx));
  end;
end;

procedure TDlgIconEdit.ShowIcon(const AName: string);
var
  Script: string;
  CmdPos: Integer;
  Lines: TStringList;
begin
  FCurName := AName;
  Script := DsgIconScript(AName);
  Lines := TStringList.Create;
  try
    while Script <> '' do
    begin
      CmdPos := Pos(';', Script);
      if CmdPos = 0 then
        CmdPos := Length(Script) + 1;
      if Trim(Copy(Script, 1, CmdPos - 1)) <> '' then
        Lines.Add(Trim(Copy(Script, 1, CmdPos - 1)));
      Delete(Script, 1, CmdPos);
    end;
    FLoading := True;
    try
      memScript.Lines.Assign(Lines);
    finally
      FLoading := False;
    end;
  finally
    Lines.Free;
  end;
  FModified := False;
  UpdateState;
  pbPreview.Invalidate;
end;

function TDlgIconEdit.ScriptFromMemo: string;
var
  LineIdx: Integer;
  Line: string;
begin
  Result := '';
  for LineIdx := 0 to memScript.Lines.Count - 1 do
  begin
    Line := Trim(memScript.Lines[LineIdx]);
    if Line = '' then
      Continue;
    if Result <> '' then
      Result := Result + ';';
    Result := Result + Line;
  end;
end;

procedure TDlgIconEdit.UpdateState;
var
  Text: string;
begin
  if FCurName = '' then
    Text := ''
  else if DsgIconUser(FCurName) <> '' then
    Text := FCurName + ': свой значок (' +
            ExtractFileName(DsgIconUserFile) + ')'
  else if DsgIconBuiltin(FCurName) <> '' then
    Text := FCurName + ': встроенный значок'
  else
    Text := FCurName;
  if FModified then
    Text := Text + ' - изменён, не применён';
  lblState.Caption := Text;
  btnApply.Enabled := FModified;
  btnBuiltin.Enabled := (FCurName <> '') and
                        ((DsgIconUser(FCurName) <> '') or FModified) and
                        (DsgIconBuiltin(FCurName) <> '');
end;

// Изменённый скрипт при уходе с него: применить? False - не уходить.
function TDlgIconEdit.AskApply: Boolean;
begin
  Result := True;
  if not FModified then
    Exit;
  case MessageDlg('Значок ' + FCurName + ' изменён. Применить?',
                  mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
    mrYes:
      btnApplyClick(nil);
    mrNo:
      FModified := False;
  else
    Result := False;
  end;
end;

procedure TDlgIconEdit.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := AskApply;
end;

procedure TDlgIconEdit.lstIconsClick(Sender: TObject);
var
  NewName: string;
begin
  NewName := ItemName(lstIcons.ItemIndex);
  if (NewName = '') or (NewName = FCurName) then
    Exit;
  if not AskApply then
  begin
    // Остаёмся на прежнем
    lstIcons.ItemIndex := lstIcons.Items.IndexOf(ItemCaption(FCurName));
    Exit;
  end;
  ShowIcon(NewName);
end;

procedure TDlgIconEdit.memScriptChange(Sender: TObject);
begin
  if not FKeepSel then
  begin
    SetLength(FSelLines, 0);
    SetLength(FSelBoxes, 0);
  end;
  if FLoading then
    Exit;
  FModified := ScriptFromMemo <> DsgIconScript(FCurName);
  UpdateState;
  pbPreview.Invalidate;
end;

// Точки прозрачного цвета палитры (clOlive) - цветом фона ABack
procedure KeyToBack(ABmp: TBitmap; ABack: TColor);
type
  TRGBLine = array[0..32767] of TRGBTriple;
  PRGBLine = ^TRGBLine;
var
  PosX, PosY: Integer;
  Line: PRGBLine;
  KeyRGB, BackRGB: Longint;
begin
  KeyRGB := ColorToRGB(clOlive);
  BackRGB := ColorToRGB(ABack);
  ABmp.PixelFormat := pf24bit;
  for PosY := 0 to ABmp.Height - 1 do
  begin
    Line := ABmp.ScanLine[PosY];
    for PosX := 0 to ABmp.Width - 1 do
      if RGB(Line[PosX].rgbtRed, Line[PosX].rgbtGreen,
             Line[PosX].rgbtBlue) = KeyRGB then
      begin
        Line[PosX].rgbtRed := GetRValue(BackRGB);
        Line[PosX].rgbtGreen := GetGValue(BackRGB);
        Line[PosX].rgbtBlue := GetBValue(BackRGB);
      end;
  end;
end;

procedure TDlgIconEdit.pbPreviewPaint(Sender: TObject);
var
  Glyph: TBitmap;
  Script: string;
  PanelIdx, PanelTop, BoxIdx: Integer;
  Ink, Back: TColor;
  PanelRect: TRect;
begin
  Script := ScriptFromMemo;
  Glyph := TBitmap.Create;
  try
    for PanelIdx := 0 to 1 do
    begin
      if PanelIdx = 0 then
      begin
        Ink := FLightInk;
        Back := FLightBack;
      end
      else
      begin
        Ink := FDarkInk;
        Back := FDarkBack;
      end;
      PanelTop := PanelIdx * (PanelHeight + 4);
      PanelRect := Rect(0, PanelTop, pbPreview.Width, PanelTop + PanelHeight);
      pbPreview.Canvas.Brush.Style := bsSolid;
      pbPreview.Canvas.Brush.Color := Back;
      pbPreview.Canvas.FillRect(PanelRect);
      pbPreview.Canvas.Font := Font;
      pbPreview.Canvas.Font.Color := Ink;
      if PanelIdx = 0 then
        pbPreview.Canvas.TextOut(BigLeft, PanelTop + 2, 'Light')
      else
        pbPreview.Canvas.TextOut(BigLeft, PanelTop + 2, 'Dark');

      DsgDrawSmoothScript(Glyph, Script, Ink, Back);
      // Пустые точки - прозрачный цвет кнопки палитры (clOlive): здесь фон
      KeyToBack(Glyph, Back);
      // Крупно - без сглаживания растяжения: видна каждая точка
      SetStretchBltMode(pbPreview.Canvas.Handle, COLORONCOLOR);
      pbPreview.Canvas.StretchDraw(
        Rect(BigLeft, PanelTop + BigTop,
             BigLeft + PreviewSide * PreviewZoom,
             PanelTop + BigTop + PreviewSide * PreviewZoom), Glyph);
      pbPreview.Canvas.Draw(SmallLeft, PanelTop + BigTop +
                            (PreviewSide * PreviewZoom - PreviewSide) div 2,
                            Glyph);
      // Рамка крупного - границы поля 24x24
      pbPreview.Canvas.Brush.Style := bsClear;
      pbPreview.Canvas.Pen.Color := clGray;
      pbPreview.Canvas.Rectangle(BigLeft - 1, PanelTop + BigTop - 1,
                                 BigLeft + PreviewSide * PreviewZoom + 1,
                                 PanelTop + BigTop +
                                 PreviewSide * PreviewZoom + 1);
      // Выделенные фигуры
      pbPreview.Canvas.Pen.Color := clFuchsia;
      for BoxIdx := 0 to High(FSelBoxes) do
        pbPreview.Canvas.Rectangle(BigLeft + FSelBoxes[BoxIdx].Left - 2,
                                   PanelTop + BigTop + FSelBoxes[BoxIdx].Top - 2,
                                   BigLeft + FSelBoxes[BoxIdx].Right + 2,
                                   PanelTop + BigTop +
                                   FSelBoxes[BoxIdx].Bottom + 2);
    end;
  finally
    Glyph.Free;
  end;
end;

// Координата значка с шагом 0.25 - текстом с точкой, как в скрипте
function CoordText(APixels: Integer): string;
const
  Fractions: array[0..3] of string = ('', '.25', '.5', '.75');
begin
  Result := IntToStr(APixels div PreviewZoom) +
            Fractions[APixels mod PreviewZoom];
end;

procedure TDlgIconEdit.pbPreviewMouseMove(Sender: TObject; Shift: TShiftState;
                                          X, Y: Integer);
var
  PanelIdx, LocalY, LocalX: Integer;
begin
  lblCoords.Caption := '';
  for PanelIdx := 0 to 1 do
  begin
    LocalX := X - BigLeft;
    LocalY := Y - PanelIdx * (PanelHeight + 4) - BigTop;
    if (LocalX >= 0) and (LocalY >= 0) and
       (LocalX < PreviewSide * PreviewZoom) and
       (LocalY < PreviewSide * PreviewZoom) then
    begin
      lblCoords.Caption := 'x ' + CoordText(LocalX) + '   y ' +
                           CoordText(LocalY);
      Exit;
    end;
  end;
end;

// Строка AText - перед строкой каретки
procedure TDlgIconEdit.InsertLine(const AText: string);
var
  LineIdx: Integer;
begin
  LineIdx := memScript.CaretPos.Y;
  if (LineIdx < 0) or (LineIdx > memScript.Lines.Count) then
    LineIdx := memScript.Lines.Count;
  memScript.Lines.Insert(LineIdx, AText);
  memScript.SetFocus;
end;

procedure TDlgIconEdit.btnColorClick(Sender: TObject);
var
  ColorDlg: TUiColorDialog;
  RGBValue: Longint;
  ColorText: string;
begin
  ColorDlg := TUiColorDialog.Create(Self);
  try
    ColorDlg.Color := clRed;
    if not ColorDlg.Execute then
      Exit;
    RGBValue := ColorToRGB(ColorDlg.Color);
    ColorText := IntToHex(GetRValue(RGBValue), 2) +
                 IntToHex(GetGValue(RGBValue), 2) +
                 IntToHex(GetBValue(RGBValue), 2);
    if Length(FSelLines) > 0 then
      ApplyColorToSel(ColorText)
    else
      InsertLine('@ ' + ColorText);
  finally
    ColorDlg.Free;
  end;
end;

procedure TDlgIconEdit.btnThemeInkClick(Sender: TObject);
begin
  if Length(FSelLines) > 0 then
    ApplyColorToSel('')
  else
    InsertLine('@');
end;

// ---------------------------------------------------------------------------
//  Выделение фигур
// ---------------------------------------------------------------------------

// Строка скрипта - команда рисования (не пустая и не @)
function TDlgIconEdit.IsDrawLine(ALineIdx: Integer): Boolean;
var
  Line: string;
begin
  Result := False;
  if (ALineIdx < 0) or (ALineIdx >= memScript.Lines.Count) then
    Exit;
  Line := Trim(memScript.Lines[ALineIdx]);
  Result := (Line <> '') and (Line[1] <> '@');
end;

// Одна команда на холсте 96x96: её рамка ABox (что нарисовано не белым) и
// попадание в точку APixX, APixY с запасом в 2 точки (AHit). Стирающие
// (E, K, Q) рисуются как обычные - их место тоже можно выделить. False -
// команда ничего не нарисовала.
function TDlgIconEdit.CommandBox(const ACmd: string; var ABox: TRect;
                                 APixX, APixY: Integer;
                                 var AHit: Boolean): Boolean;
type
  TRGBLine = array[0..32767] of TRGBTriple;
  PRGBLine = ^TRGBLine;
const
  HitPad = 2;
var
  Mask: TBitmap;
  Cmd: string;
  PosX, PosY, Side: Integer;
  Line: PRGBLine;
begin
  Result := False;
  AHit := False;
  ABox := Rect(MaxInt, MaxInt, -1, -1);
  Cmd := Trim(ACmd);
  if (Cmd = '') or (Cmd[1] = '@') then
    Exit;
  // Стирающая команда - как рисующая, иначе её не видно на белом
  case UpCase(Cmd[1]) of
    'E': Cmd := 'F' + Copy(Cmd, 2, MaxInt);
    'K': Cmd := 'D' + Copy(Cmd, 2, MaxInt);
    'Q': Cmd := 'P' + Copy(Cmd, 2, MaxInt);
  end;
  Side := PreviewSide * PreviewZoom;
  Mask := TBitmap.Create;
  try
    Mask.PixelFormat := pf24bit;
    Mask.Width := Side;
    Mask.Height := Side;
    DsgPaintIcon(Mask.Canvas, Cmd);
    for PosY := 0 to Side - 1 do
    begin
      Line := Mask.ScanLine[PosY];
      for PosX := 0 to Side - 1 do
        if (Line[PosX].rgbtRed <> 255) or (Line[PosX].rgbtGreen <> 255) or
           (Line[PosX].rgbtBlue <> 255) then
        begin
          Result := True;
          if PosX < ABox.Left then
            ABox.Left := PosX;
          if PosY < ABox.Top then
            ABox.Top := PosY;
          if PosX + 1 > ABox.Right then
            ABox.Right := PosX + 1;
          if PosY + 1 > ABox.Bottom then
            ABox.Bottom := PosY + 1;
          if (Abs(PosX - APixX) <= HitPad) and (Abs(PosY - APixY) <= HitPad) then
            AHit := True;
        end;
    end;
  finally
    Mask.Free;
  end;
end;

// Строка фигуры под точкой холста: последняя нарисованная там. -1 - нет.
function TDlgIconEdit.HitLine(APixX, APixY: Integer): Integer;
var
  LineIdx: Integer;
  Box: TRect;
  Hit: Boolean;
begin
  Result := -1;
  for LineIdx := memScript.Lines.Count - 1 downto 0 do
    if IsDrawLine(LineIdx) and
       CommandBox(memScript.Lines[LineIdx], Box, APixX, APixY, Hit) and Hit then
    begin
      Result := LineIdx;
      Exit;
    end;
end;

function TDlgIconEdit.IsSelected(ALineIdx: Integer): Boolean;
var
  SelIdx: Integer;
begin
  Result := False;
  for SelIdx := 0 to High(FSelLines) do
    if FSelLines[SelIdx] = ALineIdx then
    begin
      Result := True;
      Exit;
    end;
end;

procedure TDlgIconEdit.ToggleSel(ALineIdx: Integer);
var
  SelIdx, MoveIdx: Integer;
begin
  for SelIdx := 0 to High(FSelLines) do
    if FSelLines[SelIdx] = ALineIdx then
    begin
      for MoveIdx := SelIdx to High(FSelLines) - 1 do
        FSelLines[MoveIdx] := FSelLines[MoveIdx + 1];
      SetLength(FSelLines, Length(FSelLines) - 1);
      Exit;
    end;
  SetLength(FSelLines, Length(FSelLines) + 1);
  FSelLines[High(FSelLines)] := ALineIdx;
end;

procedure TDlgIconEdit.UpdateSelBoxes;
var
  SelIdx: Integer;
  Hit: Boolean;
begin
  SetLength(FSelBoxes, 0);
  for SelIdx := 0 to High(FSelLines) do
  begin
    SetLength(FSelBoxes, Length(FSelBoxes) + 1);
    if not IsDrawLine(FSelLines[SelIdx]) or
       not CommandBox(memScript.Lines[FSelLines[SelIdx]],
                      FSelBoxes[High(FSelBoxes)], -100, -100, Hit) then
      SetLength(FSelBoxes, Length(FSelBoxes) - 1);
  end;
  if Length(FSelLines) > 0 then
    lblCoords.Caption := 'Выделено фигур: ' + IntToStr(Length(FSelLines));
  pbPreview.Invalidate;
end;

// Первая выделенная строка - выделена и в скрипте
procedure TDlgIconEdit.ShowSelInMemo;
var
  LineIdx: Integer;
begin
  if Length(FSelLines) = 0 then
    Exit;
  LineIdx := FSelLines[0];
  memScript.SelStart := memScript.Perform(EM_LINEINDEX, LineIdx, 0);
  memScript.SelLength := Length(memScript.Lines[LineIdx]);
  memScript.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TDlgIconEdit.pbPreviewMouseDown(Sender: TObject;
                                          Button: TMouseButton;
                                          Shift: TShiftState; X, Y: Integer);
var
  PanelIdx, LocalX, LocalY, LineIdx: Integer;
begin
  if Button <> mbLeft then
    Exit;
  for PanelIdx := 0 to 1 do
  begin
    LocalX := X - BigLeft;
    LocalY := Y - PanelIdx * (PanelHeight + 4) - BigTop;
    if (LocalX < 0) or (LocalY < 0) or
       (LocalX >= PreviewSide * PreviewZoom) or
       (LocalY >= PreviewSide * PreviewZoom) then
      Continue;
    LineIdx := HitLine(LocalX, LocalY);
    if ssCtrl in Shift then
    begin
      if LineIdx >= 0 then
        ToggleSel(LineIdx);
    end
    else
    begin
      SetLength(FSelLines, 0);
      if LineIdx >= 0 then
      begin
        SetLength(FSelLines, 1);
        FSelLines[0] := LineIdx;
      end;
    end;
    UpdateSelBoxes;
    ShowSelInMemo;
    Exit;
  end;
end;

// Каретка в скрипте на строке фигуры - она выделена
procedure TDlgIconEdit.memScriptClick(Sender: TObject);
var
  LineIdx: Integer;
begin
  LineIdx := memScript.CaretPos.Y;
  SetLength(FSelLines, 0);
  if IsDrawLine(LineIdx) then
  begin
    SetLength(FSelLines, 1);
    FSelLines[0] := LineIdx;
  end;
  UpdateSelBoxes;
end;

procedure TDlgIconEdit.memScriptKeyUp(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
begin
  if Key in [VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_HOME, VK_END] then
    memScriptClick(Sender);
end;

// Цвет строки @: '' - цвет темы
function ColorOfLine(const ALine: string): string;
begin
  Result := UpperCase(Trim(Copy(Trim(ALine), 2, MaxInt)));
end;

function IsColorLine(const ALine: string): Boolean;
var
  Line: string;
begin
  Line := Trim(ALine);
  Result := (Line <> '') and (Line[1] = '@');
end;

function ColorLineText(const AColor: string): string;
begin
  if AColor = '' then
    Result := '@'
  else
    Result := '@ ' + AColor;
end;

// Строки @, которые ничего не меняют, - вон: за которыми сразу другая @,
// после которых нет ни одной фигуры, и с тем же цветом, что уже действует
procedure NormalizeColors(ALines: TStrings);
var
  LineIdx, NextIdx: Integer;
  Active, LineColor: string;
begin
  Active := '';
  LineIdx := 0;
  while LineIdx < ALines.Count do
  begin
    if not IsColorLine(ALines[LineIdx]) then
    begin
      Inc(LineIdx);
      Continue;
    end;
    LineColor := ColorOfLine(ALines[LineIdx]);
    NextIdx := LineIdx + 1;
    while (NextIdx < ALines.Count) and (Trim(ALines[NextIdx]) = '') do
      Inc(NextIdx);
    if (NextIdx >= ALines.Count) or IsColorLine(ALines[NextIdx]) or
       (LineColor = Active) then
    begin
      ALines.Delete(LineIdx);
      Continue;
    end;
    Active := LineColor;
    Inc(LineIdx);
  end;
end;

// Выделенным фигурам - цвет AColor ('' - цвет темы): перед строкой
// "@ цвет", после - цвет, что действовал до неё
procedure TDlgIconEdit.ApplyColorToSel(const AColor: string);
var
  Lines: TStringList;
  Order: array of Integer;
  SelIdx, SwapIdx, LineIdx, Swap: Integer;
  Before: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Assign(memScript.Lines);
    for LineIdx := 0 to Lines.Count - 1 do
      Lines.Objects[LineIdx] := nil;
    // С конца: вставки не сдвигают ещё не обработанные строки
    SetLength(Order, Length(FSelLines));
    for SelIdx := 0 to High(FSelLines) do
      Order[SelIdx] := FSelLines[SelIdx];
    for SelIdx := 0 to High(Order) - 1 do
      for SwapIdx := SelIdx + 1 to High(Order) do
        if Order[SwapIdx] > Order[SelIdx] then
        begin
          Swap := Order[SelIdx];
          Order[SelIdx] := Order[SwapIdx];
          Order[SwapIdx] := Swap;
        end;
    for SelIdx := 0 to High(Order) do
    begin
      LineIdx := Order[SelIdx];
      if (LineIdx < 0) or (LineIdx >= Lines.Count) then
        Continue;
      Lines.Objects[LineIdx] := TObject(1);   // выделенная - найти потом
      Before := '';
      for SwapIdx := LineIdx - 1 downto 0 do
        if IsColorLine(Lines[SwapIdx]) then
        begin
          Before := ColorOfLine(Lines[SwapIdx]);
          Break;
        end;
      if Before = UpperCase(AColor) then
        Continue;
      Lines.Insert(LineIdx + 1, ColorLineText(Before));
      Lines.Insert(LineIdx, ColorLineText(AColor));
    end;
    NormalizeColors(Lines);

    // Выделение - на те же фигуры на новых местах
    SetLength(FSelLines, 0);
    for LineIdx := 0 to Lines.Count - 1 do
      if Lines.Objects[LineIdx] <> nil then
      begin
        SetLength(FSelLines, Length(FSelLines) + 1);
        FSelLines[High(FSelLines)] := LineIdx;
      end;
    FKeepSel := True;
    try
      memScript.Lines.Assign(Lines);
    finally
      FKeepSel := False;
    end;
  finally
    Lines.Free;
  end;
  UpdateSelBoxes;
  ShowSelInMemo;
end;

procedure TDlgIconEdit.SaveUser;
var
  ErrText: string;
begin
  if not DsgIconSaveUser(ErrText) then
    ShowMessage('Файл своих значков не записан: ' + DsgIconUserFile +
                #13#10 + ErrText);
end;

procedure TDlgIconEdit.btnBuiltinClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  if FCurName = '' then
    Exit;
  DsgIconSetUser(FCurName, '');
  SaveUser;
  ItemIdx := lstIcons.ItemIndex;
  if ItemIdx >= 0 then
  begin
    lstIcons.Items[ItemIdx] := ItemCaption(FCurName);
    lstIcons.ItemIndex := ItemIdx;
  end;
  ShowIcon(FCurName);
  if Assigned(FOnApply) then
    FOnApply(Self);
end;

procedure TDlgIconEdit.btnApplyClick(Sender: TObject);
var
  Script: string;
  ItemIdx: Integer;
begin
  if FCurName = '' then
    Exit;
  Script := ScriptFromMemo;
  // Совпал со встроенным - свой не нужен
  if Script = DsgIconBuiltin(FCurName) then
    DsgIconSetUser(FCurName, '')
  else
    DsgIconSetUser(FCurName, Script);
  SaveUser;
  FModified := False;
  ItemIdx := lstIcons.ItemIndex;
  if ItemName(ItemIdx) <> FCurName then
    ItemIdx := lstIcons.Items.IndexOf(FCurName);
  if ItemIdx < 0 then
    ItemIdx := lstIcons.Items.IndexOf(FCurName + UserMark);
  if ItemIdx >= 0 then
  begin
    lstIcons.Items[ItemIdx] := ItemCaption(FCurName);
    // Замена строки снимает выделение - если это была выделенная, вернуть
    if lstIcons.ItemIndex < 0 then
      lstIcons.ItemIndex := ItemIdx;
  end;
  UpdateState;
  if Assigned(FOnApply) then
    FOnApply(Self);
end;

end.
