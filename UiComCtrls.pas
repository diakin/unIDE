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
  Windows, Messages, SysUtils, Classes, Graphics, Controls, ComCtrls,
  CommCtrl, UiTheme, UiEditCtrls;

type
  TUiPageControl = class(TPageControl)
  private
    FHot: Integer;
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TUiTabControl = class(TTabControl)
  private
    FHot: Integer;
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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

  TUiUpDown = class(TUpDown)
  private
    FHotPart: Integer;    // 0 - нет, 1 - вверх/влево, 2 - вниз/вправо
    FDownPart: Integer;
    function PartAt(X, Y: Integer): Integer;
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
procedure UiPaintTabs(C: TCustomTabControl; DC: HDC; AHot: Integer);
var
  Cv: TCanvas;
  A: TUiTabAcc;
  I, Active: Integer;
  R, D: TRect;
  S: string;
  DIS: TDrawItemStruct;
begin
  A := TUiTabAcc(C);
  Cv := TCanvas.Create;
  try
    Cv.Handle := DC;
    Cv.Brush.Style := bsSolid;
    Cv.Brush.Color := UiThemeColorFor(C, 'Window.BG');
    Cv.FillRect(C.ClientRect);

    // Область страниц - рамкой, ярлычки к ней примыкают. Её место даёт
    // сам элемент Windows (TCM_ADJUSTRECT).
    D := C.ClientRect;
    if C.HandleAllocated then
      SendMessage(C.Handle, TCM_ADJUSTRECT, 0, Integer(@D));
    InflateRect(D, 1, 1);
    Cv.Brush.Color := UiThemeColorFor(C, 'Tab.Border');
    Cv.FrameRect(D);

    Cv.Font := A.Font;
    Active := A.TabIndex;
    for I := 0 to A.Tabs.Count - 1 do
    begin
      R := C.TabRect(I);
      if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
        Continue;
      if I = Active then
        Cv.Brush.Color := UiThemeColorFor(C, 'Tab.ActiveBG')
      else if I = AHot then
        Cv.Brush.Color := UiThemeColorFor(C, 'Tab.HotBG')
      else
        Cv.Brush.Color := UiThemeColorFor(C, 'Tab.BG');
      Cv.FillRect(R);
      Cv.Brush.Color := UiThemeColorFor(C, 'Tab.Border');
      Cv.FrameRect(R);
      if A.OwnerDraw then
      begin
        FillChar(DIS, SizeOf(DIS), 0);
        DIS.CtlType := ODT_TAB;
        DIS.itemID := I;
        DIS.itemAction := ODA_DRAWENTIRE;
        if I = Active then
          DIS.itemState := ODS_SELECTED;
        DIS.hwndItem := C.Handle;
        DIS.hDC := DC;
        DIS.rcItem := R;
        InflateRect(DIS.rcItem, -1, -1);   // рамка ярлычка - наша
        C.Perform(CN_DRAWITEM, 0, Longint(@DIS));
        Continue;
      end;
      S := A.Tabs[I];
      if C.Enabled then
        Cv.Font.Color := UiThemeColorFor(C, 'Tab.Text')
      else
        Cv.Font.Color := UiThemeColorFor(C, 'OffText');
      Cv.Brush.Style := bsClear;
      DrawText(Cv.Handle, PChar(S), Length(S), R,
               DT_SINGLELINE or DT_CENTER or DT_VCENTER);
      Cv.Brush.Style := bsSolid;
    end;
  finally
    Cv.Handle := 0;
    Cv.Free;
  end;
end;

// WM_PAINT своих вкладок: в Light при темах Windows - Windows, иначе свои
function UiTabsPaint(C: TCustomTabControl; var Message: TWMPaint;
                     AHot: Integer): Boolean;
var
  PS: TPaintStruct;
  DC: HDC;
begin
  Result := False;
  if UiThemeNativeFor(C) then
    Exit;
  Result := True;
  DC := Message.DC;
  if DC = 0 then
    DC := BeginPaint(C.Handle, PS);
  try
    UiPaintTabs(C, DC, AHot);
  finally
    if Message.DC = 0 then
      EndPaint(C.Handle, PS);
  end;
  Message.Result := 0;
end;

// Вкладки в несколько рядов (MultiLine): у ярлычков-вкладок Windows ставит
// ряд выбранной вкладки вниз, к странице, и ряды меняются местами при
// каждом выборе. У ярлычков-кнопок (TCS_BUTTONS) ряды стоят на месте.
procedure UiTabsFixRows(C: TCustomTabControl; var Params: TCreateParams);
begin
  if Params.Style and TCS_MULTILINE <> 0 then
    Params.Style := Params.Style or TCS_BUTTONS;
