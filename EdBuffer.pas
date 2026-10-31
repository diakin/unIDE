unit EdBuffer;

// ---------------------------------------------------------------------------
//  Текст редактора без окна - общий для редактора F4 unIDE FAR (TFarEditor,
//  FarEdit.pas) и, дальше по плану портирования (шаг 0.7), основного
//  редактора unIDE.
//
//  - Строки - WideString, без переводов строк. Позиция - строка (с 0) и
//    символ в строке (с 0). Кусок текста из нескольких строк - строки
//    через #10.
//  - Хранение - дерево кусков (как в Edit2GB): исходный текст (FOrig) и
//    буфер добавленного (FAdd) не меняются, текст - последовательность
//    кусков-ссылок на них в декартовом дереве (treap). В узле - длина и
//    число #10 своего поддерева, поэтому поиск строки, правка и сквозной
//    индекс - за O(log n) без сдвига массива строк.
//  - Строки для чтения (Lines[], LineLength) - из кэша на EdCacheSize
//    строк; при промахе читается EdCacheBlock строк подряд.
//  - Правка без отката: InsertRaw, DeleteRaw. С откатом: InsertText,
//    DeleteText, ReplaceText (или RecordInsert / RecordDelete рядом с
//    InsertRaw / DeleteRaw). В записи отката - и
//    каретка до правки: Undo возвращает её туда.
//  - Откат группами: правки одной группы (BeginGroup - новая) откатываются
//    вместе; набор подряд (ATyping) в одной строке сливается в одну правку.
//  - Modified - по откату: вернулись к состоянию записи (MarkSaved) - не
//    изменён.
//  - Сквозной индекс символа (перевод строки - 1 символ, как у RichEdit 4.1
//    и прослойки EdIntf): CharIndex, PosOfIndex, TextLength - по дереву.
//  - Version растёт при каждой правке; подписчики (AddListener) получают,
//    какие строки заменены: первая, сколько было, сколько стало.
//
//  Модуль без Windows и VCL/LCL: собирается Free Pascal (Windows, Linux).
//  Тесты - tests\EdBuffer.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  SysUtils;

