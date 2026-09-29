unit UiTheme;

// ---------------------------------------------------------------------------
//  Ядро тем для своих элементов (TUiButton, TUiGroupBox, TUiScrollBar и
//  следующих): какая тема сейчас и какие у неё цвета ролей.
//
//  Модуль ни от чего в программе не зависит: им пользуются и IDE (Unit1
//  выбирает тему и передаёт сюда цвета из IDE.clr), и программы
//  пользователя - через невидимый компонент TUiTheme.
//
//  TUiTheme (кладётся на форму): Kind - Light / Dark / Custom, CustomColors
//  - цвета своей темы строками Роль=цвет, FormColors - красить ли фон и
//  шрифт форм, AutoSave - самому запоминать Kind и CustomColors в ini-файле
//  и восстанавливать их при следующем запуске. В программе пользователя он ставит тему всей программе
//  (общую, ниже). Элементы на форме, где он лежит, берут цвета у него
//  (UiThemeColorFor, UiThemeNativeFor), остальные - общие.
//
//  В IDE (UiThemeHostLocked = True) общую тему ведёт сама IDE: TUiTheme на
//  форме в конструкторе форм красит только элементы этой формы - так форма
//  пользователя видна в своей теме, а IDE своей не меняет.
//
//  Темы:
//    utLight  - как Windows. Элементы, которые это умеют, рисуют себя
//               через тему Windows (UiThemeNative); цвета ролей - для тех,
//               кто рисует сам;
//    utDark   - элементы рисуют себя сами цветами ролей;
//    utCustom - как utDark, но цвета задаёт владелец целиком.
//  UiThemeSetKind ставит тему и цвета её ролей по умолчанию. Владелец
//  может после этого заменить любые цвета (UiThemeSetColor) и один раз
//  разослать смену (UiThemeChanged).
//
//  Элементы, которым нужно знать о смене темы, записываются в список
//  (UiThemeAddClient / UiThemeRemoveClient). UiThemeChanged посылает
//  каждому UM_UITHEMECHANGED через Perform; кто его не обрабатывает -
//  просто перерисовывается.
//
//  Роли (имя - что красит):
//    Window.BG, Window.Text  - окна, панели, рамки, надписи, флажки
//    List.BG, List.Text      - деревья, списки, таблицы
//    Edit.BG, Edit.Text      - поля ввода, списки выбора
//    Button.BG, Button.HotBG, Button.DownBG, Button.Text, Button.Border
//    Group.Text, Group.Border - рамка с подписью
//    Scroll.Track, Scroll.Thumb, Scroll.ThumbHot, Scroll.Arrow
//    Grid.Lines              - линии сетки таблиц
//    Tab.BG, Tab.ActiveBG, Tab.HotBG, Tab.Text, Tab.Border - ярлычки
//                              вкладок (TUiPageControl, TUiTabControl)
//    Menu.BG, Menu.Text, Menu.HotBG, Menu.HotText, Menu.Border - своё
//                              меню (TUiMenuBar, TUiPopupMenu)
//    IconButton.HotBG        - выделение кнопки-значка под мышью: ободок
//                              вокруг подложки (TUiIconButton)
//    IconButton.BG           - подложка под значком (TUiIconButton)
//    Focus                   - рамка элемента в фокусе, кнопки для Enter
//    OffText                 - подпись выключенного элемента
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls;

