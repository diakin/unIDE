unit EdView;

// ---------------------------------------------------------------------------
//  Окно текста своего редактора unIDE (план портирования, шаги 0.7.2 -
//  0.7.3): показывает и правит TEdBuffer (EdBuffer.pas).
//
//  Шаг 0.7.2 - отрисовка, каретка, прокрутка, переходы. Шаг 0.7.3 - правка:
//  набор (вставка / замена - Ins), Enter с отступом строки, Backspace,
//  Delete, Ctrl+Backspace / Ctrl+Delete - слово, Tab / Shift+Tab (по
//  нескольким строкам - отступ блока); выделение Shift+клавишами, мышью
//  с протяжкой и прокруткой у края, двойной щелчок - слово, тройной -
//  строка, Shift+щелчок; буфер обмена Ctrl+C / X / V, Ctrl+Ins,
//  Shift+Ins, Shift+Del, Ctrl+A; откат Ctrl+Z, Alt+Backspace, повтор
//  Ctrl+Y, Ctrl+Shift+Z. Правки одного действия - одна группа отката, набор
//  подряд - одна правка (группы - в TEdBuffer).
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
  SysUtils, Classes, Graphics, Controls, Forms, StdCtrls, ExtCtrls,
  {$IFDEF FPC}Clipbrd,{$ENDIF}
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
    FOnChange: TNotifyEvent;
    FReadOnly: Boolean;
    FOverwrite: Boolean;       // Ins: набор заменяет символ под кареткой
    FAutoIndent: Boolean;      // Enter - с отступом текущей строки
    FMouseSelecting: Boolean;  // левая кнопка нажата в тексте
    FLastMouse: TPoint;
    FScrollTimer: TTimer;      // прокрутка у края при протяжке мышью
    FDblClickTick: Cardinal;   // двойной щелчок: время и место - для
    FDblClickPos: TPoint;      // тройного (Delphi 7 его не сообщает)
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
    procedure AfterEdit;
    procedure DeleteSelectionRaw;
    procedure DeleteRange(ARow1, ACol1, ARow2, ACol2: Integer);
    procedure WordLeftOf(var ARow, ACol: Integer);
    procedure WordRightOf(var ARow, ACol: Integer);
    procedure SelectWordAt(ARow, ACol: Integer);
    procedure SelectLine(ARow: Integer);
    procedure TypeChar(ACh: WideChar);
    procedure IndentBlock(AOutdent: Boolean);
    procedure ExtendToMouse;
    procedure ScrollTimerTick(Sender: TObject);
    procedure SetOverwrite(AValue: Boolean);
    function OwnsKey(AKey: Word; AShift: TShiftState): Boolean;
    {$IFNDEF FPC}
    procedure CNKeyDown(var Message: TWMKeyDown); message CN_KEYDOWN;
    {$ENDIF}
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
    {$IFDEF FPC}
    procedure UTF8KeyPress(var UTF8Key: TUTF8Char); override;
    {$ELSE}
    procedure KeyPress(var Key: Char); override;
    {$ENDIF}
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
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
    // Каретку в (ARow, ACol) как переход клавишей: ASelect - выделение от
    // прежнего места (или продолжить начатое), иначе выделение снимается.
    // Конец набора: следующий набор - новая правка для отката
    procedure MoveTo(ARow, ACol: Integer; ASelect: Boolean;
      AKeepPref: Boolean = False);
    // Выделение от (ARow, ACol) до каретки; снять - ClearSelection
    procedure SetSelection(ARow, ACol: Integer);
    procedure ClearSelection;
    function SelRange(var ARow1, ACol1, ARow2, ACol2: Integer): Boolean;
    function HasSelection: Boolean;
    // Выделенный текст, строки через #13#10
    function SelectedText: WideString;
    procedure SelectAll;
    // Правка (с откатом; в ReadOnly - ничего). AText - строки через любые
    // переводы строк; поверх выделения; ATyping - набор (сливается с
    // набором подряд в одну правку)
    procedure InsertText(const AText: WideString; ATyping: Boolean = False);
    procedure DeleteSelection;
    procedure Backspace;
    procedure DeleteChar;
    procedure NewLine;
    procedure DeleteWordLeft;
    procedure DeleteWordRight;
    procedure CutToClipboard;
    procedure CopyToClipboard;
    procedure PasteFromClipboard;
    procedure Undo;
    procedure Redo;
    function CanUndo: Boolean;
    function CanRedo: Boolean;
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
    // Текст буфера изменился (любой правкой, и не из этого окна)
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property Overwrite: Boolean read FOverwrite write SetOverwrite;
    property AutoIndent: Boolean read FAutoIndent write FAutoIndent;
    property Font;
    property TabStop;
    property Align;
    property PopupMenu;
  end;

