unit MakeProj;

// ---------------------------------------------------------------------------
//  Проект C / C++ со сборкой make (Makefile). Без VCL.
//
//  Пример - Walker (движок на исходниках Quake III): из папки code
//    mingw32-make -f Makefile.mingw [engine|qvm|clean]
//  результат - walker\dist\Walker.exe, запуск из walker\dist:
//    Walker.exe +map wk_islands
//
//  Настройки - в разделе проекта ([Project.<имя>] в editor.ini, через
//  TProjectIni), с приставкой Make_:
//    Make_Dir=code              папка, из которой запускается make; внутри
//                               папки проекта - от неё, иначе полный путь.
//                               Пусто - папка с Makefile (MakeFindDefault)
//    Make_File=Makefile.mingw   ключ -f; пусто - make ищет Makefile сам
//    Make_Target=engine         цель; пусто - первая цель Makefile (all)
//    Make_Jobs=0                ключ -j; 0 - не задавать
//    Make_Tool=                 make полным путём; пусто - mingw32-make
//                               32-битного MinGW (DevTools), иначе make
//                               из PATH
//    Make_GitSh=1               папка usr\bin Git for Windows - в PATH
//                               сборки (sh, cp, rm, mkdir для Makefile,
//                               написанного под Git Bash)
//    Make_RunExe=walker\dist\Walker.exe   Run: программа
//    Make_RunArgs=+map wk_islands         её параметры
//    Make_RunDir=walker\dist              рабочая папка; пусто - папка exe
//
//  Сборку и запуск делает Unit1 (CompileMake, MakeRunProgram).
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, PrjStore;

const
  MakeSection = 'Make';            // ключи Make_* в разделе проекта

type
  TMakeSettings = record
    ProjectDir: string;     // папка проекта, с \ в конце
    MakeDir: string;        // полный путь без \ в конце
    MakeFile: string;       // как в -f (имя или путь от MakeDir); '' - нет
    Target: string;         // '' - цель по умолчанию
    Jobs: Integer;          // -j; 0 - нет
    Tool: string;           // полный путь; '' - найти (Unit1)
    GitSh: Boolean;
    RunExe: string;         // полный путь; '' - не задано
    RunArgs: string;
    RunDir: string;         // полный путь; '' - папка exe
  end;

// Тип проекта со сборкой make
function MakeProjectType(const AType: string): Boolean;
// Имя файла - Makefile (Makefile, makefile, GNUmakefile, Makefile.*,
// *.mak, *.mk)
function MakeIsMakefileName(const AFileName: string): Boolean;
// Makefile в папке ADir: под Windows сначала Makefile.mingw, потом
// Makefile, makefile, GNUmakefile; имя без пути; нет - ''
function MakeFileIn(const ADir: string): string;
// Папка с Makefile в проекте: сама папка, code, src, build, потом любая
// подпапка первого уровня (по алфавиту). AMakeDir - полный путь без \,
// AMakeFile - имя. Нет - False
function MakeFindDefault(const AProjectDir: string;
                         var AMakeDir, AMakeFile: string): Boolean;
// Цели Makefile AFile (правила "имя: ..." без шаблонов и переменных);
// первая - цель по умолчанию
procedure MakeTargets(const AFile: string; AList: TStrings);
// Путь в настройках: внутри папки проекта - от неё, иначе полный
function MakePathToStore(const AProjectDir, APath: string): string;
function MakePathFromStore(const AProjectDir, AValue: string): string;
procedure MakeLoadSettings(APrj: TProjectIni; const AProjectDir: string;
                           var ASettings: TMakeSettings);
procedure MakeSaveSettings(APrj: TProjectIni; const ASettings: TMakeSettings);
// Полный путь Makefile ('' - не задан и не найден в MakeDir)
function MakeFilePath(const ASettings: TMakeSettings): string;
// Параметры make: -f "<файл>" -j N <цель>
function MakeArgs(const ASettings: TMakeSettings): string;
// Рабочая папка запуска: RunDir, иначе папка RunExe
function MakeRunDir(const ASettings: TMakeSettings): string;
// Что и как будет собрано - строками для лога сборки
procedure MakeDescribeBuild(const ASettings: TMakeSettings; ALines: TStrings);

