unit DlgGitClone;

// ---------------------------------------------------------------------------
//  Окно Clone Repository (меню Repository - Clone Repository, Unit1), как
//  в GitHub Desktop: вкладки GitHub.com (список репозиториев пользователя
//  с фильтром) и URL (адрес или владелец/имя), локальный путь с кнопкой
//  Choose..., флажок «Создать проект на основе локального репозитория»,
//  кнопки Clone и Cancel.
//
//  Окно строится в коде (CreateDlg), .dfm нет. Список берётся GitHub API
//  (GitHubApi) с токеном из сохранённого логина git: его достаёт Unit1
//  (OnCredGet - git credential fill). Нет логина - кнопка «Войти...»:
//  логин и personal access token, токен проверяется (GET /user) и
//  сохраняется через git (OnCredStore - git credential approve).
//
//  Локальный путь - <папка>\<имя репозитория>: идёт за выбранным
//  репозиторием, пока его не правили руками; Choose... выбирает папку, в
//  которой будет папка репозитория. Клонирует Unit1 после ShowModal = mrOk
//  (CloneUrl, TargetDir, CreateProject); BaseDir - папка для следующего
//  раза (editor.ini [Git] CloneDir).
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiEdit
  UiStdCtrls,    // TUiCheckBox, TUiLabel
  UiComCtrls,    // TUiListView, TUiPageControl
  FolderDlg,     // BrowseFolderDialog
  GitHubApi;     // GitHubListRepos, GitHubTokenLogin, GitHubNormalizeUrl

type
  // Сохранённый логин git для github.com (логин и токен); False - нет
  TGitCredGetEvent = function(var AUser, AToken: string): Boolean of object;
  // Сохранить логин git для github.com; False - AError
  TGitCredStoreEvent = function(const AUser, AToken: string;
    var AError: string): Boolean of object;

  TDlgGitClone = class(TForm)
  private
    FOnCredGet: TGitCredGetEvent;
    FOnCredStore: TGitCredStoreEvent;
    FRepos: TGitHubRepos;
    FUser: string;
    FToken: string;
    FBaseDir: string;
    FPathAuto: Boolean;
    FSettingPath: Boolean;
    FLoaded: Boolean;
    FCloneUrl: string;
    FTargetDir: string;
    FPages: TUiPageControl;
    FTabGitHub: TTabSheet;
    FTabUrl: TTabSheet;
    FFilter: TUiEdit;
    FBtnRefresh: TUiButton;
    FBtnLogin: TUiButton;
    FLblAccount: TUiLabel;
    FList: TUiListView;
    FLblUrl: TUiLabel;
    FUrl: TUiEdit;
    FLblUrlNote: TUiLabel;
    FLblPath: TUiLabel;
    FPath: TUiEdit;
    FBtnChoose: TUiButton;
    FChkProject: TUiCheckBox;
    FBtnClone: TUiButton;
    FBtnCancel: TUiButton;
    procedure FormShowEvent(Sender: TObject);
    procedure LoadRepos(AFromGit: Boolean);
    procedure FillList;
    function CurrentName: string;
    procedure SetAutoPath;
    procedure FilterChange(Sender: TObject);
    procedure ListSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ListDblClick(Sender: TObject);
    procedure UrlChange(Sender: TObject);
    procedure PathChange(Sender: TObject);
    procedure PagesChange(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnLoginClick(Sender: TObject);
    procedure BtnChooseClick(Sender: TObject);
    procedure BtnCloneClick(Sender: TObject);
    function AskLogin(var AUser, AToken: string): Boolean;
    procedure Warn(const AText: string);
    // Загрузка списка - после показа окна (WM_USER + 100)
    procedure UMLoad(var Message: TMessage); message WM_USER + 100;
    // $0128 - WM_UPDATEUISTATE (кнопки не пропадают по Alt, как в других окнах)
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    constructor CreateDlg(AOwner: TComponent; const ABaseDir: string;
      ACreateProject: Boolean; AOnCredGet: TGitCredGetEvent;
      AOnCredStore: TGitCredStoreEvent);
    // Адрес для git clone
    property CloneUrl: string read FCloneUrl;
    // Папка клона (её создаст git)
    property TargetDir: string read FTargetDir;
    // Папка, в которой создаются клоны (для следующего раза)
    property BaseDir: string read FBaseDir;
    function CreateProject: Boolean;
  end;

implementation

const
  CloneCaption = 'Clone Repository';

// Папка пуста (git clone в неё можно)
function DirIsEmpty(const ADir: string): Boolean;
var
  SearchRec: TSearchRec;
begin
  Result := True;
  if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*.*', faAnyFile,
     SearchRec) = 0 then
  try
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        Result := False;
        Exit;
      end;
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
end;