const
  EdPieceMax = 256;      // наибольший кусок при загрузке и вставке, символов
  EdCacheSize = 256;     // строк в кэше чтения (степень двойки)
  EdCacheBlock = 32;     // строк читается подряд при промахе кэша

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
    Typing: Boolean;        // набор с клавиатуры (сливается при откате)
  end;
  TEdUndoItems = array of TEdUndoItem;

  // Строки AFirst .. AFirst + AOldCount - 1 заменены ANewCount строками
  TEdChangeEvent = procedure(Sender: TObject; AFirst, AOldCount,
    ANewCount: Integer) of object;

  // Узел дерева кусков: кусок Source (0 - FOrig, 1 - FAdd) с символа Start
  // (с 0) длиной Len, в нём Lf переводов строки; SubLen / SubLf - то же для
  // всего поддерева
  PEdPiece = ^TEdPiece;
  TEdPiece = record
    Left: PEdPiece;
    Right: PEdPiece;
    Prio: Cardinal;
    Source: Byte;
    Start: Integer;
    Len: Integer;
    Lf: Integer;
    SubLen: Integer;
    SubLf: Integer;
  end;

  TEdBuffer = class
  private
    FRoot: PEdPiece;
    FOrig: WideString;
    FAdd: WideString;
    FAddLen: Integer;        // занято в FAdd (остальное - запас)
    FSeed: Cardinal;
    FCount: Integer;
    FCacheRows: array[0..EdCacheSize - 1] of Integer;   // -1 - пусто
    FCacheText: array[0..EdCacheSize - 1] of WideString;
    FPatchedRow: Integer;    // строка, исправленная в кэше на месте (-1 - нет)
    FUndo: TEdUndoItems;
    FUndoCount: Integer;
    FRedo: TEdUndoItems;
    FRedoCount: Integer;
    FGroup: Integer;
    FSavedUndo: Integer;    // FUndoCount на момент записи; -1 - не достичь
    FVersion: Integer;
    FListeners: array of TEdChangeEvent;
    function GetLine(AIndex: Integer): WideString;
    procedure Changed(AFirst, AOldCount, ANewCount: Integer);
    procedure PushUndo(const AItem: TEdUndoItem);
    // --- дерево кусков ---
    function NextPrio: Cardinal;
    function PieceText(ANode: PEdPiece): PWideChar;
    function NewPiece(ASource: Byte; AStart, ALen: Integer;
      APrio: Cardinal): PEdPiece;
    procedure SplitTree(ANode: PEdPiece; APos: Integer;
      var ALeft, ARight: PEdPiece);
    function MergeTree(ALeft, ARight: PEdPiece): PEdPiece;
    function BuildTree(AFirst, ALast, ADepth: Integer): PEdPiece;
    function ExtendLast(ANode: PEdPiece; AAddStart, ALen: Integer): Boolean;
    procedure CopyRange(ANode: PEdPiece; APos, ACount: Integer;
      var ADest: PWideChar);
    procedure CopyWithBreaks(ANode: PEdPiece; const ALineBreak: WideString;
      var ADest: PWideChar);
    procedure LoadOrig(AOldCount: Integer);
    procedure InsertAt(APos: Integer; const AText: WideString);
    procedure DeleteAt(APos, ACount: Integer);
    function ReadRange(APos, ACount: Integer): WideString;
    function LineStartOf(ARow: Integer): Integer;
    function BreaksBefore(APos: Integer): Integer;
    // --- кэш строк ---
    procedure ClearCache;
    procedure FillCache(ARow: Integer);
    function CacheSlot(ARow: Integer): Integer;
    procedure LineSpan(ARow: Integer; var AStart, ALen: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    // Весь текст: строки через #10 (#13#10 и одиночный #13 - тоже перевод
    // строки). Откат очищается, текст считается записанным
    procedure SetText(const AText: WideString);
    // То же, но строка забирается без копии (после вызова AText пуст):
    // для текста, только что прочитанного из файла. #13 в ней ищется и
    // заменяется на месте; текст уже через #10 - без лишнего прохода с
    // переносом
    procedure TakeText(var AText: WideString);
    // Весь текст, строки через ALineBreak (после последней - нет)
    function GetText(const ALineBreak: WideString): WideString;
    // Замена текста массивом строк (строки без #10): ALines забирается
    // (после вызова пуст), ACount строк (0 - один пустой). Откат очищается
    procedure AssignLines(var ALines: TEdLines; ACount: Integer);
    // Конец куска AText (строки через #10), вставленного в (ARow, ACol)
    class procedure EndPosOf(ARow, ACol: Integer; const AText: WideString;
      var AEndRow, AEndCol: Integer);
    // Текст отрезка (ARow1, ACol1) - (ARow2, ACol2), строки через #10
    function TextRange(ARow1, ACol1, ARow2, ACol2: Integer): WideString;

    // --- Без отката ---
    // Вставка AText в (ARow, ACol); конец вставленного - AEndRow / AEndCol.
    // False - вставлять нечего
    function InsertRaw(ARow, ACol: Integer; const AText: WideString;
      var AEndRow, AEndCol: Integer): Boolean;
    // Удаление (ARow1, ACol1) - (ARow2, ACol2); результат - удалённое
    function DeleteRaw(ARow1, ACol1, ARow2, ACol2: Integer): WideString;

    // --- Откат ---
    // Новая группа отката: следующие правки откатываются отдельно
    procedure BeginGroup;
    // Последняя запись - набор с клавиатуры (сливается со следующим)
    function LastIsTyping: Boolean;
    // Записать вставку / удаление в откат (сама правка - InsertRaw /
    // DeleteRaw). ACurRow / ACurCol - каретка до правки. Набор подряд
    // (ATyping) в одной группе дописывается к последней записи
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
    // Удаление плюс вставка - одной группой отката (своей группой для Undo);
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

    // --- Подписчики на изменения строк ---
    procedure AddListener(AEvent: TEdChangeEvent);
    procedure RemoveListener(AEvent: TEdChangeEvent);

    // Длина строки без копирования строки
    function LineLength(ARow: Integer): Integer;

    property Count: Integer read FCount;
    property Lines[AIndex: Integer]: WideString read GetLine; default;
    property Version: Integer read FVersion;
    property UndoCount: Integer read FUndoCount;
    property RedoCount: Integer read FRedoCount;
  end;

implementation

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

function CountBreaks(AText: PWideChar; ALen: Integer): Integer;
var
  CharIdx: Integer;
begin
  Result := 0;
  for CharIdx := 0 to ALen - 1 do
    if AText[CharIdx] = #10 then
      Inc(Result);
end;

// Номер символа (с 0) ANth-го (с 1) перевода строки в куске
function NthBreak(AText: PWideChar; ALen, ANth: Integer): Integer;
var
  CharIdx: Integer;
begin
  for CharIdx := 0 to ALen - 1 do
    if AText[CharIdx] = #10 then
    begin
      Dec(ANth);
      if ANth = 0 then
      begin
        Result := CharIdx;
        Exit;
      end;
    end;
  Result := ALen;
end;

function SubLenOf(ANode: PEdPiece): Integer;
begin
  if ANode = nil then
    Result := 0
  else
    Result := ANode^.SubLen;
end;

function SubLfOf(ANode: PEdPiece): Integer;
begin
  if ANode = nil then
    Result := 0
  else
    Result := ANode^.SubLf;
end;

procedure UpdatePiece(ANode: PEdPiece);
begin
  ANode^.SubLen := ANode^.Len + SubLenOf(ANode^.Left) +
    SubLenOf(ANode^.Right);
  ANode^.SubLf := ANode^.Lf + SubLfOf(ANode^.Left) + SubLfOf(ANode^.Right);
end;

procedure FreeTree(ANode: PEdPiece);
begin
  if ANode = nil then
    Exit;
  FreeTree(ANode^.Left);
  FreeTree(ANode^.Right);
  Dispose(ANode);
end;

function MinInt(AFirst, ASecond: Integer): Integer;
begin
  if AFirst < ASecond then
    Result := AFirst
  else
    Result := ASecond;
end;

constructor TEdBuffer.Create;
begin
  inherited Create;
  FSeed := $9E3779B9;
  FPatchedRow := -1;
  FSavedUndo := 0;
  FOrig := '';
  LoadOrig(1);
end;

destructor TEdBuffer.Destroy;
begin
  FreeTree(FRoot);
  FRoot := nil;
  inherited Destroy;
end;

// --- Дерево кусков ----------------------------------------------------------

function TEdBuffer.NextPrio: Cardinal;
begin
  // xorshift32
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed;
end;

function TEdBuffer.PieceText(ANode: PEdPiece): PWideChar;
begin
  if ANode^.Source = 0 then
    Result := PWideChar(Pointer(FOrig))
  else
    Result := PWideChar(Pointer(FAdd));
  Inc(Result, ANode^.Start);
end;

function TEdBuffer.NewPiece(ASource: Byte; AStart, ALen: Integer;
  APrio: Cardinal): PEdPiece;
begin
  New(Result);
  Result^.Left := nil;
  Result^.Right := nil;
  Result^.Prio := APrio;
  Result^.Source := ASource;
  Result^.Start := AStart;
  Result^.Len := ALen;
  Result^.Lf := CountBreaks(PieceText(Result), ALen);
  Result^.SubLen := ALen;
  Result^.SubLf := Result^.Lf;
end;

// Разрезать дерево: ALeft - первые APos символов, ARight - остальное
procedure TEdBuffer.SplitTree(ANode: PEdPiece; APos: Integer;
  var ALeft, ARight: PEdPiece);
var
  LeftLen, Offset: Integer;
  Tail, Middle: PEdPiece;
begin
  if ANode = nil then
  begin
    ALeft := nil;
    ARight := nil;
    Exit;
  end;
  LeftLen := SubLenOf(ANode^.Left);
  if APos <= LeftLen then
  begin
    SplitTree(ANode^.Left, APos, ALeft, Middle);
    ANode^.Left := Middle;
    UpdatePiece(ANode);
    ARight := ANode;
  end
  else if APos >= LeftLen + ANode^.Len then
  begin
    SplitTree(ANode^.Right, APos - LeftLen - ANode^.Len, Middle, ARight);
    ANode^.Right := Middle;
    UpdatePiece(ANode);
    ALeft := ANode;
  end
  else
  begin
    // Разрез внутри куска: хвост - новый кусок перед правым поддеревом
    Offset := APos - LeftLen;
    Tail := NewPiece(ANode^.Source, ANode^.Start + Offset,
      ANode^.Len - Offset, NextPrio);
    ANode^.Len := Offset;
    ANode^.Lf := ANode^.Lf - Tail^.Lf;
    ARight := MergeTree(Tail, ANode^.Right);
    ANode^.Right := nil;
    UpdatePiece(ANode);
    ALeft := ANode;
  end;
end;

function TEdBuffer.MergeTree(ALeft, ARight: PEdPiece): PEdPiece;
begin
  if ALeft = nil then
    Result := ARight
  else if ARight = nil then
    Result := ALeft
  else if ALeft^.Prio > ARight^.Prio then
  begin
    ALeft^.Right := MergeTree(ALeft^.Right, ARight);
    UpdatePiece(ALeft);
    Result := ALeft;
  end
  else
  begin
    ARight^.Left := MergeTree(ALeft, ARight^.Left);
    UpdatePiece(ARight);
    Result := ARight;
  end;
end;

// Сбалансированное дерево из кусков FOrig с номерами AFirst .. ALast.
// Приоритет убывает с глубиной (старший байт), чтобы дерево оставалось
// правильным treap для последующих правок
function TEdBuffer.BuildTree(AFirst, ALast, ADepth: Integer): PEdPiece;
var
  MidIdx: Integer;
begin
  Result := nil;
  if AFirst > ALast then
    Exit;
  MidIdx := (AFirst + ALast) div 2;
  Result := NewPiece(0, MidIdx * EdPieceMax,
    MinInt(EdPieceMax, Length(FOrig) - MidIdx * EdPieceMax),
    Cardinal($FFFFFFFF) - (Cardinal(ADepth) shl 24) - (NextPrio and $FFFFFF));
  Result^.Left := BuildTree(AFirst, MidIdx - 1, ADepth + 1);
  Result^.Right := BuildTree(MidIdx + 1, ALast, ADepth + 1);
  UpdatePiece(Result);
end;

// Набор подряд: дописать ALen символов FAdd с AAddStart к последнему куску
// дерева, если он кончается ровно там
function TEdBuffer.ExtendLast(ANode: PEdPiece; AAddStart,
  ALen: Integer): Boolean;
begin
  Result := False;
  if ANode = nil then
    Exit;
  if ANode^.Right <> nil then
    Result := ExtendLast(ANode^.Right, AAddStart, ALen)
  else if (ANode^.Source = 1) and (ANode^.Start + ANode^.Len = AAddStart) and
    (ANode^.Len + ALen <= EdPieceMax) then
  begin
    Inc(ANode^.Lf, CountBreaks(PWideChar(Pointer(FAdd)) + AAddStart, ALen));
    Inc(ANode^.Len, ALen);
    Result := True;
  end;
  if Result then
    UpdatePiece(ANode);
end;

// Скопировать ACount символов с APos (относительно поддерева) в ADest
procedure TEdBuffer.CopyRange(ANode: PEdPiece; APos, ACount: Integer;
  var ADest: PWideChar);
var
  LeftLen, Part: Integer;
begin
  if (ANode = nil) or (ACount <= 0) then
    Exit;
  LeftLen := SubLenOf(ANode^.Left);
  if APos < LeftLen then
  begin
    Part := MinInt(ACount, LeftLen - APos);
    CopyRange(ANode^.Left, APos, Part, ADest);
    Dec(ACount, Part);
    APos := LeftLen;
  end;
  if ACount <= 0 then
    Exit;
  Dec(APos, LeftLen);
  if APos < ANode^.Len then
  begin
    Part := MinInt(ACount, ANode^.Len - APos);
    Move((PieceText(ANode) + APos)^, ADest^, Part * SizeOf(WideChar));
    Inc(ADest, Part);
    Dec(ACount, Part);
    APos := ANode^.Len;
  end;
  if ACount > 0 then
    CopyRange(ANode^.Right, APos - ANode^.Len, ACount, ADest);
end;

// Всё поддерево в ADest, #10 заменяется на ALineBreak
procedure TEdBuffer.CopyWithBreaks(ANode: PEdPiece;
  const ALineBreak: WideString; var ADest: PWideChar);
var
  Chars: PWideChar;
  CharIdx, RunStart, BreakLen: Integer;
begin
  if ANode = nil then
    Exit;
  CopyWithBreaks(ANode^.Left, ALineBreak, ADest);
  Chars := PieceText(ANode);
  BreakLen := Length(ALineBreak);
  RunStart := 0;
  for CharIdx := 0 to ANode^.Len do
    if (CharIdx = ANode^.Len) or (Chars[CharIdx] = #10) then
    begin
      if CharIdx > RunStart then
      begin
        Move(Chars[RunStart], ADest^, (CharIdx - RunStart) *
          SizeOf(WideChar));
        Inc(ADest, CharIdx - RunStart);
      end;
      if (CharIdx < ANode^.Len) and (BreakLen > 0) then
      begin
        Move(ALineBreak[1], ADest^, BreakLen * SizeOf(WideChar));
        Inc(ADest, BreakLen);
      end;
      RunStart := CharIdx + 1;
    end;
  CopyWithBreaks(ANode^.Right, ALineBreak, ADest);
end;

// FOrig заменён: дерево заново, добавленное и откат - пусто
procedure TEdBuffer.LoadOrig(AOldCount: Integer);
var
  PieceCount: Integer;
begin
  FreeTree(FRoot);
  FAdd := '';
  FAddLen := 0;
  PieceCount := (Length(FOrig) + EdPieceMax - 1) div EdPieceMax;
  FRoot := BuildTree(0, PieceCount - 1, 0);
  FCount := SubLfOf(FRoot) + 1;
  ClearCache;
  ClearUndo;
  FSavedUndo := 0;
  Changed(0, AOldCount, FCount);
end;

procedure TEdBuffer.InsertAt(APos: Integer; const AText: WideString);
var
  TextLen, AddStart, Offset, Part: Integer;
  LeftTree, RightTree: PEdPiece;
begin
  TextLen := Length(AText);
  if TextLen = 0 then
    Exit;
  AddStart := FAddLen;
  if FAddLen + TextLen > Length(FAdd) then
    SetLength(FAdd, (FAddLen + TextLen) * 2 + 1024);
  Move(AText[1], FAdd[FAddLen + 1], TextLen * SizeOf(WideChar));
  Inc(FAddLen, TextLen);
  SplitTree(FRoot, APos, LeftTree, RightTree);
  Offset := 0;
  if ExtendLast(LeftTree, AddStart, TextLen) then
    Offset := TextLen;
  while Offset < TextLen do
  begin
    Part := MinInt(EdPieceMax, TextLen - Offset);
    LeftTree := MergeTree(LeftTree,
      NewPiece(1, AddStart + Offset, Part, NextPrio));
    Inc(Offset, Part);
  end;
  FRoot := MergeTree(LeftTree, RightTree);
end;

procedure TEdBuffer.DeleteAt(APos, ACount: Integer);
var
  LeftTree, Rest, Middle, RightTree: PEdPiece;
begin
  if ACount <= 0 then
    Exit;
  SplitTree(FRoot, APos, LeftTree, Rest);
  SplitTree(Rest, ACount, Middle, RightTree);
  FreeTree(Middle);
  FRoot := MergeTree(LeftTree, RightTree);
end;

function TEdBuffer.ReadRange(APos, ACount: Integer): WideString;
var
  Dest: PWideChar;
begin
  Result := '';
  if ACount <= 0 then
    Exit;
  SetLength(Result, ACount);
  Dest := PWideChar(Pointer(Result));
  CopyRange(FRoot, APos, ACount, Dest);
end;

// Сквозной индекс начала строки ARow (0 .. FCount - 1)
function TEdBuffer.LineStartOf(ARow: Integer): Integer;
var
  Node: PEdPiece;
  Remaining, LeftLf: Integer;
begin
  Result := 0;
  if ARow <= 0 then
    Exit;
  Node := FRoot;
  Remaining := ARow;
  while Node <> nil do
  begin
    LeftLf := SubLfOf(Node^.Left);
    if Remaining <= LeftLf then
      Node := Node^.Left
    else
    begin
      Dec(Remaining, LeftLf);
      Inc(Result, SubLenOf(Node^.Left));
      if Remaining <= Node^.Lf then
      begin
        Inc(Result, NthBreak(PieceText(Node), Node^.Len, Remaining) + 1);
        Exit;
      end;
      Dec(Remaining, Node^.Lf);
      Inc(Result, Node^.Len);
      Node := Node^.Right;
    end;
  end;
end;

// Число #10 среди первых APos символов
function TEdBuffer.BreaksBefore(APos: Integer): Integer;
var
  Node: PEdPiece;
  LeftLen: Integer;
begin
  Result := 0;
  Node := FRoot;
  while Node <> nil do
  begin
    LeftLen := SubLenOf(Node^.Left);
    if APos <= LeftLen then
      Node := Node^.Left
    else
    begin
      Inc(Result, SubLfOf(Node^.Left));
      Dec(APos, LeftLen);
      if APos <= Node^.Len then
      begin
        Inc(Result, CountBreaks(PieceText(Node), APos));
        Exit;
      end;
      Inc(Result, Node^.Lf);
      Dec(APos, Node^.Len);
      Node := Node^.Right;
    end;
  end;
end;

// --- Кэш строк -----------------------------------------------------------

procedure TEdBuffer.ClearCache;
var
  SlotIdx: Integer;
begin
  for SlotIdx := 0 to EdCacheSize - 1 do
  begin
    FCacheRows[SlotIdx] := -1;
    FCacheText[SlotIdx] := '';
  end;
end;

// Прочитать строку ARow в кэш. Чтение подряд (предыдущая строка в кэше,
// следующей нет) - сразу EdCacheBlock строк одним куском
procedure TEdBuffer.FillCache(ARow: Integer);
var
  LastRow, StartPos, EndPos, CharIdx, LineBegin, RowIdx, SlotIdx: Integer;
  Block: WideString;
begin
  if (ARow > 0) and
     (FCacheRows[(ARow - 1) and (EdCacheSize - 1)] = ARow - 1) and
     (FCacheRows[(ARow + 1) and (EdCacheSize - 1)] <> ARow + 1) then
    LastRow := MinInt(ARow + EdCacheBlock, FCount) - 1
  else
    LastRow := ARow;
  StartPos := LineStartOf(ARow);
  if LastRow >= FCount - 1 then
    EndPos := TextLength
  else
    EndPos := LineStartOf(LastRow + 1) - 1;
  Block := ReadRange(StartPos, EndPos - StartPos);
  RowIdx := ARow;
  LineBegin := 1;
  for CharIdx := 1 to Length(Block) + 1 do
    if (CharIdx > Length(Block)) or (Block[CharIdx] = #10) then
    begin
      SlotIdx := RowIdx and (EdCacheSize - 1);
      FCacheRows[SlotIdx] := RowIdx;
      if (LineBegin = 1) and (CharIdx > Length(Block)) then
        FCacheText[SlotIdx] := Block
      else
        FCacheText[SlotIdx] := Copy(Block, LineBegin, CharIdx - LineBegin);
      Inc(RowIdx);
      LineBegin := CharIdx + 1;
    end;
end;

function TEdBuffer.CacheSlot(ARow: Integer): Integer;
begin
  Result := ARow and (EdCacheSize - 1);
  if FCacheRows[Result] <> ARow then
    FillCache(ARow);
end;

// Начало и длина строки ARow (0 .. FCount - 1) без чтения её в кэш
procedure TEdBuffer.LineSpan(ARow: Integer; var AStart, ALen: Integer);
begin
  AStart := LineStartOf(ARow);
  if FCacheRows[ARow and (EdCacheSize - 1)] = ARow then
    ALen := Length(FCacheText[ARow and (EdCacheSize - 1)])
  else if ARow = FCount - 1 then
    ALen := TextLength - AStart
  else
    ALen := LineStartOf(ARow + 1) - 1 - AStart;
end;

// --- Чтение ---------------------------------------------------------------

function TEdBuffer.GetLine(AIndex: Integer): WideString;
begin
  if (AIndex >= 0) and (AIndex < FCount) then
    Result := FCacheText[CacheSlot(AIndex)]
  else
    Result := '';
end;

function TEdBuffer.LineLength(ARow: Integer): Integer;
begin
  if (ARow >= 0) and (ARow < FCount) then
    Result := Length(FCacheText[CacheSlot(ARow)])
  else
    Result := 0;
end;

procedure TEdBuffer.Changed(AFirst, AOldCount, ANewCount: Integer);
var
  SlotIdx, ListenerIdx: Integer;
begin
  Inc(FVersion);
  FCount := SubLfOf(FRoot) + 1;
  // Кэш: при том же числе строк сдвига нет - устарели только изменённые;
  // иначе - все от AFirst
  if (AOldCount = ANewCount) and (AOldCount < EdCacheSize) then
  begin
    for SlotIdx := AFirst to AFirst + AOldCount - 1 do
      if (FCacheRows[SlotIdx and (EdCacheSize - 1)] = SlotIdx) and
         (SlotIdx <> FPatchedRow) then
        FCacheRows[SlotIdx and (EdCacheSize - 1)] := -1;
  end
  else
    for SlotIdx := 0 to EdCacheSize - 1 do
      if FCacheRows[SlotIdx] >= AFirst then
        FCacheRows[SlotIdx] := -1;
  FPatchedRow := -1;
  for ListenerIdx := 0 to High(FListeners) do
    FListeners[ListenerIdx](Self, AFirst, AOldCount, ANewCount);
end;

procedure TEdBuffer.SetText(const AText: WideString);
var
  NewText: WideString;
  SrcIdx, DestIdx: Integer;
begin
  // #13#10 и одиночный #13 - в #10
  SetLength(NewText, Length(AText));
  DestIdx := 0;
  SrcIdx := 1;
  while SrcIdx <= Length(AText) do
  begin
    Inc(DestIdx);
    if AText[SrcIdx] = #13 then
    begin
      NewText[DestIdx] := #10;
      if (SrcIdx < Length(AText)) and (AText[SrcIdx + 1] = #10) then
        Inc(SrcIdx);
    end
    else
      NewText[DestIdx] := AText[SrcIdx];
    Inc(SrcIdx);
  end;
  SetLength(NewText, DestIdx);
  FreeTree(FRoot);
  FRoot := nil;
  FOrig := NewText;
  NewText := '';
  LoadOrig(FCount);
end;

procedure TEdBuffer.TakeText(var AText: WideString);
var
  SrcIdx, DestIdx, TextLen: Integer;
begin
  TextLen := Length(AText);
  SrcIdx := 1;
  while (SrcIdx <= TextLen) and (AText[SrcIdx] <> #13) do
    Inc(SrcIdx);
  if SrcIdx <= TextLen then
  begin
    // С первого #13: #13#10 и одиночный #13 - в #10, сдвиг на месте
    DestIdx := SrcIdx - 1;
    while SrcIdx <= TextLen do
    begin
      Inc(DestIdx);
      if AText[SrcIdx] = #13 then
      begin
        AText[DestIdx] := #10;
        if (SrcIdx < TextLen) and (AText[SrcIdx + 1] = #10) then
          Inc(SrcIdx);
      end
      else
        AText[DestIdx] := AText[SrcIdx];
      Inc(SrcIdx);
    end;
    SetLength(AText, DestIdx);
  end;
  FreeTree(FRoot);
  FRoot := nil;
  // WideString при присваивании копируется - передаём сам указатель
  FOrig := '';
  Pointer(FOrig) := Pointer(AText);
  Pointer(AText) := nil;
  LoadOrig(FCount);
end;

function TEdBuffer.GetText(const ALineBreak: WideString): WideString;
var
  Dest: PWideChar;
  TotalLen: Integer;
begin
  if ALineBreak = #10 then
  begin
    Result := ReadRange(0, TextLength);
    Exit;
  end;
  // Длина известна заранее: одно выделение памяти на весь текст
  TotalLen := TextLength + (Length(ALineBreak) - 1) * (FCount - 1);
  Result := '';
  if TotalLen <= 0 then
    Exit;
  SetLength(Result, TotalLen);
  Dest := PWideChar(Pointer(Result));
  CopyWithBreaks(FRoot, ALineBreak, Dest);
end;

procedure TEdBuffer.AssignLines(var ALines: TEdLines; ACount: Integer);
var
  RowIdx, TotalLen, CharPos: Integer;
begin
  if ACount > Length(ALines) then
    ACount := Length(ALines);
  TotalLen := 0;
  for RowIdx := 0 to ACount - 1 do
    Inc(TotalLen, Length(ALines[RowIdx]));
  if ACount > 1 then
    Inc(TotalLen, ACount - 1);
  FreeTree(FRoot);
  FRoot := nil;
  FOrig := '';
  SetLength(FOrig, TotalLen);
  CharPos := 1;
  for RowIdx := 0 to ACount - 1 do
  begin
    if ALines[RowIdx] <> '' then
    begin
      Move(ALines[RowIdx][1], FOrig[CharPos],
        Length(ALines[RowIdx]) * SizeOf(WideChar));
      Inc(CharPos, Length(ALines[RowIdx]));
    end;
    if RowIdx < ACount - 1 then
    begin
      FOrig[CharPos] := #10;
      Inc(CharPos);
    end;
  end;
  ALines := nil;
  LoadOrig(FCount);
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
  Index1, Index2: Integer;
begin
  Index1 := CharIndex(ARow1, ACol1);
  Index2 := CharIndex(ARow2, ACol2);
  Result := ReadRange(Index1, Index2 - Index1);
end;

function TEdBuffer.InsertRaw(ARow, ACol: Integer; const AText: WideString;
  var AEndRow, AEndCol: Integer): Boolean;
var
  LineStart, LineLen, SlotIdx: Integer;
begin
  Result := AText <> '';
  AEndRow := ARow;
  AEndCol := ACol;
  if not Result then
    Exit;
  if ARow < 0 then
    ARow := 0;
  if ARow >= FCount then
    ARow := FCount - 1;
  LineSpan(ARow, LineStart, LineLen);
  if ACol > LineLen then
    ACol := LineLen;
  if ACol < 0 then
    ACol := 0;
  InsertAt(LineStart + ACol, AText);
  EndPosOf(ARow, ACol, AText, AEndRow, AEndCol);
  // Набор в строке: строка в кэше правится на месте, не перечитывается
  SlotIdx := ARow and (EdCacheSize - 1);
  if (AEndRow = ARow) and (FCacheRows[SlotIdx] = ARow) then
  begin
    Insert(AText, FCacheText[SlotIdx], ACol + 1);
    FPatchedRow := ARow;
  end;
  Changed(ARow, 1, AEndRow - ARow + 1);
end;

function TEdBuffer.DeleteRaw(ARow1, ACol1, ARow2, ACol2: Integer): WideString;
var
  Index1, Index2, SlotIdx: Integer;
begin
  Index1 := CharIndex(ARow1, ACol1);
  Index2 := CharIndex(ARow2, ACol2);
  Result := ReadRange(Index1, Index2 - Index1);
  DeleteAt(Index1, Index2 - Index1);
  // Удаление внутри строки: строка в кэше правится на месте
  SlotIdx := ARow1 and (EdCacheSize - 1);
  if (ARow1 = ARow2) and (ARow1 >= 0) and (ARow1 < FCount) and
     (FCacheRows[SlotIdx] = ARow1) and (Index2 > Index1) then
  begin
    if ACol1 < 0 then
      ACol1 := 0;
    Delete(FCacheText[SlotIdx], ACol1 + 1, Index2 - Index1);
    FPatchedRow := ARow1;
  end;
  Changed(ARow1, ARow2 - ARow1 + 1, 1);
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
  // Новая правка - повторять отменённое больше нельзя
  FRedoCount := 0;
  // Записанное состояние было в отменённой ветке - его не достичь
  if FSavedUndo > FUndoCount then
    FSavedUndo := -1;
end;

procedure TEdBuffer.RecordInsert(ARow, ACol: Integer; const AText: WideString;
  ATyping: Boolean; ACurRow, ACurCol: Integer);
var
  Item: TEdUndoItem;
  EndRow, EndCol: Integer;
begin
  // Набор подряд: в позицию сразу после прошлого набора - дописать к нему
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
  if ACol > LineLength(ARow) then
    ACol := LineLength(ARow);
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
    // Повтор - снова в откат, но набор дальше не дописывать
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

function TEdBuffer.CharIndex(ARow, ACol: Integer): Integer;
var
  LineLen: Integer;
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
  if ACol <= 0 then
  begin
    Result := LineStartOf(ARow);
    Exit;
  end;
  LineSpan(ARow, Result, LineLen);
  if ACol > LineLen then
    ACol := LineLen;
  Inc(Result, ACol);
end;

procedure TEdBuffer.PosOfIndex(AIndex: Integer; var ARow, ACol: Integer);
begin
  if AIndex <= 0 then
  begin
    ARow := 0;
    ACol := 0;
    Exit;
  end;
  if AIndex > TextLength then
    AIndex := TextLength;
  ARow := BreaksBefore(AIndex);
  ACol := AIndex - LineStartOf(ARow);
end;

function TEdBuffer.TextLength: Integer;
begin
  Result := SubLenOf(FRoot);
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