// Буфер обмена: текст Unicode (Windows - CF_UNICODETEXT, иначе - LCL)
function EdClipboardText: WideString;
procedure EdSetClipboardText(const AText: WideString);

implementation

const
  EdCfUnicodeText = 13;        // CF_UNICODETEXT
  EdCfText = 1;                // CF_TEXT

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

function EdTicks: Cardinal;
begin
  {$IFDEF FPC}
  Result := Cardinal(GetTickCount64);
  {$ELSE}
  Result := GetTickCount;
  {$ENDIF}
end;

// Символ слова: буквы, цифры, '_' и всё не латинское выше пробелов
// (кириллица) - как у редактора F4 (FarEdit)
function EdIsWordChar(ACh: WideChar): Boolean;
begin
  Result := ((ACh >= 'a') and (ACh <= 'z')) or ((ACh >= 'A') and (ACh <= 'Z')) or
    ((ACh >= '0') and (ACh <= '9')) or (ACh = '_') or (Ord(ACh) >= 192);
end;

// Переводы строк любого вида (CRLF, CR, LF) - #10
function EdNormalizeBreaks(const AText: WideString): WideString;
var
  SrcIdx, DstIdx: Integer;
begin
  SetLength(Result, Length(AText));
  DstIdx := 0;
  SrcIdx := 1;
  while SrcIdx <= Length(AText) do
  begin
    Inc(DstIdx);
    if AText[SrcIdx] = #13 then
    begin
      Result[DstIdx] := #10;
      if (SrcIdx < Length(AText)) and (AText[SrcIdx + 1] = #10) then
        Inc(SrcIdx);
    end
    else
      Result[DstIdx] := AText[SrcIdx];
    Inc(SrcIdx);
  end;
  SetLength(Result, DstIdx);
end;

// #10 -> #13#10 (буфер обмена Windows)
function EdCrlf(const AText: WideString): WideString;
var
  SrcIdx, DstIdx, BreakCount: Integer;
begin
  BreakCount := 0;
  for SrcIdx := 1 to Length(AText) do
    if AText[SrcIdx] = #10 then
      Inc(BreakCount);
  SetLength(Result, Length(AText) + BreakCount);
  DstIdx := 0;
  for SrcIdx := 1 to Length(AText) do
  begin
    if AText[SrcIdx] = #10 then
    begin
      Inc(DstIdx);
      Result[DstIdx] := #13;
    end;
    Inc(DstIdx);
    Result[DstIdx] := AText[SrcIdx];
  end;
end;

{$IFDEF MSWINDOWS}
// Буфер обмена занят другой программой - несколько попыток
function EdOpenClipboard: Boolean;
var
  TryIdx: Integer;
begin
  Result := False;
  for TryIdx := 1 to 10 do
  begin
    if OpenClipboard(0) then
    begin
      Result := True;
      Exit;
    end;
    Sleep(10);
  end;
end;

function EdClipboardText: WideString;
var
  DataHandle: THandle;
  DataPtr: Pointer;
  AnsiText: AnsiString;
  WideLen: Integer;
begin
  Result := '';
  if not EdOpenClipboard then
    Exit;
  try
    DataHandle := GetClipboardData(EdCfUnicodeText);
    if DataHandle <> 0 then
    begin
      DataPtr := GlobalLock(DataHandle);
      if DataPtr <> nil then
      try
        Result := PWideChar(DataPtr);
      finally
        GlobalUnlock(DataHandle);
      end;
      Exit;
    end;
    DataHandle := GetClipboardData(EdCfText);
    if DataHandle = 0 then
      Exit;
    DataPtr := GlobalLock(DataHandle);
    if DataPtr = nil then
      Exit;
    try
      AnsiText := PAnsiChar(DataPtr);
    finally
      GlobalUnlock(DataHandle);
    end;
    if AnsiText <> '' then
    begin
      WideLen := MultiByteToWideChar(CP_ACP, 0, PAnsiChar(AnsiText),
        Length(AnsiText), nil, 0);
      SetLength(Result, WideLen);
      if WideLen > 0 then
        MultiByteToWideChar(CP_ACP, 0, PAnsiChar(AnsiText), Length(AnsiText),
          PWideChar(Result), WideLen);
    end;
  finally
    CloseClipboard;
  end;
end;

procedure EdSetClipboardText(const AText: WideString);
var
  DataHandle: THandle;
  DataPtr: Pointer;
  ByteCount: Integer;
begin
  if not EdOpenClipboard then
    Exit;
  try
    EmptyClipboard;
    ByteCount := (Length(AText) + 1) * SizeOf(WideChar);
    DataHandle := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, ByteCount);
    if DataHandle = 0 then
      Exit;
    DataPtr := GlobalLock(DataHandle);
    if DataPtr = nil then
    begin
      GlobalFree(DataHandle);
      Exit;
    end;
    try
      FillChar(DataPtr^, ByteCount, 0);
      if AText <> '' then
        Move(AText[1], DataPtr^, Length(AText) * SizeOf(WideChar));
    finally
      GlobalUnlock(DataHandle);
    end;
    // CF_TEXT для старых программ Windows делает сама из CF_UNICODETEXT
    if SetClipboardData(EdCfUnicodeText, DataHandle) = 0 then
      GlobalFree(DataHandle);
  finally
    CloseClipboard;
  end;
