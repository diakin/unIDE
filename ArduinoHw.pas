unit ArduinoHw;

// Установленные платформы и платы Arduino, библиотеки и скетчи - по файлам
// на диске, без запуска arduino-cli. Для меню Arduino главного окна:
// Board, Port (имя платы по VID/PID), Examples, Include Library,
// Sketchbook.
//
// Платформы:
//   <data>\packages\<vendor>\hardware\<arch>\<version>\  - установленные
//     через arduino-cli или Boards Manager; <data> - CliDataPath,
//     Arduino15Path и %LOCALAPPDATA%\Arduino15; из нескольких версий
//     берётся старшая, из нескольких папок <data> - первая;
//   <sketchbook>\hardware\<vendor>\<arch>\  - поставленные вручную.
// Имя платформы - name= из platform.txt, платы - из boards.txt: <id>.name,
// VID/PID - <id>.vid.N и <id>.pid.N; платы с <id>.hide не показываются
// (так же делает Arduino IDE).
//
// Библиотека - папка с library.properties, папкой src или файлами .h.
// Имя - name= из library.properties, иначе имя папки. Заголовки для
// Include Library - includes= из library.properties, иначе файлы .h в src
// (формат 1.5) или в корне папки (старый формат).
//
// Скетч - папка, в которой есть <имя папки>.ino (или .pde).

interface

uses
  Windows, SysUtils, Classes, IniFiles, ArduinoCli;

type
  TArdBoardInfo = record
    Name: string;
    Fqbn: string;           // vendor:arch:id
    PlatformIdx: Integer;
    VidPids: string;        // ';2341:003D;2341:803D;' - VID:PID заглавными
  end;

  TArdPlatformInfo = record
    Id: string;             // vendor:arch
    Name: string;           // name= из platform.txt, иначе Id
    Version: string;        // '' - из sketchbook\hardware
    Folder: string;         // с завершающей \
    FirstBoard: Integer;    // платы платформы - подряд в Boards
    BoardCount: Integer;
  end;

  TArdHardware = class
  private
    FPlatforms: array of TArdPlatformInfo;
    FBoards: array of TArdBoardInfo;
    FPlatformCount: Integer;
    FBoardCount: Integer;
    function GetPlatform(AIndex: Integer): TArdPlatformInfo;
    function GetBoard(AIndex: Integer): TArdBoardInfo;
    procedure AddPlatform(const AId, AVersion, AFolder: string);
    procedure ReadBoards(APlatformIdx: Integer);
  public
    procedure Clear;
    procedure Scan(const ASettings: TArdSettings);
    // Плата по FQBN (сравниваются первые три части: опции платы вида
    // :cpu=... не мешают); -1 - нет
    function BoardByFqbn(const AFqbn: string): Integer;
    // Плата по VID и PID (шестнадцатеричные, как в Windows: '2341');
    // -1 - нет
    function BoardByVidPid(const AVid, APid: string): Integer;
    // Папка библиотек платформы ('' - нет)
    function PlatformLibFolder(APlatformIdx: Integer): string;
    property PlatformCount: Integer read FPlatformCount;
    property BoardCount: Integer read FBoardCount;
    property Platforms[AIndex: Integer]: TArdPlatformInfo read GetPlatform;
    property Boards[AIndex: Integer]: TArdBoardInfo read GetBoard;
  end;

// Папки данных arduino-cli и Arduino IDE (packages, индексы), без
// повторов: CliDataPath, Arduino15Path, %LOCALAPPDATA%\Arduino15
procedure ArdDataFolders(const ASettings: TArdSettings; AFolders: TStrings);
// Сравнение версий '1.8.9' и '1.8.10' по числам; <0, 0, >0
function ArdCompareVersion(const AVersion1, AVersion2: string): Integer;
// Вложенные папки AFolder (только имена), по алфавиту без учёта регистра
procedure ArdSubFolders(const AFolder: string; ANames: TStrings);
// Файл скетча папки AFolder: <папка>\<имя>.ino или .pde; '' - не скетч
function ArdSketchFile(const AFolder: string): string;
// Библиотеки папки AFolder: строки "имя"#9"папка библиотеки\", по
// алфавиту. AOnlyWithExamples - только те, у которых есть examples.
procedure ArdScanLibraries(const AFolder: string; ALibs: TStrings;
                           AOnlyWithExamples: Boolean);
