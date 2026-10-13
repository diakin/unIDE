unit GitInfo;

// ---------------------------------------------------------------------------
//  Из какой версии исходников собран exe: ветка и коммит git папки проекта
//  и незакоммиченные изменения - в текстовый файл рядом с exe
//  (<имя exe>.build.txt), см. GitWriteBuildInfo. Запущенный unIDE читает
//  такой файл своего exe и показывает ветку и коммит в заголовке окна.
//
//  Ветка и коммит читаются из папки .git самим модулем (HEAD, refs/heads,
//  packed-refs). Список изменений - через git.exe (git status --porcelain):
//  из PATH, из GitHub Desktop (%LOCALAPPDATA%\GitHubDesktop\app-*\resources\
//  app\git\cmd\git.exe) или из Program Files\Git. Нет git.exe - изменения
//  "не проверены", ветка и коммит всё равно пишутся.
// ---------------------------------------------------------------------------

interface

uses
  {$IFDEF MSWINDOWS}Windows,{$ENDIF} SysUtils, Classes;

// Папка репозитория (та, где лежит .git) для файла или папки APath; '' - нет
function GitFindRoot(const APath: string): string;

// Ветка и коммит (полный хеш) репозитория ARoot. Отделённый HEAD - ветка
// '(коммит)'. False - не прочитано.
function GitHeadInfo(const ARoot: string; var ABranch, ACommit: string): Boolean;

// git.exe: PATH, GitHub Desktop, Program Files\Git; '' - не найден
function GitFindExe: string;

// Незакоммиченные изменения: строки git status --porcelain в AChanges.
// False - git.exe нет или не отработал (тогда изменения не проверены).
function GitStatus(const ARoot: string; AChanges: TStrings): Boolean;

// Файл <exe без расширения>.build.txt рядом с AExe: время сборки, исходник
// ASource, репозиторий, ветка, коммит, изменения. False - исходник не в
// репозитории или файл не записался (тогда прежний файл удаляется).
function GitWriteBuildInfo(const AExe, ASource: string): Boolean;

// Коротко для заголовка: "RQFreeBasic 3a902c6" и " + изменения: N" (файлы
// репозитория, изменённые и не закоммиченные) / " + изменения не
// проверены"; '' - файла нет
function GitBuildInfoShort(const AExe: string): string;

function GitBuildInfoFile(const AExe: string): string;

implementation

function GitBuildInfoFile(const AExe: string): string;
begin
  Result := ChangeFileExt(AExe, '.build.txt');
end;

function GitFindRoot(const APath: string): string;
var
  Dir, Parent: string;
begin
  Result := '';
  if DirectoryExists(APath) then
    Dir := ExcludeTrailingPathDelimiter(ExpandFileName(APath))
  else
    Dir := ExcludeTrailingPathDelimiter(ExtractFilePath(ExpandFileName(APath)));
  while Dir <> '' do
  begin
    if DirectoryExists(IncludeTrailingPathDelimiter(Dir) + '.git') then
    begin
      Result := Dir;
      Exit;
    end;
    Parent := ExcludeTrailingPathDelimiter(ExtractFilePath(Dir));
    if (Parent = Dir) or (Parent = '') then
      Exit;
    Dir := Parent;
  end;
end;

function ReadFirstLine(const AFile: string): string;
var
  Lines: TStringList;
begin
  Result := '';
  if not FileExists(AFile) then
    Exit;
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFile);
      if Lines.Count > 0 then
        Result := Trim(Lines[0]);
    except
      Result := '';
    end;
  finally
    Lines.Free;
  end;
end;

// Хеш ветки ARef (refs/heads/X): отдельный файл или строка packed-refs
function RefHash(const AGitDir, ARef: string): string;
var
  Lines: TStringList;
  LineIdx: Integer;
  Line: string;
begin
  Result := ReadFirstLine(AGitDir + StringReplace(ARef, '/', PathDelim,
                                                  [rfReplaceAll]));
  if Result <> '' then
    Exit;
  if not FileExists(AGitDir + 'packed-refs') then
    Exit;
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AGitDir + 'packed-refs');
    except
      Exit;
    end;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[LineIdx]);
      if (Length(Line) > 41) and (Copy(Line, 42, MaxInt) = ARef) then
      begin
        Result := Copy(Line, 1, 40);
        Exit;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function GitHeadInfo(const ARoot: string; var ABranch, ACommit: string): Boolean;
var
  GitDir, Head, Ref: string;
