unit EdFileText;

// ---------------------------------------------------------------------------
//  Файл и TEdBuffer без промежуточной ANSI-строки всего текста (перевод
//  Unit1 на буфер, шаг 3).
//
//  Раньше файл шёл в буфер так: байты -> UTF-16 -> ANSI (Utf8ToAnsiFull) ->
//  UTF-16 (SetWinText) -> копия без #13 (TEdBuffer.SetText); запись -
//  обратно через ANSI-строку всего текста и AnsiToUtf8. Здесь байты сразу
//  переводятся в текст буфера (уже через #10, TEdBuffer.TakeText забирает
//  его без копии), а запись собирает байты файла по строкам буфера.
//
//  Символы UTF-8 файла, которых нет в кодовой странице Windows (стрелки,
//  греческие буквы и т.п.), остаются в буфере как есть и записываются
//  обратно, а не становятся '?'. Символ за U+FFFF (эмодзи) - '?', как и
//  раньше: Unit1 считает позиции по ANSI-тексту, где такой символ - один
//  знак, а в UTF-16 это пара.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  Windows, Messages, SysUtils, EdBuffer;

// Байты файла (без BOM) - текст для буфера: строки через #10 (#13#10 и
// одиночный #13 - тоже перевод строки). AIsUtf8 - своим разбором UTF-8
// (оборванная или недопустимая последовательность - '?'), иначе кодовая
// страница Windows
function EdDecodeBytes(const ARaw: AnsiString; AIsUtf8: Boolean): WideString;

// Текст буфера байтами файла: строки через #13#10, после последней - нет.
// AsUtf8 - UTF-8 (без BOM), иначе кодовая страница Windows (символ, которого
// в ней нет, - как у WideCharToMultiByte)
function EdEncodeBuffer(ABuffer: TEdBuffer; AsUtf8: Boolean): AnsiString;

// Весь текст окна редактора одним EM_SETTEXTEX в UTF-16: символы вне
// кодовой страницы Windows доходят до буфера окна как есть
procedure EdSendWideText(AWnd: HWND; const AText: WideString);

implementation

const
  EM_SETTEXTEX_ = WM_USER + 97;
  ST_DEFAULT_ = 0;
  CP_UNICODE_ = 1200;

type
  TSetTextEx_ = record
    flags: DWORD;
    codepage: UINT;
  end;

// Перевод строки в выходном тексте: #13#10 и одиночный #13 - один #10.
// APrevCR - прошлый символ был #13 (его #10 уже записан)
procedure PutChar(ACode: Word; var ADest: PWideChar; var APrevCR: Boolean);
begin
  if ACode = 13 then
  begin
    ADest^ := #10;
    Inc(ADest);
    APrevCR := True;
    Exit;
  end;
  if (ACode = 10) and APrevCR then
  begin
    APrevCR := False;
    Exit;
  end;
  APrevCR := False;
  ADest^ := WideChar(ACode);
  Inc(ADest);
end;

function DecodeUtf8(const ARaw: AnsiString): WideString;
var
  Dest, DestStart: PWideChar;
  ByteIdx, RawLen, Extra, TailIdx: Integer;
  LeadByte: Byte;
  CodePoint: Cardinal;
  PrevCR: Boolean;