constructor TDlgGitClone.CreateDlg(AOwner: TComponent; const ABaseDir: string;
  ACreateProject: Boolean; AOnCredGet: TGitCredGetEvent;
  AOnCredStore: TGitCredStoreEvent);
var
  Column: TListColumn;
begin
  inherited CreateNew(AOwner);
  FOnCredGet := AOnCredGet;
  FOnCredStore := AOnCredStore;
  FBaseDir := ExcludeTrailingPathDelimiter(ABaseDir);
  FPathAuto := True;
  FSettingPath := False;
  FLoaded := False;
  Caption := CloneCaption;
  Position := poMainFormCenter;
  BorderStyle := bsDialog;
  ClientWidth := 560;
  ClientHeight := 470;
  KeyPreview := True;
  OnShow := FormShowEvent;

  FPages := TUiPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.SetBounds(8, 8, 544, 330);
  FPages.OnChange := PagesChange;

  FTabGitHub := TTabSheet.Create(Self);
  FTabGitHub.PageControl := FPages;
  FTabGitHub.Caption := 'GitHub.com';

  FTabUrl := TTabSheet.Create(Self);
  FTabUrl.PageControl := FPages;
  FTabUrl.Caption := 'URL';

  // --- GitHub.com: фильтр, Обновить, Войти, кто вошёл, список ---
  FFilter := TUiEdit.Create(Self);
  FFilter.Parent := FTabGitHub;
  FFilter.SetBounds(8, 8, 330, 22);
  FFilter.Hint := 'Фильтр: часть имени репозитория';
  FFilter.ShowHint := True;
  FFilter.OnChange := FilterChange;

  FBtnRefresh := TUiButton.Create(Self);
  FBtnRefresh.Parent := FTabGitHub;
  FBtnRefresh.SetBounds(344, 7, 84, 24);
  FBtnRefresh.Caption := 'Обновить';
  FBtnRefresh.Hint := 'Перечитать список репозиториев с GitHub';
  FBtnRefresh.ShowHint := True;
  FBtnRefresh.OnClick := BtnRefreshClick;

  FBtnLogin := TUiButton.Create(Self);
  FBtnLogin.Parent := FTabGitHub;
  FBtnLogin.SetBounds(434, 7, 92, 24);
  FBtnLogin.Caption := 'Войти...';
  FBtnLogin.Hint := 'Логин GitHub и personal access token: проверяется и ' +
    'сохраняется через git (credential.helper)';
  FBtnLogin.ShowHint := True;
  FBtnLogin.OnClick := BtnLoginClick;

  FLblAccount := TUiLabel.Create(Self);
  FLblAccount.Parent := FTabGitHub;
  FLblAccount.SetBounds(8, 36, 518, 16);
  FLblAccount.AutoSize := False;
  FLblAccount.Caption := 'Список репозиториев загружается...';

  FList := TUiListView.Create(Self);
  FList.Parent := FTabGitHub;
  FList.SetBounds(8, 56, 518, 238);
  FList.ViewStyle := vsReport;
  FList.ReadOnly := True;
  FList.RowSelect := True;
  FList.HideSelection := False;
  Column := FList.Columns.Add;
  Column.Caption := 'Репозиторий';
  Column.Width := 220;
  Column := FList.Columns.Add;
  Column.Caption := 'Доступ';
  Column.Width := 90;
  Column := FList.Columns.Add;
  Column.Caption := 'Описание';
  Column.Width := 185;
  FList.OnSelectItem := ListSelect;
  FList.OnDblClick := ListDblClick;

  // --- URL: адрес или владелец/имя ---
  FLblUrl := TUiLabel.Create(Self);
  FLblUrl.Parent := FTabUrl;
  FLblUrl.SetBounds(8, 12, 518, 16);
  FLblUrl.Caption := 'Адрес репозитория или владелец/имя:';

  FUrl := TUiEdit.Create(Self);
  FUrl.Parent := FTabUrl;
  FUrl.SetBounds(8, 32, 518, 22);
  FUrl.OnChange := UrlChange;

  FLblUrlNote := TUiLabel.Create(Self);
  FLblUrlNote.Parent := FTabUrl;
  FLblUrlNote.SetBounds(8, 64, 518, 60);
  FLblUrlNote.AutoSize := False;
  FLblUrlNote.WordWrap := True;
  FLblUrlNote.Caption := 'Например: https://github.com/владелец/имя.git, ' +
    'github.com/владелец/имя или владелец/имя (тогда - с github.com). ' +
    'Подходит и адрес другого сервера git (https://, git@).';

  // --- Локальный путь, флажок проекта, кнопки ---
  FLblPath := TUiLabel.Create(Self);
  FLblPath.Parent := Self;
  FLblPath.SetBounds(8, 348, 400, 16);
  FLblPath.Caption := 'Локальный путь (Local path):';

  FPath := TUiEdit.Create(Self);
  FPath.Parent := Self;
  FPath.SetBounds(8, 366, 448, 22);
  FPath.Text := FBaseDir;
  FPath.OnChange := PathChange;

  FBtnChoose := TUiButton.Create(Self);
  FBtnChoose.Parent := Self;
  FBtnChoose.SetBounds(462, 365, 90, 24);
  FBtnChoose.Caption := 'Choose...';
  FBtnChoose.Hint := 'Папка, в которой будет создана папка репозитория';
  FBtnChoose.ShowHint := True;
  FBtnChoose.OnClick := BtnChooseClick;

  FChkProject := TUiCheckBox.Create(Self);
  FChkProject.Parent := Self;
  FChkProject.SetBounds(8, 398, 544, 20);
  FChkProject.Caption := 'Создать проект на основе локального репозитория';
  FChkProject.Hint := 'После клонирования - окно New Project с папкой ' +
    'клона и отмеченным «На базе существующего проекта»';
  FChkProject.ShowHint := True;
  FChkProject.Checked := ACreateProject;

  FBtnClone := TUiButton.Create(Self);
  FBtnClone.Parent := Self;
  FBtnClone.SetBounds(370, 434, 88, 26);
  FBtnClone.Caption := 'Clone';
  FBtnClone.Default := True;
  FBtnClone.OnClick := BtnCloneClick;

  FBtnCancel := TUiButton.Create(Self);
  FBtnCancel.Parent := Self;
  FBtnCancel.SetBounds(464, 434, 88, 26);
  FBtnCancel.Caption := 'Cancel';
  FBtnCancel.Cancel := True;
  FBtnCancel.ModalResult := mrCancel;

  FPages.ActivePage := FTabGitHub;
  ActiveControl := FFilter;
