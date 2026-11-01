unit LazPrep;

// ---------------------------------------------------------------------------
//  Шаг 1.2 плана переноса на Lazarus: исходники проекта Delphi 7 -> папка
//  сборки Lazarus в UTF-8.
//
//  Исходники unIDE лежат в CP1251 (так их читает Delphi 7), а LCL ждёт
//  строки в UTF-8. Lazarus-сборка идёт из отдельной папки (обычно
//  <папка .dpr>\laz): туда копируются .pas, .inc, .dpr, .dfm с переводом
//  CP1251 -> UTF-8 и без изменений - .res, .rc, .manifest, .ico. Файлы
//  папки lazarus\ рядом с .dpr (свои .lpi, .lpr, .lpk) копируются в
//  корень папки сборки как есть.
//
//  Файл, который уже в UTF-8 (с меткой EF BB BF или только из правильных
//  последовательностей UTF-8), копируется без перевода. Скопированный
//  файл получает дату исходного; файл с той же датой и тем же размером
//  исходного второй раз не пишется - повторная подготовка переписывает
//  только изменённое. Файлы папки сборки, которых нет в исходной, не
//  удаляются (там же будут .lfm шага 1.4 и результаты lazbuild).
//
//  Без VCL и без WinAPI: собирается Delphi 7 и Free Pascal.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes;

type
  TLazPrepStats = record
    Converted: Integer;   // переведено CP1251 -> UTF-8
    Copied: Integer;      // скопировано как есть (UTF-8, ASCII, двоичные)
    Unchanged: Integer;   // уже есть с той же датой и размером
    Failed: Integer;      // не прочитан или не записан
  end;

// Перевод текста CP1251 -> UTF-8
function Cp1251ToUtf8(const AText: string): string;

// Текст уже в UTF-8: метка EF BB BF или есть байты > 127 и все они -
// правильные последовательности UTF-8. Только ASCII - False (переводить
// нечего, перевод ничего не изменит)
function LooksUtf8(const AText: string): Boolean;

// Подготовить папку сборки ADstDir из папки проекта ASrcDir. В ALog -
// строки отчёта (ошибки и итог), можно nil
function LazPrepSources(const ASrcDir, ADstDir: string; ALog: TStrings;
  var AStats: TLazPrepStats): Boolean;

const
  // Расширения, которые переводятся в UTF-8
  LazPrepTextExts: array[0..3] of string = ('.pas', '.inc', '.dpr', '.dfm');
  // Расширения, которые копируются как есть
  LazPrepCopyExts: array[0..3] of string = ('.res', '.rc', '.manifest',
                                             '.ico');
  // Папка рядом с .dpr со своими файлами Lazarus (.lpi, .lpr, .lpk)
  LazPrepTemplateDir = 'lazarus';

implementation

const
  // CP1251, байты $80..$BF -> Unicode ($98 в CP1251 не занят - как у
  // MultiByteToWideChar, U+0098). $C0..$FF - А..я, U+0410..U+044F
  Cp1251High: array[$80..$BF] of Word = (
    $0402, $0403, $201A, $0453, $201E, $2026, $2020, $2021,
    $20AC, $2030, $0409, $2039, $040A, $040C, $040B, $040F,
    $0452, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $0098, $2122, $0459, $203A, $045A, $045C, $045B, $045F,
    $00A0, $040E, $045E, $0408, $00A4, $0490, $00A6, $00A7,
    $0401, $00A9, $0404, $00AB, $00AC, $00AD, $00AE, $0407,
    $00B0, $00B1, $0406, $0456, $0491, $00B5, $00B6, $00B7,
    $0451, $2116, $0454, $00BB, $0458, $0405, $0455, $0457);

function Cp1251ToUtf8(const AText: string): string;
var
  SrcIdx, DstIdx, CodePoint: Integer;
  ByteVal: Byte;
