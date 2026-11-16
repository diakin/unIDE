unit ArdGlyphPanel;

// Панель знаков шрифта UTFT под таблицей свойств инспектора (.ino):
// все знаки шрифта выбранной надписи, как в Font Viewer. Щелчок по знаку -
// OnPick(код знака): Unit1 вставляет его в поле текста (Caption).
//
// Панель держит свою копию данных шрифта: шрифты эмулятора (FindFont)
// освобождаются при новой сборке, ссылка на них устарела бы.
// Щелчок по знаку не забирает фокус у поля правки: знаки рисуются на
// TPaintBox (не оконный элемент), панель фокус по щелчку не берёт.

interface

uses
  {$IFDEF FPC} LCLType, {$ENDIF}
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls,
  UiStdCtrls,     // TUiPanel, TUiLabel
  UiScroll,       // TUiScrollBar
  DlgFontViewer;  // TUtftFont

type
  TArdGlyphPickEvent = procedure(ACode: Integer) of object;

  TArdGlyphPanel = class(TUiPanel)
  private
    FTitle: TUiLabel;
    FBar: TUiScrollBar;
    FView: TPaintBox;
    FSheet: TBitmap;          // все знаки, ширина - по FView
    FData: array of Byte;
    FFontName: string;        // имя массива шрифта
    FShownName: string;       // как шрифт записан в коде (имя или #define)
    FSizeX, FSizeY: Integer;
    FFirstChar, FCharCount: Integer;
    FScale: Integer;          // мелкие шрифты - вдвое
    FCols: Integer;
    FTopPos: Integer;
    FHotCode: Integer;        // знак под мышью, -1 - нет
    FHasFont: Boolean;
    FMessage: string;         // текст вместо знаков (шрифт не найден)
    FTarget: string;          // куда вставляется знак - для подсказки
    FOnPick: TArdGlyphPickEvent;
    function CellWidth: Integer;
    function CellHeight: Integer;
    function GlyphOffset(ACode: Integer): Integer;
    function CodeAt(PosX, PosY: Integer): Integer;
    procedure BuildSheet;
    procedure UpdateScroll;
    procedure UpdateTitle;
    procedure ViewPaint(Sender: TObject);
    procedure ViewMouseMove(Sender: TObject; Shift: TShiftState;
                            PosX, PosY: Integer);
    procedure ViewMouseDown(Sender: TObject; Button: TMouseButton;
                            Shift: TShiftState; PosX, PosY: Integer);
    procedure BarChange(Sender: TObject);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    // размер поля глифов меняется вместе с панелью (FView - alClient):
    // у TPaintBox в Delphi 7 нет OnResize
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // AShownName - как шрифт записан в коде (имя или #define);
    // ATarget - подпись поля, куда идёт знак (Caption, Arg1...)
    procedure SetFont(AFont: TUtftFont; const AShownName, ATarget: string);
    procedure ClearFont(const AMessage: string);
    // Высота, при которой видны все знаки (без полосы прокрутки)
    function PreferredHeight(AWidth: Integer): Integer;
    property HasFont: Boolean read FHasFont;
    property FontName: string read FFontName;
    property OnPick: TArdGlyphPickEvent read FOnPick write FOnPick;
  end;

implementation

uses
  EdScheme;   // EdUiText - знак cp1251 в кодировке интерфейса

const
  // Цвета - как образец в Font Viewer
  GlyphColor = clWhite;
  ScreenColor = clBlack;
  CellColor = $00242424;     // клетка через одну
  MissingColor = $00000050;  // знака нет в данных
  HotColor = $0000FFFF;      // рамка знака под мышью - жёлтая

constructor TArdGlyphPanel.Create(AOwner: TComponent);
var
  BarWidth: Integer;
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  FHotCode := -1;
  FScale := 1;

  FTitle := TUiLabel.Create(Self);
  FTitle.Parent := Self;
  FTitle.Align := alTop;
  FTitle.AutoSize := False;
  FTitle.Height := 18;
  FTitle.Caption := '';
  FTitle.ShowAccelChar := False;

  BarWidth := GetSystemMetrics(SM_CXVSCROLL);
  if BarWidth < 12 then
    BarWidth := 17;
  FBar := TUiScrollBar.Create(Self);
  FBar.Parent := Self;
  FBar.Kind := sbVertical;
  FBar.Align := alRight;
  FBar.Width := BarWidth;
  FBar.OnChange := BarChange;

  FView := TPaintBox.Create(Self);
  FView.Parent := Self;
  FView.Align := alClient;
  FView.OnPaint := ViewPaint;
  FView.OnMouseMove := ViewMouseMove;
  FView.OnMouseDown := ViewMouseDown;
end;

destructor TArdGlyphPanel.Destroy;
begin
  FSheet.Free;
  inherited Destroy;
end;

function TArdGlyphPanel.CellWidth: Integer;
begin
  Result := FSizeX * FScale;
end;

function TArdGlyphPanel.CellHeight: Integer;
begin
  Result := FSizeY * FScale;
end;

