unit UiMenus;

// ---------------------------------------------------------------------------
//  Своё меню по теме UiTheme: строка меню и выпадающие окна.
//
//    TUiMenuBar    - строка меню вверху окна по пунктам TMainMenu. В теме
//                    Light (при темах Windows) прячется, и у окна обычное
//                    меню Windows (Form.Menu); в темах Dark и Custom -
//                    наоборот: Form.Menu = nil, видна она. Переключается
//                    сама при смене темы.
//    TUiPopupMenu  - TPopupMenu, который в темах Dark и Custom показывает
//                    своё выпадающее окно вместо меню Windows.
//    TUiMainMenu   - TMainMenu, который в работающей программе сам ставит
//                    своему окну TUiMenuBar (для палитры и программ
//                    пользователя).
//
//  Пункты - обычные TMenuItem: подпись с &, ShortCut, Checked, RadioItem,
//  Enabled, Visible, Default, подменю, разделители. OnClick пункта с
//  подменю вызывается перед его раскрытием (как у меню Windows в VCL:
//  так строятся меню на лету). Значки пунктов: ImageIndex из Images меню
//  (или SubMenuImages владельца) и Bitmap пункта - в левой колонке;
//  отмеченный пункт со значком - значок в рамке, без значка - галочка.
//  OwnerDraw и колонки (Break) не поддерживаются.
//
//  Раскрытое меню ведёт свой цикл сообщений (как TrackPopupMenu): мышь
//  захвачена, клавиши разбирает меню - стрелки, Enter, Esc, буква из &.
//  Щелчок вне меню закрывает его. Выбранный пункт нажимается (Click) уже
//  после закрытия окон.
//
//  Цвета - роли темы Menu.BG, Menu.Text, Menu.HotBG, Menu.HotText,
//  Menu.Border, подпись выключенного пункта - OffText.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Menus,
  ImgList, UiTheme;

type
  TUiMenuBar = class(TCustomControl)
  private
    FMenu: TMainMenu;
    FHot: Integer;            // пункт под мышью (номер среди видимых)
    FOpen: Integer;           // пункт, чьё меню раскрыто; -1 - нет
    FShowAccel: Boolean;      // подчёркивать буквы (меню открыто клавишами)
    FForm: TCustomForm;       // окно, у которого мы вместо меню Windows
    FOldFormProc: TWndMethod;
    FFormHooked: Boolean;
    FOldShortCut: TShortCutEvent;
    procedure SetMenu(Value: TMainMenu);
    procedure HookForm;
    procedure UnhookForm;
    procedure FormWndProc(var Message: TMessage);
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
    procedure SetParent(AParent: TWinControl); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Видимые пункты верхнего уровня: сколько, пункт по номеру, место
    function  TopCount: Integer;
    function  TopItem(AIndex: Integer): TMenuItem;
    function  TopRect(AIndex: Integer): TRect;
    function  TopAt(X, Y: Integer): Integer;
    // Раскрыть меню пункта AIndex (номер среди видимых) - до закрытия
    procedure OpenItem(AIndex: Integer; AByKeyboard: Boolean);
    // По теме: своя строка (Dark, Custom) или меню Windows у окна (Light)
    procedure ApplyMode;
  published
    property Menu: TMainMenu read FMenu write SetMenu;
    property Align default alTop;
    property Font;
    property ParentFont default False;
    property Visible;
  end;

  TUiPopupMenu = class(TPopupMenu)
  public
    procedure Popup(X, Y: Integer); override;
  end;

  TUiMainMenu = class(TMainMenu)
  private
    FBar: TUiMenuBar;
  protected
    procedure Loaded; override;
  public
    // Строка меню, которую он поставил окну; nil - не ставил (Delphi,
    // конструктор форм IDE)
    property Bar: TUiMenuBar read FBar;
  end;

// Раскрыть меню пунктов AItems в точке X, Y (экран) и ждать выбора.
// ABar/ABarIndex - меню раскрыто из строки меню (стрелки влево-вправо
// переходят по её пунктам). Результат - выбранный пункт (его Click - за
// вызывающим) или nil.
function UiTrackMenu(AItems: TMenuItem; X, Y: Integer; ABar: TUiMenuBar;
  ABarIndex: Integer; AByKeyboard: Boolean): TMenuItem;

implementation

const
  CS_DROPSHADOW_ = $00020000;
  DT_HIDEPREFIX_ = $00100000;
  GutterWidth = 24;           // место под отметку слева
  ArrowWidth = 18;            // место под стрелку подменю справа
  SeparatorHeight = 8;

type
  TUiFormAcc = class(TCustomForm);

// ---------------------------------------------------------------------------
//  Окно одного уровня меню
// ---------------------------------------------------------------------------

type
  TUiMenuWindow = class(TCustomControl)
  public
    Items: TMenuItem;         // чьи пункты
    Selected: Integer;        // выделенный пункт (индекс в Items); -1 - нет
    OwnerWnd: HWND;
    ShowAccel: Boolean;
    RowTop, RowBottom: array of Integer;
    ItemHeight: Integer;
    CaptionWidth, ShortCutWidth: Integer;
    Gutter: Integer;              // левая колонка: отметка или значок
    IconWidth, IconHeight: Integer;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure Layout(var AWidth, AHeight: Integer);
    function  RowAt(const AScreen: TPoint): Integer;
    function  Selectable(AIndex: Integer): Boolean;
    function  NextSelectable(AFrom, AStep: Integer): Integer;
  end;

