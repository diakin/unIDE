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
//  Каретка, выделение, команды правки и разбор клавиш - в TEdEditor
//  (EdEditor.pas): то же ядро правки - у замены RichEdit в основном
//  редакторе (шаг 0.7.4). Окно добавляет отрисовку, прокрутку, мышь.
//
//  - Шрифт моноширинный: каждый символ - ячейка CharW x LineH. X символа =
//    (колонка с раскрытыми табуляциями) x CharW; обратно - делением. Замеры
//    ширины строк не нужны.
//  - Вывод - ExtTextOutW с шагом CharW на каждый символ: знак стоит в своей
//    ячейке и у жирного начертания. Табуляции раскрывает сам редактор.
//  - Цвета кусков строки даёт владелец (OnLineRuns): подсветка - не дело
//    окна. Нет обработчика - строка цветом текста.
//  - Слева - номера строк (поле Gutter), справа и снизу - полосы прокрутки
//    (TUiScrollBar по теме IDE).
//  - Буфер не принадлежит окну; изменения буфера окно получает подпиской
//    (AddListener) и перерисовывается.
//  - Строки экрана (SetDisplayMap, сравнение двух текстов как в WinMerge):
//    между строками буфера - пустые строки-заполнители, у которых нет
//    номера и текста. TopRow, ScrollTo, PosAt, каретка - в строках буфера;
//    TopDisp, ScrollToDisp - в строках экрана. Без карты строка экрана =
//    строка буфера. Правка, меняющая число строк, сдвигает карту сама.
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
  UiScroll,
  EdBuffer, EdEditor;

