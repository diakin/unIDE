unit UiStdDlgs;

// ---------------------------------------------------------------------------
//  Свои диалоги выбора цвета и шрифта по теме UiTheme:
//
//    TUiColorDialog - наследник TColorDialog: Color, CustomColors, Options,
//                     Execute - как у него
//    TUiFontDialog  - наследник TFontDialog: Font, Options, MinFontSize,
//                     MaxFontSize, OnApply, Execute - как у него
//
//  В теме Light при включённых темах Windows Execute показывает диалог
//  Windows (как у предка); в темах Dark и Custom - своё окно из своих
//  элементов.
//
//  Цвет: основные цвета (48, как в диалоге Windows), свои цвета (16,
//  CustomColors - строки ColorA=RRGGBB... как у TColorDialog), поле
//  оттенка и насыщенности, полоса яркости, R, G, B и #RRGGBB, образец
//  «было / стало».
//
//  Шрифт: список шрифтов с поиском по началу имени, начертание, размер,
//  зачёркнутый и подчёркнутый и цвет (fdEffects), образец. Учитываются
//  fdFixedPitchOnly (только моноширинные), fdLimitSize (MinFontSize,
//  MaxFontSize), fdApplyButton (кнопка «Применить» и OnApply).
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  UiTheme;

type
  TUiColorDialog = class(TColorDialog)
  public
    function Execute: Boolean; override;
  end;

  TUiFontDialog = class(TFontDialog)
  public
    function Execute: Boolean; override;
  end;

implementation

uses
  UiButton, UiStdCtrls, UiEditCtrls;

// ---------------------------------------------------------------------------
//  Цвет: HSL
// ---------------------------------------------------------------------------

procedure RgbToHsl(AColor: TColor; var H, S, L: Double);
var
  R, G, B, MaxV, MinV, Delta: Double;
  Rgb: Longint;
begin
  Rgb := ColorToRGB(AColor);
  R := GetRValue(Rgb) / 255;
  G := GetGValue(Rgb) / 255;
  B := GetBValue(Rgb) / 255;
  MaxV := R;
  if G > MaxV then MaxV := G;
  if B > MaxV then MaxV := B;
  MinV := R;
  if G < MinV then MinV := G;
  if B < MinV then MinV := B;
  L := (MaxV + MinV) / 2;
  Delta := MaxV - MinV;
  if Delta = 0 then
  begin
    H := 0;
    S := 0;
    Exit;
  end;
  if L < 0.5 then
    S := Delta / (MaxV + MinV)
  else
    S := Delta / (2 - MaxV - MinV);
  if MaxV = R then
    H := (G - B) / Delta
  else if MaxV = G then
    H := 2 + (B - R) / Delta
  else
    H := 4 + (R - G) / Delta;
  H := H * 60;
  if H < 0 then
    H := H + 360;
end;

function HslToColor(H, S, L: Double): TColor;

  function Part(P, Q, T: Double): Double;
  begin
    if T < 0 then T := T + 1;
    if T > 1 then T := T - 1;
    if T < 1 / 6 then
      Result := P + (Q - P) * 6 * T
    else if T < 1 / 2 then
      Result := Q
    else if T < 2 / 3 then
      Result := P + (Q - P) * (2 / 3 - T) * 6
    else
      Result := P;
  end;

var
  P, Q, Hue: Double;
begin
  if S <= 0 then
  begin
    Result := RGB(Round(L * 255), Round(L * 255), Round(L * 255));
    Exit;
  end;
  if L < 0.5 then
    Q := L * (1 + S)
  else
    Q := L + S - L * S;
  P := 2 * L - Q;
  Hue := H / 360;
  Result := RGB(Round(Part(P, Q, Hue + 1 / 3) * 255),
                Round(Part(P, Q, Hue) * 255),
                Round(Part(P, Q, Hue - 1 / 3) * 255));
end;

// ---------------------------------------------------------------------------
//  Элементы окна цвета
// ---------------------------------------------------------------------------

