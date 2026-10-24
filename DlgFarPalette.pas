unit DlgFarPalette;

// ---------------------------------------------------------------------------
//  Палитра окна unIDE FAR (F9 - Options - Colors в FAR, Options - unIDE
//  FAR - Colors в меню IDE): цвет каждого элемента панелей, меню,
//  диалогов, предупреждений, кейбара и командной строки.
//
//  Таблица: группа | элемент | образец (текст на фоне - парные элементы
//  палитры) | цвет. Щелчок по образцу или цвету, Enter - выбрать цвет
//  (TUiColorDialog, любые цвета). Правый щелчок, Del - стандартный цвет
//  элемента. «Стандартные» - вся палитра по умолчанию.
//
//  Изменения сразу видны в окне FAR: после каждого изменения - OnChange
//  (Unit1 отдаёт палитру окну FAR). Отмена - Unit1 возвращает прежнюю.
//
//  Окно строится в коде (CreateDlg), .dfm нет. Палитра и её формат в
//  editor.ini - UnFar.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Grids,
  UiButton,     // TUiButton
  UiStdDlgs,    // TUiColorDialog - выбор цвета в цветах темы
  UnFar;        // TFarPalette, FarPal*

type
  TDlgFarPalette = class(TForm)
  private
    FPalette: TFarPalette;
    FOnChange: TNotifyEvent;
    FGrid: TDrawGrid;
    FHintLabel: TLabel;
    FBtnDefault: TUiButton;
    FBtnOk: TUiButton;
    FBtnCancel: TUiButton;
    procedure GridDrawCell(Sender: TObject; ACol, ARow: Longint;
      Rect: TRect; State: TGridDrawState);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GridKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure DefaultClick(Sender: TObject);
    function ItemOfRow(ARow: Integer; var AItem: TFarPalItem): Boolean;
    procedure PickColor(AItem: TFarPalItem);
    procedure ResetItem(AItem: TFarPalItem);
    procedure PaletteChanged;
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    constructor CreateDlg(AOwner: TComponent; const APalette: TFarPalette;
      AOnChange: TNotifyEvent);
    property Palette: TFarPalette read FPalette;
  end;

implementation

const
  ColGroup = 0;
  ColItem = 1;
  ColSample = 2;
  ColColor = 3;
  SwatchWidth = 28;
  PalItemCount = Ord(High(TFarPalItem)) + 1;

constructor TDlgFarPalette.CreateDlg(AOwner: TComponent;
  const APalette: TFarPalette; AOnChange: TNotifyEvent);
begin
  inherited CreateNew(AOwner);
  FPalette := APalette;
  FOnChange := AOnChange;
  Caption := 'unIDE FAR - Colors';
  Position := poOwnerFormCenter;
  BorderStyle := bsDialog;
  Font.Name := 'Tahoma';
  Font.Height := -11;
  ClientWidth := 640;
  ClientHeight := 560;

  FGrid := TDrawGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.SetBounds(8, 8, 624, 452);
  FGrid.ColCount := 4;
  FGrid.FixedCols := 0;
  FGrid.RowCount := PalItemCount + 1;
  FGrid.FixedRows := 1;
  FGrid.DefaultRowHeight := 20;
  FGrid.DefaultDrawing := False;
  FGrid.Options := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine,
    goRowSelect];
  FGrid.ScrollBars := ssVertical;
  FGrid.ColWidths[ColGroup] := 120;
  FGrid.ColWidths[ColItem] := 260;
  FGrid.ColWidths[ColSample] := 100;
  // Ширина окна таблицы (без рамки и линий сетки) - без ClientWidth: окно
  // таблицы ещё не создано
  FGrid.ColWidths[ColColor] := FGrid.Width - 120 - 260 - 100 - 4 - 4 -
    GetSystemMetrics(SM_CXVSCROLL);
  FGrid.OnDrawCell := GridDrawCell;
  FGrid.OnMouseDown := GridMouseDown;
  FGrid.OnKeyDown := GridKeyDown;
  FGrid.TabOrder := 0;

  FHintLabel := TLabel.Create(Self);
  FHintLabel.Parent := Self;
  FHintLabel.AutoSize := False;
  FHintLabel.WordWrap := True;
  FHintLabel.SetBounds(8, 466, 624, 44);
  FHintLabel.Caption := 'Щелчок по образцу или цвету, Enter - выбрать цвет. ' +
    'Правый щелчок, Del - стандартный цвет элемента. Изменения сразу ' +
    'видны в окне FAR; OK - записать в editor.ini, Отмена - вернуть ' +
    'прежние цвета.';

  FBtnDefault := TUiButton.Create(Self);
  FBtnDefault.Parent := Self;
  FBtnDefault.SetBounds(8, 522, 110, 28);
  FBtnDefault.Caption := 'Стандартные';
  FBtnDefault.OnClick := DefaultClick;
  FBtnDefault.TabOrder := 1;

  FBtnOk := TUiButton.Create(Self);
  FBtnOk.Parent := Self;
  FBtnOk.SetBounds(440, 522, 92, 28);
  FBtnOk.Caption := 'OK';
  FBtnOk.ModalResult := mrOk;
  FBtnOk.TabOrder := 2;

  FBtnCancel := TUiButton.Create(Self);
  FBtnCancel.Parent := Self;
  FBtnCancel.SetBounds(540, 522, 92, 28);
  FBtnCancel.Caption := 'Отмена';
  FBtnCancel.ModalResult := mrCancel;
  FBtnCancel.Cancel := True;
  FBtnCancel.TabOrder := 3;

  ActiveControl := FGrid;