type
  // Свои полосы и в Lazarus: TScrollBar LCL - системная полоса, светлая
  // и в тёмной теме IDE
  TEdScrollBar = TUiScrollBar;

  // Кусок строки одного вида: символы Start .. Start + Len - 1 (с 0)
  TEdRun = record
    Start: Integer;
    Len: Integer;
    Fore: TColor;          // clNone - цвет текста окна
    Back: TColor;          // clNone - фон строки
    Style: TFontStyles;
  end;
  TEdRuns = array of TEdRun;
  // Именованный тип: в Delphi 7 два 'array of Integer' несовместимы при
  // присваивании
  TEdIntArray = array of Integer;

  // Куски строки ARow (текст - ALine). Куски - по возрастанию Start, без
  // наложений; не покрытое кусками - цветом текста. ARuns растёт по
  // надобности, ACount - сколько кусков заполнено
  TEdLineRunsEvent = procedure(Sender: TObject; ARow: Integer;
    const ALine: WideString; var ARuns: TEdRuns;
    var ACount: Integer) of object;

  // Щелчок по тексту окна в режиме «только щелчок» (OnTextClick): символ
  // ACol строки ARow (с 0)
  TEdTextClickEvent = procedure(Sender: TObject; ARow, ACol: Integer)
    of object;

  // Отметка строки ARow целиком (владелец окна): ABack - фон строки и всех
  // её символов, AFore - цвет всех символов; clNone - не менять. Выделение
  // рисуется поверх
  TEdRowStyleEvent = procedure(Sender: TObject; ARow: Integer;
    var ABack, AFore: TColor) of object;
  // Дорисовать строку ARow поверх текста (направляющие отступов и т.п.):
  // ATextX - X колонки 0 с учётом прокрутки вбок (левее GutterWidth - не
  // рисовать), AY - верх строки
  TEdRowPaintEvent = procedure(Sender: TObject; ACanvas: TCanvas;
    ARow, ATextX, AY: Integer) of object;

  TEdView = class(TCustomControl)
  private
    FBuffer: TEdBuffer;
    FTopRow: Integer;          // первая видимая строка экрана
    // Строки экрана (SetDisplayMap): FDispMap - строка буфера каждой строки
    // экрана (-1 - заполнитель), FRowDisp - обратно; пусто - один к одному
    FDispMap: TEdIntArray;
    FRowDisp: TEdIntArray;
    FFillerColor: TColor;
    FOnMarkRuns: TEdLineRunsEvent;
    FMarkRuns: TEdRuns;
    FLeftCol: Integer;         // первая видимая колонка экрана
    FEditor: TEdEditor;        // каретка, выделение, правка
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
    FOnTextClick: TEdTextClickEvent;
    FOnViewScroll: TNotifyEvent;
    FOnRowStyle: TEdRowStyleEvent;
    FOnRowPaint: TEdRowPaintEvent;
    FCaretOverwrite: Boolean;  // каретка создана для режима замены
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
    function GetTopRow: Integer;
    procedure RebuildRowDisp;
    procedure AdjustDispMap(AFirst, AOldCount, ANewCount: Integer);
    procedure BufferChanged(Sender: TObject; AFirst, AOldCount,
      ANewCount: Integer);
    procedure EditorMoved(Sender: TObject);
    procedure EditorScroll(Sender: TObject; ARows: Integer);
    function GetCaretRow: Integer;
    function AreaW: Integer;
    function AreaH: Integer;
    function GetCaretCol: Integer;
    function GetTabSize: Integer;
    procedure SetTabSize(AValue: Integer);
    function GetReadOnly: Boolean;
    procedure SetReadOnly(AValue: Boolean);
    function GetOverwrite: Boolean;
    procedure SetOverwrite(AValue: Boolean);
    function GetAutoIndent: Boolean;
    procedure SetAutoIndent(AValue: Boolean);
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
    procedure ExtendToMouse;
    procedure ScrollTimerTick(Sender: TObject);
    {$IFDEF FPC}
    procedure CNKeyDown(var Message: TLMKeyDown); message CN_KEYDOWN;
    {$ELSE}
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
      PosX, PosY: Integer); override;
    procedure MouseMove(Shift: TShiftState; PosX, PosY: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      PosX, PosY: Integer); override;
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
    // Первая видимая строка буфера ATopRow (с картой - её строка экрана)
    procedure ScrollTo(ATopRow, ALeftCol: Integer);
    // Первая видимая строка экрана ATopDisp
    procedure ScrollToDisp(ATopDisp, ALeftCol: Integer);
    procedure EnsureCaretVisible;
    // Строки экрана: AMap - строка буфера каждой строки экрана, -1 -
    // заполнитель. Строки буфера - все и по порядку, иначе карта не
    // ставится (ClearDisplayMap). Первая видимая строка буфера остаётся
    procedure SetDisplayMap(const AMap: array of Integer);
    procedure ClearDisplayMap;
    function HasDisplayMap: Boolean;
    // Число строк экрана; строка экрана строки буфера; строка буфера
    // строки экрана (-1 - заполнитель или за концом); ближайшая строка
    // буфера (заполнитель - следующая за ним, в конце - предыдущая)
    function DispCount: Integer;
    function DispOfRow(ARow: Integer): Integer;
    function RowOfDisp(ADisp: Integer): Integer;
    function RowNearDisp(ADisp: Integer): Integer;
    // Шрифт, цвета или разбор подсветки менялись - пересчитать и
    // перерисовать всё
    procedure RefreshAll;

    property Buffer: TEdBuffer read FBuffer write SetBuffer;
    // Первая видимая строка буфера и строка экрана
    property TopRow: Integer read GetTopRow;
    property TopDisp: Integer read FTopRow;
    // Фон строк-заполнителей (clNone - фон окна)
    property FillerColor: TColor read FFillerColor write FFillerColor;
    // Куски строки поверх подсветки (отличия внутри строки): фон Back и
    // цвет Fore (clNone - не менять) у символов куска; выделение - поверх
    property OnMarkRuns: TEdLineRunsEvent read FOnMarkRuns write FOnMarkRuns;
    property LeftCol: Integer read FLeftCol;
    property CaretRow: Integer read GetCaretRow;
    property CaretCol: Integer read GetCaretCol;
    property CharW: Integer read FCharW;
    property LineH: Integer read FLineH;
    property GutterWidth: Integer read FGutterW;
    property TabSize: Integer read GetTabSize write SetTabSize;
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
    // Задан - простой щелчок левой кнопкой по тексту не ставит каретку и не
    // начинает выделение, а сообщает место (вторая панель Unit1: щелчок -
    // править там). Shift+щелчок, двойной и тройной - как обычно
    property OnTextClick: TEdTextClickEvent read FOnTextClick
      write FOnTextClick;
    // Первая видимая строка сменилась (полоса, колесо, клавиши, ScrollTo,
    // каретка ушла за край) - сразу, не при отрисовке
    property OnViewScroll: TNotifyEvent read FOnViewScroll
      write FOnViewScroll;
    property OnRowStyle: TEdRowStyleEvent read FOnRowStyle write FOnRowStyle;
    property OnRowPaint: TEdRowPaintEvent read FOnRowPaint write FOnRowPaint;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
    property Overwrite: Boolean read GetOverwrite write SetOverwrite;
    property AutoIndent: Boolean read GetAutoIndent write SetAutoIndent;
    // Ядро правки: каретка, выделение, команды
    property Editor: TEdEditor read FEditor;
    property Font;
    property TabStop;
    property Align;
    property PopupMenu;
    // Щелчок и двойной щелчок (окна логов, EdLog): сначала окно ставит
    // каретку или выделяет слово, потом - событие
    property OnClick;
    property OnDblClick;
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