type
  TColorPickEvent = procedure(Sender: TObject; AColor: TColor) of object;

  // Сетка образцов: основные или свои цвета
  TUiSwatchGrid = class(TCustomControl)
  public
    Colors: array of TColor;
    Cols: Integer;
    Selected: Integer;
    OnPick: TColorPickEvent;
    constructor Create(AOwner: TComponent); override;
    function CellRect(AIndex: Integer): TRect;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        X, Y: Integer); override;
  end;

  // Поле оттенка (вправо) и насыщенности (вниз - меньше), яркость 0.5
  TUiHueSatArea = class(TCustomControl)
  public
    Hue, Sat: Double;
    Picture: TBitmap;
    OnChangeHS: TNotifyEvent;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure PickAt(X, Y: Integer);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  end;

  // Полоса яркости для текущих оттенка и насыщенности (вверху - светлее)
  TUiLumBar = class(TCustomControl)
  public
    Hue, Sat, Lum: Double;
    OnChangeL: TNotifyEvent;
    procedure Paint; override;
    procedure PickAt(Y: Integer);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  end;

  // Образец: слева «было», справа «стало»
  TUiColorPreview = class(TCustomControl)
  public
    OldColor, NewColor: TColor;
    procedure Paint; override;
  end;

constructor TUiSwatchGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Cols := 8;
  Selected := -1;
end;

function TUiSwatchGrid.CellRect(AIndex: Integer): TRect;
var
  CellW, CellH, Rows: Integer;
begin
  Rows := (Length(Colors) + Cols - 1) div Cols;
  if Rows < 1 then
    Rows := 1;
  CellW := ClientWidth div Cols;
  CellH := ClientHeight div Rows;
  Result := Rect((AIndex mod Cols) * CellW, (AIndex div Cols) * CellH,
                 (AIndex mod Cols) * CellW + CellW,
                 (AIndex div Cols) * CellH + CellH);
end;

procedure TUiSwatchGrid.Paint;
var
  Index: Integer;
  R: TRect;
begin
  Canvas.Brush.Color := UiThemeColor('Window.BG');
  Canvas.FillRect(ClientRect);
  for Index := 0 to Length(Colors) - 1 do
  begin
    R := CellRect(Index);
    InflateRect(R, -2, -2);
    if Index = Selected then
    begin
      Canvas.Brush.Color := UiThemeColor('Focus');
      Canvas.FillRect(R);
    end;
    InflateRect(R, -2, -2);
    Canvas.Brush.Color := UiThemeColor('Button.Border');
    Canvas.FrameRect(R);
    InflateRect(R, -1, -1);
    Canvas.Brush.Color := Colors[Index];
    Canvas.FillRect(R);
  end;
end;

procedure TUiSwatchGrid.MouseDown(Button: TMouseButton; Shift: TShiftState;
                                  X, Y: Integer);
var
  Index: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  for Index := 0 to Length(Colors) - 1 do
    if PtInRect(CellRect(Index), Point(X, Y)) then
    begin
      Selected := Index;
      Invalidate;
      if Assigned(OnPick) then
        OnPick(Self, Colors[Index]);
      Exit;
    end;
end;

constructor TUiHueSatArea.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  Picture := TBitmap.Create;
end;

destructor TUiHueSatArea.Destroy;
begin
  Picture.Free;
  inherited Destroy;
end;

procedure TUiHueSatArea.Paint;
var
  X, Y, W, H, MarkX, MarkY: Integer;
begin
  W := ClientWidth;
  H := ClientHeight;
  // Картинка поля - один раз на размер
  if (Picture.Width <> W) or (Picture.Height <> H) then
  begin
    Picture.Width := W;
    Picture.Height := H;
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
        Picture.Canvas.Pixels[X, Y] :=
          HslToColor(X * 360 / W, 1 - Y / H, 0.5);
  end;
  Canvas.Draw(0, 0, Picture);
  // Крестик - на выбранном
  MarkX := Round(Hue / 360 * W);
  MarkY := Round((1 - Sat) * H);
  Canvas.Pen.Color := clBlack;
  Canvas.MoveTo(MarkX - 6, MarkY);
  Canvas.LineTo(MarkX - 1, MarkY);
  Canvas.MoveTo(MarkX + 2, MarkY);
  Canvas.LineTo(MarkX + 7, MarkY);
  Canvas.MoveTo(MarkX, MarkY - 6);
  Canvas.LineTo(MarkX, MarkY - 1);
  Canvas.MoveTo(MarkX, MarkY + 2);
  Canvas.LineTo(MarkX, MarkY + 7);
end;

