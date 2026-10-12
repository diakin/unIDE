unit DlgFindInc;

// Поиск inc-файла (View - Find inc file...): копии файла с данным именем
// на дисках, сравнение каждой с эталоном и проверка на ошибки (IncCheck),
// выбранная копия - в папку inc проекта, с защитным $IFNDEF.
//
// Нужен, когда сборка RapidQ останавливается на "$INCLUDE file X does not
// exist": такой файл обычно где-то на диске есть, и не один - редактор
// предлагает найти его сам (TForm1.CompileRapidQ).
//
// Окно немодальное, создаётся один раз (TForm1.FindIncShow). Открыть файл
// в редакторе - через OnOpenFile (Unit1).

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls,
  IncCheck,     // сравнение с эталоном, проверки, защита, поиск на дисках
  FolderDlg,    // выбор папки - BrowseFolderDialog
  UiButton,     // TUiButton
  UiStdCtrls,   // TUiCheckBox
  UiEditCtrls;  // TUiEdit

type
  // Открыть файл в редакторе на строке (с 1; 0 - без перехода)
  TFindIncOpenEvent = procedure(const AFile: string; ALine: Integer) of object;

  TDlgFindInc = class(TForm)
    pnlTop: TPanel;
    lblName: TLabel;
    edName: TUiEdit;
    btnFind: TUiButton;
    chkAllDrives: TUiCheckBox;
    lblFolder: TLabel;
    btnFolder: TUiButton;
    lblFound: TLabel;
    lstFound: TListBox;
    Splitter1: TSplitter;
    pnlInfo: TPanel;
    lblHead: TLabel;
    lstErrors: TListBox;
    pnlBottom: TPanel;
    lblTarget: TLabel;
    btnTarget: TUiButton;
    btnCopy: TUiButton;
    btnOpen: TUiButton;
    lblStatus: TLabel;
    procedure btnFindClick(Sender: TObject);
    procedure btnFolderClick(Sender: TObject);
    procedure btnTargetClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure chkAllDrivesClick(Sender: TObject);
    procedure edNameKeyPress(Sender: TObject; var Key: Char);
    procedure lstFoundClick(Sender: TObject);
    procedure lstFoundDblClick(Sender: TObject);
    procedure lstFoundDrawItem(Control: TWinControl; Index: Integer;
                               Rect: TRect; State: TOwnerDrawState);
    procedure lstErrorsDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
  private
    FRefDir: string;       // эталон (incOld)
    FSysDir: string;       // общие inc
    FTargetDir: string;    // куда копировать (папка inc проекта)
    FSearchDir: string;    // где искать, если не на всех дисках
    // Сначала - Include (папка -I проекта), Include system (папка общих inc,
    // если другая), текущая папка (главного .bas
    // или открытого файла), папка выше текущей; потом диски или FSearchDir
    FCurDir: string;
    FUserIncDir: string;
    FFoundWhere: TStringList;   // по найденной копии - где нашлась
    FStageLabel: string;        // шаг поиска, который идёт сейчас
    FFindName: string;          // искомое имя
    FCounts: array[TIncStatus] of Integer;  // найденные по итогу проверки
    FRef: TIncRefIndex;    // nil - эталон ещё не прочитан
    FInfos: TList;         // TIncFileInfo найденных копий - владелец
    FBusy: Boolean;
    FAbort: Boolean;
    FLastTick: Cardinal;
    FOnOpenFile: TFindIncOpenEvent;
    procedure ProgressStep(const AText: string; var ACancel: Boolean);
    procedure FoundStep(const AFile: string);
    procedure SetBusy(ABusy: Boolean);
    procedure ClearFound;
    procedure ShowInfo(AIndex: Integer);
    procedure UpdateLabels;
    function  SelectedInfo: TIncFileInfo;
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет.
    // По Alt Windows меняет показ подчёркиваний, и контролы окна пропадают
    // (см. TForm1.WMUpdateUIState) - сообщение дальше не передаём.
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  protected
    // Окно принадлежит окну редактора (Owner) и всегда над ним
    procedure CreateParams(var Params: TCreateParams); override;
  public
    // Показать окно. AName - имя файла (пусто - без поиска), ARefDir -
    // эталон, ASysDir - общие inc, ATargetDir - папка inc проекта, куда
    // копировать. AName задано - поиск начинается сразу.
    procedure ShowFind(const AName, ARefDir, ASysDir, ATargetDir: string;
                       const ACurDir: string = ''; const AUserIncDir: string = '');
    property OnOpenFile: TFindIncOpenEvent read FOnOpenFile write FOnOpenFile;
  end;

