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
//  Строки - по виду файла, как в окне Commit (GitFileKind, GitKindColor
//  из DlgGitCommit): сверху красные - то, что обычно не хранят в
//  репозитории (exe, log, $$$, архивы, old ...), затем библиотеки,
//  картинки, исходники, текст; цвет строки - цвет вида.
//
//  Чтобы понять, что за файл: в списке размер и время изменения на диске,
//  под списком - начало выделенного файла (текст; двоичный - байты в
//  шестнадцатеричном виде), кнопка «Показать в папке».
//
//  Окно строится в коде, .dfm нет. Список и действия - у Unit1 (OnLoad,
//  OnKeep, OnUntrack: спрашивают и выполняют сами); после действия список
//  перечитывается, флажки оставшихся строк сохраняются.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls, Math,
  UiButton,      // TUiButton
  UiStdCtrls,    // TUiLabel, TUiPanel
  UiComCtrls,    // TUiListView
  UiEditCtrls,   // TUiMemo - начало файла
  OsShell,       // ShellShowInFolder
  DlgGitCommit,  // GitFileKind, GitKindColor, GitKindNames - вид файла
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
    FRepo: string;
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
    FBtnShow: TUiButton;
    FPreview: TUiMemo;
    FSplitter: TSplitter;
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
    procedure BtnShowClick(Sender: TObject);
    function FullPath(AFileIdx: Integer): WideString;
    function SelectedFileIdx: Integer;
    procedure ShowPreview;
    procedure ListSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure BtnKeepClick(Sender: TObject);
    procedure BtnUntrackClick(Sender: TObject);
    procedure ListChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure LayoutTop(Sender: TObject);
    procedure LayoutButtons(Sender: TObject);
    procedure ListCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure ListCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
    // $0128 - WM_UPDATEUISTATE (кнопки не пропадают по Alt, как в других окнах)
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    // ARepo - папка репозитория (пути файлов - от неё)
    constructor CreateDlg(AOwner: TComponent; const ATitle, ARepo: string;
      const AFiles: TGitTrackedFiles; AOnLoad: TGitTrackedLoadEvent;
      AOnKeep, AOnUntrack: TGitTrackedActEvent);
    // Что-то сделано (исключения в .gitignore или git rm --cached) -
    // изменения нужно закоммитить
    property Changed: Boolean read FChanged;
  end;

// Папка пути с '/' в конце ('a/b/c.txt' -> 'a/b/'); в корне - ''
function GitTrackedDir(const APath: WideString): WideString;

implementation

const
  // Сколько байт файла показывать: текст и двоичный
  PreviewTextBytes = 16384;
  PreviewBinBytes = 512;

type
  // Сведения о файле на диске
  TTrackedFileInfo = record
    Exists: Boolean;
    IsDir: Boolean;
    Size: Int64;
    Modified: TDateTime;
  end;

{$IFDEF MSWINDOWS}
type
  TTrackedAttrData = record
    Attributes: DWORD;
    CreationTime, LastAccessTime, LastWriteTime: TFileTime;
    SizeHigh, SizeLow: DWORD;
  end;

function TrackedGetAttrEx(AName: PWideChar; ALevel: Integer;
  var AData: TTrackedAttrData): BOOL; stdcall;
  external 'kernel32.dll' name 'GetFileAttributesExW';
function TrackedCreateFileW(AName: PWideChar; AAccess, AShare: DWORD;
  ASecurity: Pointer; ACreation, AFlags: DWORD; ATemplate: THandle): THandle;
  stdcall; external 'kernel32.dll' name 'CreateFileW';
{$ENDIF}

