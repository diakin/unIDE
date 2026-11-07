unit SchemeData;

// ---------------------------------------------------------------------------
//  Правка схемы подсветки без окон: подписи разделов, есть ли у раздела
//  цвета и строка данных, чтение и запись строки данных, загрузка схемы для
//  правки, список схем и соответствия расширений (schemes\alias.ini).
//
//  Сделано по окну IDE Options unIDE (Unit2: SectionCaption,
//  SectionHasColors, IsHiddenSection, RefreshGridFromForm1,
//  ApplyGridToForm1; Unit1: LoadCustomClrSchema, LoadSchemaFileForEdit,
//  SchemeAliasRows, SchemeAliasSet). Нужно окну F9 - Schemes в uniFAR.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$CODEPAGE CP1251}{$ENDIF}

interface

uses
  SysUtils, Classes, IniFiles, Graphics, ClrScheme, SchemeFiles;

// Подпись раздела; незнакомый раздел - своим именем из файла
function SchemeSectionCaption(const AName: string): string;
// У разделов слов (SubList, Fmt*, TagVoid ...) цветов нет
function SchemeSectionHasColors(const AName: string): Boolean;
// Fmt* и Tag* в списке не показываются (в файле остаются)
function SchemeSectionHidden(const AName: string): Boolean;
// Строка данных раздела. False - у раздела её нет или она не правится
// (Text, SubBody, Components, PairMark, CUSTOMn)
function SchemeSectionData(AScheme: TClrScheme; const AName: string;
  var AData: string): Boolean;
procedure SchemeSetSectionData(AScheme: TClrScheme; const AName,
  AData: string);
// Подсказка над полем строки данных раздела
function SchemeSectionHint(const AName: string): string;
// Схема для правки. AKey = '' - •default•.clr одна; иначе •default•.clr и
// <AKey>.clr, порядок разделов - схемы расширения (как LoadCustomClrSchema
// unIDE). Записывать - SaveClrSchemaTo в SchemeEditPath. nil - не прочитана.
function SchemeLoadForEdit(const ASchemesDir, AKey, ATheme: string;
  AFontColor, ABgColor: TColor): TClrScheme;
function SchemeEditPath(const ASchemesDir, AKey: string): string;
// Имена схем папки (без .clr, без •default•), по алфавиту
procedure SchemeNameList(const ASchemesDir: string; AList: TStrings);
// Соответствия расширений: строки 'ext=схема'#9'откуда', по алфавиту
// (alias.ini, встроенные, свои ext.clr)
procedure SchemeAliasRows(const ASchemesDir: string; ARows: TStrings);
// Записать ext=схема в alias.ini; AScheme = '' - удалить строку
function SchemeAliasSet(const ASchemesDir, AExt, AScheme: string): Boolean;

const
  // Откуда соответствие (вторая часть строки SchemeAliasRows)
  SchemeFromAlias = 'alias.ini';
  SchemeFromBuiltin = 'встроенное';
  SchemeFromOwn = 'своя схема';

implementation

function StartsWith(const AName, APrefix: string): Boolean;
begin
  Result := (Length(AName) >= Length(APrefix)) and
    (Copy(AName, 1, Length(APrefix)) = APrefix);
end;

function SchemeSectionCaption(const AName: string): string;
var
  Num: Integer;