type
  TUiThemeKind = (utLight, utDark, utCustom);

  // Невидимый компонент: тема программы (см. в начале модуля)
  TUiTheme = class(TComponent)
  private
    FKind: TUiThemeKind;
    FCustomColors: TStrings;
    FFormColors: Boolean;
    FColors: array of TColor;     // по ролям, как RoleDefs
    FOnChange: TNotifyEvent;
    FOldActiveFormChange: TNotifyEvent;
    FHooked: Boolean;
    FLastFormBG, FLastFormText: TColor;
    FAutoSave: Boolean;
    FIniFile: string;
    FIniSection: string;
    FRestoring: Boolean;
    procedure SetKind(Value: TUiThemeKind);
    procedure SetCustomColors(Value: TStrings);
    procedure SetFormColors(Value: Boolean);
    procedure CustomColorsChange(Sender: TObject);
    procedure Rebuild;
    procedure Apply;
    procedure PaintForms;
    procedure PaintForm(AForm: TComponent);
    procedure ActiveFormChange(Sender: TObject);
    function  CanStore: Boolean;
    function  ReadSettings: Boolean;
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Цвет роли этой темы; роль неизвестна - clNone
    function RoleColor(const ARole: string): TColor;
    // Свой цвет роли - строкой в CustomColors; действует в теме Custom
    procedure SetRoleColor(const ARole: string; AColor: TColor);
    // CustomColors из файла и в файл: строки Роль=цвет
    procedure LoadColors(const AFileName: string);
    procedure SaveColors(const AFileName: string);
    // Полное имя ini-файла AutoSave: IniFile, пустой - <программа>.ini,
    // без папки - рядом с программой
    function  IniFileName: string;
    // Записать Kind и CustomColors в ini-файл и прочитать оттуда. При
    // AutoSave это делается само: чтение - при загрузке формы, запись -
    // при каждой смене темы.
    procedure SaveSettings;
    procedure RestoreSettings;
  published
    property Kind: TUiThemeKind read FKind write SetKind default utLight;
    // Цвета темы Custom: Роль=цвет (Button.BG=$003F3F3F). Каких ролей нет -
    // те как в Dark.
    property CustomColors: TStrings read FCustomColors write SetCustomColors;
    // Фон и цвет шрифта форм программы - по теме (Window.BG, Window.Text)
    property FormColors: Boolean read FFormColors write SetFormColors
      default True;
    // Сам запоминать Kind и CustomColors между запусками (ini-файл). По
    // умолчанию включено: программе ничего не нужно делать самой.
    property AutoSave: Boolean read FAutoSave write FAutoSave default True;
    // Ini-файл для AutoSave; пустой - <программа>.ini рядом с программой
    property IniFile: string read FIniFile write FIniFile;
    // Раздел ini-файла; цвета - в разделе <IniSection>.Colors
    property IniSection: string read FIniSection write FIniSection;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

var
  // IDE: общую тему ведёт сама программа, TUiTheme её не трогает
  UiThemeHostLocked: Boolean = False;

const
  // Сообщение элементу: тема или её цвета сменились. Через Perform, в
  // очередь Windows не попадает.
  UM_UITHEMECHANGED = WM_APP + $0A10;

// Тема сейчас
function UiThemeKind: TUiThemeKind;

// Поставить тему: цвета всех ролей - её значения по умолчанию (для
// utCustom - значения utDark). ANotify - разослать смену сразу; False -
// владелец ещё заменит цвета и разошлёт сам (UiThemeChanged).
procedure UiThemeSetKind(AKind: TUiThemeKind; ANotify: Boolean = True);

// Элементы, которые умеют, рисуют себя через тему Windows: тема utLight и
// темы Windows включены
function UiThemeNative: Boolean;

// Цвет роли; роль неизвестна - clNone
function UiThemeColor(const ARole: string): TColor;

// Заменить цвет роли. Не рассылает - после серии замен UiThemeChanged.
procedure UiThemeSetColor(const ARole: string; AColor: TColor);

// Разослать смену всем записанным элементам
procedure UiThemeChanged;

procedure UiThemeAddClient(AControl: TControl);
procedure UiThemeRemoveClient(AControl: TControl);

// Роли по порядку: сколько их и имя - для редактора цветов своей темы
function UiThemeRoleCount: Integer;
function UiThemeRoleName(AIndex: Integer): string;

// Тема формы, на которой лежит элемент (TUiTheme в её компонентах); nil -
// на форме её нет, действует общая
function UiThemeFor(AControl: TControl): TUiTheme;
// Цвет роли и «рисует ли Windows» для элемента - по теме его формы, если
// она есть, иначе общие (UiThemeColor, UiThemeNative)
function UiThemeColorFor(AControl: TControl; const ARole: string): TColor;
function UiThemeNativeFor(AControl: TControl): Boolean;

implementation

uses
  Themes, Forms, IniFiles;

type
  TUiRoleDef = record
    Name: string;
    Light, Dark: TColor;
  end;

