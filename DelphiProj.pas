unit DelphiProj;

// ---------------------------------------------------------------------------
//  Файлы проекта Delphi 7:
//    - .dpr: модули проекта из секции uses (ParseDprUnits);
//    - .dof: ключи dcc32, как их задала среда (DofCompilerParams);
//    - $(DELPHI) и $(BDS) в путях (ExpandDelphiRoot).
//
//  Вынесено из Unit1 без изменения поведения. Без VCL.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, IniFiles, StrUtils;

// Секция uses файла .dpr: строки UnitName|FileName|Form|Class. Возвращает
// число разобранных модулей.
function ParseDprUnits(const ADpr: string; AList: TStrings): Integer;
// Ключи dcc32 из <проект>.dof; SearchPath - в ASearch, Conditionals - в
// ADefines. Что найдено и что взято - строками в ALog (может быть nil).
function DofCompilerParams(const ADpr, ARoot: string;
                           var ASearch, ADefines: string;
                           ALog: TStrings): string;
// $(DELPHI) и $(BDS) - папка Delphi ARoot
function ExpandDelphiRoot(const S, ARoot: string): string;

// Повторы имён компонентов в текстовом .dfm - строками "файл(строка)
// Error: ..." в AErrors. Результат - число повторов.
function DfmDuplicateNames(const ADfm: string; AErrors: TStrings): Integer;

implementation

// $(DELPHI) в путях. Окно настроек разворачивает макросы при вводе, но
// editor.ini правят и руками, а dcc32 макросов не понимает - для него это
// просто несуществующая папка.
function ExpandDelphiRoot(const S, ARoot: string): string;
var
  R: string;
begin
  Result := S;
  if (S = '') or (ARoot = '') then
    Exit;

  R := ExcludeTrailingPathDelimiter(ARoot);
  Result := StringReplace(Result, '$(DELPHI)', R, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '$(BDS)', R, [rfReplaceAll, rfIgnoreCase]);
end;

// Разбор секции uses. Каждая строка списка - UnitName|FileName|Form|Class.
// Модули без "in 'файл'" (Forms, SysUtils и прочие) пропускаем: они не часть
// проекта. Возвращает число разобранных модулей.
function ParseDprUnits(const ADpr: string; AList: TStrings): Integer;
var
  SL, Parts: TStringList;
  Txt, Up, Seg, Item, Brace, UnitNm, FileNm, FormNm, FormCls: string;
  P, Q, B1, B2, C, Q1, Q2, I: Integer;
