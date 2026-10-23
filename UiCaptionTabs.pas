unit UiCaptionTabs;

// ---------------------------------------------------------------------------
//  TUiCaptionTabs - вкладки на месте подписи рамки (TUiGroupBox): строка
//  «Components | Git» в верхней линии рамки палитры (Unit1). Места не
//  занимает: рамка без подписи (Caption = ''), вкладки - поверх её
//  верхней линии, как подпись.
//
//  Вид - по теме (UiTheme): выбранная вкладка - цветом подписи рамки
//  (Group.Text) в рамке (Group.Border), остальные - цветом OffText.
//  Щелчок по вкладке - TabIndex и OnChange. Ширина - по текстам вкладок
//  (AutoWidth), высота - строка шрифта.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  UiTheme;

type
  TUiCaptionTabs = class(TCustomControl)
  private
    FTabs: TStringList;
    FTabIndex: Integer;
    FOnChange: TNotifyEvent;
    FMeasure: TBitmap;     // холст для замеров текста (без окна)
    function TextW(const AText: string): Integer;
    procedure SetTabIndex(Value: Integer);
    procedure TabsChanged(Sender: TObject);
    function TabRect(AIndex: Integer): TRect;
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Ширина и высота - по текстам и шрифту
    procedure AutoWidth;
    // Номер вкладки под точкой X (-1 - нет)
    function TabAt(X: Integer): Integer;
    property Tabs: TStringList read FTabs;
    property TabIndex: Integer read FTabIndex write SetTabIndex;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  TabPadding = 6;    // отступ текста от краёв вкладки
  TabGap = 2;        // между вкладками

constructor TUiCaptionTabs.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTabs := TStringList.Create;
  FTabs.OnChange := TabsChanged;
  FTabIndex := 0;
  FMeasure := TBitmap.Create;
  FMeasure.Width := 1;
  FMeasure.Height := 1;
  ParentFont := True;
  ParentColor := True;
  DoubleBuffered := True;
  Width := 100;
  Height := 16;
  UiThemeAddClient(Self);
end;

destructor TUiCaptionTabs.Destroy;
begin
  UiThemeRemoveClient(Self);
  FTabs.Free;
  FMeasure.Free;
  inherited Destroy;
end;

procedure TUiCaptionTabs.UMUiThemeChanged(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TUiCaptionTabs.CMFontChanged(var Message: TMessage);
begin
  inherited;
  AutoWidth;
end;

procedure TUiCaptionTabs.TabsChanged(Sender: TObject);
begin
  AutoWidth;
  Invalidate;
end;

procedure TUiCaptionTabs.SetTabIndex(Value: Integer);
begin
  if (Value < 0) or (Value >= FTabs.Count) or (Value = FTabIndex) then
    Exit;
  FTabIndex := Value;
  Invalidate;
end;

function TUiCaptionTabs.TextW(const AText: string): Integer;
begin
  FMeasure.Canvas.Font := Font;
  Result := FMeasure.Canvas.TextWidth(AText);
end;

function TUiCaptionTabs.TabRect(AIndex: Integer): TRect;
var
  TabIdx, TabLeft: Integer;
begin
  TabLeft := 0;
  for TabIdx := 0 to AIndex - 1 do
    Inc(TabLeft, TextW(FTabs[TabIdx]) + 2 * TabPadding + TabGap);
  Result := Rect(TabLeft, 0, TabLeft + TextW(FTabs[AIndex]) + 2 * TabPadding,
    Height);
end;

procedure TUiCaptionTabs.AutoWidth;
var
  NewWidth, NewHeight: Integer;
begin
  FMeasure.Canvas.Font := Font;
  NewHeight := FMeasure.Canvas.TextHeight('0') + 2;
  if FTabs.Count = 0 then
    NewWidth := 10
  else
    NewWidth := TabRect(FTabs.Count - 1).Right;
  if (NewWidth <> Width) or (NewHeight <> Height) then
    SetBounds(Left, Top, NewWidth, NewHeight);
end;

function TUiCaptionTabs.TabAt(X: Integer): Integer;
var
  TabIdx: Integer;
  Bounds: TRect;
begin
  Result := -1;
  for TabIdx := 0 to FTabs.Count - 1 do
  begin
    Bounds := TabRect(TabIdx);
    if (X >= Bounds.Left) and (X < Bounds.Right) then
    begin
      Result := TabIdx;
      Exit;
    end;
  end;
end;

procedure TUiCaptionTabs.Paint;
var
  TabIdx: Integer;
  Bounds: TRect;
  Text: string;
begin
  Canvas.Font := Font;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  for TabIdx := 0 to FTabs.Count - 1 do
  begin
    Bounds := TabRect(TabIdx);
    Text := FTabs[TabIdx];
    if TabIdx = FTabIndex then
    begin
      Canvas.Brush.Color := UiThemeColorFor(Self, 'Group.Border');
      Canvas.FrameRect(Bounds);
      Canvas.Brush.Color := Color;
      Canvas.Font.Color := UiThemeColorFor(Self, 'Group.Text');
    end
    else
      Canvas.Font.Color := UiThemeColorFor(Self, 'OffText');
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(Bounds.Left + TabPadding,
      (Height - Canvas.TextHeight(Text)) div 2, Text);
    Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TUiCaptionTabs.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  Picked: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  Picked := TabAt(X);
  if (Picked < 0) or (Picked = FTabIndex) then
    Exit;
  FTabIndex := Picked;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TUiCaptionTabs.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Hovered: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  Hovered := TabAt(X);
  if (Hovered >= 0) and (Hovered <> FTabIndex) then
    Cursor := crHandPoint
  else
    Cursor := crDefault;
end;

end.
