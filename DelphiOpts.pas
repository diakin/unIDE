unit DelphiOpts;

// ---------------------------------------------------------------------------
//  Настройки проекта Delphi 7 (окно Project Options): чтение и запись
//  <проект>.dof, правка <проект>.dpr и <проект>.res так, как это делает
//  среда Delphi.
//
//  Где что хранится (как у Delphi 7):
//    - <проект>.dof - страницы Compiler, Compiler Messages, Linker,
//      Directories/Conditionals, Version Info, Packages;
//    - <проект>.dpr - Title и Help file (Application.Title := ...,
//      Application.HelpFile := ...), список автосоздаваемых форм
//      (Application.CreateForm), главная форма - первая в нём;
//    - <проект>.res - значок (MAINICON) и VERSIONINFO, собранный по .dof.
//
//  Сборка в unIDE идёт через dcc32, а dcc32 .res не меняет. Поэтому
//  VERSIONINFO пишется в .res перед каждой сборкой (DofPrepareBuild) -
//  с увеличением номера сборки, если включено Auto-increment build number.
//
//  Модуль без VCL.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, IniFiles, DelphiProj, ResFile;

const
  // Ключи предупреждений [Compiler] в .dof Delphi 7 - в порядке среды
  DofWarnKeys: array[0..43] of string = (
    'SymbolDeprecated', 'SymbolLibrary', 'SymbolPlatform', 'UnitLibrary',
    'UnitPlatform', 'UnitDeprecated', 'HResultCompat', 'HidingMember',
    'HiddenVirtual', 'Garbage', 'BoundsError', 'ZeroNilCompat',
    'StringConstTruncated', 'ForLoopVarVarPar', 'TypedConstVarPar',
    'AsgToTypedConst', 'CaseLabelRange', 'ForVariable',
    'ConstructingAbstract', 'ComparisonFalse', 'ComparisonTrue',
    'ComparingSignedUnsigned', 'CombiningSignedUnsigned',
    'UnsupportedConstruct', 'FileOpen', 'FileOpenUnitSrc',
    'BadGlobalSymbol', 'DuplicateConstructorDestructor', 'InvalidDirective',
    'PackageNoLink', 'PackageThreadVar', 'ImplicitImport', 'HPPEMITIgnored',
    'NoRetVal', 'UseBeforeDef', 'ForLoopVarUndef', 'UnitNameMismatch',
    'NoCFGFileFound', 'MessageDirective', 'ImplicitVariants',
    'UnicodeToLocale', 'LocaleToUnicode', 'ImagebaseMultiple',
    'SuspiciousTypecast');
  // Три предупреждения о небезопасном коде (.NET) - у Delphi 7 они по
  // умолчанию выключены
  DofUnsafeKeys: array[0..2] of string = (
    'UnsafeType', 'UnsafeCode', 'UnsafeCast');

  // Ключи [Version Info Keys], которые среда Delphi 7 ставит в новый проект
  DofVerKeyNames: array[0..9] of string = (
    'CompanyName', 'FileDescription', 'FileVersion', 'InternalName',
    'LegalCopyright', 'LegalTrademarks', 'OriginalFilename', 'ProductName',
    'ProductVersion', 'Comments');

function DofFileOf(const ADpr: string): string;
function ResFileOf(const ADpr: string): string;

// .dof в памяти. Файла нет - настройки нового проекта Delphi 7; ключи,
// которых в файле нет, тоже дополняются ими. Освобождает вызывающий.
function DofOpen(const ADpr: string): TMemIniFile;
procedure DofApplyDefaults(AIni: TCustomIniFile);

// Подпись предупреждения по ключу: "SymbolDeprecated" -> "Symbol deprecated"
function DofWarnCaption(const AKey: string): string;

// Номер версии и флаги страницы Version Info
function DofVerInfo(AIni: TCustomIniFile): TVerInfo;
function VerNumberText(const AInfo: TVerInfo): string;
// [Version Info Keys] - в список "Ключ=Значение" и обратно
procedure DofReadVerKeys(AIni: TCustomIniFile; AKeys: TStrings);
procedure DofWriteVerKeys(AIni: TCustomIniFile; AKeys: TStrings);

