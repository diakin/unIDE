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

end.
