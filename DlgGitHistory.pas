unit DlgGitHistory;

// ---------------------------------------------------------------------------
//  Окно History (меню Repository, панель Git - Unit1): коммиты текущей
//  ветки (git log), у выбранного - сведения (автор, дата, полный текст),
//  изменённые файлы и разница выбранного файла. Как вкладка History
//  GitHub Desktop.
//
//  git запускает Unit1 (OnQuery - тихий запуск в папке репозитория).
//  Кнопки: Copy SHA (в буфер), View on GitHub (страница коммита), New
//  Branch from Commit и Revert Commit - их выполняет Unit1 после
//  закрытия окна (Action, SelectedHash).
//
//  Окно строится в коде (CreateDlg), .dfm нет.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls, Clipbrd, ShellAPI,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiMemo
  UiStdCtrls,    // TUiLabel, TUiPanel
  UiComCtrls,    // TUiListView
  GitDiffView,   // TGitDiffView - разница с подсветкой
  GitRun;        // TGitCommit, разбор вывода

type
  // Тихий запуск git с аргументами AArgs; результат - код выхода
  TGitQueryEvent = function(const AArgs: string;
    var AOutput: WideString): Integer of object;

  // Что сделать после закрытия окна
  TGitHistAction = (ghaNone, ghaBranch, ghaRevert);

  TDlgGitHistory = class(TForm)
  private
    FOnQuery: TGitQueryEvent;
    FWebUrl: string;
    FCommits: TGitCommits;
    FFiles: TGitChanges;
    FCurHash: string;
    FCurHasParent: Boolean;
    FAction: TGitHistAction;
    FLimit: Integer;
    FLeft: TUiPanel;
    FRight: TUiPanel;
    FBtnPanel: TUiPanel;
    FLblInfo: TUiLabel;
    FCommitList: TUiListView;
    FDetails: TUiMemo;
    FFileList: TUiListView;
    FDiff: TGitDiffView;
    FSplitLeft: TSplitter;
    FSplitTop: TSplitter;
    FSplitFiles: TSplitter;
    FBtnMore: TUiButton;
    FBtnCopy: TUiButton;
    FBtnWeb: TUiButton;
    FBtnBranch: TUiButton;
    FBtnRevert: TUiButton;
    FBtnClose: TUiButton;
    procedure LoadCommits;
    procedure ShowCommit(AIndex: Integer);
    procedure ShowFileDiff(AIndex: Integer);
    procedure CommitSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure FileSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure BtnMoreClick(Sender: TObject);
    procedure BtnCopyClick(Sender: TObject);
    procedure BtnWebClick(Sender: TObject);
    procedure BtnBranchClick(Sender: TObject);
    procedure BtnRevertClick(Sender: TObject);
    procedure LayoutButtons(Sender: TObject);
    function Query(const AArgs: string; var AOutput: WideString): Integer;
    procedure UpdateButtons;
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    constructor CreateDlg(AOwner: TComponent; const ATitle, AWebUrl: string;
      AOnQuery: TGitQueryEvent);
    property Action: TGitHistAction read FAction;
    property SelectedHash: string read FCurHash;
  end;

const
  GitHistPage = 500;        // столько коммитов за раз (Load More - ещё)
  GitHistDiffMax = 300000;  // разница длиннее - обрезается

implementation

constructor TDlgGitHistory.CreateDlg(AOwner: TComponent; const ATitle,
  AWebUrl: string; AOnQuery: TGitQueryEvent);
var
  Column: TListColumn;