function EdTicks: Cardinal;
begin
  {$IFDEF FPC}
  Result := Cardinal(GetTickCount64);
  {$ELSE}
  Result := GetTickCount;
  {$ENDIF}
end;

// ---------------------------------------------------------------------------

constructor TEdView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Кадр - первым: смена шрифта ниже уже меряет ячейку по нему
  FBack := TBitmap.Create;
  FEditor := TEdEditor.Create;
  FEditor.OnCaretMove := EditorMoved;
  FEditor.OnScroll := EditorScroll;
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse, csClickEvents];
  TabStop := True;
  FShowGutter := True;
  FTextColor := clWindowText;
  FBackColor := clWindow;
  FGutterColor := clBtnFace;
  FGutterTextColor := clGrayText;
  FGutterCurColor := clNone;
  FGutterCurText := clWindowText;
  FCurLineColor := clNone;
  FFillerColor := clNone;
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
  FEditor.Free;
  inherited Destroy;
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

// Ширина и высота клиентской области. Окно без родителя (создано, Parent
// ещё не задан - TEdLogView, свойства из конструктора) - по Width / Height:
// ClientWidth у Delphi 7 спрашивает окно Windows, а создать его без
// родителя нельзя («Control '' has no parent window»)
function TEdView.AreaW: Integer;
begin
  if HandleAllocated or (Parent <> nil) then
    Result := ClientWidth
  else
    Result := Width;
end;

function TEdView.AreaH: Integer;
begin
  if HandleAllocated or (Parent <> nil) then
    Result := ClientHeight
  else
    Result := Height;
end;

function TEdView.VisibleRows: Integer;
begin
  UpdateMetrics;
  Result := (AreaH - FBarSize) div FLineH;
  if Result < 1 then
    Result := 1;
end;

function TEdView.VisibleCols: Integer;
begin
  UpdateMetrics;
  Result := (AreaW - FBarSize - FGutterW) div FCharW;
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
  ARow := RowNearDisp(FTopRow + AY div FLineH);
  if ARow >= FBuffer.Count then
    ARow := FBuffer.Count - 1;
  if ARow < 0 then
    ARow := 0;
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
  FVBar.SetBounds(AreaW - FBarSize, 0, FBarSize,
    AreaH - FBarSize);
  FHBar.SetBounds(0, AreaH - FBarSize, AreaW - FBarSize,
    FBarSize);
end;

// Диапазон и место полос (TUiScrollBar): Max - наибольшее место, ползунок -
// LargeChange
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
    RowMax := DispCount - VisibleRows;
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
    FVBar.Max := RowMax;
    FVBar.LargeChange := PageRows;
    FVBar.Position := FTopRow;
    FHBar.Max := ColMax;
    FHBar.LargeChange := PageCols;
    FHBar.Position := FLeftCol;
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
  ScrollToDisp(FVBar.Position, FLeftCol);
end;

procedure TEdView.HBarChange(Sender: TObject);
begin
  if FLockBars then
    Exit;
  ScrollToDisp(FTopRow, FHBar.Position);
end;

procedure TEdView.ScrollTo(ATopRow, ALeftCol: Integer);
begin
  ScrollToDisp(DispOfRow(ATopRow), ALeftCol);
end;

// OnViewScroll - и при прокрутке вбок: по нему вторая панель сравнения
// встаёт на то же место
procedure TEdView.ScrollToDisp(ATopDisp, ALeftCol: Integer);
var
  RowMax: Integer;
begin
  RowMax := 0;
  if FBuffer <> nil then
    RowMax := DispCount - VisibleRows;
  if ATopDisp > RowMax then
    ATopDisp := RowMax;
  if ATopDisp < 0 then
    ATopDisp := 0;
  if ALeftCol < 0 then
    ALeftCol := 0;
  if (ATopDisp = FTopRow) and (ALeftCol = FLeftCol) then
    Exit;
  FTopRow := ATopDisp;
  FLeftCol := ALeftCol;
  UpdateBars;
  PlaceCaret;
  Invalidate;
  if Assigned(FOnViewScroll) then
    FOnViewScroll(Self);
