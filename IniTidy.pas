unit IniTidy;

// ---------------------------------------------------------------------------
//  Разбор editor.ini: Project - Manage Projects - Tidy editor.ini. Без VCL.
//
//  В editor.ini накопились копии разделов [<раздел>Old<N>] (их делали
//  CheckIniPaths и MergeOwnSettings), проекты старого вида (имя=путь к
//  .prj), записи других компьютеров. Команда читает editor.ini и пишет
//  рядом три вида файлов; сам editor.ini не меняется:
//
//    editorNew.ini - настройки этого компьютера: только существующие пути,
//      без копий Old; проекты в новом виде ([Projects] имя=папка и раздел
//      [Project.<имя>]), .prj, который есть на диске, переносится в раздел;
//      недавние файлы из [Recent] и всех [RecentOld<N>] без повторов.
//    editorN.ini - по одному на другой компьютер: записи с путями на
//      дисках и папках, которых здесь нет (D:\308\..., D:\bas\...). Корень
//      пути - диск и первая папка; корни, которые встречаются в одном
//      разделе, - один компьютер. Файл пишется, если у группы есть проекты;
//      без проектов её пути - в editorOLD.ini. Остальные настройки - как в
//      editorNew.ini, как и при переходе на другой компьютер
//      (SelectEditorIni). [Path] - предположение по пути этой программы.
//      Первая строка файла - пометка TidyMark: по ней повторный запуск
//      пишет в тот же editorN.ini, а не в новый номер.
//    editorOLD.ini - остальные записи с ненайденными путями: проекты,
//      недавние файлы, значения настроек. Разделы настроек - с исходными
//      именами ([Compiler.Delphi.Delphi 7Old1]), чтобы было видно, откуда
//      значение.
//
//  Значение ключа настроек: из раздела и его копий (сначала сам раздел,
//  потом копии от большего номера к меньшему) берётся то, где больше
//  существующих путей; из списка через ";" убираются пути, которых нет.
//  Ключи, которые есть только в копиях, добавляются. Ключи-пути
//  ([BuildKind], [RapidQ.Build]) остаются, если файл есть. Нумерованные
//  ключи, из которых что-то убрано (Dir1, Dir2...), нумеруются заново:
//  их читают до первого пропуска.
//
//  Проекты: сначала [Projects], потом копии от новых к старым. Один и тот
//  же проект (папка и цель сборки) берётся один раз. Одно имя у разных
//  проектов: первый остаётся с этим именем, следующие - "Имя (Папка)".
//
//  Строки в UTF-8 (так их записывал другой редактор) переводятся в
//  кодировку Windows, если все символы в ней есть.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes;

const
  TidyNewName = 'editorNew.ini';
  TidyOldName = 'editorOLD.ini';
  TidyMark = '; unIDE: Tidy editor.ini';
  TidyRecentMax = 9;

type
  TTidyExistsFunc = function(const APath: string): Boolean;

var
  // Есть ли файл или папка. nil - FileExists/DirectoryExists; тест
  // подставляет свою проверку
  TidyPathExists: TTidyExistsFunc = nil;

// AIniFile - editor.ini; файлы пишутся в его папку. ANotes - отчёт.
// False - editor.ini не прочитан или editorNew.ini не записан.
function TidyEditorIni(const AIniFile: string; ANotes: TStrings): Boolean;

implementation

// ---------------------------------------------------------------------------
//  Текст ini: разделы и строки
// ---------------------------------------------------------------------------

type
  TTidySect = class
  public
    Name: string;
    Lines: TStringList;
    constructor Create(const AName: string);
    destructor Destroy; override;
  end;

  TTidyDoc = class
  private
    FList: TList;
    function GetCount: Integer;
    function GetSect(AIndex: Integer): TTidySect;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadLines(ALines: TStrings);
    function Find(const AName: string): TTidySect;
    function Need(const AName: string): TTidySect;
    procedure SaveLines(ALines: TStrings);
    function Empty: Boolean;
    property Count: Integer read GetCount;
    property Sects[AIndex: Integer]: TTidySect read GetSect; default;
  end;

constructor TTidySect.Create(const AName: string);
begin
  inherited Create;
  Name := AName;
  Lines := TStringList.Create;
end;

destructor TTidySect.Destroy;
begin
  Lines.Free;
  inherited Destroy;
end;

constructor TTidyDoc.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TTidyDoc.Destroy;
var
  SectIdx: Integer;
begin
  for SectIdx := 0 to FList.Count - 1 do
    TTidySect(FList[SectIdx]).Free;
  FList.Free;
  inherited Destroy;
end;

function TTidyDoc.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TTidyDoc.GetSect(AIndex: Integer): TTidySect;
begin
  Result := TTidySect(FList[AIndex]);
end;

function TTidyDoc.Find(const AName: string): TTidySect;
var
  SectIdx: Integer;
begin
  for SectIdx := 0 to FList.Count - 1 do
  begin
    Result := TTidySect(FList[SectIdx]);
    if CompareText(Result.Name, AName) = 0 then
      Exit;
  end;
  Result := nil;
end;

function TTidyDoc.Need(const AName: string): TTidySect;
begin
  Result := Find(AName);
  if Result = nil then
  begin
    Result := TTidySect.Create(AName);
    FList.Add(Result);
  end;
end;

function SectionHeader(const ALine: string; var AName: string): Boolean;
var
  Txt: string;
  CloseAt: Integer;
begin
  Result := False;
  Txt := Trim(ALine);
  if (Txt = '') or (Txt[1] <> '[') then
    Exit;
  CloseAt := Pos(']', Txt);
  if CloseAt < 2 then
    Exit;
  AName := Trim(Copy(Txt, 2, CloseAt - 2));
  Result := True;
end;

// Строки до первого заголовка - раздел без имени. Пустые строки не
// хранятся: при записи после каждого раздела ставится одна. Повторный
// заголовок того же раздела - строки в тот же раздел.
procedure TTidyDoc.LoadLines(ALines: TStrings);
var
  LineIdx: Integer;
  Cur: TTidySect;
  Name: string;
begin
  Cur := Need('');
  for LineIdx := 0 to ALines.Count - 1 do
    if SectionHeader(ALines[LineIdx], Name) then
      Cur := Need(Name)
    else if Trim(ALines[LineIdx]) <> '' then
      Cur.Lines.Add(ALines[LineIdx]);
end;

procedure TTidyDoc.SaveLines(ALines: TStrings);
var
  SectIdx: Integer;
  Sect: TTidySect;
begin
  ALines.Clear;
  for SectIdx := 0 to FList.Count - 1 do
  begin
    Sect := TTidySect(FList[SectIdx]);
    if Sect.Name = '' then
    begin
      if Sect.Lines.Count = 0 then
        Continue;
    end
    else
      ALines.Add('[' + Sect.Name + ']');
    ALines.AddStrings(Sect.Lines);
    ALines.Add('');
  end;
end;

function TTidyDoc.Empty: Boolean;
var
  SectIdx: Integer;
begin
  Result := False;
  for SectIdx := 0 to FList.Count - 1 do
    if TTidySect(FList[SectIdx]).Lines.Count > 0 then
      Exit;
  Result := True;
end;

// --- строки "ключ=значение" ------------------------------------------------

function LineKey(const ALine: string): string;
var
  Txt: string;
  EqAt: Integer;
begin
  Result := '';
  Txt := Trim(ALine);
  if (Txt = '') or (Txt[1] = ';') or (Txt[1] = '#') then
    Exit;
  EqAt := Pos('=', Txt);
  if EqAt > 1 then
    Result := Trim(Copy(Txt, 1, EqAt - 1));
end;

function LineValue(const ALine: string): string;
var
  EqAt: Integer;
begin
  EqAt := Pos('=', ALine);
  if EqAt > 0 then
    Result := Trim(Copy(ALine, EqAt + 1, MaxInt))
  else
    Result := '';
end;

function KeyIndex(ALines: TStrings; const AKey: string): Integer;
var
  LineIdx: Integer;
begin
  Result := -1;
  for LineIdx := 0 to ALines.Count - 1 do
    if CompareText(LineKey(ALines[LineIdx]), AKey) = 0 then
    begin
      Result := LineIdx;
      Exit;
    end;
end;

function KeyValue(ALines: TStrings; const AKey: string;
                  var AFound: Boolean): string;
var
  LineIdx: Integer;
begin
  LineIdx := KeyIndex(ALines, AKey);
  AFound := LineIdx >= 0;
  if AFound then
    Result := LineValue(ALines[LineIdx])
  else
    Result := '';
end;

procedure SetKey(ALines: TStrings; const AKey, AValue: string);
var
  LineIdx: Integer;
begin
  LineIdx := KeyIndex(ALines, AKey);
  if LineIdx >= 0 then
    ALines[LineIdx] := AKey + '=' + AValue
  else
    ALines.Add(AKey + '=' + AValue);
end;

// Как StripIniComment в Unit1: всё после ";" - комментарий
function StripComment(const AValue: string): string;
var
  SemiAt: Integer;
begin
  Result := AValue;
  SemiAt := Pos(';', Result);
  if SemiAt > 0 then
    Result := Copy(Result, 1, SemiAt - 1);
  Result := Trim(Result);
end;