procedure TUiMenuWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP or WS_BORDER;
  Params.ExStyle := WS_EX_TOOLWINDOW;
  Params.WndParent := OwnerWnd;
  Params.WindowClass.style := Params.WindowClass.style or CS_DROPSHADOW_;
end;

procedure TUiMenuWindow.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

// Окно меню фокус не забирает
procedure TUiMenuWindow.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

function ItemText(AItem: TMenuItem): string;
begin
  Result := AItem.Caption;
end;

function ItemShortCut(AItem: TMenuItem): string;
begin
  if AItem.ShortCut <> 0 then
    Result := ShortCutToText(AItem.ShortCut)
  else
    Result := '';
end;

function IsSeparator(AItem: TMenuItem): Boolean;
begin
  Result := AItem.Caption = cLineCaption;
end;

// Список значков пункта: SubMenuImages владельца, иначе Images меню
function ItemImages(AItem: TMenuItem): TCustomImageList;
begin
  Result := nil;
  if (AItem.Parent <> nil) and (AItem.Parent.SubMenuImages <> nil) then
    Result := AItem.Parent.SubMenuImages
  else if AItem.GetParentMenu <> nil then
    Result := AItem.GetParentMenu.Images;
end;

// Размер значка пункта; 0 - значка нет
procedure ItemIconSize(AItem: TMenuItem; var W, H: Integer);
var
  Images: TCustomImageList;
begin
  W := 0;
  H := 0;
  Images := ItemImages(AItem);
  if (Images <> nil) and (AItem.ImageIndex >= 0) and
     (AItem.ImageIndex < Images.Count) then
  begin
    W := Images.Width;
    H := Images.Height;
  end
  else if not AItem.Bitmap.Empty then
  begin
    W := AItem.Bitmap.Width;
    H := AItem.Bitmap.Height;
  end;
end;

// Размер окна и места строк
procedure TUiMenuWindow.Layout(var AWidth, AHeight: Integer);
var
  Index, Y, W: Integer;
  Item: TMenuItem;
  Measure: TRect;
begin
  Canvas.Font := Font;
  // Значки: самый большой задаёт левую колонку и высоту строк
  IconWidth := 0;
  IconHeight := 0;
  for Index := 0 to Items.Count - 1 do
    if Items[Index].Visible and not IsSeparator(Items[Index]) then
    begin
      ItemIconSize(Items[Index], W, Y);
      if W > IconWidth then
        IconWidth := W;
      if Y > IconHeight then
        IconHeight := Y;
    end;
  Gutter := GutterWidth;
  if IconWidth + 8 > Gutter then
    Gutter := IconWidth + 8;
  ItemHeight := Canvas.TextHeight('Wg') + 8;
  if ItemHeight < IconHeight + 6 then
    ItemHeight := IconHeight + 6;
  if ItemHeight < 22 then
    ItemHeight := 22;
  CaptionWidth := 60;
  ShortCutWidth := 0;
  SetLength(RowTop, Items.Count);
  SetLength(RowBottom, Items.Count);
  Y := 2;
  for Index := 0 to Items.Count - 1 do
  begin
    Item := Items[Index];
    RowTop[Index] := Y;
    if not Item.Visible then
    begin
      RowBottom[Index] := Y;
      Continue;
    end;
    if IsSeparator(Item) then
      Inc(Y, SeparatorHeight)
    else
    begin
      if Item.Default then
        Canvas.Font.Style := [fsBold]
      else
        Canvas.Font.Style := [];
      Measure := Rect(0, 0, 0, 0);
      DrawText(Canvas.Handle, PChar(ItemText(Item)), -1, Measure,
               DT_CALCRECT or DT_SINGLELINE);
      W := Measure.Right;
      if W > CaptionWidth then
        CaptionWidth := W;
      W := Canvas.TextWidth(ItemShortCut(Item));
      if W > ShortCutWidth then
        ShortCutWidth := W;
      Inc(Y, ItemHeight);
    end;
    RowBottom[Index] := Y;
  end;
  Canvas.Font.Style := [];
  AWidth := Gutter + CaptionWidth + 24 + ShortCutWidth + ArrowWidth + 2;
  AHeight := Y + 2 + 2;       // + рамка
end;

function TUiMenuWindow.Selectable(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Items.Count) and
            Items[AIndex].Visible and not IsSeparator(Items[AIndex]);
end;

function TUiMenuWindow.NextSelectable(AFrom, AStep: Integer): Integer;
var
  Index, Count: Integer;
begin
  Result := -1;
  Count := Items.Count;
  if Count = 0 then
    Exit;
  Index := AFrom;
  repeat
    Index := Index + AStep;
    if Index < 0 then
      Index := Count - 1
    else if Index >= Count then
      Index := 0;
    if Selectable(Index) then
    begin
      Result := Index;
      Exit;
    end;
  until Index = AFrom;
  if Selectable(AFrom) then
    Result := AFrom;
