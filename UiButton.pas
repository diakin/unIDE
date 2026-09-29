unit UiButton;

// ---------------------------------------------------------------------------
//  TUiButton - кнопка, которую рисует программа (TCustomControl), вместо
//  TButton в окнах самой IDE. Windows в её отрисовке не участвует: нет
//  стиля кнопки, темы, перехвата WM_PAINT - только Paint этого класса.
//
//  Поведение - как у TButton:
//    - щелчок мышью (нажали и отпустили над кнопкой), пробел в фокусе;
//    - Default: Enter в окне нажимает её, пока фокус не на другой кнопке;
//      кнопка в фокусе сама становится кнопкой для Enter;
//    - Cancel: Esc в окне;
//    - ModalResult: ставится окну перед OnClick;
//    - буква с & в Caption - Alt+буква.
//
//  Вид - по теме (UiTheme): в теме Light при включённых темах Windows
//  кнопка рисуется темой Windows, как системная; иначе - сама, цветами
//  ролей Button.*, Focus, OffText. Цвет шрифта кнопки (Font.Color) не
//  используется: шрифт от родителя несёт цвет текста панели. Свой цвет
//  подписи - TextColor (clNone - по теме).
//
//  TUiIconButton - кнопка-значок для панелей инструментов (вместо
//  TSpeedButton). Квадрат 34x34 (значок 24x24) с фоном родителя. Слои снизу
//  вверх:
//    1. скруглённый прямоугольник во всю кнопку - цветом фона родителя, а
//       когда над кнопкой мышь - цветом выделения (HotColor);
//    2. подложка - такой же прямоугольник, на RingWidth меньше с каждой
//       стороны (FaceColor): вокруг неё остаётся ободок первого слоя;
//    3. значок по центру; нажатую - сдвинут на пиксель. Сам значок - Glyph, как у TSpeedButton: прозрачный
//  цвет - левый нижний пиксель, при NumGlyphs = 2 правая половина - значок
//  недоступной кнопки. 32-битный Glyph (pf32bit) - с альфа-каналом:
//  цвета умножены на альфу, рисуется через AlphaBlend, сглаженные края
//  ложатся на любой фон. Фокуса не берёт: щелчок не уводит его из поля ввода.
//
//  Фон - цвет родителя (Color): в IDE Dark это цвет роли панели.
//  Цвет выделения - HotColor; clNone - роль темы IconButton.HotBG. Цвет
//  подложки - FaceColor; clNone - роль IconButton.BG.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  UiTheme;

type
  TUiButton = class(TCustomControl)
  private
    FDefault: Boolean;
    FCancel: Boolean;
    FModalResult: TModalResult;
    FActive: Boolean;     // Enter в окне нажимает эту кнопку
    FHot: Boolean;        // мышь над кнопкой
    FPressing: Boolean;   // левая кнопка мыши нажата на ней и держится
    FMouseIn: Boolean;    // при этом мышь над кнопкой
    FKeyDown: Boolean;    // пробел нажат и держится
    FTextColor: TColor;
    procedure SetDefault(Value: Boolean);
    procedure SetTextColor(Value: TColor);
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMDialogKey(var Message: TCMDialogKey); message CM_DIALOGKEY;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMFocusChanged(var Message: TCMFocusChanged); message CM_FOCUSCHANGED;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure PaintNative;
    procedure PaintOwn;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
                      X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
  published
    property Default: Boolean read FDefault write SetDefault default False;
    property Cancel: Boolean read FCancel write FCancel default False;
    property ModalResult: TModalResult read FModalResult write FModalResult
      default 0;
    // Цвет подписи этой кнопки; clNone - общий (UiButtonSetColors)
    property TextColor: TColor read FTextColor write SetTextColor
      default clNone;
    property Align;
    property Anchors;
    property Caption;
    property Constraints;
    property Enabled;
    property Font;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

  TUiIconButton = class(TCustomControl)
  private
    FGlyph: TBitmap;
    FNumGlyphs: Integer;
    FHotColor: TColor;
    FFaceColor: TColor;
    FRingWidth: Integer;
    FCornerRadius: Integer;
    FHot: Boolean;          // мышь над кнопкой
    FPressing: Boolean;     // левая кнопка мыши нажата на ней и держится
    FMouseIn: Boolean;      // при этом мышь над кнопкой
    FCellNormal: TBitmap;   // значок обычный - вырезан из Glyph
    FCellOff: TBitmap;      // значок недоступной кнопки
    FCellsReady: Boolean;
    FOffForDark: Boolean;   // FCellOff построен под тёмный фон
    FCellAlpha: Boolean;    // значки 32-битные с альфа-каналом (AlphaBlend)
    procedure BuildAlphaCells;
    procedure SetGlyph(Value: TBitmap);
    procedure SetNumGlyphs(Value: Integer);
    procedure SetHotColor(Value: TColor);
    procedure SetFaceColor(Value: TColor);
    procedure SetRingWidth(Value: Integer);
    function  ActualFaceColor: TColor;
    procedure SetCornerRadius(Value: Integer);
    procedure GlyphChanged(Sender: TObject);
    procedure BuildCells;
    function  BackColor: TColor;
    function  ActualHotColor: TColor;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
                      X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
  published
    // Значок; при NumGlyphs = 2 - два рядом: обычный и недоступный
    property Glyph: TBitmap read FGlyph write SetGlyph;
    property NumGlyphs: Integer read FNumGlyphs write SetNumGlyphs default 1;
    // Цвет прямоугольника под значком, когда над кнопкой мышь; clNone -
    // роль темы IconButton.HotBG
    property HotColor: TColor read FHotColor write SetHotColor default clNone;
    // Скругление углов этого прямоугольника, пикселей (у подложки - на
    // RingWidth меньше)
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius
      default 8;
    // Цвет подложки под значком; clNone - роль темы IconButton.BG
    property FaceColor: TColor read FFaceColor write SetFaceColor
      default clNone;
    // Ширина ободка выделения вокруг подложки, пикселей; 0 - подложки нет
    property RingWidth: Integer read FRingWidth write SetRingWidth default 2;
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  Themes;

