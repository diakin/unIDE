unit ArduinoCli;

// Работа с arduino-cli без окон: настройки из editor.ini
// ([Compiler.Arduino]), запуск команды с перехватом вывода, разбор
// табличного вывода (core list, core search, board search ...), разбор
// справки (--help) и индекса библиотек (library_index.json), импорт путей
// из RQdb.ini RQdebugger.
//
// Окна Board Manager, Library Manager и Arduino CLI Help (DlgArdBoards,
// DlgArdLibs, DlgArdCli) работают с arduino-cli только через этот модуль.
//
// Перенос из RQdebugger853-8.bas (GetConsoleOutPut, RunOnClickLibMng,
// RefreshBoardList, ShowInstCoreList, LoadLibJson ...). Отличия от него:
// - команда запускается напрямую с выводом через канал, без .bat,
//   промежуточных файлов и опроса их размера;
// - вывод arduino-cli идёт в UTF-8 и переводится в ANSI по строкам;
// - у каждой команды --config-file из настроек, если файл есть;
// - library_index.json разбирается как JSON, а не по строкам: поле "name"
//   встречается и внутри "dependencies", построчный разбор их путал бы.

interface

uses
  Windows, SysUtils, Classes, IniFiles;

const
  // Раздел настроек; при выбранном инструменте - [Compiler.Arduino.<имя>]
  ArdIniSection = 'Compiler.Arduino';

  // Коды ArdRunCli, кроме кода завершения самой программы
  ArdRunNoStart = -1;      // не удалось запустить
  ArdRunCancelled = -2;    // прервано кнопкой Stop

type
  TArdSettings = record
    Section: string;        // раздел editor.ini, из которого прочитано
    CliFile: string;        // arduino-cli.exe
    CliCfgFile: string;     // arduino-cli.yaml
    CliDataPath: string;    // directories.data: индексы, packages
    DownloadsPath: string;  // directories.downloads
    SketchPath: string;     // directories.user (sketchbook)
    BuildPath: string;
    LibPath: string;
    LogFile: string;
    Arduino15Path: string;  // папка Arduino IDE (%LOCALAPPDATA%\Arduino15)
    IdePath: string;        // установленная Arduino IDE (examples, libraries);
                            // не обязательно
    AdditionalUrls: string; // Additional Boards Manager URLs, через запятую
  end;

  // Очередная строка вывода arduino-cli (уже в ANSI, без перевода строки)
  TArdLineEvent = procedure(const ALine: string) of object;
  // Зовётся в циклах ожидания: обработать сообщения окна. ACancel := True -
  // прервать работу.
  TArdIdleEvent = procedure(var ACancel: Boolean) of object;

  // Библиотека из library_index.json (одна версия - одна запись)
  TArdLib = record
    Name: string;
    Version: string;
    Category: string;       // Topic в окне: Communication, Display ...
    Types: string;          // Type: Arduino, Partner, Contributed ...
    Architectures: string;
    Sentence: string;
    ObjStart: Integer;      // объект записи в тексте индекса: от '{'
    ObjEnd: Integer;        // до '}' включительно
  end;

  TArdLibIndex = class
  private
    FText: string;          // содержимое library_index.json
    FItems: array of TArdLib;
    FCount: Integer;
    FFileName: string;
    function GetItem(AIndex: Integer): TArdLib;
    procedure AddItem(const AItem: TArdLib);
  public
    // False - файла нет, он не разобран или разбор прерван (AError)
    function LoadFromFile(const AFile: string; AOnIdle: TArdIdleEvent;
                          var AError: string): Boolean;
    procedure Clear;
    // Все поля записи строками "имя: значение"
    function Details(AIndex: Integer): string;
    property Count: Integer read FCount;
    property Items[AIndex: Integer]: TArdLib read GetItem; default;
    property FileName: string read FFileName;
  end;

function ArdLoadSettings(const AIniFile: string): TArdSettings;
procedure ArdSaveSetting(const AIniFile, ASection, AKey, AValue: string);
// arduino-cli.exe задан и есть на диске; иначе False и текст для человека
function ArdCheckCli(const ASettings: TArdSettings;
                     var AMessage: string): Boolean;
// Из списка (строки или через запятую) - только адреса http(s), через
// запятую: так их принимает --additional-urls
function ArdHttpUrls(const AText: string): string;
// Полная строка запуска: exe, аргументы, --config-file
function ArdCommandLine(const ASettings: TArdSettings;
                        const AArgs: string): string;
// Запуск arduino-cli с аргументами AArgs. Строки вывода - в AOutput (если
// не nil) и в AOnLine (если задан) по мере поступления. AOnProgress - ход
// загрузки (core install, lib install, update-index): строка прогресса
// "<пакет> 6.12 MiB / 49.01 MiB 12.50%", которую arduino-cli
// перерисовывает через #13 без перевода строки; зовётся при каждом её
// изменении. Итог загрузки ("<пакет> downloaded") приходит в AOnLine.
// Результат - код завершения или ArdRunNoStart / ArdRunCancelled.
function ArdRunCli(const ASettings: TArdSettings; const AArgs: string;
                   AOutput: TStrings; AOnLine: TArdLineEvent;
                   AOnIdle: TArdIdleEvent;
                   AOnProgress: TArdLineEvent = nil): Integer;
// Строка прогресса загрузки в логе ALines: первая - новой строкой в конце,
// следующие заменяют её. AProgressIdx - номер этой строки, -1 - её нет.
procedure ArdLogProgress(ALines: TStrings; var AProgressIdx: Integer;
                         const AText: string);
// Строка вывода в лог ALines: последняя строка лога - строка прогресса -
// заменяется ею (итог загрузки встаёт на место прогресса), иначе
// добавляется
procedure ArdLogLine(ALines: TStrings; var AProgressIdx: Integer;
                     const ALine: string);
function ArdUtf8ToAnsi(const AText: string): string;
// Значение в кавычках, если в нём есть пробел
function ArdQuote(const AValue: string): string;

// Таблица из текстового вывода arduino-cli: строка заголовка - первая, где
// есть все AHeaders отдельными словами; строки ниже режутся по позициям
// заголовков. В ARows - значения через #9 в порядке AHeaders.
function ArdParseTable(ALines: TStrings; const AHeaders: array of string;
                       ARows: TStrings): Boolean;
// Поле AIndex (от нуля) строки ArdParseTable
function ArdRowField(const ARow: string; AIndex: Integer): string;
// Раздел "Available Commands:" справки --help: "команда"#9"описание"
function ArdHelpCommands(AHelp: TStrings; ACommands: TStrings): Integer;
// Раздел "Flags:" и "Global Flags:" справки: строки как есть
function ArdHelpFlags(AHelp: TStrings; AFlags: TStrings): Integer;
// Папка установленной платформы: <data>\packages\<vendor>\hardware\<arch>\
// <version>\ - сначала в CliDataPath, потом в Arduino15Path. '' - нет.
function ArdPackagePath(const ASettings: TArdSettings;
                        const APlatformId, AVersion: string): string;
