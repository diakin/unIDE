unit WineRun;

// Linux-сборка unIDE: программы Windows (dcc32.exe, rc.exe, собранные exe
// RapidQ и Delphi) запускаются через Wine (этап 4.3 плана).
//
// Настройки - в разделе компилятора editor.ini (IDE Options - Compilers,
// страницы Delphi и RapidQ Basic): WineFile - программа wine, WinePrefix -
// папка префикса (WINEPREFIX). Пусто - раздел [Wine], затем wine из PATH и
// префикс по умолчанию (переменная WINEPREFIX или ~/.wine).
//
// Пути. Программа Windows под Wine видит файлы Linux через буквы дисков:
// <префикс>/dosdevices/z: -> /, c: -> ../drive_c и т.д. Пути в командной
// строке переводятся в такие имена (WineArgsToWin), пути в выводе
// компилятора - обратно (WineTextToUnix), чтобы переход к ошибке открыл
// файл Linux. Буквы читаются из dosdevices; нет такой папки - только Z: = /.
//
// Под Windows функции ничего не меняют: WineNeeded = False.

interface

uses
  SysUtils, Classes, IniFiles;

const
  WineIniSection = 'Wine';

type
  TWineSettings = record
    WineFile: string;   // программа wine (полный путь или 'wine')
    Prefix: string;     // WINEPREFIX; '' - как в среде
  end;

// Настройки из раздела ASection editor.ini, запасные - [Wine]
function WineLoad(const AIniFile, ASection: string): TWineSettings;
// Нужен ли Wine для запуска AExe: Linux и файл .exe, .com или .bat
function WineNeeded(const AExe: string): Boolean;
// wine есть; иначе False и текст для человека
function WineCheck(const ASettings: TWineSettings;
                   var AMessage: string): Boolean;
// Строка запуска: env WINEPREFIX=... WINEDEBUG=-all wine "AExe" + AParams
// (AParams уже с путями Windows)
function WineCommand(const ASettings: TWineSettings;
                     const AExe, AParams: string): string;
// Путь Linux -> путь программы Windows: /home/a/b.pas -> Z:\home\a\b.pas.
// ASlash - разделитель / (Z:/home/a/b.pas: так пути пишет RapidQ)
function WinePathToWin(const ASettings: TWineSettings; const APath: string;
                       ASlash: Boolean): string;
// Путь программы Windows -> путь Linux; не путь с буквой - как есть
function WinePathToUnix(const ASettings: TWineSettings;
                        const APath: string): string;
// Пути Linux в строке параметров -> пути Windows. Путь - то, что начинается
// с / в начале слова, после кавычки, после ; или = и после ключа вида -X
// или -XY в начале слова (-U/a;/b, -E"/a b").
function WineArgsToWin(const ASettings: TWineSettings; const AParams: string;
                       ASlash: Boolean): string;
// Пути с буквой диска в строке вывода -> пути Linux
function WineTextToUnix(const ASettings: TWineSettings;
                        const AText: string): string;

implementation

{$IFDEF UNIX}
uses
  BaseUnix;
{$ENDIF}

type
  TWineDrive = record
    Letter: Char;     // 'Z'
    Target: string;   // '/' (папка Linux, с / в конце)
  end;

var
  DriveCachePrefix: string = #0;
  DriveCache: array of TWineDrive;

function WineNeeded(const AExe: string): Boolean;
var
  ExtText: string;
begin
  Result := False;
  {$IFDEF UNIX}
  ExtText := LowerCase(ExtractFileExt(AExe));
  Result := (ExtText = '.exe') or (ExtText = '.com') or (ExtText = '.bat');
  {$ENDIF}
end;

function WineLoad(const AIniFile, ASection: string): TWineSettings;
var
  Ini: TIniFile;
begin
  Result.WineFile := '';
  Result.Prefix := '';
  if (AIniFile <> '') and FileExists(AIniFile) then
  begin
    Ini := TIniFile.Create(AIniFile);
    try
      if ASection <> '' then
      begin
        Result.WineFile := Trim(Ini.ReadString(ASection, 'WineFile', ''));
        Result.Prefix := Trim(Ini.ReadString(ASection, 'WinePrefix', ''));
      end;
      if Result.WineFile = '' then
        Result.WineFile := Trim(Ini.ReadString(WineIniSection, 'WineFile',
                                               ''));
      if Result.Prefix = '' then
        Result.Prefix := Trim(Ini.ReadString(WineIniSection, 'WinePrefix',
                                             ''));
    finally
      Ini.Free;
    end;
  end;
  {$IFDEF UNIX}
  if Result.WineFile = '' then
    Result.WineFile := ExeSearch('wine', GetEnvironmentVariable('PATH'));
  {$ENDIF}
  if Result.WineFile = '' then
    Result.WineFile := 'wine';
