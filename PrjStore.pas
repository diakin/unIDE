unit PrjStore;

// ---------------------------------------------------------------------------
//  Проекты в editor.ini и выбор editor.ini по папке программы. Без VCL.
//
//  editor.ini - настройки ОДНОГО компьютера, вместе с проектами:
//
//    [Path]
//    ;путь по которому проверяется актуальность ini файла
//    D:\_F\balan\_SyntaxHLClaude\SyntaxHLBeta\
//
//    [Projects]
//    BalKom1A=D:\...\B1Acurr200M56\          имя = папка проекта
//
//    [Project.BalKom1A]
//    Type=Delphi
//    Target=\BalKom1A.dpr                    \ в начале - от папки проекта
//    Windows_Index=0
//    Windows_win0=1 D:\...\BalKom1A.dpr
//    Windows_curposic0=0
//    Tabs_TabIndex=0
//    Bookmarks_bmarkCaption0,0=11 // текст
//
//  Разделы бывшего .prj лежат в одном разделе [Project.<имя>]: [Project] -
//  ключи как есть, остальные ([Windows], [Tabs], [Bookmarks], [HotBookmarks],
//  [Release]) - с приставкой "<раздел>_". TProjectIni читает и пишет их
//  теми же вызовами, что TIniFile - разделом и ключом бывшего .prj.
//
//  Раздел проекта читается из текста файла и пишется в него целиком, одной
//  записью (Save): ключей у проекта сотни, и запись каждого через
//  WritePrivateProfileString переписывала бы файл сотни раз. Перед записью
//  файл читается заново - разделы, которые за это время записал TIniFile,
//  не теряются. Комментарии вне раздела проекта остаются.
//
//  Несколько компьютеров (папка редактора на флешке): рядом с editor.ini
//  лежат editor1.ini, editor2.ini... - каждый со своего компьютера, его
//  папка - в [Path]. При запуске (SelectEditorIni) editor.ini другого
//  компьютера переименовывается в свободный editorN.ini, а editorN.ini этой
//  папки - в editor.ini. Такого нет - editor.ini остаётся (его копия -
//  в editorN.ini), в нём новый [Path], а проекты прежнего компьютера
//  убираются: остальные настройки - цвета, компиляторы - общие.
// ---------------------------------------------------------------------------

interface

uses
  {$IFDEF MSWINDOWS}Windows,{$ENDIF} SysUtils, Classes;

const
  ProjectSectionPrefix = 'Project.';   // [Project.<имя>]
  IniPathSection = 'Path';

type
  TProjectIni = class
  private
    FIniFile: string;
    FSection: string;          // Project.<имя>
    FLines: TStringList;       // строки раздела: "ключ=значение", комментарии
    FExists: Boolean;          // раздел был в файле
    FModified: Boolean;
    function KeyOf(const ASection, AKey: string): string;
    function IndexOfKey(const AFullKey: string): Integer;
  public
    constructor Create(const AIniFile, AProject: string);
    destructor Destroy; override;    // изменения - в файл (Save)
    function Exists: Boolean;
    function ReadString(const ASection, AKey, ADefault: string): string;
    function ReadInteger(const ASection, AKey: string;
                         ADefault: Integer): Integer;
    procedure WriteString(const ASection, AKey, AValue: string);
    procedure WriteInteger(const ASection, AKey: string; AValue: Integer);
    function ValueExists(const ASection, AKey: string): Boolean;
    procedure DeleteKey(const ASection, AKey: string);
    procedure EraseSection(const ASection: string);
    procedure ReadSection(const ASection: string; AKeys: TStrings);
    procedure Clear;                 // все ключи проекта
    procedure Save;
    property Modified: Boolean read FModified;
  end;

// Строки файла - копия; nil, если файла нет. Освобождает вызывающий.
function IniLoadLines(const AFile: string): TStringList;
// Забыть запомненный текст файла (после записи файла не через этот модуль,
// если она должна быть видна сразу)
procedure IniCacheReset;
// Номер строки заголовка [ASection] и последней строки раздела; -1 - нет
function IniFindSection(ALines: TStrings; const ASection: string;
                        var ALast: Integer): Integer;