end;

// ---------------------------------------------------------------------------
//  Строки экрана (заполнители между строками буфера)
// ---------------------------------------------------------------------------

function TEdView.HasDisplayMap: Boolean;
begin
  Result := Length(FDispMap) > 0;
end;

function TEdView.DispCount: Integer;
begin
  if Length(FDispMap) > 0 then
    Result := Length(FDispMap)
  else if FBuffer <> nil then
    Result := FBuffer.Count
  else
    Result := 0;
end;

function TEdView.DispOfRow(ARow: Integer): Integer;
begin
  if Length(FDispMap) = 0 then
    Result := ARow
  else if ARow < 0 then
    Result := ARow
  else if ARow < Length(FRowDisp) then
    Result := FRowDisp[ARow]
  else
    Result := Length(FDispMap) + ARow - Length(FRowDisp);
end;

function TEdView.RowOfDisp(ADisp: Integer): Integer;
begin
  if Length(FDispMap) = 0 then
  begin
    Result := ADisp;
    if (FBuffer = nil) or (ADisp < 0) or (ADisp >= FBuffer.Count) then
      Result := -1;
  end
  else if (ADisp >= 0) and (ADisp < Length(FDispMap)) then
    Result := FDispMap[ADisp]
  else
    Result := -1;
end;

function TEdView.RowNearDisp(ADisp: Integer): Integer;
var
  DispIdx: Integer;
begin
  if Length(FDispMap) = 0 then
  begin
    Result := ADisp;
    Exit;
  end;
  if ADisp < 0 then
    ADisp := 0;
  if ADisp > High(FDispMap) then
    ADisp := High(FDispMap);
  for DispIdx := ADisp to High(FDispMap) do
    if FDispMap[DispIdx] >= 0 then
    begin
      Result := FDispMap[DispIdx];
      Exit;
    end;
  for DispIdx := ADisp downto 0 do
    if FDispMap[DispIdx] >= 0 then
    begin
      Result := FDispMap[DispIdx];
      Exit;
    end;
  Result := 0;
end;

function TEdView.GetTopRow: Integer;
begin
  Result := RowNearDisp(FTopRow);
end;

procedure TEdView.RebuildRowDisp;
var
  DispIdx, RowCount: Integer;
begin
  RowCount := 0;
  for DispIdx := 0 to High(FDispMap) do
    if FDispMap[DispIdx] >= 0 then
      Inc(RowCount);
  SetLength(FRowDisp, RowCount);
  for DispIdx := 0 to High(FDispMap) do
    if FDispMap[DispIdx] >= 0 then
      FRowDisp[FDispMap[DispIdx]] := DispIdx;
end;

procedure TEdView.SetDisplayMap(const AMap: array of Integer);
var
  OldTop, DispIdx, NextRow: Integer;
  MapOk: Boolean;
begin
  OldTop := GetTopRow;
  // Строки буфера - все, по порядку, каждая один раз
  NextRow := 0;
  MapOk := (FBuffer <> nil) and (Length(AMap) > 0);
  if MapOk then
    for DispIdx := 0 to High(AMap) do
      if AMap[DispIdx] >= 0 then
      begin
        if AMap[DispIdx] <> NextRow then
        begin
          MapOk := False;
          Break;
        end;
        Inc(NextRow);
      end;
  if MapOk and (NextRow <> FBuffer.Count) then
    MapOk := False;
  if not MapOk then
  begin
    ClearDisplayMap;
    Exit;
  end;
  SetLength(FDispMap, Length(AMap));
  for DispIdx := 0 to High(AMap) do
    FDispMap[DispIdx] := AMap[DispIdx];
  RebuildRowDisp;
  FTopRow := DispOfRow(OldTop);
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

procedure TEdView.ClearDisplayMap;
begin
  if Length(FDispMap) = 0 then
    Exit;
  FTopRow := GetTopRow;
  FDispMap := nil;
  FRowDisp := nil;
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

