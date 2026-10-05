unit DlgArdLibs;

// Library Manager: библиотеки Arduino из library_index.json и команды
// arduino-cli lib. Перенос окна LibMngForm из RQdebugger853-8.bas.
//
// Слева - список библиотек индекса (каждая версия - строка), справа -
// все поля выбранной, под ними - команда lib и кнопка Run ClibCmd, внизу -
// вывод команд. Сверху - файл индекса (дата, размер), Update Lib Idx и
// StopIt!, фильтры Type и Topic и строка поиска.
//
// Отличия от RQdebugger:
// - индекс разбирается как JSON сразу в память (без parsedJson.txt);
// - фильтры Type (поле types) и Topic (поле category) работают; поиск -
//   фильтр по части имени;
// - галка version: команде уходит имя@версия.
//
// Окно описано в DlgArdLibs.dfm. Создаёт и показывает его TForm1
// (ArdLibsShow, Unit1); здесь - вся работа окна. Форма создаётся по месту,
// в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiEdit, TUiMemo, TUiComboBox
  UiStdCtrls,    // TUiCheckBox
  UiComCtrls,    // TUiListView
  ArduinoCli,
  Dialogs,       // TMsgDlgType, mbYes ... для MessageDlg
  // Окна сообщений по теме - последним, поверх Dialogs
  UiDialogs;

type
  TDlgArdLibs = class(TForm)
    pnlJson: TPanel;
    lblJson: TLabel;
    btnUpdateIdx: TUiButton;
    btnStop: TUiButton;
    pnlFilter: TPanel;
    lblType: TLabel;
    cbType: TUiComboBox;
    lblTopic: TLabel;
    cbTopic: TUiComboBox;
    lblSearch: TLabel;
    edSearch: TUiEdit;
    lblCount: TLabel;
    lvLibs: TUiListView;
    splLibs: TSplitter;
    splLog: TSplitter;
    memLog: TUiMemo;
    pnlRight: TPanel;
    memDetails: TUiMemo;
    pnlCmd: TPanel;
    cbLibCmd: TUiComboBox;
    pnlCmdArgs: TPanel;
    lblLibName: TLabel;
    chkVersion: TUiCheckBox;
    btnRunCmd: TUiButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure lvLibsData(Sender: TObject; Item: TListItem);
    procedure lvLibsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure FilterChange(Sender: TObject);
    procedure btnUpdateIdxClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnRunCmdClick(Sender: TObject);
  private
    FSettingsFile: string;
    FSettings: TArdSettings;
    FIndex: TArdLibIndex;
    FLowNames: array of string;  // имена строчными - для поиска
    FView: array of Integer;     // строки списка -> записи индекса
    FViewCount: Integer;
    FSelIdx: Integer;            // выбранная запись индекса, -1 - нет
    FLoaded: Boolean;
    FBusy: Boolean;
    FStop: Boolean;
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
    // Чтение индекса после показа окна (FormShow его посылает)
    procedure WMLoadIndex(var Message: TMessage); message WM_USER + 1;
    function  LoadSettings: Boolean;
    function  IndexFile: string;
    procedure LoadIndex;
    procedure UpdateJsonLabel;
    procedure ApplyFilter;
    function  RunCli(const AArgs: string): Integer;
    procedure CliLine(const ALine: string);
    procedure CliIdle(var ACancel: Boolean);
    procedure SetStatus(const AText: string);
  public
    property SettingsFile: string read FSettingsFile write FSettingsFile;
  end;

implementation

{$R *.dfm}

