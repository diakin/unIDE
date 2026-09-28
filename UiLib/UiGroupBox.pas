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
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls,
  UiTheme;

type
  TUiGroupBox = class(TCustomGroupBox)
  private
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
  protected
    procedure Paint; override;
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
    property Ctl3D;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBackground default True;
    property ParentBiDiMode;
    property ParentColor;
    property ParentCtl3D;
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
  UiThemeAddClient(Self);
end;

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

// Как у TCustomGroupBox без темы: рамка от середины строки подписи, подпись
// с отступом 8 точек поверх рамки на фоне рамки
procedure TUiGroupBox.Paint;
var
  H: Integer;
  R: TRect;
  Flags: Longint;
  S: string;
begin
  // Тема Light - как у TGroupBox: при включённых темах Windows рисует тема
  if UiThemeNativeFor(Self) then
  begin
    inherited Paint;
    Exit;
  end;
  with Canvas do
  begin
    Font := Self.Font;
    H := TextHeight('0');

    R := Rect(0, H div 2 - 1, Self.Width, Self.Height);
    Brush.Style := bsSolid;
    Brush.Color := UiThemeColorFor(Self, 'Group.Border');
    FrameRect(R);

    S := Self.Caption;
    if S <> '' then
    begin
      if not UseRightToLeftAlignment then
        R := Rect(8, 0, 0, H)
      else
        R := Rect(R.Right - 8, 0, 0, H);
      Flags := DrawTextBiDiModeFlags(DT_SINGLELINE);
      // Self.: внутри with Canvas Handle - у холста, он и нужен DrawText
      DrawText(Handle, PChar(S), Length(S), R, Flags or DT_CALCRECT);
      if UseRightToLeftAlignment then
        OffsetRect(R, -(R.Right - R.Left), 0);
      Brush.Color := Self.Color;
      if Self.Enabled then
        Font.Color := UiThemeColorFor(Self, 'Group.Text')
      else
        Font.Color := UiThemeColorFor(Self, 'OffText');
      DrawText(Handle, PChar(S), Length(S), R, Flags);
    end;
  end;
end;

initialization
  // Класс знает GetClass: конструктор форм и снимок строят настоящую рамку,
  // а не заглушку
  if GetClass(TUiGroupBox.ClassName) = nil then
    RegisterClass(TUiGroupBox);

end.