begin
  Result := '';
  RawLen := Length(ARaw);
  if RawLen = 0 then
    Exit;
  // Знаков UTF-16 не больше, чем байтов
  SetLength(Result, RawLen);
  DestStart := PWideChar(Pointer(Result));
  Dest := DestStart;
  PrevCR := False;
  ByteIdx := 1;
  while ByteIdx <= RawLen do
  begin
    LeadByte := Byte(ARaw[ByteIdx]);
    if LeadByte < $80 then
    begin
      PutChar(LeadByte, Dest, PrevCR);
      Inc(ByteIdx);
      Continue;
    end;
    if (LeadByte and $E0) = $C0 then
    begin
      CodePoint := LeadByte and $1F;
      Extra := 1;
    end
    else if (LeadByte and $F0) = $E0 then
    begin
      CodePoint := LeadByte and $0F;
      Extra := 2;
    end
    else if (LeadByte and $F8) = $F0 then
    begin
      CodePoint := LeadByte and $07;
      Extra := 3;
    end
    else
    begin
      CodePoint := Ord('?');
      Extra := 0;
    end;

    if ByteIdx + Extra > RawLen then
    begin
      // Последовательность оборвана концом файла
      CodePoint := Ord('?');
      Extra := RawLen - ByteIdx;
    end
    else
      for TailIdx := 1 to Extra do
      begin
        if (Byte(ARaw[ByteIdx + TailIdx]) and $C0) <> $80 then
        begin
          // Хвост не того вида - ведущий байт считаем одиночным
          CodePoint := Ord('?');
          Extra := 0;
          Break;
        end;
        CodePoint := (CodePoint shl 6) or (Byte(ARaw[ByteIdx + TailIdx]) and $3F);
      end;
    Inc(ByteIdx, Extra + 1);

    // За U+FFFF и половинки суррогатной пары - один '?' (см. заголовок)
    if (CodePoint > $FFFF) or
       ((CodePoint >= $D800) and (CodePoint <= $DFFF)) then
      CodePoint := Ord('?');
    PutChar(Word(CodePoint), Dest, PrevCR);
  end;
  SetLength(Result, Dest - DestStart);
end;

// Однобайтовая кодовая страница Windows: таблица байт -> знак
function DecodeAnsi(const ARaw: AnsiString): WideString;
var
  CharMap: array[0..255] of WideChar;
  AllBytes: array[0..255] of AnsiChar;
  CpInfo: TCPInfo;
  Dest, DestStart: PWideChar;
  ByteIdx: Integer;
  PrevCR: Boolean;
begin
  Result := '';
  if ARaw = '' then
    Exit;
  if not GetCPInfo(CP_ACP, CpInfo) or (CpInfo.MaxCharSize <> 1) then
  begin
    // Многобайтовая страница - перевод Windows, #13 уберёт TakeText
    SetLength(Result, MultiByteToWideChar(CP_ACP, 0, PAnsiChar(ARaw),
      Length(ARaw), nil, 0));
    if Result <> '' then
      MultiByteToWideChar(CP_ACP, 0, PAnsiChar(ARaw), Length(ARaw),
        PWideChar(Pointer(Result)), Length(Result));
    Exit;
  end;
  for ByteIdx := 0 to 255 do
    AllBytes[ByteIdx] := AnsiChar(ByteIdx);
  // Байт 0 - тоже знак (#0), длина задана явно
  if MultiByteToWideChar(CP_ACP, 0, @AllBytes[0], 256, @CharMap[0],
     256) <> 256 then
    for ByteIdx := 0 to 255 do
      CharMap[ByteIdx] := WideChar(ByteIdx);
  SetLength(Result, Length(ARaw));
  DestStart := PWideChar(Pointer(Result));
  Dest := DestStart;
  PrevCR := False;
  for ByteIdx := 1 to Length(ARaw) do
    PutChar(Word(CharMap[Byte(ARaw[ByteIdx])]), Dest, PrevCR);
  SetLength(Result, Dest - DestStart);
end;

function EdDecodeBytes(const ARaw: AnsiString; AIsUtf8: Boolean): WideString;
begin
  if AIsUtf8 then
    Result := DecodeUtf8(ARaw)
  else
    Result := DecodeAnsi(ARaw);
end;

// Байты строки ALine (UTF-8 или CP_ACP) в AOut с места AOutLen; AOut
// растёт вдвое по мере надобности
procedure AppendLine(const ALine: WideString; AsUtf8: Boolean;
  var AOut: AnsiString; var AOutLen: Integer);
var
  CharIdx, LineLen, NeedLen, ByteCount: Integer;
  CodePoint: Cardinal;
  Dest: PAnsiChar;