end;
{$ELSE}
function EdClipboardText: WideString;
begin
  Result := UTF8Decode(Clipboard.AsText);
end;

procedure EdSetClipboardText(const AText: WideString);
begin
  Clipboard.AsText := UTF8Encode(AText);
end;
{$ENDIF}

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
  FAutoIndent := True;
  FScrollTimer := TTimer.Create(Self);
  FScrollTimer.Enabled := False;
  FScrollTimer.Interval := 50;
  FScrollTimer.OnTimer := ScrollTimerTick;
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
  if Assigned(FOnChange) then
    FOnChange(Self);
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
var
  CaretWidth: Integer;
begin
  if FCaretMade or not HandleAllocated then
    Exit;
  UpdateMetrics;
  // Замена (Ins) - каретка во всю ячейку
  if FOverwrite then
    CaretWidth := FCharW
  else
    CaretWidth := 2;
  {$IFDEF FPC}
  LCLIntf.CreateCaret(Handle, 0, CaretWidth, FLineH);
  {$ELSE}
  CreateCaret(Handle, 0, CaretWidth, FLineH);
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

// Клавиши, которые окно разбирает само: в Delphi 7 они не уходят ярлыкам
// меню формы и главного окна (Ctrl+C, Ctrl+Z... главного меню unIDE
// работают с RichEdit) - см. CNKeyDown
function TEdView.OwnsKey(AKey: Word; AShift: TShiftState): Boolean;
var
  Ctrl, Alt: Boolean;
begin
  Ctrl := ssCtrl in AShift;
  Alt := ssAlt in AShift;
  case AKey of
    VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_HOME, VK_END,
    VK_INSERT, VK_DELETE:
      Result := not Alt;
    VK_BACK:
      Result := True;
    VK_RETURN:
      Result := not Alt and not Ctrl;
    VK_TAB:
      Result := not Alt and not Ctrl;
    Ord('A'), Ord('C'), Ord('V'), Ord('X'), Ord('Y'), Ord('Z'):
      Result := Ctrl and not Alt;
  else
    Result := False;
  end;
end;

{$IFNDEF FPC}
procedure TEdView.CNKeyDown(var Message: TWMKeyDown);
begin
  // Свои клавиши - мимо ярлыков меню: сообщение уходит в KeyDown
  if OwnsKey(Message.CharCode, KeyDataToShiftState(Message.KeyData)) then
  begin
    Message.Result := 0;
    Exit;
  end;
  inherited;
end;
{$ENDIF}

procedure TEdView.KeyDown(var Key: Word; Shift: TShiftState);
var
  Ctrl, Sel, Alt: Boolean;
  NewRow, NewCol, Row1, Col1, Row2, Col2, PageRows, LineIdx: Integer;
  Line: WideString;