implementation

function MakeProjectType(const AType: string): Boolean;
begin
  Result := (CompareText(AType, 'C project') = 0) or
            (CompareText(AType, 'CPP project') = 0);
end;

function MakeIsMakefileName(const AFileName: string): Boolean;
var
  LowName, Ext: string;
begin
  LowName := LowerCase(ExtractFileName(AFileName));
  Ext := ExtractFileExt(LowName);
  Result := (LowName = 'makefile') or (LowName = 'gnumakefile') or
            (Copy(LowName, 1, 9) = 'makefile.') or (Ext = '.mak') or
            (Ext = '.mk');
end;

function MakeFileIn(const ADir: string): string;
const
  NameCount = 4;
  Names: array[0..NameCount - 1] of string = (
    {$IFDEF UNIX}'GNUmakefile', 'makefile', 'Makefile', 'Makefile.mingw'
    {$ELSE}'Makefile.mingw', 'Makefile', 'makefile', 'GNUmakefile'{$ENDIF});
var
  Dir: string;
  NameIdx: Integer;
begin
  Result := '';
  if Trim(ADir) = '' then
    Exit;
  Dir := IncludeTrailingPathDelimiter(Trim(ADir));
  for NameIdx := 0 to NameCount - 1 do
    if FileExists(Dir + Names[NameIdx]) then
    begin
      Result := Names[NameIdx];
      Exit;
    end;
end;

function MakeFindDefault(const AProjectDir: string;
                         var AMakeDir, AMakeFile: string): Boolean;
const
  SubCount = 3;
  Subs: array[0..SubCount - 1] of string = ('code', 'src', 'build');
var
  Dir, FileName: string;
  SubIdx: Integer;
  SR: TSearchRec;
  Names: TStringList;
begin
  Result := False;
  AMakeDir := '';
  AMakeFile := '';
  if Trim(AProjectDir) = '' then
    Exit;
  Dir := IncludeTrailingPathDelimiter(Trim(AProjectDir));
  FileName := MakeFileIn(Dir);
  if FileName <> '' then
  begin
    AMakeDir := ExcludeTrailingPathDelimiter(Dir);
    AMakeFile := FileName;
    Result := True;
    Exit;
  end;
  for SubIdx := 0 to SubCount - 1 do
  begin
    FileName := MakeFileIn(Dir + Subs[SubIdx]);
    if FileName <> '' then
    begin
      AMakeDir := Dir + Subs[SubIdx];
      AMakeFile := FileName;
      Result := True;
      Exit;
    end;
  end;
  Names := TStringList.Create;
  try
    if FindFirst(Dir + '*', faDirectory, SR) = 0 then
    try
      repeat
        if ((SR.Attr and faDirectory) <> 0) and (SR.Name <> '.') and
           (SR.Name <> '..') and (SR.Name[1] <> '.') then
          Names.Add(SR.Name);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
    Names.Sort;
    for SubIdx := 0 to Names.Count - 1 do
    begin
      FileName := MakeFileIn(Dir + Names[SubIdx]);
      if FileName <> '' then
      begin
        AMakeDir := Dir + Names[SubIdx];
        AMakeFile := FileName;
        Result := True;
        Exit;
      end;
    end;
  finally
    Names.Free;
  end;
end;

procedure MakeTargets(const AFile: string; AList: TStrings);
var
  Lines: TStringList;
  LineIdx, ColonPos, CharIdx: Integer;
  LineText, Head, Name: string;
  Usable: Boolean;
