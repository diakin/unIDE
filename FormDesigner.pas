unit FormDesigner;

// ---------------------------------------------------------------------------
//  Визуальный конструктор форм: первый этап
//
//  Форма строится из текста .dfm настоящими контролами VCL и показывается
//  отдельным окном - так же устроен конструктор Delphi 7. Поверх - сетка
//  точками, выделение щелчком, перемещение мышью и 8 маркеров изменения
//  размера. Логика маркеров - из RQFormDsg (ShowCarets, MouseResizeObject):
//  та же нумерация по кругу и те же правила, какую сторону тянет маркер.
//
//      1   8   7
//      2       6
//      3   4   5
//
//  Маркеры стоят ВНУТРИ рамки компонента, а не снаружи: снаружи их бывает
//  не зацепить - у края формы или у соседнего компонента.
//
//  Сам текст .dfm конструктор не хранит. Изменения он отдаёт наружу
//  (OnChange: имя компонента и строки Имя=значение), а кто владеет текстом -
//  тот и пишет. Для этого же здесь DfmSetProps - точечная правка строк
//  свойств объекта: остальной файл не трогается.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, Graphics, ExtCtrls,
  ComCtrls;

type
  TFormDesigner = class;

  // Отладочный вывод конструктора: главное окно подставляет сюда запись в
  // свой лог (HiLite log). Не подставило - строки просто не выводятся.
  TDsgLogProc = procedure(const S: string; AColor: TColor) of object;

  TDsgSelectEvent = procedure(const AName: string) of object;
  // Изменились свойства компонента. AProps - строки Имя=значение в записи
  // .dfm; имя с "?" в начале - менять, только если строка уже есть
  TDsgChangeEvent = procedure(const AName: string; AProps: TStrings) of object;
  TDsgKeyEvent = procedure(AKey: Word; ACtrl, AShift: Boolean) of object;
  // Щелчок по форме, пока на палитре выбран класс. AParent - контейнер под
  // курсором (панель, группа, лист, сама форма); X, Y - точка в нём, по
  // сетке; AFormX, AFormY - та же точка на форме (для невизуальных, они
  // лежат на корне). AHandled = True - щелчок ушёл на вставку, выделения
  // и перемещения не будет.
  // Двойной щелчок по компоненту в конструкторе: AName - его имя
  TDsgNameEvent = procedure(const AName: string) of object;
  // Правый щелчок: точка на экране, где показать меню
  TDsgPointEvent = procedure(const AScreen: TPoint) of object;
  // Открыта другая вкладка TPageControl (щелчком в конструкторе или при
  // загрузке формы - по ActivePage из .dfm)
  TDsgPageEvent = procedure(const APageCtl: string; AIndex: Integer) of object;
  // Серия правок конструктора (перенос группы, выравнивание): ABegin = True
  // - перед первой, False - после последней. Главное окно пишет их в .dfm
  // одним шагом отката и перестраивает инспектор один раз.
  TDsgBatchEvent = procedure(ABegin: Boolean) of object;
  TDsgPlaceEvent = procedure(const AParent: string; X, Y, AFormX, AFormY: Integer;
                             var AHandled: Boolean) of object;

  // Маркер изменения размера: окошко 6x6 внутри рамки выделенного компонента
  TDsgCaret = class(TCustomControl)
  private
    FDesigner: TFormDesigner;
    FIndex: Integer;
    FActive: Boolean;
    FFrom: TPoint;
    FRect: TRect;
    function CanDrag: Boolean;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
                      X, Y: Integer); override;
  public
    constructor CreateCaret(AOwner: TComponent; ADesigner: TFormDesigner;
                            AIndex: Integer);
  end;

  // Уголок компонента группы: окошко 5x5 поверх формы, как маркер выделения.
  // Отдельным окном, а не рисованием на самом компоненте: своя отрисовка
  // компонента (подсветка под мышью и т. п.) его не закрывает. Окно
  // выключено (Enabled = False) - щелчки проходят к компоненту под ним.
  TDsgGroupMark = class(TCustomControl)
  protected
    procedure Paint; override;
  end;

  // Значок невизуального компонента (TTimer, TMainMenu, диалоги) в его точке
  // Left/Top, как в конструкторе Delphi
  TDsgIcon = class(TCustomControl)
  private
    FDesigner: TFormDesigner;
    FComp: TComponent;
    FClassName: string;
    FActive, FMoved: Boolean;
    FFrom: TPoint;
    FStart: TPoint;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
                      X, Y: Integer); override;
  end;

  // Заглушки для классов, которых в редакторе нет (TComPort, TRichView):
  // визуальный - серый прямоугольник с подписью, невизуальный - значок
  TDsgStub = class(TPanel);
  TDsgNonVisual = class(TComponent);

  TFormDesigner = class
  private
    FForm: TForm;
    FCarets: array[1..8] of TDsgCaret;
    FSel: TComponent;
    FGrid: Integer;
    FRootName: string;
    FClassOf: TStringList;    // имя компонента -> класс из .dfm
    FVisualUnknown: TStringList; // неизвестные классы, у которых есть Width
    // перемещение мышью
    FDragging, FDragMoved: Boolean;
    FDragCtl: TControl;
    FDragFrom: TPoint;
    FDragRect: TRect;
    FOnSelect: TDsgSelectEvent;
    FOnChange: TDsgChangeEvent;
    FOnKey: TDsgKeyEvent;
    FOnClose: TNotifyEvent;
    FOnPlace: TDsgPlaceEvent;
    FOnDblClick: TDsgNameEvent;
    FOnContext: TDsgPointEvent;
    FOnPageChange: TDsgPageEvent;
    FOnBatch: TDsgBatchEvent;
    FOnGroupChange: TNotifyEvent;
    // Группа выделенных Shift+щелчком (как в Delphi): первым - главный
    // (FSel), по нему выравниваются остальные. Пуста или один - группы нет,
    // выделение обычное, с чёрными маркерами. У группы маркеров нет - у
    // каждого её компонента уголки (ShowGroupMarks).
    FGroup: TList;
    FGroupMarks: TList;           // окошки уголков, по 4 на компонент
    FGroupDrag: Boolean;          // тянут группу
    FGroupFrom: array of TRect;   // места компонентов группы до переноса
    // Компоненты, созданные по коду модуля (runtime): только просмотр -
    // их не двигают, не растягивают и не пишут в .dfm
    FRuntime: TList;
    // Компоненты .dfm, у которых часть места и размера при работе задаёт
    // код (MarkCodePlaced): строки "адрес компонента=буквы" - L, T, W, H.
    // Эти координаты не меняются ни мышью, ни маркерами.
    FCodePlaced: TStringList;
    // Идёт установка компонентов из кода (BeginRuntime .. FinishRuntime):
    // окно не перерисовывается, выравнивание в контейнерах отложено
    FRtBatch: Boolean;
    FAlignOff: TList;            // кому отложено выравнивание - вернуть
    // Контролы, скрытые в .dfm или в коде (Visible = False). В
    // конструкторе они показываются, но обводятся красной рамкой.
    FHidden: TList;
    // Видимость по вкладкам: что код показывает и прячет при смене вкладки.
    // Имена - TPageControl, Objects - TStringList "Компонент=1/0". Правило
    // здесь сильнее Visible из .dfm (FHidden). См. SetPageRules.
    FPageRules: TStringList;
    FRuntimeParent: TComponent;  // родитель для AddRuntime объектом, не именем
    FLastRuntime: TComponent;    // что создал последний AddRuntime
    FRefocusing: Boolean; // форма сейчас забирает фокус себе
    // Компоненты вкладок TTabControl (SetTabMembers): строки - адрес
    // TTabControl, Objects - TStringList "Имя=номер вкладки"
    FTabMembers: TStringList;
    procedure ApplyTabMembers(ATabCtl: TTabControl);
    procedure LockButtonRows;
    procedure ToggleGroup(AComp: TComponent);
    procedure ShowGroupMarks;
    procedure CommitGroup;
    procedure SpaceGroup(AHorz: Boolean);
    function PlaceParent(ATarget: TComponent): TWinControl;
    procedure ApplyPropText(AObj: TPersistent; const AProp, AValue: string);
    function PrepareText(const AText: string): string;
    procedure ReaderFindClass(Reader: TReader; const ClassName: string;
                              var ComponentClass: TComponentClass);
    procedure ReaderFindMethod(Reader: TReader; const MethodName: string;
                               var Address: Pointer; var Error: Boolean);
    procedure ReaderError(Reader: TReader; const Message: string;
                          var Handled: Boolean);
    procedure AfterLoad;
    procedure FlushPaint;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Clear;
  public
    constructor Create;
    destructor Destroy; override;
    function Load(const ADfmText: string; var AError: string): Boolean;
    function Snap(V: Integer): Integer;
    procedure Select(AComp: TComponent; ANotify: Boolean);
    // Щелчок по строке меню формы (точка в координатах экрана): меню не
    // раскрывается, выделяется меню формы, а в инспекторе - пункт под
    // мышью (OnSelect с его именем)
    procedure MenuBarClick(const AScreen: TPoint);
    procedure SelectByName(const AName: string);
    function SelectedName: string;
    function SelControl: TControl;
    procedure ShowCarets;
    procedure HideCarets;
    procedure PaintGrid(DC: HDC);
    // от перехватчиков сообщений
    procedure MouseDown(ATarget: TComponent; const AScreen: TPoint);
    procedure MouseMove(const AScreen: TPoint);
    procedure MouseUp;
    procedure KeyDown(AKey: Word);
    procedure FormMoved;
    procedure CommitBounds(AComp: TComponent);
    property Form: TForm read FForm;
    property RootName: string read FRootName;
    property Dragging: Boolean read FDragging;
    property Grid: Integer read FGrid write FGrid;
    property OnSelect: TDsgSelectEvent read FOnSelect write FOnSelect;
    property OnChange: TDsgChangeEvent read FOnChange write FOnChange;
    property OnKey: TDsgKeyEvent read FOnKey write FOnKey;
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
    property OnPlace: TDsgPlaceEvent read FOnPlace write FOnPlace;
    property OnDblClick: TDsgNameEvent read FOnDblClick write FOnDblClick;
    property OnContext: TDsgPointEvent read FOnContext write FOnContext;
    property OnPageChange: TDsgPageEvent read FOnPageChange write FOnPageChange;
    property OnBatch: TDsgBatchEvent read FOnBatch write FOnBatch;
    // Состав группы изменился (Shift+щелчок)
    property OnGroupChange: TNotifyEvent read FOnGroupChange write FOnGroupChange;
    // Сколько компонентов в группе; 0 - группы нет
    function GroupCount: Integer;
    // Имена выделенных: группы (главный первым) или одного выделенного.
    // Сама форма и компоненты из кода не входят.
    procedure GroupNames(ANames: TStrings);
    function InGroup(AComp: TComponent): Boolean;
    // Компоненты группы - объектами, включая созданные в коде и безымянные
    // (значок невизуального - его компонент). Группы нет - пусто.
    procedure GroupComps(AList: TList);
    // Группа из компонентов, созданных в коде (кнопки палитры и т. п.).
    // Группа бывает либо из таких, либо из компонентов .dfm - не вперемешку.
    // Место таким задаёт код: их не двигают, не выравнивают и в .dfm не
    // пишут - правятся только свойства (главное окно, editor.ini).
    function GroupIsRuntime: Boolean;
    // Выравнивание группы по главному (первому выделенному):
    // 0 - левые края, 1 - правые, 2 - верх, 3 - низ, 4 - ширина, 5 - высота;
    // 6, 7 - расставить на равных промежутках по ширине, по высоте
    // родителя (SpaceGroup)
    procedure AlignGroup(AKind: Integer);
    // Правый щелчок по AComp: выделить и попросить главное окно показать
    // меню конструктора
    procedure ContextMenu(AComp: TComponent; const AScreen: TPoint);
    // Двойной щелчок: выделенный компонент - в OnDblClick. Перетаскивание,
    // начатое вторым нажатием, отменяется.
    procedure DblClick;
    // Компонент, созданный в коде: класс, имя переменной, родитель (имя
    // компонента на форме, '' или имя корня - сама форма) и свойства
    // "Имя=значение" в записи .dfm. Выражения, которые не разобрать, и
    // события пропускаются. False - класс неизвестен или родителя нет.
    function AddRuntime(const AName, AClass, AParent: string;
                        AProps: TStrings): Boolean;
    function IsRuntime(AComp: TComponent): Boolean;
    // Родитель следующих AddRuntime - сам компонент, а не имя: у созданных
    // в чужом модуле (вкладки палитры внутри TDsgPalette) имени нет.
    // nil - искать по имени, как раньше.
    property RuntimeParent: TComponent read FRuntimeParent write FRuntimeParent;
    property LastRuntime: TComponent read FLastRuntime;
    // Перед серией AddRuntime: окно перестаёт перерисовываться, выравнивание
    // во всех контейнерах откладывается до FinishRuntime. Иначе каждое
    // свойство каждого компонента (Left, Width, Align...) - перерисовка и
    // пересчёт раскладки родителя: сотни компонентов - секунды.
    procedure BeginRuntime;
    // Все компоненты из кода поставлены - пересчитать выравнивание сразу,
    // во всех контейнерах: иначе оно пересчитывается при первом щелчке
    // (маркеры выделения - тоже окна на форме), и раскладка прыгает. После
    // BeginRuntime - вернуть выравнивание и перерисовку.
    procedure FinishRuntime;
    // Компонент .dfm, которому код меняет родителя (RichEdit1.Parent :=
    // FEditHost): ставится туда же, что и в работе. Дальше он только для
    // просмотра - его Left/Top в .dfm записаны относительно прежнего
    // родителя, и писать туда новые было бы неверно.
    function Reparent(const AName, AParent: string): Boolean;
    procedure MarkRuntime(ACtl: TWinControl);
    // Серая пунктирная рамка у контейнера без видимой границы (TPanel с
    // BevelOuter = bvNone и т. п.), как в Delphi: иначе его края на форме
    // не видны. Только в окне конструктора, в .dfm не пишется.
    procedure MarkBorderless(ACtl: TWinControl);
    // Такая же рамка у безоконных детей ACtl, которые сами ничего не рисуют:
    // плоская TSpeedButton (Flat) - пока над ней нет мыши, TPaintBox,
    // TImage без картинки. Их рисует ACtl, поэтому и рамка - здесь.
    procedure MarkInvisibleKids(ACtl: TWinControl);
    // Компонент .dfm, у которого часть места и размера при работе задаёт
    // код. ASides - какие координаты: L (Left), T (Top), W (Width),
    // H (Height). Главное окно ставит их как в живой форме и помечает
    // здесь: двигать по этой оси и тянуть эту сторону нельзя, остальное -
    // можно, и в .dfm пишется только оно.
    procedure MarkCodePlaced(AComp: TComponent; const ASides: string);
    // Буквы координат, которые задаёт код; '' - никакие
    function CodePlacedSides(AComp: TComponent): string;
    // Красная рамка у скрытых: у самого ACtl, если он скрыт, и у его
    // безоконных детей (TLabel и т. п.) - их рисует ACtl
    procedure MarkHidden(ACtl: TWinControl);
    // Компонент формы под точкой экрана: самый верхний, включая
    // отключённые. Внутренние контролы компонента (кнопки TRadioGroup)
    // заменяются им самим.
    function TargetAt(const AScreen: TPoint): TControl;
    // Видимость компонентов для открытой вкладки APageCtl: строки
    // "Имя=1" (показан) или "Имя=0" (скрыт). Заменяет прежние правила этого
    // TPageControl и перерисовывает форму.
    procedure SetPageRules(const APageCtl: string; ARules: TStrings);
    // Скрыт ли компонент: по правилу вкладки, если оно есть, иначе по .dfm
    function MarkedHidden(AC: TControl): Boolean;
    // Какой компонент на какой вкладке ATabCtl: строки "Имя=номер вкладки".
    // У TTabControl одна клиентская область на все вкладки, и что на какой
    // из них, знает только код (палитра - TDsgPalette). Показываются
    // компоненты открытой вкладки, остальные прячутся - и сразу, и при
    // щелчке по вкладке в конструкторе. Красной рамки у спрятанных так нет:
    // они не скрыты, они на другой вкладке.
    procedure SetTabMembers(ATabCtl: TTabControl; AMembers: TStrings);
    // Одно свойство одному компоненту - после правки в инспекторе, без
    // перестройки формы. AComp - имя компонента (созданный в коде назван
    // по переменной), имя корня - сама форма. AValue - в записи .dfm.
    // False - компонента на форме нет или свойство так не ставится (Name):
    // нужна полная перезагрузка.
    function SetPropText(const AComp, AProp, AValue: string): Boolean;
    // То же по самому компоненту - и безымянному
    function SetCompPropText(AComp: TComponent;
                             const AProp, AValue: string): Boolean;
    // Перерисовать маркеры выделения и уголки группы (сменился
    // DsgCaretColor или DsgGroupColor)
    procedure RepaintCarets;
  end;

// Точечная правка свойств объекта AName в тексте .dfm. Есть строка
// свойства на уровне объекта - меняется значение; нет - добавляется сразу
// под заголовком object (порядок строк Delphi не важен). Имя с "?" в
// начале - только замена. Остальной текст не трогается.
function DfmSetProps(const AText, AName: string; AProps: TStrings): string;

// Границы объекта AName в тексте .dfm: строка заголовка object и строка
// его end, от нуля. Вложенные объекты и многострочные значения (списки,
// двоичные данные, коллекции с их item ... end, строки через +) учтены.
function DfmObjectRange(const AText, AName: string;
                        var AFirst, ALast: Integer): Boolean;

// Имена объекта AName и всех вложенных в него, в порядке файла. Нужны,
// чтобы при удалении убрать их поля из .pas.
function DfmObjectNames(const AText, AName: string; ANames: TStrings): Boolean;

// Текст без объекта AName вместе со всем вложенным. Нет объекта - AText.
function DfmDeleteObject(const AText, AName: string): string;

// Вставка объекта последним ребёнком в AParent, перед его end. AObjText -
// текст object ... end с нулевым отступом, отступ ставится по родителю.
// Нет родителя - AText.
function DfmInsertObject(const AText, AParent, AObjText: string): string;

// Класс корня формы из первой строки .dfm: TForm0. '' - не .dfm.
function DfmRootClass(const AText: string): string;

// Строки свойств-ссылок на удалённые компоненты (ActivePage = TabSheet2,
// PopupMenu = PopupMenu1, Images = ImageList1): значение - одно имя из
// ANames. Delphi при удалении компонента такие ссылки тоже убирает. Внутри
// коллекций (item ... end) ссылки не ищутся.
function DfmRemoveRefs(const AText: string; ANames: TStrings): string;

