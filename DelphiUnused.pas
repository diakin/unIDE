unit DelphiUnused;

// Файлы папки проекта Delphi, которые не участвуют в сборке .dpr.
// От .dpr по цепочке uses (и contains у .dpk) собираются модули проекта,
// их .dfm, файлы из {$I}/{$INCLUDE} и {$R}/{$RESOURCE}, файлы самого
// проекта (.res, .dof, .cfg, .dsk, .todo с именем .dpr). Все остальные
// файлы папки проекта и её подпапок - неиспользуемые, в том числе ini,
// данные, dll, exe, картинки и документы: нужное для работы программы
// пользователь возвращает сам. Не трогаются только .git и файлы git в
// корне (.gitignore, .gitattributes).
// Директивы {$IFDEF} не разбираются: модуль из любой ветки считается
// нужным - так файлов уходит меньше, но ни один нужный для сборки не уходит.

interface

uses
  SysUtils, Classes;

// AUnused - пути относительно папки .dpr. ASkipDirs - имена подпапок
// первого уровня, которые не просматриваются (через ';', например
// 'unused;.git'). Результат - число файлов в AUnused
function DelphiUnusedFiles(const ADpr, ASkipDirs: string;
  AUnused: TStrings): Integer;

// Используемые файлы (пути относительно папки .dpr) - для журнала и проверки
function DelphiUsedFiles(const ADpr, ASkipDirs: string;
  AUsed: TStrings): Integer;

implementation

type
  TTokKind = (tkIdent, tkString, tkSymbol);

  TUnusedScan = class
  private
    FRoot: string;                // папка .dpr с разделителем на конце
    FSkipDirs: TStringList;
    FAllFiles: TStringList;       // ключ - путь в нижнем регистре, Objects - нет
    FAllReal: TStringList;        // те же индексы: путь как на диске
    FByName: TStringList;         // имя файла (нижний регистр) = индекс в FAllFiles
    FUsed: TStringList;           // пути (нижний регистр)
    FQueue: TStringList;          // пути как на диске, ещё не разобраны
    FSearchDirs: TStringList;     // относительные папки поиска модулей
    FDprUnits: TStringList;       // имя модуля = путь из 'in'
    procedure ScanTree(const ARelDir: string);
    function IndexOfRel(const ARel: string): Integer;
    function NormRel(const ABaseRelDir, APath: string): string;
    procedure MarkUsed(const ARel: string);
    procedure MarkWithSiblings(const ARel: string; const AExts: array of string);
    function FindUnit(const AUnit, AFromRelDir: string): string;
    procedure ParseSource(const ARel: string);
    procedure ReadDofSearchPath(const ADofRel: string);
  public
    constructor Create(const ADpr, ASkipDirs: string);
    destructor Destroy; override;
    procedure Run(const ADprRel: string);
    function IsMovable(const ARel: string): Boolean;
    property AllReal: TStringList read FAllReal;
    property Used: TStringList read FUsed;
  end;

function SameDirSep(const Str: string): string;
var
  Idx: Integer;
