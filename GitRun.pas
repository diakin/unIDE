unit GitRun;

// ---------------------------------------------------------------------------
//  Запуск консольного git для окна unIDE (панель Git, меню Repository и
//  Branch): процесс без окна консоли, stdout и stderr - в одну трубу, вывод
//  git (UTF-8) - в Unicode. Пока git работает, вызывается AOnIdle (окно
//  обрабатывает сообщения); False из него - git прерывается.
//
//  - окружение - как у unIDE плюс GIT_TERMINAL_PROMPT=0: git не ждёт ввода
//    имени и пароля в консоли, которой нет (иначе завис бы). Окно входа
//    Git Credential Manager (credential.helper=manager у Git for Windows)
//    при этом показывается, как обычно;
//  - ключи для всех команд (GitBaseArgs): core.quotepath=false (имена не
//    в восьмеричных кодах), color.ui=false;
//  - разбор вывода: git status --porcelain=v1 -z (GitParseStatus), ветки,
//    счётчики ahead / behind; адрес GitHub из адреса remote; история
//    (git log, GitParseLog) и файлы коммита (--name-status -z,
//    GitParseNameStatus);
//  - GitRecycleFiles - файлы в корзину Windows (Discard новых файлов, как
//    в GitHub Desktop: их можно вернуть из корзины).
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes;

type
  // Строка вывода git (без перевода строки)
  TGitLineEvent = procedure(const ALine: WideString) of object;
  // Пока git работает; False - прервать
  TGitIdleEvent = function: Boolean of object;

  // Изменённый файл из git status
  TGitChange = record
    Code: string;          // два символа XY: ' M', 'M ', '??', 'A ', ' D', 'R ' ...
    Path: WideString;      // путь от корня репозитория, '/' - разделитель
    OrigPath: WideString;  // прежнее имя (переименование), иначе ''
  end;
  TGitChanges = array of TGitChange;

  // Коммит из истории (GitLogFormat)
  TGitCommit = record
    Hash: string;          // полный SHA
    Short: string;         // короткий
    Author: WideString;
    Date: string;          // 'yyyy-mm-dd hh:nn'
    Subject: WideString;
  end;
  TGitCommits = array of TGitCommit;

  TGitPaths = array of WideString;

  // Файл в репозитории, который подходит под правила .gitignore (окно
  // DlgGitTracked): путь и правило по git check-ignore -v
  TGitTrackedFile = record
    Path: WideString;     // от корня репозитория, '/' - разделитель
    Source: string;       // файл правила: '.gitignore', 'папка/.gitignore',
                          // '.git/info/exclude'; '' - правило не найдено
    LineNo: string;       // номер строки правила в нём
    Pattern: string;      // само правило: '*.dll', 'old/'
    Rule: string;         // для показа: '.gitignore:31  *.dll'
  end;
  TGitTrackedFiles = array of TGitTrackedFile;

const
  GitBaseArgs = '-c core.quotepath=false -c color.ui=false ';
  // git log: поля через #$1F, записи через #$1E (GitParseLog)
  GitLogFormat = '--format=%H%x1f%h%x1f%an%x1f%ad%x1f%s%x1e --date=iso';

// Запустить AGitExe с аргументами AArgs (GitBaseArgs добавляются) в папке
// AWorkDir. AOutput - весь вывод, AExitCode - код выхода. AInput - что
// подать git на вход (git credential fill / approve), '' - вход не нужен.
// Результат: '' - git отработал (код смотреть в AExitCode), иначе - почему
// не вышло (не запустился, прерван)
function GitExec(const AGitExe, AArgs, AWorkDir: WideString;
  AOnLine: TGitLineEvent; AOnIdle: TGitIdleEvent; var AOutput: WideString;
  var AExitCode: Integer; const AInput: string = ''): string;
