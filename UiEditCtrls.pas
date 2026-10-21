unit UiEditCtrls;

// ---------------------------------------------------------------------------
//  Свои поля страницы Standard (этап 1, вторая часть), вид - по теме
//  UiTheme:
//
//    TUiEdit     - поле ввода (TEdit)
//    TUiMemo     - многострочное поле (TMemo)
//    TUiListBox  - список (TListBox)
//    TUiComboBox - список выбора (TComboBox)
//
//  Ввод, выделение, буфер обмена, откат - у элемента Windows внутри: это
//  наследники TCustomEdit, TCustomMemo, TCustomListBox, TCustomComboBox, с
//  тем же набором опубликованных свойств, что у TEdit и т. д. Своё у них:
//
//    - цвета: ThemeColors (по умолчанию True) - фон и цвет шрифта из темы
//      (Edit.BG / Edit.Text, у списка List.BG / List.Text) и меняются вместе
//      с ней. Цвет фона, заданный кодом (Color := ...), выключает
//      ThemeColors: элемент остаётся со своим цветом;
//    - рамка в темах Dark и Custom: поверх рамки Windows - линия цветом
//      Button.Border (в фокусе - Focus), внутри - цветом фона. В теме Light
//      при темах Windows рамка - как у системного элемента;
//    - полосы прокрутки у TUiMemo и TUiListBox - свои (TUiListScroll из
//      UiScroll), ставятся сами при создании окна;
//    - у TUiComboBox в темах Dark и Custom кнопка списка рисуется поверх
//      кнопки Windows цветами Button.*.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls,
  UiTheme;

const
  // Себе: поставить свои полосы прокрутки, когда окно уже создано
  UM_UIATTACHSCROLL = WM_APP + $0A11;

type
  TUiEdit = class(TCustomEdit)
  private
    FThemeColors: Boolean;
    FApplying: Boolean;
    FReady: Boolean;
    procedure SetThemeColors(Value: Boolean);
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
    procedure WMNCPaint(var Message: TMessage); message WM_NCPAINT;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
  protected
    procedure ApplyTheme;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ThemeColors: Boolean read FThemeColors write SetThemeColors
      default True;
    property Anchors;
    property AutoSelect;
    property AutoSize;
    property BiDiMode;
    property BorderStyle;
    property CharCase;
    property Color;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property HideSelection;
    property ImeMode;
    property ImeName;
    property MaxLength;
    property OEMConvert;
    property ParentBiDiMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PasswordChar;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Text;
    property Visible;
    property OnChange;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

  TUiMemo = class(TCustomMemo)
  private
    FThemeColors: Boolean;
    FApplying: Boolean;
    FReady: Boolean;
    procedure SetThemeColors(Value: Boolean);
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure UMUiAttachScroll(var Message: TMessage); message UM_UIATTACHSCROLL;
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
    procedure WMNCPaint(var Message: TMessage); message WM_NCPAINT;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
  protected
    procedure ApplyTheme;
    procedure Loaded; override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ThemeColors: Boolean read FThemeColors write SetThemeColors
      default True;
    property Align;
    property Alignment;
    property Anchors;
    property BiDiMode;
    property BorderStyle;
    property Color;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property HideSelection;
    property ImeMode;
    property ImeName;
    property Lines;
    property MaxLength;
    property OEMConvert;
    property ParentBiDiMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ScrollBars;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property WantReturns;
    property WantTabs;
    property WordWrap;
    property OnChange;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

  TUiListBox = class(TCustomListBox)
  private
    FThemeColors: Boolean;
    FApplying: Boolean;
    FReady: Boolean;
    procedure SetThemeColors(Value: Boolean);
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure UMUiAttachScroll(var Message: TMessage); message UM_UIATTACHSCROLL;
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
    procedure WMNCPaint(var Message: TMessage); message WM_NCPAINT;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
  protected
    procedure ApplyTheme;
    procedure Loaded; override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ThemeColors: Boolean read FThemeColors write SetThemeColors
      default True;
    property Style;
    property Align;
    property Anchors;
    property BiDiMode;
    property BorderStyle;
    property Color;
    property Columns;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ExtendedSelect;
    property Font;
    property ImeMode;
    property ImeName;
    property IntegralHeight;
    property ItemHeight;
    property Items;
    property MultiSelect;
    property ParentBiDiMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ScrollWidth;
    property ShowHint;
    property Sorted;
    property TabOrder;
    property TabStop;
    property TabWidth;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawItem;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMeasureItem;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

  TUiComboBox = class(TCustomComboBox)
  private
    FThemeColors: Boolean;
    FApplying: Boolean;
    FReady: Boolean;
    FHot: Boolean;
    FListOwnerDraw: Boolean;
    procedure SetThemeColors(Value: Boolean);
    procedure SetListOwnerDraw(Value: Boolean);
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CNCommand(var Message: TWMCommand); message CN_COMMAND;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure PaintOver(DC: HDC);
  protected
    procedure ApplyTheme;
    procedure Loaded; override;
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ThemeColors: Boolean read FThemeColors write SetThemeColors
      default True;
    // Строки раскрытого списка рисует OnDrawItem при любом Style, и у
    // списка с полем ввода (csDropDown) тоже: CBS_OWNERDRAWFIXED и
    // CBS_HASSTRINGS к стилю окна. Поле ввода остаётся обычным.
    property ListOwnerDraw: Boolean read FListOwnerDraw write SetListOwnerDraw
      default False;
    property Style;
    property Anchors;
    property BiDiMode;
    property CharCase;
    property Color;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property DropDownCount;
    property Enabled;
    property Font;
    property ImeMode;
    property ImeName;
    property ItemHeight;
    property ItemIndex default -1;
    property MaxLength;
    property ParentBiDiMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Sorted;
    property TabOrder;
    property TabStop;
    property Text;
    property Visible;
    property OnChange;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawItem;
    property OnDropDown;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMeasureItem;
    property OnSelect;
    property OnStartDock;
    property OnStartDrag;
    property Items;
  end;

