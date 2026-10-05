unit EnvOptions;

// Настройки среды - вкладки Preferences, Designer и Environment Variables
// окна IDE Options (как Tools - Environment Options в Delphi 7). Хранятся в
// editor.ini: [Preferences], [Designer], [EnvironmentVariables].
//
// Переменные окружения: «системные» - окружение программы при запуске (до
// подмен), «подмены пользователя» - пары имя=значение из editor.ini. Подмены
// ставятся в окружение самой среды (SetEnvironmentVariable): их видят
// $(VAR) и %VAR% в путях компиляторов и все программы, которые среда
// запускает (dcc32, rc, arduino-cli, собранные программы). %VAR% в значении
// подмены раскрывается по исходному окружению. Убранная подмена
// возвращает исходное значение (или убирает переменную, если её не было).

interface

uses
  Windows, SysUtils, Classes, IniFiles;

type
  TEnvOptions = record
    // Preferences
    AutosaveEditor: Boolean;      // сохранять изменённые файлы перед
                                  // сборкой, запуском и при выходе - без вопроса
    AutosaveDesktop: Boolean;     // сохранять состав проекта (.prj) при
                                  // закрытии проекта и выходе - без вопроса
    ShowCompileProgress: Boolean; // окно хода сборки
    MinimizeOnRun: Boolean;       // свернуть среду, пока работает программа
    HideDesignersOnRun: Boolean;  // спрятать конструкторы форм на время работы
    // Designer
    DsgShowGrid: Boolean;
    DsgSnapToGrid: Boolean;
    DsgGridX: Integer;
    DsgGridY: Integer;
    DsgAutoCreateForms: Boolean;  // New Form вписывает Application.CreateForm
    DsgShowCaptions: Boolean;     // имена под значками невизуальных компонентов
    DsgShowHints: Boolean;        // подсказка «Имя: Класс» над компонентом
    DsgExtendedHints: Boolean;    // в подсказке - место, размер, TabOrder
  end;

const
  EnvGridMin = 2;
  EnvGridMax = 128;

procedure EnvDefaultOptions(var AOpts: TEnvOptions);
procedure EnvLoadOptions(const AIniFile: string; var AOpts: TEnvOptions);
procedure EnvSaveOptions(const AIniFile: string; const AOpts: TEnvOptions);

// Окружение программы при запуске (до подмен): строки имя=значение, по
// алфавиту; служебные переменные Windows вида =C: не входят
procedure EnvSystemVars(AList: TStrings);
// Исходное значение переменной; AFound - была ли она
function EnvSystemValue(const AName: string; var AFound: Boolean): string;
// Подмены пользователя из editor.ini и запись их туда
procedure EnvLoadOverrides(const AIniFile: string; AList: TStrings);
procedure EnvSaveOverrides(const AIniFile: string; AList: TStrings);
// Поставить подмены AList в окружение среды. Переменные, подменённые
// прошлым вызовом и отсутствующие в AList, возвращаются к исходным.
procedure EnvApplyOverrides(AList: TStrings);

implementation

const
  SecPrefs = 'Preferences';
  SecDesigner = 'Designer';
  SecEnvVars = 'EnvironmentVariables';

var
  SystemEnv: TStringList = nil;    // окружение при запуске
  AppliedNames: TStringList = nil; // имена, которые подменены сейчас

procedure EnvDefaultOptions(var AOpts: TEnvOptions);
begin
  AOpts.AutosaveEditor := False;
  AOpts.AutosaveDesktop := False;
  AOpts.ShowCompileProgress := False;
  AOpts.MinimizeOnRun := False;
  AOpts.HideDesignersOnRun := True;   // так среда работала и раньше
  AOpts.DsgShowGrid := True;
  AOpts.DsgSnapToGrid := True;
  AOpts.DsgGridX := 8;
  AOpts.DsgGridY := 8;
  AOpts.DsgAutoCreateForms := True;   // так New Form работал и раньше
  AOpts.DsgShowCaptions := False;
  AOpts.DsgShowHints := True;
  AOpts.DsgExtendedHints := True;
end;

function GridValue(AValue: Integer): Integer;
begin
  Result := AValue;
  if Result < EnvGridMin then
    Result := EnvGridMin;
  if Result > EnvGridMax then
    Result := EnvGridMax;
end;

procedure EnvLoadOptions(const AIniFile: string; var AOpts: TEnvOptions);
var
  Ini: TIniFile;
