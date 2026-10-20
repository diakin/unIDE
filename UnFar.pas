unit UnFar;

// ---------------------------------------------------------------------------
//  unIDE FAR - двухпанельный файловый менеджер в духе FAR Manager
//  (меню Utils - unIDE FAR).
//
//  Окно встаёт поверх области редактора: вкладки, тулбар, лог, инспектор и
//  строки состояния остаются видны. Место и размер задаёт Unit1
//  (TForm1.FarLayout), закрывает окно тоже Unit1 (OnClose, клавиша F10).
//
//  Сделано (FarBuild):
//    - две панели в режиме Brief (две колонки имён), как в FAR;
//    - переходы по папкам: Enter, Ctrl+PgDn - войти, Ctrl+PgUp - выше,
//      Ctrl+\ - в корень диска; Tab - другая панель; Ctrl+R - перечитать;
//    - курсор: стрелки, Home/End, PgUp/PgDn (на страницу, как в FAR);
//    - выделение: Ins, Shift+стрелки, Shift+PgUp/PgDn, Shift+Home/End;
//    - нижняя строка - кейбар FAR, при Shift / Ctrl / Alt - свой слой;
//    - пути панелей и файл под курсором - в editor.ini, раздел [Far].
//  Остальные клавиши FAR пока сообщают в строке состояния, что не сделаны
//  (F1, F2, F3, F12 - заглушки по плану).
//
//  Имена файлов - WideString, папки читаются W-функциями Windows
//  (FindFirstFileW): имена с символами вне cp1251 не теряются.
//
//  Шрифт - Terminus Bold 10x18 в кодировке cp1251 (SIL OFL 1.1) из ресурсов
//  exe (farfont.res, см. fonts\make_farfont.py). При первом открытии файл
//  шрифта пишется во временную папку и подключается только для этой
//  программы (AddFontResourceEx с FR_PRIVATE). Файл ter-c18b.fnt рядом с
//  exe важнее ресурса - так шрифт можно заменить без пересборки.
//  Нет Terminus - Lucida Console того же размера.
//  Символов вне cp1251 в Terminus нет: их рисует Lucida Console в ту же
//  клетку. Рамки рисуются линиями (псевдографики в cp1251 нет).
//
//  Клавиши приходят из TForm1.AppMessage (KeyMessage) раньше всех
//  обработчиков IDE: F-клавиши FAR не доходят ни до отладчика, ни до
//  ярлыков меню, F10 и Alt+F... - до полосы меню.
//
//  Цвета - палитра FAR по умолчанию (far\palette.cpp форка FarManager).
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, IniBuf;

const
  FarBuild = 'b.1';

