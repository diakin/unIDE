unit UiStdCtrls;

// ---------------------------------------------------------------------------
//  Свои элементы страницы Standard (этап 1), вид - по теме UiTheme:
//
//    TUiCheckBox    - флажок (TCheckBox)
//    TUiRadioButton - переключатель (TRadioButton)
//    TUiRadioGroup  - группа переключателей (TRadioGroup) на TUiGroupBox
//    TUiPanel       - панель (TPanel)
//    TUiLabel       - надпись (TLabel)
//
//  В теме Light при включённых темах Windows флажок, переключатель, панель
//  и надпись выглядят как системные: флажок и переключатель рисуют
//  квадратик и кружок темой Windows, панель - как TPanel. В темах Dark и
//  Custom - всё сами, цветами ролей темы.
//
//  Флажок и переключатель - TCustomControl: Windows в их отрисовке не
//  участвует. Поведение - как у TCheckBox / TRadioButton: щелчок, пробел,
//  Alt+буква из Caption; OnClick - при каждой смене Checked (у
//  переключателя - когда он стал выбранным), в том числе из кода.
//  Переключатель снимает выбор с соседних переключателей того же родителя.
//
//  Панель и надпись - наследники TCustomPanel / TCustomLabel. ThemeColors
//  (по умолчанию True): цвет фона панели и цвет шрифта берутся из темы
//  (Window.BG, Window.Text) и меняются вместе с ней. False - свои цвета.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  ExtCtrls, UiTheme, UiGroupBox;