begin
  inherited CreateNew(AOwner);
  FOnQuery := AOnQuery;
  FWebUrl := AWebUrl;
  FAction := ghaNone;
  FCurHash := '';
  FLimit := GitHistPage;
  Caption := ATitle;
  Position := poMainFormCenter;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Width := 1000;
  Height := 650;
  Constraints.MinWidth := 640;
  Constraints.MinHeight := 420;

  FBtnPanel := TUiPanel.Create(Self);
  FBtnPanel.Parent := Self;
  FBtnPanel.Align := alBottom;
  FBtnPanel.Height := 36;
  FBtnPanel.BevelOuter := bvNone;
  FBtnPanel.Caption := '';
  FBtnPanel.OnResize := LayoutButtons;

  FLeft := TUiPanel.Create(Self);
  FLeft.Parent := Self;
  FLeft.Align := alLeft;
  FLeft.Width := 470;
  FLeft.BevelOuter := bvNone;
  FLeft.Caption := '';

  FSplitLeft := TSplitter.Create(Self);
  FSplitLeft.Parent := Self;
  FSplitLeft.Align := alLeft;
  FSplitLeft.Left := FLeft.Width + 1;
  FSplitLeft.Width := 5;

  FRight := TUiPanel.Create(Self);
  FRight.Parent := Self;
  FRight.Align := alClient;
  FRight.BevelOuter := bvNone;
  FRight.Caption := '';

  FLblInfo := TUiLabel.Create(Self);
  FLblInfo.Parent := FLeft;
  FLblInfo.Align := alTop;
  FLblInfo.Caption := '';

  FCommitList := TUiListView.Create(Self);
  FCommitList.Parent := FLeft;
  FCommitList.Align := alClient;
  FCommitList.ViewStyle := vsReport;
  FCommitList.ReadOnly := True;
  FCommitList.RowSelect := True;
  FCommitList.HideSelection := False;
  Column := FCommitList.Columns.Add;
  Column.Caption := 'Коммит';
  Column.Width := 250;
  Column := FCommitList.Columns.Add;
  Column.Caption := 'Автор';
  Column.Width := 90;
  Column := FCommitList.Columns.Add;
  Column.Caption := 'Дата';
  Column.Width := 100;
  Column := FCommitList.Columns.Add;
  Column.Caption := 'SHA';
  Column.Width := 64;

  // Справа сверху вниз: сведения, файлы, разница
  FDetails := TUiMemo.Create(Self);
  FDetails.Parent := FRight;
  FDetails.Align := alTop;
  FDetails.Height := 120;
  FDetails.ReadOnly := True;
  FDetails.ScrollBars := ssVertical;

  FSplitTop := TSplitter.Create(Self);
  FSplitTop.Parent := FRight;
  FSplitTop.Align := alTop;
  FSplitTop.Top := FDetails.Height + 1;
  FSplitTop.Height := 5;

  FFileList := TUiListView.Create(Self);
  FFileList.Parent := FRight;
  FFileList.Align := alTop;
  FFileList.Top := FDetails.Height + 10;
  FFileList.Height := 150;
  FFileList.ViewStyle := vsReport;
  FFileList.ReadOnly := True;
  FFileList.RowSelect := True;
  FFileList.HideSelection := False;
  Column := FFileList.Columns.Add;
  Column.Caption := 'Файл';
  Column.Width := 380;
  Column := FFileList.Columns.Add;
  Column.Caption := 'Что';
  Column.Width := 100;

  FSplitFiles := TSplitter.Create(Self);
  FSplitFiles.Parent := FRight;
  FSplitFiles.Align := alTop;
  FSplitFiles.Top := FFileList.Top + FFileList.Height + 1;
  FSplitFiles.Height := 5;

  FDiff := TGitDiffView.Create(Self);
  FDiff.Parent := FRight;
  FDiff.Align := alClient;

  FBtnMore := TUiButton.Create(Self);
  FBtnMore.Parent := FBtnPanel;
  FBtnMore.Caption := 'Load More';
  FBtnMore.Hint := 'Показать ещё ' + IntToStr(GitHistPage) + ' коммитов';
  FBtnMore.ShowHint := True;
  FBtnMore.OnClick := BtnMoreClick;

  FBtnCopy := TUiButton.Create(Self);
  FBtnCopy.Parent := FBtnPanel;
  FBtnCopy.Caption := 'Copy SHA';
  FBtnCopy.Hint := 'Полный SHA выбранного коммита - в буфер обмена';
  FBtnCopy.ShowHint := True;
  FBtnCopy.OnClick := BtnCopyClick;

  FBtnWeb := TUiButton.Create(Self);
  FBtnWeb.Parent := FBtnPanel;
  FBtnWeb.Caption := 'View on GitHub';
  FBtnWeb.Hint := 'Страница коммита на GitHub';
  FBtnWeb.ShowHint := True;
  FBtnWeb.OnClick := BtnWebClick;

  FBtnBranch := TUiButton.Create(Self);
  FBtnBranch.Parent := FBtnPanel;
  FBtnBranch.Caption := 'New Branch from Commit...';
  FBtnBranch.Hint := 'Новая ветка от выбранного коммита и переход на неё';
  FBtnBranch.ShowHint := True;
  FBtnBranch.OnClick := BtnBranchClick;

  FBtnRevert := TUiButton.Create(Self);
  FBtnRevert.Parent := FBtnPanel;
  FBtnRevert.Caption := 'Revert Commit';
  FBtnRevert.Hint := 'Новый коммит, отменяющий изменения выбранного ' +
    '(git revert); история не переписывается';
  FBtnRevert.ShowHint := True;
  FBtnRevert.OnClick := BtnRevertClick;

  FBtnClose := TUiButton.Create(Self);
  FBtnClose.Parent := FBtnPanel;
  FBtnClose.Caption := 'Close';
  FBtnClose.Cancel := True;
  FBtnClose.ModalResult := mrCancel;

  LoadCommits;
  FCommitList.OnSelectItem := CommitSelect;
  FFileList.OnSelectItem := FileSelect;
  UpdateButtons;
  ActiveControl := FCommitList;
