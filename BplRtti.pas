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
//  программе. Поэтому класс пакета - не TClass, а адрес его таблицы
//  (TBplClass), и проверки is / InheritsFrom не применяются - родство
//  проверяется по именам (BplInheritsFromName).
//
//  Таблицы класса, RTTI и ресурс PACKAGEINFO читаются по раскладке
//  Delphi 7 (32 бита) своими функциями, без модуля TypInfo и
//  SysUtils.GetPackageInfo: раскладка записей у компилятора, которым
//  собран редактор (например FPC), другая, а пакеты - от Delphi 7.
//  Все чтения - с проверкой, что память доступна.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes;

type
  // Класс из пакета: адрес его таблицы (VMT Delphi 7); nil - нет класса
  TBplClass = Pointer;

// Пакет - для чтения классов (с зависимостями, без initialization).
// 0 - не загрузился, причина в AError.
function BplLoadForRtti(const APath: string; var AError: string): HMODULE;

// Пакет - как файл данных: только ресурсы (PACKAGEINFO, значки)
function BplLoadAsData(const APath: string): HMODULE;

// Классы пакета: строки "Имя класса=имя экспорта", в Objects - TBplClass.
// AExportSample - первые экспорты пакета, если классов не нашлось (для
// разбора, как пакет называет символы).
procedure BplListClasses(AModule: HMODULE; AList, AExportSample: TStrings);

// Имя класса; '' - не читается
function BplClassName(AClass: TBplClass): string;

// Предок класса; nil - его нет (TObject)
function BplClassParent(AClass: TBplClass): TBplClass;

// Цепочка предков: "TComPort < TCustomComPort < TComponent < ..."
function BplClassChain(AClass: TBplClass): string;

// AClass или его предок называется AName
function BplInheritsFromName(AClass: TBplClass; const AName: string): Boolean;

// У класса (с предками) есть published-свойство или событие AProp
// (как GetPropInfo(ClassInfo, AProp) <> nil)
function BplHasPublished(AClass: TBplClass; const AProp: string): Boolean;

// Published-свойства и события класса - строками в AOut
procedure BplDumpProps(AClass: TBplClass; AOut: TStrings);

// Сведения пакета (ресурс PACKAGEINFO): модули и требуемые пакеты
procedure BplPackageInfo(AModule: HMODULE; AUnits, ARequires: TStrings);

implementation

type
  // Адрес как число: в Delphi 7 - 32 бита
  {$IFDEF FPC}
  TBplAddr = PtrUInt;
  {$ELSE}
  TBplAddr = Cardinal;
  {$ENDIF}

const
  BplLoadAsDataFile = $00000002;     // LOAD_LIBRARY_AS_DATAFILE
  BplAlteredSearch = $00000008;      // LOAD_WITH_ALTERED_SEARCH_PATH
  BplNoDefault = Integer($80000000); // у свойства нет default
  BplPtrSize = 4;                    // указатель в записях Delphi 7

  // Поля таблицы класса Delphi 7: на сколько байт они до её адреса
  // (vmtSelfPtr = -76 и т. д.)
  BplVmtSelfPtrBack = 76;
  BplVmtTypeInfoBack = 60;
  BplVmtClassNameBack = 44;
  BplVmtInstanceSizeBack = 40;
  BplVmtParentBack = 36;

  // TTypeKind Delphi 7
  BplTkInteger = 1;
  BplTkChar = 2;
  BplTkEnumeration = 3;
  BplTkSet = 6;
  BplTkClass = 7;
  BplTkMethod = 8;
  BplTkWChar = 9;
  BplTkLast = 17;
  BplKindNames: array[0..BplTkLast] of string = (
    'tkUnknown', 'tkInteger', 'tkChar', 'tkEnumeration', 'tkFloat',
    'tkString', 'tkSet', 'tkClass', 'tkMethod', 'tkWChar', 'tkLString',
    'tkWString', 'tkVariant', 'tkArray', 'tkRecord', 'tkInterface',
    'tkInt64', 'tkDynArray');

  // TMethodKind: mkFunction
  BplMkFunction = 1;
  // TParamFlags: биты pfVar, pfConst, pfArray, pfOut
  BplPfVar = $01;
  BplPfConst = $02;
  BplPfArray = $04;
  BplPfOut = $20;

  // Запись свойства (TPropInfo): PropType, GetProc, SetProc, StoredProc,
  // Index, Default (по 4 байта), NameIndex (2), Name (ShortString)
  BplPropSetProcOfs = 8;
  BplPropDefaultOfs = 20;
  BplPropNameIndexOfs = 24;
  BplPropNameOfs = 26;

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

  TBplAddrs = array[0..65535] of TBplAddr;
  PBplAddrs = ^TBplAddrs;

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

