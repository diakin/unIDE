unit DlgPathList;

// Список путей (Library path, Browsing path страницы Compilers) - как окно
// Directories у Delphi: список по порядку поиска, поле пути, Replace / Add /
// Delete, удаление папок, которых нет на диске, порядок.
//
// Окно описано в DlgPathList.dfm и правится в конструкторе форм. Вызывает
// его TForm2.EditPathList (Unit2): отдаёт список через SetPaths, забирает
// через GetPaths. Макросы в путях ($(DELPHI), %VAR%) для проверки папок
// раскрывает обработчик OnExpand - это знает страница Compilers.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls,
  UiButton,     // TUiButton
  UiEditCtrls,  // TUiListBox, TUiEdit
  FolderDlg;    // выбор папки окном Проводника

type
  // Путь с раскрытыми макросами
  TPathExpandEvent = function(const APath: string): string of object;

  TDlgPathList = class(TForm)
    lstPaths: TUiListBox;
    lblState: TLabel;
    edPath: TUiEdit;
    btnBrowse: TUiButton;
    btnReplace: TUiButton;
    btnAdd: TUiButton;
    btnDelete: TUiButton;
    btnDelInvalid: TUiButton;
    btnUp: TUiButton;
    btnDown: TUiButton;
    btnOk: TUiButton;
    btnCancel: TUiButton;
    procedure lstPathsClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnReplaceClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnDelInvalidClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
  private
    FOnExpand: TPathExpandEvent;
    function ExpandPath(const APath: string): string;
    function PathExists(const APath: string): Boolean;
    procedure UpdateState;
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    procedure SetPaths(const AValue: string);
    function  GetPaths: string;
    property OnExpand: TPathExpandEvent read FOnExpand write FOnExpand;
  end;

implementation

{$R *.dfm}

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана (см. TForm1.WMUpdateUIState). Сообщение дальше не
// передаём: состояние не меняется, и перерисовывать нечего.
procedure TDlgPathList.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

function TDlgPathList.ExpandPath(const APath: string): string;
begin
  if Assigned(FOnExpand) then
    Result := FOnExpand(Trim(APath))
  else
    Result := Trim(APath);
end;

function TDlgPathList.PathExists(const APath: string): Boolean;
begin
  Result := DirectoryExists(ExpandPath(APath));
end;

// Строка под списком: сколько папок и скольких нет на диске
procedure TDlgPathList.UpdateState;
var
  ItemIdx, Missing: Integer;
  StateText: string;
begin
  Missing := 0;
  for ItemIdx := 0 to lstPaths.Items.Count - 1 do
    if not PathExists(lstPaths.Items[ItemIdx]) then
      Inc(Missing);
  StateText := 'Папок: ' + IntToStr(lstPaths.Items.Count) +
               ', нет на диске: ' + IntToStr(Missing);
  if lstPaths.ItemIndex >= 0 then
  begin
    if PathExists(lstPaths.Items[lstPaths.ItemIndex]) then
      StateText := StateText + '.  Выбранная есть'
    else
      StateText := StateText + '.  Выбранной нет на диске';
  end;
  lblState.Caption := StateText;
end;

// Пути через точку с запятой - в список, первый выбран
procedure TDlgPathList.SetPaths(const AValue: string);
var
  Rest, Item: string;
  SepPos: Integer;
begin
  lstPaths.Items.Clear;
  Rest := AValue;
  while Rest <> '' do
  begin
    SepPos := Pos(';', Rest);
    if SepPos = 0 then
      SepPos := Length(Rest) + 1;
    Item := Trim(Copy(Rest, 1, SepPos - 1));
    Delete(Rest, 1, SepPos);
    if Item <> '' then
      lstPaths.Items.Add(Item);
  end;
  if lstPaths.Items.Count > 0 then
  begin
    lstPaths.ItemIndex := 0;
    edPath.Text := lstPaths.Items[0];
  end;
  UpdateState;
end;

function TDlgPathList.GetPaths: string;
var
  ItemIdx: Integer;
begin
  Result := '';
  for ItemIdx := 0 to lstPaths.Items.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + ';';
    Result := Result + lstPaths.Items[ItemIdx];
  end;
end;

procedure TDlgPathList.lstPathsClick(Sender: TObject);
begin
  if lstPaths.ItemIndex >= 0 then
    edPath.Text := lstPaths.Items[lstPaths.ItemIndex];
  UpdateState;
end;

procedure TDlgPathList.btnBrowseClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := ExpandPath(edPath.Text);
  if BrowseFolderDialog('Папка', Dir) then
    edPath.Text := ExcludeTrailingPathDelimiter(Dir);
end;

procedure TDlgPathList.btnReplaceClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  ItemIdx := lstPaths.ItemIndex;
  if (ItemIdx < 0) or (Trim(edPath.Text) = '') then
    Exit;
  lstPaths.Items[ItemIdx] := Trim(edPath.Text);
  lstPaths.ItemIndex := ItemIdx;
  UpdateState;
end;

procedure TDlgPathList.btnAddClick(Sender: TObject);
var
  Item: string;
begin
  Item := Trim(edPath.Text);
  if Item = '' then
    Exit;
  if lstPaths.Items.IndexOf(Item) < 0 then
    lstPaths.Items.Add(Item);
  lstPaths.ItemIndex := lstPaths.Items.IndexOf(Item);
  UpdateState;
end;

procedure TDlgPathList.btnDeleteClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  ItemIdx := lstPaths.ItemIndex;
  if ItemIdx < 0 then
    Exit;
  lstPaths.Items.Delete(ItemIdx);
  if ItemIdx >= lstPaths.Items.Count then
    ItemIdx := lstPaths.Items.Count - 1;
  lstPaths.ItemIndex := ItemIdx;
  UpdateState;
end;

procedure TDlgPathList.btnDelInvalidClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  for ItemIdx := lstPaths.Items.Count - 1 downto 0 do
    if not PathExists(lstPaths.Items[ItemIdx]) then
      lstPaths.Items.Delete(ItemIdx);
  UpdateState;
end;

procedure TDlgPathList.btnUpClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  ItemIdx := lstPaths.ItemIndex;
  if ItemIdx <= 0 then
    Exit;
  lstPaths.Items.Exchange(ItemIdx, ItemIdx - 1);
  lstPaths.ItemIndex := ItemIdx - 1;
end;

procedure TDlgPathList.btnDownClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  ItemIdx := lstPaths.ItemIndex;
  if (ItemIdx < 0) or (ItemIdx >= lstPaths.Items.Count - 1) then
    Exit;
  lstPaths.Items.Exchange(ItemIdx, ItemIdx + 1);
  lstPaths.ItemIndex := ItemIdx + 1;
end;

end.