end;

function TUiMenuWindow.RowAt(const AScreen: TPoint): Integer;
var
  Local: TPoint;
  Index: Integer;
begin
  Result := -1;
  Local := ScreenToClient(AScreen);
  if (Local.X < 0) or (Local.X >= ClientWidth) then
    Exit;
  for Index := 0 to Items.Count - 1 do
    if (Local.Y >= RowTop[Index]) and (Local.Y < RowBottom[Index]) then
    begin
      if Selectable(Index) then
        Result := Index;
      Exit;
    end;
end;

procedure TUiMenuWindow.Paint;
var
  Index, Cx, Cy, IconW, IconH, IconX, IconY: Integer;
  Item: TMenuItem;
  Row, TextRect: TRect;
  Hot, Enabled: Boolean;
  Fore: TColor;
  Flags: Cardinal;
  S: string;
  Images: TCustomImageList;
  Icon: TBitmap;
begin
  Canvas.Font := Font;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := UiThemeColor('Menu.BG');
  Canvas.FillRect(ClientRect);
  for Index := 0 to Items.Count - 1 do
  begin
    Item := Items[Index];
    if not Item.Visible or (RowBottom[Index] <= RowTop[Index]) then
      Continue;
    Row := Rect(2, RowTop[Index], ClientWidth - 2, RowBottom[Index]);
    if IsSeparator(Item) then
    begin
      Canvas.Pen.Color := UiThemeColor('Menu.Border');
      Cy := (Row.Top + Row.Bottom) div 2;
      Canvas.MoveTo(Row.Left + Gutter, Cy);
      Canvas.LineTo(Row.Right - 2, Cy);
      Continue;
    end;
    Hot := Index = Selected;
    Enabled := Item.Enabled;
    if Hot then
    begin
      Canvas.Brush.Color := UiThemeColor('Menu.HotBG');
      Canvas.FillRect(Row);
    end;
    if not Enabled then
      Fore := UiThemeColor('OffText')
    else if Hot then
      Fore := UiThemeColor('Menu.HotText')
    else
      Fore := UiThemeColor('Menu.Text');

    // Значок; у отмеченного - в рамке
    ItemIconSize(Item, IconW, IconH);
    if IconW > 0 then
    begin
      IconX := Row.Left + (Gutter - IconW) div 2;
      IconY := (Row.Top + Row.Bottom - IconH) div 2;
      if Item.Checked then
      begin
        Canvas.Brush.Color := UiThemeColor('Menu.HotText');
        Canvas.FrameRect(Rect(IconX - 2, IconY - 2, IconX + IconW + 2,
                              IconY + IconH + 2));
      end;
      Images := ItemImages(Item);
      if (Images <> nil) and (Item.ImageIndex >= 0) and
         (Item.ImageIndex < Images.Count) then
        Images.Draw(Canvas, IconX, IconY, Item.ImageIndex, Enabled)
      else
      begin
        // Bitmap пункта - копией: Transparent у самого пункта не трогаем
        Icon := TBitmap.Create;
        try
          Icon.Assign(Item.Bitmap);
          Icon.Transparent := True;
          Canvas.Draw(IconX, IconY, Icon);
        finally
          Icon.Free;
        end;
      end;
    end
    // Отметка без значка: галочка или точка (RadioItem)
    else if Item.Checked then
    begin
      Cx := Row.Left + Gutter div 2;
      Cy := (Row.Top + Row.Bottom) div 2;
      Canvas.Pen.Color := Fore;
      Canvas.Brush.Color := Fore;
      if Item.RadioItem then
        Canvas.Ellipse(Cx - 3, Cy - 3, Cx + 4, Cy + 4)
      else
      begin
        Canvas.Pen.Width := 2;
        Canvas.PolyLine([Point(Cx - 4, Cy), Point(Cx - 1, Cy + 3),
                         Point(Cx + 4, Cy - 3)]);
        Canvas.Pen.Width := 1;
      end;
    end;

    // Подпись и клавиша
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := Fore;
    if Item.Default then
      Canvas.Font.Style := [fsBold]
    else
      Canvas.Font.Style := [];
    TextRect := Rect(Row.Left + Gutter, Row.Top,
                     Row.Left + Gutter + CaptionWidth + 4, Row.Bottom);
    Flags := DT_SINGLELINE or DT_VCENTER or DT_LEFT;
    if not ShowAccel then
      Flags := Flags or DT_HIDEPREFIX_;
    S := ItemText(Item);
    DrawText(Canvas.Handle, PChar(S), Length(S), TextRect, Flags);
    S := ItemShortCut(Item);
    if S <> '' then
    begin
      TextRect := Rect(Row.Right - ArrowWidth - ShortCutWidth, Row.Top,
                       Row.Right - ArrowWidth, Row.Bottom);
      DrawText(Canvas.Handle, PChar(S), Length(S), TextRect,
               DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_NOPREFIX);
    end;
    Canvas.Font.Style := [];
    Canvas.Brush.Style := bsSolid;

    // Стрелка подменю
    if Item.Count > 0 then
    begin
      Cx := Row.Right - ArrowWidth div 2;
      Cy := (Row.Top + Row.Bottom) div 2;
      Canvas.Pen.Color := Fore;
      Canvas.Brush.Color := Fore;
      Canvas.Polygon([Point(Cx - 2, Cy - 4), Point(Cx + 2, Cy),
                      Point(Cx - 2, Cy + 4)]);
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Цикл раскрытого меню
// ---------------------------------------------------------------------------

