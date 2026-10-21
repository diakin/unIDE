unit SearchDirs;

// ---------------------------------------------------------------------------
//  Папки поиска окон утилит (недостающие файлы, строгая проверка): список
//  для окна Directory Tree в режиме "папки поиска" (TForm1.SearchDirsDialog)
//  и его хранение в editor.ini.
//
//  Стандартные папки (Include, папка программы, папка выше ...) задаёт
//  окно утилиты, они в списке всегда и не удаляются; галка снята - папка не
//  ищется. Свои папки пользователь добавляет из дерева и может удалить.
//
//  Строки списка AItems:
//    "U1|папка" / "U0|папка" - своя папка, с галкой / без;
//    "F0|папка"              - стандартная папка, у которой галка снята
//                              (стандартные с галкой не пишутся: галка у
//                              них по умолчанию).
//  Вложенная папка при отмеченной объемлющей не ищется (SearchDirsChecked):
//  её подпапки и так обходятся.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, IniFiles;

procedure SearchDirsLoad(const AIniFile, ASection: string; AItems: TStrings);
procedure SearchDirsSave(const AIniFile, ASection: string; AItems: TStrings);

// Стандартная папка отмечена (нет строки "F0|папка")
function  SearchDirsFixedOn(AItems: TStrings; const ADir: string): Boolean;

// Папки для поиска по порядку: отмеченные стандартные из AFixed, потом
// отмеченные свои; вложенные в уже взятую - не берутся
procedure SearchDirsChecked(AFixed, AItems, AOut: TStrings);

// ADir лежит внутри AOuter (или это она же)
function  SearchDirInside(const ADir, AOuter: string): Boolean;

implementation

function NormDir(const ADir: string): string;
begin
  Result := Trim(ADir);
  if Length(Result) > 3 then
    Result := ExcludeTrailingPathDelimiter(Result);
end;

function SearchDirInside(const ADir, AOuter: string): Boolean;
var
  Inner, Outer: string;
begin
  Inner := UpperCase(IncludeTrailingPathDelimiter(NormDir(ADir)));
  Outer := UpperCase(IncludeTrailingPathDelimiter(NormDir(AOuter)));
  Result := (Length(Outer) > 1) and (Copy(Inner, 1, Length(Outer)) = Outer);
end;

procedure SearchDirsLoad(const AIniFile, ASection: string; AItems: TStrings);
var
  Ini: TIniFile;
  Count, KeyIdx: Integer;
  Line: string;
begin
  AItems.Clear;
  if (AIniFile = '') or not FileExists(AIniFile) then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    Count := Ini.ReadInteger(ASection, 'Count', 0);
    for KeyIdx := 1 to Count do
    begin
      Line := Ini.ReadString(ASection, IntToStr(KeyIdx), '');
      if (Length(Line) > 3) and (Line[3] = '|') and
         ((Line[1] = 'U') or (Line[1] = 'F')) then
        AItems.Add(Line);
    end;
  finally
    Ini.Free;
  end;
end;

procedure SearchDirsSave(const AIniFile, ASection: string; AItems: TStrings);
var
  Ini: TIniFile;
  KeyIdx: Integer;
begin
  if AIniFile = '' then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    Ini.EraseSection(ASection);
    Ini.WriteInteger(ASection, 'Count', AItems.Count);
    for KeyIdx := 0 to AItems.Count - 1 do
      Ini.WriteString(ASection, IntToStr(KeyIdx + 1), AItems[KeyIdx]);
  finally
    Ini.Free;
  end;
end;

function SearchDirsFixedOn(AItems: TStrings; const ADir: string): Boolean;
var
  ItemIdx: Integer;
begin
  Result := True;
  for ItemIdx := 0 to AItems.Count - 1 do
    if (Copy(AItems[ItemIdx], 1, 3) = 'F0|') and
       (CompareText(NormDir(Copy(AItems[ItemIdx], 4, MaxInt)),
                    NormDir(ADir)) = 0) then
    begin
      Result := False;
      Exit;
    end;
end;

procedure SearchDirsChecked(AFixed, AItems, AOut: TStrings);

  procedure TryAdd(const ADir: string);
  var
    OutIdx: Integer;
  begin
    if NormDir(ADir) = '' then
      Exit;
    for OutIdx := 0 to AOut.Count - 1 do
      if SearchDirInside(ADir, AOut[OutIdx]) then
        Exit;
    // Новая объемлет уже взятые - те больше не нужны
    for OutIdx := AOut.Count - 1 downto 0 do
      if SearchDirInside(AOut[OutIdx], ADir) then
        AOut.Delete(OutIdx);
    AOut.Add(NormDir(ADir));
  end;

var
  ItemIdx: Integer;
begin
  AOut.Clear;
  for ItemIdx := 0 to AFixed.Count - 1 do
    if SearchDirsFixedOn(AItems, AFixed[ItemIdx]) then
      TryAdd(AFixed[ItemIdx]);
  for ItemIdx := 0 to AItems.Count - 1 do
    if Copy(AItems[ItemIdx], 1, 3) = 'U1|' then
      TryAdd(Copy(AItems[ItemIdx], 4, MaxInt));
end;

end.
