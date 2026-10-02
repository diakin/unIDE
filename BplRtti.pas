unit BplRtti;

// ---------------------------------------------------------------------------
//  Описание компонентов из пакета Delphi (.bpl) без выполнения его кода
//
//  Пакет загружается обычным LoadLibraryEx, а не LoadPackage: Windows
//  связывает его с пакетами, от которых он зависит (rtl70.bpl, vcl70.bpl),
//  но секции initialization модулей не выполняются - их запускает только
//  LoadPackage (InitializePackage). Объекты не создаются. Из пакета читаются
//  данные: таблицы классов (VMT) и описание published-свойств (RTTI) -
//  то же, по чему строит список свойств инспектор Delphi.
//
//  Классы ищутся среди экспортов пакета: пакет экспортирует все символы
//  интерфейсной части модулей. Экспорт - таблица класса, если по адресу
//  vmtSelfPtr лежит сам этот адрес; или описание типа класса (tkClass).
//
//  Классы пакета - чужие: TComponent в нём - из rtl70.bpl, не тот, что в
//  программе. Поэтому проверки is / InheritsFrom с классами программы
//  не годятся - родство проверяется по именам (BplInheritsFromName).
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes, TypInfo;

// Пакет - для чтения классов (с зависимостями, без initialization).
// 0 - не загрузился, причина в AError.
function BplLoadForRtti(const APath: string; var AError: string): HMODULE;

// Пакет - как файл данных: только ресурсы (PACKAGEINFO, значки)
function BplLoadAsData(const APath: string): HMODULE;

// Классы пакета: строки "Имя класса=имя экспорта", в Objects - TClass.
// AExportSample - первые экспорты пакета, если классов не нашлось (для
// разбора, как пакет называет символы).
procedure BplListClasses(AModule: HMODULE; AList, AExportSample: TStrings);

// Цепочка предков: "TComPort < TCustomComPort < TComponent < ..."
function BplClassChain(AClass: TClass): string;

// AClass или его предок называется AName
function BplInheritsFromName(AClass: TClass; const AName: string): Boolean;

// Published-свойства и события класса - строками в AOut
procedure BplDumpProps(AClass: TClass; AOut: TStrings);

// Сведения пакета (ресурс PACKAGEINFO): модули и требуемые пакеты
procedure BplPackageInfo(AModule: HMODULE; AUnits, ARequires: TStrings);

implementation

const
  BplLoadAsDataFile = $00000002;     // LOAD_LIBRARY_AS_DATAFILE
  BplAlteredSearch = $00000008;      // LOAD_WITH_ALTERED_SEARCH_PATH
  BplNoDefault = Integer($80000000); // у свойства нет default

type
  TBplExportDir = packed record
    Characteristics: DWORD;
    TimeDateStamp: DWORD;
    MajorVersion: Word;
    MinorVersion: Word;
    NameRva: DWORD;
    Base: DWORD;
    NumberOfFunctions: DWORD;
    NumberOfNames: DWORD;
    AddressOfFunctions: DWORD;
    AddressOfNames: DWORD;
    AddressOfNameOrdinals: DWORD;
  end;
  PBplExportDir = ^TBplExportDir;

  TBplDWords = array[0..65535] of DWORD;
  PBplDWords = ^TBplDWords;
  TBplWords = array[0..65535] of Word;
  PBplWords = ^TBplWords;

function BplLoadForRtti(const APath: string; var AError: string): HMODULE;
var
  OldMode: UINT;
begin
  AError := '';
  // Не найденная зависимость - без окна Windows, ошибкой
  OldMode := SetErrorMode(SEM_FAILCRITICALERRORS or SEM_NOOPENFILEERRORBOX);
  try
    Result := LoadLibraryEx(PChar(APath), 0, BplAlteredSearch);
  finally
    SetErrorMode(OldMode);
  end;
  if Result = 0 then
    AError := SysErrorMessage(GetLastError);
end;

