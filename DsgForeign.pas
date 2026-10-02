unit DsgForeign;

// ---------------------------------------------------------------------------
//  Сторонние компоненты для палитры конструктора
//
//  Список берётся из установленной Delphi 7, ничего не настраивается
//  вручную:
//    - HKCU\Software\Borland\Delphi\7.0\Known Packages - установленные
//      design-пакеты. Пакеты самой Delphi (папка Bin) пропускаются: их
//      компоненты вкомпилированы в редактор (DsgClasses).
//    - Ресурс PACKAGEINFO каждого design-пакета и runtime-пакетов, которые
//      он требует: какие модули в каком пакете. Пакеты открываются как
//      файлы данных - их код не выполняется.
//    - HKCU\Software\Borland\Delphi\7.0\Palette - раскладка палитры Delphi:
//      страница и её компоненты "Модуль.Класс" по порядку. Компонент
//      сторонний, если его модуль лежит в одном из сторонних пакетов, а
//      класса в редакторе нет.
//  Значок компонента - ресурс BITMAP с именем класса в design-пакете
//  (как у компонентов Delphi в dcl*.bpl); пакеты для значков - IconLibs.
//
//  Класс компонента (ForeignClass) - из runtime-пакета, загруженного без
//  выполнения кода (BplRtti): его предки, свойства и события. Пакет
//  загружается при первом обращении к любому его классу и остаётся в
//  памяти до выхода. Классы чужие: проверки is с классами редактора к ним
//  не применяются, только имена (BplInheritsFromName) и RTTI.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes, Registry;

type
  // Сторонний компонент на странице палитры
  TDsgForeignComp = class
  public
    PageName: string;    // страница палитры Delphi
    CompUnit: string;    // модуль, как в реестре (CPort, RVEdit)
    CompClass: string;   // класс: TComPort
    RuntimePkg: string;  // пакет с модулем - полный путь
    PkgDescr: string;    // описание пакета из Known Packages
  end;

  TDsgForeignList = class
  private
    FComps: TList;       // TDsgForeignComp, страница за страницей
    FPages: TStringList; // страницы по порядку палитры Delphi
    FIconLibs: TStringList; // design-пакеты: в них значки
    FLog: TStringList;   // что найдено и что пропущено - для лога
    // Загруженные runtime-пакеты: путь прописными, в Objects - HMODULE
    // (0 - не загрузился; причина - в FModErrors под тем же номером)
    FModules: TStringList;
    FModErrors: TStringList;
    // Классы загруженных пакетов: имя -> TClass в Objects
    FClassMap: TStringList;
    function GetComp(AIndex: Integer): TDsgForeignComp;
    function LoadCache(const ACacheFile, ASig: string): Boolean;
    procedure SaveCache(const ACacheFile, ASig: string);
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    // Прочитать из реестра и пакетов. ADelphiRoot - папка установки Delphi
    // (без Bin), '' - взять из реестра. ACacheFile - файл кэша: если
    // пакеты, их даты, раскладка палитры и exe редактора те же, список
    // берётся из него без чтения пакетов; '' - без кэша.
    procedure Scan(const ADelphiRoot, ACacheFile: string);
    // Номер компонента с классом AClass; -1 - нет на палитре
    function IndexOfClass(const AClass: string): Integer;
    // Класс компонента из его runtime-пакета; nil - пакет не загрузился
    // или класса в нём нет, причина - в AError
    function ForeignClass(AIndex: Integer; var AError: string): TClass;
    property Count: Integer read GetCount;
    property Comps[AIndex: Integer]: TDsgForeignComp read GetComp; default;
    property Pages: TStringList read FPages;
    property IconLibs: TStringList read FIconLibs;
    property Log: TStringList read FLog;
  end;

// Папка установки Delphi 7 по реестру (RootDir), без слэша в конце
function DsgDelphiRootDir: string;

implementation

uses
  BplRtti;

const
  RegDelphi = 'Software\Borland\Delphi\7.0';

function DsgDelphiRootDir: string;
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('SOFTWARE\Borland\Delphi\7.0') then
      Result := Reg.ReadString('RootDir');
    if Result = '' then
    begin
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKeyReadOnly(RegDelphi) then
        Result := Reg.ReadString('RootDir');
    end;
  finally
    Reg.Free;
  end;
  Result := ExcludeTrailingPathDelimiter(Result);
end;

// Папка без слэша, в коротком написании и прописными: пути в Known Packages
// бывают и длинными, и короткими (C:\PROGRA~2\...)
function SameDirKey(const ADir: string): string;
var
  ShortDir: string;
