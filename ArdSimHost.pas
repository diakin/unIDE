unit ArdSimHost;

// ---------------------------------------------------------------------------
//  Вкладка «Эмулятор» правой панели: скетч Arduino, собранный ArdSim
//  (ArdSim\build_sim.cmd), работает отдельным процессом без своего окна:
//    <скетч>_sim.exe /host:<имя>
//  Экран 480x320, вывод Serial и нажатия клавиш - через общую память
//  "Local\ArdSim_<имя>", её создаёт эта вкладка. Раскладка - как в
//  ArdSim\src\sim_host.cpp:
//    смещение 0       заголовок, 32 слова по 4 байта (индексы Hdr*)
//    смещение 128     экран 320 строк по 480 точек, RGB565 (как у UTFT)
//    смещение 307328  кольцо вывода Serial, 65536 байт
//    смещение 372864  область отладчика (индексы Dbg*, ArdSim\src\sim_internal.h)
//  Сигналы (обороты, гармоники, ротор) задаются в ardsim.ini рядом с exe:
//  эмулятор перечитывает файл, когда тот меняется. Главное из него - на
//  панели «Сигналы» под прибором (тахометр, обороты, 1-я гармоника A0/A1,
//  модель ротора и грузы); остальное - в самом файле.
//
//  Отладчик: ardprep вставляет в скетч SIM_STEP перед каждым оператором,
//  эмулятор останавливается на точках останова (F5 в редакторе), шагает
//  (F7, F8, Shift+F8, F4) и отдаёт значения переменных (окно Watch). Номер
//  строки в общей памяти - (номер файла shl 20) or строка, файлы - .ino
//  папки скетча (главный - 0, остальные по имени).
//
//  Отдельный процесс, а не DLL: скетч может писать за границы массивов, и
//  тогда упадёт только эмулятор, а не unIDE с несохранёнными файлами.
//
//  Прибор рисуется как BS10: зелёный корпус с экраном, под ним светлая
//  панель с клавиатурой (цвета и раскладка клавиш - с фото прибора).
//  Экран всегда 480x320, точка в точку: так текст UTFT читается, как на
//  приборе. Вокруг экрана - узкие зелёные поля, клавиатура подгоняется под
//  оставшуюся высоту. Показывается в отдельном окне (TArdSimWindow): в
//  правую панель unIDE прибор шириной 508 точек не помещался.
// ---------------------------------------------------------------------------

interface

uses
  {$IFDEF FPC} LCLType, {$ENDIF}
  Windows, Messages, SysUtils, Classes, Controls,
  Graphics, StdCtrls, ExtCtrls, Forms, IniFiles, UiStdCtrls, UiButton,
  UiEditCtrls, ProcRun,
  ArdSimFonts,   // шрифты UTFT из libraries для build_sim.cmd
  ArdWinShots,   // снимок экрана в .bmp (SaveScreenBmp)
  DlgFontViewer; // TUtftFont, UtftParseFile - шрифты для превью надписи

const
  ArdSimScreenW = 480;
  ArdSimScreenH = 320;
  ArdSimKeyRows = 5;
  ArdSimKeyCols = 4;
  ArdSimKeyCount = ArdSimKeyRows * ArdSimKeyCols;

  // Команды отладчика эмулятора (SimCmd* в ArdSim\src\sim_internal.h).
  // Пауза, шаг и Run to cursor во время работы - остановка на ближайшем
  // операторе (Run to cursor - на строке)
  ArdDbgPause = 1;
  ArdDbgRun = 2;
  ArdDbgInto = 3;
  ArdDbgOver = 4;
  ArdDbgOut = 5;
  ArdDbgRunTo = 6;
  // Только при запуске: дойти до строки и записать переменную (окно скетча
  // с карты окон: WinState=25 перед switch), без остановки
  ArdDbgRunToSet = 7;