function BplLoadAsData(const APath: string): HMODULE;
begin
  Result := LoadLibraryEx(PChar(APath), 0, BplLoadAsDataFile);
end;

// По адресу можно читать ASize байт
function BplReadable(AAddr: Pointer; ASize: Integer): Boolean;
begin
  Result := (Cardinal(AAddr) >= $10000) and
            not IsBadReadPtr(AAddr, ASize);
end;

// Адрес - таблица класса (VMT): по vmtSelfPtr лежит он сам, имя класса
// читается, размер экземпляра не нулевой
function BplIsVmt(AAddr: Pointer): Boolean;
var
  SelfSlot, NameSlot: PPointer;
  SizeSlot: PInteger;
  NamePtr: PShortString;
begin
  Result := False;
  if Cardinal(AAddr) < $10000 then
    Exit;
  SelfSlot := PPointer(Integer(AAddr) + vmtSelfPtr);
  if not BplReadable(SelfSlot, SizeOf(Pointer)) or (SelfSlot^ <> AAddr) then
    Exit;
  NameSlot := PPointer(Integer(AAddr) + vmtClassName);
  if not BplReadable(NameSlot, SizeOf(Pointer)) then
    Exit;
  NamePtr := NameSlot^;
  if not BplReadable(NamePtr, 1) or (Length(NamePtr^) = 0) or
     not BplReadable(NamePtr, Length(NamePtr^) + 1) then
    Exit;
  SizeSlot := PInteger(Integer(AAddr) + vmtInstanceSize);
  if not BplReadable(SizeSlot, SizeOf(Integer)) or (SizeSlot^ <= 0) then
    Exit;
  Result := True;
end;

// Адрес - описание типа класса (tkClass) - его класс; иначе nil
function BplClassOfTypeInfo(AAddr: Pointer): TClass;
var
  TypeRec: PTypeInfo;
  DataRec: PTypeData;
begin
  Result := nil;
  if not BplReadable(AAddr, 2) then
    Exit;
  TypeRec := AAddr;
  if TypeRec^.Kind <> tkClass then
    Exit;
  if not BplReadable(AAddr, Length(TypeRec^.Name) + 2 + SizeOf(Pointer)) then
    Exit;
  DataRec := GetTypeData(TypeRec);
  if not BplReadable(DataRec, SizeOf(Pointer)) then
    Exit;
  if BplIsVmt(Pointer(DataRec^.ClassType)) and
     (TClass(DataRec^.ClassType).ClassInfo = TypeRec) then
    Result := DataRec^.ClassType;
end;

procedure BplListClasses(AModule: HMODULE; AList, AExportSample: TStrings);
var
  DosHdr: PImageDosHeader;
  NtHdr: PImageNtHeaders;
  ExpDir: PBplExportDir;
  ExpStart, ExpEnd: Cardinal;
  NameRvas, FuncRvas: PBplDWords;
  Ordinals: PBplWords;
  Idx: Integer;
  FuncRva: Cardinal;
  ExpName: string;
  Addr: Pointer;
  FoundClass: TClass;