begin
  if AName = 'Operators' then
    Result := 'Operators'
  else if StartsWith(AName, 'Operators') then
    Result := 'Operators ' + Copy(AName, 10, MaxInt)
  else if AName = 'LineComment' then
    Result := 'Line Comment'
  else if AName = 'BlockComment' then
    Result := 'Block Comment'
  else if StartsWith(AName, 'BlockComment') then
    Result := 'Block Comment ' + Copy(AName, 13, MaxInt)
  else if AName = 'Strings' then
    Result := 'Strings'
  else if StartsWith(AName, 'Strings') then
    Result := 'Strings ' + Copy(AName, 8, MaxInt)
  else if AName = 'StrEscape' then
    Result := 'String escape char'
  else if AName = 'Digits' then
    Result := 'Digits (Numbers)'
  else if AName = 'Text' then
    Result := 'Text'
  else if AName = 'LineMark' then
    Result := 'Line Mark'
  else if StartsWith(AName, 'LineMark') then
    Result := 'Line Mark ' + Copy(AName, 9, MaxInt)
  else if AName = 'SubBody' then
    Result := 'Sub Body (header line)'
  else if AName = 'Components' then
    Result := 'Components (form objects)'
  else if AName = 'SubList' then
    Result := 'Sub List (begin words)'
  else if AName = 'SubEnd' then
    Result := 'Sub End (end words)'
  else if AName = 'SubOpen' then
    Result := 'Sub Open (block words)'
  else if AName = 'SubNoBody' then
    Result := 'Sub No Body (declaration words)'
  else if AName = 'SubOpenFirst' then
    Result := 'Sub Open First (line start only)'
  else if AName = 'SubSkip' then
    Result := 'Sub Skip (line start modifiers)'
  else if AName = 'SubStyle' then
    Result := 'Sub Style (words/braces)'
  else if AName = 'SubScope' then
    Result := 'Sub Scope (search below)'
  else if AName = 'PairMark' then
    Result := 'Pair Mark (bracket under caret)'
  else if StartsWith(AName, 'CUSTOM') and (Length(AName) > 6) then
  begin
    Num := StrToIntDef(Copy(AName, 7, 1), 0);
    if (Num >= 1) and (Num <= 5) then
      Result := 'Custom Comment (' + StringOfChar('!', Num) + ')'
    else
      Result := AName;
  end
  else
    Result := AName;
end;

function SchemeSectionHasColors(const AName: string): Boolean;
begin
  Result := (AName <> '') and (AName <> 'SubList') and (AName <> 'SubEnd') and
            (AName <> 'SubStyle') and (AName <> 'SubScope') and
            (AName <> 'SubOpen') and (AName <> 'SubNoBody') and
            (AName <> 'SubOpenFirst') and (AName <> 'SubSkip') and
            not StartsWith(AName, 'Fmt') and (AName <> 'TagVoid') and
            (AName <> 'StrEscape');
end;

function SchemeSectionHidden(const AName: string): Boolean;
begin
  Result := StartsWith(AName, 'Fmt') or StartsWith(AName, 'Tag');
end;

// Список слов раздела Sub*, Fmt*, TagVoid; nil - не такой раздел
function WordList(AScheme: TClrScheme; const AName: string): TStringList;
begin
  Result := nil;
  if AName = 'SubList' then
    Result := AScheme.FSubWords
  else if AName = 'SubEnd' then
    Result := AScheme.FSubEndWords
  else if AName = 'SubOpen' then
    Result := AScheme.FSubOpenWords
  else if AName = 'SubNoBody' then
    Result := AScheme.FSubNoBodyWords
  else if AName = 'SubOpenFirst' then
    Result := AScheme.FSubOpenFirst
  else if AName = 'SubSkip' then
    Result := AScheme.FSubSkip
  else if AName = 'FmtOutdent' then
    Result := AScheme.FFmtOutdent
  else if AName = 'FmtSection' then
    Result := AScheme.FFmtSection
  else if AName = 'FmtClass' then
    Result := AScheme.FFmtClass
  else if AName = 'FmtHang' then
    Result := AScheme.FFmtHang
  else if AName = 'FmtStmtEnd' then
    Result := AScheme.FFmtStmtEnd
  else if AName = 'FmtContinue' then
    Result := AScheme.FFmtContinue
  else if AName = 'FmtHangFirst' then
    Result := AScheme.FFmtHangFirst
  else if AName = 'FmtLabel' then
    Result := AScheme.FFmtLabel
  else if AName = 'TagVoid' then
    Result := AScheme.FTagVoid;
end;

function KeywordIndex(AScheme: TClrScheme; const AName: string): Integer;
var
  GrpIdx: Integer;
begin
  Result := -1;
  for GrpIdx := 0 to High(AScheme.KeywordGroups) do
    if (AScheme.KeywordGroups[GrpIdx].Words <> nil) and
       (CompareText(AScheme.KeywordGroups[GrpIdx].Name, AName) = 0) then
    begin
      Result := GrpIdx;
      Exit;
    end;
end;

function SchemeSectionData(AScheme: TClrScheme; const AName: string;
  var AData: string): Boolean;
var
  GrpIdx: Integer;
  Words: TStringList;