// Правка заменила строки буфера [AFirst, AFirst + AOldCount) на ANewCount
// строк: новые строки - на месте прежних, строки ниже - со сдвигом;
// заполнители остаются на своих местах
procedure TEdView.AdjustDispMap(AFirst, AOldCount, ANewCount: Integer);
var
  NewMap: TEdIntArray;
  OutCount, DispIdx, RowVal, Delta: Integer;
  Added: Boolean;

  procedure AddNewRows;
  var
    AddIdx: Integer;
  begin
    for AddIdx := 0 to ANewCount - 1 do
    begin
      NewMap[OutCount] := AFirst + AddIdx;
      Inc(OutCount);
    end;
    Added := True;
  end;

begin
  if (Length(FDispMap) = 0) or (AOldCount = ANewCount) then
    Exit;
  Delta := ANewCount - AOldCount;
  SetLength(NewMap, Length(FDispMap) + ANewCount);
  OutCount := 0;
  Added := False;
  for DispIdx := 0 to High(FDispMap) do
  begin
    RowVal := FDispMap[DispIdx];
    if (RowVal < 0) or (RowVal < AFirst) then
    begin
      NewMap[OutCount] := RowVal;
      Inc(OutCount);
      Continue;
    end;
    if not Added then
      AddNewRows;
    if RowVal < AFirst + AOldCount then
      Continue;
    NewMap[OutCount] := RowVal + Delta;
    Inc(OutCount);
  end;
  if not Added then
    AddNewRows;
  SetLength(NewMap, OutCount);
  FDispMap := NewMap;
  RebuildRowDisp;
  // Карта разошлась с буфером (так быть не должно) - без карты
  if (FBuffer = nil) or (Length(FRowDisp) <> FBuffer.Count) then
  begin
    FDispMap := nil;
    FRowDisp := nil;
  end;
end;

procedure TEdView.EnsureCaretVisible;
var
  NewTop, NewLeft, CaretScreen, Margin, CaretDisp: Integer;
begin
  NewTop := FTopRow;
  NewLeft := FLeftCol;
  CaretDisp := DispOfRow(FEditor.CaretRow);
  if CaretDisp < NewTop then
    NewTop := CaretDisp
  else if CaretDisp >= NewTop + VisibleRows then
    NewTop := CaretDisp - VisibleRows + 1;
  CaretScreen := ScreenCol(FEditor.CaretRow, FEditor.CaretCol);
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
    if Assigned(FOnViewScroll) then
      FOnViewScroll(Self);
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
  FCaretOverwrite := FEditor.Overwrite;
  if FEditor.Overwrite then
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
  CaretX := FGutterW + (ScreenCol(FEditor.CaretRow, FEditor.CaretCol) - FLeftCol) * FCharW;
  CaretY := (DispOfRow(FEditor.CaretRow) - FTopRow) * FLineH;
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
  TextW, TextH, RowIdx, RowY, RowCount, DispTotal, BufRow: Integer;
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
  DispTotal := DispCount;
  for RowIdx := 0 to RowCount - 1 do
  begin
    RowY := RowIdx * FLineH;
    if (FBuffer = nil) or (FTopRow + RowIdx >= DispTotal) then
      Break;
    BufRow := RowOfDisp(FTopRow + RowIdx);
    // Строка-заполнитель: без номера и текста, своим фоном
    if BufRow < 0 then
    begin
      if FFillerColor <> clNone then
      begin
        FBack.Canvas.Brush.Color := FFillerColor;
        FBack.Canvas.FillRect(Rect(FGutterW, RowY, TextW, RowY + FLineH));
      end;
      Continue;
    end;
    PaintRow(FBack.Canvas, BufRow, RowY, TextW);
    if FGutterW > 0 then
      PaintGutterRow(FBack.Canvas, BufRow, RowY);
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
  if ARow = FEditor.CaretRow then
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
    if ARow = FEditor.CaretRow then
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
  CellNo, Sel1Row, Sel1Col, Sel2Row, Sel2Col, MarkCount, MarkIdx: Integer;
  RowBack, CharFore, CharBack, MarkBack, MarkFore: TColor;
  CharStyle: Byte;
  HasSel, CharSel, PastEndSel: Boolean;
  CharCode: WideChar;
