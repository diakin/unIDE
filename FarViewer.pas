unit FarViewer;

// ---------------------------------------------------------------------------
//  Просмотр файла (F3) для FAR unIDE / uniFAR - без окна: модель, которую
//  рисует TFarView (UnFar).
//
//  Файл в память целиком не читается: позиция - смещение в байтах, нужное
//  читается блоками по ViewBlockSize (кэш из нескольких блоков). Так
//  смотрятся и файлы в гигабайты.
//
//  Режимы: текст (с переносом длинных строк по ширине окна или без, тогда -
//  сдвиг влево-вправо) и hex (смещение, байты, символы). Кодировки текста:
//  ANSI и OEM (кодовые страницы Windows), UTF-8, UTF-16 LE. При открытии -
//  по BOM, иначе по первым 64 КБ (UTF-16 по нулевым байтам, UTF-8 - если
//  есть многобайтные последовательности и нет ошибок, иначе ANSI).
//
//  Строка текста - до перевода строки (LF; CR перед ним не показывается),
//  но не длиннее ViewMaxLine байт: дальше - следующая строка экрана (так
//  двоичный файл без переводов строк не читается целиком ради одной строки).
//
//  Поиск - по символам в выбранной кодировке, с учётом регистра или без.
// ---------------------------------------------------------------------------

// Free Pascal (uniFAR): исходник в кодировке Windows-1251 - строки с
// кириллицей в WideString без кракозябр. Delphi 7 эту строку пропускает
{$IFDEF FPC}{$CODEPAGE CP1251}{$ENDIF}

interface

uses
  Windows, SysUtils;

type
  TFarViewEncoding = (fvAnsi, fvOem, fvUtf8, fvUtf16);

  // Строка экрана: байты [Start, Stop) файла; Text - клетки экрана (табуляции
  // раскрыты, без переноса - с колонки LeftCol); HlStart / HlLen - клетки
  // найденного текста (HlLen = 0 - нет)
  TFarViewRow = record
    Start: Int64;
    Stop: Int64;
    Text: WideString;
    HlStart: Integer;
    HlLen: Integer;
  end;
  TFarViewRows = array of TFarViewRow;
  TInt64Array = array of Int64;

  TFarViewer = class
  private
    FFileName: WideString;
    FHandle: THandle;
    FSize: Int64;
    FBomEncoding: TFarViewEncoding;
    FBomSize: Integer;
    FEncoding: TFarViewEncoding;
    FHex: Boolean;
    FWrap: Boolean;
    FTop: Int64;
    FLeftCol: Integer;
    FTabSize: Integer;
    FFoundPos: Int64;
    FFoundEnd: Int64;
    // Кэш блоков
    FBlockPos: array of Int64;
    FBlockData: array of string;
    FBlockLen: array of Integer;
    FBlockNext: Integer;
    FByteMap: array[Byte] of WideChar;   // ANSI / OEM: байт -> символ
    // Последний поиск начала строки назад: в [FScanLow, FScanHigh) нет LF,
    // начало строки - FScanStart (FScanHigh < 0 - нет)
    FScanLow: Int64;
    FScanHigh: Int64;
    FScanStart: Int64;
    FByteMapOem: Boolean;
    FByteMapDone: Boolean;
    function ReadAt(APos: Int64; ACount: Integer; var ABuf: string): Integer;
    function ByteAt(APos: Int64): Integer;
    function UnitSize: Integer;
    function DataStart: Int64;
    function IsLineEnd(APos: Int64): Boolean;
    function LineStart(APos: Int64): Int64;
    function NextLineStart(AChunk: Int64): Int64;
    procedure BuildByteMap(AOem: Boolean);
    procedure DecodeRange(AStart, AStop: Int64; var AChars: WideString;
      var AOffs: TInt64Array);
    procedure ChunkRows(AChunk: Int64; AWidth: Integer; var ARows: TFarViewRows;
      var ACount: Integer);
    procedure HexRow(APos: Int64; AWidth: Integer; var ARow: TFarViewRow);
    procedure SetEncoding(AValue: TFarViewEncoding);
    procedure SetHex(AValue: Boolean);
    procedure SetWrap(AValue: Boolean);
    procedure SetTop(AValue: Int64);
    procedure SetLeftCol(AValue: Integer);
    function AlignTop(APos: Int64): Int64;
  public
    constructor Create;
    destructor Destroy; override;
    function Open(const AFileName: WideString; var AError: string): Boolean;
    // Перечитать размер (файл мог вырасти), кэш - заново
    procedure Reread;
    // Строки экрана от позиции ATop
    function Rows(ATop: Int64; AWidth, ACount: Integer): TFarViewRows;
    // Байт в строке hex при ширине AWidth (16, 8 или 4)
    function HexBytesPerRow(AWidth: Integer): Integer;
    // Начало строки экрана, где байт APos
    function RowStartOf(APos: Int64; AWidth: Integer): Int64;
    // Начало предыдущей строки экрана
    function PrevRowStart(APos: Int64; AWidth: Integer): Int64;
    procedure LineDown(AWidth, AHeight: Integer);
    procedure LineUp(AWidth: Integer);
    procedure PageDown(AWidth, AHeight: Integer);
    procedure PageUp(AWidth, AHeight: Integer);
    procedure GoHome;
    procedure GoEnd(AWidth, AHeight: Integer);
    // К смещению (верх экрана - строка с ним)
    procedure GoToPos(APos: Int64; AWidth: Integer);
    // Поиск AText от позиции AFrom; найдено - FoundPos / FoundEnd и экран
    // так, чтобы найденное было видно
    function FindNext(const AText: WideString; ACaseSensitive: Boolean;
      AFrom: Int64; AWidth, AHeight: Integer): Boolean;
    // Сколько процентов файла до APos (обычно - конец последней строки экрана)
    function Percent(APos: Int64): Integer;
    // Следующая кодировка по F8
    function NextEncoding: TFarViewEncoding;
    property FileName: WideString read FFileName;
    property Size: Int64 read FSize;
    property Encoding: TFarViewEncoding read FEncoding write SetEncoding;
    property Hex: Boolean read FHex write SetHex;
    property Wrap: Boolean read FWrap write SetWrap;
    property Top: Int64 read FTop write SetTop;
    property LeftCol: Integer read FLeftCol write SetLeftCol;
    property TabSize: Integer read FTabSize write FTabSize;
    property FoundPos: Int64 read FFoundPos;
    property FoundEnd: Int64 read FFoundEnd;
  end;