// ---------------------------------------------------------------------------
//  Чтение памяти пакета с проверкой
// ---------------------------------------------------------------------------

// По адресу можно читать ASize байт
function BplReadable(AAddr: TBplAddr; ASize: Integer): Boolean;
begin
  Result := (AAddr >= $10000) and
            not IsBadReadPtr(Pointer(AAddr), ASize);
end;

function BplByteAt(AAddr: TBplAddr): Byte;
begin
  Result := 0;
  if BplReadable(AAddr, 1) then
    Result := PByte(Pointer(AAddr))^;
end;

function BplWordAt(AAddr: TBplAddr): Word;
begin
  Result := 0;
  if BplReadable(AAddr, 2) then
    Result := PWord(Pointer(AAddr))^;
end;

function BplIntAt(AAddr: TBplAddr): Integer;
begin
  Result := 0;
  if BplReadable(AAddr, 4) then
    Result := PInteger(Pointer(AAddr))^;
end;

// Указатель из записи Delphi 7 (4 байта); 0 - не читается
function BplPtrAt(AAddr: TBplAddr): TBplAddr;
begin
  Result := 0;
  if BplReadable(AAddr, BplPtrSize) then
    Result := PCardinal(Pointer(AAddr))^;
end;

// ShortString по адресу; '' - не читается
function BplShortAt(AAddr: TBplAddr): string;
var
  StrLen: Integer;
begin
  Result := '';
  if not BplReadable(AAddr, 1) then
    Exit;
  StrLen := PByte(Pointer(AAddr))^;
  if (StrLen = 0) or not BplReadable(AAddr, StrLen + 1) then
    Exit;
  SetLength(Result, StrLen);
  Move(Pointer(AAddr + 1)^, Result[1], StrLen);
end;

// Адрес за ShortString по адресу AAddr
function BplAfterShort(AAddr: TBplAddr): TBplAddr;
begin
  Result := AAddr + 1 + BplByteAt(AAddr);
end;

// Указатель на указатель (PPTypeInfo) - адрес; 0 - нет
function BplDeref2(AAddr: TBplAddr): TBplAddr;
begin
  Result := BplPtrAt(AAddr);
  if Result <> 0 then
    Result := BplPtrAt(Result);
end;

// ---------------------------------------------------------------------------
//  Описание типа (TTypeInfo): Kind (1 байт), Name (ShortString), за ним -
//  данные типа (TTypeData)
// ---------------------------------------------------------------------------

function BplTypeKind(AType: TBplAddr): Integer;
begin
  Result := BplByteAt(AType);
end;

function BplTypeName(AType: TBplAddr): string;
begin
  Result := BplShortAt(AType + 1);
end;

function BplTypeData(AType: TBplAddr): TBplAddr;
begin
  Result := BplAfterShort(AType + 1);
end;

function BplKindName(AKind: Integer): string;
begin
  if (AKind >= 0) and (AKind <= BplTkLast) then
    Result := BplKindNames[AKind]
  else
    Result := 'tk' + IntToStr(AKind);
end;

// ---------------------------------------------------------------------------
//  Таблица класса
// ---------------------------------------------------------------------------

// Адрес - таблица класса (VMT): по vmtSelfPtr лежит он сам, имя класса
// читается, размер экземпляра не нулевой
function BplIsVmt(AAddr: TBplAddr): Boolean;
begin
  Result := (AAddr >= $10000) and
            (BplPtrAt(AAddr - BplVmtSelfPtrBack) = AAddr) and
            (BplShortAt(BplPtrAt(AAddr - BplVmtClassNameBack)) <> '') and
            (BplIntAt(AAddr - BplVmtInstanceSizeBack) > 0);
end;

// Описание типа класса (ClassInfo); 0 - нет RTTI
function BplClassTypeInfo(AClass: TBplClass): TBplAddr;
begin
  Result := 0;
  if AClass <> nil then
    Result := BplPtrAt(TBplAddr(AClass) - BplVmtTypeInfoBack);
end;

function BplClassName(AClass: TBplClass): string;
begin
  Result := '';
  if AClass <> nil then
    Result := BplShortAt(BplPtrAt(TBplAddr(AClass) -
                                  BplVmtClassNameBack));
