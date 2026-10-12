unit Unit3;

// INC Manager (View - IncManager...): свои inc-файлы пользователя рядом с
// общими, что ставятся с редактором (rapidqAllProc.inc,
// rapidqComponents.inc). Цель - проверить свои файлы на ошибки, уже
// исправленные в эталоне, и найти то, чего в эталоне нет.
//
//   1. Список папок, где лежат свои inc: папка выбирается слева (диск и
//      дерево), "Добавить" кладёт её в список; галка - папка участвует.
//   2. Файлы .inc отмеченных папок - справа (с подпапками по флажку).
//   3. Сравнение с эталоном (исходные inc общих - rapidq_ref\incOld):
//      зелёный - совпадает, жёлтый - эталон с тем же именем отличается,
//      белый - в эталоне нет (кандидат в хранилище).
//   4. "Защитный $IFNDEF" - в начало отмеченных файлов без защиты; имя
//      защиты - как у эталона (тогда свой файл и общие исключают друг
//      друга). Прежний текст - в <файл>.bak.
//   5. Ошибки каждого файла - под списком папок, по выбранному файлу;
//      двойной щелчок - строка в редакторе. Красное число у файла - ошибки.
//   6. "Демо-программа" - программа .bas, подключающая файл: найденная в
//      папках из списка или новая <имя>_demo.bas рядом с файлом.
//   7. Щелчок по надписи эталона - в правом списке файлы эталонной папки
//      (ещё щелчок - снова свои).
//   8. Состав выбранного файла (справа от замечаний): процедуры, функции
//      DLL, компоненты с галками; "Изъять" - каждый отмеченный в свой
//      <имя>.inc рядом с файлом вместе с тем, чем пользуется только он
//      (IncEdit.pas). Пункт, нужный оставшемуся в файле или файлу, который
//      его подключает, не изымается - причина в списке замечаний.
//   9. "Собрать в один..." - отмеченные галкой файлы в один новый; из
//      одноимённых объявлений остаётся первое.
//
// Проверки - в IncCheck.pas (без VCL). Список папок и путь эталона - в
// editor.ini, раздел [IncManager]:
//   Count=2
//   Folder1=C:\BAS\RAPIDQ\INC|1     (1 - отмечена, 0 - нет)
//   SubDirs=1                       (искать и в подпапках)
//   RefPath=...\rapidq_ref\incOld   (пусто - по умолчанию)
// Записывается сразу при каждой правке - окно немодальное, кнопки OK нет.

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, ExtCtrls, FileCtrl, StdCtrls, Buttons, CheckLst,
  IniFiles,
  IncCheck,     // сравнение с эталоном, проверки, защита, демо
  IncEdit,      // состав файла, изъятие пунктов, сборка файлов в один
  UiEditCtrls,  // TUiEdit - поле фильтра состава
  FolderDlg,    // выбор папки эталона - BrowseFolderDialog
  UiStdCtrls,   // TUiPanel
  UiButton;     // TUiButton - кнопки в цветах темы (TBitBtn рисуется белым)

