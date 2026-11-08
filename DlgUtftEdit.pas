unit DlgUtftEdit;

// ---------------------------------------------------------------------------
//  Редактор шрифта UTFT по точкам (FontViewer - Правка - Редактировать
//  символы...).
//
//  Слева - таблица всех символов шрифта (щелчок - выбрать символ;
//  перетащить символ мышью на другой - заменить тот копией). Справа -
//  выбранный символ крупно: левая кнопка мыши ставит точки, правая -
//  стирает, можно вести мышью. Под ним - символ 1:1 и кнопки:
//    Копировать (Ctrl+C) / Вставить (Ctrl+V) - символ через свой буфер,
//    Очистить (Del), Отменить (Ctrl+Z), сдвиг символа на точку
//    (Shift+стрелки), стрелки - выбор символа в таблице.
//  Внизу - имя массива и Сохранить как... (Ctrl+S): весь шрифт в новый
//  .c-файл (один массив, как пишет TTF to UTFT). Исходный файл не
//  меняется; записать в него можно, только если в нём один этот массив.
//
//  Правится копия данных шрифта; окно модальное, строится в коде.
// ---------------------------------------------------------------------------

interface

uses
  {$IFDEF FPC} LCLType, {$ENDIF}
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, Dialogs,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiEdit
  UiStdCtrls,    // TUiLabel
  UiScroll,      // TUiScrollBar
  UiTheme,       // UiThemeColor
  DlgFontViewer; // TUtftFont

