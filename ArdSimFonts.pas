unit ArdSimFonts;

// ---------------------------------------------------------------------------
//  Шрифты UTFT для сборки эмулятора (ArdSim): какие .c из папок libraries
//  дать build_sim.cmd.
//
//  Нужные шрифты - имена из объявлений extern ... Имя[] в .ino, .h, .cpp, .c
//  папки скетча (комментарии не в счёт). Уже есть - массивы .c папки
//  скетча и папки %ARDSIM_FONTS%: их build_sim.cmd собирает сам.
//  Остальные ищутся в папках libraries (ARoots) со всеми вложенными
//  папками: первый .c, где есть массив-шрифт с этим именем. Порядок - как
//  в ARoots, в папке сначала файлы, потом вложенные папки, всё по имени.
//  Файл с массивом, который уже есть (другой файл того же шрифта), не
//  берётся: линкер выдал бы повторное определение.
//
//  Список - <папка скетча>\ardsim_build\ardsim_fonts.txt, по пути в
//  строке; build_sim.cmd собирает эти файлы вместо DefaultFonts.c из
//  Documents. Что не нашлось - замены из ArdSim\fonts, как раньше.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, StrUtils,
  DlgFontViewer;   // UtftParseFile, TUtftFont

const
  ArdSimFontListName = 'ardsim_fonts.txt';

// AList - выбранные файлы; ALog - строки для журнала. AEnvFontsDir -
// %ARDSIM_FONTS% ('' - нет)
procedure ArdSimPickFonts(const ASketchFile: string; ARoots: TStrings;
  const AEnvFontsDir: string; AList, ALog: TStrings);

// Выбрать шрифты и записать список рядом со сборкой; результат - имя
// списка ('' - не записан)
function ArdSimWriteFontList(const ASketchFile: string; ARoots: TStrings;
  ALog: TStrings): string;

implementation

const
  // Больше - не шрифт (или не стоит читать целиком)
  MaxFontFileSize = 8 * 1024 * 1024;

function IsIdentChar(ACh: Char): Boolean;
begin
  Result := ACh in ['A'..'Z', 'a'..'z', '0'..'9', '_'];
end;

// Комментарии - пробелами
function StripComments(const ASrc: string): string;
var
  Index, SrcLen: Integer;