const
  // Значения по умолчанию - те же, что у ролей IDE в Unit1 (UiDefault)
  RoleDefs: array[0..31] of TUiRoleDef = (
    (Name: 'Window.BG';       Light: clBtnFace;    Dark: $00302D2D),
    (Name: 'Window.Text';     Light: clWindowText; Dark: $00DCDCDC),
    (Name: 'List.BG';         Light: clWindow;     Dark: $001E1E1E),
    (Name: 'List.Text';       Light: clWindowText; Dark: $00D4D4D4),
    (Name: 'Edit.BG';         Light: clWindow;     Dark: $003C3C3C),
    (Name: 'Edit.Text';       Light: clWindowText; Dark: $00F0F0F0),
    (Name: 'Button.BG';       Light: clBtnFace;    Dark: $003F3F3F),
    (Name: 'Button.HotBG';    Light: clBtnFace;    Dark: $00505050),
    (Name: 'Button.DownBG';   Light: clBtnShadow;  Dark: $00784F26),
    (Name: 'Button.Text';     Light: clBtnText;    Dark: $00F0F0F0),
    (Name: 'Button.Border';   Light: clBtnShadow;  Dark: $00707070),
    (Name: 'Group.Text';      Light: clWindowText; Dark: $00DCDCDC),
    (Name: 'Group.Border';    Light: clBtnShadow;  Dark: $00707070),
    (Name: 'Scroll.Track';    Light: $00F0F0F0;    Dark: $00262626),
    (Name: 'Scroll.Thumb';    Light: $00CDCDCD;    Dark: $00555555),
    (Name: 'Scroll.ThumbHot'; Light: $00A6A6A6;    Dark: $00787878),
    (Name: 'Scroll.Arrow';    Light: $00606060;    Dark: $00A0A0A0),
    (Name: 'Grid.Lines';      Light: $00F0F0F0;    Dark: $00404040),
    (Name: 'Focus';           Light: $00C0FFC0;    Dark: $00784F26),
    (Name: 'OffText';         Light: clGray;       Dark: $00808080),
    (Name: 'Tab.BG';          Light: clBtnFace;    Dark: $00302D2D),
    (Name: 'Tab.ActiveBG';    Light: clWindow;     Dark: $00784F26),
    (Name: 'Tab.HotBG';       Light: $00F0E8E0;    Dark: $00505050),
    (Name: 'Tab.Text';        Light: clWindowText; Dark: $00DCDCDC),
    (Name: 'Tab.Border';      Light: clBtnShadow;  Dark: $00707070),
    (Name: 'Menu.BG';         Light: clMenu;       Dark: $002B2B2B),
    (Name: 'Menu.Text';       Light: clMenuText;   Dark: $00DCDCDC),
    (Name: 'Menu.HotBG';      Light: clHighlight;  Dark: $00784F26),
    (Name: 'Menu.HotText';    Light: clHighlightText; Dark: clWhite),
    (Name: 'Menu.Border';     Light: clBtnShadow;  Dark: $00505050),
    (Name: 'IconButton.HotBG'; Light: $00F2DCC4;   Dark: $00606060),
    (Name: 'IconButton.BG';    Light: clBtnFace;   Dark: $00302D2D)
  );

var
  Kind: TUiThemeKind = utLight;
  Colors: array[Low(RoleDefs)..High(RoleDefs)] of TColor;
  ColorsReady: Boolean = False;
  Clients: TList = nil;
  ThemeComps: TList = nil;       // все TUiTheme программы

type
  // Доступ к защищённым Color и Font формы
  TUiFormAcc = class(TCustomForm);

function RoleIndex(const ARole: string): Integer;
var
  I: Integer;
begin
  for I := Low(RoleDefs) to High(RoleDefs) do
    if CompareText(RoleDefs[I].Name, ARole) = 0 then
    begin
      Result := I;
      Exit;
    end;
  Result := -1;
end;

procedure FillDefaults(AKind: TUiThemeKind);
var
  I: Integer;
begin
  for I := Low(RoleDefs) to High(RoleDefs) do
    if AKind = utLight then
      Colors[I] := RoleDefs[I].Light
    else
      Colors[I] := RoleDefs[I].Dark;
  ColorsReady := True;
end;

function UiThemeKind: TUiThemeKind;
begin
  Result := Kind;
end;

procedure UiThemeSetKind(AKind: TUiThemeKind; ANotify: Boolean);
begin
  Kind := AKind;
  FillDefaults(AKind);
  if ANotify then
    UiThemeChanged;
end;

function UiThemeNative: Boolean;
begin
  Result := (Kind = utLight) and ThemeServices.ThemesEnabled;
end;

function UiThemeColor(const ARole: string): TColor;
var
  I: Integer;
