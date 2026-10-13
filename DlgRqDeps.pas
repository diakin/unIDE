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
  ExtCtrls, ComCtrls, Dialogs,
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
    pnlCands: TPanel;
    lvCands: TListView;     // копии на диске: путь, размер, создан, изменён
    splDeps: TSplitter;
    splCands: TSplitter;
    memPreview: TMemo;      // текст копии, выделенной в lvCands
    lblNote: TLabel;
    pnlBottom: TPanel;
    lblTarget: TLabel;
    cbTarget: TComboBox;
    chkIgnore: TUiCheckBox;
    btnSearch: TUiButton;
    btnCopy: TUiButton;
    btnBuild: TUiButton;
    btnCancel: TUiButton;
    btnFix: TUiButton;      // проверить выбранную копию inc и исправить
    btnUndo: TUiButton;     // отменить исправления файлов
    // Исправленные файлы и их копии до исправления (IncAutoFix) - для Undo
    FFixFiles: TStringList;
    FFixBaks: TStringList;
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
    procedure lvCandsSelectItem(Sender: TObject; Item: TListItem;
                                Selected: Boolean);
    procedure UpdateNote;
    procedure ShowPreview;
    procedure cbTargetChange(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnBuildClick(Sender: TObject);
    procedure btnFixClick(Sender: TObject);
    procedure btnUndoClick(Sender: TObject);
    function  CheckFiles(AFiles, AReport: TStrings): Integer;
    procedure FixFiles(AFiles, AReport: TStrings);
    procedure CheckUserIncludes;
    function  EnsureRef: Boolean;
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
  FFixFiles.Free;
  FFixBaks.Free;
  FRef.Free;
  inherited Destroy;
end;

procedure TRqDepsForm.BuildControls;

  procedure AddCol(AList: TListView; const ACaption: string; AWidth: Integer);
  var
    Col: TListColumn;
  begin
    Col := AList.Columns.Add;
    Col.Caption := ACaption;
    Col.Width := AWidth;
  end;

  function MakeButton(const ACaption: string; ALeft, AWidth: Integer;
                      AClick: TNotifyEvent): TUiButton;
  begin
    Result := TUiButton.Create(Self);
    Result.Parent := pnlBottom;
    Result.SetBounds(ALeft, 62, AWidth, 25);
    Result.Caption := ACaption;
    Result.OnClick := AClick;
  end;

begin
  Caption := 'Недостающие файлы программы';
  Width := 960;
  Height := 720;
  Position := poScreenCenter;
  BorderIcons := [biSystemMenu, biMaximize];
  Constraints.MinWidth := 700;
  Constraints.MinHeight := 520;
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

  // Низ окна: пояснение, куда, кнопки, строка хода
  pnlBottom := TPanel.Create(Self);
  pnlBottom.Parent := Self;
  // Ширина задаётся сразу: от неё отсчитываются якоря akRight внутри
  pnlBottom.SetBounds(0, ClientHeight - 112, ClientWidth, 112);
  pnlBottom.Align := alBottom;
  pnlBottom.BevelOuter := bvNone;
  pnlBottom.Caption := '';

  lblNote := TLabel.Create(Self);
  lblNote.Parent := pnlBottom;
  lblNote.AutoSize := False;
  lblNote.WordWrap := True;
  lblNote.SetBounds(8, 4, ClientWidth - 16, 28);
  lblNote.Anchors := [akLeft, akTop, akRight];

  lblTarget := TLabel.Create(Self);
  lblTarget.Parent := pnlBottom;
  lblTarget.SetBounds(8, 38, 40, 13);
  lblTarget.Caption := 'Куда:';
  cbTarget := TComboBox.Create(Self);
  cbTarget.Parent := pnlBottom;
  cbTarget.Style := csDropDownList;
  cbTarget.SetBounds(50, 34, 560, 21);
  cbTarget.OnChange := cbTargetChange;
  cbTarget.Hint := 'Куда копировать выбранный файл. Путь из $INCLUDE ' +
                   '(Object\QINI.inc) сохраняется: файл ляжет в подпапку. ' +
                   'DLL - всегда в папку программы: Windows ищет её рядом с ' +
                   'exe, а не в папке -I';
  chkIgnore := TUiCheckBox.Create(Self);
  chkIgnore.Parent := pnlBottom;
  chkIgnore.SetBounds(620, 36, 270, 17);
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
  btnFix := MakeButton('Проверить и исправить', 630, 160, btnFixClick);
  btnUndo := MakeButton('Undo', 796, 70, btnUndoClick);
  btnUndo.Hint := 'Отменить исправления: исправленные файлы удалить, ' +
                  'прежние вернуть из .bak';
  btnUndo.Enabled := False;
  FFixFiles := TStringList.Create;
  FFixBaks := TStringList.Create;
  btnFix.Hint := 'Проверка INC Manager выбранной копии inc; однозначные ' +
                 'ошибки (директивы без $, U/L и 0x из C, ";" вне строки) - ' +
                 'исправить в самом файле, прежний текст - в .bak';

  lblStatus := TLabel.Create(Self);
  lblStatus.Parent := pnlBottom;
  lblStatus.AutoSize := False;
  lblStatus.SetBounds(8, 94, ClientWidth - 16, 13);
  lblStatus.Anchors := [akLeft, akTop, akRight];

  // Середина сверху вниз: недостающие | сплиттер | копии | сплиттер |
  // просмотр. Порядок alTop - по Top, поэтому Top задаётся до Align.
  lvDeps := TListView.Create(Self);
  lvDeps.Parent := Self;
  lvDeps.Top := 100;
  lvDeps.Height := 170;
  lvDeps.Align := alTop;
  lvDeps.ViewStyle := vsReport;
  lvDeps.Checkboxes := True;
  lvDeps.RowSelect := True;
  lvDeps.ReadOnly := True;
  lvDeps.HideSelection := False;
  lvDeps.OnSelectItem := lvDepsSelectItem;
  AddCol(lvDeps, 'Файл', 170);
  AddCol(lvDeps, 'Вид', 55);
  AddCol(lvDeps, 'Подключён', 170);
  AddCol(lvDeps, 'Копий', 50);
  AddCol(lvDeps, 'Взять', 480);

  splDeps := TSplitter.Create(Self);
  splDeps.Parent := Self;
  splDeps.Top := 300;
  splDeps.Height := 5;
  splDeps.Align := alTop;
  splDeps.MinSize := 60;

  pnlCands := TPanel.Create(Self);
  pnlCands.Parent := Self;
  pnlCands.Top := 310;
  pnlCands.Height := 160;
  pnlCands.Align := alTop;
  pnlCands.BevelOuter := bvNone;
  pnlCands.Caption := '';

  lblCands := TLabel.Create(Self);
  lblCands.Parent := pnlCands;
  lblCands.Align := alTop;
  lblCands.Caption := ' Копии на диске (выделенная - берётся, её текст - ниже):';

  lvCands := TListView.Create(Self);
  lvCands.Parent := pnlCands;
  lvCands.Align := alClient;
  lvCands.ViewStyle := vsReport;
  lvCands.RowSelect := True;
  lvCands.ReadOnly := True;
  lvCands.HideSelection := False;
  lvCands.OnSelectItem := lvCandsSelectItem;
  AddCol(lvCands, 'Путь', 560);
  AddCol(lvCands, 'Размер', 80);
  AddCol(lvCands, 'Создан', 115);
  AddCol(lvCands, 'Изменён', 115);

  splCands := TSplitter.Create(Self);
  splCands.Parent := Self;
  splCands.Top := 480;
  splCands.Height := 5;
  splCands.Align := alTop;
  splCands.MinSize := 60;

  memPreview := TMemo.Create(Self);
  memPreview.Parent := Self;
  memPreview.Align := alClient;
  memPreview.ReadOnly := True;
  memPreview.WordWrap := False;
  memPreview.ScrollBars := ssBoth;
  memPreview.Font.Name := 'Courier New';
  memPreview.Font.Height := -12;

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

// Размер и время файла: создан, изменён (местное время)
function FileStampText(const AFile: string; var ASize, ACreated,
                       AWritten: string): Boolean;
var
  SR: TSearchRec;
  LocalTime: TFileTime;
  SysTime: TSystemTime;
  FileSize: Int64;

  function TimeText(const AStamp: TFileTime): string;
  begin
    Result := '';
    if FileTimeToLocalFileTime(AStamp, LocalTime) and
       FileTimeToSystemTime(LocalTime, SysTime) then
      Result := FormatDateTime('dd.mm.yyyy hh:nn', SystemTimeToDateTime(SysTime));
  end;

begin
  ASize := '';
  ACreated := '';
  AWritten := '';
  Result := FindFirst(AFile, faAnyFile, SR) = 0;
  if not Result then
    Exit;
  try
    FileSize := Int64(SR.FindData.nFileSizeHigh) shl 32 +
                SR.FindData.nFileSizeLow;
    ASize := FormatFloat('#,##0', FileSize);
    ACreated := TimeText(SR.FindData.ftCreationTime);
    AWritten := TimeText(SR.FindData.ftLastWriteTime);
  finally
    FindClose(SR);
  end;
end;

procedure TRqDepsForm.ShowSelected;
var
  Dep: TRqDep;
  CandIdx: Integer;
  IncText, SizeText, CreatedText, WrittenText: string;
  Item: TListItem;
begin
  Dep := SelectedDep;
  FFilling := True;
  try
    lvCands.Items.BeginUpdate;
    try
      lvCands.Items.Clear;
      if Dep <> nil then
        for CandIdx := 0 to Dep.Candidates.Count - 1 do
        begin
          Item := lvCands.Items.Add;
          Item.Caption := Dep.Candidates[CandIdx];
          FileStampText(Dep.Candidates[CandIdx], SizeText, CreatedText,
                        WrittenText);
          Item.SubItems.Add(SizeText);
          Item.SubItems.Add(CreatedText);
          Item.SubItems.Add(WrittenText);
        end;
    finally
      lvCands.Items.EndUpdate;
    end;
    if (Dep <> nil) and (Dep.Chosen >= 0) and
       (Dep.Chosen < lvCands.Items.Count) then
    begin
      lvCands.Selected := lvCands.Items[Dep.Chosen];
      lvCands.Selected.MakeVisible(False);
    end;
  finally
    FFilling := False;
  end;
  cbTarget.Items.Clear;
  if Dep = nil then
  begin
    lblNote.Caption := '';
    cbTarget.Enabled := False;
    ShowPreview;
    Exit;
  end;
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
  UpdateNote;
  ShowPreview;
end;

// Пояснение под списками: почему взята копия и куда она ляжет
procedure TRqDepsForm.UpdateNote;
var
  Dep: TRqDep;
begin
  Dep := SelectedDep;
  if Dep = nil then
    lblNote.Caption := ''
  else if Dep.Chosen >= 0 then
    lblNote.Caption := Dep.ChosenNote + '. Копия ляжет в ' +
                       RqDepTargetPath(Dep, FScan.IncDir, FScan.MainDir)
  else if FBusy then
    lblNote.Caption := ''
  else
    lblNote.Caption := 'Копий не найдено. Поиск по всем дискам - View - Find ' +
                       'inc file, галка "Все локальные диски"';
end;

// Текст выбранной копии (inc и прочие текстовые; DLL и картинки - нет)
procedure TRqDepsForm.ShowPreview;
const
  PreviewMax = 1048576;
var
  Dep: TRqDep;
  FileName, Ext: string;
  Stream: TFileStream;
  Buf: string;
begin
  memPreview.Lines.Clear;
  Dep := SelectedDep;
  if (Dep = nil) or (lvCands.Selected = nil) then
    Exit;
  FileName := lvCands.Selected.Caption;
  Ext := LowerCase(ExtractFileExt(FileName));
  if (Dep.Kind = dpkLib) or (Ext = '.bmp') or (Ext = '.ico') or
     (Ext = '.jpg') or (Ext = '.gif') or (Ext = '.cur') or (Ext = '.wav') then
  begin
    memPreview.Lines.Add('(' + FileName + ' - не текст, просмотра нет)');
    Exit;
  end;
  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      if Stream.Size > PreviewMax then
        SetLength(Buf, PreviewMax)
      else
        SetLength(Buf, Stream.Size);
      if Length(Buf) > 0 then
        Stream.ReadBuffer(Buf[1], Length(Buf));
    finally
      Stream.Free;
    end;
    memPreview.Text := Buf;
    memPreview.SelStart := 0;
  except
    on E: Exception do
      memPreview.Lines.Add('Не прочитан: ' + E.Message);
  end;
end;

procedure TRqDepsForm.lvDepsSelectItem(Sender: TObject; Item: TListItem;
                                       Selected: Boolean);
begin
  if not FFilling and Selected then
    ShowSelected;
end;

// Выделенная копия - та, что берётся
procedure TRqDepsForm.lvCandsSelectItem(Sender: TObject; Item: TListItem;
                                        Selected: Boolean);
var
  Dep: TRqDep;
begin
  if FFilling or not Selected or (Item = nil) then
    Exit;
  Dep := SelectedDep;
  if Dep <> nil then
  begin
    if not FBusy and (Item.Index <> Dep.Chosen) then
    begin
      Dep.Chosen := Item.Index;
      Dep.ChosenNote := 'выбрана вручную';
      FillRow(lvDeps.Selected);
      lvDeps.Selected.Checked := True;
    end;
    UpdateNote;
  end;
  ShowPreview;
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
  btnFix.Enabled := not ABusy;
  btnUndo.Enabled := not ABusy and (FFixFiles <> nil) and (FFixFiles.Count > 0);
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
  if Done then
    CheckUserIncludes;
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

// Эталон для проверки inc - один раз за окно. False - не прочитан.
function TRqDepsForm.EnsureRef: Boolean;
begin
  if FRef = nil then
  begin
    SetBusy(True);
    try
      FRef := TIncRefIndex.Create;
      if not FRef.Load(FRefDir, FSysDir, ProgressStep) then
        FreeAndNil(FRef);
    finally
      SetBusy(False);
    end;
  end;
  Result := FRef <> nil;
  if not Result then
    lblStatus.Caption := 'Эталон не прочитан - проверка прервана';
end;

// Проверка INC Manager по файлам AFiles: отчёт - в AReport, результат -
// сколько ошибок всего
function TRqDepsForm.CheckFiles(AFiles, AReport: TStrings): Integer;
var
  FileIdx, MsgIdx: Integer;
  Info: TIncFileInfo;
begin
  Result := 0;
  for FileIdx := 0 to AFiles.Count - 1 do
  begin
    Info := TIncFileInfo.Create(AFiles[FileIdx]);
    try
      IncCheckFile(Info, FRef);
      Inc(Result, Info.Errors);
      AReport.Add(AFiles[FileIdx] + ' - ' + IncStatusNames[Info.Status] +
                  Format(', ошибок: %d', [Info.Errors]));
      for MsgIdx := 0 to Info.Messages.Count - 1 do
        AReport.Add('    ' + Info.Messages[MsgIdx]);
    finally
      Info.Free;
    end;
  end;
end;

// Исправить однозначные ошибки в AFiles (IncAutoFix); копии до
// исправления - в список Undo
procedure TRqDepsForm.FixFiles(AFiles, AReport: TStrings);
var
  FileIdx, Fixed: Integer;
  Backup, Err: string;
  FixRep: TStringList;
begin
  FixRep := TStringList.Create;
  try
    for FileIdx := 0 to AFiles.Count - 1 do
    begin
      FixRep.Clear;
      Fixed := IncAutoFix(AFiles[FileIdx], FixRep, Backup, Err);
      if Fixed < 0 then
        AReport.Add(AFiles[FileIdx] + ' - не исправлен: ' + Err)
      else if Fixed = 0 then
        AReport.Add(AFiles[FileIdx] + ' - исправлять нечего ' +
                    '(ошибки только те, что правят руками)')
      else
      begin
        AReport.Add(Format('%s - исправлено строк: %d, прежний текст - %s',
                           [AFiles[FileIdx], Fixed, ExtractFileName(Backup)]));
        AReport.AddStrings(FixRep);
        FFixFiles.Add(AFiles[FileIdx]);
        FFixBaks.Add(Backup);
      end;
    end;
  finally
    FixRep.Free;
  end;
  btnUndo.Enabled := FFixFiles.Count > 0;
end;

// После поиска: копии, найденные в Include User, - проверить; есть
// ошибки - список в просмотре и вопрос, исправить ли файлы
procedure TRqDepsForm.CheckUserIncludes;
var
  ItemIdx, ErrCount: Integer;
  Dep: TRqDep;
  Files, Report: TStringList;
begin
  Files := TStringList.Create;
  Report := TStringList.Create;
  try
    for ItemIdx := 0 to FScan.Count - 1 do
    begin
      Dep := FScan[ItemIdx];
      if Dep.Missing and (Dep.Kind = dpkInclude) and (Dep.Chosen >= 0) and
         (CompareText(Dep.Where[Dep.Chosen], 'Include User') = 0) and
         (Files.IndexOf(Dep.Candidates[Dep.Chosen]) < 0) then
        Files.Add(Dep.Candidates[Dep.Chosen]);
    end;
    if (Files.Count = 0) or not EnsureRef then
      Exit;
    Report.Add(Format('Найдены в Include User: %d. Проверка:', [Files.Count]));
    ErrCount := CheckFiles(Files, Report);
    memPreview.Lines.Assign(Report);
    if ErrCount = 0 then
    begin
      lblStatus.Caption := 'Файлы из Include User проверены - ошибок нет';
      Exit;
    end;
    lblStatus.Caption := Format('В файлах из Include User ошибок: %d',
                                [ErrCount]);
    if MessageDlg(Format('В файлах из Include User ошибок: %d (список - в окне ' +
                         'просмотра).'#13#10#13#10'Исправить файлы? Исходные ' +
                         'будут сохранены с расширением .bak. Исправляются ' +
                         'однозначные ошибки (директивы без $, числа с U/L и ' +
                         '0x из C, ";" вне строки), остальные правят руками. ' +
                         'Кнопка Undo вернёт прежние файлы.', [ErrCount]),
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    Report.Add('');
    Report.Add('Исправление:');
    FixFiles(Files, Report);
    Report.Add('');
    Report.Add('После исправления:');
    ErrCount := CheckFiles(Files, Report);
    memPreview.Lines.Assign(Report);
    lblStatus.Caption := Format('Исправлено; ошибок осталось: %d', [ErrCount]);
  finally
    Report.Free;
    Files.Free;
  end;
end;

// Проверить выбранную копию inc (как INC Manager) и исправить однозначные
// ошибки на месте; отчёт - в окне просмотра
procedure TRqDepsForm.btnFixClick(Sender: TObject);
var
  Dep: TRqDep;
  Files, Report: TStringList;
  ErrCount: Integer;
begin
  Dep := SelectedDep;
  if (Dep = nil) or (lvCands.Selected = nil) or FBusy then
    Exit;
  if Dep.Kind <> dpkInclude then
  begin
    lblStatus.Caption := 'Проверка - только для inc';
    Exit;
  end;
  if not EnsureRef then
    Exit;
  Files := TStringList.Create;
  Report := TStringList.Create;
  try
    Files.Add(lvCands.Selected.Caption);
    ErrCount := CheckFiles(Files, Report);
    if (ErrCount > 0) and
       (MessageDlg(Format('%s: ошибок %d.'#13#10#13#10'Исправить файл? ' +
                          'Исходный будет сохранён с расширением .bak. ' +
                          'Исправляются однозначные ошибки, остальные - в ' +
                          'отчёте. Кнопка Undo вернёт прежний файл.',
                          [ExtractFileName(Files[0]), ErrCount]),
                   mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
    begin
      Report.Add('');
      FixFiles(Files, Report);
      Report.Add('');
      Report.Add('После исправления:');
      ErrCount := CheckFiles(Files, Report);
    end;
    memPreview.Lines.Assign(Report);
    lblStatus.Caption := Format('%s: ошибок %d', [ExtractFileName(Files[0]),
                                                  ErrCount]);
  finally
    Report.Free;
    Files.Free;
  end;
end;

// Undo: исправленные файлы удалить, прежние - из .bak обратно
procedure TRqDepsForm.btnUndoClick(Sender: TObject);
var
  FileIdx: Integer;
  Err: string;
  Report: TStringList;
begin
  if FFixFiles.Count = 0 then
    Exit;
  Report := TStringList.Create;
  try
    Report.Add('Undo:');
    for FileIdx := FFixFiles.Count - 1 downto 0 do
      if IncUndoFix(FFixFiles[FileIdx], FFixBaks[FileIdx], Err) then
      begin
        Report.Add(FFixFiles[FileIdx] + ' - возвращён прежний');
        FFixFiles.Delete(FileIdx);
        FFixBaks.Delete(FileIdx);
      end
      else
        Report.Add(FFixFiles[FileIdx] + ' - не вышло: ' + Err);
    memPreview.Lines.Assign(Report);
    if FFixFiles.Count = 0 then
      lblStatus.Caption := 'Исправления отменены'
    else
      lblStatus.Caption := Format('Не отменено файлов: %d', [FFixFiles.Count]);
  finally
    Report.Free;
  end;
  btnUndo.Enabled := FFixFiles.Count > 0;
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
      ' Поиск: Include UnIde, Include User, папка программы с подпапками, ' +
      'папка выше. Отмеченные копируются, затем сборка.';
    Result := Dlg.ShowModal = mrOk;
  finally
    Dlg.Free;
  end;
end;

end.