begin
  CellCount := (ATextW - FGutterW) div FCharW + 1;
  if CellCount <= 0 then
    Exit;
  RowBack := FBackColor;
  if (ARow = FEditor.CaretRow) and (FCurLineColor <> clNone) then
    RowBack := FCurLineColor;
  MarkBack := clNone;
  MarkFore := clNone;
  if Assigned(FOnRowStyle) then
    FOnRowStyle(Self, ARow, MarkBack, MarkFore);
  if MarkBack <> clNone then
    RowBack := MarkBack;
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
  MarkCount := 0;
  if Assigned(FOnMarkRuns) and (Line <> '') then
    FOnMarkRuns(Self, ARow, Line, FMarkRuns, MarkCount);
  MarkIdx := 0;
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
      CellWidth := FEditor.TabSize - ScreenPos mod FEditor.TabSize
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
    // Отмеченная строка: фон отметки у всех символов, цвет - если задан
    if MarkBack <> clNone then
      CharBack := MarkBack;
    if MarkFore <> clNone then
      CharFore := MarkFore;
    // Куски-отметки (отличия внутри строки)
    while (MarkIdx < MarkCount) and
          (FMarkRuns[MarkIdx].Start + FMarkRuns[MarkIdx].Len <= CharIdx) do
      Inc(MarkIdx);
    if (MarkIdx < MarkCount) and (FMarkRuns[MarkIdx].Start <= CharIdx) then
    begin
      if FMarkRuns[MarkIdx].Back <> clNone then
        CharBack := FMarkRuns[MarkIdx].Back;
      if FMarkRuns[MarkIdx].Fore <> clNone then
        CharFore := FMarkRuns[MarkIdx].Fore;
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
  if Assigned(FOnRowPaint) then
    FOnRowPaint(Self, ACanvas, ARow, FGutterW - FLeftCol * FCharW, AY);
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

{$IFDEF FPC}
// В LCL CN_KEYDOWN проверяет ярлыки меню (своего, формы, Application), и
// оттуда же (DoKeyDownBeforeInterface) вызывается KeyDown: Ctrl+A, Ctrl+C
// уходили пунктам главного меню. Свои клавиши - сразу в KeyDown, мимо
// ярлыков
procedure TEdView.CNKeyDown(var Message: TLMKeyDown);
var
  KeyCode: Word;
begin
  if FEditor.OwnsKey(Message.CharCode, KeyDataToShiftState(Message.KeyData)) then
  begin
    KeyCode := Message.CharCode;
    KeyDown(KeyCode, KeyDataToShiftState(Message.KeyData));
    Message.CharCode := KeyCode;
    Message.Result := 1;
    Exit;
  end;
  inherited;
end;
{$ELSE}
procedure TEdView.CNKeyDown(var Message: TWMKeyDown);
begin
  // Свои клавиши - мимо ярлыков меню: сообщение уходит в KeyDown
  if FEditor.OwnsKey(Message.CharCode, KeyDataToShiftState(Message.KeyData)) then
  begin
    Message.Result := 0;
    Exit;
  end;
  inherited;
end;
{$ENDIF}

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
    FEditor.TypeChar(WideText[CharIdx]);
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
  FEditor.TypeChar(WideCh);
  Key := #0;
end;
{$ENDIF}

// ---------------------------------------------------------------------------
//  Мышь
// ---------------------------------------------------------------------------

