unit FileCtrlLcl;

// ---------------------------------------------------------------------------
//  TDriveComboBox и TDirectoryListBox для сборки Lazarus (шаг 1.4 плана).
//
//  В модуле FileCtrl Delphi 7 они есть, в FileCtrl LCL - только
//  TFileListBox и TFilterComboBox. Формы DlgPickFolder, DlgTidyIni и Unit3
//  держат их в .dfm; здесь - то, чем пользуется unIDE: Drive, Directory,
//  OnChange, связки DirList (диск -> папки) и FileList (папки -> файлы).
//
//  Список папок - как в Delphi: путь от корня по одной строке на уровень,
//  ниже - вложенные папки текущей; двойной щелчок (или Enter) - перейти.
//  Под Windows диски - по GetLogicalDrives, под Linux диск один - '/'.
//
//  Модуль только для Free Pascal: в Delphi 7 подключается FileCtrl.
// ---------------------------------------------------------------------------

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  {$IFDEF MSWINDOWS} Windows, {$ENDIF}
  SysUtils, Classes, Controls, StdCtrls, FileCtrl;

type
  TDirectoryListBox = class;

  TDriveComboBox = class(TCustomComboBox)
  private
    FDirList: TDirectoryListBox;
    FDrive: Char;
    FOnDriveChange: TNotifyEvent;
    procedure SetDrive(AValue: Char);
    procedure SetDirList(AValue: TDirectoryListBox);
    procedure FillDrives;
  protected
    procedure Loaded; override;
    procedure Select; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Drive: Char read FDrive write SetDrive;
  published
    property Align;
    property Anchors;
    property Color;
    property Constraints;
    property DirList: TDirectoryListBox read FDirList write SetDirList;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnChange: TNotifyEvent read FOnDriveChange write FOnDriveChange;
    property OnClick;
    property OnEnter;
    property OnExit;
  end;

  TDirectoryListBox = class(TCustomListBox)
  private
    FDirectory: string;
    FFileList: TFileListBox;
    FOnDirChange: TNotifyEvent;
    FLevels: Integer;          // строк пути (от корня до текущей)
    procedure SetDirectory(const AValue: string);
    procedure SetFileList(AValue: TFileListBox);
    function GetDrive: Char;
    procedure SetDrive(AValue: Char);
    procedure Fill;
    function PathOfRow(ARow: Integer): string;
  protected
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Directory: string read FDirectory write SetDirectory;
    property Drive: Char read GetDrive write SetDrive;
  published
    property Align;
    property Anchors;
    property Color;
    property Constraints;
    property Enabled;
    property FileList: TFileListBox read FFileList write SetFileList;
    property Font;
    property ItemHeight;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnChange: TNotifyEvent read FOnDirChange write FOnDirChange;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
  end;

implementation

const
  RootDrive = '/';   // не Windows: «диск» один

// --- TDriveComboBox --------------------------------------------------------

constructor TDriveComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Style := csDropDownList;
  FDrive := #0;
end;

procedure TDriveComboBox.FillDrives;
{$IFDEF MSWINDOWS}
var
  Mask: DWORD;
  Letter: Char;
{$ENDIF}
begin
  Items.BeginUpdate;
  try
    Items.Clear;
    {$IFDEF MSWINDOWS}
    Mask := GetLogicalDrives;
    for Letter := 'A' to 'Z' do
      if (Mask and (1 shl (Ord(Letter) - Ord('A')))) <> 0 then
        Items.Add(LowerCase(Letter) + ':');
    {$ELSE}
    Items.Add(RootDrive);
    {$ENDIF}
  finally
    Items.EndUpdate;
  end;
end;

procedure TDriveComboBox.Loaded;
begin
  inherited Loaded;
  FillDrives;
  if FDrive = #0 then
  begin
    {$IFDEF MSWINDOWS}
    Drive := UpCase(GetCurrentDir[1]);
    {$ELSE}
    Drive := RootDrive;
    {$ENDIF}
  end;
end;

procedure TDriveComboBox.SetDrive(AValue: Char);
var
  Row: Integer;
begin
  AValue := UpCase(AValue);
  if Items.Count = 0 then
    FillDrives;
  FDrive := AValue;
  ItemIndex := -1;
  for Row := 0 to Items.Count - 1 do
    if UpCase(Items[Row][1]) = AValue then
      ItemIndex := Row;
  if (FDirList <> nil) and (FDirList.Drive <> AValue) then
    {$IFDEF MSWINDOWS}
    FDirList.Directory := AValue + ':\';
    {$ELSE}
    FDirList.Directory := RootDrive;
    {$ENDIF}
end;

// Выбор в списке - как в Delphi: новый диск, папки - его корень
procedure TDriveComboBox.Select;
begin
  inherited Select;
  if ItemIndex >= 0 then
  begin
    SetDrive(Items[ItemIndex][1]);
    if Assigned(FOnDriveChange) then
      FOnDriveChange(Self);
  end;
end;

procedure TDriveComboBox.SetDirList(AValue: TDirectoryListBox);
begin
  if FDirList <> nil then
    FDirList.RemoveFreeNotification(Self);
  FDirList := AValue;
  if FDirList <> nil then
    FDirList.FreeNotification(Self);
