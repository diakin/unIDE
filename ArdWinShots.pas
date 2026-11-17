unit ArdWinShots;

// ---------------------------------------------------------------------------
//  Снимки окон скетча (экран эмулятора 480x320) для карты окон и
//  конструктора окон.
//
//  Файл снимка: <папка сборки эмулятора>\winshots\Win<номер>.bmp, 24 бита,
//  без сжатия - запись и чтение своими силами (одинаково в Delphi 7 и
//  Lazarus). Миниатюра - среднее по клеткам исходных точек.
// ---------------------------------------------------------------------------

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils, Graphics;

// Имя файла снимка окна с номером AState в папке ADir
function WinShotFile(const ADir: string; AState: Integer): string;

// Экран RGB565 (AWidth x AHeight точек подряд, строки сверху вниз) - в .bmp
function SaveRgb565Bmp(const AFileName: string; APixels: PWord;
  AWidth, AHeight: Integer): Boolean;

// Миниатюра снимка размером AWidth x AHeight; nil - файла нет или он не
// 24-битный .bmp
function LoadShotThumb(const AFileName: string; AWidth, AHeight: Integer): TBitmap;

implementation

function WinShotFile(const ADir: string; AState: Integer): string;
begin
  Result := IncludeTrailingPathDelimiter(ADir) + 'Win' + IntToStr(AState) + '.bmp';
end;

procedure PutWord(var ABuf: array of Byte; AOffset: Integer; AValue: Cardinal);
begin
  ABuf[AOffset] := AValue and $FF;
  ABuf[AOffset + 1] := (AValue shr 8) and $FF;
end;

procedure PutLong(var ABuf: array of Byte; AOffset: Integer; AValue: Cardinal);
begin
  PutWord(ABuf, AOffset, AValue and $FFFF);
  PutWord(ABuf, AOffset + 2, AValue shr 16);
end;

function GetLong(const ABuf: string; AOffset: Integer): Cardinal;
begin
  // AOffset - с нуля
  Result := Byte(ABuf[AOffset + 1]) or (Byte(ABuf[AOffset + 2]) shl 8) or
            (Byte(ABuf[AOffset + 3]) shl 16) or (Cardinal(Byte(ABuf[AOffset + 4])) shl 24);
end;

function SaveRgb565Bmp(const AFileName: string; APixels: PWord;
  AWidth, AHeight: Integer): Boolean;
var
  Head: array[0..53] of Byte;
  Row: array of Byte;
  RowBytes, RowIdx, ColIdx: Integer;
  Pixel: Word;
  Source: PWord;
  Red, Green, Blue: Byte;
  Stream: TFileStream;
begin
  Result := False;
  if (APixels = nil) or (AWidth <= 0) or (AHeight <= 0) then
    Exit;
  RowBytes := (AWidth * 3 + 3) and not 3;
  FillChar(Head, SizeOf(Head), 0);
  Head[0] := Ord('B');
  Head[1] := Ord('M');
  PutLong(Head, 2, 54 + RowBytes * AHeight);
  PutLong(Head, 10, 54);
  PutLong(Head, 14, 40);
  PutLong(Head, 18, AWidth);
  PutLong(Head, 22, AHeight);          // снизу вверх
  PutWord(Head, 26, 1);
  PutWord(Head, 28, 24);
  PutLong(Head, 34, RowBytes * AHeight);
  SetLength(Row, RowBytes);
  try
    ForceDirectories(ExtractFilePath(AFileName));
    Stream := TFileStream.Create(AFileName, fmCreate);
    try
      Stream.WriteBuffer(Head, SizeOf(Head));
      for RowIdx := AHeight - 1 downto 0 do
      begin
        FillChar(Row[0], RowBytes, 0);
        Source := APixels;
        Inc(Source, RowIdx * AWidth);
        for ColIdx := 0 to AWidth - 1 do
        begin
          Pixel := Source^;
          Inc(Source);
          Red := (Pixel shr 11) and $1F;
          Green := (Pixel shr 5) and $3F;
          Blue := Pixel and $1F;
          Row[ColIdx * 3] := (Blue shl 3) or (Blue shr 2);
          Row[ColIdx * 3 + 1] := (Green shl 2) or (Green shr 4);
          Row[ColIdx * 3 + 2] := (Red shl 3) or (Red shr 2);
        end;
        Stream.WriteBuffer(Row[0], RowBytes);
      end;
    finally
      Stream.Free;
    end;
    Result := True;
  except
    Result := False;
  end;
end;

function LoadShotThumb(const AFileName: string; AWidth, AHeight: Integer): TBitmap;
var
  Stream: TFileStream;
  Data: string;
  DataOffset, SrcW, SrcH, RowBytes, ThumbX, ThumbY, SrcX, SrcY: Integer;
  FromX, ToX, FromY, ToY, Count, PixelPos: Integer;
  SumRed, SumGreen, SumBlue: Cardinal;
begin
  Result := nil;
  if (AWidth <= 0) or (AHeight <= 0) or not FileExists(AFileName) then
    Exit;
  try
    Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(Data, Stream.Size);
      if Length(Data) > 0 then
        Stream.ReadBuffer(Data[1], Length(Data));
    finally
      Stream.Free;
    end;
  except
    Exit;
  end;
  if (Length(Data) < 54) or (Data[1] <> 'B') or (Data[2] <> 'M') or
     (Byte(Data[29]) <> 24) then
    Exit;
  DataOffset := GetLong(Data, 10);
  SrcW := GetLong(Data, 18);
  SrcH := GetLong(Data, 22);
  RowBytes := (SrcW * 3 + 3) and not 3;
  if (SrcW <= 0) or (SrcH <= 0) or (DataOffset + RowBytes * SrcH > Length(Data)) then
    Exit;
  Result := TBitmap.Create;
  Result.Width := AWidth;
  Result.Height := AHeight;
  for ThumbY := 0 to AHeight - 1 do
  begin
    FromY := ThumbY * SrcH div AHeight;
    ToY := (ThumbY + 1) * SrcH div AHeight;
    if ToY <= FromY then
      ToY := FromY + 1;
    for ThumbX := 0 to AWidth - 1 do
    begin
      FromX := ThumbX * SrcW div AWidth;
      ToX := (ThumbX + 1) * SrcW div AWidth;
      if ToX <= FromX then
        ToX := FromX + 1;
      SumRed := 0;
      SumGreen := 0;
      SumBlue := 0;
      Count := 0;
      for SrcY := FromY to ToY - 1 do
        for SrcX := FromX to ToX - 1 do
        begin
          // строки в файле снизу вверх; Data - с единицы
          PixelPos := DataOffset + (SrcH - 1 - SrcY) * RowBytes + SrcX * 3 + 1;
          Inc(SumBlue, Byte(Data[PixelPos]));
          Inc(SumGreen, Byte(Data[PixelPos + 1]));
          Inc(SumRed, Byte(Data[PixelPos + 2]));
          Inc(Count);
        end;
      Result.Canvas.Pixels[ThumbX, ThumbY] := TColor((SumRed div Cardinal(Count)) or
        ((SumGreen div Cardinal(Count)) shl 8) or ((SumBlue div Cardinal(Count)) shl 16));
    end;
  end;
end;

end.