type
  // Общее у флажка и переключателя
  TUiCheckControl = class(TCustomControl)
  private
    FState: TCheckBoxState;
    FAllowGrayed: Boolean;
    FAlignment: TLeftRight;
    FTextColor: TColor;
    FHot, FPressing, FMouseIn, FKeyDown: Boolean;
    FClicksOff: Integer;
    function GetChecked: Boolean;
    procedure SetChecked(Value: Boolean);
    procedure SetAlignment(Value: TLeftRight);
    procedure SetTextColor(Value: TColor);
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    function  IsRadio: Boolean; virtual;
    procedure SetState(Value: TCheckBoxState); virtual;
    // Действие пользователя: щелчок, пробел, Alt+буква
    procedure Toggle; virtual;
    // Состояние сменилось (до OnClick)
    procedure StateChanged; virtual;
    procedure Paint; override;
    procedure PaintBoxNative(const RectVal: TRect);
    procedure PaintBoxOwn(const BoxRect: TRect);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        PosX, PosY: Integer); override;
    procedure MouseMove(Shift: TShiftState; PosX, PosY: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
                      PosX, PosY: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    property State: TCheckBoxState read FState write SetState
      default cbUnchecked;
    property AllowGrayed: Boolean read FAllowGrayed write FAllowGrayed
      default False;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    // Квадратик слева от подписи (taRightJustify, как у TCheckBox) или справа
    property Alignment: TLeftRight read FAlignment write SetAlignment
      default taRightJustify;
    property Checked: Boolean read GetChecked write SetChecked default False;
    // Цвет подписи; clNone - по теме
    property TextColor: TColor read FTextColor write SetTextColor
      default clNone;
    property Align;
    property Anchors;
    property Caption;
    property Color;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor;
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

  TUiCheckBox = class(TUiCheckControl)
  published
    property AllowGrayed;
    property State;
  end;

  TUiRadioButton = class(TUiCheckControl)
  protected
    function  IsRadio: Boolean; override;
    procedure Toggle; override;
    procedure StateChanged; override;
  end;

  // Переключатель внутри TUiRadioGroup - его строит сама группа по Items
  TUiGroupButton = class(TUiRadioButton);

  TUiRadioGroup = class(TUiGroupBox)
  private
    FItems: TStrings;
    FButtons: TList;
    FItemIndex: Integer;
    FColumns: Integer;
    FUpdating: Boolean;
    procedure SetItems(Value: TStrings);
    procedure SetItemIndex(Value: Integer);
    procedure SetColumns(Value: Integer);
    procedure ItemsChange(Sender: TObject);
    procedure ButtonClick(Sender: TObject);
    procedure UpdateButtons;
    procedure ArrangeButtons;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    procedure Loaded; override;
    procedure Resize; override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Columns: Integer read FColumns write SetColumns default 1;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;
    property Items: TStrings read FItems write SetItems;
  end;

  TUiPanel = class(TCustomPanel)
  private
    FThemeColors: Boolean;
    procedure SetThemeColors(Value: Boolean);
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
  protected
    procedure ApplyTheme;
    procedure Loaded; override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ThemeColors: Boolean read FThemeColors write SetThemeColors
      default True;
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property BiDiMode;
    property BorderWidth;
    property BorderStyle;
    property Caption;
    property Color;
    property Constraints;
    property Ctl3D;
    property UseDockManager default True;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property FullRepaint;
    property Font;
    property Locked;
    property ParentBiDiMode;
    property ParentBackground;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDockDrop;
    property OnDockOver;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
  end;

  TUiLabel = class(TCustomLabel)
  private
    FThemeColors: Boolean;
    procedure SetThemeColors(Value: Boolean);
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
  protected
    procedure ApplyTheme;
    procedure Loaded; override;
    procedure DoDrawText(var Rect: TRect; Flags: Longint); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ThemeColors: Boolean read FThemeColors write SetThemeColors
      default True;
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property Caption;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property FocusControl;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowAccelChar;
    property ShowHint;
    property Transparent;
    property Layout;
    property Visible;
    property WordWrap;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

uses
  Themes;

const
  WM_QUERYUISTATE_ = $0129;
  UISF_HIDEFOCUS_ = $0001;
  UISF_HIDEACCEL_ = $0002;
  DT_HIDEPREFIX_ = $00100000;
  BoxSize = 13;       // квадратик флажка, кружок переключателя
  BoxGap = 4;         // от квадратика до подписи

function UiState(WinCtrl: TWinControl): Integer;
begin
  if WinCtrl.HandleAllocated then
    Result := SendMessage(WinCtrl.Handle, WM_QUERYUISTATE_, 0, 0)
  else
    Result := 0;
end;

// ---------------------------------------------------------------------------
//  TUiCheckControl
// ---------------------------------------------------------------------------

constructor TUiCheckControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csCaptureMouse, csSetCaption, csOpaque, csReplicatable];
  Width := 97;
  Height := 17;
  TabStop := True;
  FAlignment := taRightJustify;
  FTextColor := clNone;
  UiThemeAddClient(Self);
end;

destructor TUiCheckControl.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

function TUiCheckControl.IsRadio: Boolean;
begin
  Result := False;
end;

function TUiCheckControl.GetChecked: Boolean;
begin
  Result := FState = cbChecked;
end;

procedure TUiCheckControl.SetChecked(Value: Boolean);
begin
  if Value then
    SetState(cbChecked)
  else
    SetState(cbUnchecked);
end;

procedure TUiCheckControl.SetState(Value: TCheckBoxState);
begin
  if FState = Value then
    Exit;
  FState := Value;
  Invalidate;
  StateChanged;
  // Как у TCheckBox: OnClick при каждой смене, в том числе из кода; у
  // переключателя - только когда он стал выбранным
  if (FClicksOff = 0) and (not IsRadio or (FState = cbChecked)) and
     not (csLoading in ComponentState) then
    Click;
end;

procedure TUiCheckControl.StateChanged;
begin
end;

procedure TUiCheckControl.Toggle;
begin
  case FState of
    cbUnchecked:
      if FAllowGrayed then
        SetState(cbGrayed)
      else
        SetState(cbChecked);
    cbGrayed: SetState(cbChecked);
    cbChecked: SetState(cbUnchecked);
  end;
end;

procedure TUiCheckControl.SetAlignment(Value: TLeftRight);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Invalidate;
  end;
end;

procedure TUiCheckControl.SetTextColor(Value: TColor);
begin
  if FTextColor <> Value then
  begin
    FTextColor := Value;
    Invalidate;
  end;
