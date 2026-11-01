program BplRttiTest;

{$APPTYPE CONSOLE}

// ---------------------------------------------------------------------------
//  Проба: можно ли прочитать свойства и события компонентов из пакета
//  Delphi (.bpl), не выполняя его код (модуль BplRtti). Результат - на
//  экран и в BplRtti.log рядом с программой.
//
//  Сборка (из папки tests\BplRtti):
//    dcc32 -U..\.. BplRttiTest.dpr
//
//  Запуск:
//    BplRttiTest
//        - установленные в Delphi 7 design-пакеты (Known Packages) и
//          runtime-пакеты, которые им нужны: где искать .bpl с классами;
//          раскладка палитры Delphi из реестра (страницы и компоненты)
//    BplRttiTest <путь к runtime .bpl> [часть имени класса]
//        - классы пакета, их предки, свойства и события. Без второго
//          параметра свойства печатаются у всех наследников TComponent.
//    BplRttiTest -compare <путь к runtime .bpl>
//        - сверка BplRtti (свои записи RTTI Delphi 7) с модулем TypInfo и
//          SysUtils.GetPackageInfo по всем классам пакета: цепочки предков,
//          списки свойств, BplHasPublished против GetPropInfo, PACKAGEINFO.
//          В лог - только расхождения и итог.
//    Без параметров PACKAGEINFO каждого пакета тоже сверяется с
//    GetPackageInfo.
// ---------------------------------------------------------------------------

uses
  Windows, SysUtils, Classes, Registry, TypInfo,
  BplRtti in '..\..\BplRtti.pas',
  Unit2 in 'Unit2.pas' {Form2};

var
  LogLines: TStringList;

procedure Say(const AText: string);
var
  OemText: string;
begin
  LogLines.Add(AText);
  // Консоль Windows - в OEM-кодировке
  SetLength(OemText, Length(AText));
  if AText <> '' then
    CharToOemBuff(PChar(AText), PChar(OemText), Length(AText));
  Writeln(OemText);
end;

// ---------------------------------------------------------------------------
//  Прежнее чтение через TypInfo и GetPackageInfo - для сверки (-compare).
//  Класс пакета здесь - TClass: тест собран Delphi 7, раскладка та же.
// ---------------------------------------------------------------------------

const
  OldNoDefault = Integer($80000000);

var
  DiffCount: Integer;

procedure Differ(const AWhat, ANew, AOld: string);
begin
  Inc(DiffCount);
  Say('РАСХОЖДЕНИЕ ' + AWhat);
  Say('  BplRtti: ' + ANew);
  Say('  TypInfo: ' + AOld);
end;

function LineAt(ALines: TStrings; AIndex: Integer): string;
begin
  if AIndex < ALines.Count then
    Result := ALines[AIndex]
  else
    Result := '(нет строки)';
end;

function OldClassChain(AClass: TClass): string;
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

function OldEnumValues(AType: PTypeInfo): string;
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

function OldMethodSignature(AType: PTypeInfo): string;
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

// То же, что прежний BplDumpProps; AProps - имена свойств (для сверки
// BplHasPublished)
procedure OldDumpProps(AClass: TClass; AOut, AProps: TStrings);
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
      AProps.Add(PropRec^.Name);
      if PropType^.Kind = tkMethod then
      begin
        Events.Add('      ' + PropRec^.Name + ': ' + PropType^.Name + ' = ' +
                   OldMethodSignature(PropType));
        Continue;
      end;
      KindName := GetEnumName(TypeInfo(TTypeKind), Ord(PropType^.Kind));
      Line := '      ' + PropRec^.Name + ': ' + PropType^.Name +
              ' [' + KindName + ']';
      if PropRec^.SetProc = nil then
        Line := Line + ' только чтение';
      if (PropRec^.Default <> OldNoDefault) and
         (PropType^.Kind in [tkInteger, tkChar, tkEnumeration, tkSet,
                             tkWChar]) then
        Line := Line + ' default ' + IntToStr(PropRec^.Default);
      case PropType^.Kind of
        tkEnumeration:
          Line := Line + ' (' + OldEnumValues(PropType) + ')';
        tkSet:
          Line := Line + ' (set of ' +
                  OldEnumValues(GetTypeData(PropType)^.CompType^) + ')';
        tkClass:
          Line := Line + ' -> ' +
                  OldClassChain(GetTypeData(PropType)^.ClassType);
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
  TOldInfoLists = record
    Units: TStrings;
    Requires: TStrings;
  end;
  POldInfoLists = ^TOldInfoLists;