begin
  if not ColorsReady then
    FillDefaults(Kind);
  I := RoleIndex(ARole);
  if I < 0 then
    Result := clNone
  else
    Result := Colors[I];
end;

procedure UiThemeSetColor(const ARole: string; AColor: TColor);
var
  I: Integer;
begin
  if not ColorsReady then
    FillDefaults(Kind);
  I := RoleIndex(ARole);
  if I >= 0 then
    Colors[I] := AColor;
end;

procedure UiThemeChanged;
var
  I: Integer;
  C: TControl;
begin
  if Clients = nil then
    Exit;
  for I := Clients.Count - 1 downto 0 do
    if I < Clients.Count then
    begin
      C := TControl(Clients[I]);
      if C.Perform(UM_UITHEMECHANGED, 0, 0) = 0 then
        C.Invalidate;
    end;
end;

procedure UiThemeAddClient(AControl: TControl);
begin
  if AControl = nil then
    Exit;
  if Clients = nil then
    Clients := TList.Create;
  if Clients.IndexOf(AControl) < 0 then
    Clients.Add(AControl);
end;

procedure UiThemeRemoveClient(AControl: TControl);
begin
  if Clients <> nil then
    Clients.Remove(AControl);
end;

function UiThemeRoleCount: Integer;
begin
  Result := High(RoleDefs) - Low(RoleDefs) + 1;
end;

function UiThemeRoleName(AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < UiThemeRoleCount) then
    Result := RoleDefs[Low(RoleDefs) + AIndex].Name
  else
    Result := '';
end;

function UiThemeFor(AControl: TControl): TUiTheme;
var
  Root: TControl;
  Index: Integer;
begin
  Result := nil;
  if (ThemeComps = nil) or (ThemeComps.Count = 0) or (AControl = nil) then
    Exit;
  Root := AControl;
  while Root.Parent <> nil do
    Root := Root.Parent;
  for Index := 0 to ThemeComps.Count - 1 do
    if TUiTheme(ThemeComps[Index]).Owner = Root then
    begin
      Result := TUiTheme(ThemeComps[Index]);
      Exit;
    end;
end;

function UiThemeColorFor(AControl: TControl; const ARole: string): TColor;
var
  Theme: TUiTheme;
begin
  Theme := UiThemeFor(AControl);
  if Theme <> nil then
    Result := Theme.RoleColor(ARole)
  else
    Result := UiThemeColor(ARole);
end;

function UiThemeNativeFor(AControl: TControl): Boolean;
var
  Theme: TUiTheme;
begin
  Theme := UiThemeFor(AControl);
  if Theme <> nil then
    Result := (Theme.Kind = utLight) and ThemeServices.ThemesEnabled
  else
    Result := UiThemeNative;
end;

// ---------------------------------------------------------------------------
//  TUiTheme
// ---------------------------------------------------------------------------

constructor TUiTheme.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FKind := utLight;
  FFormColors := True;
  FLastFormBG := clNone;
  FLastFormText := clNone;
  FIniSection := 'UiTheme';
  FAutoSave := True;
  FCustomColors := TStringList.Create;
  TStringList(FCustomColors).OnChange := CustomColorsChange;
  SetLength(FColors, UiThemeRoleCount);
  if ThemeComps = nil then
    ThemeComps := TList.Create;
  ThemeComps.Add(Self);
  Rebuild;
end;

destructor TUiTheme.Destroy;
var
  Handler: TNotifyEvent;
begin
  if ThemeComps <> nil then
    ThemeComps.Remove(Self);
  // Свой обработчик смены окна - вернуть прежний, если он ещё наш
  if FHooked and (Screen <> nil) then
  begin
    Handler := Screen.OnActiveFormChange;
    if (TMethod(Handler).Code = @TUiTheme.ActiveFormChange) and
       (TMethod(Handler).Data = Self) then
      Screen.OnActiveFormChange := FOldActiveFormChange;
  end;
  FCustomColors.Free;
  inherited Destroy;
end;

// Цвета ролей этой темы: умолчания Light или Dark; у Custom поверх
// тёмных - строки CustomColors
procedure TUiTheme.Rebuild;
var
  Index, Role: Integer;
  Line, RoleName, Value: string;
  Eq: Integer;
