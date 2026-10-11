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
  FolderDlg;    // выбор папки эталона - BrowseFolderDialog

type
  // Открыть файл в редакторе на строке (с 1; 0 - без перехода)
  TIncOpenFileEvent = procedure(const AFile: string; ALine: Integer) of object;
  // Выбор строки из списка ('' - отказались)
  TIncChooseEvent = function(const ACaption, APrompt: string;
                             AItems: TStrings): string of object;

  TForm3 = class(TForm)
    Panel1: TPanel;
    DirectoryListBox1: TDirectoryListBox;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Label1: TLabel;
    CheckListBox1: TCheckListBox;
    DriveComboBox1: TDriveComboBox;
    chkSubDirs: TCheckBox;
    lstIncFiles: TCheckListBox;
    lblCount: TLabel;
    lblRef: TLabel;
    btnRef: TButton;
    lblErrHead: TLabel;
    lstErrors: TListBox;
    btnScan: TButton;
    btnGuard: TButton;
    btnDemo: TButton;
    lblLegend: TLabel;
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
  private
    FIniFile: string;
    FSysDir: string;       // общие inc (SysIncPath)
    FDefaultRef: string;   // эталон по умолчанию
    FRefDir: string;       // эталон сейчас
    FRef: TIncRefIndex;    // nil - эталон ещё не прочитан
    FLoading: Boolean;     // список заполняется из editor.ini - не записывать
    FOnOpenFile: TIncOpenFileEvent;
    FOnChoose: TIncChooseEvent;
    procedure LoadFolders;
    procedure SaveFolders;
    procedure ClearInfos;
    procedure FillIncFiles;
    procedure EnsureRef(AReload: Boolean);
    procedure ShowMessagesOf(AIndex: Integer);
    procedure CheckedFolders(AList: TStrings);
    function  SelectedInfo: TIncFileInfo;
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

procedure TForm3.ShowFor(const AIniFile, ASysDir, ADefaultRef: string);
begin
  FIniFile := AIniFile;
  FSysDir := ASysDir;
  FDefaultRef := ADefaultRef;
  LoadFolders;
  Show;
  BringToFront;
end;

procedure TForm3.FormDestroy(Sender: TObject);
begin
  ClearInfos;
  FreeAndNil(FRef);
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

procedure TForm3.ClearInfos;
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to lstIncFiles.Items.Count - 1 do
    lstIncFiles.Items.Objects[ItemIdx].Free;
  lstIncFiles.Items.Clear;
  lstErrors.Items.Clear;
  lblErrHead.Caption := '';
end;

// Эталон: файлы папки FRefDir и имена общих inc (FSysDir)
procedure TForm3.EnsureRef(AReload: Boolean);
begin
  if (FRef <> nil) and not AReload then
    Exit;
  if FRef = nil then
    FRef := TIncRefIndex.Create;
  FRef.Load(FRefDir, FSysDir);
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
begin
  if FLoading then
    Exit;
  Screen.Cursor := crHourGlass;
  Files := TStringList.Create;
  Folders := TStringList.Create;
  lstIncFiles.Items.BeginUpdate;
  try
    EnsureRef(False);
    ClearInfos;
    Files.Sorted := True;
    Files.Duplicates := dupIgnore;
    Missing := 0;
    CheckedFolders(Folders);
    for ItemIdx := 0 to Folders.Count - 1 do
      if not DirectoryExists(Folders[ItemIdx]) then
        Inc(Missing)
      else
        FindFilesExt(Folders[ItemIdx], '.inc', chkSubDirs.Checked, Files,
                     IncMgrMaxFiles);

    for Status := Low(TIncStatus) to High(TIncStatus) do
      Counts[Status] := 0;
    Errors := 0;
    for ItemIdx := 0 to Files.Count - 1 do
    begin
      Info := TIncFileInfo.Create(Files[ItemIdx]);
      IncCheckFile(Info, FRef);
      Inc(Counts[Info.Status]);
      if Info.Errors > 0 then
        Inc(Errors);
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
  finally
    lstIncFiles.Items.EndUpdate;
    Folders.Free;
    Files.Free;
    Screen.Cursor := crDefault;
  end;
  if lstIncFiles.Items.Count > 0 then
  begin
    lstIncFiles.ItemIndex := 0;
    ShowMessagesOf(0);
  end;
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
  Screen.Cursor := crHourGlass;
  try
    EnsureRef(True);
  finally
    Screen.Cursor := crDefault;
  end;
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
  Screen.Cursor := crHourGlass;
  try
    EnsureRef(True);
  finally
    Screen.Cursor := crDefault;
  end;
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

end.