function TArdGlyphPanel.GlyphOffset(ACode: Integer): Integer;
begin
  Result := -1;
  if (ACode < FFirstChar) or (ACode >= FFirstChar + FCharCount) then
    Exit;
  Result := 4 + (ACode - FFirstChar) * (FSizeX div 8) * FSizeY;
  if Result + (FSizeX div 8) * FSizeY > Length(FData) then
    Result := -1;
end;

procedure TArdGlyphPanel.SetFont(AFont: TUtftFont; const AShownName,
  ATarget: string);
var
  ByteIdx: Integer;
begin
  FTarget := ATarget;
  if (AFont <> nil) and (AFont.Name = FFontName) and FHasFont and
     (Length(FData) = Length(AFont.Data)) then
  begin
    // тот же шрифт - только подпись (поле могло смениться)
    FShownName := AShownName;
    UpdateTitle;
    Exit;
  end;
  FHasFont := (AFont <> nil) and AFont.IsFont and (AFont.SizeX >= 8) and
              (AFont.SizeY > 0);
  FMessage := '';
  FHotCode := -1;
  FTopPos := 0;
  if not FHasFont then
  begin
    ClearFont('Шрифт ' + AShownName + ' не разобран');
    Exit;
  end;
  FFontName := AFont.Name;
  SetLength(FData, Length(AFont.Data));
  for ByteIdx := 0 to High(FData) do
    FData[ByteIdx] := AFont.Data[ByteIdx];
  FSizeX := AFont.SizeX;
  FSizeY := AFont.SizeY;
  FFirstChar := AFont.FirstChar;
  FCharCount := AFont.CharCount;
  if FSizeY < 16 then
    FScale := 2
  else
    FScale := 1;
  FShownName := AShownName;
  BuildSheet;
  UpdateTitle;
  FView.Invalidate;
end;

procedure TArdGlyphPanel.ClearFont(const AMessage: string);
begin
  FHasFont := False;
  FFontName := '';
  SetLength(FData, 0);
  FMessage := AMessage;
  FHotCode := -1;
  FTopPos := 0;
  FreeAndNil(FSheet);
  UpdateScroll;
  UpdateTitle;
  FView.Invalidate;
end;

function TArdGlyphPanel.PreferredHeight(AWidth: Integer): Integer;
var
  Cols, Rows: Integer;
begin
  Result := FTitle.Height + 4;
  if not FHasFont or (CellWidth = 0) then
    Exit;
  Cols := (AWidth - FBar.Width) div CellWidth;
  if Cols < 1 then
    Cols := 1;
  Rows := (FCharCount + Cols - 1) div Cols;
  Result := Result + Rows * CellHeight;
end;

procedure TArdGlyphPanel.BuildSheet;
var
  CodeIdx, Code, Offset, CellX, CellY, Row, Part, Bit, RunStart: Integer;
  BytesPerRow, Rows: Integer;
  Bits: Byte;
  Canvas: TCanvas;
begin
  FreeAndNil(FSheet);
  if not FHasFont then
    Exit;
  FCols := FView.Width div CellWidth;
  if FCols < 1 then
    FCols := 1;
  Rows := (FCharCount + FCols - 1) div FCols;
  FSheet := TBitmap.Create;
  FSheet.PixelFormat := pf24bit;
  FSheet.Width := FCols * CellWidth;
  FSheet.Height := Rows * CellHeight;
  Canvas := FSheet.Canvas;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := ScreenColor;
  Canvas.FillRect(Rect(0, 0, FSheet.Width, FSheet.Height));
  BytesPerRow := FSizeX div 8;
  for CodeIdx := 0 to FCharCount - 1 do
  begin
    Code := FFirstChar + CodeIdx;
    CellX := (CodeIdx mod FCols) * CellWidth;
    CellY := (CodeIdx div FCols) * CellHeight;
    Offset := GlyphOffset(Code);
    if Offset < 0 then
    begin
      Canvas.Brush.Color := MissingColor;
      Canvas.FillRect(Rect(CellX, CellY, CellX + CellWidth, CellY + CellHeight));
      Continue;
    end;
    // Клетки через одну - темнее: видно, где кончается знак
    if Odd(CodeIdx mod FCols + CodeIdx div FCols) then
    begin
      Canvas.Brush.Color := CellColor;
      Canvas.FillRect(Rect(CellX, CellY, CellX + CellWidth, CellY + CellHeight));
    end;
    Canvas.Brush.Color := GlyphColor;
    for Row := 0 to FSizeY - 1 do
    begin
      RunStart := -1;
      for Part := 0 to BytesPerRow - 1 do
      begin
        Bits := FData[Offset + Row * BytesPerRow + Part];
        for Bit := 0 to 7 do
          if (Bits and ($80 shr Bit)) <> 0 then
          begin
            if RunStart < 0 then
              RunStart := Part * 8 + Bit;
          end
          else if RunStart >= 0 then
          begin
            Canvas.FillRect(Rect(CellX + RunStart * FScale, CellY + Row * FScale,
              CellX + (Part * 8 + Bit) * FScale, CellY + (Row + 1) * FScale));
            RunStart := -1;
          end;
      end;
      if RunStart >= 0 then
        Canvas.FillRect(Rect(CellX + RunStart * FScale, CellY + Row * FScale,
          CellX + CellWidth, CellY + (Row + 1) * FScale));
    end;
  end;
  UpdateScroll;
