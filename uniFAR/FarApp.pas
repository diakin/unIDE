unit FarApp;

// ---------------------------------------------------------------------------
//  uniFAR - FAR из unIDE отдельной программой (Free Pascal, без LCL).
//
//  Главное окно - окно Windows (RegisterClassW), в нём TFarView (UnFar) на
//  всю клиентскую область. Свой цикл сообщений: клавиши сначала в
//  TFarView.KeyMessage (как TForm1.AppMessage в unIDE), остальное -
//  TranslateMessage / DispatchMessageW.
//
//  Настройки - uniFAR.ini рядом с uniFAR.exe. Его нет - создаётся из
//  editor.ini unIDE (папка программы и до трёх папок выше): разделы FAR,
//  тема ([Themes] Current) и цвета редактора ([Editor]). Дальше uniFAR и
//  unIDE хранят настройки FAR каждый у себя.
//
//  Схемы подсветки (редактор F4) - папка schemes\ там же, где искался
//  editor.ini (рядом с uniFAR.exe или выше).
//
//  Командная строка: uniFAR.exe [папка | файл] - активная панель в эту
//  папку (у файла - в его папку, курсор на нём).
//  Значок - res\uniFAR_icon.res (res\make_icon.py).
//
//  Над панелями - вкладки папок (FarTabs.pas): папка активной панели и
//  свой список вкладок ([FolderTabs]), сколько поместится по ширине. Alt+Left /
//  Alt+Right - по вкладкам, мышь - просмотр, щелчок - перейти.
//  uniFAR.ini [uniFAR] FolderTabs=0 - без вкладок.
// ---------------------------------------------------------------------------

{$mode delphi}

// Исходник в кодировке Windows-1251 (строки с кириллицей в WideString)
{$CODEPAGE CP1251}

interface

procedure FarAppRun;

implementation

{$R res\uniFAR_icon.res}

uses
  Windows, Messages, SysUtils, Classes, IniFiles, Graphics, ClrScheme,
  SchemeFiles, UnFar, FarTabs;

function AppCommandLineToArgv(ACmdLine: PWideChar;
  var AArgCount: Integer): PPWideChar; stdcall;
  external 'shell32.dll' name 'CommandLineToArgvW';

const
  AppTitle = 'uniFAR';
  AppIniFile = 'uniFAR.ini';
  AppIniSection = 'uniFAR';
  AppClassName: PWideChar = 'uniFARMain';
  // Сколько папок выше uniFAR.exe смотреть в поисках editor.ini и schemes\
  AppSearchUp = 3;
  // Разделы editor.ini, которые переходят в uniFAR.ini целиком
  ImportSections: array[0..5] of string = ('Far', 'FarHistory',
    'FarCmdHistory', 'FarColors', 'FarPalette', 'FarFtp');

type
  // Обработчики событий TFarView - методы объекта
  TFarAppEvents = class
  public
    procedure FarClose(Sender: TObject);
    procedure FarPainted(Sender: TObject);
    function FarGetScheme(const AFileName: WideString): TClrScheme;
  end;

var
  MainWnd: HWND = 0;
  FarView: TFarView = nil;
  TabBar: TFarTabBar = nil;
  Events: TFarAppEvents = nil;
  IniName: string = '';
  SchemesDir: string = '';
  ThemeName: string = '';
  EditFontColor: TColor = clBlack;
  EditBgColor: TColor = TColor($00F9F9F9);

// Папка программы или папка выше (до AppSearchUp), где есть AName (файл или
// папка); '' - нет нигде
function FindUp(const AName: string; AIsDir: Boolean): string;
var
  Dir, Parent: string;
  Level: Integer;
begin
  Result := '';
  Dir := ExtractFilePath(ParamStr(0));
  for Level := 0 to AppSearchUp do
  begin
    if (AIsDir and DirectoryExists(Dir + AName)) or
       (not AIsDir and FileExists(Dir + AName)) then
    begin
      Result := Dir;
      Exit;
    end;
    Parent := ExtractFilePath(ExcludeTrailingPathDelimiter(Dir));
    if (Parent = '') or (Parent = Dir) then
      Exit;
    Dir := Parent;
  end;
end;

// Первый запуск: uniFAR.ini из editor.ini unIDE
procedure ImportFromEditorIni(const AEditorIni: string);
var
  Source: TIniFile;
  Target: TMemIniFile;
  Values, Keys: TStringList;
  SectIdx, KeyIdx: Integer;
  KeyName, BaseKey: string;
