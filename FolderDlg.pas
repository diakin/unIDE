unit FolderDlg;

// Выбор папки окном открытия файла (Проводник: адресная строка, избранное,
// поиск, поле с именем) вместо системного "Обзор папок" (SHBrowseForFolder).
//
// В Vista и новее - IFileOpenDialog с FOS_PICKFOLDERS: окно Проводника,
// в котором выбирается папка. В Delphi 7 этих интерфейсов нет, они описаны
// здесь. Если объект не создаётся (XP), показывается обычный TOpenDialog:
// в поле имени стоит заглушка, папкой считается та, в которой нажали
// "Открыть".

interface

uses
  Windows, SysUtils, Classes, Forms, Dialogs, ActiveX;

// ACaption - заголовок окна. ADir - стартовая папка на входе (если её нет,
// берётся ближайшая существующая папка выше), выбранная папка на выходе,
// без завершающего "\" - как у FileCtrl.SelectDirectory.
function BrowseFolderDialog(const ACaption: string; var ADir: string): Boolean;

implementation

const
  CLSID_FileOpenDialog: TGUID = '{DC1C5A9C-E88A-4DDE-A5A1-60F82A20AEF7}';

  FOS_NOCHANGEDIR     = $00000008;
  FOS_PICKFOLDERS     = $00000020;
  FOS_FORCEFILESYSTEM = $00000040;
  FOS_PATHMUSTEXIST   = $00000800;

  SIGDN_FILESYSPATH   = DWORD($80058000);

type
  IShellItem = interface(IUnknown)
    ['{43826D1E-E718-42EE-BC55-A1E261C37BFE}']
    function BindToHandler(pbc: Pointer; const bhid: TGUID;
      const riid: TIID; out ppv): HResult; stdcall;
    function GetParent(out ppsi: IShellItem): HResult; stdcall;
    function GetDisplayName(sigdnName: DWORD;
      out ppszName: PWideChar): HResult; stdcall;
    function GetAttributes(sfgaoMask: DWORD;
      out psfgaoAttribs: DWORD): HResult; stdcall;
    function Compare(const psi: IShellItem; hint: DWORD;
      out piOrder: Integer): HResult; stdcall;
  end;

  // Методы перечислены в порядке таблицы IFileDialog (shobjidl.h):
  // по этому порядку и вызываются, имена параметров значения не имеют
  IFileDialog = interface(IUnknown)
    ['{42F85136-DB7E-439C-85F1-E4075D135FC8}']
    // IModalWindow
    function Show(hwndOwner: HWND): HResult; stdcall;
    // IFileDialog
    function SetFileTypes(cFileTypes: UINT; rgFilterSpec: Pointer): HResult; stdcall;
    function SetFileTypeIndex(iFileType: UINT): HResult; stdcall;
    function GetFileTypeIndex(out piFileType: UINT): HResult; stdcall;
    function Advise(const pfde: IUnknown; out pdwCookie: DWORD): HResult; stdcall;
    function Unadvise(dwCookie: DWORD): HResult; stdcall;
    function SetOptions(fos: DWORD): HResult; stdcall;
    function GetOptions(out pfos: DWORD): HResult; stdcall;
    function SetDefaultFolder(const psi: IShellItem): HResult; stdcall;
    function SetFolder(const psi: IShellItem): HResult; stdcall;
    function GetFolder(out ppsi: IShellItem): HResult; stdcall;
    function GetCurrentSelection(out ppsi: IShellItem): HResult; stdcall;
    function SetFileName(pszName: PWideChar): HResult; stdcall;
    function GetFileName(out pszName: PWideChar): HResult; stdcall;
    function SetTitle(pszTitle: PWideChar): HResult; stdcall;
    function SetOkButtonLabel(pszText: PWideChar): HResult; stdcall;
    function SetFileNameLabel(pszLabel: PWideChar): HResult; stdcall;
    function GetResult(out ppsi: IShellItem): HResult; stdcall;
    function AddPlace(const psi: IShellItem; fdap: DWORD): HResult; stdcall;
    function SetDefaultExtension(pszDefaultExtension: PWideChar): HResult; stdcall;
    function Close(hr: HResult): HResult; stdcall;
    function SetClientGuid(const guid: TGUID): HResult; stdcall;
    function ClearClientData: HResult; stdcall;
    function SetFilter(pFilter: Pointer): HResult; stdcall;
  end;

  // shell32 с Vista. Берётся через GetProcAddress, чтобы программа
  // запускалась и на XP
  TSHCreateItemFromParsingName = function(pszPath: PWideChar; pbc: Pointer;
    const riid: TIID; out ppv): HResult; stdcall;

