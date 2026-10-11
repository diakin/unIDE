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
    AutosaveDesktop: Boolean;     // сохранять состав проекта (editor.ini) при
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
    DsgDragTrace: Boolean;        // журнал переноса в HiLite log (отладка;
                                  // сам журнал замедляет перенос)
  end;

  // Editor Options - Margin and gutter, Code Insight. В editor.ini -
  // [Editor] (поля и номера) и [CodeInsight].
  TEdInsightOptions = record
    ShowRightMargin: Boolean;
    RightMargin: Integer;        // столбец, по которому идёт линия
    ShowGutter: Boolean;         // полоса слева: номера строк и метки
    ShowLineNumbers: Boolean;    // номера строк в полосе
    GutterWidth: Integer;        // ширина полосы; 0 - по числу цифр
    CodeCompletion: Boolean;     // список имён: Ctrl+Space и после точки
    CodeParams: Boolean;         // параметры подпрограммы после "("
    TooltipEval: Boolean;        // значение под мышью на остановке
    TooltipSymbol: Boolean;      // объявление имени под мышью
    DelayMs: Integer;            // задержка автоматических подсказок
    Colors: array[0..9] of Integer;  // CiCol*: цвета списка (TColor)
  end;

const
  EnvGridMin = 2;
  EnvGridMax = 128;

  // Цвета Code Insight - номера в TEdInsightOptions.Colors
  CiColAbstract = 0;
  CiColConstant = 1;
  CiColFunction = 2;
  CiColLabel = 3;
  CiColProcedure = 4;
  CiColProperty = 5;
  CiColType = 6;
  CiColUnit = 7;
  CiColVariable = 8;
  CiColBackground = 9;
  CiColorNames: array[0..9] of string = (
    'Abstract Symbol', 'Constant Symbol', 'Function Symbol', 'Label Symbol',
    'Procedure Symbol', 'Property Symbol', 'Type Symbol', 'Unit Symbol',
    'Variable Symbol', 'Background');
  // Фон списка «по окну»: фон и текст редактора (clWindow в Delphi)
  CiWindowColor = Integer($FF000005);
  CiDelayMin = 100;
  CiDelayMax = 1500;

procedure EnvDefaultOptions(var AOpts: TEnvOptions);
procedure EnvLoadOptions(const AIniFile: string; var AOpts: TEnvOptions);
procedure EnvSaveOptions(const AIniFile: string; const AOpts: TEnvOptions);

// ADarkBg - фон редактора тёмный: цвета Code Insight по умолчанию светлее
// (цвета Delphi на тёмном фоне не читаются). Записанные в editor.ini
// цвета берутся как есть.
procedure EdDefaultInsight(var AOpts: TEdInsightOptions; ADarkBg: Boolean);
procedure EdLoadInsight(const AIniFile: string; var AOpts: TEdInsightOptions;
                        ADarkBg: Boolean);
procedure EdSaveInsight(const AIniFile: string;
                        const AOpts: TEdInsightOptions);

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
  AOpts.DsgDragTrace := False;
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
    AOpts.DsgDragTrace := Ini.ReadBool(SecDesigner, 'DragTrace',
                                       AOpts.DsgDragTrace);
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
    Ini.WriteBool(SecDesigner, 'DragTrace', AOpts.DsgDragTrace);
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
//  Editor Options: Margin and gutter, Code Insight
// ---------------------------------------------------------------------------

const
  SecEditor = 'Editor';
  SecInsight = 'CodeInsight';
  // Цвета Delphi 7 (clRed, clGreen, clBlue, clTeal, clTeal, clNavy, clOlive,
  // clBlack, clMaroon) и светлые замены для тёмного фона; формат TColor
  // ($00BBGGRR)
  CiLightDefaults: array[0..8] of Integer = (
    $000000FF, $00008000, $00FF0000, $00808000, $00808000, $00800000,
    $00008080, $00000000, $00000080);
  CiDarkDefaults: array[0..8] of Integer = (
    $006060FF, $0060C060, $00FF9A50, $00C0C040, $00C0C040, $00FF9090,
    $0040C0C0, $00C0C0C0, $008080FF);

procedure EdDefaultInsight(var AOpts: TEdInsightOptions; ADarkBg: Boolean);
var
  ColorIdx: Integer;