// Заголовки библиотеки для #include
procedure ArdLibraryIncludes(const ALibFolder: string; AHeaders: TStrings);
// Папка примеров библиотеки ('' - нет)
function ArdLibraryExamples(const ALibFolder: string): string;
// Встроенные примеры: <IdePath>examples, иначе <CliDataPath>examples,
// иначе <Arduino15Path>examples; '' - нет
function ArdBuiltinExamples(const ASettings: TArdSettings): string;

implementation

// ---------------------------------------------------------------------------
//  Папки
// ---------------------------------------------------------------------------

function DirWithSlash(const APath: string): string;
begin
  Result := Trim(APath);
  if Result <> '' then
    Result := IncludeTrailingPathDelimiter(Result);
end;

procedure ArdDataFolders(const ASettings: TArdSettings; AFolders: TStrings);

  procedure AddFolder(const AFolder: string);
  var
    Folder: string;
    FolderIdx: Integer;
  begin
    Folder := DirWithSlash(AFolder);
    if (Folder = '') or not DirectoryExists(Folder) then
      Exit;
    for FolderIdx := 0 to AFolders.Count - 1 do
      if CompareText(AFolders[FolderIdx], Folder) = 0 then
        Exit;
    AFolders.Add(Folder);
  end;

var
  LocalData: array[0..MAX_PATH] of Char;
begin
  AFolders.Clear;
  AddFolder(ASettings.CliDataPath);
  AddFolder(ASettings.Arduino15Path);
  if Windows.GetEnvironmentVariable('LOCALAPPDATA', LocalData,
                                    SizeOf(LocalData)) > 0 then
    AddFolder(DirWithSlash(string(LocalData)) + 'Arduino15');
end;

function ArdCompareVersion(const AVersion1, AVersion2: string): Integer;
var
  Rest1, Rest2, Part1, Part2: string;
  Num1, Num2, DotPos: Integer;

  function TakePart(var ARest: string): string;
  begin
    DotPos := Pos('.', ARest);
    if DotPos = 0 then
    begin
      Result := ARest;
      ARest := '';
    end
    else
    begin
      Result := Copy(ARest, 1, DotPos - 1);
      Delete(ARest, 1, DotPos);
    end;
  end;

begin
  Result := 0;
  Rest1 := Trim(AVersion1);
  Rest2 := Trim(AVersion2);
  while (Result = 0) and ((Rest1 <> '') or (Rest2 <> '')) do
  begin
    Part1 := TakePart(Rest1);
    Part2 := TakePart(Rest2);
    Num1 := StrToIntDef(Part1, -1);
    Num2 := StrToIntDef(Part2, -1);
    if (Num1 >= 0) and (Num2 >= 0) then
      Result := Num1 - Num2
    else
      Result := CompareText(Part1, Part2);
  end;
end;

procedure ArdSubFolders(const AFolder: string; ANames: TStrings);
var
  Found: TSearchRec;
  Names: TStringList;
begin
  ANames.Clear;
  if (AFolder = '') or not DirectoryExists(AFolder) then
    Exit;
  Names := TStringList.Create;
  try
    if FindFirst(DirWithSlash(AFolder) + '*', faDirectory, Found) = 0 then
    try
      repeat
        if (Found.Attr and faDirectory <> 0) and (Found.Name <> '.') and
           (Found.Name <> '..') then
          Names.Add(Found.Name);
      until FindNext(Found) <> 0;
    finally
      FindClose(Found);
    end;
    Names.Sort;    // CompareText - без учёта регистра
    ANames.Assign(Names);
  finally
    Names.Free;
  end;
end;

function ArdSketchFile(const AFolder: string): string;
var
  Folder, BaseName: string;
begin
  Folder := DirWithSlash(AFolder);
  BaseName := ExtractFileName(ExcludeTrailingPathDelimiter(Folder));
  Result := Folder + BaseName + '.ino';
  if FileExists(Result) then
    Exit;
  Result := Folder + BaseName + '.pde';
  if FileExists(Result) then
    Exit;
  Result := '';
end;

// Значение ключа AKey (name=, includes= ...) файла key=value; '' - нет
function PropertyValue(const AFile, AKey: string): string;
var
  Lines: TStringList;
  LineIdx, EqPos: Integer;
  Line: string;
