program RqDataBuild;

{$APPTYPE CONSOLE}

// ---------------------------------------------------------------------------
//  Сборка общего описания компонентов RapidQ - ComponentAll.data
//
//  RqDataBuild <ComponentAll.data> <rapidq.inc> <папка inc> [выходной файл]
//
//  1. Читается прежний ComponentAll.data (встроенные классы, комментарии);
//     классы из inc и пометки о них от прошлой сборки убираются.
//  2. Варианты перечислений получают значения из rapidq.inc:
//     bsSizeable -> bsSizeable=2; False|True -> False=0|True=1. Варианту без
//     константы значение не дописывается.
//  3. Классы TYPE ... EXTENDS из всех .inc/.bi/.cmp папки inc (сначала
//     файлы самой папки, потом вложенных, по алфавиту) дописываются в конец
//     со строкой '@source и разделом * Defaults. Имя, которое уже есть
//     (встроенный класс или класс из файла раньше), не дописывается -
//     у принятого класса появляется комментарий, где ещё такое имя.
//  4. Целые константы rapidq.inc - разделом * Constants в конце файла:
//     по ним показываются значения, которых нет среди вариантов (alBottom
//     у QSPLITTER).
//  5. Результат - в выходной файл (по умолчанию - тот же ComponentAll.data).
//
//  Собирается Delphi 7 (dcc32 RqDataBuild.dpr из этой папки, модуль
//  RqComponents.pas - на уровень выше) или Free Pascal (-Mdelphi).
// ---------------------------------------------------------------------------

uses
  SysUtils, Classes, RqComponents in '..\RqComponents.pas';