begin
  // В UTF-8 символ CP1251 - не больше трёх байт
  SetLength(Result, Length(AText) * 3);
  DstIdx := 0;
  for SrcIdx := 1 to Length(AText) do
  begin
    ByteVal := Byte(AText[SrcIdx]);
    if ByteVal < $80 then
    begin
      Inc(DstIdx);
      Result[DstIdx] := AText[SrcIdx];
      Continue;
    end;
    if ByteVal >= $C0 then
      CodePoint := $0410 + ByteVal - $C0
    else
      CodePoint := Cp1251High[ByteVal];
    if CodePoint < $800 then
    begin
      Result[DstIdx + 1] := Char($C0 or (CodePoint shr 6));
      Result[DstIdx + 2] := Char($80 or (CodePoint and $3F));
      Inc(DstIdx, 2);
    end
    else
    begin
      Result[DstIdx + 1] := Char($E0 or (CodePoint shr 12));
      Result[DstIdx + 2] := Char($80 or ((CodePoint shr 6) and $3F));
      Result[DstIdx + 3] := Char($80 or (CodePoint and $3F));
      Inc(DstIdx, 3);
    end;
  end;
  SetLength(Result, DstIdx);
end;

function LooksUtf8(const AText: string): Boolean;
var
  CharIdx, Tail, TailIdx: Integer;
  ByteVal: Byte;
  HasHigh: Boolean;
