// ---------------------------------------------------------------------------
//  RqLcl: QGAUGE (свой элемент TRqGauge), QTABCONTROL (TTabControl),
//  QTREEVIEW (TTreeView), QSTATUSBAR (TStatusBar), QFILELISTBOX
//  (TFileListBox) - свойства и методы, которых нет в RTTI LCL или которые
//  у RapidQ другие.
//
//  Пункты дерева и панели строки состояния - по номеру: свойства
//  "Item.Text", "Item.ImageIndex"..., "Panel.Caption", "Panel.Width"...
//  через RqGetItemStr / RqGetItemInt. Номер пункта дерева - сквозной
//  (AbsoluteIndex), как в RapidQ.
// ---------------------------------------------------------------------------
unit rqlclmore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Controls, StdCtrls, ComCtrls, FileCtrl, Forms,
  Graphics, LazUTF8;

type
  // QGAUGE: полоса хода (как TGauge Delphi, на котором QGauge RapidQ):
  // ForeColor - заполненная часть, BackColor - фон, ShowText - процент.
  // Kind: 0 gkText, 1 gkHorizontalBar, 2 gkVerticalBar, 3 gkPie,
  // 4 gkNeedle.
  TRqGauge = class(TGraphicControl)
  private
    FMinValue: Integer;
    FMaxValue: Integer;
    FPosition: Integer;
    FForeColor: TColor;
    FBackColor: TColor;
    FShowText: Boolean;
    FKind: Integer;
    FBorderStyle: TBorderStyle;
    procedure SetMinValue(AValue: Integer);
    procedure SetMaxValue(AValue: Integer);
    procedure SetPosition(AValue: Integer);
    procedure SetForeColor(AValue: TColor);
    procedure SetBackColor(AValue: TColor);
    procedure SetShowText(AValue: Boolean);
    procedure SetKind(AValue: Integer);
    procedure SetBorderStyle(AValue: TBorderStyle);
    function Percent: Integer;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Min: Integer read FMinValue write SetMinValue;
    property Max: Integer read FMaxValue write SetMaxValue;
    property Position: Integer read FPosition write SetPosition;
    property ForeColor: TColor read FForeColor write SetForeColor;
    property BackColor: TColor read FBackColor write SetBackColor;
    property ShowText: Boolean read FShowText write SetShowText;
    property Kind: Integer read FKind write SetKind;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle;
    property Align;
    property Color;
    property Cursor;
    property Enabled;
    property Font;
    property Hint;
    property ParentShowHint;
    property ShowHint;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

function MoreGetInt(AObj: TObject; const AProp: string;
                    out AValue: Integer): Boolean;
function MoreSetInt(AObj: TObject; const AProp: string;
                    AValue: Integer): Boolean;
function MoreGetStr(AObj: TObject; const AProp: string;
                    out AValue: string): Boolean;
function MoreSetStr(AObj: TObject; const AProp: string;
                    const AValue: string): Boolean;
function MoreGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     out AValue: string): Boolean;
function MoreSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     const AValue: string): Boolean;
function MoreGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        out AValue: Integer): Boolean;
function MoreSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        AValue: Integer): Boolean;
function MoreCallEx(AObj: TObject; const AMethod, AStr: string;
                    AInt1, AInt2, AInt3: Integer;
                    out AIntResult: Integer): Boolean;
// Начальные значения как в RapidQ
procedure MoreInitNew(AObj: TObject);
procedure MoreBeforeParent(AObj, AParent: TObject);
procedure MoreAfterParent(AObj: TObject);

implementation

type
  // Значения, которые только запоминаются (у LCL их нет)
  TRqMoreExtra = class(TComponent)
  public
    ShowIcons: Integer;
    FlatSeperators: Integer;
    FocusButtons: Integer;
    VerticalTabs: Integer;
  end;

function ExtraOf(AComp: TComponent): TRqMoreExtra;
var
  CompIdx: Integer;
