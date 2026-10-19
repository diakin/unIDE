unit DlgArdCli;

// Arduino CLI Help: команды arduino-cli и их справка. Перенос окна
// ArdCliHelpForm из RQdebugger853-8.bas.
//
// Слева - команды верхнего уровня, рядом - подкоманды выбранной, под ними -
// список флагов. Щелчок по команде или подкоманде показывает справа её
// справку (--help) и ставит её в строку команды внизу. Run выполняет
// строку команды, вывод - справа.
//
// Отличия от RQdebugger:
// - список команд и флагов берётся из справки самой arduino-cli (--help);
//   если не вышло - список RQdebugger;
// - в строке команды - только аргументы, без пути к exe и перенаправления
//   в файл: полная строка запуска видна внизу окна;
// - выбор флага в списке дописывает его в строку команды.
//
// Окно описано в DlgArdCli.dfm. Создаёт и показывает его TForm1
// (ArdCliShow, Unit1); здесь - вся работа окна. Форма создаётся по месту,
// в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiEdit, TUiMemo, TUiListBox, TUiComboBox
  ArduinoCli,
  Dialogs,       // TMsgDlgType, mbYes ... для MessageDlg
  // Окна сообщений по теме - последним, поверх Dialogs
  UiDialogs;

type
  TDlgArdCli = class(TForm)
    pnlBottom: TPanel;
    edCmdLine: TUiEdit;
    btnRun: TUiButton;
    btnStop: TUiButton;
    lblStatus: TLabel;
    pnlHelp: TPanel;
    memHelp: TUiMemo;
    splHelp: TSplitter;
    pnlLeft: TPanel;
    pnlFlags: TPanel;
    cbFlags: TUiComboBox;
    pnlCmds: TPanel;
    lblCmds: TLabel;
    lbCmds: TUiListBox;
    pnlSubs: TPanel;
    lblSubs: TLabel;
    lbSubs: TUiListBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure lbCmdsClick(Sender: TObject);
    procedure lbSubsClick(Sender: TObject);
    procedure cbFlagsChange(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure edCmdLineKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FSettingsFile: string;
    FSettings: TArdSettings;
    FCmdNames: TStringList;    // имена команд lbCmds (без описания)
    FSubNames: TStringList;    // имена подкоманд lbSubs
    FCurCmd: string;           // выбранная команда верхнего уровня
    FLoaded: Boolean;
    FBusy: Boolean;
    FStop: Boolean;
    FProgressIdx: Integer;     // строка прогресса загрузки, -1 - нет
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
    // Списки после показа окна (FormShow его посылает)
    procedure WMLoadLists(var Message: TMessage); message WM_USER + 1;
    procedure LoadLists;
    procedure FillDefaultLists;
    function  RunCli(const AArgs: string; AOutput: TStrings): Integer;
    procedure CliLine(const ALine: string);
    procedure CliProgress(const AText: string);
    procedure CliIdle(var ACancel: Boolean);
    procedure ShowHelpOf(const AArgs: string; AFillSubs: Boolean);
  public
    property SettingsFile: string read FSettingsFile write FSettingsFile;
  end;

implementation

{$R *.dfm}

const
  // Команды и флаги arduino-cli 0.18 - из RQdebugger (ArdCliHelpFormShow);
  // нужны, только если справку самой программы получить не удалось
  DefaultCommands: array[0..16] of string = (
    'board', 'burn-bootloader', 'cache', 'compile', 'completion', 'config',
    'core', 'daemon', 'debug', 'help', 'lib', 'outdated', 'sketch', 'update',
    'upgrade', 'upload', 'version');
  DefaultFlags: array[0..7] of string = (
    '--additional-urls strings   Comma (space)-separated list of ' +
      'additional URLs for the Boards Manager',
    '--config-file string        The custom config file (if not ' +
      'specified the default will be used)',
    '--format string             The output format, can be {text|json}. ' +
      '(default "text")',
    '-h, --help                  help for arduino-cli',
    '--log-file string           Path to the file where logs will be written',
    '--log-format string         The output format for the logs, can be ' +
      '{text|json}',
    '--log-level string          Messages with this level and above will ' +
      'be logged. Valid levels are: trace, debug, info, warn, error, ' +
      'fatal, panic',
    '-v, --verbose               Print the logs on the standard output');

procedure TDlgArdCli.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgArdCli.FormCreate(Sender: TObject);
begin
  FCmdNames := TStringList.Create;
  FSubNames := TStringList.Create;
  btnStop.Enabled := False;
end;

procedure TDlgArdCli.FormDestroy(Sender: TObject);
begin
  FCmdNames.Free;
  FSubNames.Free;
end;

procedure TDlgArdCli.FormShow(Sender: TObject);
begin
  if not FLoaded then
    PostMessage(Handle, WM_USER + 1, 0, 0);
end;

procedure TDlgArdCli.WMLoadLists(var Message: TMessage);
begin
  if not FLoaded then
    LoadLists;
end;

procedure TDlgArdCli.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FBusy then
  begin
    FStop := True;
    lblStatus.Caption := 'Останавливаю команду arduino-cli...';
    CanClose := False;
  end;
end;

// ---------------------------------------------------------------------------
//  Списки команд и флагов
// ---------------------------------------------------------------------------

procedure TDlgArdCli.FillDefaultLists;
var
  ItemIdx: Integer;
begin
  lbCmds.Items.Clear;
  FCmdNames.Clear;
  for ItemIdx := Low(DefaultCommands) to High(DefaultCommands) do
  begin
    lbCmds.Items.Add(DefaultCommands[ItemIdx]);
    FCmdNames.Add(DefaultCommands[ItemIdx]);
  end;
  cbFlags.Items.Clear;
  for ItemIdx := Low(DefaultFlags) to High(DefaultFlags) do
    cbFlags.Items.Add(DefaultFlags[ItemIdx]);
end;

// Команды и общие флаги - из справки arduino-cli --help
procedure TDlgArdCli.LoadLists;
var
  Output, Rows: TStringList;
  RowIdx: Integer;
begin
  Output := TStringList.Create;
  Rows := TStringList.Create;
  try
    if RunCli('--help', Output) = 0 then
    begin
      memHelp.Lines.Assign(Output);
      FLoaded := True;
    end;
    if ArdHelpCommands(Output, Rows) > 0 then
    begin
      lbCmds.Items.Clear;
      FCmdNames.Clear;
      for RowIdx := 0 to Rows.Count - 1 do
      begin
        FCmdNames.Add(ArdRowField(Rows[RowIdx], 0));
        lbCmds.Items.Add(ArdRowField(Rows[RowIdx], 0));
      end;
      ArdHelpFlags(Output, Rows);
      cbFlags.Items.Assign(Rows);
    end
    else
      FillDefaultLists;
  finally
    Rows.Free;
    Output.Free;
  end;
end;

// Справка по AArgs (--help) - справа; AFillSubs - её подкоманды в список
// подкоманд
procedure TDlgArdCli.ShowHelpOf(const AArgs: string; AFillSubs: Boolean);
var
  Output, Rows: TStringList;
  RowIdx: Integer;
begin
  Output := TStringList.Create;
  Rows := TStringList.Create;
  try
    RunCli(AArgs + ' --help', Output);
    memHelp.Lines.Assign(Output);
    if AFillSubs then
    begin
      lbSubs.Items.Clear;
      FSubNames.Clear;
      ArdHelpCommands(Output, Rows);
      for RowIdx := 0 to Rows.Count - 1 do
      begin
        FSubNames.Add(ArdRowField(Rows[RowIdx], 0));
        lbSubs.Items.Add(Format('%-12s %s', [ArdRowField(Rows[RowIdx], 0),
                                             ArdRowField(Rows[RowIdx], 1)]));
      end;
    end;
  finally
    Rows.Free;
    Output.Free;
  end;
end;

procedure TDlgArdCli.lbCmdsClick(Sender: TObject);
begin
  if (lbCmds.ItemIndex < 0) or (lbCmds.ItemIndex >= FCmdNames.Count) then
    Exit;
  FCurCmd := FCmdNames[lbCmds.ItemIndex];
  edCmdLine.Text := FCurCmd;
  ShowHelpOf(FCurCmd, True);
end;

procedure TDlgArdCli.lbSubsClick(Sender: TObject);
var
  Args: string;
begin
  if (lbSubs.ItemIndex < 0) or (lbSubs.ItemIndex >= FSubNames.Count) then
    Exit;
  Args := FCurCmd + ' ' + FSubNames[lbSubs.ItemIndex];
  edCmdLine.Text := Args;
  ShowHelpOf(Args, False);
end;

// Флаг из списка - в конец строки команды: длинное имя (--verbose), а
// если его нет - короткое
procedure TDlgArdCli.cbFlagsChange(Sender: TObject);
var
  FlagLine, FlagName, Token: string;
  SpacePos: Integer;
begin
  if cbFlags.ItemIndex < 0 then
    Exit;
  FlagLine := Trim(cbFlags.Items[cbFlags.ItemIndex]);
  FlagName := '';
  while FlagLine <> '' do
  begin
    SpacePos := Pos(' ', FlagLine);
    if SpacePos = 0 then
      SpacePos := Length(FlagLine) + 1;
    Token := Copy(FlagLine, 1, SpacePos - 1);
    FlagLine := TrimLeft(Copy(FlagLine, SpacePos + 1, Length(FlagLine)));
    if (Token <> '') and (Token[Length(Token)] = ',') then
      SetLength(Token, Length(Token) - 1);
    if Copy(Token, 1, 2) = '--' then
    begin
      FlagName := Token;
      Break;
    end;
    if (Copy(Token, 1, 1) = '-') and (FlagName = '') then
      FlagName := Token
    else
      Break;
  end;
  if FlagName <> '' then
  begin
    edCmdLine.Text := TrimRight(edCmdLine.Text) + ' ' + FlagName + ' ';
    edCmdLine.SetFocus;
    edCmdLine.SelStart := Length(edCmdLine.Text);
  end;
end;

// ---------------------------------------------------------------------------
//  Запуск
// ---------------------------------------------------------------------------

function TDlgArdCli.RunCli(const AArgs: string; AOutput: TStrings): Integer;
var
  ErrText: string;
begin
  Result := ArdRunNoStart;
  if FBusy then
  begin
    lblStatus.Caption := 'Уже идёт команда arduino-cli - дождитесь её ' +
                         'или нажмите Stop';
    Exit;
  end;
  FSettings := ArdLoadSettings(FSettingsFile);
  if not ArdCheckCli(FSettings, ErrText) then
  begin
    lblStatus.Caption := ErrText;
    memHelp.Lines.Text := ErrText;
    Exit;
  end;

  FBusy := True;
  FStop := False;
  btnStop.Enabled := True;
  btnRun.Enabled := False;
  Screen.Cursor := crAppStart;
  lblStatus.Caption := ArdCommandLine(FSettings, AArgs);
  lblStatus.Update;
  try
    Result := ArdRunCli(FSettings, AArgs, AOutput, nil, CliIdle);
  finally
    Screen.Cursor := crDefault;
    btnRun.Enabled := True;
    btnStop.Enabled := False;
    FBusy := False;
  end;
  if Result = ArdRunCancelled then
    lblStatus.Caption := 'Прервано: ' + lblStatus.Caption
  else if Result > 0 then
    lblStatus.Caption := 'Код завершения ' + IntToStr(Result) + ': ' +
                         lblStatus.Caption;
end;

procedure TDlgArdCli.CliLine(const ALine: string);
begin
  ArdLogLine(memHelp.Lines, FProgressIdx, ALine);
end;

// Ход загрузки: одна строка, обновляется на месте
procedure TDlgArdCli.CliProgress(const AText: string);
begin
  ArdLogProgress(memHelp.Lines, FProgressIdx, AText);
end;

procedure TDlgArdCli.CliIdle(var ACancel: Boolean);
begin
  Application.ProcessMessages;
  ACancel := FStop;
end;

// Run: строка команды, вывод - справа по мере поступления
procedure TDlgArdCli.btnRunClick(Sender: TObject);
var
  Args: string;
  ErrText: string;
  ExitCode: Integer;
begin
  Args := Trim(edCmdLine.Text);
  if Args = '' then
  begin
    ShowMessage('Строка команды пустая');
    Exit;
  end;
  if FBusy then
    Exit;
  FSettings := ArdLoadSettings(FSettingsFile);
  if not ArdCheckCli(FSettings, ErrText) then
  begin
    ShowMessage(ErrText);
    Exit;
  end;

  memHelp.Lines.Clear;
  memHelp.Lines.Add('> arduino-cli ' + Args);
  FBusy := True;
  FStop := False;
  btnStop.Enabled := True;
  btnRun.Enabled := False;
  lblStatus.Caption := ArdCommandLine(FSettings, Args);
  try
    FProgressIdx := -1;
    ExitCode := ArdRunCli(FSettings, Args, nil, CliLine, CliIdle, CliProgress);
  finally
    btnRun.Enabled := True;
    btnStop.Enabled := False;
    FBusy := False;
  end;
  if ExitCode = ArdRunCancelled then
    memHelp.Lines.Add('Прервано')
  else if ExitCode <> 0 then
    memHelp.Lines.Add('Код завершения ' + IntToStr(ExitCode));
end;

procedure TDlgArdCli.btnStopClick(Sender: TObject);
begin
  FStop := True;
end;

// Enter в строке команды - Run
procedure TDlgArdCli.edCmdLineKeyDown(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    btnRunClick(Sender);
  end;
end;

end.