end;

procedure TArdGlyphPanel.UpdateScroll;
var
  Page, MaxPos, Total: Integer;
begin
  Page := FView.Height;
  if Page < 1 then
    Page := 1;
  Total := 0;
  if FSheet <> nil then
    Total := FSheet.Height;
  MaxPos := Total - Page;
  if MaxPos < 0 then
    MaxPos := 0;
  if FTopPos > MaxPos then
    FTopPos := MaxPos;
  FBar.SmallChange := CellHeight;
  if FBar.SmallChange < 1 then
    FBar.SmallChange := 16;
  FBar.LargeChange := Page;
  FBar.Max := MaxPos;
  FBar.Position := FTopPos;
  FBar.Enabled := MaxPos > 0;
end;

procedure TArdGlyphPanel.UpdateTitle;
var
  Text: string;
begin
  if not FHasFont then
  begin
    FTitle.Caption := ' ' + FMessage;
    Exit;
  end;
  Text := ' ' + FShownName;
  if FShownName <> FFontName then
    Text := Text + ' (' + FFontName + ')';
  Text := Text + '  ' + IntToStr(FSizeX) + 'x' + IntToStr(FSizeY);
  if FHotCode >= 0 then
  begin
    Text := Text + '   ' + IntToStr(FHotCode) + ' ($' + IntToHex(FHotCode, 2) + ')';
    if FHotCode > 32 then
      Text := Text + ' ''' + EdUiText(Chr(FHotCode)) + '''';
  end;
  if FTarget <> '' then
    Text := Text + '   - щелчок: знак в ' + FTarget;
  FTitle.Caption := Text;
end;

function TArdGlyphPanel.CodeAt(PosX, PosY: Integer): Integer;
var
  Col, Row, CodeIdx: Integer;
begin
  Result := -1;
  if not FHasFont or (FSheet = nil) or (PosX < 0) or (PosY < 0) then
    Exit;
  Col := PosX div CellWidth;
  Row := (PosY + FTopPos) div CellHeight;
  if Col >= FCols then
    Exit;
  CodeIdx := Row * FCols + Col;
  if CodeIdx < FCharCount then
    Result := FFirstChar + CodeIdx;
end;

procedure TArdGlyphPanel.ViewPaint(Sender: TObject);
var
  Canvas: TCanvas;
  CodeIdx, CellX, CellY: Integer;
begin
  Canvas := FView.Canvas;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := ScreenColor;
  if FSheet = nil then
  begin
    Canvas.FillRect(Rect(0, 0, FView.Width, FView.Height));
    Exit;
  end;
  Canvas.Draw(0, -FTopPos, FSheet);
  if FSheet.Width < FView.Width then
    Canvas.FillRect(Rect(FSheet.Width, 0, FView.Width, FView.Height));
  if FSheet.Height - FTopPos < FView.Height then
    Canvas.FillRect(Rect(0, FSheet.Height - FTopPos, FView.Width, FView.Height));
  if FHotCode >= 0 then
  begin
    CodeIdx := FHotCode - FFirstChar;
    CellX := (CodeIdx mod FCols) * CellWidth;
    CellY := (CodeIdx div FCols) * CellHeight - FTopPos;
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Color := HotColor;
    Canvas.Pen.Width := 1;
    Canvas.Rectangle(CellX, CellY, CellX + CellWidth, CellY + CellHeight);
    Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TArdGlyphPanel.Resize;
begin
  inherited Resize;
  if FView = nil then
    Exit;
  if FHasFont and ((FSheet = nil) or (FView.Width div CellWidth <> FCols)) then
    BuildSheet
  else
    UpdateScroll;
  FView.Invalidate;
end;

procedure TArdGlyphPanel.ViewMouseMove(Sender: TObject; Shift: TShiftState;
  PosX, PosY: Integer);
var
  Code: Integer;
begin
  Code := CodeAt(PosX, PosY);
  if Code = FHotCode then
    Exit;
  FHotCode := Code;
  UpdateTitle;
  FView.Invalidate;
end;

procedure TArdGlyphPanel.ViewMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; PosX, PosY: Integer);
var
  Code: Integer;
begin
  if Button <> mbLeft then
    Exit;
  Code := CodeAt(PosX, PosY);
  if (Code >= 32) and Assigned(FOnPick) then
    FOnPick(Code);
end;

procedure TArdGlyphPanel.BarChange(Sender: TObject);
begin
  FTopPos := FBar.Position;
  FView.Invalidate;
end;

procedure TArdGlyphPanel.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotCode >= 0 then
  begin
    FHotCode := -1;
    UpdateTitle;
    FView.Invalidate;
  end;
end;

end.