begin
  Result := True;
  AData := '';
  Words := WordList(AScheme, AName);
  if Words <> nil then
  begin
    AData := WordsByComma(Words);
    Exit;
  end;
  if AName = 'FmtContinueFirst' then
    AData := WordsBySpace(AScheme.FFmtContinueFirst)
  else if IsKeywordSection(AName) then
  begin
    GrpIdx := KeywordIndex(AScheme, AName);
    Result := GrpIdx >= 0;
    if Result then
      AData := AScheme.KeywordGroups[GrpIdx].Words.CommaText;
  end
  else if StartsWith(AName, 'Operators') then
  begin
    GrpIdx := AScheme.OpGroupIndex(AName);
    Result := GrpIdx >= 0;
    if Result then
      AData := AScheme.OpCharsStr(GrpIdx);
  end
  else if AName = 'LineComment' then
    AData := AScheme.LineCommentSchemeText
  else if AName = 'BlockComment' then
    AData := AScheme.FBlockCommentStart + ' ' + AScheme.FBlockCommentEnd
  else if StartsWith(AName, 'BlockComment') then
  begin
    GrpIdx := AScheme.BcExtraIndex(AName);
    Result := GrpIdx >= 0;
    if Result then
      AData := AScheme.FBcExtra[GrpIdx].StartMark + ' ' +
        AScheme.FBcExtra[GrpIdx].EndMark;
  end
  else if AName = 'Strings' then
    AData := AScheme.FStringMarker
  else if StartsWith(AName, 'Strings') then
  begin
    GrpIdx := AScheme.StrExtraIndex(AName);
    Result := GrpIdx >= 0;
    if Result then
      AData := AScheme.FStrExtra[GrpIdx].StartMark;
  end
  else if AName = 'Digits' then
    AData := AScheme.BuildDigitFormats
  else if StartsWith(AName, 'LineMark') then
  begin
    GrpIdx := AScheme.MarkGroupIndex(AName);
    Result := (GrpIdx >= 0) and (AScheme.MarkGroups[GrpIdx].Words <> nil);
    if Result then
      AData := WordsByComma(AScheme.MarkGroups[GrpIdx].Words);
  end
  else if AName = 'StrEscape' then
  begin
    if AScheme.FStrEscape <> #0 then
      AData := AScheme.FStrEscape;
  end
  else if AName = 'SubStyle' then
  begin
    if AScheme.FSubTags then
      AData := 'tags'
    else if AScheme.FSubBraces then
      AData := 'braces'
    else
      AData := 'words';
  end
  else if AName = 'SubScope' then
    AData := AScheme.FSubScope
  else
    Result := False;
end;

procedure SchemeSetSectionData(AScheme: TClrScheme; const AName,
  AData: string);
var
  GrpIdx: Integer;
  Words: TStringList;
  StyleText: string;
begin
  Words := WordList(AScheme, AName);
  if Words <> nil then
  begin
    SetWordsByComma(Words, AData, True);
    Exit;
  end;
  if AName = 'FmtContinueFirst' then
    SetWordsBySpace(AScheme.FFmtContinueFirst, AData)
  else if IsKeywordSection(AName) then
  begin
    GrpIdx := KeywordIndex(AScheme, AName);
    if GrpIdx >= 0 then
      AScheme.KeywordGroups[GrpIdx].Words.CommaText := AData;
  end
  else if StartsWith(AName, 'Operators') then
  begin
    GrpIdx := AScheme.OpGroupIndex(AName);
    if GrpIdx >= 0 then
      AScheme.SetOpChars(GrpIdx, AData);
  end
  // Маркеры - как есть, без Trim: пробелы в маркере допустимы
  else if AName = 'LineComment' then
    AScheme.SetLineCommentSchemeText(AData)
  else if AName = 'BlockComment' then
    SplitMarkers(AData, AScheme.FBlockCommentStart, AScheme.FBlockCommentEnd)
  else if StartsWith(AName, 'BlockComment') then
  begin
    GrpIdx := AScheme.BcExtraIndex(AName);
    if GrpIdx >= 0 then
      SplitMarkers(AData, AScheme.FBcExtra[GrpIdx].StartMark,
        AScheme.FBcExtra[GrpIdx].EndMark);
  end
  else if AName = 'Strings' then
    AScheme.FStringMarker := AData
  else if StartsWith(AName, 'Strings') then
  begin
    GrpIdx := AScheme.StrExtraIndex(AName);
    if GrpIdx >= 0 then
    begin
      if Trim(AData) = 'none' then
        AScheme.FStrExtra[GrpIdx].StartMark := ''
      else
        AScheme.FStrExtra[GrpIdx].StartMark := Trim(AData);
      AScheme.FStrExtra[GrpIdx].EndMark := AScheme.FStrExtra[GrpIdx].StartMark;
    end;
  end
  else if AName = 'Digits' then
    AScheme.ParseDigitFormats(Trim(AData))
  else if StartsWith(AName, 'LineMark') then
  begin
    GrpIdx := AScheme.MarkGroupIndex(AName);
    if (GrpIdx >= 0) and (AScheme.MarkGroups[GrpIdx].Words <> nil) then
      SetWordsByComma(AScheme.MarkGroups[GrpIdx].Words, AData);
  end
  else if AName = 'StrEscape' then
  begin
    if Trim(AData) = '' then
      AScheme.FStrEscape := #0
    else
      AScheme.FStrEscape := Trim(AData)[1];
  end
  else if AName = 'SubStyle' then
  begin
    StyleText := LowerCase(Trim(AData));
    AScheme.FSubTags := StyleText = 'tags';
    AScheme.FSubBraces := StyleText = 'braces';
  end
  else if AName = 'SubScope' then
    AScheme.FSubScope := Trim(AData);
  AScheme.BuildMarkerChars;