procedure TEdView.MouseDown(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
var
  ClickRow, ClickCol: Integer;
  IsTriple: Boolean;
begin
  inherited MouseDown(Button, Shift, PosX, PosY);
  if CanFocus and not Focused then
    SetFocus;
  if (Button <> mbLeft) or (FBuffer = nil) then
    Exit;
  PosAt(PosX, PosY, ClickRow, ClickCol);
  if Assigned(FOnTextClick) and (Shift * [ssShift, ssDouble] = []) then
  begin
    FDblClickTick := 0;
    FOnTextClick(Self, ClickRow, ClickCol);
    Exit;
  end;
  // Тройной щелчок: Lazarus сообщает сам, в Delphi 7 - щелчок вскоре после
  // двойного на том же месте
  {$IFDEF FPC}
  IsTriple := ssTriple in Shift;
  {$ELSE}
  IsTriple := (FDblClickTick <> 0) and
    (EdTicks - FDblClickTick <= GetDoubleClickTime) and
    (Abs(PosX - FDblClickPos.X) <= 4) and (Abs(PosY - FDblClickPos.Y) <= 4);
  {$ENDIF}
  if IsTriple then
  begin
    FDblClickTick := 0;
    FEditor.SelectLine(ClickRow);
    Exit;
  end;
  if ssDouble in Shift then
  begin
    FDblClickTick := EdTicks;
    FDblClickPos := Point(PosX, PosY);
    FEditor.SelectWordAt(ClickRow, ClickCol);
    Exit;
  end;
  FDblClickTick := 0;
  if ssShift in Shift then
    MoveTo(ClickRow, ClickCol, True)
  else
  begin
    MoveTo(ClickRow, ClickCol, False);
    // Начало протяжки: выделение от места щелчка (пока пустое)
    FEditor.SetSelection(FEditor.CaretRow, FEditor.CaretCol);
  end;
  FMouseSelecting := True;
  FLastMouse := Point(PosX, PosY);
end;

procedure TEdView.MouseMove(Shift: TShiftState; PosX, PosY: Integer);
var
  TextW, TextH: Integer;
begin
  inherited MouseMove(Shift, PosX, PosY);
  if not FMouseSelecting then
    Exit;
  FLastMouse := Point(PosX, PosY);
  ExtendToMouse;
  // За краем текста - прокрутка таймером, пока мышь там
  TextW := ClientWidth - FBarSize;
  TextH := ClientHeight - FBarSize;
  FScrollTimer.Enabled := (PosY < 0) or (PosY >= TextH) or (PosX < FGutterW) or
    (PosX >= TextW);
end;

procedure TEdView.MouseUp(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
begin
  inherited MouseUp(Button, Shift, PosX, PosY);
  if Button <> mbLeft then
    Exit;
  FMouseSelecting := False;
  FScrollTimer.Enabled := False;
  if FEditor.SelActive and not FEditor.HasSelection then
    FEditor.ClearSelection;
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
    ScrollToDisp(FTopRow - 1, FLeftCol)
  else if FLastMouse.Y >= TextH then
    ScrollToDisp(FTopRow + 1, FLeftCol);
  if FLastMouse.X < FGutterW then
    ScrollToDisp(FTopRow, FLeftCol - 1)
  else if FLastMouse.X >= TextW then
    ScrollToDisp(FTopRow, FLeftCol + 1);
  ExtendToMouse;
end;

// ---------------------------------------------------------------------------
//  Буфер и ядро правки (TEdEditor)
// ---------------------------------------------------------------------------

procedure TEdView.SetBuffer(AValue: TEdBuffer);
begin
  if AValue = FBuffer then
    Exit;
  if FBuffer <> nil then
    FBuffer.RemoveListener(BufferChanged);
  FBuffer := AValue;
  if FBuffer <> nil then
    FBuffer.AddListener(BufferChanged);
  FEditor.Buffer := FBuffer;
  FTopRow := 0;
  FLeftCol := 0;
  FDispMap := nil;
  FRowDisp := nil;
  FMaxColsValid := False;
  UpdateGutterWidth;
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

// Буфер изменился: каретка - в пределах текста, ширина - пересчитать
procedure TEdView.BufferChanged(Sender: TObject; AFirst, AOldCount,
  ANewCount: Integer);
var
  RowIdx, LastRow, Cols: Integer;
begin
  // Ширина самой длинной строки: при правке - только по изменённым
  // строкам (она может лишь вырасти; укороченная строка оставляет прежнюю
  // ширину до полного пересчёта). Полный проход по большому файлу на
  // каждое нажатие заметен; весь текст заменён - пересчитать заново
  if FMaxColsValid and (FBuffer <> nil) and
     not ((AFirst = 0) and (ANewCount >= FBuffer.Count)) then
  begin
    LastRow := AFirst + ANewCount - 1;
    if LastRow > FBuffer.Count - 1 then
      LastRow := FBuffer.Count - 1;
    for RowIdx := AFirst to LastRow do
    begin
      Cols := ScreenCol(RowIdx, MaxInt);
      if Cols > FMaxCols then
        FMaxCols := Cols;
    end;
  end
  else
    FMaxColsValid := False;
  AdjustDispMap(AFirst, AOldCount, ANewCount);
  FEditor.ClampToBuffer;
  UpdateGutterWidth;
  UpdateBars;
  PlaceCaret;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

// Каретка, выделение или текст изменились (ядро правки): каретка видна,
// окно перерисовано; режим замены - каретка другой ширины
procedure TEdView.EditorMoved(Sender: TObject);
begin
  if FCaretMade and (FCaretOverwrite <> FEditor.Overwrite) then
  begin
    KillCaret;
    MakeCaret;
  end;
  EnsureCaretVisible;
  Invalidate;
  if Assigned(FOnCaretMove) then
    FOnCaretMove(Self);
end;

procedure TEdView.EditorScroll(Sender: TObject; ARows: Integer);
begin
  ScrollToDisp(FTopRow + ARows, FLeftCol);
end;

procedure TEdView.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = 0) or (FBuffer = nil) then
    Exit;
  FEditor.PageRows := VisibleRows;
  if FEditor.KeyDown(Key, Shift) then
    Key := 0;
end;

function TEdView.GetCaretRow: Integer;
begin
  Result := FEditor.CaretRow;
end;

function TEdView.GetCaretCol: Integer;
begin
  Result := FEditor.CaretCol;
end;

function TEdView.GetTabSize: Integer;
begin
  Result := FEditor.TabSize;
end;

procedure TEdView.SetTabSize(AValue: Integer);
begin
  if AValue = FEditor.TabSize then
    Exit;
  FEditor.TabSize := AValue;
  FMaxColsValid := False;
  UpdateBars;
  PlaceCaret;
  Invalidate;
end;

function TEdView.GetReadOnly: Boolean;
begin
  Result := FEditor.ReadOnly;
end;

procedure TEdView.SetReadOnly(AValue: Boolean);
begin
  FEditor.ReadOnly := AValue;
end;

function TEdView.GetOverwrite: Boolean;
begin
  Result := FEditor.Overwrite;
end;

procedure TEdView.SetOverwrite(AValue: Boolean);
begin
  FEditor.Overwrite := AValue;
end;

function TEdView.GetAutoIndent: Boolean;
begin
  Result := FEditor.AutoIndent;
end;

procedure TEdView.SetAutoIndent(AValue: Boolean);
begin
  FEditor.AutoIndent := AValue;
end;

function TEdView.ScreenCol(ARow, ACol: Integer): Integer;
begin
  Result := FEditor.ScreenCol(ARow, ACol);
end;

function TEdView.ColAtScreen(ARow, AScreenCol: Integer): Integer;
begin
  Result := FEditor.ColAtScreen(ARow, AScreenCol);
end;

procedure TEdView.CaretTo(ARow, ACol: Integer; AKeepPref: Boolean);
begin
  FEditor.CaretTo(ARow, ACol, AKeepPref);
end;

procedure TEdView.MoveTo(ARow, ACol: Integer; ASelect: Boolean;
  AKeepPref: Boolean);
begin
  FEditor.MoveTo(ARow, ACol, ASelect, AKeepPref);
end;

procedure TEdView.SetSelection(ARow, ACol: Integer);
begin
  FEditor.SetSelection(ARow, ACol);
end;

procedure TEdView.ClearSelection;
begin
  FEditor.ClearSelection;
end;

function TEdView.SelRange(var ARow1, ACol1, ARow2, ACol2: Integer): Boolean;
begin
  Result := FEditor.SelRange(ARow1, ACol1, ARow2, ACol2);
end;

function TEdView.HasSelection: Boolean;
begin
  Result := FEditor.HasSelection;
end;

function TEdView.SelectedText: WideString;
begin
  Result := FEditor.SelectedText;
end;

procedure TEdView.SelectAll;
begin
  FEditor.SelectAll;
end;

procedure TEdView.InsertText(const AText: WideString; ATyping: Boolean);
begin
  FEditor.InsertText(AText, ATyping);
end;

procedure TEdView.DeleteSelection;
begin
  FEditor.DeleteSelection;
end;

procedure TEdView.Backspace;
begin
  FEditor.Backspace;
end;

procedure TEdView.DeleteChar;
begin
  FEditor.DeleteChar;
end;

procedure TEdView.NewLine;
begin
  FEditor.NewLine;
end;

procedure TEdView.DeleteWordLeft;
begin
  FEditor.DeleteWordLeft;
end;

procedure TEdView.DeleteWordRight;
begin
  FEditor.DeleteWordRight;
end;

procedure TEdView.CutToClipboard;
begin
  FEditor.CutToClipboard;
end;

procedure TEdView.CopyToClipboard;
begin
  FEditor.CopyToClipboard;
end;

procedure TEdView.PasteFromClipboard;
begin
  FEditor.PasteFromClipboard;
end;

procedure TEdView.Undo;
begin
  FEditor.Undo;
end;

procedure TEdView.Redo;
begin
  FEditor.Redo;
end;

function TEdView.CanUndo: Boolean;
begin
  Result := FEditor.CanUndo;
end;

function TEdView.CanRedo: Boolean;
begin
  Result := FEditor.CanRedo;
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
  ScrollToDisp(FTopRow - WheelDelta * WheelLines div 120, FLeftCol);
  Result := True;
end;

end.
