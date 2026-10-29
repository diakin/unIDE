unit EdView;

// ---------------------------------------------------------------------------
//  Окно текста своего редактора unIDE (план портирования, шаг 0.7.2):
//  показывает TEdBuffer (EdBuffer.pas). Пока только просмотр: отрисовка,
//  каретка, прокрутка, переходы клавишами и мышью. Правка, выделение мышью
//  и клавишами, буфер обмена - шаг 0.7.3.
//
//  - Шрифт моноширинный: каждый символ - ячейка CharW x LineH. X символа =
//    (колонка с раскрытыми табуляциями) x CharW; обратно - делением. Замеры
//    ширины строк не нужны.
//  - Вывод - ExtTextOutW с шагом CharW на каждый символ: знак стоит в своей
//    ячейке и у жирного начертания. Табуляции раскрывает сам редактор.
//  - Цвета кусков строки даёт владелец (OnLineRuns): подсветка - не дело
//    окна. Нет обработчика - строка цветом текста.
//  - Слева - номера строк (поле Gutter), справа и снизу - полосы прокрутки
//    (в Delphi 7 - TUiScrollBar по теме IDE, в Lazarus - TScrollBar).
//  - Буфер не принадлежит окну; изменения буфера окно получает подпиской
//    (AddListener) и перерисовывается.
//
//  Собирается Delphi 7 (VCL) и Free Pascal / Lazarus (LCL).
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  {$IFDEF FPC}
  LCLIntf, LCLType, LMessages,
  {$IFDEF MSWINDOWS}Windows,{$ENDIF}
  {$ELSE}
  Windows, Messages,
  {$ENDIF}
  SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  {$IFNDEF FPC}UiScroll,{$ENDIF}
  EdBuffer;