begin
  Result := ExcludeTrailingPathDelimiter(ADir);
  if Result = '' then
    Exit;
  ShortDir := ExtractShortPathName(Result);
  if ShortDir <> '' then
    Result := ShortDir;
  Result := UpperCase(Result);
end;

// Где Windows найдёт пакет AName: сначала папка AFirstDir, потом PATH и
// системные папки (как при загрузке зависимостей)
function FindPackage(const AName, AFirstDir: string): string;
var
  Buffer: array[0..MAX_PATH] of Char;
  FilePart: PChar;
  FileName: string;
begin
  Result := '';
  FileName := AName;
  if ExtractFileExt(FileName) = '' then
    FileName := FileName + '.bpl';
  if (AFirstDir <> '') and
     FileExists(IncludeTrailingPathDelimiter(AFirstDir) + FileName) then
  begin
    Result := IncludeTrailingPathDelimiter(AFirstDir) + FileName;
    Exit;
  end;
  if SearchPath(nil, PChar(FileName), nil, MAX_PATH, Buffer, FilePart) > 0 then
    Result := Buffer;
end;

// Строка страницы палитры "Модуль.Класс;Модуль.Класс;" - по элементам
procedure SplitItems(const AText: string; AItems: TStrings);
var
  Rest: string;
  SemiPos: Integer;
begin
  AItems.Clear;
  Rest := AText;
  while Rest <> '' do
  begin
    SemiPos := Pos(';', Rest);
    if SemiPos = 0 then
      SemiPos := Length(Rest) + 1;
    if SemiPos > 1 then
      AItems.Add(Copy(Rest, 1, SemiPos - 1));
    Delete(Rest, 1, SemiPos);
  end;
end;

{ TDsgForeignList }

constructor TDsgForeignList.Create;
begin
  inherited Create;
  FComps := TList.Create;
  FPages := TStringList.Create;
  FIconLibs := TStringList.Create;
  FLog := TStringList.Create;
  FModules := TStringList.Create;
  FModErrors := TStringList.Create;
  FClassMap := TStringList.Create;
  FClassMap.Sorted := True;
  FClassMap.Duplicates := dupIgnore;
end;

destructor TDsgForeignList.Destroy;
begin
  Clear;
  FComps.Free;
  FPages.Free;
  FIconLibs.Free;
  FLog.Free;
  // Пакеты не выгружаются: их код не выполнялся, а на их классы могут
  // ссылаться списки редактора до самого выхода
  FModules.Free;
  FModErrors.Free;
  FClassMap.Free;
  inherited;
end;

procedure TDsgForeignList.Clear;
var
  CompIdx: Integer;
begin
  for CompIdx := 0 to FComps.Count - 1 do
    TObject(FComps[CompIdx]).Free;
  FComps.Clear;
  FPages.Clear;
  FIconLibs.Clear;
  FLog.Clear;
end;

function TDsgForeignList.GetComp(AIndex: Integer): TDsgForeignComp;
begin
  Result := TDsgForeignComp(FComps[AIndex]);
end;

function TDsgForeignList.IndexOfClass(const AClass: string): Integer;
var
  CompIdx: Integer;
begin
  Result := -1;
  for CompIdx := 0 to FComps.Count - 1 do
    if CompareText(TDsgForeignComp(FComps[CompIdx]).CompClass, AClass) = 0 then
    begin
      Result := CompIdx;
      Exit;
    end;
end;

function TDsgForeignList.ForeignClass(AIndex: Integer;
                                      var AError: string): TClass;
var
  Comp: TDsgForeignComp;
  ModKey, LoadError: string;
  ModIdx, ClsIdx: Integer;
  Module: HMODULE;
  Found: TStringList;
begin
  Result := nil;
  AError := '';
  if (AIndex < 0) or (AIndex >= FComps.Count) then
  begin
    AError := 'компонента нет в списке палитры';
    Exit;
  end;
  Comp := TDsgForeignComp(FComps[AIndex]);
  ModKey := UpperCase(Comp.RuntimePkg);
  ModIdx := FModules.IndexOf(ModKey);
  if ModIdx < 0 then
  begin
    Module := BplLoadForRtti(Comp.RuntimePkg, LoadError);
    ModIdx := FModules.AddObject(ModKey, TObject(Module));
    FModErrors.Add(LoadError);
    if Module <> 0 then
    begin
      Found := TStringList.Create;
      try
        BplListClasses(Module, Found, nil);
        for ClsIdx := 0 to Found.Count - 1 do
          FClassMap.AddObject(Found.Names[ClsIdx], Found.Objects[ClsIdx]);
      finally
        Found.Free;
      end;
    end;
  end;
  if HMODULE(FModules.Objects[ModIdx]) = 0 then
  begin
    AError := ExtractFileName(Comp.RuntimePkg) + ' не загрузился: ' +
              FModErrors[ModIdx];
    Exit;
  end;
  ClsIdx := FClassMap.IndexOf(Comp.CompClass);
  if ClsIdx < 0 then
  begin
    AError := 'в ' + ExtractFileName(Comp.RuntimePkg) + ' нет класса ' +
              Comp.CompClass;
    Exit;
  end;
  Result := TClass(Pointer(FClassMap.Objects[ClsIdx]));
