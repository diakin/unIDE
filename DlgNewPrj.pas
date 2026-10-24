unit DlgNewPrj;

// New Project и Project Properties: имя, папка, "на базе существующего",
// тип проекта; для проекта Delphi - ещё страница Project options с
// вкладками как в окне Project Options среды Delphi 7: Forms, Application,
// Compiler, Compiler Messages, Linker, Directories/Conditionals,
// Version Info, Packages.
//
// Проект ReactOS / LiberNT (CMake + Ninja) - рамка grpRos под типом: папка
// сборки output-*, цель ninja, параметры configure.cmd, скрипт окружения
// RosBE. Рамка строится кодом (BuildRosControls); хранение - RosProj.
//
// Окно описано в DlgNewPrj.dfm и правится в конструкторе форм.
// Обработчики полей вкладки Project (NewPrjNameChange, NewPrjDirChange,
// NewPrjOnBaseClick), подсказку папки и само создание проекта ведёт
// TForm1.NewProjectClick (Unit1). Кнопка "..." у папки закрывает окно с
// mrRetry: папка выбирается после закрытия, и окно показывается снова.
// Порядок типов в cbType важен только для пункта по умолчанию - его
// ставит код (ItemIndex := 0).
//
// Вкладка Project options видна, только если вызван LoadDelphiOptions
// (Project Properties проекта Delphi); иначе окно - прежнего, малого
// размера. Где что хранится - см. DelphiOpts: .dof, .dpr и .res проекта.
// Записывает настройки SaveDelphiOptions - его вызывает Unit1 после OK.
//
// Новый проект RapidQ (только New Project, ShowRqKind): справа от типа -
// список "Вид" (Application, Console Application, CGI Application) и
// компилятор (rc.exe, FB Smart / FB Compat 32 или 64 бит). Списки строятся
// кодом (BuildRqKindControls), видны только у типа RapidQ Basic. Заготовку
// пишет TForm1.NewProjectClick.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls, CheckLst, IniFiles, Registry,
  UiButton,     // TUiButton
  UiStdCtrls,   // TUiCheckBox, TUiRadioButton
  UiEditCtrls,  // TUiEdit, TUiComboBox, TUiListBox
  UiGroupBox,   // TUiGroupBox
  UiComCtrls,   // TUiPageControl, TUiListView, TUiUpDown
  DelphiOpts,   // .dof, .dpr
  ResFile,      // .res: VERSIONINFO, MAINICON
  FolderDlg,    // BrowseFolderDialog
  RosProj,      // настройки проекта ReactOS / LiberNT
  PciIds,       // список производителей PCI по умолчанию
  Dialogs,      // TOpenDialog
  // Окна сообщений по теме - последним, поверх Dialogs
  UiDialogs;

const
  // Вид заготовки нового проекта RapidQ (список "Вид" в New Project)
  rqkApp = 1;       // программа с формой
  rqkConsole = 2;   // $APPTYPE CONSOLE
  rqkCgi = 3;       // $APPTYPE CGI