const
  // WM_QUERYUISTATE: скрыто ли подчёркивание букв (пока не нажат Alt)
  WM_QUERYUISTATE_ = $0129;
  UISF_HIDEFOCUS_ = $0001;
  UISF_HIDEACCEL_ = $0002;
  DT_HIDEPREFIX_ = $00100000;

type
  // Доступ к защищённому Color родителя
  TUiParentAcc = class(TWinControl);

// ---------------------------------------------------------------------------
//  TUiButton
// ---------------------------------------------------------------------------

constructor TUiButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // csClickEvents: Click - когда кнопку мыши отпустили над кнопкой (это
  // делает TControl); csCaptureMouse - мышь за кнопкой, пока держат
  ControlStyle := [csCaptureMouse, csClickEvents, csSetCaption, csOpaque];
  Width := 75;
  Height := 25;
  TabStop := True;
  FTextColor := clNone;
  UiThemeAddClient(Self);
end;

destructor TUiButton.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

// Тема сменилась - перерисоваться (Result 0: UiThemeChanged сделает это
// сам через Invalidate)
procedure TUiButton.UMUiThemeChanged(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TUiButton.SetDefault(Value: Boolean);
var
  Form: TCustomForm;
begin
  FDefault := Value;
  FActive := Value;
  // Как у TButton: окно заново решает, какая кнопка отвечает на Enter
  if HandleAllocated then
  begin
    Form := GetParentForm(Self);
    if Form <> nil then
      Form.Perform(CM_FOCUSCHANGED, 0, Longint(Form.ActiveControl));
  end;
  Invalidate;
end;

procedure TUiButton.SetTextColor(Value: TColor);
begin
  if FTextColor <> Value then
  begin
    FTextColor := Value;
    Invalidate;
  end;
end;

procedure TUiButton.Click;
var
  Form: TCustomForm;
begin
  // Обработчик может открыть окно - кнопка к этому времени уже отжата
  FPressing := False;
  FKeyDown := False;
  Invalidate;
  Form := GetParentForm(Self);
  if Form <> nil then
    Form.ModalResult := ModalResult;
  inherited Click;
end;

procedure TUiButton.Paint;
begin
  if UiThemeNativeFor(Self) then
    PaintNative
  else
    PaintOwn;
end;

// Тема Light: кнопка темы Windows - фон, рамка, состояние; подпись -
// системным цветом текста кнопки
procedure TUiButton.PaintNative;
var
  R: TRect;
  TB: TThemedButton;
  Details: TThemedElementDetails;
  S: string;
  Fl: Cardinal;
begin
  R := ClientRect;
  // Углы кнопки темы скруглены - под ними цвет родителя
  if Parent <> nil then
    Canvas.Brush.Color := TUiParentAcc(Parent).Color
  else
    Canvas.Brush.Color := clBtnFace;
  Canvas.FillRect(R);

  if not Enabled then
    TB := tbPushButtonDisabled
  else if (FPressing and FMouseIn) or FKeyDown then
    TB := tbPushButtonPressed
  else if FHot then
    TB := tbPushButtonHot
  else if Focused or FActive then
    TB := tbPushButtonDefaulted
  else
    TB := tbPushButtonNormal;
  Details := ThemeServices.GetElementDetails(TB);
  ThemeServices.DrawElement(Canvas.Handle, Details, R);

  Canvas.Font := Font;
  if not Enabled then
    Canvas.Font.Color := clGrayText
  else if FTextColor <> clNone then
    Canvas.Font.Color := FTextColor
  else
    Canvas.Font.Color := clBtnText;
  S := Caption;
  InflateRect(R, -3, -2);
  Fl := DT_CENTER or DT_VCENTER or DT_SINGLELINE;
  if HandleAllocated and
     ((SendMessage(Handle, WM_QUERYUISTATE_, 0, 0) and UISF_HIDEACCEL_) <> 0) then
    Fl := Fl or DT_HIDEPREFIX_;
  Canvas.Brush.Style := bsClear;
  DrawText(Canvas.Handle, PChar(S), Length(S), R, Fl);
  Canvas.Brush.Style := bsSolid;

  // Рамка фокуса, как у системной кнопки
  if Focused and HandleAllocated and
     ((SendMessage(Handle, WM_QUERYUISTATE_, 0, 0) and UISF_HIDEFOCUS_) = 0) then
  begin
    R := ClientRect;
    InflateRect(R, -3, -3);
    Canvas.Brush.Color := clBtnFace;
    Canvas.Font.Color := clBtnText;
    Canvas.DrawFocusRect(R);
  end;
end;

// Темы Dark и Custom (и Light без тем Windows): кнопка рисуется сама
// цветами ролей
procedure TUiButton.PaintOwn;
var
  R: TRect;
  Off, Down, Mark: Boolean;
  S: string;
  Fl: Cardinal;
begin
  R := ClientRect;
  Off := not Enabled;
  Down := (FPressing and FMouseIn) or FKeyDown;
  // Двойная рамка цветом фокуса: кнопка в фокусе или та, что нажмётся по
  // Enter
  Mark := (Focused or FActive) and not Off;

  with Canvas do
  begin
    Brush.Style := bsSolid;
    if Down then
      Brush.Color := UiThemeColorFor(Self, 'Button.DownBG')
    else if FHot and not Off then
      Brush.Color := UiThemeColorFor(Self, 'Button.HotBG')
    else
      Brush.Color := UiThemeColorFor(Self, 'Button.BG');
    Pen.Style := psSolid;
    Pen.Width := 1;
    if Mark then
      Pen.Color := UiThemeColorFor(Self, 'Focus')
    else
      Pen.Color := UiThemeColorFor(Self, 'Button.Border');
    Rectangle(R.Left, R.Top, R.Right, R.Bottom);
    if Mark then
    begin
      Brush.Style := bsClear;
      Rectangle(R.Left + 1, R.Top + 1, R.Right - 1, R.Bottom - 1);
      Brush.Style := bsSolid;
    end;

    Font := Self.Font;
    if Off then
      Font.Color := UiThemeColorFor(Self, 'OffText')
    else if FTextColor <> clNone then
      Font.Color := FTextColor
    else
      Font.Color := UiThemeColorFor(Self, 'Button.Text');
    S := Caption;
    InflateRect(R, -3, -2);
    if Down then
      OffsetRect(R, 1, 1);
    Fl := DT_CENTER or DT_VCENTER or DT_SINGLELINE;
    // Self.: внутри with Canvas Handle и HandleAllocated - у холста
    if Self.HandleAllocated and
       ((SendMessage(Self.Handle, WM_QUERYUISTATE_, 0, 0) and
         UISF_HIDEACCEL_) <> 0) then
      Fl := Fl or DT_HIDEPREFIX_;
    Brush.Style := bsClear;
    DrawText(Handle, PChar(S), Length(S), R, Fl);
    Brush.Style := bsSolid;
  end;
end;

procedure TUiButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
                              X, Y: Integer);