const
  // Команды lib (как LibCmdCombo в RQdebugger). Признак после имени:
  // N - нужно имя библиотеки, V - можно имя@версия, '-' - без имени
  LibCommands: array[0..8] of string = (
    'deps|NV|Check dependencies status for the specified library.',
    'download|NV|Downloads one or more libraries without installing them.',
    'examples|N|Shows the list of the examples for libraries.',
    'install|NV|Installs one or more specified libraries into the system.',
    'list|-|Shows a list of installed libraries.',
    'search|N|Searches for one or more libraries data.',
    'uninstall|N|Uninstalls one or more libraries.',
    'update-index|-|Updates the libraries index.',
    'upgrade|-|Upgrades installed libraries.');

  TypeItems: array[0..5] of string = (
    'All', 'Arduino', 'Partner', 'Recommended', 'Contributed', 'Retired');
  TopicItems: array[0..10] of string = (
    'All', 'Communication', 'Data Processing', 'Data Storage',
    'Device Control', 'Display', 'Other', 'Sensors', 'Signal Input/Output',
    'Timing', 'Uncategorized');

// Поле AIndex (от нуля) строки вида "a|b|c"
function BarField(const AText: string; AIndex: Integer): string;
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

procedure TDlgArdLibs.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgArdLibs.FormCreate(Sender: TObject);
var
  ItemIdx: Integer;
begin
  FIndex := TArdLibIndex.Create;
  FSelIdx := -1;
  btnStop.Enabled := False;

  cbType.Items.Clear;
  for ItemIdx := Low(TypeItems) to High(TypeItems) do
    cbType.Items.Add(TypeItems[ItemIdx]);
  cbType.ItemIndex := 0;
  cbTopic.Items.Clear;
  for ItemIdx := Low(TopicItems) to High(TopicItems) do
    cbTopic.Items.Add(TopicItems[ItemIdx]);
  cbTopic.ItemIndex := 0;

  cbLibCmd.Items.Clear;
  for ItemIdx := Low(LibCommands) to High(LibCommands) do
    cbLibCmd.Items.Add(Format('%-13s %s', [BarField(LibCommands[ItemIdx], 0),
                                           BarField(LibCommands[ItemIdx], 2)]));
  cbLibCmd.ItemIndex := 3;   // install
end;

procedure TDlgArdLibs.FormDestroy(Sender: TObject);
begin
  FIndex.Free;
end;

// Индекс читается при первом показе - после того, как окно появилось на
// экране (в RQdebugger - таймером после показа окна, timerJ)
procedure TDlgArdLibs.FormShow(Sender: TObject);
begin
  if FLoaded then
    Exit;
  FLoaded := True;
  PostMessage(Handle, WM_USER + 1, 0, 0);
end;

procedure TDlgArdLibs.WMLoadIndex(var Message: TMessage);
begin
  LoadIndex;
end;

procedure TDlgArdLibs.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FBusy then
  begin
    FStop := True;
    SetStatus('Останавливаю...');
    CanClose := False;
  end;
end;

function TDlgArdLibs.LoadSettings: Boolean;
var
  ErrText: string;
begin
  FSettings := ArdLoadSettings(FSettingsFile);
  Result := ArdCheckCli(FSettings, ErrText);
  if not Result then
    SetStatus(ErrText);
end;

// library_index.json - в папке данных arduino-cli (Cli data path); нет её -
// в папке Arduino IDE (Arduino15 path)
function TDlgArdLibs.IndexFile: string;
begin
  Result := '';
  if FSettings.CliDataPath <> '' then
    Result := FSettings.CliDataPath + 'library_index.json';
  if ((Result = '') or not FileExists(Result)) and
     (FSettings.Arduino15Path <> '') and
     FileExists(FSettings.Arduino15Path + 'library_index.json') then
    Result := FSettings.Arduino15Path + 'library_index.json';
end;

// Строка над списком: файл индекса, дата, размер (UpdateJsonLbl)
procedure TDlgArdLibs.UpdateJsonLabel;
var
  FileName: string;
  SearchRec: TSearchRec;