// Раздел ASection файла - строками ABody; ABody = nil - раздел удаляется.
// Раздела нет - дописывается в конец.
function IniReplaceSection(const AFile, ASection: string;
                           ABody: TStrings): Boolean;
// Имена всех разделов файла
procedure IniSectionNames(const AFile: string; ANames: TStrings);
// Раздел ADst - копия ASrc (ADst, если был, заменяется). False - ASrc нет.
function IniCopySection(const AFile, ASrc, ADst: string): Boolean;
// ASrc переименовывается в ADst (ADst, если был, заменяется)
function IniRenameSection(const AFile, ASrc, ADst: string): Boolean;

// Папка из [Path]: первая строка раздела, не комментарий (или Path=...)
function IniPathOf(const AFile: string): string;
// [Path] файла - APath (раздел создаётся в начале файла)
procedure IniSetPath(const AFile, APath: string);
function SamePathText(const APathA, APathB: string): Boolean;

// editor.ini для папки программы AExeDir (см. в начале модуля). Что
// сделано - строками в ANotes. True - файлы переименовывались.
function SelectEditorIni(const AExeDir: string; ANotes: TStrings): Boolean;

implementation

const
  MaxIniCopies = 99;

// ---------------------------------------------------------------------------
//  Текст файла
// ---------------------------------------------------------------------------

// Последний прочитанный файл: проекты читаются часто (тип проекта - при
// каждой смене вкладки, список проектов - в меню), а файл меняется редко.
// Ключ - время записи и размер; свои записи сбрасывают его сами.
var
  CacheFile: string;
  CacheStamp: string;
  CacheLines: TStringList;

function FileStampOf(const AFile: string): string;
var
  Found: TSearchRec;
begin
  Result := '';
  if FindFirst(AFile, faAnyFile, Found) <> 0 then
    Exit;
  try
    Result := IntToStr(Found.Size) + ':' + IntToStr(Found.Time);
    {$IFDEF MSWINDOWS}
    Result := Result + ':' +
      IntToStr(Found.FindData.ftLastWriteTime.dwLowDateTime) + ':' +
      IntToStr(Found.FindData.ftLastWriteTime.dwHighDateTime);
    {$ENDIF}
  finally
    FindClose(Found);
  end;
end;

procedure IniCacheReset;
begin
  CacheFile := '';
  CacheStamp := '';
  FreeAndNil(CacheLines);
end;

// AFresh - мимо запомненного: перед записью файл читается с диска
function IniLoadLinesEx(const AFile: string; AFresh: Boolean): TStringList;
var
  Stamp: string;
begin
  Result := nil;
  if not FileExists(AFile) then
    Exit;
  Stamp := FileStampOf(AFile);
  if not AFresh and (CacheLines <> nil) and (Stamp <> '') and
     (CompareText(CacheFile, AFile) = 0) and (CacheStamp = Stamp) then
  begin
    Result := TStringList.Create;
    Result.Assign(CacheLines);
    Exit;
  end;
  Result := TStringList.Create;
  try
    Result.LoadFromFile(AFile);
  except
    FreeAndNil(Result);
    Exit;
  end;
  if CacheLines = nil then
    CacheLines := TStringList.Create;
  CacheLines.Assign(Result);
  CacheFile := AFile;
  CacheStamp := Stamp;
end;

function IniLoadLines(const AFile: string): TStringList;
begin
  Result := IniLoadLinesEx(AFile, False);
end;

// Запись строк в файл; запомненный текст - сброшен
function IniSaveLines(ALines: TStrings; const AFile: string): Boolean;
begin
  IniCacheReset;
  try
    ALines.SaveToFile(AFile);
    Result := True;
  except
    Result := False;
  end;
end;

function IsSectionHeader(const ALine: string; var AName: string): Boolean;
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

function IniFindSection(ALines: TStrings; const ASection: string;
                        var ALast: Integer): Integer;
var
  LineIdx: Integer;
  Name: string;
begin
  Result := -1;
  ALast := -1;
  for LineIdx := 0 to ALines.Count - 1 do
    if IsSectionHeader(ALines[LineIdx], Name) then
    begin
      if Result >= 0 then
      begin
        ALast := LineIdx - 1;
        Exit;
      end;
      if CompareText(Name, ASection) = 0 then
        Result := LineIdx;
    end;
  if Result >= 0 then
    ALast := ALines.Count - 1;
