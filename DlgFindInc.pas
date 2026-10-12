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
    FRef: TIncRefIndex;    // nil - эталон ещё не прочитан
    FInfos: TList;         // TIncFileInfo найденных копий - владелец
    FBusy: Boolean;
    FAbort: Boolean;
    FLastTick: Cardinal;
    FOnOpenFile: TFindIncOpenEvent;
    procedure ProgressStep(const AText: string; var ACancel: Boolean);
    procedure SetBusy(ABusy: Boolean);
    procedure ClearFound;
    procedure ShowInfo(AIndex: Integer);
    procedure UpdateLabels;
    function  SelectedInfo: TIncFileInfo;
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет.
    // По Alt Windows меняет показ подчёркиваний, и контролы окна пропадают
    // (см. TForm1.WMUpdateUIState) - сообщение дальше не передаём.
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    // Показать окно. AName - имя файла (пусто - без поиска), ARefDir -
    // эталон, ASysDir - общие inc, ATargetDir - папка inc проекта, куда
    // копировать. AName задано - поиск начинается сразу.
    procedure ShowFind(const AName, ARefDir, ASysDir, ATargetDir: string);
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

procedure TDlgFindInc.ShowFind(const AName, ARefDir, ASysDir,
                               ATargetDir: string);
begin
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
end;

procedure TDlgFindInc.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FBusy then
    FAbort := True;
end;

procedure TDlgFindInc.UpdateLabels;
begin
  if chkAllDrives.Checked then
    lblFolder.Caption := 'Где искать: все локальные диски'
  else if FSearchDir = '' then
    lblFolder.Caption := 'Где искать: папка не выбрана'
  else
    lblFolder.Caption := 'Где искать: ' + FSearchDir;
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
  if csDestroying in ComponentState then
    Exit;
  lstFound.Items.Clear;
  lstErrors.Items.Clear;
  lblHead.Caption := '';
end;

// Найти: имя - на дисках или в папке, каждая копия - с эталоном и на
// ошибки. Идёт поиск - кнопка останавливает его.
procedure TDlgFindInc.btnFindClick(Sender: TObject);
var
  Roots, Files: TStringList;
  SearchName: string;
  Drives: array[0..255] of Char;
  DrivePtr: PChar;
  FileIdx: Integer;
  Info: TIncFileInfo;
  Cancel, Done: Boolean;
  Counts: array[TIncStatus] of Integer;
  Status: TIncStatus;
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
    lblStatus.Caption := 'Введите имя файла, например QColorDialog10.inc';
    Exit;
  end;
  if not chkAllDrives.Checked and (FSearchDir = '') then
  begin
    lblStatus.Caption := 'Выберите папку поиска (кнопка "...") или ' +
                         'отметьте "Все локальные диски"';
    Exit;
  end;

  Roots := TStringList.Create;
  Files := TStringList.Create;
  SetBusy(True);
  try
    ClearFound;
    if chkAllDrives.Checked then
    begin
      // Локальные диски: C:\, D:\ ... (без сетевых, CD и съёмных)
      FillChar(Drives, SizeOf(Drives), 0);
      GetLogicalDriveStrings(SizeOf(Drives) - 1, Drives);
      DrivePtr := Drives;
      while DrivePtr^ <> #0 do
      begin
        if GetDriveType(DrivePtr) = DRIVE_FIXED then
          Roots.Add(StrPas(DrivePtr));
        Inc(DrivePtr, StrLen(DrivePtr) + 1);
      end;
    end
    else
      Roots.Add(FSearchDir);

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

    Done := IncFindOnDisk(SearchName, Roots, Files, ProgressStep);
    Files.Sort;

    for Status := Low(TIncStatus) to High(TIncStatus) do
      Counts[Status] := 0;
    Cancel := False;
    if FInfos = nil then
      FInfos := TList.Create;
    for FileIdx := 0 to Files.Count - 1 do
    begin
      ProgressStep(Format('Проверка: %d из %d', [FileIdx + 1, Files.Count]),
                   Cancel);
      if Cancel then
        Break;
      Info := TIncFileInfo.Create(Files[FileIdx]);
      IncCheckFile(Info, FRef);
      Inc(Counts[Info.Status]);
      FInfos.Add(Info);
      lstFound.Items.AddObject(Files[FileIdx], Info);
    end;

    lblFound.Caption := Format('Найдено копий %s: %d', [SearchName, Files.Count]);
    lblStatus.Caption := Format('Совпадают с эталоном: %d, отличаются: %d, ' +
                                'нет в эталоне: %d',
                                [Counts[isSame], Counts[isChanged],
                                 Counts[isNew]]);
    if not Done or Cancel then
      lblStatus.Caption := 'Поиск прерван. ' + lblStatus.Caption;
    if Files.Count = 0 then
      lblStatus.Caption := 'Файл ' + SearchName + ' не найден';
  finally
    SetBusy(False);
    Files.Free;
    Roots.Free;
  end;
  if lstFound.Items.Count > 0 then
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
  if lstErrors.Items.Count = 0 then
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
