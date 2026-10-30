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
//  В History коммиты, которых нет на сервере (не отправлены: git rev-list
//  @{u}..HEAD; ветки на сервере нет - --not --remotes), - оранжевым.
//
//  Сравнение веток (панель Git - Compare...): ARevs = 'A...B' - коммиты,
//  которые есть только в одной из веток (git log --left-right). Первый
//  столбец - ветка, строки - цветом своей ветки. Revert в этом режиме нет:
//  коммит может быть не из текущей ветки.
//
//  Коммиты не в основной ветке (панель Git - Unmerged..., CreateUnmerged):
//  у каждой ветки из списка - коммиты, которых нет в ABase (git log
//  --right-only --cherry-pick: перенесённые cherry-pick'ом с тем же
//  содержимым не в счёт), в одной таблице, цвет - свой у каждой ветки.
//  Коммит в нескольких ветках - одна строка, ветки через запятую. Кнопки
//  Cherry-pick (выделенные коммиты - в текущую ветку), Merge Branch
//  (ветку выделенного коммита - целиком), Delete Branch - выполняет
//  Unit1 после закрытия окна (Action, SelectedHashes, ActionBranch) и
//  открывает окно снова. Сколько коммитов у каждой ветки не в ABase -
//  в Objects списка ABranchRefs.
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
  IniBuf,        // TBufIniFile - положение окна в editor.ini
  GitRun;        // TGitCommit, разбор вывода

type
  // Тихий запуск git с аргументами AArgs; результат - код выхода
  // Ход долгой загрузки (Unmerged): текст для жёлтой панели Unit1
  TGitProgressEvent = procedure(const AText: string) of object;

  TGitQueryEvent = function(const AArgs: string;
    var AOutput: WideString): Integer of object;

  // Что сделать после закрытия окна
  TGitHistAction = (ghaNone, ghaBranch, ghaRevert, ghaCherryPick,
    ghaMergeBranch, ghaDeleteBranch, ghaWorktree, ghaBisectGood,
    ghaBisectBad, ghaBisectSkip, ghaBisectEnd);

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
    FRevs: string;          // что показывать: 'HEAD' или 'A...B'
    FCompare: Boolean;      // сравнение веток (FRevs с '...')
    FUnmerged: Boolean;     // коммиты веток, которых нет в FBase
    FBase: string;
    // Ветки (Names) и их ссылки через пробел (Values: 'x origin/x');
    // Objects - сколько коммитов ветки не в FBase. Список - Unit1
    FBranchRefs: TStrings;
    // У каждого коммита FCommits: ветки (через ', ') и номер цвета
    // (-1 - цвет списка; History: неотправленный - GitUnpushedColor)
    FCommitBranch: array of string;
    FCommitColor: array of Integer;
    FSelHashes: TStringList;
    FActionBranch: string;
    // Сведения о коммите - после того, как выделение перестало меняться
    // (CommitSelect, SelTimerTick)
    FSelTimer: TTimer;
    // Положение окна, разделителей и ширина колонок - в файле настроек
    // (SetPlacementIni), раздел по виду окна (PlaceSection)
    FIniFile: string;
    FPlaceSaved: Boolean;
    // Немодальное окно (History, ShowModeless): New Branch / Revert -
    // сразу FOnAction, окно остаётся; FOnDone - окно уничтожается
    FModeless: Boolean;
    FOnAction: TNotifyEvent;
    FOnDone: TNotifyEvent;
    FBtnPick: TUiButton;
    FBtnMergeBranch: TUiButton;
    FBtnDelBranch: TUiButton;
    FOnProgress: TGitProgressEvent;
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
    FBtnWorktree: TUiButton;
    // Поиск регрессии (git bisect) в копии Checkout to Folder
    FBtnGood: TUiButton;
    FBtnBad: TUiButton;
    FBtnSkip: TUiButton;
    FBtnBisectEnd: TUiButton;
    FBtnClose: TUiButton;
    procedure Build(const ATitle: string);
    procedure LoadCommits;
    procedure LoadUnmerged;
    procedure FillList;
    function BranchColor(AIndex: Integer): TColor;
    procedure ListCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure ListCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure BtnPickClick(Sender: TObject);
    procedure BtnMergeBranchClick(Sender: TObject);
    procedure BtnDelBranchClick(Sender: TObject);
    function FirstBranchOf(AIndex: Integer): string;
    procedure ShowCommit(AIndex: Integer);
    procedure ShowFileDiff(AIndex: Integer);
    procedure CommitSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure SelTimerTick(Sender: TObject);
    function  PlaceSection: string;
    procedure LoadPlacement;
    procedure SavePlacement;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnCloseClick(Sender: TObject);
    procedure FileSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure BtnMoreClick(Sender: TObject);
    procedure BtnCopyClick(Sender: TObject);
    procedure BtnWebClick(Sender: TObject);
    procedure BtnBranchClick(Sender: TObject);
    procedure BtnRevertClick(Sender: TObject);
    procedure BtnWorktreeClick(Sender: TObject);
    procedure BtnBisectClick(Sender: TObject);
    procedure DoAction(AAction: TGitHistAction);
    procedure LayoutButtons(Sender: TObject);
    function Query(const AArgs: string; var AOutput: WideString): Integer;
    procedure UpdateButtons;
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateDlg(AOwner: TComponent; const ATitle, AWebUrl: string;
      AOnQuery: TGitQueryEvent; const ARevs: string = 'HEAD');
    constructor CreateUnmerged(AOwner: TComponent; const ATitle,
      AWebUrl: string; AOnQuery: TGitQueryEvent; const ABase: string;
      ABranchRefs: TStrings; AOnProgress: TGitProgressEvent = nil);
    destructor Destroy; override;
    // Положение и размер окна, разделители, ширина колонок списка - из
    // файла настроек AIniFile; при закрытии - туда же
    procedure SetPlacementIni(const AIniFile: string);
    // Показать немодальным: New Branch from Commit, Revert Commit и
    // Checkout to Folder - сразу
    // AOnAction (Action, SelectedHash), окно остаётся; AOnDone - окно
    // уничтожается
    procedure ShowModeless(AOnAction, AOnDone: TNotifyEvent);
    // Коммиты заново (после действия в немодальном окне)
    procedure ReloadCommits;
    // Выделить коммит AHash (полный или начало) и показать его; False -
    // его нет среди загруженных
    function SelectCommit(const AHash: string): Boolean;
    property Action: TGitHistAction read FAction;
    property SelectedHash: string read FCurHash;
    // Cherry-pick: выделенные коммиты, от старых к новым
    property SelectedHashes: TStringList read FSelHashes;
    // Merge Branch: ветка выделенного коммита ('' - нет); Delete Branch:
    // ветки всех выделенных коммитов через ', '
    property ActionBranch: string read FActionBranch;
    // Схема подсветки кода в разнице (Unit1.SchemeCopyFor)
    procedure SetSchemeProvider(AProvider: TGitSchemeEvent);
  end;