end;

// Квадратик темы Windows: состояние - отмечен / нет / серый, мышь, нажат
procedure TUiCheckControl.PaintBoxNative(const RectVal: TRect);
var
  Base: TThemedButton;
  Idx3: Integer;
  Details: TThemedElementDetails;
begin
  if IsRadio then
  begin
    if FState = cbChecked then
      Base := tbRadioButtonCheckedNormal
    else
      Base := tbRadioButtonUncheckedNormal;
  end
  else
    case FState of
      cbChecked: Base := tbCheckBoxCheckedNormal;
      cbGrayed: Base := tbCheckBoxMixedNormal;
    else
      Base := tbCheckBoxUncheckedNormal;
    end;
  // За каждым ...Normal в перечне темы идут Hot, Pressed, Disabled
  if not Enabled then
    Idx3 := 3
  else if (FPressing and FMouseIn) or FKeyDown then
    Idx3 := 2
  else if FHot then
    Idx3 := 1
  else
    Idx3 := 0;
  Details := ThemeServices.GetElementDetails(TThemedButton(Ord(Base) + Idx3));
  ThemeServices.DrawElement(Canvas.Handle, Details, RectVal);
end;

// Квадратик цветами темы: рамка, фон поля, галочка или точка
procedure TUiCheckControl.PaintBoxOwn(const BoxRect: TRect);
var
  Mark: TColor;
  Pts: array[0..2] of TPoint;
  InnerRect: TRect;
begin
  with Canvas do
  begin
    Pen.Width := 1;
    Pen.Style := psSolid;
    if FHot and Enabled then
      Pen.Color := UiThemeColorFor(Self, 'Focus')
    else
      Pen.Color := UiThemeColorFor(Self, 'Button.Border');
    if (FPressing and FMouseIn) or FKeyDown then
      Brush.Color := UiThemeColorFor(Self, 'Button.DownBG')
    else
      Brush.Color := UiThemeColorFor(Self, 'Edit.BG');
    if Enabled then
      Mark := UiThemeColorFor(Self, 'Edit.Text')
    else
      Mark := UiThemeColorFor(Self, 'OffText');

    if IsRadio then
    begin
      Ellipse(BoxRect.Left, BoxRect.Top, BoxRect.Right, BoxRect.Bottom);
      if FState = cbChecked then
      begin
        Brush.Color := Mark;
        Pen.Color := Mark;
        InnerRect := BoxRect;
        InflateRect(InnerRect, -4, -4);
        Ellipse(InnerRect.Left, InnerRect.Top, InnerRect.Right, InnerRect.Bottom);
      end;
    end
    else
    begin
      Rectangle(BoxRect.Left, BoxRect.Top, BoxRect.Right, BoxRect.Bottom);
      if FState = cbChecked then
      begin
        // Галочка: две линии толщиной в 2 точки
        Pen.Color := Mark;
        Pen.Width := 2;
        Pts[0] := Point(BoxRect.Left + 3, BoxRect.Top + 6);
        Pts[1] := Point(BoxRect.Left + 5, BoxRect.Top + 9);
        Pts[2] := Point(BoxRect.Left + 10, BoxRect.Top + 3);
        Polyline(Pts);
        Pen.Width := 1;
      end
      else if FState = cbGrayed then
      begin
        InnerRect := BoxRect;
        InflateRect(InnerRect, -3, -3);
        Brush.Color := UiThemeColorFor(Self, 'OffText');
        FillRect(InnerRect);
      end;
    end;
  end;
end;

procedure TUiCheckControl.Paint;
var
  Box, TR, FR: TRect;
  PosY: Integer;
  Str: string;
  Fl: Cardinal;
  Native: Boolean;
  St: Integer;