begin
  ABranch := '';
  ACommit := '';
  GitDir := IncludeTrailingPathDelimiter(ARoot) + '.git' + PathDelim;
  Head := ReadFirstLine(GitDir + 'HEAD');
  if Copy(Head, 1, 5) = 'ref: ' then
  begin
    Ref := Trim(Copy(Head, 6, MaxInt));
    ABranch := Ref;
    if Copy(ABranch, 1, 11) = 'refs/heads/' then
      Delete(ABranch, 1, 11);
    ACommit := RefHash(GitDir, Ref);
  end
  else if Length(Head) >= 40 then
  begin
    ABranch := '(коммит)';
    ACommit := Copy(Head, 1, 40);
  end;
  Result := ACommit <> '';
end;

{$IFDEF MSWINDOWS}
function EnvVar(const AName: string): string;
var
  Buf: array[0..1023] of Char;
  Len: DWORD;
begin
  Len := GetEnvironmentVariable(PChar(AName), Buf, SizeOf(Buf));
  if (Len > 0) and (Len < SizeOf(Buf)) then
    Result := Buf
  else
    Result := '';
end;
{$ENDIF}

function GitFindExe: string;
{$IFDEF MSWINDOWS}
var
  Buf: array[0..MAX_PATH] of Char;
  FilePart: PChar;
  Info: TSearchRec;
  Base, Best, Candidate: string;
{$ENDIF}
begin
  Result := '';
  {$IFDEF MSWINDOWS}
  if SearchPath(nil, 'git.exe', nil, MAX_PATH, Buf, FilePart) > 0 then
  begin
    Result := Buf;
    Exit;
  end;
  // GitHub Desktop: своя копия git в папке последней версии приложения
  Base := EnvVar('LOCALAPPDATA');
  if Base <> '' then
  begin
    Base := IncludeTrailingPathDelimiter(Base) + 'GitHubDesktop\';
    Best := '';
    if FindFirst(Base + 'app-*', faDirectory, Info) = 0 then
    begin
      repeat
        Candidate := Base + Info.Name + '\resources\app\git\cmd\git.exe';
        if FileExists(Candidate) and (CompareText(Info.Name, Best) > 0) then
        begin
          Best := Info.Name;
          Result := Candidate;
        end;
      until FindNext(Info) <> 0;
      FindClose(Info);
    end;
    if Result <> '' then
      Exit;
  end;
  Candidate := EnvVar('ProgramFiles');
  if Candidate <> '' then
  begin
    Candidate := IncludeTrailingPathDelimiter(Candidate) + 'Git\cmd\git.exe';
    if FileExists(Candidate) then
      Result := Candidate;
  end;
  {$ENDIF}
end;

function GitStatus(const ARoot: string; AChanges: TStrings): Boolean;
{$IFDEF MSWINDOWS}
const
  WaitMs = 15000;
var
  GitExe, CmdLine, Output, Chunk: string;
  Security: TSecurityAttributes;
  ReadPipe, WritePipe: THandle;
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  Buf: array[0..4095] of Char;
  BytesRead, Avail, ExitCode: DWORD;
  StartTick: DWORD;
  Finished: Boolean;
{$ENDIF}
begin
  Result := False;
  AChanges.Clear;
  {$IFDEF MSWINDOWS}
  GitExe := GitFindExe;
  if GitExe = '' then
    Exit;
  Security.nLength := SizeOf(Security);
  Security.lpSecurityDescriptor := nil;
  Security.bInheritHandle := True;
  if not CreatePipe(ReadPipe, WritePipe, @Security, 0) then
    Exit;
  try
    FillChar(StartInfo, SizeOf(StartInfo), 0);
    StartInfo.cb := SizeOf(StartInfo);
    StartInfo.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    StartInfo.wShowWindow := SW_HIDE;
    StartInfo.hStdOutput := WritePipe;
    StartInfo.hStdError := WritePipe;
    StartInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
    CmdLine := '"' + GitExe + '" -C "' + ExcludeTrailingPathDelimiter(ARoot) +
               '" status --porcelain';
    if not CreateProcess(nil, PChar(CmdLine), nil, nil, True,
                         CREATE_NO_WINDOW, nil, PChar(ARoot), StartInfo,
                         ProcInfo) then
      Exit;
    CloseHandle(WritePipe);
    WritePipe := 0;
    Output := '';
    StartTick := GetTickCount;
    Finished := False;
    try
      // Читаем, пока git не закончит (и не дольше WaitMs): иначе он
      // встанет на заполненном канале
      repeat
        Avail := 0;
        if PeekNamedPipe(ReadPipe, nil, 0, nil, @Avail, nil) and (Avail > 0) then
        begin
          if ReadFile(ReadPipe, Buf, SizeOf(Buf), BytesRead, nil) and
             (BytesRead > 0) then
          begin
            SetString(Chunk, Buf, BytesRead);
            Output := Output + Chunk;
          end;
        end
        else if WaitForSingleObject(ProcInfo.hProcess, 50) = WAIT_OBJECT_0 then
          Finished := True;
      until Finished or (GetTickCount - StartTick > WaitMs);
      // Остаток после конца процесса
      while PeekNamedPipe(ReadPipe, nil, 0, nil, @Avail, nil) and (Avail > 0) and
            ReadFile(ReadPipe, Buf, SizeOf(Buf), BytesRead, nil) and
            (BytesRead > 0) do
      begin
        SetString(Chunk, Buf, BytesRead);
        Output := Output + Chunk;
      end;
      if not Finished then
        TerminateProcess(ProcInfo.hProcess, 1);
      GetExitCodeProcess(ProcInfo.hProcess, ExitCode);
      Result := Finished and (ExitCode = 0);
    finally
      CloseHandle(ProcInfo.hProcess);
      CloseHandle(ProcInfo.hThread);
    end;
    if Result then
      AChanges.Text := Output;
  finally
    CloseHandle(ReadPipe);
    if WritePipe <> 0 then
      CloseHandle(WritePipe);
  end;
  {$ENDIF}