function FarViewEncodingName(AEncoding: TFarViewEncoding): string;
// Позиция из текста окна Alt+F8: '50%', '0x1F00', '$1F00', '1F00h' или
// десятичное число. False - не разобрать
function FarViewParsePos(const AText: string; ASize: Int64;
  var APos: Int64): Boolean;

implementation

const
  ViewBlockSize = 65536;
  ViewBlockCount = 32;
  // Строка длиннее - продолжается следующей строкой экрана (чётное: UTF-16)
  ViewMaxLine = 16384;
  // Дальше назад начало строки не ищется (двоичный файл без LF)
  ViewMaxBackScan = 1048576;
  ViewDetectSize = 65536;
  VwShareDelete = $00000004;      // FILE_SHARE_DELETE

function VwCreateFile(AFileName: PWideChar; AAccess, AShare: DWORD;
  ASecurity: Pointer; ACreation, AFlags: DWORD;
  ATemplate: THandle): THandle; stdcall;
  external 'kernel32.dll' name 'CreateFileW';
function VwMultiToWide(ACodePage: UINT; AFlags: DWORD; AMulti: PAnsiChar;
  AMultiLen: Integer; AWide: PWideChar; AWideLen: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'MultiByteToWideChar';
function VwCharLowerBuff(AText: PWideChar; ALength: DWORD): DWORD; stdcall;
  external 'user32.dll' name 'CharLowerBuffW';

var
  // Строчные буквы для поиска без учёта регистра (строится один раз)
  LowerMap: array of WideChar;

procedure BuildLowerMap;
var
  CharIdx: Integer;
begin
  if Length(LowerMap) > 0 then
    Exit;
  SetLength(LowerMap, 65536);
  for CharIdx := 0 to 65535 do
    LowerMap[CharIdx] := WideChar(CharIdx);
  VwCharLowerBuff(@LowerMap[1], 65535);
end;

function FarViewEncodingName(AEncoding: TFarViewEncoding): string;
begin
  case AEncoding of
    fvAnsi: Result := 'ANSI ' + IntToStr(GetACP);
    fvOem: Result := 'OEM ' + IntToStr(GetOEMCP);
    fvUtf8: Result := 'UTF-8';
  else
    Result := 'UTF-16';
  end;
end;

function FarViewParsePos(const AText: string; ASize: Int64;
  var APos: Int64): Boolean;
var
  Text: string;
  PercentValue: Integer;
  Value: Int64;
begin
  Result := False;
  Text := Trim(AText);
  if Text = '' then
    Exit;
  if Text[Length(Text)] = '%' then
  begin
    PercentValue := StrToIntDef(Trim(Copy(Text, 1, Length(Text) - 1)), -1);
    if (PercentValue < 0) or (PercentValue > 100) then
      Exit;
    APos := ASize * PercentValue div 100;
    Result := True;
    Exit;
  end;
  if (Length(Text) > 2) and (Text[1] = '0') and
     ((Text[2] = 'x') or (Text[2] = 'X')) then
    Text := '$' + Copy(Text, 3, MaxInt)
  else if (Length(Text) > 1) and
          ((Text[Length(Text)] = 'h') or (Text[Length(Text)] = 'H')) then
    Text := '$' + Copy(Text, 1, Length(Text) - 1);
  Value := StrToInt64Def(Text, -1);
  if Value < 0 then
    Exit;
  APos := Value;
  Result := True;
end;

// ---------------------------------------------------------------------------

constructor TFarViewer.Create;
begin
  inherited Create;
  FHandle := INVALID_HANDLE_VALUE;
  FTabSize := 8;
  FWrap := True;
  FFoundPos := -1;
  FFoundEnd := -1;
  FScanHigh := -1;
  SetLength(FBlockPos, ViewBlockCount);
  SetLength(FBlockData, ViewBlockCount);
  SetLength(FBlockLen, ViewBlockCount);
end;

destructor TFarViewer.Destroy;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FHandle);
  inherited Destroy;
end;

function TFarViewer.Open(const AFileName: WideString;
  var AError: string): Boolean;
var
  Head: string;
  HeadLen, BytePos, TailCount, TailIdx, OddZeros, EvenZeros: Integer;
  ByteValue: Byte;
  ValidUtf8, HasMulti: Boolean;