procedure TUiHueSatArea.PickAt(X, Y: Integer);
begin
  if X < 0 then X := 0;
  if X > ClientWidth - 1 then X := ClientWidth - 1;
  if Y < 0 then Y := 0;
  if Y > ClientHeight - 1 then Y := ClientHeight - 1;
  Hue := X * 360 / ClientWidth;
  Sat := 1 - Y / ClientHeight;
  Invalidate;
  if Assigned(OnChangeHS) then
    OnChangeHS(Self);
end;

procedure TUiHueSatArea.MouseDown(Button: TMouseButton; Shift: TShiftState;
                                  X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
    PickAt(X, Y);
end;

procedure TUiHueSatArea.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if ssLeft in Shift then
    PickAt(X, Y);
end;

procedure TUiLumBar.Paint;
var
  Y, H, MarkY: Integer;
begin
  H := ClientHeight;
  for Y := 0 to H - 1 do
  begin
    Canvas.Pen.Color := HslToColor(Hue, Sat, 1 - Y / (H - 1));
    Canvas.MoveTo(0, Y);
    Canvas.LineTo(ClientWidth - 6, Y);
  end;
  Canvas.Brush.Color := UiThemeColor('Window.BG');
  Canvas.FillRect(Rect(ClientWidth - 6, 0, ClientWidth, H));
  // Треугольник справа - на выбранной яркости
  MarkY := Round((1 - Lum) * (H - 1));
  Canvas.Pen.Color := UiThemeColor('Window.Text');
  Canvas.Brush.Color := UiThemeColor('Window.Text');
  Canvas.Polygon([Point(ClientWidth - 6, MarkY),
                  Point(ClientWidth - 1, MarkY - 4),
                  Point(ClientWidth - 1, MarkY + 4)]);
end;

procedure TUiLumBar.PickAt(Y: Integer);
begin
  if Y < 0 then Y := 0;
  if Y > ClientHeight - 1 then Y := ClientHeight - 1;
  Lum := 1 - Y / (ClientHeight - 1);
  Invalidate;
  if Assigned(OnChangeL) then
    OnChangeL(Self);
end;

procedure TUiLumBar.MouseDown(Button: TMouseButton; Shift: TShiftState;
                              X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
    PickAt(Y);
end;

procedure TUiLumBar.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if ssLeft in Shift then
    PickAt(Y);
end;

procedure TUiColorPreview.Paint;
var
  Half: Integer;
begin
  Half := ClientWidth div 2;
  Canvas.Brush.Color := OldColor;
  Canvas.FillRect(Rect(0, 0, Half, ClientHeight));
  Canvas.Brush.Color := NewColor;
  Canvas.FillRect(Rect(Half, 0, ClientWidth, ClientHeight));
  Canvas.Brush.Color := UiThemeColor('Button.Border');
  Canvas.FrameRect(ClientRect);
end;

// ---------------------------------------------------------------------------
//  Окно цвета
// ---------------------------------------------------------------------------

const
  // Основные цвета диалога Windows, $RRGGBB
  BasicColors: array[0..47] of Longint = (
    $FF8080, $FFFF80, $80FF80, $00FF80, $80FFFF, $0080FF, $FF80C0, $FF80FF,
    $FF0000, $FFFF00, $80FF00, $00FF40, $00FFFF, $0080C0, $8080C0, $FF00FF,
    $804040, $FF8040, $00FF00, $008080, $004080, $8080FF, $800040, $FF0080,
    $800000, $FF8000, $008000, $008040, $0000FF, $0000A0, $800080, $8000FF,
    $400000, $804000, $004000, $004040, $000080, $000040, $400040, $400080,
    $000000, $808000, $808040, $808080, $408080, $C0C0C0, $400040, $FFFFFF);

type
  TUiColorForm = class(TForm)
  private
    FDialog: TColorDialog;
    FColor: TColor;
    FUpdating: Boolean;
    FNextCustom: Integer;
    gridBasic, gridCustom: TUiSwatchGrid;
    areaHS: TUiHueSatArea;
    barL: TUiLumBar;
    preview: TUiColorPreview;
    edR, edG, edB, edHex: TUiEdit;
    procedure SetColorFrom(AColor: TColor; AFromPicker: Boolean);
    procedure SwatchPick(Sender: TObject; AColor: TColor);
    procedure AreaChange(Sender: TObject);
    procedure LumChange(Sender: TObject);
    procedure RgbChange(Sender: TObject);
    procedure HexChange(Sender: TObject);
    procedure AddCustomClick(Sender: TObject);
    procedure ReadCustom;
    procedure WriteCustom;
  public
    constructor CreateFor(ADialog: TColorDialog);
  end;

function NewLabel(AOwner: TWinControl; const ACaption: string;
  X, Y, W: Integer): TUiLabel;
begin
  Result := TUiLabel.Create(AOwner);
  Result.Parent := AOwner;
  Result.Caption := ACaption;
  Result.SetBounds(X, Y, W, 15);
end;

function NewEdit(AOwner: TWinControl; X, Y, W: Integer): TUiEdit;
begin
  Result := TUiEdit.Create(AOwner);
  Result.Parent := AOwner;
  Result.SetBounds(X, Y, W, 21);
end;

function NewButton(AOwner: TWinControl; const ACaption: string;
  X, Y, W: Integer): TUiButton;
begin
  Result := TUiButton.Create(AOwner);
  Result.Parent := AOwner;
  Result.Caption := ACaption;
  Result.SetBounds(X, Y, W, 25);
end;

procedure PrepareForm(AForm: TForm; const ACaption: string; W, H: Integer);
begin
  AForm.Caption := ACaption;
  AForm.BorderStyle := bsDialog;
  AForm.Position := poScreenCenter;
  if Application.MainForm <> nil then
    AForm.Font := Application.MainForm.Font;
  AForm.Color := UiThemeColor('Window.BG');
  AForm.Font.Color := UiThemeColor('Window.Text');
  AForm.ClientWidth := W;
  AForm.ClientHeight := H;
end;

constructor TUiColorForm.CreateFor(ADialog: TColorDialog);
var
  Index: Integer;
  Btn: TUiButton;
begin
  inherited CreateNew(Application);
  FDialog := ADialog;
  PrepareForm(Self, 'Цвет', 520, 330);

  NewLabel(Self, 'Основные цвета:', 12, 10, 200);
  gridBasic := TUiSwatchGrid.Create(Self);
  gridBasic.Parent := Self;
  gridBasic.SetBounds(12, 28, 208, 132);
  SetLength(gridBasic.Colors, Length(BasicColors));
  for Index := 0 to High(BasicColors) do
    gridBasic.Colors[Index] := RGB((BasicColors[Index] shr 16) and $FF,
                                   (BasicColors[Index] shr 8) and $FF,
                                   BasicColors[Index] and $FF);
  gridBasic.OnPick := SwatchPick;

  NewLabel(Self, 'Свои цвета:', 12, 170, 200);
  gridCustom := TUiSwatchGrid.Create(Self);
  gridCustom.Parent := Self;
  gridCustom.SetBounds(12, 188, 208, 44);
  SetLength(gridCustom.Colors, 16);
  gridCustom.OnPick := SwatchPick;
  ReadCustom;

  Btn := NewButton(Self, 'Добавить в свои', 12, 240, 208);
  Btn.OnClick := AddCustomClick;

  areaHS := TUiHueSatArea.Create(Self);
  areaHS.Parent := Self;
  areaHS.SetBounds(236, 28, 200, 160);
  areaHS.OnChangeHS := AreaChange;

  barL := TUiLumBar.Create(Self);
  barL.Parent := Self;
  barL.SetBounds(444, 28, 22, 160);
  barL.OnChangeL := LumChange;

  NewLabel(Self, 'Было / стало:', 236, 198, 100);
  preview := TUiColorPreview.Create(Self);
  preview.Parent := Self;
  preview.SetBounds(236, 216, 90, 40);

  NewLabel(Self, 'R', 340, 200, 12);
  edR := NewEdit(Self, 354, 197, 40);
  NewLabel(Self, 'G', 402, 200, 12);
  edG := NewEdit(Self, 416, 197, 40);
  NewLabel(Self, 'B', 464, 200, 12);
  edB := NewEdit(Self, 476, 197, 40);
  NewLabel(Self, '#', 340, 229, 12);
  edHex := NewEdit(Self, 354, 226, 72);
  edR.OnChange := RgbChange;
  edG.OnChange := RgbChange;
  edB.OnChange := RgbChange;
  edHex.OnChange := HexChange;

  Btn := NewButton(Self, 'Отмена', ClientWidth - 12 - 90, 292, 90);
  Btn.Cancel := True;
  Btn.ModalResult := mrCancel;
  Btn := NewButton(Self, 'OK', ClientWidth - 12 - 90 - 8 - 90, 292, 90);
  Btn.Default := True;
  Btn.ModalResult := mrOk;

  preview.OldColor := ColorToRGB(FDialog.Color);
  SetColorFrom(ColorToRGB(FDialog.Color), False);
end;

// Свои цвета из CustomColors: ColorA=RRGGBB ... ColorP (в шестнадцатеричном
// - число COLORREF, как пишет TColorDialog)
procedure TUiColorForm.ReadCustom;
var
  Index: Integer;
  Value: string;
begin
  for Index := 0 to 15 do
  begin
    Value := FDialog.CustomColors.Values['Color' + Chr(Ord('A') + Index)];
    if Value <> '' then
      gridCustom.Colors[Index] := StrToIntDef('$' + Value, $FFFFFF)
    else
      gridCustom.Colors[Index] := $FFFFFF;
  end;
end;

procedure TUiColorForm.WriteCustom;
var
  Index: Integer;
begin
  for Index := 0 to 15 do
    FDialog.CustomColors.Values['Color' + Chr(Ord('A') + Index)] :=
      IntToHex(ColorToRGB(gridCustom.Colors[Index]), 6);
end;

// Цвет - во все части окна; AFromPicker - пришёл из поля и полосы: их
// оттенок и насыщенность не пересчитываются (у серых оттенок не
// определён, и крестик прыгал бы)
procedure TUiColorForm.SetColorFrom(AColor: TColor; AFromPicker: Boolean);
var
  H, S, L: Double;
  Rgb: Longint;
begin
  FUpdating := True;
  try
    FColor := AColor;
    Rgb := ColorToRGB(AColor);
    if not AFromPicker then
    begin
      RgbToHsl(AColor, H, S, L);
      areaHS.Hue := H;
      areaHS.Sat := S;
      barL.Hue := H;
      barL.Sat := S;
      barL.Lum := L;
    end;
    areaHS.Invalidate;
    barL.Invalidate;
    preview.NewColor := AColor;
    preview.Invalidate;
    edR.Text := IntToStr(GetRValue(Rgb));
    edG.Text := IntToStr(GetGValue(Rgb));
    edB.Text := IntToStr(GetBValue(Rgb));
    edHex.Text := IntToHex(GetRValue(Rgb), 2) + IntToHex(GetGValue(Rgb), 2) +
                  IntToHex(GetBValue(Rgb), 2);
  finally
    FUpdating := False;
  end;
end;

procedure TUiColorForm.SwatchPick(Sender: TObject; AColor: TColor);
begin
  if Sender = gridBasic then
  begin
    gridCustom.Selected := -1;
    gridCustom.Invalidate;
  end
  else
  begin
    gridBasic.Selected := -1;
    gridBasic.Invalidate;
    FNextCustom := gridCustom.Selected;
  end;
  SetColorFrom(AColor, False);
end;

procedure TUiColorForm.AreaChange(Sender: TObject);
begin
  if FUpdating then
    Exit;
  barL.Hue := areaHS.Hue;
  barL.Sat := areaHS.Sat;
  SetColorFrom(HslToColor(areaHS.Hue, areaHS.Sat, barL.Lum), True);
end;

procedure TUiColorForm.LumChange(Sender: TObject);
begin
  if FUpdating then
    Exit;
  SetColorFrom(HslToColor(barL.Hue, barL.Sat, barL.Lum), True);
end;

procedure TUiColorForm.RgbChange(Sender: TObject);
var
  R, G, B: Integer;
begin
  if FUpdating then
    Exit;
  R := StrToIntDef(edR.Text, -1);
  G := StrToIntDef(edG.Text, -1);
  B := StrToIntDef(edB.Text, -1);
  if (R < 0) or (R > 255) or (G < 0) or (G > 255) or (B < 0) or (B > 255) then
    Exit;                     // пока вводят - ждём целого числа
  SetColorFrom(RGB(R, G, B), False);
end;

procedure TUiColorForm.HexChange(Sender: TObject);
var
  Value: Longint;
  Text: string;
begin
  if FUpdating then
    Exit;
  Text := Trim(edHex.Text);
  if (Length(Text) > 0) and (Text[1] = '#') then
    Delete(Text, 1, 1);
  if Length(Text) <> 6 then
    Exit;
  Value := StrToIntDef('$' + Text, -1);
  if Value < 0 then
    Exit;
  SetColorFrom(RGB((Value shr 16) and $FF, (Value shr 8) and $FF,
                   Value and $FF), False);
end;

// Текущий цвет - в свои: в выбранную ячейку, иначе по кругу
procedure TUiColorForm.AddCustomClick(Sender: TObject);
begin
  if (FNextCustom < 0) or (FNextCustom > 15) then
    FNextCustom := 0;
  gridCustom.Colors[FNextCustom] := FColor;
  gridCustom.Selected := FNextCustom;
  gridCustom.Invalidate;
  FNextCustom := (FNextCustom + 1) mod 16;
  WriteCustom;
end;

function TUiColorDialog.Execute: Boolean;
var
  Form: TUiColorForm;
begin
  if UiThemeNative then
  begin
    Result := inherited Execute;
    Exit;
  end;
  Form := TUiColorForm.CreateFor(Self);
  try
    DoShow;
    Result := Form.ShowModal = mrOk;
    if Result then
      Color := Form.FColor;
    DoClose;
  finally
    Form.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Окно шрифта
// ---------------------------------------------------------------------------

type
  // Образец текста выбранным шрифтом
  TUiFontPreview = class(TCustomControl)
  public
    SampleFont: TFont;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
  end;

  TUiFontForm = class(TForm)
  private
    FDialog: TFontDialog;
    FUpdating: Boolean;
    FColor: TColor;
    edFace, edSize: TUiEdit;
    lstFace, lstStyle, lstSize: TUiListBox;
    chkStrike, chkUnder: TUiCheckBox;
    btnColor: TUiButton;
    preview: TUiFontPreview;
    procedure FillFaces;
    procedure FaceEditChange(Sender: TObject);
    procedure ListClick(Sender: TObject);
    procedure SizeEditChange(Sender: TObject);
    procedure ColorClick(Sender: TObject);
    procedure ApplyClick(Sender: TObject);
    procedure UpdatePreview;
  public
    constructor CreateFor(ADialog: TFontDialog);
    procedure ReadResult(AFont: TFont);
  end;

const
  FontSizes: array[0..15] of Integer =
    (8, 9, 10, 11, 12, 14, 16, 18, 20, 22, 24, 26, 28, 36, 48, 72);
  StyleNames: array[0..3] of string =
    ('Обычный', 'Курсив', 'Жирный', 'Жирный курсив');

constructor TUiFontPreview.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SampleFont := TFont.Create;
end;

destructor TUiFontPreview.Destroy;
begin
  SampleFont.Free;
  inherited Destroy;
end;

procedure TUiFontPreview.Paint;
var
  R: TRect;
  S: string;
begin
  R := ClientRect;
  Canvas.Brush.Color := UiThemeColor('Edit.BG');
  Canvas.FillRect(R);
  Canvas.Brush.Color := UiThemeColor('Button.Border');
  Canvas.FrameRect(R);
  Canvas.Font := SampleFont;
  Canvas.Brush.Style := bsClear;
  S := 'AaBbYyZz АаБбЯя 0123';
  DrawText(Canvas.Handle, PChar(S), Length(S), R,
           DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
  Canvas.Brush.Style := bsSolid;
end;

constructor TUiFontForm.CreateFor(ADialog: TFontDialog);
var
  Index: Integer;
  Btn: TUiButton;
  Effects: Boolean;
begin
  inherited CreateNew(Application);
  FDialog := ADialog;
  PrepareForm(Self, 'Шрифт', 480, 390);
  Effects := fdEffects in FDialog.Options;

  NewLabel(Self, 'Шрифт:', 12, 10, 200);
  edFace := NewEdit(Self, 12, 28, 220);
  lstFace := TUiListBox.Create(Self);
  lstFace.Parent := Self;
  lstFace.SetBounds(12, 52, 220, 170);
  lstFace.Sorted := True;

  NewLabel(Self, 'Начертание:', 244, 10, 120);
  lstStyle := TUiListBox.Create(Self);
  lstStyle.Parent := Self;
  lstStyle.SetBounds(244, 28, 130, 72);
  for Index := 0 to High(StyleNames) do
    lstStyle.Items.Add(StyleNames[Index]);

  NewLabel(Self, 'Размер:', 386, 10, 80);
  edSize := NewEdit(Self, 386, 28, 82);
  lstSize := TUiListBox.Create(Self);
  lstSize.Parent := Self;
  lstSize.SetBounds(386, 52, 82, 170);
  for Index := 0 to High(FontSizes) do
    if not (fdLimitSize in FDialog.Options) or
       ((FontSizes[Index] >= FDialog.MinFontSize) and
        ((FDialog.MaxFontSize = 0) or
         (FontSizes[Index] <= FDialog.MaxFontSize))) then
      lstSize.Items.Add(IntToStr(FontSizes[Index]));

  chkStrike := TUiCheckBox.Create(Self);
  chkStrike.Parent := Self;
  chkStrike.Caption := 'Зачёркнутый';
  chkStrike.SetBounds(244, 112, 130, 17);
  chkStrike.Visible := Effects;
  chkUnder := TUiCheckBox.Create(Self);
  chkUnder.Parent := Self;
  chkUnder.Caption := 'Подчёркнутый';
  chkUnder.SetBounds(244, 134, 130, 17);
  chkUnder.Visible := Effects;
  btnColor := NewButton(Self, 'Цвет...', 244, 160, 130);
  btnColor.Visible := Effects;
  btnColor.OnClick := ColorClick;

  NewLabel(Self, 'Образец:', 12, 232, 100);
  preview := TUiFontPreview.Create(Self);
  preview.Parent := Self;
  preview.SetBounds(12, 250, ClientWidth - 24, 90);

  Btn := NewButton(Self, 'Отмена', ClientWidth - 12 - 90, 352, 90);
  Btn.Cancel := True;
  Btn.ModalResult := mrCancel;
  Btn := NewButton(Self, 'OK', Btn.Left - 8 - 90, 352, 90);
  Btn.Default := True;
  Btn.ModalResult := mrOk;
  if fdApplyButton in FDialog.Options then
  begin
    Btn := NewButton(Self, 'Применить', Btn.Left - 8 - 90, 352, 90);
    Btn.OnClick := ApplyClick;
  end;

  FillFaces;

  // Текущий шрифт диалога - в поля
  FUpdating := True;
  try
    edFace.Text := FDialog.Font.Name;
    lstFace.ItemIndex := lstFace.Items.IndexOf(FDialog.Font.Name);
    if (fsBold in FDialog.Font.Style) and (fsItalic in FDialog.Font.Style) then
      lstStyle.ItemIndex := 3
    else if fsBold in FDialog.Font.Style then
      lstStyle.ItemIndex := 2
    else if fsItalic in FDialog.Font.Style then
      lstStyle.ItemIndex := 1
    else
      lstStyle.ItemIndex := 0;
    edSize.Text := IntToStr(FDialog.Font.Size);
    lstSize.ItemIndex := lstSize.Items.IndexOf(edSize.Text);
    chkStrike.Checked := fsStrikeOut in FDialog.Font.Style;
    chkUnder.Checked := fsUnderline in FDialog.Font.Style;
    FColor := FDialog.Font.Color;
  finally
    FUpdating := False;
  end;

  edFace.OnChange := FaceEditChange;
  edSize.OnChange := SizeEditChange;
  lstFace.OnClick := ListClick;
  lstStyle.OnClick := ListClick;
  lstSize.OnClick := ListClick;
  chkStrike.OnClick := ListClick;
  chkUnder.OnClick := ListClick;
  UpdatePreview;
end;

// Шрифты системы; с fdFixedPitchOnly - только моноширинные (ширина «i» и
// «W» совпадает). Вертикальные (@имя) не показываются.
procedure TUiFontForm.FillFaces;
var
  Index: Integer;
  Face: string;
  Measure: TBitmap;
begin
  Measure := TBitmap.Create;
  lstFace.Items.BeginUpdate;
  try
    for Index := 0 to Screen.Fonts.Count - 1 do
    begin
      Face := Screen.Fonts[Index];
      if (Face = '') or (Face[1] = '@') then
        Continue;
      if fdFixedPitchOnly in FDialog.Options then
      begin
        Measure.Canvas.Font.Name := Face;
        Measure.Canvas.Font.Size := 10;
        if Measure.Canvas.TextWidth('i') <> Measure.Canvas.TextWidth('W') then
          Continue;
      end;
      lstFace.Items.Add(Face);
    end;
  finally
    lstFace.Items.EndUpdate;
    Measure.Free;
  end;
end;

// Поиск по началу имени шрифта
procedure TUiFontForm.FaceEditChange(Sender: TObject);
var
  Index: Integer;
begin
  if FUpdating then
    Exit;
  for Index := 0 to lstFace.Items.Count - 1 do
    if AnsiCompareText(Copy(lstFace.Items[Index], 1, Length(edFace.Text)),
                       edFace.Text) = 0 then
    begin
      lstFace.ItemIndex := Index;
      Break;
    end;
  UpdatePreview;
end;

procedure TUiFontForm.SizeEditChange(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FUpdating := True;
  try
    lstSize.ItemIndex := lstSize.Items.IndexOf(Trim(edSize.Text));
  finally
    FUpdating := False;
  end;
  UpdatePreview;
end;

procedure TUiFontForm.ListClick(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FUpdating := True;
  try
    if (Sender = lstFace) and (lstFace.ItemIndex >= 0) then
      edFace.Text := lstFace.Items[lstFace.ItemIndex];
    if (Sender = lstSize) and (lstSize.ItemIndex >= 0) then
      edSize.Text := lstSize.Items[lstSize.ItemIndex];
  finally
    FUpdating := False;
  end;
  UpdatePreview;
end;

procedure TUiFontForm.ColorClick(Sender: TObject);
var
  Dlg: TUiColorDialog;
begin
  Dlg := TUiColorDialog.Create(nil);
  try
    Dlg.Color := FColor;
    if Dlg.Execute then
    begin
      FColor := Dlg.Color;
      UpdatePreview;
    end;
  finally
    Dlg.Free;
  end;
end;

// Выбранное - в шрифт AFont (имя, размер, начертание, цвет; набор символов
// - как был)
procedure TUiFontForm.ReadResult(AFont: TFont);
var
  Style: TFontStyles;
  Size: Integer;
begin
  if lstFace.ItemIndex >= 0 then
    AFont.Name := lstFace.Items[lstFace.ItemIndex]
  else if Trim(edFace.Text) <> '' then
    AFont.Name := Trim(edFace.Text);
  Size := StrToIntDef(Trim(edSize.Text), AFont.Size);
  if fdLimitSize in FDialog.Options then
  begin
    if (FDialog.MinFontSize > 0) and (Size < FDialog.MinFontSize) then
      Size := FDialog.MinFontSize;
    if (FDialog.MaxFontSize > 0) and (Size > FDialog.MaxFontSize) then
      Size := FDialog.MaxFontSize;
  end;
  if Size > 0 then
    AFont.Size := Size;
  Style := [];
  case lstStyle.ItemIndex of
    1: Style := [fsItalic];
    2: Style := [fsBold];
    3: Style := [fsBold, fsItalic];
  end;
  if chkStrike.Checked then
    Include(Style, fsStrikeOut);
  if chkUnder.Checked then
    Include(Style, fsUnderline);
  AFont.Style := Style;
  if fdEffects in FDialog.Options then
    AFont.Color := FColor;
end;

procedure TUiFontForm.UpdatePreview;
begin
  preview.SampleFont.Assign(FDialog.Font);
  ReadResult(preview.SampleFont);
  if not (fdEffects in FDialog.Options) then
    preview.SampleFont.Color := UiThemeColor('Edit.Text');
  preview.Invalidate;
end;

// «Применить»: выбранное - в Font диалога и OnApply, окно остаётся
procedure TUiFontForm.ApplyClick(Sender: TObject);
begin
  ReadResult(FDialog.Font);
  if Assigned(FDialog.OnApply) then
    FDialog.OnApply(FDialog, Handle);
end;

function TUiFontDialog.Execute: Boolean;
var
  Form: TUiFontForm;
begin
  if UiThemeNative then
  begin
    Result := inherited Execute;
    Exit;
  end;
  Form := TUiFontForm.CreateFor(Self);
  try
    DoShow;
    Result := Form.ShowModal = mrOk;
    if Result then
      Form.ReadResult(Font);
    DoClose;
  finally
    Form.Free;
  end;
end;

initialization
  if GetClass(TUiColorDialog.ClassName) = nil then
    RegisterClass(TUiColorDialog);
  if GetClass(TUiFontDialog.ClassName) = nil then
    RegisterClass(TUiFontDialog);
end.