type
  {$IFDEF FPC}
  TEdScrollBar = TScrollBar;
  {$ELSE}
  TEdScrollBar = TUiScrollBar;
  {$ENDIF}

  // Кусок строки одного вида: символы Start .. Start + Len - 1 (с 0)
  TEdRun = record
    Start: Integer;
    Len: Integer;
    Fore: TColor;          // clNone - цвет текста окна
    Back: TColor;          // clNone - фон строки
    Style: TFontStyles;
  end;
  TEdRuns = array of TEdRun;

  // Куски строки ARow (текст - ALine). Куски - по возрастанию Start, без
  // наложений; не покрытое кусками - цветом текста. ARuns растёт по
  // надобности, ACount - сколько кусков заполнено
  TEdLineRunsEvent = procedure(Sender: TObject; ARow: Integer;
    const ALine: WideString; var ARuns: TEdRuns;
    var ACount: Integer) of object;

  TEdView = class(TCustomControl)
  private
    FBuffer: TEdBuffer;
    FTopRow: Integer;          // первая видимая строка
    FLeftCol: Integer;         // первая видимая колонка экрана
    FCaretRow: Integer;
    FCaretCol: Integer;        // символ в строке (с 0)
    FPrefCol: Integer;         // колонка экрана для движения вверх-вниз
    FSelActive: Boolean;       // выделение: от (FSelRow, FSelCol) до каретки
    FSelRow: Integer;
    FSelCol: Integer;
    FTabSize: Integer;
    FCharW: Integer;
    FLineH: Integer;
    FMetricsValid: Boolean;
    FShowGutter: Boolean;
    FGutterW: Integer;
    FMaxCols: Integer;         // ширина самой длинной строки, колонок
    FMaxColsValid: Boolean;
    FTextColor: TColor;
    FBackColor: TColor;
    FGutterColor: TColor;
    FGutterTextColor: TColor;
    FGutterCurColor: TColor;   // номер строки с кареткой: фон
    FGutterCurText: TColor;    // и цвет
    FCurLineColor: TColor;     // фон строки с кареткой; clNone - нет
    FSelColor: TColor;
    FSelTextColor: TColor;
    FVBar: TEdScrollBar;
    FHBar: TEdScrollBar;
    FBarSize: Integer;
    FBack: TBitmap;            // кадр целиком, потом - на экран одним вызовом
    FRuns: TEdRuns;
    FCaretMade: Boolean;
    FLockBars: Boolean;
    FOnLineRuns: TEdLineRunsEvent;
    FOnCaretMove: TNotifyEvent;
    // Ячейки видимой части строки (отрисовка)
    FCellText: WideString;
    FCellFore: array of TColor;
    FCellBack: array of TColor;
    FCellStyle: array of Byte;
    FDx: array of Integer;
    procedure SetBuffer(AValue: TEdBuffer);
    procedure BufferChanged(Sender: TObject; AFirst, AOldCount,
      ANewCount: Integer);
    procedure SetTabSize(AValue: Integer);
    procedure SetShowGutter(AValue: Boolean);
    procedure UpdateMetrics;
    procedure UpdateGutterWidth;
    function GetMaxCols: Integer;
    procedure LayoutBars;
    procedure UpdateBars;
    procedure VBarChange(Sender: TObject);
    procedure HBarChange(Sender: TObject);
    procedure MakeCaret;
    procedure KillCaret;
    procedure PlaceCaret;
    procedure PaintRow(ACanvas: TCanvas; ARow, AY, ATextW: Integer);
    procedure PaintGutterRow(ACanvas: TCanvas; ARow, AY: Integer);
    procedure OutCells(ACanvas: TCanvas; AX, AY, ACount: Integer);
    function RowLength(ARow: Integer): Integer;
    {$IFDEF FPC}
    procedure WMGetDlgCode(var Message: TLMNoParams); message LM_GETDLGCODE;
    procedure WMSetFocus(var Message: TLMSetFocus); message LM_SETFOCUS;
    procedure WMKillFocus(var Message: TLMKillFocus); message LM_KILLFOCUS;
    procedure WMEraseBkgnd(var Message: TLMEraseBkgnd); message LM_ERASEBKGND;
    {$ELSE}
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    {$ENDIF}
    {$IFDEF FPC}
    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;
    {$ELSE}
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    {$ENDIF}
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Видимых строк и колонок текста (целых)
    function VisibleRows: Integer;
    function VisibleCols: Integer;
    // Колонка экрана символа ACol строки ARow (табуляции раскрыты) и
    // обратно - символ под колонкой экрана (табуляция: правее середины -
    // после неё)
    function ScreenCol(ARow, ACol: Integer): Integer;
    function ColAtScreen(ARow, AScreenCol: Integer): Integer;
    // Символ под точкой окна
    procedure PosAt(AX, AY: Integer; var ARow, ACol: Integer);
    // Каретку в (ARow, ACol); AKeepPref - не менять колонку для движения
    // вверх-вниз. Окно прокручивается к каретке
    procedure CaretTo(ARow, ACol: Integer; AKeepPref: Boolean = False);
    // Выделение от (ARow, ACol) до каретки; снять - ClearSelection
    procedure SetSelection(ARow, ACol: Integer);
    procedure ClearSelection;
    function SelRange(var ARow1, ACol1, ARow2, ACol2: Integer): Boolean;
    procedure ScrollTo(ATopRow, ALeftCol: Integer);
    procedure EnsureCaretVisible;
    // Шрифт, цвета или разбор подсветки менялись - пересчитать и
    // перерисовать всё
    procedure RefreshAll;

    property Buffer: TEdBuffer read FBuffer write SetBuffer;
    property TopRow: Integer read FTopRow;
    property LeftCol: Integer read FLeftCol;
    property CaretRow: Integer read FCaretRow;
    property CaretCol: Integer read FCaretCol;
    property CharW: Integer read FCharW;
    property LineH: Integer read FLineH;
    property GutterWidth: Integer read FGutterW;
    property TabSize: Integer read FTabSize write SetTabSize;
    property ShowGutter: Boolean read FShowGutter write SetShowGutter;
    property TextColor: TColor read FTextColor write FTextColor;
    property BackColor: TColor read FBackColor write FBackColor;
    property GutterColor: TColor read FGutterColor write FGutterColor;
    property GutterTextColor: TColor read FGutterTextColor
      write FGutterTextColor;
    property GutterCurColor: TColor read FGutterCurColor write FGutterCurColor;
    property GutterCurText: TColor read FGutterCurText write FGutterCurText;
    property CurLineColor: TColor read FCurLineColor write FCurLineColor;
    property SelColor: TColor read FSelColor write FSelColor;
    property SelTextColor: TColor read FSelTextColor write FSelTextColor;
    property OnLineRuns: TEdLineRunsEvent read FOnLineRuns write FOnLineRuns;
    property OnCaretMove: TNotifyEvent read FOnCaretMove write FOnCaretMove;
    property Font;
    property TabStop;
    property Align;
    property PopupMenu;
  end;

implementation

const
  // Байт стиля ячейки: биты TFontStyle
  EdStyleBold = 1;
  EdStyleItalic = 2;
  EdStyleUnderline = 4;

function EdStyleByte(AStyle: TFontStyles): Byte;
begin
  Result := 0;
  if fsBold in AStyle then
    Result := Result or EdStyleBold;
  if fsItalic in AStyle then
    Result := Result or EdStyleItalic;
  if fsUnderline in AStyle then
    Result := Result or EdStyleUnderline;
end;

function EdByteStyle(AByte: Byte): TFontStyles;
begin
  Result := [];
  if AByte and EdStyleBold <> 0 then
    Include(Result, fsBold);
  if AByte and EdStyleItalic <> 0 then
    Include(Result, fsItalic);
  if AByte and EdStyleUnderline <> 0 then
    Include(Result, fsUnderline);
end;

// ---------------------------------------------------------------------------