// Пути из RQdb.ini [Arduino] (и AdditURLEdit.txt рядом) - в раздел
// ASection editor.ini. AReport - что перенесено. Результат - число ключей.
function ArdImportRqdbIni(const ARqdbIni, AEditorIni, ASection: string;
                          AReport: TStrings): Integer;

// ---------------------------------------------------------------------------
//  Сборка скетча (Verify / Upload)
// ---------------------------------------------------------------------------

type
  // Ключи [Compiler.Arduino], которые меняют командную строку compile.
  // Пишет их IDE Options - Arduino (Unit2).
  TArdBuildOptions = record
    Warnings: string;          // none / default / more / all
    LogLevel: string;          // trace ... panic; идёт вместе с --log-file
    CompileVerbose: Boolean;   // Show verbose output - Compilation: -v
    UploadVerbose: Boolean;    // Show verbose output - Upload: -v
    VerifyAfterUpload: Boolean;// Verify code after upload: -t
    SaveBeforeBuild: Boolean;  // Save sketch when verifying or uploading
    ExportBinaries: Boolean;   // -e: .hex / .bin в папку скетча
  end;

function ArdLoadBuildOptions(const AIniFile, ASection: string):
  TArdBuildOptions;
// Папка сборки скетча: <BuildPath>\<имя папки скетча>\. Своя папка у
// каждого скетча - объектные файлы и compile_commands.json разных скетчей
// не смешиваются. BuildPath не задан - пусто (arduino-cli берёт временную
// папку).
function ArdSketchBuildDir(const ASettings: TArdSettings;
                           const ASketchDir: string): string;
// Аргументы arduino-cli compile (без --config-file - его добавляет
// ArdCommandLine). APort не пусто - с загрузкой (-u -p).
function ArdCompileArgs(const ASettings: TArdSettings;
                        const AOptions: TArdBuildOptions;
                        const AFqbn, ASketchDir, APort: string): string;
// Платформа из FQBN: первые две части (arduino:avr:uno -> arduino:avr) -
// аргумент core install
function ArdPlatformOfFqbn(const AFqbn: string): string;
// Вывод сборки говорит, что платформа не установлена
function ArdIsPlatformMissing(const AText: string): Boolean;
// Строка ошибки gcc: "файл:строка:столбец: error: ..." или
// "... fatal error: ..."
function ArdIsGccError(const AText: string): Boolean;
// Строка gcc/ld с местом: "файл:строка:столбец: текст" или
// "файл:строка: текст", с приставкой "In file included from " или
// "from ". Буква диска (C:) номером не считается. AColNo = 0 - столбца
// нет. / в пути заменяется на \.
function ArdParseGccLine(const AText: string; var AFile: string;
                         var ALineNo, AColNo: Integer): Boolean;

implementation

uses
  ProcRun;

// ---------------------------------------------------------------------------
//  Настройки
// ---------------------------------------------------------------------------

// Папка с завершающей \ (пустая остаётся пустой)
function ArdDir(const APath: string): string;
begin
  Result := Trim(APath);
  if Result <> '' then
    Result := IncludeTrailingPathDelimiter(Result);
end;

function ArdLoadSettings(const AIniFile: string): TArdSettings;
var
  Ini: TIniFile;
  ToolName: string;
begin
  Result.Section := ArdIniSection;
  Result.CliFile := '';
  Result.CliCfgFile := '';
  Result.CliDataPath := '';
  Result.DownloadsPath := '';
  Result.SketchPath := '';
  Result.BuildPath := '';
  Result.LibPath := '';
  Result.LogFile := '';
  Result.Arduino15Path := '';
  Result.IdePath := '';
  Result.AdditionalUrls := '';
  if (AIniFile = '') or not FileExists(AIniFile) then
    Exit;

  Ini := TIniFile.Create(AIniFile);
  try
    // Инструмент по умолчанию (IDE Options - Compilers, строка над полями):
    // у него свой раздел. '(default)' - раздел самого типа.
    ToolName := Trim(Ini.ReadString(ArdIniSection, 'Default', ''));
    if (ToolName <> '') and (ToolName <> '(default)') and
       Ini.SectionExists(ArdIniSection + '.' + ToolName) then
      Result.Section := ArdIniSection + '.' + ToolName;

    Result.CliFile := Trim(Ini.ReadString(Result.Section, 'CliFile', ''));
    Result.CliCfgFile := Trim(Ini.ReadString(Result.Section, 'CliCfgFile',
                                             ''));
    Result.CliDataPath := ArdDir(Ini.ReadString(Result.Section,
                                                'CliDataPath', ''));
    Result.DownloadsPath := ArdDir(Ini.ReadString(Result.Section,
                                                  'DownloadsPath', ''));
    Result.SketchPath := ArdDir(Ini.ReadString(Result.Section, 'SketchPath',
                                               ''));
    Result.BuildPath := ArdDir(Ini.ReadString(Result.Section, 'BuildPath',
                                              ''));
    Result.LibPath := ArdDir(Ini.ReadString(Result.Section, 'LibPath', ''));
    Result.LogFile := Trim(Ini.ReadString(Result.Section, 'LogFile', ''));
    Result.Arduino15Path := ArdDir(Ini.ReadString(Result.Section,
                                                  'Arduino15Path', ''));
    Result.IdePath := ArdDir(Ini.ReadString(Result.Section, 'IdePath', ''));
    Result.AdditionalUrls := Trim(Ini.ReadString(Result.Section,
                                                 'AdditionalUrls', ''));
  finally
    Ini.Free;
  end;
end;

procedure ArdSaveSetting(const AIniFile, ASection, AKey, AValue: string);
var
  Ini: TIniFile;
begin
  if AIniFile = '' then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    Ini.WriteString(ASection, AKey, AValue);
  finally
    Ini.Free;
  end;
end;

function ArdCheckCli(const ASettings: TArdSettings;
                     var AMessage: string): Boolean;
begin
  Result := False;
  if ASettings.CliFile = '' then
  begin
    AMessage := 'Не задан arduino-cli.exe: IDE Options - Compilers - ' +
                'Arduino, поле Arduino CLI file (или кнопка «Импорт из ' +
                'RQdb.ini» там же).';
    Exit;
  end;
  if not FileExists(ASettings.CliFile) then
  begin
    AMessage := 'Не найден arduino-cli.exe: ' + ASettings.CliFile +
                #13#10'Путь задаётся в IDE Options - Compilers - Arduino, ' +
                'поле Arduino CLI file.';
    Exit;
  end;
  AMessage := '';
  Result := True;
end;

function ArdHttpUrls(const AText: string): string;
var
  Parts: TStringList;
  Item: string;
  PartIdx: Integer;