const
  GitHistPage = 500;        // столько коммитов за раз (Load More - ещё)
  GitHistDiffMax = 300000;  // разница длиннее - обрезается
  GitBranchColorCount = 8;  // цветов веток; дальше - по кругу
  GitUnpushedColor = 6;     // History: неотправленный коммит - оранжевый

implementation

constructor TDlgGitHistory.CreateDlg(AOwner: TComponent; const ATitle,
  AWebUrl: string; AOnQuery: TGitQueryEvent; const ARevs: string);
begin
  inherited CreateNew(AOwner);
  FOnQuery := AOnQuery;
  FRevs := ARevs;
  if FRevs = '' then
    FRevs := 'HEAD';
  FCompare := Pos('...', FRevs) > 0;
  FWebUrl := AWebUrl;
  Build(ATitle);
end;

constructor TDlgGitHistory.CreateUnmerged(AOwner: TComponent; const ATitle,
  AWebUrl: string; AOnQuery: TGitQueryEvent; const ABase: string;
  ABranchRefs: TStrings; AOnProgress: TGitProgressEvent);
begin
  inherited CreateNew(AOwner);
  FOnQuery := AOnQuery;
  FOnProgress := AOnProgress;
  FUnmerged := True;
  FBase := ABase;
  FBranchRefs := ABranchRefs;
  FRevs := ABase;
  FWebUrl := AWebUrl;
  Build(ATitle);
end;

destructor TDlgGitHistory.Destroy;
begin
  // Закрыли не крестиком (программа выходит при открытом окне)
  if not FPlaceSaved then
    SavePlacement;
  if Assigned(FOnDone) then
    FOnDone(Self);
  FSelHashes.Free;
  inherited Destroy;
end;

// Окно - общее для History, Compare и Unmerged
procedure TDlgGitHistory.Build(const ATitle: string);
var
  Column: TListColumn;
