unit ArdWinDesigner;

// ---------------------------------------------------------------------------
//  Конструктор окон скетча (Arduino - Window Designer).
//
//  Слева - все окна (снимки из ArdWinShots) в порядке дерева карты окон.
//  В центре - прибор эмулятора (его ставит сюда владелец:
//  TArdSimPanel.PlaceDevice(DeviceHost)), правка надписей - как в окне
//  эмулятора. По бокам от прибора - соседи текущего окна: «Откуда» (окна,
//  из которых есть переход сюда) и «Куда» (куда ведут его клавиши), с
//  клавишами. Щелчок по любому снимку - открыть это окно в эмуляторе
//  (OnOpenWindow делает владелец).
// ---------------------------------------------------------------------------

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils, Controls, Forms, Graphics, ExtCtrls, StdCtrls,
  ArdWinMap, ArdWinMapView, ArdWinShots;

type
  TArdWinDesignerForm = class;
  TWdPickEvent = procedure(ANode: TWmNode) of object;

  // Столбец снимков окон: заголовок, клавиша, миниатюра
  TWdThumbList = class(TCustomControl)
  private
    FOwnerForm: TArdWinDesignerForm;
    FNodes: TList;
    FKeys: TStringList;          // подпись клавиши по номерам FNodes
    FIndents: array of Integer;
    FHotIdx: Integer;
    FOnPick: TWdPickEvent;
    FOnGoto: TWdPickEvent;
    function ItemAt(AY: Integer): Integer;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; PosX, PosY: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      PosX, PosY: Integer); override;
    procedure DblClick; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    procedure AddItem(ANode: TWmNode; const AKeys: string; AIndent: Integer);
    procedure Finish;            // высота по числу строк
    property OnPick: TWdPickEvent read FOnPick write FOnPick;
    property OnGoto: TWdPickEvent read FOnGoto write FOnGoto;
  end;

  TArdWinDesignerForm = class(TForm)
  private
    FMap: TWmMap;
    FSketchFile: string;
    FShotDir: string;
    FCurrentState: Integer;
    FThumbKeys: TStringList;     // ключ узла -> TBitmap
    FListBox, FFromBox, FToBox: TScrollBox;
    FList, FFromList, FToList: TWdThumbList;
    FRightPanel, FCenter: TPanel;
    FDeviceHost: TPanel;
    FTitle, FStatus: TLabel;
    FWindowsCombo: TComboBox;
    FComboNodes: TList;
    FBtnShots: TButton;
    FOnFill: TWmFillEvent;
    FOnOpenWindow: TWmOpenEvent;
    FOnGoto: TWmGotoEvent;
    FOnShots: TNotifyEvent;
    FOnShotCurrent: TNotifyEvent;
    FOnShowMap: TNotifyEvent;
    FOnDeviceResize: TNotifyEvent;
    FOnClosed: TNotifyEvent;
    FOnNewWindow: TNotifyEvent;
    function MakeColumn(AParent: TWinControl; AAlign: TAlign;
      const ACaption: string; var AList: TWdThumbList): TScrollBox;
    function MakeButton(const ACaption, AHint: string; ATop: Integer;
      AClick: TNotifyEvent): TButton;
    procedure FreeThumbs;
    procedure FillWindowList;
    procedure FillNeighbours;
    procedure PickNode(ANode: TWmNode);
    procedure GotoNode(ANode: TWmNode);
    procedure DeviceHostResize(Sender: TObject);
    procedure FormClosed(Sender: TObject; var Action: TCloseAction);
    procedure BtnShotsClick(Sender: TObject);
    procedure BtnShotCurrentClick(Sender: TObject);
    procedure BtnMapClick(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnNewClick(Sender: TObject);
    procedure ComboSelect(Sender: TObject);
    procedure SetCurrentState(AValue: Integer);
    function NodeOfState(AState: Integer): TWmNode;
  public
    constructor CreateDesigner(AOwner: TComponent);
    destructor Destroy; override;
    // Разобрать скетч заново (OnFill даёт файлы), снимки - из ShotDir
    procedure RefreshMap;
    procedure ReloadShots;
    function ThumbOf(ANode: TWmNode): TBitmap;
    // Начальное окно скетча (куда ведёт старт из setup()), -1 - нет
    function HomeState: Integer;
    procedure SetShotsBusy(ABusy: Boolean);
    procedure ShowStatus(const AText: string);
    property Map: TWmMap read FMap;
    property SketchFile: string read FSketchFile write FSketchFile;
    property ShotDir: string read FShotDir write FShotDir;
    // Окно, открытое в эмуляторе: заголовок, соседи, рамка в списке
    property CurrentState: Integer read FCurrentState write SetCurrentState;
    // Сюда владелец ставит прибор эмулятора
    property DeviceHost: TPanel read FDeviceHost;
    property OnFill: TWmFillEvent read FOnFill write FOnFill;
    property OnOpenWindow: TWmOpenEvent read FOnOpenWindow write FOnOpenWindow;
    property OnGoto: TWmGotoEvent read FOnGoto write FOnGoto;
    property OnShots: TNotifyEvent read FOnShots write FOnShots;
    property OnShotCurrent: TNotifyEvent read FOnShotCurrent write FOnShotCurrent;
    property OnShowMap: TNotifyEvent read FOnShowMap write FOnShowMap;
    property OnDeviceResize: TNotifyEvent read FOnDeviceResize write FOnDeviceResize;
    // Окно закрыто: владелец возвращает прибор на панель эмулятора
    property OnClosed: TNotifyEvent read FOnClosed write FOnClosed;
    // «Создать новое окно»: панель настройки и правку скетча делает владелец
    property OnNewWindow: TNotifyEvent read FOnNewWindow write FOnNewWindow;
  end;

implementation

uses
  Math;

const
  ThumbW = 160;
  ThumbH = 107;
  ItemTitleH = 34;               // имя окна и клавиша
  ItemH = ItemTitleH + ThumbH + 10;
  ItemW = ThumbW + 16;
  IndentStep = 6;
  MaxIndent = 4;
  ColumnW = ItemW + 2 + MaxIndent * IndentStep + 26; // с полосой прокрутки

  ClrBack = $00FFFFFF;
  ClrItem = $00FBEFE3;
  ClrItemEdge = $00A0704A;
  ClrCurrent = $0000A000;
  ClrHot = $00D77800;
  ClrModal = $00D9F6FF;
  ClrMissing = $00DDDDFF;

{ TWdThumbList }

constructor TWdThumbList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNodes := TList.Create;
  FKeys := TStringList.Create;
  FHotIdx := -1;
  Color := ClrBack;
  DoubleBuffered := True;
  Width := ItemW;
  Height := 40;
end;

destructor TWdThumbList.Destroy;
begin
  FKeys.Free;
  FNodes.Free;
  inherited Destroy;
end;

procedure TWdThumbList.Clear;
begin
  FNodes.Clear;
  FKeys.Clear;
  SetLength(FIndents, 0);
  FHotIdx := -1;
end;

procedure TWdThumbList.AddItem(ANode: TWmNode; const AKeys: string; AIndent: Integer);
begin
  FNodes.Add(ANode);
  FKeys.Add(AKeys);
  SetLength(FIndents, FNodes.Count);
  FIndents[FNodes.Count - 1] := Min(AIndent, MaxIndent) * IndentStep;
end;

procedure TWdThumbList.Finish;
begin
  Height := Max(40, FNodes.Count * ItemH + 6);
  Invalidate;
end;

function TWdThumbList.ItemAt(AY: Integer): Integer;
begin
  Result := (AY - 3) div ItemH;
  if (AY < 3) or (Result >= FNodes.Count) then
    Result := -1;
end;

procedure TWdThumbList.Paint;
var
  ItemIdx, TopY, LeftX: Integer;
  Node: TWmNode;
  BoxRect, PicRect: TRect;
  Thumb: TBitmap;
  Text: string;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := ClrBack;
  Canvas.FillRect(ClientRect);
  if FNodes.Count = 0 then
  begin
    Canvas.Font.Size := 8;
    Canvas.Font.Color := $00808080;
    Canvas.TextOut(6, 8, '(нет)');
    Exit;
  end;
  for ItemIdx := 0 to FNodes.Count - 1 do
  begin
    Node := TWmNode(FNodes[ItemIdx]);
    TopY := 3 + ItemIdx * ItemH;
    LeftX := 2 + FIndents[ItemIdx];
    BoxRect := Rect(LeftX, TopY, Min(ClientWidth - 2, LeftX + ItemW - 4), TopY + ItemH - 6);
    case Node.Kind of
      wnkModal:
        Canvas.Brush.Color := ClrModal;
      wnkMissing:
        Canvas.Brush.Color := ClrMissing;
    else
      Canvas.Brush.Color := ClrItem;
    end;
    if (Node.Kind = wnkWindow) and (Node.State = FOwnerForm.FCurrentState) then
    begin
      Canvas.Pen.Color := ClrCurrent;
      Canvas.Pen.Width := 3;
    end
    else if ItemIdx = FHotIdx then
    begin
      Canvas.Pen.Color := ClrHot;
      Canvas.Pen.Width := 2;
    end
    else
    begin
      Canvas.Pen.Color := ClrItemEdge;
      Canvas.Pen.Width := 1;
    end;
    Canvas.RoundRect(BoxRect.Left, BoxRect.Top, BoxRect.Right, BoxRect.Bottom, 8, 8);
    Canvas.Pen.Width := 1;
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Size := 8;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := clBlack;
    Text := Node.Title;
    if FKeys[ItemIdx] <> '' then
      Text := Text + '   [' + FKeys[ItemIdx] + ']';
    Canvas.TextRect(Rect(BoxRect.Left + 3, TopY + 2, BoxRect.Right - 3, TopY + 17),
                    BoxRect.Left + 5, TopY + 3, Text);
    Canvas.Font.Style := [];
    Canvas.TextRect(Rect(BoxRect.Left + 3, TopY + 17, BoxRect.Right - 3, TopY + 32),
                    BoxRect.Left + 5, TopY + 17, Node.Caption);
    PicRect := Rect(BoxRect.Left + (BoxRect.Right - BoxRect.Left - ThumbW) div 2,
                    TopY + ItemTitleH, 0, 0);
    PicRect.Right := PicRect.Left + ThumbW;
    PicRect.Bottom := PicRect.Top + ThumbH;
    Thumb := FOwnerForm.ThumbOf(Node);
    Canvas.Brush.Style := bsSolid;
    if Thumb <> nil then
      Canvas.Draw(PicRect.Left, PicRect.Top, Thumb)
    else
    begin
      Canvas.Brush.Color := $00303030;
      Canvas.FillRect(PicRect);
      Canvas.Font.Color := $00C0C0C0;
      case Node.Kind of
        wnkWindow:
          Text := 'нет снимка';
        wnkModal:
          Text := 'вызов из окна';
        wnkMissing:
          Text := 'нет такого окна';
      else
        Text := '';
      end;
      Canvas.TextOut(PicRect.Left + 6, PicRect.Top + 6, Text);
    end;
  end;
end;

procedure TWdThumbList.MouseMove(Shift: TShiftState; PosX, PosY: Integer);
var
  ItemIdx: Integer;
begin
  inherited MouseMove(Shift, PosX, PosY);
  ItemIdx := ItemAt(PosY);
  if ItemIdx <> FHotIdx then
  begin
    FHotIdx := ItemIdx;
    if ItemIdx >= 0 then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TWdThumbList.MouseUp(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
var
  ItemIdx: Integer;
begin
  inherited MouseUp(Button, Shift, PosX, PosY);
  if Button <> mbLeft then
    Exit;
  ItemIdx := ItemAt(PosY);
  if (ItemIdx >= 0) and Assigned(FOnPick) then
    FOnPick(TWmNode(FNodes[ItemIdx]));
end;

procedure TWdThumbList.DblClick;
var
  ItemIdx: Integer;
  CursorPos: TPoint;
begin
  inherited DblClick;
  CursorPos := ScreenToClient(Mouse.CursorPos);
  ItemIdx := ItemAt(CursorPos.Y);
  if (ItemIdx >= 0) and Assigned(FOnGoto) then
    FOnGoto(TWmNode(FNodes[ItemIdx]));
end;

{ TArdWinDesignerForm }

constructor TArdWinDesignerForm.CreateDesigner(AOwner: TComponent);
var
  Caption2: TLabel;
begin
  inherited CreateNew(AOwner);
  Caption := 'Конструктор окон';
  Position := poDesigned;
  Left := Screen.WorkAreaLeft + 4;
  Top := Screen.WorkAreaTop + 4;
  Width := Min(1500, Screen.WorkAreaWidth - 8);
  Height := Screen.WorkAreaHeight - 8;
  OnClose := FormClosed;
  FCurrentState := -1;
  FMap := TWmMap.Create;
  FThumbKeys := TStringList.Create;
  FComboNodes := TList.Create;

  FStatus := TLabel.Create(Self);
  FStatus.Parent := Self;
  FStatus.Align := alBottom;
  FStatus.AutoSize := False;
  FStatus.Height := 20;
  FStatus.Layout := tlCenter;
  FStatus.Caption := '';

  FListBox := MakeColumn(Self, alLeft, 'Окна', FList);

  // справа - действия
  FRightPanel := TPanel.Create(Self);
  FRightPanel.Parent := Self;
  FRightPanel.Align := alRight;
  FRightPanel.Width := 200;
  FRightPanel.BevelOuter := bvNone;
  MakeButton('Создать новое окно', 'Новое пустое окно: переход в него из ' +
    'предыдущего окна, выход - в следующее', 10, BtnNewClick);
  MakeButton('Снимок текущего', 'Записать снимок экрана эмулятора для ' +
    'текущего окна (после правки надписей)', 44, BtnShotCurrentClick);
  FBtnShots := MakeButton('Снимки всех окон', 'Открыть каждое окно в ' +
    'эмуляторе и записать снимок (около секунды на окно)', 78, BtnShotsClick);
  MakeButton('Карта окон', 'Открыть карту окон', 112, BtnMapClick);
  MakeButton('Обновить', 'Разобрать скетч заново (файлы с диска)', 146,
    BtnRefreshClick);
  Caption2 := TLabel.Create(Self);
  Caption2.Parent := FRightPanel;
  Caption2.SetBounds(10, 190, 180, 18);
  Caption2.Caption := 'Перейти в окно:';
  FWindowsCombo := TComboBox.Create(Self);
  FWindowsCombo.Parent := FRightPanel;
  FWindowsCombo.SetBounds(10, 210, 180, 24);
  FWindowsCombo.Style := csDropDownList;
  FWindowsCombo.DropDownCount := 30;
  FWindowsCombo.OnChange := ComboSelect;

  FCenter := TPanel.Create(Self);
  FCenter.Parent := Self;
  FCenter.Align := alClient;
  FCenter.BevelOuter := bvNone;

  FFromBox := MakeColumn(FCenter, alLeft, 'Откуда', FFromList);
  FToBox := MakeColumn(FCenter, alRight, 'Куда', FToList);

  FTitle := TLabel.Create(Self);
  FTitle.Parent := FCenter;
  FTitle.Align := alTop;
  FTitle.AutoSize := False;
  FTitle.Height := 28;
  FTitle.Layout := tlCenter;
  FTitle.Alignment := taCenter;
  FTitle.Font.Size := 11;
  FTitle.Font.Style := [fsBold];
  FTitle.Caption := '';

  FDeviceHost := TPanel.Create(Self);
  FDeviceHost.Parent := FCenter;
  FDeviceHost.Align := alClient;
  FDeviceHost.BevelOuter := bvNone;
  FDeviceHost.Caption := '';
  FDeviceHost.OnResize := DeviceHostResize;
end;

destructor TArdWinDesignerForm.Destroy;
begin
  FreeThumbs;
  FThumbKeys.Free;
  FComboNodes.Free;
  FMap.Free;
  inherited Destroy;
end;

function TArdWinDesignerForm.MakeColumn(AParent: TWinControl; AAlign: TAlign;
  const ACaption: string; var AList: TWdThumbList): TScrollBox;
var
  Head, Holder: TPanel;
begin
  Holder := TPanel.Create(Self);
  Holder.Parent := AParent;
  Holder.Align := AAlign;
  Holder.Width := ColumnW;
  Holder.BevelOuter := bvNone;
  // заголовок - панель: TLabel с alTop в панели gtk2 не рисует
  Head := TPanel.Create(Self);
  Head.Parent := Holder;
  Head.Align := alTop;
  Head.Height := 24;
  Head.BevelOuter := bvNone;
  Head.Alignment := taCenter;
  Head.Font.Size := 9;
  Head.Font.Style := [fsBold];
  Head.Caption := ACaption;
  Result := TScrollBox.Create(Self);
  Result.Parent := Holder;
  Result.Align := alClient;
  Result.Color := ClrBack;
  Result.HorzScrollBar.Visible := False;
  Result.VertScrollBar.Tracking := True;
  AList := TWdThumbList.Create(Self);
  AList.FOwnerForm := Self;
  AList.Parent := Result;
  AList.SetBounds(0, 0, ItemW + 2 + MaxIndent * IndentStep, 40);
  AList.OnPick := PickNode;
  AList.OnGoto := GotoNode;
end;

function TArdWinDesignerForm.MakeButton(const ACaption, AHint: string; ATop: Integer;
  AClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := FRightPanel;
  Result.SetBounds(10, ATop, 180, 26);
  Result.Caption := ACaption;
  Result.Hint := AHint;
  Result.ShowHint := True;
  Result.OnClick := AClick;
end;

procedure TArdWinDesignerForm.FreeThumbs;
var
  ThumbIdx: Integer;
begin
  for ThumbIdx := 0 to FThumbKeys.Count - 1 do
    FThumbKeys.Objects[ThumbIdx].Free;
  FThumbKeys.Clear;
end;

procedure TArdWinDesignerForm.ReloadShots;
var
  NodeIdx: Integer;
  Node: TWmNode;
begin
  FreeThumbs;
  if FShotDir <> '' then
    for NodeIdx := 0 to FMap.NodeCount - 1 do
    begin
      Node := FMap.Nodes[NodeIdx];
      if Node.Kind = wnkWindow then
        FThumbKeys.AddObject(Node.Key,
          LoadShotThumb(WinShotFile(FShotDir, Node.State), ThumbW, ThumbH));
    end;
  FList.Invalidate;
  FFromList.Invalidate;
  FToList.Invalidate;
end;

function TArdWinDesignerForm.ThumbOf(ANode: TWmNode): TBitmap;
var
  KeyIdx: Integer;
begin
  Result := nil;
  KeyIdx := FThumbKeys.IndexOf(ANode.Key);
  if KeyIdx >= 0 then
    Result := TBitmap(FThumbKeys.Objects[KeyIdx]);
end;

procedure TArdWinDesignerForm.RefreshMap;
var
  OldMap: TWmMap;
begin
  // списки держат узлы прежней карты - сначала очистить
  FList.Clear;
  FFromList.Clear;
  FToList.Clear;
  FComboNodes.Clear;
  OldMap := FMap;
  FMap := TWmMap.Create;
  OldMap.Free;
  if Assigned(FOnFill) then
    FOnFill(FMap);
  FMap.Parse;
  Caption := 'Конструктор окон - ' + ExtractFileName(FSketchFile);
  ReloadShots;
  FillWindowList;
  // соседи и выбор в списке «Перейти в окно» - по новой карте
  SetCurrentState(FCurrentState);
  if FMap.StateVar = '' then
    ShowStatus('В скетче нет switch с окнами')
  else
    ShowStatus('Щелчок по снимку - открыть окно в эмуляторе, двойной щелчок - ' +
               'перейти к функции окна');
end;

procedure TArdWinDesignerForm.FillWindowList;
var
  Order: TList;
  NodeIdx: Integer;
  Node: TWmNode;
begin
  FList.Clear;
  FWindowsCombo.Items.Clear;
  FComboNodes.Clear;
  Order := TList.Create;
  try
    FMap.TreeOrder(Order);
    for NodeIdx := 0 to Order.Count - 1 do
    begin
      Node := TWmNode(Order[NodeIdx]);
      if Node.Kind <> wnkWindow then
        Continue;
      FList.AddItem(Node, '', Max(0, Node.Depth - 1));
      FWindowsCombo.Items.Add(Node.Title + '  ' + Node.Caption);
      FComboNodes.Add(Node);
    end;
  finally
    Order.Free;
  end;
  FList.Finish;
end;

// Соседи текущего окна по стрелкам карты; клавиши одного соседа - вместе
procedure TArdWinDesignerForm.FillNeighbours;
var
  Current, Other: TWmNode;
  EdgeIdx, ItemIdx: Integer;
  Edge: TWmEdge;
  FromNodes, ToNodes: TList;
  FromKeys, ToKeys: TStringList;

  procedure AddKey(ANodes: TList; AKeys: TStringList; ANode: TWmNode; const AKey: string);
  var
    Found: Integer;
  begin
    Found := ANodes.IndexOf(ANode);
    if Found < 0 then
    begin
      ANodes.Add(ANode);
      AKeys.Add(AKey);
    end
    else if (AKey <> '') and (Pos(AKey, AKeys[Found]) = 0) then
    begin
      if AKeys[Found] = '' then
        AKeys[Found] := AKey
      else
        AKeys[Found] := AKeys[Found] + ', ' + AKey;
    end;
  end;

begin
  FFromList.Clear;
  FToList.Clear;
  Current := NodeOfState(FCurrentState);
  if Current = nil then
  begin
    FTitle.Caption := '';
    FFromList.Finish;
    FToList.Finish;
    Exit;
  end;
  FTitle.Caption := Current.Title + '   ' + Current.Caption;
  FromNodes := TList.Create;
  ToNodes := TList.Create;
  FromKeys := TStringList.Create;
  ToKeys := TStringList.Create;
  try
    for EdgeIdx := 0 to FMap.EdgeCount - 1 do
    begin
      Edge := FMap.Edges[EdgeIdx];
      if Edge.FromNode = Edge.ToNode then
        Continue;
      if Edge.ToNode = Current then
        AddKey(FromNodes, FromKeys, Edge.FromNode, Edge.Keys)
      else if Edge.FromNode = Current then
        AddKey(ToNodes, ToKeys, Edge.ToNode, Edge.Keys);
    end;
    for ItemIdx := 0 to FromNodes.Count - 1 do
    begin
      Other := TWmNode(FromNodes[ItemIdx]);
      FFromList.AddItem(Other, FromKeys[ItemIdx], 0);
    end;
    for ItemIdx := 0 to ToNodes.Count - 1 do
    begin
      Other := TWmNode(ToNodes[ItemIdx]);
      FToList.AddItem(Other, ToKeys[ItemIdx], 0);
    end;
  finally
    ToKeys.Free;
    FromKeys.Free;
    ToNodes.Free;
    FromNodes.Free;
  end;
  FFromList.Finish;
  FToList.Finish;
end;

function TArdWinDesignerForm.NodeOfState(AState: Integer): TWmNode;
var
  NodeIdx: Integer;
begin
  for NodeIdx := 0 to FMap.NodeCount - 1 do
  begin
    Result := FMap.Nodes[NodeIdx];
    if (Result.Kind = wnkWindow) and (Result.State = AState) then
      Exit;
  end;
  Result := nil;
end;

function TArdWinDesignerForm.HomeState: Integer;
var
  EdgeIdx: Integer;
begin
  Result := -1;
  for EdgeIdx := 0 to FMap.EdgeCount - 1 do
    if (FMap.Edges[EdgeIdx].FromNode.Kind = wnkSetup) and
       (FMap.Edges[EdgeIdx].Keys = 'старт') and
       (FMap.Edges[EdgeIdx].ToNode.Kind = wnkWindow) then
    begin
      Result := FMap.Edges[EdgeIdx].ToNode.State;
      Exit;
    end;
end;

procedure TArdWinDesignerForm.SetCurrentState(AValue: Integer);
var
  ComboIdx: Integer;
begin
  FCurrentState := AValue;
  FillNeighbours;
  FList.Invalidate;
  FWindowsCombo.OnChange := nil;
  FWindowsCombo.ItemIndex := -1;
  for ComboIdx := 0 to FComboNodes.Count - 1 do
    if TWmNode(FComboNodes[ComboIdx]).State = AValue then
      FWindowsCombo.ItemIndex := ComboIdx;
  FWindowsCombo.OnChange := ComboSelect;
end;

procedure TArdWinDesignerForm.PickNode(ANode: TWmNode);
begin
  case ANode.Kind of
    wnkWindow:
      if Assigned(FOnOpenWindow) then
      begin
        ShowStatus('Эмулятор: окно ' + ANode.FuncName + ' (' + FMap.StateVar +
                   ' = ' + IntToStr(ANode.State) + ')');
        FOnOpenWindow(FMap, ANode);
      end;
    wnkModal:
      ShowStatus(ANode.FuncName + '() вызывается из окна напрямую - откройте ' +
                 'окно, которое её вызывает');
    wnkMissing:
      ShowStatus('Номер ' + IntToStr(ANode.State) + ': ветки case нет');
    wnkSetup:
      ShowStatus('setup() - начало скетча');
  end;
end;

procedure TArdWinDesignerForm.GotoNode(ANode: TWmNode);
begin
  if (ANode.FileName <> '') and Assigned(FOnGoto) then
    FOnGoto(ANode.FileName, ANode.Line);
end;

procedure TArdWinDesignerForm.DeviceHostResize(Sender: TObject);
begin
  if Assigned(FOnDeviceResize) then
    FOnDeviceResize(Self);
end;

procedure TArdWinDesignerForm.FormClosed(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
  if Assigned(FOnClosed) then
    FOnClosed(Self);
end;

procedure TArdWinDesignerForm.BtnShotsClick(Sender: TObject);
begin
  if Assigned(FOnShots) then
    FOnShots(Self);
end;

procedure TArdWinDesignerForm.BtnShotCurrentClick(Sender: TObject);
begin
  if Assigned(FOnShotCurrent) then
    FOnShotCurrent(Self);
end;

procedure TArdWinDesignerForm.BtnMapClick(Sender: TObject);
begin
  if Assigned(FOnShowMap) then
    FOnShowMap(Self);
end;

procedure TArdWinDesignerForm.BtnRefreshClick(Sender: TObject);
begin
  RefreshMap;
end;

procedure TArdWinDesignerForm.BtnNewClick(Sender: TObject);
begin
  if Assigned(FOnNewWindow) then
    FOnNewWindow(Self);
end;

procedure TArdWinDesignerForm.ComboSelect(Sender: TObject);
begin
  if (FWindowsCombo.ItemIndex >= 0) and (FWindowsCombo.ItemIndex < FComboNodes.Count) then
    PickNode(TWmNode(FComboNodes[FWindowsCombo.ItemIndex]));
end;

procedure TArdWinDesignerForm.SetShotsBusy(ABusy: Boolean);
begin
  if ABusy then
    FBtnShots.Caption := 'Остановить снимки'
  else
    FBtnShots.Caption := 'Снимки всех окон';
end;

procedure TArdWinDesignerForm.ShowStatus(const AText: string);
begin
  FStatus.Caption := '  ' + AText;
end;

end.