// Общее для своих элементов с рамкой Windows (здесь и в UiComCtrls):

// Рамка элемента в темах Dark и Custom - поверх рамки Windows (из WM_NCPAINT
// после inherited)
procedure UiPaintNcBorder(C: TWinControl; ABack: TColor);
// Перерисовать рамку (служебную область окна)
procedure UiRedrawFrame(C: TWinControl);
// Поставить свои полосы прокрутки (TUiListScroll), если их ещё нет
procedure UiAttachScroll(C: TWinControl);

implementation

uses
  UiScroll;

// ---------------------------------------------------------------------------
//  Общее
// ---------------------------------------------------------------------------

// Рамка элемента в темах Dark и Custom - поверх рамки, которую только что
// нарисовал Windows: внешняя линия - цветом рамки, остальная ширина рамки -
// цветом фона. Полосы прокрутки внутри рамки не задеваются.
procedure UiPaintNcBorder(C: TWinControl; ABack: TColor);
var
  DC: HDC;
  R: TRect;
  P: TPoint;
  B, I: Integer;
  Br: HBRUSH;
  Line: TColor;
begin
  if UiThemeNativeFor(C) or not C.HandleAllocated then
    Exit;
  GetWindowRect(C.Handle, R);
  P := Point(0, 0);
  Windows.ClientToScreen(C.Handle, P);
  B := P.X - R.Left;          // ширина рамки слева - такая же со всех сторон
  if B <= 0 then
    Exit;
  if B > 3 then
    B := 3;
  OffsetRect(R, -R.Left, -R.Top);
  if C.Focused then
    Line := UiThemeColorFor(C, 'Focus')
  else
    Line := UiThemeColorFor(C, 'Button.Border');
  DC := GetWindowDC(C.Handle);
  try
    Br := CreateSolidBrush(ColorToRGB(Line));
    FrameRect(DC, R, Br);
    DeleteObject(Br);
    Br := CreateSolidBrush(ColorToRGB(ABack));
    for I := 2 to B do
    begin
      InflateRect(R, -1, -1);
      FrameRect(DC, R, Br);
    end;
    DeleteObject(Br);
  finally
    ReleaseDC(C.Handle, DC);
  end;
end;

// Перерисовать рамку (служебную область окна)
procedure UiRedrawFrame(C: TWinControl);
begin
  if C.HandleAllocated then
    RedrawWindow(C.Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or
                 RDW_NOCHILDREN);
end;

// Поставить свои полосы прокрутки, если их ещё нет
procedure UiAttachScroll(C: TWinControl);
begin
  if (C.Parent <> nil) and (UiScrollFind(C) = nil) then
    TUiListScroll.Attach(C);
end;

// ---------------------------------------------------------------------------
//  TUiEdit
// ---------------------------------------------------------------------------

constructor TUiEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FThemeColors := True;
  UiThemeAddClient(Self);
  ApplyTheme;
  FReady := True;
end;