begin
  for CompIdx := 0 to AComp.ComponentCount - 1 do
    if AComp.Components[CompIdx] is TRqMoreExtra then
    begin
      Result := TRqMoreExtra(AComp.Components[CompIdx]);
      Exit;
    end;
  Result := TRqMoreExtra.Create(AComp);
end;

procedure CheckIndex(const AWhat: string; AIndex, ACount: Integer);
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise Exception.Create(AWhat + '(' + IntToStr(AIndex) + '): out of 0..' +
                           IntToStr(ACount - 1));
end;

function NodeOf(ATree: TCustomTreeView; AIndex: Integer): TTreeNode;
begin
  CheckIndex('Item', AIndex, ATree.Items.Count);
  Result := ATree.Items[AIndex];
end;

function NodeIndex(ANode: TTreeNode): Integer;
begin
  if ANode = nil then
    Result := -1
  else
    Result := ANode.AbsoluteIndex;
end;

function PanelOf(ABar: TStatusBar; AIndex: Integer): TStatusPanel;
begin
  CheckIndex('Panel', AIndex, ABar.Panels.Count);
  Result := ABar.Panels[AIndex];
end;

function ReadWholeFile(const AFileName: string): string;
var
  Source: TFileStream;
begin
  Source := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, Source.Size);
    if Length(Result) > 0 then
      Source.ReadBuffer(Result[1], Length(Result));
  finally
    Source.Free;
  end;
end;

procedure WriteWholeFile(const AFileName, AData: string);
var
  Dest: TFileStream;
begin
  Dest := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(AData) > 0 then
      Dest.WriteBuffer(AData[1], Length(AData));
  finally
    Dest.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  TRqGauge
// ---------------------------------------------------------------------------

constructor TRqGauge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMinValue := 0;
  FMaxValue := 100;
  FPosition := 0;
  FForeColor := clBlack;
  FBackColor := clWhite;
  FShowText := True;
  FKind := 1;
  FBorderStyle := bsSingle;
  SetInitialBounds(0, 0, 100, 100);
end;

function TRqGauge.Percent: Integer;
begin
  if FMaxValue <= FMinValue then
    Result := 0
  else
    Result := Round((FPosition - FMinValue) * 100 / (FMaxValue - FMinValue));
  if Result < 0 then
    Result := 0;
  if Result > 100 then
    Result := 100;
end;

procedure TRqGauge.SetMinValue(AValue: Integer);
begin
  if FMinValue = AValue then
    Exit;
  FMinValue := AValue;
  Invalidate;
end;

procedure TRqGauge.SetMaxValue(AValue: Integer);
begin
  if FMaxValue = AValue then
    Exit;
  FMaxValue := AValue;
  Invalidate;
end;

procedure TRqGauge.SetPosition(AValue: Integer);
begin
  if AValue < FMinValue then
    AValue := FMinValue;
  if AValue > FMaxValue then
    AValue := FMaxValue;
  if FPosition = AValue then
    Exit;
  FPosition := AValue;
  Invalidate;
end;

procedure TRqGauge.SetForeColor(AValue: TColor);
begin
  FForeColor := AValue;
  Invalidate;
end;

procedure TRqGauge.SetBackColor(AValue: TColor);
begin
  FBackColor := AValue;
  Invalidate;
end;

procedure TRqGauge.SetShowText(AValue: Boolean);
begin
  FShowText := AValue;
  Invalidate;
end;

procedure TRqGauge.SetKind(AValue: Integer);
begin
  FKind := AValue;
  Invalidate;
end;

procedure TRqGauge.SetBorderStyle(AValue: TBorderStyle);
begin
  FBorderStyle := AValue;
  Invalidate;
end;

procedure TRqGauge.Paint;
var
  Area, FillRect: TRect;
  PercentText: string;
  TextSize: TSize;
  CenterX, CenterY, Radius: Integer;
  Angle: Double;