end;

function BplClassParent(AClass: TBplClass): TBplClass;
begin
  Result := nil;
  if AClass <> nil then
    Result := Pointer(BplDeref2(TBplAddr(AClass) - BplVmtParentBack));
end;

// Адрес - описание типа класса (tkClass) - его класс; иначе nil
function BplClassOfTypeInfo(AAddr: TBplAddr): TBplClass;
var
  ClassAddr: TBplAddr;
begin
  Result := nil;
  if not BplReadable(AAddr, 2) or (BplTypeKind(AAddr) <> BplTkClass) then
    Exit;
  ClassAddr := BplPtrAt(BplTypeData(AAddr));
  if BplIsVmt(ClassAddr) and
     (BplClassTypeInfo(Pointer(ClassAddr)) = AAddr) then
    Result := Pointer(ClassAddr);
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
  ExpName, FoundName: string;
  Addr: TBplAddr;
  FoundClass: TBplClass;
begin
  AList.Clear;
  if AExportSample <> nil then
    AExportSample.Clear;
  if AModule = 0 then
    Exit;
  DosHdr := PImageDosHeader(AModule);
  if DosHdr^.e_magic <> IMAGE_DOS_SIGNATURE then
    Exit;
  NtHdr := PImageNtHeaders(TBplAddr(AModule) + TBplAddr(DosHdr^._lfanew));
  if NtHdr^.Signature <> IMAGE_NT_SIGNATURE then
    Exit;
  ExpStart := NtHdr^.OptionalHeader.DataDirectory[
                IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
  ExpEnd := ExpStart + NtHdr^.OptionalHeader.DataDirectory[
                         IMAGE_DIRECTORY_ENTRY_EXPORT].Size;
  if ExpStart = 0 then
    Exit;
  ExpDir := PBplExportDir(TBplAddr(AModule) + ExpStart);
  NameRvas := PBplDWords(TBplAddr(AModule) + ExpDir^.AddressOfNames);
  FuncRvas := PBplDWords(TBplAddr(AModule) + ExpDir^.AddressOfFunctions);
  Ordinals := PBplWords(TBplAddr(AModule) + ExpDir^.AddressOfNameOrdinals);

  for Idx := 0 to Integer(ExpDir^.NumberOfNames) - 1 do
  begin
    ExpName := PChar(TBplAddr(AModule) + NameRvas^[Idx]);
    if (AExportSample <> nil) and (AExportSample.Count < 40) then
      AExportSample.Add(ExpName);
    FuncRva := FuncRvas^[Ordinals^[Idx]];
    // Пересылка в другой модуль - не адрес
    if (FuncRva >= ExpStart) and (FuncRva < ExpEnd) then
      Continue;
    Addr := TBplAddr(AModule) + FuncRva;
    FoundClass := nil;
    try
      if BplIsVmt(Addr) then
        FoundClass := Pointer(Addr)
      else
        FoundClass := BplClassOfTypeInfo(Addr);
    except
      FoundClass := nil;
    end;
    if FoundClass = nil then
      Continue;
    FoundName := BplClassName(FoundClass);
    if AList.IndexOfName(FoundName) < 0 then
      AList.AddObject(FoundName + '=' + ExpName, TObject(FoundClass));
  end;
end;

function BplClassChain(AClass: TBplClass): string;
var
  Cur: TBplClass;
  Depth: Integer;
begin
  Result := '';
  Cur := AClass;
  Depth := 0;
  // Глубина - от зацикливания на испорченной таблице
  while (Cur <> nil) and (Depth < 256) do
  begin
    if Result <> '' then
      Result := Result + ' < ';
    Result := Result + BplClassName(Cur);
    Cur := BplClassParent(Cur);
    Inc(Depth);
  end;
end;

function BplInheritsFromName(AClass: TBplClass; const AName: string): Boolean;
var
  Cur: TBplClass;
  Depth: Integer;
begin
  Result := False;
  Cur := AClass;
  Depth := 0;
  while (Cur <> nil) and (Depth < 256) do
  begin
    if CompareText(BplClassName(Cur), AName) = 0 then
    begin
      Result := True;
      Exit;
    end;
    Cur := BplClassParent(Cur);
    Inc(Depth);
  end;
end;

// ---------------------------------------------------------------------------
//  Свойства класса. Данные типа tkClass: ClassType (4), ParentInfo (4,
//  PPTypeInfo), PropCount (2, со свойствами предков), UnitName
//  (ShortString), затем свойства самого класса: число (2) и записи
//  TPropInfo подряд.
// ---------------------------------------------------------------------------

// Описание типа предка; 0 - нет
function BplParentTypeInfo(AType: TBplAddr): TBplAddr;
begin
  Result := BplDeref2(BplTypeData(AType) + BplPtrSize);
end;

// Число свойств с предками
function BplTotalProps(AType: TBplAddr): Integer;
begin
  Result := SmallInt(BplWordAt(BplTypeData(AType) + 2 * BplPtrSize));
end;

// Начало свойств самого класса: адрес числа свойств (Word)
function BplOwnPropData(AType: TBplAddr): TBplAddr;
begin
  Result := BplAfterShort(BplTypeData(AType) + 2 * BplPtrSize + 2);
end;

function BplNextProp(AProp: TBplAddr): TBplAddr;
begin
  Result := BplAfterShort(AProp + BplPropNameOfs);
end;

function BplPropName(AProp: TBplAddr): string;
begin
  Result := BplShortAt(AProp + BplPropNameOfs);
end;

function BplPropType(AProp: TBplAddr): TBplAddr;
begin
  Result := BplDeref2(AProp);
end;

function BplHasPublished(AClass: TBplClass; const AProp: string): Boolean;
var
  TypeAddr, PropData, PropAddr: TBplAddr;
  OwnCount, PropIdx, Depth: Integer;
begin
  Result := False;
  TypeAddr := BplClassTypeInfo(AClass);
  Depth := 0;
  while (TypeAddr <> 0) and (Depth < 256) and
        (BplTypeKind(TypeAddr) = BplTkClass) do
  begin
    PropData := BplOwnPropData(TypeAddr);
    OwnCount := BplWordAt(PropData);
    PropAddr := PropData + 2;
    for PropIdx := 0 to OwnCount - 1 do
    begin
      if CompareText(BplPropName(PropAddr), AProp) = 0 then
      begin
        Result := True;
        Exit;
      end;
      PropAddr := BplNextProp(PropAddr);
    end;
    TypeAddr := BplParentTypeInfo(TypeAddr);
    Inc(Depth);
  end;
end;

// Свойства класса с предками, как GetPropInfos + сортировка GetPropList:
// место свойства - его NameIndex, свойство потомка закрывает свойство
// предка с тем же номером; затем - по имени. Возвращает число свойств.
function BplCollectProps(AType: TBplAddr; var AProps: PBplAddrs): Integer;
var
  TotalCount, OwnCount, PropIdx, NameIdx, Depth, SortIdx, InsIdx: Integer;
  TypeAddr, PropData, PropAddr, Moving: TBplAddr;
  MovingName: string;
begin
  Result := 0;
  AProps := nil;
  TotalCount := BplTotalProps(AType);
  if (TotalCount <= 0) or (TotalCount > 65535) then
    Exit;
  GetMem(AProps, TotalCount * SizeOf(TBplAddr));
  FillChar(AProps^, TotalCount * SizeOf(TBplAddr), 0);
  TypeAddr := AType;
  Depth := 0;
  while (TypeAddr <> 0) and (Depth < 256) and
        (BplTypeKind(TypeAddr) = BplTkClass) do
  begin
    PropData := BplOwnPropData(TypeAddr);
    OwnCount := BplWordAt(PropData);
    PropAddr := PropData + 2;
    for PropIdx := 0 to OwnCount - 1 do
    begin
      NameIdx := SmallInt(BplWordAt(PropAddr + BplPropNameIndexOfs));
      if (NameIdx >= 0) and (NameIdx < TotalCount) and
         (AProps^[NameIdx] = 0) then
        AProps^[NameIdx] := PropAddr;
      PropAddr := BplNextProp(PropAddr);
    end;
    TypeAddr := BplParentTypeInfo(TypeAddr);
    Inc(Depth);
  end;
  // Пустые места (испорченные данные) - убрать
  for PropIdx := 0 to TotalCount - 1 do
    if AProps^[PropIdx] <> 0 then
    begin
      AProps^[Result] := AProps^[PropIdx];
      Inc(Result);
    end;
  // По имени (вставками: свойств немного)
  for SortIdx := 1 to Result - 1 do
  begin
    Moving := AProps^[SortIdx];
    MovingName := BplPropName(Moving);
    InsIdx := SortIdx - 1;
    while (InsIdx >= 0) and
          (CompareText(BplPropName(AProps^[InsIdx]), MovingName) > 0) do
    begin
      AProps^[InsIdx + 1] := AProps^[InsIdx];
      Dec(InsIdx);
    end;
    AProps^[InsIdx + 1] := Moving;
  end;
end;

// Имя значения перечисления (как GetEnumName). Данные tkEnumeration:
// OrdType (1), MinValue (4), MaxValue (4), BaseType (4, PPTypeInfo),
// NameList - имена значений базового типа подряд.
function BplEnumName(AType: TBplAddr; AValue: Integer): string;
var
  BaseType, NameAddr: TBplAddr;
  StepIdx: Integer;
begin
  Result := '';
  if BplTypeKind(AType) = BplTkInteger then
  begin
    Result := IntToStr(AValue);
    Exit;
  end;
  BaseType := BplDeref2(BplTypeData(AType) + 9);
  if BaseType = 0 then
    Exit;
  // ByteBool/WordBool/LongBool: MinValue < 0, любое не 0 - True
  if BplIntAt(BplTypeData(BaseType) + 1) < 0 then
    if AValue <> 0 then
      AValue := 1;
  NameAddr := BplTypeData(BaseType) + 13;
  for StepIdx := 1 to AValue do
    NameAddr := BplAfterShort(NameAddr);
  Result := BplShortAt(NameAddr);
end;

// Значения перечисления: "a, b, c" (длинные - с сокращением)
function BplEnumValues(AType: TBplAddr): string;
var
  MinVal, MaxVal, ValIdx: Integer;
begin
  Result := '';
  MinVal := BplIntAt(BplTypeData(AType) + 1);
  MaxVal := BplIntAt(BplTypeData(AType) + 5);
  for ValIdx := MinVal to MaxVal do
  begin
    if ValIdx - MinVal >= 40 then
    begin
      Result := Result + ', ...';
      Exit;
    end;
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + BplEnumName(AType, ValIdx);
  end;
end;

// Заголовок события: "procedure(Sender: TObject; var Key: Char) of object".
// Данные tkMethod: MethodKind (1), ParamCount (1), параметры: Flags (1),
// ParamName, TypeName (ShortString); у функции затем - ResultType.
function BplMethodSignature(AType: TBplAddr): string;
var
  DataAddr, Cursor: TBplAddr;
  ParamIdx: Integer;
  Flags: Byte;
  ParamName, TypeName, Params: string;
begin
  DataAddr := BplTypeData(AType);
  Cursor := DataAddr + 2;
  Params := '';
  for ParamIdx := 0 to BplByteAt(DataAddr + 1) - 1 do
  begin
    Flags := BplByteAt(Cursor);
    Inc(Cursor);
    ParamName := BplShortAt(Cursor);
    Cursor := BplAfterShort(Cursor);
    TypeName := BplShortAt(Cursor);
    Cursor := BplAfterShort(Cursor);
    if Params <> '' then
      Params := Params + '; ';
    if Flags and BplPfVar <> 0 then
      Params := Params + 'var '
    else if Flags and BplPfConst <> 0 then
      Params := Params + 'const '
    else if Flags and BplPfOut <> 0 then
      Params := Params + 'out ';
    Params := Params + ParamName;
    // Нетипизированный параметр (const Buffer) - без типа
    if TypeName <> '' then
    begin
      Params := Params + ': ';
      if Flags and BplPfArray <> 0 then
        Params := Params + 'array of ';
      Params := Params + TypeName;
    end;
  end;
  if BplByteAt(DataAddr) = BplMkFunction then
    Result := 'function(' + Params + '): ' + BplShortAt(Cursor) +
              ' of object'
  else
    Result := 'procedure(' + Params + ') of object';
end;

procedure BplDumpProps(AClass: TBplClass; AOut: TStrings);
var
  ClsTypeInfo, PropRec, PropType: TBplAddr;
  PropCount, PropIdx, PropKind, DefValue: Integer;
  PropList: PBplAddrs;
  Line: string;
  Events: TStringList;
begin
  ClsTypeInfo := BplClassTypeInfo(AClass);
  if ClsTypeInfo = 0 then
  begin
    AOut.Add('    (у класса нет RTTI)');
    Exit;
  end;
  if BplTotalProps(ClsTypeInfo) <= 0 then
  begin
    AOut.Add('    (published-свойств нет)');
    Exit;
  end;
  Events := TStringList.Create;
  PropList := nil;
  try
    PropCount := BplCollectProps(ClsTypeInfo, PropList);
    AOut.Add('    свойства:');
    for PropIdx := 0 to PropCount - 1 do
    begin
      PropRec := PropList^[PropIdx];
      PropType := BplPropType(PropRec);
      PropKind := BplTypeKind(PropType);
      if PropKind = BplTkMethod then
      begin
        Events.Add('      ' + BplPropName(PropRec) + ': ' +
                   BplTypeName(PropType) + ' = ' +
                   BplMethodSignature(PropType));
        Continue;
      end;
      Line := '      ' + BplPropName(PropRec) + ': ' + BplTypeName(PropType) +
              ' [' + BplKindName(PropKind) + ']';
      if BplPtrAt(PropRec + BplPropSetProcOfs) = 0 then
        Line := Line + ' только чтение';
      DefValue := BplIntAt(PropRec + BplPropDefaultOfs);
      if (DefValue <> BplNoDefault) and
         (PropKind in [BplTkInteger, BplTkChar, BplTkEnumeration, BplTkSet,
                       BplTkWChar]) then
        Line := Line + ' default ' + IntToStr(DefValue);
      case PropKind of
        BplTkEnumeration:
          Line := Line + ' (' + BplEnumValues(PropType) + ')';
        BplTkSet:
          // Данные tkSet: OrdType (1), CompType (4, PPTypeInfo)
          Line := Line + ' (set of ' +
                  BplEnumValues(BplDeref2(BplTypeData(PropType) + 1)) + ')';
        BplTkClass:
          Line := Line + ' -> ' +
                  BplClassChain(Pointer(BplPtrAt(BplTypeData(PropType))));
      end;
      AOut.Add(Line);
    end;
    if Events.Count > 0 then
    begin
      AOut.Add('    события:');
      AOut.AddStrings(Events);
    end;
  finally
    if PropList <> nil then
      FreeMem(PropList);
    Events.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Ресурс PACKAGEINFO: Flags (4), RequiresCount (4), требуемые пакеты
//  (HashCode (1) + имя с #0), ContainsCount (4), модули (Flags (1) +
//  HashCode (1) + имя с #0)
// ---------------------------------------------------------------------------

procedure BplPackageInfo(AModule: HMODULE; AUnits, ARequires: TStrings);
var
  ResInfo: HRSRC;
  ResData: HGLOBAL;
  ResSize: DWORD;
  InfoStart, InfoEnd, Cursor: TBplAddr;
  ItemCount, ItemIdx: Integer;

  // Строка с #0 по адресу, в пределах ресурса; Cursor - за ней
  function TakeName: string;
  var
    NameEnd: TBplAddr;
  begin
    NameEnd := Cursor;
    while (NameEnd < InfoEnd) and (PChar(Pointer(NameEnd))^ <> #0) do
      Inc(NameEnd);
    SetString(Result, PChar(Pointer(Cursor)), NameEnd - Cursor);
    Cursor := NameEnd + 1;
  end;

begin
  if AUnits <> nil then
    AUnits.Clear;
  if ARequires <> nil then
    ARequires.Clear;
  if AModule = 0 then
    Exit;
  ResInfo := FindResource(AModule, 'PACKAGEINFO', RT_RCDATA);
  if ResInfo = 0 then
    Exit;
  ResSize := SizeofResource(AModule, ResInfo);
  ResData := LoadResource(AModule, ResInfo);
  if (ResData = 0) or (ResSize < 8) then
    Exit;
  InfoStart := TBplAddr(LockResource(ResData));
  if InfoStart = 0 then
    Exit;
  InfoEnd := InfoStart + ResSize;
  Cursor := InfoStart + 8;
  ItemCount := PInteger(Pointer(InfoStart + 4))^;
  for ItemIdx := 0 to ItemCount - 1 do
  begin
    if Cursor + 1 >= InfoEnd then
      Exit;
    Inc(Cursor);                     // HashCode
    if ARequires <> nil then
      ARequires.Add(TakeName)
    else
      TakeName;
  end;
  if Cursor + 4 > InfoEnd then
    Exit;
  ItemCount := PInteger(Pointer(Cursor))^;
  Inc(Cursor, 4);
  for ItemIdx := 0 to ItemCount - 1 do
  begin
    if Cursor + 2 >= InfoEnd then
      Exit;
    Inc(Cursor, 2);                  // Flags, HashCode
    if AUnits <> nil then
      AUnits.Add(TakeName)
    else
      TakeName;
  end;
end;

end.
