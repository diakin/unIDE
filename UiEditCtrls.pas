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
  {$IFDEF FPC} LCLType, LMessages, {$ENDIF}
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
    {$IFDEF FPC}
    procedure CreateWnd; override;
    {$ENDIF}
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
    {$IFNDEF FPC}property Ctl3D;{$ENDIF}
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property HideSelection;
    {$IFNDEF FPC}property ImeMode;{$ENDIF}
    {$IFNDEF FPC}property ImeName;{$ENDIF}
    property MaxLength;
    {$IFNDEF FPC}property OEMConvert;{$ENDIF}
    property ParentBiDiMode;
    property ParentColor;
    {$IFNDEF FPC}property ParentCtl3D;{$ENDIF}
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
    {$IFNDEF FPC}property Ctl3D;{$ENDIF}
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property HideSelection;
    {$IFNDEF FPC}property ImeMode;{$ENDIF}
    {$IFNDEF FPC}property ImeName;{$ENDIF}
    property Lines;
    property MaxLength;
    {$IFNDEF FPC}property OEMConvert;{$ENDIF}
    property ParentBiDiMode;
    property ParentColor;
    {$IFNDEF FPC}property ParentCtl3D;{$ENDIF}
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
    {$IFNDEF FPC}property Ctl3D;{$ENDIF}
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ExtendedSelect;
    property Font;
    {$IFNDEF FPC}property ImeMode;{$ENDIF}
    {$IFNDEF FPC}property ImeName;{$ENDIF}
    property IntegralHeight;
    property ItemHeight;
    property Items;
    property MultiSelect;
    property ParentBiDiMode;
    property ParentColor;
    {$IFNDEF FPC}property ParentCtl3D;{$ENDIF}
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ScrollWidth;
    property ShowHint;
    property Sorted;
    property TabOrder;
    property TabStop;
    {$IFNDEF FPC}property TabWidth;{$ENDIF}
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
    {$IFDEF FPC}
    procedure LMDrawItem(var Message: TLMDrawItems); message LM_DRAWITEM;
    {$ENDIF}
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
    {$IFNDEF FPC}property Ctl3D;{$ENDIF}
    property DragCursor;
    property DragKind;
    property DragMode;
    property DropDownCount;
    property Enabled;
    property Font;
    {$IFNDEF FPC}property ImeMode;{$ENDIF}
    {$IFNDEF FPC}property ImeName;{$ENDIF}
    property ItemHeight;
    property ItemIndex default -1;
    property MaxLength;
    property ParentBiDiMode;
    property ParentColor;
    {$IFNDEF FPC}property ParentCtl3D;{$ENDIF}
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
procedure UiPaintNcBorder(WinCtrl: TWinControl; ABack: TColor);
// Перерисовать рамку (служебную область окна)
procedure UiRedrawFrame(WinCtrl: TWinControl);
{$IFDEF FPC}
// Lazarus: рамку системного элемента LCL рисует Windows уже после своего
// WM_NCPAINT элемента - своя рамка (UiPaintNcBorder) пропадала. Окно
// подменяется: после WM_NCPAINT Windows - своя рамка цветом Color.
// Вызывать из CreateWnd
procedure UiNcHookAttach(WinCtrl: TWinControl);
{$ENDIF}
// Поставить свои полосы прокрутки (TUiListScroll), если их ещё нет
procedure UiAttachScroll(WinCtrl: TWinControl);

implementation

uses
  UiScroll;

// ---------------------------------------------------------------------------
//  Общее
// ---------------------------------------------------------------------------

// Рамка элемента в темах Dark и Custom - поверх рамки, которую только что
// нарисовал Windows: внешняя линия - цветом рамки, остальная ширина рамки -
// цветом фона. Полосы прокрутки внутри рамки не задеваются.
procedure UiPaintNcBorder(WinCtrl: TWinControl; ABack: TColor);
var
  DC: HDC;
  RectVal: TRect;
  Pnt: TPoint;
  BorderW, I: Integer;
  Br: HBRUSH;
  Line: TColor;
