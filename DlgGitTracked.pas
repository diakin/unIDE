unit DlgGitTracked;

// ---------------------------------------------------------------------------
//  Окно Tracked but Ignored (меню Branch, панель Git): файлы, которые лежат
//  в репозитории, хотя подходят под правила .gitignore (git ls-files -ci
//  --exclude-standard). На такие файлы .gitignore не действует: git их
//  отслеживает дальше. Проверка Git status на панели считает их как
//  «Внимание».
//
//  Для отмеченных флажками файлов - одна из двух кнопок:
//  - Оставить в репозитории: в .gitignore дописывается исключение !путь,
//    и проверка о файле больше не говорит;
//  - Убрать из репозитория: git rm --cached - файл остаётся на диске, из
//    репозитория уходит следующим коммитом, .gitignore дальше его не
//    пускает.
//  Отмечать помогают кнопки: все, ни одного, все с тем же правилом, что у
//  выделенной строки, вся папка выделенной строки.
//
//  Окно строится в коде, .dfm нет. Список и действия - у Unit1 (OnLoad,
//  OnKeep, OnUntrack: спрашивают и выполняют сами); после действия список
//  перечитывается, флажки оставшихся строк сохраняются.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls,
  UiButton,      // TUiButton
  UiStdCtrls,    // TUiLabel, TUiPanel
  UiComCtrls,    // TUiListView
  GitRun;        // TGitTrackedFile

type
  // Прочитать список заново; False - не вышло
  TGitTrackedLoadEvent = function(var AFiles: TGitTrackedFiles): Boolean
    of object;
  // Действие над файлами; True - сделано (список нужно перечитать)
  TGitTrackedActEvent = function(const AFiles: TGitTrackedFiles): Boolean
    of object;

  TDlgGitTracked = class(TForm)
  private
    FFiles: TGitTrackedFiles;
    FOnLoad: TGitTrackedLoadEvent;
    FOnKeep: TGitTrackedActEvent;
    FOnUntrack: TGitTrackedActEvent;
    FChanged: Boolean;
    FTopPanel: TUiPanel;
    FBtnPanel: TUiPanel;
    FLblInfo: TUiLabel;
    FLblInfo2: TUiLabel;
    FLblCount: TUiLabel;
    FList: TUiListView;
    FBtnAll: TUiButton;
    FBtnNone: TUiButton;
    FBtnRule: TUiButton;
    FBtnFolder: TUiButton;
    FBtnKeep: TUiButton;
    FBtnUntrack: TUiButton;
    FBtnClose: TUiButton;
    FFilling: Boolean;
    procedure FillList(AKeepChecked: TStrings);
    procedure Reload;
    procedure UpdateCount;
    function CheckedFiles(var APicked: TGitTrackedFiles): Integer;
    procedure CheckLike(AByRule: Boolean);
    procedure BtnAllClick(Sender: TObject);
    procedure BtnNoneClick(Sender: TObject);
    procedure BtnRuleClick(Sender: TObject);
    procedure BtnFolderClick(Sender: TObject);
    procedure BtnKeepClick(Sender: TObject);
    procedure BtnUntrackClick(Sender: TObject);
    procedure ListChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure LayoutTop(Sender: TObject);
    procedure LayoutButtons(Sender: TObject);
    // $0128 - WM_UPDATEUISTATE (кнопки не пропадают по Alt, как в других окнах)
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    constructor CreateDlg(AOwner: TComponent; const ATitle: string;
      const AFiles: TGitTrackedFiles; AOnLoad: TGitTrackedLoadEvent;
      AOnKeep, AOnUntrack: TGitTrackedActEvent);
    // Что-то сделано (исключения в .gitignore или git rm --cached) -
    // изменения нужно закоммитить
    property Changed: Boolean read FChanged;
  end;

// Папка пути с '/' в конце ('a/b/c.txt' -> 'a/b/'); в корне - ''
function GitTrackedDir(const APath: WideString): WideString;

implementation

function GitTrackedDir(const APath: WideString): WideString;
var
  CharIdx: Integer;
