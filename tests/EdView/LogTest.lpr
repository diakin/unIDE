program LogTest;

// TEdLogView (шаг 0.7.6): строки в конец с цветом, срез начала, очистка,
// текст целиком, прокрутка к концу (Lazarus, Linux, Xvfb).

{$MODE DELPHI}

uses
  Interfaces, SysUtils, Classes, Graphics, Controls, Forms, EdView, EdLog;

var
  Form: TForm;
  Log: TEdLogView;
  Fails, LineNo: Integer;
  Runs: TEdRuns;
  RunCount: Integer;

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

begin
  Application.Initialize;
  Form := TForm.CreateNew(nil);
  Form.SetBounds(0, 0, 600, 200);
  Log := TEdLogView.Create(Form);
  Log.Parent := Form;
  Log.Align := alClient;
  Form.Show;
  Application.ProcessMessages;

  Check('empty', (Log.LogCount = 0) and (Log.LogText = ''));
  Log.AddLine('first', clNone);
  Log.AddLine('second'#13#10'broken', clRed);
  Log.AddLine('', clNone);
  Check('count 3 (' + IntToStr(Log.LogCount) + ')', Log.LogCount = 3);
  Check('line 1 joined', Log.LogLine(1) = 'second  broken');
  Check('text', Log.LogText = 'first'#13#10'second  broken'#13#10#13#10);
  RunCount := 0;
  Log.OnLineRuns(Log, 1, Log.LogLine(1), Runs, RunCount);
  Check('red run', (RunCount = 1) and (Runs[0].Fore = clRed) and
    (Runs[0].Len = Length('second  broken')));
  RunCount := 5;
  Log.OnLineRuns(Log, 0, Log.LogLine(0), Runs, RunCount);
  Check('default color - no run', RunCount = 0);

  for LineNo := 1 to 200 do
    Log.AddLine('line ' + IntToStr(LineNo), clBlue);
  Application.ProcessMessages;
  Check('scrolled to end (top ' + IntToStr(Log.TopRow) + ')',
    Log.TopRow + Log.VisibleRows >= Log.Buffer.Count - 1);
  Log.DeleteFirst(3);
  Check('delete first 3', (Log.LogCount = 200) and (Log.LogLine(0) = 'line 1'));
  RunCount := 0;
  Log.OnLineRuns(Log, 0, Log.LogLine(0), Runs, RunCount);
  Check('colors shifted', (RunCount = 1) and (Runs[0].Fore = clBlue));
  Log.SelectAll;
  Check('select all', Log.HasSelection);
  Log.InsertText('typed', False);
  Check('read only', Log.LogLine(0) = 'line 1');
  Log.ClearLog;
  Check('clear', (Log.LogCount = 0) and (Log.LogText = ''));
  Log.AddLine('after clear', clGreen);
  Check('add after clear', (Log.LogCount = 1) and (Log.LogLine(0) = 'after clear'));
  Form.Free;
  Writeln('failures ', Fails);
end.