end;

procedure TDlgGitClone.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

function TDlgGitClone.CreateProject: Boolean;
begin
  Result := FChkProject.Checked;
end;

procedure TDlgGitClone.Warn(const AText: string);
begin
  MessageBox(Handle, PChar(AText), CloneCaption, MB_OK or MB_ICONWARNING);
end;

// Окно уже на экране - список грузится после отрисовки
procedure TDlgGitClone.FormShowEvent(Sender: TObject);
begin
  if FLoaded then
    Exit;
  FLoaded := True;
  PostMessage(Handle, WM_USER + 100, 0, 0);
end;

procedure TDlgGitClone.UMLoad(var Message: TMessage);
begin
  LoadRepos(True);
end;

// Список с GitHub. AFromGit - токен взять из сохранённого логина git
// (иначе - уже известный FToken)
procedure TDlgGitClone.LoadRepos(AFromGit: Boolean);
var
  ErrText: string;
begin
  if AFromGit or (FToken = '') then
  begin
    FUser := '';
    FToken := '';
    FLblAccount.Caption := 'Логин GitHub - из git (credential.helper)...';
    FLblAccount.Update;
    if not Assigned(FOnCredGet) or not FOnCredGet(FUser, FToken) or
       (FToken = '') then
    begin
      SetLength(FRepos, 0);
      FillList;
      FLblAccount.Caption := 'Логин GitHub не сохранён - «Войти...» ' +
        '(логин и personal access token) или вкладка URL';
      Exit;
    end;
  end;
  FLblAccount.Caption := 'Список репозиториев с GitHub...';
  FLblAccount.Update;
  Screen.Cursor := crHourGlass;
  try
    if not GitHubListRepos(FToken, FRepos, ErrText) then
    begin
      SetLength(FRepos, 0);
      FillList;
      FLblAccount.Caption := ErrText + ' - «Войти...» или вкладка URL';
      Exit;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  FillList;
  if FUser <> '' then
    FLblAccount.Caption := 'Вход: ' + FUser + ', репозиториев: ' +
      IntToStr(Length(FRepos))
  else
    FLblAccount.Caption := 'Репозиториев: ' + IntToStr(Length(FRepos));
