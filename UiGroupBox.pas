unit UiGroupBox;

// ---------------------------------------------------------------------------
//  TUiGroupBox - рамка с подписью (TGroupBox), у которой рамку и подпись
//  рисует программа, а не тема Windows. С темой TGroupBox рисует подпись
//  цветом темы, и цвет шрифта на неё не действует. Здесь только Paint
//  своя; всё остальное (место для детей, Alt+буква из подписи) - от
//  TCustomGroupBox, как у TGroupBox.
//
//  Вид - по теме (UiTheme): в теме Light при включённых темах Windows
//  рамка рисуется как у TGroupBox (темой Windows); иначе - сама, цветами
//  ролей Group.Text, Group.Border, OffText. Фон - Color рамки.
// ---------------------------------------------------------------------------

interface

uses
  {$IFDEF FPC} LCLType, {$ENDIF}
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls,
  UiTheme;

type
  // В LCL TCustomGroupBox - окно виджета без Paint и Canvas: там рамка -
  // TCustomControl, место детей под подписью задаёт AdjustClientRect
  TUiGroupBox = class({$IFDEF FPC}TCustomControl{$ELSE}TCustomGroupBox{$ENDIF})
  private
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
    {$IFDEF FPC}
    procedure AdjustClientRect(var ARect: TRect); override;
    {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Align;
    property Anchors;
    property BiDiMode;
    property Caption;
    property Color;
    property Constraints;
    {$IFNDEF FPC}property Ctl3D;{$ENDIF}
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBackground default True;
    property ParentBiDiMode;
    property ParentColor;
    {$IFNDEF FPC}property ParentCtl3D;{$ENDIF}
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

constructor TUiGroupBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  {$IFDEF FPC}
  ControlStyle := ControlStyle + [csAcceptsControls, csCaptureMouse,
    csClickEvents, csSetCaption, csDoubleClicks, csReplicatable];
  SetInitialBounds(0, 0, 185, 105);
  {$ENDIF}
  UiThemeAddClient(Self);
end;

{$IFDEF FPC}
// Место детей: внутри рамки, сверху - под строкой подписи (как у
// TCustomGroupBox Delphi)
procedure TUiGroupBox.AdjustClientRect(var ARect: TRect);
begin
  inherited AdjustClientRect(ARect);
  Canvas.Font := Font;
  Inc(ARect.Top, Canvas.TextHeight('0'));
  InflateRect(ARect, -1, -1);
end;
{$ENDIF}

destructor TUiGroupBox.Destroy;
begin
  UiThemeRemoveClient(Self);
  inherited Destroy;
end;

// Тема сменилась - перерисоваться (Result 0: UiThemeChanged сделает это
// сам через Invalidate)
procedure TUiGroupBox.UMUiThemeChanged(var Message: TMessage);
begin
  Message.Result := 0;
end;

// С двойной буферизацией фон стирается в буфере (WMPaint VCL шлёт
// WM_ERASEBKGND с DC буфера в обоих параметрах). Стирание на экране, которое
// Windows шлёт при BeginPaint, пропускается: с темами Windows и
// ParentBackground оно рисовало на экран фон родителя без подписи, и
// подпись мигала до прихода буфера.
procedure TUiGroupBox.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  if DoubleBuffered and
     (TMessage(Message).WParam <> TMessage(Message).LParam) then
    Message.Result := 1
  else
    inherited;
end;

// Как у TCustomGroupBox без темы: рамка от середины строки подписи, подпись
// с отступом 8 точек поверх рамки на фоне рамки
procedure TUiGroupBox.Paint;
var
  HeightPx: Integer;
  RectVal: TRect;
  Flags: Longint;
  Str: string;
begin
  // Тема Light - как у TGroupBox: при включённых темах Windows рисует тема
  // (в LCL предок - TCustomControl, тему не рисует: всегда сами)
  {$IFNDEF FPC}
  if UiThemeNativeFor(Self) then
  begin
    inherited Paint;
    Exit;
  end;
  {$ENDIF}
  with Canvas do
  begin
    Font := Self.Font;
    HeightPx := TextHeight('0');

    RectVal := Rect(0, HeightPx div 2 - 1, Self.Width, Self.Height);
    Brush.Style := bsSolid;
    Brush.Color := UiThemeColorFor(Self, 'Group.Border');
    FrameRect(RectVal);

    Str := Self.Caption;
    if Str <> '' then
    begin
      if not UseRightToLeftAlignment then
        RectVal := Rect(8, 0, 0, HeightPx)
      else
        RectVal := Rect(RectVal.Right - 8, 0, 0, HeightPx);
      Flags := UiDrawTextFlags(Self, DT_SINGLELINE);
      // Self.: внутри with Canvas Handle - у холста, он и нужен DrawText
      DrawText(Handle, PChar(Str), Length(Str), RectVal, Flags or DT_CALCRECT);
      if UseRightToLeftAlignment then
        OffsetRect(RectVal, -(RectVal.Right - RectVal.Left), 0);
      Brush.Color := Self.Color;
      if Self.Enabled then
        Font.Color := UiThemeColorFor(Self, 'Group.Text')
      else
        Font.Color := UiThemeColorFor(Self, 'OffText');
      DrawText(Handle, PChar(Str), Length(Str), RectVal, Flags);
    end;
  end;
end;

initialization
  // Класс знает GetClass: конструктор форм и снимок строят настоящую рамку,
  // а не заглушку
  if GetClass(TUiGroupBox.ClassName) = nil then
    RegisterClass(TUiGroupBox);

end.