implementation

{$R *.dfm}

const
  // Цвета значков: не проверен / совпадает / отличается / нет в эталоне
  StatusColors: array[TIncStatus] of TColor =
    (clSilver, $0040B040, $0000C8FF, clWhite);

procedure TDlgFindInc.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgFindInc.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Без владельца немодальное окно Delphi 7 принадлежит скрытому окну
  // Application и уходит под редактор при щелчке по нему
  if (Owner is TWinControl) and TWinControl(Owner).HandleAllocated then
    Params.WndParent := TWinControl(Owner).Handle;
end;

procedure TDlgFindInc.ShowFind(const AName, ARefDir, ASysDir,
                               ATargetDir: string; const ACurDir: string;
                               const AUserIncDir: string);
begin
  FCurDir := ExcludeTrailingPathDelimiter(ACurDir);
  FUserIncDir := ExcludeTrailingPathDelimiter(AUserIncDir);
  Show;
  BringToFront;
  if FBusy then
    Exit;
  // Эталон сменился - перечитать при поиске
  if (CompareText(ARefDir, FRefDir) <> 0) or
     (CompareText(ASysDir, FSysDir) <> 0) then
    FreeAndNil(FRef);
  FRefDir := ARefDir;
  FSysDir := ASysDir;
  FTargetDir := ATargetDir;
  UpdateLabels;
  if AName <> '' then
  begin
    edName.Text := AName;
    Update;
    btnFindClick(nil);
  end
  else if edName.CanFocus then
    edName.SetFocus;
end;

procedure TDlgFindInc.FormDestroy(Sender: TObject);
begin
  FAbort := True;
  ClearFound;
  FreeAndNil(FInfos);
  FreeAndNil(FRef);
  FreeAndNil(FFoundWhere);
end;

procedure TDlgFindInc.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FBusy then
    FAbort := True;
end;

procedure TDlgFindInc.UpdateLabels;
begin
  lblFolder.Caption := 'Где искать: Include, Include system, ' +
                       'текущая папка, папка выше';
  if chkAllDrives.Checked then
    lblFolder.Caption := lblFolder.Caption + ', затем все локальные диски'
  else if FSearchDir <> '' then
    lblFolder.Caption := lblFolder.Caption + ', затем ' + FSearchDir;
  lblFolder.Hint := 'Include: ' + FUserIncDir + #13#10'Include system: ' +
                    FSysDir + #13#10'Текущая: ' + FCurDir;
  lblFolder.ShowHint := True;
  btnFolder.Enabled := not chkAllDrives.Checked and not FBusy;
  if FTargetDir = '' then
    lblTarget.Caption := 'Куда копировать: папка не задана'
  else
    lblTarget.Caption := 'Куда копировать: ' + FTargetDir;
end;

// Шаг долгой работы: раз в 100 мс - строка хода и очередь сообщений
procedure TDlgFindInc.ProgressStep(const AText: string; var ACancel: Boolean);
begin
  ACancel := FAbort;
  if ACancel or (GetTickCount - FLastTick < 100) then
    Exit;
  FLastTick := GetTickCount;
  lblStatus.Caption := AText;
  Application.ProcessMessages;
  ACancel := FAbort;
end;

procedure TDlgFindInc.SetBusy(ABusy: Boolean);
begin
  FBusy := ABusy;
  if ABusy then
  begin
    FAbort := False;
    FLastTick := 0;
    btnFind.Caption := 'Стоп';
  end
  else
    btnFind.Caption := 'Найти';
  edName.Enabled := not ABusy;
  chkAllDrives.Enabled := not ABusy;
  btnTarget.Enabled := not ABusy;
  btnCopy.Enabled := not ABusy;
  btnOpen.Enabled := not ABusy;
  UpdateLabels;
end;