function TrackedInfo(const APath: WideString): TTrackedFileInfo;
{$IFDEF MSWINDOWS}
var
  Data: TTrackedAttrData;
  LocalTime: TFileTime;
  SysTime: TSystemTime;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not TrackedGetAttrEx(PWideChar(APath), 0, Data) then
    Exit;
  Result.Exists := True;
  Result.IsDir := (Data.Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0;
  Result.Size := Int64(Data.SizeHigh) shl 32 + Data.SizeLow;
  if FileTimeToLocalFileTime(Data.LastWriteTime, LocalTime) and
     FileTimeToSystemTime(LocalTime, SysTime) then
    Result.Modified := SystemTimeToDateTime(SysTime);
end;
{$ELSE}
var
  Found: TSearchRec;
begin
  FillChar(Result, SizeOf(Result), 0);
  if FindFirst(UTF8Encode(APath), faAnyFile, Found) <> 0 then
    Exit;
  try
    Result.Exists := True;
    Result.IsDir := (Found.Attr and faDirectory) <> 0;
    Result.Size := Found.Size;
    Result.Modified := FileDateToDateTime(Found.Time);
  finally
    FindClose(Found);
  end;
end;
{$ENDIF}

// Первые AMaxBytes байт файла; не открылся - False
function TrackedReadHead(const APath: WideString; AMaxBytes: Integer;
  var AData: string): Boolean;
var
  Stream: THandleStream;
  FileHandle: THandle;
  ReadCount: Integer;
begin
  Result := False;
  AData := '';
  {$IFDEF MSWINDOWS}
  FileHandle := TrackedCreateFileW(PWideChar(APath), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  if FileHandle = INVALID_HANDLE_VALUE then
    Exit;
  {$ELSE}
  FileHandle := FileOpen(UTF8Encode(APath), fmOpenRead or fmShareDenyNone);
  if FileHandle = THandle(-1) then
    Exit;
  {$ENDIF}
  Stream := THandleStream.Create(FileHandle);
  try
    SetLength(AData, AMaxBytes);
    ReadCount := Stream.Read(AData[1], AMaxBytes);
    if ReadCount < 0 then
      ReadCount := 0;
    SetLength(AData, ReadCount);
    Result := True;
  finally
    Stream.Free;
    FileClose(FileHandle);
  end;
end;

// Текст в UTF-8 (есть байты от $80 и все последовательности верные)
function TrackedIsUtf8(const AText: string): Boolean;
var
  CharIdx, Follow, FollowIdx: Integer;
  Code: Byte;
  HasHigh: Boolean;
begin
  Result := False;
  HasHigh := False;
  CharIdx := 1;
  while CharIdx <= Length(AText) do
  begin
    Code := Ord(AText[CharIdx]);
    if Code < $80 then
      Follow := 0
    else if (Code and $E0) = $C0 then
      Follow := 1
    else if (Code and $F0) = $E0 then
      Follow := 2
    else if (Code and $F8) = $F0 then
      Follow := 3
    else
      Exit;
    if Follow > 0 then
    begin
      HasHigh := True;
      // Последовательность, обрезанная концом прочитанного куска, - не ошибка
      for FollowIdx := 1 to Follow do
        if (CharIdx + FollowIdx <= Length(AText)) and
           ((Ord(AText[CharIdx + FollowIdx]) and $C0) <> $80) then
          Exit;
    end;
    Inc(CharIdx, Follow + 1);
  end;
  Result := HasHigh;
end;

// Двоичное: байты в шестнадцатеричном виде по 16 в строке, справа - знаки
function TrackedHexDump(const AData: string): string;
var
  LineStart, ByteIdx: Integer;
  HexPart, CharPart: string;
  Code: Byte;
begin
  Result := '';
  LineStart := 1;
  while LineStart <= Length(AData) do
  begin
    HexPart := '';
    CharPart := '';
    for ByteIdx := LineStart to LineStart + 15 do
      if ByteIdx <= Length(AData) then
      begin
        Code := Ord(AData[ByteIdx]);
        HexPart := HexPart + IntToHex(Code, 2) + ' ';
        if (Code >= 32) and (Code < 127) then
          CharPart := CharPart + Chr(Code)
        else
          CharPart := CharPart + '.';
      end
      else
        HexPart := HexPart + '   ';
    Result := Result + IntToHex(LineStart - 1, 6) + '  ' + HexPart + ' ' +
      CharPart + #13#10;
    Inc(LineStart, 16);
  end;
end;

// Переводы строк - CRLF (окно текста другие не показывает как перевод)
function TrackedCrLf(const AText: string): string;
begin
  Result := StringReplace(AText, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #10, #13#10, [rfReplaceAll]);
end;

function TrackedSizeText(ASize: Int64): string;
begin
  Result := FormatFloat('#,##0', ASize);
end;

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

constructor TDlgGitTracked.CreateDlg(AOwner: TComponent;
  const ATitle, ARepo: string; const AFiles: TGitTrackedFiles; AOnLoad: TGitTrackedLoadEvent;
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
  FRepo := ARepo;
  FOnLoad := AOnLoad;
  FOnKeep := AOnKeep;
  FOnUntrack := AOnUntrack;
  FChanged := False;
  Caption := ATitle;
  Position := poMainFormCenter;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Width := 900;
  Height := 680;
  Constraints.MinWidth := 640;
  Constraints.MinHeight := 420;

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
  FBtnShow := NewButton(FTopPanel, 'Показать в папке', 'Открыть папку ' +
    'выделенного файла с выделенным файлом', BtnShowClick);
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

  // Над кнопками: начало выделенного файла
  FPreview := TUiMemo.Create(Self);
  FPreview.Parent := Self;
  FPreview.Align := alBottom;
  FPreview.Height := 200;
  FPreview.ReadOnly := True;
  FPreview.ScrollBars := ssBoth;
  FPreview.WordWrap := False;
  FPreview.Font.Name := 'Courier New';
  FPreview.Font.Size := 9;
  FSplitter := TSplitter.Create(Self);
  FSplitter.Parent := Self;
  FSplitter.Align := alBottom;
  FSplitter.Height := 5;
  // Порядок снизу вверх: кнопки, начало файла, разделитель (alBottom
  // раскладывает по Top)
  FBtnPanel.Top := ClientHeight;
  FPreview.Top := ClientHeight - FBtnPanel.Height - FPreview.Height;
  FSplitter.Top := FPreview.Top - FSplitter.Height - 1;

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
  Column.Width := 340;
  Column := FList.Columns.Add;
  Column.Caption := 'Правило .gitignore';
  Column.Width := 170;
  Column := FList.Columns.Add;
  Column.Caption := 'Вид';
  Column.Width := 100;
  Column := FList.Columns.Add;
  Column.Caption := 'Размер';
  Column.Width := 90;
  Column.Alignment := taRightJustify;
  Column := FList.Columns.Add;
  Column.Caption := 'Изменён';
  Column.Width := 115;
  FList.OnCustomDrawItem := ListCustomDrawItem;
  FList.OnCustomDrawSubItem := ListCustomDrawSubItem;
  FillList(nil);
  FList.OnChange := ListChange;
  FList.OnSelectItem := ListSelectItem;
  if FList.Items.Count > 0 then
  begin
    FList.Items[0].Selected := True;
    FList.Items[0].Focused := True;
  end;
  ShowPreview;
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
  Inc(BtnLeft, 70 + BtnGap * 3);
  FBtnShow.SetBounds(BtnLeft, 42, 120, BtnH);
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

// Список по FFiles: сначала красные (не хранить?), затем по видам как в
// окне Commit; внутри вида - порядок git. AKeepChecked - пути, у которых
// флажок стоял до перечитывания (nil - все без флажков)
procedure TDlgGitTracked.FillList(AKeepChecked: TStrings);
var
  FileIdx, KindIdx, FileKind: Integer;
  Item: TListItem;
  Info: TTrackedFileInfo;
begin
  FFilling := True;
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for KindIdx := 0 to gfkCount - 1 do
    for FileIdx := 0 to High(FFiles) do
    begin
      FileKind := GitFileKind(FFiles[FileIdx].Path);
      if FileKind <> KindIdx then
        Continue;
      Item := FList.Items.Add;
      Item.Caption := string(FFiles[FileIdx].Path);
      Item.SubItems.Add(FFiles[FileIdx].Rule);
      Item.SubItems.Add(GitKindNames[FileKind]);
      Info := TrackedInfo(FullPath(FileIdx));
      if not Info.Exists then
      begin
        Item.SubItems.Add('нет на диске');
        Item.SubItems.Add('');
      end
      else
      begin
        if Info.IsDir then
          Item.SubItems.Add('папка')
        else
          Item.SubItems.Add(TrackedSizeText(Info.Size));
        if Info.Modified <> 0 then
          Item.SubItems.Add(FormatDateTime('dd.mm.yyyy hh:nn', Info.Modified))
        else
          Item.SubItems.Add('');
      end;
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
    begin
      FillList(KeepChecked);
      if FList.Items.Count > 0 then
        FList.Items[0].Selected := True;
      ShowPreview;
    end;
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

// Полный путь файла строки FFiles[AFileIdx] (разделители - системы)
function TDlgGitTracked.FullPath(AFileIdx: Integer): WideString;
var
  CharIdx: Integer;
begin
  Result := '';
  if (AFileIdx < 0) or (AFileIdx > High(FFiles)) then
    Exit;
  Result := FFiles[AFileIdx].Path;
  {$IFDEF MSWINDOWS}
  for CharIdx := 1 to Length(Result) do
    if Result[CharIdx] = '/' then
      Result[CharIdx] := '\';
  {$ELSE}
  CharIdx := 0;
  {$ENDIF}
  if FRepo <> '' then
    Result := WideString(IncludeTrailingPathDelimiter(FRepo)) + Result;
end;

function TDlgGitTracked.SelectedFileIdx: Integer;
begin
  Result := -1;
  if FList.Selected <> nil then
    Result := Integer(FList.Selected.Data);
  if (Result < 0) or (Result > High(FFiles)) then
    Result := -1;
end;

// Начало выделенного файла: сведения, затем текст (UTF-8 - перекодирован)
// или байты в шестнадцатеричном виде
procedure TDlgGitTracked.ShowPreview;
var
  FileIdx, ByteIdx: Integer;
  FileName: WideString;
  Info: TTrackedFileInfo;
  Data, Head, Body: string;
  IsBinary: Boolean;
begin
  FileIdx := SelectedFileIdx;
  if FileIdx < 0 then
  begin
    FPreview.Text := '';
    Exit;
  end;
  FileName := FullPath(FileIdx);
  Info := TrackedInfo(FileName);
  Head := string(FileName) + #13#10;
  if not Info.Exists then
  begin
    FPreview.Text := Head + 'Файла нет на диске (в репозитории он есть).';
    Exit;
  end;
  if Info.IsDir then
  begin
    FPreview.Text := Head + 'Это папка.';
    Exit;
  end;
  Head := Head + 'Размер ' + TrackedSizeText(Info.Size) + ' байт, изменён ' +
    FormatDateTime('dd.mm.yyyy hh:nn:ss', Info.Modified) + #13#10;
  if not TrackedReadHead(FileName, PreviewTextBytes, Data) then
  begin
    FPreview.Text := Head + 'Файл не открыть (занят другой программой?)';
    Exit;
  end;
  IsBinary := False;
  for ByteIdx := 1 to Length(Data) do
    if Data[ByteIdx] = #0 then
    begin
      IsBinary := True;
      Break;
    end;
  if IsBinary then
  begin
    Body := 'Двоичный файл, первые ' +
      IntToStr(Min(Length(Data), PreviewBinBytes)) + ' байт:' + #13#10 +
      TrackedHexDump(Copy(Data, 1, PreviewBinBytes));
  end
  else
  begin
    if TrackedIsUtf8(Data) then
      Body := Utf8ToAnsi(Data)
    else
      Body := Data;
    // Обрезанная на конце последовательность UTF-8 - не страшно: это
    // только просмотр
    Body := TrackedCrLf(Body);
    if Info.Size > Length(Data) then
      Body := Body + #13#10 + '... (показаны первые ' +
        TrackedSizeText(Length(Data)) + ' байт)';
  end;
  FPreview.Text := Head + StringOfChar('-', 60) + #13#10 + Body;
  FPreview.SelStart := 0;
end;

procedure TDlgGitTracked.ListSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected and not FFilling then
    ShowPreview;
end;

procedure TDlgGitTracked.BtnShowClick(Sender: TObject);
var
  FileIdx: Integer;
begin
  FileIdx := SelectedFileIdx;
  if FileIdx >= 0 then
    ShellShowInFolder(Handle, string(FullPath(FileIdx)));
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

// Цвет строки - по виду файла (clNone - цвет темы)
procedure TDlgGitTracked.ListCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  FileIdx: Integer;
  KindColor: TColor;
begin
  KindColor := clNone;
  if Item <> nil then
  begin
    FileIdx := Integer(Item.Data);
    if (FileIdx >= 0) and (FileIdx <= High(FFiles)) then
      KindColor := GitKindColor(GitFileKind(FFiles[FileIdx].Path),
        FList.Color);
  end;
  if KindColor <> clNone then
    Sender.Canvas.Font.Color := KindColor
  else
    Sender.Canvas.Font.Color := FList.Font.Color;
  DefaultDraw := True;
end;

procedure TDlgGitTracked.ListCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState;
  var DefaultDraw: Boolean);
begin
  ListCustomDrawItem(Sender, Item, State, DefaultDraw);
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