begin
  FSelHashes := TStringList.Create;
  FSelTimer := TTimer.Create(Self);
  FSelTimer.Enabled := False;
  FSelTimer.Interval := 40;
  FSelTimer.OnTimer := SelTimerTick;
  FAction := ghaNone;
  FCurHash := '';
  FLimit := GitHistPage;
  Caption := ATitle;
  OnClose := FormClose;
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
  if FCompare or FUnmerged then
  begin
    Column := FCommitList.Columns.Add;
    Column.Caption := 'Ветка';
    Column.Width := 130;
  end;
  FCommitList.OnCustomDrawItem := ListCustomDrawItem;
  FCommitList.OnCustomDrawSubItem := ListCustomDrawSubItem;
  // Cherry-pick - сразу несколько коммитов
  FCommitList.MultiSelect := FUnmerged;
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
  FBtnRevert.Visible := not FCompare and not FUnmerged;

  FBtnWorktree := TUiButton.Create(Self);
  FBtnWorktree.Parent := FBtnPanel;
  FBtnWorktree.Caption := 'Checkout to Folder...';
  FBtnWorktree.Hint := 'Копия рабочей папки в состоянии выбранного ' +
    'коммита: <папка репозитория>-<SHA>, рядом с репозиторием, - собрать ' +
    'и проверить. Файлы вне git - из рабочей папки; другой коммит - та же ' +
    'копия переименовывается. Рабочая папка и ветка не меняются';
  FBtnWorktree.ShowHint := True;
  FBtnWorktree.OnClick := BtnWorktreeClick;
  FBtnWorktree.Visible := not FCompare and not FUnmerged;

  FBtnGood := TUiButton.Create(Self);
  FBtnGood.Parent := FBtnPanel;
  FBtnGood.Caption := 'Good';
  FBtnGood.Hint := 'Поиск регрессии (git bisect в копии Checkout to ' +
    'Folder): выбранный коммит хороший - ошибки в нём нет. Когда отмечены ' +
    'и хороший, и плохой, копия переключается на коммит посередине: ' +
    'собрать, проверить, отметить его';
  FBtnGood.ShowHint := True;
  FBtnGood.Tag := Ord(ghaBisectGood);
  FBtnGood.OnClick := BtnBisectClick;
  FBtnGood.Visible := not FCompare and not FUnmerged;

  FBtnBad := TUiButton.Create(Self);
  FBtnBad.Parent := FBtnPanel;
  FBtnBad.Caption := 'Bad';
  FBtnBad.Hint := 'Поиск регрессии: выбранный коммит плохой - ошибка в ' +
    'нём есть';
  FBtnBad.ShowHint := True;
  FBtnBad.Tag := Ord(ghaBisectBad);
  FBtnBad.OnClick := BtnBisectClick;
  FBtnBad.Visible := not FCompare and not FUnmerged;

  FBtnSkip := TUiButton.Create(Self);
  FBtnSkip.Parent := FBtnPanel;
  FBtnSkip.Caption := 'Skip';
  FBtnSkip.Hint := 'Поиск регрессии: выбранный коммит не проверить (не ' +
    'собирается) - git возьмёт соседний';
  FBtnSkip.ShowHint := True;
  FBtnSkip.Tag := Ord(ghaBisectSkip);
  FBtnSkip.OnClick := BtnBisectClick;
  FBtnSkip.Visible := not FCompare and not FUnmerged;

  FBtnBisectEnd := TUiButton.Create(Self);
  FBtnBisectEnd.Parent := FBtnPanel;
  FBtnBisectEnd.Caption := 'End Bisect';
  FBtnBisectEnd.Hint := 'Закончить поиск регрессии (git bisect reset): ' +
    'копия возвращается на коммит, с которого поиск начался';
  FBtnBisectEnd.ShowHint := True;
  FBtnBisectEnd.Tag := Ord(ghaBisectEnd);
  FBtnBisectEnd.OnClick := BtnBisectClick;
  FBtnBisectEnd.Visible := not FCompare and not FUnmerged;

  FBtnPick := TUiButton.Create(Self);
  FBtnPick.Parent := FBtnPanel;
  FBtnPick.Caption := 'Cherry-pick';
  FBtnPick.Hint := 'Перенести выделенные коммиты в ' + FBase +
    ' (git cherry-pick -x, от старых к новым)';
  FBtnPick.ShowHint := True;
  FBtnPick.OnClick := BtnPickClick;
  FBtnPick.Visible := FUnmerged;

  FBtnMergeBranch := TUiButton.Create(Self);
  FBtnMergeBranch.Parent := FBtnPanel;
  FBtnMergeBranch.Caption := 'Merge Branch';
  FBtnMergeBranch.Hint := 'Влить в ' + FBase + ' ветку выделенного коммита ' +
    'целиком (git merge)';
  FBtnMergeBranch.ShowHint := True;
  FBtnMergeBranch.OnClick := BtnMergeBranchClick;
  FBtnMergeBranch.Visible := FUnmerged;

  FBtnDelBranch := TUiButton.Create(Self);
  FBtnDelBranch.Parent := FBtnPanel;
  FBtnDelBranch.Caption := 'Delete Branch';
  FBtnDelBranch.Hint := 'Удалить ветку выделенного коммита - локальную и ' +
    'на сервере. Выделенные коммиты из нескольких веток или ничего не ' +
    'выделено (Ctrl+щелчок снимает выделение) - выбор веток из списка';
  FBtnDelBranch.ShowHint := True;
  FBtnDelBranch.OnClick := BtnDelBranchClick;
  FBtnDelBranch.Visible := FUnmerged;

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

// Владелец окна - главное окно (а не скрытое окно Application, как по
// умолчанию в Delphi 7): модальное окно всегда над ним, не уходит под
// него, когда фокус в момент открытия у другой программы (git, Git Bash)
procedure TDlgGitHistory.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if (Owner is TWinControl) and TWinControl(Owner).HandleAllocated then
    Params.WndParent := TWinControl(Owner).Handle;
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
  if FBtnRevert.Visible then
    Place(FBtnRevert, 100);
  if FBtnWorktree.Visible then
    Place(FBtnWorktree, 130);
  if FBtnGood.Visible then
  begin
    Place(FBtnGood, 50);
    Place(FBtnBad, 50);
    Place(FBtnSkip, 50);
    Place(FBtnBisectEnd, 84);
  end;
  if FUnmerged then
  begin
    Place(FBtnPick, 84);
    Place(FBtnMergeBranch, 100);
    Place(FBtnDelBranch, 110);
  end;
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
  FBtnWorktree.Enabled := HasCommit;
  FBtnGood.Enabled := HasCommit;
  FBtnBad.Enabled := HasCommit;
  FBtnSkip.Enabled := HasCommit;
  FBtnPick.Enabled := FCommitList.SelCount > 0;
  FBtnMergeBranch.Enabled := HasCommit;
