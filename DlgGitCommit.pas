unit DlgGitCommit;

// ---------------------------------------------------------------------------
//  Окно Commit для меню Repository / панели Git (Unit1): список изменённых
//  файлов с флажками (что войдёт в коммит), разница выбранного файла
//  (git diff - строит Unit1, OnDiff), заголовок и описание коммита, кнопки
//  Commit, Commit and Push, Cancel. Как окно изменений GitHub Desktop.
//
//  Окно строится в коде (CreateDlg), .dfm нет. Коммит делает Unit1:
//  отмеченные файлы (CheckedChanges) и текст (MessageText) забирает после
//  ShowModal = mrOk; PushAfter - нажата Commit and Push.
//
//  Discard Selected - отменить изменения выделенных строк (OnDiscard -
//  Unit1 спрашивает и выполняет; вышло - строки убираются из списка).
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiEdit, TUiMemo
  UiStdCtrls,    // TUiCheckBox, TUiLabel, TUiPanel
  UiComCtrls,    // TUiListView
  GitRun;        // TGitChange

type
  // Разница для файла (текст для показа)
  TGitDiffEvent = function(const AChange: TGitChange): WideString of object;
  // Отменить изменения файлов; True - отменены
  TGitDiscardEvent = function(const AChanges: TGitChanges): Boolean of object;

  TDlgGitCommit = class(TForm)
  private
    FChanges: TGitChanges;
    FOnDiff: TGitDiffEvent;
    FOnDiscard: TGitDiscardEvent;
    FTopPanel: TUiPanel;
    FBtnDiscard: TUiButton;
    FPushAfter: Boolean;
    FLeft: TUiPanel;
    FMsgPanel: TUiPanel;
    FBtnPanel: TUiPanel;
    FChkAll: TUiCheckBox;
    FList: TUiListView;
    FLblSummary: TUiLabel;
    FSummary: TUiEdit;
    FLblDescr: TUiLabel;
    FDescr: TUiMemo;
    FDiff: TUiMemo;
    FSplitter: TSplitter;
    FBtnCommit: TUiButton;
    FBtnPush: TUiButton;
    FBtnCancel: TUiButton;
    FFilling: Boolean;
    procedure ListSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ListChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure ChkAllClick(Sender: TObject);
    procedure BtnDiscardClick(Sender: TObject);
    procedure BtnCommitClick(Sender: TObject);
    procedure BtnPushClick(Sender: TObject);
    procedure LayoutButtons(Sender: TObject);
    procedure UpdateCount;
    function TryClose: Boolean;
    // $0128 - WM_UPDATEUISTATE (кнопки не пропадают по Alt, как в других окнах)
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    constructor CreateDlg(AOwner: TComponent; const ATitle: string;
      const AChanges: TGitChanges; AOnDiff: TGitDiffEvent;
      AOnDiscard: TGitDiscardEvent);
    // Отмеченные файлы
    procedure CheckedChanges(var AList: TGitChanges);
    // Заголовок, пустая строка, описание - как пишет GitHub Desktop
    function MessageText: string;
    property PushAfter: Boolean read FPushAfter;
  end;

implementation

constructor TDlgGitCommit.CreateDlg(AOwner: TComponent; const ATitle: string;
  const AChanges: TGitChanges; AOnDiff: TGitDiffEvent;
  AOnDiscard: TGitDiscardEvent);
var
  ChangeIdx: Integer;
  Item: TListItem;
  Column: TListColumn;