procedure OldInfoProc(const AName: string; ANameType: TNameType;
                      AFlags: Byte; AParam: Pointer);
begin
  case ANameType of
    ntContainsUnit:
      POldInfoLists(AParam)^.Units.Add(AName);
    ntRequiresPackage:
      POldInfoLists(AParam)^.Requires.Add(AName);
  end;
end;

procedure OldPackageInfo(AModule: HMODULE; AUnits, ARequires: TStrings);
var
  Lists: TOldInfoLists;
  InfoFlags: Integer;
begin
  AUnits.Clear;
  ARequires.Clear;
  if (AModule = 0) or
     (FindResource(AModule, 'PACKAGEINFO', RT_RCDATA) = 0) then
    Exit;
  Lists.Units := AUnits;
  Lists.Requires := ARequires;
  InfoFlags := 0;
  GetPackageInfo(AModule, @Lists, InfoFlags, OldInfoProc);
end;

// PACKAGEINFO: BplPackageInfo против GetPackageInfo
procedure ComparePackageInfo(AModule: HMODULE; const AWhere: string);
var
  NewUnits, NewReq, OldUnits, OldReq: TStringList;
begin
  NewUnits := TStringList.Create;
  NewReq := TStringList.Create;
  OldUnits := TStringList.Create;
  OldReq := TStringList.Create;
  try
    BplPackageInfo(AModule, NewUnits, NewReq);
    try
      OldPackageInfo(AModule, OldUnits, OldReq);
    except
      on Err: Exception do
        OldUnits.Text := 'ошибка GetPackageInfo: ' + Err.Message;
    end;
    if NewUnits.Text <> OldUnits.Text then
      Differ(AWhere + ': модули', NewUnits.CommaText, OldUnits.CommaText);
    if NewReq.Text <> OldReq.Text then
      Differ(AWhere + ': требует', NewReq.CommaText, OldReq.CommaText);
  finally
    OldReq.Free;
    OldUnits.Free;
    NewReq.Free;
    NewUnits.Free;
  end;
end;

// Все классы пакета: BplRtti против TypInfo
procedure ComparePackage(const APath: string);
var
  Module: HMODULE;
  LoadError, ClsName: string;
  Found, NewLines, OldLines, PropNames: TStringList;
  ClsIdx, LineIdx, PropIdx, PropTotal: Integer;
  FoundClass: TBplClass;
  SameClass: TClass;
  OldHas: Boolean;
  StartTick, NewTicks, OldTicks: Cardinal;