type
  TUiMenuTracker = class
  public
    Levels: TList;            // TUiMenuWindow, от корня к глубокому
    Bar: TUiMenuBar;
    BarIndex: Integer;
    OwnerWnd: HWND;
    ShowAccel: Boolean;
    Chosen: TMenuItem;
    Done: Boolean;
    constructor Create;
    destructor Destroy; override;
    function  Deepest: TUiMenuWindow;
    procedure OpenLevel(AItems: TMenuItem; X, Y: Integer;
                        AFromRight: Integer; ASelectFirst: Boolean);
    procedure CloseAfter(ALevel: Integer);
    procedure OpenSub(ALevel: Integer; ASelectFirst: Boolean);
    procedure OpenBarItem(AIndex: Integer; ASelectFirst: Boolean);
    function  LevelAt(const AScreen: TPoint): Integer;
    procedure Select(ALevel, AIndex: Integer);
    procedure Execute(AItem: TMenuItem);
    procedure MouseMoveAt(const AScreen: TPoint);
    procedure MouseDownAt(const AScreen: TPoint);
    procedure MouseUpAt(const AScreen: TPoint);
    procedure KeyDown(AKey: Word);
    procedure CharKey(ACh: Char);
  end;

constructor TUiMenuTracker.Create;
begin
  inherited Create;
  Levels := TList.Create;
end;

destructor TUiMenuTracker.Destroy;
begin
  CloseAfter(-1);
  Levels.Free;
  inherited Destroy;
end;

function TUiMenuTracker.Deepest: TUiMenuWindow;
begin
  if Levels.Count > 0 then
    Result := TUiMenuWindow(Levels[Levels.Count - 1])
  else
    Result := nil;
end;

// Окно пунктов AItems в X, Y. AFromRight >= 0 - это подменю: если справа
// не влезает, окно встаёт слева от родителя (AFromRight - его левый край).
procedure TUiMenuTracker.OpenLevel(AItems: TMenuItem; X, Y: Integer;
  AFromRight: Integer; ASelectFirst: Boolean);
var
  Win: TUiMenuWindow;
  W, H: Integer;
  Work: TRect;
begin
  // Меню, которые строятся на лету, заполняются в OnClick пункта с
  // подменю - как у меню Windows в VCL
  if (Levels.Count > 0) and Assigned(AItems.OnClick) then
    AItems.Click;
  if AItems.Count = 0 then
    Exit;

  Win := TUiMenuWindow.Create(nil);
  Win.Items := AItems;
  Win.OwnerWnd := OwnerWnd;
  Win.ShowAccel := ShowAccel;
  Win.Selected := -1;
  Win.Font := Screen.MenuFont;
  Win.HandleNeeded;
  Win.Layout(W, H);

  Work := Screen.WorkAreaRect;
  if X + W > Work.Right then
  begin
    if AFromRight >= 0 then
      X := AFromRight - W + 2
    else
      X := Work.Right - W;
  end;
  if X < Work.Left then
    X := Work.Left;
  if Y + H > Work.Bottom then
    Y := Work.Bottom - H;
  if Y < Work.Top then
    Y := Work.Top;
  SetWindowPos(Win.Handle, HWND_TOP, X, Y, W, H,
               SWP_NOACTIVATE or SWP_SHOWWINDOW);
  Levels.Add(Win);
  if ASelectFirst then
    Win.Selected := Win.NextSelectable(-1, 1);
  Win.Invalidate;
end;

// Закрыть уровни глубже ALevel (-1 - все)
procedure TUiMenuTracker.CloseAfter(ALevel: Integer);
var
  Win: TUiMenuWindow;
begin
  while Levels.Count - 1 > ALevel do
  begin
    Win := TUiMenuWindow(Levels[Levels.Count - 1]);
    Levels.Delete(Levels.Count - 1);
    Win.Free;
  end;
end;

// Подменю выделенного пункта уровня ALevel
procedure TUiMenuTracker.OpenSub(ALevel: Integer; ASelectFirst: Boolean);
var
  Win: TUiMenuWindow;
  Item: TMenuItem;
  Origin: TPoint;
begin
  Win := TUiMenuWindow(Levels[ALevel]);
  if Win.Selected < 0 then
    Exit;
  Item := Win.Items[Win.Selected];
  if not Item.Enabled or (Item.Count = 0) then
    Exit;
  CloseAfter(ALevel);
  Origin := Win.ClientToScreen(Point(Win.ClientWidth, Win.RowTop[Win.Selected]));
  OpenLevel(Item, Origin.X, Origin.Y - 3, Win.Left, ASelectFirst);
end;

// Меню другого пункта строки меню
procedure TUiMenuTracker.OpenBarItem(AIndex: Integer; ASelectFirst: Boolean);
var
  Item: TMenuItem;
  R: TRect;
  Origin: TPoint;