type
  TArdSimTextEvent = procedure(Sender: TObject; const AText: string) of object;
  // Надпись TLabel перетащили мышью: AHash - FNV-1a имени (ArdSimNameHash),
  // ALeft, ATop - новые Left, Top
  TArdSimCtlMovedEvent = procedure(Sender: TObject; AHash: Cardinal;
    ALeft, ATop: Integer) of object;
  // Правый клик на экране прибора: AHash - TLabel под мышью (0 - нет),
  // AScreenPos - точка в координатах экрана для всплывающего меню
  TArdSimCtlMenuEvent = procedure(Sender: TObject; AHash: Cardinal;
    const AScreenPos: TPoint) of object;
  TArdSimCtlHashEvent = procedure(Sender: TObject; AHash: Cardinal) of object;
  // Щелчок по экрану при выбранной кнопке палитры (PlaceMode): AX, AY - точка
  // в пикселях экрана прибора
  TArdSimPlaceEvent = procedure(Sender: TObject; AX, AY: Integer) of object;
  // Надпись TLabel, добавленная после сборки (Paste в меню экрана):
  // эмулятор её не знает, её рисует unIDE поверх экрана, пока скетч не
  // пересобран. Значения - из объявления (Unit1.ArdSyncPhantoms)
  TArdSimPhantom = class
  public
    Name: string;
    Hash: Cardinal;          // ArdSimNameHash(Name)
    AnchorHash: Cardinal;    // видна, пока на экране эта надпись; 0 - всегда
    Left, Top, Width, Height: Integer;
    Caption: AnsiString;
    Font: TUtftFont;
    Color, FontColor, BorderColor: Cardinal;   // $RRGGBB
    Filled, Rounded, LineWidth, RectOn, Proportional, Alignment, Visible: Integer;
    Box: TRect;              // занятые точки при последней отрисовке
    Shown: Boolean;          // нарисована при последней отрисовке
  end;
  // Перетаскиваемая надпись: выбранные (Ctrl+щелчок) тащатся вместе
  TArdDragItem = record
    Hash: Cardinal;
    IsPhantom: Boolean;      // надпись до сборки (TArdSimPhantom)
    Left, Top: Integer;      // в начале
    NewLeft, NewTop: Integer;
  end;
  TArdSimSaveEvent = function(Sender: TObject): Boolean of object;
  // Строки точек останова: (номер файла shl 20) or строка с 1
  TArdDbgCodes = array of Cardinal;

  TArdSimPanel = class;

  // Прибор целиком: корпус, экран, клавиатура. Клавиши - мышью или
  // клавишами ПК (когда прибор в фокусе)
  TArdSimDevice = class(TCustomControl)
  private
    FOwnerPanel: TArdSimPanel;
    FScreenW: Integer;         // ширина экрана, точек (высота - 2/3)
    FBorder: Integer;          // зелёное поле вокруг экрана, точек
    FBodyRect: TRect;
    FPadRect: TRect;
    FScreenRect: TRect;
    FKeyRects: array[0..ArdSimKeyCount - 1] of TRect;
    FPressedKey: Integer;      // подсвеченная клавиша, -1 - нет
    FPressTimer: TTimer;
    FBuffer: TBitmap;
    procedure PressTimerTick(Sender: TObject);
    procedure ShowPressed(AKeyIdx: Integer);
    procedure DrawKey(ACanvas: TCanvas; AKeyIdx: Integer);
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
  protected
    procedure Paint; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      PosX, PosY: Integer); override;
    procedure MouseMove(Shift: TShiftState; PosX, PosY: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      PosX, PosY: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Разложить прибор по ширине AWidth; клавиатура - чтобы весь прибор
    // влез в AHeight. Результат - ширина и высота прибора
    function Arrange(AWidth, AHeight: Integer): TPoint;
    procedure PressKey(AKeyIdx: Integer);
    procedure InvalidateScreen;
  end;

  TArdSimPanel = class(TUiPanel)
  private
    FBar: TUiPanel;
    FBtnBuild: TUiButton;
    FBtnRun: TUiButton;
    FBtnStop: TUiButton;
    FBtnIni: TUiButton;
    FBtnWindow: TUiButton;
    FStatus: TUiLabel;
    FDevice: TArdSimDevice;
    FSerial: TUiMemo;
    FTimer: TTimer;
    FBuild: TProcRun;         // build_sim.cmd
    FBuildLine: string;       // недописанная строка вывода сборки
    FRunAfterBuild: Boolean;
    FSim: TProcRun;           // <скетч>_sim.exe /host:...
    FSimExe: string;
    FMapName: string;
    {$IFDEF MSWINDOWS}
    FMapping: THandle;
    FView: Pointer;
    {$ENDIF}
    FScreenVersion: Cardinal;
    FSerialRead: Cardinal;
    FPixels: array of Cardinal;   // экран в 32 бита для StretchDIBits
    FHasPicture: Boolean;
    FSketchFile: string;
    FArdSimDir: string;
    FMingwBin: string;
    FFontRoots: TStringList;  // папки libraries: шрифты UTFT для сборки
    FOnLog: TArdSimTextEvent;
    FOnOpenFile: TArdSimTextEvent;
    FOnViewFiles: TNotifyEvent;
    FDataFile: string;        // файл замера (Test.dat), выбранный в Match list
    FOnNeedSketch: TNotifyEvent;
    FOnSaveFiles: TArdSimSaveEvent;
    FOnStateChange: TNotifyEvent;
    // Отладчик: последние StopSeq и InfoSeq эмулятора, его ответ (строки
    // "S/F/L/G/W<TAB>..."), пути .ino по номерам, отправленные точки и
    // выражения Watch (для сравнения), команда при запуске
    FDbgStopSeq: Cardinal;
    FDbgInfoSeq: Cardinal;
    FDbgStopped: Boolean;
    FDbgStepping: Boolean;
    FDbgInfo: TStringList;
    FDbgFiles: TStringList;
    FDbgBreaks: string;
    FDbgWatch: string;
    FDbgStartCmd: Integer;
    FDbgStartArg: Cardinal;
    // ArdDbgRunToSet: "Имя=Значение" - строкой "=Имя=Значение" в запросе
    // Watch. FDbgRunAssign - у идущего запуска (в каждый запрос Watch)
    FDbgStartAssign: string;
    FDbgRunAssign: string;
    FLiveWatch: Boolean;
    FLiveTick: Cardinal;
    FBreakTick: Cardinal;
    FOnDbgStop: TNotifyEvent;
    FOnDbgResume: TNotifyEvent;
    FOnDbgInfo: TNotifyEvent;
    FOnDbgNeedBreaks: TNotifyEvent;
    // Клик по экрану: ждём ответа эмулятора, где нарисована надпись
    FWhereWait: Boolean;
    FWhereTick: Cardinal;
    FWhereCodes: TArdDbgCodes;
    FWhereText: string;
    FOnScreenWhere: TNotifyEvent;
    // Панель «Сигналы»: поля - ключи ardsim.ini. FSigDirty - поля правили
    // и не применили (тогда файл не перечитывается в поля)
    FSigHead: TUiButton;
    FSigPanel: TUiPanel;
    FSigTacho: TUiCheckBox;
    FSigSdFail: TUiCheckBox;   // [SD] Fail: скетч работает как без SD карты
    FSigRpm: TUiEdit;
    FSigFreq: TUiLabel;
    FSigRotor: TUiCheckBox;
    FSigAmp: array[0..1] of TUiEdit;
    FSigPhase: array[0..1] of TUiEdit;
    FSigWeights: array[0..1] of TUiEdit;
    FSigApply: TUiButton;
    FSigIni: TUiButton;   // открыть ardsim.ini (кнопка ini верхней строки скрыта в окне эмулятора)
    FSigNote: TUiLabel;
    FSigView: TUiButton;  // View files Test.dat: поиск файлов замеров (Unit1)
    FSigData: TUiCheckBox;  // [DataFile] Enabled: A0, A1 и тахометр - из файла замера
    FSigShown: Boolean;
    FSigDirty: Boolean;
    FSigLoading: Boolean;
    FSigIniAge: Integer;
    FSigIniFile: string;
    // Превью надписи другим шрифтом поверх экрана (SetTextPreview):
    // шрифты UTFT скетча (FindFont), что стереть и что нарисовать
    FFontCache: TList;           // TUtftFont всех найденных файлов
    FFontCacheSketch: string;    // для какого скетча собран
    // Все шрифты папок FontRoots со вложенными (список шрифтов
    // инспектора: и не объявленные в скетче)
    FLibFonts: TList;
    FLibFontsKey: string;        // FontRoots.Text, по которому собран
    // Превью: FPreview - пункт списка под мышью, FKept - выбранные
    // шрифты (TArdPreviewItem), каждое до перерисовки своего места скетчем
    FPreview: TObject;
    FKept: TList;
    FPhantoms: TList;            // TArdSimPhantom
    FOnCtlSelect: TArdSimCtlHashEvent;
    // Выбранная надпись TLabel (рамка на экране) и её перетаскивание
    FSelCtlHash: Cardinal;        // 0 - нет
    FWhereCtlHash: Cardinal;      // надпись под последним щелчком, 0 - нет
    FDragging: Boolean;
    FDragMoved: Boolean;
    FDragFromX, FDragFromY: Integer;
    // Ещё выбранные надписи (Ctrl+щелчок), кроме FSelCtlHash
    FSelExtra: array of Cardinal;
    // Перетаскиваемые: первая - под мышью, по ней - сетка
    FDragItems: array of TArdDragItem;
    FGridStep: Integer;          // шаг сетки при перетаскивании, 1 - без сетки
    FOnCtlMoved: TArdSimCtlMovedEvent;
    FOnCtlMenu: TArdSimCtlMenuEvent;
    // Меню правого клика ждёт ответа эмулятора (переход к строке вывода):
    // открывается после OnScreenWhere, иначе переход его закрывает
    FMenuPending: Boolean;
    FMenuHash: Cardinal;
    FMenuPos: TPoint;
    FMenuX, FMenuY: Integer;   // точка клика на экране прибора
    FMenuNear: Cardinal;       // клик мимо надписей: ближайшая показанная
    FMenuPlace: Boolean;       // ожидание - для OnPlace, а не для меню
    FPlaceMode: Boolean;
    FOnPlace: TArdSimPlaceEvent;
    procedure FireCtlMenu;
    function CtlShownEntry(AHash: Cardinal): PCardinal;
    function CtlShownBox(AEntry: PCardinal): TRect;
    function CtlHashAt(AX, AY: Integer): Cardinal;
    procedure DrawPhantoms;
    function CtlNearestHash(AX, AY: Integer; var ABox: TRect): Cardinal;
    procedure DrawCtlMarker;
    function SetCtlOverrideHash(AHash: Cardinal; AProp, AKind, ANumber: Integer;
                                const AText: string): Boolean;
    function CtlMouseDown(AX, AY: Integer; AToggle: Boolean): Boolean;
    function CtlSelected(AHash: Cardinal): Boolean;
    procedure CtlMakePrimary(AHash: Cardinal);
    procedure CtlSelToggle(AHash: Cardinal);
    function CtlPlace(AHash: Cardinal; var ALeft, ATop: Integer; var ABox: TRect;
                      var AIsPhantom: Boolean): Boolean;
    procedure CtlMoveTo(var AItem: TArdDragItem; ANewLeft, ANewTop: Integer);
    function CtlDragHas(AHash: Cardinal): Boolean;
    function SnapGrid(AValue: Integer): Integer;
    procedure CtlContextMenu(AX, AY: Integer; const AScreenPos: TPoint);
    procedure PlaceClick(AX, AY: Integer);
    function CtlSimHashAt(AX, AY: Integer; var AArea: Integer): Cardinal;
    procedure CtlMouseMove(AX, AY: Integer);
    procedure CtlMouseUp;
    function CtlOverPoint(AX, AY: Integer): Boolean;
    procedure SetSelectedControl(const AName: string);
    procedure LoadFontCache;
    procedure FreeLibFonts;
    procedure DrawPreview;
    procedure ClearAllPreviews;
    procedure BuildSignals;
    procedure SigHeadClick(Sender: TObject);
    procedure SigApplyClick(Sender: TObject);
    procedure SigChange(Sender: TObject);
    procedure SigUpdateState;
    procedure SigLoad;
    procedure SigPoll;
    procedure PollWhere;
    function DbgHeader(AIndex: Integer): Cardinal;
    procedure SetDbgHeader(AIndex: Integer; AValue: Cardinal);
    function DbgArea: PAnsiChar;
    procedure DbgReset;
    procedure WriteWatchRequest(const AText: string);
    procedure DbgEnd;
    procedure PollDebug;
    function ReadDbgText(AOffset, AMaxBytes: Integer): string;
    procedure ReadDbgInfo;
    function DbgLine(const APrefix: string; var ARest: string): Boolean;
    procedure DbgStatus;
    procedure SetShowToolbar(AValue: Boolean);
    function GetShowToolbar: Boolean;
    procedure BtnBuildClick(Sender: TObject);
    procedure BtnRunClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure BtnIniClick(Sender: TObject);
    procedure SigViewClick(Sender: TObject);
    procedure BtnWindowClick(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure LayoutControls;
    procedure Log(const AText: string);
    procedure SetStatus(const AText: string);
    procedure UpdateButtons;
    function SketchReady: Boolean;
    function SaveFiles: Boolean;
    function ExeOfSketch: string;
    function IniOfSketch: string;
    procedure StartBuild(ARunAfter: Boolean);
    procedure PollBuild;
    procedure StartSim;
    procedure StopSim;
    procedure PollSim;
    procedure FreeShared;
    function Header(AIndex: Integer): Cardinal;
    procedure SetHeader(AIndex: Integer; AValue: Cardinal);
    procedure AppendSerial(const AText: string);
  protected
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Нажатие клавиши прибора: строка 0..4, столбец 0..3
    procedure PostKey(ARow, ACol: Integer);
    // Экран прибора в прямоугольник ARect (3:2)
    procedure PaintScreen(ACanvas: TCanvas; const ARect: TRect);
    function Running: Boolean;
    function Building: Boolean;
    // Остановить эмулятор и сборку (закрытие unIDE)
    procedure StopAll;
    // То же, что кнопки панели (их можно спрятать - ShowToolbar - и
    // поставить свои, как в ряду Project unIDE)
    procedure BuildAndRun;
    procedure RunSim;
    procedure OpenIni;
    procedure OpenArdSimWindow;
    // Просмотр файлов замеров: курсор Match list встал на файл AFileName
    // (Test.dat). Пишется в ardsim.ini ([DataFile] Enabled=1, Path):
    // эмулятор за полсекунды переходит на сигнал из файла, скетч считает
    // по нему обычный замер
    procedure ShowDataFile(const AFileName: string);
    property DataFile: string read FDataFile;

    // ---- отладчик
    // Эмулятор идёт и скетч собран с отладкой (SIM_STEP)
    function DbgAvailable: Boolean;
    // Скетч стоит (точка, шаг, пауза) и ждёт команды
    function DbgStopped: Boolean;
    // Шаг отдан, скетч ещё не встал
    function DbgStepping: Boolean;
    // Строка остановки: (файл shl 20) or строка с 1
    function DbgStopCode: Cardinal;
    procedure DbgCommand(ACode: Integer; AArg: Cardinal);
    // Команда сразу после запуска (F7/F8/F4, когда эмулятор не шёл)
    procedure SetStartCommand(ACode: Integer; AArg: Cardinal);
    // Следующий запуск: дойти до строки ACode (номер эмулятора) и там
    // записать переменную: AAssign = 'WinState=25'. Окно карты окон
    procedure SetStartAssign(ACode: Cardinal; const AAssign: string);
    procedure DbgSetBreakpoints(const ACodes: TArdDbgCodes);
    // Номер .ino скетча, -1 - не файл скетча
    function DbgFileIndex(const AFileName: string): Integer;
    function DbgFileName(AIndex: Integer): string;
    // Выражения окна Watch: значения придут ответом (OnDbgInfo)
    procedure DbgSetWatch(AExprs: TStrings);
    // Значение выражения AIndex из ответа; False - ответа нет
    function DbgWatchResult(AIndex: Integer; var AValue: string): Boolean;
    // Переменная по имени: локальная функции остановки, потом глобальная
    function DbgVarValue(const AName: string; var AValue: string): Boolean;
    procedure DbgLocalNames(ANames: TStrings);
    // Функция остановки и стек вызовов ("loop <- ...")
    function DbgWhere: string;
    // Клик по экрану прибора (точка экрана 480x320): спросить эмулятор,
    // какая надпись там нарисована и какими строками. Ответ - OnScreenWhere
    procedure ScreenWhere(AX, AY: Integer);

    // ---- превью шрифта (инспектор Objects: список шрифтов)
    // Шрифт UTFT по имени массива: .c из ardsim_build\ardsim_fonts.txt,
    // папки скетча, %ARDSIM_FONTS%, замены ArdSim\fonts - в том же порядке,
    // что берёт build_sim.cmd. nil - не найден
    function FindFont(const AName: string): TUtftFont;
    // Имена всех шрифтов UTFT в папках FontRoots (со вложенными), без
    // повторов, по алфавиту. Папки читаются один раз, пока FontRoots те же
    procedure LibraryFontNames(AList: TStrings);
    // Надпись TLabel AName на экране эмулятора сейчас: текст, где он
    // нарисован (AX, AY - как UTFT::print), цвета, место текста в прежнем
    // шрифте (AClear). False - не на экране или эмулятор не сообщает
    function CtlShownText(const AName: string; var AX, AY: Integer;
      var AText: string; var AFore, ABack: TColor; var AClear: TRect): Boolean;
    // Поверх экрана эмулятора: стереть AClear цветом ABack, нарисовать
    // AText шрифтом AFont с (AX, AY), как UTFT::print. Цвета - TColor.
    // Картинка эмулятора не меняется: это только показ
    // AProportional - как PrintProp в BS10.ino (TLabel с Proportional 1):
    // знаки без пустых столбцов, промежуток UtftPropGap, пробел UtftPropSpace
    procedure SetTextPreview(AX, AY: Integer; const AText: AnsiString;
      AFont: TUtftFont; const AClear: TRect; AFore, ABack: TColor;
      ATransparent: Boolean; AProportional: Boolean = False);
    procedure ClearTextPreview;
    function PreviewShown: Boolean;
    // Превью под мышью остаётся на экране (шрифт выбран): до перерисовки
    // этого места скетчем; на том же месте прежнее оставленное заменяется
    procedure KeepTextPreview;

    // ---- подмена аргументов на лету (SIM_ARG в эмуляторе)
    // Эмулятор собран с SIM_ARG и читает таблицу
    function ArgOverrideAvailable: Boolean;
    // Объекты TLabel (BS10Controls.h): эмулятор собран с ними и читает
    // таблицу правок
    function CtlOverrideAvailable: Boolean;
    // Новое значение свойства AProp (номер поля TLabel) объекта AName:
    // AKind 1 - число ANumber, 2 - шрифт (имя массива в AText), 3 - текст
    // AText. Эмулятор сразу перерисовывает надпись
    function SetCtlOverride(const AName: string; AProp, AKind, ANumber: Integer;
                            const AText: string): Boolean;
    // Надпись TLabel, выбранная в инспекторе: рамка вокруг неё на экране,
    // её можно тащить мышью. '' - нет
    property SelectedControl: string write SetSelectedControl;
    // Выбранные надписи: 0 - FSelCtlHash (рамка с жёлтыми углами), дальше -
    // добавленные Ctrl+щелчком
    function SelectedCount: Integer;
    function SelectedHash(AIndex: Integer): Cardinal;
    // Занятые точки показанной надписи (или надписи до сборки)
    function CtlBoxOf(AHash: Cardinal; var ABox: TRect): Boolean;
    // Выравнивание выбранных: 0 - по левому краю, 1 - по правому, 2 - по
    // верху, 3 - по низу, 4 - равные интервалы по вертикали, 5 - по
    // горизонтали. Результат - сколько надписей сдвинуто (OnCtlMoved)
    function AlignSelected(AMode: Integer): Integer;
    property GridStep: Integer read FGridStep write FGridStep;
    property OnCtlMoved: TArdSimCtlMovedEvent read FOnCtlMoved write FOnCtlMoved;
    property OnCtlMenu: TArdSimCtlMenuEvent read FOnCtlMenu write FOnCtlMenu;
    // Надписи, добавленные после сборки (TArdSimPhantom): SetPhantom
    // забирает объект себе (та же Name - замена), RemovePhantom по имени
    procedure SetPhantom(APhantom: TArdSimPhantom);
    procedure RemovePhantom(const AName: string);
    procedure ClearPhantoms;
    function PhantomByHash(AHash: Cardinal): TArdSimPhantom;
    function PhantomCount: Integer;
    // exe эмулятора скетча (время файла - собран ли после Paste)
    function SimExeFile: string;
    // Счётчик копий экрана из эмулятора (0 после запуска - картинки ещё
    // нет) и запись экрана в .bmp (ArdWinShots): идёт - из общей памяти
    function ScreenVersion: Cardinal;
    function SaveScreenBmp(const AFileName: string): Boolean;
    // Щелчок по надписи-фантому: строки отрисовки у эмулятора нет, Unit1
    // ставит курсор на её вывод сам
    property OnCtlSelect: TArdSimCtlHashEvent read FOnCtlSelect write FOnCtlSelect;
    // Аргумент AArgIdx вызова AName (метод UTFT или функция скетча) в
    // строке ALine (с 1) файла AFileIdx, AOccurrence-го с таким именем в
    // строке: число ANumber или шрифт AFont (имя массива, AFont <> '').
    // False - таблица полна или эмулятор её не читает
    function SetArgOverride(AFileIdx, ALine: Integer; const AName: string;
      AOccurrence, AArgIdx: Integer; ANumber: Integer;
      const AFont: string): Boolean;
    // Ответ: строки (файл shl 20 or строка с 1) - оператор, который
    // нарисовал надпись, затем вызовы, которые к нему привели (наружу);
    // пусто - в этой точке надписи нет
    property WhereCodes: TArdDbgCodes read FWhereCodes;
    property WhereText: string read FWhereText;
    // TLabel под последним щелчком по экрану (ArdSimNameHash имени), 0 - нет
    property WhereCtlHash: Cardinal read FWhereCtlHash;
    // Последний правый клик на экране (OnCtlMenu): точка в пикселях экрана
    // прибора; MenuNearHash - ближайшая показанная надпись, если клик был
    // мимо надписей (по ней Paste выбирает функцию вывода), иначе 0
    property MenuX: Integer read FMenuX;
    property MenuY: Integer read FMenuY;
    property MenuNearHash: Cardinal read FMenuNear;
    // Выбрана кнопка палитры: левый щелчок по экрану не выделяет надпись,
    // а вызывает OnPlace (MenuX, MenuY, MenuNearHash - как у меню; курсор -
    // на вывод ближайшей надписи, OnPlace - после перехода к строке)
    property PlaceMode: Boolean read FPlaceMode write FPlaceMode;
    property OnPlace: TArdSimPlaceEvent read FOnPlace write FOnPlace;
    property OnScreenWhere: TNotifyEvent read FOnScreenWhere write FOnScreenWhere;
    // Окно Watch видно: значения обновляются и пока скетч идёт
    property LiveWatch: Boolean read FLiveWatch write FLiveWatch;
    property OnDbgStop: TNotifyEvent read FOnDbgStop write FOnDbgStop;
    property OnDbgResume: TNotifyEvent read FOnDbgResume write FOnDbgResume;
    property OnDbgInfo: TNotifyEvent read FOnDbgInfo write FOnDbgInfo;
    // Раз в 250 мс, пока эмулятор идёт, и перед запуском: Unit1 отдаёт
    // точки останова (DbgSetBreakpoints)
    property OnDbgNeedBreaks: TNotifyEvent read FOnDbgNeedBreaks write FOnDbgNeedBreaks;

    property ShowToolbar: Boolean read GetShowToolbar write SetShowToolbar;
    // Сборка или эмулятор запустились / закончились
    property OnStateChange: TNotifyEvent read FOnStateChange write FOnStateChange;
    // .ino, который собирается; задаёт Unit1 (OnNeedSketch перед сборкой)
    property SketchFile: string read FSketchFile write FSketchFile;
    // Папка ArdSim (с build_sim.cmd); '' - искать рядом с unIDE
    property ArdSimDir: string read FArdSimDir write FArdSimDir;
    // Папка bin своего MinGW unIDE; '' - build_sim.cmd ищет сам
    property MingwBin: string read FMingwBin write FMingwBin;
    // Папки libraries (со вложенными): там ищутся .c шрифтов UTFT, которые
    // объявлены в скетче (ArdSimFonts); задаёт Unit1 в OnNeedSketch
    property FontRoots: TStringList read FFontRoots;
    property OnLog: TArdSimTextEvent read FOnLog write FOnLog;
    property OnOpenFile: TArdSimTextEvent read FOnOpenFile write FOnOpenFile;
    // Кнопка "View files Test.dat" панели "Сигналы": Unit1 открывает окно
    // поиска файлов с маской test.dat
    property OnViewFiles: TNotifyEvent read FOnViewFiles write FOnViewFiles;
    property OnNeedSketch: TNotifyEvent read FOnNeedSketch write FOnNeedSketch;
    // Перед сборкой и запуском: Unit1 сохраняет изменённые вкладки и проект;
    // False - не всё сохранено, сборки и запуска нет
    property OnSaveFiles: TArdSimSaveEvent read FOnSaveFiles write FOnSaveFiles;
  end;

  // Отдельное окно эмулятора. При первом показе встаёт у правого края
  // главного окна на всю его высоту (поверх панели Git); дальше - где его
  // оставили. Закрытие окна останавливает эмулятор
  TArdSimWindow = class(TForm)
  private
    FPanel: TArdSimPanel;
    FMainForm: TCustomForm;
    FPlaced: Boolean;
    FOnPlaced: TNotifyEvent;
    FOnHidden: TNotifyEvent;
    {$IFDEF FPC}
    FPlaceTimer: TTimer;
    {$ENDIF}
    procedure WindowClose(Sender: TObject; var Action: TCloseAction);
    procedure WMExitSizeMove(var Message: TMessage); message WM_EXITSIZEMOVE;
    {$IFDEF FPC}
    // LCL win32 не передаёт WM_EXITSIZEMOVE в WindowProc (нет в списке
    // win32callback.inc): конец перемещения ловится по WM_MOVE / WM_SIZE и
    // таймеру, который ждёт отпускания левой кнопки мыши
    procedure WMMove(var Message: TMessage); message WM_MOVE;
    procedure WMSize(var Message: TMessage); message WM_SIZE;
    procedure PlaceNoted;
    procedure PlaceTimerTick(Sender: TObject);
    {$ENDIF}
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateFor(AMainForm: TCustomForm);
    procedure ShowAtRight;
    property Panel: TArdSimPanel read FPanel;
    // Окно показано или передвинуто / изменён размер: главное окно
    // подгоняет под него редактор
    property OnPlaced: TNotifyEvent read FOnPlaced write FOnPlaced;
    // Окно закрыто
    property OnHidden: TNotifyEvent read FOnHidden write FOnHidden;
  end;

// Папка ArdSim рядом с unIDE: <exe>\ArdSim, <exe>\..\ArdSim; нет - ''
function ArdSimFindDir: string;
// FNV-1a имени: так эмулятор узнаёт объекты TLabel
function ArdSimNameHash(const AName: string): Cardinal;

implementation

const
  HostMagic = $4D495341;    // 'ASIM'
  HostLayout = 2;
  HdrMagic = 0;
  HdrLayout = 1;
  HdrHostPid = 2;
  HdrSimPid = 3;
  HdrScreenVersion = 4;
  HdrKeyWrite = 5;
  HdrKeyRead = 6;
  HdrSerialWrite = 7;
  HdrState = 8;
  HdrStopRequest = 9;
  HdrArgTable = 10;     // эмулятор: 1 - читает таблицу подмен аргументов
  HdrKeyQueue = 16;
  HdrCtlTable = 11;     // эмулятор: 1 - читает таблицу правок объектов TLabel
  KeyQueueSize = 16;
  HeaderBytes = 128;
  ScreenBytes = ArdSimScreenW * ArdSimScreenH * 2;
  SerialRingBytes = 65536;
  // Область отладчика (sim_internal.h): заголовок 64 слова, точки
  // останова, выражения Watch, пути .ino, ответ эмулятора
  DbgOffset = HeaderBytes + ScreenBytes + SerialRingBytes;
  DbgCmdSeq = 0;
  DbgCmdCode = 1;
  DbgCmdArg = 2;
  DbgCmdDone = 3;
  DbgState = 4;
  DbgStopCodeIdx = 5;
  DbgStopSeq = 6;
  DbgBpVersion = 7;
  DbgBpCount = 8;
  DbgWatchSeq = 9;
  DbgInfoSeq = 10;
  DbgInfoBytes = 11;
  DbgInstrumented = 12;
  // «где нарисована надпись»: клик по экрану (sim_internal.h, SimDbgWhere*)
  DbgWhereSeq = 13;
  DbgWhereXY = 14;
  DbgWhereDone = 15;
  DbgWhereCount = 16;
  DbgWhereCodes = 17;
  DbgWhereMax = 6;
  DbgWhereText = 23;
  DbgWhereTextBytes = (64 - DbgWhereText) * 4;
  DbgWhereTimeoutMs = 1500;
  DbgMaxBreaks = 1024;
  DbgBreakOffset = 256;
  DbgWatchReqOffset = 4352;
  DbgWatchReqBytes = 4096;
  DbgFilesOffset = 8448;
  DbgFilesBytes = 4096;
  DbgInfoOffset = 12544;
  DbgInfoMax = 65536;
  DbgAreaBytes = DbgInfoOffset + DbgInfoMax;
  // Подмены аргументов (SIM_ARG, sim_internal.h SimArg*): после области
  // отладчика. Число записей, с 16-го байта записи по 64 байта: code,
  // hash, occurrence, index, kind (1 число, 2 шрифт), number, font[40]
  ArgOffset = DbgOffset + DbgAreaBytes;
  ArgEntryBytes = 64;
  ArgMaxEntries = 256;
  ArgFontChars = 40;
  ArgTableBytes = 16 + ArgEntryBytes * ArgMaxEntries;
  // Правки объектов TLabel (sim_internal.h SimCtl*): после подмен. Число
  // записей, версия (+1 после каждой правки); с 16-го байта записи по 128
  // байт: hash имени, номер свойства, kind (1 число, 2 шрифт, 3 текст),
  // number, text[112]
  CtlOffset = ArgOffset + ArgTableBytes;
  CtlEntryBytes = 128;
  CtlMaxEntries = 128;
  CtlTextChars = CtlEntryBytes - 16;
  // Что надписи показывают сейчас (пишет эмулятор): от CtlShownOffset
  // таблицы - число очисток экрана сейчас, число объектов; с +16 записи
  // по 32 байта в порядке регистрации: hash имени, число очисток при
  // последнем выводе ($FFFFFFFF - не выводилась), int16 Left, Top как
  // нарисованы, int16 рамка занятых точек: левый, верхний, правый, нижний
  CtlShownOffset = 16 + CtlEntryBytes * CtlMaxEntries;
  CtlShownBytes = 128;
  CtlShownTextOffset = 32;
  CtlMaxControls = 1024;
  CtlTableBytes = CtlShownOffset + 16 + CtlShownBytes * CtlMaxControls;
  SharedBytes = CtlOffset + CtlTableBytes;
  SerialMaxChars = 60000;

  // Корпус: зелёные поля вокруг экрана 480x320, точек. Обычно
  // BodyBorder; в низком окне - меньше, но не меньше BodyBorderMin
  BodyBorder = 40;
  BodyBorderMin = 14;
  // Клавиатура (по фото), в долях ширины экрана; умножаются на PadK -
  // долю, при которой клавиатура влезает по высоте, не больше PadKMax
  // (на 30% меньше, чем по фото)
  PadKMax = 0.7;
  PadWidthK = 1.22;       // ширина панели клавиатуры
  PadTopK = 0.14;         // от верха панели до первого ряда
  PadBottomK = 0.07;      // под последним рядом
  KeyWidthK = 0.23;
  KeyHeightK = 0.165;
  KeyPitchXK = 0.274;
  KeyPitchYK = 0.195;
  MinBorder = 8;          // поля панели клавиатуры вокруг клавиш
  MinKeyHeight = 20;      // клавиши не мельче, даже если не влезают
  RimWidth = 3;           // чёрный кант корпуса

  // Цвета (TColor - $00BBGGRR)
  ClrRim = $00202020;
  ClrBody = $007A9E10;      // тёмно-зелёный корпус
  ClrPad = $00B0D676;       // светло-зелёная панель клавиатуры
  ClrBezel = $00303030;     // рамка вокруг дисплея
  ClrKeyWhite = $00F2F2F2;
  ClrKeyYellow = $001ED2FF;
  ClrKeyRed = $00463CDE;
  ClrKeyText = $00303030;
  ClrKeyEdge = $00808080;

  KeyCaptions: array[0..ArdSimKeyRows - 1, 0..ArdSimKeyCols - 1] of string = (
    ('F1', 'F2', '#', '*'),
    ('1', '2', '3', '^'),
    ('4', '5', '6', 'v'),
    ('7', '8', '9', 'Esc'),
    ('<', '0', '>', 'Ent'));

type
  TKeyLook = (klWhite, klYellow, klRed, klOval);

var
  MapCounter: Integer = 0;

// Папка ArdSim: рядом с unIDE или на уровень выше. Если есть обе (старая
// копия в Output и папка репозитория), берётся та, где build_sim.cmd новее:
// иначе сборка шла со старыми заголовками и ardprep.
function ArdSimFindDir: string;
var
  ExeDir, NearDir, UpperDir: string;
  NearOk, UpperOk: Boolean;
begin
  ExeDir := ExtractFilePath(ParamStr(0));
  NearDir := ExeDir + 'ArdSim\';
  UpperDir := ExpandFileName(ExeDir + '..\ArdSim\');
  NearOk := FileExists(NearDir + 'build_sim.cmd');
  UpperOk := FileExists(UpperDir + 'build_sim.cmd');
  if NearOk and UpperOk then
  begin
    if FileAge(UpperDir + 'build_sim.cmd') > FileAge(NearDir + 'build_sim.cmd') then
      Result := UpperDir
    else
      Result := NearDir;
  end
  else if NearOk then
    Result := NearDir
  else if UpperOk then
    Result := UpperDir
  else
    Result := '';
end;

function KeyLookOf(AKeyIdx: Integer): TKeyLook;
begin
  case AKeyIdx of
    0, 1: Result := klYellow;     // F1 F2
    2, 3: Result := klRed;        // # *
    15, 19: Result := klOval;     // Esc Ent
  else
    Result := klWhite;
  end;
end;

// Темнее на AShift (подсветка нажатой клавиши)
function DarkerColor(AColor: TColor; AShift: Integer): TColor;
var
  Red, Green, Blue: Integer;
begin
  AColor := ColorToRGB(AColor);
  Red := (AColor and $FF) - AShift;
  Green := ((AColor shr 8) and $FF) - AShift;
  Blue := ((AColor shr 16) and $FF) - AShift;
  if Red < 0 then Red := 0;
  if Green < 0 then Green := 0;
  if Blue < 0 then Blue := 0;
  Result := TColor(Red or (Green shl 8) or (Blue shl 16));
end;

// ---------------------------------------------------------------------------
//  TArdSimDevice
// ---------------------------------------------------------------------------

constructor TArdSimDevice.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  TabStop := True;
  ShowHint := True;
  ControlStyle := ControlStyle + [csOpaque];
  FPressedKey := -1;
  FScreenW := ArdSimScreenW;
  FBorder := BodyBorder;
  FBuffer := TBitmap.Create;
  FPressTimer := TTimer.Create(Self);
  FPressTimer.Enabled := False;
  FPressTimer.Interval := 150;
  FPressTimer.OnTimer := PressTimerTick;
end;

destructor TArdSimDevice.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

// Сверху вниз: корпус (поля и экран 480x320), под ним панель клавиатуры.
// Прибор - по центру AWidth (не уже корпуса). Чтобы прибор влез в
// AHeight, сначала уменьшается клавиатура (PadK <= PadKMax, клавиши не
// ниже MinKeyHeight), потом поля корпуса (до BodyBorderMin). Экран не
// меняется
function TArdSimDevice.Arrange(AWidth, AHeight: Integer): TPoint;
var
  BodyW, BodyH, DeviceW, BodyLeft, PadW, PadLeft, PadTop: Integer;
  GridW, GridLeft, GridTop, KeyW, KeyH, PitchX, PitchY: Integer;
  KeyRow, KeyCol, PadUnit, PadFullH: Integer;
  PadK, PadMinK: Double;
begin
  FScreenW := ArdSimScreenW;
  // высота клавиатуры при PadK = 1, самая малая доля и доля, при которой
  // клавиатура влезает с полными полями
  PadFullH := Round(ArdSimScreenW * (PadTopK + PadBottomK + 4 * KeyPitchYK +
                                     KeyHeightK));
  PadMinK := MinKeyHeight / (ArdSimScreenW * KeyHeightK);
  FBorder := BodyBorder;
  PadK := PadKMax;
  if AHeight > 0 then
  begin
    if ArdSimScreenH + 2 * FBorder + PadK * PadFullH > AHeight then
      PadK := (AHeight - ArdSimScreenH - 2 * FBorder) / PadFullH;
    if PadK < PadMinK then
    begin
      PadK := PadMinK;
      FBorder := (AHeight - ArdSimScreenH - Round(PadK * PadFullH)) div 2;
      if FBorder > BodyBorder then
        FBorder := BodyBorder;
      if FBorder < BodyBorderMin then
        FBorder := BodyBorderMin;
    end;
  end;
  BodyW := ArdSimScreenW + 2 * FBorder;
  BodyH := ArdSimScreenH + 2 * FBorder;
  DeviceW := AWidth;
  if DeviceW < BodyW then
    DeviceW := BodyW;
  BodyLeft := (DeviceW - BodyW) div 2;
  FBodyRect := Rect(BodyLeft, 0, BodyLeft + BodyW, BodyH);
  FScreenRect := Rect(BodyLeft + FBorder, FBorder,
                      BodyLeft + FBorder + ArdSimScreenW,
                      FBorder + ArdSimScreenH);

  PadUnit := Round(ArdSimScreenW * PadK);
  KeyW := Round(PadUnit * KeyWidthK);
  KeyH := Round(PadUnit * KeyHeightK);
  PitchX := Round(PadUnit * KeyPitchXK);
  PitchY := Round(PadUnit * KeyPitchYK);
  // низкие клавиши - не уже, чем в 1.4 раза их высоты (иначе узкие столбики)
  if KeyW < KeyH * 14 div 10 then
  begin
    KeyW := KeyH * 14 div 10;
    if PitchX < KeyW + 6 then
      PitchX := KeyW + 6;
  end;
  GridW := 3 * PitchX + KeyW;
  PadW := Round(PadUnit * PadWidthK);
  if PadW < GridW + 2 * MinBorder then
    PadW := GridW + 2 * MinBorder;
  if PadW > BodyW then
    PadW := BodyW;
  PadLeft := (DeviceW - PadW) div 2;
  PadTop := FBodyRect.Bottom - RimWidth;
  GridTop := FBodyRect.Bottom + Round(PadUnit * PadTopK);
  GridLeft := PadLeft + (PadW - GridW) div 2;
  FPadRect := Rect(PadLeft, PadTop, PadLeft + PadW,
                   GridTop + 4 * PitchY + KeyH + Round(PadUnit * PadBottomK));
  for KeyRow := 0 to ArdSimKeyRows - 1 do
    for KeyCol := 0 to ArdSimKeyCols - 1 do
      FKeyRects[KeyRow * ArdSimKeyCols + KeyCol] :=
        Rect(GridLeft + KeyCol * PitchX, GridTop + KeyRow * PitchY,
             GridLeft + KeyCol * PitchX + KeyW, GridTop + KeyRow * PitchY + KeyH);
  Result := Point(DeviceW, FPadRect.Bottom + 1);
end;

procedure TArdSimDevice.InvalidateScreen;
var
  Area: TRect;
begin
  if not HandleAllocated then
    Exit;
  Area := FScreenRect;
  InvalidateRect(Handle, @Area, False);
end;

procedure TArdSimDevice.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  // стрелки, Enter и Esc - прибору, а не переходу между полями
  Message.Result := DLGC_WANTARROWS or DLGC_WANTALLKEYS or DLGC_WANTCHARS;
end;

procedure TArdSimDevice.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TArdSimDevice.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  Invalidate;
end;

procedure TArdSimDevice.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  Invalidate;
end;

procedure TArdSimDevice.PressTimerTick(Sender: TObject);
var
  KeyIdx: Integer;
  Area: TRect;
begin
  FPressTimer.Enabled := False;
  KeyIdx := FPressedKey;
  FPressedKey := -1;
  if (KeyIdx >= 0) and HandleAllocated then
  begin
    Area := FKeyRects[KeyIdx];
    InvalidateRect(Handle, @Area, False);
  end;
end;

procedure TArdSimDevice.ShowPressed(AKeyIdx: Integer);
var
  Area: TRect;
begin
  if FPressedKey >= 0 then
    PressTimerTick(nil);
  FPressedKey := AKeyIdx;
  if HandleAllocated then
  begin
    Area := FKeyRects[AKeyIdx];
    InvalidateRect(Handle, @Area, False);
  end;
  FPressTimer.Enabled := False;
  FPressTimer.Enabled := True;
end;

procedure TArdSimDevice.PressKey(AKeyIdx: Integer);
begin
  if (AKeyIdx < 0) or (AKeyIdx >= ArdSimKeyCount) then
    Exit;
  ShowPressed(AKeyIdx);
  if FOwnerPanel <> nil then
    FOwnerPanel.PostKey(AKeyIdx div ArdSimKeyCols, AKeyIdx mod ArdSimKeyCols);
end;

procedure TArdSimDevice.MouseDown(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
var
  KeyIdx: Integer;
  HitPoint: TPoint;
begin
  inherited;
  if CanFocus then
    SetFocus;
  HitPoint := Point(PosX, PosY);
  if Button <> mbLeft then
    Exit;
  // экран: где в скетче нарисована надпись под мышью; надпись TLabel -
  // сразу рамка, её можно тащить
  if PtInRect(FScreenRect, HitPoint) and (FOwnerPanel <> nil) and FOwnerPanel.PlaceMode then
  begin
    FOwnerPanel.PlaceClick(PosX - FScreenRect.Left, PosY - FScreenRect.Top);
    Exit;
  end;
  if PtInRect(FScreenRect, HitPoint) and (FOwnerPanel <> nil) then
  begin
    FOwnerPanel.CtlMouseDown(PosX - FScreenRect.Left, PosY - FScreenRect.Top,
                             ssCtrl in Shift);
    // Ctrl+щелчок снял выбор - к строке вывода не переходить
    if (FOwnerPanel.WhereCtlHash <> 0) and
       not FOwnerPanel.CtlSelected(FOwnerPanel.WhereCtlHash) then
      Exit;
    if FOwnerPanel.PhantomByHash(FOwnerPanel.WhereCtlHash) <> nil then
    begin
      if Assigned(FOwnerPanel.OnCtlSelect) then
        FOwnerPanel.OnCtlSelect(FOwnerPanel, FOwnerPanel.WhereCtlHash);
    end
    else
      FOwnerPanel.ScreenWhere(PosX - FScreenRect.Left, PosY - FScreenRect.Top);
    Exit;
  end;
  for KeyIdx := 0 to ArdSimKeyCount - 1 do
    if PtInRect(FKeyRects[KeyIdx], HitPoint) then
    begin
      PressKey(KeyIdx);
      Exit;
    end;
end;

procedure TArdSimDevice.MouseMove(Shift: TShiftState; PosX, PosY: Integer);
begin
  inherited;
  if FOwnerPanel = nil then
    Exit;
  if FOwnerPanel.FDragging then
    FOwnerPanel.CtlMouseMove(PosX - FScreenRect.Left, PosY - FScreenRect.Top)
  else if FOwnerPanel.PlaceMode and PtInRect(FScreenRect, Point(PosX, PosY)) then
    Cursor := crCross
  else if PtInRect(FScreenRect, Point(PosX, PosY)) and
          FOwnerPanel.CtlOverPoint(PosX - FScreenRect.Left, PosY - FScreenRect.Top) then
    Cursor := crSizeAll
  else
    Cursor := crDefault;
end;

procedure TArdSimDevice.MouseUp(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
begin
  inherited;
  if (Button = mbLeft) and (FOwnerPanel <> nil) and FOwnerPanel.FDragging then
    FOwnerPanel.CtlMouseUp;
  // Правый клик на экране: меню Copy / Cut / Paste / Delete для TLabel -
  // после отпускания кнопки, как контекстное меню Windows
  if (Button = mbRight) and (FOwnerPanel <> nil) and
     PtInRect(FScreenRect, Point(PosX, PosY)) then
    FOwnerPanel.CtlContextMenu(PosX - FScreenRect.Left, PosY - FScreenRect.Top,
      ClientToScreen(Point(PosX, PosY)));
end;

// Клавиши ПК -> клавиатура прибора (как в окне ArdSim, sim_window.cpp)
procedure TArdSimDevice.KeyDown(var Key: Word; Shift: TShiftState);
var
  KeyIdx: Integer;
begin
  inherited;
  // Shift+3 / Shift+8 - это '#' и '*', они придут в KeyPress
  if (ssShift in Shift) and (Key >= Ord('0')) and (Key <= Ord('9')) then
    Exit;
  case Key of
    VK_F1: KeyIdx := 0;
    VK_F2: KeyIdx := 1;
    VK_MULTIPLY: KeyIdx := 3;
    Ord('1'), VK_NUMPAD1: KeyIdx := 4;
    Ord('2'), VK_NUMPAD2: KeyIdx := 5;
    Ord('3'), VK_NUMPAD3: KeyIdx := 6;
    VK_UP: KeyIdx := 7;
    Ord('4'), VK_NUMPAD4: KeyIdx := 8;
    Ord('5'), VK_NUMPAD5: KeyIdx := 9;
    Ord('6'), VK_NUMPAD6: KeyIdx := 10;
    VK_DOWN: KeyIdx := 11;
    Ord('7'), VK_NUMPAD7: KeyIdx := 12;
    Ord('8'), VK_NUMPAD8: KeyIdx := 13;
    Ord('9'), VK_NUMPAD9: KeyIdx := 14;
    VK_ESCAPE, VK_BACK: KeyIdx := 15;
    VK_LEFT: KeyIdx := 16;
    Ord('0'), VK_NUMPAD0: KeyIdx := 17;
    VK_RIGHT: KeyIdx := 18;
    VK_RETURN: KeyIdx := 19;
  else
    KeyIdx := -1;
  end;
  if KeyIdx >= 0 then
  begin
    PressKey(KeyIdx);
    Key := 0;
  end;
end;

procedure TArdSimDevice.KeyPress(var Key: Char);
begin
  inherited;
  if Key = '#' then
  begin
    PressKey(2);
    Key := #0;
  end
  else if Key = '*' then
  begin
    PressKey(3);
    Key := #0;
  end;
end;

// Одна клавиша: цвет и форма как на приборе; стрелки - треугольником
procedure TArdSimDevice.DrawKey(ACanvas: TCanvas; AKeyIdx: Integer);
var
  Area: TRect;
  Look: TKeyLook;
  Fill, TextColor: TColor;
  Caption: string;
  KeyW, KeyH, MidX, MidY, ArrowLen, ArrowHalf, Corner: Integer;
  TextSize: TSize;
  Arrow: array[0..2] of TPoint;
  ArrowDir: Integer;   // 0 вверх, 1 вниз, 2 влево, 3 вправо, -1 не стрелка
begin
  Area := FKeyRects[AKeyIdx];
  KeyW := Area.Right - Area.Left;
  KeyH := Area.Bottom - Area.Top;
  Look := KeyLookOf(AKeyIdx);
  case Look of
    klYellow: Fill := ClrKeyYellow;
    klRed, klOval: Fill := ClrKeyRed;
  else
    Fill := ClrKeyWhite;
  end;
  if AKeyIdx = FPressedKey then
    Fill := DarkerColor(Fill, 70);
  if Look = klOval then
    TextColor := clWhite
  else
    TextColor := ClrKeyText;

  ACanvas.Pen.Color := ClrKeyEdge;
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := Fill;
  if Look = klOval then
  begin
    ACanvas.Pen.Color := DarkerColor(Fill, 40);
    ACanvas.Ellipse(Area.Left, Area.Top, Area.Right, Area.Bottom);
  end
  else
  begin
    Corner := KeyH div 4;
    ACanvas.RoundRect(Area.Left, Area.Top, Area.Right, Area.Bottom,
                      Corner, Corner);
  end;

  MidX := (Area.Left + Area.Right) div 2;
  MidY := (Area.Top + Area.Bottom) div 2;
  Caption := KeyCaptions[AKeyIdx div ArdSimKeyCols, AKeyIdx mod ArdSimKeyCols];
  case AKeyIdx of
    7: ArrowDir := 0;
    11: ArrowDir := 1;
    16: ArrowDir := 2;
    18: ArrowDir := 3;
  else
    ArrowDir := -1;
  end;
  if ArrowDir >= 0 then
  begin
    ArrowLen := KeyH * 2 div 5;
    ArrowHalf := ArrowLen div 2;
    case ArrowDir of
      0: begin
           Arrow[0] := Point(MidX, MidY - ArrowHalf);
           Arrow[1] := Point(MidX - ArrowHalf, MidY + ArrowHalf);
           Arrow[2] := Point(MidX + ArrowHalf, MidY + ArrowHalf);
         end;
      1: begin
           Arrow[0] := Point(MidX, MidY + ArrowHalf);
           Arrow[1] := Point(MidX - ArrowHalf, MidY - ArrowHalf);
           Arrow[2] := Point(MidX + ArrowHalf, MidY - ArrowHalf);
         end;
      2: begin
           Arrow[0] := Point(MidX - ArrowHalf, MidY);
           Arrow[1] := Point(MidX + ArrowHalf, MidY - ArrowHalf);
           Arrow[2] := Point(MidX + ArrowHalf, MidY + ArrowHalf);
         end;
    else
      Arrow[0] := Point(MidX + ArrowHalf, MidY);
      Arrow[1] := Point(MidX - ArrowHalf, MidY - ArrowHalf);
      Arrow[2] := Point(MidX - ArrowHalf, MidY + ArrowHalf);
    end;
    ACanvas.Pen.Color := TextColor;
    ACanvas.Brush.Color := TextColor;
    ACanvas.Polygon(Arrow);
    Exit;
  end;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Name := 'Arial';
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := TextColor;
  ACanvas.Font.Height := -(KeyH * 11 div 20);
  if ACanvas.Font.Height > -8 then
    ACanvas.Font.Height := -8;
  TextSize := ACanvas.TextExtent(Caption);
  // широкие подписи (Esc, Ent) - помельче, чтобы влезли в овал
  if TextSize.cx > KeyW * 4 div 5 then
  begin
    ACanvas.Font.Height := ACanvas.Font.Height * (KeyW * 4 div 5) div TextSize.cx;
    TextSize := ACanvas.TextExtent(Caption);
  end;
  ACanvas.TextOut(MidX - TextSize.cx div 2, MidY - TextSize.cy div 2, Caption);
  ACanvas.Brush.Style := bsSolid;
end;

procedure TArdSimDevice.Paint;
var
  Draw: TCanvas;
  Corner, KeyIdx: Integer;
  Bezel: TRect;
begin
  if (FBuffer.Width <> ClientWidth) or (FBuffer.Height <> ClientHeight) then
  begin
    FBuffer.Width := ClientWidth;
    FBuffer.Height := ClientHeight;
  end;
  Draw := FBuffer.Canvas;
  // фон - как у панели вокруг
  Draw.Brush.Style := bsSolid;
  Draw.Brush.Color := Color;
  Draw.FillRect(ClientRect);

  // панель клавиатуры (под корпусом, её верх закрывает корпус)
  Corner := (FPadRect.Right - FPadRect.Left) div 12;
  Draw.Pen.Color := ClrRim;
  Draw.Pen.Width := RimWidth;
  Draw.Brush.Color := ClrPad;
  Draw.RoundRect(FPadRect.Left + 1, FPadRect.Top + 1, FPadRect.Right - 1,
                 FPadRect.Bottom - 1, Corner, Corner);
  // корпус
  Corner := FBorder * 2;   // скругление не заходит на экран
  Draw.Brush.Color := ClrBody;
  Draw.RoundRect(FBodyRect.Left + 1, FBodyRect.Top + 1, FBodyRect.Right - 1,
                 FBodyRect.Bottom - 1, Corner, Corner);
  Draw.Pen.Width := 1;
  // рамка дисплея
  Bezel := FScreenRect;
  InflateRect(Bezel, 3, 3);
  Draw.Brush.Color := ClrBezel;
  Draw.FillRect(Bezel);
  if FOwnerPanel <> nil then
    FOwnerPanel.PaintScreen(Draw, FScreenRect);
  if Focused then
  begin
    // в фокусе: клавиши ПК идут прибору
    Draw.Brush.Color := clHighlight;
    Draw.FrameRect(Bezel);
  end;
  for KeyIdx := 0 to ArdSimKeyCount - 1 do
    DrawKey(Draw, KeyIdx);
  Canvas.Draw(0, 0, FBuffer);
end;

// ---------------------------------------------------------------------------
//  TArdSimPanel
// ---------------------------------------------------------------------------

constructor TArdSimPanel.Create(AOwner: TComponent);

  function MakeButton(AParent: TWinControl; const ACaption, AHint: string;
    AClick: TNotifyEvent): TUiButton;
  begin
    Result := TUiButton.Create(Self);
    Result.Parent := AParent;
    Result.Caption := ACaption;
    Result.Hint := AHint;
    Result.ShowHint := True;
    Result.OnClick := AClick;
    Result.TabStop := False;
  end;

begin
  inherited Create(AOwner);
  FGridStep := 1;
  BevelOuter := bvNone;
  Caption := '';
  {$IFDEF MSWINDOWS}
  FMapping := 0;
  FView := nil;
  {$ENDIF}
  SetLength(FPixels, ArdSimScreenW * ArdSimScreenH);
  FDbgInfo := TStringList.Create;
  FFontRoots := TStringList.Create;
  FDbgFiles := TStringList.Create;

  FBar := TUiPanel.Create(Self);
  FBar.Parent := Self;
  FBar.BevelOuter := bvNone;
  FBar.Caption := '';
  FBtnBuild := MakeButton(FBar, 'Build',
    'Собрать скетч под ПК (ArdSim\build_sim.cmd, MinGW g++) и запустить',
    BtnBuildClick);
  FBtnRun := MakeButton(FBar, 'Run', 'Запустить собранный скетч без сборки',
    BtnRunClick);
  FBtnStop := MakeButton(FBar, 'Stop', 'Остановить эмулятор', BtnStopClick);
  FBtnIni := MakeButton(FBar, 'ini',
    'ardsim.ini - сигналы, тахометр, модель ротора. Эмулятор перечитывает ' +
    'его после сохранения', BtnIniClick);
  FBtnWindow := MakeButton(FBar, 'Окно',
    'Запустить собранный скетч в отдельном окне ArdSim (с панелью сигналов)',
    BtnWindowClick);
  FStatus := TUiLabel.Create(Self);
  FStatus.Parent := Self;
  FStatus.AutoSize := False;
  FStatus.Caption := '';

  FDevice := TArdSimDevice.Create(Self);
  FDevice.FOwnerPanel := Self;
  FDevice.Parent := Self;
  FDevice.Hint := 'Щёлкните по прибору, чтобы клавиши ПК работали как ' +
    'клавиатура: 0-9, F1, F2, #, *, стрелки, Enter, Esc';

  BuildSignals;

  FSerial := TUiMemo.Create(Self);
  FSerial.Parent := Self;
  FSerial.ReadOnly := True;
  FSerial.ScrollBars := ssVertical;
  FSerial.WordWrap := False;
  FSerial.Font.Name := 'Courier New';
  FSerial.Font.Size := 9;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 40;
  FTimer.Enabled := False;
  FTimer.OnTimer := TimerTick;

  SetStatus('Скетч не запущен');
  UpdateButtons;
end;

destructor TArdSimPanel.Destroy;
var
  ResIdx: Integer;
begin
  FTimer.Enabled := False;
  StopAll;
  inherited Destroy;
  FDbgInfo.Free;
  FDbgFiles.Free;
  FFontRoots.Free;
  ClearAllPreviews;
  FKept.Free;
  ClearPhantoms;
  FPhantoms.Free;
  if FFontCache <> nil then
  begin
    for ResIdx := 0 to FFontCache.Count - 1 do
      TObject(FFontCache[ResIdx]).Free;
    FFontCache.Free;
  end;
  FreeLibFonts;
end;

procedure TArdSimPanel.Resize;
begin
  inherited;
  LayoutControls;
end;

// Сверху вниз: кнопки, строка состояния, прибор, вывод Serial - всё
// остальное (не меньше SerialMinH)
procedure TArdSimPanel.LayoutControls;
const
  Gap = 4;
  BarH = 24;
  StatusH = 18;
  SerialMinH = 60;
  SigHeadH = 20;
  SigPanelH = 210;
var
  AreaW, PosY, ButtonW, BtnIdx, SigH: Integer;
  DeviceSize: TPoint;
  Buttons: array[0..4] of TUiButton;
begin
  if FBar = nil then
    Exit;
  AreaW := ClientWidth - 2 * Gap;
  if AreaW < 60 then
    AreaW := 60;
  PosY := Gap;
  if FBar.Visible then
    FBar.SetBounds(Gap, PosY, AreaW, BarH);
  Buttons[0] := FBtnBuild;
  Buttons[1] := FBtnRun;
  Buttons[2] := FBtnStop;
  Buttons[3] := FBtnIni;
  Buttons[4] := FBtnWindow;
  ButtonW := (AreaW - 4 * 2) div 5;
  for BtnIdx := 0 to 4 do
    Buttons[BtnIdx].SetBounds(BtnIdx * (ButtonW + 2), 0, ButtonW, BarH);
  if FBar.Visible then
    Inc(PosY, BarH + 2);
  FStatus.SetBounds(Gap, PosY, AreaW, StatusH);
  Inc(PosY, StatusH);
  SigH := SigHeadH + Gap;
  if FSigShown then
    Inc(SigH, SigPanelH);
  DeviceSize := FDevice.Arrange(AreaW,
                                ClientHeight - PosY - SerialMinH - SigH - 2 * Gap);
  FDevice.SetBounds(Gap, PosY, DeviceSize.X, DeviceSize.Y);
  FDevice.Invalidate;
  Inc(PosY, DeviceSize.Y + Gap);
  FSigHead.SetBounds(Gap, PosY, AreaW, SigHeadH);
  Inc(PosY, SigHeadH);
  FSigPanel.Visible := FSigShown;
  if FSigShown then
  begin
    FSigPanel.SetBounds(Gap, PosY, AreaW, SigPanelH);
    for BtnIdx := 0 to 1 do
      FSigWeights[BtnIdx].Width := AreaW - FSigWeights[BtnIdx].Left - 4;
    FSigNote.Width := AreaW - FSigNote.Left - 4;
    Inc(PosY, SigPanelH);
  end;
  Inc(PosY, Gap);
  if ClientHeight - PosY - Gap > 20 then
    FSerial.SetBounds(Gap, PosY, AreaW, ClientHeight - PosY - Gap)
  else
    FSerial.SetBounds(Gap, PosY, AreaW, 20);
end;

procedure TArdSimPanel.Log(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AText);
end;

procedure TArdSimPanel.SetStatus(const AText: string);
begin
  FStatus.Caption := AText;
end;

procedure TArdSimPanel.UpdateButtons;
begin
  FBtnBuild.Enabled := not Building;
  FBtnRun.Enabled := not Building;
  FBtnStop.Enabled := Running or Building;
  FBtnWindow.Enabled := not Building;
  if Assigned(FOnStateChange) then
    FOnStateChange(Self);
end;

procedure TArdSimPanel.BuildAndRun;
begin
  BtnBuildClick(Self);
end;

procedure TArdSimPanel.RunSim;
begin
  BtnRunClick(Self);
end;

procedure TArdSimPanel.OpenIni;
begin
  BtnIniClick(Self);
end;

procedure TArdSimPanel.OpenArdSimWindow;
begin
  BtnWindowClick(Self);
end;

procedure TArdSimPanel.SigViewClick(Sender: TObject);
begin
  if Assigned(FOnViewFiles) then
    FOnViewFiles(Self);
end;

procedure TArdSimPanel.ShowDataFile(const AFileName: string);
var
  Ini: TIniFile;
begin
  if AFileName = FDataFile then
    Exit;
  FDataFile := AFileName;
  if FDataFile = '' then
    Exit;
  if (FSketchFile = '') and Assigned(FOnNeedSketch) then
    FOnNeedSketch(Self);
  if (FSketchFile = '') or not FileExists(IniOfSketch) then
  begin
    SetStatus('Файл замера: ' + FDataFile + ' - ardsim.ini появится после первого запуска');
    Exit;
  end;
  Ini := TIniFile.Create(IniOfSketch);
  try
    Ini.WriteString('DataFile', 'Enabled', '1');
    Ini.WriteString('DataFile', 'Path', FDataFile);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
  // поля панели не трогаем, если там неприменённые правки
  if not FSigDirty and (FSigData <> nil) then
  begin
    FSigLoading := True;
    FSigData.Checked := True;
    FSigLoading := False;
    FSigIniAge := FileAge(IniOfSketch);
  end;
  SetStatus('Файл замера: ' + FDataFile);
end;

procedure TArdSimPanel.SetShowToolbar(AValue: Boolean);
begin
  FBar.Visible := AValue;
  LayoutControls;
end;

function TArdSimPanel.GetShowToolbar: Boolean;
begin
  Result := FBar.Visible;
end;

function TArdSimPanel.Running: Boolean;
begin
  Result := (FSim <> nil) and FSim.Running;
end;

function TArdSimPanel.Building: Boolean;
begin
  Result := FBuild <> nil;
end;

function TArdSimPanel.SketchReady: Boolean;
begin
  if Assigned(FOnNeedSketch) then
    FOnNeedSketch(Self);
  Result := (FSketchFile <> '') and FileExists(FSketchFile);
  if not Result then
  begin
    SetStatus('Нет скетча: откройте .ino');
    Log('ArdSim: нет скетча .ino для сборки (вкладка Arduino или проект ' +
        'со скетчем)');
  end;
end;

// build_sim.cmd собирает файлы с диска, а не текст редактора
function TArdSimPanel.SaveFiles: Boolean;
begin
  Result := True;
  if Assigned(FOnSaveFiles) then
    Result := FOnSaveFiles(Self);
  if not Result then
    SetStatus('Не всё сохранено');
end;

function TArdSimPanel.ExeOfSketch: string;
begin
  Result := ExtractFilePath(FSketchFile) + 'ardsim_build\' +
            ChangeFileExt(ExtractFileName(FSketchFile), '') + '_sim.exe';
end;

function TArdSimPanel.IniOfSketch: string;
begin
  Result := ExtractFilePath(ExeOfSketch) + 'ardsim.ini';
end;

procedure TArdSimPanel.BtnBuildClick(Sender: TObject);
begin
  if Building or not SketchReady or not SaveFiles then
    Exit;
  StopSim;
  StartBuild(True);
end;

procedure TArdSimPanel.BtnRunClick(Sender: TObject);
begin
  if Building or not SketchReady or not SaveFiles then
    Exit;
  if not FileExists(ExeOfSketch) then
  begin
    // ещё не собирался - собрать
    StartBuild(True);
    Exit;
  end;
  StopSim;
  StartSim;
end;

procedure TArdSimPanel.BtnStopClick(Sender: TObject);
begin
  StopAll;
end;

procedure TArdSimPanel.BtnIniClick(Sender: TObject);
var
  IniFile: string;
begin
  if not SketchReady then
    Exit;
  IniFile := IniOfSketch;
  if not FileExists(IniFile) then
  begin
    SetStatus('ardsim.ini появится после первого запуска');
    Log('ArdSim: ' + IniFile + ' создаётся при первом запуске эмулятора');
    Exit;
  end;
  if Assigned(FOnOpenFile) then
    FOnOpenFile(Self, IniFile);
end;

procedure TArdSimPanel.BtnWindowClick(Sender: TObject);
var
  WindowRun: TProcRun;
begin
  if Building or not SketchReady then
    Exit;
  if not FileExists(ExeOfSketch) then
  begin
    SetStatus('Сначала Build+Run');
    Exit;
  end;
  WindowRun := TProcRun.Create;
  try
    WindowRun.CommandLine := '"' + ExeOfSketch + '"';
    WindowRun.Dir := ExtractFilePath(ExeOfSketch);
    if not WindowRun.Start then
      Log('ArdSim: не запустился ' + ExeOfSketch + ' - ' + WindowRun.ErrorText);
  finally
    WindowRun.Free;   // процесс работает дальше сам
  end;
end;


// ---------------------------------------------------------------- сборка

procedure TArdSimPanel.StartBuild(ARunAfter: Boolean);
var
  SimDir, Command: string;
  Notes: TStringList;
  NoteIdx: Integer;
begin
  SimDir := FArdSimDir;
  if SimDir = '' then
    SimDir := ArdSimFindDir;
  if (SimDir = '') or not FileExists(IncludeTrailingPathDelimiter(SimDir) +
     'build_sim.cmd') then
  begin
    SetStatus('Не найдена папка ArdSim');
    Log('ArdSim: не найден build_sim.cmd (папка ArdSim рядом с unIDE ' +
        'или на уровень выше)');
    Exit;
  end;
  SimDir := IncludeTrailingPathDelimiter(SimDir);
  Log('ArdSim: папка ' + SimDir);
  // Шрифты UTFT скетча из папок libraries: список ardsim_build\ardsim_fonts.txt
  Notes := TStringList.Create;
  try
    if ArdSimWriteFontList(FSketchFile, FFontRoots, Notes) = '' then
      Log('ArdSim: список шрифтов не записан (ardsim_build\' +
          ArdSimFontListName + ')');
    for NoteIdx := 0 to Notes.Count - 1 do
      Log(Notes[NoteIdx]);
  finally
    Notes.Free;
  end;
  // cmd /c ""файл" "аргумент"" - внешние кавычки снимает cmd
  Command := '"' + SimDir + 'build_sim.cmd" "' + FSketchFile + '"';
  if FMingwBin <> '' then
    Command := Command + ' "' + ExcludeTrailingPathDelimiter(FMingwBin) + '"';
  FBuild := TProcRun.Create;
  FBuild.CommandLine := 'cmd.exe /c "' + Command + '"';
  FBuild.Dir := SimDir;
  FBuild.Window := pwHidden;
  FBuild.Console := pcNoWindow;
  FBuild.CaptureOutput := True;
  FBuildLine := '';
  FRunAfterBuild := ARunAfter;
  Log('ArdSim: сборка ' + FSketchFile);
  if not FBuild.Start then
  begin
    Log('ArdSim: build_sim.cmd не запустился - ' + FBuild.ErrorText);
    FreeAndNil(FBuild);
    SetStatus('Сборка не запустилась');
    UpdateButtons;
    Exit;
  end;
  SetStatus('Сборка...');
  FTimer.Enabled := True;
  UpdateButtons;
end;

procedure TArdSimPanel.PollBuild;
var
  Chunk: string;
  Got, LineEnd: Integer;
  Finished: Boolean;
  ExitCode: Integer;
begin
  if FBuild = nil then
    Exit;
  Chunk := '';
  Got := FBuild.Read(Chunk, 65536);
  Finished := Got < 0;
  if Got > 0 then
  begin
    FBuildLine := FBuildLine + Chunk;
    repeat
      LineEnd := Pos(#10, FBuildLine);
      if LineEnd = 0 then
        Break;
      Log(TrimRight(Copy(FBuildLine, 1, LineEnd - 1)));
      Delete(FBuildLine, 1, LineEnd);
    until False;
  end;
  // -1: программа вышла и вывод прочитан весь
  if not Finished then
    Exit;
  if Trim(FBuildLine) <> '' then
    Log(TrimRight(FBuildLine));
  FBuildLine := '';
  FBuild.WaitFor(1000);
  ExitCode := FBuild.ExitCode;
  FreeAndNil(FBuild);
  if ExitCode <> 0 then
  begin
    FDbgStartCmd := 0;
    SetStatus('Сборка не удалась, см. журнал');
    Log('ArdSim: сборка не удалась, код ' + IntToStr(ExitCode));
    UpdateButtons;
    Exit;
  end;
  SetStatus('Собрано');
  if FRunAfterBuild then
    StartSim;
  UpdateButtons;
end;

// ---------------------------------------------------------------- эмулятор

function TArdSimPanel.Header(AIndex: Integer): Cardinal;
begin
  {$IFDEF MSWINDOWS}
  if FView <> nil then
    Result := PCardinal(PAnsiChar(FView) + AIndex * 4)^
  else
  {$ENDIF}
    Result := 0;
end;

procedure TArdSimPanel.SetHeader(AIndex: Integer; AValue: Cardinal);
begin
  {$IFDEF MSWINDOWS}
  if FView <> nil then
    PCardinal(PAnsiChar(FView) + AIndex * 4)^ := AValue;
  {$ENDIF}
end;

procedure TArdSimPanel.StartSim;
begin
  // Превью шрифта - к прежнему запуску
  ClearAllPreviews;
  {$IFDEF MSWINDOWS}
  FSimExe := ExeOfSketch;
  if not FileExists(FSimExe) then
  begin
    SetStatus('Нет ' + ExtractFileName(FSimExe));
    Exit;
  end;
  Inc(MapCounter);
  FMapName := IntToStr(GetCurrentProcessId) + '_' + IntToStr(MapCounter);
  FMapping := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0,
                                SharedBytes, PChar('Local\ArdSim_' + FMapName));
  if FMapping = 0 then
  begin
    Log('ArdSim: общая память не создана, код ' + IntToStr(GetLastError));
    Exit;
  end;
  FView := MapViewOfFile(FMapping, FILE_MAP_ALL_ACCESS, 0, 0, SharedBytes);
  if FView = nil then
  begin
    Log('ArdSim: общая память не открыта, код ' + IntToStr(GetLastError));
    FreeShared;
    Exit;
  end;
  FillChar(FView^, SharedBytes, 0);
  SetHeader(HdrHostPid, GetCurrentProcessId);
  SetHeader(HdrLayout, HostLayout);
  SetHeader(HdrMagic, HostMagic);
  DbgReset;
  // точки - до запуска: остановка возможна и в setup()
  if Assigned(FOnDbgNeedBreaks) then
    FOnDbgNeedBreaks(Self);
  FDbgRunAssign := '';
  if FDbgStartCmd = ArdDbgRunToSet then
  begin
    FDbgRunAssign := FDbgStartAssign;
    // строка "=Имя=Значение" - до первой команды; Watch её сохраняет
    WriteWatchRequest('');
    SetDbgHeader(DbgCmdCode, Cardinal(FDbgStartCmd));
    SetDbgHeader(DbgCmdArg, FDbgStartArg);
    SetDbgHeader(DbgCmdSeq, 1);
    FDbgStartCmd := 0;
    FDbgStartAssign := '';
  end
  else if FDbgStartCmd <> 0 then
  begin
    SetDbgHeader(DbgCmdCode, Cardinal(FDbgStartCmd));
    SetDbgHeader(DbgCmdArg, FDbgStartArg);
    SetDbgHeader(DbgCmdSeq, 1);
    FDbgStepping := True;
    FDbgStartCmd := 0;
  end;
  FScreenVersion := 0;
  FSerialRead := 0;
  FHasPicture := False;
  FSerial.Lines.Clear;

  FSim := TProcRun.Create;
  FSim.CommandLine := '"' + FSimExe + '" /host:' + FMapName;
  FSim.Dir := ExtractFilePath(FSimExe);
  FSim.Window := pwHidden;
  if not FSim.Start then
  begin
    Log('ArdSim: не запустился ' + FSimExe + ' - ' + FSim.ErrorText);
    FreeAndNil(FSim);
    FreeShared;
    SetStatus('Эмулятор не запустился');
    UpdateButtons;
    Exit;
  end;
  Log('ArdSim: запущен ' + FSimExe);
  FSigIniAge := -1;   // перечитать: ini мог появиться или поменяться
  SetStatus('Работает: ' + ExtractFileName(FSketchFile));
  FTimer.Enabled := True;
  FDevice.Invalidate;
  if FDevice.CanFocus then
    FDevice.SetFocus;
  {$ELSE}
  SetStatus('Эмулятор работает только в Windows');
  {$ENDIF}
  UpdateButtons;
end;

procedure TArdSimPanel.FreeShared;
begin
  {$IFDEF MSWINDOWS}
  if FView <> nil then
    UnmapViewOfFile(FView);
  FView := nil;
  if FMapping <> 0 then
    CloseHandle(FMapping);
  FMapping := 0;
  {$ENDIF}
end;

procedure TArdSimPanel.StopSim;
begin
  if FSim = nil then
    Exit;
  if FSim.Running then
  begin
    // просьба выйти; скетч может считать без вызовов API - тогда снять
    SetHeader(HdrStopRequest, 1);
    if not FSim.WaitFor(500) then
    begin
      FSim.Terminate(1);
      // TerminateProcess не ждёт: exe занят, пока процесс не вышел, и
      // сборка сразу после остановки не могла бы его перезаписать
      FSim.WaitFor(3000);
    end;
  end;
  FreeAndNil(FSim);
  FreeShared;
  DbgEnd;
  SetStatus('Остановлен');
  UpdateButtons;
end;

procedure TArdSimPanel.StopAll;
begin
  if FBuild <> nil then
  begin
    FBuild.KillTree;
    FreeAndNil(FBuild);
    Log('ArdSim: сборка остановлена');
  end;
  StopSim;
  if FTimer <> nil then
    FTimer.Enabled := False;
  if FBtnBuild <> nil then
    UpdateButtons;
end;

procedure TArdSimPanel.PostKey(ARow, ACol: Integer);
var
  KeyWrite: Cardinal;
begin
  if not Running then
    Exit;
  KeyWrite := Header(HdrKeyWrite);
  if KeyWrite - Header(HdrKeyRead) >= KeyQueueSize then
    Exit;   // эмулятор не успевает разбирать
  SetHeader(HdrKeyQueue + Integer(KeyWrite mod KeyQueueSize),
            Cardinal(ARow * ArdSimKeyCols + ACol));
  SetHeader(HdrKeyWrite, KeyWrite + 1);
end;

procedure TArdSimPanel.AppendSerial(const AText: string);
var
  Converted: string;
  CharIdx: Integer;
begin
  Converted := '';
  for CharIdx := 1 to Length(AText) do
  begin
    if AText[CharIdx] = #13 then
      Continue;
    if AText[CharIdx] = #10 then
      Converted := Converted + #13#10
    else
      Converted := Converted + AText[CharIdx];
  end;
  if FSerial.GetTextLen > SerialMaxChars then
  begin
    FSerial.SelStart := 0;
    FSerial.SelLength := SerialMaxChars div 3;
    FSerial.SelText := '';
  end;
  FSerial.SelStart := FSerial.GetTextLen;
  FSerial.SelLength := 0;
  FSerial.SelText := Converted;
end;

procedure TArdSimPanel.PollSim;
var
  Version, Written, Count, ByteIdx: Cardinal;
  Ring: PAnsiChar;
  Text: string;
  ExitCode: Integer;
begin
  {$IFDEF MSWINDOWS}
  if (FSim = nil) or (FView = nil) then
    Exit;
  Version := Header(HdrScreenVersion);
  if Version <> FScreenVersion then
  begin
    FScreenVersion := Version;
    FHasPicture := True;
    FDevice.InvalidateScreen;
  end;
  Written := Header(HdrSerialWrite);
  if Written <> FSerialRead then
  begin
    Count := Written - FSerialRead;
    if Count > SerialRingBytes then
    begin
      // кольцо обогнало чтение: старое потеряно
      FSerialRead := Written - SerialRingBytes;
      Count := SerialRingBytes;
    end;
    Ring := PAnsiChar(FView) + HeaderBytes + ScreenBytes;
    SetLength(Text, Count);
    for ByteIdx := 0 to Count - 1 do
      Text[ByteIdx + 1] := Char(Ring[(FSerialRead + ByteIdx) mod SerialRingBytes]);
    FSerialRead := Written;
    AppendSerial(Text);
  end;
  PollDebug;
  if FSim = nil then
    Exit;   // остановлен из обработчика события отладчика
  if not FSim.Running then
  begin
    ExitCode := FSim.ExitCode;
    FreeAndNil(FSim);
    FreeShared;
    DbgEnd;
    if ExitCode = 0 then
      SetStatus('Эмулятор завершился')
    else if ExitCode = 4 then
    begin
      SetStatus('Эмулятор собран старой версией ArdSim - нужна сборка');
      Log('ArdSim: ' + ExtractFileName(FSimExe) + ' собран прежней версией ' +
          'ArdSim (другая раскладка общей памяти) - соберите заново (Build)');
    end
    else
    begin
      SetStatus('Эмулятор завершился, код ' + IntToStr(ExitCode));
      Log('ArdSim: ' + ExtractFileName(FSimExe) + ' завершился, код ' +
          IntToStr(ExitCode));
    end;
    UpdateButtons;
  end;
  {$ENDIF}
end;

// ---------------------------------------------------------------- сигналы

// Числа в ardsim.ini - с точкой (эмулятор читает их strtod)
function IniFloatText(AValue: Double): string;
begin
  Result := StringReplace(FloatToStr(AValue), DecimalSeparator, '.', []);
end;

function IniFloat(const AText: string; ADefault: Double): Double;
var
  Text: string;
begin
  Text := Trim(AText);
  Text := StringReplace(Text, '.', DecimalSeparator, []);
  Text := StringReplace(Text, ',', DecimalSeparator, []);
  Result := StrToFloatDef(Text, ADefault);
end;

// "амплитуда,фаза" ключа Hn
procedure SplitPair(const AText: string; var AFirst, ASecond: string);
var
  CommaPos: Integer;
begin
  CommaPos := Pos(',', AText);
  if CommaPos = 0 then
  begin
    AFirst := Trim(AText);
    ASecond := '0';
  end
  else
  begin
    AFirst := Trim(Copy(AText, 1, CommaPos - 1));
    ASecond := Trim(Copy(AText, CommaPos + 1, MaxInt));
  end;
end;

procedure TArdSimPanel.BuildSignals;
var
  RowIdx: Integer;

  function AddLabel(const ACaption: string; ALeft, ATop, AWidth: Integer): TUiLabel;
  begin
    Result := TUiLabel.Create(Self);
    Result.Parent := FSigPanel;
    Result.AutoSize := False;
    Result.Caption := ACaption;
    Result.SetBounds(ALeft, ATop + 3, AWidth, 16);
  end;

  function AddEdit(ALeft, ATop, AWidth: Integer; const AHint: string): TUiEdit;
  begin
    Result := TUiEdit.Create(Self);
    Result.Parent := FSigPanel;
    Result.SetBounds(ALeft, ATop, AWidth, 22);
    Result.Hint := AHint;
    Result.ShowHint := True;
    Result.OnChange := SigChange;
  end;

  function AddCheck(const ACaption: string; ALeft, ATop, AWidth: Integer): TUiCheckBox;
  begin
    Result := TUiCheckBox.Create(Self);
    Result.Parent := FSigPanel;
    Result.Caption := ACaption;
    Result.SetBounds(ALeft, ATop, AWidth, 20);
    Result.OnClick := SigChange;
  end;

begin
  FSigShown := True;
  FSigIniAge := -1;
  FSigHead := TUiButton.Create(Self);
  FSigHead.Parent := Self;
  FSigHead.Caption := 'Сигналы - скрыть';
  FSigHead.Hint := 'Тахометр, обороты, 1-я гармоника A0/A1, модель ротора ' +
    'и грузы (ardsim.ini)';
  FSigHead.ShowHint := True;
  FSigHead.TabStop := False;
  FSigHead.OnClick := SigHeadClick;

  FSigPanel := TUiPanel.Create(Self);
  FSigPanel.Parent := Self;
  FSigPanel.BevelOuter := bvNone;
  FSigPanel.Caption := '';

  FSigTacho := AddCheck('Тахометр', 0, 2, 96);
  AddLabel('обороты, об/мин', 100, 2, 100);
  FSigRpm := AddEdit(204, 2, 70, 'Обороты ротора (RPM в [Tacho])');
  FSigFreq := AddLabel('', 282, 2, 90);
  FSigSdFail := AddCheck('Нет SD карты', 380, 2, 140);
  FSigSdFail.Hint := 'Сбой SD карты: SD.begin и card.init возвращают false ' +
    '([SD] Fail=1 в ardsim.ini). SD.begin вызывается в setup(), поэтому после ' +
    '"Применить" перезапустите скетч (Run)';
  FSigSdFail.ShowHint := True;
  FSigRotor := AddCheck('Модель ротора: 1-я гармоника A0 и A1 считается ' +
    'от дисбаланса и грузов', 0, 28, 520);
  for RowIdx := 0 to 1 do
  begin
    AddLabel('A' + IntToStr(RowIdx) + ', 1x: амплитуда, В', 0, 54 + RowIdx * 26, 140);
    FSigAmp[RowIdx] := AddEdit(144, 54 + RowIdx * 26, 70,
      'Амплитуда 1-й гармоники, вольты (H1 в [A' + IntToStr(RowIdx) + '])');
    AddLabel('фаза, град', 222, 54 + RowIdx * 26, 70);
    FSigPhase[RowIdx] := AddEdit(296, 54 + RowIdx * 26, 70,
      'Фаза пика после метки тахометра, градусы');
  end;
  for RowIdx := 0 to 1 do
  begin
    AddLabel('Грузы, плоскость ' + IntToStr(RowIdx + 1), 0, 106 + RowIdx * 26, 120);
    FSigWeights[RowIdx] := AddEdit(124, 106 + RowIdx * 26, 300,
      'Грузы на роторе: граммы@градусы через точку с запятой, ' +
      'например 10@0; 5.2@137 (Weights' + IntToStr(RowIdx + 1) + ' в [Rotor])');
  end;
  FSigApply := TUiButton.Create(Self);
  FSigApply.Parent := FSigPanel;
  FSigApply.Caption := 'Применить';
  FSigApply.Hint := 'Записать в ardsim.ini: эмулятор перечитает его за полсекунды';
  FSigApply.ShowHint := True;
  FSigApply.TabStop := False;
  FSigApply.SetBounds(0, 160, 100, 22);
  FSigApply.OnClick := SigApplyClick;
  FSigIni := TUiButton.Create(Self);
  FSigIni.Parent := FSigPanel;
  FSigIni.Caption := 'ardsim.ini';
  FSigIni.Hint := FBtnIni.Hint;
  FSigIni.ShowHint := True;
  FSigIni.TabStop := False;
  FSigIni.SetBounds(106, 160, 90, 22);
  FSigIni.OnClick := BtnIniClick;
  FSigNote := AddLabel('', 204, 160, 300);
  FSigView := TUiButton.Create(Self);
  FSigView.Parent := FSigPanel;
  FSigView.Caption := 'View files Test.dat';
  FSigView.Hint := 'Окно "Искать файл - по маскам, на диске" с маской test.dat: ' +
    'найденные файлы - в Match list, Test.dat под курсором списка ' +
    'передаётся эмулятору';
  FSigView.ShowHint := True;
  FSigView.TabStop := False;
  FSigView.SetBounds(0, 186, 196, 22);
  FSigView.OnClick := SigViewClick;
  FSigData := AddCheck('Сигнал из файла замера', 204, 187, 300);
  FSigData.Hint := 'A0, A1 и тахометр - из файла Test.dat ([DataFile] в ardsim.ini) ' +
    'вместо генератора. Обороты - по временам меток в файле, без них - по ' +
    'Garmoniki.txt рядом с файлом, без него - из поля "обороты"';
  FSigData.ShowHint := True;
  SigUpdateState;
end;

procedure TArdSimPanel.SigHeadClick(Sender: TObject);
begin
  FSigShown := not FSigShown;
  if FSigShown then
    FSigHead.Caption := 'Сигналы - скрыть'
  else
    FSigHead.Caption := 'Сигналы - показать';
  if FSigShown then
    SigLoad;
  LayoutControls;
end;

procedure TArdSimPanel.SigChange(Sender: TObject);
begin
  if FSigLoading then
    Exit;
  FSigDirty := True;
  SigUpdateState;
  // галка "Сигнал из файла замера" применяется сразу (Андрей 14.11): скетч
  // переключает метки File / Paused
  if (Sender = FSigData) and FSigApply.Enabled then
    SigApplyClick(Sender);
end;

procedure TArdSimPanel.SigUpdateState;
var
  RowIdx: Integer;
  Rpm: Double;
begin
  for RowIdx := 0 to 1 do
  begin
    FSigAmp[RowIdx].Enabled := not FSigRotor.Checked;
    FSigPhase[RowIdx].Enabled := not FSigRotor.Checked;
    FSigWeights[RowIdx].Enabled := FSigRotor.Checked;
  end;
  FSigRpm.Enabled := FSigTacho.Checked;
  Rpm := IniFloat(FSigRpm.Text, 0);
  if FSigTacho.Checked and (Rpm > 0) then
    FSigFreq.Caption := 'f = ' + FormatFloat('0.00', Rpm / 60) + ' Гц'
  else
    FSigFreq.Caption := '';
  FSigApply.Enabled := FSigDirty;
  if FSigDirty then
    FSigNote.Caption := 'изменено, не применено'
  else if FSigIniFile = '' then
    FSigNote.Caption := 'ardsim.ini появится после первого запуска'
  else
    FSigNote.Caption := 'остальное - в ardsim.ini';
end;

// Поля - из ardsim.ini (если его не правили на панели)
procedure TArdSimPanel.SigLoad;
var
  Ini: TIniFile;
  RowIdx: Integer;
  AmpText, PhaseText: string;
begin
  if FSigDirty then
    Exit;
  if (FSketchFile = '') and Assigned(FOnNeedSketch) then
    FOnNeedSketch(Self);
  if (FSketchFile = '') or not FileExists(IniOfSketch) then
  begin
    FSigIniFile := '';
    SigUpdateState;
    Exit;
  end;
  FSigIniFile := IniOfSketch;
  FSigIniAge := FileAge(FSigIniFile);
  FSigLoading := True;
  Ini := TIniFile.Create(FSigIniFile);
  try
    FSigTacho.Checked := Ini.ReadString('Tacho', 'Enabled', '1') <> '0';
    FSigRpm.Text := Ini.ReadString('Tacho', 'RPM', '1500');
    FSigSdFail.Checked := Ini.ReadString('SD', 'Fail', '0') <> '0';
    FSigData.Checked := Ini.ReadString('DataFile', 'Enabled', '0') <> '0';
    FSigRotor.Checked := Ini.ReadString('Rotor', 'Enabled', '0') <> '0';
    for RowIdx := 0 to 1 do
    begin
      SplitPair(Ini.ReadString('A' + IntToStr(RowIdx), 'H1', '0,0'), AmpText, PhaseText);
      FSigAmp[RowIdx].Text := AmpText;
      FSigPhase[RowIdx].Text := PhaseText;
      FSigWeights[RowIdx].Text := Ini.ReadString('Rotor', 'Weights' + IntToStr(RowIdx + 1), '');
    end;
  finally
    Ini.Free;
    FSigLoading := False;
  end;
  SigUpdateState;
end;

procedure TArdSimPanel.SigApplyClick(Sender: TObject);
var
  Ini: TIniFile;
  RowIdx: Integer;
begin
  if (FSketchFile = '') and Assigned(FOnNeedSketch) then
    FOnNeedSketch(Self);
  if (FSketchFile = '') or not FileExists(IniOfSketch) then
  begin
    // неполный ini эмулятор прочёл бы с нулями вместо умолчаний
    FSigNote.Caption := 'ardsim.ini появится после первого запуска';
    Exit;
  end;
  FSigIniFile := IniOfSketch;
  Ini := TIniFile.Create(FSigIniFile);
  try
    if FSigTacho.Checked then
      Ini.WriteString('Tacho', 'Enabled', '1')
    else
      Ini.WriteString('Tacho', 'Enabled', '0');
    Ini.WriteString('Tacho', 'RPM', IniFloatText(IniFloat(FSigRpm.Text, 1500)));
    if FSigSdFail.Checked then
      Ini.WriteString('SD', 'Fail', '1')
    else
      Ini.WriteString('SD', 'Fail', '0');
    if FSigData.Checked then
      Ini.WriteString('DataFile', 'Enabled', '1')
    else
      Ini.WriteString('DataFile', 'Enabled', '0');
    if FSigRotor.Checked then
      Ini.WriteString('Rotor', 'Enabled', '1')
    else
      Ini.WriteString('Rotor', 'Enabled', '0');
    for RowIdx := 0 to 1 do
    begin
      // с моделью ротора 1-ю гармонику считает эмулятор
      if not FSigRotor.Checked then
        Ini.WriteString('A' + IntToStr(RowIdx), 'H1',
          IniFloatText(IniFloat(FSigAmp[RowIdx].Text, 0)) + ',' +
          IniFloatText(IniFloat(FSigPhase[RowIdx].Text, 0)));
      Ini.WriteString('Rotor', 'Weights' + IntToStr(RowIdx + 1),
                      Trim(FSigWeights[RowIdx].Text));
    end;
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
  FSigDirty := False;
  FSigIniAge := FileAge(FSigIniFile);
  Log('ArdSim: сигналы записаны в ' + FSigIniFile);
  SigUpdateState;
end;

// Файл поменялся (кнопка ini, первый запуск) - поля заново
procedure TArdSimPanel.SigPoll;
begin
  if not FSigShown or FSigDirty or (FSketchFile = '') then
    Exit;
  if FileExists(IniOfSketch) and (FileAge(IniOfSketch) <> FSigIniAge) then
    SigLoad;
end;

// ---------------------------------------------------------------- отладчик

function TArdSimPanel.DbgArea: PAnsiChar;
begin
  Result := nil;
  {$IFDEF MSWINDOWS}
  if FView <> nil then
    Result := PAnsiChar(FView) + DbgOffset;
  {$ENDIF}
end;

function TArdSimPanel.DbgHeader(AIndex: Integer): Cardinal;
begin
  if DbgArea <> nil then
    Result := PCardinal(DbgArea + AIndex * 4)^
  else
    Result := 0;
end;

procedure TArdSimPanel.SetDbgHeader(AIndex: Integer; AValue: Cardinal);
begin
  if DbgArea <> nil then
    PCardinal(DbgArea + AIndex * 4)^ := AValue;
end;

// Новый запуск: общая память только что обнулена
procedure TArdSimPanel.DbgReset;
begin
  FWhereWait := False;
  FDbgStopSeq := 0;
  FDbgInfoSeq := 0;
  FDbgStopped := False;
  FDbgStepping := False;
  FDbgInfo.Clear;
  FDbgFiles.Clear;
  FDbgBreaks := #1;    // не совпадёт ни с одним списком: отправить
  FDbgWatch := #1;
  FLiveTick := GetTickCount;
  FBreakTick := GetTickCount;
end;

// Эмулятор закончил или снят: строки остановки больше нет
procedure TArdSimPanel.DbgEnd;
var
  WasStopped: Boolean;
begin
  WasStopped := FDbgStopped;
  FDbgStopped := False;
  FDbgStepping := False;
  FDbgInfo.Clear;
  if Assigned(FOnDbgResume) then
    FOnDbgResume(Self);
  if WasStopped then
    Log('ArdSim: отладка закончилась');
end;

function TArdSimPanel.ReadDbgText(AOffset, AMaxBytes: Integer): string;
var
  Source: PAnsiChar;
  TextLen: Integer;
begin
  Result := '';
  if DbgArea = nil then
    Exit;
  Source := DbgArea + AOffset;
  TextLen := 0;
  while (TextLen < AMaxBytes) and (Source[TextLen] <> #0) do
    Inc(TextLen);
  SetString(Result, Source, TextLen);
end;

// Ответ эмулятора. Пишется под счётчиком InfoSeq: нечётный - пишет;
// изменился за время чтения - прочитать в следующий раз
procedure TArdSimPanel.ReadDbgInfo;
var
  SeqBefore, TextLen: Cardinal;
  Text: string;
begin
  SeqBefore := DbgHeader(DbgInfoSeq);
  if Odd(SeqBefore) then
    Exit;
  TextLen := DbgHeader(DbgInfoBytes);
  if TextLen >= DbgInfoMax then
    TextLen := DbgInfoMax - 1;
  SetString(Text, DbgArea + DbgInfoOffset, TextLen);
  if DbgHeader(DbgInfoSeq) <> SeqBefore then
    Exit;
  FDbgInfoSeq := SeqBefore;
  FDbgInfo.Text := StringReplace(Text, #10, #13#10, [rfReplaceAll]);
end;

procedure TArdSimPanel.DbgStatus;
var
  Code: Cardinal;
begin
  Code := DbgHeader(DbgStopCodeIdx);
  SetStatus('Стоит: ' + ExtractFileName(DbgFileName(Code shr 20)) +
            ', строка ' + IntToStr(Code and $FFFFF) + ' - ' + DbgWhere);
end;

procedure TArdSimPanel.PollDebug;
var
  FilesText: string;
begin
  if DbgArea = nil then
    Exit;
  if FWhereWait then
    PollWhere;
  if (FDbgFiles.Count = 0) and (DbgHeader(DbgInstrumented) = 1) then
  begin
    FilesText := ReadDbgText(DbgFilesOffset, DbgFilesBytes);
    FDbgFiles.Text := StringReplace(FilesText, #10, #13#10, [rfReplaceAll]);
  end;
  // точки останова (правки двигают строки) - раз в 250 мс
  if (GetTickCount - FBreakTick >= 250) and Assigned(FOnDbgNeedBreaks) then
  begin
    FBreakTick := GetTickCount;
    FOnDbgNeedBreaks(Self);
  end;
  if DbgHeader(DbgStopSeq) <> FDbgStopSeq then
  begin
    FDbgStopSeq := DbgHeader(DbgStopSeq);
    if DbgHeader(DbgState) = 1 then
    begin
      ReadDbgInfo;
      FDbgStopped := True;
      FDbgStepping := False;
      DbgStatus;
      if Assigned(FOnDbgStop) then
        FOnDbgStop(Self);
      Exit;
    end;
  end;
  if FDbgStopped and (DbgHeader(DbgState) = 0) then
  begin
    FDbgStopped := False;
    SetStatus('Работает: ' + ExtractFileName(FSketchFile));
    if Assigned(FOnDbgResume) then
      FOnDbgResume(Self);
  end;
  if (DbgHeader(DbgInfoSeq) <> FDbgInfoSeq) and not Odd(DbgHeader(DbgInfoSeq)) then
  begin
    ReadDbgInfo;
    if Assigned(FOnDbgInfo) then
      FOnDbgInfo(Self);
  end;
  // окно Watch открыто - значения и на ходу, раз в 500 мс
  if FLiveWatch and not FDbgStopped and (FDbgWatch <> #1) and (FDbgWatch <> '') and
     (GetTickCount - FLiveTick >= 500) then
  begin
    FLiveTick := GetTickCount;
    SetDbgHeader(DbgWatchSeq, DbgHeader(DbgWatchSeq) + 1);
  end;
end;

procedure TArdSimPanel.ScreenWhere(AX, AY: Integer);
begin
  if not Running or (DbgArea = nil) then
    Exit;
  if DbgHeader(DbgInstrumented) <> 1 then
  begin
    Log('Эмулятор: скетч собран без отладочных вставок - строку надписи ' +
        'не узнать (соберите заново)');
    Exit;
  end;
  SetDbgHeader(DbgWhereXY, Cardinal(AX) or (Cardinal(AY) shl 16));
  SetDbgHeader(DbgWhereSeq, DbgHeader(DbgWhereSeq) + 1);
  FWhereWait := True;
  FWhereTick := GetTickCount;
end;

// Ответ эмулятора на клик по экрану: поля пишутся до WhereDone
procedure TArdSimPanel.PollWhere;
var
  Count, CodeIdx: Integer;
begin
  if DbgHeader(DbgWhereDone) <> DbgHeader(DbgWhereSeq) then
  begin
    if GetTickCount - FWhereTick > DbgWhereTimeoutMs then
    begin
      FWhereWait := False;
      Log('Эмулятор не ответил, где нарисована надпись: скетч собран ' +
          'прежней версией ArdSim - соберите его заново');
      if FMenuPending then
        FireCtlMenu;
    end;
    Exit;
  end;
  FWhereWait := False;
  Count := Integer(DbgHeader(DbgWhereCount));
  if Count > DbgWhereMax then
    Count := DbgWhereMax;
  if Count < 0 then
    Count := 0;
  SetLength(FWhereCodes, Count);
  for CodeIdx := 0 to Count - 1 do
    FWhereCodes[CodeIdx] := DbgHeader(DbgWhereCodes + CodeIdx);
  FWhereText := ReadDbgText(DbgWhereText * 4, DbgWhereTextBytes);
  if Assigned(FOnScreenWhere) then
    FOnScreenWhere(Self);
  if FMenuPending then
    FireCtlMenu;
end;

function TArdSimPanel.DbgAvailable: Boolean;
begin
  Result := Running and (DbgHeader(DbgInstrumented) = 1);
end;

function TArdSimPanel.DbgStopped: Boolean;
begin
  Result := Running and FDbgStopped;
end;

function TArdSimPanel.DbgStepping: Boolean;
begin
  Result := Running and FDbgStepping;
end;

function TArdSimPanel.DbgStopCode: Cardinal;
begin
  Result := DbgHeader(DbgStopCodeIdx);
end;

procedure TArdSimPanel.DbgCommand(ACode: Integer; AArg: Cardinal);
begin
  if not Running then
    Exit;
  SetDbgHeader(DbgCmdCode, Cardinal(ACode));
  SetDbgHeader(DbgCmdArg, AArg);
  SetDbgHeader(DbgCmdSeq, DbgHeader(DbgCmdSeq) + 1);
  FDbgStepping := (ACode = ArdDbgInto) or (ACode = ArdDbgOver) or
                  (ACode = ArdDbgOut) or (ACode = ArdDbgPause);
  if FDbgStopped and (ACode <> ArdDbgPause) then
  begin
    // строка остановки гаснет сразу, не дожидаясь эмулятора
    FDbgStopped := False;
    SetStatus('Работает: ' + ExtractFileName(FSketchFile));
    if Assigned(FOnDbgResume) then
      FOnDbgResume(Self);
  end;
end;

procedure TArdSimPanel.SetStartCommand(ACode: Integer; AArg: Cardinal);
begin
  FDbgStartCmd := ACode;
  FDbgStartArg := AArg;
  FDbgStartAssign := '';
end;

procedure TArdSimPanel.SetStartAssign(ACode: Cardinal; const AAssign: string);
begin
  FDbgStartCmd := ArdDbgRunToSet;
  FDbgStartArg := ACode;
  FDbgStartAssign := AAssign;
end;

// Запрос Watch в общей памяти: выражения AText (по строке) и строка
// "=Имя=Значение" запуска с карты окон
procedure TArdSimPanel.WriteWatchRequest(const AText: string);
var
  Text: string;
  Target: PAnsiChar;
begin
  if DbgArea = nil then
    Exit;
  Text := AText;
  if FDbgRunAssign <> '' then
    Text := Text + '=' + FDbgRunAssign + #10;
  if Length(Text) >= DbgWatchReqBytes then
    Text := Copy(Text, 1, DbgWatchReqBytes - 1);
  Target := DbgArea + DbgWatchReqOffset;
  if Text <> '' then
    Move(Text[1], Target^, Length(Text));
  Target[Length(Text)] := #0;
end;

procedure TArdSimPanel.DbgSetBreakpoints(const ACodes: TArdDbgCodes);
var
  Text: string;
  CodeIdx, Count: Integer;
  List: PCardinal;
begin
  if DbgArea = nil then
    Exit;
  Text := '';
  for CodeIdx := 0 to High(ACodes) do
    Text := Text + IntToStr(ACodes[CodeIdx]) + ',';
  if Text = FDbgBreaks then
    Exit;
  FDbgBreaks := Text;
  Count := Length(ACodes);
  if Count > DbgMaxBreaks then
    Count := DbgMaxBreaks;
  List := PCardinal(DbgArea + DbgBreakOffset);
  for CodeIdx := 0 to Count - 1 do
  begin
    List^ := ACodes[CodeIdx];
    Inc(List);
  end;
  SetDbgHeader(DbgBpCount, Cardinal(Count));
  SetDbgHeader(DbgBpVersion, DbgHeader(DbgBpVersion) + 1);
end;

function ArdSimCompareNames(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := CompareStr(List[Index1], List[Index2]);
end;

function TArdSimPanel.DbgFileIndex(const AFileName: string): Integer;
var
  FileIdx: Integer;
  Search: TSearchRec;
  Others: TStringList;
  Dir: string;
begin
  Result := -1;
  if AFileName = '' then
    Exit;
  if FDbgFiles.Count > 0 then
  begin
    for FileIdx := 0 to FDbgFiles.Count - 1 do
      if CompareText(ExpandFileName(FDbgFiles[FileIdx]),
                     ExpandFileName(AFileName)) = 0 then
      begin
        Result := FileIdx;
        Exit;
      end;
    Exit;
  end;
  // эмулятор ещё не сказал: то же правило, что у ardprep
  if FSketchFile = '' then
    Exit;
  if CompareText(ExpandFileName(FSketchFile), ExpandFileName(AFileName)) = 0 then
  begin
    Result := 0;
    Exit;
  end;
  Dir := ExtractFilePath(ExpandFileName(FSketchFile));
  if CompareText(ExtractFilePath(ExpandFileName(AFileName)), Dir) <> 0 then
    Exit;
  Others := TStringList.Create;
  try
    if FindFirst(Dir + '*.ino', faAnyFile, Search) = 0 then
    begin
      repeat
        if (CompareText(Search.Name, ExtractFileName(FSketchFile)) <> 0) and
           (CompareText(ExtractFileExt(Search.Name), '.ino') = 0) then
          Others.Add(Search.Name);
      until FindNext(Search) <> 0;
      FindClose(Search);
    end;
    Others.CustomSort(ArdSimCompareNames);
    for FileIdx := 0 to Others.Count - 1 do
      if CompareText(Others[FileIdx], ExtractFileName(AFileName)) = 0 then
      begin
        Result := FileIdx + 1;
        Exit;
      end;
  finally
    Others.Free;
  end;
end;

function TArdSimPanel.DbgFileName(AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < FDbgFiles.Count) then
    Result := FDbgFiles[AIndex]
  else if AIndex = 0 then
    Result := FSketchFile
  else
    Result := '';
end;

procedure TArdSimPanel.DbgSetWatch(AExprs: TStrings);
var
  Text: string;
  ExprIdx: Integer;
begin
  if DbgArea = nil then
    Exit;
  Text := '';
  for ExprIdx := 0 to AExprs.Count - 1 do
    Text := Text + AExprs[ExprIdx] + #10;
  if Length(Text) >= DbgWatchReqBytes then
    Text := Copy(Text, 1, DbgWatchReqBytes - 1);
  if Text = FDbgWatch then
    Exit;
  FDbgWatch := Text;
  WriteWatchRequest(Text);
  SetDbgHeader(DbgWatchSeq, DbgHeader(DbgWatchSeq) + 1);
end;

// Строка ответа "APrefix..." - в ARest остаток после префикса
function TArdSimPanel.DbgLine(const APrefix: string; var ARest: string): Boolean;
var
  LineIdx: Integer;
begin
  Result := False;
  for LineIdx := 0 to FDbgInfo.Count - 1 do
    if Copy(FDbgInfo[LineIdx], 1, Length(APrefix)) = APrefix then
    begin
      ARest := Copy(FDbgInfo[LineIdx], Length(APrefix) + 1, MaxInt);
      Result := True;
      Exit;
    end;
end;

function TArdSimPanel.DbgWatchResult(AIndex: Integer; var AValue: string): Boolean;
var
  Rest: string;
begin
  AValue := '';
  Result := DbgLine('W'#9 + IntToStr(AIndex) + #9, Rest);
  if not Result then
    Exit;
  if Copy(Rest, 1, 1) = '=' then
    AValue := Copy(Rest, 2, MaxInt)
  else if Rest = '?' then
    AValue := '<нет такой переменной: Watch эмулятора показывает глобальные ' +
              'и локальные переменные скетча, имя или имя[индекс]>'
  else
    AValue := '<не разобрано или индекс вне массива>';
end;

function TArdSimPanel.DbgVarValue(const AName: string; var AValue: string): Boolean;
begin
  Result := DbgLine('L'#9 + AName + #9, AValue) or DbgLine('G'#9 + AName + #9, AValue);
end;

procedure TArdSimPanel.DbgLocalNames(ANames: TStrings);
var
  LineIdx: Integer;
  Text: string;
begin
  for LineIdx := 0 to FDbgInfo.Count - 1 do
  begin
    Text := FDbgInfo[LineIdx];
    if Copy(Text, 1, 2) <> 'L'#9 then
      Continue;
    Text := Copy(Text, 3, MaxInt);
    ANames.Add(Copy(Text, 1, Pos(#9, Text) - 1));
  end;
end;

function TArdSimPanel.DbgWhere: string;
var
  LineIdx: Integer;
  Text: string;
begin
  Result := '';
  for LineIdx := 0 to FDbgInfo.Count - 1 do
  begin
    Text := FDbgInfo[LineIdx];
    if Copy(Text, 1, 2) <> 'F'#9 then
      Continue;
    Text := Copy(Text, 3, MaxInt);
    Text := Copy(Text, 1, Pos(#9, Text) - 1);
    if Result = '' then
      Result := Text
    else
      Result := Result + ' <- ' + Text;
  end;
end;

procedure TArdSimPanel.TimerTick(Sender: TObject);
begin
  PollBuild;
  PollSim;
  SigPoll;
  if (FBuild = nil) and (FSim = nil) then
    FTimer.Enabled := False;
end;


// Экран: RGB565 из общей памяти -> 32 бита -> StretchDIBits в ARect
// (3:2). Эмулятор не запущен - последняя картинка (её копия в FPixels)
// или пустое поле
procedure TArdSimPanel.PaintScreen(ACanvas: TCanvas; const ARect: TRect);
var
  {$IFDEF MSWINDOWS}
  Info: TBitmapInfo;
  Source: PWord;
  PixelIdx: Integer;
  Color, Red, Green, Blue: Cardinal;
  {$ENDIF}
  AreaW, AreaH, DrawW, DrawH, DrawX, DrawY: Integer;
begin
  AreaW := ARect.Right - ARect.Left;
  AreaH := ARect.Bottom - ARect.Top;
  ACanvas.Brush.Color := clBlack;
  ACanvas.FillRect(ARect);
  DrawW := AreaW;
  DrawH := DrawW * ArdSimScreenH div ArdSimScreenW;
  if DrawH > AreaH then
  begin
    DrawH := AreaH;
    DrawW := DrawH * ArdSimScreenW div ArdSimScreenH;
  end;
  DrawX := ARect.Left + (AreaW - DrawW) div 2;
  DrawY := ARect.Top + (AreaH - DrawH) div 2;
  {$IFDEF MSWINDOWS}
  if FView <> nil then
  begin
    Source := PWord(PAnsiChar(FView) + HeaderBytes);
    for PixelIdx := 0 to ArdSimScreenW * ArdSimScreenH - 1 do
    begin
      Color := Source^;
      Inc(Source);
      Red := (Color shr 11) and $1F;
      Green := (Color shr 5) and $3F;
      Blue := Color and $1F;
      Red := (Red shl 3) or (Red shr 2);
      Green := (Green shl 2) or (Green shr 4);
      Blue := (Blue shl 3) or (Blue shr 2);
      FPixels[PixelIdx] := (Red shl 16) or (Green shl 8) or Blue;
    end;
    if (FPreview <> nil) or ((FKept <> nil) and (FKept.Count > 0)) then
      DrawPreview;
    if PhantomCount > 0 then
      DrawPhantoms;
    if FSelCtlHash <> 0 then
      DrawCtlMarker;
  end;
  if FHasPicture then
  begin
    FillChar(Info, SizeOf(Info), 0);
    Info.bmiHeader.biSize := SizeOf(TBitmapInfoHeader);
    Info.bmiHeader.biWidth := ArdSimScreenW;
    Info.bmiHeader.biHeight := -ArdSimScreenH;   // сверху вниз
    Info.bmiHeader.biPlanes := 1;
    Info.bmiHeader.biBitCount := 32;
    Info.bmiHeader.biCompression := BI_RGB;
    // меньше 1:1 - HALFTONE (тонкие линии и мелкий текст не пропадают)
    if DrawW < ArdSimScreenW then
    begin
      SetStretchBltMode(ACanvas.Handle, HALFTONE);
      SetBrushOrgEx(ACanvas.Handle, 0, 0, nil);
    end
    else
      SetStretchBltMode(ACanvas.Handle, COLORONCOLOR);
    StretchDIBits(ACanvas.Handle, DrawX, DrawY, DrawW, DrawH, 0, 0,
      ArdSimScreenW, ArdSimScreenH, @FPixels[0], Info, DIB_RGB_COLORS, SRCCOPY);
  end
  else
  {$ENDIF}
  begin
    ACanvas.Font.Color := clGray;
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Height := -11;
    ACanvas.Font.Style := [];
    ACanvas.TextOut(DrawX + 6, DrawY + 6, 'Build - собрать и запустить');
    ACanvas.Brush.Style := bsSolid;
  end;
end;

// Все шрифты файлов, которые берёт build_sim.cmd, в его порядке: список
// unIDE (libraries), .c папки скетча, %ARDSIM_FONTS%, замены ArdSim\fonts.
// Первый шрифт с именем - тот, что в сборке (повтор линкер бы не принял)
procedure TArdSimPanel.LoadFontCache;
var
  Files, Lines: TStringList;
  ListName, SimDir, EnvDir: string;
  ResIdx: Integer;

  procedure AddFolder(const AFolder: string);
  var
    Found: TSearchRec;
    Names: TStringList;
    NameIdx: Integer;
  begin
    if (AFolder = '') or not DirectoryExists(AFolder) then
      Exit;
    Names := TStringList.Create;
    try
      if FindFirst(IncludeTrailingPathDelimiter(AFolder) + '*.c', faAnyFile,
                   Found) = 0 then
      begin
        repeat
          if (Found.Attr and faDirectory) = 0 then
            Names.Add(IncludeTrailingPathDelimiter(AFolder) + Found.Name);
        until FindNext(Found) <> 0;
        FindClose(Found);
      end;
      Names.Sort;
      for NameIdx := 0 to Names.Count - 1 do
        Files.Add(Names[NameIdx]);
    finally
      Names.Free;
    end;
  end;

var
  PhIdx: Integer;
begin
  // Превью держат шрифты кэша
  ClearAllPreviews;
  // и надписи до сборки: шрифт найдут заново (Unit1.ArdSyncPhantoms)
  if FPhantoms <> nil then
    for PhIdx := 0 to FPhantoms.Count - 1 do
      TArdSimPhantom(FPhantoms[PhIdx]).Font := nil;
  if FFontCache = nil then
    FFontCache := TList.Create;
  for ResIdx := 0 to FFontCache.Count - 1 do
    TObject(FFontCache[ResIdx]).Free;
  FFontCache.Clear;
  FFontCacheSketch := FSketchFile;
  Files := TStringList.Create;
  Lines := TStringList.Create;
  try
    if FSketchFile <> '' then
    begin
      ListName := IncludeTrailingPathDelimiter(ExtractFilePath(FSketchFile) +
                  'ardsim_build') + ArdSimFontListName;
      if FileExists(ListName) then
      try
        Lines.LoadFromFile(ListName);
        for ResIdx := 0 to Lines.Count - 1 do
          if Trim(Lines[ResIdx]) <> '' then
            Files.Add(Trim(Lines[ResIdx]));
      except
        // список не прочитался - остальные папки
      end;
      AddFolder(ExtractFilePath(FSketchFile));
    end;
    EnvDir := SysUtils.GetEnvironmentVariable('ARDSIM_FONTS');
    AddFolder(EnvDir);
    SimDir := FArdSimDir;
    if SimDir = '' then
      SimDir := ArdSimFindDir;
    if SimDir <> '' then
      AddFolder(IncludeTrailingPathDelimiter(SimDir) + 'fonts');
    for ResIdx := 0 to Files.Count - 1 do
      if FileExists(Files[ResIdx]) then
      try
        UtftParseFile(Files[ResIdx], FFontCache);
      except
        // не шрифт или не читается - пропуск
      end;
  finally
    Files.Free;
    Lines.Free;
  end;
end;

function TArdSimPanel.FindFont(const AName: string): TUtftFont;
var
  FontIdx: Integer;
  Item: TUtftFont;
begin
  Result := nil;
  if (FFontCache = nil) or (FFontCacheSketch <> FSketchFile) then
    LoadFontCache;
  for FontIdx := 0 to FFontCache.Count - 1 do
  begin
    Item := TUtftFont(FFontCache[FontIdx]);
    if Item.IsFont and (Item.Name = AName) then
    begin
      Result := Item;
      Exit;
    end;
  end;
  // не из сборки: шрифт библиотек, ещё не объявленный в скетче
  if FLibFonts <> nil then
    for FontIdx := 0 to FLibFonts.Count - 1 do
    begin
      Item := TUtftFont(FLibFonts[FontIdx]);
      if Item.IsFont and (Item.Name = AName) then
      begin
        Result := Item;
        Exit;
      end;
    end;
end;

procedure TArdSimPanel.FreeLibFonts;
var
  FontIdx: Integer;
begin
  if FLibFonts = nil then
    Exit;
  // превью держат шрифты
  ClearAllPreviews;
  for FontIdx := 0 to FLibFonts.Count - 1 do
    TObject(FLibFonts[FontIdx]).Free;
  FreeAndNil(FLibFonts);
  FLibFontsKey := '';
end;

procedure TArdSimPanel.LibraryFontNames(AList: TStrings);
const
  MaxFileSize = 8 * 1024 * 1024;   // как ArdSimFonts
var
  RootIdx, FontIdx: Integer;
  Names: TStringList;
  Item: TUtftFont;

  procedure ScanFolder(const AFolder: string; ADepth: Integer);
  var
    Found: TSearchRec;
    Path: string;
  begin
    if ADepth > 8 then
      Exit;
    Path := IncludeTrailingPathDelimiter(AFolder);
    if FindFirst(Path + '*', faAnyFile, Found) = 0 then
    begin
      repeat
        if (Found.Name = '.') or (Found.Name = '..') then
          Continue;
        if (Found.Attr and faDirectory) <> 0 then
          ScanFolder(Path + Found.Name, ADepth + 1)
        else if SameText(ExtractFileExt(Found.Name), '.c') and
                (Found.Size <= MaxFileSize) then
        try
          UtftParseFile(Path + Found.Name, FLibFonts);
        except
          // не читается - пропуск
        end;
      until FindNext(Found) <> 0;
      FindClose(Found);
    end;
  end;

begin
  AList.Clear;
  if (FLibFonts = nil) or (FLibFontsKey <> FFontRoots.Text) then
  begin
    FreeLibFonts;
    FLibFonts := TList.Create;
    FLibFontsKey := FFontRoots.Text;
    for RootIdx := 0 to FFontRoots.Count - 1 do
      if DirectoryExists(FFontRoots[RootIdx]) then
        ScanFolder(FFontRoots[RootIdx], 0);
  end;
  Names := TStringList.Create;
  try
    Names.Sorted := True;
    Names.Duplicates := dupIgnore;
    Names.CaseSensitive := True;
    for FontIdx := 0 to FLibFonts.Count - 1 do
    begin
      Item := TUtftFont(FLibFonts[FontIdx]);
      if Item.IsFont and (Item.Name <> '') then
        Names.Add(Item.Name);
    end;
    AList.Assign(Names);
  finally
    Names.Free;
  end;
end;

function ColorToRgbWord(AColor: TColor): Cardinal;
var
  Value: Cardinal;
begin
  Value := Cardinal(ColorToRGB(AColor));
  // TColor $00BBGGRR -> $RRGGBB, как FPixels
  Result := ((Value and $FF) shl 16) or (Value and $FF00) or
            ((Value shr 16) and $FF);
end;

type
  // Одна надпись поверх экрана: где, что, каким шрифтом и цветами; сумма
  // точек эмулятора под ней при первом показе
  TArdPreviewItem = class
  public
    PosX, PosY: Integer;
    Text: AnsiString;
    Font: TUtftFont;
    Clear, Area: TRect;
    Fore, Back: Cardinal;   // $RRGGBB
    Transparent: Boolean;
    Proportional: Boolean;
    Sum: Cardinal;
    SumSet: Boolean;
  end;

// Ширина строки превью: по клеткам или как PropTextWidth в BS10.ino
function PreviewTextWidth(AFont: TUtftFont; const AText: AnsiString;
  AProportional: Boolean): Integer;
var
  CharIdx, InkW, InkLeft: Integer;
begin
  if not AProportional then
  begin
    Result := Length(AText) * AFont.SizeX;
    Exit;
  end;
  Result := 0;
  for CharIdx := 1 to Length(AText) do
  begin
    InkW := UtftPropGlyph(AFont, Ord(AText[CharIdx]), InkLeft);
    if InkW > 0 then
      Inc(Result, InkW + UtftPropGap)
    else
      Inc(Result, UtftPropSpace(AFont));
  end;
end;

procedure TArdSimPanel.SetTextPreview(AX, AY: Integer; const AText: AnsiString;
  AFont: TUtftFont; const AClear: TRect; AFore, ABack: TColor;
  ATransparent: Boolean; AProportional: Boolean);
var
  Item: TArdPreviewItem;
begin
  FreeAndNil(FPreview);
  if AFont = nil then
  begin
    FDevice.InvalidateScreen;
    Exit;
  end;
  Item := TArdPreviewItem.Create;
  Item.PosX := AX;
  Item.PosY := AY;
  Item.Text := AText;
  Item.Font := AFont;
  Item.Clear := AClear;
  Item.Fore := ColorToRgbWord(AFore);
  Item.Back := ColorToRgbWord(ABack);
  Item.Transparent := ATransparent;
  Item.Proportional := AProportional;
  // Место превью: прежняя надпись и новая
  Item.Area := AClear;
  if Item.Area.Right <= Item.Area.Left then
    Item.Area := Rect(AX, AY, AX, AY);
  if AX < Item.Area.Left then
    Item.Area.Left := AX;
  if AY < Item.Area.Top then
    Item.Area.Top := AY;
  if AX + PreviewTextWidth(AFont, AText, AProportional) > Item.Area.Right then
    Item.Area.Right := AX + PreviewTextWidth(AFont, AText, AProportional);
  if AY + AFont.SizeY > Item.Area.Bottom then
    Item.Area.Bottom := AY + AFont.SizeY;
  Item.SumSet := False;
  FPreview := Item;
  FDevice.InvalidateScreen;
end;

procedure TArdSimPanel.ClearTextPreview;
begin
  if FPreview = nil then
    Exit;
  FreeAndNil(FPreview);
  FDevice.InvalidateScreen;
end;

procedure TArdSimPanel.KeepTextPreview;
var
  Item, Old: TArdPreviewItem;
  KeptIdx: Integer;
begin
  if FPreview = nil then
    Exit;
  Item := TArdPreviewItem(FPreview);
  FPreview := nil;
  if FKept = nil then
    FKept := TList.Create;
  // Та же надпись выбрана ещё раз - прежнее превью не нужно
  for KeptIdx := FKept.Count - 1 downto 0 do
  begin
    Old := TArdPreviewItem(FKept[KeptIdx]);
    if (Old.PosX = Item.PosX) and (Old.PosY = Item.PosY) then
    begin
      Old.Free;
      FKept.Delete(KeptIdx);
    end;
  end;
  FKept.Add(Item);
  FDevice.InvalidateScreen;
end;

procedure TArdSimPanel.ClearAllPreviews;
var
  KeptIdx: Integer;
begin
  FreeAndNil(FPreview);
  if FKept <> nil then
  begin
    for KeptIdx := 0 to FKept.Count - 1 do
      TObject(FKept[KeptIdx]).Free;
    FKept.Clear;
  end;
end;

function TArdSimPanel.PreviewShown: Boolean;
begin
  Result := FPreview <> nil;
end;

function TArdSimPanel.ArgOverrideAvailable: Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := (FView <> nil) and Running and (Header(HdrArgTable) = 1);
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

// FNV-1a имени: как nameHash в ArdSim\tools\ardprep.cpp
function ArgNameHash(const AName: string): Cardinal;
var
  CharIdx: Integer;
begin
  Result := 2166136261;
  for CharIdx := 1 to Length(AName) do
  begin
    Result := Result xor Ord(AName[CharIdx]);
    // в Int64 без переполнения, младшие 32 бита
    Result := Cardinal((Int64(Result) * 16777619) and $FFFFFFFF);
  end;
end;

type
  // Запись таблицы показанного по 16 бит (CtlShownBytes)
  TSmallIntArrayH = array[0..15] of SmallInt;
  PSmallIntArrayH = ^TSmallIntArrayH;

function ArdSimNameHash(const AName: string): Cardinal;
begin
  Result := ArgNameHash(AName);
end;

function TArdSimPanel.CtlOverrideAvailable: Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := (FView <> nil) and Running and (Header(HdrCtlTable) = 1);
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function TArdSimPanel.SetCtlOverride(const AName: string; AProp, AKind,
  ANumber: Integer; const AText: string): Boolean;
begin
  Result := SetCtlOverrideHash(ArgNameHash(AName), AProp, AKind, ANumber, AText);
end;

function TArdSimPanel.SetCtlOverrideHash(AHash: Cardinal; AProp, AKind,
  ANumber: Integer; const AText: string): Boolean;
{$IFDEF MSWINDOWS}
var
  Table: PCardinal;
  Count, EntryIdx, Found, CharIdx: Integer;
  Hash: Cardinal;
  Text: PAnsiChar;

  function Field(AEntry, AIndex: Integer): PCardinal;
  begin
    Result := PCardinal(PAnsiChar(Table) + 16 + AEntry * CtlEntryBytes +
                        AIndex * 4);
  end;
{$ENDIF}
begin
  Result := False;
  {$IFDEF MSWINDOWS}
  if not CtlOverrideAvailable or (AKind < 1) or (AKind > 3) then
    Exit;
  Table := PCardinal(PAnsiChar(FView) + CtlOffset);
  Hash := AHash;
  Count := Table^;
  if Count > CtlMaxEntries then
    Count := CtlMaxEntries;
  Found := -1;
  for EntryIdx := 0 to Count - 1 do
    if (Field(EntryIdx, 0)^ = Hash) and (Field(EntryIdx, 1)^ = Cardinal(AProp)) then
    begin
      Found := EntryIdx;
      Break;
    end;
  if Found < 0 then
  begin
    if Count >= CtlMaxEntries then
      Exit;
    Found := Count;
  end;
  // Вид - последним, версия - после всего: эмулятор читает без блокировки
  Field(Found, 2)^ := 0;
  Field(Found, 0)^ := Hash;
  Field(Found, 1)^ := Cardinal(AProp);
  Field(Found, 3)^ := Cardinal(ANumber);
  Text := PAnsiChar(Field(Found, 4));
  FillChar(Text^, CtlTextChars, 0);
  for CharIdx := 1 to Length(AText) do
    if CharIdx < CtlTextChars then
      Text[CharIdx - 1] := AnsiChar(AText[CharIdx]);
  Field(Found, 2)^ := Cardinal(AKind);
  if Found >= Count then
    Table^ := Found + 1;
  Inc(PCardinal(PAnsiChar(Table) + 4)^);
  Result := True;
  {$ENDIF}
end;

// ---- выбранная надпись TLabel: рамка и перетаскивание мышью

// Запись надписи AHash в таблице показанного, если она на экране сейчас
// (после неё экран не очищался); nil - нет
function TArdSimPanel.CtlShownEntry(AHash: Cardinal): PCardinal;
{$IFDEF MSWINDOWS}
var
  Shown: PCardinal;
  Count, EntryIdx: Integer;
  Entry: PCardinal;
{$ENDIF}
begin
  Result := nil;
  {$IFDEF MSWINDOWS}
  if (AHash = 0) or not CtlOverrideAvailable then
    Exit;
  Shown := PCardinal(PAnsiChar(FView) + CtlOffset + CtlShownOffset);
  // эмулятор другой версии: другие записи
  if PCardinal(PAnsiChar(Shown) + 8)^ <> CtlShownBytes then
    Exit;
  Count := Integer(PCardinal(PAnsiChar(Shown) + 4)^);
  if Count > CtlMaxControls then
    Count := CtlMaxControls;
  for EntryIdx := 0 to Count - 1 do
  begin
    Entry := PCardinal(PAnsiChar(Shown) + 16 + EntryIdx * CtlShownBytes);
    if Entry^ = AHash then
    begin
      if PCardinal(PAnsiChar(Entry) + 4)^ = Shown^ then
        Result := Entry;
      Exit;
    end;
  end;
  {$ENDIF}
end;

// Рамка занятых надписью точек: Right, Bottom - за последней точкой
function TArdSimPanel.CtlShownBox(AEntry: PCardinal): TRect;
var
  Words: PSmallIntArrayH;
begin
  Words := PSmallIntArrayH(AEntry);
  Result := Rect(Words^[6], Words^[7], Words^[8] + 1, Words^[9] + 1);
end;

// Надпись TLabel, нарисованная в точке AX, AY экрана: из нескольких -
// с меньшей рамкой (подпись внутри панели). 0 - нет
function TArdSimPanel.CtlHashAt(AX, AY: Integer): Cardinal;
var
  BestArea, Area, PhIdx: Integer;
  Phantom: TArdSimPhantom;
begin
  Result := CtlSimHashAt(AX, AY, BestArea);
  if FPhantoms = nil then
    Exit;
  for PhIdx := 0 to FPhantoms.Count - 1 do
  begin
    Phantom := TArdSimPhantom(FPhantoms[PhIdx]);
    if Phantom.Shown and PtInRect(Phantom.Box, Point(AX, AY)) then
    begin
      Area := (Phantom.Box.Right - Phantom.Box.Left) * (Phantom.Box.Bottom - Phantom.Box.Top);
      if (Result = 0) or (Area < BestArea) then
      begin
        BestArea := Area;
        Result := Phantom.Hash;
      end;
    end;
  end;
end;

// Только надписи эмулятора; AArea - площадь рамки найденной
function TArdSimPanel.CtlSimHashAt(AX, AY: Integer; var AArea: Integer): Cardinal;
{$IFDEF MSWINDOWS}
var
  Shown, Entry: PCardinal;
  Count, EntryIdx, Area, BestArea: Integer;
  Box: TRect;
{$ENDIF}
begin
  Result := 0;
  AArea := MaxInt;
  {$IFDEF MSWINDOWS}
  if not CtlOverrideAvailable then
    Exit;
  Shown := PCardinal(PAnsiChar(FView) + CtlOffset + CtlShownOffset);
  if PCardinal(PAnsiChar(Shown) + 8)^ <> CtlShownBytes then
    Exit;
  Count := Integer(PCardinal(PAnsiChar(Shown) + 4)^);
  if Count > CtlMaxControls then
    Count := CtlMaxControls;
  BestArea := MaxInt;
  for EntryIdx := 0 to Count - 1 do
  begin
    Entry := PCardinal(PAnsiChar(Shown) + 16 + EntryIdx * CtlShownBytes);
    if PCardinal(PAnsiChar(Entry) + 4)^ <> Shown^ then
      Continue;
    Box := CtlShownBox(Entry);
    if PtInRect(Box, Point(AX, AY)) then
    begin
      Area := (Box.Right - Box.Left) * (Box.Bottom - Box.Top);
      if Area < BestArea then
      begin
        BestArea := Area;
        Result := Entry^;
      end;
    end;
  end;
  AArea := BestArea;
  {$ENDIF}
end;

// Показанная сейчас надпись, рамка которой ближе всего к точке AX, AY
// (расстояние до рамки); 0 - на экране надписей нет
function TArdSimPanel.CtlNearestHash(AX, AY: Integer; var ABox: TRect): Cardinal;
{$IFDEF MSWINDOWS}
var
  Shown, Entry: PCardinal;
  Count, EntryIdx, DistX, DistY, Dist, BestDist: Integer;
  Box: TRect;
{$ENDIF}
begin
  Result := 0;
  ABox := Rect(0, 0, 0, 0);
  {$IFDEF MSWINDOWS}
  if not CtlOverrideAvailable then
    Exit;
  Shown := PCardinal(PAnsiChar(FView) + CtlOffset + CtlShownOffset);
  if PCardinal(PAnsiChar(Shown) + 8)^ <> CtlShownBytes then
    Exit;
  Count := Integer(PCardinal(PAnsiChar(Shown) + 4)^);
  if Count > CtlMaxControls then
    Count := CtlMaxControls;
  BestDist := MaxInt;
  for EntryIdx := 0 to Count - 1 do
  begin
    Entry := PCardinal(PAnsiChar(Shown) + 16 + EntryIdx * CtlShownBytes);
    if PCardinal(PAnsiChar(Entry) + 4)^ <> Shown^ then
      Continue;
    Box := CtlShownBox(Entry);
    if Box.Right <= Box.Left then
      Continue;
    DistX := 0;
    if AX < Box.Left then
      DistX := Box.Left - AX
    else if AX >= Box.Right then
      DistX := AX - Box.Right + 1;
    DistY := 0;
    if AY < Box.Top then
      DistY := Box.Top - AY
    else if AY >= Box.Bottom then
      DistY := AY - Box.Bottom + 1;
    Dist := DistX * DistX + DistY * DistY;
    if Dist < BestDist then
    begin
      BestDist := Dist;
      Result := Entry^;
      ABox := Box;
    end;
  end;
  {$ENDIF}
end;

function TArdSimPanel.CtlShownText(const AName: string; var AX, AY: Integer;
  var AText: string; var AFore, ABack: TColor; var AClear: TRect): Boolean;
var
  Entry: PCardinal;
  Words: PSmallIntArrayH;
  Chars: PAnsiChar;
  CharIdx, FontW, FontH: Integer;
  ColorWord: Cardinal;

  function Rgb565ToTColor(AValue: Cardinal): TColor;
  var
    Red, Green, Blue: Cardinal;
  begin
    Red := (AValue shr 11) and $1F;
    Green := (AValue shr 5) and $3F;
    Blue := AValue and $1F;
    Red := (Red shl 3) or (Red shr 2);
    Green := (Green shl 2) or (Green shr 4);
    Blue := (Blue shl 3) or (Blue shr 2);
    Result := TColor(Red or (Green shl 8) or (Blue shl 16));
  end;

begin
  Result := False;
  Entry := CtlShownEntry(ArgNameHash(AName));
  if Entry = nil then
    Exit;
  Words := PSmallIntArrayH(Entry);
  AX := Words^[4] + 3;
  AY := Words^[5] + 4;
  ColorWord := PCardinal(PAnsiChar(Entry) + 20)^;
  AFore := Rgb565ToTColor(ColorWord and $FFFF);
  ABack := Rgb565ToTColor(ColorWord shr 16);
  FontW := PByte(PAnsiChar(Entry) + 24)^;
  FontH := PByte(PAnsiChar(Entry) + 25)^;
  Chars := PAnsiChar(Entry) + CtlShownTextOffset;
  AText := '';
  CharIdx := 0;
  while (CharIdx < CtlShownBytes - CtlShownTextOffset) and (Chars[CharIdx] <> #0) do
  begin
    AText := AText + Chars[CharIdx];
    Inc(CharIdx);
  end;
  AClear := Rect(AX, AY, AX + Length(AText) * FontW, AY + FontH);
  Result := AText <> '';
end;

function TArdSimPanel.CtlOverPoint(AX, AY: Integer): Boolean;
var
  Entry: PCardinal;
begin
  Result := False;
  if FSelCtlHash = 0 then
    Exit;
  Entry := CtlShownEntry(FSelCtlHash);
  Result := (Entry <> nil) and PtInRect(CtlShownBox(Entry), Point(AX, AY));
  if not Result and (PhantomByHash(FSelCtlHash) <> nil) then
    Result := PhantomByHash(FSelCtlHash).Shown and
              PtInRect(PhantomByHash(FSelCtlHash).Box, Point(AX, AY));
end;

procedure TArdSimPanel.SetSelectedControl(const AName: string);
var
  Hash: Cardinal;
begin
  if AName = '' then
    Hash := 0
  else
    Hash := ArgNameHash(AName);
  if FDragging then
    Exit;
  // Уже среди выбранных (Ctrl+щелчок, переход к строке) - она главная,
  // остальные остаются
  if (Hash <> 0) and CtlSelected(Hash) then
  begin
    if Hash <> FSelCtlHash then
    begin
      CtlMakePrimary(Hash);
      FDevice.InvalidateScreen;
    end;
    Exit;
  end;
  if (Hash = FSelCtlHash) and (Length(FSelExtra) = 0) then
    Exit;
  SetLength(FSelExtra, 0);
  FSelCtlHash := Hash;
  FDevice.InvalidateScreen;
end;

function TArdSimPanel.CtlSelected(AHash: Cardinal): Boolean;
var
  SelIdx: Integer;
begin
  Result := (AHash <> 0) and (AHash = FSelCtlHash);
  if not Result and (AHash <> 0) then
    for SelIdx := 0 to High(FSelExtra) do
      if FSelExtra[SelIdx] = AHash then
      begin
        Result := True;
        Exit;
      end;
end;

// Выбранная Ctrl+щелчком становится главной, прежняя главная - на её место
procedure TArdSimPanel.CtlMakePrimary(AHash: Cardinal);
var
  SelIdx: Integer;
begin
  for SelIdx := 0 to High(FSelExtra) do
    if FSelExtra[SelIdx] = AHash then
    begin
      FSelExtra[SelIdx] := FSelCtlHash;
      FSelCtlHash := AHash;
      Exit;
    end;
end;

procedure TArdSimPanel.CtlSelToggle(AHash: Cardinal);
var
  SelIdx, Last: Integer;
begin
  Last := High(FSelExtra);
  if AHash = FSelCtlHash then
  begin
    if Last >= 0 then
    begin
      FSelCtlHash := FSelExtra[Last];
      SetLength(FSelExtra, Last);
    end
    else
      FSelCtlHash := 0;
    Exit;
  end;
  for SelIdx := 0 to Last do
    if FSelExtra[SelIdx] = AHash then
    begin
      FSelExtra[SelIdx] := FSelExtra[Last];
      SetLength(FSelExtra, Last);
      Exit;
    end;
  if FSelCtlHash = 0 then
    FSelCtlHash := AHash
  else
  begin
    SetLength(FSelExtra, Last + 2);
    FSelExtra[Last + 1] := AHash;
  end;
end;

function TArdSimPanel.SelectedCount: Integer;
begin
  if FSelCtlHash = 0 then
    Result := 0
  else
    Result := 1 + Length(FSelExtra);
end;

function TArdSimPanel.SelectedHash(AIndex: Integer): Cardinal;
begin
  Result := 0;
  if AIndex = 0 then
    Result := FSelCtlHash
  else if (FSelCtlHash <> 0) and (AIndex >= 1) and (AIndex <= Length(FSelExtra)) then
    Result := FSelExtra[AIndex - 1];
end;

// Где надпись сейчас: Left, Top (из таблицы показанных или надписи до
// сборки) и занятые точки
function TArdSimPanel.CtlPlace(AHash: Cardinal; var ALeft, ATop: Integer;
  var ABox: TRect; var AIsPhantom: Boolean): Boolean;
var
  Entry: PCardinal;
  Words: PSmallIntArrayH;
  Phantom: TArdSimPhantom;
begin
  Result := False;
  AIsPhantom := False;
  if AHash = 0 then
    Exit;
  Entry := CtlShownEntry(AHash);
  if Entry <> nil then
  begin
    Words := PSmallIntArrayH(Entry);
    ALeft := Words^[4];
    ATop := Words^[5];
    ABox := CtlShownBox(Entry);
    Result := True;
    Exit;
  end;
  Phantom := PhantomByHash(AHash);
  if (Phantom = nil) or not Phantom.Shown then
    Exit;
  ALeft := Phantom.Left;
  ATop := Phantom.Top;
  ABox := Phantom.Box;
  AIsPhantom := True;
  Result := True;
end;

function TArdSimPanel.CtlBoxOf(AHash: Cardinal; var ABox: TRect): Boolean;
var
  PosLeft, PosTop: Integer;
  IsPhantom: Boolean;
begin
  Result := CtlPlace(AHash, PosLeft, PosTop, ABox, IsPhantom);
end;

// Новое место - сразу в эмулятор (таблица правок) или надписи до сборки
procedure TArdSimPanel.CtlMoveTo(var AItem: TArdDragItem; ANewLeft, ANewTop: Integer);
var
  Phantom: TArdSimPhantom;
begin
  if ANewLeft < 0 then
    ANewLeft := 0;
  if ANewTop < 0 then
    ANewTop := 0;
  if ANewLeft > ArdSimScreenW - 1 then
    ANewLeft := ArdSimScreenW - 1;
  if ANewTop > ArdSimScreenH - 1 then
    ANewTop := ArdSimScreenH - 1;
  if AItem.IsPhantom then
  begin
    Phantom := PhantomByHash(AItem.Hash);
    if Phantom <> nil then
    begin
      Phantom.Left := ANewLeft;
      Phantom.Top := ANewTop;
      FDevice.InvalidateScreen;
    end;
  end
  else
  begin
    if ANewLeft <> AItem.NewLeft then
      SetCtlOverrideHash(AItem.Hash, 0, 1, ANewLeft, '');
    if ANewTop <> AItem.NewTop then
      SetCtlOverrideHash(AItem.Hash, 1, 1, ANewTop, '');
  end;
  AItem.NewLeft := ANewLeft;
  AItem.NewTop := ANewTop;
end;

function TArdSimPanel.CtlDragHas(AHash: Cardinal): Boolean;
var
  ItemIdx: Integer;
begin
  Result := False;
  if not FDragging then
    Exit;
  for ItemIdx := 0 to High(FDragItems) do
    if FDragItems[ItemIdx].Hash = AHash then
    begin
      Result := True;
      Exit;
    end;
end;

function TArdSimPanel.SnapGrid(AValue: Integer): Integer;
begin
  Result := AValue;
  if FGridStep <= 1 then
    Exit;
  if AValue < 0 then
    Result := 0
  else
    Result := ((AValue + FGridStep div 2) div FGridStep) * FGridStep;
end;

function TArdSimPanel.AlignSelected(AMode: Integer): Integer;
var
  Items: array of TArdDragItem;
  Boxes: array of TRect;
  Order: array of Integer;
  Count, SelIdx, ItemIdx, OtherIdx, Swap, Target, Span, SizeSum, SizeBefore,
  FreeSpace, Size, NewPos: Integer;
  Box: TRect;
  PosLeft, PosTop: Integer;
  IsPhantom, Vertical: Boolean;
begin
  Result := 0;
  if FDragging then
    Exit;
  SetLength(Items, SelectedCount);
  SetLength(Boxes, SelectedCount);
  Count := 0;
  for SelIdx := 0 to SelectedCount - 1 do
    if CtlPlace(SelectedHash(SelIdx), PosLeft, PosTop, Box, IsPhantom) then
    begin
      Items[Count].Hash := SelectedHash(SelIdx);
      Items[Count].IsPhantom := IsPhantom;
      Items[Count].Left := PosLeft;
      Items[Count].Top := PosTop;
      Items[Count].NewLeft := PosLeft;
      Items[Count].NewTop := PosTop;
      Boxes[Count] := Box;
      Inc(Count);
    end;
  if (Count < 2) or ((AMode >= 4) and (Count < 3)) then
    Exit;
  case AMode of
    0, 1, 2, 3:
      begin
        Target := 0;
        for ItemIdx := 0 to Count - 1 do
        begin
          Box := Boxes[ItemIdx];
          if (ItemIdx = 0) or ((AMode = 0) and (Box.Left < Target)) or
             ((AMode = 1) and (Box.Right > Target)) or
             ((AMode = 2) and (Box.Top < Target)) or
             ((AMode = 3) and (Box.Bottom > Target)) then
            case AMode of
              0: Target := Box.Left;
              1: Target := Box.Right;
              2: Target := Box.Top;
              3: Target := Box.Bottom;
            end;
        end;
        for ItemIdx := 0 to Count - 1 do
        begin
          Box := Boxes[ItemIdx];
          case AMode of
            0: CtlMoveTo(Items[ItemIdx], Items[ItemIdx].Left + Target - Box.Left, Items[ItemIdx].Top);
            1: CtlMoveTo(Items[ItemIdx], Items[ItemIdx].Left + Target - Box.Right, Items[ItemIdx].Top);
            2: CtlMoveTo(Items[ItemIdx], Items[ItemIdx].Left, Items[ItemIdx].Top + Target - Box.Top);
            3: CtlMoveTo(Items[ItemIdx], Items[ItemIdx].Left, Items[ItemIdx].Top + Target - Box.Bottom);
          end;
        end;
      end;
    4, 5:
      begin
        // Крайние на месте, между надписями - равные промежутки
        Vertical := AMode = 4;
        SetLength(Order, Count);
        for ItemIdx := 0 to Count - 1 do
          Order[ItemIdx] := ItemIdx;
        for ItemIdx := 0 to Count - 2 do
          for OtherIdx := ItemIdx + 1 to Count - 1 do
            if (Vertical and (Boxes[Order[OtherIdx]].Top < Boxes[Order[ItemIdx]].Top)) or
               (not Vertical and (Boxes[Order[OtherIdx]].Left < Boxes[Order[ItemIdx]].Left)) then
            begin
              Swap := Order[ItemIdx];
              Order[ItemIdx] := Order[OtherIdx];
              Order[OtherIdx] := Swap;
            end;
        SizeSum := 0;
        for ItemIdx := 0 to Count - 1 do
          if Vertical then
            Inc(SizeSum, Boxes[ItemIdx].Bottom - Boxes[ItemIdx].Top)
          else
            Inc(SizeSum, Boxes[ItemIdx].Right - Boxes[ItemIdx].Left);
        if Vertical then
          Span := Boxes[Order[Count - 1]].Bottom - Boxes[Order[0]].Top
        else
          Span := Boxes[Order[Count - 1]].Right - Boxes[Order[0]].Left;
        FreeSpace := Span - SizeSum;
        SizeBefore := 0;
        for ItemIdx := 0 to Count - 1 do
        begin
          OtherIdx := Order[ItemIdx];
          Box := Boxes[OtherIdx];
          if Vertical then
          begin
            Size := Box.Bottom - Box.Top;
            NewPos := Boxes[Order[0]].Top + SizeBefore + (FreeSpace * ItemIdx) div (Count - 1);
            CtlMoveTo(Items[OtherIdx], Items[OtherIdx].Left,
                      Items[OtherIdx].Top + NewPos - Box.Top);
          end
          else
          begin
            Size := Box.Right - Box.Left;
            NewPos := Boxes[Order[0]].Left + SizeBefore + (FreeSpace * ItemIdx) div (Count - 1);
            CtlMoveTo(Items[OtherIdx], Items[OtherIdx].Left + NewPos - Box.Left,
                      Items[OtherIdx].Top);
          end;
          Inc(SizeBefore, Size);
        end;
      end;
  end;
  for ItemIdx := 0 to Count - 1 do
    if (Items[ItemIdx].NewLeft <> Items[ItemIdx].Left) or
       (Items[ItemIdx].NewTop <> Items[ItemIdx].Top) then
    begin
      Inc(Result);
      if Assigned(FOnCtlMoved) then
        FOnCtlMoved(Self, Items[ItemIdx].Hash, Items[ItemIdx].NewLeft, Items[ItemIdx].NewTop);
    end;
  FDevice.InvalidateScreen;
end;

// Пунктир жёлтый/чёрный на точку снаружи рамки надписи и квадратики по
// углам. В FPixels: до следующей перерисовки экрана
procedure TArdSimPanel.DrawCtlMarker;
var
  Box: TRect;
  PosX, PosY, Step, CornerX, CornerY, SelIdx: Integer;
  CornerColor: Cardinal;
  PosLeft, PosTop: Integer;
  IsPhantom: Boolean;

  procedure PutPixel(APosX, APosY: Integer);
  begin
    if (APosX >= 0) and (APosX < ArdSimScreenW) and (APosY >= 0) and
       (APosY < ArdSimScreenH) then
    begin
      if ((Step div 3) mod 2) = 0 then
        FPixels[APosY * ArdSimScreenW + APosX] := $FFFF00
      else
        FPixels[APosY * ArdSimScreenW + APosX] := $000000;
      Inc(Step);
    end;
  end;

  procedure PutCorner(ACenterX, ACenterY: Integer);
  var
    DeltaX, DeltaY: Integer;
  begin
    for DeltaY := -2 to 2 do
      for DeltaX := -2 to 2 do
        if (ACenterX + DeltaX >= 0) and (ACenterX + DeltaX < ArdSimScreenW) and
           (ACenterY + DeltaY >= 0) and (ACenterY + DeltaY < ArdSimScreenH) then
        begin
          if (Abs(DeltaX) = 2) or (Abs(DeltaY) = 2) then
            FPixels[(ACenterY + DeltaY) * ArdSimScreenW + ACenterX + DeltaX] := $000000
          else
            FPixels[(ACenterY + DeltaY) * ArdSimScreenW + ACenterX + DeltaX] := CornerColor;
        end;
  end;

begin
  if Length(FPixels) < ArdSimScreenW * ArdSimScreenH then
    Exit;
  // Главная - жёлтые углы, добавленные Ctrl+щелчком - серые
  for SelIdx := SelectedCount - 1 downto 0 do
  begin
  if not CtlPlace(SelectedHash(SelIdx), PosLeft, PosTop, Box, IsPhantom) then
    Continue;
  if SelIdx = 0 then
    CornerColor := $FFFF00
  else
    CornerColor := $A0A0A0;
  // снаружи занятых точек
  Box := Rect(Box.Left - 1, Box.Top - 1, Box.Right, Box.Bottom);
  Step := 0;
  for PosX := Box.Left to Box.Right do
    PutPixel(PosX, Box.Top);
  for PosY := Box.Top + 1 to Box.Bottom do
    PutPixel(Box.Right, PosY);
  for PosX := Box.Right - 1 downto Box.Left do
    PutPixel(PosX, Box.Bottom);
  for PosY := Box.Bottom - 1 downto Box.Top + 1 do
    PutPixel(Box.Left, PosY);
  for CornerY := 0 to 1 do
    for CornerX := 0 to 1 do
      PutCorner(Box.Left + CornerX * (Box.Right - Box.Left),
                Box.Top + CornerY * (Box.Bottom - Box.Top));
  end;
end;

// Нажатие на экране: надпись TLabel под мышью - выбрана (рамка сразу, не
// дожидаясь инспектора) и тащится, пока кнопка нажата
function TArdSimPanel.CtlMouseDown(AX, AY: Integer; AToggle: Boolean): Boolean;
var
  Hash: Cardinal;
  SelIdx, Count: Integer;
  Box: TRect;
begin
  Result := False;
  FDragging := False;
  Hash := CtlHashAt(AX, AY);
  FWhereCtlHash := Hash;
  if Hash = 0 then
  begin
    if not AToggle and (Length(FSelExtra) > 0) then
    begin
      SetLength(FSelExtra, 0);
      FDevice.InvalidateScreen;
    end;
    Exit;
  end;
  // Ctrl+щелчок: добавить к выбранным или убрать, без перетаскивания
  if AToggle then
  begin
    CtlSelToggle(Hash);
    FDevice.InvalidateScreen;
    Result := CtlSelected(Hash);
    Exit;
  end;
  if CtlSelected(Hash) then
    CtlMakePrimary(Hash)
  else
  begin
    SetLength(FSelExtra, 0);
    FSelCtlHash := Hash;
  end;
  SetLength(FDragItems, SelectedCount);
  Count := 0;
  for SelIdx := 0 to SelectedCount - 1 do
    if CtlPlace(SelectedHash(SelIdx), FDragItems[Count].Left, FDragItems[Count].Top,
                Box, FDragItems[Count].IsPhantom) then
    begin
      FDragItems[Count].Hash := SelectedHash(SelIdx);
      FDragItems[Count].NewLeft := FDragItems[Count].Left;
      FDragItems[Count].NewTop := FDragItems[Count].Top;
      Inc(Count);
    end
    else if SelIdx = 0 then
      Break;
  SetLength(FDragItems, Count);
  FDevice.InvalidateScreen;
  if (Count = 0) or (FDragItems[0].Hash <> Hash) then
    Exit;
  FDragging := True;
  FDragMoved := False;
  FDragFromX := AX;
  FDragFromY := AY;
  Result := True;
end;

// Правый клик на экране: TLabel под мышью выделяется (без перетаскивания),
// курсор переводится на строку отрисовки и вызывается OnCtlMenu
procedure TArdSimPanel.CtlContextMenu(AX, AY: Integer; const AScreenPos: TPoint);
var
  Hash: Cardinal;
  NearBox: TRect;
  WhereX, WhereY: Integer;
begin
  FDragging := False;
  Hash := CtlHashAt(AX, AY);
  FWhereCtlHash := Hash;
  if (Hash <> 0) and (CtlShownEntry(Hash) <> nil) then
  begin
    // на одной из выбранных - выбор остаётся (выравнивание в меню)
    if CtlSelected(Hash) then
      CtlMakePrimary(Hash)
    else
    begin
      SetLength(FSelExtra, 0);
      FSelCtlHash := Hash;
    end;
    FDevice.InvalidateScreen;
  end;
  FMenuHash := Hash;
  FMenuPos := AScreenPos;
  FMenuX := AX;
  FMenuY := AY;
  FMenuNear := 0;
  FMenuPending := False;
  WhereX := AX;
  WhereY := AY;
  // Мимо надписей: курсор - на вывод ближайшей надписи этого экрана, туда
  // Paste добавит вывод копии
  if Hash = 0 then
  begin
    FMenuNear := CtlNearestHash(AX, AY, NearBox);
    if FMenuNear <> 0 then
    begin
      FWhereCtlHash := FMenuNear;
      WhereX := (NearBox.Left + NearBox.Right) div 2;
      WhereY := (NearBox.Top + NearBox.Bottom) div 2;
    end;
  end;
  if (FWhereCtlHash <> 0) and (PhantomByHash(FWhereCtlHash) = nil) then
  begin
    FWhereWait := False;
    ScreenWhere(WhereX, WhereY);
    // ответ придёт в PollWhere: меню - после перехода к строке
    FMenuPending := FWhereWait;
  end;
  if not FMenuPending then
    FireCtlMenu;
end;

procedure TArdSimPanel.FireCtlMenu;
begin
  FMenuPending := False;
  if FMenuPlace then
  begin
    FMenuPlace := False;
    if Assigned(FOnPlace) then
      FOnPlace(Self, FMenuX, FMenuY);
  end
  else if Assigned(FOnCtlMenu) then
    FOnCtlMenu(Self, FMenuHash, FMenuPos);
end;

// Щелчок по экрану в режиме палитры: ближайшая показанная надпись (под
// мышью - она же) - по ней Unit1 выбирает файл форм и функцию вывода
procedure TArdSimPanel.PlaceClick(AX, AY: Integer);
var
  NearBox: TRect;
begin
  FDragging := False;
  FMenuHash := 0;
  FMenuX := AX;
  FMenuY := AY;
  FMenuPlace := True;
  FMenuPending := False;
  FMenuNear := CtlNearestHash(AX, AY, NearBox);
  FWhereCtlHash := FMenuNear;
  if FMenuNear <> 0 then
  begin
    FWhereWait := False;
    ScreenWhere((NearBox.Left + NearBox.Right) div 2, (NearBox.Top + NearBox.Bottom) div 2);
    FMenuPending := FWhereWait;
  end;
  if not FMenuPending then
    FireCtlMenu;
end;

// Новые Left, Top - сразу в эмулятор: он перерисовывает надпись. Все
// выбранные - на тот же сдвиг; по сетке - Left, Top надписи под мышью
procedure TArdSimPanel.CtlMouseMove(AX, AY: Integer);
var
  DeltaX, DeltaY, ItemIdx, MinLeft, MinTop, MaxLeft, MaxTop: Integer;
begin
  if not FDragging or (Length(FDragItems) = 0) then
    Exit;
  // дрожание руки при щелчке - не перенос
  if not FDragMoved and (Abs(AX - FDragFromX) < 3) and (Abs(AY - FDragFromY) < 3) then
    Exit;
  DeltaX := SnapGrid(FDragItems[0].Left + AX - FDragFromX) - FDragItems[0].Left;
  DeltaY := SnapGrid(FDragItems[0].Top + AY - FDragFromY) - FDragItems[0].Top;
  MinLeft := MaxInt;
  MinTop := MaxInt;
  MaxLeft := -MaxInt;
  MaxTop := -MaxInt;
  for ItemIdx := 0 to High(FDragItems) do
  begin
    if FDragItems[ItemIdx].Left < MinLeft then
      MinLeft := FDragItems[ItemIdx].Left;
    if FDragItems[ItemIdx].Top < MinTop then
      MinTop := FDragItems[ItemIdx].Top;
    if FDragItems[ItemIdx].Left > MaxLeft then
      MaxLeft := FDragItems[ItemIdx].Left;
    if FDragItems[ItemIdx].Top > MaxTop then
      MaxTop := FDragItems[ItemIdx].Top;
  end;
  // группа целиком в пределах экрана
  if MinLeft + DeltaX < 0 then
    DeltaX := -MinLeft;
  if MinTop + DeltaY < 0 then
    DeltaY := -MinTop;
  if MaxLeft + DeltaX > ArdSimScreenW - 1 then
    DeltaX := ArdSimScreenW - 1 - MaxLeft;
  if MaxTop + DeltaY > ArdSimScreenH - 1 then
    DeltaY := ArdSimScreenH - 1 - MaxTop;
  if (FDragItems[0].Left + DeltaX = FDragItems[0].NewLeft) and
     (FDragItems[0].Top + DeltaY = FDragItems[0].NewTop) then
    Exit;
  FDragMoved := True;
  for ItemIdx := 0 to High(FDragItems) do
    CtlMoveTo(FDragItems[ItemIdx], FDragItems[ItemIdx].Left + DeltaX,
              FDragItems[ItemIdx].Top + DeltaY);
end;

procedure TArdSimPanel.CtlMouseUp;
var
  ItemIdx: Integer;
begin
  if not FDragging then
    Exit;
  FDragging := False;
  if FDragMoved and Assigned(FOnCtlMoved) then
    for ItemIdx := 0 to High(FDragItems) do
      if (FDragItems[ItemIdx].NewLeft <> FDragItems[ItemIdx].Left) or
         (FDragItems[ItemIdx].NewTop <> FDragItems[ItemIdx].Top) then
        FOnCtlMoved(Self, FDragItems[ItemIdx].Hash, FDragItems[ItemIdx].NewLeft,
                    FDragItems[ItemIdx].NewTop);
  SetLength(FDragItems, 0);
end;

function TArdSimPanel.SetArgOverride(AFileIdx, ALine: Integer;
  const AName: string; AOccurrence, AArgIdx: Integer; ANumber: Integer;
  const AFont: string): Boolean;
{$IFDEF MSWINDOWS}
var
  Table, Fields: PCardinal;
  Count, EntryIdx, Found, CharIdx: Integer;
  Code, Hash: Cardinal;
  FontText: PAnsiChar;

  function Field(AEntry, AIndex: Integer): PCardinal;
  begin
    Result := PCardinal(PAnsiChar(Table) + 16 + AEntry * ArgEntryBytes +
                        AIndex * 4);
  end;
{$ENDIF}
begin
  Result := False;
  {$IFDEF MSWINDOWS}
  if not ArgOverrideAvailable or (AFileIdx < 0) or (ALine <= 0) then
    Exit;
  Table := PCardinal(PAnsiChar(FView) + ArgOffset);
  Code := (Cardinal(AFileIdx) shl 20) or Cardinal(ALine);
  Hash := ArgNameHash(AName);
  Count := Table^;
  if Count > ArgMaxEntries then
    Count := ArgMaxEntries;
  Found := -1;
  for EntryIdx := 0 to Count - 1 do
    if (Field(EntryIdx, 0)^ = Code) and (Field(EntryIdx, 1)^ = Hash) and
       (Field(EntryIdx, 2)^ = Cardinal(AOccurrence)) and
       (Field(EntryIdx, 3)^ = Cardinal(AArgIdx)) then
    begin
      Found := EntryIdx;
      Break;
    end;
  if Found < 0 then
  begin
    if Count >= ArgMaxEntries then
      Exit;
    Found := Count;
  end;
  // Вид - последним: эмулятор читает запись без блокировки
  Field(Found, 4)^ := 0;
  Field(Found, 0)^ := Code;
  Field(Found, 1)^ := Hash;
  Field(Found, 2)^ := Cardinal(AOccurrence);
  Field(Found, 3)^ := Cardinal(AArgIdx);
  Field(Found, 5)^ := Cardinal(ANumber);
  FontText := PAnsiChar(Field(Found, 6));
  FillChar(FontText^, ArgFontChars, 0);
  for CharIdx := 1 to Length(AFont) do
    if CharIdx < ArgFontChars then
      FontText[CharIdx - 1] := AnsiChar(AFont[CharIdx]);
  Fields := Field(Found, 4);
  if AFont <> '' then
    Fields^ := 2
  else
    Fields^ := 1;
  if Found >= Count then
    Table^ := Found + 1;
  Result := True;
  {$ENDIF}
end;

// Превью в FPixels (копия экрана для показа): прежняя надпись стирается
// цветом фона, новая рисуется по точкам, как UTFT::printChar в
// ArdSim\src\sim_utft.cpp (символ вне шрифта - пустая клетка)
procedure TArdSimPanel.DrawPreview;
var
  KeptIdx: Integer;
  Item: TArdPreviewItem;

  procedure PutPixel(APosX, APosY: Integer; AColor: Cardinal);
  begin
    if (APosX >= 0) and (APosX < ArdSimScreenW) and (APosY >= 0) and
       (APosY < ArdSimScreenH) then
      FPixels[APosY * ArdSimScreenW + APosX] := AColor;
  end;

  // Скетч перерисовал место надписи (другое окно, clrScr, новая надпись) -
  // превью больше не к месту. FPixels здесь - ещё картинка эмулятора
  function StillValid(AItem: TArdPreviewItem): Boolean;
  var
    AreaSum: Cardinal;
    PosX, PosY: Integer;
  begin
    AreaSum := 0;
    for PosY := AItem.Area.Top to AItem.Area.Bottom - 1 do
      for PosX := AItem.Area.Left to AItem.Area.Right - 1 do
        if (PosX >= 0) and (PosX < ArdSimScreenW) and (PosY >= 0) and
           (PosY < ArdSimScreenH) then
          AreaSum := ((AreaSum shl 5) or (AreaSum shr 27)) xor
                     FPixels[PosY * ArdSimScreenW + PosX];
    if not AItem.SumSet then
    begin
      AItem.Sum := AreaSum;
      AItem.SumSet := True;
    end;
    Result := AreaSum = AItem.Sum;
  end;

  procedure DrawItem(AItem: TArdPreviewItem);
  var
    CharIdx, Code, Offset, RowIdx, PartIdx, BitIdx, PosX, PosY: Integer;
    BytesPerRow, CellX, PropX, InkW, InkLeft, TextW: Integer;
    Bits: Byte;
    Font: TUtftFont;
  begin
    Font := AItem.Font;
    for PosY := AItem.Clear.Top to AItem.Clear.Bottom - 1 do
      for PosX := AItem.Clear.Left to AItem.Clear.Right - 1 do
        PutPixel(PosX, PosY, AItem.Back);
    BytesPerRow := Font.SizeX div 8;
    PropX := AItem.PosX;
    if AItem.Proportional and not AItem.Transparent then
    begin
      // PrintProp: фон под всей строкой, знаки - только точками
      TextW := PreviewTextWidth(Font, AItem.Text, True);
      for PosY := AItem.PosY to AItem.PosY + Font.SizeY - 1 do
        for PosX := AItem.PosX to AItem.PosX + TextW - 1 do
          PutPixel(PosX, PosY, AItem.Back);
    end;
    for CharIdx := 1 to Length(AItem.Text) do
    begin
      Code := Ord(AItem.Text[CharIdx]);
      CellX := AItem.PosX + (CharIdx - 1) * Font.SizeX;
      if AItem.Proportional then
      begin
        InkW := UtftPropGlyph(Font, Code, InkLeft);
        if InkW <= 0 then
        begin
          Inc(PropX, UtftPropSpace(Font));
          Continue;
        end;
        CellX := PropX - InkLeft;
        Inc(PropX, InkW + UtftPropGap);
      end;
      Offset := Font.GlyphOffset(Code);
      for RowIdx := 0 to Font.SizeY - 1 do
        for PartIdx := 0 to BytesPerRow - 1 do
        begin
          if (Offset >= 0) and
             (Offset + RowIdx * BytesPerRow + PartIdx < Length(Font.Data)) then
            Bits := Font.Data[Offset + RowIdx * BytesPerRow + PartIdx]
          else
            Bits := 0;
          for BitIdx := 0 to 7 do
            if (Bits and ($80 shr BitIdx)) <> 0 then
              PutPixel(CellX + PartIdx * 8 + BitIdx, AItem.PosY + RowIdx,
                       AItem.Fore)
            else if not AItem.Transparent and not AItem.Proportional then
              PutPixel(CellX + PartIdx * 8 + BitIdx, AItem.PosY + RowIdx,
                       AItem.Back);
        end;
    end;
  end;

begin
  if Length(FPixels) < ArdSimScreenW * ArdSimScreenH then
    Exit;
  // Сначала все проверки по картинке эмулятора, потом рисование
  if FKept <> nil then
    for KeptIdx := FKept.Count - 1 downto 0 do
      if not StillValid(TArdPreviewItem(FKept[KeptIdx])) then
      begin
        TObject(FKept[KeptIdx]).Free;
        FKept.Delete(KeptIdx);
      end;
  if (FPreview <> nil) and not StillValid(TArdPreviewItem(FPreview)) then
    FreeAndNil(FPreview);
  if FKept <> nil then
    for KeptIdx := 0 to FKept.Count - 1 do
      DrawItem(TArdPreviewItem(FKept[KeptIdx]));
  Item := TArdPreviewItem(FPreview);
  if Item <> nil then
    DrawItem(Item);
end;

// ---------------------------------------------------------------------------
//  Надписи-фантомы: TLabel, добавленные после сборки
// ---------------------------------------------------------------------------

function TArdSimPanel.PhantomCount: Integer;
begin
  if FPhantoms = nil then
    Result := 0
  else
    Result := FPhantoms.Count;
end;

function TArdSimPanel.PhantomByHash(AHash: Cardinal): TArdSimPhantom;
var
  PhIdx: Integer;
begin
  Result := nil;
  if (FPhantoms = nil) or (AHash = 0) then
    Exit;
  for PhIdx := 0 to FPhantoms.Count - 1 do
    if TArdSimPhantom(FPhantoms[PhIdx]).Hash = AHash then
    begin
      Result := TArdSimPhantom(FPhantoms[PhIdx]);
      Exit;
    end;
end;

procedure TArdSimPanel.SetPhantom(APhantom: TArdSimPhantom);
var
  PhIdx: Integer;
  Old: TArdSimPhantom;
begin
  if APhantom = nil then
    Exit;
  if FPhantoms = nil then
    FPhantoms := TList.Create;
  APhantom.Hash := ArgNameHash(APhantom.Name);
  for PhIdx := 0 to FPhantoms.Count - 1 do
  begin
    Old := TArdSimPhantom(FPhantoms[PhIdx]);
    if Old.Hash = APhantom.Hash then
    begin
      // перетаскивание этой надписи идёт - место из мыши не теряем
      if CtlDragHas(Old.Hash) then
      begin
        APhantom.Left := Old.Left;
        APhantom.Top := Old.Top;
      end;
      APhantom.Box := Old.Box;
      APhantom.Shown := Old.Shown;
      Old.Free;
      FPhantoms[PhIdx] := APhantom;
      FDevice.InvalidateScreen;
      Exit;
    end;
  end;
  FPhantoms.Add(APhantom);
  FDevice.InvalidateScreen;
end;

procedure TArdSimPanel.RemovePhantom(const AName: string);
var
  PhIdx: Integer;
  Hash: Cardinal;
begin
  if FPhantoms = nil then
    Exit;
  Hash := ArgNameHash(AName);
  for PhIdx := FPhantoms.Count - 1 downto 0 do
    if TArdSimPhantom(FPhantoms[PhIdx]).Hash = Hash then
    begin
      if CtlDragHas(Hash) then
        FDragging := False;
      TObject(FPhantoms[PhIdx]).Free;
      FPhantoms.Delete(PhIdx);
    end;
  FDevice.InvalidateScreen;
end;

procedure TArdSimPanel.ClearPhantoms;
var
  PhIdx: Integer;
begin
  if FPhantoms = nil then
    Exit;
  for PhIdx := 0 to FPhantoms.Count - 1 do
    TObject(FPhantoms[PhIdx]).Free;
  FPhantoms.Clear;
  if FDevice <> nil then
    FDevice.InvalidateScreen;
end;

function TArdSimPanel.ScreenVersion: Cardinal;
begin
  Result := FScreenVersion;
end;

function TArdSimPanel.SaveScreenBmp(const AFileName: string): Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := (FView <> nil) and (FScreenVersion > 0) and
    SaveRgb565Bmp(AFileName, PWord(PAnsiChar(FView) + HeaderBytes),
                  ArdSimScreenW, ArdSimScreenH);
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function TArdSimPanel.SimExeFile: string;
begin
  Result := ExeOfSketch;
end;

// Фантомы - как Label() в BS10.ino: прямоугольник (Rect, Filled, Rounded),
// рамка LineWidth, текст на Top + 4 с отступом 3 или по Alignment. Видны,
// пока на экране надпись AnchorHash (тот же экран, что у неё в скетче).
// Visible 0 - серым, как у эмулятора
procedure TArdSimPanel.DrawPhantoms;
var
  PhIdx: Integer;
  Phantom, AnchorPh: TArdSimPhantom;

  function Grey(AColor: Cardinal): Cardinal;
  var
    Level: Cardinal;
  begin
    Level := (((AColor shr 16) and $FF) * 299 + ((AColor shr 8) and $FF) * 587 +
              (AColor and $FF) * 114) div 1000;
    Result := (Level shl 16) or (Level shl 8) or Level;
  end;

  procedure PutPixel(APosX, APosY: Integer; AColor: Cardinal);
  begin
    if (APosX >= 0) and (APosX < ArdSimScreenW) and (APosY >= 0) and
       (APosY < ArdSimScreenH) then
      FPixels[APosY * ArdSimScreenW + APosX] := AColor;
  end;

  procedure HLine(AX1, AX2, APosY: Integer; AColor: Cardinal);
  var
    PosX: Integer;
  begin
    for PosX := AX1 to AX2 do
      PutPixel(PosX, APosY, AColor);
  end;

  procedure VLine(APosX, AY1, AY2: Integer; AColor: Cardinal);
  var
    PosY: Integer;
  begin
    for PosY := AY1 to AY2 do
      PutPixel(APosX, PosY, AColor);
  end;

  // UTFT drawRect / drawRoundRect (углы срезаны на точку)
  procedure Frame(AX1, AY1, AX2, AY2: Integer; ARounded: Boolean; AColor: Cardinal);
  begin
    if ARounded and (AX2 - AX1 > 4) and (AY2 - AY1 > 4) then
    begin
      PutPixel(AX1 + 1, AY1 + 1, AColor);
      PutPixel(AX2 - 1, AY1 + 1, AColor);
      PutPixel(AX1 + 1, AY2 - 1, AColor);
      PutPixel(AX2 - 1, AY2 - 1, AColor);
      HLine(AX1 + 2, AX2 - 2, AY1, AColor);
      HLine(AX1 + 2, AX2 - 2, AY2, AColor);
      VLine(AX1, AY1 + 2, AY2 - 2, AColor);
      VLine(AX2, AY1 + 2, AY2 - 2, AColor);
    end
    else
    begin
      HLine(AX1, AX2, AY1, AColor);
      HLine(AX1, AX2, AY2, AColor);
      VLine(AX1, AY1, AY2, AColor);
      VLine(AX2, AY1, AY2, AColor);
    end;
  end;

  // UTFT fillRect / fillRoundRect
  procedure Fill(AX1, AY1, AX2, AY2: Integer; ARounded: Boolean; AColor: Cardinal);
  var
    PosY, Inset: Integer;
  begin
    for PosY := AY1 to AY2 do
    begin
      Inset := 0;
      if ARounded and (AX2 - AX1 > 4) and (AY2 - AY1 > 4) then
      begin
        if (PosY = AY1) or (PosY = AY2) then
          Inset := 2
        else if (PosY = AY1 + 1) or (PosY = AY2 - 1) then
          Inset := 1;
      end;
      HLine(AX1 + Inset, AX2 - Inset, PosY, AColor);
    end;
  end;

  procedure DrawText(AFont: TUtftFont; const AText: AnsiString; APosX, APosY: Integer;
    AFore, ABack: Cardinal; AProportional: Boolean);
  var
    CharIdx, Code, Offset, RowIdx, PartIdx, BitIdx, BytesPerRow: Integer;
    CellX, PropX, InkW, InkLeft: Integer;
    Bits: Byte;
  begin
    BytesPerRow := AFont.SizeX div 8;
    PropX := APosX;
    for CharIdx := 1 to Length(AText) do
    begin
      Code := Ord(AText[CharIdx]);
      CellX := APosX + (CharIdx - 1) * AFont.SizeX;
      if AProportional then
      begin
        InkW := UtftPropGlyph(AFont, Code, InkLeft);
        if InkW <= 0 then
        begin
          Inc(PropX, UtftPropSpace(AFont));
          Continue;
        end;
        CellX := PropX - InkLeft;
        Inc(PropX, InkW + UtftPropGap);
      end;
      Offset := AFont.GlyphOffset(Code);
      for RowIdx := 0 to AFont.SizeY - 1 do
        for PartIdx := 0 to BytesPerRow - 1 do
        begin
          if (Offset >= 0) and
             (Offset + RowIdx * BytesPerRow + PartIdx < Length(AFont.Data)) then
            Bits := AFont.Data[Offset + RowIdx * BytesPerRow + PartIdx]
          else
            Bits := 0;
          for BitIdx := 0 to 7 do
            if (Bits and ($80 shr BitIdx)) <> 0 then
              PutPixel(CellX + PartIdx * 8 + BitIdx, APosY + RowIdx, AFore)
            else if not AProportional then
              PutPixel(CellX + PartIdx * 8 + BitIdx, APosY + RowIdx, ABack);
        end;
    end;
  end;

  procedure DrawOne(APh: TArdSimPhantom);
  var
    BoxW, TextW, TextX, NeedW, FillW, LineIdx, FontH: Integer;
    Back, Fore, Border: Cardinal;
    Rounded, Solid: Boolean;
  begin
    Back := APh.Color;
    Fore := APh.FontColor;
    Border := APh.BorderColor;
    if APh.Visible = 0 then
    begin
      Back := Grey(Back);
      Fore := Grey(Fore);
      Border := Grey(Border);
    end;
    Rounded := APh.Rounded = 1;
    Solid := (APh.RectOn > 0) and (APh.Filled = 1);
    TextW := 0;
    FontH := 0;
    if APh.Font <> nil then
    begin
      TextW := PreviewTextWidth(APh.Font, APh.Caption, APh.Proportional <> 0);
      FontH := APh.Font.SizeY;
    end;
    NeedW := TextW + 6;
    BoxW := APh.Width;
    if BoxW < NeedW then
      BoxW := NeedW;
    if APh.RectOn > 0 then
    begin
      if APh.Filled = 1 then
        Fill(APh.Left, APh.Top, APh.Left + BoxW, APh.Top + APh.Height, Rounded, Back)
      else
        Frame(APh.Left, APh.Top, APh.Left + BoxW, APh.Top + APh.Height, Rounded, Back);
    end;
    for LineIdx := 1 to APh.LineWidth do
      Frame(APh.Left - LineIdx, APh.Top - LineIdx, APh.Left + BoxW + LineIdx,
            APh.Top + APh.Height + LineIdx, Rounded, Border);
    if APh.Alignment = 1 then
      TextX := APh.Left + BoxW - 3 - TextW
    else if APh.Alignment = 2 then
      TextX := APh.Left + (BoxW - TextW) div 2
    else
      TextX := APh.Left + 3;
    if (APh.Font <> nil) and (APh.Alignment <> 0) and not Solid then
      Fill(APh.Left + 3, APh.Top + 4, APh.Left + BoxW - 3, APh.Top + 4 + FontH - 1,
           False, Back);
    if APh.Font <> nil then
    begin
      if APh.Proportional <> 0 then
      begin
        FillW := 0;
        if not Solid and (APh.Alignment = 0) then
        begin
          FillW := APh.Font.SizeX * Length(APh.Caption);
          if FillW > BoxW - 4 then
            FillW := BoxW - 4;
        end;
        if FillW < TextW then
          FillW := TextW;
        if FillW > 0 then
          Fill(TextX, APh.Top + 4, TextX + FillW - 1, APh.Top + 4 + FontH - 1, False, Back);
      end;
      DrawText(APh.Font, APh.Caption, TextX, APh.Top + 4, Fore, Back,
               APh.Proportional <> 0);
    end;
    // занятые точки: прямоугольник с рамкой и текст
    if (APh.RectOn > 0) or (APh.LineWidth > 0) then
      APh.Box := Rect(APh.Left - APh.LineWidth, APh.Top - APh.LineWidth,
                      APh.Left + BoxW + APh.LineWidth + 1,
                      APh.Top + APh.Height + APh.LineWidth + 1)
    else
      APh.Box := Rect(TextX, APh.Top + 4, TextX + TextW, APh.Top + 4 + FontH);
    if TextX < APh.Box.Left then
      APh.Box.Left := TextX;
    if TextX + TextW > APh.Box.Right then
      APh.Box.Right := TextX + TextW;
    if APh.Box.Right <= APh.Box.Left then
      APh.Box.Right := APh.Box.Left + 4;
    if APh.Box.Bottom <= APh.Box.Top then
      APh.Box.Bottom := APh.Box.Top + 4;
  end;

begin
  if Length(FPixels) < ArdSimScreenW * ArdSimScreenH then
    Exit;
  for PhIdx := 0 to FPhantoms.Count - 1 do
  begin
    Phantom := TArdSimPhantom(FPhantoms[PhIdx]);
    // Тот же экран, что у надписи-соседа: она показана эмулятором или
    // сама фантом, нарисованный выше по списку
    Phantom.Shown := Phantom.AnchorHash = 0;
    if not Phantom.Shown then
    begin
      Phantom.Shown := CtlShownEntry(Phantom.AnchorHash) <> nil;
      if not Phantom.Shown then
      begin
        AnchorPh := PhantomByHash(Phantom.AnchorHash);
        Phantom.Shown := (AnchorPh <> nil) and (AnchorPh <> Phantom) and AnchorPh.Shown;
      end;
    end;
    if Phantom.Shown then
      DrawOne(Phantom);
  end;
end;

// ---------------------------------------------------------------------------
//  TArdSimWindow
// ---------------------------------------------------------------------------

const
  WindowClientW = ArdSimScreenW + 2 * BodyBorder + 2 * 4;

constructor TArdSimWindow.CreateFor(AMainForm: TCustomForm);
begin
  FMainForm := AMainForm;
  inherited CreateNew(AMainForm);
  Caption := 'Emulator - ArdSim';
  BorderStyle := bsSizeToolWin;
  Position := poDesigned;
  ClientWidth := WindowClientW;
  ClientHeight := 760;
  Constraints.MinWidth := Width - ClientWidth + WindowClientW;
  OnClose := WindowClose;
  FPanel := TArdSimPanel.Create(Self);
  FPanel.Parent := Self;
  FPanel.Align := alClient;
end;

// Владелец окна - главное окно unIDE: эмулятор всегда над ним, но не над
// другими программами
procedure TArdSimWindow.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if (FMainForm <> nil) and FMainForm.HandleAllocated then
    Params.WndParent := FMainForm.Handle;
end;

procedure TArdSimWindow.WindowClose(Sender: TObject; var Action: TCloseAction);
begin
  FPanel.StopAll;
  Action := caHide;
  if Assigned(FOnHidden) then
    FOnHidden(Self);
end;

procedure TArdSimWindow.WMExitSizeMove(var Message: TMessage);
begin
  inherited;
  if Assigned(FOnPlaced) then
    FOnPlaced(Self);
end;

{$IFDEF FPC}
procedure TArdSimWindow.WMMove(var Message: TMessage);
begin
  inherited;
  PlaceNoted;
end;

procedure TArdSimWindow.WMSize(var Message: TMessage);
begin
  inherited;
  PlaceNoted;
end;

procedure TArdSimWindow.PlaceNoted;
begin
  if not Visible or not FPlaced or (csDestroying in ComponentState) then
    Exit;
  if FPlaceTimer = nil then
  begin
    FPlaceTimer := TTimer.Create(Self);
    FPlaceTimer.Interval := 250;
    FPlaceTimer.OnTimer := PlaceTimerTick;
  end;
  FPlaceTimer.Enabled := False;
  FPlaceTimer.Enabled := True;
end;

procedure TArdSimWindow.PlaceTimerTick(Sender: TObject);
begin
  // Кнопка ещё нажата - окно тянут дальше
  if GetAsyncKeyState(VK_LBUTTON) < 0 then
    Exit;
  FPlaceTimer.Enabled := False;
  if Visible and Assigned(FOnPlaced) then
    FOnPlaced(Self);
end;
{$ENDIF}

procedure TArdSimWindow.ShowAtRight;
var
  FrameW: Integer;
begin
  if not FPlaced and (FMainForm <> nil) then
  begin
    FPlaced := True;
    FrameW := Width - ClientWidth;
    Width := WindowClientW + FrameW;
    Height := FMainForm.Height;
    Left := FMainForm.Left + FMainForm.Width - Width;
    Top := FMainForm.Top;
  end;
  Show;
  BringToFront;
  if Assigned(FOnPlaced) then
    FOnPlaced(Self);
end;

end.