begin
  if (Button = mbLeft) and Enabled then
  begin
    // Как TButton: щелчок забирает фокус
    if CanFocus and not Focused then
      SetFocus;
    FPressing := True;
    FMouseIn := True;
    Invalidate;
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TUiButton.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  InNow: Boolean;
begin
  if FPressing then
  begin
    InNow := PtInRect(ClientRect, Point(X, Y));
    if InNow <> FMouseIn then
    begin
      FMouseIn := InNow;
      Invalidate;
    end;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TUiButton.MouseUp(Button: TMouseButton; Shift: TShiftState;
                            X, Y: Integer);
begin
  if (Button = mbLeft) and FPressing then
  begin
    FPressing := False;
    Invalidate;
  end;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TUiButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) and (Shift = []) and not FKeyDown then
  begin
    FKeyDown := True;
    Invalidate;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TUiButton.KeyUp(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) and FKeyDown then
  begin
    FKeyDown := False;
    Invalidate;
    Click;
  end;
  inherited KeyUp(Key, Shift);
end;

procedure TUiButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  if not FHot then
  begin
    FHot := True;
    Invalidate;
  end;
end;

procedure TUiButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot then
  begin
    FHot := False;
    Invalidate;
  end;
end;

procedure TUiButton.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  if not Enabled then
  begin
    FPressing := False;
    FKeyDown := False;
  end;
  Invalidate;