begin
  Result := '';
  for CharIdx := Length(APath) downto 1 do
    if APath[CharIdx] = '/' then
    begin
      Result := Copy(APath, 1, CharIdx);
      Exit;
    end;
end;

constructor TDlgGitTracked.CreateDlg(AOwner: TComponent; const ATitle: string;
  const AFiles: TGitTrackedFiles; AOnLoad: TGitTrackedLoadEvent;
  AOnKeep, AOnUntrack: TGitTrackedActEvent);
var
  Column: TListColumn;

  function NewButton(AParent: TWinControl; const ACaption,
    AHint: string; AClick: TNotifyEvent): TUiButton;
  begin
    Result := TUiButton.Create(Self);
    Result.Parent := AParent;
    Result.Caption := ACaption;
    Result.Hint := AHint;
    Result.ShowHint := True;
    Result.OnClick := AClick;
  end;

  function NewLabel(ATop: Integer; const ACaption: string): TUiLabel;
  begin
    Result := TUiLabel.Create(Self);
    Result.Parent := FTopPanel;
    Result.AutoSize := True;
    Result.Left := 6;
    Result.Top := ATop;
    Result.Caption := ACaption;
  end;

begin
  inherited CreateNew(AOwner);
  FFiles := AFiles;
  FOnLoad := AOnLoad;
  FOnKeep := AOnKeep;
  FOnUntrack := AOnUntrack;
  FChanged := False;
  Caption := ATitle;
  Position := poMainFormCenter;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Width := 900;
  Height := 560;
  Constraints.MinWidth := 640;
  Constraints.MinHeight := 360;

  // Сверху: пояснение и кнопки отметки
  FTopPanel := TUiPanel.Create(Self);
  FTopPanel.Parent := Self;
  FTopPanel.Align := alTop;
  FTopPanel.Height := 70;
  FTopPanel.BevelOuter := bvNone;
  FTopPanel.Caption := '';
  FLblInfo := NewLabel(4, 'Эти файлы лежат в репозитории, хотя подходят ' +
    'под правила .gitignore - на них .gitignore не действует.');
  FLblInfo2 := NewLabel(22, 'Отметьте файлы флажками и выберите: оставить ' +
    'в репозитории или убрать из репозитория (файл останется на диске).');
  FBtnAll := NewButton(FTopPanel, 'Все', 'Отметить все строки',
    BtnAllClick);
  FBtnNone := NewButton(FTopPanel, 'Ни одного', 'Снять все флажки',
    BtnNoneClick);
  FBtnRule := NewButton(FTopPanel, 'По правилу', 'Отметить все строки ' +
    'с тем же правилом .gitignore, что у выделенной строки', BtnRuleClick);
  FBtnFolder := NewButton(FTopPanel, 'Папка', 'Отметить все строки из ' +
    'той же папки, что выделенная строка', BtnFolderClick);
  FTopPanel.OnResize := LayoutTop;

  // Снизу: число отмеченных и кнопки действий
  FBtnPanel := TUiPanel.Create(Self);
  FBtnPanel.Parent := Self;
  FBtnPanel.Align := alBottom;
  FBtnPanel.Height := 38;
  FBtnPanel.BevelOuter := bvNone;
  FBtnPanel.Caption := '';
  FLblCount := TUiLabel.Create(Self);
  FLblCount.Parent := FBtnPanel;
  FLblCount.AutoSize := True;
  FLblCount.Left := 6;
  FLblCount.Top := 11;
  FLblCount.Caption := '';
  FBtnKeep := NewButton(FBtnPanel, 'Оставить в репозитории',
    'Для отмеченных файлов дописать в .gitignore исключение (!путь): ' +
    'файлы остаются в репозитории, проверка Git status о них молчит',
    BtnKeepClick);
  FBtnUntrack := NewButton(FBtnPanel, 'Убрать из репозитория',
    'git rm --cached для отмеченных файлов: на диске остаются, из ' +
    'репозитория уходят следующим коммитом. На других компьютерах Pull ' +
    'из unIDE их сохраняет, из GitHub Desktop или Git Bash - удалит',
    BtnUntrackClick);
  FBtnClose := NewButton(FBtnPanel, 'Close', '', nil);
  FBtnClose.Cancel := True;
  FBtnClose.ModalResult := mrCancel;
  FBtnPanel.OnResize := LayoutButtons;

  FList := TUiListView.Create(Self);
  FList.Parent := Self;
  FList.Align := alClient;
  FList.ViewStyle := vsReport;
  FList.Checkboxes := True;
  FList.ReadOnly := True;
  FList.RowSelect := True;
  FList.HideSelection := False;
  Column := FList.Columns.Add;
  Column.Caption := 'Файл';
  Column.Width := 520;
  Column := FList.Columns.Add;
  Column.Caption := 'Правило .gitignore';
  Column.Width := 260;
  FillList(nil);
  FList.OnChange := ListChange;
  UpdateCount;
  ActiveControl := FList;
