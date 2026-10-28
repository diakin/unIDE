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
//      последние папки дисков - в editor.ini ([Far], [FarHistory]);
//    - b.7: F4 - файл под курсором в редактор unIDE: окно FAR остаётся с
//      одной (активной) панелью, редактор - во второй половине (это
//      делает Unit1 по OnEditFile, панель - SetSingle); Shift+F4 - имя
//      файла в диалоге, нет файла - создаётся пустой; Tab в FAR с одной
//      панелью - в редактор (OnLeave); ShowFile - курсор на файл вкладки;
//    - b.8: узкое окно (меньше 8 клеток на клавишу) - кейбар в две строки:
//      F1..F6 и F7..F12; HalfWidth - ширина окна FAR в режиме F4 (её
//      меняет сплиттер в Unit1), хранится в editor.ini;
//    - b.15: раскраска файлов по расширению (цвет текста и фона, любые
//      цвета; правила - editor.ini [FarColors], окно - DlgFarColors);
//      F9 - меню Options (Files highlighting - окно правил, Save setup -
//      записать настройки, Shift+F9 - то же);
//    - b.16: Ctrl+Up - нижняя граница панелей вверх (панели короче),
//      Ctrl+Down - вниз (длиннее); под панелями - вывод команд; в editor.ini
//      ([Far] PanelCut - на сколько строк панели короче окна);
//    - b.17: командная строка над кейбаром, как в FAR. Буквы - в неё,
//      Enter - выполнить (cmd.exe /C в папке активной панели, вывод - в
//      область под панелями, кодировка OEM), Esc - очистить, Ctrl+E /
//      Ctrl+X - история, Ctrl+Enter - имя файла под курсором, Ctrl+[ /
//      Ctrl+] - путь левой / правой панели, Ctrl+S / Ctrl+D - каретка,
//      Ctrl+O - спрятать / показать панели (виден весь вывод), Ctrl+Break -
//      прервать команду. Свои команды: cd, X:, cls. Пока строка не пуста,
//      Del и Backspace правят её, файлы не удаляются;
//    - b.19: Enter (и двойной щелчок) на файле: exe, com, bat, cmd -
//      выполнить, как команду (вывод - под панелями), остальные - открыть
//      программой по ассоциации (ShellExecute; ассоциации нет - окно
//      «Открыть с помощью»). Shift+Enter - открыть в своём окне (exe -
//      в отдельном окне, папку - в Проводнике);
//    - b.20: архивы (7-Zip из папки tools\7zip рядом с exe): Enter на
//      архиве (Ctrl+PgDn - на любом файле) раскрывает его в этой же панели,
//      по архиву - как по папкам, '..' в корне - выход; архив в архиве
//      (.tar в .gz) - так же, вложенно. F5 из архива - распаковать
//      выбранное в папку другой панели; Enter на файле в архиве -
//      распаковать во временную папку и открыть. Пароль - спрашивается.
//      Остальные операции в архиве пока не делаются (сообщение).
//    - b.25: буфер обмена. Ctrl+[ / Ctrl+] - путь левой / правой панели в
//      командную строку и в буфер; Ctrl+F - полный путь файла под
//      курсором в командную строку и в буфер; Ctrl+Insert - имя файла под
//      курсором в буфер. В буфер - без кавычек, текстом Unicode
//      (CF_UNICODETEXT; имена вне cp1251 не теряются).
//    - b.26: Ctrl+Left / Ctrl+Right - граница между панелями влево /
//      вправо (левая панель уже / шире; при пустой командной строке, как в
//      FAR; в строке с текстом - каретка на слово). Сдвиг от середины -
//      editor.ini [Far] PanelShift.
//    - b.27: Ctrl+Left / Ctrl+Right в режиме F4 (одна панель) - граница
//      окна FAR и редактора на клетку (OnHalfResize, ширину меняет Unit1,
//      как сплиттер).
//    - b.28: режим F4, Alt+F1 / Alt+F2 на скрытую панель (на её месте
//      редактор) - снова обе панели (OnShowPanels, Unit1 - как кнопка []:
//      файл остаётся вкладкой); на видимую - меню дисков, как раньше. Из
//      редактора - так же (Unit1, AltPanelKey).
//    - b.29: Alt+F7 - поиск файлов, как Find file в FAR (FarFind: маски,
//      текст в cp1251 / cp866 / UTF-8 / UTF-16LE, регистр, слово целиком,
//      папки, где искать). Найденное - окном поверх панелей: Enter / Go to
//      - панель на файл, F4 - файл в редактор (окно остаётся), Esc - стоп,
//      потом закрыть.
//    - b.30: меню дисков (Alt+F1 / Alt+F2), как в FAR: номер тома (Том #,
//      состояние и сведения - из diskpart, в своём потоке; без прав
//      администратора - пояснение), тип, ФС, метка, размер, свободно;
//      ниже - тома без буквы (FarVolumes).
//    - b.31: меню дисков без diskpart: вместо Том # - диск и раздел
//      ('0:2'), колонка 'Модель'; в конце - физические диски (модель, шина,
//      размер, буквы). Запросы к устройствам без прав на чтение (FarVolumes).
//    - b.32: F9 - Options - Colors: палитра окна FAR - цвет каждого
//      элемента панелей, меню, диалогов, кейбара и командной строки
//      (editor.ini [FarPalette], окно - DlgFarPalette). Недоступные пункты
//      меню по умолчанию чёрные (тёмно-серый на бирюзовом не виден).
//    - b.33: FTP (пункт FTP в меню дисков, как плагин FTP в FAR): список
//      адресов (Host | Home | User; Shift+F4 - новый, F4 - изменить,
//      F8 / Del - удалить; editor.ini [FarFtp], пароль - DPAPI), вход
//      на сервер и папки сервера (Enter, '..', Ctrl+R) - WinInet в своём
//      потоке (FarFtp). Копирование и прочее на сервере - следующим шагом.
//    - b.34: FTP: Home адреса не открылся (550) - тот же путь без '/' в
//      начале (от папки входа), нет и его - папка входа, причина - в строке
//      состояния.
//    - b.35: распаковка и упаковка - стандартное окно хода Windows
//      (IProgressDialog, FarProgress): проценты и имя файла из 7z.exe
//      -bsp1, «Отмена» - прервать. Перенос распакованного на место и
//      копирование - SHFileOperation (окно хода - от Windows).
//    - b.36: cd в командной строке: папки нет - папка выше (без последней
//      папки пути); нет и её - 'Папка ... не существует', команда остаётся
//      в строке ввода для правки.
//    - b.37: F4 - свой редактор с подсветкой по схеме .clr (FarEdit,
//      SchemeLine): в панели рядом с файлами или на всю ширину (F5);
//      основной редактор unIDE по F4 больше не открывается.
//    - b.38: палитра: цвет текста и фона редактора (нет - из схемы).
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

// Free Pascal (uniFAR): исходник в кодировке Windows-1251 - строки с
// кириллицей в WideString без кракозябр. Delphi 7 эту строку пропускает
{$IFDEF FPC}{$CODEPAGE CP1251}{$ENDIF}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, ExtCtrls,
  IniBuf, SzSetup, FarFind, FarVolumes, FarFtp, FarProgress,
  ClrScheme, SchemeLine, FarEdit, FarViewer;

const
  FarBuild = 'b.45';

  // Фон панели - для образца раскраски в окне DlgFarColors
  FarPanelColor = $800000;

type
  TFarItem = record
    Name: WideString;
    FtpRaw: string;      // FTP: имя байтами сервера (для команд серверу)
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
  TFarDlgKind = (fdNone, fdCopy, fdMove, fdMkDir, fdDelete, fdEditNew,
    fdArcExtract, fdPassword, fdSzOffer, fdSzProgress, fdSzFail, fdArcAdd,
    fdFind, fdFtpEdit, fdFtpPassword, fdFtpDelete, fdFtpError,
    fdEditQuit, fdEditSave, fdEditEncode, fdEditFind, fdEditGoto, fdEditError,
    fdViewFind, fdViewGoto, fdHiDelete, fdHistClear);

  // Строка окна с несколькими полями (Shift+F1): поле ввода или выбор из
  // нескольких значений
  TFarDlgRow = record
    Caption: WideString;
    IsChoice: Boolean;
    Masked: Boolean;         // поле ввода звёздочками (пароль)
    Text: WideString;
    Pos: Integer;            // каретка: 0..Length(Text)
    Scroll: Integer;
    Fresh: Boolean;          // текст не трогали: ввод заменяет его
    Values: TFarNames;
    Index: Integer;          // выбранное значение
    IsCheck: Boolean;        // флажок [x] (выбор из двух: 0 - снят)
  end;
  TFarDlgRows = array of TFarDlgRow;

  // Строка окна найденного (Alt+F7): заголовок папки или файл (номер в
  // списке найденного)
  TFarFindRow = record
    IsHeader: Boolean;
    Item: Integer;
  end;
  TFarFindRows = array of TFarFindRow;

  // Запись архива (из списка 7z l -slt): путь в архиве через ''
  TFarArcEntry = record
    Path: WideString;
    IsDir: Boolean;
    Size: Int64;
    Time: TFileTime;      // UTC
  end;
  TFarArcEntries = array of TFarArcEntry;

  // Внешний архив, когда открыт вложенный (.tar в .gz): к нему '..'
  TFarArcLevel = record
    ArcFile: WideString;
    Title: WideString;
    Dir: WideString;
    Password: WideString;
    Entries: TFarArcEntries;
  end;
  TFarArcLevels = array of TFarArcLevel;

  // Что делает запущенный 7z.exe
  TFarArcAction = (aaNone, aaList, aaExtract, aaOpenFile, aaAdd);


  // Сортировка панели (порядок - как в меню Ctrl+F12 и клавиши Ctrl+F3 ..
  // Ctrl+F9)
  TFarSortMode = (fsName, fsExt, fsWrite, fsSize, fsUnsorted, fsCreation,
    fsAccess);

  // Открытое меню: смена диска (Alt+F1 / Alt+F2), сортировка (Ctrl+F12),
  // история папок (Alt+F12)
  TFarMenuKind = (fmNone, fmDrive, fmSort, fmHistory, fmOptions,
    fmPalGroups, fmPalItems, fmHiRules, fmThemes);

  TFarMenuItem = record
    Text: WideString;       // '&' перед буквой быстрого выбора
    RightText: WideString;  // справа: клавиша и т.п.
    Mark: WideChar;         // слева: ' ', '+', '-', отметка
    Separator: Boolean;
    Disabled: Boolean;      // недоступен: виден серым, выбрать нельзя
    Data: WideString;       // что выбрано: путь, буква диска
    Tag: Integer;
    // Текст пункта - своими цветами (образец цвета; clNone - цвет панели)
    HasColors: Boolean;
    Fore: TColor;
    Back: TColor;
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
    // Архив в панели: файл архива ('' - обычная папка; вложенный - его
    // копия во временной папке), заголовок (путь для показа), папка в
    // архиве ('' - корень), записи, пароль, внешние архивы. FPath при
    // этом - папка, где лежит (внешний) архив
    FArcFile: WideString;
    FArcTitle: WideString;
    FArcDir: WideString;
    FArcEntries: TFarArcEntries;
    FArcPassword: WideString;
    FArcLevels: TFarArcLevels;
    // FTP: 0 - нет, 1 - список адресов, 2 - папка сервера (FFtpDir -
    // байтами сервера). FPath - папка, где панель была до FTP (туда '..'
    // из списка адресов). FFtpConn - соединение (nil, пока его держит
    // поток); FFtpSession растёт при каждом уходе с FTP - ответ потока для
    // прежнего захода отбрасывается
    FFtpMode: Integer;
    FFtpHost: TFarFtpHost;
    FFtpHostIdx: Integer;
    FFtpDir: string;
    FFtpConn: TFarFtpConn;
    FFtpSession: Integer;
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
    // Архив: содержимое папки FArcDir из FArcEntries, курсор - на AFocus
    procedure BuildArcView(const AFocusName: WideString);
    function IsArchive: Boolean;
    function IsFtp: Boolean;
    // Уйти с FTP: соединение закрыть, режим - обычная папка
    procedure FtpLeave;
    // Путь для заголовка: в архиве - архив и папка в нём
    function DisplayPath: WideString;
    // Путь элемента панели в архиве
    function ArcInnerPath(const AName: WideString): WideString;
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

  // Раскраска файлов: расширение (без точки, строчными), включено ли,
  // цвет текста и фона (clNone - фон панели). Цвета - любые RGB.
  TFarColorRule = record
    Ext: string;
    Enabled: Boolean;
    Fore: TColor;
    Back: TColor;
  end;
  TFarColorRules = array of TFarColorRule;

  // Палитра окна FAR (F9 - Options - Colors): цвет каждого элемента.
  // Порядок - как в окне DlgFarPalette (по группам)
  TFarPalItem = (
    fpPanelBack, fpPanelText, fpPanelDir, fpPanelSelected, fpPanelHeader,
    fpPanelFrame, fpPanelCursorBack, fpPanelCursorText,
    fpMenuBack, fpMenuText, fpMenuHotkey, fpMenuDisabled, fpMenuFrame,
    fpMenuCursorBack,
    fpDlgBack, fpDlgText, fpDlgFocusBack, fpDlgFocusText, fpDlgEditBack,
    fpDlgEditText, fpDlgSelBack, fpDlgSelText,
    fpWarnBack, fpWarnText, fpWarnFocusBack, fpWarnFocusText,
    fpKeyNum, fpKeyNumBack, fpKeyText, fpKeyBack,
    fpCmdBack, fpCmdPrompt, fpCmdText, fpOutText,
    fpEditBack, fpEditText, fpEditTitleBack, fpEditTitleText, fpEditSelBack,
    fpEditSelText);
  TFarPalette = array[TFarPalItem] of TColor;

  TFarStatusEvent = procedure(const AText: string) of object;
  // Схема подсветки для файла (редактор F4); объект переходит редактору,
  // nil - без подсветки
  TFarSchemeEvent = function(const AFileName: WideString): TClrScheme of object;
  // F4 / Shift+F4: файл - в редактор. ACreated - файла не было, его создал
  // Shift+F4 (пустой)
  TFarEditEvent = procedure(const AFileName: WideString;
    ACreated: Boolean) of object;
  // Режим F4, Ctrl+Left / Ctrl+Right: граница окна FAR влево (ADelta = -1)
  // или вправо (1) на ACellWidth пикселей
  TFarHalfResizeEvent = procedure(ADelta, ACellWidth: Integer) of object;

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
    FOnEditFile: TFarEditEvent;
    FOnLeave: TNotifyEvent;
    FOnHalfResize: TFarHalfResizeEvent;
    FOnShowPanels: TNotifyEvent;
    FOnColorsDialog: TNotifyEvent;
    FOnPaletteDialog: TNotifyEvent;
    FOnGetScheme: TFarSchemeEvent;
    // Своя строка сообщений над командной строкой (uniFAR; в unIDE
    // сообщения - в строку состояния IDE через OnStatus)
    FMessageLine: Boolean;
    FMessageText: WideString;
    // WM_CHAR приходит в UTF-16 (окно Unicode, uniFAR); иначе - байт
    // кодировки Windows (окно VCL Delphi 7)
    FUnicodeChars: Boolean;
    // Редактор (F4): текст; в какой панели (или обе - FEditWide); поиск;
    // куда записать после вопроса о кодировке; закрыть после записи
    FEditor: TFarEditor;
    FEditPanel: Integer;
    FEditWide: Boolean;
    FEditFind: WideString;
    FEditFindCase: Boolean;
    FEditSaveName: WideString;
    FEditQuitAfterSave: Boolean;
    FEditDragging: Boolean;
    FEditTabSize: Integer;        // editor.ini [Editor] TabChars
    // Просмотр (F3): на месте редактора (FEditPanel / FEditWide), вместе с
    // редактором не бывает
    FViewer: TFarViewer;
    FViewFind: WideString;
    FViewFindCase: Boolean;
    // F9 - Colors / Files highlighting своими окнами: группа палитры в
    // меню элементов, правило для удаления, окно выбора цвета (Pick*)
    FPalGroupFirst: TFarPalItem;
    FHiDelIdx: Integer;
    FPickOpen: Boolean;
    FPickRuleIdx: Integer;
    FPickExt: WideString;
    FPickExtPos: Integer;
    FPickFore: TColor;
    FPickBack: TColor;
    FPickFocus: Integer;
    FPickExtRow, FPickExtCol, FPickForeRow, FPickBackRow: Integer;
    FPickPanelRow, FPickBtnRow: Integer;
    FPickBtnCol: array[0..1] of Integer;
    // Тема (F9 - Options - Themes) и свои цвета окна выбора цвета
    FThemeName: string;
    FCustColors: array[0..15] of COLORREF;
    FPal: TFarPalette;            // цвета элементов (F9 - Options - Colors)
    FIniName: string;             // editor.ini (LoadState) - для Save setup
    // Раскраска файлов: правила и их расширения как WideString (сравнение
    // с именами файлов)
    FColorRules: TFarColorRules;
    FColorExt: array of WideString;
    FSingle: Integer;             // -1 - две панели; 0 / 1 - только эта (F4)
    FHalfWidth: Integer;          // ширина окна в режиме F4, пикселей (0 - нет)
    FPanelCut: Integer;           // на сколько строк панели короче окна
                                  // (Ctrl+Up / Ctrl+Down)
    FPanelShift: Integer;         // граница панелей: сдвиг от середины, клеток
                                  // (Ctrl+Left / Ctrl+Right)
    // Командная строка: текст, каретка (0..Length), история (старые
    // сверху) и место в ней при Ctrl+E / Ctrl+X
    FCmdText: WideString;
    FCmdPos: Integer;
    FCmdHistory: TFarNames;
    FCmdHistPos: Integer;
    // Вывод команд: строки (последняя может быть не закончена -
    // FOutOpen), прокрутка колесом (строк экрана от низа)
    FOutLines: TFarNames;
    FOutOpen: Boolean;
    FOutScroll: Integer;
    FPanelsHidden: Boolean;       // Ctrl+O: панели спрятаны, виден вывод
    // Выполняемая команда: процесс cmd.exe и его вывод (труба)
    FProcHandle: THandle;
    FProcPipe: THandle;
    FProcTimer: TTimer;
    // Загрузка 7-Zip (нет tools\7zip\7z.exe)
    FSzThread: TSzInstall;
    FSzTarget: WideString;
    FSzTimer: TTimer;
    FSzPackage: TSzPackage;
    FSzOsName: string;
    // Shift+F1: последние формат (0 - ZIP, 1 - 7z) и уровень (0..5); работа
    FArcAddFormat: Integer;
    FArcAddLevel: Integer;
    FArcJobFormat: Integer;
    FArcJobLevel: Integer;
    FArcJobExists: Boolean;       // архив был до упаковки (дополняется)
    FArcAddPercent: Integer;
    // Окно хода распаковки / упаковки (IProgressDialog Windows)
    FArcProgress: TFarProgress;
    // Вывод процесса не в окно, а в буфер (7z.exe: список архива, ошибки)
    FProcCapture: Boolean;
    FProcRaw: string;
    // Работа с архивом через 7z.exe: что делается и с чем (для повтора с
    // паролем - всё здесь)
    FArcAction: TFarArcAction;
    FArcJobPanel: Integer;
    FArcJobFile: WideString;      // файл архива
    FArcJobTitle: WideString;     // его заголовок (для вложенного)
    FArcJobNested: Boolean;       // открыть как вложенный в текущий архив
    FArcJobStart: WideString;     // DisplayPath панели при запуске
    FArcJobPrefix: WideString;    // папка в архиве ('' - корень)
    FArcJobNames: TFarNames;      // что распаковать (имена в FArcJobPrefix)
    FArcJobDest: WideString;      // куда (с '')
    FArcJobTemp: WideString;      // временная папка распаковки (с '')
    FArcJobPassword: WideString;
    FArcJobForce: Boolean;        // файл из архива - открыть как архив
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
    FDlgMasked: Boolean;          // поле ввода звёздочками (пароль)
    FDlgRows: TFarDlgRows;        // поля окна Shift+F1 (под строками текста)
    FDlgRow: Integer;             // строка с фокусом; -1 - фокус на кнопках
    FDlgRowsTop: Integer;         // где нарисована первая (для мыши)
    FDlgRowsLeft: Integer;        // колонка начала полей
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
    // История папок (Alt+F12): старые сверху, новые снизу. FHistoryLock -
    // закреплённые (Ins в меню): их не удаляют Del, Shift+Del и вытеснение
    // старых записей при переполнении
    FHistory: TFarNames;
    FHistoryLock: array of Boolean;
    // Поиск файлов (Alt+F7): окно Find file - что искать (запоминается),
    // окно найденного - поверх панелей
    FFindMask: WideString;
    FFindText: WideString;
    FFindCodePage: Integer;
    FFindCase: Boolean;
    FFindWhole: Boolean;
    FFindFolders: Boolean;
    FFindArea: Integer;            // 0 - с подпапками, 1 - только папка, 2 - диск
    FFindOpen: Boolean;
    FFindThread: TFarFindThread;
    FFindTimer: TTimer;
    FFindOptions: TFarFindOptions;
    FFindItems: TFarFindItems;
    FFindRows: TFarFindRows;
    FFindCursor: Integer;
    FFindTop: Integer;
    FFindFocus: Integer;           // -1 - список, 0..3 - кнопка
    FFindDone: Boolean;
    FFindListTop: Integer;         // где нарисовано (для мыши)
    FFindButtonRow: Integer;
    FFindButtonCol: array[0..3] of Integer;
    FFindButtonLen: array[0..3] of Integer;
    // Последняя папка на каждом диске A..Z (любой из панелей) - куда
    // вести при смене диска, если другая панель не на этом диске
    FDriveLast: array[0..25] of WideString;
    // FTP: адреса (editor.ini [FarFtp]), поток запроса каждой панели и что
    // он делает (заход FFtpSession панели, курсор после чтения, адрес)
    FFtpHosts: TFarFtpHosts;
    FFtpThread: array[0..1] of TFarFtpThread;
    FFtpJobSession: array[0..1] of Integer;
    FFtpJobFocus: array[0..1] of string;
    FFtpJobHost: array[0..1] of TFarFtpHost;
    FFtpJobHostIdx: array[0..1] of Integer;
    FFtpEditIdx: Integer;          // окно адреса: какой адрес (-1 - новый)
    FFtpEditPanel: Integer;
    FFtpPassPanel: Integer;        // окно пароля: панель и адрес
    FFtpPassHostIdx: Integer;
    FFtpDelIdx: Integer;           // удалить адрес: какой
    FFtpDelPanel: Integer;
    procedure CreateFonts;
    procedure FreeFonts;
    procedure UpdateGrid;
    function ActivePanel: TFarPanel;
    procedure PanelBounds(AIndex: Integer; var AX0, AWidth: Integer);
    function PanelHeight: Integer;
    function MaxPanelCut: Integer;
    // Командная строка и вывод
    function CmdRow: Integer;
    function OutBottom: Integer;
    procedure SetMessageLine(AValue: Boolean);
    procedure DrawMessageLine;
    function KeyChar(ACode: WPARAM): WideChar;
    // Текст в буфер обмена, в строке состояния - что скопировано
    procedure CopyToClipboard(const AText: WideString);
    // Полный путь файла под курсором активной панели ('..' - путь панели;
    // в архиве - путь для показа: архив\папка\имя); пусто - панель пуста
    function CursorFullName: WideString;
    function CmdKey(AKey: Word; AShift, ACtrl, AAlt: Boolean;
      var AHandled: Boolean): Boolean;
    procedure CmdInsert(const AText: WideString);
    procedure CmdSetText(const AText: WideString);
    procedure CmdExecute;
    function CmdBuiltin(const ACommand: WideString): Boolean;
    procedure CmdRun(const ACommand: WideString);
    procedure CmdHistoryAdd(const ACommand: WideString);
    procedure DrawCmdLine;
    procedure DrawOutput(ATopRow, ABottomRow: Integer);
    procedure OutAppend(const AText: WideString);
    procedure OutLine(const AText: WideString);
    procedure ProcTick(Sender: TObject);
    procedure ProcFinish(AKill: Boolean);
    function PromptText: WideString;
    procedure ChangePanelCut(ADelta: Integer);
    procedure ChangePanelShift(ADelta: Integer);
    function LeftPanelWidth: Integer;
    function KeyBarRows: Integer;
    function FileRows: Integer;
    procedure ColumnWidths(AWidth: Integer; var AFirst, ASecond: Integer);
    function PageSize(APanel: TFarPanel): Integer;
    procedure EnsureVisible(APanel: TFarPanel);
    function FitsMainFont(AText: PWideChar; ACount: Integer): Boolean;
    procedure FillCells(ACol, ARow, AWidth: Integer; ABack: TColor);
    procedure PutText(ACol, ARow, AWidth: Integer; const AText: WideString;
      AFore, ABack: TColor);
    procedure PutCentered(ACol, ARow, AWidth: Integer;
      const AText: WideString; AFore, ABack: TColor);
    procedure DrawPanel(AIndex: Integer);
    // ASecondCol - вторая граница колонок (-1 - нет)
    procedure DrawFrame(AX0, AWidth, AHeight, AFirstCol: Integer;
      ASecondCol: Integer = -1);
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
    procedure DlgAddCheck(const ACaption: WideString; AChecked: Boolean);
    // Поиск файлов (Alt+F7)
    procedure StartFind;
    // FTP
    procedure FtpHostColumns(AWidth: Integer; var AHostW, AHomeW,
      AUserW: Integer);
    function PanelColumns(APanel: TFarPanel): Integer;
    procedure FtpFillHosts(APanel: TFarPanel; AFocusIdx: Integer);
    procedure FtpFillEntries(APanel: TFarPanel;
      const AEntries: TFarFtpEntries; const AFocusRaw: string);
    procedure OpenFtpHosts(APanelIndex: Integer);
    procedure FtpExit(APanel: TFarPanel);
    procedure FtpError(const ATitle, AText: WideString);
    procedure FtpStartList(APanelIndex: Integer; const AHost: TFarFtpHost;
      AHostIdx: Integer; const ADir, AFocusRaw: string;
      AIsHome: Boolean = False);
    procedure FtpConnect(APanelIndex, AHostIdx: Integer);
    procedure FtpPasswordEntered(const APassword: WideString);
    procedure FtpCheck;
    procedure FtpUp(APanelIndex: Integer);
    procedure FtpEnter(APanelIndex: Integer);
    procedure FtpEditHost(APanelIndex, AHostIdx: Integer);
    procedure FtpEditConfirm(AConnect: Boolean);
    procedure FtpDeleteHost(APanelIndex: Integer);
    procedure FtpDeleteConfirmed;
    procedure FtpImportHosts;
    procedure FtpCopyHosts;
    function FtpPasteHosts: Boolean;
    function FtpKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
    procedure DrawFtpHosts(APanel: TFarPanel; APanelX, APanelW: Integer;
      AIsActive: Boolean);
    // Редактор (F4)
    function EditorShown(APanelIndex: Integer): Boolean;
    function EditorActive: Boolean;
    procedure EditBounds(var AX0, AWidth: Integer);
    function EditTextRows: Integer;
    procedure EditEnsureVisible;
    procedure OpenEditor(const AFileName: WideString);
    procedure CloseEditor;
    procedure EditQuit;
    procedure EditSave(const AFileName: WideString;
      AEncoding: TFarEditEncoding; AAllowLossy: Boolean);
    procedure EditFindConfirm;
    procedure EditFindNext;
    procedure EditGoto(const AText: WideString);
    procedure EditChar(ACh: WideChar);
    function EditKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
    procedure EditMouse(AX, AY: Integer; AShiftDown, ADrag: Boolean);
    procedure DrawEditor;
    function DocOpen: Boolean;
    function ViewerActive: Boolean;
    function ViewTextRows: Integer;
    procedure ViewCurrent;
    procedure OpenViewer(const AFileName: WideString);
    procedure CloseViewer;
    procedure ViewFindConfirm;
    procedure ViewFindNext;
    procedure ViewGoto(const AText: WideString);
    function ViewKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
    function ViewKeyLabel(AKeyIndex: Integer; AShift, ACtrl,
      AAlt: Boolean): string;
    procedure DrawViewer;
    procedure ShowPalGroups(ACursor: Integer);
    procedure ShowPalItems(AFirst: TFarPalItem; ACursor: TFarPalItem);
    procedure ShowHiRules(ACursor: Integer);
    procedure HiRulesApply(ACursor: Integer);
    function HiRulesKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
    procedure HiDeleteRule(AIndex: Integer);
    procedure PalItemChoose(AItem: TFarPalItem);
    procedure PalItemDefault(AItem: TFarPalItem);
    function ChooseColor(var AColor: TColor; const ATitle: WideString): Boolean;
    procedure SaveThemeState;
    procedure LoadThemeState(const AIniName: string);
    procedure ShowThemesMenu;
    procedure ApplyTheme(const AName: string; const APalette: TFarPalette);
    procedure ThemeImport;
    procedure PickOpenRule(AIndex: Integer);
    procedure PickClose;
    function PickButtonText(AIndex: Integer): WideString;
    procedure PickMoveFocus(ADelta: Integer);
    procedure PickChooseColor(ABack: Boolean);
    procedure PickButton(AIndex: Integer);
    procedure PickEditKey(var AText: WideString; var APos: Integer;
      AKey: Word; AChar: WideChar);
    function PickKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
    procedure PickChar(ACh: WideChar);
    procedure DrawPick;
    procedure PickMouse(AX, AY: Integer);
    function GetParentFormHandle: HWND;
    procedure FindConfirm;
    procedure FindBegin(const AOptions: TFarFindOptions);
    procedure FindStopThread;
    procedure FindQuit;
    procedure FindTakeFound;
    procedure FindTick(Sender: TObject);
    function FindListRows: Integer;
    procedure FindMove(ADelta: Integer);
    function FindCurrent(var AItem: TFarFindItem): Boolean;
    procedure FindGoTo;
    procedure FindEdit;
    procedure FindButton(AIndex: Integer);
    function FindKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
    function FindRowText(ARowIdx, AWidth: Integer): WideString;
    procedure DrawFind;
    function FileCountOf: Integer;
    function DirCountOf: Integer;
    procedure FindMouse(AX, AY: Integer);
    function DlgKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
    procedure DlgInsertText(const AText: WideString);
    procedure DrawDialogRow(ARowIndex, ARow, AInnerLeft, AInnerW: Integer;
      AFore, ABack: TColor);
    procedure DlgActivate(AButton: Integer);
    procedure DrawBox(ALeft, ATop, ARight, ABottom: Integer; AColor: TColor);
    procedure DrawDialog;
    procedure StartCopy(AMove, ACurrentOnly: Boolean);
    procedure StartMkDir;
    procedure StartDelete(ACurrentOnly, APermanent: Boolean);
    procedure DoCopyMove(AMove: Boolean; const ATarget: WideString);
    procedure DoMkDir(const AName: WideString);
    procedure OpenItem(ASeparate: Boolean);
    procedure ShellOpen(const AFile, ADir: WideString);
    // Архивы (7z.exe)
    function SevenZipPath: WideString;
    function IsArchiveName(const AName: WideString): Boolean;
    function ArcBlocked: Boolean;
    function StartProcess(const ACommandLine, AWorkDir: WideString;
      ACapture: Boolean): Boolean;
    procedure OpenArchive(APanelIndex: Integer; const AFile,
      ATitle: WideString; ANested: Boolean; const APassword: WideString);
    procedure ArcRun;
    procedure ArcDone(AExitCode: DWORD);
    procedure ArcApplyList(const AOutput: WideString);
    procedure ArcCleanupTemp;
    procedure SzOffer;
    procedure SzStartDownload;
    procedure SzTick(Sender: TObject);
    procedure SzProgress;
    procedure SzCancel;
    procedure SzFail(const AText: WideString);
    procedure ArcUp(APanel: TFarPanel);
    procedure ArcOpenItem(ASeparate, AForceArchive: Boolean);
    procedure StartArcExtract;
    procedure StartArcAdd;
    procedure ArcAddConfirm;
    procedure ArcAddFormatChanged(AOldFormat: Integer);
    procedure ArcAddProgress;
    procedure ArcProgressStart;
    procedure ArcAddDone(AExitCode: DWORD; const AOutput: WideString);
    procedure DlgAddRow(const ACaption: WideString; AIsChoice, AMasked: Boolean;
      const AText: WideString; const AValues: array of WideString;
      AIndex: Integer);
    function DlgRowsKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
    function DlgRowIsEdit: Boolean;
    procedure DlgRowInsert(const AText: WideString);
    procedure DlgRowsMouse(AX, AY: Integer);
    function DlgChoiceCol(const ARow: TFarDlgRow; AValueIndex: Integer): Integer;
    procedure DoArcExtract(const ATarget: WideString);
    procedure ArcError(const AOutput: WideString);
    procedure DoDelete;
    procedure EditCurrent;
    procedure StartEditNew;
    procedure DoEditNew(const AName: WideString);
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
    procedure ShowHistoryMenu(ACursor: Integer = -1);
    function HistoryFind(const APath: WideString): Integer;
    procedure HistoryDelete(AIndex: Integer);
    procedure HistoryClearUnlocked;
    procedure SetSort(APanel: TFarPanel; AMode: TFarSortMode);
    procedure ToggleSelFirst(APanel: TFarPanel);
    procedure SelectDrive(APanelIndex: Integer; ALetter: WideChar);
    procedure HistoryAdd(const APath: WideString);
    function MenuSkip(AIndex: Integer): Boolean;
    procedure ShowOptionsMenu;
    procedure SaveSetup;
    function RuleColors(const AName: WideString;
      var AFore, ABack: TColor): Boolean;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure DblClick; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Клавиатурное сообщение окна FAR (WM_KEYDOWN, WM_SYSKEYDOWN, WM_KEYUP,
    // WM_SYSKEYUP) из TForm1.AppMessage. True - разобрано, дальше не
    // отдавать. F1..F12 FAR забирает всегда.
    function KeyMessage(const AMsg: TMsg): Boolean;
    // Alt+F1 (APanelIndex = 0) / Alt+F2 (1): панель скрыта (режим F4) -
    // снова обе панели (OnShowPanels), видна - меню дисков. Отпускание Alt
    // после этого гасится (полоса меню IDE не открывается). Зовёт и Unit1,
    // когда Alt+F1 / Alt+F2 нажаты в редакторе
    procedure AltPanelKey(APanelIndex: Integer);
    // Перечитать обе панели (окно открыли снова - файлы могли измениться)
    procedure RereadAll;
    // Одна панель на всё окно (APanel 0 / 1, она же активная) или обе (-1).
    // Режим F4: окно FAR - половина области, вторая половина - редактор.
    procedure SetSingle(APanel: Integer);
    // Правила раскраски (копируются); ColorRules - копия текущих
    procedure SetColorRules(const ARules: TFarColorRules);
    function ColorRules: TFarColorRules;
    // Палитра (копируется, окно перерисовывается); Palette - копия текущей
    procedure SetPalette(const APalette: TFarPalette);
    function Palette: TFarPalette;
    function ActiveIndex: Integer;
    // Курсор активной панели - на файл AFileName (папка другая - перейти
    // в неё). Щелчок по вкладке редактора, когда FAR открыт.
    procedure ShowFile(const AFileName: WideString);
    // Активная панель - в папку APath (uniFAR: папка из командной строки)
    procedure ShowFolder(const APath: WideString);
    procedure LoadState(const AIniName: string; const ADefaultDir: WideString);
    // Закрытие unIDE: в редакторе F4 изменён текст - спросить (окном
    // Windows). False - не закрывать
    function EditorCanClose: Boolean;
    procedure SaveState(const AIniName: string);
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
    property OnStatus: TFarStatusEvent read FOnStatus write FOnStatus;
    property OnEditFile: TFarEditEvent read FOnEditFile write FOnEditFile;
    // Tab, когда видна одна панель: фокус - редактору
    property OnLeave: TNotifyEvent read FOnLeave write FOnLeave;
    // Ctrl+Left / Ctrl+Right, когда видна одна панель: ширина окна FAR
    property OnHalfResize: TFarHalfResizeEvent read FOnHalfResize
      write FOnHalfResize;
    // Alt+F1 / Alt+F2 на скрытую панель (режим F4): снова обе панели (Unit1)
    property OnShowPanels: TNotifyEvent read FOnShowPanels write FOnShowPanels;
    // F9 - Options - Files highlighting: окно правил раскраски (Unit1)
    property OnColorsDialog: TNotifyEvent read FOnColorsDialog
      write FOnColorsDialog;
    // F9 - Options - Colors: окно палитры (Unit1)
    property OnPaletteDialog: TNotifyEvent read FOnPaletteDialog
      write FOnPaletteDialog;
    // Редактор F4: схема подсветки файла (Unit1)
    property OnGetScheme: TFarSchemeEvent read FOnGetScheme write FOnGetScheme;
    // Строка сообщений над командной строкой: туда же Status, если
    // OnStatus не задан
    property MessageLine: Boolean read FMessageLine write SetMessageLine;
    property UnicodeChars: Boolean read FUnicodeChars write FUnicodeChars;
    property SinglePanel: Integer read FSingle;
    // Ширина окна FAR в режиме F4 (пикселей, 0 - не задана): ставит и
    // читает Unit1 (сплиттер), хранится в editor.ini ([Far] HalfWidth)
    property HalfWidth: Integer read FHalfWidth write FHalfWidth;
  end;

var
  // Имя программы в сообщениях и заголовках окон: 'unIDE FAR' - FAR внутри
  // unIDE; uniFAR ставит своё до создания TFarView
  FarProduct: string = 'unIDE FAR';

// Путь для ANSI-кода IDE (Delphi 7): в кодировке Windows, если она вмещает
// все символы, иначе - короткое имя 8.3; нельзя ни так, ни так - ''
function FarToAnsiPath(const APath: WideString): string;

// Раскраска файлов: стандартный набор, чтение и запись editor.ini
// ([FarColors]: '_Set=1' и строки 'ext=1,#RRGGBB,#RRGGBB'; '-' вместо фона
// - фон панели). Раздела нет (или в нём нет _Set) - стандартный набор.
procedure FarColorsDefault(var ARules: TFarColorRules);
procedure FarColorsLoad(const AIniName: string; var ARules: TFarColorRules);
procedure FarColorsSave(const AIniName: string; const ARules: TFarColorRules);
function FarColorToText(AColor: TColor): string;
function FarTextToColor(const AText: string; ADefault: TColor): TColor;
// Расширение для правила: без '*.' и '.', строчными; '' - нельзя
function FarNormalizeExt(const AText: string): string;
procedure FarCopyRules(const ASource: TFarColorRules;
  var ADest: TFarColorRules);

// Палитра окна FAR: стандартная, чтение и запись editor.ini ([FarPalette]:
// 'PanelBack=#000080' и т.д.; нет ключа - стандартный цвет)
procedure FarPaletteDefault(var APalette: TFarPalette);
procedure FarPaletteLoad(const AIniName: string; var APalette: TFarPalette);
procedure FarPaletteSave(const AIniName: string; const APalette: TFarPalette);
// Сведения об элементе палитры: ключ в editor.ini, группа, подпись,
// стандартный цвет, фон ли это, парный элемент (фон для цвета текста и
// наоборот - для образца)
function FarPalKey(AItem: TFarPalItem): string;
function FarPalGroup(AItem: TFarPalItem): string;
function FarPalCaption(AItem: TFarPalItem): string;
function FarPalDefault(AItem: TFarPalItem): TColor;
function FarPalIsBack(AItem: TFarPalItem): Boolean;
function FarPalPair(AItem: TFarPalItem): TFarPalItem;
// Фон панели текущей палитры (образцы в окне DlgFarColors)
function FarPanelBackColor: TColor;

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
  FarDarkGray = $808080;      // F_DARKGRAY

  FarFontRes = 'FAR_TER_C18B';
  FarFontFile = 'ter-c18b.fnt';
  FarGaRoot = 2;                  // GA_ROOT
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

  // Командная строка
  FarCpOem = 1;                    // CP_OEMCP: вывод консольных программ
  FarHandleInherit = 1;            // HANDLE_FLAG_INHERIT
  FarStartfUseShowWindow = 1;
  FarStartfUseStdHandles = $100;
  FarCreateNoWindow = $08000000;
  FarOutMaxLines = 2000;           // столько строк вывода держим
  FarCmdHistoryMax = 50;
  FarCmdHistorySection = 'FarCmdHistory';
  FarVkLeftBracket = $DB;          // VK_OEM_4: '['
  FarVkRightBracket = $DD;         // VK_OEM_6: ']'
  FarSeErrNoAssoc = 31;            // SE_ERR_NOASSOC: нет программы для файла

  // Архивы: 7z.exe - в папке tools\7zip рядом с exe unIDE. Enter
  // раскрывает файлы с этими расширениями (остальные - Ctrl+PgDn): exe,
  // msi, docx, jar, chm и т.п. Enter запускает или открывает программой
  FarArcExts = ' 7z zip zipx rar arj cab lzh lha tar gz gzip tgz tpz bz2 ' +
    'bzip2 tbz2 tbz xz txz zst lzma z taz cpio rpm deb xar wim swm esd ' +
    'iso udf img vhd vhdx vmdk vdi qcow qcow2 dmg squashfs cramfs 001 r00 ' +
    'chm msi jar apk xpi war ear ';
  FarFofSilent = $4;
  FarFofNoErrorUI = $400;
  FarArcTempDir = 'unIDE_far';
  // Пункт FTP в меню дисков (Data пункта)
  FarFtpMenuData = 'ftp:';
  // Окно Shift+F1: ширина подписей полей; форматы и уровни сжатия (-mx)
  FarDlgCaptionW = 11;
  FarArcAddExts: array[0..1] of string = ('.zip', '.7z');
  FarArcAddTypes: array[0..1] of string = ('zip', '7z');
  FarArcAddLevels: array[0..5] of Integer = (0, 1, 3, 5, 7, 9);
  FarMoveReplace = 1;      // MOVEFILE_REPLACE_EXISTING
  FarMoveCopyAllowed = 2;  // MOVEFILE_COPY_ALLOWED
  FarInvalidAttr = $FFFFFFFF;

  // Кейбар: подписи FAR (far\farlang.templ.m4) для того, что есть или
  // будет в unIDE FAR. Пустые - клавиша в unIDE FAR не используется.
  FarKeysNormal: array[0..11] of string = ('Help', 'UserMn', 'View', 'Edit',
    'Copy', 'RenMov', 'MkFold', 'Delete', 'ConfMn', 'Quit', '', 'Screen');
  FarKeysShift: array[0..11] of string = ('Add', '', '', 'Edit..', 'Copy',
    'Rename', '', 'Delete', 'Save', '', '', 'SelUp');
  FarKeysAlt: array[0..11] of string = ('Left', 'Right', '', '', '', '',
    'Find', '', '', '', '', 'FoldHs');
  FarKeysCtrl: array[0..11] of string = ('', '', 'Name', 'Extens', 'Write',
    'Size', 'Unsort', 'Creatn', 'Access', '', '', 'Sort');
  // Кейбар редактора (F4)
  FarEdKeysNormal: array[0..11] of string = ('', 'Save', '', '', 'Wide', '',
    'Search', '', '', 'Quit', '', '');
  FarEdKeysShift: array[0..11] of string = ('', 'SaveAs', '', '', '', '',
    'Next', '', '', '', '', '');
  FarEdKeysAlt: array[0..11] of string = ('', '', '', '', '', '', '', 'Goto',
    '', '', '', '');

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

  TFarSecurityAttributes = record
    nLength: DWORD;
    lpSecurityDescriptor: Pointer;
    bInheritHandle: BOOL;
  end;

  TFarStartupInfo = record
    cb: DWORD;
    lpReserved: PWideChar;
    lpDesktop: PWideChar;
    lpTitle: PWideChar;
    dwX, dwY, dwXSize, dwYSize: DWORD;
    dwXCountChars, dwYCountChars, dwFillAttribute: DWORD;
    dwFlags: DWORD;
    wShowWindow: Word;
    cbReserved2: Word;
    lpReserved2: Pointer;
    hStdInput, hStdOutput, hStdError: THandle;
  end;

  TFarProcessInfo = record
    hProcess, hThread: THandle;
    dwProcessId, dwThreadId: DWORD;
  end;

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
function FarMessageBox(AWnd: HWND; AText, ACaption: PWideChar;
  AType: UINT): Integer; stdcall; external 'user32.dll' name 'MessageBoxW';
function FarGetAncestor(AWnd: HWND; AFlags: UINT): HWND; stdcall;
  external 'user32.dll' name 'GetAncestor';
// Указатели, а не const: так одинаково в Delphi 7 и Free Pascal
function FarCompareFileTime(AFirst, ASecond: PFileTime): Longint; stdcall;
  external 'kernel32.dll' name 'CompareFileTime';

// Сравнение времён файлов (-1, 0, 1); параметры - копии, их адреса - для
// CompareFileTime
function FarFileTimeCmp(ATimeA, ATimeB: TFileTime): Integer;
begin
  Result := FarCompareFileTime(@ATimeA, @ATimeB);
end;

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
function FarGetShortPath(ALongPath, AShortPath: PWideChar;
  ABufferLen: DWORD): DWORD; stdcall;
  external 'kernel32.dll' name 'GetShortPathNameW';
// Командная строка: процесс cmd.exe с выводом в трубу
function FarCreatePipe(var AReadPipe, AWritePipe: THandle;
  AAttributes: Pointer; ASize: DWORD): BOOL; stdcall;
  external 'kernel32.dll' name 'CreatePipe';
function FarSetHandleInfo(AHandle: THandle; AMask, AFlags: DWORD): BOOL;
  stdcall; external 'kernel32.dll' name 'SetHandleInformation';
function FarPeekPipe(APipe: THandle; ABuffer: Pointer; ABufferSize: DWORD;
  ABytesRead, ATotalAvail, ABytesLeft: Pointer): BOOL; stdcall;
  external 'kernel32.dll' name 'PeekNamedPipe';
function FarReadFile(AFile: THandle; ABuffer: Pointer; AToRead: DWORD;
  ABytesRead: Pointer; AOverlapped: Pointer): BOOL; stdcall;
  external 'kernel32.dll' name 'ReadFile';
function FarGetExitCode(AProcess: THandle; var AExitCode: DWORD): BOOL;
  stdcall; external 'kernel32.dll' name 'GetExitCodeProcess';
function FarTerminate(AProcess: THandle; AExitCode: UINT): BOOL; stdcall;
  external 'kernel32.dll' name 'TerminateProcess';
function FarGetEnvVar(AName, ABuffer: PWideChar; ASize: DWORD): DWORD;
  stdcall; external 'kernel32.dll' name 'GetEnvironmentVariableW';
function FarGetFullPath(AFileName: PWideChar; ABufferLen: DWORD;
  ABuffer: PWideChar; AFilePart: Pointer): DWORD; stdcall;
  external 'kernel32.dll' name 'GetFullPathNameW';
function FarCreateProcess(AAppName, ACommandLine: PWideChar;
  AProcessAttr, AThreadAttr: Pointer; AInherit: BOOL; AFlags: DWORD;
  AEnvironment: Pointer; ACurrentDir: PWideChar;
  var AStartupInfo: TFarStartupInfo;
  var AProcessInfo: TFarProcessInfo): BOOL; stdcall;
  external 'kernel32.dll' name 'CreateProcessW';
function FarGetTempPath(ABufferLen: DWORD; ABuffer: PWideChar): DWORD;
  stdcall; external 'kernel32.dll' name 'GetTempPathW';
function FarShellExecute(AWnd: HWND; AOperation, AFile, AParameters,
  ADirectory: PWideChar; AShowCmd: Integer): THandle; stdcall;
  external 'shell32.dll' name 'ShellExecuteW';
function FarCreateFile(AFileName: PWideChar; AAccess, AShare: DWORD;
  ASecurity: Pointer; ADisposition, AFlags: DWORD;
  ATemplate: THandle): THandle; stdcall;
  external 'kernel32.dll' name 'CreateFileW';
function FarMoveFileEx(AExisting, ANew: PWideChar; AFlags: DWORD): BOOL;
  stdcall; external 'kernel32.dll' name 'MoveFileExW';
function FarDeleteFile(AFileName: PWideChar): BOOL; stdcall;
  external 'kernel32.dll' name 'DeleteFileW';

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

  FontPath := ExtractFilePath(ParamStr(0)) + FarFontFile;
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

// Удалить папку ADir (с '\' в конце или без) со всем содержимым, без
// окон и сообщений; для временных папок архивов
procedure FarDeleteTree(const ADir: WideString);
var
  ShellOp: TFarShFileOp;
  FromList: WideString;
begin
  FromList := ADir;
  if (FromList <> '') and (FromList[Length(FromList)] = '\') then
    SetLength(FromList, Length(FromList) - 1);
  if (FromList = '') or not FarDirExists(FromList) then
    Exit;
  FromList := FromList + WideChar(#0) + WideChar(#0);
  FillChar(ShellOp, SizeOf(ShellOp), 0);
  ShellOp.Wnd := 0;
  ShellOp.Func := FarFoDelete;
  ShellOp.From := PWideChar(FromList);
  ShellOp.Dest := nil;
  ShellOp.Flags := FarFofNoConfirmation or FarFofSilent or FarFofNoErrorUI;
  FarShFileOperation(ShellOp);
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
// 'D:\a\' -> 'D:\a' (корень 'D:\' - как есть) - для сообщений
function FarStripSlash(const APath: WideString): WideString;
begin
  Result := APath;
  if (Length(Result) > 3) and (Result[Length(Result)] = '\') then
    SetLength(Result, Length(Result) - 1);
end;

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

// Имя для вставки в строку: с пробелом - в кавычках
function FarQuoteName(const AName: WideString): WideString;
var
  CharIndex: Integer;
begin
  Result := AName;
  for CharIndex := 1 to Length(AName) do
    if AName[CharIndex] = ' ' then
    begin
      Result := WideString('"') + AName + WideString('"');
      Exit;
    end;
end;

// Текст в буфер обмена (CF_UNICODETEXT; CF_TEXT Windows сделает сама)
function FarCopyToClipboard(AOwnerWnd: HWND; const AText: WideString): Boolean;
var
  MemHandle: HGLOBAL;
  MemData: PWideChar;
  ByteLen: Integer;
begin
  Result := False;
  ByteLen := (Length(AText) + 1) * SizeOf(WideChar);
  MemHandle := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, ByteLen);
  if MemHandle = 0 then
    Exit;
  MemData := GlobalLock(MemHandle);
  if MemData = nil then
  begin
    GlobalFree(MemHandle);
    Exit;
  end;
  if AText <> '' then
    Move(AText[1], MemData^, ByteLen - SizeOf(WideChar));
  MemData[Length(AText)] := #0;
  GlobalUnlock(MemHandle);
  // Память после SetClipboardData - буфера обмена. Окно-владелец нужно:
  // при OpenClipboard(0) SetClipboardData может не сработать
  if OpenClipboard(AOwnerWnd) then
  begin
    EmptyClipboard;
    Result := SetClipboardData(CF_UNICODETEXT, MemHandle) <> 0;
    CloseClipboard;
  end;
  if not Result then
    GlobalFree(MemHandle);
end;

// В буфере обмена есть текст
function FarClipboardHasText: Boolean;
begin
  Result := IsClipboardFormatAvailable(CF_UNICODETEXT) or
    IsClipboardFormatAvailable(CF_TEXT);
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
// Текст в кодировке Windows без замен; False - есть символы вне неё
function FarWideToAnsi(const AText: WideString; var AResult: string): Boolean;
var
  UsedDefault: BOOL;
  Buffer: string;
  Written: Integer;
begin
  Result := False;
  AResult := '';
  if AText = '' then
  begin
    Result := True;
    Exit;
  end;
  SetLength(Buffer, Length(AText) * 2 + 1);
  UsedDefault := False;
  Written := FarWideToMulti(CP_ACP, FarNoBestFit, PWideChar(AText),
    Length(AText), PAnsiChar(Buffer), Length(Buffer), nil, UsedDefault);
  if (Written > 0) and not UsedDefault then
  begin
    AResult := Copy(Buffer, 1, Written);
    Result := True;
  end;
end;

function FarToAnsiPath(const APath: WideString): string;
var
  ShortBuffer: array[0..MAX_PATH] of WideChar;
  ShortLen: DWORD;
  ShortPath: WideString;
begin
  Result := '';
  if APath = '' then
    Exit;
  if FarWideToAnsi(APath, Result) then
    Exit;
  ShortLen := FarGetShortPath(PWideChar(APath), ShortBuffer, MAX_PATH + 1);
  if (ShortLen = 0) or (ShortLen > MAX_PATH) then
  begin
    Result := '';
    Exit;
  end;
  ShortPath := PWideChar(@ShortBuffer[0]);
  if not FarWideToAnsi(ShortPath, Result) then
    Result := '';
end;

// ---------------------------------------------------------------------------
//  Раскраска файлов
// ---------------------------------------------------------------------------

const
  FarColorsSection = 'FarColors';

// #RRGGBB <-> TColor ($00BBGGRR)
function FarColorToText(AColor: TColor): string;
var
  RgbValue: Longint;
begin
  if AColor = clNone then
  begin
    Result := '-';
    Exit;
  end;
  RgbValue := ColorToRGB(AColor);
  Result := '#' + IntToHex(GetRValue(RgbValue), 2) +
    IntToHex(GetGValue(RgbValue), 2) + IntToHex(GetBValue(RgbValue), 2);
end;

function FarTextToColor(const AText: string; ADefault: TColor): TColor;
var
  Text: string;
  Value: Integer;
begin
  Result := ADefault;
  Text := Trim(AText);
  if Text = '-' then
  begin
    Result := clNone;
    Exit;
  end;
  if (Length(Text) <> 7) or (Text[1] <> '#') then
    Exit;
  Value := StrToIntDef('$' + Copy(Text, 2, 6), -1);
  if Value < 0 then
    Exit;
  Result := RGB((Value shr 16) and $FF, (Value shr 8) and $FF, Value and $FF);
end;

function FarNormalizeExt(const AText: string): string;
var
  CharIndex: Integer;
begin
  Result := LowerCase(Trim(AText));
  if Copy(Result, 1, 2) = '*.' then
    Delete(Result, 1, 2);
  while (Result <> '') and (Result[1] = '.') do
    Delete(Result, 1, 1);
  for CharIndex := 1 to Length(Result) do
    if Result[CharIndex] in ['\', '/', ':', '*', '?', '"', '<', '>', '|',
       ' ', ',', '=', '[', ']', ';'] then
    begin
      Result := '';
      Exit;
    end;
end;

procedure FarCopyRules(const ASource: TFarColorRules;
  var ADest: TFarColorRules);
var
  RuleIndex: Integer;
begin
  SetLength(ADest, Length(ASource));
  for RuleIndex := 0 to High(ASource) do
    ADest[RuleIndex] := ASource[RuleIndex];
end;

// ---------------------------------------------------------------------------
//  Палитра окна FAR (F9 - Options - Colors)
// ---------------------------------------------------------------------------

const
  FarPaletteSection = 'FarPalette';
  // Недоступные пункты меню: в палитре FAR - тёмно-серый, на бирюзовом
  // фоне его не видно; по умолчанию - чёрный
  FarMenuDisabledColor = $000000;

  FarPalKeys: array[TFarPalItem] of string = (
    'PanelBack', 'PanelText', 'PanelDir', 'PanelSelected', 'PanelHeader',
    'PanelFrame', 'PanelCursorBack', 'PanelCursorText',
    'MenuBack', 'MenuText', 'MenuHotkey', 'MenuDisabled', 'MenuFrame',
    'MenuCursorBack',
    'DialogBack', 'DialogText', 'DialogFocusBack', 'DialogFocusText',
    'DialogEditBack', 'DialogEditText', 'DialogSelBack', 'DialogSelText',
    'WarnBack', 'WarnText', 'WarnFocusBack', 'WarnFocusText',
    'KeyNum', 'KeyNumBack', 'KeyText', 'KeyBack',
    'CmdBack', 'CmdPrompt', 'CmdText', 'OutText',
    'EditBack', 'EditText', 'EditTitleBack', 'EditTitleText', 'EditSelBack',
    'EditSelText');

  FarPalGroups: array[TFarPalItem] of string = (
    'Панели', 'Панели', 'Панели', 'Панели', 'Панели',
    'Панели', 'Панели', 'Панели',
    'Меню', 'Меню', 'Меню', 'Меню', 'Меню',
    'Меню',
    'Диалоги', 'Диалоги', 'Диалоги', 'Диалоги',
    'Диалоги', 'Диалоги', 'Диалоги', 'Диалоги',
    'Предупреждения', 'Предупреждения', 'Предупреждения', 'Предупреждения',
    'Кейбар', 'Кейбар', 'Кейбар', 'Кейбар',
    'Командная строка', 'Командная строка', 'Командная строка',
    'Командная строка',
    'Редактор', 'Редактор', 'Редактор', 'Редактор', 'Редактор', 'Редактор');

  FarPalCaptions: array[TFarPalItem] of string = (
    'Фон панели',
    'Файлы, строка о файле, итоги',
    'Папки',
    'Выделенные файлы',
    'Заголовки колонок',
    'Рамка',
    'Курсор, заголовок активной панели: фон',
    'Курсор, заголовок активной панели: текст',
    'Фон меню',
    'Пункты',
    'Буква-клавиша, стрелки прокрутки',
    'Недоступные пункты, сведения',
    'Рамка и заголовок',
    'Курсор: фон',
    'Фон окна',
    'Текст и рамка',
    'Кнопка с фокусом, курсор списка: фон',
    'Кнопка с фокусом, курсор списка: текст',
    'Поле ввода: фон',
    'Поле ввода: текст, каретка',
    'Выделенный текст, флажок с фокусом: фон',
    'Выделенный текст, флажок с фокусом: текст',
    'Фон окна',
    'Текст и рамка',
    'Кнопка с фокусом: фон',
    'Кнопка с фокусом: текст',
    'Номер клавиши',
    'Номер клавиши: фон',
    'Подпись клавиши',
    'Подпись клавиши: фон',
    'Фон (и вывод команд)',
    'Путь (приглашение), каретка',
    'Текст команды',
    'Вывод команд',
    'Фон текста (нет - из схемы)',
    'Текст (нет - из схемы)',
    'Строка заголовка: фон',
    'Строка заголовка: текст',
    'Выделенный текст: фон',
    'Выделенный текст: текст');

  FarPalDefaults: array[TFarPalItem] of TColor = (
    FarBlue, FarLightCyan, FarWhite, FarYellow, FarYellow,
    FarLightCyan, FarCyan, FarBlack,
    FarCyan, FarWhite, FarYellow, FarMenuDisabledColor, FarWhite,
    FarBlack,
    FarLightGray, FarBlack, FarCyan, FarBlack,
    FarCyan, FarBlack, FarBlack, FarWhite,
    FarRed, FarWhite, FarLightGray, FarBlack,
    FarLightGray, FarBlack, FarBlack, FarCyan,
    FarBlack, FarLightGray, FarWhite, FarLightGray,
    clNone, clNone, FarCyan, FarBlack, FarCyan, FarBlack);

  FarPalBacks: array[TFarPalItem] of Boolean = (
    True, False, False, False, False,
    False, True, False,
    True, False, False, False, False,
    True,
    True, False, True, False,
    True, False, True, False,
    True, False, True, False,
    False, True, False, True,
    True, False, False, False,
    True, False, True, False, True, False);

  FarPalPairs: array[TFarPalItem] of TFarPalItem = (
    fpPanelText, fpPanelBack, fpPanelBack, fpPanelBack, fpPanelBack,
    fpPanelBack, fpPanelCursorText, fpPanelCursorBack,
    fpMenuText, fpMenuBack, fpMenuBack, fpMenuBack, fpMenuBack,
    fpMenuText,
    fpDlgText, fpDlgBack, fpDlgFocusText, fpDlgFocusBack,
    fpDlgEditText, fpDlgEditBack, fpDlgSelText, fpDlgSelBack,
    fpWarnText, fpWarnBack, fpWarnFocusText, fpWarnFocusBack,
    fpKeyNumBack, fpKeyNum, fpKeyBack, fpKeyText,
    fpCmdText, fpCmdBack, fpCmdBack, fpCmdBack,
    fpEditText, fpEditBack, fpEditTitleText, fpEditTitleBack, fpEditSelText,
    fpEditSelBack);

var
  FarCurPanelBack: TColor = FarBlue;

function FarPalKey(AItem: TFarPalItem): string;
begin
  Result := FarPalKeys[AItem];
end;

function FarPalGroup(AItem: TFarPalItem): string;
begin
  Result := FarPalGroups[AItem];
end;

function FarPalCaption(AItem: TFarPalItem): string;
begin
  Result := FarPalCaptions[AItem];
end;

function FarPalDefault(AItem: TFarPalItem): TColor;
begin
  Result := FarPalDefaults[AItem];
end;

function FarPalIsBack(AItem: TFarPalItem): Boolean;
begin
  Result := FarPalBacks[AItem];
end;

function FarPalPair(AItem: TFarPalItem): TFarPalItem;
begin
  Result := FarPalPairs[AItem];
end;

function FarPanelBackColor: TColor;
begin
  Result := FarCurPanelBack;
end;

const
  // 16 цветов консоли (TColor - $00BBGGRR) в порядке номеров консоли:
  // свои цвета окна выбора цвета по умолчанию, цвета fgindex / bgindex
  // в .farconfig
  FarConColors: array[0..15] of TColor = (
    $000000, $800000, $008000, $808000, $000080, $800080, $008080, $C0C0C0,
    $808080, $FF0000, $00FF00, $FFFF00, $0000FF, $FF00FF, $00FFFF, $FFFFFF);
  // Поля окна правила раскраски (FPickFocus)
  pfExt = 0;
  pfFore = 1;
  pfBack = 2;
  pfPanel = 3;
  pfBtn = 4;                 // pfBtn + номер кнопки (OK, Cancel)

  // Темы (F9 - Options - Themes): 0 - Classic (FarPalDefaults), дальше -
  // палитры по темам FarDark 2026 и FarLight 2026 из github.com/diakin/
  // theming-far (ключи .farconfig -> элементы палитры - FarThemeKeys).
  // Курсор панели (и меню у светлой) - заметнее, чем в оригинале: там он
  // почти цвета фона. Цвета текста и фона редактора - из схемы (clNone)
  FarThemeCount = 3;
  FarThemeNames: array[0..FarThemeCount - 1] of string = ('Classic',
    'FarDark 2026', 'FarLight 2026');
  FarThemePalettes: array[1..2] of TFarPalette = (
    // FarDark 2026
    (
      $001F1F1F, $00CCCCCC, $00FFC14F, $008484FF, $00FFC14F,
      $006E6E6E, $00714709, $00CCCCCC, $001F1F1F, $00CCCCCC,
      $00FFC14F, $006E6E6E, $00CCCCCC, $00714709, $00252525,
      $00CCCCCC, $00D47800, $00FFFFFF, $001F1F1F, $00CCCCCC,
      $00784F26, $00CCCCCC, $001F1F6F, $00FFFFFF, $00CCCCCC,
      $001F1F6F, $006E6E6E, $00252525, $00CCCCCC, $00252525,
      $001F1F1F, $00FFC14F, $00CCCCCC, $00CCCCCC, clNone,
      clNone, $00D47800, $00FFFFFF, $00784F26, $00CCCCCC),
    // FarLight 2026
    (
      $00FFFFFF, $003B3B3B, $00B85F00, $000D26A1, $00B85F00,
      $00B0B0B0, $00F7E4CC, $003B3B3B, $00FFFFFF, $003B3B3B,
      $00B85F00, $00A0A0A0, $003B3B3B, $00F7E4CC, $00F8F8F8,
      $003B3B3B, $00B85F00, $00FFFFFF, $00FFFFFF, $003B3B3B,
      $00FFD6AD, $003B3B3B, $000D26A1, $00FFFFFF, $00FFFFFF,
      $000D26A1, $007E7E7E, $00F8F8F8, $003B3B3B, $00F8F8F8,
      $00FFFFFF, $00B85F00, $003B3B3B, $003B3B3B, clNone,
      clNone, $00B85F00, $00FFFFFF, $00FFD6AD, $003B3B3B));
  FarThemeKeys: array[TFarPalItem] of string = (
    'Panel.Text', 'Panel.Text', 'Panel.Text.Highlight',
    'Panel.Text.Selected', 'Panel.Title.Column', 'Panel.Box',
    'Panel.Cursor', 'Panel.Cursor', 'Menu.Text',
    'Menu.Text', 'Menu.Highlight', 'Menu.Text.Disabled',
    'Menu.Box', 'Menu.Text.Selected', 'Dialog.Text',
    'Dialog.Text', 'Dialog.Button.Selected', 'Dialog.Button.Selected',
    'Dialog.Edit', 'Dialog.Edit', 'Dialog.Edit.Selected',
    'Dialog.Edit.Selected', 'WarnDialog.Text', 'WarnDialog.Text',
    'WarnDialog.Button.Selected', 'WarnDialog.Button.Selected', 'Keybar.Num',
    'Keybar.Num', 'Keybar.Text', 'Keybar.Text',
    'CommandLine', 'CommandLine.Prefix', 'CommandLine',
    'CommandLine.UserScreen', '', '',
    'Editor.Status', 'Editor.Status', 'Editor.Text.Selected',
    'Editor.Text.Selected');
  FarThemeBackKey: array[TFarPalItem] of Boolean = (
    True, False, False, False, False, False, True, False,
    True, False, False, False, False, True, True, False,
    True, False, True, False, True, False, True, False,
    True, False, False, True, False, True, True, False,
    False, False, False, False, True, False, True, False);
  FarThemeSection = 'FarTheme';

// Смесь цветов: AShare (0..100) процентов ATo в AFrom
function FarBlend(AFrom, ATo: TColor; AShare: Integer): TColor;
var
  FromRgb, ToRgb: Longint;
begin
  FromRgb := ColorToRGB(AFrom);
  ToRgb := ColorToRGB(ATo);
  Result := RGB(
    (GetRValue(FromRgb) * (100 - AShare) + GetRValue(ToRgb) * AShare) div 100,
    (GetGValue(FromRgb) * (100 - AShare) + GetGValue(ToRgb) * AShare) div 100,
    (GetBValue(FromRgb) * (100 - AShare) + GetBValue(ToRgb) * AShare) div 100);
end;

// Яркость 0..255
function FarLuma(AColor: TColor): Integer;
var
  RgbValue: Longint;
begin
  RgbValue := ColorToRGB(AColor);
  Result := (GetRValue(RgbValue) * 299 + GetGValue(RgbValue) * 587 +
    GetBValue(RgbValue) * 114) div 1000;
end;

// Цвет текста AFore на фоне ABack, читаемый: мало отличается по яркости -
// темнее на светлом фоне, светлее на тёмном (правила раскраски, сделанные
// под синий фон, - на светлой и тёмной темах)
function FarReadable(AFore, ABack: TColor): TColor;
begin
  Result := AFore;
  if (AFore = clNone) or (ABack = clNone) then
    Exit;
  if Abs(FarLuma(AFore) - FarLuma(ABack)) >= 90 then
    Exit;
  if FarLuma(ABack) > 128 then
    Result := FarBlend(AFore, FarBlack, 60)
  else
    Result := FarBlend(AFore, FarWhite, 60);
end;

function FarThemePalette(AIndex: Integer; var APalette: TFarPalette): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FarThemeCount);
  if not Result then
    Exit;
  if AIndex = 0 then
    FarPaletteDefault(APalette)
  else
    APalette := FarThemePalettes[AIndex];
end;

// Атрибут AName="..." в теге ATag; нет - пусто
function FarXmlAttr(const ATag, AName: string): string;
var
  AttrPos, EndPos: Integer;
  Rest: string;
begin
  Result := '';
  AttrPos := Pos(' ' + AName + '="', ATag);
  if AttrPos = 0 then
    Exit;
  Rest := Copy(ATag, AttrPos + Length(AName) + 3, MaxInt);
  EndPos := Pos('"', Rest);
  if EndPos > 0 then
    Result := Copy(Rest, 1, EndPos - 1);
end;

// Цвет .farconfig: AARRGGBB; с AIndexed - номер цвета консоли в младшем
// байте ($80 - «по умолчанию хоста»: нет цвета). False - не разобрать
function FarConfigColor(const AText: string; AIndexed: Boolean;
  var AColor: TColor): Boolean;
var
  Value: Int64;
begin
  Result := False;
  if Length(AText) <> 8 then
    Exit;
  Value := StrToInt64Def('$' + AText, -1);
  if Value < 0 then
    Exit;
  if AIndexed then
  begin
    if (Value and $FF) > 15 then
      Exit;
    AColor := FarConColors[Value and $FF];
  end
  else
    AColor := RGB((Value shr 16) and $FF, (Value shr 8) and $FF,
      Value and $FF);
  Result := True;
end;

function FarPaletteFromFarconfig(const AFileName: WideString;
  var APalette: TFarPalette; var AError: string): Boolean;
var
  FileHandle: THandle;
  FileSize, ReadCount: DWORD;
  Text, Tag, Name, Flags, Value: string;
  Tags: TStringList;
  StartPos, EndPos, Mapped: Integer;
  Item: TFarPalItem;
  Color: TColor;
  IsBack: Boolean;
begin
  Result := False;
  AError := '';
  FileHandle := FarCreateFile(PWideChar(AFileName), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  if FileHandle = INVALID_HANDLE_VALUE then
  begin
    AError := SysErrorMessage(GetLastError);
    Exit;
  end;
  try
    FileSize := GetFileSize(FileHandle, nil);
    if (FileSize = $FFFFFFFF) or (FileSize > 4 * 1024 * 1024) then
    begin
      AError := 'файл не прочитать или он больше 4 МБ';
      Exit;
    end;
    SetLength(Text, FileSize);
    ReadCount := 0;
    if (FileSize > 0) and (not ReadFile(FileHandle, Text[1], FileSize,
       ReadCount, nil) or (ReadCount <> FileSize)) then
    begin
      AError := SysErrorMessage(GetLastError);
      Exit;
    end;
  finally
    CloseHandle(FileHandle);
  end;
  // Теги <object name=... background=... foreground=... flags=...>
  Tags := TStringList.Create;
  try
    StartPos := Pos('<object ', Text);
    while StartPos > 0 do
    begin
      Text := Copy(Text, StartPos, MaxInt);
      EndPos := Pos('>', Text);
      if EndPos = 0 then
        Break;
      Tag := StringReplace(Copy(Text, 1, EndPos), #9, ' ', [rfReplaceAll]);
      Tag := StringReplace(StringReplace(Tag, #13, ' ', [rfReplaceAll]), #10,
        ' ', [rfReplaceAll]);
      Name := FarXmlAttr(Tag, 'name');
      if Name <> '' then
        Tags.Values[Name] := Tag;
      Text := Copy(Text, EndPos + 1, MaxInt);
      StartPos := Pos('<object ', Text);
    end;
    Mapped := 0;
    for Item := Low(TFarPalItem) to High(TFarPalItem) do
    begin
      if FarThemeKeys[Item] = '' then
        Continue;
      Tag := Tags.Values[FarThemeKeys[Item]];
      if Tag = '' then
        Continue;
      IsBack := FarThemeBackKey[Item];
      Flags := ' ' + FarXmlAttr(Tag, 'flags') + ' ';
      if IsBack then
      begin
        Value := FarXmlAttr(Tag, 'background');
        if FarConfigColor(Value, Pos(' bgindex ', Flags) > 0, Color) then
        begin
          APalette[Item] := Color;
          Inc(Mapped);
        end;
      end
      else
      begin
        Value := FarXmlAttr(Tag, 'foreground');
        if FarConfigColor(Value, Pos(' fgindex ', Flags) > 0, Color) then
        begin
          APalette[Item] := Color;
          Inc(Mapped);
        end;
      end;
    end;
  finally
    Tags.Free;
  end;
  if Mapped = 0 then
  begin
    AError := 'в файле нет цветов FAR (<object name="Panel.Text" ...>)';
    Exit;
  end;
  Result := True;
end;

// ---------------------------------------------------------------------------
//  Окно выбора цвета Windows (ChooseColorW) в цветах палитры FAR: фон и
//  текст окна - цвета диалогов, кнопки рисуются сами (BS_OWNERDRAW). На
//  тёмной теме окно тёмное. Заголовок окна (рамка Windows) - как в системе
// ---------------------------------------------------------------------------

type
  TFarChooseColor = record
    lStructSize: DWORD;
    hWndOwner: HWND;
    hInstance: HWND;
    rgbResult: COLORREF;
    lpCustColors: Pointer;
    Flags: DWORD;
    lCustData: LPARAM;
    lpfnHook: Pointer;
    lpTemplateName: PWideChar;
  end;

  TFarOpenFileName = record
    lStructSize: DWORD;
    hWndOwner: HWND;
    hInstance: HINST;
    lpstrFilter: PWideChar;
    lpstrCustomFilter: PWideChar;
    nMaxCustFilter: DWORD;
    nFilterIndex: DWORD;
    lpstrFile: PWideChar;
    nMaxFile: DWORD;
    lpstrFileTitle: PWideChar;
    nMaxFileTitle: DWORD;
    lpstrInitialDir: PWideChar;
    lpstrTitle: PWideChar;
    Flags: DWORD;
    nFileOffset: Word;
    nFileExtension: Word;
    lpstrDefExt: PWideChar;
    lCustData: LPARAM;
    lpfnHook: Pointer;
    lpTemplateName: PWideChar;
  end;

const
  FarCcRgbInit = $0001;        // CC_RGBINIT
  FarCcFullOpen = $0002;       // CC_FULLOPEN
  FarCcEnableHook = $0010;     // CC_ENABLEHOOK
  FarCcAnyColor = $0100;       // CC_ANYCOLOR
  FarBsTypeMask = $000F;
  FarBsOwnerDraw = $000B;
  FarOfnFileMustExist = $1000;
  FarOfnPathMustExist = $0800;
  FarOfnHideReadOnly = $0004;
  FarOfnNoChangeDir = $0008;

function FarChooseColorW(var AChoose: TFarChooseColor): BOOL; stdcall;
  external 'comdlg32.dll' name 'ChooseColorW';
function FarGetOpenFileNameW(var AOpen: TFarOpenFileName): BOOL; stdcall;
  external 'comdlg32.dll' name 'GetOpenFileNameW';
function FarEnumChildWindows(AParent: HWND; AFunc: Pointer;
  AParam: LPARAM): BOOL; stdcall; external 'user32.dll' name 'EnumChildWindows';
function FarGetClassNameW(AWnd: HWND; AName: PWideChar;
  AMax: Integer): Integer; stdcall; external 'user32.dll' name 'GetClassNameW';
function FarGetWindowTextW(AWnd: HWND; AText: PWideChar;
  AMax: Integer): Integer; stdcall; external 'user32.dll' name 'GetWindowTextW';
function FarSetWindowTextW(AWnd: HWND; AText: PWideChar): BOOL; stdcall;
  external 'user32.dll' name 'SetWindowTextW';
function FarDrawTextW(ADC: HDC; AText: PWideChar; ACount: Integer;
  ARect: PRect; AFormat: UINT): Integer; stdcall;
  external 'user32.dll' name 'DrawTextW';

var
  // Цвета окна выбора цвета (на время ChooseColor)
  FarCcBack, FarCcText, FarCcEditBack, FarCcEditText: TColor;
  FarCcBtnBack, FarCcBtnFocus, FarCcBtnFocusText: TColor;
  FarCcBackBrush: HBRUSH = 0;
  FarCcEditBrush: HBRUSH = 0;
  FarCcTitle: WideString = '';

// Кнопки окна - рисуются сами
function FarCcEnumChild(AWnd: HWND; AParam: LPARAM): BOOL; stdcall;
var
  ClassName: array[0..31] of WideChar;
  Style: Longint;
begin
  Result := True;
  if FarGetClassNameW(AWnd, ClassName, 32) = 0 then
    Exit;
  if WideString(ClassName) <> 'Button' then
    Exit;
  Style := GetWindowLong(AWnd, GWL_STYLE);
  if (Style and FarBsTypeMask = BS_PUSHBUTTON) or
     (Style and FarBsTypeMask = BS_DEFPUSHBUTTON) then
  begin
    SetWindowLong(AWnd, GWL_STYLE, (Style and not FarBsTypeMask) or
      FarBsOwnerDraw);
    InvalidateRect(AWnd, nil, True);
  end;
end;

procedure FarCcDrawButton(ADraw: PDrawItemStruct);
var
  Caption: array[0..127] of WideChar;
  TextLen: Integer;
  ItemRect: TRect;
  Back, Fore: TColor;
  Brush: HBRUSH;
  Pen, OldPen: HGDIOBJ;
  OldBrush: HGDIOBJ;
begin
  // Поля по одному: TRect у Delphi 7 и Free Pascal объявлен в разных модулях
  ItemRect.Left := ADraw^.rcItem.Left;
  ItemRect.Top := ADraw^.rcItem.Top;
  ItemRect.Right := ADraw^.rcItem.Right;
  ItemRect.Bottom := ADraw^.rcItem.Bottom;
  if (ADraw^.itemState and ODS_FOCUS) <> 0 then
  begin
    Back := FarCcBtnFocus;
    Fore := FarCcBtnFocusText;
  end
  else
  begin
    Back := FarCcBtnBack;
    Fore := FarCcText;
  end;
  if (ADraw^.itemState and ODS_DISABLED) <> 0 then
    Fore := FarBlend(Fore, Back, 50);
  Brush := CreateSolidBrush(ColorToRGB(Back));
  Pen := CreatePen(PS_SOLID, 1, ColorToRGB(FarBlend(Back, FarCcText, 40)));
  OldPen := SelectObject(ADraw^.hDC, Pen);
  OldBrush := SelectObject(ADraw^.hDC, Brush);
  Windows.Rectangle(ADraw^.hDC, ItemRect.Left, ItemRect.Top, ItemRect.Right,
    ItemRect.Bottom);
  SelectObject(ADraw^.hDC, OldPen);
  SelectObject(ADraw^.hDC, OldBrush);
  DeleteObject(Pen);
  DeleteObject(Brush);
  TextLen := FarGetWindowTextW(ADraw^.hwndItem, Caption, 128);
  if (ADraw^.itemState and ODS_SELECTED) <> 0 then
  begin
    Inc(ItemRect.Left);
    Inc(ItemRect.Top);
    Inc(ItemRect.Right);
    Inc(ItemRect.Bottom);
  end;
  SetBkMode(ADraw^.hDC, TRANSPARENT);
  SetTextColor(ADraw^.hDC, ColorToRGB(Fore));
  FarDrawTextW(ADraw^.hDC, Caption, TextLen, @ItemRect,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

function FarCcHook(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
begin
  Result := 0;
  case AMsg of
    WM_INITDIALOG:
      begin
        if FarCcTitle <> '' then
          FarSetWindowTextW(AWnd, PWideChar(FarCcTitle));
        FarEnumChildWindows(AWnd, @FarCcEnumChild, 0);
      end;
    WM_CTLCOLORDLG, WM_CTLCOLORSTATIC, WM_CTLCOLORBTN:
      begin
        SetTextColor(HDC(AWParam), ColorToRGB(FarCcText));
        SetBkColor(HDC(AWParam), ColorToRGB(FarCcBack));
        Result := LRESULT(FarCcBackBrush);
      end;
    WM_CTLCOLOREDIT:
      begin
        SetTextColor(HDC(AWParam), ColorToRGB(FarCcEditText));
        SetBkColor(HDC(AWParam), ColorToRGB(FarCcEditBack));
        Result := LRESULT(FarCcEditBrush);
      end;
    WM_DRAWITEM:
      if PDrawItemStruct(ALParam)^.CtlType = ODT_BUTTON then
      begin
        FarCcDrawButton(PDrawItemStruct(ALParam));
        Result := 1;
      end;
  end;
end;

// Номер группы палитры, где элемент AItem
function FarPalGroupIndex(AItem: TFarPalItem): Integer;
var
  Item: TFarPalItem;
  GroupName: string;
begin
  Result := -1;
  GroupName := '';
  for Item := Low(TFarPalItem) to AItem do
    if FarPalGroup(Item) <> GroupName then
    begin
      GroupName := FarPalGroup(Item);
      Inc(Result);
    end;
end;

procedure FarPaletteDefault(var APalette: TFarPalette);
var
  Item: TFarPalItem;
begin
  for Item := Low(TFarPalItem) to High(TFarPalItem) do
    APalette[Item] := FarPalDefaults[Item];
end;

procedure FarPaletteLoad(const AIniName: string; var APalette: TFarPalette);
var
  Ini: TBufIniFile;
  Item: TFarPalItem;
  Color: TColor;
begin
  FarPaletteDefault(APalette);
  if (AIniName = '') or not FileExists(AIniName) then
    Exit;
  Ini := TBufIniFile.Create(AIniName);
  try
    for Item := Low(TFarPalItem) to High(TFarPalItem) do
    begin
      // '-' (clNone) - только у элементов, где «нет» - стандартное значение
      // (цвета редактора: нет - из схемы); у остальных - стандартный цвет
      Color := FarTextToColor(Ini.ReadString(FarPaletteSection,
        FarPalKeys[Item], ''), FarPalDefaults[Item]);
      if (Color <> clNone) or (FarPalDefaults[Item] = clNone) then
        APalette[Item] := Color;
    end;
  finally
    Ini.Free;
  end;
end;

procedure FarPaletteSave(const AIniName: string; const APalette: TFarPalette);
var
  Ini: TBufIniFile;
  Item: TFarPalItem;
begin
  Ini := TBufIniFile.Create(AIniName);
  try
    Ini.EraseSection(FarPaletteSection);
    for Item := Low(TFarPalItem) to High(TFarPalItem) do
      Ini.WriteString(FarPaletteSection, FarPalKeys[Item],
        FarColorToText(APalette[Item]));
  finally
    Ini.Free;
  end;
end;

// Стандартный набор: группы расширений с цветом текста и фона (#RRGGBB,
// '-' - фон панели). Цвета подобраны под синий фон панелей FAR.
procedure FarColorsDefault(var ARules: TFarColorRules);
const
  GroupCount = 17;
  GroupExts: array[0..GroupCount - 1] of string = (
    'exe com bat cmd msi',                     // программы
    'dll ocx sys bpl drv',                     // библиотеки
    'zip rar 7z arj cab gz tar bz2 xz lzh iso',// архивы
    'doc docx rtf odt',                        // документы
    'pdf djvu',                                // PDF
    'xls xlsx ods csv',                        // таблицы
    'pas dpr dpk inc',                         // Delphi
    'dfm lfm',                                 // формы
    'bas bi frm',                              // Basic (RapidQ, FreeBASIC)
    'c cpp h hpp ino',                         // C / C++ / Arduino
    'htm html css js xml json',                // веб
    'txt log md ini cfg',                      // текст
    'png jpg jpeg bmp gif ico tif svg',        // картинки
    'mp3 wav mp4 avi mkv',                     // звук и видео
    'res rc',                                  // ресурсы
    'dcu obj o bak tmp dsk ddp map drc',       // промежуточные
    'mnb spl7 spl');                           // схемы и прочие проекты
  GroupFore: array[0..GroupCount - 1] of string = (
    '#55FF55', '#40C040', '#FF66FF', '#FFA0A0', '#FFFFFF', '#80FFC0',
    '#FFFF80', '#FFD080', '#FF9A40', '#C0A0FF', '#60E0FF', '#E0E0E0',
    '#FFD700', '#FF80C0', '#A0C8FF', '#8080A0', '#FFFFFF');
  GroupBack: array[0..GroupCount - 1] of string = (
    '-', '-', '-', '-', '#A01010', '-',
    '-', '-', '-', '-', '-', '-',
    '-', '-', '-', '-', '#207020');
var
  GroupIndex, RuleCount, SpacePos: Integer;
  Exts, OneExt: string;
begin
  SetLength(ARules, 0);
  RuleCount := 0;
  for GroupIndex := 0 to GroupCount - 1 do
  begin
    Exts := GroupExts[GroupIndex] + ' ';
    while Exts <> '' do
    begin
      SpacePos := Pos(' ', Exts);
      OneExt := Copy(Exts, 1, SpacePos - 1);
      Delete(Exts, 1, SpacePos);
      if OneExt = '' then
        Continue;
      SetLength(ARules, RuleCount + 1);
      ARules[RuleCount].Ext := OneExt;
      ARules[RuleCount].Enabled := True;
      ARules[RuleCount].Fore := FarTextToColor(GroupFore[GroupIndex], clWhite);
      ARules[RuleCount].Back := FarTextToColor(GroupBack[GroupIndex], clNone);
      Inc(RuleCount);
    end;
  end;
end;

procedure FarColorsLoad(const AIniName: string; var ARules: TFarColorRules);
var
  Ini: TBufIniFile;
  Keys: TStringList;
  KeyIndex, RuleCount, CommaPos: Integer;
  Value, Part, Ext: string;
begin
  Ini := TBufIniFile.Create(AIniName);
  Keys := TStringList.Create;
  try
    if Ini.ReadString(FarColorsSection, '_Set', '') <> '1' then
    begin
      FarColorsDefault(ARules);
      Exit;
    end;
    Ini.ReadSection(FarColorsSection, Keys);
    SetLength(ARules, 0);
    RuleCount := 0;
    for KeyIndex := 0 to Keys.Count - 1 do
    begin
      if (Keys[KeyIndex] = '') or (Keys[KeyIndex][1] = '_') then
        Continue;
      Ext := FarNormalizeExt(Keys[KeyIndex]);
      if Ext = '' then
        Continue;
      Value := Ini.ReadString(FarColorsSection, Keys[KeyIndex], '') + ',';
      SetLength(ARules, RuleCount + 1);
      ARules[RuleCount].Ext := Ext;
      // вкл
      CommaPos := Pos(',', Value);
      Part := Trim(Copy(Value, 1, CommaPos - 1));
      Delete(Value, 1, CommaPos);
      ARules[RuleCount].Enabled := Part <> '0';
      // текст
      CommaPos := Pos(',', Value);
      Part := Copy(Value, 1, CommaPos - 1);
      Delete(Value, 1, CommaPos);
      ARules[RuleCount].Fore := FarTextToColor(Part, clWhite);
      if ARules[RuleCount].Fore = clNone then
        ARules[RuleCount].Fore := clWhite;
      // фон
      CommaPos := Pos(',', Value);
      if CommaPos > 0 then
        Part := Copy(Value, 1, CommaPos - 1)
      else
        Part := '-';
      ARules[RuleCount].Back := FarTextToColor(Part, clNone);
      Inc(RuleCount);
    end;
  finally
    Keys.Free;
    Ini.Free;
  end;
end;

procedure FarColorsSave(const AIniName: string; const ARules: TFarColorRules);
var
  Ini: TBufIniFile;
  RuleIndex: Integer;
begin
  Ini := TBufIniFile.Create(AIniName);
  try
    Ini.EraseSection(FarColorsSection);
    Ini.WriteString(FarColorsSection, '_Set', '1');
    for RuleIndex := 0 to High(ARules) do
      if ARules[RuleIndex].Ext <> '' then
        Ini.WriteString(FarColorsSection, ARules[RuleIndex].Ext,
          IntToStr(Ord(ARules[RuleIndex].Enabled)) + ',' +
          FarColorToText(ARules[RuleIndex].Fore) + ',' +
          FarColorToText(ARules[RuleIndex].Back));
  finally
    Ini.Free;
  end;
end;

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
  FFtpMode := 0;
  FFtpHostIdx := -1;
  FFtpConn := nil;
  FFtpSession := 0;
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
      Cmp := -FarFileTimeCmp(ItemA.WriteTime, ItemB.WriteTime);
    fsSize:
      Cmp := -FarCompareInt64(ItemA.Size, ItemB.Size);
    fsUnsorted:
      Cmp := ItemA.OrigIndex - ItemB.OrigIndex;
    fsCreation:
      Cmp := -FarFileTimeCmp(ItemA.CreateTime, ItemB.CreateTime);
    fsAccess:
      Cmp := -FarFileTimeCmp(ItemA.AccessTime, ItemB.AccessTime);
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
  // Обычная папка - архив и FTP (если были) закрыты
  if FFtpMode <> 0 then
    FtpLeave;
  FArcFile := '';
  FArcTitle := '';
  FArcDir := '';
  FArcEntries := nil;
  FArcPassword := '';
  FArcLevels := nil;

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

function TFarPanel.IsArchive: Boolean;
begin
  Result := FArcFile <> '';
end;

function TFarPanel.DisplayPath: WideString;
begin
  if FFtpMode = 1 then
    Result := 'FTP:'
  else if FFtpMode = 2 then
  begin
    Result := FarFtpHostUrl(FFtpHost);
    if (FFtpDir = '') or (FFtpDir[1] <> '/') then
      Result := Result + '/';
    Result := Result + FarFtpDecode(FFtpDir);
  end
  else if FArcFile = '' then
    Result := FPath
  else if FArcDir = '' then
    Result := FArcTitle
  else
    Result := FArcTitle + '\' + FArcDir;
end;

function TFarPanel.ArcInnerPath(const AName: WideString): WideString;
begin
  if FArcDir = '' then
    Result := AName
  else
    Result := FArcDir + '\' + AName;
end;

// Кандидат в список папки архива: имя, явная ли это запись (а не только
// часть пути другой записи), номер записи
type
  TFarArcCandidate = record
    Name: WideString;
    Direct: Boolean;
    EntryIndex: Integer;
  end;

procedure TFarPanel.BuildArcView(const AFocusName: WideString);
var
  Prefix, Rest: WideString;
  Candidates: array of TFarArcCandidate;
  Temp: TFarArcCandidate;
  CandCount, EntryIndex, SlashPos, Gap, Outer, Inner, ItemIndex,
    CandIndex: Integer;
  NewItems: TFarItems;
  NewCount: Integer;
begin
  if FArcDir = '' then
    Prefix := ''
  else
    Prefix := FArcDir + '\';

  // Имена первого уровня под FArcDir: записи самой папки и папки, которые
  // видны только по путям записей глубже
  SetLength(Candidates, 64);
  CandCount := 0;
  for EntryIndex := 0 to High(FArcEntries) do
  begin
    if (Prefix <> '') and
       (Copy(FArcEntries[EntryIndex].Path, 1, Length(Prefix)) <> Prefix) then
      Continue;
    Rest := Copy(FArcEntries[EntryIndex].Path, Length(Prefix) + 1, MaxInt);
    if Rest = '' then
      Continue;
    SlashPos := 1;
    while (SlashPos <= Length(Rest)) and (Rest[SlashPos] <> '\') do
      Inc(SlashPos);
    if CandCount >= Length(Candidates) then
      SetLength(Candidates, Length(Candidates) * 2);
    Candidates[CandCount].Name := Copy(Rest, 1, SlashPos - 1);
    Candidates[CandCount].Direct := SlashPos > Length(Rest);
    Candidates[CandCount].EntryIndex := EntryIndex;
    Inc(CandCount);
  end;

  // По имени (точное сравнение), явная запись - первой из одинаковых
  Gap := CandCount div 2;
  while Gap > 0 do
  begin
    for Outer := Gap to CandCount - 1 do
    begin
      Temp := Candidates[Outer];
      Inner := Outer;
      while (Inner >= Gap) and
            ((Temp.Name < Candidates[Inner - Gap].Name) or
             ((Temp.Name = Candidates[Inner - Gap].Name) and Temp.Direct and
              not Candidates[Inner - Gap].Direct)) do
      begin
        Candidates[Inner] := Candidates[Inner - Gap];
        Dec(Inner, Gap);
      end;
      Candidates[Inner] := Temp;
    end;
    Gap := Gap div 2;
  end;

  SetLength(NewItems, CandCount + 1);
  NewCount := 0;
  // '..' - всегда: в корне архива это выход из него
  NewItems[0].Name := '..';
  NewItems[0].IsUp := True;
  NewItems[0].IsDir := True;
  NewItems[0].Size := 0;
  NewItems[0].Attr := FILE_ATTRIBUTE_DIRECTORY;
  NewItems[0].Selected := False;
  NewItems[0].OrigIndex := -1;
  FillChar(NewItems[0].WriteTime, SizeOf(TFileTime), 0);
  FillChar(NewItems[0].CreateTime, SizeOf(TFileTime), 0);
  FillChar(NewItems[0].AccessTime, SizeOf(TFileTime), 0);
  NewCount := 1;
  CandIndex := 0;
  while CandIndex < CandCount do
  begin
    with Candidates[CandIndex] do
    begin
      ItemIndex := NewCount;
      NewItems[ItemIndex].Name := Name;
      NewItems[ItemIndex].IsUp := False;
      NewItems[ItemIndex].Selected := False;
      NewItems[ItemIndex].OrigIndex := EntryIndex;
      if Direct then
      begin
        NewItems[ItemIndex].IsDir := FArcEntries[EntryIndex].IsDir;
        if NewItems[ItemIndex].IsDir then
          NewItems[ItemIndex].Size := 0
        else
          NewItems[ItemIndex].Size := FArcEntries[EntryIndex].Size;
        NewItems[ItemIndex].WriteTime := FArcEntries[EntryIndex].Time;
      end
      else
      begin
        NewItems[ItemIndex].IsDir := True;
        NewItems[ItemIndex].Size := 0;
        FillChar(NewItems[ItemIndex].WriteTime, SizeOf(TFileTime), 0);
      end;
      if NewItems[ItemIndex].IsDir then
        NewItems[ItemIndex].Attr := FILE_ATTRIBUTE_DIRECTORY
      else
        NewItems[ItemIndex].Attr := 0;
      NewItems[ItemIndex].CreateTime := NewItems[ItemIndex].WriteTime;
      NewItems[ItemIndex].AccessTime := NewItems[ItemIndex].WriteTime;
      Inc(NewCount);
    end;
    // Одинаковые имена - один элемент (первый - явная запись, если есть)
    Inc(CandIndex);
    while (CandIndex < CandCount) and
          (Candidates[CandIndex].Name = NewItems[NewCount - 1].Name) do
    begin
      // Файл с тем же именем, что и папка, - не бывает; а путь глубже
      // делает элемент папкой
      if not Candidates[CandIndex].Direct then
        NewItems[NewCount - 1].IsDir := True;
      Inc(CandIndex);
    end;
  end;

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
  FCursor := 0;
  FTopIndex := 0;
  if AFocusName <> '' then
  begin
    FCursor := IndexOfName(AFocusName);
    if FCursor < 0 then
      FCursor := 0;
  end;
end;

procedure TFarPanel.Reread;
var
  FocusName: WideString;
  SelectedNames: array of WideString;
  SelectedCount, ItemIndex, NameIndex, OldTop, OldCursor: Integer;
  ErrorText: string;
begin
  // FTP перечитывает TFarView (Ctrl+R - запрос к серверу)
  if (FPath = '') or (FFtpMode <> 0) then
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
  // Архив перечитывать нечего - его папка строится заново из записей
  if IsArchive then
    BuildArcView(FocusName)
  else if not ReadDir(FPath, FocusName, ErrorText) then
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
  Color := FPal[fpPanelBack];
  FPanels[0] := TFarPanel.Create;
  FPanels[1] := TFarPanel.Create;
  FActive := 0;
  FarPaletteDefault(FPal);
  FBuffer := TBitmap.Create;
  CreateFonts;
  FDlgKind := fdNone;
  FDlgFocus := -1;
  FSingle := -1;
  FFtpThread[0] := nil;
  FFtpThread[1] := nil;
  FEditor := nil;
  FEditPanel := 1;
  FEditTabSize := 4;
  FFtpEditIdx := -1;
  FFtpPassPanel := -1;
  FFtpDelIdx := -1;
  FWatch[0] := 0;
  FWatch[1] := 0;
  FWatchTimer := TTimer.Create(Self);
  FWatchTimer.Interval := FarWatchInterval;
  FWatchTimer.OnTimer := WatchTick;
  FWatchTimer.Enabled := True;
  FProcTimer := TTimer.Create(Self);
  FProcTimer.Interval := 100;
  FProcTimer.OnTimer := ProcTick;
  FProcTimer.Enabled := False;
  FSzThread := nil;
  FArcAddFormat := 0;
  FArcAddLevel := 3;
  FDlgRow := -1;
  FSzTimer := TTimer.Create(Self);
  FSzTimer.Interval := 200;
  FSzTimer.OnTimer := SzTick;
  FSzTimer.Enabled := False;
  FFindMask := '*.*';
  FFindFolders := True;
  FFindDone := True;
end;

destructor TFarView.Destroy;
var
  TempBuffer: array[0..MAX_PATH] of WideChar;
  TempLen: DWORD;
  FtpIdx: Integer;
begin
  FOnStatus := nil;
  FSzTimer.Enabled := False;
  if FFindTimer <> nil then
    FFindTimer.Enabled := False;
  if FFindThread <> nil then
  begin
    FFindThread.Cancel;
    FFindThread.WaitFor;
    FFindThread.Free;
    FFindThread := nil;
  end;
  if FSzThread <> nil then
  begin
    FSzThread.Cancel;
    FSzThread.WaitFor;
    FSzThread.Free;
    FSzThread := nil;
  end;
  // FTP: запрос прервать (закрыть соединение), соединения панелей закрыть
  for FtpIdx := 0 to 1 do
  begin
    if FFtpThread[FtpIdx] <> nil then
    begin
      FFtpThread[FtpIdx].Cancel;
      FFtpThread[FtpIdx].WaitFor;
      FFtpThread[FtpIdx].Conn.Free;
      FFtpThread[FtpIdx].Free;
      FFtpThread[FtpIdx] := nil;
    end;
    FPanels[FtpIdx].FtpLeave;
  end;
  FProcTimer.Enabled := False;
  if FProcHandle <> 0 then
    ProcFinish(True);
  FArcProgress.Free;
  FArcProgress := nil;
  FreeAndNil(FEditor);
  FreeAndNil(FViewer);
  // Файлы, открытые из архивов (Enter), - %TEMP%\unIDE_far; FAR закрыт -
  // удалить
  TempLen := FarGetTempPath(MAX_PATH + 1, TempBuffer);
  if (TempLen > 0) and (TempLen <= MAX_PATH) then
    FarDeleteTree(FarWithSlash(PWideChar(@TempBuffer[0])) + FarArcTempDir);
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
  // Одна панель (F4): она на всё окно, другой нет
  if FSingle >= 0 then
  begin
    AX0 := 0;
    if AIndex = FSingle then
      AWidth := FCols
    else
      AWidth := 0;
    Exit;
  end;
  if AIndex = 0 then
  begin
    AX0 := 0;
    AWidth := LeftPanelWidth;
  end
  else
  begin
    AX0 := LeftPanelWidth;
    AWidth := FCols - AX0;
  end;
end;

// Ширина левой панели (две панели): половина окна со сдвигом PanelShift;
// у каждой панели - не меньше FarMinPanelCols клеток
const
  FarMinPanelCols = 16;

function TFarView.LeftPanelWidth: Integer;
begin
  Result := FCols div 2;
  if FCols < 2 * FarMinPanelCols then
    Exit;
  Result := Result + FPanelShift;
  if Result < FarMinPanelCols then
    Result := FarMinPanelCols;
  if Result > FCols - FarMinPanelCols then
    Result := FCols - FarMinPanelCols;
end;

// Ctrl+Left - граница панелей влево (ADelta = -1), Ctrl+Right - вправо
procedure TFarView.ChangePanelShift(ADelta: Integer);
var
  OldWidth: Integer;
begin
  // Одна панель (F4): двигается граница окна FAR и редактора (Unit1)
  if FSingle >= 0 then
  begin
    if Assigned(FOnHalfResize) then
      FOnHalfResize(ADelta, FCellW);
    Exit;
  end;
  OldWidth := LeftPanelWidth;
  // Сдвиг - от той ширины, что видна (упёрлись в край - дальше не копится)
  FPanelShift := OldWidth - FCols div 2 + ADelta;
  if LeftPanelWidth = OldWidth then
  begin
    FPanelShift := OldWidth - FCols div 2;
    Exit;
  end;
  Invalidate;
end;

// Строк у панели: всё окно без нижней строки (кейбар)
// Строк у панелей: окно без кейбара и без строк, на которые панели
// укоротили (Ctrl+Up); под панелями - вывод команд, как в FAR
function TFarView.PanelHeight: Integer;
begin
  if FPanelCut > MaxPanelCut then
    FPanelCut := MaxPanelCut;
  if FPanelCut < 0 then
    FPanelCut := 0;
  Result := OutBottom + 1 - FPanelCut;
end;

// Короче не укоротить: у панели должно остаться место под рамку,
// заголовок колонок, две строки имён, строку о файле и итог
function TFarView.MaxPanelCut: Integer;
const
  MinPanelRows = 8;
begin
  Result := OutBottom + 1 - MinPanelRows;
  if Result < 0 then
    Result := 0;
end;

// Ctrl+Up - панели короче на строку (ADelta = 1), Ctrl+Down - длиннее
procedure TFarView.ChangePanelCut(ADelta: Integer);
var
  NewCut: Integer;
begin
  NewCut := FPanelCut + ADelta;
  if NewCut > MaxPanelCut then
    NewCut := MaxPanelCut;
  if NewCut < 0 then
    NewCut := 0;
  if NewCut = FPanelCut then
    Exit;
  FPanelCut := NewCut;
  EnsureVisible(FPanels[0]);
  EnsureVisible(FPanels[1]);
  Invalidate;
end;

// Кейбар: на клавишу нужно 8 клеток (номер до 2 и подпись до 6). Не
// вмещаются 12 в строку - две строки по 6
function TFarView.KeyBarRows: Integer;
begin
  if FCols div 12 < 8 then
    Result := 2
  else
    Result := 1;
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

// Имён на экране панели (две колонки; список адресов FTP - одна)
function TFarView.PageSize(APanel: TFarPanel): Integer;
begin
  Result := FileRows * PanelColumns(APanel);
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
  Capacity := PageSize(APanel);
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
procedure TFarView.DrawFrame(AX0, AWidth, AHeight, AFirstCol,
  ASecondCol: Integer);
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
    Pen.Color := FPal[fpPanelFrame];
    Brush.Style := bsClear;
    Rectangle(LeftX - 1, TopY - 1, RightX + 2, BottomY + 2);
    Rectangle(LeftX + 1, TopY + 1, RightX, BottomY);
    Brush.Style := bsSolid;
    MoveTo(LeftX + 1, SepY);
    LineTo(RightX, SepY);
    MoveTo(ColX, TopY + 1);
    LineTo(ColX, SepY);
    // Вторая граница колонок (список адресов FTP)
    if ASecondCol >= 0 then
    begin
      ColX := (AX0 + 1 + ASecondCol) * FCellW + FCellW div 2;
      MoveTo(ColX, TopY + 1);
      LineTo(ColX, SepY);
    end;
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
  HasRule: Boolean;
  RuleFore, RuleBack: TColor;
  HostW, HomeW, UserW: Integer;
begin
  Panel := FPanels[AIndex];
  PanelBounds(AIndex, PanelX, PanelW);
  PanelH := PanelHeight;
  FillCells(PanelX, 0, PanelW, FPal[fpPanelBack]);
  for RowIndex := 1 to PanelH - 1 do
    FillCells(PanelX, RowIndex, PanelW, FPal[fpPanelBack]);
  if (PanelW < 8) or (PanelH < 7) then
    Exit;

  IsActive := AIndex = FActive;
  ColumnWidths(PanelW, FirstW, SecondW);
  Rows := FileRows;
  InnerW := PanelW - 2;

  // Список адресов FTP: Host | Home | User, строка на адрес
  if Panel.FFtpMode = 1 then
    DrawFtpHosts(Panel, PanelX, PanelW, IsActive)
  else
  begin
    // Заголовки колонок
    PutCentered(PanelX + 1, 1, FirstW, 'Name', FPal[fpPanelHeader],
      FPal[fpPanelBack]);
    PutCentered(PanelX + 2 + FirstW, 1, SecondW, 'Name', FPal[fpPanelHeader],
      FPal[fpPanelBack]);

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
          // Раскраска по расширению - только у файлов
          Back := FPal[fpPanelBack];
          HasRule := not IsDir and RuleColors(Name, RuleFore, RuleBack);
          if HasRule and (RuleBack <> clNone) then
            Back := RuleBack;
          if Selected then
            Fore := FPal[fpPanelSelected]
          else if IsDir then
            Fore := FPal[fpPanelDir]
          else if HasRule then
            Fore := RuleFore
          else
            Fore := FPal[fpPanelText];
          if IsActive and (ItemIndex = Panel.Cursor) then
          begin
            Back := FPal[fpPanelCursorBack];
            if not Selected then
              Fore := FPal[fpPanelCursorText];
          end;
          PutText(ColX, 2 + RowIndex, ColW, FarFitName(Name, ColW), Fore, Back);
        end;
      end;
    end;
  end;

  // Строка о файле под курсором
  if (Panel.Cursor >= 0) and (Panel.Cursor < Panel.Count) then
    with Panel.FItems[Panel.Cursor] do
    begin
      if IsUp then
        RightText := 'Up'
      else if Panel.FFtpMode = 1 then
        RightText := ''
      else if IsDir then
        RightText := 'Folder'
      else
        RightText := IntToStr(Size) + ' ' + FarFileDate(WriteTime);
      if Length(RightText) > InnerW then
        RightText := '';
      NameW := InnerW - Length(RightText) - 1;
      if IsUp then
        ItemName := '..'
      else if (Panel.FFtpMode = 1) and (OrigIndex >= 0) and
              (OrigIndex <= High(FFtpHosts)) then
      begin
        // Адрес: описание, нет его - адрес целиком
        ItemName := FFtpHosts[OrigIndex].Description;
        if ItemName = '' then
          ItemName := FarFtpHostUrl(FFtpHosts[OrigIndex]) +
            FFtpHosts[OrigIndex].Home;
      end
      else
        ItemName := Name;
      PutText(PanelX + 1, PanelH - 2, NameW, FarFitName(ItemName, NameW),
        FPal[fpPanelText], FPal[fpPanelBack]);
      PutText(PanelX + 1 + InnerW - Length(RightText), PanelH - 2,
        Length(RightText), RightText, FPal[fpPanelText],
        FPal[fpPanelBack]);
    end;

  if Panel.FFtpMode = 1 then
  begin
    FtpHostColumns(PanelW, HostW, HomeW, UserW);
    DrawFrame(PanelX, PanelW, PanelH, HostW, HostW + 1 + HomeW);
  end
  else
    DrawFrame(PanelX, PanelW, PanelH, FirstW);

  // Буква сортировки в левом верхнем углу
  SortLetter := Copy(FarSortLetters, Ord(Panel.FSortMode) + 1, 1);
  if Panel.FSortReverse then
    SortLetter := UpperCase(SortLetter);
  PutText(PanelX + 1, 0, 1, SortLetter, FPal[fpPanelText],
    FPal[fpPanelBack]);

  // Заголовок - путь; у активной панели - цветом курсора
  Title := Panel.DisplayPath;
  if (Length(Title) > 3) and (Title[Length(Title)] = '\') then
    SetLength(Title, Length(Title) - 1);
  Title := ' ' + FarFitPath(Title, PanelW - 6) + ' ';
  if IsActive then
    PutCentered(PanelX, 0, PanelW, Title, FPal[fpPanelCursorText],
      FPal[fpPanelCursorBack])
  else
    PutCentered(PanelX, 0, PanelW, Title, FPal[fpPanelText],
      FPal[fpPanelBack]);

  // Выделенные - на разделителе
  if Panel.SelCount > 0 then
  begin
    SelText := ' ' + FarGroupDigits(Panel.SelBytes) + ' bytes in ' +
      IntToStr(Panel.SelCount) + ' files ';
    PutCentered(PanelX + 1, PanelH - 3, InnerW, SelText, FPal[fpPanelSelected],
      FPal[fpPanelCursorBack]);
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
      FPal[fpPanelText], FPal[fpPanelBack]);
    if FreeText <> '' then
      PutText(StartCol + Length(Totals) + 2, PanelH - 1, Length(FreeText),
        FreeText, FPal[fpPanelText], FPal[fpPanelBack]);
  end;
end;

procedure TFarView.DrawKeyBar;
var
  KeyIndex, SlotW, SlotCol, LabelW, RowCount, PerRow, KeyRow, SlotIndex: Integer;
  Number, KeyLabel: string;
  AltDown, CtrlDown, ShiftDown: Boolean;
begin
  RowCount := KeyBarRows;
  if FRows < RowCount then
    Exit;
  AltDown := GetKeyState(VK_MENU) < 0;
  CtrlDown := GetKeyState(VK_CONTROL) < 0;
  ShiftDown := GetKeyState(VK_SHIFT) < 0;
  PerRow := 12 div RowCount;
  for KeyRow := FRows - RowCount to FRows - 1 do
    FillCells(0, KeyRow, FCols, FPal[fpKeyNumBack]);
  SlotW := FCols div PerRow;
  if SlotW < 3 then
    Exit;
  for KeyIndex := 0 to 11 do
  begin
    KeyRow := FRows - RowCount + KeyIndex div PerRow;
    SlotIndex := KeyIndex mod PerRow;
    SlotCol := SlotIndex * SlotW;
    if ViewerActive then
      KeyLabel := ViewKeyLabel(KeyIndex, ShiftDown, CtrlDown, AltDown)
    else if EditorActive then
    begin
      // Редактор: свои подписи
      if AltDown then
        KeyLabel := FarEdKeysAlt[KeyIndex]
      else if CtrlDown then
        KeyLabel := ''
      else if ShiftDown then
        KeyLabel := FarEdKeysShift[KeyIndex]
      else
        KeyLabel := FarEdKeysNormal[KeyIndex];
    end
    else if AltDown then
      KeyLabel := FarKeysAlt[KeyIndex]
    else if CtrlDown then
      KeyLabel := FarKeysCtrl[KeyIndex]
    else if ShiftDown then
      KeyLabel := FarKeysShift[KeyIndex]
    else
      KeyLabel := FarKeysNormal[KeyIndex];
    Number := IntToStr(KeyIndex + 1);
    LabelW := SlotW - Length(Number);
    if SlotIndex = PerRow - 1 then
      LabelW := FCols - SlotCol - Length(Number);  // последняя - до края
    PutText(SlotCol, KeyRow, Length(Number), Number, FPal[fpKeyNum],
      FPal[fpKeyNumBack]);
    PutText(SlotCol + Length(Number), KeyRow, LabelW, KeyLabel, FPal[fpKeyText],
      FPal[fpKeyBack]);
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
    FBuffer.Canvas.Brush.Color := FPal[fpCmdBack];
    FBuffer.Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));
    if (FCols >= 20) and (FRows >= 8) then
    begin
      // Вывод команд: под панелями, а спрятаны панели (Ctrl+O) - всё окно
      if FPanelsHidden then
        DrawOutput(0, OutBottom)
      else
      begin
        // Редактор (F4) - вместо своей панели или обеих
        if not EditorShown(0) then
          DrawPanel(0);
        if not EditorShown(1) then
          DrawPanel(1);
        if FEditor <> nil then
          DrawEditor;
        if FViewer <> nil then
          DrawViewer;
        if PanelHeight <= OutBottom then
          DrawOutput(PanelHeight, OutBottom);
      end;
      if FMessageLine then
        DrawMessageLine;
      DrawCmdLine;
      DrawKeyBar;
      if FFindOpen then
        DrawFind;
      if FMenuKind <> fmNone then
        DrawMenu;
      if FDlgKind <> fdNone then
        DrawDialog;
      if FPickOpen then
        DrawPick;
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
  if FSingle >= 0 then
    APanelIndex := FSingle
  else if Col < LeftPanelWidth then
    APanelIndex := 0
  else
    APanelIndex := 1;
  PanelBounds(APanelIndex, PanelX, PanelW);
  ColumnWidths(PanelW, FirstW, SecondW);
  if (Row < 2) or (Row >= 2 + FileRows) then
    Exit;
  // Список адресов FTP: строка на адрес во всю ширину
  if FPanels[APanelIndex].FFtpMode = 1 then
  begin
    if (Col <= PanelX) or (Col >= PanelX + PanelW - 1) then
      Exit;
    AItemIndex := FPanels[APanelIndex].TopIndex + Row - 2;
    Result := AItemIndex < FPanels[APanelIndex].Count;
    Exit;
  end;
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
  EditX0, EditW0: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  EditX0 := 0;
  EditW0 := 0;
  if DocOpen then
    EditBounds(EditX0, EditW0);
  if CanFocus and not Focused then
    SetFocus;
  // Окно выбора цвета: щелчки - только ему
  if FPickOpen then
  begin
    if Button = mbLeft then
      PickMouse(X, Y);
    Invalidate;
    Exit;
  end;
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
    if (Button = mbLeft) and (Length(FDlgRows) > 0) and
       (Y div FCellH >= FDlgRowsTop) and
       (Y div FCellH < FDlgRowsTop + Length(FDlgRows)) then
      DlgRowsMouse(X, Y)
    else if (Button = mbLeft) and (Y div FCellH = FDlgButtonRow) then
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
  // Окно найденного (Alt+F7)
  if FFindOpen then
  begin
    if Button = mbLeft then
      FindMouse(X, Y);
    Invalidate;
    Exit;
  end;
  // Панели спрятаны или щелчок ниже панелей (вывод, командная строка)
  if FPanelsHidden or (Y div FCellH >= PanelHeight) then
  begin
    Invalidate;
    Exit;
  end;
  // Просмотр (F3): щелчок - перейти в него
  if (FViewer <> nil) and (FEditWide or
     ((X div FCellW >= EditX0) and (X div FCellW < EditX0 + EditW0))) then
  begin
    FActive := FEditPanel;
    Invalidate;
    Exit;
  end;
  // Редактор (F4): каретка под мышь, Shift - выделение до неё
  if (FEditor <> nil) and (FEditWide or
     ((X div FCellW >= EditX0) and (X div FCellW < EditX0 + EditW0))) then
  begin
    FActive := FEditPanel;
    if Button = mbLeft then
    begin
      EditMouse(X, Y, ssShift in Shift, False);
      FEditDragging := True;
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
  // Окно найденного: двойной щелчок по файлу - Go to
  if FFindOpen then
  begin
    CursorPos := ScreenToClient(Mouse.CursorPos);
    if (CursorPos.Y div FCellH >= FFindListTop) and
       (CursorPos.Y div FCellH < FFindListTop + FindListRows) then
      FindGoTo;
    Exit;
  end;
  CursorPos := ScreenToClient(Mouse.CursorPos);
  if FPanelsHidden or (CursorPos.Y div FCellH >= PanelHeight) then
    Exit;
  // В редакторе и просмотре двойной щелчок файлы не открывает
  if EditorShown(FActive) then
    Exit;
  if ItemAt(CursorPos.X, CursorPos.Y, PanelIndex, ItemIndex) then
    OpenItem(False);   // как Enter: папка - войти, файл - выполнить / открыть
end;

procedure TFarView.WMMouseWheel(var Message: TWMMouseWheel);
var
  WheelPoint: TPoint;
  WheelX, WheelW, WheelStep: Integer;
begin
  Message.Result := 1;
  if FPickOpen then
    Exit;
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
  if FFindOpen then
  begin
    if Message.WheelDelta > 0 then
      FindMove(-3)
    else if Message.WheelDelta < 0 then
      FindMove(3);
    Invalidate;
    Exit;
  end;
  // Колесо над выводом (или панели спрятаны) - прокрутка вывода
  WheelPoint := ScreenToClient(Point(Message.XPos, Message.YPos));
  if FPanelsHidden or (WheelPoint.Y div FCellH >= PanelHeight) then
  begin
    if Message.WheelDelta > 0 then
      Inc(FOutScroll, 3)
    else if Message.WheelDelta < 0 then
      Dec(FOutScroll, 3);
    if FOutScroll < 0 then
      FOutScroll := 0;
    Invalidate;
    Exit;
  end;
  // Колесо над просмотром - на три строки
  if (FViewer <> nil) and EditorShown(FActive) then
  begin
    EditBounds(WheelX, WheelW);
    for WheelStep := 1 to 3 do
      if Message.WheelDelta > 0 then
        FViewer.LineUp(WheelW)
      else if Message.WheelDelta < 0 then
        FViewer.LineDown(WheelW, ViewTextRows);
    Invalidate;
    Exit;
  end;
  // Колесо над редактором - прокрутка текста (каретка на месте)
  if (FEditor <> nil) and EditorShown(FActive) then
  begin
    if Message.WheelDelta > 0 then
      FEditor.TopRow := FEditor.TopRow - 3
    else if Message.WheelDelta < 0 then
      FEditor.TopRow := FEditor.TopRow + 3;
    if FEditor.TopRow > FEditor.Count - 1 then
      FEditor.TopRow := FEditor.Count - 1;
    if FEditor.TopRow < 0 then
      FEditor.TopRow := 0;
    Invalidate;
    Exit;
  end;
  if Message.WheelDelta > 0 then
    MoveCursor(-1, False)
  else if Message.WheelDelta < 0 then
    MoveCursor(1, False);
  Message.Result := 1;
end;

procedure TFarView.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  // Протяжка в редакторе - выделение
  if FEditDragging and (FEditor <> nil) and (ssLeft in Shift) then
    EditMouse(X, Y, True, True);
end;

procedure TFarView.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
    FEditDragging := False;
end;

// ---------------------------------------------------------------------------
//  Клавиши
// ---------------------------------------------------------------------------

procedure TFarView.Status(const AText: string);
var
  Prefix: string;
begin
  if Assigned(FOnStatus) then
    FOnStatus(AText)
  else if FMessageLine then
  begin
    // Своя строка: имя программы в начале не нужно
    Prefix := FarProduct + ': ';
    if Copy(AText, 1, Length(Prefix)) = Prefix then
      FMessageText := WideString(Copy(AText, Length(Prefix) + 1, MaxInt))
    else
      FMessageText := WideString(AText);
    Invalidate;
  end;
end;

// Символ из WM_CHAR
function TFarView.KeyChar(ACode: WPARAM): WideChar;
var
  AnsiCh: AnsiChar;
begin
  if FUnicodeChars then
  begin
    Result := WideChar(ACode and $FFFF);
    Exit;
  end;
  AnsiCh := AnsiChar(ACode and $FF);
  Result := #0;
  FarMultiToWide(CP_ACP, 0, @AnsiCh, 1, @Result, 1);
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
  WideCh: WideChar;
begin
  Result := False;
  KeyCode := Word(AMsg.wParam);

  // Символ для поля ввода диалога. Окно VCL в Delphi 7 - ANSI: символ
  // приходит в кодировке Windows; окно uniFAR - Unicode (KeyChar)
  if AMsg.message = WM_CHAR then
  begin
    // Окно выбора цвета: поля расширения и #RRGGBB
    if FPickOpen then
    begin
      WideCh := KeyChar(AMsg.wParam);
      if (KeyCode >= 32) and (WideCh <> #0) then
        PickChar(WideCh);
      Invalidate;
      Result := True;
      Exit;
    end;
    if (FDlgKind <> fdNone) and (KeyCode >= 32) and
       ((FDlgHasEdit and (FDlgFocus < 0)) or DlgRowIsEdit) then
    begin
      WideCh := KeyChar(AMsg.wParam);
      if (WideCh <> #0) and DlgRowIsEdit then
        DlgRowInsert(WideCh)
      else if WideCh <> #0 then
        DlgInsertText(WideCh);
      Invalidate;
      Result := True;
    end
    // Символ в редактор (F4), если он активен
    else if (FDlgKind = fdNone) and (FMenuKind = fmNone) and
            not FFindOpen and (KeyCode >= 32) and EditorActive then
    begin
      WideCh := KeyChar(AMsg.wParam);
      if WideCh <> #0 then
        EditChar(WideCh);
      Result := True;
    end
    // В просмотре символы не нужны (и не в командную строку)
    else if (FDlgKind = fdNone) and (FMenuKind = fmNone) and
            not FFindOpen and (KeyCode >= 32) and ViewerActive then
      Result := True
    // Символ без диалога и меню - в командную строку
    else if (FDlgKind = fdNone) and (FMenuKind = fmNone) and
            not FFindOpen and (KeyCode >= 32) then
    begin
      WideCh := KeyChar(AMsg.wParam);
      if WideCh <> #0 then
        CmdInsert(WideCh);
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

  // Сообщение в своей строке - до следующей клавиши
  if FMessageText <> '' then
  begin
    FMessageText := '';
    Invalidate;
  end;

  if FPickOpen then
  begin
    Result := PickKey(KeyCode, ShiftDown, CtrlDown, AltDown);
    // Символы полей - WM_CHAR: без TranslateMessage его не будет
    if FPickFocus = pfExt then
      if (KeyCode <> VK_ESCAPE) and (KeyCode <> VK_TAB) and
         (KeyCode <> VK_RETURN) and (KeyCode <> VK_BACK) and
         (KeyCode <> VK_DELETE) and (KeyCode <> VK_LEFT) and
         (KeyCode <> VK_RIGHT) and (KeyCode <> VK_HOME) and
         (KeyCode <> VK_END) and not ((KeyCode >= VK_F1) and
         (KeyCode <= VK_F12)) then
        Result := False;
    Invalidate;
  end
  else if FMenuKind <> fmNone then
  begin
    Result := MenuKey(KeyCode, ShiftDown, CtrlDown, AltDown);
    Invalidate;
  end
  else if FDlgKind <> fdNone then
  begin
    Result := DlgKey(KeyCode, ShiftDown, CtrlDown, AltDown);
    Invalidate;
  end
  else if FFindOpen then
    Result := FindKey(KeyCode, ShiftDown, CtrlDown, AltDown)
  else if ViewerActive then
    Result := ViewKey(KeyCode, ShiftDown, CtrlDown, AltDown)
  else if EditorActive then
    Result := EditKey(KeyCode, ShiftDown, CtrlDown, AltDown)
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
  Plain, CmdHandled: Boolean;
begin
  Result := True;
  Plain := not ACtrl and not AAlt;

  // Список адресов FTP: Ctrl+Ins (Ctrl+C) - адреса в буфер обмена,
  // Shift+Ins (Ctrl+V) - адреса из буфера (если там ftp://...; иначе -
  // вставка в командную строку, как обычно)
  if (ActivePanel.FFtpMode = 1) and not AAlt then
  begin
    if ACtrl and not AShift and ((AKey = VK_INSERT) or (AKey = Ord('C'))) then
    begin
      FtpCopyHosts;
      Exit;
    end;
    if ((AShift and not ACtrl and (AKey = VK_INSERT)) or
        (ACtrl and not AShift and (AKey = Ord('V')))) and FtpPasteHosts then
      Exit;
  end;

  // Командная строка: её клавиши - первыми
  if CmdKey(AKey, AShift, ACtrl, AAlt, CmdHandled) then
  begin
    Result := CmdHandled;
    Exit;
  end;

  // Панели спрятаны (Ctrl+O): работают только F10 и командная строка
  if FPanelsHidden and not ((AKey = VK_F10) and Plain and not AShift) then
  begin
    if (AKey >= VK_F1) and (AKey <= VK_F12) then
      Status(FarProduct + ': панели спрятаны - Ctrl+O');
    Result := (AKey >= VK_F1) and (AKey <= VK_F12) or (AKey = VK_UP) or
      (AKey = VK_DOWN) or (AKey = VK_LEFT) or (AKey = VK_RIGHT) or
      (AKey = VK_PRIOR) or (AKey = VK_NEXT) or (AKey = VK_HOME) or
      (AKey = VK_END) or (AKey = VK_INSERT) or (AKey = VK_DELETE) or
      (AKey = VK_TAB) or (AKey = VK_RETURN);
    Exit;
  end;

  // Панель на FTP: свои Enter, Ctrl+R, F4, F8 и т.д.
  if ActivePanel.IsFtp and FtpKey(AKey, AShift, ACtrl, AAlt) then
    Exit;

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
            AltPanelKey(0);
            Exit;
          end;
        VK_F2:
          begin
            AltPanelKey(1);
            Exit;
          end;
        VK_F12:
          begin
            ShowHistoryMenu;
            Exit;
          end;
        VK_F7:
          begin
            StartFind;
            Exit;
          end;
      end;
    if Plain then
      case AKey of
        VK_F1:              // Shift+F1 - упаковать в архив
          if AShift then
          begin
            StartArcAdd;
            Exit;
          end;
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
        VK_F9:              // F9 - меню Options, Shift+F9 - Save setup
          begin
            if AShift then
              SaveSetup
            else
              ShowOptionsMenu;
            Exit;
          end;
        VK_F3:              // F3 - просмотр файла
          if not AShift then
          begin
            ViewCurrent;
            Exit;
          end;
        VK_F4:              // F4 - файл в редактор, Shift+F4 - по имени
          begin
            if AShift then
              StartEditNew
            else
              EditCurrent;
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
       (AKey = VK_F12)) then
      Status(FarProduct + ': ' + KeyName(AKey, AShift, ACtrl, AAlt) +
        ' - заглушка')
    else
      Status(FarProduct + ' ' + FarBuild + ': ' +
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
        if FSingle >= 0 then
        begin
          // Видна одна панель (F4) - Tab уводит в редактор
          if Assigned(FOnLeave) then
            FOnLeave(Self);
        end
        else
        begin
          // Другая панель - редактор F4: в него (так и было бы: 1 - FActive)
          FActive := 1 - FActive;
          Invalidate;
        end;
      VK_RETURN:            // Shift+Enter - в своём окне
        OpenItem(AShift);
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
      VK_TAB:
        // Режим F4 (одна панель): Ctrl+Tab - в редактор (обратно -
        // Ctrl+Tab в редакторе, Unit1); две панели - как Tab, другая панель
        if FSingle >= 0 then
        begin
          if Assigned(FOnLeave) then
            FOnLeave(Self);
        end
        else
        begin
          FActive := 1 - FActive;
          Invalidate;
        end;
      VK_PRIOR:
        GoUp;
      VK_NEXT:
        EnterItem;
      VK_LEFT:              // граница между панелями влево
        ChangePanelShift(-1);
      VK_RIGHT:             // граница между панелями вправо
        ChangePanelShift(1);
      VK_DOWN:              // граница панелей вниз - панели длиннее
        ChangePanelCut(-1);
      VK_UP:                // граница панелей вверх - панели короче
        ChangePanelCut(1);
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
  Step := PageSize(Panel) - 1;
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
    Status(FarProduct + ': папку не открыть: ' + ErrorText);
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
  if Panel.IsFtp then
  begin
    FtpEnter(FActive);
    Exit;
  end;
  // Ctrl+PgDn: в архиве - как Enter, файл - открыть как архив
  if Panel.IsArchive then
  begin
    ArcOpenItem(False, True);
    Exit;
  end;
  with Panel.FItems[Panel.Cursor] do
    if IsUp then
      GoUp
    else if IsDir then
      ChangeDir(Panel, Panel.Path + Name + '\', '')
    else
      // Файл - открыть как архив, какое бы ни было расширение
      OpenArchive(FActive, Panel.Path + Name, Panel.Path + Name, False, '');
end;

// Enter на файле: exe, com, bat, cmd - выполнить, как команду из
// командной строки (cmd.exe /C, вывод - под панелями); остальные - открыть
// по ассоциации. ASeparate (Shift+Enter) - в своём окне через ShellExecute:
// exe - отдельным окном, папка - в Проводнике. На папке без Shift - войти
procedure TFarView.OpenItem(ASeparate: Boolean);
var
  Panel: TFarPanel;
  Name, Ext: WideString;
  IsUp, IsDir: Boolean;
begin
  Panel := ActivePanel;
  if (Panel.Count = 0) or (Panel.Cursor < 0) or
     (Panel.Cursor >= Panel.Count) then
    Exit;
  // FTP: двойной щелчок - как Enter
  if Panel.IsFtp then
  begin
    FtpEnter(FActive);
    Exit;
  end;
  if Panel.IsArchive then
  begin
    ArcOpenItem(ASeparate, False);
    Exit;
  end;
  Name := Panel.FItems[Panel.Cursor].Name;
  IsUp := Panel.FItems[Panel.Cursor].IsUp;
  IsDir := Panel.FItems[Panel.Cursor].IsDir;
  if IsUp then
  begin
    if not ASeparate then
      GoUp;
    Exit;
  end;
  if ASeparate then
  begin
    ShellOpen(Panel.Path + Name, Panel.Path);
    Exit;
  end;
  if IsDir then
  begin
    EnterItem;
    Exit;
  end;
  // Архив - раскрыть в этой же панели (7-Zip из tools\7zip)
  if IsArchiveName(Name) then
  begin
    OpenArchive(FActive, Panel.Path + Name, Panel.Path + Name, False, '');
    Exit;
  end;
  Ext := WideLowerCase(FarNameExt(Name));
  if (Ext = 'exe') or (Ext = 'com') or (Ext = 'bat') or (Ext = 'cmd') then
  begin
    if FProcHandle <> 0 then
    begin
      Status(FarProduct + ': прежняя команда ещё выполняется (Ctrl+Break - ' +
        'прервать; Shift+Enter - запустить в своём окне)');
      Exit;
    end;
    CmdHistoryAdd(FarQuoteName(Name));
    FOutScroll := 0;
    OutLine(PromptText + FarQuoteName(Name));
    // Имя - в двойных кавычках: cmd.exe /C снимает внешнюю пару, и имя с
    // пробелами и знаками & ( ) остаётся в кавычках
    CmdRun(WideString('""') + Name + WideString('""'));
    if not FPanelsHidden and (PanelHeight > OutBottom) then
      Status(FarProduct + ': вывод команды - Ctrl+O или Ctrl+Up');
    Invalidate;
    Exit;
  end;
  ShellOpen(Panel.Path + Name, Panel.Path);
end;

// Открыть файл (папку) программой Windows по ассоциации; программы для
// файла нет - окно «Открыть с помощью»
procedure TFarView.ShellOpen(const AFile, ADir: WideString);
var
  OwnerWnd: HWND;
  ResultCode: Integer;
  Verb: WideString;
begin
  OwnerWnd := GetParentFormHandle;
  ResultCode := Integer(FarShellExecute(OwnerWnd, nil, PWideChar(AFile), nil,
    PWideChar(ADir), SW_SHOWNORMAL));
  if ResultCode = FarSeErrNoAssoc then
  begin
    Verb := 'openas';
    ResultCode := Integer(FarShellExecute(OwnerWnd, PWideChar(Verb),
      PWideChar(AFile), nil, PWideChar(ADir), SW_SHOWNORMAL));
  end;
  if (ResultCode >= 0) and (ResultCode <= 32) then
    Status(FarProduct + ': файл не открыть: ' + SysErrorMessage(ResultCode));
end;

procedure TFarView.GoUp;
var
  Panel: TFarPanel;
  ParentDir, ChildName: WideString;
begin
  Panel := ActivePanel;
  if Panel.FFtpMode = 2 then
  begin
    FtpUp(FActive);
    Exit;
  end;
  if Panel.FFtpMode = 1 then
  begin
    FtpExit(Panel);
    Exit;
  end;
  if Panel.IsArchive then
  begin
    ArcUp(Panel);
    Exit;
  end;
  ParentDir := Panel.ParentPath(ChildName);
  if ParentDir <> '' then
    ChangeDir(Panel, ParentDir, ChildName);
end;

procedure TFarView.GoRoot;
var
  Panel: TFarPanel;
begin
  Panel := ActivePanel;
  // В архиве: Ctrl+\ - в корень архива, в корне - в корень диска
  if Panel.IsArchive and (Panel.FArcDir <> '') then
  begin
    Panel.FArcDir := '';
    Panel.BuildArcView('');
    EnsureVisible(Panel);
    Invalidate;
    Exit;
  end;
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
  FDlgMasked := False;
  FDlgRows := nil;
  FDlgRow := -1;
  if AHasEdit then
    FDlgFocus := -1
  else
    FDlgFocus := 0;
  FDlgButtonRow := -1;
  Invalidate;
end;

procedure TFarView.DlgClose;
begin
  // Окно пароля закрыто (Esc, Cancel) - работа с архивом отменена; OK
  // возвращает её сам (DlgActivate)
  if FDlgKind in [fdPassword, fdSzOffer] then
  begin
    FArcAction := aaNone;
    FArcJobTemp := '';
  end;
  // Окно хода загрузки 7-Zip закрыто (Esc, Cancel) - отмена загрузки
  if (FDlgKind = fdSzProgress) and (FSzThread <> nil) then
  begin
    FDlgKind := fdNone;
    SzCancel;
  end;
  FDlgKind := fdNone;
  FDlgLines := nil;
  FDlgRows := nil;
  FDlgRow := -1;
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
  // Окно с несколькими полями (Shift+F1) - свои клавиши
  if Length(FDlgRows) > 0 then
  begin
    Result := DlgRowsKey(AKey, AShift, ACtrl, AAlt);
    Exit;
  end;
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
      if InEdit and AShift and FarClipboardHasText then
        DlgInsertText(FarClipboardText);
  else
    if InEdit and ACtrl and not AAlt and (AKey = Ord('V')) then
    begin
      if FarClipboardHasText then
        DlgInsertText(FarClipboardText);
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
  EditText, SavedTemp: WideString;
  SavedAction: TFarArcAction;
begin
  // Shift+F1, Add: сначала проверка полей - окно закрывается, только если
  // всё верно
  if (FDlgKind = fdArcAdd) and (AButton = 0) then
  begin
    ArcAddConfirm;
    Exit;
  end;
  // Alt+F7, Find: поиск
  if (FDlgKind = fdFind) and (AButton = 0) then
  begin
    FindConfirm;
    Exit;
  end;
  // Адрес FTP: Save / Connect - проверка, окно закрывает FtpEditConfirm
  if (FDlgKind = fdFtpEdit) and (AButton <= 1) then
  begin
    FtpEditConfirm(AButton = 1);
    Exit;
  end;
  // Редактор: поиск
  if (FDlgKind = fdEditFind) and (AButton = 0) then
  begin
    EditFindConfirm;
    Exit;
  end;
  // История папок: очистить? Потом - снова меню истории (если что-то
  // осталось)
  if FDlgKind = fdHistClear then
  begin
    DlgClose;
    if AButton = 0 then
    begin
      HistoryClearUnlocked;
      ShowHistoryMenu;
    end
    else
      ShowHistoryMenu(FHiDelIdx);
    Exit;
  end;
  // Files highlighting: удалить правило? Потом - снова список правил
  if FDlgKind = fdHiDelete then
  begin
    DlgClose;
    if AButton = 0 then
      HiDeleteRule(FHiDelIdx)
    else
      ShowHiRules(FHiDelIdx);
    Exit;
  end;
  // Просмотр: поиск
  if (FDlgKind = fdViewFind) and (AButton = 0) then
  begin
    ViewFindConfirm;
    Exit;
  end;
  // Редактор: изменён - Save / Don't save / Cancel
  if FDlgKind = fdEditQuit then
  begin
    DlgClose;
    if (AButton = 0) and (FEditor <> nil) then
    begin
      FEditQuitAfterSave := True;
      EditSave(FEditor.FileName, FEditor.Encoding, False);
    end
    else if AButton = 1 then
      CloseEditor;
    Exit;
  end;
  // Редактор: не все символы в кодировке Windows - UTF-8 / ANSI / Cancel
  if FDlgKind = fdEditEncode then
  begin
    DlgClose;
    if AButton = 0 then
      EditSave(FEditSaveName, feUtf8, False)
    else if AButton = 1 then
      EditSave(FEditSaveName, feAnsi, True)
    else
      FEditQuitAfterSave := False;
    Exit;
  end;
  Kind := FDlgKind;
  EditText := FDlgEdit;
  SavedAction := FArcAction;
  SavedTemp := FArcJobTemp;
  DlgClose;
  // Окно «нет 7-Zip»: вторая кнопка - страница загрузки 7-Zip в браузере
  if (Kind = fdSzFail) and (AButton = 1) then
  begin
    ShellOpen(SzDownloadPage, '');
    Exit;
  end;
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
    fdEditNew:
      DoEditNew(EditText);
    fdArcExtract:
      DoArcExtract(EditText);
    fdPassword:
      // Повтор работы с архивом с паролем
      if (SavedAction <> aaNone) and (EditText <> '') then
      begin
        FArcAction := SavedAction;
        FArcJobTemp := SavedTemp;
        FArcJobPassword := EditText;
        ArcRun;
      end;
    fdSzOffer:
      begin
        FArcAction := SavedAction;
        FArcJobTemp := SavedTemp;
        SzStartDownload;
      end;
    fdFtpPassword:
      FtpPasswordEntered(EditText);
    fdFtpDelete:
      FtpDeleteConfirmed;
    fdEditSave:
      if (FEditor <> nil) and (FarTrimW(EditText) <> '') then
        EditSave(FarFullPath(FarWithSlash(ExtractFilePath(
          string(FEditor.FileName))), FarTrimW(EditText)), FEditor.Encoding,
          False);
    fdEditGoto:
      EditGoto(EditText);
    fdViewGoto:
      ViewGoto(EditText);
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
  BoxH := Length(FDlgLines) + 6 + Length(FDlgRows);
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
    Back := FPal[fpWarnBack];
    Fore := FPal[fpWarnText];
    ButtonBack := FPal[fpWarnBack];
    ButtonFore := FPal[fpWarnText];
    FocusBack := FPal[fpWarnFocusBack];
    FocusFore := FPal[fpWarnFocusText];
  end
  else
  begin
    Back := FPal[fpDlgBack];
    Fore := FPal[fpDlgText];
    ButtonBack := FPal[fpDlgBack];
    ButtonFore := FPal[fpDlgText];
    FocusBack := FPal[fpDlgFocusBack];
    FocusFore := FPal[fpDlgFocusText];
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
    if FDlgMasked then
      for LineIndex := 1 to Length(ShownText) do
        ShownText[LineIndex] := '*';
    FillCells(InnerLeft, Row, InnerW, FPal[fpDlgEditBack]);
    if FDlgEditFresh then
      PutText(InnerLeft, Row, Length(ShownText), ShownText, FPal[fpDlgSelText],
        FPal[fpDlgSelBack])
    else
      PutText(InnerLeft, Row, Length(ShownText), ShownText, FPal[fpDlgEditText],
        FPal[fpDlgEditBack]);
    if FDlgFocus < 0 then
    begin
      CaretX := (InnerLeft + FDlgEditPos - FDlgEditScroll) * FCellW;
      FBuffer.Canvas.Brush.Style := bsSolid;
      FBuffer.Canvas.Brush.Color := FPal[fpDlgEditText];
      FBuffer.Canvas.FillRect(Rect(CaretX, Row * FCellH + 1, CaretX + 2,
        (Row + 1) * FCellH - 1));
    end;
    Inc(Row);
  end;

  // Поля окна Shift+F1: подпись, справа - поле ввода (бирюзовое) или
  // значения выбора (выбранное - бирюзовым, с фокусом - белым по чёрному)
  FDlgRowsTop := Row;
  FDlgRowsLeft := InnerLeft + FarDlgCaptionW;
  for LineIndex := 0 to High(FDlgRows) do
  begin
    DrawDialogRow(LineIndex, Row, InnerLeft, InnerW, Fore, Back);
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
  // Из архива: F5 - распаковать; F6, Shift+F5, Shift+F6 - нельзя
  if ActivePanel.IsArchive then
  begin
    if AMove or ACurrentOnly then
      ArcBlocked
    else
      StartArcExtract;
    Exit;
  end;
  if not ACurrentOnly and FPanels[1 - FActive].IsArchive then
  begin
    Status(FarProduct + ': упаковка в архив - позже (Shift+F1)');
    Exit;
  end;
  // F5 на файлы адресов FAR Manager (FTP-плагин) в список адресов FTP
  // другой панели - добавить адреса
  if not ACurrentOnly and not AMove and not ActivePanel.IsFtp and
     (FPanels[1 - FActive].FFtpMode = 1) then
  begin
    FtpImportHosts;
    Exit;
  end;
  if not ACurrentOnly and FPanels[1 - FActive].IsFtp then
  begin
    Status(FarProduct + ': копирование на FTP - следующим шагом');
    Exit;
  end;
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

// ---------------------------------------------------------------------------
//  F4 / Shift+F4: файл - в редактор unIDE (OnEditFile, делает Unit1)
// ---------------------------------------------------------------------------

procedure TFarView.EditCurrent;
var
  Panel: TFarPanel;
begin
  Panel := ActivePanel;
  if (Panel.Count = 0) or (Panel.Cursor < 0) or
     (Panel.Cursor >= Panel.Count) then
    Exit;
  if ArcBlocked then
    Exit;
  // Папку F4 не открывает (так в FAR)
  if Panel.FItems[Panel.Cursor].IsDir then
    Exit;
  OpenEditor(Panel.Path + Panel.FItems[Panel.Cursor].Name);
end;

procedure TFarView.StartEditNew;
begin
  if ArcBlocked or (ActivePanel.Path = '') then
    Exit;
  DlgOpen(fdEditNew, 'Editor', ['File to edit:'], False, False, True, '',
    ['OK', 'Cancel']);
end;

// Shift+F4: есть файл - открыть; нет - создать пустой (и недостающие
// папки) и открыть
procedure TFarView.DoEditNew(const AName: WideString);
var
  Name, FullPath, FileDir, FileName: WideString;
  FileHandle: THandle;
  Created: Boolean;
  ItemIndex: Integer;
begin
  Name := FarTrimW(AName);
  if Name = '' then
    Exit;
  FullPath := FarFullPath(ActivePanel.Path, Name);
  if FarDirExists(FullPath) then
  begin
    Status(FarProduct + ': это папка: ' + FullPath);
    Exit;
  end;
  Created := False;
  if FarGetAttributes(PWideChar(FullPath)) = FarInvalidAttr then
  begin
    FarSplitPath(FullPath, FileDir, FileName);
    if (FileDir <> '') and not FarForceDirs(FileDir) then
    begin
      Status(FarProduct + ': папку не создать: ' + SysErrorMessage(GetLastError));
      Exit;
    end;
    FileHandle := FarCreateFile(PWideChar(FullPath), GENERIC_WRITE, 0, nil,
      CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);
    if FileHandle = INVALID_HANDLE_VALUE then
    begin
      Status(FarProduct + ': файл не создать: ' + SysErrorMessage(GetLastError));
      Exit;
    end;
    CloseHandle(FileHandle);
    Created := True;
    // Новый файл в той же папке - курсор на него
    if FarSameName(FileDir, ActivePanel.Path) then
    begin
      ActivePanel.Reread;
      ItemIndex := ActivePanel.IndexOfName(FileName);
      if ItemIndex >= 0 then
        ActivePanel.Cursor := ItemIndex;
      EnsureVisible(ActivePanel);
      Invalidate;
    end;
  end;
  OpenEditor(FullPath);
end;

procedure TFarView.SetSingle(APanel: Integer);
begin
  if (APanel < -1) or (APanel > 1) then
    APanel := -1;
  FSingle := APanel;
  if APanel >= 0 then
    FActive := APanel;
  UpdateGrid;
  Invalidate;
end;

function TFarView.ActiveIndex: Integer;
begin
  Result := FActive;
end;

procedure TFarView.ShowFolder(const APath: WideString);
begin
  if (APath = '') or not FarDirExists(APath) then
    Exit;
  if ActivePanel.IsFtp or ActivePanel.IsArchive or EditorShown(FActive) then
    FActive := 1 - FActive;
  ChangeDir(ActivePanel, FarWithSlash(APath), '');
  Invalidate;
end;

procedure TFarView.ShowFile(const AFileName: WideString);
var
  FileDir, FileName: WideString;
  Panel: TFarPanel;
  ItemIndex: Integer;
begin
  FarSplitPath(AFileName, FileDir, FileName);
  if (FileDir = '') or (FileName = '') then
    Exit;
  Panel := ActivePanel;
  // Панель на FTP - остаётся на нём
  if Panel.IsFtp then
    Exit;
  if not Panel.IsArchive and
     FarSameName(FarWithSlash(FileDir), Panel.Path) then
  begin
    ItemIndex := Panel.IndexOfName(FileName);
    if ItemIndex < 0 then
    begin
      Panel.Reread;
      ItemIndex := Panel.IndexOfName(FileName);
    end;
    if ItemIndex >= 0 then
      Panel.Cursor := ItemIndex;
    EnsureVisible(Panel);
    Invalidate;
  end
  else if FarDirExists(FileDir) then
    ChangeDir(Panel, FileDir, FileName);
end;

procedure TFarView.StartMkDir;
begin
  if ArcBlocked or (ActivePanel.Path = '') then
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
  if ArcBlocked then
    Exit;
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
  ResultCode: Integer;
begin
  FillChar(ShellOp, SizeOf(ShellOp), 0);
  ShellOp.Wnd := GetParentFormHandle;
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
    Status(FarProduct + ': операция не выполнена (код ' +
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
        Status(FarProduct + ': нельзя копировать файл сам в себя');
      Exit;
    end;
    // Папку нельзя копировать или переносить внутрь неё самой
    for NameIndex := 0 to High(FDlgNames) do
      if FarSameName(Copy(TargetDir, 1,
           Length(Source.Path + FDlgNames[NameIndex]) + 1),
           Source.Path + FDlgNames[NameIndex] + '\') then
      begin
        Status(FarProduct + ': нельзя копировать или переносить папку в саму себя');
        Exit;
      end;
    if not FarForceDirs(TargetDir) then
    begin
      Status(FarProduct + ': папку не создать: ' + SysErrorMessage(GetLastError));
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
        Status(FarProduct + ': нельзя копировать файл сам в себя');
      Exit;
    end;
    FarSplitPath(Target, SourceDir, TargetName);
    if (SourceDir <> '') and not FarForceDirs(SourceDir) then
    begin
      Status(FarProduct + ': папку не создать: ' + SysErrorMessage(GetLastError));
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
    Status(FarProduct + ': папку не создать: ' + SysErrorMessage(GetLastError));
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
  // Ответ сервера FTP
  FtpCheck;
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
    until not MenuSkip(Target) or (Target = FMenuCursor);
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
    while MenuSkip(Target) and (Target + Step >= 0) and
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
  // Правила раскраски: Ins, Del, пробел, F4, Ctrl+стрелки
  if (FMenuKind = fmHiRules) and HiRulesKey(AKey, AShift, ACtrl, AAlt) then
    Exit;
  // Элементы палитры: Del - стандартный цвет
  if (FMenuKind = fmPalItems) and (AKey = VK_DELETE) and
     (FMenuCursor >= 0) and (FMenuCursor <= High(FMenuItems)) then
  begin
    PalItemDefault(TFarPalItem(FMenuItems[FMenuCursor].Tag));
    Exit;
  end;
  case AKey of
    VK_ESCAPE, VK_F10:
      // Элементы палитры - обратно в группы
      if (AKey = VK_ESCAPE) and (FMenuKind = fmPalItems) then
        ShowPalGroups(FarPalGroupIndex(FPalGroupFirst))
      else
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
    VK_INSERT:
      // История папок: Ins - закрепить / открепить папку
      if (FMenuKind = fmHistory) and (FMenuCursor >= 0) and
         (FMenuCursor <= High(FMenuItems)) then
      begin
        HistoryIndex := HistoryFind(FMenuItems[FMenuCursor].Data);
        if HistoryIndex >= 0 then
        begin
          FHistoryLock[HistoryIndex] := not FHistoryLock[HistoryIndex];
          if FHistoryLock[HistoryIndex] then
            FMenuItems[FMenuCursor].Mark := FarCheckMark
          else
            FMenuItems[FMenuCursor].Mark := ' ';
          Invalidate;
        end;
      end;
    VK_DELETE:
      // История папок: Shift+Del - убрать папку под курсором (кроме
      // закреплённой), Del - очистить историю, закреплённые остаются
      if (FMenuKind = fmHistory) and AShift and (FMenuCursor >= 0) and
         (FMenuCursor <= High(FMenuItems)) then
      begin
        HistoryIndex := HistoryFind(FMenuItems[FMenuCursor].Data);
        if (HistoryIndex >= 0) and FHistoryLock[HistoryIndex] then
          Status(FarProduct + ': папка закреплена (Ins - открепить)')
        else
        begin
          if HistoryIndex >= 0 then
            HistoryDelete(HistoryIndex);
          for ItemIndex := FMenuCursor to High(FMenuItems) - 1 do
            FMenuItems[ItemIndex] := FMenuItems[ItemIndex + 1];
          SetLength(FMenuItems, Length(FMenuItems) - 1);
          if Length(FMenuItems) = 0 then
            MenuClose
          else if FMenuCursor > High(FMenuItems) then
            FMenuCursor := High(FMenuItems);
          Invalidate;
        end;
      end
      else if (FMenuKind = fmHistory) and not ACtrl and not AAlt then
      begin
        HistoryIndex := High(FHistoryLock);
        while (HistoryIndex >= 0) and FHistoryLock[HistoryIndex] do
          Dec(HistoryIndex);
        if HistoryIndex < 0 then
          Status(FarProduct + ': в истории только закреплённые папки')
        else
        begin
          FHiDelIdx := FMenuCursor;
          MenuClose;
          DlgOpen(fdHistClear, 'Folders history',
            ['Clear folders history?', 'Locked folders will be kept'],
            True, True, False, '', ['Clear', 'Cancel']);
        end;
      end;
  else
    // Буква - пункт с этой буквой быстрого выбора
    if not ACtrl and not AAlt and
       (((AKey >= Ord('A')) and (AKey <= Ord('Z'))) or
        ((AKey >= Ord('0')) and (AKey <= Ord('9')))) then
      for ItemIndex := 0 to High(FMenuItems) do
      begin
        if MenuSkip(ItemIndex) then
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
  Pal: TFarPalette;
begin
  if (AIndex < 0) or (AIndex > High(FMenuItems)) then
    Exit;
  Item := FMenuItems[AIndex];
  if Item.Separator or Item.Disabled then
    Exit;
  Kind := FMenuKind;
  PanelIndex := FMenuPanel;
  MenuClose;
  case Kind of
    fmDrive:
      // Буква - смена диска; путь (том без буквы, подключённый в папку) -
      // в эту папку
      if Item.Data = FarFtpMenuData then
        OpenFtpHosts(PanelIndex)
      else if Length(Item.Data) = 1 then
        SelectDrive(PanelIndex, Item.Data[1])
      else if (Item.Data <> '') and FarDirExists(Item.Data) then
        ChangeDir(FPanels[PanelIndex], Item.Data, '');
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
        Status(FarProduct + ': папки нет: ' + Item.Data);
    fmOptions:
      // Окна unIDE (VCL), если заданы; иначе свои (uniFAR)
      case Item.Tag of
        1:
          if Assigned(FOnColorsDialog) then
            FOnColorsDialog(Self)
          else
            ShowHiRules(0);
        2:
          SaveSetup;
        3:
          if Assigned(FOnPaletteDialog) then
            FOnPaletteDialog(Self)
          else
            ShowPalGroups(0);
        4:
          ShowThemesMenu;
      end;
    fmPalGroups:
      if Item.Tag >= 0 then
        ShowPalItems(TFarPalItem(Item.Tag), TFarPalItem(Item.Tag))
      else
      begin
        // Default colors: вся палитра - стандартная
        FarPaletteDefault(Pal);
        SetPalette(Pal);
        if FIniName <> '' then
          FarPaletteSave(FIniName, Pal);
        Status(FarProduct + ': палитра - стандартные цвета');
        ShowPalGroups(0);
      end;
    fmPalItems:
      PalItemChoose(TFarPalItem(Item.Tag));
    fmThemes:
      if Item.Tag = 100 then
        ThemeImport
      else if FarThemePalette(Item.Tag, Pal) then
        ApplyTheme(FarThemeNames[Item.Tag], Pal);
    fmHiRules:
      PickOpenRule(Item.Tag);
  end;
  Invalidate;
end;

function TFarView.MenuSkip(AIndex: Integer): Boolean;
begin
  Result := (AIndex < 0) or (AIndex > High(FMenuItems)) or
            FMenuItems[AIndex].Separator or FMenuItems[AIndex].Disabled;
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
  if MenuSkip(Result) then
    Result := -1;
end;

procedure TFarView.DrawMenu;
var
  ItemIndex, RowIndex, MaxW, ItemW, BoxW, BoxH, AreaX, AreaW, RowY: Integer;
  TextW, HotPos, SepY: Integer;
  Item: TFarMenuItem;
  ItemText: WideString;
  Back, Fore, HotFore, SampleFore, SampleBack: TColor;
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
    FillCells(FMenuLeft, RowIndex, BoxW, FPal[fpMenuBack]);
  DrawBox(FMenuLeft, FMenuTopRow, FMenuLeft + BoxW - 1,
    FMenuTopRow + BoxH - 1, FPal[fpMenuFrame]);
  PutCentered(FMenuLeft, FMenuTopRow, BoxW, ' ' + FMenuTitle + ' ',
    FPal[fpMenuFrame], FPal[fpMenuBack]);
  // Пункты выше / ниже видимых - стрелки на рамке
  if FMenuTop > 0 then
    PutText(FMenuLeft + BoxW - 2, FMenuTopRow, 1, '^', FPal[fpMenuHotkey],
      FPal[fpMenuBack]);
  if FMenuTop + FMenuRows < Length(FMenuItems) then
    PutText(FMenuLeft + BoxW - 2, FMenuTopRow + BoxH - 1, 1, 'v',
      FPal[fpMenuHotkey], FPal[fpMenuBack]);

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
        Pen.Color := FPal[fpMenuFrame];
        MoveTo(FMenuLeft * FCellW + FCellW div 2 + 2, SepY);
        LineTo((FMenuLeft + BoxW - 1) * FCellW + FCellW div 2 - 1, SepY);
      end;
      Continue;
    end;
    Fore := FPal[fpMenuText];
    HotFore := FPal[fpMenuHotkey];
    if Item.Disabled then
    begin
      Fore := FPal[fpMenuDisabled];
      HotFore := FPal[fpMenuDisabled];
    end;
    if ItemIndex = FMenuCursor then
      Back := FPal[fpMenuCursorBack]
    else
      Back := FPal[fpMenuBack];
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
    // Образец цвета: текст пункта - его цветами
    if Item.HasColors then
    begin
      SampleFore := Item.Fore;
      SampleBack := Item.Back;
      if SampleFore = clNone then
        SampleFore := FPal[fpPanelText];
      // Правило на фоне панели - читаемым, как в панели (RuleColors)
      if SampleBack = clNone then
      begin
        SampleBack := FPal[fpPanelBack];
        SampleFore := FarReadable(SampleFore, SampleBack);
      end;
      PutText(FMenuLeft + 4, RowY, Length(ItemText), ItemText, SampleFore,
        SampleBack);
    end;
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

procedure TFarView.AltPanelKey(APanelIndex: Integer);
begin
  FEatAltUp := True;
  // В этой панели редактор - смены диска нет
  if EditorShown(APanelIndex) then
  begin
    Status(FarProduct + ': в этой панели редактор - сначала закройте его (Esc)');
    Exit;
  end;
  if (FSingle >= 0) and (APanelIndex <> FSingle) then
  begin
    if Assigned(FOnShowPanels) then
      FOnShowPanels(Self)
    else
    begin
      SetSingle(-1);
      Invalidate;
    end;
    Exit;
  end;
  ShowDriveMenu(APanelIndex);
end;

type
  // Строка меню дисков: том с буквой
  TFarDriveRow = record
    Letter: WideString;
    DriveIndex: Integer;
    TypeText, FileSys, VolumeLabel, SizeText, FreeText: WideString;
    Device: TFarDeviceNumber;
    Model: WideString;
  end;

function FarPadLeft(const AText: WideString; AWidth: Integer): WideString;
begin
  Result := AText;
  while Length(Result) < AWidth do
    Result := ' ' + Result;
end;

// Меню дисков (Alt+F1 / Alt+F2), как в FAR: буква, диск и раздел ('0:2'),
// тип, файловая система, метка, размер, свободно, модель диска. Ниже -
// тома без буквы (системные, скрытые разделы): только для сведений, том,
// подключённый в папку, - выбирается (переход в папку). В конце -
// физические диски: номер, модель, шина, размер, буквы на нём.
// Всё - запросами к устройствам (FarVolumes), без diskpart.
// Метка, ФС и размер - у жёстких, RAM-дисков и сменных (кроме A: и B:):
// у дисководов, CD и сетевых чтение может ждать устройство или сеть
procedure TFarView.ShowDriveMenu(APanelIndex: Integer);
var
  Items: TFarMenuItems;
  Rows: array of TFarDriveRow;
  Row: TFarDriveRow;
  DriveMask: DWORD;
  DriveIndex, CurrentDrive, CursorIndex, VolIdx, RowIdx, DiskIdx: Integer;
  ModelW, DiskModelW: Integer;
  Root, DiskText, SizeText, LettersText: WideString;
  LabelBuffer, FsBuffer: array[0..MAX_PATH] of WideChar;
  DriveType: UINT;
  OldMode: UINT;
  FreeAvail, TotalBytes, TotalFree: Int64;
  NoLetter: TFarVolumes;
  NoLetterModels: array of WideString;
  Disks: TFarDisks;
  DisksError: DWORD;
  CdInfo: TFarDisk;

  procedure AddItem(const AText, ARight, AData: WideString;
    ADisabled: Boolean; ATag: Integer);
  begin
    SetLength(Items, Length(Items) + 1);
    Items[High(Items)].Text := AText;
    Items[High(Items)].RightText := ARight;
    Items[High(Items)].Mark := ' ';
    Items[High(Items)].Separator := False;
    Items[High(Items)].Disabled := ADisabled;
    Items[High(Items)].Data := AData;
    Items[High(Items)].Tag := ATag;
  end;

  procedure AddSeparator;
  begin
    SetLength(Items, Length(Items) + 1);
    Items[High(Items)].Text := '';
    Items[High(Items)].RightText := '';
    Items[High(Items)].Mark := ' ';
    Items[High(Items)].Separator := True;
    Items[High(Items)].Disabled := True;
    Items[High(Items)].Data := '';
    Items[High(Items)].Tag := -1;
  end;

  // Строка тома: колонки одной ширины у всех строк и у заголовка
  function Columns(const ADisk, AType, AFs, ALabel, ASize, AFree,
    AModel: WideString): WideString;
  begin
    Result := FarPadRight(ADisk, 5) + ' ' + FarPadRight(AType, 10) + ' ' +
      FarPadRight(AFs, 6) + ' ' + FarPadRight(FarFitName(ALabel, 12), 12) +
      ' ' + FarPadLeft(ASize, 9) + ' ' + FarPadLeft(AFree, 9) + '  ' +
      FarPadRight(FarFitName(AModel, ModelW), ModelW);
  end;

  // Модель диска, на котором том (CD - модель самого привода)
  function DeviceModel(const ADevice: TFarDeviceNumber;
    const ADevicePath: WideString): WideString;
  var
    FoundIdx: Integer;
  begin
    Result := '';
    if not ADevice.Valid then
      Exit;
    if ADevice.DeviceType = FarDeviceDisk then
    begin
      FoundIdx := FarFindDisk(Disks, ADevice.DiskNumber);
      if FoundIdx >= 0 then
        Result := Disks[FoundIdx].Model;
    end
    else if (ADevice.DeviceType = FarDeviceCdRom) or
            (ADevice.DeviceType = FarDeviceDvd) then
    begin
      if FarDeviceInfo(ADevicePath, False, CdInfo) then
        Result := CdInfo.Model;
    end;
  end;

  procedure WidenModel(const AModel: WideString; var AWidth: Integer);
  begin
    if Length(AModel) > AWidth then
      AWidth := Length(AModel);
  end;

begin
  CurrentDrive := FarDriveIndex(FPanels[APanelIndex].Path);
  CursorIndex := -1;
  SetLength(Items, 0);
  SetLength(Rows, 0);
  DriveMask := GetLogicalDrives;
  // Нет диска в дисководе - без окна Windows с ошибкой
  OldMode := FarSetErrorMode(FarSemFailCritical);
  try
    DisksError := FarPhysicalDisks(Disks);
    for DriveIndex := 0 to 25 do
    begin
      if DriveMask and (DWORD(1) shl DriveIndex) = 0 then
        Continue;
      // Delphi 7 не складывает символ-литерал с WideChar - буква отдельной
      // строкой
      Row.Letter := WideChar(Ord('A') + DriveIndex);
      Row.DriveIndex := DriveIndex;
      Root := Row.Letter + ':\';
      DriveType := FarGetDriveType(PWideChar(Root));
      case DriveType of
        FarDriveRemovable: Row.TypeText := 'removable';
        FarDriveFixed: Row.TypeText := 'fixed';
        FarDriveRemote: Row.TypeText := 'network';
        FarDriveCdRom: Row.TypeText := 'CD-ROM';
        FarDriveRamDisk: Row.TypeText := 'RAM disk';
      else
        Row.TypeText := '';
      end;
      Row.VolumeLabel := '';
      Row.FileSys := '';
      Row.SizeText := '';
      Row.FreeText := '';
      if (DriveType = FarDriveFixed) or (DriveType = FarDriveRamDisk) or
         ((DriveType = FarDriveRemovable) and (DriveIndex >= 2)) then
      begin
        LabelBuffer[0] := #0;
        FsBuffer[0] := #0;
        if FarGetVolumeInfo(PWideChar(Root), LabelBuffer, MAX_PATH, nil, nil,
             nil, FsBuffer, MAX_PATH) then
        begin
          Row.VolumeLabel := PWideChar(@LabelBuffer[0]);
          Row.FileSys := PWideChar(@FsBuffer[0]);
        end;
        if FarDiskFree(PWideChar(Root), @FreeAvail, @TotalBytes,
           @TotalFree) then
        begin
          Row.SizeText := FarSizeShort(TotalBytes);
          Row.FreeText := FarSizeShort(TotalFree);
        end;
      end;
      // Диск и раздел: сетевые и дисководы A:, B: не спрашиваем
      Row.Model := '';
      if (DriveType = FarDriveFixed) or (DriveType = FarDriveRamDisk) or
         (DriveType = FarDriveCdRom) or
         ((DriveType = FarDriveRemovable) and (DriveIndex >= 2)) then
      begin
        FarDeviceNumber('\\.\' + Row.Letter + ':', Row.Device);
        Row.Model := DeviceModel(Row.Device, '\\.\' + Row.Letter + ':');
      end
      else
      begin
        Row.Device.Valid := False;
        Row.Device.DeviceType := 0;
        Row.Device.DiskNumber := -1;
        Row.Device.PartNumber := -1;
      end;
      SetLength(Rows, Length(Rows) + 1);
      Rows[High(Rows)] := Row;
    end;
    FarNoLetterVolumes(NoLetter);
  finally
    FarSetErrorMode(OldMode);
  end;
  SetLength(NoLetterModels, Length(NoLetter));
  for VolIdx := 0 to High(NoLetter) do
    NoLetterModels[VolIdx] := DeviceModel(NoLetter[VolIdx].Device, '');
  // Ширина колонки 'Модель' - по самой длинной, не больше 28
  ModelW := Length('Модель');
  for RowIdx := 0 to High(Rows) do
    WidenModel(Rows[RowIdx].Model, ModelW);
  for VolIdx := 0 to High(NoLetterModels) do
    WidenModel(NoLetterModels[VolIdx], ModelW);
  if ModelW > 28 then
    ModelW := 28;
  AddItem('    ' + Columns('Диск', 'Тип', 'ФС', 'Метка', 'Размер', 'Свободно',
    'Модель'), '', '', True, -1);
  for RowIdx := 0 to High(Rows) do
  begin
    Row := Rows[RowIdx];
    AddItem(WideString('&') + Row.Letter + ':  ' + FarEscapeAmp(Columns(
      FarDeviceText(Row.Device), Row.TypeText, Row.FileSys, Row.VolumeLabel,
      Row.SizeText, Row.FreeText, Row.Model)), '', Row.Letter, False,
      Row.DriveIndex);
    if (Row.DriveIndex = CurrentDrive) or (CursorIndex < 0) then
      CursorIndex := High(Items);
  end;
  // Тома без буквы
  for VolIdx := 0 to High(NoLetter) do
  begin
    if VolIdx = 0 then
      AddSeparator;
    AddItem('    ' + FarEscapeAmp(Columns(FarDeviceText(NoLetter[VolIdx].Device),
      'no letter', NoLetter[VolIdx].FileSys, NoLetter[VolIdx].VolLabel,
      NoLetter[VolIdx].SizeText, FarSizeShort(NoLetter[VolIdx].Free),
      NoLetterModels[VolIdx])), NoLetter[VolIdx].MountPath,
      NoLetter[VolIdx].MountPath, NoLetter[VolIdx].MountPath = '', -1);
  end;
  // FTP - как плагин FTP в FAR
  AddSeparator;
  if Length(FFtpHosts) > 0 then
    AddItem('    FTP', 'адресов: ' + WideString(IntToStr(Length(FFtpHosts))),
      FarFtpMenuData, False, -1)
  else
    AddItem('    FTP', '', FarFtpMenuData, False, -1);
  // Физические диски: номер, модель, шина, размер, буквы томов на нём
  if Length(Disks) > 0 then
  begin
    AddSeparator;
    DiskModelW := 6;
    for DiskIdx := 0 to High(Disks) do
      WidenModel(Disks[DiskIdx].Model, DiskModelW);
    if DiskModelW > 40 then
      DiskModelW := 40;
    for DiskIdx := 0 to High(Disks) do
    begin
      if Disks[DiskIdx].HasSize then
        SizeText := FarSizeShort(Disks[DiskIdx].Size)
      else if Disks[DiskIdx].Removable then
        SizeText := 'нет носителя'
      else
        SizeText := '';
      LettersText := '';
      for RowIdx := 0 to High(Rows) do
        if Rows[RowIdx].Device.Valid and
           (Rows[RowIdx].Device.DeviceType = FarDeviceDisk) and
           (Rows[RowIdx].Device.DiskNumber = Disks[DiskIdx].Number) then
          LettersText := LettersText + ' ' + Rows[RowIdx].Letter + ':';
      DiskText := 'Диск ' + IntToStr(Disks[DiskIdx].Number);
      AddItem('    ' + FarEscapeAmp(FarPadRight(DiskText, 8) + ' ' +
        FarPadRight(FarFitName(Disks[DiskIdx].Model, DiskModelW), DiskModelW) +
        '  ' + FarPadRight(Disks[DiskIdx].BusText, 7) +
        FarPadLeft(SizeText, 12) + ' ' + LettersText), '', '', True, -1);
    end;
  end
  else if DisksError <> 0 then
    AddItem('    Физические диски: ' + WideString(SysErrorMessage(DisksError)),
      '', '', True, -1);
  MenuOpen(fmDrive, 'Change drive', Items, CursorIndex, APanelIndex);
end;

// ---------------------------------------------------------------------------
//  FTP (пункт FTP в меню дисков). Панель на FTP - два режима:
//  FFtpMode = 1 - список адресов (Host | Home | User): Enter - войти,
//  Shift+F4 - новый адрес, F4 - изменить, F8 / Del - удалить, '..' -
//  обратно в папку панели; FFtpMode = 2 - папка сервера: Enter на папке -
//  войти, '..' - выше, из корня - к списку адресов, Ctrl+R - перечитать.
//  Сеть - в потоке TFarFtpThread (FarFtp), ответ забирает WatchTick
//  (FtpCheck). Пока поток идёт, соединение у него (панель - без него);
//  панель ушла с FTP за это время (FFtpSession другой) - ответ
//  отбрасывается, соединение закрывается.
//  Копирование, папки, удаление на сервере - следующим шагом.
// ---------------------------------------------------------------------------

procedure FarEmptyItem(var AItem: TFarItem);
begin
  AItem.Name := '';
  AItem.FtpRaw := '';
  AItem.Size := 0;
  AItem.Attr := 0;
  FillChar(AItem.WriteTime, SizeOf(TFileTime), 0);
  FillChar(AItem.CreateTime, SizeOf(TFileTime), 0);
  FillChar(AItem.AccessTime, SizeOf(TFileTime), 0);
  AItem.OrigIndex := -1;
  AItem.IsDir := False;
  AItem.IsUp := False;
  AItem.Selected := False;
end;

// Текст по словам в строки шириной AWidth (для окон)
function FarWrapText(const AText: WideString; AWidth: Integer): TFarNames;
var
  Rest: WideString;
  Cut, Count: Integer;
begin
  Result := nil;
  Count := 0;
  Rest := FarTrimW(AText);
  while Rest <> '' do
  begin
    if Length(Rest) <= AWidth then
      Cut := Length(Rest)
    else
    begin
      Cut := AWidth;
      while (Cut > AWidth div 2) and (Rest[Cut + 1] <> ' ') do
        Dec(Cut);
      if Rest[Cut + 1] <> ' ' then
        Cut := AWidth;
    end;
    SetLength(Result, Count + 1);
    Result[Count] := FarTrimW(Copy(Rest, 1, Cut));
    Inc(Count);
    Rest := FarTrimW(Copy(Rest, Cut + 1, MaxInt));
  end;
end;

function TFarPanel.IsFtp: Boolean;
begin
  Result := FFtpMode <> 0;
end;

// Панель уходит с FTP (или в список адресов): соединение закрыть, ответ
// идущего потока - отбросить (FFtpSession)
procedure TFarPanel.FtpLeave;
begin
  Inc(FFtpSession);
  FFtpConn.Free;
  FFtpConn := nil;
  FFtpMode := 0;
  FFtpDir := '';
end;

// Адрес для колонки Host: 'host' или 'host:port'
function FarFtpHostText(const AHost: TFarFtpHost): WideString;
begin
  Result := WideString(AHost.Host);
  if (AHost.Port > 0) and (AHost.Port <> FarFtpDefaultPort) then
    Result := Result + ':' + WideString(IntToStr(AHost.Port));
end;

// Ширина колонок списка адресов: Host | Home | User
procedure TFarView.FtpHostColumns(AWidth: Integer; var AHostW, AHomeW,
  AUserW: Integer);
var
  Inner: Integer;
begin
  Inner := AWidth - 2;
  AHostW := Inner * 30 div 100;
  AUserW := Inner * 22 div 100;
  AHomeW := Inner - AHostW - AUserW - 2;
  if AHomeW < 0 then
    AHomeW := 0;
end;

// Колонок имён у панели: в списке адресов - одна строка на адрес
function TFarView.PanelColumns(APanel: TFarPanel): Integer;
begin
  if APanel.FFtpMode = 1 then
    Result := 1
  else
    Result := 2;
end;

// Список адресов в панели; курсор - на адрес AFocusIdx (-1 - на '..')
procedure TFarView.FtpFillHosts(APanel: TFarPanel; AFocusIdx: Integer);
var
  NewItems: TFarItems;
  HostIdx, ItemIdx: Integer;
begin
  if APanel.FFtpMode <> 1 then
  begin
    APanel.FtpLeave;
    APanel.FFtpMode := 1;
  end;
  SetLength(NewItems, Length(FFtpHosts) + 1);
  FarEmptyItem(NewItems[0]);
  NewItems[0].Name := '..';
  NewItems[0].IsUp := True;
  NewItems[0].IsDir := True;
  NewItems[0].Attr := FILE_ATTRIBUTE_DIRECTORY;
  for HostIdx := 0 to High(FFtpHosts) do
  begin
    FarEmptyItem(NewItems[HostIdx + 1]);
    NewItems[HostIdx + 1].Name := FarFtpHostText(FFtpHosts[HostIdx]);
    NewItems[HostIdx + 1].OrigIndex := HostIdx;
  end;
  APanel.FItems := NewItems;
  APanel.FCount := Length(NewItems);
  APanel.SortItems;
  APanel.FFileCount := Length(FFtpHosts);
  APanel.FFileBytes := 0;
  APanel.FFreeKnown := False;
  APanel.FCursor := 0;
  APanel.FTopIndex := 0;
  for ItemIdx := 0 to APanel.FCount - 1 do
    if (AFocusIdx >= 0) and (APanel.FItems[ItemIdx].OrigIndex = AFocusIdx) and
       not APanel.FItems[ItemIdx].IsUp then
      APanel.FCursor := ItemIdx;
  EnsureVisible(APanel);
  Invalidate;
end;

// Папка сервера в панели; курсор - на имя AFocusRaw (байтами сервера)
procedure TFarView.FtpFillEntries(APanel: TFarPanel;
  const AEntries: TFarFtpEntries; const AFocusRaw: string);
var
  NewItems: TFarItems;
  EntryIdx, ItemIdx: Integer;
begin
  SetLength(NewItems, Length(AEntries) + 1);
  FarEmptyItem(NewItems[0]);
  NewItems[0].Name := '..';
  NewItems[0].IsUp := True;
  NewItems[0].IsDir := True;
  NewItems[0].Attr := FILE_ATTRIBUTE_DIRECTORY;
  for EntryIdx := 0 to High(AEntries) do
    with NewItems[EntryIdx + 1] do
    begin
      FarEmptyItem(NewItems[EntryIdx + 1]);
      Name := AEntries[EntryIdx].Name;
      FtpRaw := AEntries[EntryIdx].Raw;
      IsDir := AEntries[EntryIdx].IsDir;
      if IsDir then
        Attr := FILE_ATTRIBUTE_DIRECTORY
      else
        Attr := FILE_ATTRIBUTE_NORMAL;
      Size := AEntries[EntryIdx].Size;
      WriteTime := AEntries[EntryIdx].Time;
      CreateTime := AEntries[EntryIdx].Time;
      AccessTime := AEntries[EntryIdx].Time;
      OrigIndex := EntryIdx;
    end;
  APanel.FItems := NewItems;
  APanel.FCount := Length(NewItems);
  APanel.FFtpMode := 2;
  APanel.SortItems;
  APanel.FFileCount := 0;
  APanel.FFileBytes := 0;
  for ItemIdx := 0 to APanel.FCount - 1 do
    if not APanel.FItems[ItemIdx].IsDir then
    begin
      Inc(APanel.FFileCount);
      Inc(APanel.FFileBytes, APanel.FItems[ItemIdx].Size);
    end;
  APanel.FFreeKnown := False;
  APanel.FCursor := 0;
  APanel.FTopIndex := 0;
  if AFocusRaw <> '' then
    for ItemIdx := 0 to APanel.FCount - 1 do
      if not APanel.FItems[ItemIdx].IsUp and
         (APanel.FItems[ItemIdx].FtpRaw = AFocusRaw) then
        APanel.FCursor := ItemIdx;
  EnsureVisible(APanel);
  Invalidate;
end;

// Пункт FTP в меню дисков: список адресов в панели
procedure TFarView.OpenFtpHosts(APanelIndex: Integer);
var
  Panel: TFarPanel;
begin
  Panel := FPanels[APanelIndex];
  // Из архива - сначала в папку архива: обычный режим панели
  if Panel.IsArchive then
    ChangeDir(Panel, Panel.Path, '');
  if Panel.IsArchive then
    Exit;
  Panel.FtpLeave;
  FtpFillHosts(Panel, -1);
  if Length(FFtpHosts) = 0 then
    Status(FarProduct + ': FTP - адресов нет: Shift+F4 - новый адрес')
  else
    Status(FarProduct + ': FTP - Enter - войти, Shift+F4 - новый адрес, F4 - ' +
      'изменить, F8 - удалить');
end;

// Выйти с FTP - в папку, где панель была до него
procedure TFarView.FtpExit(APanel: TFarPanel);
var
  ErrorText: string;
begin
  APanel.FtpLeave;
  if not APanel.ReadDir(APanel.Path, '', ErrorText) then
    APanel.ReadDir(FarRootOf(APanel.Path), '', ErrorText);
  EnsureVisible(APanel);
  Invalidate;
end;

// Окно с ошибкой FTP
procedure TFarView.FtpError(const ATitle, AText: WideString);
var
  Lines, Wrapped: TFarNames;
  LineIdx: Integer;
begin
  SetLength(Lines, 1);
  Lines[0] := ATitle;
  Wrapped := FarWrapText(AText, 58);
  for LineIdx := 0 to High(Wrapped) do
  begin
    SetLength(Lines, Length(Lines) + 1);
    Lines[High(Lines)] := Wrapped[LineIdx];
  end;
  DlgOpen(fdFtpError, 'FTP', Lines, True, True, False, '', ['OK']);
  Status(FarProduct + ': FTP - ' + string(AText));
end;

// Запрос к серверу: перейти в ADir (байтами; '' - начальная папка адреса)
// и прочитать её; курсор - на AFocusRaw
procedure TFarView.FtpStartList(APanelIndex: Integer; const AHost: TFarFtpHost;
  AHostIdx: Integer; const ADir, AFocusRaw: string; AIsHome: Boolean);
var
  Panel: TFarPanel;
  Conn: TFarFtpConn;
begin
  Panel := FPanels[APanelIndex];
  if FFtpThread[APanelIndex] <> nil then
  begin
    Status(FarProduct + ': FTP - ждём ответа сервера (Esc - прервать)');
    Exit;
  end;
  Conn := Panel.FFtpConn;
  Panel.FFtpConn := nil;
  if Conn = nil then
    Conn := TFarFtpConn.Create;
  FFtpJobSession[APanelIndex] := Panel.FFtpSession;
  FFtpJobFocus[APanelIndex] := AFocusRaw;
  FFtpJobHost[APanelIndex] := AHost;
  FFtpJobHostIdx[APanelIndex] := AHostIdx;
  if Conn.Connected then
    Status(FarProduct + ': FTP - ' + string(FarFtpHostUrl(AHost)) +
      ': чтение папки...')
  else
    Status(FarProduct + ': FTP - соединение с ' + string(FarFtpHostUrl(AHost)) +
      '... (Esc - прервать)');
  FFtpThread[APanelIndex] := TFarFtpThread.Create(Conn, AHost, ADir,
    AIsHome);
  Invalidate;
end;

// Войти на адрес AHostIdx: «спрашивать пароль» - сначала окно пароля
procedure TFarView.FtpConnect(APanelIndex, AHostIdx: Integer);
var
  Host: TFarFtpHost;
begin
  if (AHostIdx < 0) or (AHostIdx > High(FFtpHosts)) then
    Exit;
  Host := FFtpHosts[AHostIdx];
  if Host.AskPassword and (Host.User <> '') then
  begin
    FFtpPassPanel := APanelIndex;
    FFtpPassHostIdx := AHostIdx;
    DlgOpen(fdFtpPassword, 'Password', ['Password for',
      FarFitName(FarFtpHostUrl(Host), 60)], True, False, True, '',
      ['OK', 'Cancel']);
    FDlgMasked := True;
    Exit;
  end;
  FtpStartList(APanelIndex, Host, AHostIdx, FarFtpEncode(Host.Home), '',
    True);
end;

procedure TFarView.FtpPasswordEntered(const APassword: WideString);
var
  Host: TFarFtpHost;
begin
  if (FFtpPassHostIdx < 0) or (FFtpPassHostIdx > High(FFtpHosts)) or
     (FFtpPassPanel < 0) or (FFtpPassPanel > 1) then
    Exit;
  if not FPanels[FFtpPassPanel].IsFtp then
    Exit;
  Host := FFtpHosts[FFtpPassHostIdx];
  Host.Password := APassword;
  FtpStartList(FFtpPassPanel, Host, FFtpPassHostIdx, FarFtpEncode(Host.Home),
    '', True);
end;

// Ответ потока FTP (WatchTick)
procedure TFarView.FtpCheck;
var
  PanelIndex: Integer;
  Thread: TFarFtpThread;
  Panel: TFarPanel;
begin
  for PanelIndex := 0 to 1 do
  begin
    Thread := FFtpThread[PanelIndex];
    if (Thread = nil) or not Thread.Finished then
      Continue;
    Thread.WaitFor;
    FFtpThread[PanelIndex] := nil;
    Panel := FPanels[PanelIndex];
    try
      if (Panel.FFtpSession <> FFtpJobSession[PanelIndex]) or
         not Panel.IsFtp then
        // Панель ушла с FTP, пока ждали ответа
        Thread.Conn.Free
      else if Thread.ErrorText <> '' then
      begin
        // На сервере - соединение остаётся (следующий запрос соединится
        // заново, если оно разорвано); из списка адресов - закрыть
        if Panel.FFtpMode = 2 then
          Panel.FFtpConn := Thread.Conn
        else
          Thread.Conn.Free;
        FtpError(FarFtpHostUrl(FFtpJobHost[PanelIndex]),
          WideString(Thread.ErrorText));
      end
      else
      begin
        Panel.FFtpConn := Thread.Conn;
        Panel.FFtpHost := FFtpJobHost[PanelIndex];
        Panel.FFtpHostIdx := FFtpJobHostIdx[PanelIndex];
        Panel.FFtpDir := Thread.CurDir;
        FtpFillEntries(Panel, Thread.Entries, FFtpJobFocus[PanelIndex]);
        if Thread.Warning <> '' then
          Status(FarProduct + ': FTP - ' + FarFtpDecode(Thread.Warning))
        else
          Status(FarProduct + ': FTP - ' + string(Panel.DisplayPath));
      end;
    finally
      Thread.Free;
    end;
    Invalidate;
  end;
end;

// '..' на сервере: папка выше; из корня - к списку адресов
procedure TFarView.FtpUp(APanelIndex: Integer);
var
  Panel: TFarPanel;
  ParentDir, ChildRaw: string;
  HostIdx: Integer;
begin
  Panel := FPanels[APanelIndex];
  ParentDir := FarFtpParent(Panel.FFtpDir, ChildRaw);
  if ParentDir = '' then
  begin
    HostIdx := Panel.FFtpHostIdx;
    Panel.FtpLeave;
    FtpFillHosts(Panel, HostIdx);
    Exit;
  end;
  FtpStartList(APanelIndex, Panel.FFtpHost, Panel.FFtpHostIdx, ParentDir,
    ChildRaw);
end;

// Enter в панели FTP
procedure TFarView.FtpEnter(APanelIndex: Integer);
var
  Panel: TFarPanel;
  Item: TFarItem;
begin
  Panel := FPanels[APanelIndex];
  if (Panel.Cursor < 0) or (Panel.Cursor >= Panel.Count) then
    Exit;
  Item := Panel.FItems[Panel.Cursor];
  if Panel.FFtpMode = 1 then
  begin
    if Item.IsUp then
      FtpExit(Panel)
    else
      FtpConnect(APanelIndex, Item.OrigIndex);
    Exit;
  end;
  if Item.IsUp then
    FtpUp(APanelIndex)
  else if Item.IsDir then
    FtpStartList(APanelIndex, Panel.FFtpHost, Panel.FFtpHostIdx,
      FarFtpJoin(Panel.FFtpDir, Item.FtpRaw), '')
  else
    Status(FarProduct + ': FTP - просмотр и копирование файлов - следующим ' +
      'шагом');
end;

// Окно адреса: AHostIdx - изменить, -1 - новый
procedure TFarView.FtpEditHost(APanelIndex, AHostIdx: Integer);
var
  Host: TFarFtpHost;
  Title: WideString;
begin
  if (AHostIdx >= 0) and (AHostIdx <= High(FFtpHosts)) then
  begin
    Host := FFtpHosts[AHostIdx];
    Title := 'Edit FTP address';
  end
  else
  begin
    AHostIdx := -1;
    FarFtpHostClear(Host);
    Title := 'New FTP address';
  end;
  FFtpEditIdx := AHostIdx;
  FFtpEditPanel := APanelIndex;
  DlgOpen(fdFtpEdit, Title, ['Address: host, host:port or',
    'ftp://user:password@host:port/dir'], False, False, False, '',
    ['Save', 'Connect', 'Cancel']);
  DlgAddRow('Address:', False, False, FarFtpHostText(Host), [], 0);
  DlgAddRow('Home:', False, False, Host.Home, [], 0);
  DlgAddRow('User:', False, False, Host.User, [], 0);
  DlgAddRow('Password:', False, True, Host.Password, [], 0);
  DlgAddRow('Comment:', False, False, Host.Description, [], 0);
  DlgAddCheck('Ask for password every time', Host.AskPassword);
  DlgAddCheck('Passive mode', Host.Passive);
  FDlgRow := 0;
end;

// [ Save ] / [ Connect ] в окне адреса
procedure TFarView.FtpEditConfirm(AConnect: Boolean);
var
  Host: TFarFtpHost;
  HostIdx, PanelIndex: Integer;
begin
  if Length(FDlgRows) < 7 then
    Exit;
  FarFtpHostClear(Host);
  Host.Home := FarTrimW(FDlgRows[1].Text);
  Host.User := FarTrimW(FDlgRows[2].Text);
  Host.Password := FDlgRows[3].Text;
  Host.Description := FarTrimW(FDlgRows[4].Text);
  Host.AskPassword := FDlgRows[5].Index = 1;
  Host.Passive := FDlgRows[6].Index = 1;
  // В адресе может быть всё сразу (ftp://user:password@host:port/dir) -
  // его части заменяют поля
  if not FarFtpParseUrl(FDlgRows[0].Text, Host) then
  begin
    Status(FarProduct + ': FTP - не задан адрес сервера');
    FDlgRow := 0;
    Invalidate;
    Exit;
  end;
  HostIdx := FFtpEditIdx;
  if (HostIdx < 0) or (HostIdx > High(FFtpHosts)) then
  begin
    HostIdx := Length(FFtpHosts);
    SetLength(FFtpHosts, HostIdx + 1);
  end;
  FFtpHosts[HostIdx] := Host;
  if FIniName <> '' then
    FarFtpHostsSave(FIniName, FFtpHosts);
  PanelIndex := FFtpEditPanel;
  DlgClose;
  if (PanelIndex < 0) or (PanelIndex > 1) then
    Exit;
  if FPanels[PanelIndex].FFtpMode = 1 then
    FtpFillHosts(FPanels[PanelIndex], HostIdx);
  if FPanels[1 - PanelIndex].FFtpMode = 1 then
    FtpFillHosts(FPanels[1 - PanelIndex], -1);
  if AConnect then
    FtpConnect(PanelIndex, HostIdx);
end;

// F8 / Del на адресе - спросить
procedure TFarView.FtpDeleteHost(APanelIndex: Integer);
var
  Panel: TFarPanel;
  HostIdx: Integer;
begin
  Panel := FPanels[APanelIndex];
  if (Panel.Cursor < 0) or (Panel.Cursor >= Panel.Count) or
     Panel.FItems[Panel.Cursor].IsUp then
    Exit;
  HostIdx := Panel.FItems[Panel.Cursor].OrigIndex;
  if (HostIdx < 0) or (HostIdx > High(FFtpHosts)) then
    Exit;
  FFtpDelIdx := HostIdx;
  FFtpDelPanel := APanelIndex;
  DlgOpen(fdFtpDelete, 'Delete', ['Delete FTP address',
    FarFitName(FarFtpHostUrl(FFtpHosts[HostIdx]), 60)], True, True, False,
    '', ['Delete', 'Cancel']);
end;

procedure TFarView.FtpDeleteConfirmed;
var
  HostIdx, PanelIndex: Integer;
begin
  HostIdx := FFtpDelIdx;
  if (HostIdx < 0) or (HostIdx > High(FFtpHosts)) then
    Exit;
  for PanelIndex := HostIdx to High(FFtpHosts) - 1 do
    FFtpHosts[PanelIndex] := FFtpHosts[PanelIndex + 1];
  SetLength(FFtpHosts, Length(FFtpHosts) - 1);
  if FIniName <> '' then
    FarFtpHostsSave(FIniName, FFtpHosts);
  for PanelIndex := 0 to 1 do
    if FPanels[PanelIndex].FFtpMode = 1 then
      FtpFillHosts(FPanels[PanelIndex], HostIdx);
end;

// Адрес FTP из файла FAR Manager: FTP-плагин по F5 на адресе пишет файл
// его настроек (строки Ключ=Значение). Берутся адрес (Url или HostName -
// хост, порт, папка), пользователь, папка, порт, пассивный режим,
// описание. Пароль не переносится: спросится при первом входе. False - в
// файле нет адреса
function FarFtpHostFromFile(const AFileName: WideString;
  var AHost: TFarFtpHost): Boolean;
var
  Lines: TStringList;
  LineIdx, EqPos: Integer;
  Key, Value, AnsiName: string;
  UserText, HomeText, PortText, PassiveText, DescrText, UrlText: string;
begin
  Result := False;
  FarFtpHostClear(AHost);
  AnsiName := FarToAnsiPath(AFileName);
  if AnsiName = '' then
    Exit;
  UserText := '';
  HomeText := '';
  PortText := '';
  PassiveText := '';
  DescrText := '';
  UrlText := '';
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AnsiName);
    except
      Exit;
    end;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      EqPos := Pos('=', Lines[LineIdx]);
      if EqPos < 2 then
        Continue;
      Key := LowerCase(Trim(Copy(Lines[LineIdx], 1, EqPos - 1)));
      Value := Trim(Copy(Lines[LineIdx], EqPos + 1, MaxInt));
      if (Length(Value) >= 2) and (Value[1] = '"') and
         (Value[Length(Value)] = '"') then
        Value := Copy(Value, 2, Length(Value) - 2);
      if (Key = 'url') or (Key = 'hostname') or (Key = 'host') then
      begin
        if UrlText = '' then
          UrlText := Value;
      end
      else if (Key = 'user') or (Key = 'username') then
        UserText := Value
      else if (Key = 'directory') or (Key = 'path') or (Key = 'homedir') then
        HomeText := Value
      else if Key = 'port' then
        PortText := Value
      else if (Key = 'passivemode') or (Key = 'passive') then
        PassiveText := Value
      else if (Key = 'description') or (Key = 'hostdescr') then
        DescrText := Value;
    end;
  finally
    Lines.Free;
  end;
  if (UrlText = '') or not FarFtpParseUrl(WideString(UrlText), AHost) then
    Exit;
  if UserText <> '' then
    AHost.User := WideString(UserText);
  if (HomeText <> '') and (AHost.Home = '') then
    AHost.Home := WideString(HomeText);
  if StrToIntDef(PortText, 0) > 0 then
    AHost.Port := StrToIntDef(PortText, 0);
  if PassiveText <> '' then
    AHost.Passive := (PassiveText = '1') or (CompareText(PassiveText,
      'true') = 0) or (CompareText(PassiveText, 'yes') = 0);
  if DescrText <> '' then
    AHost.Description := WideString(DescrText);
  // Пароль - не из файла: спросить при входе
  AHost.Password := '';
  AHost.AskPassword := True;
  Result := AHost.Host <> '';
end;

// F5: выделенные файлы (или файл под курсором) - адреса FTP в список
// другой панели. Такой же адрес (хост, пользователь, папка) - пропуск
procedure TFarView.FtpImportHosts;
var
  Names: TFarNames;
  NameIdx, HostIdx, Added, Skipped, Unknown, LastIdx: Integer;
  NewHost: TFarFtpHost;
  Found: Boolean;
  Report: string;
begin
  Names := CollectNames(False);
  Added := 0;
  Skipped := 0;
  Unknown := 0;
  LastIdx := -1;
  for NameIdx := 0 to High(Names) do
  begin
    if not FarFtpHostFromFile(ActivePanel.Path + Names[NameIdx], NewHost) then
    begin
      Inc(Unknown);
      Continue;
    end;
    Found := False;
    for HostIdx := 0 to High(FFtpHosts) do
      if (CompareText(FFtpHosts[HostIdx].Host, NewHost.Host) = 0) and
         (FFtpHosts[HostIdx].User = NewHost.User) and
         (FFtpHosts[HostIdx].Home = NewHost.Home) then
      begin
        Found := True;
        LastIdx := HostIdx;
      end;
    if Found then
    begin
      Inc(Skipped);
      Continue;
    end;
    SetLength(FFtpHosts, Length(FFtpHosts) + 1);
    FFtpHosts[High(FFtpHosts)] := NewHost;
    LastIdx := High(FFtpHosts);
    Inc(Added);
  end;
  if (Added > 0) and (FIniName <> '') then
    FarFtpHostsSave(FIniName, FFtpHosts);
  if LastIdx >= 0 then
    FtpFillHosts(FPanels[1 - FActive], LastIdx);
  Report := FarProduct + ': FTP - добавлено адресов: ' + IntToStr(Added);
  if Skipped > 0 then
    Report := Report + ', уже были: ' + IntToStr(Skipped);
  if Unknown > 0 then
    Report := Report + ', не адрес FTP: ' + IntToStr(Unknown);
  if Added > 0 then
    Report := Report + ' (пароль спросится при первом входе)';
  Status(Report);
  Invalidate;
end;

// Адрес FTP строкой для буфера обмена: ftp://пользователь:пароль@хост:порт
// /папка и через табуляцию - описание. Пароль - открытым текстом (как
// копирует FAR); у адреса «спрашивать пароль» его нет
function FarFtpHostLine(const AHost: TFarFtpHost): WideString;
begin
  Result := 'ftp://';
  if AHost.User <> '' then
  begin
    Result := Result + AHost.User;
    if (AHost.Password <> '') and not AHost.AskPassword then
      Result := Result + ':' + AHost.Password;
    Result := Result + '@';
  end;
  Result := Result + WideString(AHost.Host);
  if (AHost.Port > 0) and (AHost.Port <> FarFtpDefaultPort) then
    Result := Result + ':' + WideString(IntToStr(AHost.Port));
  if AHost.Home <> '' then
  begin
    if AHost.Home[1] <> '/' then
      Result := Result + '/';
    Result := Result + AHost.Home;
  end;
  if AHost.Description <> '' then
    Result := Result + #9 + AHost.Description;
end;

// Ctrl+Ins в списке адресов: выделенные адреса (или под курсором) - в
// буфер обмена, по строке на адрес
procedure TFarView.FtpCopyHosts;
var
  Panel: TFarPanel;
  ItemIdx, HostIdx, Count, WithPass: Integer;
  Text: WideString;

  procedure AddHost(AIndex: Integer);
  begin
    if (AIndex < 0) or (AIndex > High(FFtpHosts)) then
      Exit;
    if Text <> '' then
      Text := Text + #13#10;
    Text := Text + FarFtpHostLine(FFtpHosts[AIndex]);
    Inc(Count);
    if (FFtpHosts[AIndex].Password <> '') and
       not FFtpHosts[AIndex].AskPassword then
      Inc(WithPass);
  end;

begin
  Panel := ActivePanel;
  Text := '';
  Count := 0;
  WithPass := 0;
  for ItemIdx := 0 to Panel.Count - 1 do
    if Panel.FItems[ItemIdx].Selected and not Panel.FItems[ItemIdx].IsUp then
      AddHost(Panel.FItems[ItemIdx].OrigIndex);
  if (Count = 0) and (Panel.Cursor >= 0) and (Panel.Cursor < Panel.Count) and
     not Panel.FItems[Panel.Cursor].IsUp then
  begin
    HostIdx := Panel.FItems[Panel.Cursor].OrigIndex;
    AddHost(HostIdx);
  end;
  if Count = 0 then
    Exit;
  if not FarCopyToClipboard(Handle, Text) then
  begin
    Status(FarProduct + ': буфер обмена занят - не скопировано');
    Exit;
  end;
  if WithPass > 0 then
    Status(FarProduct + ': FTP - в буфере обмена адресов: ' +
      IntToStr(Count) + ', с паролем: ' + IntToStr(WithPass) +
      ' (пароль - открытым текстом)')
  else
    Status(FarProduct + ': FTP - в буфере обмена адресов: ' + IntToStr(Count));
end;

// Shift+Ins в списке адресов: строки ftp://... из буфера обмена - в
// список (с паролем, если он в строке). Такой же адрес (хост,
// пользователь, папка) не повторяется; у него без пароля - пароль
// дополняется. False - в буфере нет ни одной строки ftp://
function TFarView.FtpPasteHosts: Boolean;
var
  Text, Line, Descr: WideString;
  LineIdx, HostIdx, TabPos, Added, Updated, Same, LastIdx: Integer;
  NewHost: TFarFtpHost;
  Found: Integer;
  Report: string;
begin
  Result := False;
  Text := FarClipboardText;
  if Text = '' then
    Exit;
  Added := 0;
  Updated := 0;
  Same := 0;
  LastIdx := -1;
  begin
    // Строки по CR / LF (WideString - вручную)
    Line := '';
    for LineIdx := 1 to Length(Text) + 1 do
      if (LineIdx > Length(Text)) or (Text[LineIdx] = #13) or
         (Text[LineIdx] = #10) then
      begin
        Line := FarTrimW(Line);
        if WideLowerCase(Copy(Line, 1, 6)) = 'ftp://' then
        begin
          Result := True;
          Descr := '';
          TabPos := Pos(WideString(#9), Line);
          if TabPos > 0 then
          begin
            Descr := FarTrimW(Copy(Line, TabPos + 1, MaxInt));
            Line := FarTrimW(Copy(Line, 1, TabPos - 1));
          end;
          FarFtpHostClear(NewHost);
          if FarFtpParseUrl(Line, NewHost) and (NewHost.Host <> '') then
          begin
            NewHost.Description := Descr;
            NewHost.AskPassword := NewHost.Password = '';
            Found := -1;
            for HostIdx := 0 to High(FFtpHosts) do
              if (CompareText(FFtpHosts[HostIdx].Host, NewHost.Host) = 0) and
                 (FFtpHosts[HostIdx].User = NewHost.User) and
                 (FFtpHosts[HostIdx].Home = NewHost.Home) then
                Found := HostIdx;
            if Found < 0 then
            begin
              SetLength(FFtpHosts, Length(FFtpHosts) + 1);
              FFtpHosts[High(FFtpHosts)] := NewHost;
              LastIdx := High(FFtpHosts);
              Inc(Added);
            end
            else
            begin
              LastIdx := Found;
              if (NewHost.Password <> '') and
                 ((FFtpHosts[Found].Password = '') or
                  FFtpHosts[Found].AskPassword) then
              begin
                FFtpHosts[Found].Password := NewHost.Password;
                FFtpHosts[Found].AskPassword := False;
                Inc(Updated);
              end
              else
                Inc(Same);
            end;
          end;
        end;
        Line := '';
      end
      else
        Line := Line + Text[LineIdx];
  end;
  if not Result then
    Exit;
  if ((Added > 0) or (Updated > 0)) and (FIniName <> '') then
    FarFtpHostsSave(FIniName, FFtpHosts);
  if LastIdx >= 0 then
    FtpFillHosts(ActivePanel, LastIdx);
  Report := FarProduct + ': FTP - добавлено адресов: ' + IntToStr(Added);
  if Updated > 0 then
    Report := Report + ', пароль дополнен: ' + IntToStr(Updated);
  if Same > 0 then
    Report := Report + ', уже были: ' + IntToStr(Same);
  Status(Report);
  Invalidate;
end;

// Клавиши панели на FTP. True - клавиша обработана; False - обычная
// (стрелки, Insert, Tab, сортировка, Alt+F1 / Alt+F2 и т.п.)
function TFarView.FtpKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
var
  Panel: TFarPanel;
  Plain: Boolean;
begin
  Result := True;
  Panel := ActivePanel;
  Plain := not ACtrl and not AAlt;
  // Esc - прервать запрос к серверу
  if (AKey = VK_ESCAPE) and (FFtpThread[FActive] <> nil) then
  begin
    FFtpThread[FActive].Cancel;
    Status(FarProduct + ': FTP - прерываю...');
    Exit;
  end;
  if Plain and (AKey = VK_RETURN) then
  begin
    FtpEnter(FActive);
    Exit;
  end;
  if ACtrl and not AAlt and not AShift then
    case AKey of
      VK_NEXT:
        begin
          FtpEnter(FActive);
          Exit;
        end;
      VK_PRIOR:
        begin
          if Panel.FFtpMode = 2 then
            FtpUp(FActive)
          else
            FtpExit(Panel);
          Exit;
        end;
      Ord('R'):
        begin
          if Panel.FFtpMode = 2 then
            FtpStartList(FActive, Panel.FFtpHost, Panel.FFtpHostIdx,
              Panel.FFtpDir, Panel.FItems[Panel.Cursor].FtpRaw)
          else
            FtpFillHosts(Panel, Panel.FItems[Panel.Cursor].OrigIndex);
          Exit;
        end;
      FarVkBackslash, FarVkBackslash2:
        begin
          if Panel.FFtpMode = 2 then
            FtpStartList(FActive, Panel.FFtpHost, Panel.FFtpHostIdx, '/', '');
          Exit;
        end;
    end;
  // Список адресов: Shift+F4 - новый, F4 - изменить, F8 / Del - удалить
  if (Panel.FFtpMode = 1) and Plain then
    case AKey of
      VK_F4:
        begin
          if AShift or (Panel.Cursor < 0) or (Panel.Cursor >= Panel.Count) or
             Panel.FItems[Panel.Cursor].IsUp then
            FtpEditHost(FActive, -1)
          else
            FtpEditHost(FActive, Panel.FItems[Panel.Cursor].OrigIndex);
          Exit;
        end;
      VK_F8, VK_DELETE:
        begin
          FtpDeleteHost(FActive);
          Exit;
        end;
    end;
  // Остальные операции с файлами на FTP - позже
  if (Plain and ((AKey = VK_F3) or (AKey = VK_F4) or (AKey = VK_F5) or
     (AKey = VK_F6) or (AKey = VK_F7) or (AKey = VK_F8) or
     (AKey = VK_DELETE))) or (Plain and AShift and (AKey = VK_F1)) or
     (AAlt and not ACtrl and (AKey = VK_F7)) then
  begin
    Status(FarProduct + ': FTP - просмотр, копирование, папки и удаление на ' +
      'сервере - следующим шагом');
    Exit;
  end;
  Result := False;
end;
// Список адресов FTP: заголовки и строки Host | Home | User
procedure TFarView.DrawFtpHosts(APanel: TFarPanel; APanelX, APanelW: Integer;
  AIsActive: Boolean);
var
  HostW, HomeW, UserW, RowIndex, ItemIndex, HostIdx, RowY: Integer;
  Fore, Back: TColor;
  HostText, HomeText, UserText: WideString;
begin
  FtpHostColumns(APanelW, HostW, HomeW, UserW);
  PutCentered(APanelX + 1, 1, HostW, 'Host', FPal[fpPanelHeader],
    FPal[fpPanelBack]);
  PutCentered(APanelX + 2 + HostW, 1, HomeW, 'Home', FPal[fpPanelHeader],
    FPal[fpPanelBack]);
  PutCentered(APanelX + 3 + HostW + HomeW, 1, UserW, 'User',
    FPal[fpPanelHeader], FPal[fpPanelBack]);
  for RowIndex := 0 to FileRows - 1 do
  begin
    ItemIndex := APanel.TopIndex + RowIndex;
    if ItemIndex >= APanel.Count then
      Break;
    RowY := 2 + RowIndex;
    with APanel.FItems[ItemIndex] do
    begin
      Back := FPal[fpPanelBack];
      if Selected then
        Fore := FPal[fpPanelSelected]
      else if IsUp then
        Fore := FPal[fpPanelDir]
      else
        Fore := FPal[fpPanelText];
      if AIsActive and (ItemIndex = APanel.Cursor) then
      begin
        Back := FPal[fpPanelCursorBack];
        if not Selected then
          Fore := FPal[fpPanelCursorText];
        // Курсор - во всю строку (и под границами колонок)
        FillCells(APanelX + 1, RowY, APanelW - 2, Back);
      end;
      HostIdx := OrigIndex;
      if IsUp or (HostIdx < 0) or (HostIdx > High(FFtpHosts)) then
      begin
        HostText := '..';
        HomeText := '..';
        UserText := '..';
      end
      else
      begin
        HostText := Name;
        HomeText := FFtpHosts[HostIdx].Home;
        UserText := FFtpHosts[HostIdx].User;
        if UserText = '' then
          UserText := 'anonymous';
      end;
      PutText(APanelX + 1, RowY, HostW, FarFitName(HostText, HostW), Fore,
        Back);
      PutText(APanelX + 2 + HostW, RowY, HomeW, FarFitName(HomeText, HomeW),
        Fore, Back);
      PutText(APanelX + 3 + HostW + HomeW, RowY, UserW,
        FarFitName(UserText, UserW), Fore, Back);
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Редактор unIDE FAR (F4). Текст, каретка, откат, файл - TFarEditor
//  (FarEdit); здесь - место на экране, отрисовка, клавиши и диалоги.
//
//  Редактор занимает одну панель (другую - ту, где был файл, - видно
//  рядом) или обе на всю ширину (F5). Tab в редакторе - символ табуляции;
//  Ctrl+Tab - в другую панель, Tab / Ctrl+Tab оттуда - обратно.
//  Подсветка - схема .clr файла (OnGetScheme - Unit1, та же, что у
//  основного редактора), её цвета текста и фона. Шаг табуляции -
//  editor.ini [Editor] TabChars, как в основном редакторе.
//
//  Клавиши (как в редакторе FAR): стрелки, Home / End, PgUp / PgDn,
//  Ctrl+Home / End (и Ctrl+PgUp / PgDn) - начало / конец текста,
//  Ctrl+стрелки - по словам, Shift+ - выделение; Ctrl+A - всё;
//  Ctrl+C / Ctrl+Ins - копировать, Ctrl+X / Shift+Del - вырезать,
//  Ctrl+V / Shift+Ins - вставить; Ctrl+Z - откат, Ctrl+Shift+Z - повтор;
//  Ctrl+Y - удалить строку; Ctrl+Backspace / Ctrl+Del - слово;
//  F2 - записать, Shift+F2 - записать как; F7 - поиск, Shift+F7 - дальше;
//  Alt+F8 - к строке; F5 - на всю ширину / в панель; Esc / F10 - закрыть.
// ---------------------------------------------------------------------------

// Панель занята редактором (F4) или просмотром (F3)
function TFarView.EditorShown(APanelIndex: Integer): Boolean;
begin
  Result := DocOpen and (FEditWide or (APanelIndex = FEditPanel));
end;

function TFarView.EditorActive: Boolean;
begin
  Result := (FEditor <> nil) and not FPanelsHidden and
    (FEditWide or (FActive = FEditPanel));
end;

procedure TFarView.EditBounds(var AX0, AWidth: Integer);
begin
  if FEditWide then
  begin
    AX0 := 0;
    AWidth := FCols;
  end
  else
    PanelBounds(FEditPanel, AX0, AWidth);
end;

// Строк текста: панель без строки заголовка
function TFarView.EditTextRows: Integer;
begin
  Result := PanelHeight - 1;
  if Result < 1 then
    Result := 1;
end;

// Каретка - в видимой части
procedure TFarView.EditEnsureVisible;
var
  EditX, EditW, Rows, ScreenPos: Integer;
begin
  if FEditor = nil then
    Exit;
  EditBounds(EditX, EditW);
  Rows := EditTextRows;
  if FEditor.Row < FEditor.TopRow then
    FEditor.TopRow := FEditor.Row;
  if FEditor.Row >= FEditor.TopRow + Rows then
    FEditor.TopRow := FEditor.Row - Rows + 1;
  if FEditor.TopRow < 0 then
    FEditor.TopRow := 0;
  ScreenPos := FEditor.ScreenCol(FEditor.Row, FEditor.Col);
  if ScreenPos < FEditor.LeftCol then
    FEditor.LeftCol := ScreenPos;
  if (EditW > 1) and (ScreenPos >= FEditor.LeftCol + EditW) then
    FEditor.LeftCol := ScreenPos - EditW + 1;
  if FEditor.LeftCol < 0 then
    FEditor.LeftCol := 0;
end;

// F4: файл - в свой редактор
procedure TFarView.OpenEditor(const AFileName: WideString);
var
  Editor: TFarEditor;
  ErrorText: string;
  Scheme: TClrScheme;
  FromViewer, SlotWide: Boolean;
  SlotPanel: Integer;
begin
  FromViewer := False;
  SlotWide := False;
  SlotPanel := FEditPanel;
  if FEditor <> nil then
  begin
    if FarSameName(FEditor.FileName, AFileName) then
    begin
      FActive := FEditPanel;
      Invalidate;
      Exit;
    end;
    if FEditor.Modified then
    begin
      FActive := FEditPanel;
      Status(FarProduct + ': в редакторе изменён ' +
        string(ExtractFileName(string(FEditor.FileName))) +
        ' - сначала запишите (F2) или закройте (Esc)');
      Invalidate;
      Exit;
    end;
    FreeAndNil(FEditor);
  end;
  Editor := TFarEditor.Create;
  if not Editor.LoadFromFile(AFileName, ErrorText) then
  begin
    Editor.Free;
    Status(FarProduct + ': файл не открыть: ' + ErrorText);
    Exit;
  end;
  // Открыт просмотр (F6 в нём или F4 в панели) - редактор на его место
  FromViewer := FViewer <> nil;
  if FromViewer then
  begin
    SlotPanel := FEditPanel;
    SlotWide := FEditWide;
    FreeAndNil(FViewer);
  end;
  Editor.TabSize := FEditTabSize;
  Scheme := nil;
  if Assigned(FOnGetScheme) then
    Scheme := FOnGetScheme(AFileName);
  // Без схемы - цвета панели FAR
  Editor.SetScheme(Scheme, FPal[fpPanelText], FPal[fpPanelBack]);
  FEditor := Editor;
  // Режим F4 основного редактора (одна панель) - снова обе панели
  if (FSingle >= 0) and Assigned(FOnShowPanels) then
    FOnShowPanels(Self);
  // Редактор - в другой панели: файл, откуда открыли, остаётся виден
  if FromViewer then
  begin
    FEditPanel := SlotPanel;
    FEditWide := SlotWide;
  end
  else
  begin
    if FSingle >= 0 then
      FEditPanel := FSingle
    else
      FEditPanel := 1 - FActive;
    FEditWide := False;
  end;
  FActive := FEditPanel;
  FEditQuitAfterSave := False;
  Status(FarProduct + ': редактор - ' + string(AFileName) + ' (F2 - записать, ' +
    'Esc - закрыть, F5 - на всю ширину)');
  Invalidate;
end;

procedure TFarView.CloseEditor;
var
  PanelIndex: Integer;
begin
  if FEditor = nil then
    Exit;
  FreeAndNil(FEditor);
  FEditWide := False;
  FEditQuitAfterSave := False;
  if FSingle < 0 then
    FActive := 1 - FEditPanel;
  // Файл мог измениться - размер и время в панелях
  for PanelIndex := 0 to 1 do
  begin
    FPanels[PanelIndex].Reread;
    EnsureVisible(FPanels[PanelIndex]);
  end;
  Status(FarProduct + ': редактор закрыт');
  Invalidate;
end;

// Esc / F10: изменён - спросить
procedure TFarView.EditQuit;
begin
  if FEditor = nil then
    Exit;
  if not FEditor.Modified then
  begin
    CloseEditor;
    Exit;
  end;
  DlgOpen(fdEditQuit, 'Editor', ['File has been modified',
    FarFitPath(FEditor.FileName, 60), 'Save changes?'], True, True, False, '',
    ['Save', 'Don''t save', 'Cancel']);
end;

// Записать в AFileName; в кодировке Windows не все символы - спросить
procedure TFarView.EditSave(const AFileName: WideString;
  AEncoding: TFarEditEncoding; AAllowLossy: Boolean);
var
  Lossy: Boolean;
  ErrorText: string;
  PanelIndex: Integer;
begin
  if FEditor = nil then
    Exit;
  if not FEditor.SaveToFile(AFileName, AEncoding, AAllowLossy, Lossy,
     ErrorText) then
  begin
    if Lossy then
    begin
      FEditSaveName := AFileName;
      DlgOpen(fdEditEncode, 'Save', ['Some characters cannot be saved in ' +
        'the Windows code page.', 'UTF-8 - keep them, ANSI - replace them ' +
        'with "?"'], True, True, False, '', ['UTF-8', 'ANSI', 'Cancel']);
      Exit;
    end;
    FEditQuitAfterSave := False;
    DlgOpen(fdEditError, 'Editor', ['Cannot save the file',
      FarFitPath(AFileName, 60), WideString(ErrorText)], True, True, False,
      '', ['OK']);
    Status(FarProduct + ': файл не записан: ' + ErrorText);
    Exit;
  end;
  Status(FarProduct + ': записан ' + string(AFileName) + ' (' +
    FarEditEncodingName(FEditor.Encoding) + ')');
  // Панели, где этот файл, - перечитать (кроме той, где редактор)
  for PanelIndex := 0 to 1 do
    if not EditorShown(PanelIndex) then
    begin
      FPanels[PanelIndex].Reread;
      EnsureVisible(FPanels[PanelIndex]);
    end;
  if FEditQuitAfterSave then
    CloseEditor;
  Invalidate;
end;

// [ Find ] в окне поиска
procedure TFarView.EditFindConfirm;
begin
  if Length(FDlgRows) < 2 then
    Exit;
  FEditFind := FDlgRows[0].Text;
  FEditFindCase := FDlgRows[1].Index = 1;
  DlgClose;
  EditFindNext;
end;

procedure TFarView.EditFindNext;
begin
  if (FEditor = nil) or (FEditFind = '') then
    Exit;
  if FEditor.FindNext(FEditFind, FEditFindCase) then
  begin
    EditEnsureVisible;
    Status(FarProduct + ': найдено - строка ' + IntToStr(FEditor.Row + 1) +
      ' (Shift+F7 - дальше)');
  end
  else
    Status(FarProduct + ': не найдено: ' + string(FEditFind));
  Invalidate;
end;

procedure TFarView.EditGoto(const AText: WideString);
var
  LineNo: Integer;
begin
  if FEditor = nil then
    Exit;
  LineNo := StrToIntDef(Trim(string(AText)), 0);
  if (LineNo < 1) or (LineNo > FEditor.Count) then
  begin
    Status(FarProduct + ': строки ' + string(AText) + ' нет (1..' +
      IntToStr(FEditor.Count) + ')');
    Exit;
  end;
  FEditor.MoveTo(LineNo - 1, 0, False);
  // Строка - в середину окна
  FEditor.TopRow := LineNo - 1 - EditTextRows div 2;
  EditEnsureVisible;
  Invalidate;
end;

// Символ с клавиатуры
procedure TFarView.EditChar(ACh: WideChar);
begin
  if FEditor = nil then
    Exit;
  FEditor.InsertText(ACh, True);
  EditEnsureVisible;
  Invalidate;
end;

// Клавиши редактора. True - обработана; False - символ (придёт WM_CHAR)
function TFarView.EditKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
var
  Ed: TFarEditor;
  Plain: Boolean;
  ClipText: WideString;
begin
  Result := True;
  Ed := FEditor;
  Plain := not ACtrl and not AAlt;
  // F-клавиши
  if (AKey >= VK_F1) and (AKey <= VK_F12) then
  begin
    if Plain and not AShift then
      case AKey of
        VK_F2:
          EditSave(Ed.FileName, Ed.Encoding, False);
        VK_F5:
          begin
            FEditWide := not FEditWide;
            if FEditWide then
              FActive := FEditPanel;
            EditEnsureVisible;
          end;
        VK_F7:
          begin
            DlgOpen(fdEditFind, 'Search', ['Search in the text'], False,
              False, False, '', ['Find', 'Cancel']);
            DlgAddRow('Search for:', False, False, FEditFind, [], 0);
            DlgAddCheck('Case sensitive', FEditFindCase);
            FDlgRow := 0;
          end;
        VK_F10:
          EditQuit;
      else
        Status(FarProduct + ': в редакторе ' + KeyName(AKey, AShift, ACtrl, AAlt) +
          ' не используется');
      end
    else if Plain and AShift and (AKey = VK_F2) then
      DlgOpen(fdEditSave, 'Save file as', ['Save file as:'], False, False,
        True, Ed.FileName, ['Save', 'Cancel'])
    else if Plain and AShift and (AKey = VK_F7) then
      EditFindNext
    else if AAlt and not ACtrl and not AShift and (AKey = VK_F8) then
      DlgOpen(fdEditGoto, 'Go to', ['Line number (1..' + IntToStr(Ed.Count) +
        '):'], False, False, True, IntToStr(Ed.Row + 1), ['Go', 'Cancel'])
    else
      Status(FarProduct + ': в редакторе ' + KeyName(AKey, AShift, ACtrl, AAlt) +
        ' не используется');
    Invalidate;
    Exit;
  end;
  if AAlt then
  begin
    Result := False;
    Exit;
  end;
  if not ACtrl then
    case AKey of
      VK_LEFT:
        if Ed.Col > 0 then
          Ed.MoveTo(Ed.Row, Ed.Col - 1, AShift)
        else if Ed.Row > 0 then
          Ed.MoveTo(Ed.Row - 1, Length(Ed.Lines[Ed.Row - 1]), AShift)
        else
          Ed.MoveTo(0, 0, AShift);
      VK_RIGHT:
        if Ed.Col < Length(Ed.Lines[Ed.Row]) then
          Ed.MoveTo(Ed.Row, Ed.Col + 1, AShift)
        else if Ed.Row < Ed.Count - 1 then
          Ed.MoveTo(Ed.Row + 1, 0, AShift)
        else
          Ed.MoveTo(Ed.Row, Ed.Col, AShift);
      VK_UP:
        Ed.MoveVert(-1, AShift);
      VK_DOWN:
        Ed.MoveVert(1, AShift);
      VK_PRIOR:
        begin
          Ed.TopRow := Ed.TopRow - (EditTextRows - 1);
          Ed.MoveVert(-(EditTextRows - 1), AShift);
        end;
      VK_NEXT:
        begin
          Ed.TopRow := Ed.TopRow + (EditTextRows - 1);
          if Ed.TopRow > Ed.Count - EditTextRows then
            Ed.TopRow := Ed.Count - EditTextRows;
          Ed.MoveVert(EditTextRows - 1, AShift);
        end;
      VK_HOME:
        Ed.MoveTo(Ed.Row, 0, AShift);
      VK_END:
        Ed.MoveTo(Ed.Row, Length(Ed.Lines[Ed.Row]), AShift);
      VK_RETURN:
        Ed.NewLine;
      VK_TAB:
        Ed.InsertText(#9);
      VK_BACK:
        Ed.Backspace;
      VK_DELETE:
        if AShift then
        begin
          // Shift+Del - вырезать
          if Ed.HasSelection then
          begin
            FarCopyToClipboard(Handle, Ed.SelectedText);
            Ed.DeleteSelection;
          end;
        end
        else
          Ed.DeleteChar;
      VK_INSERT:
        if AShift then
        begin
          ClipText := FarClipboardText;
          if ClipText <> '' then
            Ed.InsertText(ClipText);
        end;
      VK_ESCAPE:
        EditQuit;
    else
      Result := False;   // символ - придёт WM_CHAR
    end
  else
    case AKey of
      VK_LEFT:
        Ed.WordLeft(AShift);
      VK_RIGHT:
        Ed.WordRight(AShift);
      VK_UP:
        if Ed.TopRow > 0 then
          Ed.TopRow := Ed.TopRow - 1;
      VK_DOWN:
        if Ed.TopRow < Ed.Count - 1 then
          Ed.TopRow := Ed.TopRow + 1;
      VK_HOME, VK_PRIOR:
        Ed.MoveTo(0, 0, AShift);
      VK_END, VK_NEXT:
        Ed.MoveTo(Ed.Count - 1, Length(Ed.Lines[Ed.Count - 1]), AShift);
      VK_BACK:
        Ed.DeleteWordLeft;
      VK_DELETE:
        Ed.DeleteWordRight;
      VK_INSERT, Ord('C'):
        if Ed.HasSelection then
          FarCopyToClipboard(Handle, Ed.SelectedText);
      Ord('X'):
        if Ed.HasSelection then
        begin
          FarCopyToClipboard(Handle, Ed.SelectedText);
          Ed.DeleteSelection;
        end;
      Ord('V'):
        begin
          ClipText := FarClipboardText;
          if ClipText <> '' then
            Ed.InsertText(ClipText);
        end;
      Ord('A'):
        Ed.SelectAll;
      Ord('Z'):
        if AShift then
          Ed.Redo
        else
          Ed.Undo;
      Ord('Y'):
        Ed.DeleteLine;
      VK_TAB:
        // В другую панель (редактор - в своей)
        if not FEditWide and (FSingle < 0) then
          FActive := 1 - FEditPanel;
    else
      // Прочие Ctrl+буква в редакторе - ничего (не в командную строку)
      Result := True;
    end;
  // Ctrl+стрелки вверх-вниз прокручивают окно, не двигая каретку
  if not (ACtrl and ((AKey = VK_UP) or (AKey = VK_DOWN))) then
    EditEnsureVisible;
  Invalidate;
end;

// Щелчок / протяжка мышью в тексте редактора
procedure TFarView.EditMouse(AX, AY: Integer; AShiftDown, ADrag: Boolean);
var
  EditX, EditW, CellCol, CellRow, LineIdx: Integer;
begin
  if FEditor = nil then
    Exit;
  EditBounds(EditX, EditW);
  CellCol := AX div FCellW - EditX;
  CellRow := AY div FCellH;
  if CellCol < 0 then
    CellCol := 0;
  if CellRow < 1 then
    CellRow := 1;
  if CellRow > EditTextRows then
    CellRow := EditTextRows;
  LineIdx := FEditor.TopRow + CellRow - 1;
  if LineIdx >= FEditor.Count then
    LineIdx := FEditor.Count - 1;
  FEditor.MoveTo(LineIdx, FEditor.ColAtScreen(LineIdx,
    FEditor.LeftCol + CellCol), AShiftDown or ADrag);
  EditEnsureVisible;
  Invalidate;
end;

procedure TFarView.DrawEditor;
var
  Ed: TFarEditor;
  EditX, EditW, PanelH, ScreenRow, LineIdx, CharIdx, ScreenPos, NextPos: Integer;
  CellIdx, RunIdx, RunPos, RunCount, State, GroupStart: Integer;
  Row1, Col1, Row2, Col2: Integer;
  HasSel, InSel: Boolean;
  Line, CellText, Title, RightText: WideString;
  CharFg, CharBg: array of TColor;
  CellFg, CellBg: array of TColor;
  Runs: TSchemeRuns;
  TextFg, PageBg, SelFg, SelBg, RunFg, RunBg: TColor;
  SchemeFg, SchemeBg: TColor;
  CaretX, CaretRow: Integer;
  ShownCh: WideChar;
begin
  Ed := FEditor;
  EditBounds(EditX, EditW);
  PanelH := PanelHeight;
  if (EditW < 4) or (PanelH < 2) then
    Exit;
  // Заголовок: имя файла; справа - изменён, строка / всего, колонка,
  // кодировка
  FillCells(EditX, 0, EditW, FPal[fpEditTitleBack]);
  if Ed.Modified then
    RightText := '*'
  else
    RightText := ' ';
  RightText := ' ' + RightText + ' ' + IntToStr(Ed.Row + 1) + '/' +
    IntToStr(Ed.Count) + '  ' + IntToStr(Ed.ScreenCol(Ed.Row, Ed.Col) + 1) +
    '  ' + WideString(FarEditEncodingName(Ed.Encoding)) + ' ';
  if Length(RightText) > EditW - 8 then
    RightText := '';
  Title := ' ' + FarFitPath(Ed.FileName, EditW - Length(RightText) - 2);
  PutText(EditX, 0, EditW - Length(RightText), Title, FPal[fpEditTitleText],
    FPal[fpEditTitleBack]);
  if RightText <> '' then
    PutText(EditX + EditW - Length(RightText), 0, Length(RightText), RightText,
      FPal[fpEditTitleText], FPal[fpEditTitleBack]);

  // Цвета текста и фона: заданы в палитре (F9 - Colors - Редактор) - они,
  // нет - схемы. Куски схемы цветом её текста / фона - тоже цветом палитры
  SchemeFg := ColorToRGB(Ed.Colorizer.TextFg);
  SchemeBg := ColorToRGB(Ed.Colorizer.PageBg);
  TextFg := SchemeFg;
  PageBg := SchemeBg;
  if FPal[fpEditText] <> clNone then
    TextFg := ColorToRGB(FPal[fpEditText]);
  if FPal[fpEditBack] <> clNone then
    PageBg := ColorToRGB(FPal[fpEditBack]);
  SelFg := FPal[fpEditSelText];
  SelBg := FPal[fpEditSelBack];
  HasSel := Ed.SelRange(Row1, Col1, Row2, Col2);
  SetLength(CellFg, EditW);
  SetLength(CellBg, EditW);
  Runs := nil;
  for ScreenRow := 1 to PanelH - 1 do
  begin
    LineIdx := Ed.TopRow + ScreenRow - 1;
    if LineIdx >= Ed.Count then
    begin
      FillCells(EditX, ScreenRow, EditW, PageBg);
      Continue;
    end;
    Line := Ed.Lines[LineIdx];
    // Цвет каждого символа - по кускам схемы
    SetLength(CharFg, Length(Line) + 1);
    SetLength(CharBg, Length(Line) + 1);
    for CharIdx := 1 to Length(Line) do
    begin
      CharFg[CharIdx] := TextFg;
      CharBg[CharIdx] := PageBg;
    end;
    State := Ed.LineState(LineIdx);
    Ed.Colorizer.ColorLine(Ed.AnsiLine(LineIdx), State, Runs, RunCount);
    for RunIdx := 0 to RunCount - 1 do
    begin
      RunFg := Runs[RunIdx].Fg;
      RunBg := Runs[RunIdx].Bg;
      if (RunFg = clNone) or (RunFg = clDefault) or
         (ColorToRGB(RunFg) = SchemeFg) then
        RunFg := TextFg
      else
        RunFg := ColorToRGB(RunFg);
      if (RunBg = clNone) or (RunBg = clDefault) or
         (ColorToRGB(RunBg) = SchemeBg) then
        RunBg := PageBg
      else
        RunBg := ColorToRGB(RunBg);
      for RunPos := Runs[RunIdx].Start to Runs[RunIdx].Start +
          Runs[RunIdx].Len - 1 do
        if (RunPos >= 1) and (RunPos <= Length(Line)) then
        begin
          CharFg[RunPos] := RunFg;
          CharBg[RunPos] := RunBg;
        end;
    end;
    // Клетки экрана: табуляции раскрыты, сдвиг LeftCol
    CellText := StringOfChar(' ', EditW);
    for CellIdx := 0 to EditW - 1 do
    begin
      CellFg[CellIdx] := TextFg;
      CellBg[CellIdx] := PageBg;
    end;
    ScreenPos := 0;
    for CharIdx := 1 to Length(Line) do
    begin
      if Line[CharIdx] = #9 then
        NextPos := (ScreenPos div Ed.TabSize + 1) * Ed.TabSize
      else
        NextPos := ScreenPos + 1;
      InSel := HasSel and
        ((LineIdx > Row1) or ((LineIdx = Row1) and (CharIdx - 1 >= Col1))) and
        ((LineIdx < Row2) or ((LineIdx = Row2) and (CharIdx - 1 < Col2)));
      ShownCh := Line[CharIdx];
      if Ord(ShownCh) < 32 then
        ShownCh := ' ';
      while ScreenPos < NextPos do
      begin
        CellIdx := ScreenPos - Ed.LeftCol;
        if (CellIdx >= 0) and (CellIdx < EditW) then
        begin
          CellText[CellIdx + 1] := ShownCh;
          if InSel then
          begin
            CellFg[CellIdx] := SelFg;
            CellBg[CellIdx] := SelBg;
          end
          else
          begin
            CellFg[CellIdx] := CharFg[CharIdx];
            CellBg[CellIdx] := CharBg[CharIdx];
          end;
        end;
        Inc(ScreenPos);
      end;
      if ScreenPos >= Ed.LeftCol + EditW then
        Break;
    end;
    // Выделен перевод строки - одна клетка за концом строки
    if HasSel and (LineIdx >= Row1) and (LineIdx < Row2) then
    begin
      CellIdx := ScreenPos - Ed.LeftCol;
      if (CellIdx >= 0) and (CellIdx < EditW) and
         (ScreenPos = Ed.ScreenCol(LineIdx, Length(Line))) then
      begin
        CellFg[CellIdx] := SelFg;
        CellBg[CellIdx] := SelBg;
      end;
    end;
    // Вывод - кусками одного цвета
    GroupStart := 0;
    for CellIdx := 1 to EditW do
      if (CellIdx = EditW) or (CellFg[CellIdx] <> CellFg[GroupStart]) or
         (CellBg[CellIdx] <> CellBg[GroupStart]) then
      begin
        PutText(EditX + GroupStart, ScreenRow, CellIdx - GroupStart,
          Copy(CellText, GroupStart + 1, CellIdx - GroupStart),
          CellFg[GroupStart], CellBg[GroupStart]);
        GroupStart := CellIdx;
      end;
  end;
  // Каретка - полоса внизу клетки, когда редактор активен и окно в фокусе
  if EditorActive and Focused and (FDlgKind = fdNone) and
     (FMenuKind = fmNone) and not FFindOpen then
  begin
    CaretRow := Ed.Row - Ed.TopRow + 1;
    CaretX := Ed.ScreenCol(Ed.Row, Ed.Col) - Ed.LeftCol;
    if (CaretRow >= 1) and (CaretRow < PanelH) and (CaretX >= 0) and
       (CaretX < EditW) then
    begin
      FBuffer.Canvas.Brush.Style := bsSolid;
      FBuffer.Canvas.Brush.Color := TextFg;
      FBuffer.Canvas.FillRect(Rect((EditX + CaretX) * FCellW,
        (CaretRow + 1) * FCellH - 3, (EditX + CaretX + 1) * FCellW,
        (CaretRow + 1) * FCellH - 1));
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Просмотр (F3) - модель TFarViewer (FarViewer.pas), здесь клавиши и
//  отрисовка. Место - то же, что у редактора: другая панель, F5 - вся
//  ширина. Файл не читается целиком: годится и для больших файлов.
//
//  Клавиши (как в просмотре FAR): стрелки, PgUp / PgDn, Home / End (и
//  Ctrl+Home / End) - начало / конец, Left / Right (без переноса) - сдвиг,
//  Ctrl+Left / Right - на 20 колонок; F2 - перенос строк, F4 - hex / текст,
//  F8 - кодировка (ANSI, OEM, UTF-8, UTF-16); F7 - поиск, Shift+F7 -
//  дальше; Alt+F8 - к позиции (смещение или процент); F6 - редактор;
//  Ctrl+R - перечитать; Esc / F10 / F3 - закрыть.
// ---------------------------------------------------------------------------

function TFarView.DocOpen: Boolean;
begin
  Result := (FEditor <> nil) or (FViewer <> nil);
end;

function TFarView.ViewerActive: Boolean;
begin
  Result := (FViewer <> nil) and not FPanelsHidden and
    (FEditWide or (FActive = FEditPanel));
end;

function TFarView.ViewTextRows: Integer;
begin
  Result := PanelHeight - 1;
  if Result < 1 then
    Result := 1;
end;

procedure TFarView.ViewCurrent;
var
  Panel: TFarPanel;
begin
  Panel := ActivePanel;
  if (Panel.Count = 0) or (Panel.Cursor < 0) or
     (Panel.Cursor >= Panel.Count) then
    Exit;
  if ArcBlocked then
    Exit;
  if Panel.FItems[Panel.Cursor].IsDir then
  begin
    Status(FarProduct + ': F3 - просмотр файла; это папка');
    Exit;
  end;
  OpenViewer(Panel.Path + Panel.FItems[Panel.Cursor].Name);
end;

procedure TFarView.OpenViewer(const AFileName: WideString);
var
  Viewer: TFarViewer;
  ErrorText: string;
  FromEditor: Boolean;
begin
  FromEditor := False;
  if FViewer <> nil then
  begin
    if FarSameName(FViewer.FileName, AFileName) then
    begin
      FActive := FEditPanel;
      Invalidate;
      Exit;
    end;
  end;
  // Редактор: изменённый не трогаем; нет - просмотр на его место
  if FEditor <> nil then
  begin
    if FEditor.Modified then
    begin
      FActive := FEditPanel;
      Status(FarProduct + ': в редакторе изменён ' +
        string(ExtractFileName(string(FEditor.FileName))) +
        ' - сначала запишите (F2) или закройте (Esc)');
      Invalidate;
      Exit;
    end;
    FromEditor := True;
  end;
  Viewer := TFarViewer.Create;
  if not Viewer.Open(AFileName, ErrorText) then
  begin
    Viewer.Free;
    Status(FarProduct + ': файл не открыть: ' + ErrorText);
    Exit;
  end;
  Viewer.TabSize := FEditTabSize;
  if FromEditor then
    FreeAndNil(FEditor)
  else if FViewer = nil then
  begin
    // Режим F4 основного редактора (одна панель) - снова обе панели
    if (FSingle >= 0) and Assigned(FOnShowPanels) then
      FOnShowPanels(Self);
    if FSingle >= 0 then
      FEditPanel := FSingle
    else
      FEditPanel := 1 - FActive;
    FEditWide := False;
  end;
  FreeAndNil(FViewer);
  FViewer := Viewer;
  FActive := FEditPanel;
  Status(FarProduct + ': просмотр - ' + string(AFileName) + ' (' +
    FarViewEncodingName(Viewer.Encoding) + '; F8 - кодировка, F4 - hex, ' +
    'Esc - закрыть)');
  Invalidate;
end;

procedure TFarView.CloseViewer;
begin
  if FViewer = nil then
    Exit;
  FreeAndNil(FViewer);
  FEditWide := False;
  if FSingle < 0 then
    FActive := 1 - FEditPanel;
  Status('');
  Invalidate;
end;

procedure TFarView.ViewFindConfirm;
begin
  if Length(FDlgRows) < 2 then
    Exit;
  FViewFind := FDlgRows[0].Text;
  FViewFindCase := FDlgRows[1].Index = 1;
  DlgClose;
  // Новый поиск - от верха экрана
  ViewFindNext;
end;

// Поиск: после найденного в прошлый раз, если оно на экране или ниже;
// иначе - от верха экрана
procedure TFarView.ViewFindNext;
var
  ViewX, ViewW: Integer;
  FromPos: Int64;
begin
  if (FViewer = nil) or (FViewFind = '') then
    Exit;
  EditBounds(ViewX, ViewW);
  FromPos := FViewer.Top;
  if FViewer.FoundPos >= FViewer.Top then
    FromPos := FViewer.FoundPos + 1;
  if FViewer.FindNext(FViewFind, FViewFindCase, FromPos, ViewW,
     ViewTextRows) then
    Status(FarProduct + ': найдено - позиция ' + IntToStr(FViewer.FoundPos) +
      ' (Shift+F7 - дальше)')
  else
    Status(FarProduct + ': не найдено: ' + string(FViewFind));
  Invalidate;
end;

procedure TFarView.ViewGoto(const AText: WideString);
var
  ViewX, ViewW: Integer;
  Target: Int64;
begin
  if FViewer = nil then
    Exit;
  if not FarViewParsePos(string(AText), FViewer.Size, Target) then
  begin
    Status(FarProduct + ': позиция не понята: ' + string(AText) +
      ' (число, 0x1F00 или 50%)');
    Exit;
  end;
  EditBounds(ViewX, ViewW);
  FViewer.GoToPos(Target, ViewW);
  Invalidate;
end;

function TFarView.ViewKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
var
  Viewer: TFarViewer;
  ViewX, ViewW, Rows: Integer;
  Plain: Boolean;
begin
  Result := True;
  Viewer := FViewer;
  EditBounds(ViewX, ViewW);
  Rows := ViewTextRows;
  Plain := not ACtrl and not AAlt;
  if (AKey >= VK_F1) and (AKey <= VK_F12) then
  begin
    if Plain and not AShift then
      case AKey of
        VK_F2:
          Viewer.Wrap := not Viewer.Wrap;
        VK_F3, VK_F10:
          begin
            CloseViewer;
            Exit;
          end;
        VK_F4:
          Viewer.Hex := not Viewer.Hex;
        VK_F5:
          begin
            FEditWide := not FEditWide;
            if FEditWide then
              FActive := FEditPanel;
          end;
        VK_F6:
          begin
            OpenEditor(Viewer.FileName);
            Exit;
          end;
        VK_F7:
          begin
            DlgOpen(fdViewFind, 'Search', ['Search in the file'], False,
              False, False, '', ['Find', 'Cancel']);
            DlgAddRow('Search for:', False, False, FViewFind, [], 0);
            DlgAddCheck('Case sensitive', FViewFindCase);
            FDlgRow := 0;
          end;
        VK_F8:
          begin
            Viewer.Encoding := Viewer.NextEncoding;
            Status(FarProduct + ': кодировка ' +
              FarViewEncodingName(Viewer.Encoding));
          end;
      else
        Status(FarProduct + ': в просмотре ' +
          KeyName(AKey, AShift, ACtrl, AAlt) + ' не используется');
      end
    else if Plain and AShift and (AKey = VK_F7) then
      ViewFindNext
    else if AAlt and not ACtrl and not AShift and (AKey = VK_F8) then
      DlgOpen(fdViewGoto, 'Go to', ['Position: offset (12345, 0x3039) ' +
        'or percent (50%)'], False, False, True, '', ['Go', 'Cancel'])
    else
      Status(FarProduct + ': в просмотре ' +
        KeyName(AKey, AShift, ACtrl, AAlt) + ' не используется');
    Invalidate;
    Exit;
  end;
  if AAlt then
  begin
    Result := False;
    Exit;
  end;
  if not ACtrl then
    case AKey of
      VK_UP:
        Viewer.LineUp(ViewW);
      VK_DOWN:
        Viewer.LineDown(ViewW, Rows);
      VK_PRIOR:
        Viewer.PageUp(ViewW, Rows);
      VK_NEXT:
        Viewer.PageDown(ViewW, Rows);
      VK_HOME:
        Viewer.GoHome;
      VK_END:
        Viewer.GoEnd(ViewW, Rows);
      VK_LEFT:
        if not Viewer.Wrap and not Viewer.Hex then
          Viewer.LeftCol := Viewer.LeftCol - 1;
      VK_RIGHT:
        if not Viewer.Wrap and not Viewer.Hex then
          Viewer.LeftCol := Viewer.LeftCol + 1;
      VK_ESCAPE:
        begin
          CloseViewer;
          Exit;
        end;
      VK_TAB:
        if not FEditWide and (FSingle < 0) then
          FActive := 1 - FEditPanel;
    else
      Result := False;
    end
  else
    case AKey of
      VK_HOME, VK_PRIOR:
        Viewer.GoHome;
      VK_END, VK_NEXT:
        Viewer.GoEnd(ViewW, Rows);
      VK_LEFT:
        if not Viewer.Wrap and not Viewer.Hex then
          Viewer.LeftCol := Viewer.LeftCol - 20;
      VK_RIGHT:
        if not Viewer.Wrap and not Viewer.Hex then
          Viewer.LeftCol := Viewer.LeftCol + 20;
      Ord('R'):
        begin
          Viewer.Reread;
          Status(FarProduct + ': перечитан, ' + IntToStr(Viewer.Size) +
            ' байт');
        end;
      VK_TAB:
        if not FEditWide and (FSingle < 0) then
          FActive := 1 - FEditPanel;
    else
      // Прочие Ctrl+клавиши в просмотре - ничего
      Result := True;
    end;
  Invalidate;
end;

function TFarView.ViewKeyLabel(AKeyIndex: Integer; AShift, ACtrl,
  AAlt: Boolean): string;
begin
  Result := '';
  if AAlt then
  begin
    if AKeyIndex = 7 then
      Result := 'Goto';
    Exit;
  end;
  if ACtrl then
    Exit;
  if AShift then
  begin
    if AKeyIndex = 6 then
      Result := 'Next';
    Exit;
  end;
  case AKeyIndex of
    1:
      if FViewer.Wrap then
        Result := 'Unwrap'
      else
        Result := 'Wrap';
    2, 9:
      Result := 'Quit';
    3:
      if FViewer.Hex then
        Result := 'Text'
      else
        Result := 'Hex';
    4:
      Result := 'Wide';
    5:
      Result := 'Edit';
    6:
      Result := 'Search';
    7:
      case FViewer.NextEncoding of
        fvAnsi: Result := 'ANSI';
        fvOem: Result := 'OEM';
        fvUtf8: Result := 'UTF-8';
      else
        Result := 'UTF-16';
      end;
  end;
end;

procedure TFarView.DrawViewer;
var
  ViewX, ViewW, PanelH, TextRows, RowIdx, Row, HlStart, HlLen: Integer;
  Shown: TFarViewRows;
  TextFg, PageBg, HlFg, HlBg: TColor;
  Title, RightText, LineText: WideString;
  Pct: Integer;
begin
  EditBounds(ViewX, ViewW);
  PanelH := PanelHeight;
  if (ViewW < 4) or (PanelH < 2) then
    Exit;
  TextRows := PanelH - 1;
  Shown := FViewer.Rows(FViewer.Top, ViewW, TextRows);
  // Заголовок: имя файла; справа - процент (до конца экрана), кодировка,
  // режим
  if Length(Shown) > 0 then
    Pct := FViewer.Percent(Shown[High(Shown)].Stop)
  else
    Pct := 100;
  RightText := ' ' + IntToStr(Pct) + '%  ' +
    WideString(FarViewEncodingName(FViewer.Encoding));
  if FViewer.Hex then
    RightText := RightText + '  Hex'
  else if not FViewer.Wrap and (FViewer.LeftCol > 0) then
    RightText := RightText + '  Col ' + IntToStr(FViewer.LeftCol + 1);
  RightText := RightText + ' ';
  if Length(RightText) > ViewW - 8 then
    RightText := '';
  FillCells(ViewX, 0, ViewW, FPal[fpEditTitleBack]);
  Title := ' ' + FarFitPath(FViewer.FileName, ViewW - Length(RightText) - 2);
  PutText(ViewX, 0, ViewW - Length(RightText), Title, FPal[fpEditTitleText],
    FPal[fpEditTitleBack]);
  if RightText <> '' then
    PutText(ViewX + ViewW - Length(RightText), 0, Length(RightText),
      RightText, FPal[fpEditTitleText], FPal[fpEditTitleBack]);
  // Цвета: заданы для редактора в палитре - они, нет - цвета панели
  TextFg := FPal[fpPanelText];
  PageBg := FPal[fpPanelBack];
  if FPal[fpEditText] <> clNone then
    TextFg := FPal[fpEditText];
  if FPal[fpEditBack] <> clNone then
    PageBg := FPal[fpEditBack];
  HlFg := FPal[fpEditSelText];
  HlBg := FPal[fpEditSelBack];
  for RowIdx := 0 to TextRows - 1 do
  begin
    Row := RowIdx + 1;
    if RowIdx > High(Shown) then
    begin
      FillCells(ViewX, Row, ViewW, PageBg);
      Continue;
    end;
    LineText := Shown[RowIdx].Text;
    PutText(ViewX, Row, ViewW, LineText, TextFg, PageBg);
    HlStart := Shown[RowIdx].HlStart;
    HlLen := Shown[RowIdx].HlLen;
    if HlStart >= ViewW then
      HlLen := 0;
    if HlStart + HlLen > ViewW then
      HlLen := ViewW - HlStart;
    if HlLen > 0 then
      PutText(ViewX + HlStart, Row, HlLen, Copy(LineText, HlStart + 1, HlLen),
        HlFg, HlBg);
  end;
end;

// Закрытие unIDE: текст в редакторе FAR изменён - спросить (окном
// Windows: окна FAR может быть не видно). False - не закрывать
function TFarView.EditorCanClose: Boolean;
var
  Answer: Integer;
  Prompt: WideString;
  Lossy: Boolean;
  ErrorText: string;
  Encoding: TFarEditEncoding;
begin
  Result := True;
  if (FEditor = nil) or not FEditor.Modified then
    Exit;
  Prompt := 'Файл ' + FEditor.FileName + ' изменён в редакторе ' +
    WideString(FarProduct) + '.'#13#10'Записать изменения?';
  Answer := FarMessageBox(GetParentFormHandle, PWideChar(Prompt),
    PWideChar(WideString(FarProduct)), MB_YESNOCANCEL or MB_ICONQUESTION);
  if Answer = IDNO then
    Exit;
  if Answer <> IDYES then
  begin
    Result := False;
    Exit;
  end;
  Encoding := FEditor.Encoding;
  if not FEditor.SaveToFile(FEditor.FileName, Encoding, False, Lossy,
     ErrorText) and Lossy then
  begin
    Prompt := 'В кодировке Windows нет некоторых символов текста.'#13#10 +
      'Да - записать в UTF-8, Нет - заменить их на "?".';
    Answer := FarMessageBox(GetParentFormHandle, PWideChar(Prompt),
      PWideChar(WideString(FarProduct)), MB_YESNOCANCEL or MB_ICONQUESTION);
    if Answer = IDYES then
      FEditor.SaveToFile(FEditor.FileName, feUtf8, False, Lossy, ErrorText)
    else if Answer = IDNO then
      FEditor.SaveToFile(FEditor.FileName, Encoding, True, Lossy, ErrorText)
    else
    begin
      Result := False;
      Exit;
    end;
  end;
  if FEditor.Modified then
  begin
    Prompt := 'Файл не записан: ' + WideString(ErrorText);
    FarMessageBox(GetParentFormHandle, PWideChar(Prompt),
      PWideChar(WideString(FarProduct)), MB_OK or MB_ICONERROR);
    Result := False;
  end;
end;

// Окно верхнего уровня, в котором FAR (форма unIDE, главное окно uniFAR) -
// владелец окон Windows (сообщения, ход операции, ShellExecute)
function TFarView.GetParentFormHandle: HWND;
begin
  Result := FarGetAncestor(Handle, FarGaRoot);
  if Result = 0 then
    Result := Handle;
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
      Status(FarProduct + ': диск ' + Root + ' не готов');
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

function TFarView.HistoryFind(const APath: WideString): Integer;
begin
  Result := High(FHistory);
  while (Result >= 0) and not FarSameName(FHistory[Result], APath) do
    Dec(Result);
end;

procedure TFarView.HistoryDelete(AIndex: Integer);
var
  MoveIndex: Integer;
begin
  if (AIndex < 0) or (AIndex > High(FHistory)) then
    Exit;
  for MoveIndex := AIndex to High(FHistory) - 1 do
  begin
    FHistory[MoveIndex] := FHistory[MoveIndex + 1];
    FHistoryLock[MoveIndex] := FHistoryLock[MoveIndex + 1];
  end;
  SetLength(FHistory, Length(FHistory) - 1);
  SetLength(FHistoryLock, Length(FHistory));
end;

procedure TFarView.HistoryClearUnlocked;
var
  HistoryIndex: Integer;
begin
  for HistoryIndex := High(FHistory) downto 0 do
    if not FHistoryLock[HistoryIndex] then
      HistoryDelete(HistoryIndex);
end;

// Папка уходит в конец списка (закрепление сохраняется). При переполнении
// вытесняются самые старые незакреплённые
procedure TFarView.HistoryAdd(const APath: WideString);
var
  HistoryIndex: Integer;
  WasLocked: Boolean;
begin
  if APath = '' then
    Exit;
  SetLength(FHistoryLock, Length(FHistory));
  WasLocked := False;
  HistoryIndex := HistoryFind(APath);
  while HistoryIndex >= 0 do
  begin
    WasLocked := WasLocked or FHistoryLock[HistoryIndex];
    HistoryDelete(HistoryIndex);
    HistoryIndex := HistoryFind(APath);
  end;
  SetLength(FHistory, Length(FHistory) + 1);
  SetLength(FHistoryLock, Length(FHistory));
  FHistory[High(FHistory)] := APath;
  FHistoryLock[High(FHistory)] := WasLocked;
  while Length(FHistory) > FarHistoryMax do
  begin
    HistoryIndex := 0;
    while (HistoryIndex < High(FHistory)) and FHistoryLock[HistoryIndex] do
      Inc(HistoryIndex);
    if HistoryIndex >= High(FHistory) then
      Break;
    HistoryDelete(HistoryIndex);
  end;
end;

// Меню истории: Enter - перейти, Ins - закрепить, Shift+Del - убрать
// папку, Del - очистить (закреплённые остаются)
procedure TFarView.ShowHistoryMenu(ACursor: Integer);
var
  Items: TFarMenuItems;
  HistoryIndex: Integer;
  ShownPath: WideString;
begin
  SetLength(FHistoryLock, Length(FHistory));
  if Length(FHistory) = 0 then
  begin
    Status(FarProduct + ': история папок пуста');
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
    if FHistoryLock[HistoryIndex] then
      Items[HistoryIndex].Mark := FarCheckMark
    else
      Items[HistoryIndex].Mark := ' ';
    Items[HistoryIndex].Separator := False;
    Items[HistoryIndex].Data := FHistory[HistoryIndex];
    Items[HistoryIndex].Tag := HistoryIndex;
  end;
  if (ACursor < 0) or (ACursor > High(Items)) then
    ACursor := High(Items);
  MenuOpen(fmHistory, 'Folders history', Items, ACursor, FActive);
end;

// ---------------------------------------------------------------------------
//  Командная строка (над кейбаром) и вывод команд (под панелями)
// ---------------------------------------------------------------------------

function TFarView.CmdRow: Integer;
begin
  Result := FRows - KeyBarRows - 1;
end;

// Последняя строка вывода команд (и панелей): над командной строкой, а
// есть строка сообщений - над ней
function TFarView.OutBottom: Integer;
begin
  Result := CmdRow - 1;
  if FMessageLine then
    Dec(Result);
end;

procedure TFarView.SetMessageLine(AValue: Boolean);
begin
  if AValue = FMessageLine then
    Exit;
  FMessageLine := AValue;
  EnsureVisible(FPanels[0]);
  EnsureVisible(FPanels[1]);
  Invalidate;
end;

// Строка сообщений: цвета строки вывода команд
procedure TFarView.DrawMessageLine;
var
  Row: Integer;
  Shown: WideString;
begin
  Row := CmdRow - 1;
  if Row < 0 then
    Exit;
  FillCells(0, Row, FCols, FPal[fpCmdBack]);
  Shown := FMessageText;
  if Length(Shown) > FCols then
    Shown := Copy(Shown, 1, FCols - 3) + '...';
  PutText(0, Row, Length(Shown), Shown, FPal[fpOutText], FPal[fpCmdBack]);
end;

// Приглашение: путь активной панели и '>' (как у cmd.exe)
function TFarView.PromptText: WideString;
begin
  Result := ActivePanel.Path;
  if (Length(Result) > 3) and (Result[Length(Result)] = '\') then
    SetLength(Result, Length(Result) - 1);
  Result := Result + '>';
end;

procedure TFarView.CmdSetText(const AText: WideString);
begin
  FCmdText := AText;
  FCmdPos := Length(FCmdText);
  Invalidate;
end;

procedure TFarView.CmdInsert(const AText: WideString);
var
  Clean: WideString;
  CharIndex: Integer;
begin
  // Переводы строк из буфера обмена - пробелами: строка одна
  Clean := AText;
  for CharIndex := 1 to Length(Clean) do
    if (Clean[CharIndex] = #13) or (Clean[CharIndex] = #10) or
       (Clean[CharIndex] = #9) then
      Clean[CharIndex] := ' ';
  if FCmdPos > Length(FCmdText) then
    FCmdPos := Length(FCmdText);
  Insert(Clean, FCmdText, FCmdPos + 1);
  Inc(FCmdPos, Length(Clean));
  FCmdHistPos := Length(FCmdHistory);
  Invalidate;
end;

procedure TFarView.CopyToClipboard(const AText: WideString);
begin
  if FarCopyToClipboard(Handle, AText) then
    Status('В буфере: ' + string(AText))
  else
    Status(FarProduct + ': буфер обмена занят - не скопировано');
end;

function TFarView.CursorFullName: WideString;
var
  Panel: TFarPanel;
  BaseDir: WideString;
begin
  Result := '';
  Panel := ActivePanel;
  if (Panel.Cursor < 0) or (Panel.Cursor >= Panel.Count) then
    Exit;
  if Panel.FFtpMode = 2 then
  begin
    // 'ftp://user@host/dir/' + имя
    BaseDir := Panel.DisplayPath;
    if (BaseDir <> '') and (BaseDir[Length(BaseDir)] <> '/') then
      BaseDir := BaseDir + '/';
  end
  else if Panel.FFtpMode = 1 then
    BaseDir := ''
  else if Panel.IsArchive then
    BaseDir := Panel.DisplayPath + '\'
  else
    BaseDir := Panel.Path;
  if Panel.FItems[Panel.Cursor].IsUp then
  begin
    Result := BaseDir;
    // 'D:\a\' -> 'D:\a' (корень диска 'D:\' - как есть)
    if (Length(Result) > 3) and (Result[Length(Result)] = '\') then
      SetLength(Result, Length(Result) - 1);
  end
  else
    Result := BaseDir + Panel.FItems[Panel.Cursor].Name;
end;

// Клавиши командной строки. True - клавиша её (AHandled - забрать ли
// нажатие: False - пусть придёт символом WM_CHAR); False - не её, дальше
// панелям. Пока строка не пуста, Enter, Esc, Backspace и Del - её: Del
// не удаляет файлы
function TFarView.CmdKey(AKey: Word; AShift, ACtrl, AAlt: Boolean;
  var AHandled: Boolean): Boolean;
var
  Panel: TFarPanel;
  Insertion: WideString;
begin
  Result := True;
  AHandled := True;
  if AAlt then
  begin
    Result := False;
    Exit;
  end;
  if ACtrl then
  begin
    case AKey of
      Ord('O'):                       // спрятать / показать панели
        begin
          FPanelsHidden := not FPanelsHidden;
          FOutScroll := 0;
          Invalidate;
        end;
      Ord('E'), Ord('X'):             // история: старше / новее
        begin
          if Length(FCmdHistory) = 0 then
            Exit;
          if AKey = Ord('E') then
          begin
            if FCmdHistPos > 0 then
              Dec(FCmdHistPos);
          end
          else if FCmdHistPos < Length(FCmdHistory) then
            Inc(FCmdHistPos);
          if FCmdHistPos < Length(FCmdHistory) then
            CmdSetText(FCmdHistory[FCmdHistPos])
          else
            CmdSetText('');
        end;
      Ord('Y'):                       // очистить
        CmdSetText('');
      Ord('S'):                       // каретка влево
        begin
          if FCmdPos > 0 then
            Dec(FCmdPos);
          Invalidate;
        end;
      Ord('D'):                       // каретка вправо
        begin
          if FCmdPos < Length(FCmdText) then
            Inc(FCmdPos);
          Invalidate;
        end;
      VK_LEFT, VK_RIGHT:              // каретка на слово; строка пуста -
        if FCmdText = '' then         // ширина панелей (дальше, панелям)
          Result := False
        else
        begin
          if AKey = VK_LEFT then
          begin
            while (FCmdPos > 0) and (FCmdText[FCmdPos] = ' ') do
              Dec(FCmdPos);
            while (FCmdPos > 0) and (FCmdText[FCmdPos] <> ' ') do
              Dec(FCmdPos);
          end
          else
          begin
            while (FCmdPos < Length(FCmdText)) and
                  (FCmdText[FCmdPos + 1] <> ' ') do
              Inc(FCmdPos);
            while (FCmdPos < Length(FCmdText)) and
                  (FCmdText[FCmdPos + 1] = ' ') do
              Inc(FCmdPos);
          end;
          Invalidate;
        end;
      Ord('V'):                       // вставить
        if FarClipboardHasText then
          CmdInsert(FarClipboardText);
      VK_RETURN:                      // имя файла под курсором
        begin
          Panel := ActivePanel;
          if (Panel.Cursor >= 0) and (Panel.Cursor < Panel.Count) then
            CmdInsert(FarQuoteName(Panel.FItems[Panel.Cursor].Name) + ' ');
        end;
      FarVkLeftBracket, FarVkRightBracket:  // путь левой / правой панели
        begin
          if AKey = FarVkLeftBracket then
            Insertion := FPanels[0].Path
          else
            Insertion := FPanels[1].Path;
          CmdInsert(FarQuoteName(Insertion) + ' ');
          CopyToClipboard(Insertion);
        end;
      Ord('F'):                       // полный путь файла под курсором
        begin
          Insertion := CursorFullName;
          if Insertion <> '' then
          begin
            CmdInsert(FarQuoteName(Insertion) + ' ');
            CopyToClipboard(Insertion);
          end;
        end;
      VK_INSERT:                      // имя файла под курсором - в буфер
        begin
          Panel := ActivePanel;
          if (Panel.Cursor >= 0) and (Panel.Cursor < Panel.Count) and
             not Panel.FItems[Panel.Cursor].IsUp then
            CopyToClipboard(Panel.FItems[Panel.Cursor].Name)
          else
            Status(FarProduct + ': курсор на "..", имени для буфера нет');
        end;
      VK_CANCEL:                      // Ctrl+Break - прервать команду
        if FProcHandle <> 0 then
        begin
          ProcFinish(True);
          OutLine('^C');
          Invalidate;
        end;
    else
      Result := False;
    end;
    Exit;
  end;

  // Без Ctrl и Alt
  case AKey of
    VK_RETURN:
      if FCmdText <> '' then
        CmdExecute
      else
        Result := False;
    VK_ESCAPE:
      if FCmdText <> '' then
        CmdSetText('')
      else
        Result := False;
    VK_BACK:
      if FCmdText <> '' then
      begin
        if FCmdPos > 0 then
        begin
          Delete(FCmdText, FCmdPos, 1);
          Dec(FCmdPos);
        end;
        Invalidate;
      end
      else
        Result := False;
    VK_DELETE:
      if FCmdText <> '' then
      begin
        if FCmdPos < Length(FCmdText) then
          Delete(FCmdText, FCmdPos + 1, 1);
        Invalidate;
      end
      else
        Result := False;
    VK_INSERT:
      if AShift then
      begin
        if FarClipboardHasText then
          CmdInsert(FarClipboardText);
      end
      else
        Result := False;
  else
    Result := False;
  end;
end;

procedure TFarView.CmdHistoryAdd(const ACommand: WideString);
var
  HistoryIndex, MoveIndex: Integer;
begin
  for HistoryIndex := High(FCmdHistory) downto 0 do
    if FCmdHistory[HistoryIndex] = ACommand then
    begin
      for MoveIndex := HistoryIndex to High(FCmdHistory) - 1 do
        FCmdHistory[MoveIndex] := FCmdHistory[MoveIndex + 1];
      SetLength(FCmdHistory, Length(FCmdHistory) - 1);
    end;
  SetLength(FCmdHistory, Length(FCmdHistory) + 1);
  FCmdHistory[High(FCmdHistory)] := ACommand;
  if Length(FCmdHistory) > FarCmdHistoryMax then
  begin
    for MoveIndex := 0 to FarCmdHistoryMax - 1 do
      FCmdHistory[MoveIndex] := FCmdHistory[MoveIndex + Length(FCmdHistory) -
        FarCmdHistoryMax];
    SetLength(FCmdHistory, FarCmdHistoryMax);
  end;
  FCmdHistPos := Length(FCmdHistory);
end;

// Enter: команда - в вывод (с приглашением) и в историю; своя (cd, X:,
// cls) - выполняется здесь, остальные - cmd.exe
procedure TFarView.CmdExecute;
var
  Command: WideString;
begin
  Command := FarTrimW(FCmdText);
  if Command = '' then
    Exit;
  if FProcHandle <> 0 then
  begin
    Status(FarProduct + ': прежняя команда ещё выполняется (Ctrl+Break - ' +
      'прервать)');
    Exit;
  end;
  CmdHistoryAdd(Command);
  CmdSetText('');
  FOutScroll := 0;
  OutLine(PromptText + Command);
  if not CmdBuiltin(Command) then
    CmdRun(Command);
  // Вывода не видно (панели во всё окно) - подсказка
  if not FPanelsHidden and (PanelHeight > OutBottom) then
    Status(FarProduct + ': вывод команды - Ctrl+O или Ctrl+Up');
  Invalidate;
end;

// Свои команды: смена папки и диска панели, очистка вывода. True -
// выполнена здесь
function TFarView.CmdBuiltin(const ACommand: WideString): Boolean;
var
  Lower, Arg, Target, ParentDir, ChildName: WideString;
  FullBuffer: array[0..MAX_PATH] of WideChar;
  FullLen: DWORD;
  Code: Integer;
begin
  Result := False;
  Lower := WideLowerCase(ACommand);

  // X: - диск
  if (Length(ACommand) = 2) and (ACommand[2] = ':') then
  begin
    Code := Ord(Lower[1]);
    if (Code >= Ord('a')) and (Code <= Ord('z')) then
    begin
      SelectDrive(FActive, WideChar(Code - 32));
      Result := True;
    end;
    Exit;
  end;

  if Lower = 'cls' then
  begin
    FOutLines := nil;
    FOutOpen := False;
    Result := True;
    Exit;
  end;

  // cd путь, cd.., cd\, chdir путь, cd /d путь
  Arg := '';
  if Copy(Lower, 1, 5) = 'chdir' then
  begin
    if (Length(Lower) > 5) and not ((Lower[6] = ' ') or (Lower[6] = '.') or
       (Lower[6] = '\')) then
      Exit;
    Arg := Copy(ACommand, 6, MaxInt);
  end
  else if Copy(Lower, 1, 2) = 'cd' then
  begin
    if (Length(Lower) > 2) and not ((Lower[3] = ' ') or (Lower[3] = '.') or
       (Lower[3] = '\')) then
      Exit;
    Arg := Copy(ACommand, 3, MaxInt);
  end
  else
    Exit;
  Result := True;
  Arg := FarTrimW(Arg);
  if WideLowerCase(Copy(Arg, 1, 3)) = '/d ' then
    Arg := FarTrimW(Copy(Arg, 4, MaxInt));
  if (Length(Arg) >= 2) and (Arg[1] = '"') and (Arg[Length(Arg)] = '"') then
    Arg := Copy(Arg, 2, Length(Arg) - 2);
  if Arg = '' then
  begin
    OutLine(Copy(PromptText, 1, Length(PromptText) - 1));
    Exit;
  end;
  Target := FarFullPath(ActivePanel.Path, Arg);
  // '..' и '.' в пути - полным путём Windows
  FullLen := FarGetFullPath(PWideChar(Target), MAX_PATH + 1, FullBuffer, nil);
  if (FullLen > 0) and (FullLen <= MAX_PATH) then
    Target := PWideChar(@FullBuffer[0]);
  if FarDirExists(Target) then
  begin
    ChangeDir(ActivePanel, Target, '');
    Exit;
  end;
  // Нет папки - папка на уровень выше (без последней папки пути)
  ParentDir := FarParentOf(FarWithSlash(Target), ChildName);
  if (ParentDir <> '') and FarDirExists(ParentDir) then
  begin
    OutLine('Папка ' + FarStripSlash(Target) + ' не существует - открыта ' +
      FarStripSlash(ParentDir));
    Status(FarProduct + ': папка ' + string(FarStripSlash(Target)) +
      ' не существует - открыта папка выше');
    ChangeDir(ActivePanel, ParentDir, '');
    Exit;
  end;
  // Нет и её - сообщение, команда - снова в строке ввода: поправить и
  // повторить
  OutLine('Папка ' + FarStripSlash(Target) + ' не существует');
  Status(FarProduct + ': папка ' + string(FarStripSlash(Target)) +
    ' не существует - поправьте путь и нажмите Enter');
  CmdSetText(FarTrimW(ACommand));
end;

// Внешняя команда: cmd.exe /C в папке активной панели, вывод (stdout и
// stderr) - в трубу, ввода нет (программа, ждущая ввода, получит конец
// файла). Окна консоли нет. Вывод читает ProcTick.
procedure TFarView.CmdRun(const ACommand: WideString);
var
  ComSpec: WideString;
  EnvBuffer: array[0..MAX_PATH] of WideChar;
  EnvLen: DWORD;
begin
  EnvLen := FarGetEnvVar('ComSpec', EnvBuffer, MAX_PATH + 1);
  if (EnvLen > 0) and (EnvLen <= MAX_PATH) then
    ComSpec := PWideChar(@EnvBuffer[0])
  else
    ComSpec := 'cmd.exe';
  StartProcess(WideString('"') + ComSpec + WideString('" /C ') + ACommand,
    ActivePanel.Path, False);
end;

// Процесс без окна консоли: stdout и stderr - в трубу, ввода нет (конец
// файла). ACapture - вывод в буфер FProcRaw (7z.exe), иначе - в окно
// вывода (OEM). Вывод читает ProcTick, конец - ProcFinish
function TFarView.StartProcess(const ACommandLine, AWorkDir: WideString;
  ACapture: Boolean): Boolean;
var
  Security: TFarSecurityAttributes;
  OutRead, OutWrite, InRead, InWrite: THandle;
  Startup: TFarStartupInfo;
  ProcInfo: TFarProcessInfo;
  CommandLine, WorkDir: WideString;
  PipeSize: DWORD;
begin
  Result := False;
  Security.nLength := SizeOf(Security);
  Security.lpSecurityDescriptor := nil;
  Security.bInheritHandle := True;
  // Список большого архива - мегабайты: труба побольше
  if ACapture then
    PipeSize := 1024 * 1024
  else
    PipeSize := 0;
  if not FarCreatePipe(OutRead, OutWrite, @Security, PipeSize) then
  begin
    OutLine(FarProduct + ': трубу вывода не создать: ' +
      SysErrorMessage(GetLastError));
    Exit;
  end;
  if not FarCreatePipe(InRead, InWrite, @Security, 0) then
  begin
    CloseHandle(OutRead);
    CloseHandle(OutWrite);
    OutLine(FarProduct + ': трубу ввода не создать: ' +
      SysErrorMessage(GetLastError));
    Exit;
  end;
  // Наши концы труб процессу не нужны
  FarSetHandleInfo(OutRead, FarHandleInherit, 0);
  FarSetHandleInfo(InWrite, FarHandleInherit, 0);

  CommandLine := ACommandLine;
  WorkDir := AWorkDir;
  FillChar(Startup, SizeOf(Startup), 0);
  Startup.cb := SizeOf(Startup);
  Startup.dwFlags := FarStartfUseStdHandles or FarStartfUseShowWindow;
  Startup.wShowWindow := SW_HIDE;
  Startup.hStdInput := InRead;
  Startup.hStdOutput := OutWrite;
  Startup.hStdError := OutWrite;
  FillChar(ProcInfo, SizeOf(ProcInfo), 0);
  // Строка команды CreateProcessW может менять - у WideString она и так
  // своя (не общая с другими строками)
  if not FarCreateProcess(nil, PWideChar(CommandLine), nil, nil, True,
       FarCreateNoWindow, nil, PWideChar(WorkDir), Startup, ProcInfo) then
  begin
    OutLine(FarProduct + ': не запустить: ' + SysErrorMessage(GetLastError));
    CloseHandle(OutRead);
    CloseHandle(OutWrite);
    CloseHandle(InRead);
    CloseHandle(InWrite);
    Exit;
  end;
  // Концы процесса закрываем у себя: иначе труба не кончится вместе с ним
  CloseHandle(OutWrite);
  CloseHandle(InRead);
  CloseHandle(InWrite);
  CloseHandle(ProcInfo.hThread);
  FProcHandle := ProcInfo.hProcess;
  FProcPipe := OutRead;
  FProcCapture := ACapture;
  FProcRaw := '';
  FProcTimer.Enabled := True;
  Result := True;
end;

// Вывод процесса: что есть в трубе - прочитать (OEM -> Unicode); процесс
// закончился и труба пуста - закрыть
procedure TFarView.ProcTick(Sender: TObject);
var
  Available, BytesRead: DWORD;
  Buffer: array[0..8191] of AnsiChar;
  WideBuffer: array[0..8192] of WideChar;
  WideLen, Rounds, MaxRounds, OldLen: Integer;
  Text: WideString;
  Changed: Boolean;
begin
  if FProcHandle = 0 then
  begin
    FProcTimer.Enabled := False;
    Exit;
  end;
  Changed := False;
  Rounds := 0;
  // В буфер (7z.exe) - читаем всё, что есть: список архива бывает большим
  if FProcCapture then
    MaxRounds := 4096
  else
    MaxRounds := 16;
  while Rounds < MaxRounds do
  begin
    Inc(Rounds);
    Available := 0;
    if not FarPeekPipe(FProcPipe, nil, 0, nil, @Available, nil) then
      Break;   // процесс закрыл свой конец - конец вывода
    if Available = 0 then
      Break;
    if Available > SizeOf(Buffer) then
      Available := SizeOf(Buffer);
    BytesRead := 0;
    if not FarReadFile(FProcPipe, @Buffer[0], Available, @BytesRead, nil) or
       (BytesRead = 0) then
      Break;
    if FProcCapture then
    begin
      OldLen := Length(FProcRaw);
      SetLength(FProcRaw, OldLen + Integer(BytesRead));
      Move(Buffer[0], FProcRaw[OldLen + 1], BytesRead);
      if FArcAction in [aaAdd, aaExtract, aaOpenFile] then
        ArcAddProgress;
      Continue;
    end;
    WideLen := FarMultiToWide(FarCpOem, 0, @Buffer[0], BytesRead,
      @WideBuffer[0], Length(WideBuffer) - 1);
    if WideLen > 0 then
    begin
      WideBuffer[WideLen] := #0;
      Text := PWideChar(@WideBuffer[0]);
      OutAppend(Text);
      Changed := True;
    end;
  end;
  // «Отмена» в окне хода распаковки / упаковки - прервать 7z.exe
  if (FArcProgress <> nil) and FArcProgress.Active and
     FArcProgress.Cancelled then
  begin
    ProcFinish(True);
    Invalidate;
    Exit;
  end;
  if WaitForSingleObject(FProcHandle, 0) = WAIT_OBJECT_0 then
  begin
    Available := 0;
    if not FarPeekPipe(FProcPipe, nil, 0, nil, @Available, nil) or
       (Available = 0) then
    begin
      ProcFinish(False);
      Changed := True;
    end;
  end;
  if Changed then
    Invalidate;
end;

// Конец команды (AKill - прервать): закрыть процесс и трубу; ненулевой
// код выхода - в строку состояния
procedure TFarView.ProcFinish(AKill: Boolean);
var
  ProcExitCode: DWORD;
  WasCapture: Boolean;
begin
  FProcTimer.Enabled := False;
  // Окно хода - закрыть до переноса файлов на место (у него своё окно)
  if FArcProgress <> nil then
    FArcProgress.Stop;
  ProcExitCode := 0;
  WasCapture := FProcCapture;
  if FProcHandle <> 0 then
  begin
    if AKill then
      FarTerminate(FProcHandle, 1)
    else if not FarGetExitCode(FProcHandle, ProcExitCode) then
      ProcExitCode := 0
    else if (ProcExitCode <> 0) and not WasCapture then
      Status(FarProduct + ': команда завершилась с кодом ' +
        IntToStr(ProcExitCode));
    CloseHandle(FProcHandle);
  end;
  if FProcPipe <> 0 then
    CloseHandle(FProcPipe);
  FProcHandle := 0;
  FProcPipe := 0;
  FProcCapture := False;
  FOutOpen := False;
  // 7z.exe: что дальше - по работе с архивом
  if FArcAction <> aaNone then
  begin
    if AKill then
    begin
      ArcCleanupTemp;
      // Упаковку в новый архив прервали - недописанный архив удалить
      if (FArcAction = aaAdd) and not FArcJobExists then
        FarDeleteFile(PWideChar(FArcJobFile));
      FArcAction := aaNone;
      Status(FarProduct + ': работа с архивом прервана');
    end
    else
      ArcDone(ProcExitCode);
  end;
end;

// Текст вывода: переводы строк - новые строки, табуляция - пробелами до
// 8, прочие управляющие символы пропускаются
procedure TFarView.OutAppend(const AText: WideString);
var
  CharIndex, DropCount, MoveIndex: Integer;
  Current: WideString;
  Ch: WideChar;
begin
  if FOutOpen and (Length(FOutLines) > 0) then
    Current := FOutLines[High(FOutLines)]
  else
    Current := '';
  for CharIndex := 1 to Length(AText) do
  begin
    Ch := AText[CharIndex];
    if Ch = #10 then
    begin
      if FOutOpen and (Length(FOutLines) > 0) then
        FOutLines[High(FOutLines)] := Current
      else
      begin
        SetLength(FOutLines, Length(FOutLines) + 1);
        FOutLines[High(FOutLines)] := Current;
      end;
      FOutOpen := False;
      Current := '';
      Continue;
    end;
    if Ch = #13 then
      Continue;
    if not FOutOpen then
    begin
      SetLength(FOutLines, Length(FOutLines) + 1);
      FOutOpen := True;
      Current := '';
    end;
    if Ch = #9 then
      repeat
        Current := Current + ' ';
      until Length(Current) mod 8 = 0
    else if Ord(Ch) >= 32 then
      Current := Current + Ch;
  end;
  if FOutOpen and (Length(FOutLines) > 0) then
    FOutLines[High(FOutLines)] := Current;
  // Старые строки - прочь
  if Length(FOutLines) > FarOutMaxLines then
  begin
    DropCount := Length(FOutLines) - FarOutMaxLines + FarOutMaxLines div 4;
    for MoveIndex := 0 to Length(FOutLines) - DropCount - 1 do
      FOutLines[MoveIndex] := FOutLines[MoveIndex + DropCount];
    SetLength(FOutLines, Length(FOutLines) - DropCount);
  end;
end;

// Целая строка вывода (приглашение с командой, сообщение)
procedure TFarView.OutLine(const AText: WideString);
begin
  FOutOpen := False;
  OutAppend(AText + #10);
end;

// Вывод в строках ATopRow..ABottomRow: последние строки внизу (как в
// консоли), длинные переносятся, FOutScroll - сдвиг вверх
procedure TFarView.DrawOutput(ATopRow, ABottomRow: Integer);
var
  Rows, Need, LineIndex, ChunkCount, ChunkIndex, RowIndex, VisIndex: Integer;
  Visual: TFarNames;
  VisCount: Integer;
  Line: WideString;
begin
  Rows := ABottomRow - ATopRow + 1;
  if (Rows <= 0) or (FCols <= 0) then
    Exit;
  for RowIndex := ATopRow to ABottomRow do
    FillCells(0, RowIndex, FCols, FPal[fpCmdBack]);
  Need := Rows + FOutScroll;
  SetLength(Visual, Need);
  VisCount := 0;
  // Экранные строки с конца: Visual[0] - самая нижняя
  LineIndex := High(FOutLines);
  while (LineIndex >= 0) and (VisCount < Need) do
  begin
    Line := FOutLines[LineIndex];
    ChunkCount := (Length(Line) + FCols - 1) div FCols;
    if ChunkCount < 1 then
      ChunkCount := 1;
    ChunkIndex := ChunkCount - 1;
    while (ChunkIndex >= 0) and (VisCount < Need) do
    begin
      Visual[VisCount] := Copy(Line, ChunkIndex * FCols + 1, FCols);
      Inc(VisCount);
      Dec(ChunkIndex);
    end;
    Dec(LineIndex);
  end;
  // Прокрутили дальше начала - к началу
  if (LineIndex < 0) and (FOutScroll > VisCount - Rows) then
  begin
    FOutScroll := VisCount - Rows;
    if FOutScroll < 0 then
      FOutScroll := 0;
  end;
  for RowIndex := 0 to Rows - 1 do
  begin
    VisIndex := FOutScroll + RowIndex;
    if VisIndex >= VisCount then
      Break;
    PutText(0, ABottomRow - RowIndex, FCols, Visual[VisIndex], FPal[fpOutText],
      FPal[fpCmdBack]);
  end;
end;

// Командная строка: приглашение и текст, каретка - подчёркиванием (когда
// у окна фокус и нет диалога и меню)
procedure TFarView.DrawCmdLine;
var
  Row, PromptW, TextW, ScrollPos, CaretCol: Integer;
  Prompt, Shown: WideString;
begin
  Row := CmdRow;
  if Row < 0 then
    Exit;
  FillCells(0, Row, FCols, FPal[fpCmdBack]);
  Prompt := PromptText;
  // Длинный путь - его конец, на текст остаётся не меньше трети строки
  if Length(Prompt) > FCols * 2 div 3 then
    Prompt := FarFitPath(Prompt, FCols * 2 div 3);
  PromptW := Length(Prompt);
  TextW := FCols - PromptW - 1;
  if TextW < 1 then
    Exit;
  ScrollPos := 0;
  if FCmdPos > TextW then
    ScrollPos := FCmdPos - TextW;
  Shown := Copy(FCmdText, ScrollPos + 1, TextW);
  PutText(0, Row, PromptW, Prompt, FPal[fpCmdPrompt],
    FPal[fpCmdBack]);
  PutText(PromptW, Row, Length(Shown), Shown, FPal[fpCmdText],
    FPal[fpCmdBack]);
  if Focused and (FDlgKind = fdNone) and (FMenuKind = fmNone) then
  begin
    CaretCol := PromptW + FCmdPos - ScrollPos;
    FBuffer.Canvas.Brush.Style := bsSolid;
    FBuffer.Canvas.Brush.Color := FPal[fpCmdPrompt];
    FBuffer.Canvas.FillRect(Rect(CaretCol * FCellW, (Row + 1) * FCellH - 3,
      (CaretCol + 1) * FCellW, (Row + 1) * FCellH - 1));
  end;
end;

// ---------------------------------------------------------------------------
//  Архивы: 7z.exe (7-Zip) из папки tools\7zip рядом с exe unIDE.
//  Список - 7z l -slt -sccUTF-8 (в буфер, разбор - FarParseSlt);
//  распаковка - 7z x во временную папку и перенос на место (7z x кладёт
//  файлы с полным путём из архива). Всё - асинхронно, через StartProcess /
//  ProcTick / ProcFinish -> ArcDone.
// ---------------------------------------------------------------------------

// Подстрока в WideString (точно, с учётом регистра); 0 - нет
function FarPosText(const ASub, AText: WideString): Integer;
var
  StartIndex, SubIndex: Integer;
begin
  Result := 0;
  if (ASub = '') or (Length(ASub) > Length(AText)) then
    Exit;
  for StartIndex := 1 to Length(AText) - Length(ASub) + 1 do
  begin
    SubIndex := 1;
    while (SubIndex <= Length(ASub)) and
          (AText[StartIndex + SubIndex - 1] = ASub[SubIndex]) do
      Inc(SubIndex);
    if SubIndex > Length(ASub) then
    begin
      Result := StartIndex;
      Exit;
    end;
  end;
end;

// 'ГГГГ-ММ-ДД ЧЧ:ММ:СС[.ддддддд]' (местное время, как печатает 7z) -> UTC
function FarParseArcTime(const AText: WideString; var ATime: TFileTime): Boolean;
var
  SysTime: Windows.TSystemTime;
  LocalTime: TFileTime;
  Text: string;
begin
  Result := False;
  FillChar(ATime, SizeOf(ATime), 0);
  Text := Trim(string(AText));
  if Length(Text) < 19 then
    Exit;
  FillChar(SysTime, SizeOf(SysTime), 0);
  SysTime.wYear := StrToIntDef(Copy(Text, 1, 4), 0);
  SysTime.wMonth := StrToIntDef(Copy(Text, 6, 2), 0);
  SysTime.wDay := StrToIntDef(Copy(Text, 9, 2), 0);
  SysTime.wHour := StrToIntDef(Copy(Text, 12, 2), 0);
  SysTime.wMinute := StrToIntDef(Copy(Text, 15, 2), 0);
  SysTime.wSecond := StrToIntDef(Copy(Text, 18, 2), 0);
  if (SysTime.wYear < 1601) or (SysTime.wMonth < 1) or (SysTime.wDay < 1) then
    Exit;
  if not SystemTimeToFileTime(SysTime, LocalTime) then
    Exit;
  Result := LocalFileTimeToFileTime(LocalTime, ATime);
end;

// Разбор 7z l -slt: после строки '----------' - записи, по строке
// 'Ключ = значение', записи разделены пустой строкой. False - списка нет
// (не архив, ошибка)
function FarParseSlt(const AText: WideString;
  var AEntries: TFarArcEntries): Boolean;
var
  LineStart, LineEnd, EqPos, Count: Integer;
  Line, Key, Value: WideString;
  InList, HasPath, HasFolder: Boolean;
  Current: TFarArcEntry;
  CharIndex: Integer;

  procedure Flush;
  begin
    if HasPath and (Current.Path <> '') then
    begin
      if Count >= Length(AEntries) then
        SetLength(AEntries, Length(AEntries) * 2 + 64);
      AEntries[Count] := Current;
      Inc(Count);
    end;
    HasPath := False;
    HasFolder := False;
    Current.Path := '';
    Current.IsDir := False;
    Current.Size := 0;
    FillChar(Current.Time, SizeOf(Current.Time), 0);
  end;

begin
  SetLength(AEntries, 0);
  Count := 0;
  InList := False;
  HasPath := False;
  HasFolder := False;
  Current.Path := '';
  Current.IsDir := False;
  Current.Size := 0;
  FillChar(Current.Time, SizeOf(Current.Time), 0);
  LineStart := 1;
  while LineStart <= Length(AText) do
  begin
    LineEnd := LineStart;
    while (LineEnd <= Length(AText)) and (AText[LineEnd] <> #10) do
      Inc(LineEnd);
    Line := Copy(AText, LineStart, LineEnd - LineStart);
    if (Line <> '') and (Line[Length(Line)] = #13) then
      SetLength(Line, Length(Line) - 1);
    LineStart := LineEnd + 1;

    if not InList then
    begin
      if Line = '----------' then
        InList := True;
      Continue;
    end;
    if Line = '' then
    begin
      Flush;
      Continue;
    end;
    EqPos := FarPosText(' = ', Line);
    if EqPos = 0 then
    begin
      // 'Ключ =' без значения
      if (Length(Line) >= 2) and (Copy(Line, Length(Line) - 1, 2) = ' =') then
      begin
        Key := Copy(Line, 1, Length(Line) - 2);
        Value := '';
      end
      else
        Continue;
    end
    else
    begin
      Key := Copy(Line, 1, EqPos - 1);
      Value := Copy(Line, EqPos + 3, MaxInt);
    end;
    if Key = 'Path' then
    begin
      Flush;
      for CharIndex := 1 to Length(Value) do
        if Value[CharIndex] = '/' then
          Value[CharIndex] := '\';
      while (Value <> '') and (Value[Length(Value)] = '\') do
        SetLength(Value, Length(Value) - 1);
      Current.Path := Value;
      HasPath := True;
    end
    else if Key = 'Folder' then
    begin
      Current.IsDir := Value = '+';
      HasFolder := True;
    end
    else if Key = 'Size' then
      Current.Size := StrToInt64Def(string(Value), 0)
    else if Key = 'Modified' then
      FarParseArcTime(Value, Current.Time)
    else if (Key = 'Attributes') and not HasFolder and (Value <> '') and
            (Value[1] = 'D') then
      Current.IsDir := True;
  end;
  Flush;
  SetLength(AEntries, Count);
  Result := InList;
end;

// 7z.exe своего 7-Zip unIDE (SzSetup: tools\7zip у exe или в профиле);
// нет - ''
function TFarView.SevenZipPath: WideString;
begin
  Result := SzLocalExe;
end;

function TFarView.IsArchiveName(const AName: WideString): Boolean;
var
  Ext: WideString;
begin
  Ext := WideLowerCase(FarNameExt(AName));
  Result := (Ext <> '') and
            (FarPosText(' ' + Ext + ' ', WideString(FarArcExts)) > 0);
end;

// Операция, которой в архиве пока нет: сообщение, True
function TFarView.ArcBlocked: Boolean;
begin
  Result := ActivePanel.IsArchive;
  if Result then
    Status(FarProduct + ': в архиве пока только просмотр и распаковка (F5, ' +
      'Enter)');
end;

// Открыть архив AFile в панели APanelIndex (ANested - внутри текущего
// архива этой панели). Сначала - список (асинхронно), панель меняется в
// ArcApplyList
procedure TFarView.OpenArchive(APanelIndex: Integer; const AFile,
  ATitle: WideString; ANested: Boolean; const APassword: WideString);
begin
  if FProcHandle <> 0 then
  begin
    Status(FarProduct + ': выполняется команда - архив откроется после неё');
    Exit;
  end;
  FArcAction := aaList;
  FArcJobPanel := APanelIndex;
  FArcJobFile := AFile;
  FArcJobTitle := ATitle;
  FArcJobNested := ANested;
  FArcJobStart := FPanels[APanelIndex].DisplayPath;
  FArcJobPassword := APassword;
  FArcJobTemp := '';
  ArcRun;
end;

// Запуск 7z.exe для FArcAction (повтор с паролем - тоже сюда)
procedure TFarView.ArcRun;
var
  SevenZip, Command, ListFile: WideString;
  ListText: UTF8String;
  ListHandle: THandle;
  NameIndex: Integer;
  Written: DWORD;
  ListOk: Boolean;
begin
  SevenZip := SevenZipPath;
  if SevenZip = '' then
  begin
    // Нет 7-Zip - предложить скачать; работа с архивом (FArcAction и
    // остальное) ждёт и продолжится после установки
    SzOffer;
    Exit;
  end;
  Command := WideString('"') + SevenZip + WideString('"');
  if FArcAction = aaList then
  begin
    Command := Command + ' l -slt -sccUTF-8';
    if FArcJobPassword <> '' then
      Command := Command + WideString(' "-p') + FArcJobPassword +
        WideString('"');
    Command := Command + WideString(' "') + FArcJobFile + WideString('"');
    Status(FarProduct + ': открываю архив...');
  end
  else
  begin
    // Распаковка: что - списком в файле (UTF-8), куда - во временную папку
    ListFile := FArcJobTemp + '~unide_list.txt';
    if not FarForceDirs(FArcJobTemp) then
    begin
      Status(FarProduct + ': временную папку не создать: ' +
        SysErrorMessage(GetLastError));
      FArcAction := aaNone;
      Exit;
    end;
    ListText := '';
    for NameIndex := 0 to High(FArcJobNames) do
    begin
      if FArcJobPrefix <> '' then
        ListText := ListText + UTF8Encode(FArcJobPrefix + '\' +
          FArcJobNames[NameIndex]) + #13#10
      else
        ListText := ListText + UTF8Encode(FArcJobNames[NameIndex]) + #13#10;
    end;
    // Файл списка - W-функцией: в пути могут быть символы вне cp1251
    ListOk := False;
    ListHandle := FarCreateFile(PWideChar(ListFile), GENERIC_WRITE, 0, nil,
      CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if ListHandle <> INVALID_HANDLE_VALUE then
    begin
      Written := 0;
      ListOk := (ListText = '') or
        (WriteFile(ListHandle, ListText[1], Length(ListText), Written, nil) and
         (Integer(Written) = Length(ListText)));
      CloseHandle(ListHandle);
    end;
    if not ListOk then
    begin
      Status(FarProduct + ': список для 7-Zip не записать');
      ArcCleanupTemp;
      FArcAction := aaNone;
      Exit;
    end;
    if FArcAction = aaAdd then
    begin
      // Упаковка: имена из списка - относительно папки панели (рабочая
      // папка процесса); папки - со всем содержимым. -bsp1 - ход (проценты)
      Command := Command + ' a -t' + FarArcAddTypes[FArcJobFormat] +
        ' -mx=' + IntToStr(FArcJobLevel) +
        ' -sccUTF-8 -scsUTF-8 -bso0 -bsp1';
      if FArcJobPassword <> '' then
      begin
        Command := Command + WideString(' "-p') + FArcJobPassword +
          WideString('"');
        // 7z - шифровать и имена файлов; ZIP - AES-256 (не ZipCrypto)
        if FArcJobFormat = 1 then
          Command := Command + ' -mhe=on'
        else
          Command := Command + ' -mem=AES256';
      end;
      Command := Command + WideString(' "') + FArcJobFile +
        WideString('" "@') + ListFile + WideString('"');
      Status(FarProduct + ': упаковка... (Ctrl+Break - прервать)');
    end
    else
    begin
      // -bsp1 - ход (проценты и имя файла) - в окно хода
      Command := Command + ' x -y -sccUTF-8 -scsUTF-8 -bso0 -bsp1';
      // Без пароля -p не ставим: '-p' без значения - вопрос пароля
      if FArcJobPassword <> '' then
        Command := Command + WideString(' "-p') + FArcJobPassword +
          WideString('"');
      Command := Command + WideString(' "-o') +
        Copy(FArcJobTemp, 1, Length(FArcJobTemp) - 1) + WideString('" "') +
        FArcJobFile + WideString('" "@') + ListFile + WideString('"');
      Status(FarProduct + ': распаковка...');
    end;
  end;
  if not StartProcess(Command, FPanels[FArcJobPanel].Path, True) then
  begin
    ArcCleanupTemp;
    FArcAction := aaNone;
  end
  else if FArcAction in [aaExtract, aaOpenFile, aaAdd] then
    ArcProgressStart;
end;

// Окно хода Windows для распаковки / упаковки: оболочка покажет его, если
// работа затянется; «Отмена» в нём - как Ctrl+Break (ProcTick)
procedure TFarView.ArcProgressStart;
var
  ParentWnd: HWND;
  Title, Line1: WideString;
begin
  if FArcProgress = nil then
    FArcProgress := TFarProgress.Create;
  ParentWnd := GetParentFormHandle;
  if FArcAction = aaAdd then
  begin
    Title := FarProduct + ' - упаковка';
    Line1 := 'В архив ' + FArcJobFile;
  end
  else
  begin
    Title := FarProduct + ' - распаковка';
    Line1 := 'Из архива ' + FArcJobFile;
  end;
  FArcAddPercent := -1;
  FArcProgress.Start(ParentWnd, Title, Line1);
end;

// Сообщение об ошибке 7-Zip: первая строка с ERROR / Error / Wrong
procedure TFarView.ArcError(const AOutput: WideString);
var
  LineStart, LineEnd: Integer;
  Line, Found: WideString;
begin
  Found := '';
  LineStart := 1;
  while (LineStart <= Length(AOutput)) and (Found = '') do
  begin
    LineEnd := LineStart;
    while (LineEnd <= Length(AOutput)) and (AOutput[LineEnd] <> #10) do
      Inc(LineEnd);
    Line := FarTrimW(Copy(AOutput, LineStart, LineEnd - LineStart));
    LineStart := LineEnd + 1;
    if (FarPosText('ERROR', Line) > 0) or (FarPosText('Error', Line) > 0) or
       (FarPosText('Is not archive', Line) > 0) or
       (FarPosText('Wrong password', Line) > 0) then
      Found := Line;
  end;
  if Found = '' then
    Found := 'архив не открыть';
  Status(FarProduct + ': 7-Zip: ' + string(Found));
  // Весь ответ 7-Zip - в вывод под панелями
  OutLine('7-Zip: ' + FArcJobFile);
  OutAppend(AOutput);
  OutLine('');
end;

procedure TFarView.ArcCleanupTemp;
begin
  if FArcJobTemp = '' then
    Exit;
  FarDeleteTree(FArcJobTemp);
  FArcJobTemp := '';
end;

// ---------------------------------------------------------------------------
//  Нет своего 7-Zip unIDE (tools\7zip, SzSetup) - скачать: сборка по
//  Windows, установка в своём потоке (TSzInstall), окно хода; потом -
//  работа с архивом, ради которой 7-Zip понадобился. Системный 7-Zip не
//  используется и не меняется
// ---------------------------------------------------------------------------

procedure TFarView.SzOffer;
var
  OsInfo: TSzOsInfo;
  ToolFile: TSzFile;
  SizeText: string;
begin
  if (FSzThread <> nil) or SzInstallRunning then
  begin
    FArcAction := aaNone;
    Status(FarProduct + ': 7-Zip уже устанавливается');
    Exit;
  end;
  SzGetOsInfo(OsInfo);
  FSzOsName := OsInfo.Name;
  FSzTarget := SzChooseTargetDir;
  if not SzChoosePackage(OsInfo, FSzPackage) then
  begin
    FArcAction := aaNone;
    DlgOpen(fdSzFail, '7-Zip', ['Для архивов нужен 7-Zip, его нет в папке',
      FarFitPath(SzAppDir, 62), '', '7-Zip работает в Windows 2000 и новее,',
      'а здесь ' + WideString(OsInfo.Name) + '.'], True, True, False, '',
      ['OK', 'Сайт 7-Zip']);
    Exit;
  end;
  if FSzTarget = '' then
  begin
    FArcAction := aaNone;
    SzFail('Нет папки для 7-Zip: в ' + SzAppDir + ' и ' + SzUserDir +
      ' не записать.');
    Exit;
  end;
  SzToolFile(ToolFile);
  SizeText := FormatFloat('0.0', (ToolFile.Size + FSzPackage.Size) /
    (1024 * 1024));
  DlgOpen(fdSzOffer, '7-Zip', ['Для архивов нужен свой 7-Zip unIDE,',
    'его нет. Системный 7-Zip не используется и не меняется.', '',
    'Система: ' + WideString(OsInfo.Name),
    'Скачать 7-Zip ' + WideString(FSzPackage.Version) + ' (' +
    WideString(FSzPackage.Arch) + ') с github.com/ip7z/7zip (' +
    WideString(SizeText) + ' МБ)', 'и распаковать в', FarFitPath(FSzTarget,
    62)], True, False, False, '', ['Скачать', 'Отмена']);
end;

procedure TFarView.SzStartDownload;
begin
  if (FSzThread <> nil) or SzInstallRunning then
  begin
    FArcAction := aaNone;
    Status(FarProduct + ': 7-Zip уже устанавливается');
    Exit;
  end;
  if FSzTarget = '' then
  begin
    FArcAction := aaNone;
    Exit;
  end;
  FSzThread := TSzInstall.Create(FSzTarget,
    Sz7ZipPlan(FSzPackage, FSzOsName));
  FSzTimer.Enabled := True;
  SzProgress;
end;

// Окно хода: файл, полоса, килобайты; распаковка - строкой
procedure TFarView.SzProgress;
const
  BarWidth = 50;
var
  FileLine, BarLine, BytesLine: WideString;
  Filled, CellIndex, DoneBytes, TotalBytes: Integer;
begin
  if FSzThread = nil then
    Exit;
  if FSzThread.Stage = ssExtract then
  begin
    FileLine := 'Распаковка 7z.exe и 7z.dll из ' +
      WideString(FSzPackage.FileName);
    BarLine := '';
    BytesLine := '';
  end
  else
  begin
    DoneBytes := FSzThread.Done;
    TotalBytes := FSzThread.Total;
    if FSzThread.FileIndex = 0 then
      FileLine := SzToolName
    else
      FileLine := FSzPackage.FileName;
    FileLine := 'Файл ' + IntToStr(FSzThread.FileIndex + 1) + ' из 2: ' +
      FileLine;
    if TotalBytes <= 0 then
      TotalBytes := 1;
    Filled := Int64(DoneBytes) * BarWidth div TotalBytes;
    if Filled > BarWidth then
      Filled := BarWidth;
    BarLine := '';
    for CellIndex := 1 to BarWidth do
      if CellIndex <= Filled then
        BarLine := BarLine + WideChar($2588)
      else
        BarLine := BarLine + WideChar($2591);
    BytesLine := WideString(FarGroupDigits(DoneBytes div 1024)) + ' / ' +
      WideString(FarGroupDigits(TotalBytes div 1024)) + ' КБ';
  end;
  DlgOpen(fdSzProgress, 'Загрузка 7-Zip ' + WideString(FSzPackage.Version) +
    ' (' + WideString(FSzPackage.Arch) + ')', [FileLine, BarLine, BytesLine],
    True, False, False, '', ['Отмена']);
end;

procedure TFarView.SzTick(Sender: TObject);
var
  ErrorText: string;
  WasCancelled: Boolean;
begin
  if FSzThread = nil then
  begin
    FSzTimer.Enabled := False;
    Exit;
  end;
  if not FSzThread.Finished then
  begin
    if FDlgKind = fdSzProgress then
      SzProgress;
    Exit;
  end;
  FSzTimer.Enabled := False;
  FSzThread.WaitFor;
  ErrorText := FSzThread.ErrorText;
  WasCancelled := FSzThread.Cancelled;
  FSzThread.Free;
  FSzThread := nil;
  if FDlgKind = fdSzProgress then
    DlgClose;
  if WasCancelled or (ErrorText <> '') or (SzLocalExe = '') then
  begin
    FArcAction := aaNone;
    if WasCancelled then
      Status(FarProduct + ': установка 7-Zip отменена')
    else if ErrorText <> '' then
      SzFail('7-Zip не установить: ' + WideString(ErrorText))
    else
      SzFail('7-Zip не установить: 7z.exe после установки не найден.');
    Exit;
  end;
  Status(FarProduct + ': 7-Zip ' + FSzPackage.Version + ' (' + FSzPackage.Arch +
    ') установлен в ' + string(FSzTarget));
  // Работа с архивом, ради которой 7-Zip качали
  if FArcAction <> aaNone then
    ArcRun;
end;

// Отмена (окно хода закрыто): поток прервёт загрузку или 7zr.exe; конец -
// в SzTick
procedure TFarView.SzCancel;
begin
  if FSzThread <> nil then
    FSzThread.Cancel;
end;

// Не вышло: причина и как поставить 7-Zip руками
procedure TFarView.SzFail(const AText: WideString);
var
  Lines, Wrapped: TFarNames;
  LineIndex, Count: Integer;
begin
  Wrapped := FarWrapText(AText, 62);
  Count := Length(Wrapped);
  SetLength(Lines, Count + 4);
  for LineIndex := 0 to Count - 1 do
    Lines[LineIndex] := Wrapped[LineIndex];
  Lines[Count] := '';
  Lines[Count + 1] := 'Вручную: взять 7z.exe и 7z.dll из 7-Zip с www.7-zip.org';
  Lines[Count + 2] := '(той же разрядности) и положить в';
  Lines[Count + 3] := FarFitPath(SzAppDir, 62);
  DlgOpen(fdSzFail, '7-Zip', Lines, False, True, False, '',
    ['OK', 'Сайт 7-Zip']);
end;

// 7z.exe закончил: по FArcAction - список в панель, перенос распакованного
// на место или открытие файла; нужен пароль - спросить и повторить
procedure TFarView.ArcDone(AExitCode: DWORD);
var
  Output, SourceDir, FromList, OpenPath: WideString;
  NeedPassword, Aborted: Boolean;
  NameIndex: Integer;
  Action: TFarArcAction;
  DestPanel: Integer;
begin
  Output := UTF8Decode(FProcRaw);
  FProcRaw := '';
  Action := FArcAction;
  NeedPassword := (FarPosText('Enter password', Output) > 0) or
    (FarPosText('Wrong password', Output) > 0) or
    (FarPosText('Can not open encrypted archive', Output) > 0) or
    (FarPosText('Cannot open encrypted archive', Output) > 0);
  if NeedPassword then
  begin
    // Временную папку - очистить, путь - оставить для повтора
    if Action <> aaList then
    begin
      SourceDir := FArcJobTemp;
      ArcCleanupTemp;
      FArcJobTemp := SourceDir;
    end;
    // FArcAction остаётся: повтор - из окна пароля (DlgActivate)
    DlgOpen(fdPassword, 'Password', ['Password for', FarFitName(
      ExtractFileName(string(FArcJobFile)), 60)], True, False, True, '',
      ['OK', 'Cancel']);
    FDlgMasked := True;
    Status(FarProduct + ': архив защищён паролем');
    Exit;
  end;
  FArcAction := aaNone;
  case Action of
    aaList:
      ArcApplyList(Output);
    aaExtract, aaOpenFile:
      begin
        // 0 - всё хорошо, 1 - предупреждения, дальше - ошибки
        if AExitCode >= 2 then
        begin
          ArcError(Output);
          ArcCleanupTemp;
          Exit;
        end;
        if AExitCode = 1 then
          ArcError(Output);
        SourceDir := FArcJobTemp;
        if FArcJobPrefix <> '' then
          SourceDir := SourceDir + FArcJobPrefix + '\';
        if Action = aaOpenFile then
        begin
          // Файл - во временной папке unIDE_far, она остаётся до выхода
          OpenPath := SourceDir + FArcJobNames[0];
          if FPanels[FArcJobPanel].DisplayPath = FArcJobStart then
            FPanels[FArcJobPanel].FArcPassword := FArcJobPassword;
          if IsArchiveName(FArcJobNames[0]) or FArcJobForce then
            OpenArchive(FArcJobPanel, OpenPath,
              FPanels[FArcJobPanel].DisplayPath + '\' + FArcJobNames[0], True,
              '')
          else
            ShellOpen(OpenPath, SourceDir);
          FArcJobTemp := '';
          Exit;
        end;
        // Распаковка: верхние элементы - на место (замену спросит Windows)
        FromList := '';
        for NameIndex := 0 to High(FArcJobNames) do
          FromList := FromList + SourceDir + FArcJobNames[NameIndex] +
            WideChar(#0);
        FromList := FromList + WideChar(#0);
        RunShellOp(FarFoMove, FromList, FArcJobDest + WideChar(#0) +
          WideChar(#0), FarFofNoConfirmMkDir, Aborted);
        if FPanels[FArcJobPanel].DisplayPath = FArcJobStart then
          FPanels[FArcJobPanel].FArcPassword := FArcJobPassword;
        ArcCleanupTemp;
        // Папка, куда распаковали, - перечитать
        for DestPanel := 0 to 1 do
          if not FPanels[DestPanel].IsArchive and
             FarSameName(FPanels[DestPanel].Path, FArcJobDest) then
          begin
            FPanels[DestPanel].Reread;
            EnsureVisible(FPanels[DestPanel]);
          end;
        if not Aborted and (AExitCode = 0) then
          Status(FarProduct + ': распаковано: ' + IntToStr(Length(FArcJobNames)));
        Invalidate;
      end;
    aaAdd:
      ArcAddDone(AExitCode, Output);
  end;
end;

// Упаковка закончилась: ошибки - в строку состояния и вывод; панели с
// папкой архива - перечитать, в панели, откуда паковали, - снять выделение
// с упакованного и курсор на архив
procedure TFarView.ArcAddDone(AExitCode: DWORD; const AOutput: WideString);
var
  PanelIndex, NameIndex, ItemIndex: Integer;
  ArcDir, ArcName: WideString;
  Panel: TFarPanel;
  SizeText: string;
  FindHandle: THandle;
  FindData: TFarFindData;
begin
  ArcCleanupTemp;
  if AExitCode >= 2 then
  begin
    ArcError(AOutput);
    // 7-Zip не дописал новый архив - убрать то, что осталось
    if not FArcJobExists then
      FarDeleteFile(PWideChar(FArcJobFile));
    Invalidate;
    Exit;
  end;
  // 1 - предупреждения (файл занят, нет доступа): архив есть, но не полный
  if AExitCode = 1 then
    ArcError(AOutput);
  FarSplitPath(FArcJobFile, ArcDir, ArcName);
  for PanelIndex := 0 to 1 do
  begin
    Panel := FPanels[PanelIndex];
    if Panel.IsArchive then
      Continue;
    if (PanelIndex = FArcJobPanel) and FarSameName(Panel.Path, FArcJobDest) then
      for NameIndex := 0 to High(FArcJobNames) do
      begin
        ItemIndex := Panel.IndexOfName(FArcJobNames[NameIndex]);
        if ItemIndex >= 0 then
          Panel.SetSelected(ItemIndex, False);
      end;
    if FarSameName(Panel.Path, FarWithSlash(ArcDir)) then
    begin
      Panel.Reread;
      if PanelIndex = FArcJobPanel then
      begin
        ItemIndex := Panel.IndexOfName(ArcName);
        if ItemIndex >= 0 then
          Panel.Cursor := ItemIndex;
      end;
      EnsureVisible(Panel);
    end;
  end;
  if AExitCode = 0 then
  begin
    SizeText := '';
    FindHandle := FarFindFirst(PWideChar(FArcJobFile), FindData);
    if FindHandle <> INVALID_HANDLE_VALUE then
    begin
      SizeText := ', ' + FarGroupDigits(Int64(FindData.nFileSizeHigh) shl 32 +
        FindData.nFileSizeLow) + ' байт';
      Windows.FindClose(FindHandle);
    end;
    if FArcJobExists then
      Status(FarProduct + ': добавлено в архив ' + string(ArcName) + SizeText)
    else
      Status(FarProduct + ': архив создан: ' + string(ArcName) + SizeText);
  end;
  Invalidate;
end;

// Список архива готов: панель - в архив (вложенный - поверх текущего)
procedure TFarView.ArcApplyList(const AOutput: WideString);
var
  Entries: TFarArcEntries;
  Panel: TFarPanel;
  Level: Integer;
begin
  Panel := FPanels[FArcJobPanel];
  // Панель за это время ушла в другую папку - не трогаем
  if Panel.DisplayPath <> FArcJobStart then
  begin
    Status(FarProduct + ': панель уже в другой папке - архив не открыт');
    Exit;
  end;
  if not FarParseSlt(AOutput, Entries) then
  begin
    ArcError(AOutput);
    Exit;
  end;
  if FArcJobNested and Panel.IsArchive then
  begin
    Level := Length(Panel.FArcLevels);
    SetLength(Panel.FArcLevels, Level + 1);
    Panel.FArcLevels[Level].ArcFile := Panel.FArcFile;
    Panel.FArcLevels[Level].Title := Panel.FArcTitle;
    Panel.FArcLevels[Level].Dir := Panel.FArcDir;
    Panel.FArcLevels[Level].Password := Panel.FArcPassword;
    Panel.FArcLevels[Level].Entries := Panel.FArcEntries;
  end
  else
    Panel.FArcLevels := nil;
  Panel.FArcFile := FArcJobFile;
  Panel.FArcTitle := FArcJobTitle;
  Panel.FArcDir := '';
  Panel.FArcEntries := Entries;
  Panel.FArcPassword := FArcJobPassword;
  Panel.BuildArcView('');
  EnsureVisible(Panel);
  Status(FarProduct + ': ' + string(ExtractFileName(string(FArcJobFile))) +
    ' - записей: ' + IntToStr(Length(Entries)));
  Invalidate;
end;

// '..' в архиве: на папку выше; в корне вложенного - во внешний архив; в
// корне внешнего - выход из архива (курсор - на файл архива)
procedure TFarView.ArcUp(APanel: TFarPanel);
var
  ChildName, ArcName: WideString;
  SlashPos, Level: Integer;
begin
  if APanel.FArcDir <> '' then
  begin
    SlashPos := Length(APanel.FArcDir);
    while (SlashPos > 0) and (APanel.FArcDir[SlashPos] <> '\') do
      Dec(SlashPos);
    ChildName := Copy(APanel.FArcDir, SlashPos + 1, MaxInt);
    if SlashPos > 0 then
      APanel.FArcDir := Copy(APanel.FArcDir, 1, SlashPos - 1)
    else
      APanel.FArcDir := '';
    APanel.BuildArcView(ChildName);
    EnsureVisible(APanel);
    Invalidate;
    Exit;
  end;
  Level := High(APanel.FArcLevels);
  if Level >= 0 then
  begin
    // Имя вложенного архива - курсор на него во внешнем
    FarSplitPath(APanel.FArcFile, ChildName, ArcName);
    APanel.FArcFile := APanel.FArcLevels[Level].ArcFile;
    APanel.FArcTitle := APanel.FArcLevels[Level].Title;
    APanel.FArcDir := APanel.FArcLevels[Level].Dir;
    APanel.FArcPassword := APanel.FArcLevels[Level].Password;
    APanel.FArcEntries := APanel.FArcLevels[Level].Entries;
    SetLength(APanel.FArcLevels, Level);
    APanel.BuildArcView(ArcName);
    EnsureVisible(APanel);
    Invalidate;
    Exit;
  end;
  // Из архива - в его папку
  ArcName := APanel.FArcTitle;
  SlashPos := Length(ArcName);
  while (SlashPos > 0) and (ArcName[SlashPos] <> '\') do
    Dec(SlashPos);
  ArcName := Copy(ArcName, SlashPos + 1, MaxInt);
  ChangeDir(APanel, APanel.Path, ArcName);
end;

// Enter (Ctrl+PgDn - AForceArchive) в архиве: папка - войти, '..' - выше,
// файл - распаковать во временную папку и открыть (архив - вложенно)
procedure TFarView.ArcOpenItem(ASeparate, AForceArchive: Boolean);
var
  Panel: TFarPanel;
  Name: WideString;
  TempBuffer: array[0..MAX_PATH] of WideChar;
  TempLen: DWORD;
begin
  Panel := ActivePanel;
  if (Panel.Count = 0) or (Panel.Cursor < 0) or
     (Panel.Cursor >= Panel.Count) then
    Exit;
  if ASeparate then
  begin
    ArcBlocked;
    Exit;
  end;
  Name := Panel.FItems[Panel.Cursor].Name;
  if Panel.FItems[Panel.Cursor].IsUp then
  begin
    ArcUp(Panel);
    Exit;
  end;
  if Panel.FItems[Panel.Cursor].IsDir then
  begin
    Panel.FArcDir := Panel.ArcInnerPath(Name);
    Panel.BuildArcView('');
    EnsureVisible(Panel);
    Invalidate;
    Exit;
  end;
  if FProcHandle <> 0 then
  begin
    Status(FarProduct + ': выполняется команда - подождите');
    Exit;
  end;
  // Файл из архива - во временную папку %TEMP%\unIDE_far\<метка>\
  TempLen := FarGetTempPath(MAX_PATH + 1, TempBuffer);
  if (TempLen = 0) or (TempLen > MAX_PATH) then
  begin
    Status(FarProduct + ': нет временной папки Windows');
    Exit;
  end;
  FArcAction := aaOpenFile;
  FArcJobForce := AForceArchive;
  FArcJobPanel := FActive;
  FArcJobFile := Panel.FArcFile;
  FArcJobStart := Panel.DisplayPath;
  FArcJobPrefix := Panel.FArcDir;
  SetLength(FArcJobNames, 1);
  FArcJobNames[0] := Name;
  FArcJobPassword := Panel.FArcPassword;
  FArcJobTemp := FarWithSlash(PWideChar(@TempBuffer[0])) + FarArcTempDir +
    '\' + IntToHex(GetTickCount, 8) + '\';
  ArcRun;
end;

// F5 из панели архива: окно «Extract to» с папкой другой панели
procedure TFarView.StartArcExtract;
var
  Names: TFarNames;
  Subject: WideString;
begin
  if FPanels[1 - FActive].IsArchive or FPanels[1 - FActive].IsFtp then
  begin
    Status(FarProduct + ': из архива - только в обычную папку');
    Exit;
  end;
  Names := CollectNames(False);
  if Length(Names) = 0 then
    Exit;
  FDlgNames := Names;
  if Length(Names) = 1 then
    Subject := '"' + Names[0] + '"'
  else
    Subject := IntToStr(Length(Names)) + ' items';
  DlgOpen(fdArcExtract, 'Extract', ['Extract ' + Subject + ' to:'], False,
    False, True, FPanels[1 - FActive].Path, ['Extract', 'Cancel']);
end;

procedure TFarView.DoArcExtract(const ATarget: WideString);
var
  Panel: TFarPanel;
  Target: WideString;
begin
  Panel := ActivePanel;
  Target := FarTrimW(ATarget);
  if (Target = '') or (Length(FDlgNames) = 0) or not Panel.IsArchive then
    Exit;
  if FProcHandle <> 0 then
  begin
    Status(FarProduct + ': выполняется команда - подождите');
    Exit;
  end;
  Target := FarWithSlash(FarFullPath(FPanels[1 - FActive].Path, Target));
  if not FarForceDirs(Target) then
  begin
    Status(FarProduct + ': папку не создать: ' + SysErrorMessage(GetLastError));
    Exit;
  end;
  FArcAction := aaExtract;
  FArcJobPanel := FActive;
  FArcJobFile := Panel.FArcFile;
  FArcJobStart := Panel.DisplayPath;
  FArcJobPrefix := Panel.FArcDir;
  FArcJobNames := FDlgNames;
  FArcJobDest := Target;
  FArcJobPassword := Panel.FArcPassword;
  // Временная папка - в папке назначения: перенос оттуда - без копирования
  FArcJobTemp := Target + '~unIDE_7z_' + IntToHex(GetTickCount, 8) + '\';
  FDlgNames := nil;
  ArcRun;
end;

// ---------------------------------------------------------------------------
//  Окно с несколькими полями (Shift+F1): строки FDlgRows под текстом окна.
//  Фокус: FDlgRow >= 0 - строка, иначе - кнопка FDlgFocus
// ---------------------------------------------------------------------------

procedure TFarView.DlgAddRow(const ACaption: WideString; AIsChoice,
  AMasked: Boolean; const AText: WideString; const AValues: array of WideString;
  AIndex: Integer);
var
  RowIndex, ValueIndex: Integer;
begin
  RowIndex := Length(FDlgRows);
  SetLength(FDlgRows, RowIndex + 1);
  with FDlgRows[RowIndex] do
  begin
    Caption := ACaption;
    IsChoice := AIsChoice;
    Masked := AMasked;
    Text := AText;
    Pos := Length(AText);
    Scroll := 0;
    Fresh := AText <> '';
    SetLength(Values, Length(AValues));
    for ValueIndex := 0 to High(AValues) do
      Values[ValueIndex] := AValues[ValueIndex];
    Index := AIndex;
    if (Index < 0) or (Index > High(Values)) then
      Index := 0;
    IsCheck := False;
  end;
  // Фокус - на первой строке
  FDlgRow := 0;
  FDlgFocus := -1;
  Invalidate;
end;

function TFarView.DlgRowIsEdit: Boolean;
begin
  Result := (FDlgRow >= 0) and (FDlgRow < Length(FDlgRows)) and
    not FDlgRows[FDlgRow].IsChoice;
end;

// Колонка значения AValueIndex строки выбора: значения - ' значение ',
// между ними пробел
function TFarView.DlgChoiceCol(const ARow: TFarDlgRow;
  AValueIndex: Integer): Integer;
var
  ValueIndex: Integer;
begin
  Result := FDlgRowsLeft;
  for ValueIndex := 0 to AValueIndex - 1 do
    Inc(Result, Length(ARow.Values[ValueIndex]) + 3);
end;

procedure TFarView.DrawDialogRow(ARowIndex, ARow, AInnerLeft,
  AInnerW: Integer; AFore, ABack: TColor);
var
  FieldLeft, FieldW, ValueIndex, CharIndex, CaretX, ValueCol: Integer;
  ShownText, ValueText: WideString;
  Focused: Boolean;
begin
  FieldLeft := AInnerLeft + FarDlgCaptionW;
  FieldW := AInnerW - FarDlgCaptionW;
  Focused := ARowIndex = FDlgRow;
  with FDlgRows[ARowIndex] do
  begin
    // Флажок: [x] подпись (с фокусом - [x] белым по чёрному)
    if IsCheck then
    begin
      if Index = 1 then
        ValueText := '[x]'
      else
        ValueText := '[ ]';
      if Focused then
        PutText(AInnerLeft, ARow, 3, ValueText, FPal[fpDlgSelText],
          FPal[fpDlgSelBack])
      else
        PutText(AInnerLeft, ARow, 3, ValueText, AFore, ABack);
      PutText(AInnerLeft + 4, ARow, AInnerW - 4, Caption, AFore, ABack);
      Exit;
    end;
    PutText(AInnerLeft, ARow, FarDlgCaptionW, Caption, AFore, ABack);
    if IsChoice then
    begin
      for ValueIndex := 0 to High(Values) do
      begin
        ValueText := ' ' + Values[ValueIndex] + ' ';
        ValueCol := DlgChoiceCol(FDlgRows[ARowIndex], ValueIndex);
        if ValueCol + Length(ValueText) > FieldLeft + FieldW then
          Break;
        if ValueIndex <> Index then
          PutText(ValueCol, ARow, Length(ValueText), ValueText, AFore, ABack)
        else if Focused then
          PutText(ValueCol, ARow, Length(ValueText), ValueText,
            FPal[fpDlgSelText], FPal[fpDlgSelBack])
        else
          PutText(ValueCol, ARow, Length(ValueText), ValueText,
            FPal[fpDlgEditText], FPal[fpDlgEditBack]);
      end;
    end
    else
    begin
      if Pos < Scroll then
        Scroll := Pos;
      if Pos > Scroll + FieldW - 1 then
        Scroll := Pos - FieldW + 1;
      ShownText := Copy(Text, Scroll + 1, FieldW);
      if Masked then
        for CharIndex := 1 to Length(ShownText) do
          ShownText[CharIndex] := '*';
      FillCells(FieldLeft, ARow, FieldW, FPal[fpDlgEditBack]);
      if Fresh and Focused then
        PutText(FieldLeft, ARow, Length(ShownText), ShownText,
          FPal[fpDlgSelText], FPal[fpDlgSelBack])
      else
        PutText(FieldLeft, ARow, Length(ShownText), ShownText,
          FPal[fpDlgEditText], FPal[fpDlgEditBack]);
      if Focused then
      begin
        CaretX := (FieldLeft + Pos - Scroll) * FCellW;
        FBuffer.Canvas.Brush.Style := bsSolid;
        FBuffer.Canvas.Brush.Color := FPal[fpDlgEditText];
        FBuffer.Canvas.FillRect(Rect(CaretX, ARow * FCellH + 1, CaretX + 2,
          (ARow + 1) * FCellH - 1));
      end;
    end;
  end;
end;

procedure TFarView.DlgRowInsert(const AText: WideString);
begin
  if not DlgRowIsEdit then
    Exit;
  with FDlgRows[FDlgRow] do
  begin
    if Fresh then
    begin
      Text := '';
      Pos := 0;
      Fresh := False;
    end;
    Insert(AText, Text, Pos + 1);
    Inc(Pos, Length(AText));
  end;
  Invalidate;
end;

// Смена значения строки выбора (строка формата - ещё и расширение имени)
procedure FarDlgChoose(var ARow: TFarDlgRow; ANewIndex: Integer);
begin
  if ANewIndex < 0 then
    ANewIndex := 0;
  if ANewIndex > High(ARow.Values) then
    ANewIndex := High(ARow.Values);
  ARow.Index := ANewIndex;
end;

function TFarView.DlgRowsKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
var
  ButtonCount, RowCount, OldIndex: Integer;
  InEdit, InChoice: Boolean;
begin
  Result := True;
  ButtonCount := Length(FDlgButtons);
  RowCount := Length(FDlgRows);
  InEdit := DlgRowIsEdit;
  InChoice := (FDlgRow >= 0) and not InEdit;
  OldIndex := -1;
  if InChoice then
    OldIndex := FDlgRows[FDlgRow].Index;
  case AKey of
    VK_ESCAPE, VK_F10:
      DlgClose;
    VK_RETURN:
      if FDlgRow >= 0 then
        DlgActivate(0)
      else
        DlgActivate(FDlgFocus);
    VK_SPACE:
      if InChoice then
        // Пробел - следующее значение по кругу
        with FDlgRows[FDlgRow] do
          Index := (Index + 1) mod Length(Values)
      else if FDlgRow < 0 then
        DlgActivate(FDlgFocus)
      else
        Result := False;  // пробел - символ поля ввода (WM_CHAR)
    VK_TAB, VK_UP, VK_DOWN:
      if (AKey = VK_UP) or ((AKey = VK_TAB) and AShift) then
      begin
        if FDlgRow > 0 then
          Dec(FDlgRow)
        else if FDlgRow = 0 then
        begin
          FDlgRow := -1;
          FDlgFocus := ButtonCount - 1;
        end
        else if FDlgFocus > 0 then
          Dec(FDlgFocus)
        else
        begin
          FDlgRow := RowCount - 1;
          FDlgFocus := -1;
        end;
      end
      else
      begin
        if (FDlgRow >= 0) and (FDlgRow < RowCount - 1) then
          Inc(FDlgRow)
        else if FDlgRow >= 0 then
        begin
          FDlgRow := -1;
          FDlgFocus := 0;
        end
        else if FDlgFocus < ButtonCount - 1 then
          Inc(FDlgFocus)
        else
        begin
          FDlgRow := 0;
          FDlgFocus := -1;
        end;
      end;
    VK_LEFT, VK_RIGHT:
      if InEdit then
        with FDlgRows[FDlgRow] do
        begin
          Fresh := False;
          if (AKey = VK_LEFT) and (Pos > 0) then
            Dec(Pos)
          else if (AKey = VK_RIGHT) and (Pos < Length(Text)) then
            Inc(Pos);
        end
      else if InChoice then
      begin
        if AKey = VK_LEFT then
          FarDlgChoose(FDlgRows[FDlgRow], FDlgRows[FDlgRow].Index - 1)
        else
          FarDlgChoose(FDlgRows[FDlgRow], FDlgRows[FDlgRow].Index + 1);
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
        with FDlgRows[FDlgRow] do
        begin
          Fresh := False;
          if AKey = VK_HOME then
            Pos := 0
          else
            Pos := Length(Text);
        end
      else if InChoice then
      begin
        if AKey = VK_HOME then
          FarDlgChoose(FDlgRows[FDlgRow], 0)
        else
          FarDlgChoose(FDlgRows[FDlgRow], MaxInt);
      end;
    VK_BACK:
      if InEdit then
        with FDlgRows[FDlgRow] do
          if Fresh then
          begin
            Text := '';
            Pos := 0;
            Fresh := False;
          end
          else if Pos > 0 then
          begin
            Delete(Text, Pos, 1);
            Dec(Pos);
          end;
    VK_DELETE:
      if InEdit then
        with FDlgRows[FDlgRow] do
          if Fresh then
          begin
            Text := '';
            Pos := 0;
            Fresh := False;
          end
          else if Pos < Length(Text) then
            Delete(Text, Pos + 1, 1);
    VK_INSERT:
      if InEdit and AShift and FarClipboardHasText then
        DlgRowInsert(FarClipboardText);
  else
    if InEdit and ACtrl and not AAlt and (AKey = Ord('V')) then
    begin
      if FarClipboardHasText then
        DlgRowInsert(FarClipboardText);
    end
    else if InEdit and ACtrl and not AAlt and (AKey = Ord('Y')) then
      with FDlgRows[FDlgRow] do
      begin
        Text := '';
        Pos := 0;
        Fresh := False;
      end
    else if ACtrl or AAlt then
      Result := True   // сочетания в окне никуда не отдаём (ярлыки меню)
    else
      Result := False; // буквы, цифры - символы поля ввода (WM_CHAR)
  end;
  // Сменился формат архива - расширение в имени
  if InChoice and (FDlgKind = fdArcAdd) and (FDlgRow = 1) and
     (FDlgRows[FDlgRow].Index <> OldIndex) then
    ArcAddFormatChanged(OldIndex);
  Invalidate;
end;

// Щелчок по строке полей: фокус на неё; по значению выбора - выбрать его,
// по полю ввода - каретку туда
procedure TFarView.DlgRowsMouse(AX, AY: Integer);
var
  RowIndex, ValueIndex, ClickCol, OldIndex, ValueCol: Integer;
begin
  RowIndex := AY div FCellH - FDlgRowsTop;
  if (RowIndex < 0) or (RowIndex > High(FDlgRows)) then
    Exit;
  FDlgRow := RowIndex;
  FDlgFocus := -1;
  ClickCol := AX div FCellW;
  with FDlgRows[RowIndex] do
    if IsCheck then
      Index := 1 - Index
    else if IsChoice then
    begin
      OldIndex := Index;
      for ValueIndex := 0 to High(Values) do
      begin
        ValueCol := DlgChoiceCol(FDlgRows[RowIndex], ValueIndex);
        if (ClickCol >= ValueCol) and
           (ClickCol < ValueCol + Length(Values[ValueIndex]) + 2) then
          Index := ValueIndex;
      end;
      if (FDlgKind = fdArcAdd) and (RowIndex = 1) and (Index <> OldIndex) then
        ArcAddFormatChanged(OldIndex);
    end
    else if ClickCol >= FDlgRowsLeft then
    begin
      Fresh := False;
      Pos := Scroll + ClickCol - FDlgRowsLeft;
      if Pos > Length(Text) then
        Pos := Length(Text);
    end;
  Invalidate;
end;

// ---------------------------------------------------------------------------
//  Shift+F1: упаковка выделенного (или файла под курсором) в ZIP / 7z
//  (7z.exe a). Архив - в папку панели, если в имени нет своего пути
// ---------------------------------------------------------------------------

procedure TFarView.StartArcAdd;
var
  Panel: TFarPanel;
  Names: TFarNames;
  BaseName, Subject, ParentDir: WideString;
  ItemIndex: Integer;
begin
  if ArcBlocked then
    Exit;
  Panel := ActivePanel;
  if Panel.Path = '' then
    Exit;
  Names := CollectNames(False);
  if Length(Names) = 0 then
    Exit;
  FDlgNames := Names;
  // Имя архива: один элемент - его имя (у файла - без расширения), иначе -
  // имя папки панели
  BaseName := '';
  if Length(Names) = 1 then
  begin
    BaseName := Names[0];
    ItemIndex := Panel.IndexOfName(Names[0]);
    if (ItemIndex >= 0) and not Panel.FItems[ItemIndex].IsDir and
       (FarNameExt(BaseName) <> '') then
      SetLength(BaseName, Length(BaseName) - Length(FarNameExt(BaseName)) - 1);
  end;
  if BaseName = '' then
  begin
    ParentDir := FarParentOf(Panel.Path, BaseName);
    if ParentDir = '' then
      BaseName := '';   // корень диска
  end;
  if BaseName = '' then
    BaseName := 'archive';
  if (FArcAddFormat < 0) or (FArcAddFormat > High(FarArcAddExts)) then
    FArcAddFormat := 0;
  if (FArcAddLevel < 0) or (FArcAddLevel > High(FarArcAddLevels)) then
    FArcAddLevel := 3;
  if Length(Names) = 1 then
    Subject := '"' + FarFitName(Names[0], 40) + '"'
  else
    Subject := IntToStr(Length(Names)) + ' items';
  DlgOpen(fdArcAdd, 'Add to archive', ['Add ' + Subject + ' to archive:'],
    False, False, False, '', ['Add', 'Cancel']);
  DlgAddRow('Archive:', False, False,
    BaseName + WideString(FarArcAddExts[FArcAddFormat]), [], 0);
  DlgAddRow('Format:', True, False, '', ['ZIP', '7z'], FArcAddFormat);
  DlgAddRow('Level:', True, False, '', ['Store', 'Fastest', 'Fast', 'Normal',
    'Maximum', 'Ultra'], FArcAddLevel);
  DlgAddRow('Password:', False, True, '', [], 0);
  DlgAddRow('Confirm:', False, True, '', [], 0);
  FDlgRow := 0;
end;

// Формат сменился: имя кончается на прежнее расширение - заменить
procedure TFarView.ArcAddFormatChanged(AOldFormat: Integer);
var
  OldExt, NewExt: WideString;
  NewFormat: Integer;
begin
  if (Length(FDlgRows) < 2) or (AOldFormat < 0) or
     (AOldFormat > High(FarArcAddExts)) then
    Exit;
  NewFormat := FDlgRows[1].Index;
  OldExt := FarArcAddExts[AOldFormat];
  NewExt := FarArcAddExts[NewFormat];
  with FDlgRows[0] do
    if (Length(Text) > Length(OldExt)) and FarSameName(Copy(Text,
       Length(Text) - Length(OldExt) + 1, MaxInt), OldExt) then
    begin
      Text := Copy(Text, 1, Length(Text) - Length(OldExt)) + NewExt;
      Pos := Length(Text);
      Fresh := False;
    end;
end;

// [ Add ]: проверить поля, закрыть окно, запустить 7z.exe a
procedure TFarView.ArcAddConfirm;
var
  Panel: TFarPanel;
  Name, Password, Confirm, Target, TempDir: WideString;
  FormatIndex, LevelIndex, CharIndex: Integer;
  TempBuffer: array[0..MAX_PATH] of WideChar;
  TempLen: DWORD;
  Attr: DWORD;

  procedure FocusRow(ARow: Integer; const AMessage: string);
  begin
    FDlgRow := ARow;
    FDlgFocus := -1;
    Status(FarProduct + ': ' + AMessage);
    Invalidate;
  end;

begin
  Name := FarTrimW(FDlgRows[0].Text);
  FormatIndex := FDlgRows[1].Index;
  LevelIndex := FDlgRows[2].Index;
  Password := FDlgRows[3].Text;
  Confirm := FDlgRows[4].Text;
  if Name = '' then
  begin
    FocusRow(0, 'нет имени архива');
    Exit;
  end;
  if Password <> Confirm then
  begin
    FocusRow(4, 'пароль и повтор не совпадают');
    Exit;
  end;
  for CharIndex := 1 to Length(Password) do
  begin
    // В командной строке 7-Zip кавычку в пароль не передать
    if Password[CharIndex] = '"' then
    begin
      FocusRow(3, 'кавычка " в пароле не допускается');
      Exit;
    end;
    // ZIP (AES-256): 7-Zip берёт пароль только из символов ASCII
    if (FormatIndex = 0) and (Ord(Password[CharIndex]) > 126) then
    begin
      FocusRow(3, 'пароль ZIP - только латиница, цифры и знаки ASCII ' +
        '(с кириллицей - формат 7z)');
      Exit;
    end;
  end;
  Panel := ActivePanel;
  Target := FarFullPath(Panel.Path, Name);
  if FarNameExt(Target) = '' then
    Target := Target + WideString(FarArcAddExts[FormatIndex]);
  Attr := FarGetAttributes(PWideChar(Target));
  if (Attr <> FarInvalidAttr) and (Attr and FILE_ATTRIBUTE_DIRECTORY <> 0) then
  begin
    FocusRow(0, 'это имя папки');
    Exit;
  end;
  if FProcHandle <> 0 then
  begin
    FocusRow(0, 'выполняется команда - подождите');
    Exit;
  end;
  TempLen := FarGetTempPath(MAX_PATH + 1, TempBuffer);
  if (TempLen = 0) or (TempLen > MAX_PATH) then
  begin
    FocusRow(0, 'нет временной папки Windows');
    Exit;
  end;
  TempDir := FarWithSlash(PWideChar(@TempBuffer[0])) + FarArcTempDir +
    '\add_' + IntToHex(GetTickCount, 8) + '\';
  // Всё верно: выбор формата и уровня - на следующий раз
  FArcAddFormat := FormatIndex;
  FArcAddLevel := LevelIndex;
  DlgClose;
  FArcAction := aaAdd;
  FArcJobPanel := FActive;
  FArcJobFile := Target;
  FArcJobTitle := '';
  FArcJobStart := Panel.Path;
  FArcJobPrefix := '';
  FArcJobNames := FDlgNames;
  FArcJobDest := Panel.Path;
  FArcJobPassword := Password;
  FArcJobFormat := FormatIndex;
  FArcJobLevel := FarArcAddLevels[LevelIndex];
  FArcJobExists := Attr <> FarInvalidAttr;
  FArcJobTemp := TempDir;
  FArcAddPercent := -1;
  FDlgNames := nil;
  ArcRun;
end;

// Ход распаковки / упаковки - из вывода 7z.exe -bsp1 ('  42% 3 - имя'):
// последний процент и имя файла - в окно хода и в строку состояния
procedure TFarView.ArcAddProgress;
var
  Percent: Integer;
  FileName: string;
  Verb: string;
begin
  if not FarParse7zProgress(FProcRaw, Percent, FileName) then
    Exit;
  if (FileName <> '') and (FArcProgress <> nil) then
    FArcProgress.SetLine2(UTF8Decode(FileName));
  if Percent = FArcAddPercent then
    Exit;
  FArcAddPercent := Percent;
  if FArcProgress <> nil then
    FArcProgress.SetPercent(Percent);
  if FArcAction = aaAdd then
    Verb := 'упаковка'
  else
    Verb := 'распаковка';
  Status(FarProduct + ': ' + Verb + ' ' + IntToStr(Percent) + '% (Ctrl+Break - ' +
    'прервать)');
end;

// ---------------------------------------------------------------------------
//  Раскраска файлов и меню Options (F9)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
//  Alt+F7: поиск файлов (FarFind - обход в своём потоке). Окно Find file
//  (маски, текст, кодировка, флажки, где искать), затем окно найденного
//  поверх панелей: папка - строкой, под ней файлы (дата, размер, имя).
//  Enter / Go to - панель на найденный файл; F4 - файл в редактор (FAR -
//  одной панелью, редактор рядом), окно найденного остаётся; Esc - стоп,
//  потом закрыть; New search / Alt+F7 - снова окно Find file
// ---------------------------------------------------------------------------

procedure TFarView.DlgAddCheck(const ACaption: WideString; AChecked: Boolean);
var
  RowIndex: Integer;
begin
  // Флажок - выбор из двух значений (0 - снят, 1 - стоит), рисуется [x]
  if AChecked then
    DlgAddRow(ACaption, True, False, '', ['off', 'on'], 1)
  else
    DlgAddRow(ACaption, True, False, '', ['off', 'on'], 0);
  RowIndex := High(FDlgRows);
  FDlgRows[RowIndex].IsCheck := True;
end;

procedure TFarView.StartFind;
var
  Panel: TFarPanel;
begin
  Panel := ActivePanel;
  if Panel.IsArchive then
  begin
    Status(FarProduct + ': поиск в архиве пока не делается - выйдите из архива');
    Exit;
  end;
  if Panel.Path = '' then
    Exit;
  if FFindMask = '' then
    FFindMask := '*.*';
  DlgOpen(fdFind, 'Find file', ['Search in ' + FarFitPath(Panel.Path, 50)],
    False, False, False, '', ['Find', 'Cancel']);
  DlgAddRow('Masks:', False, False, FFindMask, [], 0);
  DlgAddRow('Text:', False, False, FFindText, [], 0);
  DlgAddRow('Code page:', True, False, '', ['All', 'ANSI', 'OEM', 'UTF-8',
    'UTF-16'], FFindCodePage);
  DlgAddCheck('Case sensitive', FFindCase);
  DlgAddCheck('Whole words', FFindWhole);
  DlgAddCheck('Search for folders', FFindFolders);
  DlgAddRow('Area:', True, False, '', ['With subfolders', 'This folder',
    'Whole drive'], FFindArea);
  FDlgRow := 0;
end;

// [ Find ]: поля - в память (и в editor.ini при закрытии FAR), окно -
// закрыть, начать поиск
procedure TFarView.FindConfirm;
var
  Options: TFarFindOptions;
  Panel: TFarPanel;
begin
  if Length(FDlgRows) < 7 then
    Exit;
  FFindMask := FarTrimW(FDlgRows[0].Text);
  if FFindMask = '' then
    FFindMask := '*.*';
  FFindText := FDlgRows[1].Text;
  FFindCodePage := FDlgRows[2].Index;
  FFindCase := FDlgRows[3].Index = 1;
  FFindWhole := FDlgRows[4].Index = 1;
  FFindFolders := FDlgRows[5].Index = 1;
  FFindArea := FDlgRows[6].Index;
  DlgClose;
  Panel := ActivePanel;
  Options.Root := Panel.Path;
  if FFindArea = 2 then
    Options.Root := FarRootOf(Panel.Path);
  Options.Masks := FFindMask;
  Options.Text := FFindText;
  Options.CodePage := TFarFindCodePage(FFindCodePage);
  Options.CaseSensitive := FFindCase;
  Options.WholeWords := FFindWhole;
  Options.Folders := FFindFolders;
  Options.Recursive := FFindArea <> 1;
  FindBegin(Options);
end;

procedure TFarView.FindBegin(const AOptions: TFarFindOptions);
begin
  FindStopThread;
  FFindOptions := AOptions;
  SetLength(FFindItems, 0);
  SetLength(FFindRows, 0);
  FFindCursor := -1;
  FFindTop := 0;
  FFindFocus := -1;
  FFindDone := False;
  FFindOpen := True;
  FFindThread := TFarFindThread.Create(AOptions);
  if FFindTimer = nil then
  begin
    FFindTimer := TTimer.Create(Self);
    FFindTimer.Interval := 150;
    FFindTimer.OnTimer := FindTick;
  end;
  FFindTimer.Enabled := True;
  Invalidate;
end;

// Остановить поток и освободить (ждёт его конца)
procedure TFarView.FindStopThread;
begin
  if FFindTimer <> nil then
    FFindTimer.Enabled := False;
  if FFindThread <> nil then
  begin
    FFindThread.Cancel;
    FFindThread.WaitFor;
    FindTakeFound;
    FFindThread.Free;
    FFindThread := nil;
  end;
  FFindDone := True;
end;

procedure TFarView.FindQuit;
begin
  FindStopThread;
  FFindOpen := False;
  SetLength(FFindItems, 0);
  SetLength(FFindRows, 0);
  Invalidate;
end;

// Найденное потоком - в список: новая папка - строкой-заголовком
procedure TFarView.FindTakeFound;
var
  OldCount, ItemIdx, RowCount: Integer;
  LastDir: WideString;
begin
  if FFindThread = nil then
    Exit;
  OldCount := Length(FFindItems);
  if FFindThread.TakeFound(FFindItems) = 0 then
    Exit;
  LastDir := '';
  if OldCount > 0 then
    LastDir := FFindItems[OldCount - 1].Dir;
  RowCount := Length(FFindRows);
  SetLength(FFindRows, RowCount + 2 * (Length(FFindItems) - OldCount));
  for ItemIdx := OldCount to High(FFindItems) do
  begin
    if FFindItems[ItemIdx].Dir <> LastDir then
    begin
      LastDir := FFindItems[ItemIdx].Dir;
      FFindRows[RowCount].IsHeader := True;
      FFindRows[RowCount].Item := ItemIdx;
      Inc(RowCount);
    end;
    FFindRows[RowCount].IsHeader := False;
    FFindRows[RowCount].Item := ItemIdx;
    Inc(RowCount);
  end;
  SetLength(FFindRows, RowCount);
  // Первый найденный - под курсор
  if FFindCursor < 0 then
    FindMove(1);
end;

procedure TFarView.FindTick(Sender: TObject);
begin
  if FFindThread = nil then
  begin
    FFindTimer.Enabled := False;
    Exit;
  end;
  FindTakeFound;
  if FFindThread.Finished then
  begin
    FindTakeFound;
    FFindTimer.Enabled := False;
    FFindDone := True;
  end;
  Invalidate;
end;

// Строк списка в окне
function TFarView.FindListRows: Integer;
begin
  Result := PanelHeight - 6;
  if Result < 1 then
    Result := 1;
end;

// Курсор на ADelta строк (заголовки папок пропускаются)
procedure TFarView.FindMove(ADelta: Integer);
var
  Target, Step: Integer;
begin
  if Length(FFindRows) = 0 then
    Exit;
  Target := FFindCursor + ADelta;
  if Target < 0 then
    Target := 0;
  if Target > High(FFindRows) then
    Target := High(FFindRows);
  if ADelta >= 0 then
    Step := 1
  else
    Step := -1;
  while (Target >= 0) and (Target <= High(FFindRows)) and
        FFindRows[Target].IsHeader do
    Inc(Target, Step);
  // У края - в другую сторону
  if (Target < 0) or (Target > High(FFindRows)) then
  begin
    Target := FFindCursor;
    if (Target < 0) or (Target > High(FFindRows)) or
       FFindRows[Target].IsHeader then
    begin
      Target := 0;
      while (Target <= High(FFindRows)) and FFindRows[Target].IsHeader do
        Inc(Target);
      if Target > High(FFindRows) then
        Exit;
    end;
  end;
  FFindCursor := Target;
  // Видимость; заголовок папки над первым файлом - тоже
  if FFindCursor < FFindTop then
    FFindTop := FFindCursor;
  if (FFindTop > 0) and (FFindCursor = FFindTop) and
     FFindRows[FFindTop - 1].IsHeader then
    Dec(FFindTop);
  if FFindCursor >= FFindTop + FindListRows then
    FFindTop := FFindCursor - FindListRows + 1;
end;

// Файл под курсором; нет - False
function TFarView.FindCurrent(var AItem: TFarFindItem): Boolean;
begin
  Result := (FFindCursor >= 0) and (FFindCursor <= High(FFindRows)) and
    not FFindRows[FFindCursor].IsHeader;
  if Result then
    AItem := FFindItems[FFindRows[FFindCursor].Item];
end;

// Go to: панель - в папку найденного, курсор на него; окно закрывается
procedure TFarView.FindGoTo;
var
  Item: TFarFindItem;
begin
  if not FindCurrent(Item) then
    Exit;
  FindQuit;
  ChangeDir(ActivePanel, Item.Dir, Item.Name);
end;

// F4: файл в редактор (как F4 в панели), окно найденного остаётся
procedure TFarView.FindEdit;
var
  Item: TFarFindItem;
begin
  if not FindCurrent(Item) then
    Exit;
  if Item.IsDir then
  begin
    Status(FarProduct + ': это папка - Enter перейдёт в неё');
    Exit;
  end;
  OpenEditor(Item.Dir + Item.Name);
end;

// Кнопки окна найденного: New search, Go to, Edit, Stop / Cancel
procedure TFarView.FindButton(AIndex: Integer);
begin
  case AIndex of
    0: StartFind;
    1: FindGoTo;
    2: FindEdit;
    3: if not FFindDone then
         FindStopThread
       else
         FindQuit;
  end;
  Invalidate;
end;

function TFarView.FindKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
begin
  Result := True;
  if AAlt and (AKey = VK_F7) then
  begin
    StartFind;
    Exit;
  end;
  case AKey of
    VK_ESCAPE, VK_F10:
      if not FFindDone then
        FindStopThread
      else
        FindQuit;
    VK_CANCEL:                      // Ctrl+Break - остановить
      FindStopThread;
    VK_UP:
      FindMove(-1);
    VK_DOWN:
      FindMove(1);
    VK_PRIOR:
      FindMove(-(FindListRows - 1));
    VK_NEXT:
      FindMove(FindListRows - 1);
    VK_HOME:
      begin
        FFindCursor := -1;
        FFindTop := 0;
        FindMove(1);
      end;
    VK_END:
      FindMove(Length(FFindRows));
    VK_TAB, VK_LEFT, VK_RIGHT:
      begin
        // Фокус: список -> кнопки по кругу
        if (AKey = VK_LEFT) or ((AKey = VK_TAB) and AShift) then
          Dec(FFindFocus)
        else
          Inc(FFindFocus);
        if FFindFocus > 3 then
          FFindFocus := -1;
        if FFindFocus < -1 then
          FFindFocus := 3;
      end;
    VK_RETURN:
      if FFindFocus < 0 then
        FindGoTo
      else
        FindButton(FFindFocus);
    VK_F4:
      FindEdit;
  else
    // Остальное не отдаём панелям и меню IDE
    Result := True;
  end;
  Invalidate;
end;

// Строка списка ARowIdx в клетках AWidth: заголовок - путь папки, файл -
// дата, размер (папка - <Folder>), имя
function TFarView.FindRowText(ARowIdx, AWidth: Integer): WideString;
var
  Item: TFarFindItem;
  SizeText: string;
  NameW: Integer;
begin
  Item := FFindItems[FFindRows[ARowIdx].Item];
  if FFindRows[ARowIdx].IsHeader then
  begin
    Result := FarFitPath(Item.Dir, AWidth);
    Exit;
  end;
  if Item.IsDir then
    SizeText := '<Folder>'
  else
    SizeText := FarGroupDigits(Item.Size);
  while Length(SizeText) < 14 do
    SizeText := ' ' + SizeText;
  NameW := AWidth - 2 - 14 - 1 - 14 - 2;
  Result := '  ' + WideString(FarFileDate(Item.Time)) + ' ' +
    WideString(SizeText) + '  ' + FarFitName(Item.Name, NameW);
end;

procedure TFarView.DrawFind;
const
  ButtonTexts: array[0..2] of string = ('New search', 'Go to', 'Edit');
var
  BoxW, BoxH, InnerLeft, InnerW, ListRows, Row, RowIdx, SepY: Integer;
  ButtonIdx, ButtonsW, ButtonCol: Integer;
  Title, StatusText, ButtonText, LastText: WideString;
  Fore, Back: TColor;
begin
  BoxW := FCols;
  BoxH := PanelHeight;
  if (BoxW < 30) or (BoxH < 10) then
    Exit;
  Fore := FPal[fpDlgText];
  Back := FPal[fpDlgBack];
  for Row := 0 to BoxH - 1 do
    FillCells(0, Row, BoxW, Back);
  DrawBox(1, 0, BoxW - 2, BoxH - 1, Fore);
  Title := ' Find file: ' + FFindOptions.Masks;
  if FFindOptions.Text <> '' then
    Title := Title + ' containing "' + FFindOptions.Text + '"';
  Title := FarFitName(Title, BoxW - 8) + ' ';
  PutCentered(0, 0, BoxW, Title, Fore, Back);
  InnerLeft := 3;
  InnerW := BoxW - 6;
  ListRows := FindListRows;
  FFindListTop := 1;
  // Список
  for Row := 0 to ListRows - 1 do
  begin
    RowIdx := FFindTop + Row;
    if RowIdx > High(FFindRows) then
      Break;
    if RowIdx = FFindCursor then
    begin
      if FFindFocus < 0 then
      begin
        FillCells(InnerLeft - 1, 1 + Row, InnerW + 2, FPal[fpDlgSelBack]);
        PutText(InnerLeft, 1 + Row, InnerW, FindRowText(RowIdx, InnerW),
          FPal[fpDlgSelText], FPal[fpDlgSelBack]);
      end
      else
      begin
        FillCells(InnerLeft - 1, 1 + Row, InnerW + 2, FPal[fpDlgFocusBack]);
        PutText(InnerLeft, 1 + Row, InnerW, FindRowText(RowIdx, InnerW),
          FPal[fpDlgFocusText], FPal[fpDlgFocusBack]);
      end;
    end
    else
      PutText(InnerLeft, 1 + Row, InnerW, FindRowText(RowIdx, InnerW), Fore,
        Back);
  end;
  // Разделитель, строка хода, разделитель, кнопки
  Row := BoxH - 5;
  SepY := Row * FCellH + FCellH div 2;
  with FBuffer.Canvas do
  begin
    Pen.Color := Fore;
    MoveTo(1 * FCellW + FCellW div 2 + 1, SepY);
    LineTo((BoxW - 2) * FCellW + FCellW div 2, SepY);
  end;
  if FFindDone then
    StatusText := 'Search done. Found files: ' + IntToStr(FileCountOf) +
      ', folders: ' + IntToStr(DirCountOf)
  else if FFindThread <> nil then
    StatusText := 'Found files: ' + IntToStr(FileCountOf) + ', folders: ' +
      IntToStr(DirCountOf) + '. Searching in: ' + FFindThread.CurrentDir
  else
    StatusText := '';
  PutText(InnerLeft, BoxH - 4, InnerW, FarFitPath(StatusText, InnerW), Fore,
    Back);
  Row := BoxH - 3;
  SepY := Row * FCellH + FCellH div 2;
  with FBuffer.Canvas do
  begin
    MoveTo(1 * FCellW + FCellW div 2 + 1, SepY);
    LineTo((BoxW - 2) * FCellW + FCellW div 2, SepY);
  end;
  if FFindDone then
    LastText := 'Cancel'
  else
    LastText := 'Stop';
  ButtonsW := 0;
  for ButtonIdx := 0 to 2 do
    Inc(ButtonsW, Length(ButtonTexts[ButtonIdx]) + 5);
  Inc(ButtonsW, Length(LastText) + 4);
  ButtonCol := (BoxW - ButtonsW) div 2;
  FFindButtonRow := BoxH - 2;
  for ButtonIdx := 0 to 3 do
  begin
    if ButtonIdx < 3 then
      ButtonText := '[ ' + ButtonTexts[ButtonIdx] + ' ]'
    else
      ButtonText := '[ ' + LastText + ' ]';
    FFindButtonCol[ButtonIdx] := ButtonCol;
    FFindButtonLen[ButtonIdx] := Length(ButtonText);
    if ButtonIdx = FFindFocus then
      PutText(ButtonCol, BoxH - 2, Length(ButtonText), ButtonText,
        FPal[fpDlgFocusText], FPal[fpDlgFocusBack])
    else
      PutText(ButtonCol, BoxH - 2, Length(ButtonText), ButtonText, Fore, Back);
    Inc(ButtonCol, Length(ButtonText) + 1);
  end;
end;

function TFarView.FileCountOf: Integer;
var
  ItemIdx: Integer;
begin
  Result := 0;
  for ItemIdx := 0 to High(FFindItems) do
    if not FFindItems[ItemIdx].IsDir then
      Inc(Result);
end;

function TFarView.DirCountOf: Integer;
begin
  Result := Length(FFindItems) - FileCountOf;
end;

// Мышь в окне найденного: строка - курсор, кнопка - нажать
procedure TFarView.FindMouse(AX, AY: Integer);
var
  Row, Col, RowIdx, ButtonIdx: Integer;
begin
  Row := AY div FCellH;
  Col := AX div FCellW;
  if Row = FFindButtonRow then
  begin
    for ButtonIdx := 0 to 3 do
      if (Col >= FFindButtonCol[ButtonIdx]) and
         (Col < FFindButtonCol[ButtonIdx] + FFindButtonLen[ButtonIdx]) then
      begin
        FFindFocus := ButtonIdx;
        FindButton(ButtonIdx);
        Exit;
      end;
    Exit;
  end;
  RowIdx := FFindTop + Row - FFindListTop;
  if (Row >= FFindListTop) and (Row < FFindListTop + FindListRows) and
     (RowIdx >= 0) and (RowIdx <= High(FFindRows)) and
     not FFindRows[RowIdx].IsHeader then
  begin
    FFindCursor := RowIdx;
    FFindFocus := -1;
  end;
  Invalidate;
end;

procedure TFarView.SetColorRules(const ARules: TFarColorRules);
var
  RuleIndex: Integer;
begin
  FarCopyRules(ARules, FColorRules);
  SetLength(FColorExt, Length(FColorRules));
  for RuleIndex := 0 to High(FColorRules) do
    FColorExt[RuleIndex] := FColorRules[RuleIndex].Ext;
  Invalidate;
end;

procedure TFarView.SetPalette(const APalette: TFarPalette);
begin
  FPal := APalette;
  FarCurPanelBack := FPal[fpPanelBack];
  Color := FPal[fpPanelBack];
  Invalidate;
end;

function TFarView.Palette: TFarPalette;
begin
  Result := FPal;
end;

function TFarView.ColorRules: TFarColorRules;
begin
  FarCopyRules(FColorRules, Result);
end;

// Цвета файла AName по его расширению; False - правила нет (или выключено)
function TFarView.RuleColors(const AName: WideString;
  var AFore, ABack: TColor): Boolean;
var
  Ext: WideString;
  RuleIndex: Integer;
begin
  Result := False;
  if Length(FColorRules) = 0 then
    Exit;
  Ext := FarNameExt(AName);
  if Ext = '' then
    Exit;
  for RuleIndex := 0 to High(FColorRules) do
    if FColorRules[RuleIndex].Enabled and
       FarSameName(Ext, FColorExt[RuleIndex]) then
    begin
      AFore := FColorRules[RuleIndex].Fore;
      ABack := FColorRules[RuleIndex].Back;
      // На фоне панели - читаемым (правила под синий фон на светлой теме)
      if ABack = clNone then
        AFore := FarReadable(AFore, FPal[fpPanelBack]);
      Result := True;
      Exit;
    end;
end;

// ---------------------------------------------------------------------------
//  F9 - Options - Colors и Files highlighting своими окнами (без VCL): для
//  uniFAR. В unIDE эти пункты открывают окна DlgFarPalette и DlgFarColors
//  (OnPaletteDialog, OnColorsDialog), если они заданы.
//
//  Themes: Classic, FarDark 2026, FarLight 2026 и импорт темы FAR Manager
//  (.farconfig) - вся палитра сразу. Colors: меню групп палитры -> меню
//  элементов группы (справа - цвет); Enter - окно выбора цвета Windows (в
//  цветах палитры: на тёмной теме тёмное), Del - стандартный цвет. Files
//  highlighting: меню правил раскраски (образец - цветами правила); Enter /
//  F4 - изменить, Ins - новое, Del - удалить, пробел - вкл / выкл, Ctrl+Up
//  / Ctrl+Down - выше / ниже (действует первое подходящее правило).
//  Изменения записываются в ini сразу (как OK в окнах unIDE).
// ---------------------------------------------------------------------------

// Меню групп палитры; ACursor - группа под курсором
procedure TFarView.ShowPalGroups(ACursor: Integer);
var
  Items: TFarMenuItems;
  Item: TFarPalItem;
  GroupName: string;
  GroupCount: Integer;
begin
  SetLength(Items, 0);
  GroupCount := 0;
  GroupName := '';
  for Item := Low(TFarPalItem) to High(TFarPalItem) do
    if FarPalGroup(Item) <> GroupName then
    begin
      GroupName := FarPalGroup(Item);
      SetLength(Items, Length(Items) + 1);
      Items[High(Items)].Text := WideString(GroupName);
      Items[High(Items)].Mark := ' ';
      Items[High(Items)].Tag := Ord(Item);   // первый элемент группы
      Inc(GroupCount);
    end;
  SetLength(Items, Length(Items) + 2);
  Items[High(Items) - 1].Separator := True;
  Items[High(Items)].Text := '&Default colors';
  Items[High(Items)].Mark := ' ';
  Items[High(Items)].Tag := -1;
  if (ACursor < 0) or (ACursor >= GroupCount) then
    ACursor := 0;
  MenuOpen(fmPalGroups, 'Colors', Items, ACursor, FActive);
end;

// Меню элементов группы, где элемент AFirst (первый в группе); справа -
// цвет. ACursor - элемент под курсором
procedure TFarView.ShowPalItems(AFirst: TFarPalItem; ACursor: TFarPalItem);
var
  Items: TFarMenuItems;
  Item: TFarPalItem;
  GroupName: string;
  CursorIdx: Integer;
begin
  FPalGroupFirst := AFirst;
  GroupName := FarPalGroup(AFirst);
  SetLength(Items, 0);
  CursorIdx := 0;
  for Item := AFirst to High(TFarPalItem) do
  begin
    if FarPalGroup(Item) <> GroupName then
      Break;
    SetLength(Items, Length(Items) + 1);
    Items[High(Items)].Text := WideString(FarPalCaption(Item));
    Items[High(Items)].Mark := ' ';
    Items[High(Items)].Tag := Ord(Item);
    if FPal[Item] = clNone then
      Items[High(Items)].RightText := 'нет'
    else
      Items[High(Items)].RightText := WideString(FarColorToText(FPal[Item]));
    // Образец: справа цветом элемента
    Items[High(Items)].HasColors := True;
    if FarPalIsBack(Item) then
    begin
      Items[High(Items)].Fore := FPal[FarPalPair(Item)];
      Items[High(Items)].Back := FPal[Item];
    end
    else
    begin
      Items[High(Items)].Fore := FPal[Item];
      Items[High(Items)].Back := FPal[FarPalPair(Item)];
    end;
    if Item = ACursor then
      CursorIdx := High(Items);
  end;
  MenuOpen(fmPalItems, WideString(GroupName), Items, CursorIdx, FActive);
  Status(FarProduct + ': Enter - выбрать цвет, Del - стандартный, Esc - ' +
    'к группам');
end;

// Элемент палитры: цвет - окном выбора цвета Windows
procedure TFarView.PalItemChoose(AItem: TFarPalItem);
var
  NewColor: TColor;
begin
  NewColor := FPal[AItem];
  if ChooseColor(NewColor, WideString(FarPalGroup(AItem) + ': ' +
     FarPalCaption(AItem))) then
  begin
    FPal[AItem] := NewColor;
    SetPalette(FPal);
    if FIniName <> '' then
      FarPaletteSave(FIniName, FPal);
  end;
  ShowPalItems(FPalGroupFirst, AItem);
end;

// Del в меню элементов: стандартный цвет элемента
procedure TFarView.PalItemDefault(AItem: TFarPalItem);
begin
  FPal[AItem] := FarPalDefault(AItem);
  SetPalette(FPal);
  if FIniName <> '' then
    FarPaletteSave(FIniName, FPal);
  ShowPalItems(FPalGroupFirst, AItem);
end;

// Меню правил раскраски; ACursor - правило под курсором
procedure TFarView.ShowHiRules(ACursor: Integer);
var
  Items: TFarMenuItems;
  RuleIdx: Integer;
begin
  SetLength(Items, Length(FColorRules));
  for RuleIdx := 0 to High(FColorRules) do
  begin
    Items[RuleIdx].Text := WideString('*.' + FColorRules[RuleIdx].Ext);
    if FColorRules[RuleIdx].Enabled then
      Items[RuleIdx].Mark := FarCheckMark
    else
      Items[RuleIdx].Mark := ' ';
    Items[RuleIdx].RightText :=
      WideString(FarColorToText(FColorRules[RuleIdx].Fore) + ' ' +
      FarColorToText(FColorRules[RuleIdx].Back));
    Items[RuleIdx].Tag := RuleIdx;
    Items[RuleIdx].HasColors := True;
    Items[RuleIdx].Fore := FColorRules[RuleIdx].Fore;
    Items[RuleIdx].Back := FColorRules[RuleIdx].Back;
  end;
  if Length(Items) = 0 then
  begin
    // Пустой список: один пункт - добавить
    SetLength(Items, 1);
    Items[0].Text := '(нет правил - Ins: добавить)';
    Items[0].Mark := ' ';
    Items[0].Tag := -1;
  end;
  MenuOpen(fmHiRules, 'Files highlighting', Items, ACursor, FActive);
  Status(FarProduct + ': Enter / F4 - изменить, Ins - добавить, Del - ' +
    'удалить, пробел - вкл/выкл, Ctrl+Up/Down - порядок');
end;

// Правила изменены: в окно и в ini
procedure TFarView.HiRulesApply(ACursor: Integer);
var
  Rules: TFarColorRules;
begin
  FarCopyRules(FColorRules, Rules);
  SetColorRules(Rules);
  if FIniName <> '' then
    FarColorsSave(FIniName, FColorRules);
  ShowHiRules(ACursor);
end;

// Клавиши меню правил сверх обычных. True - разобрана
function TFarView.HiRulesKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
var
  RuleIdx: Integer;
  Swap: TFarColorRule;
begin
  Result := True;
  RuleIdx := -1;
  if (FMenuCursor >= 0) and (FMenuCursor <= High(FMenuItems)) then
    RuleIdx := FMenuItems[FMenuCursor].Tag;
  if (RuleIdx > High(FColorRules)) then
    RuleIdx := -1;
  if (AKey = VK_INSERT) and not ACtrl and not AAlt then
  begin
    MenuClose;
    PickOpenRule(-1);
  end
  else if ((AKey = VK_F4) or (AKey = VK_RETURN)) and not ACtrl and
          not AAlt then
  begin
    MenuClose;
    PickOpenRule(RuleIdx);
  end
  else if (AKey = VK_DELETE) and (RuleIdx >= 0) then
  begin
    FHiDelIdx := RuleIdx;
    MenuClose;
    DlgOpen(fdHiDelete, 'Files highlighting', ['Delete highlighting for',
      WideString('*.' + FColorRules[RuleIdx].Ext) + '?'], True, True, False,
      '', ['Delete', 'Cancel']);
  end
  else if (AKey = VK_SPACE) and (RuleIdx >= 0) then
  begin
    FColorRules[RuleIdx].Enabled := not FColorRules[RuleIdx].Enabled;
    HiRulesApply(FMenuCursor);
  end
  else if ACtrl and ((AKey = VK_UP) or (AKey = VK_DOWN)) and
          (RuleIdx >= 0) then
  begin
    if (AKey = VK_UP) and (RuleIdx > 0) then
    begin
      Swap := FColorRules[RuleIdx - 1];
      FColorRules[RuleIdx - 1] := FColorRules[RuleIdx];
      FColorRules[RuleIdx] := Swap;
      HiRulesApply(RuleIdx - 1);
    end
    else if (AKey = VK_DOWN) and (RuleIdx < High(FColorRules)) then
    begin
      Swap := FColorRules[RuleIdx + 1];
      FColorRules[RuleIdx + 1] := FColorRules[RuleIdx];
      FColorRules[RuleIdx] := Swap;
      HiRulesApply(RuleIdx + 1);
    end;
  end
  else
    Result := False;
end;

procedure TFarView.HiDeleteRule(AIndex: Integer);
var
  RuleIdx: Integer;
begin
  if (AIndex < 0) or (AIndex > High(FColorRules)) then
    Exit;
  for RuleIdx := AIndex to High(FColorRules) - 1 do
    FColorRules[RuleIdx] := FColorRules[RuleIdx + 1];
  SetLength(FColorRules, Length(FColorRules) - 1);
  if AIndex > High(FColorRules) then
    AIndex := High(FColorRules);
  HiRulesApply(AIndex);
end;

// ---------------------------------------------------------------------------
//  Темы и выбор цвета
// ---------------------------------------------------------------------------

// Окно выбора цвета Windows: AColor - начальный и выбранный цвет (clNone -
// начать с фона панели). False - отказались
function TFarView.ChooseColor(var AColor: TColor;
  const ATitle: WideString): Boolean;
var
  Choose: TFarChooseColor;
begin
  FarCcBack := FPal[fpDlgBack];
  FarCcText := FPal[fpDlgText];
  FarCcEditBack := FPal[fpDlgEditBack];
  FarCcEditText := FPal[fpDlgEditText];
  FarCcBtnBack := FarBlend(FPal[fpDlgBack], FPal[fpDlgText], 12);
  FarCcBtnFocus := FPal[fpDlgFocusBack];
  FarCcBtnFocusText := FPal[fpDlgFocusText];
  FarCcBackBrush := CreateSolidBrush(ColorToRGB(FarCcBack));
  FarCcEditBrush := CreateSolidBrush(ColorToRGB(FarCcEditBack));
  FarCcTitle := ATitle;
  FillChar(Choose, SizeOf(Choose), 0);
  Choose.lStructSize := SizeOf(Choose);
  Choose.hWndOwner := GetParentFormHandle;
  if AColor = clNone then
    Choose.rgbResult := ColorToRGB(FPal[fpPanelBack])
  else
    Choose.rgbResult := ColorToRGB(AColor);
  Choose.lpCustColors := @FCustColors[0];
  Choose.Flags := FarCcRgbInit or FarCcFullOpen or FarCcAnyColor or
    FarCcEnableHook;
  Choose.lpfnHook := @FarCcHook;
  try
    Result := FarChooseColorW(Choose);
  finally
    DeleteObject(FarCcBackBrush);
    DeleteObject(FarCcEditBrush);
    FarCcBackBrush := 0;
    FarCcEditBrush := 0;
  end;
  if Result then
    AColor := TColor(Choose.rgbResult and $FFFFFF);
  // Свои цвета окна (16 ячеек) - до следующего раза
  SaveThemeState;
end;

// [FarTheme]: имя темы и свои цвета окна выбора цвета
procedure TFarView.SaveThemeState;
var
  Ini: TBufIniFile;
  ColorIdx: Integer;
  ColorList: string;
begin
  if FIniName = '' then
    Exit;
  ColorList := '';
  for ColorIdx := 0 to 15 do
  begin
    if ColorIdx > 0 then
      ColorList := ColorList + ',';
    ColorList := ColorList + FarColorToText(TColor(FCustColors[ColorIdx]));
  end;
  Ini := TBufIniFile.Create(FIniName);
  try
    Ini.WriteString(FarThemeSection, 'Name', FThemeName);
    Ini.WriteString(FarThemeSection, 'CustomColors', ColorList);
  finally
    Ini.Free;
  end;
end;

procedure TFarView.LoadThemeState(const AIniName: string);
var
  Ini: TBufIniFile;
  ColorIdx, CommaPos: Integer;
  ColorList, Part: string;
begin
  for ColorIdx := 0 to 15 do
    FCustColors[ColorIdx] := FarConColors[ColorIdx];
  FThemeName := '';
  Ini := TBufIniFile.Create(AIniName);
  try
    FThemeName := Ini.ReadString(FarThemeSection, 'Name', '');
    ColorList := Ini.ReadString(FarThemeSection, 'CustomColors', '');
  finally
    Ini.Free;
  end;
  ColorIdx := 0;
  while (ColorList <> '') and (ColorIdx <= 15) do
  begin
    CommaPos := Pos(',', ColorList);
    if CommaPos > 0 then
    begin
      Part := Copy(ColorList, 1, CommaPos - 1);
      ColorList := Copy(ColorList, CommaPos + 1, MaxInt);
    end
    else
    begin
      Part := ColorList;
      ColorList := '';
    end;
    FCustColors[ColorIdx] := COLORREF(FarTextToColor(Part,
      FarConColors[ColorIdx]));
    Inc(ColorIdx);
  end;
end;

// F9 - Options - Themes
procedure TFarView.ShowThemesMenu;
var
  Items: TFarMenuItems;
  ThemeIdx, CursorIdx: Integer;
begin
  SetLength(Items, FarThemeCount + 2);
  CursorIdx := 0;
  for ThemeIdx := 0 to FarThemeCount - 1 do
  begin
    Items[ThemeIdx].Text := WideString(FarThemeNames[ThemeIdx]);
    Items[ThemeIdx].Tag := ThemeIdx;
    if CompareText(FThemeName, FarThemeNames[ThemeIdx]) = 0 then
    begin
      Items[ThemeIdx].Mark := FarCheckMark;
      CursorIdx := ThemeIdx;
    end
    else
      Items[ThemeIdx].Mark := ' ';
  end;
  Items[FarThemeCount].Separator := True;
  Items[FarThemeCount + 1].Text := '&Import .farconfig...';
  Items[FarThemeCount + 1].Mark := ' ';
  Items[FarThemeCount + 1].Tag := 100;
  // Тема из файла - её имя последней строкой
  if (FThemeName <> '') and (CursorIdx = 0) and
     (CompareText(FThemeName, FarThemeNames[0]) <> 0) then
    Items[FarThemeCount + 1].RightText := WideString(FThemeName);
  MenuOpen(fmThemes, 'Themes', Items, CursorIdx, FActive);
end;

// Палитра темы - в окно и в ini
procedure TFarView.ApplyTheme(const AName: string;
  const APalette: TFarPalette);
begin
  FThemeName := AName;
  SetPalette(APalette);
  if FIniName <> '' then
  begin
    FarPaletteSave(FIniName, FPal);
    SaveThemeState;
  end;
  Status(FarProduct + ': тема ' + AName);
end;

// Импорт .farconfig (тема FAR Manager 3): окно выбора файла
procedure TFarView.ThemeImport;
var
  Open: TFarOpenFileName;
  FileBuf: array[0..MAX_PATH * 2] of WideChar;
  Filter, InitialDir, FileName, Title: WideString;
  Pal: TFarPalette;
  ErrorText: string;
begin
  FillChar(Open, SizeOf(Open), 0);
  FillChar(FileBuf, SizeOf(FileBuf), 0);
  Filter := 'Far Manager themes (*.farconfig)'#0'*.farconfig'#0 +
    'All files (*.*)'#0'*.*'#0#0;
  InitialDir := ActivePanel.Path;
  Open.lStructSize := SizeOf(Open);
  Open.hWndOwner := GetParentFormHandle;
  Open.lpstrFilter := PWideChar(Filter);
  Open.nFilterIndex := 1;
  Open.lpstrFile := FileBuf;
  Open.nMaxFile := Length(FileBuf) - 1;
  if InitialDir <> '' then
    Open.lpstrInitialDir := PWideChar(InitialDir);
  Title := 'Import Far Manager theme';
  Open.lpstrTitle := PWideChar(Title);
  Open.Flags := FarOfnFileMustExist or FarOfnPathMustExist or
    FarOfnHideReadOnly or FarOfnNoChangeDir;
  if not FarGetOpenFileNameW(Open) then
    Exit;
  FileName := FileBuf;
  // Цветов, которых нет в файле, - как в текущей палитре
  Pal := FPal;
  if not FarPaletteFromFarconfig(FileName, Pal, ErrorText) then
  begin
    Status(FarProduct + ': тема не прочитана: ' + ErrorText);
    Exit;
  end;
  ApplyTheme(ChangeFileExt(ExtractFileName(string(FileName)), ''), Pal);
end;

// ---------------------------------------------------------------------------
//  Окно правила раскраски (Files highlighting): расширение, цвет текста и
//  фона (Enter или щелчок - окно выбора цвета Windows), Panel - фон
//  панели, образец. Tab / Shift+Tab - между полями, Enter - OK (на цвете -
//  выбор цвета), Esc - отмена
// ---------------------------------------------------------------------------

procedure TFarView.PickOpenRule(AIndex: Integer);
begin
  FPickOpen := True;
  FPickRuleIdx := AIndex;
  if (AIndex >= 0) and (AIndex <= High(FColorRules)) then
  begin
    FPickExt := WideString(FColorRules[AIndex].Ext);
    FPickFore := FColorRules[AIndex].Fore;
    FPickBack := FColorRules[AIndex].Back;
    FPickFocus := pfFore;
  end
  else
  begin
    FPickRuleIdx := -1;
    FPickExt := '';
    FPickFore := FPal[fpPanelText];
    FPickBack := clNone;
    FPickFocus := pfExt;
  end;
  FPickExtPos := Length(FPickExt);
  Invalidate;
end;

// Закрыть; вернуться в список правил
procedure TFarView.PickClose;
begin
  FPickOpen := False;
  if FPickRuleIdx >= 0 then
    ShowHiRules(FPickRuleIdx)
  else
    ShowHiRules(High(FColorRules));
  Invalidate;
end;

function TFarView.PickButtonText(AIndex: Integer): WideString;
begin
  if AIndex = 0 then
    Result := 'OK'
  else
    Result := 'Cancel';
end;

procedure TFarView.PickMoveFocus(ADelta: Integer);
const
  FocusCount = pfBtn + 2;
begin
  FPickFocus := (FPickFocus + ADelta + FocusCount) mod FocusCount;
end;

// Цвет текста (ABack = False) или фона - окном выбора цвета
procedure TFarView.PickChooseColor(ABack: Boolean);
var
  NewColor: TColor;
  Title: WideString;
begin
  if ABack then
  begin
    NewColor := FPickBack;
    Title := 'Background: *.' + FPickExt;
  end
  else
  begin
    NewColor := FPickFore;
    Title := 'Foreground: *.' + FPickExt;
  end;
  if not ChooseColor(NewColor, Title) then
    Exit;
  if ABack then
    FPickBack := NewColor
  else
    FPickFore := NewColor;
end;

procedure TFarView.PickButton(AIndex: Integer);
var
  Ext: string;
  RuleIdx: Integer;
begin
  if AIndex <> 0 then
  begin
    PickClose;
    Exit;
  end;
  Ext := FarNormalizeExt(string(FPickExt));
  if Ext = '' then
  begin
    Status(FarProduct + ': расширение не задано (pas, *.pas, .pas)');
    FPickFocus := pfExt;
    Exit;
  end;
  for RuleIdx := 0 to High(FColorRules) do
    if (RuleIdx <> FPickRuleIdx) and
       (CompareText(FColorRules[RuleIdx].Ext, Ext) = 0) then
    begin
      Status(FarProduct + ': правило для *.' + Ext + ' уже есть');
      FPickFocus := pfExt;
      Exit;
    end;
  if FPickRuleIdx < 0 then
  begin
    SetLength(FColorRules, Length(FColorRules) + 1);
    FPickRuleIdx := High(FColorRules);
    FColorRules[FPickRuleIdx].Enabled := True;
  end;
  FColorRules[FPickRuleIdx].Ext := Ext;
  FColorRules[FPickRuleIdx].Fore := FPickFore;
  FColorRules[FPickRuleIdx].Back := FPickBack;
  FPickOpen := False;
  HiRulesApply(FPickRuleIdx);
end;

// Правка поля расширения: символ AChar (#0 - клавиша AKey)
procedure TFarView.PickEditKey(var AText: WideString; var APos: Integer;
  AKey: Word; AChar: WideChar);
begin
  if APos > Length(AText) then
    APos := Length(AText);
  if AChar <> #0 then
  begin
    Insert(WideString(AChar), AText, APos + 1);
    Inc(APos);
    Exit;
  end;
  case AKey of
    VK_BACK:
      if APos > 0 then
      begin
        Delete(AText, APos, 1);
        Dec(APos);
      end;
    VK_DELETE:
      if APos < Length(AText) then
        Delete(AText, APos + 1, 1);
    VK_LEFT:
      if APos > 0 then
        Dec(APos);
    VK_RIGHT:
      if APos < Length(AText) then
        Inc(APos);
    VK_HOME:
      APos := 0;
    VK_END:
      APos := Length(AText);
  end;
end;

function TFarView.PickKey(AKey: Word; AShift, ACtrl, AAlt: Boolean): Boolean;
begin
  Result := True;
  case AKey of
    VK_ESCAPE, VK_F10:
      begin
        PickClose;
        Exit;
      end;
    VK_TAB:
      begin
        if AShift then
          PickMoveFocus(-1)
        else
          PickMoveFocus(1);
        Exit;
      end;
    VK_RETURN:
      begin
        case FPickFocus of
          pfFore:
            PickChooseColor(False);
          pfBack:
            PickChooseColor(True);
          pfPanel:
            PickButton(0);
        else
          if FPickFocus >= pfBtn then
            PickButton(FPickFocus - pfBtn)
          else
            PickButton(0);
        end;
        Exit;
      end;
  end;
  case FPickFocus of
    pfExt:
      if (AKey = VK_UP) or (AKey = VK_DOWN) then
        PickMoveFocus(Ord(AKey = VK_DOWN) * 2 - 1)
      else
        PickEditKey(FPickExt, FPickExtPos, AKey, #0);
    pfFore, pfBack, pfPanel:
      if (AKey = VK_UP) or (AKey = VK_LEFT) then
        PickMoveFocus(-1)
      else if (AKey = VK_DOWN) or (AKey = VK_RIGHT) then
        PickMoveFocus(1)
      else if AKey = VK_SPACE then
      begin
        if FPickFocus = pfPanel then
        begin
          // Panel: фон панели или свой цвет (последний выбранный)
          if FPickBack = clNone then
            PickChooseColor(True)
          else
            FPickBack := clNone;
        end
        else
          PickChooseColor(FPickFocus = pfBack);
      end;
  else
    // Кнопки: стрелки - между ними, пробел - нажать
    if (AKey = VK_LEFT) or (AKey = VK_UP) then
      PickMoveFocus(-1)
    else if (AKey = VK_RIGHT) or (AKey = VK_DOWN) then
      PickMoveFocus(1)
    else if AKey = VK_SPACE then
      PickButton(FPickFocus - pfBtn);
  end;
end;

procedure TFarView.PickChar(ACh: WideChar);
begin
  if FPickFocus = pfExt then
    PickEditKey(FPickExt, FPickExtPos, 0, ACh);
end;

procedure TFarView.DrawPick;
var
  BoxW, BoxH, BoxLeft, BoxTop, Inner, Row, SepY, ButtonIdx, ButtonsW: Integer;
  ButtonCol, EditW, CaretX, Scroll: Integer;
  Back, Fore, SampleBack, CapFore, CapBack: TColor;
  SampleText, ButtonText, Shown, Caption: WideString;

  // Подпись поля: с фокусом - цветом фокуса
  procedure PutCaption(ACol, ARow: Integer; const AText: WideString;
    AFocused: Boolean);
  begin
    if AFocused then
    begin
      CapFore := FPal[fpDlgFocusText];
      CapBack := FPal[fpDlgFocusBack];
    end
    else
    begin
      CapFore := Fore;
      CapBack := Back;
    end;
    PutText(ACol, ARow, Length(AText), AText, CapFore, CapBack);
  end;

begin
  BoxW := 56;
  if BoxW > FCols - 2 then
    BoxW := FCols - 2;
  BoxH := 13;
  if (BoxW < 40) or (PanelHeight < BoxH) then
    Exit;
  BoxLeft := (FCols - BoxW) div 2;
  BoxTop := (PanelHeight - BoxH) div 2;
  if BoxTop < 0 then
    BoxTop := 0;
  Inner := BoxLeft + 5;
  Back := FPal[fpDlgBack];
  Fore := FPal[fpDlgText];
  for Row := BoxTop to BoxTop + BoxH - 1 do
    FillCells(BoxLeft, Row, BoxW, Back);
  DrawBox(BoxLeft + 2, BoxTop + 1, BoxLeft + BoxW - 3, BoxTop + BoxH - 2, Fore);
  PutCentered(BoxLeft, BoxTop + 1, BoxW, ' Files highlighting ', Fore, Back);

  // Расширение
  Row := BoxTop + 2;
  FPickExtRow := Row;
  FPickExtCol := Inner + 12;
  PutCaption(Inner, Row, 'Extension:', FPickFocus = pfExt);
  EditW := BoxW - 10 - 12;
  Scroll := 0;
  if FPickExtPos > EditW - 1 then
    Scroll := FPickExtPos - EditW + 1;
  Shown := Copy(FPickExt, Scroll + 1, EditW);
  PutText(FPickExtCol, Row, EditW, Shown, FPal[fpDlgEditText],
    FPal[fpDlgEditBack]);
  if FPickFocus = pfExt then
  begin
    CaretX := (FPickExtCol + FPickExtPos - Scroll) * FCellW;
    FBuffer.Canvas.Brush.Style := bsSolid;
    FBuffer.Canvas.Brush.Color := FPal[fpDlgEditText];
    FBuffer.Canvas.FillRect(Rect(CaretX, Row * FCellH + 1, CaretX + 2,
      (Row + 1) * FCellH - 1));
  end;

  // Цвет текста: образец цвета и #RRGGBB
  Inc(Row, 2);
  FPickForeRow := Row;
  PutCaption(Inner, Row, 'Foreground:', FPickFocus = pfFore);
  PutText(Inner + 12, Row, 6, '', Fore, FPickFore);
  PutText(Inner + 19, Row, 20, WideString(FarColorToText(FPickFore)) +
    '  (Enter - выбрать)', Fore, Back);

  // Цвет фона
  Inc(Row);
  FPickBackRow := Row;
  PutCaption(Inner, Row, 'Background:', FPickFocus = pfBack);
  if FPickBack = clNone then
  begin
    PutText(Inner + 12, Row, 6, '', Fore, FPal[fpPanelBack]);
    Caption := 'фон панели';
  end
  else
  begin
    PutText(Inner + 12, Row, 6, '', Fore, FPickBack);
    Caption := WideString(FarColorToText(FPickBack));
  end;
  PutText(Inner + 19, Row, 20, Caption, Fore, Back);

  // Panel: фон панели вместо своего
  Inc(Row);
  FPickPanelRow := Row;
  if FPickBack = clNone then
    Caption := '[x] Panel background'
  else
    Caption := '[ ] Panel background';
  PutCaption(Inner + 12, Row, Caption, FPickFocus = pfPanel);

  // Образец
  Inc(Row, 2);
  if FPickBack = clNone then
    SampleBack := FPal[fpPanelBack]
  else
    SampleBack := FPickBack;
  if FPickExt <> '' then
    SampleText := ' file.' + FPickExt + ' '
  else
    SampleText := ' file.ext ';
  PutText(Inner, Row, 8, 'Sample:', Fore, Back);
  PutText(Inner + 12, Row, Length(SampleText), SampleText, FPickFore,
    SampleBack);
  Inc(Row);

  // Разделитель и кнопки
  SepY := Row * FCellH + FCellH div 2;
  with FBuffer.Canvas do
  begin
    Pen.Color := Fore;
    MoveTo((BoxLeft + 2) * FCellW + FCellW div 2 + 1, SepY);
    LineTo((BoxLeft + BoxW - 3) * FCellW + FCellW div 2, SepY);
  end;
  Inc(Row);
  ButtonsW := 0;
  for ButtonIdx := 0 to 1 do
    Inc(ButtonsW, Length(PickButtonText(ButtonIdx)) + 5);
  Dec(ButtonsW);
  ButtonCol := BoxLeft + (BoxW - ButtonsW) div 2;
  FPickBtnRow := Row;
  for ButtonIdx := 0 to 1 do
  begin
    ButtonText := '[ ' + PickButtonText(ButtonIdx) + ' ]';
    FPickBtnCol[ButtonIdx] := ButtonCol;
    PutCaption(ButtonCol, Row, ButtonText, FPickFocus = pfBtn + ButtonIdx);
    Inc(ButtonCol, Length(ButtonText) + 1);
  end;
end;

// Щелчок в окне правила
procedure TFarView.PickMouse(AX, AY: Integer);
var
  Col, Row, ButtonIdx: Integer;
begin
  Col := AX div FCellW;
  Row := AY div FCellH;
  if (Row = FPickExtRow) and (Col >= FPickExtCol) then
    FPickFocus := pfExt
  else if Row = FPickForeRow then
  begin
    FPickFocus := pfFore;
    PickChooseColor(False);
  end
  else if Row = FPickBackRow then
  begin
    FPickFocus := pfBack;
    PickChooseColor(True);
  end
  else if Row = FPickPanelRow then
  begin
    FPickFocus := pfPanel;
    if FPickBack = clNone then
      PickChooseColor(True)
    else
      FPickBack := clNone;
  end
  else if Row = FPickBtnRow then
    for ButtonIdx := 0 to 1 do
      if (Col >= FPickBtnCol[ButtonIdx]) and (Col < FPickBtnCol[ButtonIdx] +
         Length(PickButtonText(ButtonIdx)) + 4) then
      begin
        FPickFocus := pfBtn + ButtonIdx;
        PickButton(ButtonIdx);
        Exit;
      end;
end;

// F9: меню Options (только оно - решено). Что ещё не сделано - серым
procedure TFarView.ShowOptionsMenu;
const
  ItemTexts: array[0..7] of string = ('&Panel settings', 'Con&firmations',
    '', '&Themes', '&Colors', 'Files &highlighting', '', '&Save setup');
  ItemTags: array[0..7] of Integer = (0, 0, 0, 4, 3, 1, 0, 2);
var
  Items: TFarMenuItems;
  ItemIndex: Integer;
begin
  SetLength(Items, 8);
  for ItemIndex := 0 to 7 do
  begin
    Items[ItemIndex].Text := ItemTexts[ItemIndex];
    Items[ItemIndex].RightText := '';
    Items[ItemIndex].Mark := ' ';
    Items[ItemIndex].Separator := ItemTexts[ItemIndex] = '';
    Items[ItemIndex].Disabled := (ItemTags[ItemIndex] = 0) and
      not Items[ItemIndex].Separator;
    Items[ItemIndex].Data := '';
    Items[ItemIndex].Tag := ItemTags[ItemIndex];
  end;
  Items[7].RightText := 'Shift+F9';
  MenuOpen(fmOptions, 'Options', Items, 3, FActive);
end;

// Save setup (Shift+F9): папки панелей, сортировка, история - в editor.ini
procedure TFarView.SaveSetup;
begin
  if FIniName = '' then
    Exit;
  SaveState(FIniName);
  Status(FarProduct + ': настройки записаны в ' + ExtractFileName(FIniName));
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
  Rules: TFarColorRules;
  Pal: TFarPalette;
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
    SetLength(FHistoryLock, 0);
    for HistoryIndex := 1 to HistoryCount do
    begin
      SavedPath := FarDecodePath(Ini.ReadString(FarHistorySection,
        'Folder' + IntToStr(HistoryIndex), ''));
      if SavedPath <> '' then
      begin
        SetLength(FHistory, Length(FHistory) + 1);
        SetLength(FHistoryLock, Length(FHistory));
        FHistory[High(FHistory)] := SavedPath;
        FHistoryLock[High(FHistory)] := Ini.ReadBool(FarHistorySection,
          'Lock' + IntToStr(HistoryIndex), False);
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
    FHalfWidth := Ini.ReadInteger(FarIniSection, 'HalfWidth', 0);
    FIniName := AIniName;
    FPanelCut := Ini.ReadInteger(FarIniSection, 'PanelCut', 0);
    FPanelShift := Ini.ReadInteger(FarIniSection, 'PanelShift', 0);
    // Shift+F1: формат (0 - ZIP, 1 - 7z) и уровень сжатия (0..5, 3 - Normal)
    FArcAddFormat := Ini.ReadInteger(FarIniSection, 'ArcFormat', 0);
    FArcAddLevel := Ini.ReadInteger(FarIniSection, 'ArcLevel', 3);
    // Alt+F7: что искали
    FFindMask := FarDecodePath(Ini.ReadString(FarIniSection, 'FindMask',
      '*.*'));
    FFindText := FarDecodePath(Ini.ReadString(FarIniSection, 'FindText', ''));
    FFindCodePage := Ini.ReadInteger(FarIniSection, 'FindCodePage', 0);
    if (FFindCodePage < 0) or (FFindCodePage > 4) then
      FFindCodePage := 0;
    FFindCase := Ini.ReadInteger(FarIniSection, 'FindCase', 0) = 1;
    FFindWhole := Ini.ReadInteger(FarIniSection, 'FindWhole', 0) = 1;
    FFindFolders := Ini.ReadInteger(FarIniSection, 'FindFolders', 1) = 1;
    FFindArea := Ini.ReadInteger(FarIniSection, 'FindArea', 0);
    if (FFindArea < 0) or (FFindArea > 2) then
      FFindArea := 0;
    // История командной строки
    HistoryCount := Ini.ReadInteger(FarCmdHistorySection, 'Count', 0);
    if HistoryCount > FarCmdHistoryMax then
      HistoryCount := FarCmdHistoryMax;
    SetLength(FCmdHistory, 0);
    for HistoryIndex := 1 to HistoryCount do
    begin
      SavedPath := FarDecodePath(Ini.ReadString(FarCmdHistorySection,
        'Cmd' + IntToStr(HistoryIndex), ''));
      if SavedPath <> '' then
      begin
        SetLength(FCmdHistory, Length(FCmdHistory) + 1);
        FCmdHistory[High(FCmdHistory)] := SavedPath;
      end;
    end;
    FCmdHistPos := Length(FCmdHistory);
    FActive := Ini.ReadInteger(FarIniSection, 'Active', 0);
    if (FActive < 0) or (FActive > 1) then
      FActive := 0;
  finally
    Ini.Free;
  end;
  FarColorsLoad(AIniName, Rules);
  SetColorRules(Rules);
  FarFtpHostsLoad(AIniName, FFtpHosts);
  // Шаг табуляции редактора - как у основного ([Editor] TabChars)
  FEditTabSize := 4;
  Ini := TBufIniFile.Create(AIniName);
  try
    FEditTabSize := StrToIntDef(Ini.ReadString('Editor', 'TabChars', '4'), 4);
  finally
    Ini.Free;
  end;
  if (FEditTabSize < 1) or (FEditTabSize > 32) then
    FEditTabSize := 4;
  FarPaletteLoad(AIniName, Pal);
  SetPalette(Pal);
  LoadThemeState(AIniName);
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
    SetLength(FHistoryLock, Length(FHistory));
    for HistoryIndex := 0 to High(FHistory) do
    begin
      Ini.WriteString(FarHistorySection, 'Folder' + IntToStr(HistoryIndex + 1),
        FarEncodePath(FHistory[HistoryIndex]));
      if FHistoryLock[HistoryIndex] then
        Ini.WriteBool(FarHistorySection, 'Lock' + IntToStr(HistoryIndex + 1),
          True);
    end;
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
    Ini.WriteInteger(FarIniSection, 'PanelCut', FPanelCut);
    Ini.WriteInteger(FarIniSection, 'PanelShift', FPanelShift);
    Ini.WriteInteger(FarIniSection, 'ArcFormat', FArcAddFormat);
    Ini.WriteInteger(FarIniSection, 'ArcLevel', FArcAddLevel);
    Ini.WriteString(FarIniSection, 'FindMask', FarEncodePath(FFindMask));
    Ini.WriteString(FarIniSection, 'FindText', FarEncodePath(FFindText));
    Ini.WriteInteger(FarIniSection, 'FindCodePage', FFindCodePage);
    Ini.WriteInteger(FarIniSection, 'FindCase', Ord(FFindCase));
    Ini.WriteInteger(FarIniSection, 'FindWhole', Ord(FFindWhole));
    Ini.WriteInteger(FarIniSection, 'FindFolders', Ord(FFindFolders));
    Ini.WriteInteger(FarIniSection, 'FindArea', FFindArea);
    Ini.EraseSection(FarCmdHistorySection);
    Ini.WriteInteger(FarCmdHistorySection, 'Count', Length(FCmdHistory));
    for HistoryIndex := 0 to High(FCmdHistory) do
      Ini.WriteString(FarCmdHistorySection, 'Cmd' + IntToStr(HistoryIndex + 1),
        FarEncodePath(FCmdHistory[HistoryIndex]));
    if FHalfWidth > 0 then
      Ini.WriteInteger(FarIniSection, 'HalfWidth', FHalfWidth);
  finally
    Ini.Free;
  end;
end;

end.