begin
  Say('Сверка с TypInfo: ' + APath);
  Module := BplLoadForRtti(APath, LoadError);
  if Module = 0 then
  begin
    Say('Не загрузился: ' + LoadError);
    Exit;
  end;
  DiffCount := 0;
  PropTotal := 0;
  NewTicks := 0;
  OldTicks := 0;
  ComparePackageInfo(Module, 'PACKAGEINFO');
  Found := TStringList.Create;
  NewLines := TStringList.Create;
  OldLines := TStringList.Create;
  PropNames := TStringList.Create;
  try
    BplListClasses(Module, Found, nil);
    Say('Классов: ' + IntToStr(Found.Count));
    for ClsIdx := 0 to Found.Count - 1 do
    begin
      FoundClass := TBplClass(Found.Objects[ClsIdx]);
      SameClass := TClass(FoundClass);
      ClsName := Found.Names[ClsIdx];
      if BplClassName(FoundClass) <> SameClass.ClassName then
        Differ(ClsName + ': имя', BplClassName(FoundClass),
               SameClass.ClassName);
      if BplClassChain(FoundClass) <> OldClassChain(SameClass) then
        Differ(ClsName + ': предки', BplClassChain(FoundClass),
               OldClassChain(SameClass));
      NewLines.Clear;
      OldLines.Clear;
      PropNames.Clear;
      StartTick := GetTickCount;
      BplDumpProps(FoundClass, NewLines);
      NewTicks := NewTicks + (GetTickCount - StartTick);
      StartTick := GetTickCount;
      OldDumpProps(SameClass, OldLines, PropNames);
      OldTicks := OldTicks + (GetTickCount - StartTick);
      if NewLines.Text <> OldLines.Text then
      begin
        LineIdx := 0;
        while (LineIdx < NewLines.Count) and (LineIdx < OldLines.Count) and
              (NewLines[LineIdx] = OldLines[LineIdx]) do
          Inc(LineIdx);
        Differ(ClsName + ': свойства, строка ' + IntToStr(LineIdx + 1) +
               ' (строк ' + IntToStr(NewLines.Count) + ' / ' +
               IntToStr(OldLines.Count) + ')',
               LineAt(NewLines, LineIdx),
               LineAt(OldLines, LineIdx));
      end;
      // Каждое свойство и одно несуществующее
      PropNames.Add('NoSuchPropXyz');
      for PropIdx := 0 to PropNames.Count - 1 do
      begin
        OldHas := (SameClass.ClassInfo <> nil) and
                  (GetPropInfo(SameClass.ClassInfo, PropNames[PropIdx]) <> nil);
        if BplHasPublished(FoundClass, PropNames[PropIdx]) <> OldHas then
          Differ(ClsName + ': BplHasPublished ' + PropNames[PropIdx],
                 BoolToStr(not OldHas, True), BoolToStr(OldHas, True));
        // Регистр имени не важен
        if BplHasPublished(FoundClass, UpperCase(PropNames[PropIdx])) <>
           OldHas then
          Differ(ClsName + ': BplHasPublished ' +
                 UpperCase(PropNames[PropIdx]),
                 BoolToStr(not OldHas, True), BoolToStr(OldHas, True));
      end;
      Inc(PropTotal, PropNames.Count - 1);
    end;
  finally
    PropNames.Free;
    OldLines.Free;
    NewLines.Free;
    Found.Free;
  end;
  Say('Свойств сверено: ' + IntToStr(PropTotal) + '; время BplRtti ' +
      IntToStr(NewTicks) + ' мс, TypInfo ' + IntToStr(OldTicks) + ' мс');
  if DiffCount = 0 then
    Say('Расхождений нет')
  else
    Say('Расхождений: ' + IntToStr(DiffCount));
end;

// Где Windows найдёт пакет по имени (как при загрузке зависимостей)
function FindOnPath(const AName, AFirstDir: string): string;
var
  Buffer: array[0..MAX_PATH] of Char;
  FilePart: PChar;
begin
  Result := '';
  if (AFirstDir <> '') and FileExists(IncludeTrailingPathDelimiter(AFirstDir) +
                                       AName) then
  begin
    Result := IncludeTrailingPathDelimiter(AFirstDir) + AName;
    Exit;
  end;
  if SearchPath(nil, PChar(AName), nil, MAX_PATH, Buffer, FilePart) > 0 then
    Result := Buffer;
end;

function DelphiRootDir: string;
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
      if Reg.OpenKeyReadOnly('Software\Borland\Delphi\7.0') then
        Result := Reg.ReadString('RootDir');
    end;
  finally
    Reg.Free;
  end;
  Result := ExcludeTrailingPathDelimiter(Result);
end;

