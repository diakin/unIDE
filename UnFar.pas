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
//    - пути панелей и файл под курсором - в editor.ini, раздел [Far];
//    - b.2: F5 / Shift+F5 - копирование, F6 / Shift+F6 - перенос и
//      переименование, F7 - папка, F8 / Shift+F8 / Del - удаление в
//      корзину, Shift+Del - удаление мимо корзины. Диалоги - свои, в
//      духе FAR, поверх панелей; сами операции - SHFileOperationW
//      (ход и вопросы о замене файлов - стандартные окна Windows);
//    - b.2: панели следят за своими папками (FindFirstChangeNotification)
//      и перечитываются сами, когда в папке что-то изменилось;
//    - b.3: Alt+F1 / Alt+F2 - смена диска левой / правой панели (другая
//      панель на этом диске - в её папку, иначе - в последнюю папку на
//      диске; активная панель не меняется); Ctrl+F12 - меню
//      сортировки, Ctrl+F3 .. Ctrl+F9 - сортировка сразу (повтор -
//      обратный порядок), Shift+F12 - выделенные первыми; буква
//      сортировки - в левом верхнем углу панели; Alt+F12 - история папок
//      (Del - убрать папку из истории). Сортировка панелей, история и
//      последние папки дисков - в editor.ini ([Far], [FarHistory]).
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
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls,
  Clipbrd, IniBuf;

const
  FarBuild = 'b.6';