begin
  Area := ClientRect;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FBackColor;
  if FBorderStyle = bsSingle then
  begin
    Canvas.Pen.Color := clBlack;
    Canvas.Rectangle(Area);
    InflateRect(Area, -1, -1);
  end
  else
    Canvas.FillRect(Area);
  case FKind of
    1, 2:
      begin
        FillRect := Area;
        if FKind = 1 then
          FillRect.Right := Area.Left + (Area.Right - Area.Left) * Percent div 100
        else
          FillRect.Top := Area.Bottom - (Area.Bottom - Area.Top) * Percent div 100;
        Canvas.Brush.Color := FForeColor;
        Canvas.FillRect(FillRect);
      end;
    3, 4:
      begin
        CenterX := (Area.Left + Area.Right) div 2;
        CenterY := (Area.Top + Area.Bottom) div 2;
        Radius := (Area.Right - Area.Left) div 2;
        if (Area.Bottom - Area.Top) div 2 < Radius then
          Radius := (Area.Bottom - Area.Top) div 2;
        Angle := Percent * 2 * Pi / 100;
        Canvas.Pen.Color := FForeColor;
        if FKind = 3 then
        begin
          Canvas.Brush.Color := FForeColor;
          if Percent >= 100 then
            Canvas.Ellipse(CenterX - Radius, CenterY - Radius,
                           CenterX + Radius, CenterY + Radius)
          else if Percent > 0 then
            Canvas.Pie(CenterX - Radius, CenterY - Radius, CenterX + Radius,
                       CenterY + Radius,
                       CenterX + Round(Radius * Sin(Angle)),
                       CenterY - Round(Radius * Cos(Angle)),
                       CenterX, CenterY - Radius);
        end
        else
        begin
          // стрелка по полукругу слева направо
          Angle := Pi - Percent * Pi / 100;
          Canvas.Line(CenterX, Area.Bottom - 2,
                      CenterX + Round(Radius * Cos(Angle)),
                      Area.Bottom - 2 - Round(Radius * Sin(Angle)));
        end;
      end;
  end;
  if FShowText then
  begin
    PercentText := IntToStr(Percent) + '%';
    Canvas.Font := Font;
    Canvas.Brush.Style := bsClear;
    TextSize := Canvas.TextExtent(PercentText);
    Canvas.TextOut((Area.Left + Area.Right - TextSize.cx) div 2,
                   (Area.Top + Area.Bottom - TextSize.cy) div 2, PercentText);
  end;
end;

// ---------------------------------------------------------------------------

procedure MoreInitNew(AObj: TObject);
begin
  // QSTATUSBAR: с AutoSize LCL при показе формы создаёт окно строки
  // состояния без родителя - "Can't create top-level child window"
  // (проверено под Wine). Высота - обычная для Windows при 96 dpi.
  if AObj is TStatusBar then
  begin
    TStatusBar(AObj).AutoSize := False;
    TStatusBar(AObj).Height := 22;
  end;
end;

// Перед Parent - пока ничего
procedure MoreBeforeParent(AObj, AParent: TObject);
begin
end;

// Элемент получил Parent. QFILELISTBOX: список файлов текущей папки (до
// Parent окна у списка нет, и заполнение дало бы ошибку)
procedure MoreAfterParent(AObj: TObject);
begin
  if (AObj is TCustomFileListBox) and (TControl(AObj).Parent <> nil) then
    TFileListBox(AObj).UpdateFileList;
end;

function MoreGetInt(AObj: TObject; const AProp: string;
                    out AValue: Integer): Boolean;
var
  Prop: string;