end;

function WineCheck(const ASettings: TWineSettings;
                   var AMessage: string): Boolean;
begin
  AMessage := '';
  Result := True;
  {$IFDEF UNIX}
  if (Pos('/', ASettings.WineFile) = 0) or not FileExists(ASettings.WineFile) then
  begin
    Result := False;
    AMessage := 'Не найден wine (' + ASettings.WineFile + '). Установите ' +
                'Wine или задайте путь: IDE Options - Compilers, поле Wine ' +
                '(exe) на странице компилятора.';
    Exit;
  end;
  if (ASettings.Prefix <> '') and not DirectoryExists(ASettings.Prefix) then
  begin
    Result := False;
    AMessage := 'Нет папки префикса Wine: ' + ASettings.Prefix +
                ' (IDE Options - Compilers, поле Wine prefix).';
  end;
  {$ENDIF}
end;

function QuoteArg(const AText: string): string;
begin
  Result := '"' + AText + '"';
end;

// Параметры для Wine. Строку команды Linux делит на слова (кавычки
// убираются), а Wine из слов собирает строку Windows заново: слово с
// кавычкой внутри (-U"a;b") уходит как "-U\"a;b\"", и dcc32 получает путь с
// \ в начале. Поэтому кавычки внутри слова снимаются; слово с пробелом
// берётся в кавычки целиком ("-UZ:\my dir") - Wine так его и передаст.
function WineWords(const AParams: string): string;
var
  CharIdx: Integer;
  InQuote: Boolean;
  WordText: string;

  procedure FlushWord;
  begin
    if WordText = '' then
      Exit;
    if Result <> '' then
      Result := Result + ' ';
    if Pos(' ', WordText) > 0 then
      Result := Result + '"' + WordText + '"'
    else
      Result := Result + WordText;
    WordText := '';
  end;

begin
  Result := '';
  WordText := '';
  InQuote := False;
  for CharIdx := 1 to Length(AParams) do
  begin
    if AParams[CharIdx] = '"' then
      InQuote := not InQuote
    else if (AParams[CharIdx] = ' ') and not InQuote then
      FlushWord
    else
      WordText := WordText + AParams[CharIdx];
  end;
  FlushWord;
end;

function WineCommand(const ASettings: TWineSettings;
                     const AExe, AParams: string): string;
begin
  // WINEDEBUG=-all: без строк fixme: Wine в выводе компилятора
  Result := 'env WINEDEBUG=-all ';
  if ASettings.Prefix <> '' then
    Result := Result + QuoteArg('WINEPREFIX=' +
                                ExcludeTrailingPathDelimiter(ASettings.Prefix)) +
              ' ';
  Result := Result + QuoteArg(ASettings.WineFile) + ' ' + QuoteArg(AExe);
  if Trim(AParams) <> '' then
    Result := Result + ' ' + WineWords(AParams);
end;

// ---------------------------------------------------------------------------
//  Буквы дисков
// ---------------------------------------------------------------------------

function PrefixDir(const ASettings: TWineSettings): string;
begin
  Result := ASettings.Prefix;
  {$IFDEF UNIX}
  if Result = '' then
    Result := GetEnvironmentVariable('WINEPREFIX');
  if Result = '' then
    Result := GetEnvironmentVariable('HOME') + '/.wine';
  {$ENDIF}
  Result := IncludeTrailingPathDelimiter(Result);
end;

procedure AddDrive(ALetter: Char; const ATarget: string);
var
  DriveIdx: Integer;
  Target: string;
begin
  Target := ATarget;
  if (Target = '') or (Target[Length(Target)] <> '/') then
    Target := Target + '/';
  for DriveIdx := 0 to High(DriveCache) do
    if DriveCache[DriveIdx].Letter = ALetter then
      Exit;
  SetLength(DriveCache, Length(DriveCache) + 1);
  DriveCache[High(DriveCache)].Letter := ALetter;
  DriveCache[High(DriveCache)].Target := Target;