begin
  for Index := Low(RoleDefs) to High(RoleDefs) do
    if FKind = utLight then
      FColors[Index - Low(RoleDefs)] := RoleDefs[Index].Light
    else
      FColors[Index - Low(RoleDefs)] := RoleDefs[Index].Dark;
  if FKind <> utCustom then
    Exit;
  for Index := 0 to FCustomColors.Count - 1 do
  begin
    Line := FCustomColors[Index];
    Eq := Pos('=', Line);
    if Eq = 0 then
      Continue;
    RoleName := Trim(Copy(Line, 1, Eq - 1));
    Value := Trim(Copy(Line, Eq + 1, MaxInt));
    Role := RoleIndex(RoleName);
    if (Role < 0) or (Value = '') then
      Continue;
    try
      FColors[Role - Low(RoleDefs)] := StringToColor(Value);
    except
      // строка с ошибкой в цвете - роль остаётся тёмной
    end;
  end;
end;

// Тема сменилась: в программе - общая тема и формы; в IDE (конструктор
// форм) и в Delphi - только перерисовать элементы
procedure TUiTheme.Apply;
var
  Index: Integer;
begin
  if csLoading in ComponentState then
    Exit;
  if not UiThemeHostLocked and not (csDesigning in ComponentState) then
  begin
    UiThemeSetKind(FKind, False);
    for Index := 0 to UiThemeRoleCount - 1 do
      UiThemeSetColor(UiThemeRoleName(Index), FColors[Index]);
    UiThemeChanged;
    PaintForms;
    if not FHooked and (Screen <> nil) then
    begin
      // Окна, открытые позже, - тоже по теме
      FOldActiveFormChange := Screen.OnActiveFormChange;
      Screen.OnActiveFormChange := ActiveFormChange;
      FHooked := True;
    end;
  end
  else
    UiThemeChanged;
  // AutoSave: каждую смену - в ini-файл (кроме самого восстановления)
  if FAutoSave and not FRestoring and CanStore then
    SaveSettings;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

// Фон и шрифт форм: меняются только цвета по умолчанию (clBtnFace,
// clWindowText) и прошлые цвета темы - свой цвет формы остаётся
procedure TUiTheme.PaintForm(AForm: TComponent);
var
  Form: TUiFormAcc;
begin
  if not FFormColors or not (AForm is TCustomForm) then
    Exit;
  Form := TUiFormAcc(AForm);
  if (Form.Color = clBtnFace) or (Form.Color = FLastFormBG) then
    Form.Color := RoleColor('Window.BG');
  if (Form.Font.Color = clWindowText) or (Form.Font.Color = FLastFormText) then
    Form.Font.Color := RoleColor('Window.Text');
end;

procedure TUiTheme.PaintForms;
var
  Index: Integer;
begin
  if Screen = nil then
    Exit;
  for Index := 0 to Screen.FormCount - 1 do
    PaintForm(Screen.Forms[Index]);
  FLastFormBG := RoleColor('Window.BG');
  FLastFormText := RoleColor('Window.Text');
end;

procedure TUiTheme.ActiveFormChange(Sender: TObject);
begin
  if (Screen <> nil) and (Screen.ActiveForm <> nil) then
    PaintForm(Screen.ActiveForm);
  if Assigned(FOldActiveFormChange) then
    FOldActiveFormChange(Sender);
end;

procedure TUiTheme.Loaded;
begin
  inherited Loaded;
  // Прошлая тема программы - до первой отрисовки по теме из .dfm
  if FAutoSave and CanStore then
    ReadSettings;
  Rebuild;
  Apply;
end;

// Писать и читать ini-файл можно только в работающей программе: не в
// Delphi (csDesigning) и не в конструкторе форм IDE (UiThemeHostLocked) -
// там ini-файл был бы файлом самой IDE
function TUiTheme.CanStore: Boolean;
begin
  Result := not UiThemeHostLocked and not (csDesigning in ComponentState);
end;

function TUiTheme.IniFileName: string;
begin
  Result := FIniFile;
  if Result = '' then
    Result := ChangeFileExt(ParamStr(0), '.ini')
  else if ExtractFilePath(Result) = '' then
    Result := ExtractFilePath(ParamStr(0)) + Result;
end;

procedure TUiTheme.SaveSettings;
const
  KindNames: array[TUiThemeKind] of string = ('Light', 'Dark', 'Custom');
var
  Ini: TIniFile;
  Index: Integer;
  ColorSection, Line: string;
  Eq: Integer;