end;

function IniReplaceSection(const AFile, ASection: string;
                           ABody: TStrings): Boolean;
var
  Lines: TStringList;
  First, Last, LineIdx, InsertAt: Integer;
begin
  Result := False;
  Lines := IniLoadLinesEx(AFile, True);
  if Lines = nil then
  begin
    if ABody = nil then
    begin
      Result := True;
      Exit;
    end;
    Lines := TStringList.Create;
  end;
  try
    First := IniFindSection(Lines, ASection, Last);
    if First >= 0 then
    begin
      // Пустые строки в конце раздела - разделитель перед следующим, их
      // оставляем
      while (Last > First) and (Trim(Lines[Last]) = '') do
        Dec(Last);
      for LineIdx := Last downto First do
        Lines.Delete(LineIdx);
      InsertAt := First;
      // Раздел удалён целиком - и пустая строка за ним
      if (ABody = nil) and (InsertAt < Lines.Count) and
         (Trim(Lines[InsertAt]) = '') then
        Lines.Delete(InsertAt);
    end
    else
    begin
      if ABody = nil then
      begin
        Result := True;
        Exit;
      end;
      if (Lines.Count > 0) and (Trim(Lines[Lines.Count - 1]) <> '') then
        Lines.Add('');
      InsertAt := Lines.Count;
    end;
    if ABody <> nil then
    begin
      Lines.Insert(InsertAt, '[' + ASection + ']');
      for LineIdx := 0 to ABody.Count - 1 do
        Lines.Insert(InsertAt + 1 + LineIdx, ABody[LineIdx]);
    end;
    Result := IniSaveLines(Lines, AFile);
  finally
    Lines.Free;
  end;
end;

procedure IniSectionNames(const AFile: string; ANames: TStrings);
var
  Lines: TStringList;
  LineIdx: Integer;
  Name: string;
begin
  ANames.Clear;
  Lines := IniLoadLines(AFile);
  if Lines = nil then
    Exit;
  try
    for LineIdx := 0 to Lines.Count - 1 do
      if IsSectionHeader(Lines[LineIdx], Name) then
        ANames.Add(Name);
  finally
    Lines.Free;
  end;
end;

function IniCopySection(const AFile, ASrc, ADst: string): Boolean;
var
  Lines, Body: TStringList;
  First, Last, LineIdx: Integer;
begin
  Result := False;
  Lines := IniLoadLinesEx(AFile, True);
  if Lines = nil then
    Exit;
  Body := TStringList.Create;
  try
    First := IniFindSection(Lines, ASrc, Last);
    if First < 0 then
      Exit;
    while (Last > First) and (Trim(Lines[Last]) = '') do
      Dec(Last);
    for LineIdx := First + 1 to Last do
      Body.Add(Lines[LineIdx]);
    Result := IniReplaceSection(AFile, ADst, Body);
  finally
    Body.Free;
    Lines.Free;
  end;
end;

function IniRenameSection(const AFile, ASrc, ADst: string): Boolean;
begin
  Result := CompareText(ASrc, ADst) = 0;
  if Result then
    Exit;
  Result := IniCopySection(AFile, ASrc, ADst) and
            IniReplaceSection(AFile, ASrc, nil);
end;

// ---------------------------------------------------------------------------
//  [Path]
// ---------------------------------------------------------------------------

function PathLineValue(const ALine: string): string;
var
  Txt: string;
  EqAt: Integer;
begin
  Result := '';
  Txt := Trim(ALine);
  if (Txt = '') or (Txt[1] = ';') or (Txt[1] = '#') then
    Exit;
  EqAt := Pos('=', Txt);
  if (EqAt > 0) and (CompareText(Trim(Copy(Txt, 1, EqAt - 1)), 'Path') = 0) then
    Result := Trim(Copy(Txt, EqAt + 1, MaxInt))
  else if EqAt = 0 then
    Result := Txt;
end;

function IniPathOf(const AFile: string): string;
var
  Lines: TStringList;
  First, Last, LineIdx: Integer;
begin
  Result := '';
  Lines := IniLoadLines(AFile);
  if Lines = nil then
    Exit;
  try
    First := IniFindSection(Lines, IniPathSection, Last);
    if First < 0 then
      Exit;
    for LineIdx := First + 1 to Last do
    begin
      Result := PathLineValue(Lines[LineIdx]);
      if Result <> '' then
        Exit;
    end;
  finally
    Lines.Free;
  end;
