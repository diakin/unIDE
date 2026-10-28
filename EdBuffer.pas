unit EdBuffer;

// ---------------------------------------------------------------------------
//  Текст редактора без окна - общий для редактора F4 unIDE FAR (TFarEditor,
//  FarEdit.pas) и, дальше по плану портирования (шаг 0.7), основного
//  редактора unIDE.
//
//  - Строки - WideString, без переводов строк. Позиция - строка (с 0) и
//    символ в строке (с 0). Кусок текста из нескольких строк - строки
//    через #10.
//  - Правка без отката: InsertRaw, DeleteRaw. С откатом: InsertText,
//    DeleteText, ReplaceText (или RecordInsert / RecordDelete рядом с
//    InsertRaw / DeleteRaw). В записи отката - и
//    каретка до правки: Undo возвращает её туда.
//  - Откат группами: правки одной группы (BeginGroup - новая) откатываются
//    вместе; набор подряд (ATyping) в одной строке сливается в одну правку.
//  - Modified - по откату: вернулись к состоянию записи (MarkSaved) - не
//    изменён.
//  - Сквозной индекс символа (перевод строки - 1 символ, как у RichEdit 4.1
//    и прослойки EdIntf): CharIndex, PosOfIndex, TextLength - по таблице
//    начал строк; после правки таблица пересчитывается от её места и только
//    по мере надобности.
//  - Version растёт при каждой правке; подписчики (AddListener) получают,
//    какие строки заменены: первая, сколько было, сколько стало.
//
//  Модуль без Windows и VCL/LCL: собирается Delphi 7 и Free Pascal
//  (Windows, Linux). Тесты - tests\EdBuffer.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  SysUtils;