begin
  AList.Clear;
  if AExportSample <> nil then
    AExportSample.Clear;
  if AModule = 0 then
    Exit;
  DosHdr := PImageDosHeader(AModule);
  if DosHdr^.e_magic <> IMAGE_DOS_SIGNATURE then
    Exit;
  NtHdr := PImageNtHeaders(Cardinal(AModule) + Cardinal(DosHdr^._lfanew));
  if NtHdr^.Signature <> IMAGE_NT_SIGNATURE then
    Exit;
  ExpStart := NtHdr^.OptionalHeader.DataDirectory[
                IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
  ExpEnd := ExpStart + NtHdr^.OptionalHeader.DataDirectory[
                         IMAGE_DIRECTORY_ENTRY_EXPORT].Size;
  if ExpStart = 0 then
    Exit;
  ExpDir := PBplExportDir(Cardinal(AModule) + ExpStart);
  NameRvas := PBplDWords(Cardinal(AModule) + ExpDir^.AddressOfNames);
  FuncRvas := PBplDWords(Cardinal(AModule) + ExpDir^.AddressOfFunctions);
  Ordinals := PBplWords(Cardinal(AModule) + ExpDir^.AddressOfNameOrdinals);

  for Idx := 0 to Integer(ExpDir^.NumberOfNames) - 1 do
  begin
    ExpName := PChar(Cardinal(AModule) + NameRvas^[Idx]);
    if (AExportSample <> nil) and (AExportSample.Count < 40) then
      AExportSample.Add(ExpName);
    FuncRva := FuncRvas^[Ordinals^[Idx]];
    // Пересылка в другой модуль - не адрес
    if (FuncRva >= ExpStart) and (FuncRva < ExpEnd) then
      Continue;
    Addr := Pointer(Cardinal(AModule) + FuncRva);
    FoundClass := nil;
    try
      if BplIsVmt(Addr) then
        FoundClass := TClass(Addr)
      else
        FoundClass := BplClassOfTypeInfo(Addr);
    except
      FoundClass := nil;
    end;
    if (FoundClass <> nil) and
       (AList.IndexOfName(FoundClass.ClassName) < 0) then
      AList.AddObject(FoundClass.ClassName + '=' + ExpName,
                      TObject(Pointer(FoundClass)));
  end;
end;

function BplClassChain(AClass: TClass): string;
var
  Cur: TClass;
begin
  Result := '';
  Cur := AClass;
  while Cur <> nil do
  begin
    if Result <> '' then
      Result := Result + ' < ';
    Result := Result + Cur.ClassName;
    Cur := Cur.ClassParent;
  end;
end;

function BplInheritsFromName(AClass: TClass; const AName: string): Boolean;
var
  Cur: TClass;
begin
  Result := False;
  Cur := AClass;
  while Cur <> nil do
  begin
    if CompareText(Cur.ClassName, AName) = 0 then
    begin
      Result := True;
      Exit;
    end;
    Cur := Cur.ClassParent;
  end;
end;

// Значения перечисления: "a, b, c" (длинные - с сокращением)
function BplEnumValues(AType: PTypeInfo): string;
var
  DataRec: PTypeData;
  ValIdx: Integer;
begin
  Result := '';
  DataRec := GetTypeData(AType);
  for ValIdx := DataRec^.MinValue to DataRec^.MaxValue do
  begin
    if ValIdx - DataRec^.MinValue >= 40 then
    begin
      Result := Result + ', ...';
      Exit;
    end;
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + GetEnumName(AType, ValIdx);
  end;
end;

// Заголовок события: "procedure(Sender: TObject; var Key: Char) of object"
function BplMethodSignature(AType: PTypeInfo): string;
var
  DataRec: PTypeData;
  Cursor: PChar;
  ParamIdx: Integer;
  Flags: TParamFlags;
  ParamName, TypeName, Params: string;
begin
  DataRec := GetTypeData(AType);
  Cursor := @DataRec^.ParamList;
  Params := '';
  for ParamIdx := 0 to DataRec^.ParamCount - 1 do
  begin
    Move(Cursor^, Flags, SizeOf(Flags));
    Inc(Cursor, SizeOf(Flags));
    ParamName := PShortString(Cursor)^;
    Inc(Cursor, Length(ParamName) + 1);
    TypeName := PShortString(Cursor)^;
    Inc(Cursor, Length(TypeName) + 1);
    if Params <> '' then
      Params := Params + '; ';
    if pfVar in Flags then
      Params := Params + 'var '
    else if pfConst in Flags then
      Params := Params + 'const '
    else if pfOut in Flags then
      Params := Params + 'out ';
    Params := Params + ParamName;
    // Нетипизированный параметр (const Buffer) - без типа
    if TypeName <> '' then
    begin
      Params := Params + ': ';
      if pfArray in Flags then
        Params := Params + 'array of ';
      Params := Params + TypeName;
    end;
  end;
  if DataRec^.MethodKind = mkFunction then
    Result := 'function(' + Params + '): ' + PShortString(Cursor)^ +
              ' of object'
  else
    Result := 'procedure(' + Params + ') of object';
end;

procedure BplDumpProps(AClass: TClass; AOut: TStrings);
var
  ClsTypeInfo: PTypeInfo;
  PropCount, PropIdx: Integer;
  PropList: PPropList;
  PropRec: PPropInfo;
  PropType: PTypeInfo;
  Line, KindName: string;
  Events: TStringList;
begin
  ClsTypeInfo := AClass.ClassInfo;
  if ClsTypeInfo = nil then
  begin
    AOut.Add('    (у класса нет RTTI)');
    Exit;
  end;
  PropCount := GetTypeData(ClsTypeInfo)^.PropCount;
  if PropCount = 0 then
  begin
    AOut.Add('    (published-свойств нет)');
    Exit;
  end;
  Events := TStringList.Create;
  GetMem(PropList, PropCount * SizeOf(Pointer));
  try
    PropCount := GetPropList(ClsTypeInfo, tkAny, PropList);
    AOut.Add('    свойства:');
    for PropIdx := 0 to PropCount - 1 do
    begin
      PropRec := PropList^[PropIdx];
      PropType := PropRec^.PropType^;
      if PropType^.Kind = tkMethod then
      begin
        Events.Add('      ' + PropRec^.Name + ': ' + PropType^.Name + ' = ' +
                   BplMethodSignature(PropType));
        Continue;
      end;
      KindName := GetEnumName(TypeInfo(TTypeKind), Ord(PropType^.Kind));
      Line := '      ' + PropRec^.Name + ': ' + PropType^.Name +
              ' [' + KindName + ']';
      if PropRec^.SetProc = nil then
        Line := Line + ' только чтение';
      if (PropRec^.Default <> BplNoDefault) and
         (PropType^.Kind in [tkInteger, tkChar, tkEnumeration, tkSet,
                             tkWChar]) then
        Line := Line + ' default ' + IntToStr(PropRec^.Default);
      case PropType^.Kind of
        tkEnumeration:
          Line := Line + ' (' + BplEnumValues(PropType) + ')';
        tkSet:
          Line := Line + ' (set of ' +
                  BplEnumValues(GetTypeData(PropType)^.CompType^) + ')';
        tkClass:
          Line := Line + ' -> ' +
                  BplClassChain(GetTypeData(PropType)^.ClassType);
      end;
      AOut.Add(Line);
    end;
    if Events.Count > 0 then
    begin
      AOut.Add('    события:');
      AOut.AddStrings(Events);
    end;
  finally
    FreeMem(PropList);
    Events.Free;
  end;
end;

type
  TBplInfoLists = record
    Units: TStrings;
    Requires: TStrings;
  end;
  PBplInfoLists = ^TBplInfoLists;

procedure BplInfoProc(const AName: string; ANameType: TNameType;
                      AFlags: Byte; AParam: Pointer);
begin
  case ANameType of
    ntContainsUnit:
      if PBplInfoLists(AParam)^.Units <> nil then
        PBplInfoLists(AParam)^.Units.Add(AName);
    ntRequiresPackage:
      if PBplInfoLists(AParam)^.Requires <> nil then
        PBplInfoLists(AParam)^.Requires.Add(AName);
  end;
end;

procedure BplPackageInfo(AModule: HMODULE; AUnits, ARequires: TStrings);
var
  Lists: TBplInfoLists;
  InfoFlags: Integer;
begin
  if AUnits <> nil then
    AUnits.Clear;
  if ARequires <> nil then
    ARequires.Clear;
  if (AModule = 0) or
     (FindResource(AModule, 'PACKAGEINFO', RT_RCDATA) = 0) then
    Exit;
  Lists.Units := AUnits;
  Lists.Requires := ARequires;
  InfoFlags := 0;
  GetPackageInfo(AModule, @Lists, InfoFlags, BplInfoProc);
end;

end.