end;

procedure IniSetPath(const AFile, APath: string);
var
  Lines: TStringList;
  First, Last, LineIdx: Integer;
begin
  Lines := IniLoadLinesEx(AFile, True);
  if Lines = nil then
    Lines := TStringList.Create;
  try
    First := IniFindSection(Lines, IniPathSection, Last);
    if First >= 0 then
    begin
      for LineIdx := First + 1 to Last do
        if PathLineValue(Lines[LineIdx]) <> '' then
        begin
          Lines[LineIdx] := APath;
          IniSaveLines(Lines, AFile);
          Exit;
        end;
      Lines.Insert(First + 1, APath);
    end
    else
    begin
      // Первым разделом файла, как в образце
      Lines.Insert(0, '[' + IniPathSection + ']');
      Lines.Insert(1, ';путь по которому проверяется актуальность ini файла');
      Lines.Insert(2, ';если путь не совпадает с текущей папкой exe, то ini ' +
                      'файл не актуальный');
      Lines.Insert(3, APath);
      Lines.Insert(4, '');
    end;
    IniSaveLines(Lines, AFile);
  finally
    Lines.Free;
  end;
end;

function SamePathText(const APathA, APathB: string): Boolean;
begin
  Result := (APathA <> '') and (APathB <> '') and
    (CompareText(IncludeTrailingPathDelimiter(ExpandFileName(APathA)),
                 IncludeTrailingPathDelimiter(ExpandFileName(APathB))) = 0);
end;

// ---------------------------------------------------------------------------
//  Выбор editor.ini
// ---------------------------------------------------------------------------

function CopyNumberedName(const AExeDir: string; ANum: Integer): string;
begin
  Result := AExeDir + 'editor' + IntToStr(ANum) + '.ini';
end;

function FreeCopyNumber(const AExeDir: string): Integer;
begin
  Result := 1;
  while (Result <= MaxIniCopies) and
        FileExists(CopyNumberedName(AExeDir, Result)) do
    Inc(Result);
end;

// Копия editorN.ini, сохранённая в этой папке; 0 - нет
function CopyForDir(const AExeDir: string): Integer;
var
  CopyNum: Integer;
begin
  Result := 0;
  for CopyNum := 1 to MaxIniCopies do
    if FileExists(CopyNumberedName(AExeDir, CopyNum)) and
       SamePathText(IniPathOf(CopyNumberedName(AExeDir, CopyNum)), AExeDir) then
    begin
      Result := CopyNum;
      Exit;
    end;
end;

// Проекты другого компьютера: [Projects], [Project.*], [ProjectsOld*]
procedure DropProjectSections(const AFile: string);
var
  Names: TStringList;
  NameIdx: Integer;
  Name: string;
begin
  Names := TStringList.Create;
  try
    IniSectionNames(AFile, Names);
    for NameIdx := 0 to Names.Count - 1 do
    begin
      Name := Names[NameIdx];
      if (CompareText(Name, 'Projects') = 0) or
         (CompareText(Copy(Name, 1, Length(ProjectSectionPrefix)),
                      ProjectSectionPrefix) = 0) or
         (CompareText(Copy(Name, 1, 11), 'ProjectsOld') = 0) then
        IniReplaceSection(AFile, Name, nil);
    end;
  finally
    Names.Free;
  end;
end;

function SelectEditorIni(const AExeDir: string; ANotes: TStrings): Boolean;
var
  ExeDir, MainIni, CurPath, SavedName: string;
  Found, FreeNum: Integer;
  Lines: TStringList;
