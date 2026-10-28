unit SchemeFiles;

// ---------------------------------------------------------------------------
//  Схема подсветки для файла: какой .clr взять и чтение схемы - без окон,
//  общее для unIDE (Unit1) и uniFAR.
//
//  Папка схем (ASchemesDir, с '\' на конце): <расширение>.clr, файл
//  умолчаний •default•.clr (его разделы - основа любой схемы, ключевые
//  слова из него не берутся), alias.ini ([Alias] pp=pas - чужая схема для
//  расширения без своей).
//
//  Схема по расширению (SchemeKeyByExt): своя <ext>.clr; иначе alias.ini;
//  иначе .inc в проекте RapidQ Basic (AIncIsBasic) - bas; иначе встроенные
//  соответствия SchemeBuiltin. Своя схема всегда важнее соответствия.
//  .inc без своей inc.clr и без inc= в alias.ini - по тексту файла
//  (SchemeGuessIncText: Basic или Паскаль).
//
//  Схема для показа (SchemeLoadFromDir): •default•.clr, затем схема ключа,
//  затем цвета выбранной темы (ApplyTheme). Тема - имя из editor.ini
//  [Themes] Current (ThemeKey: основная тема - '').
// ---------------------------------------------------------------------------

// Free Pascal (uniFAR): исходник в кодировке Windows-1251 - строки с
// кириллицей в WideString без кракозябр. Delphi 7 эту строку пропускает
{$IFDEF FPC}{$CODEPAGE CP1251}{$ENDIF}

interface

uses
  SysUtils, Classes, IniFiles, Graphics, ClrScheme;

const
  // Встроенные соответствия. Паскаль: Delphi, Free Pascal, Lazarus
  SchemeBuiltin: array[0..11] of string = (
    'dpr=pas', 'dpk=pas', 'pp=pas', 'p=pas', 'lpr=pas', 'inc=pas',
    'lfm=dfm',                         // форма Lazarus - текст того же вида
    'lpi=xml', 'lps=xml', 'lpk=xml',   // проект, сеанс и пакет Lazarus - XML
    'fpd=xml',
    'toml=ini');                       // Cargo.toml - те же [разделы]

// schemes\•default•.clr
function SchemeDefaultPath(const ASchemesDir: string): string;
// Ключ схемы (имя .clr без расширения) по расширению AExt ('.pas' или 'pas')
function SchemeKeyByExt(const ASchemesDir, AExt: string;
  AIncIsBasic: Boolean): string;
// Есть ли для .inc своя inc.clr или строка inc= в alias.ini
function SchemeIncHasOwn(const ASchemesDir: string): Boolean;
// Текст .inc: 'bas', 'pas' или '' (не понять)
function SchemeGuessIncText(const AText: string): string;
// То же по файлу (первые 64 КБ); '' - не прочитать или не понять
function SchemeGuessIncFile(const AFile: string): string;
// Ключ схемы для файла: .inc без своей схемы - по тексту, иначе по
// расширению (без выбора схемы для отдельного файла - это у unIDE своё)
function SchemeKeyForFile(const ASchemesDir, AFile: string;
  AIncIsBasic: Boolean): string;
// Схема ключа AKey: умолчания, схема, тема. Освобождает вызвавший; nil -
// не прочиталась
function SchemeLoadFromDir(const ASchemesDir, AKey, ATheme: string;
  AFontColor, ABgColor: TColor): TClrScheme;

implementation

function SchemeDefaultPath(const ASchemesDir: string): string;
begin
  Result := ASchemesDir + #149 + 'default' + #149 + '.clr';
end;

function SchemeAliasOf(const ASchemesDir, AExtName: string): string;
var
  Ini: TIniFile;
begin
  Result := '';
  if not FileExists(ASchemesDir + 'alias.ini') then
    Exit;
  Ini := TIniFile.Create(ASchemesDir + 'alias.ini');
  try
    Result := LowerCase(Trim(Ini.ReadString('Alias', AExtName, '')));
  finally
    Ini.Free;
  end;
end;

function SchemeKeyByExt(const ASchemesDir, AExt: string;
  AIncIsBasic: Boolean): string;
var
  ExtName, AliasKey: string;
  ItemIdx: Integer;
begin
  ExtName := LowerCase(AExt);
  if (ExtName <> '') and (ExtName[1] = '.') then
    Delete(ExtName, 1, 1);
  Result := ExtName;
  if ExtName = '' then
    Exit;
  // Своя схема - важнее любых соответствий
  if FileExists(ASchemesDir + ExtName + '.clr') then
    Exit;
  AliasKey := SchemeAliasOf(ASchemesDir, ExtName);
  // .inc в проекте RapidQ Basic - схема Basic
  if (AliasKey = '') and (ExtName = 'inc') and AIncIsBasic and
     FileExists(ASchemesDir + 'bas.clr') then
    AliasKey := 'bas';
  if AliasKey = '' then
    for ItemIdx := Low(SchemeBuiltin) to High(SchemeBuiltin) do
      if Copy(SchemeBuiltin[ItemIdx], 1, Length(ExtName) + 1) =
         ExtName + '=' then
      begin
        AliasKey := Copy(SchemeBuiltin[ItemIdx], Length(ExtName) + 2, MaxInt);
        Break;
      end;
  if (AliasKey <> '') and FileExists(ASchemesDir + AliasKey + '.clr') then
    Result := AliasKey;
