unit DlgRqDeps;

// ---------------------------------------------------------------------------
//  Окно "Недостающие файлы" перед сборкой RapidQ (RqDeps). Показывается,
//  когда $INCLUDE, $RESOURCE или DLL из DECLARE ... LIB нет там, где их
//  возьмёт rc.exe / Windows. Сразу ищет их на диске (Include, общая
//  Include, папка программы с подпапками, папка выше), выбирает копию
//  (inc - совпадающую с эталоном) и копирует отмеченные: inc и ресурсы - в
//  папку -I сборки (её можно сменить на папку программы), DLL - в папку
//  программы (exe). Окно строится кодом, без .dfm.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  ExtCtrls, ComCtrls,
  IncCheck,     // эталон, TIncProgress
  RqDeps,       // TRqDepScan, поиск и выбор копий
  UiButton,     // TUiButton
  UiStdCtrls;   // TUiCheckBox

// Показать окно. AScan - результат проверки (есть недостающие); ARoots -
// шаги поиска "подпись|папка"; ARefDir / ASysDir - эталон для inc. ALog -
// что скопировано (строки для лога сборки); AIgnore - имена (верхний
// регистр), про которые больше не спрашивать. True - собирать дальше.
function RqDepsDialog(AOwner: TComponent; AScan: TRqDepScan; ARoots: TStrings;
                      const ARefDir, ASysDir: string;
                      ALog, AIgnore: TStrings): Boolean;

implementation