end;

// Коммиты текущей ветки: первые FLimit
procedure TDlgGitHistory.LoadCommits;
var
  Output: WideString;
  CommitIdx, UnpushedCount: Integer;
  LogArgs, LeftName, RightName: string;
  Unpushed: TStringList;
begin
  if FUnmerged then
  begin
    LoadUnmerged;
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    // Сравнение: %m - '<' или '>' (с какой стороны коммит) перед заголовком;
    // пробел - %x20: аргумент без кавычек
    if FCompare then
      LogArgs := 'log --left-right --format=%H%x1f%h%x1f%an%x1f%ad%x1f' +
        '%m%x20%s%x1e --date=iso'
    else
      LogArgs := 'log ' + GitLogFormat;
    if Query(LogArgs + ' -n ' + IntToStr(FLimit) + ' ' + FRevs,
       Output) <> 0 then
    begin
      SetLength(FCommits, 0);
      FLblInfo.Caption := 'История пуста (коммитов ещё нет) или git log не ' +
        'вышел';
    end
    else
      GitParseLog(Output, FCommits);
    SetLength(FCommitBranch, Length(FCommits));
    SetLength(FCommitColor, Length(FCommits));
    for CommitIdx := 0 to High(FCommits) do
      FCommitColor[CommitIdx] := -1;
    UnpushedCount := 0;
    if not FCompare and (Length(FCommits) > 0) then
    begin
      // Неотправленные: нет в ветке на сервере (@{u}); ветки там нет -
      // нет ни в одной ветке с сервера
      Unpushed := TStringList.Create;
      try
        if Query('rev-list @{u}..' + FRevs, Output) <> 0 then
          if Query('rev-list ' + FRevs + ' --not --remotes', Output) <> 0 then
            Output := '';
        Unpushed.Text := string(Output);
        Unpushed.Sorted := True;
        for CommitIdx := 0 to High(FCommits) do
          if Unpushed.IndexOf(FCommits[CommitIdx].Hash) >= 0 then
          begin
            FCommitColor[CommitIdx] := GitUnpushedColor;
            Inc(UnpushedCount);
          end;
      finally
        Unpushed.Free;
      end;
    end;
    if FCompare then
    begin
      LeftName := Copy(FRevs, 1, Pos('...', FRevs) - 1);
      RightName := Copy(FRevs, Pos('...', FRevs) + 3, MaxInt);
      // '<' / '>' в начале заголовка - сторона: ветка и цвет вместо стрелки
      for CommitIdx := 0 to High(FCommits) do
      begin
        if Copy(FCommits[CommitIdx].Subject, 1, 1) = '<' then
        begin
          FCommitBranch[CommitIdx] := LeftName;
          FCommitColor[CommitIdx] := 0;
        end
        else
        begin
          FCommitBranch[CommitIdx] := RightName;
          FCommitColor[CommitIdx] := 1;
        end;
        FCommits[CommitIdx].Subject := Copy(FCommits[CommitIdx].Subject, 3,
          MaxInt);
      end;
    end;
    FillList;
    if Length(FCommits) > 0 then
      FLblInfo.Caption := 'Коммитов показано: ' + IntToStr(Length(FCommits));
    if UnpushedCount > 0 then
      FLblInfo.Caption := FLblInfo.Caption + ';  не отправлено на сервер: ' +
        IntToStr(UnpushedCount) + ' (оранжевые)';
    if FCompare and (Length(FCommits) = 0) and (Output = '') then
      FLblInfo.Caption := 'Различающихся коммитов нет: ветки на одном ' +
        'коммите';
    FBtnMore.Enabled := Length(FCommits) >= FLimit;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// Список - по FCommits (и FCommitBranch в сравнении и Unmerged)
procedure TDlgGitHistory.FillList;
var
  CommitIdx, KeepIdx: Integer;
  Item: TListItem;
begin
  KeepIdx := -1;
  if FCommitList.Selected <> nil then
    KeepIdx := FCommitList.Selected.Index;
  FCommitList.Items.BeginUpdate;
  try
    FCommitList.Items.Clear;
    for CommitIdx := 0 to High(FCommits) do
    begin
      Item := FCommitList.Items.Add;
      if FCompare or FUnmerged then
      begin
        Item.Caption := FCommitBranch[CommitIdx];
        Item.SubItems.Add(string(FCommits[CommitIdx].Subject));
      end
      else
        Item.Caption := string(FCommits[CommitIdx].Subject);
      Item.SubItems.Add(string(FCommits[CommitIdx].Author));
      Item.SubItems.Add(FCommits[CommitIdx].Date);
      Item.SubItems.Add(FCommits[CommitIdx].Short);
    end;
  finally
    FCommitList.Items.EndUpdate;
  end;
  if (KeepIdx >= 0) and (KeepIdx < FCommitList.Items.Count) then
    FCommitList.Items[KeepIdx].Selected := True;