begin
  Result := '';
  Parts := TStringList.Create;
  try
    // Разделители - перевод строки, запятая и точка с запятой
    Parts.Text := StringReplace(StringReplace(AText, ',', #13#10,
                                              [rfReplaceAll]),
                                ';', #13#10, [rfReplaceAll]);
    for PartIdx := 0 to Parts.Count - 1 do
    begin
      Item := Trim(Parts[PartIdx]);
      if (CompareText(Copy(Item, 1, 7), 'http://') = 0) or
         (CompareText(Copy(Item, 1, 8), 'https://') = 0) then
      begin
        if Result <> '' then
          Result := Result + ',';
        Result := Result + Item;
      end;
    end;
  finally
    Parts.Free;
  end;
end;

function ArdQuote(const AValue: string): string;
begin
  if (Pos(' ', AValue) > 0) and (Copy(AValue, 1, 1) <> '"') then
  begin
    // \ перед закрывающей кавычкой в командной строке Windows её
    // экранирует: завершающий \ удваивается
    if Copy(AValue, Length(AValue), 1) = '\' then
      Result := '"' + AValue + '\"'
    else
      Result := '"' + AValue + '"';
  end
  else
    Result := AValue;
end;

function ArdCommandLine(const ASettings: TArdSettings;
                        const AArgs: string): string;
begin
  Result := '"' + ASettings.CliFile + '" ' + Trim(AArgs);
  if (ASettings.CliCfgFile <> '') and FileExists(ASettings.CliCfgFile) then
    Result := Result + ' --config-file "' + ASettings.CliCfgFile + '"';
end;

// ---------------------------------------------------------------------------
//  UTF-8 -> ANSI
// ---------------------------------------------------------------------------

// UTF-8 -> WideString своим разбором: Utf8Decode Delphi 7 на
// четырёхбайтовой последовательности возвращает пустую строку целиком.
// Неправильный байт и символ вне BMP - '?'.
function ArdUtf8ToWide(const AText: string): WideString;
var
  SrcIdx, DstLen, SrcLen, Extra, ExtraIdx: Integer;
  ByteVal: Byte;
  CodePoint: Cardinal;
begin
  SrcLen := Length(AText);
  SetLength(Result, SrcLen);
  DstLen := 0;
  SrcIdx := 1;
  while SrcIdx <= SrcLen do
  begin
    ByteVal := Ord(AText[SrcIdx]);
    Inc(SrcIdx);
    if ByteVal < $80 then
    begin
      Inc(DstLen);
      Result[DstLen] := WideChar(ByteVal);
      Continue;
    end;
    if ByteVal and $E0 = $C0 then
    begin
      Extra := 1;
      CodePoint := ByteVal and $1F;
    end
    else if ByteVal and $F0 = $E0 then
    begin
      Extra := 2;
      CodePoint := ByteVal and $0F;
    end
    else if ByteVal and $F8 = $F0 then
    begin
      Extra := 3;
      CodePoint := ByteVal and $07;
    end
    else
    begin
      Inc(DstLen);
      Result[DstLen] := '?';
      Continue;
    end;
    for ExtraIdx := 1 to Extra do
    begin
      if (SrcIdx > SrcLen) or (Ord(AText[SrcIdx]) and $C0 <> $80) then
      begin
        CodePoint := Ord('?');
        Break;
      end;
      CodePoint := (CodePoint shl 6) or (Ord(AText[SrcIdx]) and $3F);
      Inc(SrcIdx);
    end;
    if CodePoint > $FFFF then
      CodePoint := Ord('?');
    Inc(DstLen);
    Result[DstLen] := WideChar(CodePoint);
  end;
  SetLength(Result, DstLen);
end;

function ArdWideToAnsi(const AText: WideString): string;
var
  NeedLen: Integer;
begin
  Result := '';
  if AText = '' then
    Exit;
  NeedLen := WideCharToMultiByte(CP_ACP, 0, PWideChar(AText), Length(AText),
                                 nil, 0, nil, nil);
  if NeedLen <= 0 then
    Exit;
  SetLength(Result, NeedLen);
  WideCharToMultiByte(CP_ACP, 0, PWideChar(AText), Length(AText),
                      PChar(Result), NeedLen, nil, nil);
end;

function ArdUtf8ToAnsi(const AText: string): string;
var
  CharIdx: Integer;
  PlainAscii: Boolean;
begin
  PlainAscii := True;
  for CharIdx := 1 to Length(AText) do
    if Ord(AText[CharIdx]) >= $80 then
    begin
      PlainAscii := False;
      Break;
    end;
  if PlainAscii then
    Result := AText
  else
    Result := ArdWideToAnsi(ArdUtf8ToWide(AText));
end;

// ---------------------------------------------------------------------------
//  Запуск arduino-cli
// ---------------------------------------------------------------------------

function ArdRunCli(const ASettings: TArdSettings; const AArgs: string;
                   AOutput: TStrings; AOnLine: TArdLineEvent;
                   AOnIdle: TArdIdleEvent;
                   AOnProgress: TArdLineEvent = nil): Integer;
var
  Proc: TProcRun;
  Chunk: string;
  Got: Integer;
  Pending, LineText, CmdLine, WorkDir, LastProgress: string;
  LocaleBuf: array[0..255] of Char;
  HadLocale, Cancel, Ended, Started: Boolean;
  NewLinePos, CarriagePos: Integer;

  procedure EmitLine(const ARaw: string);
  var
    LineAnsi: string;
  begin
    LineAnsi := ARaw;
    // Строка прогресса загрузки перерисовывается через #13: остаётся
    // последнее её состояние
    CarriagePos := LastDelimiter(#13, LineAnsi);
    if CarriagePos = Length(LineAnsi) then
    begin
      SetLength(LineAnsi, Length(LineAnsi) - 1);
      CarriagePos := LastDelimiter(#13, LineAnsi);
    end;
    if CarriagePos > 0 then
      LineAnsi := Copy(LineAnsi, CarriagePos + 1, Length(LineAnsi));
    LineAnsi := ArdUtf8ToAnsi(LineAnsi);
    if AOutput <> nil then
      AOutput.Add(LineAnsi);
    if Assigned(AOnLine) then
      AOnLine(LineAnsi);
  end;

  // Хвост без перевода строки с #13 - строка прогресса загрузки:
  // arduino-cli пишет каждое её состояние как #13 + текст. Состояние
  // считается целым, когда за ним пришёл следующий #13 (чтение могло
  // застать запись на середине): отдаётся последнее целое, если оно
  // изменилось. Полоса до имени пакета (" 0 / 51395093 0.00%" - имя ещё
  // не задано) пропускается.
  procedure EmitProgress;
  var
    ProgressText: string;
    LastCarriage: Integer;
  begin
    if not Assigned(AOnProgress) then
      Exit;
    LastCarriage := LastDelimiter(#13, Pending);
    if LastCarriage <= 1 then
      Exit;
    ProgressText := Copy(Pending, 1, LastCarriage - 1);
    LastCarriage := LastDelimiter(#13, ProgressText);
    ProgressText := Trim(ArdUtf8ToAnsi(Copy(ProgressText, LastCarriage + 1,
                                            Length(ProgressText))));
    if (ProgressText = '') or (ProgressText[1] in ['0'..'9']) or
       (ProgressText = LastProgress) then
      Exit;
    LastProgress := ProgressText;
    AOnProgress(ProgressText);
  end;

begin
  Result := ArdRunNoStart;
  CmdLine := ArdCommandLine(ASettings, AArgs);
  WorkDir := ExtractFilePath(ASettings.CliFile);
  if (WorkDir = '') or not DirectoryExists(WorkDir) then
    WorkDir := GetCurrentDir;

  Proc := TProcRun.Create;
  try
    Proc.CommandLine := CmdLine;
    Proc.Dir := WorkDir;
    Proc.Window := pwHidden;
    Proc.Console := pcNoWindow;
    Proc.CaptureOutput := True;

    // Английская локаль: таблицы разбираются по заголовкам колонок (так же
    // делал RQdebugger: set ARDUINO_LOCALE=en). Переменная - только на время
    // запуска, дочерний процесс получает копию окружения.
    HadLocale := Windows.GetEnvironmentVariable('ARDUINO_LOCALE', LocaleBuf,
                                        SizeOf(LocaleBuf)) > 0;
    Windows.SetEnvironmentVariable('ARDUINO_LOCALE', 'en');
    try
      Started := Proc.Start;
    finally
      if HadLocale then
        Windows.SetEnvironmentVariable('ARDUINO_LOCALE', LocaleBuf)
      else
        Windows.SetEnvironmentVariable('ARDUINO_LOCALE', nil);
    end;
    if not Started then
    begin
      EmitLine('Не удалось запустить: ' + CmdLine + ' (' + Proc.ErrorText + ')');
      Exit;
    end;

    Pending := '';
    LastProgress := '';
    Ended := False;
    Cancel := False;
    repeat
      Chunk := '';
      Got := Proc.Read(Chunk);
      if Got < 0 then
        Break;
      if Got = 0 then
      begin
        if Ended then
          Break;
        if Proc.WaitFor(50) then
          Ended := True;
        if Assigned(AOnIdle) then
          AOnIdle(Cancel);
        if Cancel then
        begin
          Proc.Terminate(1);
          Break;
        end;
        Continue;
      end;
      Pending := Pending + Chunk;

      // Целые строки - сразу, хвост ждёт следующего чтения
      NewLinePos := Pos(#10, Pending);
      while NewLinePos > 0 do
      begin
        LineText := Copy(Pending, 1, NewLinePos - 1);
        Pending := Copy(Pending, NewLinePos + 1, Length(Pending));
        EmitLine(LineText);
        LastProgress := '';
        NewLinePos := Pos(#10, Pending);
      end;
      EmitProgress;

      if Assigned(AOnIdle) then
        AOnIdle(Cancel);
      if Cancel then
      begin
        Proc.Terminate(1);
        Break;
      end;
    until False;

    if Pending <> '' then
      EmitLine(Pending);

    if Cancel then
      Result := ArdRunCancelled
    else
    begin
      Proc.WaitFor(2000);
      if Proc.ExitCode >= 0 then
        Result := Proc.ExitCode
      else
        Result := 0;
    end;
  finally
    Proc.Free;
  end;
end;

procedure ArdLogProgress(ALines: TStrings; var AProgressIdx: Integer;
                         const AText: string);
begin
  // Строка прогресса должна быть последней: лог чистили или в него
  // писали после неё - начинаем новую
  if (AProgressIdx >= 0) and (AProgressIdx = ALines.Count - 1) then
    ALines[AProgressIdx] := AText
  else
    AProgressIdx := ALines.Add(AText);
end;

procedure ArdLogLine(ALines: TStrings; var AProgressIdx: Integer;
                     const ALine: string);
begin
  if (AProgressIdx >= 0) and (AProgressIdx = ALines.Count - 1) then
    ALines[AProgressIdx] := ALine
  else
    ALines.Add(ALine);
  AProgressIdx := -1;
end;

// ---------------------------------------------------------------------------
//  Разбор текстового вывода
// ---------------------------------------------------------------------------

// Позиция AHeader в ALine отдельным словом (по краям - пробел или край
// строки): "ID" не должен найтись внутри "Platform ID", а "Name" - внутри
// "Board Name"
function ArdHeaderPos(const ALine, AHeader: string): Integer;
var
  StartIdx, FoundIdx, HeaderLen: Integer;
  Rest: string;
  BeforeOk, AfterOk: Boolean;
begin
  Result := 0;
  HeaderLen := Length(AHeader);
  if HeaderLen = 0 then
    Exit;
  StartIdx := 1;
  while StartIdx <= Length(ALine) - HeaderLen + 1 do
  begin
    Rest := Copy(ALine, StartIdx, Length(ALine));
    FoundIdx := Pos(AHeader, Rest);
    if FoundIdx = 0 then
      Exit;
    FoundIdx := FoundIdx + StartIdx - 1;
    BeforeOk := (FoundIdx = 1) or (ALine[FoundIdx - 1] = ' ');
    AfterOk := (FoundIdx + HeaderLen > Length(ALine)) or
               (ALine[FoundIdx + HeaderLen] = ' ');
    if BeforeOk and AfterOk then
    begin
      Result := FoundIdx;
      Exit;
    end;
    StartIdx := FoundIdx + 1;
  end;
end;

function ArdParseTable(ALines: TStrings; const AHeaders: array of string;
                       ARows: TStrings): Boolean;
var
  HeaderRow, LineIdx, HeaderIdx, OtherIdx, CellEnd, HeaderCount: Integer;
  Positions: array of Integer;
  LineText, RowText, Cell: string;
  AllFound: Boolean;
begin
  Result := False;
  ARows.Clear;
  HeaderCount := Length(AHeaders);
  if HeaderCount = 0 then
    Exit;
  SetLength(Positions, HeaderCount);

  HeaderRow := -1;
  for LineIdx := 0 to ALines.Count - 1 do
  begin
    AllFound := True;
    for HeaderIdx := 0 to HeaderCount - 1 do
    begin
      Positions[HeaderIdx] := ArdHeaderPos(ALines[LineIdx],
                                           AHeaders[HeaderIdx]);
      if Positions[HeaderIdx] = 0 then
      begin
        AllFound := False;
        Break;
      end;
    end;
    if AllFound then
    begin
      HeaderRow := LineIdx;
      Break;
    end;
  end;
  if HeaderRow < 0 then
    Exit;

  for LineIdx := HeaderRow + 1 to ALines.Count - 1 do
  begin
    LineText := ALines[LineIdx];
    if Trim(LineText) = '' then
      Continue;
    RowText := '';
    for HeaderIdx := 0 to HeaderCount - 1 do
    begin
      // Конец ячейки - перед ближайшим заголовком правее этого
      CellEnd := Length(LineText);
      for OtherIdx := 0 to HeaderCount - 1 do
        if (Positions[OtherIdx] > Positions[HeaderIdx]) and
           (Positions[OtherIdx] - 1 < CellEnd) then
          CellEnd := Positions[OtherIdx] - 1;
      Cell := Trim(Copy(LineText, Positions[HeaderIdx],
                        CellEnd - Positions[HeaderIdx] + 1));
      if HeaderIdx > 0 then
        RowText := RowText + #9;
      RowText := RowText + Cell;
    end;
    ARows.Add(RowText);
  end;
  Result := True;
end;

function ArdRowField(const ARow: string; AIndex: Integer): string;
var
  Rest: string;
  TabPos, FieldIdx: Integer;
begin
  Rest := ARow;
  for FieldIdx := 0 to AIndex - 1 do
  begin
    TabPos := Pos(#9, Rest);
    if TabPos = 0 then
    begin
      Result := '';
      Exit;
    end;
    Rest := Copy(Rest, TabPos + 1, Length(Rest));
  end;
  TabPos := Pos(#9, Rest);
  if TabPos > 0 then
    Result := Copy(Rest, 1, TabPos - 1)
  else
    Result := Rest;
end;

// Раздел справки от строки ATitle до пустой строки или следующего
// заголовка (строка без отступа, кончается двоеточием)
function ArdHelpSection(AHelp: TStrings; const ATitle: string;
                        AStart: Integer; var AFrom, ATo: Integer): Boolean;
var
  LineIdx: Integer;
  LineText: string;
begin
  Result := False;
  AFrom := -1;
  ATo := -1;
  for LineIdx := AStart to AHelp.Count - 1 do
    if Trim(AHelp[LineIdx]) = ATitle then
    begin
      AFrom := LineIdx + 1;
      Break;
    end;
  if AFrom < 0 then
    Exit;
  ATo := AFrom - 1;
  for LineIdx := AFrom to AHelp.Count - 1 do
  begin
    LineText := AHelp[LineIdx];
    if Trim(LineText) = '' then
      Break;
    if (LineText[1] <> ' ') and (LineText[Length(LineText)] = ':') then
      Break;
    ATo := LineIdx;
  end;
  Result := ATo >= AFrom;
end;

function ArdHelpCommands(AHelp: TStrings; ACommands: TStrings): Integer;
var
  FromIdx, ToIdx, LineIdx, SpacePos: Integer;
  LineText, CmdName, CmdText: string;
begin
  ACommands.Clear;
  if ArdHelpSection(AHelp, 'Available Commands:', 0, FromIdx, ToIdx) then
    for LineIdx := FromIdx to ToIdx do
    begin
      LineText := Trim(AHelp[LineIdx]);
      SpacePos := Pos(' ', LineText);
      if SpacePos = 0 then
      begin
        CmdName := LineText;
        CmdText := '';
      end
      else
      begin
        CmdName := Copy(LineText, 1, SpacePos - 1);
        CmdText := Trim(Copy(LineText, SpacePos + 1, Length(LineText)));
      end;
      if CmdName <> '' then
        ACommands.Add(CmdName + #9 + CmdText);
    end;
  Result := ACommands.Count;
end;

function ArdHelpFlags(AHelp: TStrings; AFlags: TStrings): Integer;
var
  FromIdx, ToIdx, LineIdx: Integer;
begin
  AFlags.Clear;
  if ArdHelpSection(AHelp, 'Flags:', 0, FromIdx, ToIdx) then
    for LineIdx := FromIdx to ToIdx do
      AFlags.Add(Trim(AHelp[LineIdx]));
  if ArdHelpSection(AHelp, 'Global Flags:', 0, FromIdx, ToIdx) then
    for LineIdx := FromIdx to ToIdx do
      AFlags.Add(Trim(AHelp[LineIdx]));
  Result := AFlags.Count;
end;

function ArdPackagePath(const ASettings: TArdSettings;
                        const APlatformId, AVersion: string): string;
var
  Vendor, Arch, Root: string;
  ColonPos, RootIdx: Integer;
begin
  Result := '';
  ColonPos := Pos(':', APlatformId);
  if (ColonPos = 0) or (Trim(AVersion) = '') then
    Exit;
  Vendor := Copy(APlatformId, 1, ColonPos - 1);
  Arch := Copy(APlatformId, ColonPos + 1, Length(APlatformId));
  for RootIdx := 0 to 1 do
  begin
    if RootIdx = 0 then
      Root := ASettings.CliDataPath
    else
      Root := ASettings.Arduino15Path;
    if Root = '' then
      Continue;
    Root := Root + 'packages\' + Vendor + '\hardware\' + Arch + '\' +
            Trim(AVersion) + '\';
    if DirectoryExists(Root) then
    begin
      Result := Root;
      Exit;
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Импорт из RQdb.ini
// ---------------------------------------------------------------------------

function ArdImportRqdbIni(const ARqdbIni, AEditorIni, ASection: string;
                          AReport: TStrings): Integer;
const
  // Ключ RQdb.ini [Arduino] = ключ editor.ini [Compiler.Arduino]
  KeyMap: array[0..11] of string = (
    'sketchbookPathEdit=SketchPath',
    'CliPathEdit=CliFile',
    'BuildPathEdit=BuildPath',
    'ArdLibraryPathEdit=LibPath',
    'ArdLogFileEdit=LogFile',
    'ArdCliCfgFileEdit=CliCfgFile',
    'ArdCliDataPathEdit=CliDataPath',
    'ArdCliDOWNLPathEdit=DownloadsPath',
    'ArdCompileDetail=CompileVerbose',
    'ArdLoadDetail=UploadVerbose',
    'ArdCheckCode=VerifyAfterUpload',
    'ArdSaveScetch=SaveBeforeBuild');
  WarningValues = ',none,default,more,all,';
  LogLevelValues = ',trace,debug,info,warn,error,fatal,panic,';
var
  Source, Target: TIniFile;
  MapIdx, EqPos: Integer;
  SrcKey, DstKey, Value, UrlsFile: string;
  UrlsList: TStringList;

  procedure Put(const AKey, AValue: string);
  begin
    Target.WriteString(ASection, AKey, AValue);
    if AReport <> nil then
      AReport.Add(AKey + ' = ' + AValue);
    Inc(Result);
  end;

begin
  Result := 0;
  if not FileExists(ARqdbIni) then
    Exit;
  Source := TIniFile.Create(ARqdbIni);
  Target := TIniFile.Create(AEditorIni);
  try
    for MapIdx := Low(KeyMap) to High(KeyMap) do
    begin
      EqPos := Pos('=', KeyMap[MapIdx]);
      SrcKey := Copy(KeyMap[MapIdx], 1, EqPos - 1);
      DstKey := Copy(KeyMap[MapIdx], EqPos + 1, Length(KeyMap[MapIdx]));
      Value := Trim(Source.ReadString('Arduino', SrcKey, ''));
      if Value <> '' then
        Put(DstKey, Value);
    end;

    // В RQdb.ini бывает "0" вместо уровня - такое не переносится
    Value := LowerCase(Trim(Source.ReadString('Arduino', 'ArdWarningCmb',
                                              '')));
    if (Value <> '') and (Pos(',' + Value + ',', WarningValues) > 0) then
      Put('Warnings', Value)
    else if AReport <> nil then
      AReport.Add('Warnings: в RQdb.ini "' + Value + '" - не перенесено, ' +
                  'будет none');
    Value := LowerCase(Trim(Source.ReadString('Arduino', 'ArdLogLevelCmb',
                                              '')));
    if (Value <> '') and (Pos(',' + Value + ',', LogLevelValues) > 0) then
      Put('LogLevel', Value)
    else if AReport <> nil then
      AReport.Add('LogLevel: в RQdb.ini "' + Value + '" - не перенесено, ' +
                  'будет info');

    // Additional Boards Manager URLs RQdebugger держал в AdditURLEdit.txt
    // рядом с RQdb.ini; берутся только адреса http(s)
    UrlsFile := ExtractFilePath(ARqdbIni) + 'AdditURLEdit.txt';
    if FileExists(UrlsFile) then
    begin
      UrlsList := TStringList.Create;
      try
        UrlsList.LoadFromFile(UrlsFile);
        Value := ArdHttpUrls(UrlsList.Text);
        if Value <> '' then
          Put('AdditionalUrls', Value);
      finally
        UrlsList.Free;
      end;
    end;
  finally
    Target.Free;
    Source.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  JSON: чтение library_index.json
// ---------------------------------------------------------------------------

type
  // Разбор JSON по месту, без построения дерева: позиция в тексте и
  // пропуск значений. Строки возвращаются как есть (UTF-8 с \-escape),
  // перевод - ArdJsonDecode.
  TArdJsonScan = class
  private
    FText: string;
    FLen: Integer;
    FPos: Integer;
  public
    constructor Create(const AText: string; AStart: Integer);
    procedure SkipWs;
    function Peek: Char;
    function Expect(AChar: Char): Boolean;
    function ReadString(var ARaw: string): Boolean;
    function SkipValue: Boolean;
    // Массив строк - через ", "; прочие элементы пропускаются
    function ReadStringArray(var AJoined: string): Boolean;
    property Pos: Integer read FPos;
  end;

constructor TArdJsonScan.Create(const AText: string; AStart: Integer);
begin
  inherited Create;
  FText := AText;
  FLen := Length(AText);
  FPos := AStart;
end;

procedure TArdJsonScan.SkipWs;
begin
  while (FPos <= FLen) and (FText[FPos] in [' ', #9, #10, #13]) do
    Inc(FPos);
end;

function TArdJsonScan.Peek: Char;
begin
  SkipWs;
  if FPos <= FLen then
    Result := FText[FPos]
  else
    Result := #0;
end;

function TArdJsonScan.Expect(AChar: Char): Boolean;
begin
  Result := Peek = AChar;
  if Result then
    Inc(FPos);
end;

function TArdJsonScan.ReadString(var ARaw: string): Boolean;
var
  StartPos: Integer;
begin
  Result := False;
  ARaw := '';
  if Peek <> '"' then
    Exit;
  Inc(FPos);
  StartPos := FPos;
  while FPos <= FLen do
  begin
    if FText[FPos] = '\' then
      Inc(FPos, 2)
    else if FText[FPos] = '"' then
      Break
    else
      Inc(FPos);
  end;
  if FPos > FLen then
    Exit;
  ARaw := Copy(FText, StartPos, FPos - StartPos);
  Inc(FPos);
  Result := True;
end;

function TArdJsonScan.SkipValue: Boolean;
var
  Raw: string;
begin
  Result := False;
  case Peek of
    '"':
      Result := ReadString(Raw);
    '{':
      begin
        Inc(FPos);
        if Expect('}') then
        begin
          Result := True;
          Exit;
        end;
        repeat
          if not ReadString(Raw) or not Expect(':') or not SkipValue then
            Exit;
        until not Expect(',');
        Result := Expect('}');
      end;
    '[':
      begin
        Inc(FPos);
        if Expect(']') then
        begin
          Result := True;
          Exit;
        end;
        repeat
          if not SkipValue then
            Exit;
        until not Expect(',');
        Result := Expect(']');
      end;
    #0:
      Result := False;
  else
    // Число, true, false, null
    while (FPos <= FLen) and
          not (FText[FPos] in [',', '}', ']', ' ', #9, #10, #13]) do
      Inc(FPos);
    Result := True;
  end;
end;

function TArdJsonScan.ReadStringArray(var AJoined: string): Boolean;
var
  Raw: string;
begin
  Result := False;
  AJoined := '';
  if not Expect('[') then
    Exit;
  if Expect(']') then
  begin
    Result := True;
    Exit;
  end;
  repeat
    if Peek = '"' then
    begin
      if not ReadString(Raw) then
        Exit;
      if AJoined <> '' then
        AJoined := AJoined + ', ';
      AJoined := AJoined + Raw;
    end
    else if not SkipValue then
      Exit;
  until not Expect(',');
  Result := Expect(']');
end;

// Строка JSON (как в файле: UTF-8, \-escape) -> ANSI
function ArdJsonDecode(const ARaw: string): string;
var
  Wide, Decoded: WideString;
  SrcIdx, DstLen: Integer;
  Hex: string;
  CodeVal: Integer;
begin
  if (Pos('\', ARaw) = 0) then
  begin
    Result := ArdUtf8ToAnsi(ARaw);
    Exit;
  end;
  Wide := ArdUtf8ToWide(ARaw);
  SetLength(Decoded, Length(Wide));
  DstLen := 0;
  SrcIdx := 1;
  while SrcIdx <= Length(Wide) do
  begin
    if (Wide[SrcIdx] = '\') and (SrcIdx < Length(Wide)) then
    begin
      Inc(SrcIdx);
      Inc(DstLen);
      case Ord(Wide[SrcIdx]) of
        Ord('n'): Decoded[DstLen] := WideChar(10);
        Ord('r'): Decoded[DstLen] := WideChar(13);
        Ord('t'): Decoded[DstLen] := WideChar(9);
        Ord('b'), Ord('f'): Decoded[DstLen] := WideChar(32);
        Ord('u'):
          begin
            Hex := Copy(Wide, SrcIdx + 1, 4);
            CodeVal := StrToIntDef('$' + Hex, Ord('?'));
            // Половинка суррогатной пары - символ вне BMP, в ANSI его нет
            if (CodeVal >= $D800) and (CodeVal <= $DFFF) then
              CodeVal := Ord('?');
            Decoded[DstLen] := WideChar(CodeVal);
            Inc(SrcIdx, 4);
          end;
      else
        Decoded[DstLen] := Wide[SrcIdx];   // \" \\ \/
      end;
      Inc(SrcIdx);
    end
    else
    begin
      Inc(DstLen);
      Decoded[DstLen] := Wide[SrcIdx];
      Inc(SrcIdx);
    end;
  end;
  SetLength(Decoded, DstLen);
  Result := ArdWideToAnsi(Decoded);
end;

// ---------------------------------------------------------------------------
//  TArdLibIndex
// ---------------------------------------------------------------------------

procedure TArdLibIndex.Clear;
begin
  FText := '';
  FItems := nil;
  FCount := 0;
  FFileName := '';
end;

function TArdLibIndex.GetItem(AIndex: Integer): TArdLib;
begin
  Result := FItems[AIndex];
end;

procedure TArdLibIndex.AddItem(const AItem: TArdLib);
begin
  if FCount >= Length(FItems) then
    SetLength(FItems, FCount + 4096);
  FItems[FCount] := AItem;
  Inc(FCount);
end;

function TArdLibIndex.LoadFromFile(const AFile: string;
                                   AOnIdle: TArdIdleEvent;
                                   var AError: string): Boolean;
var
  Stream: TFileStream;
  Scan: TArdJsonScan;
  Key, Raw, Joined: string;
  Lib: TArdLib;
  Cancel: Boolean;
  LibCounter: Integer;

  function ParseLib: Boolean;
  begin
    Result := False;
    Lib.Name := '';
    Lib.Version := '';
    Lib.Category := '';
    Lib.Types := '';
    Lib.Architectures := '';
    Lib.Sentence := '';
    Lib.ObjStart := Scan.Pos;
    if not Scan.Expect('{') then
      Exit;
    if not Scan.Expect('}') then
    begin
      repeat
        if not Scan.ReadString(Key) or not Scan.Expect(':') then
          Exit;
        if Scan.Peek = '"' then
        begin
          if not Scan.ReadString(Raw) then
            Exit;
          if Key = 'name' then
            Lib.Name := ArdJsonDecode(Raw)
          else if Key = 'version' then
            Lib.Version := ArdJsonDecode(Raw)
          else if Key = 'category' then
            Lib.Category := ArdJsonDecode(Raw)
          else if Key = 'sentence' then
            Lib.Sentence := ArdJsonDecode(Raw);
        end
        else if (Scan.Peek = '[') and
                ((Key = 'types') or (Key = 'architectures')) then
        begin
          if not Scan.ReadStringArray(Joined) then
            Exit;
          if Key = 'types' then
            Lib.Types := ArdJsonDecode(Joined)
          else
            Lib.Architectures := ArdJsonDecode(Joined);
        end
        else if not Scan.SkipValue then
          Exit;
      until not Scan.Expect(',');
      if not Scan.Expect('}') then
        Exit;
    end;
    Lib.ObjEnd := Scan.Pos - 1;
    AddItem(Lib);
    Result := True;
  end;

  function ParseLibArray: Boolean;
  begin
    Result := False;
    if not Scan.Expect('[') then
      Exit;
    if Scan.Expect(']') then
    begin
      Result := True;
      Exit;
    end;
    repeat
      if Scan.Peek = '{' then
      begin
        if not ParseLib then
          Exit;
      end
      else if not Scan.SkipValue then
        Exit;
      Inc(LibCounter);
      if (LibCounter mod 500 = 0) and Assigned(AOnIdle) then
      begin
        AOnIdle(Cancel);
        if Cancel then
          Exit;
      end;
    until not Scan.Expect(',');
    Result := Scan.Expect(']');
  end;

begin
  Result := False;
  AError := '';
  Clear;
  if not FileExists(AFile) then
  begin
    AError := 'Нет файла ' + AFile;
    Exit;
  end;

  Stream := TFileStream.Create(AFile, fmOpenRead or fmShareDenyNone);
  try
    SetLength(FText, Stream.Size);
    if Stream.Size > 0 then
      Stream.ReadBuffer(FText[1], Stream.Size);
  finally
    Stream.Free;
  end;

  Cancel := False;
  LibCounter := 0;
  Scan := TArdJsonScan.Create(FText, 1);
  try
    if not Scan.Expect('{') then
    begin
      AError := 'Файл не похож на JSON: ' + AFile;
      Exit;
    end;
    if not Scan.Expect('}') then
      repeat
        if not Scan.ReadString(Key) or not Scan.Expect(':') then
        begin
          AError := Format('Ошибка разбора JSON около позиции %d',
                           [Scan.Pos]);
          Exit;
        end;
        if (Key = 'libraries') and (Scan.Peek = '[') then
        begin
          if not ParseLibArray then
          begin
            if Cancel then
              AError := 'Чтение прервано'
            else
              AError := Format('Ошибка разбора JSON около позиции %d',
                               [Scan.Pos]);
            Exit;
          end;
        end
        else if not Scan.SkipValue then
        begin
          AError := Format('Ошибка разбора JSON около позиции %d',
                           [Scan.Pos]);
          Exit;
        end;
      until not Scan.Expect(',');
  finally
    Scan.Free;
    if AError <> '' then
      Clear;
  end;
  SetLength(FItems, FCount);
  FFileName := AFile;
  Result := True;
end;

function TArdLibIndex.Details(AIndex: Integer): string;
var
  Scan: TArdJsonScan;
  Key, Raw, Joined, Line: string;
  ValueStart: Integer;
  Lines: TStringList;
begin
  Result := '';
  if (AIndex < 0) or (AIndex >= FCount) then
    Exit;
  Lines := TStringList.Create;
  Scan := TArdJsonScan.Create(FText, FItems[AIndex].ObjStart);
  try
    if Scan.Expect('{') and not Scan.Expect('}') then
      repeat
        if not Scan.ReadString(Key) or not Scan.Expect(':') then
          Break;
        Key := ArdJsonDecode(Key);
        if Scan.Peek = '"' then
        begin
          if not Scan.ReadString(Raw) then
            Break;
          Line := Key + ': ' + ArdJsonDecode(Raw);
        end
        else if Scan.Peek = '[' then
        begin
          ValueStart := Scan.Pos;
          if not Scan.ReadStringArray(Joined) then
            Break;
          // Массив объектов (dependencies) - текстом как есть, в одну строку
          if (Joined = '') and (Scan.Pos - ValueStart > 2) then
            Joined := StringReplace(StringReplace(
              Copy(FText, ValueStart, Scan.Pos - ValueStart),
              #13, ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]);
          while Pos('  ', Joined) > 0 do
            Joined := StringReplace(Joined, '  ', ' ', [rfReplaceAll]);
          Line := Key + ': ' + ArdJsonDecode(Joined);
        end
        else
        begin
          ValueStart := Scan.Pos;
          if not Scan.SkipValue then
            Break;
          Line := Key + ': ' + Trim(Copy(FText, ValueStart,
                                         Scan.Pos - ValueStart));
        end;
        // Перевод строки внутри значения (\n в paragraph) - тоже CRLF
        Line := StringReplace(StringReplace(Line, #13#10, #10,
                                            [rfReplaceAll]),
                              #10, #13#10, [rfReplaceAll]);
        Lines.Add(Line);
      until not Scan.Expect(',');
    Result := Lines.Text;
  finally
    Scan.Free;
    Lines.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Сборка скетча (Verify / Upload)
// ---------------------------------------------------------------------------

function ArdLoadBuildOptions(const AIniFile, ASection: string):
  TArdBuildOptions;
const
  WarningValues = ',none,default,more,all,';
  LogLevelValues = ',trace,debug,info,warn,error,fatal,panic,';
var
  Ini: TIniFile;
begin
  Result.Warnings := 'none';
  Result.LogLevel := 'info';
  Result.CompileVerbose := False;
  Result.UploadVerbose := False;
  Result.VerifyAfterUpload := False;
  Result.SaveBeforeBuild := False;
  Result.ExportBinaries := False;
  if (AIniFile = '') or not FileExists(AIniFile) then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    Result.Warnings := LowerCase(Trim(Ini.ReadString(ASection, 'Warnings',
                                                     'none')));
    if Pos(',' + Result.Warnings + ',', WarningValues) = 0 then
      Result.Warnings := 'none';
    Result.LogLevel := LowerCase(Trim(Ini.ReadString(ASection, 'LogLevel',
                                                     'info')));
    if Pos(',' + Result.LogLevel + ',', LogLevelValues) = 0 then
      Result.LogLevel := 'info';
    Result.CompileVerbose := Trim(Ini.ReadString(ASection, 'CompileVerbose',
                                                 '0')) = '1';
    Result.UploadVerbose := Trim(Ini.ReadString(ASection, 'UploadVerbose',
                                                '0')) = '1';
    Result.VerifyAfterUpload := Trim(Ini.ReadString(ASection,
                                       'VerifyAfterUpload', '0')) = '1';
    Result.SaveBeforeBuild := Trim(Ini.ReadString(ASection,
                                     'SaveBeforeBuild', '0')) = '1';
    Result.ExportBinaries := Trim(Ini.ReadString(ASection, 'ExportBinaries',
                                                 '0')) = '1';
  finally
    Ini.Free;
  end;
end;

function ArdSketchBuildDir(const ASettings: TArdSettings;
                           const ASketchDir: string): string;
var
  SketchName: string;
begin
  Result := '';
  if ASettings.BuildPath = '' then
    Exit;
  SketchName := ExtractFileName(ExcludeTrailingPathDelimiter(ASketchDir));
  if SketchName = '' then
    Exit;
  Result := IncludeTrailingPathDelimiter(ASettings.BuildPath) + SketchName +
            '\';
end;

function ArdCompileArgs(const ASettings: TArdSettings;
                        const AOptions: TArdBuildOptions;
                        const AFqbn, ASketchDir, APort: string): string;
var
  BuildDir: string;
  Upload: Boolean;
begin
  Upload := Trim(APort) <> '';
  Result := 'compile -b ' + Trim(AFqbn);
  BuildDir := ArdSketchBuildDir(ASettings, ASketchDir);
  if BuildDir <> '' then
    Result := Result + ' --build-path ' +
              ArdQuote(ExcludeTrailingPathDelimiter(BuildDir));
  if (ASettings.LibPath <> '') and DirectoryExists(ASettings.LibPath) then
    Result := Result + ' --libraries ' +
              ArdQuote(ExcludeTrailingPathDelimiter(ASettings.LibPath));
  Result := Result + ' --warnings ' + AOptions.Warnings;
  if AOptions.CompileVerbose or (Upload and AOptions.UploadVerbose) then
    Result := Result + ' -v';
  if AOptions.ExportBinaries then
    Result := Result + ' -e';
  // Уровень лога без файла лога сыплет служебные строки в вывод
  if ASettings.LogFile <> '' then
    Result := Result + ' --log-file ' + ArdQuote(ASettings.LogFile) +
              ' --log-level ' + AOptions.LogLevel;
  if Upload then
  begin
    Result := Result + ' -u -p ' + Trim(APort);
    if AOptions.VerifyAfterUpload then
      Result := Result + ' -t';
  end;
  Result := Result + ' ' + ArdQuote(ExcludeTrailingPathDelimiter(ASketchDir));
end;

function ArdPlatformOfFqbn(const AFqbn: string): string;
var
  FirstColon, SecondColon: Integer;
begin
  Result := Trim(AFqbn);
  FirstColon := Pos(':', Result);
  if FirstColon = 0 then
    Exit;
  SecondColon := Pos(':', Copy(Result, FirstColon + 1, MaxInt));
  if SecondColon > 0 then
    Result := Copy(Result, 1, FirstColon + SecondColon - 1);
end;

function ArdIsPlatformMissing(const AText: string): Boolean;
var
  LowText: string;
begin
  LowText := LowerCase(AText);
  Result := (Pos('platform', LowText) > 0) and
            ((Pos('not found', LowText) > 0) or
             (Pos('not installed', LowText) > 0));
end;

function ArdIsGccError(const AText: string): Boolean;
var
  LowText: string;
begin
  LowText := LowerCase(AText);
  Result := (Pos(': error:', LowText) > 0) or
            (Pos(': fatal error:', LowText) > 0) or
            (Pos('undefined reference to', LowText) > 0);
end;

function ArdParseGccLine(const AText: string; var AFile: string;
                         var ALineNo, AColNo: Integer): Boolean;
const
  IncludedTag = 'in file included from ';
  FromTag = 'from ';
var
  Work, LowWork: string;
  ColonPos, NumEnd, ColEnd, SearchFrom, Found: Integer;

  // Конец цифр, начиная с AFrom; цифр нет - AFrom
  function DigitsEnd(AFrom: Integer): Integer;
  begin
    Result := AFrom;
    while (Result <= Length(Work)) and (Work[Result] in ['0'..'9']) do
      Inc(Result);
  end;

begin
  Result := False;
  AFile := '';
  ALineNo := 0;
  AColNo := 0;
  Work := Trim(AText);
  LowWork := LowerCase(Work);
  if Copy(LowWork, 1, Length(IncludedTag)) = IncludedTag then
    Work := TrimLeft(Copy(Work, Length(IncludedTag) + 1, MaxInt))
  else if Copy(LowWork, 1, Length(FromTag)) = FromTag then
    Work := TrimLeft(Copy(Work, Length(FromTag) + 1, MaxInt));
  if Length(Work) < 4 then
    Exit;

  // C: в начале - буква диска, искать двоеточие после неё
  SearchFrom := 1;
  if (Work[2] = ':') and (UpCase(Work[1]) in ['A'..'Z']) then
    SearchFrom := 3;

  // Первое двоеточие, за которым цифры и снова двоеточие (или запятая)
  ColonPos := 0;
  while SearchFrom <= Length(Work) do
  begin
    Found := Pos(':', Copy(Work, SearchFrom, MaxInt));
    if Found = 0 then
      Exit;
    Found := SearchFrom + Found - 1;
    NumEnd := DigitsEnd(Found + 1);
    // "from файл:12," - у вложенного include после строки запятая
    if (NumEnd > Found + 1) and (NumEnd <= Length(Work)) and
       (Work[NumEnd] in [':', ',']) then
    begin
      ColonPos := Found;
      Break;
    end;
    SearchFrom := Found + 1;
  end;
  if ColonPos <= 1 then
    Exit;

  NumEnd := DigitsEnd(ColonPos + 1);
  ALineNo := StrToIntDef(Copy(Work, ColonPos + 1, NumEnd - ColonPos - 1), 0);
  // Столбец: цифры после второго двоеточия, дальше : , или конец строки
  ColEnd := DigitsEnd(NumEnd + 1);
  if (ColEnd > NumEnd + 1) and
     ((ColEnd > Length(Work)) or (Work[ColEnd] in [':', ','])) then
    AColNo := StrToIntDef(Copy(Work, NumEnd + 1, ColEnd - NumEnd - 1), 0);

  AFile := Trim(Copy(Work, 1, ColonPos - 1));
  AFile := StringReplace(AFile, '/', '\', [rfReplaceAll]);
  Result := (AFile <> '') and (ALineNo > 0);
end;

end.