end;

// Строки списка - по фильтру (часть полного имени, без учёта регистра)
procedure TDlgGitClone.FillList;
var
  RepoIndex: Integer;
  Item: TListItem;
  FilterText, Access: string;
begin
  FilterText := AnsiLowerCase(Trim(FFilter.Text));
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for RepoIndex := 0 to High(FRepos) do
    begin
      if (FilterText <> '') and
         (Pos(FilterText, AnsiLowerCase(string(FRepos[RepoIndex].FullName))) =
          0) then
        Continue;
      Item := FList.Items.Add;
      Item.Caption := string(FRepos[RepoIndex].FullName);
      if FRepos[RepoIndex].IsPrivate then
        Access := 'private'
      else
        Access := 'public';
      if FRepos[RepoIndex].IsFork then
        Access := Access + ', fork';
      Item.SubItems.Add(Access);
      Item.SubItems.Add(string(FRepos[RepoIndex].Description));
      Item.Data := Pointer(RepoIndex);
    end;
  finally
    FList.Items.EndUpdate;
  end;
  if FList.Items.Count > 0 then
    FList.Items[0].Selected := True;
end;

// Имя репозитория - по текущей вкладке ('' - не выбран / не разобран)
function TDlgGitClone.CurrentName: string;
var
  RepoIndex: Integer;
begin
  Result := '';
  if FPages.ActivePage = FTabUrl then
    GitHubNormalizeUrl(FUrl.Text, Result)
  else if FList.Selected <> nil then
  begin
    RepoIndex := Integer(FList.Selected.Data);
    if (RepoIndex >= 0) and (RepoIndex <= High(FRepos)) then
      Result := string(FRepos[RepoIndex].Name);
  end;
end;

// Путь идёт за репозиторием, пока его не правили руками
procedure TDlgGitClone.SetAutoPath;
var
  RepoName: string;
begin
  if not FPathAuto then
    Exit;
  RepoName := CurrentName;
  FSettingPath := True;
  try
    if RepoName <> '' then
      FPath.Text := IncludeTrailingPathDelimiter(FBaseDir) + RepoName
    else
      FPath.Text := FBaseDir;
  finally
    FSettingPath := False;
  end;
