unit EdEditor;

// ---------------------------------------------------------------------------
//  Правка текста своего редактора unIDE без окна: каретка, выделение,
//  команды правки и разбор клавиш над TEdBuffer (EdBuffer.pas). Общее для
//  окна TEdView (EdView.pas) и для замены RichEdit в основном редакторе
//  unIDE (план портирования, шаг 0.7.4) - поведение одно.
//
//  - Позиция - строка и символ в строке (с 0). Выделение - от места
//    (SelRow, SelCol) до каретки; пустое выделение - нет выделения.
//  - Каждое действие правки - своя группа отката TEdBuffer; набор подряд
//    продолжает свою группу, пока каретку не двигали (MoveTo начинает
//    новую).
//  - Окна нет, поэтому то, что зависит от экрана, - у владельца: сколько
//    строк в странице (PageRows), прокрутка без каретки (OnScroll),
//    каретку показать и перерисовать (OnCaretMove - после любого движения
//    каретки, выделения или правки).
//
//  Без VCL / LCL; буфер обмена - EdClip.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  SysUtils, Classes, EdBuffer, EdClip;

const
  // Коды клавиш - как в Windows и LCL (VK_*)
  EdKeyBack = 8;
  EdKeyTab = 9;
  EdKeyReturn = 13;
  EdKeyPrior = 33;
  EdKeyNext = 34;
  EdKeyEnd = 35;
  EdKeyHome = 36;
  EdKeyLeft = 37;
  EdKeyUp = 38;
  EdKeyRight = 39;
  EdKeyDown = 40;
  EdKeyInsert = 45;
  EdKeyDelete = 46;

type
  // Прокрутка окна на ARows строк без движения каретки
  TEdScrollEvent = procedure(Sender: TObject; ARows: Integer) of object;

  TEdEditor = class
  private
    FBuffer: TEdBuffer;
    FCaretRow: Integer;
    FCaretCol: Integer;
    FPrefCol: Integer;         // колонка экрана для движения вверх-вниз
    FSelActive: Boolean;
    FSelRow: Integer;
    FSelCol: Integer;
    FTabSize: Integer;
    FReadOnly: Boolean;
    FOverwrite: Boolean;
    FAutoIndent: Boolean;
    FSmartHome: Boolean;
    FTypingUndo: Boolean;
    FTypingRun: Boolean;       // идёт набор: каретку с тех пор не двигали
    FPageRows: Integer;
    FOnCaretMove: TNotifyEvent;
    FOnScroll: TEdScrollEvent;
    procedure Moved;
    procedure AfterEdit;
    procedure DeleteSelectionRaw;
    procedure DeleteRange(ARow1, ACol1, ARow2, ACol2: Integer);
    procedure SetBuffer(AValue: TEdBuffer);
    procedure SetOverwrite(AValue: Boolean);
    procedure SetTabSize(AValue: Integer);
    procedure BeginTypingStep;
  public
    constructor Create;
    // Каретка и выделение - в пределах текста (после правки буфера не
    // отсюда)
    procedure ClampToBuffer;
    // Конец набора: следующая правка - новая группа отката
    procedure StopTyping;

    // --- Позиции ---
    // Колонка экрана символа ACol строки ARow (табуляции раскрыты) и
    // обратно - символ под колонкой экрана (табуляция: правее середины -
    // после неё)
    function ScreenCol(ARow, ACol: Integer): Integer;
    function ColAtScreen(ARow, AScreenCol: Integer): Integer;
    procedure WordLeftOf(var ARow, ACol: Integer);
    procedure WordRightOf(var ARow, ACol: Integer);

    // --- Каретка и выделение ---
    // Каретку в (ARow, ACol), выделение не трогается; AKeepPref - не менять
    // колонку для движения вверх-вниз
    procedure CaretTo(ARow, ACol: Integer; AKeepPref: Boolean = False);
    // Как переход клавишей: ASelect - выделение от прежнего места (или
    // продолжить начатое), иначе выделение снимается. Конец набора
    procedure MoveTo(ARow, ACol: Integer; ASelect: Boolean;
      AKeepPref: Boolean = False);
    // Выделение от (ARow, ACol) до каретки
    procedure SetSelection(ARow, ACol: Integer);
    procedure ClearSelection;
    function SelRange(var ARow1, ACol1, ARow2, ACol2: Integer): Boolean;
    function HasSelection: Boolean;
    // Выделенный текст, строки через #13#10
    function SelectedText: WideString;
    procedure SelectAll;
    // Двойной щелчок: слово (не слово - символ); тройной: строка
    procedure SelectWordAt(ARow, ACol: Integer);
    procedure SelectLine(ARow: Integer);

    // --- Правка (с откатом; в ReadOnly - ничего) ---
    // AText - строки через любые переводы строк; поверх выделения; ATyping
    // - набор (сливается с набором подряд в одну правку)
    procedure InsertText(const AText: WideString; ATyping: Boolean = False);
    // Символ с клавиатуры (в режиме замены - вместо символа под кареткой)
    procedure TypeChar(ACh: WideChar);
    procedure DeleteSelection;
    procedure Backspace;
    procedure DeleteChar;
    procedure NewLine;
    procedure DeleteWordLeft;
    procedure DeleteWordRight;
    // Tab / Shift+Tab по строкам выделения (нет выделения - строка каретки)
    procedure IndentBlock(AOutdent: Boolean);
    procedure CutToClipboard;
    procedure CopyToClipboard;
    procedure PasteFromClipboard;
    procedure Undo;
    procedure Redo;
    function CanUndo: Boolean;
    function CanRedo: Boolean;

    // --- Клавиши ---
    // Клавиша, которую разбирает KeyDown (окну - не отдавать её ярлыкам
    // меню)
    function OwnsKey(AKey: Word; AShift: TShiftState): Boolean;
    // Нажатие AKey: True - разобрано
    function KeyDown(AKey: Word; AShift: TShiftState): Boolean;

    property Buffer: TEdBuffer read FBuffer write SetBuffer;
    property CaretRow: Integer read FCaretRow;
    property CaretCol: Integer read FCaretCol;
    property SelActive: Boolean read FSelActive;
    property SelRow: Integer read FSelRow;
    property SelCol: Integer read FSelCol;
    property TabSize: Integer read FTabSize write SetTabSize;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property Overwrite: Boolean read FOverwrite write SetOverwrite;
    property AutoIndent: Boolean read FAutoIndent write FAutoIndent;
    // Home - к первому непробельному символу (повтор - в начало строки);
    // False - сразу в начало, как в RichEdit
    property SmartHome: Boolean read FSmartHome write FSmartHome;
    // Откат как у RichEdit: Backspace, Delete и Enter посреди набора - в
    // той же правке, что и набор (False - каждая такая клавиша - своя)
    property TypingUndo: Boolean read FTypingUndo write FTypingUndo;
    // Строк в странице окна (PgUp / PgDn)
    property PageRows: Integer read FPageRows write FPageRows;
    property OnCaretMove: TNotifyEvent read FOnCaretMove write FOnCaretMove;
    property OnScroll: TEdScrollEvent read FOnScroll write FOnScroll;
  end;

