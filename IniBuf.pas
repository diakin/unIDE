unit IniBuf;

// ---------------------------------------------------------------------------
//  TBufIniFile - ini-файл, который читается один раз и пишется один раз.
//
//  TIniFile пишет каждый ключ через WritePrivateProfileString: Windows
//  читает и переписывает файл целиком на каждый WriteString / WriteInteger.
//  В editor.ini лежат и проекты (сотни ключей), а SaveSettings пишет
//  десятки ключей подряд (окно, редактор, Recent, HotFolders) - это
//  десятки полных перезаписей файла за одно сохранение настроек, и каждую
//  может ещё проверять антивирус.
//
//  Здесь текст файла держится строками в памяти: чтение и запись ключей -
//  по ним, файл пишется один раз - в UpdateFile или при Free, и только если
//  что-то изменилось. Комментарии, пустые строки и порядок разделов и
//  ключей остаются как были; новый ключ - в конец своего раздела, новый
//  раздел - в конец файла. Значение читается как у GetPrivateProfileString:
//  пробелы по краям убираются, кавычки "..." или '...' вокруг - тоже.
//
//  После записи вызывается IniBufOnWritten (если задан) - редактор так
//  узнаёт, что файл записал он сам, а не другая программа.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, IniFiles;

type
  TIniWrittenEvent = procedure(const AFile: string) of object;

  TBufIniFile = class(TCustomIniFile)
  private
    FLines: TStringList;
    FModified: Boolean;
    function SectionLine(const ASection: string): Integer;
    function SectionEnd(AHead: Integer): Integer;
    function KeyLine(AHead: Integer; const AKey: string): Integer;
    function LineKey(const ALine: string): string;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    function ReadString(const Section, Ident, Default: string): string; override;
    procedure WriteString(const Section, Ident, Value: string); override;
    procedure ReadSection(const Section: string; Strings: TStrings); override;
    procedure ReadSections(Strings: TStrings); override;
    procedure ReadSectionValues(const Section: string; Strings: TStrings); override;
    procedure EraseSection(const Section: string); override;
    procedure DeleteKey(const Section, Ident: string); override;
    procedure UpdateFile; override;
    property Modified: Boolean read FModified;
  end;

var
  // Файл записан TBufIniFile (полный путь, как его передали в Create)
  IniBufOnWritten: TIniWrittenEvent = nil;

implementation

// Строка - заголовок раздела: имя без скобок, иначе ''
function HeadName(const ALine: string): string;
var
  Txt: string;
begin
  Result := '';
  Txt := Trim(ALine);
  if (Length(Txt) >= 2) and (Txt[1] = '[') and (Txt[Length(Txt)] = ']') then
    Result := Trim(Copy(Txt, 2, Length(Txt) - 2));
end;

function IsHead(const ALine: string): Boolean;
var
  Txt: string;
begin
  Txt := Trim(ALine);
  Result := (Length(Txt) >= 2) and (Txt[1] = '[') and (Txt[Length(Txt)] = ']');
end;

constructor TBufIniFile.Create(const AFileName: string);
begin
  inherited Create(AFileName);
  FLines := TStringList.Create;
  if FileExists(AFileName) then
    FLines.LoadFromFile(AFileName);
end;

destructor TBufIniFile.Destroy;
begin
  try
    UpdateFile;
  finally
    FLines.Free;
    inherited Destroy;
  end;
end;

function TBufIniFile.LineKey(const ALine: string): string;
var
  EqPos: Integer;
  Txt: string;
begin
  Result := '';
  Txt := TrimLeft(ALine);
  if (Txt = '') or (Txt[1] in [';', '#']) then
    Exit;
  EqPos := Pos('=', Txt);
  if EqPos > 0 then
    Result := Trim(Copy(Txt, 1, EqPos - 1));
end;

function TBufIniFile.SectionLine(const ASection: string): Integer;
var
  LineIdx: Integer;
begin
  for LineIdx := 0 to FLines.Count - 1 do
    if IsHead(FLines[LineIdx]) and
       (CompareText(HeadName(FLines[LineIdx]), Trim(ASection)) = 0) then
    begin
      Result := LineIdx;
      Exit;
    end;
  Result := -1;
end;

// Строка после раздела: следующий заголовок или конец файла
function TBufIniFile.SectionEnd(AHead: Integer): Integer;
begin
  Result := AHead + 1;
  while (Result < FLines.Count) and not IsHead(FLines[Result]) do
    Inc(Result);
end;

function TBufIniFile.KeyLine(AHead: Integer; const AKey: string): Integer;
var
  LineIdx, LastLine: Integer;
begin
  LastLine := SectionEnd(AHead) - 1;
  for LineIdx := AHead + 1 to LastLine do
    if CompareText(LineKey(FLines[LineIdx]), Trim(AKey)) = 0 then
    begin
      Result := LineIdx;
      Exit;
    end;
  Result := -1;