end;

procedure TUiButton.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TUiButton.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

// Enter и Esc в окне: как у TButton
procedure TUiButton.CMDialogKey(var Message: TCMDialogKey);
begin
  with Message do
    if (((CharCode = VK_RETURN) and FActive) or
        ((CharCode = VK_ESCAPE) and FCancel)) and
       (KeyDataToShiftState(KeyData) = []) and CanFocus then
    begin
      Click;
      Result := 1;
    end
    else
      inherited;
end;

// Alt+буква из Caption
procedure TUiButton.CMDialogChar(var Message: TCMDialogChar);
begin
  with Message do
    if IsAccel(CharCode, Caption) and CanFocus then
    begin
      Click;
      Result := 1;
    end
    else
      inherited;
end;

// Фокус перешёл: на кнопку - Enter нажимает её; на другое - кнопку Default
procedure TUiButton.CMFocusChanged(var Message: TCMFocusChanged);
var
  Was: Boolean;
begin
  Was := FActive;
  if (Message.Sender is TUiButton) or (Message.Sender is TButton) then
    FActive := Message.Sender = Self
  else
    FActive := FDefault;
  if Was <> FActive then
    Invalidate;
  inherited;
end;

procedure TUiButton.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  Invalidate;
end;

procedure TUiButton.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  FKeyDown := False;
  Invalidate;
end;

procedure TUiButton.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  // Paint закрашивает всю кнопку сам
  Message.Result := 1;
end;

// ---------------------------------------------------------------------------
//  TUiIconButton
// ---------------------------------------------------------------------------

type
  // Доступ к защищённому Color родителя
  TUiIconParentAcc = class(TWinControl);

constructor TUiIconButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Как у TUiButton: Click - когда кнопку мыши отпустили над кнопкой
  ControlStyle := [csCaptureMouse, csClickEvents, csOpaque];
  Width := 34;
  Height := 34;
  TabStop := False;
  FNumGlyphs := 1;
  FHotColor := clNone;
  FFaceColor := clNone;
  FRingWidth := 2;
  FCornerRadius := 8;
  FGlyph := TBitmap.Create;
  FGlyph.OnChange := GlyphChanged;
  FCellNormal := TBitmap.Create;
  FCellOff := TBitmap.Create;
  UiThemeAddClient(Self);
end;

destructor TUiIconButton.Destroy;
begin
  UiThemeRemoveClient(Self);
  FCellOff.Free;
  FCellNormal.Free;
  FGlyph.Free;
  inherited Destroy;
end;

procedure TUiIconButton.SetGlyph(Value: TBitmap);
begin
  FGlyph.Assign(Value);   // OnChange -> GlyphChanged
end;

// Как у TSpeedButton: ширина - целое число высот, их столько и значков
procedure TUiIconButton.GlyphChanged(Sender: TObject);
var
  Count: Integer;
begin
  if not FGlyph.Empty and (FGlyph.Height > 0) and
     (FGlyph.Width mod FGlyph.Height = 0) then
  begin
    Count := FGlyph.Width div FGlyph.Height;
    if Count > 2 then
      Count := 1;
    FNumGlyphs := Count;
  end;
  FCellsReady := False;
  Invalidate;