end;

procedure TDriveComboBox.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FDirList) then
    FDirList := nil;
end;

// --- TDirectoryListBox -----------------------------------------------------

constructor TDirectoryListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDirectory := '';
end;

procedure TDirectoryListBox.Loaded;
begin
  inherited Loaded;
  if FDirectory = '' then
    SetDirectory(GetCurrentDir);
end;

function TDirectoryListBox.GetDrive: Char;
begin
  {$IFDEF MSWINDOWS}
  if (Length(FDirectory) >= 2) and (FDirectory[2] = ':') then
    Result := UpCase(FDirectory[1])
  else
    Result := #0;
  {$ELSE}
  Result := RootDrive;
  {$ENDIF}
end;

procedure TDirectoryListBox.SetDrive(AValue: Char);
begin
  {$IFDEF MSWINDOWS}
  if UpCase(AValue) <> GetDrive then
    SetDirectory(UpCase(AValue) + ':\');
  {$ENDIF}
end;

// Строки: корень, папки пути по одной, затем вложенные папки текущей
procedure TDirectoryListBox.Fill;
var
  Parts: TStringList;
  Rest, Root, Part: string;
  SepPos, PartIdx: Integer;
  SearchRec: TSearchRec;
  Subs: TStringList;
begin
  Parts := TStringList.Create;
  Subs := TStringList.Create;
  Items.BeginUpdate;
  try
    Items.Clear;
    Rest := ExcludeTrailingPathDelimiter(FDirectory);
    Root := ExtractFileDrive(Rest);
    if Root = '' then
      Root := PathDelim
    else
      Root := IncludeTrailingPathDelimiter(Root);
    Delete(Rest, 1, Length(ExcludeTrailingPathDelimiter(Root)));
    if (Rest <> '') and (Rest[1] = PathDelim) then
      Delete(Rest, 1, 1);
    while Rest <> '' do
    begin
      SepPos := Pos(PathDelim, Rest);
      if SepPos = 0 then
      begin
        Part := Rest;
        Rest := '';
      end
      else
      begin
        Part := Copy(Rest, 1, SepPos - 1);
        Delete(Rest, 1, SepPos);
      end;
      if Part <> '' then
        Parts.Add(Part);
    end;
    Items.Add(Root);
    for PartIdx := 0 to Parts.Count - 1 do
      Items.Add(StringOfChar(' ', 2 * (PartIdx + 1)) + Parts[PartIdx]);
    FLevels := Items.Count;
    if FindFirst(IncludeTrailingPathDelimiter(FDirectory) + '*', faDirectory,
                 SearchRec) = 0 then
    try
      repeat
        if ((SearchRec.Attr and faDirectory) <> 0) and
           (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          Subs.Add(SearchRec.Name);
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
    Subs.Sort;
    for PartIdx := 0 to Subs.Count - 1 do
      Items.Add(StringOfChar(' ', 2 * FLevels) + Subs[PartIdx]);
    ItemIndex := FLevels - 1;
  finally
    Items.EndUpdate;
    Subs.Free;
    Parts.Free;
  end;
end;

// Полный путь строки ARow
function TDirectoryListBox.PathOfRow(ARow: Integer): string;
var
  RowIdx: Integer;
begin
  Result := Items[0];
  for RowIdx := 1 to ARow do
  begin
    if (RowIdx >= FLevels) and (RowIdx <> ARow) then
      Continue;
    Result := IncludeTrailingPathDelimiter(Result) + Trim(Items[RowIdx]);
  end;
end;

procedure TDirectoryListBox.SetDirectory(const AValue: string);
var
  NewDir: string;
begin
  NewDir := ExpandFileName(AValue);
  if (Length(NewDir) > 3) or ((NewDir <> '') and (NewDir[Length(NewDir)] <> PathDelim)) then
    NewDir := ExcludeTrailingPathDelimiter(NewDir);
  if SameText(NewDir, FDirectory) and (Items.Count > 0) then
    Exit;
  FDirectory := NewDir;
  Fill;
  if FFileList <> nil then
    FFileList.Directory := FDirectory;
  if Assigned(FOnDirChange) then
    FOnDirChange(Self);
end;

procedure TDirectoryListBox.DblClick;
begin
  if ItemIndex >= 0 then
    SetDirectory(PathOfRow(ItemIndex));
  inherited DblClick;
end;

procedure TDirectoryListBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = 13) and (ItemIndex >= 0) then
  begin
    SetDirectory(PathOfRow(ItemIndex));
    Key := 0;
    Exit;
  end;
  inherited KeyDown(Key, Shift);
end;

procedure TDirectoryListBox.SetFileList(AValue: TFileListBox);
begin
  if FFileList <> nil then
    FFileList.RemoveFreeNotification(Self);
  FFileList := AValue;
  if FFileList <> nil then
  begin
    FFileList.FreeNotification(Self);
    if FDirectory <> '' then
      FFileList.Directory := FDirectory;
  end;
end;

procedure TDirectoryListBox.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FFileList) then
    FFileList := nil;
end;

end.
