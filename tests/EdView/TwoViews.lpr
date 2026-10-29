program TwoViews;

// Два TEdView на один TEdBuffer (шаг 0.7.5): правка в одном видна в другом,
// второй только для чтения и в режиме «только щелчок» (OnTextClick),
// подсветка на общем буфере, освобождение в порядке Unit1 / SplitPane.

{$MODE DELPHI}

uses
  Interfaces, SysUtils, Classes, Graphics, Controls, Forms,
  EdBuffer, EdView, EdScheme;

type
  THost = class
    ClickRow, ClickCol, Clicks: Integer;
    procedure TextClick(Sender: TObject; ARow, ACol: Integer);
  end;

procedure THost.TextClick(Sender: TObject; ARow, ACol: Integer);
begin
  ClickRow := ARow;
  ClickCol := ACol;
  Inc(Clicks);
end;

type
  TTestView = class(TEdView);

var
  Form: TForm;
  Buffer: TEdBuffer;
  MainView, PaneView: TEdView;
  High: TEdSchemeHighlighter;
  Host: THost;
  Fails: Integer;

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

var
  RowIdx: Integer;
  Text: WideString;
begin
  Application.Initialize;
  Form := TForm.CreateNew(nil);
  Form.SetBounds(0, 0, 800, 400);
  Text := '';
  for RowIdx := 1 to 300 do
    Text := Text + 'line ' + WideString(IntToStr(RowIdx)) + #13#10;
  Buffer := TEdBuffer.Create;
  Buffer.SetText(Text);
  MainView := TEdView.Create(Form);
  MainView.Parent := Form;
  MainView.SetBounds(0, 0, 400, 400);
  MainView.Buffer := Buffer;
  PaneView := TEdView.Create(nil);
  PaneView.Parent := Form;
  PaneView.SetBounds(400, 0, 400, 400);
  PaneView.ReadOnly := True;
  Host := THost.Create;
  PaneView.OnTextClick := Host.TextClick;
  High := TEdSchemeHighlighter.Create(Buffer, nil, clBlack, clWhite);
  PaneView.OnLineRuns := High.LineRuns;
  PaneView.Buffer := Buffer;
  Form.Show;
  Application.ProcessMessages;
  PaneView.ScrollTo(200, 0);

  MainView.CaretTo(0, 0);
  MainView.InsertText('ABC', True);
  Check('pane sees edit', PaneView.Buffer.Lines[0] = 'ABCline 1');
  MainView.CaretTo(250, 4);
  MainView.InsertText('long long long long long long long long long long ' +
    'long long long long long long long long long long long long', False);
  Application.ProcessMessages;
  Check('pane top kept (' + IntToStr(PaneView.TopRow) + ')',
    PaneView.TopRow = 200);
  PaneView.InsertText('X', True);
  Check('pane read-only', Buffer.Lines[0] = 'ABCline 1');
  MainView.Undo;
  MainView.Undo;
  Check('undo from main seen in pane', PaneView.Buffer.Lines[0] = 'line 1');

  TTestView(PaneView).MouseDown(mbLeft, [], PaneView.GutterWidth +
    PaneView.CharW * 2 + 1, PaneView.LineH * 3 + 1);
  Check('pane click reported row ' + IntToStr(Host.ClickRow) + ' col ' +
    IntToStr(Host.ClickCol), (Host.Clicks = 1) and (Host.ClickRow = 203) and
    (Host.ClickCol = 2));
  Check('pane click left no selection', not PaneView.HasSelection);
  TTestView(PaneView).MouseUp(mbLeft, [], 10, 10);

  // Порядок Unit1: панель отпускает буфер, потом буфер освобождается
  PaneView.Buffer := nil;
  FreeAndNil(High);
  FreeAndNil(PaneView);
  MainView.CaretTo(250, 0);
  MainView.InsertText('after', True);
  Check('main still edits after pane freed', Pos('after', Buffer.Lines[250]) = 1);
  MainView.Buffer := nil;
  Buffer.Free;
  Form.Free;
  Writeln('failures ', Fails);
end.