destructor TUiEdit.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiEdit.ApplyTheme;
begin
  if not FThemeColors then
    Exit;
  FApplying := True;
  try
    Color := UiThemeColorFor(Self, 'Edit.BG');
    Font.Color := UiThemeColorFor(Self, 'Edit.Text');
  finally
    FApplying := False;
  end;
end;

procedure TUiEdit.SetThemeColors(Value: Boolean);
begin
  if FThemeColors <> Value then
  begin
    FThemeColors := Value;
    ApplyTheme;
  end;
end;

procedure TUiEdit.Loaded;
begin
  inherited Loaded;
  ApplyTheme;
end;

procedure TUiEdit.UMUiThemeChanged(var Message: TMessage);
begin
  ApplyTheme;
  Invalidate;
  UiRedrawFrame(Self);
  Message.Result := 1;
end;

// Цвет фона поставил код - дальше элемент со своим цветом
procedure TUiEdit.CMColorChanged(var Message: TMessage);
begin
  inherited;
  if FReady and not FApplying and not (csLoading in ComponentState) then
    FThemeColors := False;
end;

procedure TUiEdit.WMNCPaint(var Message: TMessage);
begin
  inherited;
  UiPaintNcBorder(Self, Color);
end;

procedure TUiEdit.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  UiRedrawFrame(Self);
end;

procedure TUiEdit.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  UiRedrawFrame(Self);
end;

// ---------------------------------------------------------------------------
//  TUiMemo
// ---------------------------------------------------------------------------

constructor TUiMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FThemeColors := True;
  UiThemeAddClient(Self);
  ApplyTheme;
  FReady := True;
end;

destructor TUiMemo.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiMemo.ApplyTheme;
begin
  if not FThemeColors then
    Exit;
  FApplying := True;
  try
    Color := UiThemeColorFor(Self, 'Edit.BG');
    Font.Color := UiThemeColorFor(Self, 'Edit.Text');
  finally
    FApplying := False;
  end;
end;

procedure TUiMemo.SetThemeColors(Value: Boolean);
begin
  if FThemeColors <> Value then
  begin
    FThemeColors := Value;
    ApplyTheme;
  end;
end;

procedure TUiMemo.Loaded;
begin
  inherited Loaded;
  ApplyTheme;
end;

// Окно создано - полосы ставятся чуть позже, из очереди: родитель сейчас
// может ещё создавать окна своих детей
procedure TUiMemo.CreateWnd;
begin
  inherited CreateWnd;
  PostMessage(Handle, UM_UIATTACHSCROLL, 0, 0);
end;

procedure TUiMemo.UMUiAttachScroll(var Message: TMessage);
begin
  UiAttachScroll(Self);
end;

procedure TUiMemo.UMUiThemeChanged(var Message: TMessage);
begin
  ApplyTheme;
  Invalidate;
  UiRedrawFrame(Self);
  Message.Result := 1;
end;

procedure TUiMemo.CMColorChanged(var Message: TMessage);
begin
  inherited;
  if FReady and not FApplying and not (csLoading in ComponentState) then
    FThemeColors := False;
end;

procedure TUiMemo.WMNCPaint(var Message: TMessage);
begin
  inherited;
  UiPaintNcBorder(Self, Color);
end;

procedure TUiMemo.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  UiRedrawFrame(Self);
end;

procedure TUiMemo.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  UiRedrawFrame(Self);
end;

// ---------------------------------------------------------------------------
//  TUiListBox
// ---------------------------------------------------------------------------

constructor TUiListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FThemeColors := True;
  UiThemeAddClient(Self);
  ApplyTheme;
  FReady := True;
end;

destructor TUiListBox.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiListBox.ApplyTheme;
begin
  if not FThemeColors then
    Exit;
  FApplying := True;
  try
    Color := UiThemeColorFor(Self, 'List.BG');
    Font.Color := UiThemeColorFor(Self, 'List.Text');
  finally
    FApplying := False;
  end;
end;

procedure TUiListBox.SetThemeColors(Value: Boolean);
begin
  if FThemeColors <> Value then
  begin
    FThemeColors := Value;
    ApplyTheme;
  end;
end;

procedure TUiListBox.Loaded;
begin
  inherited Loaded;
  ApplyTheme;
end;

procedure TUiListBox.CreateWnd;
begin
  inherited CreateWnd;
  PostMessage(Handle, UM_UIATTACHSCROLL, 0, 0);
end;

procedure TUiListBox.UMUiAttachScroll(var Message: TMessage);
begin
  UiAttachScroll(Self);
end;

procedure TUiListBox.UMUiThemeChanged(var Message: TMessage);
begin
  ApplyTheme;
  Invalidate;
  UiRedrawFrame(Self);
  Message.Result := 1;