begin
  Result := Str;
  for Idx := 1 to Length(Result) do
    if (Result[Idx] = '/') or (Result[Idx] = '\') then
      Result[Idx] := PathDelim;
end;

constructor TUnusedScan.Create(const ADpr, ASkipDirs: string);
var
  Rest, Part: string;
  SepPos: Integer;
begin
  inherited Create;
  FRoot := IncludeTrailingPathDelimiter(ExtractFilePath(ExpandFileName(ADpr)));
  FSkipDirs := TStringList.Create;
  Rest := ASkipDirs;
  while Rest <> '' do
  begin
    SepPos := Pos(';', Rest);
    if SepPos = 0 then
      SepPos := Length(Rest) + 1;
    Part := Trim(Copy(Rest, 1, SepPos - 1));
    Delete(Rest, 1, SepPos);
    if Part <> '' then
      FSkipDirs.Add(AnsiLowerCase(Part));
  end;
  FAllFiles := TStringList.Create;
  FAllReal := TStringList.Create;
  FByName := TStringList.Create;
  FUsed := TStringList.Create;
  FUsed.Sorted := True;
  FUsed.Duplicates := dupIgnore;
  FQueue := TStringList.Create;
  FSearchDirs := TStringList.Create;
  FDprUnits := TStringList.Create;
end;

destructor TUnusedScan.Destroy;
begin
  FSkipDirs.Free;
  FAllFiles.Free;
  FAllReal.Free;
  FByName.Free;
  FUsed.Free;
  FQueue.Free;
  FSearchDirs.Free;
  FDprUnits.Free;
  inherited Destroy;
end;

procedure TUnusedScan.ScanTree(const ARelDir: string);
var
  SearchRec: TSearchRec;
  RelPath: string;
begin
  if FindFirst(FRoot + ARelDir + '*', faAnyFile, SearchRec) <> 0 then
    Exit;
  try
    repeat
      if (SearchRec.Name = '.') or (SearchRec.Name = '..') then
        Continue;
      RelPath := ARelDir + SearchRec.Name;
      if (SearchRec.Attr and faDirectory) <> 0 then
      begin
        if (ARelDir = '') and
           (FSkipDirs.IndexOf(AnsiLowerCase(SearchRec.Name)) >= 0) then
          Continue;
        if AnsiLowerCase(SearchRec.Name) = '.git' then
          Continue;
        ScanTree(RelPath + PathDelim);
      end
      else
      begin
        FAllReal.Add(RelPath);
        FAllFiles.Add(AnsiLowerCase(RelPath));
        FByName.Add(AnsiLowerCase(SearchRec.Name) + '=' +
          IntToStr(FAllReal.Count - 1));
      end;
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
end;

function TUnusedScan.IndexOfRel(const ARel: string): Integer;
begin
  if ARel = '' then
    Result := -1
  else
    Result := FAllFiles.IndexOf(AnsiLowerCase(ARel));
end;

// APath (относительный от ABaseRelDir или абсолютный) -> путь от корня
// проекта без '.' и '..'; вне папки проекта - ''
function TUnusedScan.NormRel(const ABaseRelDir, APath: string): string;
var
  FullPath, RootLower: string;
  Parts: TStringList;
  Rest, Part: string;
  SepPos, PartIdx: Integer;
begin
  Result := '';
  FullPath := SameDirSep(Trim(APath));
  if FullPath = '' then
    Exit;
  if (Pos(':', FullPath) > 0) or (FullPath[1] = PathDelim) then
  begin
    // абсолютный путь: только внутри папки проекта
    RootLower := AnsiLowerCase(FRoot);
    if Pos(RootLower, AnsiLowerCase(FullPath)) <> 1 then
      Exit;
    FullPath := Copy(FullPath, Length(FRoot) + 1, MaxInt);
  end
  else
    FullPath := ABaseRelDir + FullPath;
  Parts := TStringList.Create;
  try
    Rest := FullPath;
    while Rest <> '' do
    begin
      SepPos := Pos(PathDelim, Rest);
      if SepPos = 0 then
        SepPos := Length(Rest) + 1;
      Part := Copy(Rest, 1, SepPos - 1);
      Delete(Rest, 1, SepPos);
      if (Part = '') or (Part = '.') then
        Continue;
      if Part = '..' then
      begin
        if Parts.Count = 0 then
          Exit; // выше папки проекта
        Parts.Delete(Parts.Count - 1);
      end
      else
        Parts.Add(Part);
    end;
    for PartIdx := 0 to Parts.Count - 1 do
    begin
      if PartIdx > 0 then
        Result := Result + PathDelim;
      Result := Result + Parts[PartIdx];
    end;
  finally
    Parts.Free;
  end;
end;

procedure TUnusedScan.MarkUsed(const ARel: string);
var
  FileIdx: Integer;
  Ext: string;
begin
  FileIdx := IndexOfRel(ARel);
  if FileIdx < 0 then
    Exit;
  if FUsed.IndexOf(FAllFiles[FileIdx]) >= 0 then
    Exit;
  FUsed.Add(FAllFiles[FileIdx]);
  Ext := AnsiLowerCase(ExtractFileExt(ARel));
  if (Ext = '.pas') or (Ext = '.dpr') or (Ext = '.dpk') or (Ext = '.inc') or
     (Ext = '.pp') then
    FQueue.Add(FAllReal[FileIdx]);
end;

procedure TUnusedScan.MarkWithSiblings(const ARel: string;
  const AExts: array of string);
var
  ExtIdx: Integer;
begin
  MarkUsed(ARel);
  for ExtIdx := Low(AExts) to High(AExts) do
    MarkUsed(ChangeFileExt(ARel, AExts[ExtIdx]));
end;

// Модуль AUnit: 'in' из .dpr, папка ссылающегося файла, папка .dpr,
// SearchPath из .dof, иначе любой одноимённый файл в дереве проекта
function TUnusedScan.FindUnit(const AUnit, AFromRelDir: string): string;
var
  FileName, Cand: string;
  DirIdx, NameIdx: Integer;
begin
  Result := '';
  Cand := FDprUnits.Values[AnsiLowerCase(AUnit)];
  if (Cand <> '') and (IndexOfRel(Cand) >= 0) then
  begin
    Result := Cand;
    Exit;
  end;
  FileName := AUnit + '.pas';
  Cand := NormRel(AFromRelDir, FileName);
  if IndexOfRel(Cand) >= 0 then
  begin
    Result := Cand;
    Exit;
  end;
  if IndexOfRel(FileName) >= 0 then
  begin
    Result := FileName;
    Exit;
  end;
  for DirIdx := 0 to FSearchDirs.Count - 1 do
  begin
    Cand := NormRel(FSearchDirs[DirIdx], FileName);
    if IndexOfRel(Cand) >= 0 then
    begin
      Result := Cand;
      Exit;
    end;
  end;
  NameIdx := FByName.IndexOfName(AnsiLowerCase(FileName));
  if NameIdx >= 0 then
  begin
    Result := FAllReal[StrToInt(FByName.ValueFromIndex[NameIdx])];
    Exit;
  end;
  // только .dcu (модуль без исходника)
  NameIdx := FByName.IndexOfName(AnsiLowerCase(AUnit + '.dcu'));
  if NameIdx >= 0 then
    Result := FAllReal[StrToInt(FByName.ValueFromIndex[NameIdx])];
end;

procedure TUnusedScan.ReadDofSearchPath(const ADofRel: string);
var
  Lines: TStringList;
  LineIdx, SepPos: Integer;
  Line, Rest, Part, InSection: string;
begin
  if IndexOfRel(ADofRel) < 0 then
    Exit;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FRoot + ADofRel);
    InSection := '';
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[LineIdx]);
      if (Line <> '') and (Line[1] = '[') then
      begin
        InSection := AnsiLowerCase(Line);
        Continue;
      end;
      if (InSection = '[directories]') and
         (AnsiLowerCase(Copy(Line, 1, 11)) = 'searchpath=') then
      begin
        Rest := Copy(Line, 12, MaxInt);
        while Rest <> '' do
        begin
          SepPos := Pos(';', Rest);
          if SepPos = 0 then
            SepPos := Length(Rest) + 1;
          Part := Trim(Copy(Rest, 1, SepPos - 1));
          Delete(Rest, 1, SepPos);
          if (Part <> '') and (Pos('$(', Part) = 0) then
          begin
            Part := NormRel('', Part);
            if Part <> '' then
              FSearchDirs.Add(IncludeTrailingPathDelimiter(Part))
            else
              FSearchDirs.Add('');
          end;
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