end;

procedure TDlgGitTracked.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgGitTracked.LayoutTop(Sender: TObject);
const
  BtnGap = 6;
  BtnH = 23;
var
  BtnLeft: Integer;
begin
  BtnLeft := 6;
  FBtnAll.SetBounds(BtnLeft, 42, 60, BtnH);
  Inc(BtnLeft, 60 + BtnGap);
  FBtnNone.SetBounds(BtnLeft, 42, 84, BtnH);
  Inc(BtnLeft, 84 + BtnGap);
  FBtnRule.SetBounds(BtnLeft, 42, 96, BtnH);
  Inc(BtnLeft, 96 + BtnGap);
  FBtnFolder.SetBounds(BtnLeft, 42, 70, BtnH);
end;

procedure TDlgGitTracked.LayoutButtons(Sender: TObject);
const
  BtnGap = 6;
  BtnH = 24;
var
  BtnTop, BtnRight: Integer;
begin
  BtnTop := (FBtnPanel.ClientHeight - BtnH) div 2;
  BtnRight := FBtnPanel.ClientWidth - 6;
  FBtnClose.SetBounds(BtnRight - 70, BtnTop, 70, BtnH);
  Dec(BtnRight, 70 + BtnGap * 3);
  FBtnUntrack.SetBounds(BtnRight - 170, BtnTop, 170, BtnH);
  Dec(BtnRight, 170 + BtnGap);
  FBtnKeep.SetBounds(BtnRight - 180, BtnTop, 180, BtnH);
end;

// Список по FFiles. AKeepChecked - пути, у которых флажок стоял до
// перечитывания (nil - все без флажков)
procedure TDlgGitTracked.FillList(AKeepChecked: TStrings);
var
  FileIdx: Integer;
  Item: TListItem;
begin
  FFilling := True;
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for FileIdx := 0 to High(FFiles) do
    begin
      Item := FList.Items.Add;
      Item.Caption := string(FFiles[FileIdx].Path);
      Item.SubItems.Add(FFiles[FileIdx].Rule);
      Item.Data := Pointer(FileIdx);
      Item.Checked := (AKeepChecked <> nil) and
        (AKeepChecked.IndexOf(string(FFiles[FileIdx].Path)) >= 0);
    end;
  finally
    FList.Items.EndUpdate;
    FFilling := False;
  end;
end;

procedure TDlgGitTracked.Reload;
var
  KeepChecked: TStringList;
  ItemIdx: Integer;
begin
  if not Assigned(FOnLoad) then
    Exit;
  KeepChecked := TStringList.Create;
  try
    for ItemIdx := 0 to FList.Items.Count - 1 do
      if FList.Items[ItemIdx].Checked then
        KeepChecked.Add(FList.Items[ItemIdx].Caption);
    if FOnLoad(FFiles) then
      FillList(KeepChecked);
  finally
    KeepChecked.Free;
  end;
  UpdateCount;
end;

procedure TDlgGitTracked.UpdateCount;
var
  ItemIdx, CheckedCount: Integer;