end;

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана (см. TForm1.WMUpdateUIState)
procedure TDlgFarPalette.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

function TDlgFarPalette.ItemOfRow(ARow: Integer;
  var AItem: TFarPalItem): Boolean;
begin
  Result := (ARow >= 1) and (ARow <= PalItemCount);
  if Result then
    AItem := TFarPalItem(ARow - 1)
  else
    AItem := Low(TFarPalItem);
end;

procedure TDlgFarPalette.GridDrawCell(Sender: TObject; ACol, ARow: Longint;
  Rect: TRect; State: TGridDrawState);
const
  Titles: array[0..3] of string = ('Группа', 'Элемент', 'Образец', 'Цвет');
var
  GridCanvas: TCanvas;
  Item: TFarPalItem;
  TextY: Integer;
  Back, Fore, SampleFore, SampleBack: TColor;
  SwatchRect: TRect;
begin
  GridCanvas := FGrid.Canvas;
  TextY := Rect.Top +
    (Rect.Bottom - Rect.Top - GridCanvas.TextHeight('Wg')) div 2;

  if ARow = 0 then
  begin
    GridCanvas.Brush.Color := FGrid.FixedColor;
    GridCanvas.FillRect(Rect);
    GridCanvas.Font.Color := FGrid.Font.Color;
    GridCanvas.TextOut(Rect.Left + 4, TextY, Titles[ACol]);
    Exit;
  end;

  if ARow = FGrid.Row then
  begin
    Back := clHighlight;
    Fore := clHighlightText;
  end
  else
  begin
    Back := FGrid.Color;
    Fore := FGrid.Font.Color;
  end;
  GridCanvas.Brush.Color := Back;
  GridCanvas.FillRect(Rect);
  if not ItemOfRow(ARow, Item) then
    Exit;
  GridCanvas.Font.Color := Fore;

  case ACol of
    ColGroup:
      // Группа - только у первой строки группы
      if (Item = Low(TFarPalItem)) or
         (FarPalGroup(Pred(Item)) <> FarPalGroup(Item)) then
        GridCanvas.TextOut(Rect.Left + 4, TextY, FarPalGroup(Item));
    ColItem:
      GridCanvas.TextOut(Rect.Left + 4, TextY, FarPalCaption(Item));
    ColSample:
      begin
        // Текст цветом элемента на парном фоне (или наоборот)
        if FarPalIsBack(Item) then
        begin
          SampleBack := FPalette[Item];
          SampleFore := FPalette[FarPalPair(Item)];
        end
        else
        begin
          SampleBack := FPalette[FarPalPair(Item)];
          SampleFore := FPalette[Item];
        end;
        SwatchRect := Rect;
        InflateRect(SwatchRect, -2, -2);
        GridCanvas.Brush.Color := SampleBack;
        GridCanvas.FillRect(SwatchRect);
        GridCanvas.Font.Color := SampleFore;
        GridCanvas.TextOut(SwatchRect.Left + 4, TextY, 'Образец');
      end;
    ColColor:
      begin
        SwatchRect := Classes.Rect(Rect.Left + 4, Rect.Top + 3,
          Rect.Left + 4 + SwatchWidth, Rect.Bottom - 3);
        GridCanvas.Brush.Color := FPalette[Item];
        GridCanvas.FillRect(SwatchRect);
        GridCanvas.Brush.Color := Fore;
        GridCanvas.FrameRect(SwatchRect);
        GridCanvas.Brush.Color := Back;
        GridCanvas.TextOut(SwatchRect.Right + 6, TextY,
          FarColorToText(FPalette[Item]));
      end;
  end;
end;

procedure TDlgFarPalette.PaletteChanged;
begin
  FGrid.Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TDlgFarPalette.PickColor(AItem: TFarPalItem);
var
  ColorDlg: TUiColorDialog;
begin
  ColorDlg := TUiColorDialog.Create(Self);
  try
    ColorDlg.Options := [cdFullOpen, cdAnyColor];
    ColorDlg.Color := FPalette[AItem];
    if not ColorDlg.Execute then
      Exit;
    FPalette[AItem] := ColorToRGB(ColorDlg.Color);
  finally
    ColorDlg.Free;
  end;
  PaletteChanged;
end;

procedure TDlgFarPalette.ResetItem(AItem: TFarPalItem);
begin
  FPalette[AItem] := FarPalDefault(AItem);
  PaletteChanged;
end;

procedure TDlgFarPalette.DefaultClick(Sender: TObject);
begin
  FarPaletteDefault(FPalette);
  PaletteChanged;
end;

procedure TDlgFarPalette.GridMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CellCol, CellRow: Longint;
  Item: TFarPalItem;
begin
  FGrid.MouseToCell(X, Y, CellCol, CellRow);
  if not ItemOfRow(CellRow, Item) then
    Exit;
  if FGrid.Row <> CellRow then
    FGrid.Row := CellRow;
  if Button = mbRight then
    ResetItem(Item)
  else if (Button = mbLeft) and
          ((CellCol = ColSample) or (CellCol = ColColor)) then
    PickColor(Item);
end;

procedure TDlgFarPalette.GridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Item: TFarPalItem;
begin
  if not ItemOfRow(FGrid.Row, Item) then
    Exit;
  case Key of
    VK_RETURN, VK_SPACE:
      begin
        PickColor(Item);
        Key := 0;
      end;
    VK_DELETE, VK_BACK:
      begin
        ResetItem(Item);
        Key := 0;
      end;
  end;
end;

end.