type
  TEdLines = array of WideString;

  TEdUndoItem = record
    IsInsert: Boolean;      // True - вставка Text в (Row, Col); False -
                            // удаление Text, начинавшегося в (Row, Col)
    Row: Integer;
    Col: Integer;
    Text: WideString;       // строки через #10
    Group: Integer;
    CurRow: Integer;        // каретка до правки
    CurCol: Integer;
    Typing: Boolean;        // набор с клавиатуры (продолжается тем же)
  end;
  TEdUndoItems = array of TEdUndoItem;

  // Строки AFirst .. AFirst + AOldCount - 1 заменены ANewCount строками
  TEdChangeEvent = procedure(Sender: TObject; AFirst, AOldCount,
    ANewCount: Integer) of object;

  TEdBuffer = class
  private
    FLines: TEdLines;
    FCount: Integer;
    FUndo: TEdUndoItems;
    FUndoCount: Integer;
    FRedo: TEdUndoItems;
    FRedoCount: Integer;
    FGroup: Integer;
    FSavedUndo: Integer;    // FUndoCount на момент записи; -1 - не достичь
    FVersion: Integer;
    FStarts: array of Integer;   // сквозной индекс начала строки
    FStartsValid: Integer;       // верны FStarts[0 .. FStartsValid - 1]
    FListeners: array of TEdChangeEvent;
    function GetLine(AIndex: Integer): WideString;
    procedure Changed(AFirst, AOldCount, ANewCount: Integer);
    procedure PushUndo(const AItem: TEdUndoItem);
    procedure EnsureStarts(ARow: Integer);
  public
    constructor Create;
    // Весь текст: строки через #10 (#13#10 и одиночный #13 - тоже перевод
    // строки). Откат очищается, текст считается записанным
    procedure SetText(const AText: WideString);
    // Весь текст, строки через ALineBreak (после последней - нет)
    function GetText(const ALineBreak: WideString): WideString;
    // Строки готовым массивом (чтение файла): ALines забирается (после
    // вызова пуст), ACount строк (0 - одна пустая). Откат очищается
    procedure AssignLines(var ALines: TEdLines; ACount: Integer);
    // Конец куска AText (строки через #10), вставленного в (ARow, ACol)
    class procedure EndPosOf(ARow, ACol: Integer; const AText: WideString;
      var AEndRow, AEndCol: Integer);
    // Кусок текста (ARow1, ACol1) - (ARow2, ACol2), строки через #10
    function TextRange(ARow1, ACol1, ARow2, ACol2: Integer): WideString;

    // --- Без отката ---
    // Вставка AText в (ARow, ACol); конец вставленного - AEndRow / AEndCol.
    // False - вставлять нечего
    function InsertRaw(ARow, ACol: Integer; const AText: WideString;
      var AEndRow, AEndCol: Integer): Boolean;
    // Удаление (ARow1, ACol1) - (ARow2, ACol2); результат - удалённое
    function DeleteRaw(ARow1, ACol1, ARow2, ACol2: Integer): WideString;

    // --- Откат ---
    // Новая группа отката: следующая правка откатывается отдельно
    procedure BeginGroup;
    // Последняя правка - набор с клавиатуры (продолжать ли его группу)
    function LastIsTyping: Boolean;
    // Записать вставку / удаление в откат (сама правка - InsertRaw /
    // DeleteRaw). ACurRow / ACurCol - каретка до правки. Набор подряд
    // (ATyping) в конце прежнего набора той же группы - к нему
    procedure RecordInsert(ARow, ACol: Integer; const AText: WideString;
      ATyping: Boolean; ACurRow, ACurCol: Integer);
    procedure RecordDelete(ARow, ACol: Integer; const AText: WideString;
      ACurRow, ACurCol: Integer);
    // Правка с откатом (в текущей группе)
    procedure InsertText(ARow, ACol: Integer; const AText: WideString;
      ATyping: Boolean; ACurRow, ACurCol: Integer;
      var AEndRow, AEndCol: Integer);
    function DeleteText(ARow1, ACol1, ARow2, ACol2: Integer;
      ACurRow, ACurCol: Integer): WideString;
    // Заменить кусок текстом - своей группой отката (одна правка для Undo);
    // конец вставленного - AEndRow / AEndCol
    procedure ReplaceText(ARow1, ACol1, ARow2, ACol2: Integer;
      const AText: WideString; ACurRow, ACurCol: Integer;
      var AEndRow, AEndCol: Integer);
    // Откатить / повторить группу; ARow / ACol - куда поставить каретку.
    // False - нечего
    function Undo(var ARow, ACol: Integer): Boolean;
    function Redo(var ARow, ACol: Integer): Boolean;
    function CanUndo: Boolean;
    function CanRedo: Boolean;
    procedure ClearUndo;
    // Текст записан: Modified = False, пока откат не уйдёт от этого места
    procedure MarkSaved;
    function Modified: Boolean;

    // --- Сквозной индекс (перевод строки - 1 символ) ---
    function CharIndex(ARow, ACol: Integer): Integer;
    procedure PosOfIndex(AIndex: Integer; var ARow, ACol: Integer);
    function TextLength: Integer;

    // --- Подписчики на изменение строк ---
    procedure AddListener(AEvent: TEdChangeEvent);
    procedure RemoveListener(AEvent: TEdChangeEvent);

    // Длина строки без копирования (Lines[] в Delphi 7 копирует WideString)
    function LineLength(ARow: Integer): Integer;

    property Count: Integer read FCount;
    property Lines[AIndex: Integer]: WideString read GetLine; default;
    property Version: Integer read FVersion;
    property UndoCount: Integer read FUndoCount;
    property RedoCount: Integer read FRedoCount;
  end;

implementation

// ADest := AFirst + ASecond. Обе пустые - приёмник очищается явно: в
// Delphi 7 после Enter в начале строки строка оставалась прежней (копия
// вместо пустой), хотя в Free Pascal тот же код работает. Пустая строка не
// получается сложением двух пустых WideString
procedure EdJoin(var ADest: WideString; const AFirst, ASecond: WideString);
begin
  if AFirst = '' then
  begin
    if ASecond = '' then
      ADest := ''
    else
      ADest := ASecond;
  end
  else if ASecond = '' then
    ADest := AFirst
  else
    ADest := AFirst + ASecond;
