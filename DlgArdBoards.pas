unit DlgArdBoards;

// Board Manager: платформы (cores) arduino-cli и их платы. Перенос окна
// BoardMngForm из RQdebugger853-8.bas.
//
// Что показывает:
// - Core list: установленные платформы (core list) и все известные из
//   индекса (core search) - неустановленные с пометкой Not installed;
//   справа - платы выбранной платформы (из board search);
// - Board list: все известные платы (board search);
// - 3rd-party-boards list: Additional Boards Manager URLs;
// - Log: вывод команд arduino-cli;
// - внизу - programmers.txt, boards.txt и platform.txt выбранной
//   установленной платформы.
//
// Отличия от RQdebugger:
// - списки берутся из вывода команд в памяти, без промежуточных txt-файлов;
// - пункты Core operations (Download, Uninstall, Search, Update index,
//   Upgrade) выполняют свои команды, а не обновление списка;
// - Additional Boards Manager URLs хранятся в editor.ini
//   ([Compiler.Arduino] AdditionalUrls) и передаются командам core и board
//   ключом --additional-urls;
// - выбор платы - без порта: порт берётся по факту подключения платы, а
//   плата (FQBN) - для какой платы собирается скетч.
//
// Окно описано в DlgArdBoards.dfm. Создаёт и показывает его TForm1
// (ArdBoardsShow, Unit1); здесь - вся работа окна. Форма создаётся по
// месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls, Menus,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiEdit, TUiMemo
  UiStdCtrls,    // TUiCheckBox
  UiComCtrls,    // TUiListView, TUiPageControl
  UiMenus,       // TUiPopupMenu
  ArduinoCli,
  Dialogs,       // TMsgDlgType, mbYes ... для MessageDlg
  // Окна сообщений по теме - последним, поверх Dialogs
  UiDialogs;