// Поле компонента "AName: AType;" в объявление класса формы AClassName -
// после последнего поля первой секции (там, где их держит Delphi), перед
// первым методом, свойством или словом видимости. Нет класса - APas.
function PasAddField(const APas, AClassName, AName, AType: string): string;

var
  DsgLogProc: TDsgLogProc = nil;
  // Подробный журнал установки компонентов из кода: строка на компонент и
  // строка на каждое его свойство. Сотня компонентов со снимком - тысячи
  // строк в окне лога и секунды, в которые главный поток не выбирает
  // сообщения. Включать только для разбора AddRuntime. Предупреждения
  // (класс неизвестен, родитель не найден, не создался) пишутся всегда.
  DsgLogVerbose: Boolean = False;
  // Цвет маркеров выделения (8 квадратиков вокруг выбранного компонента).
  // Ставит главное окно из цветов IDE (Dsg.Caret); после смены -
  // RepaintCarets у конструктора.
  DsgCaretColor: TColor = clBlack;
  // Цвет уголков компонентов группы (Shift+щелчок). Ставит главное окно из
  // цветов IDE (Dsg.GroupMark); после смены - RepaintCarets.
  DsgGroupColor: TColor = $00E07000;

// Отладочная строка в лог главного окна
procedure DsgLog(const S: string; AColor: TColor = clRed);

// Класс объекта AName из его заголовка в .dfm (TButton). '' - нет объекта.
function DfmObjectClass(const AText, AName: string): string;

// Значение свойства AProp объекта AName - как записано в .dfm, одной
// строкой (OnClick = Button1Click -> Button1Click). '' - свойства нет.
// Ищется только среди своих свойств объекта, не у вложенных.
function DfmGetProp(const AText, AName, AProp: string): string;

// Метод формы: объявление ADecl ("procedure Button1Click(Sender: TObject);")
// - в первую секцию класса AClassName, после полей и методов, перед первым
// словом видимости; тело с пустыми begin/end - в конец implementation,
// перед initialization/finalization или end. модуля. Нет класса - APas.
function PasAddMethod(const APas, AClassName, ADecl: string): string;

// Имя родителя объекта AName в тексте .dfm: объект, в чьём блоке он лежит.
// У детей формы - имя корня. '' - объекта нет или это сам корень.
function DfmParentOf(const AText, AName: string): string;

// Блок object AName ... end с нулевым отступом (для буфера обмена)
function DfmObjectText(const AText, AName: string): string;

// Перенос блока объекта последним (AToFront, поверх соседей) или первым
// (под соседей) среди детей его родителя: порядок в .dfm - это порядок
// создания и, значит, Z-порядок
function DfmMoveObject(const AText, AName: string; AToFront: Boolean): string;

// Вставка первым ребёнком AParent: после его собственных свойств, перед
// первым вложенным объектом
function DfmInsertObjectFirst(const AText, AParent, AObjText: string): string;

// Модуль AUnit - в uses раздела interface, если его там ещё нет: без
// ExtCtrls в uses строка "Panel1: TPanel;" не соберётся. Уже есть или uses
// не найден - APas.
function PasAddUses(const APas, AUnit: string): string;

// Идентификатор AIdent встречается в тексте как отдельное слово (без учёта
// регистра). Для подбора свободного имени компонента.
function PasHasIdent(const APas, AIdent: string): Boolean;

// Поля компонентов из объявления класса формы AClassName в тексте модуля:
// строки вида "Button1: TButton;". В строке "A, B: TLabel;" убирается
// только нужное имя. Обработчики событий и код не трогаются.
function PasRemoveFields(const APas, AClassName: string;
                         ANames: TStrings): string;

implementation

uses
  TypInfo, Buttons, Menus;

const
  CaretSize = 6;
  GroupMarkSize = 5;
  WM_DSG_FOCUS = WM_USER + 311;

type
  // Перехватчик сообщений контрола на форме конструктора. Кнопки не должны
  // нажиматься, поля - забирать фокус: мышь и клавиатура уходят
  // конструктору. Объект живёт как компонент самого контрола.
  TDsgHook = class(TComponent)
  private
    FDesigner: TFormDesigner;
    FCtl: TWinControl;
    FPrev: TWndMethod;
    procedure WndProc(var Msg: TMessage);
  public
    constructor CreateHook(ACtl: TWinControl; ADesigner: TFormDesigner);
    destructor Destroy; override;
  end;

// Отступ строки пробелами
function LeadSpaces(const S: string): Integer;
begin
  Result := 0;
  while (Result < Length(S)) and (S[Result + 1] = ' ') do
    Inc(Result);
end;

// Строка - заголовок объекта? Имя и класс - в ответе.
function ParseHeader(const ALine: string; var AName, AClass: string): Boolean;
var
  T, U, H: string;
  P: Integer;
begin
  Result := False;
  T := Trim(ALine);
  U := UpperCase(T);
  if not ((Copy(U, 1, 7) = 'OBJECT ') or (Copy(U, 1, 10) = 'INHERITED ') or
          (Copy(U, 1, 7) = 'INLINE ')) then
    Exit;
  H := Trim(Copy(T, Pos(' ', T) + 1, MaxInt));
  P := Pos('[', H);
  if P > 0 then
    H := Trim(Copy(H, 1, P - 1));
  P := Pos(':', H);
  if P > 0 then
  begin
    AName := Trim(Copy(H, 1, P - 1));
    AClass := Trim(Copy(H, P + 1, MaxInt));
  end
  else
  begin
    AName := '';
    AClass := H;
  end;
  Result := True;
end;

// Последний знак строки, #0 у пустой
function LastCh(const S: string): Char;
begin
  if S = '' then
    Result := #0
  else
    Result := S[Length(S)];
end;

// Строка I - свойство: I переводится на последнюю строку его значения.
// Правила те же, что у разбора дерева инспектора (ParseDfmNodes).
procedure SkipDfmValue(SL: TStrings; var I: Integer);
var
  T, V: string;
  P, D: Integer;
begin
  T := Trim(SL[I]);
  P := Pos(' = ', T);
  if P > 0 then
    V := Trim(Copy(T, P + 3, MaxInt))
  else if (Length(T) > 2) and (Copy(T, Length(T) - 1, 2) = ' =') then
  begin
    // Длинная строка: значение начинается со следующей строки
    if I + 1 >= SL.Count then
      Exit;
    Inc(I);
    V := Trim(SL[I]);
  end
  else
    Exit;
  if V = '' then
    Exit;

  case V[1] of
    '(':
      while (LastCh(V) <> ')') and (I + 1 < SL.Count) do
      begin
        Inc(I);
        V := Trim(SL[I]);
      end;
    '{':
      while (LastCh(V) <> '}') and (I + 1 < SL.Count) do
      begin
        Inc(I);
        V := Trim(SL[I]);
      end;
    '<':
      if V <> '<>' then
      begin
        // Коллекция: item ... end внутри, бывают вложенные коллекции.
        // Пустая вложенная (Columns = <>) глубину не меняет.
        D := 1;
        while (D > 0) and (I + 1 < SL.Count) do
        begin
          Inc(I);
          V := Trim(SL[I]);
          if Copy(V, Length(V) - 1, 2) = '<>' then
            // пустая коллекция - ничего
          else if LastCh(V) = '>' then
            Dec(D)
          else if LastCh(V) = '<' then
            Inc(D);
        end;
      end;
  else
    // Строка, склеенная из частей через +
    while (LastCh(V) = '+') and (I + 1 < SL.Count) do
    begin
      Inc(I);
      V := Trim(SL[I]);
    end;
  end;
end;

// Строку end объекта с заголовком в строке AFirst. -1 - текст оборван.
function FindObjectEnd(SL: TStrings; AFirst: Integer): Integer;
var
  I, Depth: Integer;
  T, U: string;
begin
  Result := -1;
  Depth := 1;
  I := AFirst + 1;
  while I < SL.Count do
  begin
    T := Trim(SL[I]);
    U := UpperCase(T);
    if (Copy(U, 1, 7) = 'OBJECT ') or (Copy(U, 1, 10) = 'INHERITED ') or
       (Copy(U, 1, 7) = 'INLINE ') then
      Inc(Depth)
    else if U = 'END' then
    begin
      Dec(Depth);
      if Depth = 0 then
      begin
        Result := I;
        Exit;
      end;
    end
    else
      SkipDfmValue(SL, I);
    Inc(I);
  end;
end;

// Строка заголовка объекта AName, -1 - нет
function FindObjectHeader(SL: TStrings; const AName: string): Integer;
var
  I: Integer;
  Nm, Cl: string;
begin
  Result := -1;
  if AName = '' then
    Exit;
  for I := 0 to SL.Count - 1 do
    if ParseHeader(SL[I], Nm, Cl) and (CompareText(Nm, AName) = 0) then
    begin
      Result := I;
      Exit;
    end;
end;

// SL.Text с тем же концом, что у исходного текста: был без перевода строки
// в конце - и остаётся без него
function TextLike(SL: TStrings; const AOrig: string): string;
var
  I: Integer;