end;

procedure TUiListBox.CMColorChanged(var Message: TMessage);
begin
  inherited;
  if FReady and not FApplying and not (csLoading in ComponentState) then
    FThemeColors := False;
end;

procedure TUiListBox.WMNCPaint(var Message: TMessage);
begin
  inherited;
  UiPaintNcBorder(Self, Color);
end;

procedure TUiListBox.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  UiRedrawFrame(Self);
end;

procedure TUiListBox.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  UiRedrawFrame(Self);
end;

// ---------------------------------------------------------------------------
//  TUiComboBox
// ---------------------------------------------------------------------------

constructor TUiComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FThemeColors := True;
  UiThemeAddClient(Self);
  ApplyTheme;
  FReady := True;
end;

destructor TUiComboBox.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiComboBox.ApplyTheme;
begin
  if not FThemeColors then
    Exit;
  FApplying := True;
  try
    Color := UiThemeColorFor(Self, 'Edit.BG');
    Font.Color := UiThemeColorFor(Self, 'Edit.Text');
  finally
    FApplying := False;
  end;
end;

procedure TUiComboBox.SetThemeColors(Value: Boolean);
begin
  if FThemeColors <> Value then
  begin
    FThemeColors := Value;
    ApplyTheme;
  end;
end;

procedure TUiComboBox.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if FListOwnerDraw then
    Params.Style := Params.Style or CBS_OWNERDRAWFIXED or CBS_HASSTRINGS;
end;

procedure TUiComboBox.SetListOwnerDraw(Value: Boolean);
begin
  if FListOwnerDraw <> Value then
  begin
    FListOwnerDraw := Value;
    if HandleAllocated then
      RecreateWnd;
  end;
end;

procedure TUiComboBox.Loaded;
begin
  inherited Loaded;
  ApplyTheme;
end;

procedure TUiComboBox.UMUiThemeChanged(var Message: TMessage);
begin
  ApplyTheme;
  Invalidate;
  Message.Result := 1;
end;

procedure TUiComboBox.CMColorChanged(var Message: TMessage);
begin
  inherited;
  if FReady and not FApplying and not (csLoading in ComponentState) then
    FThemeColors := False;
end;

procedure TUiComboBox.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  if not FHot then
  begin
    FHot := True;
    Invalidate;
  end;
end;

procedure TUiComboBox.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot then
  begin
    FHot := False;
    Invalidate;
  end;
end;

// Список раскрылся или закрылся - кнопка меняет вид
procedure TUiComboBox.CNCommand(var Message: TWMCommand);
begin
  inherited;
  if (Message.NotifyCode = CBN_DROPDOWN) or
     (Message.NotifyCode = CBN_CLOSEUP) then
    Invalidate;
end;

// Windows рисует список выбора целиком; в темах Dark и Custom поверх -
// рамка и кнопка списка
procedure TUiComboBox.WMPaint(var Message: TWMPaint);
var
  DC: HDC;
begin
  inherited;
  if UiThemeNativeFor(Self) or not HandleAllocated then
    Exit;
  DC := Message.DC;
  if DC <> 0 then
    PaintOver(DC)
  else
  begin
    DC := GetDC(Handle);
    try
      PaintOver(DC);
    finally
      ReleaseDC(Handle, DC);
    end;
  end;
end;

procedure TUiComboBox.PaintOver(DC: HDC);
var
  R, B: TRect;
  W, Cx, Cy, S: Integer;
  Br: HBRUSH;
  Pen, OldPen: HPEN;
  OldBr: HBRUSH;
  Pts: array[0..2] of TPoint;
  Down: Boolean;
  Face, Mark, Line, Back, Fore: TColor;
  T: TRect;
  Cv: TCanvas;
  Txt: string;
  EditWnd: HWND;
  EditRect: TRect;
  SavedDC: Integer;
