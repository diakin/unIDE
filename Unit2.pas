unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls,ExtCtrls,ComCtrls,StrUtils, Menus, IniFiles,
  FileCtrl, Registry, Gauges,
  UiButton,       // кнопка, которую рисует программа (вместо TButton)
  UiGroupBox,     // рамка с подписью своими цветами (вместо TGroupBox)
  UiStdCtrls,     // флажок, переключатель и прочие свои элементы Standard
  UiEditCtrls,    // поле ввода, многострочное поле, список, список выбора
  UiComCtrls,     // вкладки, строка состояния, дерево, таблица, счётчик
  UiMenus,        // всплывающее меню по теме (TUiPopupMenu)
  UiStdDlgs,      // диалоги цвета и шрифта по теме
  FolderDlg,      // выбор папки окном Проводника вместо "Обзор папок"
  ArduinoCli,     // Compilers - Arduino: импорт путей из RQdb.ini
  // Окна сообщений по теме. Последним: его ShowMessage, MessageDlg,
  // InputQuery перекрывают одноимённые функции Dialogs
  UiDialogs;

type
  TForm2 = class(TForm)
  protected
    procedure WndProc(var Message: TMessage); override;
  private
    procedure GridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);

    procedure ButtonClick1(Sender: TObject);


  public
FLockMemo: Boolean; // НАШ СЕМАФОР БЛОКИРОВКИ ДЛЯ TMEMO
    Grid: TStringGrid;
    // ВКЛАДКА IDE COLORS: таблица цветов оформления самой программы -
    // вкладки, дерево объектов и прочее, что не относится к подсветке
    // синтаксиса. Список ролей и значения живут в Form1 (FUiColors),
    // хранятся в IDE.clr.
    UiGrid: TStringGrid;
    UiKeys: TStringList;      // ключ для каждой строки таблицы
    pnlUiBottom: TPanel;
    btnUiDefaults: TUiButton;
    lblUiHint: TLabel;
    ColorDlg: TColorDialog;
    btnOK: TUiButton;
    btnCancel: TUiButton;
    pnlBottom: TPanel; // --- ДОБАВЬТЕ ЭТУ СТРОКУ СЮДА ---
  // НАШИ НОВЫЕ ЧЕКБОКСЫ (Добавьте эти две строки в public)
    chkUseHighlight: TUiCheckBox;
    chkHotTabHighlight: TUiCheckBox;
    edtPale: TUiEdit;
    udPale: TUpDown;
    lblTabWidth: TLabel;
    cmbTabWidth: TUiComboBox;
    // ОТСТУП: своя группа Indent. Чем его делает Format text (spaces, tab,
    // none), сколько символов в уровне, подсвечивать ли полосами и насколько
    // они бледные.
    // ВКЛАДКА COMPILERS: слева список типов проектов, справа поля настроек
    // того типа, что выбран. Поля описаны таблицей CompFields и строятся
    // одинаково: подпись, путь, кнопка выбора.
    lstCompTypes: TUiListBox;
    // ИНСТРУМЕНТ СБОРКИ внутри типа: у Delphi это версия среды, у C++ -
    // MSVC, GCC или Clang. У каждого свои пути, поэтому раздел настроек
    // свой: [Compiler.<Тип>.<Инструмент>]. Какой из них берётся по
    // умолчанию, хранится в [Compiler.<Тип>] Default, а проект может
    // указать свой ключом Toolchain в .prj.
    cbTool: TUiComboBox;
    btnToolAdd, btnToolDel, btnToolFind: TUiButton;
    FCompType: string;
    pnlCompPage: TPanel;
    FCompEdits: array of TUiEdit;   // поля текущей страницы
    FCompKeys: array of string;   // ключи в editor.ini, по одному на поле
    // Поле хранит СПИСОК путей (Library path, Browsing path): у него кнопка
    // открывает окно списка (EditPathList). Папки, которых нет на этом
    // компьютере, в списке остаются - сборка их пропускает.
    FCompIsList: array of Boolean;
    // Find installed только что записал пути в editor.ini, а на экране
    // ещё прежние значения полей. Нормализация при пересборке страницы
    // вернула бы их поверх найденных - на один раз её отключаем.
    FSkipNormalize: Boolean;
    FCompSection: string;         // раздел настроек текущего типа
    btnDelphiImport: TUiButton;  // Compilers - Delphi: «Взять из Delphi»
    btnArdImport: TUiButton;     // Compilers - Arduino: «Импорт из RQdb.ini»
    // ВКЛАДКА ARDUINO (BuildArduinoTab): настройки arduino-cli, как в IDE
    // Options RQdebugger. Ключи - [Compiler.Arduino], те же, что на
    // странице Compilers - Arduino.
    FArdTab: TTabSheet;
    FArdEdits: array of TUiEdit;    // поля путей
    FArdEditKeys: array of string;  // их ключи в editor.ini
    cbArdWarnings: TUiComboBox;
    cbArdLogLevel: TUiComboBox;
    chkArdCompileVerbose: TUiCheckBox;
    chkArdUploadVerbose: TUiCheckBox;
    chkArdVerifyAfterUpload: TUiCheckBox;
    chkArdSaveBeforeBuild: TUiCheckBox;
    memArdUrls: TUiMemo;            // Additional Boards Manager URLs
    memArdCfg: TUiMemo;             // arduino-cli.yaml
    lblArdCfgState: TLabel;
    FArdLoading: Boolean;           // элементы заполняются из editor.ini
    FArdTop: TPanel;                // панель путей на листе Settings
    FArdPathBtns: array of TUiButton;  // кнопки выбора справа от путей
    // Лист Network: прокси, как в настройках Arduino IDE
    rbArdProxyNone: TUiRadioButton;
    rbArdProxyAuto: TUiRadioButton;
    rbArdProxyManual: TUiRadioButton;
    chkArdProxyAutoUrl: TUiCheckBox;
    edArdProxyAutoUrl: TUiEdit;
    rbArdProxyHttp: TUiRadioButton;
    rbArdProxySocks: TUiRadioButton;
    edArdProxyHost: TUiEdit;
    edArdProxyPort: TUiEdit;
    edArdProxyUser: TUiEdit;
    edArdProxyPassword: TUiEdit;
    // Окно списка путей (EditPathList): его элементы на время показа
    FPathList: TUiListBox;
    FPathEdit: TUiEdit;
    FPathState: TLabel;

    grpIndent: TUiGroupBox;
    lblIndent: TLabel;
    cmbIndentKind: TUiComboBox;   // spaces / tab / none
    cmbIndentSize: TUiComboBox;
    // Подсказка внизу вкладки: настройки отступа описывают будущий вид
    // файла, а текст сам собой не меняется - его надо переформатировать
    lblIndentHint: TLabel;
    chkShowLineNumbers: TUiCheckBox;
    chkShowSpaces: TUiCheckBox; // показывать пробелы и табуляции знаками
  // НАШЕ НОВОЕ ПОЛЕ ПРОСМОТРА И РЕДАКТИРОВАНИЯ ДЕТАЛЕЙ СХЕМЫ
    MemoSchemaDetails: TUiMemo;

    // НАША НОВАЯ КНОПКА СБРОСА НАСТРОЕК
    btnRestoreDefaults: TUiButton;
    pnlGroupActions: TPanel;
    cmbGroupType: TUiComboBox;
    btnAddGroup: TUiButton;
    btnDeleteGroup: TUiButton;
    // ПАНЕЛЬ ТЕМЫ - первая строка вкладки Color Scheme, как в окне
    // настроек RQdebugger: подпись, список тем (в нём же вводится имя
    // новой), Add, Delete и оформление IDE - светлое или тёмное.
    // Хранится в editor.ini, раздел [Themes].
    pnlTheme: TPanel;
    lblTheme: TPanel;
    cmbTheme: TUiComboBox;
    btnThemeAdd, btnThemeDel: TUiButton;
    // Режим IDE: Light, Dark или своя тема (Custom) из списка cmbIdeCustom;
    // Add - новая своя тема из цветов текущего режима, Del - удалить
    rbIdeLight, rbIdeDark, rbIdeCustom: TUiRadioButton;
    cmbIdeCustom: TUiComboBox;
    btnIdeCustomAdd, btnIdeCustomDel: TUiButton;
    FThemeLock: Boolean; // идёт заполнение - события не сохраняют

// НАШИ НОВЫЕ КОМПОНЕНТЫ ДЛЯ СМЕНЫ ШРИФТА
    FontDlg: TFontDialog;
    btnFontChange: TUiButton;
    // Фон пустого места редактора (BGColor в editor.ini)
    // Цвета редактора: текст (FontColor) и фон пустого места (BGColor)
    lblEditorColor: TLabel;
    pnlEditorFG: TPanel;
    pnlEditorBG: TPanel;
    // Группа Editor colors: фон редактора и цвета панели номеров строк
    grpEditorColors: TUiGroupBox;
    lblGutterColor: TLabel;
    pnlGutterFG: TPanel;
    pnlGutterBG: TPanel;
    // В редакторе показаны цвета из таблицы, ещё не сохранённые в схему
    FPreviewDirty: Boolean;
    // В таблице и в редакторе - схема •default•.clr, а не схема вкладки
    FEditDefault: Boolean;
    btnEditDefault: TUiButton;
    btnOpenClr: TUiButton;
    btnSelectSchema: TUiButton;
    FSchemaMenu: TPopupMenu;
    FSchemaFiles: TStringList; // пути схем в порядке пунктов меню
    // Кнопка в ячейке Text таблицы: цвета текста - из настроек редактора
    btnBaseColors: TUiButton;
    FGridOldProc: TWndMethod; // обработчик таблицы до подмены

    // Имя раздела схемы для каждой строки таблицы: FRowSec[номер строки].
    // Нулевой элемент - шапка, он пуст. Строки идут в том порядке, в каком
    // разделы лежат в файле .clr (Form1.SchemaSections), поэтому обращаться
    // к строке по номеру больше нельзя - только по имени раздела.
    FRowSec: array of string;

procedure btnFontChangeClick(Sender: TObject);
procedure MemoSchemaDetailsChange(Sender: TObject);
procedure btnRestoreDefaultsClick(Sender: TObject);

// ВМЕСТО FormCreate делаем публичный метод ручной настройки
    procedure InitOptions;
    procedure LayoutEditorOptions(AGroup: TUiGroupBox);
    procedure LayoutEditorColors;
    procedure ColorSwatchClick(Sender: TObject);
    procedure SetupSwatch(APanel: TPanel; const ACaption, AHint: string);
    procedure UpdateColorSwatches;
    procedure Form2Close(Sender: TObject; var Action: TCloseAction);
    procedure Form2CloseQuery(Sender: TObject; var CanClose: Boolean);
function  ConfirmSaveSchema(AForgetOnNo: Boolean): Boolean;
    procedure BeforeTabSwitch;
    procedure AfterTabSwitch;
    procedure btnEditDefaultClick(Sender: TObject);
    procedure btnOpenClrClick(Sender: TObject);
    procedure btnSelectSchemaClick(Sender: TObject);
    procedure SchemaMenuItemClick(Sender: TObject);
    procedure LoadSchemaForEdit(const APath: string);
    function  TargetSchemaFile: string;
    procedure SaveToTarget;
    procedure AskSavePreview;
    procedure UpdateEditTargetUI;
    procedure PlaceBaseColorsButton;
    procedure GridTopLeftChanged(Sender: TObject);
    procedure Form2ResizeOrShow(Sender: TObject);
    procedure btnBaseColorsClick(Sender: TObject);
    procedure GridWndProc(var Message: TMessage);
    procedure SetTextRowColors(AFg, ABg: TColor);
    procedure InitGridStructure;
    function  RowSection(ARow: Integer): string;
    function  SectionRow(const AName: string): Integer;
    function  SectionCaption(const AName: string): string;
    function  SectionHasColors(const AName: string): Boolean;
    function  IsKeywordSection(const AName: string): Boolean;
    function  IsOpSection(const AName: string): Boolean;
    function  IsMarkSection(const AName: string): Boolean;
    function  IsBcSection(const AName: string): Boolean;
    function  IsHiddenSection(const AName: string): Boolean;
    function  SectionRowByPrefix(const APrefix: string): Integer;
    function  KeywordGroupIndex(const AName: string): Integer;
    procedure RefreshGridFromForm1;
    procedure ApplyGridToForm1(SaveSchema: Boolean);
    procedure cmbGroupTypeChange(Sender: TObject);
    procedure btnAddGroupClick(Sender: TObject);
    procedure btnDeleteGroupClick(Sender: TObject);
    procedure BuildThemePanel(ATab: TWinControl);
    procedure LoadThemeList;
    procedure SaveThemeList;
    function  SwitchToSelectedTheme: Boolean;
    procedure cmbThemeChange(Sender: TObject);
    procedure cmbThemeKeyPress(Sender: TObject; var Key: Char);
    procedure btnThemeAddClick(Sender: TObject);
    procedure btnThemeDelClick(Sender: TObject);
    procedure rbIdeModeClick(Sender: TObject);
    procedure cmbIdeCustomChange(Sender: TObject);
    procedure btnIdeCustomAddClick(Sender: TObject);
    procedure btnIdeCustomDelClick(Sender: TObject);
    procedure LoadIdeCustomList;
    procedure ShowIdeMode;

procedure chkUseHighlightClick(Sender: TObject); // Наш мгновенный обработчик
procedure chkShowLineNumbersClick(Sender: TObject);
procedure chkShowSpacesClick(Sender: TObject);
procedure HideIndentHint;
procedure chkHotTabHighlightClick(Sender: TObject);
procedure cmbTabWidthChange(Sender: TObject);
procedure cmbIndentKindChange(Sender: TObject);
procedure cmbIndentSizeChange(Sender: TObject);
procedure SetIndentControls(AKind, ASize: Integer);
procedure LayoutIndentGroup;
procedure BuildUiColorsTab(ATab: TWinControl);
procedure RefreshUiGrid;
procedure UiGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
                         State: TGridDrawState);
procedure UiGridDblClick(Sender: TObject);
procedure btnUiDefaultsClick(Sender: TObject);
procedure BuildCompilersTab(ATab: TWinControl);
procedure LoadToolList(const AType: string);
procedure SaveToolList(const AType: string);
procedure cbToolChange(Sender: TObject);
procedure btnToolAddClick(Sender: TObject);
procedure btnToolDelClick(Sender: TObject);
procedure btnToolFindClick(Sender: TObject);
procedure ShowCompilerPage(const AType: string);
procedure lstCompTypesClick(Sender: TObject);
procedure CompBrowseClick(Sender: TObject);
procedure CompEditChange(Sender: TObject);
procedure CompEditExit(Sender: TObject);
procedure NormalizeCompFields;
procedure CollectUnresolved(const S: string; AList: TStrings);
procedure WarnUnresolved(ABad, ADropped: TStrings);
function  IsFileKey(const AKey: string): Boolean;
function  ExpandCompMacros(const S: string): string;
procedure CollectDelphiVars(AList: TStrings);
function  LookupEnvVar(const AName: string): string;
function  NormalizePathValue(const S: string; AIsFile, AIsList: Boolean;
                             ADropped: TStrings): string;
procedure btnDelphiImportClick(Sender: TObject);
procedure btnArdImportClick(Sender: TObject);
procedure BuildArduinoTab(ATab: TTabSheet);
procedure ArdTabLoad;
procedure ArdTabSetField(const AKey, AValue: string);
function  ArdSection: string;
procedure ArdWrite(const AKey, AValue: string);
procedure ArdEditChange(Sender: TObject);
procedure ArdBrowseClick(Sender: TObject);
procedure ArdOptionChange(Sender: TObject);
procedure ArdUrlsChange(Sender: TObject);
procedure ArdCfgLoadClick(Sender: TObject);
procedure ArdCfgWriteClick(Sender: TObject);
procedure ArdCliIdle(var ACancel: Boolean);
procedure OptionsPageChange(Sender: TObject);
procedure ArdTopResize(Sender: TObject);
procedure BuildArduinoNetwork(ATab: TTabSheet);
procedure ArdNetChange(Sender: TObject);
procedure ArdNetEnable;
function  CompFieldIdx(const AKey: string): Integer;
function  CompIniSection(const AKey: string): string;
function  CompIniKey(const AKey: string): string;
function  FindDelphiRegKey(const ARoot, ATool: string;
                           var AFoundRoot: string): string;
function  ExpandDelphiRegVars(const S, ARoot, AKey: string): string;
function  EditPathList(const ACaption: string; var AValue: string): Boolean;
function  PathExists(const APath: string): Boolean;
procedure PathUpdateState;
procedure PathListClick(Sender: TObject);
procedure PathBrowseClick(Sender: TObject);
procedure PathReplaceClick(Sender: TObject);
procedure PathAddClick(Sender: TObject);
procedure PathDeleteClick(Sender: TObject);
procedure PathDelInvalidClick(Sender: TObject);
procedure PathUpClick(Sender: TObject);
procedure PathDownClick(Sender: TObject);
procedure edtPaleChange(Sender: TObject);
procedure SetHotTabPale(AValue: Integer);
procedure SetTabWidthInCombo(AChars: Integer);
procedure GridDblClick(Sender: TObject);

  end;

var
  Form2: TForm2;

implementation

uses Unit1, ClrScheme;

{$R *.dfm}

// Раздел схемы, показанный в строке ARow; пусто - строка ничему не отвечает
function TForm2.RowSection(ARow: Integer): string;
begin
  if (ARow >= 1) and (ARow <= High(FRowSec)) then
    Result := FRowSec[ARow]
  else
    Result := '';
end;