begin
  Native := UiThemeNativeFor(Self);
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  // Квадратик - по середине высоты, у края со стороны Alignment
  PosY := (ClientHeight - BoxSize) div 2;
  if FAlignment = taRightJustify then
  begin
    Box := Rect(0, PosY, BoxSize, PosY + BoxSize);
    TR := Rect(BoxSize + BoxGap, 0, ClientWidth, ClientHeight);
  end
  else
  begin
    Box := Rect(ClientWidth - BoxSize, PosY, ClientWidth, PosY + BoxSize);
    TR := Rect(0, 0, ClientWidth - BoxSize - BoxGap, ClientHeight);
  end;
  if Native then
    PaintBoxNative(Box)
  else
    PaintBoxOwn(Box);

  // Подпись
  Str := Caption;
  Canvas.Font := Font;
  if not Enabled then
  begin
    if Native then
      Canvas.Font.Color := clGrayText
    else
      Canvas.Font.Color := UiThemeColorFor(Self, 'OffText');
  end
  else if FTextColor <> clNone then
    Canvas.Font.Color := FTextColor
  else if Native then
    Canvas.Font.Color := clWindowText
  else
    Canvas.Font.Color := UiThemeColorFor(Self, 'Window.Text');
  St := UiState(Self);
  Fl := DT_SINGLELINE or DT_VCENTER or DT_LEFT;
  if (St and UISF_HIDEACCEL_) <> 0 then
    Fl := Fl or DT_HIDEPREFIX_;
  Canvas.Brush.Style := bsClear;
  DrawText(Canvas.Handle, PChar(Str), Length(Str), TR, Fl);
  Canvas.Brush.Style := bsSolid;

  // Рамка фокуса - вокруг подписи
  if Focused and (Str <> '') and ((St and UISF_HIDEFOCUS_) = 0) then
  begin
    FR := TR;
    DrawText(Canvas.Handle, PChar(Str), Length(Str), FR, Fl or DT_CALCRECT);
    FR.Top := TR.Top + (TR.Bottom - TR.Top - (FR.Bottom - FR.Top)) div 2;
    FR.Bottom := FR.Top + Canvas.TextHeight('0');
    InflateRect(FR, 1, 1);
    if FR.Left < 0 then
      FR.Left := 0;
    if FR.Right > ClientWidth then
      FR.Right := ClientWidth;
    Canvas.Brush.Color := Color;
    Canvas.Font.Color := clWindowText;
    Canvas.DrawFocusRect(FR);
  end;
end;

procedure TUiCheckControl.MouseDown(Button: TMouseButton; Shift: TShiftState;
                                    PosX, PosY: Integer);
begin
  if (Button = mbLeft) and Enabled then
  begin
    if CanFocus and not Focused then
      SetFocus;
    FPressing := True;
    FMouseIn := True;
    Invalidate;
  end;
  inherited MouseDown(Button, Shift, PosX, PosY);
end;

procedure TUiCheckControl.MouseMove(Shift: TShiftState; PosX, PosY: Integer);
var
  InNow: Boolean;
begin
  if FPressing then
  begin
    InNow := PtInRect(ClientRect, Point(PosX, PosY));
    if InNow <> FMouseIn then
    begin
      FMouseIn := InNow;
      Invalidate;
    end;
  end;
  inherited MouseMove(Shift, PosX, PosY);
end;

procedure TUiCheckControl.MouseUp(Button: TMouseButton; Shift: TShiftState;
                                  PosX, PosY: Integer);
var
  Was: Boolean;
begin
  Was := FPressing and (Button = mbLeft);
  if Was then
  begin
    FPressing := False;
    Invalidate;
  end;
  inherited MouseUp(Button, Shift, PosX, PosY);
  // Отпустили над элементом - это щелчок
  if Was and PtInRect(ClientRect, Point(PosX, PosY)) then
    Toggle;
end;

procedure TUiCheckControl.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) and (Shift = []) and not FKeyDown then
  begin
    FKeyDown := True;
    Invalidate;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TUiCheckControl.KeyUp(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_SPACE) and FKeyDown then
  begin
    FKeyDown := False;
    Invalidate;
    Toggle;
  end;
  inherited KeyUp(Key, Shift);
end;