// Аргумент в кавычках, если в нём пробел или его нет (кавычки внутри -
// \", как ждёт разбор командной строки git)
function GitQuote(const AArg: WideString): WideString;
// Вывод без завершающих переводов строки и пробелов
function GitTrimOut(const AText: WideString): WideString;
// git status --porcelain=v1 -z -> список изменений
procedure GitParseStatus(const AOutput: WideString; var AChanges: TGitChanges);
// Строки вывода (по #10, #13 отбрасывается) -> AList (пустые пропускаются)
procedure GitSplitLines(const AOutput: WideString; AList: TStrings);
// 'git rev-list --left-right --count A...B' -> AAhead (слева), ABehind
function GitParseCounts(const AOutput: WideString;
  var ALeft, ARight: Integer): Boolean;
// Адрес remote -> страница на GitHub: git@github.com:o/r.git,
// https://github.com/o/r.git -> https://github.com/o/r; не GitHub - ''
function GitHubWebUrl(const ARemoteUrl: WideString): WideString;
// Вывод git log с GitLogFormat -> список коммитов
procedure GitParseLog(const AOutput: WideString; var ACommits: TGitCommits);
// git diff --name-status -z -> список (Code - буква: M, A, D, R, C, T;
// переименование - OrigPath)
procedure GitParseNameStatus(const AOutput: WideString;
  var AChanges: TGitChanges);
// Файлы (полные пути) - в корзину Windows; False - не вышло или отменено
function GitRecycleFiles(AWnd: HWND; const AFiles: TGitPaths): Boolean;
// Пояснение к коду XY для списка изменений ('изменён', 'новый' ...)
function GitChangeText(const ACode: string): string;
// Имя ветки допустимо для git (упрощённая проверка check-ref-format)
function GitValidBranchName(const AName: string): Boolean;
// '/' -> '\'
function GitWinPath(const APath: WideString): WideString;
// UTF-8 -> Unicode / Unicode -> UTF-8 (без BOM)
function GitFromUtf8(const AText: string): WideString;
function GitToUtf8(const AText: WideString): string;

implementation

uses
  ProcRun, OsShell;

const
  GitPipeSize = 1048576;   // буфер трубы вывода git (CreatePipe)

function GitGetEnvStrings: PWideChar; stdcall;
  external 'kernel32.dll' name 'GetEnvironmentStringsW';
function GitFreeEnvStrings(AEnv: PWideChar): BOOL; stdcall;
  external 'kernel32.dll' name 'FreeEnvironmentStringsW';
