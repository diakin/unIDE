unit UiScroll;

// ---------------------------------------------------------------------------
//  Полоса прокрутки, которую целиком рисует сама программа
//
//  Стандартную полосу (TScrollBar) рисует Windows, и цвет ей не задать: в
//  IDE Dark она остаётся светлой. Попытки перехватывать отрисовку Windows-
//  элементов приводили к сбоям перерисовки окон. Эта полоса - обычный
//  TCustomControl: всё рисует его Paint, мышь - его MouseDown/Move/Up,
//  Windows здесь ничего не рисует.
//
//  Снаружи похожа на TScrollBar: Kind, Min, Max, Position, SmallChange,
//  LargeChange, OnChange. Позиция - полное Integer, без ограничения 32767,
//  как у TWMScroll.Pos, поэтому OnScroll с GetScrollInfo не нужен.
//
//  Части: стрелка в начале, дорожка, ползунок, стрелка в конце. Щелчок по
//  стрелке - шаг SmallChange, по дорожке - страница LargeChange в сторону
//  мыши; при удержании повторяется (сначала через 350 мс, потом каждые
//  50 мс; по дорожке - пока ползунок не дойдёт до мыши). Ползунок тянется;
//  на длинной прокрутке он не короче MinThumb.
//  Цвета - по теме (UiTheme, роли Scroll.*), пока владелец не задал свои
//  (SetColors).
//
//  TUiListScroll - такие же полосы вместо полос Windows у элемента: списка,
//  дерева, таблицы, лога, поля с полосами. Полосы Windows элемент рисует
//  в служебной области своего окна, и выключить их нельзя: элемент
//  возвращает их сам. Поэтому наши ставятся поверх них - соседями в том же
//  родителе, выше по порядку окон, ровно на их место; когда видны обе,
//  квадратик между ними закрывает TUiScrollCorner. В отрисовку и сообщения
//  элемента ничего не встраивается: положение и диапазон читаются у
//  элемента общим таймером (GetScrollInfo), прокрутка идёт обычными
//  сообщениями элементу.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls,
  ComCtrls, StdCtrls, Grids;

type
  TUiScrollPart = (spNone, spArrowLo, spArrowHi, spTrackLo, spTrackHi,
                   spThumb);

  TUiScrollBar = class(TCustomControl)
  private
    FKind: TScrollBarKind;
    FMin, FMax, FPosition: Integer;
    FSmallChange, FLargeChange: Integer;
    FOnChange: TNotifyEvent;
    FTrackColor, FThumbColor, FThumbHotColor, FArrowColor: TColor;
    FOwnColors: Boolean;        // цвета задал владелец, а не тема
    FDown: TUiScrollPart;       // нажато мышью
    FHot: TUiScrollPart;        // под мышью
    FDragOffset: Integer;       // от начала ползунка до точки захвата
    FDragFrom: Integer;         // точка захвата вдоль полосы
    FMouse: TPoint;             // последняя точка мыши - для повтора
    FTimer: TTimer;
    procedure SetKind(Value: TScrollBarKind);
    procedure SetMin(Value: Integer);
    procedure SetMax(Value: Integer);
    procedure SetPosition(Value: Integer);
    procedure SetLargeChange(Value: Integer);
    function  Len: Integer;
    function  Thick: Integer;
    function  ArrowLen: Integer;
    function  Along(X, Y: Integer): Integer;
    procedure ThumbSpan(var AStart, ALen: Integer);
    function  PartAt(X, Y: Integer): TUiScrollPart;
    function  PartRect(AFrom, ATo: Integer): TRect;
    procedure DoStep(APart: TUiScrollPart);
    procedure TimerTick(Sender: TObject);
    procedure DrawArrow(const R: TRect; ALow: Boolean; APart: TUiScrollPart);
    procedure PaintNative;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
                      X, Y: Integer); override;
    procedure Change; virtual;
    function  GetDragging: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Свои цвета полосы вместо цветов темы: дорожка, ползунок, ползунок под
    // мышью или нажатый, стрелки
    procedure SetColors(ATrack, AThumb, AThumbHot, AArrow: TColor);
    // Ползунок сейчас тянут мышью
    property Dragging: Boolean read GetDragging;
  published
    // Опубликованы, как у TScrollBar: их записывает снимок формы, а
    // конструктор форм по ним строит полосу того же вида и размера
    property Align;
    property Anchors;
    property Visible;
    property Kind: TScrollBarKind read FKind write SetKind default sbHorizontal;
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 0;
    property Position: Integer read FPosition write SetPosition default 0;
    property SmallChange: Integer read FSmallChange write FSmallChange
      default 1;
    property LargeChange: Integer read FLargeChange write SetLargeChange
      default 1;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