procedure TUiCheckControl.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  if not FHot then
  begin
    FHot := True;
    Invalidate;
  end;
end;

procedure TUiCheckControl.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot then
  begin
    FHot := False;
    Invalidate;
  end;
end;

procedure TUiCheckControl.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  if not Enabled then
  begin
    FPressing := False;
    FKeyDown := False;
  end;
  Invalidate;
end;

procedure TUiCheckControl.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TUiCheckControl.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TUiCheckControl.CMDialogChar(var Message: TCMDialogChar);
begin
  with Message do
    if IsAccel(CharCode, Caption) and CanFocus then
    begin
      SetFocus;
      if Focused then
        Toggle;
      Result := 1;
    end
    else
      inherited;
end;

procedure TUiCheckControl.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  Invalidate;
end;

procedure TUiCheckControl.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  FKeyDown := False;
  Invalidate;
end;

procedure TUiCheckControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

// ---------------------------------------------------------------------------
//  TUiRadioButton
// ---------------------------------------------------------------------------

function TUiRadioButton.IsRadio: Boolean;
begin
  Result := True;
end;

// Выбранный переключатель щелчком не снимается
procedure TUiRadioButton.Toggle;
begin
  SetState(cbChecked);
end;

// Стал выбранным - соседние переключатели того же родителя снимаются
procedure TUiRadioButton.StateChanged;
var
  I: Integer;
  Ctrl: TControl;
begin
  if (FState <> cbChecked) or (Parent = nil) then
    Exit;
  for I := 0 to Parent.ControlCount - 1 do
  begin
    Ctrl := Parent.Controls[I];
    if (Ctrl <> Self) and (Ctrl is TUiRadioButton) then
      TUiRadioButton(Ctrl).SetState(cbUnchecked);
  end;
end;

// ---------------------------------------------------------------------------
//  TUiRadioGroup
// ---------------------------------------------------------------------------

constructor TUiRadioGroup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csSetCaption, csDoubleClicks];
  FButtons := TList.Create;
  FItems := TStringList.Create;
  TStringList(FItems).OnChange := ItemsChange;
  FItemIndex := -1;
  FColumns := 1;
end;

destructor TUiRadioGroup.Destroy;
begin
  // Переключатели принадлежат группе и уходят вместе с ней
  FButtons.Free;
  FButtons := nil;
  FItems.Free;
  inherited Destroy;
end;

procedure TUiRadioGroup.SetItems(Value: TStrings);
begin
  FItems.Assign(Value);
end;

procedure TUiRadioGroup.SetColumns(Value: Integer);
begin
  if Value < 1 then
    Value := 1;
  if Value > 16 then
    Value := 16;
  if FColumns <> Value then
  begin
    FColumns := Value;
    ArrangeButtons;
    Invalidate;
  end;
end;

procedure TUiRadioGroup.SetItemIndex(Value: Integer);
var
  I: Integer;
begin
  if csLoading in ComponentState then
  begin
    FItemIndex := Value;
    Exit;
  end;
  if Value < -1 then
    Value := -1;
  if Value >= FButtons.Count then
    Value := FButtons.Count - 1;
  if FItemIndex = Value then
    Exit;
  FItemIndex := Value;
  FUpdating := True;
  try
    for I := 0 to FButtons.Count - 1 do
      TUiGroupButton(FButtons[I]).Checked := I = Value;
  finally
    FUpdating := False;
  end;
end;

procedure TUiRadioGroup.ItemsChange(Sender: TObject);
begin
  if csLoading in ComponentState then
    Exit;
  if FItemIndex >= FItems.Count then
    FItemIndex := FItems.Count - 1;
  UpdateButtons;
end;

// Переключатели - по одному на строку Items
procedure TUiRadioGroup.UpdateButtons;
var
  I: Integer;
  UiGroupButton: TUiGroupButton;