procedure TDlgFindInc.ClearFound;
var
  ItemIdx: Integer;
begin
  if FInfos <> nil then
  begin
    for ItemIdx := 0 to FInfos.Count - 1 do
      TObject(FInfos[ItemIdx]).Free;
    FInfos.Clear;
  end;
  if FFoundWhere <> nil then
    FFoundWhere.Clear;
  if csDestroying in ComponentState then
    Exit;
  lstFound.Items.Clear;
  lstErrors.Items.Clear;
  lblHead.Caption := '';
end;

// Найден файл: сразу в список, с проверкой по эталону (после "Стоп" -
// без проверки, серый значок)
procedure TDlgFindInc.FoundStep(const AFile: string);
var
  Info: TIncFileInfo;
begin
  if lstFound.Items.IndexOf(AFile) >= 0 then
    Exit;
  Info := TIncFileInfo.Create(AFile);
  if not FAbort then
    IncCheckFile(Info, FRef);
  Inc(FCounts[Info.Status]);
  FInfos.Add(Info);
  FFoundWhere.Add(FStageLabel);
  lstFound.Items.AddObject(AFile, Info);
  lblFound.Caption := Format('Найдено копий %s: %d', [FFindName,
                                                       lstFound.Items.Count]);
  if lstFound.Items.Count = 1 then
  begin
    lstFound.ItemIndex := 0;
    ShowInfo(0);
  end;
end;

procedure TDlgFindInc.btnFindClick(Sender: TObject);
var
  Roots, Searched, StageFiles, StageList: TStringList;
  SearchName, StageRoot, WhereText: string;
  Drives: array[0..255] of Char;
  DrivePtr: PChar;
  FileIdx, StageIdx, SkipIdx, WhereCount: Integer;
  Done, Covered: Boolean;
  Status: TIncStatus;

  // Шаг поиска: подпись и папка; папки нет на диске - шага нет
  procedure AddStage(const ALabel, ADir: string);
  begin
    if (Trim(ADir) <> '') and DirectoryExists(ADir) then
      Roots.Add(ALabel + '|' + ExcludeTrailingPathDelimiter(ADir));
  end;

