program FileTextTest;

// Тест чтения и записи файла через буфер (перевод Unit1 на буфер, шаг 3):
// EdFileText.EdDecodeBytes / EdEncodeBuffer и TEdBuffer.TakeText. Большой
// файл - Unit1.pas в UTF-8 (как его хранит git) с CRLF: байты -> буфер ->
// байты должны совпасть, ANSI-текст буфера - с прежним путём
// (Utf8ToAnsiFull).
//
// Сборка - Free Pascal win32, запуск - Windows или Wine:
//   fpc -Twin32 -Mdelphi -Fu..\.. FileTextTest.dpr
//   FileTextTest.exe [файл UTF-8]

{$APPTYPE CONSOLE}
{$MODE DELPHI}

uses
  Windows, SysUtils, Classes, EdBuffer, EdFileText;

var
  FailCount: Integer;

procedure Check(ACond: Boolean; const AName: string);
begin
  if ACond then
    WriteLn('ok   ', AName)
  else
  begin
    WriteLn('FAIL ', AName);
    Inc(FailCount);
  end;
end;

function SameWide(const ALeft, ARight: WideString): Boolean;
begin
  Result := (Length(ALeft) = Length(ARight)) and
    ((ALeft = '') or (CompareByte(ALeft[1], ARight[1],
      Length(ALeft) * SizeOf(WideChar)) = 0));
end;

function SameBytes(const ALeft, ARight: AnsiString): Boolean;
begin
  Result := (Length(ALeft) = Length(ARight)) and
    ((ALeft = '') or (CompareByte(ALeft[1], ARight[1], Length(ALeft)) = 0));
end;

function WideOf(const ACodes: array of Word): WideString;
var
  CodeIdx: Integer;
begin
  SetLength(Result, Length(ACodes));
  for CodeIdx := 0 to High(ACodes) do
    Result[CodeIdx + 1] := WideChar(ACodes[CodeIdx]);
end;

function BytesOf(const ACodes: array of Byte): AnsiString;
var
  CodeIdx: Integer;
begin
  SetLength(Result, Length(ACodes));
  for CodeIdx := 0 to High(ACodes) do
    Result[CodeIdx + 1] := AnsiChar(ACodes[CodeIdx]);
end;

// Прежний путь Unit1: UTF-8 -> UTF-16 -> ANSI (копия Utf8ToAnsiFull)
function OldUtf8ToAnsi(const ARaw: AnsiString): AnsiString;
var
  Wide: WideString;
  Dest: PWideChar;
  ByteIdx, OutIdx, RawLen, Extra, TailIdx, OutLen: Integer;
  LeadByte: Byte;
  CodePoint: Cardinal;
begin
  Result := '';
  RawLen := Length(ARaw);
  if RawLen = 0 then
    Exit;
  SetLength(Wide, RawLen);
  Dest := PWideChar(Pointer(Wide));
  ByteIdx := 1;
  OutIdx := 0;
  while ByteIdx <= RawLen do
  begin
    LeadByte := Byte(ARaw[ByteIdx]);
    if LeadByte < $80 then
    begin
      CodePoint := LeadByte;
      Extra := 0;
    end
    else if (LeadByte and $E0) = $C0 then
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
      CodePoint := Ord('?');
      Extra := RawLen - ByteIdx;
    end
    else
      for TailIdx := 1 to Extra do
      begin
        if (Byte(ARaw[ByteIdx + TailIdx]) and $C0) <> $80 then
        begin
          CodePoint := Ord('?');
          Extra := 0;
          Break;
        end;
        CodePoint := (CodePoint shl 6) or (Byte(ARaw[ByteIdx + TailIdx]) and $3F);
      end;
    Inc(ByteIdx, Extra + 1);
    if CodePoint > $10FFFF then
      CodePoint := Ord('?');
    if CodePoint > $FFFF then
    begin
      Dec(CodePoint, $10000);
      Dest[OutIdx] := WideChar(Word($D800 or (CodePoint shr 10)));
      Inc(OutIdx);
      Dest[OutIdx] := WideChar(Word($DC00 or (CodePoint and $3FF)));
      Inc(OutIdx);
    end
    else
    begin
      Dest[OutIdx] := WideChar(Word(CodePoint));
      Inc(OutIdx);
    end;
  end;
  OutLen := WideCharToMultiByte(CP_ACP, 0, Dest, OutIdx, nil, 0, nil, nil);
  SetLength(Result, OutLen);
  WideCharToMultiByte(CP_ACP, 0, Dest, OutIdx, PAnsiChar(Pointer(Result)),
    OutLen, nil, nil);