begin
  Result := '';
  if not FileExists(AFile) then
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
      Line := Trim(Lines[LineIdx]);
      EqPos := Pos('=', Line);
      if (EqPos > 1) and (CompareText(Trim(Copy(Line, 1, EqPos - 1)),
                                      AKey) = 0) then
      begin
        Result := ArdUtf8ToAnsi(Trim(Copy(Line, EqPos + 1, MaxInt)));
        Exit;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function HasFiles(const AMask: string): Boolean;
var
  Found: TSearchRec;
begin
  Result := FindFirst(AMask, faAnyFile and not faDirectory, Found) = 0;
  if Result then
    FindClose(Found);
end;

function ArdLibraryExamples(const ALibFolder: string): string;
begin
  Result := DirWithSlash(ALibFolder) + 'examples\';
  if not DirectoryExists(Result) then
    Result := '';
end;

procedure ArdScanLibraries(const AFolder: string; ALibs: TStrings;
                           AOnlyWithExamples: Boolean);
var
  Folders, Libs: TStringList;
  FolderIdx: Integer;
  LibFolder, LibName: string;
begin
  ALibs.Clear;
  Folders := TStringList.Create;
  Libs := TStringList.Create;
  try
    ArdSubFolders(AFolder, Folders);
    for FolderIdx := 0 to Folders.Count - 1 do
    begin
      LibFolder := DirWithSlash(AFolder) + Folders[FolderIdx] + '\';
      if not FileExists(LibFolder + 'library.properties') and
         not DirectoryExists(LibFolder + 'src') and
         not HasFiles(LibFolder + '*.h') then
        Continue;
      if AOnlyWithExamples and (ArdLibraryExamples(LibFolder) = '') then
        Continue;
      LibName := PropertyValue(LibFolder + 'library.properties', 'name');
      if LibName = '' then
        LibName := Folders[FolderIdx];
      Libs.Add(LibName + #9 + LibFolder);
    end;
    Libs.Sort;
    ALibs.Assign(Libs);
  finally
    Libs.Free;
    Folders.Free;
  end;
end;

procedure ArdLibraryIncludes(const ALibFolder: string; AHeaders: TStrings);
var
  Folder, Includes, OneHeader: string;
  CommaPos: Integer;
  Found: TSearchRec;
begin
  AHeaders.Clear;
  Folder := DirWithSlash(ALibFolder);
  Includes := PropertyValue(Folder + 'library.properties', 'includes');
  if Includes <> '' then
  begin
    while Includes <> '' do
    begin
      CommaPos := Pos(',', Includes);
      if CommaPos = 0 then
        CommaPos := Length(Includes) + 1;
      OneHeader := Trim(Copy(Includes, 1, CommaPos - 1));
      Delete(Includes, 1, CommaPos);
      if OneHeader <> '' then
        AHeaders.Add(OneHeader);
    end;
    Exit;
  end;
  if DirectoryExists(Folder + 'src') then
    Folder := Folder + 'src\';
  if FindFirst(Folder + '*.h', faAnyFile and not faDirectory, Found) = 0 then
  try
    repeat
      AHeaders.Add(Found.Name);
    until FindNext(Found) <> 0;
  finally
    FindClose(Found);
  end;
end;

function ArdBuiltinExamples(const ASettings: TArdSettings): string;
begin
  Result := '';
  if (ASettings.IdePath <> '') and
     DirectoryExists(ASettings.IdePath + 'examples') then
    Result := ASettings.IdePath + 'examples\'
  else if (ASettings.CliDataPath <> '') and
          DirectoryExists(ASettings.CliDataPath + 'examples') then
    Result := ASettings.CliDataPath + 'examples\'
  else if (ASettings.Arduino15Path <> '') and
          DirectoryExists(ASettings.Arduino15Path + 'examples') then
    Result := ASettings.Arduino15Path + 'examples\';
end;

// ---------------------------------------------------------------------------
//  TArdHardware
// ---------------------------------------------------------------------------

function TArdHardware.GetPlatform(AIndex: Integer): TArdPlatformInfo;
begin
  Result := FPlatforms[AIndex];
end;

function TArdHardware.GetBoard(AIndex: Integer): TArdBoardInfo;
begin
  Result := FBoards[AIndex];
end;

procedure TArdHardware.Clear;
begin
  FPlatforms := nil;
  FBoards := nil;
  FPlatformCount := 0;
  FBoardCount := 0;
end;

procedure TArdHardware.AddPlatform(const AId, AVersion, AFolder: string);
var
  PlatformIdx: Integer;
  PlatformName: string;
begin
  for PlatformIdx := 0 to FPlatformCount - 1 do
    if CompareText(FPlatforms[PlatformIdx].Id, AId) = 0 then
      Exit;     // та же платформа из другой папки данных - первая остаётся
  if not FileExists(AFolder + 'boards.txt') then
    Exit;
  if FPlatformCount = Length(FPlatforms) then
    SetLength(FPlatforms, FPlatformCount + 8);
  PlatformName := PropertyValue(AFolder + 'platform.txt', 'name');
  if PlatformName = '' then
    PlatformName := AId;
  FPlatforms[FPlatformCount].Id := AId;
  FPlatforms[FPlatformCount].Name := PlatformName;
  FPlatforms[FPlatformCount].Version := AVersion;
  FPlatforms[FPlatformCount].Folder := AFolder;
  FPlatforms[FPlatformCount].FirstBoard := FBoardCount;
  FPlatforms[FPlatformCount].BoardCount := 0;
  Inc(FPlatformCount);
  ReadBoards(FPlatformCount - 1);
end;

// Платы из boards.txt платформы - в FBoards, в порядке файла
procedure TArdHardware.ReadBoards(APlatformIdx: Integer);
var
  Lines, BoardIds: TStringList;
  Values: THashedStringList;
  LineIdx, EqPos, DotPos, IdIdx, PairIdx: Integer;
  Line, Key, Value, BoardId, Rest, VidText, PidText: string;
begin
  Lines := TStringList.Create;
  BoardIds := TStringList.Create;
  Values := THashedStringList.Create;
  try
    try
      Lines.LoadFromFile(FPlatforms[APlatformIdx].Folder + 'boards.txt');
    except
      Exit;
    end;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[LineIdx]);
      if (Line = '') or (Line[1] = '#') then
        Continue;
      EqPos := Pos('=', Line);
      if EqPos < 2 then
        Continue;
      Key := Trim(Copy(Line, 1, EqPos - 1));
      Value := Trim(Copy(Line, EqPos + 1, MaxInt));
      Values.Add(LowerCase(Key) + '=' + Value);
      // <id>.name - новая плата (menu.cpu=... - не плата)
      DotPos := Pos('.', Key);
      if DotPos = 0 then
        Continue;
      BoardId := Copy(Key, 1, DotPos - 1);
      Rest := Copy(Key, DotPos + 1, MaxInt);
      if (CompareText(Rest, 'name') = 0) and
         (CompareText(BoardId, 'menu') <> 0) then
        BoardIds.Add(BoardId);
    end;

    for IdIdx := 0 to BoardIds.Count - 1 do
    begin
      BoardId := LowerCase(BoardIds[IdIdx]);
      if Values.IndexOfName(BoardId + '.hide') >= 0 then
        Continue;
      if FBoardCount = Length(FBoards) then
        SetLength(FBoards, FBoardCount + 32);
      FBoards[FBoardCount].Name :=
        ArdUtf8ToAnsi(Values.Values[BoardId + '.name']);
      FBoards[FBoardCount].Fqbn := FPlatforms[APlatformIdx].Id + ':' +
                                   BoardIds[IdIdx];
      FBoards[FBoardCount].PlatformIdx := APlatformIdx;
      FBoards[FBoardCount].VidPids := ';';
      for PairIdx := 0 to 31 do
      begin
        VidText := Values.Values[BoardId + '.vid.' + IntToStr(PairIdx)];
        PidText := Values.Values[BoardId + '.pid.' + IntToStr(PairIdx)];
        if (VidText = '') or (PidText = '') then
        begin
          if PairIdx > 0 then
            Break;
          Continue;    // нумерация бывает и с 1
        end;
        if Pos('0x', LowerCase(VidText)) = 1 then
          Delete(VidText, 1, 2);
        if Pos('0x', LowerCase(PidText)) = 1 then
          Delete(PidText, 1, 2);
        FBoards[FBoardCount].VidPids := FBoards[FBoardCount].VidPids +
          UpperCase(VidText) + ':' + UpperCase(PidText) + ';';
      end;
      Inc(FBoardCount);
      Inc(FPlatforms[APlatformIdx].BoardCount);
    end;
  finally
    Values.Free;
    BoardIds.Free;
    Lines.Free;
  end;