begin
  if (Bar = nil) or (AIndex < 0) or (AIndex >= Bar.TopCount) then
    Exit;
  CloseAfter(-1);
  BarIndex := AIndex;
  Bar.FOpen := AIndex;
  Bar.Invalidate;
  Item := Bar.TopItem(AIndex);
  if Assigned(Item.OnClick) then
    Item.Click;
  R := Bar.TopRect(AIndex);
  Origin := Bar.ClientToScreen(Point(R.Left, R.Bottom));
  // OnClick пункта уже вызван: у корня (Levels пуст) OpenLevel его второй
  // раз не вызывает
  if Item.Count > 0 then
    OpenLevel(Item, Origin.X, Origin.Y, -1, ASelectFirst);
end;

function TUiMenuTracker.LevelAt(const AScreen: TPoint): Integer;
var
  Index: Integer;
  Win: TUiMenuWindow;
begin
  Result := -1;
  for Index := Levels.Count - 1 downto 0 do
  begin
    Win := TUiMenuWindow(Levels[Index]);
    if PtInRect(Win.BoundsRect, AScreen) then
    begin
      Result := Index;
      Exit;
    end;
  end;
end;

procedure TUiMenuTracker.Select(ALevel, AIndex: Integer);
var
  Win: TUiMenuWindow;
begin
  Win := TUiMenuWindow(Levels[ALevel]);
  if Win.Selected <> AIndex then
  begin
    Win.Selected := AIndex;
    Win.Invalidate;
  end;
end;

procedure TUiMenuTracker.Execute(AItem: TMenuItem);
begin
  if (AItem <> nil) and AItem.Enabled and (AItem.Count = 0) then
  begin
    Chosen := AItem;
    Done := True;
  end;
end;

procedure TUiMenuTracker.MouseMoveAt(const AScreen: TPoint);
var
  Level, Row, BarItem: Integer;
  Win: TUiMenuWindow;
  Local: TPoint;
begin
  Level := LevelAt(AScreen);
  if Level >= 0 then
  begin
    Win := TUiMenuWindow(Levels[Level]);
    Row := Win.RowAt(AScreen);
    if (Row >= 0) and (Row <> Win.Selected) then
    begin
      Select(Level, Row);
      CloseAfter(Level);
      if Win.Items[Row].Enabled and (Win.Items[Row].Count > 0) then
        OpenSub(Level, False);
    end;
    Exit;
  end;
  // Над строкой меню - другой её пункт
  if Bar <> nil then
  begin
    Local := Bar.ScreenToClient(AScreen);
    BarItem := Bar.TopAt(Local.X, Local.Y);
    if (BarItem >= 0) and (BarItem <> BarIndex) then
      OpenBarItem(BarItem, False);
  end;
end;

procedure TUiMenuTracker.MouseDownAt(const AScreen: TPoint);
var
  Local: TPoint;
  BarItem: Integer;
begin
  if LevelAt(AScreen) >= 0 then
    Exit;                     // выбор - по отпусканию
  if Bar <> nil then
  begin
    Local := Bar.ScreenToClient(AScreen);
    BarItem := Bar.TopAt(Local.X, Local.Y);
    if BarItem = BarIndex then
    begin
      Done := True;           // тот же пункт строки - закрыть
      Exit;
    end;
    if BarItem >= 0 then
    begin
      OpenBarItem(BarItem, False);
      Exit;
    end;
  end;
  Done := True;               // мимо меню - закрыть
end;

procedure TUiMenuTracker.MouseUpAt(const AScreen: TPoint);
var
  Level, Row: Integer;
  Win: TUiMenuWindow;
begin
  Level := LevelAt(AScreen);
  if Level < 0 then
    Exit;
  Win := TUiMenuWindow(Levels[Level]);
  Row := Win.RowAt(AScreen);
  if Row >= 0 then
    Execute(Win.Items[Row]);
end;

procedure TUiMenuTracker.KeyDown(AKey: Word);
var
  Win: TUiMenuWindow;
  Level, Next: Integer;
  Item: TMenuItem;
begin
  Win := Deepest;
  if Win = nil then
  begin
    Done := True;
    Exit;
  end;
  Level := Levels.Count - 1;
  case AKey of
    VK_DOWN, VK_UP:
      begin
        if AKey = VK_DOWN then
          Next := Win.NextSelectable(Win.Selected, 1)
        else
          Next := Win.NextSelectable(Win.Selected, -1);
        if Next >= 0 then
          Select(Level, Next);
      end;
    VK_HOME:
      Select(Level, Win.NextSelectable(-1, 1));
    VK_END:
      Select(Level, Win.NextSelectable(Win.Items.Count, -1));
    VK_RIGHT:
      begin
        Item := nil;
        if Win.Selected >= 0 then
          Item := Win.Items[Win.Selected];
        if (Item <> nil) and Item.Enabled and (Item.Count > 0) then
          OpenSub(Level, True)
        else if Bar <> nil then
          OpenBarItem((BarIndex + 1) mod Bar.TopCount, True);
      end;
    VK_LEFT:
      if Level > 0 then
        CloseAfter(Level - 1)
      else if Bar <> nil then
        OpenBarItem((BarIndex + Bar.TopCount - 1) mod Bar.TopCount, True);
    VK_RETURN, VK_SPACE:
      if Win.Selected >= 0 then
      begin
        Item := Win.Items[Win.Selected];
        if Item.Enabled and (Item.Count > 0) then
          OpenSub(Level, True)
        else
          Execute(Item);
      end;
    VK_ESCAPE:
      if Level > 0 then
        CloseAfter(Level - 1)
      else
        Done := True;
    VK_MENU, VK_F10:
      Done := True;
  end;