begin
  Result := ASrc;
  SrcLen := Length(Result);
  Index := 1;
  while Index <= SrcLen do
  begin
    if (Result[Index] = '/') and (Index < SrcLen) and (Result[Index + 1] = '/') then
    begin
      while (Index <= SrcLen) and (Result[Index] <> #10) do
      begin
        Result[Index] := ' ';
        Inc(Index);
      end;
    end
    else if (Result[Index] = '/') and (Index < SrcLen) and (Result[Index + 1] = '*') then
    begin
      while (Index <= SrcLen) and
            not ((Result[Index] = '*') and (Index < SrcLen) and (Result[Index + 1] = '/')) do
      begin
        if Result[Index] <> #10 then
          Result[Index] := ' ';
        Inc(Index);
      end;
      if Index < SrcLen then
      begin
        Result[Index] := ' ';
        Result[Index + 1] := ' ';
      end;
      Inc(Index, 2);
    end
    else
      Inc(Index);
  end;
end;

function ReadText(const AFileName: string): string;
var
  Stream: TFileStream;
begin
  Result := '';
  try
    Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      if Stream.Size > MaxFontFileSize then
        Exit;
      SetLength(Result, Stream.Size);
      if Stream.Size > 0 then
        Stream.ReadBuffer(Result[1], Stream.Size);
    finally
      Stream.Free;
    end;
  except
    Result := '';
  end;
end;

// Имена из extern <тип байт> Имя[] в тексте
procedure CollectExterns(const AText: string; ANames: TStrings);
var
  Src, Decl, LowerDecl, Name: string;
  Found, DeclEnd, Bracket, NameEnd, NameStart: Integer;
begin
  Src := StripComments(AText);
  Found := 0;
  while True do
  begin
    Found := PosEx('extern', Src, Found + 1);
    if Found = 0 then
      Break;
    if ((Found > 1) and IsIdentChar(Src[Found - 1])) or
       ((Found + 6 <= Length(Src)) and IsIdentChar(Src[Found + 6])) then
      Continue;
    DeclEnd := Found;
    while (DeclEnd <= Length(Src)) and not (Src[DeclEnd] in [';', '{', '(']) do
      Inc(DeclEnd);
    Decl := Copy(Src, Found, DeclEnd - Found);
    Found := DeclEnd;
    Bracket := Pos('[', Decl);
    if Bracket = 0 then
      Continue;
    LowerDecl := LowerCase(Copy(Decl, 1, Bracket));
    if (Pos('uint8_t', LowerDecl) = 0) and (Pos('char', LowerDecl) = 0) and
       (Pos('byte', LowerDecl) = 0) and (Pos('fontdatatype', LowerDecl) = 0) then
      Continue;
    NameEnd := Bracket - 1;
    while (NameEnd > 0) and not IsIdentChar(Decl[NameEnd]) do
      Dec(NameEnd);
    NameStart := NameEnd;
    while (NameStart > 1) and IsIdentChar(Decl[NameStart - 1]) do
      Dec(NameStart);
    if NameEnd < 1 then
      Continue;
    Name := Copy(Decl, NameStart, NameEnd - NameStart + 1);
    if ANames.IndexOf(Name) < 0 then
      ANames.Add(Name);
  end;
end;

// Имена всех массивов .c-файла
procedure CollectArrays(const AFileName: string; ANames: TStrings;
  AFontsOnly: Boolean);
var
  Fonts: TList;
  Index: Integer;
  FontItem: TUtftFont;
begin
  Fonts := TList.Create;
  try
    UtftParseFile(AFileName, Fonts);
    for Index := 0 to Fonts.Count - 1 do
    begin
      FontItem := TUtftFont(Fonts[Index]);
      if (not AFontsOnly or FontItem.IsFont) and
         (ANames.IndexOf(FontItem.Name) < 0) then
        ANames.Add(FontItem.Name);
      FontItem.Free;
    end;
  finally
    Fonts.Free;
  end;
end;

// Файлы папки по маске (без вложенных), по имени
procedure ListFiles(const AFolder, AMask: string; AFiles: TStrings);
var
  Search: TSearchRec;
  Names: TStringList;
begin
  Names := TStringList.Create;
  try
    if FindFirst(IncludeTrailingPathDelimiter(AFolder) + AMask, faAnyFile,
       Search) = 0 then
    begin
      repeat
        if (Search.Attr and faDirectory) = 0 then
          Names.Add(IncludeTrailingPathDelimiter(AFolder) + Search.Name);
      until FindNext(Search) <> 0;
      FindClose(Search);
    end;
    Names.Sort;
    AFiles.AddStrings(Names);
  finally
    Names.Free;
  end;
end;

// Все .c папки и вложенных: сначала файлы папки, потом папки по имени
procedure ListFilesDeep(const AFolder: string; AFiles: TStrings; ADepth: Integer);
var
  Search: TSearchRec;
  Dirs: TStringList;
  Index: Integer;
begin
  if ADepth > 12 then
    Exit;
  ListFiles(AFolder, '*.c', AFiles);
  Dirs := TStringList.Create;
  try
    if FindFirst(IncludeTrailingPathDelimiter(AFolder) + '*', faAnyFile,
       Search) = 0 then
    begin
      repeat
        if ((Search.Attr and faDirectory) <> 0) and (Search.Name <> '.') and
           (Search.Name <> '..') and (Search.Name[1] <> '.') then
          Dirs.Add(IncludeTrailingPathDelimiter(AFolder) + Search.Name);
      until FindNext(Search) <> 0;
      FindClose(Search);
    end;
    Dirs.Sort;
    for Index := 0 to Dirs.Count - 1 do
      ListFilesDeep(Dirs[Index], AFiles, ADepth + 1);
  finally
    Dirs.Free;
  end;
end;

// Есть ли в тексте имя отдельным словом
function HasIdent(const AText, AName: string): Boolean;
var
  Start, Found: Integer;
begin
  Result := False;
  Start := 1;
  repeat
    Found := PosEx(AName, AText, Start);
    if Found = 0 then
      Exit;
    if ((Found = 1) or not IsIdentChar(AText[Found - 1])) and
       ((Found + Length(AName) > Length(AText)) or
        not IsIdentChar(AText[Found + Length(AName)])) then
    begin
      Result := True;
      Exit;
    end;
    Start := Found + 1;
  until False;
end;

procedure ArdSimPickFonts(const ASketchFile: string; ARoots: TStrings;
  const AEnvFontsDir: string; AList, ALog: TStrings);
var
  SketchDir, Text, Root: string;
  Needed, Provided, SketchFiles, Candidates, FileNames: TStringList;
  FileIdx, NameIdx, RootIdx, Conflict: Integer;
  Wanted: Boolean;
begin
  SketchDir := ExtractFilePath(ASketchFile);
  Needed := TStringList.Create;
  Provided := TStringList.Create;
  SketchFiles := TStringList.Create;
  Candidates := TStringList.Create;
  FileNames := TStringList.Create;
  try
    // Что объявлено в скетче
    ListFiles(SketchDir, '*.ino', SketchFiles);
    ListFiles(SketchDir, '*.h', SketchFiles);
    ListFiles(SketchDir, '*.cpp', SketchFiles);
    for FileIdx := 0 to SketchFiles.Count - 1 do
      CollectExterns(ReadText(SketchFiles[FileIdx]), Needed);
    // Что уже есть: .c папки скетча, %ARDSIM_FONTS%
    SketchFiles.Clear;
    ListFiles(SketchDir, '*.c', SketchFiles);
    if AEnvFontsDir <> '' then
      ListFiles(AEnvFontsDir, '*.c', SketchFiles);
    for FileIdx := 0 to SketchFiles.Count - 1 do
      CollectArrays(SketchFiles[FileIdx], Provided, False);
    for NameIdx := Needed.Count - 1 downto 0 do
      if Provided.IndexOf(Needed[NameIdx]) >= 0 then
        Needed.Delete(NameIdx);
    if Needed.Count = 0 then
      Exit;

    for RootIdx := 0 to ARoots.Count - 1 do
    begin
      Root := ExcludeTrailingPathDelimiter(ARoots[RootIdx]);
      if (Root = '') or not DirectoryExists(Root) then
        Continue;
      Candidates.Clear;
      ListFilesDeep(Root, Candidates, 0);
      for FileIdx := 0 to Candidates.Count - 1 do
      begin
        if Needed.Count = 0 then
          Break;
        if AList.IndexOf(Candidates[FileIdx]) >= 0 then
          Continue;
        Text := ReadText(Candidates[FileIdx]);
        Wanted := False;
        for NameIdx := 0 to Needed.Count - 1 do
          if HasIdent(Text, Needed[NameIdx]) then
          begin
            Wanted := True;
            Break;
          end;
        if not Wanted then
          Continue;
        // Шрифты файла; нужен ли какой-то из них
        FileNames.Clear;
        CollectArrays(Candidates[FileIdx], FileNames, True);
        Wanted := False;
        for NameIdx := 0 to FileNames.Count - 1 do
          if Needed.IndexOf(FileNames[NameIdx]) >= 0 then
            Wanted := True;
        if not Wanted then
          Continue;
        // Все массивы файла - не должны повторять уже взятые
        FileNames.Clear;
        CollectArrays(Candidates[FileIdx], FileNames, False);
        Conflict := -1;
        for NameIdx := 0 to FileNames.Count - 1 do
          if Provided.IndexOf(FileNames[NameIdx]) >= 0 then
          begin
            Conflict := NameIdx;
            Break;
          end;
        if Conflict >= 0 then
        begin
          ALog.Add('ArdSim: шрифты - пропущен ' + Candidates[FileIdx] + ': ' +
            FileNames[Conflict] + ' уже взят из другого файла');
          Continue;
        end;
        AList.Add(Candidates[FileIdx]);
        Provided.AddStrings(FileNames);
        for NameIdx := Needed.Count - 1 downto 0 do
          if FileNames.IndexOf(Needed[NameIdx]) >= 0 then
          begin
            ALog.Add('ArdSim: шрифт ' + Needed[NameIdx] + ' - ' +
              Candidates[FileIdx]);
            Needed.Delete(NameIdx);
          end;
      end;
    end;
    for NameIdx := 0 to Needed.Count - 1 do
      ALog.Add('ArdSim: шрифт ' + Needed[NameIdx] + ' не найден в libraries - ' +
        'будет замена из ArdSim\fonts (если она есть)');
  finally
    Needed.Free;
    Provided.Free;
    SketchFiles.Free;
    Candidates.Free;
    FileNames.Free;
  end;
end;

// Путь для cmd (for /f читает список в кодовой странице OEM): с буквами
// не ASCII - короткое имя 8.3
function CmdSafePath(const APath: string): string;
var
  Index: Integer;
  Ascii: Boolean;
begin
  Result := APath;
  Ascii := True;
  for Index := 1 to Length(APath) do
    if Ord(APath[Index]) > 127 then
      Ascii := False;
  {$IFNDEF UNIX}
  if not Ascii then
    Result := ExtractShortPathName(APath);
  if Result = '' then
    Result := APath;
  {$ENDIF}
end;

function ArdSimWriteFontList(const ASketchFile: string; ARoots: TStrings;
  ALog: TStrings): string;
var
  Files, Lines: TStringList;
  OutDir: string;
  Index: Integer;
begin
  Result := '';
  OutDir := ExtractFilePath(ASketchFile) + 'ardsim_build';
  if not ForceDirectories(OutDir) then
    Exit;
  Files := TStringList.Create;
  Lines := TStringList.Create;
  try
    ArdSimPickFonts(ASketchFile, ARoots, SysUtils.GetEnvironmentVariable('ARDSIM_FONTS'),
      Files, ALog);
    for Index := 0 to Files.Count - 1 do
      Lines.Add(CmdSafePath(Files[Index]));
    Result := IncludeTrailingPathDelimiter(OutDir) + ArdSimFontListName;
    try
      Lines.SaveToFile(Result);
    except
      Result := '';
    end;
  finally
    Files.Free;
    Lines.Free;
  end;
end;

end.