end;

function TDsgForeignList.GetCount: Integer;
begin
  Result := FComps.Count;
end;

// Подпись установки: пакеты Known Packages (путь, описание, дата файла) и
// раскладка палитры. Совпала с записанной в кэше - список из кэша. Дата exe
// в подпись не входит: редактор пересобирается часто, и кэш сбрасывался бы
// на каждой сборке. Классы, которые в exe вкомпилированы, отбрасываются при
// чтении кэша (LoadCache) - так же, как при чтении пакетов.
function ScanSignature(APkgPaths, APkgDescrs, APageNames,
                       APageTexts: TStrings): string;
var
  Hash: Cardinal;
  ItemIdx: Integer;

  procedure AddText(const AText: string);
  var
    CharIdx: Integer;
  begin
    for CharIdx := 1 to Length(AText) do
      Hash := (Hash xor Ord(AText[CharIdx])) * 16777619;
    Hash := (Hash xor 10) * 16777619;
  end;

begin
  Hash := 2166136261;
  for ItemIdx := 0 to APkgPaths.Count - 1 do
  begin
    AddText(APkgPaths[ItemIdx]);
    AddText(APkgDescrs[ItemIdx]);
    AddText(IntToStr(FileAge(APkgPaths[ItemIdx])));
  end;
  for ItemIdx := 0 to APageNames.Count - 1 do
  begin
    AddText(APageNames[ItemIdx]);
    AddText(APageTexts[ItemIdx]);
  end;
  Result := IntToHex(Hash, 8) + '-' + IntToStr(APkgPaths.Count) + '-' +
            IntToStr(APageNames.Count);
end;

// Поле строки кэша "a|b|c": номер AIndex с нуля
function CacheField(const ALine: string; AIndex: Integer): string;
var
  Rest: string;
  BarPos, FieldIdx: Integer;
begin
  Result := '';
  Rest := ALine;
  for FieldIdx := 0 to AIndex do
  begin
    BarPos := Pos('|', Rest);
    if BarPos = 0 then
      BarPos := Length(Rest) + 1;
    Result := Copy(Rest, 1, BarPos - 1);
    Delete(Rest, 1, BarPos);
  end;
end;

function TDsgForeignList.LoadCache(const ACacheFile, ASig: string): Boolean;
var
  Lines: TStringList;
  LineIdx: Integer;
  Line: string;
  Comp: TDsgForeignComp;
begin
  Result := False;
  if (ACacheFile = '') or not FileExists(ACacheFile) then
    Exit;
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(ACacheFile);
    except
      Exit;
    end;
    if (Lines.Count = 0) or (Lines[0] <> 'sig=' + ASig) then
      Exit;
    for LineIdx := 1 to Lines.Count - 1 do
    begin
      Line := Lines[LineIdx];
      if Copy(Line, 1, 5) = 'page=' then
        FPages.Add(Copy(Line, 6, MaxInt))
      else if Copy(Line, 1, 4) = 'lib=' then
        FIconLibs.Add(Copy(Line, 5, MaxInt))
      else if Copy(Line, 1, 4) = 'log=' then
        FLog.Add(Copy(Line, 5, MaxInt))
      else if Copy(Line, 1, 5) = 'comp=' then
      begin
        Line := Copy(Line, 6, MaxInt);
        Comp := TDsgForeignComp.Create;
        Comp.PageName := CacheField(Line, 0);
        Comp.CompUnit := CacheField(Line, 1);
        Comp.CompClass := CacheField(Line, 2);
        Comp.RuntimePkg := CacheField(Line, 3);
        Comp.PkgDescr := CacheField(Line, 4);
        // Класс теперь вкомпилирован в редактор - не сторонний
        if GetClass(Comp.CompClass) <> nil then
          Comp.Free
        else
          FComps.Add(Comp);
      end;
    end;
    Result := True;
  finally
    Lines.Free;
  end;
end;

procedure TDsgForeignList.SaveCache(const ACacheFile, ASig: string);
var
  Lines: TStringList;
  ItemIdx: Integer;
  Comp: TDsgForeignComp;
