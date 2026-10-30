unit EdLog;

// ---------------------------------------------------------------------------
//  Окно лога на своём редакторе (план портирования, шаг 0.7.6): TEdView
//  только для чтения, строки дописываются в конец, у каждой строки свой
//  цвет. Замена окнам логов TRichEdit (Compilation, Error, HiLite, Runtime,
//  Git log) - без RTF и сообщений EM_*.
//
//  Текст - в своём TEdBuffer, без отката. Последняя строка буфера всегда
//  пустая: каждая запись лога кончается переводом строки, как в RichEdit
//  (LogTo), поэтому строк лога - Count - 1.
//
//  Выделение мышью и клавишами, Ctrl+C, Ctrl+A - как у TEdView; правки нет.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  SysUtils, Classes, Graphics, Controls, EdBuffer, EdView;

type
  TEdLogView = class(TEdView)
  private
    FLogBuffer: TEdBuffer;
    FColors: array of TColor;   // цвет строки лога; clNone - цвет текста окна
    procedure LogLineRuns(Sender: TObject; ARow: Integer;
      const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
    function GetLogCount: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Строка в конец лога цветом AColor (clNone - цвет текста окна); окно
    // прокручивается к концу
    procedure AddLine(const AText: WideString; AColor: TColor);
    // Убрать первые ACount строк (лог длиннее предела)
    procedure DeleteFirst(ACount: Integer);
    procedure ClearLog;
    // Строка лога ARow (с 0)
    function LogLine(ARow: Integer): WideString;
    // Весь текст, строки через #13#10 (с переводом строки в конце)
    function LogText: WideString;
    property LogCount: Integer read GetLogCount;
  end;

implementation

constructor TEdLogView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLogBuffer := TEdBuffer.Create;
  ReadOnly := True;
  ShowGutter := False;
  OnLineRuns := LogLineRuns;
  Buffer := FLogBuffer;
end;

destructor TEdLogView.Destroy;
begin
  Buffer := nil;
  FLogBuffer.Free;
  inherited Destroy;
end;

function TEdLogView.GetLogCount: Integer;
begin
  Result := FLogBuffer.Count - 1;
end;

procedure TEdLogView.AddLine(const AText: WideString; AColor: TColor);
var
  Row, EndRow, EndCol, CharIdx: Integer;
  Clean: WideString;
begin
  // Перевод строки внутри записи разорвал бы её - как в LogTo
  Clean := AText;
  for CharIdx := 1 to Length(Clean) do
    if (Clean[CharIdx] = #13) or (Clean[CharIdx] = #10) then
      Clean[CharIdx] := ' ';
  Row := FLogBuffer.Count - 1;
  if Length(FColors) < Row + 1 then
    SetLength(FColors, (Row + 1) * 2 + 16);
  FColors[Row] := AColor;
  // Перевод строки в буфере - #10 (InsertRaw)
  FLogBuffer.InsertRaw(Row, 0, Clean + #10, EndRow, EndCol);
  ScrollTo(FLogBuffer.Count - VisibleRows, 0);
end;

procedure TEdLogView.DeleteFirst(ACount: Integer);
var
  Total: Integer;
begin
  Total := LogCount;
  if ACount > Total then
    ACount := Total;
  if ACount <= 0 then
    Exit;
  FLogBuffer.DeleteRaw(0, 0, ACount, 0);
  Move(FColors[ACount], FColors[0], (Total - ACount) * SizeOf(TColor));
end;

procedure TEdLogView.ClearLog;
begin
  FLogBuffer.SetText('');
  SetLength(FColors, 0);
end;

function TEdLogView.LogLine(ARow: Integer): WideString;
begin
  if (ARow >= 0) and (ARow < LogCount) then
    Result := FLogBuffer[ARow]
  else
    Result := '';
end;

function TEdLogView.LogText: WideString;
begin
  Result := FLogBuffer.GetText(#13#10);
end;

procedure TEdLogView.LogLineRuns(Sender: TObject; ARow: Integer;
  const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
begin
  ACount := 0;
  if (ARow < 0) or (ARow >= LogCount) or (ARow > High(FColors)) or
     (FColors[ARow] = clNone) then
    Exit;
  if Length(ARuns) < 1 then
    SetLength(ARuns, 4);
  ARuns[0].Start := 0;
  ARuns[0].Len := Length(ALine);
  ARuns[0].Fore := FColors[ARow];
  ARuns[0].Back := clNone;
  ARuns[0].Style := [];
  ACount := 1;
end;

end.