begin
  Source := TIniFile.Create(AEditorIni);
  Target := TMemIniFile.Create(IniName);
  Values := TStringList.Create;
  Keys := TStringList.Create;
  try
    for SectIdx := Low(ImportSections) to High(ImportSections) do
    begin
      Source.ReadSection(ImportSections[SectIdx], Keys);
      for KeyIdx := 0 to Keys.Count - 1 do
        Target.WriteString(ImportSections[SectIdx], Keys[KeyIdx],
          Source.ReadString(ImportSections[SectIdx], Keys[KeyIdx], ''));
    end;
    if Source.ValueExists('Themes', 'Current') then
      Target.WriteString('Themes', 'Current',
        Source.ReadString('Themes', 'Current', ''));
    // [Editor]: шаг табуляции и цвета текста и фона (с вариантами Ключ@Тема)
    Source.ReadSection('Editor', Keys);
    for KeyIdx := 0 to Keys.Count - 1 do
    begin
      KeyName := Keys[KeyIdx];
      BaseKey := KeyName;
      if Pos('@', BaseKey) > 0 then
        BaseKey := Copy(BaseKey, 1, Pos('@', BaseKey) - 1);
      if (CompareText(BaseKey, 'TabChars') = 0) or
         (CompareText(BaseKey, 'FontColor') = 0) or
         (CompareText(BaseKey, 'BGColor') = 0) then
        Target.WriteString('Editor', KeyName,
          Source.ReadString('Editor', KeyName, ''));
    end;
    Target.WriteString(AppIniSection, 'ImportedFrom', AEditorIni);
    Target.UpdateFile;
  finally
    Keys.Free;
    Values.Free;
    Target.Free;
    Source.Free;
  end;
end;

// Значение с учётом темы: Ключ@Тема, если есть, иначе Ключ (как у unIDE)
function ThemeRead(AIni: TCustomIniFile; const ASection, AKey,
  ADefault: string): string;
begin
  Result := AIni.ReadString(ASection, AKey, ADefault);
  if ThemeKey(ThemeName) <> '' then
    Result := AIni.ReadString(ASection, AKey + '@' + ThemeKey(ThemeName),
      Result);
end;

function SafeColor(const AText: string; ADefault: TColor): TColor;
begin
  try
    Result := StringToColor(AText);
  except
    Result := ADefault;
  end;
end;

procedure LoadSettings;
var
  EditorDir: string;
  Ini: TIniFile;
begin
  IniName := ExtractFilePath(ParamStr(0)) + AppIniFile;
  EditorDir := FindUp('editor.ini', False);
  if not FileExists(IniName) and (EditorDir <> '') then
    try
      ImportFromEditorIni(EditorDir + 'editor.ini');
    except
      // Не прочитался editor.ini - начинаем с чистого uniFAR.ini
    end;
  SchemesDir := FindUp('schemes', True);
  if SchemesDir <> '' then
    SchemesDir := SchemesDir + 'schemes\';
  Ini := TIniFile.Create(IniName);
  try
    ThemeName := Trim(Ini.ReadString('Themes', 'Current', BaseThemeName));
    if ThemeName = '' then
      ThemeName := BaseThemeName;
    EditFontColor := SafeColor(ThemeRead(Ini, 'Editor', 'FontColor',
      ColorToString(EditFontColor)), EditFontColor);
    EditBgColor := SafeColor(ThemeRead(Ini, 'Editor', 'BGColor',
      ColorToString(EditBgColor)), EditBgColor);
  finally
    Ini.Free;
  end;
end;

// ---------------------------------------------------------------------------

procedure TFarAppEvents.FarClose(Sender: TObject);
begin
  PostMessage(MainWnd, WM_CLOSE, 0, 0);
end;

procedure LayoutView; forward;

// Окно FAR перерисовано: вкладки - тоже (папка панели, история могли
// измениться); сменился шрифт панелей - другая высота полосы вкладок
procedure TFarAppEvents.FarPainted(Sender: TObject);
begin
  if TabBar = nil then
    Exit;
  if TabBar.Height <> TabBar.BarHeight then
    LayoutView
  else
    TabBar.Invalidate;
end;

function TFarAppEvents.FarGetScheme(const AFileName: WideString): TClrScheme;
var
  SchemeKey: string;
begin
  Result := nil;
  if SchemesDir = '' then
    Exit;
  SchemeKey := SchemeKeyForFile(SchemesDir, string(AFileName), False);
  Result := SchemeLoadFromDir(SchemesDir, SchemeKey, ThemeName, EditFontColor,
    EditBgColor);
end;

// ---------------------------------------------------------------------------

procedure SaveWindowPlacement;
var
  Placement: TWindowPlacement;
  Ini: TMemIniFile;