// Разбор .pas/.dpr/.dpk/.inc: uses, contains, {$I}, {$R}
procedure TUnusedScan.ParseSource(const ARel: string);
var
  Src: string;
  SrcLen, Pos0, TokStart: Integer;
  RelDir: string;
  Toks: TStringList;     // текст токена, Objects - вид
  TokIdx: Integer;
  UnitName, InPath, Found: string;
  IsDpr: Boolean;

  procedure AddTok(const AText: string; AKind: TTokKind);
  begin
    Toks.AddObject(AText, TObject(Ord(AKind)));
  end;

  function TokKind(AIdx: Integer): TTokKind;
  begin
    Result := TTokKind(Integer(Toks.Objects[AIdx]));
  end;

  // Имена из директивы: {$I имя}, {$R имя.res имя.rc}
  procedure HandleDirective(const ABody: string);
  var
    Body, Word, Args, Arg: string;
    WordEnd, ArgPos: Integer;
  begin
    Body := Trim(ABody);
    WordEnd := 1;
    while (WordEnd <= Length(Body)) and (Body[WordEnd] in ['A'..'Z', 'a'..'z', '_']) do
      Inc(WordEnd);
    Word := UpperCase(Copy(Body, 1, WordEnd - 1));
    Args := Trim(Copy(Body, WordEnd, MaxInt));
    if not ((Word = 'I') or (Word = 'INCLUDE') or (Word = 'R') or
       (Word = 'RESOURCE')) then
      Exit;
    // {$I+} {$I-} {$R+} {$R-} - переключатели, не файлы
    if (Args = '') or (Args[1] in ['+', '-']) then
      Exit;
    while Args <> '' do
    begin
      if Args[1] = '''' then
      begin
        ArgPos := 2;
        while (ArgPos <= Length(Args)) and (Args[ArgPos] <> '''') do
          Inc(ArgPos);
        Arg := Copy(Args, 2, ArgPos - 2);
        Delete(Args, 1, ArgPos);
      end
      else
      begin
        ArgPos := 1;
        while (ArgPos <= Length(Args)) and (Args[ArgPos] <> ' ') do
          Inc(ArgPos);
        Arg := Copy(Args, 1, ArgPos - 1);
        Delete(Args, 1, ArgPos);
      end;
      Args := Trim(Args);
      if Arg = '' then
        Continue;
      if Arg[1] = '*' then
        Arg := ChangeFileExt(ExtractFileName(ARel), '') + Copy(Arg, 2, MaxInt);
      if (Word = 'R') or (Word = 'RESOURCE') then
      begin
        if ExtractFileExt(Arg) = '' then
          Arg := Arg + '.res';
        // .res и одноимённый .rc, из которого он собирается
        MarkWithSiblings(NormRel(RelDir, Arg), ['.rc']);
      end
      else
      begin
        if ExtractFileExt(Arg) = '' then
          Arg := Arg + '.pas';
        Found := NormRel(RelDir, Arg);
        if IndexOfRel(Found) < 0 then
          Found := NormRel('', Arg);
        MarkUsed(Found);
      end;
    end;
  end;