end;

function SchemeSectionHint(const AName: string): string;
begin
  if IsKeywordSection(AName) or StartsWith(AName, 'LineMark') or
     StartsWith(AName, 'Sub') and (AName <> 'SubStyle') and
     (AName <> 'SubScope') or StartsWith(AName, 'Fmt') or
     (AName = 'TagVoid') then
    Result := 'Words, comma separated:'
  else if StartsWith(AName, 'Operators') then
    Result := 'Characters of the group:'
  else if AName = 'LineComment' then
    Result := 'Marker (^ before it - only at line start):'
  else if StartsWith(AName, 'BlockComment') then
    Result := 'Start and end markers, space separated:'
  else if StartsWith(AName, 'Strings') then
    Result := 'String marker:'
  else if AName = 'StrEscape' then
    Result := 'Escape character (empty - doubled marker):'
  else if AName = 'Digits' then
    Result := 'Number forms (0x, &H, exp, suffix=...):'
  else if AName = 'SubStyle' then
    Result := 'words, braces or tags:'
  else if AName = 'SubScope' then
    Result := 'Search subs below this word:'
  else
    Result := 'Value:';
end;

function SchemeEditPath(const ASchemesDir, AKey: string): string;
begin
  if AKey = '' then
    Result := SchemeDefaultPath(ASchemesDir)
  else
    Result := ASchemesDir + AKey + '.clr';
end;

function SchemeLoadForEdit(const ASchemesDir, AKey, ATheme: string;
  AFontColor, ABgColor: TColor): TClrScheme;
var
  DefaultPath, ClrPath: string;
  DefSections: TStringList;
  SecIdx: Integer;
begin
  Result := TClrScheme.Create;
  DefSections := TStringList.Create;
  try
    try
      Result.FTheme := ThemeKey(ATheme);
      Result.ResetSchemaState(AFontColor, ABgColor);
      DefaultPath := SchemeDefaultPath(ASchemesDir);
      if AKey = '' then
      begin
        // Одна схема, без умолчаний под ней - порядок разделов её
        if FileExists(DefaultPath) then
          Result.ParseClrFile(DefaultPath);
        Result.SchemaSections.Assign(Result.FFileSections);
      end
      else
      begin
        if FileExists(DefaultPath) then
        begin
          Result.ParseClrFile(DefaultPath);
          DefSections.Assign(Result.FFileSections);
          Result.ClearKeywordGroups; // ключевые слова - свои у языка
        end;
        ClrPath := ASchemesDir + AKey + '.clr';
        if FileExists(ClrPath) then
          Result.ParseClrFile(ClrPath)
        else
          Result.FFileSections.Clear;
        // Порядок - схемы расширения; разделы только из •default•.clr -
        // за ними (без групп ключевых слов)
        Result.SchemaSections.Assign(Result.FFileSections);
        for SecIdx := 0 to DefSections.Count - 1 do
          if not IsKeywordSection(DefSections[SecIdx]) and
             (Result.SchemaSections.IndexOf(DefSections[SecIdx]) < 0) then
            Result.SchemaSections.Add(DefSections[SecIdx]);
      end;
      Result.EnsureSchemaSection('PairMark');
      Result.ApplyTheme;
      Result.BuildMarkerChars;
    except
      FreeAndNil(Result);
    end;
  finally
    DefSections.Free;
  end;
