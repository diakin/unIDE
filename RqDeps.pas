unit RqDeps;

// ---------------------------------------------------------------------------
//  Проверка перед сборкой RapidQ: есть ли на диске всё, что нужно программе.
//    - $INCLUDE "файл" / <файл> - с вложенными, по тем же правилам, что
//      rc.exe: путь целиком, иначе папка программы (текущая папка rc.exe),
//      потом папка -I;
//    - $RESOURCE Имя AS "файл" - там же (справка Rapid-Q: текущая папка и
//      папки include);
//    - DECLARE ... LIB "имя.dll" - при запуске exe Windows ищет DLL в папке
//      exe, в системных папках и в PATH.
//  Условная сборка: $IFDEF, $IFNDEF, $ELSE, $ENDIF, $DEFINE, $UNDEF и
//  псевдонимы директив через $DEFINE (brem/erem, remb/reme из RAPIDQ.INC
//  известны заранее). Имя считается определённым, только если его $DEFINE
//  встретился раньше в тексте: $IFDEF неизвестного имени - блок не
//  проверяется. Так же поступает отладчик (RqDbgInstr).
//  Недостающее ищется на диске (IncFindNamesOnDisk); копия выбирается:
//  inc - совпадающая с эталоном (incOld), иначе первая по порядку поиска.
//  Без VCL.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes,
  IncCheck,     // IncSplitLine, IncFindNamesOnDisk, эталон
  RqDbgInstr;   // RqDbgIncludeName, RqDbgResolveInclude

type
  TRqDepKind = (dpkInclude, dpkResource, dpkLib);

  // Куда копировать найденное: папка -I сборки или папка программы (exe)
  TRqDepTarget = (dptIncDir, dptMainDir);

  TRqDep = class
  public
    Kind: TRqDepKind;
    Name: string;          // как написано в исходнике
    FromFile: string;      // где подключён (первое место)
    FromLine: Integer;     // строка, с 1
    Resolved: string;      // найден там, где его возьмёт rc.exe / Windows
    Candidates: TStringList;  // копии на диске, в порядке поиска
    Where: TStringList;    // шаг поиска каждой копии
    Chosen: Integer;       // выбранная копия (-1 - нет)
    ChosenNote: string;    // почему выбрана (совпадает с эталоном ...)
    Target: TRqDepTarget;
    constructor Create;
    destructor Destroy; override;
    function Missing: Boolean;
    function FileNameOnly: string;
  end;

  TRqDepScan = class
  private
    FMainDir: string;
    FIncDir: string;
    FItems: TList;          // TRqDep, владелец
    FScanned: TStringList;  // прочитанные файлы (верхний регистр)
    FDefined: TStringList;  // $DEFINE имена (верхний регистр)
    FAliases: TStringList;  // ИМЯ=IFDEF / IFNDEF / ELSE / ENDIF
    FLibCache: TStringList; // ИМЯ.DLL=1/0
    procedure ScanFile(const AFile: string; ADepth: Integer);
    function AddDep(AKind: TRqDepKind; const AName, AFrom: string;
                    ALine: Integer): TRqDep;
    function GetItem(AIndex: Integer): TRqDep;
  public
    constructor Create;
    destructor Destroy; override;
    // AMainBas - главный .bas; AIncDir - папка -I ('' - нет)
    procedure Scan(const AMainBas, AIncDir: string);
    function Count: Integer;
    function MissingCount: Integer;
    function CountOf(AKind: TRqDepKind): Integer;
    // Убрать из списка недостающие с этими именами (верхний регистр)
    procedure DropNames(ANames: TStrings);
    property Items[AIndex: Integer]: TRqDep read GetItem; default;
    property MainDir: string read FMainDir;
    property IncDir: string read FIncDir;
    property ScannedFiles: TStringList read FScanned;
  end;

const
  RqDepKindNames: array[TRqDepKind] of string = ('inc', 'ресурс', 'DLL');

// Найдёт ли Windows DLL при запуске exe из папки AExeDir
function RqLibExists(const ALib, AExeDir: string): Boolean;