end;

// Коммиты веток FBranchRefs, которых нет в FBase: по веткам подряд, у
// каждой - от новых к старым. --cherry-pick: коммит с тем же изменением,
// что уже есть в FBase (перенесён cherry-pick'ом), не показывается
procedure TDlgGitHistory.LoadUnmerged;
var
  Output: WideString;
  Part: TGitCommits;
  Refs, Seen, BranchHashes, Picked, BodyLines: TStringList;
  BranchIdx, RefIdx, PartIdx, Found, Count, BranchesWith, LineIdx,
  MarkPos, PickedCount: Integer;
  Name, Line: string;
const
  PickMark = 'cherry picked from commit ';
begin
  Screen.Cursor := crHourGlass;
  Refs := TStringList.Create;
  Seen := TStringList.Create;
  BranchHashes := TStringList.Create;
  Picked := TStringList.Create;
  BodyLines := TStringList.Create;
  try
    Seen.Sorted := True;
    BranchHashes.Sorted := True;
    Picked.Sorted := True;
    PickedCount := 0;
    // Уже перенесённые в FBase cherry-pick -x: их SHA - в строке
    // "(cherry picked from commit <SHA>)" коммита FBase. Если при переносе
    // разрешали конфликт, изменение отличается от исходного, и --cherry-pick
    // его не узнаёт - такие коммиты пропускаются по этой строке
    if Assigned(FOnProgress) then
      FOnProgress('Unmerged: что уже перенесено в ' + FBase);
    if Query('log --grep=cherry.picked.from.commit --format=%b ' + FBase,
       Output) = 0 then
    begin
      BodyLines.Text := string(Output);
      for LineIdx := 0 to BodyLines.Count - 1 do
      begin
        Line := BodyLines[LineIdx];
        MarkPos := Pos(PickMark, Line);
        if MarkPos > 0 then
          Picked.Add(LowerCase(Copy(Line, MarkPos + Length(PickMark), 40)));
      end;
    end;
    SetLength(FCommits, 0);
    SetLength(FCommitBranch, 0);
    SetLength(FCommitColor, 0);
    Count := 0;
    BranchesWith := 0;
    for BranchIdx := 0 to FBranchRefs.Count - 1 do
    begin
      Name := FBranchRefs.Names[BranchIdx];
      Refs.Delimiter := ' ';
      Refs.DelimitedText := FBranchRefs.ValueFromIndex[BranchIdx];
      BranchHashes.Clear;
      for RefIdx := 0 to Refs.Count - 1 do
      begin
        if Refs[RefIdx] = '' then
          Continue;
        if Assigned(FOnProgress) then
          FOnProgress('Unmerged: ветка ' + IntToStr(BranchIdx + 1) + ' из ' +
            IntToStr(FBranchRefs.Count) + ' - ' + Refs[RefIdx]);
        if Query('log --right-only --cherry-pick --no-merges ' +
           GitLogFormat + ' -n ' + IntToStr(FLimit) + ' ' + FBase + '...' +
           Refs[RefIdx], Output) <> 0 then
          Continue;
        GitParseLog(Output, Part);
        for PartIdx := 0 to High(Part) do
        begin
          Found := Picked.IndexOf(LowerCase(Part[PartIdx].Hash));
          if Found >= 0 then
          begin
            // Уже перенесён в FBase (cherry-pick -x); считается один раз
            if Picked.Objects[Found] = nil then
            begin
              Picked.Objects[Found] := TObject(1);
              Inc(PickedCount);
            end;
            Continue;
          end;
          if BranchHashes.IndexOf(Part[PartIdx].Hash) >= 0 then
            Continue;   // тот же коммит в локальной и в origin/<ветка>
          BranchHashes.Add(Part[PartIdx].Hash);
          Found := Seen.IndexOf(Part[PartIdx].Hash);
          if Found >= 0 then
          begin
            // Уже показан у другой ветки - дописать эту
            Found := Integer(Seen.Objects[Found]);
            FCommitBranch[Found] := FCommitBranch[Found] + ', ' + Name;
            Continue;
          end;
          SetLength(FCommits, Count + 1);
          SetLength(FCommitBranch, Count + 1);
          SetLength(FCommitColor, Count + 1);
          FCommits[Count] := Part[PartIdx];
          FCommitBranch[Count] := Name;
          FCommitColor[Count] := BranchIdx mod GitBranchColorCount;
          Seen.AddObject(Part[PartIdx].Hash, TObject(Count));
          Inc(Count);
        end;
      end;
      FBranchRefs.Objects[BranchIdx] := TObject(BranchHashes.Count);
      if BranchHashes.Count > 0 then
        Inc(BranchesWith);
    end;
    FillList;
    if Count = 0 then
      FLblInfo.Caption := 'Коммитов, которых нет в ' + FBase + ', нет ни ' +
        'в одной ветке (веток: ' + IntToStr(FBranchRefs.Count) + ') - ' +
        'ветки можно удалять (Delete Branch)'
    else
      FLblInfo.Caption := 'Не в ' + FBase + ': ' + IntToStr(Count) +
        ' коммит(ов) из ' + IntToStr(BranchesWith) + ' веток; у ' +
        IntToStr(FBranchRefs.Count - BranchesWith) + ' веток всё уже в ' +
        FBase + '. Ctrl / Shift - выделить несколько';
    if PickedCount > 0 then
      FLblInfo.Caption := FLblInfo.Caption + '. Не показаны уже ' +
        'перенесённые (cherry-pick -x): ' + IntToStr(PickedCount);
    FBtnMore.Enabled := False;
    for BranchIdx := 0 to FBranchRefs.Count - 1 do
      if Integer(FBranchRefs.Objects[BranchIdx]) >= FLimit then
        FBtnMore.Enabled := True;
  finally
    BodyLines.Free;
    Picked.Free;
    BranchHashes.Free;
    Seen.Free;
    Refs.Free;
    Screen.Cursor := crDefault;
  end;