end;

// Буква из & - пункт с этой буквой: подменю раскрыть, иначе нажать
procedure TUiMenuTracker.CharKey(ACh: Char);
var
  Win: TUiMenuWindow;
  Index, Level: Integer;
  Item: TMenuItem;
begin
  Win := Deepest;
  if Win = nil then
    Exit;
  Level := Levels.Count - 1;
  for Index := 0 to Win.Items.Count - 1 do
  begin
    Item := Win.Items[Index];
    if Win.Selectable(Index) and IsAccel(Ord(ACh), Item.Caption) then
    begin
      Select(Level, Index);
      if Item.Enabled and (Item.Count > 0) then
        OpenSub(Level, True)
      else
        Execute(Item);
      Exit;
    end;
  end;
end;

function UiTrackMenu(AItems: TMenuItem; X, Y: Integer; ABar: TUiMenuBar;
  ABarIndex: Integer; AByKeyboard: Boolean): TMenuItem;
var
  Tracker: TUiMenuTracker;
  Msg: TMsg;
  CaptureWnd: HWND;
begin
  Result := nil;
  Tracker := TUiMenuTracker.Create;
  try
    Tracker.Bar := ABar;
    Tracker.BarIndex := ABarIndex;
    Tracker.ShowAccel := AByKeyboard;
    Tracker.OwnerWnd := GetActiveWindow;
    if Tracker.OwnerWnd = 0 then
      Tracker.OwnerWnd := Application.Handle;
    if ABar <> nil then
      Tracker.OpenBarItem(ABarIndex, AByKeyboard)
    else
      Tracker.OpenLevel(AItems, X, Y, -1, AByKeyboard);
    if Tracker.Levels.Count = 0 then
      Exit;
    // Мышь - у корневого окна меню: сообщения мыши приходят и из-за его
    // пределов
    CaptureWnd := TUiMenuWindow(Tracker.Levels[0]).Handle;
    SetCapture(CaptureWnd);

    while not Tracker.Done do
    begin
      if not GetMessage(Msg, 0, 0, 0) then
      begin
        PostQuitMessage(Msg.wParam);
        Break;
      end;
      case Msg.message of
        WM_MOUSEMOVE, WM_NCMOUSEMOVE:
          Tracker.MouseMoveAt(Msg.pt);
        WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN,
        WM_NCLBUTTONDOWN, WM_NCRBUTTONDOWN:
          Tracker.MouseDownAt(Msg.pt);
        WM_LBUTTONUP, WM_RBUTTONUP:
          Tracker.MouseUpAt(Msg.pt);
        WM_LBUTTONDBLCLK, WM_RBUTTONDBLCLK, WM_MBUTTONUP:
          ;
        WM_KEYDOWN, WM_SYSKEYDOWN:
          Tracker.KeyDown(Msg.wParam);
        WM_CHAR, WM_SYSCHAR:
          Tracker.CharKey(Char(Msg.wParam));
        WM_KEYUP, WM_SYSKEYUP:
          ;
      else
        TranslateMessage(Msg);
        DispatchMessage(Msg);
      end;
      if (Tracker.Levels.Count = 0) or Application.Terminated then
        Break;
      // Корневое окно сменилось (другой пункт строки меню) - мышь ему
      if TUiMenuWindow(Tracker.Levels[0]).Handle <> CaptureWnd then
      begin
        CaptureWnd := TUiMenuWindow(Tracker.Levels[0]).Handle;
        SetCapture(CaptureWnd);
      end
      // Мышь забрал кто-то другой (переключили программу) - закрыть
      else if GetCapture <> CaptureWnd then
        Break;
    end;
    Result := Tracker.Chosen;
  finally
    ReleaseCapture;
    if ABar <> nil then
    begin
      ABar.FOpen := -1;
      ABar.FShowAccel := False;
      ABar.Invalidate;
    end;
    Tracker.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  TUiMenuBar
// ---------------------------------------------------------------------------

constructor TUiMenuBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque] - [csAcceptsControls];
  Align := alTop;
  ParentFont := False;
  Font := Screen.MenuFont;
  Height := Screen.MenuFont.Size + 16;
  FHot := -1;
  FOpen := -1;
  TabStop := False;
  UiThemeAddClient(Self);
end;

destructor TUiMenuBar.Destroy;
begin
  UiThemeRemoveClient(Self);
  UnhookForm;
  inherited Destroy;
end;

procedure TUiMenuBar.SetMenu(Value: TMainMenu);
begin
  if FMenu = Value then
    Exit;
  if FMenu <> nil then
    FMenu.RemoveFreeNotification(Self);
  FMenu := Value;
  if FMenu <> nil then
    FMenu.FreeNotification(Self);
  ApplyMode;
  Invalidate;
