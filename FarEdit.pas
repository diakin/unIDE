unit FarEdit;

// ---------------------------------------------------------------------------
//  Текст редактора unIDE FAR (F4) - без окна: строки, каретка, выделение,
//  откат, чтение и запись файла, подсветка по схеме. Рисует и принимает
//  клавиши TFarView (UnFar): там же диалоги и строка состояния.
//
//  - Строки - WideString; позиция - строка (с 0) и символ в строке (с 0).
//    Колонка экрана - с раскрытыми табуляциями (шаг TabSize);
//  - кодировка файла определяется при чтении: BOM UTF-8, BOM UTF-16 LE,
//    верный UTF-8 без BOM, иначе - кодировка Windows (CP_ACP). Запись - в
//    той же кодировке, с теми же переводами строк (CRLF / LF / CR) и с
//    переводом в конце файла, если он был;
//  - строки и откат - в TEdBuffer (EdBuffer.pas, общий с основным
//    редактором unIDE по плану портирования): каждая правка - вставка или
//    удаление куска текста (перевод строки внутри куска - #10). Правки
//    одного действия (набор поверх выделения, вставка) - одна группа:
//    Ctrl+Z откатывает её целиком. Набор подряд в одной строке - одна
//    правка;
//  - подсветка: TSchemeColorizer (SchemeLine) по строке в кодировке
//    Windows; состояние «открыт блочный комментарий» в начале каждой
//    строки - в FStates, после правки пересчитывается от неё вниз и только
//    по мере надобности (до видимых строк).
// ---------------------------------------------------------------------------

// Free Pascal (uniFAR): исходник в кодировке Windows-1251 - строки с
// кириллицей в WideString без кракозябр. Delphi 7 эту строку пропускает
{$IFDEF FPC}{$CODEPAGE CP1251}{$ENDIF}

interface

uses
  Windows, SysUtils, Classes, ClrScheme, SchemeLine, EdBuffer;

type
  TFarEditLines = TEdLines;

  TFarEditEncoding = (feAnsi, feUtf8, feUtf8Bom, feUtf16);

  TFarEditor = class
  private
    FBuffer: TEdBuffer;
    FFileName: WideString;
    FEncoding: TFarEditEncoding;
    FLineBreak: WideString;
    FFinalBreak: Boolean;
    FSavedEncoding: TFarEditEncoding; // в какой кодировке файл на диске
    FRow: Integer;
    FCol: Integer;
    FPrefCol: Integer;       // колонка экрана для движения вверх-вниз
    FTopRow: Integer;
    FLeftCol: Integer;
    FSelActive: Boolean;
    FSelRow: Integer;        // второй конец выделения (первый - каретка)
    FSelCol: Integer;
    FTabSize: Integer;
    FScheme: TClrScheme;
    FColorizer: TSchemeColorizer;
    FStates: array of Integer;
    FStatesValid: Integer;
    procedure LinesChanged(AFromRow: Integer);
    procedure BufferChanged(Sender: TObject; AFirst, AOldCount,
      ANewCount: Integer);
    // Удалить кусок с откатом; каретка - в его начало
    procedure DeleteRange(ARow1, ACol1, ARow2, ACol2: Integer);
    function GetLine(AIndex: Integer): WideString;
    function GetCount: Integer;
    function GetModified: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromFile(const AFileName: WideString;
      var AError: string): Boolean;
    // AEncoding - в какой кодировке записать; ALossy - в кодировке Windows
    // не все символы есть (запись не делается, если AAllowLossy = False)
    function SaveToFile(const AFileName: WideString;
      AEncoding: TFarEditEncoding; AAllowLossy: Boolean; var ALossy: Boolean;
      var AError: string): Boolean;
    // Схема подсветки (забирает объект; nil - без подсветки)
    procedure SetScheme(AScheme: TClrScheme; ADefFg, ADefBg: Integer);
    // Строка для разбора схемой - в кодировке Windows ('?' вместо
    // отсутствующих символов; длина - та же)
    function AnsiLine(ARow: Integer): string;
    // Состояние разбора в начале строки (открытый блочный комментарий)
    function LineState(ARow: Integer): Integer;
    // Колонка экрана символа ACol строки ARow (табуляции раскрыты) и
    // обратно - символ под колонкой экрана
    function ScreenCol(ARow, ACol: Integer): Integer;
    function ColAtScreen(ARow, AScreenCol: Integer): Integer;
    // Выделение: упорядоченные концы. False - выделения нет
    function SelRange(var ARow1, ACol1, ARow2, ACol2: Integer): Boolean;
    function SelectedText: WideString;
    function HasSelection: Boolean;
    procedure SelectAll;
    procedure ClearSelection;
    // Каретку в (ARow, ACol); ASelect - выделение от прежнего места
    // (или продолжить начатое). AKeepPref - не менять колонку для
    // движения вверх-вниз
    procedure MoveTo(ARow, ACol: Integer; ASelect: Boolean;
      AKeepPref: Boolean = False);
    procedure MoveVert(ADelta: Integer; ASelect: Boolean);
    procedure WordLeft(ASelect: Boolean);
    procedure WordRight(ASelect: Boolean);
    // Правка: всё - с откатом, поверх выделения
    procedure InsertText(const AText: WideString; ATyping: Boolean = False);
    procedure DeleteSelection;
    procedure Backspace;
    procedure DeleteChar;
    procedure NewLine;
    procedure DeleteLine;
    procedure DeleteWordLeft;
    procedure DeleteWordRight;
    procedure Undo;
    procedure Redo;
    // Поиск AText с позиции каретки (после выделения) вниз; найдено -
    // выделено, каретка в конце
    function FindNext(const AText: WideString; ACaseSensitive: Boolean): Boolean;
    property Count: Integer read GetCount;
    property Lines[AIndex: Integer]: WideString read GetLine;
    // Строки и откат
    property Buffer: TEdBuffer read FBuffer;
    property FileName: WideString read FFileName write FFileName;
    // Кодировка записи (F2). Другая, чем у файла на диске, - Modified
    property Encoding: TFarEditEncoding read FEncoding write FEncoding;
    property Modified: Boolean read GetModified;
    property Row: Integer read FRow;
    property Col: Integer read FCol;
    property TopRow: Integer read FTopRow write FTopRow;
    property LeftCol: Integer read FLeftCol write FLeftCol;
    property TabSize: Integer read FTabSize write FTabSize;
    property Colorizer: TSchemeColorizer read FColorizer;
    property Scheme: TClrScheme read FScheme;
  end;