// VERSIONINFO в <проект>.res по настройкам AIni: Include version
// information включено - пишется, выключено - убирается. Что сделано -
// строкой в ALog (может быть nil).
function DofApplyVersionToRes(const ADpr: string; AIni: TCustomIniFile;
                              ALog: TStrings): Boolean;

// Перед сборкой: Auto-increment build number и VERSIONINFO в .res.
// .dof нет или версия не включена - ничего не делается.
procedure DofPrepareBuild(const ADpr: string; ALog: TStrings);

// .dpr: есть ли в нём Application.Run (программа, а не библиотека)
function DprHasApplication(const ADpr: string): Boolean;
// Title, HelpFile и автосоздаваемые формы ("Переменная=Класс", по порядку)
procedure DprReadApp(const ADpr: string; out ATitle, AHelpFile: string;
                     ACreated: TStrings);
// Все формы и модули данных проекта ("Переменная=Класс") - из uses .dpr,
// класс - из первой строки .dfm
procedure DprFormList(const ADpr: string; AForms: TStrings);
// Записать Title, HelpFile и список CreateForm. Файл меняется, только если
// текст изменился. AChanged - был ли он переписан.
function DprWriteApp(const ADpr, ATitle, AHelpFile: string; ACreated: TStrings;
                     out AChanged: Boolean; out AError: string): Boolean;
// Имя в строке program - по имени файла .dpr. dcc32 подставляет в
// {$R *.res} имя программы, а не файла, и после переименования .dpr в exe
// попадал бы .res со старым именем. AOldName - прежнее имя, если файл
// переписан, иначе пусто. False - файл не тронут, причина в AError.
function DprFixProgramName(const ADpr: string; out AOldName: string;
                           out AError: string): Boolean;
// Годится ли AName в идентификатор Delphi 7: латинские буквы, цифры, _,
// первой не цифра
function IsPascalIdent(const AName: string): Boolean;

implementation

function DofFileOf(const ADpr: string): string;
begin
  Result := ChangeFileExt(ADpr, '.dof');
end;

function ResFileOf(const ADpr: string): string;
begin
  Result := ChangeFileExt(ADpr, '.res');
end;

// ---------------------------------------------------------------------------
//  Умолчания
// ---------------------------------------------------------------------------

procedure SetIfMissing(AIni: TCustomIniFile; const ASection, AKey,
                       AValue: string);
begin
  if not AIni.ValueExists(ASection, AKey) then
    AIni.WriteString(ASection, AKey, AValue);
end;

procedure DofApplyDefaults(AIni: TCustomIniFile);
const
  // Ключи $A..$Z нового проекта Delphi 7
  CompilerLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  CompilerValues: array[1..26] of string = (
    '8', '0', '1', '1', '0', '0', '1', '1', '1', '0', '0', '1', '0',
    '1', '1', '1', '0', '0', '0', '0', '0', '1', '0', '1', '1', '1');
var
  LetterIdx, KeyIdx: Integer;