begin
  R := ClientRect;
  // Цвета поля: пока ThemeColors - прямо из темы
  if FThemeColors then
  begin
    Back := UiThemeColorFor(Self, 'Edit.BG');
    Fore := UiThemeColorFor(Self, 'Edit.Text');
  end
  else
  begin
    Back := Color;
    Fore := Font.Color;
  end;
  W := GetSystemMetrics(SM_CXVSCROLL);
  Down := SendMessage(Handle, CB_GETDROPPEDSTATE, 0, 0) <> 0;
  if Focused or Down then
    Line := UiThemeColorFor(Self, 'Focus')
  else
    Line := UiThemeColorFor(Self, 'Button.Border');
  if Down then
    Face := UiThemeColorFor(Self, 'Button.DownBG')
  else if FHot and Enabled then
    Face := UiThemeColorFor(Self, 'Button.HotBG')
  else
    Face := UiThemeColorFor(Self, 'Button.BG');
  if Enabled then
    Mark := UiThemeColorFor(Self, 'Button.Text')
  else
    Mark := UiThemeColorFor(Self, 'OffText');

  // Список с полем ввода (csDropDown): между рамкой и полем Windows
  // оставляет светлую полосу своей рамки - закрашиваем всё вокруг поля
  // цветом фона. Само поле ввода - отдельное окно, его не трогаем.
  if Style <> csDropDownList then
  begin
    SavedDC := SaveDC(DC);
    try
      EditWnd := FindWindowEx(Handle, 0, 'Edit', nil);
      if EditWnd <> 0 then
      begin
        GetWindowRect(EditWnd, EditRect);
        MapWindowPoints(0, Handle, EditRect, 2);
        ExcludeClipRect(DC, EditRect.Left, EditRect.Top, EditRect.Right,
                        EditRect.Bottom);
      end;
      Br := CreateSolidBrush(ColorToRGB(Back));
      FillRect(DC, R, Br);
      DeleteObject(Br);
    finally
      RestoreDC(DC, SavedDC);
    end;
  end;

  // Рамка: линия и полоса в точку цветом фона внутри
  Br := CreateSolidBrush(ColorToRGB(Line));
  FrameRect(DC, R, Br);
  DeleteObject(Br);
  InflateRect(R, -1, -1);
  Br := CreateSolidBrush(ColorToRGB(Back));
  FrameRect(DC, R, Br);
  DeleteObject(Br);

  // Кнопка списка - справа во всю высоту внутри рамки
  B := Rect(R.Right - W, R.Top, R.Right, R.Bottom);

  // Список без поля ввода (csDropDownList): выбранный пункт - тоже сами.
  // Windows рисует его поле по-своему и не всегда цветом Color. В фокусе -
  // фон цветом Focus, как выделение у системного.
  if Style = csDropDownList then
  begin
    T := Rect(R.Left + 1, R.Top + 1, B.Left, R.Bottom - 1);
    Cv := TCanvas.Create;
    try
      Cv.Handle := DC;
      if Focused and not Down then
        Cv.Brush.Color := UiThemeColorFor(Self, 'Focus')
      else
        Cv.Brush.Color := Back;
      Cv.FillRect(T);
      Cv.Font := Font;
      if Enabled then
        Cv.Font.Color := Fore
      else
        Cv.Font.Color := UiThemeColorFor(Self, 'OffText');
      Txt := Text;
      InflateRect(T, -2, 0);
      Cv.Brush.Style := bsClear;
      DrawText(Cv.Handle, PChar(Txt), Length(Txt), T,
               DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS or
               DT_NOPREFIX);
    finally
      Cv.Handle := 0;
      Cv.Free;
    end;
  end;
  Br := CreateSolidBrush(ColorToRGB(Face));
  FillRect(DC, B, Br);
  DeleteObject(Br);

  // Стрелка вниз
  Cx := (B.Left + B.Right) div 2;
  Cy := (B.Top + B.Bottom) div 2;
  S := W div 4;
  if S < 2 then
    S := 2;
  Pts[0] := Point(Cx - S, Cy - S div 2);
  Pts[1] := Point(Cx + S, Cy - S div 2);
  Pts[2] := Point(Cx, Cy + S div 2 + 1);
  Br := CreateSolidBrush(ColorToRGB(Mark));
  Pen := CreatePen(PS_SOLID, 1, ColorToRGB(Mark));
  OldBr := SelectObject(DC, Br);
  OldPen := SelectObject(DC, Pen);
  Polygon(DC, Pts, 3);
  SelectObject(DC, OldPen);
  SelectObject(DC, OldBr);
  DeleteObject(Pen);
  DeleteObject(Br);
end;

initialization
  // Классы знает GetClass: конструктор форм и снимок строят настоящие
  // элементы, а не заглушки
  if GetClass(TUiEdit.ClassName) = nil then
    RegisterClass(TUiEdit);
  if GetClass(TUiMemo.ClassName) = nil then
    RegisterClass(TUiMemo);
  if GetClass(TUiListBox.ClassName) = nil then
    RegisterClass(TUiListBox);
  if GetClass(TUiComboBox.ClassName) = nil then
    RegisterClass(TUiComboBox);
end.