begin
  inherited CreateNew(AOwner);
  FChanges := AChanges;
  FOnDiff := AOnDiff;
  FOnDiscard := AOnDiscard;
  FPushAfter := False;
  Caption := ATitle;
  Position := poMainFormCenter;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Width := 900;
  Height := 600;
  Constraints.MinWidth := 600;
  Constraints.MinHeight := 400;
  KeyPreview := True;

  FLeft := TUiPanel.Create(Self);
  FLeft.Parent := Self;
  FLeft.Align := alLeft;
  FLeft.Width := 340;
  FLeft.BevelOuter := bvNone;
  FLeft.Caption := '';

  FSplitter := TSplitter.Create(Self);
  FSplitter.Parent := Self;
  FSplitter.Align := alLeft;
  FSplitter.Left := FLeft.Width + 1;
  FSplitter.Width := 5;

  FDiff := TUiMemo.Create(Self);
  FDiff.Parent := Self;
  FDiff.Align := alClient;
  FDiff.ReadOnly := True;
  FDiff.WordWrap := False;
  FDiff.ScrollBars := ssBoth;
  FDiff.Font.Name := 'Courier New';
  FDiff.Font.Size := 9;
  FDiff.Lines.Text := 'Выберите файл слева - здесь будет его разница ' +
    '(git diff).';

  // Сверху слева: флажок «все» и Discard Selected
  FTopPanel := TUiPanel.Create(Self);
  FTopPanel.Parent := FLeft;
  FTopPanel.Align := alTop;
  FTopPanel.Height := 28;
  FTopPanel.BevelOuter := bvNone;
  FTopPanel.Caption := '';

  FChkAll := TUiCheckBox.Create(Self);
  FChkAll.Parent := FTopPanel;
  FChkAll.SetBounds(2, 4, 200, 20);
  FChkAll.Checked := True;
  FChkAll.OnClick := ChkAllClick;

  FBtnDiscard := TUiButton.Create(Self);
  FBtnDiscard.Parent := FTopPanel;
  FBtnDiscard.SetBounds(FLeft.Width - 122, 2, 118, 23);
  FBtnDiscard.Anchors := [akTop, akRight];
  FBtnDiscard.Caption := 'Discard Selected...';
  FBtnDiscard.Hint := 'Отменить изменения выделенных строк (не флажков): ' +
    'файлы - как в последнем коммите, новые файлы - в корзину';
  FBtnDiscard.ShowHint := True;
  FBtnDiscard.OnClick := BtnDiscardClick;
  FBtnDiscard.Visible := Assigned(AOnDiscard);

  // Низ левой части: заголовок, описание, кнопки
  FMsgPanel := TUiPanel.Create(Self);
  FMsgPanel.Parent := FLeft;
  FMsgPanel.Align := alBottom;
  FMsgPanel.Height := 200;
  FMsgPanel.BevelOuter := bvNone;
  FMsgPanel.Caption := '';

  // У TUiEdit нет Align - место и якоря вручную (ширина панели - как у
  // левой части)
  FLblSummary := TUiLabel.Create(Self);
  FLblSummary.Parent := FMsgPanel;
  FLblSummary.SetBounds(2, 4, 300, 16);
  FLblSummary.Caption := 'Заголовок (Summary, обязательно):';

  FSummary := TUiEdit.Create(Self);
  FSummary.Parent := FMsgPanel;
  FSummary.SetBounds(2, 22, FLeft.Width - 4, 22);
  FSummary.Anchors := [akLeft, akTop, akRight];

  FLblDescr := TUiLabel.Create(Self);
  FLblDescr.Parent := FMsgPanel;
  FLblDescr.SetBounds(2, 50, 300, 16);
  FLblDescr.Caption := 'Описание (Description):';

  FBtnPanel := TUiPanel.Create(Self);
  FBtnPanel.Parent := FMsgPanel;
  FBtnPanel.Align := alBottom;
  FBtnPanel.Height := 34;
  FBtnPanel.BevelOuter := bvNone;
  FBtnPanel.Caption := '';
  FBtnPanel.OnResize := LayoutButtons;

  FDescr := TUiMemo.Create(Self);
  FDescr.Parent := FMsgPanel;
  FDescr.SetBounds(2, 68, FLeft.Width - 4,
    FMsgPanel.Height - 68 - FBtnPanel.Height - 4);
  FDescr.Anchors := [akLeft, akTop, akRight, akBottom];
  FDescr.ScrollBars := ssVertical;

  FBtnCommit := TUiButton.Create(Self);
  FBtnCommit.Parent := FBtnPanel;
  FBtnCommit.Caption := 'Commit';
  FBtnCommit.Default := True;
  FBtnCommit.OnClick := BtnCommitClick;
  FBtnCommit.Hint := 'Закоммитить отмеченные файлы в текущую ветку';
  FBtnCommit.ShowHint := True;

  FBtnPush := TUiButton.Create(Self);
  FBtnPush.Parent := FBtnPanel;
  FBtnPush.Caption := 'Commit and Push';
  FBtnPush.OnClick := BtnPushClick;
  FBtnPush.Hint := 'Закоммитить и сразу отправить на сервер (git push)';
  FBtnPush.ShowHint := True;

  FBtnCancel := TUiButton.Create(Self);
  FBtnCancel.Parent := FBtnPanel;
  FBtnCancel.Caption := 'Cancel';
  FBtnCancel.Cancel := True;
  FBtnCancel.ModalResult := mrCancel;

  FList := TUiListView.Create(Self);
  FList.Parent := FLeft;
  FList.Align := alClient;
  FList.ViewStyle := vsReport;
  FList.Checkboxes := True;
  FList.ReadOnly := True;
  FList.RowSelect := True;
  FList.MultiSelect := True;
  FList.HideSelection := False;
  Column := FList.Columns.Add;
  Column.Caption := 'Файл';
  Column.Width := 230;
  Column := FList.Columns.Add;
  Column.Caption := 'Что';
  Column.Width := 90;
  FFilling := True;
  try
    for ChangeIdx := 0 to High(FChanges) do
    begin
      Item := FList.Items.Add;
      if FChanges[ChangeIdx].OrigPath <> '' then
        Item.Caption := string(GitWinPath(FChanges[ChangeIdx].Path)) + '  <-  ' +
          string(GitWinPath(FChanges[ChangeIdx].OrigPath))
      else
        Item.Caption := string(GitWinPath(FChanges[ChangeIdx].Path));
      Item.SubItems.Add(GitChangeText(FChanges[ChangeIdx].Code));
      Item.Checked := True;
      Item.Data := Pointer(ChangeIdx);
    end;
  finally
    FFilling := False;
  end;
  FList.OnSelectItem := ListSelect;
  FList.OnChange := ListChange;
  UpdateCount;
  ActiveControl := FSummary;