end;

procedure TArdHardware.Scan(const ASettings: TArdSettings);
var
  DataFolders, Vendors, Arches, Versions: TStringList;
  DataIdx, VendorIdx, ArchIdx, VersionIdx: Integer;
  HwFolder, ArchFolder, BestVersion: string;
begin
  Clear;
  DataFolders := TStringList.Create;
  Vendors := TStringList.Create;
  Arches := TStringList.Create;
  Versions := TStringList.Create;
  try
    ArdDataFolders(ASettings, DataFolders);
    for DataIdx := 0 to DataFolders.Count - 1 do
    begin
      ArdSubFolders(DataFolders[DataIdx] + 'packages', Vendors);
      for VendorIdx := 0 to Vendors.Count - 1 do
      begin
        HwFolder := DataFolders[DataIdx] + 'packages\' + Vendors[VendorIdx] +
                    '\hardware\';
        ArdSubFolders(HwFolder, Arches);
        for ArchIdx := 0 to Arches.Count - 1 do
        begin
          ArchFolder := HwFolder + Arches[ArchIdx] + '\';
          ArdSubFolders(ArchFolder, Versions);
          BestVersion := '';
          for VersionIdx := 0 to Versions.Count - 1 do
            if FileExists(ArchFolder + Versions[VersionIdx] + '\boards.txt') and
               ((BestVersion = '') or
                (ArdCompareVersion(Versions[VersionIdx], BestVersion) > 0)) then
              BestVersion := Versions[VersionIdx];
          if BestVersion <> '' then
            AddPlatform(Vendors[VendorIdx] + ':' + Arches[ArchIdx],
                        BestVersion, ArchFolder + BestVersion + '\');
        end;
      end;
    end;

    // Платформы, поставленные вручную: <sketchbook>\hardware\<vendor>\<arch>
    if ASettings.SketchPath <> '' then
    begin
      HwFolder := ASettings.SketchPath + 'hardware\';
      ArdSubFolders(HwFolder, Vendors);
      for VendorIdx := 0 to Vendors.Count - 1 do
      begin
        ArdSubFolders(HwFolder + Vendors[VendorIdx], Arches);
        for ArchIdx := 0 to Arches.Count - 1 do
          AddPlatform(Vendors[VendorIdx] + ':' + Arches[ArchIdx], '',
                      HwFolder + Vendors[VendorIdx] + '\' + Arches[ArchIdx] +
                      '\');
      end;
    end;
  finally
    Versions.Free;
    Arches.Free;
    Vendors.Free;
    DataFolders.Free;
  end;
end;

// Первые три части FQBN (vendor:arch:board)
function FqbnBase(const AFqbn: string): string;
var
  CharIdx, Colons: Integer;
begin
  Result := Trim(AFqbn);
  Colons := 0;
  for CharIdx := 1 to Length(Result) do
    if Result[CharIdx] = ':' then
    begin
      Inc(Colons);
      if Colons = 3 then
      begin
        Result := Copy(Result, 1, CharIdx - 1);
        Exit;
      end;
    end;
end;

function TArdHardware.BoardByFqbn(const AFqbn: string): Integer;
var
  Base: string;
  BoardIdx: Integer;
begin
  Result := -1;
  Base := FqbnBase(AFqbn);
  for BoardIdx := 0 to FBoardCount - 1 do
    if CompareText(FBoards[BoardIdx].Fqbn, Base) = 0 then
    begin
      Result := BoardIdx;
      Exit;
    end;
end;

function TArdHardware.BoardByVidPid(const AVid, APid: string): Integer;
var
  Pair: string;
  BoardIdx: Integer;
begin
  Result := -1;
  if (AVid = '') or (APid = '') then
    Exit;
  Pair := ';' + UpperCase(AVid) + ':' + UpperCase(APid) + ';';
  for BoardIdx := 0 to FBoardCount - 1 do
    if Pos(Pair, FBoards[BoardIdx].VidPids) > 0 then
    begin
      Result := BoardIdx;
      Exit;
    end;
end;

function TArdHardware.PlatformLibFolder(APlatformIdx: Integer): string;
begin
  Result := '';
  if (APlatformIdx < 0) or (APlatformIdx >= FPlatformCount) then
    Exit;
  Result := FPlatforms[APlatformIdx].Folder + 'libraries\';
  if not DirectoryExists(Result) then
    Result := '';
end;

end.