end;

// Папка с . и .. по частям: /a/b/../c -> /a/c
function CleanUnixPath(const APath: string): string;
var
  Parts: TStringList;
  Rest, Part: string;
  SepPos, PartIdx: Integer;
begin
  Parts := TStringList.Create;
  try
    Rest := APath;
    while Rest <> '' do
    begin
      SepPos := Pos('/', Rest);
      if SepPos = 0 then
        SepPos := Length(Rest) + 1;
      Part := Copy(Rest, 1, SepPos - 1);
      Delete(Rest, 1, SepPos);
      if (Part = '') or (Part = '.') then
        Continue;
      if Part = '..' then
      begin
        if Parts.Count > 0 then
          Parts.Delete(Parts.Count - 1);
        Continue;
      end;
      Parts.Add(Part);
    end;
    Result := '';
    for PartIdx := 0 to Parts.Count - 1 do
      Result := Result + '/' + Parts[PartIdx];
    if Result = '' then
      Result := '/';
  finally
    Parts.Free;
  end;
end;

procedure LoadDrives(const ASettings: TWineSettings);
{$IFDEF UNIX}
var
  DevDir, Target: string;
  Found: TSearchRec;
  LinkText: string;
{$ENDIF}
begin
  if DriveCachePrefix = ASettings.Prefix then
    Exit;
  DriveCachePrefix := ASettings.Prefix;
  SetLength(DriveCache, 0);
  {$IFDEF UNIX}
  DevDir := PrefixDir(ASettings) + 'dosdevices/';
  if FindFirst(DevDir + '*', faAnyFile, Found) = 0 then
  try
    repeat
      // c:, z: - ссылки на папки; c::, com1 - не диски
      if (Length(Found.Name) <> 2) or (Found.Name[2] <> ':') or
         not (UpCase(Found.Name[1]) in ['A'..'Z']) then
        Continue;
      LinkText := fpReadLink(DevDir + Found.Name);
      if LinkText = '' then
        Continue;
      if LinkText[1] = '/' then
        Target := LinkText
      else
        Target := DevDir + LinkText;
      AddDrive(UpCase(Found.Name[1]), CleanUnixPath(Target));
    until FindNext(Found) <> 0;
  finally
    FindClose(Found);
  end;
  {$ENDIF}
  // Z: = / есть в любом префиксе по умолчанию
  AddDrive('Z', '/');
end;

function WinePathToWin(const ASettings: TWineSettings; const APath: string;
                       ASlash: Boolean): string;
var
  DriveIdx, BestIdx: Integer;
  Rest: string;
  SepChar: Char;