begin
  Result := SL.Text;
  if not ((AOrig <> '') and (AOrig[Length(AOrig)] in [#13, #10])) then
  begin
    I := Length(Result);
    while (I > 0) and (Result[I] in [#13, #10]) do
      Dec(I);
    SetLength(Result, I);
  end;
end;

function DfmObjectRange(const AText, AName: string;
                        var AFirst, ALast: Integer): Boolean;
var
  SL: TStringList;
begin
  Result := False;
  AFirst := -1;
  ALast := -1;
  SL := TStringList.Create;
  try
    SL.Text := AText;
    AFirst := FindObjectHeader(SL, AName);
    if AFirst < 0 then
      Exit;
    ALast := FindObjectEnd(SL, AFirst);
    Result := ALast > AFirst;
  finally
    SL.Free;
  end;
end;

function DfmObjectNames(const AText, AName: string; ANames: TStrings): Boolean;
var
  SL: TStringList;
  I, First, Last: Integer;
  Nm, Cl: string;
begin
  Result := False;
  ANames.Clear;
  SL := TStringList.Create;
  try
    SL.Text := AText;
    First := FindObjectHeader(SL, AName);
    if First < 0 then
      Exit;
    Last := FindObjectEnd(SL, First);
    if Last < 0 then
      Exit;
    I := First;
    while I < Last do
    begin
      if ParseHeader(SL[I], Nm, Cl) then
      begin
        if Nm <> '' then
          ANames.Add(Nm);
      end
      else if UpperCase(Trim(SL[I])) <> 'END' then
        SkipDfmValue(SL, I);
      Inc(I);
    end;
    Result := True;
  finally
    SL.Free;
  end;
end;

function DfmDeleteObject(const AText, AName: string): string;
var
  SL: TStringList;
  I, First, Last: Integer;
begin
  Result := AText;
  SL := TStringList.Create;
  try
    SL.Text := AText;
    First := FindObjectHeader(SL, AName);
    if First <= 0 then
      Exit; // нет объекта; корень формы (строка 0) не удаляется
    Last := FindObjectEnd(SL, First);
    if Last < 0 then
      Exit;
    for I := Last downto First do
      SL.Delete(I);
    Result := TextLike(SL, AText);
  finally
    SL.Free;
  end;
end;

function DfmInsertObject(const AText, AParent, AObjText: string): string;
var
  SL, Obj: TStringList;
  I, First, Last: Integer;
  Pad: string;
begin
  Result := AText;
  SL := TStringList.Create;
  Obj := TStringList.Create;
  try
    SL.Text := AText;
    First := FindObjectHeader(SL, AParent);
    if First < 0 then
      Exit;
    Last := FindObjectEnd(SL, First);
    if Last < 0 then
      Exit;
    Pad := StringOfChar(' ', LeadSpaces(SL[First]) + 2);
    Obj.Text := AObjText;
    for I := Obj.Count - 1 downto 0 do
      if Obj[I] <> '' then
        SL.Insert(Last, Pad + Obj[I]);
    Result := TextLike(SL, AText);
  finally
    Obj.Free;
    SL.Free;
  end;
end;

procedure DsgLog(const S: string; AColor: TColor);
begin
  if Assigned(DsgLogProc) then
    DsgLogProc(S, AColor);
end;

// Имя и класс компонента для журнала
function DsgCompName(C: TComponent): string;
begin
  if C = nil then
    Result := 'nil'
  else
    Result := C.Name + ':' + C.ClassName;
end;

// Строка - идентификатор Паскаля
function IsIdentStr(const S: string): Boolean;
var
  I: Integer;
begin
  Result := (S <> '') and (S[1] in ['A'..'Z', 'a'..'z', '_']);
  if Result then
    for I := 2 to Length(S) do
      if not (S[I] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      begin
        Result := False;
        Exit;
      end;
end;

function DfmRootClass(const AText: string): string;
var
  SL: TStringList;
  I: Integer;
  Nm, Cl: string;
begin
  Result := '';
  SL := TStringList.Create;
  try
    SL.Text := AText;
    for I := 0 to SL.Count - 1 do
      if Trim(SL[I]) <> '' then
      begin
        if ParseHeader(SL[I], Nm, Cl) then
          Result := Cl;
        Exit;
      end;
  finally
    SL.Free;
  end;
end;

function DfmRemoveRefs(const AText: string; ANames: TStrings): string;
var
  SL: TStringList;
  I, P: Integer;
  T, V, Nm, Cl: string;
  Changed: Boolean;
begin
  Result := AText;
  if ANames.Count = 0 then
    Exit;
  Changed := False;
  SL := TStringList.Create;
  try
    SL.Text := AText;
    I := 0;
    while I < SL.Count do
    begin
      T := Trim(SL[I]);
      if ParseHeader(SL[I], Nm, Cl) or (UpperCase(T) = 'END') then
      begin
        Inc(I);
        Continue;
      end;
      P := Pos(' = ', T);
      if P > 0 then
      begin
        V := Trim(Copy(T, P + 3, MaxInt));
        if IsIdentStr(V) and (ANames.IndexOf(V) >= 0) then
        begin
          SL.Delete(I);
          Changed := True;
          Continue;
        end;
      end;
      SkipDfmValue(SL, I);
      Inc(I);
    end;
    if Changed then
      Result := TextLike(SL, AText);
  finally
    SL.Free;
  end;
end;

// Строка объявления класса: "TForm0 = class(TForm)" или "TForm0 = class".
// Опережающее "TForm0 = class;" и "class of" - не оно.
function IsClassDeclLine(const ALine, AClassName: string): Boolean;
var
  T, U: string;
begin
  Result := False;
  T := Trim(ALine);
  if CompareText(Copy(T, 1, Length(AClassName)), AClassName) <> 0 then
    Exit;
  U := UpperCase(Trim(Copy(T, Length(AClassName) + 1, MaxInt)));
  if Copy(U, 1, 1) <> '=' then
    Exit;
  U := Trim(Copy(U, 2, MaxInt));
  if Copy(U, 1, 5) <> 'CLASS' then
    Exit;
  U := Trim(Copy(U, 6, MaxInt));
  Result := (U = '') or (U[1] = '(');
end;

function PasAddField(const APas, AClassName, AName, AType: string): string;
var
  SL: TStringList;
  I, Start, Ins, Ind: Integer;
  T, U, W: string;
begin
  Result := APas;
  SL := TStringList.Create;
  try
    SL.Text := APas;
    Start := -1;
    for I := 0 to SL.Count - 1 do
      if IsClassDeclLine(SL[I], AClassName) then
      begin
        Start := I;
        Break;
      end;
    if Start < 0 then
      Exit;

    // Первая строка, которая уже не поле первой секции
    Ins := -1;
    for I := Start + 1 to SL.Count - 1 do
    begin
      T := Trim(SL[I]);
      if T = '' then
        Continue;
      U := UpperCase(T);
      W := U;
      if Pos(' ', W) > 0 then
        W := Copy(W, 1, Pos(' ', W) - 1);
      if Pos('(', W) > 0 then
        W := Copy(W, 1, Pos('(', W) - 1);
      if Pos(';', W) > 0 then
        W := Copy(W, 1, Pos(';', W) - 1);
      if (W = 'PROCEDURE') or (W = 'FUNCTION') or (W = 'CONSTRUCTOR') or
         (W = 'DESTRUCTOR') or (W = 'PROPERTY') or (W = 'CLASS') or
         (W = 'PRIVATE') or (W = 'PROTECTED') or (W = 'PUBLIC') or
         (W = 'PUBLISHED') or (W = 'END') or (W = 'STRICT') then
      begin
        Ins := I;
        Break;
      end;
    end;
    if Ins < 0 then
      Exit;

    // Отступ - как у первого поля, иначе на шаг глубже объявления класса
    Ind := LeadSpaces(SL[Start]) + 2;
    for I := Start + 1 to Ins - 1 do
      if Trim(SL[I]) <> '' then
      begin
        Ind := LeadSpaces(SL[I]);
        Break;
      end;
    // Пустые строки перед методами остаются под полями
    while (Ins - 1 > Start) and (Trim(SL[Ins - 1]) = '') do
      Dec(Ins);
    SL.Insert(Ins, StringOfChar(' ', Ind) + AName + ': ' + AType + ';');
    Result := TextLike(SL, APas);
  finally
    SL.Free;
  end;
end;

function DfmObjectClass(const AText, AName: string): string;
var
  SL: TStringList;
  I: Integer;
  Nm, Cl: string;
begin
  Result := '';
  SL := TStringList.Create;
  try
    SL.Text := AText;
    I := FindObjectHeader(SL, AName);
    if (I >= 0) and ParseHeader(SL[I], Nm, Cl) then
      Result := Cl;
  finally
    SL.Free;
  end;
end;

function DfmGetProp(const AText, AName, AProp: string): string;
var
  SL: TStringList;
  I, Hdr, Ind: Integer;
  T, Nm, Cl: string;
begin
  Result := '';
  SL := TStringList.Create;
  try
    SL.Text := AText;
    Hdr := FindObjectHeader(SL, AName);
    if Hdr < 0 then
      Exit;
    Ind := LeadSpaces(SL[Hdr]);
    I := Hdr + 1;
    while I < SL.Count do
    begin
      T := Trim(SL[I]);
      if (LeadSpaces(SL[I]) <= Ind) or ParseHeader(SL[I], Nm, Cl) or
         (UpperCase(T) = 'END') then
        Break; // конец своих свойств: end объекта или вложенный объект
      if CompareText(Copy(T, 1, Length(AProp) + 3), AProp + ' = ') = 0 then
      begin
        Result := Trim(Copy(T, Length(AProp) + 4, MaxInt));
        Exit;
      end;
      SkipDfmValue(SL, I);
      Inc(I);
    end;
  finally
    SL.Free;
  end;
end;

// Первое слово строки, прописными: до пробела, скобки, точки с запятой
function FirstWordU(const S: string): string;
var
  I: Integer;
begin
  Result := UpperCase(Trim(S));
  for I := 1 to Length(Result) do
    if Result[I] in [' ', '(', ';', ':', #9] then
    begin
      SetLength(Result, I - 1);
      Exit;
    end;
end;

function PasAddMethod(const APas, AClassName, ADecl: string): string;
var
  SL: TStringList;
  I, Start, Ins, Ind, Impl, Tail: Integer;
  W, Head: string;
begin
  Result := APas;
  SL := TStringList.Create;
  try
    SL.Text := APas;
    Start := -1;
    for I := 0 to SL.Count - 1 do
      if IsClassDeclLine(SL[I], AClassName) then
      begin
        Start := I;
        Break;
      end;
    if Start < 0 then
      Exit;

    // Объявление: конец первой секции класса
    Ins := -1;
    for I := Start + 1 to SL.Count - 1 do
    begin
      W := FirstWordU(SL[I]);
      if (W = 'PRIVATE') or (W = 'PROTECTED') or (W = 'PUBLIC') or
         (W = 'PUBLISHED') or (W = 'STRICT') or (W = 'END') then
      begin
        Ins := I;
        Break;
      end;
    end;
    if Ins < 0 then
      Exit;
    Ind := LeadSpaces(SL[Start]) + 2;
    for I := Start + 1 to Ins - 1 do
      if Trim(SL[I]) <> '' then
      begin
        Ind := LeadSpaces(SL[I]);
        Break;
      end;
    while (Ins - 1 > Start) and (Trim(SL[Ins - 1]) = '') do
      Dec(Ins);
    SL.Insert(Ins, StringOfChar(' ', Ind) + Trim(ADecl));

    // Тело: в конец implementation
    Impl := -1;
    for I := 0 to SL.Count - 1 do
      if FirstWordU(SL[I]) = 'IMPLEMENTATION' then
      begin
        Impl := I;
        Break;
      end;
    if Impl < 0 then
      Exit;
    Tail := -1;
    for I := Impl + 1 to SL.Count - 1 do
    begin
      W := FirstWordU(SL[I]);
      if (W = 'INITIALIZATION') or (W = 'FINALIZATION') then
      begin
        Tail := I;
        Break;
      end;
    end;
    if Tail < 0 then
      for I := SL.Count - 1 downto Impl + 1 do
        if UpperCase(Trim(SL[I])) = 'END.' then
        begin
          Tail := I;
          Break;
        end;
    if Tail < 0 then
      Exit;

    // "procedure Button1Click(...)" -> "procedure TForm0.Button1Click(...)"
    Head := Trim(ADecl);
    I := Pos(' ', Head);
    Head := Copy(Head, 1, I) + AClassName + '.' + Trim(Copy(Head, I + 1, MaxInt));

    while (Tail - 1 > Impl) and (Trim(SL[Tail - 1]) = '') do
      Dec(Tail);
    SL.Insert(Tail, '');
    SL.Insert(Tail + 1, Head);
    SL.Insert(Tail + 2, 'begin');
    SL.Insert(Tail + 3, '');
    SL.Insert(Tail + 4, 'end;');
    // перед initialization / end. остаётся пустая строка
    if (Tail + 5 < SL.Count) and (Trim(SL[Tail + 5]) <> '') then
      SL.Insert(Tail + 5, '');
    Result := TextLike(SL, APas);
  finally
    SL.Free;
  end;
end;

function DfmParentOf(const AText, AName: string): string;
var
  SL: TStringList;
  I, Hdr, Ind: Integer;
  Nm, Cl: string;
begin
  Result := '';
  SL := TStringList.Create;
  try
    SL.Text := AText;
    Hdr := FindObjectHeader(SL, AName);
    if Hdr <= 0 then
      Exit;
    Ind := LeadSpaces(SL[Hdr]);
    for I := Hdr - 1 downto 0 do
      if (LeadSpaces(SL[I]) < Ind) and ParseHeader(SL[I], Nm, Cl) and
         (FindObjectEnd(SL, I) > Hdr) then
      begin
        Result := Nm;
        Exit;
      end;
  finally
    SL.Free;
  end;
end;

function DfmObjectText(const AText, AName: string): string;
var
  SL, Obj: TStringList;
  I, First, Last, Ind: Integer;
begin
  Result := '';
  SL := TStringList.Create;
  Obj := TStringList.Create;
  try
    SL.Text := AText;
    First := FindObjectHeader(SL, AName);
    if First < 0 then
      Exit;
    Last := FindObjectEnd(SL, First);
    if Last < 0 then
      Exit;
    Ind := LeadSpaces(SL[First]);
    for I := First to Last do
      if LeadSpaces(SL[I]) >= Ind then
        Obj.Add(Copy(SL[I], Ind + 1, MaxInt))
      else
        Obj.Add(TrimLeft(SL[I]));
    Result := Obj.Text;
  finally
    Obj.Free;
    SL.Free;
  end;
end;

function DfmInsertObjectFirst(const AText, AParent, AObjText: string): string;
var
  SL, Obj: TStringList;
  I, Hdr, Ins, Ind: Integer;
  Pad, Nm, Cl, T: string;
begin
  Result := AText;
  SL := TStringList.Create;
  Obj := TStringList.Create;
  try
    SL.Text := AText;
    Hdr := FindObjectHeader(SL, AParent);
    if Hdr < 0 then
      Exit;
    Ind := LeadSpaces(SL[Hdr]);
    // Свои свойства родителя - до первого вложенного объекта или end
    Ins := -1;
    I := Hdr + 1;
    while I < SL.Count do
    begin
      T := Trim(SL[I]);
      if ParseHeader(SL[I], Nm, Cl) or
         ((UpperCase(T) = 'END') and (LeadSpaces(SL[I]) <= Ind)) then
      begin
        Ins := I;
        Break;
      end;
      SkipDfmValue(SL, I);
      Inc(I);
    end;
    if Ins < 0 then
      Exit;
    Pad := StringOfChar(' ', Ind + 2);
    Obj.Text := AObjText;
    for I := Obj.Count - 1 downto 0 do
      if Obj[I] <> '' then
        SL.Insert(Ins, Pad + Obj[I]);
    Result := TextLike(SL, AText);
  finally
    Obj.Free;
    SL.Free;
  end;
end;

function DfmMoveObject(const AText, AName: string; AToFront: Boolean): string;
var
  Par, Obj, T: string;
begin
  Result := AText;
  Par := DfmParentOf(AText, AName);
  if Par = '' then
    Exit;
  Obj := DfmObjectText(AText, AName);
  if Obj = '' then
    Exit;
  T := DfmDeleteObject(AText, AName);
  if T = AText then
    Exit;
  if AToFront then
    Result := DfmInsertObject(T, Par, Obj)
  else
    Result := DfmInsertObjectFirst(T, Par, Obj);
  if Result = T then
    Result := AText; // вставка не удалась - ничего не меняем
end;

function PasAddUses(const APas, AUnit: string): string;
var
  SL: TStringList;
  I, U, E, P: Integer;
  W, Code, Tail, Line: string;
  InIface: Boolean;
begin
  Result := APas;
  if AUnit = '' then
    Exit;
  SL := TStringList.Create;
  try
    SL.Text := APas;

    // uses раздела interface
    InIface := False;
    U := -1;
    for I := 0 to SL.Count - 1 do
    begin
      W := FirstWordU(SL[I]);
      if W = 'INTERFACE' then
        InIface := True
      else if W = 'IMPLEMENTATION' then
        Break
      else if InIface and (W = 'USES') then
      begin
        U := I;
        Break;
      end;
    end;
    if U < 0 then
      Exit;

    // Конец списка - строка с точкой с запятой (не в комментарии)
    E := -1;
    for I := U to SL.Count - 1 do
    begin
      Code := SL[I];
      P := Pos('//', Code);
      if P > 0 then
        Code := Copy(Code, 1, P - 1);
      if Pos(';', Code) > 0 then
      begin
        E := I;
        Break;
      end;
    end;
    if E < 0 then
      Exit;

    // Уже в списке?
    Code := '';
    for I := U to E do
    begin
      Line := SL[I];
      P := Pos('//', Line);
      if P > 0 then
        Line := Copy(Line, 1, P - 1);
      Code := Code + ' ' + Line;
    end;
    if PasHasIdent(Code, AUnit) then
      Exit;

    // Перед точкой с запятой; длинную строку продолжаем новой
    Line := SL[E];
    P := Pos('//', Line);
    if P > 0 then
    begin
      Code := Copy(Line, 1, P - 1);
      Tail := Copy(Line, P, MaxInt);
    end
    else
    begin
      Code := Line;
      Tail := '';
    end;
    P := LastDelimiter(';', Code);
    if Length(TrimRight(Copy(Code, 1, P - 1))) + Length(AUnit) + 2 > 76 then
    begin
      SL[E] := TrimRight(Copy(Code, 1, P - 1)) + ',' + Copy(Code, P + 1, MaxInt) +
               Tail;
      SL.Insert(E + 1, '  ' + AUnit + ';');
    end
    else
      SL[E] := TrimRight(Copy(Code, 1, P - 1)) + ', ' + AUnit + ';' +
               Copy(Code, P + 1, MaxInt) + Tail;
    Result := TextLike(SL, APas);
  finally
    SL.Free;
  end;
end;

function PasHasIdent(const APas, AIdent: string): Boolean;
var
  U, W: string;
  P, L, From: Integer;
begin
  Result := False;
  if AIdent = '' then
    Exit;
  U := UpperCase(APas);
  W := UpperCase(AIdent);
  L := Length(W);
  From := 1;
  repeat
    P := Pos(W, Copy(U, From, MaxInt));
    if P = 0 then
      Exit;
    P := P + From - 1;
    if ((P = 1) or not (U[P - 1] in ['A'..'Z', '0'..'9', '_'])) and
       ((P + L > Length(U)) or not (U[P + L] in ['A'..'Z', '0'..'9', '_'])) then
    begin
      Result := True;
      Exit;
    end;
    From := P + 1;
  until False;
end;

function PasRemoveFields(const APas, AClassName: string;
                         ANames: TStrings): string;
var
  SL, Ids: TStringList;
  I, K, P, Start: Integer;
  T, U, Code, Tail, Left, Right, Pad, S: string;
  Ok, Changed: Boolean;
begin
  Result := APas;
  if (AClassName = '') or (ANames.Count = 0) then
    Exit;
  Changed := False;
  SL := TStringList.Create;
  Ids := TStringList.Create;
  try
    SL.Text := APas;
    Start := -1;
    for I := 0 to SL.Count - 1 do
      if IsClassDeclLine(SL[I], AClassName) then
      begin
        Start := I;
        Break;
      end;
    if Start < 0 then
      Exit;

    I := Start + 1;
    while I < SL.Count do
    begin
      T := Trim(SL[I]);
      U := UpperCase(T);
      // Конец объявления класса
      if (U = 'END') or (Copy(U, 1, 4) = 'END;') then
        Break;

      // Поле: "Имя1, Имя2: Тип;" и, может быть, комментарий //
      P := Pos('//', T);
      if P > 0 then
      begin
        Code := Trim(Copy(T, 1, P - 1));
        Tail := Copy(T, P, MaxInt);
      end
      else
      begin
        Code := T;
        Tail := '';
      end;
      P := Pos(':', Code);
      Ok := P > 0;
      if Ok then
      begin
        Left := Trim(Copy(Code, 1, P - 1));
        Right := Trim(Copy(Code, P + 1, MaxInt));
        // Тип - одно имя, можно с модулем через точку: StdCtrls.TButton
        S := Right;
        Ok := (S <> '') and (S[Length(S)] = ';');
        if Ok then
        begin
          S := Trim(Copy(S, 1, Length(S) - 1));
          Ok := S <> '';
          for K := 1 to Length(S) do
            if not (S[K] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '.']) then
              Ok := False;
        end;
        if Ok then
        begin
          Ids.Clear;
          S := Left;
          repeat
            P := Pos(',', S);
            if P > 0 then
            begin
              Ids.Add(Trim(Copy(S, 1, P - 1)));
              Delete(S, 1, P);
            end
            else
              Ids.Add(Trim(S));
          until P = 0;
          for K := 0 to Ids.Count - 1 do
            if not IsIdentStr(Ids[K]) then
              Ok := False;
        end;
      end;

      if Ok then
      begin
        P := Ids.Count;
        for K := Ids.Count - 1 downto 0 do
          if ANames.IndexOf(Ids[K]) >= 0 then
            Ids.Delete(K);
        if Ids.Count <> P then
        begin
          Changed := True;
          if Ids.Count = 0 then
          begin
            SL.Delete(I);
            Continue;
          end;
          Pad := StringOfChar(' ', LeadSpaces(SL[I]));
          S := Ids[0];
          for K := 1 to Ids.Count - 1 do
            S := S + ', ' + Ids[K];
          S := Pad + S + ': ' + Right;
          if Tail <> '' then
            S := S + ' ' + Tail;
          SL[I] := S;
        end;
      end;
      Inc(I);
    end;

    if Changed then
      Result := TextLike(SL, APas);
  finally
    Ids.Free;
    SL.Free;
  end;
end;

function DfmSetProps(const AText, AName: string; AProps: TStrings): string;
var
  SL: TStringList;
  I, J, K, Hdr, Ind, Lead: Integer;
  Nm, Cl, PName, PVal, T, U, Pad: string;
  OnlyIfExists, Found, EndsWithBreak: Boolean;
begin
  Result := AText;
  // Без имени объект в тексте не найти: под пустое имя подошёл бы любой
  // заголовок object, и свойство ушло бы в чужой объект
  if AName = '' then
    Exit;
  SL := TStringList.Create;
  try
    SL.Text := AText;

    Hdr := -1;
    for I := 0 to SL.Count - 1 do
      if ParseHeader(SL[I], Nm, Cl) and (CompareText(Nm, AName) = 0) then
      begin
        Hdr := I;
        Break;
      end;
    if Hdr < 0 then
      Exit;

    Ind := LeadSpaces(SL[Hdr]);
    Pad := StringOfChar(' ', Ind + 2);

    for K := 0 to AProps.Count - 1 do
    begin
      PName := AProps.Names[K];
      PVal := Copy(AProps[K], Length(PName) + 2, MaxInt);
      OnlyIfExists := (PName <> '') and (PName[1] = '?');
      if OnlyIfExists then
        Delete(PName, 1, 1);
      if PName = '' then
        Continue;

      // Свои свойства объекта - строки с отступом ровно на шаг глубже
      // заголовка и до первого вложенного объекта. Глубже - продолжения
      // многострочных значений; на уровне заголовка - его end.
      Found := False;
      J := Hdr + 1;
      while J < SL.Count do
      begin
        Lead := LeadSpaces(SL[J]);
        if Lead <= Ind then
          Break;
        if Lead = Ind + 2 then
        begin
          T := Trim(SL[J]);
          U := UpperCase(T);
          if (Copy(U, 1, 7) = 'OBJECT ') or (Copy(U, 1, 10) = 'INHERITED ') or
             (Copy(U, 1, 7) = 'INLINE ') then
            Break;
          if CompareText(Copy(T, 1, Length(PName) + 3), PName + ' = ') = 0 then
          begin
            SL[J] := Pad + PName + ' = ' + PVal;
            Found := True;
            Break;
          end;
        end;
        Inc(J);
      end;

      // Нового свойства не было - в конец своих свойств объекта (J -
      // вложенный объект или end), как пишет Delphi: события после свойств
      if not Found and not OnlyIfExists then
        SL.Insert(J, Pad + PName + ' = ' + PVal);
    end;

    EndsWithBreak := (AText <> '') and (AText[Length(AText)] in [#13, #10]);
    Result := SL.Text;
    if not EndsWithBreak then
    begin
      I := Length(Result);
      while (I > 0) and (Result[I] in [#13, #10]) do
        Dec(I);
      SetLength(Result, I);
    end;
  finally
    SL.Free;
  end;
end;

{ TDsgHook }

constructor TDsgHook.CreateHook(ACtl: TWinControl; ADesigner: TFormDesigner);
begin
  inherited Create(ACtl);
  FCtl := ACtl;
  FDesigner := ADesigner;
  FPrev := ACtl.WindowProc;
  ACtl.WindowProc := WndProc;
end;

destructor TDsgHook.Destroy;
begin
  if (FCtl <> nil) and Assigned(FPrev) then
    FCtl.WindowProc := FPrev;
  inherited;
end;

// Клавиши, которые конструктор забирает себе раньше горячих клавиш меню
// главного окна. Ctrl+Z там - откат редактора: VCL разбирает горячие
// клавиши меню в TApplication.ProcessMessage (IsKeyMsg: CN_KEYDOWN, затем
// CM_APPKEYDOWN к главной форме), и WM_KEYDOWN до окна конструктора уже не
// доходит. Delete в меню без горячей клавиши, но берём и его здесь, чтобы
// обе клавиши шли одним путём.
function DsgOwnKey(AKey: Word): Boolean;
var
  Ctrl, Shift: Boolean;
begin
  Ctrl := GetKeyState(VK_CONTROL) < 0;
  Shift := GetKeyState(VK_SHIFT) < 0;
  Result := ((AKey = Ord('Z')) and Ctrl and not Shift) or
            ((AKey = Ord('C')) and Ctrl and not Shift) or
            ((AKey = Ord('X')) and Ctrl and not Shift) or
            ((AKey = Ord('V')) and Ctrl and not Shift) or
            ((AKey = VK_DELETE) and not Ctrl and not Shift);
end;

// Компонент под точкой APt (в координатах AParent) - самый глубокий,
// включая отключённые оконные. Отключённое окно (Enabled = False) мышиных
// сообщений не получает, щелчок по нему приходит родителю, и без спуска
// вглубь выделялся бы родитель, а не GroupBox2 и не метки внутри него.
// В конструкторе Delphi отключённые компоненты тоже выделяются.
function DeepTarget(AParent: TWinControl; APt: TPoint): TControl;
var
  C: TControl;
  W: TWinControl;
  P: TPoint;
begin
  Result := AParent;
  W := AParent;
  P := APt;
  repeat
    C := W.ControlAtPos(P, True, True);
    if C = nil then
      Break;
    Result := C;
    if not (C is TWinControl) then
      Break;
    // Точка - в координаты найденного и ищем уже в нём
    P := TWinControl(C).ScreenToClient(W.ClientToScreen(P));
    W := TWinControl(C);
  until False;
end;

// Есть ли у контрола перехватчик: TDsgHook создаётся с владельцем - самим
// контролом
function HasDsgHook(ACtl: TWinControl): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to ACtl.ComponentCount - 1 do
    if ACtl.Components[I] is TDsgHook then
    begin
      Result := True;
      Exit;
    end;
end;

// Перехватчики всем оконным контролам дерева, у которых их ещё нет
procedure HookInner(AParent: TWinControl; ADesigner: TFormDesigner);
var
  I: Integer;
  C: TControl;
begin
  for I := 0 to AParent.ControlCount - 1 do
  begin
    C := AParent.Controls[I];
    // Значок невизуального (TDsgIcon) мышь обрабатывает сам: выделяет свой
    // компонент (TTimer) и пишет его место в DesignInfo. С перехватчиком
    // щелчок шёл бы конструктору, выделялся бы безымянный значок - без
    // узла в инспекторе и без записи места в .dfm.
    if not (C is TWinControl) or (C is TDsgIcon) then
      Continue;
    if not HasDsgHook(TWinControl(C)) then
      TDsgHook.CreateHook(TWinControl(C), ADesigner);
    HookInner(TWinControl(C), ADesigner);
  end;
end;

function TFormDesigner.TargetAt(const AScreen: TPoint): TControl;
begin
  Result := FForm;
  if FForm = nil then
    Exit;
  Result := DeepTarget(FForm, FForm.ScreenToClient(AScreen));
  // Внутренний контрол - к ближайшему предку, которым владеет форма
  while (Result <> nil) and (Result <> FForm) and (Result.Owner <> FForm) do
    Result := Result.Parent;
  if Result = nil then
    Result := FForm;
end;

procedure TDsgHook.WndProc(var Msg: TMessage);
var
  Pt: TPoint;
  Target: TControl;
  IsRoot: Boolean;
  OldPage: Integer;
begin
  IsRoot := FCtl = FDesigner.Form;

  case Msg.Msg of
    // Правый щелчок: выделить компонент под курсором и показать меню
    // конструктора. Своё контекстное меню контролов (у TMemo, TEdit) не
    // показываем.
    WM_RBUTTONDOWN:
      Exit;
    WM_RBUTTONUP:
      begin
        Pt := Point(SmallInt(LoWord(Msg.LParam)), SmallInt(HiWord(Msg.LParam)));
        Target := FDesigner.TargetAt(FCtl.ClientToScreen(Pt));
        FDesigner.ContextMenu(Target, FCtl.ClientToScreen(Pt));
        Exit;
      end;
    WM_CONTEXTMENU:
      Exit;

    WM_PAINT:
      begin
        FPrev(Msg);
        if FDesigner.IsRuntime(FCtl) then
          FDesigner.MarkRuntime(FCtl)
        else if not IsRoot then
          FDesigner.MarkBorderless(FCtl);
        FDesigner.MarkInvisibleKids(FCtl);
        FDesigner.MarkHidden(FCtl);
        Exit;
      end;

    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK:
      begin
        Pt := Point(SmallInt(LoWord(Msg.LParam)), SmallInt(HiWord(Msg.LParam)));
        // Щелчок по TLabel, TSpeedButton и другим безоконным приходит их
        // родителю - компонент ищем по точке. От корня формы, а не от
        // окна, получившего щелчок: над отключённой кнопкой щелчок
        // получает окно ПОД ней (Windows отключённые окна пропускает),
        // например кнопка соседнего TRadioGroup.
        Target := FDesigner.TargetAt(FCtl.ClientToScreen(Pt));
        SetCapture(FCtl.Handle);
        FDesigner.MouseDown(Target, FCtl.ClientToScreen(Pt));
        if Msg.Msg = WM_LBUTTONDBLCLK then
        begin
          FDesigner.DblClick;
          Exit;
        end;
        // Вкладки переключаются и в конструкторе - как у Delphi: иначе до
        // компонентов на других страницах не добраться
        if (FCtl is TPageControl) and (Target = FCtl) and
           (TPageControl(FCtl).IndexOfTabAt(Pt.X, Pt.Y) >= 0) then
        begin
          ReleaseCapture;
          OldPage := TPageControl(FCtl).ActivePageIndex;
          FPrev(Msg);
          // Вкладка сменилась внутри FPrev (TCN_SELCHANGE обрабатывается
          // сразу) - сообщить: видимость компонентов по вкладке
          if (TPageControl(FCtl).ActivePageIndex <> OldPage) and
             Assigned(FDesigner.FOnPageChange) then
            FDesigner.FOnPageChange(FCtl.Name,
                                    TPageControl(FCtl).ActivePageIndex);
        end;
        // TTabControl - так же; какие компоненты на открытой вкладке,
        // задано SetTabMembers
        if (FCtl is TTabControl) and (Target = FCtl) and
           (TTabControl(FCtl).IndexOfTabAt(Pt.X, Pt.Y) >= 0) then
        begin
          ReleaseCapture;
          OldPage := TTabControl(FCtl).TabIndex;
          FPrev(Msg);
          if TTabControl(FCtl).TabIndex <> OldPage then
            FDesigner.ApplyTabMembers(TTabControl(FCtl));
        end;
        Exit;
      end;

    WM_MOUSEMOVE:
      begin
        if FDesigner.Dragging then
        begin
          Pt := Point(SmallInt(LoWord(Msg.LParam)),
                      SmallInt(HiWord(Msg.LParam)));
          FDesigner.MouseMove(FCtl.ClientToScreen(Pt));
        end;
        Exit;
      end;

    WM_LBUTTONUP:
      begin
        if GetCapture = FCtl.Handle then
          ReleaseCapture;
        FDesigner.MouseUp;
        Exit;
      end;

    // Правая кнопка и контекстное меню разобраны выше
    WM_RBUTTONDBLCLK, WM_MBUTTONDOWN, WM_MBUTTONUP, WM_MBUTTONDBLCLK:
      Exit;

    // Строка меню формы: в конструкторе меню не раскрывается - щелчок
    // выделяет пункт в инспекторе, как в Delphi
    WM_NCLBUTTONDOWN, WM_NCLBUTTONDBLCLK:
      if IsRoot and (Msg.WParam = HTMENU) then
      begin
        FDesigner.MenuBarClick(Point(SmallInt(LoWord(Msg.LParam)),
                                     SmallInt(HiWord(Msg.LParam))));
        Exit;
      end;

    // Alt и F10 тоже раскрыли бы меню формы
    WM_SYSCOMMAND:
      if IsRoot and ((Msg.WParam and $FFF0) = SC_KEYMENU) then
        Exit;

    CN_KEYDOWN:
      // Приходит от IsKeyMsg до разбора горячих клавиш меню. Result = 1 -
      // клавиша обработана: ни меню главного окна, ни WM_KEYDOWN её не
      // получат. Остальные клавиши (Ctrl+S и т. д.) идут в меню как обычно.
      if DsgOwnKey(Msg.WParam) then
      begin
        FDesigner.KeyDown(Msg.WParam);
        Msg.Result := 1;
        Exit;
      end;

    WM_KEYDOWN:
      begin
        FDesigner.KeyDown(Msg.WParam);
        Exit;
      end;

    WM_CHAR, WM_KEYUP:
      Exit;

    WM_SETFOCUS:
      // Фокус у контрола на форме конструктора - это мигающая каретка в
      // поле и перехваченные клавиши. Возвращаем его форме, но не прямо из
      // обработчика фокуса, а следом, сообщением. Пока форма забирает
      // фокус (FRefocusing), ответный WM_SETFOCUS контрола не учитываем,
      // иначе пара WM_SETFOCUS - WM_DSG_FOCUS идёт по кругу.
      if not IsRoot and not FDesigner.FRefocusing then
        PostMessage(FDesigner.Form.Handle, WM_DSG_FOCUS, 0, 0);

    WM_DSG_FOCUS:
      if IsRoot then
      begin
        FDesigner.FRefocusing := True;
        try
          FDesigner.Form.ActiveControl := nil;
          Windows.SetFocus(FCtl.Handle);
        finally
          FDesigner.FRefocusing := False;
        end;
        Exit;
      end;

    WM_ERASEBKGND:
      if IsRoot then
      begin
        FPrev(Msg);
        FDesigner.PaintGrid(HDC(Msg.WParam));
        Exit;
      end;

    WM_EXITSIZEMOVE:
      if IsRoot then
      begin
        FPrev(Msg);
        FDesigner.FormMoved;
        Exit;
      end;

    WM_SIZE:
      // Размер формы поменялся - выровненные компоненты (alRight,
      // alClient) встали по-новому. Раскладка делается внутри обработки
      // WM_SIZE (Realign), поэтому маркеры - после неё. Маркеры в
      // раскладке формы не участвуют и сами за компонентом не едут.
      if IsRoot then
      begin
        FPrev(Msg);
        if ((FDesigner.FCarets[1] <> nil) and FDesigner.FCarets[1].Visible) or
           (FDesigner.GroupCount > 1) then
          FDesigner.ShowCarets;
        Exit;
      end;
  end;

  FPrev(Msg);
end;

// Место компонента - в пределах клиентской области родителя: перетаскивание
// и маркеры не уводят его за край, где его уже не зацепить мышью (Left =
// -232 под соседним компонентом). AParent - родитель, R - новое место в его
// координатах. Растягивание (AResize) обрезает стороны по краю; перенос
// сдвигает целиком, размер не меняется. Компонент больше родителя стоит от
// левого (верхнего) края.
procedure ClampToParent(AParent: TWinControl; var R: TRect; AResize: Boolean);
var
  PW, PH, W, H: Integer;
begin
  if AParent = nil then
    Exit;
  PW := AParent.ClientWidth;
  PH := AParent.ClientHeight;
  if AResize then
  begin
    if R.Left < 0 then
      R.Left := 0;
    if R.Top < 0 then
      R.Top := 0;
    if R.Right > PW then
      R.Right := PW;
    if R.Bottom > PH then
      R.Bottom := PH;
    Exit;
  end;
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  if R.Left > PW - W then
    R.Left := PW - W;
  if R.Top > PH - H then
    R.Top := PH - H;
  if R.Left < 0 then
    R.Left := 0;
  if R.Top < 0 then
    R.Top := 0;
  R.Right := R.Left + W;
  R.Bottom := R.Top + H;
end;

{ TDsgCaret }

constructor TDsgCaret.CreateCaret(AOwner: TComponent; ADesigner: TFormDesigner;
                                  AIndex: Integer);
begin
  inherited Create(AOwner);
  FDesigner := ADesigner;
  FIndex := AIndex;
  Width := CaretSize;
  Height := CaretSize;
  Visible := False;
  case AIndex of
    1, 5: Cursor := crSizeNWSE;
    3, 7: Cursor := crSizeNESW;
    2, 6: Cursor := crSizeWE;
  else
    Cursor := crSizeNS;
  end;
end;

procedure TDsgCaret.Paint;
begin
  Canvas.Brush.Color := DsgCaretColor;
  Canvas.FillRect(ClientRect);
end;

procedure TFormDesigner.RepaintCarets;
var
  I: Integer;
begin
  for I := Low(FCarets) to High(FCarets) do
    if FCarets[I] <> nil then
      FCarets[I].Invalidate;
  if FGroupMarks <> nil then
    for I := 0 to FGroupMarks.Count - 1 do
      TControl(FGroupMarks[I]).Invalidate;
end;

{ TDsgGroupMark }

procedure TDsgGroupMark.Paint;
begin
  Canvas.Brush.Color := DsgGroupColor;
  Canvas.FillRect(ClientRect);
end;

// Можно ли тянуть этот маркер. Компонент из кода - нет: его размер
// задаёт код. Выровненный - только за свободную сторону, как в Delphi:
// alTop - нижний средний маркер (высота), alBottom - верхний средний,
// alLeft - правый средний (ширина), alRight - левый средний. Остальные
// стороны у него задаёт родитель. alClient - никак.
function TDsgCaret.CanDrag: Boolean;
var
  C: TControl;
  Code: string;
begin
  Result := False;
  C := FDesigner.SelControl;
  if (C = nil) or FDesigner.IsRuntime(C) then
    Exit;
  // Координаты, которые задаёт код: левая сторона меняет Left и Width,
  // правая - Width, верхняя - Top и Height, нижняя - Height
  Code := FDesigner.CodePlacedSides(C);
  if (FIndex in [1, 2, 3]) and ((Pos('L', Code) > 0) or (Pos('W', Code) > 0)) then
    Exit;
  if (FIndex in [5, 6, 7]) and (Pos('W', Code) > 0) then
    Exit;
  if (FIndex in [1, 7, 8]) and ((Pos('T', Code) > 0) or (Pos('H', Code) > 0)) then
    Exit;
  if (FIndex in [3, 4, 5]) and (Pos('H', Code) > 0) then
    Exit;
  case C.Align of
    alNone:   Result := True;
    alTop:    Result := FIndex = 4;
    alBottom: Result := FIndex = 8;
    alLeft:   Result := FIndex = 6;
    alRight:  Result := FIndex = 2;
  end;
end;

// Курсор ставим сами: окно маркера - без родителя-контрола (ParentWindow),
// и курсор не должен обещать то, чего сделать нельзя - у маркера, который
// не тянется, обычная стрелка.
procedure TDsgCaret.WMSetCursor(var Message: TWMSetCursor);
begin
  if Message.HitTest = HTCLIENT then
  begin
    if CanDrag then
      Windows.SetCursor(Screen.Cursors[Cursor])
    else
      Windows.SetCursor(Screen.Cursors[crArrow]);
    Message.Result := 1;
    Exit;
  end;
  inherited;
end;

procedure TDsgCaret.MouseDown(Button: TMouseButton; Shift: TShiftState;
                              X, Y: Integer);
var
  C: TControl;
begin
  if Button <> mbLeft then
    Exit;
  C := FDesigner.SelControl;
  if (C = nil) or not CanDrag then
    Exit;
  FActive := True;
  FFrom := ClientToScreen(Point(X, Y));
  FRect := C.BoundsRect;
end;

// Правила из MouseResizeObject: какой маркер какую сторону тянет. Край
// встаёт на сетку; меньше 4 пикселей компонент не сжимается.
procedure TDsgCaret.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  C: TControl;
  P: TPoint;
  R: TRect;
  DX, DY: Integer;
begin
  if not FActive then
    Exit;
  C := FDesigner.SelControl;
  if C = nil then
    Exit;

  P := ClientToScreen(Point(X, Y));
  DX := P.X - FFrom.X;
  DY := P.Y - FFrom.Y;
  R := FRect;

  if FIndex in [1, 2, 3] then
    R.Left := FDesigner.Snap(FRect.Left + DX);
  if FIndex in [5, 6, 7] then
    R.Right := FDesigner.Snap(FRect.Right + DX);
  if FIndex in [1, 7, 8] then
    R.Top := FDesigner.Snap(FRect.Top + DY);
  if FIndex in [3, 4, 5] then
    R.Bottom := FDesigner.Snap(FRect.Bottom + DY);

  if R.Right - R.Left < 4 then
    if FIndex in [1, 2, 3] then
      R.Left := R.Right - 4
    else
      R.Right := R.Left + 4;
  if R.Bottom - R.Top < 4 then
    if FIndex in [1, 7, 8] then
      R.Top := R.Bottom - 4
    else
      R.Bottom := R.Top + 4;

  ClampToParent(C.Parent, R, True);
  // Обрезка по краю не должна сжать меньше 4 пикселей
  if (R.Right - R.Left >= 4) and (R.Bottom - R.Top >= 4) then
    C.BoundsRect := R;
  FDesigner.ShowCarets;
end;

procedure TDsgCaret.MouseUp(Button: TMouseButton; Shift: TShiftState;
                            X, Y: Integer);
var
  C: TControl;
begin
  if not FActive then
    Exit;
  FActive := False;
  C := FDesigner.SelControl;
  if (C <> nil) and not EqualRect(C.BoundsRect, FRect) then
    FDesigner.CommitBounds(C);
end;

{ TDsgIcon }

procedure TDsgIcon.Paint;
var
  R: TRect;
  S: string;
begin
  R := ClientRect;
  if FDesigner.FSel = FComp then
    Canvas.Brush.Color := $00FFE0C0
  else
    Canvas.Brush.Color := clWindow;
  Canvas.Pen.Color := clGray;
  Canvas.Rectangle(R);
  // Имя класса без T - как подпись у значка Delphi
  S := FClassName;
  if (Length(S) > 1) and (S[1] = 'T') then
    Delete(S, 1, 1);
  Canvas.Font.Height := -9;
  InflateRect(R, -1, -1);
  DrawText(Canvas.Handle, PChar(S), Length(S), R,
           DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
end;

procedure TDsgIcon.MouseDown(Button: TMouseButton; Shift: TShiftState;
                             X, Y: Integer);
begin
  if Button = mbRight then
  begin
    FDesigner.ContextMenu(FComp, ClientToScreen(Point(X, Y)));
    Exit;
  end;
  if Button <> mbLeft then
    Exit;
  // Shift+щелчок - значок в группу или из группы (главный - визуальный
  // компонент); место в группе пишется в DesignInfo (CommitGroup)
  if (ssShift in Shift) and (FDesigner.SelControl <> nil) and
     not FDesigner.IsRuntime(FDesigner.SelControl) then
  begin
    FDesigner.ToggleGroup(Self);
    Exit;
  end;
  FDesigner.Select(FComp, True);
  FActive := True;
  FMoved := False;
  FFrom := ClientToScreen(Point(X, Y));
  FStart := Point(Left, Top);
end;

procedure TDsgIcon.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
  R: TRect;
begin
  if not FActive then
    Exit;
  P := ClientToScreen(Point(X, Y));
  if not FMoved and (Abs(P.X - FFrom.X) < 3) and (Abs(P.Y - FFrom.Y) < 3) then
    Exit;
  FMoved := True;
  // Значок - в пределах формы
  R.Left := FDesigner.Snap(FStart.X + P.X - FFrom.X);
  R.Top := FDesigner.Snap(FStart.Y + P.Y - FFrom.Y);
  R.Right := R.Left + Width;
  R.Bottom := R.Top + Height;
  ClampToParent(Parent, R, False);
  SetBounds(R.Left, R.Top, Width, Height);
end;

procedure TDsgIcon.MouseUp(Button: TMouseButton; Shift: TShiftState;
                           X, Y: Integer);
begin
  if not FActive then
    Exit;
  FActive := False;
  if FMoved then
  begin
    // У невизуального компонента место на форме - DesignInfo
    FComp.DesignInfo := MakeLong(Word(Left), Word(Top));
    FDesigner.CommitBounds(FComp);
  end;
end;

{ TFormDesigner }

constructor TFormDesigner.Create;
begin
  inherited Create;
  FGrid := 8;   // как у Delphi: формы, сделанные в ней, выровнены по 8
  FClassOf := TStringList.Create;
  FVisualUnknown := TStringList.Create;
  FVisualUnknown.Sorted := True;
  FVisualUnknown.Duplicates := dupIgnore;
  FRuntime := TList.Create;
  FCodePlaced := TStringList.Create;
  FGroup := TList.Create;
  FGroupMarks := TList.Create;
  FAlignOff := TList.Create;
  FHidden := TList.Create;
  FPageRules := TStringList.Create;
  FTabMembers := TStringList.Create;
end;

destructor TFormDesigner.Destroy;
begin
  Clear;
  FTabMembers.Free;
  FPageRules.Free;
  FHidden.Free;
  FRuntime.Free;
  FCodePlaced.Free;
  FGroup.Free;
  FGroupMarks.Free;
  FAlignOff.Free;
  FVisualUnknown.Free;
  FClassOf.Free;
  inherited;
end;

procedure TFormDesigner.Clear;
var
  I: Integer;
begin
  FSel := nil;
  FDragging := False;
  FDragCtl := nil;
  if FRuntime <> nil then
    FRuntime.Clear;      // сами компоненты принадлежат форме
  if FCodePlaced <> nil then
    FCodePlaced.Clear;
  if FGroup <> nil then
    FGroup.Clear;
  if FGroupMarks <> nil then
    FGroupMarks.Clear;   // окошки принадлежат форме, уйдут вместе с ней
  FGroupDrag := False;
  if FHidden <> nil then
    FHidden.Clear;
  if FPageRules <> nil then
  begin
    for I := 0 to FPageRules.Count - 1 do
      FPageRules.Objects[I].Free;
    FPageRules.Clear;
  end;
  if FTabMembers <> nil then
  begin
    for I := 0 to FTabMembers.Count - 1 do
      FTabMembers.Objects[I].Free;
    FTabMembers.Clear;
  end;
  for I := 1 to 8 do
    FCarets[I] := nil;   // принадлежат форме, уйдут вместе с ней
  if FForm <> nil then
  begin
    FForm.OnClose := nil;
    FreeAndNil(FForm);
  end;
end;

function TFormDesigner.Snap(V: Integer): Integer;
begin
  if FGrid > 1 then
    Result := Round(V / FGrid) * FGrid
  else
    Result := V;
end;

// Текст перед чтением. Имена и классы всех объектов - в FClassOf; классы,
// которых в редакторе нет, но у которых есть Width, - визуальные (им
// заглушка-панель, прочим - значок). У самой формы убираются свойства,
// которые мешают показать её окном конструктора: MDI-дочерняя форма без
// MDI-родителя не создастся, развёрнутая - закроет экран.
function TFormDesigner.PrepareText(const AText: string): string;
var
  SL: TStringList;
  I, Depth, Lead: Integer;
  Nm, Cl, T: string;
  Stack: TStringList;
begin
  FClassOf.Clear;
  FVisualUnknown.Clear;
  FRootName := '';

  SL := TStringList.Create;
  Stack := TStringList.Create;
  try
    SL.Text := AText;
    Depth := 0;
    I := 0;
    while I < SL.Count do
    begin
      T := Trim(SL[I]);
      if ParseHeader(SL[I], Nm, Cl) then
      begin
        if FRootName = '' then
          FRootName := Nm;
        FClassOf.Values[Nm] := Cl;
        Stack.Add(Cl);
        Inc(Depth);
      end
      // Элемент коллекции (item ... end) - тоже уровень, но без класса:
      // иначе его end снял бы со стека объект
      else if UpperCase(T) = 'ITEM' then
        Stack.Add('')
      else if (UpperCase(T) = 'END') or (UpperCase(T) = 'END>') then
      begin
        if Stack.Count > 0 then
        begin
          if Stack[Stack.Count - 1] <> '' then
            Dec(Depth);
          Stack.Delete(Stack.Count - 1);
        end;
      end
      else if Stack.Count > 0 then
      begin
        // Width у объекта - признак визуального компонента
        if (Copy(T, 1, 8) = 'Width = ') and (Stack[Stack.Count - 1] <> '') and
           (GetClass(Stack[Stack.Count - 1]) = nil) then
          FVisualUnknown.Add(Stack[Stack.Count - 1]);

        if Depth = 1 then
        begin
          Lead := LeadSpaces(SL[I]);
          if (Lead = 2) and ((Copy(T, 1, 12) = 'FormStyle = ') or
                             (Copy(T, 1, 10) = 'Visible = ') or
                             (Copy(T, 1, 14) = 'WindowState = ')) then
          begin
            SL.Delete(I);
            Continue;
          end;
        end;
      end;
      Inc(I);
    end;
    Result := SL.Text;
  finally
    Stack.Free;
    SL.Free;
  end;
end;

procedure TFormDesigner.ReaderFindClass(Reader: TReader; const ClassName: string;
                                        var ComponentClass: TComponentClass);
var
  C: TPersistentClass;
begin
  if ComponentClass <> nil then
    Exit;
  C := GetClass(ClassName);
  if (C <> nil) and C.InheritsFrom(TComponent) then
    ComponentClass := TComponentClass(C)
  else if FVisualUnknown.IndexOf(ClassName) >= 0 then
    ComponentClass := TDsgStub
  else
    ComponentClass := TDsgNonVisual;
end;

// Обработчиков событий в редакторе нет - ссылки на них пропускаем
procedure TFormDesigner.ReaderFindMethod(Reader: TReader;
                                         const MethodName: string;
                                         var Address: Pointer;
                                         var Error: Boolean);
begin
  Address := nil;
  Error := False;
end;

// Свойства, которых у заглушки нет, - тоже пропускаем
procedure TFormDesigner.ReaderError(Reader: TReader; const Message: string;
                                    var Handled: Boolean);
begin
  Handled := True;
end;

function TFormDesigner.Load(const ADfmText: string; var AError: string): Boolean;
var
  Src: TStringStream;
  Bin: TMemoryStream;
  R: TReader;
  OldSel: string;
begin
  Result := False;
  AError := '';
  OldSel := SelectedName;
  Clear;

  Src := TStringStream.Create(PrepareText(ADfmText));
  Bin := TMemoryStream.Create;
  try
    try
      ObjectTextToBinary(Src, Bin);
      Bin.Position := 0;
      FForm := TForm.CreateNew(nil);
      R := TReader.Create(Bin, 4096);
      try
        R.OnFindComponentClass := ReaderFindClass;
        R.OnFindMethod := ReaderFindMethod;
        R.OnError := ReaderError;
        R.ReadRootComponent(FForm);
      finally
        R.Free;
      end;
    except
      on E: Exception do
      begin
        AError := E.Message;
        if FForm <> nil then
          FreeAndNil(FForm);
        Exit;
      end;
    end;
  finally
    Bin.Free;
    Src.Free;
  end;

  AfterLoad;
  Result := True;
  if OldSel <> '' then
    SelectByName(OldSel);
end;

procedure TFormDesigner.AfterLoad;
var
  I: Integer;
  C: TComponent;
  Icon: TDsgIcon;
  Cl: string;
begin
  // Скрытые в .dfm контролы в конструкторе видны - как у Delphi.
  // TTabSheet не трогаем: его Visible переключает сам TPageControl.
  for I := 0 to FForm.ComponentCount - 1 do
  begin
    C := FForm.Components[I];
    if (C is TControl) and not (C is TTabSheet) and
       not TControl(C).Visible then
    begin
      FHidden.Add(C);    // запомнить - обводится красной рамкой
      TControl(C).Visible := True;
    end;
  end;

  // Заглушки подписываем: имя и настоящий класс
  for I := 0 to FForm.ComponentCount - 1 do
  begin
    C := FForm.Components[I];
    if C is TDsgStub then
    begin
      TDsgStub(C).Caption := C.Name + ': ' + FClassOf.Values[C.Name];
      TDsgStub(C).Color := $00E0E0E0;
    end;
  end;

  // Перехватчики - у формы и всех оконных контролов
  TDsgHook.CreateHook(FForm, Self);
  for I := 0 to FForm.ComponentCount - 1 do
    if FForm.Components[I] is TWinControl then
      TDsgHook.CreateHook(TWinControl(FForm.Components[I]), Self);
  // И у внутренних: их создаёт сам компонент, владелец - он, а не форма
  // (кнопки TGroupButton у TRadioGroup). Без перехватчика такой контрол
  // обрабатывает щелчок сам - переключатель переключается, а конструктор
  // щелчка не видит.
  HookInner(FForm, Self);

  // Невизуальные - значками. Пункты меню и прочее, что лежит внутри
  // другого компонента (HasParent), значка не получают.
  for I := 0 to FForm.ComponentCount - 1 do
  begin
    C := FForm.Components[I];
    if (C is TControl) or (C is TDsgHook) or C.HasParent then
      Continue; // TDsgHook - перехватчик самой формы, не компонент .dfm
    Cl := FClassOf.Values[C.Name];
    if Cl = '' then
      Cl := C.ClassName;
    Icon := TDsgIcon.Create(FForm);
    Icon.FDesigner := Self;
    Icon.FComp := C;
    Icon.FClassName := Cl;
    Icon.SetBounds(LongRec(C.DesignInfo).Lo, LongRec(C.DesignInfo).Hi, 28, 28);
    Icon.Hint := C.Name + ': ' + Cl;
    Icon.ShowHint := True;
    Icon.Parent := FForm;
  end;

  for I := 1 to 8 do
  begin
    FCarets[I] := TDsgCaret.CreateCaret(FForm, Self, I);
    // Не Parent, а ParentWindow: окно маркера - дочернее окно формы, но в
    // список её контролов не входит. Иначе форма с AutoScroll считает
    // маркеры в области прокрутки (CalcAutoRange), а выравнивание идёт
    // по этой области (AdjustClientRect): маркер у правого края
    // выделенного компонента расширял область, выровненные панели
    // (alRight, alClient) уезжали вправо - уже после расстановки маркеров.
    FCarets[I].ParentWindow := FForm.Handle;
  end;

  LockButtonRows;

  FForm.OnClose := FormClose;
  // Окно конструктора стоит там, где записано в .dfm (Left/Top). Position
  // из .dfm (poDesktopCenter, poScreenCenter, poDefault...) - это правило
  // для запущенной программы; конструктор Delphi его тоже не применяет.
  // Без этого каждая перестройка формы (Ctrl+Z, Delete) ставила окно по
  // правилу заново, например в центр экрана.
  FForm.Position := poDesigned;
  FForm.Show;
  // Окно конструктора - поверх главного окна редактора: его владельцем
  // делается главное окно. Иначе щелчок по палитре или инспектору поднимает
  // редактор, и форма уходит под него - компонент некуда поставить.
  // Владелец, а не fsStayOnTop: форма остаётся над редактором, но не над
  // окнами других программ, и сворачивается вместе с редактором.
  if (Application.MainForm <> nil) and Application.MainForm.HandleAllocated then
    SetWindowLong(FForm.Handle, GWL_HWNDPARENT,
                  Integer(Application.MainForm.Handle));
  Windows.SetFocus(FForm.Handle);

  // Открытые по .dfm вкладки - как если бы их выбрали: код, который
  // показывает и прячет компоненты по вкладке, применяется и к ним
  if Assigned(FOnPageChange) then
    for I := 0 to FForm.ComponentCount - 1 do
      if FForm.Components[I] is TPageControl then
        FOnPageChange(FForm.Components[I].Name,
                      TPageControl(FForm.Components[I]).ActivePageIndex);
end;

procedure TFormDesigner.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
  if Assigned(FOnClose) then
    FOnClose(Self);
end;

// Сетка точками поверх фона формы - как PaintFormGrid у RQ
procedure TFormDesigner.PaintGrid(DC: HDC);
var
  X, Y: Integer;
begin
  if (FForm = nil) or (FGrid < 2) then
    Exit;
  Y := 0;
  while Y < FForm.ClientHeight do
  begin
    X := 0;
    while X < FForm.ClientWidth do
    begin
      SetPixel(DC, X, Y, $007F7F7F);
      Inc(X, FGrid);
    end;
    Inc(Y, FGrid);
  end;
end;

function TFormDesigner.SelControl: TControl;
begin
  if (FSel is TControl) and (FSel <> FForm) then
    Result := TControl(FSel)
  else
    Result := nil;
end;

function TFormDesigner.SelectedName: string;
begin
  if FSel = nil then
    Result := ''
  else if FSel = FForm then
    Result := FRootName
  else
    Result := FSel.Name;
end;

procedure TFormDesigner.MenuBarClick(const AScreen: TPoint);
var
  MainMenu: TMainMenu;
  Index, Position: Integer;
  Item: TMenuItem;
  ItemRect: TRect;
begin
  if (FForm = nil) or (FForm.Menu = nil) then
    Exit;
  MainMenu := FForm.Menu;
  // Места пунктов - у Windows; в строке меню только видимые пункты
  Position := 0;
  for Index := 0 to MainMenu.Items.Count - 1 do
  begin
    Item := MainMenu.Items[Index];
    if not Item.Visible then
      Continue;
    if GetMenuItemRect(FForm.Handle, MainMenu.Handle, Position, ItemRect) and
       PtInRect(ItemRect, AScreen) then
    begin
      // Маркеры - на значке меню; в инспекторе - сам пункт
      Select(MainMenu, False);
      if (Item.Name <> '') and Assigned(FOnSelect) then
        FOnSelect(Item.Name)
      else if Assigned(FOnSelect) then
        FOnSelect(MainMenu.Name);
      Exit;
    end;
    Inc(Position);
  end;
  // Мимо пунктов - само меню
  Select(MainMenu, True);
end;

// Выделенный компонент - поверх соседей, чтобы его было видно и можно было
// зацепить мышью, даже если он перекрыт (поле под заголовком таблицы,
// флажок под редактором). Только на форме конструктора: порядок в .dfm не
// меняется (для этого - Bring to Front в меню). Выровненный не трогаем:
// порядок выровненных соседей - это и порядок их раскладки.
//
// Соседние окна, которых нет среди контролов VCL (заголовок таблицы
// SysHeader32), могут рисовать поверх, не глядя на порядок: им ставится
// WS_CLIPSIBLINGS - тогда они обходят окна, лежащие выше.
procedure DsgRaiseSelected(C: TControl);
var
  W: HWND;
  St: Longint;
begin
  if (C = nil) or (C.Parent = nil) or (C.Align <> alNone) then
    Exit;
  C.BringToFront;
  if not (C is TWinControl) or not C.Parent.HandleAllocated then
    Exit;
  W := GetWindow(C.Parent.Handle, GW_CHILD);
  while W <> 0 do
  begin
    if W <> TWinControl(C).Handle then
    begin
      St := GetWindowLong(W, GWL_STYLE);
      if St and WS_CLIPSIBLINGS = 0 then
        SetWindowLong(W, GWL_STYLE, St or WS_CLIPSIBLINGS);
    end;
    W := GetWindow(W, GW_HWNDNEXT);
  end;
  TWinControl(C).Invalidate;
end;

procedure TFormDesigner.Select(AComp: TComponent; ANotify: Boolean);
var
  I: Integer;
begin
  // Обычное выделение - группа распадается
  if (FGroup <> nil) and (FGroup.Count > 0) then
  begin
    DsgLog('2582: группа сброшена: выделен ' + DsgCompName(AComp), clNavy);
    FGroup.Clear;
    ShowGroupMarks;
  end;
  FSel := AComp;
  if SelControl <> nil then
    DsgRaiseSelected(SelControl);
  if SelControl <> nil then
    ShowCarets
  else
    HideCarets;
  // Значки перерисовать: выделенный подсвечен
  if FForm <> nil then
    for I := 0 to FForm.ControlCount - 1 do
      if FForm.Controls[I] is TDsgIcon then
        FForm.Controls[I].Invalidate;
  if ANotify and Assigned(FOnSelect) then
    FOnSelect(SelectedName);
end;

procedure TFormDesigner.SelectByName(const AName: string);
var
  C: TComponent;
begin
  if FForm = nil then
    Exit;
  if CompareText(AName, FRootName) = 0 then
    C := FForm
  else
    C := FForm.FindComponent(AName);
  Select(C, False);
end;

// Маркеры - внутри рамки компонента: 1, 3, 5, 7 в углах, 2, 4, 6, 8 на
// серединах сторон
procedure TFormDesigner.ShowCarets;
var
  C: TControl;
  P, Was: TPoint;
  L, T, W, H, MX, MY, I, Pass: Integer;
  OldR: array[1..8] of TRect;
  WasVisible: array[1..8] of Boolean;
begin
  C := SelControl;
  // Группа: вместо маркеров - уголки у каждого компонента
  if GroupCount > 1 then
  begin
    HideCarets;
    ShowGroupMarks;
    Exit;
  end;
  if (C = nil) or (C.Parent = nil) then
  begin
    HideCarets;
    Exit;
  end;

  // Где маркеры стояли - после переноса это место перерисовывается
  for I := 1 to 8 do
  begin
    WasVisible[I] := FCarets[I].Visible;
    OldR[I] := FCarets[I].BoundsRect;
  end;

  // Окно формы могли создать заново - маркеры переселяем в новое.
  // Координаты маркеров - клиентские координаты окна формы, те же, что
  // даёт FForm.ScreenToClient.
  for I := 1 to 8 do
  begin
    if FCarets[I].ParentWindow <> FForm.Handle then
      FCarets[I].ParentWindow := FForm.Handle;
    if not FCarets[I].Visible then
      FCarets[I].Visible := True;
  end;

  // Место компонента сверяется ещё раз после расстановки: если раскладка
  // формы всё же сдвинулась, маркеры переставляются. Маркеры в
  // выравнивании больше не участвуют (см. ParentWindow выше), обычно
  // хватает одного прохода.

  Was := Point(MaxInt, MaxInt);
  W := -1;
  H := -1;
  for Pass := 1 to 3 do
  begin
    P := FForm.ScreenToClient(C.Parent.ClientToScreen(Point(C.Left, C.Top)));
    if (P.X = Was.X) and (P.Y = Was.Y) and (C.Width = W) and
       (C.Height = H) then
      Break;
    Was := P;
    L := P.X;
    T := P.Y;
    W := C.Width;
    H := C.Height;
    MX := L + (W - CaretSize) div 2;
    MY := T + (H - CaretSize) div 2;

    FCarets[1].SetBounds(L, T, CaretSize, CaretSize);
    FCarets[2].SetBounds(L, MY, CaretSize, CaretSize);
    FCarets[3].SetBounds(L, T + H - CaretSize, CaretSize, CaretSize);
    FCarets[4].SetBounds(MX, T + H - CaretSize, CaretSize, CaretSize);
    FCarets[5].SetBounds(L + W - CaretSize, T + H - CaretSize, CaretSize, CaretSize);
    FCarets[6].SetBounds(L + W - CaretSize, MY, CaretSize, CaretSize);
    FCarets[7].SetBounds(L + W - CaretSize, T, CaretSize, CaretSize);
    FCarets[8].SetBounds(MX, T, CaretSize, CaretSize);
  end;

  // Поверх всего на форме: компонент может лежать глубоко в панелях
  for I := 1 to 8 do
    FCarets[I].BringToFront;

  // Маркер - дочернее окно формы, а стоит он над контролами, вложенными в
  // панели. Место, откуда он ушёл, помечаем к перерисовке вместе со всеми
  // вложенными окнами (RDW_ALLCHILDREN) - и перерисовываем сразу
  // (FlushPaint): иначе при перетаскивании за маркерами оставался след.
  for I := 1 to 8 do
    if WasVisible[I] and not EqualRect(OldR[I], FCarets[I].BoundsRect) then
      RedrawWindow(FForm.Handle, @OldR[I], 0,
                   RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN);
  FlushPaint;
end;

// Всё, что на форме помечено к перерисовке, - нарисовать сейчас. WM_PAINT
// Windows присылает, только когда в очереди нет других сообщений, а пока
// кнопка мыши нажата и мышь движется, WM_MOUSEMOVE идут непрерывно: место,
// откуда ушёл компонент или маркер, стояло стёртым до отпускания кнопки.
procedure TFormDesigner.FlushPaint;
begin
  if (FForm <> nil) and FForm.HandleAllocated then
    RedrawWindow(FForm.Handle, nil, 0, RDW_UPDATENOW or RDW_ALLCHILDREN);
end;

procedure TFormDesigner.HideCarets;
var
  I: Integer;
  R: TRect;
begin
  for I := 1 to 8 do
    if (FCarets[I] <> nil) and FCarets[I].Visible then
    begin
      R := FCarets[I].BoundsRect;
      FCarets[I].Visible := False;
      // Место маркера - перерисовать вместе с вложенными окнами (см.
      // ShowCarets)
      if (FForm <> nil) and FForm.HandleAllocated then
        RedrawWindow(FForm.Handle, @R, 0,
                     RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN);
    end;
  FlushPaint;
end;

procedure TFormDesigner.ContextMenu(AComp: TComponent; const AScreen: TPoint);
begin
  FDragging := False;
  if AComp <> nil then
    Select(AComp, True);
  if Assigned(FOnContext) then
    FOnContext(AScreen);
end;

procedure TFormDesigner.DblClick;
begin
  FDragging := False;
  ReleaseCapture;
  // Компонент из кода: его обработчики назначаются в коде - не трогаем
  if IsRuntime(FSel) then
    Exit;
  if Assigned(FOnDblClick) and (FSel <> nil) then
    FOnDblClick(SelectedName);
end;

// Куда встанет компонент, поставленный щелчком по ATarget: ближайший
// контейнер снизу вверх. У TPageControl - его открытый лист. Заглушка
// неизвестного класса контейнером не считается: принимает ли настоящий
// класс детей, конструктор не знает.
function TFormDesigner.PlaceParent(ATarget: TComponent): TWinControl;
var
  C: TControl;
begin
  Result := FForm;
  if not (ATarget is TControl) then
    Exit;
  C := TControl(ATarget);
  while (C <> nil) and (C <> FForm) do
  begin
    if (C is TPageControl) and (TPageControl(C).ActivePage <> nil) then
    begin
      Result := TPageControl(C).ActivePage;
      Exit;
    end;
    if (C is TWinControl) and not (C is TDsgStub) and
       (csAcceptsControls in C.ControlStyle) then
    begin
      Result := TWinControl(C);
      Exit;
    end;
    C := C.Parent;
  end;
end;

procedure TFormDesigner.MarkCodePlaced(AComp: TComponent;
                                       const ASides: string);
var
  Key, Old: string;
  I: Integer;
begin
  if (AComp = nil) or (ASides = '') then
    Exit;
  Key := IntToHex(Integer(AComp), 8);
  Old := FCodePlaced.Values[Key];
  for I := 1 to Length(ASides) do
    if Pos(UpCase(ASides[I]), Old) = 0 then
      Old := Old + UpCase(ASides[I]);
  FCodePlaced.Values[Key] := Old;
end;

function TFormDesigner.CodePlacedSides(AComp: TComponent): string;
begin
  Result := '';
  if (AComp <> nil) and (FCodePlaced <> nil) then
    Result := FCodePlaced.Values[IntToHex(Integer(AComp), 8)];
end;

function TFormDesigner.IsRuntime(AComp: TComponent): Boolean;
begin
  Result := (AComp <> nil) and (FRuntime <> nil) and
            (FRuntime.IndexOf(AComp) >= 0);
end;

// Одно свойство из текста в записи .dfm: числа, True/False, элементы
// перечислений, наборы в скобках, строки в апострофах, цвета. Вложенные -
// через точку (Font.Size). Не разобралось - молча пропускаем: в коде это
// могло быть выражение.
procedure TFormDesigner.ApplyPropText(AObj: TPersistent;
                                      const AProp, AValue: string);
var
  P: Integer;
  Sub: TObject;
  PI: PPropInfo;
  V, S: string;
  N: Integer;
  C: Longint;
begin
  // Список строк: Tabs.Strings = ('SubList' 'Objects' 'Includes') - сюда
  // приходит уже объект Tabs и имя Strings. Элементы - литералы .dfm:
  // части в апострофах и #коды, склеенные без пробела; между элементами -
  // пробелы.
  if (AObj is TStrings) and (CompareText(AProp, 'Strings') = 0) then
  begin
    V := Trim(AValue);
    if (V = '') or (V[1] <> '(') then
      Exit;
    TStrings(AObj).Clear;
    S := '';
    P := 2;
    N := 0;          // 1 - внутри элемента
    while P <= Length(V) do
    begin
      if V[P] = '''' then
      begin
        // строка в апострофах, '' внутри - один апостроф
        Inc(P);
        while P <= Length(V) do
        begin
          if V[P] = '''' then
          begin
            if (P < Length(V)) and (V[P + 1] = '''') then
            begin
              S := S + '''';
              Inc(P, 2);
              Continue;
            end;
            Break;
          end;
          S := S + V[P];
          Inc(P);
        end;
        N := 1;
        Inc(P);
      end
      else if V[P] = '#' then
      begin
        // #13, #1234 - код знака
        Inc(P);
        C := 0;
        while (P <= Length(V)) and (V[P] in ['0'..'9']) do
        begin
          C := C * 10 + Ord(V[P]) - Ord('0');
          Inc(P);
        end;
        S := S + Chr(C and $FF);
        N := 1;
      end
      else
      begin
        // пробел или ')' - конец элемента
        if N = 1 then
        begin
          TStrings(AObj).Add(S);
          S := '';
          N := 0;
        end;
        Inc(P);
      end;
    end;
    if N = 1 then
      TStrings(AObj).Add(S);
    Exit;
  end;

  P := Pos('.', AProp);
  if P > 0 then
  begin
    PI := GetPropInfo(AObj, Copy(AProp, 1, P - 1));
    if (PI = nil) or (PI^.PropType^^.Kind <> tkClass) then
      Exit;
    Sub := GetObjectProp(AObj, PI);
    if Sub is TPersistent then
      ApplyPropText(TPersistent(Sub), Copy(AProp, P + 1, MaxInt), AValue);
    Exit;
  end;

  PI := GetPropInfo(AObj, AProp);
  if (PI = nil) or (PI^.SetProc = nil) then
    Exit;
  V := Trim(AValue);
  if V = '' then
    Exit;
  try
    case PI^.PropType^^.Kind of
      tkInteger:
        if IdentToColor(V, C) then
          SetOrdProp(AObj, PI, C)
        else if TryStrToInt(V, N) then
          SetOrdProp(AObj, PI, N);
      tkChar:
        if (Length(V) = 3) and (V[1] = '''') then
          SetOrdProp(AObj, PI, Ord(V[2]));
      tkEnumeration:
        begin
          N := GetEnumValue(PI^.PropType^, V);
          if N >= 0 then
            SetOrdProp(AObj, PI, N);
        end;
      tkSet:
        if (V[1] = '[') and (V[Length(V)] = ']') then
          SetSetProp(AObj, PI, Copy(V, 2, Length(V) - 2));
      tkString, tkLString, tkWString:
        if (Length(V) >= 2) and (V[1] = '''') and (V[Length(V)] = '''') then
        begin
          S := Copy(V, 2, Length(V) - 2);
          S := StringReplace(S, '''''', '''', [rfReplaceAll]);
          SetStrProp(AObj, PI, S);
        end;
      tkFloat:
        begin
          S := StringReplace(V, '.', DecimalSeparator, []);
          SetFloatProp(AObj, PI, StrToFloat(S));
        end;
    end;
  except
    // выражение или значение не того типа - пропускаем
  end;
end;

function TFormDesigner.AddRuntime(const AName, AClass, AParent: string;
                                  AProps: TStrings): Boolean;
var
  Cls: TPersistentClass;
  Par: TComponent;
  Inst: TComponent;
  I, P, Pass: Integer;
  Nm, Val: string;
  IsAlign, HasAlign: Boolean;
  DefAlign: TAlign;
begin
  Result := False;
  FLastRuntime := nil;
  if FForm = nil then
    Exit;
  Cls := GetClass(AClass);
  // Класс неизвестен, но по свойствам это визуальный компонент (у него
  // есть размеры) - ставим заглушку, как для неизвестных классов из .dfm:
  // на ней встанут его дети (палитра - TDsgPalette - и её вкладки)
  if ((Cls = nil) or not Cls.InheritsFrom(TComponent)) and (AProps <> nil) and
     ((AProps.IndexOfName('Width') >= 0) or (AProps.IndexOfName('Height') >= 0)) then
  begin
    DsgLog('2969: runtime ' + AName + ': класс ' + AClass +
           ' неизвестен - заглушка', clGray);
    Cls := TDsgStub;
    if AName <> '' then
      FClassOf.Values[AName] := AClass;
  end;
  if (Cls = nil) or not Cls.InheritsFrom(TComponent) then
  begin
    DsgLog('2977: runtime ' + AName + ': класс ' + AClass + ' неизвестен');
    Exit;
  end;
  // Форма, созданная в коде, - отдельное окно, а не часть этой формы
  if Cls.InheritsFrom(TCustomForm) then
  begin
    DsgLog('2983: runtime ' + AName + ': ' + AClass + ' - отдельное окно, ' +
           'не показываем', clGray);
    Exit;
  end;

  if FRuntimeParent <> nil then
    Par := FRuntimeParent
  else if (AParent = '') or (CompareText(AParent, FRootName) = 0) then
    Par := FForm
  else
    Par := FForm.FindComponent(AParent);
  if Cls.InheritsFrom(TControl) and not (Par is TWinControl) then
  begin
    DsgLog('2996: runtime ' + AName + ': родитель ' + AParent + ' не найден');
    Exit; // визуальному некуда встать
  end;

  if DsgLogVerbose then
    DsgLog('3001: runtime ' + AName + ': ' + AClass + ' в ' + AParent + ', ' +
           IntToStr(AProps.Count) + ' свойств', clNavy);
  try
    Inst := TComponentClass(Cls).Create(FForm);
  except
    on E: Exception do
    begin
      DsgLog('3008: runtime ' + AName + ': не создался - ' + E.Message);
      Exit;
    end;
  end;
  // Имя - имя переменной, если оно свободно: по нему выделение связано с
  // деревом инспектора
  if IsValidIdent(AName) and (FForm.FindComponent(AName) = nil) then
  try
    Inst.Name := AName;
  except
  end;

  if (Inst is TTabSheet) and (Par is TPageControl) then
    // Лист встаёт страницей, а не просто ребёнком - иначе его вкладки нет
    TTabSheet(Inst).PageControl := TPageControl(Par)
  else if Inst is TControl then
    TControl(Inst).Parent := TWinControl(Par);

  // Серия (BeginRuntime): и в новом контейнере выравнивание - в конце
  if FRtBatch and (Inst is TWinControl) then
  begin
    TWinControl(Inst).DisableAlign;
    FAlignOff.Add(Inst);
  end;

  // Своё выравнивание по умолчанию (TSplitter - alLeft, TStatusBar -
  // alBottom) на время размеров снимается. Иначе:
  //  - Height = 3 у TSplitter с alLeft растягивается на высоту родителя;
  //  - потом Align := alTop: VCL при смене вертикального выравнивания на
  //    горизонтальное меняет ширину и высоту местами (TControl.SetAlign,
  //    не при загрузке из .dfm) - и сплиттер становится высотой в свою
  //    ширину, на полформы.
  // С alNone перестановки нет. Если в свойствах Align нет - прежнее
  // выравнивание возвращается во втором проходе, тоже с alNone.
  HasAlign := (AProps <> nil) and (AProps.IndexOfName('Align') >= 0);
  DefAlign := alNone;
  if Inst is TControl then
  begin
    DefAlign := TControl(Inst).Align;
    if DefAlign <> alNone then
      TControl(Inst).Align := alNone;
  end;

  // Два прохода: сначала всё, кроме Align и Anchors, потом они. Порядок
  // выровненных соседей VCL берёт из их Left/Top, поэтому место должно
  // быть на месте до того, как включится выравнивание.
  if AProps <> nil then
    for Pass := 1 to 2 do
      for I := 0 to AProps.Count - 1 do
      begin
        P := Pos('=', AProps[I]);
        if P = 0 then
          Continue;
        Nm := Trim(Copy(AProps[I], 1, P - 1));
        Val := Copy(AProps[I], P + 1, MaxInt);
        if (Nm = '') or (CompareText(Copy(Nm, 1, 2), 'On') = 0) or
           (CompareText(Nm, 'Name') = 0) or (CompareText(Nm, 'Parent') = 0) then
          Continue;
        IsAlign := (CompareText(Nm, 'Align') = 0) or
                   (CompareText(Nm, 'Anchors') = 0);
        if IsAlign <> (Pass = 2) then
          Continue;
        if DsgLogVerbose then
          DsgLog('3071:   ' + Nm + ' = ' + Val, clGray);
        ApplyPropText(Inst, Nm, Val);
      end;
  if (Inst is TControl) and not HasAlign and (DefAlign <> alNone) then
    TControl(Inst).Align := DefAlign;

  // Скрытые видны, как у компонентов .dfm. Кроме листов: их видимость
  // переключает сам TPageControl, открытый чужой лист лёг бы поверх
  if (Inst is TControl) and not (Inst is TTabSheet) then
  begin
    if not TControl(Inst).Visible then
      FHidden.Add(Inst);
    TControl(Inst).Visible := True;
  end;
  // Плоская кнопка без значка (значок в снимок не попадает) ничего не
  // рисует, пока над ней нет мыши - в конструкторе её было бы не видно
  if (Inst is TSpeedButton) and TSpeedButton(Inst).Glyph.Empty then
    TSpeedButton(Inst).Flat := False;
  FRuntime.Add(Inst);
  if Inst is TWinControl then
    TDsgHook.CreateHook(TWinControl(Inst), Self);
  FLastRuntime := Inst;
  Result := True;
end;

function TFormDesigner.Reparent(const AName, AParent: string): Boolean;
var
  C, P: TComponent;
begin
  Result := False;
  if FForm = nil then
    Exit;
  C := FForm.FindComponent(AName);
  if (AParent = '') or (CompareText(AParent, FRootName) = 0) then
    P := FForm
  else
    P := FForm.FindComponent(AParent);
  if not (C is TControl) or not (P is TWinControl) then
  begin
    DsgLog('3110: перенос ' + AName + ' в ' + AParent + ': не найден ' +
           'компонент или родитель');
    Exit;
  end;
  if DsgLogVerbose then
    DsgLog('3115: перенос ' + AName + ' в ' + AParent, clNavy);
  TControl(C).Parent := TWinControl(P);
  if FRuntime.IndexOf(C) < 0 then
    FRuntime.Add(C);
  Result := True;
end;

procedure TFormDesigner.BeginRuntime;
var
  I: Integer;
begin
  if (FForm = nil) or FRtBatch then
    Exit;
  FRtBatch := True;
  FAlignOff.Clear;
  if FForm.HandleAllocated then
    SendMessage(FForm.Handle, WM_SETREDRAW, 0, 0);
  FForm.DisableAlign;
  FAlignOff.Add(FForm);
  for I := 0 to FForm.ComponentCount - 1 do
    if FForm.Components[I] is TWinControl then
    begin
      TWinControl(FForm.Components[I]).DisableAlign;
      FAlignOff.Add(FForm.Components[I]);
    end;
end;

procedure TFormDesigner.FinishRuntime;
var
  I, Pass: Integer;
begin
  if FForm = nil then
    Exit;
  if FRtBatch then
  begin
    // Выравнивание - обратно, от вложенных к форме: каждый контейнер
    // выстраивает детей один раз, а не на каждое их свойство
    FRtBatch := False;
    for I := FAlignOff.Count - 1 downto 0 do
      TWinControl(FAlignOff[I]).EnableAlign;
    FAlignOff.Clear;
  end;
  // Два прохода: после первого у вложенных контейнеров меняются размеры,
  // и их дети выстраиваются уже по ним
  for Pass := 1 to 2 do
  begin
    FForm.Realign;
    for I := 0 to FForm.ComponentCount - 1 do
      if FForm.Components[I] is TWinControl then
        TWinControl(FForm.Components[I]).Realign;
  end;
  // Перехватчики - и внутренним контролам, которые появились после
  // загрузки: TRadioGroup строит кнопки заново, когда ему ставят Items
  HookInner(FForm, Self);
  // Перерисовка - обратно и сразу вся форма
  if FForm.HandleAllocated then
  begin
    SendMessage(FForm.Handle, WM_SETREDRAW, 1, 0);
    RedrawWindow(FForm.Handle, nil, 0, RDW_ERASE or RDW_FRAME or
                 RDW_INVALIDATE or RDW_ALLCHILDREN);
  end;
  if FSel <> nil then
    Select(FSel, False);  // маркеры - по новому месту выделенного
end;

// Пометка runtime-компонента: пунктирная рамка по краю, чтобы не спутать
// с компонентом из .dfm
procedure TFormDesigner.MarkRuntime(ACtl: TWinControl);
var
  DC: HDC;
  C: TCanvas;
  R: TRect;
begin
  if not ACtl.HandleAllocated then
    Exit;
  DC := GetDC(ACtl.Handle);
  C := TCanvas.Create;
  try
    C.Handle := DC;
    R := ACtl.ClientRect;
    C.Brush.Style := bsClear;
    C.Pen.Color := clNavy;
    C.Pen.Style := psDot;
    C.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
  finally
    C.Handle := 0;
    C.Free;
    ReleaseDC(ACtl.Handle, DC);
  end;
end;

// Контейнер без своей видимой границы: принимает детей (csAcceptsControls),
// и все свойства рамки, какие у него есть, выключены - BevelOuter,
// BevelInner, BevelKind, BorderStyle. Свойства читаются по имени (RTTI):
// так подходят и TPanel, и TScrollBox, и свои панели с теми же свойствами.
// У кого ни одного такого свойства нет (TGroupBox, TPageControl), тот
// рисует рамку сам.
function NoVisibleBorder(ACtl: TWinControl): Boolean;
var
  HasBorderProp: Boolean;

  // Свойство есть и не выключено: AOff - значение «нет рамки»
  function PropOn(const AProp: string; AOff: Integer): Boolean;
  begin
    Result := False;
    if not IsPublishedProp(ACtl, AProp) or
       not (PropType(ACtl, AProp) in [tkEnumeration]) then
      Exit;
    HasBorderProp := True;
    Result := GetOrdProp(ACtl, AProp) <> AOff;
  end;

begin
  Result := False;
  if (ACtl = nil) or not (csAcceptsControls in ACtl.ControlStyle) then
    Exit;
  HasBorderProp := False;
  if PropOn('BevelOuter', Ord(bvNone)) or PropOn('BevelInner', Ord(bvNone)) or
     PropOn('BevelKind', Ord(bkNone)) or PropOn('BorderStyle', Ord(bsNone)) then
    Exit;
  Result := HasBorderProp;
end;

// Цвет пунктирной рамки на фоне контрола AOn: на тёмном светлее, на
// светлом темнее
function OutlineColorOn(AOn: TWinControl): TColor;
var
  Back: Longint;
begin
  Back := ColorToRGB(clBtnFace);
  if IsPublishedProp(AOn, 'Color') then
    Back := ColorToRGB(TColor(GetOrdProp(AOn, 'Color')));
  if (GetRValue(Back) * 299 + GetGValue(Back) * 587 +
      GetBValue(Back) * 114) div 1000 < 128 then
    Result := $00A0A0A0
  else
    Result := $00808080;
end;

// Безоконный контрол, который сам ничего не рисует (в работе его не видно,
// пока нет мыши или картинки)
function DrawsNothing(ACtl: TControl): Boolean;
begin
  Result := ((ACtl is TSpeedButton) and TSpeedButton(ACtl).Flat) or
            (ACtl is TPaintBox) or
            ((ACtl is TImage) and (TImage(ACtl).Picture.Graphic = nil));
end;

procedure TFormDesigner.MarkInvisibleKids(ACtl: TWinControl);
var
  DC: HDC;
  Cnv: TCanvas;
  KidIdx: Integer;
  Kid: TControl;
  KidRect: TRect;
  Any: Boolean;
begin
  if not ACtl.HandleAllocated then
    Exit;
  Any := False;
  for KidIdx := 0 to ACtl.ControlCount - 1 do
    if not (ACtl.Controls[KidIdx] is TWinControl) and
       DrawsNothing(ACtl.Controls[KidIdx]) then
    begin
      Any := True;
      Break;
    end;
  if not Any then
    Exit;
  DC := GetDC(ACtl.Handle);
  Cnv := TCanvas.Create;
  try
    Cnv.Handle := DC;
    Cnv.Brush.Style := bsClear;
    Cnv.Pen.Color := OutlineColorOn(ACtl);
    Cnv.Pen.Style := psDot;
    Cnv.Pen.Width := 1;
    for KidIdx := 0 to ACtl.ControlCount - 1 do
    begin
      Kid := ACtl.Controls[KidIdx];
      if (Kid is TWinControl) or not Kid.Visible or not DrawsNothing(Kid) then
        Continue;
      KidRect := Kid.BoundsRect;
      Cnv.Rectangle(KidRect.Left, KidRect.Top, KidRect.Right, KidRect.Bottom);
    end;
  finally
    Cnv.Handle := 0;
    Cnv.Free;
    ReleaseDC(ACtl.Handle, DC);
  end;
end;

procedure TFormDesigner.MarkBorderless(ACtl: TWinControl);
var
  DC: HDC;
  Cnv: TCanvas;
  Area: TRect;
begin
  if not ACtl.HandleAllocated or not NoVisibleBorder(ACtl) then
    Exit;
  DC := GetDC(ACtl.Handle);
  Cnv := TCanvas.Create;
  try
    Cnv.Handle := DC;
    Area := ACtl.ClientRect;
    Cnv.Brush.Style := bsClear;
    Cnv.Pen.Color := OutlineColorOn(ACtl);
    Cnv.Pen.Style := psDot;
    Cnv.Pen.Width := 1;
    Cnv.Rectangle(Area.Left, Area.Top, Area.Right, Area.Bottom);
  finally
    Cnv.Handle := 0;
    Cnv.Free;
    ReleaseDC(ACtl.Handle, DC);
  end;
end;

procedure TFormDesigner.SetPageRules(const APageCtl: string; ARules: TStrings);
var
  I: Integer;
  L: TStringList;
begin
  I := FPageRules.IndexOf(APageCtl);
  if I < 0 then
    I := FPageRules.AddObject(APageCtl, TStringList.Create);
  L := TStringList(FPageRules.Objects[I]);
  L.Assign(ARules);
  if (FForm <> nil) and FForm.HandleAllocated then
    RedrawWindow(FForm.Handle, nil, 0,
                 RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN);
end;

function TFormDesigner.SetPropText(const AComp, AProp, AValue: string): Boolean;
var
  C: TComponent;
begin
  Result := False;
  if FForm = nil then
    Exit;
  if CompareText(AComp, FRootName) = 0 then
    C := FForm
  else
    C := FForm.FindComponent(AComp);
  Result := SetCompPropText(C, AProp, AValue);
end;

function TFormDesigner.SetCompPropText(AComp: TComponent;
                                       const AProp, AValue: string): Boolean;
var
  C: TComponent;
  Hid: Boolean;
begin
  Result := False;
  C := AComp;
  if (FForm = nil) or (C = nil) then
    Exit;
  // Имя - это и ссылки на компонент из других: только перезагрузка
  if CompareText(AProp, 'Name') = 0 then
    Exit;

  Result := True;

  // Окно конструктора живёт по своим правилам, как при загрузке
  // (PrepareText, AfterLoad): стиль, видимость, развёрнутость и место по
  // правилу Position ему не применяются
  if (C = FForm) and
     ((CompareText(AProp, 'FormStyle') = 0) or
      (CompareText(AProp, 'Visible') = 0) or
      (CompareText(AProp, 'WindowState') = 0) or
      (CompareText(AProp, 'Position') = 0)) then
    Exit;

  // Скрытый контрол остаётся видимым, с красной рамкой (FHidden). TTabSheet
  // не трогаем: его Visible переключает сам TPageControl.
  if (C is TControl) and not (C is TTabSheet) and
     (CompareText(AProp, 'Visible') = 0) then
  begin
    Hid := CompareText(Trim(AValue), 'False') = 0;
    if Hid then
    begin
      if FHidden.IndexOf(C) < 0 then
        FHidden.Add(C);
    end
    else
      FHidden.Remove(C);
    if FForm.HandleAllocated then
      RedrawWindow(FForm.Handle, nil, 0,
                   RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN);
    Exit;
  end;

  ApplyPropText(C, AProp, AValue);

  // Размер, место или выравнивание могли сдвинуть и соседей - маркеры
  // выделения ставятся заново
  if C is TControl then
    TControl(C).Invalidate;
  if SelControl <> nil then
    ShowCarets;
end;

// Кнопки в ряд - панель инструментов из TSpeedButton: у всех кнопок одного
// родителя (без выравнивания) один и тот же Top, и их не меньше трёх. Такие
// кнопки двигаются только вдоль ряда: Top закреплён так же, как координата
// от кода (MarkCodePlaced, буква T) - и мышью, и верхними маркерами.
// Высоту тянуть можно, Top в инспекторе правится. Ряд проверяется при
// каждой загрузке: кнопку, у которой Top поправили, ряд уже не держит.
procedure TFormDesigner.LockButtonRows;
var
  I, J, N, T: Integer;
  W: TWinControl;
  C: TControl;
  Row: Boolean;
begin
  if FForm = nil then
    Exit;
  for I := -1 to FForm.ComponentCount - 1 do
  begin
    if I < 0 then
      W := FForm
    else if FForm.Components[I] is TWinControl then
      W := TWinControl(FForm.Components[I])
    else
      Continue;
    N := 0;
    T := 0;
    Row := True;
    for J := 0 to W.ControlCount - 1 do
    begin
      C := W.Controls[J];
      if not (C is TSpeedButton) or (C.Align <> alNone) then
        Continue;
      if N = 0 then
        T := C.Top
      else if C.Top <> T then
      begin
        Row := False;
        Break;
      end;
      Inc(N);
    end;
    if not Row or (N < 3) then
      Continue;
    for J := 0 to W.ControlCount - 1 do
    begin
      C := W.Controls[J];
      if (C is TSpeedButton) and (C.Align = alNone) then
        MarkCodePlaced(C, 'T');
    end;
  end;
end;

procedure TFormDesigner.SetTabMembers(ATabCtl: TTabControl;
                                      AMembers: TStrings);
var
  I: Integer;
  Key: string;
begin
  if ATabCtl = nil then
    Exit;
  Key := IntToHex(Integer(ATabCtl), 8);
  I := FTabMembers.IndexOf(Key);
  if I < 0 then
    I := FTabMembers.AddObject(Key, TStringList.Create);
  TStringList(FTabMembers.Objects[I]).Assign(AMembers);
  ApplyTabMembers(ATabCtl);
end;

// Компоненты открытой вкладки ATabCtl - видны, других вкладок - спрятаны
procedure TFormDesigner.ApplyTabMembers(ATabCtl: TTabControl);
var
  I, K, P: Integer;
  L: TStringList;
  C: TComponent;
begin
  if FForm = nil then
    Exit;
  I := FTabMembers.IndexOf(IntToHex(Integer(ATabCtl), 8));
  if I < 0 then
    Exit;
  L := TStringList(FTabMembers.Objects[I]);
  for K := 0 to L.Count - 1 do
  begin
    P := Pos('=', L[K]);
    if P = 0 then
      Continue;
    C := FForm.FindComponent(Copy(L[K], 1, P - 1));
    if not (C is TControl) then
      Continue;
    // Спрятан в снимке потому, что на другой вкладке, - не «скрыт»
    FHidden.Remove(C);
    TControl(C).Visible :=
      StrToIntDef(Copy(L[K], P + 1, MaxInt), -1) = ATabCtl.TabIndex;
  end;
  // Выделенный ушёл на другую вкладку - маркеры убрать
  if SelControl <> nil then
    if SelControl.Visible then
      ShowCarets
    else
      HideCarets;
end;

function TFormDesigner.MarkedHidden(AC: TControl): Boolean;
var
  I: Integer;
  V: string;
  Found: Boolean;
begin
  Result := False;
  if AC = nil then
    Exit;
  Found := False;
  if AC.Name <> '' then
    for I := 0 to FPageRules.Count - 1 do
    begin
      V := TStringList(FPageRules.Objects[I]).Values[AC.Name];
      if V <> '' then
      begin
        Result := V = '0';
        Found := True;
      end;
    end;
  if not Found then
    Result := FHidden.IndexOf(AC) >= 0;
end;

// Рамка рисуется поверх уже нарисованного, после WM_PAINT: у оконного
// скрытого - по краю его клиентской области; безоконные (TLabel,
// TSpeedButton, TImage) рисует их родитель, поэтому их рамки - здесь же,
// по их месту у родителя. Дети-окна родителя рамку не перекрывают:
// DC клиентской области их не включает.
procedure TFormDesigner.MarkHidden(ACtl: TWinControl);
var
  DC: HDC;
  C: TCanvas;
  R: TRect;
  I: Integer;
  Ch: TControl;
  Any: Boolean;
begin
  if (FHidden = nil) or not ACtl.HandleAllocated then
    Exit;
  if (FHidden.Count = 0) and (FPageRules.Count = 0) then
    Exit;

  // Есть ли что рисовать - до GetDC
  Any := MarkedHidden(ACtl);
  if not Any then
    for I := 0 to ACtl.ControlCount - 1 do
    begin
      Ch := ACtl.Controls[I];
      if not (Ch is TWinControl) and MarkedHidden(Ch) then
      begin
        Any := True;
        Break;
      end;
    end;
  if not Any then
    Exit;

  DC := GetDC(ACtl.Handle);
  C := TCanvas.Create;
  try
    C.Handle := DC;
    C.Brush.Style := bsClear;
    C.Pen.Color := clRed;
    C.Pen.Style := psSolid;
    C.Pen.Width := 1;
    if MarkedHidden(ACtl) then
    begin
      R := ACtl.ClientRect;
      C.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
      C.Rectangle(R.Left + 1, R.Top + 1, R.Right - 1, R.Bottom - 1);
    end;
    for I := 0 to ACtl.ControlCount - 1 do
    begin
      Ch := ACtl.Controls[I];
      if (Ch is TWinControl) or not MarkedHidden(Ch) then
        Continue;
      R := Ch.BoundsRect;
      C.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
      C.Rectangle(R.Left + 1, R.Top + 1, R.Right - 1, R.Bottom - 1);
    end;
  finally
    C.Handle := 0;
    C.Free;
    ReleaseDC(ACtl.Handle, DC);
  end;
end;

// ---------------------------------------------------------------------------
//  Группа выделенных (Shift+щелчок)
// ---------------------------------------------------------------------------

function TFormDesigner.GroupCount: Integer;
begin
  Result := 0;
  if (FGroup <> nil) and (FGroup.Count > 1) then
    Result := FGroup.Count;
end;

function TFormDesigner.InGroup(AComp: TComponent): Boolean;
begin
  Result := (AComp <> nil) and (GroupCount > 1) and
            (FGroup.IndexOf(AComp) >= 0);
end;

procedure TFormDesigner.GroupNames(ANames: TStrings);
var
  I: Integer;
  C: TComponent;
begin
  ANames.Clear;
  if GroupCount > 1 then
  begin
    for I := 0 to FGroup.Count - 1 do
    begin
      C := TComponent(FGroup[I]);
      // Значок невизуального (TTimer) - это его компонент
      if C is TDsgIcon then
        C := TDsgIcon(C).FComp;
      if (C <> nil) and (C <> FForm) and not IsRuntime(C) and
         (C.Name <> '') then
        ANames.Add(C.Name);
    end;
  end
  else if (FSel <> nil) and (FSel <> FForm) and not IsRuntime(FSel) and
          (FSel.Name <> '') then
    ANames.Add(FSel.Name);
end;

procedure TFormDesigner.GroupComps(AList: TList);
var
  I: Integer;
  C: TComponent;
begin
  AList.Clear;
  if GroupCount < 2 then
    Exit;
  for I := 0 to FGroup.Count - 1 do
  begin
    C := TComponent(FGroup[I]);
    if C is TDsgIcon then
      C := TDsgIcon(C).FComp;
    if C <> nil then
      AList.Add(C);
  end;
end;

function TFormDesigner.GroupIsRuntime: Boolean;
begin
  Result := (GroupCount > 1) and IsRuntime(TComponent(FGroup[0]));
end;

// Компонент - в группу, а если он уже там - из группы. Первый Shift+щелчок
// делает группу из выделенного и нового. Главный ушёл из группы - главным
// становится следующий.
procedure TFormDesigner.ToggleGroup(AComp: TComponent);
var
  I: Integer;
begin
  if FGroup.Count = 0 then
    FGroup.Add(FSel);
  I := FGroup.IndexOf(AComp);
  if I < 0 then
    FGroup.Add(AComp)
  else
  begin
    FGroup.Delete(I);
    if (AComp = FSel) and (FGroup.Count > 0) then
    begin
      FSel := TComponent(FGroup[0]);
      if Assigned(FOnSelect) then
        FOnSelect(SelectedName);
    end;
  end;
  if FGroup.Count <= 1 then
  begin
    FGroup.Clear;
    ShowCarets;
  end
  else
    HideCarets;
  DsgLog('3572: группа: компонентов ' + IntToStr(FGroup.Count), clNavy);
  ShowGroupMarks;
  if Assigned(FOnGroupChange) then
    FOnGroupChange(Self);
end;

// Уголки 5x5 по углам компонентов группы - как у Delphi. Окошки - дочерние
// окна формы (ParentWindow, как маркеры выделения), координаты - клиентские
// координаты формы: компоненты группы могут лежать в разных панелях. Группы
// нет - все окошки прячутся. Компонент на скрытой вкладке - без уголков.
procedure TFormDesigner.ShowGroupMarks;
var
  Need, I, K, S: Integer;
  M: TDsgGroupMark;
  C: TControl;
  P: TPoint;
  OldR: array of TRect;
  WasVisible: array of Boolean;
  Shown: Boolean;
begin
  if (FForm = nil) or not FForm.HandleAllocated then
    Exit;
  S := GroupMarkSize;
  if GroupCount > 1 then
    Need := FGroup.Count * 4
  else
    Need := 0;
  while FGroupMarks.Count < Need do
  begin
    M := TDsgGroupMark.Create(FForm);
    M.Visible := False;
    M.Enabled := False;
    M.Width := S;
    M.Height := S;
    M.ParentWindow := FForm.Handle;
    FGroupMarks.Add(M);
  end;

  SetLength(OldR, FGroupMarks.Count);
  SetLength(WasVisible, FGroupMarks.Count);
  for I := 0 to FGroupMarks.Count - 1 do
  begin
    M := TDsgGroupMark(FGroupMarks[I]);
    WasVisible[I] := M.Visible;
    OldR[I] := M.BoundsRect;
  end;

  for I := 0 to FGroupMarks.Count - 1 do
  begin
    M := TDsgGroupMark(FGroupMarks[I]);
    K := I div 4;
    Shown := False;
    if I < Need then
    begin
      C := TControl(FGroup[K]);
      Shown := (C.Parent <> nil) and C.Visible and C.Parent.Showing;
      if Shown then
      begin
        if M.ParentWindow <> FForm.Handle then
          M.ParentWindow := FForm.Handle;
        P := FForm.ScreenToClient(C.Parent.ClientToScreen(Point(C.Left, C.Top)));
        case I mod 4 of
          0: M.SetBounds(P.X, P.Y, S, S);
          1: M.SetBounds(P.X + C.Width - S, P.Y, S, S);
          2: M.SetBounds(P.X, P.Y + C.Height - S, S, S);
        else
          M.SetBounds(P.X + C.Width - S, P.Y + C.Height - S, S, S);
        end;
        if not M.Visible then
          M.Visible := True;
        // Поверх всего на форме: компонент может лежать глубоко в панелях
        M.BringToFront;
      end;
    end;
    if not Shown and M.Visible then
      M.Visible := False;
  end;

  // Место, откуда окошко ушло, - перерисовать вместе с вложенными окнами
  // (как в ShowCarets)
  for I := 0 to FGroupMarks.Count - 1 do
  begin
    M := TDsgGroupMark(FGroupMarks[I]);
    if WasVisible[I] and
       (not M.Visible or not EqualRect(OldR[I], M.BoundsRect)) then
      RedrawWindow(FForm.Handle, @OldR[I], 0,
                   RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN);
  end;
  FlushPaint;
end;

// Новые места группы - в .dfm одной серией (OnBatch)
procedure TFormDesigner.CommitGroup;
var
  I: Integer;
begin
  if Assigned(FOnBatch) then
    FOnBatch(True);
  try
    for I := 0 to FGroup.Count - 1 do
      if (I > High(FGroupFrom)) or
         not EqualRect(TControl(FGroup[I]).BoundsRect, FGroupFrom[I]) then
      begin
        // Значок невизуального: место - в DesignInfo его компонента
        if TObject(FGroup[I]) is TDsgIcon then
          with TDsgIcon(FGroup[I]) do
          begin
            FComp.DesignInfo := MakeLong(Word(Left), Word(Top));
            CommitBounds(FComp);
          end
        else
          CommitBounds(TComponent(FGroup[I]));
      end;
  finally
    if Assigned(FOnBatch) then
      FOnBatch(False);
  end;
end;

procedure TFormDesigner.AlignGroup(AKind: Integer);
var
  Ref, C: TControl;
  RefR, R: TRect;
  P: TPoint;
  I: Integer;
  Code: string;
begin
  if GroupCount < 2 then
    Exit;
  if AKind in [6, 7] then
  begin
    SpaceGroup(AKind = 6);
    Exit;
  end;
  Ref := TControl(FGroup[0]);
  if Ref.Parent = nil then
    Exit;
  // Место главного - в координатах экрана: остальные могут лежать в других
  // панелях
  P := Ref.Parent.ClientToScreen(Point(Ref.Left, Ref.Top));
  RefR := Rect(P.X, P.Y, P.X + Ref.Width, P.Y + Ref.Height);
  SetLength(FGroupFrom, FGroup.Count);
  for I := 0 to FGroup.Count - 1 do
    FGroupFrom[I] := TControl(FGroup[I]).BoundsRect;
  for I := 1 to FGroup.Count - 1 do
  begin
    C := TControl(FGroup[I]);
    if (C.Parent = nil) or (C.Align <> alNone) or IsRuntime(C) then
      Continue;
    Code := CodePlacedSides(C);
    R := C.BoundsRect;
    P := C.Parent.ScreenToClient(RefR.TopLeft);
    case AKind of
      0: if Pos('L', Code) = 0 then
           OffsetRect(R, P.X - R.Left, 0);
      1: if Pos('L', Code) = 0 then
           OffsetRect(R, P.X + Ref.Width - R.Right, 0);
      2: if Pos('T', Code) = 0 then
           OffsetRect(R, 0, P.Y - R.Top);
      3: if Pos('T', Code) = 0 then
           OffsetRect(R, 0, P.Y + Ref.Height - R.Bottom);
      4: if Pos('W', Code) = 0 then
           R.Right := R.Left + Ref.Width;
      5: if Pos('H', Code) = 0 then
           R.Bottom := R.Top + Ref.Height;
    end;
    if AKind in [0..3] then
      ClampToParent(C.Parent, R, False);
    C.BoundsRect := R;
  end;
  ShowGroupMarks;
  CommitGroup;
end;

type
  // Доступ к защищённому AdjustClientRect: у рамки с подписью (TGroupBox)
  // место для детей - ниже подписи
  TDsgClientCrack = class(TWinControl);

// Расставить группу по родителю на равных промежутках: по ширине (AHorz)
// или по высоте. Промежутки одинаковые и между компонентами, и от краёв
// родителя (его места для детей). Порядок - как стоят сейчас (слева
// направо, сверху вниз), размеры не меняются, другая ось не трогается.
// Участвуют компоненты с тем же родителем, что у главного (первого
// выделенного), без Align и не те, чьё место по этой оси задаёт код.
// Не помещаются - промежутки нулевые, ряд идёт от края.
procedure TFormDesigner.SpaceGroup(AHorz: Boolean);
var
  Par: TWinControl;
  Items: TList;
  Area, R: TRect;
  Ctl, Tmp: TControl;
  Index, Other, Total, FreeSpace, Gap, Extra, Pos0: Integer;
  Code: string;

  function StartOf(AControl: TControl): Integer;
  begin
    if AHorz then
      Result := AControl.Left
    else
      Result := AControl.Top;
  end;

begin
  if (GroupCount < 2) or (TControl(FGroup[0]).Parent = nil) then
    Exit;
  Par := TControl(FGroup[0]).Parent;
  Items := TList.Create;
  try
    for Index := 0 to FGroup.Count - 1 do
    begin
      Ctl := TControl(FGroup[Index]);
      if (Ctl.Parent <> Par) or (Ctl.Align <> alNone) or IsRuntime(Ctl) or
         (Ctl is TDsgIcon) then
        Continue;
      Code := CodePlacedSides(Ctl);
      if (AHorz and (Pos('L', Code) > 0)) or
         (not AHorz and (Pos('T', Code) > 0)) then
        Continue;
      Items.Add(Ctl);
    end;
    if Items.Count < 2 then
    begin
      DsgLog('3990: расстановка: подходящих компонентов меньше двух ' +
             '(нужен общий родитель, без Align)', clGray);
      Exit;
    end;

    // Порядок - по нынешнему месту
    for Index := 0 to Items.Count - 2 do
      for Other := Index + 1 to Items.Count - 1 do
        if StartOf(TControl(Items[Other])) < StartOf(TControl(Items[Index])) then
        begin
          Tmp := TControl(Items[Index]);
          Items[Index] := Items[Other];
          Items[Other] := Tmp;
        end;

    Area := Par.ClientRect;
    TDsgClientCrack(Par).AdjustClientRect(Area);
    Total := 0;
    for Index := 0 to Items.Count - 1 do
      if AHorz then
        Inc(Total, TControl(Items[Index]).Width)
      else
        Inc(Total, TControl(Items[Index]).Height);
    if AHorz then
      FreeSpace := (Area.Right - Area.Left) - Total
    else
      FreeSpace := (Area.Bottom - Area.Top) - Total;
    if FreeSpace < 0 then
      FreeSpace := 0;
    // Промежутков на один больше, чем компонентов: и у краёв. Остаток от
    // деления - по пикселю первым промежуткам.
    Gap := FreeSpace div (Items.Count + 1);
    Extra := FreeSpace mod (Items.Count + 1);

    SetLength(FGroupFrom, FGroup.Count);
    for Index := 0 to FGroup.Count - 1 do
      FGroupFrom[Index] := TControl(FGroup[Index]).BoundsRect;

    if AHorz then
      Pos0 := Area.Left
    else
      Pos0 := Area.Top;
    for Index := 0 to Items.Count - 1 do
    begin
      Inc(Pos0, Gap);
      if Index < Extra then
        Inc(Pos0);
      Ctl := TControl(Items[Index]);
      R := Ctl.BoundsRect;
      if AHorz then
        OffsetRect(R, Pos0 - R.Left, 0)
      else
        OffsetRect(R, 0, Pos0 - R.Top);
      Ctl.BoundsRect := R;
      if AHorz then
        Inc(Pos0, Ctl.Width)
      else
        Inc(Pos0, Ctl.Height);
    end;
  finally
    Items.Free;
  end;
  ShowGroupMarks;
  CommitGroup;
end;

procedure TFormDesigner.MouseDown(ATarget: TComponent; const AScreen: TPoint);
var
  Par: TWinControl;
  Pt, FPt: TPoint;
  Nm: string;
  Handled: Boolean;
  I: Integer;
begin
  // Выбран класс на палитре - щелчок ставит компонент
  if Assigned(FOnPlace) then
  begin
    Par := PlaceParent(ATarget);
    if Par = FForm then
      Nm := FRootName
    else
      Nm := Par.Name;
    Pt := Par.ScreenToClient(AScreen);
    FPt := FForm.ScreenToClient(AScreen);
    Handled := False;
    FOnPlace(Nm, Snap(Pt.X), Snap(Pt.Y), Snap(FPt.X), Snap(FPt.Y), Handled);
    if Handled then
    begin
      FDragging := False;
      Exit;
    end;
  end;

  // Разбор Shift+щелчка - в HiLite log: кто под мышью, кто выделен и
  // почему группа не собирается
  if GetKeyState(VK_SHIFT) < 0 then
    DsgLog('3771: Shift+щелчок: под мышью ' + DsgCompName(ATarget) +
           ', выделен ' + DsgCompName(FSel) + ', из кода: ' +
           BoolToStr(IsRuntime(ATarget), True) + ' / ' +
           BoolToStr(IsRuntime(FSel), True) + ', в группе ' +
           IntToStr(FGroup.Count), clNavy);

  // Shift+щелчок - компонент в группу или из группы, как в Delphi. Группа -
  // либо из компонентов .dfm, либо из созданных в коде (кнопки палитры):
  // у вторых правятся только свойства, и не в .dfm (GroupIsRuntime).
  // Shift+щелчок по компоненту другого рода группу не меняет.
  if (GetKeyState(VK_SHIFT) < 0) and (ATarget is TControl) and
     (ATarget <> FForm) and (SelControl <> nil) then
  begin
    FDragging := False;
    if IsRuntime(ATarget) = IsRuntime(SelControl) then
      ToggleGroup(ATarget)
    else
      DsgLog('3788: Shift+щелчок: ' + DsgCompName(ATarget) + ' и ' +
             DsgCompName(FSel) + ' - один из .dfm, другой из кода, в одну ' +
             'группу их не взять', clNavy);
    Exit;
  end;

  // Щелчок по компоненту группы - тянут всю группу; выделение не меняется
  if (GroupCount > 1) and InGroup(ATarget) then
  begin
    FDragCtl := TControl(ATarget);
    FDragFrom := AScreen;
    FDragRect := FDragCtl.BoundsRect;
    SetLength(FGroupFrom, FGroup.Count);
    for I := 0 to FGroup.Count - 1 do
      FGroupFrom[I] := TControl(FGroup[I]).BoundsRect;
    FGroupDrag := True;
    FDragging := True;
    FDragMoved := False;
    Exit;
  end;

  Select(ATarget, True);
  // Компонент из кода и компонент, у которого код задаёт и Left, и Top, -
  // только выделяются. Одну из них - двигается по другой оси (MouseMove).
  if IsRuntime(ATarget) or
     ((Pos('L', CodePlacedSides(ATarget)) > 0) and
      (Pos('T', CodePlacedSides(ATarget)) > 0)) then
  begin
    FDragging := False;
    Exit;
  end;
  FDragging := False;
  if (ATarget = FForm) or not (ATarget is TControl) then
    Exit;
  // Выровненный компонент стоит там, где его ставит родитель
  if TControl(ATarget).Align <> alNone then
    Exit;
  FDragCtl := TControl(ATarget);
  FDragFrom := AScreen;
  FDragRect := FDragCtl.BoundsRect;
  FDragging := True;
  FDragMoved := False;
end;

// Перемещение - как MouseMoveObject у RQ: смещение от точки нажатия, угол
// компонента встаёт на сетку. Первые 3 пикселя - не перемещение, а
// дрожание руки при щелчке.
procedure TFormDesigner.MouseMove(const AScreen: TPoint);
var
  DX, DY, NewX, NewY, I: Integer;
  Code: string;
  R: TRect;
  C: TControl;
begin
  if not FDragging or (FDragCtl = nil) then
    Exit;
  DX := AScreen.X - FDragFrom.X;
  DY := AScreen.Y - FDragFrom.Y;
  if not FDragMoved and (Abs(DX) < 3) and (Abs(DY) < 3) then
    Exit;
  FDragMoved := True;

  // Группа: сдвиг - по тому, за кого тянут (угол на сетку), и тот же сдвиг
  // у всех. У каждого - свои ограничения: выровненный не едет, ось, по
  // которой место задаёт код, остаётся, за край родителя не уходит.
  if FGroupDrag then
  begin
    DX := Snap(FDragRect.Left + DX) - FDragRect.Left;
    DY := Snap(FDragRect.Top + DY) - FDragRect.Top;
    for I := 0 to FGroup.Count - 1 do
    begin
      C := TControl(FGroup[I]);
      if (I > High(FGroupFrom)) or (C.Align <> alNone) or IsRuntime(C) then
        Continue;
      R := FGroupFrom[I];
      Code := CodePlacedSides(C);
      if Pos('L', Code) = 0 then
        OffsetRect(R, DX, 0);
      if Pos('T', Code) = 0 then
        OffsetRect(R, 0, DY);
      ClampToParent(C.Parent, R, False);
      C.SetBounds(R.Left, R.Top, C.Width, C.Height);
    end;
    ShowGroupMarks;
    Exit;
  end;

  // Ось, по которой место задаёт код, остаётся на месте
  Code := CodePlacedSides(FDragCtl);
  NewX := Snap(FDragRect.Left + DX);
  NewY := Snap(FDragRect.Top + DY);
  if Pos('L', Code) > 0 then
    NewX := FDragRect.Left;
  if Pos('T', Code) > 0 then
    NewY := FDragRect.Top;
  // В пределах родителя
  R := Rect(NewX, NewY, NewX + FDragCtl.Width, NewY + FDragCtl.Height);
  ClampToParent(FDragCtl.Parent, R, False);
  NewX := R.Left;
  NewY := R.Top;
  FDragCtl.SetBounds(NewX, NewY, FDragCtl.Width, FDragCtl.Height);
  ShowCarets;
end;

procedure TFormDesigner.MouseUp;
begin
  if not FDragging then
    Exit;
  FDragging := False;
  if FGroupDrag then
  begin
    FGroupDrag := False;
    FDragCtl := nil;
    if FDragMoved then
      CommitGroup;
    Exit;
  end;
  if FDragMoved and (FDragCtl <> nil) and
     not EqualRect(FDragCtl.BoundsRect, FDragRect) then
    CommitBounds(FDragCtl);
  FDragCtl := nil;
end;

procedure TFormDesigner.KeyDown(AKey: Word);
begin
  if Assigned(FOnKey) then
    FOnKey(AKey, GetKeyState(VK_CONTROL) < 0, GetKeyState(VK_SHIFT) < 0);
end;

// Окно формы подвинули или потянули за край: у формы в .dfm место и
// клиентский размер. Width/Height и ClientWidth/ClientHeight пишутся
// только те, что в файле уже есть: иначе в .dfm оказались бы обе пары.
procedure TFormDesigner.FormMoved;
begin
  CommitBounds(FForm);
end;

procedure TFormDesigner.CommitBounds(AComp: TComponent);
var
  L: TStringList;
  C: TControl;
  Code: string;
begin
  if not Assigned(FOnChange) then
    Exit;
  L := TStringList.Create;
  try
    if AComp = FForm then
    begin
      L.Add('Left=' + IntToStr(FForm.Left));
      L.Add('Top=' + IntToStr(FForm.Top));
      L.Add('?Width=' + IntToStr(FForm.Width));
      L.Add('?Height=' + IntToStr(FForm.Height));
      L.Add('?ClientWidth=' + IntToStr(FForm.ClientWidth));
      L.Add('?ClientHeight=' + IntToStr(FForm.ClientHeight));
      FOnChange(FRootName, L);
    end
    else if AComp is TControl then
    begin
      C := TControl(AComp);
      // Без имени объект в .dfm не найти; компонент из кода - не в .dfm
      if (C.Name = '') or IsRuntime(C) then
        Exit;
      // Координаты, которые задаёт код, в .dfm не пишутся: там они
      // живые, а не из файла (MarkCodePlaced)
      Code := CodePlacedSides(C);
      // Выровненному место задаёт родитель - пишется только свободный
      // размер: у alTop/alBottom высота, у alLeft/alRight ширина
      case C.Align of
        alTop, alBottom:
          begin
            if Pos('H', Code) > 0 then
              Exit;
            L.Add('Height=' + IntToStr(C.Height));
            FOnChange(C.Name, L);
            Exit;
          end;
        alLeft, alRight:
          begin
            if Pos('W', Code) > 0 then
              Exit;
            L.Add('Width=' + IntToStr(C.Width));
            FOnChange(C.Name, L);
            Exit;
          end;
        alNone: ;
      else
        Exit;
      end;
      if Pos('L', Code) = 0 then
        L.Add('Left=' + IntToStr(C.Left));
      if Pos('T', Code) = 0 then
        L.Add('Top=' + IntToStr(C.Top));
      if Pos('W', Code) = 0 then
        L.Add('Width=' + IntToStr(C.Width));
      if Pos('H', Code) = 0 then
        L.Add('Height=' + IntToStr(C.Height));
      if L.Count > 0 then
        FOnChange(C.Name, L);
    end
    else
    begin
      if AComp.Name = '' then
        Exit;
      L.Add('Left=' + IntToStr(LongRec(AComp.DesignInfo).Lo));
      L.Add('Top=' + IntToStr(LongRec(AComp.DesignInfo).Hi));
      FOnChange(AComp.Name, L);
    end;
  finally
    L.Free;
  end;
end;

end.