begin
  if UiThemeNativeFor(WinCtrl) or not WinCtrl.HandleAllocated then
    Exit;
  GetWindowRect(WinCtrl.Handle, RectVal);
  Pnt := Point(0, 0);
  Windows.ClientToScreen(WinCtrl.Handle, Pnt);
  BorderW := Pnt.X - RectVal.Left;          // ширина рамки слева - такая же со всех сторон
  if BorderW <= 0 then
    Exit;
  if BorderW > 3 then
    BorderW := 3;
  OffsetRect(RectVal, -RectVal.Left, -RectVal.Top);
  if WinCtrl.Focused then
    Line := UiThemeColorFor(WinCtrl, 'Focus')
  else
    Line := UiThemeColorFor(WinCtrl, 'Button.Border');
  DC := GetWindowDC(WinCtrl.Handle);
  try
    Br := CreateSolidBrush(ColorToRGB(Line));
    FrameRect(DC, RectVal, Br);
    DeleteObject(Br);
    Br := CreateSolidBrush(ColorToRGB(ABack));
    for I := 2 to BorderW do
    begin
      InflateRect(RectVal, -1, -1);
      FrameRect(DC, RectVal, Br);
    end;
    DeleteObject(Br);
  finally
    ReleaseDC(WinCtrl.Handle, DC);
  end;
end;

// Перерисовать рамку (служебную область окна)
procedure UiRedrawFrame(WinCtrl: TWinControl);
begin
  if WinCtrl.HandleAllocated then
    RedrawWindow(WinCtrl.Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or
                 RDW_NOCHILDREN);
end;

{$IFDEF FPC}
const
  UiNcHookProp = 'UiNcHook';

type
  TUiNcHook = class
    Ctrl: TWinControl;
    OldProc: Pointer;
  end;
  TUiNcColorAcc = class(TWinControl);

function UiNcHookProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
var
  Hook: TUiNcHook;
begin
  Hook := TUiNcHook(GetProp(AWnd, UiNcHookProp));
  if Hook = nil then
  begin
    Result := DefWindowProcW(AWnd, AMsg, AWParam, ALParam);
    Exit;
  end;
  Result := CallWindowProcW(Hook.OldProc, AWnd, AMsg, AWParam, ALParam);
  case AMsg of
    WM_NCPAINT:
      UiPaintNcBorder(Hook.Ctrl, TUiNcColorAcc(Hook.Ctrl).Color);
    WM_NCDESTROY:
      begin
        SetWindowLongPtrW(AWnd, GWLP_WNDPROC, LONG_PTR(Hook.OldProc));
        RemoveProp(AWnd, UiNcHookProp);
        Hook.Free;
      end;
  end;
end;

procedure UiNcHookAttach(WinCtrl: TWinControl);
var
  Hook: TUiNcHook;
begin
  if not WinCtrl.HandleAllocated or
     (GetProp(WinCtrl.Handle, UiNcHookProp) <> 0) then
    Exit;
  Hook := TUiNcHook.Create;
  Hook.Ctrl := WinCtrl;
  SetProp(WinCtrl.Handle, UiNcHookProp, THandle(Hook));
  Hook.OldProc := Pointer(SetWindowLongPtrW(WinCtrl.Handle, GWLP_WNDPROC,
    LONG_PTR(@UiNcHookProc)));
end;
{$ENDIF}

// Поставить свои полосы прокрутки, если их ещё нет
procedure UiAttachScroll(WinCtrl: TWinControl);
begin
  if (WinCtrl.Parent <> nil) and (UiScrollFind(WinCtrl) = nil) then
    TUiListScroll.Attach(WinCtrl);
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

{$IFDEF FPC}
procedure TUiEdit.CreateWnd;
begin
  inherited CreateWnd;
  UiNcHookAttach(Self);
end;
{$ENDIF}

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
  {$IFDEF FPC}
  UiNcHookAttach(Self);
  {$ENDIF}
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
  {$IFDEF FPC}
  UiNcHookAttach(Self);
  {$ENDIF}
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
      {$IFDEF FPC}RecreateWnd(Self){$ELSE}RecreateWnd{$ENDIF};
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

{$IFDEF FPC}
// Lazarus (Windows): строку раскрытого списка LCL отдаёт OnDrawItem только
// при Style csOwnerDrawFixed и подобных (win32callback, WM_DRAWITEM). У
// ListOwnerDraw стиль окна свой (CBS_OWNERDRAWFIXED в CreateParams), а Style
// остаётся csDropDown или csDropDownList - строка приходит сюда как
// LM_DRAWITEM и без этого обработчика не рисовалась: список раскрывался
// белым полем. Переводим её в LM_DRAWLISTITEM - дальше как у LCL:
// холст, шрифт, цвет выделения и DrawItem (OnDrawItem).
procedure TUiComboBox.LMDrawItem(var Message: TLMDrawItems);
var
  ItemRec: LCLType.PDrawItemStruct;
  ListRec: TDrawListItemStruct;
  ListMsg: TLMDrawListItem;
  StateKind: TOwnerDrawStateType;