begin
  FileName := IndexFile;
  if FileName = '' then
  begin
    lblJson.Caption := 'Не задан Cli data path (IDE Options - Compilers - ' +
                       'Arduino)';
    Exit;
  end;
  if FindFirst(FileName, faAnyFile, SearchRec) = 0 then
  begin
    lblJson.Caption := FileName + '  ' +
      FormatDateTime('dd.mm.yy hh:nn', FileDateToDateTime(SearchRec.Time)) +
      '  ' + IntToStr(SearchRec.Size) + ' bytes';
    FindClose(SearchRec);
  end
  else
    lblJson.Caption := FileName + ' не найден - нажмите Update Lib Idx';
end;

procedure TDlgArdLibs.LoadIndex;
var
  ErrText, FileName: string;
  ItemIdx: Integer;
begin
  FSettings := ArdLoadSettings(FSettingsFile);
  UpdateJsonLabel;
  FileName := IndexFile;
  lvLibs.Items.Count := 0;
  FViewCount := 0;
  FSelIdx := -1;
  memDetails.Lines.Clear;
  if (FileName = '') or not FileExists(FileName) then
  begin
    FIndex.Clear;
    SetStatus(lblJson.Caption);
    Exit;
  end;

  FBusy := True;
  FStop := False;
  btnStop.Enabled := True;
  Screen.Cursor := crHourGlass;
  try
    SetStatus('Читаю ' + FileName + '...');
    if not FIndex.LoadFromFile(FileName, CliIdle, ErrText) then
    begin
      SetStatus(ErrText);
      memLog.Lines.Add(ErrText);
    end;
  finally
    Screen.Cursor := crDefault;
    btnStop.Enabled := False;
    FBusy := False;
  end;

  SetLength(FLowNames, FIndex.Count);
  for ItemIdx := 0 to FIndex.Count - 1 do
    FLowNames[ItemIdx] := LowerCase(FIndex[ItemIdx].Name);
  ApplyFilter;
end;

// Список по Type, Topic и строке поиска (часть имени, без регистра)
procedure TDlgArdLibs.ApplyFilter;
var
  ItemIdx: Integer;
  TypeText, TopicText, Needle: string;
  Lib: TArdLib;
begin
  TypeText := '';
  if cbType.ItemIndex > 0 then
    TypeText := LowerCase(cbType.Items[cbType.ItemIndex]);
  TopicText := '';
  if cbTopic.ItemIndex > 0 then
    TopicText := cbTopic.Items[cbTopic.ItemIndex];
  Needle := LowerCase(Trim(edSearch.Text));

  SetLength(FView, FIndex.Count);
  FViewCount := 0;
  for ItemIdx := 0 to FIndex.Count - 1 do
  begin
    if (Needle <> '') and (Pos(Needle, FLowNames[ItemIdx]) = 0) then
      Continue;
    if (TypeText <> '') or (TopicText <> '') then
    begin
      Lib := FIndex[ItemIdx];
      if (TypeText <> '') and (Pos(TypeText, LowerCase(Lib.Types)) = 0) then
        Continue;
      if (TopicText <> '') and (CompareText(Lib.Category, TopicText) <> 0)
      then
        Continue;
    end;
    FView[FViewCount] := ItemIdx;
    Inc(FViewCount);
  end;

  lvLibs.Items.Count := FViewCount;
  lvLibs.Invalidate;
  lblCount.Caption := Format('%d / %d', [FViewCount, FIndex.Count]);
end;

procedure TDlgArdLibs.FilterChange(Sender: TObject);
begin
  ApplyFilter;
end;

// Строки списка - по запросу (OwnerData): в индексе десятки тысяч версий
procedure TDlgArdLibs.lvLibsData(Sender: TObject; Item: TListItem);
var
  Lib: TArdLib;
begin
  if (Item.Index < 0) or (Item.Index >= FViewCount) then
    Exit;
  Lib := FIndex[FView[Item.Index]];
  Item.Caption := IntToStr(Item.Index + 1);
  Item.SubItems.Add(Lib.Name);
  Item.SubItems.Add(Lib.Version);
end;

procedure TDlgArdLibs.lvLibsSelectItem(Sender: TObject; Item: TListItem;
                                       Selected: Boolean);