end;

procedure TUiMenuBar.Notification(AComponent: TComponent;
                                  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FMenu) then
    FMenu := nil;
end;

procedure TUiMenuBar.SetParent(AParent: TWinControl);
begin
  UnhookForm;
  inherited SetParent(AParent);
  if (AParent <> nil) and not (csDestroying in ComponentState) then
    ApplyMode;
end;

// Окно: Alt, F10, Alt+буква (без меню Windows их некому разобрать) и
// горячие клавиши пунктов (ShortCut) - через нас
procedure TUiMenuBar.HookForm;
begin
  if FFormHooked or (Parent = nil) then
    Exit;
  FForm := GetParentForm(Self);
  if FForm = nil then
    Exit;
  FOldFormProc := FForm.WindowProc;
  FForm.WindowProc := FormWndProc;
  FOldShortCut := TUiFormAcc(FForm).OnShortCut;
  TUiFormAcc(FForm).OnShortCut := FormShortCut;
  FFormHooked := True;
end;

procedure TUiMenuBar.UnhookForm;
var
  Current: TWndMethod;
  CurrentShortCut: TShortCutEvent;
begin
  if not FFormHooked or (FForm = nil) then
    Exit;
  // Вернуть прежнее, только если после нас его никто не менял
  Current := FForm.WindowProc;
  if (TMethod(Current).Code = @TUiMenuBar.FormWndProc) and
     (TMethod(Current).Data = Self) then
    FForm.WindowProc := FOldFormProc;
  CurrentShortCut := TUiFormAcc(FForm).OnShortCut;
  if (TMethod(CurrentShortCut).Code = @TUiMenuBar.FormShortCut) and
     (TMethod(CurrentShortCut).Data = Self) then
    TUiFormAcc(FForm).OnShortCut := FOldShortCut;
  FFormHooked := False;
end;

procedure TUiMenuBar.FormWndProc(var Message: TMessage);
var
  Ch: Char;
  Index: Integer;
begin
  if Visible and (FMenu <> nil) and (Message.Msg = WM_SYSCOMMAND) and
     ((Message.WParam and $FFF0) = SC_KEYMENU) then
  begin
    Ch := Char(Message.LParam and $FF);
    if Ch = #0 then
    begin
      // Alt или F10 - первый пункт
      if TopCount > 0 then
        OpenItem(0, True);
      Message.Result := 0;
      Exit;
    end;
    if Ch <> ' ' then           // Alt+пробел - системное меню окна
    begin
      for Index := 0 to TopCount - 1 do
        if IsAccel(Ord(Ch), TopItem(Index).Caption) then
        begin
          OpenItem(Index, True);
          Message.Result := 0;
          Exit;
        end;
    end;
  end;
  FOldFormProc(Message);
end;

procedure TUiMenuBar.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
begin
  if Assigned(FOldShortCut) then
    FOldShortCut(Msg, Handled);
  // Меню Windows у окна нет - горячие клавиши пунктов разбираем сами
  if not Handled and Visible and (FMenu <> nil) and (FForm <> nil) and
     (TUiFormAcc(FForm).Menu = nil) then
    Handled := FMenu.IsShortCut(Msg);
end;

procedure TUiMenuBar.ApplyMode;
var
  Native: Boolean;
begin
  if (Parent = nil) or (csDestroying in ComponentState) then
    Exit;
  HookForm;
  if FForm = nil then
    Exit;
  Native := UiThemeNativeFor(Self) or (FMenu = nil);
  if Native then
  begin
    if (FMenu <> nil) and (TUiFormAcc(FForm).Menu <> FMenu) then
      TUiFormAcc(FForm).Menu := FMenu;
    Visible := False;
  end
  else
  begin
    if TUiFormAcc(FForm).Menu = FMenu then
      TUiFormAcc(FForm).Menu := nil;
    Visible := True;
    // Строка меню - выше остальных элементов с alTop
    Top := -1;
  end;
end;

procedure TUiMenuBar.UMUiThemeChanged(var Message: TMessage);
begin
  ApplyMode;
  Invalidate;
  Message.Result := 1;
end;

function TUiMenuBar.TopCount: Integer;
var
  Index: Integer;
begin
  Result := 0;
  if FMenu <> nil then
    for Index := 0 to FMenu.Items.Count - 1 do
      if FMenu.Items[Index].Visible then
        Inc(Result);
end;

function TUiMenuBar.TopItem(AIndex: Integer): TMenuItem;
var
  Index, Pos: Integer;
begin
  Result := nil;
  if FMenu = nil then
    Exit;
  Pos := 0;
  for Index := 0 to FMenu.Items.Count - 1 do
    if FMenu.Items[Index].Visible then
    begin
      if Pos = AIndex then
      begin
        Result := FMenu.Items[Index];
        Exit;
      end;
      Inc(Pos);
    end;
end;

function TUiMenuBar.TopRect(AIndex: Integer): TRect;
var
  Index, X, W: Integer;
  Measure: TRect;
  S: string;