begin
  ItemRec := Message.DrawItemStruct;
  if not FListOwnerDraw or (ItemRec = nil) or
     (ItemRec^.itemID = UINT(-1)) then
  begin
    inherited;
    Exit;
  end;
  ListRec.ItemID := ItemRec^.itemID;
  ListRec.Area := ItemRec^.rcItem;
  ListRec.DC := ItemRec^._hDC;
  // Биты ODS_* идут в том же порядке, что TOwnerDrawStateType
  ListRec.ItemState := [];
  for StateKind := Low(TOwnerDrawStateType) to High(TOwnerDrawStateType) do
    if (ItemRec^.itemState and (UINT(1) shl Ord(StateKind))) <> 0 then
      Include(ListRec.ItemState, StateKind);
  FillChar(ListMsg, SizeOf(ListMsg), 0);
  ListMsg.Msg := LM_DRAWLISTITEM;
  ListMsg.DrawListItemStruct := @ListRec;
  Dispatch(ListMsg);
  Message.Result := 1;
end;
{$ENDIF}

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
  RectVal2, RectVal: TRect;
  WidthPx, Cx, Cy, StartPos: Integer;
  Br: HBRUSH;
  Pen, OldPen: HPEN;
  OldBr: HBRUSH;
  Pts: array[0..2] of TPoint;
  Down: Boolean;
  Face, Mark, Line, Back, Fore: TColor;
  RectVal3: TRect;
  Cv: TCanvas;
  Txt: string;
  EditWnd: HWND;
  EditRect: TRect;
  SavedDC: Integer;
begin
  RectVal2 := ClientRect;
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
  WidthPx := GetSystemMetrics(SM_CXVSCROLL);
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
      FillRect(DC, RectVal2, Br);
      DeleteObject(Br);
    finally
      RestoreDC(DC, SavedDC);
    end;
  end;

  // Рамка: линия и полоса в точку цветом фона внутри
  Br := CreateSolidBrush(ColorToRGB(Line));
  FrameRect(DC, RectVal2, Br);
  DeleteObject(Br);
  InflateRect(RectVal2, -1, -1);
  Br := CreateSolidBrush(ColorToRGB(Back));
  FrameRect(DC, RectVal2, Br);
  DeleteObject(Br);

  // Кнопка списка - справа во всю высоту внутри рамки
  RectVal := Rect(RectVal2.Right - WidthPx, RectVal2.Top, RectVal2.Right, RectVal2.Bottom);

  // Список без поля ввода (csDropDownList): выбранный пункт - тоже сами.
  // Windows рисует его поле по-своему и не всегда цветом Color. В фокусе -
  // фон цветом Focus, как выделение у системного.
  if Style = csDropDownList then
  begin
    RectVal3 := Rect(RectVal2.Left + 1, RectVal2.Top + 1, RectVal.Left, RectVal2.Bottom - 1);
    Cv := TCanvas.Create;
    try
      Cv.Handle := DC;
      if Focused and not Down then
        Cv.Brush.Color := UiThemeColorFor(Self, 'Focus')
      else
        Cv.Brush.Color := Back;
      Cv.FillRect(RectVal3);
      Cv.Font := Font;
      if Enabled then
        Cv.Font.Color := Fore
      else
        Cv.Font.Color := UiThemeColorFor(Self, 'OffText');
      Txt := Text;
      InflateRect(RectVal3, -2, 0);
      Cv.Brush.Style := bsClear;
      UiDrawText(Cv.Handle, PChar(Txt), Length(Txt), RectVal3,
               DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS or
               DT_NOPREFIX);
    finally
      Cv.Handle := 0;
      Cv.Free;
    end;
  end;
  Br := CreateSolidBrush(ColorToRGB(Face));
  FillRect(DC, RectVal, Br);
  DeleteObject(Br);

  // Стрелка вниз
  Cx := (RectVal.Left + RectVal.Right) div 2;
  Cy := (RectVal.Top + RectVal.Bottom) div 2;
  StartPos := WidthPx div 4;
  if StartPos < 2 then
    StartPos := 2;
  Pts[0] := Point(Cx - StartPos, Cy - StartPos div 2);
  Pts[1] := Point(Cx + StartPos, Cy - StartPos div 2);
  Pts[2] := Point(Cx, Cy + StartPos div 2 + 1);
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