begin
  if ACacheFile = '' then
    Exit;
  Lines := TStringList.Create;
  try
    Lines.Add('sig=' + ASig);
    for ItemIdx := 0 to FPages.Count - 1 do
      Lines.Add('page=' + FPages[ItemIdx]);
    for ItemIdx := 0 to FIconLibs.Count - 1 do
      Lines.Add('lib=' + FIconLibs[ItemIdx]);
    for ItemIdx := 0 to FLog.Count - 1 do
      Lines.Add('log=' + FLog[ItemIdx]);
    for ItemIdx := 0 to FComps.Count - 1 do
    begin
      Comp := TDsgForeignComp(FComps[ItemIdx]);
      Lines.Add('comp=' + Comp.PageName + '|' + Comp.CompUnit + '|' +
                Comp.CompClass + '|' + Comp.RuntimePkg + '|' +
                StringReplace(Comp.PkgDescr, '|', '/', [rfReplaceAll]));
    end;
    try
      ForceDirectories(ExtractFilePath(ACacheFile));
      Lines.SaveToFile(ACacheFile);
    except
      // кэш не записался - в следующий раз список прочитается заново
    end;
  finally
    Lines.Free;
  end;
end;

procedure TDsgForeignList.Scan(const ADelphiRoot, ACacheFile: string);
var
  Reg: TRegistry;
  RegNames, PkgPaths, PkgDescrs, PageNames, PageTexts: TStringList;
  Units, Requires, Items: TStringList;
  // модуль (прописными) -> пакет; Objects - номер описания в Descrs
  UnitPkg: TStringList;
  Descrs, Seen: TStringList;
  RootDir, BinKey, PkgPath, ReqPath, Item, Sig: string;
  UnitNm, ClassNm, PageText: string;
  PkgIdx, ReqIdx, PageIdx, ItemIdx, DotPos, Found, DescrIdx: Integer;
  Comp: TDsgForeignComp;
  PageHasComps: Boolean;
  StartTick: Cardinal;

  // Модули пакета APath - в UnitPkg; False - пакет не открылся
  function AddPackageUnits(const APath: string; ADescrIdx: Integer): Boolean;
  var
    InfoModule: HMODULE;
    InfoIdx: Integer;
  begin
    Result := False;
    InfoModule := BplLoadAsData(APath);
    if InfoModule = 0 then
      Exit;
    try
      BplPackageInfo(InfoModule, Units, Requires);
    finally
      FreeLibrary(InfoModule);
    end;
    for InfoIdx := 0 to Units.Count - 1 do
      if UnitPkg.IndexOfName(UpperCase(Units[InfoIdx])) < 0 then
        UnitPkg.AddObject(UpperCase(Units[InfoIdx]) + '=' + APath,
                          TObject(ADescrIdx));
    Result := True;
  end;