const
  // Начало комментариев, которые пишет сборщик, - по нему повторная сборка
  // их узнаёт и убирает
  BuildMark = '''  класс программы с этим именем: ';

var
  DataFile, IncFile, IncDir, OutFile: string;
  Files, Lines, Taken, Missing: TStringList;
  FileIdx, ClassIdx, ItemIdx, ChoiceIdx, ChoiceValue, Valued, Added,
    Dups: Integer;
  Cls, Existing: TRqClass;
  Member: TRqMember;
  Choice, RelName: string;

// Файлы include папки ADir (вложенные папки - после файлов), по алфавиту
procedure CollectFiles(const ADir: string; AList: TStrings);
var
  Found: TSearchRec;
  Here, Subdirs: TStringList;
  Ext: string;
  ItemIdx: Integer;
begin
  Here := TStringList.Create;
  Subdirs := TStringList.Create;
  try
    if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*', faAnyFile,
                 Found) = 0 then
    try
      repeat
        if (Found.Name = '.') or (Found.Name = '..') then
          Continue;
        if (Found.Attr and faDirectory) <> 0 then
        begin
          // old - старые версии компонентов (COMPONENTS.md), в описание не идут
          if CompareText(Found.Name, 'old') <> 0 then
            Subdirs.Add(Found.Name);
        end
        else
        begin
          Ext := LowerCase(ExtractFileExt(Found.Name));
          if (Ext = '.inc') or (Ext = '.bi') or (Ext = '.cmp') then
            Here.Add(Found.Name);
        end;
      until FindNext(Found) <> 0;
    finally
      FindClose(Found);
    end;
    Here.Sort;
    Subdirs.Sort;
    for ItemIdx := 0 to Here.Count - 1 do
      AList.Add(IncludeTrailingPathDelimiter(ADir) + Here[ItemIdx]);
    for ItemIdx := 0 to Subdirs.Count - 1 do
      CollectFiles(IncludeTrailingPathDelimiter(ADir) + Subdirs[ItemIdx], AList);
  finally
    Subdirs.Free;
    Here.Free;
  end;
end;

// Путь от папки над inc, с обратной косой: inc\object\QStatusBarEx.inc
function RelativeName(const AFile: string): string;
var
  BaseDir: string;
begin
  BaseDir := ExtractFilePath(ExcludeTrailingPathDelimiter(
               IncludeTrailingPathDelimiter(ExpandFileName(IncDir))));
  Result := ExpandFileName(AFile);
  if CompareText(Copy(Result, 1, Length(BaseDir)), BaseDir) = 0 then
    Delete(Result, 1, Length(BaseDir));
  Result := StringReplace(Result, '/', '\', [rfReplaceAll]);
end;

begin
  if ParamCount < 3 then
  begin
    Writeln('RqDataBuild <ComponentAll.data> <rapidq.inc> <inc folder> [out]');
    Halt(1);
  end;
  DataFile := ParamStr(1);
  IncFile := ParamStr(2);
  IncDir := ParamStr(3);
  if ParamCount >= 4 then
    OutFile := ParamStr(4)
  else
    OutFile := DataFile;

  if RqLoadComponents(DataFile) = 0 then
  begin
    Writeln('not loaded: ', DataFile);
    Halt(1);
  end;
  Writeln('classes: ', RqClassCount);
  // Повторная сборка: прежние классы из inc и пометки о них - заново
  RqDropCustomClasses;
  for ClassIdx := 0 to RqClassCount - 1 do
  begin
    Cls := RqClassAt(ClassIdx);
    for ItemIdx := Cls.Comments.Count - 1 downto 0 do
      if Pos(BuildMark, Cls.Comments[ItemIdx]) > 0 then
        Cls.Comments.Delete(ItemIdx);
  end;

  // --- значения вариантов из rapidq.inc
  Lines := TStringList.Create;
  Missing := TStringList.Create;
  Missing.Sorted := True;
  Missing.Duplicates := dupIgnore;
  try
    Lines.LoadFromFile(IncFile);
    Writeln('constants: ', RqParseConsts(Lines));
    // И в файл: раздел * Constants
    RqKeepConstsInData;
    Valued := 0;
    for ClassIdx := 0 to RqClassCount - 1 do
    begin
      Cls := RqClassAt(ClassIdx);
      for ItemIdx := 0 to Cls.Props.Count - 1 do
      begin
        Member := TRqMember(Cls.Props.Objects[ItemIdx]);
        for ChoiceIdx := 0 to Member.Choices.Count - 1 do
        begin
          Choice := Member.Choices[ChoiceIdx];
          if (Pos('=', Choice) > 0) or (Copy(Choice, 1, 1) = '<') then
            Continue;
          if CompareText(Choice, 'False') = 0 then
            Member.Choices[ChoiceIdx] := Choice + '=0'
          else if CompareText(Choice, 'True') = 0 then
            Member.Choices[ChoiceIdx] := Choice + '=1'
          else if RqConstValue(Choice, ChoiceValue) then
            Member.Choices[ChoiceIdx] := Choice + '=' + IntToStr(ChoiceValue)
          else
          begin
            Missing.Add(Choice);
            Continue;
          end;
          Inc(Valued);
        end;
      end;
    end;
    Writeln('choices with values: ', Valued, ', without constant: ',
            Missing.Count);
    if Missing.Count > 0 then
      Writeln('  ', Missing.CommaText);
  finally
    Lines.Free;
  end;

  // --- классы TYPE ... EXTENDS из папки inc
  Files := TStringList.Create;
  Lines := TStringList.Create;
  try
    CollectFiles(IncDir, Files);
    Added := 0;
    Dups := 0;
    for FileIdx := 0 to Files.Count - 1 do
    begin
      Lines.LoadFromFile(Files[FileIdx]);
      RqClearCustom;
      RqParseTypes(Lines, Files[FileIdx]);
      Taken := RqTakeCustom;
      try
        RelName := RelativeName(Files[FileIdx]);
        for ClassIdx := 0 to Taken.Count - 1 do
        begin
          Cls := TRqClass(Taken.Objects[ClassIdx]);
          Taken.Objects[ClassIdx] := nil;
          Cls.SrcFile := RelName;
          Existing := RqFindClass(Cls.Name);
          if Existing <> nil then
          begin
            if Existing.IsCustom then
              Existing.Comments.Add('''  то же имя ещё в ' + RelName +
                                    ', строка ' + IntToStr(Cls.SrcLine + 1) +
                                    ' (EXTENDS ' + Cls.BaseName + ')')
            else
              Existing.Comments.Add(BuildMark + RelName + ', строка ' +
                                    IntToStr(Cls.SrcLine + 1) + ' (EXTENDS ' +
                                    Cls.BaseName + ') - берётся, если ' +
                                    'программа подключает этот файл');
            Cls.Free;
            Inc(Dups);
            Continue;
          end;
          RqAddClass(Cls);
          Inc(Added);
        end;
      finally
        for ClassIdx := 0 to Taken.Count - 1 do
          Taken.Objects[ClassIdx].Free;
        Taken.Free;
      end;
    end;
    Writeln('include files: ', Files.Count, ', classes added: ', Added,
            ', same names skipped: ', Dups);
  finally
    Lines.Free;
    Files.Free;
  end;

  // --- комментарий файла
  with RqHeaderComments do
  begin
    Clear;
    Add('''  Описание компонентов RapidQ для unIDE - общий файл.');
    Add('''  Собран RqDataBuild (rapidq_ref\RqDataBuild.dpr) из:');
    Add('''    Component.data   - основная редакция, её записи как есть;');
    Add('''    Component1.data  - классы, которых в основной нет (меню,');
    Add('''                       QGLASSFRAME), и недостающие свойства и события;');
    Add('''                       где у общей записи другое значение - оно');
    Add('''                       комментарием под записью;');
    Add('''    inc\rapidq.inc   - значения вариантов: bsSizeable=2, и все его');
    Add('''                       целые константы - раздел * Constants в конце;');
    Add('''    inc\...          - классы TYPE ... EXTENDS: заголовок');
    Add('''                       "# N ИМЯ EXTENDS БАЗОВЫЙ", строка ''@source');
    Add('''                       файл строка, раздел * Defaults - значения из');
    Add('''                       CONSTRUCTOR.');
    Add('''  Формат записей - в RqComponents.pas. Строки с '' - комментарии.');
  end;

  RqSaveComponents(OutFile);
  Writeln('written: ', OutFile, ', classes: ', RqClassCount);
end.