begin
  Result := False;
  if (Length(AText) >= 3) and (AText[1] = #$EF) and (AText[2] = #$BB) and
     (AText[3] = #$BF) then
  begin
    Result := True;
    Exit;
  end;
  HasHigh := False;
  CharIdx := 1;
  while CharIdx <= Length(AText) do
  begin
    ByteVal := Byte(AText[CharIdx]);
    if ByteVal < $80 then
    begin
      Inc(CharIdx);
      Continue;
    end;
    HasHigh := True;
    // Ведущий байт: 110xxxxx - ещё один, 1110xxxx - два, 11110xxx - три
    if (ByteVal and $E0) = $C0 then
      Tail := 1
    else if (ByteVal and $F0) = $E0 then
      Tail := 2
    else if (ByteVal and $F8) = $F0 then
      Tail := 3
    else
      Exit;
    // Слишком короткая запись (C0, C1 - ASCII двумя байтами)
    if (Tail = 1) and (ByteVal < $C2) then
      Exit;
    if CharIdx + Tail > Length(AText) then
      Exit;
    for TailIdx := 1 to Tail do
      if (Byte(AText[CharIdx + TailIdx]) and $C0) <> $80 then
        Exit;
    Inc(CharIdx, Tail + 1);
  end;
  Result := HasHigh;
end;

function ReadFileText(const AFileName: string; var AText: string): Boolean;
var
  Stream: TFileStream;
begin
  Result := False;
  AText := '';
  try
    Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(AText, Stream.Size);
      if Stream.Size > 0 then
        Stream.ReadBuffer(AText[1], Stream.Size);
      Result := True;
    finally
      Stream.Free;
    end;
  except
    AText := '';
  end;
end;

function WriteFileText(const AFileName, AText: string): Boolean;
var
  Stream: TFileStream;
begin
  Result := False;
  try
    Stream := TFileStream.Create(AFileName, fmCreate);
    try
      if AText <> '' then
        Stream.WriteBuffer(AText[1], Length(AText));
      Result := True;
    finally
      Stream.Free;
    end;
  except
    // нет доступа, файл занят
  end;
end;

function FileSizeOf(const AFileName: string): Int64;
var
  SearchRec: TSearchRec;
begin
  Result := -1;
  if FindFirst(AFileName, faAnyFile, SearchRec) = 0 then
  begin
    Result := SearchRec.Size;
    FindClose(SearchRec);
  end;
end;

function ExtIn(const AExt: string; const AList: array of string): Boolean;
var
  ExtIdx: Integer;
begin
  Result := False;
  for ExtIdx := Low(AList) to High(AList) do
    if SameText(AExt, AList[ExtIdx]) then
    begin
      Result := True;
      Exit;
    end;
end;

// Один файл. AConvert - переводить CP1251 -> UTF-8 (если он не в UTF-8)
procedure PrepFile(const ASrc, ADst: string; AConvert: Boolean;
  ALog: TStrings; var AStats: TLazPrepStats);
var
  SrcText, OutText: string;
  SrcAge, DstAge: Integer;
  Converted: Boolean;
begin
  SrcAge := FileAge(ASrc);
  if FileExists(ADst) then
  begin
    DstAge := FileAge(ADst);
    // Та же дата: файл не менялся с прошлой подготовки. Размер сверяется
    // только у копий без перевода (у переведённого он другой)
    if (DstAge = SrcAge) and
       (AConvert or (FileSizeOf(ADst) = FileSizeOf(ASrc))) then
    begin
      Inc(AStats.Unchanged);
      Exit;
    end;
  end;
  if not ReadFileText(ASrc, SrcText) then
  begin
    Inc(AStats.Failed);
    if ALog <> nil then
      ALog.Add('не прочитан: ' + ASrc);
    Exit;
  end;
  Converted := AConvert and not LooksUtf8(SrcText);
  if Converted then
    OutText := Cp1251ToUtf8(SrcText)
  else
    OutText := SrcText;
  if not WriteFileText(ADst, OutText) then
  begin
    Inc(AStats.Failed);
    if ALog <> nil then
      ALog.Add('не записан: ' + ADst);
    Exit;
  end;
  if SrcAge <> -1 then
    FileSetDate(ADst, SrcAge);
  if Converted then
    Inc(AStats.Converted)
  else
    Inc(AStats.Copied);
end;

function LazPrepSources(const ASrcDir, ADstDir: string; ALog: TStrings;
  var AStats: TLazPrepStats): Boolean;
var
  SrcDir, DstDir, TplDir, Ext: string;
  SearchRec: TSearchRec;
begin
  FillChar(AStats, SizeOf(AStats), 0);
  Result := False;
  SrcDir := IncludeTrailingPathDelimiter(ASrcDir);
  DstDir := IncludeTrailingPathDelimiter(ADstDir);
  if not DirectoryExists(SrcDir) then
  begin
    if ALog <> nil then
      ALog.Add('нет папки проекта: ' + SrcDir);
    Exit;
  end;
  if SameText(ExpandFileName(SrcDir), ExpandFileName(DstDir)) then
  begin
    if ALog <> nil then
      ALog.Add('папка сборки совпадает с папкой проекта: ' + DstDir);
    Exit;
  end;
  if not ForceDirectories(DstDir) then
  begin
    if ALog <> nil then
      ALog.Add('не создана папка сборки: ' + DstDir);
    Exit;
  end;

  if FindFirst(SrcDir + '*', faAnyFile, SearchRec) = 0 then
  try
    repeat
      if (SearchRec.Attr and faDirectory) <> 0 then
        Continue;
      Ext := ExtractFileExt(SearchRec.Name);
      if ExtIn(Ext, LazPrepTextExts) then
        PrepFile(SrcDir + SearchRec.Name, DstDir + SearchRec.Name, True,
                 ALog, AStats)
      else if ExtIn(Ext, LazPrepCopyExts) then
        PrepFile(SrcDir + SearchRec.Name, DstDir + SearchRec.Name, False,
                 ALog, AStats);
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;

  // Свои файлы Lazarus - в корень папки сборки, как есть
  TplDir := SrcDir + LazPrepTemplateDir + PathDelim;
  if FindFirst(TplDir + '*', faAnyFile, SearchRec) = 0 then
  try
    repeat
      if (SearchRec.Attr and faDirectory) = 0 then
        PrepFile(TplDir + SearchRec.Name, DstDir + SearchRec.Name, False,
                 ALog, AStats);
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
  Result := AStats.Failed = 0;
end;

end.