begin
  SetIfMissing(AIni, 'FileVersion', 'Version', '7.0');

  for LetterIdx := 1 to Length(CompilerLetters) do
    SetIfMissing(AIni, 'Compiler', CompilerLetters[LetterIdx],
                 CompilerValues[LetterIdx]);
  SetIfMissing(AIni, 'Compiler', 'ShowHints', '1');
  SetIfMissing(AIni, 'Compiler', 'ShowWarnings', '1');
  SetIfMissing(AIni, 'Compiler', 'UnitAliases',
    'WinTypes=Windows;WinProcs=Windows;DbiTypes=BDE;DbiProcs=BDE;DbiErrs=BDE;');
  SetIfMissing(AIni, 'Compiler', 'NamespacePrefix', '');
  for KeyIdx := Low(DofWarnKeys) to High(DofWarnKeys) do
    SetIfMissing(AIni, 'Compiler', DofWarnKeys[KeyIdx], '1');
  for KeyIdx := Low(DofUnsafeKeys) to High(DofUnsafeKeys) do
    SetIfMissing(AIni, 'Compiler', DofUnsafeKeys[KeyIdx], '0');

  SetIfMissing(AIni, 'Linker', 'MapFile', '0');
  SetIfMissing(AIni, 'Linker', 'OutputObjs', '0');
  SetIfMissing(AIni, 'Linker', 'ConsoleApp', '1');
  SetIfMissing(AIni, 'Linker', 'DebugInfo', '0');
  SetIfMissing(AIni, 'Linker', 'RemoteSymbols', '0');
  SetIfMissing(AIni, 'Linker', 'MinStackSize', '16384');
  SetIfMissing(AIni, 'Linker', 'MaxStackSize', '1048576');
  SetIfMissing(AIni, 'Linker', 'ImageBase', '4194304');
  SetIfMissing(AIni, 'Linker', 'ExeDescription', '');

  SetIfMissing(AIni, 'Directories', 'OutputDir', '');
  SetIfMissing(AIni, 'Directories', 'UnitOutputDir', '');
  SetIfMissing(AIni, 'Directories', 'PackageDLLOutputDir', '');
  SetIfMissing(AIni, 'Directories', 'PackageDCPOutputDir', '');
  SetIfMissing(AIni, 'Directories', 'SearchPath', '');
  SetIfMissing(AIni, 'Directories', 'Packages', '');
  SetIfMissing(AIni, 'Directories', 'Conditionals', '');
  SetIfMissing(AIni, 'Directories', 'DebugSourceDirs', '');
  SetIfMissing(AIni, 'Directories', 'UsePackages', '0');

  SetIfMissing(AIni, 'Version Info', 'IncludeVerInfo', '0');
  SetIfMissing(AIni, 'Version Info', 'AutoIncBuild', '0');
  SetIfMissing(AIni, 'Version Info', 'MajorVer', '1');
  SetIfMissing(AIni, 'Version Info', 'MinorVer', '0');
  SetIfMissing(AIni, 'Version Info', 'Release', '0');
  SetIfMissing(AIni, 'Version Info', 'Build', '0');
  SetIfMissing(AIni, 'Version Info', 'Debug', '0');
  SetIfMissing(AIni, 'Version Info', 'PreRelease', '0');
  SetIfMissing(AIni, 'Version Info', 'Special', '0');
  SetIfMissing(AIni, 'Version Info', 'Private', '0');
  SetIfMissing(AIni, 'Version Info', 'DLL', '0');
  SetIfMissing(AIni, 'Version Info', 'Locale', '1049');
  SetIfMissing(AIni, 'Version Info', 'CodePage', '1251');

  if not AIni.SectionExists('Version Info Keys') then
    for KeyIdx := Low(DofVerKeyNames) to High(DofVerKeyNames) do
      if (DofVerKeyNames[KeyIdx] = 'FileVersion') or
         (DofVerKeyNames[KeyIdx] = 'ProductVersion') then
        AIni.WriteString('Version Info Keys', DofVerKeyNames[KeyIdx], '1.0.0.0')
      else
        AIni.WriteString('Version Info Keys', DofVerKeyNames[KeyIdx], '');
end;

function DofOpen(const ADpr: string): TMemIniFile;
begin
  Result := TMemIniFile.Create(DofFileOf(ADpr));
  DofApplyDefaults(Result);
end;

function DofWarnCaption(const AKey: string): string;
var
  CharIdx: Integer;
begin
  Result := '';
  for CharIdx := 1 to Length(AKey) do
  begin
    // Граница слова - заглавная после строчной ("SymbolDeprecated") или
    // заглавная перед строчной после заглавных ("HPPEMITIgnored")
    if (CharIdx > 1) and (AKey[CharIdx] in ['A'..'Z']) and
       ((AKey[CharIdx - 1] in ['a'..'z']) or
        ((CharIdx < Length(AKey)) and (AKey[CharIdx + 1] in ['a'..'z']) and
         (AKey[CharIdx - 1] in ['A'..'Z']))) then
      Result := Result + ' ' + LowerCase(AKey[CharIdx])
    else
      Result := Result + AKey[CharIdx];
  end;