begin
  Result := True;
  AValue := 0;
  Prop := UpperCase(AProp);
  if AObj is TCustomTreeView then
  begin
    if Prop = 'ITEMCOUNT' then
      AValue := TCustomTreeView(AObj).Items.Count
    else if Prop = 'ITEMINDEX' then
      AValue := NodeIndex(TCustomTreeView(AObj).Selected)
    else if Prop = 'TOPINDEX' then
      AValue := NodeIndex(TCustomTreeView(AObj).TopItem)
    else
      Result := False;
  end
  else if AObj is TTabControl then
  begin
    if Prop = 'TABCOUNT' then
      AValue := TTabControl(AObj).Tabs.Count
    else if Prop = 'BUTTONSTYLE' then
      AValue := Ord(TTabControl(AObj).Style <> tsTabs)
    else if Prop = 'FLATBUTTONS' then
      AValue := Ord(TTabControl(AObj).Style = tsFlatButtons)
    else if Prop = 'FLATSEPERATORS' then
      AValue := ExtraOf(TComponent(AObj)).FlatSeperators
    else if Prop = 'FOCUSBUTTONS' then
      AValue := ExtraOf(TComponent(AObj)).FocusButtons
    else if Prop = 'VERTICALTABS' then
      AValue := ExtraOf(TComponent(AObj)).VerticalTabs
    else
      Result := False;
  end
  else if AObj is TStatusBar then
  begin
    if Prop = 'PANELCOUNT' then
      AValue := TStatusBar(AObj).Panels.Count
    else
      Result := False;
  end
  else if AObj is TCustomFileListBox then
  begin
    if Prop = 'SHOWICONS' then
      AValue := ExtraOf(TComponent(AObj)).ShowIcons
    else
      Result := False;
  end
  else
    Result := False;
end;

function MoreSetInt(AObj: TObject; const AProp: string;
                    AValue: Integer): Boolean;
var
  Prop: string;
  Tree: TCustomTreeView;
begin
  Result := True;
  Prop := UpperCase(AProp);
  if AObj is TCustomTreeView then
  begin
    Tree := TCustomTreeView(AObj);
    if Prop = 'ITEMINDEX' then
    begin
      if AValue < 0 then
        Tree.Selected := nil
      else
        Tree.Selected := NodeOf(Tree, AValue);
    end
    else if Prop = 'TOPINDEX' then
      Tree.TopItem := NodeOf(Tree, AValue)
    else
      Result := False;
  end
  else if AObj is TTabControl then
  begin
    if Prop = 'BUTTONSTYLE' then
    begin
      if AValue <> 0 then
        TTabControl(AObj).Style := tsButtons
      else
        TTabControl(AObj).Style := tsTabs;
    end
    else if Prop = 'FLATBUTTONS' then
    begin
      if AValue <> 0 then
        TTabControl(AObj).Style := tsFlatButtons
      else if TTabControl(AObj).Style = tsFlatButtons then
        TTabControl(AObj).Style := tsButtons;
    end
    // У LCL нет - запоминается
    else if Prop = 'FLATSEPERATORS' then
      ExtraOf(TComponent(AObj)).FlatSeperators := AValue
    else if Prop = 'FOCUSBUTTONS' then
      ExtraOf(TComponent(AObj)).FocusButtons := AValue
    else if Prop = 'VERTICALTABS' then
      ExtraOf(TComponent(AObj)).VerticalTabs := AValue
    else
      Result := False;
  end
  else if AObj is TCustomFileListBox then
  begin
    if Prop = 'SHOWICONS' then
      ExtraOf(TComponent(AObj)).ShowIcons := AValue
    else
      Result := False;
  end
  else
    Result := False;
end;

function MoreGetStr(AObj: TObject; const AProp: string;
                    out AValue: string): Boolean;
var
  Prop, ItemText: string;
  ItemNum: Integer;