end;

procedure TUiIconButton.SetNumGlyphs(Value: Integer);
begin
  if Value < 1 then
    Value := 1
  else if Value > 2 then
    Value := 2;
  if FNumGlyphs <> Value then
  begin
    FNumGlyphs := Value;
    FCellsReady := False;
    Invalidate;
  end;
end;

procedure TUiIconButton.SetHotColor(Value: TColor);
begin
  if FHotColor <> Value then
  begin
    FHotColor := Value;
    Invalidate;
  end;
end;

procedure TUiIconButton.SetFaceColor(Value: TColor);
begin
  if FFaceColor <> Value then
  begin
    FFaceColor := Value;
    Invalidate;
  end;
end;

procedure TUiIconButton.SetRingWidth(Value: Integer);
begin
  if Value < 0 then
    Value := 0;
  if FRingWidth <> Value then
  begin
    FRingWidth := Value;
    Invalidate;
  end;
end;

function TUiIconButton.ActualFaceColor: TColor;
begin
  Result := FFaceColor;
  if Result = clNone then
    Result := UiThemeColorFor(Self, 'IconButton.BG');
  if Result = clNone then
    Result := clBtnFace;
end;

procedure TUiIconButton.SetCornerRadius(Value: Integer);
begin
  if Value < 0 then
    Value := 0;
  if FCornerRadius <> Value then
  begin
    FCornerRadius := Value;
    Invalidate;
  end;
end;

// Цвет родителя - фон кнопки без тем Windows и основа для недоступного
// значка
function TUiIconButton.BackColor: TColor;
begin
  if Parent <> nil then
    Result := TUiIconParentAcc(Parent).Color
  else
    Result := clBtnFace;
end;

function TUiIconButton.ActualHotColor: TColor;
begin
  Result := FHotColor;
  if Result = clNone then
    Result := UiThemeColorFor(Self, 'IconButton.HotBG');
  if Result = clNone then
    Result := clHighlight;
end;

// Значки из Glyph: обычный и недоступный. Недоступного нет (NumGlyphs = 1)
// - он строится из обычного: серый, светлее на тёмном фоне, темнее на
// светлом, чтобы был виден, но не спорил с доступными.
procedure TUiIconButton.BuildCells;
var
  Side, PosX, PosY, Lum: Integer;
  KeyColor, PixColor: TColor;
  DarkBack: Boolean;
  Back: Longint;
begin
  Back := ColorToRGB(BackColor);
  DarkBack := (GetRValue(Back) * 299 + GetGValue(Back) * 587 +
               GetBValue(Back) * 114) div 1000 < 128;
  if FCellsReady and ((FNumGlyphs = 2) or (FOffForDark = DarkBack)) then
    Exit;
  FCellsReady := True;
  FOffForDark := DarkBack;
  FCellNormal.Width := 0;
  FCellOff.Width := 0;
  FCellAlpha := False;
  if FGlyph.Empty then
    Exit;
  if FGlyph.PixelFormat = pf32bit then
  begin
    BuildAlphaCells;
    Exit;
  end;
  Side := FGlyph.Width div FNumGlyphs;
  KeyColor := FGlyph.Canvas.Pixels[0, FGlyph.Height - 1];

  FCellNormal.PixelFormat := pf24bit;
  FCellNormal.Width := Side;
  FCellNormal.Height := FGlyph.Height;
  FCellNormal.Canvas.CopyRect(Rect(0, 0, Side, FGlyph.Height), FGlyph.Canvas,
                              Rect(0, 0, Side, FGlyph.Height));

  FCellOff.PixelFormat := pf24bit;
  FCellOff.Width := Side;
  FCellOff.Height := FGlyph.Height;
  if FNumGlyphs = 2 then
    FCellOff.Canvas.CopyRect(Rect(0, 0, Side, FGlyph.Height), FGlyph.Canvas,
                             Rect(Side, 0, Side * 2, FGlyph.Height))
  else
  begin
    FCellOff.Canvas.Draw(0, 0, FCellNormal);
    for PosY := 0 to FCellOff.Height - 1 do
      for PosX := 0 to Side - 1 do
      begin
        PixColor := FCellOff.Canvas.Pixels[PosX, PosY];
        if PixColor = KeyColor then
          Continue;
        PixColor := ColorToRGB(PixColor);
        Lum := (GetRValue(PixColor) * 30 + GetGValue(PixColor) * 59 +
                GetBValue(PixColor) * 11) div 100;
        if DarkBack then
          Lum := 60 + Lum div 3
        else
          Lum := 120 + Lum div 2;
        if Lum > 230 then
          Lum := 230;
        FCellOff.Canvas.Pixels[PosX, PosY] := RGB(Lum, Lum, Lum);
      end;
  end;
  FCellNormal.TransparentMode := tmFixed;
  FCellNormal.TransparentColor := KeyColor;
  FCellNormal.Transparent := True;
  FCellOff.TransparentMode := tmFixed;
  FCellOff.TransparentColor := KeyColor;
  FCellOff.Transparent := True;