// Существующая папка для старта: сама ADir или ближайшая выше по пути
function ExistingStartDir(const ADir: string): string;
var
  Parent: string;
begin
  Result := ExcludeTrailingPathDelimiter(Trim(ADir));
  while (Result <> '') and not DirectoryExists(Result) do
  begin
    Parent := ExcludeTrailingPathDelimiter(ExtractFilePath(Result));
    if Parent = Result then
    begin
      Result := '';
      Break;
    end;
    Result := Parent;
  end;
end;

// Окно владельца: активная форма программы, чтобы диалог встал над ней
function OwnerWnd: HWND;
begin
  if Screen.ActiveForm <> nil then
    Result := Screen.ActiveForm.Handle
  else
    Result := Application.Handle;
end;

// Vista и новее. Result = False и AShown = False - объект не создан,
// нужен запасной путь. AShown = True - окно было, Result - нажали ли ОК.
function VistaPickFolder(const ACaption, AStart: string; var ADir: string;
                         out AShown: Boolean): Boolean;
var
  FileDlg: IFileDialog;
  Item: IShellItem;
  Opts: DWORD;
  WideStr: WideString;
  PathPtr: PWideChar;
  Shell32: HMODULE;
  CreateItem: TSHCreateItemFromParsingName;
begin
  Result := False;
  AShown := False;

  if Failed(CoCreateInstance(CLSID_FileOpenDialog, nil,
       CLSCTX_INPROC_SERVER, IFileDialog, FileDlg)) then
    Exit;

  if Succeeded(FileDlg.GetOptions(Opts)) then
    FileDlg.SetOptions(Opts or FOS_PICKFOLDERS or FOS_FORCEFILESYSTEM or
                       FOS_PATHMUSTEXIST or FOS_NOCHANGEDIR);

  if ACaption <> '' then
  begin
    WideStr := ACaption;
    FileDlg.SetTitle(PWideChar(WideStr));
  end;

  if AStart <> '' then
  begin
    Shell32 := GetModuleHandle('shell32.dll');
    @CreateItem := nil;
    if Shell32 <> 0 then
      @CreateItem := GetProcAddress(Shell32, 'SHCreateItemFromParsingName');
    if Assigned(CreateItem) then
    begin
      WideStr := AStart;
      if Succeeded(CreateItem(PWideChar(WideStr), nil, IShellItem, Item)) then
        FileDlg.SetFolder(Item);
      Item := nil;
    end;
  end;

  AShown := True;
  // Отмена возвращает ERROR_CANCELLED в виде HResult - это тоже Failed
  if Failed(FileDlg.Show(OwnerWnd)) then
    Exit;

  if Failed(FileDlg.GetResult(Item)) then
    Exit;
  if Succeeded(Item.GetDisplayName(SIGDN_FILESYSPATH, PathPtr)) then
  try
    ADir := ExcludeTrailingPathDelimiter(string(WideString(PathPtr)));
    Result := ADir <> '';
  finally
    CoTaskMemFree(PathPtr);
  end;
end;

// XP: обычное окно открытия файла. Имя файла - заглушка, проверка имени
// отключена, и "Открыть" принимается в любой папке
function LegacyPickFolder(const ACaption, AStart: string;
                          var ADir: string): Boolean;
const
  StubName = 'Выбрать эту папку';
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Title := ACaption;
    OpenDlg.InitialDir := AStart;
    OpenDlg.FileName := StubName;
    OpenDlg.Filter := 'Папки|*.~folder~';
    OpenDlg.Options := [ofNoValidate, ofPathMustExist, ofHideReadOnly,
                        ofNoChangeDir, ofEnableSizing];
    Result := OpenDlg.Execute;
    if Result then
    begin
      ADir := ExcludeTrailingPathDelimiter(ExtractFilePath(OpenDlg.FileName));
      Result := ADir <> '';
    end;
  finally
    OpenDlg.Free;
  end;
end;

function BrowseFolderDialog(const ACaption: string; var ADir: string): Boolean;
var
  Start, Picked: string;
  Shown: Boolean;
  InitRes: HResult;
begin
  Start := ExistingStartDir(ADir);
  Picked := '';

  // COM в главном потоке может быть ещё не поднят. S_OK и S_FALSE требуют
  // парного CoUninitialize; RPC_E_CHANGED_MODE - уже поднят в другом
  // режиме, тогда просто работаем дальше
  InitRes := CoInitialize(nil);
  try
    Result := VistaPickFolder(ACaption, Start, Picked, Shown);
  finally
    if Succeeded(InitRes) then
      CoUninitialize;
  end;

  if not Shown then
    Result := LegacyPickFolder(ACaption, Start, Picked);

  if Result then
    ADir := Picked;
end;

end.