type
  // Угол между нашими полосами, когда у элемента видны обе: закрывает
  // квадратик Windows цветом дорожки
  TUiScrollCorner = class(TCustomControl)
  private
    FColor: TColor;
    FOwnColor: Boolean;         // цвет задал владелец, а не тема
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetColor(AColor: TColor);
  end;

  // Наши полосы поверх полос Windows у элемента (список, дерево, таблица,
  // лог, поле с полосами): вертикальная, горизонтальная и угол между ними
  TUiListScroll = class(TComponent)
  private
    FCtl: TWinControl;
    FBar: TUiScrollBar;          // вертикальная
    FHBar: TUiScrollBar;         // горизонтальная
    FCorner: TUiScrollCorner;
    FLock: Boolean;
    FOldCtlProc: TWndMethod;     // WindowProc элемента до нас
    procedure CtlWndProc(var Message: TMessage);
    procedure BarChange(Sender: TObject);
    procedure HBarChange(Sender: TObject);
    procedure SyncBar(ABar: TUiScrollBar; ASB: Integer; AShow: Boolean;
                      const R: TRect);
    function  GetRange(ASB: Integer;
                       var AMin, AMax, APage, APos: Integer): Boolean;
    procedure HideAll;
  protected
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
  public
    // Принадлежит самому элементу (Owner) и уходит вместе с ним
    constructor Attach(ACtl: TWinControl);
    destructor Destroy; override;
    // Сверить с полосами элемента сейчас: место, видимость, диапазон,
    // позиция
    procedure Sync;
    // Цвета обеих полос и угла
    procedure SetColors(ATrack, AThumb, AThumbHot, AArrow: TColor);
    property Bar: TUiScrollBar read FBar;
    property HBar: TUiScrollBar read FHBar;
  end;

// Наши полосы элемента, если уже поставлены, иначе nil
function UiScrollFind(ACtl: TWinControl): TUiListScroll;

// Сверить все наши полосы элементов сейчас, не дожидаясь таймера. Нужно
// сразу после показа окна: пока оно было спрятано, сверка по таймеру
// убрала полосы его элементов (элемент не виден), и до следующей сверки
// на их месте видны полосы Windows.
procedure UiScrollSyncAll;

// Служебная часть TUiListScroll (полоса или угол поверх полос элемента), а
// не полоса, которую поставили в форму сами. Для снимка формы: таких
// элементов нет ни в коде, ни в .dfm.
function UiScrollIsService(C: TComponent): Boolean;

implementation

uses
  UiTheme, Themes;

const
  FirstDelay = 350;    // мс до первого повтора
  RepeatDelay = 50;    // мс между повторами
  MinThumb = 32;       // наименьшая длина ползунка, пикселей

constructor TUiScrollBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  TabStop := False;
  DoubleBuffered := True;
  FKind := sbHorizontal;
  FSmallChange := 1;
  FLargeChange := 1;
  FTrackColor := UiThemeColorFor(Self, 'Scroll.Track');
  FThumbColor := UiThemeColorFor(Self, 'Scroll.Thumb');
  FThumbHotColor := UiThemeColorFor(Self, 'Scroll.ThumbHot');
  FArrowColor := UiThemeColorFor(Self, 'Scroll.Arrow');
  // Смена темы - перерисовка; цвета берёт Paint
  UiThemeAddClient(Self);
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.OnTimer := TimerTick;
  Width := 17;
  Height := 17;
end;

destructor TUiScrollBar.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiScrollBar.SetColors(ATrack, AThumb, AThumbHot, AArrow: TColor);
begin
  FOwnColors := True;
  FTrackColor := ATrack;
  FThumbColor := AThumb;
  FThumbHotColor := AThumbHot;
  FArrowColor := AArrow;
  Invalidate;
end;

