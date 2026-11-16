unit ArdWinMapView;
// ---------------------------------------------------------------------------
//  Окно «Карта окон» скетча Arduino (Arduino - Window Map): окна WinXXX()
//  и переходы между ними (разбор - ArdWinMap)
//
//  Узел - окно (номер в switch), окно-вызов (помощь), setup(), номер без
//  окна (красный). Серый узел - до него нет перехода от setup().
//  Стрелки: сплошная - пункт меню TMenuItem, штрихи - присваивание в коде,
//  точки - прямой вызов. Подпись - клавиши. Переходы внутри окна (повтор,
//  помощь) - строкой под узлом.
//
//  Щелчок по окну - оно открывается в эмуляторе (OnOpenWindow) и в
//  редакторе - его функция (OnGoto). Щелчок по стрелке или подписи -
//  строка перехода. Узлы перетаскиваются мышью, места - в файле .winmap
//  рядом со скетчем. Правая кнопка - меню.
// ---------------------------------------------------------------------------

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils, Controls, Forms, Graphics, ExtCtrls, StdCtrls, Menus,
  ArdWinMap;

type
  TWmGotoEvent = procedure(const AFileName: string; ALine: Integer) of object;
  TWmOpenEvent = procedure(AMap: TWmMap; ANode: TWmNode) of object;
  TWmFillEvent = procedure(AMap: TWmMap) of object;

  TArdWinMapForm = class;

  // Холст карты
  TWmBox = class(TCustomControl)
  private
    FOwnerForm: TArdWinMapForm;
    FRects: array of TRect;          // по номерам узлов карты
    FSelfText: array of string;      // переходы внутри окна - под узлом
    FSelfRects: array of TRect;
    FEdgeShown: array of Boolean;
    FLabelRects: array of TRect;     // подписи стрелок
    FEdgeFrom, FEdgeTo: array of TPoint;
    FDragNode: Integer;
    FDragDX, FDragDY: Integer;
    FDownX, FDownY: Integer;
    FDragged: Boolean;
    FHotNode, FHotEdge: Integer;
    FSelNode: Integer;
    procedure CalcRects;
    procedure CalcEdges;
    function NodeAt(AX, AY: Integer): Integer;
    function EdgeAt(AX, AY: Integer): Integer;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      PosX, PosY: Integer); override;
    procedure MouseMove(Shift: TShiftState; PosX, PosY: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      PosX, PosY: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Rebuild;
  end;

  TArdWinMapForm = class(TForm)
  private
    FMap: TWmMap;
    FBox: TWmBox;
    FScroll: TScrollBox;
    FTop: TPanel;
    FStatus: TLabel;
    FShowHome: TCheckBox;
    FPopup: TPopupMenu;
    FPopupNode: Integer;
    FMapFile: string;
    FSketchFile: string;
    FOnGoto: TWmGotoEvent;
    FOnOpenWindow: TWmOpenEvent;
    FOnFill: TWmFillEvent;
    FCurrentState: Integer;
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnLayoutClick(Sender: TObject);
    procedure ShowHomeClick(Sender: TObject);
    procedure PopupOpenClick(Sender: TObject);
    procedure PopupCodeClick(Sender: TObject);
    procedure PopupCaseClick(Sender: TObject);
    procedure SetStatus(const AText: string);
    procedure NodeClick(ANodeIdx: Integer);
    procedure EdgeClick(AEdgeIdx: Integer);
    procedure NodeMenu(ANodeIdx: Integer; const AScreenPos: TPoint);
    procedure HoverInfo(ANodeIdx, AEdgeIdx: Integer);
    procedure SavePositions;
    function HomeNode: TWmNode;
    procedure SetCurrentState(AValue: Integer);
  public
    constructor CreateMap(AOwner: TComponent);
    destructor Destroy; override;
    // Разобрать скетч заново (OnFill даёт файлы) и нарисовать
    procedure RefreshMap;
    property Map: TWmMap read FMap;
    property SketchFile: string read FSketchFile write FSketchFile;
    property MapFile: string read FMapFile write FMapFile;
    property OnGoto: TWmGotoEvent read FOnGoto write FOnGoto;
    property OnOpenWindow: TWmOpenEvent read FOnOpenWindow write FOnOpenWindow;
    property OnFill: TWmFillEvent read FOnFill write FOnFill;
    // Номер окна, открытого в эмуляторе (рамка узла), -1 - нет
    property CurrentState: Integer read FCurrentState write SetCurrentState;
  end;

implementation

uses
  Math;

const
  CellW = 210;
  CellH = 66;
  BoxMinW = 120;
  BoxH = 38;

  ClrBack = $00FFFFFF;
  ClrWindow = $00FBEFE3;     // голубой (BGR)
  ClrWindowEdge = $00A0704A;
  ClrModal = $00D9F6FF;
  ClrSetup = $00EEEEEE;
  ClrUnreach = $00E2E2E2;
  ClrMissing = $00DDDDFF;
  ClrMenuLine = $00803C1E;
  ClrCodeLine = $00505050;
  ClrCallLine = $00007A9C;
  ClrMissLine = $000000C0;
  ClrSelect = $00D77800;
  ClrCurrent = $0000A000;

{ TWmBox }

constructor TWmBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDragNode := -1;
  FHotNode := -1;
  FHotEdge := -1;
  FSelNode := -1;
  Color := ClrBack;
  DoubleBuffered := True;
end;

procedure TWmBox.CalcRects;
var
  Map: TWmMap;
  NodeIdx, EdgeIdx, TextW, MaxRight, MaxBottom: Integer;
  Node: TWmNode;
  Edge: TWmEdge;
  Part: string;
begin
  Map := FOwnerForm.FMap;
  SetLength(FRects, Map.NodeCount);
  SetLength(FSelfText, Map.NodeCount);
  SetLength(FSelfRects, Map.NodeCount);
  for NodeIdx := 0 to Map.NodeCount - 1 do
    FSelfText[NodeIdx] := '';
  // переходы внутри окна: "< actRepeat, F1 actHelp"
  for EdgeIdx := 0 to Map.EdgeCount - 1 do
  begin
    Edge := Map.Edges[EdgeIdx];
    if Edge.FromNode <> Edge.ToNode then
      Continue;
    NodeIdx := 0;
    while (NodeIdx < Map.NodeCount) and (Map.Nodes[NodeIdx] <> Edge.FromNode) do
      Inc(NodeIdx);
    Part := Edge.Keys;
    if Edge.Action <> '' then
      Part := Part + ' ' + Edge.Action;
    if Length(Part) > 30 then
      Part := Copy(Part, 1, 28) + '..';
    if FSelfText[NodeIdx] = '' then
      FSelfText[NodeIdx] := 'в окне: ' + Part
    else
      FSelfText[NodeIdx] := FSelfText[NodeIdx] + '; ' + Part;
  end;
  MaxRight := 0;
  MaxBottom := 0;
  Canvas.Font.Size := 9;
  for NodeIdx := 0 to Map.NodeCount - 1 do
  begin
    Node := Map.Nodes[NodeIdx];
    Canvas.Font.Style := [fsBold];
    TextW := Canvas.TextWidth(Node.Title);
    Canvas.Font.Style := [];
    TextW := Max(TextW, Canvas.TextWidth(Node.Caption));
    TextW := Min(CellW - 30, Max(BoxMinW, TextW + 14));
    FRects[NodeIdx] := Rect(Node.PosX, Node.PosY, Node.PosX + TextW, Node.PosY + BoxH);
    FSelfRects[NodeIdx] := Rect(0, 0, 0, 0);
    if FSelfText[NodeIdx] <> '' then
    begin
      Canvas.Font.Size := 8;
      FSelfRects[NodeIdx] := Rect(Node.PosX, Node.PosY + BoxH + 1,
        Node.PosX + Canvas.TextWidth(FSelfText[NodeIdx]) + 4,
        Node.PosY + BoxH + 1 + Canvas.TextHeight('Wg'));
      Canvas.Font.Size := 9;
    end;
    MaxRight := Max(MaxRight, Max(FRects[NodeIdx].Right, FSelfRects[NodeIdx].Right));
    MaxBottom := Max(MaxBottom, FRects[NodeIdx].Bottom + 20);
  end;
  SetBounds(Left, Top, Max(MaxRight + 60, 400), Max(MaxBottom + 40, 300));
end;

// Точка выхода стрелки из прямоугольника ARect: от его центра к ATarget
function BorderPoint(const ARect: TRect; const ATarget: TPoint): TPoint;
var
  CenterX, CenterY, DeltaX, DeltaY: Double;
  ScaleX, ScaleY, Scale: Double;
begin
  CenterX := (ARect.Left + ARect.Right) / 2;
  CenterY := (ARect.Top + ARect.Bottom) / 2;
  DeltaX := ATarget.X - CenterX;
  DeltaY := ATarget.Y - CenterY;
  if (Abs(DeltaX) < 0.5) and (Abs(DeltaY) < 0.5) then
  begin
    Result := Point(Round(CenterX), Round(CenterY));
    Exit;
  end;
  if Abs(DeltaX) > 0.5 then
    ScaleX := ((ARect.Right - ARect.Left) / 2) / Abs(DeltaX)
  else
    ScaleX := 1E9;
  if Abs(DeltaY) > 0.5 then
    ScaleY := ((ARect.Bottom - ARect.Top) / 2) / Abs(DeltaY)
  else
    ScaleY := 1E9;
  Scale := Min(ScaleX, ScaleY);
  Result := Point(Round(CenterX + DeltaX * Scale), Round(CenterY + DeltaY * Scale));
end;

function RectCenter(const ARect: TRect): TPoint;
begin
  Result := Point((ARect.Left + ARect.Right) div 2, (ARect.Top + ARect.Bottom) div 2);
end;

procedure TWmBox.CalcEdges;
var
  Map: TWmMap;
  EdgeIdx, OtherIdx, FromIdx, ToIdx, ShiftX, ShiftY, TextW, TextH: Integer;
  Edge, Other: TWmEdge;
  Home: TWmNode;
  FromPt, ToPt, MidPt: TPoint;
  Len: Double;
  Reverse: Boolean;
begin
  Map := FOwnerForm.FMap;
  Home := FOwnerForm.HomeNode;
  SetLength(FEdgeShown, Map.EdgeCount);
  SetLength(FLabelRects, Map.EdgeCount);
  SetLength(FEdgeFrom, Map.EdgeCount);
  SetLength(FEdgeTo, Map.EdgeCount);
  Canvas.Font.Size := 8;
  Canvas.Font.Style := [];
  TextH := Canvas.TextHeight('Wg');
  for EdgeIdx := 0 to Map.EdgeCount - 1 do
  begin
    Edge := Map.Edges[EdgeIdx];
    FEdgeShown[EdgeIdx] := (Edge.FromNode <> Edge.ToNode) and
      (FOwnerForm.FShowHome.Checked or (Edge.ToNode <> Home) or
       (Edge.FromNode.Kind = wnkSetup));
    FLabelRects[EdgeIdx] := Rect(0, 0, 0, 0);
    if not FEdgeShown[EdgeIdx] then
      Continue;
    FromIdx := 0;
    while Map.Nodes[FromIdx] <> Edge.FromNode do
      Inc(FromIdx);
    ToIdx := 0;
    while Map.Nodes[ToIdx] <> Edge.ToNode do
      Inc(ToIdx);
    FromPt := BorderPoint(FRects[FromIdx], RectCenter(FRects[ToIdx]));
    ToPt := BorderPoint(FRects[ToIdx], RectCenter(FRects[FromIdx]));
    // встречная стрелка - обе в сторону, чтобы не слились
    Reverse := False;
    for OtherIdx := 0 to Map.EdgeCount - 1 do
    begin
      Other := Map.Edges[OtherIdx];
      if (Other.FromNode = Edge.ToNode) and (Other.ToNode = Edge.FromNode) then
      begin
        Reverse := True;
        Break;
      end;
    end;
    if Reverse then
    begin
      Len := Sqrt(Sqr(ToPt.X - FromPt.X) + Sqr(ToPt.Y - FromPt.Y));
      if Len > 1 then
      begin
        ShiftX := Round(-(ToPt.Y - FromPt.Y) / Len * 5);
        ShiftY := Round((ToPt.X - FromPt.X) / Len * 5);
        FromPt := Point(FromPt.X + ShiftX, FromPt.Y + ShiftY);
        ToPt := Point(ToPt.X + ShiftX, ToPt.Y + ShiftY);
      end;
    end;
    FEdgeFrom[EdgeIdx] := FromPt;
    FEdgeTo[EdgeIdx] := ToPt;
    if Edge.Keys <> '' then
    begin
      // подпись - ближе к началу: у окна с многими выходами они не на одной точке
      MidPt := Point(FromPt.X + (ToPt.X - FromPt.X) * 2 div 5,
                     FromPt.Y + (ToPt.Y - FromPt.Y) * 2 div 5);
      TextW := Canvas.TextWidth(Edge.Keys);
      FLabelRects[EdgeIdx] := Rect(MidPt.X - TextW div 2 - 2, MidPt.Y - TextH div 2,
                                   MidPt.X + TextW div 2 + 2, MidPt.Y + TextH div 2 + 1);
    end;
  end;
end;

procedure TWmBox.Rebuild;
begin
  FHotNode := -1;
  FHotEdge := -1;
  if FSelNode >= FOwnerForm.FMap.NodeCount then
    FSelNode := -1;
  CalcRects;
  CalcEdges;
  Invalidate;
end;

procedure DrawArrowHead(ACanvas: TCanvas; const AFrom, ATo: TPoint);
var
  Angle: Double;
  Points: array[0..2] of TPoint;
begin
  Angle := ArcTan2(ATo.Y - AFrom.Y, ATo.X - AFrom.X);
  Points[0] := ATo;
  Points[1] := Point(Round(ATo.X - 10 * Cos(Angle - 0.4)), Round(ATo.Y - 10 * Sin(Angle - 0.4)));
  Points[2] := Point(Round(ATo.X - 10 * Cos(Angle + 0.4)), Round(ATo.Y - 10 * Sin(Angle + 0.4)));
  ACanvas.Pen.Style := psSolid;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := ACanvas.Pen.Color;
  ACanvas.Polygon(Points);
end;

procedure TWmBox.Paint;
var
  Map: TWmMap;
  NodeIdx, EdgeIdx, TextY: Integer;
  Node: TWmNode;
  Edge: TWmEdge;
  BoxRect: TRect;
  LineColor: TColor;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := ClrBack;
  Canvas.FillRect(ClientRect);
  if FOwnerForm = nil then
    Exit;
  Map := FOwnerForm.FMap;
  if (Length(FRects) <> Map.NodeCount) or (Length(FEdgeShown) <> Map.EdgeCount) then
    Exit;
  // стрелки
  for EdgeIdx := 0 to Map.EdgeCount - 1 do
  begin
    if not FEdgeShown[EdgeIdx] then
      Continue;
    Edge := Map.Edges[EdgeIdx];
    case Edge.Kind of
      wekMenu:
        LineColor := ClrMenuLine;
      wekCall:
        LineColor := ClrCallLine;
    else
      LineColor := ClrCodeLine;
    end;
    if Edge.ToNode.Kind = wnkMissing then
      LineColor := ClrMissLine;
    if EdgeIdx = FHotEdge then
      LineColor := ClrSelect;
    Canvas.Pen.Color := LineColor;
    Canvas.Pen.Width := 1;
    case Edge.Kind of
      wekCode:
        Canvas.Pen.Style := psDash;
      wekCall:
        Canvas.Pen.Style := psDot;
    else
      Canvas.Pen.Style := psSolid;
    end;
    Canvas.Brush.Style := bsClear;
    Canvas.MoveTo(FEdgeFrom[EdgeIdx].X, FEdgeFrom[EdgeIdx].Y);
    Canvas.LineTo(FEdgeTo[EdgeIdx].X, FEdgeTo[EdgeIdx].Y);
    DrawArrowHead(Canvas, FEdgeFrom[EdgeIdx], FEdgeTo[EdgeIdx]);
  end;
  // узлы
  Canvas.Pen.Style := psSolid;
  for NodeIdx := 0 to Map.NodeCount - 1 do
  begin
    Node := Map.Nodes[NodeIdx];
    BoxRect := FRects[NodeIdx];
    case Node.Kind of
      wnkModal:
        Canvas.Brush.Color := ClrModal;
      wnkSetup:
        Canvas.Brush.Color := ClrSetup;
      wnkMissing:
        Canvas.Brush.Color := ClrMissing;
    else
      if Node.Reachable then
        Canvas.Brush.Color := ClrWindow
      else
        Canvas.Brush.Color := ClrUnreach;
    end;
    Canvas.Brush.Style := bsSolid;
    if NodeIdx = FSelNode then
    begin
      Canvas.Pen.Color := ClrSelect;
      Canvas.Pen.Width := 2;
    end
    else if (Node.Kind = wnkWindow) and (Node.State = FOwnerForm.FCurrentState) then
    begin
      Canvas.Pen.Color := ClrCurrent;
      Canvas.Pen.Width := 3;
    end
    else
    begin
      Canvas.Pen.Color := ClrWindowEdge;
      if Node.Kind = wnkMissing then
        Canvas.Pen.Color := ClrMissLine;
      Canvas.Pen.Width := 1;
    end;
    if NodeIdx = FHotNode then
      Canvas.Pen.Width := Canvas.Pen.Width + 1;
    Canvas.RoundRect(BoxRect.Left, BoxRect.Top, BoxRect.Right, BoxRect.Bottom, 10, 10);
    Canvas.Pen.Width := 1;
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Size := 9;
    Canvas.Font.Style := [fsBold];
    if Node.Kind = wnkMissing then
      Canvas.Font.Color := ClrMissLine
    else if (Node.Kind = wnkWindow) and not Node.Reachable then
      Canvas.Font.Color := $00707070
    else
      Canvas.Font.Color := clBlack;
    TextY := BoxRect.Top + 3;
    Canvas.TextRect(Rect(BoxRect.Left + 4, TextY, BoxRect.Right - 4, BoxRect.Bottom - 2),
                    BoxRect.Left + 7, TextY, Node.Title);
    Canvas.Font.Style := [];
    Canvas.TextRect(Rect(BoxRect.Left + 4, TextY, BoxRect.Right - 4, BoxRect.Bottom - 2),
                    BoxRect.Left + 7, TextY + Canvas.TextHeight('Wg'), Node.Caption);
    if FSelfText[NodeIdx] <> '' then
    begin
      Canvas.Font.Size := 8;
      Canvas.Font.Color := $00505050;
      Canvas.TextOut(FSelfRects[NodeIdx].Left + 2, FSelfRects[NodeIdx].Top, FSelfText[NodeIdx]);
    end;
  end;
  // подписи стрелок - поверх
  Canvas.Font.Size := 8;
  Canvas.Font.Style := [];
  for EdgeIdx := 0 to Map.EdgeCount - 1 do
  begin
    if not FEdgeShown[EdgeIdx] or (FLabelRects[EdgeIdx].Right = 0) then
      Continue;
    Edge := Map.Edges[EdgeIdx];
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := ClrBack;
    Canvas.Pen.Style := psClear;
    Canvas.FillRect(FLabelRects[EdgeIdx]);
    Canvas.Pen.Style := psSolid;
    Canvas.Brush.Style := bsClear;
    if EdgeIdx = FHotEdge then
      Canvas.Font.Color := ClrSelect
    else if Edge.ToNode.Kind = wnkMissing then
      Canvas.Font.Color := ClrMissLine
    else
      Canvas.Font.Color := clBlack;
    Canvas.TextOut(FLabelRects[EdgeIdx].Left + 2, FLabelRects[EdgeIdx].Top, Edge.Keys);
  end;
end;

function PtIn(const ARect: TRect; AX, AY: Integer): Boolean;
begin
  Result := (AX >= ARect.Left) and (AX < ARect.Right) and (AY >= ARect.Top) and
            (AY < ARect.Bottom);
end;

function TWmBox.NodeAt(AX, AY: Integer): Integer;
var
  NodeIdx: Integer;
begin
  // верхний - последний нарисованный
  for NodeIdx := Length(FRects) - 1 downto 0 do
    if PtIn(FRects[NodeIdx], AX, AY) or PtIn(FSelfRects[NodeIdx], AX, AY) then
    begin
      Result := NodeIdx;
      Exit;
    end;
  Result := -1;
end;

function SegmentDistance(const AFrom, ATo: TPoint; AX, AY: Integer): Double;
var
  DeltaX, DeltaY, Part: Double;
begin
  DeltaX := ATo.X - AFrom.X;
  DeltaY := ATo.Y - AFrom.Y;
  if (DeltaX = 0) and (DeltaY = 0) then
    Part := 0
  else
    Part := ((AX - AFrom.X) * DeltaX + (AY - AFrom.Y) * DeltaY) / (DeltaX * DeltaX + DeltaY * DeltaY);
  Part := Max(0, Min(1, Part));
  Result := Sqrt(Sqr(AFrom.X + Part * DeltaX - AX) + Sqr(AFrom.Y + Part * DeltaY - AY));
end;

function TWmBox.EdgeAt(AX, AY: Integer): Integer;
var
  EdgeIdx: Integer;
begin
  for EdgeIdx := Length(FEdgeShown) - 1 downto 0 do
    if FEdgeShown[EdgeIdx] and PtIn(FLabelRects[EdgeIdx], AX, AY) then
    begin
      Result := EdgeIdx;
      Exit;
    end;
  for EdgeIdx := Length(FEdgeShown) - 1 downto 0 do
    if FEdgeShown[EdgeIdx] and
       (SegmentDistance(FEdgeFrom[EdgeIdx], FEdgeTo[EdgeIdx], AX, AY) <= 4) then
    begin
      Result := EdgeIdx;
      Exit;
    end;
  Result := -1;
end;

procedure TWmBox.MouseDown(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
var
  NodeIdx: Integer;
begin
  inherited MouseDown(Button, Shift, PosX, PosY);
  if CanFocus then
    SetFocus;
  NodeIdx := NodeAt(PosX, PosY);
  if Button = mbRight then
  begin
    if NodeIdx >= 0 then
      FOwnerForm.NodeMenu(NodeIdx, ClientToScreen(Point(PosX, PosY)));
    Exit;
  end;
  if Button <> mbLeft then
    Exit;
  FDownX := PosX;
  FDownY := PosY;
  FDragged := False;
  FDragNode := -1;
  if (NodeIdx >= 0) and PtIn(FRects[NodeIdx], PosX, PosY) then
  begin
    FDragNode := NodeIdx;
    FDragDX := PosX - FOwnerForm.FMap.Nodes[NodeIdx].PosX;
    FDragDY := PosY - FOwnerForm.FMap.Nodes[NodeIdx].PosY;
    MouseCapture := True;
  end;
end;

procedure TWmBox.MouseMove(Shift: TShiftState; PosX, PosY: Integer);
var
  Node: TWmNode;
  NodeIdx, EdgeIdx: Integer;
begin
  inherited MouseMove(Shift, PosX, PosY);
  if FDragNode >= 0 then
  begin
    if not FDragged and (Abs(PosX - FDownX) + Abs(PosY - FDownY) < 4) then
      Exit;
    FDragged := True;
    Node := FOwnerForm.FMap.Nodes[FDragNode];
    Node.PosX := Max(0, PosX - FDragDX);
    Node.PosY := Max(0, PosY - FDragDY);
    Node.PosSet := True;
    CalcRects;
    CalcEdges;
    Invalidate;
    Exit;
  end;
  NodeIdx := NodeAt(PosX, PosY);
  EdgeIdx := -1;
  if NodeIdx < 0 then
    EdgeIdx := EdgeAt(PosX, PosY);
  if (NodeIdx <> FHotNode) or (EdgeIdx <> FHotEdge) then
  begin
    FHotNode := NodeIdx;
    FHotEdge := EdgeIdx;
    if (NodeIdx >= 0) or (EdgeIdx >= 0) then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
    FOwnerForm.HoverInfo(NodeIdx, EdgeIdx);
    Invalidate;
  end;
end;

procedure TWmBox.MouseUp(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
var
  NodeIdx, EdgeIdx: Integer;
begin
  inherited MouseUp(Button, Shift, PosX, PosY);
  if Button <> mbLeft then
    Exit;
  MouseCapture := False;
  if FDragNode >= 0 then
  begin
    NodeIdx := FDragNode;
    FDragNode := -1;
    if FDragged then
    begin
      FOwnerForm.SavePositions;
      Exit;
    end;
    FSelNode := NodeIdx;
    Invalidate;
    FOwnerForm.NodeClick(NodeIdx);
    Exit;
  end;
  NodeIdx := NodeAt(PosX, PosY);
  if NodeIdx >= 0 then
  begin
    // строка переходов внутри окна - первый такой переход
    for EdgeIdx := 0 to FOwnerForm.FMap.EdgeCount - 1 do
      if (FOwnerForm.FMap.Edges[EdgeIdx].FromNode = FOwnerForm.FMap.Nodes[NodeIdx]) and
         (FOwnerForm.FMap.Edges[EdgeIdx].ToNode = FOwnerForm.FMap.Nodes[NodeIdx]) then
      begin
        FOwnerForm.EdgeClick(EdgeIdx);
        Exit;
      end;
    Exit;
  end;
  EdgeIdx := EdgeAt(PosX, PosY);
  if EdgeIdx >= 0 then
    FOwnerForm.EdgeClick(EdgeIdx);
end;

{ TArdWinMapForm }

constructor TArdWinMapForm.CreateMap(AOwner: TComponent);
var
  Button: TButton;
  MenuItem: TMenuItem;
begin
  inherited CreateNew(AOwner);
  Caption := 'Карта окон';
  Width := 1100;
  Height := 700;
  Position := poScreenCenter;
  FCurrentState := -1;
  FMap := TWmMap.Create;

  FTop := TPanel.Create(Self);
  FTop.Parent := Self;
  FTop.Align := alTop;
  FTop.Height := 34;
  FTop.BevelOuter := bvNone;

  Button := TButton.Create(Self);
  Button.Parent := FTop;
  Button.SetBounds(6, 5, 96, 24);
  Button.Caption := 'Обновить';
  Button.Hint := 'Разобрать скетч заново (файлы с диска)';
  Button.ShowHint := True;
  Button.OnClick := BtnRefreshClick;

  Button := TButton.Create(Self);
  Button.Parent := FTop;
  Button.SetBounds(108, 5, 110, 24);
  Button.Caption := 'Расставить';
  Button.Hint := 'Расставить все узлы заново: столбцы по числу переходов от setup()';
  Button.ShowHint := True;
  Button.OnClick := BtnLayoutClick;

  FShowHome := TCheckBox.Create(Self);
  FShowHome.Parent := FTop;
  FShowHome.SetBounds(230, 8, 230, 20);
  FShowHome.Caption := 'Переходы в начальное окно';
  FShowHome.Hint := 'Стрелки в Win0 (клавиша #) из каждого окна';
  FShowHome.ShowHint := True;
  FShowHome.Checked := False;
  FShowHome.OnClick := ShowHomeClick;

  FStatus := TLabel.Create(Self);
  FStatus.Parent := Self;
  FStatus.Align := alBottom;
  FStatus.Height := 20;
  FStatus.AutoSize := False;
  FStatus.Layout := tlCenter;
  FStatus.Caption := '';

  FScroll := TScrollBox.Create(Self);
  FScroll.Parent := Self;
  FScroll.Align := alClient;
  FScroll.Color := ClrBack;
  FScroll.HorzScrollBar.Tracking := True;
  FScroll.VertScrollBar.Tracking := True;

  FBox := TWmBox.Create(Self);
  FBox.FOwnerForm := Self;
  FBox.Parent := FScroll;
  FBox.SetBounds(0, 0, 800, 600);

  FPopup := TPopupMenu.Create(Self);
  MenuItem := TMenuItem.Create(FPopup);
  MenuItem.Caption := 'Открыть в эмуляторе';
  MenuItem.OnClick := PopupOpenClick;
  FPopup.Items.Add(MenuItem);
  MenuItem := TMenuItem.Create(FPopup);
  MenuItem.Caption := 'Перейти к функции';
  MenuItem.OnClick := PopupCodeClick;
  FPopup.Items.Add(MenuItem);
  MenuItem := TMenuItem.Create(FPopup);
  MenuItem.Caption := 'Перейти к case';
  MenuItem.OnClick := PopupCaseClick;
  FPopup.Items.Add(MenuItem);
end;

destructor TArdWinMapForm.Destroy;
begin
  FMap.Free;
  inherited Destroy;
end;

procedure TArdWinMapForm.SetStatus(const AText: string);
begin
  FStatus.Caption := '  ' + AText;
end;

function TArdWinMapForm.HomeNode: TWmNode;
var
  EdgeIdx: Integer;
begin
  // окно, куда ведёт старт из setup()
  for EdgeIdx := 0 to FMap.EdgeCount - 1 do
    if (FMap.Edges[EdgeIdx].FromNode.Kind = wnkSetup) and
       (FMap.Edges[EdgeIdx].Keys = 'старт') then
    begin
      Result := FMap.Edges[EdgeIdx].ToNode;
      Exit;
    end;
  Result := nil;
end;

procedure TArdWinMapForm.RefreshMap;
var
  OldMap: TWmMap;
  WindowTotal, NodeIdx: Integer;
begin
  OldMap := FMap;
  FMap := TWmMap.Create;
  OldMap.Free;
  if Assigned(FOnFill) then
    FOnFill(FMap);
  FMap.Parse;
  if FMapFile <> '' then
    FMap.LoadPositions(FMapFile);
  FMap.AutoLayout(CellW, CellH, True);
  FBox.FSelNode := -1;
  FBox.Rebuild;
  Caption := 'Карта окон - ' + ExtractFileName(FSketchFile);
  if FMap.StateVar = '' then
  begin
    SetStatus('В скетче нет switch (Переменная) с тремя и больше ветками ' +
              'case N: Функция(); - окон не найдено');
    Exit;
  end;
  WindowTotal := 0;
  for NodeIdx := 0 to FMap.NodeCount - 1 do
    if FMap.Nodes[NodeIdx].Kind = wnkWindow then
      Inc(WindowTotal);
  SetStatus(IntToStr(WindowTotal) + ' окон, переменная ' + FMap.StateVar +
            '. Щелчок по окну - открыть в эмуляторе, по стрелке - строка ' +
            'перехода; узлы перетаскиваются');
end;

procedure TArdWinMapForm.BtnRefreshClick(Sender: TObject);
begin
  RefreshMap;
end;

procedure TArdWinMapForm.BtnLayoutClick(Sender: TObject);
begin
  FMap.AutoLayout(CellW, CellH, False);
  FBox.Rebuild;
  SavePositions;
end;

procedure TArdWinMapForm.ShowHomeClick(Sender: TObject);
begin
  FBox.Rebuild;
end;

procedure TArdWinMapForm.SavePositions;
begin
  if FMapFile = '' then
    Exit;
  try
    FMap.SavePositions(FMapFile);
  except
    on Err: Exception do
      SetStatus('Места узлов не записаны: ' + Err.Message);
  end;
end;

procedure TArdWinMapForm.SetCurrentState(AValue: Integer);
begin
  if AValue = FCurrentState then
    Exit;
  FCurrentState := AValue;
  FBox.Invalidate;
end;

procedure TArdWinMapForm.NodeClick(ANodeIdx: Integer);
var
  Node: TWmNode;
begin
  Node := FMap.Nodes[ANodeIdx];
  if (Node.FileName <> '') and Assigned(FOnGoto) then
    FOnGoto(Node.FileName, Node.Line)
  else if (Node.CaseFile <> '') and Assigned(FOnGoto) then
    FOnGoto(Node.CaseFile, Node.CaseLine);
  case Node.Kind of
    wnkWindow:
      if Assigned(FOnOpenWindow) then
      begin
        SetStatus('Эмулятор: окно ' + Node.FuncName + ' (' + FMap.StateVar + ' = ' +
                  IntToStr(Node.State) + ')');
        FOnOpenWindow(FMap, Node);
      end;
    wnkModal:
      SetStatus(Node.FuncName + '() вызывается из окна напрямую - в эмуляторе ' +
                'откройте окно, которое её вызывает');
    wnkMissing:
      SetStatus('Номер ' + IntToStr(Node.State) + ': ветки case нет - переход ' +
                'на него оставит скетч без окна');
  end;
end;

procedure TArdWinMapForm.EdgeClick(AEdgeIdx: Integer);
var
  Edge: TWmEdge;
begin
  Edge := FMap.Edges[AEdgeIdx];
  if (Edge.FileName <> '') and Assigned(FOnGoto) then
    FOnGoto(Edge.FileName, Edge.Line);
end;

procedure TArdWinMapForm.HoverInfo(ANodeIdx, AEdgeIdx: Integer);
const
  KindText: array[TWmEdgeKind] of string = ('меню', 'код', 'вызов');
var
  Node: TWmNode;
  Edge: TWmEdge;
  Text: string;
begin
  if ANodeIdx >= 0 then
  begin
    Node := FMap.Nodes[ANodeIdx];
    Text := Node.Title;
    if Node.Caption <> '' then
      Text := Text + ' - ' + Node.Caption;
    if Node.FileName <> '' then
      Text := Text + '   ' + ExtractFileName(Node.FileName) + ':' + IntToStr(Node.Line + 1);
    if (Node.Kind = wnkWindow) and not Node.Reachable then
      Text := Text + '   (нет перехода от setup)';
    SetStatus(Text);
  end
  else if AEdgeIdx >= 0 then
  begin
    Edge := FMap.Edges[AEdgeIdx];
    Text := Edge.FromNode.Key + ' -> ' + Edge.ToNode.Key + ': ' + Edge.Keys +
            '   (' + KindText[Edge.Kind] + ', ' + ExtractFileName(Edge.FileName) + ':' +
            IntToStr(Edge.Line + 1) + ')';
    if Edge.Cond <> '' then
      Text := Text + '   if (' + Edge.Cond + ')';
    SetStatus(Text);
  end;
end;

procedure TArdWinMapForm.NodeMenu(ANodeIdx: Integer; const AScreenPos: TPoint);
begin
  FPopupNode := ANodeIdx;
  FPopup.Items[0].Enabled := FMap.Nodes[ANodeIdx].Kind = wnkWindow;
  FPopup.Items[1].Enabled := FMap.Nodes[ANodeIdx].FileName <> '';
  FPopup.Items[2].Enabled := FMap.Nodes[ANodeIdx].CaseFile <> '';
  FPopup.Popup(AScreenPos.X, AScreenPos.Y);
end;

procedure TArdWinMapForm.PopupOpenClick(Sender: TObject);
begin
  if (FPopupNode >= 0) and (FPopupNode < FMap.NodeCount) and Assigned(FOnOpenWindow) then
    FOnOpenWindow(FMap, FMap.Nodes[FPopupNode]);
end;

procedure TArdWinMapForm.PopupCodeClick(Sender: TObject);
var
  Node: TWmNode;
begin
  if (FPopupNode < 0) or (FPopupNode >= FMap.NodeCount) then
    Exit;
  Node := FMap.Nodes[FPopupNode];
  if (Node.FileName <> '') and Assigned(FOnGoto) then
    FOnGoto(Node.FileName, Node.Line);
end;

procedure TArdWinMapForm.PopupCaseClick(Sender: TObject);
var
  Node: TWmNode;
begin
  if (FPopupNode < 0) or (FPopupNode >= FMap.NodeCount) then
    Exit;
  Node := FMap.Nodes[FPopupNode];
  if (Node.CaseFile <> '') and Assigned(FOnGoto) then
    FOnGoto(Node.CaseFile, Node.CaseLine);
end;

end.