end;

// 32-битный Glyph: значки копируются построчно, вместе с альфой (через
// Canvas она не сохраняется). Недоступного нет (NumGlyphs = 1) - серый из
// обычного, вдвое прозрачнее. Цвета в Glyph уже умножены на альфу.
procedure TUiIconButton.BuildAlphaCells;
type
  TQuadRow = array[0..32767] of TRGBQuad;
  PQuadRow = ^TQuadRow;
var
  Side, RowIdx, ColIdx, Lum: Integer;
  SrcRow, DstRow: PQuadRow;
  Src: TBitmap;
begin
  FCellAlpha := True;
  Side := FGlyph.Width div FNumGlyphs;
  // Строки - из копии: ScanLine у самого Glyph трогал бы его как
  // изменяемый (и OnChange - перерисовку по кругу)
  Src := TBitmap.Create;
  try
    Src.Assign(FGlyph);
    Src.PixelFormat := pf32bit;
    FCellNormal.PixelFormat := pf32bit;
    FCellNormal.Width := Side;
    FCellNormal.Height := FGlyph.Height;
    FCellOff.PixelFormat := pf32bit;
    FCellOff.Width := Side;
    FCellOff.Height := FGlyph.Height;
    for RowIdx := 0 to FGlyph.Height - 1 do
    begin
      SrcRow := Src.ScanLine[RowIdx];
      DstRow := FCellNormal.ScanLine[RowIdx];
      Move(SrcRow^[0], DstRow^[0], Side * SizeOf(TRGBQuad));
      DstRow := FCellOff.ScanLine[RowIdx];
      if FNumGlyphs = 2 then
        Move(SrcRow^[Side], DstRow^[0], Side * SizeOf(TRGBQuad))
      else
        for ColIdx := 0 to Side - 1 do
          with SrcRow^[ColIdx] do
          begin
            Lum := (rgbRed * 30 + rgbGreen * 59 + rgbBlue * 11) div 200;
            DstRow^[ColIdx].rgbRed := Lum;
            DstRow^[ColIdx].rgbGreen := Lum;
            DstRow^[ColIdx].rgbBlue := Lum;
            DstRow^[ColIdx].rgbReserved := rgbReserved div 2;
          end;
    end;
  finally
    Src.Free;
  end;
end;

procedure TUiIconButton.Paint;
const
  IconSrcAlpha = $01;   // AC_SRC_ALPHA: у значка своя альфа на точку
var
  Buf, Cell: TBitmap;
  Area, Inner: TRect;
  Shift, PosX, PosY, InnerRadius: Integer;
  ShowHot: Boolean;
  Blend: TBlendFunction;