begin
  EnvDefaultOptions(AOpts);
  if (AIniFile = '') or not FileExists(AIniFile) then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    AOpts.AutosaveEditor := Ini.ReadBool(SecPrefs, 'AutosaveEditorFiles',
                                         AOpts.AutosaveEditor);
    AOpts.AutosaveDesktop := Ini.ReadBool(SecPrefs, 'AutosaveProjectDesktop',
                                          AOpts.AutosaveDesktop);
    AOpts.ShowCompileProgress := Ini.ReadBool(SecPrefs, 'ShowCompilerProgress',
                                              AOpts.ShowCompileProgress);
    AOpts.MinimizeOnRun := Ini.ReadBool(SecPrefs, 'MinimizeOnRun',
                                        AOpts.MinimizeOnRun);
    AOpts.HideDesignersOnRun := Ini.ReadBool(SecPrefs, 'HideDesignersOnRun',
                                             AOpts.HideDesignersOnRun);
    AOpts.DsgShowGrid := Ini.ReadBool(SecDesigner, 'DisplayGrid',
                                      AOpts.DsgShowGrid);
    AOpts.DsgSnapToGrid := Ini.ReadBool(SecDesigner, 'SnapToGrid',
                                        AOpts.DsgSnapToGrid);
    AOpts.DsgGridX := GridValue(Ini.ReadInteger(SecDesigner, 'GridSizeX',
                                                AOpts.DsgGridX));
    AOpts.DsgGridY := GridValue(Ini.ReadInteger(SecDesigner, 'GridSizeY',
                                                AOpts.DsgGridY));
    AOpts.DsgAutoCreateForms := Ini.ReadBool(SecDesigner, 'AutoCreateForms',
                                             AOpts.DsgAutoCreateForms);
    AOpts.DsgShowCaptions := Ini.ReadBool(SecDesigner, 'ShowComponentCaptions',
                                          AOpts.DsgShowCaptions);
    AOpts.DsgShowHints := Ini.ReadBool(SecDesigner, 'ShowDesignerHints',
                                       AOpts.DsgShowHints);
    AOpts.DsgExtendedHints := Ini.ReadBool(SecDesigner, 'ShowExtendedHints',
                                           AOpts.DsgExtendedHints);
  finally
    Ini.Free;
  end;
end;

procedure EnvSaveOptions(const AIniFile: string; const AOpts: TEnvOptions);
var
  Ini: TIniFile;
begin
  if AIniFile = '' then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    Ini.WriteBool(SecPrefs, 'AutosaveEditorFiles', AOpts.AutosaveEditor);
    Ini.WriteBool(SecPrefs, 'AutosaveProjectDesktop', AOpts.AutosaveDesktop);
    Ini.WriteBool(SecPrefs, 'ShowCompilerProgress', AOpts.ShowCompileProgress);
    Ini.WriteBool(SecPrefs, 'MinimizeOnRun', AOpts.MinimizeOnRun);
    Ini.WriteBool(SecPrefs, 'HideDesignersOnRun', AOpts.HideDesignersOnRun);
    Ini.WriteBool(SecDesigner, 'DisplayGrid', AOpts.DsgShowGrid);
    Ini.WriteBool(SecDesigner, 'SnapToGrid', AOpts.DsgSnapToGrid);
    Ini.WriteInteger(SecDesigner, 'GridSizeX', GridValue(AOpts.DsgGridX));
    Ini.WriteInteger(SecDesigner, 'GridSizeY', GridValue(AOpts.DsgGridY));
    Ini.WriteBool(SecDesigner, 'AutoCreateForms', AOpts.DsgAutoCreateForms);
    Ini.WriteBool(SecDesigner, 'ShowComponentCaptions', AOpts.DsgShowCaptions);
    Ini.WriteBool(SecDesigner, 'ShowDesignerHints', AOpts.DsgShowHints);
    Ini.WriteBool(SecDesigner, 'ShowExtendedHints', AOpts.DsgExtendedHints);
  finally
    Ini.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Переменные окружения
// ---------------------------------------------------------------------------

procedure TakeSystemSnapshot;
var
  Block, Entry: PChar;
  Line: string;
begin
  if SystemEnv <> nil then
    Exit;
  SystemEnv := TStringList.Create;
  Block := GetEnvironmentStrings;
  if Block = nil then
    Exit;
  try
    Entry := Block;
    while Entry^ <> #0 do
    begin
      Line := string(Entry);
      // =C:=C:\... - текущие папки дисков, не переменные
      if (Line <> '') and (Line[1] <> '=') then
        SystemEnv.Add(Line);
      Inc(Entry, StrLen(Entry) + 1);
    end;
  finally
    FreeEnvironmentStrings(Block);
  end;
  SystemEnv.Sort;