// Полный путь, куда копировать найденную копию
function RqDepTargetPath(ADep: TRqDep; const AIncDir, AMainDir: string): string;

// Поиск недостающих на диске: ARoots - строки "шаг|папка" по порядку.
// Копии - в Candidates / Where каждого. AStopAfterInclude - если в
// папках Include (шаги "Include ...") что-то нашлось, дальше не искать:
// остальное - при следующем поиске без этого флага. False - прервано.
function RqDepsFindOnDisk(AScan: TRqDepScan; ARoots: TStrings;
                          AProgress: TIncProgress;
                          AStopAfterInclude: Boolean = False): Boolean;

// Выбор копии: inc - первая, совпадающая с эталоном ARef (nil - без
// сравнения), иначе первая по порядку
procedure RqDepsChoose(AScan: TRqDepScan; ARef: TIncRefIndex);

implementation

const
  MaxDepth = 20;
  MaxCandidates = 200;

{ TRqDep }

constructor TRqDep.Create;
begin
  inherited Create;
  Candidates := TStringList.Create;
  Where := TStringList.Create;
  Chosen := -1;
end;

destructor TRqDep.Destroy;
begin
  Candidates.Free;
  Where.Free;
  inherited Destroy;
end;

function TRqDep.Missing: Boolean;
begin
  Result := Resolved = '';
end;

function TRqDep.FileNameOnly: string;
begin
  Result := ExtractFileName(Name);
  if (Kind = dpkLib) and (ExtractFileExt(Result) = '') then
    Result := Result + '.dll';
end;

{ helpers }