end;

procedure TDlgGitClone.FilterChange(Sender: TObject);
begin
  FillList;
  SetAutoPath;
end;

procedure TDlgGitClone.ListSelect(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected then
    SetAutoPath;
end;

procedure TDlgGitClone.ListDblClick(Sender: TObject);
begin
  if FList.Selected <> nil then
    BtnCloneClick(nil);
end;

procedure TDlgGitClone.UrlChange(Sender: TObject);
begin
  SetAutoPath;
end;

procedure TDlgGitClone.PathChange(Sender: TObject);
begin
  if not FSettingPath then
    FPathAuto := False;
end;

procedure TDlgGitClone.PagesChange(Sender: TObject);
begin
  SetAutoPath;
  if FPages.ActivePage = FTabUrl then
  begin
    if FUrl.CanFocus then
      FUrl.SetFocus;
  end
  else if FFilter.CanFocus then
    FFilter.SetFocus;
end;

procedure TDlgGitClone.BtnRefreshClick(Sender: TObject);
begin
  LoadRepos(FToken = '');
end;

// Окно входа: логин и токен (токен - звёздочками)
function TDlgGitClone.AskLogin(var AUser, AToken: string): Boolean;
var
  LoginForm: TForm;
  LblUser, LblToken, LblNote: TUiLabel;
  EdUser, EdToken: TUiEdit;
  BtnOk, BtnCancel: TUiButton;
begin
  Result := False;
  LoginForm := TForm.CreateNew(Self);
  try
    LoginForm.Caption := 'Вход в GitHub';
    LoginForm.Position := poOwnerFormCenter;
    LoginForm.BorderStyle := bsDialog;
    LoginForm.ClientWidth := 420;
    LoginForm.ClientHeight := 230;

    LblUser := TUiLabel.Create(LoginForm);
    LblUser.Parent := LoginForm;
    LblUser.SetBounds(12, 12, 396, 16);
    LblUser.Caption := 'Логин GitHub (Username):';

    EdUser := TUiEdit.Create(LoginForm);
    EdUser.Parent := LoginForm;
    EdUser.SetBounds(12, 30, 396, 22);
    EdUser.Text := AUser;

    LblToken := TUiLabel.Create(LoginForm);
    LblToken.Parent := LoginForm;
    LblToken.SetBounds(12, 60, 396, 16);
    LblToken.Caption := 'Personal access token (вместо пароля):';

    EdToken := TUiEdit.Create(LoginForm);
    EdToken.Parent := LoginForm;
    EdToken.SetBounds(12, 78, 396, 22);
    EdToken.PasswordChar := '*';

    LblNote := TUiLabel.Create(LoginForm);
    LblNote.Parent := LoginForm;
    LblNote.SetBounds(12, 108, 396, 76);
    LblNote.AutoSize := False;
    LblNote.WordWrap := True;
    LblNote.Caption := 'Пароль от аккаунта GitHub для git по https не ' +
      'принимается. Токен создаётся на GitHub: Settings - Developer ' +
      'settings - Personal access tokens; нужен доступ к репозиториям ' +
      '(classic: repo; fine-grained: Contents - Read and write). Токен ' +
      'сохраняется через git (credential.helper, например wincred - ' +
      'диспетчер учётных данных Windows).';

    BtnOk := TUiButton.Create(LoginForm);
    BtnOk.Parent := LoginForm;
    BtnOk.SetBounds(226, 194, 88, 26);
    BtnOk.Caption := 'OK';
    BtnOk.Default := True;
    BtnOk.ModalResult := mrOk;

    BtnCancel := TUiButton.Create(LoginForm);
    BtnCancel.Parent := LoginForm;
    BtnCancel.SetBounds(320, 194, 88, 26);
    BtnCancel.Caption := 'Cancel';
    BtnCancel.Cancel := True;
    BtnCancel.ModalResult := mrCancel;

    if AUser = '' then
      LoginForm.ActiveControl := EdUser
    else
      LoginForm.ActiveControl := EdToken;
    if LoginForm.ShowModal <> mrOk then
      Exit;
    AUser := Trim(EdUser.Text);
    AToken := Trim(EdToken.Text);
    Result := AToken <> '';
  finally
    LoginForm.Free;
  end;
end;

// Войти: токен проверяется (логин - от GitHub), сохраняется через git,
// список перечитывается
procedure TDlgGitClone.BtnLoginClick(Sender: TObject);
var
  NewUser, NewToken, Login, ErrText: string;
  TokenOk: Boolean;
begin
  NewUser := FUser;
  NewToken := '';
  if not AskLogin(NewUser, NewToken) then
    Exit;
  Screen.Cursor := crHourGlass;
  try
    TokenOk := GitHubTokenLogin(NewToken, Login, ErrText);
  finally
    Screen.Cursor := crDefault;
  end;
  if not TokenOk then
  begin
    Warn('Токен не принят: ' + ErrText);
    Exit;
  end;
  if (NewUser <> '') and not SameText(NewUser, Login) then
    Warn('Токен принадлежит пользователю ' + Login + ' (введено ' +
      NewUser + ') - сохраняется как ' + Login + '.');
  FUser := Login;
  FToken := NewToken;
  if Assigned(FOnCredStore) and not FOnCredStore(FUser, FToken, ErrText) then
    Warn('Токен подходит, но git его не сохранил: ' + ErrText + #13#10#13#10 +
      'Список репозиториев покажется в этот раз; при clone, fetch, push ' +
      'git снова спросит логин.');
  LoadRepos(False);
end;

procedure TDlgGitClone.BtnChooseClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FBaseDir;
  if not BrowseFolderDialog('Clone Repository - папка, в которой будет ' +
     'создана папка репозитория', Dir) then
    Exit;
  FBaseDir := ExcludeTrailingPathDelimiter(Dir);
  FPathAuto := True;
  SetAutoPath;
end;

procedure TDlgGitClone.BtnCloneClick(Sender: TObject);
var
  RepoIndex: Integer;
  RepoName, Target: string;
begin
  FCloneUrl := '';
  if FPages.ActivePage = FTabUrl then
  begin
    FCloneUrl := GitHubNormalizeUrl(FUrl.Text, RepoName);
    if FCloneUrl = '' then
    begin
      Warn('Адрес не разобран. Нужен адрес репозитория ' +
        '(https://github.com/владелец/имя) или владелец/имя.');
      if FUrl.CanFocus then
        FUrl.SetFocus;
      Exit;
    end;
  end
  else
  begin
    if FList.Selected = nil then
    begin
      Warn('Выберите репозиторий в списке или задайте адрес на вкладке URL.');
      Exit;
    end;
    RepoIndex := Integer(FList.Selected.Data);
    if (RepoIndex < 0) or (RepoIndex > High(FRepos)) then
      Exit;
    FCloneUrl := string(FRepos[RepoIndex].CloneUrl);
  end;
  Target := ExcludeTrailingPathDelimiter(Trim(FPath.Text));
  if (Target = '') or (ExtractFileDrive(Target) = '') then
  begin
    Warn('Нужен полный локальный путь - папка клона (например ' +
      'D:\projects\имя).');
    Exit;
  end;
  if FileExists(Target) then
  begin
    Warn('По этому пути - файл:'#13#10 + Target);
    Exit;
  end;
  if DirectoryExists(Target) and not DirIsEmpty(Target) then
  begin
    Warn('Папка уже есть и не пуста:'#13#10 + Target + #13#10#13#10 +
      'git clone в неё не пишет - выберите другой путь.');
    Exit;
  end;
  FTargetDir := Target;
  FBaseDir := ExcludeTrailingPathDelimiter(ExtractFilePath(Target));
  ModalResult := mrOk;
end;

end.