begin
  AOpts.ShowRightMargin := True;
  AOpts.RightMargin := 80;
  AOpts.ShowGutter := True;
  AOpts.ShowLineNumbers := True;
  AOpts.GutterWidth := 0;
  AOpts.CodeCompletion := True;
  AOpts.CodeParams := True;
  AOpts.TooltipEval := True;
  AOpts.TooltipSymbol := True;
  AOpts.DelayMs := 500;
  for ColorIdx := 0 to 8 do
    if ADarkBg then
      AOpts.Colors[ColorIdx] := CiDarkDefaults[ColorIdx]
    else
      AOpts.Colors[ColorIdx] := CiLightDefaults[ColorIdx];
  AOpts.Colors[CiColBackground] := CiWindowColor;
end;

procedure EdLoadInsight(const AIniFile: string; var AOpts: TEdInsightOptions;
                        ADarkBg: Boolean);
var
  Ini: TIniFile;
  ColorIdx: Integer;
  KeyName: string;
begin
  EdDefaultInsight(AOpts, ADarkBg);
  if (AIniFile = '') or not FileExists(AIniFile) then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    AOpts.ShowRightMargin := Ini.ReadBool(SecEditor, 'VisibleRightMargin',
                                          AOpts.ShowRightMargin);
    AOpts.RightMargin := Ini.ReadInteger(SecEditor, 'RightMargin',
                                         AOpts.RightMargin);
    if (AOpts.RightMargin < 1) or (AOpts.RightMargin > 1024) then
      AOpts.RightMargin := 80;
    AOpts.ShowGutter := Ini.ReadBool(SecEditor, 'VisibleGutter',
                                     AOpts.ShowGutter);
    AOpts.ShowLineNumbers := Ini.ReadBool(SecEditor, 'ShowLineNumbers',
                                          AOpts.ShowLineNumbers);
    AOpts.GutterWidth := Ini.ReadInteger(SecEditor, 'GutterWidth',
                                         AOpts.GutterWidth);
    if (AOpts.GutterWidth < 0) or (AOpts.GutterWidth > 400) then
      AOpts.GutterWidth := 0;
    AOpts.CodeCompletion := Ini.ReadBool(SecInsight, 'CodeCompletion',
                                         AOpts.CodeCompletion);
    AOpts.CodeParams := Ini.ReadBool(SecInsight, 'CodeParameters',
                                     AOpts.CodeParams);
    AOpts.TooltipEval := Ini.ReadBool(SecInsight, 'TooltipEvaluation',
                                      AOpts.TooltipEval);
    AOpts.TooltipSymbol := Ini.ReadBool(SecInsight, 'TooltipSymbolInsight',
                                        AOpts.TooltipSymbol);
    AOpts.DelayMs := Ini.ReadInteger(SecInsight, 'DelayMs', AOpts.DelayMs);
    if AOpts.DelayMs < CiDelayMin then
      AOpts.DelayMs := CiDelayMin;
    if AOpts.DelayMs > CiDelayMax then
      AOpts.DelayMs := CiDelayMax;
    for ColorIdx := 0 to 9 do
    begin
      KeyName := StringReplace(CiColorNames[ColorIdx], ' ', '',
                               [rfReplaceAll]);
      AOpts.Colors[ColorIdx] := Ini.ReadInteger(SecInsight, KeyName,
                                                AOpts.Colors[ColorIdx]);
    end;
  finally
    Ini.Free;
  end;
end;

procedure EdSaveInsight(const AIniFile: string;
                        const AOpts: TEdInsightOptions);
var
  Ini: TIniFile;
  ColorIdx: Integer;
begin
  if AIniFile = '' then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    Ini.WriteBool(SecEditor, 'VisibleRightMargin', AOpts.ShowRightMargin);
    Ini.WriteInteger(SecEditor, 'RightMargin', AOpts.RightMargin);
    Ini.WriteBool(SecEditor, 'VisibleGutter', AOpts.ShowGutter);
    Ini.WriteBool(SecEditor, 'ShowLineNumbers', AOpts.ShowLineNumbers);
    Ini.WriteInteger(SecEditor, 'GutterWidth', AOpts.GutterWidth);
    Ini.WriteBool(SecInsight, 'CodeCompletion', AOpts.CodeCompletion);
    Ini.WriteBool(SecInsight, 'CodeParameters', AOpts.CodeParams);
    Ini.WriteBool(SecInsight, 'TooltipEvaluation', AOpts.TooltipEval);
    Ini.WriteBool(SecInsight, 'TooltipSymbolInsight', AOpts.TooltipSymbol);
    Ini.WriteInteger(SecInsight, 'DelayMs', AOpts.DelayMs);
    for ColorIdx := 0 to 9 do
      Ini.WriteInteger(SecInsight, StringReplace(CiColorNames[ColorIdx], ' ',
                       '', [rfReplaceAll]), AOpts.Colors[ColorIdx]);
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