begin
  Result := APath;
  if (APath = '') or (APath[1] <> '/') then
    Exit;
  LoadDrives(ASettings);
  // Самая длинная подходящая папка: /home/u/.wine/drive_c/x -> C:\x, а не
  // Z:\home\...
  BestIdx := -1;
  for DriveIdx := 0 to High(DriveCache) do
    if (Copy(APath + '/', 1, Length(DriveCache[DriveIdx].Target)) =
        DriveCache[DriveIdx].Target) and
       ((BestIdx < 0) or (Length(DriveCache[DriveIdx].Target) >
                          Length(DriveCache[BestIdx].Target))) then
      BestIdx := DriveIdx;
  if BestIdx < 0 then
    Exit;
  Rest := Copy(APath, Length(DriveCache[BestIdx].Target) + 1, MaxInt);
  if ASlash then
    SepChar := '/'
  else
  begin
    SepChar := '\';
    Rest := StringReplace(Rest, '/', '\', [rfReplaceAll]);
  end;
  Result := DriveCache[BestIdx].Letter + ':' + SepChar + Rest;
end;

function WinePathToUnix(const ASettings: TWineSettings;
                        const APath: string): string;
var
  DriveIdx: Integer;
  Letter: Char;
begin
  Result := APath;
  if (Length(APath) < 3) or (APath[2] <> ':') or
     not ((APath[3] = '\') or (APath[3] = '/')) then
    Exit;
  Letter := UpCase(APath[1]);
  if not (Letter in ['A'..'Z']) then
    Exit;
  LoadDrives(ASettings);
  for DriveIdx := 0 to High(DriveCache) do
    if DriveCache[DriveIdx].Letter = Letter then
    begin
      Result := DriveCache[DriveIdx].Target +
                StringReplace(Copy(APath, 4, MaxInt), '\', '/',
                              [rfReplaceAll]);
      Exit;
    end;
end;

function WineArgsToWin(const ASettings: TWineSettings; const AParams: string;
                       ASlash: Boolean): string;
var
  CharIdx, WordStart, RunEnd: Integer;
  InQuote, IsPathStart: Boolean;
  PrevChar: Char;
  PathText: string;
begin
  Result := '';
  if not WineNeeded('x.exe') then
  begin
    Result := AParams;
    Exit;
  end;
  InQuote := False;
  WordStart := 1;
  CharIdx := 1;
  while CharIdx <= Length(AParams) do
  begin
    if AParams[CharIdx] = '"' then
    begin
      InQuote := not InQuote;
      Result := Result + '"';
      Inc(CharIdx);
      Continue;
    end;
    if (AParams[CharIdx] = ' ') and not InQuote then
    begin
      Result := Result + ' ';
      Inc(CharIdx);
      WordStart := CharIdx;
      Continue;
    end;
    IsPathStart := False;
    if AParams[CharIdx] = '/' then
    begin
      if CharIdx = WordStart then
        IsPathStart := True
      else
      begin
        PrevChar := AParams[CharIdx - 1];
        if (PrevChar = '"') or (PrevChar = ';') or (PrevChar = '=') then
          IsPathStart := True
        // -E/a, -LE/a: ключ в начале слова
        else if (AParams[WordStart] = '-') and (CharIdx - WordStart <= 3) then
          IsPathStart := True;
      end;
    end;
    if not IsPathStart then
    begin
      Result := Result + AParams[CharIdx];
      Inc(CharIdx);
      Continue;
    end;
    // Конец пути: ; или кавычка, вне кавычек - ещё и пробел
    RunEnd := CharIdx;
    while (RunEnd <= Length(AParams)) and (AParams[RunEnd] <> ';') and
          (AParams[RunEnd] <> '"') and
          (InQuote or (AParams[RunEnd] <> ' ')) do
      Inc(RunEnd);
    PathText := Copy(AParams, CharIdx, RunEnd - CharIdx);
    Result := Result + WinePathToWin(ASettings, PathText, ASlash);
    CharIdx := RunEnd;
  end;
end;

function WineTextToUnix(const ASettings: TWineSettings;
                        const AText: string): string;
var
  CharIdx, RunEnd, NextSpace, ScanIdx: Integer;
  HasSep: Boolean;
  PathText: string;
begin
  Result := '';
  if not WineNeeded('x.exe') then
  begin
    Result := AText;
    Exit;
  end;
  CharIdx := 1;
  while CharIdx <= Length(AText) do
  begin
    if (CharIdx + 2 <= Length(AText)) and
       (UpCase(AText[CharIdx]) in ['A'..'Z']) and
       (AText[CharIdx + 1] = ':') and
       ((AText[CharIdx + 2] = '\') or (AText[CharIdx + 2] = '/')) and
       ((CharIdx = 1) or not (UpCase(AText[CharIdx - 1]) in
                              ['A'..'Z', '0'..'9', '_'])) then
    begin
      // Конец пути: скобка, кавычка, запятая, ; - или пробел, за которым
      // до следующего пробела нет разделителя папок (пробел в имени папки
      // остаётся частью пути)
      RunEnd := CharIdx + 3;
      while RunEnd <= Length(AText) do
      begin
        if AText[RunEnd] in ['(', ')', '"', '''', ',', ';', #9, '<', '>',
                             '|'] then
          Break;
        if AText[RunEnd] = ' ' then
        begin
          NextSpace := RunEnd + 1;
          while (NextSpace <= Length(AText)) and (AText[NextSpace] <> ' ') do
            Inc(NextSpace);
          HasSep := False;
          for ScanIdx := RunEnd + 1 to NextSpace - 1 do
            if AText[ScanIdx] in ['\', '/'] then
            begin
              HasSep := True;
              Break;
            end;
          if not HasSep then
            Break;
        end;
        Inc(RunEnd);
      end;
      PathText := Copy(AText, CharIdx, RunEnd - CharIdx);
      Result := Result + WinePathToUnix(ASettings, PathText);
      CharIdx := RunEnd;
      Continue;
    end;
    Result := Result + AText[CharIdx];
    Inc(CharIdx);
  end;
end;

end.