begin
  LineLen := Length(ALine);
  if LineLen = 0 then
    Exit;
  // UTF-8: не больше 3 байтов на знак UTF-16 (пара - 4 байта на 2 знака)
  if AsUtf8 then
    NeedLen := AOutLen + LineLen * 3
  else
    NeedLen := AOutLen + WideCharToMultiByte(CP_ACP, 0,
      PWideChar(Pointer(ALine)), LineLen, nil, 0, nil, nil);
  if NeedLen > Length(AOut) then
    SetLength(AOut, NeedLen * 2 + 4096);
  Dest := PAnsiChar(Pointer(AOut)) + AOutLen;

  if not AsUtf8 then
  begin
    ByteCount := WideCharToMultiByte(CP_ACP, 0, PWideChar(Pointer(ALine)),
      LineLen, Dest, Length(AOut) - AOutLen, nil, nil);
    Inc(AOutLen, ByteCount);
    Exit;
  end;

  CharIdx := 1;
  while CharIdx <= LineLen do
  begin
    CodePoint := Word(ALine[CharIdx]);
    // Пара UTF-16 - один символ; половинка без пары - '?'
    if (CodePoint >= $D800) and (CodePoint <= $DBFF) and
       (CharIdx < LineLen) and (Word(ALine[CharIdx + 1]) >= $DC00) and
       (Word(ALine[CharIdx + 1]) <= $DFFF) then
    begin
      CodePoint := $10000 + ((CodePoint - $D800) shl 10) +
        (Word(ALine[CharIdx + 1]) - $DC00);
      Inc(CharIdx);
    end
    else if (CodePoint >= $D800) and (CodePoint <= $DFFF) then
      CodePoint := Ord('?');
    Inc(CharIdx);

    if CodePoint < $80 then
    begin
      Dest^ := AnsiChar(CodePoint);
      Inc(Dest);
    end
    else if CodePoint < $800 then
    begin
      Dest[0] := AnsiChar($C0 or (CodePoint shr 6));
      Dest[1] := AnsiChar($80 or (CodePoint and $3F));
      Inc(Dest, 2);
    end
    else if CodePoint < $10000 then
    begin
      Dest[0] := AnsiChar($E0 or (CodePoint shr 12));
      Dest[1] := AnsiChar($80 or ((CodePoint shr 6) and $3F));
      Dest[2] := AnsiChar($80 or (CodePoint and $3F));
      Inc(Dest, 3);
    end
    else
    begin
      Dest[0] := AnsiChar($F0 or (CodePoint shr 18));
      Dest[1] := AnsiChar($80 or ((CodePoint shr 12) and $3F));
      Dest[2] := AnsiChar($80 or ((CodePoint shr 6) and $3F));
      Dest[3] := AnsiChar($80 or (CodePoint and $3F));
      Inc(Dest, 4);
    end;
  end;
  AOutLen := Dest - PAnsiChar(Pointer(AOut));
end;

function EdEncodeBuffer(ABuffer: TEdBuffer; AsUtf8: Boolean): AnsiString;
var
  RowIdx, OutLen: Integer;
begin
  Result := '';
  OutLen := 0;
  // Начальный размер - по числу знаков: у кода почти всё ASCII
  SetLength(Result, ABuffer.TextLength + ABuffer.Count + 16);
  for RowIdx := 0 to ABuffer.Count - 1 do
  begin
    if RowIdx > 0 then
    begin
      if OutLen + 2 > Length(Result) then
        SetLength(Result, (OutLen + 2) * 2 + 4096);
      Result[OutLen + 1] := #13;
      Result[OutLen + 2] := #10;
      Inc(OutLen, 2);
    end;
    AppendLine(ABuffer[RowIdx], AsUtf8, Result, OutLen);
  end;
  SetLength(Result, OutLen);
end;

procedure EdSendWideText(AWnd: HWND; const AText: WideString);
var
  SetEx: TSetTextEx_;
  EmptyText: WideChar;
begin
  SetEx.flags := ST_DEFAULT_;
  SetEx.codepage := CP_UNICODE_;
  EmptyText := #0;
  if AText = '' then
    SendMessage(AWnd, EM_SETTEXTEX_, WPARAM(@SetEx), LPARAM(@EmptyText))
  else
    SendMessage(AWnd, EM_SETTEXTEX_, WPARAM(@SetEx),
      LPARAM(PWideChar(Pointer(AText))));
end;

end.