begin
  while FButtons.Count < FItems.Count do
  begin
    UiGroupButton := TUiGroupButton.Create(Self);
    UiGroupButton.Parent := Self;
    UiGroupButton.OnClick := ButtonClick;
    FButtons.Add(UiGroupButton);
  end;
  while FButtons.Count > FItems.Count do
  begin
    TObject(FButtons[FButtons.Count - 1]).Free;
    FButtons.Delete(FButtons.Count - 1);
  end;
  FUpdating := True;
  try
    for I := 0 to FButtons.Count - 1 do
    begin
      UiGroupButton := TUiGroupButton(FButtons[I]);
      UiGroupButton.Caption := FItems[I];
      UiGroupButton.Enabled := Enabled;
      UiGroupButton.Checked := I = FItemIndex;
    end;
  finally
    FUpdating := False;
  end;
  ArrangeButtons;
  Invalidate;
end;

// Раскладка - как у TRadioGroup: столбцы по ширине, строки поровну по
// высоте под подписью
procedure TUiRadioGroup.ArrangeButtons;
var
  PerCol, WidthPx, HeightPx, I, TopMargin, TextH: Integer;
begin
  if (FButtons = nil) or (FButtons.Count = 0) or not HandleAllocated then
    Exit;
  Canvas.Font := Font;
  TextH := Canvas.TextHeight('0');
  PerCol := (FButtons.Count + FColumns - 1) div FColumns;
  WidthPx := (Width - 10) div FColumns;
  I := Height - TextH - 5;
  HeightPx := I div PerCol;
  TopMargin := TextH + 1 + (I mod PerCol) div 2;
  for I := 0 to FButtons.Count - 1 do
    TUiGroupButton(FButtons[I]).SetBounds(
      (I div PerCol) * WidthPx + 8, (I mod PerCol) * HeightPx + TopMargin, WidthPx, HeightPx);
end;

procedure TUiRadioGroup.ButtonClick(Sender: TObject);
begin
  if FUpdating then
    Exit;
  FItemIndex := FButtons.IndexOf(Sender);
  Click;
end;

procedure TUiRadioGroup.Loaded;
begin
  inherited Loaded;
  UpdateButtons;
end;

procedure TUiRadioGroup.Resize;
begin
  inherited Resize;
  ArrangeButtons;
end;

procedure TUiRadioGroup.CreateWnd;
begin
  inherited CreateWnd;
  ArrangeButtons;
end;

procedure TUiRadioGroup.CMFontChanged(var Message: TMessage);
begin
  inherited;
  ArrangeButtons;
end;

procedure TUiRadioGroup.CMEnabledChanged(var Message: TMessage);
var
  I: Integer;
begin
  inherited;
  if FButtons <> nil then
    for I := 0 to FButtons.Count - 1 do
      TUiGroupButton(FButtons[I]).Enabled := Enabled;
end;

// ---------------------------------------------------------------------------
//  TUiPanel
// ---------------------------------------------------------------------------

constructor TUiPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FThemeColors := True;
  // Фон - свой цвет (из темы), а не фон вкладки из темы Windows
  ParentBackground := False;
  UiThemeAddClient(Self);
  ApplyTheme;
end;

destructor TUiPanel.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiPanel.ApplyTheme;
begin
  if not FThemeColors then
    Exit;
  Color := UiThemeColorFor(Self, 'Window.BG');
  Font.Color := UiThemeColorFor(Self, 'Window.Text');
end;

procedure TUiPanel.SetThemeColors(Value: Boolean);
begin
  if FThemeColors <> Value then
  begin
    FThemeColors := Value;
    ApplyTheme;
  end;
end;

// Цвета из .dfm не перебивают тему, пока ThemeColors
procedure TUiPanel.Loaded;
begin
  inherited Loaded;
  ApplyTheme;
end;

procedure TUiPanel.UMUiThemeChanged(var Message: TMessage);
begin
  ApplyTheme;
  Invalidate;
  Message.Result := 1;
end;

// Тема Light при темах Windows - как TPanel. Иначе фон, рамки Bevel* -
// линией цветом Group.Border, подпись по середине.
procedure TUiPanel.Paint;
var
  RectVal: TRect;
  Str: string;
  Fl: Cardinal;
