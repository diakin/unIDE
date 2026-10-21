unit DlgFarColors;

// Раскраска файлов в unIDE FAR: список расширений с цветом текста и фона.
//
// Таблица: флажок (правило включено) | расширение (образцом - его цветами
// на фоне панели FAR) | цвет текста | цвет фона. Щелчок по флажку -
// включить / выключить, по цвету - выбрать цвет (TUiColorDialog, любые
// цвета). Правый щелчок по фону - фон панели. Пробел - флажок строки,
// Enter - цвет текста, Del - удалить строку.
// Внизу - поле нового расширения, Добавить, Удалить; OK / Отмена.
//
// Окно описано в DlgFarColors.dfm. Вызывает его TForm1.FarColorsClick
// (Unit1): правила - SetRules, обратно - GetRules; запись в editor.ini и
// в окно FAR - там же. Правила и их формат в editor.ini - UnFar.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Grids,
  UiButton,     // TUiButton
  UiEditCtrls,  // TUiEdit
  UiStdDlgs,    // TUiColorDialog - выбор цвета в цветах темы
  UnFar;        // TFarColorRules, FarNormalizeExt, FarPanelColor

type
  TDlgFarColors = class(TForm)
    grdColors: TDrawGrid;
    lblHint: TLabel;
    lblExt: TLabel;
    edExt: TUiEdit;
    btnAdd: TUiButton;
    btnDelete: TUiButton;
    btnOk: TUiButton;
    btnCancel: TUiButton;
    procedure FormCreate(Sender: TObject);
    procedure grdColorsDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure grdColorsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure grdColorsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edExtKeyPress(Sender: TObject; var Key: Char);
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
  private
    FRules: TFarColorRules;
    procedure UpdateGrid;
    function RuleIndexOfRow(ARow: Integer): Integer;
    procedure PickColor(ARuleIndex: Integer; ABackground: Boolean);
    procedure ToggleRule(ARuleIndex: Integer);
    procedure DeleteRule(ARuleIndex: Integer);
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    procedure SetRules(const ARules: TFarColorRules);
    function GetRules: TFarColorRules;
  end;

implementation

{$R *.dfm}

const
  ColCheck = 0;
  ColExt = 1;
  ColFore = 2;
  ColBack = 3;
  SwatchWidth = 28;

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана (см. TForm1.WMUpdateUIState)
procedure TDlgFarColors.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgFarColors.FormCreate(Sender: TObject);
begin
  grdColors.ColWidths[ColCheck] := 26;
  grdColors.ColWidths[ColExt] := 130;
  grdColors.ColWidths[ColFore] := 130;
  grdColors.ColWidths[ColBack] := grdColors.ClientWidth - 26 - 130 - 130 - 4;
end;

procedure TDlgFarColors.SetRules(const ARules: TFarColorRules);
begin
  FarCopyRules(ARules, FRules);
  UpdateGrid;
end;

function TDlgFarColors.GetRules: TFarColorRules;
begin
  FarCopyRules(FRules, Result);
end;

// Строк - по числу правил (и строка заголовка); без правил - одна пустая:
// у таблицы под заголовком должна быть хотя бы одна строка
procedure TDlgFarColors.UpdateGrid;
begin
  if Length(FRules) > 0 then
    grdColors.RowCount := Length(FRules) + 1
  else
    grdColors.RowCount := 2;
  btnDelete.Enabled := Length(FRules) > 0;
  grdColors.Invalidate;
end;

function TDlgFarColors.RuleIndexOfRow(ARow: Integer): Integer;
begin
  Result := ARow - 1;
  if (Result < 0) or (Result > High(FRules)) then
    Result := -1;
end;

procedure TDlgFarColors.grdColorsDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
const
  Titles: array[0..3] of string = ('', 'Расширение', 'Цвет текста',
    'Цвет фона');
var
  GridCanvas: TCanvas;
  RuleIndex, TextY, CheckFlags: Integer;
  Rule: TFarColorRule;
  Back, Fore: TColor;
  IsSelected: Boolean;
  BoxRect, SwatchRect: TRect;
  CellText: string;