end;

procedure SchemeNameList(const ASchemesDir: string; AList: TStrings);
var
  Found: TSearchRec;
  Names: TStringList;
  DefaultName: string;
begin
  Names := TStringList.Create;
  try
    Names.Sorted := True;
    Names.Duplicates := dupIgnore;
    DefaultName := ExtractFileName(SchemeDefaultPath(ASchemesDir));
    if FindFirst(ASchemesDir + '*.clr', faAnyFile, Found) = 0 then
    try
      repeat
        if (Found.Attr and faDirectory = 0) and
           (CompareText(Found.Name, DefaultName) <> 0) then
          Names.Add(LowerCase(ChangeFileExt(Found.Name, '')));
      until FindNext(Found) <> 0;
    finally
      FindClose(Found);
    end;
    AList.Assign(Names);
  finally
    Names.Free;
  end;
end;

procedure SchemeAliasRows(const ASchemesDir: string; ARows: TStrings);
var
  ExtName: string;
  Rows, IniKeys: TStringList;
  ItemIdx, SepPos: Integer;
  Ini: TIniFile;
begin
  ARows.Clear;
  Rows := TStringList.Create;
  IniKeys := TStringList.Create;
  try
    Rows.Sorted := True;
    Rows.Duplicates := dupIgnore;
    if FileExists(ASchemesDir + 'alias.ini') then
    begin
      Ini := TIniFile.Create(ASchemesDir + 'alias.ini');
      try
        Ini.ReadSection('Alias', IniKeys);
        for ItemIdx := 0 to IniKeys.Count - 1 do
        begin
          ExtName := LowerCase(Trim(IniKeys[ItemIdx]));
          if ExtName <> '' then
            Rows.Add(ExtName + '=' + LowerCase(Trim(Ini.ReadString('Alias',
              IniKeys[ItemIdx], ''))) + #9 + SchemeFromAlias);
        end;
      finally
        Ini.Free;
      end;
    end;
    for ItemIdx := Low(SchemeBuiltin) to High(SchemeBuiltin) do
    begin
      SepPos := Pos('=', SchemeBuiltin[ItemIdx]);
      ExtName := Copy(SchemeBuiltin[ItemIdx], 1, SepPos - 1);
      if Rows.IndexOfName(ExtName) < 0 then
        Rows.Add(SchemeBuiltin[ItemIdx] + #9 + SchemeFromBuiltin);
    end;
    SchemeNameList(ASchemesDir, IniKeys);
    for ItemIdx := 0 to IniKeys.Count - 1 do
      if Rows.IndexOfName(IniKeys[ItemIdx]) < 0 then
        Rows.Add(IniKeys[ItemIdx] + '=' + IniKeys[ItemIdx] + #9 +
          SchemeFromOwn);
    ARows.Assign(Rows);
  finally
    IniKeys.Free;
    Rows.Free;
  end;
end;

function SchemeAliasSet(const ASchemesDir, AExt, AScheme: string): Boolean;
var
  ExtName: string;
  Ini: TIniFile;
begin
  Result := False;
  ExtName := LowerCase(Trim(AExt));
  if (ExtName <> '') and (ExtName[1] = '.') then
    Delete(ExtName, 1, 1);
  if ExtName = '' then
    Exit;
  try
    ForceDirectories(ASchemesDir);
    Ini := TIniFile.Create(ASchemesDir + 'alias.ini');
    try
      if Trim(AScheme) = '' then
        Ini.DeleteKey('Alias', ExtName)
      else
        Ini.WriteString('Alias', ExtName, LowerCase(Trim(AScheme)));
      Ini.UpdateFile;
    finally
      Ini.Free;
    end;
    Result := True;
  except
    Result := False;
  end;
end;

end.