begin
  if UiThemeNativeFor(Self) then
  begin
    inherited Paint;
    Exit;
  end;
  RectVal := GetClientRect;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(RectVal);
  Canvas.Brush.Color := UiThemeColorFor(Self, 'Group.Border');
  if BevelOuter <> bvNone then
  begin
    Canvas.FrameRect(RectVal);
    InflateRect(RectVal, -BevelWidth, -BevelWidth);
  end;
  InflateRect(RectVal, -BorderWidth, -BorderWidth);
  if BevelInner <> bvNone then
  begin
    Canvas.FrameRect(RectVal);
    InflateRect(RectVal, -BevelWidth, -BevelWidth);
  end;
  Str := Caption;
  if Str <> '' then
  begin
    Canvas.Font := Font;
    Canvas.Brush.Style := bsClear;
    Fl := DT_SINGLELINE or DT_VCENTER;
    case Alignment of
      taLeftJustify: Fl := Fl or DT_LEFT;
      taRightJustify: Fl := Fl or DT_RIGHT;
    else
      Fl := Fl or DT_CENTER;
    end;
    DrawText(Canvas.Handle, PChar(Str), Length(Str), RectVal, DrawTextBiDiModeFlags(Fl));
    Canvas.Brush.Style := bsSolid;
  end;
end;

// ---------------------------------------------------------------------------
//  TUiLabel
// ---------------------------------------------------------------------------

constructor TUiLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FThemeColors := True;
  UiThemeAddClient(Self);
  ApplyTheme;
end;

destructor TUiLabel.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiLabel.ApplyTheme;
begin
  if not FThemeColors then
    Exit;
  Font.Color := UiThemeColorFor(Self, 'Window.Text');
end;

procedure TUiLabel.SetThemeColors(Value: Boolean);
begin
  if FThemeColors <> Value then
  begin
    FThemeColors := Value;
    ApplyTheme;
  end;
end;

procedure TUiLabel.Loaded;
begin
  inherited Loaded;
  ApplyTheme;
end;

procedure TUiLabel.UMUiThemeChanged(var Message: TMessage);
begin
  ApplyTheme;
  Invalidate;
  Message.Result := 1;
end;

// Выключенная надпись: в темах Dark и Custom - цветом OffText, а не
// выпуклым серым, как у TLabel (на тёмном фоне он светлый и яркий)
procedure TUiLabel.DoDrawText(var Rect: TRect; Flags: Longint);
var
  Str: string;
begin
  if Enabled or UiThemeNativeFor(Self) then
  begin
    inherited DoDrawText(Rect, Flags);
    Exit;
  end;
  Str := GetLabelText;
  if (Flags and DT_CALCRECT <> 0) and ((Str = '') or ShowAccelChar and
     (Str[1] = '&') and (Length(Str) = 1)) then
    Str := Str + ' ';
  if not ShowAccelChar then
    Flags := Flags or DT_NOPREFIX;
  Flags := DrawTextBiDiModeFlags(Flags);
  Canvas.Font := Font;
  Canvas.Font.Color := UiThemeColorFor(Self, 'OffText');
  DrawText(Canvas.Handle, PChar(Str), Length(Str), Rect, Flags);
end;

initialization
  // Классы знает GetClass: конструктор форм и снимок строят настоящие
  // элементы, а не заглушки
  if GetClass(TUiCheckBox.ClassName) = nil then
    RegisterClass(TUiCheckBox);
  if GetClass(TUiRadioButton.ClassName) = nil then
    RegisterClass(TUiRadioButton);
  if GetClass(TUiGroupButton.ClassName) = nil then
    RegisterClass(TUiGroupButton);
  if GetClass(TUiRadioGroup.ClassName) = nil then
    RegisterClass(TUiRadioGroup);
  if GetClass(TUiPanel.ClassName) = nil then
    RegisterClass(TUiPanel);
  if GetClass(TUiLabel.ClassName) = nil then
    RegisterClass(TUiLabel);
end.