end;

function GitWriteBuildInfo(const AExe, ASource: string): Boolean;
const
  MaxListed = 50;
var
  Root, Branch, Commit: string;
  Info, Changes, Untracked: TStringList;
  ChangeIdx: Integer;
begin
  Result := False;
  Root := GitFindRoot(ASource);
  if (Root = '') or not GitHeadInfo(Root, Branch, Commit) then
  begin
    // Прежний файл описывал бы не эту сборку
    if FileExists(GitBuildInfoFile(AExe)) then
      DeleteFile(GitBuildInfoFile(AExe));
    Exit;
  end;
  Info := TStringList.Create;
  Changes := TStringList.Create;
  try
    Info.Add('build=' + FormatDateTime('dd.mm.yyyy hh:nn:ss', Now));
    Info.Add('source=' + ASource);
    Info.Add('repo=' + Root);
    Info.Add('branch=' + Branch);
    Info.Add('commit=' + Commit);
    if GitStatus(Root, Changes) then
    begin
      // Изменённые файлы репозитория - отдельно от новых, которых в нём
      // нет ("?? файл": exe, dcu, логи) - они к версии исходников не
      // относятся и в число изменений не идут
      Untracked := TStringList.Create;
      try
        for ChangeIdx := Changes.Count - 1 downto 0 do
          if Trim(Changes[ChangeIdx]) = '' then
            Changes.Delete(ChangeIdx)
          else if Copy(Changes[ChangeIdx], 1, 2) = '??' then
          begin
            Untracked.Insert(0, Changes[ChangeIdx]);
            Changes.Delete(ChangeIdx);
          end;
        Info.Add('changes=' + IntToStr(Changes.Count));
        for ChangeIdx := 0 to Changes.Count - 1 do
          if ChangeIdx < MaxListed then
            Info.Add('  ' + Changes[ChangeIdx]);
        if Changes.Count > MaxListed then
          Info.Add(Format('  ... и ещё %d', [Changes.Count - MaxListed]));
        Info.Add('untracked=' + IntToStr(Untracked.Count) +
                 '   (файлы не из репозитория)');
        for ChangeIdx := 0 to Untracked.Count - 1 do
          if ChangeIdx < MaxListed then
            Info.Add('  ' + Untracked[ChangeIdx]);
        if Untracked.Count > MaxListed then
          Info.Add(Format('  ... и ещё %d', [Untracked.Count - MaxListed]));
      finally
        Untracked.Free;
      end;
    end
    else
      Info.Add('changes=?   (git.exe не найден - изменения не проверены)');
    try
      Info.SaveToFile(GitBuildInfoFile(AExe));
      Result := True;
    except
      Result := False;
    end;
  finally
    Changes.Free;
    Info.Free;
  end;
end;

function GitBuildInfoShort(const AExe: string): string;
var
  Info: TStringList;
  Changes: string;
begin
  Result := '';
  if not FileExists(GitBuildInfoFile(AExe)) then
    Exit;
  Info := TStringList.Create;
  try
    try
      Info.LoadFromFile(GitBuildInfoFile(AExe));
    except
      Exit;
    end;
    if Info.Values['commit'] = '' then
      Exit;
    Result := Info.Values['branch'] + ' ' + Copy(Info.Values['commit'], 1, 7);
    Changes := Trim(Info.Values['changes']);
    if Copy(Changes, 1, 1) = '?' then
      Result := Result + ' + изменения не проверены'
    else if (Changes <> '') and (Changes <> '0') then
      Result := Result + ' + изменения: ' + Changes;
  finally
    Info.Free;
  end;
end;

end.