end;

// ---------------------------------------------------------------------------
//  Версия
// ---------------------------------------------------------------------------

function ReadWordValue(AIni: TCustomIniFile; const ASection, AKey: string;
                       ADefault: Integer): Word;
var
  Value: Integer;
begin
  Value := StrToIntDef(Trim(AIni.ReadString(ASection, AKey, '')), ADefault);
  if (Value < 0) or (Value > 65535) then
    Value := ADefault;
  Result := Value;
end;

function ReadFlag(AIni: TCustomIniFile; const ASection, AKey: string): Boolean;
begin
  Result := Trim(AIni.ReadString(ASection, AKey, '0')) = '1';
end;

function DofVerInfo(AIni: TCustomIniFile): TVerInfo;
begin
  Result.Major := ReadWordValue(AIni, 'Version Info', 'MajorVer', 1);
  Result.Minor := ReadWordValue(AIni, 'Version Info', 'MinorVer', 0);
  Result.Release := ReadWordValue(AIni, 'Version Info', 'Release', 0);
  Result.Build := ReadWordValue(AIni, 'Version Info', 'Build', 0);
  Result.Debug := ReadFlag(AIni, 'Version Info', 'Debug');
  Result.PreRelease := ReadFlag(AIni, 'Version Info', 'PreRelease');
  Result.Special := ReadFlag(AIni, 'Version Info', 'Special');
  Result.PrivateBuild := ReadFlag(AIni, 'Version Info', 'Private');
  Result.IsDll := ReadFlag(AIni, 'Version Info', 'DLL');
  Result.LangId := ReadWordValue(AIni, 'Version Info', 'Locale', 1049);
  Result.CodePage := ReadWordValue(AIni, 'Version Info', 'CodePage', 1251);
end;

function VerNumberText(const AInfo: TVerInfo): string;
begin
  Result := Format('%d.%d.%d.%d', [AInfo.Major, AInfo.Minor, AInfo.Release,
                                   AInfo.Build]);
end;

procedure DofReadVerKeys(AIni: TCustomIniFile; AKeys: TStrings);
var
  Names: TStringList;
  KeyIdx: Integer;
begin
  AKeys.Clear;
  Names := TStringList.Create;
  try
    AIni.ReadSection('Version Info Keys', Names);
    for KeyIdx := 0 to Names.Count - 1 do
      AKeys.Add(Names[KeyIdx] + '=' +
                AIni.ReadString('Version Info Keys', Names[KeyIdx], ''));
  finally
    Names.Free;
  end;
end;

procedure DofWriteVerKeys(AIni: TCustomIniFile; AKeys: TStrings);
var
  KeyIdx: Integer;
  KeyName: string;
begin
  AIni.EraseSection('Version Info Keys');
  for KeyIdx := 0 to AKeys.Count - 1 do
  begin
    KeyName := Trim(AKeys.Names[KeyIdx]);
    if KeyName <> '' then
      AIni.WriteString('Version Info Keys', KeyName,
        Copy(AKeys[KeyIdx], Pos('=', AKeys[KeyIdx]) + 1, MaxInt));
  end;
end;

procedure LogLine(ALog: TStrings; const AText: string);
begin
  if ALog <> nil then
    ALog.Add(AText);
end;

function DofApplyVersionToRes(const ADpr: string; AIni: TCustomIniFile;
                              ALog: TStrings): Boolean;
var
  Info: TVerInfo;
  Keys: TStringList;
  ErrText: string;
begin
  if not ReadFlag(AIni, 'Version Info', 'IncludeVerInfo') then
  begin
    Result := ResRemoveVersion(ResFileOf(ADpr), ErrText);
    if not Result then
      LogLine(ALog, 'Версия: ' + ErrText);
    Exit;
  end;

  Info := DofVerInfo(AIni);
  Keys := TStringList.Create;
  try
    DofReadVerKeys(AIni, Keys);
    Result := ResWriteVersion(ResFileOf(ADpr), Info, Keys, ErrText);
    if Result then
      LogLine(ALog, 'Версия ' + VerNumberText(Info) + ' записана в ' +
                    ExtractFileName(ResFileOf(ADpr)))
    else
      LogLine(ALog, 'Версия: ' + ErrText);
  finally
    Keys.Free;
  end;