// Символ слова: буквы, цифры, '_' и всё не латинское от #192 (кириллица)
function EdIsWordChar(ACh: WideChar): Boolean;
// Переводы строк любого вида - #10
function EdNormalizeBreaks(const AText: WideString): WideString;
// #10 -> #13#10
function EdCrlf(const AText: WideString): WideString;

implementation

function EdIsWordChar(ACh: WideChar): Boolean;
begin
  Result := ((ACh >= 'a') and (ACh <= 'z')) or ((ACh >= 'A') and (ACh <= 'Z')) or
    ((ACh >= '0') and (ACh <= '9')) or (ACh = '_') or (Ord(ACh) >= 192);
end;

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

// ---------------------------------------------------------------------------

constructor TEdEditor.Create;
begin
  inherited Create;
  FTabSize := 8;
  FAutoIndent := True;
  FSmartHome := True;
  FPageRows := 20;
end;

procedure TEdEditor.SetBuffer(AValue: TEdBuffer);
begin
  FBuffer := AValue;
  FTypingRun := False;
  FCaretRow := 0;
  FCaretCol := 0;
  FPrefCol := 0;
  FSelActive := False;
  FSelRow := 0;
  FSelCol := 0;
end;

procedure TEdEditor.SetTabSize(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;
  FTabSize := AValue;
end;

procedure TEdEditor.SetOverwrite(AValue: Boolean);
begin
  if AValue = FOverwrite then
    Exit;
  FOverwrite := AValue;
  Moved;
end;

procedure TEdEditor.ClampToBuffer;
begin
  if FBuffer = nil then
    Exit;
  if FCaretRow >= FBuffer.Count then
    FCaretRow := FBuffer.Count - 1;
  if FCaretRow < 0 then
    FCaretRow := 0;
  if FCaretCol > FBuffer.LineLength(FCaretRow) then
    FCaretCol := FBuffer.LineLength(FCaretRow);
  if FCaretCol < 0 then
    FCaretCol := 0;
  if FSelRow >= FBuffer.Count then
  begin
    FSelRow := FBuffer.Count - 1;
    FSelCol := FBuffer.LineLength(FSelRow);
  end;
  if FSelCol > FBuffer.LineLength(FSelRow) then
    FSelCol := FBuffer.LineLength(FSelRow);
end;

procedure TEdEditor.StopTyping;
begin
  FTypingRun := False;
  if FBuffer <> nil then
    FBuffer.BeginGroup;
end;

// Перед Backspace, Delete, Enter: посреди набора (TypingUndo) - в той же
// группе отката, иначе - новая
procedure TEdEditor.BeginTypingStep;
begin
  if not (FTypingUndo and FTypingRun and not HasSelection) then
    FBuffer.BeginGroup;
end;

procedure TEdEditor.Moved;
begin
  if Assigned(FOnCaretMove) then
    FOnCaretMove(Self);
end;

// ---------------------------------------------------------------------------
//  Позиции
// ---------------------------------------------------------------------------

function TEdEditor.ScreenCol(ARow, ACol: Integer): Integer;
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

function TEdEditor.ColAtScreen(ARow, AScreenCol: Integer): Integer;
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

procedure TEdEditor.WordLeftOf(var ARow, ACol: Integer);
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

procedure TEdEditor.WordRightOf(var ARow, ACol: Integer);
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

// ---------------------------------------------------------------------------
//  Каретка и выделение
// ---------------------------------------------------------------------------

procedure TEdEditor.CaretTo(ARow, ACol: Integer; AKeepPref: Boolean);
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
  FCaretRow := ARow;
  FCaretCol := ACol;
  if not AKeepPref then
    FPrefCol := ScreenCol(FCaretRow, FCaretCol);
  Moved;
end;

procedure TEdEditor.MoveTo(ARow, ACol: Integer; ASelect: Boolean;
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
  else
    FSelActive := False;
  // Движение каретки - конец набора: следующий набор - новая правка
  if (ARow <> FCaretRow) or (ACol <> FCaretCol) then
  begin
    FTypingRun := False;
    FBuffer.BeginGroup;
  end;
  CaretTo(ARow, ACol, AKeepPref);
end;

procedure TEdEditor.SetSelection(ARow, ACol: Integer);
begin
  FSelActive := True;
  FSelRow := ARow;
  FSelCol := ACol;
  Moved;
end;

procedure TEdEditor.ClearSelection;
begin
  if not FSelActive then
    Exit;
  FSelActive := False;
  Moved;
end;

function TEdEditor.SelRange(var ARow1, ACol1, ARow2, ACol2: Integer): Boolean;
begin
  Result := HasSelection;
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

function TEdEditor.HasSelection: Boolean;
begin
  Result := FSelActive and ((FSelRow <> FCaretRow) or (FSelCol <> FCaretCol));
end;

function TEdEditor.SelectedText: WideString;
var
  Row1, Col1, Row2, Col2: Integer;
begin
  Result := '';
  if (FBuffer <> nil) and SelRange(Row1, Col1, Row2, Col2) then
    Result := EdCrlf(FBuffer.TextRange(Row1, Col1, Row2, Col2));
end;

procedure TEdEditor.SelectAll;
begin
  if FBuffer = nil then
    Exit;
  FSelActive := True;
  FSelRow := 0;
  FSelCol := 0;
  FBuffer.BeginGroup;
  CaretTo(FBuffer.Count - 1, FBuffer.LineLength(FBuffer.Count - 1));
end;

procedure TEdEditor.SelectWordAt(ARow, ACol: Integer);
var
  Line: WideString;
  WordStart, WordEnd: Integer;
begin
  if FBuffer = nil then
    Exit;
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

procedure TEdEditor.SelectLine(ARow: Integer);
begin
  if FBuffer = nil then
    Exit;
  MoveTo(ARow, 0, False);
  if ARow < FBuffer.Count - 1 then
    MoveTo(ARow + 1, 0, True)
  else
    MoveTo(ARow, FBuffer.LineLength(ARow), True);
end;

// ---------------------------------------------------------------------------
//  Правка. Каждое действие - своя группа отката (BeginGroup), кроме набора
//  подряд: он продолжает группу, пока каретку не двигали
// ---------------------------------------------------------------------------

procedure TEdEditor.AfterEdit;
begin
  FPrefCol := ScreenCol(FCaretRow, FCaretCol);
  Moved;
end;

// Удаление с откатом (каретка до правки - в записи отката); каретка - в
// начало удалённого
procedure TEdEditor.DeleteRange(ARow1, ACol1, ARow2, ACol2: Integer);
begin
  FBuffer.DeleteText(ARow1, ACol1, ARow2, ACol2, FCaretRow, FCaretCol);
  FCaretRow := ARow1;
  FCaretCol := ACol1;
end;

procedure TEdEditor.DeleteSelectionRaw;
var
  Row1, Col1, Row2, Col2: Integer;
begin
  if SelRange(Row1, Col1, Row2, Col2) then
    DeleteRange(Row1, Col1, Row2, Col2);
  FSelActive := False;
end;

procedure TEdEditor.InsertText(const AText: WideString; ATyping: Boolean);
var
  Clean: WideString;
  EndRow, EndCol: Integer;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  Clean := EdNormalizeBreaks(AText);
  // Набор продолжает свою группу, если выделения нет и до него был набор
  if not (ATyping and not HasSelection and
          (FBuffer.LastIsTyping or (FTypingUndo and FTypingRun))) then
    FBuffer.BeginGroup;
  FTypingRun := ATyping;
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

procedure TEdEditor.TypeChar(ACh: WideChar);
var
  EndRow, EndCol: Integer;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  if FOverwrite and not HasSelection and
     (FCaretCol < FBuffer.LineLength(FCaretRow)) then
  begin
    if not (FBuffer.LastIsTyping or (FTypingUndo and FTypingRun)) then
      FBuffer.BeginGroup;
    FTypingRun := True;
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

procedure TEdEditor.DeleteSelection;
begin
  if FReadOnly or (FBuffer = nil) or not HasSelection then
    Exit;
  FBuffer.BeginGroup;
  DeleteSelectionRaw;
  AfterEdit;
end;

procedure TEdEditor.Backspace;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  BeginTypingStep;
  FTypingRun := True;
  if HasSelection then
    DeleteSelectionRaw
  else if FCaretCol > 0 then
    DeleteRange(FCaretRow, FCaretCol - 1, FCaretRow, FCaretCol)
  else if FCaretRow > 0 then
    DeleteRange(FCaretRow - 1, FBuffer.LineLength(FCaretRow - 1), FCaretRow, 0);
  FSelActive := False;
  AfterEdit;
end;

procedure TEdEditor.DeleteChar;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  BeginTypingStep;
  FTypingRun := True;
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
procedure TEdEditor.NewLine;
var
  Line, Indent: WideString;
  CharIdx: Integer;
  WasRun: Boolean;
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
  if FTypingUndo then
  begin
    // Как у RichEdit: перевод строки посреди набора - в той же правке
    BeginTypingStep;
    WasRun := FTypingRun;
    FTypingRun := True;
    InsertText(#10 + Indent, True);
    // Следующий символ - новая запись отката, но та же группа
    if not WasRun then
      FTypingRun := True;
  end
  else
    InsertText(#10 + Indent);
end;

procedure TEdEditor.DeleteWordLeft;
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

procedure TEdEditor.DeleteWordRight;
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
procedure TEdEditor.IndentBlock(AOutdent: Boolean);
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

procedure TEdEditor.CutToClipboard;
begin
  if FReadOnly or not HasSelection then
    Exit;
  CopyToClipboard;
  DeleteSelection;
end;

procedure TEdEditor.CopyToClipboard;
begin
  if HasSelection then
    EdSetClipboardText(SelectedText);
end;

procedure TEdEditor.PasteFromClipboard;
var
  ClipText: WideString;
begin
  if FReadOnly then
    Exit;
  ClipText := EdClipboardText;
  if ClipText <> '' then
    InsertText(ClipText, False);
end;

procedure TEdEditor.Undo;
var
  NewRow, NewCol: Integer;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  NewRow := FCaretRow;
  NewCol := FCaretCol;
  FTypingRun := False;
  if not FBuffer.Undo(NewRow, NewCol) then
    Exit;
  FSelActive := False;
  FCaretRow := NewRow;
  FCaretCol := NewCol;
  AfterEdit;
end;

procedure TEdEditor.Redo;
var
  NewRow, NewCol: Integer;
begin
  if FReadOnly or (FBuffer = nil) then
    Exit;
  NewRow := FCaretRow;
  NewCol := FCaretCol;
  FTypingRun := False;
  if not FBuffer.Redo(NewRow, NewCol) then
    Exit;
  FSelActive := False;
  FCaretRow := NewRow;
  FCaretCol := NewCol;
  AfterEdit;
end;

function TEdEditor.CanUndo: Boolean;
begin
  Result := (FBuffer <> nil) and not FReadOnly and FBuffer.CanUndo;
end;

function TEdEditor.CanRedo: Boolean;
begin
  Result := (FBuffer <> nil) and not FReadOnly and FBuffer.CanRedo;
end;

// ---------------------------------------------------------------------------
//  Клавиши
// ---------------------------------------------------------------------------

function TEdEditor.OwnsKey(AKey: Word; AShift: TShiftState): Boolean;
var
  Ctrl, Alt: Boolean;
begin
  Ctrl := ssCtrl in AShift;
  Alt := ssAlt in AShift;
  case AKey of
    EdKeyLeft, EdKeyRight, EdKeyUp, EdKeyDown, EdKeyPrior, EdKeyNext,
    EdKeyHome, EdKeyEnd, EdKeyInsert, EdKeyDelete:
      Result := not Alt;
    EdKeyBack:
      Result := True;
    EdKeyReturn:
      Result := not Alt and not Ctrl;
    EdKeyTab:
      Result := not Alt and not Ctrl;
    Ord('A'), Ord('C'), Ord('V'), Ord('X'), Ord('Y'), Ord('Z'):
      Result := Ctrl and not Alt;
  else
    Result := False;
  end;
end;

function TEdEditor.KeyDown(AKey: Word; AShift: TShiftState): Boolean;
var
  Ctrl, Sel, Alt: Boolean;
  NewRow, NewCol, Row1, Col1, Row2, Col2, PageRows, LineIdx: Integer;
  Line: WideString;
begin
  Result := False;
  if FBuffer = nil then
    Exit;
  Ctrl := ssCtrl in AShift;
  Sel := ssShift in AShift;
  Alt := ssAlt in AShift;
  NewRow := FCaretRow;
  NewCol := FCaretCol;
  // Буквы - только с Ctrl (без Alt: Ctrl+Alt - AltGr, это символ)
  if (AKey >= Ord('A')) and (AKey <= Ord('Z')) and (not Ctrl or Alt) then
    Exit;
  case AKey of
    EdKeyLeft:
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
    EdKeyRight:
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
    EdKeyUp:
      if Ctrl then
      begin
        if Assigned(FOnScroll) then
          FOnScroll(Self, -1);
      end
      else if FCaretRow > 0 then
        MoveTo(FCaretRow - 1, ColAtScreen(FCaretRow - 1, FPrefCol), Sel, True)
      else
        MoveTo(FCaretRow, FCaretCol, Sel, True);
    EdKeyDown:
      if Ctrl then
      begin
        if Assigned(FOnScroll) then
          FOnScroll(Self, 1);
      end
      else if FCaretRow < FBuffer.Count - 1 then
        MoveTo(FCaretRow + 1, ColAtScreen(FCaretRow + 1, FPrefCol), Sel, True)
      else
        MoveTo(FCaretRow, FCaretCol, Sel, True);
    EdKeyPrior, EdKeyNext:
      begin
        // Страница: окно и каретка - на столько же строк
        PageRows := FPageRows - 1;
        if PageRows < 1 then
          PageRows := 1;
        if AKey = EdKeyPrior then
          PageRows := -PageRows;
        if Assigned(FOnScroll) then
          FOnScroll(Self, PageRows);
        NewRow := FCaretRow + PageRows;
        if NewRow < 0 then
          NewRow := 0;
        if NewRow > FBuffer.Count - 1 then
          NewRow := FBuffer.Count - 1;
        MoveTo(NewRow, ColAtScreen(NewRow, FPrefCol), Sel, True);
      end;
    EdKeyHome:
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
        if (FCaretCol = LineIdx) or not FSmartHome then
          LineIdx := 0;
        MoveTo(FCaretRow, LineIdx, Sel);
      end;
    EdKeyEnd:
      if Ctrl then
        MoveTo(FBuffer.Count - 1, FBuffer.LineLength(FBuffer.Count - 1), Sel)
      else
        MoveTo(FCaretRow, FBuffer.LineLength(FCaretRow), Sel);
    EdKeyInsert:
      if Ctrl and not Sel then
        CopyToClipboard
      else if Sel and not Ctrl then
        PasteFromClipboard
      else if not Ctrl and not Sel then
        SetOverwrite(not FOverwrite);
    EdKeyDelete:
      if Sel and not Ctrl then
        CutToClipboard
      else if Ctrl then
        DeleteWordRight
      else
        DeleteChar;
    EdKeyBack:
      if Alt and Sel then
        Redo
      else if Alt then
        Undo
      else if Ctrl then
        DeleteWordLeft
      else
        Backspace;
    EdKeyReturn:
      if Alt then
        Exit
      else
        NewLine;
    EdKeyTab:
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
  Result := True;
end;

end.