// Копия раздела ABase - [ABase]Old<N>; номер копии, 0 - не копия
function CopyNumber(const AName, ABase: string): Integer;
var
  Tail: string;
  CharIdx: Integer;
begin
  Result := 0;
  if (Length(AName) <= Length(ABase) + 3) or
     (CompareText(Copy(AName, 1, Length(ABase) + 3), ABase + 'Old') <> 0) then
    Exit;
  Tail := Copy(AName, Length(ABase) + 4, MaxInt);
  for CharIdx := 1 to Length(Tail) do
    if not (Tail[CharIdx] in ['0'..'9']) then
      Exit;
  Result := StrToIntDef(Tail, 0);
end;

// Имя раздела, копией которого является AName; '' - не копия
function CopyBaseName(const AName: string): string;
var
  CharIdx: Integer;
begin
  Result := '';
  CharIdx := Length(AName);
  while (CharIdx > 0) and (AName[CharIdx] in ['0'..'9']) do
    Dec(CharIdx);
  if (CharIdx = Length(AName)) or (CharIdx <= 3) or
     (CompareText(Copy(AName, CharIdx - 2, 3), 'Old') <> 0) then
    Exit;
  Result := Copy(AName, 1, CharIdx - 3);
end;

// ---------------------------------------------------------------------------
//  Пути
// ---------------------------------------------------------------------------