// Имя кодировки для строки состояния
function FarEditEncodingName(AEncoding: TFarEditEncoding): string;
// Кодировка подробно - для меню Shift+F8 и строки состояния
function FarEditEncodingTitle(AEncoding: TFarEditEncoding): string;
// Текст буфера обмена (Unicode; нет - ANSI); '' - пусто
function FarClipboardText: WideString;

implementation

const
  EdCpUtf8 = 65001;
  EdCpAnsi = 0;               // CP_ACP
  EdNoBestFit = $400;         // WC_NO_BEST_FIT_CHARS
  EdCfUnicodeText = 13;
  EdCfText = 1;

var
  // Символ Unicode -> байт кодировки Windows ('?' - нет такого)
  WideToAnsiMap: array of AnsiChar;

function EdMultiToWide(ACodePage: UINT; AFlags: DWORD; AMulti: PAnsiChar;
  AMultiLen: Integer; AWide: PWideChar; AWideLen: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'MultiByteToWideChar';
function EdWideToMulti(ACodePage: UINT; AFlags: DWORD; AWide: PWideChar;
  AWideLen: Integer; AMulti: PAnsiChar; AMultiLen: Integer;
  ADefault: PAnsiChar; AUsedDefault: Pointer): Integer; stdcall;
  external 'kernel32.dll' name 'WideCharToMultiByte';
function EdCreateFile(AFileName: PWideChar; AAccess, AShare: DWORD;
  ASecurity: Pointer; ACreation, AFlags: DWORD;
  ATemplate: THandle): THandle; stdcall;
  external 'kernel32.dll' name 'CreateFileW';
function EdOpenClipboard(AWnd: HWND): BOOL; stdcall;
  external 'user32.dll' name 'OpenClipboard';
function EdCloseClipboard: BOOL; stdcall;
  external 'user32.dll' name 'CloseClipboard';
function EdGetClipboardData(AFormat: UINT): THandle; stdcall;
  external 'user32.dll' name 'GetClipboardData';
function EdGlobalLock(AMem: THandle): Pointer; stdcall;
  external 'kernel32.dll' name 'GlobalLock';
function EdGlobalUnlock(AMem: THandle): BOOL; stdcall;
  external 'kernel32.dll' name 'GlobalUnlock';

function FarEditEncodingName(AEncoding: TFarEditEncoding): string;
begin
  case AEncoding of
    feUtf8: Result := 'UTF-8';
    feUtf8Bom: Result := 'UTF-8 BOM';
    feUtf16: Result := 'UTF-16';
  else
    Result := 'ANSI ' + IntToStr(GetACP);
  end;
end;

function FarEditEncodingTitle(AEncoding: TFarEditEncoding): string;
begin
  case AEncoding of
    feUtf8: Result := 'UTF-8';
    feUtf8Bom: Result := 'UTF-8 with BOM';
    feUtf16: Result := 'UTF-16 LE';
  else
    Result := 'ANSI (Windows ' + IntToStr(GetACP) + ')';
  end;
end;

function FarClipboardText: WideString;
var
  DataHandle: THandle;
  DataPtr: Pointer;
  AnsiText: string;
  WideLen: Integer;
begin
  Result := '';
  if not EdOpenClipboard(0) then
    Exit;
  try
    DataHandle := EdGetClipboardData(EdCfUnicodeText);
    if DataHandle <> 0 then
    begin
      DataPtr := EdGlobalLock(DataHandle);
      if DataPtr <> nil then
      try
        Result := PWideChar(DataPtr);
      finally
        EdGlobalUnlock(DataHandle);
      end;
      Exit;
    end;
    DataHandle := EdGetClipboardData(EdCfText);
    if DataHandle = 0 then
      Exit;
    DataPtr := EdGlobalLock(DataHandle);
    if DataPtr = nil then
      Exit;
    try
      AnsiText := PAnsiChar(DataPtr);
    finally
      EdGlobalUnlock(DataHandle);
    end;
    if AnsiText <> '' then
    begin
      WideLen := EdMultiToWide(EdCpAnsi, 0, PAnsiChar(AnsiText),
        Length(AnsiText), nil, 0);
      SetLength(Result, WideLen);
      if WideLen > 0 then
        EdMultiToWide(EdCpAnsi, 0, PAnsiChar(AnsiText), Length(AnsiText),
          PWideChar(Result), WideLen);
    end;
  finally
    EdCloseClipboard;
  end;
end;

procedure BuildWideToAnsiMap;
var
  CharCode: Integer;
  WideCh: WideChar;
  AnsiCh: AnsiChar;
  UsedDefault: BOOL;
begin
  SetLength(WideToAnsiMap, 65536);
  for CharCode := 0 to 127 do
    WideToAnsiMap[CharCode] := AnsiChar(CharCode);
  for CharCode := 128 to 65535 do
  begin
    WideCh := WideChar(CharCode);
    AnsiCh := '?';
    UsedDefault := False;
    if (EdWideToMulti(EdCpAnsi, EdNoBestFit, @WideCh, 1, @AnsiCh, 1, nil,
       @UsedDefault) <> 1) or UsedDefault then
      AnsiCh := '?';
    WideToAnsiMap[CharCode] := AnsiCh;
  end;
end;

// Позиция ANeedle в AHay (WideString; Pos Delphi 7 - для string); 0 - нет
function EdPos(const ANeedle, AHay: WideString): Integer;
var
  StartIdx, CharIdx: Integer;
  Matched: Boolean;
begin
  Result := 0;
  if (ANeedle = '') or (Length(ANeedle) > Length(AHay)) then
    Exit;
  for StartIdx := 1 to Length(AHay) - Length(ANeedle) + 1 do
    if AHay[StartIdx] = ANeedle[1] then
    begin
      Matched := True;
      for CharIdx := 2 to Length(ANeedle) do
        if AHay[StartIdx + CharIdx - 1] <> ANeedle[CharIdx] then
        begin
          Matched := False;
          Break;
        end;
      if Matched then
      begin
        Result := StartIdx;
        Exit;
      end;
    end;
end;

function IsWordChar(ACh: WideChar): Boolean;
begin
  Result := ((ACh >= 'a') and (ACh <= 'z')) or ((ACh >= 'A') and (ACh <= 'Z')) or
    ((ACh >= '0') and (ACh <= '9')) or (ACh = '_') or (Ord(ACh) >= 192);
end;

// ---------------------------------------------------------------------------

constructor TFarEditor.Create;
begin
  inherited Create;
  FBuffer := TEdBuffer.Create;
  FBuffer.AddListener(BufferChanged);
  FEncoding := feAnsi;
  FSavedEncoding := feAnsi;
  FLineBreak := #13#10;
  FFinalBreak := False;
  FTabSize := 8;
  FStatesValid := 0;
end;

destructor TFarEditor.Destroy;
begin
  FColorizer.Free;
  FScheme.Free;
  FBuffer.Free;
  inherited Destroy;
end;

function TFarEditor.GetLine(AIndex: Integer): WideString;
begin
  Result := FBuffer[AIndex];
end;

function TFarEditor.GetCount: Integer;
begin
  Result := FBuffer.Count;
end;

// Изменён текст или выбрана другая кодировка записи (Shift+F8)
function TFarEditor.GetModified: Boolean;
begin
  Result := FBuffer.Modified or (FEncoding <> FSavedEncoding);
end;

procedure TFarEditor.BufferChanged(Sender: TObject; AFirst, AOldCount,
  ANewCount: Integer);
begin
  LinesChanged(AFirst);
end;

procedure TFarEditor.SetScheme(AScheme: TClrScheme; ADefFg, ADefBg: Integer);
begin
  FColorizer.Free;
  FColorizer := nil;
  FScheme.Free;
  FScheme := AScheme;
  FColorizer := TSchemeColorizer.Create(FScheme, ADefFg, ADefBg);
  FStatesValid := 0;
end;

procedure TFarEditor.LinesChanged(AFromRow: Integer);
begin
  // Состояние в начале строки AFromRow не меняется (оно - от строк выше),
  // меняется у следующих
  if FStatesValid > AFromRow + 1 then
    FStatesValid := AFromRow + 1;
  if FStatesValid < 0 then
    FStatesValid := 0;
end;

function TFarEditor.AnsiLine(ARow: Integer): string;
var
  Line: WideString;
  CharIdx: Integer;
begin
  if WideToAnsiMap = nil then
    BuildWideToAnsiMap;
  Line := GetLine(ARow);
  SetLength(Result, Length(Line));
  for CharIdx := 1 to Length(Line) do
    Result[CharIdx] := WideToAnsiMap[Ord(Line[CharIdx])];
end;

function TFarEditor.LineState(ARow: Integer): Integer;
var
  State, RunCount, RowIdx: Integer;
  Runs: TSchemeRuns;
begin
  Result := -1;
  if (FColorizer = nil) or (ARow <= 0) then
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
  Runs := nil;
  while FStatesValid <= ARow do
  begin
    RowIdx := FStatesValid - 1;
    State := FStates[RowIdx];
    FColorizer.ColorLine(AnsiLine(RowIdx), State, Runs, RunCount);
    FStates[FStatesValid] := State;
    Inc(FStatesValid);
  end;
  Result := FStates[ARow];
end;

function TFarEditor.ScreenCol(ARow, ACol: Integer): Integer;
var
  Line: WideString;
  CharIdx, Limit: Integer;
begin
  Line := GetLine(ARow);
  Result := 0;
  Limit := ACol;
  if Limit > Length(Line) then
    Limit := Length(Line);
  for CharIdx := 1 to Limit do
    if Line[CharIdx] = #9 then
      Result := (Result div FTabSize + 1) * FTabSize
    else
      Inc(Result);
end;

function TFarEditor.ColAtScreen(ARow, AScreenCol: Integer): Integer;
var
  Line: WideString;
  CharIdx, Pos, NextPos: Integer;
begin
  Line := GetLine(ARow);
  Pos := 0;
  for CharIdx := 1 to Length(Line) do
  begin
    if Line[CharIdx] = #9 then
      NextPos := (Pos div FTabSize + 1) * FTabSize
    else
      NextPos := Pos + 1;
    if AScreenCol < NextPos then
    begin
      // Табуляция: правее её середины - после неё
      if (Line[CharIdx] = #9) and (AScreenCol - Pos > (NextPos - Pos) div 2) then
        Result := CharIdx
      else
        Result := CharIdx - 1;
      Exit;
    end;
    Pos := NextPos;
  end;
  Result := Length(Line);
end;

function TFarEditor.HasSelection: Boolean;
begin
  Result := FSelActive and ((FSelRow <> FRow) or (FSelCol <> FCol));
end;

function TFarEditor.SelRange(var ARow1, ACol1, ARow2, ACol2: Integer): Boolean;
begin
  Result := HasSelection;
  if not Result then
    Exit;
  if (FSelRow < FRow) or ((FSelRow = FRow) and (FSelCol < FCol)) then
  begin
    ARow1 := FSelRow;
    ACol1 := FSelCol;
    ARow2 := FRow;
    ACol2 := FCol;
  end
  else
  begin
    ARow1 := FRow;
    ACol1 := FCol;
    ARow2 := FSelRow;
    ACol2 := FSelCol;
  end;
end;

function TFarEditor.SelectedText: WideString;
var
  Row1, Col1, Row2, Col2, RowIdx: Integer;
begin
  Result := '';
  if not SelRange(Row1, Col1, Row2, Col2) then
    Exit;
  if Row1 = Row2 then
  begin
    Result := Copy(FBuffer[Row1], Col1 + 1, Col2 - Col1);
    Exit;
  end;
  Result := Copy(FBuffer[Row1], Col1 + 1, MaxInt);
  for RowIdx := Row1 + 1 to Row2 - 1 do
    Result := Result + #13#10 + FBuffer[RowIdx];
  Result := Result + #13#10 + Copy(FBuffer[Row2], 1, Col2);
end;

procedure TFarEditor.SelectAll;
begin
  FSelActive := True;
  FSelRow := 0;
  FSelCol := 0;
  FRow := FBuffer.Count - 1;
  FCol := FBuffer.LineLength(FRow);
  FPrefCol := ScreenCol(FRow, FCol);
end;

procedure TFarEditor.ClearSelection;
begin
  FSelActive := False;
end;

procedure TFarEditor.MoveTo(ARow, ACol: Integer; ASelect: Boolean;
  AKeepPref: Boolean);
begin
  if ARow < 0 then
    ARow := 0;
  if ARow >= FBuffer.Count then
    ARow := FBuffer.Count - 1;
  if ACol < 0 then
    ACol := 0;
  if ACol > FBuffer.LineLength(ARow) then
    ACol := FBuffer.LineLength(ARow);
  if ASelect then
  begin
    if not FSelActive then
    begin
      FSelActive := True;
      FSelRow := FRow;
      FSelCol := FCol;
    end;
  end
  else
    FSelActive := False;
  // Движение каретки - конец набора: следующий набор - новая группа отката
  if (ARow <> FRow) or (ACol <> FCol) then
    FBuffer.BeginGroup;
  FRow := ARow;
  FCol := ACol;
  if not AKeepPref then
    FPrefCol := ScreenCol(FRow, FCol);
end;

procedure TFarEditor.MoveVert(ADelta: Integer; ASelect: Boolean);
var
  NewRow: Integer;
begin
  NewRow := FRow + ADelta;
  if NewRow < 0 then
    NewRow := 0;
  if NewRow >= FBuffer.Count then
    NewRow := FBuffer.Count - 1;
  MoveTo(NewRow, ColAtScreen(NewRow, FPrefCol), ASelect, True);
end;

procedure TFarEditor.WordLeft(ASelect: Boolean);
var
  Line: WideString;
  NewCol: Integer;
begin
  if FCol = 0 then
  begin
    if FRow > 0 then
      MoveTo(FRow - 1, FBuffer.LineLength(FRow - 1), ASelect);
    Exit;
  end;
  Line := FBuffer[FRow];
  NewCol := FCol;
  while (NewCol > 0) and not IsWordChar(Line[NewCol]) do
    Dec(NewCol);
  while (NewCol > 0) and IsWordChar(Line[NewCol]) do
    Dec(NewCol);
  MoveTo(FRow, NewCol, ASelect);
end;

procedure TFarEditor.WordRight(ASelect: Boolean);
var
  Line: WideString;
  NewCol: Integer;
begin
  Line := FBuffer[FRow];
  if FCol >= Length(Line) then
  begin
    if FRow < FBuffer.Count - 1 then
      MoveTo(FRow + 1, 0, ASelect);
    Exit;
  end;
  NewCol := FCol;
  while (NewCol < Length(Line)) and IsWordChar(Line[NewCol + 1]) do
    Inc(NewCol);
  while (NewCol < Length(Line)) and not IsWordChar(Line[NewCol + 1]) do
    Inc(NewCol);
  MoveTo(FRow, NewCol, ASelect);
end;

// Удаление с откатом (каретка до правки - в записи отката)
procedure TFarEditor.DeleteRange(ARow1, ACol1, ARow2, ACol2: Integer);
begin
  FBuffer.DeleteText(ARow1, ACol1, ARow2, ACol2, FRow, FCol);
  FRow := ARow1;
  FCol := ACol1;
end;

procedure TFarEditor.DeleteSelection;
var
  Row1, Col1, Row2, Col2: Integer;
begin
  if not SelRange(Row1, Col1, Row2, Col2) then
  begin
    FSelActive := False;
    Exit;
  end;
  DeleteRange(Row1, Col1, Row2, Col2);
  FSelActive := False;
  FPrefCol := ScreenCol(FRow, FCol);
end;

procedure TFarEditor.InsertText(const AText: WideString; ATyping: Boolean);
var
  Clean: WideString;
  CharIdx, EndRow, EndCol: Integer;
  ContinueTyping: Boolean;
begin
  // Переводы строк любого вида - #10
  Clean := '';
  CharIdx := 1;
  while CharIdx <= Length(AText) do
  begin
    if AText[CharIdx] = #13 then
    begin
      Clean := Clean + #10;
      if (CharIdx < Length(AText)) and (AText[CharIdx + 1] = #10) then
        Inc(CharIdx);
    end
    else
      Clean := Clean + AText[CharIdx];
    Inc(CharIdx);
  end;
  // Набор продолжает группу набора, если выделения нет
  ContinueTyping := ATyping and not HasSelection and FBuffer.LastIsTyping;
  if not ContinueTyping then
    FBuffer.BeginGroup;
  if HasSelection then
    DeleteSelection;
  FSelActive := False;
  if Clean = '' then
    Exit;
  FBuffer.InsertText(FRow, FCol, Clean, ATyping, FRow, FCol, EndRow, EndCol);
  FRow := EndRow;
  FCol := EndCol;
  FPrefCol := ScreenCol(FRow, FCol);
end;

procedure TFarEditor.Backspace;
var
  NewRow, NewCol: Integer;
begin
  FBuffer.BeginGroup;
  if HasSelection then
  begin
    DeleteSelection;
    Exit;
  end;
  FSelActive := False;
  if (FRow = 0) and (FCol = 0) then
    Exit;
  if FCol > 0 then
  begin
    NewRow := FRow;
    NewCol := FCol - 1;
  end
  else
  begin
    NewRow := FRow - 1;
    NewCol := FBuffer.LineLength(NewRow);
  end;
  DeleteRange(NewRow, NewCol, FRow, FCol);
  FPrefCol := ScreenCol(FRow, FCol);
end;

procedure TFarEditor.DeleteChar;
begin
  FBuffer.BeginGroup;
  if HasSelection then
  begin
    DeleteSelection;
    Exit;
  end;
  FSelActive := False;
  if FCol < FBuffer.LineLength(FRow) then
    DeleteRange(FRow, FCol, FRow, FCol + 1)
  else if FRow < FBuffer.Count - 1 then
    DeleteRange(FRow, FCol, FRow + 1, 0);
end;

// Enter: перевод строки и отступ, как у текущей строки (до каретки)
procedure TFarEditor.NewLine;
var
  Line, Indent: WideString;
  CharIdx: Integer;
begin
  Line := FBuffer[FRow];
  CharIdx := 1;
  while (CharIdx <= Length(Line)) and (CharIdx <= FCol) and
        ((Line[CharIdx] = ' ') or (Line[CharIdx] = #9)) do
    Inc(CharIdx);
  Indent := Copy(Line, 1, CharIdx - 1);
  InsertText(#10 + Indent);
end;

// Ctrl+Y: удалить строку (как в FAR)
procedure TFarEditor.DeleteLine;
var
  KeepRow: Integer;
begin
  FBuffer.BeginGroup;
  FSelActive := False;
  KeepRow := FRow;
  if FRow < FBuffer.Count - 1 then
    DeleteRange(FRow, 0, FRow + 1, 0)
  else if FRow > 0 then
  begin
    // Последняя строка: вместе с переводом строки перед ней
    KeepRow := FRow - 1;
    DeleteRange(FRow - 1, FBuffer.LineLength(FRow - 1), FRow,
      FBuffer.LineLength(FRow));
  end
  else if FBuffer.LineLength(0) > 0 then
    DeleteRange(0, 0, 0, FBuffer.LineLength(0))
  else
    Exit;
  FRow := KeepRow;
  FCol := ColAtScreen(FRow, FPrefCol);
end;

procedure TFarEditor.DeleteWordLeft;
begin
  if not HasSelection then
    WordLeft(True);
  FBuffer.BeginGroup;
  DeleteSelection;
end;

procedure TFarEditor.DeleteWordRight;
begin
  if not HasSelection then
    WordRight(True);
  FBuffer.BeginGroup;
  DeleteSelection;
end;

procedure TFarEditor.Undo;
begin
  if not FBuffer.Undo(FRow, FCol) then
    Exit;
  FSelActive := False;
  FPrefCol := ScreenCol(FRow, FCol);
end;

procedure TFarEditor.Redo;
begin
  if not FBuffer.Redo(FRow, FCol) then
    Exit;
  FSelActive := False;
  FPrefCol := ScreenCol(FRow, FCol);
end;

function TFarEditor.FindNext(const AText: WideString;
  ACaseSensitive: Boolean): Boolean;
var
  Needle, Hay: WideString;
  RowIdx, StartCol, FoundPos, Pass: Integer;
begin
  Result := False;
  if AText = '' then
    Exit;
  if ACaseSensitive then
    Needle := AText
  else
    Needle := WideUpperCase(AText);
  // С каретки до конца, потом с начала до каретки
  for Pass := 0 to 1 do
    for RowIdx := 0 to FBuffer.Count - 1 do
    begin
      if (Pass = 0) and (RowIdx < FRow) then
        Continue;
      if (Pass = 1) and (RowIdx > FRow) then
        Break;
      if ACaseSensitive then
        Hay := FBuffer[RowIdx]
      else
        Hay := WideUpperCase(FBuffer[RowIdx]);
      if (Pass = 0) and (RowIdx = FRow) then
        StartCol := FCol
      else
        StartCol := 0;
      FoundPos := EdPos(Needle, Copy(Hay, StartCol + 1, MaxInt));
      if FoundPos > 0 then
      begin
        FoundPos := FoundPos + StartCol - 1;
        MoveTo(RowIdx, FoundPos, False);
        MoveTo(RowIdx, FoundPos + Length(Needle), True);
        Result := True;
        Exit;
      end;
    end;
end;

// ---------------------------------------------------------------------------
//  Файл
// ---------------------------------------------------------------------------

function EdIsUtf8(const ARaw: string; AStart: Integer; var AHasHigh: Boolean): Boolean;
var
  BytePos, TailCount, TailIdx: Integer;
  ByteValue: Byte;
begin
  Result := True;
  AHasHigh := False;
  BytePos := AStart;
  while BytePos <= Length(ARaw) do
  begin
    ByteValue := Ord(ARaw[BytePos]);
    if ByteValue < $80 then
    begin
      Inc(BytePos);
      Continue;
    end;
    AHasHigh := True;
    if (ByteValue >= $C2) and (ByteValue <= $DF) then
      TailCount := 1
    else if (ByteValue >= $E0) and (ByteValue <= $EF) then
      TailCount := 2
    else if (ByteValue >= $F0) and (ByteValue <= $F4) then
      TailCount := 3
    else
    begin
      Result := False;
      Exit;
    end;
    // Обрыв последовательности в самом конце файла - не повод
    if BytePos + TailCount > Length(ARaw) then
      Exit;
    for TailIdx := 1 to TailCount do
      if (Ord(ARaw[BytePos + TailIdx]) and $C0) <> $80 then
      begin
        Result := False;
        Exit;
      end;
    Inc(BytePos, TailCount + 1);
  end;
end;

function EdDecode(ACodePage: UINT; const ARaw: string; AStart: Integer): WideString;
var
  WideLen, ByteLen: Integer;
begin
  Result := '';
  ByteLen := Length(ARaw) - AStart + 1;
  if ByteLen <= 0 then
    Exit;
  WideLen := EdMultiToWide(ACodePage, 0, @ARaw[AStart], ByteLen, nil, 0);
  if WideLen <= 0 then
    Exit;
  SetLength(Result, WideLen);
  EdMultiToWide(ACodePage, 0, @ARaw[AStart], ByteLen, PWideChar(Result),
    WideLen);
end;

function TFarEditor.LoadFromFile(const AFileName: WideString;
  var AError: string): Boolean;
var
  FileHandle: THandle;
  FileSize, ReadCount: DWORD;
  Raw: string;
  Text: WideString;
  HasHigh: Boolean;
  CharIdx, StartIdx, LineCount: Integer;
  BreakFound: Boolean;
  NewLines: TEdLines;
begin
  Result := False;
  AError := '';
  FileHandle := EdCreateFile(PWideChar(AFileName), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  if FileHandle = INVALID_HANDLE_VALUE then
  begin
    AError := SysErrorMessage(GetLastError);
    Exit;
  end;
  try
    FileSize := GetFileSize(FileHandle, nil);
    if FileSize = $FFFFFFFF then
    begin
      AError := SysErrorMessage(GetLastError);
      Exit;
    end;
    if FileSize > 256 * 1024 * 1024 then
    begin
      AError := 'файл больше 256 МБ';
      Exit;
    end;
    SetLength(Raw, FileSize);
    ReadCount := 0;
    if (FileSize > 0) and (not ReadFile(FileHandle, Raw[1], FileSize,
       ReadCount, nil) or (ReadCount <> FileSize)) then
    begin
      AError := SysErrorMessage(GetLastError);
      Exit;
    end;
  finally
    CloseHandle(FileHandle);
  end;
  // Кодировка
  if (Length(Raw) >= 3) and (Raw[1] = #$EF) and (Raw[2] = #$BB) and
     (Raw[3] = #$BF) then
  begin
    FEncoding := feUtf8Bom;
    Text := EdDecode(EdCpUtf8, Raw, 4);
  end
  else if (Length(Raw) >= 2) and (Raw[1] = #$FF) and (Raw[2] = #$FE) then
  begin
    FEncoding := feUtf16;
    SetLength(Text, (Length(Raw) - 2) div 2);
    if Length(Text) > 0 then
      Move(Raw[3], Text[1], Length(Text) * 2);
  end
  else if EdIsUtf8(Raw, 1, HasHigh) and HasHigh then
  begin
    FEncoding := feUtf8;
    Text := EdDecode(EdCpUtf8, Raw, 1);
  end
  else
  begin
    FEncoding := feAnsi;
    Text := EdDecode(EdCpAnsi, Raw, 1);
  end;
  Raw := '';
  // Строки; перевод строки - по первому
  FLineBreak := #13#10;
  BreakFound := False;
  LineCount := 0;
  SetLength(NewLines, 1024);
  StartIdx := 1;
  CharIdx := 1;
  while CharIdx <= Length(Text) do
  begin
    if (Text[CharIdx] = #13) or (Text[CharIdx] = #10) then
    begin
      if LineCount >= Length(NewLines) then
        SetLength(NewLines, LineCount * 2);
      NewLines[LineCount] := Copy(Text, StartIdx, CharIdx - StartIdx);
      Inc(LineCount);
      if (Text[CharIdx] = #13) and (CharIdx < Length(Text)) and
         (Text[CharIdx + 1] = #10) then
      begin
        if not BreakFound then
          FLineBreak := #13#10;
        Inc(CharIdx);
      end
      else if not BreakFound then
      begin
        if Text[CharIdx] = #13 then
          FLineBreak := #13
        else
          FLineBreak := #10;
      end;
      BreakFound := True;
      StartIdx := CharIdx + 1;
    end;
    Inc(CharIdx);
  end;
  // Последняя строка (после последнего перевода - может быть пустой)
  if LineCount >= Length(NewLines) then
    SetLength(NewLines, LineCount + 1);
  NewLines[LineCount] := Copy(Text, StartIdx, MaxInt);
  Inc(LineCount);
  FFinalBreak := BreakFound and (NewLines[LineCount - 1] = '');
  // Перевод в конце файла - не отдельная пустая строка для показа
  if FFinalBreak and (LineCount > 1) then
    Dec(LineCount);
  FBuffer.AssignLines(NewLines, LineCount);
  FFileName := AFileName;
  FSavedEncoding := FEncoding;
  FRow := 0;
  FCol := 0;
  FPrefCol := 0;
  FTopRow := 0;
  FLeftCol := 0;
  FSelActive := False;
  FStatesValid := 0;
  Result := True;
end;

function TFarEditor.SaveToFile(const AFileName: WideString;
  AEncoding: TFarEditEncoding; AAllowLossy: Boolean; var ALossy: Boolean;
  var AError: string): Boolean;
var
  Text: WideString;
  Raw, Bom: string;
  ByteLen: Integer;
  UsedDefault: BOOL;
  FileHandle: THandle;
  Written: DWORD;
begin
  Result := False;
  AError := '';
  ALossy := False;
  Text := FBuffer.GetText(FLineBreak);
  if FFinalBreak then
    Text := Text + FLineBreak;
  case AEncoding of
    feUtf16:
      begin
        SetLength(Raw, Length(Text) * 2 + 2);
        Raw[1] := #$FF;
        Raw[2] := #$FE;
        if Text <> '' then
          Move(Text[1], Raw[3], Length(Text) * 2);
      end;
    feUtf8, feUtf8Bom:
      begin
        Raw := '';
        if Text <> '' then
        begin
          ByteLen := EdWideToMulti(EdCpUtf8, 0, PWideChar(Text), Length(Text),
            nil, 0, nil, nil);
          SetLength(Raw, ByteLen);
          EdWideToMulti(EdCpUtf8, 0, PWideChar(Text), Length(Text),
            PAnsiChar(Raw), ByteLen, nil, nil);
        end;
        // BOM - байтами. Строковая константа в Free Pascal ({$CODEPAGE
        // CP1251}) при сложении перекодируется в кодировку Windows: при
        // кодировке не 1251 байты EF и BF становились '?'
        if AEncoding = feUtf8Bom then
        begin
          SetLength(Bom, 3);
          Bom[1] := AnsiChar($EF);
          Bom[2] := AnsiChar($BB);
          Bom[3] := AnsiChar($BF);
          Raw := Bom + Raw;
        end;
      end;
  else
    Raw := '';
    if Text <> '' then
    begin
      UsedDefault := False;
      ByteLen := EdWideToMulti(EdCpAnsi, EdNoBestFit, PWideChar(Text),
        Length(Text), nil, 0, nil, @UsedDefault);
      SetLength(Raw, ByteLen);
      UsedDefault := False;
      EdWideToMulti(EdCpAnsi, EdNoBestFit, PWideChar(Text), Length(Text),
        PAnsiChar(Raw), ByteLen, nil, @UsedDefault);
      ALossy := UsedDefault;
      if ALossy and not AAllowLossy then
        Exit;
    end;
  end;
  FileHandle := EdCreateFile(PWideChar(AFileName), GENERIC_WRITE, 0, nil,
    CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if FileHandle = INVALID_HANDLE_VALUE then
  begin
    AError := SysErrorMessage(GetLastError);
    Exit;
  end;
  try
    Written := 0;
    if (Raw <> '') and (not WriteFile(FileHandle, Raw[1], Length(Raw), Written,
       nil) or (Integer(Written) <> Length(Raw))) then
    begin
      AError := SysErrorMessage(GetLastError);
      Exit;
    end;
  finally
    CloseHandle(FileHandle);
  end;
  FFileName := AFileName;
  FEncoding := AEncoding;
  FSavedEncoding := AEncoding;
  FBuffer.MarkSaved;
  Result := True;
end;

end.