end;

procedure DofPrepareBuild(const ADpr: string; ALog: TStrings);
var
  DofData: TMemIniFile;
  Info: TVerInfo;
  OldText: string;
begin
  if not FileExists(DofFileOf(ADpr)) then
    Exit;
  DofData := TMemIniFile.Create(DofFileOf(ADpr));
  try
    if not ReadFlag(DofData, 'Version Info', 'IncludeVerInfo') then
      Exit;

    if ReadFlag(DofData, 'Version Info', 'AutoIncBuild') then
    begin
      Info := DofVerInfo(DofData);
      OldText := VerNumberText(Info);
      if Info.Build < 65535 then
        Inc(Info.Build);
      DofData.WriteString('Version Info', 'Build', IntToStr(Info.Build));
      // FileVersion среда Delphi ведёт сама, по номеру версии
      DofData.WriteString('Version Info Keys', 'FileVersion',
                          VerNumberText(Info));
      try
        DofData.UpdateFile;
        LogLine(ALog, 'Номер сборки: ' + OldText + ' -> ' +
                      VerNumberText(Info));
      except
        on E: Exception do
          LogLine(ALog, 'Номер сборки не записан в ' +
                        ExtractFileName(DofFileOf(ADpr)) + ': ' + E.Message);
      end;
    end;

    DofApplyVersionToRes(ADpr, DofData, ALog);
  finally
    DofData.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  .dpr
// ---------------------------------------------------------------------------

type
  TDprLineKind = (dlOther, dlTitle, dlHelp, dlCreate, dlInit, dlRun);

function DprLineKind(const ALine: string): TDprLineKind;
var
  Upper: string;
begin
  Result := dlOther;
  Upper := UpperCase(Trim(ALine));
  if (Upper = '') or (Copy(Upper, 1, 2) = '//') or (Upper[1] = '{') then
    Exit;
  // Пробелы до скобки и до := в коде Delphi бывают - убираем их
  Upper := StringReplace(Upper, ' ', '', [rfReplaceAll]);
  if Copy(Upper, 1, 20) = 'APPLICATION.TITLE:=' + '''' then
    Result := dlTitle
  else if Copy(Upper, 1, 23) = 'APPLICATION.HELPFILE:=' + '''' then
    Result := dlHelp
  else if Copy(Upper, 1, 23) = 'APPLICATION.CREATEFORM(' then
    Result := dlCreate
  else if Copy(Upper, 1, 22) = 'APPLICATION.INITIALIZE' then
    Result := dlInit
  else if Copy(Upper, 1, 15) = 'APPLICATION.RUN' then
    Result := dlRun;
end;

// Строковая константа Паскаля из строки: от первой кавычки до последней,
// удвоенные кавычки - одна
function PascalLiteral(const ALine: string): string;
var
  FirstPos, LastPos: Integer;