type
  TDlgNewPrj = class(TForm)
    pcMain: TUiPageControl;
    tsProject: TTabSheet;
    lblName: TLabel;
    lblDir: TLabel;
    lblType: TLabel;
    edName: TUiEdit;
    edDir: TUiEdit;
    btnBrowse: TUiButton;
    chkBase: TUiCheckBox;
    cbType: TUiComboBox;
    grpRqInc: TUiGroupBox;
    rbIncSys: TUiRadioButton;
    rbIncUser: TUiRadioButton;
    edIncPath: TUiEdit;
    btnIncBrowse: TUiButton;
    lblIncNote: TLabel;
    tsOptions: TTabSheet;
    pcOptions: TUiPageControl;
    tsForms: TTabSheet;
    lblMainForm: TLabel;
    cbMainForm: TUiComboBox;
    lblAutoForms: TLabel;
    lbAutoForms: TUiListBox;
    btnFormToAvail: TUiButton;
    btnAllToAvail: TUiButton;
    btnFormToAuto: TUiButton;
    btnAllToAuto: TUiButton;
    lblAvailForms: TLabel;
    lbAvailForms: TUiListBox;
    lblFormsNote: TLabel;
    tsApplication: TTabSheet;
    grpAppSettings: TUiGroupBox;
    lblTitle: TLabel;
    edTitle: TUiEdit;
    lblHelpFile: TLabel;
    edHelpFile: TUiEdit;
    btnHelpBrowse: TUiButton;
    lblIcon: TLabel;
    imgIcon: TImage;
    btnLoadIcon: TUiButton;
    lblAppNote: TLabel;
    tsCompiler: TTabSheet;
    grpCodeGen: TUiGroupBox;
    chkOptimization: TUiCheckBox;
    chkStackFrames: TUiCheckBox;
    chkSafeDivide: TUiCheckBox;
    lblAlign: TLabel;
    cbAlign: TUiComboBox;
    grpRuntimeErr: TUiGroupBox;
    chkRangeCheck: TUiCheckBox;
    chkIoCheck: TUiCheckBox;
    chkOverflowCheck: TUiCheckBox;
    grpDebugging: TUiGroupBox;
    chkDebugInfo: TUiCheckBox;
    chkLocalSymbols: TUiCheckBox;
    chkReferenceInfo: TUiCheckBox;
    chkDefinitionsOnly: TUiCheckBox;
    chkAssertions: TUiCheckBox;
    grpSyntax: TUiGroupBox;
    chkStrictVar: TUiCheckBox;
    chkCompleteBool: TUiCheckBox;
    chkExtendedSyntax: TUiCheckBox;
    chkTypedAddress: TUiCheckBox;
    chkOpenParams: TUiCheckBox;
    chkHugeStrings: TUiCheckBox;
    chkWritableConst: TUiCheckBox;
    lblCompilerNote: TLabel;
    tsMessages: TTabSheet;
    grpMsgGeneral: TUiGroupBox;
    chkShowHints: TUiCheckBox;
    chkShowWarnings: TUiCheckBox;
    grpWarnings: TUiGroupBox;
    clbWarnings: TCheckListBox;
    tsLinker: TTabSheet;
    grpMapFile: TUiGroupBox;
    rbMapOff: TUiRadioButton;
    rbMapSegments: TUiRadioButton;
    rbMapPublics: TUiRadioButton;
    rbMapDetailed: TUiRadioButton;
    grpExeOptions: TUiGroupBox;
    chkConsoleApp: TUiCheckBox;
    chkTd32Info: TUiCheckBox;
    chkRemoteSymbols: TUiCheckBox;
    grpMemory: TUiGroupBox;
    lblMinStack: TLabel;
    edMinStack: TUiEdit;
    lblMaxStack: TLabel;
    edMaxStack: TUiEdit;
    lblImageBase: TLabel;
    edImageBase: TUiEdit;
    grpExeDescr: TUiGroupBox;
    edExeDescription: TUiEdit;
    lblLinkerNote: TLabel;
    tsDirectories: TTabSheet;
    grpDirs: TUiGroupBox;
    lblOutputDir: TLabel;
    edOutputDir: TUiEdit;
    btnOutputDir: TUiButton;
    lblUnitOutputDir: TLabel;
    edUnitOutputDir: TUiEdit;
    btnUnitOutputDir: TUiButton;
    lblSearchPath: TLabel;
    edSearchPath: TUiEdit;
    btnSearchPath: TUiButton;
    lblDebugSourceDirs: TLabel;
    edDebugSourceDirs: TUiEdit;
    btnDebugSourceDirs: TUiButton;
    lblBplOutputDir: TLabel;
    edBplOutputDir: TUiEdit;
    btnBplOutputDir: TUiButton;
    lblDcpOutputDir: TLabel;
    edDcpOutputDir: TUiEdit;
    btnDcpOutputDir: TUiButton;
    grpConditionals: TUiGroupBox;
    lblConditionals: TLabel;
    edConditionals: TUiEdit;
    grpAliases: TUiGroupBox;
    lblUnitAliases: TLabel;
    edUnitAliases: TUiEdit;
    lblDirsNote: TLabel;
    tsVersion: TTabSheet;
    chkIncludeVer: TUiCheckBox;
    grpVerNumber: TUiGroupBox;
    lblMajor: TLabel;
    edMajor: TUiEdit;
    udMajor: TUiUpDown;
    lblMinor: TLabel;
    edMinor: TUiEdit;
    udMinor: TUiUpDown;
    lblRelease: TLabel;
    edRelease: TUiEdit;
    udRelease: TUiUpDown;
    lblBuild: TLabel;
    edBuild: TUiEdit;
    udBuild: TUiUpDown;
    chkAutoInc: TUiCheckBox;
    grpModAttr: TUiGroupBox;
    chkVerDebug: TUiCheckBox;
    chkVerPreRelease: TUiCheckBox;
    chkVerDll: TUiCheckBox;
    chkVerSpecial: TUiCheckBox;
    chkVerPrivate: TUiCheckBox;
    grpLanguage: TUiGroupBox;
    lblLocaleId: TLabel;
    cbLocale: TUiComboBox;
    lvVerKeys: TUiListView;
    lblVerKey: TLabel;
    edVerKey: TUiEdit;
    lblVerValue: TLabel;
    edVerValue: TUiEdit;
    btnVerKeySet: TUiButton;
    btnVerKeyDel: TUiButton;
    tsPackages: TTabSheet;
    grpDesignPkgs: TUiGroupBox;
    clbDesignPkgs: TCheckListBox;
    lblPkgPath: TLabel;
    grpRuntimePkgs: TUiGroupBox;
    chkUsePackages: TUiCheckBox;
    edRuntimePkgs: TUiEdit;
    lblPkgNote: TLabel;
    btnOk: TUiButton;
    btnCancel: TUiButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbMainFormChange(Sender: TObject);
    procedure btnFormMoveClick(Sender: TObject);
    procedure btnHelpBrowseClick(Sender: TObject);
    procedure btnLoadIconClick(Sender: TObject);
    procedure chkReferenceInfoClick(Sender: TObject);
    procedure btnDirBrowseClick(Sender: TObject);
    procedure edVerNumberChange(Sender: TObject);
    procedure chkIncludeVerClick(Sender: TObject);
    procedure cbLocaleChange(Sender: TObject);
    procedure lvVerKeysSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure btnVerKeySetClick(Sender: TObject);
    procedure btnVerKeyDelClick(Sender: TObject);
    procedure clbDesignPkgsClick(Sender: TObject);
    procedure cbTypeChange(Sender: TObject);
    procedure rbIncClick(Sender: TObject);
    procedure btnIncBrowseClick(Sender: TObject);
  private
    // Папки inc RapidQ из настроек компилятора: системные (новые) и
    // пользовательские (старые) - см. SetRqInc
    FIncSysDir: string;
    FIncUserDir: string;
    // Выбор папки inc: Include UnIde, Include User и свои папки проекта
    // (строятся кодом в grpRqInc при первом SetRqInc)
    cbIncDir: TUiComboBox;
    btnIncDel: TUiButton;
    btnIncDelAll: TUiButton;
    lblIncPaths: TLabel;
    // Рамка проекта ReactOS / LiberNT (строится кодом в BuildRosControls)
    grpRos: TUiGroupBox;
    cbRosBuildDir: TUiComboBox;
    btnRosBuildDir: TUiButton;
    cbRosTarget: TUiComboBox;
    edRosArgs: TUiEdit;
    edRosEnv: TUiEdit;
    btnRosEnv: TUiButton;
    edRosPciVendors: TUiEdit;
    edRosRun: TUiEdit;
    // Новый проект RapidQ: вид заготовки и компилятор (BuildRqKindControls)
    lblRqKind: TLabel;
    cbRqKind: TUiComboBox;
    cbRqComp: TUiComboBox;
    FRqKindShown: Boolean;      // списки нужны (New Project, ShowRqKind)
    FDpr: string;               // .dpr проекта; '' - вкладки Delphi нет
    FDof: TMemIniFile;          // <проект>.dof в памяти
    FDofBefore: string;         // текст .dof после загрузки - для сравнения
    FIncludeVerBefore: Boolean;
    FVerKeys: TStringList;      // [Version Info Keys]: Ключ=Значение
    FVerCodePage: Word;
    FFormClasses: TStringList;  // формы проекта: Переменная=Класс
    FHasApp: Boolean;           // в .dpr есть Application.Run
    FOldTitle: string;
    FOldHelpFile: string;
    FOldCreated: string;        // список CreateForm после загрузки
    FNewIconFile: string;       // выбранный значок; '' - не меняется
    FPkgPaths: TStringList;     // пути design-пакетов, по строкам clbDesignPkgs
    FLoading: Boolean;
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
    procedure SetOptionsVisible(AVisible: Boolean);
    procedure UpdateRqIncVisible;
    procedure BuildIncControls;
    procedure UpdateIncPaths;
    procedure cbIncDirChange(Sender: TObject);
    procedure btnIncDelClick(Sender: TObject);
    procedure btnIncDelAllClick(Sender: TObject);
    procedure BuildRosControls;
    procedure BuildRqKindControls;
    function RosSourceDir: string;
    procedure cbRosBuildDirDropDown(Sender: TObject);
    procedure btnRosBuildDirClick(Sender: TObject);
    procedure btnRosEnvClick(Sender: TObject);
    function CompFlag(const AKey: string): Boolean;
    procedure SetCompFlag(const AKey: string; AValue: Boolean);
    procedure LoadForms;
    procedure LoadApplication;
    procedure LoadCompiler;
    procedure LoadMessages;
    procedure LoadLinker;
    procedure LoadDirectories;
    procedure LoadVersion;
    procedure LoadPackages;
    procedure SaveCompiler;
    procedure SaveMessages;
    procedure SaveLinker;
    procedure SaveDirectories;
    procedure SaveVersion;
    procedure SavePackages;
    function SaveDpr(ALog: TStrings): Boolean;
    procedure RefreshMainForm;
    procedure RefreshVerKeys;
    procedure SetVerKey(const AKey, AValue: string);
    procedure EnableVersionControls;
    procedure FillLocales;
    procedure SelectLocale(ALocale: Word);
    function DofText: string;
  public
    // Показать вкладку Project options и заполнить её по ADpr
    procedure LoadDelphiOptions(const ADpr: string);
    // Папка inc проекта RapidQ: ASysDir (Include UnIde), AUserDir (Include
    // User) - из настроек компилятора; AMode - 'sys', 'user' или 'own';
    // AOwnDir - своя папка проекта (при own); AOwnList - свои папки,
    // из которых выбирали, через "|"
    procedure SetRqInc(const ASysDir, AUserDir, AMode, AOwnDir,
                       AOwnList: string);
    // 'sys' - Include UnIde, 'user' - Include User, 'own' - своя папка
    function RqIncMode: string;
    // Своя папка проекта (при 'own'), иначе ''
    function RqIncOwnDir: string;
    // Свои папки списка через "|"
    function RqIncOwnList: string;
    // Выбран тип ReactOS
    function IsRosType: Boolean;
    // New Project: показать у типа RapidQ Basic списки вида заготовки и
    // компилятора; AKind - выбранный вид (rqkApp, rqkConsole, rqkCgi)
    procedure ShowRqKind(AKind: Integer);
    // Выбранный вид заготовки RapidQ (rqkApp ...)
    function RqKind: Integer;
    // Компилятор RapidQ: 0 - rc.exe, 1 - FB Smart, 2 - FB Compat (номера -
    // как rqcRc, rqcFbSmart, rqcFbCompat в Unit1)
    function RqComp: Integer;
    // Разрядность сборки через FreeBASIC: 32 или 64
    function RqBits: Integer;
    // Рамка ReactOS: заполнить по настройкам проекта и прочитать. Пути в
    // поле папки сборки - от папки проекта (edDir), если они внутри неё.
    procedure SetRosSettings(const ASettings: TRosSettings);
    procedure GetRosSettings(var ASettings: TRosSettings);
    // Записать .dof, .dpr и .res. AChanged - было ли что записано. Что
    // сделано и ошибки - строками в ALog.
    function SaveDelphiOptions(ALog: TStrings; out AChanged: Boolean): Boolean;
    property DelphiDpr: string read FDpr;
  end;

implementation

{$R *.dfm}

const
  // Высота окна без вкладки Project options и с ней; с рамкой папки inc
  // (проект RapidQ) - выше на её высоту
  CompactClientHeight = 224;
  CompactRqClientHeight = 352;
  CompactRosClientHeight = 456;
  FullClientHeight = 560;
  // Design-пакеты Delphi 7
  KnownPackagesKey = 'Software\Borland\Delphi\7.0\Known Packages';