begin
  Clear;
  StartTick := GetTickCount;
  RootDir := ADelphiRoot;
  if RootDir = '' then
    RootDir := DsgDelphiRootDir;
  RootDir := ExcludeTrailingPathDelimiter(RootDir);
  BinKey := SameDirKey(RootDir + '\Bin');

  Reg := TRegistry.Create(KEY_READ);
  RegNames := TStringList.Create;
  PkgPaths := TStringList.Create;
  PkgDescrs := TStringList.Create;
  PageNames := TStringList.Create;
  PageTexts := TStringList.Create;
  Units := TStringList.Create;
  Requires := TStringList.Create;
  Items := TStringList.Create;
  UnitPkg := TStringList.Create;
  Descrs := TStringList.Create;
  Seen := TStringList.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;

    // Реестр: установленные пакеты (кроме пакетов самой Delphi) и раскладка
    // палитры - быстро, без чтения пакетов
    if not Reg.OpenKeyReadOnly(RegDelphi + '\Known Packages') then
    begin
      FLog.Add('в реестре нет ' + RegDelphi + '\Known Packages');
      Exit;
    end;
    Reg.GetValueNames(RegNames);
    for PkgIdx := 0 to RegNames.Count - 1 do
    begin
      PkgPath := StringReplace(RegNames[PkgIdx], '$(DELPHI)', RootDir,
                               [rfReplaceAll, rfIgnoreCase]);
      if SameDirKey(ExtractFilePath(PkgPath)) = BinKey then
        Continue;
      PkgPaths.Add(PkgPath);
      PkgDescrs.Add(Reg.ReadString(RegNames[PkgIdx]));
    end;
    Reg.CloseKey;
    if not Reg.OpenKeyReadOnly(RegDelphi + '\Palette') then
    begin
      FLog.Add('в реестре нет ' + RegDelphi + '\Palette');
      Exit;
    end;
    Reg.GetValueNames(RegNames);
    for PageIdx := 0 to RegNames.Count - 1 do
    begin
      try
        PageText := Reg.ReadString(RegNames[PageIdx]);
      except
        Continue;
      end;
      PageNames.Add(RegNames[PageIdx]);
      PageTexts.Add(PageText);
    end;
    Reg.CloseKey;

    Sig := ScanSignature(PkgPaths, PkgDescrs, PageNames, PageTexts);
    if LoadCache(ACacheFile, Sig) then
    begin
      FLog.Add('из кэша, ' + IntToStr(GetTickCount - StartTick) + ' мс');
      Exit;
    end;

    // 1. Модули сторонних пакетов: design-пакет и требуемые им runtime-
    //    пакеты не из Bin
    for PkgIdx := 0 to PkgPaths.Count - 1 do
    begin
      PkgPath := PkgPaths[PkgIdx];
      if not FileExists(PkgPath) then
      begin
        FLog.Add('пакета нет на диске: ' + PkgPath);
        Continue;
      end;
      DescrIdx := Descrs.Add(PkgDescrs[PkgIdx]);
      if not AddPackageUnits(PkgPath, DescrIdx) then
      begin
        FLog.Add('пакет не открылся: ' + PkgPath);
        Continue;
      end;
      FIconLibs.Add(PkgPath);
      Items.Assign(Requires);
      for ReqIdx := 0 to Items.Count - 1 do
      begin
        // Пакеты Delphi (rtl70, vcl70, designide70 ...) не ищем: их модули
        // не нужны, а поиск по PATH - самое долгое здесь
        if FileExists(RootDir + '\Bin\' + Items[ReqIdx]) then
          Continue;
        ReqPath := FindPackage(Items[ReqIdx], ExtractFilePath(PkgPath));
        if (ReqPath = '') or
           (SameDirKey(ExtractFilePath(ReqPath)) = BinKey) then
          Continue;
        if Seen.IndexOf(UpperCase(ReqPath)) >= 0 then
          Continue;
        Seen.Add(UpperCase(ReqPath));
        AddPackageUnits(ReqPath, DescrIdx);
      end;
    end;

    // 2. Раскладка палитры: компоненты из этих модулей
    for PageIdx := 0 to PageNames.Count - 1 do
    begin
      SplitItems(PageTexts[PageIdx], Items);
      PageHasComps := False;
      for ItemIdx := 0 to Items.Count - 1 do
      begin
        Item := Trim(Items[ItemIdx]);
        DotPos := Pos('.', Item);
        if DotPos <= 1 then
          Continue;                       // ".Frames" и пустые
        UnitNm := Copy(Item, 1, DotPos - 1);
        ClassNm := Copy(Item, DotPos + 1, MaxInt);
        Found := UnitPkg.IndexOfName(UpperCase(UnitNm));
        if Found < 0 then
          Continue;                       // модуль не из стороннего пакета
        if GetClass(ClassNm) <> nil then
          Continue;                       // класс вкомпилирован в редактор
        Comp := TDsgForeignComp.Create;
        Comp.PageName := PageNames[PageIdx];
        Comp.CompUnit := UnitNm;
        Comp.CompClass := ClassNm;
        Comp.RuntimePkg := UnitPkg.ValueFromIndex[Found];
        Comp.PkgDescr := Descrs[Integer(UnitPkg.Objects[Found])];
        FComps.Add(Comp);
        PageHasComps := True;
      end;
      if PageHasComps then
        FPages.Add(PageNames[PageIdx]);
    end;
    FLog.Add('пакетов ' + IntToStr(Descrs.Count) + ', модулей ' +
             IntToStr(UnitPkg.Count) + ', страниц ' + IntToStr(FPages.Count) +
             ', компонентов ' + IntToStr(FComps.Count));
    for PageIdx := 0 to FPages.Count - 1 do
      FLog.Add('страница ' + FPages[PageIdx]);
    SaveCache(ACacheFile, Sig);
    FLog.Add('прочитано из пакетов, ' + IntToStr(GetTickCount - StartTick) +
             ' мс; записано в кэш');
  finally
    Seen.Free;
    Descrs.Free;
    UnitPkg.Free;
    Items.Free;
    Requires.Free;
    Units.Free;
    PageTexts.Free;
    PageNames.Free;
    PkgDescrs.Free;
    PkgPaths.Free;
    RegNames.Free;
    Reg.Free;
  end;
end;

end.