end;

function SchemeIncHasOwn(const ASchemesDir: string): Boolean;
begin
  Result := FileExists(ASchemesDir + 'inc.clr') or
    (SchemeAliasOf(ASchemesDir, 'inc') <> '');
end;

function SchemeGuessIncText(const AText: string): string;
var
  Lines: TStringList;
  LineIdx, BasScore, PasScore: Integer;
  LineText: string;

  function Starts(const APrefix: string): Boolean;
  begin
    Result := Copy(LineText, 1, Length(APrefix)) = APrefix;
  end;

begin
  Result := '';
  BasScore := 0;
  PasScore := 0;
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      LineText := LowerCase(Trim(Lines[LineIdx]));
      if LineText = '' then
        Continue;
      // Basic: комментарий ', REM, концы блоков, DECLARE, директивы $
      if Starts('''') or Starts('rem ') or Starts('end sub') or
         Starts('end function') or Starts('end type') or Starts('end with') or
         Starts('end select') or Starts('end create') or
         Starts('declare sub') or Starts('declare function') or
         Starts('$include') or Starts('$define') or Starts('$ifdef') or
         Starts('$ifndef') or Starts('$typecheck') or Starts('$apptype') or
         Starts('$resource') or Starts('dim ') or Starts('subi ') or
         Starts('functioni ') or Starts('wend') or Starts('next') then
        Inc(BasScore)
      // Паскаль: {$...}, begin / end;, :=, procedure, разделы модуля
      else if Starts('{$') or (LineText = 'begin') or Starts('end;') or
              Starts('end.') or Starts('procedure ') or Starts('unit ') or
              (LineText = 'interface') or (LineText = 'implementation') or
              Starts('//') or Starts('(*') or Starts('uses ') or
              (Pos(':=', LineText) > 0) then
        Inc(PasScore);
    end;
  finally
    Lines.Free;
  end;
  if BasScore > PasScore then
    Result := 'bas'
  else if PasScore > BasScore then
    Result := 'pas';
end;

function SchemeGuessIncFile(const AFile: string): string;
const
  ReadMax = 65536;
var
  Stream: TFileStream;
  Buf: string;
begin
  Result := '';
  if (AFile = '') or not FileExists(AFile) then
    Exit;
  try
    Stream := TFileStream.Create(AFile, fmOpenRead or fmShareDenyNone);
    try
      if Stream.Size > ReadMax then
        SetLength(Buf, ReadMax)
      else
        SetLength(Buf, Stream.Size);
      if Length(Buf) > 0 then
        Stream.ReadBuffer(Buf[1], Length(Buf));
    finally
      Stream.Free;
    end;
  except
    Exit;
  end;
  Result := SchemeGuessIncText(Buf);
end;

function SchemeKeyForFile(const ASchemesDir, AFile: string;
  AIncIsBasic: Boolean): string;
var
  ExtName, Guess: string;
begin
  ExtName := LowerCase(ExtractFileExt(AFile));
  if (ExtName = '.inc') and not SchemeIncHasOwn(ASchemesDir) then
  begin
    Guess := SchemeGuessIncFile(AFile);
    if (Guess <> '') and FileExists(ASchemesDir + Guess + '.clr') then
    begin
      Result := Guess;
      Exit;
    end;
  end;
  Result := SchemeKeyByExt(ASchemesDir, ExtName, AIncIsBasic);
end;

function SchemeLoadFromDir(const ASchemesDir, AKey, ATheme: string;
  AFontColor, ABgColor: TColor): TClrScheme;
var
  DefaultPath, ClrPath: string;
begin
  Result := TClrScheme.Create;
  try
    Result.FTheme := ThemeKey(ATheme);
    Result.ResetSchemaState(AFontColor, ABgColor);
    DefaultPath := SchemeDefaultPath(ASchemesDir);
    if FileExists(DefaultPath) then
    begin
      Result.ParseClrFile(DefaultPath);
      Result.ClearKeywordGroups; // ключевые слова - свои у каждого языка
    end;
    ClrPath := ASchemesDir + AKey + '.clr';
    if (AKey <> '') and FileExists(ClrPath) then
      Result.ParseClrFile(ClrPath);
    Result.ApplyTheme;
  except
    FreeAndNil(Result);
  end;
end;

end.
