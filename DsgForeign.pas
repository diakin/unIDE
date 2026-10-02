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
    function GetComp(AIndex: Integer): TDsgForeignComp;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    // Прочитать из реестра и пакетов. ADelphiRoot - папка установки Delphi
    // (без Bin), '' - взять из реестра.
    procedure Scan(const ADelphiRoot: string);
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
end;

destructor TDsgForeignList.Destroy;
begin
  Clear;
  FComps.Free;
  FPages.Free;
  FIconLibs.Free;
  FLog.Free;
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

function TDsgForeignList.GetCount: Integer;
begin
  Result := FComps.Count;
end;

procedure TDsgForeignList.Scan(const ADelphiRoot: string);
var
  Reg: TRegistry;
  PkgNames, PageNames, Units, Requires, Items: TStringList;
  // модуль (прописными) -> пакет; Objects - номер описания в Descrs
  UnitPkg: TStringList;
  Descrs, Seen: TStringList;
  RootDir, BinKey, PkgPath, ReqPath, Descr, PageText, Item: string;
  UnitNm, ClassNm: string;
  PkgIdx, ReqIdx, UnitIdx, PageIdx, ItemIdx, DotPos, Found, DescrIdx: Integer;
  DataModule: HMODULE;
  Comp: TDsgForeignComp;
  PageHasComps: Boolean;

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
  RootDir := ADelphiRoot;
  if RootDir = '' then
    RootDir := DsgDelphiRootDir;
  RootDir := ExcludeTrailingPathDelimiter(RootDir);
  BinKey := SameDirKey(RootDir + '\Bin');

  Reg := TRegistry.Create(KEY_READ);
  PkgNames := TStringList.Create;
  PageNames := TStringList.Create;
  Units := TStringList.Create;
  Requires := TStringList.Create;
  Items := TStringList.Create;
  UnitPkg := TStringList.Create;
  Descrs := TStringList.Create;
  Seen := TStringList.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;

    // 1. Сторонние пакеты и их модули
    if not Reg.OpenKeyReadOnly(RegDelphi + '\Known Packages') then
    begin
      FLog.Add('в реестре нет ' + RegDelphi + '\Known Packages');
      Exit;
    end;
    Reg.GetValueNames(PkgNames);
    for PkgIdx := 0 to PkgNames.Count - 1 do
    begin
      PkgPath := StringReplace(PkgNames[PkgIdx], '$(DELPHI)', RootDir,
                               [rfReplaceAll, rfIgnoreCase]);
      if SameDirKey(ExtractFilePath(PkgPath)) = BinKey then
        Continue;                         // пакет самой Delphi
      Descr := Reg.ReadString(PkgNames[PkgIdx]);
      if not FileExists(PkgPath) then
      begin
        FLog.Add('пакета нет на диске: ' + PkgPath);
        Continue;
      end;
      DescrIdx := Descrs.Add(Descr);
      if not AddPackageUnits(PkgPath, DescrIdx) then
      begin
        FLog.Add('пакет не открылся: ' + PkgPath);
        Continue;
      end;
      FIconLibs.Add(PkgPath);
      // Требуемые runtime-пакеты не из Bin - их модули тоже
      Items.Assign(Requires);
      for ReqIdx := 0 to Items.Count - 1 do
      begin
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
    Reg.CloseKey;

    // 2. Раскладка палитры: компоненты из этих модулей
    if not Reg.OpenKeyReadOnly(RegDelphi + '\Palette') then
    begin
      FLog.Add('в реестре нет ' + RegDelphi + '\Palette');
      Exit;
    end;
    Reg.GetValueNames(PageNames);
    for PageIdx := 0 to PageNames.Count - 1 do
    begin
      try
        PageText := Reg.ReadString(PageNames[PageIdx]);
      except
        Continue;
      end;
      SplitItems(PageText, Items);
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
    for UnitIdx := 0 to FPages.Count - 1 do
      FLog.Add('страница ' + FPages[UnitIdx]);
  finally
    Seen.Free;
    Descrs.Free;
    UnitPkg.Free;
    Items.Free;
    Requires.Free;
    Units.Free;
    PageNames.Free;
    PkgNames.Free;
    Reg.Free;
  end;
end;

end.