// Раскладка палитры Delphi: HKCU\Software\Borland\Delphi\7.0\Palette -
// страница и список её компонентов
procedure ListPalette;
var
  Reg: TRegistry;
  PageNames: TStringList;
  PageIdx: Integer;
  PageText: string;
begin
  Reg := TRegistry.Create(KEY_READ);
  PageNames := TStringList.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if not Reg.OpenKeyReadOnly('Software\Borland\Delphi\7.0\Palette') then
    begin
      Say('В реестре нет HKCU\Software\Borland\Delphi\7.0\Palette');
      Exit;
    end;
    Reg.GetValueNames(PageNames);
    Say('Палитра Delphi (Palette): страниц ' + IntToStr(PageNames.Count));
    for PageIdx := 0 to PageNames.Count - 1 do
    begin
      try
        PageText := Reg.ReadString(PageNames[PageIdx]);
      except
        PageText := '(не строка)';
      end;
      Say('  ' + PageNames[PageIdx] + ' = ' + PageText);
    end;
  finally
    PageNames.Free;
    Reg.Free;
  end;
end;

procedure ListKnownPackages;
var
  Reg: TRegistry;
  PkgNames, Units, Requires: TStringList;
  PkgIdx, ReqIdx: Integer;
  PkgPath, RootDir, Descr, ReqPath, ReqName: string;
  DataModule: HMODULE;