end;

procedure EnvSystemVars(AList: TStrings);
begin
  TakeSystemSnapshot;
  AList.Assign(SystemEnv);
end;

function EnvSystemValue(const AName: string; var AFound: Boolean): string;
var
  LineIdx: Integer;
begin
  TakeSystemSnapshot;
  LineIdx := SystemEnv.IndexOfName(AName);
  AFound := LineIdx >= 0;
  if AFound then
    Result := Copy(SystemEnv[LineIdx], Length(SystemEnv.Names[LineIdx]) + 2,
                   MaxInt)
  else
    Result := '';
end;

procedure EnvLoadOverrides(const AIniFile: string; AList: TStrings);
var
  Ini: TIniFile;
  Names: TStringList;
  NameIdx: Integer;
begin
  AList.Clear;
  if (AIniFile = '') or not FileExists(AIniFile) then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  Names := TStringList.Create;
  try
    Ini.ReadSection(SecEnvVars, Names);
    for NameIdx := 0 to Names.Count - 1 do
      if Trim(Names[NameIdx]) <> '' then
        AList.Add(Trim(Names[NameIdx]) + '=' +
                  Ini.ReadString(SecEnvVars, Names[NameIdx], ''));
  finally
    Names.Free;
    Ini.Free;
  end;
end;

procedure EnvSaveOverrides(const AIniFile: string; AList: TStrings);
var
  Ini: TIniFile;
  LineIdx: Integer;
begin
  if AIniFile = '' then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    Ini.EraseSection(SecEnvVars);
    for LineIdx := 0 to AList.Count - 1 do
      if Trim(AList.Names[LineIdx]) <> '' then
        Ini.WriteString(SecEnvVars, Trim(AList.Names[LineIdx]),
          Copy(AList[LineIdx], Length(AList.Names[LineIdx]) + 2, MaxInt));
  finally
    Ini.Free;
  end;
end;

// %VAR% в AText - по исходному окружению; неизвестные остаются как есть
function ExpandBySystem(const AText: string): string;
var
  Rest, VarName, VarValue: string;
  StartPos, EndPos: Integer;
  Found: Boolean;
begin
  Result := '';
  Rest := AText;
  while Rest <> '' do
  begin
    StartPos := Pos('%', Rest);
    if StartPos = 0 then
      Break;
    EndPos := Pos('%', Copy(Rest, StartPos + 1, MaxInt));
    if EndPos = 0 then
      Break;
    VarName := Copy(Rest, StartPos + 1, EndPos - 1);
    VarValue := EnvSystemValue(VarName, Found);
    if Found and (VarName <> '') then
      Result := Result + Copy(Rest, 1, StartPos - 1) + VarValue
    else
      Result := Result + Copy(Rest, 1, StartPos + EndPos);
    Delete(Rest, 1, StartPos + EndPos);
  end;
  Result := Result + Rest;
end;

procedure EnvApplyOverrides(AList: TStrings);
var
  LineIdx, OldIdx: Integer;
  VarName, OldValue: string;
  Found: Boolean;
begin
  TakeSystemSnapshot;
  if AppliedNames = nil then
    AppliedNames := TStringList.Create;

  // Подмены, которых больше нет, - к исходному окружению
  for OldIdx := AppliedNames.Count - 1 downto 0 do
  begin
    VarName := AppliedNames[OldIdx];
    if AList.IndexOfName(VarName) >= 0 then
      Continue;
    OldValue := EnvSystemValue(VarName, Found);
    if Found then
      Windows.SetEnvironmentVariable(PChar(VarName), PChar(OldValue))
    else
      Windows.SetEnvironmentVariable(PChar(VarName), nil);
    AppliedNames.Delete(OldIdx);
  end;

  for LineIdx := 0 to AList.Count - 1 do
  begin
    VarName := Trim(AList.Names[LineIdx]);
    if VarName = '' then
      Continue;
    Windows.SetEnvironmentVariable(PChar(VarName),
      PChar(ExpandBySystem(Copy(AList[LineIdx],
                                Length(AList.Names[LineIdx]) + 2, MaxInt))));
    if AppliedNames.IndexOf(VarName) < 0 then
      AppliedNames.Add(VarName);
  end;
end;

initialization
  // Окружение - как при запуске, до любых подмен
  TakeSystemSnapshot;

finalization
  FreeAndNil(AppliedNames);
  FreeAndNil(SystemEnv);

end.