begin
  ColorSection := FIniSection + '.Colors';
  try
    Ini := TIniFile.Create(IniFileName);
    try
      Ini.WriteString(FIniSection, 'Kind', KindNames[FKind]);
      // Цвета своей темы - раздел целиком заново
      Ini.EraseSection(ColorSection);
      for Index := 0 to FCustomColors.Count - 1 do
      begin
        Line := FCustomColors[Index];
        Eq := Pos('=', Line);
        if Eq > 1 then
          Ini.WriteString(ColorSection, Trim(Copy(Line, 1, Eq - 1)),
                          Trim(Copy(Line, Eq + 1, MaxInt)));
      end;
    finally
      Ini.Free;
    end;
  except
    // файл только для чтения, нет прав на папку - тема просто не
    // запомнится, программа работает дальше
  end;
end;

// Kind и CustomColors из ini-файла. Чего в файле нет - остаётся как было
// (из .dfm или из кода). Только чтение: тему ставит тот, кто вызвал.
// False - файла нет.
function TUiTheme.ReadSettings: Boolean;
var
  Ini: TIniFile;
  KindText, ColorSection: string;
  Colors: TStringList;
begin
  Result := FileExists(IniFileName);
  if not Result then
    Exit;
  ColorSection := FIniSection + '.Colors';
  FRestoring := True;
  // Цвета меняются здесь без CustomColorsChange: тема ставится один раз,
  // после чтения
  TStringList(FCustomColors).OnChange := nil;
  try
    Ini := TIniFile.Create(IniFileName);
    Colors := TStringList.Create;
    try
      if Ini.SectionExists(ColorSection) then
      begin
        Ini.ReadSectionValues(ColorSection, Colors);
        FCustomColors.Assign(Colors);
      end;
      KindText := Trim(Ini.ReadString(FIniSection, 'Kind', ''));
      if CompareText(KindText, 'Light') = 0 then
        FKind := utLight
      else if CompareText(KindText, 'Dark') = 0 then
        FKind := utDark
      else if CompareText(KindText, 'Custom') = 0 then
        FKind := utCustom;
    finally
      Colors.Free;
      Ini.Free;
    end;
  finally
    TStringList(FCustomColors).OnChange := CustomColorsChange;
    FRestoring := False;
  end;
end;

procedure TUiTheme.RestoreSettings;
begin
  if not CanStore then
    Exit;
  if ReadSettings then
  begin
    Rebuild;
    Apply;
  end;
end;

procedure TUiTheme.SetKind(Value: TUiThemeKind);
begin
  if FKind = Value then
    Exit;
  FKind := Value;
  Rebuild;
  Apply;
end;

procedure TUiTheme.SetCustomColors(Value: TStrings);
begin
  FCustomColors.Assign(Value);
end;

procedure TUiTheme.CustomColorsChange(Sender: TObject);
begin
  Rebuild;
  if FKind = utCustom then
    Apply;
end;

procedure TUiTheme.SetFormColors(Value: Boolean);
begin
  if FFormColors = Value then
    Exit;
  FFormColors := Value;
  if not UiThemeHostLocked and not (csLoading in ComponentState) and
     not (csDesigning in ComponentState) then
    PaintForms;
end;

function TUiTheme.RoleColor(const ARole: string): TColor;
var
  Role: Integer;
begin
  Role := RoleIndex(ARole);
  if Role < 0 then
    Result := clNone
  else
    Result := FColors[Role - Low(RoleDefs)];
end;

procedure TUiTheme.SetRoleColor(const ARole: string; AColor: TColor);
begin
  if RoleIndex(ARole) < 0 then
    Exit;
  FCustomColors.Values[ARole] := ColorToString(AColor);
end;

procedure TUiTheme.LoadColors(const AFileName: string);
begin
  if FileExists(AFileName) then
    FCustomColors.LoadFromFile(AFileName);
end;

procedure TUiTheme.SaveColors(const AFileName: string);
begin
  FCustomColors.SaveToFile(AFileName);
end;

initialization
  if GetClass(TUiTheme.ClassName) = nil then
    RegisterClass(TUiTheme);

finalization
  // Элементы могут уходить уже после этой секции: UiThemeRemoveClient
  // проверяет список на nil
  FreeAndNil(Clients);
  FreeAndNil(ThemeComps);
end.
