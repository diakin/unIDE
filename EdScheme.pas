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

// Текст редактора для Unit1 и обратно. Unit1 держит текст редактора в
// строках string в кодировке Windows (CP_ACP), позиция байта = позиция
// символа. В Delphi 7 это и есть string(WideString). Под FPC строки LCL -
// UTF-8, и string(WideString) дал бы UTF-8 (длина другая, A-функции
// рисования показывают его неверно), поэтому перевод - явно через CP_ACP
function EdAnsiText(const AText: WideString): string;
function EdWideText(const AText: string): WideString;
// Текст редактора (CP_ACP) для подписей и подсказок LCL: под FPC - UTF-8,
// в Delphi 7 - как есть
function EdUiText(const AText: string): string;
// Обратно: текст из элемента LCL (UTF-8 под FPC) - в кодировку редактора
// (CP_ACP); в Delphi 7 - как есть
function EdFromUiText(const AText: string): string;

implementation

var
  WideToAnsiMap: array of AnsiChar;

{$IFNDEF MSWINDOWS}
const
  // cp1251, байты $80..$FF -> Unicode ($98 в cp1251 не занят)
  EdCp1251High: array[$80..$FF] of Word = (
    $0402, $0403, $201A, $0453, $201E, $2026, $2020, $2021,
    $20AC, $2030, $0409, $2039, $040A, $040C, $040B, $040F,
    $0452, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $003F, $2122, $0459, $203A, $045A, $045C, $045B, $045F,
    $00A0, $040E, $045E, $0408, $00A4, $0490, $00A6, $00A7,
    $0401, $00A9, $0404, $00AB, $00AC, $00AD, $00AE, $0407,
    $00B0, $00B1, $0406, $0456, $0491, $00B5, $00B6, $00B7,
    $0451, $2116, $0454, $00BB, $0458, $0405, $0455, $0457,
    $0410, $0411, $0412, $0413, $0414, $0415, $0416, $0417,
    $0418, $0419, $041A, $041B, $041C, $041D, $041E, $041F,
    $0420, $0421, $0422, $0423, $0424, $0425, $0426, $0427,
    $0428, $0429, $042A, $042B, $042C, $042D, $042E, $042F,
    $0430, $0431, $0432, $0433, $0434, $0435, $0436, $0437,
    $0438, $0439, $043A, $043B, $043C, $043D, $043E, $043F,
    $0440, $0441, $0442, $0443, $0444, $0445, $0446, $0447,
    $0448, $0449, $044A, $044B, $044C, $044D, $044E, $044F);
{$ENDIF}

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
    WideToAnsiMap[CharCode] := '?';
    {$ENDIF}
  end;
  {$IFNDEF MSWINDOWS}
  // Не Windows: строки редактора - в cp1251, как в Windows с русской
  // кодовой страницей
  for CharCode := $80 to $FF do
    if EdCp1251High[CharCode] <> $3F then
      WideToAnsiMap[EdCp1251High[CharCode]] := AnsiChar(CharCode);
  {$ENDIF}
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

function EdAnsiText(const AText: WideString): string;
begin
  {$IFDEF FPC}
  Result := EdAnsiLine(AText);
  {$ELSE}
  Result := string(AText);
  {$ENDIF}
end;

function EdUiText(const AText: string): string;
begin
  {$IFDEF FPC}
  Result := UTF8Encode(EdWideText(AText));
  {$ELSE}
  Result := AText;
  {$ENDIF}
end;

function EdFromUiText(const AText: string): string;
begin
  {$IFDEF FPC}
  Result := EdAnsiText(UTF8Decode(AText));
  {$ELSE}
  Result := AText;
  {$ENDIF}
end;

function EdWideText(const AText: string): WideString;
{$IFDEF FPC}
var
{$IFDEF MSWINDOWS}
  WideLen: Integer;
{$ELSE}
  CharIdx: Integer;
{$ENDIF}
{$ENDIF}
begin
  {$IFDEF FPC}
  {$IFDEF MSWINDOWS}
  Result := '';
  if AText = '' then
    Exit;
  WideLen := MultiByteToWideChar(CP_ACP, 0, PAnsiChar(AText), Length(AText),
    nil, 0);
  SetLength(Result, WideLen);
  if WideLen > 0 then
    MultiByteToWideChar(CP_ACP, 0, PAnsiChar(AText), Length(AText),
      PWideChar(Result), WideLen);
  {$ELSE}
  SetLength(Result, Length(AText));
  for CharIdx := 1 to Length(AText) do
    if Ord(AText[CharIdx]) < $80 then
      Result[CharIdx] := WideChar(Ord(AText[CharIdx]))
    else
      Result[CharIdx] := WideChar(EdCp1251High[Ord(AText[CharIdx])]);
  {$ENDIF}
  {$ELSE}
  Result := WideString(AText);
  {$ENDIF}
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