begin
  Result := False;
  AValue := '';
  Prop := UpperCase(AProp);
  if (AObj is TCustomFileListBox) and (Prop = 'DRIVE') then
  begin
    AValue := TFileListBox(AObj).Drive;
    Result := True;
  end
  else if (AObj is TCustomFileListBox) and (Prop = 'FILENAME') then
  begin
    // Выбранный файл с путём - по текущему ItemIndex (LCL обновляет
    // FileName только по щелчку)
    Result := True;
    ItemNum := TFileListBox(AObj).ItemIndex;
    if (ItemNum < 0) or (ItemNum >= TFileListBox(AObj).Items.Count) then
      Exit;
    ItemText := TFileListBox(AObj).Items[ItemNum];
    if (Length(ItemText) > 1) and (ItemText[1] = '[') and
       (ItemText[Length(ItemText)] = ']') then
      ItemText := Copy(ItemText, 2, Length(ItemText) - 2);
    AValue := UTF8ToWinCP(IncludeTrailingPathDelimiter(
                TFileListBox(AObj).Directory) + ItemText);
  end;
end;

function MoreSetStr(AObj: TObject; const AProp: string;
                    const AValue: string): Boolean;
var
  Prop, MaskText: string;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if (AObj is TCustomFileListBox) and (Prop = 'DRIVE') then
  begin
    if AValue <> '' then
      TFileListBox(AObj).Drive := AValue[1];
    Result := True;
  end
  else if (AObj is TCustomFileListBox) and (Prop = 'MASK') then
  begin
    // "*.*" в Windows (и RapidQ) - все файлы, в масках LCL - только имена
    // с точкой: заменяется на "*"
    MaskText := ';' + WinCPToUTF8(AValue) + ';';
    while Pos(';*.*;', MaskText) > 0 do
      MaskText := StringReplace(MaskText, ';*.*;', ';*;', []);
    TFileListBox(AObj).Mask := Copy(MaskText, 2, Length(MaskText) - 2);
    Result := True;
  end;
end;

// Строка по номеру: Item(i).Text дерева, Tab(i), Panel(i).Caption
function MoreGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     out AValue: string): Boolean;
var
  Prop: string;
begin
  Result := True;
  AValue := '';
  Prop := UpperCase(AProp);
  if (AObj is TCustomTreeView) and (Prop = 'ITEM.TEXT') then
    AValue := UTF8ToWinCP(NodeOf(TCustomTreeView(AObj), AIndex).Text)
  else if (AObj is TTabControl) and (Prop = 'TAB') then
  begin
    CheckIndex('Tab', AIndex, TTabControl(AObj).Tabs.Count);
    AValue := UTF8ToWinCP(TTabControl(AObj).Tabs[AIndex]);
  end
  else if (AObj is TStatusBar) and (Prop = 'PANEL.CAPTION') then
    AValue := UTF8ToWinCP(PanelOf(TStatusBar(AObj), AIndex).Text)
  else
    Result := False;
end;

function MoreSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     const AValue: string): Boolean;
var
  Prop: string;
begin
  Result := True;
  Prop := UpperCase(AProp);
  if (AObj is TCustomTreeView) and (Prop = 'ITEM.TEXT') then
    NodeOf(TCustomTreeView(AObj), AIndex).Text := WinCPToUTF8(AValue)
  else if (AObj is TTabControl) and (Prop = 'TAB') then
  begin
    CheckIndex('Tab', AIndex, TTabControl(AObj).Tabs.Count);
    TTabControl(AObj).Tabs[AIndex] := WinCPToUTF8(AValue);
  end
  else if (AObj is TStatusBar) and (Prop = 'PANEL.CAPTION') then
    PanelOf(TStatusBar(AObj), AIndex).Text := WinCPToUTF8(AValue)
  else
    Result := False;
end;

function MoreGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        out AValue: Integer): Boolean;
var
  Prop: string;
  Node: TTreeNode;
  Panel: TStatusPanel;
