unit Unit3;

// INC Manager (View - IncManager...): свои inc-файлы пользователя рядом с
// общими, что ставятся с редактором (rapidqAllProc.inc,
// rapidqComponents.inc). Цель - проверить свои файлы на ошибки, уже
// исправленные в общих, и найти то, чего в общих нет.
//
// Шаг 1 - список папок, где лежат свои inc-файлы. Папка выбирается слева
// (диск и дерево папок), "Добавить" кладёт её в список; галка в списке -
// папка участвует. Справа - найденные в отмеченных папках файлы .inc.
// Список хранится в editor.ini, раздел [IncManager]:
//   Count=2
//   Folder1=C:\BAS\RAPIDQ\INC|1     (1 - отмечена, 0 - нет)
//   SubDirs=1                       (искать и в подпапках)
// Записывается сразу при каждой правке - окно немодальное, кнопки OK нет.

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, ExtCtrls, FileCtrl, StdCtrls, Buttons, CheckLst,
  IniFiles;

type
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
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure CheckListBox1ClickCheck(Sender: TObject);
    procedure chkSubDirsClick(Sender: TObject);
  private
    FIniFile: string;
    FLoading: Boolean;   // список заполняется из editor.ini - не записывать
    procedure LoadFolders;
    procedure SaveFolders;
    procedure FillIncFiles;
  public
    // Показать окно со списком папок из AIniFile (editor.ini)
    procedure ShowFor(const AIniFile: string);
  end;

// Файлы .inc в папке (и в подпапках при ASub) - полными путями в AList
// (nil - только счёт). Обход останавливается на AMax файлах. Результат -
// число найденных.
function FindIncFiles(const ADir: string; ASub: Boolean; AList: TStrings;
                      AMax: Integer): Integer;

const
  IncMgrSection = 'IncManager';
  IncMgrMaxFiles = 20000;   // больше - скорее всего, выбран корень диска

var
  Form3: TForm3;

implementation

{$R *.dfm}

function FindIncFiles(const ADir: string; ASub: Boolean; AList: TStrings;
                      AMax: Integer): Integer;

  procedure Walk(const ADirPath: string);
  var
    SR: TSearchRec;
  begin
    if Result >= AMax then
      Exit;
    // Маска *.inc по коротким именам находит и file.inc~ - расширение
    // сверяется ещё раз
    if FindFirst(ADirPath + '*.inc', faAnyFile, SR) = 0 then
    try
      repeat
        if ((SR.Attr and faDirectory) = 0) and
           (CompareText(ExtractFileExt(SR.Name), '.inc') = 0) then
        begin
          if AList <> nil then
            AList.Add(ADirPath + SR.Name);
          Inc(Result);
          if Result >= AMax then
            Exit;
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
    if not ASub then
      Exit;
    if FindFirst(ADirPath + '*', faDirectory, SR) = 0 then
    try
      repeat
        if ((SR.Attr and faDirectory) <> 0) and (SR.Name <> '.') and
           (SR.Name <> '..') then
          Walk(ADirPath + SR.Name + '\');
        if Result >= AMax then
          Exit;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

begin
  Result := 0;
  if (ADir = '') or not DirectoryExists(ADir) then
    Exit;
  Walk(IncludeTrailingPathDelimiter(ADir));
end;

procedure TForm3.ShowFor(const AIniFile: string);
begin
  FIniFile := AIniFile;
  LoadFolders;
  Show;
  BringToFront;
end;

procedure TForm3.LoadFolders;
var
  Ini: TIniFile;
  Count, FolderIdx, BarPos, ItemIdx: Integer;
  Value, Dir: string;
begin
  FLoading := True;
  try
    CheckListBox1.Items.Clear;
    if FileExists(FIniFile) then
    begin
      Ini := TIniFile.Create(FIniFile);
      try
        chkSubDirs.Checked := Ini.ReadBool(IncMgrSection, 'SubDirs', True);
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
    Ini.EraseSection(IncMgrSection);
    Ini.WriteBool(IncMgrSection, 'SubDirs', chkSubDirs.Checked);
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

// Файлы .inc отмеченных папок - справа, без повторов (папка и её подпапка
// в списке вместе не дают двойного счёта). Все отмечены.
procedure TForm3.FillIncFiles;
var
  Files: TStringList;
  ItemIdx, Missing: Integer;
begin
  if FLoading then
    Exit;
  Screen.Cursor := crHourGlass;
  Files := TStringList.Create;
  try
    Files.Sorted := True;
    Files.Duplicates := dupIgnore;
    Missing := 0;
    for ItemIdx := 0 to CheckListBox1.Items.Count - 1 do
      if CheckListBox1.Checked[ItemIdx] then
      begin
        if not DirectoryExists(CheckListBox1.Items[ItemIdx]) then
          Inc(Missing)
        else
          FindIncFiles(CheckListBox1.Items[ItemIdx], chkSubDirs.Checked,
                       Files, IncMgrMaxFiles);
      end;
    lstIncFiles.Items.BeginUpdate;
    try
      lstIncFiles.Items.Assign(Files);
      for ItemIdx := 0 to lstIncFiles.Items.Count - 1 do
        lstIncFiles.Checked[ItemIdx] := True;
    finally
      lstIncFiles.Items.EndUpdate;
    end;
    lblCount.Caption := Format('Папок: %d, файлов .inc: %d',
                               [CheckListBox1.Items.Count, Files.Count]);
    if Missing > 0 then
      lblCount.Caption := lblCount.Caption +
                          Format(', папок нет на диске: %d', [Missing]);
  finally
    Files.Free;
    Screen.Cursor := crDefault;
  end;
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