begin
  FillChar(Placement, SizeOf(Placement), 0);
  Placement.length := SizeOf(Placement);
  if not GetWindowPlacement(MainWnd, @Placement) then
    Exit;
  Ini := TMemIniFile.Create(IniName);
  try
    with Placement.rcNormalPosition do
    begin
      Ini.WriteInteger(AppIniSection, 'Left', Left);
      Ini.WriteInteger(AppIniSection, 'Top', Top);
      Ini.WriteInteger(AppIniSection, 'Width', Right - Left);
      Ini.WriteInteger(AppIniSection, 'Height', Bottom - Top);
    end;
    Ini.WriteInteger(AppIniSection, 'Maximized',
      Ord(Placement.showCmd = SW_SHOWMAXIMIZED));
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

// Закрыть программу: в редакторе F4 изменён текст - спросить
procedure TryClose;
begin
  if (FarView <> nil) and not FarView.EditorCanClose then
    Exit;
  if TabBar <> nil then
    TabBar.LeaveMode;
  SaveWindowPlacement;
  if FarView <> nil then
    FarView.SaveState(IniName);
  DestroyWindow(MainWnd);
end;

procedure LayoutView;
var
  ClientRect: TRect;
  BarH: Integer;
begin
  if FarView = nil then
    Exit;
  GetClientRect(MainWnd, ClientRect);
  BarH := 0;
  if TabBar <> nil then
  begin
    BarH := TabBar.BarHeight;
    TabBar.SetBounds(0, 0, ClientRect.Right, BarH);
  end;
  FarView.SetBounds(0, BarH, ClientRect.Right, ClientRect.Bottom - BarH);
end;

function MainWindowProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
var
  MinMax: PMinMaxInfo;
begin
  Result := 0;
  case AMsg of
    WM_SIZE:
      LayoutView;
    WM_SETFOCUS:
      if (FarView <> nil) and FarView.HandleAllocated then
        Windows.SetFocus(FarView.Handle);
    WM_GETMINMAXINFO:
      begin
        MinMax := PMinMaxInfo(ALParam);
        MinMax^.ptMinTrackSize.X := 400;
        MinMax^.ptMinTrackSize.Y := 250;
      end;
    WM_SYSCOMMAND:
      // Alt или F10 без других клавиш: окно ушло бы в режим меню, следующая
      // клавиша не дошла бы до FAR. Alt+Space (системное меню) - как обычно
      if ((AWParam and $FFF0) = SC_KEYMENU) and (ALParam = 0) then
        Result := 0
      else
        Result := DefWindowProcW(AWnd, AMsg, AWParam, ALParam);
    WM_CLOSE:
      TryClose;
    WM_DESTROY:
      begin
        FreeAndNil(TabBar);
        FreeAndNil(FarView);
        MainWnd := 0;
        PostQuitMessage(0);
      end;
  else
    Result := DefWindowProcW(AWnd, AMsg, AWParam, ALParam);
  end;
end;

// Заголовок окна: версия FAR и дата сборки - видно, свежий ли exe
function AppCaption: WideString;
var
  BuildDate: string;
begin
  BuildDate := {$I %DATE%};      // ГГГГ/ММ/ДД
  if Length(BuildDate) = 10 then
    BuildDate := Copy(BuildDate, 9, 2) + '.' + Copy(BuildDate, 6, 2) + '.' +
      Copy(BuildDate, 1, 4);
  Result := WideString(AppTitle + ' ' + FarBuild + ' (сборка ' + BuildDate +
    ' ' + Copy({$I %TIME%}, 1, 5) + ')');
end;

procedure CreateMainWindow;
var
  WndClass: TWndClassW;
  Ini: TIniFile;
  WinLeft, WinTop, WinWidth, WinHeight, TabCount: Integer;
  Maximized: Boolean;