// Строка таблицы, где показан раздел AName; 0 - такого раздела в схеме нет
function TForm2.SectionRow(const AName: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to High(FRowSec) do
    if CompareText(FRowSec[I], AName) = 0 then
    begin
      Result := I;
      Exit;
    end;
end;

function TForm2.IsKeywordSection(const AName: string): Boolean;
begin
  Result := (Length(AName) >= 8) and (Copy(AName, 1, 8) = 'Keywords');
end;

// Разделы групп операторов: Operators, Operators2, ...
function TForm2.IsOpSection(const AName: string): Boolean;
begin
  Result := (Length(AName) >= 9) and (Copy(AName, 1, 9) = 'Operators');
end;

// Дополнительные пары маркеров блочного комментария: BlockComment2 и
// дальше. Сам BlockComment - не группа, он лежит в отдельных полях Form1
// и есть всегда, поэтому ни добавить, ни удалить его нельзя.
function TForm2.IsBcSection(const AName: string): Boolean;
begin
  Result := (Length(AName) > 12) and (Copy(AName, 1, 12) = 'BlockComment');
end;

// Разделы, которых в таблице нет: Fmt* описывают синтаксис языка для
// форматировщика (слова блоков, переносы, разделы объявлений), Tag* -
// список тегов без содержимого. Править их пользователю незачем, а строк
// они добавляют много. В файле схемы они остаются: и читаются, и пишутся
// обратно, порядок разделов не меняется.
function TForm2.IsHiddenSection(const AName: string): Boolean;
begin
  Result := ((Length(AName) >= 3) and (Copy(AName, 1, 3) = 'Fmt')) or
            ((Length(AName) >= 3) and (Copy(AName, 1, 3) = 'Tag'));
end;

// Разделы групп отметки строк: LineMark, LineMark2, ...
function TForm2.IsMarkSection(const AName: string): Boolean;
begin
  Result := (Length(AName) >= 8) and (Copy(AName, 1, 8) = 'LineMark');
end;

// Первая строка таблицы, чей раздел начинается с APrefix; 0 - таких нет
function TForm2.SectionRowByPrefix(const APrefix: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to High(FRowSec) do
    if (Length(FRowSec[I]) >= Length(APrefix)) and
       (CompareText(Copy(FRowSec[I], 1, Length(APrefix)), APrefix) = 0) then
    begin
      Result := I;
      Exit;
    end;
end;

// Группа ключевых слов по имени раздела; -1 - такой группы нет.
// Ищем по имени, а не по номеру: после удаления групп имена идут не подряд.
function TForm2.KeywordGroupIndex(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  if Form1 = nil then
    Exit;
  for I := 0 to High(Form1.FScheme.KeywordGroups) do
    if (Form1.FScheme.KeywordGroups[I].Words <> nil) and
       (CompareText(Form1.FScheme.KeywordGroups[I].Name, AName) = 0) then
    begin
      Result := I;
      Exit;
    end;
end;

// Подпись раздела в первом столбце. Незнакомый раздел показывается своим
// именем из файла - таблица показывает файл, а не наоборот.
function TForm2.SectionCaption(const AName: string): string;
var
  N: Integer;
begin
  if IsOpSection(AName) then
  begin
    if AName = 'Operators' then
      Result := 'Operators'
    else
      Result := 'Operators ' + Copy(AName, 10, MaxInt);
  end
  else if AName = 'LineComment' then
    Result := 'Line Comment'
  else if AName = 'BlockComment' then
    Result := 'Block Comment'
  else if (Length(AName) > 12) and (Copy(AName, 1, 12) = 'BlockComment') then
    Result := 'Block Comment ' + Copy(AName, 13, MaxInt)
  else if AName = 'Strings' then
    Result := 'Strings'
  else if AName = 'Digits' then
    Result := 'Digits (Numbers)'
  else if AName = 'Text' then
    Result := 'Text'
  else if IsMarkSection(AName) then
  begin
    if AName = 'LineMark' then
      Result := 'Line Mark'
    else
      Result := 'Line Mark ' + Copy(AName, 9, MaxInt);
  end
  else if AName = 'SubBody' then
    Result := 'Sub Body (header line)'
  else if AName = 'Components' then
    Result := 'Components (form objects)'
  else if AName = 'SubList' then
    Result := 'Sub List (begin words)'
  else if AName = 'SubEnd' then
    Result := 'Sub End (end words)'
  else if AName = 'SubOpen' then
    Result := 'Sub Open (block words)'
  else if AName = 'SubNoBody' then
    Result := 'Sub No Body (declaration words)'
  else if AName = 'SubOpenFirst' then
    Result := 'Sub Open First (line start only)'
  else if AName = 'SubSkip' then
    Result := 'Sub Skip (line start modifiers)'
  else if AName = 'FmtOutdent' then
    Result := 'Fmt Outdent (left by one)'
  else if AName = 'FmtSection' then
    Result := 'Fmt Section (var, type, const)'
  else if AName = 'FmtClass' then
    Result := 'Fmt Class (declaration blocks)'
  else if AName = 'FmtHang' then
    Result := 'Fmt Hang (then, do, else)'
  else if AName = 'FmtStmtEnd' then
    Result := 'Fmt Stmt End (statement done)'
  else if AName = 'SubStyle' then
    Result := 'Sub Style (words/braces)'
  else if AName = 'SubScope' then
    Result := 'Sub Scope (search below)'
  else if (Length(AName) > 6) and (Copy(AName, 1, 6) = 'CUSTOM') then
  begin
    N := StrToIntDef(Copy(AName, 7, 1), 0);
    if (N >= 1) and (N <= 5) then
      Result := 'Custom Comment (' + StringOfChar('!', N) + ')'
    else
      Result := AName;
  end
  else
    Result := AName;

  Result := ' ' + Result;
end;

// Разделы SubList, SubEnd и SubStyle цветов не имеют: у них заполнен только
// скрытый столбец данных, а ячейки цвета пустые и палитру не открывают
function TForm2.SectionHasColors(const AName: string): Boolean;
begin
  Result := (AName <> '') and (AName <> 'SubList') and (AName <> 'SubEnd') and
            (AName <> 'SubStyle') and (AName <> 'SubScope') and
            (AName <> 'SubOpen') and (AName <> 'SubNoBody') and
            (AName <> 'SubOpenFirst') and (AName <> 'SubSkip') and
            (AName <> 'FmtOutdent') and (AName <> 'FmtSection') and
            (AName <> 'FmtClass') and (AName <> 'FmtHang') and
            (AName <> 'FmtStmtEnd');
end;

// Строки таблицы - разделы файла схемы, по одной на раздел, в порядке файла.
// Раньше порядок был жёстким: группы ключевых слов, потом десять постоянных
// строк. Теперь и состав, и порядок берутся из Form1.SchemaSections, а
// соответствие строка-раздел держит FRowSec.
procedure TForm2.InitGridStructure;
var
  I, R, SecCount, W: Integer;
  Sec: string;
  Bmp: TBitmap; // Временный холст для замера ширины заголовков
begin
  // В таблицу идут не все разделы: Fmt* скрыты, см. IsHiddenSection
  SecCount := 0;
  if (Form1 <> nil) and (Form1.FScheme.SchemaSections <> nil) then
    for I := 0 to Form1.FScheme.SchemaSections.Count - 1 do
      if not IsHiddenSection(Form1.FScheme.SchemaSections[I]) then
        Inc(SecCount);

  Grid.ColCount := 4;
  // Строк - по числу разделов. Схема пустая (в файле нет ни одного раздела) -
  // одна пустая строка: таблицы без строк данных в Delphi 7 не бывает,
  // RowCount должен быть больше FixedRows.
  if SecCount > 0 then
    Grid.RowCount := 1 + SecCount
  else
    Grid.RowCount := 2;

  Grid.FixedCols := 0;
  Grid.FixedRows := 1;
  Grid.DefaultRowHeight := 22;
  Grid.Options := Grid.Options + [goDrawFocusSelected];

  SetLength(FRowSec, Grid.RowCount);
  for I := 0 to High(FRowSec) do
    FRowSec[I] := '';

  // Заполнение шапки таблицы
  Grid.Cells[0, 0] := ' Syntax Element';
  Grid.Cells[1, 0] := ' Font Color';
  Grid.Cells[2, 0] := ' Background Color';
  Grid.Cells[3, 0] := ' Hidden Data Cache';

  // Подписи разделов - до замера ширины: первый столбец меряется по самой
  // длинной из них, а не по одному заголовку, как раньше. Имена разделов
  // приходят из файла, и заранее их длина неизвестна.
  R := 0;
  if (Form1 <> nil) and (Form1.FScheme.SchemaSections <> nil) then
    for I := 0 to Form1.FScheme.SchemaSections.Count - 1 do
    begin
      Sec := Form1.FScheme.SchemaSections[I];
      if IsHiddenSection(Sec) then
        Continue;
      Inc(R);
      FRowSec[R] := Sec;
      Grid.Cells[0, R] := SectionCaption(Sec);
    end;

  if SecCount = 0 then
    Grid.Cells[0, 1] := ' (no sections in scheme file)';

  // Ширина столбца = ширина его самого длинного текста + 40 пикселей.
  // Замер идёт на временном TBitmap, а не на Grid.Canvas, чтобы не дёргать
  // создание оконного хэндла раньше времени.
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(Grid.Font);
    for I := 1 to Grid.ColCount - 1 do
      Grid.ColWidths[I] := Bmp.Canvas.TextWidth(Grid.Cells[I, 0]) + 40;

    W := Bmp.Canvas.TextWidth(Grid.Cells[0, 0]);
    for I := 1 to Grid.RowCount - 1 do
      if Bmp.Canvas.TextWidth(Grid.Cells[0, I]) > W then
        W := Bmp.Canvas.TextWidth(Grid.Cells[0, I]);
    Grid.ColWidths[0] := W + 40;
  finally
    Bmp.Free;
  end;

  // Число строк могло измениться - кнопка Base colors за своей строкой
  PlaceBaseColorsButton;
end;

procedure TForm2.GridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  CellColor: TColor;
  RGBColor: Longint;
  ColorStr: string;
begin
  // Шапку таблицы (строку 0) отрисовывает сама операционная система Windows
  if ARow = 0 then Exit;

  // Раскрашиваем только столбцы выбора цвета (1 - цвет текста, 2 - цвет фона)
  if (ACol = 1) or (ACol = 2) then
  begin
    // У раздела без цветов (SubList, SubEnd, SubStyle) эти ячейки пустые
    if not SectionHasColors(RowSection(ARow)) then
    begin
      Grid.Canvas.Brush.Color := Grid.Color;
      Grid.Canvas.Brush.Style := bsSolid;
      Grid.Canvas.FillRect(Rect);
      Exit;
    end;

    // Цвет ячейки. Ноль - это настоящий clBlack, а не "не задано": раньше
    // ноль подменялся подложкой текста, и выбранный чёрный показывался не
    // тем цветом. Все ячейки заполняет RefreshGridFromForm1.
    CellColor := TColor(Grid.Objects[ACol, ARow]);
    RGBColor := ColorToRGB(CellColor);

    // 1. ЗАЛИВАЕМ ФОН ЯЧЕЙКИ ВЫБРАННЫМ ЦВЕТОМ
    Grid.Canvas.Brush.Color := CellColor;
    Grid.Canvas.Brush.Style := bsSolid;
    Grid.Canvas.FillRect(Rect);

    // 2. КОНТРАСТНЫЙ ЦВЕТ ТЕКСТА НАЗВАНИЯ ЦВЕТА - по яркости
    // (0.299 R + 0.587 G + 0.114 B, в тысячных): зелёный глаз видит ярче
    // синего, и яркость ближе к тому, как цвет выглядит, чем сумма каналов.
    // Системные цвета (clWindow и т.п.) - через ColorToRGB.
    Grid.Canvas.Font.Assign(Grid.Font);
    if (GetRValue(RGBColor) * 299 + GetGValue(RGBColor) * 587 +
        GetBValue(RGBColor) * 114) < 128000 then
      Grid.Canvas.Font.Color := clWhite  // Для темных ячеек текст белый
    else
      Grid.Canvas.Font.Color := clBlack; // Для светлых ячеек текст черный

    // 3. ОТРИСОВЫВАЕМ ТЕКСТОВОЕ НАЗВАНИЕ ЦВЕТА (например, 'clBlue' или '$00FF80FF')
    ColorStr := ColorToString(CellColor);
    Grid.Canvas.Brush.Style := bsClear; // Убираем фон вокруг самих букв
    Grid.Canvas.TextOut(Rect.Left + 6, Rect.Top + 4, ColorStr);
  end;
end;



// Буфер отрисовки у окна настроек и у всех контейнеров в нём (листы
// вкладок, панели, рамки), а также у таблиц и многострочных полей. Надписи
// (TLabel) рисует их родитель: без буфера при смене размера окна фон под
// ними стирается и рисуется заново, и надписи моргают. Так же сделано в
// главном окне (TForm1.FormCreate) и на вкладке Arduino.
procedure BufferPaintTree(AControl: TWinControl);
var
  ChildIdx: Integer;
  Child: TControl;
begin
  if (AControl is TCustomForm) or (AControl is TTabSheet) or
     (AControl is TCustomPanel) or (AControl is TCustomGroupBox) or
     (AControl is TCustomGrid) or (AControl is TCustomMemo) or
     (AControl is TScrollBox) then
    AControl.DoubleBuffered := True;
  for ChildIdx := 0 to AControl.ControlCount - 1 do
  begin
    Child := AControl.Controls[ChildIdx];
    if Child is TWinControl then
      BufferPaintTree(TWinControl(Child));
  end;
end;

procedure TForm2.InitOptions;
var
  PageControl: TPageControl;
  TabEditor, TabEdOptions, TabColors, TabDirs, TabArduino: TTabSheet;
  grpEditorOptions: TUiGroupBox; // Переменная для нашего нового групбокса
  Bmp: TBitmap;                // замер ширины текста
  W, I: Integer;
begin

FLockMemo := False; // Инициализация
  // 1. Настройка базовых параметров окна настроек
  Self.ClientWidth := 620;   // расширена под шесть контролов в Editor options
  Self.ClientHeight := 510;  // Увеличили высоту формы на 30px, чтобы компенсировать появление GroupBox
  Self.Position := poOwnerFormCenter;
  Self.Caption := 'IDE Options';
  // Окно настроек не должно уходить за редактор: цвета правятся с
  // немедленным предпросмотром, и его надо видеть
  Self.FormStyle := fsStayOnTop;
  Self.Color := clBtnFace;

  // 2. Создаем TColorDialog
  // Закрытие (Exit, крестик): вопрос о несохранённом и отмена предпросмотра
  OnClose := Form2Close;
  OnCloseQuery := Form2CloseQuery;

  ColorDlg := TUiColorDialog.Create(Self);
  ColorDlg.Options := [cdFullOpen, cdAnyColor];

  // 3. СОЗДАЕМ КОНТЕЙНЕР ВКЛАДОК (PageControl)
  PageControl := TUiPageControl.Create(Self);
  PageControl.Parent := Self;
  PageControl.Align := alClient; 
//  PageControl.BorderWidth := 4; 

  // 4. СОЗДАЕМ СТРАНИЦЫ (ВКЛАДКИ)
  //
  // Порядок вкладок задаётся порядком создания: каждая новая встаёт правее.
  TabEditor := TTabSheet.Create(Self);
  TabEditor.PageControl := PageControl;
  TabEditor.Caption := 'Color Scheme';

  TabEdOptions := TTabSheet.Create(Self);
  TabEdOptions.PageControl := PageControl;
  TabEdOptions.Caption := 'Editor Options';

  TabColors := TTabSheet.Create(Self);
  TabColors.PageControl := PageControl;
  TabColors.Caption := 'IDE colors';

  TabDirs := TTabSheet.Create(Self);
  TabDirs.PageControl := PageControl;
  TabDirs.Caption := 'Compilers';

  TabArduino := TTabSheet.Create(Self);
  TabArduino.PageControl := PageControl;
  TabArduino.Caption := 'Arduino';

// 5. ГРУППА НАСТРОЕК РЕДАКТОРА - на своей вкладке Editor Options.
  // На вкладке Color Scheme остались только таблица цветов и работа с группами.
  grpEditorOptions := TUiGroupBox.Create(Self);
  grpEditorOptions.Parent := TabEdOptions;
  grpEditorOptions.Caption := ' Editor options '; 
  grpEditorOptions.Align := alTop;       
  grpEditorOptions.Height := 40;         // Высота 40 пикселей

  // ЧЕКБОКС 1: подсветка синтаксиса
  chkUseHighlight := TUiCheckBox.Create(Self);
  chkUseHighlight.Parent := grpEditorOptions;
  chkUseHighlight.Caption := 'Syntax HiLight';
  chkUseHighlight.Left := 5;
  chkUseHighlight.Top := 16;
  chkUseHighlight.Width := 105;
  chkUseHighlight.Checked := True;
  chkUseHighlight.OnClick := chkUseHighlightClick;

  // БЛЕДНОСТЬ НАПРАВЛЯЮЩИХ, 0..100 %. К цвету полосы подмешивается фон
  // редактора: 0 - исходный насыщенный цвет, 100 - полное слияние с фоном.
  edtPale := TUiEdit.Create(Self);
  edtPale.Left := 228;
  edtPale.Top := 14;
  edtPale.Width := 32;
  edtPale.ShowHint := True;
  edtPale.Hint := 'Бледность полос отступа, %';

  udPale := TUiUpDown.Create(Self);
  // Associate - ниже, когда у поля появится родитель (группа Indent)
  udPale.Min := 0;
  udPale.Max := 100;
  udPale.Increment := 5;
  udPale.Position := 50;

  // Позицию UpDown отражает в тексте поля, поэтому ловим именно OnChange поля -
  // так один обработчик покрывает и стрелки, и ручной ввод.
  edtPale.OnChange := edtPaleChange;

  // ШИРИНА ТАБУЛЯЦИИ В СИМВОЛАХ. Отсюда считается шаг табстопов, который
  // ApplyTabStops в Unit1 переводит в твипы и отдаёт через EM_SETPARAFORMAT.
  lblTabWidth := TLabel.Create(Self);
  lblTabWidth.Parent := grpEditorOptions;
  lblTabWidth.Caption := 'Tab';
  lblTabWidth.Left := 292;
  lblTabWidth.Top := 18;

  cmbTabWidth := TUiComboBox.Create(Self);
  cmbTabWidth.Parent := grpEditorOptions;
  cmbTabWidth.Left := 318;
  cmbTabWidth.Top := 14;
  cmbTabWidth.Width := 45;
  cmbTabWidth.Style := csDropDownList;
  cmbTabWidth.Items.Add('2');
  cmbTabWidth.Items.Add('3');
  cmbTabWidth.Items.Add('4');
  cmbTabWidth.Items.Add('6');
  cmbTabWidth.Items.Add('8');
  cmbTabWidth.ItemIndex := 2; // 4 символа
  cmbTabWidth.OnChange := cmbTabWidthChange;

  // ЧЕКБОКС 3: номера строк
  // Непечатные символы: точка вместо пробела, стрелка вместо табуляции.
  // Рисуется поверх текста, файл не меняется.
  chkShowSpaces := TUiCheckBox.Create(Self);
  chkShowSpaces.Parent := grpEditorOptions;
  chkShowSpaces.Caption := 'Show spaces';
  chkShowSpaces.Top := 16;
  chkShowSpaces.Checked := False;
  chkShowSpaces.ShowHint := True;
  chkShowSpaces.Hint := 'Показывать пробелы и табуляции знаками';
  chkShowSpaces.OnClick := chkShowSpacesClick;

  chkShowLineNumbers := TUiCheckBox.Create(Self);
  chkShowLineNumbers.Parent := grpEditorOptions;
  chkShowLineNumbers.Caption := 'Show line numbers';
  chkShowLineNumbers.Left := 373;
  chkShowLineNumbers.Top := 16;
  chkShowLineNumbers.Width := 125;
  chkShowLineNumbers.Checked := True;
  chkShowLineNumbers.OnClick := chkShowLineNumbersClick;


// 1. СОЗДАЕМ ДИАЛОГ ВЫБОРА ШРИФТА
  FontDlg := TUiFontDialog.Create(Self);
  // Ограничим выбор только моноширинными шрифтами (идеально для кода) и снимем лишние эффекты
//  FontDlg.Options := [fdAnsiOnly, fdFixedPitchOnly];
 // ИСПРАВЛЕНИЕ: Добавляем флаг fdEffects. Именно он открывает скрытые поля "Цвет" и "Подчеркивание/Зачеркивание"
  // Без fdEffects: цвет текста задаётся квадратиком FG в группе Editor colors
  FontDlg.Options := [fdAnsiOnly, fdFixedPitchOnly];

  // 2. СОЗДАЕМ КНОПКУ FONT CHANGE ВНУТРИ GROUPBOX
  btnFontChange := TUiButton.Create(Self);
  btnFontChange.Parent := grpEditorOptions; // Родителем выступает сам GroupBox!
  btnFontChange.Caption := 'Font Change';
  btnFontChange.Left := 505;                // Размещаем правее чекбоксов
  btnFontChange.Top := 11;                  // Аккуратно выравниваем внутри 40px групбокса
  btnFontChange.Width := 90;
  btnFontChange.Height := 24;
  
  // Привязываем обработчик клика (напишем его в следующем шаге)
  // Объявите процедуру btnFontChangeClick(Sender: TObject); в private/public секции TForm2
  btnFontChange.OnClick := btnFontChangeClick;

  // ГРУППА INDENT - под Editor options. Здесь всё про отступы: чем их
  // делает Format text, сколько символов в уровне, подсвечивать ли их
  // полосами и насколько бледными.
  grpIndent := TUiGroupBox.Create(Self);
  grpIndent.Parent := TabEdOptions;
  grpIndent.Caption := ' Indent hilight ';
  grpIndent.Top := grpEditorOptions.Top + grpEditorOptions.Height + 1;
  grpIndent.Align := alTop;
  grpIndent.Height := 40;

  lblIndent := TLabel.Create(Self);
  lblIndent.Parent := grpIndent;
  lblIndent.Caption := 'Indent';
  lblIndent.Top := 18;

  // spaces - отступ пробелами, tab - табуляциями, none - отступов не делать
  cmbIndentKind := TUiComboBox.Create(Self);
  cmbIndentKind.Parent := grpIndent;
  cmbIndentKind.Top := 14;
  cmbIndentKind.Width := 62;
  cmbIndentKind.Style := csDropDownList;
  cmbIndentKind.Items.Add('spaces');
  cmbIndentKind.Items.Add('tab');
  cmbIndentKind.Items.Add('none');
  cmbIndentKind.ItemIndex := 0;
  cmbIndentKind.ShowHint := True;
  cmbIndentKind.Hint := 'Чем Format text делает отступы; none - не делать вовсе';
  cmbIndentKind.OnChange := cmbIndentKindChange;

  // Сколько символов в одном уровне: пробелов при spaces, табуляций при tab.
  // Полосам подсветки это число нужно всегда - в открытом файле отступы
  // могут быть любыми.
  cmbIndentSize := TUiComboBox.Create(Self);
  cmbIndentSize.Parent := grpIndent;
  cmbIndentSize.Top := 14;
  cmbIndentSize.Width := 45;
  cmbIndentSize.Style := csDropDownList;
  cmbIndentSize.Items.Add('1');
  cmbIndentSize.Items.Add('2');
  cmbIndentSize.Items.Add('3');
  cmbIndentSize.Items.Add('4');
  cmbIndentSize.Items.Add('6');
  cmbIndentSize.Items.Add('8');
  cmbIndentSize.ItemIndex := 1;
  cmbIndentSize.ShowHint := True;
  cmbIndentSize.Hint := 'Символов в одном уровне отступа';
  cmbIndentSize.OnChange := cmbIndentSizeChange;

  // Подсвечивать ли уровни полосами. Прежняя галка HotTab HiLight - она же.
  chkHotTabHighlight := TUiCheckBox.Create(Self);
  chkHotTabHighlight.Parent := grpIndent;
  chkHotTabHighlight.Caption := 'HiLight';
  chkHotTabHighlight.Top := 16;
  chkHotTabHighlight.Checked := False;
  chkHotTabHighlight.OnClick := chkHotTabHighlightClick;

  edtPale.Parent := grpIndent;
  udPale.Parent := grpIndent;
  udPale.Associate := edtPale;

  // Подсказка о переформатировании - по низу вкладки. Появляется после
  // смены режима или размера, гаснет при следующем открытии окна.
  lblIndentHint := TLabel.Create(Self);
  lblIndentHint.Parent := TabEdOptions;
  lblIndentHint.Align := alBottom;
  lblIndentHint.AutoSize := False;
  lblIndentHint.Height := 30;
  lblIndentHint.Layout := tlCenter;
  lblIndentHint.Alignment := taCenter;
  lblIndentHint.Caption :=
    'Настройки отступа применятся к тексту только после Format text';
  lblIndentHint.Font.Size := 16;
  lblIndentHint.Font.Style := [fsBold];
  lblIndentHint.Font.Color := clRed;
  lblIndentHint.Visible := False;

  // ГРУППА EDITOR COLORS - под Indent
  grpEditorColors := TUiGroupBox.Create(Self);
  grpEditorColors.Parent := TabEdOptions;
  grpEditorColors.Caption := ' Editor colors ';
  grpEditorColors.Top := grpIndent.Top + grpIndent.Height + 1;
  grpEditorColors.Align := alTop; // Top выше - встаёт под Indent
  grpEditorColors.Height := 40;

  // ЦВЕТА РЕДАКТОРА: надпись и два квадратика - цвет текста (FG, FontColor)
  // и фон пустого места (BG, BGColor). Подложка под символами - строка Text
  // в таблице схемы.
  lblEditorColor := TLabel.Create(Self);
  lblEditorColor.Parent := grpEditorColors;
  lblEditorColor.Caption := 'Editor color';
  lblEditorColor.Top := 18;

  pnlEditorFG := TPanel.Create(Self);
  SetupSwatch(pnlEditorFG, 'FG',
    'Цвет текста (FontColor в editor.ini); раздел Text схемы его перекрывает');
  pnlEditorBG := TPanel.Create(Self);
  SetupSwatch(pnlEditorBG, 'BG', 'Фон редактора (BGColor в editor.ini)');

  // ПАНЕЛЬ НОМЕРОВ СТРОК: надпись и два квадратика - цвет цифр (FG) и фон
  // (BG). Квадратик залит выбранным цветом; щелчок - выбор цвета.
  lblGutterColor := TLabel.Create(Self);
  lblGutterColor.Parent := grpEditorColors;
  lblGutterColor.Caption := 'Gutter color';
  lblGutterColor.Top := 18;

  pnlGutterFG := TPanel.Create(Self);
  SetupSwatch(pnlGutterFG, 'FG', 'Цвет номеров строк (GutterFG в editor.ini)');
  pnlGutterBG := TPanel.Create(Self);
  SetupSwatch(pnlGutterBG, 'BG', 'Фон панели номеров строк (GutterBG в editor.ini)');

  // Все элементы групп - в ряд, вплотную по ширине надписей
  LayoutEditorOptions(grpEditorOptions);
  LayoutIndentGroup;
  BuildUiColorsTab(TabColors);
  BuildCompilersTab(TabDirs);
  LayoutEditorColors;

  // Панель темы - самая верхняя на вкладке Color Scheme. Окно выше на её
  // высоту: таблице цветов место не уменьшаем.
  BuildThemePanel(TabEditor);
  Self.ClientHeight := Self.ClientHeight + pnlTheme.Height;

  // Вкладка Arduino; при переходе на неё значения перечитываются
  BuildArduinoTab(TabArduino);
  PageControl.OnChange := OptionsPageChange;

  pnlGroupActions := TPanel.Create(Self);
  pnlGroupActions.Parent := TabEditor;
  // Top до Align: так alTop ставит группу под панелью темы, а не над ней
  pnlGroupActions.Top := pnlTheme.Top + pnlTheme.Height + 1;
  pnlGroupActions.Align := alTop;
  pnlGroupActions.Height := 42;
  pnlGroupActions.BevelOuter := bvNone;
  pnlGroupActions.Caption := '';

  cmbGroupType := TUiComboBox.Create(Self);
  cmbGroupType.Parent := pnlGroupActions;
  cmbGroupType.Left := 10;
  // Шрифт задаём ДО Top: высоту списка VCL подгоняет под шрифт, и по ней
  // считается сдвиг, чтобы список встал по центру высоты кнопок
  cmbGroupType.Font.Size := 10;
  cmbGroupType.Top := 8 + (26 - cmbGroupType.Height) div 2;
  cmbGroupType.Style := csDropDownList;
  cmbGroupType.Items.Add('Keywords');
  cmbGroupType.Items.Add('Operators');
  cmbGroupType.Items.Add('Line comment');
  cmbGroupType.Items.Add('Block comment');
  cmbGroupType.Items.Add('String');
  cmbGroupType.Items.Add('Brackets'); // зарезервировано
  cmbGroupType.Items.Add('Line Mark');
  cmbGroupType.ItemIndex := 0;
  cmbGroupType.OnChange := cmbGroupTypeChange;

  // Ширина - по самому длинному пункту: текст, стрелка, рамка
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(cmbGroupType.Font);
    W := 0;
    for I := 0 to cmbGroupType.Items.Count - 1 do
      if Bmp.Canvas.TextWidth(cmbGroupType.Items[I]) > W then
        W := Bmp.Canvas.TextWidth(cmbGroupType.Items[I]);
  finally
    Bmp.Free;
  end;
  cmbGroupType.Width := W + GetSystemMetrics(SM_CXVSCROLL) + 10;

  btnAddGroup := TUiButton.Create(Self);
  btnAddGroup.Parent := pnlGroupActions;
  btnAddGroup.Left := cmbGroupType.Left + cmbGroupType.Width + 6;
  btnAddGroup.Top := 7;
  btnAddGroup.Width := 80;
  btnAddGroup.Height := 26;
  btnAddGroup.Caption := 'Add Group';
  btnAddGroup.OnClick := btnAddGroupClick;

  // Кнопки идут подряд, каждая за предыдущей: сдвинулся список - сдвинулись
  // и они
  btnDeleteGroup := TUiButton.Create(Self);
  btnDeleteGroup.Parent := pnlGroupActions;
  btnDeleteGroup.Left := btnAddGroup.Left + btnAddGroup.Width + 6;
  btnDeleteGroup.Top := 7;
  btnDeleteGroup.Width := 90;
  btnDeleteGroup.Height := 26;
  btnDeleteGroup.Caption := 'Delete Group';
  btnDeleteGroup.OnClick := btnDeleteGroupClick;

  btnRestoreDefaults := TUiButton.Create(Self);
  btnRestoreDefaults.Parent := pnlGroupActions;
  btnRestoreDefaults.Left := btnDeleteGroup.Left + btnDeleteGroup.Width + 6;
  btnRestoreDefaults.Top := 7;
  btnRestoreDefaults.Width := 105;
  btnRestoreDefaults.Height := 26;
  btnRestoreDefaults.Caption := 'Restore Defaults';
  btnRestoreDefaults.OnClick := btnRestoreDefaultsClick;

  // Правка схемы умолчаний •default•.clr и возврат к схеме вкладки
  btnEditDefault := TUiButton.Create(Self);
  btnEditDefault.Parent := pnlGroupActions;
  btnEditDefault.Left := btnRestoreDefaults.Left +
                         btnRestoreDefaults.Width + 6;
  btnEditDefault.Top := 7;
  btnEditDefault.Width := 95;
  btnEditDefault.Height := 26;
  btnEditDefault.Caption := 'Edit Default';
  btnEditDefault.OnClick := btnEditDefaultClick;

  // Второй ряд, под списком групп: работа с файлами схем
  btnOpenClr := TUiButton.Create(Self);
  btnOpenClr.Parent := pnlGroupActions;
  btnOpenClr.Left := cmbGroupType.Left;
  btnOpenClr.Top := 39;
  btnOpenClr.Width := 100;
  btnOpenClr.Height := 26;
  btnOpenClr.Caption := 'Open clr file';
  btnOpenClr.ShowHint := True;
  btnOpenClr.Hint := 'Открыть файл текущей схемы в редакторе';
  btnOpenClr.OnClick := btnOpenClrClick;

  // Выбор схемы из папки schemes: её данные попадают в таблицу как
  // заготовка, а Save пишет их в схему текущей вкладки
  btnSelectSchema := TUiButton.Create(Self);
  btnSelectSchema.Parent := pnlGroupActions;
  btnSelectSchema.Left := btnOpenClr.Left + btnOpenClr.Width + 6;
  btnSelectSchema.Top := 39;
  btnSelectSchema.Width := 110;
  btnSelectSchema.Height := 26;
  btnSelectSchema.Caption := 'Select scheme';
  btnSelectSchema.ShowHint := True;
  btnSelectSchema.Hint := 'Взять данные другой схемы за основу; Save запишет' +
                          ' их в схему текущего расширения';
  btnSelectSchema.OnClick := btnSelectSchemaClick;

  FSchemaFiles := TStringList.Create;
  FSchemaMenu := TUiPopupMenu.Create(Self);

  // Два ряда кнопок - панели нужна высота на оба
  pnlGroupActions.Height := 72;

  // Кнопки выстроены подряд - окно может оказаться уже верхнего ряда
  if btnEditDefault.Left + btnEditDefault.Width + 10 > Self.ClientWidth then
    Self.ClientWidth := btnEditDefault.Left + btnEditDefault.Width + 10;

  // 6. СОЗДАЕМ НИЖНЮЮ ПАНЕЛЬ ДЛЯ КНОПОК НА СТРАНИЦЕ EDITOR
  pnlBottom := TPanel.Create(Self);
  pnlBottom.Parent := TabEditor;       
  pnlBottom.Align := alBottom;         // Прижимаем к самому низу вкладки
  pnlBottom.Height := 42;
  pnlBottom.BevelOuter := bvNone;      
  pnlBottom.Color := clBtnFace;

 // 7. НОВОЕ: СОЗДАЕМ ПОЛЕ TMEMO ДЛЯ КЛЮЧЕВЫХ СЛОВ И МАРКЕРОВ (ВСТАНЕТ НАД КНОПКАМИ)
  MemoSchemaDetails := TUiMemo.Create(Self);
  MemoSchemaDetails.Parent := TabEditor;
  MemoSchemaDetails.Align := alBottom; // Прижимается к нижней части над кнопками
  MemoSchemaDetails.Height := 100;     // Оптимальная высота в 100 пикселей для длинных списков
  MemoSchemaDetails.ScrollBars := ssVertical; // Включаем вертикальный скроллбар
  MemoSchemaDetails.Font.Name := 'Courier New'; // Моноширинный шрифт для удобства программиста
  MemoSchemaDetails.Font.Size := 10;
  
  // Стартовый текст-подсказка для пользователя
  MemoSchemaDetails.Lines.Text := 'Выберите элемент в первом столбце таблицы для редактирования его структуры...';  

  // 7. СОЗДАЕМ ТАБЛИЦУ НА СТРАНИЦЕ EDITOR
  // Так как GroupBox (alTop) и Panel (alBottom) уже заняли свои места,
  // Grid с alClient идеально растянется ровно в пространстве МЕЖДУ ними!
  Grid := TStringGrid.Create(Self);
  Grid.Parent := TabEditor;            
  Grid.Align := alClient;              
  Grid.BorderStyle := bsSingle; 
  
  Grid.OnDrawCell := GridDrawCell;
  Grid.OnSelectCell := GridSelectCell;
  Grid.OnDblClick := GridDblClick; // выбор цвета - только по двойному клику
  Grid.OnTopLeftChanged := GridTopLeftChanged; // прокрутка - кнопку следом
  // Размер таблицы известен только на экране - кнопку ставим и там
  OnShow := Form2ResizeOrShow;
  OnResize := Form2ResizeOrShow;

  // Маленькая кнопка в правой части ячейки Text: цвет текста и подложка -
  // из настроек редактора (FontColor и BGColor, вкладка Editor Options)
  btnBaseColors := TUiButton.Create(Self);
  btnBaseColors.Parent := Grid;
  btnBaseColors.Caption := 'Base colors';
  btnBaseColors.Font.Size := 7;
  btnBaseColors.TabStop := False;
  btnBaseColors.ShowHint := True;
  btnBaseColors.Hint := 'Цвета текста - из настроек редактора (Editor Options)';
  btnBaseColors.OnClick := btnBaseColorsClick;
  btnBaseColors.Visible := False; // покажет PlaceBaseColorsButton

  // Нажатие кнопки приходит родителю - таблице - как WM_COMMAND, а таблица
  // Delphi 7 передаёт дальше только сообщения своего редактора ячейки;
  // до OnClick кнопки дело не доходило. Перехватываем сами.
  FGridOldProc := Grid.WindowProc;
  Grid.WindowProc := GridWndProc;

  // 8. РАЗМЕЩАЕМ КНОПКИ ВНУТРИ НИЖНЕЙ ПАНЕЛИ (ПРИЖАТЫ СЛЕВА)
  btnOK := TUiButton.Create(Self);
  btnOK.Parent := pnlBottom;           
  btnOK.Width := 80;
  btnOK.Height := 28;
  btnOK.Left := 10;                     
  btnOK.Top := 7;                      
  btnOK.Caption := 'Save';   // применить и записать схему; окно остаётся
  btnOK.OnClick := ButtonClick1;

  btnCancel := TUiButton.Create(Self);
  btnCancel.Parent := pnlBottom;       
  btnCancel.Width := 80;
  btnCancel.Height := 28;
  btnCancel.Left := 100;                
  btnCancel.Top := 7;                      
  btnCancel.Caption := 'Exit'; // закрыть; несохранённое - с вопросом
  btnCancel.OnClick := ButtonClick1;

  btnOK.Anchors := [akLeft, akTop];
  btnCancel.Anchors := [akLeft, akTop];    

  // Запускаем наполнение шапки и структуры нашей таблицы
  InitGridStructure;
// В самый конец процедуры TForm2.InitOptions добавьте привязку события:
  MemoSchemaDetails.OnChange := MemoSchemaDetailsChange;

 // Имитируем выбор первой строки, чтобы скрытый кэш сразу выгрузился в TMemo при старте!
  Grid.Row := 1;
  MemoSchemaDetails.Lines.Text := Grid.Cells[3, 1];  

  // Всё окно построено - буфер отрисовки у контейнеров всех вкладок.
  // Страница Compilers при смене типа строится заново внутри pnlCompPage,
  // а он уже с буфером.
  BufferPaintTree(Self);
end;


// ---------------------------------------------------------------------------
//  Панель темы
//
//  Контролы - как в окне настроек RQdebugger: подпись Color Schem, список
//  тем, Add, Delete, IDE Light и IDE Dark. Отдельное поле для имени новой
//  темы не нужно: список допускает ввод, Enter в нём - то же, что Add.
//
//  Список, выбранная тема и режим оформления хранятся в editor.ini:
//    [Themes]
//    Count=3
//    Theme_0=Classic Windows
//    Current=Dark
//    Mode=Dark
//  Цвета редактора и IDE выбор темы пока не меняет.
// ---------------------------------------------------------------------------

procedure TForm2.BuildThemePanel(ATab: TWinControl);
var
  X: Integer;
  Spc: TPanel;
begin
  pnlTheme := TPanel.Create(Self);
  pnlTheme.Parent := ATab;
  pnlTheme.Top := 0;
  pnlTheme.Align := alTop;
  // Две строки: тема редактора, под ней режим IDE (Light / Dark / Custom)
  pnlTheme.Height := 58;
  pnlTheme.BevelOuter := bvNone;
  pnlTheme.Caption := '';

  X := 10;

  // Подпись - панель, а не метка: у неё свой фон на всю высоту строки
  lblTheme := TPanel.Create(Self);
  lblTheme.Parent := pnlTheme;
  lblTheme.BevelOuter := bvNone;
  lblTheme.ParentBackground := False;
  lblTheme.Color := clBtnFace;
  lblTheme.Alignment := taCenter;
  lblTheme.Caption := 'Color Schem';
  lblTheme.SetBounds(X, 5, 80, 21);
  Inc(X, lblTheme.Width);

  cmbTheme := TUiComboBox.Create(Self);
  cmbTheme.Parent := pnlTheme;
  cmbTheme.Style := csDropDown; // выбор из списка и ввод имени новой темы
  cmbTheme.Color := clWindow;
  cmbTheme.Left := X;
  cmbTheme.Top := 5;
  cmbTheme.Width := 140;
  cmbTheme.ShowHint := True;
  cmbTheme.Hint := 'Тема. Имя новой - ввести здесь и нажать Add или Enter';
  cmbTheme.OnChange := cmbThemeChange;
  cmbTheme.OnKeyPress := cmbThemeKeyPress;
  Inc(X, cmbTheme.Width + 4);

  btnThemeAdd := TUiButton.Create(Self);
  btnThemeAdd.Parent := pnlTheme;
  btnThemeAdd.Caption := 'Add';
  btnThemeAdd.SetBounds(X, 4, 40, 23);
  btnThemeAdd.OnClick := btnThemeAddClick;
  Inc(X, btnThemeAdd.Width + 2);

  btnThemeDel := TUiButton.Create(Self);
  btnThemeDel.Parent := pnlTheme;
  btnThemeDel.Caption := 'Delete';
  btnThemeDel.SetBounds(X, 4, 50, 23);
  btnThemeDel.OnClick := btnThemeDelClick;
  Inc(X, btnThemeDel.Width);

  // Промежуток перед переключателем, как PanSpc1 в RQdebugger
  Spc := TPanel.Create(Self);
  Spc.Parent := pnlTheme;
  Spc.BevelOuter := bvNone;
  Spc.Caption := '';
  Spc.SetBounds(X, 4, 16, 23);
  Inc(X, Spc.Width);

  // Вторая строка - режим IDE. Переключатели на одной панели - одна группа.
  X := 10;
  rbIdeLight := TUiRadioButton.Create(Self);
  rbIdeLight.Parent := pnlTheme;
  rbIdeLight.Caption := 'IDE Light';
  rbIdeLight.TextColor := clRed;   // Font.Color свои элементы не берут
  rbIdeLight.SetBounds(X, 35, 75, 17);
  rbIdeLight.OnClick := rbIdeModeClick;
  Inc(X, rbIdeLight.Width + 6);

  rbIdeDark := TUiRadioButton.Create(Self);
  rbIdeDark.Parent := pnlTheme;
  rbIdeDark.Caption := 'IDE Dark';
  rbIdeDark.TextColor := clBlue;
  rbIdeDark.SetBounds(X, 35, 75, 17);
  rbIdeDark.OnClick := rbIdeModeClick;
  Inc(X, rbIdeDark.Width + 6);

  // Своя тема IDE: переключатель и список имён (в нём же вводится имя
  // новой), Add и Del
  rbIdeCustom := TUiRadioButton.Create(Self);
  rbIdeCustom.Parent := pnlTheme;
  rbIdeCustom.Caption := 'Custom';
  rbIdeCustom.SetBounds(X, 35, 62, 17);
  rbIdeCustom.OnClick := rbIdeModeClick;
  Inc(X, rbIdeCustom.Width + 2);

  cmbIdeCustom := TUiComboBox.Create(Self);
  cmbIdeCustom.Parent := pnlTheme;
  cmbIdeCustom.Style := csDropDown;
  cmbIdeCustom.SetBounds(X, 33, 140, 21);
  cmbIdeCustom.ShowHint := True;
  cmbIdeCustom.Hint := 'Своя тема IDE. Имя новой - ввести здесь и нажать Add';
  cmbIdeCustom.OnChange := cmbIdeCustomChange;
  Inc(X, cmbIdeCustom.Width + 4);

  btnIdeCustomAdd := TUiButton.Create(Self);
  btnIdeCustomAdd.Parent := pnlTheme;
  btnIdeCustomAdd.Caption := 'Add';
  btnIdeCustomAdd.ShowHint := True;
  btnIdeCustomAdd.Hint := 'Новая своя тема IDE - копия цветов текущего режима';
  btnIdeCustomAdd.SetBounds(X, 32, 40, 23);
  btnIdeCustomAdd.OnClick := btnIdeCustomAddClick;
  Inc(X, btnIdeCustomAdd.Width + 2);

  btnIdeCustomDel := TUiButton.Create(Self);
  btnIdeCustomDel.Parent := pnlTheme;
  btnIdeCustomDel.Caption := 'Del';
  btnIdeCustomDel.ShowHint := True;
  btnIdeCustomDel.Hint := 'Удалить выбранную свою тему IDE';
  btnIdeCustomDel.SetBounds(X, 32, 40, 23);
  btnIdeCustomDel.OnClick := btnIdeCustomDelClick;

  LoadThemeList;
end;

procedure TForm2.LoadThemeList;
var
  Ini: TIniFile;
  I, N: Integer;
  S, Cur: string;
  Dark: Boolean;
begin
  FThemeLock := True;
  try
    cmbTheme.Items.Clear;
    Cur := '';
    Dark := False;
    if (Form1 <> nil) and FileExists(Form1.SettingsFileName) then
    begin
      Ini := TIniFile.Create(Form1.SettingsFileName);
      try
        N := Ini.ReadInteger('Themes', 'Count', 0);
        for I := 0 to N - 1 do
        begin
          S := Trim(Ini.ReadString('Themes', 'Theme_' + IntToStr(I), ''));
          if (S <> '') and (cmbTheme.Items.IndexOf(S) < 0) then
            cmbTheme.Items.Add(S);
        end;
        Cur := Trim(Ini.ReadString('Themes', 'Current', ''));
        Dark := CompareText(Trim(Ini.ReadString('Themes', 'Mode', 'Light')),
                            'Dark') = 0;
      finally
        Ini.Free;
      end;
    end;

    // Списка ещё нет - те же три темы, с которых начинается RQdebugger
    if cmbTheme.Items.Count = 0 then
    begin
      cmbTheme.Items.Add('Classic Windows');
      cmbTheme.Items.Add('Dark');
      cmbTheme.Items.Add('NightVision');
    end;

    I := cmbTheme.Items.IndexOf(Cur);
    if I < 0 then
      I := 0;
    cmbTheme.ItemIndex := I;

    // Checked := вызывает OnClick - поэтому под FThemeLock. Режим IDE -
    // как сейчас у главного окна.
    if Form1 <> nil then
    begin
      LoadIdeCustomList;
      ShowIdeMode;
    end
    else
    begin
      rbIdeLight.Checked := not Dark;
      rbIdeDark.Checked := Dark;
    end;
  finally
    FThemeLock := False;
  end;
end;

procedure TForm2.SaveThemeList;
var
  Ini: TIniFile;
  I: Integer;
begin
  if Form1 = nil then
    Exit;
  Ini := TIniFile.Create(Form1.SettingsFileName);
  try
    // Раздел целиком: после Delete в нём не должно остаться хвоста Theme_N
    Ini.EraseSection('Themes');
    Ini.WriteInteger('Themes', 'Count', cmbTheme.Items.Count);
    for I := 0 to cmbTheme.Items.Count - 1 do
      Ini.WriteString('Themes', 'Theme_' + IntToStr(I), cmbTheme.Items[I]);
    if cmbTheme.ItemIndex >= 0 then
      Ini.WriteString('Themes', 'Current', cmbTheme.Items[cmbTheme.ItemIndex]);
    // Режим IDE - как сейчас у главного окна
    case Form1.IdeMode of
      IdeModeDark: Ini.WriteString('Themes', 'Mode', 'Dark');
      IdeModeCustom: Ini.WriteString('Themes', 'Mode', 'Custom');
    else
      Ini.WriteString('Themes', 'Mode', 'Light');
    end;
    Ini.WriteString('Themes', 'IdeCustom', Form1.IdeCustom);
  finally
    Ini.Free;
  end;
end;

// Выбор из списка. При вводе имени новой темы пункта нет (ItemIndex = -1) -
// сохранять нечего.
procedure TForm2.cmbThemeChange(Sender: TObject);
begin
  if FThemeLock or (cmbTheme.ItemIndex < 0) then
    Exit;
  SwitchToSelectedTheme;
end;

// Выбранная в списке тема - применить. Несохранённые цвета в таблице - к
// теме, которую покидаем: вопрос, как при закрытии окна (в RapidQ они
// записываются сами). Отмена - выбор возвращается на прежнюю тему, False.
function TForm2.SwitchToSelectedTheme: Boolean;
var
  Name: string;
  I: Integer;
begin
  Result := False;
  if (Form1 = nil) or (cmbTheme.ItemIndex < 0) then
    Exit;
  Name := cmbTheme.Items[cmbTheme.ItemIndex];

  if CompareText(Name, Form1.ThemeName) <> 0 then
  begin
    if not ConfirmSaveSchema(True) then
    begin
      FThemeLock := True;
      try
        I := cmbTheme.Items.IndexOf(Form1.ThemeName);
        if I >= 0 then
          cmbTheme.ItemIndex := I;
      finally
        FThemeLock := False;
      end;
      Exit;
    end;
    FPreviewDirty := False;
  end;

  SaveThemeList;
  if CompareText(Name, Form1.ThemeName) <> 0 then
  begin
    Form1.ApplyTheme(Name);
    // Правится •default•.clr - его и показать, уже с цветами темы
    if FEditDefault then
      Form1.LoadSchemaFileForEdit(Form1.DefaultSchemaFile);
    // Таблицы и образцы окна - по цветам новой темы
    if Grid <> nil then
      RefreshGridFromForm1;
    if UiGrid <> nil then
      RefreshUiGrid;
    UpdateColorSwatches;
  end;
  Result := True;
end;

// Enter в списке - добавить введённое имя, как Enter в поле RQdebugger
procedure TForm2.cmbThemeKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    btnThemeAddClick(btnThemeAdd);
  end;
end;

procedure TForm2.btnThemeAddClick(Sender: TObject);
var
  Name: string;
  I: Integer;
begin
  Name := Trim(cmbTheme.Text);
  if Name = '' then
  begin
    ShowMessage('1290:Введите имя темы в поле списка');
    Exit;
  end;

  I := cmbTheme.Items.IndexOf(Name);
  if I >= 0 then
  begin
    FThemeLock := True;
    try
      cmbTheme.ItemIndex := I;
    finally
      FThemeLock := False;
    end;
    SwitchToSelectedTheme;
    ShowMessage('1304:Тема "' + Name + '" уже есть в списке - выбрана она');
    Exit;
  end;

  FThemeLock := True;
  try
    I := cmbTheme.Items.Add(Name);
    cmbTheme.ItemIndex := I;
  finally
    FThemeLock := False;
  end;
  // Новая тема сразу выбрана: пока у неё нет своих цветов, видны основные;
  // правка под ней пишется в её цвета (@Тема)
  SwitchToSelectedTheme;
end;

procedure TForm2.btnThemeDelClick(Sender: TObject);
var
  I: Integer;
  Name: string;
begin
  I := cmbTheme.ItemIndex;
  if I < 0 then
    I := cmbTheme.Items.IndexOf(Trim(cmbTheme.Text));
  if I < 0 then
  begin
    ShowMessage('1330:Темы "' + Trim(cmbTheme.Text) + '" нет в списке');
    Exit;
  end;
  if cmbTheme.Items.Count = 1 then
  begin
    ShowMessage('1335:Последнюю тему удалить нельзя - список не может быть пустым');
    Exit;
  end;

  Name := cmbTheme.Items[I];
  if CompareText(Name, BaseThemeName) = 0 then
  begin
    ShowMessage('1342:"' + Name + '" - основная тема: её цвета записаны в ' +
                'схемах без @, удалить её нельзя');
    Exit;
  end;
  if MessageDlg('1346:Удалить тему "' + Name + '" из списка?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  FThemeLock := True;
  try
    cmbTheme.Items.Delete(I);
    if I >= cmbTheme.Items.Count then
      I := cmbTheme.Items.Count - 1;
    cmbTheme.ItemIndex := I;
  finally
    FThemeLock := False;
  end;
  // Строки удалённой темы (@Тема) в файлах схем остаются - они просто не
  // используются, пока тему с тем же именем не заведут снова
  SwitchToSelectedTheme;
end;

// Режим IDE: Light / Dark / своя тема - цвета самой IDE (окна, панели,
// списки, поля, логи) и вид своих элементов. Отдельно от темы редактора:
// её выбирает список слева.
procedure TForm2.rbIdeModeClick(Sender: TObject);
var
  Mode, I: Integer;
  CName: string;
begin
  if FThemeLock or (Form1 = nil) then
    Exit;
  CName := '';
  if rbIdeCustom.Checked then
  begin
    Mode := IdeModeCustom;
    if cmbIdeCustom.ItemIndex < 0 then
    begin
      // Своих тем ещё нет - первая, из цветов текущего режима
      if cmbIdeCustom.Items.Count = 0 then
      begin
        Form1.UiCustomAdd('Custom 1');
        LoadIdeCustomList;
      end;
      I := cmbIdeCustom.Items.IndexOf(Trim(cmbIdeCustom.Text));
      if I < 0 then
        I := 0;
      FThemeLock := True;
      try
        cmbIdeCustom.ItemIndex := I;
      finally
        FThemeLock := False;
      end;
    end;
    if cmbIdeCustom.ItemIndex >= 0 then
      CName := cmbIdeCustom.Items[cmbIdeCustom.ItemIndex];
  end
  else if rbIdeDark.Checked then
    Mode := IdeModeDark
  else
    Mode := IdeModeLight;

  if (Mode <> Form1.IdeMode) or
     ((Mode = IdeModeCustom) and (CompareText(CName, Form1.IdeCustom) <> 0)) then
  begin
    Form1.ApplyIdeMode(Mode, CName);
    // Своей темы не нашлось - главное окно выбрало другой режим
    ShowIdeMode;
    // Вкладка IDE colors показывает цвета выбранного режима
    if UiGrid <> nil then
      RefreshUiGrid;
  end;
  SaveThemeList;
end;

// Имена своих тем IDE - в список; выбрана включённая
procedure TForm2.LoadIdeCustomList;
var
  Was: Boolean;
begin
  if Form1 = nil then
    Exit;
  Was := FThemeLock;
  FThemeLock := True;
  try
    Form1.UiCustomNames(cmbIdeCustom.Items);
    cmbIdeCustom.ItemIndex := cmbIdeCustom.Items.IndexOf(Form1.IdeCustom);
    btnIdeCustomDel.Enabled := cmbIdeCustom.Items.Count > 0;
  finally
    FThemeLock := Was;
  end;
end;

// Переключатели - по режиму главного окна
procedure TForm2.ShowIdeMode;
var
  Was: Boolean;
begin
  if Form1 = nil then
    Exit;
  Was := FThemeLock;
  FThemeLock := True;
  try
    case Form1.IdeMode of
      IdeModeDark: rbIdeDark.Checked := True;
      IdeModeCustom:
        begin
          rbIdeCustom.Checked := True;
          cmbIdeCustom.ItemIndex :=
            cmbIdeCustom.Items.IndexOf(Form1.IdeCustom);
        end;
    else
      rbIdeLight.Checked := True;
    end;
  finally
    FThemeLock := Was;
  end;
end;

// Выбрали свою тему в списке - она и включается. При вводе имени новой
// пункта нет (ItemIndex = -1) - ждём Add.
procedure TForm2.cmbIdeCustomChange(Sender: TObject);
begin
  if FThemeLock or (cmbIdeCustom.ItemIndex < 0) then
    Exit;
  if rbIdeCustom.Checked then
    rbIdeModeClick(rbIdeCustom)
  else
    rbIdeCustom.Checked := True;     // OnClick включит её
end;

// Новая своя тема: имя из списка (пусто - Custom N), цвета - копия
// текущего режима. Сразу включается - её цвета правятся на вкладке IDE
// colors.
procedure TForm2.btnIdeCustomAddClick(Sender: TObject);
var
  CName: string;
  N: Integer;
begin
  if Form1 = nil then
    Exit;
  CName := Trim(cmbIdeCustom.Text);
  if CName = '' then
  begin
    N := 1;
    repeat
      CName := 'Custom ' + IntToStr(N);
      Inc(N);
    until cmbIdeCustom.Items.IndexOf(CName) < 0;
  end;
  if cmbIdeCustom.Items.IndexOf(CName) < 0 then
    if not Form1.UiCustomAdd(CName) then
    begin
      ShowMessage('Имя своей темы IDE не подходит: пустое или со знаком "=".');
      Exit;
    end;
  LoadIdeCustomList;
  FThemeLock := True;
  try
    cmbIdeCustom.ItemIndex := cmbIdeCustom.Items.IndexOf(CName);
  finally
    FThemeLock := False;
  end;
  if rbIdeCustom.Checked then
    rbIdeModeClick(rbIdeCustom)
  else
    rbIdeCustom.Checked := True;
end;

// Удалить выбранную свою тему. Была включена - режим Dark.
procedure TForm2.btnIdeCustomDelClick(Sender: TObject);
var
  CName: string;
begin
  if (Form1 = nil) or (cmbIdeCustom.ItemIndex < 0) then
    Exit;
  CName := cmbIdeCustom.Items[cmbIdeCustom.ItemIndex];
  if UiMessageBox(PChar('Удалить свою тему IDE "' + CName + '"?'),
       'IDE Options', MB_YESNO or MB_ICONQUESTION) <> IDYES then
    Exit;
  Form1.UiCustomDelete(CName);
  LoadIdeCustomList;
  ShowIdeMode;
  if UiGrid <> nil then
    RefreshUiGrid;
  SaveThemeList;
end;

procedure TForm2.ButtonClick1(Sender: TObject);
begin
  if Sender = btnCancel then
  begin
    Self.Close;
    Exit;
  end;

  if Sender = btnOK then
  begin
    // Таблица - в Form1 и в файл схемы. Раньше выгрузка была здесь своя,
    // вторым списком тех же строк; теперь путь один - ApplyGridToForm1.
    if Form1 <> nil then
    begin
      ApplyGridToForm1(True);
      FPreviewDirty := False;
    end;
    // Окно остаётся открытым: Save - применить и записать схему
  end;
end;

// Окно закрывается. Если изменения не записаны (ответ "Нет") или в
// схема активной вкладки берётся заново из файла - показанные для
// предпросмотра цвета пропадают.
// Вопрос о несохранённой схеме. Да - записать (как кнопка Save), Нет -
// оставить как есть, Отмена - False, продолжать не надо.
//
// AForgetOnNo: при выходе из ПРОГРАММЫ ответ "Нет" снимает признак
// правки, иначе Form2Close на закрытии приложения ещё раз перечитал бы
// схему. При закрытии самого окна признак нужно сохранить: по нему
// Form2Close возвращает цвета вкладки из файла, убирая предпросмотр.
function TForm2.ConfirmSaveSchema(AForgetOnNo: Boolean): Boolean;
begin
  Result := True;
  if not FPreviewDirty or (Form1 = nil) then
    Exit;

  case MessageDlg('1408:Сохранить изменения цветовой схемы в файл ' +
                  ExtractFileName(TargetSchemaFile) + '?',
                  mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
    mrYes:
      ButtonClick1(btnOK); // тот же путь, что у Save
    mrNo:
      if AForgetOnNo then
        FPreviewDirty := False;
  else
    Result := False;
  end;
end;

// Закрытие окна (кнопка Exit, крестик): есть несохранённые изменения
// схемы - спросить. Нет - закрываемся, Form2Close откатит цвета.
procedure TForm2.Form2CloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := ConfirmSaveSchema(False);
end;

procedure TForm2.Form2Close(Sender: TObject; var Action: TCloseAction);
begin
  // Поле могли оставить с курсором внутри - тогда OnExit не сработал, и в
  // editor.ini осталось бы то, что набрано, с макросами и файлами вместо
  // папок
  NormalizeCompFields;

  // В редакторе цвета без Save или схема умолчаний - вернуть схему вкладки
  if (FPreviewDirty or FEditDefault) and (Form1 <> nil) then
    Form1.ReloadActiveClrSchema;
  FPreviewDirty := False;
  FEditDefault := False;
  UpdateEditTargetUI;
end;

// Редактор переключается на другую вкладку, окно настроек открыто.
// Если изменения не записаны (Save) - спросить, записать ли их в схему
// прежней вкладки. Ответ "нет" - цвета пропадут: новая вкладка загрузит
// свою схему из файла.
procedure TForm2.BeforeTabSwitch;
begin
  AskSavePreview;
end;

// Вкладка сменилась: таблица и флажки - под её схему
procedure TForm2.AfterTabSwitch;
begin
  if Form1 = nil then
    Exit;
  FPreviewDirty := False;
  // Вкладка загрузила свою схему - правка умолчаний закончена
  FEditDefault := False;
  UpdateEditTargetUI;
  RefreshGridFromForm1;
  chkUseHighlight.Checked := Form1.FUseSyntaxHighlight;
end;

// Файл, в который пишет Save: •default•.clr в режиме Edit Default, иначе
// схема активной вкладки
function TForm2.TargetSchemaFile: string;
begin
  if FEditDefault then
    Result := Form1.DefaultSchemaFile
  else
    Result := Form1.ActiveSchemaFile;
end;

procedure TForm2.SaveToTarget;
begin
  if Form1 = nil then
    Exit;
  if FEditDefault then
    Form1.SaveClrSchemaTo(Form1.DefaultSchemaFile)
  else
    // Схема вкладки: файла может ещё не быть - он создастся
    Form1.SaveActiveClrSchema;
end;

// Изменения есть, Save не нажат - спросить, записать ли их в файл цели
procedure TForm2.AskSavePreview;
begin
  if not FPreviewDirty or (Form1 = nil) then
    Exit;
  FPreviewDirty := False;
  if MessageDlg('1492:Сохранить изменения цветовой схемы в файл ' +
                ExtractFileName(TargetSchemaFile) + '?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    ApplyGridToForm1(True);
end;

// Заголовок окна и надпись кнопки - по тому, какая схема в таблице
// Заголовок окна: какая схема сейчас в таблице. У схемы вкладки это её
// расширение, взятое из имени файла схемы (bas.clr -> *.bas).
procedure TForm2.UpdateEditTargetUI;
var
  S: string;
begin
  if Form1 = nil then
  begin
    Caption := 'IDE Options';
    Exit;
  end;

  if FEditDefault then
  begin
    Caption := 'IDE Options - Color scheme ' +
               ExtractFileName(Form1.DefaultSchemaFile);
    if btnEditDefault <> nil then
      btnEditDefault.Caption := 'Edit Current';
  end
  else
  begin
    S := ChangeFileExt(ExtractFileName(TargetSchemaFile), '');
    if S <> '' then
      Caption := 'IDE Options - Color scheme *.' + S
    else
      Caption := 'IDE Options';
    if btnEditDefault <> nil then
      btnEditDefault.Caption := 'Edit Default';
  end;
end;

// Открыть файл схемы, которая сейчас в таблице, вкладкой редактора.
//
// Несохранённые изменения сначала предлагается записать: иначе в редакторе
// окажется файл без них, а Save из этого окна потом их перезапишет.
procedure TForm2.btnOpenClrClick(Sender: TObject);
var
  Path: string;
begin
  if Form1 = nil then
    Exit;
  AskSavePreview;

  Path := TargetSchemaFile;
  if not FileExists(Path) then
  begin
    ShowMessage('1545:Файл схемы ещё не создан: ' + Path + #13#10 +
                'Нажмите Save - он будет записан.');
    Exit;
  end;

  Form1.OpenNamedFile(Path);
end;

// Данные схемы из файла APath - в таблицу и в редактор, как заготовка.
//
// Куда пойдёт Save, это не меняет: файлом-целью остаётся схема вкладки
// (или •default•.clr в режиме Edit Default). Если файла схемы для текущего
// расширения ещё нет, Save его создаст.
procedure TForm2.LoadSchemaForEdit(const APath: string);
begin
  if Form1 = nil then
    Exit;
  AskSavePreview;
  Form1.LoadSchemaFileForEdit(APath);
  // Данные чужие, в файле цели их ещё нет
  FPreviewDirty := True;
  UpdateEditTargetUI;
  RefreshGridFromForm1;
end;

// Select scheme: список файлов схем из папки schemes рядом с кнопкой
procedure TForm2.btnSelectSchemaClick(Sender: TObject);
var
  Dir, Name: string;
  SR: TSearchRec;
  It: TMenuItem;
  P: TPoint;
  I: Integer;
begin
  if Form1 = nil then
    Exit;

  Dir := ExtractFilePath(Form1.ActiveSchemaFile);
  FSchemaFiles.Clear;
  FSchemaMenu.Items.Clear;

  if FindFirst(Dir + '*.clr', faAnyFile - faDirectory, SR) = 0 then
  try
    repeat
      FSchemaFiles.Add(Dir + SR.Name);
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
  FSchemaFiles.Sort;

  if FSchemaFiles.Count = 0 then
  begin
    ShowMessage('1598:В папке ' + Dir + ' нет файлов схем (*.clr)');
    Exit;
  end;

  for I := 0 to FSchemaFiles.Count - 1 do
  begin
    Name := ExtractFileName(FSchemaFiles[I]);
    It := TMenuItem.Create(FSchemaMenu);
    It.Caption := Name;
    It.Tag := I;
    It.RadioItem := True;
    It.Checked := CompareText(FSchemaFiles[I], TargetSchemaFile) = 0;
    It.OnClick := SchemaMenuItemClick;
    FSchemaMenu.Items.Add(It);
  end;

  P := btnSelectSchema.ClientToScreen(Point(0, btnSelectSchema.Height));
  FSchemaMenu.Popup(P.X, P.Y);
end;

procedure TForm2.SchemaMenuItemClick(Sender: TObject);
var
  I: Integer;
begin
  I := (Sender as TMenuItem).Tag;
  if (I < 0) or (I >= FSchemaFiles.Count) then
    Exit;
  LoadSchemaForEdit(FSchemaFiles[I]);
end;

// Edit Default: в таблицу и в редактор - схема •default•.clr, Save будет
// писать в неё. Повторное нажатие (Edit Current) - обратно к схеме вкладки.
procedure TForm2.btnEditDefaultClick(Sender: TObject);
begin
  if Form1 = nil then
    Exit;

  // Несохранённые цвета прежней цели - спросить до смены
  AskSavePreview;

  if not FEditDefault then
  begin
    Form1.LoadSchemaFileForEdit(Form1.DefaultSchemaFile);
    FEditDefault := True;
  end
  else
  begin
    Form1.ReloadActiveClrSchema;
    FEditDefault := False;
  end;

  FPreviewDirty := False;
  UpdateEditTargetUI;
  RefreshGridFromForm1;
end;

// Таблица - в поля Form1. Строки разбираются по имени раздела: их порядок
// задаёт файл схемы, и считать его постоянным нельзя.
procedure TForm2.ApplyGridToForm1(SaveSchema: Boolean);
var
  R, G, CIdx: Integer;
  Sec: string;
begin
  if (Form1 = nil) or (Grid = nil) then
    Exit;

  for R := 1 to Grid.RowCount - 1 do
  begin
    Sec := RowSection(R);
    if Sec = '' then
      Continue;

    if IsKeywordSection(Sec) then
    begin
      G := KeywordGroupIndex(Sec);
      if G >= 0 then
      begin
        Form1.FScheme.KeywordGroups[G].FgColor := TColor(Grid.Objects[1, R]);
        Form1.FScheme.KeywordGroups[G].BgColor := TColor(Grid.Objects[2, R]);
        Form1.FScheme.KeywordGroups[G].Words.CommaText := Grid.Cells[3, R];
      end;
    end
    else if IsOpSection(Sec) then
    begin
      G := Form1.FScheme.OpGroupIndex(Sec);
      if G >= 0 then
      begin
        Form1.FScheme.OpGroups[G].FgColor := TColor(Grid.Objects[1, R]);
        Form1.FScheme.OpGroups[G].BgColor := TColor(Grid.Objects[2, R]);
        // Строка данных группы - набор её символов
        Form1.FScheme.SetOpChars(G, Grid.Cells[3, R]);
      end;
    end
    // Маркер как есть, без Trim: в схеме заголовки помечены (SchemaHeadMark
    // в Unit1), и пробелы в маркере, в том числе по краям, допустимы
    else if Sec = 'LineComment' then
    begin
      Form1.FScheme.FLcFG := TColor(Grid.Objects[1, R]);
      Form1.FScheme.FLcBG := TColor(Grid.Objects[2, R]);
      Form1.FScheme.FLineCommentMarker := Grid.Cells[3, R];
    end
    else if Sec = 'BlockComment' then
    begin
      Form1.FScheme.FBcFG := TColor(Grid.Objects[1, R]);
      Form1.FScheme.FBcBG := TColor(Grid.Objects[2, R]);
      // Разбор вручную: у DelimitedText кавычка служебная, и питоновское
      // """ """ превратилось бы в пустую строку
      SplitMarkers(Grid.Cells[3, R], Form1.FScheme.FBlockCommentStart,
                         Form1.FScheme.FBlockCommentEnd);
    end
    // Дополнительные пары маркеров: BlockComment2 и дальше
    else if (Length(Sec) > 12) and (Copy(Sec, 1, 12) = 'BlockComment') then
    begin
      G := Form1.FScheme.BcExtraIndex(Sec);
      if G >= 0 then
      begin
        Form1.FScheme.FBcExtra[G].FgColor := TColor(Grid.Objects[1, R]);
        Form1.FScheme.FBcExtra[G].BgColor := TColor(Grid.Objects[2, R]);
        // Одного маркера мало - пара выключается
        SplitMarkers(Grid.Cells[3, R], Form1.FScheme.FBcExtra[G].StartMark,
                           Form1.FScheme.FBcExtra[G].EndMark);
      end;
    end
    else if Sec = 'Strings' then
    begin
      Form1.FScheme.FStrFG := TColor(Grid.Objects[1, R]);
      Form1.FScheme.FStrBG := TColor(Grid.Objects[2, R]);
      Form1.FScheme.FStringMarker := Grid.Cells[3, R];
    end
    else if Sec = 'Digits' then
    begin
      Form1.FScheme.FDgFG := TColor(Grid.Objects[1, R]);
      Form1.FScheme.FDgBG := TColor(Grid.Objects[2, R]);
      // Формы записи чисел разбираются и при предпросмотре: раньше это
      // делалось только по кнопке Save
      Form1.FScheme.ParseDigitFormats(Trim(Grid.Cells[3, R]));
    end
    else if (Length(Sec) > 6) and (Copy(Sec, 1, 6) = 'CUSTOM') then
    begin
      CIdx := StrToIntDef(Copy(Sec, 7, 1), 0);
      if (CIdx >= 1) and (CIdx <= 5) then
      begin
        Form1.FScheme.FCustomFG[CIdx] := TColor(Grid.Objects[1, R]);
        Form1.FScheme.FCustomBG[CIdx] := TColor(Grid.Objects[2, R]);
      end;
    end
    else if IsMarkSection(Sec) then
    begin
      G := Form1.FScheme.MarkGroupIndex(Sec);
      if (G >= 0) and (Form1.FScheme.MarkGroups[G].Words <> nil) then
      begin
        Form1.FScheme.MarkGroups[G].FgColor := TColor(Grid.Objects[1, R]);
        Form1.FScheme.MarkGroups[G].BgColor := TColor(Grid.Objects[2, R]);
        SetWordsByComma(Form1.FScheme.MarkGroups[G].Words, Grid.Cells[3, R]);
      end;
    end
    // Строка раздела есть в таблице - значит раздел есть и в схеме
    else if Sec = 'SubBody' then
    begin
      Form1.FScheme.FSubBodyFG := TColor(Grid.Objects[1, R]);
      Form1.FScheme.FSubBodyBG := TColor(Grid.Objects[2, R]);
      Form1.FScheme.FSubBodyHasColors := True;
    end
    // Имена компонентов: только цвета, список собирается по .dfm и тексту
    else if Sec = 'Components' then
    begin
      Form1.FScheme.FCompFG := TColor(Grid.Objects[1, R]);
      Form1.FScheme.FCompBG := TColor(Grid.Objects[2, R]);
      Form1.FScheme.FCompHasColors := True;
    end
    else if Sec = 'SubList' then
      SetWordsByComma(Form1.FScheme.FSubWords, Grid.Cells[3, R], True)
    else if Sec = 'SubEnd' then
      SetWordsByComma(Form1.FScheme.FSubEndWords, Grid.Cells[3, R], True)
    else if Sec = 'SubOpen' then
      SetWordsByComma(Form1.FScheme.FSubOpenWords, Grid.Cells[3, R], True)
    else if Sec = 'SubNoBody' then
      SetWordsByComma(Form1.FScheme.FSubNoBodyWords, Grid.Cells[3, R], True)
    else if Sec = 'SubOpenFirst' then
      SetWordsByComma(Form1.FScheme.FSubOpenFirst, Grid.Cells[3, R], True)
    else if Sec = 'SubSkip' then
      SetWordsByComma(Form1.FScheme.FSubSkip, Grid.Cells[3, R], True)
    else if Sec = 'FmtOutdent' then
      SetWordsByComma(Form1.FScheme.FFmtOutdent, Grid.Cells[3, R], True)
    else if Sec = 'FmtSection' then
      SetWordsByComma(Form1.FScheme.FFmtSection, Grid.Cells[3, R], True)
    else if Sec = 'FmtClass' then
      SetWordsByComma(Form1.FScheme.FFmtClass, Grid.Cells[3, R], True)
    else if Sec = 'FmtHang' then
      SetWordsByComma(Form1.FScheme.FFmtHang, Grid.Cells[3, R], True)
    else if Sec = 'FmtStmtEnd' then
      SetWordsByComma(Form1.FScheme.FFmtStmtEnd, Grid.Cells[3, R], True)
    else if Sec = 'SubStyle' then
      Form1.FScheme.FSubBraces := CompareText(Trim(Grid.Cells[3, R]), 'braces') = 0
    else if Sec = 'SubScope' then
      Form1.FScheme.FSubScope := Trim(Grid.Cells[3, R]);
  end;

  // Основной текст (раздел Text схемы): цвет текста и подложка под символами.
  // Цвет перекрывает FontColor из editor.ini; фон пустого места редактора -
  // отдельно, кнопка BG Color. Через ApplyEditorLook: правка цвета шрифта
  // тоже взводит Modified. Раздела в схеме нет - цвета остаются из editor.ini.
  R := SectionRow('Text');
  if R > 0 then
    Form1.ApplyEditorLook(nil, TColor(Grid.Objects[1, R]),
                          TColor(Grid.Objects[2, R]));

  Form1.FUseSyntaxHighlight := chkUseHighlight.Checked;
  if SaveSchema then
    SaveToTarget;
end;

// Поля Form1 - в таблицу. Строки и их порядок задаёт InitGridStructure по
// списку разделов файла схемы.
procedure TForm2.RefreshGridFromForm1;
var
  R, G, CIdx: Integer;
  Sec: string;
begin
  if (Form1 = nil) or (Grid = nil) then
    Exit;

  InitGridStructure;

  for R := 1 to Grid.RowCount - 1 do
  begin
    // Строка могла достаться от прежней схемы - чистим её целиком
    Grid.Objects[1, R] := nil;
    Grid.Objects[2, R] := nil;
    Grid.Cells[3, R] := '';

    Sec := RowSection(R);
    if Sec = '' then
      Continue;

    if IsKeywordSection(Sec) then
    begin
      G := KeywordGroupIndex(Sec);
      if G >= 0 then
      begin
        Grid.Objects[1, R] := TObject(Form1.FScheme.KeywordGroups[G].FgColor);
        Grid.Objects[2, R] := TObject(Form1.FScheme.KeywordGroups[G].BgColor);
        Grid.Cells[3, R] := Form1.FScheme.KeywordGroups[G].Words.CommaText;
      end;
    end
    else if IsOpSection(Sec) then
    begin
      G := Form1.FScheme.OpGroupIndex(Sec);
      if G >= 0 then
      begin
        Grid.Objects[1, R] := TObject(Form1.FScheme.OpGroups[G].FgColor);
        Grid.Objects[2, R] := TObject(Form1.FScheme.OpGroups[G].BgColor);
        Grid.Cells[3, R] := Form1.FScheme.OpCharsStr(G);
      end;
    end
    else if Sec = 'LineComment' then
    begin
      Grid.Objects[1, R] := TObject(Form1.FScheme.FLcFG);
      Grid.Objects[2, R] := TObject(Form1.FScheme.FLcBG);
      Grid.Cells[3, R] := Form1.FScheme.FLineCommentMarker;
    end
    else if Sec = 'BlockComment' then
    begin
      Grid.Objects[1, R] := TObject(Form1.FScheme.FBcFG);
      Grid.Objects[2, R] := TObject(Form1.FScheme.FBcBG);
      Grid.Cells[3, R] := Form1.FScheme.FBlockCommentStart + ' ' +
                         Form1.FScheme.FBlockCommentEnd;
    end
    // Дополнительные пары маркеров: BlockComment2 и дальше
    else if (Length(Sec) > 12) and (Copy(Sec, 1, 12) = 'BlockComment') then
    begin
      G := Form1.FScheme.BcExtraIndex(Sec);
      if G >= 0 then
      begin
        Grid.Objects[1, R] := TObject(Form1.FScheme.FBcExtra[G].FgColor);
        Grid.Objects[2, R] := TObject(Form1.FScheme.FBcExtra[G].BgColor);
        Grid.Cells[3, R] := Form1.FScheme.FBcExtra[G].StartMark + ' ' +
                           Form1.FScheme.FBcExtra[G].EndMark;
      end;
    end
    else if Sec = 'Strings' then
    begin
      Grid.Objects[1, R] := TObject(Form1.FScheme.FStrFG);
      Grid.Objects[2, R] := TObject(Form1.FScheme.FStrBG);
      Grid.Cells[3, R] := Form1.FScheme.FStringMarker;
    end
    else if Sec = 'Digits' then
    begin
      Grid.Objects[1, R] := TObject(Form1.FScheme.FDgFG);
      Grid.Objects[2, R] := TObject(Form1.FScheme.FDgBG);
      // Формы записи чисел: 0x, &H, exp, suffix=...
      Grid.Cells[3, R] := Form1.FScheme.BuildDigitFormats;
    end
    else if (Length(Sec) > 6) and (Copy(Sec, 1, 6) = 'CUSTOM') then
    begin
      CIdx := StrToIntDef(Copy(Sec, 7, 1), 0);
      if (CIdx >= 1) and (CIdx <= 5) then
      begin
        Grid.Objects[1, R] := TObject(Form1.FScheme.FCustomFG[CIdx]);
        Grid.Objects[2, R] := TObject(Form1.FScheme.FCustomBG[CIdx]);
        Grid.Cells[3, R] := StringOfChar('!', CIdx);
      end;
    end
    else if Sec = 'Text' then
    begin
      // Базовые цвета редактора
      Grid.Objects[1, R] := TObject(Form1.RichEdit1.Font.Color);
      Grid.Objects[2, R] := TObject(Form1.FScheme.FTextBG);
      Grid.Cells[3, R] := 'auto';
    end
    else if IsMarkSection(Sec) then
    begin
      G := Form1.FScheme.MarkGroupIndex(Sec);
      if (G >= 0) and (Form1.FScheme.MarkGroups[G].Words <> nil) then
      begin
        Grid.Objects[1, R] := TObject(Form1.FScheme.MarkGroups[G].FgColor);
        Grid.Objects[2, R] := TObject(Form1.FScheme.MarkGroups[G].BgColor);
        Grid.Cells[3, R] := WordsByComma(Form1.FScheme.MarkGroups[G].Words);
      end;
    end
    else if Sec = 'SubBody' then
    begin
      Grid.Objects[1, R] := TObject(Form1.FScheme.FSubBodyFG);
      Grid.Objects[2, R] := TObject(Form1.FScheme.FSubBodyBG);
      Grid.Cells[3, R] := 'auto';
    end
    else if Sec = 'Components' then
    begin
      Grid.Objects[1, R] := TObject(Form1.FScheme.FCompFG);
      Grid.Objects[2, R] := TObject(Form1.FScheme.FCompBG);
      Grid.Cells[3, R] := 'auto';
    end
    else if Sec = 'SubList' then
      Grid.Cells[3, R] := WordsByComma(Form1.FScheme.FSubWords)
    else if Sec = 'SubEnd' then
      Grid.Cells[3, R] := WordsByComma(Form1.FScheme.FSubEndWords)
    else if Sec = 'SubOpen' then
      Grid.Cells[3, R] := WordsByComma(Form1.FScheme.FSubOpenWords)
    else if Sec = 'SubNoBody' then
      Grid.Cells[3, R] := WordsByComma(Form1.FScheme.FSubNoBodyWords)
    else if Sec = 'SubOpenFirst' then
      Grid.Cells[3, R] := WordsByComma(Form1.FScheme.FSubOpenFirst)
    else if Sec = 'SubSkip' then
      Grid.Cells[3, R] := WordsByComma(Form1.FScheme.FSubSkip)
    else if Sec = 'FmtOutdent' then
      Grid.Cells[3, R] := WordsByComma(Form1.FScheme.FFmtOutdent)
    else if Sec = 'FmtSection' then
      Grid.Cells[3, R] := WordsByComma(Form1.FScheme.FFmtSection)
    else if Sec = 'FmtClass' then
      Grid.Cells[3, R] := WordsByComma(Form1.FScheme.FFmtClass)
    else if Sec = 'FmtHang' then
      Grid.Cells[3, R] := WordsByComma(Form1.FScheme.FFmtHang)
    else if Sec = 'FmtStmtEnd' then
      Grid.Cells[3, R] := WordsByComma(Form1.FScheme.FFmtStmtEnd)
    else if Sec = 'SubStyle' then
    begin
      if Form1.FScheme.FSubBraces then
        Grid.Cells[3, R] := 'braces'
      else
        Grid.Cells[3, R] := 'words';
    end
    else if Sec = 'SubScope' then
      Grid.Cells[3, R] := Form1.FScheme.FSubScope;
  end;

  UpdateColorSwatches;
  UpdateEditTargetUI; // вкладка могла смениться - заголовок окна тоже

  if cmbGroupType <> nil then
    cmbGroupType.ItemIndex := 0;
  Grid.Row := 1;
  MemoSchemaDetails.Lines.Text := Grid.Cells[3, 1];
  Grid.Invalidate;
end;

procedure TForm2.cmbGroupTypeChange(Sender: TObject);
var
  TargetRow: Integer;
  Sec: string;
begin
  if (Form1 = nil) or (Grid = nil) or (cmbGroupType.ItemIndex <= 0) then
    Exit;

  case cmbGroupType.ItemIndex of
    1: Sec := 'Operators';
    2: Sec := 'LineComment';
    3: Sec := 'BlockComment';
    4: Sec := 'Strings';
    6: Sec := 'LineMark';
  else
    Exit; // Brackets - зарезервировано, строки пока нет
  end;

  // У групп имя раздела может быть с номером - берём первую группу типа
  if (Sec = 'Operators') or (Sec = 'LineMark') then
    TargetRow := SectionRowByPrefix(Sec)
  else
    TargetRow := SectionRow(Sec);

  if TargetRow <= 0 then
  begin
    ShowMessage('1999:Section "' + Sec + '" is not defined in this scheme file.');
    Exit;
  end;

  Grid.Row := TargetRow;
  MemoSchemaDetails.Lines.Text := Grid.Cells[3, TargetRow];
end;

// Новая группа. Добавлять можно три типа: ключевые слова, операторы и
// отметку строк - у каждого свои цвета и своя строка данных. Имя нового
// раздела - первое свободное: Keywords3, Operators2, LineMark2 и так далее.
procedure TForm2.btnAddGroupClick(Sender: TObject);
var
  I, N, Place, Cnt: Integer;
  Prefix, NewName: string;
begin
  if (Form1 = nil) or (Grid = nil) then
    Exit;

  case cmbGroupType.ItemIndex of
    0: Prefix := 'Keywords';
    1: Prefix := 'Operators';
    3: Prefix := 'BlockComment';
    6: Prefix := 'LineMark';
  else
    ShowMessage('2024:Only Keywords, Operators, Block Comment and Line Mark ' +
                'can be added as groups.');
    Exit;
  end;

  ApplyGridToForm1(False);

  // Имя без номера занимают старые схемы (Operators, LineMark) - тогда
  // нумерация начинается с двойки. У ключевых слов номер есть всегда, а у
  // блочного комментария имя без номера занято основной парой.
  if (Prefix <> 'Keywords') and (Prefix <> 'BlockComment') and
     (Form1.FScheme.SchemaSections.IndexOf(Prefix) < 0) and
     (((Prefix = 'Operators') and (Form1.FScheme.OpGroupIndex(Prefix) < 0)) or
      ((Prefix = 'LineMark') and (Form1.FScheme.MarkGroupIndex(Prefix) < 0))) then
    NewName := Prefix
  else
  begin
    N := 1;
    while True do
    begin
      NewName := Prefix + IntToStr(N);
      if (KeywordGroupIndex(NewName) < 0) and
         (Form1.FScheme.OpGroupIndex(NewName) < 0) and
         (Form1.FScheme.MarkGroupIndex(NewName) < 0) and
         (Form1.FScheme.BcExtraIndex(NewName) < 0) and
         (Form1.FScheme.SchemaSections.IndexOf(NewName) < 0) then
        Break;
      Inc(N);
    end;
  end;

  if Prefix = 'Keywords' then
  begin
    Cnt := Length(Form1.FScheme.KeywordGroups);
    SetLength(Form1.FScheme.KeywordGroups, Cnt + 1);
    Form1.FScheme.KeywordGroups[Cnt].Name := NewName;
    Form1.FScheme.KeywordGroups[Cnt].FgColor := clBlue;
    Form1.FScheme.KeywordGroups[Cnt].BgColor := Form1.FScheme.FTextBG;
    Form1.FScheme.KeywordGroups[Cnt].Words := TStringList.Create;
    Form1.FScheme.KeywordGroups[Cnt].Words.Sorted := True;
    Form1.FScheme.KeywordGroups[Cnt].Words.Duplicates := dupIgnore;
    Form1.FScheme.KeywordGroups[Cnt].Words.CaseSensitive := False;
  end
  else if Prefix = 'BlockComment' then
  begin
    // Маркеры пустые: их вписывают в поле справа, через пробел - '/* */'
    Cnt := Length(Form1.FScheme.FBcExtra);
    SetLength(Form1.FScheme.FBcExtra, Cnt + 1);
    Form1.FScheme.FBcExtra[Cnt].Name := NewName;
    Form1.FScheme.FBcExtra[Cnt].StartMark := '';
    Form1.FScheme.FBcExtra[Cnt].EndMark := '';
    Form1.FScheme.FBcExtra[Cnt].FgColor := Form1.FScheme.FBcFG;
    Form1.FScheme.FBcExtra[Cnt].BgColor := Form1.FScheme.FBcBG;
  end
  else if Prefix = 'Operators' then
  begin
    // Набор символов пустой: его вписывают в поле справа от таблицы
    Cnt := Length(Form1.FScheme.OpGroups);
    SetLength(Form1.FScheme.OpGroups, Cnt + 1);
    Form1.FScheme.OpGroups[Cnt].Name := NewName;
    Form1.FScheme.OpGroups[Cnt].Chars := [];
    Form1.FScheme.OpGroups[Cnt].FgColor := clRed;
    Form1.FScheme.OpGroups[Cnt].BgColor := Form1.FScheme.FTextBG;
  end
  else
  begin
    Cnt := Length(Form1.FScheme.MarkGroups);
    SetLength(Form1.FScheme.MarkGroups, Cnt + 1);
    Form1.FScheme.MarkGroups[Cnt].Name := NewName;
    Form1.FScheme.MarkGroups[Cnt].FgColor := clNone;
    Form1.FScheme.MarkGroups[Cnt].BgColor := clYellow;
    Form1.FScheme.MarkGroups[Cnt].Words := TStringList.Create;
    Form1.FScheme.MarkGroups[Cnt].Words.Sorted := True;
    Form1.FScheme.MarkGroups[Cnt].Words.Duplicates := dupIgnore;
    Form1.FScheme.MarkGroups[Cnt].Words.CaseSensitive := False;
  end;

  // Место раздела в файле - за последним разделом того же типа; таких ещё
  // нет - в конец
  Place := Form1.FScheme.SchemaSections.Count;
  for I := 0 to Form1.FScheme.SchemaSections.Count - 1 do
    if (Length(Form1.FScheme.SchemaSections[I]) >= Length(Prefix)) and
       (Copy(Form1.FScheme.SchemaSections[I], 1, Length(Prefix)) = Prefix) then
      Place := I + 1;
  Form1.FScheme.SchemaSections.Insert(Place, NewName);

  RefreshGridFromForm1;
  Grid.Row := SectionRow(NewName);
  MemoSchemaDetails.Lines.Text := Grid.Cells[3, Grid.Row];
  FPreviewDirty := True; // группа добавлена, в файл ещё не записана
end;

// Удаляется группа ВЫБРАННОЙ строки - ключевых слов, операторов или отметки
procedure TForm2.btnDeleteGroupClick(Sender: TObject);
var
  I, GroupIndex, Cnt: Integer;
  Sec: string;
begin
  if (Form1 = nil) or (Grid = nil) then
    Exit;

  Sec := RowSection(Grid.Row);
  if not (IsKeywordSection(Sec) or IsOpSection(Sec) or IsMarkSection(Sec) or
          IsBcSection(Sec)) then
  begin
    ShowMessage('2129:Select a Keywords, Operators, Block Comment or Line Mark ' +
                'row before deleting it.');
    Exit;
  end;

  ApplyGridToForm1(False);

  if IsKeywordSection(Sec) then
  begin
    GroupIndex := KeywordGroupIndex(Sec);
    Cnt := Length(Form1.FScheme.KeywordGroups);
    if GroupIndex < 0 then
      Exit;
    Form1.FScheme.KeywordGroups[GroupIndex].Words.Free;
    for I := GroupIndex to Cnt - 2 do
      Form1.FScheme.KeywordGroups[I] := Form1.FScheme.KeywordGroups[I + 1];
    SetLength(Form1.FScheme.KeywordGroups, Cnt - 1);
  end
  else if IsBcSection(Sec) then
  begin
    GroupIndex := Form1.FScheme.BcExtraIndex(Sec);
    Cnt := Length(Form1.FScheme.FBcExtra);
    if GroupIndex < 0 then
      Exit;
    for I := GroupIndex to Cnt - 2 do
      Form1.FScheme.FBcExtra[I] := Form1.FScheme.FBcExtra[I + 1];
    SetLength(Form1.FScheme.FBcExtra, Cnt - 1);
  end
  else if IsOpSection(Sec) then
  begin
    GroupIndex := Form1.FScheme.OpGroupIndex(Sec);
    Cnt := Length(Form1.FScheme.OpGroups);
    if GroupIndex < 0 then
      Exit;
    for I := GroupIndex to Cnt - 2 do
      Form1.FScheme.OpGroups[I] := Form1.FScheme.OpGroups[I + 1];
    SetLength(Form1.FScheme.OpGroups, Cnt - 1);
  end
  else
  begin
    GroupIndex := Form1.FScheme.MarkGroupIndex(Sec);
    Cnt := Length(Form1.FScheme.MarkGroups);
    if GroupIndex < 0 then
      Exit;
    if Form1.FScheme.MarkGroups[GroupIndex].Words <> nil then
      Form1.FScheme.MarkGroups[GroupIndex].Words.Free;
    for I := GroupIndex to Cnt - 2 do
      Form1.FScheme.MarkGroups[I] := Form1.FScheme.MarkGroups[I + 1];
    SetLength(Form1.FScheme.MarkGroups, Cnt - 1);
  end;

  // Раздел уходит и из файла: его больше нет ни в таблице, ни в схеме
  I := Form1.FScheme.SchemaSections.IndexOf(Sec);
  if I >= 0 then
    Form1.FScheme.SchemaSections.Delete(I);

  RefreshGridFromForm1;
  FPreviewDirty := True; // группа удалена, в файл ещё не записано
end;

procedure TForm2.chkUseHighlightClick(Sender: TObject);
begin
  // Проверяем, существует ли главная форма в памяти
  if Form1 <> nil then
  begin
    // Напрямую меняем флаг в Unit1 в реальном времени!
    Form1.FUseSyntaxHighlight := chkUseHighlight.Checked;
    
    // Заставляем RichEdit немедленно очистить старый кэш отрисовки и перекраситься
    Form1.RichEdit1.Invalidate;
    
    // Опционально: если номера строк тоже должны реагировать (например, тускнеть)
    if Form1.PaintBox1 <> nil then
      Form1.PaintBox1.Invalidate;
  end;
end;

procedure TForm2.GridSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
  if ARow = 0 then Exit;

  // ТЕПЕРЬ ПРИ ВЫБОРЕ ЛЮБОЙ СТРОКИ (не важно, какой столбец)
  // мы берем данные из скрытого кэша (столбец 3) выбранной строки и показываем в Memo!
// ВКЛЮЧАЕМ БЛОКИРОВКУ: Говорим Memo, что сейчас текст в него запишет программа!
  FLockMemo := True;
  try
    // Берем данные из скрытого кэша (столбец 3) выбранной строки и показываем в Memo
    MemoSchemaDetails.Lines.Text := Grid.Cells[3, ARow];
  finally
    // ОБЯЗАТЕЛЬНО ВЫКЛЮЧАЕМ БЛОКИРОВКУ, чтобы пользователь снова мог редактировать текст
    FLockMemo := False;
  end;

  // Палитру здесь НЕ открываем: OnSelectCell срабатывает и на стрелки
  // клавиатуры, и на программное присваивание Grid.Row, из-за чего диалог
  // цвета выскакивал сам собой. Выбор цвета перенесён в GridDblClick.
end;

// Цвета строки Text - в таблицу и сразу в редактор.
//
// Смена ФОНА каскадом переносится на те элементы синтаксиса, фон которых
// совпадал со старым фоном текста. При загрузке схемы их фоны как раз и
// берутся из подложки текста (FTextBG), так что без каскада после смены
// фона комментарии и операторы остались бы со старой плашкой. Элементы, которым
// фон задали отдельно (например, белый под числами), остаются нетронутыми.
procedure TForm2.SetTextRowColors(AFg, ABg: TColor);
var
  TextRow, R: Integer;
  OldBg: TColor;
begin
  // Строка Text стоит там, где раздел Text лежит в файле схемы; раздела нет -
  // нет и строки, менять нечего
  TextRow := SectionRow('Text');
  if TextRow <= 0 then
    Exit;
  OldBg := TColor(Grid.Objects[2, TextRow]);

  Grid.Objects[1, TextRow] := TObject(AFg);
  Grid.Objects[2, TextRow] := TObject(ABg);
  if ABg <> OldBg then
    for R := 1 to Grid.RowCount - 1 do
      if (R <> TextRow) and SectionHasColors(RowSection(R)) and
         (TColor(Grid.Objects[2, R]) = OldBg) then
        Grid.Objects[2, R] := TObject(ABg);
  Grid.Invalidate;

  // Сразу в редактор, без записи в файл: схема сохраняется по Save,
  // закрытие без Save возвращает её из файла (Form2Close)
  ApplyGridToForm1(False);
  FPreviewDirty := True;
  if Form1 <> nil then
  begin
    Form1.RichEdit1.Invalidate;
    if Form1.PaintBox1 <> nil then
      Form1.PaintBox1.Invalidate;
  end;
end;

// Base colors: цвет текста - FontColor, подложка - BGColor из editor.ini
procedure TForm2.btnBaseColorsClick(Sender: TObject);
begin
  if (Form1 = nil) or (Grid = nil) then
    Exit;
  SetTextRowColors(Form1.BaseFontColor, Form1.EditorBG);
end;

// Кнопка Base colors - в правой части ячейки Text (столбец 0, последняя
// строка). Таблица её не двигает сама: при прокрутке и смене числа строк
// место пересчитывается здесь; строка не видна - кнопка прячется.
procedure TForm2.PlaceBaseColorsButton;
var
  R: TRect;
  W: Integer;
  Bmp: TBitmap;
begin
  if (btnBaseColors = nil) or (Grid = nil) then
    Exit;

  // Кнопка стоит в ячейке раздела Text, где бы он ни лежал в файле
  if SectionRow('Text') <= 0 then
  begin
    btnBaseColors.Visible := False;
    Exit;
  end;

  R := Grid.CellRect(0, SectionRow('Text'));
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then
  begin
    btnBaseColors.Visible := False;
    Exit;
  end;

  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(btnBaseColors.Font);
    W := Bmp.Canvas.TextWidth(btnBaseColors.Caption) + 12;
  finally
    Bmp.Free;
  end;

  btnBaseColors.SetBounds(R.Right - W - 2, R.Top + 2, W, R.Bottom - R.Top - 4);
  btnBaseColors.Visible := True;
end;

// Таблица: WM_COMMAND от кнопки Base colors - переслать кнопке как
// CN_COMMAND, как это делает обычный родитель VCL; кнопка вызовет OnClick
procedure TForm2.GridWndProc(var Message: TMessage);
begin
  // Колесо мыши над таблицей обрабатывает Form1.AppMessage - для всех
  // таблиц программы сразу
  if (Message.Msg = WM_COMMAND) and (btnBaseColors <> nil) and
     btnBaseColors.HandleAllocated and
     (HWND(Message.LParam) = btnBaseColors.Handle) then
  begin
    Message.Result := btnBaseColors.Perform(CN_COMMAND, Message.WParam,
                                            Message.LParam);
    Exit;
  end;
  FGridOldProc(Message);
end;

procedure TForm2.GridTopLeftChanged(Sender: TObject);
begin
  PlaceBaseColorsButton;
end;

procedure TForm2.Form2ResizeOrShow(Sender: TObject);
begin
  PlaceBaseColorsButton;
end;

procedure TForm2.GridDblClick(Sender: TObject);
var
  OldColor, NewColor: TColor;
  TextRow: Integer;
begin
  if Grid.Row <= 0 then
    Exit;
  if (Grid.Col <> 1) and (Grid.Col <> 2) then
    Exit;
  // У SubList, SubEnd и SubStyle цветов нет - палитру не открываем
  if not SectionHasColors(RowSection(Grid.Row)) then
    Exit;

  OldColor := TColor(Grid.Objects[Grid.Col, Grid.Row]);
  ColorDlg.Color := OldColor;
  if not ColorDlg.Execute then
    Exit;

  NewColor := ColorDlg.Color;

  TextRow := SectionRow('Text');
  if (TextRow > 0) and (Grid.Row = TextRow) then
  begin
    // Строка Text - через общий метод: у фона там каскад
    if Grid.Col = 1 then
      SetTextRowColors(NewColor, TColor(Grid.Objects[2, TextRow]))
    else
      SetTextRowColors(TColor(Grid.Objects[1, TextRow]), NewColor);
    Exit;
  end;

  Grid.Objects[Grid.Col, Grid.Row] := TObject(NewColor);
  Grid.Invalidate;

  // Сразу в редактор, без записи в файл: схема сохраняется по Save,
  // закрытие без Save возвращает её из файла (Form2Close)
  ApplyGridToForm1(False);
  FPreviewDirty := True;
  if Form1 <> nil then
  begin
    Form1.RichEdit1.Invalidate;
    if Form1.PaintBox1 <> nil then
      Form1.PaintBox1.Invalidate;
  end;
end;

procedure TForm2.chkHotTabHighlightClick(Sender: TObject);
begin
  if Form1 = nil then
    Exit;
  Form1.FUseHotTab := chkHotTabHighlight.Checked;
  Form1.SaveSettings;
  Form1.RichEdit1.Invalidate;
end;

// Ставит в комбобоксе пункт, соответствующий ширине AChars. Если такого пункта
// в списке нет, выбор не меняем - лучше показать неточность, чем молча подменить.
procedure TForm2.SetTabWidthInCombo(AChars: Integer);
var
  I: Integer;
begin
  if cmbTabWidth = nil then
    Exit;
  for I := 0 to cmbTabWidth.Items.Count - 1 do
    if StrToIntDef(cmbTabWidth.Items[I], -1) = AChars then
    begin
      cmbTabWidth.ItemIndex := I;
      Exit;
    end;
end;

// Ставит значение, не вызывая обработчик: иначе синхронизация при открытии
// окна сама бы перезаписывала настройку в Form1.
procedure TForm2.SetHotTabPale(AValue: Integer);
var
  Saved: TNotifyEvent;
begin
  if (edtPale = nil) or (udPale = nil) then
    Exit;
  if AValue < 0 then
    AValue := 0;
  if AValue > 100 then
    AValue := 100;

  Saved := edtPale.OnChange;
  edtPale.OnChange := nil;
  try
    udPale.Position := AValue;
    edtPale.Text := IntToStr(AValue);
  finally
    edtPale.OnChange := Saved;
  end;
end;

procedure TForm2.edtPaleChange(Sender: TObject);
var
  V: Integer;
begin
  if Form1 = nil then
    Exit;

  V := StrToIntDef(Trim(edtPale.Text), -1);
  if (V < 0) or (V > 100) then
    Exit; // промежуточный ввод, например пустое поле - просто ждём

  Form1.FHotTabPale := V;
  Form1.SaveSettings;
  Form1.RichEdit1.Invalidate;
end;

// Настройки отступа - в Form1 и в editor.ini. Текст в редакторе от этого не
// меняется: они нужны Format text и отрисовке направляющих полос.
// Непечатные символы - только отрисовка, текст не трогается
procedure TForm2.chkShowSpacesClick(Sender: TObject);
begin
  if Form1 = nil then
    Exit;
  Form1.FShowSpaces := chkShowSpaces.Checked;
  Form1.SaveSettings;
  Form1.RichEdit1.Invalidate;
end;

// Текст привели к настройкам - подсказка о переформатировании не нужна
procedure TForm2.HideIndentHint;
begin
  if lblIndentHint <> nil then
    lblIndentHint.Visible := False;
end;

procedure TForm2.cmbIndentKindChange(Sender: TObject);
begin
  if Form1 = nil then
    Exit;
  Form1.FIndentKind := cmbIndentKind.ItemIndex;
  Form1.SaveSettings;
  lblIndentHint.Visible := True;
  // В режиме none полос нет - перерисовываем
  Form1.RichEdit1.Invalidate;
end;

procedure TForm2.cmbIndentSizeChange(Sender: TObject);
var
  N: Integer;
begin
  if Form1 = nil then
    Exit;
  N := StrToIntDef(cmbIndentSize.Text, 0);
  if N < 1 then
    Exit;
  Form1.FIndentSize := N;
  Form1.SaveSettings;
  lblIndentHint.Visible := True;
  // Полосы считают уровни по этому числу
  Form1.RichEdit1.Invalidate;
end;

// Показать в окне то, что лежит в Form1 - без записи обратно в editor.ini
procedure TForm2.SetIndentControls(AKind, ASize: Integer);
var
  OldKind, OldSize: TNotifyEvent;
  I: Integer;
begin
  // Окно открыли заново - подсказка о переформатировании больше не к месту
  if lblIndentHint <> nil then
    lblIndentHint.Visible := False;

  OldKind := cmbIndentKind.OnChange;
  OldSize := cmbIndentSize.OnChange;
  cmbIndentKind.OnChange := nil;
  cmbIndentSize.OnChange := nil;
  try
    if (AKind < 0) or (AKind >= cmbIndentKind.Items.Count) then
      AKind := 0;
    cmbIndentKind.ItemIndex := AKind;

    // Числа в списке фиксированные - берём ближайшее подходящее
    cmbIndentSize.ItemIndex := -1;
    for I := 0 to cmbIndentSize.Items.Count - 1 do
      if StrToIntDef(cmbIndentSize.Items[I], 0) = ASize then
      begin
        cmbIndentSize.ItemIndex := I;
        Break;
      end;
    if cmbIndentSize.ItemIndex < 0 then
      cmbIndentSize.ItemIndex := 1; // 2
  finally
    cmbIndentKind.OnChange := OldKind;
    cmbIndentSize.OnChange := OldSize;
  end;
end;

procedure TForm2.cmbTabWidthChange(Sender: TObject);
var
  Chars: Integer;
begin
  if Form1 = nil then
    Exit;
  if cmbTabWidth.ItemIndex < 0 then
    Exit;

  Chars := StrToIntDef(cmbTabWidth.Items[cmbTabWidth.ItemIndex], 0);
  if Chars < 1 then
    Exit;

  Form1.FTabChars := Chars;
  Form1.SaveSettings;
  Form1.ApplyTabStops; // пересчёт шага и EM_SETPARAFORMAT
end;

procedure TForm2.chkShowLineNumbersClick(Sender: TObject);
begin
  if Form1 = nil then
    Exit;
  if Form1.PaintBox1 <> nil then
    Form1.PaintBox1.Visible := chkShowLineNumbers.Checked;
  if Form1.Panel1 <> nil then
    Form1.Panel1.Visible := chkShowLineNumbers.Checked;
  Form1.RichEdit1.Invalidate;
end;


procedure TForm2.MemoSchemaDetailsChange(Sender: TObject);
var
  S: string;
begin
  // Если флаг взведен (текст меняет программа при переключении строк) — игнорируем событие!
  if FLockMemo then
    Exit;

  // Если флаг False (пользователь сам печатает буквы) — сохраняем данные в кэш.
  //
  // Берём текст поля как есть (Text, а не Lines.Text - тот дописывает перевод
  // строки в конце) и отрезаем переводы строк в конце: маркеры теперь не
  // обрезаются по пробелам, и CRLF стал бы частью маркера.
  // Изменением считается только настоящая разница - программная запись в
  // поле того же значения изменением не является.
  S := MemoSchemaDetails.Text;
  while (S <> '') and ((S[Length(S)] = #13) or (S[Length(S)] = #10)) do
    SetLength(S, Length(S) - 1);
  if Grid.Cells[3, Grid.Row] <> S then
  begin
    Grid.Cells[3, Grid.Row] := S;
    FPreviewDirty := True;
  end;
end;

// Раскладка группы Editor options в один ряд.
//
// Раньше у элементов стояли постоянные Left и Width с запасом, и между ними
// оставались большие зазоры. Теперь ширина флажка считается по надписи, а
// каждый следующий элемент ставится за предыдущим через Gap пикселей.
procedure TForm2.LayoutEditorOptions(AGroup: TUiGroupBox);
const
  Gap = 8;
var
  Bmp: TBitmap;
  X: Integer;

  function CheckW(C: TUiCheckBox): Integer;
  begin
    // квадратик флажка + отступ до надписи + надпись + запас на рамку фокуса
    Result := GetSystemMetrics(SM_CXMENUCHECK) + 4 +
              Bmp.Canvas.TextWidth(C.Caption) + 6;
  end;

  function ButtonW(B: TUiButton): Integer;
  begin
    Result := Bmp.Canvas.TextWidth(B.Caption) + 20;
  end;

  procedure PlaceCheck(C: TUiCheckBox);
  begin
    C.Left := X;
    C.Width := CheckW(C);
    Inc(X, C.Width + Gap);
  end;

  procedure PlaceButton(B: TUiButton);
  begin
    B.Left := X;
    B.Width := ButtonW(B);
    Inc(X, B.Width + Gap);
  end;

begin
  if AGroup = nil then
    Exit;

  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(AGroup.Font);
    X := 6;

    PlaceCheck(chkUseHighlight);
    PlaceCheck(chkShowSpaces);

    lblTabWidth.Left := X;
    Inc(X, Bmp.Canvas.TextWidth(lblTabWidth.Caption) + 4);
    cmbTabWidth.Left := X;
    Inc(X, cmbTabWidth.Width + Gap);

    PlaceCheck(chkShowLineNumbers);
    PlaceButton(btnFontChange);
  finally
    Bmp.Free;
  end;
end;

// Группа Editor colors в ряд: Editor color [FG][BG]   Gutter color [FG][BG]
// Ряд группы Indent: список режима, список размера, галка подсветки и поле
// бледности. Ширины считаются по надписям, как в Editor options.
// Список инструментов типа из editor.ini: [Compiler.<Тип>] Tools, имена
// через точку с запятой. Пусто - работаем с безымянным инструментом, как
// было до появления версий.
procedure TForm2.LoadToolList(const AType: string);
var
  Ini: TIniFile;
  S, Def: string;
  I: Integer;
begin
  cbTool.Items.Clear;
  Def := '';

  if (Form1 <> nil) and FileExists(Form1.SettingsFileName) then
  begin
    Ini := TIniFile.Create(Form1.SettingsFileName);
    try
      S := Ini.ReadString('Compiler.' + AType, 'Tools', '');
      Def := Ini.ReadString('Compiler.' + AType, 'Default', '');
    finally
      Ini.Free;
    end;
  end;

  while S <> '' do
  begin
    I := Pos(';', S);
    if I = 0 then
      I := Length(S) + 1;
    if Trim(Copy(S, 1, I - 1)) <> '' then
      cbTool.Items.Add(Trim(Copy(S, 1, I - 1)));
    S := Copy(S, I + 1, Length(S));
  end;

  if cbTool.Items.Count = 0 then
    cbTool.Items.Add('(default)');

  cbTool.ItemIndex := cbTool.Items.IndexOf(Def);
  if cbTool.ItemIndex < 0 then
    cbTool.ItemIndex := 0;
end;

procedure TForm2.SaveToolList(const AType: string);
var
  Ini: TIniFile;
  S: string;
  I: Integer;
begin
  if Form1 = nil then
    Exit;

  S := '';
  for I := 0 to cbTool.Items.Count - 1 do
    if cbTool.Items[I] <> '(default)' then
    begin
      if S <> '' then
        S := S + ';';
      S := S + cbTool.Items[I];
    end;

  Ini := TIniFile.Create(Form1.SettingsFileName);
  try
    Ini.WriteString('Compiler.' + AType, 'Tools', S);
    if cbTool.ItemIndex >= 0 then
      Ini.WriteString('Compiler.' + AType, 'Default',
                      cbTool.Items[cbTool.ItemIndex]);
  finally
    Ini.Free;
  end;
end;

procedure TForm2.cbToolChange(Sender: TObject);
begin
  SaveToolList(FCompType);   // выбранный становится основным для типа
  ShowCompilerPage(FCompType);
end;

procedure TForm2.btnToolAddClick(Sender: TObject);
var
  S: string;
begin
  S := '';
  if not InputQuery('Инструмент сборки', 'Название:', S) then
    Exit;
  S := Trim(S);
  if (S = '') or (cbTool.Items.IndexOf(S) >= 0) then
    Exit;

  if (cbTool.Items.Count = 1) and (cbTool.Items[0] = '(default)') then
    cbTool.Items.Clear;
  cbTool.ItemIndex := cbTool.Items.Add(S);
  SaveToolList(FCompType);
  ShowCompilerPage(FCompType);
end;

procedure TForm2.btnToolDelClick(Sender: TObject);
var
  I: Integer;
begin
  I := cbTool.ItemIndex;
  if (I < 0) or (cbTool.Items[I] = '(default)') then
    Exit;
  if MessageDlg('2753:Убрать инструмент ' + cbTool.Items[I] + ' из списка? ' +
                'Его настройки останутся в editor.ini.',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  cbTool.Items.Delete(I);
  if cbTool.Items.Count = 0 then
    cbTool.Items.Add('(default)');
  cbTool.ItemIndex := 0;
  SaveToolList(FCompType);
  ShowCompilerPage(FCompType);
end;

// Поиск установленных сред. Delphi пишет корень установки в реестр:
// седьмая в HKCU\Software\Borland\Delphi\7.0, ключ RootDir; начиная с
// 2005-й - в HKCU\Software\Embarcadero\BDS\<версия>. Для прочих типов
// такой ветки нет, пути указываются руками.
procedure TForm2.btnToolFindClick(Sender: TObject);
var
  Reg: TRegistry;
  Keys: TStringList;
  I, Found: Integer;
  Root, Nm: string;
  Ini: TIniFile;

  // Развернуть $(DELPHI) и прочие переменные среды Delphi. Их список
  // лежит в той же ветке реестра, в Environment Variables.
  function ExpandVars(const S, ARoot, AKey: string): string;
  begin
    Result := ExpandDelphiRegVars(S, ARoot, AKey);
  end;

  procedure AddFound(const AName, ARoot, AKey: string);
  var
    Lib: string;
    R3: TRegistry;
  begin
    if (AName = '') or (ARoot = '') or not DirectoryExists(ARoot) then
      Exit;
    if cbTool.Items.IndexOf(AName) < 0 then
    begin
      if (cbTool.Items.Count = 1) and (cbTool.Items[0] = '(default)') then
        cbTool.Items.Clear;
      cbTool.Items.Add(AName);
    end;
    Ini.WriteString('Compiler.' + FCompType + '.' + AName, 'DelphiPath',
                    IncludeTrailingPathDelimiter(ARoot));

    // Пути поиска модулей берём те же, что у самой среды: она хранит их
    // в реестре, в Library\Search Path. Переменные разворачиваем - dcc32
    // про них не знает.
    R3 := TRegistry.Create;
    try
      R3.RootKey := HKEY_CURRENT_USER;
      if R3.OpenKeyReadOnly(AKey + '\Library') then
      begin
        Lib := R3.ReadString('Search Path');
        R3.CloseKey;
        if Lib <> '' then
          Ini.WriteString('Compiler.' + FCompType + '.' + AName, 'LibPath',
                          ExpandVars(Lib, ARoot, AKey));
      end;
    finally
      R3.Free;
    end;

    Inc(Found);
  end;

begin
  if (Form1 = nil) or (FCompType <> 'Delphi') then
  begin
    ShowMessage('2861:Поиск по реестру умеет находить только установленные Delphi.');
    Exit;
  end;

  Found := 0;
  Reg := TRegistry.Create;
  Keys := TStringList.Create;
  Ini := TIniFile.Create(Form1.SettingsFileName);
  try
    Reg.RootKey := HKEY_CURRENT_USER;

    // Borland: Delphi 5, 6, 7
    if Reg.OpenKeyReadOnly('Software\Borland\Delphi') then
    begin
      Reg.GetKeyNames(Keys);
      Reg.CloseKey;
      for I := 0 to Keys.Count - 1 do
        if Reg.OpenKeyReadOnly('Software\Borland\Delphi\' + Keys[I]) then
        begin
          Root := Reg.ReadString('RootDir');
          Reg.CloseKey;
          Nm := 'Delphi ' + Copy(Keys[I], 1, Pos('.', Keys[I] + '.') - 1);
          AddFound(Nm, Root, 'Software\Borland\Delphi\' + Keys[I]);
        end;
    end;

    // Embarcadero: BDS 2005 и новее, номер версии продукта в имени ветки
    Keys.Clear;
    if Reg.OpenKeyReadOnly('Software\Embarcadero\BDS') then
    begin
      Reg.GetKeyNames(Keys);
      Reg.CloseKey;
      for I := 0 to Keys.Count - 1 do
        if Reg.OpenKeyReadOnly('Software\Embarcadero\BDS\' + Keys[I]) then
        begin
          Root := Reg.ReadString('RootDir');
          Reg.CloseKey;
          AddFound('BDS ' + Keys[I], Root,
                   'Software\Embarcadero\BDS\' + Keys[I]);
        end;
    end;
  finally
    Ini.Free;
    Keys.Free;
    Reg.Free;
  end;

  if Found = 0 then
    ShowMessage('2909:Установленных Delphi в реестре не нашлось.')
  else
  begin
    if cbTool.ItemIndex < 0 then
      cbTool.ItemIndex := 0;
    SaveToolList(FCompType);
    FSkipNormalize := True;   // на экране ещё старое, в файле уже найденное
    ShowCompilerPage(FCompType);
  end;
end;

// Список типов и поля настроек для каждого. Строка поля - 'Ключ|Подпись';
// ключ идёт в editor.ini, раздел Compiler.<Тип>. Ключ, кончающийся на File,
// выбирается как файл, остальные как папка.
// ---------------------------------------------------------------------------
//  Вкладка IDE colors
//
//  Цвета оформления самой программы: вкладки файлов, дерево объектов и то,
//  что добавится позже. Это не подсветка синтаксиса - у неё своя схема и
//  своя вкладка. Список ролей и значения хранит Form1 (UiColors), файл -
//  IDE.clr рядом с программой. Тёмная тема - это другой такой файл.
//
//  Новая роль добавляется одной строкой в LoadUiDefaults в Unit1: строка в
//  таблице появится сама.
// ---------------------------------------------------------------------------

procedure TForm2.BuildUiColorsTab(ATab: TWinControl);
begin
  UiKeys := TStringList.Create;

  pnlUiBottom := TPanel.Create(Self);
  pnlUiBottom.Parent := ATab;
  pnlUiBottom.Align := alBottom;
  pnlUiBottom.Height := 34;
  pnlUiBottom.BevelOuter := bvNone;

  btnUiDefaults := TUiButton.Create(Self);
  btnUiDefaults.Parent := pnlUiBottom;
  btnUiDefaults.Caption := 'Вернуть умолчания';
  btnUiDefaults.Left := 6;
  btnUiDefaults.Top := 4;
  btnUiDefaults.Width := 140;
  btnUiDefaults.OnClick := btnUiDefaultsClick;

  lblUiHint := TLabel.Create(Self);
  lblUiHint.Parent := pnlUiBottom;
  lblUiHint.Left := 156;
  lblUiHint.Top := 9;
  lblUiHint.Caption := 'Двойной щелчок по цвету - выбор. Пишется в IDE.clr сразу.';

  UiGrid := TStringGrid.Create(Self);
  UiGrid.Parent := ATab;
  UiGrid.Align := alClient;
  UiGrid.ColCount := 2;
  UiGrid.FixedCols := 0;
  UiGrid.FixedRows := 1;
  UiGrid.DefaultRowHeight := 20;
  UiGrid.Options := UiGrid.Options - [goRangeSelect] + [goRowSelect];
  UiGrid.ColWidths[0] := 300;
  UiGrid.ColWidths[1] := 200;
  UiGrid.OnDrawCell := UiGridDrawCell;
  UiGrid.OnDblClick := UiGridDblClick;

  RefreshUiGrid;
end;

// Таблица из списка ролей Form1
procedure TForm2.RefreshUiGrid;
var
  I: Integer;
  Key: string;
begin
  if (UiGrid = nil) or (Form1 = nil) or (Form1.UiColors = nil) then
    Exit;
  UiKeys.Clear;
  for I := 0 to Form1.UiColors.Count - 1 do
    UiKeys.Add(Form1.UiColors.Names[I]);

  UiGrid.RowCount := UiKeys.Count + 1;
  UiGrid.Cells[0, 0] := 'Элемент';
  UiGrid.Cells[1, 0] := 'Цвет';
  for I := 0 to UiKeys.Count - 1 do
  begin
    Key := UiKeys[I];
    UiGrid.Cells[0, I + 1] := Form1.UiCaption(Key);
    UiGrid.Cells[1, I + 1] := ColorToString(Form1.UiColor(Key));
  end;
  UiGrid.Invalidate;
end;

// В колонке цвета - квадрат образца и название цвета
procedure TForm2.UiGridDrawCell(Sender: TObject; ACol, ARow: Integer;
                                Rect: TRect; State: TGridDrawState);
var
  C: TCanvas;
  R: TRect;
  S: string;
begin
  C := UiGrid.Canvas;
  if (ACol <> 1) or (ARow = 0) or (ARow > UiKeys.Count) then
    Exit;

  // Сетка уже нарисовала текст ячейки по-своему, а мы рисуем его со
  // сдвигом под образец цвета. Поэтому сначала затираем ячейку.
  if gdSelected in State then
  begin
    C.Brush.Color := clHighlight;
    C.Font.Color := clHighlightText;
  end
  else
  begin
    // Цвета самой таблицы: их ставят цвета IDE (IDE Light / IDE Dark)
    C.Brush.Color := UiGrid.Color;
    C.Font.Color := UiGrid.Font.Color;
  end;
  C.Brush.Style := bsSolid;
  C.FillRect(Rect);

  S := UiGrid.Cells[1, ARow];
  R := Rect;
  R.Left := R.Left + 2;
  R.Top := R.Top + 3;
  R.Right := R.Left + 16;
  R.Bottom := R.Top + 12;
  // clDefault - «как у другого элемента» (своего цвета нет): пустой
  // квадратик с диагональю
  if Form1.UiColor(UiKeys[ARow - 1]) <> clDefault then
  begin
    C.Brush.Color := Form1.UiColor(UiKeys[ARow - 1]);
    C.FillRect(R);
  end;
  C.Brush.Style := bsClear;
  C.Pen.Color := clGray;
  C.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
  if Form1.UiColor(UiKeys[ARow - 1]) = clDefault then
  begin
    C.MoveTo(R.Left, R.Bottom - 1);
    C.LineTo(R.Right, R.Top - 1);
  end;

  C.Brush.Style := bsClear;
  C.TextOut(Rect.Left + 24, Rect.Top + 2, S);
end;

// Двойной щелчок по строке - выбор цвета. Значение сразу применяется к
// окнам и пишется в IDE.clr: отдельной кнопки сохранения нет.
procedure TForm2.UiGridDblClick(Sender: TObject);
var
  Row: Integer;
  Key: string;
begin
  Row := UiGrid.Row;
  if (Row < 1) or (Row > UiKeys.Count) then
    Exit;
  Key := UiKeys[Row - 1];
  ColorDlg.Color := Form1.UiColor(Key);
  if not ColorDlg.Execute then
    Exit;
  Form1.UiSetColor(Key, ColorDlg.Color);
  Form1.SaveUiSchema;
  Form1.UiApply;
  RefreshUiGrid;
end;

procedure TForm2.btnUiDefaultsClick(Sender: TObject);
begin
  Form1.UiResetDefaults;
  Form1.SaveUiSchema;
  Form1.UiApply;
  RefreshUiGrid;
end;

procedure TForm2.BuildCompilersTab(ATab: TWinControl);
begin
  if ATab = nil then
    Exit;
  if lstCompTypes <> nil then
    Exit;

  lstCompTypes := TUiListBox.Create(Self);
  lstCompTypes.Parent := ATab;
  lstCompTypes.Align := alLeft;
  lstCompTypes.Width := 130;
  lstCompTypes.Items.Add('RapidQ Basic');
  lstCompTypes.Items.Add('Delphi');
  lstCompTypes.Items.Add('FreeBASIC');
  lstCompTypes.Items.Add('Visual Basic');
  lstCompTypes.Items.Add('Arduino');
  lstCompTypes.Items.Add('C project');
  lstCompTypes.Items.Add('CPP project');
  lstCompTypes.Items.Add('WebSite');
  lstCompTypes.OnClick := lstCompTypesClick;

  pnlCompPage := TPanel.Create(Self);
  pnlCompPage.Parent := ATab;
  pnlCompPage.Align := alClient;
  pnlCompPage.BevelOuter := bvNone;

  // Строка выбора инструмента живёт над страницей и при переключении типа
  // не пересоздаётся - меняется только её содержимое
  cbTool := TUiComboBox.Create(Self);
  cbTool.Parent := ATab;
  cbTool.Style := csDropDownList;
  cbTool.OnChange := cbToolChange;

  btnToolAdd := TUiButton.Create(Self);
  btnToolAdd.Parent := ATab;
  btnToolAdd.Caption := 'Add';
  btnToolAdd.OnClick := btnToolAddClick;

  btnToolDel := TUiButton.Create(Self);
  btnToolDel.Parent := ATab;
  btnToolDel.Caption := 'Delete';
  btnToolDel.OnClick := btnToolDelClick;

  btnToolFind := TUiButton.Create(Self);
  btnToolFind.Parent := ATab;
  btnToolFind.Caption := 'Find installed';
  btnToolFind.OnClick := btnToolFindClick;

  btnDelphiImport := TUiButton.Create(Self);
  btnDelphiImport.Parent := ATab;
  btnDelphiImport.Caption := 'Взять из Delphi';
  btnDelphiImport.ShowHint := True;
  btnDelphiImport.Hint := 'Library path и Browsing path из Environment ' +
                          'Options этой Delphi (реестр); свои пути остаются ' +
                          'в конце';
  btnDelphiImport.OnClick := btnDelphiImportClick;

  btnArdImport := TUiButton.Create(Self);
  btnArdImport.Parent := ATab;
  btnArdImport.Caption := 'Импорт из RQdb.ini';
  btnArdImport.ShowHint := True;
  btnArdImport.Hint := 'Пути Arduino из RQdb.ini RQdebugger (раздел ' +
                       '[Arduino]) и Additional URLs из AdditURLEdit.txt';
  btnArdImport.OnClick := btnArdImportClick;

  lstCompTypes.ItemIndex := 0;
  FCompType := lstCompTypes.Items[0];
  LoadToolList(FCompType);
  ShowCompilerPage(FCompType);
end;

// Страница настроек одного типа. Прежние поля уничтожаются и строятся
// заново: типов немного, а держать восемь готовых страниц ради переключения
// незачем.
procedure TForm2.ShowCompilerPage(const AType: string);
var
  Fields: TStringList;
  I, Y, LabW: Integer;
  L: TLabel;
  E: TUiEdit;
  B: TUiButton;
  T: TLabel;
  Ini: TIniFile;
  Bmp: TBitmap;
  Key, Cap: string;
  NoBrowse: Boolean;
  P: Integer;
begin
  if pnlCompPage = nil then
    Exit;

  // Поля прежней страницы сейчас исчезнут вместе с их OnExit - приводим
  // значения в порядок, пока они ещё на месте. Раздел настроек тоже пока
  // прежний.
  if FSkipNormalize then
    FSkipNormalize := False
  else
    NormalizeCompFields;

  while pnlCompPage.ControlCount > 0 do
    pnlCompPage.Controls[0].Free;
  SetLength(FCompEdits, 0);
  SetLength(FCompKeys, 0);
  SetLength(FCompIsList, 0);

  // Раздел настроек - по типу и выбранному инструменту. Инструмент без
  // имени пишется в раздел типа, как было до появления версий.
  FCompType := AType;
  if (cbTool <> nil) and (cbTool.ItemIndex >= 0) and
     (cbTool.Items[cbTool.ItemIndex] <> '(default)') then
    FCompSection := 'Compiler.' + AType + '.' + cbTool.Items[cbTool.ItemIndex]
  else
    FCompSection := 'Compiler.' + AType;

  Fields := TStringList.Create;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(pnlCompPage.Font);

    if AType = 'RapidQ Basic' then
    begin
      Fields.Add('IdePath|IDE path');
      Fields.Add('CompPath|Compiler');
      Fields.Add('IncPath|Include');
      Fields.Add('LibPath|Library');
      Fields.Add('PrjPath|Projects');
      Fields.Add('TplPath|Templates');
      Fields.Add('IcoFile|App icon');
      // Описание компонентов для инспектора и снимка: ComponentAll.data
      // (RapidQComponentsReady в Unit1)
      Fields.Add('CompDataFile|Components');
    end
    else if AType = 'Delphi' then
    begin
      Fields.Add('DelphiPath|Delphi path');
      Fields.Add('-LibPath|Library path');
      Fields.Add('-BrowsePath|Browsing path');
      Fields.Add('ExePath|Output (exe)');
      Fields.Add('DcuPath|Output (dcu)');
      // Папка исходников Ui*.pas - [UiLib] Source (CompIniSection)
      Fields.Add('UiSource|Ui components');
      // Library path и Browsing path - списки через точку с запятой, как в
      // самой среде; Library заполняется кнопкой Find installed, Browsing
      // задаётся вручную. Пустые Output - папка проекта.
    end
    else if AType = 'FreeBASIC' then
    begin
      Fields.Add('FBCompPath|FB compiler');
      Fields.Add('IncPath|Include');
      Fields.Add('LibPath|Library');
    end
    else if AType = 'Visual Basic' then
    begin
      Fields.Add('VbCompFile|VB6.exe');
      Fields.Add('OutPath|Output');
    end
    else if AType = 'Arduino' then
    begin
      Fields.Add('SketchPath|Sketch path');
      Fields.Add('CliFile|Arduino CLI file');
      Fields.Add('BuildPath|Build path');
      Fields.Add('LibPath|Library path');
      Fields.Add('LogFile|Log file');
      Fields.Add('CliCfgFile|Cli cfg file');
      Fields.Add('CliDataPath|Cli data path');
      Fields.Add('DownloadsPath|Cli downloads path');
      // Папка Arduino IDE (%LOCALAPPDATA%\Arduino15): там тоже ищутся
      // установленные платформы и library_index.json
      Fields.Add('Arduino15Path|Arduino15 path');
    end
    else if (AType = 'C project') or (AType = 'CPP project') then
    begin
      Fields.Add('CompFile|Compiler (exe)');
      Fields.Add('IncPath|Include');
      Fields.Add('LibPath|Library');
      Fields.Add('OutPath|Output');
    end
    else if AType = 'WebSite' then
    begin
      Fields.Add('BrowserFile|Browser (exe)');
      Fields.Add('PublishPath|Publish folder');
    end;

    // Строка выбора инструмента поверх страницы
    if cbTool <> nil then
    begin
      cbTool.Left := lstCompTypes.Width + 12;
      cbTool.Top := 8;
      cbTool.Width := 180;
      btnToolAdd.Left := cbTool.Left + cbTool.Width + 6;
      btnToolAdd.Top := 7;
      btnToolAdd.Width := 60;
      btnToolAdd.Height := 23;
      btnToolDel.Left := btnToolAdd.Left + 66;
      btnToolDel.Top := 7;
      btnToolDel.Width := 60;
      btnToolDel.Height := 23;
      btnToolFind.Left := btnToolDel.Left + 66;
      btnToolFind.Top := 7;
      btnToolFind.Width := 90;
      btnToolFind.Height := 23;
      btnToolFind.Enabled := AType = 'Delphi';
      btnDelphiImport.Left := btnToolFind.Left + 96;
      btnDelphiImport.Top := 7;
      btnDelphiImport.Width := 110;
      btnDelphiImport.Height := 23;
      btnDelphiImport.Visible := AType = 'Delphi';
      btnArdImport.Left := btnToolFind.Left + 96;
      btnArdImport.Top := 7;
      btnArdImport.Width := 140;
      btnArdImport.Height := 23;
      btnArdImport.Visible := AType = 'Arduino';
    end;

    T := TLabel.Create(Self);
    T.Parent := pnlCompPage;
    T.Caption := AType;
    T.Left := 12;
    T.Top := 40;
    T.Font.Style := [fsBold];

    // Ширина колонки подписей - по самой длинной
    LabW := 0;
    for I := 0 to Fields.Count - 1 do
    begin
      P := Pos('|', Fields[I]);
      Cap := Copy(Fields[I], P + 1, Length(Fields[I]));
      if Bmp.Canvas.TextWidth(Cap) > LabW then
        LabW := Bmp.Canvas.TextWidth(Cap);
    end;
    Inc(LabW, 16);

    Ini := nil;
    if (Form1 <> nil) and FileExists(Form1.SettingsFileName) then
      Ini := TIniFile.Create(Form1.SettingsFileName);
    try
      Y := 66;
      SetLength(FCompEdits, Fields.Count);
      SetLength(FCompKeys, Fields.Count);
      SetLength(FCompIsList, Fields.Count);

      for I := 0 to Fields.Count - 1 do
      begin
        P := Pos('|', Fields[I]);
        Key := Copy(Fields[I], 1, P - 1);
        Cap := Copy(Fields[I], P + 1, Length(Fields[I]));
        NoBrowse := (Key <> '') and (Key[1] = '-');
        FCompIsList[I] := NoBrowse;
        if NoBrowse then
          Key := Copy(Key, 2, Length(Key));
        FCompKeys[I] := Key;

        L := TLabel.Create(Self);
        L.Parent := pnlCompPage;
        L.Caption := Cap;
        L.Left := 12;
        L.Top := Y + 4;

        E := TUiEdit.Create(Self);
        E.Parent := pnlCompPage;
        E.Left := 12 + LabW;
        E.Top := Y;
        E.Width := pnlCompPage.ClientWidth - E.Left - 46;
        E.Anchors := [akLeft, akTop, akRight];
        E.Tag := I;
        if Ini <> nil then
          E.Text := Ini.ReadString(CompIniSection(Key), CompIniKey(Key), '');
        E.OnChange := CompEditChange;
        E.OnExit := CompEditExit;   // нормализация при уходе из поля
        FCompEdits[I] := E;

        // Кнопка выбора: у папки и файла - системный диалог, у списка
        // путей (поля со знаком минус перед ключом в таблице) - окно
        // списка, EditPathList
        B := TUiButton.Create(Self);
        B.Parent := pnlCompPage;
        B.Caption := '...';
        B.Left := E.Left + E.Width + 4;
        B.Top := Y - 1;
        B.Width := 30;
        B.Height := 23;
        B.Anchors := [akTop, akRight];
        B.Tag := I;
        B.OnClick := CompBrowseClick;

        Inc(Y, 28);
      end;
    finally
      if Ini <> nil then
        Ini.Free;
    end;
  finally
    Bmp.Free;
    Fields.Free;
  end;

  // Порядок поиска модулей при сборке Delphi - под полями
  if AType = 'Delphi' then
  begin
    L := TLabel.Create(Self);
    L.Parent := pnlCompPage;
    L.Left := 12;
    L.Top := Y + 8;
    L.AutoSize := False;
    L.WordWrap := True;
    L.Width := pnlCompPage.ClientWidth - 24;
    L.Height := 150;
    L.Anchors := [akLeft, akTop, akRight];
    L.Caption :=
      'Модули при сборке (dcc32 -U, -I, -O, -R) ищутся по порядку: папка ' +
      'проекта; Search path проекта из его .dof; UiLib рядом с программой ' +
      '(туда копируются Ui*.pas из папки Ui components; она пустая - из ' +
      'папки программы, папки проекта редактора или папок выше программы); ' +
      'Library path. Browsing path компилятору не передаётся, как и в самой ' +
      'Delphi.' + #13#10#13#10 +
      'Папки, которых нет на этом компьютере, в списках остаются (они могут ' +
      'быть с другого компьютера) и при сборке пропускаются; удалить их - ' +
      'кнопка ... и Delete invalid.';
  end;

  // Значения из editor.ini приводим в порядок сразу, не дожидаясь, пока
  // человек зайдёт в поле: макросы разворачиваем, файлы заменяем папками и
  // записываем обратно уже раскрытыми. Иначе строка с $(...) дожила бы до
  // сборки и обернулась ошибкой компилятора.
  NormalizeCompFields;
end;

// ---------------------------------------------------------------------------
//  Пути Delphi из реестра (Compilers - Delphi, «Взять из Delphi»)
// ---------------------------------------------------------------------------

// Развернуть $(DELPHI) и прочие переменные среды Delphi: список - в той же
// ветке реестра (AKey), в Environment Variables; не раскрылось - шире, по
// всем установкам (переменные от установщиков компонентов лежат в HKLM)
function TForm2.ExpandDelphiRegVars(const S, ARoot, AKey: string): string;
var
  Vars: TStringList;
  VarIdx: Integer;
  Reg: TRegistry;
begin
  Result := S;
  if ARoot <> '' then
    Result := StringReplace(Result, '$(DELPHI)',
                ExcludeTrailingPathDelimiter(ARoot),
                [rfReplaceAll, rfIgnoreCase]);

  Vars := TStringList.Create;
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if (AKey <> '') and
       Reg.OpenKeyReadOnly(AKey + '\Environment Variables') then
    begin
      Reg.GetValueNames(Vars);
      for VarIdx := 0 to Vars.Count - 1 do
        Result := StringReplace(Result, '$(' + Vars[VarIdx] + ')',
                    Reg.ReadString(Vars[VarIdx]), [rfReplaceAll, rfIgnoreCase]);
      Reg.CloseKey;
    end;

    if Pos('$(', Result) > 0 then
    begin
      Vars.Clear;
      CollectDelphiVars(Vars);
      for VarIdx := 0 to Vars.Count - 1 do
        Result := StringReplace(Result, '$(' + Vars.Names[VarIdx] + ')',
                    ExcludeTrailingPathDelimiter(Vars.Values[Vars.Names[VarIdx]]),
                    [rfReplaceAll, rfIgnoreCase]);
    end;
  finally
    Reg.Free;
    Vars.Free;
  end;
end;

// Ветка реестра установки Delphi: та, чей RootDir совпадает с ARoot; нет
// такой - по имени инструмента (Delphi 7, BDS 22.0); нет и его - если
// установка одна, она. '' - не нашлось. AFoundRoot - её RootDir.
function TForm2.FindDelphiRegKey(const ARoot, ATool: string;
                                 var AFoundRoot: string): string;
var
  Reg: TRegistry;
  Keys: TStringList;
  BranchIdx, KeyIdx, Installs: Integer;
  Branch, RootDir, ToolName, ByName, ByNameRoot, Single, SingleRoot: string;
begin
  Result := '';
  AFoundRoot := '';
  ByName := '';
  ByNameRoot := '';
  Single := '';
  SingleRoot := '';
  Installs := 0;
  Reg := TRegistry.Create;
  Keys := TStringList.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    for BranchIdx := 0 to 1 do
    begin
      if BranchIdx = 0 then
        Branch := 'Software\Borland\Delphi'
      else
        Branch := 'Software\Embarcadero\BDS';
      Keys.Clear;
      if not Reg.OpenKeyReadOnly(Branch) then
        Continue;
      Reg.GetKeyNames(Keys);
      Reg.CloseKey;
      for KeyIdx := 0 to Keys.Count - 1 do
      begin
        if not Reg.OpenKeyReadOnly(Branch + '\' + Keys[KeyIdx]) then
          Continue;
        RootDir := Reg.ReadString('RootDir');
        Reg.CloseKey;
        if (RootDir = '') or not DirectoryExists(RootDir) then
          Continue;
        Inc(Installs);
        Single := Branch + '\' + Keys[KeyIdx];
        SingleRoot := RootDir;
        if (ARoot <> '') and
           (CompareText(ExcludeTrailingPathDelimiter(ARoot),
                        ExcludeTrailingPathDelimiter(RootDir)) = 0) then
        begin
          Result := Single;
          AFoundRoot := RootDir;
          Exit;
        end;
        if BranchIdx = 0 then
          ToolName := 'Delphi ' + Copy(Keys[KeyIdx], 1,
                                       Pos('.', Keys[KeyIdx] + '.') - 1)
        else
          ToolName := 'BDS ' + Keys[KeyIdx];
        if CompareText(ToolName, ATool) = 0 then
        begin
          ByName := Single;
          ByNameRoot := RootDir;
        end;
      end;
    end;
  finally
    Keys.Free;
    Reg.Free;
  end;
  if ByName <> '' then
  begin
    Result := ByName;
    AFoundRoot := ByNameRoot;
  end
  else if Installs = 1 then
  begin
    Result := Single;
    AFoundRoot := SingleRoot;
  end;
end;

// Номер поля страницы Compilers по ключу; -1 - нет такого
function TForm2.CompFieldIdx(const AKey: string): Integer;
var
  FieldIdx: Integer;
begin
  Result := -1;
  for FieldIdx := 0 to High(FCompKeys) do
    if CompareText(FCompKeys[FieldIdx], AKey) = 0 then
    begin
      Result := FieldIdx;
      Exit;
    end;
end;

// Где в editor.ini лежит поле страницы: почти все - в разделе типа и
// инструмента (FCompSection); папка исходников своих компонентов Ui* - в
// общем разделе [UiLib], ключ Source (её читает UiLibDir в Unit1)
function TForm2.CompIniSection(const AKey: string): string;
begin
  if CompareText(AKey, 'UiSource') = 0 then
    Result := 'UiLib'
  else
    Result := FCompSection;
end;

function TForm2.CompIniKey(const AKey: string): string;
begin
  if CompareText(AKey, 'UiSource') = 0 then
    Result := 'Source'
  else
    Result := AKey;
end;

// ---------------------------------------------------------------------------
//  Вкладка Arduino: настройки arduino-cli (как вкладка Arduino в IDE Options
//  RQdebugger). Ключи - те же, что на странице Compilers - Arduino
//  ([Compiler.Arduino] editor.ini); правка сразу пишется в editor.ini, поле
//  с тем же ключом на странице Compilers обновляется.
// ---------------------------------------------------------------------------

const
  // Поля путей: ключ | подпись кнопки | подсказка
  ArdPathFields: array[0..8] of string = (
    'SketchPath|Sketch path|Sketchbook (directories.user arduino-cli)',
    'CliFile|Arduino CLI file|arduino-cli.exe',
    'BuildPath|Build Path|Папка, куда сохраняются собранные файлы (--build-path)',
    'LibPath|Library Path|Папки своих библиотек (--libraries)',
    'LogFile|Log file|Файл лога сборки (--log-file)',
    'CliCfgFile|Cli cfg file|arduino-cli.yaml (--config-file)',
    'CliDataPath|Cli Data Path|directories.data: индексы, платформы (packages)',
    'DownloadsPath|Cli Downloads Path|directories.downloads: скачанные архивы',
    'Arduino15Path|Ard15 Default Path|Папка Arduino IDE (%LOCALAPPDATA%\Arduino15): ' +
      'там тоже ищутся платформы и library_index.json');
  ArdWarningItems: array[0..3] of string = ('none', 'default', 'more', 'all');
  ArdLogLevelItems: array[0..6] of string = (
    'trace', 'debug', 'info', 'warn', 'error', 'fatal', 'panic');

// Поле AIndex (от нуля) строки "a|b|c"
function ArdBarField(const AText: string; AIndex: Integer): string;
var
  Rest: string;
  BarPos, FieldIdx: Integer;
begin
  Rest := AText;
  for FieldIdx := 0 to AIndex - 1 do
  begin
    BarPos := Pos('|', Rest);
    if BarPos = 0 then
    begin
      Result := '';
      Exit;
    end;
    Rest := Copy(Rest, BarPos + 1, Length(Rest));
  end;
  BarPos := Pos('|', Rest);
  if BarPos > 0 then
    Result := Copy(Rest, 1, BarPos - 1)
  else
    Result := Rest;
end;

procedure TForm2.BuildArduinoTab(ATab: TTabSheet);
var
  InnerPages: TUiPageControl;
  TabSettings, TabNetwork, TabCfg: TTabSheet;
  PnlTop, PnlBottom, PnlCfgTop: TPanel;
  FieldEdit: TUiEdit;
  BrowseBtn, ImportBtn, CfgReloadBtn, CfgWriteBtn: TUiButton;
  TextLbl: TLabel;
  RowIdx, RowTop, ItemIdx: Integer;
begin
  FArdTab := ATab;

  InnerPages := TUiPageControl.Create(Self);
  InnerPages.Parent := ATab;
  InnerPages.Align := alClient;
  TabSettings := TTabSheet.Create(Self);
  TabSettings.PageControl := InnerPages;
  TabSettings.Caption := 'Settings';
  TabNetwork := TTabSheet.Create(Self);
  TabNetwork.PageControl := InnerPages;
  TabNetwork.Caption := 'Network';
  TabCfg := TTabSheet.Create(Self);
  TabCfg.PageControl := InnerPages;
  TabCfg.Caption := 'Cli config file';
  InnerPages.ActivePage := TabSettings;

  // --- Settings: пути, уровни, флажки ---
  PnlTop := TPanel.Create(Self);
  PnlTop.Parent := TabSettings;
  PnlTop.Align := alTop;
  PnlTop.Height := 392;
  PnlTop.BevelOuter := bvNone;
  PnlTop.Caption := '';
  FArdTop := PnlTop;

  // Ширина полей и место кнопок - в ArdTopResize, по ширине панели: при
  // постройке она ещё не та, что будет на экране (выравнивание alTop
  // применится позже), и привязка к правому краю считалась бы от неё
  SetLength(FArdEdits, Length(ArdPathFields));
  SetLength(FArdEditKeys, Length(ArdPathFields));
  SetLength(FArdPathBtns, Length(ArdPathFields));
  RowTop := 10;
  for RowIdx := 0 to High(ArdPathFields) do
  begin
    FArdEditKeys[RowIdx] := ArdBarField(ArdPathFields[RowIdx], 0);

    FieldEdit := TUiEdit.Create(Self);
    FieldEdit.Parent := PnlTop;
    FieldEdit.Left := 8;
    FieldEdit.Top := RowTop;
    FieldEdit.Width := 300;
    FieldEdit.Tag := RowIdx;
    FieldEdit.ShowHint := True;
    FieldEdit.Hint := ArdBarField(ArdPathFields[RowIdx], 2);
    FieldEdit.OnChange := ArdEditChange;
    FArdEdits[RowIdx] := FieldEdit;

    BrowseBtn := TUiButton.Create(Self);
    BrowseBtn.Parent := PnlTop;
    BrowseBtn.Left := FieldEdit.Left + FieldEdit.Width + 6;
    BrowseBtn.Top := RowTop - 1;
    BrowseBtn.Width := 150;
    BrowseBtn.Height := 23;
    FArdPathBtns[RowIdx] := BrowseBtn;
    BrowseBtn.Caption := ArdBarField(ArdPathFields[RowIdx], 1);
    BrowseBtn.ShowHint := True;
    BrowseBtn.Hint := FieldEdit.Hint;
    BrowseBtn.Tag := RowIdx;
    BrowseBtn.OnClick := ArdBrowseClick;

    Inc(RowTop, 26);
  end;

  Inc(RowTop, 8);
  TextLbl := TLabel.Create(Self);
  TextLbl.Parent := PnlTop;
  TextLbl.Caption := 'Warnings';
  TextLbl.Left := 8;
  TextLbl.Top := RowTop + 4;
  cbArdWarnings := TUiComboBox.Create(Self);
  cbArdWarnings.Parent := PnlTop;
  cbArdWarnings.Style := csDropDownList;
  cbArdWarnings.Left := 80;
  cbArdWarnings.Top := RowTop;
  cbArdWarnings.Width := 100;
  cbArdWarnings.ShowHint := True;
  cbArdWarnings.Hint := 'Уровень предупреждений gcc (--warnings)';
  for ItemIdx := Low(ArdWarningItems) to High(ArdWarningItems) do
    cbArdWarnings.Items.Add(ArdWarningItems[ItemIdx]);
  cbArdWarnings.OnChange := ArdOptionChange;

  TextLbl := TLabel.Create(Self);
  TextLbl.Parent := PnlTop;
  TextLbl.Caption := 'Log level';
  TextLbl.Left := 220;
  TextLbl.Top := RowTop + 4;
  cbArdLogLevel := TUiComboBox.Create(Self);
  cbArdLogLevel.Parent := PnlTop;
  cbArdLogLevel.Style := csDropDownList;
  cbArdLogLevel.Left := 290;
  cbArdLogLevel.Top := RowTop;
  cbArdLogLevel.Width := 100;
  cbArdLogLevel.ShowHint := True;
  cbArdLogLevel.Hint := 'Сообщения этого уровня и выше пишутся в лог ' +
                        '(--log-level)';
  for ItemIdx := Low(ArdLogLevelItems) to High(ArdLogLevelItems) do
    cbArdLogLevel.Items.Add(ArdLogLevelItems[ItemIdx]);
  cbArdLogLevel.OnChange := ArdOptionChange;

  Inc(RowTop, 30);
  TextLbl := TLabel.Create(Self);
  TextLbl.Parent := PnlTop;
  TextLbl.Caption := 'Show verbose output during';
  TextLbl.Left := 8;
  TextLbl.Top := RowTop + 2;
  chkArdCompileVerbose := TUiCheckBox.Create(Self);
  chkArdCompileVerbose.Parent := PnlTop;
  chkArdCompileVerbose.Caption := 'Compilation';
  chkArdCompileVerbose.Left := 200;
  chkArdCompileVerbose.Top := RowTop;
  chkArdCompileVerbose.Width := 110;
  chkArdCompileVerbose.OnClick := ArdOptionChange;
  chkArdUploadVerbose := TUiCheckBox.Create(Self);
  chkArdUploadVerbose.Parent := PnlTop;
  chkArdUploadVerbose.Caption := 'Upload';
  chkArdUploadVerbose.Left := 320;
  chkArdUploadVerbose.Top := RowTop;
  chkArdUploadVerbose.Width := 90;
  chkArdUploadVerbose.OnClick := ArdOptionChange;

  Inc(RowTop, 24);
  chkArdVerifyAfterUpload := TUiCheckBox.Create(Self);
  chkArdVerifyAfterUpload.Parent := PnlTop;
  chkArdVerifyAfterUpload.Caption := 'Verify code after upload';
  chkArdVerifyAfterUpload.Left := 8;
  chkArdVerifyAfterUpload.Top := RowTop;
  chkArdVerifyAfterUpload.Width := 300;
  chkArdVerifyAfterUpload.OnClick := ArdOptionChange;

  Inc(RowTop, 24);
  chkArdSaveBeforeBuild := TUiCheckBox.Create(Self);
  chkArdSaveBeforeBuild.Parent := PnlTop;
  chkArdSaveBeforeBuild.Caption := 'Save sketch when verifying or uploading';
  chkArdSaveBeforeBuild.Left := 8;
  chkArdSaveBeforeBuild.Top := RowTop;
  chkArdSaveBeforeBuild.Width := 340;
  chkArdSaveBeforeBuild.OnClick := ArdOptionChange;

  Inc(RowTop, 28);
  TextLbl := TLabel.Create(Self);
  TextLbl.Parent := PnlTop;
  TextLbl.Caption := 'Additional Boards Manager URLs (по одному в строке; ' +
                     'в arduino-cli уходят только адреса http(s))';
  TextLbl.Left := 8;
  TextLbl.Top := RowTop;
  PnlTop.Height := RowTop + 22;
  PnlTop.OnResize := ArdTopResize;

  PnlBottom := TPanel.Create(Self);
  PnlBottom.Parent := TabSettings;
  PnlBottom.Align := alBottom;
  PnlBottom.Height := 34;
  PnlBottom.BevelOuter := bvNone;
  PnlBottom.Caption := '';
  ImportBtn := TUiButton.Create(Self);
  ImportBtn.Parent := PnlBottom;
  ImportBtn.Left := 8;
  ImportBtn.Top := 5;
  ImportBtn.Width := 160;
  ImportBtn.Height := 24;
  ImportBtn.Caption := 'Импорт из RQdb.ini';
  ImportBtn.ShowHint := True;
  ImportBtn.Hint := 'Пути Arduino из RQdb.ini RQdebugger (раздел ' +
                    '[Arduino]) и Additional URLs из AdditURLEdit.txt';
  ImportBtn.OnClick := btnArdImportClick;

  memArdUrls := TUiMemo.Create(Self);
  memArdUrls.Parent := TabSettings;
  memArdUrls.Align := alClient;
  memArdUrls.ScrollBars := ssBoth;
  memArdUrls.WordWrap := False;
  memArdUrls.OnChange := ArdUrlsChange;

  BuildArduinoNetwork(TabNetwork);

  // Надписи (TLabel) рисует родитель: без буфера при смене размера окна
  // фон под ними стирается и рисуется заново - надписи моргают. Буфер - у
  // родителей надписей и у поля адресов (так же сделано в главном окне,
  // FormCreate: панели, которые мерцали при смене ширины)
  TabSettings.DoubleBuffered := True;
  TabNetwork.DoubleBuffered := True;
  TabCfg.DoubleBuffered := True;
  PnlTop.DoubleBuffered := True;
  PnlBottom.DoubleBuffered := True;
  memArdUrls.DoubleBuffered := True;

  // --- Cli config file: arduino-cli.yaml ---
  PnlCfgTop := TPanel.Create(Self);
  PnlCfgTop.Parent := TabCfg;
  PnlCfgTop.Align := alTop;
  PnlCfgTop.Height := 34;
  PnlCfgTop.BevelOuter := bvNone;
  PnlCfgTop.Caption := '';
  PnlCfgTop.DoubleBuffered := True;
  CfgReloadBtn := TUiButton.Create(Self);
  CfgReloadBtn.Parent := PnlCfgTop;
  CfgReloadBtn.Left := 8;
  CfgReloadBtn.Top := 5;
  CfgReloadBtn.Width := 110;
  CfgReloadBtn.Height := 24;
  CfgReloadBtn.Caption := 'Перечитать';
  CfgReloadBtn.OnClick := ArdCfgLoadClick;
  CfgWriteBtn := TUiButton.Create(Self);
  CfgWriteBtn.Parent := PnlCfgTop;
  CfgWriteBtn.Left := 124;
  CfgWriteBtn.Top := 5;
  CfgWriteBtn.Width := 190;
  CfgWriteBtn.Height := 24;
  CfgWriteBtn.Caption := 'Записать пути в yaml';
  CfgWriteBtn.ShowHint := True;
  CfgWriteBtn.Hint := 'arduino-cli config set: directories.data = Cli Data ' +
                      'Path, directories.downloads = Cli Downloads Path, ' +
                      'directories.user = Sketch path. Нет файла - сначала ' +
                      'config init';
  CfgWriteBtn.OnClick := ArdCfgWriteClick;
  lblArdCfgState := TLabel.Create(Self);
  lblArdCfgState.Parent := PnlCfgTop;
  lblArdCfgState.Left := 324;
  lblArdCfgState.Top := 9;
  lblArdCfgState.Caption := '';

  memArdCfg := TUiMemo.Create(Self);
  memArdCfg.Parent := TabCfg;
  memArdCfg.Align := alClient;
  memArdCfg.ReadOnly := True;
  memArdCfg.ScrollBars := ssBoth;
  memArdCfg.WordWrap := False;
  memArdCfg.Font.Name := 'Courier New';
  memArdCfg.Font.Size := 9;

  ArdTabLoad;
  ArdTopResize(nil);
end;

// Поля путей - на всю ширину панели, кнопки выбора - у правого края
procedure TForm2.ArdTopResize(Sender: TObject);
const
  BtnWidth = 150;
var
  RowIdx, EditWidth: Integer;
begin
  if FArdTop = nil then
    Exit;
  EditWidth := FArdTop.ClientWidth - 8 - BtnWidth - 14;
  if EditWidth < 120 then
    EditWidth := 120;
  for RowIdx := 0 to High(FArdEdits) do
  begin
    FArdEdits[RowIdx].Width := EditWidth;
    if RowIdx <= High(FArdPathBtns) then
      FArdPathBtns[RowIdx].Left := FArdEdits[RowIdx].Left + EditWidth + 6;
  end;
end;

// Лист Network - прокси, как вкладка Network в настройках Arduino IDE:
// без прокси, определять автоматически (с адресом файла настройки или без),
// вручную (HTTP или SOCKS, хост, порт, имя, пароль). Значения - в
// [Compiler.Arduino]: ProxyMode (none, auto, manual), ProxyAutoUrlOn,
// ProxyAutoUrl, ProxyType (http, socks), ProxyHost, ProxyPort, ProxyUser,
// ProxyPassword. В arduino-cli пока не передаются.
procedure TForm2.BuildArduinoNetwork(ATab: TTabSheet);
var
  PnlType: TPanel;
  TextLbl: TLabel;
  RowTop: Integer;

  function AddRadio(AParent: TWinControl; const ACaption: string;
                    ALeft, ATop, AWidth: Integer): TUiRadioButton;
  begin
    Result := TUiRadioButton.Create(Self);
    Result.Parent := AParent;
    Result.Caption := ACaption;
    Result.Left := ALeft;
    Result.Top := ATop;
    Result.Width := AWidth;
    Result.OnClick := ArdNetChange;
  end;

  function AddEdit(const ALabel: string; ATop, AWidth: Integer): TUiEdit;
  begin
    TextLbl := TLabel.Create(Self);
    TextLbl.Parent := ATab;
    TextLbl.Caption := ALabel;
    TextLbl.Left := 50;
    TextLbl.Top := ATop + 4;
    Result := TUiEdit.Create(Self);
    Result.Parent := ATab;
    Result.Left := 180;
    Result.Top := ATop;
    Result.Width := AWidth;
    Result.OnChange := ArdNetChange;
  end;

begin
  RowTop := 12;
  rbArdProxyNone := AddRadio(ATab, 'No proxy', 8, RowTop, 300);
  Inc(RowTop, 26);
  rbArdProxyAuto := AddRadio(ATab, 'Auto-detect proxy settings', 8, RowTop,
                             300);
  Inc(RowTop, 26);
  chkArdProxyAutoUrl := TUiCheckBox.Create(Self);
  chkArdProxyAutoUrl.Parent := ATab;
  chkArdProxyAutoUrl.Caption := 'Automatic proxy configuration URL:';
  chkArdProxyAutoUrl.Left := 30;
  chkArdProxyAutoUrl.Top := RowTop;
  chkArdProxyAutoUrl.Width := 260;
  chkArdProxyAutoUrl.OnClick := ArdNetChange;
  Inc(RowTop, 24);
  edArdProxyAutoUrl := TUiEdit.Create(Self);
  edArdProxyAutoUrl.Parent := ATab;
  edArdProxyAutoUrl.Left := 50;
  edArdProxyAutoUrl.Top := RowTop;
  edArdProxyAutoUrl.Width := 400;
  edArdProxyAutoUrl.OnChange := ArdNetChange;
  Inc(RowTop, 34);
  rbArdProxyManual := AddRadio(ATab, 'Manual proxy configuration', 8,
                               RowTop, 300);
  Inc(RowTop, 26);

  // HTTP / SOCKS - своя группа: переключатели выбираются в пределах
  // родителя
  PnlType := TPanel.Create(Self);
  PnlType.Parent := ATab;
  PnlType.Left := 44;
  PnlType.Top := RowTop;
  PnlType.Width := 260;
  PnlType.Height := 24;
  PnlType.BevelOuter := bvNone;
  PnlType.Caption := '';
  rbArdProxyHttp := AddRadio(PnlType, 'HTTP', 6, 2, 80);
  rbArdProxySocks := AddRadio(PnlType, 'SOCKS', 100, 2, 90);
  Inc(RowTop, 32);

  edArdProxyHost := AddEdit('Host name:', RowTop, 270);
  Inc(RowTop, 28);
  edArdProxyPort := AddEdit('Port number:', RowTop, 80);
  Inc(RowTop, 28);
  edArdProxyUser := AddEdit('Username:', RowTop, 200);
  Inc(RowTop, 28);
  edArdProxyPassword := AddEdit('Password:', RowTop, 200);
  edArdProxyPassword.PasswordChar := '*';
  Inc(RowTop, 36);

  TextLbl := TLabel.Create(Self);
  TextLbl.Parent := ATab;
  TextLbl.Left := 8;
  TextLbl.Top := RowTop;
  TextLbl.Width := 520;
  TextLbl.Height := 48;
  TextLbl.AutoSize := False;
  TextLbl.WordWrap := True;
  TextLbl.Caption := 'Настройки хранятся в editor.ini ([Compiler.Arduino], ' +
                     'пароль - открытым текстом). В arduino-cli пока не ' +
                     'передаются.';
end;

// Доступность полей по выбранному режиму прокси
procedure TForm2.ArdNetEnable;
var
  Manual: Boolean;
begin
  chkArdProxyAutoUrl.Enabled := rbArdProxyAuto.Checked;
  edArdProxyAutoUrl.Enabled := rbArdProxyAuto.Checked and
                               chkArdProxyAutoUrl.Checked;
  Manual := rbArdProxyManual.Checked;
  rbArdProxyHttp.Enabled := Manual;
  rbArdProxySocks.Enabled := Manual;
  edArdProxyHost.Enabled := Manual;
  edArdProxyPort.Enabled := Manual;
  edArdProxyUser.Enabled := Manual;
  edArdProxyPassword.Enabled := Manual;
end;

// Любая правка на листе Network - все его значения в editor.ini
procedure TForm2.ArdNetChange(Sender: TObject);
var
  ModeText, TypeText, AutoUrlOn: string;
begin
  if FArdLoading then
    Exit;
  if rbArdProxyAuto.Checked then
    ModeText := 'auto'
  else if rbArdProxyManual.Checked then
    ModeText := 'manual'
  else
    ModeText := 'none';
  if rbArdProxySocks.Checked then
    TypeText := 'socks'
  else
    TypeText := 'http';
  if chkArdProxyAutoUrl.Checked then
    AutoUrlOn := '1'
  else
    AutoUrlOn := '0';
  ArdWrite('ProxyMode', ModeText);
  ArdWrite('ProxyAutoUrlOn', AutoUrlOn);
  ArdWrite('ProxyAutoUrl', Trim(edArdProxyAutoUrl.Text));
  ArdWrite('ProxyType', TypeText);
  ArdWrite('ProxyHost', Trim(edArdProxyHost.Text));
  ArdWrite('ProxyPort', Trim(edArdProxyPort.Text));
  ArdWrite('ProxyUser', edArdProxyUser.Text);
  ArdWrite('ProxyPassword', edArdProxyPassword.Text);
  ArdNetEnable;
end;

// Раздел настроек Arduino - как его читает ArduinoCli (с инструментом по
// умолчанию, если он выбран на странице Compilers)
function TForm2.ArdSection: string;
begin
  if Form1 <> nil then
    Result := ArdLoadSettings(Form1.SettingsFileName).Section
  else
    Result := ArdIniSection;
end;

procedure TForm2.ArdWrite(const AKey, AValue: string);
begin
  if (Form1 = nil) or FArdLoading then
    Exit;
  ArdSaveSetting(Form1.SettingsFileName, ArdSection, AKey, AValue);
end;

// Значения из editor.ini - в элементы вкладки (при построении, показе окна
// настроек, переходе на вкладку и после импорта)
procedure TForm2.ArdTabLoad;
var
  Ini: TIniFile;
  Section, Value: string;
  RowIdx: Integer;
begin
  if (FArdTab = nil) or (Form1 = nil) then
    Exit;
  Section := ArdSection;
  FArdLoading := True;
  Ini := TIniFile.Create(Form1.SettingsFileName);
  try
    for RowIdx := 0 to High(FArdEdits) do
      FArdEdits[RowIdx].Text := Ini.ReadString(Section, FArdEditKeys[RowIdx],
                                               '');

    Value := LowerCase(Trim(Ini.ReadString(Section, 'Warnings', 'none')));
    cbArdWarnings.ItemIndex := cbArdWarnings.Items.IndexOf(Value);
    if cbArdWarnings.ItemIndex < 0 then
      cbArdWarnings.ItemIndex := 0;   // none
    Value := LowerCase(Trim(Ini.ReadString(Section, 'LogLevel', 'info')));
    cbArdLogLevel.ItemIndex := cbArdLogLevel.Items.IndexOf(Value);
    if cbArdLogLevel.ItemIndex < 0 then
      cbArdLogLevel.ItemIndex := cbArdLogLevel.Items.IndexOf('info');

    chkArdCompileVerbose.Checked := Ini.ReadString(Section, 'CompileVerbose',
                                                   '0') = '1';
    chkArdUploadVerbose.Checked := Ini.ReadString(Section, 'UploadVerbose',
                                                  '0') = '1';
    chkArdVerifyAfterUpload.Checked := Ini.ReadString(Section,
                                         'VerifyAfterUpload', '0') = '1';
    chkArdSaveBeforeBuild.Checked := Ini.ReadString(Section,
                                       'SaveBeforeBuild', '0') = '1';

    memArdUrls.Lines.Text := StringReplace(
      Ini.ReadString(Section, 'AdditionalUrls', ''), ',', #13#10,
      [rfReplaceAll]);

    Value := LowerCase(Trim(Ini.ReadString(Section, 'ProxyMode', 'none')));
    rbArdProxyAuto.Checked := Value = 'auto';
    rbArdProxyManual.Checked := Value = 'manual';
    rbArdProxyNone.Checked := (Value <> 'auto') and (Value <> 'manual');
    chkArdProxyAutoUrl.Checked := Ini.ReadString(Section, 'ProxyAutoUrlOn',
                                                 '0') = '1';
    edArdProxyAutoUrl.Text := Ini.ReadString(Section, 'ProxyAutoUrl', '');
    Value := LowerCase(Trim(Ini.ReadString(Section, 'ProxyType', 'http')));
    rbArdProxySocks.Checked := Value = 'socks';
    rbArdProxyHttp.Checked := Value <> 'socks';
    edArdProxyHost.Text := Ini.ReadString(Section, 'ProxyHost', '');
    edArdProxyPort.Text := Ini.ReadString(Section, 'ProxyPort', '');
    edArdProxyUser.Text := Ini.ReadString(Section, 'ProxyUser', '');
    edArdProxyPassword.Text := Ini.ReadString(Section, 'ProxyPassword', '');
    ArdNetEnable;
  finally
    Ini.Free;
    FArdLoading := False;
  end;
  ArdCfgLoadClick(nil);
end;

// Поле пути с ключом AKey - новое значение (правка на странице Compilers)
procedure TForm2.ArdTabSetField(const AKey, AValue: string);
var
  RowIdx: Integer;
begin
  for RowIdx := 0 to High(FArdEdits) do
    if (CompareText(FArdEditKeys[RowIdx], AKey) = 0) and
       (FArdEdits[RowIdx].Text <> AValue) then
    begin
      FArdLoading := True;
      try
        FArdEdits[RowIdx].Text := AValue;
      finally
        FArdLoading := False;
      end;
    end;
end;

procedure TForm2.ArdEditChange(Sender: TObject);
var
  RowIdx, CompIdx: Integer;
  Value: string;
begin
  if FArdLoading then
    Exit;
  RowIdx := TUiEdit(Sender).Tag;
  if (RowIdx < 0) or (RowIdx > High(FArdEditKeys)) then
    Exit;
  Value := TUiEdit(Sender).Text;
  ArdWrite(FArdEditKeys[RowIdx], Value);

  // То же поле на странице Compilers - Arduino, если она открыта: иначе
  // при уходе с неё прежнее значение записалось бы обратно
  if (CompareText(FCompType, 'Arduino') = 0) and
     (CompareText(FCompSection, ArdSection) = 0) then
  begin
    CompIdx := CompFieldIdx(FArdEditKeys[RowIdx]);
    if (CompIdx >= 0) and (FCompEdits[CompIdx] <> nil) and
       (FCompEdits[CompIdx].Text <> Value) then
      FCompEdits[CompIdx].Text := Value;
  end;
end;

procedure TForm2.ArdBrowseClick(Sender: TObject);
var
  RowIdx: Integer;
  Dir: string;
  Dlg: TOpenDialog;
begin
  RowIdx := TUiButton(Sender).Tag;
  if (RowIdx < 0) or (RowIdx > High(FArdEdits)) then
    Exit;
  if IsFileKey(FArdEditKeys[RowIdx]) then
  begin
    Dlg := TOpenDialog.Create(Self);
    try
      Dlg.Title := 'Выберите файл';
      Dlg.FileName := FArdEdits[RowIdx].Text;
      if Dlg.Execute then
        FArdEdits[RowIdx].Text := Dlg.FileName;   // OnChange пишет в ini
    finally
      Dlg.Free;
    end;
  end
  else
  begin
    Dir := FArdEdits[RowIdx].Text;
    if BrowseFolderDialog('Выберите папку', Dir) then
      FArdEdits[RowIdx].Text := IncludeTrailingPathDelimiter(Dir);
  end;
end;

// Warnings, Log level и флажки
procedure TForm2.ArdOptionChange(Sender: TObject);

  function Flag(ABox: TUiCheckBox): string;
  begin
    if ABox.Checked then
      Result := '1'
    else
      Result := '0';
  end;

begin
  if FArdLoading then
    Exit;
  if Sender = cbArdWarnings then
  begin
    if cbArdWarnings.ItemIndex >= 0 then
      ArdWrite('Warnings', cbArdWarnings.Items[cbArdWarnings.ItemIndex]);
  end
  else if Sender = cbArdLogLevel then
  begin
    if cbArdLogLevel.ItemIndex >= 0 then
      ArdWrite('LogLevel', cbArdLogLevel.Items[cbArdLogLevel.ItemIndex]);
  end
  else if Sender = chkArdCompileVerbose then
    ArdWrite('CompileVerbose', Flag(chkArdCompileVerbose))
  else if Sender = chkArdUploadVerbose then
    ArdWrite('UploadVerbose', Flag(chkArdUploadVerbose))
  else if Sender = chkArdVerifyAfterUpload then
    ArdWrite('VerifyAfterUpload', Flag(chkArdVerifyAfterUpload))
  else if Sender = chkArdSaveBeforeBuild then
    ArdWrite('SaveBeforeBuild', Flag(chkArdSaveBeforeBuild));
end;

// Список адресов - в editor.ini через запятую, все непустые строки как
// есть (во время набора адрес ещё не похож на http); в arduino-cli уходят
// только http(s) - отбор при запуске (ArdHttpUrls)
procedure TForm2.ArdUrlsChange(Sender: TObject);
var
  LineIdx: Integer;
  Joined, LineText: string;
begin
  if FArdLoading then
    Exit;
  Joined := '';
  for LineIdx := 0 to memArdUrls.Lines.Count - 1 do
  begin
    LineText := Trim(memArdUrls.Lines[LineIdx]);
    if LineText = '' then
      Continue;
    if Joined <> '' then
      Joined := Joined + ',';
    Joined := Joined + LineText;
  end;
  ArdWrite('AdditionalUrls', Joined);
end;

// arduino-cli.yaml - на вкладку Cli config file (файл в UTF-8)
procedure TForm2.ArdCfgLoadClick(Sender: TObject);
var
  Settings: TArdSettings;
  CfgLines: TStringList;
begin
  if (memArdCfg = nil) or (Form1 = nil) then
    Exit;
  Settings := ArdLoadSettings(Form1.SettingsFileName);
  memArdCfg.Lines.Clear;
  if Settings.CliCfgFile = '' then
  begin
    lblArdCfgState.Caption := 'Не задан Cli cfg file (вкладка Settings)';
    Exit;
  end;
  if not FileExists(Settings.CliCfgFile) then
  begin
    lblArdCfgState.Caption := 'Нет файла ' + Settings.CliCfgFile;
    Exit;
  end;
  CfgLines := TStringList.Create;
  try
    CfgLines.LoadFromFile(Settings.CliCfgFile);
    memArdCfg.Lines.Text := ArdUtf8ToAnsi(CfgLines.Text);
  finally
    CfgLines.Free;
  end;
  lblArdCfgState.Caption := Settings.CliCfgFile;
end;

procedure TForm2.ArdCliIdle(var ACancel: Boolean);
begin
  Application.ProcessMessages;
  ACancel := False;
end;

// «Записать пути в yaml»: каталоги arduino-cli - из полей вкладки Settings.
// Так делал RQdebugger при каждом сохранении настроек (SaveIDEOptions),
// здесь - по кнопке. Файла нет - config init в его папку.
procedure TForm2.ArdCfgWriteClick(Sender: TObject);
const
  // Ключ arduino-cli = ключ editor.ini
  CfgKeys: array[0..2] of string = (
    'directories.data=CliDataPath',
    'directories.downloads=DownloadsPath',
    'directories.user=SketchPath');
var
  Settings: TArdSettings;
  Output: TStringList;
  ErrText, CfgKey, Value: string;
  KeyIdx, EqPos, ExitCode: Integer;
  Ini: TIniFile;
begin
  if Form1 = nil then
    Exit;
  Settings := ArdLoadSettings(Form1.SettingsFileName);
  if not ArdCheckCli(Settings, ErrText) then
  begin
    ShowMessage(ErrText);
    Exit;
  end;
  if Settings.CliCfgFile = '' then
  begin
    ShowMessage('Не задан Cli cfg file (вкладка Settings)');
    Exit;
  end;

  Output := TStringList.Create;
  Ini := TIniFile.Create(Form1.SettingsFileName);
  Screen.Cursor := crHourGlass;
  try
    if not FileExists(Settings.CliCfgFile) then
    begin
      Output.Add('> config init');
      ExitCode := ArdRunCli(Settings, 'config init --dest-dir ' +
        ArdQuote(ExcludeTrailingPathDelimiter(
          ExtractFilePath(Settings.CliCfgFile))), Output, nil, ArdCliIdle);
      if (ExitCode <> 0) or not FileExists(Settings.CliCfgFile) then
      begin
        ShowMessage('Не удалось создать ' + Settings.CliCfgFile + #13#10 +
                    Output.Text);
        Exit;
      end;
    end;

    for KeyIdx := Low(CfgKeys) to High(CfgKeys) do
    begin
      EqPos := Pos('=', CfgKeys[KeyIdx]);
      CfgKey := Copy(CfgKeys[KeyIdx], 1, EqPos - 1);
      Value := Trim(Ini.ReadString(Settings.Section,
        Copy(CfgKeys[KeyIdx], EqPos + 1, Length(CfgKeys[KeyIdx])), ''));
      if Value = '' then
        Continue;
      Output.Add('> config set ' + CfgKey + ' ' + Value);
      ExitCode := ArdRunCli(Settings, 'config set ' + CfgKey + ' ' +
                            ArdQuote(ExcludeTrailingPathDelimiter(Value)),
                            Output, nil, ArdCliIdle);
      if ExitCode <> 0 then
      begin
        ShowMessage('Ошибка arduino-cli:' + #13#10 + Output.Text);
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
    Ini.Free;
    Output.Free;
    ArdCfgLoadClick(nil);
  end;
end;

// Переход на вкладку Arduino - значения заново: их мог поменять Board
// Manager (Additional URLs) или страница Compilers
procedure TForm2.OptionsPageChange(Sender: TObject);
begin
  if (Sender is TPageControl) and (FArdTab <> nil) and
     (TPageControl(Sender).ActivePage = FArdTab) then
    ArdTabLoad;
end;

// «Импорт из RQdb.ini» (Compilers - Arduino): пути из раздела [Arduino]
// RQdb.ini RQdebugger и Additional URLs из AdditURLEdit.txt рядом с ним -
// в раздел страницы (ArdImportRqdbIni). Окно выбора файла начинается с
// папки IDE path страницы RapidQ Basic.
procedure TForm2.btnArdImportClick(Sender: TObject);
var
  Dlg: TOpenDialog;
  Report: TStringList;
  Ini: TIniFile;
  StartDir, Section: string;
  KeyCount: Integer;
begin
  if Form1 = nil then
    Exit;
  Dlg := TOpenDialog.Create(Self);
  Report := TStringList.Create;
  try
    Dlg.Title := 'RQdb.ini RQdebugger';
    Dlg.Filter := 'RQdb.ini|RQdb.ini|*.ini|*.ini';
    StartDir := '';
    if FileExists(Form1.SettingsFileName) then
    begin
      Ini := TIniFile.Create(Form1.SettingsFileName);
      try
        StartDir := Trim(Ini.ReadString('Compiler.RapidQ Basic', 'IdePath',
                                        ''));
      finally
        Ini.Free;
      end;
    end;
    if (StartDir <> '') and DirectoryExists(StartDir) then
      Dlg.InitialDir := StartDir;
    Dlg.FileName := 'RQdb.ini';
    if not Dlg.Execute then
      Exit;

    // Правки на открытой странице Compilers - в editor.ini до переноса;
    // после - страница строится заново без нормализации (иначе прежние
    // значения полей записались бы поверх перенесённых). Раздел - как его
    // читает ArduinoCli, с какой бы вкладки ни нажали кнопку.
    NormalizeCompFields;
    Section := ArdSection;
    KeyCount := ArdImportRqdbIni(Dlg.FileName, Form1.SettingsFileName,
                                 Section, Report);
    if CompareText(FCompType, 'Arduino') = 0 then
    begin
      FSkipNormalize := True;
      ShowCompilerPage(FCompType);
    end;
    ArdTabLoad;
    if KeyCount = 0 then
      ShowMessage('В ' + Dlg.FileName + ' нет путей Arduino (раздел ' +
                  '[Arduino])')
    else
      ShowMessage('Перенесено из ' + Dlg.FileName + ' в [' +
                  Section + ']:' + #13#10#13#10 + Report.Text);
  finally
    Report.Free;
    Dlg.Free;
  end;
end;

// «Взять из Delphi»: Library path и Browsing path из Environment Options
// выбранной Delphi (реестр, ...\Library). Пути Delphi - первыми, свои, которых
// у неё нет, - после. Delphi path пустой - ставится найденный.
procedure TForm2.btnDelphiImportClick(Sender: TObject);
var
  Root, FoundRoot, RegKey, RegLib, RegBrowse, Tool: string;
  Reg: TRegistry;
  RootIdx, LibIdx, BrowseIdx: Integer;

  // AFirst, к нему - из ASecond, чего в AFirst нет. AKept - сколько взято
  // из ASecond.
  function MergeLists(const AFirst, ASecond: string;
                      var AKept: Integer): string;
  var
    Seen: TStringList;
    Rest, Item: string;
    SepPos, PassIdx: Integer;
  begin
    Result := '';
    AKept := 0;
    Seen := TStringList.Create;
    try
      for PassIdx := 0 to 1 do
      begin
        if PassIdx = 0 then
          Rest := AFirst
        else
          Rest := ASecond;
        while Rest <> '' do
        begin
          SepPos := Pos(';', Rest);
          if SepPos = 0 then
            SepPos := Length(Rest) + 1;
          Item := Trim(Copy(Rest, 1, SepPos - 1));
          Delete(Rest, 1, SepPos);
          if Length(Item) > 3 then
            Item := ExcludeTrailingPathDelimiter(Item);
          if (Item = '') or (Seen.IndexOf(AnsiUpperCase(Item)) >= 0) then
            Continue;
          Seen.Add(AnsiUpperCase(Item));
          if Result <> '' then
            Result := Result + ';';
          Result := Result + Item;
          if PassIdx = 1 then
            Inc(AKept);
        end;
      end;
    finally
      Seen.Free;
    end;
  end;

var
  KeptLib, KeptBrowse: Integer;
begin
  if (Form1 = nil) or (FCompType <> 'Delphi') then
    Exit;
  RootIdx := CompFieldIdx('DelphiPath');
  LibIdx := CompFieldIdx('LibPath');
  BrowseIdx := CompFieldIdx('BrowsePath');
  if (RootIdx < 0) or (LibIdx < 0) or (BrowseIdx < 0) then
    Exit;
  Root := Trim(FCompEdits[RootIdx].Text);
  Tool := cbTool.Text;
  RegKey := FindDelphiRegKey(Root, Tool, FoundRoot);
  if RegKey = '' then
  begin
    ShowMessage('Установка Delphi для "' + Tool + '" в реестре не найдена' +
                ' (сравнивается с Delphi path: ' + Root + ').');
    Exit;
  end;
  // Delphi path не задан - ставим найденный (OnChange пишет в editor.ini)
  if Root = '' then
  begin
    Root := FoundRoot;
    FCompEdits[RootIdx].Text := IncludeTrailingPathDelimiter(Root);
  end;

  RegLib := '';
  RegBrowse := '';
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly(RegKey + '\Library') then
    begin
      if Reg.ValueExists('Search Path') then
        RegLib := Reg.ReadString('Search Path');
      if Reg.ValueExists('Browsing Path') then
        RegBrowse := Reg.ReadString('Browsing Path');
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
  if (RegLib = '') and (RegBrowse = '') then
  begin
    ShowMessage('В ' + RegKey + '\Library путей нет.');
    Exit;
  end;

  RegLib := ExpandDelphiRegVars(RegLib, Root, RegKey);
  RegBrowse := ExpandDelphiRegVars(RegBrowse, Root, RegKey);
  FCompEdits[LibIdx].Text := MergeLists(RegLib, FCompEdits[LibIdx].Text,
                                        KeptLib);
  CompEditExit(FCompEdits[LibIdx]);
  FCompEdits[BrowseIdx].Text := MergeLists(RegBrowse,
                                           FCompEdits[BrowseIdx].Text,
                                           KeptBrowse);
  CompEditExit(FCompEdits[BrowseIdx]);
  ShowMessage('Пути взяты из ' + RegKey + '\Library.' + #13#10 +
              'Своих путей, которых у Delphi нет, оставлено: Library path - ' +
              IntToStr(KeptLib) + ', Browsing path - ' + IntToStr(KeptBrowse) +
              '.');
end;

// ---------------------------------------------------------------------------
//  Окно списка путей - как Directories у Delphi: список по порядку поиска,
//  поле пути, Replace / Add / Delete, удаление несуществующих, порядок.
// ---------------------------------------------------------------------------

function TForm2.PathExists(const APath: string): Boolean;
begin
  Result := DirectoryExists(ExpandCompMacros(Trim(APath)));
end;

procedure TForm2.PathUpdateState;
var
  ItemIdx, Missing: Integer;
  Text: string;
begin
  if (FPathList = nil) or (FPathState = nil) then
    Exit;
  Missing := 0;
  for ItemIdx := 0 to FPathList.Items.Count - 1 do
    if not PathExists(FPathList.Items[ItemIdx]) then
      Inc(Missing);
  Text := 'Папок: ' + IntToStr(FPathList.Items.Count) + ', нет на диске: ' +
          IntToStr(Missing);
  if FPathList.ItemIndex >= 0 then
  begin
    if PathExists(FPathList.Items[FPathList.ItemIndex]) then
      Text := Text + '.  Выбранная есть'
    else
      Text := Text + '.  Выбранной нет на диске';
  end;
  FPathState.Caption := Text;
end;

procedure TForm2.PathListClick(Sender: TObject);
begin
  if FPathList.ItemIndex >= 0 then
    FPathEdit.Text := FPathList.Items[FPathList.ItemIndex];
  PathUpdateState;
end;

procedure TForm2.PathBrowseClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := ExpandCompMacros(Trim(FPathEdit.Text));
  if BrowseFolderDialog('Папка', Dir) then
    FPathEdit.Text := ExcludeTrailingPathDelimiter(Dir);
end;

procedure TForm2.PathReplaceClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  ItemIdx := FPathList.ItemIndex;
  if (ItemIdx < 0) or (Trim(FPathEdit.Text) = '') then
    Exit;
  FPathList.Items[ItemIdx] := Trim(FPathEdit.Text);
  FPathList.ItemIndex := ItemIdx;
  PathUpdateState;
end;

procedure TForm2.PathAddClick(Sender: TObject);
var
  Item: string;
begin
  Item := Trim(FPathEdit.Text);
  if Item = '' then
    Exit;
  if FPathList.Items.IndexOf(Item) < 0 then
    FPathList.Items.Add(Item);
  FPathList.ItemIndex := FPathList.Items.IndexOf(Item);
  PathUpdateState;
end;

procedure TForm2.PathDeleteClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  ItemIdx := FPathList.ItemIndex;
  if ItemIdx < 0 then
    Exit;
  FPathList.Items.Delete(ItemIdx);
  if ItemIdx >= FPathList.Items.Count then
    ItemIdx := FPathList.Items.Count - 1;
  FPathList.ItemIndex := ItemIdx;
  PathUpdateState;
end;

procedure TForm2.PathDelInvalidClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  for ItemIdx := FPathList.Items.Count - 1 downto 0 do
    if not PathExists(FPathList.Items[ItemIdx]) then
      FPathList.Items.Delete(ItemIdx);
  PathUpdateState;
end;

procedure TForm2.PathUpClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  ItemIdx := FPathList.ItemIndex;
  if ItemIdx <= 0 then
    Exit;
  FPathList.Items.Exchange(ItemIdx, ItemIdx - 1);
  FPathList.ItemIndex := ItemIdx - 1;
end;

procedure TForm2.PathDownClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  ItemIdx := FPathList.ItemIndex;
  if (ItemIdx < 0) or (ItemIdx >= FPathList.Items.Count - 1) then
    Exit;
  FPathList.Items.Exchange(ItemIdx, ItemIdx + 1);
  FPathList.ItemIndex := ItemIdx + 1;
end;

// Список путей AValue (через ;) - в окне; True - нажали OK, AValue - новый
function TForm2.EditPathList(const ACaption: string;
                             var AValue: string): Boolean;
var
  Dlg: TForm;
  DlgBtn: TUiButton;
  Rest, Item: string;
  SepPos, ItemIdx: Integer;

  function AddBtn(const ACap: string; ALeft, ATop, AWidth: Integer;
                  AClick: TNotifyEvent): TUiButton;
  begin
    Result := TUiButton.Create(Dlg);
    Result.Parent := Dlg;
    Result.Caption := ACap;
    Result.SetBounds(ALeft, ATop, AWidth, 25);
    Result.OnClick := AClick;
  end;

begin
  Result := False;
  Dlg := TForm.CreateNew(Self);
  try
    Dlg.Caption := 'Пути: ' + ACaption;
    Dlg.BorderStyle := bsDialog;
    Dlg.Position := poOwnerFormCenter;
    // Окно настроек - поверх всех; без этого список ушёл бы под него
    Dlg.FormStyle := fsStayOnTop;
    Dlg.Font := Font;
    Dlg.Color := clBtnFace;
    Dlg.ClientWidth := 560;
    Dlg.ClientHeight := 356;

    FPathList := TUiListBox.Create(Dlg);
    FPathList.Parent := Dlg;
    FPathList.SetBounds(8, 8, 544, 206);
    FPathList.OnClick := PathListClick;

    FPathState := TLabel.Create(Dlg);
    FPathState.Parent := Dlg;
    FPathState.AutoSize := False;
    FPathState.SetBounds(8, 220, 544, 16);

    FPathEdit := TUiEdit.Create(Dlg);
    FPathEdit.Parent := Dlg;
    FPathEdit.SetBounds(8, 242, 506, 22);
    AddBtn('...', 518, 241, 34, PathBrowseClick);

    AddBtn('Replace', 8, 272, 80, PathReplaceClick);
    AddBtn('Add', 92, 272, 80, PathAddClick);
    AddBtn('Delete', 176, 272, 80, PathDeleteClick);
    AddBtn('Delete invalid', 260, 272, 110, PathDelInvalidClick);
    AddBtn('Up', 412, 272, 68, PathUpClick);
    AddBtn('Down', 484, 272, 68, PathDownClick);

    DlgBtn := AddBtn('OK', 388, 318, 80, nil);
    DlgBtn.ModalResult := mrOk;
    DlgBtn.Default := True;
    DlgBtn := AddBtn('Cancel', 472, 318, 80, nil);
    DlgBtn.ModalResult := mrCancel;
    DlgBtn.Cancel := True;

    Rest := AValue;
    while Rest <> '' do
    begin
      SepPos := Pos(';', Rest);
      if SepPos = 0 then
        SepPos := Length(Rest) + 1;
      Item := Trim(Copy(Rest, 1, SepPos - 1));
      Delete(Rest, 1, SepPos);
      if Item <> '' then
        FPathList.Items.Add(Item);
    end;
    if FPathList.Items.Count > 0 then
    begin
      FPathList.ItemIndex := 0;
      FPathEdit.Text := FPathList.Items[0];
    end;
    PathUpdateState;

    if Form1 <> nil then
      Form1.UiApplyForm(Dlg);
    if Dlg.ShowModal = mrOk then
    begin
      AValue := '';
      for ItemIdx := 0 to FPathList.Items.Count - 1 do
      begin
        if AValue <> '' then
          AValue := AValue + ';';
        AValue := AValue + FPathList.Items[ItemIdx];
      end;
      Result := True;
    end;
  finally
    FPathList := nil;
    FPathEdit := nil;
    FPathState := nil;
    Dlg.Free;
  end;
end;

procedure TForm2.lstCompTypesClick(Sender: TObject);
begin
  if lstCompTypes.ItemIndex < 0 then
    Exit;
  FCompType := lstCompTypes.Items[lstCompTypes.ItemIndex];
  LoadToolList(FCompType);
  ShowCompilerPage(FCompType);
end;

// Поле хранит ФАЙЛ, а не папку. Признак - окончание ключа: IcoFile,
// CliFile, VbCompFile и прочие.
function TForm2.IsFileKey(const AKey: string): Boolean;
begin
  Result := (Length(AKey) >= 4) and
            (CompareText(Copy(AKey, Length(AKey) - 3, 4), 'File') = 0);
end;

// Развёртка макросов. $(DELPHI) - корень установки: его подставляет сама
// среда Delphi, а dcc32 о макросах не знает вовсе и получит путь как есть.
// Значение берём из поля Delphi path этой же страницы. %VAR% раскрывает
// Windows.
function TForm2.ExpandCompMacros(const S: string): string;
var
  I: Integer;
  Root: string;
  Vars: TStringList;
  Buf: array[0..2047] of Char;
  N: DWORD;
begin
  Result := S;

  Root := '';
  for I := 0 to High(FCompKeys) do
    if (CompareText(FCompKeys[I], 'DelphiPath') = 0) and
       (FCompEdits[I] <> nil) then
      Root := Trim(FCompEdits[I].Text);

  if Root <> '' then
  begin
    Root := ExcludeTrailingPathDelimiter(Root);
    Result := StringReplace(Result, '$(DELPHI)', Root,
                            [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, '$(BDS)', Root,
                            [rfReplaceAll, rfIgnoreCase]);
  end;

  // Переменные самой среды: $(TRichViewVCL) и подобные. Их задают в
  // Environment Options, а хранит их реестр. Ищем только если в строке
  // ещё остались макросы - иначе лишний поход в реестр на каждое поле.
  if Pos('$(', Result) > 0 then
  begin
    Vars := TStringList.Create;
    try
      CollectDelphiVars(Vars);
      for I := 0 to Vars.Count - 1 do
        Result := StringReplace(Result,
                    '$(' + Vars.Names[I] + ')',
                    ExcludeTrailingPathDelimiter(
                      Vars.Values[Vars.Names[I]]),
                    [rfReplaceAll, rfIgnoreCase]);
    finally
      Vars.Free;
    end;
  end;

  // Осталось нераскрытое - ищем среди переменных окружения Windows.
  // Установщики компонентов заводят их именно там, а в записи пути Delphi
  // обращается к ним в своём виде, $(Имя), а не %Имя%.
  if Pos('$(', Result) > 0 then
  begin
    Vars := TStringList.Create;
    try
      CollectUnresolved(Result, Vars);
      for I := 0 to Vars.Count - 1 do
      begin
        Root := LookupEnvVar(Vars[I]);
        if Root <> '' then
          Result := StringReplace(Result, '$(' + Vars[I] + ')',
                      ExcludeTrailingPathDelimiter(Root),
                      [rfReplaceAll, rfIgnoreCase]);
      end;
    finally
      Vars.Free;
    end;
  end;

  N := ExpandEnvironmentStrings(PChar(Result), Buf, SizeOf(Buf));
  if (N > 0) and (N <= SizeOf(Buf)) then
    Result := Buf;
end;

// Переменная окружения Windows по имени.
//
// Сначала окружение самой программы, потом реестр: переменную могли завести
// уже после запуска среды, а процессу окружение достаётся один раз, при
// старте. Без реестра пришлось бы перезапускать программу после установки
// каждого компонента.
function TForm2.LookupEnvVar(const AName: string): string;
var
  Buf: array[0..2047] of Char;
  N: DWORD;
  Reg: TRegistry;
begin
  Result := '';
  if AName = '' then
    Exit;

  N := GetEnvironmentVariable(PChar(AName), Buf, SizeOf(Buf));
  if (N > 0) and (N < SizeOf(Buf)) then
  begin
    Result := Buf;
    Exit;
  end;

  Reg := TRegistry.Create;
  try
    // Пользовательские
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('Environment') then
    begin
      if Reg.ValueExists(AName) then
        Result := Reg.ReadString(AName);
      Reg.CloseKey;
    end;
    if Result <> '' then
      Exit;

    // Системные
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Control\' +
                           'Session Manager\Environment') then
    begin
      if Reg.ValueExists(AName) then
        Result := Reg.ReadString(AName);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

// Переменные среды Delphi из реестра, строками вида Имя=значение.
//
// Лежат они в двух местах. Заданные пользователем - в HKCU; записанные
// установщиками компонентов, как $(TRichViewVCL) у TRichView, - в HKLM.
// Сначала HKCU: пользовательское значение перекрывает общее.
//
// Wow6432Node в пути не пишем. Среда - 32-разрядная программа, и на 64-бит
// Windows её обращения к HKLM\Software и так уводятся в Wow6432Node;
// указывать узел явно означало бы промахнуться на 32-бит системе.
//
// Какой версии принадлежит текущий инструмент, поле не знает, поэтому
// просматриваем все ветки и берём первое совпадение по имени.
procedure TForm2.CollectDelphiVars(AList: TStrings);

  procedure Scan(ARootKey: HKEY; const ABranch: string);
  var
    Reg: TRegistry;
    Keys, Names: TStringList;
    I, J: Integer;
  begin
    Reg := TRegistry.Create;
    Keys := TStringList.Create;
    Names := TStringList.Create;
    try
      Reg.RootKey := ARootKey;
      if not Reg.OpenKeyReadOnly(ABranch) then
        Exit;
      Reg.GetKeyNames(Keys);
      Reg.CloseKey;

      for I := 0 to Keys.Count - 1 do
        if Reg.OpenKeyReadOnly(ABranch + '\' + Keys[I] +
                               '\Environment Variables') then
        begin
          Names.Clear;
          Reg.GetValueNames(Names);
          for J := 0 to Names.Count - 1 do
            if AList.IndexOfName(Names[J]) < 0 then
              AList.Add(Names[J] + '=' + Reg.ReadString(Names[J]));
          Reg.CloseKey;
        end;
    finally
      Names.Free;
      Keys.Free;
      Reg.Free;
    end;
  end;

begin
  Scan(HKEY_CURRENT_USER,  'Software\Borland\Delphi');
  Scan(HKEY_LOCAL_MACHINE, 'Software\Borland\Delphi');
  Scan(HKEY_CURRENT_USER,  'Software\Embarcadero\BDS');
  Scan(HKEY_LOCAL_MACHINE, 'Software\Embarcadero\BDS');
end;

// Приведение введённого значения к тому, что понимает компилятор.
//
// Список разбирается по точке с запятой, и в каждом элементе:
//   - разворачиваются макросы;
//   - путь к существующему ФАЙЛУ заменяется на его папку - компилятор ищет
//     модули по папкам, имя файла ему ничего не скажет;
//   - снимается хвостовой слэш, кроме корня диска;
//   - выбрасываются пустые элементы и повторы.
// Папки, которых нет на этом компьютере, остаются: настройки переносятся
// между компьютерами, и на другом они есть. Сборка (CompileDelphi) такие
// пропускает, удалить их можно в окне списка - Delete invalid.
//
// Поле, хранящее файл, остаётся файлом: там разворачиваются только макросы.
// Одиночное поле пути на существование не проверяется: папка вывода может
// быть ещё не создана.
function TForm2.NormalizePathValue(const S: string; AIsFile, AIsList: Boolean;
                                   ADropped: TStrings): string;
var
  Seen: TStringList;
  Rest, V: string;
  P: Integer;
begin
  Result := Trim(ExpandCompMacros(Trim(S)));
  if AIsFile or (Result = '') then
    Exit;

  // Разбор списка руками. DelimitedText тут не годится: он рвёт строку ещё
  // и по пробелам, а в путях они обычны - Program Files.
  Seen := TStringList.Create;
  try
    Rest := Result;
    Result := '';

    while Rest <> '' do
    begin
      P := Pos(';', Rest);
      if P > 0 then
      begin
        V := Trim(Copy(Rest, 1, P - 1));
        Rest := Copy(Rest, P + 1, Length(Rest));
      end
      else
      begin
        V := Trim(Rest);
        Rest := '';
      end;

      if V = '' then
        Continue;

      // Файл - берём папку, в которой он лежит
      if FileExists(V) and not DirectoryExists(V) then
        V := ExtractFilePath(V);

      // Хвостовой слэш снимаем везде, кроме корня диска: в параметре с
      // кавычками он съел бы закрывающую кавычку
      if Length(V) > 3 then
        V := ExcludeTrailingPathDelimiter(V);

      if Seen.IndexOf(AnsiUpperCase(V)) >= 0 then
        Continue;
      Seen.Add(AnsiUpperCase(V));

      // Несуществующую папку не выбрасываем (см. выше): она может быть
      // путём с другого компьютера

      if Result = '' then
        Result := V
      else
        Result := Result + ';' + V;
    end;
  finally
    Seen.Free;
  end;
end;

// Имена нераскрытых макросов вида $(Имя) - в список, без повторов.
//
// Всё, что осталось после развёртки, для компилятора просто часть имени
// папки: такой путь молча не ищется, и ошибка приходит потом из dcc32 уже
// без связи с настройками.
procedure TForm2.CollectUnresolved(const S: string; AList: TStrings);
var
  P, Q: Integer;
  Rest, Nm: string;
begin
  Rest := S;
  repeat
    P := Pos('$(', Rest);
    if P <= 0 then
      Break;

    Rest := Copy(Rest, P + 2, Length(Rest));
    Q := Pos(')', Rest);
    if Q <= 0 then
      Break;

    Nm := Copy(Rest, 1, Q - 1);
    Rest := Copy(Rest, Q + 1, Length(Rest));

    if (Nm <> '') and (AList.IndexOf(Nm) < 0) then
      AList.Add(Nm);
  until False;
end;

// Одно сообщение на обе беды: что не раскрылось и что выброшено как
// несуществующее. Два отдельных окна подряд читаются хуже одного.
procedure TForm2.WarnUnresolved(ABad, ADropped: TStrings);
var
  I: Integer;
  M, L: string;
begin
  M := '';

  if (ABad <> nil) and (ABad.Count > 0) then
  begin
    L := '';
    for I := 0 to ABad.Count - 1 do
    begin
      if L <> '' then
        L := L + ', ';
      L := L + '$(' + ABad[I] + ')';
    end;
    M := 'Не удалось раскрыть: ' + L + #13#10#13#10 +
         'Такие переменные задаёт сама Delphi (Environment Options - ' +
         'Environment Variables) или Windows. Компилятор их не понимает - ' +
         'впишите полный путь.';
  end;

  if (ADropped <> nil) and (ADropped.Count > 0) then
  begin
    if M <> '' then
      M := M + #13#10#13#10;
    M := M + 'Убраны из списка - таких папок нет:' + #13#10;
    for I := 0 to ADropped.Count - 1 do
      M := M + #13#10 + ADropped[I];
  end;

  if M <> '' then
    ShowMessage('3686:' + M);
end;

// Нормализация всех полей текущей страницы с записью в editor.ini.
//
// Нужна там, где OnExit не случится: окно закрыли с курсором в поле или
// переключились на другой тип компилятора, отчего поля уничтожаются.
// Пишем прямо в файл, не через присвоение Text: контролы могут быть уже
// на пути к освобождению.
procedure TForm2.NormalizeCompFields;
var
  I: Integer;
  V: string;
  Ini: TIniFile;
  Bad, Dropped: TStringList;
begin
  if (Form1 = nil) or (FCompSection = '') then
    Exit;
  if Length(FCompEdits) = 0 then
    Exit;

  Bad := TStringList.Create;
  Dropped := TStringList.Create;
  Ini := TIniFile.Create(Form1.SettingsFileName);
  try
    for I := 0 to High(FCompEdits) do
    begin
      if (FCompEdits[I] = nil) or (I > High(FCompKeys)) then
        Continue;

      V := NormalizePathValue(FCompEdits[I].Text, IsFileKey(FCompKeys[I]),
                              FCompIsList[I], Dropped);
      if V <> FCompEdits[I].Text then
        FCompEdits[I].Text := V;   // если поле ещё живо - показываем как есть
      Ini.WriteString(CompIniSection(FCompKeys[I]), CompIniKey(FCompKeys[I]),
                      V);
      CollectUnresolved(V, Bad);
    end;
  finally
    Ini.Free;
  end;

  // Предупреждение одно на всю страницу, а не на каждое поле
  try
    WarnUnresolved(Bad, Dropped);
  finally
    Dropped.Free;
    Bad.Free;
  end;
end;

// Нормализация делается при уходе из поля, а не при каждом нажатии клавиши:
// иначе правка пути превратилась бы в борьбу с автоподстановкой. Присвоение
// Text поднимает OnChange, а он и сохраняет значение в editor.ini.
procedure TForm2.CompEditExit(Sender: TObject);
var
  I: Integer;
  V: string;
  Bad, Dropped: TStringList;
begin
  I := TUiEdit(Sender).Tag;
  if (I < 0) or (I > High(FCompKeys)) then
    Exit;

  Bad := TStringList.Create;
  Dropped := TStringList.Create;

  V := NormalizePathValue(TUiEdit(Sender).Text, IsFileKey(FCompKeys[I]),
                          FCompIsList[I], Dropped);
  if V <> TUiEdit(Sender).Text then
    TUiEdit(Sender).Text := V;

  try
    CollectUnresolved(V, Bad);
    WarnUnresolved(Bad, Dropped);
  finally
    Dropped.Free;
    Bad.Free;
  end;
end;

// Кнопка выбора: ключ, кончающийся на File, спрашивает файл, прочие - папку
procedure TForm2.CompBrowseClick(Sender: TObject);
var
  I: Integer;
  Dir: string;
  Dlg: TOpenDialog;
begin
  I := TUiButton(Sender).Tag;
  if (I < 0) or (I > High(FCompEdits)) then
    Exit;

  if FCompIsList[I] then
  begin
    Dir := FCompEdits[I].Text;
    if EditPathList(FCompType + ': ' + FCompKeys[I], Dir) then
    begin
      FCompEdits[I].Text := Dir;      // OnChange пишет в editor.ini
      CompEditExit(FCompEdits[I]);    // и нормализация, как при уходе
    end;
    Exit;
  end;

  if IsFileKey(FCompKeys[I]) then
  begin
    Dlg := TOpenDialog.Create(Self);
    try
      Dlg.Title := 'Выберите файл';
      Dlg.FileName := FCompEdits[I].Text;
      if Dlg.Execute then
        FCompEdits[I].Text := Dlg.FileName;
    finally
      Dlg.Free;
    end;
  end
  else
  begin
    Dir := FCompEdits[I].Text;
    // Поле пустое - начинаем с папки текущего проекта, а её нет - с папки
    // самой программы: искать с корня диска неудобно
    if (Dir = '') and (Form1 <> nil) then
      Dir := Form1.CurrentProjectDir;

    if BrowseFolderDialog('Выберите папку', Dir) then
      FCompEdits[I].Text := IncludeTrailingPathDelimiter(Dir);
  end;
end;

// Правка поля сразу уходит в editor.ini: отдельной кнопки сохранения на
// этой вкладке нет, как и на прочих настройках редактора
procedure TForm2.CompEditChange(Sender: TObject);
var
  I: Integer;
  Ini: TIniFile;
begin
  if Form1 = nil then
    Exit;
  I := TUiEdit(Sender).Tag;
  if (I < 0) or (I > High(FCompKeys)) then
    Exit;

  Ini := TIniFile.Create(Form1.SettingsFileName);
  try
    Ini.WriteString(CompIniSection(FCompKeys[I]), CompIniKey(FCompKeys[I]),
                    TUiEdit(Sender).Text);
  finally
    Ini.Free;
  end;

  // То же поле на вкладке Arduino
  if CompareText(FCompType, 'Arduino') = 0 then
    ArdTabSetField(FCompKeys[I], TUiEdit(Sender).Text);
end;

procedure TForm2.LayoutIndentGroup;
const
  Gap = 8;
var
  Bmp: TBitmap;
  X: Integer;
begin
  if grpIndent = nil then
    Exit;

  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(grpIndent.Font);
    X := 6;

    lblIndent.Left := X;
    Inc(X, Bmp.Canvas.TextWidth(lblIndent.Caption) + 4);
    cmbIndentKind.Left := X;
    Inc(X, cmbIndentKind.Width + 4);
    cmbIndentSize.Left := X;
    Inc(X, cmbIndentSize.Width + Gap * 2);

    chkHotTabHighlight.Left := X;
    chkHotTabHighlight.Width := GetSystemMetrics(SM_CXMENUCHECK) + 4 +
      Bmp.Canvas.TextWidth(chkHotTabHighlight.Caption) + 6;
    Inc(X, chkHotTabHighlight.Width + Gap);

    // UpDown встаёт вплотную к полю при привязке, поэтому после переноса
    // поля привязываем заново
    edtPale.Left := X;
    udPale.Associate := nil;
    udPale.Associate := edtPale;
  finally
    Bmp.Free;
  end;
end;

procedure TForm2.LayoutEditorColors;
const
  Gap = 8;
var
  Bmp: TBitmap;
  X: Integer;
begin
  if grpEditorColors = nil then
    Exit;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(grpEditorColors.Font);
    X := 6;

    lblEditorColor.Left := X;
    Inc(X, Bmp.Canvas.TextWidth(lblEditorColor.Caption) + Gap);
    pnlEditorFG.Left := X;
    Inc(X, pnlEditorFG.Width + 3);
    pnlEditorBG.Left := X;
    Inc(X, pnlEditorBG.Width + Gap * 3);

    lblGutterColor.Left := X;
    Inc(X, Bmp.Canvas.TextWidth(lblGutterColor.Caption) + Gap);

    pnlGutterFG.Left := X;
    Inc(X, pnlGutterFG.Width + 3);
    pnlGutterBG.Left := X;
  finally
    Bmp.Free;
  end;
end;

// Цвет надписи для заливки C: белый на тёмном, чёрный на светлом
function ContrastTextColor(C: TColor): TColor;
var
  RGBColor: Longint;
begin
  RGBColor := ColorToRGB(C);
  if (GetRValue(RGBColor) * 299 + GetGValue(RGBColor) * 587 +
      GetBValue(RGBColor) * 114) < 128000 then
    Result := clWhite
  else
    Result := clBlack;
end;

// Квадратик залит цветом C, надпись - контрастная
procedure PaintSwatch(APanel: TPanel; C: TColor);
begin
  if APanel = nil then
    Exit;
  APanel.Color := C;
  APanel.Font.Color := ContrastTextColor(C);
end;

// Квадратик цвета в группе Editor colors: размер, рамка, надпись, щелчок
procedure TForm2.SetupSwatch(APanel: TPanel; const ACaption, AHint: string);
begin
  APanel.Parent := grpEditorColors;
  APanel.Caption := ACaption;
  APanel.Top := 13;
  APanel.Width := 24;
  APanel.Height := 20;
  APanel.BevelOuter := bvLowered;
  APanel.ParentBackground := False;
  APanel.ParentFont := False;
  APanel.Font.Style := [fsBold];
  APanel.Cursor := crHandPoint;
  APanel.ShowHint := True;
  APanel.Hint := AHint;
  APanel.OnClick := ColorSwatchClick;
end;

// Образцы цветов на вкладке Editor Options - по текущим значениям редактора
procedure TForm2.UpdateColorSwatches;
begin
  if Form1 = nil then
    Exit;
  PaintSwatch(pnlEditorFG, Form1.BaseFontColor);
  PaintSwatch(pnlEditorBG, Form1.EditorBG);
  PaintSwatch(pnlGutterFG, Form1.GutterFG);
  PaintSwatch(pnlGutterBG, Form1.GutterBG);
end;

// Щелчок по квадратику цвета: выбор цвета, сразу на экран и в editor.ini
procedure TForm2.ColorSwatchClick(Sender: TObject);
var
  C: TColor;
begin
  if Form1 = nil then
    Exit;

  if Sender = pnlEditorFG then
    C := Form1.BaseFontColor
  else if Sender = pnlEditorBG then
    C := Form1.EditorBG
  else if Sender = pnlGutterFG then
    C := Form1.GutterFG
  else if Sender = pnlGutterBG then
    C := Form1.GutterBG
  else
    Exit;

  ColorDlg.Color := C;
  if not ColorDlg.Execute then
    Exit;
  C := ColorDlg.Color;

  if Sender = pnlEditorFG then
    Form1.SetBaseFontColor(C)
  else if Sender = pnlEditorBG then
    Form1.SetEditorBG(C)
  else if Sender = pnlGutterFG then
    Form1.SetGutterColors(C, Form1.GutterBG)
  else
    Form1.SetGutterColors(Form1.GutterFG, C);
  UpdateColorSwatches;
end;

// Windows 7 с темами: по нажатии Alt система рассылает окну и всем его
// дочерним WM_UPDATEUISTATE (показать подчёркивания горячих клавиш), и
// кнопки и флажки на панелях и групбоксах Delphi 7 после этого не
// перерисовываются - пропадают. Окно целиком со всеми дочерними -
// перерисовать.
procedure TForm2.WndProc(var Message: TMessage);
const
  WM_UPDATEUISTATE_ = $0128;
begin
  inherited WndProc(Message);
  if (Message.Msg = WM_UPDATEUISTATE_) and HandleAllocated then
    RedrawWindow(Handle, nil, 0,
                 RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN);
end;

procedure TForm2.btnFontChangeClick(Sender: TObject);
begin
  if Form1 = nil then Exit;

  // Загружаем текущий шрифт редактора в диалог как стартовый
  FontDlg.Font.Assign(Form1.RichEdit1.Font);

  if not FontDlg.Execute then
    Exit;

  // Всё остальное - пересчёт высоты строки, шага табуляции и перерисовку -
  // делает сам редактор. И, что важно, он при этом НЕ помечает файл
  // изменённым: присваивание шрифта переписывает форматирование всего
  // текста, и RichEdit иначе взводит Modified.
  Form1.ApplyEditorLook(FontDlg.Font, clNone, clNone);

  // Шрифт ОБЩИЙ для всех языков и лежит в editor.ini, а не в схеме
  // подсветки. Записываем сразу: до кнопки Save можно и не дойти, а без
  // записи выбранный шрифт продержится только до конца сеанса.
  Form1.SaveSettings;

  ShowMessage('4014:Шрифт редактора: ' + Form1.RichEdit1.Font.Name + ', ' +
              IntToStr(Form1.RichEdit1.Font.Size) + ' пт.' + #13#10#13#10 +
              'Записан в editor.ini и действует для всех языков.');
end;
// Restore Defaults: цвета - из •default•.clr (в режиме Edit Default и без
// файла - встроенные), данные языка остаются.
//
// Данные языка - слова групп ключевых слов, маркеры комментариев и строк,
// символы операторов, формы чисел - свои у каждой схемы; умолчания задают
// только цвета. Цвета групп ключевых слов берутся из групп •default•.clr по
// номеру; групп в нём меньше - первая синяя, остальные фиолетовые.
//
// Результат - в таблице и в редакторе; в файл его пишет Save.
procedure TForm2.btnRestoreDefaultsClick(Sender: TObject);
var
  I, N, G: Integer;
  SavedNames, SavedWords: array of string;
  OpNames, OpChars: array of string;   // группы операторов: имя и символы
  MkNames, MkWords: array of string;   // группы отметки строк
  Sections: TStringList;               // порядок разделов схемы
  GFg, GBg: array of TColor;
  LcMarker, BcStart, BcEnd, StrMarker, DigitForms: string;
  DefFont: TFont;
begin
  if (Form1 = nil) or (Grid = nil) then
    Exit;

  // 1. Таблица - в редактор: данные языка берём из неё, с правками.
  // Формы записи чисел ApplyGridToForm1 разбирает сама.
  ApplyGridToForm1(False);

  // 2. Данные языка - запомнить
  N := Length(Form1.FScheme.KeywordGroups);
  SetLength(SavedNames, N);
  SetLength(SavedWords, N);
  for I := 0 to N - 1 do
  begin
    SavedNames[I] := Form1.FScheme.KeywordGroups[I].Name;
    if Form1.FScheme.KeywordGroups[I].Words <> nil then
      SavedWords[I] := Form1.FScheme.KeywordGroups[I].Words.CommaText
    else
      SavedWords[I] := '';
  end;
  LcMarker := Form1.FScheme.FLineCommentMarker;
  BcStart := Form1.FScheme.FBlockCommentStart;
  BcEnd := Form1.FScheme.FBlockCommentEnd;
  StrMarker := Form1.FScheme.FStringMarker;
  DigitForms := Form1.FScheme.BuildDigitFormats;

  // Группы операторов и отметки строк: беречь имена и данные, цвета придут
  // из умолчаний
  SetLength(OpNames, Length(Form1.FScheme.OpGroups));
  SetLength(OpChars, Length(Form1.FScheme.OpGroups));
  for I := 0 to High(OpNames) do
  begin
    OpNames[I] := Form1.FScheme.OpGroups[I].Name;
    OpChars[I] := Form1.FScheme.OpCharsStr(I);
  end;
  SetLength(MkNames, Length(Form1.FScheme.MarkGroups));
  SetLength(MkWords, Length(Form1.FScheme.MarkGroups));
  for I := 0 to High(MkNames) do
  begin
    MkNames[I] := Form1.FScheme.MarkGroups[I].Name;
    if Form1.FScheme.MarkGroups[I].Words <> nil then
      MkWords[I] := WordsByComma(Form1.FScheme.MarkGroups[I].Words)
    else
      MkWords[I] := '';
  end;

  // Состав и порядок разделов - тоже от схемы, а не от умолчаний: иначе
  // после загрузки •default•.clr таблица осталась бы с его строками
  Sections := TStringList.Create;
  Sections.Assign(Form1.FScheme.SchemaSections);

  // 3. Умолчания. Когда в таблице сама схема умолчаний - встроенные.
  if not FEditDefault and FileExists(Form1.DefaultSchemaFile) then
    Form1.LoadSchemaFileForEdit(Form1.DefaultSchemaFile)
  else
    Form1.LoadSchemaFileForEdit(''); // файла нет - только встроенные

  SetLength(GFg, Length(Form1.FScheme.KeywordGroups));
  SetLength(GBg, Length(Form1.FScheme.KeywordGroups));
  for I := 0 to High(GFg) do
  begin
    GFg[I] := Form1.FScheme.KeywordGroups[I].FgColor;
    GBg[I] := Form1.FScheme.KeywordGroups[I].BgColor;
  end;

  // 4. Данные языка - обратно, с цветами умолчаний
  Form1.FScheme.ClearKeywordGroups;
  SetLength(Form1.FScheme.KeywordGroups, N);
  for I := 0 to N - 1 do
  begin
    Form1.FScheme.KeywordGroups[I].Name := SavedNames[I];
    Form1.FScheme.KeywordGroups[I].Words := TStringList.Create;
    Form1.FScheme.KeywordGroups[I].Words.Sorted := True;
    Form1.FScheme.KeywordGroups[I].Words.Duplicates := dupIgnore;
    Form1.FScheme.KeywordGroups[I].Words.CaseSensitive := False;
    Form1.FScheme.KeywordGroups[I].Words.CommaText := SavedWords[I];
    if I <= High(GFg) then
    begin
      Form1.FScheme.KeywordGroups[I].FgColor := GFg[I];
      Form1.FScheme.KeywordGroups[I].BgColor := GBg[I];
    end
    else
    begin
      if I = 0 then
        Form1.FScheme.KeywordGroups[I].FgColor := clBlue
      else
        Form1.FScheme.KeywordGroups[I].FgColor := clFuchsia;
      Form1.FScheme.KeywordGroups[I].BgColor := Form1.FScheme.FTextBG;
    end;
  end;

  Form1.FScheme.FLineCommentMarker := LcMarker;
  Form1.FScheme.FBlockCommentStart := BcStart;
  Form1.FScheme.FBlockCommentEnd := BcEnd;
  Form1.FScheme.FStringMarker := StrMarker;
  Form1.FScheme.ParseDigitFormats(DigitForms);

  // Группы обратно: цвета - те, что пришли из умолчаний, данные - свои.
  // Группы, которой в умолчаниях нет, заводим заново.
  for I := 0 to High(OpNames) do
  begin
    G := Form1.FScheme.OpGroupIndex(OpNames[I]);
    if G < 0 then
    begin
      SetLength(Form1.FScheme.OpGroups, Length(Form1.FScheme.OpGroups) + 1);
      G := High(Form1.FScheme.OpGroups);
      Form1.FScheme.OpGroups[G].Name := OpNames[I];
      Form1.FScheme.OpGroups[G].FgColor := clRed;
      Form1.FScheme.OpGroups[G].BgColor := Form1.FScheme.FTextBG;
    end;
    Form1.FScheme.SetOpChars(G, OpChars[I]);
  end;

  for I := 0 to High(MkNames) do
  begin
    G := Form1.FScheme.MarkGroupIndex(MkNames[I]);
    if G < 0 then
    begin
      SetLength(Form1.FScheme.MarkGroups, Length(Form1.FScheme.MarkGroups) + 1);
      G := High(Form1.FScheme.MarkGroups);
      Form1.FScheme.MarkGroups[G].Name := MkNames[I];
      Form1.FScheme.MarkGroups[G].FgColor := clNone;
      Form1.FScheme.MarkGroups[G].BgColor := clYellow;
      Form1.FScheme.MarkGroups[G].Words := TStringList.Create;
      Form1.FScheme.MarkGroups[G].Words.Sorted := True;
      Form1.FScheme.MarkGroups[G].Words.Duplicates := dupIgnore;
      Form1.FScheme.MarkGroups[G].Words.CaseSensitive := False;
    end;
    SetWordsByComma(Form1.FScheme.MarkGroups[G].Words, MkWords[I]);
  end;

  Form1.FScheme.SchemaSections.Assign(Sections);
  Sections.Free;

  Form1.RefreshMapIfMarkersChanged; // маркеры снова языковые - карта под них

  RefreshGridFromForm1;
  FPreviewDirty := True;

  // 5. Шрифт и базовые цвета редактора - как раньше. Собираем шрифт во
  // временном TFont и отдаём редактору целиком: так флаг "файл изменён"
  // останется нетронутым.
  DefFont := TFont.Create;
  try
    DefFont.Assign(Form1.RichEdit1.Font);
    DefFont.Name := 'Tahoma';
    DefFont.Size := 11;
    DefFont.Color := clBlack;
    Form1.ApplyEditorLook(DefFont, clNone, clNone);
    Form1.SetBaseFontColor(clBlack);
    Form1.SetEditorBG(TColor($00F9F9F9));
    // Панель номеров строк - к встроенным цветам
    Form1.SetGutterColors(TColor($00202020), TColor($00FDF2E1));
    UpdateColorSwatches;
  finally
    DefFont.Free;
  end;

  // Шрифт живёт в editor.ini - возврат к умолчанию тоже надо записать
  Form1.SaveSettings;

  Form1.RichEdit1.Invalidate;
  if Form1.PaintBox1 <> nil then
    Form1.PaintBox1.Invalidate;
  MemoSchemaDetails.Lines.Text := Grid.Cells[3, Grid.Row];
  Grid.Invalidate;
  ShowMessage('4203:Defaults restored. Press Save to write the scheme.');
end;

end.