begin
  Result := True;
  AValue := 0;
  Prop := UpperCase(AProp);
  if (AObj is TCustomTreeView) and (Copy(Prop, 1, 5) = 'ITEM.') then
  begin
    Node := NodeOf(TCustomTreeView(AObj), AIndex);
    if Prop = 'ITEM.IMAGEINDEX' then
      AValue := Node.ImageIndex
    else if Prop = 'ITEM.STATEINDEX' then
      AValue := Node.StateIndex
    else if Prop = 'ITEM.SELECTEDINDEX' then
      AValue := Node.SelectedIndex
    else if Prop = 'ITEM.COUNT' then
      AValue := Node.Count
    else if Prop = 'ITEM.LEVEL' then
      AValue := Node.Level
    else if Prop = 'ITEM.ISVISIBLE' then
      AValue := Ord(Node.IsVisible)
    else if Prop = 'ITEM.HANDLE' then
      AValue := Integer(PtrInt(Node.Handle))
    else if Prop = 'ITEM.HASCHILDREN' then
      AValue := Ord(Node.HasChildren)
    else if Prop = 'ITEM.SELECTED' then
      AValue := Ord(Node.Selected)
    else if Prop = 'ITEM.PARENT' then
      AValue := NodeIndex(Node.Parent)
    else
      Result := False;
  end
  else if (AObj is TStatusBar) and (Copy(Prop, 1, 6) = 'PANEL.') then
  begin
    Panel := PanelOf(TStatusBar(AObj), AIndex);
    if Prop = 'PANEL.WIDTH' then
      AValue := Panel.Width
    else if Prop = 'PANEL.ALIGNMENT' then
      AValue := Ord(Panel.Alignment)
    else
      Result := False;
  end
  else
    Result := False;
end;

function MoreSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        AValue: Integer): Boolean;
var
  Prop: string;
  Node: TTreeNode;
  Panel: TStatusPanel;
begin
  Result := True;
  Prop := UpperCase(AProp);
  if (AObj is TCustomTreeView) and (Copy(Prop, 1, 5) = 'ITEM.') then
  begin
    Node := NodeOf(TCustomTreeView(AObj), AIndex);
    if Prop = 'ITEM.IMAGEINDEX' then
      Node.ImageIndex := AValue
    else if Prop = 'ITEM.STATEINDEX' then
      Node.StateIndex := AValue
    else if Prop = 'ITEM.SELECTEDINDEX' then
      Node.SelectedIndex := AValue
    else if Prop = 'ITEM.HASCHILDREN' then
      Node.HasChildren := AValue <> 0
    else if Prop = 'ITEM.SELECTED' then
      Node.Selected := AValue <> 0
    else
      raise Exception.Create(AProp + ' is read-only');
  end
  else if (AObj is TStatusBar) and (Copy(Prop, 1, 6) = 'PANEL.') then
  begin
    Panel := PanelOf(TStatusBar(AObj), AIndex);
    if Prop = 'PANEL.WIDTH' then
      Panel.Width := AValue
    else if Prop = 'PANEL.ALIGNMENT' then
      Panel.Alignment := TAlignment(AValue)
    else
      Result := False;
  end
  else
    Result := False;
end;

function MoreCallEx(AObj: TObject; const AMethod, AStr: string;
                    AInt1, AInt2, AInt3: Integer;
                    out AIntResult: Integer): Boolean;
var
  Method, FileText: string;
  Tree: TCustomTreeView;
  Tabs: TStrings;
  Node: TTreeNode;
  TextStream: TStringStream;