begin
  inherited KeyDown(Key, Shift);
  if (FBuffer = nil) or (Key = 0) then
    Exit;
  Ctrl := ssCtrl in Shift;
  Sel := ssShift in Shift;
  Alt := ssAlt in Shift;
  NewRow := FCaretRow;
  NewCol := FCaretCol;
  // Буквы - только с Ctrl (без Alt: Ctrl+Alt - AltGr, это символ)
  if (Key >= Ord('A')) and (Key <= Ord('Z')) and (not Ctrl or Alt) then
    Exit;
  case Key of
    VK_LEFT:
      if not Sel and not Ctrl and SelRange(Row1, Col1, Row2, Col2) then
        // Без Shift при выделении - к его началу
        MoveTo(Row1, Col1, False)
      else
      begin
        if Ctrl then
          WordLeftOf(NewRow, NewCol)
        else if NewCol > 0 then
          Dec(NewCol)
        else if NewRow > 0 then
        begin
          Dec(NewRow);
          NewCol := FBuffer.LineLength(NewRow);
        end;
        MoveTo(NewRow, NewCol, Sel);
      end;
    VK_RIGHT:
      if not Sel and not Ctrl and SelRange(Row1, Col1, Row2, Col2) then
        MoveTo(Row2, Col2, False)
      else
      begin
        if Ctrl then
          WordRightOf(NewRow, NewCol)
        else if NewCol < FBuffer.LineLength(NewRow) then
          Inc(NewCol)
        else if NewRow < FBuffer.Count - 1 then
        begin
          Inc(NewRow);
          NewCol := 0;
        end;
        MoveTo(NewRow, NewCol, Sel);
      end;
    VK_UP:
      if Ctrl then
        ScrollTo(FTopRow - 1, FLeftCol)
      else if FCaretRow > 0 then
        MoveTo(FCaretRow - 1, ColAtScreen(FCaretRow - 1, FPrefCol), Sel, True)
      else
        MoveTo(FCaretRow, FCaretCol, Sel, True);
    VK_DOWN:
      if Ctrl then
        ScrollTo(FTopRow + 1, FLeftCol)
      else if FCaretRow < FBuffer.Count - 1 then
        MoveTo(FCaretRow + 1, ColAtScreen(FCaretRow + 1, FPrefCol), Sel, True)
      else
        MoveTo(FCaretRow, FCaretCol, Sel, True);
    VK_PRIOR, VK_NEXT:
      begin
        // Страница: окно и каретка - на столько же строк
        if Key = VK_PRIOR then
          PageRows := -(VisibleRows - 1)
        else
          PageRows := VisibleRows - 1;
        ScrollTo(FTopRow + PageRows, FLeftCol);
        NewRow := FCaretRow + PageRows;
        if NewRow < 0 then
          NewRow := 0;
        if NewRow > FBuffer.Count - 1 then
          NewRow := FBuffer.Count - 1;
        MoveTo(NewRow, ColAtScreen(NewRow, FPrefCol), Sel, True);
      end;
    VK_HOME:
      if Ctrl then
        MoveTo(0, 0, Sel)
      else
      begin
        // К первому непробельному символу строки; уже там - в начало
        Line := FBuffer[FCaretRow];
        LineIdx := 0;
        while (LineIdx < Length(Line)) and
              ((Line[LineIdx + 1] = ' ') or (Line[LineIdx + 1] = #9)) do
          Inc(LineIdx);
        if FCaretCol = LineIdx then
          LineIdx := 0;
        MoveTo(FCaretRow, LineIdx, Sel);
      end;
    VK_END:
      if Ctrl then
        MoveTo(FBuffer.Count - 1, FBuffer.LineLength(FBuffer.Count - 1), Sel)
      else
        MoveTo(FCaretRow, FBuffer.LineLength(FCaretRow), Sel);
    VK_INSERT:
      if Ctrl and not Sel then
        CopyToClipboard
      else if Sel and not Ctrl then
        PasteFromClipboard
      else if not Ctrl and not Sel then
        SetOverwrite(not FOverwrite);
    VK_DELETE:
      if Sel and not Ctrl then
        CutToClipboard
      else if Ctrl then
        DeleteWordRight
      else
        DeleteChar;
    VK_BACK:
      if Alt and Sel then
        Redo
      else if Alt then
        Undo
      else if Ctrl then
        DeleteWordLeft
      else
        Backspace;
    VK_RETURN:
      if Alt then
        Exit
      else
        NewLine;
    VK_TAB:
      if Ctrl or Alt then
        Exit
      else if Sel then
        IndentBlock(True)
      else if SelRange(Row1, Col1, Row2, Col2) and (Row2 > Row1) then
        IndentBlock(False)
      else
        InsertText(#9, True);
    Ord('A'):
      SelectAll;
    Ord('C'):
      CopyToClipboard;
    Ord('X'):
      CutToClipboard;
    Ord('V'):
      PasteFromClipboard;
    Ord('Z'):
      if Sel then
        Redo
      else
        Undo;
    Ord('Y'):
      Redo;
  else
    Exit;
  end;
  Key := 0;
end;

{$IFDEF FPC}
procedure TEdView.UTF8KeyPress(var UTF8Key: TUTF8Char);
var
  WideText: WideString;
  CharIdx: Integer;
begin
  inherited UTF8KeyPress(UTF8Key);
  if UTF8Key = '' then
    Exit;
  WideText := UTF8Decode(UTF8Key);
  // Управляющие (Enter, Tab, Backspace, Ctrl+буква) - в KeyDown
  if (WideText = '') or (Ord(WideText[1]) < 32) or (WideText[1] = #127) then
    Exit;
  for CharIdx := 1 to Length(WideText) do
    TypeChar(WideText[CharIdx]);
  UTF8Key := '';
end;
{$ELSE}
procedure TEdView.KeyPress(var Key: Char);
var
  WideCh: WideChar;
begin
  inherited KeyPress(Key);
  // Управляющие (Enter, Tab, Backspace, Ctrl+буква) - в KeyDown
  if (Key < ' ') or (Key = #127) then
    Exit;
  // Окно не Unicode: символ приходит в кодировке Windows
  WideCh := WideChar(Ord(Key));
  if Ord(Key) >= 128 then
    MultiByteToWideChar(CP_ACP, 0, @Key, 1, @WideCh, 1);
  TypeChar(WideCh);
  Key := #0;
end;
{$ENDIF}

// ---------------------------------------------------------------------------
//  Мышь
// ---------------------------------------------------------------------------

procedure TEdView.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  ClickRow, ClickCol: Integer;
  IsTriple: Boolean;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if CanFocus and not Focused then
    SetFocus;
  if (Button <> mbLeft) or (FBuffer = nil) then
    Exit;
  PosAt(X, Y, ClickRow, ClickCol);
  // Тройной щелчок: Lazarus сообщает сам, в Delphi 7 - щелчок вскоре после
  // двойного на том же месте
  {$IFDEF FPC}
  IsTriple := ssTriple in Shift;
  {$ELSE}
  IsTriple := (FDblClickTick <> 0) and
    (EdTicks - FDblClickTick <= GetDoubleClickTime) and
    (Abs(X - FDblClickPos.X) <= 4) and (Abs(Y - FDblClickPos.Y) <= 4);
  {$ENDIF}
  if IsTriple then
  begin
    FDblClickTick := 0;
    SelectLine(ClickRow);
    Exit;
  end;
  if ssDouble in Shift then
  begin
    FDblClickTick := EdTicks;
    FDblClickPos := Point(X, Y);
    SelectWordAt(ClickRow, ClickCol);
    Exit;
  end;
  FDblClickTick := 0;
  if ssShift in Shift then
    MoveTo(ClickRow, ClickCol, True)
  else
  begin
    MoveTo(ClickRow, ClickCol, False);
    // Начало протяжки: выделение от места щелчка (пока пустое)
    FSelActive := True;
    FSelRow := FCaretRow;
    FSelCol := FCaretCol;
  end;
  FMouseSelecting := True;
  FLastMouse := Point(X, Y);
end;

procedure TEdView.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  TextW, TextH: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if not FMouseSelecting then
    Exit;
  FLastMouse := Point(X, Y);
  ExtendToMouse;
  // За краем текста - прокрутка таймером, пока мышь там
  TextW := ClientWidth - FBarSize;
  TextH := ClientHeight - FBarSize;
  FScrollTimer.Enabled := (Y < 0) or (Y >= TextH) or (X < FGutterW) or
    (X >= TextW);
end;

procedure TEdView.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  FMouseSelecting := False;
  FScrollTimer.Enabled := False;
  if FSelActive and not HasSelection then
    FSelActive := False;
end;

procedure TEdView.ExtendToMouse;
var
  MouseRow, MouseCol: Integer;
begin
  PosAt(FLastMouse.X, FLastMouse.Y, MouseRow, MouseCol);
  MoveTo(MouseRow, MouseCol, True);
end;

procedure TEdView.ScrollTimerTick(Sender: TObject);
var
  TextW, TextH: Integer;
begin
  if not FMouseSelecting then
  begin
    FScrollTimer.Enabled := False;
    Exit;
  end;
  TextW := ClientWidth - FBarSize;
  TextH := ClientHeight - FBarSize;
  if FLastMouse.Y < 0 then
    ScrollTo(FTopRow - 1, FLeftCol)
  else if FLastMouse.Y >= TextH then
    ScrollTo(FTopRow + 1, FLeftCol);
  if FLastMouse.X < FGutterW then
    ScrollTo(FTopRow, FLeftCol - 1)
  else if FLastMouse.X >= TextW then
    ScrollTo(FTopRow, FLeftCol + 1);
  ExtendToMouse;
end;

// ---------------------------------------------------------------------------
//  Переходы и выделение
// ---------------------------------------------------------------------------

procedure TEdView.MoveTo(ARow, ACol: Integer; ASelect: Boolean;
  AKeepPref: Boolean);
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
  if ASelect then
  begin
    if not FSelActive then
    begin
      FSelActive := True;
      FSelRow := FCaretRow;
      FSelCol := FCaretCol;
    end;
  end
  else if FSelActive then
  begin
    FSelActive := False;
    Invalidate;
  end;
  // Движение каретки - конец набора: следующий набор - новая правка
  if (ARow <> FCaretRow) or (ACol <> FCaretCol) then
    FBuffer.BeginGroup;
  CaretTo(ARow, ACol, AKeepPref);
end;

function TEdView.HasSelection: Boolean;
begin
  Result := FSelActive and ((FSelRow <> FCaretRow) or (FSelCol <> FCaretCol));
end;

function TEdView.SelectedText: WideString;
var
  Row1, Col1, Row2, Col2: Integer;
begin
  Result := '';
  if (FBuffer <> nil) and SelRange(Row1, Col1, Row2, Col2) then
    Result := EdCrlf(FBuffer.TextRange(Row1, Col1, Row2, Col2));
end;

procedure TEdView.SelectAll;
begin
  if FBuffer = nil then
    Exit;
  FSelActive := True;
  FSelRow := 0;
  FSelCol := 0;
  FBuffer.BeginGroup;
  CaretTo(FBuffer.Count - 1, FBuffer.LineLength(FBuffer.Count - 1));
  Invalidate;
end;

procedure TEdView.WordLeftOf(var ARow, ACol: Integer);
var
  Line: WideString;
begin
  if ACol = 0 then
  begin
    if ARow > 0 then
    begin
      Dec(ARow);
      ACol := FBuffer.LineLength(ARow);
    end;
    Exit;
  end;
  Line := FBuffer[ARow];
  while (ACol > 0) and not EdIsWordChar(Line[ACol]) do
    Dec(ACol);
  while (ACol > 0) and EdIsWordChar(Line[ACol]) do
    Dec(ACol);
end;

procedure TEdView.WordRightOf(var ARow, ACol: Integer);
var
  Line: WideString;
begin
  Line := FBuffer[ARow];
  if ACol >= Length(Line) then
  begin
    if ARow < FBuffer.Count - 1 then
    begin
      Inc(ARow);
      ACol := 0;
    end;
    Exit;
  end;
  while (ACol < Length(Line)) and EdIsWordChar(Line[ACol + 1]) do
    Inc(ACol);
  while (ACol < Length(Line)) and not EdIsWordChar(Line[ACol + 1]) do
    Inc(ACol);
end;

// Двойной щелчок: слово под мышью (или слева от неё); не слово - символ
procedure TEdView.SelectWordAt(ARow, ACol: Integer);
var
  Line: WideString;
  WordStart, WordEnd: Integer;
begin
  Line := FBuffer[ARow];
  if (ACol >= Length(Line)) or not EdIsWordChar(Line[ACol + 1]) then
    if (ACol > 0) and (ACol <= Length(Line)) and EdIsWordChar(Line[ACol]) then
      Dec(ACol);
  WordStart := ACol;
  WordEnd := ACol;
  if (ACol < Length(Line)) and EdIsWordChar(Line[ACol + 1]) then
  begin
    while (WordStart > 0) and EdIsWordChar(Line[WordStart]) do
      Dec(WordStart);
    while (WordEnd < Length(Line)) and EdIsWordChar(Line[WordEnd + 1]) do
      Inc(WordEnd);
  end
  else if ACol < Length(Line) then
    WordEnd := ACol + 1;
  MoveTo(ARow, WordStart, False);
  MoveTo(ARow, WordEnd, True);
end;

// Тройной щелчок: строка целиком, с переводом строки
procedure TEdView.SelectLine(ARow: Integer);
begin
  MoveTo(ARow, 0, False);
  if ARow < FBuffer.Count - 1 then
    MoveTo(ARow + 1, 0, True)
  else
    MoveTo(ARow, FBuffer.LineLength(ARow), True);
end;

procedure TEdView.SetOverwrite(AValue: Boolean);
begin
  if AValue = FOverwrite then
    Exit;
  FOverwrite := AValue;
  if FCaretMade then
  begin
    KillCaret;
    MakeCaret;
  end;
  if Assigned(FOnCaretMove) then
    FOnCaretMove(Self);
end;

// ---------------------------------------------------------------------------
//  Правка. Каждое действие - своя группа отката (BeginGroup), кроме набора
//  подряд: он продолжает группу, пока каретку не двигали
// ---------------------------------------------------------------------------

// После правки: каретка видна, колонка для движения вверх-вниз - новая
procedure TEdView.AfterEdit;
begin
  FPrefCol := ScreenCol(FCaretRow, FCaretCol);
  EnsureCaretVisible;
  Invalidate;
  if Assigned(FOnCaretMove) then
    FOnCaretMove(Self);
end;

// Удаление с откатом (каретка до правки - в записи отката); каретка - в
// начало удалённого
procedure TEdView.DeleteRange(ARow1, ACol1, ARow2, ACol2: Integer);
begin
  FBuffer.DeleteText(ARow1, ACol1, ARow2, ACol2, FCaretRow, FCaretCol);
  FCaretRow := ARow1;
  FCaretCol := ACol1;
end;

procedure TEdView.DeleteSelectionRaw;
var
  Row1, Col1, Row2, Col2: Integer;
begin
  if SelRange(Row1, Col1, Row2, Col2) then
    DeleteRange(Row1, Col1, Row2, Col2);
  FSelActive := False;
end;

procedure TEdView.InsertText(const AText: WideString; ATyping: Boolean);
var
  Clean: WideString;
  EndRow, EndCol: Integer;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  Clean := EdNormalizeBreaks(AText);
  // Набор продолжает свою группу, если выделения нет и до него был набор
  if not (ATyping and not HasSelection and FBuffer.LastIsTyping) then
    FBuffer.BeginGroup;
  if HasSelection then
    DeleteSelectionRaw;
  FSelActive := False;
  if Clean <> '' then
  begin
    FBuffer.InsertText(FCaretRow, FCaretCol, Clean, ATyping, FCaretRow,
      FCaretCol, EndRow, EndCol);
    FCaretRow := EndRow;
    FCaretCol := EndCol;
  end;
  AfterEdit;
end;

// Символ с клавиатуры; в режиме замены - вместо символа под кареткой
procedure TEdView.TypeChar(ACh: WideChar);
var
  EndRow, EndCol: Integer;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  if FOverwrite and not HasSelection and
     (FCaretCol < FBuffer.LineLength(FCaretRow)) then
  begin
    if not FBuffer.LastIsTyping then
      FBuffer.BeginGroup;
    FBuffer.DeleteText(FCaretRow, FCaretCol, FCaretRow, FCaretCol + 1,
      FCaretRow, FCaretCol);
    FBuffer.InsertText(FCaretRow, FCaretCol, ACh, True, FCaretRow, FCaretCol,
      EndRow, EndCol);
    FCaretRow := EndRow;
    FCaretCol := EndCol;
    AfterEdit;
  end
  else
    InsertText(ACh, True);
end;

procedure TEdView.DeleteSelection;
begin
  if FReadOnly or (FBuffer = nil) or not HasSelection then
    Exit;
  FBuffer.BeginGroup;
  DeleteSelectionRaw;
  AfterEdit;
end;

procedure TEdView.Backspace;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  FBuffer.BeginGroup;
  if HasSelection then
    DeleteSelectionRaw
  else if FCaretCol > 0 then
    DeleteRange(FCaretRow, FCaretCol - 1, FCaretRow, FCaretCol)
  else if FCaretRow > 0 then
    DeleteRange(FCaretRow - 1, FBuffer.LineLength(FCaretRow - 1), FCaretRow, 0);
  FSelActive := False;
  AfterEdit;
end;

procedure TEdView.DeleteChar;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  FBuffer.BeginGroup;
  if HasSelection then
    DeleteSelectionRaw
  else if FCaretCol < FBuffer.LineLength(FCaretRow) then
    DeleteRange(FCaretRow, FCaretCol, FCaretRow, FCaretCol + 1)
  else if FCaretRow < FBuffer.Count - 1 then
    DeleteRange(FCaretRow, FCaretCol, FCaretRow + 1, 0);
  FSelActive := False;
  AfterEdit;
end;

// Enter: перевод строки и отступ, как у текущей строки (до каретки)
procedure TEdView.NewLine;
var
  Line, Indent: WideString;
  CharIdx: Integer;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  Indent := '';
  if FAutoIndent then
  begin
    Line := FBuffer[FCaretRow];
    CharIdx := 1;
    while (CharIdx <= Length(Line)) and (CharIdx <= FCaretCol) and
          ((Line[CharIdx] = ' ') or (Line[CharIdx] = #9)) do
      Inc(CharIdx);
    Indent := Copy(Line, 1, CharIdx - 1);
  end;
  InsertText(#10 + Indent);
end;

procedure TEdView.DeleteWordLeft;
var
  WordRow, WordCol: Integer;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  if HasSelection then
  begin
    DeleteSelection;
    Exit;
  end;
  WordRow := FCaretRow;
  WordCol := FCaretCol;
  WordLeftOf(WordRow, WordCol);
  if (WordRow = FCaretRow) and (WordCol = FCaretCol) then
    Exit;
  FBuffer.BeginGroup;
  DeleteRange(WordRow, WordCol, FCaretRow, FCaretCol);
  AfterEdit;
end;

procedure TEdView.DeleteWordRight;
var
  WordRow, WordCol: Integer;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  if HasSelection then
  begin
    DeleteSelection;
    Exit;
  end;
  WordRow := FCaretRow;
  WordCol := FCaretCol;
  WordRightOf(WordRow, WordCol);
  if (WordRow = FCaretRow) and (WordCol = FCaretCol) then
    Exit;
  FBuffer.BeginGroup;
  DeleteRange(FCaretRow, FCaretCol, WordRow, WordCol);
  AfterEdit;
end;

// Tab по нескольким строкам - табуляция в начало каждой; Shift+Tab -
// убрать одну табуляцию или до TabSize пробелов в начале. Строка, где
// выделение кончается в колонке 0, не трогается. Одна группа отката
procedure TEdView.IndentBlock(AOutdent: Boolean);
var
  Row1, Col1, Row2, Col2, LastRow, RowIdx, Removed, EndRow, EndCol: Integer;
  HadSel: Boolean;
  Line: WideString;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  HadSel := SelRange(Row1, Col1, Row2, Col2);
  if not HadSel then
  begin
    Row1 := FCaretRow;
    Row2 := FCaretRow;
    Col2 := FCaretCol;
  end;
  LastRow := Row2;
  if (Row2 > Row1) and (Col2 = 0) then
    LastRow := Row2 - 1;
  FBuffer.BeginGroup;
  for RowIdx := Row1 to LastRow do
    if AOutdent then
    begin
      Line := FBuffer[RowIdx];
      Removed := 0;
      if (Line <> '') and (Line[1] = #9) then
        Removed := 1
      else
        while (Removed < FTabSize) and (Removed < Length(Line)) and
              (Line[Removed + 1] = ' ') do
          Inc(Removed);
      if Removed > 0 then
      begin
        FBuffer.DeleteText(RowIdx, 0, RowIdx, Removed, FCaretRow, FCaretCol);
        if (RowIdx = FCaretRow) and not HadSel then
        begin
          Dec(FCaretCol, Removed);
          if FCaretCol < 0 then
            FCaretCol := 0;
        end;
      end;
    end
    else
      FBuffer.InsertText(RowIdx, 0, #9, False, FCaretRow, FCaretCol, EndRow,
        EndCol);
  FBuffer.BeginGroup;
  if HadSel then
  begin
    // Выделены строки блока целиком
    FSelActive := True;
    FSelRow := Row1;
    FSelCol := 0;
    FCaretRow := Row2;
    if LastRow < Row2 then
      FCaretCol := 0
    else
      FCaretCol := FBuffer.LineLength(Row2);
  end
  else if FCaretCol > FBuffer.LineLength(FCaretRow) then
    FCaretCol := FBuffer.LineLength(FCaretRow);
  AfterEdit;
end;

procedure TEdView.CutToClipboard;
begin
  if FReadOnly or not HasSelection then
    Exit;
  CopyToClipboard;
  DeleteSelection;
end;

procedure TEdView.CopyToClipboard;
begin
  if HasSelection then
    EdSetClipboardText(SelectedText);
end;

procedure TEdView.PasteFromClipboard;
var
  ClipText: WideString;
begin
  if FReadOnly then
    Exit;
  ClipText := EdClipboardText;
  if ClipText <> '' then
    InsertText(ClipText, False);
end;

procedure TEdView.Undo;
var
  NewRow, NewCol: Integer;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  NewRow := FCaretRow;
  NewCol := FCaretCol;
  if not FBuffer.Undo(NewRow, NewCol) then
    Exit;
  FSelActive := False;
  FCaretRow := NewRow;
  FCaretCol := NewCol;
  AfterEdit;
end;

procedure TEdView.Redo;
var
  NewRow, NewCol: Integer;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  NewRow := FCaretRow;
  NewCol := FCaretCol;
  if not FBuffer.Redo(NewRow, NewCol) then
    Exit;
  FSelActive := False;
  FCaretRow := NewRow;
  FCaretCol := NewCol;
  AfterEdit;
end;

function TEdView.CanUndo: Boolean;
begin
  Result := (FBuffer <> nil) and not FReadOnly and FBuffer.CanUndo;
end;

function TEdView.CanRedo: Boolean;
begin
  Result := (FBuffer <> nil) and not FReadOnly and FBuffer.CanRedo;
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