begin
  CheckedCount := 0;
  for ItemIdx := 0 to FList.Items.Count - 1 do
    if FList.Items[ItemIdx].Checked then
      Inc(CheckedCount);
  if FList.Items.Count = 0 then
    FLblCount.Caption := 'Таких файлов нет'
  else
    FLblCount.Caption := 'Отмечено ' + IntToStr(CheckedCount) + ' из ' +
      IntToStr(FList.Items.Count);
  FBtnKeep.Enabled := CheckedCount > 0;
  FBtnUntrack.Enabled := CheckedCount > 0;
end;

function TDlgGitTracked.CheckedFiles(var APicked: TGitTrackedFiles): Integer;
var
  ItemIdx, FileIdx: Integer;
begin
  SetLength(APicked, 0);
  for ItemIdx := 0 to FList.Items.Count - 1 do
    if FList.Items[ItemIdx].Checked then
    begin
      FileIdx := Integer(FList.Items[ItemIdx].Data);
      if (FileIdx < 0) or (FileIdx > High(FFiles)) then
        Continue;
      SetLength(APicked, Length(APicked) + 1);
      APicked[High(APicked)] := FFiles[FileIdx];
    end;
  Result := Length(APicked);
end;

// Отметить строки как у выделенной: с тем же правилом (AByRule) или из
// той же папки
procedure TDlgGitTracked.CheckLike(AByRule: Boolean);
var
  Key, ItemKey: string;
  ItemIdx, FileIdx: Integer;
begin
  if FList.Selected = nil then
    Exit;
  FileIdx := Integer(FList.Selected.Data);
  if (FileIdx < 0) or (FileIdx > High(FFiles)) then
    Exit;
  if AByRule then
    Key := FFiles[FileIdx].Rule
  else
    Key := string(GitTrackedDir(FFiles[FileIdx].Path));
  FFilling := True;
  try
    for ItemIdx := 0 to FList.Items.Count - 1 do
    begin
      FileIdx := Integer(FList.Items[ItemIdx].Data);
      if (FileIdx < 0) or (FileIdx > High(FFiles)) then
        Continue;
      if AByRule then
        ItemKey := FFiles[FileIdx].Rule
      else
        ItemKey := string(GitTrackedDir(FFiles[FileIdx].Path));
      if ItemKey = Key then
        FList.Items[ItemIdx].Checked := True;
    end;
  finally
    FFilling := False;
  end;
  UpdateCount;
end;

procedure TDlgGitTracked.BtnAllClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  FFilling := True;
  try
    for ItemIdx := 0 to FList.Items.Count - 1 do
      FList.Items[ItemIdx].Checked := True;
  finally
    FFilling := False;
  end;
  UpdateCount;
end;

procedure TDlgGitTracked.BtnNoneClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  FFilling := True;
  try
    for ItemIdx := 0 to FList.Items.Count - 1 do
      FList.Items[ItemIdx].Checked := False;
  finally
    FFilling := False;
  end;
  UpdateCount;
end;

procedure TDlgGitTracked.BtnRuleClick(Sender: TObject);
begin
  CheckLike(True);
end;

procedure TDlgGitTracked.BtnFolderClick(Sender: TObject);
begin
  CheckLike(False);
end;

procedure TDlgGitTracked.BtnKeepClick(Sender: TObject);
var
  Picked: TGitTrackedFiles;
begin
  if (CheckedFiles(Picked) = 0) or not Assigned(FOnKeep) then
    Exit;
  if FOnKeep(Picked) then
  begin
    FChanged := True;
    Reload;
  end;
end;

procedure TDlgGitTracked.BtnUntrackClick(Sender: TObject);
var
  Picked: TGitTrackedFiles;
begin
  if (CheckedFiles(Picked) = 0) or not Assigned(FOnUntrack) then
    Exit;
  if FOnUntrack(Picked) then
  begin
    FChanged := True;
    Reload;
  end;
end;

// Флажок строки поставили или сняли - число отмеченных
procedure TDlgGitTracked.ListChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
  if FFilling or (Change <> ctState) then
    Exit;
  UpdateCount;
end;

end.