begin
  GridCanvas := grdColors.Canvas;
  TextY := Rect.Top +
    (Rect.Bottom - Rect.Top - GridCanvas.TextHeight('Wg')) div 2;

  // Заголовок
  if ARow = 0 then
  begin
    GridCanvas.Brush.Color := grdColors.FixedColor;
    GridCanvas.FillRect(Rect);
    GridCanvas.Font.Color := grdColors.Font.Color;
    GridCanvas.TextOut(Rect.Left + 4, TextY, Titles[ACol]);
    Exit;
  end;

  RuleIndex := RuleIndexOfRow(ARow);
  IsSelected := ARow = grdColors.Row;
  if IsSelected then
  begin
    Back := clHighlight;
    Fore := clHighlightText;
  end
  else
  begin
    Back := grdColors.Color;
    Fore := grdColors.Font.Color;
  end;
  GridCanvas.Brush.Color := Back;
  GridCanvas.FillRect(Rect);
  if RuleIndex < 0 then
    Exit;
  Rule := FRules[RuleIndex];
  GridCanvas.Font.Color := Fore;

  case ACol of
    ColCheck:
      begin
        BoxRect := Classes.Rect(0, 0, 13, 13);
        OffsetRect(BoxRect, Rect.Left + (Rect.Right - Rect.Left - 13) div 2,
          Rect.Top + (Rect.Bottom - Rect.Top - 13) div 2);
        CheckFlags := DFCS_BUTTONCHECK;
        if Rule.Enabled then
          CheckFlags := CheckFlags or DFCS_CHECKED;
        DrawFrameControl(GridCanvas.Handle, BoxRect, DFC_BUTTON, CheckFlags);
      end;
    ColExt:
      begin
        // Образец: расширение цветами правила на фоне панели FAR
        SwatchRect := Rect;
        InflateRect(SwatchRect, -2, -2);
        if Rule.Back <> clNone then
          GridCanvas.Brush.Color := Rule.Back
        else
          GridCanvas.Brush.Color := FarPanelColor;
        GridCanvas.FillRect(SwatchRect);
        if Rule.Enabled then
          GridCanvas.Font.Color := Rule.Fore
        else
          GridCanvas.Font.Color := clGray;
        GridCanvas.TextOut(SwatchRect.Left + 4, TextY, '*.' + Rule.Ext);
      end;
    ColFore, ColBack:
      begin
        SwatchRect := Classes.Rect(Rect.Left + 4, Rect.Top + 3,
          Rect.Left + 4 + SwatchWidth, Rect.Bottom - 3);
        if (ACol = ColBack) and (Rule.Back = clNone) then
        begin
          GridCanvas.Brush.Color := FarPanelColor;
          CellText := 'фон панели';
        end
        else if ACol = ColBack then
        begin
          GridCanvas.Brush.Color := Rule.Back;
          CellText := FarColorToText(Rule.Back);
        end
        else
        begin
          GridCanvas.Brush.Color := Rule.Fore;
          CellText := FarColorToText(Rule.Fore);
        end;
        GridCanvas.FillRect(SwatchRect);
        GridCanvas.Brush.Color := Fore;
        GridCanvas.FrameRect(SwatchRect);
        GridCanvas.Brush.Color := Back;
        GridCanvas.TextOut(SwatchRect.Right + 6, TextY, CellText);
      end;
  end;
end;

procedure TDlgFarColors.ToggleRule(ARuleIndex: Integer);
begin
  if ARuleIndex < 0 then
    Exit;
  FRules[ARuleIndex].Enabled := not FRules[ARuleIndex].Enabled;
  grdColors.Invalidate;
end;

procedure TDlgFarColors.PickColor(ARuleIndex: Integer; ABackground: Boolean);
var
  ColorDlg: TUiColorDialog;