begin
  Result := False;
  IniCacheReset;
  ExeDir := IncludeTrailingPathDelimiter(AExeDir);
  MainIni := ExeDir + 'editor.ini';

  // editor.ini нет - копия этой папки, если она есть
  if not FileExists(MainIni) then
  begin
    Found := CopyForDir(ExeDir);
    if (Found > 0) and RenameFile(CopyNumberedName(ExeDir, Found), MainIni) then
    begin
      Result := True;
      ANotes.Add('editor.ini: взят editor' + IntToStr(Found) + '.ini - ' +
                 'сохранён в этой папке');
    end;
    Exit;
  end;

  CurPath := IniPathOf(MainIni);
  // Файл прежнего вида, без [Path] - он здешний: путь записывается
  if CurPath = '' then
  begin
    IniSetPath(MainIni, ExeDir);
    ANotes.Add('editor.ini: записан путь [Path] ' + ExeDir);
    Exit;
  end;
  if SamePathText(CurPath, ExeDir) then
    Exit;

  // editor.ini другого компьютера (папки) - в свободный editorN.ini
  FreeNum := FreeCopyNumber(ExeDir);
  if FreeNum > MaxIniCopies then
  begin
    ANotes.Add('editor.ini сохранён для ' + CurPath + ', а программа в ' +
               ExeDir + ': свободного номера editorN.ini нет, файл не ' +
               'переименован');
    Exit;
  end;
  Found := CopyForDir(ExeDir);
  SavedName := CopyNumberedName(ExeDir, FreeNum);
  if not RenameFile(MainIni, SavedName) then
  begin
    ANotes.Add('editor.ini: не удалось переименовать в ' +
               ExtractFileName(SavedName));
    Exit;
  end;
  Result := True;
  ANotes.Add('editor.ini (папка ' + CurPath + ') переименован в ' +
             ExtractFileName(SavedName));

  IniCacheReset;
  if (Found > 0) and RenameFile(CopyNumberedName(ExeDir, Found), MainIni) then
  begin
    ANotes.Add('editor' + IntToStr(Found) + '.ini (папка ' + ExeDir +
               ') переименован в editor.ini');
    Exit;
  end;

  // Этой папки ещё не было: настройки те же, проекты - заново
  Lines := IniLoadLinesEx(SavedName, True);
  try
    if Lines <> nil then
      IniSaveLines(Lines, MainIni);
  finally
    Lines.Free;
  end;
  IniSetPath(MainIni, ExeDir);
  DropProjectSections(MainIni);
  ANotes.Add('editor.ini для этой папки не было: настройки взяты из ' +
             ExtractFileName(SavedName) + ', список проектов пуст');
end;

// ---------------------------------------------------------------------------
//  TProjectIni
// ---------------------------------------------------------------------------

constructor TProjectIni.Create(const AIniFile, AProject: string);
var
  Lines: TStringList;
  First, Last, LineIdx: Integer;
begin
  inherited Create;
  FIniFile := AIniFile;
  FSection := ProjectSectionPrefix + AProject;
  FLines := TStringList.Create;
  Lines := IniLoadLines(AIniFile);
  if Lines = nil then
    Exit;
  try
    First := IniFindSection(Lines, FSection, Last);
    if First < 0 then
      Exit;
    FExists := True;
    // Пустые строки в конце раздела не берём: при записи они лишние
    while (Last > First) and (Trim(Lines[Last]) = '') do
      Dec(Last);
    for LineIdx := First + 1 to Last do
      FLines.Add(Lines[LineIdx]);
  finally
    Lines.Free;
  end;
end;

destructor TProjectIni.Destroy;
begin
  if FModified then
    Save;
  FLines.Free;
  inherited Destroy;
end;

function TProjectIni.Exists: Boolean;
begin
  Result := FExists or (FLines.Count > 0);
end;

function TProjectIni.KeyOf(const ASection, AKey: string): string;
begin
  if (ASection = '') or (CompareText(ASection, 'Project') = 0) then
    Result := AKey
  else
    Result := ASection + '_' + AKey;
end;

function TProjectIni.IndexOfKey(const AFullKey: string): Integer;
var
  LineIdx, EqAt: Integer;
  Txt: string;
begin
  Result := -1;
  for LineIdx := 0 to FLines.Count - 1 do
  begin
    Txt := TrimLeft(FLines[LineIdx]);
    EqAt := Pos('=', Txt);
    if (EqAt > 1) and (Txt[1] <> ';') and
       (CompareText(Trim(Copy(Txt, 1, EqAt - 1)), AFullKey) = 0) then
    begin
      Result := LineIdx;
      Exit;
    end;
  end;
end;

function TProjectIni.ReadString(const ASection, AKey,
                                ADefault: string): string;
var
  LineIdx: Integer;
  Txt: string;