begin
  if FBusy then
  begin
    FAbort := True;
    Exit;
  end;
  SearchName := Trim(edName.Text);
  // Из строки $INCLUDE могли вставить с кавычками или с путём
  if (SearchName <> '') and (SearchName[1] in ['"', '<']) then
    SearchName := Copy(SearchName, 2, Length(SearchName) - 2);
  SearchName := ExtractFileName(SearchName);
  if SearchName = '' then
  begin
    lblStatus.Caption := 'Введите имя файла или маску, например QColorDialog10.inc, QColorDialog*.inc';
    Exit;
  end;
  FFindName := SearchName;
  Roots := TStringList.Create;
  Searched := TStringList.Create;
  StageFiles := TStringList.Create;
  SetBusy(True);
  try
    ClearFound;
    // Шаги поиска по порядку: "где|папка"
    AddStage('Include', FUserIncDir);
    AddStage('Include system', FSysDir);
    AddStage('текущая папка', FCurDir);
    if FCurDir <> '' then
      AddStage('папка выше', ExtractFileDir(FCurDir));
    if chkAllDrives.Checked then
    begin
      // Локальные диски: C:\, D:\ ... (без сетевых, CD и съёмных)
      FillChar(Drives, SizeOf(Drives), 0);
      GetLogicalDriveStrings(SizeOf(Drives) - 1, Drives);
      DrivePtr := Drives;
      while DrivePtr^ <> #0 do
      begin
        if GetDriveType(DrivePtr) = DRIVE_FIXED then
          AddStage('диск ' + Copy(StrPas(DrivePtr), 1, 2), StrPas(DrivePtr));
        Inc(DrivePtr, StrLen(DrivePtr) + 1);
      end;
    end
    else if FSearchDir <> '' then
      AddStage('выбранная папка', FSearchDir);

    // Эталон - один раз за сеанс окна
    if FRef = nil then
    begin
      FRef := TIncRefIndex.Create;
      if not FRef.Load(FRefDir, FSysDir, ProgressStep) then
      begin
        FreeAndNil(FRef);
        lblStatus.Caption := 'Прервано: эталон не прочитан';
        Exit;
      end;
    end;

    // Список заполняется по ходу поиска (FoundStep)
    for Status := Low(TIncStatus) to High(TIncStatus) do
      FCounts[Status] := 0;
    if FInfos = nil then
      FInfos := TList.Create;
    if FFoundWhere = nil then
      FFoundWhere := TStringList.Create;
    lblFound.Caption := Format('Найдено копий %s: 0', [SearchName]);

    // Шаг за шагом; папка, просмотренная раньше (или внутри неё), второй
    // раз не обходится. В каждой папке подпапки с "inc" в имени - первыми.
    Done := True;
    Searched.Sorted := True;
    Searched.Duplicates := dupIgnore;
    for StageIdx := 0 to Roots.Count - 1 do
    begin
      StageRoot := UpperCase(IncludeTrailingPathDelimiter(
                     Copy(Roots[StageIdx], Pos('|', Roots[StageIdx]) + 1, MaxInt)));
      Covered := False;
      for SkipIdx := 0 to Searched.Count - 1 do
        if Copy(StageRoot, 1, Length(Searched[SkipIdx])) = Searched[SkipIdx] then
          Covered := True;
      if Covered then
        Continue;
      FStageLabel := Copy(Roots[StageIdx], 1, Pos('|', Roots[StageIdx]) - 1);
      StageList := TStringList.Create;
      try
        StageList.Add(Copy(Roots[StageIdx], Pos('|', Roots[StageIdx]) + 1, MaxInt));
        StageFiles.Clear;
        Done := IncFindOnDisk(SearchName, StageList, StageFiles, ProgressStep,
                              Searched, FoundStep);
      finally
        StageList.Free;
      end;
      Searched.Add(StageRoot);
      if not Done then
        Break;
    end;

    // Сколько где нашлось, в порядке шагов
    WhereText := '';
    for StageIdx := 0 to Roots.Count - 1 do
    begin
      StageRoot := Copy(Roots[StageIdx], 1, Pos('|', Roots[StageIdx]) - 1);
      WhereCount := 0;
      for FileIdx := 0 to FFoundWhere.Count - 1 do
        if FFoundWhere[FileIdx] = StageRoot then
          Inc(WhereCount);
      if WhereCount > 0 then
      begin
        if WhereText <> '' then
          WhereText := WhereText + ', ';
        WhereText := WhereText + Format('%s: %d', [StageRoot, WhereCount]);
      end;
    end;
    lblFound.Caption := Format('Найдено копий %s: %d', [SearchName,
                                                         lstFound.Items.Count]);
    if WhereText <> '' then
      lblFound.Caption := lblFound.Caption + ' (' + WhereText + ')';
    if lstFound.Items.Count = 0 then
      lblStatus.Caption := 'Файл ' + SearchName + ' не найден'
    else
    begin
      lblStatus.Caption := Format('Совпадают с эталоном: %d, отличаются: %d, ' +
                                  'нет в эталоне: %d',
                                  [FCounts[isSame], FCounts[isChanged],
                                   FCounts[isNew]]);
      if FCounts[isUnknown] > 0 then
        lblStatus.Caption := lblStatus.Caption +
                             Format(', не проверено: %d', [FCounts[isUnknown]]);
    end;
    // Остановили - так и написать, и при пустом списке тоже
    if not Done or FAbort then
      lblStatus.Caption := 'Поиск остановлен. ' + lblStatus.Caption;
  finally
    SetBusy(False);
    StageFiles.Free;
    Searched.Free;
    Roots.Free;
  end;
  if (lstFound.ItemIndex < 0) and (lstFound.Items.Count > 0) then
  begin
    lstFound.ItemIndex := 0;
    ShowInfo(0);
  end;
end;

procedure TDlgFindInc.edNameKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    btnFindClick(nil);
  end;
end;

procedure TDlgFindInc.chkAllDrivesClick(Sender: TObject);
begin
  UpdateLabels;
end;

procedure TDlgFindInc.btnFolderClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FSearchDir;
  if BrowseFolderDialog('Где искать inc-файл', Dir) then
  begin
    FSearchDir := ExcludeTrailingPathDelimiter(Dir);
    UpdateLabels;
  end;