begin
  Result := False;
  AError := '';
  FHandle := VwCreateFile(PWideChar(AFileName), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE or VwShareDelete, nil,
    OPEN_EXISTING, 0, 0);
  if FHandle = INVALID_HANDLE_VALUE then
  begin
    AError := SysErrorMessage(GetLastError);
    Exit;
  end;
  FFileName := AFileName;
  Reread;
  // Кодировка: BOM, иначе по началу файла
  HeadLen := ReadAt(0, ViewDetectSize, Head);
  FBomSize := 0;
  FBomEncoding := fvAnsi;
  if (HeadLen >= 3) and (Head[1] = #$EF) and (Head[2] = #$BB) and
     (Head[3] = #$BF) then
  begin
    FBomEncoding := fvUtf8;
    FBomSize := 3;
  end
  else if (HeadLen >= 2) and (Head[1] = #$FF) and (Head[2] = #$FE) then
  begin
    FBomEncoding := fvUtf16;
    FBomSize := 2;
  end;
  if FBomSize > 0 then
    FEncoding := FBomEncoding
  else
  begin
    // UTF-16 LE: старшие (нечётные) байты часто нулевые, младшие - нет
    OddZeros := 0;
    EvenZeros := 0;
    for BytePos := 1 to HeadLen do
      if Head[BytePos] = #0 then
        if BytePos mod 2 = 0 then
          Inc(OddZeros)
        else
          Inc(EvenZeros);
    if (HeadLen >= 4) and (OddZeros > HeadLen div 8) and
       (EvenZeros < OddZeros div 8) then
      FEncoding := fvUtf16
    else
    begin
      ValidUtf8 := True;
      HasMulti := False;
      BytePos := 1;
      while ValidUtf8 and (BytePos <= HeadLen) do
      begin
        ByteValue := Ord(Head[BytePos]);
        if ByteValue < $80 then
        begin
          Inc(BytePos);
          Continue;
        end;
        if (ByteValue >= $C2) and (ByteValue <= $DF) then
          TailCount := 1
        else if (ByteValue >= $E0) and (ByteValue <= $EF) then
          TailCount := 2
        else if (ByteValue >= $F0) and (ByteValue <= $F4) then
          TailCount := 3
        else
        begin
          ValidUtf8 := False;
          Break;
        end;
        // Обрыв на границе прочитанного - не ошибка
        if BytePos + TailCount > HeadLen then
          Break;
        for TailIdx := 1 to TailCount do
          if (Ord(Head[BytePos + TailIdx]) and $C0) <> $80 then
            ValidUtf8 := False;
        HasMulti := True;
        Inc(BytePos, TailCount + 1);
      end;
      if ValidUtf8 and HasMulti then
        FEncoding := fvUtf8
      else
        FEncoding := fvAnsi;
    end;
  end;
  FTop := DataStart;
  Result := True;
end;

procedure TFarViewer.Reread;
var
  SizeLow, SizeHigh: DWORD;
  BlockIdx: Integer;
begin
  FSize := 0;
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    SizeHigh := 0;
    SizeLow := GetFileSize(FHandle, @SizeHigh);
    if (SizeLow <> $FFFFFFFF) or (GetLastError = NO_ERROR) then
      FSize := Int64(SizeHigh) shl 32 + SizeLow;
  end;
  for BlockIdx := 0 to ViewBlockCount - 1 do
  begin
    FBlockPos[BlockIdx] := -1;
    FBlockData[BlockIdx] := '';
    FBlockLen[BlockIdx] := 0;
  end;
  FBlockNext := 0;
  FScanHigh := -1;
  if FTop > FSize then
    FTop := AlignTop(FSize);
end;

// Прочитать до ACount байт с APos (через кэш блоков); результат - число
// прочитанных
function TFarViewer.ReadAt(APos: Int64; ACount: Integer;
  var ABuf: string): Integer;
var
  BlockStart: Int64;
  BlockIdx, Found, InBlock, Take: Integer;
  PosLow, PosHigh: Longint;
  ReadCount: DWORD;
begin
  Result := 0;
  SetLength(ABuf, ACount);
  while (Result < ACount) and (APos < FSize) do
  begin
    BlockStart := APos - APos mod ViewBlockSize;
    Found := -1;
    for BlockIdx := 0 to ViewBlockCount - 1 do
      if FBlockPos[BlockIdx] = BlockStart then
      begin
        Found := BlockIdx;
        Break;
      end;
    if Found < 0 then
    begin
      Found := FBlockNext;
      FBlockNext := (FBlockNext + 1) mod ViewBlockCount;
      SetLength(FBlockData[Found], ViewBlockSize);
      PosLow := Longint(BlockStart and $FFFFFFFF);
      PosHigh := Longint(BlockStart shr 32);
      ReadCount := 0;
      if (SetFilePointer(FHandle, PosLow, @PosHigh, FILE_BEGIN) = $FFFFFFFF)
         and (GetLastError <> NO_ERROR) then
        Break;
      if not ReadFile(FHandle, FBlockData[Found][1], ViewBlockSize,
         ReadCount, nil) then
        ReadCount := 0;
      FBlockPos[Found] := BlockStart;
      FBlockLen[Found] := ReadCount;
      if ReadCount = 0 then
      begin
        FBlockPos[Found] := -1;
        Break;
      end;
    end;
    InBlock := APos - BlockStart;
    Take := FBlockLen[Found] - InBlock;
    if Take <= 0 then
      Break;
    if Take > ACount - Result then
      Take := ACount - Result;
    Move(FBlockData[Found][InBlock + 1], ABuf[Result + 1], Take);
    Inc(Result, Take);
    Inc(APos, Take);
  end;
  SetLength(ABuf, Result);
end;

function TFarViewer.ByteAt(APos: Int64): Integer;
var
  Buf: string;
begin
  if ReadAt(APos, 1, Buf) = 1 then
    Result := Ord(Buf[1])
  else
    Result := -1;
end;

function TFarViewer.UnitSize: Integer;
begin
  if FEncoding = fvUtf16 then
    Result := 2
  else
    Result := 1;
end;

// Начало текста: после BOM, если кодировка - та, что по BOM
function TFarViewer.DataStart: Int64;
begin
  if (FBomSize > 0) and (FEncoding = FBomEncoding) then
    Result := FBomSize
  else
    Result := 0;
end;

// Перед APos - перевод строки (LF)
function TFarViewer.IsLineEnd(APos: Int64): Boolean;
begin
  if FEncoding = fvUtf16 then
    Result := (APos - 2 >= DataStart) and (ByteAt(APos - 2) = 10) and
      (ByteAt(APos - 1) = 0)
  else
    Result := (APos - 1 >= DataStart) and (ByteAt(APos - 1) = 10);
end;

// Начало строки экрана без переноса (куска строки не длиннее ViewMaxLine),
// в которой байт APos
function TFarViewer.LineStart(APos: Int64): Int64;
var
  Start, ScanFrom, Limit, ChunkStart: Int64;
  Buf: string;
  BufLen, BufIdx, Step: Integer;
  Found: Boolean;
begin
  Result := DataStart;
  if APos <= DataStart then
    Exit;
  Step := UnitSize;
  if FEncoding = fvUtf16 then
    APos := APos - (APos - DataStart) mod 2;
  if IsLineEnd(APos) then
  begin
    Result := APos;
    Exit;
  end;
  // Тот же участок без LF, что в прошлый раз (листание назад по двоичному
  // файлу) - без нового поиска
  if (FScanHigh >= 0) and (APos > FScanLow) and (APos <= FScanHigh) then
  begin
    Result := FScanStart + ((APos - FScanStart) div ViewMaxLine) * ViewMaxLine;
    Exit;
  end;
  // Назад до LF блоками
  Found := False;
  Start := DataStart;
  Limit := APos - ViewMaxBackScan;
  if Limit < DataStart then
    Limit := DataStart;
  ScanFrom := APos;
  while (ScanFrom > Limit) and not Found do
  begin
    ChunkStart := ScanFrom - ViewBlockSize;
    if ChunkStart < Limit then
      ChunkStart := Limit;
    if (FEncoding = fvUtf16) and ((ChunkStart - DataStart) mod 2 <> 0) then
      Inc(ChunkStart);
    BufLen := ReadAt(ChunkStart, ScanFrom - ChunkStart, Buf);
    BufIdx := BufLen - Step + 1;
    while BufIdx >= 1 do
    begin
      if (Buf[BufIdx] = #10) and ((Step = 1) or ((BufIdx < BufLen) and
         (Buf[BufIdx + 1] = #0))) then
      begin
        Start := ChunkStart + BufIdx - 1 + Step;
        Found := True;
        Break;
      end;
      Dec(BufIdx, Step);
    end;
    if ChunkStart = ScanFrom then
      Break;
    ScanFrom := ChunkStart;
  end;
  if not Found and (Limit > DataStart) then
    // Начало строки дальше, чем ищем: куски - от начала текста
    Start := DataStart;
  if Found then
    FScanLow := Start
  else
    FScanLow := Limit;
  FScanHigh := APos;
  FScanStart := Start;
  Result := Start + ((APos - Start) div ViewMaxLine) * ViewMaxLine;
end;

// Конец куска строки, начатого в AChunk: после LF, или конец файла, или
// AChunk + ViewMaxLine
function TFarViewer.NextLineStart(AChunk: Int64): Int64;
var
  Buf: string;
  BufLen, BufIdx, Step: Integer;
begin
  Step := UnitSize;
  BufLen := ReadAt(AChunk, ViewMaxLine, Buf);
  BufIdx := 1;
  while BufIdx + Step - 1 <= BufLen do
  begin
    if (Buf[BufIdx] = #10) and ((Step = 1) or (Buf[BufIdx + 1] = #0)) then
    begin
      Result := AChunk + BufIdx - 1 + Step;
      Exit;
    end;
    Inc(BufIdx, Step);
  end;
  Result := AChunk + BufLen;
  if Result > FSize then
    Result := FSize;
end;

// Байт -> символ: кодовая страница OEM или ANSI
procedure TFarViewer.BuildByteMap(AOem: Boolean);
var
  ByteIdx: Integer;
  CodePage: UINT;
  Ch: AnsiChar;
  WideCh: WideChar;
begin
  if FByteMapDone and (FByteMapOem = AOem) then
    Exit;
  if AOem then
    CodePage := CP_OEMCP
  else
    CodePage := CP_ACP;
  FByteMapOem := AOem;
  for ByteIdx := 0 to 255 do
  begin
    Ch := AnsiChar(ByteIdx);
    WideCh := '?';
    if VwMultiToWide(CodePage, 0, @Ch, 1, @WideCh, 1) <> 1 then
      WideCh := '?';
    FByteMap[ByteIdx] := WideCh;
  end;
  FByteMapDone := True;
end;

// Символы байт [AStart, AStop) и смещение каждого (AOffs[N] - конец).
// Неверный байт UTF-8 - символ U+FFFD
procedure TFarViewer.DecodeRange(AStart, AStop: Int64; var AChars: WideString;
  var AOffs: TInt64Array);
var
  Buf: string;
  BufLen, BufIdx, CharCount, TailCount, TailIdx: Integer;
  ByteValue: Byte;
  CodePoint: Cardinal;
  Valid: Boolean;

  procedure AddChar(ACode: Cardinal; AOffset: Integer);
  begin
    Inc(CharCount);
    if ACode > $FFFF then
      ACode := $FFFD;   // вне BMP - знак замены (клетка одна)
    AChars[CharCount] := WideChar(ACode);
    AOffs[CharCount - 1] := AStart + AOffset - 1;
  end;

begin
  BufLen := 0;
  if AStop > AStart then
    BufLen := ReadAt(AStart, AStop - AStart, Buf);
  SetLength(AChars, BufLen);
  SetLength(AOffs, BufLen + 1);
  CharCount := 0;
  BufIdx := 1;
  case FEncoding of
    fvUtf16:
      while BufIdx + 1 <= BufLen do
      begin
        AddChar(Ord(Buf[BufIdx]) or (Ord(Buf[BufIdx + 1]) shl 8), BufIdx);
        Inc(BufIdx, 2);
      end;
    fvUtf8:
      while BufIdx <= BufLen do
      begin
        ByteValue := Ord(Buf[BufIdx]);
        if ByteValue < $80 then
        begin
          AddChar(ByteValue, BufIdx);
          Inc(BufIdx);
          Continue;
        end;
        if (ByteValue >= $C2) and (ByteValue <= $DF) then
        begin
          TailCount := 1;
          CodePoint := ByteValue and $1F;
        end
        else if (ByteValue >= $E0) and (ByteValue <= $EF) then
        begin
          TailCount := 2;
          CodePoint := ByteValue and $0F;
        end
        else if (ByteValue >= $F0) and (ByteValue <= $F4) then
        begin
          TailCount := 3;
          CodePoint := ByteValue and $07;
        end
        else
        begin
          AddChar($FFFD, BufIdx);
          Inc(BufIdx);
          Continue;
        end;
        Valid := BufIdx + TailCount <= BufLen;
        if Valid then
          for TailIdx := 1 to TailCount do
            if (Ord(Buf[BufIdx + TailIdx]) and $C0) <> $80 then
              Valid := False
            else
              CodePoint := (CodePoint shl 6) or
                (Cardinal(Ord(Buf[BufIdx + TailIdx])) and $3F);
        if Valid then
        begin
          AddChar(CodePoint, BufIdx);
          Inc(BufIdx, TailCount + 1);
        end
        else
        begin
          AddChar($FFFD, BufIdx);
          Inc(BufIdx);
        end;
      end;
  else
    begin
      BuildByteMap(FEncoding = fvOem);
      while BufIdx <= BufLen do
      begin
        AddChar(Ord(FByteMap[Ord(Buf[BufIdx])]), BufIdx);
        Inc(BufIdx);
      end;
    end;
  end;
  SetLength(AChars, CharCount);
  SetLength(AOffs, CharCount + 1);
  AOffs[CharCount] := AStart + BufIdx - 1;
  if AOffs[CharCount] > AStop then
    AOffs[CharCount] := AStop;
end;

// Строки экрана куска строки AChunk: без переноса - одна (с LeftCol), с
// переносом - по AWidth клеток
procedure TFarViewer.ChunkRows(AChunk: Int64; AWidth: Integer;
  var ARows: TFarViewRows; var ACount: Integer);
var
  ChunkEnd, RowStart: Int64;
  Chars: WideString;
  Offs: TInt64Array;
  CharCount, CharIdx, CellCount, NextCell, CellIdx, RowFirstCell: Integer;
  Cells: WideString;
  CellChar: array of Integer;   // клетка -> номер символа (с 0)
  ShownCh: WideChar;
  FirstCell, LastCell, BackCell, ShownCells, HlFirst, HlLast: Integer;
  HlFrom, HlTo: Integer;

  procedure AddRow(AFirstCell, ACellCount: Integer; AStart, AStop: Int64);
  var
    HlA, HlB: Integer;
  begin
    if ACount >= Length(ARows) then
      SetLength(ARows, ACount * 2 + 8);
    ARows[ACount].Start := AStart;
    ARows[ACount].Stop := AStop;
    ARows[ACount].Text := Copy(Cells, AFirstCell + 1, ACellCount);
    ARows[ACount].HlStart := 0;
    ARows[ACount].HlLen := 0;
    if HlFrom >= 0 then
    begin
      HlA := HlFrom;
      if HlA < AFirstCell then
        HlA := AFirstCell;
      HlB := HlTo;
      if HlB > AFirstCell + ACellCount then
        HlB := AFirstCell + ACellCount;
      if HlB > HlA then
      begin
        ARows[ACount].HlStart := HlA - AFirstCell;
        ARows[ACount].HlLen := HlB - HlA;
      end;
    end;
    Inc(ACount);
  end;

begin
  ChunkEnd := NextLineStart(AChunk);
  DecodeRange(AChunk, ChunkEnd, Chars, Offs);
  CharCount := Length(Chars);
  // Перевод строки не показываем
  while (CharCount > 0) and ((Chars[CharCount] = #10) or
        (Chars[CharCount] = #13)) do
    Dec(CharCount);
  // Клетки: табуляции раскрыты
  SetLength(Cells, CharCount * 2 + 16);
  SetLength(CellChar, Length(Cells) + 1);
  CellCount := 0;
  for CharIdx := 1 to CharCount do
  begin
    ShownCh := Chars[CharIdx];
    if ShownCh = #9 then
      NextCell := (CellCount div FTabSize + 1) * FTabSize
    else
      NextCell := CellCount + 1;
    if Ord(ShownCh) < 32 then
      ShownCh := ' ';
    while CellCount < NextCell do
    begin
      if CellCount >= Length(Cells) then
      begin
        SetLength(Cells, CellCount * 2);
        SetLength(CellChar, Length(Cells) + 1);
      end;
      Inc(CellCount);
      Cells[CellCount] := ShownCh;
      CellChar[CellCount - 1] := CharIdx - 1;
    end;
  end;
  SetLength(Cells, CellCount);
  // Найденное: клетки [HlFrom, HlTo)
  HlFrom := -1;
  HlTo := -1;
  if (FFoundPos >= 0) and (FFoundEnd > AChunk) and (FFoundPos < ChunkEnd) then
  begin
    HlFirst := -1;
    HlLast := -1;
    for CellIdx := 0 to CellCount - 1 do
      if (Offs[CellChar[CellIdx]] >= FFoundPos) and
         (Offs[CellChar[CellIdx]] < FFoundEnd) then
      begin
        if HlFirst < 0 then
          HlFirst := CellIdx;
        HlLast := CellIdx;
      end;
    if HlFirst >= 0 then
    begin
      HlFrom := HlFirst;
      HlTo := HlLast + 1;
    end;
  end;
  if not FWrap or (AWidth < 1) then
  begin
    AddRow(FLeftCol, AWidth, AChunk, ChunkEnd);
    Exit;
  end;
  // С переносом: по AWidth клеток; строка экрана начинается с символа (не
  // с середины табуляции)
  RowFirstCell := 0;
  if CellCount = 0 then
  begin
    AddRow(0, 0, AChunk, ChunkEnd);
    Exit;
  end;
  while RowFirstCell < CellCount do
  begin
    FirstCell := RowFirstCell;
    LastCell := FirstCell + AWidth;
    if LastCell > CellCount then
      LastCell := CellCount;
    // Не резать табуляцию: следующая строка - с границы символа. Вся строка
    // экрана - одна табуляция (окно уже её) - строка до конца табуляции,
    // видно AWidth клеток
    if (LastCell < CellCount) and
       (CellChar[LastCell] = CellChar[LastCell - 1]) then
    begin
      BackCell := LastCell;
      while (BackCell > FirstCell) and
            (CellChar[BackCell] = CellChar[BackCell - 1]) do
        Dec(BackCell);
      if BackCell > FirstCell then
        LastCell := BackCell
      else
        while (LastCell < CellCount) and
              (CellChar[LastCell] = CellChar[LastCell - 1]) do
          Inc(LastCell);
    end;
    ShownCells := LastCell - FirstCell;
    if ShownCells > AWidth then
      ShownCells := AWidth;
    if FirstCell = 0 then
      RowStart := AChunk
    else
      RowStart := Offs[CellChar[FirstCell]];
    if LastCell >= CellCount then
      AddRow(FirstCell, ShownCells, RowStart, ChunkEnd)
    else
      AddRow(FirstCell, ShownCells, RowStart, Offs[CellChar[LastCell]]);
    RowFirstCell := LastCell;
  end;
end;

function TFarViewer.HexBytesPerRow(AWidth: Integer): Integer;
begin
  // 'XXXXXXXXXX: ' + 3 клетки на байт + ' ' + символ на байт
  Result := 16;
  while (Result > 4) and (12 + Result * 4 + 1 > AWidth) do
    Result := Result div 2;
end;

procedure TFarViewer.HexRow(APos: Int64; AWidth: Integer; var ARow: TFarViewRow);
var
  Buf: string;
  BufLen, ByteIdx, PerRow, HexCol, CharCol: Integer;
  Text: WideString;
  OffsetText: string;
  ByteValue: Byte;
  ShownCh: WideChar;
begin
  PerRow := HexBytesPerRow(AWidth);
  BufLen := ReadAt(APos, PerRow, Buf);
  if FSize > $FFFFFFFF then
    OffsetText := IntToHex(APos, 10)
  else
    OffsetText := IntToHex(APos, 8);
  Text := WideString(OffsetText) + ': ';
  HexCol := Length(Text);
  CharCol := HexCol + PerRow * 3 + 1;
  Text := Text + StringOfChar(' ', CharCol + PerRow - Length(Text));
  // Символы в hex - OEM или ANSI (и для UTF-8 / UTF-16)
  BuildByteMap(FEncoding = fvOem);
  ARow.HlStart := 0;
  ARow.HlLen := 0;
  for ByteIdx := 0 to BufLen - 1 do
  begin
    ByteValue := Ord(Buf[ByteIdx + 1]);
    OffsetText := IntToHex(ByteValue, 2);
    Text[HexCol + ByteIdx * 3 + 1] := WideChar(OffsetText[1]);
    Text[HexCol + ByteIdx * 3 + 2] := WideChar(OffsetText[2]);
    if ByteValue < 32 then
      ShownCh := '.'
    else
      ShownCh := FByteMap[ByteValue];
    Text[CharCol + ByteIdx + 1] := ShownCh;
  end;
  // Найденное - в колонке байт
  if (FFoundPos >= 0) and (FFoundPos < APos + BufLen) and (FFoundEnd > APos) then
  begin
    ByteIdx := 0;
    if FFoundPos > APos then
      ByteIdx := FFoundPos - APos;
    ARow.HlStart := HexCol + ByteIdx * 3;
    if FFoundEnd >= APos + BufLen then
      ARow.HlLen := (BufLen - ByteIdx) * 3 - 1
    else
      ARow.HlLen := (FFoundEnd - APos - ByteIdx) * 3 - 1;
  end;
  ARow.Start := APos;
  ARow.Stop := APos + BufLen;
  ARow.Text := Text;
end;

function TFarViewer.Rows(ATop: Int64; AWidth, ACount: Integer): TFarViewRows;
var
  RowCount, ChunkCount, ChunkIdx: Integer;
  RowPos, Chunk: Int64;
  ChunkList: TFarViewRows;
  PerRow: Integer;
begin
  SetLength(Result, ACount);
  RowCount := 0;
  if FHex then
  begin
    PerRow := HexBytesPerRow(AWidth);
    RowPos := ATop;
    while (RowCount < ACount) and (RowPos < FSize) do
    begin
      HexRow(RowPos, AWidth, Result[RowCount]);
      Inc(RowCount);
      Inc(RowPos, PerRow);
    end;
    SetLength(Result, RowCount);
    Exit;
  end;
  RowPos := AlignTop(ATop);
  ChunkList := nil;
  // Первый кусок - от начала строки (ATop бывает серединой строки при
  // переносе); дальше куски идут подряд
  Chunk := LineStart(RowPos);
  while (RowCount < ACount) and (Chunk < FSize) do
  begin
    ChunkCount := 0;
    ChunkRows(Chunk, AWidth, ChunkList, ChunkCount);
    if ChunkCount = 0 then
      Break;
    for ChunkIdx := 0 to ChunkCount - 1 do
      // Строки экрана до ATop - мимо
      if (ChunkList[ChunkIdx].Stop > RowPos) and (RowCount < ACount) then
      begin
        Result[RowCount] := ChunkList[ChunkIdx];
        Inc(RowCount);
      end;
    if ChunkList[ChunkCount - 1].Stop <= Chunk then
      Break;
    Chunk := ChunkList[ChunkCount - 1].Stop;
  end;
  SetLength(Result, RowCount);
end;

function TFarViewer.AlignTop(APos: Int64): Int64;
var
  PerRow: Integer;
begin
  if APos < 0 then
    APos := 0;
  if APos > FSize then
    APos := FSize;
  if FHex then
  begin
    PerRow := 16;
    Result := APos - APos mod PerRow;
  end
  else
  begin
    Result := APos;
    if Result < DataStart then
      Result := DataStart;
    if (FEncoding = fvUtf16) and ((Result - DataStart) mod 2 <> 0) then
      Dec(Result);
  end;
end;

function TFarViewer.RowStartOf(APos: Int64; AWidth: Integer): Int64;
var
  Chunk: Int64;
  ChunkList: TFarViewRows;
  ChunkCount, ChunkIdx, PerRow: Integer;
begin
  if FHex then
  begin
    PerRow := HexBytesPerRow(AWidth);
    Result := APos - APos mod PerRow;
    Exit;
  end;
  APos := AlignTop(APos);
  Chunk := LineStart(APos);
  Result := Chunk;
  if not FWrap then
    Exit;
  ChunkList := nil;
  ChunkCount := 0;
  ChunkRows(Chunk, AWidth, ChunkList, ChunkCount);
  for ChunkIdx := 0 to ChunkCount - 1 do
    if ChunkList[ChunkIdx].Start <= APos then
      Result := ChunkList[ChunkIdx].Start;
end;

function TFarViewer.PrevRowStart(APos: Int64; AWidth: Integer): Int64;
var
  Chunk: Int64;
  ChunkList: TFarViewRows;
  ChunkCount, ChunkIdx, PerRow: Integer;
begin
  if FHex then
  begin
    PerRow := HexBytesPerRow(AWidth);
    Result := APos - PerRow;
    if Result < 0 then
      Result := 0;
    Result := Result - Result mod PerRow;
    Exit;
  end;
  Result := APos;
  if APos <= DataStart then
    Exit;
  Chunk := LineStart(APos);
  if Chunk >= APos then
    Chunk := LineStart(APos - UnitSize);
  Result := Chunk;
  if not FWrap then
    Exit;
  ChunkList := nil;
  ChunkCount := 0;
  ChunkRows(Chunk, AWidth, ChunkList, ChunkCount);
  for ChunkIdx := 0 to ChunkCount - 1 do
    if ChunkList[ChunkIdx].Start < APos then
      Result := ChunkList[ChunkIdx].Start;
end;

procedure TFarViewer.LineDown(AWidth, AHeight: Integer);
var
  Shown: TFarViewRows;
begin
  Shown := Rows(FTop, AWidth, AHeight + 1);
  if Length(Shown) > AHeight then
    FTop := Shown[1].Start;
end;

procedure TFarViewer.LineUp(AWidth: Integer);
begin
  FTop := PrevRowStart(FTop, AWidth);
end;

procedure TFarViewer.PageDown(AWidth, AHeight: Integer);
var
  Shown: TFarViewRows;
  Target: Integer;
begin
  if AHeight < 2 then
    AHeight := 2;
  Shown := Rows(FTop, AWidth, AHeight * 2);
  if Length(Shown) <= AHeight then
    Exit;
  Target := AHeight - 1;
  if Target > Length(Shown) - AHeight then
    Target := Length(Shown) - AHeight;
  FTop := Shown[Target].Start;
end;

procedure TFarViewer.PageUp(AWidth, AHeight: Integer);
var
  StepIdx: Integer;
begin
  for StepIdx := 1 to AHeight - 1 do
  begin
    if FTop <= DataStart then
      Break;
    LineUp(AWidth);
  end;
  if FHex and (FTop < 0) then
    FTop := 0;
end;

procedure TFarViewer.GoHome;
begin
  FLeftCol := 0;
  if FHex then
    FTop := 0
  else
    FTop := DataStart;
end;

procedure TFarViewer.GoEnd(AWidth, AHeight: Integer);
var
  StepIdx, PerRow: Integer;
begin
  if FHex then
  begin
    PerRow := HexBytesPerRow(AWidth);
    FTop := FSize - FSize mod PerRow;
    if (FTop = FSize) and (FTop > 0) then
      Dec(FTop, PerRow);
  end
  else
    FTop := PrevRowStart(FSize, AWidth);
  for StepIdx := 1 to AHeight - 1 do
  begin
    if FTop <= DataStart then
      Break;
    LineUp(AWidth);
  end;
end;

procedure TFarViewer.GoToPos(APos: Int64; AWidth: Integer);
begin
  if APos > FSize then
    APos := FSize;
  if APos < 0 then
    APos := 0;
  if APos >= FSize then
    FTop := PrevRowStart(FSize, AWidth)
  else
    FTop := RowStartOf(APos, AWidth);
end;

function TFarViewer.FindNext(const AText: WideString; ACaseSensitive: Boolean;
  AFrom: Int64; AWidth, AHeight: Integer): Boolean;
const
  SearchChunk = 262144;
var
  Pattern, Chars: WideString;
  Offs: TInt64Array;
  ChunkStart, ChunkStop, OwnStop: Int64;
  CharIdx, PatIdx, PatLen, CharCount: Integer;
  FirstCh: WideChar;
  Matched: Boolean;
  Shown: TFarViewRows;
  RowIdx, HlCell, SavedLeft: Integer;
  Visible: Boolean;
begin
  Result := False;
  PatLen := Length(AText);
  if PatLen = 0 then
    Exit;
  Pattern := AText;
  if not ACaseSensitive then
  begin
    BuildLowerMap;
    for PatIdx := 1 to PatLen do
      Pattern[PatIdx] := LowerMap[Ord(Pattern[PatIdx])];
  end;
  FirstCh := Pattern[1];
  ChunkStart := AFrom;
  if ChunkStart < DataStart then
    ChunkStart := DataStart;
  if (FEncoding = fvUtf16) and ((ChunkStart - DataStart) mod 2 <> 0) then
    Inc(ChunkStart);
  while ChunkStart < FSize do
  begin
    OwnStop := ChunkStart + SearchChunk;
    if OwnStop > FSize then
      OwnStop := FSize;
    // С запасом на совпадение через границу куска
    ChunkStop := OwnStop + PatLen * 4;
    if ChunkStop > FSize then
      ChunkStop := FSize;
    DecodeRange(ChunkStart, ChunkStop, Chars, Offs);
    CharCount := Length(Chars);
    if not ACaseSensitive then
      for CharIdx := 1 to CharCount do
        Chars[CharIdx] := LowerMap[Ord(Chars[CharIdx])];
    for CharIdx := 1 to CharCount - PatLen + 1 do
    begin
      if Offs[CharIdx - 1] >= OwnStop then
        Break;
      if Chars[CharIdx] <> FirstCh then
        Continue;
      Matched := True;
      for PatIdx := 2 to PatLen do
        if Chars[CharIdx + PatIdx - 1] <> Pattern[PatIdx] then
        begin
          Matched := False;
          Break;
        end;
      if Matched then
      begin
        FFoundPos := Offs[CharIdx - 1];
        FFoundEnd := Offs[CharIdx - 1 + PatLen];
        Result := True;
        Break;
      end;
    end;
    if Result then
      Break;
    if OwnStop >= FSize then
      Break;
    ChunkStart := OwnStop;
  end;
  if not Result then
    Exit;
  // Найденное на экране - не двигать; иначе - строка с ним сверху
  Shown := Rows(FTop, AWidth, AHeight);
  Visible := (Length(Shown) > 0) and (FFoundPos >= Shown[0].Start) and
    (FFoundPos < Shown[High(Shown)].Stop);
  if not Visible then
    FTop := RowStartOf(FFoundPos, AWidth);
  // Без переноса - сдвиг, чтобы найденное было по ширине (клетки строки
  // считаются с нулевым сдвигом)
  if not FHex and not FWrap then
  begin
    SavedLeft := FLeftCol;
    FLeftCol := 0;
    Shown := Rows(FTop, ViewMaxLine * 8, AHeight);
    FLeftCol := SavedLeft;
    for RowIdx := 0 to High(Shown) do
      if Shown[RowIdx].HlLen > 0 then
      begin
        HlCell := Shown[RowIdx].HlStart;
        if (HlCell < FLeftCol) or
           (HlCell + Shown[RowIdx].HlLen > FLeftCol + AWidth) then
        begin
          FLeftCol := HlCell - AWidth div 3;
          if FLeftCol < 0 then
            FLeftCol := 0;
        end;
        Break;
      end;
  end;
end;

function TFarViewer.Percent(APos: Int64): Integer;
begin
  if FSize <= 0 then
    Result := 100
  else
    Result := APos * 100 div FSize;
  if Result > 100 then
    Result := 100;
end;

function TFarViewer.NextEncoding: TFarViewEncoding;
begin
  if FEncoding = High(TFarViewEncoding) then
    Result := Low(TFarViewEncoding)
  else
    Result := Succ(FEncoding);
end;

procedure TFarViewer.SetEncoding(AValue: TFarViewEncoding);
begin
  if AValue = FEncoding then
    Exit;
  FEncoding := AValue;
  FScanHigh := -1;
  FFoundPos := -1;
  FFoundEnd := -1;
  if not FHex then
    FTop := LineStart(AlignTop(FTop));
end;

procedure TFarViewer.SetHex(AValue: Boolean);
begin
  if AValue = FHex then
    Exit;
  FHex := AValue;
  FLeftCol := 0;
  if FHex then
    FTop := FTop - FTop mod 16
  else
    FTop := LineStart(AlignTop(FTop));
end;

procedure TFarViewer.SetWrap(AValue: Boolean);
begin
  if AValue = FWrap then
    Exit;
  FWrap := AValue;
  FLeftCol := 0;
  if not FHex then
    FTop := LineStart(AlignTop(FTop));
end;

procedure TFarViewer.SetTop(AValue: Int64);
begin
  FTop := AlignTop(AValue);
end;

procedure TFarViewer.SetLeftCol(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  FLeftCol := AValue;
end;

end.