type
  TDlgArdBoards = class(TForm)
    pnlViews: TPanel;
    btnAllCores: TUiButton;
    btnInstCores: TUiButton;
    btnAllBoards: TUiButton;
    btnInstBoards: TUiButton;
    btnRefresh: TUiButton;
    btnCoreOps: TUiButton;
    pnlFilter: TPanel;
    edFilter: TUiEdit;
    chkFilter: TUiCheckBox;
    btnInstallCore: TUiButton;
    pnlSelect: TPanel;
    edSelBoard: TUiEdit;
    btnSelectBoard: TUiButton;
    pcMain: TUiPageControl;
    tsCores: TTabSheet;
    lvCores: TUiListView;
    splCores: TSplitter;
    lvCoreBoards: TUiListView;
    tsBoards: TTabSheet;
    lvBoards: TUiListView;
    tsUrls: TTabSheet;
    lblUrls: TLabel;
    memUrls: TUiMemo;
    pnlUrlsButtons: TPanel;
    btnUrlsSave: TUiButton;
    btnUrlsIndex: TUiButton;
    tsLog: TTabSheet;
    memLog: TUiMemo;
    splFiles: TSplitter;
    pnlFiles: TPanel;
    pnlProgr: TPanel;
    lblProgr: TLabel;
    memProgr: TUiMemo;
    splProgr: TSplitter;
    pnlPlatf: TPanel;
    lblPlatf: TLabel;
    memPlatf: TUiMemo;
    splPlatf: TSplitter;
    pnlBoardsTxt: TPanel;
    lblBoardsTxt: TLabel;
    memBoardsTxt: TUiMemo;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    btnStop: TUiButton;
    pmCoreOps: TUiPopupMenu;
    miCoreDownload: TMenuItem;
    miCoreInstall: TMenuItem;
    miCoreUninstall: TMenuItem;
    miCoreSearch: TMenuItem;
    miCoreUpdateIndex: TMenuItem;
    miCoreUpgrade: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnAllCoresClick(Sender: TObject);
    procedure btnInstCoresClick(Sender: TObject);
    procedure btnAllBoardsClick(Sender: TObject);
    procedure btnInstBoardsClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnCoreOpsClick(Sender: TObject);
    procedure edFilterChange(Sender: TObject);
    procedure chkFilterClick(Sender: TObject);
    procedure btnInstallCoreClick(Sender: TObject);
    procedure btnSelectBoardClick(Sender: TObject);
    procedure lvCoresSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure lvBoardSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure btnUrlsSaveClick(Sender: TObject);
    procedure btnUrlsIndexClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure miCoreDownloadClick(Sender: TObject);
    procedure miCoreInstallClick(Sender: TObject);
    procedure miCoreUninstallClick(Sender: TObject);
    procedure miCoreSearchClick(Sender: TObject);
    procedure miCoreUpdateIndexClick(Sender: TObject);
    procedure miCoreUpgradeClick(Sender: TObject);
  private
    FSettingsFile: string;
    FSettings: TArdSettings;
    // Платформы: "Имя"#9"Installed"#9"Latest"#9"ID"; Installed пустой -
    // не установлена
    FCoreRows: TStringList;
    // Платы: "Board Name"#9"FQBN"#9"Platform ID"; FQBN пустой - платформа
    // не установлена
    FBoardRows: TStringList;
    FCoresInstalledOnly: Boolean;
    FBoardsInstalledOnly: Boolean;
    FLoaded: Boolean;          // списки уже читались
    FBusy: Boolean;            // идёт команда arduino-cli
    FStop: Boolean;            // нажата Stop
    FProgressIdx: Integer;     // строка прогресса загрузки в Log, -1 - нет
    FSelFqbn: string;          // выбранная плата
    FSelBoardName: string;
    FSelCore: string;
    FOnBoardSelected: TNotifyEvent;
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
    // Чтение списков после показа окна (FormShow его посылает)
    procedure WMRefreshLists(var Message: TMessage); message WM_USER + 1;
    function  LoadSettings: Boolean;
    function  UrlArgs: string;
    function  RunCli(const AArgs: string; AOutput: TStrings): Integer;
    procedure CliLine(const ALine: string);
    procedure CliProgress(const AText: string);
    procedure CliIdle(var ACancel: Boolean);
    procedure SetStatus(const AText: string);
    procedure LogAdd(const AText: string);
    procedure RefreshLists;
    procedure FillCores;
    procedure FillBoards;
    procedure FillCoreBoards(const APlatformId: string);
    procedure ShowPlatformFiles(const APlatformId, AVersion: string);
    procedure SelectBoardRow(const ARow: string);
    function  RowMatchesFilter(const ARow: string): Boolean;
    function  SelectedCoreRow: string;
    function  SelectedCoreId: string;
    procedure RunCoreCommand(const ACommand, ACoreId: string;
                             ARefresh: Boolean);
  public
    // editor.ini; настройки перечитываются перед каждой командой
    property SettingsFile: string read FSettingsFile write FSettingsFile;
    // Плата, выбранная кнопкой Select board
    property SelectedFqbn: string read FSelFqbn;
    property SelectedBoardName: string read FSelBoardName;
    property OnBoardSelected: TNotifyEvent read FOnBoardSelected
                                           write FOnBoardSelected;
  end;

implementation

{$R *.dfm}

