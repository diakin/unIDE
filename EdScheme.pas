unit EdScheme;

// ---------------------------------------------------------------------------
//  Подсветка для окна TEdView по цветовой схеме (.clr): куски строки -
//  TSchemeColorizer (SchemeLine), как у редактора F4 unIDE FAR.
//
//  Состояние «открыт блочный комментарий» в начале каждой строки хранится;
//  после правки буфера оно пересчитывается от места правки вниз и только по
//  мере надобности (до строк, которые рисуются). Строка разбирается в
//  кодировке Windows (cp1251), как её читает схема.
//
//  Это подсветка текста по схеме - без отметок строк, имён компонентов и
//  пар скобок основного редактора unIDE (их окно получит на шаге 0.7.4).
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  {$IFDEF MSWINDOWS}Windows,{$ENDIF}
  SysUtils, Classes, Graphics, ClrScheme, SchemeLine, EdBuffer, EdView;

type
  TEdSchemeHighlighter = class
  private
    FBuffer: TEdBuffer;
    FScheme: TClrScheme;
    FColorizer: TSchemeColorizer;
    FStates: array of Integer;     // состояние в начале строки
    FStatesValid: Integer;         // верны FStates[0 .. FStatesValid - 1]
    FSchemeRuns: TSchemeRuns;
    procedure BufferChanged(Sender: TObject; AFirst, AOldCount,
      ANewCount: Integer);
    function LineState(ARow: Integer): Integer;
    function GetTextColor: TColor;
    function GetBackColor: TColor;
  public
    // AScheme переходит подсветке (nil - без подсветки: цвета ADefFg /
    // ADefBg). Буфер не принадлежит подсветке
    constructor Create(ABuffer: TEdBuffer; AScheme: TClrScheme;
      ADefFg, ADefBg: TColor);
    destructor Destroy; override;
    // Обработчик TEdView.OnLineRuns
    procedure LineRuns(Sender: TObject; ARow: Integer;
      const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
    // Цвет текста и фона схемы (для TEdView.TextColor / BackColor)
    property TextColor: TColor read GetTextColor;
    property BackColor: TColor read GetBackColor;
    property Scheme: TClrScheme read FScheme;
  end;

// Строка для разбора схемой: символ Unicode -> байт кодировки Windows
// ('?' - такого символа в ней нет). Длина та же
function EdAnsiLine(const ALine: WideString): string;

implementation

var
  WideToAnsiMap: array of AnsiChar;

procedure BuildWideToAnsiMap;
var
  CharCode: Integer;
  {$IFDEF MSWINDOWS}
  WideCh: WideChar;
  AnsiCh: AnsiChar;
  UsedDefault: BOOL;
  {$ENDIF}
begin
  SetLength(WideToAnsiMap, 65536);
  for CharCode := 0 to 127 do
    WideToAnsiMap[CharCode] := AnsiChar(CharCode);
  for CharCode := 128 to 65535 do
  begin
    {$IFDEF MSWINDOWS}
    WideCh := WideChar(CharCode);
    AnsiCh := '?';
    UsedDefault := False;
    if (WideCharToMultiByte(CP_ACP, $400 {WC_NO_BEST_FIT_CHARS}, @WideCh, 1,
       @AnsiCh, 1, nil, @UsedDefault) <> 1) or UsedDefault then
      AnsiCh := '?';
    WideToAnsiMap[CharCode] := AnsiCh;
    {$ELSE}
    // Не Windows: кириллица - как в cp1251, остальное - '?'
    if (CharCode >= $0410) and (CharCode <= $044F) then
      WideToAnsiMap[CharCode] := AnsiChar(CharCode - $0410 + $C0)
    else if CharCode = $0401 then
      WideToAnsiMap[CharCode] := AnsiChar($A8)
    else if CharCode = $0451 then
      WideToAnsiMap[CharCode] := AnsiChar($B8)
    else
      WideToAnsiMap[CharCode] := '?';
    {$ENDIF}
  end;
end;

function EdAnsiLine(const ALine: WideString): string;
var
  CharIdx: Integer;
begin
  if WideToAnsiMap = nil then
    BuildWideToAnsiMap;
  SetLength(Result, Length(ALine));
  for CharIdx := 1 to Length(ALine) do
    Result[CharIdx] := WideToAnsiMap[Ord(ALine[CharIdx])];
end;

// ---------------------------------------------------------------------------

constructor TEdSchemeHighlighter.Create(ABuffer: TEdBuffer;
  AScheme: TClrScheme; ADefFg, ADefBg: TColor);
begin
  inherited Create;
  FBuffer := ABuffer;
  FScheme := AScheme;
  FColorizer := TSchemeColorizer.Create(FScheme, ADefFg, ADefBg);
  FStatesValid := 0;
  if FBuffer <> nil then
    FBuffer.AddListener(BufferChanged);
end;

destructor TEdSchemeHighlighter.Destroy;
begin
  if FBuffer <> nil then
    FBuffer.RemoveListener(BufferChanged);
  FColorizer.Free;
  FScheme.Free;
  inherited Destroy;
end;

function TEdSchemeHighlighter.GetTextColor: TColor;
begin
  Result := FColorizer.TextFg;
end;

function TEdSchemeHighlighter.GetBackColor: TColor;
begin
  Result := FColorizer.PageBg;
end;

// Состояние в начале строки AFirst не меняется (оно - от строк выше),
// меняется у следующих
procedure TEdSchemeHighlighter.BufferChanged(Sender: TObject; AFirst,
  AOldCount, ANewCount: Integer);
begin
  if FStatesValid > AFirst + 1 then
    FStatesValid := AFirst + 1;
  if FStatesValid < 0 then
    FStatesValid := 0;
end;

function TEdSchemeHighlighter.LineState(ARow: Integer): Integer;
var
  State, RunCount, RowIdx: Integer;
begin
  Result := -1;
  if (FBuffer = nil) or (ARow <= 0) then
    Exit;
  if ARow >= FBuffer.Count then
    ARow := FBuffer.Count - 1;
  if Length(FStates) < FBuffer.Count then
    SetLength(FStates, FBuffer.Count + 64);
  if FStatesValid = 0 then
  begin
    FStates[0] := -1;
    FStatesValid := 1;
  end;
  while FStatesValid <= ARow do
  begin
    RowIdx := FStatesValid - 1;
    State := FStates[RowIdx];
    FColorizer.ColorLine(EdAnsiLine(FBuffer[RowIdx]), State, FSchemeRuns,
      RunCount);
    FStates[FStatesValid] := State;
    Inc(FStatesValid);
  end;
  Result := FStates[ARow];
end;

procedure TEdSchemeHighlighter.LineRuns(Sender: TObject; ARow: Integer;
  const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
var
  State, RunCount, RunIdx: Integer;
begin
  ACount := 0;
  State := LineState(ARow);
  FColorizer.ColorLine(EdAnsiLine(ALine), State, FSchemeRuns, RunCount);
  if Length(ARuns) < RunCount then
    SetLength(ARuns, RunCount + 16);
  for RunIdx := 0 to RunCount - 1 do
  begin
    // Куски схемы - с 1, окна - с 0; clNone / clDefault - цвета окна
    ARuns[ACount].Start := FSchemeRuns[RunIdx].Start - 1;
    ARuns[ACount].Len := FSchemeRuns[RunIdx].Len;
    ARuns[ACount].Fore := FSchemeRuns[RunIdx].Fg;
    if ARuns[ACount].Fore = clDefault then
      ARuns[ACount].Fore := clNone;
    ARuns[ACount].Back := FSchemeRuns[RunIdx].Bg;
    if (ARuns[ACount].Back = clDefault) or
       (ARuns[ACount].Back = FColorizer.PageBg) then
      ARuns[ACount].Back := clNone;
    ARuns[ACount].Style := [];
    Inc(ACount);
  end;
end;

end.