constructor TEdView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Кадр - первым: смена шрифта ниже уже меряет ячейку по нему
  FBack := TBitmap.Create;
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse, csClickEvents];
  TabStop := True;
  FTabSize := 8;
  FShowGutter := True;
  FTextColor := clWindowText;
  FBackColor := clWindow;
  FGutterColor := clBtnFace;
  FGutterTextColor := clGrayText;
  FGutterCurColor := clNone;
  FGutterCurText := clWindowText;
  FCurLineColor := clNone;
  FSelColor := clHighlight;
  FSelTextColor := clHighlightText;
  Font.Name := 'Courier New';
  Font.Size := 10;
  FBarSize := GetSystemMetrics(SM_CXVSCROLL);
  FVBar := TEdScrollBar.Create(Self);
  FVBar.Kind := sbVertical;
  FVBar.TabStop := False;
  FVBar.Parent := Self;
  FVBar.OnChange := VBarChange;
  FHBar := TEdScrollBar.Create(Self);
  FHBar.Kind := sbHorizontal;
  FHBar.TabStop := False;
  FHBar.Parent := Self;
  FHBar.OnChange := HBarChange;
  // Размер - после полос: Resize раскладывает их
  Width := 400;
  Height := 300;
end;

destructor TEdView.Destroy;
begin
  SetBuffer(nil);
  FBack.Free;
  inherited Destroy;
end;

procedure TEdView.SetBuffer(AValue: TEdBuffer);
begin
  if AValue = FBuffer then
    Exit;
  if FBuffer <> nil then
    FBuffer.RemoveListener(BufferChanged);
  FBuffer := AValue;
  if FBuffer <> nil then
    FBuffer.AddListener(BufferChanged);
  FTopRow := 0;
  FLeftCol := 0;
  FCaretRow := 0;
  FCaretCol := 0;
  FPrefCol := 0;
  FSelActive := False;
  FMaxColsValid := False;
  UpdateGutterWidth;
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

// Буфер изменился: каретка - в пределах текста, ширина - пересчитать
procedure TEdView.BufferChanged(Sender: TObject; AFirst, AOldCount,
  ANewCount: Integer);
begin
  FMaxColsValid := False;
  if FCaretRow >= FBuffer.Count then
    FCaretRow := FBuffer.Count - 1;
  if FCaretCol > FBuffer.LineLength(FCaretRow) then
    FCaretCol := FBuffer.LineLength(FCaretRow);
  if FSelRow >= FBuffer.Count then
  begin
    FSelRow := FBuffer.Count - 1;
    FSelCol := FBuffer.LineLength(FSelRow);
  end;
  UpdateGutterWidth;
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