function GitMultiToWide(ACodePage: UINT; AFlags: DWORD; AMulti: PAnsiChar;
  AMultiLen: Integer; AWide: PWideChar; AWideLen: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'MultiByteToWideChar';
function GitWideToMulti(ACodePage: UINT; AFlags: DWORD; AWide: PWideChar;
  AWideLen: Integer; AMulti: PAnsiChar; AMultiLen: Integer;
  ADefault: PAnsiChar; AUsedDefault: Pointer): Integer; stdcall;
  external 'kernel32.dll' name 'WideCharToMultiByte';

const
  GitCpUtf8 = 65001;

function GitFromUtf8(const AText: string): WideString;
var
  WideLen: Integer;
begin
  Result := '';
  if AText = '' then
    Exit;
  WideLen := GitMultiToWide(GitCpUtf8, 0, PAnsiChar(AText), Length(AText),
    nil, 0);
  if WideLen <= 0 then
    Exit;
  SetLength(Result, WideLen);
  GitMultiToWide(GitCpUtf8, 0, PAnsiChar(AText), Length(AText),
    PWideChar(Result), WideLen);
end;

function GitToUtf8(const AText: WideString): string;
var
  MultiLen: Integer;
begin
  Result := '';
  if AText = '' then
    Exit;
  MultiLen := GitWideToMulti(GitCpUtf8, 0, PWideChar(AText), Length(AText),
    nil, 0, nil, nil);
  if MultiLen <= 0 then
    Exit;
  SetLength(Result, MultiLen);
  GitWideToMulti(GitCpUtf8, 0, PWideChar(AText), Length(AText),
    PAnsiChar(Result), MultiLen, nil, nil);
end;

// Окружение unIDE + GIT_TERMINAL_PROMPT=0 (блок W: строки через #0, в
// конце ещё #0)
function GitEnvBlock: WideString;
var
  EnvStart, EnvPos: PWideChar;
  Entry: WideString;
begin
  Result := '';
  EnvStart := GitGetEnvStrings;
  if EnvStart <> nil then
  try
    EnvPos := EnvStart;
    while EnvPos^ <> #0 do
    begin
      Entry := EnvPos;
      Inc(EnvPos, Length(Entry) + 1);
      // Своё значение - ниже; прежнее (если было) не повторяем
      if WideUpperCase(Copy(Entry, 1, 20)) <> 'GIT_TERMINAL_PROMPT=' then
        Result := Result + Entry + WideChar(#0);
    end;
  finally
    GitFreeEnvStrings(EnvStart);
  end;
  Result := Result + 'GIT_TERMINAL_PROMPT=0' + WideChar(#0) + WideChar(#0);
end;

function GitQuote(const AArg: WideString): WideString;
var
  CharIndex: Integer;
  NeedQuote: Boolean;
begin
  NeedQuote := AArg = '';
  for CharIndex := 1 to Length(AArg) do
    if (AArg[CharIndex] = ' ') or (AArg[CharIndex] = #9) or
       (AArg[CharIndex] = '"') then
      NeedQuote := True;
  if not NeedQuote then
  begin
    Result := AArg;
    Exit;
  end;
  Result := '"';
  for CharIndex := 1 to Length(AArg) do
    if AArg[CharIndex] = '"' then
      Result := Result + '\"'
    else
      Result := Result + AArg[CharIndex];
  // '\' перед закрывающей кавычкой её экранировал бы
  if (AArg <> '') and (AArg[Length(AArg)] = '\') then
    Result := Result + '\';
  Result := Result + '"';
end;

function GitTrimOut(const AText: WideString): WideString;
var
  TextLen: Integer;
begin
  TextLen := Length(AText);
  while (TextLen > 0) and ((AText[TextLen] = #10) or (AText[TextLen] = #13) or
        (AText[TextLen] = ' ') or (AText[TextLen] = #0)) do
    Dec(TextLen);
  Result := Copy(AText, 1, TextLen);
end;

function GitExec(const AGitExe, AArgs, AWorkDir: WideString;
  AOnLine: TGitLineEvent; AOnIdle: TGitIdleEvent; var AOutput: WideString;
  var AExitCode: Integer; const AInput: string = ''): string;
var
  Proc: TProcRun;
  AllRaw, LineBuf, Piece: string;
  Finished, Cancelled, GotData: Boolean;
  IdleTick: DWORD;

  // Готовые строки из LineBuf - в AOnLine. Режем по байтам #10 / #13:
  // символ UTF-8 может прийти разрезанным между чтениями трубы
  procedure FlushLines(AAll: Boolean);
  var
    LineEnd: Integer;
    LineRaw: string;
  begin
    while LineBuf <> '' do
    begin
      LineEnd := 1;
      while (LineEnd <= Length(LineBuf)) and (LineBuf[LineEnd] <> #10) and
            (LineBuf[LineEnd] <> #13) do
        Inc(LineEnd);
      if (LineEnd > Length(LineBuf)) and not AAll then
        Exit;
      LineRaw := Copy(LineBuf, 1, LineEnd - 1);
      Delete(LineBuf, 1, LineEnd);
      if (LineRaw <> '') and Assigned(AOnLine) then
        AOnLine(GitFromUtf8(LineRaw));
    end;
  end;

  procedure ReadAvailable;
  begin
    Piece := '';
    if Proc.Read(Piece) <= 0 then
      Exit;
    AllRaw := AllRaw + Piece;
    GotData := True;
    // Построчно - только если строки кому-то нужны (AOnLine)
    if Assigned(AOnLine) then
    begin
      LineBuf := LineBuf + Piece;
      FlushLines(False);
    end;
  end;

begin
  Result := '';
  AOutput := '';
  AExitCode := -1;
  Proc := TProcRun.Create;
  try
    Proc.CommandLineW := GitQuote(AGitExe) + ' ' + GitBaseArgs + AArgs;
    Proc.DirW := AWorkDir;
    Proc.EnvBlockW := GitEnvBlock;
    Proc.Window := pwHidden;
    Proc.Console := pcNoWindow;
    Proc.CaptureOutput := True;
    // Буфер трубы - GitPipeSize: заполнив трубу, git ждёт, пока цикл ниже
    // её прочитает; с маленьким буфером по умолчанию большой вывод (git diff
    // большого файла) шёл кусками между засыпаниями цикла
    Proc.PipeSize := GitPipeSize;
    // Вход git: текст короткий - пишется целиком сразу после запуска (буфер
    // трубы его вмещает), затем труба закрывается (конец ввода)
    Proc.InputText := AInput;
    if not Proc.Start then
    begin
      Result := 'git ' + Proc.ErrorText;
      Exit;
    end;
    AllRaw := '';
    LineBuf := '';
    Cancelled := False;
    IdleTick := GetTickCount;
    repeat
      Finished := not Proc.Running;
      GotData := False;
      ReadAvailable;
      if Finished then
        Break;
      // Окно живёт (AOnIdle) не чаще раза в 15 мс, пока вывод идёт
      if not GotData or (GetTickCount - IdleTick >= 15) then
      begin
        IdleTick := GetTickCount;
        if Assigned(AOnIdle) and not AOnIdle then
        begin
          Proc.Terminate(1);
          Proc.WaitFor(3000);
          Cancelled := True;
          Break;
        end;
      end;
      // Труба была пуста - подождать; читали - сразу дальше: git, может
      // быть, уже пишет следующий кусок
      if not GotData then
        Sleep(15);
    until False;
    // Остаток после выхода процесса
    ReadAvailable;
    FlushLines(True);
    Proc.WaitFor(3000);
    AExitCode := Proc.ExitCode;
  finally
    Proc.Free;
  end;
  AOutput := GitFromUtf8(AllRaw);
  if Cancelled then
    Result := 'прервано';
end;

// Корзина - OsShell (общая с остальной программой)
function GitRecycleFiles(AWnd: HWND; const AFiles: TGitPaths): Boolean;
begin
  Result := ShellRecycleFilesW(AWnd, AFiles);
end;

// Следующее поле до разделителя ASep (или до конца); APos - после него
function GitNextField(const AText: WideString; var APos: Integer;
  ASep: WideChar): WideString;
var
  FieldEnd: Integer;
begin
  FieldEnd := APos;
  while (FieldEnd <= Length(AText)) and (AText[FieldEnd] <> ASep) do
    Inc(FieldEnd);
  Result := Copy(AText, APos, FieldEnd - APos);
  APos := FieldEnd + 1;
end;

procedure GitParseLog(const AOutput: WideString; var ACommits: TGitCommits);
var
  RecPos, FieldPos, Count: Integer;
  Rec: WideString;
  Commit: TGitCommit;
begin
  SetLength(ACommits, 0);
  Count := 0;
  RecPos := 1;
  while RecPos <= Length(AOutput) do
  begin
    Rec := GitNextField(AOutput, RecPos, WideChar($1E));
    // Между записями git ставит перевод строки
    while (Rec <> '') and ((Rec[1] = #10) or (Rec[1] = #13)) do
      Delete(Rec, 1, 1);
    if Rec = '' then
      Continue;
    FieldPos := 1;
    Commit.Hash := string(GitNextField(Rec, FieldPos, WideChar($1F)));
    Commit.Short := string(GitNextField(Rec, FieldPos, WideChar($1F)));
    Commit.Author := GitNextField(Rec, FieldPos, WideChar($1F));
    // --date=iso: '2026-10-23 12:34:56 +0300' -> без секунд и пояса
    Commit.Date := Copy(string(GitNextField(Rec, FieldPos, WideChar($1F))), 1, 16);
    Commit.Subject := GitNextField(Rec, FieldPos, WideChar($1F));
    if Length(Commit.Hash) < 7 then
      Continue;
    SetLength(ACommits, Count + 1);
    ACommits[Count] := Commit;
    Inc(Count);
  end;
end;

procedure GitParseNameStatus(const AOutput: WideString;
  var AChanges: TGitChanges);
var
  FieldPos, Count: Integer;
  Status: WideString;
  Change: TGitChange;
begin
  SetLength(AChanges, 0);
  Count := 0;
  FieldPos := 1;
  while FieldPos <= Length(AOutput) do
  begin
    Status := GitNextField(AOutput, FieldPos, WideChar(#0));
    while (Status <> '') and ((Status[1] = #10) or (Status[1] = #13)) do
      Delete(Status, 1, 1);
    if Status = '' then
      Continue;
    Change.Code := string(Copy(Status, 1, 1));
    Change.OrigPath := '';
    if (Change.Code = 'R') or (Change.Code = 'C') then
    begin
      // R100 старое новое
      Change.OrigPath := GitNextField(AOutput, FieldPos, WideChar(#0));
      Change.Path := GitNextField(AOutput, FieldPos, WideChar(#0));
    end
    else
      Change.Path := GitNextField(AOutput, FieldPos, WideChar(#0));
    // Код - как в status (буква и пробел), для GitChangeText
    Change.Code := Change.Code + ' ';
    SetLength(AChanges, Count + 1);
    AChanges[Count] := Change;
    Inc(Count);
  end;
end;

procedure GitParseStatus(const AOutput: WideString; var AChanges: TGitChanges);
var
  Pos0, NextZero, Count: Integer;
  Entry: WideString;
  Change: TGitChange;
begin
  SetLength(AChanges, 0);
  Count := 0;
  Pos0 := 1;
  while Pos0 <= Length(AOutput) do
  begin
    NextZero := Pos0;
    while (NextZero <= Length(AOutput)) and (AOutput[NextZero] <> #0) do
      Inc(NextZero);
    Entry := Copy(AOutput, Pos0, NextZero - Pos0);
    Pos0 := NextZero + 1;
    if Length(Entry) < 4 then
      Continue;
    Change.Code := string(Copy(Entry, 1, 2));
    Change.Path := Copy(Entry, 4, MaxInt);
    Change.OrigPath := '';
    // Переименование / копия: следом - прежнее имя отдельной записью
    if (Change.Code[1] = 'R') or (Change.Code[1] = 'C') or
       (Change.Code[2] = 'R') or (Change.Code[2] = 'C') then
    begin
      NextZero := Pos0;
      while (NextZero <= Length(AOutput)) and (AOutput[NextZero] <> #0) do
        Inc(NextZero);
      Change.OrigPath := Copy(AOutput, Pos0, NextZero - Pos0);
      Pos0 := NextZero + 1;
    end;
    SetLength(AChanges, Count + 1);
    AChanges[Count] := Change;
    Inc(Count);
  end;
end;

procedure GitSplitLines(const AOutput: WideString; AList: TStrings);
var
  Pos0, LineEnd: Integer;
  Line: WideString;
begin
  AList.Clear;
  Pos0 := 1;
  while Pos0 <= Length(AOutput) do
  begin
    LineEnd := Pos0;
    while (LineEnd <= Length(AOutput)) and (AOutput[LineEnd] <> #10) do
      Inc(LineEnd);
    Line := Copy(AOutput, Pos0, LineEnd - Pos0);
    Pos0 := LineEnd + 1;
    while (Line <> '') and ((Line[Length(Line)] = #13) or
          (Line[Length(Line)] = ' ')) do
      SetLength(Line, Length(Line) - 1);
    if Line <> '' then
      AList.Add(string(Line));
  end;
end;

function GitParseCounts(const AOutput: WideString;
  var ALeft, ARight: Integer): Boolean;
var
  Text: string;
  TabPos: Integer;
begin
  Text := Trim(string(GitTrimOut(AOutput)));
  TabPos := Pos(#9, Text);
  if TabPos = 0 then
    TabPos := Pos(' ', Text);
  Result := (TabPos > 0) and
    TryStrToInt(Trim(Copy(Text, 1, TabPos - 1)), ALeft) and
    TryStrToInt(Trim(Copy(Text, TabPos + 1, MaxInt)), ARight);
end;

function GitHubWebUrl(const ARemoteUrl: WideString): WideString;
var
  Url: string;
  AtPos: Integer;
begin
  Result := '';
  Url := Trim(string(ARemoteUrl));
  if Copy(LowerCase(Url), 1, 15) = 'git@github.com:' then
    Url := 'https://github.com/' + Copy(Url, 16, MaxInt)
  else if Copy(LowerCase(Url), 1, 21) = 'ssh://git@github.com/' then
    Url := 'https://github.com/' + Copy(Url, 22, MaxInt)
  else if Copy(LowerCase(Url), 1, 8) = 'https://' then
  begin
    // https://user@github.com/... - без имени
    AtPos := Pos('@', Url);
    if (AtPos > 0) and (AtPos < Pos('/', Copy(Url, 9, MaxInt)) + 8) then
      Url := 'https://' + Copy(Url, AtPos + 1, MaxInt);
  end;
  if Copy(LowerCase(Url), 1, 19) <> 'https://github.com/' then
    Exit;
  if LowerCase(Copy(Url, Length(Url) - 3, 4)) = '.git' then
    SetLength(Url, Length(Url) - 4);
  while (Url <> '') and (Url[Length(Url)] = '/') do
    SetLength(Url, Length(Url) - 1);
  Result := Url;
end;

function GitChangeText(const ACode: string): string;
var
  StateChar: Char;
begin
  if ACode = '??' then
  begin
    Result := 'новый';
    Exit;
  end;
  if (Length(ACode) = 2) and ((ACode[1] = 'U') or (ACode[2] = 'U') or
     (ACode = 'AA') or (ACode = 'DD')) then
  begin
    Result := 'конфликт';
    Exit;
  end;
  StateChar := ' ';
  if Length(ACode) = 2 then
  begin
    StateChar := ACode[1];
    if StateChar = ' ' then
      StateChar := ACode[2];
  end;
  case StateChar of
    'M': Result := 'изменён';
    'A': Result := 'добавлен';
    'D': Result := 'удалён';
    'R': Result := 'переименован';
    'C': Result := 'скопирован';
    'T': Result := 'тип изменён';
  else
    Result := ACode;
  end;
end;

function GitValidBranchName(const AName: string): Boolean;
var
  CharIndex: Integer;
begin
  Result := False;
  if (AName = '') or (AName[1] = '-') or (AName[1] = '/') or
     (AName[Length(AName)] = '/') or (AName[Length(AName)] = '.') or
     (Pos('..', AName) > 0) or (Pos('@{', AName) > 0) or
     (Pos('//', AName) > 0) or (AName = '@') or
     (LowerCase(Copy(AName, Length(AName) - 4, 5)) = '.lock') then
    Exit;
  for CharIndex := 1 to Length(AName) do
    if (AName[CharIndex] <= ' ') or (AName[CharIndex] in ['~', '^', ':', '?',
       '*', '[', '\', #127]) then
      Exit;
  Result := True;
end;

function GitWinPath(const APath: WideString): WideString;
var
  CharIndex: Integer;
begin
  Result := APath;
  // Не под Windows путь git ('/') - и есть путь системы
  {$IFDEF MSWINDOWS}
  for CharIndex := 1 to Length(Result) do
    if Result[CharIndex] = '/' then
      Result[CharIndex] := '\';
  {$ENDIF}
end;

end.