begin
  Result := '';
  FirstPos := Pos('''', ALine);
  LastPos := Length(ALine);
  while (LastPos > FirstPos) and (ALine[LastPos] <> '''') do
    Dec(LastPos);
  if (FirstPos > 0) and (LastPos > FirstPos) then
    Result := StringReplace(Copy(ALine, FirstPos + 1, LastPos - FirstPos - 1),
                            '''''', '''', [rfReplaceAll]);
end;

function QuotePascal(const AText: string): string;
begin
  Result := '''' + StringReplace(AText, '''', '''''', [rfReplaceAll]) + '''';
end;

function LeadingSpace(const ALine: string): string;
var
  CharIdx: Integer;
begin
  CharIdx := 1;
  while (CharIdx <= Length(ALine)) and (ALine[CharIdx] in [' ', #9]) do
    Inc(CharIdx);
  Result := Copy(ALine, 1, CharIdx - 1);
end;

function DprHasApplication(const ADpr: string): Boolean;
var
  Lines: TStringList;
  LineIdx: Integer;
begin
  Result := False;
  if not FileExists(ADpr) then
    Exit;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(ADpr);
    for LineIdx := 0 to Lines.Count - 1 do
      if DprLineKind(Lines[LineIdx]) = dlRun then
      begin
        Result := True;
        Exit;
      end;
  finally
    Lines.Free;
  end;
end;

procedure DprReadApp(const ADpr: string; out ATitle, AHelpFile: string;
                     ACreated: TStrings);
var
  Lines: TStringList;
  LineIdx, OpenPos, ClosePos, CommaPos: Integer;
  Inner: string;
begin
  ATitle := '';
  AHelpFile := '';
  ACreated.Clear;
  if not FileExists(ADpr) then
    Exit;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(ADpr);
    for LineIdx := 0 to Lines.Count - 1 do
      case DprLineKind(Lines[LineIdx]) of
        dlTitle:
          ATitle := PascalLiteral(Lines[LineIdx]);
        dlHelp:
          AHelpFile := PascalLiteral(Lines[LineIdx]);
        dlCreate:
          begin
            OpenPos := Pos('(', Lines[LineIdx]);
            ClosePos := Pos(')', Lines[LineIdx]);
            if (OpenPos > 0) and (ClosePos > OpenPos) then
            begin
              Inner := Copy(Lines[LineIdx], OpenPos + 1, ClosePos - OpenPos - 1);
              CommaPos := Pos(',', Inner);
              if CommaPos > 0 then
                ACreated.Add(Trim(Copy(Inner, CommaPos + 1, MaxInt)) + '=' +
                             Trim(Copy(Inner, 1, CommaPos - 1)));
            end;
          end;
      end;
  finally
    Lines.Free;
  end;
end;

// Класс формы из .dfm: текстовый - "object Form1: TForm1" (или inherited,
// inline), двоичный - 'TPF0', имя класса и имя объекта строками с длиной
function DfmClassName(const ADfm: string): string;
var
  FileStream: TFileStream;
  Head, FirstLine: string;
  ColonPos, LineEnd, NameLen: Integer;
begin
  Result := '';
  if not FileExists(ADfm) then
    Exit;
  FileStream := TFileStream.Create(ADfm, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Head, 256);
    SetLength(Head, FileStream.Read(Head[1], 256));
  finally
    FileStream.Free;
  end;

  if Copy(Head, 1, 4) = 'TPF0' then
  begin
    if Length(Head) >= 5 then
    begin
      NameLen := Ord(Head[5]);
      Result := Copy(Head, 6, NameLen);
    end;
    Exit;
  end;

  LineEnd := Pos(#13, Head);
  if LineEnd = 0 then
    LineEnd := Pos(#10, Head);
  if LineEnd = 0 then
    LineEnd := Length(Head) + 1;
  FirstLine := Trim(Copy(Head, 1, LineEnd - 1));
  ColonPos := Pos(':', FirstLine);
  if ColonPos > 0 then
    Result := Trim(Copy(FirstLine, ColonPos + 1, MaxInt));
end;

procedure DprFormList(const ADpr: string; AForms: TStrings);
var
  Units: TStringList;
  UnitIdx, PartIdx, BarPos: Integer;
  Rest, FileName, FormName, ClassName: string;
  Parts: array[0..3] of string;
begin
  AForms.Clear;
  Units := TStringList.Create;
  try
    ParseDprUnits(ADpr, Units);
    for UnitIdx := 0 to Units.Count - 1 do
    begin
      // UnitName|FileName|Form|Class
      Rest := Units[UnitIdx];
      for PartIdx := 0 to 3 do
      begin
        BarPos := Pos('|', Rest);
        if BarPos > 0 then
        begin
          Parts[PartIdx] := Copy(Rest, 1, BarPos - 1);
          Rest := Copy(Rest, BarPos + 1, MaxInt);
        end
        else
        begin
          Parts[PartIdx] := Rest;
          Rest := '';
        end;
      end;
      FormName := Trim(Parts[2]);
      if FormName = '' then
        Continue;
      FileName := Parts[1];
      if ExtractFileDrive(FileName) = '' then
        FileName := ExtractFilePath(ADpr) + FileName;
      ClassName := DfmClassName(ChangeFileExt(FileName, '.dfm'));
      if ClassName = '' then
        ClassName := 'T' + FormName;
      AForms.Add(FormName + '=' + ClassName);
    end;
  finally
    Units.Free;
  end;
end;

function DprWriteApp(const ADpr, ATitle, AHelpFile: string; ACreated: TStrings;
                     out AChanged: Boolean; out AError: string): Boolean;
var
  OldLines, NewLines: TStringList;
  LineIdx: Integer;
  HasTitle, HasHelp, TitleDone, HelpDone, BlockDone: Boolean;
  Indent: string;

  procedure EmitTitle;
  begin
    if (not TitleDone) and (ATitle <> '') then
      NewLines.Add(Indent + 'Application.Title := ' + QuotePascal(ATitle) + ';');
    TitleDone := True;
  end;

  procedure EmitHelp;
  begin
    if (not HelpDone) and (AHelpFile <> '') then
      NewLines.Add(Indent + 'Application.HelpFile := ' +
                   QuotePascal(AHelpFile) + ';');
    HelpDone := True;
  end;

  procedure EmitBlock;
  var
    FormIdx: Integer;
  begin
    if not BlockDone then
      for FormIdx := 0 to ACreated.Count - 1 do
        NewLines.Add(Indent + 'Application.CreateForm(' +
                     ACreated.ValueFromIndex[FormIdx] + ', ' +
                     ACreated.Names[FormIdx] + ');');
    BlockDone := True;
  end;

begin
  Result := False;
  AChanged := False;
  AError := '';
  if not FileExists(ADpr) then
  begin
    AError := 'Файл не найден: ' + ADpr;
    Exit;
  end;

  OldLines := TStringList.Create;
  NewLines := TStringList.Create;
  try
    OldLines.LoadFromFile(ADpr);

    HasTitle := False;
    HasHelp := False;
    Indent := '';
    for LineIdx := 0 to OldLines.Count - 1 do
      case DprLineKind(OldLines[LineIdx]) of
        dlTitle:
          HasTitle := True;
        dlHelp:
          HasHelp := True;
        dlCreate, dlInit, dlRun:
          if Indent = '' then
            Indent := LeadingSpace(OldLines[LineIdx]);
      end;
    if Indent = '' then
      Indent := '  ';

    TitleDone := False;
    HelpDone := False;
    BlockDone := False;
    for LineIdx := 0 to OldLines.Count - 1 do
      case DprLineKind(OldLines[LineIdx]) of
        dlTitle:
          EmitTitle;
        dlHelp:
          EmitHelp;
        dlCreate:
          EmitBlock;
        dlInit:
          begin
            NewLines.Add(OldLines[LineIdx]);
            if not HasTitle then
              EmitTitle;
            if not HasHelp then
              EmitHelp;
          end;
        dlRun:
          begin
            EmitTitle;
            EmitHelp;
            EmitBlock;
            NewLines.Add(OldLines[LineIdx]);
          end;
      else
        NewLines.Add(OldLines[LineIdx]);
      end;

    if not (TitleDone and HelpDone and BlockDone) then
    begin
      AError := 'В ' + ExtractFileName(ADpr) + ' нет строки Application.Run';
      Exit;
    end;

    if NewLines.Text <> OldLines.Text then
    begin
      try
        NewLines.SaveToFile(ADpr);
      except
        on E: Exception do
        begin
          AError := 'Не записан ' + ADpr + ': ' + E.Message;
          Exit;
        end;
      end;
      AChanged := True;
    end;
    Result := True;
  finally
    NewLines.Free;
    OldLines.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Имя программы
// ---------------------------------------------------------------------------

const
  IdentChars = ['A'..'Z', 'a'..'z', '0'..'9', '_'];

function IsPascalIdent(const AName: string): Boolean;
var
  CharIdx: Integer;
begin
  Result := (AName <> '') and (AName[1] in ['A'..'Z', 'a'..'z', '_']);
  if Result then
    for CharIdx := 2 to Length(AName) do
      if not (AName[CharIdx] in IdentChars) then
      begin
        Result := False;
        Exit;
      end;
end;

// Пробелы и комментарии ({ }, (* *), //) с позиции APos - первая позиция
// после них
function SkipBlanks(const AText: string; APos: Integer): Integer;
var
  TextLen: Integer;
begin
  TextLen := Length(AText);
  Result := APos;
  while Result <= TextLen do
  begin
    if AText[Result] <= ' ' then
      Inc(Result)
    else if AText[Result] = '{' then
    begin
      while (Result <= TextLen) and (AText[Result] <> '}') do
        Inc(Result);
      Inc(Result);
    end
    else if (AText[Result] = '(') and (Result < TextLen) and
            (AText[Result + 1] = '*') then
    begin
      Inc(Result, 2);
      while (Result < TextLen) and
            not ((AText[Result] = '*') and (AText[Result + 1] = ')')) do
        Inc(Result);
      Inc(Result, 2);
    end
    else if (AText[Result] = '/') and (Result < TextLen) and
            (AText[Result + 1] = '/') then
    begin
      while (Result <= TextLen) and not (AText[Result] in [#10, #13]) do
        Inc(Result);
    end
    else
      Exit;
  end;
end;

function DprFixProgramName(const ADpr: string; out AOldName: string;
                           out AError: string): Boolean;
var
  FileText, BaseName: string;
  KeyPos, NameStart, NameEnd: Integer;
  Stream: TFileStream;
begin
  Result := False;
  AOldName := '';
  AError := '';
  BaseName := ChangeFileExt(ExtractFileName(ADpr), '');
  if not IsPascalIdent(BaseName) then
  begin
    AError := 'имя файла "' + BaseName + '" не годится в имя программы ' +
              '(латинские буквы, цифры и _, первой не цифра)';
    Exit;
  end;

  // Файл - как есть, байт в байт: меняется только имя
  try
    Stream := TFileStream.Create(ADpr, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(FileText, Stream.Size);
      if Stream.Size > 0 then
        Stream.ReadBuffer(FileText[1], Stream.Size);
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      AError := 'не прочитан ' + ADpr + ': ' + E.Message;
      Exit;
    end;
  end;

  KeyPos := SkipBlanks(FileText, 1);
  if (CompareText(Copy(FileText, KeyPos, 7), 'program') <> 0) or
     ((KeyPos + 7 <= Length(FileText)) and
      (FileText[KeyPos + 7] in IdentChars)) then
  begin
    AError := 'в начале ' + ExtractFileName(ADpr) + ' нет строки program';
    Exit;
  end;
  NameStart := SkipBlanks(FileText, KeyPos + 7);
  NameEnd := NameStart;
  while (NameEnd <= Length(FileText)) and (FileText[NameEnd] in IdentChars) do
    Inc(NameEnd);
  if NameEnd = NameStart then
  begin
    AError := 'в ' + ExtractFileName(ADpr) + ' после program нет имени';
    Exit;
  end;

  // Регистр букв компилятору и Windows не важен
  if CompareText(Copy(FileText, NameStart, NameEnd - NameStart),
                 BaseName) = 0 then
  begin
    Result := True;
    Exit;
  end;

  AOldName := Copy(FileText, NameStart, NameEnd - NameStart);
  FileText := Copy(FileText, 1, NameStart - 1) + BaseName +
              Copy(FileText, NameEnd, MaxInt);
  try
    Stream := TFileStream.Create(ADpr, fmCreate);
    try
      Stream.WriteBuffer(FileText[1], Length(FileText));
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      AError := 'не записан ' + ADpr + ': ' + E.Message;
      AOldName := '';
      Exit;
    end;
  end;
  Result := True;
end;

end.