end;

procedure TDlgGitHistory.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgGitHistory.LayoutButtons(Sender: TObject);
const
  BtnGap = 6;
  BtnH = 24;
var
  BtnTop, BtnLeft: Integer;

  procedure Place(ABtn: TUiButton; AWidth: Integer);
  begin
    ABtn.SetBounds(BtnLeft, BtnTop, AWidth, BtnH);
    Inc(BtnLeft, AWidth + BtnGap);
  end;

begin
  BtnTop := (FBtnPanel.ClientHeight - BtnH) div 2;
  BtnLeft := 4;
  Place(FBtnMore, 80);
  Place(FBtnCopy, 76);
  Place(FBtnWeb, 104);
  Place(FBtnBranch, 170);
  Place(FBtnRevert, 100);
  FBtnClose.SetBounds(FBtnPanel.ClientWidth - 74, BtnTop, 70, BtnH);
end;

function TDlgGitHistory.Query(const AArgs: string;
  var AOutput: WideString): Integer;
begin
  AOutput := '';
  Result := -1;
  if Assigned(FOnQuery) then
    Result := FOnQuery(AArgs, AOutput);
end;

procedure TDlgGitHistory.UpdateButtons;
var
  HasCommit: Boolean;
begin
  HasCommit := FCurHash <> '';
  FBtnCopy.Enabled := HasCommit;
  FBtnWeb.Enabled := HasCommit and (FWebUrl <> '');
  FBtnBranch.Enabled := HasCommit;
  FBtnRevert.Enabled := HasCommit;
end;

// Коммиты текущей ветки: первые FLimit
procedure TDlgGitHistory.LoadCommits;
var
  Output: WideString;
  CommitIdx, KeepIdx: Integer;
  Item: TListItem;
begin
  Screen.Cursor := crHourGlass;
  try
    if Query('log ' + GitLogFormat + ' -n ' + IntToStr(FLimit) + ' HEAD',
       Output) <> 0 then
    begin
      SetLength(FCommits, 0);
      FLblInfo.Caption := 'История пуста (коммитов ещё нет) или git log не ' +
        'вышел';
    end
    else
      GitParseLog(Output, FCommits);
    KeepIdx := -1;
    if FCommitList.Selected <> nil then
      KeepIdx := FCommitList.Selected.Index;
    FCommitList.Items.BeginUpdate;
    try
      FCommitList.Items.Clear;
      for CommitIdx := 0 to High(FCommits) do
      begin
        Item := FCommitList.Items.Add;
        Item.Caption := string(FCommits[CommitIdx].Subject);
        Item.SubItems.Add(string(FCommits[CommitIdx].Author));
        Item.SubItems.Add(FCommits[CommitIdx].Date);
        Item.SubItems.Add(FCommits[CommitIdx].Short);
      end;
    finally
      FCommitList.Items.EndUpdate;
    end;
    if Length(FCommits) > 0 then
      FLblInfo.Caption := 'Коммитов показано: ' + IntToStr(Length(FCommits));
    FBtnMore.Enabled := Length(FCommits) >= FLimit;
    if (KeepIdx >= 0) and (KeepIdx < FCommitList.Items.Count) then
      FCommitList.Items[KeepIdx].Selected := True;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TDlgGitHistory.ShowCommit(AIndex: Integer);
var
  Output: WideString;
  Hash: string;
  FileIdx: Integer;
  Item: TListItem;