begin
  Toks := TStringList.Create;
  try
    with TStringList.Create do
    try
      LoadFromFile(FRoot + ARel);
      Src := Text;
    finally
      Free;
    end;
    RelDir := ExtractFilePath(ARel);
    IsDpr := (AnsiLowerCase(ExtractFileExt(ARel)) = '.dpr') or
      (AnsiLowerCase(ExtractFileExt(ARel)) = '.dpk');
    SrcLen := Length(Src);
    Pos0 := 1;
    while Pos0 <= SrcLen do
    begin
      case Src[Pos0] of
        '{':
          begin
            TokStart := Pos0;
            while (Pos0 <= SrcLen) and (Src[Pos0] <> '}') do
              Inc(Pos0);
            if (TokStart < SrcLen) and (Src[TokStart + 1] = '$') then
              HandleDirective(Copy(Src, TokStart + 2, Pos0 - TokStart - 2));
            Inc(Pos0);
          end;
        '(':
          if (Pos0 < SrcLen) and (Src[Pos0 + 1] = '*') then
          begin
            TokStart := Pos0;
            Inc(Pos0, 2);
            while (Pos0 < SrcLen) and not ((Src[Pos0] = '*') and (Src[Pos0 + 1] = ')')) do
              Inc(Pos0);
            if (Src[TokStart + 2] = '$') then
              HandleDirective(Copy(Src, TokStart + 3, Pos0 - TokStart - 3));
            Inc(Pos0, 2);
          end
          else
          begin
            AddTok('(', tkSymbol);
            Inc(Pos0);
          end;
        '/':
          if (Pos0 < SrcLen) and (Src[Pos0 + 1] = '/') then
          begin
            while (Pos0 <= SrcLen) and not (Src[Pos0] in [#10, #13]) do
              Inc(Pos0);
          end
          else
          begin
            AddTok('/', tkSymbol);
            Inc(Pos0);
          end;
        '''':
          begin
            TokStart := Pos0 + 1;
            Inc(Pos0);
            while (Pos0 <= SrcLen) and (Src[Pos0] <> '''') and
                  not (Src[Pos0] in [#10, #13]) do
              Inc(Pos0);
            AddTok(Copy(Src, TokStart, Pos0 - TokStart), tkString);
            Inc(Pos0);
          end;
        'A'..'Z', 'a'..'z', '_':
          begin
            TokStart := Pos0;
            while (Pos0 <= SrcLen) and
                  (Src[Pos0] in ['A'..'Z', 'a'..'z', '_', '0'..'9', '.']) do
              Inc(Pos0);
            AddTok(Copy(Src, TokStart, Pos0 - TokStart), tkIdent);
          end;
        ',', ';':
          begin
            AddTok(Src[Pos0], tkSymbol);
            Inc(Pos0);
          end;
      else
        Inc(Pos0);
      end;
    end;

    // uses / contains: имя [in 'путь'] {, ...} ;
    TokIdx := 0;
    while TokIdx < Toks.Count do
    begin
      if (TokKind(TokIdx) = tkIdent) and
         ((CompareText(Toks[TokIdx], 'uses') = 0) or
          (IsDpr and (CompareText(Toks[TokIdx], 'contains') = 0))) then
      begin
        Inc(TokIdx);
        while (TokIdx < Toks.Count) and (Toks[TokIdx] <> ';') do
        begin
          if TokKind(TokIdx) = tkIdent then
          begin
            UnitName := Toks[TokIdx];
            InPath := '';
            if (TokIdx + 2 < Toks.Count) and
               (CompareText(Toks[TokIdx + 1], 'in') = 0) and
               (TokKind(TokIdx + 2) = tkString) then
            begin
              InPath := NormRel(RelDir, Toks[TokIdx + 2]);
              Inc(TokIdx, 2);
              if IsDpr and (InPath <> '') then
                FDprUnits.Values[AnsiLowerCase(UnitName)] := InPath;
            end;
            if InPath <> '' then
              Found := InPath
            else
              Found := FindUnit(UnitName, RelDir);
            if Found <> '' then
              MarkWithSiblings(Found, ['.dfm', '.xfm', '.dcu']);
          end;
          Inc(TokIdx);
        end;
      end;
      Inc(TokIdx);
    end;
  finally
    Toks.Free;
  end;
end;

procedure TUnusedScan.Run(const ADprRel: string);
begin
  ScanTree('');
  FAllFiles.Sorted := False; // индексы FAllFiles и FAllReal совпадают
  ReadDofSearchPath(ChangeFileExt(ADprRel, '.dof'));
  // файлы самого проекта
  MarkWithSiblings(ADprRel, ['.res', '.dof', '.cfg', '.dsk', '.todo',
    '.dproj', '.bdsproj', '.mes']);
  while FQueue.Count > 0 do
  begin
    ParseSource(FQueue[0]);
    FQueue.Delete(0);
  end;
end;

// Файл можно переносить: всё, кроме файлов git в корне проекта
function TUnusedScan.IsMovable(const ARel: string): Boolean;
var
  NameLower: string;
begin
  NameLower := AnsiLowerCase(ARel);
  Result := not ((NameLower = '.gitignore') or (NameLower = '.gitattributes') or
    (NameLower = '.gitmodules'));
end;

function RelOfDpr(const ADpr: string): string;
begin
  Result := ExtractFileName(ADpr);
end;

function DelphiUnusedFiles(const ADpr, ASkipDirs: string;
  AUnused: TStrings): Integer;
var
  Scan: TUnusedScan;
  FileIdx: Integer;
begin
  AUnused.Clear;
  Scan := TUnusedScan.Create(ADpr, ASkipDirs);
  try
    Scan.Run(RelOfDpr(ADpr));
    for FileIdx := 0 to Scan.AllReal.Count - 1 do
      if Scan.IsMovable(Scan.AllReal[FileIdx]) and
         (Scan.Used.IndexOf(AnsiLowerCase(Scan.AllReal[FileIdx])) < 0) then
        AUnused.Add(Scan.AllReal[FileIdx]);
  finally
    Scan.Free;
  end;
  Result := AUnused.Count;
end;

function DelphiUsedFiles(const ADpr, ASkipDirs: string;
  AUsed: TStrings): Integer;
var
  Scan: TUnusedScan;
  FileIdx: Integer;
begin
  AUsed.Clear;
  Scan := TUnusedScan.Create(ADpr, ASkipDirs);
  try
    Scan.Run(RelOfDpr(ADpr));
    for FileIdx := 0 to Scan.AllReal.Count - 1 do
      if Scan.Used.IndexOf(AnsiLowerCase(Scan.AllReal[FileIdx])) >= 0 then
        AUsed.Add(Scan.AllReal[FileIdx]);
  finally
    Scan.Free;
  end;
  Result := AUsed.Count;
end;

end.