procedure TUiScrollBar.Change;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TUiScrollBar.SetKind(Value: TScrollBarKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    Invalidate;
  end;
end;

// Min, Max и Position - как у TScrollBar: позиция всегда в [Min, Max];
// если она сдвинулась, приходит OnChange
procedure TUiScrollBar.SetMin(Value: Integer);
begin
  if FMin = Value then
    Exit;
  FMin := Value;
  if FMax < FMin then
    FMax := FMin;
  if FPosition < FMin then
    SetPosition(FMin)
  else
    Invalidate;
end;

procedure TUiScrollBar.SetMax(Value: Integer);
begin
  if FMax = Value then
    Exit;
  FMax := Value;
  if FMax < FMin then
    FMax := FMin;
  if FPosition > FMax then
    SetPosition(FMax)
  else
    Invalidate;
end;

procedure TUiScrollBar.SetPosition(Value: Integer);
begin
  if Value < FMin then
    Value := FMin;
  if Value > FMax then
    Value := FMax;
  if Value = FPosition then
    Exit;
  FPosition := Value;
  Invalidate;
  Change;
end;

procedure TUiScrollBar.SetLargeChange(Value: Integer);
begin
  if Value < 1 then
    Value := 1;
  if FLargeChange <> Value then
  begin
    FLargeChange := Value;
    Invalidate;
  end;
end;

// Длина вдоль полосы и толщина поперёк
function TUiScrollBar.Len: Integer;
begin
  if FKind = sbVertical then
    Result := ClientHeight
  else
    Result := ClientWidth;
end;

function TUiScrollBar.Thick: Integer;
begin
  if FKind = sbVertical then
    Result := ClientWidth
  else
    Result := ClientHeight;
end;

// Стрелка - квадрат со стороной в толщину полосы; на короткой полосе -
// по половине длины
function TUiScrollBar.ArrowLen: Integer;
begin
  Result := Thick;
  if Result > Len div 2 then
    Result := Len div 2;
end;

function TUiScrollBar.Along(X, Y: Integer): Integer;
begin
  if FKind = sbVertical then
    Result := Y
  else
    Result := X;
end;

// Ползунок: начало и длина вдоль полосы. Длина - доля видимого (LargeChange)
// во всём (Max - Min + LargeChange). Прокручивать нечего - длина 0.
procedure TUiScrollBar.ThumbSpan(var AStart, ALen: Integer);
var
  Track, Range: Integer;
begin
  Track := Len - 2 * ArrowLen;
  Range := FMax - FMin;
  AStart := ArrowLen;
  ALen := 0;
  if (Range <= 0) or (Track <= 0) then
    Exit;
  ALen := MulDiv(Track, FLargeChange, Range + FLargeChange);
  if ALen < MinThumb then
    ALen := MinThumb;
  if ALen > Track then
    ALen := Track;
  AStart := ArrowLen + MulDiv(Track - ALen, FPosition - FMin, Range);
end;

function TUiScrollBar.PartAt(X, Y: Integer): TUiScrollPart;
var
  P, S, L: Integer;
begin
  P := Along(X, Y);
  if P < ArrowLen then
    Result := spArrowLo
  else if P >= Len - ArrowLen then
    Result := spArrowHi
  else
  begin
    ThumbSpan(S, L);
    if L = 0 then
      Result := spNone
    else if P < S then
      Result := spTrackLo
    else if P >= S + L then
      Result := spTrackHi
    else
      Result := spThumb;
  end;
end;

// Прямоугольник участка полосы [AFrom, ATo) вдоль неё, во всю толщину
function TUiScrollBar.PartRect(AFrom, ATo: Integer): TRect;
begin
  if FKind = sbVertical then
    Result := Rect(0, AFrom, ClientWidth, ATo)
  else
    Result := Rect(AFrom, 0, ATo, ClientHeight);
end;

procedure TUiScrollBar.DoStep(APart: TUiScrollPart);
begin
  case APart of
    spArrowLo: Position := FPosition - FSmallChange;
    spArrowHi: Position := FPosition + FSmallChange;
    spTrackLo: Position := FPosition - FLargeChange;
    spTrackHi: Position := FPosition + FLargeChange;
  end;
end;

procedure TUiScrollBar.TimerTick(Sender: TObject);
begin
  FTimer.Interval := RepeatDelay;
  // По дорожке - пока ползунок не дошёл до мыши
  if (FDown in [spTrackLo, spTrackHi]) and
     (PartAt(FMouse.X, FMouse.Y) <> FDown) then
    Exit;
  if FDown in [spArrowLo, spArrowHi, spTrackLo, spTrackHi] then
    DoStep(FDown)
  else
    FTimer.Enabled := False;
end;

procedure TUiScrollBar.MouseDown(Button: TMouseButton; Shift: TShiftState;
                                 X, Y: Integer);
var
  S, L: Integer;
begin
  inherited;
  if Button <> mbLeft then
    Exit;
  FMouse := Point(X, Y);
  FDown := PartAt(X, Y);
  case FDown of
    spThumb:
      begin
        ThumbSpan(S, L);
        FDragOffset := Along(X, Y) - S;
        FDragFrom := Along(X, Y);
      end;
    spArrowLo, spArrowHi, spTrackLo, spTrackHi:
      begin
        DoStep(FDown);
        FTimer.Interval := FirstDelay;
        FTimer.Enabled := True;
      end;
  end;
  Invalidate;
end;

procedure TUiScrollBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  S, L, Track, NewStart: Integer;
  P: TUiScrollPart;
begin
  inherited;
  FMouse := Point(X, Y);
  if FDown = spThumb then
  begin
    // Мышь ещё не сдвинулась с точки захвата - позицию не пересчитываем:
    // пересчёт через пиксели округляет, и один щелчок сдвинул бы текст
    if Along(X, Y) = FDragFrom then
      Exit;
    FDragFrom := MaxInt;
    // Ползунок - за мышью; позиция - той же долей от диапазона
    ThumbSpan(S, L);
    Track := Len - 2 * ArrowLen;
    if Track - L > 0 then
    begin
      NewStart := Along(X, Y) - FDragOffset - ArrowLen;
      Position := FMin + MulDiv(NewStart, FMax - FMin, Track - L);
    end;
  end
  else if FDown = spNone then
  begin
    P := PartAt(X, Y);
    if P <> FHot then
    begin
      FHot := P;
      Invalidate;
    end;
  end;
end;

procedure TUiScrollBar.MouseUp(Button: TMouseButton; Shift: TShiftState;
                               X, Y: Integer);
begin
  inherited;
  FTimer.Enabled := False;
  FDown := spNone;
  FHot := PartAt(X, Y);
  Invalidate;
end;

procedure TUiScrollBar.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHot <> spNone then
  begin
    FHot := spNone;
    Invalidate;
  end;
end;

// Фон рисует Paint целиком
procedure TUiScrollBar.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

// Стрелка: подложка (нажата - цветом нажатого ползунка, под мышью - цветом
// ползунка) и треугольник
procedure TUiScrollBar.DrawArrow(const R: TRect; ALow: Boolean;
                                 APart: TUiScrollPart);
var
  Cx, Cy, S: Integer;
  Pts: array[0..2] of TPoint;
  Off: Boolean;
begin
  if FDown = APart then
    Canvas.Brush.Color := FThumbHotColor
  else if FHot = APart then
    Canvas.Brush.Color := FThumbColor
  else
    Canvas.Brush.Color := FTrackColor;
  Canvas.FillRect(R);

  Off := FMax <= FMin;
  Cx := (R.Left + R.Right) div 2;
  Cy := (R.Top + R.Bottom) div 2;
  // Размер треугольника - от толщины полосы
  if FKind = sbVertical then
    S := (R.Right - R.Left) div 4
  else
    S := (R.Bottom - R.Top) div 4;
  if S < 2 then
    S := 2;
  if FKind = sbVertical then
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
  if Off then
    Canvas.Brush.Color := FThumbColor
  else
    Canvas.Brush.Color := FArrowColor;
  Canvas.Pen.Color := Canvas.Brush.Color;
  Canvas.Polygon(Pts);
end;

// Тема Light при темах Windows: части полосы - элементами темы Windows
// (стрелки, дорожка до и после ползунка, ползунок с насечкой)
procedure TUiScrollBar.PaintNative;
var
  A, S, L: Integer;
  Off, Vert: Boolean;

  // Состояние части: за каждым ...Normal в перечне темы идут Hot, Pressed,
  // Disabled
  procedure Draw(ABase: TThemedScrollBar; APart: TUiScrollPart;
                 const R: TRect);
  var
    K: Integer;
  begin
    if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
      Exit;
    if Off then
      K := 3
    else if FDown = APart then
      K := 2
    else if FHot = APart then
      K := 1
    else
      K := 0;
    ThemeServices.DrawElement(Canvas.Handle,
      ThemeServices.GetElementDetails(TThemedScrollBar(Ord(ABase) + K)), R);
  end;

begin
  Off := (FMax <= FMin) or not Enabled;
  Vert := FKind = sbVertical;
  A := ArrowLen;
  ThumbSpan(S, L);
  if Vert then
  begin
    Draw(tsArrowBtnUpNormal, spArrowLo, PartRect(0, A));
    Draw(tsArrowBtnDownNormal, spArrowHi, PartRect(Len - A, Len));
    if L > 0 then
    begin
      Draw(tsLowerTrackVertNormal, spTrackLo, PartRect(A, S));
      Draw(tsUpperTrackVertNormal, spTrackHi, PartRect(S + L, Len - A));
      Draw(tsThumbBtnVertNormal, spThumb, PartRect(S, S + L));
      Draw(tsGripperVertNormal, spThumb, PartRect(S, S + L));
    end
    else
      Draw(tsLowerTrackVertNormal, spNone, PartRect(A, Len - A));
  end
  else
  begin
    Draw(tsArrowBtnLeftNormal, spArrowLo, PartRect(0, A));
    Draw(tsArrowBtnRightNormal, spArrowHi, PartRect(Len - A, Len));
    if L > 0 then
    begin
      Draw(tsLowerTrackHorzNormal, spTrackLo, PartRect(A, S));
      Draw(tsUpperTrackHorzNormal, spTrackHi, PartRect(S + L, Len - A));
      Draw(tsThumbBtnHorzNormal, spThumb, PartRect(S, S + L));
      Draw(tsGripperHorzNormal, spThumb, PartRect(S, S + L));
    end
    else
      Draw(tsLowerTrackHorzNormal, spNone, PartRect(A, Len - A));
  end;
end;

procedure TUiScrollBar.Paint;
var
  A, S, L, Inset: Integer;
  R: TRect;
begin
  // Тема Light при темах Windows, своих цветов владелец не задавал - как
  // полоса Windows
  if UiThemeNativeFor(Self) and not FOwnColors then
  begin
    PaintNative;
    Exit;
  end;
  // Свои цвета владелец не задавал - цвета темы сейчас
  if not FOwnColors then
  begin
    FTrackColor := UiThemeColorFor(Self, 'Scroll.Track');
    FThumbColor := UiThemeColorFor(Self, 'Scroll.Thumb');
    FThumbHotColor := UiThemeColorFor(Self, 'Scroll.ThumbHot');
    FArrowColor := UiThemeColorFor(Self, 'Scroll.Arrow');
  end;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FTrackColor;
  Canvas.FillRect(ClientRect);

  A := ArrowLen;
  if A > 0 then
  begin
    DrawArrow(PartRect(0, A), True, spArrowLo);
    DrawArrow(PartRect(Len - A, Len), False, spArrowHi);
  end;

  ThumbSpan(S, L);
  if L > 0 then
  begin
    if FDown = spThumb then
      Canvas.Brush.Color := FThumbHotColor
    else if FHot = spThumb then
      Canvas.Brush.Color := FThumbHotColor
    else
      Canvas.Brush.Color := FThumbColor;
    // Поперёк - с отступом от краёв, вдоль - с зазором в пиксель
    R := PartRect(S + 1, S + L - 1);
    Inset := Thick div 5;
    if Inset < 2 then
      Inset := 2;
    if FKind = sbVertical then
      InflateRect(R, -Inset, 0)
    else
      InflateRect(R, 0, -Inset);
    Canvas.FillRect(R);
  end;
end;

function TUiScrollBar.GetDragging: Boolean;
begin
  Result := FDown = spThumb;
end;

// ---------------------------------------------------------------------------
//  TUiScrollCorner
// ---------------------------------------------------------------------------

constructor TUiScrollCorner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  TabStop := False;
  FColor := UiThemeColorFor(Self, 'Scroll.Track');
  UiThemeAddClient(Self);
  Width := 17;
  Height := 17;
end;

destructor TUiScrollCorner.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

procedure TUiScrollCorner.SetColor(AColor: TColor);
begin
  FOwnColor := True;
  if FColor <> AColor then
  begin
    FColor := AColor;
    Invalidate;
  end;
end;

procedure TUiScrollCorner.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TUiScrollCorner.Paint;
begin
  if not FOwnColor then
    FColor := UiThemeColorFor(Self, 'Scroll.Track');
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FColor;
  Canvas.FillRect(ClientRect);
end;

// ---------------------------------------------------------------------------
//  TUiListScroll
//
//  Все наши полосы сверяются с полосами своих элементов одним общим таймером
//  (TUiScrollTicker): так таймер один на программу, сколько бы элементов с
//  полосами ни было. Полоса регистрируется в Attach и уходит из списка в
//  Destroy.
// ---------------------------------------------------------------------------

const
  SyncInterval = 50;   // мс между сверками с полосами элементов
  LVM_GETTOPINDEX_ = $1000 + 39;
  LVM_GETITEMRECT_ = $1000 + 14;
  LVM_SCROLL_ = $1000 + 20;
  LVM_GETITEMCOUNT_ = $1000 + 4;
  TVM_GETNEXTITEM_ = $1100 + 10;
  TVM_SELECTITEM_ = $1100 + 11;
  TVGN_ROOT_ = 0;
  TVGN_FIRSTVISIBLE_ = 5;
  TVGN_NEXTVISIBLE_ = 6;
  // Шагов по строке, не больше, при прокрутке дерева по горизонтали
  MaxLineSteps = 1000;

type
  // Доступ к защищённым RowCount, ColCount, FixedRows, FixedCols таблицы
  TUiGridAcc = class(TCustomGrid);

  TUiScrollTicker = class(TObject)
  public
    Timer: TTimer;
    List: TList;
    constructor Create;
    destructor Destroy; override;
    procedure Tick(Sender: TObject);
  end;

var
  Ticker: TUiScrollTicker = nil;

constructor TUiScrollTicker.Create;
begin
  inherited Create;
  List := TList.Create;
  Timer := TTimer.Create(nil);
  Timer.Interval := SyncInterval;
  Timer.OnTimer := Tick;
  Timer.Enabled := True;
end;

destructor TUiScrollTicker.Destroy;
begin
  Timer.Free;
  List.Free;
  inherited Destroy;
end;

procedure TUiScrollTicker.Tick(Sender: TObject);
var
  I: Integer;
begin
  for I := List.Count - 1 downto 0 do
    if I < List.Count then
      TUiListScroll(List[I]).Sync;
end;

procedure UiScrollSyncAll;
begin
  if Ticker <> nil then
    Ticker.Tick(nil);
end;

function UiScrollFind(ACtl: TWinControl): TUiListScroll;
var
  K: Integer;
begin
  Result := nil;
  if ACtl = nil then
    Exit;
  for K := 0 to ACtl.ComponentCount - 1 do
    if ACtl.Components[K] is TUiListScroll then
    begin
      Result := TUiListScroll(ACtl.Components[K]);
      Exit;
    end;
end;

function UiScrollIsService(C: TComponent): Boolean;
var
  LS: TUiListScroll;
begin
  Result := C is TUiScrollCorner;
  if Result or not (C is TUiScrollBar) or not (C.Owner is TWinControl) then
    Exit;
  LS := UiScrollFind(TWinControl(C.Owner));
  Result := (LS <> nil) and ((LS.Bar = C) or (LS.HBar = C));
end;

constructor TUiListScroll.Attach(ACtl: TWinControl);
begin
  inherited Create(ACtl);
  FCtl := ACtl;
  // Полосы и угол - соседи элемента в том же родителе. Владелец - элемент:
  // уходят вместе с ним. Родитель может уничтожить их раньше элемента -
  // об этом сообщит Notification.
  FBar := TUiScrollBar.Create(ACtl);
  FBar.Visible := False;
  FBar.Kind := sbVertical;
  FBar.Parent := ACtl.Parent;
  FBar.OnChange := BarChange;
  FBar.FreeNotification(Self);

  FHBar := TUiScrollBar.Create(ACtl);
  FHBar.Visible := False;
  FHBar.Kind := sbHorizontal;
  FHBar.Parent := ACtl.Parent;
  FHBar.OnChange := HBarChange;
  FHBar.FreeNotification(Self);

  FCorner := TUiScrollCorner.Create(ACtl);
  FCorner.Visible := False;
  FCorner.Parent := ACtl.Parent;
  FCorner.FreeNotification(Self);

  // alCustom: место полос задаём только мы. У окна или панели с
  // AutoScroll элемент с alNone и якорем слева входит в размер области
  // прокрутки: пока полоса после сжатия окна ещё прежней длины и торчит за
  // край, у окна появлялась своя полоса прокрутки Windows. alCustom в этот
  // размер не входит, и якоря VCL такие элементы не двигают.
  FBar.Align := alCustom;
  FHBar.Align := alCustom;
  FCorner.Align := alCustom;

  if Ticker = nil then
    Ticker := TUiScrollTicker.Create;
  Ticker.List.Add(Self);

  // Элемент сдвинулся или сменил размер (растянули окно, сдвинули
  // разделитель) - полосы на новое место сразу, а не при следующей
  // сверке по таймеру: иначе на время между сверками открывается полоса
  // Windows на новом месте, а наша догоняет её рывками
  FOldCtlProc := ACtl.WindowProc;
  ACtl.WindowProc := CtlWndProc;
end;

procedure TUiListScroll.CtlWndProc(var Message: TMessage);
begin
  FOldCtlProc(Message);
  case Message.Msg of
    WM_WINDOWPOSCHANGED, WM_SIZE, WM_SHOWWINDOW:
      Sync;
  end;
end;

destructor TUiListScroll.Destroy;
var
  CurProc: TWndMethod;
begin
  if Ticker <> nil then
    Ticker.List.Remove(Self);
  // Свой WindowProc - вернуть прежний, если после нас его никто не менял
  if FCtl <> nil then
  begin
    CurProc := FCtl.WindowProc;
    if (TMethod(CurProc).Code = @TUiListScroll.CtlWndProc) and
       (TMethod(CurProc).Data = Self) then
      FCtl.WindowProc := FOldCtlProc;
  end;
  inherited Destroy;
end;

procedure TUiListScroll.Notification(AComponent: TComponent;
                                     Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FBar then
      FBar := nil
    else if AComponent = FHBar then
      FHBar := nil
    else if AComponent = FCorner then
      FCorner := nil;
  end;
end;

procedure TUiListScroll.SetColors(ATrack, AThumb, AThumbHot, AArrow: TColor);
begin
  if FBar <> nil then
    FBar.SetColors(ATrack, AThumb, AThumbHot, AArrow);
  if FHBar <> nil then
    FHBar.SetColors(ATrack, AThumb, AThumbHot, AArrow);
  if FCorner <> nil then
    FCorner.SetColor(ATrack);
end;

procedure TUiListScroll.HideAll;
begin
  if (FBar <> nil) and FBar.Visible then
    FBar.Visible := False;
  if (FHBar <> nil) and FHBar.Visible then
    FHBar.Visible := False;
  if (FCorner <> nil) and FCorner.Visible then
    FCorner.Visible := False;
end;

// Одна полоса: место R (в координатах родителя), диапазон и позиция - как у
// полосы Windows ASB элемента
procedure TUiListScroll.SyncBar(ABar: TUiScrollBar; ASB: Integer;
                                AShow: Boolean; const R: TRect);
var
  AMin, AMax, APage, APos: Integer;
  Moved: Boolean;
begin
  if ABar = nil then
    Exit;
  if not AShow then
  begin
    if ABar.Visible then
      ABar.Visible := False;
    Exit;
  end;
  if ABar.Parent <> FCtl.Parent then
    ABar.Parent := FCtl.Parent;
  Moved := (ABar.Left <> R.Left) or (ABar.Top <> R.Top) or
           (ABar.Width <> R.Right - R.Left) or
           (ABar.Height <> R.Bottom - R.Top);
  if Moved then
    ABar.SetBounds(R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top);

  if GetRange(ASB, AMin, AMax, APage, APos) then
  begin
    FLock := True;
    try
      ABar.Min := AMin;
      ABar.Max := AMax;
      ABar.LargeChange := APage;
      // Ползунок тянут - его место задаёт мышь, а не элемент: иначе каждая
      // сверка возвращала бы его к месту элемента, и он шёл бы рывками
      if not ABar.Dragging then
        ABar.Position := APos;
    finally
      FLock := False;
    end;
  end;

  if not ABar.Visible then
  begin
    ABar.Visible := True;
    ABar.BringToFront;
    Moved := True;
  end;

  // Сдвинули или показали - нарисовать сразу, в этом же сообщении. При
  // быстром растягивании окна сообщения о перемене места идут подряд, а
  // WM_PAINT ждёт, пока очередь опустеет: без этого полоса стояла бы на
  // новом месте недорисованной. Invalidate - вся полоса: при смене длины
  // Windows помечает к перерисовке только добавленный кусок.
  if Moved and ABar.HandleAllocated then
  begin
    ABar.Invalidate;
    ABar.Update;
  end;
end;

// Диапазон, страница и позиция полосы ASB элемента - в тех единицах, в
// которых нашу полосу удобно двигать:
//   таблица (TCustomGrid) - строки и колонки: место таблицы задают TopRow
//     и LeftCol, и шаг стрелки - ровно одна строка или колонка;
//   поле и лог (TCustomMemo) по вертикали - строки: у RichEdit полоса в
//     пикселях, шаг стрелки в пиксель не сдвигает на строку;
//   прочие - как у полосы Windows (GetScrollInfo).
function TUiListScroll.GetRange(ASB: Integer;
                                var AMin, AMax, APage, APos: Integer): Boolean;
var
  SI: TScrollInfo;
  G: TUiGridAcc;
  Lines, Span: Integer;
begin
  Result := False;
  if FCtl is TCustomGrid then
  begin
    G := TUiGridAcc(FCtl);
    if ASB = SB_VERT then
    begin
      AMin := G.FixedRows;
      APage := G.VisibleRowCount;
      AMax := G.RowCount - APage;
      APos := G.TopRow;
    end
    else
    begin
      AMin := G.FixedCols;
      APage := G.VisibleColCount;
      AMax := G.ColCount - APage;
      APos := G.LeftCol;
    end;
    if APage < 1 then
      APage := 1;
    if AMax < AMin then
      AMax := AMin;
    Result := True;
    Exit;
  end;

  FillChar(SI, SizeOf(SI), 0);
  SI.cbSize := SizeOf(SI);
  SI.fMask := SIF_ALL;
  if not GetScrollInfo(FCtl.Handle, ASB, SI) then
    Exit;

  if (ASB = SB_VERT) and (FCtl is TCustomMemo) then
  begin
    Lines := SendMessage(FCtl.Handle, EM_GETLINECOUNT, 0, 0);
    Span := SI.nMax - SI.nMin + 1;
    // Видимых строк - та же доля, что страница полосы от её диапазона
    if (SI.nPage > 0) and (Span > 0) then
      APage := MulDiv(Lines, SI.nPage, Span)
    else
      APage := 1;
    if APage < 1 then
      APage := 1;
    AMin := 0;
    AMax := Lines - APage;
    if AMax < 0 then
      AMax := 0;
    APos := SendMessage(FCtl.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
    Result := True;
    Exit;
  end;

  AMin := SI.nMin;
  AMax := SI.nMax - Integer(SI.nPage) + 1;
  if AMax < AMin then
    AMax := AMin;
  APage := SI.nPage;
  if APage < 1 then
    APage := 1;
  APos := SI.nPos;
  Result := True;
end;

procedure TUiListScroll.Sync;
var
  R: TRect;
  P: TPoint;
  W, H: Integer;
  Style: Longint;
  VOn, HOn: Boolean;
begin
  if (FCtl = nil) or (FCtl.Parent = nil) then
    Exit;
  // Элемент не виден (в том числе на скрытой вкладке или в скрытом окне) -
  // полосы не нужны
  if not FCtl.HandleAllocated or not IsWindowVisible(FCtl.Handle) then
  begin
    HideAll;
    Exit;
  end;
  // Тема Light при темах Windows: видны полосы Windows самого элемента
  if UiThemeNativeFor(FCtl) then
  begin
    HideAll;
    Exit;
  end;

  // Какие полосы Windows сейчас есть у элемента
  Style := GetWindowLong(FCtl.Handle, GWL_STYLE);
  VOn := (Style and WS_VSCROLL) <> 0;
  HOn := (Style and WS_HSCROLL) <> 0;
  if not VOn and not HOn then
  begin
    HideAll;
    Exit;
  end;

  // Рабочая область элемента в координатах родителя. Вертикальная полоса
  // Windows - справа от неё во всю её высоту, горизонтальная - снизу во всю
  // ширину, угол - между ними.
  Windows.GetClientRect(FCtl.Handle, R);
  P := Point(R.Left, R.Top);
  Windows.ClientToScreen(FCtl.Handle, P);
  P := FCtl.Parent.ScreenToClient(P);
  OffsetRect(R, P.X - R.Left, P.Y - R.Top);
  W := GetSystemMetrics(SM_CXVSCROLL);
  H := GetSystemMetrics(SM_CYHSCROLL);

  SyncBar(FBar, SB_VERT, VOn, Rect(R.Right, R.Top, R.Right + W, R.Bottom));
  SyncBar(FHBar, SB_HORZ, HOn, Rect(R.Left, R.Bottom, R.Right, R.Bottom + H));

  if FCorner <> nil then
  begin
    if VOn and HOn then
    begin
      if FCorner.Parent <> FCtl.Parent then
        FCorner.Parent := FCtl.Parent;
      if (FCorner.Left <> R.Right) or (FCorner.Top <> R.Bottom) or
         (FCorner.Width <> W) or (FCorner.Height <> H) then
      begin
        FCorner.SetBounds(R.Right, R.Bottom, W, H);
        if FCorner.HandleAllocated then
          FCorner.Update;
      end;
      if not FCorner.Visible then
      begin
        FCorner.Visible := True;
        FCorner.BringToFront;
      end;
    end
    else if FCorner.Visible then
      FCorner.Visible := False;
  end;
end;

// Прокрутка шагами по строке (SB_LINEUP / SB_LINEDOWN, для горизонтали это
// SB_LINELEFT / SB_LINERIGHT) до позиции ATarget полосы ASB: пока не дошли,
// не перешагнули или позиция не перестала меняться
procedure ScrollStepTo(AWnd: HWND; ASB, AMsg, ATarget: Integer);
var
  SI: TScrollInfo;
  N, Last: Integer;
begin
  FillChar(SI, SizeOf(SI), 0);
  SI.cbSize := SizeOf(SI);
  SI.fMask := SIF_POS;
  for N := 1 to MaxLineSteps do
  begin
    if not GetScrollInfo(AWnd, ASB, SI) then
      Break;
    if SI.nPos = ATarget then
      Break;
    Last := SI.nPos;
    if ATarget < Last then
      SendMessage(AWnd, AMsg, SB_LINEUP, 0)
    else
      SendMessage(AWnd, AMsg, SB_LINEDOWN, 0);
    if not GetScrollInfo(AWnd, ASB, SI) then
      Break;
    if SI.nPos = Last then
      Break;                                  // дальше не едет
    if (ATarget < Last) <> (ATarget < SI.nPos) then
      Break;                                  // перешагнули
  end;
  SendMessage(AWnd, AMsg, SB_ENDSCROLL, 0);
end;

// Нашу вертикальную полосу сдвинули - прокрутить элемент к её позиции
procedure TUiListScroll.BarChange(Sender: TObject);
var
  RowH, Count, K, First, V, MaxV: Integer;
  H, N: THandle;
  R: TRect;
  SI: TScrollInfo;
  G: TUiGridAcc;
begin
  if FLock or (FCtl = nil) or (FBar = nil) or not FCtl.HandleAllocated then
    Exit;
  if FCtl is TCustomGrid then
  begin
    // Таблица: полоса в строках (GetRange) - первая видимая строка
    G := TUiGridAcc(FCtl);
    MaxV := G.RowCount - G.VisibleRowCount;
    if MaxV < G.FixedRows then
      MaxV := G.FixedRows;
    V := FBar.Position;
    if V > MaxV then
      V := MaxV;
    if V < G.FixedRows then
      V := G.FixedRows;
    if G.TopRow <> V then
      G.TopRow := V;
  end
  else if FCtl is TCustomListView then
  begin
    // LVM_SCROLL принимает пиксели. Полоса таблицы (vsReport) считает в
    // строках - сдвиг переводим через высоту строки; если же её диапазон
    // в пикселях (намного больше числа строк), сдвиг и так в пикселях.
    FillChar(SI, SizeOf(SI), 0);
    SI.cbSize := SizeOf(SI);
    SI.fMask := SIF_ALL;
    if not GetScrollInfo(FCtl.Handle, SB_VERT, SI) then
      Exit;
    Count := SendMessage(FCtl.Handle, LVM_GETITEMCOUNT_, 0, 0);
    FillChar(R, SizeOf(R), 0);
    R.Left := 0;             // LVIR_BOUNDS
    RowH := 0;
    if (Count > 0) and
       (SendMessage(FCtl.Handle, LVM_GETITEMRECT_, 0, Integer(@R)) <> 0) then
      RowH := R.Bottom - R.Top;
    if RowH <= 0 then
      Exit;
    if SI.nMax + 1 > Count * 2 then
      SendMessage(FCtl.Handle, LVM_SCROLL_, 0, FBar.Position - SI.nPos)
    else
      SendMessage(FCtl.Handle, LVM_SCROLL_, 0,
                  (FBar.Position - SendMessage(FCtl.Handle, LVM_GETTOPINDEX_,
                                               0, 0)) * RowH);
  end
  else if FCtl is TCustomTreeView then
  begin
    // Дерево: полоса считает в видимых строках. Первым видимым ставится
    // узел с этим номером среди раскрытых (TVGN_FIRSTVISIBLE). WM_VSCROLL
    // с SB_THUMBPOSITION дерево не слушает: позицию оно берёт у своей
    // полосы, которую никто не тянул.
    H := SendMessage(FCtl.Handle, TVM_GETNEXTITEM_, TVGN_ROOT_, 0);
    K := 0;
    while (H <> 0) and (K < FBar.Position) do
    begin
      N := SendMessage(FCtl.Handle, TVM_GETNEXTITEM_, TVGN_NEXTVISIBLE_, H);
      if N = 0 then
        Break;
      H := N;
      Inc(K);
    end;
    if H <> 0 then
      SendMessage(FCtl.Handle, TVM_SELECTITEM_, TVGN_FIRSTVISIBLE_, H);
  end
  else if FCtl is TCustomMemo then
  begin
    // Поле и лог (TMemo, TRichEdit): полоса в строках (GetRange) - первая
    // видимая строка, прокрутка строками (EM_LINESCROLL). Позиция в
    // WM_VSCROLL 16-битная, а диапазон RichEdit в пикселях бывает больше.
    First := SendMessage(FCtl.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
    if FBar.Position <> First then
      SendMessage(FCtl.Handle, EM_LINESCROLL, 0, FBar.Position - First);
  end
  else
  begin
    // Прочие (список, таблица, прокручиваемая панель): обычное сообщение
    // полосы, позиция в нём 16-битная
    SendMessage(FCtl.Handle, WM_VSCROLL,
                MakeWParam(SB_THUMBPOSITION, Word(FBar.Position)), 0);
    SendMessage(FCtl.Handle, WM_VSCROLL, SB_ENDSCROLL, 0);
  end;
  Sync;
end;

// Нашу горизонтальную полосу сдвинули - прокрутить элемент к её позиции
procedure TUiListScroll.HBarChange(Sender: TObject);
var
  SI: TScrollInfo;
  G: TUiGridAcc;
  V, MaxV: Integer;
begin
  if FLock or (FCtl = nil) or (FHBar = nil) or not FCtl.HandleAllocated then
    Exit;
  if FCtl is TCustomGrid then
  begin
    // Таблица: полоса в колонках (GetRange) - первая видимая колонка
    G := TUiGridAcc(FCtl);
    MaxV := G.ColCount - G.VisibleColCount;
    if MaxV < G.FixedCols then
      MaxV := G.FixedCols;
    V := FHBar.Position;
    if V > MaxV then
      V := MaxV;
    if V < G.FixedCols then
      V := G.FixedCols;
    if G.LeftCol <> V then
      G.LeftCol := V;
  end
  else if FCtl is TCustomListView then
  begin
    // Таблица: горизонтальная полоса считает в пикселях, LVM_SCROLL - тоже
    FillChar(SI, SizeOf(SI), 0);
    SI.cbSize := SizeOf(SI);
    SI.fMask := SIF_POS;
    if GetScrollInfo(FCtl.Handle, SB_HORZ, SI) and
       (FHBar.Position <> SI.nPos) then
      SendMessage(FCtl.Handle, LVM_SCROLL_, FHBar.Position - SI.nPos, 0);
  end
  else if FCtl is TCustomTreeView then
    // Дерево: SB_THUMBPOSITION по вертикали оно не слушает (см. BarChange),
    // по горизонтали не проверено - едем шагами по строке
    ScrollStepTo(FCtl.Handle, SB_HORZ, WM_HSCROLL, FHBar.Position)
  else
  begin
    SendMessage(FCtl.Handle, WM_HSCROLL,
                MakeWParam(SB_THUMBPOSITION, Word(FHBar.Position)), 0);
    SendMessage(FCtl.Handle, WM_HSCROLL, SB_ENDSCROLL, 0);
  end;
  Sync;
end;

initialization
  // Класс знает GetClass: конструктор форм строит настоящую полосу, а не
  // заглушку
  if GetClass(TUiScrollBar.ClassName) = nil then
    RegisterClass(TUiScrollBar);

finalization
  // Формы, а с ними и полосы, могут уходить уже после этой секции: Destroy
  // полосы проверяет Ticker на nil
  FreeAndNil(Ticker);
end.