type
  // Шрифт записан в файл
  TUtftSavedEvent = procedure(const AFileName: string) of object;

  TDlgUtftEdit = class;

  // Поле окна: таблица символов или крупный символ
  TUtftEditView = class(TCustomControl)
  private
    FOwnerDlg: TDlgUtftEdit;
    FIsTable: Boolean;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      PosX, PosY: Integer); override;
    procedure MouseMove(Shift: TShiftState; PosX, PosY: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      PosX, PosY: Integer); override;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  // Прежний вид одного символа - для Отменить
  TUtftUndoItem = record
    Code: Integer;
    Bytes: array of Byte;
  end;

  TDlgUtftEdit = class(TForm)
  private
    FFont: TUtftFont;           // своя копия шрифта
    FSourceFile: string;
    FSourceName: string;
    FSourceArrays: Integer;     // массивов в исходном файле
    FCode: Integer;             // выбранный символ
    FModified: Boolean;
    FSavedFile: string;
    FOnSaved: TUtftSavedEvent;
    FUndo: array of TUtftUndoItem;
    FClip: array of Byte;       // буфер Копировать / Вставить
    FClipCode: Integer;
    // Таблица
    FTableZoom, FTableCols, FTableRows, FCellW, FCellH: Integer;
    FTableTop: Integer;         // первая видимая строка таблицы
    FDragFrom, FDragOver: Integer;
    // Крупный символ
    FPixZoom: Integer;
    FPaintValue: Integer;       // -1 - мышь не ведёт; 0 - стирает; 1 - ставит
    FHoverX, FHoverY: Integer;
    FLastX, FLastY: Integer;    // прошлая точка, пока мышь ведёт; -1 - нет
    FTextHeight: Integer;
    FTable: TUtftEditView;
    FTableBar: TUiScrollBar;
    FPixels: TUtftEditView;
    FPreview: TPaintBox;
    FLblChar: TUiLabel;
    FLblHint: TUiLabel;
    FLblName: TUiLabel;
    FEdName: TUiEdit;
    FBtnCopy, FBtnPaste, FBtnClear, FBtnUndo: TUiButton;
    FBtnShift: array[0..3] of TUiButton;   // влево, вправо, вверх, вниз
    FBtnSave, FBtnClose: TUiButton;
    procedure Build;
    function MakeButton(const ACaption, AHint: string; ALeft, ATop,
      AWidth: Integer; AOnClick: TNotifyEvent): TUiButton;
    function BytesPerChar: Integer;
    function GetPixel(ACode, PosX, PosY: Integer): Boolean;
    procedure SetPixel(ACode, PosX, PosY: Integer; AValue: Boolean);
    procedure PushUndo(ACode: Integer);
    procedure Changed;
    procedure SelectCode(ACode: Integer);
    procedure EnsureCodeVisible;
    procedure UpdateTableScroll;
    procedure UpdateCaptionText;
    procedure UpdateColors;
    function TableCodeAt(PosX, PosY: Integer): Integer;
    procedure DrawGlyph(ACanvas: TCanvas; ACode, ALeft, ATop, AZoom: Integer);
    procedure PaintTable(ACanvas: TCanvas);
    procedure PaintPixels(ACanvas: TCanvas);
    procedure PreviewPaint(Sender: TObject);
    procedure ViewMouseDown(AView: TUtftEditView; Button: TMouseButton;
      PosX, PosY: Integer);
    procedure ViewMouseMove(AView: TUtftEditView; Shift: TShiftState;
      PosX, PosY: Integer);
    procedure ViewMouseUp(AView: TUtftEditView; PosX, PosY: Integer);
    procedure PixelAt(PosX, PosY: Integer);
    procedure CopyGlyph(AFrom, ATo: Integer);
    procedure ShiftGlyph(ADeltaX, ADeltaY: Integer);
    function SaveAs: Boolean;
    procedure BtnCopyClick(Sender: TObject);
    procedure BtnPasteClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure BtnUndoClick(Sender: TObject);
    procedure BtnShiftClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
    procedure TableScrollChange(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  public
    constructor CreateDlg(AOwner: TComponent; AFont: TUtftFont;
      AStartCode: Integer);
    destructor Destroy; override;
    property OnSaved: TUtftSavedEvent read FOnSaved write FOnSaved;
  end;

// Редактор шрифта AFont (правится копия); AStartCode - выбранный сначала
// символ (-1 - первый). AOnSaved - после каждой записи файла
procedure EditUtftFont(AOwner: TComponent; AFont: TUtftFont;
  AStartCode: Integer; AOnSaved: TUtftSavedEvent);

implementation

uses
  DlgTtfToUtft;  // TtfFontSource, Cp1251ToUnicode

const
  UeGap = 8;
  UePixArea = 400;      // крупный символ - не больше этого по стороне
  UeTableWidth = 520;   // таблица символов - не шире
  UeUndoMax = 300;
  UeGlyphColor = clWhite;
  UeScreenColor = clBlack;
  UeGridColor = $00404040;
  UeDropColor = $0000C0FF;     // клетка, на которую тащат символ
  UeSelectColor = $00E08000;   // выбранный символ

procedure EditUtftFont(AOwner: TComponent; AFont: TUtftFont;
  AStartCode: Integer; AOnSaved: TUtftSavedEvent);
var
  Dlg: TDlgUtftEdit;
begin
  if (AFont = nil) or not AFont.IsFont or (AFont.CharCount < 1) then
    Exit;
  Dlg := TDlgUtftEdit.CreateDlg(AOwner, AFont, AStartCode);
  try
    Dlg.OnSaved := AOnSaved;
    Dlg.ShowModal;
  finally
    Dlg.Free;
  end;
end;

// Подпись символа: код и сам символ
function CodeText(ACode: Integer): string;
var
  Uni: Integer;
begin
  Result := Format('%d ($%.2x)', [ACode, ACode]);
  if ACode = 32 then
    Result := Result + ' пробел'
  else if (ACode > 32) and (ACode < 127) then
    Result := Result + ' ''' + Chr(ACode) + ''''
  else if ACode >= 128 then
  begin
    Uni := Cp1251ToUnicode(ACode);
    if Uni > 0 then
      {$IFDEF FPC}
      Result := Result + ' ''' + UTF8Encode(WideString(WideChar(Uni))) + '''';
      {$ELSE}
      Result := Result + ' ''' + Chr(ACode) + '''';
      {$ENDIF}
  end;
end;

// ---------------------------------------------------------------------------
//  TUtftEditView
// ---------------------------------------------------------------------------

constructor TUtftEditView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
end;

procedure TUtftEditView.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TUtftEditView.Paint;
begin
  if FOwnerDlg = nil then
    Exit;
  if FIsTable then
    FOwnerDlg.PaintTable(Canvas)
  else
    FOwnerDlg.PaintPixels(Canvas);
end;

procedure TUtftEditView.MouseDown(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
begin
  inherited MouseDown(Button, Shift, PosX, PosY);
  if FOwnerDlg <> nil then
    FOwnerDlg.ViewMouseDown(Self, Button, PosX, PosY);
end;

procedure TUtftEditView.MouseMove(Shift: TShiftState; PosX, PosY: Integer);
begin
  inherited MouseMove(Shift, PosX, PosY);
  if FOwnerDlg <> nil then
    FOwnerDlg.ViewMouseMove(Self, Shift, PosX, PosY);
end;

procedure TUtftEditView.MouseUp(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
begin
  inherited MouseUp(Button, Shift, PosX, PosY);
  if FOwnerDlg <> nil then
    FOwnerDlg.ViewMouseUp(Self, PosX, PosY);
end;

// ---------------------------------------------------------------------------
//  TDlgUtftEdit
// ---------------------------------------------------------------------------

constructor TDlgUtftEdit.CreateDlg(AOwner: TComponent; AFont: TUtftFont;
  AStartCode: Integer);
var
  Arrays: TList;
  ArrIdx: Integer;
begin
  inherited CreateNew(AOwner);
  FFont := TUtftFont.Create;
  FFont.Name := AFont.Name;
  FFont.FileName := AFont.FileName;
  FFont.SizeX := AFont.SizeX;
  FFont.SizeY := AFont.SizeY;
  FFont.FirstChar := AFont.FirstChar;
  FFont.CharCount := AFont.CharCount;
  FFont.DeclSize := AFont.DeclSize;
  // Только заголовок и символы: лишние байты за таблицей не нужны
  SetLength(FFont.Data, 4 + AFont.CharCount * (AFont.SizeX div 8) * AFont.SizeY);
  Move(AFont.Data[0], FFont.Data[0], Length(FFont.Data));
  FSourceFile := AFont.FileName;
  FSourceName := AFont.Name;
  // Сколько массивов в исходном файле: в файл с другими массивами не пишем
  FSourceArrays := 0;
  Arrays := TList.Create;
  try
    if UtftParseFile(FSourceFile, Arrays) then
      FSourceArrays := Arrays.Count;
    for ArrIdx := 0 to Arrays.Count - 1 do
      TUtftFont(Arrays[ArrIdx]).Free;
  finally
    Arrays.Free;
  end;
  FCode := AStartCode;
  if FFont.GlyphOffset(FCode) < 0 then
    FCode := FFont.FirstChar;
  FDragFrom := -1;
  FDragOver := -1;
  FPaintValue := -1;
  FHoverX := -1;
  FHoverY := -1;
  FClipCode := -1;
  Build;
  UiThemeAddClient(Self);
  UpdateCaptionText;
  EnsureCodeVisible;
end;

destructor TDlgUtftEdit.Destroy;
begin
  UiThemeRemoveClient(Self);
  FFont.Free;
  inherited Destroy;
end;

function TDlgUtftEdit.MakeButton(const ACaption, AHint: string; ALeft, ATop,
  AWidth: Integer; AOnClick: TNotifyEvent): TUiButton;
begin
  Result := TUiButton.Create(Self);
  Result.Parent := Self;
  Result.Caption := ACaption;
  Result.Hint := AHint;
  Result.ShowHint := AHint <> '';
  Result.SetBounds(ALeft, ATop, AWidth, FTextHeight + 10);
  Result.OnClick := AOnClick;
end;

procedure TDlgUtftEdit.Build;
var
  Measure: TBitmap;
  BarWidth, TableW, TableH, PixW, PixH, RightX, RightW, PosY, BtnW: Integer;
  BottomY, BtnH, ShiftIdx: Integer;
const
  ShiftCaptions: array[0..3] of string = ('<', '>', '^', 'v');
  ShiftHints: array[0..3] of string = ('Сдвинуть символ влево на точку ' +
    '(Shift+Влево)', 'Сдвинуть символ вправо (Shift+Вправо)',
    'Сдвинуть символ вверх (Shift+Вверх)', 'Сдвинуть символ вниз (Shift+Вниз)');
begin
  Caption := 'Редактор шрифта UTFT';
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  KeyPreview := True;
  OnKeyDown := FormKeyDown;
  OnMouseWheel := FormMouseWheel;
  OnCloseQuery := FormCloseQuery;
  Font.Assign(Screen.MenuFont);
  if Font.Height = 0 then
    Font.Size := 9;
  Measure := TBitmap.Create;
  try
    Measure.Canvas.Font := Font;
    FTextHeight := Measure.Canvas.TextHeight('Wg');
  finally
    Measure.Free;
  end;
  BtnH := FTextHeight + 10;

  // Таблица: символы в 1-3 раза крупнее, 16 столбцов (меньше, если широко)
  if FFont.SizeY <= 12 then
    FTableZoom := 3
  else if FFont.SizeY <= 26 then
    FTableZoom := 2
  else
    FTableZoom := 1;
  // Клетка: символ, вокруг рамка 2 точки (выбор), между клетками 1 точка
  FCellW := FFont.SizeX * FTableZoom + 5;
  FCellH := FFont.SizeY * FTableZoom + 5;
  FTableCols := 16;
  while (FTableCols > 4) and (FTableCols * FCellW > UeTableWidth) do
    Dec(FTableCols);
  FTableRows := (FFont.CharCount + FTableCols - 1) div FTableCols;

  // Крупный символ
  FPixZoom := UePixArea div FFont.SizeX;
  if UePixArea div FFont.SizeY < FPixZoom then
    FPixZoom := UePixArea div FFont.SizeY;
  if FPixZoom > 32 then
    FPixZoom := 32;
  if FPixZoom < 3 then
    FPixZoom := 3;
  PixW := FFont.SizeX * FPixZoom + 1;
  PixH := FFont.SizeY * FPixZoom + 1;

  BarWidth := GetSystemMetrics(SM_CXVSCROLL);
  if BarWidth < 12 then
    BarWidth := 17;
  TableW := FTableCols * FCellW;
  RightX := UeGap + TableW + BarWidth + 2 * UeGap;
  BtnW := 92;
  RightW := 4 * BtnW + 3 * 6;
  if PixW > RightW then
    RightW := PixW;

  // Правая колонка: крупный символ, подпись, 1:1, кнопки, подсказка
  FPixels := TUtftEditView.Create(Self);
  FPixels.FOwnerDlg := Self;
  FPixels.FIsTable := False;
  FPixels.Parent := Self;
  FPixels.SetBounds(RightX, UeGap, PixW, PixH);
  FPixels.Cursor := crCross;
  PosY := UeGap + PixH + 6;
  FLblChar := TUiLabel.Create(Self);
  FLblChar.Parent := Self;
  FLblChar.AutoSize := False;
  FLblChar.SetBounds(RightX, PosY, RightW, FTextHeight + 2);
  Inc(PosY, FTextHeight + 6);
  FPreview := TPaintBox.Create(Self);
  FPreview.Parent := Self;
  FPreview.SetBounds(RightX, PosY, 3 * FFont.SizeX + 8, FFont.SizeY + 4);
  FPreview.OnPaint := PreviewPaint;
  Inc(PosY, FFont.SizeY + 4 + 8);
  FBtnCopy := MakeButton('Копировать', 'Запомнить символ (Ctrl+C)',
    RightX, PosY, BtnW, BtnCopyClick);
  FBtnPaste := MakeButton('Вставить', 'Заменить символ запомненным (Ctrl+V)',
    RightX + BtnW + 6, PosY, BtnW, BtnPasteClick);
  FBtnClear := MakeButton('Очистить', 'Стереть все точки символа (Del)',
    RightX + 2 * (BtnW + 6), PosY, BtnW, BtnClearClick);
  FBtnUndo := MakeButton('Отменить', 'Отменить последнее изменение (Ctrl+Z)',
    RightX + 3 * (BtnW + 6), PosY, BtnW, BtnUndoClick);
  Inc(PosY, BtnH + 6);
  for ShiftIdx := 0 to 3 do
  begin
    FBtnShift[ShiftIdx] := MakeButton(ShiftCaptions[ShiftIdx],
      ShiftHints[ShiftIdx], RightX + ShiftIdx * 40, PosY, 34, BtnShiftClick);
    FBtnShift[ShiftIdx].Tag := ShiftIdx;
  end;
  Inc(PosY, BtnH + 6);
  FLblHint := TUiLabel.Create(Self);
  FLblHint.Parent := Self;
  FLblHint.AutoSize := False;
  FLblHint.WordWrap := True;
  FLblHint.SetBounds(RightX, PosY, RightW, 4 * FTextHeight + 4);
  FLblHint.Caption := 'Левая кнопка мыши - поставить точки, правая - ' +
    'стереть. В таблице: перетащить символ на другой - заменить его ' +
    'копией. Стрелки - другой символ, Shift+стрелки - сдвиг.';
  Inc(PosY, 4 * FTextHeight + 4);

  // Таблица слева на всю высоту правой колонки
  TableH := PosY - UeGap;
  if TableH < 3 * FCellH then
    TableH := 3 * FCellH;
  if TableH > FTableRows * FCellH then
    TableH := FTableRows * FCellH;
  if TableH < PosY - UeGap then
    TableH := PosY - UeGap;
  FTable := TUtftEditView.Create(Self);
  FTable.FOwnerDlg := Self;
  FTable.FIsTable := True;
  FTable.Parent := Self;
  FTable.SetBounds(UeGap, UeGap, TableW, TableH);
  FTableBar := TUiScrollBar.Create(Self);
  FTableBar.Parent := Self;
  FTableBar.Kind := sbVertical;
  FTableBar.SetBounds(UeGap + TableW, UeGap, BarWidth, TableH);
  FTableBar.SmallChange := 1;
  FTableBar.OnChange := TableScrollChange;
  if UeGap + TableH > PosY then
    PosY := UeGap + TableH;

  // Низ: имя массива, Сохранить как..., Закрыть
  BottomY := PosY + 10;
  FLblName := TUiLabel.Create(Self);
  FLblName.Parent := Self;
  FLblName.AutoSize := True;
  FLblName.Caption := 'Имя массива:';
  FLblName.Left := UeGap;
  FLblName.Top := BottomY + 4;
  FEdName := TUiEdit.Create(Self);
  FEdName.Parent := Self;
  FEdName.SetBounds(UeGap + 100, BottomY, 220, FTextHeight + 8);
  FEdName.Text := FSourceName + '_edit';
  FEdName.Hint := 'Имя массива в новом .c-файле (в скетче - extern uint8_t ' +
    'Имя[];). Два массива с одним именем в одной сборке не уживутся';
  FEdName.ShowHint := True;
  // Lazarus: в поле ввода KeyPreview окна не срабатывает - Ctrl+S и Esc
  // из поля сюда же (в Delphi форма уже обнулила Key)
  FEdName.OnKeyDown := FormKeyDown;
  ClientWidth := RightX + RightW + UeGap;
  FBtnClose := MakeButton('Закрыть', '', ClientWidth - UeGap - 100, BottomY - 1,
    100, BtnCloseClick);
  FBtnSave := MakeButton('Сохранить как...', 'Записать шрифт в новый .c-файл ' +
    '(Ctrl+S)', FBtnClose.Left - 8 - 140, BottomY - 1, 140, BtnSaveClick);
  ClientHeight := BottomY + BtnH + UeGap;

  UpdateTableScroll;
  UpdateColors;
end;

procedure TDlgUtftEdit.UpdateColors;
begin
  Color := UiThemeColor('Window.BG');
  Font.Color := UiThemeColor('Window.Text');
end;

function TDlgUtftEdit.BytesPerChar: Integer;
begin
  Result := (FFont.SizeX div 8) * FFont.SizeY;
end;

function TDlgUtftEdit.GetPixel(ACode, PosX, PosY: Integer): Boolean;
var
  Offset: Integer;
begin
  Result := False;
  Offset := FFont.GlyphOffset(ACode);
  if (Offset < 0) or (PosX < 0) or (PosY < 0) or (PosX >= FFont.SizeX) or
     (PosY >= FFont.SizeY) then
    Exit;
  Result := (FFont.Data[Offset + PosY * (FFont.SizeX div 8) + PosX div 8] and
    ($80 shr (PosX mod 8))) <> 0;
end;

procedure TDlgUtftEdit.SetPixel(ACode, PosX, PosY: Integer; AValue: Boolean);
var
  Offset, ByteIdx: Integer;
  Mask: Byte;
begin
  Offset := FFont.GlyphOffset(ACode);
  if (Offset < 0) or (PosX < 0) or (PosY < 0) or (PosX >= FFont.SizeX) or
     (PosY >= FFont.SizeY) then
    Exit;
  ByteIdx := Offset + PosY * (FFont.SizeX div 8) + PosX div 8;
  Mask := $80 shr (PosX mod 8);
  if AValue then
    FFont.Data[ByteIdx] := FFont.Data[ByteIdx] or Mask
  else
    FFont.Data[ByteIdx] := FFont.Data[ByteIdx] and not Mask;
end;

procedure TDlgUtftEdit.PushUndo(ACode: Integer);
var
  Offset, Count, Index: Integer;
begin
  Offset := FFont.GlyphOffset(ACode);
  if Offset < 0 then
    Exit;
  Count := Length(FUndo);
  if Count >= UeUndoMax then
  begin
    for Index := 1 to Count - 1 do
      FUndo[Index - 1] := FUndo[Index];
    Dec(Count);
  end;
  SetLength(FUndo, Count + 1);
  FUndo[Count].Code := ACode;
  SetLength(FUndo[Count].Bytes, BytesPerChar);
  Move(FFont.Data[Offset], FUndo[Count].Bytes[0], BytesPerChar);
end;

procedure TDlgUtftEdit.Changed;
begin
  FModified := True;
  FTable.Invalidate;
  FPixels.Invalidate;
  FPreview.Invalidate;
  UpdateCaptionText;
end;

procedure TDlgUtftEdit.UpdateCaptionText;
var
  Text: string;
begin
  Text := 'Символ ' + CodeText(FCode) + Format(', номер %d; %d x %d точек',
    [FCode - FFont.FirstChar, FFont.SizeX, FFont.SizeY]);
  if (FHoverX >= 0) and (FHoverY >= 0) then
    Text := Text + Format('; точка %d, %d', [FHoverX, FHoverY]);
  if FLblChar.Caption <> Text then
    FLblChar.Caption := Text;
  Text := 'Редактор шрифта UTFT - ' + FSourceName + ' (' +
    ExtractFileName(FSourceFile) + ')';
  if FModified then
    Text := Text + ' *';
  if Caption <> Text then
    Caption := Text;
end;

procedure TDlgUtftEdit.SelectCode(ACode: Integer);
begin
  if ACode < FFont.FirstChar then
    ACode := FFont.FirstChar;
  if ACode > FFont.FirstChar + FFont.CharCount - 1 then
    ACode := FFont.FirstChar + FFont.CharCount - 1;
  if ACode = FCode then
    Exit;
  FCode := ACode;
  EnsureCodeVisible;
  FTable.Invalidate;
  FPixels.Invalidate;
  FPreview.Invalidate;
  UpdateCaptionText;
end;

procedure TDlgUtftEdit.EnsureCodeVisible;
var
  Row, Visible: Integer;
begin
  Row := (FCode - FFont.FirstChar) div FTableCols;
  Visible := FTable.ClientHeight div FCellH;
  if Visible < 1 then
    Visible := 1;
  if Row < FTableTop then
    FTableTop := Row
  else if Row >= FTableTop + Visible then
    FTableTop := Row - Visible + 1;
  UpdateTableScroll;
end;

procedure TDlgUtftEdit.UpdateTableScroll;
var
  Visible, MaxTop: Integer;
begin
  Visible := FTable.ClientHeight div FCellH;
  if Visible < 1 then
    Visible := 1;
  MaxTop := FTableRows - Visible;
  if MaxTop < 0 then
    MaxTop := 0;
  if FTableTop > MaxTop then
    FTableTop := MaxTop;
  if FTableTop < 0 then
    FTableTop := 0;
  FTableBar.LargeChange := Visible;
  FTableBar.Max := MaxTop;
  FTableBar.Position := FTableTop;
  FTableBar.Enabled := MaxTop > 0;
  FTable.Invalidate;
end;

procedure TDlgUtftEdit.TableScrollChange(Sender: TObject);
begin
  if FTableBar.Position <> FTableTop then
  begin
    FTableTop := FTableBar.Position;
    FTable.Invalidate;
  end;
end;

function TDlgUtftEdit.TableCodeAt(PosX, PosY: Integer): Integer;
var
  Col, Row, CodeIdx: Integer;
begin
  Result := -1;
  if (PosX < 0) or (PosY < 0) then
    Exit;
  Col := PosX div FCellW;
  Row := PosY div FCellH + FTableTop;
  if Col >= FTableCols then
    Exit;
  CodeIdx := Row * FTableCols + Col;
  if CodeIdx < FFont.CharCount then
    Result := FFont.FirstChar + CodeIdx;
end;

// Символ ACode точками размером AZoom с левого верхнего угла
procedure TDlgUtftEdit.DrawGlyph(ACanvas: TCanvas; ACode, ALeft, ATop,
  AZoom: Integer);
var
  Row, Col, RunStart: Integer;
begin
  ACanvas.Brush.Color := UeGlyphColor;
  for Row := 0 to FFont.SizeY - 1 do
  begin
    RunStart := -1;
    for Col := 0 to FFont.SizeX do
      if (Col < FFont.SizeX) and GetPixel(ACode, Col, Row) then
      begin
        if RunStart < 0 then
          RunStart := Col;
      end
      else if RunStart >= 0 then
      begin
        ACanvas.FillRect(Rect(ALeft + RunStart * AZoom, ATop + Row * AZoom,
          ALeft + Col * AZoom, ATop + (Row + 1) * AZoom));
        RunStart := -1;
      end;
  end;
end;

procedure TDlgUtftEdit.PaintTable(ACanvas: TCanvas);
var
  CodeIdx, Code, Col, Row, CellX, CellY: Integer;
  FrameColor: TColor;
begin
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := UiThemeColor('List.BG');
  ACanvas.FillRect(FTable.ClientRect);
  for CodeIdx := FTableTop * FTableCols to FFont.CharCount - 1 do
  begin
    Row := CodeIdx div FTableCols - FTableTop;
    Col := CodeIdx mod FTableCols;
    CellY := Row * FCellH;
    if CellY > FTable.ClientHeight then
      Break;
    CellX := Col * FCellW;
    Code := FFont.FirstChar + CodeIdx;
    // Клетка экрана: чёрная, вокруг рамка 2 точки (выбор - цветом)
    if Code = FDragOver then
      FrameColor := UeDropColor
    else if Code = FCode then
      FrameColor := UeSelectColor
    else
      FrameColor := UiThemeColor('List.BG');
    ACanvas.Brush.Color := FrameColor;
    ACanvas.FillRect(Rect(CellX, CellY, CellX + FCellW - 1, CellY + FCellH - 1));
    ACanvas.Brush.Color := UeScreenColor;
    ACanvas.FillRect(Rect(CellX + 2, CellY + 2, CellX + FCellW - 3,
      CellY + FCellH - 3));
    DrawGlyph(ACanvas, Code, CellX + 2, CellY + 2, FTableZoom);
  end;
end;

procedure TDlgUtftEdit.PaintPixels(ACanvas: TCanvas);
var
  Index, GridW, GridH: Integer;
begin
  GridW := FFont.SizeX * FPixZoom;
  GridH := FFont.SizeY * FPixZoom;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := UeScreenColor;
  ACanvas.FillRect(FPixels.ClientRect);
  DrawGlyph(ACanvas, FCode, 0, 0, FPixZoom);
  // Сетка; через 8 точек - ярче (границы байт)
  for Index := 0 to FFont.SizeX do
  begin
    if Index mod 8 = 0 then
      ACanvas.Pen.Color := $00707070
    else
      ACanvas.Pen.Color := UeGridColor;
    ACanvas.MoveTo(Index * FPixZoom, 0);
    ACanvas.LineTo(Index * FPixZoom, GridH + 1);
  end;
  for Index := 0 to FFont.SizeY do
  begin
    if Index mod 8 = 0 then
      ACanvas.Pen.Color := $00707070
    else
      ACanvas.Pen.Color := UeGridColor;
    ACanvas.MoveTo(0, Index * FPixZoom);
    ACanvas.LineTo(GridW + 1, Index * FPixZoom);
  end;
end;

procedure TDlgUtftEdit.PreviewPaint(Sender: TObject);
var
  Canvas: TCanvas;
begin
  Canvas := FPreview.Canvas;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := UeScreenColor;
  Canvas.FillRect(Rect(0, 0, FPreview.Width, FPreview.Height));
  // Символ 1:1 и рядом с соседями в строке, как на экране
  if FFont.GlyphOffset(FCode - 1) >= 0 then
    DrawGlyph(Canvas, FCode - 1, 2, 2, 1);
  DrawGlyph(Canvas, FCode, 2 + FFont.SizeX, 2, 1);
  if FFont.GlyphOffset(FCode + 1) >= 0 then
    DrawGlyph(Canvas, FCode + 1, 2 + 2 * FFont.SizeX, 2, 1);
end;

procedure TDlgUtftEdit.ViewMouseDown(AView: TUtftEditView;
  Button: TMouseButton; PosX, PosY: Integer);
var
  Code: Integer;
begin
  if AView.FIsTable then
  begin
    if Button <> mbLeft then
      Exit;
    Code := TableCodeAt(PosX, PosY);
    if Code < 0 then
      Exit;
    SelectCode(Code);
    FDragFrom := Code;
    FDragOver := -1;
  end
  else
  begin
    if Button = mbLeft then
      FPaintValue := 1
    else if Button = mbRight then
      FPaintValue := 0
    else
      Exit;
    PushUndo(FCode);
    FLastX := -1;
    FLastY := -1;
    PixelAt(PosX, PosY);
  end;
end;

procedure TDlgUtftEdit.ViewMouseMove(AView: TUtftEditView; Shift: TShiftState;
  PosX, PosY: Integer);
var
  Code, CellX, CellY: Integer;
begin
  if AView.FIsTable then
  begin
    if (FDragFrom < 0) or not (ssLeft in Shift) then
      Exit;
    Code := TableCodeAt(PosX, PosY);
    if Code = FDragFrom then
      Code := -1;
    if Code <> FDragOver then
    begin
      FDragOver := Code;
      if Code >= 0 then
        FTable.Cursor := crDrag
      else
        FTable.Cursor := crDefault;
      FTable.Invalidate;
    end;
  end
  else
  begin
    CellX := -1;
    CellY := -1;
    if (PosX >= 0) and (PosY >= 0) and (PosX < FFont.SizeX * FPixZoom) and
       (PosY < FFont.SizeY * FPixZoom) then
    begin
      CellX := PosX div FPixZoom;
      CellY := PosY div FPixZoom;
    end;
    if (CellX <> FHoverX) or (CellY <> FHoverY) then
    begin
      FHoverX := CellX;
      FHoverY := CellY;
      UpdateCaptionText;
    end;
    if FPaintValue >= 0 then
      PixelAt(PosX, PosY);
  end;
end;

procedure TDlgUtftEdit.ViewMouseUp(AView: TUtftEditView; PosX, PosY: Integer);
var
  Target: Integer;
begin
  if AView.FIsTable then
  begin
    Target := FDragOver;
    FDragOver := -1;
    FTable.Cursor := crDefault;
    if (FDragFrom >= 0) and (Target >= 0) and (Target <> FDragFrom) then
    begin
      CopyGlyph(FDragFrom, Target);
      FDragFrom := -1;
      SelectCode(Target);
    end
    else
      FTable.Invalidate;
    FDragFrom := -1;
  end
  else
    FPaintValue := -1;
end;

// Точка под мышью - в FPaintValue; от прошлой точки - линией, чтобы
// при быстром движении мыши не было пропусков
procedure TDlgUtftEdit.PixelAt(PosX, PosY: Integer);
var
  CellX, CellY, Steps, StepIdx, DotX, DotY: Integer;
  AnyChange: Boolean;
begin
  if (FPaintValue < 0) or (PosX < 0) or (PosY < 0) then
    Exit;
  CellX := PosX div FPixZoom;
  CellY := PosY div FPixZoom;
  if (CellX >= FFont.SizeX) or (CellY >= FFont.SizeY) then
    Exit;
  if FLastX < 0 then
  begin
    FLastX := CellX;
    FLastY := CellY;
  end;
  Steps := Abs(CellX - FLastX);
  if Abs(CellY - FLastY) > Steps then
    Steps := Abs(CellY - FLastY);
  AnyChange := False;
  for StepIdx := 0 to Steps do
  begin
    if Steps = 0 then
    begin
      DotX := CellX;
      DotY := CellY;
    end
    else
    begin
      DotX := FLastX + Round((CellX - FLastX) * StepIdx / Steps);
      DotY := FLastY + Round((CellY - FLastY) * StepIdx / Steps);
    end;
    if GetPixel(FCode, DotX, DotY) <> (FPaintValue = 1) then
    begin
      SetPixel(FCode, DotX, DotY, FPaintValue = 1);
      AnyChange := True;
    end;
  end;
  FLastX := CellX;
  FLastY := CellY;
  if AnyChange then
    Changed;
end;

procedure TDlgUtftEdit.CopyGlyph(AFrom, ATo: Integer);
var
  FromOffset, ToOffset: Integer;
begin
  FromOffset := FFont.GlyphOffset(AFrom);
  ToOffset := FFont.GlyphOffset(ATo);
  if (FromOffset < 0) or (ToOffset < 0) or (AFrom = ATo) then
    Exit;
  PushUndo(ATo);
  Move(FFont.Data[FromOffset], FFont.Data[ToOffset], BytesPerChar);
  Changed;
end;

procedure TDlgUtftEdit.ShiftGlyph(ADeltaX, ADeltaY: Integer);
var
  Old: array of Boolean;
  Row, Col, SrcX, SrcY: Integer;
begin
  PushUndo(FCode);
  SetLength(Old, FFont.SizeX * FFont.SizeY);
  for Row := 0 to FFont.SizeY - 1 do
    for Col := 0 to FFont.SizeX - 1 do
      Old[Row * FFont.SizeX + Col] := GetPixel(FCode, Col, Row);
  for Row := 0 to FFont.SizeY - 1 do
    for Col := 0 to FFont.SizeX - 1 do
    begin
      SrcX := Col - ADeltaX;
      SrcY := Row - ADeltaY;
      SetPixel(FCode, Col, Row, (SrcX >= 0) and (SrcY >= 0) and
        (SrcX < FFont.SizeX) and (SrcY < FFont.SizeY) and
        Old[SrcY * FFont.SizeX + SrcX]);
    end;
  Changed;
end;

procedure TDlgUtftEdit.BtnCopyClick(Sender: TObject);
var
  Offset: Integer;
begin
  Offset := FFont.GlyphOffset(FCode);
  if Offset < 0 then
    Exit;
  SetLength(FClip, BytesPerChar);
  Move(FFont.Data[Offset], FClip[0], BytesPerChar);
  FClipCode := FCode;
  FLblHint.Caption := 'Запомнен символ ' + CodeText(FCode) +
    '. Выберите другой символ и нажмите Вставить (Ctrl+V).';
end;

procedure TDlgUtftEdit.BtnPasteClick(Sender: TObject);
var
  Offset: Integer;
begin
  Offset := FFont.GlyphOffset(FCode);
  if (Offset < 0) or (Length(FClip) <> BytesPerChar) then
    Exit;
  PushUndo(FCode);
  Move(FClip[0], FFont.Data[Offset], BytesPerChar);
  Changed;
end;

procedure TDlgUtftEdit.BtnClearClick(Sender: TObject);
var
  Offset: Integer;
begin
  Offset := FFont.GlyphOffset(FCode);
  if Offset < 0 then
    Exit;
  PushUndo(FCode);
  FillChar(FFont.Data[Offset], BytesPerChar, 0);
  Changed;
end;

procedure TDlgUtftEdit.BtnUndoClick(Sender: TObject);
var
  Count, Offset: Integer;
begin
  Count := Length(FUndo);
  if Count = 0 then
    Exit;
  Offset := FFont.GlyphOffset(FUndo[Count - 1].Code);
  if Offset >= 0 then
    Move(FUndo[Count - 1].Bytes[0], FFont.Data[Offset], BytesPerChar);
  FCode := FUndo[Count - 1].Code;
  SetLength(FUndo, Count - 1);
  EnsureCodeVisible;
  Changed;
end;

procedure TDlgUtftEdit.BtnShiftClick(Sender: TObject);
begin
  case TComponent(Sender).Tag of
    0: ShiftGlyph(-1, 0);
    1: ShiftGlyph(1, 0);
    2: ShiftGlyph(0, -1);
    3: ShiftGlyph(0, 1);
  end;
end;

function TDlgUtftEdit.SaveAs: Boolean;
var
  SaveDlg: TSaveDialog;
  Source: TStringList;
  ArrayName, FileName: string;
  CharIdx: Integer;
begin
  Result := False;
  ArrayName := Trim(FEdName.Text);
  if ArrayName = '' then
  begin
    MessageDlg('Нет имени массива', mtWarning, [mbOK], 0);
    Exit;
  end;
  for CharIdx := 1 to Length(ArrayName) do
    if not (ArrayName[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) or
       ((CharIdx = 1) and (ArrayName[CharIdx] in ['0'..'9'])) then
    begin
      MessageDlg('Имя массива - латинские буквы, цифры и _, не с цифры: ' +
        ArrayName, mtWarning, [mbOK], 0);
      Exit;
    end;
  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.Title := 'Сохранить шрифт UTFT как';
    SaveDlg.Filter := 'Шрифты UTFT (*.c)|*.c|Все файлы (*.*)|*.*';
    SaveDlg.DefaultExt := 'c';
    if FSavedFile <> '' then
    begin
      SaveDlg.InitialDir := ExtractFileDir(FSavedFile);
      SaveDlg.FileName := ExtractFileName(FSavedFile);
    end
    else
    begin
      SaveDlg.InitialDir := ExtractFileDir(FSourceFile);
      SaveDlg.FileName := ArrayName + '.c';
    end;
    SaveDlg.Options := [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing,
      ofPathMustExist];
    if not SaveDlg.Execute then
      Exit;
    FileName := SaveDlg.FileName;
  finally
    SaveDlg.Free;
  end;
  // В исходный файл - только если в нём один этот массив: иначе
  // остальные массивы файла пропали бы
  if SameText(ExpandFileName(FileName), ExpandFileName(FSourceFile)) and
     (FSourceArrays > 1) then
  begin
    MessageDlg('В ' + ExtractFileName(FSourceFile) + ' ' +
      IntToStr(FSourceArrays) + ' массивов; запись туда одного шрифта ' +
      'удалила бы остальные. Выберите другое имя файла.', mtWarning,
      [mbOK], 0);
    Exit;
  end;
  FFont.Name := ArrayName;
  Source := TStringList.Create;
  try
    Source.Text := TtfFontSource(FFont, 'Edited in unIDE Font Viewer from ' +
      FSourceName + ' (' + ExtractFileName(FSourceFile) + ')');
    try
      Source.SaveToFile(FileName);
    except
      on E: Exception do
      begin
        MessageDlg('Файл не записан: ' + E.Message, mtError, [mbOK], 0);
        Exit;
      end;
    end;
  finally
    Source.Free;
  end;
  FSavedFile := FileName;
  FModified := False;
  UpdateCaptionText;
  FLblHint.Caption := 'Записан ' + FileName;
  if Assigned(FOnSaved) then
    FOnSaved(FileName);
  Result := True;
end;

procedure TDlgUtftEdit.BtnSaveClick(Sender: TObject);
begin
  SaveAs;
end;

procedure TDlgUtftEdit.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TDlgUtftEdit.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if not FModified then
    Exit;
  case MessageDlg('Шрифт изменён. Сохранить в новый файл?', mtConfirmation,
    [mbYes, mbNo, mbCancel], 0) of
    mrYes: CanClose := SaveAs;
    mrNo: CanClose := True;
  else
    CanClose := False;
  end;
end;

procedure TDlgUtftEdit.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  InEdit: Boolean;
begin
  if Key = 0 then
    Exit;
  InEdit := ActiveControl = FEdName;
  if (Key = Ord('S')) and (Shift = [ssCtrl]) then
    SaveAs
  else if Key = VK_ESCAPE then
    Close
  else if InEdit then
    Exit
  else if (Key = Ord('C')) and (Shift = [ssCtrl]) then
    BtnCopyClick(nil)
  else if (Key = Ord('V')) and (Shift = [ssCtrl]) then
    BtnPasteClick(nil)
  else if (Key = Ord('Z')) and (Shift = [ssCtrl]) then
    BtnUndoClick(nil)
  else if (Key = VK_DELETE) and (Shift = []) then
    BtnClearClick(nil)
  else if Shift = [ssShift] then
    case Key of
      VK_LEFT: ShiftGlyph(-1, 0);
      VK_RIGHT: ShiftGlyph(1, 0);
      VK_UP: ShiftGlyph(0, -1);
      VK_DOWN: ShiftGlyph(0, 1);
    else
      Exit;
    end
  else if Shift = [] then
    case Key of
      VK_LEFT: SelectCode(FCode - 1);
      VK_RIGHT: SelectCode(FCode + 1);
      VK_UP: SelectCode(FCode - FTableCols);
      VK_DOWN: SelectCode(FCode + FTableCols);
      VK_HOME: SelectCode(FFont.FirstChar);
      VK_END: SelectCode(FFont.FirstChar + FFont.CharCount - 1);
    else
      Exit;
    end
  else
    Exit;
  Key := 0;
end;

procedure TDlgUtftEdit.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  FTableTop := FTableTop - WheelDelta div 120;
  UpdateTableScroll;
  Handled := True;
end;

end.
