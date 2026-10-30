program EdBufferTest;

// ---------------------------------------------------------------------------
//  Тесты EdBuffer.pas (текст редактора без окна). Консольная программа:
//  Free Pascal (Windows, Linux) или Delphi 7.
//
//    fpc -Mdelphi -Fu..\.. EdBufferTest.dpr        (Linux: -Fu../..)
//    dcc32 -CC -U..\.. EdBufferTest.dpr
//
//  Итог - число проверок и ошибок; код выхода 1, если ошибки есть.
//  Кроме отдельных случаев - случайная проверка: тысячи правок сверяются с
//  простой моделью (весь текст одной строкой, переводы - #10), затем всё
//  откатывается к исходному тексту и повторяется обратно.
// ---------------------------------------------------------------------------

{$APPTYPE CONSOLE}
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

uses
  SysUtils,
  EdBuffer in '..\..\EdBuffer.pas';

type
  TListenerProbe = class
  public
    CallCount: Integer;
    LastFirst, LastOld, LastNew: Integer;
    procedure OnChange(Sender: TObject; AFirst, AOldCount, ANewCount: Integer);
  end;

var
  CheckCount: Integer = 0;
  FailCount: Integer = 0;

procedure TListenerProbe.OnChange(Sender: TObject; AFirst, AOldCount,
  ANewCount: Integer);
begin
  Inc(CallCount);
  LastFirst := AFirst;
  LastOld := AOldCount;
  LastNew := ANewCount;
end;

function Show(const AText: WideString): string;
var
  CharIdx: Integer;
begin
  Result := '';
  for CharIdx := 1 to Length(AText) do
    if AText[CharIdx] = #10 then
      Result := Result + '\n'
    else if Ord(AText[CharIdx]) < 128 then
      Result := Result + Char(Ord(AText[CharIdx]))
    else
      Result := Result + '#' + IntToStr(Ord(AText[CharIdx]));
end;

procedure Check(ACond: Boolean; const AWhat: string);
begin
  Inc(CheckCount);
  if not ACond then
  begin
    Inc(FailCount);
    Writeln('FAIL: ', AWhat);
  end;
end;

procedure CheckText(ABuf: TEdBuffer; const AExpected: WideString;
  const AWhat: string);
var
  Actual: WideString;
