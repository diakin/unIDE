unit DlgGitRepoSettings;

// ---------------------------------------------------------------------------
//  Окно Repository Settings (меню Repository - Repository Settings...,
//  кнопка .gitignore... панели Git, Unit1), как в GitHub Desktop. Вкладки:
//
//    Remote        - адрес remote origin;
//    Ignored files - текст .gitignore в корне репозитория;
//    Git config    - имя и почта автора коммитов: общие (git config
//                    --global) или только для этого репозитория (--local).
//
//  Окно строится в коде (CreateDlg), .dfm нет. Само окно git не вызывает и
//  файлов не пишет: значения ему даёт Unit1, после ShowModal = mrOk Unit1
//  сравнивает их с прежними и применяет изменённые. Кнопка «Открыть в
//  редакторе» на вкладке Ignored files - тоже mrOk, с OpenIgnoreInEditor.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiEdit, TUiMemo
  UiStdCtrls,    // TUiLabel, TUiRadioButton
  UiComCtrls;    // TUiPageControl

const
  RepoTabRemote = 0;
  RepoTabIgnore = 1;
  RepoTabConfig = 2;

type
  TDlgGitRepoSettings = class(TForm)
  private
    FPages: TUiPageControl;
    FTabRemote: TTabSheet;
    FTabIgnore: TTabSheet;
    FTabConfig: TTabSheet;
    FLblRemote: TUiLabel;
    FEdRemote: TUiEdit;
    FLblRemoteNote: TUiLabel;
    FLblIgnore: TUiLabel;
    FMemoIgnore: TUiMemo;
    FBtnIgnoreEditor: TUiButton;
    FRbGlobal: TUiRadioButton;
    FRbLocal: TUiRadioButton;
    FLblName: TUiLabel;
    FEdName: TUiEdit;
    FLblEmail: TUiLabel;
    FEdEmail: TUiEdit;
    FLblConfigNote: TUiLabel;
    FBtnOk: TUiButton;
    FBtnCancel: TUiButton;
    FGlobalName: string;
    FGlobalEmail: string;
    FLocalName: string;
    FLocalEmail: string;
    FOpenIgnoreInEditor: Boolean;
    FIgnoreShown: string;       // текст .gitignore, как его показало окно
    procedure ConfigModeClick(Sender: TObject);
    procedure UpdateConfigFields;
    procedure BtnIgnoreEditorClick(Sender: TObject);
    function GetRemoteUrl: string;
    function GetIgnoreText: string;
    function GetUseLocalConfig: Boolean;
    function GetUserName: string;
    function GetUserEmail: string;
  public
    // ARepo - папка репозитория (в заголовок), ATab - RepoTab*.
    // AIgnoreExists - .gitignore уже есть (иначе вкладка говорит, что он
    // будет создан). Имя и почта: общие (--global) и этого репозитория
    // (--local, пусто - не заданы).
    constructor CreateDlg(AOwner: TComponent; const ARepo: string;
      ATab: Integer; const ARemoteUrl, AIgnoreText: string;
      AIgnoreExists: Boolean; const AGlobalName, AGlobalEmail, ALocalName,
      ALocalEmail: string);
    property RemoteUrl: string read GetRemoteUrl;
    property IgnoreText: string read GetIgnoreText;
    // IgnoreText сразу после показа: Lines.Text переводит строки в CRLF и
    // добавляет перевод в конце - сравнивать с ним, а не с исходным
    property IgnoreShownText: string read FIgnoreShown;
    property UseLocalConfig: Boolean read GetUseLocalConfig;
    // Имя и почта для --local (при UseLocalConfig)
    property UserName: string read GetUserName;
    property UserEmail: string read GetUserEmail;
    property OpenIgnoreInEditor: Boolean read FOpenIgnoreInEditor;
  end;

implementation

constructor TDlgGitRepoSettings.CreateDlg(AOwner: TComponent;
  const ARepo: string; ATab: Integer; const ARemoteUrl, AIgnoreText: string;
  AIgnoreExists: Boolean; const AGlobalName, AGlobalEmail, ALocalName,
  ALocalEmail: string);