type
  TRqDepsForm = class(TForm)
  private
    FScan: TRqDepScan;
    FRoots: TStrings;
    FRefDir: string;
    FSysDir: string;
    FRef: TIncRefIndex;
    FLog: TStrings;
    FIgnore: TStrings;
    FBusy: Boolean;
    FAbort: Boolean;
    FLastTick: Cardinal;
    FFilling: Boolean;
    FStartTimer: TTimer;
    lblInfo: TLabel;
    lvDeps: TListView;
    lblCands: TLabel;
    lstCands: TListBox;
    lblNote: TLabel;
    pnlBottom: TPanel;
    lblTarget: TLabel;
    cbTarget: TComboBox;
    chkIgnore: TUiCheckBox;
    btnSearch: TUiButton;
    btnCopy: TUiButton;
    btnBuild: TUiButton;
    btnCancel: TUiButton;
    lblStatus: TLabel;
    procedure BuildControls;
    procedure FillList;
    procedure FillRow(AItem: TListItem);
    procedure ShowSelected;
    procedure RunSearch;
    procedure SetBusy(ABusy: Boolean);
    function  SelectedDep: TRqDep;
    procedure ProgressStep(const AText: string; var ACancel: Boolean);
    procedure StartTimerTick(Sender: TObject);
    procedure lvDepsSelectItem(Sender: TObject; Item: TListItem;
                               Selected: Boolean);
    procedure lstCandsClick(Sender: TObject);
    procedure cbTargetChange(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnBuildClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CollectIgnore;
  public
    destructor Destroy; override;
  end;

function DepWhere(ADep: TRqDep): string;
begin
  Result := ExtractFileName(ADep.FromFile) + ' (' + IntToStr(ADep.FromLine) + ')';
end;

{ TRqDepsForm }

destructor TRqDepsForm.Destroy;
begin
  FRef.Free;
  inherited Destroy;
end;

procedure TRqDepsForm.BuildControls;
var
  Col: TListColumn;

  procedure AddCol(const ACaption: string; AWidth: Integer);
  begin
    Col := lvDeps.Columns.Add;
    Col.Caption := ACaption;
    Col.Width := AWidth;
  end;

  function MakeButton(const ACaption: string; ALeft, AWidth: Integer;
                      AClick: TNotifyEvent): TUiButton;
  begin
    Result := TUiButton.Create(Self);
    Result.Parent := pnlBottom;
    Result.SetBounds(ALeft, 198, AWidth, 25);
    Result.Caption := ACaption;
    Result.OnClick := AClick;
  end;

begin
  Caption := 'Недостающие файлы программы';
  Width := 900;
  Height := 560;
  Position := poScreenCenter;
  BorderIcons := [biSystemMenu, biMaximize];
  Constraints.MinWidth := 700;
  Constraints.MinHeight := 420;
  Font.Name := 'Tahoma';
  Font.Height := -11;
  ShowHint := True;
  OnCloseQuery := FormCloseQuery;

  lblInfo := TLabel.Create(Self);
  lblInfo.Parent := Self;
  lblInfo.Align := alTop;
  lblInfo.AutoSize := True;
  lblInfo.WordWrap := True;
  lblInfo.Layout := tlCenter;

  // Низ окна - одна панель с позициями: копии, пояснение, куда, кнопки
  pnlBottom := TPanel.Create(Self);
  pnlBottom.Parent := Self;
  // Ширина задаётся сразу: от неё отсчитываются якоря akRight внутри
  pnlBottom.SetBounds(0, ClientHeight - 252, ClientWidth, 252);
  pnlBottom.Align := alBottom;
  pnlBottom.BevelOuter := bvNone;
  pnlBottom.Caption := '';

  lblCands := TLabel.Create(Self);
  lblCands.Parent := pnlBottom;
  lblCands.SetBounds(8, 6, 400, 13);
  lblCands.Caption := 'Копии на диске (щелчок - взять эту):';

  lstCands := TListBox.Create(Self);
  lstCands.Parent := pnlBottom;
  lstCands.SetBounds(8, 22, ClientWidth - 16, 110);
  lstCands.Anchors := [akLeft, akTop, akRight];
  lstCands.OnClick := lstCandsClick;

  lblNote := TLabel.Create(Self);
  lblNote.Parent := pnlBottom;
  lblNote.AutoSize := False;
  lblNote.WordWrap := True;
  lblNote.SetBounds(8, 136, ClientWidth - 16, 28);
  lblNote.Anchors := [akLeft, akTop, akRight];

  lblTarget := TLabel.Create(Self);
  lblTarget.Parent := pnlBottom;
  lblTarget.SetBounds(8, 172, 40, 13);
  lblTarget.Caption := 'Куда:';
  cbTarget := TComboBox.Create(Self);
  cbTarget.Parent := pnlBottom;
  cbTarget.Style := csDropDownList;
  cbTarget.SetBounds(50, 168, 560, 21);
  cbTarget.OnChange := cbTargetChange;
  cbTarget.Hint := 'Куда копировать выбранный файл. DLL - всегда в папку ' +
                   'программы: Windows ищет её рядом с exe, а не в папке -I';
  chkIgnore := TUiCheckBox.Create(Self);
  chkIgnore.Parent := pnlBottom;
  chkIgnore.SetBounds(620, 170, 270, 17);
  chkIgnore.Caption := 'Не спрашивать про неотмеченные';
  chkIgnore.Hint := 'Неотмеченные файлы для этой программы больше не ' +
                    'проверяются (editor.ini, [RqDepsIgnore])';

  btnSearch := MakeButton('Искать снова', 8, 110, btnSearchClick);
  btnSearch.Hint := 'Искать недостающие на диске ещё раз; во время поиска - ' +
                    'остановить';
  btnCopy := MakeButton('Копировать отмеченные и собрать', 126, 220, btnCopyClick);
  btnCopy.Hint := 'Скопировать выбранные копии отмеченных файлов и начать сборку';
  btnBuild := MakeButton('Собрать без копирования', 354, 170, btnBuildClick);
  btnCancel := MakeButton('Отмена', 532, 90, nil);
  btnCancel.ModalResult := mrCancel;

  lblStatus := TLabel.Create(Self);
  lblStatus.Parent := pnlBottom;
  lblStatus.AutoSize := False;
  lblStatus.SetBounds(8, 230, ClientWidth - 16, 13);
  lblStatus.Anchors := [akLeft, akTop, akRight];

  lvDeps := TListView.Create(Self);
  lvDeps.Parent := Self;
  lvDeps.Align := alClient;
  lvDeps.ViewStyle := vsReport;
  lvDeps.Checkboxes := True;
  lvDeps.RowSelect := True;
  lvDeps.ReadOnly := True;
  lvDeps.HideSelection := False;
  lvDeps.OnSelectItem := lvDepsSelectItem;
  AddCol('Файл', 170);
  AddCol('Вид', 55);
  AddCol('Подключён', 170);
  AddCol('Копий', 50);
  AddCol('Взять', 420);

  FStartTimer := TTimer.Create(Self);
  FStartTimer.Interval := 50;
  FStartTimer.OnTimer := StartTimerTick;
  FStartTimer.Enabled := True;
end;

function TRqDepsForm.SelectedDep: TRqDep;
begin
  Result := nil;
  if (lvDeps <> nil) and (lvDeps.Selected <> nil) then
    Result := TRqDep(lvDeps.Selected.Data);
end;

procedure TRqDepsForm.FillRow(AItem: TListItem);
var
  Dep: TRqDep;
begin
  Dep := TRqDep(AItem.Data);
  AItem.SubItems.Clear;
  AItem.Caption := Dep.Name;
  AItem.SubItems.Add(RqDepKindNames[Dep.Kind]);
  AItem.SubItems.Add(DepWhere(Dep));
  AItem.SubItems.Add(IntToStr(Dep.Candidates.Count));
  if Dep.Chosen >= 0 then
    AItem.SubItems.Add(Dep.Candidates[Dep.Chosen])
  else if FBusy then
    AItem.SubItems.Add('ищется...')
  else
    AItem.SubItems.Add('не найден');
end;

procedure TRqDepsForm.FillList;
var
  ItemIdx: Integer;
  Item: TListItem;
  KeepIdx: Integer;
begin
  FFilling := True;
  KeepIdx := 0;
  if lvDeps.Selected <> nil then
    KeepIdx := lvDeps.Selected.Index;
  lvDeps.Items.BeginUpdate;
  try
    lvDeps.Items.Clear;
    for ItemIdx := 0 to FScan.Count - 1 do
      if FScan[ItemIdx].Missing then
      begin
        Item := lvDeps.Items.Add;
        Item.Data := FScan[ItemIdx];
        FillRow(Item);
        Item.Checked := FScan[ItemIdx].Chosen >= 0;
      end;
  finally
    lvDeps.Items.EndUpdate;
    FFilling := False;
  end;
  if lvDeps.Items.Count > 0 then
  begin
    if KeepIdx >= lvDeps.Items.Count then
      KeepIdx := 0;
    lvDeps.Selected := lvDeps.Items[KeepIdx];
  end;
  ShowSelected;
end;

procedure TRqDepsForm.ShowSelected;
var
  Dep: TRqDep;
  CandIdx: Integer;
  IncText: string;
begin
  Dep := SelectedDep;
  lstCands.Items.Clear;
  cbTarget.Items.Clear;
  if Dep = nil then
  begin
    lblNote.Caption := '';
    cbTarget.Enabled := False;
    Exit;
  end;
  for CandIdx := 0 to Dep.Candidates.Count - 1 do
    lstCands.Items.Add('[' + Dep.Where[CandIdx] + '] ' + Dep.Candidates[CandIdx]);
  lstCands.ItemIndex := Dep.Chosen;
  IncText := FScan.IncDir;
  if IncText = '' then
    IncText := '(не задана - папка программы)';
  cbTarget.Items.Add('в папку -I сборки: ' + IncText);
  cbTarget.Items.Add('в папку программы: ' + FScan.MainDir);
  if Dep.Kind = dpkLib then
  begin
    cbTarget.ItemIndex := 1;
    cbTarget.Enabled := False;
  end
  else
  begin
    cbTarget.ItemIndex := Ord(Dep.Target);
    cbTarget.Enabled := not FBusy;
  end;
  if Dep.Chosen >= 0 then
    lblNote.Caption := Dep.ChosenNote + '. Копия ляжет в ' +
                       RqDepTargetPath(Dep, FScan.IncDir, FScan.MainDir)
  else if FBusy then
    lblNote.Caption := ''
  else
    lblNote.Caption := 'Копий не найдено. Поиск по всем дискам - View - Find ' +
                       'inc file, галка "Все локальные диски"';
end;

procedure TRqDepsForm.lvDepsSelectItem(Sender: TObject; Item: TListItem;
                                       Selected: Boolean);
begin
  if not FFilling and Selected then
    ShowSelected;
end;

procedure TRqDepsForm.lstCandsClick(Sender: TObject);
var
  Dep: TRqDep;
begin
  Dep := SelectedDep;
  if (Dep = nil) or (lstCands.ItemIndex < 0) or FBusy then
    Exit;
  Dep.Chosen := lstCands.ItemIndex;
  Dep.ChosenNote := 'выбрана вручную';
  FillRow(lvDeps.Selected);
  lvDeps.Selected.Checked := True;
  ShowSelected;
end;

procedure TRqDepsForm.cbTargetChange(Sender: TObject);
var
  Dep: TRqDep;
begin
  Dep := SelectedDep;
  if (Dep = nil) or (Dep.Kind = dpkLib) or (cbTarget.ItemIndex < 0) then
    Exit;
  Dep.Target := TRqDepTarget(cbTarget.ItemIndex);
  ShowSelected;
end;

procedure TRqDepsForm.ProgressStep(const AText: string; var ACancel: Boolean);
begin
  ACancel := FAbort;
  if ACancel or (GetTickCount - FLastTick < 100) then
    Exit;
  FLastTick := GetTickCount;
  lblStatus.Caption := AText;
  Application.ProcessMessages;
  ACancel := FAbort;
end;

procedure TRqDepsForm.SetBusy(ABusy: Boolean);
begin
  FBusy := ABusy;
  if ABusy then
  begin
    FAbort := False;
    FLastTick := 0;
    btnSearch.Caption := 'Стоп';
  end
  else
    btnSearch.Caption := 'Искать снова';
  btnCopy.Enabled := not ABusy;
  btnBuild.Enabled := not ABusy;
  btnCancel.Enabled := not ABusy;
  chkIgnore.Enabled := not ABusy;
end;

procedure TRqDepsForm.RunSearch;
var
  Done, NeedRef: Boolean;
  ItemIdx, FoundCount: Integer;
begin
  SetBusy(True);
  try
    FillList;
    Done := RqDepsFindOnDisk(FScan, FRoots, ProgressStep);
    // Эталон - только если есть копии inc для сравнения
    NeedRef := False;
    for ItemIdx := 0 to FScan.Count - 1 do
      if FScan[ItemIdx].Missing and (FScan[ItemIdx].Kind = dpkInclude) and
         (FScan[ItemIdx].Candidates.Count > 0) then
        NeedRef := True;
    if NeedRef and (FRef = nil) and Done then
    begin
      FRef := TIncRefIndex.Create;
      if not FRef.Load(FRefDir, FSysDir, ProgressStep) then
        FreeAndNil(FRef);
    end;
    RqDepsChoose(FScan, FRef);
    FoundCount := 0;
    for ItemIdx := 0 to FScan.Count - 1 do
      if FScan[ItemIdx].Missing and (FScan[ItemIdx].Chosen >= 0) then
        Inc(FoundCount);
    lblStatus.Caption := Format('Нет на месте: %d, найдены копии: %d',
                                [FScan.MissingCount, FoundCount]);
    if not Done then
      lblStatus.Caption := 'Поиск остановлен. ' + lblStatus.Caption;
  finally
    SetBusy(False);
  end;
  FillList;
end;

procedure TRqDepsForm.StartTimerTick(Sender: TObject);
begin
  FStartTimer.Enabled := False;
  RunSearch;
end;

procedure TRqDepsForm.btnSearchClick(Sender: TObject);
begin
  if FBusy then
    FAbort := True
  else
    RunSearch;
end;

procedure TRqDepsForm.CollectIgnore;
var
  ItemIdx: Integer;
  Dep: TRqDep;
begin
  if not chkIgnore.Checked then
    Exit;
  for ItemIdx := 0 to lvDeps.Items.Count - 1 do
    if not lvDeps.Items[ItemIdx].Checked then
    begin
      Dep := TRqDep(lvDeps.Items[ItemIdx].Data);
      FIgnore.Add(UpperCase(Dep.Name));
    end;
end;

procedure TRqDepsForm.btnCopyClick(Sender: TObject);
var
  ItemIdx, Copied, Failed: Integer;
  Dep: TRqDep;
  Target: string;
begin
  Copied := 0;
  Failed := 0;
  for ItemIdx := 0 to lvDeps.Items.Count - 1 do
  begin
    if not lvDeps.Items[ItemIdx].Checked then
      Continue;
    Dep := TRqDep(lvDeps.Items[ItemIdx].Data);
    if Dep.Chosen < 0 then
      Continue;
    Target := RqDepTargetPath(Dep, FScan.IncDir, FScan.MainDir);
    if FileExists(Target) then
    begin
      FLog.Add('Не скопирован ' + Dep.Name + ': ' + Target + ' уже есть');
      Inc(Failed);
      Continue;
    end;
    ForceDirectories(ExtractFilePath(Target));
    if CopyFile(PChar(Dep.Candidates[Dep.Chosen]), PChar(Target), True) then
    begin
      FLog.Add('Скопирован ' + Dep.Name + ': ' + Dep.Candidates[Dep.Chosen] +
               ' -> ' + Target + ' (' + Dep.ChosenNote + ')');
      Inc(Copied);
    end
    else
    begin
      FLog.Add('Не скопирован ' + Dep.Name + ': ' +
               SysErrorMessage(GetLastError));
      Inc(Failed);
    end;
  end;
  CollectIgnore;
  if Failed > 0 then
  begin
    lblStatus.Caption := Format('Скопировано: %d, не скопировано: %d - ' +
                                'подробности в логе сборки', [Copied, Failed]);
  end;
  ModalResult := mrOk;
end;

procedure TRqDepsForm.btnBuildClick(Sender: TObject);
begin
  CollectIgnore;
  ModalResult := mrOk;
end;

procedure TRqDepsForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FBusy then
  begin
    FAbort := True;
    CanClose := False;
  end;
end;

function RqDepsDialog(AOwner: TComponent; AScan: TRqDepScan; ARoots: TStrings;
                      const ARefDir, ASysDir: string;
                      ALog, AIgnore: TStrings): Boolean;
var
  Dlg: TRqDepsForm;
  Kinds: string;
begin
  Dlg := TRqDepsForm.CreateNew(AOwner);
  try
    Dlg.FScan := AScan;
    Dlg.FRoots := ARoots;
    Dlg.FRefDir := ARefDir;
    Dlg.FSysDir := ASysDir;
    Dlg.FLog := ALog;
    Dlg.FIgnore := AIgnore;
    Dlg.BuildControls;
    Kinds := Format('inc: %d, ресурсы: %d, DLL: %d',
                    [AScan.CountOf(dpkInclude), AScan.CountOf(dpkResource),
                     AScan.CountOf(dpkLib)]);
    Dlg.lblInfo.Caption :=
      ' Этих файлов нет там, где их возьмёт rc.exe (папка программы ' +
      AScan.MainDir + ', папка -I ' + AScan.IncDir + ') или Windows (DLL: ' +
      'папка exe, системные папки, PATH). Недостающих - ' + Kinds + '.'#13#10 +
      ' Поиск: Include (-I), общая Include, папка программы с подпапками, ' +
      'папка выше. Отмеченные копируются, затем сборка.';
    Result := Dlg.ShowModal = mrOk;
  finally
    Dlg.Free;
  end;
end;

end.