function HasPath(const AName: string): Boolean;
begin
  Result := (ExtractFileDrive(AName) <> '') or (Pos('\', AName) > 0) or
            (Pos('/', AName) > 0);
end;

function RqLibExists(const ALib, AExeDir: string): Boolean;
var
  LibName, PathList, PathDir: string;
  Buf: array[0..MAX_PATH] of Char;
  SepPos: Integer;

  function InDir(const ADir: string): Boolean;
  begin
    Result := (Trim(ADir) <> '') and
              FileExists(IncludeTrailingPathDelimiter(Trim(ADir)) + LibName);
  end;

begin
  LibName := StringReplace(Trim(ALib), '/', '\', [rfReplaceAll]);
  Result := LibName = '';
  if Result then
    Exit;
  if ExtractFileExt(LibName) = '' then
    LibName := LibName + '.dll';
  if HasPath(LibName) then
  begin
    if ExtractFileDrive(LibName) <> '' then
      Result := FileExists(LibName)
    else
      Result := FileExists(IncludeTrailingPathDelimiter(AExeDir) + LibName);
    Exit;
  end;
  Result := InDir(AExeDir);
  if Result then
    Exit;
  // 32-битная программа: System32 открывается как SysWOW64 - так же, как
  // для exe RapidQ
  if GetSystemDirectory(Buf, SizeOf(Buf)) > 0 then
    Result := InDir(StrPas(Buf));
  if Result then
    Exit;
  if GetWindowsDirectory(Buf, SizeOf(Buf)) > 0 then
  begin
    Result := InDir(StrPas(Buf)) or
              InDir(IncludeTrailingPathDelimiter(StrPas(Buf)) + 'System');
    if Result then
      Exit;
  end;
  PathList := GetEnvironmentVariable('PATH');
  while PathList <> '' do
  begin
    SepPos := Pos(';', PathList);
    if SepPos = 0 then
    begin
      PathDir := PathList;
      PathList := '';
    end
    else
    begin
      PathDir := Copy(PathList, 1, SepPos - 1);
      Delete(PathList, 1, SepPos);
    end;
    PathDir := StringReplace(PathDir, '"', '', [rfReplaceAll]);
    if InDir(PathDir) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function RqDepTargetPath(ADep: TRqDep; const AIncDir, AMainDir: string): string;
var
  BaseDir, RelName: string;
begin
  RelName := StringReplace(ADep.Name, '/', '\', [rfReplaceAll]);
  if ADep.Kind = dpkLib then
    RelName := ADep.FileNameOnly;
  // Путь с диском - туда и копировать: иначе rc.exe / Windows его не найдут
  if ExtractFileDrive(RelName) <> '' then
  begin
    Result := RelName;
    Exit;
  end;
  if (ADep.Target = dptIncDir) and (AIncDir <> '') and (ADep.Kind <> dpkLib) then
    BaseDir := AIncDir
  else
    BaseDir := AMainDir;
  Result := ExpandFileName(IncludeTrailingPathDelimiter(BaseDir) + RelName);
end;

// Первое слово строки (до пробела) и остаток
function SplitWord(const AText: string; var ARest: string): string;
var
  CharIdx: Integer;
  Txt: string;
begin
  Txt := Trim(AText);
  CharIdx := 1;
  while (CharIdx <= Length(Txt)) and not (Txt[CharIdx] in [' ', #9]) do
    Inc(CharIdx);
  Result := Copy(Txt, 1, CharIdx - 1);
  ARest := Trim(Copy(Txt, CharIdx, MaxInt));
end;

// Имя в кавычках или в <> в начале AText ('' - нет)
function QuotedName(const AText: string): string;
var
  Txt: string;
  CloseChar: Char;
  ClosePos: Integer;
begin
  Result := '';
  Txt := Trim(AText);
  if Txt = '' then
    Exit;
  if Txt[1] = '"' then
    CloseChar := '"'
  else if Txt[1] = '<' then
    CloseChar := '>'
  else
    Exit;
  ClosePos := Pos(CloseChar, Copy(Txt, 2, MaxInt));
  if ClosePos > 0 then
    Result := Trim(Copy(Txt, 2, ClosePos - 1));
  Result := StringReplace(Result, '/', '\', [rfReplaceAll]);
end;

{ TRqDepScan }

constructor TRqDepScan.Create;
begin
  inherited Create;
  FItems := TList.Create;
  FScanned := TStringList.Create;
  FDefined := TStringList.Create;
  FDefined.Sorted := True;
  FDefined.Duplicates := dupIgnore;
  FAliases := TStringList.Create;
  FLibCache := TStringList.Create;
end;

destructor TRqDepScan.Destroy;
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to FItems.Count - 1 do
    TObject(FItems[ItemIdx]).Free;
  FItems.Free;
  FScanned.Free;
  FDefined.Free;
  FAliases.Free;
  FLibCache.Free;
  inherited Destroy;
end;

function TRqDepScan.GetItem(AIndex: Integer): TRqDep;
begin
  Result := TRqDep(FItems[AIndex]);
end;

function TRqDepScan.Count: Integer;
begin
  Result := FItems.Count;
end;

function TRqDepScan.MissingCount: Integer;
var
  ItemIdx: Integer;
begin
  Result := 0;
  for ItemIdx := 0 to FItems.Count - 1 do
    if Items[ItemIdx].Missing then
      Inc(Result);
end;

function TRqDepScan.CountOf(AKind: TRqDepKind): Integer;
var
  ItemIdx: Integer;
begin
  Result := 0;
  for ItemIdx := 0 to FItems.Count - 1 do
    if Items[ItemIdx].Kind = AKind then
      Inc(Result);
end;

procedure TRqDepScan.DropNames(ANames: TStrings);
var
  ItemIdx: Integer;
begin
  for ItemIdx := FItems.Count - 1 downto 0 do
    if Items[ItemIdx].Missing and
       (ANames.IndexOf(UpperCase(Items[ItemIdx].Name)) >= 0) then
    begin
      Items[ItemIdx].Free;
      FItems.Delete(ItemIdx);
    end;
end;

// Одно имя одного вида - один раз (первое место подключения)
function TRqDepScan.AddDep(AKind: TRqDepKind; const AName, AFrom: string;
                           ALine: Integer): TRqDep;
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to FItems.Count - 1 do
    if (Items[ItemIdx].Kind = AKind) and
       (CompareText(Items[ItemIdx].Name, AName) = 0) then
    begin
      Result := nil;
      Exit;
    end;
  Result := TRqDep.Create;
  Result.Kind := AKind;
  Result.Name := AName;
  Result.FromFile := AFrom;
  Result.FromLine := ALine;
  if AKind = dpkLib then
    Result.Target := dptMainDir
  else
    Result.Target := dptIncDir;
  FItems.Add(Result);
end;

procedure TRqDepScan.Scan(const AMainBas, AIncDir: string);
begin
  FMainDir := ExtractFilePath(ExpandFileName(AMainBas));
  FIncDir := '';
  if Trim(AIncDir) <> '' then
    FIncDir := IncludeTrailingPathDelimiter(Trim(AIncDir));
  FScanned.Clear;
  FDefined.Clear;
  FAliases.Clear;
  // Из RAPIDQ.INC: $define brem $ifdef, erem $endif, remb, reme
  FAliases.Values['BREM'] := 'IFDEF';
  FAliases.Values['EREM'] := 'ENDIF';
  FAliases.Values['REMB'] := 'IFDEF';
  FAliases.Values['REME'] := 'ENDIF';
  ScanFile(ExpandFileName(AMainBas), 0);
end;

procedure TRqDepScan.ScanFile(const AFile: string; ADepth: Integer);
var
  Lines: TStringList;
  LineIdx, FirstLine, StackTop, LibPos: Integer;
  Code, Blank, PartCode, PartBlank, Word1, Rest, Directive, Arg, Name1,
  Name2, UpCode, Full, LibKey: string;
  // Условная сборка: активен ли блок и его родитель
  CondActive, CondParent: array of Boolean;
  Active: Boolean;

  procedure Push(AOn: Boolean);
  begin
    Inc(StackTop);
    if StackTop >= Length(CondActive) then
    begin
      SetLength(CondActive, StackTop + 16);
      SetLength(CondParent, StackTop + 16);
    end;
    CondParent[StackTop] := Active;
    CondActive[StackTop] := Active and AOn;
    Active := CondActive[StackTop];
  end;

begin
  if ADepth > MaxDepth then
    Exit;
  if FScanned.IndexOf(UpperCase(AFile)) >= 0 then
    Exit;
  FScanned.Add(UpperCase(AFile));
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFile);
    except
      Exit;
    end;
    Active := True;
    StackTop := -1;
    LineIdx := 0;
    while LineIdx < Lines.Count do
    begin
      FirstLine := LineIdx;
      IncSplitLine(Lines[LineIdx], Code, Blank);
      // Продолжение строки "_"
      while (Code <> '') and (Code[Length(Code)] = '_') and
            (LineIdx < Lines.Count - 1) do
      begin
        Inc(LineIdx);
        IncSplitLine(Lines[LineIdx], PartCode, PartBlank);
        Code := Copy(Code, 1, Length(Code) - 1) + ' ' + PartCode;
      end;
      Inc(LineIdx);
      if Code = '' then
        Continue;

      Word1 := UpperCase(SplitWord(Code, Rest));
      Directive := '';
      if (Word1 <> '') and (Word1[1] = '$') then
        Directive := Copy(Word1, 2, MaxInt)
      else if FAliases.IndexOfName(Word1) >= 0 then
        Directive := FAliases.Values[Word1];

      if Directive = 'IFDEF' then
      begin
        Push(FDefined.IndexOf(UpperCase(SplitWord(Rest, Arg))) >= 0);
        Continue;
      end;
      if Directive = 'IFNDEF' then
      begin
        Push(FDefined.IndexOf(UpperCase(SplitWord(Rest, Arg))) < 0);
        Continue;
      end;
      if Directive = 'ELSE' then
      begin
        if StackTop >= 0 then
        begin
          CondActive[StackTop] := CondParent[StackTop] and
                                  not CondActive[StackTop];
          Active := CondActive[StackTop];
        end;
        Continue;
      end;
      if Directive = 'ENDIF' then
      begin
        if StackTop >= 0 then
        begin
          Active := CondParent[StackTop];
          Dec(StackTop);
        end;
        Continue;
      end;
      if not Active then
        Continue;

      if Directive = 'DEFINE' then
      begin
        Name1 := UpperCase(SplitWord(Rest, Arg));
        Name2 := UpperCase(SplitWord(Arg, Arg));
        if (Name2 = '$IFDEF') or (Name2 = '$IFNDEF') or (Name2 = '$ELSE') or
           (Name2 = '$ENDIF') then
          FAliases.Values[Name1] := Copy(Name2, 2, MaxInt)
        else if Name1 <> '' then
          FDefined.Add(Name1);
        Continue;
      end;
      if Directive = 'UNDEF' then
      begin
        Name1 := UpperCase(SplitWord(Rest, Arg));
        if FDefined.IndexOf(Name1) >= 0 then
          FDefined.Delete(FDefined.IndexOf(Name1));
        Continue;
      end;
      if Directive = 'INCLUDE' then
      begin
        Name1 := RqDbgIncludeName(Code);
        if Name1 = '' then
          Continue;
        Full := RqDbgResolveInclude(Name1, FMainDir, FIncDir);
        if Full = '' then
          AddDep(dpkInclude, Name1, AFile, FirstLine + 1)
        else
          ScanFile(ExpandFileName(Full), ADepth + 1);
        Continue;
      end;
      if Directive = 'RESOURCE' then
      begin
        // $RESOURCE Имя AS "файл"
        SplitWord(Rest, Arg);
        if UpperCase(SplitWord(Arg, Arg)) <> 'AS' then
          Continue;
        Name1 := QuotedName(Arg);
        if (Name1 <> '') and
           (RqDbgResolveInclude(Name1, FMainDir, FIncDir) = '') then
          AddDep(dpkResource, Name1, AFile, FirstLine + 1);
        Continue;
      end;
      if Directive <> '' then
        Continue;

      // DECLARE SUB|FUNCTION ... LIB "имя"
      if Word1 = 'DECLARE' then
      begin
        UpCode := UpperCase(Code);
        LibPos := Pos(' LIB ', UpCode);
        if LibPos = 0 then
          LibPos := Pos(' LIB"', UpCode);
        if LibPos = 0 then
          Continue;
        Name1 := QuotedName(Copy(Code, LibPos + 4, MaxInt));
        if Name1 = '' then
          Continue;
        LibKey := UpperCase(Name1);
        if FLibCache.IndexOfName(LibKey) < 0 then
        begin
          if RqLibExists(Name1, FMainDir) then
            FLibCache.Values[LibKey] := '1'
          else
            FLibCache.Values[LibKey] := '0';
        end;
        if FLibCache.Values[LibKey] = '0' then
        begin
          AddDep(dpkLib, Name1, AFile, FirstLine + 1);
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

{ поиск и выбор }

type
  // Приём найденных файлов: раскладывает по недостающим
  TRqDepCollector = class
  public
    Scan: TRqDepScan;
    StageLabel: string;
    Done: TStringList;   // номера уже найденных в папках Include
    // Имена, которые ищет IncFindNamesOnDisk (верхний регистр). DLL и
    // ресурс берутся первой найденной копией - после неё имя отсюда
    // убирается, и подпапки дальше ради него не смотрятся; inc ищется
    // дальше: из копий выбирается совпадающая с эталоном.
    Names: TStringList;
    procedure Found(const AFile: string);
  end;

procedure TRqDepCollector.Found(const AFile: string);
var
  ItemIdx, OtherIdx, NameIdx: Integer;
  Dep: TRqDep;
  StillWanted: Boolean;
begin
  for ItemIdx := 0 to Scan.Count - 1 do
  begin
    Dep := Scan[ItemIdx];
    if not Dep.Missing or (Dep.Candidates.Count >= MaxCandidates) then
      Continue;
    if (Done <> nil) and (Done.IndexOf(IntToStr(ItemIdx)) >= 0) then
      Continue;
    if CompareText(Dep.FileNameOnly, ExtractFileName(AFile)) <> 0 then
      Continue;
    if Dep.Candidates.IndexOf(AFile) >= 0 then
      Continue;
    Dep.Candidates.Add(AFile);
    Dep.Where.Add(StageLabel);
    if (Dep.Kind = dpkInclude) or (Names = nil) then
      Continue;
    // DLL / ресурс: копия есть. Имя - из поиска, если его не ждёт ещё
    // кто-то без копии (inc с тем же именем ищется всегда)
    StillWanted := False;
    for OtherIdx := 0 to Scan.Count - 1 do
      if Scan[OtherIdx].Missing and
         (CompareText(Scan[OtherIdx].FileNameOnly, Dep.FileNameOnly) = 0) and
         ((Scan[OtherIdx].Kind = dpkInclude) or
          (Scan[OtherIdx].Candidates.Count = 0)) then
        StillWanted := True;
    if not StillWanted and Names.Find(UpperCase(Dep.FileNameOnly), NameIdx) then
      Names.Delete(NameIdx);
  end;
end;

function RqDepsFindOnDisk(AScan: TRqDepScan; ARoots: TStrings;
                          AProgress: TIncProgress;
                          AStopAfterInclude: Boolean): Boolean;
var
  Names, Searched, StageList, Found, Done: TStringList;
  Collector: TRqDepCollector;
  ItemIdx, StageIdx, SkipIdx: Integer;
  StageRoot, StageLabel, StageDir, Cand: string;
  Covered: Boolean;
  Dep: TRqDep;

  // Шаг "Include ...": папка inc - как её смотрит rc.exe, без подпапок:
  // имя из $INCLUDE (с путём Object\QINI.inc), потом само имя файла.
  // Нашлось - этот файл дальше не ищется.
  procedure IncludeStage;
  var
    DepIdx: Integer;
  begin
    for DepIdx := 0 to AScan.Count - 1 do
    begin
      Dep := AScan[DepIdx];
      if not Dep.Missing or (Done.IndexOf(IntToStr(DepIdx)) >= 0) then
        Continue;
      Cand := StageDir + StringReplace(Dep.Name, '/', '\', [rfReplaceAll]);
      if (ExtractFileDrive(Dep.Name) <> '') or not FileExists(Cand) then
        Cand := StageDir + Dep.FileNameOnly;
      if not FileExists(Cand) then
        Continue;
      Cand := ExpandFileName(Cand);
      if Dep.Candidates.IndexOf(Cand) < 0 then
      begin
        Dep.Candidates.Add(Cand);
        Dep.Where.Add(StageLabel);
      end;
      Done.Add(IntToStr(DepIdx));
    end;
  end;

begin
  Result := True;
  Names := TStringList.Create;
  Searched := TStringList.Create;
  StageList := TStringList.Create;
  Found := TStringList.Create;
  Done := TStringList.Create;
  Collector := TRqDepCollector.Create;
  try
    Names.Sorted := True;
    Names.Duplicates := dupIgnore;
    for ItemIdx := 0 to AScan.Count - 1 do
      if AScan[ItemIdx].Missing then
      begin
        AScan[ItemIdx].Candidates.Clear;
        AScan[ItemIdx].Where.Clear;
        AScan[ItemIdx].Chosen := -1;
      end;
    Collector.Scan := AScan;
    Searched.Sorted := True;
    Searched.Duplicates := dupIgnore;
    for StageIdx := 0 to ARoots.Count - 1 do
    begin
      StageLabel := Copy(ARoots[StageIdx], 1, Pos('|', ARoots[StageIdx]) - 1);
      StageDir := Copy(ARoots[StageIdx], Pos('|', ARoots[StageIdx]) + 1, MaxInt);
      if (Trim(StageDir) = '') or not DirectoryExists(StageDir) then
        Continue;
      StageDir := IncludeTrailingPathDelimiter(StageDir);
      if CompareText(Copy(StageLabel, 1, 7), 'Include') = 0 then
      begin
        IncludeStage;
        Continue;
      end;

      // В папках Include нашлось - на первый раз хватит
      if AStopAfterInclude and (Done.Count > 0) then
        Break;
      // Остальные шаги - с подпапками, только то, что в папках Include не
      // нашлось
      // DLL и ресурс с найденной копией - тоже нет (берётся первая копия)
      Names.Clear;
      for ItemIdx := 0 to AScan.Count - 1 do
        if AScan[ItemIdx].Missing and (Done.IndexOf(IntToStr(ItemIdx)) < 0) and
           ((AScan[ItemIdx].Kind = dpkInclude) or
            (AScan[ItemIdx].Candidates.Count = 0)) then
          Names.Add(UpperCase(AScan[ItemIdx].FileNameOnly));
      if Names.Count = 0 then
        Break;
      StageRoot := UpperCase(StageDir);
      Covered := False;
      for SkipIdx := 0 to Searched.Count - 1 do
        if Copy(StageRoot, 1, Length(Searched[SkipIdx])) = Searched[SkipIdx] then
          Covered := True;
      if Covered then
        Continue;
      Collector.StageLabel := StageLabel;
      Collector.Done := Done;
      Collector.Names := Names;
      StageList.Clear;
      StageList.Add(StageDir);
      Found.Clear;
      Result := IncFindNamesOnDisk(Names, StageList, Found, AProgress, Searched,
                                   Collector.Found);
      Searched.Add(StageRoot);
      if not Result then
        Break;
    end;
  finally
    Collector.Free;
    Done.Free;
    Found.Free;
    StageList.Free;
    Searched.Free;
    Names.Free;
  end;
end;

procedure RqDepsChoose(AScan: TRqDepScan; ARef: TIncRefIndex);
var
  ItemIdx, CandIdx: Integer;
  Dep: TRqDep;
  Info: TIncFileInfo;
  Tail: string;
begin
  for ItemIdx := 0 to AScan.Count - 1 do
  begin
    Dep := AScan[ItemIdx];
    Dep.Chosen := -1;
    Dep.ChosenNote := '';
    if not Dep.Missing or (Dep.Candidates.Count = 0) then
      Continue;
    // Нашёлся в папке Include UnIde / User - его и брать: дальше не искали
    if CompareText(Copy(Dep.Where[0], 1, 7), 'Include') = 0 then
    begin
      Dep.Chosen := 0;
      Dep.ChosenNote := 'есть в папке ' + Dep.Where[0];
      Continue;
    end;
    if (Dep.Kind = dpkInclude) and (ARef <> nil) then
      for CandIdx := 0 to Dep.Candidates.Count - 1 do
      begin
        Info := TIncFileInfo.Create(Dep.Candidates[CandIdx]);
        try
          IncCheckFile(Info, ARef);
          if Info.Status = isSame then
          begin
            Dep.Chosen := CandIdx;
            Dep.ChosenNote := 'совпадает с эталоном';
            Break;
          end;
        finally
          Info.Free;
        end;
      end;
    // Путь в $INCLUDE (Object\QINI.inc) - сначала копия из такой же подпапки
    if (Dep.Chosen < 0) and HasPath(Dep.Name) then
    begin
      Tail := '\' + UpperCase(StringReplace(Dep.Name, '/', '\', [rfReplaceAll]));
      for CandIdx := 0 to Dep.Candidates.Count - 1 do
        if Copy(UpperCase(Dep.Candidates[CandIdx]),
                Length(Dep.Candidates[CandIdx]) - Length(Tail) + 1,
                Length(Tail)) = Tail then
        begin
          Dep.Chosen := CandIdx;
          Dep.ChosenNote := 'из папки с тем же путём, что в $INCLUDE';
          if Dep.Kind = dpkInclude then
            Dep.ChosenNote := Dep.ChosenNote + ' (с эталоном не совпадает)';
          Break;
        end;
    end;
    if Dep.Chosen < 0 then
    begin
      Dep.Chosen := 0;
      if Dep.Kind = dpkInclude then
        Dep.ChosenNote := 'с эталоном не совпадает ни одна копия - проверьте'
      else
        Dep.ChosenNote := 'первая по порядку поиска';
    end;
  end;
end;

end.