begin
  Buf := TBitmap.Create;
  try
    Buf.Width := ClientWidth;
    Buf.Height := ClientHeight;
    Area := ClientRect;

    // Фон - цвет родителя. Не через тему Windows (DrawParentBackground):
    // родитель, который на WM_PRINTCLIENT ничего не рисует, оставлял бы в
    // буфере его начальный белый цвет.
    Buf.Canvas.Brush.Color := BackColor;
    Buf.Canvas.FillRect(Area);

    // Слой 1 - прямоугольник во всю кнопку: цвет фона, а под мышью (или
    // пока её держат нажатой) - цвет выделения
    ShowHot := Enabled and (FHot or (FPressing and FMouseIn));
    if ShowHot then
      Buf.Canvas.Brush.Color := ActualHotColor
    else
      Buf.Canvas.Brush.Color := BackColor;
    Buf.Canvas.Pen.Color := Buf.Canvas.Brush.Color;
    Buf.Canvas.RoundRect(Area.Left, Area.Top, Area.Right, Area.Bottom,
                         FCornerRadius * 2, FCornerRadius * 2);

    // Слой 2 - подложка, на ободок меньше: ободок первого слоя остаётся
    // вокруг неё
    if FRingWidth > 0 then
    begin
      Inner := Area;
      InflateRect(Inner, -FRingWidth, -FRingWidth);
      InnerRadius := FCornerRadius - FRingWidth;
      if InnerRadius < 0 then
        InnerRadius := 0;
      Buf.Canvas.Brush.Color := ActualFaceColor;
      Buf.Canvas.Pen.Color := Buf.Canvas.Brush.Color;
      Buf.Canvas.RoundRect(Inner.Left, Inner.Top, Inner.Right, Inner.Bottom,
                           InnerRadius * 2, InnerRadius * 2);
    end;

    // Слой 3 - значок по центру
    BuildCells;
    if Enabled then
      Cell := FCellNormal
    else
      Cell := FCellOff;
    if not Cell.Empty then
    begin
      Shift := 0;
      if FPressing and FMouseIn then
        Shift := 1;
      PosX := (ClientWidth - Cell.Width) div 2 + Shift;
      PosY := (ClientHeight - Cell.Height) div 2 + Shift;
      if FCellAlpha then
      begin
        Blend.BlendOp := AC_SRC_OVER;
        Blend.BlendFlags := 0;
        Blend.SourceConstantAlpha := 255;
        Blend.AlphaFormat := IconSrcAlpha;
        Windows.AlphaBlend(Buf.Canvas.Handle, PosX, PosY, Cell.Width,
                           Cell.Height, Cell.Canvas.Handle, 0, 0, Cell.Width,
                           Cell.Height, Blend);
      end
      else
        Buf.Canvas.Draw(PosX, PosY, Cell);
    end
    else
    begin
      // Значка нет - пунктирная рамка, иначе кнопку не видно вовсе
      Buf.Canvas.Brush.Style := bsClear;
      Buf.Canvas.Pen.Color := clGray;
      Buf.Canvas.Pen.Style := psDot;
      Buf.Canvas.Rectangle(Area.Left, Area.Top, Area.Right, Area.Bottom);
    end;
    Canvas.Draw(0, 0, Buf);
  finally
    Buf.Free;
  end;
end;

procedure TUiIconButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
                                  X, Y: Integer);
begin
  if (Button = mbLeft) and Enabled then
  begin
    FPressing := True;
    FMouseIn := True;
    Invalidate;
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TUiIconButton.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Inside: Boolean;
begin
  if FPressing then
  begin
    Inside := PtInRect(ClientRect, Point(X, Y));
    if Inside <> FMouseIn then
    begin
      FMouseIn := Inside;
      Invalidate;
    end;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TUiIconButton.MouseUp(Button: TMouseButton; Shift: TShiftState;
                                X, Y: Integer);
begin
  if (Button = mbLeft) and FPressing then
  begin
    FPressing := False;
    Invalidate;
  end;
  inherited MouseUp(Button, Shift, X, Y);   // здесь TControl вызовет Click
end;

procedure TUiIconButton.Click;
begin
  // Обработчик может открыть окно - кнопка к этому времени уже отжата
  FPressing := False;
  Invalidate;
  inherited Click;
end;

procedure TUiIconButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  if not FHot then
  begin
    FHot := True;
    Invalidate;
  end;
end;

procedure TUiIconButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot then
  begin
    FHot := False;
    Invalidate;
  end;
end;

procedure TUiIconButton.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  if not Enabled then
  begin
    FHot := False;
    FPressing := False;
  end;
  Invalidate;
end;

procedure TUiIconButton.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  // Paint закрашивает всю кнопку сам
  Message.Result := 1;
end;

// Тема сменилась: цвет выделения и фон могут быть другими, недоступный
// значок - под другой фон
procedure TUiIconButton.UMUiThemeChanged(var Message: TMessage);
begin
  FCellsReady := False;
  Message.Result := 0;   // UiThemeChanged перерисует через Invalidate
end;

initialization
  // Класс знает GetClass: конструктор форм и снимок строят настоящую кнопку,
  // а не заглушку
  if GetClass(TUiButton.ClassName) = nil then
    RegisterClass(TUiButton);
  if GetClass(TUiIconButton.ClassName) = nil then
    RegisterClass(TUiIconButton);

end.