begin
  inherited CreateNew(AOwner);
  FGlobalName := AGlobalName;
  FGlobalEmail := AGlobalEmail;
  FLocalName := ALocalName;
  FLocalEmail := ALocalEmail;
  FOpenIgnoreInEditor := False;
  Caption := 'Repository Settings - ' +
    ExtractFileName(ExcludeTrailingPathDelimiter(ARepo));
  Position := poMainFormCenter;
  BorderStyle := bsDialog;
  ClientWidth := 600;
  ClientHeight := 400;
  KeyPreview := True;

  FPages := TUiPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.SetBounds(8, 8, 584, 344);

  FTabRemote := TTabSheet.Create(Self);
  FTabRemote.PageControl := FPages;
  FTabRemote.Caption := 'Remote';

  FTabIgnore := TTabSheet.Create(Self);
  FTabIgnore.PageControl := FPages;
  FTabIgnore.Caption := 'Ignored files';

  FTabConfig := TTabSheet.Create(Self);
  FTabConfig.PageControl := FPages;
  FTabConfig.Caption := 'Git config';

  // --- Remote ---
  FLblRemote := TUiLabel.Create(Self);
  FLblRemote.Parent := FTabRemote;
  FLblRemote.SetBounds(8, 12, 556, 16);
  FLblRemote.Caption := 'Адрес remote origin:';

  FEdRemote := TUiEdit.Create(Self);
  FEdRemote.Parent := FTabRemote;
  FEdRemote.SetBounds(8, 32, 556, 22);
  FEdRemote.Text := ARemoteUrl;

  FLblRemoteNote := TUiLabel.Create(Self);
  FLblRemoteNote.Parent := FTabRemote;
  FLblRemoteNote.SetBounds(8, 64, 556, 60);
  FLblRemoteNote.AutoSize := False;
  FLblRemoteNote.WordWrap := True;
  FLblRemoteNote.Caption := 'Например https://github.com/владелец/имя.git. ' +
    'Новый адрес - git remote set-url origin, если origin ещё нет - git ' +
    'remote add origin.';

  // --- Ignored files ---
  FLblIgnore := TUiLabel.Create(Self);
  FLblIgnore.Parent := FTabIgnore;
  FLblIgnore.SetBounds(8, 8, 556, 32);
  FLblIgnore.AutoSize := False;
  FLblIgnore.WordWrap := True;
  if AIgnoreExists then
    FLblIgnore.Caption := '.gitignore: файлы, которые git не отслеживает. ' +
      'На файлы, уже добавленные в git, не действует.'
  else
    FLblIgnore.Caption := '.gitignore в репозитории нет - при сохранении ' +
      'непустого текста он будет создан в корне репозитория.';

  FMemoIgnore := TUiMemo.Create(Self);
  FMemoIgnore.Parent := FTabIgnore;
  FMemoIgnore.SetBounds(8, 44, 556, 230);
  FMemoIgnore.ScrollBars := ssBoth;
  FMemoIgnore.WordWrap := False;
  FMemoIgnore.WantTabs := False;
  FMemoIgnore.Font.Name := 'Courier New';
  FMemoIgnore.Font.Size := 10;
  FMemoIgnore.Lines.Text := AIgnoreText;
  FIgnoreShown := FMemoIgnore.Lines.Text;

  FBtnIgnoreEditor := TUiButton.Create(Self);
  FBtnIgnoreEditor.Parent := FTabIgnore;
  FBtnIgnoreEditor.SetBounds(8, 282, 170, 24);
  FBtnIgnoreEditor.Caption := 'Открыть в редакторе';
  FBtnIgnoreEditor.Hint := 'Сохранить настройки окна и открыть .gitignore ' +
    'во вкладке редактора';
  FBtnIgnoreEditor.ShowHint := True;
  FBtnIgnoreEditor.OnClick := BtnIgnoreEditorClick;

  // --- Git config ---
  FRbGlobal := TUiRadioButton.Create(Self);
  FRbGlobal.Parent := FTabConfig;
  FRbGlobal.SetBounds(8, 12, 556, 20);
  FRbGlobal.Caption := 'Общие настройки git (git config --global)';
  FRbGlobal.OnClick := ConfigModeClick;

  FRbLocal := TUiRadioButton.Create(Self);
  FRbLocal.Parent := FTabConfig;
  FRbLocal.SetBounds(8, 36, 556, 20);
  FRbLocal.Caption := 'Свои для этого репозитория (git config --local)';
  FRbLocal.OnClick := ConfigModeClick;

  FLblName := TUiLabel.Create(Self);
  FLblName.Parent := FTabConfig;
  FLblName.SetBounds(8, 72, 120, 16);
  FLblName.Caption := 'Имя (user.name):';

  FEdName := TUiEdit.Create(Self);
  FEdName.Parent := FTabConfig;
  FEdName.SetBounds(136, 69, 428, 22);

  FLblEmail := TUiLabel.Create(Self);
  FLblEmail.Parent := FTabConfig;
  FLblEmail.SetBounds(8, 102, 120, 16);
  FLblEmail.Caption := 'Почта (user.email):';

  FEdEmail := TUiEdit.Create(Self);
  FEdEmail.Parent := FTabConfig;
  FEdEmail.SetBounds(136, 99, 428, 22);

  FLblConfigNote := TUiLabel.Create(Self);
  FLblConfigNote.Parent := FTabConfig;
  FLblConfigNote.SetBounds(8, 134, 556, 60);
  FLblConfigNote.AutoSize := False;
  FLblConfigNote.WordWrap := True;
  FLblConfigNote.Caption := 'Имя и почта пишутся автором в каждый новый ' +
    'коммит. Общие настройки здесь только показываются; свои для ' +
    'репозитория записываются в .git\config этой папки.';

  // Свои уже заданы - выбраны свои
  if (FLocalName <> '') or (FLocalEmail <> '') then
    FRbLocal.Checked := True
  else
    FRbGlobal.Checked := True;
  UpdateConfigFields;

  // --- Кнопки ---
  FBtnOk := TUiButton.Create(Self);
  FBtnOk.Parent := Self;
  FBtnOk.SetBounds(410, 364, 88, 26);
  FBtnOk.Caption := 'Save';
  FBtnOk.Default := True;
  FBtnOk.ModalResult := mrOk;

  FBtnCancel := TUiButton.Create(Self);
  FBtnCancel.Parent := Self;
  FBtnCancel.SetBounds(504, 364, 88, 26);
  FBtnCancel.Caption := 'Cancel';
  FBtnCancel.Cancel := True;
  FBtnCancel.ModalResult := mrCancel;

  if (ATab >= 0) and (ATab < FPages.PageCount) then
    FPages.ActivePageIndex := ATab;
