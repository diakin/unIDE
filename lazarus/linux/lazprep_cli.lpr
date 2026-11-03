program lazprep_cli;

// ---------------------------------------------------------------------------
//  unIDE: source preparation for a Lazarus build without the unIDE window
//  (same as Utils - "Lazarus: prepare sources" in unIDE, LazPrep.pas):
//  copy of the sources in UTF-8, .dfm -> .lfm, .dpr -> .lpr, templates
//  from lazarus\. Used by build_linux.sh (plan stage 7).
//
//  LazPrep.pas is CP1251: build_linux.sh converts it to UTF-8 before
//  compiling this program, so the log is readable in a UTF-8 terminal.
//
//  Usage: lazprep_cli <folder with SyntaxHLClaude.dpr> <output folder>
//  Exit code: 0 - done, 1 - some files failed, 2 - wrong parameters.
// ---------------------------------------------------------------------------

{$mode delphi}{$H+}

uses
  SysUtils, Classes, LazPrep;

var
  Log: TStringList;
  Stats: TLazPrepStats;
  LineIdx: Integer;
  Done: Boolean;
begin
  if ParamCount < 2 then
  begin
    Writeln('usage: lazprep_cli <source folder> <output folder>');
    Halt(2);
  end;
  Log := TStringList.Create;
  try
    Done := LazPrepSources(ExpandFileName(ParamStr(1)),
                           ExpandFileName(ParamStr(2)), Log, Stats);
    for LineIdx := 0 to Log.Count - 1 do
      Writeln(Log[LineIdx]);
    Writeln(Format('lazprep: converted %d, copied %d, unchanged %d, ' +
                   'failed %d, forms %d', [Stats.Converted, Stats.Copied,
                   Stats.Unchanged, Stats.Failed, Stats.Forms]));
    if not Done then
      Halt(1);
  finally
    Log.Free;
  end;
end.