begin
  if ARuleIndex < 0 then
    Exit;
  ColorDlg := TUiColorDialog.Create(Self);
  try
    ColorDlg.Options := [cdFullOpen, cdAnyColor];
    if ABackground then
    begin
      if FRules[ARuleIndex].Back <> clNone then
        ColorDlg.Color := FRules[ARuleIndex].Back
      else
        ColorDlg.Color := FarPanelColor;
    end
    else
      ColorDlg.Color := FRules[ARuleIndex].Fore;
    if not ColorDlg.Execute then
      Exit;
    if ABackground then
      FRules[ARuleIndex].Back := ColorToRGB(ColorDlg.Color)
    else
      FRules[ARuleIndex].Fore := ColorToRGB(ColorDlg.Color);
  finally
    ColorDlg.Free;
  end;
  grdColors.Invalidate;
end;

procedure TDlgFarColors.DeleteRule(ARuleIndex: Integer);
var
  MoveIndex, KeepRow: Integer;
begin
  if ARuleIndex < 0 then
    Exit;
  for MoveIndex := ARuleIndex to High(FRules) - 1 do
    FRules[MoveIndex] := FRules[MoveIndex + 1];
  SetLength(FRules, Length(FRules) - 1);
  KeepRow := grdColors.Row;
  UpdateGrid;
  if KeepRow >= grdColors.RowCount then
    KeepRow := grdColors.RowCount - 1;
  if KeepRow >= 1 then
    grdColors.Row := KeepRow;
end;

procedure TDlgFarColors.grdColorsMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CellCol, CellRow, RuleIndex: Integer;
begin
  grdColors.MouseToCell(X, Y, CellCol, CellRow);
  RuleIndex := RuleIndexOfRow(CellRow);
  if RuleIndex < 0 then
    Exit;
  if grdColors.Row <> CellRow then
    grdColors.Row := CellRow;
  if Button = mbRight then
  begin
    // Правый щелчок по фону - фон панели
    if CellCol = ColBack then
    begin
      FRules[RuleIndex].Back := clNone;
      grdColors.Invalidate;
    end;
    Exit;
  end;
  if Button <> mbLeft then
    Exit;
  case CellCol of
    ColCheck:
      ToggleRule(RuleIndex);
    ColFore:
      PickColor(RuleIndex, False);
    ColBack:
      PickColor(RuleIndex, True);
  end;
end;

procedure TDlgFarColors.grdColorsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  RuleIndex: Integer;
begin
  RuleIndex := RuleIndexOfRow(grdColors.Row);
  case Key of
    VK_SPACE:
      begin
        ToggleRule(RuleIndex);
        Key := 0;
      end;
    VK_RETURN:
      begin
        PickColor(RuleIndex, ssShift in Shift);
        Key := 0;
      end;
    VK_DELETE:
      begin
        DeleteRule(RuleIndex);
        Key := 0;
      end;
  end;
end;

procedure TDlgFarColors.edExtKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    btnAddClick(Sender);
  end;
end;

// Новое расширение: '*.ext', '.ext' и 'ext' - одно и то же; такое уже
// есть - курсор на него
procedure TDlgFarColors.btnAddClick(Sender: TObject);
var
  Ext: string;
  RuleIndex: Integer;
begin
  Ext := FarNormalizeExt(edExt.Text);
  if Ext = '' then
  begin
    lblHint.Caption := 'Расширение не задано или в нём есть недопустимые ' +
      'символы';
    Exit;
  end;
  for RuleIndex := 0 to High(FRules) do
    if FRules[RuleIndex].Ext = Ext then
    begin
      grdColors.Row := RuleIndex + 1;
      lblHint.Caption := '*.' + Ext + ' уже есть в списке';
      Exit;
    end;
  RuleIndex := Length(FRules);
  SetLength(FRules, RuleIndex + 1);
  FRules[RuleIndex].Ext := Ext;
  FRules[RuleIndex].Enabled := True;
  FRules[RuleIndex].Fore := clWhite;
  FRules[RuleIndex].Back := clNone;
  UpdateGrid;
  grdColors.Row := RuleIndex + 1;
  edExt.Text := '';
  lblHint.Caption := '*.' + Ext + ' добавлено - цвет задаётся щелчком ' +
    'по образцу цвета';
end;

procedure TDlgFarColors.btnDeleteClick(Sender: TObject);
begin
  DeleteRule(RuleIndexOfRow(grdColors.Row));
end;

end.