end;

function EdHasBreak(const AText: WideString): Boolean;
var
  CharIdx: Integer;
begin
  Result := False;
  for CharIdx := 1 to Length(AText) do
    if AText[CharIdx] = #10 then
    begin
      Result := True;
      Exit;
    end;
end;

constructor TEdBuffer.Create;
begin
  inherited Create;
  SetLength(FLines, 1);
  FLines[0] := '';
  FCount := 1;
  FSavedUndo := 0;
  FStartsValid := 0;
end;

function TEdBuffer.GetLine(AIndex: Integer): WideString;
begin
  if (AIndex >= 0) and (AIndex < FCount) then
    Result := FLines[AIndex]
  else
    Result := '';
end;

procedure TEdBuffer.Changed(AFirst, AOldCount, ANewCount: Integer);
var
  ListenerIdx: Integer;
begin
  Inc(FVersion);
  // Начало строки AFirst не меняется (оно - от строк выше), следующих - да
  if FStartsValid > AFirst + 1 then
    FStartsValid := AFirst + 1;
  if FStartsValid < 0 then
    FStartsValid := 0;
  for ListenerIdx := 0 to High(FListeners) do
    FListeners[ListenerIdx](Self, AFirst, AOldCount, ANewCount);
end;

procedure TEdBuffer.SetText(const AText: WideString);
var
  NewLines: TEdLines;
  LineCount, CharIdx, StartIdx: Integer;