end;

procedure TDlgGitRepoSettings.ConfigModeClick(Sender: TObject);
begin
  UpdateConfigFields;
end;

// Общие - поля с общими значениями, только для чтения; свои - свои
// значения (не заданы - общие как начальный текст)
procedure TDlgGitRepoSettings.UpdateConfigFields;
var
  IsLocal: Boolean;
begin
  IsLocal := FRbLocal.Checked;
  FEdName.ReadOnly := not IsLocal;
  FEdEmail.ReadOnly := not IsLocal;
  FEdName.Enabled := IsLocal;
  FEdEmail.Enabled := IsLocal;
  if IsLocal then
  begin
    if FLocalName <> '' then
      FEdName.Text := FLocalName
    else
      FEdName.Text := FGlobalName;
    if FLocalEmail <> '' then
      FEdEmail.Text := FLocalEmail
    else
      FEdEmail.Text := FGlobalEmail;
  end
  else
  begin
    // Правки своих значений не теряются при переключении туда-обратно
    if FEdName.Text <> FGlobalName then
      FLocalName := FEdName.Text;
    if FEdEmail.Text <> FGlobalEmail then
      FLocalEmail := FEdEmail.Text;
    FEdName.Text := FGlobalName;
    FEdEmail.Text := FGlobalEmail;
  end;
end;

procedure TDlgGitRepoSettings.BtnIgnoreEditorClick(Sender: TObject);
begin
  FOpenIgnoreInEditor := True;
  ModalResult := mrOk;
end;

function TDlgGitRepoSettings.GetRemoteUrl: string;
begin
  Result := Trim(FEdRemote.Text);
end;

function TDlgGitRepoSettings.GetIgnoreText: string;
begin
  Result := FMemoIgnore.Lines.Text;
end;

function TDlgGitRepoSettings.GetUseLocalConfig: Boolean;
begin
  Result := FRbLocal.Checked;
end;

function TDlgGitRepoSettings.GetUserName: string;
begin
  Result := Trim(FEdName.Text);
end;

function TDlgGitRepoSettings.GetUserEmail: string;
begin
  Result := Trim(FEdEmail.Text);
end;

end.