begin
  Result := Rect(0, 0, 0, 0);
  Canvas.Font := Font;
  X := 2;
  for Index := 0 to TopCount - 1 do
  begin
    S := TopItem(Index).Caption;
    Measure := Rect(0, 0, 0, 0);
    DrawText(Canvas.Handle, PChar(S), -1, Measure, DT_CALCRECT or DT_SINGLELINE);
    W := Measure.Right + 16;
    if Index = AIndex then
    begin
      Result := Rect(X, 0, X + W, ClientHeight);
      Exit;
    end;
    Inc(X, W);
  end;
end;

function TUiMenuBar.TopAt(X, Y: Integer): Integer;
var
  Index: Integer;
begin
  Result := -1;
  if (Y < 0) or (Y >= ClientHeight) then
    Exit;
  for Index := 0 to TopCount - 1 do
    if PtInRect(TopRect(Index), Point(X, Y)) then
    begin
      Result := Index;
      Exit;
    end;
end;

procedure TUiMenuBar.OpenItem(AIndex: Integer; AByKeyboard: Boolean);
var
  Chosen: TMenuItem;
begin
  if (AIndex < 0) or (AIndex >= TopCount) then
    Exit;
  FShowAccel := AByKeyboard;
  Chosen := UiTrackMenu(nil, 0, 0, Self, AIndex, AByKeyboard);
  if Chosen <> nil then
    Chosen.Click;
end;

procedure TUiMenuBar.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TUiMenuBar.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TUiMenuBar.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot <> -1 then
  begin
    FHot := -1;
    Invalidate;
  end;
end;

procedure TUiMenuBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Hot: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  Hot := TopAt(X, Y);
  if Hot <> FHot then
  begin
    FHot := Hot;
    Invalidate;
  end;
end;

procedure TUiMenuBar.MouseDown(Button: TMouseButton; Shift: TShiftState;
                               X, Y: Integer);
var
  Index: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  Index := TopAt(X, Y);
  if Index < 0 then
    Exit;
  // Пункт без подменю - сразу его OnClick, как у меню Windows
  if TopItem(Index).Count = 0 then
  begin
    if TopItem(Index).Enabled then
      TopItem(Index).Click;
    Exit;
  end;
  OpenItem(Index, False);
end;

procedure TUiMenuBar.Paint;
var
  Index: Integer;
  R: TRect;
  Item: TMenuItem;
  S: string;
  Flags: Cardinal;
begin
  Canvas.Font := Font;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := UiThemeColor('Menu.BG');
  Canvas.FillRect(ClientRect);
  for Index := 0 to TopCount - 1 do
  begin
    Item := TopItem(Index);
    R := TopRect(Index);
    if ((Index = FOpen) or (Index = FHot)) and Item.Enabled then
    begin
      Canvas.Brush.Color := UiThemeColor('Menu.HotBG');
      Canvas.FillRect(R);
      Canvas.Font.Color := UiThemeColor('Menu.HotText');
    end
    else if Item.Enabled then
      Canvas.Font.Color := UiThemeColor('Menu.Text')
    else
      Canvas.Font.Color := UiThemeColor('OffText');
    Flags := DT_SINGLELINE or DT_VCENTER or DT_CENTER;
    if not FShowAccel then
      Flags := Flags or DT_HIDEPREFIX_;
    S := Item.Caption;
    Canvas.Brush.Style := bsClear;
    DrawText(Canvas.Handle, PChar(S), Length(S), R, Flags);
    Canvas.Brush.Style := bsSolid;
  end;
  // Черта снизу - граница с тем, что под меню
  Canvas.Pen.Color := UiThemeColor('Menu.Border');
  Canvas.MoveTo(0, ClientHeight - 1);
  Canvas.LineTo(ClientWidth, ClientHeight - 1);
end;

// ---------------------------------------------------------------------------
//  TUiPopupMenu, TUiMainMenu
// ---------------------------------------------------------------------------

procedure TUiPopupMenu.Popup(X, Y: Integer);
var
  Chosen: TMenuItem;
  Probe: TControl;
begin
  // Тема Light при темах Windows - меню Windows. Тема - по окну, на
  // котором меню вызвали, иначе общая.
  Probe := nil;
  if PopupComponent is TControl then
    Probe := TControl(PopupComponent);
  if UiThemeNativeFor(Probe) then
  begin
    inherited Popup(X, Y);
    Exit;
  end;
  DoPopup(Self);
  Chosen := UiTrackMenu(Items, X, Y, nil, -1, False);
  if Chosen <> nil then
    Chosen.Click;
end;

procedure TUiMainMenu.Loaded;
begin
  inherited Loaded;
  // В работающей программе - своя строка меню своему окну; в Delphi и в
  // конструкторе форм IDE - обычное меню
  if (csDesigning in ComponentState) or UiThemeHostLocked or
     not (Owner is TCustomForm) then
    Exit;
  FBar := TUiMenuBar.Create(Owner);
  FBar.Parent := TWinControl(Owner);
  FBar.Menu := Self;
end;

initialization
  if GetClass(TUiMenuBar.ClassName) = nil then
    RegisterClass(TUiMenuBar);
  if GetClass(TUiPopupMenu.ClassName) = nil then
    RegisterClass(TUiPopupMenu);
  if GetClass(TUiMainMenu.ClassName) = nil then
    RegisterClass(TUiMainMenu);
end.