end;

procedure TDlgGitCommit.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgGitCommit.LayoutButtons(Sender: TObject);
const
  BtnGap = 6;
  BtnH = 24;
var
  BtnTop, BtnLeft: Integer;
begin
  BtnTop := (FBtnPanel.ClientHeight - BtnH) div 2;
  BtnLeft := 0;
  FBtnCommit.SetBounds(BtnLeft, BtnTop, 80, BtnH);
  Inc(BtnLeft, 80 + BtnGap);
  FBtnPush.SetBounds(BtnLeft, BtnTop, 120, BtnH);
  FBtnCancel.SetBounds(FBtnPanel.ClientWidth - 70, BtnTop, 70, BtnH);
end;

procedure TDlgGitCommit.UpdateCount;
var
  ItemIdx, CheckedCount: Integer;
begin
  CheckedCount := 0;
  for ItemIdx := 0 to FList.Items.Count - 1 do
    if FList.Items[ItemIdx].Checked then
      Inc(CheckedCount);
  FChkAll.Caption := 'Изменения: ' + IntToStr(CheckedCount) + ' из ' +
    IntToStr(FList.Items.Count) + ' отмечено';
end;

procedure TDlgGitCommit.ListSelect(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  ChangeIdx: Integer;
begin
  if FFilling or not Selected or (Item = nil) or not Assigned(FOnDiff) then
    Exit;
  ChangeIdx := Integer(Item.Data);
  if (ChangeIdx < 0) or (ChangeIdx > High(FChanges)) then
    Exit;
  Screen.Cursor := crHourGlass;
  try
    FDiff.Lines.Text := string(FOnDiff(FChanges[ChangeIdx]));
  finally
    Screen.Cursor := crDefault;
  end;
end;

// Флажок строки поменялся (щелчок, пробел) - пересчёт
procedure TDlgGitCommit.ListChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
  if not FFilling and (Change = ctState) then
    UpdateCount;
end;

procedure TDlgGitCommit.ChkAllClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  FFilling := True;
  try
    for ItemIdx := 0 to FList.Items.Count - 1 do
      FList.Items[ItemIdx].Checked := FChkAll.Checked;
  finally
    FFilling := False;
  end;
  UpdateCount;
end;

// Discard Selected: выделенные строки - в OnDiscard; вышло - убрать их
procedure TDlgGitCommit.BtnDiscardClick(Sender: TObject);
var
  ItemIdx, ChangeIdx, Count: Integer;
  Picked: TGitChanges;
begin
  if not Assigned(FOnDiscard) then
    Exit;
  SetLength(Picked, 0);
  Count := 0;
  for ItemIdx := 0 to FList.Items.Count - 1 do
    if FList.Items[ItemIdx].Selected then
    begin
      ChangeIdx := Integer(FList.Items[ItemIdx].Data);
      if (ChangeIdx < 0) or (ChangeIdx > High(FChanges)) then
        Continue;
      SetLength(Picked, Count + 1);
      Picked[Count] := FChanges[ChangeIdx];
      Inc(Count);
    end;
  if Count = 0 then
  begin
    MessageBox(Handle, 'Выделите строки (щелчок, Ctrl+щелчок, Shift+щелчок) ' +
      '- изменения каких файлов отменить.', 'Discard', MB_OK or
      MB_ICONINFORMATION);
    Exit;
  end;
  if not FOnDiscard(Picked) then
    Exit;
  FFilling := True;
  try
    for ItemIdx := FList.Items.Count - 1 downto 0 do
      if FList.Items[ItemIdx].Selected then
        FList.Items[ItemIdx].Delete;
  finally
    FFilling := False;
  end;
  FDiff.Lines.Text := '';
  UpdateCount;
  if FList.Items.Count = 0 then
    ModalResult := mrCancel;
end;

function TDlgGitCommit.TryClose: Boolean;
var
  ItemIdx: Integer;
  AnyChecked: Boolean;
begin
  Result := False;
  AnyChecked := False;
  for ItemIdx := 0 to FList.Items.Count - 1 do
    if FList.Items[ItemIdx].Checked then
      AnyChecked := True;
  if not AnyChecked then
  begin
    MessageBox(Handle, 'Не отмечено ни одного файла.', 'Commit',
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if Trim(FSummary.Text) = '' then
  begin
    MessageBox(Handle, 'Нужен заголовок коммита (Summary).', 'Commit',
      MB_OK or MB_ICONINFORMATION);
    if FSummary.CanFocus then
      FSummary.SetFocus;
    Exit;
  end;
  Result := True;
end;

procedure TDlgGitCommit.BtnCommitClick(Sender: TObject);
begin
  if not TryClose then
    Exit;
  FPushAfter := False;
  ModalResult := mrOk;
end;

procedure TDlgGitCommit.BtnPushClick(Sender: TObject);
begin
  if not TryClose then
    Exit;
  FPushAfter := True;
  ModalResult := mrOk;
end;

procedure TDlgGitCommit.CheckedChanges(var AList: TGitChanges);
var
  ItemIdx, ChangeIdx, Count: Integer;
begin
  SetLength(AList, 0);
  Count := 0;
  for ItemIdx := 0 to FList.Items.Count - 1 do
    if FList.Items[ItemIdx].Checked then
    begin
      ChangeIdx := Integer(FList.Items[ItemIdx].Data);
      if (ChangeIdx < 0) or (ChangeIdx > High(FChanges)) then
        Continue;
      SetLength(AList, Count + 1);
      AList[Count] := FChanges[ChangeIdx];
      Inc(Count);
    end;
end;

function TDlgGitCommit.MessageText: string;
begin
  Result := Trim(FSummary.Text);
  if Trim(FDescr.Lines.Text) <> '' then
    Result := Result + #10#10 + TrimRight(FDescr.Lines.Text);
end;

end.