begin
  AList.Clear;
  if (AFile = '') or not FileExists(AFile) then
    Exit;
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFile);
    except
      Exit;
    end;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      LineText := Lines[LineIdx];
      // Команды правил - с табуляции; комментарии, пустые строки
      if (LineText = '') or (LineText[1] in [#9, ' ', '#', '.']) then
        Continue;
      ColonPos := Pos(':', LineText);
      if ColonPos < 2 then
        Continue;
      // "a := b", "a ::= b" - переменная, а не правило
      if (ColonPos < Length(LineText)) and (LineText[ColonPos + 1] in [':', '=']) then
        Continue;
      Head := Copy(LineText, 1, ColonPos - 1);
      if (Pos('=', Head) > 0) or (Pos('$', Head) > 0) or
         (Pos('%', Head) > 0) or (Pos('(', Head) > 0) then
        Continue;
      // Несколько целей через пробел - каждая
      Head := Trim(Head) + ' ';
      while Trim(Head) <> '' do
      begin
        Head := TrimLeft(Head);
        Name := Copy(Head, 1, Pos(' ', Head) - 1);
        Head := Copy(Head, Pos(' ', Head) + 1, MaxInt);
        Usable := Name <> '';
        // Файлы (main.o, ../dist/x.exe) - не цели для списка
        for CharIdx := 1 to Length(Name) do
          if Name[CharIdx] in ['.', '/', '\'] then
            Usable := False;
        if Usable and (AList.IndexOf(Name) < 0) then
          AList.Add(Name);
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function MakePathToStore(const AProjectDir, APath: string): string;
var
  Dir: string;
begin
  Result := Trim(APath);
  if (Result = '') or (Trim(AProjectDir) = '') then
    Exit;
  Dir := IncludeTrailingPathDelimiter(Trim(AProjectDir));
  if CompareText(Copy(Result, 1, Length(Dir)), Dir) = 0 then
    Result := Copy(Result, Length(Dir) + 1, MaxInt)
  else if CompareText(Result, ExcludeTrailingPathDelimiter(Dir)) = 0 then
    Result := '.';
end;

function MakePathFromStore(const AProjectDir, AValue: string): string;
var
  Value: string;
begin
  Value := Trim(AValue);
  Result := '';
  if Value = '' then
    Exit;
  if Value = '.' then
  begin
    Result := ExcludeTrailingPathDelimiter(Trim(AProjectDir));
    Exit;
  end;
  if (ExtractFileDrive(Value) <> '') or (Value[1] in ['\', '/']) or
     (Trim(AProjectDir) = '') then
    Result := Value
  else
    Result := ExpandFileName(IncludeTrailingPathDelimiter(Trim(AProjectDir)) +
                             Value);
end;

procedure MakeLoadSettings(APrj: TProjectIni; const AProjectDir: string;
                           var ASettings: TMakeSettings);
var
  FoundDir, FoundFile: string;
begin
  ASettings.ProjectDir := '';
  if Trim(AProjectDir) <> '' then
    ASettings.ProjectDir := IncludeTrailingPathDelimiter(Trim(AProjectDir));
  ASettings.MakeDir := ExcludeTrailingPathDelimiter(MakePathFromStore(
    ASettings.ProjectDir, APrj.ReadString(MakeSection, 'Dir', '')));
  ASettings.MakeFile := Trim(APrj.ReadString(MakeSection, 'File', ''));
  // Папка не задана - где лежит Makefile; файл - найденный там
  if ASettings.MakeDir = '' then
  begin
    if MakeFindDefault(ASettings.ProjectDir, FoundDir, FoundFile) then
    begin
      ASettings.MakeDir := FoundDir;
      if ASettings.MakeFile = '' then
        ASettings.MakeFile := FoundFile;
    end
    else
      ASettings.MakeDir := ExcludeTrailingPathDelimiter(ASettings.ProjectDir);
  end
  else if (ASettings.MakeFile = '') and
          not APrj.ValueExists(MakeSection, 'File') then
    ASettings.MakeFile := MakeFileIn(ASettings.MakeDir);
  ASettings.Target := Trim(APrj.ReadString(MakeSection, 'Target', ''));
  ASettings.Jobs := APrj.ReadInteger(MakeSection, 'Jobs', 0);
  if ASettings.Jobs < 0 then
    ASettings.Jobs := 0;
  ASettings.Tool := MakePathFromStore(ASettings.ProjectDir,
                                      APrj.ReadString(MakeSection, 'Tool', ''));
  ASettings.GitSh := APrj.ReadString(MakeSection, 'GitSh', '1') <> '0';
  ASettings.RunExe := MakePathFromStore(ASettings.ProjectDir,
    APrj.ReadString(MakeSection, 'RunExe', ''));
  ASettings.RunArgs := Trim(APrj.ReadString(MakeSection, 'RunArgs', ''));
  ASettings.RunDir := ExcludeTrailingPathDelimiter(MakePathFromStore(
    ASettings.ProjectDir, APrj.ReadString(MakeSection, 'RunDir', '')));
end;

procedure MakeSaveSettings(APrj: TProjectIni; const ASettings: TMakeSettings);
begin
  APrj.WriteString(MakeSection, 'Dir',
                   MakePathToStore(ASettings.ProjectDir, ASettings.MakeDir));
  APrj.WriteString(MakeSection, 'File', Trim(ASettings.MakeFile));
  APrj.WriteString(MakeSection, 'Target', Trim(ASettings.Target));
  APrj.WriteInteger(MakeSection, 'Jobs', ASettings.Jobs);
  APrj.WriteString(MakeSection, 'Tool',
                   MakePathToStore(ASettings.ProjectDir, ASettings.Tool));
  if ASettings.GitSh then
    APrj.WriteString(MakeSection, 'GitSh', '1')
  else
    APrj.WriteString(MakeSection, 'GitSh', '0');
  APrj.WriteString(MakeSection, 'RunExe',
                   MakePathToStore(ASettings.ProjectDir, ASettings.RunExe));
  APrj.WriteString(MakeSection, 'RunArgs', Trim(ASettings.RunArgs));
  APrj.WriteString(MakeSection, 'RunDir',
                   MakePathToStore(ASettings.ProjectDir, ASettings.RunDir));
end;

function MakeFilePath(const ASettings: TMakeSettings): string;
var
  FileName: string;
begin
  Result := '';
  FileName := Trim(ASettings.MakeFile);
  if FileName = '' then
    FileName := MakeFileIn(ASettings.MakeDir);
  if FileName = '' then
    Exit;
  if (ExtractFileDrive(FileName) <> '') or (FileName[1] in ['\', '/']) then
    Result := FileName
  else
    Result := ExpandFileName(IncludeTrailingPathDelimiter(ASettings.MakeDir) +
                             FileName);
end;

function MakeArgs(const ASettings: TMakeSettings): string;
begin
  Result := '';
  if Trim(ASettings.MakeFile) <> '' then
    Result := '-f "' + Trim(ASettings.MakeFile) + '"';
  if ASettings.Jobs > 0 then
    Result := Trim(Result + ' -j' + IntToStr(ASettings.Jobs));
  if ASettings.Target <> '' then
    Result := Trim(Result + ' ' + ASettings.Target);
end;

function MakeRunDir(const ASettings: TMakeSettings): string;
begin
  Result := ASettings.RunDir;
  if (Result = '') and (ASettings.RunExe <> '') then
    Result := ExcludeTrailingPathDelimiter(ExtractFilePath(ASettings.RunExe));
end;

procedure MakeDescribeBuild(const ASettings: TMakeSettings; ALines: TStrings);
var
  TargetText: string;
begin
  ALines.Clear;
  ALines.Add('Папка make:  ' + ASettings.MakeDir);
  if MakeFilePath(ASettings) <> '' then
    ALines.Add('Makefile:    ' + MakeFilePath(ASettings))
  else
    ALines.Add('Makefile:    не найден');
  TargetText := ASettings.Target;
  if TargetText = '' then
    TargetText := '(по умолчанию - первая цель Makefile)';
  ALines.Add('Цель:        ' + TargetText);
  if ASettings.RunExe <> '' then
  begin
    ALines.Add('Run:         ' + ASettings.RunExe + ' ' + ASettings.RunArgs);
    ALines.Add('Папка Run:   ' + MakeRunDir(ASettings));
  end;
end;

end.
