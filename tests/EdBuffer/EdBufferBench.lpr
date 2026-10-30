program EdBufferBench;

// ---------------------------------------------------------------------------
//  Замеры EdBuffer на файле (CP1251 / ANSI): загрузка, чтение строк,
//  сквозной индекс, весь текст, набор, Enter, откат.
//
//    fpc -O2 -Mdelphi -Fu..\.. EdBufferBench.lpr      (Linux: -Fu../..)
//    EdBufferBench ..\..\Unit1.pas
// ---------------------------------------------------------------------------

{$APPTYPE CONSOLE}
{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

uses
  SysUtils, DateUtils,
  EdBuffer in '..\..\EdBuffer.pas';

const
  ReadCount = 200000;
  TypeCount = 10000;
  EnterCount = 2000;

var
  StartTime: TDateTime;

function Elapsed: Double;
begin
  Result := MilliSecondSpan(Now, StartTime);
end;

procedure Report(const AName: string; AMs: Double; ACount: Integer);
begin
  if ACount > 1 then
    WriteLn(Format('%-28s %10.2f ms  %8.3f us/op', [AName, AMs, AMs * 1000 / ACount]))
  else
    WriteLn(Format('%-28s %10.2f ms', [AName, AMs]));
end;

var
  InFile: File;
  AnsiText: AnsiString;
  WideText, LineText: WideString;
  Buf: TEdBuffer;
  HeapBefore: PtrUInt;
  Idx, Row, EndRow, EndCol, CurRow, CurCol, LineCount: Integer;
  Sum: Int64;
begin
  AssignFile(InFile, ParamStr(1));
  Reset(InFile, 1);
  SetLength(AnsiText, FileSize(InFile));
  BlockRead(InFile, AnsiText[1], Length(AnsiText));
  CloseFile(InFile);
  WideText := WideString(AnsiText);
  AnsiText := '';
  RandSeed := 1;
  HeapBefore := GetFPCHeapStatus.CurrHeapUsed;
  StartTime := Now;
  Buf := TEdBuffer.Create;
  Buf.SetText(WideText);
  Report('SetText', Elapsed, 1);
  WideText := '';
  WriteLn(Format('  lines %d, heap %.1f MB', [Buf.Count,
    (GetFPCHeapStatus.CurrHeapUsed - HeapBefore) / 1048576]));
  LineCount := Buf.Count;
  Sum := 0;
  StartTime := Now;
  for Idx := 0 to LineCount - 1 do
    Inc(Sum, Length(Buf[Idx]));
  Report('read all lines in order', Elapsed, LineCount);
  StartTime := Now;
  for Idx := 1 to ReadCount do
    Inc(Sum, Length(Buf[Random(LineCount)]));
  Report('read random line', Elapsed, ReadCount);
  Row := LineCount div 2;
  StartTime := Now;
  for Idx := 1 to ReadCount do
    Inc(Sum, Length(Buf[Row + Idx mod 50]));
  Report('read screen (50 lines)', Elapsed, ReadCount);
  StartTime := Now;
  for Idx := 1 to ReadCount do
    Inc(Sum, Buf.CharIndex(Random(LineCount), 3));
  Report('CharIndex random', Elapsed, ReadCount);
  StartTime := Now;
  for Idx := 1 to 10 do
    LineText := Buf.GetText(#13#10);
  Report('GetText CRLF', Elapsed / 10, 1);
  CurRow := LineCount div 2;
  CurCol := 0;
  StartTime := Now;
  for Idx := 1 to TypeCount do
  begin
    Buf.InsertText(CurRow, CurCol, 'a', True, CurRow, CurCol, EndRow, EndCol);
    CurRow := EndRow;
    CurCol := EndCol;
    if Idx mod 40 = 0 then
    begin
      Buf.BeginGroup;
      CurRow := Random(Buf.Count);
      CurCol := 0;
    end;
    // строка для экрана после ввода
    Inc(Sum, Length(Buf[CurRow]));
  end;
  Report('type char + read line', Elapsed, TypeCount);
  StartTime := Now;
  for Idx := 1 to EnterCount do
  begin
    Row := Random(Buf.Count);
    Buf.BeginGroup;
    Buf.InsertText(Row, Buf.LineLength(Row) div 2, #10, False, Row, 0,
      EndRow, EndCol);
  end;
  Report('Enter at random line', Elapsed, EnterCount);
  StartTime := Now;
  for Idx := 1 to TypeCount do
  begin
    Buf.InsertRaw(CurRow, CurCol, 'b', EndRow, EndCol);
    CurCol := EndCol;
    if Idx mod 40 = 0 then
    begin
      CurRow := Random(Buf.Count);
      CurCol := 0;
    end;
  end;
  Report('type char raw', Elapsed, TypeCount);
  StartTime := Now;
  while Buf.Undo(CurRow, CurCol) do
    ;
  Report('undo all', Elapsed, 1);
  Buf.Free;
  if Sum = 0 then
    WriteLn;
end.