var
  Lib: TArdLib;
begin
  if not Selected or (Item = nil) or (Item.Index >= FViewCount) then
    Exit;
  FSelIdx := FView[Item.Index];
  Lib := FIndex[FSelIdx];
  memDetails.Lines.Text := FIndex.Details(FSelIdx);
  memDetails.SelStart := 0;
  lblLibName.Caption := Lib.Name;
  chkVersion.Caption := 'version ' + Lib.Version;
end;

// ---------------------------------------------------------------------------
//  Команды arduino-cli lib
// ---------------------------------------------------------------------------

function TDlgArdLibs.RunCli(const AArgs: string): Integer;
begin
  Result := ArdRunNoStart;
  if FBusy then
  begin
    SetStatus('Уже идёт работа - дождитесь её или нажмите StopIt!');
    Exit;
  end;
  if not LoadSettings then
  begin
    ShowMessage(lblJson.Hint);
    Exit;
  end;

  FBusy := True;
  FStop := False;
  btnStop.Enabled := True;
  Screen.Cursor := crAppStart;
  try
    memLog.Lines.Add('> arduino-cli ' + AArgs);
    Result := ArdRunCli(FSettings, AArgs, nil, CliLine, CliIdle);
  finally
    Screen.Cursor := crDefault;
    btnStop.Enabled := False;
    FBusy := False;
  end;

  if Result = ArdRunCancelled then
    memLog.Lines.Add('Прервано')
  else if Result > 0 then
    memLog.Lines.Add('Код завершения ' + IntToStr(Result));
end;

procedure TDlgArdLibs.CliLine(const ALine: string);
begin
  memLog.Lines.Add(ALine);
end;

procedure TDlgArdLibs.CliIdle(var ACancel: Boolean);
begin
  Application.ProcessMessages;
  ACancel := FStop;
end;

// Строка состояния окна - подсказка строки файла индекса и сам лог
procedure TDlgArdLibs.SetStatus(const AText: string);
begin
  lblJson.Hint := AText;
  memLog.Lines.Add(AText);
end;

procedure TDlgArdLibs.btnStopClick(Sender: TObject);
begin
  FStop := True;
end;

// Update Lib Idx: lib update-index и чтение индекса заново
procedure TDlgArdLibs.btnUpdateIdxClick(Sender: TObject);
begin
  if RunCli('lib update-index') = 0 then
    LoadIndex
  else
    UpdateJsonLabel;
end;

// Run ClibCmd: команда из списка, имя - выбранной библиотеки
procedure TDlgArdLibs.btnRunCmdClick(Sender: TObject);
var
  CmdIdx: Integer;
  CmdName, CmdFlags, Args, LibArg: string;
  Lib: TArdLib;
begin
  CmdIdx := cbLibCmd.ItemIndex;
  if (CmdIdx < Low(LibCommands)) or (CmdIdx > High(LibCommands)) then
  begin
    ShowMessage('Выберите команду в списке');
    Exit;
  end;
  CmdName := BarField(LibCommands[CmdIdx], 0);
  CmdFlags := BarField(LibCommands[CmdIdx], 1);
  Args := 'lib ' + CmdName;

  if Pos('N', CmdFlags) > 0 then
  begin
    if FSelIdx < 0 then
    begin
      ShowMessage('Выберите библиотеку в списке');
      Exit;
    end;
    Lib := FIndex[FSelIdx];
    LibArg := Lib.Name;
    if chkVersion.Checked and (Pos('V', CmdFlags) > 0) then
      LibArg := LibArg + '@' + Lib.Version;
    Args := Args + ' "' + LibArg + '"';
  end;

  if (CmdName = 'uninstall') and
     (MessageDlg('Удалить библиотеку ' + Lib.Name + '?', mtConfirmation,
                 [mbYes, mbNo], 0) <> mrYes) then
    Exit;

  if (RunCli(Args) = 0) and (CmdName = 'update-index') then
    LoadIndex;
end;

end.