end;

function TBufIniFile.ReadString(const Section, Ident, Default: string): string;
var
  Head, KeyIdx, EqPos: Integer;
begin
  Result := Default;
  Head := SectionLine(Section);
  if Head < 0 then
    Exit;
  KeyIdx := KeyLine(Head, Ident);
  if KeyIdx < 0 then
    Exit;
  EqPos := Pos('=', FLines[KeyIdx]);
  Result := Trim(Copy(FLines[KeyIdx], EqPos + 1, MaxInt));
  // Кавычки вокруг значения снимаются, как у GetPrivateProfileString
  if (Length(Result) >= 2) and (Result[1] in ['"', '''']) and
     (Result[Length(Result)] = Result[1]) then
    Result := Copy(Result, 2, Length(Result) - 2);
end;

procedure TBufIniFile.WriteString(const Section, Ident, Value: string);
var
  Head, KeyIdx, InsertAt, EqPos: Integer;
  NewLine: string;
begin
  Head := SectionLine(Section);
  if Head < 0 then
  begin
    if (FLines.Count > 0) and (Trim(FLines[FLines.Count - 1]) <> '') then
      FLines.Add('');
    FLines.Add('[' + Section + ']');
    FLines.Add(Ident + '=' + Value);
    FModified := True;
    Exit;
  end;
  KeyIdx := KeyLine(Head, Ident);
  if KeyIdx >= 0 then
  begin
    // Имя ключа - как было записано
    EqPos := Pos('=', FLines[KeyIdx]);
    NewLine := TrimRight(Copy(FLines[KeyIdx], 1, EqPos - 1)) + '=' + Value;
    if NewLine <> FLines[KeyIdx] then
    begin
      FLines[KeyIdx] := NewLine;
      FModified := True;
    end;
    Exit;
  end;
  // Новый ключ - после последней непустой строки раздела
  InsertAt := SectionEnd(Head);
  while (InsertAt - 1 > Head) and (Trim(FLines[InsertAt - 1]) = '') do
    Dec(InsertAt);
  FLines.Insert(InsertAt, Ident + '=' + Value);
  FModified := True;
end;

procedure TBufIniFile.ReadSection(const Section: string; Strings: TStrings);
var
  Head, LineIdx: Integer;
  Key: string;
begin
  Strings.BeginUpdate;
  try
    Strings.Clear;
    Head := SectionLine(Section);
    if Head < 0 then
      Exit;
    for LineIdx := Head + 1 to SectionEnd(Head) - 1 do
    begin
      Key := LineKey(FLines[LineIdx]);
      if Key <> '' then
        Strings.Add(Key);
    end;
  finally
    Strings.EndUpdate;
  end;
end;

procedure TBufIniFile.ReadSections(Strings: TStrings);
var
  LineIdx: Integer;
begin
  Strings.BeginUpdate;
  try
    Strings.Clear;
    for LineIdx := 0 to FLines.Count - 1 do
      if IsHead(FLines[LineIdx]) then
        Strings.Add(HeadName(FLines[LineIdx]));
  finally
    Strings.EndUpdate;
  end;
end;

procedure TBufIniFile.ReadSectionValues(const Section: string; Strings: TStrings);
var
  Head, LineIdx: Integer;
  Key: string;
begin
  Strings.BeginUpdate;
  try
    Strings.Clear;
    Head := SectionLine(Section);
    if Head < 0 then
      Exit;
    for LineIdx := Head + 1 to SectionEnd(Head) - 1 do
    begin
      Key := LineKey(FLines[LineIdx]);
      if Key <> '' then
        Strings.Add(Key + '=' + ReadString(Section, Key, ''));
    end;
  finally
    Strings.EndUpdate;
  end;
end;

procedure TBufIniFile.EraseSection(const Section: string);
var
  Head, LastLine, LineIdx: Integer;
begin
  Head := SectionLine(Section);
  if Head < 0 then
    Exit;
  LastLine := SectionEnd(Head) - 1;
  for LineIdx := LastLine downto Head do
    FLines.Delete(LineIdx);
  FModified := True;
end;

procedure TBufIniFile.DeleteKey(const Section, Ident: string);
var
  Head, KeyIdx: Integer;
begin
  Head := SectionLine(Section);
  if Head < 0 then
    Exit;
  KeyIdx := KeyLine(Head, Ident);
  if KeyIdx < 0 then
    Exit;
  FLines.Delete(KeyIdx);
  FModified := True;
end;

procedure TBufIniFile.UpdateFile;
begin
  if not FModified then
    Exit;
  FLines.SaveToFile(FileName);
  FModified := False;
  if Assigned(IniBufOnWritten) then
    IniBufOnWritten(FileName);
end;

end.