end;

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
  inherited Destroy;
end;

procedure TUiPageControl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  UiTabsFixRows(Self, Params);
end;

procedure TUiPageControl.UMUiThemeChanged(var Message: TMessage);
begin
  Message.Result := 0;   // UiThemeChanged перерисует
end;

procedure TUiPageControl.WMPaint(var Message: TWMPaint);
begin
  if not UiTabsPaint(Self, Message, FHot) then
    inherited;
end;

procedure TUiPageControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  if UiThemeNativeFor(Self) then
    inherited
  else
    Message.Result := 1;
end;

procedure TUiPageControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  H: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  H := UiTabAt(Self, X, Y);
  if H <> FHot then
  begin
    FHot := H;
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
  inherited Destroy;
end;

procedure TUiTabControl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  UiTabsFixRows(Self, Params);
end;

procedure TUiTabControl.UMUiThemeChanged(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TUiTabControl.WMPaint(var Message: TWMPaint);
begin
  if not UiTabsPaint(Self, Message, FHot) then
    inherited;
end;

procedure TUiTabControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  if UiThemeNativeFor(Self) then
    inherited
  else
    Message.Result := 1;
end;

procedure TUiTabControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  H: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  H := UiTabAt(Self, X, Y);
  if H <> FHot then
  begin
    FHot := H;
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
  R: TRect;
  S: string;
  Fl: Cardinal;
  P: TStatusPanel;
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
      R := ClientRect;
      InflateRect(R, -4, 0);
      S := SimpleText;
      DrawText(Cv.Handle, PChar(S), Length(S), R,
               DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
      Exit;
    end;

    for I := 0 to Panels.Count - 1 do
    begin
      if SendMessage(Handle, SB_GETRECT, I, Integer(@R)) = 0 then
        Continue;
      P := Panels[I];
      if P.Style = psOwnerDraw then
      begin
        // Как у TStatusBar: холст панели - в OnDrawPanel
        Canvas.Handle := DC;
        try
          Canvas.Brush.Color := UiThemeColorFor(Self, 'Window.BG');
          Canvas.Font := Font;
          Canvas.Font.Color := UiThemeColorFor(Self, 'Window.Text');
          DrawPanel(P, R);
        finally
          Canvas.Handle := 0;
        end;
      end
      else
      begin
        S := P.Text;
        Fl := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
        case P.Alignment of
          taRightJustify: Fl := Fl or DT_RIGHT;
          taCenter: Fl := Fl or DT_CENTER;
        else
          Fl := Fl or DT_LEFT;
        end;
        InflateRect(R, -3, 0);
        DrawText(Cv.Handle, PChar(S), Length(S), R, Fl);
        InflateRect(R, 3, 0);
      end;
      // Черта справа от панели, кроме последней
      if I < Panels.Count - 1 then
      begin
        Cv.MoveTo(R.Right, R.Top + 2);
        Cv.LineTo(R.Right, R.Bottom - 2);
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
  PostMessage(Handle, UM_UIATTACHSCROLL, 0, 0);
end;

procedure TUiListView.UMUiAttachScroll(var Message: TMessage);
begin
  UiAttachScroll(Self);
end;

procedure TUiListView.UMUiThemeChanged(var Message: TMessage);
var
  H: HWND;
begin
  ApplyTheme;
  Invalidate;
  UiRedrawFrame(Self);
  // Заголовок колонок - отдельное окно: перерисовать и его
  if HandleAllocated then
  begin
    H := SendMessage(Handle, LVM_GETHEADER, 0, 0);
    if H <> 0 then
      InvalidateRect(H, nil, True);
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
  H: HWND;
begin
  if not UiThemeNativeFor(Self) and HandleAllocated and
     (Message.NMHdr^.code = NM_CUSTOMDRAW) then
  begin
    H := SendMessage(Handle, LVM_GETHEADER, 0, 0);
    if (H <> 0) and (Message.NMHdr^.hwndFrom = H) then
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
  R: TRect;
  I: Integer;
  S: string;
  Fl: Cardinal;
begin
  R := CD^.rc;
  I := Integer(CD^.dwItemSpec);
  Cv := TCanvas.Create;
  try
    Cv.Handle := CD^.hdc;
    if (CD^.uItemState and CDIS_SELECTED) <> 0 then
      Cv.Brush.Color := UiThemeColorFor(Self, 'Button.DownBG')
    else
      Cv.Brush.Color := UiThemeColorFor(Self, 'Button.BG');
    Cv.FillRect(R);
    Cv.Pen.Color := UiThemeColorFor(Self, 'Button.Border');
    Cv.MoveTo(R.Right - 1, R.Top);
    Cv.LineTo(R.Right - 1, R.Bottom);
    Cv.MoveTo(R.Left, R.Bottom - 1);
    Cv.LineTo(R.Right, R.Bottom - 1);
    if (I >= 0) and (I < Columns.Count) then
    begin
      S := Columns[I].Caption;
      Fl := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
      case Columns[I].Alignment of
        taRightJustify: Fl := Fl or DT_RIGHT;
        taCenter: Fl := Fl or DT_CENTER;
      else
        Fl := Fl or DT_LEFT;
      end;
      Cv.Font := Font;
      Cv.Font.Color := UiThemeColorFor(Self, 'Button.Text');
      Cv.Brush.Style := bsClear;
      InflateRect(R, -6, 0);
      DrawText(Cv.Handle, PChar(S), Length(S), R, Fl);
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
  H: HWND;
  N: Integer;
  R, C: TRect;
begin
  H := CD^.hdr.hwndFrom;
  Windows.GetClientRect(H, C);
  N := SendMessage(H, HDM_GETITEMCOUNT, 0, 0);
  R := C;
  if N > 0 then
  begin
    if SendMessage(H, HDM_GETITEMRECT, N - 1, Integer(@R)) = 0 then
      Exit;
    R.Left := R.Right;
    R.Right := C.Right;
    R.Top := C.Top;
    R.Bottom := C.Bottom;
  end;
  if R.Right <= R.Left then
    Exit;
  Cv := TCanvas.Create;
  try
    Cv.Handle := CD^.hdc;
    Cv.Brush.Color := UiThemeColorFor(Self, 'Button.BG');
    Cv.FillRect(R);
    Cv.Pen.Color := UiThemeColorFor(Self, 'Button.Border');
    Cv.MoveTo(R.Left, R.Bottom - 1);
    Cv.LineTo(R.Right, R.Bottom - 1);
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
function TUiUpDown.PartAt(X, Y: Integer): Integer;
begin
  Result := 0;
  if not PtInRect(ClientRect, Point(X, Y)) then
    Exit;
  if Orientation = udVertical then
  begin
    if Y < ClientHeight div 2 then
      Result := 1
    else
      Result := 2;
  end
  else
  begin
    if X < ClientWidth div 2 then
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

  procedure Part(const R: TRect; APart: Integer; ALow: Boolean);
  var
    Cx, Cy, S: Integer;
    Pts: array[0..2] of TPoint;
  begin
    if FDownPart = APart then
      Cv.Brush.Color := UiThemeColorFor(Self, 'Button.DownBG')
    else if (FHotPart = APart) and Enabled then
      Cv.Brush.Color := UiThemeColorFor(Self, 'Button.HotBG')
    else
      Cv.Brush.Color := UiThemeColorFor(Self, 'Button.BG');
    Cv.Pen.Color := UiThemeColorFor(Self, 'Button.Border');
    Cv.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
    Cx := (R.Left + R.Right) div 2;
    Cy := (R.Top + R.Bottom) div 2;
    if Orientation = udVertical then
      S := (R.Bottom - R.Top) div 4
    else
      S := (R.Right - R.Left) div 4;
    if S < 2 then
      S := 2;
    if Orientation = udVertical then
    begin
      if ALow then
      begin
        Pts[0] := Point(Cx, Cy - S div 2 - 1);
        Pts[1] := Point(Cx - S, Cy + S div 2);
        Pts[2] := Point(Cx + S, Cy + S div 2);
      end
      else
      begin
        Pts[0] := Point(Cx, Cy + S div 2 + 1);
        Pts[1] := Point(Cx - S, Cy - S div 2);
        Pts[2] := Point(Cx + S, Cy - S div 2);
      end;
    end
    else
    begin
      if ALow then
      begin
        Pts[0] := Point(Cx - S div 2 - 1, Cy);
        Pts[1] := Point(Cx + S div 2, Cy - S);
        Pts[2] := Point(Cx + S div 2, Cy + S);
      end
      else
      begin
        Pts[0] := Point(Cx + S div 2 + 1, Cy);
        Pts[1] := Point(Cx - S div 2, Cy - S);
        Pts[2] := Point(Cx - S div 2, Cy + S);
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
  P: Integer;
begin
  inherited;
  P := PartAt(Message.XPos, Message.YPos);
  if P <> FHotPart then
  begin
    FHotPart := P;
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