begin
  Actual := ABuf.GetText(#10);
  Inc(CheckCount);
  if Actual <> AExpected then
  begin
    Inc(FailCount);
    Writeln('FAIL: ', AWhat, ': "', Show(Actual), '" <> "', Show(AExpected),
      '"');
  end;
end;

procedure CheckInt(AActual, AExpected: Integer; const AWhat: string);
begin
  Inc(CheckCount);
  if AActual <> AExpected then
  begin
    Inc(FailCount);
    Writeln('FAIL: ', AWhat, ': ', AActual, ' <> ', AExpected);
  end;
end;

// --- Модель: весь текст одной строкой, позиция - сквозной индекс --------

function ModelIndex(const AText: WideString; ARow, ACol: Integer): Integer;
var
  CharIdx, RowIdx: Integer;
begin
  RowIdx := 0;
  CharIdx := 1;
  while (RowIdx < ARow) and (CharIdx <= Length(AText)) do
  begin
    if AText[CharIdx] = #10 then
      Inc(RowIdx);
    Inc(CharIdx);
  end;
  Result := CharIdx - 1 + ACol;
end;

// --- Отдельные случаи -----------------------------------------------------

procedure TestSetGetText;
var
  Buf: TEdBuffer;
begin
  Buf := TEdBuffer.Create;
  try
    CheckInt(Buf.Count, 1, 'empty count');
    CheckText(Buf, '', 'empty text');
    Buf.SetText('a'#13#10'b'#10'c'#13'd');
    CheckInt(Buf.Count, 4, 'mixed breaks count');
    CheckText(Buf, 'a'#10'b'#10'c'#10'd', 'mixed breaks text');
    Check(Buf.GetText(#13#10) = 'a'#13#10'b'#13#10'c'#13#10'd',
      'GetText CRLF');
    Buf.SetText('x'#10);
    CheckInt(Buf.Count, 2, 'trailing break gives empty last line');
    Buf.SetText('');
    CheckInt(Buf.Count, 1, 'empty again');
    Check(not Buf.Modified, 'SetText - not modified');
    Check(not Buf.CanUndo, 'SetText - no undo');
  finally
    Buf.Free;
  end;
end;

procedure TestRawEdits;
var
  Buf: TEdBuffer;
  EndRow, EndCol: Integer;
  Removed: WideString;
begin
  Buf := TEdBuffer.Create;
  try
    Buf.SetText('hello'#10'world');
    Buf.InsertRaw(0, 5, ' big', EndRow, EndCol);
    CheckText(Buf, 'hello big'#10'world', 'insert in line');
    CheckInt(EndRow, 0, 'insert end row');
    CheckInt(EndCol, 9, 'insert end col');
    Buf.InsertRaw(1, 2, 'X'#10'Y'#10'Z', EndRow, EndCol);
    CheckText(Buf, 'hello big'#10'woX'#10'Y'#10'Zrld', 'insert 3 lines');
    CheckInt(Buf.Count, 4, 'count after multi insert');
    CheckInt(EndRow, 3, 'multi insert end row');
    CheckInt(EndCol, 1, 'multi insert end col');
    Removed := Buf.DeleteRaw(1, 3, 3, 1);
    Check(Removed = #10'Y'#10'Z', 'removed text across lines');
    CheckText(Buf, 'hello big'#10'woXrld', 'delete across lines');
    Removed := Buf.DeleteRaw(0, 9, 1, 0);
    Check(Removed = #10, 'removed line break');
    CheckText(Buf, 'hello bigwoXrld', 'join lines');
    Buf.InsertRaw(0, 0, #10, EndRow, EndCol);
    CheckText(Buf, #10'hello bigwoXrld', 'break at start');
    CheckInt(EndRow, 1, 'break end row');
    CheckInt(EndCol, 0, 'break end col');
    Check(not Buf.InsertRaw(0, 0, '', EndRow, EndCol), 'empty insert = False');
    Check(Buf.TextRange(1, 6, 1, 9) = 'big', 'TextRange in line');
    Check(Buf.TextRange(0, 0, 1, 5) = #10'hello', 'TextRange across');
  finally
    Buf.Free;
  end;
end;

procedure TestUndoTyping;
var
  Buf: TEdBuffer;
  CurRow, CurCol, EndRow, EndCol, CharIdx: Integer;
  Typed: WideString;
begin
  Buf := TEdBuffer.Create;
  try
    Buf.SetText('ab');
    CurRow := 0;
    CurCol := 1;
    Typed := 'xyz';
    // Набор по символу - одна правка
    Buf.BeginGroup;
    for CharIdx := 1 to Length(Typed) do
    begin
      Buf.InsertText(CurRow, CurCol, Typed[CharIdx], True, CurRow, CurCol,
        EndRow, EndCol);
      CurRow := EndRow;
      CurCol := EndCol;
    end;
    CheckText(Buf, 'axyzb', 'typed');
    CheckInt(Buf.UndoCount, 1, 'typing merged into one undo item');
    Check(Buf.Modified, 'typed - modified');
    Check(Buf.Undo(CurRow, CurCol), 'undo typing');
    CheckText(Buf, 'ab', 'undo typing text');
    CheckInt(CurCol, 1, 'undo typing caret col');
    Check(not Buf.Modified, 'undo to saved - not modified');
    Check(Buf.Redo(CurRow, CurCol), 'redo typing');
    CheckText(Buf, 'axyzb', 'redo typing text');
    CheckInt(CurCol, 4, 'redo typing caret');
    Check(Buf.Modified, 'redo - modified again');
    // Перевод строки набором - отдельная правка
    Buf.InsertText(0, 4, #10, True, 0, 4, EndRow, EndCol);
    CheckInt(Buf.UndoCount, 2, 'break is a new undo item');
    Buf.MarkSaved;
    Check(not Buf.Modified, 'MarkSaved');
    Buf.Undo(CurRow, CurCol);
    Check(Buf.Modified, 'undo past saved - modified');
    // Новая правка после отката - записанное состояние не достижимо
    Buf.BeginGroup;
    Buf.InsertText(0, 0, 'q', False, 0, 0, EndRow, EndCol);
    Buf.Undo(CurRow, CurCol);
    Check(Buf.Modified, 'saved state unreachable after new edit');
    Check(not Buf.CanRedo or (Buf.RedoCount = 1), 'redo after undo of q');
  finally
    Buf.Free;
  end;
end;

procedure TestGroupsReplace;
var
  Buf: TEdBuffer;
  CurRow, CurCol, EndRow, EndCol: Integer;
begin
  Buf := TEdBuffer.Create;
  try
    Buf.SetText('one two'#10'three');
    Buf.BeginGroup;
    Buf.DeleteText(0, 3, 0, 7, 0, 7);
    Buf.BeginGroup;
    Buf.InsertText(1, 5, '!', False, 1, 5, EndRow, EndCol);
    CheckText(Buf, 'one'#10'three!', 'two groups');
    Buf.Undo(CurRow, CurCol);
    CheckText(Buf, 'one'#10'three', 'undo second group only');
    CheckInt(CurRow, 1, 'caret row after undo 2');
    CheckInt(CurCol, 5, 'caret col after undo 2');
    Buf.Undo(CurRow, CurCol);
    CheckText(Buf, 'one two'#10'three', 'undo first group');
    CheckInt(CurCol, 7, 'caret col after undo 1');
    // Замена - одна правка для отката
    Buf.ReplaceText(0, 0, 1, 2, 'X'#10'Y', 0, 0, EndRow, EndCol);
    CheckText(Buf, 'X'#10'Yree', 'replace');
    CheckInt(EndRow, 1, 'replace end row');
    CheckInt(EndCol, 1, 'replace end col');
    Buf.Undo(CurRow, CurCol);
    CheckText(Buf, 'one two'#10'three', 'undo replace in one step');
    Buf.Redo(CurRow, CurCol);
    CheckText(Buf, 'X'#10'Yree', 'redo replace');
  finally
    Buf.Free;
  end;
end;

procedure TestIndex;
var
  Buf: TEdBuffer;
  RowIdx, ColIdx: Integer;
  EndRow, EndCol: Integer;
begin
  Buf := TEdBuffer.Create;
  try
    Buf.SetText('ab'#10#10'cde');
    CheckInt(Buf.TextLength, 7, 'TextLength');
    CheckInt(Buf.CharIndex(0, 0), 0, 'index 0,0');
    CheckInt(Buf.CharIndex(0, 2), 2, 'index end of row 0');
    CheckInt(Buf.CharIndex(1, 0), 3, 'index empty row');
    CheckInt(Buf.CharIndex(2, 3), 7, 'index end');
    CheckInt(Buf.CharIndex(0, 99), 2, 'index col clamped');
    Buf.PosOfIndex(3, RowIdx, ColIdx);
    CheckInt(RowIdx, 1, 'pos 3 row');
    CheckInt(ColIdx, 0, 'pos 3 col');
    Buf.PosOfIndex(5, RowIdx, ColIdx);
    CheckInt(RowIdx, 2, 'pos 5 row');
    CheckInt(ColIdx, 1, 'pos 5 col');
    Buf.PosOfIndex(2, RowIdx, ColIdx);
    CheckInt(RowIdx, 0, 'pos 2 row (end of line)');
    CheckInt(ColIdx, 2, 'pos 2 col');
    Buf.PosOfIndex(999, RowIdx, ColIdx);
    CheckInt(RowIdx, 2, 'pos past end row');
    CheckInt(ColIdx, 3, 'pos past end col');
    // После правки вверху - индексы ниже сдвигаются
    Buf.InsertRaw(0, 1, 'XYZ', EndRow, EndCol);
    CheckInt(Buf.CharIndex(2, 0), 7, 'index after edit above');
    Buf.InsertRaw(1, 0, 'q'#10, EndRow, EndCol);
    CheckInt(Buf.CharIndex(3, 1), 10, 'index after line insert');
  finally
    Buf.Free;
  end;
end;

procedure TestLongLine;
var
  Buf: TEdBuffer;
  Long: WideString;
  CharIdx, EndRow, EndCol, RowIdx, ColIdx: Integer;
begin
  Buf := TEdBuffer.Create;
  try
    SetLength(Long, 1000000);
    for CharIdx := 1 to Length(Long) do
      Long[CharIdx] := WideChar(Ord('a') + CharIdx mod 26);
    Buf.SetText('first'#10'last');
    Buf.InsertRaw(1, 0, Long, EndRow, EndCol);
    CheckInt(Buf.Count, 2, 'long: still 2 lines');
    CheckInt(Length(Buf[1]), 1000004, 'long line length');
    CheckInt(EndCol, 1000000, 'long insert end col');
    CheckInt(Buf.CharIndex(1, 1000004), 1000010, 'long index');
    Buf.PosOfIndex(1000010, RowIdx, ColIdx);
    CheckInt(ColIdx, 1000004, 'long pos col');
  finally
    Buf.Free;
  end;
end;

procedure TestListener;
var
  Buf: TEdBuffer;
  Probe: TListenerProbe;
  EndRow, EndCol, OldVersion: Integer;
begin
  Buf := TEdBuffer.Create;
  Probe := TListenerProbe.Create;
  try
    Buf.SetText('a'#10'b'#10'c');
    Buf.AddListener(Probe.OnChange);
    OldVersion := Buf.Version;
    Buf.InsertRaw(1, 1, 'x'#10'y', EndRow, EndCol);
    CheckInt(Probe.CallCount, 1, 'listener called');
    CheckInt(Probe.LastFirst, 1, 'listener first');
    CheckInt(Probe.LastOld, 1, 'listener old count');
    CheckInt(Probe.LastNew, 2, 'listener new count');
    Check(Buf.Version > OldVersion, 'version grows');
    Buf.DeleteRaw(0, 1, 2, 1);
    CheckInt(Probe.LastFirst, 0, 'delete listener first');
    CheckInt(Probe.LastOld, 3, 'delete listener old');
    CheckInt(Probe.LastNew, 1, 'delete listener new');
    Buf.RemoveListener(Probe.OnChange);
    Buf.InsertRaw(0, 0, 'z', EndRow, EndCol);
    CheckInt(Probe.CallCount, 2, 'removed listener not called');
  finally
    Probe.Free;
    Buf.Free;
  end;
end;

// --- Случайная проверка против модели ------------------------------------

procedure TestRandom;
const
  StepCount = 4000;
var
  Buf: TEdBuffer;
  Model, Original, Piece, Removed, Alphabet: WideString;
  Step, Row1, Col1, Row2, Col2, EndRow, EndCol, Index1, Index2, PieceLen,
  CharIdx, CurRow, CurCol, UndoSteps, Swap, RowIdx, ColIdx, CheckIdx: Integer;
  History: array of WideString;
begin
  RandSeed := 20261028;
  // #1046 - Ж (кириллица)
  Alphabet := 'ab c'#10'd' + WideChar(1046) + 'e';
  Buf := TEdBuffer.Create;
  try
    Original := 'start'#10'line two'#10#10'end';
    Buf.SetText(Original);
    Model := Original;
    SetLength(History, 0);
    for Step := 1 to StepCount do
    begin
      SetLength(History, Length(History) + 1);
      History[High(History)] := Model;
      Buf.BeginGroup;
      Row1 := Random(Buf.Count);
      Col1 := Random(Length(Buf[Row1]) + 1);
      if Random(5) < 3 then
      begin
        PieceLen := Random(6) + 1;
        Piece := '';
        for CharIdx := 1 to PieceLen do
          Piece := Piece + Alphabet[Random(Length(Alphabet)) + 1];
        Index1 := ModelIndex(Model, Row1, Col1);
        Buf.InsertText(Row1, Col1, Piece, False, Row1, Col1, EndRow, EndCol);
        Model := Copy(Model, 1, Index1) + Piece +
          Copy(Model, Index1 + 1, MaxInt);
      end
      else
      begin
        // Кусок рядом (текст не схлопывается), изредка - через весь текст
        if Random(400) = 0 then
          Row2 := Random(Buf.Count)
        else
          Row2 := Row1 + Random(2);
        if Row2 >= Buf.Count then
          Row2 := Buf.Count - 1;
        Col2 := Random(Length(Buf[Row2]) + 1);
        if (Row2 < Row1) or ((Row2 = Row1) and (Col2 < Col1)) then
        begin
          Swap := Row1; Row1 := Row2; Row2 := Swap;
          Swap := Col1; Col1 := Col2; Col2 := Swap;
        end;
        Index1 := ModelIndex(Model, Row1, Col1);
        Index2 := ModelIndex(Model, Row2, Col2);
        // Пустой кусок: правки нет, в откат не пишется
        if Index1 = Index2 then
          SetLength(History, Length(History) - 1);
        Removed := Buf.DeleteText(Row1, Col1, Row2, Col2, Row1, Col1);
        Check(Removed = Copy(Model, Index1 + 1, Index2 - Index1),
          'random: removed text, step ' + IntToStr(Step));
        Model := Copy(Model, 1, Index1) + Copy(Model, Index2 + 1, MaxInt);
      end;
      if Buf.GetText(#10) <> Model then
      begin
        CheckText(Buf, Model, 'random: text, step ' + IntToStr(Step));
        Break;
      end;
      // Индексы - выборочно против модели
      if Step mod 50 = 0 then
      begin
        CheckInt(Buf.TextLength, Length(Model), 'random: length');
        for CheckIdx := 1 to 20 do
        begin
          Index1 := Random(Length(Model) + 1);
          Buf.PosOfIndex(Index1, RowIdx, ColIdx);
          CheckInt(Buf.CharIndex(RowIdx, ColIdx), Index1,
            'random: index round trip');
          CheckInt(ModelIndex(Model, RowIdx, ColIdx), Index1,
            'random: index vs model');
        end;
      end;
    end;
    // Откат до начала: на каждом шаге - текст, как был до правки
    UndoSteps := 0;
    while Buf.Undo(CurRow, CurCol) do
    begin
      Inc(UndoSteps);
      if Buf.GetText(#10) <> History[High(History) - UndoSteps + 1] then
      begin
        CheckText(Buf, History[High(History) - UndoSteps + 1],
          'random: undo step ' + IntToStr(UndoSteps));
        Break;
      end;
    end;
    CheckInt(UndoSteps, Length(History), 'random: undo steps');
    Check(Length(History) > StepCount div 2, 'random: most steps edit');
    CheckText(Buf, Original, 'random: back to original');
    Check(not Buf.Modified, 'random: original - not modified');
    // И обратно повтором
    while Buf.Redo(CurRow, CurCol) do
      ;
    CheckText(Buf, Model, 'random: redo all');
    Writeln('random: edits ', Length(History), ', final lines ', Buf.Count,
      ', chars ', Buf.TextLength);
  finally
    Buf.Free;
  end;
end;

begin
  TestSetGetText;
  TestRawEdits;
  TestUndoTyping;
  TestGroupsReplace;
  TestIndex;
  TestLongLine;
  TestListener;
  TestRandom;
  Writeln('EdBuffer: checks ', CheckCount, ', failed ', FailCount);
  if FailCount > 0 then
    Halt(1);
end.