end;

function WideToAnsi(const AText: WideString): AnsiString;
var
  OutLen: Integer;
begin
  Result := '';
  if AText = '' then
    Exit;
  OutLen := WideCharToMultiByte(CP_ACP, 0, PWideChar(Pointer(AText)),
    Length(AText), nil, 0, nil, nil);
  SetLength(Result, OutLen);
  WideCharToMultiByte(CP_ACP, 0, PWideChar(Pointer(AText)), Length(AText),
    PAnsiChar(Pointer(Result)), OutLen, nil, nil);
end;

function ReadBytes(const AFileName: string): AnsiString;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, Stream.Size);
    if Stream.Size > 0 then
      Stream.ReadBuffer(Result[1], Stream.Size);
  finally
    Stream.Free;
  end;
end;

procedure TestTakeText;
var
  Buffer: TEdBuffer;
  Text: WideString;
begin
  Buffer := TEdBuffer.Create;
  try
    Text := WideString('a'#13#10'b'#13'c'#10'd');
    Buffer.TakeText(Text);
    Check(Text = '', 'TakeText: строка забрана');
    Check((Buffer.Count = 4) and (Buffer[0] = 'a') and (Buffer[1] = 'b') and
      (Buffer[2] = 'c') and (Buffer[3] = 'd'), 'TakeText: #13#10, #13, #10');
    Check(SameWide(Buffer.GetText(#10), WideString('a'#10'b'#10'c'#10'd')),
      'TakeText: текст через #10');
    Check(not Buffer.Modified and not Buffer.CanUndo,
      'TakeText: не изменён, откат пуст');

    Text := WideString('x'#10'y'#10);
    Buffer.TakeText(Text);
    Check((Buffer.Count = 3) and (Buffer[2] = ''), 'TakeText: без #13');

    Text := '';
    Buffer.TakeText(Text);
    Check((Buffer.Count = 1) and (Buffer.TextLength = 0), 'TakeText: пусто');

    Text := WideString(#13#13#10);
    Buffer.TakeText(Text);
    Check(Buffer.Count = 3, 'TakeText: #13 и #13#10 подряд');
  finally
    Buffer.Free;
  end;
end;

procedure TestDecodeUtf8;
var
  Raw: AnsiString;
  Expected: WideString;
begin
  // Я, стрелка U+2192, эмодзи U+1F600, CRLF, b, CR, c, LF
  Raw := BytesOf([$D0, $AF, $E2, $86, $92, $F0, $9F, $98, $80, 13, 10,
    Ord('b'), 13, Ord('c'), 10]);
  Expected := WideOf([$042F, $2192, Ord('?'), 10, Ord('b'), 10, Ord('c'), 10]);
  Check(SameWide(EdDecodeBytes(Raw, True), Expected),
    'UTF-8: кириллица, стрелка, эмодзи - один ?, переводы строк');

  Raw := BytesOf([$C3, Ord('A'), $E2, $86]);
  Expected := WideOf([Ord('?'), Ord('A'), Ord('?')]);
  Check(SameWide(EdDecodeBytes(Raw, True), Expected),
    'UTF-8: неверный хвост, оборвано концом');

  Check(EdDecodeBytes('', True) = '', 'UTF-8: пусто');
end;

procedure TestDecodeAnsi;
var
  Raw: AnsiString;
  Expected, Decoded: WideString;
  ByteIdx, ExpLen: Integer;
begin
  SetLength(Raw, 254);
  ExpLen := 0;
  for ByteIdx := 0 to 255 do
    if (ByteIdx <> 10) and (ByteIdx <> 13) then
    begin
      Inc(ExpLen);
      Raw[ExpLen] := AnsiChar(ByteIdx);
    end;
  SetLength(Expected, 254);
  MultiByteToWideChar(CP_ACP, 0, PAnsiChar(Pointer(Raw)), 254,
    PWideChar(Pointer(Expected)), 254);
  Decoded := EdDecodeBytes(Raw, False);
  Check(SameWide(Decoded, Expected), 'ANSI: все байты - как MultiByteToWideChar');

  Raw := 'a'#13#10'b'#13'c';
  Check(SameWide(EdDecodeBytes(Raw, False), WideString('a'#10'b'#10'c')),
    'ANSI: переводы строк');
end;

procedure TestEncode;
var
  Buffer: TEdBuffer;
  Text: WideString;
  EndRow, EndCol: Integer;
  Expected: AnsiString;
begin
  Buffer := TEdBuffer.Create;
  try
    Text := WideOf([$042F, $2192, 10, Ord('b'), 10]);
    Buffer.TakeText(Text);
    // Набрано: эмодзи парой UTF-16 в начале второй строки
    Buffer.InsertRaw(1, 0, WideOf([$D83D, $DE00]), EndRow, EndCol);
    Expected := BytesOf([$D0, $AF, $E2, $86, $92, 13, 10, $F0, $9F, $98, $80,
      Ord('b'), 13, 10]);
    Check(SameBytes(EdEncodeBuffer(Buffer, True), Expected),
      'UTF-8: запись, пара - 4 байта, CRLF, последняя строка пустая');

    Text := WideOf([Ord('x'), $D800, Ord('y')]);
    Buffer.TakeText(Text);
    Check(SameBytes(EdEncodeBuffer(Buffer, True), 'x?y'),
      'UTF-8: половинка пары - ?');

    Text := WideString('a'#10#10'b');
    Buffer.TakeText(Text);
    Check(SameBytes(EdEncodeBuffer(Buffer, False), 'a'#13#10#13#10'b'),
      'ANSI: запись с CRLF');

    Text := '';
    Buffer.TakeText(Text);
    Check(EdEncodeBuffer(Buffer, True) = '', 'запись пустого');
  finally
    Buffer.Free;
  end;
end;

procedure TestBigFile(const AFileName: string);
var
  Raw, Back, OldAnsi, NewAnsi: AnsiString;
  Text: WideString;
  Buffer: TEdBuffer;
  StartTick: Cardinal;
  DecodeMs, EncodeMs, OldMs: Cardinal;
begin
  if not FileExists(AFileName) then
  begin
    WriteLn('skip большой файл: нет ', AFileName);
    Exit;
  end;
  Raw := ReadBytes(AFileName);
  Buffer := TEdBuffer.Create;
  try
    StartTick := GetTickCount;
    Text := EdDecodeBytes(Raw, True);
    Buffer.TakeText(Text);
    DecodeMs := GetTickCount - StartTick;

    StartTick := GetTickCount;
    Back := EdEncodeBuffer(Buffer, True);
    EncodeMs := GetTickCount - StartTick;
    Check(SameBytes(Back, Raw), 'большой файл: байты -> буфер -> байты');

    StartTick := GetTickCount;
    OldAnsi := OldUtf8ToAnsi(Raw);
    Buffer.SetText(WideString(OldAnsi));
    OldMs := GetTickCount - StartTick;
    NewAnsi := WideToAnsi(Buffer.GetText(#13#10));
    Check(SameBytes(NewAnsi, OldAnsi), 'большой файл: ANSI-текст как прежде');

    WriteLn(Format('     %d байт, %d строк: чтение %d мс, запись %d мс, ' +
      'прежнее чтение %d мс', [Length(Raw), Buffer.Count, DecodeMs,
      EncodeMs, OldMs]));
  finally
    Buffer.Free;
  end;
end;

begin
  FailCount := 0;
  TestTakeText;
  TestDecodeUtf8;
  TestDecodeAnsi;
  TestEncode;
  if ParamCount > 0 then
    TestBigFile(ParamStr(1));
  if FailCount = 0 then
    WriteLn('Все проверки прошли')
  else
    WriteLn('Не прошло: ', FailCount);
  Halt(FailCount);
end.
