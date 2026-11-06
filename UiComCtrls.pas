unit UiComCtrls;

// ---------------------------------------------------------------------------
//  Свои элементы страницы Win32, которые есть в IDE (этап 2), вид - по
//  теме UiTheme:
//
//    TUiPageControl, TUiTabControl - вкладки (TPageControl, TTabControl)
//    TUiStatusBar                  - строка состояния (TStatusBar)
//    TUiTreeView, TUiListView      - дерево и таблица (TTreeView, TListView)
//    TUiUpDown                     - стрелки счётчика (TUpDown)
//
//  Все - наследники классов VCL с тем же поведением. В теме Light при
//  включённых темах Windows выглядят как системные (рисует Windows). В
//  темах Dark и Custom:
//    - вкладки, строку состояния и стрелки счётчика рисуют сами целиком
//      (WM_PAINT своего класса): ярлычки - ролями Tab.*, строка состояния -
//      Window.*, стрелки - Button.*;
//    - у дерева и таблицы - цвета List.BG / List.Text (ThemeColors, как у
//      TUiEdit), рамка поверх рамки Windows, свои полосы прокрутки;
//      заголовки колонок таблицы - через NM_CUSTOMDRAW заголовка, цветами
//      Button.*.
// ---------------------------------------------------------------------------

interface

uses
  {$IFDEF FPC} LCLType, {$ENDIF}
  Windows, Messages, SysUtils, Classes, Graphics, Controls, ComCtrls,
  CommCtrl, UiTheme, UiEditCtrls;