procedure TEdView.SetTabSize(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;
  if AValue = FTabSize then
    Exit;
  FTabSize := AValue;
  FMaxColsValid := False;
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

procedure TEdView.SetShowGutter(AValue: Boolean);
begin
  if AValue = FShowGutter then
    Exit;
  FShowGutter := AValue;
  UpdateGutterWidth;
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

procedure TEdView.RefreshAll;
begin
  FMetricsValid := False;
  UpdateMetrics;
  UpdateGutterWidth;
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

// Ячейка символа - по шрифту окна
procedure TEdView.UpdateMetrics;
begin
  if FMetricsValid then
    Exit;
  FBack.Canvas.Font.Assign(Font);
  FCharW := FBack.Canvas.TextWidth('M');
  FLineH := FBack.Canvas.TextHeight('Wg');
  if FCharW < 1 then
    FCharW := 1;
  if FLineH < 1 then
    FLineH := 1;
  FMetricsValid := True;
end;

procedure TEdView.UpdateGutterWidth;
var
  Digits, LineCount: Integer;
begin
  UpdateMetrics;
  if not FShowGutter then
  begin
    FGutterW := 0;
    Exit;
  end;
  LineCount := 1;
  if FBuffer <> nil then
    LineCount := FBuffer.Count;
  Digits := Length(IntToStr(LineCount));
  if Digits < 3 then
    Digits := 3;
  FGutterW := (Digits + 2) * FCharW;
end;

{$IFDEF FPC}
procedure TEdView.CMFontChanged(var Message: TLMessage);
{$ELSE}
procedure TEdView.CMFontChanged(var Message: TMessage);
{$ENDIF}
begin
  inherited;
  FMetricsValid := False;
  // Из конструктора - полос ещё нет
  if FVBar = nil then
    Exit;
  if FCaretMade then
  begin
    KillCaret;
    MakeCaret;
  end;
  UpdateGutterWidth;
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

function TEdView.RowLength(ARow: Integer): Integer;
begin
  if FBuffer = nil then
    Result := 0
  else
    Result := FBuffer.LineLength(ARow);
end;

// Ширина самой длинной строки (колонки экрана). Считается заново после
// правки - по надобности, при обновлении полос
function TEdView.GetMaxCols: Integer;
var
  RowIdx, Cols: Integer;
begin
  if not FMaxColsValid then
  begin
    FMaxCols := 0;
    if FBuffer <> nil then
      for RowIdx := 0 to FBuffer.Count - 1 do
      begin
        Cols := ScreenCol(RowIdx, MaxInt);
        if Cols > FMaxCols then
          FMaxCols := Cols;
      end;
    FMaxColsValid := True;
  end;
  Result := FMaxCols;
end;

function TEdView.ScreenCol(ARow, ACol: Integer): Integer;
var
  Line: WideString;
  CharIdx, Limit: Integer;
begin
  Result := 0;
  if FBuffer = nil then
    Exit;
  Line := FBuffer[ARow];
  Limit := ACol;
  if Limit > Length(Line) then
    Limit := Length(Line);
  for CharIdx := 1 to Limit do
    if Line[CharIdx] = #9 then
      Result := (Result div FTabSize + 1) * FTabSize
    else
      Inc(Result);
end;

function TEdView.ColAtScreen(ARow, AScreenCol: Integer): Integer;
var
  Line: WideString;
  CharIdx, CellPos, NextPos: Integer;
begin
  Result := 0;
  if FBuffer = nil then
    Exit;
  Line := FBuffer[ARow];
  CellPos := 0;
  for CharIdx := 1 to Length(Line) do
  begin
    if Line[CharIdx] = #9 then
      NextPos := (CellPos div FTabSize + 1) * FTabSize
    else
      NextPos := CellPos + 1;
    if AScreenCol < NextPos then
    begin
      if (Line[CharIdx] = #9) and
         (AScreenCol - CellPos > (NextPos - CellPos) div 2) then
        Result := CharIdx
      else
        Result := CharIdx - 1;
      Exit;
    end;
    CellPos := NextPos;
  end;
  Result := Length(Line);
end;

function TEdView.VisibleRows: Integer;
begin
  UpdateMetrics;
  Result := (ClientHeight - FBarSize) div FLineH;
  if Result < 1 then
    Result := 1;
end;

function TEdView.VisibleCols: Integer;
begin
  UpdateMetrics;
  Result := (ClientWidth - FBarSize - FGutterW) div FCharW;
  if Result < 1 then
    Result := 1;
end;

procedure TEdView.PosAt(AX, AY: Integer; var ARow, ACol: Integer);
var
  ScreenColumn: Integer;
begin
  UpdateMetrics;
  ARow := 0;
  ACol := 0;
  if FBuffer = nil then
    Exit;
  if AY < 0 then
    AY := 0;
  ARow := FTopRow + AY div FLineH;
  if ARow >= FBuffer.Count then
    ARow := FBuffer.Count - 1;
  // Ближе к правому краю ячейки - после символа
  ScreenColumn := FLeftCol + (AX - FGutterW + FCharW div 2) div FCharW;
  if AX < FGutterW then
    ScreenColumn := FLeftCol;
  if ScreenColumn < 0 then
    ScreenColumn := 0;
  ACol := ColAtScreen(ARow, ScreenColumn);
end;

// ---------------------------------------------------------------------------
//  Полосы прокрутки
// ---------------------------------------------------------------------------

procedure TEdView.LayoutBars;
begin
  FVBar.SetBounds(ClientWidth - FBarSize, 0, FBarSize,
    ClientHeight - FBarSize);
  FHBar.SetBounds(0, ClientHeight - FBarSize, ClientWidth - FBarSize,
    FBarSize);
end;

// Диапазон и место полос. В Delphi 7 (TUiScrollBar) Max - наибольшее место,
// ползунок - LargeChange; в LCL (TScrollBar) Max - конец всего, PageSize -
// видимая часть
procedure TEdView.UpdateBars;
var
  RowMax, ColMax, PageRows, PageCols: Integer;
begin
  if FBuffer = nil then
  begin
    RowMax := 0;
    ColMax := 0;
  end
  else
  begin
    RowMax := FBuffer.Count - VisibleRows;
    ColMax := GetMaxCols + 1 - VisibleCols;
  end;
  if RowMax < 0 then
    RowMax := 0;
  if ColMax < 0 then
    ColMax := 0;
  if FTopRow > RowMax then
    FTopRow := RowMax;
  if FLeftCol > ColMax then
    FLeftCol := ColMax;
  PageRows := VisibleRows;
  PageCols := VisibleCols;
  FLockBars := True;
  try
    {$IFDEF FPC}
    FVBar.SetParams(FTopRow, 0, RowMax + PageRows - 1, PageRows);
    FVBar.LargeChange := PageRows;
    FHBar.SetParams(FLeftCol, 0, ColMax + PageCols - 1, PageCols);
    FHBar.LargeChange := PageCols;
    {$ELSE}
    FVBar.Max := RowMax;
    FVBar.LargeChange := PageRows;
    FVBar.Position := FTopRow;
    FHBar.Max := ColMax;
    FHBar.LargeChange := PageCols;
    FHBar.Position := FLeftCol;
    {$ENDIF}
    FVBar.SmallChange := 1;
    FHBar.SmallChange := 1;
  finally
    FLockBars := False;
  end;
end;

procedure TEdView.VBarChange(Sender: TObject);
begin
  if FLockBars then
    Exit;
  ScrollTo(FVBar.Position, FLeftCol);
end;

procedure TEdView.HBarChange(Sender: TObject);
begin
  if FLockBars then
    Exit;
  ScrollTo(FTopRow, FHBar.Position);
end;

procedure TEdView.ScrollTo(ATopRow, ALeftCol: Integer);
var
  RowMax: Integer;
begin
  RowMax := 0;
  if FBuffer <> nil then
    RowMax := FBuffer.Count - VisibleRows;
  if ATopRow > RowMax then
    ATopRow := RowMax;
  if ATopRow < 0 then
    ATopRow := 0;
  if ALeftCol < 0 then
    ALeftCol := 0;
  if (ATopRow = FTopRow) and (ALeftCol = FLeftCol) then
    Exit;
  FTopRow := ATopRow;
  FLeftCol := ALeftCol;
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

procedure TEdView.EnsureCaretVisible;
var
  NewTop, NewLeft, CaretScreen, Margin: Integer;
begin
  NewTop := FTopRow;
  NewLeft := FLeftCol;
  if FCaretRow < NewTop then
    NewTop := FCaretRow
  else if FCaretRow >= NewTop + VisibleRows then
    NewTop := FCaretRow - VisibleRows + 1;
  CaretScreen := ScreenCol(FCaretRow, FCaretCol);
  // Вбок - с запасом в четверть окна, чтобы не двигать на каждый символ
  Margin := VisibleCols div 4;
  if CaretScreen < NewLeft then
    NewLeft := CaretScreen - Margin
  else if CaretScreen >= NewLeft + VisibleCols then
    NewLeft := CaretScreen - VisibleCols + 1 + Margin;
  if NewLeft < 0 then
    NewLeft := 0;
  if (NewTop <> FTopRow) or (NewLeft <> FLeftCol) then
  begin
    FTopRow := NewTop;
    FLeftCol := NewLeft;
    UpdateBars;
    Invalidate;
  end;
  PlaceCaret;
end;

procedure TEdView.Resize;
begin
  inherited Resize;
  // Из конструктора (размер задаётся) - полос ещё нет
  if FVBar = nil then
    Exit;
  LayoutBars;
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

// ---------------------------------------------------------------------------
//  Каретка и выделение
// ---------------------------------------------------------------------------

procedure TEdView.MakeCaret;
begin
  if FCaretMade or not HandleAllocated then
    Exit;
  UpdateMetrics;
  {$IFDEF FPC}
  LCLIntf.CreateCaret(Handle, 0, 2, FLineH);
  {$ELSE}
  CreateCaret(Handle, 0, 2, FLineH);
  {$ENDIF}
  FCaretMade := True;
  PlaceCaret;
  {$IFDEF FPC}
  LCLIntf.ShowCaret(Handle);
  {$ELSE}
  ShowCaret(Handle);
  {$ENDIF}
end;

procedure TEdView.KillCaret;
begin
  if not FCaretMade then
    Exit;
  FCaretMade := False;
  {$IFDEF FPC}
  LCLIntf.DestroyCaret(Handle);
  {$ELSE}
  DestroyCaret;
  {$ENDIF}
end;

procedure TEdView.PlaceCaret;
var
  CaretX, CaretY: Integer;
begin
  if not FCaretMade then
    Exit;
  CaretX := FGutterW + (ScreenCol(FCaretRow, FCaretCol) - FLeftCol) * FCharW;
  CaretY := (FCaretRow - FTopRow) * FLineH;
  // Вне текста - за краем окна (каретка не видна)
  if (CaretX < FGutterW) or (CaretY < 0) then
  begin
    CaretX := -100;
    CaretY := -100;
  end;
  {$IFDEF FPC}
  LCLIntf.SetCaretPosEx(Handle, CaretX, CaretY);
  {$ELSE}
  SetCaretPos(CaretX, CaretY);
  {$ENDIF}
end;

procedure TEdView.CaretTo(ARow, ACol: Integer; AKeepPref: Boolean);
var
  OldRow: Integer;
begin
  if FBuffer = nil then
    Exit;
  if ARow < 0 then
    ARow := 0;
  if ARow >= FBuffer.Count then
    ARow := FBuffer.Count - 1;
  if ACol < 0 then
    ACol := 0;
  if ACol > FBuffer.LineLength(ARow) then
    ACol := FBuffer.LineLength(ARow);
  OldRow := FCaretRow;
  FCaretRow := ARow;
  FCaretCol := ACol;
  if not AKeepPref then
    FPrefCol := ScreenCol(FCaretRow, FCaretCol);
  EnsureCaretVisible;
  // Строка с кареткой выделена фоном и номером - перерисовать обе
  if (OldRow <> FCaretRow) or FSelActive then
    Invalidate;
  if Assigned(FOnCaretMove) then
    FOnCaretMove(Self);
end;

procedure TEdView.SetSelection(ARow, ACol: Integer);
begin
  FSelActive := True;
  FSelRow := ARow;
  FSelCol := ACol;
  Invalidate;
end;

procedure TEdView.ClearSelection;
begin
  if not FSelActive then
    Exit;
  FSelActive := False;
  Invalidate;
end;

function TEdView.SelRange(var ARow1, ACol1, ARow2, ACol2: Integer): Boolean;
begin
  Result := FSelActive and ((FSelRow <> FCaretRow) or (FSelCol <> FCaretCol));
  if not Result then
    Exit;
  if (FSelRow < FCaretRow) or
     ((FSelRow = FCaretRow) and (FSelCol < FCaretCol)) then
  begin
    ARow1 := FSelRow;
    ACol1 := FSelCol;
    ARow2 := FCaretRow;
    ACol2 := FCaretCol;
  end
  else
  begin
    ARow1 := FCaretRow;
    ACol1 := FCaretCol;
    ARow2 := FSelRow;
    ACol2 := FSelCol;
  end;
end;

// ---------------------------------------------------------------------------
//  Отрисовка
// ---------------------------------------------------------------------------

{$IFDEF FPC}
procedure TEdView.WMEraseBkgnd(var Message: TLMEraseBkgnd);
{$ELSE}
procedure TEdView.WMEraseBkgnd(var Message: TWMEraseBkgnd);
{$ENDIF}
begin
  // Фон рисует Paint целиком - стирание Windows только мигало бы
  Message.Result := 1;
end;

procedure TEdView.Paint;
var
  TextW, TextH, RowIdx, RowY, RowCount: Integer;
  AreaRect: TRect;
begin
  UpdateMetrics;
  TextW := ClientWidth - FBarSize;
  TextH := ClientHeight - FBarSize;
  if (TextW <= 0) or (TextH <= 0) then
    Exit;
  if (FBack.Width <> TextW) or (FBack.Height <> TextH) then
  begin
    FBack.Width := TextW;
    FBack.Height := TextH;
  end;
  FBack.Canvas.Font.Assign(Font);
  // Фон всего кадра: строки ниже конца текста, полоска внизу
  AreaRect := Rect(0, 0, TextW, TextH);
  FBack.Canvas.Brush.Style := bsSolid;
  FBack.Canvas.Brush.Color := FBackColor;
  FBack.Canvas.FillRect(AreaRect);
  if FGutterW > 0 then
  begin
    FBack.Canvas.Brush.Color := FGutterColor;
    FBack.Canvas.FillRect(Rect(0, 0, FGutterW, TextH));
  end;
  RowCount := TextH div FLineH + 1;
  for RowIdx := 0 to RowCount - 1 do
  begin
    RowY := RowIdx * FLineH;
    if (FBuffer = nil) or (FTopRow + RowIdx >= FBuffer.Count) then
      Break;
    PaintRow(FBack.Canvas, FTopRow + RowIdx, RowY, TextW);
    if FGutterW > 0 then
      PaintGutterRow(FBack.Canvas, FTopRow + RowIdx, RowY);
  end;
  Canvas.Draw(0, 0, FBack);
  // Квадрат между полосами
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FGutterColor;
  Canvas.FillRect(Rect(TextW, TextH, ClientWidth, ClientHeight));
end;

procedure TEdView.PaintGutterRow(ACanvas: TCanvas; ARow, AY: Integer);
var
  NumText: WideString;
  CellIdx, NumX: Integer;
  RowBack, RowFore: TColor;
begin
  RowBack := FGutterColor;
  RowFore := FGutterTextColor;
  if ARow = FCaretRow then
  begin
    if FGutterCurColor <> clNone then
      RowBack := FGutterCurColor;
    if FGutterCurText <> clNone then
      RowFore := FGutterCurText;
  end;
  // Номер - по правому краю, с одной пустой ячейкой справа
  NumText := WideString(IntToStr(ARow + 1));
  NumX := FGutterW - (Length(NumText) + 1) * FCharW;
  SetLength(FCellText, FGutterW div FCharW);
  for CellIdx := 1 to Length(FCellText) do
    FCellText[CellIdx] := ' ';
  SetLength(FCellFore, Length(FCellText));
  SetLength(FCellBack, Length(FCellText));
  SetLength(FCellStyle, Length(FCellText));
  for CellIdx := 0 to High(FCellFore) do
  begin
    FCellFore[CellIdx] := RowFore;
    FCellBack[CellIdx] := RowBack;
    FCellStyle[CellIdx] := 0;
    if ARow = FCaretRow then
      FCellStyle[CellIdx] := EdStyleBold;
  end;
  for CellIdx := 1 to Length(NumText) do
    if NumX div FCharW + CellIdx <= Length(FCellText) then
      FCellText[NumX div FCharW + CellIdx] := NumText[CellIdx];
  OutCells(ACanvas, 0, AY, Length(FCellText));
end;

// Строка ARow: ячейки видимых колонок, потом - куски одного вида
procedure TEdView.PaintRow(ACanvas: TCanvas; ARow, AY, ATextW: Integer);
var
  Line: WideString;
  CellCount, RunCount, RunIdx, CharIdx, ScreenPos, CellWidth, CellIdx,
  CellNo, Sel1Row, Sel1Col, Sel2Row, Sel2Col: Integer;
  RowBack, CharFore, CharBack: TColor;
  CharStyle: Byte;
  HasSel, CharSel, PastEndSel: Boolean;
  CharCode: WideChar;
begin
  CellCount := (ATextW - FGutterW) div FCharW + 1;
  if CellCount <= 0 then
    Exit;
  RowBack := FBackColor;
  if (ARow = FCaretRow) and (FCurLineColor <> clNone) then
    RowBack := FCurLineColor;
  // Пустые ячейки - пробелы фоном строки
  SetLength(FCellText, CellCount);
  SetLength(FCellFore, CellCount);
  SetLength(FCellBack, CellCount);
  SetLength(FCellStyle, CellCount);
  for CellIdx := 0 to CellCount - 1 do
  begin
    FCellText[CellIdx + 1] := ' ';
    FCellFore[CellIdx] := FTextColor;
    FCellBack[CellIdx] := RowBack;
    FCellStyle[CellIdx] := 0;
  end;
  Line := FBuffer[ARow];
  RunCount := 0;
  if Assigned(FOnLineRuns) and (Line <> '') then
    FOnLineRuns(Self, ARow, Line, FRuns, RunCount);
  HasSel := SelRange(Sel1Row, Sel1Col, Sel2Row, Sel2Col) and
    (ARow >= Sel1Row) and (ARow <= Sel2Row);
  RunIdx := 0;
  ScreenPos := 0;
  for CharIdx := 0 to Length(Line) - 1 do
  begin
    if ScreenPos >= FLeftCol + CellCount then
      Break;
    CharCode := Line[CharIdx + 1];
    if CharCode = #9 then
      CellWidth := FTabSize - ScreenPos mod FTabSize
    else
      CellWidth := 1;
    // Кусок, в который попал символ
    while (RunIdx < RunCount) and
          (FRuns[RunIdx].Start + FRuns[RunIdx].Len <= CharIdx) do
      Inc(RunIdx);
    CharFore := FTextColor;
    CharBack := RowBack;
    CharStyle := 0;
    if (RunIdx < RunCount) and (FRuns[RunIdx].Start <= CharIdx) then
    begin
      if FRuns[RunIdx].Fore <> clNone then
        CharFore := FRuns[RunIdx].Fore;
      if FRuns[RunIdx].Back <> clNone then
        CharBack := FRuns[RunIdx].Back;
      CharStyle := EdStyleByte(FRuns[RunIdx].Style);
    end;
    if HasSel then
    begin
      CharSel := ((ARow > Sel1Row) or (CharIdx >= Sel1Col)) and
                 ((ARow < Sel2Row) or (CharIdx < Sel2Col));
      if CharSel then
      begin
        CharFore := FSelTextColor;
        CharBack := FSelColor;
      end;
    end;
    if ScreenPos + CellWidth > FLeftCol then
      for CellNo := ScreenPos to ScreenPos + CellWidth - 1 do
        if (CellNo >= FLeftCol) and (CellNo < FLeftCol + CellCount) then
        begin
          CellIdx := CellNo - FLeftCol;
          if CharCode = #9 then
            FCellText[CellIdx + 1] := ' '
          else
            FCellText[CellIdx + 1] := CharCode;
          FCellFore[CellIdx] := CharFore;
          FCellBack[CellIdx] := CharBack;
          FCellStyle[CellIdx] := CharStyle;
        end;
    Inc(ScreenPos, CellWidth);
  end;
  // Выделение переходит на следующую строку - ячейка за концом строки
  PastEndSel := HasSel and (ARow < Sel2Row);
  if PastEndSel and (ScreenPos >= FLeftCol) and
     (ScreenPos < FLeftCol + CellCount) then
    FCellBack[ScreenPos - FLeftCol] := FSelColor;
  OutCells(ACanvas, FGutterW, AY, CellCount);
end;

// Ячейки FCellText[1 .. ACount] - кусками одного вида, каждый символ в
// своей ячейке CharW
procedure TEdView.OutCells(ACanvas: TCanvas; AX, AY, ACount: Integer);
var
  SpanStart, SpanEnd, DxIdx: Integer;
  SpanRect: TRect;
  {$IFDEF MSWINDOWS}
  DC: HDC;
  {$ELSE}
  CellIdx: Integer;
  CharText: string;
  {$ENDIF}
begin
  if Length(FDx) < ACount then
  begin
    SetLength(FDx, ACount);
    for DxIdx := 0 to High(FDx) do
      FDx[DxIdx] := FCharW;
  end;
  if FDx[0] <> FCharW then
    for DxIdx := 0 to High(FDx) do
      FDx[DxIdx] := FCharW;
  SpanStart := 0;
  while SpanStart < ACount do
  begin
    SpanEnd := SpanStart + 1;
    while (SpanEnd < ACount) and
          (FCellFore[SpanEnd] = FCellFore[SpanStart]) and
          (FCellBack[SpanEnd] = FCellBack[SpanStart]) and
          (FCellStyle[SpanEnd] = FCellStyle[SpanStart]) do
      Inc(SpanEnd);
    ACanvas.Font.Style := EdByteStyle(FCellStyle[SpanStart]);
    ACanvas.Font.Color := FCellFore[SpanStart];
    ACanvas.Brush.Color := FCellBack[SpanStart];
    SpanRect := Rect(AX + SpanStart * FCharW, AY, AX + SpanEnd * FCharW,
      AY + FLineH);
    {$IFDEF MSWINDOWS}
    // Шрифт - явно: Canvas.Handle сам выбрать его не обязан
    DC := ACanvas.Handle;
    SelectObject(DC, ACanvas.Font.Handle);
    SetBkColor(DC, ColorToRGB(FCellBack[SpanStart]));
    SetTextColor(DC, ColorToRGB(FCellFore[SpanStart]));
    Windows.ExtTextOutW(DC, SpanRect.Left, AY, ETO_OPAQUE or ETO_CLIPPED,
      @SpanRect, @FCellText[SpanStart + 1], SpanEnd - SpanStart, @FDx[0]);
    {$ELSE}
    // Не Windows: фон куском, символы - по ячейке (UTF-8)
    ACanvas.FillRect(SpanRect);
    ACanvas.Brush.Style := bsClear;
    for CellIdx := SpanStart to SpanEnd - 1 do
      if FCellText[CellIdx + 1] <> ' ' then
      begin
        CharText := UTF8Encode(WideString(FCellText[CellIdx + 1]));
        ACanvas.TextOut(AX + CellIdx * FCharW, AY, CharText);
      end;
    ACanvas.Brush.Style := bsSolid;
    {$ENDIF}
    SpanStart := SpanEnd;
  end;
end;

// ---------------------------------------------------------------------------
//  Клавиатура, мышь, фокус
// ---------------------------------------------------------------------------

{$IFDEF FPC}
procedure TEdView.WMGetDlgCode(var Message: TLMNoParams);
{$ELSE}
procedure TEdView.WMGetDlgCode(var Message: TWMGetDlgCode);
{$ENDIF}
begin
  // Стрелки и Tab - окну, а не переходу между элементами формы
  Message.Result := DLGC_WANTARROWS or DLGC_WANTCHARS or DLGC_WANTTAB;
end;

{$IFDEF FPC}
procedure TEdView.WMSetFocus(var Message: TLMSetFocus);
{$ELSE}
procedure TEdView.WMSetFocus(var Message: TWMSetFocus);
{$ENDIF}
begin
  inherited;
  MakeCaret;
end;

{$IFDEF FPC}
procedure TEdView.WMKillFocus(var Message: TLMKillFocus);
{$ELSE}
procedure TEdView.WMKillFocus(var Message: TWMKillFocus);
{$ENDIF}
begin
  KillCaret;
  inherited;
end;

procedure TEdView.KeyDown(var Key: Word; Shift: TShiftState);
var
  Ctrl: Boolean;
  NewRow: Integer;
begin
  inherited KeyDown(Key, Shift);
  if FBuffer = nil then
    Exit;
  Ctrl := ssCtrl in Shift;
  case Key of
    VK_LEFT:
      if FCaretCol > 0 then
        CaretTo(FCaretRow, FCaretCol - 1)
      else if FCaretRow > 0 then
        CaretTo(FCaretRow - 1, FBuffer.LineLength(FCaretRow - 1));
    VK_RIGHT:
      if FCaretCol < FBuffer.LineLength(FCaretRow) then
        CaretTo(FCaretRow, FCaretCol + 1)
      else if FCaretRow < FBuffer.Count - 1 then
        CaretTo(FCaretRow + 1, 0);
    VK_UP:
      if Ctrl then
        ScrollTo(FTopRow - 1, FLeftCol)
      else if FCaretRow > 0 then
        CaretTo(FCaretRow - 1, ColAtScreen(FCaretRow - 1, FPrefCol), True);
    VK_DOWN:
      if Ctrl then
        ScrollTo(FTopRow + 1, FLeftCol)
      else if FCaretRow < FBuffer.Count - 1 then
        CaretTo(FCaretRow + 1, ColAtScreen(FCaretRow + 1, FPrefCol), True);
    VK_PRIOR, VK_NEXT:
      begin
        // Страница: окно и каретка - на столько же строк
        if Key = VK_PRIOR then
          NewRow := -(VisibleRows - 1)
        else
          NewRow := VisibleRows - 1;
        ScrollTo(FTopRow + NewRow, FLeftCol);
        NewRow := FCaretRow + NewRow;
        if NewRow < 0 then
          NewRow := 0;
        if NewRow > FBuffer.Count - 1 then
          NewRow := FBuffer.Count - 1;
        CaretTo(NewRow, ColAtScreen(NewRow, FPrefCol), True);
      end;
    VK_HOME:
      if Ctrl then
        CaretTo(0, 0)
      else
        CaretTo(FCaretRow, 0);
    VK_END:
      if Ctrl then
        CaretTo(FBuffer.Count - 1, FBuffer.LineLength(FBuffer.Count - 1))
      else
        CaretTo(FCaretRow, FBuffer.LineLength(FCaretRow));
  else
    Exit;
  end;
  Key := 0;
end;

procedure TEdView.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  ClickRow, ClickCol: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if CanFocus and not Focused then
    SetFocus;
  if (Button = mbLeft) and (FBuffer <> nil) then
  begin
    PosAt(X, Y, ClickRow, ClickCol);
    CaretTo(ClickRow, ClickCol);
  end;
end;

function TEdView.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
var
  WheelLines: Integer;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if Result then
    Exit;
  // Строк на щелчок колеса - как в Windows (по умолчанию 3)
  WheelLines := 3;
  {$IFDEF MSWINDOWS}
  SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @WheelLines, 0);
  if (WheelLines <= 0) or (WheelLines > VisibleRows) then
    WheelLines := VisibleRows;
  {$ENDIF}
  ScrollTo(FTopRow - WheelDelta * WheelLines div 120, FLeftCol);
  Result := True;
end;

end.