type
  TFarItem = record
    Name: WideString;
    Size: Int64;
    Attr: DWORD;
    WriteTime: TFileTime;
    CreateTime: TFileTime;
    AccessTime: TFileTime;
    OrigIndex: Integer;  // порядок, в котором отдала Windows (Unsorted)
    IsDir: Boolean;
    IsUp: Boolean;       // строка '..'
    Selected: Boolean;
  end;
  // Один тип массива для поля и локальных переменных: в Delphi 7 два
  // отдельно описанных 'array of TFarItem' - разные типы, присвоить нельзя
  TFarItems = array of TFarItem;
  TFarNames = array of WideString;

  // Открытый диалог: копирование, перенос, папка, удаление
  TFarDlgKind = (fdNone, fdCopy, fdMove, fdMkDir, fdDelete);

  // Сортировка панели (порядок - как в меню Ctrl+F12 и клавиши Ctrl+F3 ..
  // Ctrl+F9)
  TFarSortMode = (fsName, fsExt, fsWrite, fsSize, fsUnsorted, fsCreation,
    fsAccess);

  // Открытое меню: смена диска (Alt+F1 / Alt+F2), сортировка (Ctrl+F12),
  // история папок (Alt+F12)
  TFarMenuKind = (fmNone, fmDrive, fmSort, fmHistory);

  TFarMenuItem = record
    Text: WideString;       // '&' перед буквой быстрого выбора
    RightText: WideString;  // справа: клавиша и т.п.
    Mark: WideChar;         // слева: ' ', '+', '-', отметка
    Separator: Boolean;
    Data: WideString;       // что выбрано: путь, буква диска
    Tag: Integer;
  end;
  TFarMenuItems = array of TFarMenuItem;

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
    FSortMode: TFarSortMode;
    FSortReverse: Boolean;
    FDirsFirst: Boolean;
    FSelFirst: Boolean;
    procedure SortItems;
    function ItemLess(const ItemA, ItemB: TFarItem): Boolean;
  public
    constructor Create;
    // Пересортировать (сменилась сортировка или выделение при
    // FSelFirst); курсор остаётся на том же файле
    procedure Resort;
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
    // Диалог (F5 - F8): рисуется поверх панелей, клавиши - ему
    FDlgKind: TFarDlgKind;
    FDlgTitle: WideString;
    FDlgLines: TFarNames;
    FDlgCentered: Boolean;
    FDlgWarn: Boolean;            // красный, как предупреждения FAR
    FDlgHasEdit: Boolean;
    FDlgEdit: WideString;
    FDlgEditPos: Integer;         // каретка: 0..Length(FDlgEdit)
    FDlgEditScroll: Integer;
    FDlgEditFresh: Boolean;       // текст не трогали: ввод заменяет его
    FDlgButtons: TFarNames;
    FDlgFocus: Integer;           // -1 - поле ввода, 0.. - кнопка
    FDlgButtonCol: array of Integer;  // где нарисованы кнопки (для мыши)
    FDlgButtonRow: Integer;
    FDlgNames: TFarNames;         // с чем работает операция
    FDlgPermanent: Boolean;       // удаление мимо корзины
    // Слежение за папками панелей
    FWatch: array[0..1] of THandle;
    FWatchPath: array[0..1] of WideString;
    FWatchDirty: array[0..1] of Boolean;
    FWatchFirstTick: Cardinal;    // первый сигнал из ещё не перечитанных
    FWatchLastTick: Cardinal;     // последний сигнал
    FWatchTimer: TTimer;
    FBusy: Boolean;               // идёт операция с файлами
    // Меню (Alt+F1 / Alt+F2, Ctrl+F12, Alt+F12): рисуется поверх панелей
    FMenuKind: TFarMenuKind;
    FMenuTitle: WideString;
    FMenuItems: TFarMenuItems;
    FMenuCursor: Integer;
    FMenuTop: Integer;            // первый видимый пункт
    FMenuPanel: Integer;          // к какой панели относится
    FMenuLeft: Integer;           // где нарисовано (для мыши)
    FMenuTopRow: Integer;
    FMenuWidth: Integer;
    FMenuRows: Integer;
    // История папок (Alt+F12): старые сверху, новые снизу
    FHistory: TFarNames;
    // Последняя папка на каждом диске A..Z (любой из панелей) - куда
    // вести при смене диска, если другая панель не на этом диске
    FDriveLast: array[0..25] of WideString;
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
    // Диалоги и операции с файлами
    function CollectNames(ACurrentOnly: Boolean): TFarNames;
    procedure DlgOpen(AKind: TFarDlgKind; const ATitle: WideString;
      const ALines: array of WideString; ACentered, AWarn, AHasEdit: Boolean;
      const AEdit: WideString; const AButtons: array of WideString);
    procedure DlgClose;
    function DlgKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
    procedure DlgInsertText(const AText: WideString);
    procedure DlgActivate(AButton: Integer);
    procedure DrawBox(ALeft, ATop, ARight, ABottom: Integer; AColor: TColor);
    procedure DrawDialog;
    procedure StartCopy(AMove, ACurrentOnly: Boolean);
    procedure StartMkDir;
    procedure StartDelete(ACurrentOnly, APermanent: Boolean);
    procedure DoCopyMove(AMove: Boolean; const ATarget: WideString);
    procedure DoMkDir(const AName: WideString);
    procedure DoDelete;
    function RunShellOp(AFunc: UINT; const AFrom, ATo: WideString;
      AFlags: Word; var AAborted: Boolean): Boolean;
    procedure AfterOperation(const AFocusName: WideString);
    procedure WatchTick(Sender: TObject);
    procedure WatchStop;
    // Меню, сортировка, диски, история папок
    procedure MenuOpen(AKind: TFarMenuKind; const ATitle: WideString;
      const AItems: TFarMenuItems; ACursor, APanel: Integer);
    procedure MenuClose;
    function MenuKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
    procedure MenuMove(ADelta: Integer);
    procedure MenuActivate(AIndex: Integer);
    function MenuItemAt(AX, AY: Integer): Integer;
    procedure DrawMenu;
    procedure ShowDriveMenu(APanelIndex: Integer);
    procedure ShowSortMenu;
    procedure ShowHistoryMenu;
    procedure SetSort(APanel: TFarPanel; AMode: TFarSortMode);
    procedure ToggleSelFirst(APanel: TFarPanel);
    procedure SelectDrive(APanelIndex: Integer; ALetter: WideChar);
    procedure HistoryAdd(const APath: WideString);
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
  FarVkBackslash = $DC;            // VK_OEM_5: '\' над Enter
  FarVkBackslash2 = $E2;           // VK_OEM_102: '\' у левого Shift

  // Диалоги (палитра FAR: Dialog.*, WarnDialog.*)
  FarRed = $000080;                // B_RED
  FarDlgTitleCopy = 'Copy';
  FarDlgTitleMove = 'Rename/Move';

  // SHFileOperation
  FarFoMove = 1;
  FarFoCopy = 2;
  FarFoDelete = 3;
  FarFofNoConfirmation = $10;
  FarFofAllowUndo = $40;
  FarFofNoConfirmMkDir = $200;

  // FindFirstChangeNotification: имена файлов и папок, атрибуты, размер,
  // время записи
  FarNotifyFilter = $01 or $02 or $04 or $08 or $10;
  FarWatchInterval = 250;          // мс, опрос сигналов
  FarWatchQuiet = 300;             // мс без новых сигналов - перечитать
  FarWatchMaxDelay = 2000;         // но не реже, чем раз в столько мс

  // Буква сортировки в левом верхнем углу панели (как в FAR 2): по
  // возрастанию - строчная, обратный порядок - прописная
  FarSortLetters = 'nxmsuca';
  FarHistoryMax = 50;
  FarHistorySection = 'FarHistory';
  FarCheckMark = WideChar($221A);  // отметка в меню (в Terminus cp1251 её
                                   // нет - рисует Lucida Console)
  FarSemFailCritical = 1;          // SEM_FAILCRITICALERRORS
  FarDriveRemovable = 2;
  FarDriveFixed = 3;
  FarDriveRemote = 4;
  FarDriveCdRom = 5;
  FarDriveRamDisk = 6;
  FarInvalidAttr = $FFFFFFFF;

  // Кейбар: подписи FAR (far\farlang.templ.m4) для того, что есть или
  // будет в unIDE FAR. Пустые - клавиша в unIDE FAR не используется.
  FarKeysNormal: array[0..11] of string = ('Help', 'UserMn', 'View', 'Edit',
    'Copy', 'RenMov', 'MkFold', 'Delete', 'ConfMn', 'Quit', '', 'Screen');
  FarKeysShift: array[0..11] of string = ('', '', '', 'Edit..', 'Copy',
    'Rename', '', 'Delete', 'Save', '', '', 'SelUp');
  FarKeysAlt: array[0..11] of string = ('Left', 'Right', '', '', '', '', '',
    '', '', '', '', 'FoldHs');
  FarKeysCtrl: array[0..11] of string = ('', '', 'Name', 'Extens', 'Write',
    'Size', 'Unsort', 'Creatn', 'Access', '', '', 'Sort');

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

  // SHFILEOPSTRUCTW - в 32-битной Windows без выравнивания (packed)
  TFarShFileOp = packed record
    Wnd: HWND;
    Func: UINT;
    From: PWideChar;
    Dest: PWideChar;
    Flags: Word;
    AnyAborted: BOOL;
    NameMappings: Pointer;
    ProgressTitle: PWideChar;
  end;

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
function FarMultiToWide(ACodePage: UINT; AFlags: DWORD; AMulti: PAnsiChar;
  AMultiLen: Integer; AWide: PWideChar; AWideLen: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'MultiByteToWideChar';
function FarCreateDir(APath: PWideChar; ASecurity: Pointer): BOOL; stdcall;
  external 'kernel32.dll' name 'CreateDirectoryW';
function FarShFileOperation(var AOp: TFarShFileOp): Integer; stdcall;
  external 'shell32.dll' name 'SHFileOperationW';
function FarFindFirstChange(APath: PWideChar; AWatchSubtree: BOOL;
  AFilter: DWORD): THandle; stdcall;
  external 'kernel32.dll' name 'FindFirstChangeNotificationW';
function FarFindNextChange(AHandle: THandle): BOOL; stdcall;
  external 'kernel32.dll' name 'FindNextChangeNotification';
function FarFindCloseChange(AHandle: THandle): BOOL; stdcall;
  external 'kernel32.dll' name 'FindCloseChangeNotification';
function FarGetDriveType(ARoot: PWideChar): UINT; stdcall;
  external 'kernel32.dll' name 'GetDriveTypeW';
function FarGetVolumeInfo(ARoot, AVolumeName: PWideChar; AVolumeNameSize: DWORD;
  ASerial, AMaxComponent, AFsFlags: Pointer; AFsName: PWideChar;
  AFsNameSize: DWORD): BOOL; stdcall;
  external 'kernel32.dll' name 'GetVolumeInformationW';
function FarSetErrorMode(AMode: UINT): UINT; stdcall;
  external 'kernel32.dll' name 'SetErrorMode';

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

function FarTrimW(const AText: WideString): WideString;
var
  FirstPos, LastPos: Integer;
begin
  FirstPos := 1;
  LastPos := Length(AText);
  while (FirstPos <= LastPos) and (AText[FirstPos] <= ' ') do
    Inc(FirstPos);
  while (LastPos >= FirstPos) and (AText[LastPos] <= ' ') do
    Dec(LastPos);
  Result := Copy(AText, FirstPos, LastPos - FirstPos + 1);
end;

function FarSameName(const ANameA, ANameB: WideString): Boolean;
begin
  Result := FarCompareNames(ANameA, ANameB) = 0;
end;

// Путь из диалога: полный - как есть, '\...' - от корня диска панели,
// остальное - от папки панели ABase
function FarFullPath(const ABase, ATarget: WideString): WideString;
begin
  if (Length(ATarget) >= 2) and (ATarget[2] = ':') then
    Result := ATarget
  else if Copy(ATarget, 1, 2) = '\\' then
    Result := ATarget
  else if (ATarget <> '') and (ATarget[1] = '\') then
    Result := Copy(FarRootOf(ABase), 1, Length(FarRootOf(ABase)) - 1) +
      ATarget
  else
    Result := ABase + ATarget;
end;

// 'D:\a\b.txt' -> ADir = 'D:\a\', AName = 'b.txt'
procedure FarSplitPath(const APath: WideString; var ADir, AName: WideString);
var
  SlashPos: Integer;
begin
  SlashPos := Length(APath);
  while (SlashPos > 0) and (APath[SlashPos] <> '\') do
    Dec(SlashPos);
  ADir := Copy(APath, 1, SlashPos);
  AName := Copy(APath, SlashPos + 1, MaxInt);
end;

// Номер диска пути: 'D:\...' - 3 (A = 0); не диск - -1
function FarDriveIndex(const APath: WideString): Integer;
var
  Code: Integer;
begin
  Result := -1;
  if (Length(APath) < 2) or (APath[2] <> ':') then
    Exit;
  Code := Ord(APath[1]);
  if (Code >= Ord('a')) and (Code <= Ord('z')) then
    Dec(Code, 32);
  if (Code >= Ord('A')) and (Code <= Ord('Z')) then
    Result := Code - Ord('A');
end;

// Папка со всеми недостающими папками выше
function FarForceDirs(const APath: WideString): Boolean;
var
  DirPath, Upper, ChildName: WideString;
begin
  DirPath := APath;
  if (Length(DirPath) > 3) and (DirPath[Length(DirPath)] = '\') then
    SetLength(DirPath, Length(DirPath) - 1);
  if FarDirExists(DirPath) then
  begin
    Result := True;
    Exit;
  end;
  Upper := FarParentOf(FarWithSlash(DirPath), ChildName);
  if (Upper <> '') and not FarDirExists(Upper) then
    if not FarForceDirs(Upper) then
    begin
      Result := False;
      Exit;
    end;
  Result := FarCreateDir(PWideChar(DirPath), nil) or
            (GetLastError = ERROR_ALREADY_EXISTS);
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

constructor TFarPanel.Create;
begin
  inherited Create;
  FSortMode := fsName;
  FSortReverse := False;
  FDirsFirst := True;
  FSelFirst := False;
end;

// Расширение имени: после последней точки ('' - нет точки)
function FarNameExt(const AName: WideString): WideString;
var
  DotPos: Integer;
begin
  DotPos := Length(AName);
  while (DotPos > 0) and (AName[DotPos] <> '.') do
    Dec(DotPos);
  if DotPos > 1 then
    Result := Copy(AName, DotPos + 1, MaxInt)
  else
    Result := '';
end;

function FarCompareInt64(AValueA, AValueB: Int64): Integer;
begin
  if AValueA < AValueB then
    Result := -1
  else if AValueA > AValueB then
    Result := 1
  else
    Result := 0;
end;

// Порядок, как в FAR (filelist.cpp, SortModes): '..' - первым; при
// FSelFirst - выделенные, при FDirsFirst - папки перед файлами; дальше по
// ключу сортировки. Имя и расширение - по возрастанию, время и размер - по
// убыванию (новые и большие сверху); FSortReverse переворачивает ключ.
// Равные по ключу - по имени.
function TFarPanel.ItemLess(const ItemA, ItemB: TFarItem): Boolean;
var
  Cmp: Integer;
begin
  if ItemA.IsUp <> ItemB.IsUp then
  begin
    Result := ItemA.IsUp;
    Exit;
  end;
  if FSelFirst and (ItemA.Selected <> ItemB.Selected) then
  begin
    Result := ItemA.Selected;
    Exit;
  end;
  if FDirsFirst and (ItemA.IsDir <> ItemB.IsDir) then
  begin
    Result := ItemA.IsDir;
    Exit;
  end;
  case FSortMode of
    fsExt:
      Cmp := FarCompareNames(FarNameExt(ItemA.Name), FarNameExt(ItemB.Name));
    fsWrite:
      Cmp := -CompareFileTime(ItemA.WriteTime, ItemB.WriteTime);
    fsSize:
      Cmp := -FarCompareInt64(ItemA.Size, ItemB.Size);
    fsUnsorted:
      Cmp := ItemA.OrigIndex - ItemB.OrigIndex;
    fsCreation:
      Cmp := -CompareFileTime(ItemA.CreateTime, ItemB.CreateTime);
    fsAccess:
      Cmp := -CompareFileTime(ItemA.AccessTime, ItemB.AccessTime);
  else
    Cmp := 0;
  end;
  if (Cmp = 0) and (FSortMode <> fsUnsorted) then
  begin
    Cmp := FarCompareNames(ItemA.Name, ItemB.Name);
    if Cmp = 0 then
      Cmp := ItemA.OrigIndex - ItemB.OrigIndex;
  end;
  if FSortReverse then
    Cmp := -Cmp;
  Result := Cmp < 0;
end;

procedure TFarPanel.Resort;
var
  FocusName: WideString;
  NewIndex: Integer;
begin
  FocusName := '';
  if (FCursor >= 0) and (FCursor < FCount) then
    FocusName := FItems[FCursor].Name;
  SortItems;
  if FocusName <> '' then
  begin
    NewIndex := IndexOfName(FocusName);
    if NewIndex >= 0 then
      FCursor := NewIndex;
  end;
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
    NewItems[0].OrigIndex := -1;
    FillChar(NewItems[0].CreateTime, SizeOf(TFileTime), 0);
    FillChar(NewItems[0].AccessTime, SizeOf(TFileTime), 0);
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
        NewItems[NewCount].CreateTime := FindData.ftCreationTime;
        NewItems[NewCount].AccessTime := FindData.ftLastAccessTime;
        NewItems[NewCount].OrigIndex := NewCount;
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
  SelectedCount, ItemIndex, NameIndex, OldTop, OldCursor: Integer;
  ErrorText: string;
begin
  if FPath = '' then
    Exit;
  FocusName := '';
  OldCursor := FCursor;
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
  // Файла под курсором больше нет (удалён, переименован) - курсор на том
  // же месте списка, как в FAR
  if (FocusName <> '') and (IndexOfName(FocusName) < 0) then
  begin
    FCursor := OldCursor;
    if FCursor >= FCount then
      FCursor := FCount - 1;
    if FCursor < 0 then
      FCursor := 0;
  end;
  for NameIndex := 0 to SelectedCount - 1 do
  begin
    ItemIndex := IndexOfName(SelectedNames[NameIndex]);
    if ItemIndex >= 0 then
      SetSelected(ItemIndex, True);
  end;
  // Выделенные первыми: при чтении выделения ещё не было
  if FSelFirst and (SelectedCount > 0) then
    Resort;
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
  FDlgKind := fdNone;
  FDlgFocus := -1;
  FWatch[0] := 0;
  FWatch[1] := 0;
  FWatchTimer := TTimer.Create(Self);
  FWatchTimer.Interval := FarWatchInterval;
  FWatchTimer.OnTimer := WatchTick;
  FWatchTimer.Enabled := True;
end;

destructor TFarView.Destroy;
begin
  FWatchTimer.Enabled := False;
  WatchStop;
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
  SortLetter: string;
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

  // Буква сортировки в левом верхнем углу
  SortLetter := Copy(FarSortLetters, Ord(Panel.FSortMode) + 1, 1);
  if Panel.FSortReverse then
    SortLetter := UpperCase(SortLetter);
  PutText(PanelX + 1, 0, 1, SortLetter, FarLightCyan, FarBlue);

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
      if FMenuKind <> fmNone then
        DrawMenu;
      if FDlgKind <> fdNone then
        DrawDialog;
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
  // Открыто меню: щелчок по пункту выбирает его, мимо меню - закрывает
  if FMenuKind <> fmNone then
  begin
    ItemIndex := MenuItemAt(X, Y);
    if ItemIndex >= 0 then
      MenuActivate(ItemIndex)
    else
      MenuClose;
    Invalidate;
    Exit;
  end;
  // Открыт диалог: щелчок по его кнопке нажимает её, панели не трогаем
  if FDlgKind <> fdNone then
  begin
    if (Button = mbLeft) and (Y div FCellH = FDlgButtonRow) then
      for ItemIndex := 0 to High(FDlgButtonCol) do
        if (X div FCellW >= FDlgButtonCol[ItemIndex]) and
           (X div FCellW < FDlgButtonCol[ItemIndex] +
                           Length(FDlgButtons[ItemIndex]) + 4) then
        begin
          DlgActivate(ItemIndex);
          Break;
        end;
    Invalidate;
    Exit;
  end;
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
  if (FDlgKind <> fdNone) or (FMenuKind <> fmNone) then
    Exit;
  CursorPos := ScreenToClient(Mouse.CursorPos);
  if ItemAt(CursorPos.X, CursorPos.Y, PanelIndex, ItemIndex) then
    EnterItem;
end;

procedure TFarView.WMMouseWheel(var Message: TWMMouseWheel);
begin
  Message.Result := 1;
  if FMenuKind <> fmNone then
  begin
    if Message.WheelDelta > 0 then
      MenuMove(-1)
    else if Message.WheelDelta < 0 then
      MenuMove(1);
    Invalidate;
    Exit;
  end;
  if FDlgKind <> fdNone then
    Exit;
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
  AnsiCh: AnsiChar;
  WideCh: WideChar;
begin
  Result := False;
  KeyCode := Word(AMsg.wParam);

  // Символ для поля ввода диалога. Окно VCL в Delphi 7 - ANSI: символ
  // приходит в кодировке Windows
  if AMsg.message = WM_CHAR then
  begin
    if (FDlgKind <> fdNone) and FDlgHasEdit and (FDlgFocus < 0) and
       (KeyCode >= 32) then
    begin
      AnsiCh := AnsiChar(KeyCode and $FF);
      WideCh := #0;
      FarMultiToWide(CP_ACP, 0, @AnsiCh, 1, @WideCh, 1);
      if WideCh <> #0 then
        DlgInsertText(WideCh);
      Invalidate;
      Result := True;
    end;
    Exit;
  end;

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

  if FMenuKind <> fmNone then
  begin
    Result := MenuKey(KeyCode, ShiftDown, CtrlDown, AltDown);
    Invalidate;
  end
  else if FDlgKind <> fdNone then
  begin
    Result := DlgKey(KeyCode, ShiftDown, CtrlDown, AltDown);
    Invalidate;
  end
  else
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
    // Ctrl+F3 .. Ctrl+F9 - сортировка (повтор - обратный порядок),
    // Ctrl+F12 - меню сортировки
    if ACtrl and not AAlt and not AShift then
      case AKey of
        VK_F3..VK_F9:
          begin
            SetSort(ActivePanel, TFarSortMode(AKey - VK_F3));
            Exit;
          end;
        VK_F12:
          begin
            ShowSortMenu;
            Exit;
          end;
      end;
    // Alt+F1 / Alt+F2 - смена диска левой / правой панели, Alt+F12 -
    // история папок
    if AAlt and not ACtrl and not AShift then
      case AKey of
        VK_F1:
          begin
            ShowDriveMenu(0);
            Exit;
          end;
        VK_F2:
          begin
            ShowDriveMenu(1);
            Exit;
          end;
        VK_F12:
          begin
            ShowHistoryMenu;
            Exit;
          end;
      end;
    if Plain then
      case AKey of
        VK_F12:             // Shift+F12 - выделенные первыми
          if AShift then
          begin
            ToggleSelFirst(ActivePanel);
            Exit;
          end;
        VK_F10:
          if not AShift then
          begin
            if Assigned(FOnClose) then
              FOnClose(Self);
            Exit;
          end;
        VK_F5:              // Shift+F5 - только файл под курсором
          begin
            StartCopy(False, AShift);
            Exit;
          end;
        VK_F6:              // Shift+F6 - переименовать файл под курсором
          begin
            StartCopy(True, AShift);
            Exit;
          end;
        VK_F7:
          if not AShift then
          begin
            StartMkDir;
            Exit;
          end;
        VK_F8:              // Shift+F8 - только файл под курсором
          begin
            StartDelete(AShift, False);
            Exit;
          end;
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
      VK_DELETE:            // Del - как F8, Shift+Del - мимо корзины
        StartDelete(False, AShift);
    else
      Result := False;
    end
  else if ACtrl and not AAlt and not AShift then
    case AKey of
      VK_PRIOR:
        GoUp;
      VK_NEXT:
        EnterItem;
      FarVkBackslash, FarVkBackslash2:
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
    if Panel.FSelFirst then
      Panel.Resort;
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
  if Panel.FSelFirst then
  begin
    Panel.Resort;
    EnsureVisible(Panel);
  end;
end;

procedure TFarView.ChangeDir(APanel: TFarPanel; const APath,
  AFocus: WideString);
var
  ErrorText: string;
  DriveIndex: Integer;
begin
  if not APanel.ReadDir(APath, AFocus, ErrorText) then
  begin
    Status('unIDE FAR: папку не открыть: ' + ErrorText);
    Exit;
  end;
  HistoryAdd(APanel.Path);
  DriveIndex := FarDriveIndex(APanel.Path);
  if DriveIndex >= 0 then
    FDriveLast[DriveIndex] := APanel.Path;
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
//  Диалоги в духе FAR: рамка, строки текста, поле ввода, кнопки.
//  Esc и F10 - отмена, Enter - кнопка в фокусе (из поля ввода - первая),
//  Tab / стрелки вверх-вниз - следующий элемент, стрелки влево-вправо на
//  кнопках - соседняя кнопка. В поле ввода: Home/End, стрелки, Backspace,
//  Del, Ctrl+Y - очистить, Ctrl+V / Shift+Ins - вставить. Пока текст не
//  трогали, он показан выделенным и первый набранный символ заменяет его.
// ---------------------------------------------------------------------------

procedure TFarView.DlgOpen(AKind: TFarDlgKind; const ATitle: WideString;
  const ALines: array of WideString; ACentered, AWarn, AHasEdit: Boolean;
  const AEdit: WideString; const AButtons: array of WideString);
var
  LineIndex: Integer;
begin
  FDlgKind := AKind;
  FDlgTitle := ATitle;
  SetLength(FDlgLines, Length(ALines));
  for LineIndex := 0 to High(ALines) do
    FDlgLines[LineIndex] := ALines[LineIndex];
  SetLength(FDlgButtons, Length(AButtons));
  for LineIndex := 0 to High(AButtons) do
    FDlgButtons[LineIndex] := AButtons[LineIndex];
  SetLength(FDlgButtonCol, Length(AButtons));
  FDlgCentered := ACentered;
  FDlgWarn := AWarn;
  FDlgHasEdit := AHasEdit;
  FDlgEdit := AEdit;
  FDlgEditPos := Length(AEdit);
  FDlgEditScroll := 0;
  FDlgEditFresh := AEdit <> '';
  if AHasEdit then
    FDlgFocus := -1
  else
    FDlgFocus := 0;
  FDlgButtonRow := -1;
  Invalidate;
end;

procedure TFarView.DlgClose;
begin
  FDlgKind := fdNone;
  FDlgLines := nil;
  FDlgButtons := nil;
  FDlgButtonCol := nil;
  Invalidate;
end;

procedure TFarView.DlgInsertText(const AText: WideString);
begin
  if FDlgEditFresh then
  begin
    FDlgEdit := '';
    FDlgEditPos := 0;
    FDlgEditFresh := False;
  end;
  Insert(AText, FDlgEdit, FDlgEditPos + 1);
  Inc(FDlgEditPos, Length(AText));
end;

function TFarView.DlgKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
var
  InEdit: Boolean;
  ButtonCount: Integer;
begin
  Result := True;
  InEdit := FDlgHasEdit and (FDlgFocus < 0);
  ButtonCount := Length(FDlgButtons);
  case AKey of
    VK_ESCAPE, VK_F10:
      DlgClose;
    VK_RETURN:
      if FDlgFocus < 0 then
        DlgActivate(0)
      else
        DlgActivate(FDlgFocus);
    VK_SPACE:
      if FDlgFocus >= 0 then
        DlgActivate(FDlgFocus)
      else
        Result := False;  // пробел - символ поля ввода (WM_CHAR)
    VK_TAB, VK_UP, VK_DOWN:
      begin
        if (AKey = VK_UP) or ((AKey = VK_TAB) and AShift) then
          Dec(FDlgFocus)
        else
          Inc(FDlgFocus);
        if FDlgFocus >= ButtonCount then
        begin
          if FDlgHasEdit then
            FDlgFocus := -1
          else
            FDlgFocus := 0;
        end;
        if (FDlgFocus < -1) or ((FDlgFocus = -1) and not FDlgHasEdit) then
          FDlgFocus := ButtonCount - 1;
      end;
    VK_LEFT, VK_RIGHT:
      if InEdit then
      begin
        FDlgEditFresh := False;
        if (AKey = VK_LEFT) and (FDlgEditPos > 0) then
          Dec(FDlgEditPos)
        else if (AKey = VK_RIGHT) and (FDlgEditPos < Length(FDlgEdit)) then
          Inc(FDlgEditPos);
      end
      else if ButtonCount > 0 then
      begin
        if AKey = VK_LEFT then
          FDlgFocus := (FDlgFocus + ButtonCount - 1) mod ButtonCount
        else
          FDlgFocus := (FDlgFocus + 1) mod ButtonCount;
      end;
    VK_HOME, VK_END:
      if InEdit then
      begin
        FDlgEditFresh := False;
        if AKey = VK_HOME then
          FDlgEditPos := 0
        else
          FDlgEditPos := Length(FDlgEdit);
      end;
    VK_BACK:
      if InEdit then
      begin
        if FDlgEditFresh then
          DlgInsertText('')
        else if FDlgEditPos > 0 then
        begin
          Delete(FDlgEdit, FDlgEditPos, 1);
          Dec(FDlgEditPos);
        end;
      end;
    VK_DELETE:
      if InEdit then
      begin
        if FDlgEditFresh then
          DlgInsertText('')
        else if FDlgEditPos < Length(FDlgEdit) then
          Delete(FDlgEdit, FDlgEditPos + 1, 1);
      end;
    VK_INSERT:
      if InEdit and AShift and Clipboard.HasFormat(CF_TEXT) then
        DlgInsertText(Clipboard.AsText);
  else
    if InEdit and ACtrl and not AAlt and (AKey = Ord('V')) then
    begin
      if Clipboard.HasFormat(CF_TEXT) then
        DlgInsertText(Clipboard.AsText);
    end
    else if InEdit and ACtrl and not AAlt and (AKey = Ord('Y')) then
    begin
      FDlgEdit := '';
      FDlgEditPos := 0;
      FDlgEditFresh := False;
    end
    else if ACtrl or AAlt then
      Result := True   // сочетания в диалоге никуда не отдаём (ярлыки меню)
    else
      Result := False; // буквы, цифры - символы поля ввода (WM_CHAR)
  end;
end;

procedure TFarView.DlgActivate(AButton: Integer);
var
  Kind: TFarDlgKind;
  EditText: WideString;
begin
  Kind := FDlgKind;
  EditText := FDlgEdit;
  DlgClose;
  // Первая кнопка - действие, остальные (Cancel) - отмена
  if AButton <> 0 then
    Exit;
  case Kind of
    fdCopy:
      DoCopyMove(False, EditText);
    fdMove:
      DoCopyMove(True, EditText);
    fdMkDir:
      DoMkDir(EditText);
    fdDelete:
      DoDelete;
  end;
end;

// Двойная рамка по клеткам: линии посередине клеток краёв
procedure TFarView.DrawBox(ALeft, ATop, ARight, ABottom: Integer;
  AColor: TColor);
var
  LeftX, RightX, TopY, BottomY: Integer;
begin
  LeftX := ALeft * FCellW + FCellW div 2;
  RightX := ARight * FCellW + FCellW div 2;
  TopY := ATop * FCellH + FCellH div 2;
  BottomY := ABottom * FCellH + FCellH div 2;
  with FBuffer.Canvas do
  begin
    Pen.Style := psSolid;
    Pen.Width := 1;
    Pen.Color := AColor;
    Brush.Style := bsClear;
    Rectangle(LeftX - 1, TopY - 1, RightX + 2, BottomY + 2);
    Rectangle(LeftX + 1, TopY + 1, RightX, BottomY);
    Brush.Style := bsSolid;
  end;
end;

procedure TFarView.DrawDialog;
var
  BoxW, BoxH, BoxLeft, BoxTop, InnerLeft, InnerW, Row, LineIndex: Integer;
  ButtonIndex, ButtonsW, ButtonCol, SepY: Integer;
  Back, Fore, ButtonBack, ButtonFore, FocusBack, FocusFore: TColor;
  ButtonText, ShownText: WideString;
  CaretX: Integer;
begin
  BoxW := 72;
  if BoxW > FCols - 2 then
    BoxW := FCols - 2;
  if BoxW < 20 then
    Exit;
  BoxH := Length(FDlgLines) + 6;
  if FDlgHasEdit then
    Inc(BoxH);
  BoxLeft := (FCols - BoxW) div 2;
  BoxTop := (PanelHeight - BoxH) div 2;
  if BoxTop < 0 then
    BoxTop := 0;
  InnerLeft := BoxLeft + 5;
  InnerW := BoxW - 10;

  if FDlgWarn then
  begin
    Back := FarRed;
    Fore := FarWhite;
    ButtonBack := FarRed;
    ButtonFore := FarWhite;
    FocusBack := FarLightGray;
    FocusFore := FarBlack;
  end
  else
  begin
    Back := FarLightGray;
    Fore := FarBlack;
    ButtonBack := FarLightGray;
    ButtonFore := FarBlack;
    FocusBack := FarCyan;
    FocusFore := FarBlack;
  end;

  for Row := BoxTop to BoxTop + BoxH - 1 do
    FillCells(BoxLeft, Row, BoxW, Back);
  DrawBox(BoxLeft + 2, BoxTop + 1, BoxLeft + BoxW - 3, BoxTop + BoxH - 2, Fore);
  PutCentered(BoxLeft, BoxTop + 1, BoxW, ' ' + FDlgTitle + ' ', Fore, Back);

  Row := BoxTop + 2;
  for LineIndex := 0 to High(FDlgLines) do
  begin
    if FDlgCentered then
      PutCentered(InnerLeft, Row, InnerW,
        FarFitName(FDlgLines[LineIndex], InnerW), Fore, Back)
    else
      PutText(InnerLeft, Row, InnerW,
        FarFitName(FDlgLines[LineIndex], InnerW), Fore, Back);
    Inc(Row);
  end;

  // Поле ввода: чёрным по бирюзовому, нетронутый текст - выделен
  if FDlgHasEdit then
  begin
    if FDlgEditPos < FDlgEditScroll then
      FDlgEditScroll := FDlgEditPos;
    if FDlgEditPos > FDlgEditScroll + InnerW - 1 then
      FDlgEditScroll := FDlgEditPos - InnerW + 1;
    ShownText := Copy(FDlgEdit, FDlgEditScroll + 1, InnerW);
    FillCells(InnerLeft, Row, InnerW, FarCyan);
    if FDlgEditFresh then
      PutText(InnerLeft, Row, Length(ShownText), ShownText, FarWhite, FarBlack)
    else
      PutText(InnerLeft, Row, Length(ShownText), ShownText, FarBlack, FarCyan);
    if FDlgFocus < 0 then
    begin
      CaretX := (InnerLeft + FDlgEditPos - FDlgEditScroll) * FCellW;
      FBuffer.Canvas.Brush.Style := bsSolid;
      FBuffer.Canvas.Brush.Color := FarBlack;
      FBuffer.Canvas.FillRect(Rect(CaretX, Row * FCellH + 1, CaretX + 2,
        (Row + 1) * FCellH - 1));
    end;
    Inc(Row);
  end;

  // Разделитель над кнопками - одинарная линия до внутренней рамки
  SepY := Row * FCellH + FCellH div 2;
  with FBuffer.Canvas do
  begin
    Pen.Color := Fore;
    MoveTo((BoxLeft + 2) * FCellW + FCellW div 2 + 1, SepY);
    LineTo((BoxLeft + BoxW - 3) * FCellW + FCellW div 2, SepY);
  end;
  Inc(Row);

  // Кнопки по центру: [ Copy ] [ Cancel ]
  ButtonsW := 0;
  for ButtonIndex := 0 to High(FDlgButtons) do
    Inc(ButtonsW, Length(FDlgButtons[ButtonIndex]) + 4 + 1);
  Dec(ButtonsW);
  ButtonCol := BoxLeft + (BoxW - ButtonsW) div 2;
  FDlgButtonRow := Row;
  for ButtonIndex := 0 to High(FDlgButtons) do
  begin
    ButtonText := '[ ' + FDlgButtons[ButtonIndex] + ' ]';
    FDlgButtonCol[ButtonIndex] := ButtonCol;
    if ButtonIndex = FDlgFocus then
      PutText(ButtonCol, Row, Length(ButtonText), ButtonText, FocusFore,
        FocusBack)
    else
      PutText(ButtonCol, Row, Length(ButtonText), ButtonText, ButtonFore,
        ButtonBack);
    Inc(ButtonCol, Length(ButtonText) + 1);
  end;
end;

// ---------------------------------------------------------------------------
//  F5 - F8: копирование, перенос, папка, удаление
// ---------------------------------------------------------------------------

// Имена для операции: выделенные, а нет выделенных (или ACurrentOnly) -
// файл под курсором. '..' не берётся.
function TFarView.CollectNames(ACurrentOnly: Boolean): TFarNames;
var
  Panel: TFarPanel;
  ItemIndex, NameCount: Integer;
begin
  Result := nil;
  Panel := ActivePanel;
  if Panel.Count = 0 then
    Exit;
  if not ACurrentOnly and (Panel.SelCount > 0) then
  begin
    SetLength(Result, Panel.SelCount);
    NameCount := 0;
    for ItemIndex := 0 to Panel.Count - 1 do
      if Panel.FItems[ItemIndex].Selected then
      begin
        Result[NameCount] := Panel.FItems[ItemIndex].Name;
        Inc(NameCount);
      end;
    SetLength(Result, NameCount);
  end
  else if (Panel.Cursor >= 0) and (Panel.Cursor < Panel.Count) and
          not Panel.FItems[Panel.Cursor].IsUp then
  begin
    SetLength(Result, 1);
    Result[0] := Panel.FItems[Panel.Cursor].Name;
  end;
end;

procedure TFarView.StartCopy(AMove, ACurrentOnly: Boolean);
var
  Names: TFarNames;
  Subject, Prompt, Target: WideString;
begin
  Names := CollectNames(ACurrentOnly);
  if Length(Names) = 0 then
    Exit;
  FDlgNames := Names;
  // F5 / F6 - в папку другой панели; Shift+F5 / Shift+F6 - новое имя
  // в той же папке
  if ACurrentOnly then
    Target := Names[0]
  else
    Target := FPanels[1 - FActive].Path;
  if Length(Names) = 1 then
    Subject := '"' + Names[0] + '"'
  else
    Subject := IntToStr(Length(Names)) + ' items';
  if AMove then
  begin
    Prompt := 'Rename or move ' + Subject + ' to:';
    DlgOpen(fdMove, FarDlgTitleMove, [Prompt], False, False, True, Target,
      ['Rename', 'Cancel']);
  end
  else
  begin
    Prompt := 'Copy ' + Subject + ' to:';
    DlgOpen(fdCopy, FarDlgTitleCopy, [Prompt], False, False, True, Target,
      ['Copy', 'Cancel']);
  end;
end;

procedure TFarView.StartMkDir;
begin
  if ActivePanel.Path = '' then
    Exit;
  DlgOpen(fdMkDir, 'Make folder', ['Create the folder:'], False, False, True,
    '', ['OK', 'Cancel']);
end;

procedure TFarView.StartDelete(ACurrentOnly, APermanent: Boolean);
var
  Names: TFarNames;
  Lines: TFarNames;
  ItemIndex: Integer;
  What: WideString;
begin
  Names := CollectNames(ACurrentOnly);
  if Length(Names) = 0 then
    Exit;
  FDlgNames := Names;
  FDlgPermanent := APermanent;
  if Length(Names) = 1 then
  begin
    ItemIndex := ActivePanel.IndexOfName(Names[0]);
    if (ItemIndex >= 0) and ActivePanel.FItems[ItemIndex].IsDir then
      What := 'the folder'
    else
      What := 'the file';
    SetLength(Lines, 3);
    Lines[0] := 'Do you wish to delete';
    Lines[1] := What;
    Lines[2] := Names[0];
  end
  else
  begin
    SetLength(Lines, 2);
    Lines[0] := 'Do you wish to delete';
    Lines[1] := IntToStr(Length(Names)) + ' items';
  end;
  if APermanent then
  begin
    SetLength(Lines, Length(Lines) + 1);
    Lines[High(Lines)] := 'bypassing the Recycle Bin';
  end;
  DlgOpen(fdDelete, 'Delete', Lines, True, True, False, '',
    ['Delete', 'Cancel']);
end;

function TFarView.RunShellOp(AFunc: UINT; const AFrom, ATo: WideString;
  AFlags: Word; var AAborted: Boolean): Boolean;
var
  ShellOp: TFarShFileOp;
  ParentForm: TCustomForm;
  ResultCode: Integer;
begin
  FillChar(ShellOp, SizeOf(ShellOp), 0);
  ParentForm := GetParentForm(Self);
  if ParentForm <> nil then
    ShellOp.Wnd := ParentForm.Handle
  else
    ShellOp.Wnd := Handle;
  ShellOp.Func := AFunc;
  ShellOp.From := PWideChar(AFrom);
  if ATo <> '' then
    ShellOp.Dest := PWideChar(ATo)
  else
    ShellOp.Dest := nil;
  ShellOp.Flags := AFlags;
  FBusy := True;
  try
    ResultCode := FarShFileOperation(ShellOp);
  finally
    FBusy := False;
  end;
  AAborted := ShellOp.AnyAborted;
  Result := ResultCode = 0;
  if not Result and not AAborted then
    Status('unIDE FAR: операция не выполнена (код ' +
      IntToStr(ResultCode) + ')');
end;

// Список для pFrom / pTo SHFileOperation: полные пути через #0, в конце
// ещё #0
function FarZeroList(const ADir: WideString; const ANames: TFarNames): WideString;
var
  NameIndex: Integer;
begin
  Result := '';
  for NameIndex := 0 to High(ANames) do
    Result := Result + ADir + ANames[NameIndex] + WideChar(#0);
  Result := Result + WideChar(#0);
end;

procedure TFarView.DoCopyMove(AMove: Boolean; const ATarget: WideString);
var
  Source: TFarPanel;
  Target, TargetDir, DestPath, SourceDir, TargetName, NewName: WideString;
  NameIndex, ItemIndex: Integer;
  IntoDir, Aborted, Done: Boolean;
  Func: UINT;
begin
  Source := ActivePanel;
  Target := FarTrimW(ATarget);
  if (Target = '') or (Length(FDlgNames) = 0) then
    Exit;
  Target := FarFullPath(Source.Path, Target);
  NewName := '';

  // В папку: путь кончается на '\', папка уже есть или имён несколько.
  // Иначе (одно имя) - копия / перенос под новым именем.
  IntoDir := (Target[Length(Target)] = '\') or FarDirExists(Target) or
             (Length(FDlgNames) > 1);
  if IntoDir then
  begin
    TargetDir := FarWithSlash(Target);
    if FarSameName(TargetDir, Source.Path) then
    begin
      if not AMove then
        Status('unIDE FAR: нельзя копировать файл сам в себя');
      Exit;
    end;
    // Папку нельзя копировать или переносить внутрь неё самой
    for NameIndex := 0 to High(FDlgNames) do
      if FarSameName(Copy(TargetDir, 1,
           Length(Source.Path + FDlgNames[NameIndex]) + 1),
           Source.Path + FDlgNames[NameIndex] + '\') then
      begin
        Status('unIDE FAR: нельзя копировать или переносить папку в саму себя');
        Exit;
      end;
    if not FarForceDirs(TargetDir) then
    begin
      Status('unIDE FAR: папку не создать: ' + SysErrorMessage(GetLastError));
      Exit;
    end;
    if Length(TargetDir) > 3 then
      DestPath := Copy(TargetDir, 1, Length(TargetDir) - 1)
    else
      DestPath := TargetDir;
  end
  else
  begin
    if FarSameName(Target, Source.Path + FDlgNames[0]) then
    begin
      if not AMove then
        Status('unIDE FAR: нельзя копировать файл сам в себя');
      Exit;
    end;
    FarSplitPath(Target, SourceDir, TargetName);
    if (SourceDir <> '') and not FarForceDirs(SourceDir) then
    begin
      Status('unIDE FAR: папку не создать: ' + SysErrorMessage(GetLastError));
      Exit;
    end;
    if FarSameName(SourceDir, Source.Path) then
      NewName := TargetName;  // курсор - на новое имя
    DestPath := Target;
  end;

  if AMove then
    Func := FarFoMove
  else
    Func := FarFoCopy;
  Done := RunShellOp(Func, FarZeroList(Source.Path, FDlgNames),
    DestPath + WideChar(#0) + WideChar(#0),
    FarFofNoConfirmMkDir or FarFofAllowUndo, Aborted);

  // Обработанные - без выделения (так в FAR)
  if Done and not Aborted then
    for NameIndex := 0 to High(FDlgNames) do
    begin
      ItemIndex := Source.IndexOfName(FDlgNames[NameIndex]);
      if ItemIndex >= 0 then
        Source.SetSelected(ItemIndex, False);
    end;
  AfterOperation(NewName);
end;

procedure TFarView.DoMkDir(const AName: WideString);
var
  Name, FullPath, FirstPart: WideString;
  SlashPos: Integer;
begin
  Name := FarTrimW(AName);
  if Name = '' then
    Exit;
  FullPath := FarFullPath(ActivePanel.Path, Name);
  if not FarForceDirs(FullPath) then
  begin
    Status('unIDE FAR: папку не создать: ' + SysErrorMessage(GetLastError));
    Exit;
  end;
  // 'a\b\c' - курсор на 'a'
  FirstPart := Name;
  SlashPos := 1;
  while (SlashPos <= Length(FirstPart)) and (FirstPart[SlashPos] <> '\') do
    Inc(SlashPos);
  FirstPart := Copy(FirstPart, 1, SlashPos - 1);
  if (Length(FirstPart) >= 2) and (FirstPart[2] = ':') then
    FirstPart := '';
  AfterOperation(FirstPart);
end;

procedure TFarView.DoDelete;
var
  Flags: Word;
  Aborted: Boolean;
begin
  if Length(FDlgNames) = 0 then
    Exit;
  // Подтверждение уже было - своё; Windows не спрашивает ещё раз
  Flags := FarFofNoConfirmation;
  if not FDlgPermanent then
    Flags := Flags or FarFofAllowUndo;
  RunShellOp(FarFoDelete, FarZeroList(ActivePanel.Path, FDlgNames), '',
    Flags, Aborted);
  AfterOperation('');
end;

// После операции - обе панели перечитать, курсор на AFocusName (если задан)
procedure TFarView.AfterOperation(const AFocusName: WideString);
var
  ItemIndex: Integer;
begin
  ActivePanel.Reread;
  if AFocusName <> '' then
  begin
    ItemIndex := ActivePanel.IndexOfName(AFocusName);
    if ItemIndex >= 0 then
      ActivePanel.Cursor := ItemIndex;
  end;
  FPanels[1 - FActive].Reread;
  EnsureVisible(FPanels[0]);
  EnsureVisible(FPanels[1]);
  FWatchDirty[0] := False;
  FWatchDirty[1] := False;
  FDlgNames := nil;
  Invalidate;
end;

// ---------------------------------------------------------------------------
//  Слежение за папками панелей: FindFirstChangeNotification на каждую,
//  сигналы опрашивает таймер. Перечитывается, когда сигналы затихли
//  (копирование многих файлов даёт их подряд), но не реже FarWatchMaxDelay.
//  Окно спрятано - слежение снято: открытый handle папки мешает удалить её.
// ---------------------------------------------------------------------------

procedure TFarView.WatchStop;
var
  PanelIndex: Integer;
begin
  for PanelIndex := 0 to 1 do
  begin
    if FWatch[PanelIndex] <> 0 then
      FarFindCloseChange(FWatch[PanelIndex]);
    FWatch[PanelIndex] := 0;
    FWatchPath[PanelIndex] := '';
    FWatchDirty[PanelIndex] := False;
  end;
end;

procedure TFarView.WatchTick(Sender: TObject);
var
  PanelIndex: Integer;
  Panel: TFarPanel;
  NowTick: Cardinal;
  UpperPath, ChildName: WideString;
  AnyDirty: Boolean;
begin
  if not Visible or not HandleAllocated then
  begin
    if (FWatch[0] <> 0) or (FWatch[1] <> 0) then
      WatchStop;
    Exit;
  end;
  if FBusy then
    Exit;
  NowTick := GetTickCount;
  AnyDirty := False;
  for PanelIndex := 0 to 1 do
  begin
    Panel := FPanels[PanelIndex];
    if Panel.Path <> FWatchPath[PanelIndex] then
    begin
      if FWatch[PanelIndex] <> 0 then
        FarFindCloseChange(FWatch[PanelIndex]);
      FWatch[PanelIndex] := 0;
      FWatchPath[PanelIndex] := Panel.Path;
      if Panel.Path <> '' then
      begin
        FWatch[PanelIndex] := FarFindFirstChange(PWideChar(Panel.Path),
          False, FarNotifyFilter);
        if FWatch[PanelIndex] = INVALID_HANDLE_VALUE then
          FWatch[PanelIndex] := 0;
      end;
    end;
    if (FWatch[PanelIndex] <> 0) and
       (WaitForSingleObject(FWatch[PanelIndex], 0) = WAIT_OBJECT_0) then
    begin
      FarFindNextChange(FWatch[PanelIndex]);
      if not FWatchDirty[0] and not FWatchDirty[1] then
        FWatchFirstTick := NowTick;
      FWatchDirty[PanelIndex] := True;
      FWatchLastTick := NowTick;
    end;
    if FWatchDirty[PanelIndex] then
      AnyDirty := True;
  end;

  if not AnyDirty or (FDlgKind <> fdNone) or (FMenuKind <> fmNone) then
    Exit;
  if (NowTick - FWatchLastTick < FarWatchQuiet) and
     (NowTick - FWatchFirstTick < FarWatchMaxDelay) then
    Exit;

  for PanelIndex := 0 to 1 do
    if FWatchDirty[PanelIndex] then
    begin
      FWatchDirty[PanelIndex] := False;
      Panel := FPanels[PanelIndex];
      if (Panel.Path <> '') and not FarDirExists(Panel.Path) then
      begin
        // Папку удалили - ближайшая существующая выше, как в FAR
        UpperPath := Panel.Path;
        while (UpperPath <> '') and not FarDirExists(UpperPath) do
          UpperPath := FarParentOf(UpperPath, ChildName);
        if UpperPath <> '' then
          ChangeDir(Panel, UpperPath, '');
      end
      else
        Panel.Reread;
      EnsureVisible(Panel);
    end;
  Invalidate;
end;

// ---------------------------------------------------------------------------
//  Меню в духе FAR (VMenu): белым по бирюзовому, пункт под курсором -
//  белым по чёрному, буква быстрого выбора - жёлтая. Стрелки, Home/End,
//  PgUp/PgDn, Enter - выбрать, буква - выбрать пункт с этой буквой,
//  Esc / F10 - закрыть. В истории папок Del удаляет пункт.
// ---------------------------------------------------------------------------

// Текст пункта без '&': AHotPos - номер буквы быстрого выбора (0 - нет).
// '&&' - сам знак '&'.
function FarStripAmp(const AText: WideString; var AHotPos: Integer): WideString;
var
  CharIndex: Integer;
begin
  Result := '';
  AHotPos := 0;
  CharIndex := 1;
  while CharIndex <= Length(AText) do
  begin
    if (AText[CharIndex] = '&') and (CharIndex < Length(AText)) then
    begin
      Inc(CharIndex);
      if (AText[CharIndex] <> '&') and (AHotPos = 0) then
        AHotPos := Length(Result) + 1;
    end;
    Result := Result + AText[CharIndex];
    Inc(CharIndex);
  end;
end;

// Знак '&' в тексте пункта - буквально (пути в истории папок)
function FarEscapeAmp(const AText: WideString): WideString;
var
  CharIndex: Integer;
begin
  Result := '';
  for CharIndex := 1 to Length(AText) do
  begin
    if AText[CharIndex] = '&' then
      Result := Result + '&';
    Result := Result + AText[CharIndex];
  end;
end;

function FarPadRight(const AText: WideString; AWidth: Integer): WideString;
begin
  Result := AText;
  while Length(Result) < AWidth do
    Result := Result + ' ';
end;

procedure TFarView.MenuOpen(AKind: TFarMenuKind; const ATitle: WideString;
  const AItems: TFarMenuItems; ACursor, APanel: Integer);
begin
  if Length(AItems) = 0 then
    Exit;
  FMenuKind := AKind;
  FMenuTitle := ATitle;
  FMenuItems := AItems;
  FMenuCursor := ACursor;
  if (FMenuCursor < 0) or (FMenuCursor >= Length(AItems)) then
    FMenuCursor := 0;
  FMenuTop := 0;
  FMenuPanel := APanel;
  FMenuRows := 0;
  Invalidate;
end;

procedure TFarView.MenuClose;
begin
  FMenuKind := fmNone;
  FMenuItems := nil;
  FMenuRows := 0;
  Invalidate;
end;

// Курсор на ADelta пунктов, разделители пропускаются. Шаг на 1 с края
// списка переходит на другой край (так в FAR).
procedure TFarView.MenuMove(ADelta: Integer);
var
  ItemCount, Target, Step: Integer;
begin
  ItemCount := Length(FMenuItems);
  if ItemCount = 0 then
    Exit;
  if Abs(ADelta) = 1 then
  begin
    Target := FMenuCursor;
    repeat
      Target := (Target + ADelta + ItemCount) mod ItemCount;
    until not FMenuItems[Target].Separator or (Target = FMenuCursor);
  end
  else
  begin
    Target := FMenuCursor + ADelta;
    if Target < 0 then
      Target := 0;
    if Target >= ItemCount then
      Target := ItemCount - 1;
    if ADelta < 0 then
      Step := 1
    else
      Step := -1;
    while FMenuItems[Target].Separator and (Target + Step >= 0) and
          (Target + Step < ItemCount) do
      Inc(Target, Step);
  end;
  FMenuCursor := Target;
end;

function TFarView.MenuKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
var
  ItemIndex, HotPos, HistoryIndex: Integer;
  ItemText: WideString;
  HotChar: Integer;
begin
  // Пока меню открыто, клавиши - только ему
  Result := True;
  case AKey of
    VK_ESCAPE, VK_F10:
      MenuClose;
    VK_UP:
      MenuMove(-1);
    VK_DOWN:
      MenuMove(1);
    VK_HOME:
      begin
        FMenuCursor := 0;
        MenuMove(0);
      end;
    VK_END:
      begin
        FMenuCursor := High(FMenuItems);
        MenuMove(0);
      end;
    VK_PRIOR:
      MenuMove(-FMenuRows + 1);
    VK_NEXT:
      MenuMove(FMenuRows - 1);
    VK_RETURN:
      MenuActivate(FMenuCursor);
    VK_DELETE:
      // История папок: Del - убрать папку из истории
      if (FMenuKind = fmHistory) and (FMenuCursor >= 0) and
         (FMenuCursor <= High(FMenuItems)) then
      begin
        for HistoryIndex := High(FHistory) downto 0 do
          if FarSameName(FHistory[HistoryIndex],
                         FMenuItems[FMenuCursor].Data) then
          begin
            for ItemIndex := HistoryIndex to High(FHistory) - 1 do
              FHistory[ItemIndex] := FHistory[ItemIndex + 1];
            SetLength(FHistory, Length(FHistory) - 1);
          end;
        for ItemIndex := FMenuCursor to High(FMenuItems) - 1 do
          FMenuItems[ItemIndex] := FMenuItems[ItemIndex + 1];
        SetLength(FMenuItems, Length(FMenuItems) - 1);
        if Length(FMenuItems) = 0 then
          MenuClose
        else if FMenuCursor > High(FMenuItems) then
          FMenuCursor := High(FMenuItems);
      end;
  else
    // Буква - пункт с этой буквой быстрого выбора
    if not ACtrl and not AAlt and
       (((AKey >= Ord('A')) and (AKey <= Ord('Z'))) or
        ((AKey >= Ord('0')) and (AKey <= Ord('9')))) then
      for ItemIndex := 0 to High(FMenuItems) do
      begin
        if FMenuItems[ItemIndex].Separator then
          Continue;
        ItemText := FarStripAmp(FMenuItems[ItemIndex].Text, HotPos);
        if HotPos = 0 then
          Continue;
        HotChar := Ord(ItemText[HotPos]);
        if (HotChar >= Ord('a')) and (HotChar <= Ord('z')) then
          Dec(HotChar, 32);
        if HotChar = AKey then
        begin
          FMenuCursor := ItemIndex;
          MenuActivate(ItemIndex);
          Break;
        end;
      end;
  end;
end;

procedure TFarView.MenuActivate(AIndex: Integer);
var
  Item: TFarMenuItem;
  Kind: TFarMenuKind;
  PanelIndex: Integer;
  Panel: TFarPanel;
begin
  if (AIndex < 0) or (AIndex > High(FMenuItems)) then
    Exit;
  Item := FMenuItems[AIndex];
  if Item.Separator then
    Exit;
  Kind := FMenuKind;
  PanelIndex := FMenuPanel;
  MenuClose;
  case Kind of
    fmDrive:
      if Item.Data <> '' then
        SelectDrive(PanelIndex, Item.Data[1]);
    fmSort:
      begin
        Panel := FPanels[PanelIndex];
        if Item.Tag <= Ord(High(TFarSortMode)) then
          SetSort(Panel, TFarSortMode(Item.Tag))
        else if Item.Tag = 100 then
          ToggleSelFirst(Panel)
        else if Item.Tag = 101 then
        begin
          Panel.FDirsFirst := not Panel.FDirsFirst;
          Panel.Resort;
          EnsureVisible(Panel);
        end;
      end;
    fmHistory:
      if FarDirExists(Item.Data) then
        ChangeDir(ActivePanel, Item.Data, '')
      else
        Status('unIDE FAR: папки нет: ' + Item.Data);
  end;
  Invalidate;
end;

// Номер пункта меню под точкой (клиентские координаты); -1 - не пункт
function TFarView.MenuItemAt(AX, AY: Integer): Integer;
var
  Col, Row: Integer;
begin
  Result := -1;
  if FMenuRows <= 0 then
    Exit;
  Col := AX div FCellW;
  Row := AY div FCellH;
  if (Col <= FMenuLeft) or (Col >= FMenuLeft + FMenuWidth - 1) then
    Exit;
  if (Row <= FMenuTopRow) or (Row > FMenuTopRow + FMenuRows) then
    Exit;
  Result := FMenuTop + Row - FMenuTopRow - 1;
  if (Result > High(FMenuItems)) or FMenuItems[Result].Separator then
    Result := -1;
end;

procedure TFarView.DrawMenu;
var
  ItemIndex, RowIndex, MaxW, ItemW, BoxW, BoxH, AreaX, AreaW, RowY: Integer;
  TextW, HotPos, SepY: Integer;
  Item: TFarMenuItem;
  ItemText: WideString;
  Back, Fore, HotFore: TColor;
begin
  MaxW := Length(FMenuTitle) + 4;
  for ItemIndex := 0 to High(FMenuItems) do
  begin
    ItemW := Length(FarStripAmp(FMenuItems[ItemIndex].Text, HotPos)) + 2;
    if FMenuItems[ItemIndex].RightText <> '' then
      Inc(ItemW, Length(FMenuItems[ItemIndex].RightText) + 3);
    if ItemW > MaxW then
      MaxW := ItemW;
  end;
  BoxW := MaxW + 4;
  if BoxW > FCols - 2 then
    BoxW := FCols - 2;
  if BoxW < 10 then
    Exit;
  FMenuRows := Length(FMenuItems);
  if FMenuRows > PanelHeight - 4 then
    FMenuRows := PanelHeight - 4;
  if FMenuRows < 1 then
    FMenuRows := 1;
  BoxH := FMenuRows + 2;
  FMenuWidth := BoxW;

  // Смена диска и сортировка - над своей панелью, история - посередине
  if FMenuKind = fmHistory then
  begin
    AreaX := 0;
    AreaW := FCols;
  end
  else
    PanelBounds(FMenuPanel, AreaX, AreaW);
  FMenuLeft := AreaX + (AreaW - BoxW) div 2;
  if FMenuLeft + BoxW > FCols then
    FMenuLeft := FCols - BoxW;
  if FMenuLeft < 0 then
    FMenuLeft := 0;
  FMenuTopRow := (PanelHeight - BoxH) div 2;
  if FMenuTopRow < 0 then
    FMenuTopRow := 0;

  if FMenuCursor < FMenuTop then
    FMenuTop := FMenuCursor;
  if FMenuCursor >= FMenuTop + FMenuRows then
    FMenuTop := FMenuCursor - FMenuRows + 1;
  if FMenuTop > Length(FMenuItems) - FMenuRows then
    FMenuTop := Length(FMenuItems) - FMenuRows;
  if FMenuTop < 0 then
    FMenuTop := 0;

  for RowIndex := FMenuTopRow to FMenuTopRow + BoxH - 1 do
    FillCells(FMenuLeft, RowIndex, BoxW, FarCyan);
  DrawBox(FMenuLeft, FMenuTopRow, FMenuLeft + BoxW - 1,
    FMenuTopRow + BoxH - 1, FarWhite);
  PutCentered(FMenuLeft, FMenuTopRow, BoxW, ' ' + FMenuTitle + ' ', FarWhite,
    FarCyan);
  // Пункты выше / ниже видимых - стрелки на рамке
  if FMenuTop > 0 then
    PutText(FMenuLeft + BoxW - 2, FMenuTopRow, 1, '^', FarYellow, FarCyan);
  if FMenuTop + FMenuRows < Length(FMenuItems) then
    PutText(FMenuLeft + BoxW - 2, FMenuTopRow + BoxH - 1, 1, 'v', FarYellow,
      FarCyan);

  for RowIndex := 0 to FMenuRows - 1 do
  begin
    ItemIndex := FMenuTop + RowIndex;
    if ItemIndex > High(FMenuItems) then
      Break;
    Item := FMenuItems[ItemIndex];
    RowY := FMenuTopRow + 1 + RowIndex;
    if Item.Separator then
    begin
      SepY := RowY * FCellH + FCellH div 2;
      with FBuffer.Canvas do
      begin
        Pen.Color := FarWhite;
        MoveTo(FMenuLeft * FCellW + FCellW div 2 + 2, SepY);
        LineTo((FMenuLeft + BoxW - 1) * FCellW + FCellW div 2 - 1, SepY);
      end;
      Continue;
    end;
    Fore := FarWhite;
    HotFore := FarYellow;
    if ItemIndex = FMenuCursor then
      Back := FarBlack
    else
      Back := FarCyan;
    FillCells(FMenuLeft + 1, RowY, BoxW - 2, Back);
    PutText(FMenuLeft + 2, RowY, 1, Item.Mark, Fore, Back);
    ItemText := FarStripAmp(Item.Text, HotPos);
    TextW := BoxW - 6;
    if Item.RightText <> '' then
      Dec(TextW, Length(Item.RightText) + 1);
    if FMenuKind = fmHistory then
      ItemText := FarFitPath(ItemText, TextW)
    else
      ItemText := FarFitName(ItemText, TextW);
    PutText(FMenuLeft + 4, RowY, TextW, ItemText, Fore, Back);
    if (HotPos > 0) and (HotPos <= Length(ItemText)) then
      PutText(FMenuLeft + 4 + HotPos - 1, RowY, 1, ItemText[HotPos], HotFore,
        Back);
    if Item.RightText <> '' then
      PutText(FMenuLeft + BoxW - 2 - Length(Item.RightText), RowY,
        Length(Item.RightText), Item.RightText, Fore, Back);
  end;
end;

// ---------------------------------------------------------------------------
//  Сортировка (Ctrl+F12, Ctrl+F3 .. Ctrl+F9, Shift+F12)
// ---------------------------------------------------------------------------

procedure TFarView.SetSort(APanel: TFarPanel; AMode: TFarSortMode);
begin
  // Та же сортировка ещё раз - обратный порядок (так в FAR)
  if APanel.FSortMode = AMode then
    APanel.FSortReverse := not APanel.FSortReverse
  else
  begin
    APanel.FSortMode := AMode;
    APanel.FSortReverse := False;
  end;
  APanel.Resort;
  EnsureVisible(APanel);
  Invalidate;
end;

procedure TFarView.ToggleSelFirst(APanel: TFarPanel);
begin
  APanel.FSelFirst := not APanel.FSelFirst;
  APanel.Resort;
  EnsureVisible(APanel);
  Invalidate;
end;

procedure TFarView.ShowSortMenu;
const
  SortTexts: array[TFarSortMode] of string = ('&Name', 'E&xtension',
    '&Write time', '&Size', '&Unsorted', '&Creation time', '&Access time');
  SortKeys: array[TFarSortMode] of string = ('Ctrl+F3', 'Ctrl+F4', 'Ctrl+F5',
    'Ctrl+F6', 'Ctrl+F7', 'Ctrl+F8', 'Ctrl+F9');
var
  Items: TFarMenuItems;
  Mode: TFarSortMode;
  Panel: TFarPanel;
  ItemIndex: Integer;
begin
  Panel := ActivePanel;
  SetLength(Items, Ord(High(TFarSortMode)) + 1 + 3);
  ItemIndex := 0;
  for Mode := Low(TFarSortMode) to High(TFarSortMode) do
  begin
    Items[ItemIndex].Text := SortTexts[Mode];
    Items[ItemIndex].RightText := SortKeys[Mode];
    Items[ItemIndex].Mark := ' ';
    if Mode = Panel.FSortMode then
    begin
      if Panel.FSortReverse then
        Items[ItemIndex].Mark := '-'
      else
        Items[ItemIndex].Mark := '+';
    end;
    Items[ItemIndex].Separator := False;
    Items[ItemIndex].Tag := Ord(Mode);
    Inc(ItemIndex);
  end;
  Items[ItemIndex].Separator := True;
  Inc(ItemIndex);
  Items[ItemIndex].Text := 'Show selected f&irst';
  Items[ItemIndex].RightText := 'Shift+F12';
  Items[ItemIndex].Separator := False;
  Items[ItemIndex].Tag := 100;
  if Panel.FSelFirst then
    Items[ItemIndex].Mark := FarCheckMark
  else
    Items[ItemIndex].Mark := ' ';
  Inc(ItemIndex);
  Items[ItemIndex].Text := 'Show &directories first';
  Items[ItemIndex].RightText := '';
  Items[ItemIndex].Separator := False;
  Items[ItemIndex].Tag := 101;
  if Panel.FDirsFirst then
    Items[ItemIndex].Mark := FarCheckMark
  else
    Items[ItemIndex].Mark := ' ';
  MenuOpen(fmSort, 'Sort by', Items, Ord(Panel.FSortMode), FActive);
end;

// ---------------------------------------------------------------------------
//  Смена диска (Alt+F1 - левая панель, Alt+F2 - правая)
// ---------------------------------------------------------------------------

procedure TFarView.ShowDriveMenu(APanelIndex: Integer);
var
  Items: TFarMenuItems;
  DriveMask: DWORD;
  DriveIndex, CurrentDrive, CursorIndex: Integer;
  Root, TypeText, VolumeLabel, Letter: WideString;
  LabelBuffer: array[0..MAX_PATH] of WideChar;
  DriveType: UINT;
  OldMode: UINT;
begin
  CurrentDrive := FarDriveIndex(FPanels[APanelIndex].Path);
  CursorIndex := 0;
  SetLength(Items, 0);
  DriveMask := GetLogicalDrives;
  // Нет диска в дисководе - без окна Windows с ошибкой
  OldMode := FarSetErrorMode(FarSemFailCritical);
  try
    for DriveIndex := 0 to 25 do
    begin
      if DriveMask and (DWORD(1) shl DriveIndex) = 0 then
        Continue;
      Root := WideString(WideChar(Ord('A') + DriveIndex)) + ':\';
      DriveType := FarGetDriveType(PWideChar(Root));
      case DriveType of
        FarDriveRemovable: TypeText := 'removable';
        FarDriveFixed: TypeText := 'fixed';
        FarDriveRemote: TypeText := 'network';
        FarDriveCdRom: TypeText := 'CD-ROM';
        FarDriveRamDisk: TypeText := 'RAM disk';
      else
        TypeText := '';
      end;
      // Метка - только у жёстких и RAM-дисков: у сменных, CD и сетевых
      // чтение может ждать устройство или сеть
      VolumeLabel := '';
      if (DriveType = FarDriveFixed) or (DriveType = FarDriveRamDisk) then
      begin
        LabelBuffer[0] := #0;
        if FarGetVolumeInfo(PWideChar(Root), LabelBuffer, MAX_PATH, nil, nil,
             nil, nil, 0) then
          VolumeLabel := PWideChar(@LabelBuffer[0]);
      end;
      // Delphi 7 не складывает символ-литерал с WideChar - буква отдельной
      // строкой
      Letter := WideChar(Ord('A') + DriveIndex);
      SetLength(Items, Length(Items) + 1);
      Items[High(Items)].Text := WideString('&') + Letter + ':  ' +
        FarPadRight(TypeText, 10) + '  ' + FarEscapeAmp(VolumeLabel);
      Items[High(Items)].RightText := '';
      Items[High(Items)].Mark := ' ';
      Items[High(Items)].Separator := False;
      Items[High(Items)].Data := Letter;
      Items[High(Items)].Tag := DriveIndex;
      if DriveIndex = CurrentDrive then
        CursorIndex := High(Items);
    end;
  finally
    FarSetErrorMode(OldMode);
  end;
  MenuOpen(fmDrive, 'Change drive', Items, CursorIndex, APanelIndex);
end;

procedure TFarView.SelectDrive(APanelIndex: Integer; ALetter: WideChar);
var
  Root, Target: WideString;
  DriveIndex: Integer;
  OldMode: UINT;
begin
  Root := WideString(ALetter) + ':\';
  DriveIndex := FarDriveIndex(Root);
  if DriveIndex < 0 then
    Exit;
  OldMode := FarSetErrorMode(FarSemFailCritical);
  try
    if not FarDirExists(Root) then
    begin
      Status('unIDE FAR: диск ' + Root + ' не готов');
      Exit;
    end;
    // Куда вести:
    //  - другая панель на этом диске - в её папку;
    //  - эта панель уже на этом диске - папка не меняется;
    //  - иначе - последняя папка на этом диске, нет её - корень.
    // Активная панель не меняется.
    Target := '';
    if FarDriveIndex(FPanels[1 - APanelIndex].Path) = DriveIndex then
      Target := FPanels[1 - APanelIndex].Path
    else if FarDriveIndex(FPanels[APanelIndex].Path) = DriveIndex then
      Target := FPanels[APanelIndex].Path
    else
      Target := FDriveLast[DriveIndex];
    if (Target = '') or not FarDirExists(Target) then
      Target := Root;
    ChangeDir(FPanels[APanelIndex], Target, '');
  finally
    FarSetErrorMode(OldMode);
  end;
end;

// ---------------------------------------------------------------------------
//  История папок (Alt+F12): общая для обеих панелей, до FarHistoryMax
// ---------------------------------------------------------------------------

procedure TFarView.HistoryAdd(const APath: WideString);
var
  HistoryIndex, MoveIndex: Integer;
begin
  if APath = '' then
    Exit;
  for HistoryIndex := High(FHistory) downto 0 do
    if FarSameName(FHistory[HistoryIndex], APath) then
    begin
      for MoveIndex := HistoryIndex to High(FHistory) - 1 do
        FHistory[MoveIndex] := FHistory[MoveIndex + 1];
      SetLength(FHistory, Length(FHistory) - 1);
    end;
  SetLength(FHistory, Length(FHistory) + 1);
  FHistory[High(FHistory)] := APath;
  if Length(FHistory) > FarHistoryMax then
  begin
    for MoveIndex := 0 to FarHistoryMax - 1 do
      FHistory[MoveIndex] := FHistory[MoveIndex + Length(FHistory) -
        FarHistoryMax];
    SetLength(FHistory, FarHistoryMax);
  end;
end;

procedure TFarView.ShowHistoryMenu;
var
  Items: TFarMenuItems;
  HistoryIndex: Integer;
  ShownPath: WideString;
begin
  if Length(FHistory) = 0 then
  begin
    Status('unIDE FAR: история папок пуста');
    Exit;
  end;
  SetLength(Items, Length(FHistory));
  for HistoryIndex := 0 to High(FHistory) do
  begin
    ShownPath := FHistory[HistoryIndex];
    if (Length(ShownPath) > 3) and (ShownPath[Length(ShownPath)] = '\') then
      SetLength(ShownPath, Length(ShownPath) - 1);
    Items[HistoryIndex].Text := FarEscapeAmp(ShownPath);
    Items[HistoryIndex].RightText := '';
    Items[HistoryIndex].Mark := ' ';
    Items[HistoryIndex].Separator := False;
    Items[HistoryIndex].Data := FHistory[HistoryIndex];
    Items[HistoryIndex].Tag := HistoryIndex;
  end;
  MenuOpen(fmHistory, 'Folders history', Items, High(Items), FActive);
end;

// ---------------------------------------------------------------------------
//  Состояние в editor.ini, раздел [Far]
// ---------------------------------------------------------------------------

procedure TFarView.LoadState(const AIniName: string;
  const ADefaultDir: WideString);
const
  PathKeys: array[0..1] of string = ('LeftPath', 'RightPath');
  FileKeys: array[0..1] of string = ('LeftFile', 'RightFile');
  SidePrefix: array[0..1] of string = ('Left', 'Right');
var
  Ini: TBufIniFile;
  PanelIndex, DriveIndex, HistoryCount, HistoryIndex, SortIndex: Integer;
  SavedPath, SavedFile, ChildName: WideString;
  ErrorText: string;
begin
  Ini := TBufIniFile.Create(AIniName);
  try
    // Последние папки дисков и история папок
    for DriveIndex := 0 to 25 do
      FDriveLast[DriveIndex] := FarDecodePath(Ini.ReadString(FarIniSection,
        'Drive' + Chr(Ord('A') + DriveIndex), ''));
    HistoryCount := Ini.ReadInteger(FarHistorySection, 'Count', 0);
    if HistoryCount > FarHistoryMax then
      HistoryCount := FarHistoryMax;
    if HistoryCount < 0 then
      HistoryCount := 0;
    SetLength(FHistory, 0);
    for HistoryIndex := 1 to HistoryCount do
    begin
      SavedPath := FarDecodePath(Ini.ReadString(FarHistorySection,
        'Folder' + IntToStr(HistoryIndex), ''));
      if SavedPath <> '' then
      begin
        SetLength(FHistory, Length(FHistory) + 1);
        FHistory[High(FHistory)] := SavedPath;
      end;
    end;

    for PanelIndex := 0 to 1 do
    begin
      // Сортировка панели - до чтения папки
      SortIndex := Ini.ReadInteger(FarIniSection,
        SidePrefix[PanelIndex] + 'Sort', 0);
      if (SortIndex < Ord(Low(TFarSortMode))) or
         (SortIndex > Ord(High(TFarSortMode))) then
        SortIndex := 0;
      FPanels[PanelIndex].FSortMode := TFarSortMode(SortIndex);
      FPanels[PanelIndex].FSortReverse := Ini.ReadInteger(FarIniSection,
        SidePrefix[PanelIndex] + 'SortReverse', 0) <> 0;
      FPanels[PanelIndex].FDirsFirst := Ini.ReadInteger(FarIniSection,
        SidePrefix[PanelIndex] + 'DirsFirst', 1) <> 0;
      FPanels[PanelIndex].FSelFirst := Ini.ReadInteger(FarIniSection,
        SidePrefix[PanelIndex] + 'SelFirst', 0) <> 0;

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
  SidePrefix: array[0..1] of string = ('Left', 'Right');
var
  Ini: TBufIniFile;
  PanelIndex, DriveIndex, HistoryIndex: Integer;
  CurrentName: WideString;
  DriveKey: string;
begin
  Ini := TBufIniFile.Create(AIniName);
  try
    for DriveIndex := 0 to 25 do
    begin
      DriveKey := 'Drive' + Chr(Ord('A') + DriveIndex);
      if FDriveLast[DriveIndex] <> '' then
        Ini.WriteString(FarIniSection, DriveKey,
          FarEncodePath(FDriveLast[DriveIndex]))
      else if Ini.ReadString(FarIniSection, DriveKey, '') <> '' then
        Ini.DeleteKey(FarIniSection, DriveKey);
      // Ключи сборки b.5 (память у каждой панели своя) - не нужны
      for PanelIndex := 0 to 1 do
      begin
        DriveKey := SidePrefix[PanelIndex] + 'Drive' + Chr(Ord('A') + DriveIndex);
        if Ini.ReadString(FarIniSection, DriveKey, '') <> '' then
          Ini.DeleteKey(FarIniSection, DriveKey);
      end;
    end;
    Ini.EraseSection(FarHistorySection);
    Ini.WriteInteger(FarHistorySection, 'Count', Length(FHistory));
    for HistoryIndex := 0 to High(FHistory) do
      Ini.WriteString(FarHistorySection, 'Folder' + IntToStr(HistoryIndex + 1),
        FarEncodePath(FHistory[HistoryIndex]));
    for PanelIndex := 0 to 1 do
    begin
      Ini.WriteInteger(FarIniSection, SidePrefix[PanelIndex] + 'Sort',
        Ord(FPanels[PanelIndex].FSortMode));
      Ini.WriteInteger(FarIniSection, SidePrefix[PanelIndex] + 'SortReverse',
        Ord(FPanels[PanelIndex].FSortReverse));
      Ini.WriteInteger(FarIniSection, SidePrefix[PanelIndex] + 'DirsFirst',
        Ord(FPanels[PanelIndex].FDirsFirst));
      Ini.WriteInteger(FarIniSection, SidePrefix[PanelIndex] + 'SelFirst',
        Ord(FPanels[PanelIndex].FSelFirst));

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