begin
  RootDir := DelphiRootDir;
  Say('Delphi 7: ' + RootDir);
  Reg := TRegistry.Create(KEY_READ);
  PkgNames := TStringList.Create;
  Units := TStringList.Create;
  Requires := TStringList.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if not Reg.OpenKeyReadOnly('Software\Borland\Delphi\7.0\Known Packages') then
    begin
      Say('В реестре нет HKCU\Software\Borland\Delphi\7.0\Known Packages');
      Exit;
    end;
    Reg.GetValueNames(PkgNames);
    for PkgIdx := 0 to PkgNames.Count - 1 do
    begin
      PkgPath := StringReplace(PkgNames[PkgIdx], '$(DELPHI)', RootDir,
                               [rfReplaceAll, rfIgnoreCase]);
      Descr := Reg.ReadString(PkgNames[PkgIdx]);
      // Пакеты самой Delphi (dcl*.bpl в Bin) - пропускаем: их классы и так
      // вкомпилированы в редактор
      if (RootDir <> '') and
         (CompareText(ExtractFilePath(PkgPath),
                      IncludeTrailingPathDelimiter(RootDir) + 'Bin\') = 0) then
        Continue;
      Say('');
      Say(Descr);
      Say('  design: ' + PkgPath);
      if not FileExists(PkgPath) then
      begin
        Say('  файла нет');
        Continue;
      end;
      DataModule := BplLoadAsData(PkgPath);
      if DataModule = 0 then
      begin
        Say('  не открылся: ' + SysErrorMessage(GetLastError));
        Continue;
      end;
      try
        BplPackageInfo(DataModule, Units, Requires);
        ComparePackageInfo(DataModule, ExtractFileName(PkgPath));
      finally
        FreeLibrary(DataModule);
      end;
      for ReqIdx := 0 to Requires.Count - 1 do
      begin
        // Имя в PACKAGEINFO - уже с расширением (CPortLib7.bpl)
        ReqName := Requires[ReqIdx];
        if ExtractFileExt(ReqName) = '' then
          ReqName := ReqName + '.bpl';
        ReqPath := FindOnPath(ReqName, ExtractFilePath(PkgPath));
        if ReqPath = '' then
          ReqPath := '(не найден)';
        Say('  требует ' + Requires[ReqIdx] + ': ' + ReqPath);
      end;
    end;
  finally
    Requires.Free;
    Units.Free;
    PkgNames.Free;
    Reg.Free;
  end;
end;

procedure DumpPackage(const APath, AFilter: string);
var
  Module: HMODULE;
  LoadError: string;
  Found, Sample, Units, Requires, Props: TStringList;
  ClsIdx, LineIdx: Integer;
  FoundClass: TBplClass;
  StartTick: Cardinal;
  Kind: string;
begin
  Say('Пакет: ' + APath);
  StartTick := GetTickCount;
  Module := BplLoadForRtti(APath, LoadError);
  if Module = 0 then
  begin
    Say('Не загрузился: ' + LoadError);
    Say('Нужные ему пакеты (rtl70.bpl, vcl70.bpl и т. д.) должны быть в ' +
        'папке пакета, в Windows\System32 или в PATH.');
    Exit;
  end;
  Say('Загружен за ' + IntToStr(GetTickCount - StartTick) + ' мс');

  Found := TStringList.Create;
  Sample := TStringList.Create;
  Units := TStringList.Create;
  Requires := TStringList.Create;
  Props := TStringList.Create;
  try
    BplPackageInfo(Module, Units, Requires);
    Say('Модули: ' + Units.CommaText);
    Say('Требует: ' + Requires.CommaText);

    StartTick := GetTickCount;
    BplListClasses(Module, Found, Sample);
    Say('Классов: ' + IntToStr(Found.Count) + ', поиск ' +
        IntToStr(GetTickCount - StartTick) + ' мс');
    if Found.Count = 0 then
    begin
      Say('Классы не найдены. Первые экспорты пакета:');
      for LineIdx := 0 to Sample.Count - 1 do
        Say('  ' + Sample[LineIdx]);
      Exit;
    end;

    Found.Sort;
    for ClsIdx := 0 to Found.Count - 1 do
    begin
      FoundClass := TBplClass(Found.Objects[ClsIdx]);
      if BplInheritsFromName(FoundClass, 'TWinControl') then
        Kind := 'оконный контрол'
      else if BplInheritsFromName(FoundClass, 'TControl') then
        Kind := 'контрол'
      else if BplInheritsFromName(FoundClass, 'TComponent') then
        Kind := 'невизуальный компонент'
      else
        Kind := '';
      Say('');
      Say(BplClassChain(FoundClass));
      Say('    экспорт: ' + Found.ValueFromIndex[ClsIdx]);
      if Kind <> '' then
        Say('    вид: ' + Kind);
      if AFilter <> '' then
      begin
        if Pos(UpperCase(AFilter), UpperCase(BplClassName(FoundClass))) = 0 then
          Continue;
      end
      else if Kind = '' then
        Continue;
      Props.Clear;
      try
        BplDumpProps(FoundClass, Props);
      except
        on Err: Exception do
          Props.Add('    ошибка чтения свойств: ' + Err.Message);
      end;
      for LineIdx := 0 to Props.Count - 1 do
        Say(Props[LineIdx]);
    end;
  finally
    Props.Free;
    Requires.Free;
    Units.Free;
    Sample.Free;
    Found.Free;
  end;
  // Пакет не выгружаем: код его не выполнялся, а FreeLibrary зависимостей
  // при выходе сделает Windows
end;

begin
  LogLines := TStringList.Create;
  try
    try
      DiffCount := 0;
      if ParamCount = 0 then
      begin
        ListKnownPackages;
        if DiffCount > 0 then
          Say('PACKAGEINFO: расхождений с GetPackageInfo ' +
              IntToStr(DiffCount))
        else
          Say('PACKAGEINFO: с GetPackageInfo совпадает у всех пакетов');
        Say('');
        ListPalette;
      end
      else if CompareText(ParamStr(1), '-compare') = 0 then
        ComparePackage(ParamStr(2))
      else
        DumpPackage(ParamStr(1), ParamStr(2));
    except
      on Err: Exception do
        Say('Ошибка: ' + Err.ClassName + ': ' + Err.Message);
    end;
    LogLines.SaveToFile(ExtractFilePath(ParamStr(0)) + 'BplRtti.log');
    Say('');
    Say('Записано в ' + ExtractFilePath(ParamStr(0)) + 'BplRtti.log');
  finally
    LogLines.Free;
  end;
end.