begin
  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.lpfnWndProc := @MainWindowProc;
  WndClass.hInstance := HInstance;
  WndClass.hIcon := LoadIcon(HInstance, 'UNIFARICON');
  if WndClass.hIcon = 0 then
    WndClass.hIcon := LoadIcon(0, IDI_APPLICATION);
  WndClass.hCursor := LoadCursor(0, IDC_ARROW);
  WndClass.lpszClassName := AppClassName;
  RegisterClassW(WndClass);

  Ini := TIniFile.Create(IniName);
  try
    WinLeft := Ini.ReadInteger(AppIniSection, 'Left', Integer(CW_USEDEFAULT));
    WinTop := Ini.ReadInteger(AppIniSection, 'Top', Integer(CW_USEDEFAULT));
    WinWidth := Ini.ReadInteger(AppIniSection, 'Width', 1020);
    WinHeight := Ini.ReadInteger(AppIniSection, 'Height', 680);
    Maximized := Ini.ReadInteger(AppIniSection, 'Maximized', 0) <> 0;
    TabCount := Ini.ReadInteger(AppIniSection, 'FolderTabs', 1);
  finally
    Ini.Free;
  end;
  MainWnd := CreateWindowExW(0, AppClassName, PWideChar(AppCaption),
    WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN, WinLeft, WinTop, WinWidth,
    WinHeight, 0, 0, HInstance, nil);
  if MainWnd = 0 then
    raise Exception.CreateFmt('Главное окно не создано (ошибка %d)',
      [GetLastError]);

  FarView := TFarView.Create(nil);
  FarView.UnicodeChars := True;
  FarView.MessageLine := True;
  FarView.OnClose := Events.FarClose;
  FarView.OnGetScheme := Events.FarGetScheme;
  // OnEditFile, OnLeave, OnHalfResize, OnShowPanels - режим F4 рядом с
  // редактором unIDE; OnColorsDialog, OnPaletteDialog - окна настроек
  // unIDE. Здесь их нет
  FarView.ParentWindow := MainWnd;
  if TabCount > 0 then
  begin
    TabBar := TFarTabBar.Create(nil, FarView);
    TabBar.ParentWindow := MainWnd;
    FarView.OnPainted := Events.FarPainted;
  end;
  LayoutView;

  if Maximized then
    ShowWindow(MainWnd, SW_SHOWMAXIMIZED)
  else
    ShowWindow(MainWnd, SW_SHOWNORMAL);
  UpdateWindow(MainWnd);
  Windows.SetFocus(FarView.Handle);
end;

function CurrentDirW: WideString;
var
  Buffer: array[0..MAX_PATH] of WideChar;
  Len: DWORD;
begin
  Len := GetCurrentDirectoryW(Length(Buffer), Buffer);
  if (Len = 0) or (Len >= DWORD(Length(Buffer))) then
    Result := WideString(GetCurrentDir)
  else
    SetString(Result, Buffer, Len);
end;

// Первый параметр командной строки (Unicode); нет - пусто
function FirstParamW: WideString;
var
  Args: PPWideChar;
  ArgCount: Integer;
begin
  Result := '';
  ArgCount := 0;
  Args := AppCommandLineToArgv(GetCommandLineW, ArgCount);
  if Args = nil then
    Exit;
  try
    if ArgCount >= 2 then
      Result := WideString(PPWideChar(PtrUInt(Args) + SizeOf(PWideChar))^);
  finally
    LocalFree(HLOCAL(Args));
  end;
end;

// Папка или файл из командной строки - в активную панель
procedure OpenFromCommandLine;
var
  Param: WideString;
  Attr: DWORD;
begin
  Param := FirstParamW;
  if Param = '' then
    Exit;
  Attr := GetFileAttributesW(PWideChar(Param));
  if Attr = $FFFFFFFF then
    Exit;
  if Attr and FILE_ATTRIBUTE_DIRECTORY <> 0 then
    FarView.ShowFolder(Param)
  else
    FarView.ShowFile(Param);
end;

procedure MessageLoop;
var
  Msg: TMsg;
begin
  while GetMessageW(Msg, 0, 0, 0) do
  begin
    // Вкладки папок: Alt+Left / Alt+Right, а в режиме вкладок - их клавиши
    if (TabBar <> nil) and (FarView <> nil) and FarView.HandleAllocated and
       (Msg.hwnd = FarView.Handle) then
    begin
      if ((Msg.message = WM_KEYDOWN) or (Msg.message = WM_SYSKEYDOWN)) and
         TabBar.HandleKey(Word(Msg.wParam)) then
        Continue;
      // Щелчок по панелям - из режима вкладок
      if TabBar.ModeOn and ((Msg.message = WM_LBUTTONDOWN) or
         (Msg.message = WM_RBUTTONDOWN)) then
        TabBar.LeaveMode;
    end;
    // Клавиши окна FAR - сначала ему (F-клавиши, Alt+F1, символы и т.д.)
    if (FarView <> nil) and FarView.HandleAllocated and
       (Msg.hwnd = FarView.Handle) and
       (((Msg.message >= WM_KEYFIRST) and (Msg.message <= WM_KEYLAST))) and
       FarView.KeyMessage(Msg) then
      Continue;
    TranslateMessage(Msg);
    DispatchMessageW(Msg);
  end;
end;

procedure FarAppRun;
begin
  FarProduct := AppTitle;
  Events := TFarAppEvents.Create;
  try
    LoadSettings;
    CreateMainWindow;
    FarView.LoadState(IniName, CurrentDirW);
    if TabBar <> nil then
      TabBar.LoadList(IniName);
    OpenFromCommandLine;
    MessageLoop;
  finally
    FreeAndNil(FarView);
    Events.Free;
  end;
end;

end.