begin
  LineIdx := IndexOfKey(KeyOf(ASection, AKey));
  if LineIdx < 0 then
  begin
    Result := ADefault;
    Exit;
  end;
  Txt := FLines[LineIdx];
  Result := Trim(Copy(Txt, Pos('=', Txt) + 1, MaxInt));
end;

function TProjectIni.ReadInteger(const ASection, AKey: string;
                                 ADefault: Integer): Integer;
begin
  Result := StrToIntDef(ReadString(ASection, AKey, ''), ADefault);
end;

procedure TProjectIni.WriteString(const ASection, AKey, AValue: string);
var
  FullKey, NewLine: string;
  LineIdx, InsertAt: Integer;
begin
  FullKey := KeyOf(ASection, AKey);
  NewLine := FullKey + '=' + AValue;
  LineIdx := IndexOfKey(FullKey);
  if LineIdx >= 0 then
  begin
    if FLines[LineIdx] <> NewLine then
    begin
      FLines[LineIdx] := NewLine;
      FModified := True;
    end;
    Exit;
  end;
  // Новый ключ - за последним ключом того же раздела (Windows_..., Tabs_...):
  // так файл читается по разделам
  InsertAt := FLines.Count;
  if (ASection <> '') and (CompareText(ASection, 'Project') <> 0) then
    for LineIdx := FLines.Count - 1 downto 0 do
      if CompareText(Copy(Trim(FLines[LineIdx]), 1, Length(ASection) + 1),
                     ASection + '_') = 0 then
      begin
        InsertAt := LineIdx + 1;
        Break;
      end;
  FLines.Insert(InsertAt, NewLine);
  FModified := True;
end;

procedure TProjectIni.WriteInteger(const ASection, AKey: string;
                                   AValue: Integer);
begin
  WriteString(ASection, AKey, IntToStr(AValue));
end;

function TProjectIni.ValueExists(const ASection, AKey: string): Boolean;
begin
  Result := IndexOfKey(KeyOf(ASection, AKey)) >= 0;
end;

procedure TProjectIni.DeleteKey(const ASection, AKey: string);
var
  LineIdx: Integer;
begin
  LineIdx := IndexOfKey(KeyOf(ASection, AKey));
  if LineIdx >= 0 then
  begin
    FLines.Delete(LineIdx);
    FModified := True;
  end;
end;

// Все ключи бывшего раздела ASection; 'Project' - ключи без приставки
procedure TProjectIni.EraseSection(const ASection: string);
var
  Keys: TStringList;
  KeyIdx: Integer;
begin
  Keys := TStringList.Create;
  try
    ReadSection(ASection, Keys);
    for KeyIdx := 0 to Keys.Count - 1 do
      DeleteKey(ASection, Keys[KeyIdx]);
  finally
    Keys.Free;
  end;
end;

procedure TProjectIni.ReadSection(const ASection: string; AKeys: TStrings);
var
  LineIdx, EqAt: Integer;
  Txt, Key, Prefix: string;
  PlainKeys: Boolean;
begin
  AKeys.Clear;
  PlainKeys := (ASection = '') or (CompareText(ASection, 'Project') = 0);
  Prefix := ASection + '_';
  for LineIdx := 0 to FLines.Count - 1 do
  begin
    Txt := Trim(FLines[LineIdx]);
    EqAt := Pos('=', Txt);
    if (EqAt <= 1) or (Txt[1] = ';') then
      Continue;
    Key := Trim(Copy(Txt, 1, EqAt - 1));
    if PlainKeys then
    begin
      // Ключи [Project] - без "_" (Windows_win0 - раздел окон)
      if Pos('_', Key) = 0 then
        AKeys.Add(Key);
    end
    else if CompareText(Copy(Key, 1, Length(Prefix)), Prefix) = 0 then
      AKeys.Add(Copy(Key, Length(Prefix) + 1, MaxInt));
  end;
end;

procedure TProjectIni.Clear;
begin
  if FLines.Count > 0 then
    FModified := True;
  FLines.Clear;
end;

procedure TProjectIni.Save;
begin
  if IniReplaceSection(FIniFile, FSection, FLines) then
  begin
    FExists := True;
    FModified := False;
  end;
end;

initialization

finalization
  IniCacheReset;

end.