function IsAbsPath(const APath: string): Boolean;
begin
  Result := ((Length(APath) >= 3) and (UpCase(APath[1]) in ['A'..'Z']) and
             (APath[2] = ':') and (APath[3] = '\')) or
            (Copy(APath, 1, 2) = '\\');
end;

function AddSlash(const APath: string): string;
begin
  Result := APath;
  if (Result <> '') and (Result[Length(Result)] <> '\') then
    Result := Result + '\';
end;

function DropSlash(const APath: string): string;
begin
  Result := APath;
  while (Length(Result) > 3) and (Result[Length(Result)] = '\') do
    Delete(Result, Length(Result), 1);
end;

// Папка пути, с \ в конце
function DirOf(const APath: string): string;
var
  CharIdx: Integer;
begin
  CharIdx := Length(APath);
  while (CharIdx > 0) and (APath[CharIdx] <> '\') do
    Dec(CharIdx);
  Result := Copy(APath, 1, CharIdx);
end;

// Последняя часть пути: имя файла или папки
function NameOf(const APath: string): string;
var
  Txt: string;
  CharIdx: Integer;
begin
  Txt := DropSlash(APath);
  CharIdx := Length(Txt);
  while (CharIdx > 0) and (Txt[CharIdx] <> '\') do
    Dec(CharIdx);
  Result := Copy(Txt, CharIdx + 1, MaxInt);
end;

// Расширение без точки, в нижнем регистре; '' - нет
function ExtOf(const APath: string): string;
var
  Name: string;
  CharIdx: Integer;
begin
  Result := '';
  if (APath = '') or (APath[Length(APath)] = '\') then
    Exit;
  Name := NameOf(APath);
  CharIdx := Length(Name);
  while (CharIdx > 0) and (Name[CharIdx] <> '.') do
    Dec(CharIdx);
  if CharIdx > 0 then
    Result := LowerCase(Copy(Name, CharIdx + 1, MaxInt));
end;

// Части пути: D:\a\b -> "D:", "a", "b"; \\srv\share\a -> "\\srv", "share", "a"
procedure SplitPath(const APath: string; AParts: TStrings);
var
  Txt, Part: string;
  CharIdx: Integer;
begin
  AParts.Clear;
  Txt := APath;
  Part := '';
  if Copy(Txt, 1, 2) = '\\' then
  begin
    Part := '\\';
    Delete(Txt, 1, 2);
  end;
  for CharIdx := 1 to Length(Txt) do
    if Txt[CharIdx] = '\' then
    begin
      if (Part <> '') and (Part <> '\\') then
        AParts.Add(Part);
      Part := '';
    end
    else
      Part := Part + Txt[CharIdx];
  if (Part <> '') and (Part <> '\\') then
    AParts.Add(Part);
end;

function JoinParts(AParts: TStrings; AFirst, ALast: Integer): string;
var
  PartIdx: Integer;
begin
  Result := '';
  for PartIdx := AFirst to ALast do
  begin
    if PartIdx > AFirst then
      Result := Result + '\';
    Result := Result + AParts[PartIdx];
  end;
end;

// "." и ".." в пути
function ResolveDots(const APath: string): string;
var
  Parts: TStringList;
  PartIdx: Integer;
begin
  Parts := TStringList.Create;
  try
    SplitPath(APath, Parts);
    PartIdx := 1;
    while PartIdx < Parts.Count do
      if Parts[PartIdx] = '.' then
        Parts.Delete(PartIdx)
      else if Parts[PartIdx] = '..' then
      begin
        Parts.Delete(PartIdx);
        if PartIdx > 1 then
        begin
          Parts.Delete(PartIdx - 1);
          Dec(PartIdx);
        end;
      end
      else
        Inc(PartIdx);
    Result := JoinParts(Parts, 0, Parts.Count - 1);
    if (Parts.Count = 1) or (APath[Length(APath)] = '\') then
      Result := AddSlash(Result);
  finally
    Parts.Free;
  end;
end;

// Путь для сравнения
function NormPath(const APath: string): string;
begin
  Result := AnsiLowerCase(DropSlash(Trim(APath)));
end;

// Корень: диск и первая папка ("d:\308"), для сети - сервер и ресурс.
// Файл или папка прямо на диске (C:\x.txt) - корень сам диск
function RootOf(const APath: string): string;
var
  Parts: TStringList;
begin
  Parts := TStringList.Create;
  try
    SplitPath(Trim(APath), Parts);
    if Parts.Count = 0 then
      Result := ''
    else if (Parts.Count <= 2) and (Copy(Parts[0], 1, 2) <> '\\') then
      Result := Parts[0] + '\'
    else if Parts.Count = 1 then
      Result := Parts[0] + '\'
    else
      Result := Parts[0] + '\' + Parts[1];
    Result := AnsiLowerCase(Result);
  finally
    Parts.Free;
  end;
end;

// Путь в элементе значения: "D:\x" или "<число> D:\x" (Dir1=1 D:\...,
// winN в проектах); '' - элемент не путь
function ItemPathOf(const AItem: string): string;
var
  Txt: string;
  SpaceAt, CharIdx: Integer;
begin
  Result := '';
  Txt := Trim(AItem);
  if IsAbsPath(Txt) then
  begin
    Result := Txt;
    Exit;
  end;
  SpaceAt := Pos(' ', Txt);
  if SpaceAt < 2 then
    Exit;
  for CharIdx := 1 to SpaceAt - 1 do
    if not (Txt[CharIdx] in ['0'..'9']) then
      Exit;
  Txt := Trim(Copy(Txt, SpaceAt + 1, MaxInt));
  if IsAbsPath(Txt) then
    Result := Txt;
end;

procedure SplitItems(const AValue: string; AItems: TStrings);
var
  Txt: string;
  SemiAt: Integer;
begin
  AItems.Clear;
  Txt := AValue;
  while Txt <> '' do
  begin
    SemiAt := Pos(';', Txt);
    if SemiAt = 0 then
      SemiAt := Length(Txt) + 1;
    if Trim(Copy(Txt, 1, SemiAt - 1)) <> '' then
      AItems.Add(Trim(Copy(Txt, 1, SemiAt - 1)));
    Delete(Txt, 1, SemiAt);
  end;
end;

function PathExists(const APath: string): Boolean;
var
  Txt: string;
begin
  Txt := Trim(APath);
  if Txt = '' then
    Result := False
  else if Assigned(TidyPathExists) then
    Result := TidyPathExists(Txt)
  else
    Result := FileExists(DropSlash(Txt)) or DirectoryExists(DropSlash(Txt));
end;

// Файл, который программа создаст сама (CompileMsg.log): короткое
// расширение из букв и цифр, папка есть
function FileToCreate(const APath: string): Boolean;
var
  Ext: string;
  CharIdx: Integer;
begin
  Result := False;
  Ext := ExtOf(APath);
  if (Length(Ext) < 1) or (Length(Ext) > 4) or not (Ext[1] in ['a'..'z']) then
    Exit;
  for CharIdx := 1 to Length(Ext) do
    if not (Ext[CharIdx] in ['a'..'z', '0'..'9']) then
      Exit;
  Result := (Length(DirOf(APath)) > 3) and PathExists(DirOf(APath));
end;

// Путь из .prj: относительный - от папки ABaseDir; "\имя" - тоже от неё
function PathFromBase(const ABaseDir, APath: string): string;
var
  Txt: string;
begin
  Txt := Trim(APath);
  Result := Txt;
  if (Txt = '') or IsAbsPath(Txt) or (ABaseDir = '') then
    Exit;
  if Txt[1] = '\' then
    Delete(Txt, 1, 1);
  Result := ResolveDots(AddSlash(ABaseDir) + Txt);
end;

// Target в разделе проекта: в папке проекта - "\имя", иначе полный путь
function TargetToStore(const AFolder, APath: string): string;
var
  Dir: string;
begin
  Result := APath;
  if (AFolder = '') or (APath = '') then
    Exit;
  Dir := AddSlash(AFolder);
  if AnsiCompareText(Copy(APath, 1, Length(Dir)), Dir) = 0 then
    Result := '\' + Copy(APath, Length(Dir) + 1, MaxInt);
end;

function TargetFromStore(const AFolder, AValue: string): string;
var
  Txt: string;
begin
  Txt := StripComment(AValue);
  if (Txt <> '') and (Txt[1] = '\') and (Copy(Txt, 1, 2) <> '\\') then
    Result := AddSlash(AFolder) + Copy(Txt, 2, MaxInt)
  else
    Result := PathFromBase(AFolder, Txt);
end;

// ---------------------------------------------------------------------------
//  UTF-8 -> кодировка Windows
// ---------------------------------------------------------------------------

function Utf8Line(const ALine: string): Boolean;
var
  CharIdx, Follow, ByteVal: Integer;
  HasHigh: Boolean;
begin
  Result := False;
  HasHigh := False;
  CharIdx := 1;
  while CharIdx <= Length(ALine) do
  begin
    ByteVal := Ord(ALine[CharIdx]);
    if ByteVal < $80 then
      Follow := 0
    else if (ByteVal >= $C2) and (ByteVal <= $DF) then
      Follow := 1
    else if (ByteVal >= $E0) and (ByteVal <= $EF) then
      Follow := 2
    else if (ByteVal >= $F0) and (ByteVal <= $F4) then
      Follow := 3
    else
      Exit;
    if Follow > 0 then
      HasHigh := True;
    Inc(CharIdx);
    while Follow > 0 do
    begin
      if (CharIdx > Length(ALine)) or
         not (Ord(ALine[CharIdx]) in [$80..$BF]) then
        Exit;
      Inc(CharIdx);
      Dec(Follow);
    end;
  end;
  Result := HasHigh;
end;

function Utf8ToWideText(const ALine: string): WideString;
var
  CharIdx, Code, Follow: Integer;
begin
  Result := '';
  CharIdx := 1;
  while CharIdx <= Length(ALine) do
  begin
    Code := Ord(ALine[CharIdx]);
    if Code < $80 then
      Follow := 0
    else if Code < $E0 then
    begin
      Follow := 1;
      Code := Code and $1F;
    end
    else if Code < $F0 then
    begin
      Follow := 2;
      Code := Code and $0F;
    end
    else
    begin
      Follow := 3;
      Code := Code and $07;
    end;
    Inc(CharIdx);
    while (Follow > 0) and (CharIdx <= Length(ALine)) do
    begin
      Code := (Code shl 6) or (Ord(ALine[CharIdx]) and $3F);
      Inc(CharIdx);
      Dec(Follow);
    end;
    if Code > $FFFF then
      Code := Ord('?');
    Result := Result + WideChar(Code);
  end;
end;

// False - не все символы есть в кодировке Windows
function WideToAnsiText(const AText: WideString; var AAnsi: string): Boolean;
{$IFDEF MSWINDOWS}
var
  CharIdx, WideAsk, AnsiAsk: Integer;
begin
  AAnsi := AText;
  WideAsk := 0;
  AnsiAsk := 0;
  for CharIdx := 1 to Length(AText) do
    if AText[CharIdx] = '?' then
      Inc(WideAsk);
  for CharIdx := 1 to Length(AAnsi) do
    if AAnsi[CharIdx] = '?' then
      Inc(AnsiAsk);
  Result := (AnsiAsk = WideAsk) and (Length(AAnsi) = Length(AText));
end;
{$ELSE}
// Проверка вне Windows: кириллица cp1251
var
  CharIdx, Code: Integer;
begin
  Result := True;
  AAnsi := '';
  for CharIdx := 1 to Length(AText) do
  begin
    Code := Ord(AText[CharIdx]);
    if Code < $80 then
      AAnsi := AAnsi + Chr(Code)
    else if (Code >= $0410) and (Code <= $044F) then
      AAnsi := AAnsi + Chr(Code - $0410 + $C0)
    else if Code = $0401 then
      AAnsi := AAnsi + #$A8
    else if Code = $0451 then
      AAnsi := AAnsi + #$B8
    else if Code = $2116 then
      AAnsi := AAnsi + #$B9
    else
    begin
      Result := False;
      AAnsi := AAnsi + '?';
    end;
  end;
end;
{$ENDIF}

// Число исправленных строк
function FixUtf8Lines(ALines: TStrings): Integer;
var
  LineIdx: Integer;
  Converted: string;
begin
  Result := 0;
  for LineIdx := 0 to ALines.Count - 1 do
    if Utf8Line(ALines[LineIdx]) and
       WideToAnsiText(Utf8ToWideText(ALines[LineIdx]), Converted) then
    begin
      ALines[LineIdx] := Converted;
      Inc(Result);
    end;
end;

// Строка в список без повтора пути. 0 - добавлена, 1 - уже есть,
// 2 - список полон
function AddPathUnique(AList: TStrings; const APath: string;
                       AMax: Integer): Integer;
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to AList.Count - 1 do
    if NormPath(AList[ItemIdx]) = NormPath(APath) then
    begin
      Result := 1;
      Exit;
    end;
  if AList.Count >= AMax then
  begin
    Result := 2;
    Exit;
  end;
  AList.Add(APath);
  Result := 0;
end;

// ---------------------------------------------------------------------------
//  Список проектов одного файла
// ---------------------------------------------------------------------------

type
  TTidyPrjList = class
  public
    Entries: TStringList;   // имя=значение, в порядке добавления
    Ids: TStringList;       // имя|папка и папка|цель взятых проектов
    Sects: TTidyDoc;        // [Project.<имя>]
    constructor Create;
    destructor Destroy; override;
    // Имя, под которым проект записан; '' - такой уже есть: то же имя в
    // той же папке или та же папка и цель сборки
    function Add(const AName, AValue, AFolder, ATarget: string;
                 ABody: TStrings): string;
    // Проект с этим именем в этой папке уже взят
    function Has(const AName, AFolder: string): Boolean;
  end;

constructor TTidyPrjList.Create;
begin
  inherited Create;
  Entries := TStringList.Create;
  Ids := TStringList.Create;
  Sects := TTidyDoc.Create;
end;

destructor TTidyPrjList.Destroy;
begin
  Sects.Free;
  Ids.Free;
  Entries.Free;
  inherited Destroy;
end;

// Папка для имени "Имя (Папка)": последняя, не совпадающая с именем
// проекта и не "projects"
function FolderLabel(const AFolder, AName: string): string;
var
  Parts: TStringList;
  PartIdx: Integer;
begin
  Parts := TStringList.Create;
  try
    SplitPath(AFolder, Parts);
    Result := '';
    for PartIdx := Parts.Count - 1 downto 1 do
      if (AnsiCompareText(Parts[PartIdx], AName) <> 0) and
         (CompareText(Parts[PartIdx], 'projects') <> 0) then
      begin
        Result := Parts[PartIdx];
        Exit;
      end;
    Result := NameOf(AFolder);
  finally
    Parts.Free;
  end;
end;

function TTidyPrjList.Has(const AName, AFolder: string): Boolean;
begin
  Result := Ids.IndexOf('n|' + AnsiLowerCase(AName) + '|' +
                        NormPath(AFolder)) >= 0;
end;

function TTidyPrjList.Add(const AName, AValue, AFolder, ATarget: string;
                          ABody: TStrings): string;
var
  Num: Integer;
  Folder, NameId, TargetId: string;
begin
  Result := '';
  NameId := 'n|' + AnsiLowerCase(AName) + '|' + NormPath(AFolder);
  TargetId := '';
  if ATarget <> '' then
    TargetId := 't|' + NormPath(AFolder) + '|' + NormPath(ATarget);
  if (Ids.IndexOf(NameId) >= 0) or
     ((TargetId <> '') and (Ids.IndexOf(TargetId) >= 0)) then
    Exit;
  Result := AName;
  if Entries.IndexOfName(Result) >= 0 then
  begin
    Folder := FolderLabel(AFolder, AName);
    Result := AName + ' (' + Folder + ')';
    Num := 2;
    while Entries.IndexOfName(Result) >= 0 do
    begin
      Result := AName + ' (' + Folder + ' ' + IntToStr(Num) + ')';
      Inc(Num);
    end;
  end;
  Ids.Add(NameId);
  if TargetId <> '' then
    Ids.Add(TargetId);
  Entries.Add(Result + '=' + AValue);
  if ABody <> nil then
    Sects.Need('Project.' + Result).Lines.AddStrings(ABody);
end;

// ---------------------------------------------------------------------------
//  Группа путей другого компьютера
// ---------------------------------------------------------------------------

type
  TTidyGroup = class
  public
    Roots: TStringList;
    Paths: TStringList;      // пути группы - для догадки о [Path]
    Settings: TTidyDoc;      // значения настроек с путями этой группы
    Projects: TTidyPrjList;
    Recent: TStringList;
    PathGuess: string;
    PathFound: Boolean;
    constructor Create;
    destructor Destroy; override;
    // Другой компьютер - если там есть проекты. Без них (папка, удалённая
    // с этого компьютера, флешка, которой сейчас нет) пути группы идут в
    // editorOLD.ini, как ненайденные
    function IsComputer: Boolean;
  end;

constructor TTidyGroup.Create;
begin
  inherited Create;
  Roots := TStringList.Create;
  Paths := TStringList.Create;
  Settings := TTidyDoc.Create;
  Projects := TTidyPrjList.Create;
  Recent := TStringList.Create;
end;

function TTidyGroup.IsComputer: Boolean;
begin
  Result := Projects.Entries.Count > 0;
end;

destructor TTidyGroup.Destroy;
begin
  Recent.Free;
  Projects.Free;
  Settings.Free;
  Paths.Free;
  Roots.Free;
  inherited Destroy;
end;

// ---------------------------------------------------------------------------
//  Разбор
// ---------------------------------------------------------------------------

type
  TTidyState = (tsExists, tsMissing, tsForeign);

  TTidyWork = class
  private
    FDir, FCurPath: string;
    FNotes: TStrings;
    FSrc, FNew, FOld: TTidyDoc;
    FLocalRoots: TStringList;     // корень=1 (есть) / 0
    FForeign: TStringList;        // чужие корни; Objects - номер "родителя"
    FGroups: TList;
    FOldSeen: TStringList;        // уже записанное в editorOLD.ini
    FUsedSects: TStringList;      // [Project.*] источника, уже взятые
    FNewPrj, FOldPrj: TTidyPrjList;
    FNewRecent, FOldRecent: TStringList;
    FRemovedItems, FRestoredKeys, FAddedKeys, FDroppedKeys: Integer;
    FRecentOverflow: Integer;
    function RootLocal(const ARoot: string): Boolean;
    function ForeignIndex(const ARoot: string): Integer;
    function UnionTop(AIndex: Integer): Integer;
    procedure CollectPaths(ASect: TTidySect; APaths: TStrings);
    procedure BuildGroups;
    function GroupOf(const APath: string): TTidyGroup;
    function StateOf(const APath: string; ALax: Boolean;
                     var AGroup: TTidyGroup): TTidyState;
    function ExistCount(const AValue: string): Integer;
    procedure AddOldItem(const ASect, ABase, AKey, AItem: string);
    procedure DoSettings;
    procedure DoSettingsSection(const ABase: string);
    procedure Renumber(ALines: TStrings; ARemoved: TStrings);
    function ImportPrj(const APrjFile: string; ABody: TStrings;
                       var AFolder, ATarget: string): Boolean;
    procedure DoProjects;
    procedure DoRecent;
    procedure DoOrphans;
    procedure GuessPath(AGroup: TTidyGroup);
    function GroupFileName(AGroup: TTidyGroup): string;
    function WriteDoc(ADoc: TTidyDoc; const AFile: string): Boolean;
    procedure PutProjects(ADoc: TTidyDoc; AList: TTidyPrjList);
    procedure PutRecent(ADoc: TTidyDoc; AList: TStrings);
  public
    constructor Create;
    destructor Destroy; override;
    function Run(const AIniFile: string; ANotes: TStrings): Boolean;
  end;

constructor TTidyWork.Create;
begin
  inherited Create;
  FSrc := TTidyDoc.Create;
  FNew := TTidyDoc.Create;
  FOld := TTidyDoc.Create;
  FLocalRoots := TStringList.Create;
  FForeign := TStringList.Create;
  FGroups := TList.Create;
  FOldSeen := TStringList.Create;
  FOldSeen.Sorted := True;
  FUsedSects := TStringList.Create;
  FNewPrj := TTidyPrjList.Create;
  FOldPrj := TTidyPrjList.Create;
  FNewRecent := TStringList.Create;
  FOldRecent := TStringList.Create;
end;

destructor TTidyWork.Destroy;
var
  GroupIdx: Integer;
begin
  for GroupIdx := 0 to FGroups.Count - 1 do
    TTidyGroup(FGroups[GroupIdx]).Free;
  FGroups.Free;
  FOldRecent.Free;
  FNewRecent.Free;
  FOldPrj.Free;
  FNewPrj.Free;
  FUsedSects.Free;
  FOldSeen.Free;
  FForeign.Free;
  FLocalRoots.Free;
  FOld.Free;
  FNew.Free;
  FSrc.Free;
  inherited Destroy;
end;

function TTidyWork.RootLocal(const ARoot: string): Boolean;
var
  RootIdx: Integer;
begin
  RootIdx := FLocalRoots.IndexOfName(ARoot);
  if RootIdx < 0 then
  begin
    Result := PathExists(ARoot);
    FLocalRoots.Add(ARoot + '=' + IntToStr(Ord(Result)));
  end
  else
    Result := FLocalRoots.ValueFromIndex[RootIdx] = '1';
end;

function TTidyWork.ForeignIndex(const ARoot: string): Integer;
begin
  Result := FForeign.IndexOf(ARoot);
  if Result < 0 then
  begin
    Result := FForeign.Count;
    FForeign.AddObject(ARoot, TObject(Result));
  end;
end;

function TTidyWork.UnionTop(AIndex: Integer): Integer;
begin
  Result := AIndex;
  while Integer(FForeign.Objects[Result]) <> Result do
    Result := Integer(FForeign.Objects[Result]);
end;

// Пути раздела: ключи-пути и элементы значений
procedure TTidyWork.CollectPaths(ASect: TTidySect; APaths: TStrings);
var
  LineIdx, ItemIdx: Integer;
  Key, ItemPath: string;
  Items: TStringList;
begin
  APaths.Clear;
  Items := TStringList.Create;
  try
    for LineIdx := 0 to ASect.Lines.Count - 1 do
    begin
      Key := LineKey(ASect.Lines[LineIdx]);
      if Key = '' then
        Continue;
      if IsAbsPath(Key) then
        APaths.Add(Key);
      SplitItems(LineValue(ASect.Lines[LineIdx]), Items);
      for ItemIdx := 0 to Items.Count - 1 do
      begin
        ItemPath := ItemPathOf(Items[ItemIdx]);
        if ItemPath <> '' then
          APaths.Add(ItemPath);
      end;
    end;
  finally
    Items.Free;
  end;
end;

// Чужие корни, встреченные в одном разделе, - один компьютер
procedure TTidyWork.BuildGroups;
var
  SectIdx, PathIdx, RootIdx, FirstIdx, TopA, TopB, TopIdx: Integer;
  Paths, AllPaths: TStringList;
  Root: string;
  Group: TTidyGroup;
  Tops: TStringList;
begin
  Paths := TStringList.Create;
  AllPaths := TStringList.Create;
  Tops := TStringList.Create;
  try
    for SectIdx := 0 to FSrc.Count - 1 do
    begin
      CollectPaths(FSrc[SectIdx], Paths);
      FirstIdx := -1;
      for PathIdx := 0 to Paths.Count - 1 do
      begin
        Root := RootOf(Paths[PathIdx]);
        if (Root = '') or RootLocal(Root) then
          Continue;
        RootIdx := ForeignIndex(Root);
        AllPaths.AddObject(Paths[PathIdx], TObject(RootIdx));
        if FirstIdx < 0 then
          FirstIdx := RootIdx
        else
        begin
          TopA := UnionTop(FirstIdx);
          TopB := UnionTop(RootIdx);
          if TopA <> TopB then
            FForeign.Objects[TopB] := TObject(TopA);
        end;
      end;
    end;

    // группа на каждый верхний корень
    for RootIdx := 0 to FForeign.Count - 1 do
    begin
      TopA := UnionTop(RootIdx);
      TopIdx := Tops.IndexOf(IntToStr(TopA));
      if TopIdx < 0 then
      begin
        Group := TTidyGroup.Create;
        FGroups.Add(Group);
        Tops.AddObject(IntToStr(TopA), Group);
      end
      else
        Group := TTidyGroup(Tops.Objects[TopIdx]);
      Group.Roots.Add(FForeign[RootIdx]);
    end;
    for PathIdx := 0 to AllPaths.Count - 1 do
    begin
      Group := GroupOf(AllPaths[PathIdx]);
      if (Group <> nil) and (Group.Paths.IndexOf(AllPaths[PathIdx]) < 0) then
        Group.Paths.Add(AllPaths[PathIdx]);
    end;
  finally
    Tops.Free;
    AllPaths.Free;
    Paths.Free;
  end;
end;

function TTidyWork.GroupOf(const APath: string): TTidyGroup;
var
  GroupIdx: Integer;
  Root: string;
begin
  Result := nil;
  Root := RootOf(APath);
  if (Root = '') or RootLocal(Root) then
    Exit;
  for GroupIdx := 0 to FGroups.Count - 1 do
    if TTidyGroup(FGroups[GroupIdx]).Roots.IndexOf(Root) >= 0 then
    begin
      Result := TTidyGroup(FGroups[GroupIdx]);
      Exit;
    end;
end;

// ALax - и файл, которого ещё нет, в существующей папке (FileToCreate)
function TTidyWork.StateOf(const APath: string; ALax: Boolean;
                           var AGroup: TTidyGroup): TTidyState;
begin
  AGroup := nil;
  if PathExists(APath) or (ALax and FileToCreate(APath)) then
    Result := tsExists
  else
  begin
    AGroup := GroupOf(APath);
    if AGroup = nil then
      Result := tsMissing
    else
      Result := tsForeign;
  end;
end;

function TTidyWork.ExistCount(const AValue: string): Integer;
var
  Items: TStringList;
  ItemIdx: Integer;
  ItemPath: string;
  Group: TTidyGroup;
begin
  Result := 0;
  Items := TStringList.Create;
  try
    SplitItems(AValue, Items);
    for ItemIdx := 0 to Items.Count - 1 do
    begin
      ItemPath := ItemPathOf(Items[ItemIdx]);
      if (ItemPath <> '') and (StateOf(ItemPath, True, Group) = tsExists) then
        Inc(Result);
    end;
  finally
    Items.Free;
  end;
end;

// Ненайденный элемент значения - в editorOLD.ini, раздел с исходным именем;
// тот же путь того же ключа (из другой копии) - один раз
procedure TTidyWork.AddOldItem(const ASect, ABase, AKey, AItem: string);
var
  Seen, Prev: string;
  Found: Boolean;
  Sect: TTidySect;
begin
  Seen := AnsiLowerCase(ABase + '|' + AKey + '|') + NormPath(AItem);
  if FOldSeen.IndexOf(Seen) >= 0 then
    Exit;
  FOldSeen.Add(Seen);
  Sect := FOld.Need(ASect);
  Prev := KeyValue(Sect.Lines, AKey, Found);
  if Found and (Prev <> '') then
    SetKey(Sect.Lines, AKey, Prev + ';' + AItem)
  else
    SetKey(Sect.Lines, AKey, AItem);
end;

function SpecialSection(const AName: string): Boolean;
begin
  Result := (AName = '') or (CompareText(AName, 'Path') = 0) or
            (CompareText(Copy(AName, 1, 8), 'Projects') = 0) or
            (CompareText(Copy(AName, 1, 8), 'Project.') = 0) or
            (CompareText(AName, 'Recent') = 0) or
            (CompareText(CopyBaseName(AName), 'Recent') = 0);
end;

procedure TTidyWork.DoSettings;
var
  Bases: TStringList;
  SectIdx: Integer;
  Name, Base: string;
begin
  Bases := TStringList.Create;
  try
    for SectIdx := 0 to FSrc.Count - 1 do
    begin
      Name := FSrc[SectIdx].Name;
      if SpecialSection(Name) then
        Continue;
      Base := CopyBaseName(Name);
      if Base = '' then
        Base := Name;
      if Bases.IndexOf(Base) < 0 then
        Bases.Add(Base);
    end;
    for SectIdx := 0 to Bases.Count - 1 do
      DoSettingsSection(Bases[SectIdx]);
  finally
    Bases.Free;
  end;
end;

// Нумерованные ключи, из которых что-то убрано: Dir1, Dir3 -> Dir1, Dir2
procedure TTidyWork.Renumber(ALines: TStrings; ARemoved: TStrings);
var
  RemIdx, LineIdx, KeyNum, NextNum, MinNum: Integer;
  Prefix, Key, Done: string;

  function KeyPrefix(const AKey: string; var ANum: Integer): string;
  var
    TailAt: Integer;
  begin
    TailAt := Length(AKey);
    while (TailAt > 0) and (AKey[TailAt] in ['0'..'9']) do
      Dec(TailAt);
    Result := '';
    ANum := -1;
    if (TailAt = 0) or (TailAt = Length(AKey)) then
      Exit;
    Result := Copy(AKey, 1, TailAt);
    ANum := StrToIntDef(Copy(AKey, TailAt + 1, MaxInt), -1);
  end;

begin
  Done := '|';
  for RemIdx := 0 to ARemoved.Count - 1 do
  begin
    Prefix := KeyPrefix(ARemoved[RemIdx], MinNum);
    if (Prefix = '') or (Pos('|' + LowerCase(Prefix) + '|', Done) > 0) then
      Continue;
    Done := Done + LowerCase(Prefix) + '|';
    // с какого номера считать: наименьший среди всех ключей с приставкой
    MinNum := MaxInt;
    for LineIdx := 0 to ARemoved.Count - 1 do
      if CompareText(KeyPrefix(ARemoved[LineIdx], KeyNum), Prefix) = 0 then
        if (KeyNum >= 0) and (KeyNum < MinNum) then
          MinNum := KeyNum;
    for LineIdx := 0 to ALines.Count - 1 do
      if CompareText(KeyPrefix(LineKey(ALines[LineIdx]), KeyNum), Prefix) = 0 then
        if (KeyNum >= 0) and (KeyNum < MinNum) then
          MinNum := KeyNum;
    if MinNum > 1 then
      MinNum := 1;
    NextNum := MinNum;
    for LineIdx := 0 to ALines.Count - 1 do
    begin
      Key := LineKey(ALines[LineIdx]);
      if (CompareText(KeyPrefix(Key, KeyNum), Prefix) = 0) and (KeyNum >= 0) then
      begin
        ALines[LineIdx] := Copy(Key, 1, Length(Prefix)) + IntToStr(NextNum) +
                           '=' + LineValue(ALines[LineIdx]);
        Inc(NextNum);
      end;
    end;
  end;
end;

procedure TTidyWork.DoSettingsSection(const ABase: string);
var
  Cands: TList;            // TTidySect: раздел, потом копии от новых
  Keys, Values, Items, Kept, Removed: TStringList;
  CandIdx, SectIdx, LineIdx, KeyIdx, ValIdx, ItemIdx, Num, BestIdx,
  BestCount, Count, DropCount: Integer;
  Sect, NewSect, GroupSect: TTidySect;
  Key, Value, ItemPath, NewValue: string;
  Found, HasPaths: Boolean;
  Group: TTidyGroup;
  State: TTidyState;
begin
  Cands := TList.Create;
  Keys := TStringList.Create;
  Values := TStringList.Create;
  Items := TStringList.Create;
  Kept := TStringList.Create;
  Removed := TStringList.Create;
  try
    Sect := FSrc.Find(ABase);
    if Sect <> nil then
      Cands.Add(Sect);
    // копии - по убыванию номера
    for SectIdx := 0 to FSrc.Count - 1 do
    begin
      Num := CopyNumber(FSrc[SectIdx].Name, ABase);
      if Num <= 0 then
        Continue;
      CandIdx := 0;
      if Sect <> nil then
        CandIdx := 1;
      while (CandIdx < Cands.Count) and
            (CopyNumber(TTidySect(Cands[CandIdx]).Name, ABase) > Num) do
        Inc(CandIdx);
      Cands.Insert(CandIdx, FSrc[SectIdx]);
    end;

    NewSect := FNew.Need(ABase);
    // комментарии раздела - в начало
    if Sect <> nil then
      for LineIdx := 0 to Sect.Lines.Count - 1 do
        if LineKey(Sect.Lines[LineIdx]) = '' then
          NewSect.Lines.Add(Sect.Lines[LineIdx]);

    for CandIdx := 0 to Cands.Count - 1 do
      with TTidySect(Cands[CandIdx]) do
        for LineIdx := 0 to Lines.Count - 1 do
        begin
          Key := LineKey(Lines[LineIdx]);
          if (Key <> '') and (Keys.IndexOf(Key) < 0) then
            Keys.Add(Key);
        end;

    for KeyIdx := 0 to Keys.Count - 1 do
    begin
      Key := Keys[KeyIdx];
      Values.Clear;
      for CandIdx := 0 to Cands.Count - 1 do
      begin
        Value := KeyValue(TTidySect(Cands[CandIdx]).Lines, Key, Found);
        if Found then
          Values.AddObject(Value, Cands[CandIdx]);
      end;
      if Values.Count = 0 then
        Continue;

      // ключ - путь к файлу ([BuildKind], [RapidQ.Build])
      if IsAbsPath(Key) then
      begin
        State := StateOf(Key, False, Group);
        case State of
          tsExists:
            SetKey(NewSect.Lines, Key, Values[0]);
          tsMissing:
            begin
              AddOldItem(TTidySect(Values.Objects[0]).Name, ABase, Key,
                         Values[0]);
              Inc(FRemovedItems);
              Removed.Add(Key);
            end;
          tsForeign:
            begin
              if Group.IsComputer then
              begin
                GroupSect := Group.Settings.Need(ABase);
                if KeyIndex(GroupSect.Lines, Key) < 0 then
                  SetKey(GroupSect.Lines, Key, Values[0]);
              end
              else
              begin
                AddOldItem(TTidySect(Values.Objects[0]).Name, ABase, Key,
                           Values[0]);
                Inc(FRemovedItems);
              end;
              Removed.Add(Key);
            end;
        end;
        Continue;
      end;

      HasPaths := False;
      for ValIdx := 0 to Values.Count - 1 do
      begin
        SplitItems(Values[ValIdx], Items);
        for ItemIdx := 0 to Items.Count - 1 do
          if ItemPathOf(Items[ItemIdx]) <> '' then
            HasPaths := True;
      end;

      if not HasPaths then
      begin
        SetKey(NewSect.Lines, Key, Values[0]);
        if Values.Objects[0] <> Sect then
        begin
          Inc(FAddedKeys);
          FNotes.Add('[' + ABase + '] ' + Key + ': ключ добавлен из [' +
                     TTidySect(Values.Objects[0]).Name + ']');
        end;
        Continue;
      end;

      // значение, где больше существующих путей; при равенстве - новее
      BestIdx := -1;
      BestCount := 0;
      for ValIdx := 0 to Values.Count - 1 do
      begin
        Count := ExistCount(Values[ValIdx]);
        if Count > BestCount then
        begin
          BestCount := Count;
          BestIdx := ValIdx;
        end;
      end;

      if BestIdx >= 0 then
      begin
        SplitItems(Values[BestIdx], Items);
        Kept.Clear;
        DropCount := 0;
        for ItemIdx := 0 to Items.Count - 1 do
        begin
          ItemPath := ItemPathOf(Items[ItemIdx]);
          if (ItemPath = '') or (StateOf(ItemPath, True, Group) = tsExists) then
            Kept.Add(Items[ItemIdx])
          else
            Inc(DropCount);
        end;
        NewValue := '';
        for ItemIdx := 0 to Kept.Count - 1 do
        begin
          if ItemIdx > 0 then
            NewValue := NewValue + ';';
          NewValue := NewValue + Kept[ItemIdx];
        end;
        SetKey(NewSect.Lines, Key, NewValue);
        if Values.Objects[BestIdx] <> Sect then
        begin
          if Sect <> nil then
            Inc(FRestoredKeys)
          else
            Inc(FAddedKeys);
          FNotes.Add('[' + ABase + '] ' + Key + ': значение взято из [' +
                     TTidySect(Values.Objects[BestIdx]).Name + ']');
        end;
        if DropCount > 0 then
          FNotes.Add('[' + ABase + '] ' + Key + ': убрано путей, которых ' +
                     'нет: ' + IntToStr(DropCount));
      end
      else
      begin
        Inc(FDroppedKeys);
        Removed.Add(Key);
        FNotes.Add('[' + ABase + '] ' + Key + ': ни одного существующего ' +
                   'пути - ключ не записан');
      end;

      // ненайденное - в editorOLD.ini или в файл другого компьютера
      for ValIdx := 0 to Values.Count - 1 do
      begin
        SplitItems(Values[ValIdx], Items);
        for ItemIdx := 0 to Items.Count - 1 do
        begin
          ItemPath := ItemPathOf(Items[ItemIdx]);
          if ItemPath = '' then
            Continue;
          State := StateOf(ItemPath, True, Group);
          if (State = tsForeign) and not Group.IsComputer then
            State := tsMissing;
          case State of
            tsMissing:
              begin
                AddOldItem(TTidySect(Values.Objects[ValIdx]).Name, ABase, Key,
                           Items[ItemIdx]);
                Inc(FRemovedItems);
              end;
            tsForeign:
              begin
                GroupSect := Group.Settings.Need(ABase);
                if KeyIndex(GroupSect.Lines, Key) < 0 then
                  SetKey(GroupSect.Lines, Key, Values[ValIdx]);
              end;
          end;
        end;
      end;
    end;

    if Removed.Count > 0 then
      Renumber(NewSect.Lines, Removed);
  finally
    Removed.Free;
    Kept.Free;
    Items.Free;
    Values.Free;
    Keys.Free;
    Cands.Free;
  end;
end;

// .prj -> строки раздела [Project.<имя>], как ImportPrjFile в Unit1:
// [Project] - ключи как есть, остальные - "<раздел>_<ключ>"; [Editor] и
// пути C:\ и DelphiPath из [Compiler] не переносятся. AFolder - папка
// проекта: папка .prj, а для .prj в папке projects программы (старое
// хранение) - папка цели сборки.
function TTidyWork.ImportPrj(const APrjFile: string; ABody: TStrings;
                             var AFolder, ATarget: string): Boolean;
var
  Lines: TStringList;
  Doc: TTidyDoc;
  PrjSect, Sect: TTidySect;
  SectIdx, LineIdx, SpaceAt: Integer;
  Key, Value, PrjDir: string;
  Found, PathValue: Boolean;
begin
  Result := False;
  ABody.Clear;
  Lines := TStringList.Create;
  Doc := TTidyDoc.Create;
  try
    try
      Lines.LoadFromFile(APrjFile);
    except
      Exit;
    end;
    FixUtf8Lines(Lines);
    Doc.LoadLines(Lines);
    PrjDir := DirOf(APrjFile);
    ATarget := '';
    PrjSect := Doc.Find('Project');
    if PrjSect <> nil then
      ATarget := PathFromBase(PrjDir,
                   StripComment(KeyValue(PrjSect.Lines, 'Target', Found)));
    AFolder := PrjDir;
    if (CompareText(NameOf(PrjDir), 'projects') = 0) and (ATarget <> '') and
       (NormPath(DirOf(ATarget)) <> NormPath(PrjDir)) then
      AFolder := DirOf(ATarget);

    for SectIdx := 0 to Doc.Count - 1 do
    begin
      Sect := Doc[SectIdx];
      if (Sect.Name = '') or (CompareText(Sect.Name, 'Editor') = 0) then
        Continue;
      for LineIdx := 0 to Sect.Lines.Count - 1 do
      begin
        Key := LineKey(Sect.Lines[LineIdx]);
        if Key = '' then
          Continue;
        Value := LineValue(Sect.Lines[LineIdx]);
        if (CompareText(Sect.Name, 'Compiler') = 0) and
           ((Value = 'C:\') or (CompareText(Key, 'DelphiPath') = 0)) then
          Continue;
        if (CompareText(Sect.Name, 'Project') = 0) and
           (CompareText(Key, 'Target') = 0) then
          Value := TargetToStore(AFolder, ATarget)
        else if (CompareText(Sect.Name, 'Windows') = 0) and
                (CompareText(Copy(Key, 1, 8), 'incowner') = 0) then
          Value := PathFromBase(PrjDir, Value)
        else
        begin
          // "<номер> <путь>": winN в [Windows], номера в [Tabs]
          PathValue := ((CompareText(Sect.Name, 'Windows') = 0) and
                        (CompareText(Copy(Key, 1, 3), 'win') = 0)) or
                       ((CompareText(Sect.Name, 'Tabs') = 0) and
                        (StrToIntDef(Key, -1) >= 0));
          SpaceAt := Pos(' ', Value);
          if PathValue and (SpaceAt > 1) and
             (StrToIntDef(Copy(Value, 1, SpaceAt - 1), -1) >= 0) then
            Value := Copy(Value, 1, SpaceAt) +
                     PathFromBase(PrjDir, Copy(Value, SpaceAt + 1, MaxInt));
        end;
        if CompareText(Sect.Name, 'Project') = 0 then
          SetKey(ABody, Key, Value)
        else
          SetKey(ABody, Sect.Name + '_' + Key, Value);
      end;
    end;
    Result := True;
  finally
    Doc.Free;
    Lines.Free;
  end;
end;

procedure TTidyWork.DoProjects;
var
  Sources: TList;
  Body: TStringList;
  Sect, PrjSect: TTidySect;
  SrcIdx, SectIdx, LineIdx, Num, Imported, Dups: Integer;
  Name, Raw, Folder, Target, Added: string;
  Found: Boolean;
  Group: TTidyGroup;
  BodyRef: TStrings;
begin
  Sources := TList.Create;
  Body := TStringList.Create;
  Imported := 0;
  Dups := 0;
  try
    Sect := FSrc.Find('Projects');
    if Sect <> nil then
      Sources.Add(Sect);
    for SectIdx := 0 to FSrc.Count - 1 do
    begin
      Num := CopyNumber(FSrc[SectIdx].Name, 'Projects');
      if Num <= 0 then
        Continue;
      SrcIdx := 0;
      if Sect <> nil then
        SrcIdx := 1;
      while (SrcIdx < Sources.Count) and
            (CopyNumber(TTidySect(Sources[SrcIdx]).Name, 'Projects') > Num) do
        Inc(SrcIdx);
      Sources.Insert(SrcIdx, FSrc[SectIdx]);
    end;

    for SrcIdx := 0 to Sources.Count - 1 do
    begin
      Sect := TTidySect(Sources[SrcIdx]);
      for LineIdx := 0 to Sect.Lines.Count - 1 do
      begin
        Name := LineKey(Sect.Lines[LineIdx]);
        Raw := StripComment(LineValue(Sect.Lines[LineIdx]));
        if (Name = '') or (Raw = '') then
          Continue;

        if ExtOf(Raw) = 'prj' then
        begin
          // старый вид: путь к .prj
          case StateOf(Raw, False, Group) of
            tsExists:
              if ImportPrj(Raw, Body, Folder, Target) then
              begin
                Added := FNewPrj.Add(Name, AddSlash(Folder), Folder, Target,
                                     Body);
                if Added = '' then
                  Inc(Dups)
                else
                begin
                  Inc(Imported);
                  if Added <> Name then
                    FNotes.Add('Проект ' + Name + ' (' + Raw + '): имя ' +
                               'занято другим проектом, записан как ' + Added)
                  else
                    FNotes.Add('Проект ' + Name + ': перенесён из ' + Raw);
                end;
              end
              else
                FOldPrj.Add(Name, Raw, DirOf(Raw), Raw, nil);
            tsMissing:
              // .prj уже перенесён в editor.ini и удалён - проект есть
              if not FNewPrj.Has(Name, DirOf(Raw)) then
                FOldPrj.Add(Name, Raw, DirOf(Raw), Raw, nil);
            tsForeign:
              Group.Projects.Add(Name, Raw, DirOf(Raw), Raw, nil);
          end;
          Continue;
        end;

        // новый вид: папка проекта и раздел [Project.<имя>]
        Folder := AddSlash(Raw);
        BodyRef := nil;
        PrjSect := FSrc.Find('Project.' + Name);
        if (PrjSect <> nil) and (FUsedSects.IndexOf(PrjSect.Name) < 0) then
        begin
          FUsedSects.Add(PrjSect.Name);
          BodyRef := PrjSect.Lines;
        end;
        Target := '';
        if BodyRef <> nil then
          Target := TargetFromStore(Folder, KeyValue(BodyRef, 'Target', Found));
        case StateOf(Folder, False, Group) of
          tsExists:
            begin
              Added := FNewPrj.Add(Name, Folder, Folder, Target, BodyRef);
              if Added = '' then
                Inc(Dups)
              else if Added <> Name then
                FNotes.Add('Проект ' + Name + ' (' + Folder + '): имя занято ' +
                           'другим проектом, записан как ' + Added);
              if (Added <> '') and (BodyRef = nil) then
                FNotes.Add('Проект ' + Added + ': раздела [Project.' + Name +
                           '] нет, записана только папка');
            end;
          tsMissing:
            FOldPrj.Add(Name, Folder, Folder, Target, BodyRef);
          tsForeign:
            Group.Projects.Add(Name, Folder, Folder, Target, BodyRef);
        end;
      end;
    end;
    FNotes.Add('Проекты: в editorNew.ini ' + IntToStr(FNewPrj.Entries.Count) +
               ' (из .prj перенесено ' + IntToStr(Imported) + ', повторов ' +
               'убрано ' + IntToStr(Dups) + '), в editorOLD.ini ' +
               IntToStr(FOldPrj.Entries.Count));
  finally
    Body.Free;
    Sources.Free;
  end;
end;

procedure TTidyWork.DoRecent;
var
  Sources: TList;
  Sect: TTidySect;
  SrcIdx, SectIdx, LineIdx, Num: Integer;
  Value: string;
  Group: TTidyGroup;
  Overflow: TStringList;
begin
  Sources := TList.Create;
  Overflow := TStringList.Create;
  try
    Sect := FSrc.Find('Recent');
    if Sect <> nil then
      Sources.Add(Sect);
    for SectIdx := 0 to FSrc.Count - 1 do
    begin
      Num := CopyNumber(FSrc[SectIdx].Name, 'Recent');
      if Num <= 0 then
        Continue;
      SrcIdx := 0;
      if Sect <> nil then
        SrcIdx := 1;
      while (SrcIdx < Sources.Count) and
            (CopyNumber(TTidySect(Sources[SrcIdx]).Name, 'Recent') > Num) do
        Inc(SrcIdx);
      Sources.Insert(SrcIdx, FSrc[SectIdx]);
    end;

    for SrcIdx := 0 to Sources.Count - 1 do
      with TTidySect(Sources[SrcIdx]) do
        for LineIdx := 0 to Lines.Count - 1 do
        begin
          if LineKey(Lines[LineIdx]) = '' then
            Continue;
          Value := LineValue(Lines[LineIdx]);
          if Value = '' then
            Continue;
          case StateOf(Value, False, Group) of
            tsExists:
              if AddPathUnique(FNewRecent, Value, TidyRecentMax) = 2 then
                AddPathUnique(Overflow, Value, MaxInt);
            tsMissing:
              AddPathUnique(FOldRecent, Value, MaxInt);
            tsForeign:
              // сверх списка того компьютера - в editorOLD.ini
              if AddPathUnique(Group.Recent, Value, TidyRecentMax) = 2 then
                AddPathUnique(FOldRecent, Value, MaxInt);
          end;
        end;
    FRecentOverflow := Overflow.Count;
  finally
    Overflow.Free;
    Sources.Free;
  end;
end;

// Разделы [Project.*], на которые нет записи в [Projects]
procedure TTidyWork.DoOrphans;
var
  SectIdx: Integer;
  Sect: TTidySect;
begin
  for SectIdx := 0 to FSrc.Count - 1 do
  begin
    Sect := FSrc[SectIdx];
    if (CompareText(Copy(Sect.Name, 1, 8), 'Project.') <> 0) or
       (FUsedSects.IndexOf(Sect.Name) >= 0) then
      Continue;
    FOld.Need(Sect.Name).Lines.AddStrings(Sect.Lines);
    FNotes.Add('[' + Sect.Name + ']: проекта с таким именем в [Projects] ' +
               'нет - раздел в editorOLD.ini');
  end;
end;

// [Path] другого компьютера: путь этой программы, у которого начало
// заменено так, чтобы совпал наибольший кусок с путями группы
// (D:\_F\balan\_SyntaxHLClaude\SyntaxHLBeta\... и
// D:\308\disk_C\0diakin2_0\_SyntaxHLClaude\SyntaxHLBeta\...)
procedure TTidyWork.GuessPath(AGroup: TTidyGroup);
var
  CurParts, PathParts: TStringList;
  PathIdx, CurStart, PathStart, MatchLen, BestLen: Integer;
begin
  CurParts := TStringList.Create;
  PathParts := TStringList.Create;
  try
    SplitPath(FCurPath, CurParts);
    BestLen := 1;
    AGroup.PathFound := False;
    AGroup.PathGuess := '';
    for PathIdx := 0 to AGroup.Paths.Count - 1 do
    begin
      SplitPath(AGroup.Paths[PathIdx], PathParts);
      for CurStart := 1 to CurParts.Count - 1 do
        for PathStart := 1 to PathParts.Count - 1 do
        begin
          MatchLen := 0;
          while (CurStart + MatchLen < CurParts.Count) and
                (PathStart + MatchLen < PathParts.Count) and
                (AnsiCompareText(CurParts[CurStart + MatchLen],
                                 PathParts[PathStart + MatchLen]) = 0) do
            Inc(MatchLen);
          if MatchLen > BestLen then
          begin
            BestLen := MatchLen;
            AGroup.PathGuess := JoinParts(PathParts, 0, PathStart - 1) + '\' +
              JoinParts(CurParts, CurStart, CurParts.Count - 1) + '\';
            AGroup.PathFound := True;
          end;
        end;
    end;
    if AGroup.PathGuess = '' then
    begin
      SplitPath(AGroup.Paths[0], PathParts);
      if PathParts.Count > 1 then
        AGroup.PathGuess := JoinParts(PathParts, 0, 1) + '\'
      else
        AGroup.PathGuess := AddSlash(AGroup.Roots[0]);
    end;
  finally
    PathParts.Free;
    CurParts.Free;
  end;
end;

// editorN.ini для группы: прежний файл этой команды с тем же [Path] или
// свободный номер
function TTidyWork.GroupFileName(AGroup: TTidyGroup): string;
var
  Num, LineIdx: Integer;
  Lines: TStringList;
  Doc: TTidyDoc;
  PathSect: TTidySect;
  FilePath: string;
begin
  Lines := TStringList.Create;
  try
    for Num := 1 to 99 do
    begin
      Result := FDir + 'editor' + IntToStr(Num) + '.ini';
      if not FileExists(Result) then
        Continue;
      try
        Lines.LoadFromFile(Result);
      except
        Continue;
      end;
      if (Lines.Count = 0) or (Lines[0] <> TidyMark) then
        Continue;
      Doc := TTidyDoc.Create;
      try
        Doc.LoadLines(Lines);
        PathSect := Doc.Find('Path');
        FilePath := '';
        if PathSect <> nil then
          for LineIdx := 0 to PathSect.Lines.Count - 1 do
            if (Trim(PathSect.Lines[LineIdx]) <> '') and
               (Trim(PathSect.Lines[LineIdx])[1] <> ';') then
            begin
              FilePath := Trim(PathSect.Lines[LineIdx]);
              Break;
            end;
      finally
        Doc.Free;
      end;
      if NormPath(FilePath) = NormPath(AGroup.PathGuess) then
        Exit;
    end;
    for Num := 1 to 99 do
    begin
      Result := FDir + 'editor' + IntToStr(Num) + '.ini';
      if not FileExists(Result) then
        Exit;
    end;
    Result := '';
  finally
    Lines.Free;
  end;
end;

function TTidyWork.WriteDoc(ADoc: TTidyDoc; const AFile: string): Boolean;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    ADoc.SaveLines(Lines);
    try
      Lines.SaveToFile(AFile);
      Result := True;
    except
      Result := False;
      FNotes.Add('Не удалось записать ' + AFile);
    end;
  finally
    Lines.Free;
  end;
end;

procedure TTidyWork.PutProjects(ADoc: TTidyDoc; AList: TTidyPrjList);
var
  SectIdx: Integer;
begin
  if AList.Entries.Count = 0 then
    Exit;
  ADoc.Need('Projects').Lines.AddStrings(AList.Entries);
  for SectIdx := 0 to AList.Sects.Count - 1 do
    ADoc.Need(AList.Sects[SectIdx].Name).Lines.AddStrings(
      AList.Sects[SectIdx].Lines);
end;

procedure TTidyWork.PutRecent(ADoc: TTidyDoc; AList: TStrings);
var
  FileIdx: Integer;
  Sect: TTidySect;
begin
  if AList.Count = 0 then
    Exit;
  Sect := ADoc.Need('Recent');
  for FileIdx := 0 to AList.Count - 1 do
    Sect.Lines.Add('File' + IntToStr(FileIdx + 1) + '=' + AList[FileIdx]);
end;

// Значение группы в раздел файла другого компьютера. Нумерованный ключ
// (Dir4), когда в разделе уже есть ключи с той же приставкой, - следующим
// номером, без пропусков: такие ключи читаются до первого пропуска
procedure PutGroupValue(ALines: TStrings; const AKey, AValue: string);
var
  TailAt, LineIdx, MaxNum, KeyNum: Integer;
  Prefix, Key: string;
  HasPrefix: Boolean;
begin
  TailAt := Length(AKey);
  while (TailAt > 0) and (AKey[TailAt] in ['0'..'9']) do
    Dec(TailAt);
  if (TailAt = 0) or (TailAt = Length(AKey)) then
  begin
    SetKey(ALines, AKey, AValue);
    Exit;
  end;
  Prefix := Copy(AKey, 1, TailAt);
  HasPrefix := False;
  MaxNum := 0;
  for LineIdx := 0 to ALines.Count - 1 do
  begin
    Key := LineKey(ALines[LineIdx]);
    if (CompareText(Copy(Key, 1, Length(Prefix)), Prefix) <> 0) then
      Continue;
    KeyNum := StrToIntDef(Copy(Key, Length(Prefix) + 1, MaxInt), -1);
    if KeyNum < 0 then
      Continue;
    HasPrefix := True;
    if NormPath(LineValue(ALines[LineIdx])) = NormPath(AValue) then
      Exit;
    if KeyNum > MaxNum then
      MaxNum := KeyNum;
  end;
  if HasPrefix then
    ALines.Add(Prefix + IntToStr(MaxNum + 1) + '=' + AValue)
  else
    SetKey(ALines, AKey, AValue);
end;

function TTidyWork.Run(const AIniFile: string; ANotes: TStrings): Boolean;
var
  Lines: TStringList;
  Fixed, SectIdx, LineIdx, GroupIdx: Integer;
  PathSect, Sect, GroupSect: TTidySect;
  Group: TTidyGroup;
  GroupDoc: TTidyDoc;
  Stamp, FileName: string;
begin
  Result := False;
  FNotes := ANotes;
  FDir := DirOf(AIniFile);
  Stamp := FormatDateTime('yyyy-mm-dd hh:nn', Now);
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AIniFile);
    except
      FNotes.Add('Не удалось прочитать ' + AIniFile);
      Exit;
    end;
    Fixed := FixUtf8Lines(Lines);
    if Fixed > 0 then
      FNotes.Add('Строк в UTF-8 переведено в кодировку Windows: ' +
                 IntToStr(Fixed));
    FSrc.LoadLines(Lines);
  finally
    Lines.Free;
  end;

  // [Path] - папка этого компьютера
  FCurPath := '';
  PathSect := FSrc.Find('Path');
  if PathSect <> nil then
    for LineIdx := 0 to PathSect.Lines.Count - 1 do
      if (Trim(PathSect.Lines[LineIdx]) <> '') and
         (Trim(PathSect.Lines[LineIdx])[1] <> ';') then
      begin
        FCurPath := Trim(PathSect.Lines[LineIdx]);
        if CompareText(Copy(FCurPath, 1, 5), 'Path=') = 0 then
          FCurPath := Trim(Copy(FCurPath, 6, MaxInt));
        Break;
      end;
  if FCurPath = '' then
    FCurPath := FDir;

  BuildGroups;

  FNew.Need('').Lines.Add('; editor.ini: собран командой Tidy editor.ini ' +
                          Stamp + ' из ' + AIniFile);
  if PathSect <> nil then
    FNew.Need('Path').Lines.AddStrings(PathSect.Lines)
  else
    FNew.Need('Path').Lines.Add(FCurPath);

  // проекты и недавние файлы - раньше настроек: по ним видно, какие
  // группы путей - другие компьютеры (TTidyGroup.IsComputer)
  DoProjects;
  DoRecent;
  DoSettings;
  DoOrphans;
  if FRestoredKeys + FAddedKeys + FDroppedKeys + FRemovedItems > 0 then
    FNotes.Add('Настройки: значений взято из копий ' +
               IntToStr(FRestoredKeys) + ', ключей добавлено из копий ' +
               IntToStr(FAddedKeys) + ', ключей без существующих путей ' +
               IntToStr(FDroppedKeys) + ', ненайденных путей в editorOLD.ini ' +
               IntToStr(FRemovedItems));

  PutProjects(FNew, FNewPrj);
  PutRecent(FNew, FNewRecent);
  Result := WriteDoc(FNew, FDir + TidyNewName);
  if Result then
    FNotes.Add('Записан ' + FDir + TidyNewName);

  // другие компьютеры
  for GroupIdx := 0 to FGroups.Count - 1 do
  begin
    Group := TTidyGroup(FGroups[GroupIdx]);
    if not Group.IsComputer then
    begin
      for LineIdx := 0 to Group.Recent.Count - 1 do
        AddPathUnique(FOldRecent, Group.Recent[LineIdx], MaxInt);
      Continue;
    end;
    GuessPath(Group);
    FileName := GroupFileName(Group);
    if FileName = '' then
    begin
      FNotes.Add('Нет свободного номера editorN.ini для ' +
                 Group.Roots.CommaText);
      Continue;
    end;
    GroupDoc := TTidyDoc.Create;
    try
      Sect := GroupDoc.Need('');
      Sect.Lines.Add(TidyMark);
      Sect.Lines.Add('; editor.ini другого компьютера (пути ' +
                     Group.Roots.CommaText + '), собран ' + Stamp + ' из ' +
                     AIniFile);
      Sect := GroupDoc.Need('Path');
      if Group.PathFound then
        Sect.Lines.Add(';путь программы на том компьютере - предположение ' +
                       'по путям проектов; при другом пути исправить')
      else
        Sect.Lines.Add(';путь программы на том компьютере не найден - ' +
                       'указать вручную');
      Sect.Lines.Add(Group.PathGuess);
      // общие настройки - как в editorNew.ini, без ключей-путей этого
      // компьютера; поверх - значения с путями той группы
      for SectIdx := 0 to FNew.Count - 1 do
      begin
        if SpecialSection(FNew[SectIdx].Name) then
          Continue;
        Sect := nil;
        for LineIdx := 0 to FNew[SectIdx].Lines.Count - 1 do
          if not IsAbsPath(LineKey(FNew[SectIdx].Lines[LineIdx])) then
          begin
            if Sect = nil then
              Sect := GroupDoc.Need(FNew[SectIdx].Name);
            Sect.Lines.Add(FNew[SectIdx].Lines[LineIdx]);
          end;
      end;
      for SectIdx := 0 to Group.Settings.Count - 1 do
      begin
        GroupSect := Group.Settings[SectIdx];
        Sect := GroupDoc.Need(GroupSect.Name);
        for LineIdx := 0 to GroupSect.Lines.Count - 1 do
          PutGroupValue(Sect.Lines, LineKey(GroupSect.Lines[LineIdx]),
                        LineValue(GroupSect.Lines[LineIdx]));
      end;
      PutProjects(GroupDoc, Group.Projects);
      PutRecent(GroupDoc, Group.Recent);
      if WriteDoc(GroupDoc, FileName) then
        FNotes.Add('Записан ' + FileName + ' - другой компьютер (' +
                   Group.Roots.CommaText + '): проектов ' +
                   IntToStr(Group.Projects.Entries.Count) + ', недавних ' +
                   'файлов ' + IntToStr(Group.Recent.Count) + ', [Path] ' +
                   Group.PathGuess);
    finally
      GroupDoc.Free;
    end;
  end;

  FNotes.Add('Недавние файлы: в editorNew.ini ' + IntToStr(FNewRecent.Count) +
             ', в editorOLD.ini ' + IntToStr(FOldRecent.Count) +
             '; существующих сверх ' + IntToStr(TidyRecentMax) +
             ' не записано: ' + IntToStr(FRecentOverflow));

  // остатки
  PutProjects(FOld, FOldPrj);
  PutRecent(FOld, FOldRecent);
  if FOld.Empty then
    FNotes.Add('Ненайденных записей нет - editorOLD.ini не записан')
  else
  begin
    Sect := FOld.Need('');
    Sect.Lines.Insert(0, '; Записи editor.ini с путями, которых нет на этом ' +
                      'компьютере. Tidy editor.ini, ' + Stamp);
    Sect.Lines.Insert(1, '; Разделы настроек - с исходными именами; в ' +
                      'списках - только ненайденные пути');
    // раздел без имени должен идти первым
    GroupDoc := TTidyDoc.Create;
    try
      GroupDoc.Need('').Lines.AddStrings(Sect.Lines);
      for SectIdx := 0 to FOld.Count - 1 do
        if FOld[SectIdx].Name <> '' then
          GroupDoc.Need(FOld[SectIdx].Name).Lines.AddStrings(
            FOld[SectIdx].Lines);
      if WriteDoc(GroupDoc, FDir + TidyOldName) then
        FNotes.Add('Записан ' + FDir + TidyOldName);
    finally
      GroupDoc.Free;
    end;
  end;
end;

function TidyEditorIni(const AIniFile: string; ANotes: TStrings): Boolean;
var
  Work: TTidyWork;
begin
  Work := TTidyWork.Create;
  try
    Result := Work.Run(AIniFile, ANotes);
  finally
    Work.Free;
  end;
end;

end.