begin
  Result := 0;
  AList.Clear;
  if not FileExists(ADpr) then
    Exit;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(ADpr);
    Txt := SL.Text;
  finally
    SL.Free;
  end;

  Up := AnsiUpperCase(Txt);
  P := Pos('USES', Up);
  if P <= 0 then
    Exit;
  Q := PosEx(';', Txt, P);
  if Q <= 0 then
    Exit;

  Seg := Copy(Txt, P + 4, Q - P - 4);

  Parts := TStringList.Create;
  try
    // Запятая разделяет элементы; ни в скобках, ни в кавычках запятых не
    // бывает, поэтому хватает простого разбиения
    while Seg <> '' do
    begin
      C := Pos(',', Seg);
      if C > 0 then
      begin
        Parts.Add(Copy(Seg, 1, C - 1));
        Seg := Copy(Seg, C + 1, Length(Seg));
      end
      else
      begin
        Parts.Add(Seg);
        Seg := '';
      end;
    end;

    for I := 0 to Parts.Count - 1 do
    begin
      Item := Trim(Parts[I]);
      if Item = '' then
        Continue;

      FormNm := '';
      FormCls := '';

      B1 := Pos('{', Item);
      if B1 > 0 then
      begin
        B2 := PosEx('}', Item, B1);
        if B2 > B1 then
        begin
          Brace := Trim(Copy(Item, B1 + 1, B2 - B1 - 1));
          Item := Trim(Copy(Item, 1, B1 - 1));

          // {DataModule1: TDataModule} - имя и класс через двоеточие
          C := Pos(':', Brace);
          if C > 0 then
          begin
            FormNm := Trim(Copy(Brace, 1, C - 1));
            FormCls := Trim(Copy(Brace, C + 1, Length(Brace)));
          end
          else
            FormNm := Brace;
        end;
      end;

      FileNm := '';
      UnitNm := Item;

      Q1 := Pos('''', Item);
      if Q1 > 0 then
      begin
        Q2 := PosEx('''', Item, Q1 + 1);
        if Q2 > Q1 then
        begin
          FileNm := Copy(Item, Q1 + 1, Q2 - Q1 - 1);
          UnitNm := Trim(Copy(Item, 1, Q1 - 1));

          // Осталось "Unit1 in" - отрезаем служебное слово
          if (Length(UnitNm) > 3) and
             (CompareText(Copy(UnitNm, Length(UnitNm) - 2, 3), ' in') = 0) then
            UnitNm := Trim(Copy(UnitNm, 1, Length(UnitNm) - 3));
        end;
      end;

      if (FileNm = '') or (UnitNm = '') then
        Continue;

      AList.Add(UnitNm + '|' + FileNm + '|' + FormNm + '|' + FormCls);
      Inc(Result);
    end;
  finally
    Parts.Free;
  end;
end;

// Ключи dcc32 из <проект>.dof - файла, по которому собирает среда Delphi 7.
// Сам dcc32 .dof не читает, он читает <проект>.cfg. Среда пишет .cfg при
// сохранении проекта, но .cfg может не быть (его не кладут в архив и в git)
// или он может отстать от .dof. Тогда сборка здесь и в Delphi расходится:
// например, без -$J+ присваивание типизированной константе даёт "Left side
// cannot be assigned to".
//
// Берётся:
//   [Compiler]    A..Z          -> -$A8 -$B- ... -$YD -$Z1
//                 ShowHints     -> -H+/-H-
//                 ShowWarnings  -> -W+/-W-
//                 UnitAliases   -> -A...
//                 UnsafeType, UnsafeCode, UnsafeCast = 0 -> -w-UNSAFE_...
//   [Linker]      MapFile 1/2/3 -> -GS/-GP/-GD (карта: сегменты, имена,
//                 подробная с номерами строк)
//                 DebugInfo=1   -> -V, RemoteSymbols=1 -> -VR
//                 MinStackSize, MaxStackSize -> -$M<min>,<max>
//                 ImageBase (если не $00400000) -> -K$<адрес>
//   [Directories] UsePackages=1 и Packages -> -LU<пакеты>
//   [Directories] Conditionals  -> ADefines (ключ -D ставит вызывающий)
//                 SearchPath    -> ASearch, пути абсолютные
// Выходные папки (OutputDir, UnitOutputDir) не берутся: их задают
// настройки инструмента, ExePath и DcuPath.
// Что найдено и что взято - строками в ALog (вызывающий выводит их в лог
// компиляции).
function DofCompilerParams(const ADpr, ARoot: string;
                           var ASearch, ADefines: string;
                           ALog: TStrings): string;
var
  Dof, Cfg, Dir, V, S, Rest, Item, Others: string;
  Ini: TIniFile;
  C: Char;
  P: Integer;
  SR: TSearchRec;

  // Строка для лога компиляции - вызывающий выведет её сам
  procedure Log(const S: string);
  begin
    if ALog <> nil then
      ALog.Add(S);
  end;

  function Quoted(const A: string): string;
  begin
    if Pos(' ', A) > 0 then
      Result := '"' + A + '"'
    else
      Result := A;
  end;

begin
  Result := '';
  ASearch := '';
  ADefines := '';
  Dir := ExtractFilePath(ADpr);
  Dof := ChangeFileExt(ADpr, '.dof');
  Cfg := ChangeFileExt(ADpr, '.cfg');

  if FileExists(Cfg) then
    Log('Настройки dcc32: ' + ExtractFileName(Cfg) + ' есть, dcc32 ' +
            'прочитает его сам')
  else
    Log('Настройки dcc32: ' + ExtractFileName(Cfg) + ' нет');

  if not FileExists(Dof) then
  begin
    // Другие .dof в папке - значит, собираемый .dpr назван не так, как
    // проект, чьи настройки лежат рядом
    Others := '';
    if FindFirst(Dir + '*.dof', faAnyFile, SR) = 0 then
    try
      repeat
        if (SR.Attr and faDirectory) = 0 then
        begin
          if Others <> '' then
            Others := Others + ', ';
          Others := Others + SR.Name;
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
    if Others <> '' then
      Log('Настройки проекта: ' + ExtractFileName(Dof) + ' нет, в ' +
              'папке есть ' + Others + ' - они к ' + ExtractFileName(ADpr) +
              ' не относятся')
    else
      Log('Настройки проекта: ' + ExtractFileName(Dof) + ' нет - ключи ' +
              '-$ из .cfg или умолчания dcc32');
    Exit;
  end;

  Ini := TIniFile.Create(Dof);
  try
    // Ключи $A..$Z
    for C := 'A' to 'Z' do
    begin
      V := Trim(Ini.ReadString('Compiler', C, ''));
      if V = '' then
        Continue;
      case C of
        'A':
          if V = '0' then
            S := '-$A-'
          else
            S := '-$A' + V;         // 1, 2, 4, 8 - выравнивание
        'Y':
          if V = '0' then
            S := '-$Y-'
          else if V = '1' then
            S := '-$YD'             // только объявления
          else
            S := '-$Y+';
        'Z':
          if V = '0' then
            S := '-$Z1'
          else
            S := '-$Z' + V;         // 1, 2, 4 - размер перечислений
      else
        if V = '0' then
          S := '-$' + C + '-'
        else
          S := '-$' + C + '+';
      end;
      Result := Result + ' ' + S;
    end;

    V := Trim(Ini.ReadString('Compiler', 'ShowHints', ''));
    if V = '0' then
      Result := Result + ' -H-'
    else if V = '1' then
      Result := Result + ' -H+';
    V := Trim(Ini.ReadString('Compiler', 'ShowWarnings', ''));
    if V = '0' then
      Result := Result + ' -W-'
    else if V = '1' then
      Result := Result + ' -W+';

    V := Trim(Ini.ReadString('Compiler', 'UnitAliases', ''));
    if V <> '' then
      Result := Result + ' -A' + Quoted(V);

    if Trim(Ini.ReadString('Compiler', 'UnsafeType', '')) = '0' then
      Result := Result + ' -w-UNSAFE_TYPE';
    if Trim(Ini.ReadString('Compiler', 'UnsafeCode', '')) = '0' then
      Result := Result + ' -w-UNSAFE_CODE';
    if Trim(Ini.ReadString('Compiler', 'UnsafeCast', '')) = '0' then
      Result := Result + ' -w-UNSAFE_CAST';

    // [Linker] MapFile: 1 - сегменты, 2 - публичные имена, 3 - подробная, с
    // номерами строк. По карте сторож зависаний (HangWatch) переводит
    // адреса в имена процедур и строки.
    V := Trim(Ini.ReadString('Linker', 'MapFile', ''));
    if V = '1' then
      Result := Result + ' -GS'
    else if V = '2' then
      Result := Result + ' -GP'
    else if V = '3' then
      Result := Result + ' -GD';

    // Остальное с вкладки Linker - так же, как в <проект>.cfg, который
    // пишет среда Delphi: отладочная информация TD32 в exe (-V), символы
    // удалённой отладки (-VR), размеры стека (-$M), базовый адрес (-K)
    if Trim(Ini.ReadString('Linker', 'DebugInfo', '')) = '1' then
      Result := Result + ' -V';
    if Trim(Ini.ReadString('Linker', 'RemoteSymbols', '')) = '1' then
      Result := Result + ' -VR';
    S := Trim(Ini.ReadString('Linker', 'MinStackSize', ''));
    V := Trim(Ini.ReadString('Linker', 'MaxStackSize', ''));
    if (StrToIntDef(S, 0) > 0) and (StrToIntDef(V, 0) > 0) then
      Result := Result + ' -$M' + S + ',' + V;
    V := Trim(Ini.ReadString('Linker', 'ImageBase', ''));
    if (StrToInt64Def(V, 0) > 0) and (StrToInt64Def(V, 0) <> 4194304) then
      Result := Result + ' -K$' + IntToHex(StrToInt64Def(V, 0), 8);

    // Runtime packages: Build with runtime packages и список пакетов
    if Trim(Ini.ReadString('Directories', 'UsePackages', '')) = '1' then
    begin
      V := Trim(Ini.ReadString('Directories', 'Packages', ''));
      if V <> '' then
        Result := Result + ' -LU' + Quoted(V);
    end;

    ADefines := Trim(Ini.ReadString('Directories', 'Conditionals', ''));

    // Search path: $(DELPHI) раскрываем, относительные пути - от папки
    // проекта, чтобы CheckUnitPath проверял то же, что увидит dcc32
    Rest := ExpandDelphiRoot(Trim(Ini.ReadString('Directories', 'SearchPath',
                                                 '')), ARoot);
    while Rest <> '' do
    begin
      P := Pos(';', Rest);
      if P > 0 then
      begin
        Item := Trim(Copy(Rest, 1, P - 1));
        Rest := Copy(Rest, P + 1, MaxInt);
      end
      else
      begin
        Item := Trim(Rest);
        Rest := '';
      end;
      if Item = '' then
        Continue;
      if not ((Length(Item) >= 2) and (Item[2] = ':')) and
         (Copy(Item, 1, 2) <> '\\') then
        Item := ExpandFileName(Dir + Item);
      Item := ExcludeTrailingPathDelimiter(Item);
      if ASearch <> '' then
        ASearch := ASearch + ';';
      ASearch := ASearch + Item;
    end;
  finally
    Ini.Free;
  end;

  S := 'Настройки проекта: ' + ExtractFileName(Dof) + ' -> ключи' + Result;
  if ADefines <> '' then
    S := S + ', символы ' + ADefines;
  if ASearch <> '' then
    S := S + ', Search path ' + ASearch;
  Log(S);
end;

// Одинаковые имена компонентов в тексте .dfm. dcc32 кладёт .dfm в exe как
// ресурс и внутрь не смотрит; повтор находит только TReader при создании
// формы - EComponentError "A component named X already exists". Проверка
// повторяет правило VCL: имена уникальны среди компонентов одного
// владельца. Владелец всех объектов формы - сама форма, кроме вложенных
// фреймов (inline): их компоненты принадлежат фрейму. Имя корневого
// объекта в счёт не идёт - форма не владеет сама собой.
// Каждый повтор - строкой в AErrors в формате dcc32
// "файл(строка) Error: текст". Двоичный .dfm не разбирается. Результат -
// число повторов.
function DfmDuplicateNames(const ADfm: string; AErrors: TStrings): Integer;
var
  Lines, ScopeNames: TStringList;
  Scopes: TList;          // TStringList: имя=строка, по владельцам
  BlockScope: array of Integer;  // область имён детей каждого открытого блока
  Depth, LineIdx, ColonPos, SpacePos, CurScope, NewScope, PrevIdx: Integer;
  Line, Low, Word1, CompName: string;
  Head: string;
  Stream: TFileStream;

  procedure Push(AScope: Integer);
  begin
    if Depth >= Length(BlockScope) then
      SetLength(BlockScope, Depth + 16);
    BlockScope[Depth] := AScope;
    Inc(Depth);
  end;

begin
  Result := 0;
  if not FileExists(ADfm) then
    Exit;
  // Двоичный .dfm начинается с 'TPF0' (или с заголовка ресурса $FF)
  SetLength(Head, 4);
  Stream := TFileStream.Create(ADfm, fmOpenRead or fmShareDenyNone);
  try
    if Stream.Read(Head[1], 4) < 4 then
      Exit;
  finally
    Stream.Free;
  end;
  if (Head = 'TPF0') or (Head[1] = #$FF) then
    Exit;

  Lines := TStringList.Create;
  Scopes := TList.Create;
  try
    Lines.LoadFromFile(ADfm);
    Depth := 0;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[LineIdx]);
      if Line = '' then
        Continue;
      Low := LowerCase(Line);

      // Конец объекта или элемента коллекции: end, end>, end>)
      if (Copy(Low, 1, 3) = 'end') and
         ((Length(Low) = 3) or (Low[4] in ['>', ')', ' '])) then
      begin
        if Depth > 0 then
          Dec(Depth);
        Continue;
      end;
      // Элемент коллекции - блок без имени, дети в той же области
      if Low = 'item' then
      begin
        if Depth > 0 then
          Push(BlockScope[Depth - 1])
        else
          Push(-1);
        Continue;
      end;

      SpacePos := Pos(' ', Low);
      if SpacePos = 0 then
        Continue;
      Word1 := Copy(Low, 1, SpacePos - 1);
      if (Word1 <> 'object') and (Word1 <> 'inherited') and
         (Word1 <> 'inline') then
        Continue;

      if Depth = 0 then
        CurScope := -1                 // корень: имя не учитывается
      else
        CurScope := BlockScope[Depth - 1];

      // object Name: TClass [index]; без двоеточия - объект без имени
      ColonPos := Pos(':', Line);
      if ColonPos > 0 then
        CompName := Trim(Copy(Line, SpacePos + 1, ColonPos - SpacePos - 1))
      else
        CompName := '';

      if (CurScope >= 0) and (CompName <> '') then
      begin
        ScopeNames := TStringList(Scopes[CurScope]);
        PrevIdx := ScopeNames.IndexOfName(CompName);
        if PrevIdx >= 0 then
        begin
          AErrors.Add(Format('%s(%d) Error: компонент %s уже есть (строка ' +
                             '%s) - при создании формы будет ' +
                             'EComponentError "A component named %s ' +
                             'already exists"',
                             [ADfm, LineIdx + 1, CompName,
                              ScopeNames.ValueFromIndex[PrevIdx], CompName]));
          Inc(Result);
        end
        else
          ScopeNames.Add(CompName + '=' + IntToStr(LineIdx + 1));
      end;

      // Дети корня и вложенного фрейма - в своей области имён
      if (Depth = 0) or (Word1 = 'inline') then
      begin
        ScopeNames := TStringList.Create;
        ScopeNames.CaseSensitive := False;
        NewScope := Scopes.Add(ScopeNames);
        Push(NewScope);
      end
      else
        Push(CurScope);
    end;
  finally
    for LineIdx := 0 to Scopes.Count - 1 do
      TStringList(Scopes[LineIdx]).Free;
    Scopes.Free;
    Lines.Free;
  end;
end;

end.