type
  // Открыть файл в редакторе на строке (с 1; 0 - без перехода)
  TIncOpenFileEvent = procedure(const AFile: string; ALine: Integer) of object;
  // Выбор строки из списка ('' - отказались)
  TIncChooseEvent = function(const ACaption, APrompt: string;
                             AItems: TStrings): string of object;

  TForm3 = class(TForm)
    UiPanel1: TUiPanel;
    Label1: TLabel;
    lstIncFiles: TCheckListBox;
    btnScan: TUiButton;
    btnGuard: TUiButton;
    btnDemo: TUiButton;
    lblCount: TLabel;
    lblLegend: TLabel;
    Panel2: TPanel;
    Panel1: TPanel;
    CheckListBox1: TCheckListBox;
    lblRef: TLabel;
    lblErrHead: TLabel;
    lstErrors: TListBox;
    btnRef: TUiButton;
    Splitter1: TSplitter;
    Panel3: TPanel;
    DirectoryListBox1: TDirectoryListBox;
    UiPanel2: TUiPanel;
    DriveComboBox1: TDriveComboBox;
    Panel4: TPanel;
    BitBtn1: TUiButton;
    BitBtn2: TUiButton;
    chkSubDirs: TCheckBox;
    lblFolders: TLabel;
    Splitter2: TSplitter;
    pnlRef: TPanel;
    pnlFileBtns: TPanel;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure CheckListBox1ClickCheck(Sender: TObject);
    procedure chkSubDirsClick(Sender: TObject);
    procedure lstIncFilesDrawItem(Control: TWinControl; Index: Integer;
                                  Rect: TRect; State: TOwnerDrawState);
    procedure lstIncFilesClick(Sender: TObject);
    procedure lstIncFilesDblClick(Sender: TObject);
    procedure lstErrorsDblClick(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure btnGuardClick(Sender: TObject);
    procedure btnDemoClick(Sender: TObject);
    procedure btnRefClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    FBusy: Boolean;        // идёт чтение эталона или проверка файлов
    FAbort: Boolean;       // нажат Стоп
    FLastTick: Cardinal;   // последний показ хода (ProgressStep)
    FInfos: TList;         // TIncFileInfo всех строк lstIncFiles - владелец
    FIniFile: string;
    FSysDir: string;       // общие inc (SysIncPath)
    FDefaultRef: string;   // эталон по умолчанию
    FRefDir: string;       // эталон сейчас
    FRef: TIncRefIndex;    // nil - эталон ещё не прочитан
    FLoading: Boolean;     // список заполняется из editor.ini - не записывать
    FOnOpenFile: TIncOpenFileEvent;
    FOnChoose: TIncChooseEvent;
    // Правый список - файлы эталонной папки (щелчок по надписи эталона)
    FShowRef: Boolean;
    // Состав выбранного файла: разобранный файл, все пункты, отмеченные
    // (отметки живут и при смене фильтра)
    FItemsDoc: TIncDoc;
    FItemsAll: TList;
    FItemsChecked: TList;
    pnlItems: TPanel;
    Splitter3: TSplitter;
    lblItems: TLabel;
    edItemsFilter: TUiEdit;
    lstItems: TCheckListBox;
    btnItemsAll, btnItemsNone, btnExtract: TUiButton;
    btnMerge, btnFilesAll, btnFilesNone: TUiButton;
    procedure ProgressStep(const AText: string; var ACancel: Boolean);
    procedure SetBusy(ABusy: Boolean);
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет.
    // По Alt Windows меняет показ подчёркиваний, и контролы окна пропадают
    // (см. TForm1.WMUpdateUIState) - сообщение дальше не передаём.
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
    procedure LoadFolders;
    procedure SaveFolders;
    procedure ClearInfos;
    procedure FillIncFiles;
    function  EnsureRef(AReload: Boolean): Boolean;
    procedure ShowMessagesOf(AIndex: Integer);
    procedure CheckedFolders(AList: TStrings);
    function  SelectedInfo: TIncFileInfo;
    procedure BuildItemsPane;
    procedure LoadItemsOf(const AFile: string);
    procedure FillItems;
    procedure ShowReport(const AHead: string; AReport: TStrings);
    procedure SelectFileByName(const AFile: string);
    procedure lblRefClick(Sender: TObject);
    procedure ItemsFilterChange(Sender: TObject);
    procedure ItemsClickCheck(Sender: TObject);
    procedure ItemsDblClick(Sender: TObject);
    procedure btnItemsAllClick(Sender: TObject);
    procedure btnExtractClick(Sender: TObject);
    procedure btnMergeClick(Sender: TObject);
    procedure btnFilesAllClick(Sender: TObject);
  public
    // Показать окно. AIniFile - editor.ini, ASysDir - папка общих inc,
    // ADefaultRef - эталон, если в editor.ini свой не задан.
    procedure ShowFor(const AIniFile, ASysDir, ADefaultRef: string);
    property OnOpenFile: TIncOpenFileEvent read FOnOpenFile write FOnOpenFile;
    property OnChoose: TIncChooseEvent read FOnChoose write FOnChoose;
  end;

const
  IncMgrSection = 'IncManager';
  IncMgrMaxFiles = 20000;   // больше - скорее всего, выбран корень диска

var
  Form3: TForm3;

implementation

{$R *.dfm}

const
  // Цвета значков: совпадает / отличается / нет в эталоне
  StatusColors: array[TIncStatus] of TColor =
    (clSilver, $0040B040, $0000C8FF, clWhite);

procedure TForm3.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

// Окно - сразу, потом чтение эталона и проверка файлов: ход - в строке
// под списком, кнопка Сканировать на это время - Стоп
procedure TForm3.ShowFor(const AIniFile, ASysDir, ADefaultRef: string);
begin
  Show;
  BringToFront;
  if FBusy then
    Exit;
  FIniFile := AIniFile;
  FSysDir := ASysDir;
  FDefaultRef := ADefaultRef;
  Update;
  LoadFolders;
end;

procedure TForm3.FormDestroy(Sender: TObject);
begin
  FAbort := True;
  ClearInfos;
  FreeAndNil(FInfos);
  FreeAndNil(FRef);
  FreeAndNil(FItemsDoc);
  FreeAndNil(FItemsAll);
  FreeAndNil(FItemsChecked);
end;

// Закрыли окно во время проверки - остановить
procedure TForm3.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FBusy then
    FAbort := True;
end;

// Шаг долгой работы: раз в 100 мс - строка хода и очередь сообщений
// (окно живое, Стоп нажимается). ACancel - нажали Стоп.
procedure TForm3.ProgressStep(const AText: string; var ACancel: Boolean);
begin
  ACancel := FAbort;
  if ACancel or (GetTickCount - FLastTick < 100) then
    Exit;
  FLastTick := GetTickCount;
  lblCount.Caption := AText;
  Application.ProcessMessages;
  ACancel := FAbort;
end;

// На время проверки - только Стоп: папки и кнопки, которые запускают
// проверку заново или пишут в файлы, недоступны
procedure TForm3.SetBusy(ABusy: Boolean);
begin
  FBusy := ABusy;
  if ABusy then
  begin
    FAbort := False;
    FLastTick := 0;
    btnScan.Caption := 'Стоп';
  end
  else
    btnScan.Caption := 'Сканировать';
  Panel1.Enabled := not ABusy;
  btnRef.Enabled := not ABusy;
  btnGuard.Enabled := not ABusy;
  btnDemo.Enabled := not ABusy;
end;

procedure TForm3.LoadFolders;
var
  Ini: TIniFile;
  Count, FolderIdx, BarPos, ItemIdx: Integer;
  Value, Dir, RefDir: string;
begin
  FLoading := True;
  RefDir := '';
  try
    CheckListBox1.Items.Clear;
    if FileExists(FIniFile) then
    begin
      Ini := TIniFile.Create(FIniFile);
      try
        chkSubDirs.Checked := Ini.ReadBool(IncMgrSection, 'SubDirs', True);
        RefDir := Trim(Ini.ReadString(IncMgrSection, 'RefPath', ''));
        Count := Ini.ReadInteger(IncMgrSection, 'Count', 0);
        for FolderIdx := 1 to Count do
        begin
          Value := Trim(Ini.ReadString(IncMgrSection,
                                       'Folder' + IntToStr(FolderIdx), ''));
          BarPos := Pos('|', Value);
          if BarPos > 0 then
            Dir := Trim(Copy(Value, 1, BarPos - 1))
          else
            Dir := Value;
          if Dir = '' then
            Continue;
          ItemIdx := CheckListBox1.Items.Add(Dir);
          CheckListBox1.Checked[ItemIdx] :=
            (BarPos = 0) or (Trim(Copy(Value, BarPos + 1, 10)) <> '0');
        end;
      finally
        Ini.Free;
      end;
    end;
  finally
    FLoading := False;
  end;
  if RefDir = '' then
    RefDir := FDefaultRef;
  // Эталон сменился (или ещё не читался) - перечитать
  if (FRef = nil) or (CompareText(RefDir, FRefDir) <> 0) then
  begin
    FRefDir := RefDir;
    FreeAndNil(FRef);
  end;
  FillIncFiles;
end;

procedure TForm3.SaveFolders;
var
  Ini: TIniFile;
  ItemIdx: Integer;
  Flag: string;
begin
  if FLoading or (FIniFile = '') then
    Exit;
  Ini := TIniFile.Create(FIniFile);
  try
    // RefPath переживает перезапись раздела
    Ini.EraseSection(IncMgrSection);
    Ini.WriteBool(IncMgrSection, 'SubDirs', chkSubDirs.Checked);
    if CompareText(FRefDir, FDefaultRef) <> 0 then
      Ini.WriteString(IncMgrSection, 'RefPath', FRefDir);
    Ini.WriteInteger(IncMgrSection, 'Count', CheckListBox1.Items.Count);
    for ItemIdx := 0 to CheckListBox1.Items.Count - 1 do
    begin
      if CheckListBox1.Checked[ItemIdx] then
        Flag := '1'
      else
        Flag := '0';
      Ini.WriteString(IncMgrSection, 'Folder' + IntToStr(ItemIdx + 1),
                      CheckListBox1.Items[ItemIdx] + '|' + Flag);
    end;
  finally
    Ini.Free;
  end;
end;

// Сведения о файлах - в своём списке FInfos, а не только в строках
// lstIncFiles: при разрушении формы к списку на экране не обращаемся (его
// окно уже уничтожено, а Items создавали бы его заново - исключение при
// выходе из программы обрывало разрушение остальных форм)
procedure TForm3.ClearInfos;
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
  lstIncFiles.Items.Clear;
  lstErrors.Items.Clear;
  lblErrHead.Caption := '';
end;

// Эталон: файлы папки FRefDir и имена общих inc (FSysDir). False -
// прервано Стопом (эталон тогда будет прочитан заново в следующий раз).
function TForm3.EnsureRef(AReload: Boolean): Boolean;
begin
  Result := True;
  if (FRef <> nil) and not AReload then
    Exit;
  if FRef = nil then
    FRef := TIncRefIndex.Create;
  lblRef.Caption := 'Эталон: читается...';
  if not FRef.Load(FRefDir, FSysDir, ProgressStep) then
  begin
    FreeAndNil(FRef);
    lblRef.Caption := 'Эталон: чтение прервано';
    Result := False;
    Exit;
  end;
  if FRef.RefCount = 0 then
    lblRef.Caption := 'Эталон: не найден (' + FRefDir + ')'
  else
    lblRef.Caption := Format('Эталон: %s (%d файлов)',
                             [FRefDir, FRef.RefCount]);
  lblRef.Hint := 'Общие inc: ' + FSysDir;
end;

procedure TForm3.CheckedFolders(AList: TStrings);
var
  ItemIdx: Integer;
begin
  AList.Clear;
  for ItemIdx := 0 to CheckListBox1.Items.Count - 1 do
    if CheckListBox1.Checked[ItemIdx] then
      AList.Add(CheckListBox1.Items[ItemIdx]);
end;

// Шаги 2, 3, 5: файлы .inc отмеченных папок (без повторов: папка и её
// подпапка в списке вместе не дают двойного счёта), сравнение с эталоном
// и проверка каждого
procedure TForm3.FillIncFiles;
var
  Files, Folders: TStringList;
  ItemIdx, Missing, Errors: Integer;
  Counts: array[TIncStatus] of Integer;
  Status: TIncStatus;
  Info: TIncFileInfo;
  Cancel: Boolean;
begin
  if FLoading or FBusy then
    Exit;
  SetBusy(True);
  Files := TStringList.Create;
  Folders := TStringList.Create;
  Cancel := False;
  try
    ClearInfos;
    if not EnsureRef(False) then
    begin
      lblCount.Caption := 'Прервано: эталон не прочитан. Сканировать - ' +
                          'начать заново';
      Exit;
    end;
    Files.Sorted := True;
    Files.Duplicates := dupIgnore;
    Missing := 0;
    if FShowRef then
    begin
      // Файлы эталонной папки - без подпапок
      Folders.Add(FRefDir);
      Label1.Caption := 'Файлы эталона (щелчок по надписи эталона - свои)';
    end
    else
    begin
      CheckedFolders(Folders);
      Label1.Caption := 'Файлы inc из отмеченных папок';
    end;
    for ItemIdx := 0 to Folders.Count - 1 do
      if not DirectoryExists(Folders[ItemIdx]) then
        Inc(Missing)
      else
        FindFilesExt(Folders[ItemIdx], '.inc', chkSubDirs.Checked and
                     not FShowRef, Files, IncMgrMaxFiles);

    for Status := Low(TIncStatus) to High(TIncStatus) do
      Counts[Status] := 0;
    Errors := 0;
    for ItemIdx := 0 to Files.Count - 1 do
    begin
      ProgressStep(Format('Проверка: %d из %d - %s',
                          [ItemIdx + 1, Files.Count,
                           ExtractFileName(Files[ItemIdx])]), Cancel);
      if Cancel then
        Break;
      Info := TIncFileInfo.Create(Files[ItemIdx]);
      IncCheckFile(Info, FRef);
      Inc(Counts[Info.Status]);
      if Info.Errors > 0 then
        Inc(Errors);
      if FInfos = nil then
        FInfos := TList.Create;
      FInfos.Add(Info);
      lstIncFiles.Items.AddObject(ExtractFileName(Files[ItemIdx]), Info);
      lstIncFiles.Checked[lstIncFiles.Items.Count - 1] := True;
    end;

    lblCount.Caption := Format('Файлов .inc: %d - совпадают: %d, ' +
                               'отличаются: %d, нет в эталоне: %d; ' +
                               'с ошибками: %d',
                               [Files.Count, Counts[isSame],
                                Counts[isChanged], Counts[isNew], Errors]);
    if Missing > 0 then
      lblCount.Caption := lblCount.Caption +
                          Format('; папок нет на диске: %d', [Missing]);
    if Cancel then
      lblCount.Caption := Format('Прервано: проверено %d из %d. ',
                                 [lstIncFiles.Items.Count, Files.Count]) +
                          lblCount.Caption;
  finally
    Folders.Free;
    Files.Free;
    SetBusy(False);
  end;
  if lstIncFiles.Items.Count > 0 then
  begin
    lstIncFiles.ItemIndex := 0;
    ShowMessagesOf(0);
    LoadItemsOf(SelectedInfo.FileName);
  end
  else
    LoadItemsOf('');
end;

function TForm3.SelectedInfo: TIncFileInfo;
begin
  Result := nil;
  if lstIncFiles.ItemIndex >= 0 then
    Result := TIncFileInfo(lstIncFiles.Items.Objects[lstIncFiles.ItemIndex]);
end;

// Сообщения файла - в список под папками
procedure TForm3.ShowMessagesOf(AIndex: Integer);
var
  Info: TIncFileInfo;
  Head: string;
  MsgIdx, TextMax: Integer;
begin
  lstErrors.Items.Clear;
  if (AIndex < 0) or (AIndex >= lstIncFiles.Items.Count) then
  begin
    lblErrHead.Caption := '';
    Exit;
  end;
  Info := TIncFileInfo(lstIncFiles.Items.Objects[AIndex]);
  Head := ExtractFileName(Info.FileName) + ' - ' +
          IncStatusNames[Info.Status];
  if (Info.RefFile <> '') and (Info.Status = isChanged) then
    Head := Head + ' (' + ExtractFileName(Info.RefFile) + ')';
  if Info.Errors > 0 then
    Head := Head + Format(', ошибок: %d', [Info.Errors]);
  lblErrHead.Caption := Head;
  lblErrHead.Hint := Info.FileName;
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

// Значок статуса, имя файла и красное число ошибок
procedure TForm3.lstIncFilesDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  Canvas: TCanvas;
  Info: TIncFileInfo;
  Mark: TRect;
  TextX: Integer;
  ErrText: string;
begin
  Canvas := lstIncFiles.Canvas;
  Canvas.FillRect(Rect);
  if (Index < 0) or (Index >= lstIncFiles.Items.Count) then
    Exit;
  Info := TIncFileInfo(lstIncFiles.Items.Objects[Index]);

  // Кружок статуса
  Mark := Classes.Rect(Rect.Left + 2, Rect.Top + 3, Rect.Left + 13,
                       Rect.Top + 14);
  Canvas.Pen.Color := clGray;
  Canvas.Brush.Color := StatusColors[Info.Status];
  Canvas.Ellipse(Mark.Left, Mark.Top, Mark.Right, Mark.Bottom);

  // Текст - цветом строки (выделенной или обычной)
  if odSelected in State then
  begin
    Canvas.Brush.Color := clHighlight;
    Canvas.Font.Color := clHighlightText;
  end
  else
  begin
    Canvas.Brush.Color := lstIncFiles.Color;
    Canvas.Font.Color := lstIncFiles.Font.Color;
  end;
  TextX := Mark.Right + 4;
  Canvas.TextOut(TextX, Rect.Top + 2, lstIncFiles.Items[Index]);
  if Info.Errors > 0 then
  begin
    TextX := TextX + Canvas.TextWidth(lstIncFiles.Items[Index]) + 6;
    ErrText := IntToStr(Info.Errors);
    if not (odSelected in State) then
      Canvas.Font.Color := clRed;
    Canvas.Font.Style := [fsBold];
    Canvas.TextOut(TextX, Rect.Top + 2, ErrText);
    Canvas.Font.Style := [];
  end;
end;

procedure TForm3.lstIncFilesClick(Sender: TObject);
begin
  ShowMessagesOf(lstIncFiles.ItemIndex);
  if SelectedInfo <> nil then
    LoadItemsOf(SelectedInfo.FileName);
end;

procedure TForm3.lstIncFilesDblClick(Sender: TObject);
var
  Info: TIncFileInfo;
begin
  Info := SelectedInfo;
  if (Info <> nil) and Assigned(FOnOpenFile) then
    FOnOpenFile(Info.FileName, 0);
end;

// Сообщение со строкой - файл в редакторе на этой строке
procedure TForm3.lstErrorsDblClick(Sender: TObject);
var
  Info: TIncFileInfo;
  Line: Integer;
begin
  Info := SelectedInfo;
  if (Info = nil) or (lstErrors.ItemIndex < 0) or
     (lstErrors.ItemIndex >= Info.Messages.Count) or
     not Assigned(FOnOpenFile) then
    Exit;
  Line := Integer(Info.Messages.Objects[lstErrors.ItemIndex]);
  FOnOpenFile(Info.FileName, Line);
end;

// Сканировать заново: эталон и файлы с диска
procedure TForm3.btnScanClick(Sender: TObject);
begin
  if FBusy then
  begin
    FAbort := True;
    Exit;
  end;
  FreeAndNil(FRef);   // FillIncFiles прочитает эталон заново
  FillIncFiles;
end;

// Шаг 4: защитный $IFNDEF в отмеченные файлы, где его нет
procedure TForm3.btnGuardClick(Sender: TObject);
var
  Todo, Failed: TStringList;
  ItemIdx, Done: Integer;
  Info: TIncFileInfo;
  Err: string;
begin
  Todo := TStringList.Create;
  Failed := TStringList.Create;
  try
    for ItemIdx := 0 to lstIncFiles.Items.Count - 1 do
    begin
      Info := TIncFileInfo(lstIncFiles.Items.Objects[ItemIdx]);
      if lstIncFiles.Checked[ItemIdx] and (Info.Guard = '') then
        Todo.AddObject(Info.FileName, Info);
    end;
    if Todo.Count = 0 then
    begin
      ShowMessage('У всех отмеченных файлов защитный $IFNDEF уже есть.');
      Exit;
    end;
    if MessageDlg(Format('Поставить защитный $IFNDEF в отмеченные файлы ' +
                         'без защиты: %d?'#13#10#13#10 +
                         'В начало файла - $IFNDEF и $DEFINE, в конец - ' +
                         '$ENDIF. Имя защиты - как у эталона, если он есть ' +
                         '(тогда свой файл и общие inc не подключатся ' +
                         'вместе). Прежний текст сохраняется в <файл>.bak.',
                         [Todo.Count]),
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    Done := 0;
    for ItemIdx := 0 to Todo.Count - 1 do
    begin
      Info := TIncFileInfo(Todo.Objects[ItemIdx]);
      if IncAddGuard(Info.FileName, IncGuardName(Info), Err) then
        Inc(Done)
      else
        Failed.Add(ExtractFileName(Info.FileName) + ': ' + Err);
      IncCheckFile(Info, FRef);
    end;
    lstIncFiles.Invalidate;
    ShowMessagesOf(lstIncFiles.ItemIndex);
    if Failed.Count = 0 then
      ShowMessage(Format('Защитный $IFNDEF поставлен в файлы: %d.', [Done]))
    else
      ShowMessage(Format('Защитный $IFNDEF поставлен в файлы: %d. ' +
                         'Не поставлен:'#13#10'%s', [Done, Failed.Text]));
  finally
    Failed.Free;
    Todo.Free;
  end;
end;

// Шаг 6: демо-программа выбранного файла - найденная или новая
procedure TForm3.btnDemoClick(Sender: TObject);
var
  Info: TIncFileInfo;
  Demos, Folders: TStringList;
  Demo, Err: string;
begin
  Info := SelectedInfo;
  if Info = nil then
  begin
    ShowMessage('Выберите файл в списке справа.');
    Exit;
  end;
  Demos := TStringList.Create;
  Folders := TStringList.Create;
  try
    Screen.Cursor := crHourGlass;
    try
      CheckedFolders(Folders);
      IncFindDemos(Info.FileName, Folders, chkSubDirs.Checked, Demos);
    finally
      Screen.Cursor := crDefault;
    end;
    Demo := '';
    if Demos.Count = 1 then
      Demo := Demos[0]
    else if Demos.Count > 1 then
    begin
      if Assigned(FOnChoose) then
        Demo := FOnChoose('Демо-программа',
                          'Программы, которые подключают ' +
                          ExtractFileName(Info.FileName) + ':', Demos)
      else
        Demo := Demos[0];
      if Demo = '' then
        Exit;
    end
    else
    begin
      if MessageDlg('Программ, которые подключают ' +
                    ExtractFileName(Info.FileName) + ', в папках из ' +
                    'списка нет.'#13#10#13#10'Создать демо-программу ' +
                    ChangeFileExt(ExtractFileName(Info.FileName), '') +
                    '_demo.bas рядом с файлом?',
                    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
        Exit;
      Demo := IncMakeDemo(Info.FileName, Err);
      if Demo = '' then
      begin
        ShowMessage('Демо-программа не создана: ' + Err);
        Exit;
      end;
    end;
    if Assigned(FOnOpenFile) then
      FOnOpenFile(Demo, 0);
  finally
    Folders.Free;
    Demos.Free;
  end;
end;

// Папка эталона
procedure TForm3.btnRefClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FRefDir;
  if not BrowseFolderDialog('Папка эталонных inc', Dir) then
    Exit;
  FRefDir := ExcludeTrailingPathDelimiter(Dir);
  SaveFolders;
  FreeAndNil(FRef);   // FillIncFiles прочитает эталон заново
  FillIncFiles;
end;

// Добавить - папка, выбранная слева. Та же папка второй раз не добавляется.
procedure TForm3.BitBtn1Click(Sender: TObject);
var
  Dir: string;
  ItemIdx: Integer;
begin
  Dir := ExcludeTrailingPathDelimiter(DirectoryListBox1.Directory);
  if Dir = '' then
    Exit;
  for ItemIdx := 0 to CheckListBox1.Items.Count - 1 do
    if CompareText(CheckListBox1.Items[ItemIdx], Dir) = 0 then
    begin
      CheckListBox1.ItemIndex := ItemIdx;
      Exit;
    end;
  ItemIdx := CheckListBox1.Items.Add(Dir);
  CheckListBox1.Checked[ItemIdx] := True;
  CheckListBox1.ItemIndex := ItemIdx;
  SaveFolders;
  FillIncFiles;
end;

// Удалить из списка - выбранная строка
procedure TForm3.BitBtn2Click(Sender: TObject);
var
  ItemIdx: Integer;
begin
  ItemIdx := CheckListBox1.ItemIndex;
  if ItemIdx < 0 then
    Exit;
  CheckListBox1.Items.Delete(ItemIdx);
  if ItemIdx >= CheckListBox1.Items.Count then
    ItemIdx := CheckListBox1.Items.Count - 1;
  CheckListBox1.ItemIndex := ItemIdx;
  SaveFolders;
  FillIncFiles;
end;

procedure TForm3.CheckListBox1ClickCheck(Sender: TObject);
begin
  SaveFolders;
  FillIncFiles;
end;

procedure TForm3.chkSubDirsClick(Sender: TObject);
begin
  if FLoading then
    Exit;
  SaveFolders;
  FillIncFiles;
end;

// ---------------------------------------------------------------------------
//  Состав файла, изъятие, сборка (IncEdit.pas)
// ---------------------------------------------------------------------------

procedure TForm3.FormCreate(Sender: TObject);
begin
  FItemsAll := TList.Create;
  FItemsChecked := TList.Create;
  BuildItemsPane;
  lblRef.Cursor := crHandPoint;
  lblRef.ShowHint := True;
  lblRef.OnClick := lblRefClick;
end;

// Панель состава - справа от замечаний; кнопки работы с файлами - вторым
// рядом под списком файлов
procedure TForm3.BuildItemsPane;
var
  pnlItemBtns: TPanel;
begin
  pnlItems := TPanel.Create(Self);
  pnlItems.Parent := Panel2;
  pnlItems.Left := Panel2.Width;
  pnlItems.Width := 330;
  pnlItems.Align := alRight;
  pnlItems.BevelOuter := bvNone;
  pnlItems.Caption := '';

  Splitter3 := TSplitter.Create(Self);
  Splitter3.Parent := Panel2;
  Splitter3.Left := pnlItems.Left - 6;
  Splitter3.Width := 6;
  Splitter3.Align := alRight;
  Splitter3.AutoSnap := False;
  Splitter3.MinSize := 160;

  lblItems := TLabel.Create(Self);
  lblItems.Parent := pnlItems;
  lblItems.Align := alTop;
  lblItems.AutoSize := False;
  lblItems.Height := 22;
  lblItems.Layout := tlCenter;
  lblItems.Font.Style := [fsBold];
  lblItems.Caption := 'Состав файла';

  edItemsFilter := TUiEdit.Create(Self);
  edItemsFilter.Parent := pnlItems;
  edItemsFilter.Top := 22;
  edItemsFilter.Align := alTop;
  edItemsFilter.Hint := 'Фильтр: часть имени';
  edItemsFilter.ShowHint := True;
  edItemsFilter.OnChange := ItemsFilterChange;

  pnlItemBtns := TPanel.Create(Self);
  pnlItemBtns.Parent := pnlItems;
  pnlItemBtns.Align := alBottom;
  pnlItemBtns.Height := 38;
  pnlItemBtns.BevelOuter := bvNone;
  pnlItemBtns.Caption := '';

  lstItems := TCheckListBox.Create(Self);
  lstItems.Parent := pnlItems;
  lstItems.Align := alClient;
  lstItems.Hint := 'Процедуры (Sub / Fn), функции DLL, компоненты (Comp). ' +
    'Галка - изъять; двойной щелчок - место в редакторе';
  lstItems.ShowHint := True;
  lstItems.OnClickCheck := ItemsClickCheck;
  lstItems.OnDblClick := ItemsDblClick;

  btnItemsAll := TUiButton.Create(Self);
  btnItemsAll.Parent := pnlItemBtns;
  btnItemsAll.SetBounds(0, 7, 60, 25);
  btnItemsAll.Caption := 'Все';
  btnItemsAll.Hint := 'Отметить все видимые (по фильтру)';
  btnItemsAll.OnClick := btnItemsAllClick;
  btnItemsNone := TUiButton.Create(Self);
  btnItemsNone.Parent := pnlItemBtns;
  btnItemsNone.SetBounds(66, 7, 90, 25);
  btnItemsNone.Caption := 'Ни одного';
  btnItemsNone.Hint := 'Снять все отметки';
  btnItemsNone.OnClick := btnItemsAllClick;
  btnExtract := TUiButton.Create(Self);
  btnExtract.Parent := pnlItemBtns;
  btnExtract.SetBounds(162, 7, 100, 25);
  btnExtract.Caption := 'Изъять';
  btnExtract.Hint := 'Каждый отмеченный - в свой <имя>.inc рядом с файлом ' +
    '(прежний текст файла - в .bak)';
  btnExtract.OnClick := btnExtractClick;

  // Второй ряд кнопок под списком файлов
  pnlFileBtns.Height := 70;
  btnMerge := TUiButton.Create(Self);
  btnMerge.Parent := pnlFileBtns;
  btnMerge.SetBounds(0, 39, 140, 25);
  btnMerge.Caption := 'Собрать в один...';
  btnMerge.Hint := 'Отмеченные галкой файлы - в один новый; из одноимённых ' +
    'объявлений остаётся первое';
  btnMerge.OnClick := btnMergeClick;
  btnFilesAll := TUiButton.Create(Self);
  btnFilesAll.Parent := pnlFileBtns;
  btnFilesAll.SetBounds(148, 39, 60, 25);
  btnFilesAll.Caption := 'Все';
  btnFilesAll.Hint := 'Отметить все файлы';
  btnFilesAll.OnClick := btnFilesAllClick;
  btnFilesNone := TUiButton.Create(Self);
  btnFilesNone.Parent := pnlFileBtns;
  btnFilesNone.SetBounds(214, 39, 90, 25);
  btnFilesNone.Caption := 'Ни одного';
  btnFilesNone.Hint := 'Снять галки со всех файлов';
  btnFilesNone.OnClick := btnFilesAllClick;
end;

// Надпись эталона: свои файлы <-> файлы эталонной папки
procedure TForm3.lblRefClick(Sender: TObject);
begin
  if FBusy then
    Exit;
  FShowRef := not FShowRef;
  FillIncFiles;
end;

procedure TForm3.LoadItemsOf(const AFile: string);
begin
  FreeAndNil(FItemsDoc);
  FItemsAll.Clear;
  FItemsChecked.Clear;
  if (AFile <> '') and FileExists(AFile) then
  begin
    FItemsDoc := TIncDoc.Create;
    Screen.Cursor := crHourGlass;
    try
      if FItemsDoc.LoadFromFile(AFile) then
        FItemsDoc.OfferedItems(FItemsAll)
      else
        FreeAndNil(FItemsDoc);
    finally
      Screen.Cursor := crDefault;
    end;
  end;
  FillItems;
end;

procedure TForm3.FillItems;
var
  ItemIdx: Integer;
  Item: TIncUnit;
  Filter: string;
begin
  Filter := UpperCase(Trim(edItemsFilter.Text));
  lstItems.Items.BeginUpdate;
  try
    lstItems.Items.Clear;
    for ItemIdx := 0 to FItemsAll.Count - 1 do
    begin
      Item := TIncUnit(FItemsAll[ItemIdx]);
      if (Filter <> '') and (Pos(Filter, UpperCase(Item.Name)) = 0) then
        Continue;
      lstItems.Items.AddObject(Item.Caption, Item);
      lstItems.Checked[lstItems.Items.Count - 1] :=
        FItemsChecked.IndexOf(Item) >= 0;
    end;
  finally
    lstItems.Items.EndUpdate;
  end;
  if FItemsDoc = nil then
    lblItems.Caption := 'Состав файла'
  else
    lblItems.Caption := Format('Состав %s: %d, отмечено %d',
      [ExtractFileName(FItemsDoc.FileName), FItemsAll.Count,
       FItemsChecked.Count]);
end;

procedure TForm3.ItemsFilterChange(Sender: TObject);
begin
  FillItems;
end;

procedure TForm3.ItemsClickCheck(Sender: TObject);
var
  ItemIdx: Integer;
  Item: TObject;
begin
  for ItemIdx := 0 to lstItems.Items.Count - 1 do
  begin
    Item := lstItems.Items.Objects[ItemIdx];
    if lstItems.Checked[ItemIdx] then
    begin
      if FItemsChecked.IndexOf(Item) < 0 then
        FItemsChecked.Add(Item);
    end
    else
      FItemsChecked.Remove(Item);
  end;
  if FItemsDoc <> nil then
    lblItems.Caption := Format('Состав %s: %d, отмечено %d',
      [ExtractFileName(FItemsDoc.FileName), FItemsAll.Count,
       FItemsChecked.Count]);
end;

procedure TForm3.ItemsDblClick(Sender: TObject);
var
  Item: TIncUnit;
begin
  if (lstItems.ItemIndex < 0) or (FItemsDoc = nil) or
     not Assigned(FOnOpenFile) then
    Exit;
  Item := TIncUnit(lstItems.Items.Objects[lstItems.ItemIndex]);
  FOnOpenFile(FItemsDoc.FileName, Item.Head + 1);
end;

// Все (видимые) / ни одного
procedure TForm3.btnItemsAllClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  if Sender = btnItemsNone then
    FItemsChecked.Clear;
  for ItemIdx := 0 to lstItems.Items.Count - 1 do
    lstItems.Checked[ItemIdx] := Sender = btnItemsAll;
  ItemsClickCheck(nil);
end;

procedure TForm3.btnFilesAllClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to lstIncFiles.Items.Count - 1 do
    lstIncFiles.Checked[ItemIdx] := Sender = btnFilesAll;
end;

// Отчёт - в список замечаний
procedure TForm3.ShowReport(const AHead: string; AReport: TStrings);
begin
  lblErrHead.Caption := AHead;
  lstErrors.Items.Assign(AReport);
end;

procedure TForm3.SelectFileByName(const AFile: string);
var
  ItemIdx: Integer;
  Info: TIncFileInfo;
begin
  for ItemIdx := 0 to lstIncFiles.Items.Count - 1 do
  begin
    Info := TIncFileInfo(lstIncFiles.Items.Objects[ItemIdx]);
    if CompareText(Info.FileName, AFile) = 0 then
    begin
      lstIncFiles.ItemIndex := ItemIdx;
      LoadItemsOf(AFile);
      Exit;
    end;
  end;
end;

procedure TForm3.btnExtractClick(Sender: TObject);
var
  Items: TList;
  Report, Folder, ExtUses: TStringList;
  ItemIdx, Existing, Done, Includers: Integer;
  SrcFile, Head: string;
  Overwrite: Boolean;
begin
  if (FItemsDoc = nil) or (FItemsChecked.Count = 0) then
  begin
    ShowMessage('Отметьте галкой в составе файла то, что изъять.');
    Exit;
  end;
  SrcFile := FItemsDoc.FileName;
  Items := TList.Create;
  Report := TStringList.Create;
  Folder := TStringList.Create;
  ExtUses := TStringList.Create;
  try
    // в порядке файла
    for ItemIdx := 0 to FItemsAll.Count - 1 do
      if FItemsChecked.IndexOf(FItemsAll[ItemIdx]) >= 0 then
        Items.Add(FItemsAll[ItemIdx]);
    Existing := 0;
    for ItemIdx := 0 to Items.Count - 1 do
      if FileExists(IncItemFileName(FItemsDoc, TIncUnit(Items[ItemIdx]))) then
        Inc(Existing);
    if MessageDlg(Format('Изъять из %s пунктов: %d?'#13#10#13#10 +
         'Каждый - в свой <имя>.inc в той же папке, вместе с тем, чем ' +
         'пользуется только он; новый файл подключает %s. Программам, ' +
         'которые пользуются изъятым, нужно будет подключить его файл.'#13#10 +
         'Прежний текст %s - в .bak.',
         [ExtractFileName(SrcFile), Items.Count, ExtractFileName(SrcFile),
          ExtractFileName(SrcFile)]),
         mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    Overwrite := False;
    if Existing > 0 then
      case MessageDlg(Format('Файлы с такими именами уже есть: %d. ' +
             'Перезаписать их? (Нет - эти пункты не изымать)', [Existing]),
             mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
        mrYes: Overwrite := True;
        mrNo: Overwrite := False;
      else
        Exit;
      end;
    // Файлы той же папки, которые подключают этот: нужное им не изымать
    FindFilesExt(ExtractFilePath(SrcFile), '.inc', False, Folder,
                 IncMgrMaxFiles);
    Screen.Cursor := crHourGlass;
    try
      Includers := IncExternalUses(SrcFile, Folder, ExtUses);
      Done := IncExtract(FItemsDoc, Items, Overwrite, Report, ExtUses, Folder);
    finally
      Screen.Cursor := crDefault;
    end;
    Head := Format('Изъятие из %s: изъято %d из %d', [ExtractFileName(SrcFile),
                   Done, Items.Count]);
    if Includers > 0 then
      Head := Head + Format(' (учтены подключающие его файлы: %d)', [Includers]);
    // Файлы на диске изменились - список и состав заново
    FillIncFiles;
    SelectFileByName(SrcFile);
    ShowReport(Head, Report);
  finally
    ExtUses.Free;
    Folder.Free;
    Report.Free;
    Items.Free;
  end;
end;

procedure TForm3.btnMergeClick(Sender: TObject);
var
  Files, Report: TStringList;
  ItemIdx: Integer;
  Dlg: TSaveDialog;
  List: string;
begin
  Files := TStringList.Create;
  Report := TStringList.Create;
  Dlg := TSaveDialog.Create(Self);
  try
    for ItemIdx := 0 to lstIncFiles.Items.Count - 1 do
      if lstIncFiles.Checked[ItemIdx] then
        Files.Add(TIncFileInfo(lstIncFiles.Items.Objects[ItemIdx]).FileName);
    if Files.Count < 2 then
    begin
      ShowMessage('Отметьте галкой в списке файлов те, что собрать в один ' +
                  '(хотя бы два). Кнопки "Все" / "Ни одного" - под списком.');
      Exit;
    end;
    List := '';
    for ItemIdx := 0 to Files.Count - 1 do
      if ItemIdx < 15 then
        List := List + #13#10'  ' + ExtractFileName(Files[ItemIdx]);
    if Files.Count > 15 then
      List := List + #13#10'  ... ещё ' + IntToStr(Files.Count - 15);
    if MessageDlg(Format('Собрать в один файл отмеченные (%d):%s'#13#10#13#10 +
         'Порядок - как в списке; из одноимённых объявлений остаётся первое. ' +
         'Исходные файлы не меняются.', [Files.Count, List]),
         mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    Dlg.Title := 'Собранный inc-файл';
    Dlg.Filter := 'inc|*.inc';
    Dlg.DefaultExt := 'inc';
    Dlg.InitialDir := ExtractFilePath(Files[0]);
    Dlg.Options := Dlg.Options + [ofOverwritePrompt];
    if not Dlg.Execute then
      Exit;
    Screen.Cursor := crHourGlass;
    try
      IncMerge(Files, Dlg.FileName, Report);
    finally
      Screen.Cursor := crDefault;
    end;
    FillIncFiles;
    SelectFileByName(Dlg.FileName);
    ShowReport('Сборка в ' + ExtractFileName(Dlg.FileName), Report);
  finally
    Dlg.Free;
    Report.Free;
    Files.Free;
  end;
end;

end.