end;

procedure TDlgFindInc.btnTargetClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FTargetDir;
  if BrowseFolderDialog('Куда копировать inc-файл', Dir) then
  begin
    FTargetDir := ExcludeTrailingPathDelimiter(Dir);
    UpdateLabels;
  end;
end;

function TDlgFindInc.SelectedInfo: TIncFileInfo;
begin
  Result := nil;
  if (lstFound.ItemIndex >= 0) and
     (lstFound.ItemIndex < lstFound.Items.Count) then
    Result := TIncFileInfo(lstFound.Items.Objects[lstFound.ItemIndex]);
end;

// Сведения о копии: статус, эталон, замечания
procedure TDlgFindInc.ShowInfo(AIndex: Integer);
var
  Info: TIncFileInfo;
  Head: string;
  Age, MsgIdx, TextMax: Integer;
begin
  lstErrors.Items.Clear;
  if (AIndex < 0) or (AIndex >= lstFound.Items.Count) then
  begin
    lblHead.Caption := '';
    Exit;
  end;
  Info := TIncFileInfo(lstFound.Items.Objects[AIndex]);
  Head := IncStatusNames[Info.Status];
  if (Info.RefFile <> '') and (Info.Status <> isNew) then
    Head := Head + ' (' + ExtractFileName(Info.RefFile) + ')';
  if Info.Errors > 0 then
    Head := Head + Format(', ошибок: %d', [Info.Errors]);
  Age := FileAge(Info.FileName);
  if Age <> -1 then
    Head := Head + ', ' +
            FormatDateTime('dd.mm.yyyy hh:nn', FileDateToDateTime(Age));
  lblHead.Caption := Head;
  lstErrors.Items.Assign(Info.Messages);
  if Info.Status = isUnknown then
    lstErrors.Items.Add('не проверен: поиск остановлен до проверки')
  else if lstErrors.Items.Count = 0 then
    lstErrors.Items.Add('замечаний нет');
  // Длинные сообщения - с горизонтальной прокруткой
  TextMax := 0;
  for MsgIdx := 0 to lstErrors.Items.Count - 1 do
    if lstErrors.Canvas.TextWidth(lstErrors.Items[MsgIdx]) > TextMax then
      TextMax := lstErrors.Canvas.TextWidth(lstErrors.Items[MsgIdx]);
  lstErrors.ScrollWidth := TextMax + 8;
end;

procedure TDlgFindInc.lstFoundClick(Sender: TObject);
begin
  ShowInfo(lstFound.ItemIndex);
end;

procedure TDlgFindInc.lstFoundDblClick(Sender: TObject);
begin
  if FBusy then
    Exit;
  btnOpenClick(nil);
end;

procedure TDlgFindInc.btnOpenClick(Sender: TObject);
var
  Info: TIncFileInfo;
begin
  Info := SelectedInfo;
  if (Info <> nil) and Assigned(FOnOpenFile) then
    FOnOpenFile(Info.FileName, 0);
end;

procedure TDlgFindInc.lstErrorsDblClick(Sender: TObject);
var
  Info: TIncFileInfo;
begin
  Info := SelectedInfo;
  if (Info = nil) or (lstErrors.ItemIndex < 0) or
     (lstErrors.ItemIndex >= Info.Messages.Count) or
     not Assigned(FOnOpenFile) then
    Exit;
  FOnOpenFile(Info.FileName,
              Integer(Info.Messages.Objects[lstErrors.ItemIndex]));
end;

// Значок статуса, путь и красное число ошибок
procedure TDlgFindInc.lstFoundDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  Canvas: TCanvas;
  Info: TIncFileInfo;
  TextX: Integer;