begin
  LineCount := 0;
  SetLength(NewLines, 16);
  StartIdx := 1;
  CharIdx := 1;
  while CharIdx <= Length(AText) do
  begin
    if (AText[CharIdx] = #13) or (AText[CharIdx] = #10) then
    begin
      if LineCount >= Length(NewLines) then
        SetLength(NewLines, LineCount * 2);
      NewLines[LineCount] := Copy(AText, StartIdx, CharIdx - StartIdx);
      Inc(LineCount);
      if (AText[CharIdx] = #13) and (CharIdx < Length(AText)) and
         (AText[CharIdx + 1] = #10) then
        Inc(CharIdx);
      StartIdx := CharIdx + 1;
    end;
    Inc(CharIdx);
  end;
  if LineCount >= Length(NewLines) then
    SetLength(NewLines, LineCount + 1);
  NewLines[LineCount] := Copy(AText, StartIdx, MaxInt);
  Inc(LineCount);
  AssignLines(NewLines, LineCount);
end;

function TEdBuffer.GetText(const ALineBreak: WideString): WideString;
var
  RowIdx, TotalLen, CharPos, BreakLen: Integer;
begin
  // Длина - заранее: сцепление по строке на большом тексте медленно
  BreakLen := Length(ALineBreak);
  TotalLen := 0;
  for RowIdx := 0 to FCount - 1 do
    Inc(TotalLen, Length(FLines[RowIdx]));
  Inc(TotalLen, BreakLen * (FCount - 1));
  SetLength(Result, TotalLen);
  CharPos := 1;
  for RowIdx := 0 to FCount - 1 do
  begin
    if FLines[RowIdx] <> '' then
    begin
      Move(FLines[RowIdx][1], Result[CharPos],
        Length(FLines[RowIdx]) * SizeOf(WideChar));
      Inc(CharPos, Length(FLines[RowIdx]));
    end;
    if (RowIdx < FCount - 1) and (BreakLen > 0) then
    begin
      Move(ALineBreak[1], Result[CharPos], BreakLen * SizeOf(WideChar));
      Inc(CharPos, BreakLen);
    end;
  end;
end;

procedure TEdBuffer.AssignLines(var ALines: TEdLines; ACount: Integer);
var
  OldCount: Integer;
begin
  OldCount := FCount;
  FLines := ALines;
  ALines := nil;
  FCount := ACount;
  if FCount <= 0 then
  begin
    SetLength(FLines, 1);
    FLines[0] := '';
    FCount := 1;
  end;
  if Length(FLines) < FCount then
    SetLength(FLines, FCount);
  ClearUndo;
  FSavedUndo := 0;
  FStartsValid := 0;
  Changed(0, OldCount, FCount);
end;

class procedure TEdBuffer.EndPosOf(ARow, ACol: Integer;
  const AText: WideString; var AEndRow, AEndCol: Integer);
var
  CharIdx, LastBreak: Integer;
begin
  AEndRow := ARow;
  LastBreak := 0;
  for CharIdx := 1 to Length(AText) do
    if AText[CharIdx] = #10 then
    begin
      Inc(AEndRow);
      LastBreak := CharIdx;
    end;
  if LastBreak = 0 then
    AEndCol := ACol + Length(AText)
  else
    AEndCol := Length(AText) - LastBreak;
end;

function TEdBuffer.TextRange(ARow1, ACol1, ARow2, ACol2: Integer): WideString;
var
  RowIdx: Integer;
begin
  if ARow1 = ARow2 then
  begin
    Result := Copy(GetLine(ARow1), ACol1 + 1, ACol2 - ACol1);
    Exit;
  end;
  Result := Copy(GetLine(ARow1), ACol1 + 1, MaxInt);
  for RowIdx := ARow1 + 1 to ARow2 - 1 do
    Result := Result + #10 + GetLine(RowIdx);
  Result := Result + #10 + Copy(GetLine(ARow2), 1, ACol2);
end;

function TEdBuffer.InsertRaw(ARow, ACol: Integer; const AText: WideString;
  var AEndRow, AEndCol: Integer): Boolean;
var
  Parts: TEdLines;
  PartCount, CharIdx, StartIdx, PartIdx: Integer;
  Head, Tail: WideString;
begin
  Result := AText <> '';
  AEndRow := ARow;
  AEndCol := ACol;
  if not Result then
    Exit;
  // Куски между #10
  PartCount := 0;
  SetLength(Parts, 0);
  StartIdx := 1;
  for CharIdx := 1 to Length(AText) + 1 do
    if (CharIdx > Length(AText)) or (AText[CharIdx] = #10) then
    begin
      SetLength(Parts, PartCount + 1);
      Parts[PartCount] := Copy(AText, StartIdx, CharIdx - StartIdx);
      Inc(PartCount);
      StartIdx := CharIdx + 1;
    end;
  Head := Copy(FLines[ARow], 1, ACol);
  Tail := Copy(FLines[ARow], ACol + 1, MaxInt);
  if PartCount = 1 then
  begin
    FLines[ARow] := Head + Parts[0] + Tail;
    AEndCol := ACol + Length(Parts[0]);
  end
  else
  begin
    // Новые строки - после ARow
    if FCount + PartCount - 1 > Length(FLines) then
      SetLength(FLines, FCount + PartCount - 1 + FCount div 4 + 16);
    for PartIdx := FCount - 1 downto ARow + 1 do
      FLines[PartIdx + PartCount - 1] := FLines[PartIdx];
    Inc(FCount, PartCount - 1);
    EdJoin(FLines[ARow], Head, Parts[0]);
    for PartIdx := 1 to PartCount - 2 do
      FLines[ARow + PartIdx] := Parts[PartIdx];
    EdJoin(FLines[ARow + PartCount - 1], Parts[PartCount - 1], Tail);
    AEndRow := ARow + PartCount - 1;
    AEndCol := Length(Parts[PartCount - 1]);
  end;
  Changed(ARow, 1, PartCount);
end;

function TEdBuffer.DeleteRaw(ARow1, ACol1, ARow2, ACol2: Integer): WideString;
var
  RowIdx, Removed: Integer;
begin
  if ARow1 = ARow2 then
  begin
    Result := Copy(FLines[ARow1], ACol1 + 1, ACol2 - ACol1);
    Delete(FLines[ARow1], ACol1 + 1, ACol2 - ACol1);
    Changed(ARow1, 1, 1);
    Exit;
  end;
  Result := Copy(FLines[ARow1], ACol1 + 1, MaxInt);
  for RowIdx := ARow1 + 1 to ARow2 - 1 do
    Result := Result + #10 + FLines[RowIdx];
  Result := Result + #10 + Copy(FLines[ARow2], 1, ACol2);
  EdJoin(FLines[ARow1], Copy(FLines[ARow1], 1, ACol1),
    Copy(FLines[ARow2], ACol2 + 1, MaxInt));
  Removed := ARow2 - ARow1;
  for RowIdx := ARow1 + 1 to FCount - 1 - Removed do
    FLines[RowIdx] := FLines[RowIdx + Removed];
  for RowIdx := FCount - Removed to FCount - 1 do
    FLines[RowIdx] := '';
  Dec(FCount, Removed);
  Changed(ARow1, Removed + 1, 1);
end;

procedure TEdBuffer.BeginGroup;
begin
  Inc(FGroup);
end;

function TEdBuffer.LastIsTyping: Boolean;
begin
  Result := (FUndoCount > 0) and FUndo[FUndoCount - 1].Typing;
end;

procedure TEdBuffer.PushUndo(const AItem: TEdUndoItem);
begin
  if FUndoCount >= Length(FUndo) then
    SetLength(FUndo, FUndoCount * 2 + 64);
  FUndo[FUndoCount] := AItem;
  Inc(FUndoCount);
  // Новая правка - повторять откаченное больше нечего
  FRedoCount := 0;
  // Состояние «записано» было в откаченной части - уже не достижимо
  if FSavedUndo > FUndoCount then
    FSavedUndo := -1;
end;

procedure TEdBuffer.RecordInsert(ARow, ACol: Integer; const AText: WideString;
  ATyping: Boolean; ACurRow, ACurCol: Integer);
var
  Item: TEdUndoItem;
  EndRow, EndCol: Integer;
begin
  // Набор подряд: к прежней вставке, если она - набор и кончается здесь
  if ATyping and (FUndoCount > 0) and (FUndoCount > FSavedUndo) and
     FUndo[FUndoCount - 1].IsInsert and FUndo[FUndoCount - 1].Typing and
     (FUndo[FUndoCount - 1].Group = FGroup) then
  begin
    EndPosOf(FUndo[FUndoCount - 1].Row, FUndo[FUndoCount - 1].Col,
      FUndo[FUndoCount - 1].Text, EndRow, EndCol);
    if (EndRow = ARow) and (EndCol = ACol) and not EdHasBreak(AText) then
    begin
      FUndo[FUndoCount - 1].Text := FUndo[FUndoCount - 1].Text + AText;
      FRedoCount := 0;
      Exit;
    end;
  end;
  Item.IsInsert := True;
  Item.Row := ARow;
  Item.Col := ACol;
  Item.Text := AText;
  Item.Group := FGroup;
  Item.CurRow := ACurRow;
  Item.CurCol := ACurCol;
  Item.Typing := ATyping;
  PushUndo(Item);
end;

procedure TEdBuffer.RecordDelete(ARow, ACol: Integer; const AText: WideString;
  ACurRow, ACurCol: Integer);
var
  Item: TEdUndoItem;
begin
  Item.IsInsert := False;
  Item.Row := ARow;
  Item.Col := ACol;
  Item.Text := AText;
  Item.Group := FGroup;
  Item.CurRow := ACurRow;
  Item.CurCol := ACurCol;
  Item.Typing := False;
  PushUndo(Item);
end;

procedure TEdBuffer.InsertText(ARow, ACol: Integer; const AText: WideString;
  ATyping: Boolean; ACurRow, ACurCol: Integer; var AEndRow, AEndCol: Integer);
begin
  AEndRow := ARow;
  AEndCol := ACol;
  if AText = '' then
    Exit;
  RecordInsert(ARow, ACol, AText, ATyping, ACurRow, ACurCol);
  InsertRaw(ARow, ACol, AText, AEndRow, AEndCol);
end;

function TEdBuffer.DeleteText(ARow1, ACol1, ARow2, ACol2: Integer;
  ACurRow, ACurCol: Integer): WideString;
begin
  Result := '';
  if (ARow1 = ARow2) and (ACol1 = ACol2) then
    Exit;
  Result := DeleteRaw(ARow1, ACol1, ARow2, ACol2);
  RecordDelete(ARow1, ACol1, Result, ACurRow, ACurCol);
end;

procedure TEdBuffer.ReplaceText(ARow1, ACol1, ARow2, ACol2: Integer;
  const AText: WideString; ACurRow, ACurCol: Integer;
  var AEndRow, AEndCol: Integer);
begin
  BeginGroup;
  DeleteText(ARow1, ACol1, ARow2, ACol2, ACurRow, ACurCol);
  InsertText(ARow1, ACol1, AText, False, ACurRow, ACurCol, AEndRow, AEndCol);
  BeginGroup;
end;

function TEdBuffer.Undo(var ARow, ACol: Integer): Boolean;
var
  Group, EndRow, EndCol: Integer;
  Item: TEdUndoItem;
begin
  Result := FUndoCount > 0;
  if not Result then
    Exit;
  Group := FUndo[FUndoCount - 1].Group;
  while (FUndoCount > 0) and (FUndo[FUndoCount - 1].Group = Group) do
  begin
    Item := FUndo[FUndoCount - 1];
    Dec(FUndoCount);
    if Item.IsInsert then
    begin
      EndPosOf(Item.Row, Item.Col, Item.Text, EndRow, EndCol);
      DeleteRaw(Item.Row, Item.Col, EndRow, EndCol);
    end
    else
      InsertRaw(Item.Row, Item.Col, Item.Text, EndRow, EndCol);
    if FRedoCount >= Length(FRedo) then
      SetLength(FRedo, FRedoCount * 2 + 64);
    FRedo[FRedoCount] := Item;
    Inc(FRedoCount);
    ARow := Item.CurRow;
    ACol := Item.CurCol;
  end;
  if ARow >= FCount then
    ARow := FCount - 1;
  if ARow < 0 then
    ARow := 0;
  if ACol > Length(FLines[ARow]) then
    ACol := Length(FLines[ARow]);
  if ACol < 0 then
    ACol := 0;
  Inc(FGroup);
end;

function TEdBuffer.Redo(var ARow, ACol: Integer): Boolean;
var
  Group, EndRow, EndCol: Integer;
  Item: TEdUndoItem;
begin
  Result := FRedoCount > 0;
  if not Result then
    Exit;
  Group := FRedo[FRedoCount - 1].Group;
  while (FRedoCount > 0) and (FRedo[FRedoCount - 1].Group = Group) do
  begin
    Item := FRedo[FRedoCount - 1];
    Dec(FRedoCount);
    if Item.IsInsert then
    begin
      InsertRaw(Item.Row, Item.Col, Item.Text, EndRow, EndCol);
      ARow := EndRow;
      ACol := EndCol;
    end
    else
    begin
      EndPosOf(Item.Row, Item.Col, Item.Text, EndRow, EndCol);
      DeleteRaw(Item.Row, Item.Col, EndRow, EndCol);
      ARow := Item.Row;
      ACol := Item.Col;
    end;
    // Повтор - снова в откат, не трогая остальное повторяемое
    Item.Typing := False;
    if FUndoCount >= Length(FUndo) then
      SetLength(FUndo, FUndoCount * 2 + 64);
    FUndo[FUndoCount] := Item;
    Inc(FUndoCount);
  end;
  Inc(FGroup);
end;

function TEdBuffer.CanUndo: Boolean;
begin
  Result := FUndoCount > 0;
end;

function TEdBuffer.CanRedo: Boolean;
begin
  Result := FRedoCount > 0;
end;

procedure TEdBuffer.ClearUndo;
begin
  FUndoCount := 0;
  FRedoCount := 0;
  FSavedUndo := 0;
end;

procedure TEdBuffer.MarkSaved;
begin
  FSavedUndo := FUndoCount;
end;

function TEdBuffer.Modified: Boolean;
begin
  Result := FUndoCount <> FSavedUndo;
end;

// Таблица начал строк - до строки ARow включительно
procedure TEdBuffer.EnsureStarts(ARow: Integer);
begin
  if ARow >= FCount then
    ARow := FCount - 1;
  if Length(FStarts) < FCount then
    SetLength(FStarts, FCount + FCount div 4 + 64);
  if FStartsValid = 0 then
  begin
    FStarts[0] := 0;
    FStartsValid := 1;
  end;
  while FStartsValid <= ARow do
  begin
    FStarts[FStartsValid] := FStarts[FStartsValid - 1] +
      Length(FLines[FStartsValid - 1]) + 1;
    Inc(FStartsValid);
  end;
end;

function TEdBuffer.CharIndex(ARow, ACol: Integer): Integer;
begin
  if ARow < 0 then
  begin
    Result := 0;
    Exit;
  end;
  if ARow >= FCount then
  begin
    Result := TextLength;
    Exit;
  end;
  if ACol < 0 then
    ACol := 0;
  if ACol > Length(FLines[ARow]) then
    ACol := Length(FLines[ARow]);
  EnsureStarts(ARow);
  Result := FStarts[ARow] + ACol;
end;

procedure TEdBuffer.PosOfIndex(AIndex: Integer; var ARow, ACol: Integer);
var
  LowRow, HighRow, MidRow: Integer;
begin
  EnsureStarts(FCount - 1);
  if AIndex <= 0 then
  begin
    ARow := 0;
    ACol := 0;
    Exit;
  end;
  // Последняя строка, начало которой не дальше AIndex
  LowRow := 0;
  HighRow := FCount - 1;
  while LowRow < HighRow do
  begin
    MidRow := (LowRow + HighRow + 1) div 2;
    if FStarts[MidRow] <= AIndex then
      LowRow := MidRow
    else
      HighRow := MidRow - 1;
  end;
  ARow := LowRow;
  ACol := AIndex - FStarts[ARow];
  if ACol > Length(FLines[ARow]) then
    ACol := Length(FLines[ARow]);
end;

function TEdBuffer.LineLength(ARow: Integer): Integer;
begin
  if (ARow >= 0) and (ARow < FCount) then
    Result := Length(FLines[ARow])
  else
    Result := 0;
end;

function TEdBuffer.TextLength: Integer;
begin
  EnsureStarts(FCount - 1);
  Result := FStarts[FCount - 1] + Length(FLines[FCount - 1]);
end;

procedure TEdBuffer.AddListener(AEvent: TEdChangeEvent);
begin
  SetLength(FListeners, Length(FListeners) + 1);
  FListeners[High(FListeners)] := AEvent;
end;

procedure TEdBuffer.RemoveListener(AEvent: TEdChangeEvent);
var
  ListenerIdx, MoveIdx: Integer;
begin
  for ListenerIdx := High(FListeners) downto 0 do
    if (TMethod(FListeners[ListenerIdx]).Code = TMethod(AEvent).Code) and
       (TMethod(FListeners[ListenerIdx]).Data = TMethod(AEvent).Data) then
    begin
      for MoveIdx := ListenerIdx to High(FListeners) - 1 do
        FListeners[MoveIdx] := FListeners[MoveIdx + 1];
      SetLength(FListeners, Length(FListeners) - 1);
    end;
end;

end.