var
  // Список языков для EnumSystemLocales: "Название=LCID"
  GLocaleList: TStringList;

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана - та же беда, что у главного окна (см.
// TForm1.WMUpdateUIState). Сообщение дальше не передаём: состояние не
// меняется, и перерисовывать нечего.
procedure TDlgNewPrj.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgNewPrj.FormCreate(Sender: TObject);
begin
  FVerKeys := TStringList.Create;
  FFormClasses := TStringList.Create;
  FPkgPaths := TStringList.Create;
  BuildRosControls;
  BuildRqKindControls;
  SetOptionsVisible(False);
end;

procedure TDlgNewPrj.FormDestroy(Sender: TObject);
begin
  FDof.Free;
  FVerKeys.Free;
  FFormClasses.Free;
  FPkgPaths.Free;
end;

procedure TDlgNewPrj.SetOptionsVisible(AVisible: Boolean);
begin
  tsOptions.TabVisible := AVisible;
  pcMain.ActivePage := tsProject;
  UpdateRqIncVisible;
end;

// Рамка папки inc - только у проекта RapidQ, рамка ReactOS - у проекта
// ReactOS; высота окна - по ним
procedure TDlgNewPrj.UpdateRqIncVisible;
begin
  grpRqInc.Visible := CompareText(cbType.Text, 'RapidQ Basic') = 0;
  if grpRos <> nil then
    grpRos.Visible := IsRosType;
  if cbRqKind <> nil then
  begin
    cbRqKind.Visible := FRqKindShown and grpRqInc.Visible;
    lblRqKind.Visible := cbRqKind.Visible;
    cbRqComp.Visible := cbRqKind.Visible;
  end;
  if tsOptions.TabVisible then
    ClientHeight := FullClientHeight
  else if grpRqInc.Visible then
    ClientHeight := CompactRqClientHeight
  else if (grpRos <> nil) and grpRos.Visible then
    ClientHeight := CompactRosClientHeight
  else
    ClientHeight := CompactClientHeight;
end;

function TDlgNewPrj.IsRosType: Boolean;
begin
  Result := CompareText(cbType.Text, RosProjectType) = 0;
end;

// Рамка ReactOS - на месте рамки папки inc (они не видны вместе):
//   Папка сборки  [output-*  v] [...]
//   Цель ninja    [bootcd    v]
//   configure     [параметры        ]
//   Скрипт RosBE  [путь        ] [...]
//   Производители PCI [8086 1022 ...  ]
//   Запуск (Run)  [команда эмулятора; пусто - свой QEMU unIDE]
//   пояснение
procedure TDlgNewPrj.BuildRosControls;
const
  LabelLeft = 12;
  FieldLeft = 130;

  procedure AddLabel(ATop: Integer; const ACaption: string);
  var
    RowLabel: TLabel;
  begin
    RowLabel := TLabel.Create(Self);
    RowLabel.Parent := grpRos;
    RowLabel.SetBounds(LabelLeft, ATop + 4, FieldLeft - LabelLeft - 4, 13);
    RowLabel.Caption := ACaption;
  end;

var
  NoteLabel: TLabel;
begin
  if grpRos <> nil then
    Exit;
  grpRos := TUiGroupBox.Create(Self);
  grpRos.Parent := tsProject;
  grpRos.SetBounds(grpRqInc.Left, grpRqInc.Top, grpRqInc.Width, 222);
  grpRos.Caption := 'ReactOS / LiberNT: CMake + Ninja';
  grpRos.Visible := False;

  AddLabel(22, 'Папка сборки');
  cbRosBuildDir := TUiComboBox.Create(Self);
  cbRosBuildDir.Parent := grpRos;
  cbRosBuildDir.Style := csDropDown;
  cbRosBuildDir.SetBounds(FieldLeft, 22, 530, 21);
  cbRosBuildDir.OnDropDown := cbRosBuildDirDropDown;
  cbRosBuildDir.Hint := 'Папка, которую создал configure.cmd (output-*); ' +
                        'в списке - такие папки в папке проекта';
  cbRosBuildDir.ShowHint := True;

  btnRosBuildDir := TUiButton.Create(Self);
  btnRosBuildDir.Parent := grpRos;
  btnRosBuildDir.SetBounds(FieldLeft + 536, 21, 30, 23);
  btnRosBuildDir.Caption := '...';
  btnRosBuildDir.Hint := 'Выбрать папку сборки';
  btnRosBuildDir.ShowHint := True;
  btnRosBuildDir.OnClick := btnRosBuildDirClick;

  AddLabel(50, 'Цель ninja');
  cbRosTarget := TUiComboBox.Create(Self);
  cbRosTarget.Parent := grpRos;
  cbRosTarget.Style := csDropDown;
  cbRosTarget.SetBounds(FieldLeft, 50, 200, 21);
  RosNinjaTargets(cbRosTarget.Items);
  cbRosTarget.Text := RosDefaultTarget;
  cbRosTarget.Hint := 'bootcd, livecd; у LiberNT ещё liberntimg, ' +
                      'liberntvhd; можно вписать имя модуля (ntoskrnl)';
  cbRosTarget.ShowHint := True;

  AddLabel(78, 'Параметры configure');
  edRosArgs := TUiEdit.Create(Self);
  edRosArgs.Parent := grpRos;
  edRosArgs.SetBounds(FieldLeft, 78, 566, 21);
  edRosArgs.Hint := 'Параметры configure.cmd. LiberNT: /gcc (по ' +
                    'умолчанию), /clang, /arch=amd64, /r - release';
  edRosArgs.ShowHint := True;

  AddLabel(106, 'Скрипт RosBE');
  edRosEnv := TUiEdit.Create(Self);
  edRosEnv.Parent := grpRos;
  edRosEnv.SetBounds(FieldLeft, 106, 530, 21);
  edRosEnv.Hint := 'Скрипт окружения перед сборкой: для reactosVG14 - ' +
                   'RosBE.cmd из RosBE 2.2.1. Для LiberNT пусто: ' +
                   'configure.cmd находит RosBE сам';
  edRosEnv.ShowHint := True;

  btnRosEnv := TUiButton.Create(Self);
  btnRosEnv.Parent := grpRos;
  btnRosEnv.SetBounds(FieldLeft + 536, 105, 30, 23);
  btnRosEnv.Caption := '...';
  btnRosEnv.Hint := 'Выбрать скрипт окружения (.cmd, .bat)';
  btnRosEnv.ShowHint := True;
  btnRosEnv.OnClick := btnRosEnvClick;

  AddLabel(134, 'Производители PCI');
  edRosPciVendors := TUiEdit.Create(Self);
  edRosPciVendors.Parent := grpRos;
  edRosPciVendors.SetBounds(FieldLeft, 134, 566, 21);
  edRosPciVendors.Text := PciDefaultVendors;
  edRosPciVendors.Hint := 'Коды производителей чипсетов (8086 Intel, ' +
    '1022 AMD ...) для ReactOS - Generate System Devices INF: их ' +
    'служебные устройства (контроллер памяти, SMBus ...) попадают в ' +
    'pciids.inf. Мосты PCI берутся от всех производителей';
  edRosPciVendors.ShowHint := True;

  AddLabel(162, 'Запуск (Run)');
  edRosRun := TUiEdit.Create(Self);
  edRosRun.Parent := grpRos;
  edRosRun.SetBounds(FieldLeft, 162, 566, 21);
  edRosRun.Hint := 'Пусто - собранный образ (<цель>.iso) запускается в ' +
    'своём QEMU unIDE (tools\qemu, скачивается при первом Run). Своя ' +
    'команда эмулятора: %ISO% - образ, %BUILDDIR%, %SOURCEDIR%, %SERIAL% ' +
    '- файл для COM1, %QEMU% - свой QEMU unIDE';
  edRosRun.ShowHint := True;

  NoteLabel := TLabel.Create(Self);
  NoteLabel.Parent := grpRos;
  NoteLabel.AutoSize := False;
  NoteLabel.WordWrap := True;
  NoteLabel.SetBounds(LabelLeft, 190, 690, 28);
  NoteLabel.Caption := 'Папка проекта - корень исходников (configure.cmd, ' +
                       'CMakeLists.txt, PreLoad.cmake). Compile: configure, ' +
                       'если в папке сборки нет build.ninja, затем ninja.';
end;

// Списки нового проекта RapidQ - справа от типа, в той же строке:
//   Тип проекта [RapidQ Basic v]  Вид [Application v] [rc.exe v]
procedure TDlgNewPrj.BuildRqKindControls;
begin
  if cbRqKind <> nil then
    Exit;
  lblRqKind := TLabel.Create(Self);
  lblRqKind.Parent := tsProject;
  lblRqKind.SetBounds(432, 108, 24, 13);
  lblRqKind.Caption := 'Вид';
  lblRqKind.Visible := False;

  cbRqKind := TUiComboBox.Create(Self);
  cbRqKind.Parent := tsProject;
  cbRqKind.Style := csDropDownList;
  cbRqKind.SetBounds(460, 104, 132, 21);
  cbRqKind.Items.Add('Application');
  cbRqKind.Items.Add('Console Application');
  cbRqKind.Items.Add('CGI Application');
  cbRqKind.ItemIndex := 0;
  cbRqKind.Hint := 'Заготовка главного файла: программа с формой, ' +
                   'консольная ($APPTYPE CONSOLE) или CGI ($APPTYPE CGI). ' +
                   'Только для новой папки - в готовый проект ничего не пишется';
  cbRqKind.ShowHint := True;
  cbRqKind.Visible := False;
  cbRqKind.TabOrder := cbType.TabOrder + 1;

  cbRqComp := TUiComboBox.Create(Self);
  cbRqComp.Parent := tsProject;
  cbRqComp.Style := csDropDownList;
  cbRqComp.SetBounds(598, 104, 124, 21);
  cbRqComp.Items.Add('rc.exe');
  cbRqComp.Items.Add('FB Smart 32');
  cbRqComp.Items.Add('FB Smart 64');
  cbRqComp.Items.Add('FB Compat 32');
  cbRqComp.Items.Add('FB Compat 64');
  cbRqComp.ItemIndex := 0;
  cbRqComp.Hint := 'Чем собирать главный файл: rc.exe RapidQ или ' +
                   'FreeBASIC через перевод RqToFb (Smart / Compat, 32 или ' +
                   '64 бит). Потом меняется в рамке Project';
  cbRqComp.ShowHint := True;
  cbRqComp.Visible := False;
  cbRqComp.TabOrder := cbRqKind.TabOrder + 1;
end;

procedure TDlgNewPrj.ShowRqKind(AKind: Integer);
begin
  BuildRqKindControls;
  FRqKindShown := True;
  case AKind of
    rqkConsole: cbRqKind.ItemIndex := 1;
    rqkCgi: cbRqKind.ItemIndex := 2;
  else
    cbRqKind.ItemIndex := 0;
  end;
  UpdateRqIncVisible;
end;

function TDlgNewPrj.RqKind: Integer;
begin
  Result := rqkApp;
  if cbRqKind = nil then
    Exit;
  case cbRqKind.ItemIndex of
    1: Result := rqkConsole;
    2: Result := rqkCgi;
  end;
end;

function TDlgNewPrj.RqComp: Integer;
begin
  Result := 0;
  if cbRqComp = nil then
    Exit;
  case cbRqComp.ItemIndex of
    1, 2: Result := 1;
    3, 4: Result := 2;
  end;
end;

function TDlgNewPrj.RqBits: Integer;
begin
  Result := 32;
  if (cbRqComp <> nil) and
     ((cbRqComp.ItemIndex = 2) or (cbRqComp.ItemIndex = 4)) then
    Result := 64;
end;

function TDlgNewPrj.RosSourceDir: string;
begin
  Result := Trim(edDir.Text);
  if Result <> '' then
    Result := IncludeTrailingPathDelimiter(Result);
end;

// Список папок сборки - по папке проекта на момент открытия списка: в New
// Project её могли сменить после открытия окна
procedure TDlgNewPrj.cbRosBuildDirDropDown(Sender: TObject);
var
  OldText: string;
begin
  OldText := cbRosBuildDir.Text;
  RosFindOutputDirs(RosSourceDir, cbRosBuildDir.Items);
  cbRosBuildDir.Text := OldText;
end;

procedure TDlgNewPrj.btnRosBuildDirClick(Sender: TObject);
var
  FolderPath: string;
begin
  FolderPath := RosPathFromStore(RosSourceDir, cbRosBuildDir.Text);
  if FolderPath = '' then
    FolderPath := RosSourceDir;
  if not BrowseFolderDialog('Папка сборки (output-*)', FolderPath) then
    Exit;
  cbRosBuildDir.Text := RosPathToStore(RosSourceDir, FolderPath);
end;

procedure TDlgNewPrj.btnRosEnvClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Filter := 'Скрипт (*.cmd;*.bat)|*.cmd;*.bat|*.*|*.*';
    if Trim(edRosEnv.Text) <> '' then
      OpenDlg.InitialDir := ExtractFilePath(Trim(edRosEnv.Text));
    if OpenDlg.Execute then
      edRosEnv.Text := OpenDlg.FileName;
  finally
    OpenDlg.Free;
  end;
end;

procedure TDlgNewPrj.SetRosSettings(const ASettings: TRosSettings);
begin
  BuildRosControls;
  cbRosBuildDir.Text := RosPathToStore(ASettings.SourceDir, ASettings.BuildDir);
  if ASettings.NinjaTarget <> '' then
    cbRosTarget.Text := ASettings.NinjaTarget
  else
    cbRosTarget.Text := RosDefaultTarget;
  edRosArgs.Text := ASettings.ConfigureArgs;
  edRosEnv.Text := ASettings.EnvScript;
  if ASettings.PciVendors <> '' then
    edRosPciVendors.Text := ASettings.PciVendors
  else
    edRosPciVendors.Text := PciDefaultVendors;
  edRosRun.Text := ASettings.RunCommand;
  UpdateRqIncVisible;
end;

procedure TDlgNewPrj.GetRosSettings(var ASettings: TRosSettings);
begin
  ASettings.SourceDir := RosSourceDir;
  ASettings.BuildDir := RosPathFromStore(ASettings.SourceDir,
                                         cbRosBuildDir.Text);
  ASettings.NinjaTarget := Trim(cbRosTarget.Text);
  if ASettings.NinjaTarget = '' then
    ASettings.NinjaTarget := RosDefaultTarget;
  ASettings.ConfigureArgs := Trim(edRosArgs.Text);
  ASettings.EnvScript := Trim(edRosEnv.Text);
  ASettings.PciVendors := Trim(edRosPciVendors.Text);
  ASettings.RunCommand := Trim(edRosRun.Text);
end;

procedure TDlgNewPrj.cbTypeChange(Sender: TObject);
begin
  UpdateRqIncVisible;
end;

const
  IncItemUnIde = 'Include UnIde';
  IncItemUser = 'Include User';

// Рамка папки inc: список (Include UnIde, Include User, свои папки),
// "..." - добавить свою папку, Удалить, Удалить все (свои), под списком -
// пути обеих стандартных папок. Переключатели и поле из .dfm спрятаны.
procedure TDlgNewPrj.BuildIncControls;
begin
  if cbIncDir <> nil then
    Exit;
  rbIncSys.Visible := False;
  rbIncUser.Visible := False;
  edIncPath.Visible := False;
  grpRqInc.Caption := 'Папка inc (RapidQ) - её получает rc.exe (-I)';

  cbIncDir := TUiComboBox.Create(Self);
  cbIncDir.Parent := grpRqInc;
  cbIncDir.Style := csDropDownList;
  cbIncDir.SetBounds(12, 22, 500, 21);
  cbIncDir.OnChange := cbIncDirChange;
  cbIncDir.Hint := 'Include UnIde и Include User - папки из IDE Options; ' +
                   'ниже - свои папки этого проекта';
  cbIncDir.ShowHint := True;

  btnIncBrowse.SetBounds(518, 21, 30, 23);
  btnIncBrowse.Hint := 'Добавить свою папку inc в список и выбрать её';
  btnIncBrowse.ShowHint := True;

  btnIncDel := TUiButton.Create(Self);
  btnIncDel.Parent := grpRqInc;
  btnIncDel.SetBounds(554, 21, 66, 23);
  btnIncDel.Caption := 'Удалить';
  btnIncDel.Hint := 'Убрать выбранную свою папку из списка';
  btnIncDel.ShowHint := True;
  btnIncDel.OnClick := btnIncDelClick;

  btnIncDelAll := TUiButton.Create(Self);
  btnIncDelAll.Parent := grpRqInc;
  btnIncDelAll.SetBounds(626, 21, 76, 23);
  btnIncDelAll.Caption := 'Удалить все';
  btnIncDelAll.Hint := 'Убрать все свои папки (Include UnIde и Include ' +
                       'User остаются)';
  btnIncDelAll.ShowHint := True;
  btnIncDelAll.OnClick := btnIncDelAllClick;

  lblIncPaths := TLabel.Create(Self);
  lblIncPaths.Parent := grpRqInc;
  lblIncPaths.AutoSize := False;
  lblIncPaths.WordWrap := True;
  lblIncPaths.SetBounds(12, 48, 690, 44);

  lblIncNote.Caption := 'Выбор и свои папки сохраняются в настройках ' +
                        'проекта; пути Include UnIde и Include User - в ' +
                        'IDE Options - Compilers - RapidQ Basic';
end;

procedure TDlgNewPrj.SetRqInc(const ASysDir, AUserDir, AMode, AOwnDir,
                              AOwnList: string);
var
  Rest, Item: string;
  SepPos, ItemIdx: Integer;

  procedure AddOwn(const ADir: string);
  var
    Idx: Integer;
  begin
    if Trim(ADir) = '' then
      Exit;
    for Idx := 2 to cbIncDir.Items.Count - 1 do
      if CompareText(ExcludeTrailingPathDelimiter(cbIncDir.Items[Idx]),
                     ExcludeTrailingPathDelimiter(Trim(ADir))) = 0 then
        Exit;
    cbIncDir.Items.Add(Trim(ADir));
  end;

begin
  FIncSysDir := ASysDir;
  FIncUserDir := AUserDir;
  BuildIncControls;
  cbIncDir.Items.Clear;
  cbIncDir.Items.Add(IncItemUnIde);
  cbIncDir.Items.Add(IncItemUser);
  Rest := AOwnList;
  while Rest <> '' do
  begin
    SepPos := Pos('|', Rest);
    if SepPos = 0 then
      SepPos := Length(Rest) + 1;
    Item := Copy(Rest, 1, SepPos - 1);
    Delete(Rest, 1, SepPos);
    AddOwn(Item);
  end;
  AddOwn(AOwnDir);
  cbIncDir.ItemIndex := 0;
  if AMode = 'user' then
    cbIncDir.ItemIndex := 1
  else if (AMode = 'own') and (AOwnDir <> '') then
    for ItemIdx := 2 to cbIncDir.Items.Count - 1 do
      if CompareText(ExcludeTrailingPathDelimiter(cbIncDir.Items[ItemIdx]),
                     ExcludeTrailingPathDelimiter(AOwnDir)) = 0 then
        cbIncDir.ItemIndex := ItemIdx;
  UpdateIncPaths;
  UpdateRqIncVisible;
end;

// Под списком - пути обеих стандартных папок; Удалить - только у своей
procedure TDlgNewPrj.UpdateIncPaths;

  function Shown(const ADir: string): string;
  begin
    if ADir = '' then
      Result := '(не задана в IDE Options)'
    else if not DirectoryExists(ADir) then
      Result := ADir + '  (папки нет)'
    else
      Result := ADir;
  end;

begin
  if cbIncDir = nil then
    Exit;
  lblIncPaths.Caption := IncItemUnIde + ':  ' + Shown(FIncSysDir) + #13#10 +
                         IncItemUser + ':  ' + Shown(FIncUserDir);
  btnIncDel.Enabled := cbIncDir.ItemIndex >= 2;
  btnIncDelAll.Enabled := cbIncDir.Items.Count > 2;
end;

procedure TDlgNewPrj.cbIncDirChange(Sender: TObject);
begin
  UpdateIncPaths;
end;

// "..." - своя папка: в список (если её там нет) и выбрать
procedure TDlgNewPrj.btnIncBrowseClick(Sender: TObject);
var
  FolderPath: string;
  ItemIdx: Integer;
begin
  if cbIncDir = nil then
    Exit;
  case cbIncDir.ItemIndex of
    0: FolderPath := FIncSysDir;
    1: FolderPath := FIncUserDir;
  else
    FolderPath := cbIncDir.Text;
  end;
  if not BrowseFolderDialog('Папка inc', FolderPath) then
    Exit;
  FolderPath := ExcludeTrailingPathDelimiter(Trim(FolderPath));
  if FolderPath = '' then
    Exit;
  for ItemIdx := 2 to cbIncDir.Items.Count - 1 do
    if CompareText(ExcludeTrailingPathDelimiter(cbIncDir.Items[ItemIdx]),
                   FolderPath) = 0 then
    begin
      cbIncDir.ItemIndex := ItemIdx;
      UpdateIncPaths;
      Exit;
    end;
  cbIncDir.ItemIndex := cbIncDir.Items.Add(FolderPath);
  UpdateIncPaths;
end;

procedure TDlgNewPrj.btnIncDelClick(Sender: TObject);
begin
  if (cbIncDir = nil) or (cbIncDir.ItemIndex < 2) then
    Exit;
  cbIncDir.Items.Delete(cbIncDir.ItemIndex);
  cbIncDir.ItemIndex := 0;
  UpdateIncPaths;
end;

procedure TDlgNewPrj.btnIncDelAllClick(Sender: TObject);
begin
  if cbIncDir = nil then
    Exit;
  while cbIncDir.Items.Count > 2 do
    cbIncDir.Items.Delete(cbIncDir.Items.Count - 1);
  cbIncDir.ItemIndex := 0;
  UpdateIncPaths;
end;

// Переключатели из .dfm скрыты (BuildIncControls) - обработчик остался
procedure TDlgNewPrj.rbIncClick(Sender: TObject);
begin
end;

function TDlgNewPrj.RqIncMode: string;
begin
  Result := 'sys';
  if cbIncDir = nil then
    Exit;
  if cbIncDir.ItemIndex = 1 then
    Result := 'user'
  else if cbIncDir.ItemIndex >= 2 then
    Result := 'own';
end;

function TDlgNewPrj.RqIncOwnDir: string;
begin
  Result := '';
  if (cbIncDir <> nil) and (cbIncDir.ItemIndex >= 2) then
    Result := cbIncDir.Items[cbIncDir.ItemIndex];
end;

function TDlgNewPrj.RqIncOwnList: string;
var
  ItemIdx: Integer;
begin
  Result := '';
  if cbIncDir = nil then
    Exit;
  for ItemIdx := 2 to cbIncDir.Items.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + '|';
    Result := Result + cbIncDir.Items[ItemIdx];
  end;
end;

function TDlgNewPrj.DofText: string;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    FDof.GetStrings(Lines);
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Загрузка
// ---------------------------------------------------------------------------

procedure TDlgNewPrj.LoadDelphiOptions(const ADpr: string);
begin
  FDpr := ADpr;
  FreeAndNil(FDof);
  FDof := DofOpen(ADpr);
  FDofBefore := DofText;
  FLoading := True;
  try
    LoadForms;
    LoadApplication;
    LoadCompiler;
    LoadMessages;
    LoadLinker;
    LoadDirectories;
    LoadVersion;
    LoadPackages;
  finally
    FLoading := False;
  end;
  EnableVersionControls;
  SetOptionsVisible(True);
  pcOptions.ActivePage := tsForms;
end;

function TDlgNewPrj.CompFlag(const AKey: string): Boolean;
begin
  Result := Trim(FDof.ReadString('Compiler', AKey, '0')) <> '0';
end;

procedure TDlgNewPrj.SetCompFlag(const AKey: string; AValue: Boolean);
begin
  if AValue then
    FDof.WriteString('Compiler', AKey, '1')
  else
    FDof.WriteString('Compiler', AKey, '0');
end;

// Forms: автосоздаваемые формы - из Application.CreateForm, прочие - из
// uses .dpr
procedure TDlgNewPrj.LoadForms;
var
  Created, AllForms: TStringList;
  FormIdx: Integer;
begin
  Created := TStringList.Create;
  AllForms := TStringList.Create;
  try
    FHasApp := DprHasApplication(FDpr);
    DprReadApp(FDpr, FOldTitle, FOldHelpFile, Created);
    DprFormList(FDpr, AllForms);

    FFormClasses.Assign(AllForms);
    for FormIdx := 0 to Created.Count - 1 do
      if FFormClasses.IndexOfName(Created.Names[FormIdx]) < 0 then
        FFormClasses.Add(Created[FormIdx]);

    lbAutoForms.Items.Clear;
    for FormIdx := 0 to Created.Count - 1 do
      lbAutoForms.Items.Add(Created.Names[FormIdx]);
    lbAvailForms.Items.Clear;
    for FormIdx := 0 to FFormClasses.Count - 1 do
      if lbAutoForms.Items.IndexOf(FFormClasses.Names[FormIdx]) < 0 then
        lbAvailForms.Items.Add(FFormClasses.Names[FormIdx]);
    FOldCreated := Created.Text;
  finally
    AllForms.Free;
    Created.Free;
  end;

  RefreshMainForm;

  if not FHasApp then
  begin
    lblFormsNote.Caption := 'В ' + ExtractFileName(FDpr) + ' нет строки ' +
      'Application.Run (библиотека или пакет) - список форм, Title и Help ' +
      'file здесь не меняются.';
    cbMainForm.Enabled := False;
    lbAutoForms.Enabled := False;
    lbAvailForms.Enabled := False;
    btnFormToAvail.Enabled := False;
    btnAllToAvail.Enabled := False;
    btnFormToAuto.Enabled := False;
    btnAllToAuto.Enabled := False;
    edTitle.Enabled := False;
    edHelpFile.Enabled := False;
    btnHelpBrowse.Enabled := False;
  end;
end;

procedure TDlgNewPrj.RefreshMainForm;
begin
  cbMainForm.Items.Assign(lbAutoForms.Items);
  if cbMainForm.Items.Count > 0 then
    cbMainForm.ItemIndex := 0
  else
    cbMainForm.ItemIndex := -1;
end;

procedure TDlgNewPrj.LoadApplication;
var
  IconStream: TMemoryStream;
begin
  edTitle.Text := FOldTitle;
  // Title в .dpr не задан - по имени .dpr; по OK он запишется в .dpr
  // (отличается от FOldTitle)
  if (FOldTitle = '') and FHasApp then
    edTitle.Text := ChangeFileExt(ExtractFileName(FDpr), '');
  edHelpFile.Text := FOldHelpFile;
  FNewIconFile := '';
  imgIcon.Picture := nil;

  IconStream := TMemoryStream.Create;
  try
    if ResExtractMainIcon(ResFileOf(FDpr), IconStream) then
    try
      IconStream.Position := 0;
      imgIcon.Picture.Icon.LoadFromStream(IconStream);
    except
      // Значок в .res не читается - поле остаётся пустым
      imgIcon.Picture := nil;
    end;
  finally
    IconStream.Free;
  end;
end;

procedure TDlgNewPrj.LoadCompiler;
var
  AlignValue, RefValue: string;
begin
  chkOptimization.Checked := CompFlag('O');
  chkStackFrames.Checked := CompFlag('W');
  chkSafeDivide.Checked := CompFlag('U');
  AlignValue := Trim(FDof.ReadString('Compiler', 'A', '8'));
  if AlignValue = '0' then
    AlignValue := '1';            // $A- - выравнивание по байту
  cbAlign.ItemIndex := cbAlign.Items.IndexOf(AlignValue);
  if cbAlign.ItemIndex < 0 then
    cbAlign.ItemIndex := cbAlign.Items.IndexOf('8');

  chkRangeCheck.Checked := CompFlag('R');
  chkIoCheck.Checked := CompFlag('I');
  chkOverflowCheck.Checked := CompFlag('Q');

  chkDebugInfo.Checked := CompFlag('D');
  chkLocalSymbols.Checked := CompFlag('L');
  // Y: 0 - нет, 1 - только объявления, 2 - полная
  RefValue := Trim(FDof.ReadString('Compiler', 'Y', '1'));
  chkReferenceInfo.Checked := RefValue <> '0';
  chkDefinitionsOnly.Checked := RefValue = '1';
  chkDefinitionsOnly.Enabled := chkReferenceInfo.Checked;
  chkAssertions.Checked := CompFlag('C');

  chkStrictVar.Checked := CompFlag('V');
  chkCompleteBool.Checked := CompFlag('B');
  chkExtendedSyntax.Checked := CompFlag('X');
  chkTypedAddress.Checked := CompFlag('T');
  chkOpenParams.Checked := CompFlag('P');
  chkHugeStrings.Checked := CompFlag('H');
  chkWritableConst.Checked := CompFlag('J');
end;

procedure TDlgNewPrj.chkReferenceInfoClick(Sender: TObject);
begin
  if (csLoading in ComponentState) or (chkDefinitionsOnly = nil) then
    Exit;
  chkDefinitionsOnly.Enabled := chkReferenceInfo.Checked;
end;

procedure TDlgNewPrj.LoadMessages;
var
  KeyIdx, ItemIdx: Integer;
begin
  chkShowHints.Checked := CompFlag('ShowHints');
  chkShowWarnings.Checked := CompFlag('ShowWarnings');

  clbWarnings.Items.Clear;
  for KeyIdx := Low(DofWarnKeys) to High(DofWarnKeys) do
  begin
    ItemIdx := clbWarnings.Items.Add(DofWarnCaption(DofWarnKeys[KeyIdx]));
    clbWarnings.Checked[ItemIdx] := CompFlag(DofWarnKeys[KeyIdx]);
  end;
  for KeyIdx := Low(DofUnsafeKeys) to High(DofUnsafeKeys) do
  begin
    ItemIdx := clbWarnings.Items.Add(DofWarnCaption(DofUnsafeKeys[KeyIdx]));
    clbWarnings.Checked[ItemIdx] := CompFlag(DofUnsafeKeys[KeyIdx]);
  end;
end;

procedure TDlgNewPrj.LoadLinker;
var
  MapValue: string;
  ImageBase: Int64;
begin
  MapValue := Trim(FDof.ReadString('Linker', 'MapFile', '0'));
  rbMapOff.Checked := True;
  if MapValue = '1' then
    rbMapSegments.Checked := True
  else if MapValue = '2' then
    rbMapPublics.Checked := True
  else if MapValue = '3' then
    rbMapDetailed.Checked := True;

  // ConsoleApp=1 стоит в .dof обычных оконных проектов Delphi 7, поэтому
  // галка "Generate console application" - это ConsoleApp=0
  chkConsoleApp.Checked := Trim(FDof.ReadString('Linker', 'ConsoleApp',
                                                '1')) = '0';
  chkTd32Info.Checked := Trim(FDof.ReadString('Linker', 'DebugInfo',
                                              '0')) = '1';
  chkRemoteSymbols.Checked := Trim(FDof.ReadString('Linker', 'RemoteSymbols',
                                                   '0')) = '1';

  edMinStack.Text := Trim(FDof.ReadString('Linker', 'MinStackSize', '16384'));
  edMaxStack.Text := Trim(FDof.ReadString('Linker', 'MaxStackSize',
                                          '1048576'));
  ImageBase := StrToInt64Def(Trim(FDof.ReadString('Linker', 'ImageBase',
                                                  '4194304')), 4194304);
  edImageBase.Text := '$' + IntToHex(ImageBase, 8);
  edExeDescription.Text := FDof.ReadString('Linker', 'ExeDescription', '');
end;

procedure TDlgNewPrj.LoadDirectories;
begin
  edOutputDir.Text := FDof.ReadString('Directories', 'OutputDir', '');
  edUnitOutputDir.Text := FDof.ReadString('Directories', 'UnitOutputDir', '');
  edSearchPath.Text := FDof.ReadString('Directories', 'SearchPath', '');
  edDebugSourceDirs.Text := FDof.ReadString('Directories', 'DebugSourceDirs',
                                            '');
  edBplOutputDir.Text := FDof.ReadString('Directories', 'PackageDLLOutputDir',
                                         '');
  edDcpOutputDir.Text := FDof.ReadString('Directories', 'PackageDCPOutputDir',
                                         '');
  edConditionals.Text := FDof.ReadString('Directories', 'Conditionals', '');
  edUnitAliases.Text := FDof.ReadString('Compiler', 'UnitAliases', '');
end;

function VerArrowPos(AValue: Word): SmallInt;
begin
  if AValue > 32767 then
    Result := 32767
  else
    Result := AValue;
end;

procedure TDlgNewPrj.LoadVersion;
var
  Info: TVerInfo;
begin
  Info := DofVerInfo(FDof);
  FIncludeVerBefore := Trim(FDof.ReadString('Version Info', 'IncludeVerInfo',
                                            '0')) = '1';
  chkIncludeVer.Checked := FIncludeVerBefore;
  edMajor.Text := IntToStr(Info.Major);
  edMinor.Text := IntToStr(Info.Minor);
  edRelease.Text := IntToStr(Info.Release);
  edBuild.Text := IntToStr(Info.Build);
  // Стрелки счётчиков - на те же числа (у TUpDown предел 32767)
  udMajor.Position := VerArrowPos(Info.Major);
  udMinor.Position := VerArrowPos(Info.Minor);
  udRelease.Position := VerArrowPos(Info.Release);
  udBuild.Position := VerArrowPos(Info.Build);
  chkAutoInc.Checked := Trim(FDof.ReadString('Version Info', 'AutoIncBuild',
                                             '0')) = '1';
  chkVerDebug.Checked := Info.Debug;
  chkVerPreRelease.Checked := Info.PreRelease;
  chkVerDll.Checked := Info.IsDll;
  chkVerSpecial.Checked := Info.Special;
  chkVerPrivate.Checked := Info.PrivateBuild;

  FVerCodePage := Info.CodePage;
  FillLocales;
  SelectLocale(Info.LangId);

  DofReadVerKeys(FDof, FVerKeys);
  RefreshVerKeys;
end;

procedure TDlgNewPrj.LoadPackages;
var
  Reg: TRegistry;
  Names: TStringList;
  NameIdx, ItemIdx: Integer;
  Description: string;
  Opened: Boolean;
begin
  chkUsePackages.Checked := Trim(FDof.ReadString('Directories', 'UsePackages',
                                                 '0')) = '1';
  edRuntimePkgs.Text := FDof.ReadString('Directories', 'Packages', '');

  clbDesignPkgs.Items.Clear;
  FPkgPaths.Clear;
  Names := TStringList.Create;
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    Opened := Reg.OpenKeyReadOnly(KnownPackagesKey);
    if not Opened then
    begin
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      Opened := Reg.OpenKeyReadOnly(KnownPackagesKey);
    end;
    if Opened then
    begin
      Reg.GetValueNames(Names);
      for NameIdx := 0 to Names.Count - 1 do
      begin
        try
          Description := Reg.ReadString(Names[NameIdx]);
        except
          Description := '';
        end;
        if Description = '' then
          Description := ExtractFileName(Names[NameIdx]);
        ItemIdx := clbDesignPkgs.Items.Add(Description);
        FPkgPaths.Add(Names[NameIdx]);
        clbDesignPkgs.Checked[ItemIdx] :=
          not FDof.ValueExists('Excluded Packages', Names[NameIdx]);
      end;
    end;
  finally
    Reg.Free;
    Names.Free;
  end;

  if FPkgPaths.Count = 0 then
    lblPkgPath.Caption := 'Список пакетов среды Delphi 7 в реестре не найден ' +
                          '(' + KnownPackagesKey + ')'
  else
    lblPkgPath.Caption := '';
end;

procedure TDlgNewPrj.clbDesignPkgsClick(Sender: TObject);
begin
  if (clbDesignPkgs.ItemIndex >= 0) and
     (clbDesignPkgs.ItemIndex < FPkgPaths.Count) then
    lblPkgPath.Caption := FPkgPaths[clbDesignPkgs.ItemIndex];
end;

// ---------------------------------------------------------------------------
//  Forms
// ---------------------------------------------------------------------------

procedure TDlgNewPrj.cbMainFormChange(Sender: TObject);
var
  FormName: string;
  ItemIdx: Integer;
begin
  if cbMainForm.ItemIndex <= 0 then
    Exit;
  // Главная форма - первая в списке автосоздания
  FormName := cbMainForm.Items[cbMainForm.ItemIndex];
  ItemIdx := lbAutoForms.Items.IndexOf(FormName);
  if ItemIdx > 0 then
  begin
    lbAutoForms.Items.Delete(ItemIdx);
    lbAutoForms.Items.Insert(0, FormName);
  end;
  RefreshMainForm;
end;

procedure TDlgNewPrj.btnFormMoveClick(Sender: TObject);

  procedure MoveItem(ASource, ATarget: TUiListBox; AIndex: Integer);
  begin
    ATarget.Items.Add(ASource.Items[AIndex]);
    ASource.Items.Delete(AIndex);
  end;

var
  ItemIdx: Integer;
begin
  if Sender = btnFormToAvail then
  begin
    ItemIdx := lbAutoForms.ItemIndex;
    if ItemIdx >= 0 then
      MoveItem(lbAutoForms, lbAvailForms, ItemIdx);
  end
  else if Sender = btnAllToAvail then
  begin
    for ItemIdx := lbAutoForms.Items.Count - 1 downto 0 do
      MoveItem(lbAutoForms, lbAvailForms, ItemIdx);
  end
  else if Sender = btnFormToAuto then
  begin
    ItemIdx := lbAvailForms.ItemIndex;
    if ItemIdx >= 0 then
      MoveItem(lbAvailForms, lbAutoForms, ItemIdx);
  end
  else if Sender = btnAllToAuto then
  begin
    while lbAvailForms.Items.Count > 0 do
      MoveItem(lbAvailForms, lbAutoForms, 0);
  end;
  RefreshMainForm;
end;

// ---------------------------------------------------------------------------
//  Application
// ---------------------------------------------------------------------------

procedure TDlgNewPrj.btnHelpBrowseClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Filter := 'Help (*.hlp;*.chm)|*.hlp;*.chm|*.*|*.*';
    OpenDlg.InitialDir := ExtractFilePath(FDpr);
    if OpenDlg.Execute then
      edHelpFile.Text := OpenDlg.FileName;
  finally
    OpenDlg.Free;
  end;
end;

procedure TDlgNewPrj.btnLoadIconClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Filter := 'Icon (*.ico)|*.ico';
    OpenDlg.InitialDir := ExtractFilePath(FDpr);
    if not OpenDlg.Execute then
      Exit;
    try
      imgIcon.Picture.LoadFromFile(OpenDlg.FileName);
    except
      on E: Exception do
      begin
        ShowMessage('Значок не загружен: ' + E.Message);
        Exit;
      end;
    end;
    FNewIconFile := OpenDlg.FileName;
  finally
    OpenDlg.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Directories
// ---------------------------------------------------------------------------

procedure TDlgNewPrj.btnDirBrowseClick(Sender: TObject);
var
  TargetEdit: TUiEdit;
  FolderPath: string;
  IsList: Boolean;
begin
  // Tag кнопки - строка таблицы папок (1..6)
  case (Sender as TComponent).Tag of
    1: TargetEdit := edOutputDir;
    2: TargetEdit := edUnitOutputDir;
    3: TargetEdit := edSearchPath;
    4: TargetEdit := edDebugSourceDirs;
    5: TargetEdit := edBplOutputDir;
    6: TargetEdit := edDcpOutputDir;
  else
    Exit;
  end;
  // Search path и Debug source path - списки через ";": папка добавляется
  IsList := (TargetEdit = edSearchPath) or (TargetEdit = edDebugSourceDirs);

  FolderPath := ExtractFilePath(FDpr);
  if (not IsList) and (Trim(TargetEdit.Text) <> '') then
    FolderPath := Trim(TargetEdit.Text);
  if not BrowseFolderDialog('Папка', FolderPath) then
    Exit;

  if IsList and (Trim(TargetEdit.Text) <> '') then
    TargetEdit.Text := Trim(TargetEdit.Text) + ';' + FolderPath
  else
    TargetEdit.Text := FolderPath;
end;

// ---------------------------------------------------------------------------
//  Version Info
// ---------------------------------------------------------------------------

function LocaleEnumProc(ALocaleText: PChar): Integer; stdcall;
var
  LocaleId: Integer;
  NameBuf: array[0..255] of Char;
begin
  Result := 1;
  LocaleId := StrToIntDef('$' + string(ALocaleText), 0);
  if LocaleId = 0 then
    Exit;
  if GetLocaleInfo(LocaleId, LOCALE_SLANGUAGE, NameBuf, SizeOf(NameBuf)) > 0 then
    GLocaleList.AddObject(StrPas(NameBuf), TObject(LocaleId));
end;

procedure TDlgNewPrj.FillLocales;
begin
  cbLocale.Items.Clear;
  GLocaleList := TStringList.Create;
  try
    GLocaleList.Sorted := True;
    GLocaleList.Duplicates := dupIgnore;
    EnumSystemLocales(@LocaleEnumProc, LCID_SUPPORTED);
    cbLocale.Items.Assign(GLocaleList);
  finally
    FreeAndNil(GLocaleList);
  end;
end;

procedure TDlgNewPrj.SelectLocale(ALocale: Word);
var
  ItemIdx: Integer;
begin
  ItemIdx := cbLocale.Items.IndexOfObject(TObject(Integer(ALocale)));
  if ItemIdx < 0 then
    ItemIdx := cbLocale.Items.AddObject('$' + IntToHex(ALocale, 4),
                                        TObject(Integer(ALocale)));
  cbLocale.ItemIndex := ItemIdx;
  lblLocaleId.Caption := 'Locale ID: $' + IntToHex(ALocale, 4);
end;

procedure TDlgNewPrj.cbLocaleChange(Sender: TObject);
var
  LocaleId: Integer;
  PageBuf: array[0..15] of Char;
begin
  if csLoading in ComponentState then
    Exit;
  if cbLocale.ItemIndex < 0 then
    Exit;
  LocaleId := Integer(cbLocale.Items.Objects[cbLocale.ItemIndex]);
  lblLocaleId.Caption := 'Locale ID: $' + IntToHex(LocaleId, 4);
  // Кодовая страница строк версии - ANSI-страница выбранного языка
  if GetLocaleInfo(LocaleId, LOCALE_IDEFAULTANSICODEPAGE, PageBuf,
                   SizeOf(PageBuf)) > 0 then
    FVerCodePage := StrToIntDef(StrPas(PageBuf), FVerCodePage);
  if FVerCodePage = 0 then
    FVerCodePage := 1200;   // язык без ANSI-страницы - Unicode
end;

procedure TDlgNewPrj.RefreshVerKeys;
var
  KeyIdx, SelIdx: Integer;
  ListItem: TListItem;
begin
  SelIdx := -1;
  if lvVerKeys.Selected <> nil then
    SelIdx := lvVerKeys.Selected.Index;
  lvVerKeys.Items.BeginUpdate;
  try
    lvVerKeys.Items.Clear;
    for KeyIdx := 0 to FVerKeys.Count - 1 do
    begin
      ListItem := lvVerKeys.Items.Add;
      ListItem.Caption := FVerKeys.Names[KeyIdx];
      ListItem.SubItems.Add(Copy(FVerKeys[KeyIdx],
                                 Pos('=', FVerKeys[KeyIdx]) + 1, MaxInt));
    end;
  finally
    lvVerKeys.Items.EndUpdate;
  end;
  if (SelIdx >= 0) and (SelIdx < lvVerKeys.Items.Count) then
    lvVerKeys.Selected := lvVerKeys.Items[SelIdx];
end;

// Values[] := '' в TStrings удаляет строку - здесь пустое значение остаётся
procedure TDlgNewPrj.SetVerKey(const AKey, AValue: string);
var
  KeyIdx: Integer;
begin
  KeyIdx := FVerKeys.IndexOfName(AKey);
  if KeyIdx >= 0 then
    FVerKeys[KeyIdx] := AKey + '=' + AValue
  else
    FVerKeys.Add(AKey + '=' + AValue);
end;

procedure TDlgNewPrj.edVerNumberChange(Sender: TObject);
begin
  // Обработчик срабатывает и при загрузке формы из .dfm: стрелки счётчика
  // (Associate) пишут в поле своё число раньше FormCreate, когда FVerKeys
  // ещё не создан
  if FLoading or (FVerKeys = nil) or (csLoading in ComponentState) then
    Exit;
  // FileVersion среда Delphi ведёт по номеру версии
  SetVerKey('FileVersion', Format('%d.%d.%d.%d',
    [StrToIntDef(edMajor.Text, 0), StrToIntDef(edMinor.Text, 0),
     StrToIntDef(edRelease.Text, 0), StrToIntDef(edBuild.Text, 0)]));
  RefreshVerKeys;
end;

procedure TDlgNewPrj.chkIncludeVerClick(Sender: TObject);
begin
  if csLoading in ComponentState then
    Exit;
  EnableVersionControls;
end;

procedure TDlgNewPrj.EnableVersionControls;
var
  VerOn: Boolean;
  CtlIdx: Integer;
begin
  VerOn := chkIncludeVer.Checked;
  for CtlIdx := 0 to grpVerNumber.ControlCount - 1 do
    grpVerNumber.Controls[CtlIdx].Enabled := VerOn;
  for CtlIdx := 0 to grpModAttr.ControlCount - 1 do
    grpModAttr.Controls[CtlIdx].Enabled := VerOn;
  for CtlIdx := 0 to grpLanguage.ControlCount - 1 do
    grpLanguage.Controls[CtlIdx].Enabled := VerOn;
  lvVerKeys.Enabled := VerOn;
  edVerKey.Enabled := VerOn;
  edVerValue.Enabled := VerOn;
  btnVerKeySet.Enabled := VerOn;
  btnVerKeyDel.Enabled := VerOn;
end;

procedure TDlgNewPrj.lvVerKeysSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if (not Selected) or (Item = nil) then
    Exit;
  edVerKey.Text := Item.Caption;
  if Item.SubItems.Count > 0 then
    edVerValue.Text := Item.SubItems[0]
  else
    edVerValue.Text := '';
end;

procedure TDlgNewPrj.btnVerKeySetClick(Sender: TObject);
var
  KeyName: string;
begin
  KeyName := Trim(edVerKey.Text);
  if KeyName = '' then
    Exit;
  if (Pos('=', KeyName) > 0) or (Pos(' ', KeyName) > 0) then
  begin
    ShowMessage('В имени ключа не должно быть пробелов и знака "="');
    Exit;
  end;
  SetVerKey(KeyName, edVerValue.Text);
  RefreshVerKeys;
end;

procedure TDlgNewPrj.btnVerKeyDelClick(Sender: TObject);
var
  KeyIdx: Integer;
begin
  KeyIdx := FVerKeys.IndexOfName(Trim(edVerKey.Text));
  if KeyIdx < 0 then
    Exit;
  FVerKeys.Delete(KeyIdx);
  edVerKey.Text := '';
  edVerValue.Text := '';
  RefreshVerKeys;
end;

// ---------------------------------------------------------------------------
//  Запись
// ---------------------------------------------------------------------------

procedure TDlgNewPrj.SaveCompiler;
var
  RefValue: string;
begin
  SetCompFlag('O', chkOptimization.Checked);
  SetCompFlag('W', chkStackFrames.Checked);
  SetCompFlag('U', chkSafeDivide.Checked);
  if cbAlign.ItemIndex >= 0 then
    FDof.WriteString('Compiler', 'A', cbAlign.Items[cbAlign.ItemIndex]);

  SetCompFlag('R', chkRangeCheck.Checked);
  SetCompFlag('I', chkIoCheck.Checked);
  SetCompFlag('Q', chkOverflowCheck.Checked);

  SetCompFlag('D', chkDebugInfo.Checked);
  SetCompFlag('L', chkLocalSymbols.Checked);
  if not chkReferenceInfo.Checked then
    RefValue := '0'
  else if chkDefinitionsOnly.Checked then
    RefValue := '1'
  else
    RefValue := '2';
  FDof.WriteString('Compiler', 'Y', RefValue);
  SetCompFlag('C', chkAssertions.Checked);

  SetCompFlag('V', chkStrictVar.Checked);
  SetCompFlag('B', chkCompleteBool.Checked);
  SetCompFlag('X', chkExtendedSyntax.Checked);
  SetCompFlag('T', chkTypedAddress.Checked);
  SetCompFlag('P', chkOpenParams.Checked);
  SetCompFlag('H', chkHugeStrings.Checked);
  SetCompFlag('J', chkWritableConst.Checked);
end;

procedure TDlgNewPrj.SaveMessages;
var
  KeyIdx, ItemIdx: Integer;
begin
  SetCompFlag('ShowHints', chkShowHints.Checked);
  SetCompFlag('ShowWarnings', chkShowWarnings.Checked);
  ItemIdx := 0;
  for KeyIdx := Low(DofWarnKeys) to High(DofWarnKeys) do
  begin
    SetCompFlag(DofWarnKeys[KeyIdx], clbWarnings.Checked[ItemIdx]);
    Inc(ItemIdx);
  end;
  for KeyIdx := Low(DofUnsafeKeys) to High(DofUnsafeKeys) do
  begin
    SetCompFlag(DofUnsafeKeys[KeyIdx], clbWarnings.Checked[ItemIdx]);
    Inc(ItemIdx);
  end;
end;

procedure TDlgNewPrj.SaveLinker;
var
  MapValue, BaseText: string;
  NumValue: Int64;
begin
  if rbMapSegments.Checked then
    MapValue := '1'
  else if rbMapPublics.Checked then
    MapValue := '2'
  else if rbMapDetailed.Checked then
    MapValue := '3'
  else
    MapValue := '0';
  FDof.WriteString('Linker', 'MapFile', MapValue);

  if chkConsoleApp.Checked then
    FDof.WriteString('Linker', 'ConsoleApp', '0')
  else
    FDof.WriteString('Linker', 'ConsoleApp', '1');
  if chkTd32Info.Checked then
    FDof.WriteString('Linker', 'DebugInfo', '1')
  else
    FDof.WriteString('Linker', 'DebugInfo', '0');
  if chkRemoteSymbols.Checked then
    FDof.WriteString('Linker', 'RemoteSymbols', '1')
  else
    FDof.WriteString('Linker', 'RemoteSymbols', '0');

  // Числа: неверное значение - остаётся прежнее
  NumValue := StrToInt64Def(Trim(edMinStack.Text), -1);
  if NumValue > 0 then
    FDof.WriteString('Linker', 'MinStackSize', IntToStr(NumValue));
  NumValue := StrToInt64Def(Trim(edMaxStack.Text), -1);
  if NumValue > 0 then
    FDof.WriteString('Linker', 'MaxStackSize', IntToStr(NumValue));
  BaseText := Trim(edImageBase.Text);
  if (Copy(BaseText, 1, 2) = '0x') or (Copy(BaseText, 1, 2) = '0X') then
    BaseText := '$' + Copy(BaseText, 3, MaxInt);
  NumValue := StrToInt64Def(BaseText, -1);
  if NumValue > 0 then
    FDof.WriteString('Linker', 'ImageBase', IntToStr(NumValue));
  FDof.WriteString('Linker', 'ExeDescription', edExeDescription.Text);
end;

procedure TDlgNewPrj.SaveDirectories;
begin
  FDof.WriteString('Directories', 'OutputDir', Trim(edOutputDir.Text));
  FDof.WriteString('Directories', 'UnitOutputDir', Trim(edUnitOutputDir.Text));
  FDof.WriteString('Directories', 'SearchPath', Trim(edSearchPath.Text));
  FDof.WriteString('Directories', 'DebugSourceDirs',
                   Trim(edDebugSourceDirs.Text));
  FDof.WriteString('Directories', 'PackageDLLOutputDir',
                   Trim(edBplOutputDir.Text));
  FDof.WriteString('Directories', 'PackageDCPOutputDir',
                   Trim(edDcpOutputDir.Text));
  FDof.WriteString('Directories', 'Conditionals', Trim(edConditionals.Text));
  FDof.WriteString('Compiler', 'UnitAliases', Trim(edUnitAliases.Text));
end;

procedure TDlgNewPrj.SaveVersion;

  procedure WriteFlag(const AKey: string; AValue: Boolean);
  begin
    if AValue then
      FDof.WriteString('Version Info', AKey, '1')
    else
      FDof.WriteString('Version Info', AKey, '0');
  end;

  procedure WriteNumber(const AKey: string; AEdit: TUiEdit);
  var
    NumValue: Integer;
  begin
    NumValue := StrToIntDef(Trim(AEdit.Text), -1);
    if (NumValue >= 0) and (NumValue <= 65535) then
      FDof.WriteString('Version Info', AKey, IntToStr(NumValue));
  end;

begin
  WriteFlag('IncludeVerInfo', chkIncludeVer.Checked);
  WriteFlag('AutoIncBuild', chkAutoInc.Checked);
  WriteNumber('MajorVer', edMajor);
  WriteNumber('MinorVer', edMinor);
  WriteNumber('Release', edRelease);
  WriteNumber('Build', edBuild);
  WriteFlag('Debug', chkVerDebug.Checked);
  WriteFlag('PreRelease', chkVerPreRelease.Checked);
  WriteFlag('Special', chkVerSpecial.Checked);
  WriteFlag('Private', chkVerPrivate.Checked);
  WriteFlag('DLL', chkVerDll.Checked);
  if cbLocale.ItemIndex >= 0 then
    FDof.WriteString('Version Info', 'Locale',
      IntToStr(Integer(cbLocale.Items.Objects[cbLocale.ItemIndex])));
  FDof.WriteString('Version Info', 'CodePage', IntToStr(FVerCodePage));
  DofWriteVerKeys(FDof, FVerKeys);
end;

procedure TDlgNewPrj.SavePackages;
var
  ItemIdx: Integer;
begin
  if chkUsePackages.Checked then
    FDof.WriteString('Directories', 'UsePackages', '1')
  else
    FDof.WriteString('Directories', 'UsePackages', '0');
  FDof.WriteString('Directories', 'Packages', Trim(edRuntimePkgs.Text));

  // Списка из реестра нет - прежний [Excluded Packages] не трогаем
  if FPkgPaths.Count = 0 then
    Exit;
  FDof.EraseSection('Excluded Packages');
  for ItemIdx := 0 to FPkgPaths.Count - 1 do
    if not clbDesignPkgs.Checked[ItemIdx] then
      FDof.WriteString('Excluded Packages', FPkgPaths[ItemIdx],
                       clbDesignPkgs.Items[ItemIdx]);
end;

// Title, HelpFile и CreateForm - в .dpr, если что-то из них менялось
function TDlgNewPrj.SaveDpr(ALog: TStrings): Boolean;
var
  Created: TStringList;
  FormIdx, ClassIdx: Integer;
  FormClass, ErrText: string;
  DprChanged: Boolean;
begin
  Result := False;
  if not FHasApp then
    Exit;
  Created := TStringList.Create;
  try
    for FormIdx := 0 to lbAutoForms.Items.Count - 1 do
    begin
      ClassIdx := FFormClasses.IndexOfName(lbAutoForms.Items[FormIdx]);
      if ClassIdx >= 0 then
        FormClass := FFormClasses.ValueFromIndex[ClassIdx]
      else
        FormClass := 'T' + lbAutoForms.Items[FormIdx];
      Created.Add(lbAutoForms.Items[FormIdx] + '=' + FormClass);
    end;

    if (Created.Text = FOldCreated) and (edTitle.Text = FOldTitle) and
       (edHelpFile.Text = FOldHelpFile) then
      Exit;

    if DprWriteApp(FDpr, edTitle.Text, edHelpFile.Text, Created, DprChanged,
                   ErrText) then
    begin
      Result := DprChanged;
      if DprChanged then
        ALog.Add('Записан ' + ExtractFileName(FDpr) +
                 ': Title, Help file, автосоздаваемые формы');
    end
    else
      ALog.Add('Ошибка: ' + ErrText);
  finally
    Created.Free;
  end;
end;

function TDlgNewPrj.SaveDelphiOptions(ALog: TStrings;
  out AChanged: Boolean): Boolean;
var
  ErrText: string;
  DofChanged: Boolean;
begin
  Result := True;
  AChanged := False;
  if (FDpr = '') or (FDof = nil) then
    Exit;

  SaveCompiler;
  SaveMessages;
  SaveLinker;
  SaveDirectories;
  SaveVersion;
  SavePackages;

  DofChanged := DofText <> FDofBefore;
  if DofChanged then
    try
      FDof.UpdateFile;
      ALog.Add('Записан ' + ExtractFileName(DofFileOf(FDpr)));
      AChanged := True;
    except
      on E: Exception do
      begin
        ALog.Add('Ошибка: не записан ' + DofFileOf(FDpr) + ': ' + E.Message);
        Result := False;
      end;
    end;

  if FNewIconFile <> '' then
  begin
    if ResReplaceMainIcon(ResFileOf(FDpr), FNewIconFile, ErrText) then
    begin
      ALog.Add('Значок ' + ExtractFileName(FNewIconFile) + ' записан в ' +
               ExtractFileName(ResFileOf(FDpr)));
      AChanged := True;
    end
    else
    begin
      ALog.Add('Ошибка: ' + ErrText);
      Result := False;
    end;
  end;

  // VERSIONINFO в .res: версия включена (или её только что выключили) и
  // настройки менялись
  if DofChanged and (chkIncludeVer.Checked or FIncludeVerBefore) then
  begin
    if DofApplyVersionToRes(FDpr, FDof, ALog) then
      AChanged := True
    else
      Result := False;
  end;

  if SaveDpr(ALog) then
    AChanged := True;
end;

end.