const
  NotInstalledText = 'Not installed';

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана - та же беда, что у главного окна (см.
// TForm1.WMUpdateUIState). Сообщение дальше не передаём.
procedure TDlgArdBoards.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgArdBoards.FormCreate(Sender: TObject);
begin
  FCoreRows := TStringList.Create;
  FBoardRows := TStringList.Create;
  btnStop.Enabled := False;
  pcMain.ActivePage := tsCores;
end;

procedure TDlgArdBoards.FormDestroy(Sender: TObject);
begin
  FCoreRows.Free;
  FBoardRows.Free;
end;

// Первый показ - списки читаются сразу (как BoardMngFormOnShow в
// RQdebugger, только не из старых файлов, а командами)
procedure TDlgArdBoards.FormShow(Sender: TObject);
begin
  if not LoadSettings then
    Exit;
  memUrls.Lines.Text := StringReplace(FSettings.AdditionalUrls, ',', #13#10,
                                      [rfReplaceAll]);
  // Окно сначала появится на экране, потом пойдут команды
  if not FLoaded then
    PostMessage(Handle, WM_USER + 1, 0, 0);
end;

procedure TDlgArdBoards.WMRefreshLists(var Message: TMessage);
begin
  if not FLoaded then
    RefreshLists;
end;

// Окно закрывается во время команды - сначала её остановить
procedure TDlgArdBoards.FormCloseQuery(Sender: TObject;
                                       var CanClose: Boolean);
begin
  if FBusy then
  begin
    FStop := True;
    SetStatus('Останавливаю команду arduino-cli...');
    CanClose := False;
  end;
end;

// ---------------------------------------------------------------------------
//  Запуск arduino-cli
// ---------------------------------------------------------------------------

function TDlgArdBoards.LoadSettings: Boolean;
var
  ErrText: string;
begin
  FSettings := ArdLoadSettings(FSettingsFile);
  Result := ArdCheckCli(FSettings, ErrText);
  if not Result then
  begin
    SetStatus(ErrText);
    LogAdd(ErrText);
  end;
end;

// Additional Boards Manager URLs для команд core и board
function TDlgArdBoards.UrlArgs: string;
var
  Urls: string;
begin
  // Настройки - заново: адреса могли поменяться на вкладке
  // 3rd-party-boards list или в editor.ini
  Urls := ArdHttpUrls(ArdLoadSettings(FSettingsFile).AdditionalUrls);
  if Urls <> '' then
    Result := ' --additional-urls ' + Urls
  else
    Result := '';
end;

function TDlgArdBoards.RunCli(const AArgs: string;
                              AOutput: TStrings): Integer;
begin
  Result := ArdRunNoStart;
  if FBusy then
  begin
    SetStatus('Уже идёт команда arduino-cli - дождитесь её или нажмите Stop');
    Exit;
  end;
  if not LoadSettings then
  begin
    ShowMessage(lblStatus.Caption);
    Exit;
  end;

  FBusy := True;
  FStop := False;
  btnStop.Enabled := True;
  Screen.Cursor := crAppStart;
  try
    LogAdd('> arduino-cli ' + AArgs);
    SetStatus('arduino-cli ' + AArgs);
    FProgressIdx := -1;
    Result := ArdRunCli(FSettings, AArgs, AOutput, CliLine, CliIdle,
                        CliProgress);
  finally
    Screen.Cursor := crDefault;
    btnStop.Enabled := False;
    FBusy := False;
  end;

  if Result = ArdRunCancelled then
  begin
    LogAdd('Прервано');
    SetStatus('Прервано: arduino-cli ' + AArgs);
  end
  else if Result = ArdRunNoStart then
    SetStatus('Не удалось запустить arduino-cli')
  else if Result <> 0 then
  begin
    LogAdd('Код завершения ' + IntToStr(Result));
    SetStatus('Ошибка (код ' + IntToStr(Result) + '): arduino-cli ' + AArgs +
              ' - подробности на вкладке Log');
  end
  else
    SetStatus('Готово: arduino-cli ' + AArgs);
end;

procedure TDlgArdBoards.CliLine(const ALine: string);
begin
  ArdLogLine(memLog.Lines, FProgressIdx, ALine);
  if Trim(ALine) <> '' then
    lblStatus.Caption := ALine;
end;

// Ход загрузки: одна строка в Log, обновляется на месте, и строка статуса
procedure TDlgArdBoards.CliProgress(const AText: string);
begin
  ArdLogProgress(memLog.Lines, FProgressIdx, AText);
  SetStatus(AText);
end;

procedure TDlgArdBoards.CliIdle(var ACancel: Boolean);
begin
  Application.ProcessMessages;
  ACancel := FStop;
end;

procedure TDlgArdBoards.SetStatus(const AText: string);
begin
  lblStatus.Caption := AText;
  lblStatus.Update;
end;

procedure TDlgArdBoards.LogAdd(const AText: string);
begin
  memLog.Lines.Add(AText);
end;

procedure TDlgArdBoards.btnStopClick(Sender: TObject);
begin
  FStop := True;
end;

// ---------------------------------------------------------------------------
//  Списки
// ---------------------------------------------------------------------------

// Refresh Board List: установленные платформы (core list), все платформы
// индекса (core search) и все платы (board search)
procedure TDlgArdBoards.RefreshLists;
var
  Output, Installed, Known: TStringList;
  RowIdx, KnownIdx: Integer;
  CoreId: string;
  Found: Boolean;
begin
  Output := TStringList.Create;
  Installed := TStringList.Create;
  Known := TStringList.Create;
  try
    // Установленные: ID, Installed, Latest, Name
    if RunCli('core list' + UrlArgs, Output) <> 0 then
      Exit;
    if not ArdParseTable(Output, ['ID', 'Installed', 'Latest', 'Name'],
                         Installed) then
      LogAdd('core list: таблица не найдена в выводе (установленных ' +
             'платформ нет или формат вывода другой)');

    // Все из индекса: ID, Version, Name
    Output.Clear;
    if RunCli('core search' + UrlArgs, Output) <> 0 then
      Exit;
    if not ArdParseTable(Output, ['ID', 'Version', 'Name'], Known) then
      LogAdd('core search: таблица не найдена в выводе');

    // Строки окна: установленные, затем недостающие из индекса
    FCoreRows.Clear;
    for RowIdx := 0 to Installed.Count - 1 do
      FCoreRows.Add(ArdRowField(Installed[RowIdx], 3) + #9 +
                    ArdRowField(Installed[RowIdx], 1) + #9 +
                    ArdRowField(Installed[RowIdx], 2) + #9 +
                    ArdRowField(Installed[RowIdx], 0));
    for KnownIdx := 0 to Known.Count - 1 do
    begin
      CoreId := ArdRowField(Known[KnownIdx], 0);
      Found := False;
      for RowIdx := 0 to Installed.Count - 1 do
        if CompareText(ArdRowField(Installed[RowIdx], 0), CoreId) = 0 then
        begin
          Found := True;
          Break;
        end;
      if not Found then
        FCoreRows.Add(ArdRowField(Known[KnownIdx], 2) + #9 + '' + #9 +
                      ArdRowField(Known[KnownIdx], 1) + #9 + CoreId);
    end;

    // Все платы: Board Name, FQBN, Platform ID
    Output.Clear;
    if RunCli('board search' + UrlArgs, Output) <> 0 then
      Exit;
    if not ArdParseTable(Output, ['Board Name', 'FQBN', 'Platform ID'],
                         FBoardRows) then
      LogAdd('board search: таблица не найдена в выводе');

    FLoaded := True;
    FillCores;
    FillBoards;
    SetStatus(Format('Платформ: %d (установлено %d), плат: %d',
                     [FCoreRows.Count, Installed.Count, FBoardRows.Count]));
  finally
    Known.Free;
    Installed.Free;
    Output.Free;
  end;
end;

// Строка подходит под фильтр: галка Filter снята или текст фильтра есть
// в одном из полей
function TDlgArdBoards.RowMatchesFilter(const ARow: string): Boolean;
var
  Needle: string;
begin
  Needle := LowerCase(Trim(edFilter.Text));
  if not chkFilter.Checked or (Needle = '') then
    Result := True
  else
    Result := Pos(Needle, LowerCase(ARow)) > 0;
end;

procedure TDlgArdBoards.FillCores;
var
  RowIdx, Shown: Integer;
  Row, InstalledVer: string;
  Item: TListItem;
begin
  lvCores.Items.BeginUpdate;
  try
    lvCores.Items.Clear;
    Shown := 0;
    for RowIdx := 0 to FCoreRows.Count - 1 do
    begin
      Row := FCoreRows[RowIdx];
      InstalledVer := ArdRowField(Row, 1);
      if FCoresInstalledOnly and (InstalledVer = '') then
        Continue;
      if not RowMatchesFilter(Row) then
        Continue;
      Inc(Shown);
      Item := lvCores.Items.Add;
      Item.Caption := IntToStr(Shown);
      Item.SubItems.Add(ArdRowField(Row, 0));
      if InstalledVer = '' then
        Item.SubItems.Add(NotInstalledText)
      else
        Item.SubItems.Add(InstalledVer);
      Item.SubItems.Add(ArdRowField(Row, 2));
      Item.SubItems.Add(ArdRowField(Row, 3));
      Item.Data := Pointer(RowIdx);
    end;
  finally
    lvCores.Items.EndUpdate;
  end;
  if FCoresInstalledOnly then
    tsCores.Caption := 'Core list (installed)'
  else
    tsCores.Caption := 'Core list';
end;

procedure TDlgArdBoards.FillBoards;
var
  RowIdx, Shown: Integer;
  Row, Fqbn: string;
  Item: TListItem;
begin
  lvBoards.Items.BeginUpdate;
  try
    lvBoards.Items.Clear;
    Shown := 0;
    for RowIdx := 0 to FBoardRows.Count - 1 do
    begin
      Row := FBoardRows[RowIdx];
      Fqbn := ArdRowField(Row, 1);
      if FBoardsInstalledOnly and (Fqbn = '') then
        Continue;
      if not RowMatchesFilter(Row) then
        Continue;
      Inc(Shown);
      Item := lvBoards.Items.Add;
      Item.Caption := IntToStr(Shown);
      Item.SubItems.Add(ArdRowField(Row, 0));
      if Fqbn = '' then
        Item.SubItems.Add(NotInstalledText)
      else
        Item.SubItems.Add(Fqbn);
      Item.SubItems.Add(ArdRowField(Row, 2));
      Item.Data := Pointer(RowIdx);
    end;
  finally
    lvBoards.Items.EndUpdate;
  end;
  if FBoardsInstalledOnly then
    tsBoards.Caption := 'Board list (installed)'
  else
    tsBoards.Caption := 'Board list';
end;

// Платы платформы - справа от списка платформ (InstCoreGridSelectCell)
procedure TDlgArdBoards.FillCoreBoards(const APlatformId: string);
var
  RowIdx, Shown: Integer;
  Row, Fqbn: string;
  Item: TListItem;
begin
  lvCoreBoards.Items.BeginUpdate;
  try
    lvCoreBoards.Items.Clear;
    Shown := 0;
    for RowIdx := 0 to FBoardRows.Count - 1 do
    begin
      Row := FBoardRows[RowIdx];
      if CompareText(ArdRowField(Row, 2), APlatformId) <> 0 then
        Continue;
      Inc(Shown);
      Fqbn := ArdRowField(Row, 1);
      Item := lvCoreBoards.Items.Add;
      Item.Caption := IntToStr(Shown);
      Item.SubItems.Add(ArdRowField(Row, 0));
      if Fqbn = '' then
        Item.SubItems.Add(NotInstalledText)
      else
        Item.SubItems.Add(Fqbn);
      Item.SubItems.Add(ArdRowField(Row, 2));
      Item.Data := Pointer(RowIdx);
    end;
  finally
    lvCoreBoards.Items.EndUpdate;
  end;
end;

// boards.txt, platform.txt, programmers.txt установленной платформы
procedure TDlgArdBoards.ShowPlatformFiles(const APlatformId,
                                          AVersion: string);
var
  Folder: string;

  procedure LoadInto(AMemo: TUiMemo; const AName: string);
  begin
    if (Folder <> '') and FileExists(Folder + AName) then
      AMemo.Lines.LoadFromFile(Folder + AName)
    else if Folder <> '' then
      AMemo.Lines.Text := 'Нет файла ' + Folder + AName
    else
      AMemo.Lines.Clear;
  end;

begin
  Folder := '';
  if AVersion <> '' then
    Folder := ArdPackagePath(FSettings, APlatformId, AVersion);
  LoadInto(memBoardsTxt, 'boards.txt');
  LoadInto(memPlatf, 'platform.txt');
  LoadInto(memProgr, 'programmers.txt');
  if AVersion = '' then
    memBoardsTxt.Lines.Text := 'Платформа ' + APlatformId +
                               ' не установлена'
  else if Folder = '' then
    memBoardsTxt.Lines.Text := 'Папка платформы ' + APlatformId + ' ' +
      AVersion + ' не найдена ни в Cli data path, ни в Arduino15 path ' +
      '(IDE Options - Compilers - Arduino)';
  lblBoardsTxt.Hint := Folder;
end;

function TDlgArdBoards.SelectedCoreRow: string;
begin
  Result := '';
  if (lvCores.Selected <> nil) and
     (Integer(lvCores.Selected.Data) < FCoreRows.Count) then
    Result := FCoreRows[Integer(lvCores.Selected.Data)];
end;

// Платформа для команд: выбранная в списке; нет выбранной - текст поля
// фильтра (так было в RQdebugger: InstallSelCore брал FilterEdit)
function TDlgArdBoards.SelectedCoreId: string;
var
  Row: string;
begin
  Row := SelectedCoreRow;
  if Row <> '' then
    Result := ArdRowField(Row, 3)
  else
    Result := Trim(edFilter.Text);
end;

procedure TDlgArdBoards.lvCoresSelectItem(Sender: TObject; Item: TListItem;
                                          Selected: Boolean);
var
  Row, CoreId: string;
begin
  if not Selected or (Item = nil) then
    Exit;
  Row := FCoreRows[Integer(Item.Data)];
  CoreId := ArdRowField(Row, 3);
  FillCoreBoards(CoreId);
  ShowPlatformFiles(CoreId, ArdRowField(Row, 1));
  // Без галки фильтра поле фильтра - выбранная платформа (RQdebugger)
  if not chkFilter.Checked then
    edFilter.Text := CoreId;
end;

// Плата выбрана в любом из списков плат
procedure TDlgArdBoards.lvBoardSelectItem(Sender: TObject; Item: TListItem;
                                          Selected: Boolean);
begin
  if not Selected or (Item = nil) then
    Exit;
  SelectBoardRow(FBoardRows[Integer(Item.Data)]);
end;

procedure TDlgArdBoards.SelectBoardRow(const ARow: string);
var
  FoundPos: Integer;
begin
  FSelBoardName := ArdRowField(ARow, 0);
  FSelFqbn := ArdRowField(ARow, 1);
  FSelCore := ArdRowField(ARow, 2);
  edSelBoard.Text := FSelFqbn + '/' + FSelBoardName + '/' + FSelCore;

  // Плата в boards.txt: по имени (name=...), как в RQdebugger
  FoundPos := Pos(FSelBoardName, memBoardsTxt.Lines.Text);
  if (FSelBoardName <> '') and (FoundPos > 0) then
  begin
    memBoardsTxt.SelStart := FoundPos - 1;
    memBoardsTxt.SelLength := Length(FSelBoardName);
    SendMessage(memBoardsTxt.Handle, EM_SCROLLCARET, 0, 0);
  end;
end;

procedure TDlgArdBoards.btnSelectBoardClick(Sender: TObject);
begin
  if FSelBoardName = '' then
  begin
    ShowMessage('Выберите плату в списке плат');
    Exit;
  end;
  if FSelFqbn = '' then
  begin
    ShowMessage('Платформа ' + FSelCore + ' не установлена: у платы ' +
                FSelBoardName + ' нет FQBN. Установите платформу (Install ' +
                'core).');
    Exit;
  end;
  SetStatus('Выбрана плата: ' + FSelBoardName + ' (' + FSelFqbn + ')');
  if Assigned(FOnBoardSelected) then
    FOnBoardSelected(Self);
end;

// ---------------------------------------------------------------------------
//  Вид списков
// ---------------------------------------------------------------------------

procedure TDlgArdBoards.btnAllCoresClick(Sender: TObject);
begin
  FCoresInstalledOnly := False;
  FillCores;
  pcMain.ActivePage := tsCores;
end;

procedure TDlgArdBoards.btnInstCoresClick(Sender: TObject);
begin
  FCoresInstalledOnly := True;
  FillCores;
  pcMain.ActivePage := tsCores;
end;

procedure TDlgArdBoards.btnAllBoardsClick(Sender: TObject);
begin
  FBoardsInstalledOnly := False;
  FillBoards;
  pcMain.ActivePage := tsBoards;
end;

procedure TDlgArdBoards.btnInstBoardsClick(Sender: TObject);
begin
  FBoardsInstalledOnly := True;
  FillBoards;
  pcMain.ActivePage := tsBoards;
end;

procedure TDlgArdBoards.btnRefreshClick(Sender: TObject);
begin
  RefreshLists;
end;

procedure TDlgArdBoards.edFilterChange(Sender: TObject);
begin
  if chkFilter.Checked then
  begin
    FillCores;
    FillBoards;
  end;
end;

procedure TDlgArdBoards.chkFilterClick(Sender: TObject);
begin
  FillCores;
  FillBoards;
end;

// ---------------------------------------------------------------------------
//  Операции с платформами
// ---------------------------------------------------------------------------

procedure TDlgArdBoards.btnCoreOpsClick(Sender: TObject);
var
  ScreenPt: TPoint;
begin
  ScreenPt := btnCoreOps.ClientToScreen(Point(0, btnCoreOps.Height));
  pmCoreOps.Popup(ScreenPt.X, ScreenPt.Y);
end;

// Команда core <ACommand> <ACoreId>, вывод - на вкладку Log; после
// установки и удаления списки читаются заново
procedure TDlgArdBoards.RunCoreCommand(const ACommand, ACoreId: string;
                                       ARefresh: Boolean);
var
  Args: string;
  ExitCode: Integer;
begin
  Args := 'core ' + ACommand;
  if ACoreId <> '' then
    Args := Args + ' ' + ArdQuote(ACoreId);
  pcMain.ActivePage := tsLog;
  ExitCode := RunCli(Args + UrlArgs, nil);
  if (ExitCode = 0) and ARefresh then
    RefreshLists;
end;

procedure TDlgArdBoards.btnInstallCoreClick(Sender: TObject);
begin
  miCoreInstallClick(Sender);
end;

procedure TDlgArdBoards.miCoreInstallClick(Sender: TObject);
var
  CoreId: string;
begin
  CoreId := SelectedCoreId;
  if CoreId = '' then
  begin
    ShowMessage('Выберите платформу в списке Core list');
    Exit;
  end;
  RunCoreCommand('install', CoreId, True);
end;

procedure TDlgArdBoards.miCoreDownloadClick(Sender: TObject);
var
  CoreId: string;
begin
  CoreId := SelectedCoreId;
  if CoreId = '' then
  begin
    ShowMessage('Выберите платформу в списке Core list');
    Exit;
  end;
  RunCoreCommand('download', CoreId, False);
end;

procedure TDlgArdBoards.miCoreUninstallClick(Sender: TObject);
var
  CoreId: string;
begin
  CoreId := SelectedCoreId;
  if CoreId = '' then
  begin
    ShowMessage('Выберите платформу в списке Core list');
    Exit;
  end;
  if MessageDlg('Удалить платформу ' + CoreId + '?', mtConfirmation,
                [mbYes, mbNo], 0) <> mrYes then
    Exit;
  RunCoreCommand('uninstall', CoreId, True);
end;

// Поиск по словам из поля фильтра; результат - на вкладке Log
procedure TDlgArdBoards.miCoreSearchClick(Sender: TObject);
begin
  RunCoreCommand('search', Trim(edFilter.Text), False);
end;

procedure TDlgArdBoards.miCoreUpdateIndexClick(Sender: TObject);
begin
  RunCoreCommand('update-index', '', True);
end;

// Выбрана установленная платформа - обновляется она; иначе, после
// вопроса, - все установленные
procedure TDlgArdBoards.miCoreUpgradeClick(Sender: TObject);
var
  Row: string;
begin
  Row := SelectedCoreRow;
  if (Row <> '') and (ArdRowField(Row, 1) <> '') then
    RunCoreCommand('upgrade', ArdRowField(Row, 3), True)
  else if MessageDlg('Платформа не выбрана. Обновить все установленные ' +
                     'платформы?', mtConfirmation, [mbYes, mbNo], 0) = mrYes
  then
    RunCoreCommand('upgrade', '', True);
end;

// ---------------------------------------------------------------------------
//  Additional Boards Manager URLs
// ---------------------------------------------------------------------------

// В editor.ini - все непустые строки через запятую (как вкладка Arduino в
// IDE Options); в arduino-cli уходят только адреса http(s) (UrlArgs), о
// строках другого вида (папках) - в строке состояния
procedure TDlgArdBoards.btnUrlsSaveClick(Sender: TObject);
var
  Joined, LineText: string;
  LineIdx, Skipped: Integer;
begin
  if FSettingsFile = '' then
    Exit;
  FSettings := ArdLoadSettings(FSettingsFile);
  Joined := '';
  Skipped := 0;
  for LineIdx := 0 to memUrls.Lines.Count - 1 do
  begin
    LineText := Trim(memUrls.Lines[LineIdx]);
    if LineText = '' then
      Continue;
    if ArdHttpUrls(LineText) = '' then
      Inc(Skipped);
    if Joined <> '' then
      Joined := Joined + ',';
    Joined := Joined + LineText;
  end;
  ArdSaveSetting(FSettingsFile, FSettings.Section, 'AdditionalUrls', Joined);
  FSettings.AdditionalUrls := Joined;
  if Skipped > 0 then
    SetStatus(Format('Сохранено. Строк не http(s) - в arduino-cli не ' +
                     'передаются: %d', [Skipped]))
  else
    SetStatus('Сохранено');
end;

procedure TDlgArdBoards.btnUrlsIndexClick(Sender: TObject);
begin
  btnUrlsSaveClick(Sender);
  RunCoreCommand('update-index', '', True);
end;

end.