begin
  if (AIndex < 0) or (AIndex > High(FCommits)) then
    Exit;
  Hash := FCommits[AIndex].Hash;
  FCurHash := Hash;
  Screen.Cursor := crHourGlass;
  try
    // Сведения: SHA, автор, дата, полный текст
    if Query('show -s --no-color --date=iso --format=' +
       'commit%x20%H%nAuthor:%x20%an%x20<%ae>%nDate:%x20%x20%x20%ad%n%n%B ' +
       Hash, Output) = 0 then
      FDetails.Lines.Text := AdjustLineBreaks(string(GitTrimOut(Output)))
    else
      FDetails.Lines.Text := 'commit ' + Hash;
    // Файлы: против первого родителя; у первого коммита - против пустого
    FCurHasParent := Query('rev-parse -q --verify ' + Hash + '^', Output) = 0;
    if FCurHasParent then
      Query('diff -M --no-color --name-status -z ' + Hash + '^ ' + Hash,
        Output)
    else
      Query('diff-tree -r -M --root --no-commit-id --name-status -z ' + Hash,
        Output);
    GitParseNameStatus(Output, FFiles);
    FFileList.Items.BeginUpdate;
    try
      FFileList.Items.Clear;
      for FileIdx := 0 to High(FFiles) do
      begin
        Item := FFileList.Items.Add;
        if FFiles[FileIdx].OrigPath <> '' then
          Item.Caption := string(GitWinPath(FFiles[FileIdx].Path)) + '  <-  ' +
            string(GitWinPath(FFiles[FileIdx].OrigPath))
        else
          Item.Caption := string(GitWinPath(FFiles[FileIdx].Path));
        Item.SubItems.Add(GitChangeText(FFiles[FileIdx].Code));
      end;
    finally
      FFileList.Items.EndUpdate;
    end;
    FDiff.ShowDiff('Файлов: ' + IntToStr(Length(FFiles)) +
      '. Выберите файл - здесь будет его разница.');
  finally
    Screen.Cursor := crDefault;
  end;
  UpdateButtons;
end;

procedure TDlgGitHistory.ShowFileDiff(AIndex: Integer);
var
  Output: WideString;
  Args: string;
begin
  if (AIndex < 0) or (AIndex > High(FFiles)) or (FCurHash = '') then
    Exit;
  if FCurHasParent then
  begin
    Args := 'diff -M --no-color ' + FCurHash + '^ ' + FCurHash + ' -- ' +
      string(GitQuote(FFiles[AIndex].Path));
    if FFiles[AIndex].OrigPath <> '' then
      Args := Args + ' ' + string(GitQuote(FFiles[AIndex].OrigPath));
  end
  else
    Args := 'show --no-color --format= ' + FCurHash + ' -- ' +
      string(GitQuote(FFiles[AIndex].Path));
  Screen.Cursor := crHourGlass;
  try
    Query(Args, Output);
    if Trim(string(Output)) = '' then
      Output := 'Разницы в тексте нет (двоичный файл, права или ' +
        'переименование без правок).';
    if Length(Output) > GitHistDiffMax then
      Output := Copy(Output, 1, GitHistDiffMax) + #10'... (обрезано)';
    FDiff.ShowDiff(AdjustLineBreaks(string(Output)));
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TDlgGitHistory.CommitSelect(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected and (Item <> nil) then
    ShowCommit(Item.Index);
end;

procedure TDlgGitHistory.FileSelect(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected and (Item <> nil) then
    ShowFileDiff(Item.Index);
end;

procedure TDlgGitHistory.BtnMoreClick(Sender: TObject);
begin
  Inc(FLimit, GitHistPage);
  LoadCommits;
end;

procedure TDlgGitHistory.BtnCopyClick(Sender: TObject);
begin
  if FCurHash <> '' then
    Clipboard.AsText := FCurHash;
end;

procedure TDlgGitHistory.BtnWebClick(Sender: TObject);
begin
  if (FCurHash <> '') and (FWebUrl <> '') then
    ShellExecute(Handle, 'open', PChar(FWebUrl + '/commit/' + FCurHash), nil,
      nil, SW_SHOWNORMAL);
end;

procedure TDlgGitHistory.BtnBranchClick(Sender: TObject);
begin
  if FCurHash = '' then
    Exit;
  FAction := ghaBranch;
  ModalResult := mrOk;
end;

procedure TDlgGitHistory.BtnRevertClick(Sender: TObject);
begin
  if FCurHash = '' then
    Exit;
  FAction := ghaRevert;
  ModalResult := mrOk;
end;

end.