type
  TFarItem = record
    Name: WideString;
    Size: Int64;
    Attr: DWORD;
    WriteTime: TFileTime;
    IsDir: Boolean;
    IsUp: Boolean;       // строка '..'
    Selected: Boolean;
  end;
  // Один тип массива для поля и локальных переменных: в Delphi 7 два
  // отдельно описанных 'array of TFarItem' - разные типы, присвоить нельзя
  TFarItems = array of TFarItem;

  // Одна панель: папка, её список и курсор
  TFarPanel = class
  private
    FPath: WideString;          // всегда с '\' на конце
    FItems: TFarItems;
    FCount: Integer;
    FCursor: Integer;
    FTopIndex: Integer;
    FFileCount: Integer;
    FFileBytes: Int64;
    FFreeBytes: Int64;
    FFreeKnown: Boolean;
    procedure SortItems;
    function ItemLess(const ItemA, ItemB: TFarItem): Boolean;
  public
    // Прочитать папку APath и поставить курсор на AFocusName. False - папку
    // прочитать нельзя (нет доступа и т.п.), прежнее содержимое остаётся.
    function ReadDir(const APath, AFocusName: WideString;
      var AError: string): Boolean;
    // Перечитать текущую папку: курсор и выделение по именам сохраняются
    procedure Reread;
    function IndexOfName(const AName: WideString): Integer;
    function SelCount: Integer;
    function SelBytes: Int64;
    procedure SetSelected(AIndex: Integer; AValue: Boolean);
    function IsRoot: Boolean;
    function ParentPath(var AChildName: WideString): WideString;
    property Path: WideString read FPath;
    property Count: Integer read FCount;
    property Cursor: Integer read FCursor write FCursor;
    property TopIndex: Integer read FTopIndex write FTopIndex;
  end;

  TFarStatusEvent = procedure(const AText: string) of object;

  TFarView = class(TCustomControl)
  private
    FPanels: array[0..1] of TFarPanel;
    FActive: Integer;
    FFontMain: HFONT;
    FFontAlt: HFONT;           // для символов вне cp1251 (только при Terminus)
    FFontIsTerminus: Boolean;
    FCellW: Integer;
    FCellH: Integer;
    FTextTop: Integer;
    FCols: Integer;
    FRows: Integer;
    FBuffer: TBitmap;
    FDx: array of Integer;     // шаг символов для ExtTextOutW - ширина клетки
    FShiftSelActive: Boolean;  // Shift держат: выделение идёт одним значением
    FShiftSelValue: Boolean;
    FEatAltUp: Boolean;
    FOnClose: TNotifyEvent;
    FOnStatus: TFarStatusEvent;
    procedure CreateFonts;
    procedure FreeFonts;
    procedure UpdateGrid;
    function ActivePanel: TFarPanel;
    procedure PanelBounds(AIndex: Integer; var AX0, AWidth: Integer);
    function PanelHeight: Integer;
    function FileRows: Integer;
    procedure ColumnWidths(AWidth: Integer; var AFirst, ASecond: Integer);
    function PageSize: Integer;
    procedure EnsureVisible(APanel: TFarPanel);
    function FitsMainFont(AText: PWideChar; ACount: Integer): Boolean;
    procedure FillCells(ACol, ARow, AWidth: Integer; ABack: TColor);
    procedure PutText(ACol, ARow, AWidth: Integer; const AText: WideString;
      AFore, ABack: TColor);
    procedure PutCentered(ACol, ARow, AWidth: Integer;
      const AText: WideString; AFore, ABack: TColor);
    procedure DrawPanel(AIndex: Integer);
    procedure DrawFrame(AX0, AWidth, AHeight, AFirstCol: Integer);
    procedure DrawKeyBar;
    procedure Status(const AText: string);
    function KeyName(AKey: Word; AShift, ACtrl, AAlt: Boolean): string;
    function DoKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
    procedure MoveCursor(ADelta: Integer; ASelect: Boolean);
    procedure MovePage(ADirection: Integer; ASelect: Boolean);
    procedure ToggleSelection;
    procedure EnterItem;
    procedure GoUp;
    procedure GoRoot;
    procedure ChangeDir(APanel: TFarPanel; const APath, AFocus: WideString);
    function ItemAt(AX, AY: Integer; var APanelIndex, AItemIndex: Integer): Boolean;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure DblClick; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Клавиатурное сообщение окна FAR (WM_KEYDOWN, WM_SYSKEYDOWN, WM_KEYUP,
    // WM_SYSKEYUP) из TForm1.AppMessage. True - разобрано, дальше не
    // отдавать. F1..F12 FAR забирает всегда.
    function KeyMessage(const AMsg: TMsg): Boolean;
    // Перечитать обе панели (окно открыли снова - файлы могли измениться)
    procedure RereadAll;
    procedure LoadState(const AIniName: string; const ADefaultDir: WideString);
    procedure SaveState(const AIniName: string);
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
    property OnStatus: TFarStatusEvent read FOnStatus write FOnStatus;
  end;

implementation

{$R farfont.res}  // RCDATA FAR_TER_C18B - Terminus Bold 10x18, cp1251

const
  // Палитра FAR по умолчанию (TColor - $00BBGGRR)
  FarBlue = $800000;          // B_BLUE
  FarCyan = $808000;          // B_CYAN (тёмно-бирюзовый)
  FarLightCyan = $FFFF00;     // F_LIGHTCYAN
  FarYellow = $00FFFF;        // F_YELLOW
  FarWhite = $FFFFFF;         // F_WHITE
  FarBlack = $000000;
  FarLightGray = $C0C0C0;     // F_LIGHTGRAY

  FarFontRes = 'FAR_TER_C18B';
  FarFontFile = 'ter-c18b.fnt';
  FarFontFace = 'Terminus';
  FarFallbackFace = 'Lucida Console';
  FarCellHeight = 18;
  FarCellWidth = 10;

  FarIniSection = 'Far';
  FarUtf8Prefix = 'utf8:';

  FarFrPrivate = $10;              // FR_PRIVATE
  FarNoBestFit = $400;             // WC_NO_BEST_FIT_CHARS
  FarQualityNoAntialias = 3;       // NONANTIALIASED_QUALITY
  FarVkBackslash = $DC;            // VK_OEM_5: '\'
  FarInvalidAttr = $FFFFFFFF;

  // Кейбар: подписи FAR (far\farlang.templ.m4) для того, что есть или
  // будет в unIDE FAR. Пустые - клавиша в unIDE FAR не используется.
  FarKeysNormal: array[0..11] of string = ('Help', 'UserMn', 'View', 'Edit',
    'Copy', 'RenMov', 'MkFold', 'Delete', 'ConfMn', 'Quit', '', 'Screen');
  FarKeysShift: array[0..11] of string = ('', '', '', 'Edit..', 'Copy',
    'Rename', '', 'Delete', 'Save', '', '', '');
  FarKeysAlt: array[0..11] of string = ('Left', 'Right', '', '', '', '', '',
    '', '', '', '', 'FoldHs');
  FarKeysCtrl: array[0..11] of string = ('', '', '', '', '', '', '', '', '',
    '', '', 'Sort');

type
  TFarFindData = record
    dwFileAttributes: DWORD;
    ftCreationTime: TFileTime;
    ftLastAccessTime: TFileTime;
    ftLastWriteTime: TFileTime;
    nFileSizeHigh: DWORD;
    nFileSizeLow: DWORD;
    dwReserved0: DWORD;
    dwReserved1: DWORD;
    cFileName: array[0..MAX_PATH - 1] of WideChar;
    cAlternateFileName: array[0..13] of WideChar;
  end;

  TFarInt64Ptr = ^Int64;

// W-функции Windows - свои объявления, чтобы не зависеть от того, как они
// описаны в Windows.pas Delphi 7
function FarFindFirst(AFileName: PWideChar;
  var AFindData: TFarFindData): THandle; stdcall;
  external 'kernel32.dll' name 'FindFirstFileW';
function FarFindNext(AFindHandle: THandle;
  var AFindData: TFarFindData): BOOL; stdcall;
  external 'kernel32.dll' name 'FindNextFileW';
function FarGetAttributes(AFileName: PWideChar): DWORD; stdcall;
  external 'kernel32.dll' name 'GetFileAttributesW';
function FarDiskFree(ADir: PWideChar; AFreeAvail, ATotalBytes,
  ATotalFree: TFarInt64Ptr): BOOL; stdcall;
  external 'kernel32.dll' name 'GetDiskFreeSpaceExW';
function FarCompareStr(ALocale: LCID; AFlags: DWORD; AStr1: PWideChar;
  ALen1: Integer; AStr2: PWideChar; ALen2: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'CompareStringW';
function FarWideToMulti(ACodePage: UINT; AFlags: DWORD; AWide: PWideChar;
  AWideLen: Integer; AMulti: PAnsiChar; AMultiLen: Integer;
  ADefaultChar: PAnsiChar; var AUsedDefault: BOOL): Integer; stdcall;
  external 'kernel32.dll' name 'WideCharToMultiByte';
function FarExtTextOut(ADC: HDC; AX, AY: Integer; AOptions: UINT;
  ARect: PRect; AStr: PWideChar; ACount: UINT; ADx: PInteger): BOOL; stdcall;
  external 'gdi32.dll' name 'ExtTextOutW';
function FarAddFontResourceEx(AFileName: PAnsiChar; AFlags: DWORD;
  AReserved: Pointer): Integer; stdcall;
  external 'gdi32.dll' name 'AddFontResourceExA';

var
  FarFontTried: Boolean = False;

// ---------------------------------------------------------------------------
//  Вспомогательные функции
// ---------------------------------------------------------------------------

// Шрифт Terminus - один раз за запуск: файл рядом с exe или из ресурса
// через временную папку. Подключается только для этой программы.
procedure FarRegisterFont;
var
  FontPath: string;
  TempDir: array[0..MAX_PATH] of Char;
  ResStream: TResourceStream;
  FileStream: TFileStream;
  NeedWrite: Boolean;
begin
  if FarFontTried then
    Exit;
  FarFontTried := True;

  FontPath := ExtractFilePath(Application.ExeName) + FarFontFile;
  if not FileExists(FontPath) then
  begin
    FontPath := '';
    if FindResource(HInstance, FarFontRes, RT_RCDATA) = 0 then
      Exit;
    if GetTempPath(SizeOf(TempDir), TempDir) = 0 then
      Exit;
    FontPath := IncludeTrailingPathDelimiter(TempDir) + 'unIDE_' + FarFontFile;
    ResStream := TResourceStream.Create(HInstance, FarFontRes, RT_RCDATA);
    try
      // Файл того же размера уже есть - не переписываем: его может держать
      // другой запущенный unIDE
      NeedWrite := True;
      if FileExists(FontPath) then
      begin
        try
          FileStream := TFileStream.Create(FontPath,
            fmOpenRead or fmShareDenyNone);
          try
            NeedWrite := FileStream.Size <> ResStream.Size;
          finally
            FileStream.Free;
          end;
        except
          NeedWrite := True;
        end;
      end;
      if NeedWrite then
      try
        FileStream := TFileStream.Create(FontPath, fmCreate);
        try
          FileStream.CopyFrom(ResStream, 0);
        finally
          FileStream.Free;
        end;
      except
        Exit;
      end;
    finally
      ResStream.Free;
    end;
  end;
  FarAddFontResourceEx(PAnsiChar(FontPath), FarFrPrivate, nil);
end;

function FarCompareNames(const ANameA, ANameB: WideString): Integer;
begin
  Result := FarCompareStr(LOCALE_USER_DEFAULT, NORM_IGNORECASE,
    PWideChar(ANameA), Length(ANameA), PWideChar(ANameB), Length(ANameB)) - 2;
end;

function FarDirExists(const APath: WideString): Boolean;
var
  Attr: DWORD;
begin
  Attr := FarGetAttributes(PWideChar(APath));
  Result := (Attr <> FarInvalidAttr) and
            (Attr and FILE_ATTRIBUTE_DIRECTORY <> 0);
end;

function FarWithSlash(const APath: WideString): WideString;
begin
  Result := APath;
  if (Result <> '') and (Result[Length(Result)] <> '\') then
    Result := Result + '\';
end;

// 1234567 -> '1 234 567'
function FarGroupDigits(AValue: Int64): string;
var
  Digits: string;
  Position: Integer;
begin
  Digits := IntToStr(AValue);
  Result := '';
  Position := Length(Digits);
  while Position > 3 do
  begin
    Result := ' ' + Copy(Digits, Position - 2, 3) + Result;
    Dec(Position, 3);
  end;
  Result := Copy(Digits, 1, Position) + Result;
end;

function FarFileDate(const ATime: TFileTime): string;
var
  LocalTime: TFileTime;
  SysTime: Windows.TSystemTime;
begin
  Result := '';
  if not FileTimeToLocalFileTime(ATime, LocalTime) then
    Exit;
  if not FileTimeToSystemTime(LocalTime, SysTime) then
    Exit;
  Result := Format('%.2d.%.2d.%.2d %.2d:%.2d', [SysTime.wDay, SysTime.wMonth,
    SysTime.wYear mod 100, SysTime.wHour, SysTime.wMinute]);
end;

// Имя в колонку шириной AWidth: длинное - обрезается, последняя клетка '}'
// (так в FAR)
function FarFitName(const AName: WideString; AWidth: Integer): WideString;
begin
  if AWidth <= 0 then
    Result := ''
  else if Length(AName) <= AWidth then
    Result := AName
  else
    Result := Copy(AName, 1, AWidth - 1) + '}';
end;

// Путь в заголовок шириной AWidth: длинный - '...' и конец пути
function FarFitPath(const APath: WideString; AWidth: Integer): WideString;
begin
  if AWidth <= 3 then
    Result := ''
  else if Length(APath) <= AWidth then
    Result := APath
  else
    Result := '...' + Copy(APath, Length(APath) - AWidth + 4, AWidth - 3);
end;

// Папка выше: 'D:\a\b\' -> 'D:\a\', AChildName = 'b'. У корня ('D:\',
// '\\server\share\') - ''.
function FarParentOf(const APath: WideString;
  var AChildName: WideString): WideString;
var
  Trimmed: WideString;
  SlashPos, SlashCount, CharIndex: Integer;
begin
  Result := '';
  AChildName := '';
  Trimmed := APath;
  if (Trimmed <> '') and (Trimmed[Length(Trimmed)] = '\') then
    SetLength(Trimmed, Length(Trimmed) - 1);
  SlashPos := Length(Trimmed);
  while (SlashPos > 0) and (Trimmed[SlashPos] <> '\') do
    Dec(SlashPos);
  if SlashPos < 3 then
    Exit;  // 'D:' - корень
  if Copy(Trimmed, 1, 2) = '\\' then
  begin
    // \\server\share - корень: выше него не идём
    SlashCount := 0;
    for CharIndex := 1 to Length(Trimmed) do
      if Trimmed[CharIndex] = '\' then
        Inc(SlashCount);
    if SlashCount <= 3 then
      Exit;
  end;
  AChildName := Copy(Trimmed, SlashPos + 1, MaxInt);
  Result := Copy(Trimmed, 1, SlashPos);
end;

// Корень пути: 'D:\', '\\server\share\'
function FarRootOf(const APath: WideString): WideString;
var
  ChildName, Upper: WideString;
begin
  Result := FarWithSlash(APath);
  Upper := FarParentOf(Result, ChildName);
  while Upper <> '' do
  begin
    Result := Upper;
    Upper := FarParentOf(Result, ChildName);
  end;
end;

// Путь в ini: в кодировке Windows, если она вмещает все символы, иначе
// 'utf8:' и UTF-8
function FarEncodePath(const APath: WideString): string;
var
  UsedDefault: BOOL;
  Buffer: string;
  Written: Integer;
begin
  Result := '';
  if APath = '' then
    Exit;
  SetLength(Buffer, Length(APath) * 2 + 1);
  UsedDefault := False;
  Written := FarWideToMulti(CP_ACP, FarNoBestFit, PWideChar(APath),
    Length(APath), PAnsiChar(Buffer), Length(Buffer), nil, UsedDefault);
  if (Written > 0) and not UsedDefault then
    Result := Copy(Buffer, 1, Written)
  else
    Result := FarUtf8Prefix + UTF8Encode(APath);
end;

function FarDecodePath(const AText: string): WideString;
begin
  if Copy(AText, 1, Length(FarUtf8Prefix)) = FarUtf8Prefix then
    Result := UTF8Decode(Copy(AText, Length(FarUtf8Prefix) + 1, MaxInt))
  else
    Result := AText;
end;

// ---------------------------------------------------------------------------
//  TFarPanel
// ---------------------------------------------------------------------------

function TFarPanel.ItemLess(const ItemA, ItemB: TFarItem): Boolean;
begin
  // '..' - первым, папки - перед файлами, дальше по имени без учёта регистра
  if ItemA.IsUp <> ItemB.IsUp then
    Result := ItemA.IsUp
  else if ItemA.IsDir <> ItemB.IsDir then
    Result := ItemA.IsDir
  else
    Result := FarCompareNames(ItemA.Name, ItemB.Name) < 0;
end;

procedure TFarPanel.SortItems;
var
  Gap, Outer, Inner: Integer;
  Temp: TFarItem;
begin
  // Сортировка Шелла: без рекурсии, для тысяч имён быстрая
  Gap := FCount div 2;
  while Gap > 0 do
  begin
    for Outer := Gap to FCount - 1 do
    begin
      Temp := FItems[Outer];
      Inner := Outer;
      while (Inner >= Gap) and ItemLess(Temp, FItems[Inner - Gap]) do
      begin
        FItems[Inner] := FItems[Inner - Gap];
        Dec(Inner, Gap);
      end;
      FItems[Inner] := Temp;
    end;
    Gap := Gap div 2;
  end;
end;

function TFarPanel.ReadDir(const APath, AFocusName: WideString;
  var AError: string): Boolean;
var
  NewPath, Mask: WideString;
  FindData: TFarFindData;
  FindHandle: THandle;
  FoundName: WideString;
  NewItems: TFarItems;
  NewCount, LastError, ItemIndex: Integer;
  IsRootDir: Boolean;
  FreeAvail, TotalBytes, TotalFree: Int64;
begin
  Result := False;
  AError := '';
  NewPath := FarWithSlash(APath);
  Mask := NewPath + '*';
  NewCount := 0;
  SetLength(NewItems, 64);

  IsRootDir := (Length(NewPath) = 3) and (NewPath[2] = ':');
  if not IsRootDir then
  begin
    NewItems[0].Name := '..';
    NewItems[0].IsUp := True;
    NewItems[0].IsDir := True;
    NewItems[0].Size := 0;
    NewItems[0].Attr := FILE_ATTRIBUTE_DIRECTORY;
    NewItems[0].Selected := False;
    FillChar(NewItems[0].WriteTime, SizeOf(TFileTime), 0);
    NewCount := 1;
  end;

  FindHandle := FarFindFirst(PWideChar(Mask), FindData);
  if FindHandle = INVALID_HANDLE_VALUE then
  begin
    LastError := GetLastError;
    if (LastError <> ERROR_FILE_NOT_FOUND) and
       (LastError <> ERROR_NO_MORE_FILES) then
    begin
      AError := SysErrorMessage(LastError);
      Exit;
    end;
  end
  else
  try
    repeat
      FoundName := PWideChar(@FindData.cFileName[0]);
      if (FoundName <> '.') and (FoundName <> '..') then
      begin
        if NewCount >= Length(NewItems) then
          SetLength(NewItems, Length(NewItems) * 2);
        NewItems[NewCount].Name := FoundName;
        NewItems[NewCount].Attr := FindData.dwFileAttributes;
        NewItems[NewCount].IsDir :=
          FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0;
        NewItems[NewCount].IsUp := False;
        NewItems[NewCount].Selected := False;
        NewItems[NewCount].WriteTime := FindData.ftLastWriteTime;
        if NewItems[NewCount].IsDir then
          NewItems[NewCount].Size := 0
        else
          NewItems[NewCount].Size := Int64(FindData.nFileSizeHigh) shl 32 +
                                     FindData.nFileSizeLow;
        Inc(NewCount);
      end;
    until not FarFindNext(FindHandle, FindData);
  finally
    Windows.FindClose(FindHandle);
  end;

  FPath := NewPath;
  FItems := NewItems;
  FCount := NewCount;
  SortItems;

  FFileCount := 0;
  FFileBytes := 0;
  for ItemIndex := 0 to FCount - 1 do
    if not FItems[ItemIndex].IsDir then
    begin
      Inc(FFileCount);
      Inc(FFileBytes, FItems[ItemIndex].Size);
    end;

  FFreeKnown := FarDiskFree(PWideChar(FPath), @FreeAvail, @TotalBytes,
    @TotalFree);
  if FFreeKnown then
    FFreeBytes := FreeAvail;

  FCursor := 0;
  FTopIndex := 0;
  if AFocusName <> '' then
  begin
    FCursor := IndexOfName(AFocusName);
    if FCursor < 0 then
      FCursor := 0;
  end;
  Result := True;
end;

procedure TFarPanel.Reread;
var
  FocusName: WideString;
  SelectedNames: array of WideString;
  SelectedCount, ItemIndex, NameIndex, OldTop: Integer;
  ErrorText: string;
begin
  if FPath = '' then
    Exit;
  FocusName := '';
  if (FCursor >= 0) and (FCursor < FCount) then
    FocusName := FItems[FCursor].Name;
  SelectedCount := 0;
  SetLength(SelectedNames, SelCount);
  for ItemIndex := 0 to FCount - 1 do
    if FItems[ItemIndex].Selected then
    begin
      SelectedNames[SelectedCount] := FItems[ItemIndex].Name;
      Inc(SelectedCount);
    end;
  OldTop := FTopIndex;
  if not ReadDir(FPath, FocusName, ErrorText) then
    Exit;
  FTopIndex := OldTop;
  for NameIndex := 0 to SelectedCount - 1 do
  begin
    ItemIndex := IndexOfName(SelectedNames[NameIndex]);
    if ItemIndex >= 0 then
      SetSelected(ItemIndex, True);
  end;
end;

function TFarPanel.IndexOfName(const AName: WideString): Integer;
var
  ItemIndex: Integer;
begin
  Result := -1;
  for ItemIndex := 0 to FCount - 1 do
    if FarCompareNames(FItems[ItemIndex].Name, AName) = 0 then
    begin
      Result := ItemIndex;
      Exit;
    end;
end;

function TFarPanel.SelCount: Integer;
var
  ItemIndex: Integer;
begin
  Result := 0;
  for ItemIndex := 0 to FCount - 1 do
    if FItems[ItemIndex].Selected then
      Inc(Result);
end;

function TFarPanel.SelBytes: Int64;
var
  ItemIndex: Integer;
begin
  Result := 0;
  for ItemIndex := 0 to FCount - 1 do
    if FItems[ItemIndex].Selected then
      Inc(Result, FItems[ItemIndex].Size);
end;

procedure TFarPanel.SetSelected(AIndex: Integer; AValue: Boolean);
begin
  if (AIndex < 0) or (AIndex >= FCount) or FItems[AIndex].IsUp then
    Exit;
  FItems[AIndex].Selected := AValue;
end;

function TFarPanel.IsRoot: Boolean;
var
  ChildName: WideString;
begin
  Result := ParentPath(ChildName) = '';
end;

function TFarPanel.ParentPath(var AChildName: WideString): WideString;
begin
  Result := FarParentOf(FPath, AChildName);
end;

// ---------------------------------------------------------------------------
//  TFarView
// ---------------------------------------------------------------------------

constructor TFarView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  TabStop := True;
  Color := FarBlue;
  FPanels[0] := TFarPanel.Create;
  FPanels[1] := TFarPanel.Create;
  FActive := 0;
  FBuffer := TBitmap.Create;
  CreateFonts;
end;

destructor TFarView.Destroy;
begin
  FreeFonts;
  FBuffer.Free;
  FPanels[0].Free;
  FPanels[1].Free;
  inherited Destroy;
end;

procedure TFarView.CreateFonts;
var
  ScreenDC: HDC;
  OldFont: HFONT;
  Metrics: TTextMetric;
  FaceBuffer: array[0..63] of Char;
begin
  FarRegisterFont;
  FFontMain := CreateFont(FarCellHeight, FarCellWidth, 0, 0, FW_BOLD, 0, 0, 0,
    RUSSIAN_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
    FIXED_PITCH or FF_MODERN, FarFontFace);
  ScreenDC := GetDC(0);
  try
    OldFont := SelectObject(ScreenDC, FFontMain);
    FaceBuffer[0] := #0;
    GetTextFace(ScreenDC, SizeOf(FaceBuffer), FaceBuffer);
    GetTextMetrics(ScreenDC, Metrics);
    SelectObject(ScreenDC, OldFont);
    FFontIsTerminus := (CompareText(FaceBuffer, FarFontFace) = 0) and
                       (Metrics.tmHeight = FarCellHeight) and
                       (Metrics.tmAveCharWidth = FarCellWidth);
    if not FFontIsTerminus then
    begin
      DeleteObject(FFontMain);
      FFontMain := CreateFont(FarCellHeight, 0, 0, 0, FW_NORMAL, 0, 0, 0,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        FarQualityNoAntialias, FIXED_PITCH or FF_MODERN, FarFallbackFace);
      OldFont := SelectObject(ScreenDC, FFontMain);
      GetTextMetrics(ScreenDC, Metrics);
      SelectObject(ScreenDC, OldFont);
    end;
  finally
    ReleaseDC(0, ScreenDC);
  end;

  FCellH := Metrics.tmHeight;
  FCellW := Metrics.tmAveCharWidth;
  if FCellH < 8 then
    FCellH := FarCellHeight;
  if FCellW < 4 then
    FCellW := FarCellWidth;
  FTextTop := 0;

  // Символы вне cp1251 - Lucida Console в ту же клетку
  if FFontIsTerminus then
    FFontAlt := CreateFont(FCellH, FCellW, 0, 0, FW_NORMAL, 0, 0, 0,
      DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
      FarQualityNoAntialias, FIXED_PITCH or FF_MODERN, FarFallbackFace)
  else
    FFontAlt := 0;
end;

procedure TFarView.FreeFonts;
begin
  if FFontMain <> 0 then
    DeleteObject(FFontMain);
  if FFontAlt <> 0 then
    DeleteObject(FFontAlt);
  FFontMain := 0;
  FFontAlt := 0;
end;

procedure TFarView.UpdateGrid;
begin
  FCols := ClientWidth div FCellW;
  FRows := ClientHeight div FCellH;
  EnsureVisible(FPanels[0]);
  EnsureVisible(FPanels[1]);
end;

function TFarView.ActivePanel: TFarPanel;
begin
  Result := FPanels[FActive];
end;

procedure TFarView.PanelBounds(AIndex: Integer; var AX0, AWidth: Integer);
begin
  if AIndex = 0 then
  begin
    AX0 := 0;
    AWidth := FCols div 2;
  end
  else
  begin
    AX0 := FCols div 2;
    AWidth := FCols - FCols div 2;
  end;
end;

// Строк у панели: всё окно без нижней строки (кейбар)
function TFarView.PanelHeight: Integer;
begin
  Result := FRows - 1;
end;

// Строки имён: рамка сверху, заголовок колонок, (имена), разделитель,
// строка о файле, рамка снизу
function TFarView.FileRows: Integer;
begin
  Result := PanelHeight - 5;
  if Result < 1 then
    Result := 1;
end;

procedure TFarView.ColumnWidths(AWidth: Integer; var AFirst, ASecond: Integer);
var
  Inner: Integer;
begin
  Inner := AWidth - 2;            // без рамки слева и справа
  AFirst := (Inner - 1) div 2;    // одна клетка - разделитель колонок
  ASecond := Inner - 1 - AFirst;
  if AFirst < 0 then
    AFirst := 0;
  if ASecond < 0 then
    ASecond := 0;
end;

// Имён на экране панели (две колонки)
function TFarView.PageSize: Integer;
begin
  Result := FileRows * 2;
end;

procedure TFarView.EnsureVisible(APanel: TFarPanel);
var
  Capacity, MaxTop: Integer;
begin
  if APanel.Count = 0 then
  begin
    APanel.Cursor := 0;
    APanel.TopIndex := 0;
    Exit;
  end;
  if APanel.Cursor >= APanel.Count then
    APanel.Cursor := APanel.Count - 1;
  if APanel.Cursor < 0 then
    APanel.Cursor := 0;
  Capacity := PageSize;
  if APanel.Cursor < APanel.TopIndex then
    APanel.TopIndex := APanel.Cursor;
  if APanel.Cursor >= APanel.TopIndex + Capacity then
    APanel.TopIndex := APanel.Cursor - Capacity + 1;
  MaxTop := APanel.Count - Capacity;
  if MaxTop < 0 then
    MaxTop := 0;
  if APanel.TopIndex > MaxTop then
    APanel.TopIndex := MaxTop;
  if APanel.TopIndex < 0 then
    APanel.TopIndex := 0;
end;

// ---------------------------------------------------------------------------
//  Рисование
// ---------------------------------------------------------------------------

function TFarView.FitsMainFont(AText: PWideChar; ACount: Integer): Boolean;
var
  UsedDefault: BOOL;
  Buffer: array[0..255] of AnsiChar;
  Chunk: Integer;
begin
  Result := True;
  if FFontAlt = 0 then
    Exit;  // не Terminus: Lucida Console рисует всё сама
  while ACount > 0 do
  begin
    Chunk := ACount;
    if Chunk > 120 then
      Chunk := 120;
    UsedDefault := False;
    FarWideToMulti(1251, FarNoBestFit, AText, Chunk, Buffer, SizeOf(Buffer),
      nil, UsedDefault);
    if UsedDefault then
    begin
      Result := False;
      Exit;
    end;
    Inc(AText, Chunk);
    Dec(ACount, Chunk);
  end;
end;

procedure TFarView.FillCells(ACol, ARow, AWidth: Integer; ABack: TColor);
begin
  if AWidth <= 0 then
    Exit;
  FBuffer.Canvas.Brush.Style := bsSolid;
  FBuffer.Canvas.Brush.Color := ABack;
  FBuffer.Canvas.FillRect(Rect(ACol * FCellW, ARow * FCellH,
    (ACol + AWidth) * FCellW, (ARow + 1) * FCellH));
end;

procedure TFarView.PutText(ACol, ARow, AWidth: Integer;
  const AText: WideString; AFore, ABack: TColor);
var
  DrawDC: HDC;
  CharCount, CharIndex, StepIndex: Integer;
  CharPtr: PWideChar;
begin
  FillCells(ACol, ARow, AWidth, ABack);
  CharCount := Length(AText);
  if CharCount > AWidth then
    CharCount := AWidth;
  if CharCount <= 0 then
    Exit;
  if Length(FDx) < CharCount then
  begin
    SetLength(FDx, CharCount + 64);
    for StepIndex := 0 to High(FDx) do
      FDx[StepIndex] := FCellW;
  end;
  DrawDC := FBuffer.Canvas.Handle;
  SetBkMode(DrawDC, TRANSPARENT);
  SetTextAlign(DrawDC, TA_LEFT or TA_TOP);
  SetTextColor(DrawDC, ColorToRGB(AFore));
  CharPtr := PWideChar(AText);
  if FitsMainFont(CharPtr, CharCount) then
  begin
    SelectObject(DrawDC, FFontMain);
    FarExtTextOut(DrawDC, ACol * FCellW, ARow * FCellH + FTextTop, 0, nil,
      CharPtr, CharCount, @FDx[0]);
  end
  else
    for CharIndex := 0 to CharCount - 1 do
    begin
      if FitsMainFont(CharPtr, 1) then
        SelectObject(DrawDC, FFontMain)
      else
        SelectObject(DrawDC, FFontAlt);
      FarExtTextOut(DrawDC, (ACol + CharIndex) * FCellW,
        ARow * FCellH + FTextTop, 0, nil, CharPtr, 1, @FDx[0]);
      Inc(CharPtr);
    end;
end;

procedure TFarView.PutCentered(ACol, ARow, AWidth: Integer;
  const AText: WideString; AFore, ABack: TColor);
var
  TextLen: Integer;
begin
  TextLen := Length(AText);
  if TextLen > AWidth then
    TextLen := AWidth;
  if TextLen <= 0 then
    Exit;
  PutText(ACol + (AWidth - TextLen) div 2, ARow, TextLen, AText, AFore, ABack);
end;

// Двойная рамка панели, разделитель над строкой о файле и линия между
// колонками - линиями (в cp1251 нет псевдографики)
procedure TFarView.DrawFrame(AX0, AWidth, AHeight, AFirstCol: Integer);
var
  LeftX, RightX, TopY, BottomY, SepY, ColX: Integer;
begin
  LeftX := AX0 * FCellW + FCellW div 2;
  RightX := (AX0 + AWidth - 1) * FCellW + FCellW div 2;
  TopY := FCellH div 2;
  BottomY := (AHeight - 1) * FCellH + FCellH div 2;
  SepY := (AHeight - 3) * FCellH + FCellH div 2;
  ColX := (AX0 + 1 + AFirstCol) * FCellW + FCellW div 2;

  with FBuffer.Canvas do
  begin
    Pen.Style := psSolid;
    Pen.Width := 1;
    Pen.Color := FarLightCyan;
    Brush.Style := bsClear;
    Rectangle(LeftX - 1, TopY - 1, RightX + 2, BottomY + 2);
    Rectangle(LeftX + 1, TopY + 1, RightX, BottomY);
    Brush.Style := bsSolid;
    MoveTo(LeftX + 1, SepY);
    LineTo(RightX, SepY);
    MoveTo(ColX, TopY + 1);
    LineTo(ColX, SepY);
  end;
end;

procedure TFarView.DrawPanel(AIndex: Integer);
var
  Panel: TFarPanel;
  PanelX, PanelW, PanelH, FirstW, SecondW, Rows: Integer;
  ColumnIndex, RowIndex, ItemIndex, ColX, ColW, InnerW, NameW: Integer;
  Fore, Back: TColor;
  IsActive: Boolean;
  Title, ItemName, RightText, Totals, FreeText, SelText: WideString;
  TotalsLen, StartCol: Integer;
begin
  Panel := FPanels[AIndex];
  PanelBounds(AIndex, PanelX, PanelW);
  PanelH := PanelHeight;
  FillCells(PanelX, 0, PanelW, FarBlue);
  for RowIndex := 1 to PanelH - 1 do
    FillCells(PanelX, RowIndex, PanelW, FarBlue);
  if (PanelW < 8) or (PanelH < 7) then
    Exit;

  IsActive := AIndex = FActive;
  ColumnWidths(PanelW, FirstW, SecondW);
  Rows := FileRows;
  InnerW := PanelW - 2;

  // Заголовки колонок
  PutCentered(PanelX + 1, 1, FirstW, 'Name', FarYellow, FarBlue);
  PutCentered(PanelX + 2 + FirstW, 1, SecondW, 'Name', FarYellow, FarBlue);

  // Имена: колонка за колонкой, сверху вниз
  for ColumnIndex := 0 to 1 do
  begin
    if ColumnIndex = 0 then
    begin
      ColX := PanelX + 1;
      ColW := FirstW;
    end
    else
    begin
      ColX := PanelX + 2 + FirstW;
      ColW := SecondW;
    end;
    for RowIndex := 0 to Rows - 1 do
    begin
      ItemIndex := Panel.TopIndex + ColumnIndex * Rows + RowIndex;
      if ItemIndex >= Panel.Count then
        Break;
      with Panel.FItems[ItemIndex] do
      begin
        if Selected then
          Fore := FarYellow
        else if IsDir then
          Fore := FarWhite
        else
          Fore := FarLightCyan;
        Back := FarBlue;
        if IsActive and (ItemIndex = Panel.Cursor) then
        begin
          Back := FarCyan;
          if not Selected then
            Fore := FarBlack;
        end;
        PutText(ColX, 2 + RowIndex, ColW, FarFitName(Name, ColW), Fore, Back);
      end;
    end;
  end;

  // Строка о файле под курсором
  if (Panel.Cursor >= 0) and (Panel.Cursor < Panel.Count) then
    with Panel.FItems[Panel.Cursor] do
    begin
      if IsUp then
        RightText := 'Up'
      else if IsDir then
        RightText := 'Folder'
      else
        RightText := IntToStr(Size) + ' ' + FarFileDate(WriteTime);
      if Length(RightText) > InnerW then
        RightText := '';
      NameW := InnerW - Length(RightText) - 1;
      if IsUp then
        ItemName := '..'
      else
        ItemName := Name;
      PutText(PanelX + 1, PanelH - 2, NameW, FarFitName(ItemName, NameW),
        FarLightCyan, FarBlue);
      PutText(PanelX + 1 + InnerW - Length(RightText), PanelH - 2,
        Length(RightText), RightText, FarLightCyan, FarBlue);
    end;

  DrawFrame(PanelX, PanelW, PanelH, FirstW);

  // Заголовок - путь; у активной панели - цветом курсора
  Title := Panel.Path;
  if (Length(Title) > 3) and (Title[Length(Title)] = '\') then
    SetLength(Title, Length(Title) - 1);
  Title := ' ' + FarFitPath(Title, PanelW - 6) + ' ';
  if IsActive then
    PutCentered(PanelX, 0, PanelW, Title, FarBlack, FarCyan)
  else
    PutCentered(PanelX, 0, PanelW, Title, FarLightCyan, FarBlue);

  // Выделенные - на разделителе
  if Panel.SelCount > 0 then
  begin
    SelText := ' ' + FarGroupDigits(Panel.SelBytes) + ' bytes in ' +
      IntToStr(Panel.SelCount) + ' files ';
    PutCentered(PanelX + 1, PanelH - 3, InnerW, SelText, FarYellow, FarCyan);
  end;

  // Внизу: байты в файлах (число файлов) и свободно на диске
  Totals := ' ' + FarGroupDigits(Panel.FFileBytes) + ' (' +
    IntToStr(Panel.FFileCount) + ') ';
  if Panel.FFreeKnown then
    FreeText := ' ' + FarGroupDigits(Panel.FFreeBytes) + ' '
  else
    FreeText := '';
  TotalsLen := Length(Totals);
  if FreeText <> '' then
    Inc(TotalsLen, Length(FreeText) + 2);
  if TotalsLen > InnerW then
  begin
    FreeText := '';
    TotalsLen := Length(Totals);
  end;
  if TotalsLen <= InnerW then
  begin
    StartCol := PanelX + (PanelW - TotalsLen) div 2;
    PutText(StartCol, PanelH - 1, Length(Totals), Totals,
      FarLightCyan, FarBlue);
    if FreeText <> '' then
      PutText(StartCol + Length(Totals) + 2, PanelH - 1, Length(FreeText),
        FreeText, FarLightCyan, FarBlue);
  end;
end;

procedure TFarView.DrawKeyBar;
var
  KeyIndex, SlotW, SlotCol, LabelW: Integer;
  Number, KeyLabel: string;
  AltDown, CtrlDown, ShiftDown: Boolean;
begin
  if FRows < 1 then
    Exit;
  AltDown := GetKeyState(VK_MENU) < 0;
  CtrlDown := GetKeyState(VK_CONTROL) < 0;
  ShiftDown := GetKeyState(VK_SHIFT) < 0;
  FillCells(0, FRows - 1, FCols, FarBlack);
  SlotW := FCols div 12;
  if SlotW < 3 then
    Exit;
  for KeyIndex := 0 to 11 do
  begin
    SlotCol := KeyIndex * SlotW;
    if AltDown then
      KeyLabel := FarKeysAlt[KeyIndex]
    else if CtrlDown then
      KeyLabel := FarKeysCtrl[KeyIndex]
    else if ShiftDown then
      KeyLabel := FarKeysShift[KeyIndex]
    else
      KeyLabel := FarKeysNormal[KeyIndex];
    Number := IntToStr(KeyIndex + 1);
    LabelW := SlotW - Length(Number);
    if KeyIndex = 11 then
      LabelW := FCols - SlotCol - Length(Number);
    PutText(SlotCol, FRows - 1, Length(Number), Number, FarLightGray,
      FarBlack);
    PutText(SlotCol + Length(Number), FRows - 1, LabelW, KeyLabel, FarBlack,
      FarCyan);
  end;
end;

procedure TFarView.Paint;
var
  OldFont: HFONT;
begin
  if (FBuffer.Width <> ClientWidth) or (FBuffer.Height <> ClientHeight) then
  begin
    FBuffer.Width := ClientWidth;
    FBuffer.Height := ClientHeight;
  end;
  if (FCols <> ClientWidth div FCellW) or (FRows <> ClientHeight div FCellH) then
    UpdateGrid;
  OldFont := SelectObject(FBuffer.Canvas.Handle, FFontMain);
  try
    FBuffer.Canvas.Brush.Style := bsSolid;
    FBuffer.Canvas.Brush.Color := FarBlack;
    FBuffer.Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));
    if (FCols >= 20) and (FRows >= 8) then
    begin
      DrawPanel(0);
      DrawPanel(1);
      DrawKeyBar;
    end;
  finally
    SelectObject(FBuffer.Canvas.Handle, OldFont);
  end;
  Canvas.Draw(0, 0, FBuffer);
end;

procedure TFarView.Resize;
begin
  inherited Resize;
  UpdateGrid;
  Invalidate;
end;

procedure TFarView.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TFarView.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTCHARS or
                    DLGC_WANTALLKEYS;
end;

procedure TFarView.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  Invalidate;
end;

procedure TFarView.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  FShiftSelActive := False;
  Invalidate;
end;

// ---------------------------------------------------------------------------
//  Мышь
// ---------------------------------------------------------------------------

function TFarView.ItemAt(AX, AY: Integer;
  var APanelIndex, AItemIndex: Integer): Boolean;
var
  Col, Row, PanelX, PanelW, FirstW, SecondW, Column: Integer;
begin
  Result := False;
  AItemIndex := -1;
  Col := AX div FCellW;
  Row := AY div FCellH;
  if Col < FCols div 2 then
    APanelIndex := 0
  else
    APanelIndex := 1;
  PanelBounds(APanelIndex, PanelX, PanelW);
  ColumnWidths(PanelW, FirstW, SecondW);
  if (Row < 2) or (Row >= 2 + FileRows) then
    Exit;
  if (Col > PanelX) and (Col <= PanelX + FirstW) then
    Column := 0
  else if (Col > PanelX + 1 + FirstW) and (Col < PanelX + PanelW - 1) then
    Column := 1
  else
    Exit;
  AItemIndex := FPanels[APanelIndex].TopIndex + Column * FileRows + Row - 2;
  Result := AItemIndex < FPanels[APanelIndex].Count;
end;

procedure TFarView.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  PanelIndex, ItemIndex: Integer;
  HasItem: Boolean;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if CanFocus and not Focused then
    SetFocus;
  HasItem := ItemAt(X, Y, PanelIndex, ItemIndex);
  FActive := PanelIndex;
  if HasItem then
  begin
    FPanels[PanelIndex].Cursor := ItemIndex;
    // Правая кнопка - выделить / снять, как в FAR
    if Button = mbRight then
      FPanels[PanelIndex].SetSelected(ItemIndex,
        not FPanels[PanelIndex].FItems[ItemIndex].Selected);
  end;
  Invalidate;
end;

procedure TFarView.DblClick;
var
  PanelIndex, ItemIndex: Integer;
  CursorPos: TPoint;
begin
  inherited DblClick;
  CursorPos := ScreenToClient(Mouse.CursorPos);
  if ItemAt(CursorPos.X, CursorPos.Y, PanelIndex, ItemIndex) then
    EnterItem;
end;

procedure TFarView.WMMouseWheel(var Message: TWMMouseWheel);
begin
  if Message.WheelDelta > 0 then
    MoveCursor(-1, False)
  else if Message.WheelDelta < 0 then
    MoveCursor(1, False);
  Message.Result := 1;
end;

// ---------------------------------------------------------------------------
//  Клавиши
// ---------------------------------------------------------------------------

procedure TFarView.Status(const AText: string);
begin
  if Assigned(FOnStatus) then
    FOnStatus(AText);
end;

function TFarView.KeyName(AKey: Word; AShift, ACtrl, AAlt: Boolean): string;
begin
  Result := '';
  if ACtrl then
    Result := Result + 'Ctrl+';
  if AAlt then
    Result := Result + 'Alt+';
  if AShift then
    Result := Result + 'Shift+';
  if (AKey >= VK_F1) and (AKey <= VK_F12) then
    Result := Result + 'F' + IntToStr(AKey - VK_F1 + 1)
  else
    Result := Result + '#' + IntToStr(AKey);
end;

function TFarView.KeyMessage(const AMsg: TMsg): Boolean;
var
  KeyCode: Word;
  ShiftDown, CtrlDown, AltDown: Boolean;
begin
  Result := False;
  KeyCode := Word(AMsg.wParam);

  if (AMsg.message = WM_KEYUP) or (AMsg.message = WM_SYSKEYUP) then
  begin
    if KeyCode = VK_SHIFT then
      FShiftSelActive := False;
    if (KeyCode = VK_SHIFT) or (KeyCode = VK_CONTROL) or (KeyCode = VK_MENU) then
      Invalidate;  // слой кейбара
    // Отпускание Alt после Alt+F1 и т.п.: иначе Windows откроет меню IDE -
    // нажатие F1 до неё не дошло, и Alt выглядит нажатым отдельно
    if (AMsg.message = WM_SYSKEYUP) and (KeyCode = VK_MENU) and FEatAltUp then
    begin
      FEatAltUp := False;
      Result := True;
    end;
    Exit;
  end;

  if (AMsg.message <> WM_KEYDOWN) and (AMsg.message <> WM_SYSKEYDOWN) then
    Exit;

  if (KeyCode = VK_SHIFT) or (KeyCode = VK_CONTROL) or (KeyCode = VK_MENU) then
  begin
    if KeyCode = VK_MENU then
      FEatAltUp := False;
    Invalidate;  // слой кейбара
    Exit;
  end;

  ShiftDown := GetKeyState(VK_SHIFT) < 0;
  CtrlDown := GetKeyState(VK_CONTROL) < 0;
  AltDown := GetKeyState(VK_MENU) < 0;

  Result := DoKey(KeyCode, ShiftDown, CtrlDown, AltDown);
  // F-клавиши FAR не отдаёт никому: ни отладчику, ни ярлыкам меню
  if (KeyCode >= VK_F1) and (KeyCode <= VK_F12) then
    Result := True;
  if Result and AltDown then
    FEatAltUp := True;
end;

function TFarView.DoKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
var
  Plain: Boolean;
begin
  Result := True;
  Plain := not ACtrl and not AAlt;

  // F-клавиши
  if (AKey >= VK_F1) and (AKey <= VK_F12) then
  begin
    if (AKey = VK_F10) and Plain and not AShift then
    begin
      if Assigned(FOnClose) then
        FOnClose(Self);
      Exit;
    end;
    if Plain and not AShift and ((AKey = VK_F1) or (AKey = VK_F2) or
       (AKey = VK_F3) or (AKey = VK_F12)) then
      Status('unIDE FAR: ' + KeyName(AKey, AShift, ACtrl, AAlt) +
        ' - заглушка')
    else
      Status('unIDE FAR ' + FarBuild + ': ' +
        KeyName(AKey, AShift, ACtrl, AAlt) + ' - ещё не сделано');
    Exit;
  end;

  if Plain then
    case AKey of
      VK_UP:
        MoveCursor(-1, AShift);
      VK_DOWN:
        MoveCursor(1, AShift);
      VK_LEFT:
        MoveCursor(-FileRows, AShift);
      VK_RIGHT:
        MoveCursor(FileRows, AShift);
      VK_PRIOR:
        MovePage(-1, AShift);
      VK_NEXT:
        MovePage(1, AShift);
      VK_HOME:
        MoveCursor(-ActivePanel.Count, AShift);
      VK_END:
        MoveCursor(ActivePanel.Count, AShift);
      VK_TAB:
        begin
          FActive := 1 - FActive;
          Invalidate;
        end;
      VK_RETURN:
        if not AShift then
          EnterItem
        else
          Result := False;
      VK_INSERT:
        if not AShift then
          ToggleSelection
        else
          Result := False;
    else
      Result := False;
    end
  else if ACtrl and not AAlt and not AShift then
    case AKey of
      VK_PRIOR:
        GoUp;
      VK_NEXT:
        EnterItem;
      FarVkBackslash:
        GoRoot;
      Ord('R'):
        begin
          ActivePanel.Reread;
          EnsureVisible(ActivePanel);
          Invalidate;
        end;
    else
      Result := False;
    end
  else
    Result := False;
end;

procedure TFarView.MoveCursor(ADelta: Integer; ASelect: Boolean);
var
  Panel: TFarPanel;
  Target, Step: Integer;
begin
  Panel := ActivePanel;
  if Panel.Count = 0 then
    Exit;
  Target := Panel.Cursor + ADelta;
  if Target < 0 then
    Target := 0;
  if Target >= Panel.Count then
    Target := Panel.Count - 1;
  if ASelect then
  begin
    // Первое движение с Shift задаёт, выделять или снимать: обратное
    // состоянию строки, с которой начали (так в FAR)
    if not FShiftSelActive then
    begin
      FShiftSelValue := not Panel.FItems[Panel.Cursor].Selected;
      FShiftSelActive := True;
    end;
    if ADelta > 0 then
      Step := 1
    else
      Step := -1;
    if Panel.Cursor = Target then
      Panel.SetSelected(Panel.Cursor, FShiftSelValue)  // на краю списка
    else
      while Panel.Cursor <> Target do
      begin
        Panel.SetSelected(Panel.Cursor, FShiftSelValue);
        Panel.Cursor := Panel.Cursor + Step;
      end;
  end
  else
    Panel.Cursor := Target;
  EnsureVisible(Panel);
  Invalidate;
end;

// PgUp / PgDn: курсор и первая строка сдвигаются на экран без одной строки,
// как в FAR (FileList::ProcessKey, KEY_PGDN)
procedure TFarView.MovePage(ADirection: Integer; ASelect: Boolean);
var
  Panel: TFarPanel;
  Step: Integer;
begin
  Panel := ActivePanel;
  if Panel.Count = 0 then
    Exit;
  Step := PageSize - 1;
  if Step < 1 then
    Step := 1;
  if not ASelect then
    Panel.TopIndex := Panel.TopIndex + ADirection * Step;
  MoveCursor(ADirection * Step, ASelect);
end;

procedure TFarView.ToggleSelection;
var
  Panel: TFarPanel;
begin
  Panel := ActivePanel;
  if Panel.Count = 0 then
    Exit;
  Panel.SetSelected(Panel.Cursor, not Panel.FItems[Panel.Cursor].Selected);
  MoveCursor(1, False);
end;

procedure TFarView.ChangeDir(APanel: TFarPanel; const APath,
  AFocus: WideString);
var
  ErrorText: string;
begin
  if not APanel.ReadDir(APath, AFocus, ErrorText) then
  begin
    Status('unIDE FAR: папку не открыть: ' + ErrorText);
    Exit;
  end;
  EnsureVisible(APanel);
  Invalidate;
end;

procedure TFarView.EnterItem;
var
  Panel: TFarPanel;
begin
  Panel := ActivePanel;
  if (Panel.Count = 0) or (Panel.Cursor >= Panel.Count) then
    Exit;
  with Panel.FItems[Panel.Cursor] do
    if IsUp then
      GoUp
    else if IsDir then
      ChangeDir(Panel, Panel.Path + Name + '\', '');
end;

procedure TFarView.GoUp;
var
  Panel: TFarPanel;
  ParentDir, ChildName: WideString;
begin
  Panel := ActivePanel;
  ParentDir := Panel.ParentPath(ChildName);
  if ParentDir <> '' then
    ChangeDir(Panel, ParentDir, ChildName);
end;

procedure TFarView.GoRoot;
var
  Panel: TFarPanel;
begin
  Panel := ActivePanel;
  if Panel.Path <> '' then
    ChangeDir(Panel, FarRootOf(Panel.Path), '');
end;

procedure TFarView.RereadAll;
begin
  FPanels[0].Reread;
  FPanels[1].Reread;
  EnsureVisible(FPanels[0]);
  EnsureVisible(FPanels[1]);
  Invalidate;
end;

// ---------------------------------------------------------------------------
//  Состояние в editor.ini, раздел [Far]
// ---------------------------------------------------------------------------

procedure TFarView.LoadState(const AIniName: string;
  const ADefaultDir: WideString);
const
  PathKeys: array[0..1] of string = ('LeftPath', 'RightPath');
  FileKeys: array[0..1] of string = ('LeftFile', 'RightFile');
var
  Ini: TBufIniFile;
  PanelIndex: Integer;
  SavedPath, SavedFile, ChildName: WideString;
  ErrorText: string;
begin
  Ini := TBufIniFile.Create(AIniName);
  try
    for PanelIndex := 0 to 1 do
    begin
      SavedPath := FarDecodePath(Ini.ReadString(FarIniSection,
        PathKeys[PanelIndex], ''));
      SavedFile := FarDecodePath(Ini.ReadString(FarIniSection,
        FileKeys[PanelIndex], ''));
      // Папки нет - ближайшая существующая выше
      while (SavedPath <> '') and not FarDirExists(SavedPath) do
      begin
        SavedPath := FarParentOf(FarWithSlash(SavedPath), ChildName);
        SavedFile := '';
      end;
      if SavedPath = '' then
        SavedPath := ADefaultDir;
      if not FPanels[PanelIndex].ReadDir(SavedPath, SavedFile, ErrorText) then
        FPanels[PanelIndex].ReadDir(ADefaultDir, '', ErrorText);
    end;
    FActive := Ini.ReadInteger(FarIniSection, 'Active', 0);
    if (FActive < 0) or (FActive > 1) then
      FActive := 0;
  finally
    Ini.Free;
  end;
  UpdateGrid;
  Invalidate;
end;

procedure TFarView.SaveState(const AIniName: string);
const
  PathKeys: array[0..1] of string = ('LeftPath', 'RightPath');
  FileKeys: array[0..1] of string = ('LeftFile', 'RightFile');
var
  Ini: TBufIniFile;
  PanelIndex: Integer;
  CurrentName: WideString;
begin
  Ini := TBufIniFile.Create(AIniName);
  try
    for PanelIndex := 0 to 1 do
    begin
      Ini.WriteString(FarIniSection, PathKeys[PanelIndex],
        FarEncodePath(FPanels[PanelIndex].Path));
      CurrentName := '';
      with FPanels[PanelIndex] do
        if (Cursor >= 0) and (Cursor < Count) and not FItems[Cursor].IsUp then
          CurrentName := FItems[Cursor].Name;
      Ini.WriteString(FarIniSection, FileKeys[PanelIndex],
        FarEncodePath(CurrentName));
    end;
    Ini.WriteInteger(FarIniSection, 'Active', FActive);
  finally
    Ini.Free;
  end;
end;

end.
