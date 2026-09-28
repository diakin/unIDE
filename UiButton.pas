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

initialization
  // Класс знает GetClass: конструктор форм и снимок строят настоящую кнопку,
  // а не заглушку
  if GetClass(TUiButton.ClassName) = nil then
    RegisterClass(TUiButton);

end.