begin
  Result := True;
  AIntResult := 1;
  Method := UpperCase(AMethod);
  if AObj is TCustomTreeView then
  begin
    Tree := TCustomTreeView(AObj);
    if Method = 'ADDITEMS' then
      Tree.Items.Add(nil, WinCPToUTF8(AStr))
    else if Method = 'ADDCHILDITEMS' then
      Tree.Items.AddChild(NodeOf(Tree, AInt1), WinCPToUTF8(AStr))
    else if Method = 'INSERTITEM' then
    begin
      if AInt1 = Tree.Items.Count then
        Tree.Items.Add(nil, WinCPToUTF8(AStr))
      else
        Tree.Items.Insert(NodeOf(Tree, AInt1), WinCPToUTF8(AStr));
    end
    else if Method = 'DELITEMS' then
      NodeOf(Tree, AInt1).Delete
    else if Method = 'CLEAR' then
      Tree.Items.Clear
    else if Method = 'EXPAND' then
      NodeOf(Tree, AInt1).Expand(AInt2 <> 0)
    else if Method = 'COLLAPSE' then
      NodeOf(Tree, AInt1).Collapse(AInt2 <> 0)
    else if Method = 'FULLEXPAND' then
      Tree.FullExpand
    else if Method = 'FULLCOLLAPSE' then
      Tree.FullCollapse
    else if Method = 'GETITEMAT' then
      AIntResult := NodeIndex(Tree.GetNodeAt(AInt1, AInt2))
    else if Method = 'SORT' then
      Tree.AlphaSort
    else if Method = 'LOADFROMFILE' then
    begin
      // файл - в кодировке Windows, отступ табуляцией - уровень
      TextStream := TStringStream.Create(WinCPToUTF8(ReadWholeFile(AStr)));
      try
        Tree.LoadFromStream(TextStream);
      finally
        TextStream.Free;
      end;
    end
    else if Method = 'SAVETOFILE' then
    begin
      TextStream := TStringStream.Create('');
      try
        Tree.SaveToStream(TextStream);
        FileText := UTF8ToWinCP(TextStream.DataString);
      finally
        TextStream.Free;
      end;
      WriteWholeFile(AStr, FileText);
    end
    else
      Result := False;
  end
  else if AObj is TTabControl then
  begin
    Tabs := TTabControl(AObj).Tabs;
    if Method = 'ADDTABS' then
      Tabs.Add(WinCPToUTF8(AStr))
    else if (Method = 'DELTABS') or (Method = 'DELETETABS') then
    begin
      CheckIndex('DelTabs', AInt1, Tabs.Count);
      Tabs.Delete(AInt1);
    end
    else if Method = 'INSERTTAB' then
    begin
      if (AInt1 < 0) or (AInt1 > Tabs.Count) then
        CheckIndex('InsertTab', AInt1, Tabs.Count);
      Tabs.Insert(AInt1, WinCPToUTF8(AStr));
    end
    else if Method = 'CLEAR' then
      Tabs.Clear
    else
      Result := False;
  end
  else if AObj is TStatusBar then
  begin
    if Method = 'ADDPANELS' then
      TStatusBar(AObj).Panels.Add.Text := WinCPToUTF8(AStr)
    else if Method = 'CLEAR' then
      TStatusBar(AObj).Panels.Clear
    else
      Result := False;
  end
  else if AObj is TCustomFileListBox then
  begin
    // ftReadOnly 0, ftHidden 1, ftSystem 2, ftVolumeID 3, ftDirectory 4,
    // ftArchive 5, ftNormal 6 - как TFileAttr
    if Method = 'ADDFILETYPES' then
    begin
      if (AInt1 < Ord(Low(TFileAttr))) or (AInt1 > Ord(High(TFileAttr))) then
        raise Exception.Create('no file type ' + IntToStr(AInt1));
      TFileListBox(AObj).FileType := TFileListBox(AObj).FileType + [TFileAttr(AInt1)];
    end
    else if Method = 'DELFILETYPES' then
    begin
      if (AInt1 < Ord(Low(TFileAttr))) or (AInt1 > Ord(High(TFileAttr))) then
        raise Exception.Create('no file type ' + IntToStr(AInt1));
      TFileListBox(AObj).FileType := TFileListBox(AObj).FileType - [TFileAttr(AInt1)];
    end
    else if Method = 'UPDATE' then
      TFileListBox(AObj).UpdateFileList
    else
      Result := False;
  end
  else
    Result := False;
end;

end.