type
  TUiPageControl = class(TPageControl)
  private
    FHot: Integer;
    {$IFDEF FPC}
    FTabHook: TObject;            // подмена окна ярлычков (UiTabHookAttach)
    {$ENDIF}
    {$IFDEF UNIX}
    procedure OwnColors;
    {$ENDIF}
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure MouseMove(Shift: TShiftState; PosX, PosY: Integer); override;
    procedure CreateParams(var Params: TCreateParams); override;
    {$IFDEF FPC}
    procedure CreateWnd; override;
    {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TUiTabControl = class(TTabControl)
  private
    FHot: Integer;
    {$IFDEF FPC}
    FTabHook: TObject;            // подмена окна ярлычков (UiTabHookAttach)
    procedure HookInner;
    {$ENDIF}
    {$IFDEF UNIX}
    // Linux (gtk2): ярлычки рисуются и раскладываются здесь, вложенный
    // элемент вкладок LCL скрыт (его ярлычки gtk не показывал)
  private
    FOwnRects: array of TRect;
    FMeasure: TBitmap;
    FChangeFired: Boolean;
    procedure OwnLayout;
    procedure OwnPaint(ADC: HDC);
    procedure OwnHideInner;
    {$ENDIF}
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure MouseMove(Shift: TShiftState; PosX, PosY: Integer); override;
    procedure CreateParams(var Params: TCreateParams); override;
    {$IFDEF UNIX}
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      PosX, PosY: Integer); override;
    procedure Change; override;
    {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    {$IFDEF UNIX}
    function IndexOfTabAt(X, Y: Integer): Integer; overload; override;
    {$ENDIF}
    {$IFDEF FPC}
    // В LCL ярлычки TTabControl - у вложенного элемента вкладок, а свой
    // TabRect у TTabControl возвращает пустой прямоугольник. Здесь - место
    // ярлычка у вложенного элемента, в координатах самого TUiTabControl
    function TabRect(Index: Integer): TRect; reintroduce;
    {$ENDIF}
  end;

  TUiStatusBar = class(TStatusBar)
  private
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure PaintOwn(DC: HDC);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TUiTreeView = class(TTreeView)
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
  end;

  TUiListView = class(TListView)
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
    procedure WMNotify(var Message: TWMNotify); message WM_NOTIFY;
    procedure DrawHeaderItem(CD: PNMCustomDraw);
    procedure DrawHeaderRest(CD: PNMCustomDraw);
    {$IFDEF LCLGTK2}
    procedure GtkHeaderColors;
    {$ENDIF}
  protected
    procedure ApplyTheme;
    procedure Loaded; override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
{$IFDEF FPC}
    // Как TListView.UpdateItems в VCL: перерисовать строки с AFirst по
    // ALast (LVM_REDRAWITEMS) сразу
    procedure UpdateItems(AFirst, ALast: Integer);
{$ENDIF}
  published
    property ThemeColors: Boolean read FThemeColors write SetThemeColors
      default True;
  end;

  TUiUpDown = class(TUpDown)
  private
    FHotPart: Integer;    // 0 - нет, 1 - вверх/влево, 2 - вниз/вправо
    FDownPart: Integer;
    function PartAt(PosX, PosY: Integer): Integer;
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMLButtonDown(var Message: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
    procedure WMMouseMove(var Message: TWMMouseMove); message WM_MOUSEMOVE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure PaintOwn(DC: HDC);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{$IFDEF LCLGTK2}
uses
  gtk2, gdk2, glib2;
{$ENDIF}

type
  // Доступ к защищённым Tabs и TabIndex вкладок
  TUiTabAcc = class(TCustomTabControl);

// ---------------------------------------------------------------------------
//  Общее: вкладки
// ---------------------------------------------------------------------------

// Ярлычок под точкой (в клиентских координатах); -1 - нет
function UiTabAt(C: TCustomTabControl; X, Y: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to TUiTabAcc(C).Tabs.Count - 1 do
    if PtInRect(C.TabRect(I), Point(X, Y)) then
    begin
      Result := I;
      Exit;
    end;
end;

// Вкладки целиком: фон, рамка области страниц, ярлычки с подписями. У
// вкладок OwnerDraw подпись рисует владелец - как при отрисовке Windows,
// через CN_DRAWITEM (он проходит через WindowProc элемента).
procedure UiPaintTabs(CustomTabControl: TCustomTabControl; DC: HDC; AHot: Integer);
var
  Cv: TCanvas;
  UiTabAcc: TUiTabAcc;
  I, Active: Integer;
  RectVal2, RectVal: TRect;
  Str: string;
  DIS: TDrawItemStruct;
begin
  UiTabAcc := TUiTabAcc(CustomTabControl);
  Cv := TCanvas.Create;
  try
    Cv.Handle := DC;
    Cv.Brush.Style := bsSolid;
    Cv.Brush.Color := UiThemeColorFor(CustomTabControl, 'Window.BG');
    Cv.FillRect(CustomTabControl.ClientRect);

    // Область страниц - рамкой, ярлычки к ней примыкают. Её место даёт
    // сам элемент Windows (TCM_ADJUSTRECT).
    RectVal := CustomTabControl.ClientRect;
    if CustomTabControl.HandleAllocated then
      SendMessage(CustomTabControl.Handle, TCM_ADJUSTRECT, 0, LPARAM(@RectVal));
    InflateRect(RectVal, 1, 1);
    Cv.Brush.Color := UiThemeColorFor(CustomTabControl, 'Tab.Border');
    Cv.FrameRect(RectVal);

    Cv.Font := UiTabAcc.Font;
    Active := UiTabAcc.TabIndex;
    for I := 0 to UiTabAcc.Tabs.Count - 1 do
    begin
      RectVal2 := CustomTabControl.TabRect(I);
      if (RectVal2.Right <= RectVal2.Left) or (RectVal2.Bottom <= RectVal2.Top) then
        Continue;
      if I = Active then
        Cv.Brush.Color := UiThemeColorFor(CustomTabControl, 'Tab.ActiveBG')
      else if I = AHot then
        Cv.Brush.Color := UiThemeColorFor(CustomTabControl, 'Tab.HotBG')
      else
        Cv.Brush.Color := UiThemeColorFor(CustomTabControl, 'Tab.BG');
      Cv.FillRect(RectVal2);
      Cv.Brush.Color := UiThemeColorFor(CustomTabControl, 'Tab.Border');
      Cv.FrameRect(RectVal2);
      if UiTabAcc.OwnerDraw then
      begin
        FillChar(DIS, SizeOf(DIS), 0);
        DIS.CtlType := ODT_TAB;
        DIS.itemID := I;
        DIS.itemAction := ODA_DRAWENTIRE;
        if I = Active then
          DIS.itemState := ODS_SELECTED;
        DIS.hwndItem := CustomTabControl.Handle;
        DIS.hDC := DC;
        DIS.rcItem := RectVal2;
        InflateRect(DIS.rcItem, -1, -1);   // рамка ярлычка - наша
        CustomTabControl.Perform(CN_DRAWITEM, 0, LPARAM(@DIS));
        Continue;
      end;
      Str := UiTabAcc.Tabs[I];
      if CustomTabControl.Enabled then
        Cv.Font.Color := UiThemeColorFor(CustomTabControl, 'Tab.Text')
      else
        Cv.Font.Color := UiThemeColorFor(CustomTabControl, 'OffText');
      Cv.Brush.Style := bsClear;
      UiDrawText(Cv.Handle, PChar(Str), Length(Str), RectVal2,
               DT_SINGLELINE or DT_CENTER or DT_VCENTER);
      Cv.Brush.Style := bsSolid;
    end;
  finally
    Cv.Handle := 0;
    Cv.Free;
  end;
end;

// WM_PAINT своих вкладок: в Light при темах Windows - Windows, иначе свои
function UiTabsPaint(CustomTabControl: TCustomTabControl; var Message: TWMPaint;
                     AHot: Integer): Boolean;
var
  PS: TPaintStruct;
  DC: HDC;
begin
  Result := False;
  if UiThemeNativeFor(CustomTabControl) then
    Exit;
  Result := True;
  DC := Message.DC;
  if DC = 0 then
    DC := BeginPaint(CustomTabControl.Handle, PS);
  try
    UiPaintTabs(CustomTabControl, DC, AHot);
  finally
    if Message.DC = 0 then
      EndPaint(CustomTabControl.Handle, PS);
  end;
  Message.Result := 0;
end;

// Вкладки в несколько рядов (MultiLine): у ярлычков-вкладок Windows ставит
// ряд выбранной вкладки вниз, к странице, и ряды меняются местами при
// каждом выборе. У ярлычков-кнопок (TCS_BUTTONS) ряды стоят на месте.
procedure UiTabsFixRows(CustomTabControl: TCustomTabControl; var Params: TCreateParams);
begin
  if Params.Style and TCS_MULTILINE <> 0 then
    Params.Style := Params.Style or TCS_BUTTONS;
end;

{$IFDEF FPC}
// ---------------------------------------------------------------------------
//  Lazarus: подмена окна ярлычков
// ---------------------------------------------------------------------------
//  В LCL ярлычки TPageControl и ярлычки внутри TTabControl (вложенный
//  TPageControl) рисует сам Windows: свой WM_PAINT элемента до них не
//  доходит, OwnerDraw TTabControl вложенному не передаётся. Ярлычки были
//  системными, белыми и в тёмной теме. Окно ярлычков подменяется
//  (SetWindowLongPtrW): WM_PAINT - своя отрисовка цветами темы, подписи
//  OwnerDraw - тем же CN_DRAWITEM, что у VCL.

const
  UiTabHookProp = 'UiTabHook';

type
  TUiTabHook = class
    Wnd: HWND;
    OldProc: Pointer;
    Source: TCustomTabControl;   // ярлычки, выбранный, OwnerDraw, шрифт, тема
    Rects: TCustomTabControl;    // чей TabRect и ClientOrigin
    Frame: Boolean;              // рамка области страниц (TPageControl)
  end;

procedure UiTabHookPaint(AHook: TUiTabHook; ADC: HDC);
var
  Cv: TCanvas;
  Acc: TUiTabAcc;
  TabIdx, Active: Integer;
  Area, Box: TRect;
  WndOrigin: TPoint;
  Str: string;
  DIS: TDrawItemStruct;
  TabList: TStrings;
  IsOwnerDraw: Boolean;
begin
  Acc := TUiTabAcc(AHook.Source);
  // У TTabControl LCL свои Tabs и TabIndex (TCustomTabControl.Tabs у него -
  // пустой список страниц)
  if AHook.Source is TTabControl then
  begin
    TabList := TTabControl(AHook.Source).Tabs;
    Active := TTabControl(AHook.Source).TabIndex;
    IsOwnerDraw := TTabControl(AHook.Source).OwnerDraw;
  end
  else
  begin
    TabList := Acc.Tabs;
    Active := Acc.TabIndex;
    IsOwnerDraw := Acc.OwnerDraw;
  end;
  Cv := TCanvas.Create;
  try
    Cv.Handle := ADC;
    Cv.Brush.Style := bsSolid;
    Cv.Brush.Color := UiThemeColorFor(Acc, 'Window.BG');
    Windows.GetClientRect(AHook.Wnd, Area);
    Cv.FillRect(Area);
    if AHook.Frame then
    begin
      Box := Area;
      SendMessage(AHook.Wnd, TCM_ADJUSTRECT, 0, LPARAM(@Box));
      InflateRect(Box, 1, 1);
      Cv.Brush.Color := UiThemeColorFor(Acc, 'Tab.Border');
      Cv.FrameRect(Box);
    end;
    Cv.Font := Acc.Font;
    // TabRect LCL - от клиентской области LCL (страница под ярлычками),
    // рисуем в координатах окна
    WndOrigin := Point(0, 0);
    Windows.ClientToScreen(AHook.Wnd, WndOrigin);
    for TabIdx := 0 to TabList.Count - 1 do
    begin
      Box := AHook.Rects.TabRect(TabIdx);
      if (Box.Right <= Box.Left) or (Box.Bottom <= Box.Top) then
        Continue;
      OffsetRect(Box, AHook.Rects.ClientOrigin.X - WndOrigin.X,
        AHook.Rects.ClientOrigin.Y - WndOrigin.Y);
      if TabIdx = Active then
        Cv.Brush.Color := UiThemeColorFor(Acc, 'Tab.ActiveBG')
      else
        Cv.Brush.Color := UiThemeColorFor(Acc, 'Tab.BG');
      Cv.FillRect(Box);
      Cv.Brush.Color := UiThemeColorFor(Acc, 'Tab.Border');
      Cv.FrameRect(Box);
      if IsOwnerDraw then
      begin
        FillChar(DIS, SizeOf(DIS), 0);
        DIS.CtlType := ODT_TAB;
        DIS.itemID := TabIdx;
        DIS.itemAction := ODA_DRAWENTIRE;
        if TabIdx = Active then
          DIS.itemState := ODS_SELECTED;
        DIS.hwndItem := Acc.Handle;
        DIS.hDC := ADC;
        DIS.rcItem := Box;
        InflateRect(DIS.rcItem, -1, -1);
        Acc.Perform(CN_DRAWITEM, 0, LPARAM(@DIS));
        Continue;
      end;
      Str := TabList[TabIdx];
      if Acc.Enabled then
        Cv.Font.Color := UiThemeColorFor(Acc, 'Tab.Text')
      else
        Cv.Font.Color := UiThemeColorFor(Acc, 'OffText');
      Cv.Brush.Style := bsClear;
      UiDrawText(Cv.Handle, PChar(Str), Length(Str), Box,
        DT_SINGLELINE or DT_CENTER or DT_VCENTER);
      Cv.Brush.Style := bsSolid;
    end;
  finally
    Cv.Handle := 0;
    Cv.Free;
  end;
end;

function UiTabHookProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
var
  Hook: TUiTabHook;
  PS: TPaintStruct;
  DC: HDC;
  OldProc: Pointer;
begin
  Hook := TUiTabHook(GetProp(AWnd, UiTabHookProp));
  if Hook = nil then
  begin
    Result := DefWindowProcW(AWnd, AMsg, AWParam, ALParam);
    Exit;
  end;
  OldProc := Hook.OldProc;
  case AMsg of
    WM_ERASEBKGND:
      begin
        Result := 1;
        Exit;
      end;
    WM_PAINT:
      begin
        DC := HDC(AWParam);
        if DC = 0 then
          DC := BeginPaint(AWnd, PS);
        try
          UiTabHookPaint(Hook, DC);
        finally
          if AWParam = 0 then
            EndPaint(AWnd, PS);
        end;
        Result := 0;
        Exit;
      end;
    WM_NCDESTROY:
      begin
        // Окно уходит (в том числе пересоздание): подмену снять, при
        // новом окне - поставить заново
        SetWindowLongPtrW(AWnd, GWLP_WNDPROC, LONG_PTR(OldProc));
        RemoveProp(AWnd, UiTabHookProp);
        Hook.Wnd := 0;
      end;
  end;
  Result := CallWindowProcW(OldProc, AWnd, AMsg, AWParam, ALParam);
end;

function UiTabHookActive(AHook: TObject): Boolean;
begin
  Result := (AHook <> nil) and (TUiTabHook(AHook).Wnd <> 0);
end;

procedure UiTabHookAttach(var AHook: TObject; ASource, ARects: TCustomTabControl;
  AFrame: Boolean);
var
  Hook: TUiTabHook;
begin
  if not ARects.HandleAllocated then
    Exit;
  if AHook = nil then
    AHook := TUiTabHook.Create;
  Hook := TUiTabHook(AHook);
  if Hook.Wnd = ARects.Handle then
    Exit;
  Hook.Source := ASource;
  Hook.Rects := ARects;
  Hook.Frame := AFrame;
  Hook.Wnd := ARects.Handle;
  SetProp(Hook.Wnd, UiTabHookProp, THandle(Hook));
  Hook.OldProc := Pointer(SetWindowLongPtrW(Hook.Wnd, GWLP_WNDPROC,
    LONG_PTR(@UiTabHookProc)));
  InvalidateRect(Hook.Wnd, nil, True);
end;

procedure UiTabHookInvalidate(AHook: TObject);
begin
  if UiTabHookActive(AHook) then
    InvalidateRect(TUiTabHook(AHook).Wnd, nil, True);
end;

procedure UiTabHookFree(var AHook: TObject);
var
  Hook: TUiTabHook;
begin
  if AHook = nil then
    Exit;
  Hook := TUiTabHook(AHook);
  if (Hook.Wnd <> 0) and IsWindow(Hook.Wnd) then
  begin
    SetWindowLongPtrW(Hook.Wnd, GWLP_WNDPROC, LONG_PTR(Hook.OldProc));
    RemoveProp(Hook.Wnd, UiTabHookProp);
  end;
  FreeAndNil(AHook);
end;
{$ENDIF}

// ---------------------------------------------------------------------------
//  TUiPageControl
// ---------------------------------------------------------------------------

constructor TUiPageControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHot := -1;
  UiThemeAddClient(Self);
end;

destructor TUiPageControl.Destroy;
begin
  UiThemeRemoveClient(Self);
  {$IFDEF FPC}
  UiTabHookFree(FTabHook);
  {$ENDIF}
  inherited Destroy;
end;

{$IFDEF FPC}
// Ярлычки TPageControl в LCL рисует Windows: WM_PAINT до своего
// обработчика не доходит. Окно подменяется (UiTabHookAttach)
procedure TUiPageControl.CreateWnd;
begin
  inherited CreateWnd;
  UiTabHookAttach(FTabHook, Self, Self, True);
end;
{$ENDIF}

procedure TUiPageControl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  UiTabsFixRows(Self, Params);
end;

procedure TUiPageControl.UMUiThemeChanged(var Message: TMessage);
begin
  {$IFDEF FPC}
  UiTabHookInvalidate(FTabHook);
  {$ENDIF}
  {$IFDEF UNIX}
  OwnColors;
  {$ENDIF}
  Message.Result := 0;   // UiThemeChanged перерисует
end;

{$IFDEF UNIX}
// Linux (gtk2): ярлычки GtkNotebook рисует сам gtk, своё рисование туда не
// попадает (ярлычки вне клиентской области, TabRect с отрицательным Y).
// В тёмной теме ярлычкам даются цвета темы: Color - фон notebook (ярлычки
// во всех состояниях), Font.Color страницы - подпись ярлычка
procedure TUiPageControl.OwnColors;
var
  BackColor, TextColor: TColor;
  PageIdx: Integer;
begin
  if UiThemeNativeFor(Self) then
  begin
    BackColor := clDefault;
    TextColor := clDefault;
  end
  else
  begin
    BackColor := UiThemeColorFor(Self, 'Tab.BG');
    TextColor := UiThemeColorFor(Self, 'Tab.Text');
  end;
  if Color <> BackColor then
    Color := BackColor;
  for PageIdx := 0 to PageCount - 1 do
    if Pages[PageIdx].Font.Color <> TextColor then
      Pages[PageIdx].Font.Color := TextColor;
end;
{$ENDIF}

procedure TUiPageControl.WMPaint(var Message: TWMPaint);
begin
  {$IFDEF UNIX}
  OwnColors;
  inherited;
  Exit;
  {$ENDIF}
  if not UiTabsPaint(Self, Message, FHot) then
    inherited;
end;

procedure TUiPageControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  {$IFDEF UNIX}
  inherited;
  Exit;
  {$ENDIF}
  if UiThemeNativeFor(Self) then
    inherited
  else
    Message.Result := 1;
end;

procedure TUiPageControl.MouseMove(Shift: TShiftState; PosX, PosY: Integer);
var
  HeightPx: Integer;
begin
  inherited MouseMove(Shift, PosX, PosY);
  HeightPx := UiTabAt(Self, PosX, PosY);
  if HeightPx <> FHot then
  begin
    FHot := HeightPx;
    if not UiThemeNativeFor(Self) then
      Invalidate;
  end;
end;

procedure TUiPageControl.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot <> -1 then
  begin
    FHot := -1;
    if not UiThemeNativeFor(Self) then
      Invalidate;
  end;
end;

// ---------------------------------------------------------------------------
//  TUiTabControl
// ---------------------------------------------------------------------------

constructor TUiTabControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHot := -1;
  UiThemeAddClient(Self);
end;

destructor TUiTabControl.Destroy;
begin
  UiThemeRemoveClient(Self);
  {$IFDEF FPC}
  UiTabHookFree(FTabHook);
  {$ENDIF}
  {$IFDEF UNIX}
  FMeasure.Free;
  {$ENDIF}
  inherited Destroy;
end;

{$IFDEF UNIX}
// Ярлычки по ширине подписей; MultiLine - перенос в следующий ряд
procedure TUiTabControl.OwnLayout;
const
  TabPadX = 16;
  TabPadY = 6;
var
  TabIdx, PosX, PosY, TabW, RowH, MaxW: Integer;
begin
  if FMeasure = nil then
    FMeasure := TBitmap.Create;
  FMeasure.Canvas.Font := Font;
  RowH := FMeasure.Canvas.TextHeight('Wg') + TabPadY;
  MaxW := ClientWidth - 2;
  SetLength(FOwnRects, Tabs.Count);
  PosX := 2;
  PosY := 2;
  for TabIdx := 0 to Tabs.Count - 1 do
  begin
    TabW := FMeasure.Canvas.TextWidth(Tabs[TabIdx]) + TabPadX;
    if MultiLine and (PosX > 2) and (PosX + TabW > MaxW) then
    begin
      PosX := 2;
      Inc(PosY, RowH);
    end;
    FOwnRects[TabIdx] := Rect(PosX, PosY, PosX + TabW, PosY + RowH);
    Inc(PosX, TabW);
  end;
end;

procedure TUiTabControl.OwnHideInner;
var
  CtlIdx: Integer;
begin
  for CtlIdx := 0 to ControlCount - 1 do
    if (Controls[CtlIdx] is TCustomTabControl) and Controls[CtlIdx].Visible then
      Controls[CtlIdx].Visible := False;
end;

procedure TUiTabControl.OwnPaint(ADC: HDC);
var
  Cv: TCanvas;
  TabIdx, Active: Integer;
  Box: TRect;
  Str: string;
  DIS: TDrawItemStruct;
begin
  OwnLayout;
  Active := TabIndex;
  Cv := TCanvas.Create;
  try
    Cv.Handle := ADC;
    Cv.Brush.Style := bsSolid;
    Cv.Brush.Color := UiThemeColorFor(Self, 'Window.BG');
    Cv.FillRect(ClientRect);
    Cv.Font := Font;
    for TabIdx := 0 to High(FOwnRects) do
    begin
      Box := FOwnRects[TabIdx];
      if TabIdx = Active then
        Cv.Brush.Color := UiThemeColorFor(Self, 'Tab.ActiveBG')
      else if TabIdx = FHot then
        Cv.Brush.Color := UiThemeColorFor(Self, 'Tab.HotBG')
      else
        Cv.Brush.Color := UiThemeColorFor(Self, 'Tab.BG');
      Cv.FillRect(Box);
      Cv.Brush.Color := UiThemeColorFor(Self, 'Tab.Border');
      Cv.FrameRect(Box);
      if OwnerDraw then
      begin
        FillChar(DIS, SizeOf(DIS), 0);
        DIS.CtlType := ODT_TAB;
        DIS.itemID := TabIdx;
        DIS.itemAction := ODA_DRAWENTIRE;
        if TabIdx = Active then
          DIS.itemState := ODS_SELECTED;
        DIS.hwndItem := Handle;
        DIS.hDC := ADC;
        DIS.rcItem := Box;
        InflateRect(DIS.rcItem, -1, -1);
        Perform(CN_DRAWITEM, 0, LPARAM(@DIS));
        Continue;
      end;
      Str := Tabs[TabIdx];
      if Enabled then
        Cv.Font.Color := UiThemeColorFor(Self, 'Tab.Text')
      else
        Cv.Font.Color := UiThemeColorFor(Self, 'OffText');
      Cv.Brush.Style := bsClear;
      Cv.TextRect(Box, Box.Left + 8, Box.Top + 3, Str);
      Cv.Brush.Style := bsSolid;
    end;
  finally
    Cv.Handle := 0;
    Cv.Free;
  end;
end;

function TUiTabControl.IndexOfTabAt(X, Y: Integer): Integer;
var
  TabIdx: Integer;
begin
  Result := -1;
  OwnLayout;
  for TabIdx := 0 to High(FOwnRects) do
    if PtInRect(FOwnRects[TabIdx], Point(X, Y)) then
    begin
      Result := TabIdx;
      Exit;
    end;
end;

procedure TUiTabControl.Change;
begin
  FChangeFired := True;
  inherited Change;
end;

// Щелчок по ярлычку: OnChanging, затем выбор (OnChange - от LCL при смене
// TabIndex вложенного элемента; если его не было - здесь)
procedure TUiTabControl.MouseDown(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
var
  TabIdx: Integer;
begin
  if Button = mbLeft then
  begin
    TabIdx := IndexOfTabAt(PosX, PosY);
    if (TabIdx >= 0) and (TabIdx <> TabIndex) and CanChange then
    begin
      FChangeFired := False;
      TabIndex := TabIdx;
      if not FChangeFired then
        Change;
      Invalidate;
    end;
  end;
  inherited MouseDown(Button, Shift, PosX, PosY);
end;
{$ENDIF}

{$IFDEF FPC}
// Lazarus (Windows): ярлычки TTabControl - у вложенного элемента вкладок
// LCL, его CreateParams не наш, и UiTabsFixRows до него не доходит: ряды
// без TCS_BUTTONS при каждом выборе менялись местами, выбранная вкладка
// уходила в нижний ряд. Стиль ставится окну вложенного элемента прямо.
procedure UiTabsFixRowsWnd(AWnd: HWND);
var
  StyleVal: LongInt;
begin
  if AWnd = 0 then
    Exit;
  StyleVal := GetWindowLong(AWnd, GWL_STYLE);
  if (StyleVal and TCS_MULTILINE = 0) or (StyleVal and TCS_BUTTONS <> 0) then
    Exit;
  SetWindowLong(AWnd, GWL_STYLE, StyleVal or TCS_BUTTONS);
  SetWindowPos(AWnd, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
               SWP_NOACTIVATE or SWP_FRAMECHANGED);
  InvalidateRect(AWnd, nil, True);
end;

procedure TUiTabControl.HookInner;
var
  CtlIdx: Integer;
begin
  // Стиль - при каждой отрисовке: LCL пересоздаёт вложенный элемент
  // (MultiLine, смена темы), а с ним и стиль окна
  for CtlIdx := 0 to ControlCount - 1 do
    if (Controls[CtlIdx] is TCustomTabControl) and
       TWinControl(Controls[CtlIdx]).HandleAllocated then
    begin
      UiTabsFixRowsWnd(TWinControl(Controls[CtlIdx]).Handle);
      Break;
    end;
  if UiTabHookActive(FTabHook) then
    Exit;
  for CtlIdx := 0 to ControlCount - 1 do
    if (Controls[CtlIdx] is TCustomTabControl) and
       TWinControl(Controls[CtlIdx]).HandleAllocated then
    begin
      UiTabHookAttach(FTabHook, Self, TCustomTabControl(Controls[CtlIdx]),
        False);
      Exit;
    end;
end;

function TUiTabControl.TabRect(Index: Integer): TRect;
var
  CtlIdx: Integer;
  Inner: TCustomTabControl;
begin
  {$IFDEF UNIX}
  OwnLayout;
  if (Index >= 0) and (Index <= High(FOwnRects)) then
    Result := FOwnRects[Index]
  else
    Result := Rect(0, 0, 0, 0);
  Exit;
  {$ENDIF}
  Result := inherited TabRect(Index);
  if not IsRectEmpty(Result) then
    Exit;
  for CtlIdx := 0 to ControlCount - 1 do
    if Controls[CtlIdx] is TCustomTabControl then
    begin
      Inner := TCustomTabControl(Controls[CtlIdx]);
      // TabRect вложенного - в его клиентских координатах; в тех же
      // координатах, что и здесь, LCL отдаёт OnMouseDown (AdjustXY)
      Result := Inner.TabRect(Index);
      OffsetRect(Result, Inner.ClientOrigin.X - ClientOrigin.X,
                 Inner.ClientOrigin.Y - ClientOrigin.Y);
      Exit;
    end;
end;
{$ENDIF}

procedure TUiTabControl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  UiTabsFixRows(Self, Params);
end;

procedure TUiTabControl.UMUiThemeChanged(var Message: TMessage);
begin
  {$IFDEF FPC}
  UiTabHookInvalidate(FTabHook);
  {$ENDIF}
  Message.Result := 0;
end;

procedure TUiTabControl.WMPaint(var Message: TWMPaint);
{$IFDEF FPC}
var
  PS: TPaintStruct;
  DC: HDC;
{$ENDIF}
begin
  {$IFDEF UNIX}
  OwnHideInner;
  if Message.DC <> 0 then
    OwnPaint(Message.DC);
  Message.Result := 0;
  Exit;
  {$ENDIF}
  {$IFDEF FPC}
  HookInner;
  // В LCL ярлычки рисует вложенный элемент вкладок, а сам TTabControl
  // (Paint) - область страницы темой Windows (ttPane): при включённых темах
  // это белая полоса с рамкой под ярлычками, и у вкладок-кнопок тоже. Здесь
  // всегда своя заливка фоном окна, как у VCL TTabControl с кнопками
  DC := Message.DC;
  if DC = 0 then
    DC := BeginPaint(Handle, PS);
  try
    UiPaintTabs(Self, DC, FHot);
  finally
    if Message.DC = 0 then
      EndPaint(Handle, PS);
  end;
  Message.Result := 0;
  {$ELSE}
  if not UiTabsPaint(Self, Message, FHot) then
    inherited;
  {$ENDIF}
end;

procedure TUiTabControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  if UiThemeNativeFor(Self) then
    inherited
  else
    Message.Result := 1;
end;

procedure TUiTabControl.MouseMove(Shift: TShiftState; PosX, PosY: Integer);
var
  HeightPx: Integer;
begin
  inherited MouseMove(Shift, PosX, PosY);
  {$IFDEF UNIX}
  HeightPx := IndexOfTabAt(PosX, PosY);
  {$ELSE}
  HeightPx := UiTabAt(Self, PosX, PosY);
  {$ENDIF}
  if HeightPx <> FHot then
  begin
    FHot := HeightPx;
    if not UiThemeNativeFor(Self) then
      Invalidate;
  end;
end;

procedure TUiTabControl.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot <> -1 then
  begin
    FHot := -1;
    if not UiThemeNativeFor(Self) then
      Invalidate;
  end;
end;

// ---------------------------------------------------------------------------
//  TUiStatusBar
// ---------------------------------------------------------------------------

constructor TUiStatusBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  {$IFDEF FPC}
  // В LCL по умолчанию SimplePanel = True (в VCL - False, в .dfm его нет):
  // панели не показывались бы
  SimplePanel := False;
  {$ENDIF}
  UiThemeAddClient(Self);
end;

destructor TUiStatusBar.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiStatusBar.UMUiThemeChanged(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TUiStatusBar.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  if UiThemeNativeFor(Self) then
    inherited
  else
    Message.Result := 1;
end;

procedure TUiStatusBar.WMPaint(var Message: TWMPaint);
var
  PS: TPaintStruct;
  DC: HDC;
begin
  if UiThemeNativeFor(Self) then
  begin
    inherited;
    Exit;
  end;
  DC := Message.DC;
  if DC = 0 then
    DC := BeginPaint(Handle, PS);
  try
    PaintOwn(DC);
  finally
    if Message.DC = 0 then
      EndPaint(Handle, PS);
  end;
  Message.Result := 0;
end;

// Фон, черта сверху, панели - текстом по своему выравниванию, между
// панелями - тонкая черта. Панели psOwnerDraw рисует OnDrawPanel.
procedure TUiStatusBar.PaintOwn(DC: HDC);
var
  Cv: TCanvas;
  I: Integer;
  RectVal: TRect;
  Str: string;
  Fl: Cardinal;
  StatusPanel: TStatusPanel;
begin
  Cv := TCanvas.Create;
  try
    Cv.Handle := DC;
    Cv.Brush.Style := bsSolid;
    Cv.Brush.Color := UiThemeColorFor(Self, 'Window.BG');
    Cv.FillRect(ClientRect);
    Cv.Pen.Color := UiThemeColorFor(Self, 'Group.Border');
    Cv.MoveTo(0, 0);
    Cv.LineTo(ClientWidth, 0);
    Cv.Font := Font;
    Cv.Font.Color := UiThemeColorFor(Self, 'Window.Text');
    Cv.Brush.Style := bsClear;

    if SimplePanel or (Panels.Count = 0) then
    begin
      RectVal := ClientRect;
      InflateRect(RectVal, -4, 0);
      Str := SimpleText;
      UiDrawText(Cv.Handle, PChar(Str), Length(Str), RectVal,
               DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
      Exit;
    end;

    for I := 0 to Panels.Count - 1 do
    begin
      if SendMessage(Handle, SB_GETRECT, I, LPARAM(@RectVal)) = 0 then
        Continue;
      StatusPanel := Panels[I];
      if StatusPanel.Style = psOwnerDraw then
      begin
        // Как у TStatusBar: холст панели - в OnDrawPanel
        Canvas.Handle := DC;
        try
          Canvas.Brush.Color := UiThemeColorFor(Self, 'Window.BG');
          Canvas.Font := Font;
          Canvas.Font.Color := UiThemeColorFor(Self, 'Window.Text');
          DrawPanel(StatusPanel, RectVal);
        finally
          Canvas.Handle := 0;
        end;
      end
      else
      begin
        Str := StatusPanel.Text;
        Fl := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
        case StatusPanel.Alignment of
          taRightJustify: Fl := Fl or DT_RIGHT;
          taCenter: Fl := Fl or DT_CENTER;
        else
          Fl := Fl or DT_LEFT;
        end;
        InflateRect(RectVal, -3, 0);
        UiDrawText(Cv.Handle, PChar(Str), Length(Str), RectVal, Fl);
        InflateRect(RectVal, 3, 0);
      end;
      // Черта справа от панели, кроме последней
      if I < Panels.Count - 1 then
      begin
        Cv.MoveTo(RectVal.Right, RectVal.Top + 2);
        Cv.LineTo(RectVal.Right, RectVal.Bottom - 2);
      end;
    end;
  finally
    Cv.Handle := 0;
    Cv.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  TUiTreeView
// ---------------------------------------------------------------------------

constructor TUiTreeView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  {$IFDEF FPC}
  // С tvoThemedDraw дерево LCL пишет текст и фон выделенного узла
  // цветами темы Windows (ThemeServices.DrawText): Canvas.Font.Color из
  // OnCustomDrawItem и тёмная тема IDE не действуют, текст чёрный. Без
  // него - Canvas.Font.Color, а выделенный узел - SelectionColor и
  // SelectionFontColor (Delphi 7 рисует так же, без тем: манифеста нет).
  Options := Options - [tvoThemedDraw];
  SelectionColor := clHighlight;
  SelectionFontColor := clHighlightText;
  SelectionFontColorUsed := True;
  {$ENDIF}
  FThemeColors := True;
  UiThemeAddClient(Self);
  ApplyTheme;
  FReady := True;
end;

destructor TUiTreeView.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiTreeView.ApplyTheme;
begin
  if not FThemeColors then
    Exit;
  FApplying := True;
  try
    if Color <> UiThemeColorFor(Self, 'List.BG') then
      Color := UiThemeColorFor(Self, 'List.BG');
    Font.Color := UiThemeColorFor(Self, 'List.Text');
  finally
    FApplying := False;
  end;
end;

procedure TUiTreeView.SetThemeColors(Value: Boolean);
begin
  if FThemeColors <> Value then
  begin
    FThemeColors := Value;
    ApplyTheme;
  end;
end;

procedure TUiTreeView.Loaded;
begin
  inherited Loaded;
  ApplyTheme;
end;

procedure TUiTreeView.CreateWnd;
begin
  inherited CreateWnd;
  {$IFDEF FPC}
  UiNcHookAttach(Self);
  {$ENDIF}
  PostMessage(Handle, UM_UIATTACHSCROLL, 0, 0);
end;

procedure TUiTreeView.UMUiAttachScroll(var Message: TMessage);
begin
  UiAttachScroll(Self);
end;

procedure TUiTreeView.UMUiThemeChanged(var Message: TMessage);
begin
  ApplyTheme;
  Invalidate;
  UiRedrawFrame(Self);
  Message.Result := 1;
end;

procedure TUiTreeView.CMColorChanged(var Message: TMessage);
begin
  inherited;
  if FReady and not FApplying and not (csLoading in ComponentState) then
    FThemeColors := False;
end;

procedure TUiTreeView.WMNCPaint(var Message: TMessage);
begin
  inherited;
  UiPaintNcBorder(Self, Color);
end;

procedure TUiTreeView.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  UiRedrawFrame(Self);
end;

procedure TUiTreeView.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  UiRedrawFrame(Self);
end;

// ---------------------------------------------------------------------------
//  TUiListView
// ---------------------------------------------------------------------------

{$IFDEF FPC}
procedure TUiListView.UpdateItems(AFirst, ALast: Integer);
const
  LVM_REDRAWITEMS_ = $1000 + 21;
begin
  if not HandleAllocated then
    Exit;
  SendMessage(Handle, LVM_REDRAWITEMS_, AFirst, ALast);
  UpdateWindow(Handle);
end;
{$ENDIF}

constructor TUiListView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FThemeColors := True;
  UiThemeAddClient(Self);
  ApplyTheme;
  FReady := True;
end;

destructor TUiListView.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiListView.ApplyTheme;
begin
  if not FThemeColors then
    Exit;
  FApplying := True;
  try
    if Color <> UiThemeColorFor(Self, 'List.BG') then
      Color := UiThemeColorFor(Self, 'List.BG');
    Font.Color := UiThemeColorFor(Self, 'List.Text');
  finally
    FApplying := False;
  end;
end;

{$IFDEF LCLGTK2}
// Linux (gtk2): заголовки столбцов - кнопки GtkTreeView, их рисует gtk
// цветами своей темы (NM_CUSTOMDRAW заголовка в LCL gtk2 нет). Кнопкам и
// подписям на них задаются цвета темы unIDE; в Light с системными цветами
// (UiThemeNativeFor) - сброс к цветам gtk
procedure TUiListView.GtkHeaderColors;
const
  HeaderStates: array[0..2] of TGtkStateType =
    (GTK_STATE_NORMAL, GTK_STATE_PRELIGHT, GTK_STATE_ACTIVE);
var
  TreeWidget, ButtonWidget: PGtkWidget;
  Column: PGtkTreeViewColumn;
  ColIdx, StateIdx: Integer;
  Native: Boolean;
  BackColors: array[0..2] of TGdkColor;
  TextColor: TGdkColor;

  procedure ToGdk(AColor: TColor; var AGdk: TGdkColor);
  var
    RgbValue: Longint;
  begin
    RgbValue := ColorToRGB(AColor);
    AGdk.pixel := 0;
    AGdk.red := (RgbValue and $FF) * 257;
    AGdk.green := ((RgbValue shr 8) and $FF) * 257;
    AGdk.blue := ((RgbValue shr 16) and $FF) * 257;
  end;

  procedure ColorLabels(AWidget: PGtkWidget);
  var
    Children, Item: PGList;
    LabelState: Integer;
  begin
    if GTK_IS_LABEL(AWidget) then
    begin
      for LabelState := 0 to High(HeaderStates) do
        if Native then
          gtk_widget_modify_fg(AWidget, HeaderStates[LabelState], nil)
        else
          gtk_widget_modify_fg(AWidget, HeaderStates[LabelState], @TextColor);
      Exit;
    end;
    if not GTK_IS_CONTAINER(AWidget) then
      Exit;
    Children := gtk_container_get_children(PGtkContainer(AWidget));
    Item := Children;
    while Item <> nil do
    begin
      ColorLabels(PGtkWidget(Item^.data));
      Item := Item^.next;
    end;
    g_list_free(Children);
  end;

begin
  if not HandleAllocated or (ViewStyle <> vsReport) then
    Exit;
  TreeWidget := PGtkWidget(Handle);
  if GTK_IS_BIN(TreeWidget) then
    TreeWidget := gtk_bin_get_child(PGtkBin(TreeWidget));
  if (TreeWidget = nil) or not GTK_IS_TREE_VIEW(TreeWidget) then
    Exit;
  Native := UiThemeNativeFor(Self);
  ToGdk(UiThemeColorFor(Self, 'Button.BG'), BackColors[0]);
  ToGdk(UiThemeColorFor(Self, 'Button.HotBG'), BackColors[1]);
  ToGdk(UiThemeColorFor(Self, 'Button.DownBG'), BackColors[2]);
  ToGdk(UiThemeColorFor(Self, 'Button.Text'), TextColor);
  ColIdx := 0;
  Column := gtk_tree_view_get_column(PGtkTreeView(TreeWidget), ColIdx);
  while Column <> nil do
  begin
    ButtonWidget := Column^.button;
    if ButtonWidget <> nil then
    begin
      for StateIdx := 0 to High(HeaderStates) do
        if Native then
          gtk_widget_modify_bg(ButtonWidget, HeaderStates[StateIdx], nil)
        else
          gtk_widget_modify_bg(ButtonWidget, HeaderStates[StateIdx], @BackColors[StateIdx]);
      ColorLabels(ButtonWidget);
    end;
    Inc(ColIdx);
    Column := gtk_tree_view_get_column(PGtkTreeView(TreeWidget), ColIdx);
  end;
end;
{$ENDIF}

procedure TUiListView.SetThemeColors(Value: Boolean);
begin
  if FThemeColors <> Value then
  begin
    FThemeColors := Value;
    ApplyTheme;
  end;
end;

procedure TUiListView.Loaded;
begin
  inherited Loaded;
  ApplyTheme;
end;

procedure TUiListView.CreateWnd;
begin
  inherited CreateWnd;
  {$IFDEF FPC}
  UiNcHookAttach(Self);
  {$ENDIF}
  PostMessage(Handle, UM_UIATTACHSCROLL, 0, 0);
end;

procedure TUiListView.UMUiAttachScroll(var Message: TMessage);
begin
  UiAttachScroll(Self);
  {$IFDEF LCLGTK2}
  GtkHeaderColors;   // столбцы из .dfm к этому времени созданы
  {$ENDIF}
end;

procedure TUiListView.UMUiThemeChanged(var Message: TMessage);
var
  Wnd: HWND;
begin
  ApplyTheme;
  {$IFDEF LCLGTK2}
  GtkHeaderColors;
  {$ENDIF}
  Invalidate;
  UiRedrawFrame(Self);
  // Заголовок колонок - отдельное окно: перерисовать и его
  if HandleAllocated then
  begin
    Wnd := SendMessage(Handle, LVM_GETHEADER, 0, 0);
    if Wnd <> 0 then
      InvalidateRect(Wnd, nil, True);
  end;
  Message.Result := 1;
end;

procedure TUiListView.CMColorChanged(var Message: TMessage);
begin
  inherited;
  if FReady and not FApplying and not (csLoading in ComponentState) then
    FThemeColors := False;
end;

procedure TUiListView.WMNCPaint(var Message: TMessage);
begin
  inherited;
  UiPaintNcBorder(Self, Color);
end;

procedure TUiListView.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  UiRedrawFrame(Self);
end;

procedure TUiListView.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  UiRedrawFrame(Self);
end;

// Заголовок колонок присылает NM_CUSTOMDRAW таблице (своему родителю). В
// темах Dark и Custom ярлычки колонок и пустое место справа от них
// рисуются здесь; остальное - как у TListView.
procedure TUiListView.WMNotify(var Message: TWMNotify);
var
  CD: PNMCustomDraw;
  Wnd: HWND;
begin
  if not UiThemeNativeFor(Self) and HandleAllocated and
     (Integer(Message.NMHdr^.code) = Integer(NM_CUSTOMDRAW)) then
  begin
    Wnd := SendMessage(Handle, LVM_GETHEADER, 0, 0);
    if (Wnd <> 0) and (Message.NMHdr^.hwndFrom = Wnd) then
    begin
      CD := PNMCustomDraw(Message.NMHdr);
      case CD^.dwDrawStage of
        CDDS_PREPAINT:
          Message.Result := CDRF_NOTIFYITEMDRAW or CDRF_NOTIFYPOSTPAINT;
        CDDS_ITEMPREPAINT:
          begin
            DrawHeaderItem(CD);
            Message.Result := CDRF_SKIPDEFAULT;
          end;
        CDDS_POSTPAINT:
          begin
            DrawHeaderRest(CD);
            Message.Result := CDRF_DODEFAULT;
          end;
      else
        Message.Result := CDRF_DODEFAULT;
      end;
      Exit;
    end;
  end;
  inherited;
end;

procedure TUiListView.DrawHeaderItem(CD: PNMCustomDraw);
var
  Cv: TCanvas;
  RectVal: TRect;
  Idx: Integer;
  Str: string;
  Fl: Cardinal;
begin
  RectVal := CD^.rc;
  Idx := Integer(CD^.dwItemSpec);
  Cv := TCanvas.Create;
  try
    Cv.Handle := CD^.hdc;
    if (CD^.uItemState and CDIS_SELECTED) <> 0 then
      Cv.Brush.Color := UiThemeColorFor(Self, 'Button.DownBG')
    else
      Cv.Brush.Color := UiThemeColorFor(Self, 'Button.BG');
    Cv.FillRect(RectVal);
    Cv.Pen.Color := UiThemeColorFor(Self, 'Button.Border');
    Cv.MoveTo(RectVal.Right - 1, RectVal.Top);
    Cv.LineTo(RectVal.Right - 1, RectVal.Bottom);
    Cv.MoveTo(RectVal.Left, RectVal.Bottom - 1);
    Cv.LineTo(RectVal.Right, RectVal.Bottom - 1);
    if (Idx >= 0) and (Idx < Columns.Count) then
    begin
      Str := Columns[Idx].Caption;
      Fl := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
      case Columns[Idx].Alignment of
        taRightJustify: Fl := Fl or DT_RIGHT;
        taCenter: Fl := Fl or DT_CENTER;
      else
        Fl := Fl or DT_LEFT;
      end;
      Cv.Font := Font;
      Cv.Font.Color := UiThemeColorFor(Self, 'Button.Text');
      Cv.Brush.Style := bsClear;
      InflateRect(RectVal, -6, 0);
      UiDrawText(Cv.Handle, PChar(Str), Length(Str), RectVal, Fl);
    end;
  finally
    Cv.Handle := 0;
    Cv.Free;
  end;
end;

// Справа от последней колонки заголовок рисует свой фон - закрашиваем
procedure TUiListView.DrawHeaderRest(CD: PNMCustomDraw);
var
  Cv: TCanvas;
  Wnd: HWND;
  Num: Integer;
  RectVal2, RectVal: TRect;
begin
  Wnd := CD^.hdr.hwndFrom;
  Windows.GetClientRect(Wnd, RectVal);
  Num := SendMessage(Wnd, HDM_GETITEMCOUNT, 0, 0);
  RectVal2 := RectVal;
  if Num > 0 then
  begin
    if SendMessage(Wnd, HDM_GETITEMRECT, Num - 1, LPARAM(@RectVal2)) = 0 then
      Exit;
    RectVal2.Left := RectVal2.Right;
    RectVal2.Right := RectVal.Right;
    RectVal2.Top := RectVal.Top;
    RectVal2.Bottom := RectVal.Bottom;
  end;
  if RectVal2.Right <= RectVal2.Left then
    Exit;
  Cv := TCanvas.Create;
  try
    Cv.Handle := CD^.hdc;
    Cv.Brush.Color := UiThemeColorFor(Self, 'Button.BG');
    Cv.FillRect(RectVal2);
    Cv.Pen.Color := UiThemeColorFor(Self, 'Button.Border');
    Cv.MoveTo(RectVal2.Left, RectVal2.Bottom - 1);
    Cv.LineTo(RectVal2.Right, RectVal2.Bottom - 1);
  finally
    Cv.Handle := 0;
    Cv.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  TUiUpDown
// ---------------------------------------------------------------------------

constructor TUiUpDown.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  UiThemeAddClient(Self);
end;

destructor TUiUpDown.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiUpDown.UMUiThemeChanged(var Message: TMessage);
begin
  Message.Result := 0;
end;

// Половина под точкой: 1 - верхняя (левая), 2 - нижняя (правая)
function TUiUpDown.PartAt(PosX, PosY: Integer): Integer;
begin
  Result := 0;
  if not PtInRect(ClientRect, Point(PosX, PosY)) then
    Exit;
  if Orientation = udVertical then
  begin
    if PosY < ClientHeight div 2 then
      Result := 1
    else
      Result := 2;
  end
  else
  begin
    if PosX < ClientWidth div 2 then
      Result := 1
    else
      Result := 2;
  end;
end;

procedure TUiUpDown.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  if UiThemeNativeFor(Self) then
    inherited
  else
    Message.Result := 1;
end;

procedure TUiUpDown.WMPaint(var Message: TWMPaint);
var
  PS: TPaintStruct;
  DC: HDC;
begin
  if UiThemeNativeFor(Self) then
  begin
    inherited;
    Exit;
  end;
  DC := Message.DC;
  if DC = 0 then
    DC := BeginPaint(Handle, PS);
  try
    PaintOwn(DC);
  finally
    if Message.DC = 0 then
      EndPaint(Handle, PS);
  end;
  Message.Result := 0;
end;

// Две кнопки со стрелками: фон по состоянию, рамка, треугольник
procedure TUiUpDown.PaintOwn(DC: HDC);
var
  Cv: TCanvas;
  R1, R2: TRect;

  procedure Part(const RectVal: TRect; APart: Integer; ALow: Boolean);
  var
    Cx, Cy, StartPos: Integer;
    Pts: array[0..2] of TPoint;
  begin
    if FDownPart = APart then
      Cv.Brush.Color := UiThemeColorFor(Self, 'Button.DownBG')
    else if (FHotPart = APart) and Enabled then
      Cv.Brush.Color := UiThemeColorFor(Self, 'Button.HotBG')
    else
      Cv.Brush.Color := UiThemeColorFor(Self, 'Button.BG');
    Cv.Pen.Color := UiThemeColorFor(Self, 'Button.Border');
    Cv.Rectangle(RectVal.Left, RectVal.Top, RectVal.Right, RectVal.Bottom);
    Cx := (RectVal.Left + RectVal.Right) div 2;
    Cy := (RectVal.Top + RectVal.Bottom) div 2;
    if Orientation = udVertical then
      StartPos := (RectVal.Bottom - RectVal.Top) div 4
    else
      StartPos := (RectVal.Right - RectVal.Left) div 4;
    if StartPos < 2 then
      StartPos := 2;
    if Orientation = udVertical then
    begin
      if ALow then
      begin
        Pts[0] := Point(Cx, Cy - StartPos div 2 - 1);
        Pts[1] := Point(Cx - StartPos, Cy + StartPos div 2);
        Pts[2] := Point(Cx + StartPos, Cy + StartPos div 2);
      end
      else
      begin
        Pts[0] := Point(Cx, Cy + StartPos div 2 + 1);
        Pts[1] := Point(Cx - StartPos, Cy - StartPos div 2);
        Pts[2] := Point(Cx + StartPos, Cy - StartPos div 2);
      end;
    end
    else
    begin
      if ALow then
      begin
        Pts[0] := Point(Cx - StartPos div 2 - 1, Cy);
        Pts[1] := Point(Cx + StartPos div 2, Cy - StartPos);
        Pts[2] := Point(Cx + StartPos div 2, Cy + StartPos);
      end
      else
      begin
        Pts[0] := Point(Cx + StartPos div 2 + 1, Cy);
        Pts[1] := Point(Cx - StartPos div 2, Cy - StartPos);
        Pts[2] := Point(Cx - StartPos div 2, Cy + StartPos);
      end;
    end;
    if Enabled then
      Cv.Brush.Color := UiThemeColorFor(Self, 'Button.Text')
    else
      Cv.Brush.Color := UiThemeColorFor(Self, 'OffText');
    Cv.Pen.Color := Cv.Brush.Color;
    Cv.Polygon(Pts);
  end;

begin
  Cv := TCanvas.Create;
  try
    Cv.Handle := DC;
    Cv.Brush.Style := bsSolid;
    Cv.Pen.Style := psSolid;
    if Orientation = udVertical then
    begin
      R1 := Rect(0, 0, ClientWidth, ClientHeight div 2);
      R2 := Rect(0, ClientHeight div 2, ClientWidth, ClientHeight);
    end
    else
    begin
      R1 := Rect(0, 0, ClientWidth div 2, ClientHeight);
      R2 := Rect(ClientWidth div 2, 0, ClientWidth, ClientHeight);
    end;
    // Для вертикального счётчика верхняя половина - «больше» (стрелка
    // вверх), для горизонтального левая - «меньше» (стрелка влево)
    Part(R1, 1, True);
    Part(R2, 2, False);
  finally
    Cv.Handle := 0;
    Cv.Free;
  end;
end;

// Нажатие и повтор делает сам элемент Windows; здесь - только какая
// половина нажата, для отрисовки
procedure TUiUpDown.WMLButtonDown(var Message: TWMLButtonDown);
begin
  FDownPart := PartAt(Message.XPos, Message.YPos);
  if not UiThemeNativeFor(Self) then
    Invalidate;
  inherited;
end;

procedure TUiUpDown.WMLButtonUp(var Message: TWMLButtonUp);
begin
  inherited;
  if FDownPart <> 0 then
  begin
    FDownPart := 0;
    if not UiThemeNativeFor(Self) then
      Invalidate;
  end;
end;

procedure TUiUpDown.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  if FDownPart <> 0 then
  begin
    FDownPart := 0;
    if not UiThemeNativeFor(Self) then
      Invalidate;
  end;
end;

procedure TUiUpDown.WMMouseMove(var Message: TWMMouseMove);
var
  CharPos: Integer;
begin
  inherited;
  CharPos := PartAt(Message.XPos, Message.YPos);
  if CharPos <> FHotPart then
  begin
    FHotPart := CharPos;
    if not UiThemeNativeFor(Self) then
      Invalidate;
  end;
end;

procedure TUiUpDown.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotPart <> 0 then
  begin
    FHotPart := 0;
    if not UiThemeNativeFor(Self) then
      Invalidate;
  end;
end;

initialization
  // Классы знает GetClass: .dfm, конструктор форм и снимок строят
  // настоящие элементы, а не заглушки
  if GetClass(TUiPageControl.ClassName) = nil then
    RegisterClass(TUiPageControl);
  if GetClass(TUiTabControl.ClassName) = nil then
    RegisterClass(TUiTabControl);
  if GetClass(TUiStatusBar.ClassName) = nil then
    RegisterClass(TUiStatusBar);
  if GetClass(TUiTreeView.ClassName) = nil then
    RegisterClass(TUiTreeView);
  if GetClass(TUiListView.ClassName) = nil then
    RegisterClass(TUiListView);
  if GetClass(TUiUpDown.ClassName) = nil then
    RegisterClass(TUiUpDown);
end.