begin
  Canvas := lstFound.Canvas;
  Canvas.FillRect(Rect);
  if (Index < 0) or (Index >= lstFound.Items.Count) then
    Exit;
  Info := TIncFileInfo(lstFound.Items.Objects[Index]);
  Canvas.Pen.Color := clGray;
  Canvas.Brush.Color := StatusColors[Info.Status];
  Canvas.Ellipse(Rect.Left + 3, Rect.Top + 3, Rect.Left + 14, Rect.Top + 14);
  if odSelected in State then
  begin
    Canvas.Brush.Color := clHighlight;
    Canvas.Font.Color := clHighlightText;
  end
  else
  begin
    Canvas.Brush.Color := lstFound.Color;
    Canvas.Font.Color := lstFound.Font.Color;
  end;
  TextX := Rect.Left + 18;
  // Где нашлась: текущая папка, Include user ... - перед путём
  if (FFoundWhere <> nil) and (Index < FFoundWhere.Count) then
  begin
    Canvas.TextOut(TextX, Rect.Top + 2, '[' + FFoundWhere[Index] + ']');
    TextX := TextX + Canvas.TextWidth('[' + FFoundWhere[Index] + ']') + 6;
  end;
  Canvas.TextOut(TextX, Rect.Top + 2, lstFound.Items[Index]);
  if Info.Errors > 0 then
  begin
    TextX := TextX + Canvas.TextWidth(lstFound.Items[Index]) + 6;
    if not (odSelected in State) then
      Canvas.Font.Color := clRed;
    Canvas.Font.Style := [fsBold];
    Canvas.TextOut(TextX, Rect.Top + 2, IntToStr(Info.Errors));
    Canvas.Font.Style := [];
  end;
end;

// Выбранная копия - в папку inc проекта. Уже есть файл с этим именем:
// такой же - ничего не делаем, другой - спрашиваем, прежний - в .bak.
// Защиты нет - ставится в копию (исходный файл не меняется).
procedure TDlgFindInc.btnCopyClick(Sender: TObject);
var
  Info: TIncFileInfo;
  Target, Err, Note: string;
  OldLines, NewLines: TStringList;
begin
  Info := SelectedInfo;
  if Info = nil then
  begin
    lblStatus.Caption := 'Выберите копию в списке';
    Exit;
  end;
  if (FTargetDir = '') or not DirectoryExists(FTargetDir) then
  begin
    lblStatus.Caption := 'Папка, куда копировать, не задана или её нет - ' +
                         'кнопка "..." справа от неё';
    Exit;
  end;
  Target := IncludeTrailingPathDelimiter(FTargetDir) +
            ExtractFileName(Info.FileName);
  if CompareText(ExpandFileName(Target), ExpandFileName(Info.FileName)) = 0 then
  begin
    lblStatus.Caption := 'Эта копия и так лежит в папке inc проекта';
    Exit;
  end;

  if FileExists(Target) then
  begin
    OldLines := TStringList.Create;
    NewLines := TStringList.Create;
    try
      OldLines.LoadFromFile(Target);
      NewLines.LoadFromFile(Info.FileName);
      if IncNormalize(OldLines) = IncNormalize(NewLines) then
      begin
        lblStatus.Caption := 'В папке inc проекта уже есть такой же ' +
                             ExtractFileName(Target);
        Exit;
      end;
    finally
      NewLines.Free;
      OldLines.Free;
    end;
    if MessageDlg(ExtractFileName(Target) + ' уже есть в ' + FTargetDir +
                  ', и текст другой.'#13#10#13#10'Заменить его выбранной ' +
                  'копией? Прежний файл сохранится как ' +
                  ExtractFileName(Target) + '.bak.',
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    DeleteFile(Target + '.bak');
    if not RenameFile(Target, Target + '.bak') then
    begin
      lblStatus.Caption := 'Не удалось сохранить прежний файл в .bak: ' +
                           SysErrorMessage(GetLastError);
      Exit;
    end;
  end;

  if not Windows.CopyFile(PChar(Info.FileName), PChar(Target), True) then
  begin
    lblStatus.Caption := 'Не удалось скопировать: ' +
                         SysErrorMessage(GetLastError);
    Exit;
  end;
  Note := '';
  if Info.Guard = '' then
  begin
    if IncAddGuard(Target, IncGuardName(Info), Err, False) then
      Note := ', защита ' + IncGuardName(Info) + ' поставлена'
    else
      Note := ', защита не поставлена: ' + Err;
  end;
  lblStatus.Caption := 'Скопирован в ' + Target + Note;
  if Info.Errors > 0 then
    lblStatus.Caption := lblStatus.Caption +
                         Format('; в файле замечаний-ошибок: %d', [Info.Errors]);
end;

end.