end;

// Цвет ветки AIndex на фоне списка: для тёмного и светлого фона свои
function TDlgGitHistory.BranchColor(AIndex: Integer): TColor;
const
  // $00BBGGRR
  DarkColors: array[0..GitBranchColorCount - 1] of TColor = (
    $005A5AFF, $0070D070, $00FFA050, $0040E0F0, $00FF80D0, $00E0D060,
    $0060A0FF, $00C0C0C0);
  LightColors: array[0..GitBranchColorCount - 1] of TColor = (
    $000000C8, $00008000, $00C04000, $000088A8, $00A00080, $00A06000,
    $000060D0, $00606060);
var
  BackRgb: Longint;
  Brightness: Integer;
begin
  AIndex := AIndex mod GitBranchColorCount;
  BackRgb := ColorToRGB(FCommitList.Color);
  Brightness := (GetRValue(BackRgb) * 299 + GetGValue(BackRgb) * 587 +
    GetBValue(BackRgb) * 114) div 1000;
  if Brightness < 128 then
    Result := DarkColors[AIndex]
  else
    Result := LightColors[AIndex];
end;

procedure TDlgGitHistory.ListCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  if (Item <> nil) and (Item.Index <= High(FCommitColor)) and
     (FCommitColor[Item.Index] >= 0) then
    Sender.Canvas.Font.Color := BranchColor(FCommitColor[Item.Index])
  else
    Sender.Canvas.Font.Color := FCommitList.Font.Color;
  DefaultDraw := True;
end;

procedure TDlgGitHistory.ListCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState;
  var DefaultDraw: Boolean);
begin
  ListCustomDrawItem(Sender, Item, State, DefaultDraw);
end;

// Первая ветка коммита AIndex (у коммита их может быть несколько)
function TDlgGitHistory.FirstBranchOf(AIndex: Integer): string;
begin
  Result := '';
  if (AIndex < 0) or (AIndex > High(FCommitBranch)) then
    Exit;
  Result := FCommitBranch[AIndex];
  if Pos(',', Result) > 0 then
    Result := Copy(Result, 1, Pos(',', Result) - 1);
end;

procedure TDlgGitHistory.BtnPickClick(Sender: TObject);
var
  Order: TStringList;
  ItemIdx, OrderIdx: Integer;
begin
  FSelHashes.Clear;
  // От старых к новым: по дате; в одну минуту - ниже в списке раньше
  Order := TStringList.Create;
  try
    Order.Sorted := True;
    for ItemIdx := 0 to FCommitList.Items.Count - 1 do
      if FCommitList.Items[ItemIdx].Selected and
         (ItemIdx <= High(FCommits)) then
        Order.AddObject(FCommits[ItemIdx].Date +
          Format('%.6d', [999999 - ItemIdx]), TObject(ItemIdx));
    for OrderIdx := 0 to Order.Count - 1 do
      FSelHashes.Add(FCommits[Integer(Order.Objects[OrderIdx])].Hash);
  finally
    Order.Free;
  end;
  if FSelHashes.Count = 0 then
    Exit;
  FAction := ghaCherryPick;
  ModalResult := mrOk;
end;

procedure TDlgGitHistory.BtnMergeBranchClick(Sender: TObject);
begin
  if FCommitList.Selected = nil then
    Exit;
  FActionBranch := FirstBranchOf(FCommitList.Selected.Index);
  if FActionBranch = '' then
    Exit;
  FAction := ghaMergeBranch;
  ModalResult := mrOk;
end;

// Delete Branch: все ветки выделенных коммитов, без повторов (через ', ')
procedure TDlgGitHistory.BtnDelBranchClick(Sender: TObject);
var
  ItemIdx: Integer;
  Rest, Name: string;
