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
// ---------------------------------------------------------------------------

uses
  Windows, SysUtils, Classes, Registry,
  BplRtti in '..\..\BplRtti.pas';

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
  FoundClass: TClass;
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
      FoundClass := TClass(Pointer(Found.Objects[ClsIdx]));
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
        if Pos(UpperCase(AFilter), UpperCase(FoundClass.ClassName)) = 0 then
          Continue;
      end
      else if Kind = '' then
        Continue;
      Props.Clear;
      try
        BplDumpProps(FoundClass, Props);
      except
        on E: Exception do
          Props.Add('    ошибка чтения свойств: ' + E.Message);
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
      if ParamCount = 0 then
      begin
        ListKnownPackages;
        Say('');
        ListPalette;
      end
      else
        DumpPackage(ParamStr(1), ParamStr(2));
    except
      on E: Exception do
        Say('Ошибка: ' + E.ClassName + ': ' + E.Message);
    end;
    LogLines.SaveToFile(ExtractFilePath(ParamStr(0)) + 'BplRtti.log');
    Say('');
    Say('Записано в ' + ExtractFilePath(ParamStr(0)) + 'BplRtti.log');
  finally
    LogLines.Free;
  end;
end.
