program RowsTest;

// TEdRowsView (шаг 0.7.6, часть 2): строки TSchemeRows - колонка слева,
// вводный кусок, подложка и дополнение пробелами, без подсветки, строки с
// ошибкой и текущая (Lazarus, Linux, Xvfb).

{$MODE DELPHI}

uses
  Interfaces, SysUtils, Classes, Graphics, Controls, Forms, ClrScheme,
  SchemeRtf, EdView, EdRows;

var
  Form: TForm;
  View: TEdRowsView;
  Rows: TSchemeRows;
  Runs: TEdRuns;
  RunCount, Fails: Integer;
  Marks: TList;
  Back, Fore: TColor;

procedure Check(const AWhat: string; AOk: Boolean);
begin
  if AOk then
    Writeln('ok   ', AWhat)
  else
  begin
    Inc(Fails);
    Writeln('FAIL ', AWhat);
  end;
end;

procedure SetRow(AIdx: Integer; const APrefix, ALead, AText: string;
  APrefixBg, ARowBg: TColor; APad: Integer; AHighlight: Boolean);
begin
  Rows[AIdx].Prefix := APrefix;
  Rows[AIdx].PrefixFg := clGray;
  Rows[AIdx].PrefixBg := APrefixBg;
  Rows[AIdx].Lead := ALead;
  Rows[AIdx].Text := AText;
  Rows[AIdx].Highlight := AHighlight;
  Rows[AIdx].TextFg := clMaroon;
  Rows[AIdx].RowBg := ARowBg;
  Rows[AIdx].PadTo := APad;
  Rows[AIdx].ResetBlock := False;
end;

begin
  Application.Initialize;
  Form := TForm.CreateNew(nil);
  Form.SetBounds(0, 0, 600, 300);
  View := TEdRowsView.Create(Form);
  View.Parent := Form;
  View.Align := alClient;
  Form.Show;
  Application.ProcessMessages;

  SetLength(Rows, 3);
  SetRow(0, '  12   12 ', '+ ', 'begin', clGreen, clLime, 10, True);
  SetRow(1, '          ', '', 'diff --git a b', clNone, clNone, 0, False);
  SetRow(2, '', '', 'x := 1;', clNone, clNone, 0, True);
  View.ShowRows(Rows, nil, clBlack, clWhite);
  Check('3 rows', View.Buffer.Count = 3);
  Check('row 0 text padded', View.Buffer[0] = '  12   12 + begin     ');
  RunCount := 0;
  View.OnLineRuns(View, 0, View.Buffer[0], Runs, RunCount);
  // Без схемы текст строки - её цветом (TextFg), вводный кусок и
  // дополнение - цветом текста окна; подложка у всех трёх - строки
  Check('row 0 runs: prefix gray on green, rest on lime (' +
    IntToStr(RunCount) + ')', (RunCount = 4) and (Runs[0].Len = 10) and
    (Runs[0].Back = clGreen) and (Runs[0].Fore = clGray) and
    (Runs[1].Start = 10) and (Runs[1].Back = clLime) and
    (Runs[2].Fore = clMaroon) and (Runs[2].Back = clLime) and
    (Runs[3].Len = 5) and (Runs[3].Back = clLime));
  RunCount := 0;
  View.OnLineRuns(View, 1, View.Buffer[1], Runs, RunCount);
  Check('row 1 not highlighted: text color', (RunCount = 2) and
    (Runs[1].Fore = clMaroon) and (Runs[1].Back = clWhite));

  Marks := TList.Create;
  Marks.Add(Pointer(2));
  View.ShowRows(Rows, nil, clBlack, clWhite, Marks, 3);
  Back := clNone;
  Fore := clNone;
  View.OnRowStyle(View, 1, Back, Fore);
  Check('marked row: own back and fore', (Back <> clNone) and (Fore <> clNone));
  RunCount := 0;
  View.OnLineRuns(View, 1, View.Buffer[1], Runs, RunCount);
  Check('marked row bold', (RunCount > 0) and (fsBold in Runs[RunCount - 1].Style));
  Back := clNone;
  Fore := clNone;
  View.OnRowStyle(View, 2, Back, Fore);
  Check('current row: back only', (Back <> clNone) and (Fore = clNone));
  Back := clNone;
  View.OnRowStyle(View, 0, Back, Fore);
  Check('plain row: no style', Back = clNone);
  Marks.Free;

  View.ShowPlain('one'#13#10'two', clRed, clYellow);
  Check('plain text', (View.Buffer.Count = 2) and (View.Buffer[1] = 'two') and
    (View.BackColor = clYellow));
  RunCount := 5;
  View.OnLineRuns(View, 0, View.Buffer[0], Runs, RunCount);
  Check('plain: no runs', RunCount = 0);

  Rows := SchemeTextRows('a'#13#10'b'#13#10);
  Check('SchemeTextRows', (Length(Rows) = 2) and (Rows[1].Text = 'b') and
    Rows[0].Highlight);
  View.InsertText('zz', False);
  Check('read only', View.Buffer[0] = 'one');
  Form.Free;
  Writeln('failures ', Fails);
end.