begin
  FActionBranch := '';
  for ItemIdx := 0 to FCommitList.Items.Count - 1 do
    if FCommitList.Items[ItemIdx].Selected and
       (ItemIdx <= High(FCommitBranch)) then
    begin
      Rest := FCommitBranch[ItemIdx] + ', ';
      while Pos(', ', Rest) > 0 do
      begin
        Name := Copy(Rest, 1, Pos(', ', Rest) - 1);
        Delete(Rest, 1, Pos(', ', Rest) + 1);
        if (Name <> '') and (Pos(', ' + Name + ', ', ', ' + FActionBranch +
           ', ') = 0) then
        begin
          if FActionBranch <> '' then
            FActionBranch := FActionBranch + ', ';
          FActionBranch := FActionBranch + Name;
        end;
      end;
    end;
  FAction := ghaDeleteBranch;
  ModalResult := mrOk;
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

// Выделение в списке коммитов меняется. При Ctrl+A, Shift+щелчке или
// протяжке мышью событие приходит на каждую строку, а ShowCommit - это три
// запуска git (show, rev-parse, diff): на 145 строках выделение шло
// секунды. Поэтому здесь только перезапуск таймера, а сведения читаются
// один раз, когда события кончились (SelTimerTick)
procedure TDlgGitHistory.CommitSelect(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  FSelTimer.Enabled := False;
  FSelTimer.Enabled := True;
end;

// Выделение успокоилось: сведения - о строке с фокусом (по ней щёлкнули
// последней), если она выделена, иначе о первой выделенной. Тот же коммит
// уже показан - git не запускается, обновляются только кнопки
procedure TDlgGitHistory.SelTimerTick(Sender: TObject);
var
  Item: TListItem;
begin
  FSelTimer.Enabled := False;
  Item := FCommitList.ItemFocused;
  if (Item = nil) or not Item.Selected then
    Item := FCommitList.Selected;
  if (Item <> nil) and (Item.Index <= High(FCommits)) and
     (FCommits[Item.Index].Hash <> FCurHash) then
    ShowCommit(Item.Index)
  else
    UpdateButtons;
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
  if FModeless then
  begin
    if Assigned(FOnAction) then
      FOnAction(Self);
  end
  else
    ModalResult := mrOk;
end;

procedure TDlgGitHistory.BtnRevertClick(Sender: TObject);
begin
  if FCurHash = '' then
    Exit;
  FAction := ghaRevert;
  if FModeless then
  begin
    if Assigned(FOnAction) then
      FOnAction(Self);
  end
  else
    ModalResult := mrOk;
end;

procedure TDlgGitHistory.BtnWorktreeClick(Sender: TObject);
begin
  if FCurHash = '' then
    Exit;
  DoAction(ghaWorktree);
end;

// Good / Bad / Skip / End Bisect: действие - в Tag кнопки
procedure TDlgGitHistory.BtnBisectClick(Sender: TObject);
var
  BisectAction: TGitHistAction;
begin
  BisectAction := TGitHistAction((Sender as TUiButton).Tag);
  if (FCurHash = '') and (BisectAction <> ghaBisectEnd) then
    Exit;
  DoAction(BisectAction);
end;

// Немодальное окно - сразу AOnAction, модальное - закрыть с mrOk
procedure TDlgGitHistory.DoAction(AAction: TGitHistAction);
begin
  FAction := AAction;
  if FModeless then
  begin
    if Assigned(FOnAction) then
      FOnAction(Self);
  end
  else
    ModalResult := mrOk;
end;

function TDlgGitHistory.SelectCommit(const AHash: string): Boolean;
var
  CommitIdx: Integer;
begin
  Result := False;
  if AHash = '' then
    Exit;
  for CommitIdx := 0 to High(FCommits) do
    if (CommitIdx < FCommitList.Items.Count) and
       (Copy(FCommits[CommitIdx].Hash, 1, Length(AHash)) = AHash) then
    begin
      FCommitList.ClearSelection;
      FCommitList.Items[CommitIdx].Selected := True;
      FCommitList.ItemFocused := FCommitList.Items[CommitIdx];
      FCommitList.Items[CommitIdx].MakeVisible(False);
      Result := True;
      Exit;
    end;
end;

procedure TDlgGitHistory.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TDlgGitHistory.ShowModeless(AOnAction, AOnDone: TNotifyEvent);
begin
  FModeless := True;
  FOnAction := AOnAction;
  FOnDone := AOnDone;
  // Немодальное окно ModalResult не закрывает - Close кнопкой (и Esc)
  FBtnClose.ModalResult := mrNone;
  FBtnClose.OnClick := BtnCloseClick;
  Show;
end;

procedure TDlgGitHistory.ReloadCommits;
begin
  FAction := ghaNone;
  LoadCommits;
end;

// Закрытие (и модального, и немодального): положение - в файл настроек;
// немодальное - уничтожить
procedure TDlgGitHistory.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SavePlacement;
  if FModeless then
    Action := caFree;
end;

function TDlgGitHistory.PlaceSection: string;
begin
  if FUnmerged then
    Result := 'GitUnmergedWindow'
  else if FCompare then
    Result := 'GitCompareWindow'
  else
    Result := 'GitHistoryWindow';
end;

procedure TDlgGitHistory.SetPlacementIni(const AIniFile: string);
begin
  FIniFile := AIniFile;
  LoadPlacement;
end;

// Положение из файла настроек: окно - в пределах рабочего стола (монитор
// могли сменить); разделители и колонки - если сохранены и не слишком малы
procedure TDlgGitHistory.LoadPlacement;
var
  Ini: TBufIniFile;
  Sect, Widths: string;
  WinLeft, WinTop, WinWidth, WinHeight, PaneSize, ColIdx, CommaPos: Integer;
  Work: TRect;
begin
  if (FIniFile = '') or not FileExists(FIniFile) then
    Exit;
  Sect := PlaceSection;
  Ini := TBufIniFile.Create(FIniFile);
  try
    WinWidth := Ini.ReadInteger(Sect, 'Width', 0);
    WinHeight := Ini.ReadInteger(Sect, 'Height', 0);
    if (WinWidth >= Constraints.MinWidth) and
       (WinHeight >= Constraints.MinHeight) then
    begin
      WinLeft := Ini.ReadInteger(Sect, 'Left', Left);
      WinTop := Ini.ReadInteger(Sect, 'Top', Top);
      Work := Screen.DesktopRect;
      if WinWidth > Work.Right - Work.Left then
        WinWidth := Work.Right - Work.Left;
      if WinHeight > Work.Bottom - Work.Top then
        WinHeight := Work.Bottom - Work.Top;
      if WinLeft + WinWidth > Work.Right then
        WinLeft := Work.Right - WinWidth;
      if WinTop + WinHeight > Work.Bottom then
        WinTop := Work.Bottom - WinHeight;
      if WinLeft < Work.Left then
        WinLeft := Work.Left;
      if WinTop < Work.Top then
        WinTop := Work.Top;
      Position := poDesigned;
      SetBounds(WinLeft, WinTop, WinWidth, WinHeight);
    end;
    PaneSize := Ini.ReadInteger(Sect, 'ListWidth', 0);
    if PaneSize >= 200 then
      FLeft.Width := PaneSize;
    PaneSize := Ini.ReadInteger(Sect, 'DetailsHeight', 0);
    if PaneSize >= 40 then
      FDetails.Height := PaneSize;
    PaneSize := Ini.ReadInteger(Sect, 'FilesHeight', 0);
    if PaneSize >= 40 then
      FFileList.Height := PaneSize;
    // Ширина колонок списка коммитов: через запятую, по порядку
    Widths := Ini.ReadString(Sect, 'Columns', '');
    ColIdx := 0;
    while (Widths <> '') and (ColIdx < FCommitList.Columns.Count) do
    begin
      CommaPos := Pos(',', Widths + ',');
      PaneSize := StrToIntDef(Trim(Copy(Widths, 1, CommaPos - 1)), 0);
      if PaneSize >= 20 then
        FCommitList.Columns[ColIdx].Width := PaneSize;
      Delete(Widths, 1, CommaPos);
      Inc(ColIdx);
    end;
    if Ini.ReadBool(Sect, 'Maximized', False) then
      WindowState := wsMaximized;
  finally
    Ini.Free;
  end;
end;

// Положение в файл настроек: размер «в обычном виде» (и когда окно
// развёрнуто), развёрнуто ли, разделители, ширина колонок
procedure TDlgGitHistory.SavePlacement;
var
  Ini: TBufIniFile;
  Place: TWindowPlacement;
  Sect, Widths: string;
  ColIdx: Integer;
begin
  FPlaceSaved := True;
  if (FIniFile = '') or not HandleAllocated then
    Exit;
  Place.length := SizeOf(Place);
  if not GetWindowPlacement(Handle, @Place) then
    Exit;
  Sect := PlaceSection;
  Widths := '';
  for ColIdx := 0 to FCommitList.Columns.Count - 1 do
  begin
    if ColIdx > 0 then
      Widths := Widths + ',';
    Widths := Widths + IntToStr(FCommitList.Columns[ColIdx].Width);
  end;
  Ini := TBufIniFile.Create(FIniFile);
  try
    Ini.WriteInteger(Sect, 'Left', Place.rcNormalPosition.Left);
    Ini.WriteInteger(Sect, 'Top', Place.rcNormalPosition.Top);
    Ini.WriteInteger(Sect, 'Width', Place.rcNormalPosition.Right -
      Place.rcNormalPosition.Left);
    Ini.WriteInteger(Sect, 'Height', Place.rcNormalPosition.Bottom -
      Place.rcNormalPosition.Top);
    Ini.WriteBool(Sect, 'Maximized', WindowState = wsMaximized);
    Ini.WriteInteger(Sect, 'ListWidth', FLeft.Width);
    Ini.WriteInteger(Sect, 'DetailsHeight', FDetails.Height);
    Ini.WriteInteger(Sect, 'FilesHeight', FFileList.Height);
    Ini.WriteString(Sect, 'Columns', Widths);
  finally
    Ini.Free;
  end;
end;

procedure TDlgGitHistory.SetSchemeProvider(AProvider: TGitSchemeEvent);
begin
  FDiff.OnScheme := AProvider;
end;

end.
